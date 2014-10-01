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
license folder that is included in the DebugPx module. If not, see
<https://www.gnu.org/licenses/gpl.html>.
#############################################################################>

Update-TypeData -Force -TypeName System.Array -MemberType ScriptMethod -MemberName ToString -Value {
    [System.Diagnostics.DebuggerHidden()]
    param()
    $ellipsis = ''
    if ($this.Length -gt $FormatEnumerationLimit) {
        $stringArray = $this[0..($FormatEnumerationLimit - 1)] -join ','
        $ellipsis = '...'
    } elseif ($this.Length -gt 0) {
        $stringArray = $this[0..($this.Length - 1)] -join ','
    } else {
        $stringArray = ''
    }
    "{${stringArray}${ellipsis}}"
}
$script:TypeExtensions.AddArrayItem('System.Array','ToString')

Update-TypeData -Force -TypeName System.Array -MemberType ScriptMethod -MemberName Compact -Value {
    [System.Diagnostics.DebuggerHidden()]
    param()
    # The order of the comparison here is very important because @() -ne $null returns nothing.
    ,($this.where({$null -ne $_}) -as $this.GetType())
}
$script:TypeExtensions.AddArrayItem('System.Array','Compact')

Update-TypeData -Force -TypeName System.Array -MemberType ScriptMethod -MemberName Unique -Value {
    [System.Diagnostics.DebuggerHidden()]
    param()
    $uniqueElements = New-Object -TypeName System.Collections.ArrayList
    $this.foreach({if (-not $uniqueElements.Contains($_)) {[void]$uniqueElements.Add($_)}})
    ,($uniqueElements -as $this.GetType())
}
$script:TypeExtensions.AddArrayItem('System.Array','Unique')

Update-TypeData -Force -TypeName System.Array -MemberType ScriptMethod -MemberName Reverse -Value {
    [System.Diagnostics.DebuggerHidden()]
    param()
    if ($this.Length -gt 0) {
        ,($this[-1..-$this.Length] -as $this.GetType())
    } else {
        ,($this -as $this.GetType())
    }
}
$script:TypeExtensions.AddArrayItem('System.Array','Reverse')

Update-TypeData -Force -TypeName System.Array -MemberType ScriptMethod -MemberName Flatten -Value {
    [System.Diagnostics.DebuggerHidden()]
    param(
        [Parameter(Position=0)]
        [ValidateNotNull()]
        [ValidateRange(0,2147483647)]
        [System.Int32]
        $Level
    )
    $flattenedArray = $this
    if ($Level -gt 0) {
        for ($index = 1; $index -le $Level; $index++) {
            $flattenedArray = @($flattenedArray.foreach({$_}))
        }
    } else {
        while ($flattenedArray.where({$_ -is [System.Array]})) {
            $flattenedArray = @($flattenedArray.foreach({$_}))
        }
    }
    ,($flattenedArray -as $this.GetType())
}
$script:TypeExtensions.AddArrayItem('System.Array','Flatten')

Update-TypeData -Force -TypeName System.Array -MemberType ScriptMethod -MemberName Slice -Value {
    [System.Diagnostics.DebuggerHidden()]
    param(
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNull()]
        [ValidateRange(1,2147483647)]
        [System.Int32]
        $Count
    )
    $chunk = New-Object -TypeName System.Collections.ArrayList
    $this.foreach({
        if ($chunk.Count -eq $Count) {
            ,($chunk.ToArray() -as $this.GetType())
            $chunk.Clear()
        }
        $chunk.Add($_) > $null
    })
    if ($chunk.Count) {
        ,($chunk.ToArray() -as $this.GetType())
    }
}
$script:TypeExtensions.AddArrayItem('System.Array','Slice')