namespace System.Security.AccessControl;

using Microsoft.Finance.Dimension;

permissionset 3505 "Global Dimensions - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Change Global Dimension';

    Permissions = tabledata "Change Global Dim. Header" = RIMD,
                  tabledata "Change Global Dim. Log Entry" = RIMD;
}
