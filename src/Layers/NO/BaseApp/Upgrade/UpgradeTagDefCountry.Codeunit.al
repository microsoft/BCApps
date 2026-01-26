#pragma warning disable AA0247
codeunit 9997 "Upgrade Tag Def - Country"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetVATCodeUpgradeTag());
    end;

    internal procedure GetVATCodeUpgradeTag(): Code[250]
    begin
        exit('MS-459977-VATCodeUpgradeTag-20230713');
    end;
}
