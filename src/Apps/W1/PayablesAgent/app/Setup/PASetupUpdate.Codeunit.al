// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Azure.Identity;
using System.Utilities;

/// <summary>
/// The setup update process: loads the parameters for the setup page, and applies them, both when activating and
/// deactivating the agent. Agnostic of the Payables Agent version: it works with "PA Setup Update Parameters" and the
/// facades only.
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
    begin
        PASetup.LoadParameters(PASetupUpdateParameters);
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
            if not PASetup.ObtainConsent(PASetupUpdateParameters) then
                Error(EmailMonitoringRequiresPrivacyConsentErr);

        // Validation runs before any write transaction.
        if PASetupUpdateParameters.Enabling() then
            if not PASetupUpdateParameters.GetSkipEmailVerification() then begin
                PASetupUpdateParameters.SetLastActivated(CurrentDateTime());
                PASetup.ValidateMailbox(PASetupUpdateParameters);
            end;

        // Initialize trial BEFORE creating the agent so IsEligibleForTrial() can detect first activation
        if PASetupUpdateParameters.Enabling() then
            InitializeTrialIfEligible();

        // First write transaction.
        PASetup.ApplySetup(PASetupUpdateParameters);

        PADemoGuide.SendDemoEmail(PASetupUpdateParameters);

        PASetup.GrantAccessToEligibleUsers(PASetupUpdateParameters);

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
        if PASetup.IsAgentEnabled() then begin
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
        PayablesAgentTelemetryTok: Label 'Payables Agent', Locked = true;
        TrialModeInitializedTok: Label 'Trial mode initialized for Payables Agent', Locked = true;
        TryWithUploadManuallyTok: Label 'User uploaded a file to try the agent.', Locked = true;
}
