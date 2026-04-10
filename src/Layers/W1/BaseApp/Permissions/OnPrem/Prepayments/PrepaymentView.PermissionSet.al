namespace System.Security.AccessControl;

using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

permissionset 3914 "Prepayment - View"
{
    Access = Public;
    Assignable = false;
    Caption = 'Prepayment';

    Permissions = tabledata "Prepayment Inv. Line Buffer" = rimd,
                  tabledata "Purchase Prepayment %" = R,
                  tabledata "Sales Prepayment %" = R;
}
