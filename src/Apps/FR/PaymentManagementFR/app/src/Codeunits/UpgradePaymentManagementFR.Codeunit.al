// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using System.Upgrade;

codeunit 10840 "Upgrade Payment Management FR"
{
    Access = Internal;
    Subtype = Upgrade;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagPayment: Codeunit "Upg. Tag Payment Management FR";

    trigger OnUpgradePerCompany()
    var
        CurrentModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        if CurrentModuleInfo.AppVersion().Major() >= 31 then
            UpgradePayment();

        UpgradePaymentStepObjectIDs();
    end;

    local procedure UpgradePayment()
    var
        PaymentDataMigrationFR: Codeunit "Payment Data Migration FR";
    begin
        if UpgradeTag.HasUpgradeTag(UpgTagPayment.GetPaymentUpgradeTag()) then
            exit;

        PaymentDataMigrationFR.MigratePaymentData();

        UpgradeTag.SetUpgradeTag(UpgTagPayment.GetPaymentUpgradeTag());
    end;

    local procedure UpgradePaymentStepObjectIDs()
    var
        PaymentDataMigrationFR: Codeunit "Payment Data Migration FR";
    begin
        // The remapping has its own upgrade tag on purpose. Companies that migrated the payment data from
        // Feature Management before the remapping was introduced already have the upgrade tag of the data
        // migration, so their payment steps would otherwise keep pointing at the base application objects.
        // The remapping is idempotent, so it does not matter whether the data was migrated just now or earlier.
        if UpgradeTag.HasUpgradeTag(UpgTagPayment.GetPaymentStepObjectIDsUpgradeTag()) then
            exit;

        // Only a company whose payment data was migrated can have payment steps that point at the base
        // application objects. Marking the remapping as done for a company that has not migrated yet would
        // skip the remapping of the data that the upgrade to version 31 migrates later.
        if not UpgradeTag.HasUpgradeTag(UpgTagPayment.GetPaymentUpgradeTag()) then
            exit;

        PaymentDataMigrationFR.RemapPaymentStepObjectIDs();

        UpgradeTag.SetUpgradeTag(UpgTagPayment.GetPaymentStepObjectIDsUpgradeTag());
    end;
}
