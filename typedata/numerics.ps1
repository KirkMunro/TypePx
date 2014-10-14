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

$integerTypeNames = @(
    'System.SByte'
    'System.Int16'
    'System.Int32'
    'System.Int64'
    'System.Byte'
    'System.UInt16'
    'System.UInt32'
    'System.UInt64'
)
$numericTypeNames = $integerTypeNames + @(
    'System.Single'
    'System.Double'
)

Add-ScriptMethodData -TypeName $integerTypeNames -ScriptMethodName Times -ScriptBlock {
    [System.Diagnostics.DebuggerStepThrough()]
    param(
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNull()]
        [System.Management.Automation.ScriptBlock]
        $ScriptBlock
    )
    try {
        if ($this -lt 1) {
            $message = . {
                [CmdletBinding()]
                param()
                $PSCmdlet.GetResourceString('Metadata','ValidateRangeSmallerThanMinRangeFailure') -f $this,1
            }
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception,$exception.GetType().Name,'InvalidArgument',$this
            throw $errorRecord
        }
        # This logic properly invokes the script block using lexical scoping in PowerShell 2, but
        # in PowerShell 4 it does not work that way. Wish I knew how to change that behaviour.
        (1..$this).foreach($ScriptBlock)
    } catch {
        if ($ExecutionContext.SessionState.PSVariable.Get('PSCmdlet')) {
            $PSCmdlet.ThrowTerminatingError($_)
        } else {
            throw
        }
    }
}

$timeSpanPropertyScript = @'
    try {
        # Identify the property name and the minimum and maximum values for the property
        `$propertyName = '${PropertyName}'
        `$minValue = ${MinValue}
        `$maxValue = ${MaxValue}
        # Throw an error if the current value is less than the minimum
        if (`$this -lt `$minValue) {
            `$message = . {
                [CmdletBinding()]
                param()
                `$PSCmdlet.GetResourceString('Metadata','ValidateRangeSmallerThanMinRangeFailure') -f `$propertyName,`$minValue
            }
            `$exception = New-Object -TypeName System.ArgumentException -ArgumentList `$message
            `$errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList `$exception,`$exception.GetType().Name,'InvalidArgument',`$this
            throw `$errorRecord
        }
        # Throw an error if the current value is more than the maximum
        if (`$this -gt `$maxValue) {
            `$message = . {
                [CmdletBinding()]
                param()
                `$PSCmdlet.GetResourceString('Metadata','ValidateRangeGreaterThanMaxRangeFailure') -f `$propertyName,`$maxValue
            }
            `$exception = New-Object -TypeName System.ArgumentException -ArgumentList `$message
            `$errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList `$exception,`$exception.GetType().Name,'InvalidArgument',`$this
            throw `$errorRecord
        }
        # Handle the property differently for Years and Months than standard timespan properties
        switch (`$propertyName) {
            'Years' {
                # Calculate the timespan using DateTime arithmetic
                `$now = Get-Date
                if (`$this -ge 0) {
                    `$timeSpan = `$now.AddYears(`$this) - `$now
                } else {
                    `$timeSpan = `$now - `$now.AddYears(`$this)
                }
                # Add an ETS identifier to the timespan
                `$timeSpan.PSTypeNames.Insert(0,'System.TimeSpan#Years')
                # Return the timespan with the TotalYears added to it as a member
                Add-Member -InputObject `$timeSpan -Name TotalYears -MemberType NoteProperty -Value `$this -PassThru
                break
            }
            'Months' {
                # Calculate the timespan using DateTime arithmetic
                `$now = Get-Date
                if (`$this -ge 0) {
                    `$timeSpan = `$now.AddMonths(`$this) - `$now
                } else {
                    `$timeSpan = `$now - `$now.AddMonths(`$this)
                }
                # Add an ETS identifier to the timespan
                `$timeSpan.PSTypeNames.Insert(0,'System.TimeSpan#Months')
                # Return the timespan with the TotalMonths added to it as a member
                Add-Member -InputObject `$timeSpan -Name TotalMonths -MemberType NoteProperty -Value `$this -PassThru
                break
            }
            default {
                # Determine which timespan constructor argument to start with, as well as the starting value
                if (`$propertyName -eq 'Weeks') {
                    `$argumentIndex = 0
                    `$value = `$this * 7
                } else {
                    `$argumentIndex = @('Days','Hours','Minutes','Seconds','Milliseconds').IndexOf(`$propertyName)
                    `$value = `$this
                }
                # Identify the timespan constructor arguments and their maximum values (if any)
                `$argumentList = @(0,0,0,0,0)
                `$argumentMax = @(-1,24,60,60,1000)
                # Set the starting value and calculate the remainder
                `$argumentList[`$argumentIndex] = [System.Math]::Truncate(`$value)
                `$remainder = `$value % 1
                # As long as there is a remainder and we haven't processed all values, calculate and set the next
                # value and then calculate the remainder
                while ((`$remainder -gt 0) -and
                       (`$argumentIndex -lt 4)) {
                    `$argumentIndex++
                    `$value = `$remainder * `$argumentMax[`$argumentIndex]
                    `$argumentList[`$argumentIndex] = [System.Math]::Truncate(`$value)
                    `$remainder = `$value % 1
                }
                # Return the timespan to the caller
                New-Object -TypeName System.TimeSpan -ArgumentList `$argumentList
            }
        }
    } catch {
        if (`$ExecutionContext.SessionState.PSVariable.Get('PSCmdlet')) {
            `$PSCmdlet.ThrowTerminatingError(`$_)
        } else {
            throw
        }
    }
'@

$timeSpanPropertyScriptBlock = Invoke-Snippet -Name String.ToScriptBlock -Parameters @{
            String = $timeSpanPropertyScript
    VariableValues = @{
                     propertyName = 'Years'
                     minValue = -10000
                     maxValue = 10000
                     }
}
Add-ScriptPropertyData -TypeName $integerTypeNames -ScriptPropertyName $propertyName -GetScriptBlock $timeSpanPropertyScriptBlock

$timeSpanPropertyScriptBlock = Invoke-Snippet -Name String.ToScriptBlock -Parameters @{
            String = $timeSpanPropertyScript
    VariableValues = @{
                     propertyName = 'Months'
                     minValue = -120000
                     maxValue = 120000
                     }
}
Add-ScriptPropertyData -TypeName $integerTypeNames -ScriptPropertyName $propertyName -GetScriptBlock $timeSpanPropertyScriptBlock

$timeSpanPropertyScriptBlock = Invoke-Snippet -Name String.ToScriptBlock -Parameters @{
            String = $timeSpanPropertyScript
    VariableValues = @{
                     propertyName = 'Weeks'
                     minValue = [System.Math]::Truncate([System.TimeSpan]::MinValue.TotalDays/7)
                     maxValue = [System.Math]::Truncate([System.TimeSpan]::MaxValue.TotalDays/7)
                     }
}
Add-ScriptPropertyData -TypeName $numericTypeNames -ScriptPropertyName $propertyName -GetScriptBlock $timeSpanPropertyScriptBlock

foreach ($propertyName in 'Days','Hours','Minutes','Seconds','Milliseconds') {
    $timeSpanPropertyScriptBlock = Invoke-Snippet -Name String.ToScriptBlock -Parameters @{
                String = $timeSpanPropertyScript
        VariableValues = @{
                         minValue = [System.Math]::Truncate([System.TimeSpan]::MinValue."Total${propertyName}")
                         maxValue = [System.Math]::Truncate([System.TimeSpan]::MaxValue."Total${propertyName}")
                         }
    }
    Add-ScriptPropertyData -TypeName $numericTypeNames -ScriptPropertyName $propertyName -GetScriptBlock $timeSpanPropertyScriptBlock
}

foreach ($scriptPropertyIdentifier in @('Years','Months','Weeks','Days','Hours','Minutes','Seconds','Milliseconds')) {
    Add-AliasPropertyData -TypeName $numericTypeNames -AliasPropertyName ($scriptPropertyIdentifier -replace 's$') -TargetPropertyName $scriptPropertyIdentifier
}
# SIG # Begin signature block
# MIIZIAYJKoZIhvcNAQcCoIIZETCCGQ0CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUh3WZxbSidA0PXXtcceS0tqDx
# Vx+gghRWMIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
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
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFMLL
# gE0PTWAMPTlAE2K7fMzxm/tsMA0GCSqGSIb3DQEBAQUABIIBABgobZHuW5hO9piD
# GS1xazNiUBGqlFKZKcaMJ43pv9Yc+JmVOz6hJdmt5ZhdEjvu0Bo0VE+lP2nXF3kL
# tbJFIKSjkDIHR1fLjPXJi+DqX0nbb7e7j1GjeuoZZn0EhQqLxT4BkshIjmjw7zh8
# /Lju2QLoP87Ixgxr/mxRxwIEGdDlWLoI4lzDv89RjONag6NxjDAvXQjcVeY6mtvo
# XcKVhVOMaonAvvJsLZA9ibkEf5kndGVodC4XCQicJL4luQfhy7lGoLT22O0PXht8
# t9+ACHOJ03wv28ytknIykqV1LwH1hdRdel9tD/iPeNKQ7wlFo5qmARMZNCop/g4X
# U5yI/ByhggILMIICBwYJKoZIhvcNAQkGMYIB+DCCAfQCAQEwcjBeMQswCQYDVQQG
# EwJVUzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5
# bWFudGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMgIQDs/0OMj+vzVu
# BNhqmBsaUDAJBgUrDgMCGgUAoF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAc
# BgkqhkiG9w0BCQUxDxcNMTQxMDE0MDUxMDUzWjAjBgkqhkiG9w0BCQQxFgQUeFQF
# bWOkBU7Lczr+yMc6vt5YIBwwDQYJKoZIhvcNAQEBBQAEggEAmzt7TN8excvnOW0c
# dF3EmI5LOh3aAuGr3x0Ib/5v9KJHRqt6jD0eL4SciCxWTAnIkGReoaYJOOTd0MrT
# TcfKCafSRuxMUr7o/5Bp/tmBWv+D05csZLeLJUSeoFg/fn0cjDreWGV/To6b11sp
# cBwM7T9BKgAk+dCCOfBjiBpDmGmYX33CH0wmOJjWiavDOjwlvaR7U5cNwEZDSQ8P
# /T7Oo6qQ3PYP8APJUEYiuZCPmHgEmofpBHJCQnJLxaTCILgtsYJqZbAcp096tGFj
# O8xM+sfWjDzqq08tnrAy3N3JikjBGkbDLLpBy5m39bt7DTqPV54k9ySPQn8maYgS
# fzA7Yw==
# SIG # End signature block
