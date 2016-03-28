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

@{
       ModuleToProcess = 'TypePx.psm1'

         ModuleVersion = '2.0.1.20'

                  GUID = 'cacd8e78-b36a-4c37-90f8-9f8e2879abd6'

                Author = 'Kirk Munro'

           CompanyName = 'Poshoholic Studios'

             Copyright = 'Copyright 2016 Kirk Munro'

           Description = 'The TypePx module adds properties and methods to the most commonly used types to make common tasks easier. Using these type extensions together can provide an enhanced syntax in PowerShell that is both easier to read and self-documenting. TypePx also provides commands to manage type accelerators. Type acceleration also contributes to making scripting easier and they help produce more readable scripts, particularly when using a library of .NET classes that belong to the same namespace.'

     PowerShellVersion = '3.0'

         NestedModules = @(
                         'SnippetPx'
                         )

       AliasesToExport = @(
                         'atx'
                         'gtx'
                         'rtx'
                         'stx'
                         'use'
                         )

     FunctionsToExport = @(
                         'Add-TypeAccelerator'
                         'Get-TypeAccelerator'
                         'Remove-TypeAccelerator'
                         'Set-TypeAccelerator'
                         'Use-Namespace'
                         )

       CmdletsToExport = @()

     VariablesToExport = @()

              FileList = @(
                         'LICENSE'
                         'NOTICE'
                         'TypePx.psd1'
                         'TypePx.psm1'
                         'functions\Add-TypeAccelerator.ps1'
                         'functions\Get-TypeAccelerator.ps1'
                         'functions\Remove-TypeAccelerator.ps1'
                         'functions\Set-TypeAccelerator.ps1'
                         'functions\Use-Namespace.ps1'
                         'helpers\Add-AliasPropertyData.ps1'
                         'helpers\Add-ScriptMethodData.ps1'
                         'helpers\Add-ScriptPropertyData.ps1'
                         'snippets\Dictionary.AddArrayItem.ps1'
                         'snippets\String.Expand.ps1'
                         'snippets\String.ToScriptBlock.ps1'
                         'typedata\array.ps1'
                         'typedata\datetime.ps1'
                         'typedata\dictionary.ps1'
                         'typedata\enumerable.ps1'
                         'typedata\numerics.ps1'
                         'typedata\psmoduleinfo.ps1'
                         'typedata\psscriptcmdlet.ps1'
                         'typedata\securestring.ps1'
                         'typedata\string.ps1'
                         )

           PrivateData = @{
                             PSData = @{
                                 Tags = 'type accelerator extended system ets extensions add-member update-typedata ps1xml'
                                 LicenseUri = 'http://apache.org/licenses/LICENSE-2.0.txt'
                                 ProjectUri = 'https://github.com/KirkMunro/TypePx'
                                 IconUri = ''
                                 ReleaseNotes = @'
- Using a type extension that is defined in this module will not result in the module being auto-loaded because auto-loading only works for commands. If you use this module regularly, you should add the following command to your profile:
Import-Module TypePx
- This module used to be called TypeAccelerator. In order to use this module in an environment where the TypeAccelerator module is installed, you should first uninstall (remove from disk) the TypeAccelerator module.
'@
                             }
                         }
}