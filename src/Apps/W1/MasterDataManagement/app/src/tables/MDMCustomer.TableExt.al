namespace Microsoft.Integration.MDM;

using Microsoft.Sales.Customer;

tableextension 7244 "MDM Customer" extends Customer
{
    keys
    {
        // Change-feed order for cross-environment paging (SystemModifiedAt seek + SystemId tiebreak).
        key(MDMChangeFeed; SystemModifiedAt, SystemId)
        {
        }
    }
}
