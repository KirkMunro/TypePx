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

<#
.SYNOPSIS
    Adds type accelerators for every exported type in a namespace.
.DESCRIPTION
    The Use-Namespace command adds type accelerators for every exported type in a namespace.

    Type accelerators may be added for namespaces by name or by path. By default, all type accelerators added by this command are permanently added to the session. You may use the ScriptBlock parameter to add the type accelerators for a namespace only for the duration of the invocation of the script block.
.INPUTS
    String,System.IO.File
.OUTPUTS
    None
.EXAMPLE
    PS C:\> Use-TypeAccelerator -Namespace System.Xml

    This command points adds type accelerators for every exported type from the System.Xml namespace.
.EXAMPLE
    PS C:\> Use-Namespace -Namespace System.Windows.Forms -ScriptBlock {
    >> [MessageBox]::Show('Hello world!') > $null
    >> }

    This command points adds type accelerators for every exported type from the System.Xml namespace.
.LINK
    Add-TypeAccelerator
.LINK
    Get-TypeAccelerator
.LINK
    Remove-TypeAccelerator
.LINK
    Set-TypeAccelerator
#>
function Use-Namespace {
    [CmdletBinding(SupportsShouldProcess=$true, DefaultParameterSetName='byName')]
    [OutputType([System.Void])]
    param(
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName='byPath')]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [System.String[]]
        $Path,

        [Parameter(Position=0, Mandatory=$true, ValueFromPipelineByPropertyName=$true, ParameterSetName='byLiteralPath')]
        [ValidateNotNullOrEmpty()]
        [Alias('PSPath')]
        [System.String[]]
        $LiteralPath,

        [Parameter(ParameterSetName='byName', Position=0, Mandatory=$true)]
        [Parameter(ParameterSetName='byPath', Position=1)]
        [Parameter(ParameterSetName='byLiteralPath', Position=1)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Namespace,

        [Parameter(ParameterSetName='byName', Position=1)]
        [Parameter(ParameterSetName='byPath', Position=2)]
        [Parameter(ParameterSetName='byLiteralPath', Position=2)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.ScriptBlock]
        $ScriptBlock,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Alias('As')]
        [System.String]
        $Alias,

        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NoClobber
    )
    begin {
        try {
            #region Load the current type accelerators.

            [System.Collections.Hashtable]$initialTypeAccelerators = $script:TypeAcceleratorsType::Get

            #endregion

            #region Define shared scripts.

            [System.Collections.Hashtable]$sharedScript = @{
                ProcessAssembly = {
                    param(
                        $NamespaceCollection = $null
                    )
                    $assembly.GetExportedTypes() `
                        | Where-Object {
                            $_.IsPublic -or $_.IsNestedPublic
                        } `
                        | ForEach-Object {
                            if ($NamespaceCollection) {
                                $NamespaceCollection = @($NamespaceCollection -replace '^([^,]+),.*$','$1')
                                foreach ($namespaceItem in $NamespaceCollection) {
                                    if (($namespaceItem -notmatch '^System\.') -and ($_.FullName -match "^System\.${namespaceItem}\.")) {
                                        $namespaceItem = "System.${namespaceItem}"
                                    }
                                    if ($_.FullName -match "^${namespaceItem}\.") {
                                        $acceleratorName = $_.Name
                                        if ($_.FullName -ne "${namespaceItem}.${acceleratorName}") {
                                            $acceleratorPrefix = $_.FullName -replace "^${namespaceItem}\.(.+)\.${acceleratorName}`$",'$1'
                                            if ($acceleratorPrefix -ne $_.FullName) {
                                                $acceleratorName = "${acceleratorPrefix}.${acceleratorName}"
                                            }
                                        }
                                        if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Alias')) {
                                            $acceleratorName = "${Alias}.${acceleratorName}"
                                        }
                                        Add-TypeAccelerator -Name $acceleratorName -Type $_
                                        break
                                    }
                                }
                            } else {
                                $acceleratorName = $_.Name
                                if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Alias')) {
                                    $acceleratorName = "${Alias}.${acceleratorName}"
                                }
                                Add-TypeAccelerator -Name $acceleratorName -Type $_
                            }
                        }
                }
            }

            #endregion
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    process {
        try {
            #region Define the requested type accelerators.

            switch ($PSCmdlet.ParameterSetName) {
                'byName' {
                    #region Define type accelerators for the specified namespace(s).

                    foreach ($item in $Namespace) {
                        if ($item -eq 'System') {
                            continue
                        }
                        [System.Reflection.Assembly]$assembly = $null
                        if ($item -match 'PublicKeyToken') {
                            $assembly = [System.Reflection.Assembly]::Load($item)
                        } else {
                            $assembly = [System.Reflection.Assembly]::LoadWithPartialName($item)
                            if ((-not $assembly) -and
                                ($item -notmatch '^System\.')) {
                                $assembly = [System.Reflection.Assembly]::LoadWithPartialName("System.${item}")
                                if ($assembly) {
                                    $item = "System.${item}"
                                }
                            }
                        }
                        if ($assembly) {
                            & $sharedScript.ProcessAssembly -NamespaceCollection $item
                        } else {
                            $assemblies = [System.AppDomain]::CurrentDomain.GetAssemblies() `
                                | Where-Object {
                                    $_.GetTypes() `
                                        | Where-Object {
                                            $_.Namespace -match "^${item}" -or $_.Namespace -match "^System.${item}"
                                        }
                                }
                            foreach ($assembly in $assemblies) {
                                & $sharedScript.ProcessAssembly -NamespaceCollection $item
                            }
                        }
                    }

                    #endregion
                    break
                }
                default {
                    #region Define type accelerators for the specified file(s) and namespace(s).

                    $getItemParameters = $PSCmdlet.GetSplattableParameters(@('Path','LiteralPath'))
                    foreach ($item in Get-Item @getItemParameters) {
                        if ($item -isnot [System.IO.FileInfo]) {
                            continue
                        }
                        [System.Reflection.Assembly]$assembly = [System.Reflection.Assembly]::LoadFrom($item.FullName)
                        if ($assembly) {
                            $passThruParameters = @{}
                            if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Namespace')) {
                                $passThruParameters['NamespaceCollection'] = $Namespace
                            }
                            & $sharedScript.ProcessAssembly @passThruParameters
                        }
                    }

                    #endregion
                    break
                }
            }

            #endregion

            #region If -ScriptBlock was used, invoke it.

            if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('ScriptBlock')) {
                ForEach-Object -Process $ScriptBlock
            }

            #endregion
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
    end {
        try {
            #region If -ScriptBlock was used, reset the type accelerators back to the previous state.

            if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('ScriptBlock')) {
                foreach ($key in @($script:TypeAcceleratorsType::Get | Select-Object -ExpandProperty Keys)) {
                    $script:TypeAcceleratorsType::Remove($key) > $null
                    if ($initialTypeAccelerators.ContainsKey($key)) {
                        if (Get-Member -InputObject $script:TypeAcceleratorsType -Name AddReplace -Static -ErrorAction Ignore) {
                            $script:TypeAcceleratorsType::AddReplace($key, $initialTypeAccelerators[$key])
                        } else {
                            $script:TypeAcceleratorsType::Add($key,$initialTypeAccelerators[$key])
                        }
                    }
                }
            }

            #endregion
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}

Export-ModuleMember -Function Use-Namespace

New-Alias -Name use -Value Use-Namespace -ErrorAction Ignore
if ($?) {
    Export-ModuleMember -Alias use
}