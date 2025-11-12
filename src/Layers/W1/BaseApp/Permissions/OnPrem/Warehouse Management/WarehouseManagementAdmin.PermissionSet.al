namespace System.Security.AccessControl;

using Microsoft.Warehouse.Structure;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Setup;
using System.Security.User;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Worksheet;
using Microsoft.Foundation.Shipping;

permissionset 8917 "Warehouse Management - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'Whse Mgt. setup';

    Permissions = tabledata User = R,
                  tabledata "Bin Creation Wksh. Name" = RIMD,
                  tabledata "Bin Creation Wksh. Template" = RIMD,
                  tabledata "Bin Template" = RIMD,
                  tabledata "Bin Type" = RIMD,
                  tabledata Location = RIMD,
                  tabledata "Phys. Invt. Counting Period" = RIMD,
                  tabledata "Put-away Template Header" = RIMD,
                  tabledata "Put-away Template Line" = RIMD,
                  tabledata "Shipment Method" = RIMD,
                  tabledata "Shipping Agent" = RIMD,
                  tabledata "Shipping Agent Services" = RIMD,
                  tabledata "Special Equipment" = RIMD,
                  tabledata "User Setup" = RIMD,
                  tabledata "Warehouse Class" = RIMD,
                  tabledata "Warehouse Employee" = RIMD,
                  tabledata "Warehouse Journal Batch" = RIMD,
                  tabledata "Warehouse Journal Template" = RIMD,
                  tabledata "Warehouse Setup" = RIMD,
                  tabledata "Whse. Worksheet Name" = RIMD,
                  tabledata "Whse. Worksheet Template" = RIMD,
                  tabledata Zone = RIMD;
}
