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

Update-TypeData -Force -TypeName System.Security.SecureString -MemberType ScriptMethod -MemberName Peek -Value {
    [System.Diagnostics.DebuggerHidden()]
    param()
    try {
        $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($this)
        [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    } finally {
        if ($bstr -ne $null) {
            [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        }
    }
}
$script:TypeExtensions.AddArrayItem('System.Security.SecureString','Peek')

Update-TypeData -Force -TypeName System.Security.SecureString -MemberType ScriptMethod -MemberName GetMD5Hash -Value {
    [System.Diagnostics.DebuggerHidden()]
    param()
    $this.Peek().GetMD5Hash()
}
$script:TypeExtensions.AddArrayItem('System.Security.SecureString','GetMD5Hash')