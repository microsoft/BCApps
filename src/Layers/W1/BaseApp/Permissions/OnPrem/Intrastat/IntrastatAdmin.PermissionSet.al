namespace System.Security.AccessControl;

using Microsoft.Inventory.Intrastat;

permissionset 4384 "Intrastat - Admin"
{
    Access = Public;
    Assignable = false;

    Caption = 'Intrastat setup';
    Permissions = tabledata Area = RIMD,
                  tabledata "Entry/Exit Point" = RIMD,
                  tabledata "Tariff Number" = RIMD,
                  tabledata "Transaction Specification" = RIMD,
                  tabledata "Transaction Type" = RIMD,
                  tabledata "Transport Method" = RIMD;
}
