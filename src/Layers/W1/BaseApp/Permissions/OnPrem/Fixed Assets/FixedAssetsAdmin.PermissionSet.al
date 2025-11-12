namespace System.Security.AccessControl;

using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Posting;
using Microsoft.FixedAssets.Setup;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.Insurance;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Reporting;

permissionset 7568 "Fixed Assets - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'FA setup';

    Permissions = tabledata "Depreciation Book" = RIMD,
                  tabledata "FA Allocation" = RIMD,
                  tabledata "FA Depreciation Book" = RIMD,
                  tabledata "FA Journal Batch" = RIMD,
                  tabledata "FA Journal Line" = MD,
                  tabledata "FA Journal Setup" = RIMD,
                  tabledata "FA Journal Template" = RIMD,
                  tabledata "FA Posting Group" = RIMD,
                  tabledata "FA Posting Type Setup" = RiMd,
                  tabledata "FA Reclass. Journal Batch" = RIMD,
                  tabledata "FA Reclass. Journal Line" = MD,
                  tabledata "FA Reclass. Journal Template" = RIMD,
                  tabledata "FA Setup" = RIMD,
                  tabledata "G/L Account" = R,
                  tabledata "Gen. Jnl. Allocation" = MD,
                  tabledata "Gen. Journal Batch" = RIMD,
                  tabledata "Gen. Journal Line" = MD,
                  tabledata "Gen. Journal Template" = RIMD,
                  tabledata "Insurance Journal Batch" = RIMD,
                  tabledata "Insurance Journal Line" = MD,
                  tabledata "Insurance Journal Template" = RIMD,
                  tabledata "Reason Code" = R,
                  tabledata "Report Selections" = RIMD,
                  tabledata "Source Code Setup" = R;
}
