namespace System.Security.AccessControl;

using Microsoft.Bank.Payment;
using Microsoft.Bank.Setup;
using Microsoft.FixedAssets.Depreciation;

permissionset 1001 "LOCAL"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific func.';

    IncludedPermissionSets = "LOCAL READ";

    Permissions = tabledata "Depr. Diff. Posting Buffer" = IMD,
                  tabledata "Foreign Payment Types" = IMD,
                  tabledata "Ref. Payment - Exported" = IMD,
                  tabledata "Ref. Payment - Exported Buffer" = IMD,
                  tabledata "Ref. Payment - Imported" = IMD,
                  tabledata "Reference File Setup" = IMD;
}
