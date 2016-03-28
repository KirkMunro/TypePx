﻿<#############################################################################
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

$typeName = 'System.String'

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName Wrap -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The width you want to use when wrapping the string
        [ValidateRange(1,[System.Int32]::MaxValue)]
        [System.Int32]
        $Width = $Host.UI.RawUI.BufferSize.Width
    )
    $this -split "`r`n|`r|`n" -replace "(.{1,${Width}})( +|`$`n?)|(.{1,${Width}})","`$1`$2`n" -replace '^\s+|\s+$' -split "`r`n|`r|`n" -replace '^\s+|\s+$' -join "`n"
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName ToScriptBlock -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # A hashtable of variable values that you want to use during the conversion
        [System.Collections.Hashtable]
        $VariableValues = @{}
    )
    # Invoke a snippet to convert the string to a script block
    . (Get-Module TypePx) Invoke-Snippet -InputObject $script:SnippetCache['String.ToScriptBlock'] -Parameters @{
        String = $this
        VariableValues = $VariableValues
    }
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName Expand -ScriptBlock {
    [System.Diagnostics.DebuggerStepThrough()]
    param()
    # Invoke a method to expand the string
    $ExecutionContext.InvokeCommand.ExpandString($this)
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName MatchAny -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The regular expression strings that you want to compare to the string
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Values
    )
    # Add remaining arguments to the values collection for easier invocation
    if ($args) {
        $Values += $args
    }
    # Return true if any of the regular expression strings match the string; false otherwise
    $stringToCompare = $this
    $Values.where({$stringToCompare -match $_}).Count -gt 0
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName LikeAny -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The wildcard strings that you want to compare to the string
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Values
    )
    # Add remaining arguments to the values collection for easier invocation
    if ($args) {
        $Values += $args
    }
    # Return true if any of the wildcard strings are like the string; false otherwise
    $stringToCompare = $this
    $Values.where({$stringToCompare -like $_}).Count -gt 0
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName IsHtmlEncoded -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param()
    # Return true if the string appears to be fully HTML encoded; false otherwise
    if (-not ('System.Web.HttpUtility')) {
        [System.Reflection.Assembly]::Load('System.Web, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a') > $null
    }
    $decodedString = [System.Web.HttpUtility]::HtmlDecode($this)
    $encodedString = [System.Web.HttpUtility]::HtmlEncode($decodedString)
    $encodedString -eq $this
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName HtmlEncode -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # A flag if you want to force the encoding
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force = $false
    )
    # Return the HTML encoded version of the string
    if (-not ('System.Web.HttpUtility')) {
        [System.Reflection.Assembly]::Load('System.Web, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a') > $null
    }
    if ($Force -or -not $this.IsHtmlEncoded()) {
        [System.Web.HttpUtility]::HtmlEncode($this)
    } else {
        $this
    }
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName HtmlDecode -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param()
    # Return the HTML decoded version of the string
    if (-not ('System.Web.HttpUtility')) {
        [System.Reflection.Assembly]::Load('System.Web, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a') > $null
    }
    [System.Web.HttpUtility]::HtmlDecode($this)
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName GetMD5Hash -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param()
    # Return the MD5 hash of the string
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($this)
    $hash = $md5.ComputeHash($bytes)
    $sb = New-Object -TypeName System.Text.StringBuilder
    for ($index = 0; $index -lt $hash.Count; $index++) {
        $sb.Append($hash[$index].ToString("x2")) > $null
    }
    $sb.ToString()
}
# SIG # Begin signature block
# MIIXyQYJKoZIhvcNAQcCoIIXujCCF7YCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUfBUgc8KX4oC4RA/agb46/5bB
# oe2gghL8MIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
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
# AYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUmvuETFzmKm7q
# XwLgiUVQ+Hm1nSswDQYJKoZIhvcNAQEBBQAEggEAnqAqWRy3wy2/4BCAxwxbLcBy
# caBcQm37nFg5BYSwsDcTCS5CDbRDqOG4/+CE/F2od2aFPuuc5CdfPkSSykzqkoAg
# YLdhOxIyjnSRQY3caJwSWCHgF3Xt6lUi55fP8daRlR48r3VB/40oQpLg6mBxWolI
# REtdVrLSxFM4xIfIXhPE+4Vyihn+5D/2xXPWKh6RaUl7q5xDoZfVWuF+aO8WhMxi
# R8KfF4tr+YD/g4WkqNlqDzb1yVrA4o2+vpcBmoSn+GyXgkEaP8eh6EMUBIsXujIh
# tyBMQWKO+qngTYtwdoXjKzPv0uVP7mE3Un1pJFDTkDx1QpdZx4LccEt2h6rasKGC
# AgswggIHBgkqhkiG9w0BCQYxggH4MIIB9AIBATByMF4xCzAJBgNVBAYTAlVTMR0w
# GwYDVQQKExRTeW1hbnRlYyBDb3Jwb3JhdGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMg
# VGltZSBTdGFtcGluZyBTZXJ2aWNlcyBDQSAtIEcyAhAOz/Q4yP6/NW4E2GqYGxpQ
# MAkGBSsOAwIaBQCgXTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3
# DQEJBTEPFw0xNjAzMjgyMDQ5NTlaMCMGCSqGSIb3DQEJBDEWBBT7zE9X7iNS4Q5v
# RlFxH/vohVXryTANBgkqhkiG9w0BAQEFAASCAQARi3sYcBNfmTFI3rTH/6YEdVjE
# KThr3iSTSDFfCLYv66JpWEaTC/1WHSKnzNc8uyhsBIvjuNTejirHbQVomT4V0kjp
# Q3CjDC+jBKu66tIlWe8BgoHaFpyq+3IWU24i5ntw1RpCGkKQliXI0myggAgqZkS6
# l9OnijaxUW/+8mHaO4kNBFxNpZIwllm1z6NU2hsseo9MkrRbq63BcA3XH5wxPEBP
# Yud3kQ8RfJeKe1uh8xvzvDLwHPRNVCuDKsdf6Khf7MwQnzxH8jRfK7sMaNtc5be5
# TGAhyhoZ64xw9heGKBwKzcOoji/nK8psxkkLVHsI3BBjGKpKeKKqNd7Yf3mp
# SIG # End signature block
