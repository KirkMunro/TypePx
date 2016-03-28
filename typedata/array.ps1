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

$typeName = 'System.Array'

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName ToString -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param()
    # A string to capture the ellipsis if it is required
    $ellipsis = ''
    # If we're truncating the array, join the appropriate number of items and add an ellipsis, otherwise
    # simply join the array of items
    if ($this.Length -gt $FormatEnumerationLimit) {
        $stringArray = $this[0..($FormatEnumerationLimit - 1)] -join ','
        $ellipsis = '...'
    } elseif ($this.Length -gt 0) {
        $stringArray = $this[0..($this.Length - 1)] -join ','
    } else {
        $stringArray = ''
    }
    # Return the string to the caller
    "{${stringArray}${ellipsis}}"
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName Compact -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param()
    # Return a strongly typed array with null values filtered out
    # The order of the comparison here is very important because @() -ne $null returns nothing.
    ,($this.where({$null -ne $_}) -as $this.GetType())
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName Unique -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param()
    # An array list of the unique elements in the array
    $uniqueElements = New-Object -TypeName System.Collections.ArrayList
    # Add the unique array elements to the uniqueElements collection
    $this.foreach({if (-not $uniqueElements.Contains($_)) {[void]$uniqueElements.Add($_)}})
    # Return a strongly typed array of unique elements
    ,($uniqueElements -as $this.GetType())
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName Reverse -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param()
    # Return the reversed strongly typed array
    if ($this.Length -gt 0) {
        ,($this[-1..-$this.Length] -as $this.GetType())
    } else {
        ,($this -as $this.GetType())
    }
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName Flatten -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The number of levels to flatten out (by default all levels are flattened)
        [Parameter(Position=0)]
        [ValidateNotNull()]
        [ValidateRange(0,[System.Int32]::MaxValue)]
        [System.Int32]
        $Level = 0
    )
    # The current state of the array
    $flattenedArray = $this
    # A script block to flatten one level of the array
    $flattenOneLevelScriptBlock = {
        $flattenedArray = @($flattenedArray.foreach({$_}))
    }
    # If Level is greater than 0, flatten that number of levels, othewise flatten all levels
    if ($Level -gt 0) {
        for ($index = 1; $index -le $Level; $index++) {
            . $flattenOneLevelScriptBlock
        }
    } else {
        while ($flattenedArray.where({$_ -is [System.Array]})) {
            . $flattenOneLevelScriptBlock
        }
    }
    # Return the strongly typed flattened array
    ,($flattenedArray -as $this.GetType())
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName Slice -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The number of objects to include in each slice
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNull()]
        [ValidateRange(1,[System.Int32]::MaxValue)]
        [System.Int32]
        $Count
    )
    # An array list to hold the current slice
    $slice = New-Object -TypeName System.Collections.ArrayList
    # Define a variable to hold the sliced array results
    $results = @()
    # Iterate through the collection and break it up into slices
    foreach ($item in $this) {
        if ($slice.Count -eq $Count) {
            $results += ,($slice.ToArray() -as $this.GetType())
            $slice.Clear()
        }
        $slice.Add($item) > $null
    }
    # If there are any items left not in a slice, package up all remaining items into a slice and add it to the results
    if ($slice.Count) {
        $results += ,($slice.ToArray() -as $this.GetType())
    }
    # Now return the sliced up array, considering the number of items because of how PowerShell unravels arrays
    if ($results.Count -le 1) {
        ,$results
    } else {
        $results
    }
}