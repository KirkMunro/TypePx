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

Update-TypeData -Force -TypeName System.String -MemberType ScriptMethod -MemberName Expand -Value {
    [System.Diagnostics.DebuggerStepThrough()]
    param()
    try {
        $escapedString = $this.Replace('"','""')
        . $ExecutionContext.InvokeCommand.NewScriptBlock("""${escapedString}""")
    } catch {
        if ($ExecutionContext.SessionState.PSVariable.Get('PSCmdlet')) {
            $PSCmdlet.ThrowTerminatingError($_)
        } else {
            throw
        }
    }
}
$script:TypeExtensions.AddArrayItem('System.String','Expand')

Update-TypeData -Force -TypeName System.String -MemberType ScriptMethod -MemberName MatchAny -Value {
    [System.Diagnostics.DebuggerHidden()]
    param(
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Values
    )
    if ($args) {
        $Values += $args
    }
    $stringToCompare = $this
    $Values.where({$stringToCompare -match $_}).Count -gt 0
}
$script:TypeExtensions.AddArrayItem('System.String','MatchAny')

Update-TypeData -Force -TypeName System.String -MemberType ScriptMethod -MemberName LikeAny -Value {
    [System.Diagnostics.DebuggerHidden()]
    param(
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Values
    )
    if ($args) {
        $Values += $args
    }
    $stringToCompare = $this
    $Values.where({$stringToCompare -like $_}).Count -gt 0
}
$script:TypeExtensions.AddArrayItem('System.String','LikeAny')

Update-TypeData -Force -TypeName System.String -MemberType ScriptMethod -MemberName GetMD5Hash -Value {
    [System.Diagnostics.DebuggerHidden()]
    param()
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($this)
    $hash = $md5.ComputeHash($bytes)
    $sb = New-Object -TypeName System.Text.StringBuilder
    for ($index = 0; $index -lt $hash.Count; $index++) {
        $sb.Append($hash[$index].ToString("x2")) > $null
    }
    $sb.ToString()
}
$script:TypeExtensions.AddArrayItem('System.String','GetMD5Hash')