#pragma warning disable AA0247
codeunit 104151 "ISO Code UPG.BE"
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

        UpdateCountyName();
    end;

    local procedure UpdateCountyName()
    var
        CountryRegion: Record "Country/Region";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetUpdateCountyNameTag()) then
            exit;

        CountryRegion.SetFilter("ISO Country/Region Code", '<>%1', '');
        if CountryRegion.FindSet() then
            repeat
                CountryRegion."ISO Code" := CountryRegion."ISO Country/Region Code";
                CountryRegion.Modify();
            until CountryRegion.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetUpdateCountyNameTag());
    end;
}

