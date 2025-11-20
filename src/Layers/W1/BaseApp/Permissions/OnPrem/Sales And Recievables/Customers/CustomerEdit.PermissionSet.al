namespace System.Security.AccessControl;

using Microsoft.Sales.Customer;
using Microsoft.Bank.Ledger;
using Microsoft.Warehouse.Structure;
using Microsoft.Bank.Check;
using Microsoft.Foundation.Comment;
using System.IO;
using Microsoft.CRM.Duplicates;
using Microsoft.CRM.Contact;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Profiling;
using Microsoft.Foundation.Address;
using Microsoft.Finance.Currency;
using Microsoft.Sales.Receivables;
using Microsoft.Finance.Dimension;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.HumanResources.Payables;
using Microsoft.FixedAssets.Ledger;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.Partner;
using Microsoft.CRM.Interaction;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Sales.Reminder;
using Microsoft.Inventory.Location;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.CRM.Opportunity;
using Microsoft.Bank.BankAccount;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Source;
using Microsoft.Pricing.Worksheet;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Archive;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Sales.History;
using Microsoft.Sales.Document;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Pricing;
using Microsoft.Finance.SalesTax;
using Microsoft.CRM.Task;
using Microsoft.Purchases.Payables;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Worksheet;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Projects.Project.Job;
using Microsoft.CRM.Team;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Intrastat;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.Registration;
using Microsoft.API;

permissionset 9221 "Customer - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Edit customers';

    Permissions = tabledata "Additional Fee Setup" = R,
                  tabledata "Alt. Customer Posting Group" = R,
                  tabledata "API Entities Setup" = RIMD,
                  tabledata "Bank Account Ledger Entry" = rm,
                  tabledata Bin = R,
                  tabledata "Check Ledger Entry" = r,
                  tabledata "Comment Line" = RIMD,
                  tabledata "Config. Template Header" = R,
                  tabledata "Config. Template Line" = R,
                  tabledata "Config. Tmpl. Selection Rules" = RIMD,
                  tabledata "Cont. Duplicate Search String" = RIMD,
                  tabledata Contact = RIM,
                  tabledata "Contact Business Relation" = ImD,
                  tabledata "Contact Duplicate" = R,
                  tabledata "Contact Profile Answer" = R,
                  tabledata "Country/Region" = R,
                  tabledata Currency = R,
                  tabledata "Currency Exchange Rate" = R,
                  tabledata "Cust. Invoice Disc." = R,
                  tabledata "Cust. Ledger Entry" = Rm,
                  tabledata Customer = RIMD,
                  tabledata "Customer Bank Account" = RIMD,
                  tabledata "Customer Discount Group" = RIMD,
                  tabledata "Customer Posting Group" = R,
                  tabledata "Customer Price Group" = R,
                  tabledata "Customer Templ." = rm,
                  tabledata "Default Dimension" = RIMD,
                  tabledata "Detailed Cust. Ledg. Entry" = Rim,
                  tabledata "Dispute Status" = RIMD,
                  tabledata "Dtld. Price Calculation Setup" = Rid,
                  tabledata "Duplicate Price Line" = Rid,
                  tabledata "Duplicate Search String Setup" = R,
                  tabledata "Employee Ledger Entry" = r,
                  tabledata "FA Ledger Entry" = rm,
                  tabledata "Finance Charge Terms" = R,
                  tabledata "Finance Charge Text" = R,
                  tabledata "G/L Entry - VAT Entry Link" = rm,
                  tabledata "G/L Entry" = rm,
                  tabledata "Gen. Business Posting Group" = R,
                  tabledata "Gen. Journal Batch" = r,
                  tabledata "Gen. Journal Line" = r,
                  tabledata "Gen. Journal Template" = r,
                  tabledata "IC Bank Account" = Rm,
                  tabledata "IC Partner" = Rm,
                  tabledata "Interaction Log Entry" = R,
                  tabledata "Item Analysis View Budg. Entry" = r,
                  tabledata "Item Analysis View Entry" = rid,
                  tabledata "Item Budget Entry" = r,
                  tabledata "Item Journal Line" = r,
                  tabledata "Item Ledger Entry" = rm,
                  tabledata "Item Reference" = RIMD,
                  tabledata Job = rm,
                  tabledata "Line Fee Note on Report Hist." = R,
                  tabledata Location = R,
                  tabledata "Maintenance Ledger Entry" = rm,
                  tabledata "My Customer" = RIMD,
                  tabledata Opportunity = R,
                  tabledata "Payment Method" = R,
                  tabledata "Payment Terms" = R,
                  tabledata "Price Asset" = Rid,
                  tabledata "Price Calculation Buffer" = Rid,
                  tabledata "Price Calculation Setup" = Rid,
                  tabledata "Price Line Filters" = Rid,
                  tabledata "Price List Header" = Rid,
                  tabledata "Price List Line" = Rid,
                  tabledata "Price Source" = Rid,
                  tabledata "Price Worksheet Line" = Rid,
                  tabledata "Profile Questionnaire Line" = R,
                  tabledata "Purch. Cr. Memo Hdr." = rm,
                  tabledata "Purch. Cr. Memo Line" = rm,
                  tabledata "Purch. Inv. Header" = rm,
                  tabledata "Purch. Rcpt. Header" = rm,
                  tabledata "Purchase Header" = rm,
                  tabledata "Purchase Header Archive" = r,
                  tabledata "Registered Whse. Activity Line" = rm,
                  tabledata "Reminder Attachment Text" = R,
                  tabledata "Reminder Attachment Text Line" = R,
                  tabledata "Reminder Email Text" = R,
                  tabledata "Reminder Level" = R,
                  tabledata "Reminder Terms" = R,
                  tabledata "Reminder Terms Translation" = R,
                  tabledata "Reminder Text" = R,
                  tabledata "Reminder/Fin. Charge Entry" = R,
                  tabledata "Reminder Action Group" = R,
                  tabledata "Reminder Action" = R,
                  tabledata "Create Reminders Setup" = R,
                  tabledata "Issue Reminders Setup" = R,
                  tabledata "Send Reminders Setup" = R,
                  tabledata "Reminder Automation Error" = R,
                  tabledata "Reminder Action Group Log" = R,
                  tabledata "Reminder Action Log" = R,
                  tabledata "Res. Journal Line" = r,
                  tabledata "Res. Ledger Entry" = rm,
                  tabledata "Responsibility Center" = R,
                  tabledata "Return Receipt Header" = rm,
                  tabledata "Return Receipt Line" = rm,
                  tabledata "Return Shipment Header" = rm,
                  tabledata "Return Shipment Line" = rm,
                  tabledata "Sales Cr.Memo Header" = rm,
                  tabledata "Sales Cr.Memo Line" = rm,
                  tabledata "Sales Discount Access" = Rd,
                  tabledata "Sales Header" = rm,
                  tabledata "Sales Header Archive" = rm,
                  tabledata "Sales Invoice Header" = rm,
                  tabledata "Sales Invoice Line" = rm,
                  tabledata "Sales Line" = Rm,
                  tabledata "Sales Line Discount" = Rd,
                  tabledata "Sales Price" = Rid,
                  tabledata "Sales Price Access" = Rid,
                  tabledata "Sales Shipment Header" = rm,
                  tabledata "Sales Shipment Line" = rm,
                  tabledata "Salesperson/Purchaser" = R,
                  tabledata "Ship-to Address" = RIMD,
                  tabledata "Shipment Method" = R,
                  tabledata "Shipping Agent" = R,
                  tabledata "Shipping Agent Services" = R,
                  tabledata "Sorting Table" = R,
                  tabledata "Standard Customer Sales Code" = RiD,
                  tabledata "Standard General Journal" = rm,
                  tabledata "Standard General Journal Line" = rm,
                  tabledata "Tax Area" = R,
                  tabledata Territory = R,
                  tabledata "To-do" = R,
                  tabledata "Value Entry" = rm,
                  tabledata "VAT Business Posting Group" = R,
                  tabledata "VAT Entry" = rm,
                  tabledata "VAT Reg. No. Srv Config" = rd,
                  tabledata "VAT Reg. No. Srv. Template" = RIMD,
                  tabledata "VAT Registration Log" = rd,
                  tabledata "VAT Registration Log Details" = RIMD,
                  tabledata "VAT Registration No. Format" = R,
                  tabledata "Alt. Cust. VAT Reg." = R,
                  tabledata "Vendor Ledger Entry" = r,
                  tabledata "Warehouse Activity Header" = rm,
                  tabledata "Warehouse Activity Line" = rm,
                  tabledata "Warehouse Reason Code" = rm,
                  tabledata "Warehouse Request" = rm,
                  tabledata "Warehouse Shipment Line" = rm,
                  tabledata "Whse. Worksheet Line" = r;
}
