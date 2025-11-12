namespace System.Security.AccessControl;

using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Bank.Payment;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.AllocationAccount;
using Microsoft.Finance.Analysis;
using Microsoft.Bank.Reconciliation;
using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Statement;
using Microsoft.Bank.Setup;
using Microsoft.Finance.Consolidation;
using Microsoft.Bank.Check;
using Microsoft.Foundation.Comment;
using Microsoft.Finance.Currency;
using Microsoft.Sales.Receivables;
using System.IO;
using Microsoft.Purchases.Payables;
using Microsoft.HumanResources.Payables;
using Microsoft.HumanResources.Employee;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Journal;
using System.Xml;
using Microsoft.Finance.SalesTax;
using System.Security.User;
using Microsoft.Foundation.Period;
using Microsoft.Foundation.BatchProcessing;

permissionset 6720 "General Ledger - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'G/L periodic activities';

    Permissions = tabledata "Accounting Period" = RIMD,
                  tabledata "Alloc. Acc. Manual Override" = RIMD,
                  tabledata "Alloc. Account Distribution" = RIMD,
                  tabledata "Allocation Account" = RIMD,
                  tabledata "Allocation Line" = RIMD,
                  tabledata "Analysis View" = RIMD,
                  tabledata "Analysis View Budget Entry" = RIMD,
                  tabledata "Analysis View Entry" = RIMD,
                  tabledata "Analysis View Filter" = RIMD,
                  tabledata "Applied Payment Entry" = RIMD,
                  tabledata "Bank Acc. Reconciliation" = RIMD,
                  tabledata "Bank Acc. Reconciliation Line" = RIMD,
                  tabledata "Bank Account" = RM,
                  tabledata "Bank Account Ledger Entry" = RM,
                  tabledata "Bank Account Statement" = RI,
                  tabledata "Bank Account Statement Line" = RI,
                  tabledata "Bank Clearing Standard" = RM,
                  tabledata "Bank Export/Import Setup" = R,
                  tabledata "Bank Pmt. Appl. Rule" = RIMD,
                  tabledata "Bank Pmt. Appl. Settings" = RIMD,
                  tabledata "Bank Stmt Multiple Match Line" = RIMD,
                  tabledata "Batch Processing Parameter" = Rimd,
                  tabledata "Batch Processing Session Map" = Rimd,
                  tabledata "Business Unit" = RIMD,
                  tabledata "Business Unit Information" = RIMD,
                  tabledata "Business Unit Setup" = RIMD,
                  tabledata "Check Ledger Entry" = RM,
                  tabledata "Comment Line" = R,
                  tabledata "Consolidation Account" = RIMD,
                  tabledata "Credit Trans Re-export History" = RIMD,
                  tabledata "Credit Transfer Entry" = RIMD,
                  tabledata "Credit Transfer Register" = RIMD,
                  tabledata Currency = RMD,
                  tabledata "Currency Exchange Rate" = R,
                  tabledata "Cust. Ledger Entry" = Rmd,
                  tabledata Customer = R,
                  tabledata "Customer Bank Account" = R,
                  tabledata "Customer Posting Group" = R,
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
                  tabledata "Date Compr. Register" = RimD,
                  tabledata "Detailed Cust. Ledg. Entry" = Rimd,
                  tabledata "Detailed Vendor Ledg. Entry" = Rimd,
                  tabledata "Employee Ledger Entry" = Rmd,
                  tabledata "Employee Posting Group" = R,
                  tabledata "Exch. Rate Adjmt. Reg." = RimD,
                  tabledata "Exch. Rate Adjmt. Ledg. Entry" = RimD,
                  tabledata "G/L Account" = R,
                  tabledata "G/L Budget Entry" = RIMD,
                  tabledata "G/L Budget Name" = RIMD,
                  tabledata "G/L Entry - VAT Entry Link" = Rimd,
                  tabledata "G/L Entry" = Rimd,
                  tabledata "G/L Register" = Rimd,
                  tabledata "Gen. Business Posting Group" = R,
                  tabledata "Gen. Jnl. Allocation" = RIMD,
                  tabledata "Gen. Journal Batch" = RId,
                  tabledata "Gen. Journal Line" = RIMD,
                  tabledata "Gen. Journal Template" = RI,
                  tabledata "Gen. Product Posting Group" = R,
                  tabledata "General Ledger Setup" = r,
                  tabledata "General Posting Setup" = R,
                  tabledata "Intermediate Data Import" = Rimd,
                  tabledata "Ledger Entry Matching Buffer" = RIMD,
                  tabledata "Outstanding Bank Transaction" = RIMD,
                  tabledata "Payment Application Proposal" = RIMD,
                  tabledata "Payment Export Data" = Rimd,
                  tabledata "Payment Jnl. Export Error Text" = RIMD,
                  tabledata "Payment Matching Details" = RIMD,
                  tabledata "Payment Method" = R,
                  tabledata "Posted Payment Recon. Hdr" = RI,
                  tabledata "Posted Payment Recon. Line" = RI,
                  tabledata "Reason Code" = R,
                  tabledata "Referenced XML Schema" = RIMD,
                  tabledata "Source Code Setup" = R,
                  tabledata "Tax Area" = R,
                  tabledata "Tax Area Line" = R,
                  tabledata "Tax Detail" = R,
                  tabledata "Tax Group" = R,
                  tabledata "Tax Jurisdiction" = R,
                  tabledata "User Setup" = r,
                  tabledata "VAT Assisted Setup Bus. Grp." = R,
                  tabledata "VAT Assisted Setup Templates" = R,
                  tabledata "VAT Business Posting Group" = R,
                  tabledata "VAT Entry" = Rimd,
                  tabledata "VAT Posting Setup" = R,
                  tabledata "VAT Product Posting Group" = R,
                  tabledata "VAT Setup" = R,
                  tabledata "VAT Posting Parameters" = R,
                  tabledata "VAT Rate Change Conversion" = R,
                  tabledata "VAT Rate Change Log Entry" = Ri,
                  tabledata "VAT Rate Change Setup" = R,
                  tabledata "VAT Reg. No. Srv Config" = RIMD,
                  tabledata "VAT Reg. No. Srv. Template" = RIMD,
                  tabledata "VAT Registration Log" = RIMD,
                  tabledata "VAT Registration Log Details" = RIMD,
                  tabledata "VAT Reporting Code" = R,
                  tabledata "VAT Setup Posting Groups" = R,
                  tabledata "VAT Statement Line" = RIMD,
                  tabledata "VAT Statement Name" = RIMD,
                  tabledata "VAT Statement Template" = RIMD,
                  tabledata "Alt. Cust. VAT Reg." = R,
                  tabledata Vendor = R,
                  tabledata "Vendor Bank Account" = R,
                  tabledata "Vendor Ledger Entry" = Rmd,
                  tabledata "Vendor Posting Group" = R,
                  tabledata "XML Buffer" = R,
                  tabledata "XML Schema" = RIMD,
                  tabledata "XML Schema Element" = RIMD,
                  tabledata "XML Schema Restriction" = RIMD;
}
