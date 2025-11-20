namespace System.Security.AccessControl;

using Microsoft.Foundation.Comment;
using Microsoft.Finance.Dimension;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Source;
using Microsoft.Pricing.Worksheet;
using Microsoft.Projects.Project.Archive;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Pricing;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.WIP;

permissionset 1087 "Jobs - Read"
{
    Access = Public;
    Assignable = false;
    Caption = 'Read projects and entries';

    Permissions = tabledata "Comment Line" = R,
                  tabledata "Comment Line Archive" = R,
                  tabledata "Default Dimension" = R,
                  tabledata "Dtld. Price Calculation Setup" = R,
                  tabledata "Duplicate Price Line" = R,
                  tabledata Job = R,
                  tabledata "Job Archive" = R,
                  tabledata "Job G/L Account Price" = R,
                  tabledata "Job Item Price" = R,
                  tabledata "Job Ledger Entry" = R,
                  tabledata "Job Planning Line - Calendar" = R,
                  tabledata "Job Planning Line" = R,
                  tabledata "Job Planning Line Archive" = R,
                  tabledata "Job Planning Line Invoice" = R,
                  tabledata "Job Resource Price" = R,
                  tabledata "Job Task" = R,
                  tabledata "Job Task Archive" = R,
                  tabledata "Job Usage Link" = R,
                  tabledata "Job WIP Entry" = R,
                  tabledata "Job WIP G/L Entry" = R,
                  tabledata "Job WIP Method" = R,
                  tabledata "Job WIP Total" = R,
                  tabledata "Job WIP Warning" = R,
                  tabledata "Price Asset" = R,
                  tabledata "Price Calculation Buffer" = R,
                  tabledata "Price Calculation Setup" = R,
                  tabledata "Price Line Filters" = R,
                  tabledata "Price List Header" = R,
                  tabledata "Price List Line" = R,
                  tabledata "Price Source" = R,
                  tabledata "Price Worksheet Line" = R;
}
