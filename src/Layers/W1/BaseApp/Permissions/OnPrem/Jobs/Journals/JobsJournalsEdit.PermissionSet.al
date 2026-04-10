namespace System.Security.AccessControl;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.RateChange;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Comment;
using Microsoft.Foundation.Period;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Intrastat;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Pricing.Worksheet;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.Pricing;
using Microsoft.Projects.Project.WIP;
using Microsoft.Projects.Resources.Pricing;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.TimeSheet;
using Microsoft.Sales.Pricing;
using Microsoft.Utilities;
using Microsoft.Warehouse.Structure;

permissionset 7787 "Jobs Journals - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Create entries in project journals';

    Permissions = tabledata "Accounting Period" = R,
                  tabledata Bin = R,
                  tabledata "Comment Line" = R,
                  tabledata "Country/Region" = R,
                  tabledata "Customer Price Group" = R,
                  tabledata "Default Dimension" = R,
                  tabledata "Default Dimension Priority" = R,
                  tabledata "Dtld. Price Calculation Setup" = R,
                  tabledata "Duplicate Price Line" = R,
                  tabledata "G/L Account" = R,
                  tabledata "Gen. Business Posting Group" = R,
                  tabledata "Gen. Product Posting Group" = R,
                  tabledata "General Ledger Setup" = R,
                  tabledata "General Posting Setup" = R,
                  tabledata Item = R,
                  tabledata "Item Ledger Entry" = R,
                  tabledata "Item Unit of Measure" = R,
                  tabledata "Item Variant" = R,
                  tabledata Job = R,
                  tabledata "Job G/L Account Price" = R,
                  tabledata "Job Item Price" = R,
                  tabledata "Job Journal Batch" = RI,
                  tabledata "Job Journal Line" = RIMD,
                  tabledata "Job Journal Quantity" = RIMD,
                  tabledata "Job Journal Template" = RI,
                  tabledata "Job Ledger Entry" = R,
                  tabledata "Job Planning Line - Calendar" = R,
                  tabledata "Job Planning Line" = R,
                  tabledata "Job Resource Price" = R,
                  tabledata "Job Task" = R,
                  tabledata "Job WIP Entry" = R,
                  tabledata "Job WIP G/L Entry" = R,
                  tabledata Location = R,
                  tabledata "Price Asset" = R,
                  tabledata "Price Calculation Buffer" = R,
                  tabledata "Price Calculation Setup" = R,
                  tabledata "Price Line Filters" = R,
                  tabledata "Price List Header" = R,
                  tabledata "Price List Line" = R,
                  tabledata "Price Source" = R,
                  tabledata "Price Worksheet Line" = R,
                  tabledata "Reason Code" = R,
                  tabledata Resource = R,
                  tabledata "Resource Cost" = R,
                  tabledata "Resource Group" = R,
                  tabledata "Resource Price" = R,
                  tabledata "Resource Unit of Measure" = R,
                  tabledata "Sales Price" = R,
                  tabledata "Sales Price Access" = R,
                  tabledata "Source Code Setup" = R,
                  tabledata "Time Sheet Chart Setup" = R,
                  tabledata "Time Sheet Detail" = R,
                  tabledata "Time Sheet Header" = R,
                  tabledata "Time Sheet Line" = R,
                  tabledata "Time Sheet Posting Entry" = R,
                  tabledata "Transaction Type" = R,
                  tabledata "Transport Method" = R,
                  tabledata "Unit of Measure" = R,
                  tabledata "Value Entry" = R,
                  tabledata "VAT Rate Change Log Entry" = Ri,
                  tabledata "VAT Setup" = RM,
                  tabledata "Work Type" = R;
}
