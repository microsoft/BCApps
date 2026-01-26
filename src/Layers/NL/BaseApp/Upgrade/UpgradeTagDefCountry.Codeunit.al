#pragma warning disable AA0247
codeunit 9997 "Upgrade Tag Def - Country"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetLocalSEPAInstrPrtyUpgradeTag());
        PerCompanyUpgradeTags.Add(GetElecTaxDeclSetupUpgradeTag());
    end;

    procedure GetLocalSEPAInstrPrtyUpgradeTag(): Code[250]
    begin
        exit('MS-381529-LocalSEPAInstrPrty-20201215');
    end;

    procedure GetElecTaxDeclSetupUpgradeTag(): Code[250]
    begin
        exit('MS-454920-ElecTaxDeclSetup-20221109');
    end;
}

