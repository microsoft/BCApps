// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Security.AccessControl;

using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.CRM.Team;
using Microsoft.Projects.Project.Job;
using Microsoft.Inventory.Location;
using Microsoft.Foundation.Reporting;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.Analysis;
using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.CRM.Campaign;
using Microsoft.Bank.Check;
using Microsoft.Foundation.Comment;
using Microsoft.CRM.Contact;
using Microsoft.Foundation.Address;
using Microsoft.Finance.Currency;
using Microsoft.Sales.Receivables;
using Microsoft.Finance.Dimension;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Intercompany.BankAccount;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Intercompany.Partner;
using Microsoft.Intercompany.Setup;
using Microsoft.CRM.Interaction;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Ledger;
using Microsoft.Purchases.Document;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Tracking;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Inventory.Costing;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Source;
using Microsoft.Pricing.Worksheet;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Service.Maintenance;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Service.Resources;
using Microsoft.Sales.History;
using Microsoft.Sales.Pricing;
using Microsoft.CRM.Segment;
using Microsoft.Service.Comment;
using Microsoft.Service.Contract;
using Microsoft.Service.Pricing;
using Microsoft.Service.History;
using Microsoft.Service.Document;
using Microsoft.Service.Item;
using Microsoft.Service.Ledger;
using Microsoft.Service.Setup;
using Microsoft.Service.Posting;
using Microsoft.Finance.SalesTax;
using Microsoft.Inventory.Transfer;
using System.Security.User;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Worksheet;
using Microsoft.Foundation.Period;
using Microsoft.Foundation.BatchProcessing;

permissionset 8322 "Service Documents - Post"
{
    Access = Public;
    Assignable = false;
    Caption = 'Post service orders etc.';

    Permissions = tabledata "Accounting Period" = r,
                  tabledata "Alt. Customer Posting Group" = R,
                  tabledata "Analysis View" = rimd,
                  tabledata "Analysis View Entry" = rim,
                  tabledata "Analysis View Filter" = r,
                  tabledata "Avg. Cost Adjmt. Entry Point" = Ri,
                  tabledata "Bank Account" = m,
                  tabledata "Bank Account Ledger Entry" = rim,
                  tabledata "Batch Processing Parameter" = Rimd,
                  tabledata "Batch Processing Session Map" = Rimd,
                  tabledata Campaign = R,
                  tabledata "Check Ledger Entry" = rim,
                  tabledata "Comment Line" = r,
                  tabledata Contact = R,
                  tabledata "Contact Alt. Addr. Date Range" = R,
                  tabledata "Country/Region" = R,
                  tabledata Currency = R,
                  tabledata "Currency Exchange Rate" = R,
                  tabledata "Cust. Ledger Entry" = Rim,
                  tabledata Customer = R,
                  tabledata "Customer Bank Account" = R,
                  tabledata "Customer Posting Group" = R,
                  tabledata "Default Dimension" = R,
                  tabledata "Detailed Cust. Ledg. Entry" = Ri,
                  tabledata "Dimension Combination" = R,
                  tabledata "Dimension Value Combination" = R,
                  tabledata "Dtld. Price Calculation Setup" = R,
                  tabledata "Duplicate Price Line" = R,
                  tabledata "G/L Account" = R,
                  tabledata "G/L Entry - VAT Entry Link" = Ri,
                  tabledata "G/L Entry" = Ri,
                  tabledata "G/L Register" = Rim,
                  tabledata "Gen. Jnl. Allocation" = r,
                  tabledata "Gen. Journal Template" = R,
                  tabledata "General Ledger Setup" = rm,
                  tabledata "General Posting Setup" = R,
                  tabledata "IC Bank Account" = R,
                  tabledata "IC G/L Account" = R,
                  tabledata "IC Partner" = R,
                  tabledata "IC Setup" = R,
                  tabledata "Interaction Log Entry" = RIMD,
                  tabledata "Interaction Template" = R,
                  tabledata "Interaction Tmpl. Language" = R,
                  tabledata "Inventory Posting Group" = r,
                  tabledata "Inventory Posting Setup" = R,
                  tabledata "Invoice Posting Buffer" = RIMD,
                  tabledata Item = Rm,
                  tabledata "Item Analysis View" = rIM,
                  tabledata "Item Analysis View Entry" = rim,
                  tabledata "Item Application Entry" = RI,
                  tabledata "Item Application Entry History" = R,
                  tabledata "Item Charge Assignment (Purch)" = Rm,
                  tabledata "Item Charge Assignment (Sales)" = Rd,
                  tabledata "Item Journal Line" = RIMD,
                  tabledata "Item Ledger Entry" = Rim,
                  tabledata "Item Register" = Rim,
                  tabledata "Item Substitution" = R,
                  tabledata "Item Tracking Code" = R,
                  tabledata "Item Tracking Comment" = RIMD,
                  tabledata "Item Variant" = R,
                  tabledata Job = R,
                  tabledata "Job Ledger Entry" = Rim,
                  tabledata "Job Register" = Rim,
                  tabledata Location = R,
                  tabledata "Lot No. Information" = R,
                  tabledata "Package No. Information" = R,
                  tabledata "Payment Terms" = R,
                  tabledata "Post Value Entry to G/L" = I,
                  tabledata "Price Asset" = R,
                  tabledata "Price Calculation Buffer" = R,
                  tabledata "Price Calculation Setup" = R,
                  tabledata "Price Line Filters" = R,
                  tabledata "Price List Header" = R,
                  tabledata "Price List Line" = R,
                  tabledata "Price Source" = R,
                  tabledata "Price Worksheet Line" = R,
                  tabledata "Purchase Line" = R,
                  tabledata "Registered Whse. Activity Line" = R,
                  tabledata "Repair Status" = R,
                  tabledata "Report Selections" = R,
                  tabledata "Res. Ledger Entry" = Ri,
                  tabledata "Reservation Entry" = R,
                  tabledata Resource = R,
                  tabledata "Resource Register" = Rim,
                  tabledata "Resource Skill" = R,
                  tabledata "Resource Unit of Measure" = R,
                  tabledata "Responsibility Center" = R,
                  tabledata "Return Receipt Header" = R,
                  tabledata "Sales Discount Access" = R,
                  tabledata "Sales Header" = RIM,
                  tabledata "Sales Line" = RIM,
                  tabledata "Sales Line Discount" = R,
                  tabledata "Sales Price" = R,
                  tabledata "Sales Price Access" = R,
                  tabledata "Salesperson/Purchaser" = R,
                  tabledata "Segment Header" = R,
                  tabledata "Serial No. Information" = R,
                  tabledata "Service Comment Line" = Rd,
                  tabledata "Service Contract Header" = R,
                  tabledata "Service Contract Line" = R,
                  tabledata "Service Cost" = R,
                  tabledata "Service Cr.Memo Header" = RIMD,
                  tabledata "Service Cr.Memo Line" = RIMD,
                  tabledata "Service Document Log" = RIM,
                  tabledata "Service Document Register" = RIMD,
                  tabledata "Service Header" = RIMD,
                  tabledata "Service Hour" = R,
                  tabledata "Service Invoice Header" = RIMD,
                  tabledata "Service Invoice Line" = RIMD,
                  tabledata "Service Item" = RIM,
                  tabledata "Service Item Component" = RID,
                  tabledata "Service Item Line" = RIMD,
                  tabledata "Service Item Log" = RI,
                  tabledata "Service Ledger Entry" = RIM,
                  tabledata "Service Line" = RIMD,
                  tabledata "Service Mgt. Setup" = R,
                  tabledata "Service Order Allocation" = RIMD,
                  tabledata "Service Order Posting Buffer" = RIMD,
                  tabledata "Service Register" = RIMD,
                  tabledata "Service Shipment Header" = RIMD,
                  tabledata "Service Shipment Item Line" = RIMD,
                  tabledata "Service Shipment Line" = RIMD,
                  tabledata "Ship-to Address" = r,
                  tabledata "Source Code Setup" = R,
                  tabledata "Stockkeeping Unit" = R,
                  tabledata "Tax Area" = R,
                  tabledata "Tax Area Line" = R,
                  tabledata "Tax Detail" = R,
                  tabledata "Tax Group" = R,
                  tabledata "Tax Jurisdiction" = R,
                  tabledata "Transfer Line" = R,
                  tabledata "Troubleshooting Setup" = R,
                  tabledata "User Setup" = r,
                  tabledata "Value Entry" = Rim,
                  tabledata "Value Entry Relation" = I,
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
                  tabledata "Warehouse Activity Line" = R,
                  tabledata "Warehouse Entry" = R,
                  tabledata "Warehouse Reason Code" = R,
                  tabledata "Warehouse Receipt Line" = R,
                  tabledata "Warehouse Shipment Line" = R,
                  tabledata "Warranty Ledger Entry" = RIM,
                  tabledata "Whse. Worksheet Line" = R;
}
