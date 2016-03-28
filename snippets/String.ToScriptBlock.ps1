<#
.SYNOPSIS
    Convert a string into a script block
.DESCRIPTION
    Convert a string into a script block, optionally using a set of variable values that will be applied to the string before the conversion.
#>
[System.Diagnostics.DebuggerHidden()]
param(
    # The string you are converting to a script block.
    [System.String]
    $String,

    # An optional hashtable of variable values that you want to use during the conversion.
    [System.Collections.Hashtable]
    $VariableValues = @{}
)
#region Update the local variables if we were passed in any variable values.

foreach ($key in $VariableValues.Keys) {
    Set-Variable -Name $key -Value $VariableValues.$key
}

#endregion

#region Return the script block created from the expanded string.

[System.Management.Automation.ScriptBlock]::Create($ExecutionContext.InvokeCommand.ExpandString($String))

#endregion