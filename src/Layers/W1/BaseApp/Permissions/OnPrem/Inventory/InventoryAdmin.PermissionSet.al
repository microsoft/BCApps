namespace System.Security.AccessControl;

using Microsoft.Warehouse.Structure;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Availability;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Source;
using Microsoft.Pricing.Worksheet;
using Microsoft.Purchases.Pricing;
using Microsoft.Sales.Pricing;
using Microsoft.Inventory.Transfer;
using Microsoft.Warehouse.Setup;
using Microsoft.Foundation.Calendar;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Utilities;
using Microsoft.Foundation.Shipping;
using Microsoft.Inventory.Intrastat;
using Microsoft.Foundation.UOM;
using Microsoft.Finance.VAT.RateChange;

permissionset 2928 "Inventory - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'Inventory setup';

    Permissions = tabledata "Base Calendar" = RIMD,
                  tabledata "Base Calendar Change" = RIMD,
                  tabledata Bin = RIMD,
                  tabledata "Customer Price Group" = RIMD,
                  tabledata "Customized Calendar Change" = RIMD,
                  tabledata "Customized Calendar Entry" = RIMD,
                  tabledata "Dtld. Price Calculation Setup" = RIMD,
                  tabledata "Duplicate Price Line" = RIMD,
                  tabledata "G/L Account" = R,
                  tabledata "Inventory Posting Group" = RIMD,
                  tabledata "Inventory Posting Setup" = RIMD,
                  tabledata "Inventory Setup" = RIMD,
                  tabledata "Item Category" = RIMD,
                  tabledata "Item Journal Batch" = RIMD,
                  tabledata "Item Journal Line" = MD,
                  tabledata "Item Journal Template" = RIMD,
                  tabledata "Item Tracking Code" = RIMD,
                  tabledata Location = RIMD,
                  tabledata Manufacturer = RIMD,
                  tabledata "Nonstock Item Setup" = RIMD,
                  tabledata "Order Promising Setup" = RIMD,
                  tabledata "Price Asset" = RIMD,
                  tabledata "Price Calculation Buffer" = RIMD,
                  tabledata "Price Calculation Setup" = RIMD,
                  tabledata "Price Line Filters" = RIMD,
                  tabledata "Price List Header" = RIMD,
                  tabledata "Price List Line" = RIMD,
                  tabledata "Price Source" = RIMD,
                  tabledata "Price Worksheet Line" = RIMD,
                  tabledata "Purchase Discount Access" = RIMD,
                  tabledata "Purchase Line Discount" = RIMD,
                  tabledata "Purchase Price" = RIMD,
                  tabledata "Purchase Price Access" = RIMD,
                  tabledata Purchasing = RIMD,
                  tabledata "Reason Code" = R,
                  tabledata "Rounding Method" = RIMD,
                  tabledata "Sales Discount Access" = RIMD,
                  tabledata "Sales Line Discount" = RIMD,
                  tabledata "Shipping Agent" = RIMD,
                  tabledata "Shipping Agent Services" = RIMD,
                  tabledata "Source Code" = R,
                  tabledata "Source Code Setup" = R,
                  tabledata "Tariff Number" = RIMD,
                  tabledata "Transfer Route" = RIMD,
                  tabledata "Unit of Measure" = RIMD,
                  tabledata "Unit of Measure Translation" = RIMD,
                  tabledata "VAT Rate Change Log Entry" = Ri,
                  tabledata "Warehouse Class" = RIMD;
}
