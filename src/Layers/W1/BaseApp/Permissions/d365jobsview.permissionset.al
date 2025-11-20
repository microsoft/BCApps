namespace System.Security.AccessControl;

using Microsoft.Projects.RoleCenters;
using Microsoft.Projects.Project.Archive;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Pricing;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.Posting;
using Microsoft.Projects.Project.WIP;
using Microsoft.Projects.Project.Setup;

permissionset 448 "D365 JOBS, VIEW"
{
    Assignable = true;

    Caption = 'Dynamics 365 View Projects';
    Permissions = tabledata Job = R,
                  tabledata "Job Archive" = R,
                  tabledata "Job Cue" = R,
                  tabledata "Job Entry No." = R,
                  tabledata "Job G/L Account Price" = R,
                  tabledata "Job Item Price" = R,
                  tabledata "Job Journal Batch" = R,
                  tabledata "Job Journal Line" = R,
                  tabledata "Job Journal Quantity" = R,
                  tabledata "Job Journal Template" = R,
                  tabledata "Job Ledger Entry" = R,
                  tabledata "Job Planning Line - Calendar" = R,
                  tabledata "Job Planning Line" = R,
                  tabledata "Job Planning Line Archive" = R,
                  tabledata "Job Planning Line Invoice" = R,
                  tabledata "Job Posting Buffer" = R,
                  tabledata "Job Posting Group" = R,
                  tabledata "Job Register" = R,
                  tabledata "Job Resource Price" = R,
                  tabledata "Job Task" = R,
                  tabledata "Job Task Archive" = R,
                  tabledata "Job Task Dimension" = R,
                  tabledata "Job Usage Link" = R,
                  tabledata "Job WIP Entry" = R,
                  tabledata "Job WIP G/L Entry" = R,
                  tabledata "Job WIP Method" = R,
                  tabledata "Job WIP Total" = R,
                  tabledata "Job WIP Warning" = R,
                  tabledata "Jobs Setup" = R,
                  tabledata "My Job" = R;
}
