namespace System.Security.AccessControl;

using Microsoft.Bank.Reconciliation;
using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Statement;
using Microsoft.Bank.Setup;
using Microsoft.Bank.Check;
using Microsoft.Foundation.Comment;
using Microsoft.CRM.Duplicates;
using Microsoft.CRM.Contact;
using Microsoft.CRM.BusinessRelation;
using Microsoft.Foundation.Address;
using Microsoft.Finance.Currency;
using Microsoft.Sales.Receivables;
using Microsoft.Finance.Dimension;
using Microsoft.HumanResources.Payables;
using Microsoft.FixedAssets.Ledger;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.CRM.Interaction;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.CRM.Opportunity;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Archive;
using Microsoft.Sales.History;
using Microsoft.Sales.Document;
using Microsoft.Sales.Archive;
using Microsoft.CRM.Task;
using Microsoft.Purchases.Payables;
using Microsoft.CRM.Team;
using Microsoft.Inventory.Intrastat;

permissionset 7785 "Bank Accounts - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Edit bank accounts';

    Permissions = tabledata "Bank Acc. Reconciliation" = r,
                  tabledata "Bank Acc. Reconciliation Line" = r,
                  tabledata "Bank Account" = RIMD,
                  tabledata "Bank Account Ledger Entry" = Rm,
                  tabledata "Bank Account Posting Group" = R,
                  tabledata "Bank Account Statement" = R,
                  tabledata "Bank Account Statement Line" = R,
                  tabledata "Bank Clearing Standard" = RIMD,
                  tabledata "Check Ledger Entry" = Rm,
                  tabledata "Comment Line" = RIMD,
                  tabledata "Cont. Duplicate Search String" = RID,
                  tabledata Contact = RIM,
                  tabledata "Contact Business Relation" = ImD,
                  tabledata "Contact Duplicate" = r,
                  tabledata "Country/Region" = R,
                  tabledata Currency = R,
                  tabledata "Cust. Ledger Entry" = r,
                  tabledata "Default Dimension" = RIMD,
                  tabledata "Duplicate Search String Setup" = R,
                  tabledata "Employee Ledger Entry" = rm,
                  tabledata "FA Ledger Entry" = r,
                  tabledata "G/L Entry" = rm,
                  tabledata "Gen. Journal Batch" = rm,
                  tabledata "Gen. Journal Line" = r,
                  tabledata "Gen. Journal Template" = r,
                  tabledata "Interaction Log Entry" = R,
                  tabledata "Maintenance Ledger Entry" = r,
                  tabledata Opportunity = R,
                  tabledata "Payment Method" = rm,
                  tabledata "Payment Rec. Related Entry" = R,
                  tabledata "Pmt. Rec. Applied-to Entry" = R,
                  tabledata "Post Code" = Ri,
                  tabledata "Purch. Cr. Memo Hdr." = r,
                  tabledata "Purch. Inv. Header" = rm,
                  tabledata "Purch. Rcpt. Header" = rm,
                  tabledata "Purchase Header" = r,
                  tabledata "Purchase Header Archive" = r,
                  tabledata "Return Receipt Header" = r,
                  tabledata "Return Shipment Header" = r,
                  tabledata "Sales Cr.Memo Header" = r,
                  tabledata "Sales Header" = r,
                  tabledata "Sales Header Archive" = r,
                  tabledata "Sales Invoice Header" = r,
                  tabledata "Sales Shipment Header" = r,
                  tabledata "Salesperson/Purchaser" = R,
                  tabledata "Standard General Journal" = r,
                  tabledata "Standard General Journal Line" = r,
                  tabledata Territory = R,
                  tabledata "To-do" = R,
                  tabledata "Vendor Ledger Entry" = rm;
}
