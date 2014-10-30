<#############################################################################
The TypePx module adds properties and methods to the most commonly used types
to make common tasks easier. Using these type extensions together can provide
an enhanced syntax in PowerShell that is both easier to read and
self-documenting. TypePx also provides commands to manage type accelerators.
Type acceleration also contributes to making scripting easier and they help
produce more readable scripts, particularly when using a library of .NET
classes that belong to the same namespace.

Copyright 2014 Kirk Munro

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

$typeName = 'System.Collections.Hashtable'

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName ToString -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The format you want to use when converting the hashtable into a multi-line string
        [Parameter(Position=0)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('SingleLine','MultiLine')]
        [System.String]
        $Format = 'SingleLine',

        # The indent you want to use when converting the hashtable into a multi-line string
        [Parameter(Position=1)]
        [ValidateNotNull()]
        [System.Object]
        $Indent = ' ' * 4
    )
    $kvpStrings = @()
    if ($Format -eq 'MultiLine') {
        $kvpSeparator = "`n"
        $newline = "`n"
    } else {
        $Indent = ''
        $kvpSeparator = ';'
        $newline = ''
    }
    foreach ($key in $this.Keys) {
        if (($key -is [System.String]) -and
            ($key -match '\s')) {
            $keyName = "'$($key -replace '''','''''')'"
        } elseif ($key -is [System.Collections.Hashtable]) {
            $keyName = $key.ToString('SingleLine')
        } else {
            $keyName = $key.ToString()
        }
        if ($this[$key] -is [System.Collections.Hashtable]) {
            $valueString = $this[$key].ToString($Format,$Indent)
        } elseif ($this[$key] -is [System.String]) {
            $valueString = "'$($this[$key].ToString() -replace '''','''''')'"
        } else {
            $valueString = $this[$key].ToString()
        }
        if ($Format -eq 'MultiLine') {
            $valueString = $valueString -replace "`r`n|`r|`n","${newline}${Indent}"
            $valueStrings = $valueString -split "${newline}"
            for ($index = 0; $index -lt $valueStrings.Count; $index++) {
                if ($valueStrings[$index].Length -gt ($host.UI.RawUI.BufferSize.Width - 1)) {
                    $valueStrings[$index] = $valueStrings[$index].SubString(0,$host.UI.RawUI.BufferSize.Width - 4) + '...'
                }
            }
            $valueString = $valueStrings -join "${newline}"
        }
        $kvpStrings += "${Indent}${keyName} = ${valueString}"
    }
    "@{${newline}$($kvpStrings -join $kvpSeparator)${newline}}"
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName AddArrayItem -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The hash table key for which you want to add an item to the collection
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNull()]
        [System.Object]
        $Key,

        # The item(s) you want to add to the collection
        [Parameter(Position=1, Mandatory=$true)]
        [AllowNull()]
        [System.Array]
        $Value
    )
    # Add remaining arguments to the value collection for easier invocation
    if ($args) {
        $Value += $args
    }
    # Invoke a snippet to add the item to the collection
    Invoke-Snippet -Name Hashtable.AddArrayItem -Parameters @{
        Hashtable = $this
             Keys = $Key
            Value = $Value
    }
}