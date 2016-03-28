<#
.SYNOPSIS
    Add an item to one or more keys as a list stored in a dictionary
.DESCRIPTION
    Add an item to one or more keys as a list stored in a dictionary. If the key does not yet exist in the dictionary, add it. Otherwise, concatenate the list to the current list.
#>
[System.Diagnostics.DebuggerHidden()]
param(
    # The dictionary you are modifying
    [System.Collections.Generic.Dictionary``2[System.String,System.Collections.Generic.List``1[System.Management.Automation.Runspaces.TypeMemberData]]]
    $Dictionary,

    # The array of keys for which you want to add an item to the collection
    [System.String[]]
    $Keys,

    # The item you want to add to the collection
    [System.Management.Automation.Runspaces.TypeMemberData]
    $Value
)
if ($Dictionary -ne $null) {
    foreach ($key in $Keys) {
        #region If the key does not exist, add it; otherwise, add the Value collection to its value as a collection.

        if (!$Dictionary.ContainsKey($key)) {
            $Dictionary.Add($key,$Value)
        } else {
            $Dictionary[$key].Add($Value)
        }

        #endregion
    }
}