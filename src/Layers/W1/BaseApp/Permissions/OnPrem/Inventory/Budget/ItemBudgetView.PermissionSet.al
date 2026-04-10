namespace System.Security.AccessControl;

using Microsoft.Inventory.Analysis;

permissionset 5863 "Item Budget - View"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read S&R/P&P Budgets';

    Permissions = tabledata "Item Budget Buffer" = Rimd,
                  tabledata "Item Budget Entry" = R,
                  tabledata "Item Budget Name" = R;
}
