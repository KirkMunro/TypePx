<#
.SYNOPSIS
    Add an item to one or more keys as an array stored in a hash table
.DESCRIPTION
    Add an item to one or more keys as an array stored in a hash table. If the value is not an array or if the key does not yet exist in the hash table, create the array from what is currently stored and add the item to that array.
#>
[System.Diagnostics.DebuggerHidden()]
param(
    # The hash table you are modifying
    [System.Collections.Hashtable]
    $Hashtable,

    # The hashtable keys for which you want to add an item to the collection
    [System.Object[]]
    $Keys,

    # The item(s) you want to add to the collection
    [System.Array]
    $Value
)
foreach ($key in $Keys) {
    #region If the key does not exist, add it; otherwise, add the Value collection to its value as a collection.

    if (-not $Hashtable.ContainsKey($key)) {
        $Hashtable.Add($key,$Value)
    } else {
        $Hashtable[$key] = @($Hashtable[$key]) + $Value
    }

    #endregion
}