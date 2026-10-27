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
using System.Security.AccessControl;
using System.Utilities;

codeunit 3344 "PA Setup Update"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        PAAgentInstructions: Codeunit "PA Agent Instructions";
        PAAgentAccess: Codeunit "PA Agent Access";
        PATelemetry: Codeunit "PA Telemetry";
        ActivateWithoutMailboxNameErr: Label 'To activate the agent with the current settings, a mailbox must be selected first.';
        EmailConnectionErr: Label 'Failed to connect to the email mailbox.';
        EmailConnectionMessageErr: Label 'Connection to mailbox failed. Please review the email account configuration for email %1', Comment = '%1 - Email account name';
        EmailConnectionNavigationActionLbl: Label 'Show email accounts';

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
        PASetupUpdateParameters.PrepareForApply();

        PATelemetry.LogSetupStarted();

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
        StoredSetup: Codeunit "PA Setup";
    begin
        if StoredSetup.IsStoredAgentEnabled() then begin
            AlreadyActivated := true;
            exit;
        end;

        PASetupUpdateParameters.InitializeFromStoredSetup();
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
        TempAccessControlBuffer: Record "Access Control Buffer" temporary;
        TempAgentSetupBuffer: Record "Agent Setup Buffer";
        Agent: Codeunit Agent;
        AgentSetup: Codeunit "Agent Setup";
        DesiredSetup: Codeunit "PA Setup";
        CurrentModuleInfo: ModuleInfo;
        AgentUserId: Guid;
    begin
        PASetupUpdateParameters.GetAgentSetupBuffer(TempAgentSetupBuffer);
        AgentUserId := AgentSetup.SaveChanges(TempAgentSetupBuffer);

        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
        PASetupUpdateParameters.GetDesiredSetup(DesiredSetup);
        Agent.SetProfile(AgentUserId, DesiredSetup.GetAgentProfile(), CurrentModuleInfo.Id);
        TempAccessControlBuffer."Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(TempAccessControlBuffer."Company Name"));
        TempAccessControlBuffer.Scope := TempAccessControlBuffer.Scope::System;
        TempAccessControlBuffer."App ID" := CurrentModuleInfo.Id;
        TempAccessControlBuffer."Role ID" := DesiredSetup.GetAgentPermissionSet();
        TempAccessControlBuffer.Insert();
        Agent.UpdateAccessControl(AgentUserId, TempAccessControlBuffer);

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
            PATelemetry.LogTrialInitializedOnActivation();
        end;
    end;

    /// <summary>
    /// Hands the invoice uploaded on the setup page to the agent.
    /// </summary>
    local procedure ProcessTrialUploadIfPending(var PASetupUpdateParameters: Codeunit "PA Setup Update Parameters")
    var
        TempBlob: Codeunit "Temp Blob";
        PATaskIntake: Codeunit "PA Task Intake";
        InStream: InStream;
    begin
        if not PASetupUpdateParameters.GetTrialUploadPending() then
            exit;

        PASetupUpdateParameters.GetTrialUploadBlob(TempBlob);
        TempBlob.CreateInStream(InStream);
        PATaskIntake.CreateTask(PASetupUpdateParameters.GetTrialUploadFileName(), InStream);
        PATelemetry.LogTrialUpload();

        PASetupUpdateParameters.ClearTrialUpload();
    end;

    #region Company lifecycle

    [EventSubscriber(ObjectType::Report, Report::"Copy Company", 'OnAfterCreatedNewCompanyByCopyCompany', '', false, false)]
    local procedure HandleOnAfterCreatedNewCompanyByCopyCompany(NewCompanyName: Text[30])
    var
        PayablesAgentKPI: Record "Payables Agent KPI";
        PASetup: Codeunit "PA Setup";
    begin
        PASetup.DeleteSetup(NewCompanyName);

        PayablesAgentKPI.ChangeCompany(NewCompanyName);
        PayablesAgentKPI.DeleteAll();
    end;

    #endregion
}
