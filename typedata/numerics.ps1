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

$numericTypes = @(
    [System.SByte]
    [System.Int16]
    [System.Int32]
    [System.Int64]
    [System.Byte]
    [System.UInt16]
    [System.UInt32]
    [System.UInt64]
    [System.Single]
    [System.Double]
)

$timespanPropertyScriptBlock = @'
    try {
        `$propertyName = '${PropertyName}'
        `$minValue = ${MinValue}
        `$maxValue = ${MaxValue}
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
        switch (`$propertyName) {
            'Years' {
                `$now = Get-Date
                if (`$this -ge 0) {
                    `$timeSpan = `$now.AddYears(`$this) - `$now
                } else {
                    `$timeSpan = `$now - `$now.AddYears(`$this)
                }
                `$timeSpan.PSTypeNames.Insert(0,'System.TimeSpan#Years')
                Add-Member -InputObject `$timeSpan -Name TotalYears -MemberType NoteProperty -Value `$this -PassThru
                break
            }
            'Months' {
                `$now = Get-Date
                if (`$this -ge 0) {
                    `$timeSpan = `$now.AddMonths(`$this) - `$now
                } else {
                    `$timeSpan = `$now - `$now.AddMonths(`$this)
                }
                `$timeSpan.PSTypeNames.Insert(0,'System.TimeSpan#Months')
                Add-Member -InputObject `$timeSpan -Name TotalMonths -MemberType NoteProperty -Value `$this -PassThru
                break
            }
            default {
                if (`$propertyName -eq 'Weeks') {
                    `$argumentIndex = 0
                    `$value = `$this * 7
                } else {
                    `$argumentIndex = @('Days','Hours','Minutes','Seconds','Milliseconds').IndexOf(`$propertyName)
                    `$value = `$this
                }
                `$argumentList = @(0,0,0,0,0)
                `$argumentMax = @(-1,24,60,60,1000)
                `$argumentList[`$argumentIndex] = [System.Math]::Truncate(`$value)
                `$remainder = `$value % 1
                while ((`$remainder -gt 0) -and
                       (`$argumentIndex -lt 4)) {
                    `$argumentIndex++
                    `$value = `$remainder * `$argumentMax[`$argumentIndex]
                    `$argumentList[`$argumentIndex] = [System.Math]::Truncate(`$value)
                    `$remainder = `$value % 1
                }
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

foreach ($type in $numericTypes) {
    if (@([System.Double],[System.Single]) -notcontains $type) {
        Update-TypeData -Force -TypeName $type.FullName -MemberType ScriptMethod -MemberName Times -Value {
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
        $script:TypeExtensions.AddArrayItem($type.FullName,'Times')

        $propertyName = 'Years'
        $minValue = -10000
        $maxValue = 10000
        $propertyValue = $ExecutionContext.InvokeCommand.NewScriptBlock($timespanPropertyScriptBlock.Expand())
        Update-TypeData -Force -TypeName $type.FullName -MemberType ScriptProperty -MemberName $propertyName -Value $propertyValue
        $script:TypeExtensions.AddArrayItem($type.FullName,'Years')

        $propertyName = 'Months'
        $minValue = -120000
        $maxValue = 120000
        $propertyValue = $ExecutionContext.InvokeCommand.NewScriptBlock($timespanPropertyScriptBlock.Expand())
        Update-TypeData -Force -TypeName $type.FullName -MemberType ScriptProperty -MemberName $propertyName -Value $propertyValue
        $script:TypeExtensions.AddArrayItem($type.FullName,'Months')
    }

    $propertyName = 'Weeks'
    $minValue = [System.Math]::Truncate([System.TimeSpan]::MinValue.TotalDays/7)
    $maxValue = [System.Math]::Truncate([System.TimeSpan]::MaxValue.TotalDays/7)
    $propertyValue = $ExecutionContext.InvokeCommand.NewScriptBlock($timespanPropertyScriptBlock.Expand())
    Update-TypeData -Force -TypeName $type.FullName -MemberType ScriptProperty -MemberName $propertyName -Value $propertyValue
    $script:TypeExtensions.AddArrayItem($type.FullName,'Weeks')

    foreach ($propertyName in 'Days','Hours','Minutes','Seconds','Milliseconds') {
        $minValue = [System.Math]::Truncate([System.TimeSpan]::MinValue."Total${propertyName}")
        $maxValue = [System.Math]::Truncate([System.TimeSpan]::MaxValue."Total${propertyName}")
        $propertyValue = $ExecutionContext.InvokeCommand.NewScriptBlock($timespanPropertyScriptBlock.Expand())
        Update-TypeData -Force -TypeName $type.FullName -MemberType ScriptProperty -MemberName $propertyName -Value $propertyValue
        $script:TypeExtensions.AddArrayItem($type.FullName,$propertyName)
    }

    foreach ($scriptPropertyIdentifier in @('Years','Months','Weeks','Days','Hours','Minutes','Seconds','Milliseconds')) {
        Update-TypeData -Force -TypeName $type.FullName -MemberType AliasProperty -MemberName ($scriptPropertyIdentifier -replace 's$') -Value $scriptPropertyIdentifier
    }
    $script:TypeExtensions.AddArrayItem($type.FullName,@('Year','Month','Week','Day','Hour','Minute','Second','Millisecond'))
}