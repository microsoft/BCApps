#pragma warning disable AA0247
codeunit 9997 "Upgrade Tag Def - Country"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetFixRemainingAmountCLEUpgradeTag());
        PerCompanyUpgradeTags.Add(GetFixRemainingAmountVLEUpgradeTag());
        PerCompanyUpgradeTags.Add(GetVATReportTaxAuthDocNoUpgradeTag());
        PerCompanyUpgradeTags.Add(GetNoSeriesITUpgradeTag());
    end;

    procedure GetFixRemainingAmountCLEUpgradeTag(): Code[250]
    begin
        exit('MS-314721-FixRemainingAmountsCLE-20190927');
    end;

    procedure GetFixRemainingAmountVLEUpgradeTag(): Code[250]
    begin
        exit('MS-314721-FixRemainingAmountsVLE-20190927');
    end;

    procedure GetVATReportTaxAuthDocNoUpgradeTag(): Code[250]
    begin
        exit('MS-402795-VATReportHeaderTaxAuthDocNo-20210527');
    end;

    internal procedure GetNoSeriesITUpgradeTag(): Code[250]
    begin
        exit('MS-471519-NoSeriesITUpgradeTag-20230606')
    end;

    internal procedure GetPeriodicVATSettlementEntryUpgradeTag(): Code[250]
    begin
        exit('MS-495201-PeriodicVATSettlementEntryUpgradeTag-20250423')
    end;
}

