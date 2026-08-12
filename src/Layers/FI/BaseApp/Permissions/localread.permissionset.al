namespace System.Security.AccessControl;

using Microsoft.Bank.Payment;
using Microsoft.Bank.Setup;
using Microsoft.FixedAssets.Depreciation;

permissionset 1002 "LOCAL READ"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific read only access.';

    Permissions =
#if not CLEANSCHEMA32
#pragma warning disable AL0432
                  tabledata "Depr. Diff. Posting Buffer" = R,
#pragma warning restore AL0432
#endif
                  tabledata "Foreign Payment Types" = R,
                  tabledata "Ref. Payment - Exported" = R,
                  tabledata "Ref. Payment - Exported Buffer" = R,
                  tabledata "Ref. Payment - Imported" = R,
                  tabledata "Reference File Setup" = R;
}
