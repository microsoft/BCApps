namespace System.Security.AccessControl;

using Microsoft.Assembly.Document;
using Microsoft.Assembly.Setup;
using Microsoft.Inventory.BOM;
using Microsoft.Warehouse.ADCS;
using Microsoft.Assembly.History;

permissionset 6218 "D365 ASSEMBLY, EDIT"
{
    Assignable = true;
    Caption = 'Dynamics 365 Create assembly';

    IncludedPermissionSets = "D365 ASSEMBLY, VIEW";

    Permissions = tabledata "Assemble-to-Order Link" = IMD,
                  tabledata "Assembly Header" = IMD,
                  tabledata "Assembly Line" = IMD,
                  tabledata "Assembly Setup" = imd,
                  tabledata "BOM Component" = RIMD,
                  tabledata "Item Identifier" = imd,
                  tabledata "Posted Assemble-to-Order Link" = IMD,
                  tabledata "Posted Assembly Header" = IMD,
                  tabledata "Posted Assembly Line" = IMD;
}
