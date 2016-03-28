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

$convertToTimeSpanScriptBlock = {
    param(
        [ValidateSet('Years','Months','Weeks','Days','Hours','Minutes','Seconds','Milliseconds')]
        [System.String]
        $TimeSpanUnit
    )
    try {
        # Determine the min/max value based on the unit requested
        switch ($TimeSpanUnit) {
            'Years' {
                $minValue = -10000
                $maxValue = 10000
                break
            }
            'Months' {
                $minValue = -120000
                $maxValue = 120000
                break
            }
            'Weeks' {
                $minValue = [System.Math]::Truncate([System.TimeSpan]::MinValue.TotalDays/7)
                $maxValue = [System.Math]::Truncate([System.TimeSpan]::MaxValue.TotalDays/7)
                break
            }
            default {
                $minValue = [System.Math]::Truncate([System.TimeSpan]::MinValue."Total${TimeSpanUnit}")
                $maxValue = [System.Math]::Truncate([System.TimeSpan]::MaxValue."Total${TimeSpanUnit}")
                break
            }
        }
        # Throw an error if the current value is less than the minimum
        if ($this -lt $MinValue) {
            $message = . {
                [CmdletBinding()]
                param()
                $PSCmdlet.GetResourceString('Metadata','ValidateRangeSmallerThanMinRangeFailure') -f $TimeSpanUnit,$MinValue
            }
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception,$exception.GetType().Name,'InvalidArgument',$this
            throw $errorRecord
        }
        # Throw an error if the current value is more than the maximum
        if ($this -gt $MaxValue) {
            $message = . {
                [CmdletBinding()]
                param()
                $PSCmdlet.GetResourceString('Metadata','ValidateRangeGreaterThanMaxRangeFailure') -f $TimeSpanUnit,$MaxValue
            }
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $exception,$exception.GetType().Name,'InvalidArgument',$this
            throw $errorRecord
        }
        # Handle the property differently for Years and Months than standard timespan properties
        switch ($TimeSpanUnit) {
            'Years' {
                # Calculate the timespan using DateTime arithmetic
                $now = Get-Date
                if ($this -ge 0) {
                    $timeSpan = $now.AddYears($this) - $now
                } else {
                    $timeSpan = $now - $now.AddYears($this)
                }
                # Add an ETS identifier to the timespan
                $timeSpan.PSTypeNames.Insert(0,'System.TimeSpan#Years')
                # Return the timespan with the TotalYears added to it as a member
                Add-Member -InputObject $timeSpan -Name TotalYears -MemberType NoteProperty -Value $this -PassThru
                break
            }
            'Months' {
                # Calculate the timespan using DateTime arithmetic
                $now = Get-Date
                if ($this -ge 0) {
                    $timeSpan = $now.AddMonths($this) - $now
                } else {
                    $timeSpan = $now - $now.AddMonths($this)
                }
                # Add an ETS identifier to the timespan
                $timeSpan.PSTypeNames.Insert(0,'System.TimeSpan#Months')
                # Return the timespan with the TotalMonths added to it as a member
                Add-Member -InputObject $timeSpan -Name TotalMonths -MemberType NoteProperty -Value $this -PassThru
                break
            }
            default {
                # Determine which timespan constructor argument to start with, as well as the starting value
                if ($TimeSpanUnit -eq 'Weeks') {
                    $argumentIndex = 0
                    $value = $this * 7
                } else {
                    $argumentIndex = @('Days','Hours','Minutes','Seconds','Milliseconds').IndexOf($TimeSpanUnit)
                    $value = $this
                }
                # Identify the timespan constructor arguments and their maximum values (if any)
                $argumentList = @(0,0,0,0,0)
                $argumentMax = @(-1,24,60,60,1000)
                # Set the starting value and calculate the remainder
                $argumentList[$argumentIndex] = [System.Math]::Truncate($value)
                $remainder = $value % 1
                # As long as there is a remainder and we haven't processed all values, calculate and set the next
                # value and then calculate the remainder
                while (($remainder -gt 0) -and
                        ($argumentIndex -lt 4)) {
                    $argumentIndex++
                    $value = $remainder * $argumentMax[$argumentIndex]
                    $argumentList[$argumentIndex] = [System.Math]::Truncate($value)
                    $remainder = $value % 1
                }
                # Return the timespan to the caller
                New-Object -TypeName System.TimeSpan -ArgumentList $argumentList
            }
        }
    } catch {
        if ($ExecutionContext.SessionState.PSVariable.Get('PSCmdlet')) {
            $PSCmdlet.ThrowTerminatingError($_)
        } else {
            throw
        }
    }
}
Add-ScriptMethodData -TypeName $integerTypeNames -ScriptMethodName ConvertToTimeSpan -ScriptBlock $convertToTimeSpanScriptBlock

foreach ($timeSpanUnit in @('Years','Months','Weeks','Days','Hours','Minutes','Seconds','Milliseconds')) {
    Add-ScriptPropertyData -TypeName $numericTypeNames -ScriptPropertyName $timeSpanUnit -GetScriptBlock $ExecutionContext.InvokeCommand.NewScriptBlock("`$this.ConvertToTimeSpan('$timeSpanUnit')")
    Add-AliasPropertyData -TypeName $numericTypeNames -AliasPropertyName ($timeSpanUnit -replace 's$') -TargetPropertyName $timeSpanUnit
}

Add-ScriptPropertyData -TypeName $numericTypeNames -ScriptPropertyName Score -GetScriptBlock {$this * 20}