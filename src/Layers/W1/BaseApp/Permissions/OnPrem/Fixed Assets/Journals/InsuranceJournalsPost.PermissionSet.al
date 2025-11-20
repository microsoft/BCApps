namespace System.Security.AccessControl;

using Microsoft.Finance.Dimension;
using Microsoft.FixedAssets.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Insurance;

permissionset 4465 "Insurance Journals - Post"
{
    Access = Public;
    Assignable = false;
    Caption = 'Post insurance journals';

    Permissions = tabledata "Dimension Combination" = R,
                  tabledata "Dimension Value Combination" = R,
                  tabledata "FA Class" = R,
                  tabledata "FA Depreciation Book" = R,
                  tabledata "FA Journal Setup" = R,
                  tabledata "FA Location" = R,
                  tabledata "FA Subclass" = R,
                  tabledata "Fixed Asset" = R,
                  tabledata "Ins. Coverage Ledger Entry" = rim,
                  tabledata Insurance = R,
                  tabledata "Insurance Journal Batch" = RID,
                  tabledata "Insurance Journal Line" = RIMD,
                  tabledata "Insurance Journal Template" = RI,
                  tabledata "Insurance Register" = Rim;
}
