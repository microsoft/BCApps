namespace System.Security.AccessControl;

using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Posting;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Setup;

permissionset 6408 "D365 JOBS, SETUP"
{
    Assignable = true;

    Caption = 'Dynamics 365 Projects Setup';
    Permissions = tabledata "Job Journal Template" = RIMD,
                  tabledata "Job Posting Buffer" = RIMD,
                  tabledata "Job Posting Group" = RIMD,
                  tabledata "Jobs Setup" = RIMD;
}
