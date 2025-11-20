namespace System.Security.AccessControl;

using Microsoft.Warehouse.Structure;
using Microsoft.Sales.Customer;
using Microsoft.Finance.Dimension;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Inventory.Tracking;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Location;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Source;
using Microsoft.Pricing.Worksheet;
using Microsoft.Purchases.Pricing;
using Microsoft.Purchases.Document;
using Microsoft.Inventory.Requisition;
using Microsoft.Sales.Document;
using System.Security.User;
using Microsoft.Purchases.Vendor;
using Microsoft.Foundation.AuditCodes;

permissionset 552 "Payables Req Worksheet - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Create entries on req. wksh.';

    Permissions = tabledata Bin = R,
                  tabledata Customer = R,
                  tabledata "Customer Bank Account" = R,
                  tabledata "Default Dimension" = R,
                  tabledata "Default Dimension Priority" = R,
                  tabledata "Dtld. Price Calculation Setup" = R,
                  tabledata "Duplicate Price Line" = R,
                  tabledata "Entry Summary" = RIMD,
                  tabledata "G/L Account" = R,
                  tabledata Item = R,
                  tabledata "Item Journal Line" = Rm,
                  tabledata "Item Ledger Entry" = Rm,
                  tabledata "Item Translation" = R,
                  tabledata "Item Variant" = R,
                  tabledata "Item Vendor" = R,
                  tabledata Location = R,
                  tabledata "Price Asset" = R,
                  tabledata "Price Calculation Buffer" = R,
                  tabledata "Price Calculation Setup" = R,
                  tabledata "Price Line Filters" = R,
                  tabledata "Price List Header" = R,
                  tabledata "Price List Line" = R,
                  tabledata "Price Source" = R,
                  tabledata "Price Worksheet Line" = R,
                  tabledata "Purchase Discount Access" = R,
                  tabledata "Purchase Line" = Rm,
                  tabledata "Purchase Line Discount" = R,
                  tabledata "Purchase Price" = R,
                  tabledata "Purchase Price Access" = R,
                  tabledata "Reason Code" = R,
                  tabledata "Req. Wksh. Template" = RI,
                  tabledata "Requisition Line" = RIMD,
                  tabledata "Requisition Wksh. Name" = RI,
                  tabledata "Reservation Entry" = Rimd,
                  tabledata "Sales Header" = R,
                  tabledata "Sales Line" = Rm,
                  tabledata "Ship-to Address" = R,
                  tabledata "Tracking Specification" = Rimd,
                  tabledata "User Setup" = R,
                  tabledata "Value Entry" = Rm,
                  tabledata Vendor = R,
                  tabledata "Vendor Bank Account" = R;
}
