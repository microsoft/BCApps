// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Agents;
using System.Azure.Identity;
using System.Email;
using System.Environment;
using System.Privacy;
using System.Reflection;
using System.Security.AccessControl;
using System.Security.User;
using System.Utilities;

/// <summary>
/// The setup update process: loads the parameters for the setup page, and applies them, both when activating and
/// deactivating the agent. Agnostic of the Payables Agent version: it reads and saves the setup through "PA Setup"
/// ("PA Detailed Setup") and uses "Payables Agent Setup" (codeunit) for the logic on top of it.
/// </summary>
codeunit 3344 "PA Setup Update"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Fills the parameters with the current setup.
    /// </summary>
    internal procedure Load(var PASetupUpdateParameters: Codeunit "PA Setup Update Parameters")
    var
        Agent: Record Agent;
        TempPADetailedSetup: Record "PA Detailed Setup";
        TempAgentSetupBuffer: Record "Agent Setup Buffer";
        AgentSetup: Codeunit "Agent Setup";
    begin
        // Skipping configuring the Agent framework records is valid in tests
        if not PASetupUpdateParameters.GetSkipAgentConfiguration() then begin
            if PayablesAgentSetup.GetAgent(Agent) then;
            AgentSetup.GetSetupRecord(
                TempAgentSetupBuffer,
                Agent."User Security ID",
                "Agent Metadata Provider"::"Payables Agent",
                PayablesAgentSetup.AgentUserName(),
                PayablesAgentSetup.AgentDisplayName(),
                PayablesAgentSetup.AgentSummary()
            );
            PASetupUpdateParameters.SetAgentSetupBuffer(TempAgentSetupBuffer);
        end;

        PASetup.GetSetup(TempPADetailedSetup);
        PASetupUpdateParameters.SetDesiredSetup(TempPADetailedSetup);
    end;

    /// <summary>
    /// Applies the desired setup and performs what the update needs: consent, validation, trial, sample invoices,
    /// user access and the pending trial upload.
    /// </summary>
    internal procedure Update(var PASetupUpdateParameters: Codeunit "PA Setup Update Parameters")
    var
        AzureADGraphUser: Codeunit "Azure AD Graph User";
        PADemoGuide: Codeunit "PA Demo Guide";
        DelegatedAdminErr: Label 'Delegated admin and helpdesk users are not allowed to update the agent.';
        EmailMonitoringRequiresPrivacyConsentErr: Label 'Email monitoring requires privacy consent.';
        ReviewPolicyRequiredErr: Label 'Select an Email review option before turning on monitoring. This sets when incoming emails need supervisor approval before the agent processes them.';
    begin
        if AzureADGraphUser.IsUserDelegatedAdmin() or AzureADGraphUser.IsUserDelegatedHelpdesk() then
            Error(DelegatedAdminErr);

        Session.LogMessage('0000OUW', 'Setting up payables agent', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', PayablesAgentTelemetryTok);

        // Require an explicit review policy before monitoring can start.
        if PASetupUpdateParameters.Enabling() and PASetupUpdateParameters.MonitorEmail() and
            (PASetupUpdateParameters.GetEmailReviewPolicy() = "PA Email Review Policy"::Unset) then
            Error(ReviewPolicyRequiredErr);

        // Ask for email monitoring consent before any write transaction, since the consent dialog runs modally.
        if PASetupUpdateParameters.Enabling() and PASetupUpdateParameters.MonitorEmail() then
            if not ObtainConsent(PASetupUpdateParameters) then
                Error(EmailMonitoringRequiresPrivacyConsentErr);

        // Validation runs before any write transaction.
        if PASetupUpdateParameters.Enabling() then
            if not PASetupUpdateParameters.GetSkipEmailVerification() then begin
                PASetupUpdateParameters.SetLastActivated(CurrentDateTime());
                ValidateMailbox(PASetupUpdateParameters);
            end;

        // Initialize trial BEFORE creating the agent so IsEligibleForTrial() can detect first activation
        if PASetupUpdateParameters.Enabling() then
            InitializeTrialIfEligible();

        // First write transaction.
        ApplySetup(PASetupUpdateParameters);

        PADemoGuide.SendDemoEmail(PASetupUpdateParameters);

        // Give the users that have recently created posted purchase invoices access to the agent.
        PayablesAgentSetup.InsertAccessControlForEligibleUsers(PASetupUpdateParameters.GetDesiredSetup()."User Security Id");

        ProcessTrialUploadIfPending(PASetupUpdateParameters);
    end;

    /// <summary>
    /// Ensures the agent is activated. If the agent does not exist or is not enabled, it is activated silently with
    /// trial mode initialized if eligible. Email monitoring is not enabled.
    /// </summary>
    internal procedure EnsureActivated(var AlreadyActivated: Boolean)
    var
        PASetupUpdateParameters: Codeunit "PA Setup Update Parameters";
    begin
        if PayablesAgentSetup.IsAgentEnabled() then begin
            AlreadyActivated := true;
            exit;
        end;

        Load(PASetupUpdateParameters);
        PASetupUpdateParameters.DisableEmailMonitoring();
        PASetupUpdateParameters.EnableAgent();
        PASetupUpdateParameters.SetSkipEmailVerification(true);
        Update(PASetupUpdateParameters);
        AlreadyActivated := false;
    end;

    /// <summary>
    /// Obtains the user's consent for the agent to monitor the mailbox, using the standard Microsoft-service consent
    /// experience, and records it on the desired setup. Runs modally, so it must run before any write transaction.
    /// </summary>
    /// <returns>False when consent is declined.</returns>
    local procedure ObtainConsent(var PASetupUpdateParameters: Codeunit "PA Setup Update Parameters"): Boolean
    var
        TempPADetailedSetup: Record "PA Detailed Setup";
        CustomerConsentMgt: Codeunit "Customer Consent Mgt.";
    begin
        TempPADetailedSetup := PASetupUpdateParameters.GetDesiredSetup();
        if TempPADetailedSetup."Email Monitoring Consent" then
            exit(true);
        if not CustomerConsentMgt.ConfirmUserConsentToMicrosoftService() then
            exit(false);
        TempPADetailedSetup."Email Monitoring Consent" := true;
        PASetupUpdateParameters.SetDesiredSetup(TempPADetailedSetup);
        exit(true);
    end;

    /// <summary>
    /// Checks that the desired mailbox is selected and, in SaaS, reachable. Must run before any write transaction
    /// (Codeunit.Run is used for the reachability check).
    /// </summary>
    local procedure ValidateMailbox(var PASetupUpdateParameters: Codeunit "PA Setup Update Parameters")
    var
        EnvironmentInformation: Codeunit "Environment Information";
        PAValidateSetup: Codeunit "PA Validate Setup";
        ErrorAccountNotConnecting: ErrorInfo;
    begin
        if not PASetupUpdateParameters.MonitorEmail() then
            exit;
        if IsNullGuid(PASetupUpdateParameters.GetDesiredSetup()."Email Account Id") then
            Error(ActivateWithoutMailboxNameErr);

        // SaaS only requirement. The setup already carries the mailbox configuration.
        if not EnvironmentInformation.IsSaaS() then
            exit;
        PAValidateSetup.ConfigureSetupToValidate(PASetupUpdateParameters.GetDesiredSetup());
        if not PAValidateSetup.Run() then begin
            ErrorAccountNotConnecting.Title(EmailConnectionErr);
            ErrorAccountNotConnecting.Message(StrSubstNo(EmailConnectionMessageErr, PASetupUpdateParameters.GetEmailAccount()."Email Address"));
            ErrorAccountNotConnecting.PageNo := Page::"Email Accounts";
            ErrorAccountNotConnecting.AddNavigationAction(EmailConnectionNavigationActionLbl);
            Error(ErrorAccountNotConnecting);
        end;
    end;

    /// <summary>
    /// Configures the agent (unless skipped) and saves the desired setup, including the agent user and the hash of the
    /// configuration its instructions were applied with, in a single save. The saved setup is written back to the
    /// parameters. Starts write transactions.
    /// </summary>
    local procedure ApplySetup(var PASetupUpdateParameters: Codeunit "PA Setup Update Parameters")
    var
        TempPADetailedSetup: Record "PA Detailed Setup";
    begin
        TempPADetailedSetup := PASetupUpdateParameters.GetDesiredSetup();
        if not PASetupUpdateParameters.GetSkipAgentConfiguration() then // Skipping the agent's configuration is valid in tests
            TempPADetailedSetup."User Security Id" := ConfigureAgent(PASetupUpdateParameters, TempPADetailedSetup."Applied Instr. Config Hash");
        PASetup.ApplySetup(TempPADetailedSetup, PASetupUpdateParameters.Enabling());
        PASetupUpdateParameters.SetDesiredSetup(TempPADetailedSetup);
    end;

    local procedure ConfigureAgent(var PASetupUpdateParameters: Codeunit "PA Setup Update Parameters"; var AppliedInstrConfigHash: Text[64]): Guid
    var
        AgentAdminPS: Record "Aggregate Permission Set";
        AccessControl: Record "Access Control";
        TempModifiedAgentAccessControl: Record "Agent Access Control" temporary;
        TempAgentSetupBuffer: Record "Agent Setup Buffer";
        AgentSetup: Codeunit "Agent Setup";
        UserPermissions: Codeunit "User Permissions";
        CurrentModuleInfo: ModuleInfo;
        AgentUserId: Guid;
        AgentAdminPermissionSetTok: Label 'Payables Ag. - Adm.', Locked = true;
    begin
        PASetupUpdateParameters.GetAgentSetupBuffer(TempAgentSetupBuffer);
        AgentUserId := AgentSetup.SaveChanges(TempAgentSetupBuffer);
        // We assign the necessary permission sets to the users depending on whether or not users are able to modify the agent
        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        Clear(AgentAdminPS);
        AgentAdminPS.SetRange("App ID", CurrentModuleInfo.Id);
        AgentAdminPS.SetRange("Role ID", AgentAdminPermissionSetTok);
        AgentAdminPS.FindFirst();
        Clear(TempModifiedAgentAccessControl);
        if TempModifiedAgentAccessControl.FindSet() then
            repeat
                if TempModifiedAgentAccessControl."Can Configure Agent" then
                    if (not UserPermissions.IsSuper(TempModifiedAgentAccessControl."User Security ID")) and (not UserPermissions.HasUserPermissionSetAssigned(TempModifiedAgentAccessControl."User Security ID", CompanyName(), AgentAdminPermissionSetTok, AccessControl.Scope::System, CurrentModuleInfo.Id)) then
                        // If the user is allowed to configure the agent, we assign the admin permission set
                        UserPermissions.AssignPermissionSets(TempModifiedAgentAccessControl."User Security ID", CompanyName(), AgentAdminPS);
            until TempModifiedAgentAccessControl.Next() = 0;

        // Apply agent instructions and capture the hash; ApplySetup saves it together with the rest of the setup.
        if not IsNullGuid(AgentUserId) then
            AppliedInstrConfigHash := PayablesAgentSetup.ApplyAgentInstructions(AgentUserId);
        exit(AgentUserId);
    end;

    local procedure InitializeTrialIfEligible()
    var
        PATrial: Codeunit "PA Trial";
    begin
        if PATrial.IsEligibleToStart() then begin
            PATrial.StartTrial();
            Session.LogMessage('0000SEF', TrialModeInitializedTok, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', PayablesAgentTelemetryTok);
        end;
    end;

    /// <summary>
    /// Hands the invoice uploaded on the setup page to the agent.
    /// </summary>
    local procedure ProcessTrialUploadIfPending(var PASetupUpdateParameters: Codeunit "PA Setup Update Parameters")
    var
        TempBlob: Codeunit "Temp Blob";
        PayablesAgent: Codeunit "Payables Agent Metadata";
        PATask: Codeunit "PA Task";
        InStream: InStream;
    begin
        if not PASetupUpdateParameters.GetTrialUploadPending() then
            exit;

        PASetupUpdateParameters.GetTrialUploadBlob(TempBlob);
        TempBlob.CreateInStream(InStream);
        PATask.CreateFromUpload(PASetupUpdateParameters.GetTrialUploadFileName(), InStream);
        Session.LogMessage('0000SEG', TryWithUploadManuallyTok, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, PayablesAgent.GetCustomDimensions());

        PASetupUpdateParameters.ClearTrialUpload();
    end;

    var
        PASetup: Codeunit "PA Setup";
        PayablesAgentSetup: Codeunit "Payables Agent Setup";
        ActivateWithoutMailboxNameErr: Label 'To activate the agent with the current settings, a mailbox must be selected first.';
        EmailConnectionErr: Label 'Failed to connect to the email mailbox.';
        EmailConnectionMessageErr: Label 'Connection to mailbox failed. Please review the email account configuration for email %1', Comment = '%1 - Email account name';
        EmailConnectionNavigationActionLbl: Label 'Show email accounts';
        PayablesAgentTelemetryTok: Label 'Payables Agent', Locked = true;
        TrialModeInitializedTok: Label 'Trial mode initialized for Payables Agent', Locked = true;
        TryWithUploadManuallyTok: Label 'User uploaded a file to try the agent.', Locked = true;
}
