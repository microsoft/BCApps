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
/// Only uniquely identifiable historical pairs are linked; ambiguous normal-book sources are marked so the deterministic
/// reversal logic can fall back to the legacy heuristic for them only. No link is fabricated for missing counterparts.
/// This upgrade shim must be retained until the FR CLEAN29 cleanup version removes the historical derogatory data model.
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
        UpgradeDerogatoryLinkage();
    end;

    local procedure UpgradeDerogatoryLinkage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        TelemetryDimensions: Dictionary of [Text, Text];
        FALinkedCount: Integer;
        FAAmbiguousCount: Integer;
        FAMissingCount: Integer;
        MaintenanceLinkedCount: Integer;
        MaintenanceAmbiguousCount: Integer;
        MaintenanceMissingCount: Integer;
    begin
        if UpgradeTag.HasUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageUpgradeTag()) then
            exit;

        LinkFALedgerEntries(FALinkedCount, FAAmbiguousCount, FAMissingCount);
        LinkMaintenanceLedgerEntries(MaintenanceLinkedCount, MaintenanceAmbiguousCount, MaintenanceMissingCount);

        TelemetryDimensions.Add('FALinked', Format(FALinkedCount));
        TelemetryDimensions.Add('FAAmbiguous', Format(FAAmbiguousCount));
        TelemetryDimensions.Add('FAMissing', Format(FAMissingCount));
        TelemetryDimensions.Add('MaintenanceLinked', Format(MaintenanceLinkedCount));
        TelemetryDimensions.Add('MaintenanceAmbiguous', Format(MaintenanceAmbiguousCount));
        TelemetryDimensions.Add('MaintenanceMissing', Format(MaintenanceMissingCount));
        FeatureTelemetry.LogUsage('0000FRD', 'Fixed Asset', 'FR historical derogatory linkage upgrade', TelemetryDimensions);

        UpgradeTag.SetUpgradeTag(UpgTagAcceleratedDepr.GetDerogatoryLinkageUpgradeTag());
    end;

    internal procedure LinkFALedgerEntries(var LinkedCount: Integer; var AmbiguousCount: Integer; var MissingCount: Integer)
    var
        SourceFALedgerEntry: Record "FA Ledger Entry";
        CandidateFALedgerEntry: Record "FA Ledger Entry";
        BestCandidateFALedgerEntry: Record "FA Ledger Entry";
        DerogatoryPostingMgt: Codeunit "Derogatory Posting Mgt.";
        DerogatoryDepreciationBookCode: Code[10];
    begin
        SourceFALedgerEntry.SetCurrentKey("Entry No.");
        SourceFALedgerEntry.SetRange("Automatic Entry", false);
        if not SourceFALedgerEntry.FindSet() then
            exit;
        repeat
            if DerogatoryPostingMgt.GetDerogatoryBookCode(SourceFALedgerEntry."Depreciation Book Code", DerogatoryDepreciationBookCode) then begin
                FindFACandidates(CandidateFALedgerEntry, SourceFALedgerEntry, DerogatoryDepreciationBookCode);
                case CandidateFALedgerEntry.Count() of
                    0:
                        MissingCount += 1;
                    1:
                        begin
                            CandidateFALedgerEntry.FindFirst();
                            LinkFAEntry(CandidateFALedgerEntry, SourceFALedgerEntry."Entry No.");
                            LinkedCount += 1;
                        end;
                    else
                        if SelectUniqueClosestFAEntry(CandidateFALedgerEntry, SourceFALedgerEntry."Entry No.", BestCandidateFALedgerEntry) then begin
                            LinkFAEntry(BestCandidateFALedgerEntry, SourceFALedgerEntry."Entry No.");
                            LinkedCount += 1;
                        end else begin
                            MarkFAEntryAmbiguous(SourceFALedgerEntry);
                            AmbiguousCount += 1;
                        end;
                end;
            end;
        until SourceFALedgerEntry.Next() = 0;
    end;

    local procedure FindFACandidates(var CandidateFALedgerEntry: Record "FA Ledger Entry"; SourceFALedgerEntry: Record "FA Ledger Entry"; DerogatoryDepreciationBookCode: Code[10])
    begin
        CandidateFALedgerEntry.Reset();
        CandidateFALedgerEntry.SetRange("Depreciation Book Code", DerogatoryDepreciationBookCode);
        CandidateFALedgerEntry.SetRange("FA No.", SourceFALedgerEntry."FA No.");
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

    local procedure SelectUniqueClosestFAEntry(var CandidateFALedgerEntry: Record "FA Ledger Entry"; SourceEntryNo: Integer; var BestCandidateFALedgerEntry: Record "FA Ledger Entry"): Boolean
    var
        BestDistance: Integer;
        CurrentDistance: Integer;
        TieCount: Integer;
    begin
        BestDistance := -1;
        TieCount := 0;
        if CandidateFALedgerEntry.FindSet() then
            repeat
                CurrentDistance := Abs(CandidateFALedgerEntry."Entry No." - SourceEntryNo);
                if (BestDistance = -1) or (CurrentDistance < BestDistance) then begin
                    BestDistance := CurrentDistance;
                    BestCandidateFALedgerEntry := CandidateFALedgerEntry;
                    TieCount := 1;
                end else
                    if CurrentDistance = BestDistance then
                        TieCount += 1;
            until CandidateFALedgerEntry.Next() = 0;
        exit(TieCount = 1);
    end;

    local procedure LinkFAEntry(var DerogatoryFALedgerEntry: Record "FA Ledger Entry"; SourceEntryNo: Integer)
    begin
        DerogatoryFALedgerEntry."Derogatory Source Entry No." := SourceEntryNo;
        DerogatoryFALedgerEntry.Modify();
    end;

    local procedure MarkFAEntryAmbiguous(var SourceFALedgerEntry: Record "FA Ledger Entry")
    begin
        SourceFALedgerEntry."Legacy Derogatory Ambiguous" := true;
        SourceFALedgerEntry.Modify();
    end;

    internal procedure LinkMaintenanceLedgerEntries(var LinkedCount: Integer; var AmbiguousCount: Integer; var MissingCount: Integer)
    var
        SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        CandidateMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        BestCandidateMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        DerogatoryPostingMgt: Codeunit "Derogatory Posting Mgt.";
        DerogatoryDepreciationBookCode: Code[10];
    begin
        SourceMaintenanceLedgerEntry.SetCurrentKey("Entry No.");
        SourceMaintenanceLedgerEntry.SetRange("Automatic Entry", false);
        if not SourceMaintenanceLedgerEntry.FindSet() then
            exit;
        repeat
            if DerogatoryPostingMgt.GetDerogatoryBookCode(SourceMaintenanceLedgerEntry."Depreciation Book Code", DerogatoryDepreciationBookCode) then begin
                FindMaintenanceCandidates(CandidateMaintenanceLedgerEntry, SourceMaintenanceLedgerEntry, DerogatoryDepreciationBookCode);
                case CandidateMaintenanceLedgerEntry.Count() of
                    0:
                        MissingCount += 1;
                    1:
                        begin
                            CandidateMaintenanceLedgerEntry.FindFirst();
                            LinkMaintenanceEntry(CandidateMaintenanceLedgerEntry, SourceMaintenanceLedgerEntry."Entry No.");
                            LinkedCount += 1;
                        end;
                    else
                        if SelectUniqueClosestMaintenanceEntry(CandidateMaintenanceLedgerEntry, SourceMaintenanceLedgerEntry."Entry No.", BestCandidateMaintenanceLedgerEntry) then begin
                            LinkMaintenanceEntry(BestCandidateMaintenanceLedgerEntry, SourceMaintenanceLedgerEntry."Entry No.");
                            LinkedCount += 1;
                        end else begin
                            MarkMaintenanceEntryAmbiguous(SourceMaintenanceLedgerEntry);
                            AmbiguousCount += 1;
                        end;
                end;
            end;
        until SourceMaintenanceLedgerEntry.Next() = 0;
    end;

    local procedure FindMaintenanceCandidates(var CandidateMaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; DerogatoryDepreciationBookCode: Code[10])
    begin
        CandidateMaintenanceLedgerEntry.Reset();
        CandidateMaintenanceLedgerEntry.SetRange("Depreciation Book Code", DerogatoryDepreciationBookCode);
        CandidateMaintenanceLedgerEntry.SetRange("FA No.", SourceMaintenanceLedgerEntry."FA No.");
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

    local procedure SelectUniqueClosestMaintenanceEntry(var CandidateMaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; SourceEntryNo: Integer; var BestCandidateMaintenanceLedgerEntry: Record "Maintenance Ledger Entry"): Boolean
    var
        BestDistance: Integer;
        CurrentDistance: Integer;
        TieCount: Integer;
    begin
        BestDistance := -1;
        TieCount := 0;
        if CandidateMaintenanceLedgerEntry.FindSet() then
            repeat
                CurrentDistance := Abs(CandidateMaintenanceLedgerEntry."Entry No." - SourceEntryNo);
                if (BestDistance = -1) or (CurrentDistance < BestDistance) then begin
                    BestDistance := CurrentDistance;
                    BestCandidateMaintenanceLedgerEntry := CandidateMaintenanceLedgerEntry;
                    TieCount := 1;
                end else
                    if CurrentDistance = BestDistance then
                        TieCount += 1;
            until CandidateMaintenanceLedgerEntry.Next() = 0;
        exit(TieCount = 1);
    end;

    local procedure LinkMaintenanceEntry(var DerogatoryMaintenanceLedgerEntry: Record "Maintenance Ledger Entry"; SourceEntryNo: Integer)
    begin
        DerogatoryMaintenanceLedgerEntry."Derogatory Source Entry No." := SourceEntryNo;
        DerogatoryMaintenanceLedgerEntry.Modify();
    end;

    local procedure MarkMaintenanceEntryAmbiguous(var SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry")
    begin
        SourceMaintenanceLedgerEntry."Legacy Derogatory Ambiguous" := true;
        SourceMaintenanceLedgerEntry.Modify();
    end;
}
