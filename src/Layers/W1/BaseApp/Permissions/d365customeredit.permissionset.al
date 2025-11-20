namespace System.Security.AccessControl;

using Microsoft.Bank.Ledger;
using Microsoft.Warehouse.Structure;
using Microsoft.Bank.Check;
using Microsoft.CRM.Duplicates;
using Microsoft.CRM.Contact;
using Microsoft.CRM.BusinessRelation;
using Microsoft.CRM.Profiling;
using Microsoft.Finance.Currency;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.HumanResources.Payables;
using Microsoft.Sales.FinanceCharge;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.CRM.Interaction;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Sales.Reminder;
using Microsoft.CRM.Opportunity;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Source;
using Microsoft.Pricing.Worksheet;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Archive;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Sales.History;
using Microsoft.CRM.Comment;
using Microsoft.Sales.Archive;
using Microsoft.Sales.Pricing;
using Microsoft.Sales.Document;
using Microsoft.CRM.Task;
using Microsoft.Purchases.Payables;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Worksheet;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Registration;

permissionset 5729 "D365 CUSTOMER, EDIT"
{
    Assignable = true;
    Caption = 'Dynamics 365 Create customers';

    IncludedPermissionSets = "D365 CUSTOMER, VIEW";

    Permissions = tabledata "Bank Account Ledger Entry" = rm,
                  tabledata Bin = R,
                  tabledata "Check Ledger Entry" = r,
                  tabledata "Cont. Duplicate Search String" = RIMD,
                  tabledata Contact = RIMD,
                  tabledata "Contact Business Relation" = RImD,
                  tabledata "Contact Duplicate" = R,
                  tabledata "Contact Industry Group" = Rd,
                  tabledata "Contact Job Responsibility" = Rd,
                  tabledata "Contact Mailing Group" = Rd,
                  tabledata "Contact Profile Answer" = d,
                  tabledata "Contact Web Source" = Rd,
                  tabledata Currency = RM,
                  tabledata "Cust. Invoice Disc." = IMD,
                  tabledata "Cust. Ledger Entry" = M,
                  tabledata Customer = RIMD,
                  tabledata "Customer Bank Account" = IMD,
                  tabledata "Customer Discount Group" = RIMD,
                  tabledata "Customer Templ." = rm,
                  tabledata "Detailed Cust. Ledg. Entry" = Rimd,
                  tabledata "Dtld. Price Calculation Setup" = Rid,
                  tabledata "Duplicate Price Line" = Rid,
                  tabledata "Duplicate Search String Setup" = R,
                  tabledata "Employee Ledger Entry" = rm,
                  tabledata "Finance Charge Text" = R,
                  tabledata "G/L Entry - VAT Entry Link" = rm,
                  tabledata "G/L Entry" = rm,
                  tabledata "Interaction Log Entry" = Rm,
                  tabledata "Item Analysis View Budg. Entry" = r,
                  tabledata "Item Analysis View Entry" = rid,
                  tabledata "Item Budget Entry" = r,
                  tabledata "Item Reference" = IMD,
                  tabledata "Line Fee Note on Report Hist." = R,
                  tabledata Opportunity = Rm,
                  tabledata "Opportunity Entry" = Rm,
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
                  tabledata "Purchase Header Archive" = r,
                  tabledata "Registered Whse. Activity Line" = rm,
                  tabledata "Reminder Level" = R,
                  tabledata "Reminder Text" = R,
                  tabledata "Res. Journal Line" = r,
                  tabledata "Return Receipt Header" = rm,
                  tabledata "Return Receipt Line" = rm,
                  tabledata "Return Shipment Header" = rm,
                  tabledata "Return Shipment Line" = rm,
                  tabledata "Rlshp. Mgt. Comment Line" = rD,
                  tabledata "Sales Cr.Memo Header" = rm,
                  tabledata "Sales Cr.Memo Line" = rm,
                  tabledata "Sales Discount Access" = Rd,
                  tabledata "Sales Header Archive" = rm,
                  tabledata "Sales Invoice Line" = rm,
                  tabledata "Sales Line Discount" = Rd,
                  tabledata "Sales Price" = Rid,
                  tabledata "Sales Price Access" = Rid,
                  tabledata "Sales Shipment Header" = rm,
                  tabledata "Sales Shipment Line" = Rm,
                  tabledata "Ship-to Address" = RIMD,
                  tabledata "Standard Customer Sales Code" = RIMD,
                  tabledata "Standard Sales Code" = RIMD,
                  tabledata "Standard Sales Line" = RIMD,
                  tabledata "To-do" = Rm,
                  tabledata "VAT Entry" = Rm,
                  tabledata "VAT Reg. No. Srv Config" = RIMD,
                  tabledata "VAT Reg. No. Srv. Template" = RIMD,
                  tabledata "VAT Registration Log Details" = RIMD,
                  tabledata "VAT Registration No. Format" = IMD,
                  tabledata "Vendor Ledger Entry" = rm,
                  tabledata "Warehouse Activity Header" = rm,
                  tabledata "Warehouse Activity Line" = rm,
                  tabledata "Warehouse Reason Code" = RM,
                  tabledata "Warehouse Request" = rm,
                  tabledata "Warehouse Shipment Line" = rm,
                  tabledata "Whse. Worksheet Line" = r;
}
