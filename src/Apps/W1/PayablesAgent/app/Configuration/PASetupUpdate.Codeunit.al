// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Agents;
using System.Azure.Identity;
using System.Email;
using System.Environment;
using System.Environment.Configuration;
using System.Privacy;
using System.Reflection;
using System.Security.AccessControl;
using System.Security.User;
using System.Utilities;

codeunit 3344 "PA Setup Update"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    internal procedure Load(var PASetupUpdateParameters: Codeunit "PA Setup Update Parameters")
    var
        Agent: Record Agent;
        DesiredSetup: Codeunit "PA Setup";
        TempAgentSetupBuffer: Record "Agent Setup Buffer";
        AgentSetup: Codeunit "Agent Setup";
    begin
        // Skipping configuring the Agent framework records is valid in tests
        if not PASetupUpdateParameters.GetSkipAgentConfiguration() then begin
            if PAAgentConfiguration.GetAgent(Agent) then;
            AgentSetup.GetSetupRecord(
                TempAgentSetupBuffer,
                Agent."User Security ID",
                "Agent Metadata Provider"::"Payables Agent",
                PAAgentConfiguration.AgentUserName(),
                PAAgentConfiguration.AgentDisplayName(),
                PAAgentConfiguration.AgentSummary()
            );
            PASetupUpdateParameters.SetAgentSetupBuffer(TempAgentSetupBuffer);
        end;

        DesiredSetup.GetSetup();
        PASetupUpdateParameters.SetDesiredSetup(DesiredSetup);
    end;

    internal procedure Update(var PASetupUpdateParameters: Codeunit "PA Setup Update Parameters")
    var
        AzureADGraphUser: Codeunit "Azure AD Graph User";
        PADemoGuide: Codeunit "PA Demo Guide";
        DesiredSetup: Codeunit "PA Setup";
        DelegatedAdminErr: Label 'Delegated admin and helpdesk users are not allowed to update the agent.';
        EmailMonitoringRequiresPrivacyConsentErr: Label 'Email monitoring requires privacy consent.';
    begin
        if AzureADGraphUser.IsUserDelegatedAdmin() or AzureADGraphUser.IsUserDelegatedHelpdesk() then
            Error(DelegatedAdminErr);

        // Normalize deactivation and reject unsupported proposals before consent, trial or runtime writes.
        PASetupUpdateParameters.GetDesiredSetup(DesiredSetup);
        DesiredSetup.PrepareForApply(PASetupUpdateParameters.Enabling());
        PASetupUpdateParameters.SetDesiredSetup(DesiredSetup);

        Session.LogMessage('0000OUW', 'Setting up payables agent', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', PayablesAgentTelemetryTok);

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
        PASetupUpdateParameters.GetDesiredSetup(DesiredSetup);
        PAAgentAccess.InsertAccessControlForEligibleUsers(DesiredSetup.GetUserSecurityId());

        ProcessTrialUploadIfPending(PASetupUpdateParameters);
    end;

    internal procedure EnsureActivated(var AlreadyActivated: Boolean)
    var
        PASetupUpdateParameters: Codeunit "PA Setup Update Parameters";
    begin
        if PAAgentConfiguration.IsAgentEnabled() then begin
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
        DesiredSetup: Codeunit "PA Setup";
        CustomerConsentMgt: Codeunit "Customer Consent Mgt.";
    begin
        PASetupUpdateParameters.GetDesiredSetup(DesiredSetup);
        if DesiredSetup.GetEmailMonitoringConsent() then
            exit(true);
        if not CustomerConsentMgt.ConfirmUserConsentToMicrosoftService() then
            exit(false);
        DesiredSetup.SetEmailMonitoringConsent(true);
        PASetupUpdateParameters.SetDesiredSetup(DesiredSetup);
        exit(true);
    end;

    /// <summary>
    /// Checks that the desired mailbox is selected and, in SaaS, reachable. Must run before any write transaction
    /// (Codeunit.Run is used for the reachability check).
    /// </summary>
    local procedure ValidateMailbox(var PASetupUpdateParameters: Codeunit "PA Setup Update Parameters")
    var
        EnvironmentInformation: Codeunit "Environment Information";
        DesiredSetup: Codeunit "PA Setup";
        PAValidateSetup: Codeunit "PA Validate Setup";
        ErrorAccountNotConnecting: ErrorInfo;
    begin
        if not PASetupUpdateParameters.MonitorEmail() then
            exit;
        PASetupUpdateParameters.GetDesiredSetup(DesiredSetup);
        if IsNullGuid(DesiredSetup.GetEmailAccountId()) then
            Error(ActivateWithoutMailboxNameErr);

        // SaaS only requirement. The setup already carries the mailbox configuration.
        if not EnvironmentInformation.IsSaaS() then
            exit;
        PAValidateSetup.ConfigureSetupToValidate(DesiredSetup);
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
        DesiredSetup: Codeunit "PA Setup";
        AppliedInstrConfigHash: Text[64];
    begin
        PASetupUpdateParameters.GetDesiredSetup(DesiredSetup);
        if not PASetupUpdateParameters.GetSkipAgentConfiguration() then begin // Skipping the agent's configuration is valid in tests
            AppliedInstrConfigHash := DesiredSetup.GetAppliedInstrConfigHash();
            DesiredSetup.SetUserSecurityId(ConfigureAgent(PASetupUpdateParameters, AppliedInstrConfigHash));
            DesiredSetup.SetAppliedInstrConfigHash(AppliedInstrConfigHash);
        end;
        DesiredSetup.ApplySetup(PASetupUpdateParameters.Enabling());
        PASetupUpdateParameters.SetDesiredSetup(DesiredSetup);
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
            AppliedInstrConfigHash := PAAgentInstructions.ApplyAgentInstructions(AgentUserId);
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
        PATaskIntake: Codeunit "PA Task Intake";
        InStream: InStream;
    begin
        if not PASetupUpdateParameters.GetTrialUploadPending() then
            exit;

        PASetupUpdateParameters.GetTrialUploadBlob(TempBlob);
        TempBlob.CreateInStream(InStream);
        PATaskIntake.CreateTask(PASetupUpdateParameters.GetTrialUploadFileName(), InStream);
        Session.LogMessage('0000SEG', TryWithUploadManuallyTok, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, PayablesAgent.GetCustomDimensions());

        PASetupUpdateParameters.ClearTrialUpload();
    end;

    #region Company lifecycle

    [EventSubscriber(ObjectType::Report, Report::"Copy Company", 'OnAfterCreatedNewCompanyByCopyCompany', '', false, false)]
    local procedure HandleOnAfterCreatedNewCompanyByCopyCompany(NewCompanyName: Text[30])
    var
        PASetup: Codeunit "PA Setup";
        PayablesAgentKPI: Record "Payables Agent KPI";
    begin
        PASetup.DeleteSetup(NewCompanyName);

        PayablesAgentKPI.ChangeCompany(NewCompanyName);
        PayablesAgentKPI.DeleteAll();
    end;

    #endregion

    var
        PAAgentConfiguration: Codeunit "PA Agent Configuration";
        PAAgentInstructions: Codeunit "PA Agent Instructions";
        PAAgentAccess: Codeunit "PA Agent Access";
        ActivateWithoutMailboxNameErr: Label 'To activate the agent with the current settings, a mailbox must be selected first.';
        EmailConnectionErr: Label 'Failed to connect to the email mailbox.';
        EmailConnectionMessageErr: Label 'Connection to mailbox failed. Please review the email account configuration for email %1', Comment = '%1 - Email account name';
        EmailConnectionNavigationActionLbl: Label 'Show email accounts';
        PayablesAgentTelemetryTok: Label 'Payables Agent', Locked = true;
        TrialModeInitializedTok: Label 'Trial mode initialized for Payables Agent', Locked = true;
        TryWithUploadManuallyTok: Label 'User uploaded a file to try the agent.', Locked = true;
}
