// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Depreciation;

using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.FixedAssets.Posting;
using System.Telemetry;
using System.Upgrade;

/// <summary>
/// Per-company historical upgrade that links pre-existing French derogatory FA and maintenance ledger entries using
/// the new "Derogatory Source Entry No." relationship introduced by the redesign-derogatory-mirroring change.
/// Only mutually unique historical pairs are linked; sources with more than one remaining candidate, or whose only
/// remaining candidate is itself contested by another source, are marked ambiguous so the deterministic reversal
/// logic can fall back to the legacy heuristic for them only. No link is fabricated for missing counterparts.
/// This upgrade shim survives CLEAN30. The superseded French legacy posting implementation is removed by CLEAN30, but
/// sources that stay marked as ambiguous can still require the legacy reversal fallback, so the shim MUST be retained
/// beyond CLEAN30 until a separately approved cleanup version removes the need for that fallback.
/// </summary>
codeunit 104103 "Upgrade Derogatory Linkage"
{
    Access = Internal;
    Subtype = Upgrade;

    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagAcceleratedDepr: Codeunit "Upg. Tag Accelerated Depr.";

    trigger OnUpgradePerCompany()
    begin
        RunAfterRelationshipTransfer(false);
        RunCorrectiveUpgrade();
    end;

    /// <summary>
    /// Links pre-existing French derogatory FA/maintenance ledger entries using the complete mutually-unique
    /// matching graph. MUST be called with ForceCorrective = false immediately after the feature-enable data copy
    /// ("Accelerated Depr. Feature".UpdateData) and after the CLEAN30 relationship copy ("Upgrade Accelerated Depr."),
    /// in the same upgrade transaction as those relationship-field copies, so the relationship is guaranteed to be
    /// visible before matching runs regardless of per-company upgrade codeunit ordering. This shim survives CLEAN30.
    /// Skips all work (without setting the original tag) when no relationship pair is configured yet, so a later
    /// upgrade run can still process it once the relationship exists. Sets the original linkage tag only after all
    /// writes and telemetry succeed, and only for the non-corrective, tag-gated run.
    /// </summary>
    /// <param name="ForceCorrective">When true, bypasses the original linkage upgrade tag so the forward corrective
    /// upgrade can rebuild links after clearing them; the original tag is never set in this mode.</param>
    procedure RunAfterRelationshipTransfer(ForceCorrective: Boolean)
    var
        FALinkedCount: Integer;
        FAAmbiguousCount: Integer;
        FAMissingCount: Integer;
        MaintenanceLinkedCount: Integer;
        MaintenanceAmbiguousCount: Integer;
        MaintenanceMissingCount: Integer;
    begin
        if not ForceCorrective then
            if UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageUpgradeTag()) then
                exit;

        if not HasConfiguredRelationship() then
            exit;

        LinkFALedgerEntries(FALinkedCount, FAAmbiguousCount, FAMissingCount);
        LinkMaintenanceLedgerEntries(MaintenanceLinkedCount, MaintenanceAmbiguousCount, MaintenanceMissingCount);

        EmitLinkageTelemetry(
            FALinkedCount, FAAmbiguousCount, FAMissingCount,
            MaintenanceLinkedCount, MaintenanceAmbiguousCount, MaintenanceMissingCount);

        if not ForceCorrective then
            UpgradeTag.SetUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageUpgradeTag());
    end;

    /// <summary>
    /// Forward corrective per-company upgrade guarded by its own tag (FR-NFR-003/ITEM-025). Within one transaction,
    /// clears only "Derogatory Source Entry No." and "Legacy Derogatory Ambiguous" for historical FR
    /// source/counterpart entries in configured relationship pairs, preserves later centrally posted links, then
    /// rebuilds every link from the complete matching graph. Runs the clear and rebuild via Codeunit.Run
    /// boolean-context semantics on a separate, non-Upgrade-subtype codeunit (a
    /// codeunit whose Subtype is Upgrade cannot itself be invoked via Codeunit.Run outside the schema
    /// synchronization process). A Commit is issued immediately before the Run call to establish the commit point
    /// that the platform rolls back to on failure - this is the standard AL pattern required for Codeunit.Run
    /// boolean-context rollback to take effect; without it the platform cannot establish where to roll back to.
    /// If any step fails (for example an ambiguous depreciation-book relationship setup), every database change
    /// made during that Run - including the clears and corrective tag - is automatically rolled back, leaving no
    /// partial state, per ITEM-025/NFR-003. The corrective tag is set inside that same Run only after a successful
    /// rebuild, and only when a relationship was configured to act on.
    /// </summary>
    internal procedure RunCorrectiveUpgrade()
    var
        DerogLinkageCorrectiveRun: Codeunit "Derog. Linkage Corrective Run";
    begin
        if UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageCorrectiveUpgradeTag()) then
            exit;

        if not HasConfiguredRelationship() then
            exit;

        Commit();
        if not DerogLinkageCorrectiveRun.Run() then
            Error(GetLastErrorText());
    end;

    /// <summary>
    /// Atomic clear-then-rebuild scope invoked by codeunit "Derog. Linkage Corrective Run" via Codeunit.Run on
    /// behalf of <see cref="RunCorrectiveUpgrade"/>. Not otherwise called directly.
    /// </summary>
    internal procedure ClearAndRelinkConfiguredRelationshipPairs()
    begin
        ClearConfiguredRelationshipLinks();
        ValidateConfiguredRelationships();
        RunAfterRelationshipTransfer(true);
        UpgradeTag.SetUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageCorrectiveUpgradeTag());
    end;

    local procedure HasConfiguredRelationship(): Boolean
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        DepreciationBook.SetFilter("Derogatory Calc.", '<>%1', '');
        exit(not DepreciationBook.IsEmpty());
    end;

    local procedure ClearConfiguredRelationshipLinks()
    var
        DepreciationBook: Record "Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        UpgradeTagsRecordRef: RecordRef;
        HistoricalLinkageCutoff: DateTime;
    begin
        // System table 9999 "Upgrade Tags" is internal; fields 1, 2, and 3 are Tag, Tag Timestamp, and Company.
        UpgradeTagsRecordRef.Open(9999);
        UpgradeTagsRecordRef.Field(1).SetRange(UpgTagAcceleratedDepr.GetDerogatoryLinkageUpgradeTag());
        UpgradeTagsRecordRef.Field(3).SetRange(CompanyName());
        if UpgradeTagsRecordRef.FindFirst() then
            HistoricalLinkageCutoff := UpgradeTagsRecordRef.Field(2).Value()
        else
            HistoricalLinkageCutoff := CurrentDateTime();
        UpgradeTagsRecordRef.Close();

        DepreciationBook.SetFilter("Derogatory Calc.", '<>%1', '');
        if not DepreciationBook.FindSet() then
            exit;
        repeat
            FALedgerEntry.Reset();
            FALedgerEntry.SetFilter("Depreciation Book Code", '%1|%2', DepreciationBook."Derogatory Calc.", DepreciationBook.Code);
            FALedgerEntry.SetFilter(SystemCreatedAt, '<=%1', HistoricalLinkageCutoff);
            FALedgerEntry.ModifyAll("Derogatory Source Entry No.", 0);
            FALedgerEntry.ModifyAll("Legacy Derogatory Ambiguous", false);

            MaintenanceLedgerEntry.Reset();
            MaintenanceLedgerEntry.SetFilter("Depreciation Book Code", '%1|%2', DepreciationBook."Derogatory Calc.", DepreciationBook.Code);
            MaintenanceLedgerEntry.SetFilter(SystemCreatedAt, '<=%1', HistoricalLinkageCutoff);
            MaintenanceLedgerEntry.ModifyAll("Derogatory Source Entry No.", 0);
            MaintenanceLedgerEntry.ModifyAll("Legacy Derogatory Ambiguous", false);
        until DepreciationBook.Next() = 0;
    end;

    local procedure ValidateConfiguredRelationships()
    var
        DepreciationBook: Record "Depreciation Book";
        DerogatoryPostingMgt: Codeunit "Derogatory Posting Mgt.";
        DerogatoryDepreciationBookCode: Code[10];
    begin
        DepreciationBook.SetFilter("Derogatory Calc.", '<>%1', '');
        if DepreciationBook.FindSet() then
            repeat
                DerogatoryPostingMgt.GetDerogatoryBookCode(
                    DepreciationBook."Derogatory Calc.", DerogatoryDepreciationBookCode);
            until DepreciationBook.Next() = 0;
    end;

    local procedure EmitLinkageTelemetry(FALinkedCount: Integer; FAAmbiguousCount: Integer; FAMissingCount: Integer; MaintenanceLinkedCount: Integer; MaintenanceAmbiguousCount: Integer; MaintenanceMissingCount: Integer)
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        TelemetryDimensions: Dictionary of [Text, Text];
    begin
        TelemetryDimensions.Add('FALinked', Format(FALinkedCount));
        TelemetryDimensions.Add('FAAmbiguous', Format(FAAmbiguousCount));
        TelemetryDimensions.Add('FAMissing', Format(FAMissingCount));
        TelemetryDimensions.Add('MaintenanceLinked', Format(MaintenanceLinkedCount));
        TelemetryDimensions.Add('MaintenanceAmbiguous', Format(MaintenanceAmbiguousCount));
        TelemetryDimensions.Add('MaintenanceMissing', Format(MaintenanceMissingCount));
        FeatureTelemetry.LogUsage('0000FRD', 'Fixed Asset', 'FR historical derogatory linkage upgrade', TelemetryDimensions);
    end;

    // ---------------------------------------------------------------------------------------------------------
    // FA Ledger Entry matching
    // ---------------------------------------------------------------------------------------------------------

    internal procedure LinkFALedgerEntries(var LinkedCount: Integer; var AmbiguousCount: Integer; var MissingCount: Integer)
    var
        SourceFALedgerEntry: Record "FA Ledger Entry";
        DerogatoryPostingMgt: Codeunit "Derogatory Posting Mgt.";
        SourceToCandidates: Dictionary of [Integer, List of [Integer]];
        CandidateToSources: Dictionary of [Integer, List of [Integer]];
        SourceEntryNo: Integer;
        CandidateEntryNos: List of [Integer];
        DerogatoryDepreciationBookCode: Code[10];
    begin
        // Phase 1: collect every eligible, not-yet-resolved source's full candidate set without writing anything, so
        // the graph used to decide mutual uniqueness is complete and independent of processing order (RD-005).
        SourceFALedgerEntry.SetCurrentKey("Entry No.");
        SourceFALedgerEntry.SetRange("Legacy Derogatory Ambiguous", false);
        if SourceFALedgerEntry.FindSet() then
            repeat
                if IsEligibleFASource(SourceFALedgerEntry) and IsPendingFASource(SourceFALedgerEntry) then
                    if DerogatoryPostingMgt.GetDerogatoryBookCode(SourceFALedgerEntry."Depreciation Book Code", DerogatoryDepreciationBookCode) then begin
                        CandidateEntryNos := CollectFACandidateEntryNos(SourceFALedgerEntry, DerogatoryDepreciationBookCode);
                        SourceToCandidates.Add(SourceFALedgerEntry."Entry No.", CandidateEntryNos);
                        AddReverseCandidateLinks(CandidateToSources, CandidateEntryNos, SourceFALedgerEntry."Entry No.");
                    end;
            until SourceFALedgerEntry.Next() = 0;

        // Phase 2: apply writes using the complete graph. A pair is written only when it is mutually unique: the
        // source has exactly one candidate AND that candidate has exactly one competing source. Everything else -
        // no candidate, more than one candidate, or a single candidate contested by another source - is ambiguous
        // or missing, never guessed at.
        foreach SourceEntryNo in SourceToCandidates.Keys() do begin
            CandidateEntryNos := SourceToCandidates.Get(SourceEntryNo);
            case true of
                CandidateEntryNos.Count() = 0:
                    MissingCount += 1;
                (CandidateEntryNos.Count() = 1) and (CandidateToSources.Get(CandidateEntryNos.Get(1)).Count() = 1):
                    begin
                        LinkFAEntryByNo(CandidateEntryNos.Get(1), SourceEntryNo);
                        LinkedCount += 1;
                    end;
                else begin
                    MarkFAEntryAmbiguousByNo(SourceEntryNo);
                    AmbiguousCount += 1;
                end;
            end;
        end;
    end;

    local procedure IsEligibleFASource(SourceFALedgerEntry: Record "FA Ledger Entry"): Boolean
    begin
        if not SourceFALedgerEntry."Automatic Entry" then
            exit(true);
        if not (SourceFALedgerEntry."FA Posting Type" in
                [SourceFALedgerEntry."FA Posting Type"::Depreciation, SourceFALedgerEntry."FA Posting Type"::"Custom 1"])
        then
            exit(false);
        exit(HasAcquisitionCostSibling(SourceFALedgerEntry));
    end;

    local procedure HasAcquisitionCostSibling(FALedgerEntry: Record "FA Ledger Entry"): Boolean
    var
        AcquisitionCostFALedgerEntry: Record "FA Ledger Entry";
    begin
        AcquisitionCostFALedgerEntry.SetRange("FA No.", FALedgerEntry."FA No.");
        AcquisitionCostFALedgerEntry.SetRange("Depreciation Book Code", FALedgerEntry."Depreciation Book Code");
        AcquisitionCostFALedgerEntry.SetRange("Transaction No.", FALedgerEntry."Transaction No.");
        AcquisitionCostFALedgerEntry.SetRange("Document No.", FALedgerEntry."Document No.");
        AcquisitionCostFALedgerEntry.SetRange("Posting Date", FALedgerEntry."Posting Date");
        AcquisitionCostFALedgerEntry.SetRange("Document Date", FALedgerEntry."Document Date");
        AcquisitionCostFALedgerEntry.SetRange("FA Posting Type", AcquisitionCostFALedgerEntry."FA Posting Type"::"Acquisition Cost");
        exit(not AcquisitionCostFALedgerEntry.IsEmpty());
    end;

    local procedure IsPendingFASource(SourceFALedgerEntry: Record "FA Ledger Entry"): Boolean
    var
        ExistingLinkFALedgerEntry: Record "FA Ledger Entry";
    begin
        ExistingLinkFALedgerEntry.SetRange("Derogatory Source Entry No.", SourceFALedgerEntry."Entry No.");
        exit(ExistingLinkFALedgerEntry.IsEmpty());
    end;

    local procedure ResolveFANo(FALedgerEntry: Record "FA Ledger Entry"): Code[20]
    begin
        if FALedgerEntry."FA No." <> '' then
            exit(FALedgerEntry."FA No.");
        exit(FALedgerEntry."Canceled from FA No.");
    end;

    local procedure SameFAAssetIdentity(FALedgerEntry: Record "FA Ledger Entry"; FANo: Code[20]): Boolean
    begin
        exit(ResolveFANo(FALedgerEntry) = FANo);
    end;

    local procedure CollectFACandidateEntryNos(SourceFALedgerEntry: Record "FA Ledger Entry"; DerogatoryDepreciationBookCode: Code[10]) CandidateEntryNos: List of [Integer]
    var
        CandidateFALedgerEntry: Record "FA Ledger Entry";
        SourceFANo: Code[20];
    begin
        SourceFANo := ResolveFANo(SourceFALedgerEntry);
        SetFACandidateBaseFilters(CandidateFALedgerEntry, SourceFALedgerEntry, DerogatoryDepreciationBookCode);
        if CandidateFALedgerEntry.FindSet() then
            repeat
                if SameFAAssetIdentity(CandidateFALedgerEntry, SourceFANo) and
                   HasConsistentFAReversalChain(SourceFALedgerEntry, CandidateFALedgerEntry)
                then
                    CandidateEntryNos.Add(CandidateFALedgerEntry."Entry No.");
            until CandidateFALedgerEntry.Next() = 0;
    end;

    local procedure SetFACandidateBaseFilters(var CandidateFALedgerEntry: Record "FA Ledger Entry"; SourceFALedgerEntry: Record "FA Ledger Entry"; DerogatoryDepreciationBookCode: Code[10])
    begin
        CandidateFALedgerEntry.Reset();
        CandidateFALedgerEntry.SetRange("Depreciation Book Code", DerogatoryDepreciationBookCode);
        CandidateFALedgerEntry.SetRange("FA Posting Type", SourceFALedgerEntry."FA Posting Type");
        CandidateFALedgerEntry.SetRange(Amount, SourceFALedgerEntry.Amount);
        CandidateFALedgerEntry.SetRange("Document Type", SourceFALedgerEntry."Document Type");
        CandidateFALedgerEntry.SetRange("Document No.", SourceFALedgerEntry."Document No.");
        CandidateFALedgerEntry.SetRange("External Document No.", SourceFALedgerEntry."External Document No.");
        CandidateFALedgerEntry.SetRange("FA Posting Date", SourceFALedgerEntry."FA Posting Date");
        CandidateFALedgerEntry.SetRange("Posting Date", SourceFALedgerEntry."Posting Date");
        CandidateFALedgerEntry.SetRange("Document Date", SourceFALedgerEntry."Document Date");
        if SourceFALedgerEntry."Transaction No." = 0 then
            CandidateFALedgerEntry.SetRange("Transaction No.", 0)
        else
            CandidateFALedgerEntry.SetFilter("Transaction No.", '%1|%2', SourceFALedgerEntry."Transaction No.", 0);
        CandidateFALedgerEntry.SetRange(Reversed, SourceFALedgerEntry.Reversed);
        SetFAReversalShapeFilters(CandidateFALedgerEntry, SourceFALedgerEntry);
        CandidateFALedgerEntry.SetRange("Derogatory Source Entry No.", 0);
        CandidateFALedgerEntry.SetFilter("Entry No.", '<>%1', SourceFALedgerEntry."Entry No.");
    end;

    local procedure SetFAReversalShapeFilters(var CandidateFALedgerEntry: Record "FA Ledger Entry"; SourceFALedgerEntry: Record "FA Ledger Entry")
    begin
        if SourceFALedgerEntry."Reversed Entry No." = 0 then
            CandidateFALedgerEntry.SetRange("Reversed Entry No.", 0)
        else
            CandidateFALedgerEntry.SetFilter("Reversed Entry No.", '<>0');
        if SourceFALedgerEntry."Reversed by Entry No." = 0 then
            CandidateFALedgerEntry.SetRange("Reversed by Entry No.", 0)
        else
            CandidateFALedgerEntry.SetFilter("Reversed by Entry No.", '<>0');
    end;

    local procedure HasConsistentFAReversalChain(SourceFALedgerEntry: Record "FA Ledger Entry"; CandidateFALedgerEntry: Record "FA Ledger Entry"): Boolean
    var
        RelatedSourceFALedgerEntry: Record "FA Ledger Entry";
        RelatedCandidateFALedgerEntry: Record "FA Ledger Entry";
    begin
        if SourceFALedgerEntry."Reversed Entry No." <> 0 then begin
            if not RelatedSourceFALedgerEntry.Get(SourceFALedgerEntry."Reversed Entry No.") then
                exit(false);
            if not RelatedCandidateFALedgerEntry.Get(CandidateFALedgerEntry."Reversed Entry No.") then
                exit(false);
            if (RelatedSourceFALedgerEntry."Depreciation Book Code" <> SourceFALedgerEntry."Depreciation Book Code") or
               (RelatedCandidateFALedgerEntry."Depreciation Book Code" <> CandidateFALedgerEntry."Depreciation Book Code") or
               (RelatedSourceFALedgerEntry."Reversed by Entry No." <> SourceFALedgerEntry."Entry No.") or
               (RelatedCandidateFALedgerEntry."Reversed by Entry No." <> CandidateFALedgerEntry."Entry No.") or
               not HasMatchingFAIdentity(RelatedSourceFALedgerEntry, RelatedCandidateFALedgerEntry)
            then
                exit(false);
        end;

        if SourceFALedgerEntry."Reversed by Entry No." <> 0 then begin
            if not RelatedSourceFALedgerEntry.Get(SourceFALedgerEntry."Reversed by Entry No.") then
                exit(false);
            if not RelatedCandidateFALedgerEntry.Get(CandidateFALedgerEntry."Reversed by Entry No.") then
                exit(false);
            if (RelatedSourceFALedgerEntry."Depreciation Book Code" <> SourceFALedgerEntry."Depreciation Book Code") or
               (RelatedCandidateFALedgerEntry."Depreciation Book Code" <> CandidateFALedgerEntry."Depreciation Book Code") or
               (RelatedSourceFALedgerEntry."Reversed Entry No." <> SourceFALedgerEntry."Entry No.") or
               (RelatedCandidateFALedgerEntry."Reversed Entry No." <> CandidateFALedgerEntry."Entry No.") or
               not HasMatchingFAIdentity(RelatedSourceFALedgerEntry, RelatedCandidateFALedgerEntry)
            then
                exit(false);
        end;

        exit(true);
    end;

    local procedure HasMatchingFAIdentity(SourceFALedgerEntry: Record "FA Ledger Entry"; CandidateFALedgerEntry: Record "FA Ledger Entry"): Boolean
    begin
        exit(
            (CandidateFALedgerEntry."Depreciation Book Code" <> SourceFALedgerEntry."Depreciation Book Code") and
            SameFAAssetIdentity(CandidateFALedgerEntry, ResolveFANo(SourceFALedgerEntry)) and
            (CandidateFALedgerEntry."FA Posting Type" = SourceFALedgerEntry."FA Posting Type") and
            (CandidateFALedgerEntry.Amount = SourceFALedgerEntry.Amount) and
            (CandidateFALedgerEntry."Document Type" = SourceFALedgerEntry."Document Type") and
            (CandidateFALedgerEntry."Document No." = SourceFALedgerEntry."Document No.") and
            (CandidateFALedgerEntry."External Document No." = SourceFALedgerEntry."External Document No.") and
            (CandidateFALedgerEntry."FA Posting Date" = SourceFALedgerEntry."FA Posting Date") and
            (CandidateFALedgerEntry."Posting Date" = SourceFALedgerEntry."Posting Date") and
            (CandidateFALedgerEntry."Document Date" = SourceFALedgerEntry."Document Date") and
            TransactionsMatch(SourceFALedgerEntry."Transaction No.", CandidateFALedgerEntry."Transaction No.") and
            (CandidateFALedgerEntry.Reversed = SourceFALedgerEntry.Reversed) and
            ((CandidateFALedgerEntry."Reversed Entry No." = 0) = (SourceFALedgerEntry."Reversed Entry No." = 0)) and
            ((CandidateFALedgerEntry."Reversed by Entry No." = 0) = (SourceFALedgerEntry."Reversed by Entry No." = 0)));
    end;

    local procedure TransactionsMatch(SourceTransactionNo: Integer; CandidateTransactionNo: Integer): Boolean
    begin
        if SourceTransactionNo = 0 then
            exit(CandidateTransactionNo = 0);
        exit(CandidateTransactionNo in [SourceTransactionNo, 0]);
    end;

    local procedure AddReverseCandidateLinks(var CandidateToSources: Dictionary of [Integer, List of [Integer]]; CandidateEntryNos: List of [Integer]; SourceEntryNo: Integer)
    var
        Sources: List of [Integer];
        CandidateEntryNo: Integer;
    begin
        foreach CandidateEntryNo in CandidateEntryNos do begin
            Clear(Sources);
            if CandidateToSources.ContainsKey(CandidateEntryNo) then begin
                Sources := CandidateToSources.Get(CandidateEntryNo);
                CandidateToSources.Remove(CandidateEntryNo);
            end;
            Sources.Add(SourceEntryNo);
            CandidateToSources.Add(CandidateEntryNo, Sources);
        end;
    end;

    local procedure LinkFAEntryByNo(EntryNo: Integer; SourceEntryNo: Integer)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.Get(EntryNo);
        FALedgerEntry."Derogatory Source Entry No." := SourceEntryNo;
        FALedgerEntry.Modify();
    end;

    local procedure MarkFAEntryAmbiguousByNo(EntryNo: Integer)
    var
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        FALedgerEntry.Get(EntryNo);
        FALedgerEntry."Legacy Derogatory Ambiguous" := true;
        FALedgerEntry.Modify();
    end;

    // ---------------------------------------------------------------------------------------------------------
    // Maintenance Ledger Entry matching
    // ---------------------------------------------------------------------------------------------------------

    internal procedure LinkMaintenanceLedgerEntries(var LinkedCount: Integer; var AmbiguousCount: Integer; var MissingCount: Integer)
    var
        SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        DerogatoryPostingMgt: Codeunit "Derogatory Posting Mgt.";
        SourceToCandidates: Dictionary of [Integer, List of [Integer]];
        CandidateToSources: Dictionary of [Integer, List of [Integer]];
        SourceEntryNo: Integer;
        CandidateEntryNos: List of [Integer];
        DerogatoryDepreciationBookCode: Code[10];
    begin
        // Phase 1: collect every eligible, not-yet-resolved source's full candidate set without writing anything.
        SourceMaintenanceLedgerEntry.SetCurrentKey("Entry No.");
        SourceMaintenanceLedgerEntry.SetRange("Automatic Entry", false);
        SourceMaintenanceLedgerEntry.SetRange("Legacy Derogatory Ambiguous", false);
        if SourceMaintenanceLedgerEntry.FindSet() then
            repeat
                if IsPendingMaintenanceSource(SourceMaintenanceLedgerEntry) then
                    if DerogatoryPostingMgt.GetDerogatoryBookCode(SourceMaintenanceLedgerEntry."Depreciation Book Code", DerogatoryDepreciationBookCode) then begin
                        CandidateEntryNos := CollectMaintenanceCandidateEntryNos(SourceMaintenanceLedgerEntry, DerogatoryDepreciationBookCode);
                        SourceToCandidates.Add(SourceMaintenanceLedgerEntry."Entry No.", CandidateEntryNos);
                        AddReverseCandidateLinks(CandidateToSources, CandidateEntryNos, SourceMaintenanceLedgerEntry."Entry No.");
                    end;
            until SourceMaintenanceLedgerEntry.Next() = 0;

        // Phase 2: apply writes using the complete graph, on the same mutual-uniqueness rule as the FA side.
        foreach SourceEntryNo in SourceToCandidates.Keys() do begin
            CandidateEntryNos := SourceToCandidates.Get(SourceEntryNo);
            case true of
                CandidateEntryNos.Count() = 0:
                    MissingCount += 1;
                (CandidateEntryNos.Count() = 1) and (CandidateToSources.Get(CandidateEntryNos.Get(1)).Count() = 1):
                    begin
                        LinkMaintenanceEntryByNo(CandidateEntryNos.Get(1), SourceEntryNo);
                        LinkedCount += 1;
                    end;
                else begin
                    MarkMaintenanceEntryAmbiguousByNo(SourceEntryNo);
                    AmbiguousCount += 1;
                end;
            end;
        end;
    end;

    local procedure IsPendingMaintenanceSource(SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry"): Boolean
    var
        ExistingLinkMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        ExistingLinkMaintenanceLedgerEntry.SetRange("Derogatory Source Entry No.", SourceMaintenanceLedgerEntry."Entry No.");
        exit(ExistingLinkMaintenanceLedgerEntry.IsEmpty());
    end;

    local procedure CollectMaintenanceCandidateEntryNos(SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; DerogatoryDepreciationBookCode: Code[10]) CandidateEntryNos: List of [Integer]
    var
        CandidateMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        SetMaintenanceCandidateBaseFilters(CandidateMaintenanceLedgerEntry, SourceMaintenanceLedgerEntry, DerogatoryDepreciationBookCode);
        if CandidateMaintenanceLedgerEntry.FindSet() then
            repeat
                if HasConsistentMaintenanceReversalChain(SourceMaintenanceLedgerEntry, CandidateMaintenanceLedgerEntry) then
                    CandidateEntryNos.Add(CandidateMaintenanceLedgerEntry."Entry No.");
            until CandidateMaintenanceLedgerEntry.Next() = 0;
    end;

    local procedure SetMaintenanceCandidateBaseFilters(var CandidateMaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; DerogatoryDepreciationBookCode: Code[10])
    begin
        CandidateMaintenanceLedgerEntry.Reset();
        CandidateMaintenanceLedgerEntry.SetRange("Depreciation Book Code", DerogatoryDepreciationBookCode);
        CandidateMaintenanceLedgerEntry.SetRange("FA No.", SourceMaintenanceLedgerEntry."FA No.");
        CandidateMaintenanceLedgerEntry.SetRange("Maintenance Code", SourceMaintenanceLedgerEntry."Maintenance Code");
        CandidateMaintenanceLedgerEntry.SetRange(Amount, SourceMaintenanceLedgerEntry.Amount);
        CandidateMaintenanceLedgerEntry.SetRange("Document Type", SourceMaintenanceLedgerEntry."Document Type");
        CandidateMaintenanceLedgerEntry.SetRange("Document No.", SourceMaintenanceLedgerEntry."Document No.");
        CandidateMaintenanceLedgerEntry.SetRange("External Document No.", SourceMaintenanceLedgerEntry."External Document No.");
        CandidateMaintenanceLedgerEntry.SetRange("FA Posting Date", SourceMaintenanceLedgerEntry."FA Posting Date");
        CandidateMaintenanceLedgerEntry.SetRange("Posting Date", SourceMaintenanceLedgerEntry."Posting Date");
        CandidateMaintenanceLedgerEntry.SetRange("Document Date", SourceMaintenanceLedgerEntry."Document Date");
        if SourceMaintenanceLedgerEntry."Transaction No." = 0 then
            CandidateMaintenanceLedgerEntry.SetRange("Transaction No.", 0)
        else
            CandidateMaintenanceLedgerEntry.SetFilter("Transaction No.", '%1|%2', SourceMaintenanceLedgerEntry."Transaction No.", 0);
        CandidateMaintenanceLedgerEntry.SetRange(Reversed, SourceMaintenanceLedgerEntry.Reversed);
        SetMaintenanceReversalShapeFilters(CandidateMaintenanceLedgerEntry, SourceMaintenanceLedgerEntry);
        CandidateMaintenanceLedgerEntry.SetRange("Derogatory Source Entry No.", 0);
        CandidateMaintenanceLedgerEntry.SetFilter("Entry No.", '<>%1', SourceMaintenanceLedgerEntry."Entry No.");
    end;

    local procedure SetMaintenanceReversalShapeFilters(var CandidateMaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry")
    begin
        if SourceMaintenanceLedgerEntry."Reversed Entry No." = 0 then
            CandidateMaintenanceLedgerEntry.SetRange("Reversed Entry No.", 0)
        else
            CandidateMaintenanceLedgerEntry.SetFilter("Reversed Entry No.", '<>0');
        if SourceMaintenanceLedgerEntry."Reversed by Entry No." = 0 then
            CandidateMaintenanceLedgerEntry.SetRange("Reversed by Entry No.", 0)
        else
            CandidateMaintenanceLedgerEntry.SetFilter("Reversed by Entry No.", '<>0');
    end;

    local procedure HasConsistentMaintenanceReversalChain(SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; CandidateMaintenanceLedgerEntry: Record "Maintenance Ledger Entry"): Boolean
    var
        RelatedSourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        RelatedCandidateMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        if SourceMaintenanceLedgerEntry."Reversed Entry No." <> 0 then begin
            if not RelatedSourceMaintenanceLedgerEntry.Get(SourceMaintenanceLedgerEntry."Reversed Entry No.") then
                exit(false);
            if not RelatedCandidateMaintenanceLedgerEntry.Get(CandidateMaintenanceLedgerEntry."Reversed Entry No.") then
                exit(false);
            if (RelatedSourceMaintenanceLedgerEntry."Depreciation Book Code" <> SourceMaintenanceLedgerEntry."Depreciation Book Code") or
               (RelatedCandidateMaintenanceLedgerEntry."Depreciation Book Code" <> CandidateMaintenanceLedgerEntry."Depreciation Book Code") or
               (RelatedSourceMaintenanceLedgerEntry."Reversed by Entry No." <> SourceMaintenanceLedgerEntry."Entry No.") or
               (RelatedCandidateMaintenanceLedgerEntry."Reversed by Entry No." <> CandidateMaintenanceLedgerEntry."Entry No.") or
               not HasMatchingMaintenanceIdentity(RelatedSourceMaintenanceLedgerEntry, RelatedCandidateMaintenanceLedgerEntry)
            then
                exit(false);
        end;

        if SourceMaintenanceLedgerEntry."Reversed by Entry No." <> 0 then begin
            if not RelatedSourceMaintenanceLedgerEntry.Get(SourceMaintenanceLedgerEntry."Reversed by Entry No.") then
                exit(false);
            if not RelatedCandidateMaintenanceLedgerEntry.Get(CandidateMaintenanceLedgerEntry."Reversed by Entry No.") then
                exit(false);
            if (RelatedSourceMaintenanceLedgerEntry."Depreciation Book Code" <> SourceMaintenanceLedgerEntry."Depreciation Book Code") or
               (RelatedCandidateMaintenanceLedgerEntry."Depreciation Book Code" <> CandidateMaintenanceLedgerEntry."Depreciation Book Code") or
               (RelatedSourceMaintenanceLedgerEntry."Reversed Entry No." <> SourceMaintenanceLedgerEntry."Entry No.") or
               (RelatedCandidateMaintenanceLedgerEntry."Reversed Entry No." <> CandidateMaintenanceLedgerEntry."Entry No.") or
               not HasMatchingMaintenanceIdentity(RelatedSourceMaintenanceLedgerEntry, RelatedCandidateMaintenanceLedgerEntry)
            then
                exit(false);
        end;

        exit(true);
    end;

    local procedure HasMatchingMaintenanceIdentity(SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; CandidateMaintenanceLedgerEntry: Record "Maintenance Ledger Entry"): Boolean
    begin
        exit(
            (CandidateMaintenanceLedgerEntry."Depreciation Book Code" <> SourceMaintenanceLedgerEntry."Depreciation Book Code") and
            (CandidateMaintenanceLedgerEntry."FA No." = SourceMaintenanceLedgerEntry."FA No.") and
            (CandidateMaintenanceLedgerEntry."Maintenance Code" = SourceMaintenanceLedgerEntry."Maintenance Code") and
            (CandidateMaintenanceLedgerEntry.Amount = SourceMaintenanceLedgerEntry.Amount) and
            (CandidateMaintenanceLedgerEntry."Document Type" = SourceMaintenanceLedgerEntry."Document Type") and
            (CandidateMaintenanceLedgerEntry."Document No." = SourceMaintenanceLedgerEntry."Document No.") and
            (CandidateMaintenanceLedgerEntry."External Document No." = SourceMaintenanceLedgerEntry."External Document No.") and
            (CandidateMaintenanceLedgerEntry."FA Posting Date" = SourceMaintenanceLedgerEntry."FA Posting Date") and
            (CandidateMaintenanceLedgerEntry."Posting Date" = SourceMaintenanceLedgerEntry."Posting Date") and
            (CandidateMaintenanceLedgerEntry."Document Date" = SourceMaintenanceLedgerEntry."Document Date") and
            TransactionsMatch(SourceMaintenanceLedgerEntry."Transaction No.", CandidateMaintenanceLedgerEntry."Transaction No.") and
            (CandidateMaintenanceLedgerEntry.Reversed = SourceMaintenanceLedgerEntry.Reversed) and
            ((CandidateMaintenanceLedgerEntry."Reversed Entry No." = 0) = (SourceMaintenanceLedgerEntry."Reversed Entry No." = 0)) and
            ((CandidateMaintenanceLedgerEntry."Reversed by Entry No." = 0) = (SourceMaintenanceLedgerEntry."Reversed by Entry No." = 0)));
    end;

    local procedure LinkMaintenanceEntryByNo(EntryNo: Integer; SourceEntryNo: Integer)
    var
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        MaintenanceLedgerEntry.Get(EntryNo);
        MaintenanceLedgerEntry."Derogatory Source Entry No." := SourceEntryNo;
        MaintenanceLedgerEntry.Modify();
    end;

    local procedure MarkMaintenanceEntryAmbiguousByNo(EntryNo: Integer)
    var
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        MaintenanceLedgerEntry.Get(EntryNo);
        MaintenanceLedgerEntry."Legacy Derogatory Ambiguous" := true;
        MaintenanceLedgerEntry.Modify();
    end;
}
