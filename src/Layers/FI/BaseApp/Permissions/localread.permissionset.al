namespace System.Security.AccessControl;

using Microsoft.Bank.Payment;
using Microsoft.Bank.Setup;
using Microsoft.FixedAssets.Depreciation;

permissionset 1002 "LOCAL READ"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific read only access.';

    Permissions = tabledata "Depr. Diff. Posting Buffer" = R,
                  tabledata "Foreign Payment Types" = R,
                  tabledata "Ref. Payment - Exported" = R,
                  tabledata "Ref. Payment - Exported Buffer" = R,
                  tabledata "Ref. Payment - Imported" = R,
                  tabledata "Reference File Setup" = R;
}
