// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using System.Environment;
using System.Environment.Configuration;
using System.Security.AccessControl;
using System.Security.User;
using System.Upgrade;

#if not CLEAN30
codeunit 13581 "Banking Payments Update FI" implements "Feature Data Update"
{
    Access = Internal;
    ObsoleteState = Pending;
    ObsoleteReason = 'Finnish Banking and Payments will be enabled by default in version 30.0.';
    ObsoleteTag = '30.0';
    Permissions = tabledata "Feature Data Update Status" = r;

    [Scope('OnPrem')]
    [CommitBehavior(CommitBehavior::Error)]
    procedure PrepareControlledUpgrade(TargetAppVersion: Text)
    var
        User: Record User;
        Status: Record "Feature Data Update Status";
        UserPermissions: Codeunit "User Permissions";
        UpgradeTag: Codeunit "Upgrade Tag";
        Tags: Codeunit "Banking Payments Tags FI";
        Module: ModuleInfo;
        TargetVersion: Version;
    begin
        if (CurrentClientType() <> ClientType::Management) or IsNullGuid(UserSecurityId()) then
            Error(ManagementRequiredErr);
        if not User.Get(UserSecurityId()) then
            Error(ManagementRequiredErr);
        if (User.State <> User.State::Enabled) or not UserPermissions.IsSuper(UserSecurityId()) then
            Error(ManagementRequiredErr);

        NavApp.GetCurrentModuleInfo(Module);
        TargetVersion := ValidateRequestVersion(TargetAppVersion, Module.AppVersion());
        ValidateProvisioning();
        ValidateMigratedCompanies();
        if UpgradeTag.HasUpgradeTag(Tags.GetMigrationTag()) then
            Error(AlreadyMigratedErr);
        GetPendingStatus(Status);

        if UpgradeTag.HasUpgradeTag(Tags.GetRequestMarkerTag()) then begin
            if not HasMatchingRequest(TargetVersion) then
                Error(RequestConflictErr);
            exit;
        end;

        // This records intent only. It is not evidence that tenant exclusive access is held.
        UpgradeTag.SetUpgradeTag(Tags.GetRequestTag(TargetVersion));
        UpgradeTag.SetUpgradeTag(Tags.GetRequestMarkerTag());
    end;

    internal procedure ValidateRequestVersion(TargetAppVersion: Text; CurrentVersion: Version): Version
    var
        Parts: List of [Text];
        Numbers: List of [Integer];
        Part: Text;
        Number: Integer;
        TargetVersion: Version;
    begin
        Parts := TargetAppVersion.Trim().Split('.');
        if Parts.Count() <> 4 then
            Error(InvalidVersionErr);
        foreach Part in Parts do begin
            if (Part = '') or (DelChr(Part, '=', '0123456789') <> '') then
                Error(InvalidVersionErr);
            if not Evaluate(Number, Part) then
                Error(InvalidVersionErr);
            if Number < 0 then
                Error(InvalidVersionErr);
            Numbers.Add(Number);
        end;
        TargetVersion := Version.Create(Numbers.Get(1), Numbers.Get(2), Numbers.Get(3), Numbers.Get(4));
        if TargetVersion <= CurrentVersion then
            Error(HigherVersionErr, Format(CurrentVersion));
        exit(TargetVersion);
    end;

    internal procedure ShouldMigrateDuringUpgrade(TargetVersion: Version): Boolean
    var
        Status: Record "Feature Data Update Status";
        UpgradeTag: Codeunit "Upgrade Tag";
        Tags: Codeunit "Banking Payments Tags FI";
    begin
        if UpgradeTag.HasUpgradeTag(Tags.GetMigrationTag()) then begin
            ValidateMigratedCompanies();
            VerifyCurrentCompanyActivated();
            exit(false);
        end;
        if not HasMatchingRequest(TargetVersion) then
            exit(false);
        ValidateProvisioning();
        ValidateMigratedCompanies();
        GetPendingStatus(Status);
        exit(true);
    end;

    [CommitBehavior(CommitBehavior::Error)]
    internal procedure CompleteControlledUpgrade()
    var
        Status: Record "Feature Data Update Status";
        FeatureManagementFacade: Codeunit "Feature Management Facade";
    begin
        if GetExecutionContext() <> ExecutionContext::Upgrade then
            Error(ControlledUpgradeRequiredErr);
        RequireLifecycleCompletion();
        ValidateProvisioning();
        GetPendingStatus(Status);
        FeatureManagementFacade.UpdateData(Status);
        VerifyCurrentCompanyActivated();
    end;

    procedure IsDataUpdateRequired(): Boolean
    var
        Status: Record "Feature Data Update Status";
    begin
        RequireLifecycleCompletion();
        ValidateProvisioning();
        Status.Get(FeatureKeyIdTok, CompanyName());
        Status.TestField("Data Update Required", true);
        if Status."Feature Status" = Status."Feature Status"::Complete then begin
            VerifyCurrentCompanyActivated();
            exit(false);
        end;
        GetPendingStatus(Status);
        exit(true);
    end;

    procedure ReviewData()
    begin
        Message(GetTaskDescription());
    end;

    procedure GetTaskDescription(): Text
    begin
        exit(ControlledUpgradeDescriptionTxt);
    end;

    procedure UpdateData(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    var
        StoredStatus: Record "Feature Data Update Status";
    begin
        RequireLifecycleCompletion();
        ValidateProvisioning();
        FeatureDataUpdateStatus.TestField("Feature Key", FeatureKeyIdTok);
        FeatureDataUpdateStatus.TestField("Company Name", CompanyName());
        FeatureDataUpdateStatus.TestField("Data Update Required", true);
        FeatureDataUpdateStatus.TestField("Feature Status", FeatureDataUpdateStatus."Feature Status"::Updating);
        StoredStatus.Get(FeatureKeyIdTok, CompanyName());
        StoredStatus.TestField("Feature Status", StoredStatus."Feature Status"::Updating);
        StoredStatus.TestField("Task Id", FeatureDataUpdateStatus."Task Id");
        StoredStatus.TestField("Session Id", SessionId());
        StoredStatus.TestField("Server Instance Id", ServiceInstanceId());
    end;

    procedure AfterUpdate(FeatureDataUpdateStatus: Record "Feature Data Update Status")
    begin
        FeatureDataUpdateStatus.TestField("Feature Key", FeatureKeyIdTok);
        FeatureDataUpdateStatus.TestField("Company Name", CompanyName());
        FeatureDataUpdateStatus.TestField("Feature Status", FeatureDataUpdateStatus."Feature Status"::Complete);
        VerifyCurrentCompanyActivated();
    end;

    internal procedure VerifyCurrentCompanyActivated()
    var
        Status: Record "Feature Data Update Status";
        FeatureManagementFacade: Codeunit "Feature Management Facade";
    begin
        RequireLifecycleCompletion();
        ValidateProvisioning();
        Status.Get(FeatureKeyIdTok, CompanyName());
        Status.TestField("Data Update Required", true);
        Status.TestField("Feature Status", Status."Feature Status"::Complete);
        if not FeatureManagementFacade.IsEnabled(FeatureKeyIdTok) then
            Error(UnsafeStateErr, CompanyName());
    end;

    local procedure HasMatchingRequest(TargetVersion: Version): Boolean
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        Tags: Codeunit "Banking Payments Tags FI";
    begin
        exit(UpgradeTag.HasUpgradeTag(Tags.GetRequestMarkerTag()) and
             UpgradeTag.HasUpgradeTag(Tags.GetRequestTag(TargetVersion)) and
             not UpgradeTag.HasUpgradeTagSkipped(Tags.GetRequestMarkerTag(), CopyStr(CompanyName(), 1, 30)) and
             not UpgradeTag.HasUpgradeTagSkipped(Tags.GetRequestTag(TargetVersion), CopyStr(CompanyName(), 1, 30)));
    end;

    local procedure RequireLifecycleCompletion()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        Tags: Codeunit "Banking Payments Tags FI";
    begin
        if not UpgradeTag.HasUpgradeTag(Tags.GetMigrationTag()) then
            Error(ControlledUpgradeRequiredErr);
        if UpgradeTag.HasUpgradeTagSkipped(Tags.GetMigrationTag(), CopyStr(CompanyName(), 1, 30)) then
            Error(ControlledUpgradeRequiredErr);
    end;

    local procedure ValidateProvisioning()
    var
        FeatureKey: Record "Feature Key";
    begin
        if not FeatureKey.Get(FeatureKeyIdTok) then
            Error(ProvisioningRequiredErr);
        if (FeatureKey.Enabled <> FeatureKey.Enabled::"All Users") or not FeatureKey."Data Update Required" then
            Error(ProvisioningRequiredErr);
    end;

    local procedure GetPendingStatus(var Status: Record "Feature Data Update Status")
    begin
        Status.LockTable();
        if not Status.Get(FeatureKeyIdTok, CompanyName()) then
            Error(PendingStatusRequiredErr);
        if not Status."Data Update Required" or
           (Status."Feature Status" <> Status."Feature Status"::Pending) or
           Status."Background Task" or not IsNullGuid(Status."Task Id")
        then
            Error(PendingStatusRequiredErr);
    end;

    local procedure ValidateMigratedCompanies()
    var
        Company: Record Company;
        Status: Record "Feature Data Update Status";
        UpgradeTag: Codeunit "Upgrade Tag";
        Tags: Codeunit "Banking Payments Tags FI";
        HasMigrationTag: Boolean;
    begin
        if Company.FindSet() then
            repeat
                HasMigrationTag := UpgradeTag.HasUpgradeTag(Tags.GetMigrationTag(), Company.Name);
                if HasMigrationTag then begin
                    if UpgradeTag.HasUpgradeTagSkipped(Tags.GetMigrationTag(), Company.Name) then
                        Error(UnsafeStateErr, Company.Name);
                    ValidateProvisioning();
                    if not Status.Get(FeatureKeyIdTok, Company.Name) then
                        Error(UnsafeStateErr, Company.Name);
                    if not Status."Data Update Required" or (Status."Feature Status" <> Status."Feature Status"::Complete) then
                        Error(UnsafeStateErr, Company.Name);
                end else
                    if Status.Get(FeatureKeyIdTok, Company.Name) then
                        if Status."Feature Status" in [Status."Feature Status"::Complete, Status."Feature Status"::Enabled] then
                            Error(UnsafeStateErr, Company.Name);
            until Company.Next() = 0;
    end;

    var
        FeatureKeyIdTok: Label 'BankingAndPaymentsFI', Locked = true;
        ManagementRequiredErr: Label 'Prepare the controlled Finnish banking upgrade from an authenticated management session with tenant-wide SUPER permissions, before acquiring tenant exclusive access.';
        InvalidVersionErr: Label 'Specify the exact target Finnish banking app version as four non-negative integers: major.minor.build.revision.';
        HigherVersionErr: Label 'The requested Finnish banking app version must be higher than the installed version %1.', Comment = '%1 = installed app version';
        AlreadyMigratedErr: Label 'Finnish banking migration is already complete in this company. A second preparation or disable-and-recopy transition is not supported.';
        RequestConflictErr: Label 'This company already has a different Finnish banking upgrade request. Keep the existing request and resolve deployment recovery explicitly; do not prepare another target.';
        ControlledUpgradeRequiredErr: Label 'A controlled upgrade is required for Finnish banking. An administrator must prepare this company for an exact higher app version, acquire tenant exclusive access before publishing that target package, and run the real app data upgrade. Ordinary feature activation cannot copy historical data.';
        ControlledUpgradeDescriptionTxt: Label 'First install inactive. Before locking, an authenticated management administrator must prepare every selected company for an exact higher app version. Do not publish that target until native tenant exclusive access is acquired: it disconnects existing client sessions and denies new ones for the entire tenant. Then publish the target and run the real app data upgrade with the exclusive-access ticket. The lifecycle preserves retained data and audit fields, remaps stored references and tags completion transactionally. This task only validates lifecycle completion and finishes the current company feature status; it never copies data. Keep exclusive access on any failure for explicit recovery, never release it unconditionally, and release only after every requested company passes activation checks. Never log or persist tickets.';
        ProvisioningRequiredErr: Label 'Finnish banking requires the platform feature key BankingAndPaymentsFI to exist, be enabled for All Users and declare Data Update Required. Coordinate global enablement and pending company statuses before preparation; do not reset migrated companies.';
        PendingStatusRequiredErr: Label 'Finnish banking requires a Pending, data-update-required status for this company with no scheduled or running feature task. Coordinate provisioning or recover the failed controlled upgrade explicitly; no status has been reset.';
        UnsafeStateErr: Label 'Finnish banking company %1 has inconsistent migration and feature status. Stop the cutover and recover explicitly; disabling, resetting or recopying a migrated company is unsafe.', Comment = '%1 = company name';
}
#endif
