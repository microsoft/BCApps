namespace System.Security.AccessControl;

using Microsoft.HumanResources.Employee;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Inventory.Setup;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Warehouse.Activity;

permissionset 9556 "D365 INV DOC, CREATE"
{
    Assignable = true;

    Caption = 'Dyn. 365 Create inventory doc';
    Permissions = tabledata Employee = R,
                  tabledata "G/L Entry" = R,
                  tabledata "Inventory Setup" = R,
                  tabledata "No. Series" = R,
                  tabledata "Planning Assignment" = Ri,
                  tabledata "Stockkeeping Unit" = RIMD,
                  tabledata "Transfer Header" = RIMD,
                  tabledata "Transfer Line" = RIMD,
                  tabledata "Warehouse Activity Line" = R,
                  tabledata "Warehouse Reason Code" = R;
}
