// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Telemetry;

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
        ExpenseAgentSetup: Record "Expense Agent Setup";
        FeatureTelemetry: Codeunit "Feature Telemetry";
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
        StatementClosedMsg: Label 'Corp Card statement closed.', Locked = true;
        SettlementPostedMsg: Label 'Corp Card settlement posted.', Locked = true;
        SettlementReversedMsg: Label 'Corp Card settlement reversed.', Locked = true;

    internal procedure LogImportStarted(ProviderCode: Code[20]; StatementEntryNo: Integer)
    var
        ExpenseAuditSubscribers: Codeunit "Expense Audit Subscribers";
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add('Category', ExpenseAuditSubscribers.TelemetryCategory());
        Dimensions.Add('FeatureName', ExpenseAgentSetup.GetFeatureName());
        Dimensions.Add('ProviderCode', ProviderCode);
        Dimensions.Add('StatementEntryNo', Format(StatementEntryNo));
        Session.LogMessage('0000UCS', ImportStartedMsg, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dimensions);
    end;

    internal procedure LogImportCompleted(ProviderCode: Code[20]; StatementEntryNo: Integer; Imported: Integer; Exceptions: Integer; Duplicates: Integer)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add('ProviderCode', ProviderCode);
        Dimensions.Add('StatementEntryNo', Format(StatementEntryNo));
        Dimensions.Add('Imported', Format(Imported));
        Dimensions.Add('Exceptions', Format(Exceptions));
        Dimensions.Add('Duplicates', Format(Duplicates));
        FeatureTelemetry.LogUsage('0000UCT', ExpenseAgentSetup.GetFeatureName(), ImportCompletedMsg, Dimensions);
    end;

    internal procedure LogImportFailed(ProviderCode: Code[20]; StatementEntryNo: Integer; ImportStage: Text)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add('ProviderCode', ProviderCode);
        Dimensions.Add('StatementEntryNo', Format(StatementEntryNo));
        Dimensions.Add('ImportStage', ImportStage);
        FeatureTelemetry.LogError('0000UCU', ExpenseAgentSetup.GetFeatureName(), ImportFailedMsg, ImportStage, '', Dimensions);
    end;

    internal procedure LogMatchingCompleted(Matched: Integer; Unmatched: Integer)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add('Matched', Format(Matched));
        Dimensions.Add('Unmatched', Format(Unmatched));
        FeatureTelemetry.LogUsage('0000UCV', ExpenseAgentSetup.GetFeatureName(), MatchingCompletedMsg, Dimensions);
    end;

    internal procedure LogDraftCreated(TransEntryNo: Integer)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add('TransactionEntryNo', Format(TransEntryNo));
        FeatureTelemetry.LogUsage('0000UCW', ExpenseAgentSetup.GetFeatureName(), DraftCreatedMsg, Dimensions);
    end;

    internal procedure LogJobQueueScheduled(ProviderCode: Code[20]; Frequency: Text)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add('ProviderCode', ProviderCode);
        Dimensions.Add('Frequency', Frequency);
        FeatureTelemetry.LogUsage('0000UCX', ExpenseAgentSetup.GetFeatureName(), JobQueueScheduledMsg, Dimensions);
    end;

    internal procedure LogReportCreatedFromCorpCard()
    begin
        FeatureTelemetry.LogUsage('0000UCY', ExpenseAgentSetup.GetFeatureName(), ReportCreatedMsg);
    end;

    internal procedure LogReportSubmittedForApproval()
    begin
        FeatureTelemetry.LogUsage('0000UCZ', ExpenseAgentSetup.GetFeatureName(), ReportSubmittedMsg);
    end;

    internal procedure LogReportApprovedForPosting()
    begin
        FeatureTelemetry.LogUsage('0000UD0', ExpenseAgentSetup.GetFeatureName(), ReportApprovedMsg);
    end;

    internal procedure LogReportRejected()
    begin
        FeatureTelemetry.LogUsage('0000UD1', ExpenseAgentSetup.GetFeatureName(), ReportRejectedMsg);
    end;

    internal procedure LogStatementClosed(ProviderCode: Code[20]; StatementEntryNo: Integer)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add('ProviderCode', ProviderCode);
        Dimensions.Add('StatementEntryNo', Format(StatementEntryNo));
        FeatureTelemetry.LogUsage('0000UD2', ExpenseAgentSetup.GetFeatureName(), StatementClosedMsg, Dimensions);
    end;

    internal procedure LogSettlementPosted(ProviderCode: Code[20]; SettlementEntryNo: Integer)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add('ProviderCode', ProviderCode);
        Dimensions.Add('SettlementEntryNo', Format(SettlementEntryNo));
        FeatureTelemetry.LogUsage('0000UD3', ExpenseAgentSetup.GetFeatureName(), SettlementPostedMsg, Dimensions);
    end;

    internal procedure LogSettlementReversed(ProviderCode: Code[20]; SettlementEntryNo: Integer)
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add('ProviderCode', ProviderCode);
        Dimensions.Add('SettlementEntryNo', Format(SettlementEntryNo));
        FeatureTelemetry.LogUsage('0000UD4', ExpenseAgentSetup.GetFeatureName(), SettlementReversedMsg, Dimensions);
    end;
}
