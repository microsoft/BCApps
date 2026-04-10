namespace System.Security.AccessControl;

using Microsoft.Finance.VAT.RateChange;

permissionset 2543 "VAT Rate Change Log - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'Delete VAT Rate Change Log';

    Permissions = tabledata "VAT Rate Change Log Entry" = D;
}
