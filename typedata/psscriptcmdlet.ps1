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

$typeName = 'System.Management.Automation.PSScriptCmdlet'

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName ThrowException -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The exception to be thrown
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNull()]
        [System.Exception]
        $Exception,

        # The category of the error
        [Parameter(Position=1, Mandatory=$true)]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorCategory]
        $ErrorCategory,

        # An object related to the error
        [Parameter(Position=2)]
        [System.Object]
        $RelatedObject = $null
    )
    try {
        # Throw an error record wrapping the exception
        $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList @(
            $Exception
            $Exception.GetType().Name
            $ErrorCategory
            $RelatedObject
        )
        throw $errorRecord
    } catch {
        $this.ThrowTerminatingError($_)
    }
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName ThrowError -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The error message to be reported to the caller
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Message,

        # The type of exception to be thrown
        [Parameter(Position=1, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ExceptionTypeName,

        # The category of the error
        [Parameter(Position=2, Mandatory=$true)]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorCategory]
        $ErrorCategory,

        # An object related to the error
        [Parameter(Position=3)]
        [System.Object]
        $RelatedObject = $null
    )
    try {
        # Throw an exception
        $exception = New-Object -TypeName $ExceptionTypeName -ArgumentList $Message
        $this.ThrowException($exception, $ErrorCategory, $RelatedObject)
    } catch {
        $this.ThrowTerminatingError($_)
    }
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName ThrowCommandNotFoundError -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The name of the command that was not found
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $CommandName,

        # An object related to the error
        [Parameter(Position=1)]
        [System.Object]
        $RelatedObject = $null
    )
    try {
        # Throw a command not found exception
        $message = $this.GetResourceString('DiscoveryExceptions','CommandNotFoundException') -f $CommandName
        $exception = New-Object -TypeName System.Management.Automation.CommandNotFoundException -ArgumentList $message
        $exception.CommandName = $CommandName
        $this.ThrowException($exception, [System.Management.Automation.ErrorCategory]::ObjectNotFound, $RelatedObject)
    } catch {
        $this.ThrowTerminatingError($_)
    }
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName ValidateParameterDependency -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The name of the parameter that requires other parameters in the same parameter set when it is used
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ParameterName,

        # The list of names of other required parameters
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $RequiredParameterName
    )
    # Make sure we work like a function, without requiring array input.
    if ($args) {
        $IncompatibleParameterName += $args
    }
    try {
        # If the current parameter set contains missing required parameters, throw an exception
        if ($this.MyInvocation.BoundParameters.ContainsKey($ParameterName) -and
            -not @($this.MyInvocation.BoundParameters.Keys).ContainsAny($RequiredParameterName)) {
            $message = "The following parameters are required when using the ${ParameterName} parameter: $($RequiredParameterName -join ',')."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            $this.ThrowException($exception, [System.Management.Automation.ErrorCategory]::InvalidOperation)
        }
    } catch {
        $this.ThrowTerminatingError($_)
    }
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName ValidateParameterIncompatibility -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The name of the parameter that is not compatible with other parameters in the same parameter set
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ParameterName,

        # The list of names of other incompatible parameters
        [Parameter(Position=1, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $IncompatibleParameterName
    )
    # Make sure we work like a function, without requiring array input.
    if ($args) {
        $IncompatibleParameterName += $args
    }
    try {
        # If the current parameter set contains incompatible parameters, throw an exception
        if ($this.MyInvocation.BoundParameters.ContainsKey($ParameterName) -and
            @($this.MyInvocation.BoundParameters.Keys).ContainsAny($IncompatibleParameterName)) {
            $message = "The following parameters may not be used in combination with the ${ParameterName} parameter: $($IncompatibleParameterName -join ',')."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            $this.ThrowException($exception, [System.Management.Automation.ErrorCategory]::InvalidOperation)
        }
    } catch {
        $this.ThrowTerminatingError($_)
    }
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName GetSplattableParameters -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The names of the parameters that you want to splat into other commands.
        [System.String[]]$ParameterName = @()
    )
    # Make sure we work like a function, without requiring array input.
    if ($args) {
        $ParameterName += $args
    }
    # Define the hashtable that will contain the pass thru parameters.
    $splattableParameters = @{}
    # Load the parameters that will be passed through into the hashtable.
    if (-not $ParameterName) {
        # If no specific parameters were requested, splat all bound parameters.
        $splattableParameters = $this.MyInvocation.BoundParameters
    } else {
        # Otherwise, only splat the bound parameters that were requested.
        foreach ($item in $ParameterName) {
            if ($this.MyInvocation.BoundParameters.ContainsKey($item)) {
                $splattableParameters[$item] = $this.MyInvocation.BoundParameters.$item
            }
        }
    }
    # Return the hashtable to the caller.
    $splattableParameters
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName GetBoundPagingParameters -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param()
    # Return the paging parameters in a splattable hashtable.
    $commandMetadata = $this.MyInvocation.MyCommand -as [System.Management.Automation.CommandMetadata]
    if (-not $commandMetadata -or -not $commandMetadata.SupportsPaging) {
        # If paging is not supported for this command, return an empty hashtable.
        @{}
    } else {
        # Otherwise, create a splattable hashtable containing all bound paging parameters.
        $pagingParameterNames = Get-Member -InputObject $this.PagingParameters -MemberType Property | Select-Object -ExpandProperty Name
        $this.GetSplattableParameters($pagingParameterNames)
    }
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName GetBoundShouldProcessParameters -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param()
    # Return the should process parameters in a splattable hashtable.
    $commandMetadata = $this.MyInvocation.MyCommand -as [System.Management.Automation.CommandMetadata]
    if (-not $commandMetadata -or -not $commandMetadata.SupportsShouldProcess) {
        # If should process is not supported for this command, return an empty hashtable.
        @{}
    } else {
        # Otherwise, create a splattable hashtable containing all bound should process parameters.
        $this.GetSplattableParameters(@('Confirm','WhatIf'))
    }
}
# SIG # Begin signature block
# MIIXyQYJKoZIhvcNAQcCoIIXujCCF7YCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUvF/hDLuQRFLIaox5Y5Pa2GsC
# oLKgghL8MIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
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
# AYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUll+dH4CRDQs2
# I1R3CdeiUmakQ7UwDQYJKoZIhvcNAQEBBQAEggEAC27pGRhctHN2tlJXn7xK1QGU
# 4LnHhpdKeCBc7kezvy3LNFG5GCdtXsJn29zKR6S09x92JtMh/C0EWxVkl/RIkCWk
# VTL9pc18Z+elNhT0b5kWYDJtRj0aivK4ym9I6YIuXxB7/xBeBCjl/bhLy7aus+JJ
# eLcN7jraSJht5CTCD9fr8Xwfad7fTLJ3wOEa6fDCuNNz8vWFzafNHex7ZEnJEY0r
# SbTf/hhYrcc3VzKoiNhoX5IE8vNT8Ah77xxVcuV/5ABz6SkCCr61LZfjRCEyoV6u
# gEFefQGAMKjH/Ic2qwT599VxFnV9VP4TiXMT5Nk2gSL7z9Lby5L80R0MvqIJQaGC
# AgswggIHBgkqhkiG9w0BCQYxggH4MIIB9AIBATByMF4xCzAJBgNVBAYTAlVTMR0w
# GwYDVQQKExRTeW1hbnRlYyBDb3Jwb3JhdGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMg
# VGltZSBTdGFtcGluZyBTZXJ2aWNlcyBDQSAtIEcyAhAOz/Q4yP6/NW4E2GqYGxpQ
# MAkGBSsOAwIaBQCgXTAYBgkqhkiG9w0BCQMxCwYJKoZIhvcNAQcBMBwGCSqGSIb3
# DQEJBTEPFw0xNjAzMjgyMDQ5NTlaMCMGCSqGSIb3DQEJBDEWBBSNzr5f8/PdZs5I
# ZYEBURsA3V+S4TANBgkqhkiG9w0BAQEFAASCAQBe5HldI8JMjxDVlGcQFwUeVqBs
# IghrcA93Ff6HVys5cKulm1DHo6jVuO2Ffi7WrkmkNJrSWSC5Q6rWKTc9VMaNaHPQ
# i/ohEfCJogolm8gLuZDjv5t8K7ewx8u6DyaWLa7XUdpVXAXWt68dJU14uynF6Zen
# J2a4UphLGaZXahPTF9XsmFiFaUayhysLKHZWIenr5HIRI0u+tTSIugLdr56wh95S
# OGZpeZXRxeUWvJ+GVKEvonWNsJGY+gFDE4TGmWcOfAStZIlQD2a3wB8dHXEDZvq0
# RGpZF+b9TQFkHhaSCJ1kUGJlUI9Jqy9rb2e76zhqXMka8ePh1ceGUo1sLuTT
# SIG # End signature block
