namespace System.Security.AccessControl;

using Microsoft.CostAccounting.Setup;

permissionset 2046 "D365 COSTACC, SETUP"
{
    Assignable = true;

    Caption = 'Dyn. 365 Setup Cost Accounting';
    Permissions = tabledata "Cost Accounting Setup" = RIMD;
}
