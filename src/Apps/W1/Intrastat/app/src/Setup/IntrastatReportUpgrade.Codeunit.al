#pragma warning disable AA0247
#if not CLEAN30
#pragma warning disable AA0247
codeunit 4815 "Intrastat Report Upgrade"
{
    Subtype = Upgrade;
    ObsoleteState = Pending;
    ObsoleteReason = 'Obsolete schema migration code has been removed.';
    ObsoleteTag = '30.0';

    trigger OnUpgradePerCompany()
    begin
    end;

    local procedure GetIntrastatDocumentVATIDUpgradeTag(): Code[250]
    begin
    end;

    local procedure RegisterUpgradeTags(PerCompanyUpgradeTags: List of [Code[250]])
    begin
    end;
}
#endif
