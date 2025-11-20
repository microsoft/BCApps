namespace System.Security.AccessControl;

using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Source;
using Microsoft.Pricing.Worksheet;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.Resources.Pricing;
using Microsoft.Projects.Resources.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Projects.TimeSheet;
using Microsoft.Foundation.UOM;
using Microsoft.Utilities;

permissionset 4969 "Resources - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'Resource setup';

    Permissions = tabledata "Dtld. Price Calculation Setup" = RIMD,
                  tabledata "Duplicate Price Line" = RIMD,
                  tabledata "Price Asset" = RIMD,
                  tabledata "Price Calculation Buffer" = RIMD,
                  tabledata "Price Calculation Setup" = RIMD,
                  tabledata "Price Line Filters" = RIMD,
                  tabledata "Price List Header" = RIMD,
                  tabledata "Price List Line" = RIMD,
                  tabledata "Price Source" = RIMD,
                  tabledata "Price Worksheet Line" = RIMD,
                  tabledata "Reason Code" = R,
                  tabledata "Res. Journal Batch" = RIMD,
                  tabledata "Res. Journal Template" = RIMD,
                  tabledata "Resource Cost" = RIMD,
                  tabledata "Resource Price" = RIMD,
                  tabledata "Resources Setup" = RIMD,
                  tabledata "Source Code" = R,
                  tabledata "Source Code Setup" = R,
                  tabledata "Time Sheet Chart Setup" = R,
                  tabledata "Time Sheet Header" = R,
                  tabledata "Time Sheet Line" = R,
                  tabledata "Time Sheet Posting Entry" = R,
                  tabledata "Unit of Measure" = RIMD,
                  tabledata "Work Type" = RIMD;
}
