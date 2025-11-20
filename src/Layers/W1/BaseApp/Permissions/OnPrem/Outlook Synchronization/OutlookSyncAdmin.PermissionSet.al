namespace System.Security.AccessControl;

using System.Environment;
using System.Integration;
using System.Azure.Identity;
using System.Diagnostics;
using Microsoft.CRM.Outlook;
using System.Threading;

permissionset 3285 "Outlook Sync - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'Outlook Synch. administrator';

    Permissions = tabledata "Scheduled Task" = R,
                  tabledata "Web Service" = RIMD,
                  tabledata "Azure AD Mgt. Setup" = RIMD,
                  tabledata "Change Log Entry" = Rid,
                  tabledata "Change Log Setup (Field)" = RIMd,
                  tabledata "Change Log Setup (Table)" = RIMd,
                  tabledata "Change Log Setup" = RIMD,
                  tabledata "Exchange Service Setup" = RIMD,
                  tabledata "Job Queue Category" = RIMD,
                  tabledata "Job Queue Entry" = RIMD,
                  tabledata "Job Queue Log Entry" = Rid,
                  tabledata "Job Queue Role Center Cue" = RIMD,
                  tabledata "Office Add-in" = RIMD,
                  tabledata "Office Add-in Setup" = RIMD,
                  tabledata "Office Admin. Credentials" = RIMD;
}
