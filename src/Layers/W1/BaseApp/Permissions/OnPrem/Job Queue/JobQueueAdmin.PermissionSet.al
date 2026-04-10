namespace System.Security.AccessControl;

using System.Environment;
using System.Threading;

permissionset 4184 "Job Queue - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'Job Queue Setup';

    Permissions = tabledata "Scheduled Task" = R,
                  tabledata "Job Queue Category" = RIMD,
                  tabledata "Job Queue Entry" = RIMD,
                  tabledata "Job Queue Log Entry" = RIMD,
                  tabledata "Job Queue Role Center Cue" = RIMD,
                  tabledata "Job Queue Notification Setup" = RIMD,
                  tabledata "Job Queue Notified Admin" = RIMD;

}
