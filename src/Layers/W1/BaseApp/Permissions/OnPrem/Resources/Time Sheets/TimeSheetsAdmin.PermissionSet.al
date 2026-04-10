namespace System.Security.AccessControl;

using Microsoft.Projects.TimeSheet;

permissionset 7682 "Time Sheets - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'Create and delete time sheets';

    Permissions = tabledata "Time Sheet Chart Setup" = RIMD,
                  tabledata "Time Sheet Cmt. Line Archive" = RIMD,
                  tabledata "Time Sheet Comment Line" = RIMD,
                  tabledata "Time Sheet Detail" = RIMD,
                  tabledata "Time Sheet Detail Archive" = RIMD,
                  tabledata "Time Sheet Header" = RIMD,
                  tabledata "Time Sheet Header Archive" = RIMD,
                  tabledata "Time Sheet Line" = RIMD,
                  tabledata "Time Sheet Line Archive" = RIMD,
                  tabledata "Time Sheet Posting Entry" = RIMD;
}
