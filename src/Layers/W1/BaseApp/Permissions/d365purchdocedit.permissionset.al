namespace System.Security.AccessControl;

using Microsoft.Assembly.Document;
using Microsoft.Bank.BankAccount;
using Microsoft.Foundation.Company;
using Microsoft.CRM.Contact;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CostAccounting.Account;
using Microsoft.Finance.Currency;
using Microsoft.Sales.Customer;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.HumanResources.Employee;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Tracking;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Vendor;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Inventory.Planning;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Archive;
using Microsoft.Purchases.Setup;
using Microsoft.Purchases.Remittance;
using Microsoft.Inventory.Requisition;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Ledger;
using Microsoft.Warehouse.Ledger;
using Microsoft.Utilities;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Projects.TimeSheet;
using Microsoft.Inventory.Intrastat;
using Microsoft.Foundation.Task;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.Reporting;
using System.Automation;
using System.Environment.Configuration;
using System.IO;
using System.Security.User;
using System.Threading;

permissionset 5807 "D365 PURCH DOC, EDIT"
{
    Assignable = true;
    Caption = 'Dyn. 365 Create purch. doc.';

    Permissions = tabledata "Approval Workflow Wizard" = RIMD,
                  tabledata "Assemble-to-Order Link" = R,
                  tabledata "Bank Account" = R,
                  tabledata "Cancelled Document" = Rimd,
                  tabledata "Company Information" = R,
                  tabledata Contact = RIMD,
                  tabledata "Contact Business Relation" = R,
                  tabledata "Cost Type" = RIMD,
                  tabledata Currency = RM,
                  tabledata "Customer Bank Account" = R,
                  tabledata "Detailed Employee Ledger Entry" = Rm,
                  tabledata "Detailed Vendor Ledg. Entry" = Rm,
                  tabledata Employee = R,
                  tabledata "Employee Ledger Entry" = Rm,
                  tabledata "G/L Account" = R,
                  tabledata "General Ledger Setup" = rm,
                  tabledata "Item Charge" = R,
                  tabledata "Item Entry Relation" = R,
                  tabledata "Item Reference" = R,
                  tabledata "Item Tracing Buffer" = Rimd,
                  tabledata "Item Tracing History Buffer" = Rimd,
                  tabledata "Item Tracking Code" = R,
                  tabledata "Job Queue Category" = RIMD,
                  tabledata "No. Series" = RIMD,
                  tabledata "Notification Entry" = RIMD,
                  tabledata "Order Address" = RIMD,
                  tabledata "Payment Terms" = RMD,
                  tabledata "Planning Component" = RIm,
                  tabledata "Purch. Cr. Memo Hdr." = R,
                  tabledata "Purch. Cr. Memo Line" = R,
                  tabledata "Purch. Inv. Header" = R,
                  tabledata "Purch. Inv. Line" = R,
                  tabledata "Purch. Rcpt. Header" = R,
                  tabledata "Purch. Rcpt. Line" = R,
                  tabledata "Purchase Header" = RIMD,
                  tabledata "Purchase Header Archive" = RIMD,
                  tabledata "Purchase Line" = RIMD,
                  tabledata "Purchase Line Archive" = RIMD,
                  tabledata "Purchases & Payables Setup" = R,
                  tabledata "Record Buffer" = Rimd,
                  tabledata "Remit Address" = RIMD,
                  tabledata "Requisition Line" = RIMD,
                  tabledata "Restricted Record" = RIMD,
                  tabledata "Return Reason" = R,
                  tabledata "Return Shipment Header" = R,
                  tabledata "Return Shipment Line" = R,
                  tabledata "Ship-to Address" = RIMD,
                  tabledata "Standard General Journal Line" = RIMD,
                  tabledata "Standard Purchase Code" = RIMD,
                  tabledata "Standard Purchase Line" = RIMD,
                  tabledata "Standard Vendor Purchase Code" = RIMD,
                  tabledata "Stockkeeping Unit" = R,
                  tabledata "Time Sheet Chart Setup" = RIMD,
                  tabledata "Time Sheet Comment Line" = RIMD,
                  tabledata "Time Sheet Detail" = RIMD,
                  tabledata "Time Sheet Header" = RIMD,
                  tabledata "Time Sheet Line" = RIMD,
                  tabledata "Time Sheet Posting Entry" = RIMD,
                  tabledata "Tracking Specification" = Rimd,
                  tabledata "Transaction Type" = R,
                  tabledata "Transport Method" = R,
                  tabledata "Unplanned Demand" = RIMD,
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
                  tabledata "VAT Reporting Code" = R,
                  tabledata Vendor = RM,
                  tabledata "Vendor Bank Account" = R,
                  tabledata "Vendor Invoice Disc." = R,
                  tabledata "Vendor Ledger Entry" = Rm,
                  tabledata "Whse. Item Entry Relation" = R,
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
