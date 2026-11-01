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
        StoredAgent: Record Agent;
        AzureADGraphUser: Codeunit "Azure AD Graph User";
        PADemoGuide: Codeunit "PA Demo Guide";
        DesiredSetup: Codeunit "PA Setup";
        DelegatedAdminErr: Label 'Delegated admin and helpdesk users are not allowed to update the agent.';
        EmailMonitoringRequiresPrivacyConsentErr: Label 'Email monitoring requires privacy consent.';
    begin
        if AzureADGraphUser.IsUserDelegatedAdmin() or AzureADGraphUser.IsUserDelegatedHelpdesk() then
            Error(DelegatedAdminErr);

        // Normalize deactivation and reject unsupported proposals before consent, trial or runtime writes.
        PASetupUpdateParameters.CopyProposal(DesiredSetup);
        DesiredSetup.PrepareForApply(PASetupUpdateParameters.Activating());

        PATelemetry.LogSetupStarted();

        // Ask for email monitoring consent before any write transaction, since the consent dialog runs modally.
        if PASetupUpdateParameters.Activating() and DesiredSetup.GetMonitorOutlook() then
            if not ObtainConsent(DesiredSetup) then
                Error(EmailMonitoringRequiresPrivacyConsentErr);

        // Validation runs before any write transaction.
        if PASetupUpdateParameters.Activating() then
            if not PASetupUpdateParameters.GetSkipEmailVerification() then begin
                DesiredSetup.SetLastActivated(CurrentDateTime());
                ValidateMailbox(DesiredSetup);
            end;

        // First write transaction. Repair stored identity separately, without replacing the editable proposal.
        if not PASetupUpdateParameters.GetSkipAgentConfiguration() then
            if DesiredSetup.FindAgentAndReconcileSetup(StoredAgent) then;

        // Initialize trial BEFORE creating the agent so IsEligibleForTrial() can detect first activation.
        if PASetupUpdateParameters.Activating() then
            InitializeTrialIfEligible();

        ApplySetup(PASetupUpdateParameters, DesiredSetup);

        // Use the applied proposal; deactivation may have normalized a monitoring-on request to off.
        if DesiredSetup.GetMonitorOutlook() then
            PADemoGuide.SendDemoEmail(PASetupUpdateParameters);

        // Give the users that have recently created posted purchase invoices access to the agent.
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
        PASetupUpdateParameters.DisactivateEmailMonitoring();
        PASetupUpdateParameters.ActivateAgent();
        PASetupUpdateParameters.SetSkipEmailVerification(true);
        Update(PASetupUpdateParameters);
        AlreadyActivated := false;
    end;

    /// <summary>
    /// Obtains the user's consent for the agent to monitor the mailbox, using the standard Microsoft-service consent
    /// experience, and records it on the desired setup. Runs modally, so it must run before any write transaction.
    /// </summary>
    /// <returns>False when consent is declined.</returns>
    local procedure ObtainConsent(var DesiredSetup: Codeunit "PA Setup"): Boolean
    var
        CustomerConsentMgt: Codeunit "Customer Consent Mgt.";
    begin
        if DesiredSetup.GetEmailMonitoringConsent() then
            exit(true);
        if not CustomerConsentMgt.ConfirmUserConsentToMicrosoftService() then
            exit(false);
        DesiredSetup.SetEmailMonitoringConsent(true);
        exit(true);
    end;

    /// <summary>
    /// Checks that the desired mailbox is selected and, in SaaS, reachable. Must run before any write transaction
    /// (Codeunit.Run is used for the reachability check).
    /// </summary>
    local procedure ValidateMailbox(DesiredSetup: Codeunit "PA Setup")
    var
        TempEmailAccount: Record "Email Account" temporary;
        EmailAccount: Codeunit "Email Account";
        EnvironmentInformation: Codeunit "Environment Information";
        PAValidateSetup: Codeunit "PA Validate Setup";
        ErrorAccountNotConnecting: ErrorInfo;
    begin
        if not DesiredSetup.GetMonitorOutlook() then
            exit;
        if IsNullGuid(DesiredSetup.GetEmailAccountId()) then
            Error(ActivateWithoutMailboxNameErr);

        // SaaS only requirement. The setup already carries the mailbox configuration.
        if not EnvironmentInformation.IsSaaS() then
            exit;
        PAValidateSetup.ConfigureSetupToValidate(DesiredSetup);
        if not PAValidateSetup.Run() then begin
            EmailAccount.GetAllAccounts(false, TempEmailAccount);
            if not TempEmailAccount.Get(DesiredSetup.GetEmailAccountId(), "Email Connector"::"Microsoft 365") then
                Clear(TempEmailAccount);
            ErrorAccountNotConnecting.Title(EmailConnectionErr);
            ErrorAccountNotConnecting.Message(StrSubstNo(EmailConnectionMessageErr, TempEmailAccount."Email Address"));
            ErrorAccountNotConnecting.PageNo := Page::"Email Accounts";
            ErrorAccountNotConnecting.AddNavigationAction(EmailConnectionNavigationActionLbl);
            Error(ErrorAccountNotConnecting);
        end;
    end;

    /// <summary>
    /// Configures the agent (unless skipped) and saves the desired setup, including the agent user and the hash of the
    /// configuration its instructions were applied with, in a single save. The flow retains its applied proposal.
    /// Starts write transactions.
    /// </summary>
    local procedure ApplySetup(var PASetupUpdateParameters: Codeunit "PA Setup Update Parameters"; var DesiredSetup: Codeunit "PA Setup")
    var
        AppliedInstrConfigHash: Text[64];
    begin
        if not PASetupUpdateParameters.GetSkipAgentConfiguration() then begin // Skipping the agent's configuration is valid in tests
            AppliedInstrConfigHash := DesiredSetup.GetAppliedInstrConfigHash();
            DesiredSetup.SetUserSecurityId(ConfigureAgent(PASetupUpdateParameters, DesiredSetup, AppliedInstrConfigHash));
            DesiredSetup.SetAppliedInstrConfigHash(AppliedInstrConfigHash);
        end;
        DesiredSetup.ApplySetup(PASetupUpdateParameters.Activating());
    end;

    local procedure ConfigureAgent(var PASetupUpdateParameters: Codeunit "PA Setup Update Parameters"; DesiredSetup: Codeunit "PA Setup"; var AppliedInstrConfigHash: Text[64]): Guid
    var
        TempAccessControlBuffer: Record "Access Control Buffer" temporary;
        TempAgentSetupBuffer: Record "Agent Setup Buffer";
        Agent: Codeunit Agent;
        AgentSetup: Codeunit "Agent Setup";
        CurrentModuleInfo: ModuleInfo;
        AgentUserId: Guid;
    begin
        PASetupUpdateParameters.GetAgentSetupBuffer(TempAgentSetupBuffer);
        AgentUserId := AgentSetup.SaveChanges(TempAgentSetupBuffer);

        NavApp.GetCurrentModuleInfo(CurrentModuleInfo);
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
        FileName: Text;
        InStream: InStream;
    begin
        if not PASetupUpdateParameters.TryGetTrialUpload(FileName, TempBlob) then
            exit;

        TempBlob.CreateInStream(InStream);
        PATaskIntake.CreateTask(FileName, InStream);
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
