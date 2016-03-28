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

$typeName = 'System.Management.Automation.PSScriptCmdlet'

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName ThrowException -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The exception to be thrown
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNull()]
        [System.Exception]
        $Exception,

        # The category of the error
        [Parameter(Position=1, Mandatory=$true)]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorCategory]
        $ErrorCategory,

        # An object related to the error
        [Parameter(Position=2)]
        [System.Object]
        $RelatedObject = $null
    )
    try {
        # Throw an error record wrapping the exception
        $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList @(
            $Exception
            $Exception.GetType().Name
            $ErrorCategory
            $RelatedObject
        )
        throw $errorRecord
    } catch {
        $this.ThrowTerminatingError($_)
    }
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName ThrowError -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The error message to be reported to the caller
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Message,

        # The type of exception to be thrown
        [Parameter(Position=1, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ExceptionTypeName,

        # The category of the error
        [Parameter(Position=2, Mandatory=$true)]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorCategory]
        $ErrorCategory,

        # An object related to the error
        [Parameter(Position=3)]
        [System.Object]
        $RelatedObject = $null
    )
    try {
        # Throw an exception
        $exception = New-Object -TypeName $ExceptionTypeName -ArgumentList $Message
        $this.ThrowException($exception, $ErrorCategory, $RelatedObject)
    } catch {
        $this.ThrowTerminatingError($_)
    }
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName ThrowCommandNotFoundError -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The name of the command that was not found
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $CommandName,

        # An object related to the error
        [Parameter(Position=1)]
        [System.Object]
        $RelatedObject = $null
    )
    try {
        # Throw a command not found exception
        $message = $this.GetResourceString('DiscoveryExceptions','CommandNotFoundException') -f $CommandName
        $exception = New-Object -TypeName System.Management.Automation.CommandNotFoundException -ArgumentList $message
        $exception.CommandName = $CommandName
        $this.ThrowException($exception, [System.Management.Automation.ErrorCategory]::ObjectNotFound, $RelatedObject)
    } catch {
        $this.ThrowTerminatingError($_)
    }
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName ValidateParameterDependency -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The name of the parameter that requires other parameters in the same parameter set when it is used
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ParameterName,

        # The list of names of other required parameters
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $RequiredParameterName
    )
    # Make sure we work like a function, without requiring array input.
    if ($args) {
        $IncompatibleParameterName += $args
    }
    try {
        # If the current parameter set contains missing required parameters, throw an exception
        if ($this.MyInvocation.BoundParameters.ContainsKey($ParameterName) -and
            -not @($this.MyInvocation.BoundParameters.Keys).ContainsAny($RequiredParameterName)) {
            $message = "The following parameters are required when using the ${ParameterName} parameter: $($RequiredParameterName -join ',')."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            $this.ThrowException($exception, [System.Management.Automation.ErrorCategory]::InvalidOperation)
        }
    } catch {
        $this.ThrowTerminatingError($_)
    }
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName ValidateParameterIncompatibility -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The name of the parameter that is not compatible with other parameters in the same parameter set
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ParameterName,

        # The list of names of other incompatible parameters
        [Parameter(Position=1, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $IncompatibleParameterName
    )
    # Make sure we work like a function, without requiring array input.
    if ($args) {
        $IncompatibleParameterName += $args
    }
    try {
        # If the current parameter set contains incompatible parameters, throw an exception
        if ($this.MyInvocation.BoundParameters.ContainsKey($ParameterName) -and
            @($this.MyInvocation.BoundParameters.Keys).ContainsAny($IncompatibleParameterName)) {
            $message = "The following parameters may not be used in combination with the ${ParameterName} parameter: $($IncompatibleParameterName -join ',')."
            $exception = New-Object -TypeName System.ArgumentException -ArgumentList $message
            $this.ThrowException($exception, [System.Management.Automation.ErrorCategory]::InvalidOperation)
        }
    } catch {
        $this.ThrowTerminatingError($_)
    }
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName GetSplattableParameters -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The names of the parameters that you want to splat into other commands.
        [System.String[]]$ParameterName = @()
    )
    # Make sure we work like a function, without requiring array input.
    if ($args) {
        $ParameterName += $args
    }
    # Define the hashtable that will contain the pass thru parameters.
    $splattableParameters = @{}
    # Load the parameters that will be passed through into the hashtable.
    if (-not $ParameterName) {
        # If no specific parameters were requested, splat all bound parameters.
        $splattableParameters = $this.MyInvocation.BoundParameters
    } else {
        # Otherwise, only splat the bound parameters that were requested.
        foreach ($item in $ParameterName) {
            if ($this.MyInvocation.BoundParameters.ContainsKey($item)) {
                $splattableParameters[$item] = $this.MyInvocation.BoundParameters.$item
            }
        }
    }
    # Return the hashtable to the caller.
    $splattableParameters
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName GetBoundPagingParameters -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param()
    # Return the paging parameters in a splattable hashtable.
    $commandMetadata = $this.MyInvocation.MyCommand -as [System.Management.Automation.CommandMetadata]
    if (-not $commandMetadata -or -not $commandMetadata.SupportsPaging) {
        # If paging is not supported for this command, return an empty hashtable.
        @{}
    } else {
        # Otherwise, create a splattable hashtable containing all bound paging parameters.
        $pagingParameterNames = Get-Member -InputObject $this.PagingParameters -MemberType Property | Select-Object -ExpandProperty Name
        $this.GetSplattableParameters($pagingParameterNames)
    }
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName GetBoundShouldProcessParameters -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param()
    # Return the should process parameters in a splattable hashtable.
    $commandMetadata = $this.MyInvocation.MyCommand -as [System.Management.Automation.CommandMetadata]
    if (-not $commandMetadata -or -not $commandMetadata.SupportsShouldProcess) {
        # If should process is not supported for this command, return an empty hashtable.
        @{}
    } else {
        # Otherwise, create a splattable hashtable containing all bound should process parameters.
        $this.GetSplattableParameters(@('Confirm','WhatIf'))
    }
}