// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;
using System.Agents;
using System.Environment.Configuration;
using System.Privacy;
using System.Upgrade;

codeunit 6978 "Upgrade Expense Agent Setup"
{
    Access = Internal;
    Subtype = Upgrade;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnUpgradePerDatabase()
    var
        InstallExpenseAgentSetup: Codeunit "Install Expense Agent Setup";
    begin
        // Registered on every upgrade (not gated by an upgrade tag) so environments provisioned
        // through the app-sync/upgrade path still get the capability registered. RegisterCapability
        // is idempotent via IsCapabilityRegistered, so it is a no-op when already registered and
        // leaves the admin's activation state untouched.
        InstallExpenseAgentSetup.RegisterCapability();
    end;

    trigger OnUpgradePerCompany()
    begin
        UpgradeAnthropicPrivacyNoticePerCompany();
        UpgradeClearStaleCopyCompanyState();
        UpgradeEnableCommunicationDefault();
    end;

    local procedure UpgradeClearStaleCopyCompanyState()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetClearStaleCopyCompanyStateUpgradeTag()) then
            exit;

        ClearStaleCopyCompanyStateIfNeeded();
        UpgradeTag.SetUpgradeTag(GetClearStaleCopyCompanyStateUpgradeTag());
    end;

    /// <summary>
    /// Migrates existing setups to the outgoing-communication model introduced with the
    /// "Enable Communication" master toggle and the no-reply-only send rule:
    /// 1. When no no-reply account is set but a main email account is, copy the main
    ///    account into the no-reply fields (previously outgoing emails fell back to the
    ///    main account; that fallback has been removed).
    /// 2. When the agent was enabled or a notification flag was already on (open-report
    ///    or approval), enable the new master toggle so those emails keep being sent.
    /// </summary>
    local procedure UpgradeEnableCommunicationDefault()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        UpgradeTag: Codeunit "Upgrade Tag";
        Modified: Boolean;
    begin
        if UpgradeTag.HasUpgradeTag(GetEnableCommunicationDefaultUpgradeTag()) then
            exit;

        if ExpenseAgentSetup.Get() then begin
            // 1. Preserve the previous "fall back to the main account" behavior by promoting the main email account to the no-reply account when unset.
            if IsNullGuid(ExpenseAgentSetup."Noreply Email Account ID") and not IsNullGuid(ExpenseAgentSetup."Email Account ID") then begin
                ExpenseAgentSetup."Noreply Email Account ID" := ExpenseAgentSetup."Email Account ID";
                ExpenseAgentSetup."Noreply Email Connector" := ExpenseAgentSetup."Email Connector";
                ExpenseAgentSetup."Noreply Email Address" := ExpenseAgentSetup."Email Address";
                Modified := true;
            end;

            // 2. Turn on the master toggle when the agent was enabled or an outgoing
            //    notification was already on, so previously-working outgoing emails
            //    (welcome, reimbursement, approval, reminders) keep being sent.
            if ExpenseAgentSetup."Enable Agent" or ExpenseAgentSetup."Enable Open Report Notif." or ExpenseAgentSetup."Enable Approval Notif." then
                if not ExpenseAgentSetup."Enable Communication" then begin
                    ExpenseAgentSetup."Enable Communication" := true;
                    Modified := true;
                end;

            if Modified then
                ExpenseAgentSetup.Modify();
        end;

        UpgradeTag.SetUpgradeTag(GetEnableCommunicationDefaultUpgradeTag());
    end;

    local procedure UpgradeAnthropicPrivacyNoticePerCompany()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        PrivacyNotice: Codeunit "Privacy Notice";
        ExpPrivacyNoticeReg: Codeunit "Exp. Privacy Notice Reg.";
        UpgradeTag: Codeunit "Upgrade Tag";
    begin
        if UpgradeTag.HasUpgradeTag(GetAnthropicPrivacyNoticeUpgradeTag()) then
            exit;

        if ExpenseAgentSetup.Get() and ExpenseAgentSetup."Enable Agent" then begin
            PrivacyNotice.CreateDefaultPrivacyNotices();
            if ExpPrivacyNoticeReg.IsAnthropicPrivacyNoticeRequired() then
                PrivacyNotice.SetApprovalState(ExpPrivacyNoticeReg.GetAnthropicName(), "Privacy Notice Approval State"::Agreed);
        end;

        UpgradeTag.SetUpgradeTag(GetAnthropicPrivacyNoticeUpgradeTag());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", OnGetPerCompanyUpgradeTags, '', false, false)]
    local procedure RegisterPerCompanyUpgradeTags(var PerCompanyUpgradeTags: List of [Code[250]])
    begin
        PerCompanyUpgradeTags.Add(GetAnthropicPrivacyNoticeUpgradeTag());
        PerCompanyUpgradeTags.Add(GetClearStaleCopyCompanyStateUpgradeTag());
        PerCompanyUpgradeTags.Add(GetEnableCommunicationDefaultUpgradeTag());
    end;

    /// <summary>
    /// Detects per-company Expense Agent state left over from a Copy Company performed on an
    /// earlier app version that did not wipe the source company's agent reference. The Agent
    /// record is system-wide and its user settings hold the company in which the agent was
    /// originally provisioned; when that company differs from the current company, the local
    /// Expense Agent Setup row is a stale copy and the agent does not really exist here. Wipe
    /// the per-company state so the user can reconfigure a fresh agent in this company.
    /// </summary>
    local procedure ClearStaleCopyCompanyStateIfNeeded()
    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        Agent: Record Agent;
        TempUserSettings: Record "User Settings" temporary;
        AgentCU: Codeunit Agent;
        InstallExpenseAgentSetup: Codeunit "Install Expense Agent Setup";
    begin
        if not ExpenseAgentSetup.Get() then
            exit;

        if IsNullGuid(ExpenseAgentSetup."User Security ID") then
            exit;

        if not Agent.Get(ExpenseAgentSetup."User Security ID") then
            exit;

        AgentCU.GetUserSettings(Agent."User Security ID", TempUserSettings);
        if TempUserSettings.Company = '' then
            exit;
        if TempUserSettings.Company = CopyStr(CompanyName(), 1, MaxStrLen(TempUserSettings.Company)) then
            exit;

        InstallExpenseAgentSetup.ClearPerCompanyAgentState('');
    end;

    local procedure GetAnthropicPrivacyNoticeUpgradeTag(): Code[250]
    begin
        exit('MS-621422-RegisterAnthropicPrivacyNotice-20260511');
    end;

    local procedure GetClearStaleCopyCompanyStateUpgradeTag(): Code[250]
    begin
        exit('MS-ExpenseAgent-ClearStaleCopyCompanyState-20260507');
    end;

    local procedure GetEnableCommunicationDefaultUpgradeTag(): Code[250]
    begin
        exit('MS-636970-EnableCommunicationDefault-20260701');
    end;
}