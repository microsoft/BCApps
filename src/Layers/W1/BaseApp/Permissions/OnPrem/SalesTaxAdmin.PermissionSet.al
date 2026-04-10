namespace System.Security.AccessControl;

using Microsoft.Finance.SalesTax;

permissionset 1297 "Sales Tax - Admin"
{
    Access = Public;
    Assignable = false;
    Caption = 'Sales Tax Setup';

    Permissions = tabledata "Tax Area" = RIMD,
                  tabledata "Tax Area Line" = RIMD,
                  tabledata "Tax Detail" = RIMD,
                  tabledata "Tax Group" = RIMD,
                  tabledata "Tax Jurisdiction" = RIMD;
}
