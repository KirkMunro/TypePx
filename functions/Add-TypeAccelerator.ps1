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
    Adds or updates a type accelerator in the current session.
.DESCRIPTION
    The Add-TypeAccelerator command adds or updates a type accelerator in the current session.

    By default, Add-TypeAccelerator will add a type accelerator to the current session, overwriting the type accelerator if it already exists. You can use the NoClobber parameter to prevent Add-TypeAccelerator from overwriting a type accelerator that already exists.
.INPUTS
    System.Type
.OUTPUTS
    TypeAccelerator
.NOTES
    To add accelerators for an entire namespace, use the Use-Namespace command.
.EXAMPLE
    PS C:\> Add-TypeAccelerator -Name CommandMetadata -Type System.Management.Automation.CommandMetadata
    PS C:\> New-Object -TypeName CommandMetadata -ArgumentList (Get-Command -Name Stop-Service)

    This command adds a type accelerator for the System.Management.Automation.CommandMetadata class and then uses that accelerator to get the command metadata for the Stop-Service command.
.LINK
    Get-TypeAccelerator
.LINK
    Remove-TypeAccelerator
.LINK
    Set-TypeAccelerator
.LINK
    Use-Namespace
#>
function Add-TypeAccelerator {
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType('TypeAccelerator')]
    param(
        # The name of the type accelerator.
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name,

        # The type that the type accelerator will reference.
        [Parameter(Position=1, Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNull()]
        [System.Type]
        $Type,

        # Will not overwrite a type accelerator if one already exists with the same name. By default, if a type accelerator exists with the same name, Add-TypeAccelerator overwrites the type accelerator without warning.
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $NoClobber,

        # Returns an object representing the type accelerator that was added. By default, this command does not generate any output.
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $PassThru
    )
    process {
        try {
            #region Add the type accelerator if it does not exist or of NoClobber was not used.

            if ((-not $script:TypeAcceleratorsType::Get.ContainsKey($Name)) -or
                (-not $PSCmdlet.MyInvocation.BoundParameters.ContainsKey('NoClobber')) -or
                (-not $NoClobber)) {
                if ($PSCmdlet.ShouldProcess($Name)) {
                    # Since this class changed between versions, we need to figure out which approach to take
                    if (Get-Member -InputObject $script:TypeAcceleratorsType -Name AddReplace -Static -ErrorAction Ignore) {
                        #region Add the new type accelerator.

                        $script:TypeAcceleratorsType::AddReplace($Name, $Type)

                        #endregion
                    } else {
                        #region Remove any existing type accelerator with the same name.

                        if ($script:TypeAcceleratorsType::Get.ContainsKey($Name)) {
                            $script:TypeAcceleratorsType::Remove($Name) > $null
                        }

                        #endregion

                        #region Add the new type accelerator.

                        $script:TypeAcceleratorsType::Add($Name, $Type)

                        #endregion
                    }
                }

                #region Pass the type accelerator object through if requested.

                if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('PassThru') -and $PassThru) {
                    Get-TypeAccelerator -Name $Name
                }

                #endregion
            }

            #endregion
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}

Export-ModuleMember -Function Add-TypeAccelerator

New-Alias -Name atx -Value Add-TypeAccelerator -ErrorAction Ignore
if ($?) {
    Export-ModuleMember -Alias atx
}