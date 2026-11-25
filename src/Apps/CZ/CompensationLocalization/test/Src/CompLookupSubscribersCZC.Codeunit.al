namespace Microsoft.Finance.Compensations;

using Microsoft.Purchases.Payables;
using Microsoft.Sales.Receivables;

codeunit 148136 "Comp. Lookup Subscribers CZC"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"Compensation Line CZC", 'OnSourceEntryNoLookupOnAfterCustLedgerEntryFilters', '', false, false)]
    local procedure FilterCustomerSourceEntryLookup(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgerEntry.SetRange(Description, 'Lookup event filter CZC');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Compensation Line CZC", 'OnSourceEntryNoLookupOnAfterVendorLedgerEntryFilters', '', false, false)]
    local procedure FilterVendorSourceEntryLookup(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        VendorLedgerEntry.SetRange(Description, 'Lookup event filter CZC');
    end;
}
