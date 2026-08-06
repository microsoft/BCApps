namespace Microsoft.Integration.Shopify;

using Microsoft.Finance.SalesTax;

permissionset 30470 "Shpfy TMA"
{
    Caption = 'Shopify Tax Matching Agent';
    Assignable = true;

    IncludedPermissionSets = "Shpfy - Edit";

    Permissions =
        tabledata "Tax Area" = RIMD,
        tabledata "Tax Area Line" = RIMD,
        tabledata "Tax Detail" = RIMD,
        tabledata "Tax Jurisdiction" = RIMD,
        codeunit "Shpfy TMA Register" = X,
        codeunit "Shpfy TMA Matcher" = X,
        codeunit "Shpfy Tax Area Builder" = X,
        codeunit "Shpfy TMA Events" = X,
        codeunit "Shpfy Tax Match Function" = X,
        codeunit "Shpfy TMA Install" = X,
        codeunit "Shpfy TMA Upgrade" = X,
        codeunit "Shpfy TMA Activity Log" = X,
        codeunit "Shpfy TMA Notify" = X;
}
