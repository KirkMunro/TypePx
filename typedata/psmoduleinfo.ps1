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

$typeName = 'System.Management.Automation.PSModuleInfo'

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName GetLocalStoragePath -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # If true, returns the module local storage folder for the current user; otherwise, returns the folder for all users
        [System.Boolean]
        $CurrentUser = $false
    )
    # Determine where to look for module local storage
    if ($CurrentUser) {
        $mlsRoot = $env:LocalAppData
    } else {
        # When working with All Users, we use the ProgramData folder instead of the All Users profile.
        $mlsRoot = $env:ProgramData
    }
    # Return the path based on the root folder and the module name
    Join-Path -Path $mlsRoot -ChildPath "WindowsPowerShell\Modules\$($this.Name)"
}