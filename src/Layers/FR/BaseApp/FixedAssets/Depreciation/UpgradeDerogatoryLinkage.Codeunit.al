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
/// Per-company upgrade that links existing French derogatory FA and maintenance ledger entries through
/// the "Derogatory Source Entry No." field. A link is created only when the source and counterpart form a
/// unique pair. Sources with multiple possible matches, or with a match shared by another source, are marked
/// as ambiguous so reversal can use the legacy matching logic. Sources without a counterpart remain unlinked.
/// </summary>
codeunit 104103 "Upgrade Derogatory Linkage"
{
    Access = Internal;
    Subtype = Upgrade;
    Permissions = tabledata "FA Ledger Entry" = rm,
                  tabledata "Maintenance Ledger Entry" = rm;

    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgTagAcceleratedDepr: Codeunit "Upg. Tag Accelerated Depr.";

    trigger OnUpgradePerCompany()
    begin
        RunStandaloneUpgrade();
    end;

    internal procedure RunStandaloneUpgrade()
    begin
        if not UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetAcceleratedDepreciationUpgradeTag()) then
            exit;

        RunAfterRelationshipTransfer(false);
    end;

    /// <summary>
    /// Links existing French derogatory FA and maintenance ledger entries after depreciation book relationships
    /// have been copied. Uniqueness is checked in both directions before links are created, making the
    /// result independent of processing order without retaining every matching pair. If no relationship is
    /// configured, the procedure exits without
    /// setting the upgrade tag so a later upgrade can try again. For a standard run, the tag is set only after
    /// all links are updated and telemetry is logged successfully.
    /// </summary>
    /// <param name="ForceCorrective">Specifies whether to ignore the original upgrade tag while rebuilding links.
    /// The original tag is not set when this parameter is true.</param>
    procedure RunAfterRelationshipTransfer(ForceCorrective: Boolean)
    var
        FALinkedCount: Integer;
        FAAmbiguousCount: Integer;
        FAMissingCount: Integer;
        MaintenanceLinkedCount: Integer;
        MaintenanceAmbiguousCount: Integer;
        MaintenanceMissingCount: Integer;
    begin
        if not ForceCorrective then begin
            if UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageCorrectiveUpgradeTag()) then
                exit;

            if UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageUpgradeTag()) then begin
                RunCorrectiveUpgrade();
                exit;
            end;
        end;

        if not HasConfiguredRelationship() then
            exit;

        LinkFALedgerEntries(FALinkedCount, FAAmbiguousCount, FAMissingCount);
        LinkMaintenanceLedgerEntries(MaintenanceLinkedCount, MaintenanceAmbiguousCount, MaintenanceMissingCount);

        EmitLinkageTelemetry(
            FALinkedCount, FAAmbiguousCount, FAMissingCount,
            MaintenanceLinkedCount, MaintenanceAmbiguousCount, MaintenanceMissingCount);

        if not ForceCorrective then begin
            UpgradeTag.SetUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageUpgradeTag());
            UpgradeTag.SetUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageCorrectiveUpgradeTag());
        end;
    end;

    /// <summary>
    /// Runs the corrective upgrade once for each company. Historical links and ambiguity markers for configured
    /// depreciation book relationships are cleared and rebuilt, while newer links and links to former source
    /// books are kept. The work stays in
    /// the caller's transaction so a failure also rolls back the enclosing field migration. The
    /// corrective upgrade tag is set only after the rebuild succeeds.
    /// </summary>
    internal procedure RunCorrectiveUpgrade()
    begin
        if UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageCorrectiveUpgradeTag()) then
            exit;

        if not HasConfiguredRelationship() then
            exit;

        ClearAndRelinkConfiguredRelationshipPairs();
    end;

    /// <summary>
    /// Clears historical links for configured depreciation book relationships, validates the relationships,
    /// rebuilds the links, and sets the corrective upgrade tag in the caller's transaction.
    /// </summary>
    internal procedure ClearAndRelinkConfiguredRelationshipPairs()
    begin
        ValidateConfiguredRelationships();
        ClearConfiguredRelationshipLinks();
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
        HistoricalLinkageCutoff: DateTime;
    begin
        if not UpgradeTag.GetUpgradeTagTimestamp(
             UpgTagAcceleratedDepr.GetDerogatoryLinkageUpgradeTag(), HistoricalLinkageCutoff)
        then
            exit;

        DepreciationBook.SetFilter("Derogatory Calc.", '<>%1', '');
        if not DepreciationBook.FindSet() then
            exit;
        repeat
            ClearFARelationshipLinks(DepreciationBook."Derogatory Calc.", DepreciationBook.Code, HistoricalLinkageCutoff);
            ClearMaintenanceRelationshipLinks(DepreciationBook."Derogatory Calc.", DepreciationBook.Code, HistoricalLinkageCutoff);
        until DepreciationBook.Next() = 0;
    end;

    local procedure ClearFARelationshipLinks(SourceDepreciationBookCode: Code[10]; DerogatoryDepreciationBookCode: Code[10]; HistoricalLinkageCutoff: DateTime)
    var
        SourceFALedgerEntry: Record "FA Ledger Entry";
        CounterpartFALedgerEntry: Record "FA Ledger Entry";
    begin
        SourceFALedgerEntry.SetRange("Depreciation Book Code", SourceDepreciationBookCode);
        SourceFALedgerEntry.SetRange("Derogatory Source Entry No.", 0);
        SourceFALedgerEntry.SetFilter(SystemCreatedAt, '<=%1', HistoricalLinkageCutoff);
        SourceFALedgerEntry.ModifyAll("Legacy Derogatory Ambiguous", false);
        SourceFALedgerEntry.Reset();
        SourceFALedgerEntry.SetLoadFields("Depreciation Book Code");

        CounterpartFALedgerEntry.SetRange("Depreciation Book Code", DerogatoryDepreciationBookCode);
        CounterpartFALedgerEntry.SetFilter(SystemCreatedAt, '<=%1', HistoricalLinkageCutoff);
        CounterpartFALedgerEntry.SetFilter("Derogatory Source Entry No.", '<>0');
        if CounterpartFALedgerEntry.FindSet(true) then
            repeat
                // A reassigned tax book can still hold authoritative links to its former source book.
                if not SourceFALedgerEntry.Get(CounterpartFALedgerEntry."Derogatory Source Entry No.") or
                   (SourceFALedgerEntry."Depreciation Book Code" = SourceDepreciationBookCode)
                then begin
                    CounterpartFALedgerEntry."Derogatory Source Entry No." := 0;
                    CounterpartFALedgerEntry."Legacy Derogatory Ambiguous" := false;
                    CounterpartFALedgerEntry.Modify();
                end;
            until CounterpartFALedgerEntry.Next() = 0;
    end;

    local procedure ClearMaintenanceRelationshipLinks(SourceDepreciationBookCode: Code[10]; DerogatoryDepreciationBookCode: Code[10]; HistoricalLinkageCutoff: DateTime)
    var
        SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        CounterpartMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        SourceMaintenanceLedgerEntry.SetRange("Depreciation Book Code", SourceDepreciationBookCode);
        SourceMaintenanceLedgerEntry.SetRange("Derogatory Source Entry No.", 0);
        SourceMaintenanceLedgerEntry.SetFilter(SystemCreatedAt, '<=%1', HistoricalLinkageCutoff);
        SourceMaintenanceLedgerEntry.ModifyAll("Legacy Derogatory Ambiguous", false);
        SourceMaintenanceLedgerEntry.Reset();
        SourceMaintenanceLedgerEntry.SetLoadFields("Depreciation Book Code");

        CounterpartMaintenanceLedgerEntry.SetRange("Depreciation Book Code", DerogatoryDepreciationBookCode);
        CounterpartMaintenanceLedgerEntry.SetFilter(SystemCreatedAt, '<=%1', HistoricalLinkageCutoff);
        CounterpartMaintenanceLedgerEntry.SetFilter("Derogatory Source Entry No.", '<>0');
        if CounterpartMaintenanceLedgerEntry.FindSet(true) then
            repeat
                if not SourceMaintenanceLedgerEntry.Get(CounterpartMaintenanceLedgerEntry."Derogatory Source Entry No.") or
                   (SourceMaintenanceLedgerEntry."Depreciation Book Code" = SourceDepreciationBookCode)
                then begin
                    CounterpartMaintenanceLedgerEntry."Derogatory Source Entry No." := 0;
                    CounterpartMaintenanceLedgerEntry."Legacy Derogatory Ambiguous" := false;
                    CounterpartMaintenanceLedgerEntry.Modify();
                end;
            until CounterpartMaintenanceLedgerEntry.Next() = 0;
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
        CandidateFALedgerEntry: Record "FA Ledger Entry";
        DerogatoryPostingMgt: Codeunit "Derogatory Posting Mgt.";
        SourceToCandidates: Dictionary of [Integer, List of [Integer]];
        CandidateToSourceCount: Dictionary of [Integer, Integer];
        SourceEntryNo: Integer;
        CandidateEntryNos: List of [Integer];
        SourceEntryNos: List of [Integer];
        DerogatoryDepreciationBookCode: Code[10];
        MutuallyUnique: Boolean;
    begin
        // Two matches prove ambiguity. Check singleton candidates in reverse before writing any links.
        SourceFALedgerEntry.SetCurrentKey("Entry No.");
        SourceFALedgerEntry.SetRange("Derogatory Source Entry No.", 0);
        if SourceFALedgerEntry.FindSet() then
            repeat
                if IsEligibleFASource(SourceFALedgerEntry) and IsPendingFASource(SourceFALedgerEntry) then
                    if DerogatoryPostingMgt.GetDerogatoryBookCode(SourceFALedgerEntry."Depreciation Book Code", DerogatoryDepreciationBookCode) then
                        if not SourceFALedgerEntry."Legacy Derogatory Ambiguous" then begin
                            CandidateEntryNos := CollectFAMatchingEntryNos(SourceFALedgerEntry, DerogatoryDepreciationBookCode, false);
                            SourceToCandidates.Add(SourceFALedgerEntry."Entry No.", CandidateEntryNos);
                            if CandidateEntryNos.Count() = 1 then
                                if not CandidateToSourceCount.ContainsKey(CandidateEntryNos.Get(1)) then begin
                                    CandidateFALedgerEntry.Get(CandidateEntryNos.Get(1));
                                    // Reverse matching includes previously ambiguous sources and sources with multiple candidates.
                                    SourceEntryNos := CollectFAMatchingEntryNos(CandidateFALedgerEntry, SourceFALedgerEntry."Depreciation Book Code", true);
                                    CandidateToSourceCount.Add(CandidateEntryNos.Get(1), SourceEntryNos.Count());
                                end;
                        end;
            until SourceFALedgerEntry.Next() = 0;

        foreach SourceEntryNo in SourceToCandidates.Keys() do begin
            CandidateEntryNos := SourceToCandidates.Get(SourceEntryNo);
            MutuallyUnique := false;
            if CandidateEntryNos.Count() = 1 then
                MutuallyUnique := CandidateToSourceCount.Get(CandidateEntryNos.Get(1)) = 1;
            case true of
                CandidateEntryNos.Count() = 0:
                    MissingCount += 1;
                MutuallyUnique:
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
                [SourceFALedgerEntry."FA Posting Type"::Depreciation, SourceFALedgerEntry."FA Posting Type"::"Custom 1",
                 SourceFALedgerEntry."FA Posting Type"::Derogatory, SourceFALedgerEntry."FA Posting Type"::"Salvage Value"])
        then
            exit(false);
        exit(HasAcquisitionCostSibling(SourceFALedgerEntry));
    end;

    local procedure HasAcquisitionCostSibling(FALedgerEntry: Record "FA Ledger Entry"): Boolean
    var
        AcquisitionCostFALedgerEntry: Record "FA Ledger Entry";
    begin
        AcquisitionCostFALedgerEntry.SetRange("FA No.", FALedgerEntry."FA No.");
        if FALedgerEntry."FA No." = '' then
            AcquisitionCostFALedgerEntry.SetRange("Canceled from FA No.", FALedgerEntry."Canceled from FA No.");
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

    local procedure CollectFAMatchingEntryNos(ReferenceFALedgerEntry: Record "FA Ledger Entry"; MatchingDepreciationBookCode: Code[10]; FindSources: Boolean) MatchingEntryNos: List of [Integer]
    var
        MatchingFALedgerEntry: Record "FA Ledger Entry";
        FANo: Code[20];
    begin
        FANo := ResolveFANo(ReferenceFALedgerEntry);
        SetFAMatchingBaseFilters(MatchingFALedgerEntry, ReferenceFALedgerEntry, MatchingDepreciationBookCode, FindSources);
        MatchingFALedgerEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Date");
        MatchingFALedgerEntry.SetRange("FA No.", FANo);
        if FANo = '' then
            MatchingFALedgerEntry.SetRange("Canceled from FA No.", '');
        AddFAMatchingEntryNos(MatchingFALedgerEntry, ReferenceFALedgerEntry, FindSources, MatchingEntryNos);

        if (FANo = '') or (MatchingEntryNos.Count() = 2) then
            exit;

        MatchingFALedgerEntry.SetCurrentKey("Canceled from FA No.", "Depreciation Book Code", "FA Posting Date");
        MatchingFALedgerEntry.SetRange("FA No.", '');
        MatchingFALedgerEntry.SetRange("Canceled from FA No.", FANo);
        AddFAMatchingEntryNos(MatchingFALedgerEntry, ReferenceFALedgerEntry, FindSources, MatchingEntryNos);
    end;

    local procedure AddFAMatchingEntryNos(var MatchingFALedgerEntry: Record "FA Ledger Entry"; ReferenceFALedgerEntry: Record "FA Ledger Entry"; FindSources: Boolean; var MatchingEntryNos: List of [Integer])
    var
        Matches: Boolean;
    begin
        if MatchingFALedgerEntry.Find('-') then
            repeat
                if FindSources then
                    Matches := IsEligibleFASource(MatchingFALedgerEntry) and IsPendingFASource(MatchingFALedgerEntry) and
                        HasConsistentFAReversalChain(MatchingFALedgerEntry, ReferenceFALedgerEntry)
                else
                    Matches := HasConsistentFAReversalChain(ReferenceFALedgerEntry, MatchingFALedgerEntry);
                if Matches then begin
                    MatchingEntryNos.Add(MatchingFALedgerEntry."Entry No.");
                    if MatchingEntryNos.Count() = 2 then
                        exit;
                end;
            until MatchingFALedgerEntry.Next() = 0;
    end;

    local procedure SetFAMatchingBaseFilters(var MatchingFALedgerEntry: Record "FA Ledger Entry"; ReferenceFALedgerEntry: Record "FA Ledger Entry"; MatchingDepreciationBookCode: Code[10]; FindSources: Boolean)
    begin
        MatchingFALedgerEntry.Reset();
        MatchingFALedgerEntry.SetRange("Depreciation Book Code", MatchingDepreciationBookCode);
        MatchingFALedgerEntry.SetRange("FA Posting Type", ReferenceFALedgerEntry."FA Posting Type");
        MatchingFALedgerEntry.SetRange(Amount, ReferenceFALedgerEntry.Amount);
        MatchingFALedgerEntry.SetRange("Document Type", ReferenceFALedgerEntry."Document Type");
        MatchingFALedgerEntry.SetRange("Document No.", ReferenceFALedgerEntry."Document No.");
        MatchingFALedgerEntry.SetRange("External Document No.", ReferenceFALedgerEntry."External Document No.");
        MatchingFALedgerEntry.SetRange("FA Posting Date", ReferenceFALedgerEntry."FA Posting Date");
        MatchingFALedgerEntry.SetRange("Posting Date", ReferenceFALedgerEntry."Posting Date");
        MatchingFALedgerEntry.SetRange("Document Date", ReferenceFALedgerEntry."Document Date");
        if FindSources then begin
            // A transaction-zero counterpart can match a source in any transaction.
            if ReferenceFALedgerEntry."Transaction No." <> 0 then
                MatchingFALedgerEntry.SetRange("Transaction No.", ReferenceFALedgerEntry."Transaction No.");
        end else
            if ReferenceFALedgerEntry."Transaction No." = 0 then
                MatchingFALedgerEntry.SetRange("Transaction No.", 0)
            else
                MatchingFALedgerEntry.SetFilter("Transaction No.", '%1|%2', ReferenceFALedgerEntry."Transaction No.", 0);
        MatchingFALedgerEntry.SetRange(Reversed, ReferenceFALedgerEntry.Reversed);
        SetFAReversalShapeFilters(MatchingFALedgerEntry, ReferenceFALedgerEntry);
        MatchingFALedgerEntry.SetRange("Derogatory Source Entry No.", 0);
        MatchingFALedgerEntry.SetFilter("Entry No.", '<>%1', ReferenceFALedgerEntry."Entry No.");
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
               not HasMatchingFAIdentity(RelatedSourceFALedgerEntry, RelatedCandidateFALedgerEntry) or
               not HasConsistentFAExistingLink(RelatedSourceFALedgerEntry, RelatedCandidateFALedgerEntry)
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
               not HasMatchingFAIdentity(RelatedSourceFALedgerEntry, RelatedCandidateFALedgerEntry) or
               not HasConsistentFAExistingLink(RelatedSourceFALedgerEntry, RelatedCandidateFALedgerEntry)
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

    local procedure HasConsistentFAExistingLink(SourceFALedgerEntry: Record "FA Ledger Entry"; CandidateFALedgerEntry: Record "FA Ledger Entry"): Boolean
    var
        ExistingLinkFALedgerEntry: Record "FA Ledger Entry";
    begin
        if SourceFALedgerEntry."Derogatory Source Entry No." <> 0 then
            exit(false);
        if (CandidateFALedgerEntry."Derogatory Source Entry No." <> 0) and
           (CandidateFALedgerEntry."Derogatory Source Entry No." <> SourceFALedgerEntry."Entry No.")
        then
            exit(false);

        ExistingLinkFALedgerEntry.SetRange("Derogatory Source Entry No.", SourceFALedgerEntry."Entry No.");
        ExistingLinkFALedgerEntry.SetFilter("Entry No.", '<>%1', CandidateFALedgerEntry."Entry No.");
        exit(ExistingLinkFALedgerEntry.IsEmpty());
    end;

    local procedure TransactionsMatch(SourceTransactionNo: Integer; CandidateTransactionNo: Integer): Boolean
    begin
        if SourceTransactionNo = 0 then
            exit(CandidateTransactionNo = 0);
        exit(CandidateTransactionNo in [SourceTransactionNo, 0]);
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
        CandidateMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        DerogatoryPostingMgt: Codeunit "Derogatory Posting Mgt.";
        SourceToCandidates: Dictionary of [Integer, List of [Integer]];
        CandidateToSourceCount: Dictionary of [Integer, Integer];
        SourceEntryNo: Integer;
        CandidateEntryNos: List of [Integer];
        SourceEntryNos: List of [Integer];
        DerogatoryDepreciationBookCode: Code[10];
        MutuallyUnique: Boolean;
    begin
        // Resolve both directions before writing, retaining at most two matches per lookup.
        SourceMaintenanceLedgerEntry.SetCurrentKey("Entry No.");
        SourceMaintenanceLedgerEntry.SetRange("Automatic Entry", false);
        SourceMaintenanceLedgerEntry.SetRange("Derogatory Source Entry No.", 0);
        if SourceMaintenanceLedgerEntry.FindSet() then
            repeat
                if IsPendingMaintenanceSource(SourceMaintenanceLedgerEntry) then
                    if DerogatoryPostingMgt.GetDerogatoryBookCode(SourceMaintenanceLedgerEntry."Depreciation Book Code", DerogatoryDepreciationBookCode) then
                        if not SourceMaintenanceLedgerEntry."Legacy Derogatory Ambiguous" then begin
                            CandidateEntryNos := CollectMaintenanceMatchingEntryNos(SourceMaintenanceLedgerEntry, DerogatoryDepreciationBookCode, false);
                            SourceToCandidates.Add(SourceMaintenanceLedgerEntry."Entry No.", CandidateEntryNos);
                            if CandidateEntryNos.Count() = 1 then
                                if not CandidateToSourceCount.ContainsKey(CandidateEntryNos.Get(1)) then begin
                                    CandidateMaintenanceLedgerEntry.Get(CandidateEntryNos.Get(1));
                                    SourceEntryNos := CollectMaintenanceMatchingEntryNos(CandidateMaintenanceLedgerEntry, SourceMaintenanceLedgerEntry."Depreciation Book Code", true);
                                    CandidateToSourceCount.Add(CandidateEntryNos.Get(1), SourceEntryNos.Count());
                                end;
                        end;
            until SourceMaintenanceLedgerEntry.Next() = 0;

        foreach SourceEntryNo in SourceToCandidates.Keys() do begin
            CandidateEntryNos := SourceToCandidates.Get(SourceEntryNo);
            MutuallyUnique := false;
            if CandidateEntryNos.Count() = 1 then
                MutuallyUnique := CandidateToSourceCount.Get(CandidateEntryNos.Get(1)) = 1;
            case true of
                CandidateEntryNos.Count() = 0:
                    MissingCount += 1;
                MutuallyUnique:
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

    local procedure CollectMaintenanceMatchingEntryNos(ReferenceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; MatchingDepreciationBookCode: Code[10]; FindSources: Boolean) MatchingEntryNos: List of [Integer]
    var
        MatchingMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        Matches: Boolean;
    begin
        SetMaintenanceMatchingBaseFilters(MatchingMaintenanceLedgerEntry, ReferenceMaintenanceLedgerEntry, MatchingDepreciationBookCode, FindSources);
        if MatchingMaintenanceLedgerEntry.Find('-') then
            repeat
                if FindSources then
                    Matches := IsPendingMaintenanceSource(MatchingMaintenanceLedgerEntry) and
                        HasConsistentMaintenanceReversalChain(MatchingMaintenanceLedgerEntry, ReferenceMaintenanceLedgerEntry)
                else
                    Matches := HasConsistentMaintenanceReversalChain(ReferenceMaintenanceLedgerEntry, MatchingMaintenanceLedgerEntry);
                if Matches then begin
                    MatchingEntryNos.Add(MatchingMaintenanceLedgerEntry."Entry No.");
                    if MatchingEntryNos.Count() = 2 then
                        exit;
                end;
            until MatchingMaintenanceLedgerEntry.Next() = 0;
    end;

    local procedure SetMaintenanceMatchingBaseFilters(var MatchingMaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; ReferenceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; MatchingDepreciationBookCode: Code[10]; FindSources: Boolean)
    begin
        MatchingMaintenanceLedgerEntry.Reset();
        MatchingMaintenanceLedgerEntry.SetRange("Depreciation Book Code", MatchingDepreciationBookCode);
        MatchingMaintenanceLedgerEntry.SetRange("FA No.", ReferenceMaintenanceLedgerEntry."FA No.");
        MatchingMaintenanceLedgerEntry.SetRange("Maintenance Code", ReferenceMaintenanceLedgerEntry."Maintenance Code");
        MatchingMaintenanceLedgerEntry.SetRange(Amount, ReferenceMaintenanceLedgerEntry.Amount);
        MatchingMaintenanceLedgerEntry.SetRange("Document Type", ReferenceMaintenanceLedgerEntry."Document Type");
        MatchingMaintenanceLedgerEntry.SetRange("Document No.", ReferenceMaintenanceLedgerEntry."Document No.");
        MatchingMaintenanceLedgerEntry.SetRange("External Document No.", ReferenceMaintenanceLedgerEntry."External Document No.");
        MatchingMaintenanceLedgerEntry.SetRange("FA Posting Date", ReferenceMaintenanceLedgerEntry."FA Posting Date");
        MatchingMaintenanceLedgerEntry.SetRange("Posting Date", ReferenceMaintenanceLedgerEntry."Posting Date");
        MatchingMaintenanceLedgerEntry.SetRange("Document Date", ReferenceMaintenanceLedgerEntry."Document Date");
        if FindSources then begin
            MatchingMaintenanceLedgerEntry.SetRange("Automatic Entry", false);
            if ReferenceMaintenanceLedgerEntry."Transaction No." <> 0 then
                MatchingMaintenanceLedgerEntry.SetRange("Transaction No.", ReferenceMaintenanceLedgerEntry."Transaction No.");
        end else
            if ReferenceMaintenanceLedgerEntry."Transaction No." = 0 then
                MatchingMaintenanceLedgerEntry.SetRange("Transaction No.", 0)
            else
                MatchingMaintenanceLedgerEntry.SetFilter("Transaction No.", '%1|%2', ReferenceMaintenanceLedgerEntry."Transaction No.", 0);
        MatchingMaintenanceLedgerEntry.SetRange(Reversed, ReferenceMaintenanceLedgerEntry.Reversed);
        SetMaintenanceReversalShapeFilters(MatchingMaintenanceLedgerEntry, ReferenceMaintenanceLedgerEntry);
        MatchingMaintenanceLedgerEntry.SetRange("Derogatory Source Entry No.", 0);
        MatchingMaintenanceLedgerEntry.SetFilter("Entry No.", '<>%1', ReferenceMaintenanceLedgerEntry."Entry No.");
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
               not HasMatchingMaintenanceIdentity(RelatedSourceMaintenanceLedgerEntry, RelatedCandidateMaintenanceLedgerEntry) or
               not HasConsistentMaintenanceExistingLink(RelatedSourceMaintenanceLedgerEntry, RelatedCandidateMaintenanceLedgerEntry)
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
               not HasMatchingMaintenanceIdentity(RelatedSourceMaintenanceLedgerEntry, RelatedCandidateMaintenanceLedgerEntry) or
               not HasConsistentMaintenanceExistingLink(RelatedSourceMaintenanceLedgerEntry, RelatedCandidateMaintenanceLedgerEntry)
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

    local procedure HasConsistentMaintenanceExistingLink(SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; CandidateMaintenanceLedgerEntry: Record "Maintenance Ledger Entry"): Boolean
    var
        ExistingLinkMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
    begin
        if SourceMaintenanceLedgerEntry."Derogatory Source Entry No." <> 0 then
            exit(false);
        if (CandidateMaintenanceLedgerEntry."Derogatory Source Entry No." <> 0) and
           (CandidateMaintenanceLedgerEntry."Derogatory Source Entry No." <> SourceMaintenanceLedgerEntry."Entry No.")
        then
            exit(false);

        ExistingLinkMaintenanceLedgerEntry.SetRange("Derogatory Source Entry No.", SourceMaintenanceLedgerEntry."Entry No.");
        ExistingLinkMaintenanceLedgerEntry.SetFilter("Entry No.", '<>%1', CandidateMaintenanceLedgerEntry."Entry No.");
        exit(ExistingLinkMaintenanceLedgerEntry.IsEmpty());
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
