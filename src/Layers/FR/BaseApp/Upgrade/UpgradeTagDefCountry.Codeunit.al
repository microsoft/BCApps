#pragma warning disable AA0247
codeunit 9997 "Upgrade Tag Def - Country"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetUpgradeDetailedCVLedgerEntriesTag());
    end;

    procedure GetUpgradeDetailedCVLedgerEntriesTag(): Code[250]
    begin
        exit('MS-294190-FR-UpgradeDetailedCVLedgerEntries-20190122');
    end;

    procedure GetUpgradePaymentPracticesTag(): Code[250]
    begin
        exit('MS-473083-FR-GetUpgradePaymentPracticesTag-20230713');
    end;
}

