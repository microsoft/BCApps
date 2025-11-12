namespace System.Security.AccessControl;

using System.Environment;
using System.Diagnostics;
using System.Threading;

permissionset 6098 "Outlook Sync. - View"
{
    Access = Public;
    Assignable = false;
    Caption = 'Outlook Synch. common user';

    Permissions = tabledata "Scheduled Task" = R,
                  tabledata "Change Log Entry" = Ri,
                  tabledata "Change Log Setup (Field)" = Rim,
                  tabledata "Change Log Setup (Table)" = Rim,
                  tabledata "Change Log Setup" = R,
                  tabledata "Job Queue Category" = Rimd,
                  tabledata "Job Queue Entry" = RImd,
                  tabledata "Job Queue Log Entry" = Ri,
                  tabledata "Job Queue Role Center Cue" = RImd;
}
