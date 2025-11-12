namespace System.Security.AccessControl;

using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Counting.Journal;

permissionset 9257 "Inventory Registers - Read"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read item registers';

    Permissions = tabledata "Item Ledger Entry" = R,
                  tabledata "Item Register" = R,
                  tabledata "Phys. Inventory Ledger Entry" = R,
                  tabledata "Value Entry" = R;
}
