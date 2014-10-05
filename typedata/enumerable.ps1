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

$ienumerableBaseTypes = @([System.Collections.ObjectModel.Collection`1[[System.Management.Automation.PSObject,System.Management.Automation, Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35]]])
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
        # I would love to make these more efficient for 3.0, but it is too difficult to work around the
        # limitation of being unable to invoke a script block in its scope while passing it parameters
        # without using a pipeline.
        Update-TypeData -Force -TypeName $ienumerableBaseType.FullName -MemberType ScriptMethod -MemberName foreach -Value {
            [System.Diagnostics.DebuggerStepThrough()]
            param(
                [Parameter(Position=0, Mandatory=$true)]
                [ValidateNotNull()]
                [System.Object]
                $Object
            )
            if ($Object -is [System.Management.Automation.ScriptBlock]) {
                # Process as if we used ForEach-Object
                $this | ForEach-Object -Process $ScriptBlock
            } elseif ($Object -is [System.Type]) {
                # Convert the items in the collection to the type specified
                foreach ($item in $this) {
                    $item -as $Object
                }
            } elseif ($Object -is [System.String]) {
                foreach ($item in $this) {
                    if ($member = $item.PSObject.Members[$Object -as [System.String]]) {
                        if ($member -is [System.Management.Automation.PSMethodInfo]) {
                            # Invoke the method on objects in the collection
                            $member.Invoke($args)
                        } elseif ($member -is [System.Management.Automation.PSPropertyInfo]) {
                            if ($args) {
                                # Set the property on objects in the collection
                                $member.Value = $args
                            } else {
                                # Get the property on objects in the collection
                                $member.Value
                            }
                        }
                    }
                }
            }
        }
        $script:TypeExtensions.AddArrayItem($ienumerableBaseType.FullName,'foreach')

        Update-TypeData -Force -TypeName $ienumerableBaseType.FullName -MemberType ScriptMethod -MemberName where -Value {
            [System.Diagnostics.DebuggerStepThrough()]
            param(
                [Parameter(Position=0, Mandatory=$true)]
                [ValidateNotNull()]
                [System.Management.Automation.ScriptBlock]
                $Expression,

                [Parameter(Position=1)]
                [ValidateNotNullOrEmpty()]
                [ValidateSet('Default','First','Last','SkipUntil','Until','Split')]
                [System.String]
                $Mode = 'Default',

                [Parameter(Position=2)]
                [ValidateNotNull()]
                [ValidateRange(1,[System.Int32]::MaxValue)]
                [System.Int32]
                $NumberToReturn = 0
            )
            switch ($Mode) {
                'First' {
                    # Return the first N objects matching the expression (default to 1)
                    if ($NumberToReturn -eq 0) {
                        $NumberToReturn = 1
                    }
                    $this | Where-Object -FilterScript $Expression | Select-Object -First $NumberToReturn
                    break
                }
                'Last' {
                    # Return the last N objects matching the expression (default to 1)
                    if ($NumberToReturn -eq 0) {
                        $NumberToReturn = 1
                    }
                    $this | Where-Object -FilterScript $Expression | Select-Object -Last $NumberToReturn
                    break
                }
                'SkipUntil' {
                    # Skip until an object matches the expression, then return the first N objects (default to all)
                    $outputCount = 0
                    if ($NumberToReturn -eq 0) {
                        $NumberToReturn = $this.Count
                    }
                    foreach ($item in $this) {
                        if (($outputCount -eq 0) -and -not (Where-Object -InputObject $item -FilterScript $Expression)) {
                            continue
                        }
                        if ($outputCount -lt $NumberToReturn) {
                            $outputCount++
                            $item
                        }
                        if ($outputCount -eq $NumberToReturn) {
                            break
                        }
                    }
                    break
                }
                'Until' {
                    # Return the first N objects until an object matches the expression (default to all)
                    $outputCount = 0
                    if ($NumberToReturn -eq 0) {
                        $NumberToReturn = $this.Count
                    }
                    foreach ($item in $this) {
                        if (Where-Object -InputObject $item -FilterScript $Expression) {
                            break
                        }
                        if ($outputCount -lt $NumberToReturn) {
                            $outputCount++
                            $item
                        }
                        if ($outputCount -eq $NumberToReturn) {
                            break
                        }
                    }
                    break
                }
                'Split' {
                    # Split based on condition, to a maximum count if one was provided (default to all)
                    $collection0 = @()
                    $collection1 = @()
                    if ($NumberToReturn -eq 0) {
                        $NumberToReturn = $this.Count
                    }
                    foreach ($item in $this) {
                        if (($collection0.Count -lt $NumberToReturn) -and
                            (Where-Object -InputObject $item -FilterScript $Expression)) {
                            $collection0 += $item
                        } else {
                            $collection1 += $item
                        }
                    }
                    ,$collection0
                    ,$collection1
                    break
                }
                default {
                    # Filter using the expression, to a maximum count if one was provided (default to all)
                    if ($NumberToReturn -eq 0) {
                        $this | Where-Object -FilterScript $Expression
                    } else {
                        $this | Where-Object -FilterScript $Expression | Select-Object -First $NumberToReturn
                    }
                    break
                }
            }
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
        if ($args) {
            $Values += $args
        }
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
        if ($args) {
            $Values += $args
        }
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
        if ($args) {
            $Values += $args
        }
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
        if ($Property) {
            $this.foreach({$total += $_.$Property})
        } else {
            $this.foreach({$total += $_})
        }
        $total
    }
    $script:TypeExtensions.AddArrayItem($ienumerableBaseType.FullName,'Sum')
}