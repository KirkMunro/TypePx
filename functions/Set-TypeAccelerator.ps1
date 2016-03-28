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
    Replaces the type referenced by a type accelerator with another type.
.DESCRIPTION
    The Set-TypeAccelerator command replaces the type referenced by a type accelerator with another type.

    You must either provide the name of the type accelerator you want to change in the Name parameter or pass the type accelerator you want to change in from the pipeline. The Type parameter contains the new type you want to the type accelerator to reference.
.INPUTS
    String,TypeAccelerator
.OUTPUTS
    TypeAccelerator
.EXAMPLE
    PS C:\> Set-TypeAccelerator -Name PSTypeName -Type System.Management.Automation.PSTypeNameAttribute

    This command points the PSTypeName type accelerator to the System.Management.Automation.PSTypeNameAttribute type in the current session.
.LINK
    Add-TypeAccelerator
.LINK
    Get-TypeAccelerator
.LINK
    Remove-TypeAccelerator
.LINK
    Use-Namespace
#>
function Set-TypeAccelerator {
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType('TypeAccelerator')]
    param(
        # The name of the type accelerator.
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        # The type that the type accelerator will reference.
        [Parameter(Position=1, Mandatory=$true)]
        [ValidateNotNull()]
        [System.Type]
        $Type,

        # Returns an object representing the type accelerator that was updated. By default, this command does not generate any output.
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru
    )
    process {
        try {
            #region Update the specified type accelerator.

            Add-TypeAccelerator @PSBoundParameters

            #endregion
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}

Export-ModuleMember -Function Set-TypeAccelerator

New-Alias -Name stx -Value Set-TypeAccelerator -ErrorAction Ignore
if ($?) {
    Export-ModuleMember -Alias stx
}