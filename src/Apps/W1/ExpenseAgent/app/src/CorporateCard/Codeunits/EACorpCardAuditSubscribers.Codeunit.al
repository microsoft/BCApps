// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Telemetry and audit logging for Corporate Card operations.
/// Logs import operations, exceptions, and configuration changes.
/// </summary>
codeunit 7424 "EA Corp Card Audit Subscribers"
{
    Access = Internal;
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        CorpCardTelemetryCategoryTok: Label 'Corporate Card', Locked = true;
        ImportStartedMsg: Label 'Corp Card statement import started for a provider.', Locked = true;
        ImportCompletedMsg: Label 'Corp Card statement import completed for a provider.', Locked = true;
        ImportFailedMsg: Label 'Corp Card statement import failed for a provider.', Locked = true;
        MatchingCompletedMsg: Label 'Corp Card matching completed.', Locked = true;
        DraftCreatedMsg: Label 'Corp Card draft created.', Locked = true;
        JobQueueScheduledMsg: Label 'Corp Card import job queue scheduled for a provider.', Locked = true;
        ReportCreatedMsg: Label 'Expense report created from corp card expenses.', Locked = true;
        ReportSubmittedMsg: Label 'Expense report submitted for approval.', Locked = true;
        ReportApprovedMsg: Label 'Expense report approved for posting.', Locked = true;
        ReportRejectedMsg: Label 'Expense report rejected.', Locked = true;

    internal procedure LogImportStarted(ProviderCode: Code[20]; StatementEntryNo: Integer)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add('Category', TelemetryCategory());
        Dimensions.Add('ProviderCode', ProviderCode);
        Dimensions.Add('StatementEntryNo', Format(StatementEntryNo));
        Session.LogMessage('0000UCS', ImportStartedMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dimensions);
    end;

    internal procedure LogImportCompleted(ProviderCode: Code[20]; StatementEntryNo: Integer; Imported: Integer; Exceptions: Integer; Duplicates: Integer)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add('Category', TelemetryCategory());
        Dimensions.Add('ProviderCode', ProviderCode);
        Dimensions.Add('StatementEntryNo', Format(StatementEntryNo));
        Dimensions.Add('Imported', Format(Imported));
        Dimensions.Add('Exceptions', Format(Exceptions));
        Dimensions.Add('Duplicates', Format(Duplicates));
        Session.LogMessage('0000UCT', ImportCompletedMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dimensions);
    end;

    internal procedure LogImportFailed(ProviderCode: Code[20]; StatementEntryNo: Integer; ErrorMsg: Text)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add('Category', TelemetryCategory());
        Dimensions.Add('ProviderCode', ProviderCode);
        Dimensions.Add('StatementEntryNo', Format(StatementEntryNo));
        Session.LogMessage('0000UCU', ImportFailedMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dimensions);
    end;

    internal procedure LogMatchingCompleted(Matched: Integer; Unmatched: Integer)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add('Category', TelemetryCategory());
        Dimensions.Add('Matched', Format(Matched));
        Dimensions.Add('Unmatched', Format(Unmatched));
        Session.LogMessage('0000UCV', MatchingCompletedMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dimensions);
    end;

    internal procedure LogDraftCreated(TransEntryNo: Integer; ExpenseNo: Code[20])
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add('Category', TelemetryCategory());
        Dimensions.Add('TransactionEntryNo', Format(TransEntryNo));
        Dimensions.Add('ExpenseNo', ExpenseNo);
        Session.LogMessage('0000UCW', DraftCreatedMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dimensions);
    end;

    internal procedure LogJobQueueScheduled(ProviderCode: Code[20]; Frequency: Text)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add('Category', TelemetryCategory());
        Dimensions.Add('ProviderCode', ProviderCode);
        Dimensions.Add('Frequency', Frequency);
        Session.LogMessage('0000UCX', JobQueueScheduledMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dimensions);
    end;

    internal procedure LogReportCreatedFromCorpCard()
    begin
        Session.LogMessage('0000UCY', ReportCreatedMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategory());
    end;

    internal procedure LogReportSubmittedForApproval()
    begin
        Session.LogMessage('0000UCZ', ReportSubmittedMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategory());
    end;

    internal procedure LogReportApprovedForPosting()
    begin
        Session.LogMessage('0000UD0', ReportApprovedMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategory());
    end;

    internal procedure LogReportRejected()
    begin
        Session.LogMessage('0000UD1', ReportRejectedMsg, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', TelemetryCategory());
    end;

    internal procedure TelemetryCategory(): Text
    begin
        exit(CorpCardTelemetryCategoryTok);
    end;
}
