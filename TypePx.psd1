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
license folder that is included in the ScsmPx module. If not, see
<https://www.gnu.org/licenses/gpl.html>.
#############################################################################>

@{
      ModuleToProcess = 'TypePx.psm1'

        ModuleVersion = '2.0.0.10'

                 GUID = 'cacd8e78-b36a-4c37-90f8-9f8e2879abd6'

               Author = 'Kirk Munro'

          CompanyName = 'Poshoholic Studios'

            Copyright = '© 2014 Kirk Munro'

          Description = 'The TypePx module adds properties and methods to the most commonly used types to make common tasks easier. Using these type extensions together can provide an enhanced syntax in PowerShell that is both easier to read and self-documenting. TypePx also provides commands to manage type accelerators. Type acceleration also contributes to making scripting easier and they help produce more readable scripts, particularly when using a library of .NET classes that belong to the same namespace.'

    PowerShellVersion = '3.0'

      RequiredModules = @(
                        'SnippetPx'
                        )

    FunctionsToExport = @(
                        'Add-TypeAccelerator'
                        'Get-TypeAccelerator'
                        'Remove-TypeAccelerator'
                        'Set-TypeAccelerator'
                        'Use-Namespace'
                        )

      AliasesToExport = @(
                        'atx'
                        'gtx'
                        'rtx'
                        'stx'
                        'use'
                        )

             FileList = @(
                        'TypePx.psd1'
                        'TypePx.psm1'
                        'functions\Add-TypeAccelerator.ps1'
                        'functions\Get-TypeAccelerator.ps1'
                        'functions\Remove-TypeAccelerator.ps1'
                        'functions\Set-TypeAccelerator.ps1'
                        'functions\Use-Namespace.ps1'
                        'scripts\Install-TypePxModule.ps1'
                        'scripts\Uninstall-TypePxModule.ps1'
                        'typedata\array.ps1'
                        'typedata\datetime.ps1'
                        'typedata\enumerable.ps1'
                        'typedata\hashtable.ps1'
                        'typedata\numerics.ps1'
                        'typedata\psmoduleinfo.ps1'
                        'typedata\psscriptcmdlet.ps1'
                        'typedata\securestring.ps1'
                        'typedata\string.ps1'
                        'license\gpl-3.0.txt'
                        )

          PrivateData = @{
                            PSData = @{
                                Tags = 'type accelerator extended system ets extensions add-member update-typedata ps1xml'
                                LicenseUri = 'http://www.gnu.org/licenses/gpl-3.0.html'
                                ProjectUri = 'https://github.com/KirkMunro/TypePx'
                                IconUri = ''
                                ReleaseNotes = @'
- Using a type extension that is defined in this module will not result in the module being auto-loaded because auto-loading only works for commands. If you use this module regularly, you should add the following command to your profile:
Import-Module TypePx
- This module used to be called TypeAccelerator. In order to use this module in an environment where the TypeAccelerator module is installed, you should first uninstall (remove from disk) the TypeAccelerator module.
'@
                            }
                        }
}
# SIG # Begin signature block
# MIIZIAYJKoZIhvcNAQcCoIIZETCCGQ0CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUcy44SIqG/upDwSOY3JMp1R3P
# 5SCgghRWMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
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
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFIRA
# g7o/xed8uD4IbXH/MfU1nPpUMA0GCSqGSIb3DQEBAQUABIIBABElDjw60KWa46v5
# 2/fNbhcT7yoS8qmOGWo0gVSxOKrJaHHiV5kFler27pwnrBSQAdTDABTMs6vnhtkB
# hzShGW5tD6cu4NNRJXSk7ypJgV0Rac/jIzsAYj9v81Un7MoS0LknGsdI2SYnG6RX
# 5vWgoWYBiUBl7tXz6NJKlmJB33yjQM/qfx6CCF5iM8zK1+q9dgS1HTcnqClE3HjN
# WEaSiYawRFy+G/wdBEUJ58vOV1EX2FhZWbsxPad0UsErzUJsW8cMfBM4n8E+dED1
# 3bCtA+Nxs7xLEobLLReg3zTgn+HNzgjIEsR1omzGdrS/CXp7NtUBi+9TBkoLQkHg
# IeTSBS2hggILMIICBwYJKoZIhvcNAQkGMYIB+DCCAfQCAQEwcjBeMQswCQYDVQQG
# EwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5
# bWFudGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMgIQDs/0OMj+vzVu
# BNhqmBsaUDAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAc
# BgkqhkiG9w0BCQUxDxcNMTQxMDA5MTk1NzMwWjAjBgkqhkiG9w0BCQQxFgQUt1Rd
# YRMpTuoBC3ip0U+RwJhPpk4wDQYJKoZIhvcNAQEBBQAEggEALbKQWhw0DnFD4yPP
# o1ZP/7N5r3aM7CT6RfGNE8eQsTGsTyPlo2MpEE3QMzfi4hDG+5BIVUfYSeo4C8Eq
# G3yAMzt6pFBAiqF2C1zbduJosbZIcmKt+RXwbIBbSULUUZecnaJPID7D1cZOwsyQ
# UOp17k1bec67sk7L1V9uZjlyK7cU2HcNdh7difxx9G8Dmikyc3lEcCDjeNQInPEq
# ey9coayPDgtl1et+u6MsEy5F9Gm/LUxFCKfvMmDqnfygI6oOQYvfrC8jqTAaVwaH
# p1ZkotSyKgxJPtEo86dtLSISeet6CFwrPFrRz3CL4ZptwhYWT+pcbDCkxBMOogQZ
# tkJzzw==
# SIG # End signature block
