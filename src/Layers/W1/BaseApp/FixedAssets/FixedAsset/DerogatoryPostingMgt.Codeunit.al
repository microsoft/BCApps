// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Posting;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;

codeunit 5869 "Derogatory Posting Mgt."
{
    Access = Internal;

    procedure GetDerogatoryBookCode(SourceDepreciationBookCode: Code[10]; var DerogatoryDepreciationBookCode: Code[10]): Boolean
    var
        DepreciationBook: Record "Depreciation Book";
    begin
        Clear(DerogatoryDepreciationBookCode);
        DepreciationBook.SetRange("Derogatory Calc.", SourceDepreciationBookCode);
        if not DepreciationBook.FindSet() then
            exit(false);

        DerogatoryDepreciationBookCode := DepreciationBook.Code;
        if DepreciationBook.Next() <> 0 then
            Error(AmbiguousDerogatoryBookErr, SourceDepreciationBookCode);

        exit(true);
    end;

    procedure GetDerogatoryBook(SourceDepreciationBookCode: Code[10]; var DerogatoryDepreciationBook: Record "Depreciation Book"): Boolean
    var
        DerogatoryDepreciationBookCode: Code[10];
    begin
        Clear(DerogatoryDepreciationBook);
        if not GetDerogatoryBookCode(SourceDepreciationBookCode, DerogatoryDepreciationBookCode) then
            exit(false);

        exit(DerogatoryDepreciationBook.Get(DerogatoryDepreciationBookCode));
    end;

    procedure IsEligible(FANo: Code[20]; SourceDepreciationBookCode: Code[10]; PostingRole: Enum "Derogatory Posting Role"; var DerogatoryDepreciationBookCode: Code[10]): Boolean
    var
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        if PostingRole <> PostingRole::Source then
            exit(false);
        if not GetDerogatoryBookCode(SourceDepreciationBookCode, DerogatoryDepreciationBookCode) then
            exit(false);

        exit(FADepreciationBook.Get(FANo, DerogatoryDepreciationBookCode));
    end;

    procedure MakeDerogatoryJournalLine(var DerogatoryFAJournalLine: Record "FA Journal Line"; SourceFAJournalLine: Record "FA Journal Line"; PostingRole: Enum "Derogatory Posting Role"): Boolean
    var
        DerogatoryDepreciationBookCode: Code[10];
    begin
        if not IsEligible(SourceFAJournalLine."FA No.", SourceFAJournalLine."Depreciation Book Code", PostingRole, DerogatoryDepreciationBookCode) then
            exit(false);

        DerogatoryFAJournalLine.Copy(SourceFAJournalLine);
        DerogatoryFAJournalLine.Validate("Depreciation Book Code", DerogatoryDepreciationBookCode);
        exit(true);
    end;

    procedure MakeDerogatoryJournalLine(var DerogatoryFAJournalLine: Record "FA Journal Line"; SourceGenJournalLine: Record "Gen. Journal Line"; PostingRole: Enum "Derogatory Posting Role"): Boolean
    begin
        exit(MakeDerogatoryJournalLine(DerogatoryFAJournalLine, SourceGenJournalLine, SourceGenJournalLine.Amount, PostingRole));
    end;

    procedure MakeDerogatoryJournalLine(var DerogatoryFAJournalLine: Record "FA Journal Line"; SourceGenJournalLine: Record "Gen. Journal Line"; SourceAmount: Decimal; PostingRole: Enum "Derogatory Posting Role"): Boolean
    var
        FAJournalSetup: Record "FA Journal Setup";
        DerogatoryDepreciationBookCode: Code[10];
    begin
        if not IsEligible(SourceGenJournalLine."Account No.", SourceGenJournalLine."Depreciation Book Code", PostingRole, DerogatoryDepreciationBookCode) then
            exit(false);

        DerogatoryFAJournalLine.Init();
        DerogatoryFAJournalLine.Validate("Depreciation Book Code", DerogatoryDepreciationBookCode);
        if not FAJournalSetup.Get(DerogatoryDepreciationBookCode, UserId()) then
            FAJournalSetup.Get(DerogatoryDepreciationBookCode, '');
        DerogatoryFAJournalLine."Journal Template Name" := FAJournalSetup."FA Jnl. Template Name";
        DerogatoryFAJournalLine."Journal Batch Name" := FAJournalSetup."FA Jnl. Batch Name";
        DerogatoryFAJournalLine."FA Posting Type" := Enum::"FA Journal Line FA Posting Type".FromInteger(SourceGenJournalLine."FA Posting Type".AsInteger() - 1);
        DerogatoryFAJournalLine."FA No." := SourceGenJournalLine."Account No.";
        if SourceGenJournalLine."FA Posting Date" <> 0D then
            DerogatoryFAJournalLine."FA Posting Date" := SourceGenJournalLine."FA Posting Date"
        else
            DerogatoryFAJournalLine."FA Posting Date" := SourceGenJournalLine."Posting Date";
        DerogatoryFAJournalLine."Posting Date" := SourceGenJournalLine."Posting Date";
        if DerogatoryFAJournalLine."Posting Date" = DerogatoryFAJournalLine."FA Posting Date" then
            DerogatoryFAJournalLine."Posting Date" := 0D;
        DerogatoryFAJournalLine."Document Type" := SourceGenJournalLine."Document Type";
        DerogatoryFAJournalLine."Document Date" := SourceGenJournalLine."Document Date";
        DerogatoryFAJournalLine."Document No." := SourceGenJournalLine."Document No.";
        DerogatoryFAJournalLine."External Document No." := SourceGenJournalLine."External Document No.";
        DerogatoryFAJournalLine.Description := SourceGenJournalLine.Description;
        DerogatoryFAJournalLine.Validate(Amount, SourceAmount);
        DerogatoryFAJournalLine.Validate(
            "Salvage Value", SourceGenJournalLine.ConvertAmtFCYToLCYForSourceCurrency(SourceGenJournalLine."Salvage Value"));
        DerogatoryFAJournalLine.Quantity := SourceGenJournalLine.Quantity;
        DerogatoryFAJournalLine.Validate(Correction, SourceGenJournalLine.Correction);
        DerogatoryFAJournalLine."No. of Depreciation Days" := SourceGenJournalLine."No. of Depreciation Days";
        DerogatoryFAJournalLine."Depr. until FA Posting Date" := SourceGenJournalLine."Depr. until FA Posting Date";
        DerogatoryFAJournalLine."Depr. Acquisition Cost" := SourceGenJournalLine."Depr. Acquisition Cost";
        DerogatoryFAJournalLine."FA Posting Group" := SourceGenJournalLine."Posting Group";
        DerogatoryFAJournalLine."Maintenance Code" := SourceGenJournalLine."Maintenance Code";
        DerogatoryFAJournalLine."Shortcut Dimension 1 Code" := SourceGenJournalLine."Shortcut Dimension 1 Code";
        DerogatoryFAJournalLine."Shortcut Dimension 2 Code" := SourceGenJournalLine."Shortcut Dimension 2 Code";
        DerogatoryFAJournalLine."Dimension Set ID" := SourceGenJournalLine."Dimension Set ID";
        DerogatoryFAJournalLine."Budgeted FA No." := SourceGenJournalLine."Budgeted FA No.";
        DerogatoryFAJournalLine."FA Reclassification Entry" := SourceGenJournalLine."FA Reclassification Entry";
        DerogatoryFAJournalLine."Index Entry" := SourceGenJournalLine."Index Entry";
        exit(true);
    end;

    procedure PrepareAcquisitionCostAdjustment(var AdjustmentFAJournalLine: Record "FA Journal Line"; SourceFAJournalLine: Record "FA Journal Line"): Boolean
    var
        DepreciationBook: Record "Depreciation Book";
        CalculateAcqCostDepr: Codeunit "Calculate Acq. Cost Depr.";
        DerogatoryDepreciationBookCode: Code[10];
        DerogatoryAmount: Decimal;
    begin
        if (SourceFAJournalLine."FA Posting Type" <> SourceFAJournalLine."FA Posting Type"::"Acquisition Cost") or
           not SourceFAJournalLine."Depr. Acquisition Cost"
        then
            exit(false);
        if not IsEligible(
             SourceFAJournalLine."FA No.", SourceFAJournalLine."Depreciation Book Code",
             Enum::"Derogatory Posting Role"::Source, DerogatoryDepreciationBookCode)
        then
            exit(false);

        CalculateAcqCostDepr.DerogatoryCalculation(
            DerogatoryAmount, SourceFAJournalLine."FA No.", DerogatoryDepreciationBookCode, SourceFAJournalLine.Amount);
        if DerogatoryAmount = 0 then
            exit(false);

        DepreciationBook.Get(SourceFAJournalLine."Depreciation Book Code");
        if DepreciationBook."Integration G/L - Derogatory" then
            SourceFAJournalLine.FieldError(
                "Depr. Acquisition Cost", StrSubstNo(SetupCombinationErr,
                    DepreciationBook.FieldCaption("Integration G/L - Derogatory"), true, DepreciationBook.TableCaption()));

        AdjustmentFAJournalLine.TransferFields(SourceFAJournalLine);
        AdjustmentFAJournalLine.Validate("FA Posting Type", AdjustmentFAJournalLine."FA Posting Type"::Derogatory);
        AdjustmentFAJournalLine.Validate(Amount, DerogatoryAmount);
        AdjustmentFAJournalLine.Validate("Depr. until FA Posting Date", false);
        AdjustmentFAJournalLine.Validate("Depr. Acquisition Cost", false);
        exit(true);
    end;

    procedure PrepareAcquisitionCostAdjustment(var AdjustmentGenJournalLine: Record "Gen. Journal Line"; SourceGenJournalLine: Record "Gen. Journal Line"; var IntegrationGLDerogatory: Boolean): Boolean
    var
        DepreciationBook: Record "Depreciation Book";
        CalculateAcqCostDepr: Codeunit "Calculate Acq. Cost Depr.";
        DerogatoryDepreciationBookCode: Code[10];
        DerogatoryAmount: Decimal;
    begin
        IntegrationGLDerogatory := false;
        if (SourceGenJournalLine."FA Posting Type" <> SourceGenJournalLine."FA Posting Type"::"Acquisition Cost") or
           not SourceGenJournalLine."Depr. Acquisition Cost"
        then
            exit(false);
        if not IsEligible(
             SourceGenJournalLine."Account No.", SourceGenJournalLine."Depreciation Book Code",
             Enum::"Derogatory Posting Role"::Source, DerogatoryDepreciationBookCode)
        then
            exit(false);

        CalculateAcqCostDepr.DerogatoryCalculation(
            DerogatoryAmount, SourceGenJournalLine."Account No.", DerogatoryDepreciationBookCode, SourceGenJournalLine.Amount);
        if DerogatoryAmount = 0 then
            exit(false);

        DepreciationBook.Get(SourceGenJournalLine."Depreciation Book Code");
        IntegrationGLDerogatory := DepreciationBook."Integration G/L - Derogatory";
        AdjustmentGenJournalLine.TransferFields(SourceGenJournalLine);
        AdjustmentGenJournalLine.Validate("FA Posting Type", AdjustmentGenJournalLine."FA Posting Type"::Derogatory);
        AdjustmentGenJournalLine.Validate(Amount, DerogatoryAmount);
        AdjustmentGenJournalLine.Validate("Depr. until FA Posting Date", false);
        AdjustmentGenJournalLine.Validate("Depr. Acquisition Cost", false);
        AdjustmentGenJournalLine.Validate("System-Created Entry", true);
        exit(true);
    end;

    procedure ValidateDerogatoryLink(DerogatoryFALedgerEntry: Record "FA Ledger Entry")
    var
        SourceFALedgerEntry: Record "FA Ledger Entry";
        ExistingDerogatoryFALedgerEntry: Record "FA Ledger Entry";
        ExpectedDerogatoryDepreciationBookCode: Code[10];
        SourceFANo: Code[20];
    begin
        if DerogatoryFALedgerEntry."Derogatory Source Entry No." = 0 then
            exit;

        if not SourceFALedgerEntry.Get(DerogatoryFALedgerEntry."Derogatory Source Entry No.") then
            Error(SourceEntryDoesNotExistErr, SourceFALedgerEntry.TableCaption(), DerogatoryFALedgerEntry."Derogatory Source Entry No.");
        SourceFANo := SourceFALedgerEntry."FA No.";
        if SourceFANo = '' then
            SourceFANo := SourceFALedgerEntry."Canceled from FA No.";
        if (SourceFANo <> DerogatoryFALedgerEntry."FA No.") or
           not GetDerogatoryBookCode(SourceFALedgerEntry."Depreciation Book Code", ExpectedDerogatoryDepreciationBookCode) or
           (ExpectedDerogatoryDepreciationBookCode <> DerogatoryFALedgerEntry."Depreciation Book Code")
        then
            Error(InvalidDerogatoryLinkErr, SourceFALedgerEntry."Entry No.", DerogatoryFALedgerEntry."Depreciation Book Code");

        ExistingDerogatoryFALedgerEntry.SetRange("Derogatory Source Entry No.", SourceFALedgerEntry."Entry No.");
        ExistingDerogatoryFALedgerEntry.SetRange("Depreciation Book Code", DerogatoryFALedgerEntry."Depreciation Book Code");
        if not ExistingDerogatoryFALedgerEntry.IsEmpty() then
            Error(DuplicateDerogatoryLinkErr, SourceFALedgerEntry."Entry No.", DerogatoryFALedgerEntry."Depreciation Book Code");
    end;

    procedure ValidateDerogatoryLink(DerogatoryMaintenanceLedgerEntry: Record "Maintenance Ledger Entry")
    var
        SourceMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        ExistingDerogatoryMaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        ExpectedDerogatoryDepreciationBookCode: Code[10];
    begin
        if DerogatoryMaintenanceLedgerEntry."Derogatory Source Entry No." = 0 then
            exit;

        if not SourceMaintenanceLedgerEntry.Get(DerogatoryMaintenanceLedgerEntry."Derogatory Source Entry No.") then
            Error(SourceEntryDoesNotExistErr, SourceMaintenanceLedgerEntry.TableCaption(), DerogatoryMaintenanceLedgerEntry."Derogatory Source Entry No.");
        if (SourceMaintenanceLedgerEntry."FA No." <> DerogatoryMaintenanceLedgerEntry."FA No.") or
           not GetDerogatoryBookCode(SourceMaintenanceLedgerEntry."Depreciation Book Code", ExpectedDerogatoryDepreciationBookCode) or
           (ExpectedDerogatoryDepreciationBookCode <> DerogatoryMaintenanceLedgerEntry."Depreciation Book Code")
        then
            Error(InvalidDerogatoryLinkErr, SourceMaintenanceLedgerEntry."Entry No.", DerogatoryMaintenanceLedgerEntry."Depreciation Book Code");

        ExistingDerogatoryMaintenanceLedgerEntry.SetRange("Derogatory Source Entry No.", SourceMaintenanceLedgerEntry."Entry No.");
        ExistingDerogatoryMaintenanceLedgerEntry.SetRange("Depreciation Book Code", DerogatoryMaintenanceLedgerEntry."Depreciation Book Code");
        if not ExistingDerogatoryMaintenanceLedgerEntry.IsEmpty() then
            Error(DuplicateDerogatoryLinkErr, SourceMaintenanceLedgerEntry."Entry No.", DerogatoryMaintenanceLedgerEntry."Depreciation Book Code");
    end;

    var
        AmbiguousDerogatoryBookErr: Label 'More than one derogatory depreciation book is configured for depreciation book %1. Correct the depreciation-book setup before posting.', Comment = '%1 - source depreciation book code';
        SourceEntryDoesNotExistErr: Label '%1 %2 does not exist and cannot be used as a derogatory source entry.', Comment = '%1 - table caption, %2 - entry number';
        InvalidDerogatoryLinkErr: Label 'Entry %1 cannot be linked to depreciation book %2 as a derogatory counterpart.', Comment = '%1 - source entry number, %2 - target depreciation book code';
        DuplicateDerogatoryLinkErr: Label 'A derogatory counterpart already exists for source entry %1 in depreciation book %2.', Comment = '%1 - source entry number, %2 - target depreciation book code';
        SetupCombinationErr: Label 'must not be specified when %1 = %2 in %3', Comment = '%1 - field caption, %2 - field value, %3 - table caption';
}
