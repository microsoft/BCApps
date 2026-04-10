namespace System.Security.AccessControl;

using Microsoft.Foundation.Address;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;

permissionset 2345 "Intrastat - Edit"
{
    Access = Public;
    Assignable = false;

    Caption = 'Intrastat periodic activities';
    Permissions = tabledata Area = R,
                  tabledata "Country/Region" = R,
                  tabledata "Entry/Exit Point" = R,
                  tabledata Item = R,
                  tabledata "Item Ledger Entry" = R,
                  tabledata "Item Variant" = R,
                  tabledata "Tariff Number" = R,
                  tabledata "Transaction Specification" = R,
                  tabledata "Transaction Type" = R,
                  tabledata "Transport Method" = R,
                  tabledata "Value Entry" = R;
}
