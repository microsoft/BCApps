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

    Permissions =
#if not CLEANSCHEMA32
#pragma warning disable AL0432
                  tabledata "Depr. Diff. Posting Buffer" = IMD,
#pragma warning restore AL0432
#endif
                  tabledata "Foreign Payment Types" = IMD,
                  tabledata "Ref. Payment - Exported" = IMD,
                  tabledata "Ref. Payment - Exported Buffer" = IMD,
                  tabledata "Ref. Payment - Imported" = IMD,
                  tabledata "Reference File Setup" = IMD;
}
