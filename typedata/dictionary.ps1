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

$typeNames = @(
    'System.Collections.Hashtable'
    'System.Collections.Specialized.OrderedDictionary'
)

Add-ScriptMethodData -TypeName $typeNames -ScriptMethodName ToString -ScriptBlock {
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
        $Indent = ' ' * 4,

        # Reserved for internal use
        [Parameter()]
        [ValidateNotNull()]
        [System.Int32]
        $Reserved = 0
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
    $equals = ' = '
    foreach ($key in $this.Keys) {
        if (($key -is [System.String]) -and
            ($key -match '\s')) {
            $keyName = "'$($key -replace '''','''''')'"
        } elseif ($key -is [System.Collections.Hashtable]) {
            $keyName = $key.ToString('SingleLine')
        } else {
            $keyName = $key.ToString()
        }
        $leadInLength = $Indent.Length * ($Reserved + 1) + $keyName.Length + $equals.Length
        if ($this[$key].GetType().GetInterface('IDictionary',$true)) {
            $valueString = $this[$key].ToString($Format,$Indent,$Reserved + 1)
        } else {
            if ($this[$key] -is [System.String]) {
                $valueString = "'$($this[$key] -replace '''','''''')'"
            } else {
                $valueString = $this[$key].ToString()
            }
            if ($Format -eq 'MultiLine') {
                $valueString = $valueString -replace "`r`n|`r|`n",${newline}
                $valueStrings = @($valueString -split "${newline}")
                for ($index = 0; $index -lt $valueStrings.Count; $index++) {
                    if ($valueStrings[$index].Length -gt ($host.UI.RawUI.BufferSize.Width - 1)) {
                        $valueSpace = $host.UI.RawUI.BufferSize.Width - $leadInLength
                        $valueStrings[$index] = $valueStrings[$index].Wrap($valueSpace - 1)
                    }
                }
                $valueString = $valueStrings -join "${newline}" -replace "`n","`n$(' ' * $leadInLength)"
            }
        }
        $kvpStrings += "$($Indent * ($Reserved + 1))${keyName}${equals}${valueString}"
    }
    "@{${newline}$($kvpStrings -join $kvpSeparator)${newline}$($Indent * $Reserved)}"
}

Add-ScriptMethodData -TypeName $typeNames -ScriptMethodName AddArrayItem -ScriptBlock {
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
    Invoke-Snippet -Name Dictionary.AddArrayItem -Parameters @{
        Dictionary = $this
              Keys = $Key
             Value = $Value
    }
}