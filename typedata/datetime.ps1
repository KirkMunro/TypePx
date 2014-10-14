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

$typeName = 'System.TimeSpan'

Add-ScriptPropertyData -TypeName $typeName -ScriptPropertyName FromNow -GetScriptBlock {
    try {
        # Return the relative time based on the information we have in the TimeSpan object
        if (($this.PSTypeNames -contains 'System.TimeSpan#Years') -and
            (($this.Hours + $this.Minutes + $this.Seconds + $this.Milliseconds) -eq 0)) {
            (Get-Date).AddYears($this.TotalYears)
        } elseif (($this.PSTypeNames -contains 'System.TimeSpan#Months') -and
            (($this.Hours + $this.Minutes + $this.Seconds + $this.Milliseconds) -eq 0)) {
            (Get-Date).AddMonths($this.TotalMonths)
        } else {
            (Get-Date).Add($this)
        }
    } catch {
        if ($ExecutionContext.SessionState.PSVariable.Get('PSCmdlet')) {
            $PSCmdlet.ThrowTerminatingError($_)
        } else {
            throw
        }
    }
}

Add-ScriptPropertyData -TypeName $typeName -ScriptPropertyName Ago -GetScriptBlock {
    try {
        # Return the relative time based on the information we have in the TimeSpan object
        if (($this.PSTypeNames -contains 'System.TimeSpan#Years') -and
            (($this.Hours + $this.Minutes + $this.Seconds + $this.Milliseconds) -eq 0)) {
            (Get-Date).AddYears(-$this.TotalYears)
        } elseif (($this.PSTypeNames -contains 'System.TimeSpan#Months') -and
            (($this.Hours + $this.Minutes + $this.Seconds + $this.Milliseconds) -eq 0)) {
            (Get-Date).AddMonths(-$this.TotalMonths)
        } else {
            (Get-Date).Subtract($this)
        }
    } catch {
        if ($ExecutionContext.SessionState.PSVariable.Get('PSCmdlet')) {
            $PSCmdlet.ThrowTerminatingError($_)
        } else {
            throw
        }
    }
}

$typeName = 'System.DateTime'

Add-ScriptPropertyData -TypeName $typeName -ScriptPropertyName InUtc -GetScriptBlock {
    try {
        # Return the current time in UTC
        $this.ToUniversalTime()
    } catch {
        if ($ExecutionContext.SessionState.PSVariable.Get('PSCmdlet')) {
            $PSCmdlet.ThrowTerminatingError($_)
        } else {
            throw
        }
    }
}