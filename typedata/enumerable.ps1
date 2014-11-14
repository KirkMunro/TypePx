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

$commonlyUsedGenericTypeParameters = @(
    [System.Management.Automation.PSObject]
    [System.Object]
    [System.String]
    [System.Int32]
    [System.Int64]
)
$typeNames = @()
foreach ($assembly in [System.AppDomain]::CurrentDomain.GetAssemblies()) {
    foreach ($type in $assembly.GetTypes()) {
        # If the type is not public or if it is an interface, skip it
        if ((-not $type.IsPublic) -or $type.IsInterface) {
            continue
        }
        # If the type is String or XmlNode, skip it (these are exceptions in PowerShell)
        if (@([System.String],[System.Xml.XmlNode]) -contains $type) {
            continue
        }
        # If the type does not implement IEnumerable or it implements IDictionary, skip it
        $interfaces = $type.GetInterfaces()
        if (($interfaces -notcontains [System.Collections.IEnumerable]) -or
            ($interfaces -contains [System.Collections.IDictionary])) {
            continue
        }
        # If the base type is not Object, MarshalByRefObject, or ValueType, skip it
        if (@([System.Object],[System.MarshalByRefObject],[System.ValueType]) -notcontains $type.BaseType) {
            continue
        }
        # If the type definition is generic, add a collection of common generic types to our
        # enumerable type collection; otherwise, just add the type
        if ($type.IsGenericTypeDefinition) {
            foreach ($typeParameter in $commonlyUsedGenericTypeParameters) {
                $typeNames += "$($type.FullName)[[$($typeParameter.AssemblyQualifiedName)]]"
            }
        } else {
            $typeNames += $type.FullName
        }
    }
}

if ($PSVersionTable.PSVersion -lt [System.Version]'4.0') {
    Add-ScriptMethodData -TypeName $typeNames -ScriptMethodName foreach -ScriptBlock {
        [System.Diagnostics.DebuggerStepThrough()]
        param(
            # A script block (expression), type (conversion type), or string (property or method name)
            [Parameter(Position=0, Mandatory=$true)]
            [ValidateNotNull()]
            [System.Object]
            $Object
        )
        # Create an array to hold the results
        $results = @()
        if ($Object -is [System.Management.Automation.ScriptBlock]) {
            # Process as if we used ForEach-Object
            # I would love to make this more efficient for 3.0, but it is too difficult to work around the
            # limitation of being unable to invoke a script block in its scope while passing it parameters
            # without using a pipeline.
            $passThruParameters = @{
                Process = $Object
            }
            if ($args) {
                $passThruParameters['ArgumentList'] = $args
            }
            $results = @($this | ForEach-Object @passThruParameters)
        } elseif ($Object -is [System.Type]) {
            # Convert the items in the collection to the type specified
            foreach ($item in $this) {
                $results += $item -as $Object
            }
            $results = $results -as ("System.Collections.ObjectModel.Collection``1[$($Object.FullName)]" -as [System.Type])
        } elseif ($Object -is [System.String]) {
            foreach ($item in $this) {
                if ($member = $item.PSObject.Members[$Object -as [System.String]]) {
                    if ($member -is [System.Management.Automation.PSMethodInfo]) {
                        # Invoke the method on objects in the collection
                        if ($result = $member.Invoke($args)) {
                            $results += $result
                        }
                    } elseif ($member -is [System.Management.Automation.PSPropertyInfo]) {
                        if ($args) {
                            # Set the property on objects in the collection
                            $member.Value = $args
                        } else {
                            # Get the property on objects in the collection
                            $results += $member.Value
                        }
                    }
                }
            }
        }
        if ($Object -isnot [System.Type]) {
            # Return the results in an objectmodel collection to the caller
            if ($results) {
                $results = $results -as [System.Management.Automation.PSObject[]] -as [System.Collections.ObjectModel.Collection`1[System.Management.Automation.PSObject]]
            } else {
                $results = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[System.Management.Automation.PSObject]]'
            }
        }
        ,$results
    }

    Add-ScriptMethodData -TypeName $typeNames -ScriptMethodName where -ScriptBlock {
#        [System.Diagnostics.DebuggerStepThrough()]
        param(
            # The conditional expression that we are evaluating
            [Parameter(Position=0, Mandatory=$true)]
            [ValidateNotNull()]
            [System.Management.Automation.ScriptBlock]
            $Expression,

            # The evaluation mode
            [Parameter(Position=1)]
            [ValidateNotNullOrEmpty()]
            [ValidateSet('Default','First','Last','SkipUntil','Until','Split')]
            [System.String]
            $Mode = 'Default',

            # The number of objects to return
            [Parameter(Position=2)]
            [ValidateNotNull()]
            [ValidateRange(0,[System.Int32]::MaxValue)]
            [System.Int32]
            $NumberToReturn = 0
        )
        # Create an array to hold the results
        $results = @()
        switch ($Mode) {
            'First' {
                # Return the first N objects matching the expression (default to 1)
                if ($NumberToReturn -eq 0) {
                    $NumberToReturn = 1
                }
                $results = @($this | Where-Object -FilterScript $Expression | Select-Object -First $NumberToReturn)
                break
            }
            'Last' {
                # Return the last N objects matching the expression (default to 1)
                if ($NumberToReturn -eq 0) {
                    $NumberToReturn = 1
                }
                $results = @($this | Where-Object -FilterScript $Expression | Select-Object -Last $NumberToReturn)
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
                        $results += $item
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
                        $results += $item
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
                $collection0 = $collection0 -as [System.Management.Automation.PSObject[]] -as [System.Collections.ObjectModel.Collection`1[System.Management.Automation.PSObject]]
                $collection1 = $collection1 -as [System.Management.Automation.PSObject[]] -as [System.Collections.ObjectModel.Collection`1[System.Management.Automation.PSObject]]
                $results = @($collection0,$collection1)
                break
            }
            default {
                # Filter using the expression, to a maximum count if one was provided (default to all)
                if ($NumberToReturn -eq 0) {
                    $results = @($this | Where-Object -FilterScript $Expression)
                } else {
                    $results = @($this | Where-Object -FilterScript $Expression | Select-Object -First $NumberToReturn)
                }
                break
            }
        }
        if ($Mode -ne 'Split') {
            # Return the results in an objectmodel collection to the caller
            if ($results) {
                $results = $results -as [System.Management.Automation.PSObject[]] -as [System.Collections.ObjectModel.Collection`1[System.Management.Automation.PSObject]]
            } else {
                $results = New-Object -TypeName 'System.Collections.ObjectModel.Collection`1[System.Management.Automation.PSObject]'
            }
        }
        ,$results
    }
}

Add-ScriptMethodData -TypeName $typeNames -ScriptMethodName MatchAny -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The regular expressions to compare the collection against
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Values
    )
    # Add remaining arguments to the value collection for easier invocation
    if ($args) {
        $Values += $args
    }
    # Return any items in the collection matching the values provided
    ,($this.where({([string]$_).MatchAny($Values)}) -as $this.GetType())
}

Add-ScriptMethodData -TypeName $typeNames -ScriptMethodName LikeAny -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The wildcard strings to compare the collection against
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Values
    )
    # Add remaining arguments to the value collection for easier invocation
    if ($args) {
        $Values += $args
    }
    # Return any items in the collection like the values provided
    ,($this.where({([string]$_).LikeAny($Values)}) -as $this.GetType())
}

Add-ScriptMethodData -TypeName $typeNames -ScriptMethodName ContainsAny -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The values to compare the collection against
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        $Values
    )
    # Add remaining arguments to the value collection for easier invocation
    if ($args) {
        $Values += $args
    }
    # Return true if the collection contains any of the values; false otherwise
    $matchFound = $false
    foreach ($item in $Values) {
        if ($this -contains $item) {
            $matchFound = $true
            break
        }
    }
    $matchFound
}

Add-ScriptMethodData -TypeName $typeNames -ScriptMethodName ContainsAll -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The values to compare the collection against
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.Object[]]
        $Values
    )
    # Add remaining arguments to the value collection for easier invocation
    if ($args) {
        $Values += $args
    }
    # Return true if the collection contains all of the values; false otherwise
    foreach ($item in $Values) {
        if ($this -notcontains $item) {
            $false
            break
        }
    }
    $true
}

Add-ScriptMethodData -TypeName $typeNames -ScriptMethodName Sum -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The property to use when calculating the sum
        [Parameter(Position=0)]
        [ValidateNotNull()]
        [System.String]
        $Property
    )
    # Calculate the sum of the collection or of the values of a specific property
    # in the collection
    $total = $null
    if ($PSVersionTable.PSVersion -lt [System.Version]'4.0') {
        foreach ($item in $this) {
            if ($Property) {
                $total += $item.$Property
            } else {
                $total += $item
            }
        }
    } elseif ($Property) {
        $this.foreach({$total += $_.$Property})
    } else {
        $this.foreach({$total += $_})
    }
    $total
}