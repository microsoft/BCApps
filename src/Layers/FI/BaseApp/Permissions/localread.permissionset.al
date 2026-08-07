namespace System.Security.AccessControl;

#if not CLEAN29
using Microsoft.Bank.Payment;
using Microsoft.Bank.Setup;
#endif
using Microsoft.FixedAssets.Depreciation;

permissionset 1002 "LOCAL READ"
{
    Access = Public;
    Assignable = true;
    Caption = 'Country/region-specific read only access.';

    Permissions = tabledata "Depr. Diff. Posting Buffer" = R
#if not CLEAN29
#pragma warning disable AL0432
                  , tabledata "Foreign Payment Types" = R
                  , tabledata "Ref. Payment - Exported" = R
                  , tabledata "Ref. Payment - Exported Buffer" = R
                  , tabledata "Ref. Payment - Imported" = R
                  , tabledata "Reference File Setup" = R
#pragma warning restore AL0432
#endif
                  ;
}
