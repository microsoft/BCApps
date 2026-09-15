// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;

codeunit 46896 "BC14 Journal Post Action" implements "BC14 Post Migration Action"
{
    var
        BC14Telemetry: Codeunit "BC14 Telemetry";
        MigratorNameLbl: Label 'Journal Post';
        CleanedInvalidJournalLinesLbl: Label 'Cleaned up %1 invalid journal lines (Amount = 0)', Locked = true, Comment = '%1 = Count';
        JournalPostingLbl: Label 'Journal Posting - %1', Locked = true, Comment = '%1 = Batch Name';
        JournalBatchInfoLbl: Label 'Template=%1, Batch=%2', Locked = true, Comment = '%1 = Template, %2 = Batch';
        PostMigrationJournalsCompletedLbl: Label 'PostMigrationJournals completed. Posted %1 batches.', Locked = true, Comment = '%1 = Count';
        PostMigrationJournalsSkippedLbl: Label 'PostMigrationJournals skipped - Skip Posting enabled', Locked = true;

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure IsEnabled(): Boolean
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
    begin
        BC14CompanySettings.GetSingleInstance();
        exit(not BC14CompanySettings."Posting Completed");
    end;

    procedure RunAction(): Boolean
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14JournalMgmt: Codeunit "BC14 Journal Management";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        GenJnlPostBatch: Codeunit "Gen. Jnl.-Post Batch";
        TemplateName: Code[10];
        SkipPosting: Boolean;
        BatchCount: Integer;
        FailedBatchCount: Integer;
        CleanedLinesCount: Integer;
    begin
        BC14CompanySettings.GetSingleInstance();
        SkipPosting := BC14CompanySettings.GetSkipPostingJournalBatches();

        // Allow extensions to add their own journal lines before posting
        OnBeforePostMigrationJournals(SkipPosting);

        if SkipPosting then begin
            Session.LogMessage('0000TTQ', PostMigrationJournalsSkippedLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            exit(true);
        end;

        TemplateName := BC14JournalMgmt.GetTemplateName();

        // Clean up invalid journal lines before posting (Amount = 0)
        CleanedLinesCount := CleanupInvalidJournalLines(TemplateName);
        if CleanedLinesCount > 0 then
            Session.LogMessage('0000TTR', StrSubstNo(CleanedInvalidJournalLinesLbl, CleanedLinesCount), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());

        // Find and post all BC14 migration batches.
        GenJournalBatch.SetRange("Journal Template Name", TemplateName);
        GenJournalBatch.SetFilter(Name, 'BC14*'); // All BC14 migration batches
        if GenJournalBatch.FindSet() then
            repeat
                GenJournalLine.SetRange("Journal Template Name", TemplateName);
                GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
                if GenJournalLine.FindFirst() then begin
                    Commit();
                    if not GenJnlPostBatch.Run(GenJournalLine) then begin
                        BC14MigrationErrorHandler.LogError(StrSubstNo(JournalPostingLbl, GenJournalBatch.Name), Database::"Gen. Journal Line", 'Gen. Journal Line', StrSubstNo(JournalBatchInfoLbl, TemplateName, GenJournalBatch.Name), Database::"Gen. Journal Line", GetLastErrorText(), GenJournalLine.RecordId);
                        FailedBatchCount += 1;
                        ClearLastError();
                        Clear(GenJnlPostBatch);
                    end else begin
                        BC14MigrationErrorHandler.ResolveErrorForRecord(Database::"Gen. Journal Line", StrSubstNo(JournalBatchInfoLbl, TemplateName, GenJournalBatch.Name));
                        BatchCount += 1;
                    end;
                end;
            until GenJournalBatch.Next() = 0;

        Session.LogMessage('0000TTS', StrSubstNo(PostMigrationJournalsCompletedLbl, BatchCount), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());

        // Allow extensions to run custom logic after posting
        OnAfterPostMigrationJournals(BatchCount);

        exit(FailedBatchCount = 0);
    end;

    internal procedure CleanupInvalidJournalLines(TemplateName: Code[10]): Integer
    var
        GenJournalLine: Record "Gen. Journal Line";
        CleanedCount: Integer;
    begin
        GenJournalLine.SetRange("Journal Template Name", TemplateName);
        GenJournalLine.SetFilter("Journal Batch Name", 'BC14*');
        GenJournalLine.SetRange(Amount, 0);

        CleanedCount := GenJournalLine.Count();
        if CleanedCount > 0 then
            GenJournalLine.DeleteAll();

        exit(CleanedCount);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostMigrationJournals(var SkipPosting: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostMigrationJournals(BatchCount: Integer)
    begin
    end;
}
