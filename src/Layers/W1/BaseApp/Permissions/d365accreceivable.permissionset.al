namespace System.Security.AccessControl;

using Microsoft.Bank.Reconciliation;
using Microsoft.Bank.Statement;
using Microsoft.Finance.Currency;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.Reminder;
using Microsoft.Sales.Customer;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Tracking;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Sales.Document;
using Microsoft.EServices.EDocument;
using Microsoft.Foundation.Period;
using Microsoft.Bank.Payment;
using System.Threading;
using System.Environment.Configuration;
using Microsoft.CRM.Opportunity;
using Microsoft.Purchases.Vendor;
using Microsoft.Inventory.Availability;
using Microsoft.Bank.BankAccount;
using Microsoft.Warehouse.History;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Pricing.Worksheet;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Remittance;

permissionset 7862 "D365 ACC. RECEIVABLE"
{
    Access = Public;
    Assignable = true;
    Caption = 'Dyn. 365 Accounts receivable';

    IncludedPermissionSets = "D365 JOURNALS, POST",
                             "D365 SALES DOC, POST";

    Permissions = tabledata "Applied Payment Entry" = RIMD,
                  tabledata "Bank Acc. Reconciliation" = RIMD,
                  tabledata "Bank Acc. Reconciliation Line" = RIMD,
                  tabledata "Bank Acc. Rec. Match Buffer" = RIMD,
                  tabledata "Bank Account Statement" = RimD,
                  tabledata "Bank Account Statement Line" = Rimd,
                  tabledata "Bank Pmt. Appl. Rule" = RIMD,
                  tabledata "Bank Pmt. Appl. Settings" = RIMD,
                  tabledata "Credit Transfer Entry" = Rimd,
                  tabledata "Currency Exchange Rate" = D,
                  tabledata "Currency for Fin. Charge Terms" = R,
                  tabledata "Currency for Reminder Level" = R,
                  tabledata Customer = D,
                  tabledata "Date Compr. Register" = Rimd,
                  tabledata "Exch. Rate Adjmt. Reg." = Rimd,
                  tabledata "Exch. Rate Adjmt. Ledg. Entry" = Rimd,
                  tabledata "Fin. Charge Comment Line" = RIMD,
                  tabledata "Finance Charge Interest Rate" = RIMD,
                  tabledata "Finance Charge Memo Header" = RIMD,
                  tabledata "Finance Charge Memo Line" = RIMD,
                  tabledata "Finance Charge Text" = RIMD,
                  tabledata "Incoming Document" = Rimd,
                  tabledata "Issued Fin. Charge Memo Header" = Rimd,
                  tabledata "Issued Fin. Charge Memo Line" = Rimd,
                  tabledata "Issued Reminder Header" = Rimd,
                  tabledata "Issued Reminder Line" = Rimd,
                  tabledata "Item Charge" = R,
                  tabledata "Item Charge Assignment (Purch)" = RIMD,
                  tabledata "Item Charge Assignment (Sales)" = RIMD,
                  tabledata "Item Entry Relation" = R,
                  tabledata "Item Journal Line" = RIMD,
                  tabledata "Item Ledger Entry" = Rimd,
                  tabledata "Item Reference" = RIMD,
                  tabledata "Item Register" = Rimd,
                  tabledata "Item Tracing Buffer" = Rimd,
                  tabledata "Item Tracing History Buffer" = Rimd,
                  tabledata "Item Tracking Code" = R,
                  tabledata "Job Ledger Entry" = Rimd,
                  tabledata "Job Queue Category" = RIMD,
                  tabledata "Line Fee Note on Report Hist." = Rim,
                  tabledata "Lot No. Information" = RIMD,
                  tabledata "Notification Entry" = RIMD,
                  tabledata Opportunity = R,
                  tabledata "Opportunity Entry" = RIM,
                  tabledata "Order Address" = RIMD,
                  tabledata "Order Promising Line" = RiMD,
                  tabledata "Package No. Information" = RIMD,
                  tabledata "Payment Matching Details" = RIMD,
                  tabledata "Payment Method" = RIMD,
                  tabledata "Payment Rec. Related Entry" = RIMD,
                  tabledata "Pmt. Rec. Applied-to Entry" = RIMD,
                  tabledata "Posted Payment Recon. Hdr" = RIMD,
                  tabledata "Posted Payment Recon. Line" = RIMD,
                  tabledata "Posted Whse. Shipment Header" = R,
                  tabledata "Posted Whse. Shipment Line" = R,
                  tabledata "Price Asset" = RIMD,
                  tabledata "Price Calculation Buffer" = RIMD,
                  tabledata "Price Calculation Setup" = RIMD,
                  tabledata "Price Line Filters" = RIMD,
                  tabledata "Price List Header" = RIMD,
                  tabledata "Price List Line" = RIMD,
                  tabledata "Price Source" = RIMD,
                  tabledata "Price Worksheet Line" = RIMD,
                  tabledata "Purch. Rcpt. Header" = i,
                  tabledata "Purch. Rcpt. Line" = Ri,
                  tabledata "Purchase Header" = Rimd,
                  tabledata "Purchase Line" = RIMD,
                  tabledata "Reminder Comment Line" = RIMD,
                  tabledata "Reminder Header" = RIMD,
                  tabledata "Reminder Level" = R,
                  tabledata "Reminder Line" = RIMD,
                  tabledata "Reminder Text" = R,
                  tabledata "Reminder/Fin. Charge Entry" = Rimd,
                  tabledata "Remit Address" = RIMD,
                  tabledata "VAT Registration No. Format" = IMD;
}
