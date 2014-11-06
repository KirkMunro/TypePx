<#
.SYNOPSIS
    Add an item to one or more keys as an array stored in a dictionary
.DESCRIPTION
    Add an item to one or more keys as an array stored in a dictionary. If the value is not an array or if the key does not yet exist in the dictionary, create the array from what is currently stored and add the item to that array.
#>
[System.Diagnostics.DebuggerHidden()]
param(
    # The dictionary you are modifying
    [System.Object]
    $Dictionary,

    # The hashtable keys for which you want to add an item to the collection
    [System.Object[]]
    $Keys,

    # The item(s) you want to add to the collection
    [System.Array]
    $Value
)
if (($Dictionary -ne $null) -and ($Dictionary.GetType().GetInterface('IDictionary',$true))) {
    foreach ($key in $Keys) {
        #region If the key does not exist, add it; otherwise, add the Value collection to its value as a collection.

        if ($Dictionary.Keys -notcontains $key) {
            $Dictionary.Add($key,$Value)
        } else {
            $Dictionary[$key] = @($Dictionary[$key]) + $Value
        }

        #endregion
    }
}