namespace System.Security.AccessControl;

using Microsoft.Finance.VAT.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.Analysis;
using Microsoft.Sales.Customer;
using Microsoft.Purchases.Vendor;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Check;
using Microsoft.Integration.D365Sales;
using Microsoft.Sales.Reminder;
using Microsoft.Sales.Receivables;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Inventory.Ledger;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.CRM.Interaction;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Document;
using System.Environment.Configuration;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Costing;
using Microsoft.Warehouse.History;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Pricing.Worksheet;
using Microsoft.Purchases.History;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Request;
using Microsoft.Foundation.BatchProcessing;
using Microsoft.Sales.Document;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.HumanResources.Employee;
using Microsoft.Finance.VAT.Reporting;

permissionset 9977 "D365 SALES DOC, POST"
{
    Access = Public;
    Assignable = true;
    Caption = 'Dynamics 365 Post sales doc.';

    IncludedPermissionSets = "D365 SALES DOC, EDIT";

    Permissions = tabledata "Analysis View" = rimd,
                  tabledata "Analysis View Entry" = rim,
                  tabledata "Analysis View Filter" = r,
                  tabledata "Alt. Customer Posting Group" = RM,
                  tabledata "Alt. Vendor Posting Group" = RM,
                  tabledata "Alt. Employee Posting Group" = RM,
                  tabledata "Avg. Cost Adjmt. Entry Point" = RIM,
                  tabledata "Bank Account Ledger Entry" = rim,
                  tabledata "Batch Processing Parameter" = Rimd,
                  tabledata "Batch Processing Session Map" = Rimd,
                  tabledata "Check Ledger Entry" = rim,
                  tabledata "CRM Post Buffer" = RIM,
                  tabledata "Currency for Reminder Level" = r,
                  tabledata "Customer Posting Group" = RM,
                  tabledata "Detailed Cust. Ledg. Entry" = Rimd,
                  tabledata "G/L Account" = RIM,
                  tabledata "G/L Account Source Currency" = RIM,
                  tabledata "G/L - Item Ledger Relation" = RIMD,
                  tabledata "G/L Entry - VAT Entry Link" = Ri,
                  tabledata "G/L Entry" = Rimd,
                  tabledata "G/L Register" = Rimd,
                  tabledata "Interaction Log Entry" = Rimd,
                  tabledata "Interaction Template" = R,
                  tabledata "Interaction Tmpl. Language" = R,
                  tabledata "Item Charge" = R,
                  tabledata "Item Charge Assignment (Purch)" = RIMD,
                  tabledata "Item Charge Assignment (Sales)" = RIMD,
                  tabledata "Item Entry Relation" = R,
                  tabledata "Item Ledger Entry" = Rimd,
                  tabledata "Item Register" = Rimd,
                  tabledata "Job Planning Line" = R,
                  tabledata "Jobs Setup" = R,
                  tabledata "Line Fee Note on Report Hist." = rim,
                  tabledata "Notification Entry" = RIMD,
                  tabledata "Order Promising Line" = RiMD,
                  tabledata "Post Value Entry to G/L" = i,
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
                  tabledata "Purch. Rcpt. Line" = i,
                  tabledata "Reminder Level" = r,
                  tabledata "Reservation Entry" = I,
                  tabledata "Sent Notification Entry" = RIMD,
                  tabledata "Stockkeeping Unit" = R,
                  tabledata "VAT Entry" = Rimd,
                  tabledata "VAT Business Posting Group" = RM,
                  tabledata "VAT Registration No. Format" = R,
                  tabledata "VAT Return Period" = R,
                  tabledata "VAT Setup" = R,
                  tabledata "Alt. Cust. VAT Reg." = R,
                  tabledata "VAT Posting Parameters" = R,
                  tabledata "Warehouse Request" = RIMD,
                  tabledata "Whse. Pick Request" = RIMD;
}
