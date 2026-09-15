#pragma warning disable AA0247
codeunit 104155 "Upgrade CFDI RFC Number"
{
    Subtype = Upgrade;

    trigger OnRun()
    begin
    end;

    trigger OnUpgradePerCompany()
    var
        CompanyInformation: Record "Company Information";
        HybridDeployment: Codeunit "Hybrid Deployment";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefCountry: Codeunit "Upgrade Tag Def - Country";
    begin
        if not HybridDeployment.VerifyCanStartUpgrade(CompanyName()) then
            exit;
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefCountry.GetCompanyInformationRFCNumberUpgradeTag()) then
            exit;

        if CompanyInformation.Get() then begin
            CompanyInformation."RFC Number" := CompanyInformation."RFC No.";
            CompanyInformation.Modify();
        end;

        UpgradeTag.SetUpgradeTag(UpgradeTagDefCountry.GetCompanyInformationRFCNumberUpgradeTag());
    end;
}
