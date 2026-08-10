// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Posting;

codeunit 46949 "BC14 Item Journal Post Action" implements "BC14 Post Migration Action"
{
    var
        BC14Telemetry: Codeunit "BC14 Telemetry";
        MigratorNameLbl: Label 'Item Journal Post';
        JournalPostingLbl: Label 'Item Journal Posting - %1', Locked = true, Comment = '%1 = Batch Name';
        JournalBatchInfoLbl: Label 'Template=%1, Batch=%2', Locked = true, Comment = '%1 = Template, %2 = Batch';
        PostMigrationItemJournalsCompletedLbl: Label 'PostMigrationItemJournals completed. Posted %1 batches.', Locked = true, Comment = '%1 = Count';
        PostMigrationItemJournalsSkippedLbl: Label 'PostMigrationItemJournals skipped - Skip Posting enabled', Locked = true;

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
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
        BC14ItemLedgerMigrator: Codeunit "BC14 Item Ledger Migrator";
        BC14MigrationErrorHandler: Codeunit "BC14 Migration Error Handler";
        BC14InvPostGLGuard: Codeunit "BC14 Inv. Post. G/L Guard";
        ItemJnlPostBatch: Codeunit "Item Jnl.-Post Batch";
        TemplateName: Code[10];
        SkipPosting: Boolean;
        BatchCount: Integer;
        FailedBatchCount: Integer;
    begin
        BC14CompanySettings.GetSingleInstance();
        SkipPosting := BC14CompanySettings.GetSkipPostingJournalBatches();

        // Allow extensions to add their own item journal lines before posting
        OnBeforePostMigrationItemJournals(SkipPosting);

        if SkipPosting then begin
            Session.LogMessage('0000ZC0', PostMigrationItemJournalsSkippedLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());
            exit(true);
        end;

        TemplateName := BC14ItemLedgerMigrator.GetTemplateName();

        // Rebuilding on-hand as positive adjustments must not post inventory cost to the G/L: the
        // G/L balances are migrated separately by the G/L entry migrator, so posting cost here as
        // well would double-count inventory value and would additionally require the full Inventory
        // Posting Setup and General Posting Setup accounts (Inventory Account, Inventory Adjmt.
        // Account, ...) in the target. The guard suppresses inventory posting to the G/L for the
        // duration of the item journal posting; it is turned off again once posting completes.
        BC14InvPostGLGuard.SetSuppressInvtPostingToGL(true);

        // Find and post all BC14 item migration batches. Unlike the gen. journal post action, invalid
        // (Amount = 0) lines are NOT cleaned up first: an item received at zero cost is legitimate
        // stock, and dropping it would lose on-hand quantity.
        ItemJournalBatch.SetRange("Journal Template Name", TemplateName);
        ItemJournalBatch.SetFilter(Name, 'BC14*'); // All BC14 item migration batches
        if ItemJournalBatch.FindSet() then
            repeat
                ItemJournalLine.SetRange("Journal Template Name", TemplateName);
                ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
                if ItemJournalLine.FindFirst() then begin
                    Commit();
                    if not ItemJnlPostBatch.Run(ItemJournalLine) then begin
                        BC14MigrationErrorHandler.LogError(StrSubstNo(JournalPostingLbl, ItemJournalBatch.Name), Database::"Item Journal Line", 'Item Journal Line', StrSubstNo(JournalBatchInfoLbl, TemplateName, ItemJournalBatch.Name), Database::"Item Journal Line", GetLastErrorText(), ItemJournalLine.RecordId);
                        FailedBatchCount += 1;
                        ClearLastError();
                        Clear(ItemJnlPostBatch);
                    end else begin
                        BC14MigrationErrorHandler.ResolveErrorForRecord(Database::"Item Journal Line", StrSubstNo(JournalBatchInfoLbl, TemplateName, ItemJournalBatch.Name));
                        BatchCount += 1;
                    end;
                end;
            until ItemJournalBatch.Next() = 0;

        // Stop suppressing inventory posting to the G/L now that all migration batches have posted.
        BC14InvPostGLGuard.SetSuppressInvtPostingToGL(false);

        Session.LogMessage('0000ZC1', StrSubstNo(PostMigrationItemJournalsCompletedLbl, BatchCount), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', BC14Telemetry.GetCategory());

        // Allow extensions to run custom logic after posting
        OnAfterPostMigrationItemJournals(BatchCount);

        exit(FailedBatchCount = 0);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostMigrationItemJournals(var SkipPosting: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostMigrationItemJournals(BatchCount: Integer)
    begin
    end;
}
