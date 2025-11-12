namespace System.Security.AccessControl;

using System.Environment;
using System.Diagnostics;
using System.Threading;

permissionset 7871 "Outlook Sync. - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Outlook Synch. power user';

    Permissions = tabledata "Scheduled Task" = R,
                  tabledata "Change Log Entry" = Ri,
                  tabledata "Change Log Setup (Field)" = RIM,
                  tabledata "Change Log Setup (Table)" = RIM,
                  tabledata "Change Log Setup" = RM,
                  tabledata "Job Queue Category" = Rimd,
                  tabledata "Job Queue Entry" = RImd,
                  tabledata "Job Queue Log Entry" = Ri,
                  tabledata "Job Queue Role Center Cue" = RImd;
}
