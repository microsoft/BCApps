// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.DataMigration.BC14Reimplementation;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Structure;

codeunit 46948 "BC14 Item Ledger Migrator" implements "BC14 Migrator"
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

    /// <summary>
    /// True when the location is flagged as an in-transit location. Positive-adjustment item journal
    /// lines cannot use such a location (BC restricts in-transit locations to transfer orders), so the
    /// on-hand rebuild skips these entries.
    /// </summary>
    local procedure IsInTransitLocation(LocationCode: Code[10]): Boolean
    var
        Location: Record Location;
    begin
        if LocationCode = '' then
            exit(false);
        if not Location.Get(LocationCode) then
            exit(false);
        exit(Location."Use As In-Transit");
    end;

    /// <summary>
    /// Ensures a bin-mandatory location can receive the positive adjustment, returning false when the
    /// on-hand cannot be rebuilt through the item journal. A directed put-away and pick location posts
    /// the adjustment to its Adjustment Bin (the journal line must not name it explicitly), so that bin
    /// has to exist. A non-directed bin-mandatory location needs a bin on the line itself: the item's
    /// default bin is kept when already assigned, otherwise the Adjustment Bin is used as a fallback.
    /// </summary>
    local procedure TryResolvePostingBin(var ItemJournalLine: Record "Item Journal Line"): Boolean
    var
        Location: Record Location;
        Bin: Record Bin;
    begin
        if ItemJournalLine."Location Code" = '' then
            exit(true);
        if not Location.Get(ItemJournalLine."Location Code") then
            exit(true);
        if not Location."Bin Mandatory" then
            exit(true);

        if Location."Directed Put-away and Pick" then
            exit((Location."Adjustment Bin Code" <> '') and Bin.Get(Location.Code, Location."Adjustment Bin Code"));

        if ItemJournalLine."Bin Code" <> '' then
            exit(true);
        if (Location."Adjustment Bin Code" <> '') and Bin.Get(Location.Code, Location."Adjustment Bin Code") then begin
            ItemJournalLine.Validate("Bin Code", Location."Adjustment Bin Code");
            exit(true);
        end;
        exit(false);
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

        // In-transit locations (stock currently moving between locations on an open transfer order)
        // reject positive-adjustment item journal lines - BC allows an in-transit location on transfer
        // orders only. This on-hand cannot be rebuilt through the inventory journal, so it is left to
        // the historical-phase archive rather than logged as a per-record failure the user cannot fix.
        if IsInTransitLocation(BC14ItemLedgerEntry."Location Code") then
            exit;

        TemplateName := GetTemplateName();

        // Idempotency: a prior partial run for the same phase may have already staged this line.
        if ItemJournalLine.Get(TemplateName, BC14ItemLedgerEntry."Journal Batch Name", BC14ItemLedgerEntry."Entry No.") then
            exit;

        // Unit cost = the entry's actual total cost spread over its original quantity. Applied to the
        // remaining quantity below, this rebuilds both on-hand quantity and inventory value. Posting
        // these adjustments writes only the item and value ledger, not the G/L: "BC14 Item Journal
        // Post Action" suppresses inventory posting to the G/L while the batches post, so the rebuilt
        // on-hand does not double-count against the separate G/L Entry migrator.
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

        // A positive adjustment on a bin-mandatory location must resolve to a valid bin. Validate
        // ("Location Code") above assigns the item's default bin when one exists; for locations where
        // no postable bin can be determined (for example a directed put-away and pick location whose
        // warehouse bin setup is not migrated) the on-hand cannot be rebuilt through the item journal,
        // so it is left to the historical archive rather than failing posting with "The Bin does not
        // exist".
        if not TryResolvePostingBin(ItemJournalLine) then
            exit;

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
