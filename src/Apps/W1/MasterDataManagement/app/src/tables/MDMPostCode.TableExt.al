namespace Microsoft.Integration.MDM;

using Microsoft.Foundation.Address;

tableextension 7250 "MDM Post Code" extends "Post Code"
{
    keys
    {
        // Change-feed order for cross-environment paging (SystemModifiedAt seek + SystemId tiebreak).
        key(MDMChangeFeed; SystemModifiedAt, SystemId)
        {
        }
    }
}
