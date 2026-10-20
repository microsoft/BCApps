// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using Microsoft.EServices.EDocumentConnector.Microsoft365;
using Microsoft.Purchases.History;
using System.Agents;
using System.Reflection;
using System.AI;
using System.Azure.KeyVault;
using System.Config;
using System.Email;
using System.Environment.Configuration;
using System.Security.AccessControl;
using System.Security.Encryption;

codeunit 3307 "Payables Agent Setup"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    Permissions =
        tabledata "PA Known Sender" = r;

    #region Setup makeup
    // Logic on top of "PA Detailed Setup". This is what this codeunit is meant to contain.

    /// <summary>
    /// The profile the agent gets on activation, as derived for the active Payables Agent version.
    /// </summary>
    procedure GetAgentProfile(var TempAllProfile: Record "All Profile" temporary)
    var
        TempPADetailedSetup: Record "PA Detailed Setup";
        Agent: Codeunit Agent;
        ModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ModuleInfo);
        PASetup.GetSetup(TempPADetailedSetup);
        Agent.PopulateDefaultProfile(TempPADetailedSetup."Agent Profile", ModuleInfo.Id, TempAllProfile);
    end;

    /// <summary>
    /// The permission set the agent gets on activation, as derived for the active Payables Agent version.
    /// </summary>
    procedure GetAgentAccessControls(var TempAccessControlBuffer: Record "Access Control Buffer" temporary)
    var
        TempPADetailedSetup: Record "PA Detailed Setup";
        ModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ModuleInfo);
        PASetup.GetSetup(TempPADetailedSetup);
        TempAccessControlBuffer.Init();
        TempAccessControlBuffer."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(TempAccessControlBuffer."Company Name"));
        TempAccessControlBuffer.Scope := TempAccessControlBuffer.Scope::System;
        TempAccessControlBuffer."App ID" := ModuleInfo.Id;
        TempAccessControlBuffer."Role ID" := TempPADetailedSetup."Agent Permission Set";
        TempAccessControlBuffer.Insert();
    end;

    /// <summary>
    /// Whether the agent exists and is enabled.
    /// </summary>
    internal procedure IsAgentEnabled(): Boolean
    var
        Agent: Record Agent;
        TempPADetailedSetup: Record "PA Detailed Setup";
    begin
        PASetup.GetSetup(TempPADetailedSetup);
        if not Agent.Get(TempPADetailedSetup."User Security Id") then
            exit(false);
        exit(Agent.State = Agent.State::Enabled);
    end;

    /// <summary>
    /// Whether a mailbox folder (rather than the whole mailbox) is monitored.
    /// </summary>
    internal procedure MonitoredFolderConfigured(TempPADetailedSetup: Record "PA Detailed Setup"): Boolean
    begin
        exit(TempPADetailedSetup."Email Folder" <> '');
    end;

    /// <summary>
    /// Retrieves the agent record if configured in the database, and ensures that the Payables Agent setup record is updated with the correct user security id. 
    /// </summary>
    /// <param name="Agent">Record where the Agent is loaded, if it exists</param>
    /// <returns>True if an Agent was found, false otherwise</returns>
    procedure GetAgent(var Agent: Record Agent): Boolean
    begin
        exit(GetAgent(Agent, true));
    end;

    /// <summary>
    /// Retrieves the agent record if configured in the database, and optionally ensures that the Payables Agent setup record is updated with the correct user security id. 
    /// </summary>
    /// <param name="Agent">Record where the Agent is loaded, if it exists</param>
    /// <param name="UpdateSetup">If true, the Payables Agent Setup record will be updated with the correct user security id if it was not configured or was invalid</param>
    /// <returns>True if an Agent was found, false otherwise</returns>
    procedure GetAgent(var Agent: Record Agent; UpdateSetup: Boolean): Boolean
    var
        TempPADetailedSetup: Record "PA Detailed Setup";
    begin
        // When the setup does not exist and we are not allowed to create it, we continue with a blank setup, so the agent can still be located by user name.
        if PASetup.GetSetup(TempPADetailedSetup, UpdateSetup) then;
        // We attempt to find the agent by the security id stored in the setup.
        if Agent.Get(TempPADetailedSetup."User Security Id") then
            exit(true);
        // If the agent could not be found, and there was a user security id configured, we need to clear it, since it is not valid anymore.
        if not IsNullGuid(TempPADetailedSetup."User Security Id") then
            Clear(TempPADetailedSetup."User Security Id");
        // If the agent could not be found from the configured security id, we attempt to find it by the user name.
        Agent.SetRange("User Name", AgentUserName());
        if Agent.FindFirst() then
            TempPADetailedSetup."User Security Id" := Agent."User Security ID";
        if UpdateSetup then
            PASetup.SaveUserSecurityId(TempPADetailedSetup."User Security Id");
        exit(not IsNullGuid(Agent."User Security ID"));
    end;

    #endregion

    #region Agent identity and telemetry
    // Recommendation: move to Bootstrap/. These describe the agent itself (names, summary, telemetry category), not the
    // setup. Note that the summary still describes the draft-based (v1) agent.

    internal procedure AgentUserName(): Code[50]
    begin
        exit(CopyStr(AgentUserNameLbl + ' - ' + CompanyName(), 1, 50));
    end;

    internal procedure AgentDisplayName(): Text[80]
    begin
        exit(CopyStr(AgentDisplayNameLbl, 1, 80));
    end;

    internal procedure AgentSummary(): Text
    begin
        exit(AgentSummaryLbl);
    end;

    internal procedure FeatureName(): Text
    begin
        exit(PayablesAgentTelemetryTok);
    end;

    #endregion

    #region Agent instructions
    // Recommendation: move to its own codeunit (for example Bootstrap/Instructions/). Make the prompt resource a derived
    // field of "PA Detailed Setup" (like "Agent Profile"), so the v2 instructions get applied: today the v1 prompts are
    // always used.

    internal procedure SetAgentInstructions(AgentUserSecurityId: Guid)
    begin
        if IsNullGuid(AgentUserSecurityId) then
            exit;

        PASetup.SaveAppliedInstrConfigHash(ApplyAgentInstructions(AgentUserSecurityId));
    end;

    /// <summary>
    /// Applies the agent instructions for the given user and returns the configuration hash that was used.
    /// This helper does NOT save the hash, allowing callers that are about to save the whole setup (such as
    /// "PA Setup Update") to save it together with the rest of the setup.
    /// </summary>
    internal procedure ApplyAgentInstructions(AgentUserSecurityId: Guid) ConfigHash: Text[64]
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        Agent: Codeunit Agent;
        SecurityPromptSecretText, CompletePromptSecretText : SecretText;
        PayablesAgentPromptText: Text;
        AgentDriven: Boolean;
    begin
        AgentDriven := IsAgentDrivenLineMatchingEnabled();
        if AgentDriven then
            PayablesAgentPromptText := NavApp.GetResourceAsText(PayablesAgentAgentDrivenPromptTok, TextEncoding::UTF8)
        else
            PayablesAgentPromptText := NavApp.GetResourceAsText(PayablesAgentPromptTok, TextEncoding::UTF8);
        if AzureKeyVault.GetAzureKeyVaultSecret(SecurityPromptTok, SecurityPromptSecretText) then
            CompletePromptSecretText := SecretText.SecretStrSubstNo(PayablesAgentPromptText, SecurityPromptSecretText)
        else begin
            Session.LogMessage('0000QPX', 'Failed to retrieve security prompt', Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', FeatureName());
            Error(UnableToConfigureAgentInstructionsErr);
        end;
        Agent.SetInstructions(AgentUserSecurityId, CompletePromptSecretText);

        ConfigHash := CopyStr(GetInstructionsConfigHash(), 1, MaxStrLen(ConfigHash));
    end;

    /// <summary>
    /// Feature-specific resolver for the agent-driven line-matching experiment, used to select the prompt variant.
    /// </summary>
    internal procedure IsAgentDrivenLineMatchingEnabled(): Boolean
    var
        FeatureConfiguration: Codeunit "Feature Configuration";
    begin
        exit(FeatureConfiguration.GetConfiguration(AgentDrivenLineMatchingTok) = AgentDrivenTreatmentTok);
    end;

    /// <summary>
    /// Reconciles the agent's persisted instructions with the current experiment configuration.
    /// The agent instructions are set once (at creation/upgrade), but tenant-level ECS experiments can change
    /// independently; this reapplies the instructions when the configuration that produced them has drifted.
    /// Cheap on the common path: it only reloads instructions when the config hash has actually changed.
    /// </summary>
    internal procedure EnsureAgentInstructionsMatchConfiguration(AgentUserSecurityId: Guid)
    var
        TempPADetailedSetup: Record "PA Detailed Setup";
    begin
        if IsNullGuid(AgentUserSecurityId) then
            exit;
        PASetup.GetSetup(TempPADetailedSetup);
        if TempPADetailedSetup."Applied Instr. Config Hash" = GetInstructionsConfigHash() then
            exit;
        Session.LogMessage('0000SEK', 'Payables Agent instructions reapplied due to experiment configuration drift.', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', FeatureName());
        SetAgentInstructions(AgentUserSecurityId);
    end;

    /// <summary>
    /// Non-throwing wrapper around EnsureAgentInstructionsMatchConfiguration for callers on a critical path where an instruction-refresh failure must not abort the
    /// host operation. Returns false on failure so the caller can log and continue with existing instructions.
    /// </summary>
    [TryFunction]
    internal procedure TryEnsureAgentInstructionsMatchConfiguration(AgentUserSecurityId: Guid)
    begin
        EnsureAgentInstructionsMatchConfiguration(AgentUserSecurityId);
    end;

    /// <summary>
    /// Fingerprint of every tenant-level experiment configuration that influences the agent's instructions.
    /// Generic on purpose: a future prompt-affecting experiment only needs its key added to
    /// GetInstructionsExperimentKeys (and its value consumed in prompt selection) — no new setup field required.
    /// </summary>
    internal procedure GetInstructionsConfigHash(): Text
    var
        FeatureConfiguration: Codeunit "Feature Configuration";
        CryptographyManagement: Codeunit "Cryptography Management";
        ConfigKey: Text;
        Signature: TextBuilder;
        HashAlgorithmType: Option MD5,SHA1,SHA256,SHA384,SHA512;
    begin
        foreach ConfigKey in GetInstructionsExperimentKeys() do begin
            Signature.Append(ConfigKey);
            Signature.Append('=');
            Signature.Append(FeatureConfiguration.GetConfiguration(ConfigKey));
            Signature.Append(';');
        end;
        exit(CryptographyManagement.GenerateHash(Signature.ToText(), HashAlgorithmType::SHA256));
    end;

    local procedure GetInstructionsExperimentKeys() Keys: List of [Text]
    begin
        // Tenant-level experiment keys whose ECS configuration changes the agent's instructions.
        // Add future prompt-affecting experiment keys here.
        Keys.Add(AgentDrivenLineMatchingTok);
    end;

    #endregion

    #region Who can create and use the agent
    // Recommendation: move to an access/eligibility codeunit (Bootstrap/ or Setup/). These are rules about users and
    // posted purchase invoices; they do not read the setup.

    internal procedure CanShowAgentActions(): Boolean
    var
        Agent: Record Agent;
        PayablesAgentSetup: Codeunit "Payables Agent Setup";
        AgentUtilities: Codeunit "Agent Utilities";
        CopilotCapability: Codeunit "Copilot Capability";
    begin
        if not AgentUtilities.IsAgentsFeatureEnabled() then
            exit(false);
        if not CopilotCapability.IsCapabilityActive("Copilot Capability"::"Payables Agent") then
            exit(false);
        if not PayablesAgentSetup.GetAgent(Agent) then
            exit(AllowCreateNewAgent());

        // Payables Agent is created. It has to be enabled and user has to have permissions to use it in order to show the agent actions.
        if Agent.State = Agent.State::Disabled then
            exit(false);

        exit(Agent."Can Current User Use Agent");
    end;

    /// <summary>
    /// Returns true if a new Payables Agent can be created.
    /// Blocked if an agent already exists. Otherwise allowed for SUPER users
    /// or any user who has created a posted purchase invoice.
    /// </summary>
    internal procedure AllowCreateNewAgent(): Boolean
    var
        Agent: Record Agent;
        PayablesAgentSetup: Codeunit "Payables Agent Setup";
        AgentSystemPermissions: Codeunit "Agent System Permissions";
        AgentUtilities: Codeunit "Agent Utilities";
        CopilotCapability: Codeunit "Copilot Capability";
    begin
        if not AgentUtilities.IsAgentsFeatureEnabled() then
            exit(false);
        if not CopilotCapability.IsCapabilityActive("Copilot Capability"::"Payables Agent") then
            exit(false);
        if PayablesAgentSetup.GetAgent(Agent, false) then
            exit(false);

        // No payables agent exists
        if AgentSystemPermissions.CurrentUserHasCanManageAllAgentsPermission() then
            exit(true);
        if not AgentUtilities.CanCurrentUserCreateAgent(Enum::"Agent Metadata Provider"::"Payables Agent") then
            exit(false);

        exit(HasUserCreatedPostedPurchInvoice());
    end;

    /// <summary>
    /// Computes is the session user has created a purchase invoice in the past 30 days. 
    /// This is used as a heuristic to determine if the user should be allowed to setup the agent. 
    /// </summary>
    /// <returns>true if the user has created a purchase invoice in the past 30 days, false otherwise.</returns>
    internal procedure HasUserCreatedPostedPurchInvoice(): Boolean
    var
        PurchaseInvHeader: Record "Purch. Inv. Header";
        Days30Ago: Date;
    begin
        Days30Ago := CalcDate('<-30D>', Today());

        PurchaseInvHeader.SetRange(SystemCreatedAt, CreateDateTime(Days30Ago, 0T), CurrentDateTime());
        PurchaseInvHeader.SetRange(SystemCreatedBy, UserSecurityId());
        exit(not PurchaseInvHeader.IsEmpty());
    end;

    /// <summary>
    /// Returns the list of non-agent user security IDs that have created posted purchase invoices in the past 30 days.
    /// This is used as a heuristic to determine which users should be given access to the agent.
    /// </summary>
    /// <returns>List of non-agent user security IDs that have created posted purchase invoices in the past 30 days.</returns>
    internal procedure GetUsersThatHaveCreatedPostedPurchInvoice(): List of [Guid]
    var
        User: Record User;
        PAPostedPurchInvUsers: Query "PA Posted Purch. Inv. Users";
        Users: List of [Guid];
        Days30Ago: Date;
    begin
        Days30Ago := CalcDate('<-30D>', Today());
        PAPostedPurchInvUsers.SetRange(SystemCreatedAt, CreateDateTime(Days30Ago, 0T), CurrentDateTime());
        PAPostedPurchInvUsers.Open();
        while PAPostedPurchInvUsers.Read() do
            if User.Get(PAPostedPurchInvUsers.SystemCreatedBy) then
                if User."License Type" <> User."License Type"::Agent then
                    Users.Add(PAPostedPurchInvUsers.SystemCreatedBy);
        PAPostedPurchInvUsers.Close();
        exit(Users);
    end;

    internal procedure InsertAccessControlForEligibleUsers(AgentUserSecurityId: Guid)
    var
        AgentAccessControl: Record "Agent Access Control";
        UserSecIds: List of [Guid];
        SecId: Guid;
    begin
        UserSecIds := GetUsersThatHaveCreatedPostedPurchInvoice();
        foreach SecId in UserSecIds do begin
            Clear(AgentAccessControl);

            // Platform Bug 630717: Access Control Table is virtual (Doing a if then on the insert does not capture the error, it gets surfaced)
            AgentAccessControl.SetRange("Agent User Security ID", AgentUserSecurityId);
            AgentAccessControl.SetRange("Company Name", CompanyName());
            AgentAccessControl.SetRange("User Security ID", SecId);
            if not AgentAccessControl.IsEmpty() then
                continue;

            AgentAccessControl."Agent User Security ID" := AgentUserSecurityId;
            AgentAccessControl."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(AgentAccessControl."Company Name"));
            AgentAccessControl."User Security ID" := SecId;
            AgentAccessControl.Insert();
        end;
    end;

    #endregion

    #region Incoming task review decision
    // Recommendation: move to TaskIntake/, next to Known Senders. These decide about a task (its source email, headers
    // and sender); the review policy of the setup is only one input.

    /// <summary>
    /// Decides whether a task must be reviewed by a human before the agent processes it, based on the configured
    /// review policy, the monitored folder, sender authentication (compauth / internal), and the known-senders list.
    /// </summary>
    procedure ShouldRequestReview(PATask: Codeunit "PA Task"): Boolean
    var
        KnownSender: Record "PA Known Sender";
        TempPADetailedSetup: Record "PA Detailed Setup";
        HeaderValue: Text;
        SenderAuthenticated: Boolean;
    begin
        // Only incoming emails are subject to email review. Manually uploaded documents
        // (e.g. the trial experience) are user-initiated and processed without review.
        if PATask.GetSourceType() <> "PA Source Type"::Email then
            exit(false);

        PASetup.GetSetup(TempPADetailedSetup);
        case TempPADetailedSetup."Email Review Policy" of
            "PA Email Review Policy"::Always,
            "PA Email Review Policy"::Unset:
                exit(true);
            "PA Email Review Policy"::Never:
                exit(false);
        end;

        // OnlyIfUntrusted: a configured subfolder is explicit consent, everything in it is trusted.
        if MonitoredFolderConfigured(TempPADetailedSetup) then
            exit(false);

        // Without an authenticated sender we always review. The sender is authenticated when composite
        // authentication passed (compauth=pass), or when the message originated inside the organization
        // (see IsSenderInternal). Missing email or headers means not authenticated.
        if PATask.TryGetEmailHeader('Authentication-Results', HeaderValue) then
            SenderAuthenticated := CompAuthPassed(HeaderValue);
        if not SenderAuthenticated then
            SenderAuthenticated := IsSenderInternal(PATask);
        if not SenderAuthenticated then
            exit(true);

        // Authenticated: trust senders explicitly approved in the known-senders list.
        if KnownSender.GetForTask(PATask, KnownSender) then
            exit(KnownSender."Sender Policy" <> "PA Sender Policy"::Approve);

        // Authenticated and unknown: trust internal (same-organization) senders.
        if IsSenderInternal(PATask) then
            exit(false);

        // Authenticated, unknown and external: review.
        exit(true);
    end;

    /// <summary>
    /// Returns true when the task's source email was stamped by Exchange as originating inside the
    /// organization (X-MS-Exchange-Organization-AuthAs = Internal). This covers intra-tenant mail (e.g.
    /// same onmicrosoft.com domain), which is not stamped with compauth. Exchange re-stamps this header
    /// on inbound, so it cannot be spoofed by an external sender. Missing email or header yields false.
    /// </summary>
    procedure IsSenderInternal(PATask: Codeunit "PA Task"): Boolean
    var
        HeaderValue: Text;
    begin
        if PATask.TryGetEmailHeader('X-MS-Exchange-Organization-AuthAs', HeaderValue) then
            exit(LowerCase(HeaderValue).Trim() = 'internal');
        exit(false);
    end;

    /// <summary>
    /// Returns true when an Authentication-Results header value indicates compauth=pass.
    /// </summary>
    procedure CompAuthPassed(AuthenticationResults: Text): Boolean
    begin
        // Case-insensitive match; tolerates surrounding tokens and a trailing reason=NNN.
        exit(StrPos(LowerCase(AuthenticationResults), 'compauth=pass') > 0);
    end;

    #endregion

    #region Known senders presentation
    // Recommendation: move to the Known Senders entity or page. They only drive the Known Senders notification and the
    // setup page confirmation. PolicyLabel largely repeats the enum captions; Format(Policy) may be enough.

    /// <summary>
    /// Classifies whether a pending setup change would leave the known-senders list unused.
    /// Returns None when nothing curated would be ignored (including when the list is empty).
    /// </summary>
    procedure ClassifyKnownSendersUnusedByChange(NewPolicy: Enum "PA Email Review Policy"; NewMonitoredFolder: Text; var KnownSendersCount: Integer): Enum "PA Setup Change Impact"
    var
        KnownSender: Record "PA Known Sender";
    begin
        KnownSendersCount := KnownSender.Count();
        if KnownSendersCount = 0 then
            exit("PA Setup Change Impact"::None);
        exit(ClassifyByPolicyAndFolder(NewPolicy, NewMonitoredFolder));
    end;

    /// <summary>
    /// Classifies why the known-senders list is currently unused in a saved setup, regardless of
    /// whether the list has entries. Used by the Known Senders page to surface a notification.
    /// </summary>
    procedure ClassifyKnownSendersUnusedReason(SavedPolicy: Enum "PA Email Review Policy"; SavedMonitoredFolder: Text): Enum "PA Setup Change Impact"
    begin
        exit(ClassifyByPolicyAndFolder(SavedPolicy, SavedMonitoredFolder));
    end;

    local procedure ClassifyByPolicyAndFolder(Policy: Enum "PA Email Review Policy"; MonitoredFolder: Text): Enum "PA Setup Change Impact"
    begin
        if MonitoredFolder <> '' then
            exit("PA Setup Change Impact"::KnownSendersIgnoredByFolder);
        if Policy in [Policy::Always, Policy::Never] then
            exit("PA Setup Change Impact"::KnownSendersIgnoredByPolicy);
        exit("PA Setup Change Impact"::None);
    end;

    /// <summary>
    /// Returns the user-facing label for an "Email Review Policy" value, for interpolation into messages.
    /// </summary>
    procedure PolicyLabel(Policy: Enum "PA Email Review Policy"): Text
    var
        AlwaysLbl: Label 'Always';
        NeverLbl: Label 'Never';
        OnlyIfUntrustedLbl: Label 'Manage per sender';
    begin
        case Policy of
            Policy::Always:
                exit(AlwaysLbl);
            Policy::Never:
                exit(NeverLbl);
            Policy::OnlyIfUntrusted:
                exit(OnlyIfUntrustedLbl);
        end;
        exit('');
    end;

    #endregion

    #region Setup page interactions
    // Recommendation: move next to the setup page (Setup/). SelectEmailAccount uses the e-document connector's mailbox
    // picker, so v2 needs a picker based on the Email module; OpenAdditionalFieldsSetup only forwards to v1.

    /// <summary>
    /// Lets the user pick the Microsoft 365 mailbox to monitor.
    /// </summary>
    /// <returns>True when a mailbox was picked; the account id and address are then updated.</returns>
    internal procedure SelectEmailAccount(var EmailAccountId: Guid; var EmailAddress: Text): Boolean
    var
        TempEmailAccount: Record "Email Account" temporary;
        OutlookIntegration: Codeunit "Outlook Integration Impl.";
    begin
        TempEmailAccount."Account Id" := EmailAccountId;
        TempEmailAccount.Connector := "Email Connector"::"Microsoft 365";
        if not OutlookIntegration.SelectEmailAccount(TempEmailAccount) then
            exit(false);
        EmailAccountId := TempEmailAccount."Account Id";
        EmailAddress := TempEmailAccount."Email Address";
        exit(true);
    end;

    /// <summary>
    /// Opens the configuration of the additional purchase line fields, when the active Payables Agent version supports
    /// it. Commits.
    /// </summary>
    /// <returns>True when the configuration was confirmed.</returns>
    internal procedure OpenAdditionalFieldsSetup(TempPADetailedSetup: Record "PA Detailed Setup"): Boolean
    var
        PADraftBasedSetup: Codeunit "PA Draft Based Setup";
    begin
        if not TempPADetailedSetup."Supports Additional Fields" then
            exit(false);
        exit(PADraftBasedSetup.OpenAdditionalFieldsSetup());
    end;

    #endregion

    #region Company lifecycle
    // Recommendation: move to Bootstrap/. It reacts to a company being copied and also clears the KPIs, which are not
    // setup.

    [EventSubscriber(ObjectType::Report, Report::"Copy Company", 'OnAfterCreatedNewCompanyByCopyCompany', '', false, false)]
    local procedure HandleOnAfterCreatedNewCompanyByCopyCompany(NewCompanyName: Text[30])
    var
        PayablesAgentKPI: Record "Payables Agent KPI";
    begin
        PASetup.DeleteSetup(NewCompanyName);

        PayablesAgentKPI.ChangeCompany(NewCompanyName);
        PayablesAgentKPI.DeleteAll();
    end;

    #endregion

    var
        PASetup: Codeunit "PA Setup";
        AgentUserNameLbl: Label 'Payables Agent', Comment = 'User name of the agent.', Locked = true;
        AgentSummaryLbl: Label 'Monitors incoming emails for vendor invoices, matches senders to registered vendors, and creates purchase document drafts for review.';
        AgentDisplayNameLbl: Label 'Payables Agent', Locked = true, Comment = 'Display name of the agent.';
        PayablesAgentTelemetryTok: Label 'Payables Agent', Locked = true;
        PayablesAgentPromptTok: Label '_DraftBasedPayablesAgent/Prompts/PayablesAgent-AgentInstructions.md', Locked = true;
        PayablesAgentAgentDrivenPromptTok: Label '_DraftBasedPayablesAgent/Prompts/PayablesAgent-AgentInstructions-AgentDriven.md', Locked = true;
        SecurityPromptTok: Label 'PayablesAgent-SecurityPromptV280', Locked = true;
        UnableToConfigureAgentInstructionsErr: Label 'Unable to configure agent instructions.';
        AgentDrivenLineMatchingTok: Label 'PAAgentDrivenLineMatching', Locked = true;
        AgentDrivenTreatmentTok: Label 'agent_driven', Locked = true;
}