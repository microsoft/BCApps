namespace System.Security.AccessControl;

using Microsoft.Assembly.Document;
using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Foundation.Period;
using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Pricing.Worksheet;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Pricing;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Pricing;
using Microsoft.Warehouse.ADCS;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;

permissionset 5947 "D365 ITEM, EDIT"
{
    Assignable = true;
    Caption = 'Dynamics 365 Create items';

    Permissions = tabledata "Accounting Period" = R,
                  tabledata "Avg. Cost Adjmt. Entry Point" = rimd,
                  tabledata "Assembly Header" = R,
                  tabledata "Assembly Line" = R,
                  tabledata "Bin Content" = Rd,
                  tabledata Currency = RM,
                  tabledata "Default Dimension" = RIMD,
                  tabledata "Dtld. Price Calculation Setup" = RIMD,
                  tabledata "Duplicate Price Line" = RIMD,
                  tabledata Item = RIMD,
                  tabledata "Item Analysis View" = RIMD,
                  tabledata "Item Analysis View Budg. Entry" = RIMD,
                  tabledata "Item Analysis View Entry" = RIMD,
                  tabledata "Item Analysis View Filter" = RIMD,
                  tabledata "Item Attribute Value Mapping" = RIMD,
                  tabledata "Item Budget Entry" = RIMD,
                  tabledata "Item Budget Name" = RIMD,
                  tabledata "Item Category" = R,
                  tabledata "Item Charge Assignment (Purch)" = r,
                  tabledata "Item Charge Assignment (Sales)" = r,
                  tabledata "Item Discount Group" = RIMD,
                  tabledata "Item Identifier" = RIMD,
                  tabledata "Item Journal Line" = RIMD,
                  tabledata "Item Reference" = RIMD,
                  tabledata "Item Translation" = RIMD,
                  tabledata "Item Vendor" = RIMD,
                  tabledata "Inventory Adjmt. Entry (Order)" = Rimd,
                  tabledata "Job Planning Line" = R,
                  tabledata "My Item" = RIMD,
                  tabledata "Nonstock Item" = RIMD,
                  tabledata "Planning Assignment" = Rd,
                  tabledata "Price Asset" = RIMD,
                  tabledata "Price Calculation Buffer" = RIMD,
                  tabledata "Price Calculation Setup" = RIMD,
                  tabledata "Price Line Filters" = RIMD,
                  tabledata "Price List Header" = RIMD,
                  tabledata "Price List Line" = RIMD,
                  tabledata "Price Source" = RIMD,
                  tabledata "Price Worksheet Line" = RIMD,
                  tabledata "Purch. Cr. Memo Line" = r,
                  tabledata "Purch. Inv. Line" = r,
                  tabledata "Purch. Rcpt. Line" = r,
                  tabledata "Purchase Discount Access" = RIMD,
                  tabledata "Purchase Line Discount" = RIMD,
                  tabledata "Purchase Price" = RIMD,
                  tabledata "Purchase Price Access" = RIMD,
                  tabledata "Return Receipt Line" = r,
                  tabledata "Return Shipment Line" = r,
                  tabledata "Sales Cr.Memo Line" = r,
                  tabledata "Sales Discount Access" = RimD,
                  tabledata "Sales Invoice Line" = r,
                  tabledata "Sales Line Discount" = RimD,
                  tabledata "Sales Price" = RIMD,
                  tabledata "Sales Price Access" = RIMD,
                  tabledata "Sales Shipment Line" = r,
                  tabledata "Special Equipment" = R,
                  tabledata "Standard Item Journal" = RIMD,
                  tabledata "Standard Item Journal Line" = RIMD,
                  tabledata "Standard Purchase Line" = rm,
                  tabledata "Stockkeeping Unit" = RIMD,
                  tabledata "Stockkeeping Unit Comment Line" = RIMD,
                  tabledata "Substitution Condition" = RIMD,
                  tabledata "Tariff Number" = R,
                  tabledata "Tracking Specification" = Rimd,
                  tabledata "Transfer Line" = R,
                  tabledata "VAT Rate Change Conversion" = R,
                  tabledata "VAT Rate Change Log Entry" = Ri,
                  tabledata "VAT Rate Change Setup" = R,
                  tabledata "Vendor Bank Account" = R,
                  tabledata "Warehouse Entry" = Rm;
}
