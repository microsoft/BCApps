#pragma warning disable AA0247
codeunit 104156 "Upgrade VAT Setup NA"
{
    SubType = Upgrade;

    trigger OnUpgradePerCompany()
    begin
        UpgradeVATSetupVATDateInUSAndCA();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetVATSetupAllowVATDateUSCATag());
    end;

    local procedure UpgradeVATSetupVATDateInUSAndCA()
    var
        VATSetup: Record "VAT Setup";
        UserSetup: Record "User Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        EnvironmentInfo: Codeunit "Environment Information";
        CountryCode: Text;
    begin
        if UpgradeTag.HasUpgradeTag(GetVATSetupAllowVATDateUSCATag()) then
            exit;

        // If not from US or CA then skip upgrade.
        CountryCode := EnvironmentInfo.GetApplicationFamily();
        if not (CountryCode in ['US', 'CA']) then begin
            UpgradeTag.SetUpgradeTag(GetVATSetupAllowVATDateUSCATag());
            exit;
        end;

        if VATSetup.Get() then begin
            VATSetup."Allow VAT Date From" := 0D;
            VATSetup."Allow VAT Date To" := 0D;
            VATSetup.Modify();
        end;

        if UserSetup.FindSet() then
            repeat
                UserSetup."Allow VAT Date From" := 0D;
                UserSetup."Allow VAT Date To" := 0D;
                if UserSetup.Modify() then;
            until UserSetup.Next() = 0;

        UpgradeTag.SetUpgradeTag(GetVATSetupAllowVATDateUSCATag());
    end;


    internal procedure GetVATSetupAllowVATDateUSCATag(): Code[250]
    begin
        exit('MS-493242-VATSetupAllowVATDateUpgrade-20230512');
    end;


}
