namespace System.Security.AccessControl;

using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Setup;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Posting;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Maintenance;

permissionset 3668 "D365 FA, SETUP"
{
    Assignable = true;

    Caption = 'Dyn. 365 Fixed Assets Setup';
    Permissions = tabledata "Depreciation Book" = RIMD,
                  tabledata "Depreciation Table Header" = RIMD,
                  tabledata "Depreciation Table Line" = RIMD,
                  tabledata "FA Allocation" = RIMD,
                  tabledata "FA Class" = RIMD,
                  tabledata "FA Date Type" = RIMD,
                  tabledata "FA Depreciation Book" = RIMD,
                  tabledata "FA Journal Batch" = RIMD,
                  tabledata "FA Journal Setup" = RIMD,
                  tabledata "FA Journal Template" = RIMD,
                  tabledata "FA Location" = RIMD,
                  tabledata "FA Matrix Posting Type" = RIMD,
                  tabledata "FA Posting Group" = RIMD,
                  tabledata "FA Posting Type" = RIMD,
                  tabledata "FA Posting Type Setup" = RIMD,
                  tabledata "FA Reclass. Journal Batch" = RIMD,
                  tabledata "FA Reclass. Journal Template" = RIMD,
                  tabledata "FA Setup" = RIMD,
                  tabledata "FA Subclass" = RIMD,
                  tabledata "G/L Account" = R,
                  tabledata "Ins. Coverage Ledger Entry" = rm,
                  tabledata "Insurance Journal Batch" = RIMD,
                  tabledata "Insurance Journal Template" = RIMD,
                  tabledata "Insurance Type" = RIMD,
                  tabledata Maintenance = RIMD;
}
