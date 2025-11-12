namespace System.Security.AccessControl;

using System.Environment;
using System.Threading;

permissionset 1347 "Job Queue - View"
{
    Access = Public;
    Assignable = false;
    Caption = 'Job Queue Run';

    Permissions = tabledata "Scheduled Task" = R,
                  tabledata "Job Queue Category" = Rimd,
                  tabledata "Job Queue Entry" = Rimd,
                  tabledata "Job Queue Log Entry" = Rimd,
                  tabledata "Job Queue Role Center Cue" = Rimd;
}
