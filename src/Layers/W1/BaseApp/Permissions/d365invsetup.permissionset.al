namespace System.Security.AccessControl;

using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Inventory.Item;

permissionset 8462 "D365 INV, SETUP"
{
    Assignable = true;

    Caption = 'Dyn. 365 Inventory Setup';
    Permissions = tabledata "Inventory Posting Group" = RIMD,
                  tabledata "Inventory Posting Setup" = RIMD,
                  tabledata Location = RIMD,
                  tabledata "Transfer Line" = D,
                  tabledata "Transfer Route" = RIMD;
}
