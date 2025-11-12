namespace System.Security.AccessControl;

using Microsoft.Assembly.Document;
using Microsoft.Assembly.Setup;
using Microsoft.Warehouse.ADCS;
using Microsoft.Assembly.History;

permissionset 2912 "D365 ASSEMBLY, VIEW"
{
    Assignable = true;

    Caption = 'Dynamics 365 View assembly';
    Permissions = tabledata "Assemble-to-Order Link" = R,
                  tabledata "Assembly Header" = R,
                  tabledata "Assembly Line" = R,
                  tabledata "Assembly Setup" = R,
                  tabledata "Item Identifier" = R,
                  tabledata "Posted Assemble-to-Order Link" = R,
                  tabledata "Posted Assembly Header" = R,
                  tabledata "Posted Assembly Line" = R;
}
