namespace System.Security.AccessControl;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Check;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Period;
using Microsoft.Foundation.BatchProcessing;
using Microsoft.Foundation.Reporting;
using Microsoft.HumanResources.Payables;
using Microsoft.HumanResources.Employee;
using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.Comment;
using Microsoft.Intercompany.Dimension;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Outbox;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Tracking;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Purchases.Comment;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Warehouse.History;
using System.Security.User;
using Microsoft.Warehouse.Request;

permissionset 862 "Payables Documents - Post"
{
    Access = Public;
    Assignable = false;
    Caption = 'Post purchase orders, etc.';

    Permissions = tabledata "Accounting Period" = r,
                  tabledata "Analysis View" = rimd,
                  tabledata "Analysis View Entry" = rim,
                  tabledata "Analysis View Filter" = r,
                  tabledata "Avg. Cost Adjmt. Entry Point" = Ri,
                  tabledata "Bank Account" = m,
                  tabledata "Bank Account Ledger Entry" = rim,
                  tabledata "Batch Processing Parameter" = Rimd,
                  tabledata "Batch Processing Session Map" = Rimd,
                  tabledata "Check Ledger Entry" = rim,
                  tabledata Currency = r,
                  tabledata "Currency Exchange Rate" = r,
                  tabledata "Customer Bank Account" = R,
                  tabledata "Detailed Vendor Ledg. Entry" = ri,
                  tabledata "Dimension Combination" = R,
                  tabledata "Dimension Value Combination" = R,
                  tabledata "Employee Ledger Entry" = rim,
                  tabledata "Employee Posting Group" = r,
                  tabledata "G/L Account" = r,
                  tabledata "G/L Entry - VAT Entry Link" = Ri,
                  tabledata "G/L Entry" = Ri,
                  tabledata "G/L Register" = Rim,
                  tabledata "Gen. Journal Template" = R,
                  tabledata "General Ledger Setup" = rm,
                  tabledata "General Posting Setup" = R,
                  tabledata "IC Bank Account" = R,
                  tabledata "IC Comment Line" = RIMD,
                  tabledata "IC Dimension" = R,
                  tabledata "IC Dimension Value" = R,
                  tabledata "IC Document Dimension" = RIMD,
                  tabledata "IC G/L Account" = R,
                  tabledata "IC Inbox/Outbox Jnl. Line Dim." = RIMD,
                  tabledata "IC Outbox Jnl. Line" = RIMD,
                  tabledata "IC Outbox Purchase Header" = RIMD,
                  tabledata "IC Outbox Purchase Line" = RIMD,
                  tabledata "IC Outbox Transaction" = RIMD,
                  tabledata "IC Partner" = R,
                  tabledata "IC Setup" = R,
                  tabledata "Inventory Posting Group" = r,
                  tabledata "Inventory Posting Setup" = r,
                  tabledata Item = Rm,
                  tabledata "Item Analysis View" = RM,
                  tabledata "Item Analysis View Entry" = RIM,
                  tabledata "Item Application Entry" = Ri,
                  tabledata "Item Application Entry History" = R,
                  tabledata "Item Charge Assignment (Purch)" = Rd,
                  tabledata "Item Charge Assignment (Sales)" = Rm,
                  tabledata "Item Ledger Entry" = Rim,
                  tabledata "Item Register" = Rim,
                  tabledata "Item Tracking Code" = R,
                  tabledata "Item Tracking Comment" = RIMD,
                  tabledata "Item Variant" = R,
                  tabledata Job = R,
                  tabledata "Job Ledger Entry" = Rim,
                  tabledata "Job Register" = Rim,
                  tabledata "Lot No. Information" = R,
                  tabledata "My Vendor" = Rimd,
                  tabledata "Package No. Information" = R,
                  tabledata "Planning Component" = Rm,
                  tabledata "Post Value Entry to G/L" = I,
                  tabledata "Posted Whse. Receipt Header" = R,
                  tabledata "Posted Whse. Receipt Line" = R,
                  tabledata "Purch. Comment Line" = RD,
                  tabledata "Purch. Cr. Memo Hdr." = Rim,
                  tabledata "Purch. Cr. Memo Line" = Ri,
                  tabledata "Purch. Inv. Header" = Rim,
                  tabledata "Purch. Inv. Line" = Ri,
                  tabledata "Purch. Rcpt. Header" = Rim,
                  tabledata "Purch. Rcpt. Line" = Rim,
                  tabledata "Purchase Header" = Rmd,
                  tabledata "Purchase Line" = Rd,
                  tabledata "Report Selections" = R,
                  tabledata "Return Shipment Header" = Rim,
                  tabledata "Return Shipment Line" = Rim,
                  tabledata "Sales Header" = Rm,
                  tabledata "Sales Line" = Rm,
                  tabledata "Sales Shipment Header" = i,
                  tabledata "Sales Shipment Line" = i,
                  tabledata "Serial No. Information" = R,
                  tabledata "Source Code Setup" = R,
                  tabledata "Tax Area" = R,
                  tabledata "Tax Area Line" = R,
                  tabledata "Tax Detail" = R,
                  tabledata "Tax Group" = R,
                  tabledata "Tax Jurisdiction" = R,
                  tabledata "User Setup" = r,
                  tabledata "Value Entry" = Rim,
                  tabledata "VAT Amount Line" = RIMD,
                  tabledata "VAT Assisted Setup Bus. Grp." = R,
                  tabledata "VAT Assisted Setup Templates" = R,
                  tabledata "VAT Entry" = Ri,
                  tabledata "VAT Posting Setup" = R,
                  tabledata "VAT Rate Change Log Entry" = Ri,
                  tabledata "VAT Rate Change Setup" = R,
                  tabledata "VAT Reporting Code" = R,
                  tabledata "VAT Setup Posting Groups" = R,
                  tabledata "VAT Setup" = R,
                  tabledata "VAT Posting Parameters" = R,
                  tabledata Vendor = r,
                  tabledata "Vendor Bank Account" = R,
                  tabledata "Vendor Ledger Entry" = rim,
                  tabledata "Vendor Posting Group" = r,
                  tabledata "Warehouse Request" = RIMD,
                  tabledata "Whse. Put-away Request" = RIMD;
}
