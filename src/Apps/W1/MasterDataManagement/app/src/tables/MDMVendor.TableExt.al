namespace Microsoft.Integration.MDM;

using Microsoft.Purchases.Vendor;

tableextension 7245 "MDM Vendor" extends Vendor
{
    keys
    {
        // Change-feed order for cross-environment paging (SystemModifiedAt seek + SystemId tiebreak).
        key(MDMChangeFeed; SystemModifiedAt, SystemId)
        {
        }
    }
}
