namespace System.Security.AccessControl;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.MarketingText;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Structure;

permissionset 9346 "Inventory - View"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read items/BOMs/SKUs/entries';

    Permissions = tabledata Bin = R,
                  tabledata "BOM Component" = R,
                  tabledata "Comment Line" = R,
                  tabledata "Default Dimension" = R,
                  tabledata "Extended Text Header" = R,
                  tabledata "Extended Text Line" = R,
                  tabledata Item = R,
                  tabledata "Item Application Entry" = R,
                  tabledata "Item Ledger Entry" = R,
                  tabledata "Item Reference" = R,
                  tabledata "Item Substitution" = R,
                  tabledata "Item Tracking Code" = R,
                  tabledata "Item Unit of Measure" = R,
                  tabledata "Item Variant" = R,
                  tabledata Location = R,
                  tabledata "Lot No. Information" = R,
                  tabledata "Marketing Text Attributes" = R,
                  tabledata "Nonstock Item" = R,
                  tabledata "Package No. Information" = R,
                  tabledata "Planning Component" = Rm,
                  tabledata "Serial No. Information" = R,
                  tabledata "Stockkeeping Unit" = R,
                  tabledata "Stockkeeping Unit Comment Line" = R,
                  tabledata "Substitution Condition" = R,
                  tabledata "Unit of Measure" = R,
                  tabledata "Value Entry" = R,
                  tabledata "VAT Rate Change Log Entry" = Ri;
}
