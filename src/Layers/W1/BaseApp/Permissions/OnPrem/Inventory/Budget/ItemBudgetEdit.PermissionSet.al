namespace System.Security.AccessControl;

using Microsoft.Inventory.Analysis;

permissionset 6867 "Item Budget - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Edit S&R/P&P Budgets';

    Permissions = tabledata "Item Budget Buffer" = Rimd,
                  tabledata "Item Budget Entry" = RIMd,
                  tabledata "Item Budget Name" = RIMD;
}
