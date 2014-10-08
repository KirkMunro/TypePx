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
license folder that is included in the ScsmPx module. If not, see
<https://www.gnu.org/licenses/gpl.html>.
#############################################################################>

@{
      ModuleToProcess = 'TypePx.psm1'

        ModuleVersion = '2.0.0.7'

                 GUID = 'cacd8e78-b36a-4c37-90f8-9f8e2879abd6'

               Author = 'Kirk Munro'

          CompanyName = 'Poshoholic Studios'

            Copyright = '© 2014 Kirk Munro'

          Description = 'The TypePx module adds properties and methods to the most commonly used types to make common tasks easier. Using these type extensions together can provide an enhanced syntax in PowerShell that is both easier to read and self-documenting. TypePx also provides commands to manage type accelerators. Type acceleration also contributes to making scripting easier and they help produce more readable scripts, particularly when using a library of .NET classes that belong to the same namespace.'

    PowerShellVersion = '3.0'

      RequiredModules = @(
                        'SnippetPx'
                        )

    FunctionsToExport = @(
                        'Add-TypeAccelerator'
                        'Get-TypeAccelerator'
                        'Remove-TypeAccelerator'
                        'Set-TypeAccelerator'
                        'Use-Namespace'
                        )

      AliasesToExport = @(
                        'atx'
                        'gtx'
                        'rtx'
                        'stx'
                        'use'
                        )

             FileList = @(
                        'TypePx.psd1'
                        'TypePx.psm1'
                        'functions\Add-TypeAccelerator.ps1'
                        'functions\Get-TypeAccelerator.ps1'
                        'functions\Remove-TypeAccelerator.ps1'
                        'functions\Set-TypeAccelerator.ps1'
                        'functions\Use-Namespace.ps1'
                        'scripts\Install-TypePxModule.ps1'
                        'scripts\Uninstall-TypePxModule.ps1'
                        'typedata\array.ps1'
                        'typedata\datetime.ps1'
                        'typedata\enumerable.ps1'
                        'typedata\hashtable.ps1'
                        'typedata\numerics.ps1'
                        'typedata\psmoduleinfo.ps1'
                        'typedata\psscriptcmdlet.ps1'
                        'typedata\securestring.ps1'
                        'typedata\string.ps1'
                        'license\gpl-3.0.txt'
                        )
}