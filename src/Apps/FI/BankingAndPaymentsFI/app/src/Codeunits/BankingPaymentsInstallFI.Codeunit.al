// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using System.Environment.Configuration;
using System.Upgrade;

codeunit 13585 "Banking Payments Install FI"
{
    Access = Internal;
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    begin
        InstallCompany();
    end;

    internal procedure InstallCompany()
    var
#if CLEAN30
        Migrate: Codeunit "Banking Payments Migrate FI";
#else
        FeatureKey: Record "Feature Key";
        UpgradeTag: Codeunit "Upgrade Tag";
        Tags: Codeunit "Banking Payments Tags FI";
        Update: Codeunit "Banking Payments Update FI";
#endif
    begin
#if CLEAN30
        Migrate.MigrateDuringLifecycle();
#else
        if UpgradeTag.HasUpgradeTag(Tags.GetMigrationTag()) then begin
            Update.VerifyCurrentCompanyActivated();
            exit;
        end;
        if FeatureKey.Get('BankingAndPaymentsFI') then
            if FeatureKey.Enabled <> FeatureKey.Enabled::None then
                Error(InactiveInstallationRequiredErr);
#endif
    end;

    var
        InactiveInstallationRequiredErr: Label 'First install Finnish banking with the feature inactive. Then prepare an exact higher app version and perform the controlled upgrade under tenant exclusive access; installation must not freeze a legacy data snapshot.';
}
