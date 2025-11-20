namespace System.Security.AccessControl;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Setup;
using Microsoft.Bank.Reconciliation;
using Microsoft.Foundation.Comment;
using Microsoft.Finance.Currency;
using Microsoft.Sales.Customer;
using System.IO;
using Microsoft.Finance.Dimension;
using Microsoft.Purchases.Payables;
using Microsoft.HumanResources.Payables;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.PaymentTerms;
using System.Xml;
using Microsoft.Finance.SalesTax;
using Microsoft.Purchases.Vendor;
using Microsoft.Bank.Payment;
using Microsoft.Foundation.AuditCodes;
using Microsoft.CRM.Team;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Finance.VAT.Reporting;

permissionset 8824 "Payables Journals - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Create entries in jnls. (P&P)';

    Permissions = tabledata "Bank Account" = R,
                  tabledata "Bank Export/Import Setup" = R,
                  tabledata "Bank Pmt. Appl. Rule" = RIMD,
                  tabledata "Bank Pmt. Appl. Settings" = RIMD,
                  tabledata "Bank Stmt Multiple Match Line" = RIMD,
                  tabledata "Comment Line" = R,
                  tabledata "Credit Trans Re-export History" = RIMD,
                  tabledata "Credit Transfer Entry" = RIMD,
                  tabledata "Credit Transfer Register" = RIMD,
                  tabledata Currency = R,
                  tabledata "Currency Exchange Rate" = R,
                  tabledata Customer = R,
                  tabledata "Customer Bank Account" = R,
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
                  tabledata "Detailed Vendor Ledg. Entry" = Ri,
                  tabledata "Employee Ledger Entry" = Rm,
                  tabledata "G/L Account" = R,
                  tabledata "Gen. Business Posting Group" = R,
                  tabledata "Gen. Jnl. Allocation" = RIMD,
                  tabledata "Gen. Journal Batch" = RI,
                  tabledata "Gen. Journal Line" = RIMD,
                  tabledata "Gen. Journal Template" = RI,
                  tabledata "Gen. Product Posting Group" = R,
                  tabledata "General Posting Setup" = R,
                  tabledata "Intermediate Data Import" = Rimd,
                  tabledata "Ledger Entry Matching Buffer" = RIMD,
                  tabledata "Outstanding Bank Transaction" = RIMD,
                  tabledata "Payment Application Proposal" = RIMD,
                  tabledata "Payment Export Data" = Rimd,
                  tabledata "Payment Jnl. Export Error Text" = RIMD,
                  tabledata "Payment Matching Details" = RIMD,
                  tabledata "Payment Method" = R,
                  tabledata "Payment Terms" = R,
                  tabledata "Reason Code" = R,
                  tabledata "Referenced XML Schema" = RIMD,
                  tabledata "Salesperson/Purchaser" = R,
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
                  tabledata Vendor = R,
                  tabledata "Vendor Bank Account" = R,
                  tabledata "Vendor Ledger Entry" = Rm,
                  tabledata "XML Buffer" = R,
                  tabledata "XML Schema" = RIMD,
                  tabledata "XML Schema Element" = RIMD,
                  tabledata "XML Schema Restriction" = RIMD;
}
