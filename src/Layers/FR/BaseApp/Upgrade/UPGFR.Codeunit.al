#pragma warning disable AA0247
codeunit 104101 "UPG.FR"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    var
        HybridDeployment: Codeunit "Hybrid Deployment";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;

        UpgradeDetailedCVLedgerEntries();
    end;

    local procedure UpgradeDetailedCVLedgerEntries()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetUpgradeDetailedCVLedgerEntriesTag()) then
            exit;

        CODEUNIT.RUN(CODEUNIT::"Update Dtld. CV Ledger Entries");

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetUpgradeDetailedCVLedgerEntriesTag());
    end;
}

