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

$orderedDictionaryTypeName = 'System.Collections.Specialized.OrderedDictionary'

$dictionaryTypeNames = @(
    'System.Collections.Hashtable'
    $orderedDictionaryTypeName
)

Add-ScriptMethodData -TypeName $orderedDictionaryTypeName -ScriptMethodName ContainsKey -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The key that you want to look up in the hashtable
        [Parameter(Position=0)]
        [ValidateNotNull()]
        [System.Object]
        $Key
    )
    # Return true if the specified key is in the dictionary, false otherwise
    $this.Keys -contains $Key
}

Add-ScriptMethodData -TypeName $dictionaryTypeNames -ScriptMethodName ToString -ScriptBlock {
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
    # Create a container to store the string representations of our key-value pairs
    $kvpStrings = @()
    # Identify format string components depending on the format that was chosen
    if ($Format -eq 'MultiLine') {
        $kvpSeparator = "`n"
        $newline = "`n"
        $equals = ' = '
    } else {
        $Indent = ''
        $kvpSeparator = ';'
        $newline = ''
        $equals = '='
    }
    # Convert each key-value pair into its string representation
    foreach ($key in $this.Keys) {
        if (($key -is [System.String]) -and
            ($key -match '\s')) {
            # If the key is a string that contains whitespace, wrap it in quotation marks
            $keyName = "'$($key -replace '''','''''')'"
        } elseif ($key -is [System.Collections.Hashtable]) {
            # If the key is a hashtable, convert it into its single-line string representation
            $keyName = $key.ToString('SingleLine')
        } else {
            # Otherwise, use the default ToString method for the key
            $keyName = $key.ToString()
        }
        if ($this[$key].GetType().GetInterface('IDictionary',$true)) {
            # If the value is a dictionary, recurse
            $valueString = $this[$key].ToString($Format,$Indent,$Reserved + 1)
        } else {
            # Otherwise, convert the value to a string
            if ($this[$key] -is [System.String]) {
                # If the value is a string, wrap it in quotes
                $valueString = "'$($this[$key] -replace '''','''''')'"
            } else {
                # Otherwise, use the default ToString method for the value
                $valueString = $this[$key].ToString()
            }
            if ($Format -eq 'MultiLine') {
                # Determine how much space is required for lead-in (space before all but first line
                # in key-value paris with multi-line values)
                $leadInLength = $Indent.Length * ($Reserved + 1) + $keyName.Length + $equals.Length
                # Normalize newline sequences in the value string
                $valueString = $valueString -replace "`r`n|`r|`n",${newline}
                # Split the value string into an array of value strings
                $valueStrings = @($valueString -split "${newline}")
                for ($index = 0; $index -lt $valueStrings.Count; $index++) {
                    if ($valueStrings[$index].Length -gt ($host.UI.RawUI.BufferSize.Width - $leadInLength - 1)) {
                        # If the length of the string would not fit in the current window, wrap it
                        $valueStrings[$index] = $valueStrings[$index].Wrap($host.UI.RawUI.BufferSize.Width - $leadInLength - 1)
                    }
                }
                # Join the modified value strings together, using lead-in spaces if the value spans
                # multiple lines
                $valueString = $valueStrings -join "${newline}" -replace "`n","`n$(' ' * $leadInLength)"
            }
        }
        # Add the kvp string to the collection
        $kvpStrings += "$($Indent * ($Reserved + 1))${keyName}${equals}${valueString}"
    }
    # Return the string representation of the entire dictionary
    "@{${newline}$($kvpStrings -join $kvpSeparator)${newline}$($Indent * $Reserved)}"
}

Add-ScriptMethodData -TypeName $dictionaryTypeNames -ScriptMethodName AddArrayItem -ScriptBlock {
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
    . (Get-Module TypePx) Invoke-Snippet -InputObject $script:SnippetCache['Dictionary.AddArrayItem'] -Parameters @{
        Dictionary = $this
              Keys = $Key
             Value = $Value
    }
}