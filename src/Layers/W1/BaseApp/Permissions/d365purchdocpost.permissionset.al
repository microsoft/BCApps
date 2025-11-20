namespace System.Security.AccessControl;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Ledger;
using Microsoft.Bank.Check;
using Microsoft.HumanResources.Payables;
using Microsoft.Purchases.Payables;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.FixedAssets.Setup;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.VAT.Reporting;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.CRM.Interaction;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Costing;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Source;
using Microsoft.Pricing.Worksheet;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Pricing;
using Microsoft.Inventory.Tracking;
using Microsoft.Sales.History;
using System.Environment.Configuration;
using Microsoft.Warehouse.Request;
using Microsoft.Foundation.BatchProcessing;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Projects.Project.Setup;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.Calculation;

permissionset 2909 "D365 PURCH DOC, POST"
{
    Assignable = true;
    Caption = 'Dyn. 365 Post purchase doc.';

    IncludedPermissionSets = "D365 PURCH DOC, EDIT";

    Permissions = tabledata "Avg. Cost Adjmt. Entry Point" = RIM,
                  tabledata "Bank Account" = m,
                  tabledata "Bank Account Ledger Entry" = rim,
                  tabledata "Batch Processing Parameter" = Rimd,
                  tabledata "Batch Processing Session Map" = Rimd,
                  tabledata "Check Ledger Entry" = rim,
                  tabledata "Detailed Employee Ledger Entry" = i,
                  tabledata "Detailed Vendor Ledg. Entry" = i,
                  tabledata "Dtld. Price Calculation Setup" = RIMD,
                  tabledata "Duplicate Price Line" = RIMD,
                  tabledata "Employee Ledger Entry" = imd,
                  tabledata "FA Setup" = R,
                  tabledata "G/L Account" = RIM,
                  tabledata "G/L Account Source Currency" = RIM,
                  tabledata "G/L Entry - VAT Entry Link" = Ri,
                  tabledata "G/L Entry" = Rimd,
                  tabledata "G/L Register" = Rimd,
                  tabledata "Interaction Template" = R,
                  tabledata "Interaction Tmpl. Language" = R,
                  tabledata "Interaction Log Entry" = Rimd,
                  tabledata "Item Charge" = R,
                  tabledata "Item Entry Relation" = R,
                  tabledata "Item Ledger Entry" = Rimd,
                  tabledata "Item Register" = Rimd,
                  tabledata "Jobs Setup" = R,
                  tabledata "No. Series Line" = RIMD,
                  tabledata "Post Value Entry to G/L" = I,
                  tabledata "Price Asset" = RIMD,
                  tabledata "Price Calculation Buffer" = RIMD,
                  tabledata "Price Calculation Setup" = RIMD,
                  tabledata "Price Line Filters" = RIMD,
                  tabledata "Price List Header" = RIMD,
                  tabledata "Price List Line" = RIMD,
                  tabledata "Price Source" = RIMD,
                  tabledata "Price Worksheet Line" = RIMD,
                  tabledata "Purch. Cr. Memo Hdr." = imD,
                  tabledata "Purch. Cr. Memo Line" = imd,
                  tabledata "Purch. Inv. Header" = imD,
                  tabledata "Purch. Inv. Line" = imd,
                  tabledata "Purch. Rcpt. Header" = imD,
                  tabledata "Purch. Rcpt. Line" = imd,
                  tabledata "Purchase Discount Access" = RIMD,
                  tabledata "Purchase Line Discount" = RIMD,
                  tabledata "Purchase Price" = RIMD,
                  tabledata "Purchase Price Access" = RIMD,
                  tabledata "Reservation Entry" = I,
                  tabledata "Return Shipment Header" = im,
                  tabledata "Return Shipment Line" = im,
                  tabledata "Sales Shipment Header" = i,
                  tabledata "Sales Shipment Line" = Ri,
                  tabledata "Sent Notification Entry" = RIMD,
                  tabledata "VAT Entry" = Rimd,
                  tabledata "VAT Registration No. Format" = R,
                  tabledata "VAT Return Period" = R,
                  tabledata "VAT Setup" = R,
                  tabledata "VAT Posting Parameters" = R,
                  tabledata "Vendor Ledger Entry" = iMd,
                  tabledata "Warehouse Request" = RIMD,
                  tabledata "Whse. Put-away Request" = RIMD;
}
