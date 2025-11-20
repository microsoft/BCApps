namespace System.Security.AccessControl;

using Microsoft.Finance.AllocationAccount;
using Microsoft.Bank.BankAccount;
using Microsoft.Foundation.Comment;
using Microsoft.Finance.Currency;
using System.IO;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.GeneralLedger.Journal;
using System.Xml;
using Microsoft.Finance.SalesTax;
using Microsoft.Bank.Reconciliation;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Finance.VAT.Reporting;

permissionset 4103 "General Ledger Journals - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Create entries in G/L journals';

    Permissions =
                  tabledata "Alloc. Acc. Manual Override" = R,
                  tabledata "Alloc. Account Distribution" = R,
                  tabledata "Allocation Account" = RIMD,
                  tabledata "Allocation Line" = RIMD,
                  tabledata "Bank Account" = R,
                  tabledata "Comment Line" = R,
                  tabledata Currency = R,
                  tabledata "Currency Exchange Rate" = R,
                  tabledata "Data Exch." = Rimd,
                  tabledata "Data Exch. Column Def" = R,
                  tabledata "Data Exch. Def" = R,
                  tabledata "Data Exch. Field" = Rimd,
                  tabledata "Data Exch. Field Mapping" = R,
                  tabledata "Data Exch. Line Def" = R,
                  tabledata "Data Exch. Mapping" = R,
                  tabledata "Data Exch. Field Grouping" = R,
                  tabledata "Data Exch. FlowField Gr. Buff." = R,
                  tabledata "Data Exchange Type" = Rimd,
                  tabledata "Data Exch. Table Filter" = Rimd,
                  tabledata "Default Dimension" = R,
                  tabledata "Default Dimension Priority" = R,
                  tabledata "G/L Account" = R,
                  tabledata "Gen. Business Posting Group" = R,
                  tabledata "Gen. Jnl. Allocation" = RIMD,
                  tabledata "Gen. Journal Batch" = RI,
                  tabledata "Gen. Journal Line" = RIMD,
                  tabledata "Gen. Journal Template" = RI,
                  tabledata "Gen. Product Posting Group" = R,
                  tabledata "General Posting Setup" = R,
                  tabledata "Intermediate Data Import" = Rimd,
                  tabledata "Reason Code" = R,
                  tabledata "Referenced XML Schema" = RIMD,
                  tabledata "Source Code Setup" = R,
                  tabledata "Tax Area" = R,
                  tabledata "Tax Area Line" = R,
                  tabledata "Tax Detail" = R,
                  tabledata "Tax Group" = R,
                  tabledata "Tax Jurisdiction" = R,
                  tabledata "Text-to-Account Mapping" = RIMD,
                  tabledata "VAT Assisted Setup Bus. Grp." = R,
                  tabledata "VAT Assisted Setup Templates" = R,
                  tabledata "VAT Business Posting Group" = R,
                  tabledata "VAT Posting Setup" = R,
                  tabledata "VAT Setup" = R,
                  tabledata "VAT Posting Parameters" = R,
                  tabledata "VAT Product Posting Group" = R,
                  tabledata "VAT Rate Change Conversion" = R,
                  tabledata "VAT Rate Change Log Entry" = Ri,
                  tabledata "VAT Rate Change Setup" = R,
                  tabledata "VAT Reporting Code" = R,
                  tabledata "VAT Setup Posting Groups" = R,
                  tabledata "XML Buffer" = R,
                  tabledata "XML Schema" = RIMD,
                  tabledata "XML Schema Element" = RIMD,
                  tabledata "XML Schema Restriction" = RIMD;
}
