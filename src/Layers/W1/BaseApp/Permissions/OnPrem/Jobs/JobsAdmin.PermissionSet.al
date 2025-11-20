namespace System.Security.AccessControl;

using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.WIP;
using Microsoft.Projects.Project.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Finance.VAT.RateChange;

permissionset 6124 "Jobs - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'Project setup';

    Permissions = tabledata "Job Journal Batch" = RIMD,
                  tabledata "Job Journal Template" = RIMD,
                  tabledata "Job Posting Group" = RIMD,
                  tabledata "Job WIP Method" = R,
                  tabledata "Jobs Setup" = RIMD,
                  tabledata "Reason Code" = R,
                  tabledata "Source Code" = R,
                  tabledata "Source Code Setup" = R,
                  tabledata "VAT Rate Change Log Entry" = Ri;
}
