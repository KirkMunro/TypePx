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

Update-TypeData -Force -TypeName System.Management.Automation.PSScriptCmdlet -MemberType ScriptMethod -MemberName ThrowException -Value {
    [System.Diagnostics.DebuggerHidden()]
    param(
        [System.Exception]$Exception,
        [System.Management.Automation.ErrorCategory]$ErrorCategory,
        [System.Object]$RelatedObject = $null
    )
    try {
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
$script:TypeExtensions.AddArrayItem('System.Management.Automation.PSScriptCmdlet','ThrowException')

Update-TypeData -Force -TypeName System.Management.Automation.PSScriptCmdlet -MemberType ScriptMethod -MemberName ThrowError -Value {
    [System.Diagnostics.DebuggerHidden()]
    param(
        [System.String]$Message,
        [System.String]$ExceptionTypeName,
        [System.Management.Automation.ErrorCategory]$ErrorCategory,
        [System.Object]$RelatedObject = $null
    )
    try {
        $exception = New-Object -TypeName $ExceptionTypeName -ArgumentList $Message
        $this.ThrowException($exception, $ErrorCategory, $RelatedObject)
    } catch {
        $this.ThrowTerminatingError($_)
    }
}
$script:TypeExtensions.AddArrayItem('System.Management.Automation.PSScriptCmdlet','ThrowError')

Update-TypeData -Force -TypeName System.Management.Automation.PSScriptCmdlet -MemberType ScriptMethod -MemberName ThrowCommandNotFoundError -Value {
    [System.Diagnostics.DebuggerHidden()]
    param(
        [System.String]$CommandName,
        [System.Object]$RelatedObject = $null
    )
    try {
        $message = $this.GetResourceString('DiscoveryExceptions','CommandNotFoundException') -f $CommandName
        $exception = New-Object -TypeName System.Management.Automation.CommandNotFoundException -ArgumentList $message
        $exception.CommandName = $CommandName
        $this.ThrowException($exception, [System.Management.Automation.ErrorCategory]::ObjectNotFound, $RelatedObject)
    } catch {
        $this.ThrowTerminatingError($_)
    }
}
$script:TypeExtensions.AddArrayItem('System.Management.Automation.PSScriptCmdlet','ThrowCommandNotFoundError')

Update-TypeData -Force -TypeName System.Management.Automation.PSScriptCmdlet -MemberType ScriptMethod -MemberName ValidateParameterDependency -Value {
    [System.Diagnostics.DebuggerHidden()]
    param(
        [System.String]$ParameterName,
        [System.String[]]$RequiredParameterName
    )
    try {
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
$script:TypeExtensions.AddArrayItem('System.Management.Automation.PSScriptCmdlet','ValidateParameterDependency')

Update-TypeData -Force -TypeName System.Management.Automation.PSScriptCmdlet -MemberType ScriptMethod -MemberName ValidateParameterIncompatibility -Value {
    [System.Diagnostics.DebuggerHidden()]
    param(
        [System.String]$ParameterName,
        [System.String[]]$IncompatibleParameterName
    )
    try {
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
$script:TypeExtensions.AddArrayItem('System.Management.Automation.PSScriptCmdlet','ValidateParameterIncompatibility')

Update-TypeData -Force -TypeName System.Management.Automation.PSScriptCmdlet -MemberType ScriptMethod -MemberName GetSplattableParameters -Value {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The names of the parameters that you want to splat into other commands.
        [System.String[]]$ParameterName = @()
    )
    #region Make sure we work like a function, without requiring array input.

    if ($args) {
        $ParameterName += $args
    }

    #endregion

    #region Define the hashtable that will contain the pass thru parameters.

    $splattableParameters = @{}

    #endregion

    #region Load the parameters that will be passed through into the hashtable.

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

    #endregion

    #region Return the hashtable to the caller.

    $splattableParameters

    #endregion
}
$script:TypeExtensions.AddArrayItem('System.Management.Automation.PSScriptCmdlet','GetSplattableParameters')

Update-TypeData -Force -TypeName System.Management.Automation.PSScriptCmdlet -MemberType ScriptMethod -MemberName GetBoundPagingParameters -Value {
    [System.Diagnostics.DebuggerHidden()]
    param()
    #region Return the paging parameters in a splattable hashtable.

    $commandMetadata = $this.MyInvocation.MyCommand -as [System.Management.Automation.CommandMetadata]
    if (-not $commandMetadata -or -not $commandMetadata.SupportsPaging) {
        # If paging is not supported for this command, return an empty hashtable.
        @{}
    } else {
        # Otherwise, create a splattable hashtable containing all bound paging parameters.
        $pagingParameterNames = Get-Member -InputObject $this.PagingParameters -MemberType Property | Select-Object -ExpandProperty Name
        $this.GetSplattableParameters($pagingParameterNames)
    }

    #endregion
}
$script:TypeExtensions.AddArrayItem('System.Management.Automation.PSScriptCmdlet','GetBoundPagingParameters')

Update-TypeData -Force -TypeName System.Management.Automation.PSScriptCmdlet -MemberType ScriptMethod -MemberName GetBoundShouldProcessParameters -Value {
    [System.Diagnostics.DebuggerHidden()]
    param()
    #region Return the should process parameters in a splattable hashtable.

    $commandMetadata = $this.MyInvocation.MyCommand -as [System.Management.Automation.CommandMetadata]
    if (-not $commandMetadata -or -not $commandMetadata.SupportsShouldProcess) {
        # If should process is not supported for this command, return an empty hashtable.
        @{}
    } else {
        # Otherwise, create a splattable hashtable containing all bound should process parameters.
        $this.GetSplattableParameters(@('Confirm','WhatIf'))
    }

    #endregion
}
$script:TypeExtensions.AddArrayItem('System.Management.Automation.PSScriptCmdlet','GetBoundShouldProcessParameters')