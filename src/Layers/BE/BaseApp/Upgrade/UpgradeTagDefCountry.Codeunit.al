#pragma warning disable AA0247
codeunit 9997 "Upgrade Tag Def - Country"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        // Country
        PerCompanyUpgradeTags.Add(GetUpdateCountyNameTag());
        PerCompanyUpgradeTags.Add(GetCopyInvNoToPmtRefTag());
        PerCompanyUpgradeTags.Add(GetCustomerVATLiableTag());
    end;

    procedure GetUpdateCountyNameTag(): Code[250]
    begin
        exit('MS-BE-299774-UpdateCountyName-20190211');
    end;

    procedure GetCopyInvNoToPmtRefTag(): Code[250]
    begin
        exit('MS-BE-362612-CopyInvNoToPmtRef-20200715');
    end;

    procedure GetCustomerVATLiableTag(): Code[250]
    begin
        exit('MS-BE-388486-VATLiableCustomer-20200203');
    end;
}

