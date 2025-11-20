namespace System.Security.AccessControl;

using Microsoft.Purchases.Vendor;
using Microsoft.Purchases.Payables;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.Analysis;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Foundation.Comment;
using Microsoft.Finance.Currency;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Customer;
using Microsoft.Finance.Dimension;
using Microsoft.HumanResources.Payables;
using Microsoft.HumanResources.Employee;
using Microsoft.Foundation.ExtendedText;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Ledger;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Partner;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Archive;
using Microsoft.Sales.History;
using Microsoft.Sales.Document;
using Microsoft.Sales.Archive;
using Microsoft.Finance.SalesTax;
using Microsoft.Foundation.Period;
using Microsoft.Inventory.Item;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.Job;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Finance.VAT.Reporting;

permissionset 9111 "General Ledger Accounts - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Edit G/L accounts';

    Permissions = tabledata "Accounting Period" = R,
                  tabledata "Analysis View" = rimd,
                  tabledata "Analysis View Budget Entry" = Rd,
                  tabledata "Analysis View Entry" = Rimd,
                  tabledata "Analysis View Filter" = r,
                  tabledata "Bank Account Ledger Entry" = r,
                  tabledata "Bank Account Posting Group" = r,
                  tabledata "Check Ledger Entry" = r,
                  tabledata "Comment Line" = RIMD,
                  tabledata Currency = rm,
                  tabledata "Cust. Ledger Entry" = r,
                  tabledata "Customer Posting Group" = r,
                  tabledata "Default Dimension" = RIMD,
                  tabledata "Employee Ledger Entry" = r,
                  tabledata "Employee Posting Group" = r,
                  tabledata "Extended Text Header" = RIMD,
                  tabledata "Extended Text Line" = RIMD,
                  tabledata "FA Allocation" = r,
                  tabledata "FA Ledger Entry" = r,
                  tabledata "FA Posting Group" = r,
                  tabledata "G/L Account" = RIMD,
                  tabledata "G/L Account Category" = RIMD,
                  tabledata "G/L Account Source Currency" = R,
                  tabledata "G/L Budget Entry" = RD,
                  tabledata "G/L Entry" = Rm,
                  tabledata "Gen. Business Posting Group" = R,
                  tabledata "Gen. Jnl. Allocation" = r,
                  tabledata "Gen. Journal Batch" = r,
                  tabledata "Gen. Journal Line" = r,
                  tabledata "Gen. Journal Template" = r,
                  tabledata "Gen. Product Posting Group" = R,
                  tabledata "General Posting Setup" = r,
                  tabledata "IC Bank Account" = r,
                  tabledata "IC G/L Account" = Rm,
                  tabledata "IC Partner" = r,
                  tabledata "Inventory Posting Setup" = r,
                  tabledata "Job Journal Line" = r,
                  tabledata "Job Ledger Entry" = r,
                  tabledata "Job Planning Line - Calendar" = r,
                  tabledata "Job Planning Line" = r,
                  tabledata "Job Posting Group" = r,
                  tabledata "Maintenance Ledger Entry" = r,
                  tabledata "Payment Method" = r,
                  tabledata "Purch. Cr. Memo Hdr." = r,
                  tabledata "Purch. Cr. Memo Line" = r,
                  tabledata "Purch. Inv. Header" = r,
                  tabledata "Purch. Inv. Line" = r,
                  tabledata "Purch. Rcpt. Header" = r,
                  tabledata "Purch. Rcpt. Line" = r,
                  tabledata "Purchase Header" = r,
                  tabledata "Purchase Header Archive" = r,
                  tabledata "Purchase Line" = r,
                  tabledata "Return Receipt Header" = r,
                  tabledata "Return Receipt Line" = r,
                  tabledata "Return Shipment Header" = r,
                  tabledata "Return Shipment Line" = r,
                  tabledata "Sales Cr.Memo Header" = r,
                  tabledata "Sales Cr.Memo Line" = r,
                  tabledata "Sales Header" = r,
                  tabledata "Sales Header Archive" = r,
                  tabledata "Sales Invoice Header" = r,
                  tabledata "Sales Invoice Line" = r,
                  tabledata "Sales Line" = r,
                  tabledata "Sales Shipment Header" = r,
                  tabledata "Sales Shipment Line" = r,
                  tabledata "Standard General Journal" = r,
                  tabledata "Standard General Journal Line" = r,
                  tabledata "Standard Purchase Line" = r,
                  tabledata "Standard Sales Line" = r,
                  tabledata "Tax Area" = R,
                  tabledata "Tax Group" = R,
                  tabledata "VAT Assisted Setup Bus. Grp." = r,
                  tabledata "VAT Assisted Setup Templates" = r,
                  tabledata "VAT Business Posting Group" = R,
                  tabledata "VAT Posting Setup" = r,
                  tabledata "VAT Product Posting Group" = R,
                  tabledata "VAT Rate Change Conversion" = R,
                  tabledata "VAT Rate Change Log Entry" = Ri,
                  tabledata "VAT Rate Change Setup" = r,
                  tabledata "VAT Reporting Code" = R,
                  tabledata "VAT Setup Posting Groups" = r,
                  tabledata "VAT Setup" = R,
                  tabledata "VAT Posting Parameters" = R,
                  tabledata "Vendor Ledger Entry" = r,
                  tabledata "Vendor Posting Group" = r;
}
