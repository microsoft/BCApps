namespace Microsoft.Sample.Loyalty;

permissionset 50100 "Loyalty Full Access"
{
    Assignable = true;
    Caption = 'Loyalty Full Access';

    Permissions =
        tabledata "Loyalty Member" = RIMD,
        tabledata "Loyalty Point Entry" = RIMD,
        table "Loyalty Member" = X,
        table "Loyalty Point Entry" = X,
        codeunit "Loyalty Management" = X,
        page "Loyalty Member Card" = X,
        page "Loyalty Member API" = X;
}
