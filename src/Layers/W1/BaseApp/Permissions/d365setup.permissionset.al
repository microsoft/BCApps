namespace System.Security.AccessControl;

using Microsoft.Assembly.Setup;
using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Check;
using Microsoft.Bank.DirectDebit;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Payment;
using Microsoft.Bank.PositivePay;
using Microsoft.Bank.Reconciliation;
using Microsoft.Bank.Statement;
using Microsoft.Bank.Setup;
using Microsoft.CashFlow.Setup;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Duplicates;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Outlook;
using Microsoft.CRM.Profiling;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Setup;
using Microsoft.CRM.Task;
using Microsoft.CRM.Team;
using Microsoft.EServices.EDocument;
using Microsoft.eServices.OnlineMap;
using Microsoft.Finance.AllocationAccount;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Deferral;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.SalesTax;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Clause;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.VAT.Setup;
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Calendar;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Foundation.Period;
using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.Task;
using Microsoft.HumanResources.Payables;
using Microsoft.HumanResources.Employee;
using Microsoft.HumanResources.Setup;
using Microsoft.Integration.Entity;
using Microsoft.Integration.Dataverse;
using Microsoft.Integration.D365Sales;
using Microsoft.Integration.SyncEngine;
using Microsoft.Intercompany.Setup;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.BOM.Tree;
using Microsoft.Inventory.Comment;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Counting.Comment;
using Microsoft.Inventory.Counting.Document;
using Microsoft.Inventory.Counting.History;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Counting.Recording;
using Microsoft.Inventory.Counting.Tracking;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Reconciliation;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.Resources.Pricing;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.Resources.Setup;
using Microsoft.Projects.TimeSheet;
using Microsoft.Projects.Project.WIP;
using Microsoft.Projects.Project.Setup;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Pricing.Worksheet;
using Microsoft.Purchases.Archive;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Customer;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;
using Microsoft.Sales.Document;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Reminder;
using Microsoft.Sales.Receivables;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Worksheet;
using Microsoft.Utilities;
using Microsoft;

using System.Apps;
using System.Automation;
using System.Azure.Identity;
using System.Diagnostics;
using System.Environment.Configuration;
using System.IO;
using System.Integration;
using System.Privacy;
using System.Security.User;
using System.Threading;

permissionset 191 "D365 SETUP"
{
    Access = Public;
    Assignable = true;
    Caption = 'Dyn. 365 Company data setup';

    IncludedPermissionSets = "BaseApp Objects - Exec",
                             "D365 CUSTOMER, EDIT",
                             "D365 INV, SETUP",
                             "D365 ITEM, EDIT",
                             "D365 VENDOR, EDIT",
                             "D365 RAPIDSTART",
                             "System App - Basic",
                             "Company - Edit";

    Permissions = tabledata "Data Sensitivity" = RIMD,
                  tabledata "NAV App Installed App" = Rimd,
                  tabledata "Object Options" = IMD,
                  tabledata "Acc. Sched. Cell Value" = D,
                  tabledata "Acc. Sched. KPI Web Srv. Line" = RIMD,
                  tabledata "Acc. Sched. KPI Web Srv. Setup" = RIMD,
                  tabledata "Acc. Schedule Line" = RIMD,
                  tabledata "Acc. Schedule Line Entity" = RIMD,
                  tabledata "Acc. Schedule Name" = RIMD,
                  tabledata "Alloc. Acc. Manual Override" = RIMD,
                  tabledata "Alloc. Account Distribution" = RIMD,
                  tabledata "Allocation Account" = RIMD,
                  tabledata "Allocation Line" = RIMD,
                  tabledata "Financial Report" = RIMD,
                  tabledata "Financial Report Export Log" = RIMD,
                  tabledata "Financial Report Recipient" = RIMD,
                  tabledata "Financial Report Schedule" = RIMD,
                  tabledata "Financial Report User Filters" = RIMD,
                  tabledata "Fin. Report Excel Template" = RIMD,
                  tabledata "Accounting Period" = IMD,
                  tabledata "Action Message Entry" = D,
                  tabledata Activity = D,
                  tabledata "Alt. Customer Posting Group" = RIMD,
                  tabledata "Alt. Vendor Posting Group" = RIMD,
                  tabledata "Alt. Employee Posting Group" = RIMD,
                  tabledata "Analysis Column" = D,
                  tabledata "Analysis Column Template" = D,
                  tabledata "Analysis Field Value" = D,
                  tabledata "Analysis Line" = D,
                  tabledata "Analysis Line Template" = D,
                  tabledata "Analysis Report Name" = D,
                  tabledata "Analysis Type" = D,
                  tabledata "Analysis View" = RIMD,
                  tabledata "Analysis View Budget Entry" = RD,
                  tabledata "Analysis View Entry" = RimD,
                  tabledata "Analysis View Filter" = RIMD,
                  tabledata "Applied Payment Entry" = D,
                  tabledata "Approval Workflow Wizard" = RIMD,
                  tabledata Area = RIMD,
                  tabledata "Assembly Setup" = Rimd,
                  tabledata "Assisted Company Setup Status" = RIMD,
                  tabledata Attachment = D,
                  tabledata "Availability at Date" = D,
                  tabledata "Availability Calc. Overview" = D,
                  tabledata "Average Cost Calc. Overview" = D,
                  tabledata "Avg. Cost Adjmt. Entry Point" = D,
                  tabledata "Azure AD App Setup" = RIMD,
                  tabledata "Azure AD Mgt. Setup" = RIMD,
                  tabledata "Bank Acc. Reconciliation" = D,
                  tabledata "Bank Acc. Reconciliation Line" = D,
                  tabledata "Bank Acc. Rec. Match Buffer" = D,
                  tabledata "Bank Account" = RIMD,
                  tabledata "Bank Account Ledger Entry" = d,
                  tabledata "Bank Account Posting Group" = RIMD,
                  tabledata "Bank Account Statement" = D,
                  tabledata "Bank Account Statement Line" = d,
                  tabledata "Bank Clearing Standard" = ID,
                  tabledata "Bank Export/Import Setup" = RIMD,
                  tabledata "Bank Pmt. Appl. Rule" = RIMD,
                  tabledata "Bank Pmt. Appl. Settings" = RIMD,
                  tabledata "Bank Stmt Multiple Match Line" = D,
                  tabledata "Base Calendar" = IMD,
                  tabledata "Base Calendar Change" = RIMD,
                  tabledata Bin = IMD,
                  tabledata "Bin Content" = IMD,
                  tabledata "BOM Component" = RIMD,
                  tabledata "Bus. Unit In Cons. Process" = D,
                  tabledata "Business Relation" = D,
                  tabledata "Business Unit" = D,
                  tabledata "Business Unit Information" = D,
                  tabledata "Business Unit Setup" = D,
                  tabledata Campaign = D,
                  tabledata "Campaign Entry" = D,
                  tabledata "Campaign Status" = D,
                  tabledata "Cancelled Document" = Rimd,
                  tabledata "Cash Flow Setup" = Rid,
                  tabledata "Change Log Entry" = im,
                  tabledata "Change Log Setup (Field)" = RIMD,
                  tabledata "Change Log Setup (Table)" = RIMD,
                  tabledata "Change Log Setup" = RIMD,
                  tabledata "Check Ledger Entry" = d,
                  tabledata "Close Opportunity Code" = D,
                  tabledata "Communication Method" = RIMD,
                  tabledata "Company Information" = RIMD,
                  tabledata "Config. Field Map" = RIMD,
                  tabledata "Config. Line" = RIMD,
                  tabledata "Config. Package" = RIMD,
                  tabledata "Config. Package Data" = RIMD,
                  tabledata "Config. Package Error" = RIMD,
                  tabledata "Config. Package Field" = RIMD,
                  tabledata "Config. Package Filter" = RIMD,
                  tabledata "Config. Package Record" = RIMD,
                  tabledata "Config. Package Table" = RIMD,
                  tabledata "Config. Question" = RIMD,
                  tabledata "Config. Question Area" = RIMD,
                  tabledata "Config. Questionnaire" = RIMD,
                  tabledata "Config. Record For Processing" = RIMD,
                  tabledata "Config. Related Field" = RIMD,
                  tabledata "Config. Related Table" = RIMD,
                  tabledata "Config. Selection" = RIMD,
                  tabledata "Config. Setup" = RIMD,
                  tabledata "Config. Table Processing Rule" = RIMD,
                  tabledata "Config. Template Header" = RIMD,
                  tabledata "Config. Template Line" = RIMD,
                  tabledata "Config. Tmpl. Selection Rules" = RIMD,
                  tabledata "Consolidation Account" = D,
                  tabledata "Consolidation Process" = D,
                  tabledata "Consolidation Setup" = D,
                  tabledata "Contact Duplicate" = D,
                  tabledata "Contact Industry Group" = D,
                  tabledata "Contact Job Responsibility" = D,
                  tabledata "Contact Mailing Group" = D,
                  tabledata "Contact Profile Answer" = D,
                  tabledata "Contact Value" = D,
                  tabledata "Contact Web Source" = D,
                  tabledata "Coupling Record Buffer" = RIMD,
                  tabledata "Credit Trans Re-export History" = D,
                  tabledata "Credit Transfer Entry" = D,
                  tabledata "Credit Transfer Register" = D,
                  tabledata "CRM Connection Setup" = RIMD,
                  tabledata "CRM Full Synch. Review Line" = RIMD,
                  tabledata "CRM Integration Record" = RIMD,
                  tabledata "CRM Option Mapping" = RIMD,
                  tabledata "CRM Redirect" = R,
                  tabledata "CRM Synch Status" = RIMD,
                  tabledata "CRM Synch. Conflict Buffer" = RIMD,
                  tabledata "CRM Synch. Job Status Cue" = RIMD,
                  tabledata "Curr. Exch. Rate Update Setup" = RIMD,
                  tabledata Currency = ID,
                  tabledata "Currency Exchange Rate" = RIMD,
                  tabledata "Currency for Fin. Charge Terms" = RIMD,
                  tabledata "Currency for Reminder Level" = RIMD,
                  tabledata "Cust. Ledger Entry" = d,
                  tabledata "Customer Posting Group" = RIMD,
                  tabledata "Customer Price Group" = RIMD,
                  tabledata "Customer Templ." = RIMD,
                  tabledata "Customized Calendar Change" = RIMD,
                  tabledata "Customized Calendar Entry" = RIMD,
                  tabledata "Data Exch." = RIMD,
                  tabledata "Data Exchange Type" = RimD,
                  tabledata "Data Exch. Table Filter" = RIMD,
                  tabledata "Data Migration Entity" = RIMD,
                  tabledata "Data Migration Error" = RIMD,
                  tabledata "Data Migration Parameters" = RIMD,
                  tabledata "Data Migration Setup" = RIMD,
                  tabledata "Data Migration Status" = RIMD,
                  tabledata "Data Migrator Registration" = RIMD,
                  tabledata "Data Privacy Records" = RIMD,
                  tabledata "Date Compr. Register" = Rd,
                  tabledata "Deferral Header Archive" = D,
                  tabledata "Deferral Line Archive" = D,
                  tabledata "Delivery Sorter" = D,
                  tabledata Dimension = RIMD,
                  tabledata "Dimension Value" = RIMD,
                  tabledata "Direct Debit Collection" = D,
                  tabledata "Direct Debit Collection Entry" = D,
                  tabledata "Dispute Status" = RIMD,
                  tabledata "Doc. Exch. Service Setup" = RIMD,
                  tabledata "Duplicate Search String Setup" = D,
                  tabledata "Dynamic Request Page Entity" = RIMD,
                  tabledata "Dynamic Request Page Field" = RIMD,
                  tabledata "Employee Ledger Entry" = Rd,
                  tabledata "Employee Posting Group" = RIMD,
                  tabledata "Exch. Rate Adjmt. Reg." = d,
                  tabledata "Exch. Rate Adjmt. Ledg. Entry" = d,
                  tabledata "Exchange Folder" = D,
                  tabledata "Exchange Service Setup" = RIMD,
                  tabledata "Exp. Invt. Order Tracking" = RIMD,
                  tabledata "FA Setup" = Rimd,
                  tabledata "Fin. Charge Comment Line" = D,
                  tabledata "Finance Charge Interest Rate" = RIMD,
                  tabledata "Finance Charge Memo Header" = D,
                  tabledata "Finance Charge Memo Line" = D,
                  tabledata "Finance Charge Terms" = RIMD,
                  tabledata "Finance Charge Text" = IMD,
                  tabledata "G/L - Item Ledger Relation" = D,
                  tabledata "G/L Account (Analysis View)" = D,
                  tabledata "G/L Account" = RIMD,
                  tabledata "G/L Account Category" = RIMD,
                  tabledata "G/L Budget Entry" = RIMD,
                  tabledata "G/L Budget Name" = RIMD,
                  tabledata "G/L Entry - VAT Entry Link" = d,
                  tabledata "G/L Entry" = Rd,
                  tabledata "G/L Register" = d,
                  tabledata "Gen. Journal Line" = RIMD,
                  tabledata "Gen. Journal Template" = RIMD,
                  tabledata "General Ledger Setup" = RIMD,
                  tabledata "General Posting Setup" = RIMD,
                  tabledata "Human Resources Setup" = Rimd,
                  tabledata "IC Setup" = RIMD,
                  tabledata "Incoming Document" = RIMD,
                  tabledata "Incoming Document Approver" = RIMD,
                  tabledata "Incoming Documents Setup" = RIMD,
                  tabledata "Int. Table Config Template" = RIMD,
                  tabledata "Integration Field Mapping" = RIMD,
                  tabledata "Integration Synch. Job" = RIMD,
                  tabledata "Integration Synch. Job Errors" = RIMD,
                  tabledata "Integration Table Mapping" = RIMD,
                  tabledata "Inter. Log Entry Comment Line" = D,
                  tabledata "Interaction Log Entry" = D,
                  tabledata "Intermediate Data Import" = RimD,
                  tabledata "Inventory Adjmt. Entry (Order)" = d,
                  tabledata "Inventory Comment Line" = D,
                  tabledata "Inventory Page Data" = D,
                  tabledata "Inventory Period" = RIMD,
                  tabledata "Inventory Period Entry" = D,
                  tabledata "Inventory Profile Track Buffer" = D,
                  tabledata "Inventory Report Entry" = D,
                  tabledata "Inventory Report Header" = D,
                  tabledata "Inventory Setup" = RIMD,
                  tabledata "Issued Fin. Charge Memo Header" = RmD,
                  tabledata "Issued Fin. Charge Memo Line" = d,
                  tabledata "Issued Reminder Header" = RmD,
                  tabledata "Issued Reminder Line" = d,
                  tabledata "Item Application Entry History" = D,
                  tabledata "Item Availability by Date" = D,
                  tabledata "Item Availability Line" = D,
                  tabledata "Item Category" = IMD,
                  tabledata "Item Charge" = RIMD,
                  tabledata "Item Charge Assignment (Purch)" = rD,
                  tabledata "Item Charge Assignment (Sales)" = rD,
                  tabledata "Item Discount Group" = RIMD,
                  tabledata "Item Entry Relation" = RIMD,
                  tabledata "Item Ledger Entry" = Rmd,
                  tabledata "Item Register" = d,
                  tabledata "Item Tracing Buffer" = Rimd,
                  tabledata "Item Tracing History Buffer" = Rimd,
                  tabledata "Item Tracking Code" = RIMD,
                  tabledata "Item Tracking Setup" = RIMD,
                  tabledata "Job Queue Category" = RIMD,
                  tabledata "Job Queue Log Entry" = RIMD,
                  tabledata "Job WIP Method" = Rimd,
                  tabledata "Jobs Setup" = Rimd,
                  tabledata "License Agreement" = RIMD,
                  tabledata "Line Fee Note on Report Hist." = imd,
                  tabledata "Logged Segment" = d,
                  tabledata "Lot No. Information" = RIMD,
                  tabledata "Man. Integration Table Mapping" = RIMD,
                  tabledata "Man. Int. Field Mapping" = RIMD,
                  tabledata Manufacturer = RIMD,
                  tabledata "Marketing Setup" = RImD,
                  tabledata "Memoized Result" = D,
                  tabledata "No. Series" = RIMD,
                  tabledata "No. Series Line" = RIMD,
                  tabledata "No. Series Relationship" = RIMD,
                  tabledata "Nonstock Item Setup" = RIMD,
                  tabledata "Notification Entry" = RimD,
                  tabledata "OCR Service Setup" = RIMD,
                  tabledata "Office Add-in Setup" = RIMD,
                  tabledata "Online Map Parameter Setup" = RIMD,
                  tabledata "Online Map Setup" = RIMD,
                  tabledata Opportunity = D,
                  tabledata "Opportunity Entry" = D,
                  tabledata "Order Promising Line" = D,
                  tabledata "Order Promising Setup" = RIMD,
                  tabledata "Order Tracking Entry" = d,
                  tabledata "Package No. Information" = RIMD,
                  tabledata "Payable Employee Ledger Entry" = D,
                  tabledata "Payable Vendor Ledger Entry" = D,
                  tabledata "Payment Application Proposal" = D,
                  tabledata "Payment Matching Details" = D,
                  tabledata "Payment Method" = IMD,
                  tabledata "Payment Rec. Related Entry" = RIMD,
                  tabledata "Pmt. Rec. Applied-to Entry" = RIMD,
                  tabledata "Payment Service Setup" = RIMD,
                  tabledata "Payment Terms" = RIMD,
                  tabledata "Phys. Inventory Ledger Entry" = Rmd,
                  tabledata "Phys. Invt. Comment Line" = RIMD,
                  tabledata "Phys. Invt. Count Buffer" = RIMD,
                  tabledata "Phys. Invt. Counting Period" = D,
                  tabledata "Phys. Invt. Item Selection" = D,
                  tabledata "Phys. Invt. Order Header" = RIMD,
                  tabledata "Phys. Invt. Order Line" = RIMD,
                  tabledata "Phys. Invt. Record Header" = RIMD,
                  tabledata "Phys. Invt. Record Line" = RIMD,
                  tabledata "Invt. Order Tracking" = RIMD,
                  tabledata "Planning Assignment" = D,
                  tabledata "Planning Component" = D,
                  tabledata "Positive Pay Entry" = D,
                  tabledata "Positive Pay Entry Detail" = D,
                  tabledata "Post Code" = RIMD,
                  tabledata "Post Value Entry to G/L" = d,
                  tabledata "Postcode Service Config" = RIMD,
                  tabledata "Posted Payment Recon. Hdr" = D,
                  tabledata "Posted Payment Recon. Line" = D,
                  tabledata "Posted Whse. Receipt Header" = D,
                  tabledata "Posted Whse. Receipt Line" = D,
                  tabledata "Posted Whse. Shipment Header" = D,
                  tabledata "Posted Whse. Shipment Line" = D,
                  tabledata "Price Asset" = RIMD,
                  tabledata "Price Calculation Buffer" = RIMD,
                  tabledata "Price Calculation Setup" = RIMD,
                  tabledata "Price Line Filters" = RIMD,
                  tabledata "Price List Header" = RIMD,
                  tabledata "Price List Line" = RIMD,
                  tabledata "Price Source" = RIMD,
                  tabledata "Price Worksheet Line" = RIMD,
                  tabledata "Profile Questionnaire Line" = D,
                  tabledata "Pstd.Exp.Invt.Order.Tracking" = RIMD,
                  tabledata "Pstd. Phys. Invt. Order Hdr" = RIMD,
                  tabledata "Pstd. Phys. Invt. Order Line" = RIMD,
                  tabledata "Pstd. Phys. Invt. Record Hdr" = RIMD,
                  tabledata "Pstd. Phys. Invt. Record Line" = RIMD,
                  tabledata "Pstd. Phys. Invt. Tracking" = RIMD,
                  tabledata "Purch. Cr. Memo Hdr." = RD,
                  tabledata "Purch. Cr. Memo Line" = Rd,
                  tabledata "Purch. Inv. Header" = RD,
                  tabledata "Purch. Inv. Line" = Rd,
                  tabledata "Purch. Rcpt. Header" = RD,
                  tabledata "Purch. Rcpt. Line" = Rd,
                  tabledata "Purchase Header" = RmD,
                  tabledata "Purchase Header Archive" = RmD,
                  tabledata "Purchase Line" = RmD,
                  tabledata "Purchase Line Archive" = RmD,
                  tabledata "Purchase Prepayment %" = RIMD,
                  tabledata "Purchases & Payables Setup" = RID,
                  tabledata Purchasing = RIMD,
                  tabledata Rating = D,
                  tabledata "Record Buffer" = Rimd,
                  tabledata "Registered Whse. Activity Hdr." = d,
                  tabledata "Registered Whse. Activity Line" = d,
                  tabledata "Reminder Attachment Text" = RIMD,
                  tabledata "Reminder Attachment Text Line" = RIMD,
                  tabledata "Reminder Comment Line" = D,
                  tabledata "Reminder Email Text" = RIMD,
                  tabledata "Reminder Header" = D,
                  tabledata "Reminder Level" = IMD,
                  tabledata "Reminder Line" = D,
                  tabledata "Reminder Terms" = RIMD,
                  tabledata "Reminder Action Group" = RIMD,
                  tabledata "Reminder Action" = RIMD,
                  tabledata "Create Reminders Setup" = RIMD,
                  tabledata "Issue Reminders Setup" = RIMD,
                  tabledata "Send Reminders Setup" = RIMD,
                  tabledata "Reminder Automation Error" = RIMD,
                  tabledata "Reminder Action Group Log" = RIMD,
                  tabledata "Reminder Action Log" = RIMD,
                  tabledata "Reminder Text" = IMD,
                  tabledata "Reminder/Fin. Charge Entry" = d,
                  tabledata "Req. Wksh. Template" = RIMD,
                  tabledata "Requisition Line" = RmD,
                  tabledata "Requisition Wksh. Name" = RIMD,
                  tabledata "Res. Journal Line" = D,
                  tabledata "Reservation Entry" = RimD,
                  tabledata "Resource Cost" = D,
                  tabledata "Resource Price" = D,
                  tabledata "Resource Unit of Measure" = D,
                  tabledata "Resources Setup" = RimD,
                  tabledata "Responsibility Center" = RIMD,
                  tabledata "Restricted Record" = D,
                  tabledata "Return Reason" = RIMD,
                  tabledata "Return Receipt Header" = RD,
                  tabledata "Return Receipt Line" = R,
                  tabledata "Return Shipment Header" = d,
                  tabledata "Return Shipment Line" = R,
                  tabledata "Rounding Method" = RIMD,
                  tabledata "Sales & Receivables Setup" = RIMD,
                  tabledata "Sales Cr.Memo Header" = RD,
                  tabledata "Sales Cr.Memo Line" = Rd,
                  tabledata "Sales Discount Access" = IM,
                  tabledata "Sales Header" = RmD,
                  tabledata "Sales Header Archive" = RD,
                  tabledata "Sales Invoice Header" = RmD,
                  tabledata "Sales Invoice Line" = Rd,
                  tabledata "Sales Line" = RmD,
                  tabledata "Sales Line Archive" = RmD,
                  tabledata "Sales Line Discount" = IM,
                  tabledata "Sales Planning Line" = d,
                  tabledata "Sales Prepayment %" = RIMD,
                  tabledata "Sales Price Worksheet" = RIMD,
                  tabledata "Sales Shipment Header" = RD,
                  tabledata "Sales Shipment Line" = d,
                  tabledata "Salesperson/Purchaser" = RIMD,
                  tabledata Salutation = D,
                  tabledata "Saved Segment Criteria" = D,
                  tabledata "Saved Segment Criteria Line" = D,
                  tabledata "Segment Criteria Line" = D,
                  tabledata "Segment Header" = D,
                  tabledata "Segment History" = D,
                  tabledata "Segment Interaction Language" = D,
                  tabledata "Segment Line" = D,
                  tabledata "Segment Wizard Filter" = D,
                  tabledata "Sent Notification Entry" = RimD,
                  tabledata "Serial No. Information" = RIMD,
                  tabledata "Shipment Method" = RIMD,
                  tabledata "Shipping Agent" = RIMD,
                  tabledata "Shipping Agent Services" = IMD,
                  tabledata "Source Code" = RIMD,
                  tabledata "Source Code Setup" = RIMD,
                  tabledata "Special Equipment" = IMD,
                  tabledata "Standard General Journal Line" = RIMD,
                  tabledata "Table Config Template" = RIMD,
                  tabledata "Tariff Number" = RIMD,
                  tabledata "Tax Area" = RIMD,
                  tabledata "Tax Area Line" = RIMD,
                  tabledata "Tax Area Translation" = RIMD,
                  tabledata "Tax Detail" = RIMD,
                  tabledata "Tax Group" = RIMD,
                  tabledata "Tax Jurisdiction" = RIMD,
                  tabledata "Tax Jurisdiction Translation" = RIMD,
                  tabledata Team = D,
                  tabledata "Team Salesperson" = D,
                  tabledata "Temp Integration Field Mapping" = RIMD,
                  tabledata "Tenant Config. Package File" = RIMD,
                  tabledata Territory = RIMD,
                  tabledata "Timeline Event" = D,
                  tabledata "Timeline Event Change" = D,
                  tabledata "To-do" = D,
                  tabledata "To-do Interaction Language" = D,
                  tabledata "Tracking Specification" = D,
                  tabledata "Transaction Specification" = RIMD,
                  tabledata "Transaction Type" = RIMD,
                  tabledata "Transport Method" = RIMD,
                  tabledata "Untracked Planning Element" = D,
                  tabledata "User Security Status" = D,
                  tabledata "User Setup" = RIMD,
                  tabledata "User Task Group" = RIMD,
                  tabledata "User Task Group Member" = RIMD,
                  tabledata "User Time Register" = RIMD,
                  tabledata "Value Entry" = Rmd,
                  tabledata "Value Entry Relation" = RIMD,
                  tabledata "VAT Amount Line" = RIMD,
                  tabledata "VAT Assisted Setup Bus. Grp." = RIMD,
                  tabledata "VAT Assisted Setup Templates" = RIMD,
                  tabledata "VAT Business Posting Group" = RIMD,
                  tabledata "VAT Clause" = RIMD,
                  tabledata "VAT Clause by Doc. Type" = RIMD,
                  tabledata "VAT Clause by Doc. Type Trans." = RIMD,
                  tabledata "VAT Clause Translation" = RIMD,
                  tabledata "VAT Entry" = d,
                  tabledata "VAT Posting Setup" = RIMD,
                  tabledata "VAT Product Posting Group" = RIMD,
                  tabledata "VAT Rate Change Conversion" = IMD,
                  tabledata "VAT Rate Change Log Entry" = d,
                  tabledata "VAT Rate Change Setup" = IMD,
                  tabledata "VAT Report Error Log" = RIMD,
                  tabledata "VAT Report Header" = RIMD,
                  tabledata "VAT Report Line" = RIMD,
                  tabledata "VAT Report Line Relation" = RIMD,
                  tabledata "VAT Report Setup" = RIMD,
                  tabledata "VAT Reporting Code" = RIMD,
                  tabledata "VAT Return Period" = RIMD,
                  tabledata "VAT Setup Posting Groups" = RIMD,
                  tabledata "VAT Statement Line" = RIMD,
                  tabledata "VAT Statement Name" = RIMD,
                  tabledata "VAT Statement Template" = RIMD,
                  tabledata "VAT Setup" = RIMD,
                  tabledata "Alt. Cust. VAT Reg." = RIMD,
                  tabledata "VAT Posting Parameters" = RIMD,
                  tabledata "Vendor Invoice Disc." = R,
                  tabledata "Vendor Ledger Entry" = RMd,
                  tabledata "Vendor Posting Group" = RIMD,
                  tabledata "Warehouse Activity Header" = D,
                  tabledata "Warehouse Activity Line" = D,
                  tabledata "Warehouse Comment Line" = D,
                  tabledata "Warehouse Reason Code" = IMD,
                  tabledata "Warehouse Register" = D,
                  tabledata "Warehouse Request" = D,
                  tabledata "Warehouse Setup" = RID,
                  tabledata "Warehouse Shipment Line" = D,
                  tabledata "Warehouse Source Filter" = D,
                  tabledata "Web Source" = D,
                  tabledata "Whse. Item Entry Relation" = RIMD,
                  tabledata "Whse. Pick Request" = D,
                  tabledata "Whse. Put-away Request" = D,
                  tabledata "Whse. Worksheet Line" = D,
                  tabledata "Work Type" = D,
                  tabledata "Workflow - Table Relation" = RIMD,
                  tabledata Workflow = RIMD,
                  tabledata "Workflow Event" = RIMD,
                  tabledata "Workflow Event Queue" = RIMD,
                  tabledata "Workflow Response" = RIMD,
                  tabledata "Workflow Rule" = RIMD,
                  tabledata "Workflow Step" = RIMD,
                  tabledata "Workflow Step Argument" = RIMD,
                  tabledata "Workflow Step Instance" = RimD,
                  tabledata "Workflow Table Relation Value" = RimD,
                  tabledata "Workflow User Group" = RIMD,
                  tabledata "Workflow User Group Member" = RIMD,
                  tabledata "Report Settings Override" = Rimd;
}