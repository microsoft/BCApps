namespace System.Security.AccessControl;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Ledger;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.Foundation.Period;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.AuditCodes;

permissionset 8689 "Fixed Assets - View"
{
    Access = Public;
    Assignable = false;
    Caption = 'FA periodic activities';

    Permissions = tabledata "Accounting Period" = r,
                  tabledata "Date Compr. Register" = RimD,
                  tabledata "Depreciation Book" = R,
                  tabledata "Depreciation Table Header" = R,
                  tabledata "Depreciation Table Line" = R,
                  tabledata "FA Allocation" = R,
                  tabledata "FA Depreciation Book" = Rm,
                  tabledata "FA Journal Batch" = R,
                  tabledata "FA Journal Line" = Ri,
                  tabledata "FA Journal Setup" = R,
                  tabledata "FA Journal Template" = R,
                  tabledata "FA Ledger Entry" = Rimd,
                  tabledata "FA Posting Group" = R,
                  tabledata "FA Register" = Rimd,
                  tabledata "Fixed Asset" = R,
                  tabledata "G/L Register" = Rimd,
                  tabledata "Gen. Journal Batch" = R,
                  tabledata "Gen. Journal Line" = Ri,
                  tabledata "Gen. Journal Template" = R,
                  tabledata "General Ledger Setup" = rm,
                  tabledata "VAT Setup" = rm,
                  tabledata "General Posting Setup" = r,
                  tabledata "Ins. Coverage Ledger Entry" = Rimd,
                  tabledata Insurance = R,
                  tabledata "Insurance Journal Batch" = R,
                  tabledata "Insurance Journal Line" = Ri,
                  tabledata "Insurance Journal Template" = R,
                  tabledata "Insurance Register" = Rimd,
                  tabledata "Maintenance Ledger Entry" = Rimd,
                  tabledata "Source Code Setup" = R;
}
