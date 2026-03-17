// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14;

using Microsoft.Finance.GeneralLedger.Journal;
using System.Integration;

codeunit 50152 "BC14 Helper Functions"
{
    var
        ProcessesAreRunningLbl: Label 'Migration processes are running.', Locked = true;
        MigrationErrorOccurredLbl: Label 'An error occurred during BC14 cloud migration.', Locked = true;
        MigrationTypeTok: Label 'BC14 Cloud Migration', Locked = true;
        TelemetryCategoryTok: Label 'BC14 Cloud Migration', Locked = true;
        JournalTemplateNameTok: Label 'BC14MIG', Locked = true;
        JournalTemplateDescTok: Label 'BC14 Cloud Migration', Locked = true;

    internal procedure SetProcessesRunning(IsRunning: Boolean)
    var
        BC14UpgradeSettings: Record "BC14 Upgrade Settings";
    begin
        BC14UpgradeSettings.SetMigrationInProgress(IsRunning);

        if IsRunning then
            Session.LogMessage('0000RO8', ProcessesAreRunningLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GetTelemetryCategory());
    end;

    internal procedure GetMigrationTypeTok(): Text[250]
    begin
        exit(MigrationTypeTok);
    end;

    internal procedure GetTelemetryCategory(): Text
    begin
        exit(TelemetryCategoryTok);
    end;

    internal procedure CreatePreMigrationData(): Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreatePreMigrationData(IsHandled);
        if IsHandled then
            exit(true);

        // Add any pre-migration data creation logic here
        // For example, creating posting groups, number series, etc.

        OnAfterCreatePreMigrationData();
        exit(true);
    end;

    internal procedure CreatePostMigrationData(): Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreatePostMigrationData(IsHandled);
        if IsHandled then
            exit(true);

        // Add any post-migration data creation logic here
        // For example, running additional validations, cleanup, etc.

        OnAfterCreatePostMigrationData();
        exit(true);
    end;

    internal procedure RunPreMigrationCleanup()
    var
        DataMigrationStatus: Record "Data Migration Status";
        DataMigrationEntity: Record "Data Migration Entity";
    begin
        // Clean up any previous migration status records
        DataMigrationStatus.SetRange("Migration Type", GetMigrationTypeTok());
        DataMigrationStatus.DeleteAll();

        // Clean up any previous Data Migration Entity records
        DataMigrationEntity.DeleteAll();
    end;

    internal procedure LogLastError()
    begin
        if GetLastErrorText() <> '' then
            Session.LogMessage('0000RO9', MigrationErrorOccurredLbl, Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GetTelemetryCategory());
    end;

    /// <summary>
    /// Gets the default General Journal Template name for migration entries.
    /// </summary>
    internal procedure GetGeneralJournalTemplateName(): Code[10]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::General);
        GenJournalTemplate.SetRange(Recurring, false);
        if GenJournalTemplate.FindFirst() then
            exit(GenJournalTemplate.Name);

        // Create default template if not found
        GenJournalTemplate.Init();
        GenJournalTemplate.Name := JournalTemplateNameTok;
        GenJournalTemplate.Description := JournalTemplateDescTok;
        GenJournalTemplate.Type := GenJournalTemplate.Type::General;
        GenJournalTemplate.Recurring := false;
        if GenJournalTemplate.Insert(true) then;
        exit(GenJournalTemplate.Name);
    end;

    /// <summary>
    /// Ensures a General Journal Batch exists for migration.
    /// Following GP pattern for journal batch creation.
    /// </summary>
    internal procedure EnsureGenJournalBatchExists(BatchName: Code[10]; BatchDescription: Text[100])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        TemplateName: Code[10];
    begin
        TemplateName := GetGeneralJournalTemplateName();

        if GenJournalBatch.Get(TemplateName, BatchName) then
            exit;

        GenJournalBatch.Init();
        GenJournalBatch."Journal Template Name" := TemplateName;
        GenJournalBatch.Name := BatchName;
        GenJournalBatch.Description := BatchDescription;
        GenJournalBatch.Insert(true);
    end;

    /// <summary>
    /// Opens any buffer table record for editing using the generic BC14 Buffer Record Editor page.
    /// </summary>
    internal procedure OpenBufferRecord(SourceTableId: Integer; SourceRecordId: RecordId): Boolean
    var
        BC14BufferRecordEditor: Page "BC14 Buffer Record Editor";
    begin
        if SourceTableId = 0 then
            exit(false);

        if Format(SourceRecordId) = '' then
            exit(false);

        BC14BufferRecordEditor.SetSourceRecord(SourceRecordId);
        BC14BufferRecordEditor.RunModal();
        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePreMigrationData(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePreMigrationData()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePostMigrationData(var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePostMigrationData()
    begin
    end;
}
