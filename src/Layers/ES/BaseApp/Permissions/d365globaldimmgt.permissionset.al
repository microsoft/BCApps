namespace System.Security.AccessControl;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.ReceivablesPayables;

permissionset 2332 "D365 GLOBAL DIM MGT"
{
    Assignable = true;

    Caption = 'Dyn. 365 Change Global Dim';
    
    Permissions = tabledata "Cartera Doc." = RM,
                  tabledata "Change Global Dim. Header" = RIMD,
                  tabledata "Change Global Dim. Log Entry" = RIMD,
                  tabledata "Closed Cartera Doc." = RM,
                  tabledata "Posted Cartera Doc." = RM;
}
