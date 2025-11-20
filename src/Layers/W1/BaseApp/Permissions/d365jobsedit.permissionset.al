namespace System.Security.AccessControl;

using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Projects.RoleCenters;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Source;
using Microsoft.Pricing.Worksheet;
using Microsoft.Projects.Project.Archive;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Pricing;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.WIP;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Reporting;

permissionset 9886 "D365 JOBS, EDIT"
{
    Assignable = true;
    Caption = 'Dynamics 365 Create Projects';

    IncludedPermissionSets = "D365 JOBS, VIEW",
                             "D365 JOBS, SETUP";

    Permissions = tabledata "Dtld. Price Calculation Setup" = RIMD,
                  tabledata "Duplicate Price Line" = RIMD,
                  tabledata Job = IMD,
                  tabledata "Job Archive" = IMD,
                  tabledata "Job Cue" = IMD,
                  tabledata "Job Entry No." = IMD,
                  tabledata "Job G/L Account Price" = IMD,
                  tabledata "Job Item Price" = IMD,
                  tabledata "Job Journal Batch" = IMD,
                  tabledata "Job Journal Line" = IMD,
                  tabledata "Job Journal Quantity" = IMD,
                  tabledata "Job Ledger Entry" = imd,
                  tabledata "Job Planning Line - Calendar" = IMD,
                  tabledata "Job Planning Line" = IMD,
                  tabledata "Job Planning Line Archive" = IMD,
                  tabledata "Job Planning Line Invoice" = IMD,
                  tabledata "Job Register" = imd,
                  tabledata "Job Resource Price" = IMD,
                  tabledata "Job Task" = IMD,
                  tabledata "Job Task Archive" = IMD,
                  tabledata "Job Task Dimension" = IMD,
                  tabledata "Job Usage Link" = IMD,
                  tabledata "Job WIP Entry" = IMD,
                  tabledata "Job WIP G/L Entry" = imd,
                  tabledata "Job WIP Method" = IMD,
                  tabledata "Job WIP Total" = IMD,
                  tabledata "Job WIP Warning" = IMD,
                  tabledata "My Job" = IMD,
                  tabledata "Price Asset" = RIMD,
                  tabledata "Price Calculation Buffer" = RIMD,
                  tabledata "Price Calculation Setup" = RIMD,
                  tabledata "Price Line Filters" = RIMD,
                  tabledata "Price List Header" = RIMD,
                  tabledata "Price List Line" = RIMD,
                  tabledata "Price Source" = RIMD,
                  tabledata "Price Worksheet Line" = RIMD,
                  tabledata "VAT Setup" = R,
                  tabledata "VAT Posting Parameters" = R,
                  tabledata "VAT Reporting Code" = R;
}
