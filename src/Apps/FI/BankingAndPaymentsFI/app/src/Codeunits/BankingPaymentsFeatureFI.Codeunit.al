// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using System.Environment.Configuration;

#if not CLEAN30
codeunit 13577 "Banking Payments Feature FI"
{
    Access = Internal;
    Permissions = tabledata "Feature Data Update Status" = r;

    procedure IsEnabled() Enabled: Boolean
    var
        FeatureKey: Record "Feature Key";
        Status: Record "Feature Data Update Status";
        FeatureManagementFacade: Codeunit "Feature Management Facade";
        UpgradeTag: Codeunit System.Upgrade."Upgrade Tag";
        Tags: Codeunit "Banking Payments Tags FI";
    begin
        Enabled := FeatureManagementFacade.IsEnabled('BankingAndPaymentsFI');
        if UpgradeTag.HasUpgradeTag(Tags.GetMigrationTag()) then begin
            if not FeatureKey.Get('BankingAndPaymentsFI') then
                Error(MigrationRequiredErr);
            if not Status.Get('BankingAndPaymentsFI', CompanyName()) then
                Error(UnsafeRollbackErr);
            if (FeatureKey.Enabled <> FeatureKey.Enabled::"All Users") or
               not FeatureKey."Data Update Required" or not Enabled or
               not Status."Data Update Required" or (Status."Feature Status" <> Status."Feature Status"::Complete) or
               UpgradeTag.HasUpgradeTagSkipped(Tags.GetMigrationTag(), CopyStr(CompanyName(), 1, 30))
            then
                Error(UnsafeRollbackErr);
        end;
        if Enabled then
            if not UpgradeTag.HasUpgradeTag(Tags.GetMigrationTag()) then
                Error(MigrationRequiredErr);
        OnAfterCheckFeatureEnabled(Enabled);
    end;

    procedure EnsureEnabled()
    begin
        if not IsEnabled() then
            Error(FeatureDisabledErr);
    end;

    var
        FeatureDisabledErr: Label 'Enable the Finnish Banking and Payments feature after completing data migration before using this action.';
        MigrationRequiredErr: Label 'Finnish Banking and Payments cannot run before company data migration is complete. Complete the approved controlled cutover before enabling the feature.';
        UnsafeRollbackErr: Label 'Finnish banking has already migrated in this company. The feature cannot be disabled or reset to legacy processing; recover the inconsistent feature status explicitly.';

    [IntegrationEvent(true, false)]
    local procedure OnAfterCheckFeatureEnabled(var IsEnabled: Boolean)
    begin
    end;
}
#endif
