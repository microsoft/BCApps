// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.Environment.Configuration;
using System.DataAdministration;
using System.PerformanceProfile;
using System.Upgrade;

codeunit 1933 "Performance Profiler Installer"
{
    Subtype = Install;
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;
    Permissions = tabledata "Performance Profile Scheduler" = r;

    trigger OnInstallAppPerCompany()
    begin
        AddRetentionPolicyAllowedTables(false);
    end;

    procedure AddRetentionPolicyAllowedTables(ForceUpdate: Boolean)
    var
        PerformanceProfileScheduler: Record "Performance Profile Scheduler";
        ScheduledPerfProfilerImpl: Codeunit "Scheduled Perf. Profiler Impl.";
        RetenPolAllowedTables: Codeunit "Reten. Pol. Allowed Tables";
        RetentionPolicySetup: Codeunit "Retention Policy Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        IsInitialSetup: Boolean;
    begin
        IsInitialSetup := not UpgradeTag.HasUpgradeTag(GetPerformanceProfileAddedToAllowedListUpgradeTag());
        if not (IsInitialSetup or ForceUpdate) then
            exit;

        RetenPolAllowedTables.AddAllowedTable(Database::"Performance Profile Scheduler", PerformanceProfileScheduler.FieldNo("Ending Date-Time"), 1);

        if not IsInitialSetup then
            exit;

        ScheduledPerfProfilerImpl.CreateRetentionPolicySetup(Database::"Performance Profile Scheduler", RetentionPolicySetup.FindOrCreateRetentionPeriod("Retention Period Enum"::"1 Week"));

        UpgradeTag.SetUpgradeTag(GetPerformanceProfileAddedToAllowedListUpgradeTag());
    end;

    local procedure GetPerformanceProfileAddedToAllowedListUpgradeTag(): Code[250]
    begin
        exit('MS-533346-PerformanceProfilesRetentionPolicy-20240306');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reten. Pol. Allowed Tables", OnRefreshAllowedTables, '', false, false)]
    local procedure AddAllowedTablesOnRefreshAllowedTables()
    begin
        AddRetentionPolicyAllowedTables(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", OnAfterLogin, '', false, false)]
    local procedure AddAllowedTablesOnAfterSystemInitialization()
    begin
        AddRetentionPolicyAllowedTables(false);
    end;
}