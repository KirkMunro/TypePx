<#
.SYNOPSIS
    Expand all PowerShell variables and subexpressions in a string
.DESCRIPTION
    Expand all PowerShell variables and subexpressions in a string by replacing them with their values at the time of expansion.
#>
[System.Diagnostics.DebuggerHidden()]
param(
    # The string you are expanding.
    [System.String]
    $String
)
#region Double-up on double-quotes so that they are properly escaped.

$escapedString = $String.Replace('"','""')

#endregion

#region Expand all PowerShell variables and subexpressions in the escaped string and return the results.

[System.Management.Automation.ScriptBlock]::Create("""${escapedString}""").Invoke()

#endregion