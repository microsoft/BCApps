namespace Microsoft.Integration.MDM;

using Microsoft.Finance.Currency;

tableextension 7251 "MDM Currency Exch. Rate" extends "Currency Exchange Rate"
{
    keys
    {
        // Change-feed order for cross-environment paging (SystemModifiedAt seek + SystemId tiebreak).
        key(MDMChangeFeed; SystemModifiedAt, SystemId)
        {
        }
    }
}
