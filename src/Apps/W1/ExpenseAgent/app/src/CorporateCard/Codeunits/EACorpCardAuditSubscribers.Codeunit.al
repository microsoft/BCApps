// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Telemetry and audit logging for Corporate Card operations.
/// Logs import operations, exceptions, and configuration changes.
/// </summary>
codeunit 7214 "EA Corp Card Audit Subscribers"
{
    Access = Internal;
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        CorpCardTelemetryCategoryTok: Label 'Corporate Card', Locked = true;
        ImportStartedMsg: Label 'Corp Card import started for provider %1. Batch No. %2.', Locked = true;
        ImportCompletedMsg: Label 'Corp Card import completed for provider %1. Batch No. %2. Imported: %3, Exceptions: %4, Duplicates: %5.', Locked = true;
        ImportFailedMsg: Label 'Corp Card import failed for provider %1. Batch No. %2. Error: %3.', Locked = true;
        MatchingCompletedMsg: Label 'Corp Card matching completed. Matched: %1, Unmatched: %2.', Locked = true;
        DraftCreatedMsg: Label 'Corp Card draft created. Transaction: %1, Expense No.: %2.', Locked = true;
        JobQueueScheduledMsg: Label 'Corp Card import job queue scheduled for provider %1 with frequency %2.', Locked = true;
        ReportCreatedMsg: Label 'Expense report %1 created from corp card expenses for employee %2.', Locked = true;
        ReportSubmittedMsg: Label 'Expense report %1 submitted for approval by user %2.', Locked = true;
        ReportApprovedMsg: Label 'Expense report %1 approved for posting by user %2.', Locked = true;
        ReportRejectedMsg: Label 'Expense report %1 rejected by user %2 with reason: %3.', Locked = true;

    internal procedure LogImportStarted(ProviderCode: Code[20]; BatchNo: Integer)
    begin
        Session.LogMessage('0000UCS', StrSubstNo(ImportStartedMsg, ProviderCode, BatchNo), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategory());
    end;

    internal procedure LogImportCompleted(ProviderCode: Code[20]; BatchNo: Integer; Imported: Integer; Exceptions: Integer; Duplicates: Integer)
    begin
        Session.LogMessage('0000UCT', StrSubstNo(ImportCompletedMsg, ProviderCode, BatchNo, Imported, Exceptions, Duplicates), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategory());
    end;

    internal procedure LogImportFailed(ProviderCode: Code[20]; BatchNo: Integer; ErrorMsg: Text)
    begin
        Session.LogMessage('0000UCU', StrSubstNo(ImportFailedMsg, ProviderCode, BatchNo, CopyStr(ErrorMsg, 1, 250)), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategory());
    end;

    internal procedure LogMatchingCompleted(Matched: Integer; Unmatched: Integer)
    begin
        Session.LogMessage('0000UCV', StrSubstNo(MatchingCompletedMsg, Matched, Unmatched), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategory());
    end;

    internal procedure LogDraftCreated(TransEntryNo: Integer; ExpenseNo: Code[20])
    begin
        Session.LogMessage('0000UCW', StrSubstNo(DraftCreatedMsg, TransEntryNo, ExpenseNo), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategory());
    end;

    internal procedure LogJobQueueScheduled(ProviderCode: Code[20]; Frequency: Text)
    begin
        Session.LogMessage('0000UCX', StrSubstNo(JobQueueScheduledMsg, ProviderCode, Frequency), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategory());
    end;

    internal procedure LogReportCreatedFromCorpCard(ReportNo: Code[20]; EmployeeNo: Code[20])
    begin
        Session.LogMessage('0000UCY', StrSubstNo(ReportCreatedMsg, ReportNo, EmployeeNo), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategory());
    end;

    internal procedure LogReportSubmittedForApproval(ReportNo: Code[20]; UserId: Code[50])
    begin
        Session.LogMessage('0000UCZ', StrSubstNo(ReportSubmittedMsg, ReportNo, UserId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategory());
    end;

    internal procedure LogReportApprovedForPosting(ReportNo: Code[20]; UserId: Code[50])
    begin
        Session.LogMessage('0000UD0', StrSubstNo(ReportApprovedMsg, ReportNo, UserId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategory());
    end;

    internal procedure LogReportRejected(ReportNo: Code[20]; UserId: Code[50]; Reason: Text)
    begin
        Session.LogMessage('0000UD1', StrSubstNo(ReportRejectedMsg, ReportNo, UserId, CopyStr(Reason, 1, 250)), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', TelemetryCategory());
    end;

    internal procedure TelemetryCategory(): Text
    begin
        exit(CorpCardTelemetryCategoryTok);
    end;
}
