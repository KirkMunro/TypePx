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

$ienumerableBaseTypes = @()
foreach ($assembly in [System.AppDomain]::CurrentDomain.GetAssemblies()) {
    foreach ($type in $assembly.GetTypes()) {
        if ($type -eq [System.String]) {
            continue
        }
        if ($type.IsPublic -and
            -not $type.IsInterface -and
            (@([System.Object],[System.MarshalByRefObject],[System.ValueType]) -contains $type.BaseType) -and
            ($type.GetInterfaces() -contains [System.Collections.IEnumerable])) {
            $ienumerableBaseTypes += $type
        }
    }
}

foreach ($ienumerableBaseType in $ienumerableBaseTypes) {
    if ($PSVersionTable.PSVersion -lt [System.Version]'4.0') {
        # I would love to make these more efficient for PowerShell 2.0 and 3.0, but it is too difficult to
        # work around the limitation of being unable to invoke a script block in its scope while passing it
        # parameters without using a pipeline.
        Update-TypeData -Force -TypeName $ienumerableBaseType.FullName -MemberType ScriptMethod -MemberName foreach -Value {
            [System.Diagnostics.DebuggerStepThrough()]
            param(
                [Parameter(Position=0, Mandatory=$true)]
                [ValidateNotNull()]
                [System.Management.Automation.ScriptBlock]
                $ScriptBlock
            )
            $this | ForEach-Object -Process $ScriptBlock
        }
        $script:TypeExtensions.AddArrayItem($ienumerableBaseType.FullName,'foreach')

        Update-TypeData -Force -TypeName $ienumerableBaseType.FullName -MemberType ScriptMethod -MemberName where -Value {
            [System.Diagnostics.DebuggerStepThrough()]
            param(
                [Parameter(Position=0, Mandatory=$true)]
                [ValidateNotNull()]
                [System.Management.Automation.ScriptBlock]
                $ScriptBlock
            )
            $this | Where-Object -FilterScript $ScriptBlock
        }
        $script:TypeExtensions.AddArrayItem($ienumerableBaseType.FullName,'where')
    }

    Update-TypeData -Force -TypeName $ienumerableBaseType.FullName -MemberType ScriptMethod -MemberName MatchAny -Value {
        [System.Diagnostics.DebuggerHidden()]
        param(
            [Parameter(Position=0, Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [System.String[]]
            $Values
        )
        ,($this.where({([string]$_).MatchAny($Values)}) -as $this.GetType())
    }
    $script:TypeExtensions.AddArrayItem($ienumerableBaseType.FullName,'MatchAny')

    Update-TypeData -Force -TypeName $ienumerableBaseType.FullName -MemberType ScriptMethod -MemberName LikeAny -Value {
        [System.Diagnostics.DebuggerHidden()]
        param(
            [Parameter(Position=0, Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [System.String[]]
            $Values
        )
        ,($this.where({([string]$_).LikeAny($Values)}) -as $this.GetType())
    }
    $script:TypeExtensions.AddArrayItem($ienumerableBaseType.FullName,'LikeAny')

    Update-TypeData -Force -TypeName $ienumerableBaseType.FullName -MemberType ScriptMethod -MemberName ContainsAny -Value {
        [System.Diagnostics.DebuggerHidden()]
        param(
            [Parameter(Position=0, Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [System.String[]]
            $Values
        )
        [System.Boolean]$matchFound = $false
        foreach ($item in $Values) {
            if ($this -contains $item) {
                $matchFound = $true
                break
            }
        }
        $matchFound
    }
    $script:TypeExtensions.AddArrayItem($ienumerableBaseType.FullName,'ContainsAny')

    Update-TypeData -Force -TypeName $ienumerableBaseType.FullName -MemberType ScriptMethod -MemberName Sum -Value {
        [System.Diagnostics.DebuggerHidden()]
        param(
            [Parameter(Position=0)]
            [ValidateNotNull()]
            [System.String]
            $Property
        )
        $total = $null
        if ($Property) {            $this.foreach({$total += $_.$Property})        } else {            $this.foreach({$total += $_})        }        $total    }
    $script:TypeExtensions.AddArrayItem($ienumerableBaseType.FullName,'Sum')
}