// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

codeunit 10845 "Install Payment Management FR"
{
    Access = Internal;
    Subtype = Install;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnInstallAppPerCompany()
    var
        CurrentModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        InstallPaymentVATJournalFields(CurrentModuleInfo.AppVersion().Major() >= 31);
        InstallPaymentVATBuffer(CurrentModuleInfo.AppVersion().Major() >= 31);
        InstallDirectDebitSourceFields(CurrentModuleInfo.AppVersion().Major() >= 31);
    end;

    internal procedure InstallPaymentVATJournalFields(ForceActivation: Boolean)
    var
        PaymentUpgrade: Codeunit "Upgrade Payment Management FR";
    begin
        // Installing into an existing company must use the same eligibility and journal tag as upgrades.
        // Do not run the unrelated payment-table migration or reset its tags during installation.
        PaymentUpgrade.UpgradePaymentVATJournalFields(ForceActivation);
    end;

    internal procedure InstallPaymentVATBuffer(ForceActivation: Boolean)
    var
        PaymentUpgrade: Codeunit "Upgrade Payment Management FR";
    begin
        PaymentUpgrade.UpgradePaymentVATBuffer(ForceActivation);
    end;

    internal procedure InstallDirectDebitSourceFields(ForceActivation: Boolean)
    var
        PaymentUpgrade: Codeunit "Upgrade Payment Management FR";
    begin
        PaymentUpgrade.UpgradeDirectDebitSourceFields(ForceActivation);
    end;
}
