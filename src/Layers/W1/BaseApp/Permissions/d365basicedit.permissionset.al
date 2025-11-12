namespace System.Security.AccessControl;

using Microsoft.AccountantPortal;
using Microsoft.Booking;
using Microsoft.Sales.Archive;
using Microsoft.Projects.TimeSheet;
using Microsoft.Bank.Payment;
using Microsoft.Foundation.Reporting;
using Microsoft.EServices.EDocument;
using Microsoft.Foundation.Attachment;
using Microsoft.Foundation.Navigate;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.eServices.OnlineMap;
using Microsoft.Finance.Payroll;
using System.Security.Authentication;
using System.Globalization;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.UOM;
using Microsoft.Foundation.Task;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.Registration;
using System.Reflection;
using Microsoft.Sales.Customer;
using Microsoft.Purchases.Vendor;
using System.Tooling;
using System.Privacy;
using System.Utilities;
using Microsoft.Inventory.Transfer;
using System.Integration;
using System.IO;
using System.Environment;
using System.Environment.Configuration;
using System.Upgrade;
using System.DateTime;
using Microsoft.Finance.FinancialReports;
using Microsoft.Integration.Entity;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.AllocationAccount;
using Microsoft.Inventory.Analysis;
using Microsoft.Foundation.Address;
using Microsoft.Inventory.Availability;
using System.Azure.Identity;
using System.AI;
using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Setup;
using Microsoft.Bank.Reconciliation;
using System.Visualization;
using Microsoft.Warehouse.Structure;
using Microsoft.Inventory.BOM;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.CashFlow.Forecast;
using Microsoft.CashFlow.Setup;
using Microsoft.Finance.Dimension;
using System.Diagnostics;
using Microsoft.Foundation.Comment;
using Microsoft.CRM.Contact;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Costing;
using Microsoft.Integration.PowerBI;
using Microsoft.Finance.Currency;
using Microsoft.Sales.Analysis;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.Deferral;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using System.Email;
using Microsoft.Inventory.Tracking;
using Microsoft.CRM.Outlook;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Finance.RoleCenters;
using System.Automation;
using Microsoft.Inventory.Ledger;
using Microsoft.Finance.Analysis;
using Microsoft.Integration.Graph;
using Microsoft.CRM.Interaction;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Item.Picture;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Item.Catalog;
using System.Threading;
using Microsoft.Purchases.Document;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Bank.PositivePay;
using System.Integration.PowerBI;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Source;
using Microsoft.Pricing.Worksheet;
using System.Device;
using Microsoft.Purchases.Analysis;
using Microsoft.Purchases.Comment;
using Microsoft.Purchases.Archive;
using Microsoft.Purchases.Pricing;
using Microsoft.Purchases.RoleCenters;
using Microsoft.Purchases.Setup;
using Microsoft.Finance.GeneralLedger.Reports;
using System.Xml;
using Microsoft.CRM.RoleCenters;
using Microsoft.Sales.Reminder;
using Microsoft.Purchases.Remittance;
using Microsoft.Warehouse.Setup;
using Microsoft.Inventory.Requisition;
using Microsoft.Projects.Resources.Analysis;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Finance.GeneralLedger.Reversal;
using Microsoft.Sales.Setup;
using Microsoft.Sales.Comment;
using Microsoft.Sales.RoleCenters;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Pricing;
using Microsoft.Bank.DirectDebit;
using System.Text;
using Microsoft.Finance.SalesTax;
using System.Security.User;
using Microsoft.RoleCenters;
using Microsoft.Utilities;
using Microsoft.Inventory.Intrastat;
using Microsoft.Foundation.Calendar;
using Microsoft.API.Upgrade;
using Microsoft.API;
using Microsoft.Intercompany.DataExchange;
using Microsoft;
using System.TestTools;

permissionset 208 "D365 Basic - Edit"
{
    Access = Public;
    Caption = 'Dynamics 365 Basic - Edit access';

    IncludedPermissionSets = "D365 Basic - Read";

    Permissions = tabledata "Add-in" = imd,
                  tabledata "Aggregate Permission Set" = imd,
                  tabledata "All Profile Page Metadata" = imd,
                  tabledata AllObj = imd,
                  tabledata AllObjWithCaption = imd,
                  tabledata "Buffer IC Comment Line" = IMD,
                  tabledata "Buffer IC Document Dimension" = IMD,
                  tabledata "Buffer IC Inbox Jnl. Line" = IMD,
                  tabledata "Buffer IC Inbox Purchase Line" = IMD,
                  tabledata "Buffer IC Inbox Purch Header" = IMD,
                  tabledata "Buffer IC Inbox Sales Header" = IMD,
                  tabledata "Buffer IC Inbox Sales Line" = IMD,
                  tabledata "Buffer IC Inbox Transaction" = IMD,
                  tabledata "Buffer IC InOut Jnl. Line Dim." = IMD,
                  tabledata "IC Incoming Notification" = IMD,
                  tabledata "IC Outgoing Notification" = IMD,
                  tabledata Chart = imd,
                  tabledata "Code Coverage" = imd,
                  tabledata "CodeUnit Metadata" = imd,
                  tabledata Date = imd,
                  tabledata Device = imd,
                  tabledata "Direct Trans. Header" = IMD,
                  tabledata "Direct Trans. Line" = IMD,
                  tabledata "Document Service" = imd,
                  tabledata Drive = imd,
                  tabledata Entitlement = imd,
                  tabledata "Entitlement Set" = imd,
                  tabledata "Event Subscription" = imd,
                  tabledata Field = imd,
                  tabledata File = imd,
                  tabledata Integer = imd,
                  tabledata "Intelligent Cloud" = imd,
                  tabledata "Intelligent Cloud Status" = imd,
                  tabledata Key = imd,
                  tabledata "License Information" = imd,
                  tabledata "License Permission" = imd,
                  tabledata Media = imd,
                  tabledata "Media Set" = imd,
                  tabledata "Membership Entitlement" = imd,
                  tabledata "NAV App Setting" = IMD,
                  tabledata "Object Metadata" = imd,
                  tabledata "Page Metadata" = imd,
                  tabledata "Permission Range" = imd,
                  tabledata "Query Navigation" = IMD,
                  tabledata "Report Layout" = imd,
                  tabledata "Report Metadata" = imd,
                  tabledata "Scheduled Task" = imd,
                  tabledata "Server Instance" = imd,
                  tabledata "SID - Account ID" = imd,
                  tabledata "System Object" = imd,
                  tabledata "Table Information" = imd,
                  tabledata "Table Metadata" = imd,
                  tabledata "Table Synch. Setup" = imd,
                  tabledata "Tenant Profile Page Metadata" = imd,
                  tabledata "Tenant Web Service" = IMD,
                  tabledata "Time Zone" = imd,
                  tabledata "Upgrade Blob Storage" = imd,
                  tabledata User = M,
                  tabledata "User Property" = imd,
                  tabledata "Windows Language" = imd,
                  tabledata "Acc. Sched. Cell Value" = imd,
                  tabledata "Acc. Sched. Chart Setup Line" = IMD,
                  tabledata "Acc. Sched. KPI Buffer" = IMD,
                  tabledata "Financial Report User Filters" = IMD,
                  tabledata "Account Schedules Chart Setup" = IMD,
                  tabledata "Account Use Buffer" = IMD,
                  tabledata "Accounting Services Cue" = IMD,
                  tabledata "Activities Cue" = IMD,
                  tabledata "Activity Log" = IMD,
                  tabledata "Additional Fee Setup" = IMD,
                  tabledata "Adjust Exchange Rate Buffer" = IMD,
                  tabledata "Administration Cue" = IMD,
                  tabledata "Aged Report Entity" = IMD,
                  tabledata "Aging Band Buffer" = imd,
                  tabledata "Alloc. Acc. Manual Override" = IMD,
                  tabledata "Allocation Line" = IMD,
                  tabledata "Analysis by Dim. Parameters" = IMD,
                  tabledata "Analysis by Dim. User Param." = IMD,
                  tabledata "Analysis Dim. Selection Buffer" = IMD,
                  tabledata "Analysis Report Chart Line" = IMD,
                  tabledata "Analysis Report Chart Setup" = IMD,
                  tabledata "Analysis Selected Dimension" = IMD,
                  tabledata "API Data Upgrade" = IMD,
                  tabledata "API Entities Setup" = IMD,
                  tabledata "Application Area Buffer" = IMD,
                  tabledata "Application Area Setup" = IMD,
                  tabledata "Approval Comment Line" = IMD,
                  tabledata "Approval Entry" = imd,
                  tabledata "Approvals Activities Cue" = IMD,
                  tabledata "Attachment Entity Buffer" = IMD,
                  tabledata "Autocomplete Address" = IMD,
                  tabledata "Availability at Date" = imd,
                  tabledata "Azure AD Mgt. Setup" = im,
                  tabledata "Azure AI Usage" = imd,
                  tabledata "Balance Sheet Buffer" = IMD,
                  tabledata "Bank Account Balance Buffer" = IMD,
                  tabledata "Bank Export/Import Setup" = imd,
                  tabledata "Bank Statement Matching Buffer" = IMD,
                  tabledata "Bar Chart Buffer" = IMD,
                  tabledata "Base Calendar Change" = imd,
                  tabledata "Bin Content" = imd,
                  tabledata "BOM Buffer" = IMD,
                  tabledata "BOM Warning Log" = IMD,
                  tabledata "Booking Item" = IMD,
                  tabledata "Booking Mailbox" = IMD,
                  tabledata "Booking Mgr. Setup" = IMD,
                  tabledata "Booking Service" = IMD,
                  tabledata "Booking Service Mapping" = IMD,
                  tabledata "Booking Staff" = IMD,
                  tabledata "Booking Sync" = IMD,
                  tabledata "Budget Buffer" = IMD,
                  tabledata "Business Chart Buffer" = IMD,
                  tabledata "Business Chart Map" = IMD,
                  tabledata "Business Chart User Setup" = IMD,
                  tabledata "Cash Flow Availability Buffer" = IMD,
                  tabledata "Cash Flow Azure AI Buffer" = imd,
                  tabledata "Cash Flow Setup" = i,
                  tabledata "Change Log Entry" = i,
                  tabledata "Chart Definition" = IMD,
                  tabledata "Close Income Statement Buffer" = imd,
                  tabledata "Column Layout" = IMD,
                  tabledata "Column Layout Name" = IMD,
                  tabledata "Comment Line" = IMD,
                  tabledata "Config. Media Buffer" = IMD,
                  tabledata Contact = im,
                  tabledata "Contact Alt. Addr. Date Range" = IMD,
                  tabledata "Contact Alt. Address" = IMD,
                  tabledata "Copy Gen. Journal Parameters" = IMD,
                  tabledata "Copy Item Buffer" = IMD,
                  tabledata "Copy Item Parameters" = IMD,
                  tabledata "Cost Element Buffer" = IMD,
                  tabledata "Country/Region" = IMD,
                  tabledata "Country/Region Translation" = IMD,
                  tabledata "CSV Buffer" = IMD,
                  tabledata Currency = im,
                  tabledata "Currency Amount" = imd,
                  tabledata "Currency Total Buffer" = imd,
                  tabledata "Custom Address Format" = IMD,
                  tabledata "Custom Address Format Line" = IMD,
                  tabledata "Custom Report Layout" = IMD,
                  tabledata "Custom Report Selection" = IMD,
                  tabledata Customer = im,
                  tabledata "Customer Amount" = IMD,
                  tabledata "Customer Sales Buffer" = IMD,
                  tabledata "Customized Calendar Change" = imd,
                  tabledata "CV Ledger Entry Buffer" = IMD,
                  tabledata "Data Exch." = imd,
                  tabledata "Data Exch. Column Def" = IMD,
                  tabledata "Data Exch. Def" = IMD,
                  tabledata "Data Exch. Field" = IMD,
                  tabledata "Data Exch. Field Mapping" = IMD,
                  tabledata "Data Exch. Field Mapping Buf." = IMD,
                  tabledata "Data Exch. Line Def" = IMD,
                  tabledata "Data Exch. Mapping" = IMD,
                  tabledata "Data Exch. Field Grouping" = IMD,
                  tabledata "Data Exch. FlowField Gr. Buff." = IMD,
                  tabledata "Data Exch. Table Filter" = imd,
                  tabledata "DataExch-RapidStart Buffer" = IMD,
                  tabledata "Date Lookup Buffer" = IMD,
                  tabledata "Default Dimension" = IMD,
                  tabledata "Default Dimension Priority" = IMD,
                  tabledata "Deferral Header" = IMD,
                  tabledata "Deferral Header Archive" = imd,
                  tabledata "Deferral Line" = IMD,
                  tabledata "Deferral Line Archive" = imd,
                  tabledata "Deferral Posting Buffer" = IMD,
                  tabledata "Deferral Template" = IMD,
                  tabledata "Detailed CV Ledg. Entry Buffer" = IMD,
                  tabledata "Dim. Value per Account" = IMD,
                  tabledata "Dimension Buffer" = IMD,
                  tabledata "Dimension Code Amount Buffer" = IMD,
                  tabledata "Dimension Code Buffer" = IMD,
                  tabledata "Dimension Combination" = IMD,
                  tabledata "Dimension Entry Buffer" = IMD,
                  tabledata "Dimension ID Buffer" = IMD,
                  tabledata "Dimension Selection Buffer" = IMD,
                  tabledata "Dimension Set Entry" = imd,
                  tabledata "Dimension Set Entry Buffer" = IMD,
                  tabledata "Dimension Set ID Filter Line" = IMD,
                  tabledata "Dimension Set Tree Node" = imd,
                  tabledata "Dimension Translation" = IMD,
                  tabledata "Dimension Value Combination" = IMD,
                  tabledata "Dimensions Field Map" = IMD,
                  tabledata "Dimensions Template" = IMD,
                  tabledata "Document Attachment" = IMD,
                  tabledata "Document Entry" = IMD,
                  tabledata "Document Search Result" = IMD,
                  tabledata "Document Sending Profile" = IMD,
                  tabledata "Drop Shpt. Post. Buffer" = IMD,
                  tabledata "Dtld. Price Calculation Setup" = im,
                  tabledata "Duplicate Price Line" = im,
                  tabledata "ECSL VAT Report Line" = IMD,
                  tabledata "ECSL VAT Report Line Relation" = IMD,
                  tabledata "Electronic Document Format" = IMD,
                  tabledata "Email Item" = IMD,
                  tabledata "Email Parameter" = IMD,
                  tabledata "Employee Payment Buffer" = IMD,
                  tabledata "Employee Time Reg Buffer" = IMD,
                  tabledata "Entry No. Amount Buffer" = IMD,
                  tabledata "Entry Summary" = IMD,
                  tabledata "Entry/Exit Point" = IMD,
                  tabledata "Error Buffer" = IMD,
                  tabledata "Error Handling Parameters" = IMD,
                  tabledata "Error Message" = IMD,
                  tabledata "Error Message Register" = IMD,
                  tabledata "Excel Buffer" = IMD,
                  tabledata "Excel Template Storage" = IMD,
                  tabledata "Exchange Contact" = IMD,
                  tabledata "Exchange Object" = IMD,
                  tabledata "Exchange Sync" = IMD,
                  tabledata "Experience Tier Buffer" = IMD,
                  tabledata "Experience Tier Setup" = IMD,
                  tabledata "Extended Text Header" = IMD,
                  tabledata "Extended Text Line" = IMD,
                  tabledata "Field Buffer" = IMD,
                  tabledata "Field Monitoring Setup" = m,
                  tabledata "Filter Item Attributes Buffer" = IMD,
                  tabledata "Finance Cue" = IMD,
                  tabledata "Flow User Environment Buffer" = IMD,
                  tabledata "Flow User Environment Config" = IMD,
                  tabledata "G/L - Item Ledger Relation" = imd,
                  tabledata "G/L Acc. Balance Buffer" = IMD,
                  tabledata "G/L Acc. Balance/Budget Buffer" = IMD,
                  tabledata "G/L Acc. Budget Buffer" = IMD,
                  tabledata "G/L Account Net Change" = IMD,
                  tabledata "G/L Account Where-Used" = IMD,
                  tabledata "Gen. Business Posting Group" = IMD,
                  tabledata "Gen. Jnl. Allocation" = IMD,
                  tabledata "Gen. Journal Batch" = IMD,
                  tabledata "Gen. Journal Line" = im,
                  tabledata "Gen. Journal Template" = im,
                  tabledata "Gen. Product Posting Group" = IMD,
                  tabledata "Generic Chart Captions Buffer" = IMD,
                  tabledata "Generic Chart Filter" = IMD,
                  tabledata "Generic Chart Memo Buffer" = IMD,
                  tabledata "Generic Chart Query Column" = IMD,
                  tabledata "Generic Chart Setup" = IMD,
                  tabledata "Generic Chart Y-Axis" = IMD,
                  tabledata Geolocation = IMD,
                  tabledata "Image Analysis Setup" = IMD,
                  tabledata "Import G/L Transaction" = IMD,
                  tabledata "Incoming Document" = IM,
                  tabledata "Incoming Document Attachment" = IMD,
                  tabledata "Interaction Merge Data" = IMD,
                  tabledata "Interaction Template Setup" = IMD,
                  tabledata "Inventory Adjustment Buffer" = imd,
                  tabledata "Inventory Buffer" = imd,
                  tabledata "Inventory Event Buffer" = IMD,
                  tabledata "Invoice Posting Buffer" = imd,
                  tabledata "Invoiced Booking Item" = IMD,
                  tabledata "Invt. Post to G/L Test Buffer" = IMD,
                  tabledata "Invt. Posting Buffer" = imd,
                  tabledata Item = im,
                  tabledata "Item Amount" = IMD,
                  tabledata "Item Application Entry" = imd,
                  tabledata "Item Application Entry History" = imd,
                  tabledata "Item Attr. Value Translation" = IMD,
                  tabledata "Item Attribute" = IMD,
                  tabledata "Item Attribute Translation" = IMD,
                  tabledata "Item Attribute Value" = IMD,
                  tabledata "Item Attribute Value Mapping" = IMD,
                  tabledata "Item Attribute Value Selection" = IMD,
                  tabledata "Item Availability Buffer" = IMD,
                  tabledata "Item Budget Buffer" = IMD,
                  tabledata "Item Journal Batch" = IMD,
                  tabledata "Item Journal Buffer" = IMD,
                  tabledata "Item Journal Line" = im,
                  tabledata "Item Journal Template" = IMD,
                  tabledata "Item Ledger Entry" = im,
                  tabledata "Item Picture Buffer" = IMD,
                  tabledata "Item Statistics Buffer" = IMD,
                  tabledata "Item Substitution" = IMD,
                  tabledata "Item Templ." = IMD,
                  tabledata "Item Tracking Comment" = IMD,
                  tabledata "Item Translation" = im,
                  tabledata "Item Turnover Buffer" = IMD,
                  tabledata "Item Unit of Measure" = IMD,
                  tabledata "Item Variant" = IMD,
                  tabledata "Item Vendor" = im,
                  tabledata "Job Queue Category" = imd,
                  tabledata "Job Queue Entry" = IMD,
                  tabledata "Job Queue Entry Buffer" = IMD,
                  tabledata "Job Queue Log Entry" = imd,
                  tabledata "Journal User Preferences" = IMD,
                  tabledata "JSON Buffer" = IMD,
                  tabledata "Last Used Chart" = IMD,
                  tabledata "Ledger Entry Matching Buffer" = IMD,
                  tabledata "License Agreement" = IM,
                  tabledata "Line Number Buffer" = IMD,
                  tabledata "Media Repository" = IMD,
                  tabledata "My Account" = IMD,
                  tabledata "My Customer" = IMD,
                  tabledata "My Item" = IMD,
                  tabledata "My Notifications" = IMD,
                  tabledata "My Time Sheets" = IMD,
                  tabledata "My Vendor" = IMD,
                  tabledata "Name/Value Buffer" = IMD,
                  tabledata "Named Forward Link" = IMD,
                  tabledata "Notification Context" = IMD,
                  tabledata "Notification Entry" = imd,
                  tabledata "Notification Schedule" = IMD,
                  tabledata "Notification Setup" = IMD,
                  tabledata "O365 Brand Color" = IMD,
                  tabledata "O365 Device Setup Instructions" = IMD,
                  tabledata "O365 Getting Started" = IMD,
                  tabledata "O365 Getting Started Page Data" = IMD,
                  tabledata "O365 HTML Template" = IMD,
                  tabledata "O365 Payment Service Logo" = IMD,
                  tabledata "OAuth 2.0 Setup" = IMD,
                  tabledata "Object Translation" = IMD,
                  tabledata "OCR Service Document Template" = IMD,
                  tabledata "OData Initialized Status" = IMD,
                  tabledata "Office Add-in" = IMD,
                  tabledata "Office Add-in Context" = IMD,
                  tabledata "Office Admin. Credentials" = imd,
                  tabledata "Office Contact Details" = IMD,
                  tabledata "Office Document Selection" = IMD,
                  tabledata "Office Invoice" = IMD,
                  tabledata "Office Job Journal" = IMD,
                  tabledata "Office Suggested Line Item" = IMD,
                  tabledata "Online Bank Acc. Link" = IMD,
                  tabledata "Online Map Parameter Setup" = imd,
                  tabledata "Online Map Setup" = imd,
                  tabledata "Option Lookup Buffer" = imd,
                  tabledata "Order Address" = im,
                  tabledata "Over-Receipt Code" = IMD,
                  tabledata "Overdue Approval Entry" = imd,
                  tabledata "Vendor Payment Buffer" = IMD,
                  tabledata "Payment Export Data" = imd,
                  tabledata "Payment Export Remittance Text" = IMD,
                  tabledata "Payment Jnl. Export Error Text" = IMD,
                  tabledata "Payment Method Translation" = IMD,
                  tabledata "Payment Registration Buffer" = IMD,
                  tabledata "Payment Registration Setup" = IMD,
                  tabledata "Payment Reporting Argument" = imd,
                  tabledata "Payment Term Translation" = IMD,
                  tabledata "Payroll Import Buffer" = IMD,
                  tabledata "Payroll Setup" = IMD,
                  tabledata "Phys. Inventory Ledger Entry" = im,
                  tabledata "Picture Entity" = IMD,
                  tabledata "Positive Pay Detail" = IMD,
                  tabledata "Positive Pay Entry" = imd,
                  tabledata "Positive Pay Entry Detail" = imd,
                  tabledata "Positive Pay Footer" = IMD,
                  tabledata "Positive Pay Header" = IMD,
                  tabledata "Post Code" = i,
                  tabledata "Posted Approval Comment Line" = imd,
                  tabledata "Posted Approval Entry" = imd,
                  tabledata "Posted Deferral Header" = IMD,
                  tabledata "Posted Deferral Line" = IMD,
                  tabledata "Posted Docs. With No Inc. Buf." = IMD,
                  tabledata "Posted Gen. Journal Batch" = IMD,
                  tabledata "Posted Gen. Journal Line" = IMD,
                  tabledata "Power BI Chart Buffer" = IMD,
                  tabledata "Power BI Context Settings" = IMD,
                  tabledata "Power BI Customer Reports" = IMD,
                  tabledata "Power BI Displayed Element" = IMD,
                  tabledata "Power BI Report Uploads" = IMD,
                  tabledata "Prepayment Inv. Line Buffer" = IMD,
                  tabledata "Price Asset" = im,
                  tabledata "Price Calculation Buffer" = im,
                  tabledata "Price Calculation Setup" = im,
                  tabledata "Price Line Filters" = im,
                  tabledata "Price List Header" = im,
                  tabledata "Price List Line" = im,
                  tabledata "Price Source" = im,
                  tabledata "Price Worksheet Line" = im,
                  tabledata "Printer Selection" = IMD,
                  tabledata "Purch. Comment Line" = IMD,
                  tabledata "Purch. Comment Line Archive" = IMD,
                  tabledata "Purch. Cr. Memo Entity Buffer" = IMD,
                  tabledata "Purch. Inv. Entity Aggregate" = IMD,
                  tabledata "Purch. Inv. Line Aggregate" = IMD,
                  tabledata "Purch. Price Line Disc. Buff." = IMD,
                  tabledata "Purchase Cue" = IMD,
                  tabledata "Purchase Discount Access" = im,
                  tabledata "Purchase Header" = im,
                  tabledata "Purchase Line" = im,
                  tabledata "Purchase Line Discount" = im,
                  tabledata "Purchase Order Entity Buffer" = IMD,
                  tabledata "Purchase Prepayment %" = im,
                  tabledata "Purchase Price" = im,
                  tabledata "Purchase Price Access" = im,
                  tabledata "Purchases & Payables Setup" = m,
                  tabledata "Query Metadata" = imd,
                  tabledata "RapidStart Services Cue" = IMD,
                  tabledata "RC Headlines User Data" = IMD,
                  tabledata "Reason Code" = IMD,
                  tabledata "Receivables-Payables Buffer" = IMD,
                  tabledata "Reclas. Dimension Set Buffer" = IMD,
                  tabledata "Reconcile CV Acc Buffer" = IMD,
                  tabledata "Record Export Buffer" = IMD,
                  tabledata "Record Set Buffer" = imd,
                  tabledata "Record Set Definition" = imd,
                  tabledata "Record Set Tree" = imd,
                  tabledata "Recorded Event Buffer" = IMD,
                  tabledata "Referenced XML Schema" = IMD,
                  tabledata "Relationship Mgmt. Cue" = IMD,
                  tabledata "Reminder Terms Translation" = IMD,
                  tabledata "Remit Address" = im,
                  tabledata "Report Inbox" = IMD,
                  tabledata "Report Layout Selection" = IMD,
                  tabledata "Report Layout Update Log" = IMD,
                  tabledata "Report List Translation" = IMD,
                  tabledata "Report Selection Warehouse" = IMD,
                  tabledata "Report Selections" = IMD,
                  tabledata "Report Totals Buffer" = IMD,
                  tabledata "Requisition Line" = im,
                  tabledata "Res. Availability Buffer" = IMD,
                  tabledata "Res. Gr. Availability Buffer" = IMD,
                  tabledata "Res. Journal Batch" = IMD,
                  tabledata "Res. Journal Template" = IMD,
                  tabledata "Res. Ledger Entry" = i,
                  tabledata "Reservation Entry" = imd,
                  tabledata "Reservation Entry Buffer" = IMD,
                  tabledata Resource = imd,
                  tabledata "Resource Register" = im,
                  tabledata "Restricted Record" = imd,
                  tabledata "Reversal Entry" = IMD,
                  tabledata "Role Center Notifications" = IMD,
                  tabledata "Rounding Residual Buffer" = imd,
                  tabledata "Sales & Receivables Setup" = m,
                  tabledata "Sales by Cust. Grp.Chart Setup" = IMD,
                  tabledata "Sales Comment Line" = IMD,
                  tabledata "Sales Comment Line Archive" = IMD,
                  tabledata "Sales Cr. Memo Entity Buffer" = IMD,
                  tabledata "Sales Cue" = IMD,
                  tabledata "Sales Discount Access" = im,
                  tabledata "Sales Document Icon" = imd,
                  tabledata "Sales Header" = im,
                  tabledata "Sales Invoice Entity Aggregate" = IMD,
                  tabledata "Sales Invoice Header" = m,
                  tabledata "Sales Invoice Line Aggregate" = IMD,
                  tabledata "Sales Line" = im,
                  tabledata "Sales Line Discount" = im,
                  tabledata "Sales Order Entity Buffer" = IMD,
                  tabledata "Sales Prepayment %" = im,
                  tabledata "Sales Price" = im,
                  tabledata "Sales Price Access" = im,
                  tabledata "Sales Price and Line Disc Buff" = IMD,
                  tabledata "Sales Quote Entity Buffer" = IMD,
                  tabledata "Sales Shipment Buffer" = IMD,
                  tabledata "SB Owner Cue" = IMD,
                  tabledata "Selected Dimension" = IMD,
                  tabledata "Semi-Manual Execution Log" = IMD,
                  tabledata "Semi-Manual Test Wizard" = IMD,
                  tabledata "Sent Notification Entry" = imd,
                  tabledata "SEPA Direct Debit Mandate" = IMD,
                  tabledata "Service Connection" = IMD,
                  tabledata "Sheet Definition Name" = IMD,
                  tabledata "Sheet Definition Line" = IMD,
                  tabledata "Ship-to Address" = im,
                  tabledata "Shipment Method Translation" = IMD,
                  tabledata "Sorting Table" = IMD,
                  tabledata "Standard Address" = imd,
                  tabledata "Standard General Journal" = IMD,
                  tabledata "Standard General Journal Line" = imd,
                  tabledata "Standard Item Journal" = im,
                  tabledata "Standard Item Journal Line" = imd,
                  tabledata "Standard Text" = IMD,
                  tabledata "Table Filter" = IMD,
                  tabledata "Tax Area Buffer" = IMD,
                  tabledata "Tax Group Buffer" = IMD,
                  tabledata "Tax Rate Buffer" = IMD,
                  tabledata "Tax Setup" = IMD,
                  tabledata "Team Member Cue" = IMD,
                  tabledata TempStack = IMD,
                  tabledata "Terms And Conditions" = IM,
                  tabledata "Terms And Conditions State" = IM,
                  tabledata "Text-to-Account Mapping" = IMD,
                  tabledata "Time Series Buffer" = IMD,
                  tabledata "Time Sheet Detail" = M,
                  tabledata "Time Sheet Detail Archive" = M,
                  tabledata "Time Sheet Header Archive" = m,
                  tabledata "Time Sheet Line" = m,
                  tabledata "Time Sheet Line Archive" = m,
                  tabledata "Top Customers By Sales Buffer" = IMD,
                  tabledata "Trailing Sales Orders Setup" = IMD,
                  tabledata "Transformation Rule" = IMD,
                  tabledata "Trial Balance Cache" = IMD,
                  tabledata "Trial Balance Cache Info" = IMD,
                  tabledata "Trial Balance Entity Buffer" = IMD,
                  tabledata "Trial Balance Setup" = IMD,
                  tabledata "Unit Group" = IMD,
                  tabledata "Unit of Measure" = IMD,
                  tabledata "Unit of Measure Translation" = IMD,
                  tabledata "Unlinked Attachment" = IMD,
                  tabledata "User Preference" = IMD,
                  tabledata "User Task" = IMD,
                  tabledata "User Time Register" = imd,
                  tabledata "User Tours" = IMD,
                  tabledata "Value Entry" = im,
                  tabledata "VAT Registration Log" = IMD,
                  tabledata "VAT Report Archive" = imd,
                  tabledata "VAT Reports Configuration" = IMD,
                  tabledata "VAT Statement Report Line" = IMD,
                  tabledata "VAT Setup" = IMD,
                  tabledata Vendor = im,
                  tabledata "Vendor Amount" = IMD,
                  tabledata "Vendor Purchase Buffer" = IMD,
                  tabledata "Vendor Templ." = IMD,
                  tabledata "WF Event/Response Combination" = IMD,
                  tabledata "Workflow - Record Change" = imd,
                  tabledata "Workflow Buffer" = IMD,
                  tabledata "Workflow Category" = IMD,
                  tabledata "Workflow Event" = iMD,
                  tabledata "Workflow Event Queue" = imd,
                  tabledata "Workflow Record Change Archive" = imd,
                  tabledata "Workflow Rule" = imd,
                  tabledata "Workflow Step Argument" = imd,
                  tabledata "Workflow Step Argument Archive" = imd,
                  tabledata "Workflow Step Buffer" = IMD,
                  tabledata "Workflow Step Instance" = imd,
                  tabledata "Workflow Step Instance Archive" = imd,
                  tabledata "Workflow Table Relation Value" = imd,
                  tabledata "Workflow Webhook Entry" = imd,
                  tabledata "Workflow Webhook Notification" = imd,
                  tabledata "Workflows Entries Buffer" = imd,
                  tabledata "XML Buffer" = IMD,
                  tabledata "XML Schema" = IMD,
                  tabledata "XML Schema Element" = IMD,
                  tabledata "XML Schema Restriction" = IMD,
                  tabledata "Acc. Payable Performance Chart" = IMD,
                  tabledata "Account Payable Cue" = IMD,
                  tabledata "Top Vendors By Purchase" = IMD,
                  tabledata "Purch. by Vend.Grp.Chart Setup" = IMD;
}