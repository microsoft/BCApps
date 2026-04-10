namespace System.Security.AccessControl;

using Microsoft.Finance.Dimension;

permissionset 2332 "D365 GLOBAL DIM MGT"
{
    Assignable = true;

    Caption = 'Dyn. 365 Change Global Dim';
    Permissions = tabledata "Change Global Dim. Header" = RIMD,
                  tabledata "Change Global Dim. Log Entry" = RIMD;
}
