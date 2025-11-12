namespace System.Security.AccessControl;

using Microsoft.Inventory.BOM;
using Microsoft.Foundation.Comment;
using Microsoft.Finance.Dimension;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.HumanResources.Employee;
using Microsoft.Foundation.ExtendedText;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Intercompany.GLAccount;
using Microsoft.Foundation.Address;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Source;
using Microsoft.Pricing.Worksheet;
using Microsoft.Purchases.Document;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Projects.Resources.Pricing;
using Microsoft.Sales.History;
using Microsoft.Sales.Document;
using Microsoft.Finance.SalesTax;
using Microsoft.Purchases.Vendor;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.TimeSheet;
using Microsoft.Foundation.UOM;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.RateChange;

permissionset 6427 "Resources - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Edit resources/resourcegr.';

    Permissions = tabledata "BOM Component" = r,
                  tabledata "Comment Line" = RIMD,
                  tabledata "Default Dimension" = RIMD,
                  tabledata "Dtld. Price Calculation Setup" = RIMD,
                  tabledata "Duplicate Price Line" = RIMD,
                  tabledata Employee = rm,
                  tabledata "Extended Text Header" = RIMD,
                  tabledata "Extended Text Line" = RIMD,
                  tabledata "Gen. Product Posting Group" = R,
                  tabledata "IC G/L Account" = R,
                  tabledata Job = rm,
                  tabledata "Job Journal Line" = RM,
                  tabledata "Job Ledger Entry" = RM,
                  tabledata "Job Planning Line - Calendar" = RM,
                  tabledata "Job Planning Line" = RM,
                  tabledata "Post Code" = Ri,
                  tabledata "Price Asset" = RIMD,
                  tabledata "Price Calculation Buffer" = RIMD,
                  tabledata "Price Calculation Setup" = RIMD,
                  tabledata "Price Line Filters" = RIMD,
                  tabledata "Price List Header" = RIMD,
                  tabledata "Price List Line" = RIMD,
                  tabledata "Price Source" = RIMD,
                  tabledata "Price Worksheet Line" = RIMD,
                  tabledata "Purchase Line" = r,
                  tabledata "Res. Capacity Entry" = RmD,
                  tabledata "Res. Journal Line" = Rm,
                  tabledata "Res. Ledger Entry" = Rm,
                  tabledata Resource = RIMD,
                  tabledata "Resource Cost" = RIMD,
                  tabledata "Resource Group" = RIMD,
                  tabledata "Resource Price" = RIMD,
                  tabledata "Resource Unit of Measure" = RID,
                  tabledata "Return Receipt Line" = r,
                  tabledata "Sales Cr.Memo Line" = r,
                  tabledata "Sales Invoice Line" = rm,
                  tabledata "Sales Line" = R,
                  tabledata "Sales Shipment Line" = rm,
                  tabledata "Standard Purchase Line" = r,
                  tabledata "Standard Sales Line" = r,
                  tabledata "Tax Group" = R,
                  tabledata "Time Sheet Chart Setup" = R,
                  tabledata "Time Sheet Header" = R,
                  tabledata "Time Sheet Line" = R,
                  tabledata "Time Sheet Posting Entry" = R,
                  tabledata "Unit of Measure" = R,
                  tabledata "VAT Product Posting Group" = R,
                  tabledata "VAT Rate Change Conversion" = R,
                  tabledata Vendor = R,
                  tabledata "Vendor Bank Account" = R;
}
