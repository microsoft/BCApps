#pragma warning disable AA0247
codeunit 9997 "Upgrade Tag Def - Country"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetUpdateEmployeeNewNamesTag());
        PerCompanyUpgradeTags.Add(GetUpdateNoTaxableEntriesTag());
        PerCompanyUpgradeTags.Add(GetUpdateSIISetupSchemasTag());
        PerCompanyUpgradeTags.Add(GetUpdateSIICertificateTag());
        PerCompanyUpgradeTags.Add(GetUpdateNoTaxableEntriesVATDateTag());
        PerCompanyUpgradeTags.Add(GetUpdateCustVendWarning349VATDateTag());
        PerCompanyUpgradeTags.Add(GetUpdateCustLedgerEntryVATDateTag());
        PerCompanyUpgradeTags.Add(GetUpdateVendLedgerEntryVATDateTag());
    end;

    procedure GetUpdateEmployeeNewNamesTag(): Code[250]
    begin
        exit('MS-292373-ES-UpdateEmployeeNewNames-20190201');
    end;

    procedure GetUpdateNoTaxableEntriesTag(): Code[250]
    begin
        exit('MS-293795-ES-GetUpdateNoTaxableEntriesTag-20190220');
    end;

    procedure GetUpdateReportSelectionsTag(): Code[250]
    begin
        exit('MS-308347-ES-GetUpdateReportSelectionsTag-20191115');
    end;

    procedure GetUpdateSIISetupSchemasTag(): Code[250]
    begin
        exit('MS-341500-ES-GetUpdateSIISetupSchemasTag-20200207');
    end;

    procedure GetUpdateSIICertificateTag(): Code[250]
    begin
        exit('MS-316847-ES-GetUpdateSIICertificateTag-20191206');
    end;

    procedure GetUpdateNoTaxableEntriesVATDateTag(): Code[250]
    begin
        exit('MS-450002-ES-GetUpdateNoTaxableEntriesVATDateTag-20221007');
    end;

    procedure GetUpdateCustVendWarning349VATDateTag(): Code[250]
    begin
        exit('MS-450002-ES-GetUpdateCustVendWarning349VATDateTag-20221021');
    end;

    procedure GetUpdateCustLedgerEntryVATDateTag(): Code[250]
    begin
        exit('MS-450002-ES-GetUpdateCustLedgerEntryVATDateTag-20221021');
    end;

    procedure GetUpdateVendLedgerEntryVATDateTag(): Code[250]
    begin
        exit('MS-450002-ES-GetUpdateVendLedgerEntryVATDateTag-20221021');
    end;


}

