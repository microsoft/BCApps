namespace System.Security.AccessControl;

using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;

permissionset 6555 "D365 VENDOR, VIEW"
{
    Assignable = true;

    Caption = 'Dynamics 365 View vendors';
    Permissions = tabledata "Item Reference" = R,
                  tabledata "Transaction Type" = R,
                  tabledata "Transport Method" = R,
                  tabledata "Vendor Bank Account" = R,
                  tabledata "Vendor Invoice Disc." = R,
                  tabledata "Vendor Ledger Entry" = R;
}
