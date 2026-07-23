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

    Permissions = tabledata "Foreign Payment Types" = IMD,
#if not CLEANSCHEMA32
                  tabledata "Depr. Diff. Posting Buffer" = IMD,
#endif
                  tabledata "Ref. Payment - Exported" = IMD,
                  tabledata "Ref. Payment - Exported Buffer" = IMD,
                  tabledata "Ref. Payment - Imported" = IMD,
                  tabledata "Reference File Setup" = IMD;
}
