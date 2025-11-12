namespace System.Security.AccessControl;

using Microsoft.Finance.AllocationAccount;
using Microsoft.Finance.Analysis;
using Microsoft.Bank.Reconciliation;
using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Statement;
using Microsoft.Bank.Setup;
using Microsoft.Bank.Check;
using Microsoft.CRM.Duplicates;
using Microsoft.CRM.Contact;
using Microsoft.CRM.BusinessRelation;
using Microsoft.Finance.Currency;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Customer;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Bank.DirectDebit;
using Microsoft.HumanResources.Employee;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.CRM.Interaction;
using System.IO;
using Microsoft.CRM.Opportunity;
using Microsoft.Bank.PositivePay;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Archive;
using Microsoft.Sales.History;
using Microsoft.Sales.Archive;
using Microsoft.CRM.Task;
using Microsoft.Purchases.Vendor;
using Microsoft.Foundation.BatchProcessing;
using Microsoft.Bank.Payment;
using Microsoft.Foundation.Period;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Reporting;

permissionset 5759 "D365 BANKING"
{
    Assignable = true;

    Caption = 'Dynamics 365 Banking';
    Permissions =
                  tabledata "Alloc. Account Distribution" = RIMD,
                  tabledata "Allocation Account" = RIMD,
                  tabledata "Allocation Line" = RIMD,
                  tabledata "Analysis View" = rimd,
                  tabledata "Analysis View Entry" = rim,
                  tabledata "Analysis View Filter" = r,
                  tabledata "Applied Payment Entry" = RIMD,
                  tabledata "Bank Acc. Reconciliation" = RIMD,
                  tabledata "Bank Acc. Reconciliation Line" = RIMD,
                  tabledata "Bank Acc. Rec. Match Buffer" = RIMD,
                  tabledata "Bank Account" = RIMD,
                  tabledata "Bank Account Ledger Entry" = Rimd,
                  tabledata "Bank Account Posting Group" = R,
                  tabledata "Bank Account Statement" = RimD,
                  tabledata "Bank Account Statement Line" = Rimd,
                  tabledata "Bank Clearing Standard" = RIMD,
                  tabledata "Bank Pmt. Appl. Rule" = RIMD,
                  tabledata "Bank Pmt. Appl. Settings" = RIMD,
                  tabledata "Bank Stmt Multiple Match Line" = RIMD,
                  tabledata "Batch Processing Parameter" = Rimd,
                  tabledata "Batch Processing Session Map" = Rimd,
                  tabledata "Check Ledger Entry" = Rimd,
                  tabledata "Cont. Duplicate Search String" = RID,
                  tabledata Contact = RIM,
                  tabledata "Contact Business Relation" = RImD,
                  tabledata "Contact Duplicate" = r,
                  tabledata "Credit Trans Re-export History" = RIMD,
                  tabledata "Credit Transfer Entry" = RIMD,
                  tabledata "Credit Transfer Register" = RIMD,
                  tabledata "Curr. Exch. Rate Update Setup" = RIMD,
                  tabledata Currency = RM,
                  tabledata "Currency Exchange Rate" = RIMD,
                  tabledata "Cust. Ledger Entry" = Rimd,
                  tabledata "Customer Bank Account" = R,
                  tabledata "Date Compr. Register" = R,
                  tabledata "Detailed Cust. Ledg. Entry" = Rimd,
                  tabledata "Detailed Employee Ledger Entry" = Rimd,
                  tabledata "Detailed Vendor Ledg. Entry" = Rimd,
                  tabledata "Direct Debit Collection" = RIMD,
                  tabledata "Direct Debit Collection Entry" = RIMD,
                  tabledata "Duplicate Search String Setup" = R,
                  tabledata "Employee Ledger Entry" = Rimd,
                  tabledata "Employee Posting Group" = RIMD,
                  tabledata "Exch. Rate Adjmt. Reg." = Rimd,
                  tabledata "Exch. Rate Adjmt. Ledg. Entry" = Rimd,
                  tabledata "G/L Account" = R,
                  tabledata "G/L Entry - VAT Entry Link" = Rimd,
                  tabledata "G/L Entry" = Rim,
                  tabledata "G/L Register" = Rim,
                  tabledata "Gen. Journal Line" = RIMD,
                  tabledata "Gen. Journal Template" = RIMD,
                  tabledata "Interaction Log Entry" = R,
                  tabledata "Intermediate Data Import" = Rimd,
                  tabledata Opportunity = R,
                  tabledata "Payment Application Proposal" = RIMD,
                  tabledata "Payment Matching Details" = RIMD,
                  tabledata "Payment Method" = Rm,
                  tabledata "Payment Rec. Related Entry" = RIMD,
                  tabledata "Pmt. Rec. Applied-to Entry" = RIMD,
                  tabledata "Positive Pay Entry" = RIMD,
                  tabledata "Positive Pay Entry Detail" = RIMD,
                  tabledata "Posted Payment Recon. Hdr" = Rimd,
                  tabledata "Posted Payment Recon. Line" = RIMD,
                  tabledata "Purch. Cr. Memo Hdr." = R,
                  tabledata "Purch. Cr. Memo Line" = R,
                  tabledata "Purch. Inv. Header" = Rm,
                  tabledata "Purch. Inv. Line" = R,
                  tabledata "Purch. Rcpt. Header" = Rm,
                  tabledata "Purch. Rcpt. Line" = R,
                  tabledata "Purchase Header Archive" = r,
                  tabledata "Purchase Line Archive" = r,
                  tabledata "Return Receipt Header" = r,
                  tabledata "Return Shipment Header" = r,
                  tabledata "Sales Cr.Memo Header" = R,
                  tabledata "Sales Cr.Memo Line" = R,
                  tabledata "Sales Header Archive" = r,
                  tabledata "Sales Invoice Header" = R,
                  tabledata "Sales Invoice Line" = R,
                  tabledata "Sales Line Archive" = r,
                  tabledata "Sales Shipment Header" = R,
                  tabledata "Sales Shipment Line" = R,
                  tabledata "Standard General Journal Line" = RIMD,
                  tabledata "SWIFT Code" = RIMD,
                  tabledata "To-do" = R,
                  tabledata "VAT Entry" = Rimd,
                  tabledata "VAT Setup" = R,
                  tabledata "VAT Posting Parameters" = R,
                  tabledata "VAT Reporting Code" = R,
                  tabledata "Vendor Bank Account" = R,
                  tabledata "Vendor Ledger Entry" = Rimd,
                  tabledata "Vendor Posting Group" = RIMD;
}
