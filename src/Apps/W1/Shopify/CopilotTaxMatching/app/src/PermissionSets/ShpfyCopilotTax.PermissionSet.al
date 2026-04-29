namespace Microsoft.Integration.Shopify;

using Microsoft.Finance.SalesTax;

permissionset 30470 "Shpfy Copilot Tax"
{
    Caption = 'Shopify Copilot Tax Matching';
    Assignable = true;

    IncludedPermissionSets = "Shpfy - Edit";

    Permissions =
        tabledata "Tax Area" = RIMD,
        tabledata "Tax Area Line" = RIMD,
        tabledata "Tax Detail" = RIMD,
        tabledata "Tax Jurisdiction" = RIMD,
        tabledata "Shpfy Copilot Tax Notification" = RIMD,
        codeunit "Shpfy Copilot Tax Register" = X,
        codeunit "Shpfy Copilot Tax Matcher" = X,
        codeunit "Shpfy Tax Area Builder" = X,
        codeunit "Shpfy Copilot Tax Events" = X,
        codeunit "Shpfy Tax Match Function" = X,
        codeunit "Shpfy Copilot Tax Install" = X,
        codeunit "Shpfy CT Activity Log" = X,
        codeunit "Shpfy Copilot Tax Notify" = X;
}
