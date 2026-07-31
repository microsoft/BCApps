// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace MS.DataMigration.BC14Reimplementation;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;

codeunit 66948 "BC14 Item Ledger Migrator" implements "BC14 Migrator"
{
    TableNo = "BC14 Item Ledger Entry";

    trigger OnRun()
    begin
        CreateItemJournalLine(Rec);
    end;

    var
        MigratorNameLbl: Label 'Item Ledger Entry Migrator';
        JournalTemplateNameTok: Label 'BC14MIGI', Locked = true;
        JournalTemplateDescTok: Label 'Business Central 14 Cloud Migration Inventory', Locked = true;
        JournalBatchNamePrefixTok: Label 'BC14IT', Locked = true;
        JournalBatchDescTok: Label 'Business Central 14 Item Ledger Migration %1', Locked = true, Comment = '%1 = Batch sequence number';
        DefaultDocumentNoTok: Label 'BC14-INV', Locked = true;

    procedure GetDisplayName(): Text[250]
    begin
        exit(MigratorNameLbl);
    end;

    procedure RegisterReplicationMappings(CompanyName: Text)
    var
        BC14MigrationSetup: Codeunit "BC14 Migration Setup";
    begin
        // The same buffer tables feed both this Transaction-phase migrator (which rebuilds live
        // on-hand stock) and the historical-phase archive migrator. InsertPerCompanyMapping is
        // idempotent on the source/destination pair, so registering the mappings from both
        // migrators keeps each one self-contained without creating duplicate replication rows.
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Item Ledger Entry", Database::"BC14 Item Ledger Entry");
        BC14MigrationSetup.InsertPerCompanyMapping(CompanyName, Database::"Value Entry", Database::"BC14 Value Entry");
    end;

    procedure IsEnabled(): Boolean
    var
        BC14CompanySettings: Record BC14CompanyMigrationInfo;
    begin
        BC14CompanySettings.GetSingleInstance();
        exit(BC14CompanySettings.GetInventoryModuleEnabled());
    end;

    procedure Migrate(): Boolean
    var
        BC14ItemLedgerEntry: Record "BC14 Item Ledger Entry";
        MigrationLoop: Codeunit "BC14 Migration Loop";
        SourceVariant: Variant;
        MigratorSuccess: Boolean;
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnMigrateItemLedgerEntries(IsMigrated);
        if IsMigrated then
            exit(true);

        // Pass 1: pre-assign each open buffer record to an item journal batch, capping each batch at
        // ~10,000 lines. Each line is an independent positive adjustment, so a batch can be split at
        // any record without side effects.
        AssignItemJournalBatches();

        // Pass 2: standard per-record migration loop, identical to all other migrators.
        // CreateItemJournalLine uses Get-before-Insert on Item Journal Line, so re-running the loop
        // after a partial failure does not re-insert already-staged lines.
        ApplyOpenFilter(BC14ItemLedgerEntry);
        SourceVariant := BC14ItemLedgerEntry;
        MigratorSuccess := MigrationLoop.RunRecordLoop(
            MigratorNameLbl, SourceVariant, 0,
            Codeunit::"BC14 Item Ledger Migrator");

        OnAfterMigrateItemLedgerEntries(MigratorSuccess);

        exit(MigratorSuccess);
    end;

    procedure GetRemainingPercentage(): Integer
    var
        BC14ItemLedgerEntry: Record "BC14 Item Ledger Entry";
        ItemJournalLine: Record "Item Journal Line";
        TotalCount: Integer;
        StagedCount: Integer;
    begin
        ApplyOpenFilter(BC14ItemLedgerEntry);
        TotalCount := BC14ItemLedgerEntry.Count();
        if TotalCount = 0 then
            exit(0);
        ItemJournalLine.SetRange("Journal Template Name", GetTemplateName());
        ItemJournalLine.SetFilter("Journal Batch Name", JournalBatchNamePrefixTok + '*');
        StagedCount := ItemJournalLine.Count();
        exit(Round((TotalCount - StagedCount) / TotalCount * 100, 1));
    end;

    local procedure AssignItemJournalBatches()
    var
        BC14ItemLedgerEntry: Record "BC14 Item Ledger Entry";
        CurrentBatchName: Code[10];
        BatchSeqNo: Integer;
        LinesInCurrentBatch: Integer;
    begin
        BC14ItemLedgerEntry.SetCurrentKey("Entry No.");
        ApplyOpenFilter(BC14ItemLedgerEntry);
        if not BC14ItemLedgerEntry.FindSet() then
            exit;

        BatchSeqNo := 1;
        CurrentBatchName := MakeBatchName(BatchSeqNo);
        EnsureBatchExists(CurrentBatchName, CopyStr(StrSubstNo(JournalBatchDescTok, BatchSeqNo), 1, 100));
        LinesInCurrentBatch := 0;

        repeat
            if LinesInCurrentBatch >= 10000 then begin
                BatchSeqNo += 1;
                CurrentBatchName := MakeBatchName(BatchSeqNo);
                EnsureBatchExists(CurrentBatchName, CopyStr(StrSubstNo(JournalBatchDescTok, BatchSeqNo), 1, 100));
                LinesInCurrentBatch := 0;
            end;

            if BC14ItemLedgerEntry."Journal Batch Name" <> CurrentBatchName then begin
                BC14ItemLedgerEntry."Journal Batch Name" := CurrentBatchName;
                BC14ItemLedgerEntry.Modify(false);
            end;
            LinesInCurrentBatch += 1;
        until BC14ItemLedgerEntry.Next() = 0;
    end;

    local procedure MakeBatchName(SeqNo: Integer): Code[10]
    begin
        exit(CopyStr(JournalBatchNamePrefixTok + PadLeft(Format(SeqNo), 4, '0'), 1, 10));
    end;

    /// <summary>
    /// Restricts the buffer to the open item ledger entries whose remaining quantity makes up current
    /// on-hand inventory. Unlike the customer/vendor migrators, NO "Historical Cutoff Date" split is
    /// applied: an old open inbound batch that was never fully consumed is still part of today's stock,
    /// so excluding it by posting date would understate on-hand quantity and inventory value. Every
    /// open entry is therefore rebuilt in the live item ledger; the full item ledger (including
    /// settled entries) remains available read-only via the historical-phase archive.
    /// </summary>
    local procedure ApplyOpenFilter(var BC14ItemLedgerEntry: Record "BC14 Item Ledger Entry")
    begin
        BC14ItemLedgerEntry.SetRange(Open, true);
    end;

    local procedure PadLeft(Text: Text; Length: Integer; PadChar: Char): Text
    begin
        while StrLen(Text) < Length do
            Text := PadChar + Text;
        exit(Text);
    end;

    /// <summary>
    /// Sums the actual cost of an item ledger entry from its value entries, mirroring the
    /// "Cost Amount (Actual)" FlowField on "Item Ledger Entry".
    /// </summary>
    local procedure CalcCostAmount(ItemLedgerEntryNo: Integer): Decimal
    var
        BC14ValueEntry: Record "BC14 Value Entry";
    begin
        BC14ValueEntry.SetCurrentKey("Item Ledger Entry No.");
        BC14ValueEntry.SetRange("Item Ledger Entry No.", ItemLedgerEntryNo);
        BC14ValueEntry.CalcSums("Cost Amount (Actual)");
        exit(BC14ValueEntry."Cost Amount (Actual)");
    end;

    internal procedure GetTemplateName(): Code[10]
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        if ItemJournalTemplate.Get(JournalTemplateNameTok) then
            exit(ItemJournalTemplate.Name);

        ItemJournalTemplate.Init();
        ItemJournalTemplate.Name := JournalTemplateNameTok;
        ItemJournalTemplate.Description := JournalTemplateDescTok;
        ItemJournalTemplate.Type := ItemJournalTemplate.Type::Item;
        if ItemJournalTemplate.Insert(true) then;
        exit(ItemJournalTemplate.Name);
    end;

    internal procedure EnsureBatchExists(BatchName: Code[10]; BatchDescription: Text[100])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        TemplateName: Code[10];
    begin
        TemplateName := GetTemplateName();

        if ItemJournalBatch.Get(TemplateName, BatchName) then
            exit;

        ItemJournalBatch.Init();
        ItemJournalBatch."Journal Template Name" := TemplateName;
        ItemJournalBatch.Name := BatchName;
        ItemJournalBatch.Description := BatchDescription;
        ItemJournalBatch.Insert(true);
    end;

    internal procedure CreateItemJournalLine(BC14ItemLedgerEntry: Record "BC14 Item Ledger Entry")
    var
        ItemJournalLine: Record "Item Journal Line";
        TemplateName: Code[10];
        UnitCost: Decimal;
        DocumentNo: Code[20];
        IsMigrated: Boolean;
    begin
        IsMigrated := false;
        OnBeforeCreateItemJournalLine(BC14ItemLedgerEntry, IsMigrated);
        if IsMigrated then
            exit;

        // Only open entries with a positive remaining quantity make up current on-hand stock and are
        // rebuilt as positive adjustments. Fully-consumed inbound entries (remaining 0) and outbound
        // entries (remaining <= 0) net to zero on-hand and are left to the historical-phase archive.
        if BC14ItemLedgerEntry."Remaining Quantity" <= 0 then
            exit;
        // Guard the unit-cost division below; a zero-quantity entry carries no stock to rebuild.
        if BC14ItemLedgerEntry.Quantity = 0 then
            exit;

        TemplateName := GetTemplateName();

        // Idempotency: a prior partial run for the same phase may have already staged this line.
        if ItemJournalLine.Get(TemplateName, BC14ItemLedgerEntry."Journal Batch Name", BC14ItemLedgerEntry."Entry No.") then
            exit;

        // Unit cost = the entry's actual total cost spread over its original quantity. Applied to the
        // remaining quantity below, this rebuilds both on-hand quantity and inventory value. Because
        // "Automatic Cost Posting" is off by default, posting this adjustment writes only the item and
        // value ledger (not G/L), so it does not double-count against the separate G/L Entry migrator.
        UnitCost := CalcCostAmount(BC14ItemLedgerEntry."Entry No.") / BC14ItemLedgerEntry.Quantity;

        DocumentNo := BC14ItemLedgerEntry."Document No.";
        if DocumentNo = '' then
            DocumentNo := DefaultDocumentNoTok;

        ItemJournalLine.Init();
        ItemJournalLine."Journal Template Name" := TemplateName;
        ItemJournalLine."Journal Batch Name" := BC14ItemLedgerEntry."Journal Batch Name";
        ItemJournalLine."Line No." := BC14ItemLedgerEntry."Entry No.";
        ItemJournalLine.Validate("Entry Type", ItemJournalLine."Entry Type"::"Positive Adjmt.");
        ItemJournalLine.Validate("Posting Date", BC14ItemLedgerEntry."Posting Date");
        ItemJournalLine."Document No." := DocumentNo;
        ItemJournalLine.Validate("Item No.", BC14ItemLedgerEntry."Item No.");
        ItemJournalLine.Validate("Location Code", BC14ItemLedgerEntry."Location Code");
        ItemJournalLine.Validate(Quantity, BC14ItemLedgerEntry."Remaining Quantity");
        ItemJournalLine.Validate("Unit Cost", UnitCost);
        ItemJournalLine.Description := CopyStr(BC14ItemLedgerEntry.Description, 1, MaxStrLen(ItemJournalLine.Description));
        ItemJournalLine."Shortcut Dimension 1 Code" := BC14ItemLedgerEntry."Global Dimension 1 Code";
        ItemJournalLine."Shortcut Dimension 2 Code" := BC14ItemLedgerEntry."Global Dimension 2 Code";
        ItemJournalLine."External Document No." := BC14ItemLedgerEntry."External Document No.";

        OnTransferItemLedgerEntryCustomFields(BC14ItemLedgerEntry, ItemJournalLine);

        ItemJournalLine.Insert(false);

        OnAfterCreateItemJournalLine(BC14ItemLedgerEntry, ItemJournalLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMigrateItemLedgerEntries(var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMigrateItemLedgerEntries(MigratorSuccess: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateItemJournalLine(BC14ItemLedgerEntry: Record "BC14 Item Ledger Entry"; var IsMigrated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateItemJournalLine(BC14ItemLedgerEntry: Record "BC14 Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    /// <summary>
    /// Integration event raised during item ledger migration to allow mapping of custom fields.
    /// Subscribe to transfer TableExtension fields from BC14 Item Ledger Entry to Item Journal Line.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnTransferItemLedgerEntryCustomFields(BC14ItemLedgerEntry: Record "BC14 Item Ledger Entry"; var ItemJournalLine: Record "Item Journal Line")
    begin
    end;
}
