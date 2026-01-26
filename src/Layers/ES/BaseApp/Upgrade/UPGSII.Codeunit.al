#pragma warning disable AA0247
codeunit 104100 "UPG SII"
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

        UpdateEmployeeNewNames();
        UpdateSchemasInSIISetup();
    end;

    local procedure UpdateEmployeeNewNames()
    var
        Employee: Record "Employee";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetUpdateEmployeeNewNamesTag()) then
            exit;

        if not Employee.FindSet() then
            exit;

        repeat
            Employee.UpdateNamesFromOldFields();
            Employee.Modify();
        until Employee.Next() = 0;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetUpdateEmployeeNewNamesTag());
    end;

    local procedure UpdateSchemasInSIISetup()
    var
        SIISetup: Record "SII Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetUpdateSIISetupSchemasTag()) then
            exit;

        if SIISetup.Get() then
            SIISetup.SetDefaults();

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetUpdateSIISetupSchemasTag());
    end;

}

