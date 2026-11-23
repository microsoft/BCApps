// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AS0007
namespace Microsoft.Agent.SalesOrderAgent;

using System.Agents;
using System.AI;
using System.Environment;
using System.Upgrade;

codeunit 4589 "SOA Upgrade"
{
    Access = Internal;
    Subtype = Upgrade;

    InherentEntitlements = X;
    InherentPermissions = X;

    var
        SOAImpl: Codeunit "SOA Impl";
        FailedToUpdateSOAInstructionsTxt: Label 'Failed to update SOA agent instructions during upgrade.', Locked = true;
        SkippedAgentIdentityUpgradeTxt: Label 'SOA agent identity upgrade skipped because the agent state could not be read. The upgrade tag was not set.', Locked = true;
        SkippedInstructionsUpgradeTxt: Label 'SOA agent instructions were not refreshed because the agent state could not be read.', Locked = true;
#if not CLEAN29
        SkippedKPIRecordsTxt: Label 'SOA KPI upgrade: %1 legacy records could not be attributed to an agent and were discarded.', Locked = true;
#endif

    trigger OnUpgradePerDatabase()
    begin
        RegisterCapability();
        AddBillingTypeToCapability();
    end;

    trigger OnUpgradePerCompany()
    begin
        AlwaysUpdateAgentInstructionsOnUpgrade();
        AddDailyEmailLimit();
        UpgradeUserSecurityIDField();
        SetMarkEmailAsRead();
        UpgradeOwnerUserSecurityID();
        UpgradeAgentIdentity();
        ResetReplyAttempts();
#if not CLEAN29
        UpgradeSOAKPIToPerAgent();
#endif
    end;

    // This procedure intentionally runs on every upgrade without an upgrade tag.
    // Agent instructions are embedded in the extension's resource files and may change with each version.
    // Re-applying them on every upgrade ensures the agent always uses the instructions shipped with the current extension.
    local procedure AlwaysUpdateAgentInstructionsOnUpgrade()
    var
        SOASetupRec: Record "SOA Setup";
        TempSOASetup: Record "SOA Setup" temporary;
        AgentRec: Record Agent;
        SOASetupCU: Codeunit "SOA Setup";
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if not EnvironmentInformation.IsSaaSInfrastructure() then
            exit;

        // The archived check treats an unreadable agent as archived, so record why nothing was refreshed.
        if not AgentRec.ReadPermission() then begin
            Session.LogMessage('0000V3P', SkippedInstructionsUpgradeTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'SOA Upgrade');
            exit;
        end;

        if not SOASetupRec.FindSet() then
            exit;

        repeat
            // Archived agents are read-only, so instructions cannot and need not be refreshed for them.
            // This is a write path, so it uses the check that blocks when the state cannot be read.
            if not SOASetupCU.MustTreatAgentAsArchived(SOASetupRec."User Security ID") then begin
                TempSOASetup := SOASetupRec;
                TempSOASetup.Insert();
                if not TryUpdateAgentInstructions(SOASetupRec, TempSOASetup) then
                    Session.LogMessage('0000U1P', FailedToUpdateSOAInstructionsTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'SOA Upgrade', 'ErrorCallStack', GetLastErrorCallStack());
                TempSOASetup.DeleteAll();
            end;
        until SOASetupRec.Next() = 0;
    end;

    [TryFunction]
    local procedure TryUpdateAgentInstructions(var SOASetupRec: Record "SOA Setup"; var TempSOASetup: Record "SOA Setup" temporary)
    var
        SOASetupCU: Codeunit "SOA Setup";
    begin
        SOASetupCU.UpdateInstructions(TempSOASetup);

        if SOASetupRec."Instructions Last Sync At" <> TempSOASetup."Instructions Last Sync At" then begin
            SOASetupRec."Instructions Last Sync At" := TempSOASetup."Instructions Last Sync At";
            SOASetupRec.Modify();
        end;
    end;

    local procedure RegisterCapability()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag(GetRegisterSalesOrderAgentCapabilityTag()) then begin
            SOAImpl.RegisterCapability();

            UpgradeTag.SetUpgradeTag(GetRegisterSalesOrderAgentCapabilityTag());
        end;
    end;

    local procedure AddBillingTypeToCapability()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        CopilotCapability: Codeunit "Copilot Capability";
        EnvironmentInformation: Codeunit "Environment Information";
        LearnMoreUrlTxt: Label 'https://go.microsoft.com/fwlink/?linkid=2281481', Locked = true;
    begin
        if not UpgradeTag.HasUpgradeTag(GetAddBillingTypeToSOACapabilityTag()) then begin
            if EnvironmentInformation.IsSaaSInfrastructure() then
                if CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"Sales Order Agent") then
                    CopilotCapability.ModifyCapability(Enum::"Copilot Capability"::"Sales Order Agent", Enum::"Copilot Availability"::"Generally Available", Enum::"Copilot Billing Type"::"Microsoft Billed", LearnMoreUrlTxt);

            UpgradeTag.SetUpgradeTag(GetAddBillingTypeToSOACapabilityTag());
        end;
    end;

    local procedure UpgradeUserSecurityIDField()
    var
        DummySOASetup: Record "SOA Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        SOADataTransfer: DataTransfer;
    begin
        if UpgradeTag.HasUpgradeTag(GetUserSecurityIDUpgradeTag()) then
            exit;
        SOADataTransfer.SetTables(Database::"SOA Setup", Database::"SOA Setup");
        SOADataTransfer.AddFieldValue(DummySOASetup.FieldNo("Agent User Security ID"), DummySOASetup.FieldNo("User Security ID"));
        SOADataTransfer.CopyFields();

        UpgradeTag.SetUpgradeTag(GetUserSecurityIDUpgradeTag());
    end;

    local procedure AddDailyEmailLimit()
    var
        SOASetup: Record "SOA Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag(GetSetDailyEmailLimitTag()) then begin
            // Every agent gets the limit, because the tag is set afterwards and this never runs again.
            if SOASetup.FindSet() then
                repeat
                    SOASetup."Message Limit" := SOASetup.GetDefaultMessageLimit();
                    SOASetup.Modify();
                until SOASetup.Next() = 0;

            UpgradeTag.SetUpgradeTag(GetSetDailyEmailLimitTag());
        end;
    end;

    local procedure SetMarkEmailAsRead()
    var
        SOASetup: Record "SOA Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if not UpgradeTag.HasUpgradeTag(GetSetMarkEmailAsReadTag()) then begin
            // Every agent is upgraded, because the tag is set afterwards and this never runs again.
            if SOASetup.FindSet() then
                repeat
                    SOASetup."Mark Email As Read" := true;
                    SOASetup.Modify();
                until SOASetup.Next() = 0;

            UpgradeTag.SetUpgradeTag(GetSetMarkEmailAsReadTag());
        end;
    end;

    local procedure UpgradeAgentIdentity()
    var
        SOASetup: Record "SOA Setup";
        AgentRec: Record Agent;
        SOASetupCU: Codeunit "SOA Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        IsModified: Boolean;
    begin
        if UpgradeTag.HasUpgradeTag(GetAgentIdentityTag()) then
            exit;

        // The archived check treats an unreadable agent as archived, which would skip every setup record.
        // Leaving the tag unset lets a later upgrade run do the work rather than marking it done.
        if not AgentRec.ReadPermission() then begin
            Session.LogMessage('0000V3Q', SkippedAgentIdentityUpgradeTxt, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'SOA Upgrade');
            exit;
        end;

        if SOASetup.FindSet() then
            repeat
                // Archived agents keep the identity they had; their name and initials are free to reuse.
                // This is a write path, so it uses the check that blocks when the state cannot be read.
                if not SOASetupCU.MustTreatAgentAsArchived(SOASetup."User Security ID") then begin
                    IsModified := false;

                    if SOASetup."Agent Name" = '' then begin
                        SOASetup."Agent Name" := CopyStr(SOASetupCU.GetSOAUserDisplayName(), 1, MaxStrLen(SOASetup."Agent Name"));
                        IsModified := true;
                    end;

                    if SOASetup."Agent Initials" = '' then begin
                        SOASetup."Agent Initials" := SOASetupCU.GetInitials();
                        IsModified := true;
                    end;

                    if IsModified then
                        SOASetup.Modify();
                end;
            until SOASetup.Next() = 0;

        UpgradeTag.SetUpgradeTag(GetAgentIdentityTag());
    end;

    local procedure UpgradeOwnerUserSecurityID()
    var
        SOASetup: Record "SOA Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        IsModified: Boolean;
    begin
        if UpgradeTag.HasUpgradeTag(GetOwnerUserSecurityIDTag()) then
            exit;

        if SOASetup.FindSet() then
            repeat
                IsModified := false;
                if IsNullGuid(SOASetup."Owner User Security ID") and (not IsNullGuid(SOASetup."User Security ID")) then begin
                    SOASetup."Owner User Security ID" := SOASetup."User Security ID";
                    IsModified := true;
                end;

                if IsModified then
                    SOASetup.Modify();
            until SOASetup.Next() = 0;

        UpgradeTag.SetUpgradeTag(GetOwnerUserSecurityIDTag());
    end;

#if not CLEAN29
    local procedure UpgradeSOAKPIToPerAgent()
    var
        SOASetup: Record "SOA Setup";
        LegacySOAKPI: Record "SOA KPI";
        SOAKPISummary: Record "SOA KPI Summary";
        SOASetupCU: Codeunit "SOA Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        TargetAgentSecurityID: Guid;
        SkippedRecords: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(GetSOAKPIPerAgentTag()) then
            exit;

        if not LegacySOAKPI.FindSet() then begin
            UpgradeTag.SetUpgradeTag(GetSOAKPIPerAgentTag());
            exit;
        end;

        // Legacy KPI records predate per agent tracking, so they are attributed to an agent that is still
        // in use, because the KPI pages never show an archived agent. When every agent is archived the
        // history is still migrated onto one of them rather than dropped, since the table is deleted below.
        if SOASetupCU.FindFirstNonArchivedSetup(SOASetup) and (not IsNullGuid(SOASetup."User Security ID")) then
            TargetAgentSecurityID := SOASetup."User Security ID"
        else begin
            SOASetup.Reset();
            if SOASetup.FindFirst() then
                TargetAgentSecurityID := SOASetup."User Security ID";
        end;

        repeat
            if IsNullGuid(LegacySOAKPI."User Security ID") then begin
                if not IsNullGuid(TargetAgentSecurityID) then
                    MergeSOAKPIIntoSummary(SOAKPISummary, LegacySOAKPI, TargetAgentSecurityID)
                else
                    SkippedRecords += 1;
            end else
                MergeSOAKPIIntoSummary(SOAKPISummary, LegacySOAKPI, LegacySOAKPI."User Security ID");
        until LegacySOAKPI.Next() = 0;

        if SkippedRecords > 0 then
            Session.LogMessage('0000UAO', StrSubstNo(SkippedKPIRecordsTxt, SkippedRecords), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', 'SOA Upgrade');

        LegacySOAKPI.DeleteAll();

        UpgradeTag.SetUpgradeTag(GetSOAKPIPerAgentTag());
    end;

    local procedure MergeSOAKPIIntoSummary(var SOAKPISummary: Record "SOA KPI Summary"; LegacySOAKPI: Record "SOA KPI"; TargetAgentSecurityID: Guid)
    begin
        SOAKPISummary.GetSafe(TargetAgentSecurityID);

        SOAKPISummary."Received Emails" += LegacySOAKPI."Received Emails";
        SOAKPISummary."Total Emails" += LegacySOAKPI."Total Emails";
        SOAKPISummary."Total Quotes Created" += LegacySOAKPI."Total Quotes Created";
        SOAKPISummary."Total Orders Created" += LegacySOAKPI."Total Orders Created";
        SOAKPISummary."Total Amount Orders" += LegacySOAKPI."Total Amount Orders";
        if LegacySOAKPI."Last Updated DateTime" > SOAKPISummary."Last Updated DateTime" then
            SOAKPISummary."Last Updated DateTime" := LegacySOAKPI."Last Updated DateTime";

        SOAKPISummary.Modify();
    end;
#endif

    // Attempt counts recorded before the Failed status existed represented terminal state on their own, and messages
    // that had used up their budget were skipped indefinitely while still sitting in Reviewed. Clearing the counters
    // lets those messages be attempted again and reach the real Failed status, instead of migrating a private flag.
    local procedure ResetReplyAttempts()
    var
        SOAReplyAttempt: Record "SOA Reply Attempt";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetResetReplyAttemptsTag()) then
            exit;

        SOAReplyAttempt.DeleteAll();

        UpgradeTag.SetUpgradeTag(GetResetReplyAttemptsTag());
    end;

    internal procedure GetRegisterSalesOrderAgentCapabilityTag(): Code[250]
    begin
        exit('MS-539550-SalesOrderAgentCapability-20240802');
    end;

    internal procedure GetAddBillingTypeToSOACapabilityTag(): Code[250]
    begin
        exit('MS-581366-BillingTypeToSalesOrderAgentCapability-20250731');
    end;

    internal procedure GetSetDailyEmailLimitTag(): Code[250]
    begin
        exit('MS-597734-DailyEmailLimit-20250822');
    end;

    local procedure GetUserSecurityIDUpgradeTag(): Code[250]
    begin
        exit('MS-597811-UserSecurityIDField-20251114');
    end;

    internal procedure GetSetMarkEmailAsReadTag(): Code[250]
    begin
        exit('MS-621547-MarkEmailAsRead-20260521');
    end;

    internal procedure GetAgentIdentityTag(): Code[250]
    begin
        exit('MS-635120-AgentIdentity-20260615');
    end;

#if not CLEAN29
    internal procedure GetSOAKPIPerAgentTag(): Code[250]
    begin
        exit('MS-635420-SOAKPI-PerAgent-20260616');
    end;
#endif

    internal procedure GetOwnerUserSecurityIDTag(): Code[250]
    begin
        exit('MS-635860-OwnerUserSecurityID-20260617');
    end;

    internal procedure GetResetReplyAttemptsTag(): Code[250]
    begin
        exit('MS-647024-ResetReplyAttempts-20260819');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerDatabaseUpgradeTags, '', false, false)]
    local procedure RegisterPerDatabaseUpgradeTags(var PerDatabaseUpgradeTags: List of [Code[250]])
    begin
        PerDatabaseUpgradeTags.Add(GetAddBillingTypeToSOACapabilityTag());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerCompanyUpgradeTags, '', false, false)]
    local procedure RegisterPerCompanyUpgradeTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetSetDailyEmailLimitTag());
        PerCompanyUpgradeTags.Add(GetSetMarkEmailAsReadTag());
        PerCompanyUpgradeTags.Add(GetOwnerUserSecurityIDTag());
        PerCompanyUpgradeTags.Add(GetAgentIdentityTag());
        PerCompanyUpgradeTags.Add(GetResetReplyAttemptsTag());
#if not CLEAN29
        PerCompanyUpgradeTags.Add(GetSOAKPIPerAgentTag());
#endif
    end;
}
