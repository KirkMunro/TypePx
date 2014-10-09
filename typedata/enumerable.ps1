<#############################################################################
The TypePx module adds properties and methods to the most commonly used types
to make common tasks easier. Using these type extensions together can provide
an enhanced syntax in PowerShell that is both easier to read and self-
documenting. TypePx also provides commands to manage type accelerators. Type
acceleration also contributes to making scripting easier and they help produce
more readable scripts, particularly when using a library of .NET classes that
belong to the same namespace.

Copyright © 2014 Kirk Munro.

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License in the
license folder that is included in the DebugPx module. If not, see
<https://www.gnu.org/licenses/gpl.html>.
#############################################################################>

$ienumerableBaseTypes = @(
    [System.Collections.ObjectModel.Collection`1[System.Object]]
    [System.Collections.ObjectModel.Collection`1[System.Management.Automation.PSObject]]
)
foreach ($assembly in [System.AppDomain]::CurrentDomain.GetAssemblies()) {
    foreach ($type in $assembly.GetTypes()) {
        if ($type -eq [System.String]) {
            continue
        }
        if ($type.IsPublic -and
            -not $type.IsInterface -and
            (@([System.Object],[System.MarshalByRefObject],[System.ValueType]) -contains $type.BaseType) -and
            ($type.GetInterfaces() -contains [System.Collections.IEnumerable])) {
            $ienumerableBaseTypes += $type
        }
    }
}

foreach ($ienumerableBaseType in $ienumerableBaseTypes) {
    if ($PSVersionTable.PSVersion -lt [System.Version]'4.0') {
        # I would love to make these more efficient for 3.0, but it is too difficult to work around the
        # limitation of being unable to invoke a script block in its scope while passing it parameters
        # without using a pipeline.
        Update-TypeData -Force -TypeName $ienumerableBaseType.FullName -MemberType ScriptMethod -MemberName foreach -Value {
            [System.Diagnostics.DebuggerStepThrough()]
            param(
                [Parameter(Position=0, Mandatory=$true)]
                [ValidateNotNull()]
                [System.Object]
                $Object
            )
            $results = @()
            if ($Object -is [System.Management.Automation.ScriptBlock]) {
                # Process as if we used ForEach-Object
                $results = $this | ForEach-Object -Process $Object
            } elseif ($Object -is [System.Type]) {
                # Convert the items in the collection to the type specified
                foreach ($item in $this) {
                    $results += $item -as $Object
                }
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
            if ($results) {
                $results = $results -as [System.Collections.ObjectModel.Collection`1[System.Object]]
                ,$results
            }
        }
        $script:TypeExtensions.AddArrayItem($ienumerableBaseType.FullName,'foreach')

        Update-TypeData -Force -TypeName $ienumerableBaseType.FullName -MemberType ScriptMethod -MemberName where -Value {
            [System.Diagnostics.DebuggerStepThrough()]
            param(
                [Parameter(Position=0, Mandatory=$true)]
                [ValidateNotNull()]
                [System.Management.Automation.ScriptBlock]
                $Expression,

                [Parameter(Position=1)]
                [ValidateNotNullOrEmpty()]
                [ValidateSet('Default','First','Last','SkipUntil','Until','Split')]
                [System.String]
                $Mode = 'Default',

                [Parameter(Position=2)]
                [ValidateNotNull()]
                [ValidateRange(0,[System.Int32]::MaxValue)]
                [System.Int32]
                $NumberToReturn = 0
            )
            $results = @()
            switch ($Mode) {
                'First' {
                    # Return the first N objects matching the expression (default to 1)
                    if ($NumberToReturn -eq 0) {
                        $NumberToReturn = 1
                    }
                    $results = $this | Where-Object -FilterScript $Expression | Select-Object -First $NumberToReturn
                    break
                }
                'Last' {
                    # Return the last N objects matching the expression (default to 1)
                    if ($NumberToReturn -eq 0) {
                        $NumberToReturn = 1
                    }
                    $results = $this | Where-Object -FilterScript $Expression | Select-Object -Last $NumberToReturn
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
                    $collection0 = $collection0 -as [System.Collections.ObjectModel.Collection`1[System.Object]]
                    $collection1 = $collection1 -as [System.Collections.ObjectModel.Collection`1[System.Object]]
                    $results = @($collection0,$collection1)
                    break
                }
                default {
                    # Filter using the expression, to a maximum count if one was provided (default to all)
                    if ($NumberToReturn -eq 0) {
                        $results = $this | Where-Object -FilterScript $Expression
                    } else {
                        $results = $this | Where-Object -FilterScript $Expression | Select-Object -First $NumberToReturn
                    }
                    break
                }
            }
            if ($results) {
                $results = $results -as [System.Collections.ObjectModel.Collection`1[System.Object]]
                ,$results
            }
        }
        $script:TypeExtensions.AddArrayItem($ienumerableBaseType.FullName,'where')
    }

    Update-TypeData -Force -TypeName $ienumerableBaseType.FullName -MemberType ScriptMethod -MemberName MatchAny -Value {
        [System.Diagnostics.DebuggerHidden()]
        param(
            [Parameter(Position=0, Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [System.String[]]
            $Values
        )
        if ($args) {
            $Values += $args
        }
        ,($this.where({([string]$_).MatchAny($Values)}) -as $this.GetType())
    }
    $script:TypeExtensions.AddArrayItem($ienumerableBaseType.FullName,'MatchAny')

    Update-TypeData -Force -TypeName $ienumerableBaseType.FullName -MemberType ScriptMethod -MemberName LikeAny -Value {
        [System.Diagnostics.DebuggerHidden()]
        param(
            [Parameter(Position=0, Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [System.String[]]
            $Values
        )
        if ($args) {
            $Values += $args
        }
        ,($this.where({([string]$_).LikeAny($Values)}) -as $this.GetType())
    }
    $script:TypeExtensions.AddArrayItem($ienumerableBaseType.FullName,'LikeAny')

    Update-TypeData -Force -TypeName $ienumerableBaseType.FullName -MemberType ScriptMethod -MemberName ContainsAny -Value {
        [System.Diagnostics.DebuggerHidden()]
        param(
            [Parameter(Position=0, Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [System.String[]]
            $Values
        )
        [System.Boolean]$matchFound = $false
        if ($args) {
            $Values += $args
        }
        foreach ($item in $Values) {
            if ($this -contains $item) {
                $matchFound = $true
                break
            }
        }
        $matchFound
    }
    $script:TypeExtensions.AddArrayItem($ienumerableBaseType.FullName,'ContainsAny')

    Update-TypeData -Force -TypeName $ienumerableBaseType.FullName -MemberType ScriptMethod -MemberName Sum -Value {
        [System.Diagnostics.DebuggerHidden()]
        param(
            [Parameter(Position=0)]
            [ValidateNotNull()]
            [System.String]
            $Property
        )
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
    $script:TypeExtensions.AddArrayItem($ienumerableBaseType.FullName,'Sum')
}
# SIG # Begin signature block
# MIIZIAYJKoZIhvcNAQcCoIIZETCCGQ0CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUMxx+3UfQaMWSprziXfMRI0oF
# yVegghRWMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
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
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFNfT
# msjB2bhp5fGlrEjkoseN5Qy+MA0GCSqGSIb3DQEBAQUABIIBAD/UzF4nJCKuoO5k
# qsCKSXBQZDu8Yy418/HjOHKzQ75HTkPS2Uk/9pagG/OJuc+3t59vgYMYcvX9PRhZ
# dxHhzAA5LAZHlvoJt1RjJ2dD8o/D1IP0VI2GA1P0Xv1KgXDwqmfEmWU1er1fGuzW
# wW4fTNln8RSkM0dz0vkO9BYwJxVmbuASOcjJOuoexuBE5KH1RFiytWt0DMHULUGv
# q/+zIOgMWWnaP7DLE874RSCNm5GVaDA5od1T/ZVE7apLlc+WVWXgtfefvwnqDOGo
# cLfAHoEtVK3Tib0L/AxzUV1Z8SkZTcY6NvxndCBMKGJC9dRLcYJBqFtdMP8erUNT
# h9Eqg42hggILMIICBwYJKoZIhvcNAQkGMYIB+DCCAfQCAQEwcjBeMQswCQYDVQQG
# EwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5
# bWFudGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMgIQDs/0OMj+vzVu
# BNhqmBsaUDAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAc
# BgkqhkiG9w0BCQUxDxcNMTQxMDA5MTk1NzMxWjAjBgkqhkiG9w0BCQQxFgQUg0f4
# bZnWI8BZ5wmLm1bnp8tyXNgwDQYJKoZIhvcNAQEBBQAEggEAk64nm2a8DonlVt0f
# cWZWprsH+0Zs9vZwIrC2beks+pueuEOm+CftdJwZTQwx7Yue/65+2Kyeutt2ynU/
# LysHEMIK2LUvSZ4n+zVZRMxHkyHqY157N7vS/9KytJFgHe94E1WrLSxINcdgvXji
# p7403hYnGoLbo6E69EBHmisw95jJeVM5RoK2otfZVnFbHfouZK9xaMTSXLvpxlP3
# /Wc5MmduBtU+Glct4mLdeL3nNmfZtFG4fywhDw7gfvFmd8NptTNKPr5kMSQhSytl
# mwlhvXkV7URla9C2U3EjqsJ/ZezjGTxxVij42phBLNSut2ovdO9yO1CNBRVfDQ12
# IFIbZw==
# SIG # End signature block
