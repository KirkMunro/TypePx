<#############################################################################
The TypePx module adds properties and methods to the most commonly used types
to make common tasks easier. Using these type extensions together can provide
an enhanced syntax in PowerShell that is both easier to read and
self-documenting. TypePx also provides commands to manage type accelerators.
Type acceleration also contributes to making scripting easier and they help
produce more readable scripts, particularly when using a library of .NET
classes that belong to the same namespace.

Copyright 2016 Kirk Munro

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
        [System.Diagnostics.DebuggerStepThrough()]
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

Add-ScriptMethodData -TypeName $typeNames -ScriptMethodName Take -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        [Parameter(Position=0)]
        [ValidateNotNull()]
        [System.Int32]
        $Count
    )
    [System.Linq.Enumerable]::Take([object[]]($this),$Count)
}

Add-ScriptMethodData -TypeName $typeNames -ScriptMethodName Skip -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        [Parameter(Position=0)]
        [ValidateNotNull()]
        [System.Int32]
        $Count
    )
    [System.Linq.Enumerable]::Skip([object[]]($this),$Count)
}
# SIG # Begin signature block
# MIIXyQYJKoZIhvcNAQcCoIIXujCCF7YCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUnTv/KapDyDOXeGKq9VMyPIfJ
# 41ygghL8MIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
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
# ggUrMIIEE6ADAgECAhAMazN+7i4fWwlOi2uN0bz4MA0GCSqGSIb3DQEBCwUAMHIx
# CzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3
# dy5kaWdpY2VydC5jb20xMTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJ
# RCBDb2RlIFNpZ25pbmcgQ0EwHhcNMTUwNzA5MDAwMDAwWhcNMTYxMTEwMTIwMDAw
# WjBoMQswCQYDVQQGEwJDQTEQMA4GA1UECBMHT250YXJpbzEPMA0GA1UEBxMGT3R0
# YXdhMRowGAYDVQQKExFLaXJrIEFuZHJldyBNdW5ybzEaMBgGA1UEAxMRS2lyayBB
# bmRyZXcgTXVucm8wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQChKHoG
# aabXPO+dzyq2VCIkuIUJj5zHfIGqyRGD2OWtUUSrbZ5lbl4cIXgzCn2PUxVROeoo
# mAAUAQzEhG35QPHsGvvAA24kn/JvXL/2RcQBtoWroIyzo28UpYIwcgzaou9odfeb
# jkIwgRmmY9oc+agutOGE9ZFQ9VUOq24ZDW3sCcUY1f5d91bawRctqvD4SRJhd9cc
# 6ICEw5rsr1kMs1YlEdr/3QHahlrTkjukRPEMxbThzp5K28H7xyNDYTiSDSKuUABi
# J0rZ8QGN8lElt6g4omJ1+2/4hPmuwk16J+RPwZKE9JgP+xkP3nzoLxNh9H/+47TV
# 3n8X9pk4LtQZe64LAgMBAAGjggHFMIIBwTAfBgNVHSMEGDAWgBRaxLl7Kgqjpepx
# A8Bg+S32ZXUOWDAdBgNVHQ4EFgQU84QR229qzy+aB5XNBzCXkzdkqdswDgYDVR0P
# AQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMHcGA1UdHwRwMG4wNaAzoDGG
# L2h0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9zaGEyLWFzc3VyZWQtY3MtZzEuY3Js
# MDWgM6Axhi9odHRwOi8vY3JsNC5kaWdpY2VydC5jb20vc2hhMi1hc3N1cmVkLWNz
# LWcxLmNybDBMBgNVHSAERTBDMDcGCWCGSAGG/WwDATAqMCgGCCsGAQUFBwIBFhxo
# dHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BTMAgGBmeBDAEEATCBhAYIKwYBBQUH
# AQEEeDB2MCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wTgYI
# KwYBBQUHMAKGQmh0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydFNI
# QTJBc3N1cmVkSURDb2RlU2lnbmluZ0NBLmNydDAMBgNVHRMBAf8EAjAAMA0GCSqG
# SIb3DQEBCwUAA4IBAQD1CbyvOZ3FjxiHimw8mwcNEMn74GinkGi+f2aCGRwH01Jj
# lJvjkkRKHezaAMhrK0xDmuQIanKMoJvWKi+JuzJHNhH1ZMUK7AoXjBhBmQuoqqtf
# KLbl+b5UK/iBeZX2IgUWYUaE33mr8mK/fJcQIzFrZKPY/eTRencOw8ioxLyRlp18
# mzHMV/1CH5BelGx7bBxXRXSNkLoeRy79ElPa85swSI8zI3ZMXTr6SPCZii4o/Stz
# EIK66lEVh0OGBTQWtbsWB7hqyKX1ja2PIQB6ycMgy4y5zbKzhjyX71TysyY5lgXE
# XmWCKeOqDUhbeMD0uMPNBZnnCJIlEOLhFe1aejSKMIIFMDCCBBigAwIBAgIQBAkY
# G1/Vu2Z1U0O1b5VQCDANBgkqhkiG9w0BAQsFADBlMQswCQYDVQQGEwJVUzEVMBMG
# A1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMSQw
# IgYDVQQDExtEaWdpQ2VydCBBc3N1cmVkIElEIFJvb3QgQ0EwHhcNMTMxMDIyMTIw
# MDAwWhcNMjgxMDIyMTIwMDAwWjByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGln
# aUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhE
# aWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMIIBIjANBgkq
# hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA+NOzHH8OEa9ndwfTCzFJGc/Q+0WZsTrb
# RPV/5aid2zLXcep2nQUut4/6kkPApfmJ1DcZ17aq8JyGpdglrA55KDp+6dFn08b7
# KSfH03sjlOSRI5aQd4L5oYQjZhJUM1B0sSgmuyRpwsJS8hRniolF1C2ho+mILCCV
# rhxKhwjfDPXiTWAYvqrEsq5wMWYzcT6scKKrzn/pfMuSoeU7MRzP6vIK5Fe7SrXp
# dOYr/mzLfnQ5Ng2Q7+S1TqSp6moKq4TzrGdOtcT3jNEgJSPrCGQ+UpbB8g8S9MWO
# D8Gi6CxR93O8vYWxYoNzQYIH5DiLanMg0A9kczyen6Yzqf0Z3yWT0QIDAQABo4IB
# zTCCAckwEgYDVR0TAQH/BAgwBgEB/wIBADAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0l
# BAwwCgYIKwYBBQUHAwMweQYIKwYBBQUHAQEEbTBrMCQGCCsGAQUFBzABhhhodHRw
# Oi8vb2NzcC5kaWdpY2VydC5jb20wQwYIKwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRz
# LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcnQwgYEGA1Ud
# HwR6MHgwOqA4oDaGNGh0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFz
# c3VyZWRJRFJvb3RDQS5jcmwwOqA4oDaGNGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNv
# bS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwTwYDVR0gBEgwRjA4BgpghkgB
# hv1sAAIEMCowKAYIKwYBBQUHAgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9D
# UFMwCgYIYIZIAYb9bAMwHQYDVR0OBBYEFFrEuXsqCqOl6nEDwGD5LfZldQ5YMB8G
# A1UdIwQYMBaAFEXroq/0ksuCMS1Ri6enIZ3zbcgPMA0GCSqGSIb3DQEBCwUAA4IB
# AQA+7A1aJLPzItEVyCx8JSl2qB1dHC06GsTvMGHXfgtg/cM9D8Svi/3vKt8gVTew
# 4fbRknUPUbRupY5a4l4kgU4QpO4/cY5jDhNLrddfRHnzNhQGivecRk5c/5CxGwcO
# kRX7uq+1UcKNJK4kxscnKqEpKBo6cSgCPC6Ro8AlEeKcFEehemhor5unXCBc2XGx
# DI+7qPjFEmifz0DLQESlE/DmZAwlCEIysjaKJAL+L3J+HNdJRZboWR3p+nRka7Lr
# ZkPas7CM1ekN3fYBIM6ZMWM9CBoYs4GbT8aTEAb8B4H6i9r5gkn3Ym6hU/oSlBiF
# LpKR6mhsRDKyZqHnGKSaZFHvMYIENzCCBDMCAQEwgYYwcjELMAkGA1UEBhMCVVMx
# FTATBgNVBAoTDERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNv
# bTExMC8GA1UEAxMoRGlnaUNlcnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2lnbmlu
# ZyBDQQIQDGszfu4uH1sJTotrjdG8+DAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIB
# DDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEE
# AYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUlkjQllLzZOEq
# uC045WiUF0LdaFEwDQYJKoZIhvcNAQEBBQAEggEAcR9s5y/lrrXeNmPRnSZs7Efy
# uQtpRdWWYaJh7Df1Rjv6jF7HJruPWFnpo6OlZJuh/J0d6dmkpYCGgJGoeQt/b/rS
# kwA+A+TFHu2ZM/xeDsOv9+2WkQ4thLlrxkSF4r7lU4fYQZiD9GawLV/ZmfTuLLHZ
# gjhDqYEqzofrUqyuAUCb45PhUbAmMyTqHgPjUbksHoprO3jH/DBYppKyndFST3Im
# WvfswYNt2jHv6OGBOgeOoU//kjDwTzxs2NipX+6gBmPma3stUX/eoH2R6QbESp8/
# vfHjrGOwA2oYMYprnLbGTPaH4YQyDw0rMWhxgJfNcMCinaUdbSjsvj+IWWFhOqGC
# AgswggIHBgkqhkiG9w0BCQYxggH4MIIB9AIBATByMF4xCzAJBgNVBAYTAlVTMR0w
# GwYDVQQKExRTeW1hbnRlYyBDb3Jwb3JhdGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMg
# VGltZSBTdGFtcGluZyBTZXJ2aWNlcyBDQSAtIEcyAhAOz/Q4yP6/NW4E2GqYGxpQ
# MAkGBSsOAwIaBQCgXTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3
# DQEJBTEPFw0xNjAzMjgyMDQ5NThaMCMGCSqGSIb3DQEJBDEWBBRGHp984mKHkhEZ
# 9LQPMNoLGJ1OCDANBgkqhkiG9w0BAQEFAASCAQCN+WpVse2aXdv/Jq1WQNryhVNX
# gYY00fwTGq/vq7LqOpEvX3z/dLromRIsw55L0Y28TpO/oIf3G1CFk9/Q1pC6RDkh
# qOgz1/FwyXPHFYLdpfIVYOvUncWS2tk6GaH+XzrLWr3E9zj7ZWKrlxcv1Wiz0me2
# SNluyJQm38hEbT6yvSItPBd3WknsAdGssR+rPMRsxOKxsf6vGNiLSoq5T6YpcLyN
# PLOoYdzSq1p/W3q6mHoJShe0rXZJy0RWXokXONq4MowH8kAPPyjg1iWep4xfQurr
# wv6NnCG4Y2XvEyBmtu4Z2adaidg2DGrrRK2L/S6araJnHcrcmb3v1KAPZHY5
# SIG # End signature block
