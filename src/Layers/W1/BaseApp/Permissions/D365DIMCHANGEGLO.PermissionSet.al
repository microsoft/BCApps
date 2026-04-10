namespace System.Security.AccessControl;

using Microsoft.Finance.Dimension;

permissionset 2981 "D365 DIM CHANGE GLO"
{
    Assignable = true;

    Caption = 'D365 Change Global Dimension';
    Permissions = tabledata "Change Global Dim. Header" = RIMD,
                  tabledata "Change Global Dim. Log Entry" = RIMD;
}