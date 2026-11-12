// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

#if not CLEAN28
using Microsoft.Foundation.Company;
#endif
using System.Upgrade;

codeunit 10841 "Upg. Tag Payment Management FR"
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure RegisterPerCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetPaymentUpgradeTag());
        PerCompanyUpgradeTags.Add(GetPaymentStepObjectIDsUpgradeTag());
#if CLEAN28
        PerCompanyUpgradeTags.Add(GetPaymentVATJournalFieldsUpgradeTag());
        PerCompanyUpgradeTags.Add(GetPaymentVATBufferUpgradeTag());
        PerCompanyUpgradeTags.Add(GetDirectDebitSourceFieldsUpgradeTag());
#endif
    end;

#if not CLEAN28
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company-Initialize", 'OnCompanyInitialize', '', false, false)]
    local procedure InitializePaymentVATJournalFields()
    var
        PaymentUpgrade: Codeunit "Upgrade Payment Management FR";
        CurrentModuleInfo: ModuleInfo;
    begin
        // The generic tag-list event can target another company and does not identify that company.
        // Here the current company is the initialized company: tag enabled companies after migration,
        // and leave disabled companies untagged until activation, unless version 31 forces activation.
        // Installation, upgrades and company initialization use the same version threshold.
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        PaymentUpgrade.UpgradePaymentVATJournalFields(CurrentModuleInfo.AppVersion().Major() >= 31);
        PaymentUpgrade.UpgradePaymentVATBuffer(CurrentModuleInfo.AppVersion().Major() >= 31);
        PaymentUpgrade.UpgradeDirectDebitSourceFields(CurrentModuleInfo.AppVersion().Major() >= 31);
    end;
#endif

    internal procedure GetPaymentUpgradeTag(): Code[250]
    begin
        exit('MS-581204-PaymentManagementUpgradeTag-20250918');
    end;

    internal procedure GetPaymentStepObjectIDsUpgradeTag(): Code[250]
    begin
        exit('MS-645208-PaymentStepObjectIDsUpgradeTag-20260805');
    end;

    internal procedure GetPaymentVATJournalFieldsUpgradeTag(): Code[250]
    begin
        exit('MS-653673-PaymentVATJournalFieldsUpgradeTag-20261014');
    end;

    internal procedure GetPaymentVATBufferUpgradeTag(): Code[250]
    begin
        exit('MS-653673-PaymentVATBufferUpgradeTag-20261020');
    end;

    internal procedure GetDirectDebitSourceFieldsUpgradeTag(): Code[250]
    begin
        exit('MS-653676-DirectDebitSourceFieldsUpgradeTag-20261020');
    end;
}