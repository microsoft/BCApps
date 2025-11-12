namespace System.Security.AccessControl;

using Microsoft.Inventory.Analysis;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Purchases.History;
using Microsoft.Sales.History;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Inventory.Costing;
using Microsoft.Projects.Project.Planning;
using Microsoft.Inventory.Intrastat;
using Microsoft.Finance.VAT.RateChange;

permissionset 8707 "D365 ITEM, VIEW"
{
    Assignable = true;

    Caption = 'Dynamics 365 View items';
    Permissions = tabledata "Avg. Cost Adjmt. Entry Point" = r,
                  tabledata "Item Analysis View" = R,
                  tabledata "Item Analysis View Budg. Entry" = R,
                  tabledata "Item Analysis View Entry" = R,
                  tabledata "Item Analysis View Filter" = R,
                  tabledata "Item Budget Entry" = R,
                  tabledata "Item Budget Name" = R,
                  tabledata "Item Category" = R,
                  tabledata "Item Reference" = R,
                  tabledata "Job Planning Line" = r,
                  tabledata "Purch. Cr. Memo Line" = r,
                  tabledata "Purch. Inv. Line" = r,
                  tabledata "Purch. Rcpt. Line" = r,
                  tabledata "Return Receipt Line" = r,
                  tabledata "Return Shipment Line" = r,
                  tabledata "Sales Cr.Memo Line" = r,
                  tabledata "Sales Invoice Line" = r,
                  tabledata "Sales Shipment Line" = r,
                  tabledata "Standard Purchase Line" = rm,
                  tabledata "Tariff Number" = R,
                  tabledata "VAT Rate Change Conversion" = R,
                  tabledata "VAT Rate Change Log Entry" = R,
                  tabledata "VAT Rate Change Setup" = R,
                  tabledata "Vendor Bank Account" = R;
}
