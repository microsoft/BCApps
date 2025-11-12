namespace System.Security.AccessControl;

using Microsoft.Assembly.Setup;
using Microsoft.Bank.Payment;
using Microsoft.Bank.Setup;
using Microsoft.CashFlow.Forecast;
using Microsoft.CashFlow.Setup;
using Microsoft.CostAccounting.Setup;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Duplicates;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Setup;
using Microsoft.CRM.Task;
using Microsoft.EServices.EDocument;
using Microsoft.eServices.OnlineMap;
using Microsoft.Finance.Analysis;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Posting;
using Microsoft.FixedAssets.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Calendar;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.Period;
using Microsoft.Foundation.Reporting;
using Microsoft.HumanResources.Setup;
using Microsoft.Integration.D365Sales;
using Microsoft.Integration.Dataverse;
using Microsoft.Integration.Entity;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Setup;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Setup;
using Microsoft.Projects.Project.WIP;
using Microsoft.Projects.Resources.Setup;
using Microsoft.Projects.TimeSheet;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Analysis;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Setup;
using Microsoft.Utilities;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Tracking;
using Microsoft;

using System.Automation;
using System.AI;
using System.Device;
using System.Diagnostics;
using System.Environment;
using System.Environment.Configuration;
using System.IO;
using System.Reflection;
using System.Security.User;
using System.Threading;
using System.Utilities;
using System.Visualization;

permissionset 6946 "Foundation UI"
{
    Access = Public;
    Assignable = false;
    Caption = 'Recommended for UI Removal';

    IncludedPermissionSets = "BaseApp Objects - Exec",
                             "System App - Basic";

    Permissions = tabledata Field = R,
                  tabledata Media = rimd,
                  tabledata "Media Set" = rimd,
                  tabledata User = R,
                  tabledata "Acc. Sched. KPI Web Srv. Setup" = Rim,
                  tabledata "Account Schedules Chart Setup" = Rim,
                  tabledata "Accounting Period" = R,
                  tabledata "Analysis by Dim. Parameters" = RIMD,
                  tabledata "Analysis by Dim. User Param." = RIMD,
                  tabledata "Analysis Report Chart Setup" = Rim,
                  tabledata "Application Area Buffer" = RIMD,
                  tabledata "Application Area Setup" = RIMD,
                  tabledata "Assembly Setup" = Rim,
                  tabledata "Availability at Date" = Rimd,
                  tabledata "Azure AI Usage" = Rimd,
                  tabledata "Bank Export/Import Setup" = Rim,
                  tabledata "Base Calendar" = R,
                  tabledata "Base Calendar Change" = R,
                  tabledata "Business Chart Buffer" = RIMD,
                  tabledata "Business Chart Map" = RIMD,
                  tabledata "Business Chart User Setup" = Rim,
                  tabledata "Cash Flow Azure AI Buffer" = Rimd,
                  tabledata "Cash Flow Chart Setup" = Rim,
                  tabledata "Cash Flow Setup" = Rim,
                  tabledata "CDS Connection Setup" = R,
                  tabledata "Change Log Entry" = ri,
                  tabledata "Change Log Setup (Field)" = r,
                  tabledata "Change Log Setup (Table)" = r,
                  tabledata "Change Log Setup" = Rim,
                  tabledata "Company Information" = R,
                  tabledata "Config. Setup" = Rim,
                  tabledata "Contact Business Relation" = R,
                  tabledata "Cost Accounting Setup" = Rim,
                  tabledata "CRM Connection Setup" = R,
                  tabledata "Custom Report Layout" = RIMD,
                  tabledata "Customer Discount Group" = R,
                  tabledata "Customized Calendar Change" = R,
                  tabledata "Customized Calendar Entry" = R,
                  tabledata "Depreciation Book" = R,
                  tabledata Dimension = R,
                  tabledata "Dimension Buffer" = R,
                  tabledata "Dimension Code Buffer" = R,
                  tabledata "Dimension Selection Buffer" = R,
                  tabledata "Dimension Set Entry" = Rim,
                  tabledata "Dimension Set Tree Node" = Rim,
                  tabledata "Dimension Translation" = R,
                  tabledata "Dimension Value" = R,
                  tabledata "Document Entry" = RIMD,
                  tabledata "Duplicate Search String Setup" = Rim,
                  tabledata "Dynamic Request Page Entity" = R,
                  tabledata "Dynamic Request Page Field" = R,
                  tabledata "Excel Template Storage" = RIMD,
                  tabledata "Experience Tier Buffer" = RIMD,
                  tabledata "Experience Tier Setup" = RIMD,
                  tabledata "Extended Text Header" = R,
                  tabledata "FA Date Type" = RIMD,
                  tabledata "FA Journal Setup" = Rim,
                  tabledata "FA Matrix Posting Type" = RIMD,
                  tabledata "FA Posting Type" = RIMD,
                  tabledata "FA Posting Type Setup" = Rim,
                  tabledata "FA Setup" = Rim,
                  tabledata "Field Buffer" = RIMD,
                  tabledata "G/L Account Net Change" = RIMD,
                  tabledata "General Ledger Setup" = Rim,
                  tabledata "General Posting Setup" = Rim,
                  tabledata "Generic Chart Setup" = Rim,
                  tabledata "Human Resources Setup" = Rim,
                  tabledata "Incoming Documents Setup" = Rim,
                  tabledata "Interaction Log Entry" = r,
                  tabledata "Interaction Template Setup" = Rim,
                  tabledata "Inventory Posting Setup" = Rim,
                  tabledata "Inventory Setup" = Rim,
                  tabledata "Item Discount Group" = R,
                  tabledata "Item Entry Relation" = Rimd,
                  tabledata "Job Buffer" = RIMD,
                  tabledata "Job Difference Buffer" = RIMD,
                  tabledata "Job Entry No." = RIMD,
                  tabledata "Job Queue Category" = Rimd,
                  tabledata "Job Queue Entry" = Rimd,
                  tabledata "Job Queue Log Entry" = Rimd,
                  tabledata "Job Queue Role Center Cue" = Rimd,
                  tabledata "Job WIP Buffer" = RIMD,
                  tabledata "Jobs Setup" = Rim,
                  tabledata "License Agreement" = RIM,
                  tabledata "Marketing Setup" = Rim,
                  tabledata "No. Series" = Rm,
                  tabledata "No. Series Line" = Rm,
                  tabledata "No. Series Relationship" = Rm,
                  tabledata "Nonstock Item Setup" = Rim,
                  tabledata "Notification Entry" = Rimd,
                  tabledata "Online Map Parameter Setup" = Rim,
                  tabledata "Online Map Setup" = Rim,
                  tabledata Opportunity = r,
                  tabledata "Opportunity Entry" = r,
                  tabledata "Order Promising Setup" = R,
                  tabledata "Payment Registration Setup" = Rim,
                  tabledata "Picture Entity" = RIMD,
                  tabledata "Post Code" = Ri,
                  tabledata "Printer Selection" = R,
                  tabledata "Purch. Cr. Memo Entity Buffer" = RIMD,
                  tabledata "Purch. Inv. Entity Aggregate" = RIMD,
                  tabledata "Purch. Inv. Line Aggregate" = RIMD,
                  tabledata "Purchase Order Entity Buffer" = RIMD,
                  tabledata "Purchases & Payables Setup" = Rim,
                  tabledata "Reclas. Dimension Set Buffer" = RIMD,
                  tabledata "Report List Translation" = RIMD,
                  tabledata "Resources Setup" = Rim,
                  tabledata "Restricted Record" = Rimd,
                  tabledata "Returns-Related Document" = Rimd,
                  tabledata "Sales & Receivables Setup" = Rim,
                  tabledata "Sales by Cust. Grp.Chart Setup" = Rim,
                  tabledata "Sales Cr. Memo Entity Buffer" = RIMD,
                  tabledata "Sales Invoice Entity Aggregate" = RIMD,
                  tabledata "Sales Invoice Line Aggregate" = RIMD,
                  tabledata "Sales Order Entity Buffer" = RIMD,
                  tabledata "Selected Dimension" = RIMD,
                  tabledata "Sent Notification Entry" = Rimd,
                  tabledata "Service Connection" = RIMD,
                  tabledata "Source Code" = R,
                  tabledata "Source Code Setup" = Rim,
                  tabledata "Standard Text" = R,
                  tabledata "Time Sheet Chart Setup" = Rim,
                  tabledata "To-do" = r,
                  tabledata "Top Customers By Sales Buffer" = RIMD,
                  tabledata "Trailing Sales Orders Setup" = RIm,
                  tabledata "Trial Balance Setup" = Rim,
                  tabledata "User Setup" = Rim,
                  tabledata "User Time Register" = rim,
                  tabledata "Value Entry Relation" = Rimd,
                  tabledata "VAT Assisted Setup Bus. Grp." = Rim,
                  tabledata "VAT Assisted Setup Templates" = Rim,
                  tabledata "VAT Posting Setup" = Rim,
                  tabledata "VAT Rate Change Setup" = Rim,
                  tabledata "VAT Report Setup" = Rim,
                  tabledata "VAT Reporting Code" = Rim,
                  tabledata "VAT Setup Posting Groups" = Rim,
                  tabledata "VAT Setup" = Rim,
                  tabledata "VAT Posting Parameters" = Rim,
                  tabledata "Warehouse Setup" = Rim,
                  tabledata "Where Used Base Calendar" = Rimd,
                  tabledata "Whse. Item Entry Relation" = Rimd,
                  tabledata "Whse. Item Tracking Line" = Rimd,
                  tabledata "Workflow - Record Change" = Rimd,
                  tabledata "Workflow - Table Relation" = R,
                  tabledata Workflow = R,
                  tabledata "Workflow Buffer" = RIMD,
                  tabledata "Workflow Category" = R,
                  tabledata "Workflow Event" = R,
                  tabledata "Workflow Event Queue" = Rimd,
                  tabledata "Workflow Record Change Archive" = Rimd,
                  tabledata "Workflow Response" = R,
                  tabledata "Workflow Rule" = Rimd,
                  tabledata "Workflow Step" = R,
                  tabledata "Workflow Step Argument" = Rimd,
                  tabledata "Workflow Step Argument Archive" = Rimd,
                  tabledata "Workflow Step Instance" = Rimd,
                  tabledata "Workflow Step Instance Archive" = Rimd,
                  tabledata "Workflow Table Relation Value" = Rimd,
                  tabledata "Workflow User Group" = R,
                  tabledata "Workflow User Group Member" = R;
}
