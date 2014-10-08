## TypePx

### Overview

The TypePx module adds properties and methods to the most commonly used types
to make common tasks easier. Using these type extensions together can provide
an enhanced syntax in PowerShell that is both easier to read and self-
documenting. TypePx also provides commands to manage type accelerators. Type
acceleration also contributes to making scripting easier and they help produce
more readable scripts, particularly when using a library of .NET classes that
belong to the same namespace.

### Minimum requirements

- PowerShell 3.0
- SnippetPx module

### License and Copyright

Copyright (c) 2014 Kirk Munro.

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

### Loading the TypePx module

When it comes to module auto-loading, type extensions do not function the
same way that commands do in PowerShell. As a result, if you want to use one
of the type extensions that the TypePx module creates, you have two choices:

1. If you are working inside of another module, add a dependency to the
TypePx module in the module you are working on.

2. Manually load TypePx by invoking the following command:

```powershell
Import-Module TypePx
```

If you use these extensions on a regular basis, you can add that to your
profile script.

If, on the other hand, you are working with type accelerators, simply
invoking one of the *-TypeAccelerator commands will cause the module to
load automatically using auto-loading and then the command will invoke
properly.

### Using the TypePx module

To see a list of Type Accelerator commands that are available, invoke the
following command:

```powershell
Get-Command -Module TypePx
```

This will return a list of the commands that are included in the TypePx
module. In this release, there are 5 commands, each with an associated
alias, as follows:

Add-TypeAccelerator, with alias atx
Get-TypeAccelerator, with alias gtx
Remove-TypeAccelerator, with alias rtx
Set-TypeAccelerator, with alias stx
Use-Namespace, with alias use

All commands are fully documented with examples, so you can get detailed
help information for any of these commands by invoking something like
the following:

```powershell
Get-Help Use-Namespace -Full | more
```

The type acceleration commands will make it much easier for you to use
.NET types inside of your PowerShell scripts.

The type extensions that come with the TypePx module are not discoverable
via a simple command call at the moment, however the TypePx module is
open source and you can see all type extensions that it includes by
reviewing the files in the typedata folder within the TypePx module.

To give you a few examples of some of the type extensions that are
included in the TypePx module, any of the following commands will work
anywhere in PowerShell once TypePx is loaded:

```powershell
#################
# Fun with arrays
#################
# Show a string representation of an array that respects $FormatEnumerationLimit
$a = 1..10
$a.ToString()
# Compact (remove null values) from an array
$a = 1,$null,2,$null,3
$a.Count
$a.Compact().Count
# Return unique elements in an array
$a = 1,1,2,3,3,4,4,5,6
$a.Unique()
# Reverse an array
$a = 1,2,3,4
$a.Reverse()
# Flatten a multi-dimensional array
$a = (1,2),(3,4),(5,6)
$a.Flatten()
# Slice an array into chunks
$a = 1,2,3,4,5,6
$a.Slice(3)[1]
##################
# Fun with numbers
##################
# Get a timespan in a human readable way
$x = 30
$x.Days
$x.Hours
$x.Minutes
$x.Seconds
$x.Milliseconds
(1).Day
(1).Hour
(1).Minute
(1).Second
(1).Millisecond
# Calculate relative dates
(30).Days.Ago
(7).Days.FromNow
(1).Week.Ago.InUtc
# Use relative dates in practice
 Get-EventLog -LogName System -After ((2).Days.Ago)
# Perform a task a specific number of times
$x = 10
$x.Times{'Hello'}
# Note that in PowerShell 3, you must include the script block in brackets
$x.Times({'Hello'})
######################
# Fun with collections
######################
# Compare collections against collections
$names = gsv | Select-Object -ExpandProperty Name
$names.MatchAny('^b','^u')
$names.LikeAny('b*','u*')
$names.ContainsAny('wuauserv','bits')
$names.ContainsAny('notaservicename','notaservicenameeither')
# Calculate the sum of a collection
$a = 1,2,3,4
$a.Sum()
(gps).Sum('WorkingSet64')
# Add an item to a hashtable as a collection
$ht = @{}
$ht.Add('A','This is not a collection')
$ht.AddArrayItem('B','This is a collection')
$ht.AddArrayItem('B','This adds to the collection')
$ht
# Note that PowerShell 4+ include foreach and where "magic" methods. This module
# adds them to PowerShell 3
# Expand a property in a collection
(gsv).foreach('Name')
# Convert every object in a collection to another type
(gps).foreach([string])
# Set property values on all objects in a collection
$s = Get-Service
$s.foreach('Name','Hello')
$s
# Invoke a method on all objects in a collection
$s = @(gsv wuauserv)
$s.foreach('Start')
# Invoke a method on all objects in a collection, with parameters
$a = (1,2),(3,4),(5,6)
$a.foreach('Get',1)
# Filter a collection
$s = gsv w*
$s.where({$_.Status -eq 'Running'})
# Get the first item matching a filter
$s.where({$_.Status -eq 'Running'},'First')
# Get the first N items matching a filter
$s.where({$_.Status -eq 'Running'},'First',4)
# Get the last item matching a filter
$s.where({$_.Status -eq 'Running'},'Last')
# Get the last N items matching a filter
$s.where({$_.Status -eq 'Running'},'Last',4)
# Skip items in a collection until a filter matches, then return all objects
$s.where({$_.Status -eq 'Running'},'SkipUntil')
# Skip items in a collection until a filter matches, then return the first N items
$s.where({$_.Status -eq 'Running'},'SkipUntil',4)
# Return all items in a collection until a filter matches
$s.where({$_.Status -eq 'Running'},'Until')
# Return the first N items in a collection until a filter matches
$s.where({$_.Status -eq 'Running'},'Until', 1)
# Return a collection of all items matching a filter, followed by a collection of all other items
$collections = $s.where({$_.Status -eq 'Running'},'Split')
$collections[0]
$collections[1]
# Return a collection of the first N items matching a filter, followed by a collection of all other items
$collections = $s.where({$_.Status -eq 'Running'},'Split',5)
$collections[0]
$collections[1]
# Return all items in a collection matching a filter
$s.where({$_.Status -eq 'Running'},'Default')
# Return the first N items in a collection matching a filter.
$s.where({$_.Status -eq 'Running'},'Default',3)
##################
# Fun with strings
##################
# Expand PowerShell variables/subexpressions in a string
$value = Get-Date
$s = 'The value of `$value is "${value}".'
$s.Expand()
# Compare string values against collections
$s = 'Hello'
$s.MatchAny('^b','o$')
$s.LikeAny('b*','*o')
# Calculate the MD5 hash of a string
'Hello'.GetMD5Hash()
#########################
# Fun with secure strings
#########################
$ss = ConvertTo-SecureString -String 'P0w3r$h31!' -AsPlainText -Force
# Calculate the MD5 hash of the unencrypted string
$ss.GetMD5Hash()
# Show the unencrypted string
$ss.Peek()
```

Other type extensions are included that are designed for use in specific
scenarios. Module Local Storage (MLS) is a term that was created as part
of this module, and it is used to refer to local storage locations for
the current user or for all users where a module can store and retrieve
information from files on disk that are related to that module. MLS will
always refer to accessible folders on the local system, even for modules
that are loaded from file shares or other locations. The following examples
illustrate how you can use type extensions to work with MLS via extensions
that have been added to the System.Management.Automation.PSModuleInfo type:

```powershell
#########################################
# Working with Module Local Storage (MLS)
#########################################
# From inside a module, get the MLS location for the current user
$ExecutionContext.SessionState.Module.GetLocalStoragePath($true)
# From inside a module, get the MLS location for all users
$ExecutionContext.SessionState.Module.GetLocalStoragePath()
```

There are also extensions that make some tasks easier when working with
advanved functions. The following examples demonstrate methods that have
been added to the System.Management.Automation.PSScriptCmdlet type:

```powershell
#################################
# Working with Advanced functions
#################################
# Retrieve any paging parameters that were used as a splattable hashtable
$PSCmdlet.GetBoundPagingParameters()
# Retrieve any should process parameters that were used as a splattable hashtable
$PSCmdlet.GetBoundShouldProcessParameters()
# Retrieve specific parameters that were used as a splattable hashtable
$PSCmdlet.GetBoundParameters('Name','Type')
# Retrieve all parameters in a splattable hashtable
$PSCmdlet.GetBoundParameters()
# Throw a terminating error if incompatible parameters are used together
$PSCmdlet.ValidateParameterIncompatibility('Session',@('ServerName'))
# Throw a terminating error if parameters required when other parameters are used are missing
$PSCmdlet.ValidateParameterDependency('AsPlainText',@('Force'))
# Throw a property structured terminating error when a command is not found
$PSCmdlet.ThrowCommandNotFoundError('This-DoesNotExist')
# Throw a property structured terminating error
$message = 'An item was not found.'
$exceptionType = 'System.Management.Automation.ItemNotFoundException'
$errorCategory = [System.Management.Automation.ErrorCategory]::ObjectNotFound
$relatedObject = $null
$PSCmdlet.ThrowError($message,$exceptionType,$errorCategory,$relatedObject)
# Throw an exception as a terminating error
$exception = New-Object -TypeName System.Management.Automation.ItemNotFoundException -ArgumentList 'An item was not found.'
$errorCategory = [System.Management.Automation.ErrorCategory]::ObjectNotFound
$relatedObject = $null
$PSCmdlet.ThrowException($exception,$errorCategory,$relatedObject)
```

That should give you a good idea of the kind of power that is included in this
module. This is something that will grow and evolve over time, and if you have
value to add, please contribute!