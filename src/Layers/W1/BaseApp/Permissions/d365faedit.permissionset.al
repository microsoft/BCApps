namespace System.Security.AccessControl;

using Microsoft.Finance.Currency;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Posting;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.Foundation.NoSeries;
using Microsoft.HumanResources.Employee;

permissionset 8787 "D365 FA, EDIT"
{
    Assignable = true;
    Caption = 'Dyn. 365 Create Fixed Assets';

    IncludedPermissionSets = "D365 FA, VIEW";

    Permissions = tabledata "Currency Exchange Rate" = RIM,
                  tabledata "Depreciation Book" = IMD,
                  tabledata "Depreciation Table Buffer" = IMD,
                  tabledata Employee = r,
                  tabledata "FA Buffer Projection" = IMD,
                  tabledata "FA Depreciation Book" = im,
                  tabledata "FA G/L Posting Buffer" = IMD,
                  tabledata "FA Journal Batch" = IMD,
                  tabledata "FA Journal Line" = IMD,
                  tabledata "FA Journal Setup" = IMD,
                  tabledata "FA Ledger Entry" = imd,
                  tabledata "FA Posting Group" = IM,
                  tabledata "FA Posting Group Buffer" = IMD,
                  tabledata "FA Posting Type Setup" = IMD,
                  tabledata "FA Reclass. Journal Batch" = IMD,
                  tabledata "FA Reclass. Journal Line" = IMD,
                  tabledata "FA Register" = imd,
                  tabledata "Fixed Asset" = IMD,
                  tabledata "Ins. Coverage Ledger Entry" = imd,
                  tabledata Insurance = IMD,
                  tabledata "Insurance Journal Batch" = IMD,
                  tabledata "Insurance Journal Line" = IMD,
                  tabledata "Insurance Register" = imd,
                  tabledata "Main Asset Component" = IMD,
                  tabledata "Maintenance Ledger Entry" = imd,
                  tabledata "Maintenance Registration" = IMD,
                  tabledata "No. Series" = RI,
                  tabledata "No. Series Line" = RI,
                  tabledata "Total Value Insured" = IMD;
}
