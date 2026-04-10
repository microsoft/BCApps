namespace System.Security.AccessControl;

using Microsoft.Finance.Dimension;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Comment;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Vendor;
using Microsoft.Warehouse.Structure;

permissionset 5577 "Insurance Journals - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Create entries in ins. jnls.';

    Permissions = tabledata Bin = R,
                  tabledata "Comment Line" = R,
                  tabledata "Default Dimension" = R,
                  tabledata "Default Dimension Priority" = R,
                  tabledata "FA Class" = R,
                  tabledata "FA Journal Setup" = R,
                  tabledata "FA Location" = R,
                  tabledata "FA Subclass" = R,
                  tabledata "Fixed Asset" = R,
                  tabledata "Ins. Coverage Ledger Entry" = R,
                  tabledata Insurance = R,
                  tabledata "Insurance Journal Batch" = RI,
                  tabledata "Insurance Journal Line" = RIMD,
                  tabledata "Insurance Journal Template" = RI,
                  tabledata "Insurance Type" = R,
                  tabledata Location = R,
                  tabledata "Reason Code" = R,
                  tabledata "Source Code Setup" = R,
                  tabledata Vendor = R;
}
