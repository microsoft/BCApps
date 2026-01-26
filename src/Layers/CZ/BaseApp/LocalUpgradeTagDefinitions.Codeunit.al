#pragma warning disable AA0247
codeunit 11790 "Local Upgrade Tag Definitions"
{
    Access = internal;

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetCorrectionsForBadReceivableUpgradeTag());
        PerCompanyUpgradeTags.Add(GetObsoleteGeneralLedgerEntryDescriptionFeatureUpgradeTag());
        PerCompanyUpgradeTags.Add(GetVendorTemplateUpgradeTag());
        PerCompanyUpgradeTags.Add(GetIntrastatJnlLineShipmentMethodCodeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetItemJournalLineShipmentMethodCodeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetItemLedgerEntryShipmentMethodCodeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetCashDeskWorkflowTemplatesCodeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetCreditWorkflowTemplatesCodeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetPaymentOrderWorkflowTemplatesCodeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetAdvanceLetterWorkflowTemplatesCodeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetReplaceMulIntRateSalesSetupUpgradeTag());
        PerCompanyUpgradeTags.Add(GetReplaceMulIntRateFinChargeIntRateUpgradeTag());
        PerCompanyUpgradeTags.Add(GetReplaceMulIntRateFinanceChargeMemosUpgradeTag());
        PerCompanyUpgradeTags.Add(GetReplaceMulIntRateRemindersUpgradeTag());
        PerCompanyUpgradeTags.Add(GetReplaceMulIntRateIssuedFinanceChargeMemosUpgradeTag());
        PerCompanyUpgradeTags.Add(GetReplaceMulIntRateIssuedRemindersUpgradeTag());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerDatabaseUpgradeTags', '', false, false)]
    local procedure RegisterPerDatabaseTags(var PerDatabaseUpgradeTags: List of [Code[250]])
    begin
        PerDatabaseUpgradeTags.Add(GetUseIsolatedCertificateInsteadOfCertificateCZ());
    end;

    internal procedure GetCorrectionsForBadReceivableUpgradeTag(): Code[250]
    begin
        exit('CZ-386361-CorrectionsForBadReceivable-20210122');
    end;

    internal procedure GetUseIsolatedCertificateInsteadOfCertificateCZ(): Code[250]
    begin
        exit('CZ-322699-UseIsolatedCertificateInsteadOfCertificateCZ-20190909');
    end;

    internal procedure GetObsoleteGeneralLedgerEntryDescriptionFeatureUpgradeTag(): Code[250]
    begin
        exit('CZ-335319-ObsoleteGeneralLedgerEntryDescriptionFeature-20191128');
    end;

    internal procedure GetVendorTemplateUpgradeTag(): Code[250]
    begin
        exit('CZ-383715-VendorTemplate-20201217');
    end;

    internal procedure GetIntrastatJnlLineShipmentMethodCodeUpgradeTag(): Code[250]
    begin
        exit('CZ-386361-IntrastatJnlLineShipmentMethodCode-20210122');
    end;

    internal procedure GetItemJournalLineShipmentMethodCodeUpgradeTag(): Code[250]
    begin
        exit('CZ-386361-ItemJournalLineShipmentMethodCode-20210122');
    end;

    internal procedure GetItemLedgerEntryShipmentMethodCodeUpgradeTag(): Code[250]
    begin
        exit('CZ-386361-ItemLedgerEntryShipmentMethodCode-20210122');
    end;

    internal procedure GetCashDeskWorkflowTemplatesCodeUpgradeTag(): Code[250]
    begin
        exit('CZ-403757-CashDeskWorkflowTemplatesCode-20210629');
    end;

    internal procedure GetCreditWorkflowTemplatesCodeUpgradeTag(): Code[250]
    begin
        exit('CZ-403757-CreditWorkflowTemplatesCode-20210629');
    end;

    internal procedure GetPaymentOrderWorkflowTemplatesCodeUpgradeTag(): Code[250]
    begin
        exit('CZ-403757-PaymentOrderWorkflowTemplatesCode-20210629');
    end;

    internal procedure GetAdvanceLetterWorkflowTemplatesCodeUpgradeTag(): Code[250]
    begin
        exit('CZ-403757-AdvanceLetterWorkflowTemplatesCode-20210629');
    end;

    internal procedure GetReplaceMulIntRateSalesSetupUpgradeTag(): Code[250]
    begin
        exit('CZ-461779-ReplaceMulIntRateSalesSetup-20220418');
    end;

    internal procedure GetReplaceMulIntRateFinChargeIntRateUpgradeTag(): Code[250]
    begin
        exit('CZ-461779-ReplaceMulIntRateFinChargeIntRates-20220418');
    end;

    internal procedure GetReplaceMulIntRateFinanceChargeMemosUpgradeTag(): Code[250]
    begin
        exit('CZ-461779-ReplaceMulIntRateFinanceChargeMemos-20220418');
    end;

    internal procedure GetReplaceMulIntRateRemindersUpgradeTag(): Code[250]
    begin
        exit('CZ-461779-ReplaceMulIntRateReminders-20220418');
    end;

    internal procedure GetReplaceMulIntRateIssuedFinanceChargeMemosUpgradeTag(): Code[250]
    begin
        exit('CZ-461779-ReplaceMulIntRateIssuedFinanceChargeMemos-20220418');
    end;

    internal procedure GetReplaceMulIntRateIssuedRemindersUpgradeTag(): Code[250]
    begin
        exit('CZ-461779-ReplaceMulIntRateIssuedReminders-20220418');
    end;
}
