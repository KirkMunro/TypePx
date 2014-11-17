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

<#
.SYNOPSIS
    Gets the list of type accelerators that are defined in the current session.
.DESCRIPTION
    The Get-TypeAccelerator command gets the list of type accelerators that are defined in the current session.

    By default, Get-TypeAccelerator will return all type accelerators. If you want a filtered list of type accelerators, you can use the Name, Namespace, and/or Type parameters to filter the type accelerators that are returned by Get-TypeAccelerator.
.INPUTS
    None
.OUTPUTS
    TypeAccelerator
.EXAMPLE
    PS C:\> Get-TypeAccelerator

    This command gets a list of all type accelerators that are defined in the current session.
.EXAMPLE
    PS C:\> Get-TypeAccelerator -Name switch

    This command gets the "switch" type accelerator that is defined in the current session.
.EXAMPLE
    PS C:\> Get-TypeAccelerator -Namespace System.Management.Automation

    This command gets any type accelerators that are defined in the current session that reference types belonging to the System.Management.Automation namespace.
.EXAMPLE
    PS C:\> Get-TypeAccelerator -Type System.Management.ManagementObject

    This command gets any type accelerators that are defined in the current session that reference the System.Management.ManagementObject type.
.LINK
    Add-TypeAccelerator
.LINK
    Remove-TypeAccelerator
.LINK
    Set-TypeAccelerator
.LINK
    Use-Namespace
#>
function Get-TypeAccelerator {
    [CmdletBinding()]
    [OutputType('TypeAccelerator')]
    param(
        # The name of the type accelerator.
        [Parameter(Position=0)]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [System.String[]]
        $Name,

        # The namespace containing the type that the type accelerator references.
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [System.String[]]
        $Namespace,

        # The type that the type accelerator references.
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Type[]]
        $Type
    )
    try {
        #region Get all type accelerators.

        $typeAccelerators = $script:typeAcceleratorsType::Get | Select-Object -ExpandProperty Keys | Sort-Object

        #endregion

        #region If -Name was used, filter the list of type accelerators.

        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Name')) {
            $typeAccelerators = @(
                $typeAccelerators.LikeAny($Name)
            )
        }

        #endregion

        #region If -Namespace was used, filter the list of type accelerators.

        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Namespace')) {
            :acceleratorLoop foreach ($key in $typeAccelerators) {
                foreach ($item in $Namespace | ForEach-Object {[System.Text.RegularExpressions.Regex]::Escape($_) -replace '\*','.*' -replace '\?','.'}) {
                    if (($script:typeAcceleratorsType::Get[$key].FullName -match "^$item\.") -or
                        (($item -notmatch '^System\.') -and ($script:typeAcceleratorsType::Get[$key].FullName -match "^System\.$item\."))) {
                        continue acceleratorLoop
                    }
                }
                $typeAccelerators = $typeAccelerators | Where-Object {$_ -ne $key}
            }
        }

        #endregion

        #region If -Type was used, filter the list of type accelerators.

        $filter = {$typeAccelerators -contains $_.Key}
        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Type')) {
            $filter = {($typeAccelerators -contains $_.Key) -and ($Type -contains $_.Value)}
        }

        #endregion

        #region Enumerate all type accelerators and return only those that pass all filters.

        $script:typeAcceleratorsType::Get.GetEnumerator() `
            | Where-Object $filter `
            | Sort-Object -Property Key `
            | ForEach-Object {
                [pscustomobject]@{
                    PSTypeName = 'TypeAccelerator'
                          Name = $_.Key
                          Type = $_.Value
                }
            }

        #endregion
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}

Export-ModuleMember -Function Get-TypeAccelerator

New-Alias -Name gtx -Value Get-TypeAccelerator -ErrorAction Ignore
if ($?) {
    Export-ModuleMember -Alias gtx
}
# SIG # Begin signature block
# MIIZIAYJKoZIhvcNAQcCoIIZETCCGQ0CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUjQX5EmRGeLNOAvY9fEprsnm5
# S2agghRWMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
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
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFJiy
# o1fnfdJVPjPOGDqYVCDle0A9MA0GCSqGSIb3DQEBAQUABIIBAJQlp4THny/eGCf2
# QPiG7hNtolJEbZTfx63nNrbYvNA2KGIrWFV6FeE+FJX86IN5QUfFh1yzFj71dBlv
# xR0+mRiqfJPde7waZb0O+rI129hvxdzGKlZwxiY04m2Ml0EwZ6TdQqOnJK1W0DK8
# VizFMx/uQNnbvIhjFs6o9bmAY7aEgSxvlHa/EslphpscC2aPPkjM9xlBI0yTkdsJ
# QWzHbyU0yUsi3RbXibO4jpw8VZABOqMUhjwL9u5Qj7gkwq3FTumv25Uh5Sq2YD5T
# vdrCu2xzRMG6F2o/tV3DclTIbVk66/IiLcCoEvMzaADd2EvZdodKmbbaKYFVFUWs
# A86A3COhggILMIICBwYJKoZIhvcNAQkGMYIB+DCCAfQCAQEwcjBeMQswCQYDVQQG
# EwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5
# bWFudGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMgIQDs/0OMj+vzVu
# BNhqmBsaUDAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAc
# BgkqhkiG9w0BCQUxDxcNMTQxMTE3MDIyNzEzWjAjBgkqhkiG9w0BCQQxFgQUb/gP
# HoyhbjD76L94CxPrzT/DBGswDQYJKoZIhvcNAQEBBQAEggEAoTU1C6LAHkLLXUAU
# lJxPtjHgpgWzEbYgNZR/glbMDAe5v+IbUlpKKnUYBz0ifZCVdZ/Mrb9Fmu9mEWba
# frr43DhHreVGOKlYaC3LGIBFEBHW9tF7on796FQs2Usx3p6x0GYv2lAs+oEusCH9
# 6MyQC3FxF5tcvTD8xvfZAZsUm8nfU93ol0ko2ZCkMqSXCgvsw31cQ3KpZ8AhRei4
# TXHi6OL/9j+ZkQ8UPRF60moy1f/H/JOC2jQ+zrij0NCdtDrdZsa+/E0J1jz7CsrC
# +RjPE0Jk1vbpDM3/CnSQ1b8Tj6IgiVPT/04B4Ip3M9YRM2xUojcVD7WlOqSiDX9m
# bAQBmw==
# SIG # End signature block
