<#############################################################################
The TypePx module adds properties and methods to the most commonly used types
to make common tasks easier. Using these type extensions together can provide
an enhanced syntax in PowerShell that is both easier to read and
self-documenting. TypePx also provides commands to manage type accelerators.
Type acceleration also contributes to making scripting easier and they help
produce more readable scripts, particularly when using a library of .NET
classes that belong to the same namespace.

Copyright 2014 Kirk Munro

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
#############################################################################>

$commonlyUsedGenericTypeParameters = @(
    [System.Management.Automation.PSObject]
    [System.Object]
    [System.String]
    [System.Int32]
    [System.Int64]
)
$typeNames = @()
foreach ($assembly in [System.AppDomain]::CurrentDomain.GetAssemblies()) {
    foreach ($type in $assembly.GetTypes()) {
        # If the type is not public or if it is an interface, skip it
        if ((-not $type.IsPublic) -or $type.IsInterface) {
            continue
        }
        # If the type is String or XmlNode, skip it (these are exceptions in PowerShell)
        if (@([System.String],[System.Xml.XmlNode]) -contains $type) {
            continue
        }
        # If the type does not implement IEnumerable or it implements IDictionary, skip it
        $interfaces = $type.GetInterfaces()
        if (($interfaces -notcontains [System.Collections.IEnumerable]) -or
            ($interfaces -contains [System.Collections.IDictionary])) {
            continue
        }
        # If the base type is not Object, MarshalByRefObject, or ValueType, skip it
        if (@([System.Object],[System.MarshalByRefObject],[System.ValueType]) -notcontains $type.BaseType) {
            continue
        }
        # If the type definition is generic, add a collection of common generic types to our
        # enumerable type collection; otherwise, just add the type
        if ($type.IsGenericTypeDefinition) {
            foreach ($typeParameter in $commonlyUsedGenericTypeParameters) {
                $typeNames += "$($type.FullName)[[$($typeParameter.AssemblyQualifiedName)]]"
            }
        } else {
            $typeNames += $type.FullName
        }
    }
}

if ($PSVersionTable.PSVersion -lt [System.Version]'4.0') {
    Add-ScriptMethodData -TypeName $typeNames -ScriptMethodName foreach -ScriptBlock {
        [System.Diagnostics.DebuggerStepThrough()]
        param(
            # A script block (expression), type (conversion type), or string (property or method name)
            [Parameter(Position=0, Mandatory=$true)]
            [ValidateNotNull()]
            [System.Object]
            $Object
        )
        # Create an array to hold the results
        $results = @()
        if ($Object -is [System.Management.Automation.ScriptBlock]) {
            # Process as if we used ForEach-Object
            # I would love to make this more efficient for 3.0, but it is too difficult to work around the
            # limitation of being unable to invoke a script block in its scope while passing it parameters
            # without using a pipeline.
            $passThruParameters = @{
                Process = $Object
            }
            if ($args) {
                $passThruParameters['ArgumentList'] = $args
            }
            $results = @($this | ForEach-Object @passThruParameters)
        } elseif ($Object -is [System.Type]) {
            # Convert the items in the collection to the type specified
            foreach ($item in $this) {
                $results += $item -as $Object
            }
            $results = $results -as ("System.Collections.ObjectModel.Collection``1[$($Object.FullName)]" -as [System.Type])
        } elseif ($Object -is [System.String]) {
            foreach ($item in $this) {
                if ($member = $item.PSObject.Members[$Object -as [System.String]]) {
                    if ($member -is [System.Management.Automation.PSMethodInfo]) {
                        # Invoke the method on objects in the collection
                        if ($result = $member.Invoke($args)) {
                            $results += $result
                        }
                    } elseif ($member -is [System.Management.Automation.PSPropertyInfo]) {
                        if ($args) {
                            # Set the property on objects in the collection
                            $member.Value = $args
                        } else {
                            # Get the property on objects in the collection
                            $results += $member.Value
                        }
                    }
                }
            }
        }
        if ($Object -isnot [System.Type]) {
            # Return the results in an objectmodel collection to the caller
            if ($results) {
                $results = $results -as [System.Management.Automation.PSObject[]] -as [System.Collections.ObjectModel.Collection`1[System.Management.Automation.PSObject]]
            } else {
                $results = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[System.Management.Automation.PSObject]]'
            }
        }
        ,$results
    }

    Add-ScriptMethodData -TypeName $typeNames -ScriptMethodName where -ScriptBlock {
#        [System.Diagnostics.DebuggerStepThrough()]
        param(
            # The conditional expression that we are evaluating
            [Parameter(Position=0, Mandatory=$true)]
            [ValidateNotNull()]
            [System.Management.Automation.ScriptBlock]
            $Expression,

            # The evaluation mode
            [Parameter(Position=1)]
            [ValidateNotNullOrEmpty()]
            [ValidateSet('Default','First','Last','SkipUntil','Until','Split')]
            [System.String]
            $Mode = 'Default',

            # The number of objects to return
            [Parameter(Position=2)]
            [ValidateNotNull()]
            [ValidateRange(0,[System.Int32]::MaxValue)]
            [System.Int32]
            $NumberToReturn = 0
        )
        # Create an array to hold the results
        $results = @()
        switch ($Mode) {
            'First' {
                # Return the first N objects matching the expression (default to 1)
                if ($NumberToReturn -eq 0) {
                    $NumberToReturn = 1
                }
                $results = @($this | Where-Object -FilterScript $Expression | Select-Object -First $NumberToReturn)
                break
            }
            'Last' {
                # Return the last N objects matching the expression (default to 1)
                if ($NumberToReturn -eq 0) {
                    $NumberToReturn = 1
                }
                $results = @($this | Where-Object -FilterScript $Expression | Select-Object -Last $NumberToReturn)
                break
            }
            'SkipUntil' {
                # Skip until an object matches the expression, then return the first N objects (default to all)
                $outputCount = 0
                if ($NumberToReturn -eq 0) {
                    $NumberToReturn = $this.Count
                }
                foreach ($item in $this) {
                    if (($outputCount -eq 0) -and -not (Where-Object -InputObject $item -FilterScript $Expression)) {
                        continue
                    }
                    if ($outputCount -lt $NumberToReturn) {
                        $outputCount++
                        $results += $item
                    }
                    if ($outputCount -eq $NumberToReturn) {
                        break
                    }
                }
                break
            }
            'Until' {
                # Return the first N objects until an object matches the expression (default to all)
                $outputCount = 0
                if ($NumberToReturn -eq 0) {
                    $NumberToReturn = $this.Count
                }
                foreach ($item in $this) {
                    if (Where-Object -InputObject $item -FilterScript $Expression) {
                        break
                    }
                    if ($outputCount -lt $NumberToReturn) {
                        $outputCount++
                        $results += $item
                    }
                    if ($outputCount -eq $NumberToReturn) {
                        break
                    }
                }
                break
            }
            'Split' {
                # Split based on condition, to a maximum count if one was provided (default to all)
                $collection0 = @()
                $collection1 = @()
                if ($NumberToReturn -eq 0) {
                    $NumberToReturn = $this.Count
                }
                foreach ($item in $this) {
                    if (($collection0.Count -lt $NumberToReturn) -and
                        (Where-Object -InputObject $item -FilterScript $Expression)) {
                        $collection0 += $item
                    } else {
                        $collection1 += $item
                    }
                }
                $collection0 = $collection0 -as [System.Management.Automation.PSObject[]] -as [System.Collections.ObjectModel.Collection`1[System.Management.Automation.PSObject]]
                $collection1 = $collection1 -as [System.Management.Automation.PSObject[]] -as [System.Collections.ObjectModel.Collection`1[System.Management.Automation.PSObject]]
                $results = @($collection0,$collection1)
                break
            }
            default {
                # Filter using the expression, to a maximum count if one was provided (default to all)
                if ($NumberToReturn -eq 0) {
                    $results = @($this | Where-Object -FilterScript $Expression)
                } else {
                    $results = @($this | Where-Object -FilterScript $Expression | Select-Object -First $NumberToReturn)
                }
                break
            }
        }
        if ($Mode -ne 'Split') {
            # Return the results in an objectmodel collection to the caller
            if ($results) {
                $results = $results -as [System.Management.Automation.PSObject[]] -as [System.Collections.ObjectModel.Collection`1[System.Management.Automation.PSObject]]
            } else {
                $results = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[System.Management.Automation.PSObject]'
            }
        }
        ,$results
    }
}

Add-ScriptMethodData -TypeName $typeNames -ScriptMethodName MatchAny -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The regular expressions to compare the collection against
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Values
    )
    # Add remaining arguments to the value collection for easier invocation
    if ($args) {
        $Values += $args
    }
    # Return any items in the collection matching the values provided
    ,($this.where({([string]$_).MatchAny($Values)}) -as $this.GetType())
}

Add-ScriptMethodData -TypeName $typeNames -ScriptMethodName LikeAny -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The wildcard strings to compare the collection against
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Values
    )
    # Add remaining arguments to the value collection for easier invocation
    if ($args) {
        $Values += $args
    }
    # Return any items in the collection like the values provided
    ,($this.where({([string]$_).LikeAny($Values)}) -as $this.GetType())
}

Add-ScriptMethodData -TypeName $typeNames -ScriptMethodName ContainsAny -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The values to compare the collection against
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        $Values
    )
    # Add remaining arguments to the value collection for easier invocation
    if ($args) {
        $Values += $args
    }
    # Return true if the collection contains any of the values; false otherwise
    $matchFound = $false
    foreach ($item in $Values) {
        if ($this -contains $item) {
            $matchFound = $true
            break
        }
    }
    $matchFound
}

Add-ScriptMethodData -TypeName $typeNames -ScriptMethodName ContainsAll -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The values to compare the collection against
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        $Values
    )
    # Add remaining arguments to the value collection for easier invocation
    if ($args) {
        $Values += $args
    }
    # Return true if the collection contains all of the values; false otherwise
    foreach ($item in $Values) {
        if ($this -notcontains $item) {
            $false
            break
        }
    }
    $true
}

Add-ScriptMethodData -TypeName $typeNames -ScriptMethodName Sum -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The property to use when calculating the sum
        [Parameter(Position=0)]
        [ValidateNotNull()]
        [System.String]
        $Property
    )
    # Calculate the sum of the collection or of the values of a specific property
    # in the collection
    $total = $null
    if ($PSVersionTable.PSVersion -lt [System.Version]'4.0') {
        foreach ($item in $this) {
            if ($Property) {
                $total += $item.$Property
            } else {
                $total += $item
            }
        }
    } elseif ($Property) {
        $this.foreach({$total += $_.$Property})
    } else {
        $this.foreach({$total += $_})
    }
    $total
}
# SIG # Begin signature block
# MIIZIAYJKoZIhvcNAQcCoIIZETCCGQ0CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUyp0CqWQZGfSdCkZVR9LaheFp
# CXegghRWMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
# AQUFADCBizELMAkGA1UEBhMCWkExFTATBgNVBAgTDFdlc3Rlcm4gQ2FwZTEUMBIG
# A1UEBxMLRHVyYmFudmlsbGUxDzANBgNVBAoTBlRoYXd0ZTEdMBsGA1UECxMUVGhh
# d3RlIENlcnRpZmljYXRpb24xHzAdBgNVBAMTFlRoYXd0ZSBUaW1lc3RhbXBpbmcg
# Q0EwHhcNMTIxMjIxMDAwMDAwWhcNMjAxMjMwMjM1OTU5WjBeMQswCQYDVQQGEwJV
# UzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFu
# dGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMjCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBALGss0lUS5ccEgrYJXmRIlcqb9y4JsRDc2vCvy5Q
# WvsUwnaOQwElQ7Sh4kX06Ld7w3TMIte0lAAC903tv7S3RCRrzV9FO9FEzkMScxeC
# i2m0K8uZHqxyGyZNcR+xMd37UWECU6aq9UksBXhFpS+JzueZ5/6M4lc/PcaS3Er4
# ezPkeQr78HWIQZz/xQNRmarXbJ+TaYdlKYOFwmAUxMjJOxTawIHwHw103pIiq8r3
# +3R8J+b3Sht/p8OeLa6K6qbmqicWfWH3mHERvOJQoUvlXfrlDqcsn6plINPYlujI
# fKVOSET/GeJEB5IL12iEgF1qeGRFzWBGflTBE3zFefHJwXECAwEAAaOB+jCB9zAd
# BgNVHQ4EFgQUX5r1blzMzHSa1N197z/b7EyALt0wMgYIKwYBBQUHAQEEJjAkMCIG
# CCsGAQUFBzABhhZodHRwOi8vb2NzcC50aGF3dGUuY29tMBIGA1UdEwEB/wQIMAYB
# Af8CAQAwPwYDVR0fBDgwNjA0oDKgMIYuaHR0cDovL2NybC50aGF3dGUuY29tL1Ro
# YXd0ZVRpbWVzdGFtcGluZ0NBLmNybDATBgNVHSUEDDAKBggrBgEFBQcDCDAOBgNV
# HQ8BAf8EBAMCAQYwKAYDVR0RBCEwH6QdMBsxGTAXBgNVBAMTEFRpbWVTdGFtcC0y
# MDQ4LTEwDQYJKoZIhvcNAQEFBQADgYEAAwmbj3nvf1kwqu9otfrjCR27T4IGXTdf
# plKfFo3qHJIJRG71betYfDDo+WmNI3MLEm9Hqa45EfgqsZuwGsOO61mWAK3ODE2y
# 0DGmCFwqevzieh1XTKhlGOl5QGIllm7HxzdqgyEIjkHq3dlXPx13SYcqFgZepjhq
# IhKjURmDfrYwggSjMIIDi6ADAgECAhAOz/Q4yP6/NW4E2GqYGxpQMA0GCSqGSIb3
# DQEBBQUAMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3Jh
# dGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBD
# QSAtIEcyMB4XDTEyMTAxODAwMDAwMFoXDTIwMTIyOTIzNTk1OVowYjELMAkGA1UE
# BhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTQwMgYDVQQDEytT
# eW1hbnRlYyBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIFNpZ25lciAtIEc0MIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAomMLOUS4uyOnREm7Dv+h8GEKU5Ow
# mNutLA9KxW7/hjxTVQ8VzgQ/K/2plpbZvmF5C1vJTIZ25eBDSyKV7sIrQ8Gf2Gi0
# jkBP7oU4uRHFI/JkWPAVMm9OV6GuiKQC1yoezUvh3WPVF4kyW7BemVqonShQDhfu
# ltthO0VRHc8SVguSR/yrrvZmPUescHLnkudfzRC5xINklBm9JYDh6NIipdC6Anqh
# d5NbZcPuF3S8QYYq3AhMjJKMkS2ed0QfaNaodHfbDlsyi1aLM73ZY8hJnTrFxeoz
# C9Lxoxv0i77Zs1eLO94Ep3oisiSuLsdwxb5OgyYI+wu9qU+ZCOEQKHKqzQIDAQAB
# o4IBVzCCAVMwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAO
# BgNVHQ8BAf8EBAMCB4AwcwYIKwYBBQUHAQEEZzBlMCoGCCsGAQUFBzABhh5odHRw
# Oi8vdHMtb2NzcC53cy5zeW1hbnRlYy5jb20wNwYIKwYBBQUHMAKGK2h0dHA6Ly90
# cy1haWEud3Muc3ltYW50ZWMuY29tL3Rzcy1jYS1nMi5jZXIwPAYDVR0fBDUwMzAx
# oC+gLYYraHR0cDovL3RzLWNybC53cy5zeW1hbnRlYy5jb20vdHNzLWNhLWcyLmNy
# bDAoBgNVHREEITAfpB0wGzEZMBcGA1UEAxMQVGltZVN0YW1wLTIwNDgtMjAdBgNV
# HQ4EFgQURsZpow5KFB7VTNpSYxc/Xja8DeYwHwYDVR0jBBgwFoAUX5r1blzMzHSa
# 1N197z/b7EyALt0wDQYJKoZIhvcNAQEFBQADggEBAHg7tJEqAEzwj2IwN3ijhCcH
# bxiy3iXcoNSUA6qGTiWfmkADHN3O43nLIWgG2rYytG2/9CwmYzPkSWRtDebDZw73
# BaQ1bHyJFsbpst+y6d0gxnEPzZV03LZc3r03H0N45ni1zSgEIKOq8UvEiCmRDoDR
# EfzdXHZuT14ORUZBbg2w6jiasTraCXEQ/Bx5tIB7rGn0/Zy2DBYr8X9bCT2bW+IW
# yhOBbQAuOA2oKY8s4bL0WqkBrxWcLC9JG9siu8P+eJRRw4axgohd8D20UaF5Mysu
# e7ncIAkTcetqGVvP6KUwVyyJST+5z3/Jvz4iaGNTmr1pdKzFHTx/kuDDvBzYBHUw
# ggUSMIID+qADAgECAhAN//fSWE4vjemplVn1wnAjMA0GCSqGSIb3DQEBBQUAMG8x
# CzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3
# dy5kaWdpY2VydC5jb20xLjAsBgNVBAMTJURpZ2lDZXJ0IEFzc3VyZWQgSUQgQ29k
# ZSBTaWduaW5nIENBLTEwHhcNMTQxMDAzMDAwMDAwWhcNMTUxMDA3MTIwMDAwWjBo
# MQswCQYDVQQGEwJDQTEQMA4GA1UECBMHT250YXJpbzEPMA0GA1UEBxMGT3R0YXdh
# MRowGAYDVQQKExFLaXJrIEFuZHJldyBNdW5ybzEaMBgGA1UEAxMRS2lyayBBbmRy
# ZXcgTXVucm8wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDIANwog4/2
# JUJCJ1PKeXu8S+eBp1F8fHaVFVgMToGhyNz+UptqDVBIsOu21AXNd4s/3WqhOnOt
# yBvyn5thWNGCMB/XcX6/SdV8lSyg0swreiiR7ksJc1jK75aDJV2UE/mOiMtcWo01
# SQGddbF4FpK3LxbzjKGMPP7uI1TUFTxmdR8t8HaRlI7KcsZkckGffkboAm5CWDhZ
# d4f9YhVzZ8uV0jAN9i+mtmIOHTMMskQ7tZy17GkgyjiGrnMxy6VZ18hya062ZLcV
# 20LUqsUkjr0oNvf54KrhZrPQhULagcpKwmxw3hzDfvWov4yVLWdgWT6a+TUG8D39
# HUuVCpXG+OgZAgMBAAGjggGvMIIBqzAfBgNVHSMEGDAWgBR7aM4pqsAXvkl64eU/
# 1qf3RY81MjAdBgNVHQ4EFgQUG+clmaBur2rhO4i38pTJHCFSya0wDgYDVR0PAQH/
# BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMG0GA1UdHwRmMGQwMKAuoCyGKmh0
# dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9hc3N1cmVkLWNzLWcxLmNybDAwoC6gLIYq
# aHR0cDovL2NybDQuZGlnaWNlcnQuY29tL2Fzc3VyZWQtY3MtZzEuY3JsMEIGA1Ud
# IAQ7MDkwNwYJYIZIAYb9bAMBMCowKAYIKwYBBQUHAgEWHGh0dHBzOi8vd3d3LmRp
# Z2ljZXJ0LmNvbS9DUFMwgYIGCCsGAQUFBwEBBHYwdDAkBggrBgEFBQcwAYYYaHR0
# cDovL29jc3AuZGlnaWNlcnQuY29tMEwGCCsGAQUFBzAChkBodHRwOi8vY2FjZXJ0
# cy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURDb2RlU2lnbmluZ0NBLTEu
# Y3J0MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQEFBQADggEBACJI6tx95+XcEC6X
# EAxbRZjIXJ085IDdqWXImnfQ8To+yAeHM5kP506ddtzlztW9esOxqnhnfIAClB1e
# 1f/FAlgpxrEQ2IRCuUHuMfy4AxqRkD9jePVZ7NYKcKxJZ87iu32iuGT+phFip+ZP
# O9GkqDYkvzQmB74b7hQ3knn6qFLqUZ8njpSceIeC8PHINZmSx+v+KVkEavN/z0hF
# T9xYR2VPPjIIk3MnwtkyHhTWWxNoKGCg+BZV2mApwR9EsWJHVpiGru6DNfNwSQpB
# oIvMGOOL919XgE4J1B022xnAcnCCxoGjjSmBPb1TWemijGsGD2Je8/EALw9geBB9
# vbJvwn8wggajMIIFi6ADAgECAhAPqEkGFdcAoL4hdv3F7G29MA0GCSqGSIb3DQEB
# BQUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNV
# BAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNVBAMTG0RpZ2lDZXJ0IEFzc3VyZWQg
# SUQgUm9vdCBDQTAeFw0xMTAyMTExMjAwMDBaFw0yNjAyMTAxMjAwMDBaMG8xCzAJ
# BgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5k
# aWdpY2VydC5jb20xLjAsBgNVBAMTJURpZ2lDZXJ0IEFzc3VyZWQgSUQgQ29kZSBT
# aWduaW5nIENBLTEwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCcfPmg
# jwrKiUtTmjzsGSJ/DMv3SETQPyJumk/6zt/G0ySR/6hSk+dy+PFGhpTFqxf0eH/L
# er6QJhx8Uy/lg+e7agUozKAXEUsYIPO3vfLcy7iGQEUfT/k5mNM7629ppFwBLrFm
# 6aa43Abero1i/kQngqkDw/7mJguTSXHlOG1O/oBcZ3e11W9mZJRru4hJaNjR9H4h
# webFHsnglrgJlflLnq7MMb1qWkKnxAVHfWAr2aFdvftWk+8b/HL53z4y/d0qLDJG
# 2l5jvNC4y0wQNfxQX6xDRHz+hERQtIwqPXQM9HqLckvgVrUTtmPpP05JI+cGFvAl
# qwH4KEHmx9RkO12rAgMBAAGjggNDMIIDPzAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0l
# BAwwCgYIKwYBBQUHAwMwggHDBgNVHSAEggG6MIIBtjCCAbIGCGCGSAGG/WwDMIIB
# pDA6BggrBgEFBQcCARYuaHR0cDovL3d3dy5kaWdpY2VydC5jb20vc3NsLWNwcy1y
# ZXBvc2l0b3J5Lmh0bTCCAWQGCCsGAQUFBwICMIIBVh6CAVIAQQBuAHkAIAB1AHMA
# ZQAgAG8AZgAgAHQAaABpAHMAIABDAGUAcgB0AGkAZgBpAGMAYQB0AGUAIABjAG8A
# bgBzAHQAaQB0AHUAdABlAHMAIABhAGMAYwBlAHAAdABhAG4AYwBlACAAbwBmACAA
# dABoAGUAIABEAGkAZwBpAEMAZQByAHQAIABDAFAALwBDAFAAUwAgAGEAbgBkACAA
# dABoAGUAIABSAGUAbAB5AGkAbgBnACAAUABhAHIAdAB5ACAAQQBnAHIAZQBlAG0A
# ZQBuAHQAIAB3AGgAaQBjAGgAIABsAGkAbQBpAHQAIABsAGkAYQBiAGkAbABpAHQA
# eQAgAGEAbgBkACAAYQByAGUAIABpAG4AYwBvAHIAcABvAHIAYQB0AGUAZAAgAGgA
# ZQByAGUAaQBuACAAYgB5ACAAcgBlAGYAZQByAGUAbgBjAGUALjASBgNVHRMBAf8E
# CDAGAQH/AgEAMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDovL29j
# c3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MIGBBgNVHR8EejB4
# MDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVk
# SURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGln
# aUNlcnRBc3N1cmVkSURSb290Q0EuY3JsMB0GA1UdDgQWBBR7aM4pqsAXvkl64eU/
# 1qf3RY81MjAfBgNVHSMEGDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG
# 9w0BAQUFAAOCAQEAe3IdZP+IyDrBt+nnqcSHu9uUkteQWTP6K4feqFuAJT8Tj5uD
# G3xDxOaM3zk+wxXssNo7ISV7JMFyXbhHkYETRvqcP2pRON60Jcvwq9/FKAFUeRBG
# JNE4DyahYZBNur0o5j/xxKqb9to1U0/J8j3TbNwj7aqgTWcJ8zqAPTz7NkyQ53ak
# 3fI6v1Y1L6JMZejg1NrRx8iRai0jTzc7GZQY1NWcEDzVsRwZ/4/Ia5ue+K6cmZZ4
# 0c2cURVbQiZyWo0KSiOSQOiG3iLCkzrUm2im3yl/Brk8Dr2fxIacgkdCcTKGCZly
# CXlLnXFp9UH/fzl3ZPGEjb6LHrJ9aKOlkLEM/zGCBDQwggQwAgEBMIGDMG8xCzAJ
# BgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5k
# aWdpY2VydC5jb20xLjAsBgNVBAMTJURpZ2lDZXJ0IEFzc3VyZWQgSUQgQ29kZSBT
# aWduaW5nIENBLTECEA3/99JYTi+N6amVWfXCcCMwCQYFKw4DAhoFAKB4MBgGCisG
# AQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFK6I
# qZ7FSuSspPBf6Ke8yHtYxYGNMA0GCSqGSIb3DQEBAQUABIIBAL3hO89g3KfMUb2B
# 43SrdcobJ6vatBrZu7L1O3d82xzFmDoR/zlyqzgx9shEG2hR/Pr+EtgB/wvCXkdJ
# +gNx+u/TZKUVYDc258cbCmxbaIcRKesBdG6Ac3gnB6tuoLOVFqNL7i1KsSK3dK1s
# 8bWYFzJmpkBIMlP/DZpMFMpbnwxEwGGJLaOMwzTcCCOe+3D6n3nXNu7aMI02ar0P
# c9ITYJqx3X2bAnmMhF8R/2wCngsGQX7AE/3eWD47wajriuxqIWOcd99TDFT9oKnm
# tNyWCEPM6fXSPzUS9lNu9W9+nWMiUxous2kD4PP9RRq/CECf2bDuDQM0vb6a009t
# YiEXLC6hggILMIICBwYJKoZIhvcNAQkGMYIB+DCCAfQCAQEwcjBeMQswCQYDVQQG
# EwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5
# bWFudGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMgIQDs/0OMj+vzVu
# BNhqmBsaUDAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAc
# BgkqhkiG9w0BCQUxDxcNMTQxMTE0MjExNDA2WjAjBgkqhkiG9w0BCQQxFgQUbI6/
# 04P6n+j7quHz9IlWDp3WRWowDQYJKoZIhvcNAQEBBQAEggEALc5wXvrERJb57BaJ
# avUWEwLWzkcPYe+hWrLm4mpZohO7+YUZY80jIetkjwYJNJn/Vxlj72flOubV2v+d
# 6TxbXgHODhNOTdn7Tud7/mUv8FpEYkG+adE2J3IW+SG+drD5KzdRvFaTawj3bXSD
# twgrWoj5w/qJkCNbO2HKiu1LSV1u+E+xdUHLGk3YjMoeB0fCxdwRYtoIEyqibxn8
# pV5CV3DiBEU4yxMm4+XAbUlRLAZXKkgtV6zjGnJsCifXXO8gagSv8jZ0HFfTV5Zj
# Lo9WtHYsgoyUo0pe3+FHF7IFG4/BvuUrm0W5WAhCL7n8xisbj5/yr0q2b+jdQ9Of
# lyg5fw==
# SIG # End signature block
