namespace System.Security.AccessControl;

using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

permissionset 9412 "Prepayment - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'Prepayment Setup';

    Permissions = tabledata "Purchase Prepayment %" = RIMD,
                  tabledata "Sales Prepayment %" = RIMD;
}
