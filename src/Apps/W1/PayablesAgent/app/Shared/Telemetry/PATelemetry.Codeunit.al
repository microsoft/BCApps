// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Agent.PayablesAgent;

using System.Telemetry;

codeunit 3325 "PA Telemetry"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    #region Shared dimensions
    var
        CategoryTok: Label 'Payables Agent', Locked = true;

    internal procedure GetCustomDimensions() CustomDimensions: Dictionary of [Text, Text]
    begin
        CustomDimensions.Set('category', CategoryTok);
    end;
    #endregion

    #region Intake
    local procedure GetTaskDimensions(PATask: Codeunit "Payables Agent Task") CustomDimensions: Dictionary of [Text, Text]
    var
        PASetup: Codeunit "PA Setup";
    begin
        PASetup.GetSetup();
        // 'Category' (capitalized) is kept for the task events that always used it.
        CustomDimensions.Set('Category', CategoryTok);
        CustomDimensions.Set('Version', Format(PATask.GetVersion(), 0, 9));
        CustomDimensions.Set('SystemId', LowerCase(Format(PATask.GetSourceId())).Replace('{', '').Replace('}', ''));
        CustomDimensions.Set('AgentTaskId', Format(PATask.GetAgentTaskId(), 0, 9));
        CustomDimensions.Set('SourceType', Format(PATask.GetSourceType(), 0, 9));
        CustomDimensions.Set('EmailReviewPolicy', Format(PASetup.GetEmailReviewPolicy(), 0, 9));
    end;

    local procedure GetSourceDimensions(PATaskSource: Codeunit "PA Task Source") CustomDimensions: Dictionary of [Text, Text]
    var
        PASetup: Codeunit "PA Setup";
    begin
        PASetup.GetSetup();
        CustomDimensions.Set('Category', CategoryTok);
        CustomDimensions.Set('Version', Format(PATaskSource.GetVersion(), 0, 9));
        CustomDimensions.Set('SystemId', LowerCase(Format(PATaskSource.GetId())).Replace('{', '').Replace('}', ''));
        CustomDimensions.Set('SourceType', Format(PATaskSource.GetSourceType(), 0, 9));
        CustomDimensions.Set('EmailReviewPolicy', Format(PASetup.GetEmailReviewPolicy(), 0, 9));
    end;

    internal procedure LogTaskReceived(PATask: Codeunit "Payables Agent Task"; RequiresReview: Boolean)
    var
        Telemetry: Codeunit Telemetry;
        CustomDimensions: Dictionary of [Text, Text];
    begin
        CustomDimensions := GetTaskDimensions(PATask);
        CustomDimensions.Set('RequiresReview', Format(RequiresReview, 0, 9));
        Telemetry.LogMessage('0000PJA', 'Payables Agent Task Received', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);
    end;

    internal procedure LogTaskSkippedSenderRejected(PATaskSource: Codeunit "PA Task Source")
    var
        Telemetry: Codeunit Telemetry;
    begin
        Telemetry.LogMessage('0000QJ2', 'Payables Agent Task Skipped: sender rejected', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, GetSourceDimensions(PATaskSource));
    end;

    internal procedure LogInvoiceUploaded()
    var
        InvoiceUploadTok: Label 'User uploaded an invoice for Payables Agent processing.', Locked = true;
    begin
        Session.LogMessage('0000SEJ', InvoiceUploadTok, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, GetCustomDimensions());
    end;
    #endregion

    #region Trial
    internal procedure LogTrialTaskCreated(TrialInvoiceCount: Integer; TrialInvoiceLimit: Integer)
    var
        CustomDimensions: Dictionary of [Text, Text];
    begin
        CustomDimensions := GetCustomDimensions();
        CustomDimensions.Add('TrialInvoiceCount', Format(TrialInvoiceCount, 0, 9));
        CustomDimensions.Add('TrialInvoiceLimit', Format(TrialInvoiceLimit, 0, 9));
        CustomDimensions.Add('ExcludeBilling', Format(false, 0, 9)); // Logged before billing is excluded, as it always was.
        Session.LogMessage('0000SEE', 'Agent Task created in trial mode. Skipping billing for invoice.', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CustomDimensions);
    end;

    internal procedure LogTrialStarted()
    var
        TrialModeInitializedTelemetryTok: Label 'Trial mode initialized.', Locked = true;
    begin
        Session.LogMessage('0000SEH', TrialModeInitializedTelemetryTok, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, GetCustomDimensions());
    end;

    internal procedure LogTrialReset()
    var
        TrialStateResetTelemetryTok: Label 'Trial state reset.', Locked = true;
    begin
        Session.LogMessage('0000SEI', TrialStateResetTelemetryTok, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, GetCustomDimensions());
    end;
    #endregion

    #region Configuration
    internal procedure LogSetupStarted()
    begin
        Session.LogMessage('0000OUW', 'Setting up payables agent', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', CategoryTok);
    end;

    internal procedure LogSecurityPromptUnavailable()
    begin
        Session.LogMessage('0000QPX', 'Failed to retrieve security prompt', Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', CategoryTok);
    end;

    internal procedure LogInstructionsReapplied()
    begin
        Session.LogMessage('0000SEK', 'Payables Agent instructions reapplied after instruction configuration changed.', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CategoryTok);
    end;

    internal procedure LogTrialInitializedOnActivation()
    var
        TrialModeInitializedTok: Label 'Trial mode initialized for Payables Agent', Locked = true;
    begin
        Session.LogMessage('0000SEF', TrialModeInitializedTok, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', CategoryTok);
    end;

    internal procedure LogTrialUpload()
    var
        TryWithUploadManuallyTok: Label 'User uploaded a file to try the agent.', Locked = true;
    begin
        Session.LogMessage('0000SEG', TryWithUploadManuallyTok, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, GetCustomDimensions());
    end;

    internal procedure LogDemoGuideOpened()
    begin
        Session.LogMessage('0000PJU', 'Running demo guide for payables agent', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', CategoryTok);
    end;

    internal procedure LogDemoGuideMissingSetup()
    var
        NoSetupConfigurationProvidedTok: Label 'Demo guide opened without a setup configuration, falling back to the saved setup', Locked = true;
    begin
        Session.LogMessage('0000VDH', NoSetupConfigurationProvidedTok, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', CategoryTok);
    end;

    internal procedure LogDemoGuideFinished()
    begin
        Session.LogMessage('0000PJV', 'Ran demo guide for payables agent', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', CategoryTok);
    end;

    internal procedure LogDemoInvoicesSent()
    var
        DemoInvoicesSentTok: Label 'Sent demo sample invoices by email', Locked = true;
    begin
        Session.LogMessage('0000V8C', DemoInvoicesSentTok, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', CategoryTok);
    end;

    internal procedure LogDemoInvoicesPrepared()
    var
        DemoInvoicesPreparedTok: Label 'Prepared demo sample invoices to send on agent activation', Locked = true;
    begin
        Session.LogMessage('0000V8D', DemoInvoicesPreparedTok, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', CategoryTok);
    end;

    #endregion

    #region Feedback
    internal procedure LogDisableAgentFeedback()
    var
        Telemetry: Codeunit Telemetry;
        DisableAgentFeedbackTxt: Label 'Disable agent feedback triggered', Locked = true;
    begin
        Telemetry.LogMessage('0000QSC', DisableAgentFeedbackTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All);
    end;

    internal procedure LogTaskThumbsFeedback(FeedbackType: Text)
    var
        Telemetry: Codeunit Telemetry;
        CustomDimensions: Dictionary of [Text, Text];
        TaskThumbsFeedbackTxt: Label 'Task thumbs feedback triggered', Locked = true;
    begin
        CustomDimensions.Add('FeedbackType', FeedbackType);
        Telemetry.LogMessage('0000QSD', TaskThumbsFeedbackTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);
    end;

    internal procedure LogDraftThumbsFeedback(FeedbackType: Text)
    var
        Telemetry: Codeunit Telemetry;
        CustomDimensions: Dictionary of [Text, Text];
        DraftThumbsFeedbackTxt: Label 'Draft thumbs feedback triggered', Locked = true;
    begin
        CustomDimensions.Add('FeedbackType', FeedbackType);
        Telemetry.LogMessage('0000QSE', DraftThumbsFeedbackTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, CustomDimensions);
    end;
    #endregion

    #region Operations - email storage cleanup
    internal procedure LogEmailCleanupCompleted(DeletedCount: Integer; SkippedCount: Integer; CommitBatchSize: Integer; DeleteLimit: Integer)
    var
        CustomDimensions: Dictionary of [Text, Text];
        CleanupCompletedTelemetryLbl: Label 'Payables Agent email duplicate cleanup completed.', Locked = true;
    begin
        CustomDimensions.Add('DeletedRows', Format(DeletedCount));
        CustomDimensions.Add('SkippedRows', Format(SkippedCount));
        CustomDimensions.Add('CommitBatchSize', Format(CommitBatchSize));
        CustomDimensions.Add('DeleteLimit', Format(DeleteLimit));
        Session.LogMessage('0000VMY', CleanupCompletedTelemetryLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CustomDimensions);
    end;

    internal procedure LogEmailCleanupScanCompleted(GroupCount: Integer; DeletableRowCount: Integer)
    var
        CustomDimensions: Dictionary of [Text, Text];
        ScanCompletedTelemetryLbl: Label 'Payables Agent email duplicate scan completed.', Locked = true;
    begin
        CustomDimensions.Add('DuplicateGroups', Format(GroupCount));
        CustomDimensions.Add('DeletableRows', Format(DeletableRowCount));
        Session.LogMessage('0000VMZ', ScanCompletedTelemetryLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, CustomDimensions);
    end;
    #endregion
}
