namespace System.Security.AccessControl;

using Microsoft.Warehouse.Structure;
using Microsoft.Foundation.Comment;
using Microsoft.Finance.Dimension;
using Microsoft.FixedAssets.Setup;
using Microsoft.FixedAssets.Insurance;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Vendor;

permissionset 5107 "Insurance - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Edit insurances';

    Permissions = tabledata Bin = R,
                  tabledata "Comment Line" = RIMD,
                  tabledata "Default Dimension" = RIMD,
                  tabledata "FA Class" = R,
                  tabledata "FA Location" = R,
                  tabledata "FA Subclass" = R,
                  tabledata "Ins. Coverage Ledger Entry" = Rm,
                  tabledata Insurance = RIMD,
                  tabledata "Insurance Type" = RIMD,
                  tabledata Location = R,
                  tabledata Vendor = R;
}
