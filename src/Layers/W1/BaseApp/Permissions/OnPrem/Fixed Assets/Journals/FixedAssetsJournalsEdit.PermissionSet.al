namespace System.Security.AccessControl;

using Microsoft.Bank.BankAccount;
using Microsoft.Finance.Currency;
using Microsoft.Sales.Customer;
using Microsoft.Finance.Dimension;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Setup;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Posting;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.Finance.SalesTax;
using Microsoft.Purchases.Vendor;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Calculation;

permissionset 505 "Fixed Assets Journals - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Create entries in FA journals';

    Permissions = tabledata "Bank Account" = R,
                  tabledata Currency = R,
                  tabledata "Currency Exchange Rate" = R,
                  tabledata Customer = R,
                  tabledata "Default Dimension" = R,
                  tabledata "Default Dimension Priority" = R,
                  tabledata "Depreciation Table Header" = R,
                  tabledata "Depreciation Table Line" = R,
                  tabledata "FA Allocation" = R,
                  tabledata "FA Class" = R,
                  tabledata "FA Depreciation Book" = R,
                  tabledata "FA Journal Batch" = RI,
                  tabledata "FA Journal Line" = RIMD,
                  tabledata "FA Journal Setup" = R,
                  tabledata "FA Journal Template" = RI,
                  tabledata "FA Ledger Entry" = R,
                  tabledata "FA Location" = R,
                  tabledata "FA Posting Group" = R,
                  tabledata "FA Posting Type Setup" = R,
                  tabledata "FA Reclass. Journal Batch" = RI,
                  tabledata "FA Reclass. Journal Line" = RIMD,
                  tabledata "FA Reclass. Journal Template" = RI,
                  tabledata "FA Subclass" = R,
                  tabledata "Fixed Asset" = R,
                  tabledata "G/L Account" = R,
                  tabledata "Gen. Business Posting Group" = R,
                  tabledata "Gen. Jnl. Allocation" = RIMD,
                  tabledata "Gen. Journal Batch" = RI,
                  tabledata "Gen. Journal Line" = RIMD,
                  tabledata "Gen. Journal Template" = RI,
                  tabledata "Gen. Product Posting Group" = R,
                  tabledata "General Ledger Setup" = RM,
                  tabledata "General Posting Setup" = R,
                  tabledata "Ins. Coverage Ledger Entry" = R,
                  tabledata Insurance = R,
                  tabledata "Main Asset Component" = R,
                  tabledata Maintenance = R,
                  tabledata "Maintenance Ledger Entry" = R,
                  tabledata "Maintenance Registration" = R,
                  tabledata "Reason Code" = R,
                  tabledata "Source Code Setup" = R,
                  tabledata "Tax Area" = R,
                  tabledata "Tax Area Line" = R,
                  tabledata "Tax Detail" = R,
                  tabledata "Tax Group" = R,
                  tabledata "Tax Jurisdiction" = R,
                  tabledata "VAT Assisted Setup Bus. Grp." = R,
                  tabledata "VAT Assisted Setup Templates" = R,
                  tabledata "VAT Business Posting Group" = R,
                  tabledata "VAT Posting Setup" = R,
                  tabledata "VAT Product Posting Group" = R,
                  tabledata "VAT Rate Change Conversion" = R,
                  tabledata "VAT Rate Change Log Entry" = Ri,
                  tabledata "VAT Rate Change Setup" = R,
                  tabledata "VAT Reporting Code" = R,
                  tabledata "VAT Setup Posting Groups" = R,
                  tabledata "VAT Setup" = R,
                  tabledata "VAT Posting Parameters" = R,
                  tabledata Vendor = R;
}
