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

$typeName = 'System.String'

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName Wrap -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The width you want to use when wrapping the string
        [ValidateRange(1,[System.Int32]::MaxValue)]
        [System.Int32]
        $Width = $Host.UI.RawUI.BufferSize.Width
    )
    $this -split "`r`n|`r|`n" -replace "(.{1,${Width}})( +|`$`n?)|(.{1,${Width}})","`$1`$2`n" -replace '^\s+|\s+$' -split "`r`n|`r|`n" -replace '^\s+|\s+$' -join "`n"
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName ToScriptBlock -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # A hashtable of variable values that you want to use during the conversion
        [System.Collections.Hashtable]
        $VariableValues = @{}
    )
    # Invoke a snippet to convert the string to a script block
    . (Get-Module TypePx) Invoke-Snippet -InputObject $script:SnippetCache['String.ToScriptBlock'] -Parameters @{
        String = $this
        VariableValues = $VariableValues
    }
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName Expand -ScriptBlock {
    [System.Diagnostics.DebuggerStepThrough()]
    param()
    # Invoke a method to expand the string
    $ExecutionContext.InvokeCommand.ExpandString($this)
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName MatchAny -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The regular expression strings that you want to compare to the string
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Values
    )
    # Add remaining arguments to the values collection for easier invocation
    if ($args) {
        $Values += $args
    }
    # Return true if any of the regular expression strings match the string; false otherwise
    $stringToCompare = $this
    $Values.where({$stringToCompare -match $_}).Count -gt 0
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName LikeAny -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # The wildcard strings that you want to compare to the string
        [Parameter(Position=0, Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $Values
    )
    # Add remaining arguments to the values collection for easier invocation
    if ($args) {
        $Values += $args
    }
    # Return true if any of the wildcard strings are like the string; false otherwise
    $stringToCompare = $this
    $Values.where({$stringToCompare -like $_}).Count -gt 0
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName IsHtmlEncoded -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param()
    # Return true if the string appears to be fully HTML encoded; false otherwise
    if (-not ('System.Web.HttpUtility')) {
        [System.Reflection.Assembly]::Load('System.Web, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a') > $null
    }
    $decodedString = [System.Web.HttpUtility]::HtmlDecode($this)
    $encodedString = [System.Web.HttpUtility]::HtmlEncode($decodedString)
    $encodedString -eq $this
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName HtmlEncode -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param(
        # A flag if you want to force the encoding
        [Parameter()]
        [System.Management.Automation.SwitchParameter]
        $Force = $false
    )
    # Return the HTML encoded version of the string
    if (-not ('System.Web.HttpUtility')) {
        [System.Reflection.Assembly]::Load('System.Web, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a') > $null
    }
    if ($Force -or -not $this.IsHtmlEncoded()) {
        [System.Web.HttpUtility]::HtmlEncode($this)
    } else {
        $this
    }
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName HtmlDecode -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param()
    # Return the HTML decoded version of the string
    if (-not ('System.Web.HttpUtility')) {
        [System.Reflection.Assembly]::Load('System.Web, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a') > $null
    }
    [System.Web.HttpUtility]::HtmlDecode($this)
}

Add-ScriptMethodData -TypeName $typeName -ScriptMethodName GetMD5Hash -ScriptBlock {
    [System.Diagnostics.DebuggerHidden()]
    param()
    # Return the MD5 hash of the string
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($this)
    $hash = $md5.ComputeHash($bytes)
    $sb = New-Object -TypeName System.Text.StringBuilder
    for ($index = 0; $index -lt $hash.Count; $index++) {
        $sb.Append($hash[$index].ToString("x2")) > $null
    }
    $sb.ToString()
}