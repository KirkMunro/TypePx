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

Update-TypeData -Force -TypeName System.Management.Automation.PSModuleInfo -MemberType ScriptMethod -MemberName GetLocalStoragePath -Value {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # If true, returns the module local storage folder for the current user; otherwise, returns the folder for all users
        [System.Boolean]
        $CurrentUser = $false
    )
    try {
        #region Determine where to look for module local storage.

        if ($CurrentUser) {
            $mlsRoot = $env:LocalAppData
        } else {
            # When working with All Users, we use the ProgramData folder instead of the All Users
            # profile.
            $mlsRoot = $env:ProgramData
        }

        #endregion

        #region Return the path based on the root folder and the module name.

        "${mlsRoot}\WindowsPowerShell\Modules\$($this.Name)"

        #endregion
    } catch {
        throw
    }
}
$script:TypeExtensions.AddArrayItem('System.Management.Automation.PSModuleInfo','GetLocalStoragePath')