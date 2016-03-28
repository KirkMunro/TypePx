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

#region Set up a module scope trap statement so that terminating errors actually terminate.

trap {throw $_}

#endregion

#region Initialize the module.

Invoke-Snippet -Name Module.Initialize -ModuleName SnippetPx

#endregion

#region Build a cache of the snippets that are used repeatedly in this module.

# Caching snippets greatly improves invocation performance later
$SnippetCache = @{
    'Dictionary.AddArrayItem' = Get-Snippet -Name Dictionary.AddArrayItem -ModuleName $PSModule.Name -NoHelp
    'Dictionary.AddListItem'  = Get-Snippet -Name Dictionary.AddListItem  -ModuleName $PSModule.Name -NoHelp
    'String.ToScriptBlock'    = Get-Snippet -Name String.ToScriptBlock    -ModuleName $PSModule.Name -NoHelp
}

#endregion

#region Import helper (private) function definitions.

Invoke-Snippet -Name ScriptFile.Import -ModuleName SnippetPx -Parameters @{
    Path = Join-Path -Path $PSModuleRoot -ChildPath helpers
}

#endregion

#region Define a hashtable to track the type extensions that are added.

$TypeExtensions = New-Object 'System.Collections.Generic.Dictionary``2[System.String,System.Collections.Generic.List``1[System.Management.Automation.Runspaces.TypeMemberData]]]'

#endregion

#region Add type extension definitions to our hashtable.

Invoke-Snippet -Name ScriptFile.Import -ModuleName SnippetPx -Parameters @{
    Path = Join-Path -Path $PSModuleRoot -ChildPath typedata
}

#endregion

#region Import the type extensions.

$TypeDataCollection = New-Object 'System.Collections.Generic.List``1[System.Management.Automation.Runspaces.TypeData]'
foreach ($key in $TypeExtensions.Keys) {
    $typeData = New-Object -TypeName System.Management.Automation.Runspaces.TypeData -ArgumentList $key
    foreach ($typeMemberData in $TypeExtensions.$key) {
        $typeData.Members.Add($typeMemberData.Name, $typeMemberData)
    }
    $TypeDataCollection.Add($typeData)
}
Update-TypeData -TypeData $TypeDataCollection.ToArray()

#endregion

#region Load the TypeAccelerators internal type.

[System.Type]$TypeAcceleratorsType = [System.Management.Automation.PSObject].Assembly.GetType('System.Management.Automation.TypeAccelerators', $true, $true)

#endregion

#region Import public function definitions.

Invoke-Snippet -Name ScriptFile.Import -ModuleName SnippetPx -Parameters @{
    Path = Join-Path -Path $PSModuleRoot -ChildPath functions
}

#endregion

#region Store the type accelerators when the module is first loaded.

$OldTypeAccelerators = @{}
foreach ($item in @(Get-TypeAccelerator)) {
    $OldTypeAccelerators[$item.Name] = $item.Type
}

#endregion

#region Clean-up the module when it is removed.

$PSModule.OnRemove = {
    #region Reset the type accelerators back to the original list.

    $typeAccelerators = @{}
    foreach ($item in @(Get-TypeAccelerator)) {
        $typeAccelerators[$item.Name] = $item.Type
    }
    foreach ($item in $typeAccelerators.Keys) {
        if (-not $OldTypeAccelerators.ContainsKey($item)) {
            Remove-TypeAccelerator -Name $item
        }
    }
    foreach ($item in $OldTypeAccelerators.Keys) {
        if ($typeAccelerators.ContainsKey($item)) {
            if ($typeAccelerators[$item] -ne $OldTypeAccelerators[$item]) {
                Set-TypeAccelerator -Name $item -Type $OldTypeAccelerators[$item]
            }
        } else {
            Add-TypeAccelerator -Name $item -Type $OldTypeAccelerators[$item]
        }
    }

    #endregion

    #region Remove any type data that this module added to the runspace.

    $indices = @()
    for ($index = 0; $index -lt $Host.Runspace.InitialSessionState.Types.Count; $index++) {
        if ($Host.Runspace.InitialSessionState.Types[$index].FileName) {
            continue
        }
        $typeData = $Host.Runspace.InitialSessionState.Types[$index].TypeData
        if (-not $TypeExtensions.ContainsKey($typeData.TypeName)) {
            continue
        }
        if ($typeData.Members.Count -eq 0) {
            continue
        }
        $etsMembersAdded = @($TypeExtensions[$typeData.TypeName] | Select-Object -ExpandProperty Name)
        $etsMembersFound = @($typeData.Members.Keys | ForEach-Object {$_})
        if (-not (Compare-Object -ReferenceObject $etsMembersAdded -DifferenceObject $etsMembersFound)) {
            $indices += $index
        }
    }
    if ($indices) {
        if (($indices[-1] - $indices[0] + 1) -eq $indices.Count) {
            $Host.Runspace.InitialSessionState.Types.RemoveItem($indices[0], $indices.Count);
        } else {
            for ($index = $indices.Count - 1; $index -ge 0; $index--) {
                $Host.Runspace.InitialSessionState.Types.RemoveItem($indices[$index])
            }
        }
    }
    Update-TypeData

    #endregion
}

#endregion