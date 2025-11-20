namespace System.Security.AccessControl;

using Microsoft.Projects.TimeSheet;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.Task;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.RateChange;
using System.Automation;
using Microsoft.Assembly.Document;
using Microsoft.Bank.BankAccount;
using Microsoft.Warehouse.Structure;
using Microsoft.CRM.Opportunity;
using Microsoft.Foundation.Company;
using Microsoft.CRM.Contact;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Duplicates;
using Microsoft.CostAccounting.Account;
using Microsoft.Finance.Currency;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.HumanResources.Employee;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Tracking;
using System.Threading;
using Microsoft.Foundation.NoSeries;
using System.Environment.Configuration;
using Microsoft.Purchases.Vendor;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Inventory.Planning;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Source;
using Microsoft.Pricing.Worksheet;
using Microsoft.Purchases.Remittance;
using Microsoft.Projects.Resources.Pricing;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.History;
using Microsoft.Sales.Document;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Setup;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Finance.SalesTax;
using Microsoft.CRM.Task;
using System.Security.User;
using Microsoft.Inventory.Ledger;
using Microsoft.Warehouse.Ledger;
using Microsoft.Utilities;
using Microsoft.Inventory.Intrastat;
using System.IO;

permissionset 9783 "D365 SALES DOC, EDIT"
{
    Access = Public;
    Assignable = true;
    Caption = 'Dynamics 365 Create sales doc.';

    IncludedPermissionSets = "Webhook - Edit";

    Permissions = tabledata "Approval Workflow Wizard" = RIMD,
                  tabledata "Assemble-to-Order Link" = R,
                  tabledata "Bank Account" = RM,
                  tabledata Bin = R,
                  tabledata "Cancelled Document" = Rimd,
                  tabledata "Close Opportunity Code" = R,
                  tabledata "Company Information" = R,
                  tabledata Contact = RIMD,
                  tabledata "Contact Business Relation" = RIMD,
                  tabledata "Contact Duplicate" = RD,
                  tabledata "Cont. Duplicate Search String" = RID,
                  tabledata "Cost Type" = RIMD,
                  tabledata Currency = RM,
                  tabledata "Cust. Invoice Disc." = RIMD,
                  tabledata "Cust. Ledger Entry" = RiMd,
                  tabledata Customer = RIM,
                  tabledata "Customer Bank Account" = RM,
                  tabledata "Dtld. Price Calculation Setup" = RIMD,
                  tabledata "Duplicate Price Line" = RIMD,
                  tabledata "Duplicate Search String Setup" = R,
                  tabledata Employee = R,
                  tabledata "G/L Account" = R,
                  tabledata "General Ledger Setup" = R,
                  tabledata "Item Charge" = R,
                  tabledata "Item Charge Assignment (Purch)" = RIMD,
                  tabledata "Item Charge Assignment (Sales)" = RIMD,
                  tabledata "Item Entry Relation" = R,
                  tabledata "Item Reference" = RIMD,
                  tabledata "Item Tracing Buffer" = Rimd,
                  tabledata "Item Tracing History Buffer" = Rimd,
                  tabledata "Item Tracking Code" = R,
                  tabledata "Job Queue Category" = RIMD,
                  tabledata "Lot No. Information" = RIMD,
                  tabledata "No. Series" = RIMD,
                  tabledata "No. Series Line" = RIMD,
                  tabledata "Notification Entry" = RIMD,
                  tabledata Opportunity = R,
                  tabledata "Opportunity Entry" = RIM,
                  tabledata "Order Address" = RIMD,
                  tabledata "Package No. Information" = RIMD,
                  tabledata "Payment Terms" = RMD,
                  tabledata "Planning Assignment" = Ri,
                  tabledata "Planning Component" = Rm,
                  tabledata "Price Asset" = RIMD,
                  tabledata "Price Calculation Buffer" = RIMD,
                  tabledata "Price Calculation Setup" = RIMD,
                  tabledata "Price Line Filters" = RIMD,
                  tabledata "Price List Header" = RIMD,
                  tabledata "Price List Line" = RIMD,
                  tabledata "Price Source" = RIMD,
                  tabledata "Price Worksheet Line" = RIMD,
                  tabledata "Record Buffer" = Rimd,
                  tabledata "Remit Address" = RIMD,
                  tabledata "Resource Cost" = R,
                  tabledata "Resource Price" = R,
                  tabledata "Resource Unit of Measure" = R,
                  tabledata "Restricted Record" = RIMD,
                  tabledata "Return Reason" = R,
                  tabledata "Return Receipt Header" = Rim,
                  tabledata "Return Receipt Line" = Rim,
                  tabledata "Sales Cr.Memo Header" = RimD,
                  tabledata "Sales Cr.Memo Line" = Rimd,
                  tabledata "Sales Discount Access" = RIMD,
                  tabledata "Sales Header" = RIMD,
                  tabledata "Sales Header Archive" = RIMD,
                  tabledata "Sales Invoice Header" = RimD,
                  tabledata "Sales Invoice Line" = Rimd,
                  tabledata "Sales Line" = RIMD,
                  tabledata "Sales Line Archive" = RIMD,
                  tabledata "Sales Line Discount" = RIMD,
                  tabledata "Sales Planning Line" = Rimd,
                  tabledata "Sales Price" = RIMD,
                  tabledata "Sales Price Access" = RIMD,
                  tabledata "Sales Price Worksheet" = RIMD,
                  tabledata "Sales Shipment Header" = RimD,
                  tabledata "Sales Shipment Line" = Rimd,
                  tabledata "Sales & Receivables Setup" = R,
                  tabledata "Serial No. Information" = RIMD,
                  tabledata "Ship-to Address" = RIMD,
                  tabledata "Shipping Agent Services" = R,
                  tabledata "Standard Customer Sales Code" = RIMD,
                  tabledata "Standard General Journal Line" = RIMD,
                  tabledata "Standard Sales Code" = RIMD,
                  tabledata "Standard Sales Line" = RIMD,
                  tabledata "Stockkeeping Unit" = R,
                  tabledata "Substitution Condition" = R,
                  tabledata "Tax Detail" = RIMD,
                  tabledata "Time Sheet Chart Setup" = RIMD,
                  tabledata "Time Sheet Comment Line" = RIMD,
                  tabledata "Time Sheet Detail" = RIMD,
                  tabledata "Time Sheet Header" = RIMD,
                  tabledata "Time Sheet Line" = RIMD,
                  tabledata "Time Sheet Posting Entry" = RIMD,
                  tabledata "To-do" = RM,
                  tabledata "Tracking Specification" = Rimd,
                  tabledata "Transaction Type" = R,
                  tabledata "Transport Method" = R,
                  tabledata "User Preference" = RIMD,
                  tabledata "User Setup" = R,
                  tabledata "User Task Group" = RIMD,
                  tabledata "User Task Group Member" = RIMD,
                  tabledata "Value Entry Relation" = R,
                  tabledata "VAT Amount Line" = RIMD,
                  tabledata "VAT Rate Change Conversion" = R,
                  tabledata "VAT Rate Change Log Entry" = Ri,
                  tabledata "VAT Rate Change Setup" = R,
                  tabledata "VAT Setup" = R,
                  tabledata "VAT Posting Parameters" = R,
                  tabledata "Whse. Item Entry Relation" = R,
                  tabledata "Work Type" = R,
                  tabledata "Workflow - Table Relation" = RIMD,
                  tabledata Workflow = RIMD,
                  tabledata "Workflow Event" = RIMD,
                  tabledata "Workflow Event Queue" = RIMD,
                  tabledata "Workflow Response" = RIMD,
                  tabledata "Workflow Rule" = RIMD,
                  tabledata "Workflow Step" = RIMD,
                  tabledata "Workflow Step Argument" = RIMD,
                  tabledata "Workflow Step Instance" = RIMD,
                  tabledata "Workflow Table Relation Value" = RIMD,
                  tabledata "Workflow User Group" = RIMD,
                  tabledata "Workflow User Group Member" = RIMD;
}
