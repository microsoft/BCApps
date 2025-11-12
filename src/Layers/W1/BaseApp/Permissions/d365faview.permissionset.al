namespace System.Security.AccessControl;

using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Setup;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Posting;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Maintenance;

permissionset 2381 "D365 FA, VIEW"
{
    Assignable = true;

    Caption = 'Dynamics 365 View Fixed Assets';
    Permissions = tabledata "Depreciation Book" = R,
                  tabledata "Depreciation Table Buffer" = R,
                  tabledata "Depreciation Table Header" = R,
                  tabledata "Depreciation Table Line" = R,
                  tabledata "FA Allocation" = R,
                  tabledata "FA Buffer Projection" = R,
                  tabledata "FA Class" = R,
                  tabledata "FA Date Type" = R,
                  tabledata "FA Depreciation Book" = R,
                  tabledata "FA G/L Posting Buffer" = R,
                  tabledata "FA Journal Batch" = R,
                  tabledata "FA Journal Line" = R,
                  tabledata "FA Journal Setup" = R,
                  tabledata "FA Journal Template" = R,
                  tabledata "FA Ledger Entry" = R,
                  tabledata "FA Location" = R,
                  tabledata "FA Matrix Posting Type" = R,
                  tabledata "FA Posting Group" = R,
                  tabledata "FA Posting Group Buffer" = R,
                  tabledata "FA Posting Type" = R,
                  tabledata "FA Posting Type Setup" = R,
                  tabledata "FA Reclass. Journal Batch" = R,
                  tabledata "FA Reclass. Journal Line" = R,
                  tabledata "FA Reclass. Journal Template" = R,
                  tabledata "FA Register" = R,
                  tabledata "FA Setup" = R,
                  tabledata "FA Subclass" = R,
                  tabledata "Fixed Asset" = R,
                  tabledata "G/L Account" = R,
                  tabledata "Ins. Coverage Ledger Entry" = R,
                  tabledata Insurance = R,
                  tabledata "Insurance Journal Batch" = R,
                  tabledata "Insurance Journal Line" = R,
                  tabledata "Insurance Journal Template" = R,
                  tabledata "Insurance Register" = R,
                  tabledata "Insurance Type" = R,
                  tabledata "Main Asset Component" = R,
                  tabledata Maintenance = R,
                  tabledata "Maintenance Ledger Entry" = R,
                  tabledata "Maintenance Registration" = R,
                  tabledata "Total Value Insured" = R;
}
