namespace Microsoft.API.Upgrade;

codeunit 5519 "API Fix Sales Cr. Memo"
{
    trigger OnRun()
    var
        APIDataUpgrade: Codeunit "API Data Upgrade";
    begin
        APIDataUpgrade.UpgradeSalesCreditMemoReasonCode(false);
    end;
}