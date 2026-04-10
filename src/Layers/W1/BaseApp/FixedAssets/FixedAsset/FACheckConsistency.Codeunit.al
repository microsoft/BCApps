// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.FixedAsset;

using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.FixedAssets.Posting;
using Microsoft.FixedAssets.Setup;

codeunit 5606 "FA Check Consistency"
{
    Permissions = TableData "FA Ledger Entry" = r,
                  TableData "FA Posting Type Setup" = r,
                  TableData "FA Depreciation Book" = rm,
                  TableData "Maintenance Ledger Entry" = rm,
                  TableData "Ins. Coverage Ledger Entry" = rm;
    TableNo = "FA Ledger Entry";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRun(Rec, IsHandled);
        if IsHandled then
            exit;

        if (Rec."FA Posting Category" <> Rec."FA Posting Category"::" ") or
           (Rec."FA Posting Type" = Rec."FA Posting Type"::"Gain/Loss") or
           (Rec."FA Posting Type" = Rec."FA Posting Type"::"Book Value on Disposal")
        then
            exit;
        ClearAll();
        FALedgEntry := Rec;
        // This record is not modified in the codeunit.
        FALedgEntry2 := Rec;
        DeprBookCode := FALedgEntry."Depreciation Book Code";
        FANo := FALedgEntry."FA No.";
        FAPostingDate := FALedgEntry."FA Posting Date";
        FA.Get(FANo);
        DeprBook.Get(DeprBookCode);
        FADeprBook.Get(FANo, DeprBookCode);
        case FALedgEntry."FA Posting Type" of
            FALedgEntry."FA Posting Type"::"Write-Down":
                FAPostingTypeSetup.Get(
                  DeprBookCode, FAPostingTypeSetup."FA Posting Type"::"Write-Down");
            FALedgEntry."FA Posting Type"::Appreciation:
                FAPostingTypeSetup.Get(
                  DeprBookCode, FAPostingTypeSetup."FA Posting Type"::Appreciation);
            FALedgEntry."FA Posting Type"::"Custom 1":
                FAPostingTypeSetup.Get(
                  DeprBookCode, FAPostingTypeSetup."FA Posting Type"::"Custom 1");
            FALedgEntry."FA Posting Type"::"Custom 2":
                FAPostingTypeSetup.Get(
                  DeprBookCode, FAPostingTypeSetup."FA Posting Type"::"Custom 2");
        end;
        IsHandled := false;
        OnRunOnBeforeCheckSalesPostingCheckOther(FALedgEntry, IsHandled);
        if IsHandled then
            CheckSalesPosting()
        else
            if FALedgEntry."FA Posting Type" = FALedgEntry."FA Posting Type"::"Proceeds on Disposal" then
                CheckSalesPosting()
            else
                CheckNormalPosting();
        SetFAPostingDate(FALedgEntry2, true);
        CheckInsuranceIntegration();
    end;

    var
        DeprBook: Record "Depreciation Book";
        FA: Record "Fixed Asset";
        FADeprBook: Record "FA Depreciation Book";
        FAPostingTypeSetup: Record "FA Posting Type Setup";
        FALedgEntry: Record "FA Ledger Entry";
        FALedgEntry2: Record "FA Ledger Entry";
        FAJnlLine: Record "FA Journal Line";
        FANo: Code[20];
        DeprBookCode: Code[10];
        FAPostingDate: Date;
        BookValue: Decimal;
        DeprBasis: Decimal;
        SalvageValue: Decimal;
        NewAmount: Decimal;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'The first entry must be an %2 for %1.';
        Text001: Label '%1 is disposed.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        InvalidDisposalDateErr: Label 'The disposal date of fixed asset code %1 must be the last date%2.', Comment = '%1=code value, e.g.E000140, %2=in depreciation book code x(x= a code value, e.g. COMPANY), remains empty when depr. book code is empty';
#pragma warning disable AA0074
        Text003: Label 'Accumulated';
#pragma warning disable AA0470
        Text004: Label '%2%3 must not be positive on %4 for %1.';
        Text005: Label '%2%3 must not be negative on %4 for %1.';
        Text006: Label '%2 must not be negative or less than %3 on %4 for %1.';
        Text007: Label '%2 must not be negative on %3 for %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        FixedAssetCategoryTok: Label 'AL Fixed Assest';
        HandelPatternAppliedTok: Label 'IsHandled';
        FixedAssetEntryNotFoundTok: Label 'Fixed Asset Entry Not Found';
        SalvageValueErr: Label 'There is a reclassification salvage amount that must be posted first. Open the FA Journal page, and then post the relevant reclassification entry.';

    local procedure CheckNormalPosting()
    var
        IsHandled: Boolean;
    begin
        CheckDisposalDate(FADeprBook, FA);
        FALedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Date");
        FALedgEntry.SetRange("FA No.", FANo);
        FALedgEntry.SetRange("Depreciation Book Code", DeprBookCode);
        OnCheckNormalPostingOnAfterSetFALedgerEntryFilters(FALedgEntry, FANo, DeprBookCode);
        if FALedgEntry.Find('-') then begin
            if not FALedgEntry.IsAcquisitionCost() then
                CreateAcquisitionCostError();
            if not FADeprBook."Use FA Ledger Check" then
                DeprBook.TestField("Use FA Ledger Check", false)
            else begin
                IsHandled := false;
                OnCheckNormalPostingOnCalcValues(FANo, DeprBookCode, FALedgEntry, FALedgEntry2, FAPostingDate, BookValue, DeprBasis, SalvageValue, NewAmount, IsHandled);
                if not IsHandled then begin
                    FALedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "Part of Book Value", "FA Posting Date");
                    FALedgEntry.SetRange("Part of Book Value", true);
                    FALedgEntry.SetRange("FA Posting Date", 0D, FAPostingDate - 1);
                    OnCheckNormalPostingOnBeforeCalcSumsForBookValue(FALedgEntry, FAPostingDate);
                    FALedgEntry.CalcSums(Amount);
                    BookValue := FALedgEntry.Amount;
                    FALedgEntry.SetRange("Part of Book Value");
                    FALedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "Part of Depreciable Basis", "FA Posting Date");
                    FALedgEntry.SetRange("Part of Depreciable Basis", true);
                    FALedgEntry.CalcSums(Amount);
                    DeprBasis := FALedgEntry.Amount;
                    FALedgEntry.SetRange("Part of Depreciable Basis");
                    FALedgEntry.SetCurrentKey(
                      "FA No.", "Depreciation Book Code",
                      "FA Posting Category", "FA Posting Type", "FA Posting Date");
                    FALedgEntry.SetRange("FA Posting Category", FALedgEntry."FA Posting Category"::" ");
                    FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Salvage Value");
                    FALedgEntry.CalcSums(Amount);
                    SalvageValue := FALedgEntry.Amount;
                    FALedgEntry.SetRange("FA Posting Type", FALedgEntry2."FA Posting Type");
                    FALedgEntry.CalcSums(Amount);
                    NewAmount := FALedgEntry.Amount;
                    FALedgEntry.SetRange("FA Posting Type");
                    FALedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "FA Posting Date");
                    FALedgEntry.SetFilter("FA Posting Date", '%1..', FAPostingDate);
                    FALedgEntry.SetRange(Reversed, false);
                    OnCheckNormalPostingOnBeforeFind(FALedgEntry, FAPostingDate);
                    if FALedgEntry.Find('-') then
                        repeat
                            IsHandled := false;
                            OnCheckNormalPostingOnCalcValuesFinal(FANo, DeprBookCode, FALedgEntry, FALedgEntry2, FAPostingDate, BookValue, DeprBasis, SalvageValue, NewAmount, IsHandled);
                            if not IsHandled then begin
                                if FALedgEntry."Part of Book Value" then
                                    BookValue := BookValue + FALedgEntry.Amount;
                                if FALedgEntry."Part of Depreciable Basis" then
                                    DeprBasis := DeprBasis + FALedgEntry.Amount;
                            end;
                            if FALedgEntry."FA Posting Type" = FALedgEntry."FA Posting Type"::"Salvage Value" then
                                SalvageValue := SalvageValue + FALedgEntry.Amount;
                            if FALedgEntry."FA Posting Type" = FALedgEntry2."FA Posting Type" then
                                NewAmount := NewAmount + FALedgEntry.Amount;
                            CheckForError();
                        until FALedgEntry.Next() = 0;
                end;
            end;
        end;
    end;

    local procedure CheckSalesPosting()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSalesPostingIgnore(FALedgEntry, FANo, DeprBookCode, IsHandled);
        if IsHandled then
            exit;

        if FADeprBook."Acquisition Date" = 0D then
            CreateAcquisitionCostError();
        FALedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "Part of Book Value", "FA Posting Date");
        FALedgEntry.SetRange("FA No.", FANo);
        FALedgEntry.SetRange("Depreciation Book Code", DeprBookCode);
        FALedgEntry.SetRange("Part of Book Value", true);
        FALedgEntry.SetFilter("FA Posting Date", '%1..', FAPostingDate + 1);
        OnCheckSalesPostingOnBeforeFirstFind(FALedgEntry, FANo, DeprBookCode);
        if FALedgEntry.Find('-') then
            CreateDisposalError();
        FALedgEntry.SetRange("Part of Book Value");
        FALedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "Part of Depreciable Basis", "FA Posting Date");
        FALedgEntry.SetRange("Part of Depreciable Basis", true);
        OnCheckSalesPostingOnAfterSetFALedgerEntryFilters(FALedgEntry, FANo, DeprBookCode);
        if FALedgEntry.Find('-') then
            CreateDisposalError();
        FALedgEntry.SetRange("Part of Depreciable Basis");
        if not FADeprBook."Use FA Ledger Check" then
            DeprBook.TestField("Use FA Ledger Check", false)
        else begin
            FALedgEntry.SetCurrentKey(
              "FA No.", "Depreciation Book Code",
              "FA Posting Category", "FA Posting Type", "FA Posting Date");
            FALedgEntry.SetRange("FA Posting Category", FALedgEntry."FA Posting Category"::" ");
            FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Proceeds on Disposal");
            FALedgEntry.SetRange("FA Posting Date");
            if FALedgEntry.Find('-') then
                repeat
                    NewAmount := NewAmount + FALedgEntry.Amount;
                    if NewAmount > 0 then
                        CreatePostingTypeError();
                until FALedgEntry.Next() = 0;
        end;
    end;

    procedure SetFAPostingDate(var FALedgEntry2: Record "FA Ledger Entry"; LocalCall: Boolean)
    var
        MaxDate: Date;
        MinDate: Date;
        GLDate: Date;
        IsHandled: Boolean;
    begin
        if not LocalCall then begin
            FANo := FALedgEntry2."FA No.";
            DeprBookCode := FALedgEntry2."Depreciation Book Code";
            FADeprBook.Get(FANo, DeprBookCode);
        end;
        FALedgEntry.Reset();
        FALedgEntry.SetCurrentKey(
          "FA No.", "Depreciation Book Code", "FA Posting Category", "FA Posting Type", "FA Posting Date");
        FALedgEntry.SetRange("Depreciation Book Code", DeprBookCode);
        FALedgEntry.SetRange("FA No.", FANo);
        FALedgEntry.SetRange("FA Posting Category", FALedgEntry."FA Posting Category"::" ");
        FALedgEntry.SetRange("FA Posting Type", FALedgEntry2."FA Posting Type");
        OnSetFAPostingDateOnAfterSetFALedgerEntryFilters(FANo, DeprBookCode, FALedgEntry, FALedgEntry2);
        if FALedgEntry.Find('+') then
            MaxDate := FALedgEntry."FA Posting Date"
        else
            MaxDate := 0D;

        IsHandled := false;
        OnSetFAPostingDateOnBeforeSetMinDate(FANo, DeprBookCode, FALedgEntry, FALedgEntry2, MinDate, IsHandled);
        if not IsHandled then
            case FALedgEntry2."FA Posting Type" of
                FALedgEntry2."FA Posting Type"::"Acquisition Cost",
              FALedgEntry2."FA Posting Type"::"Proceeds on Disposal":
                    if FALedgEntry.Find('-') then
                        MinDate := FALedgEntry."FA Posting Date"
                    else begin
                        MinDate := 0D;
                        Session.LogMessage('0000M49', FixedAssetEntryNotFoundTok + ' ' + Format(FALedgEntry2."Entry No."), Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', FixedAssetCategoryTok);
                    end;
            end
        else begin
            Session.LogMessage('0000M4A', HandelPatternAppliedTok + ' ' + Format(FALedgEntry2."Entry No."), Verbosity::Normal, DataClassification::CustomerContent, TelemetryScope::ExtensionPublisher, 'Category', FixedAssetCategoryTok);
            IsHandled := false;
        end;
        OnSetFAPostingDateOnBeforeSetGLDate(FANo, DeprBookCode, FALedgEntry, FALedgEntry2, GLDate, IsHandled);
        if not IsHandled then
            case FALedgEntry2."FA Posting Type" of
                FALedgEntry2."FA Posting Type"::"Acquisition Cost":
                    begin
                        FALedgEntry.SetCurrentKey(
                          "FA No.", "Depreciation Book Code",
                          "FA Posting Category", "FA Posting Type", "Posting Date");
                        if FALedgEntry.Find('-') then
                            GLDate := FALedgEntry."Posting Date"
                        else
                            GLDate := 0D;
                    end;
            end;
        case FALedgEntry2."FA Posting Type" of
            FALedgEntry2."FA Posting Type"::"Acquisition Cost":
                begin
                    FADeprBook."Last Acquisition Cost Date" := MaxDate;
                    FADeprBook."Acquisition Date" := MinDate;
                    FADeprBook."G/L Acquisition Date" := GLDate;
                end;
            FALedgEntry2."FA Posting Type"::"Salvage Value":
                FADeprBook."Last Salvage Value Date" := MaxDate;
            FALedgEntry2."FA Posting Type"::Depreciation:
                FADeprBook."Last Depreciation Date" := MaxDate;
            FALedgEntry2."FA Posting Type"::"Write-Down":
                FADeprBook."Last Write-Down Date" := MaxDate;
            FALedgEntry2."FA Posting Type"::Appreciation:
                FADeprBook."Last Appreciation Date" := MaxDate;
            FALedgEntry2."FA Posting Type"::"Custom 1":
                FADeprBook."Last Custom 1 Date" := MaxDate;
            FALedgEntry2."FA Posting Type"::"Custom 2":
                FADeprBook."Last Custom 2 Date" := MaxDate;
            FALedgEntry2."FA Posting Type"::"Proceeds on Disposal":
                FADeprBook."Disposal Date" := MinDate;
        end;

        OnSetFAPostingDateOnBeforeFADeprBookModify(FADeprBook, FALedgEntry2, MaxDate, MinDate, GLDate);
        FADeprBook.Modify();
    end;

    local procedure CheckInsuranceIntegration()
    var
        FASetup: Record "FA Setup";
        InsCoverageLedgEntry: Record "Ins. Coverage Ledger Entry";
    begin
        if FALedgEntry2."FA Posting Type" <> FALedgEntry2."FA Posting Type"::"Proceeds on Disposal" then
            exit;
        if InsCoverageLedgEntry.IsEmpty() then
            exit;
        FASetup.Get();
        FASetup.TestField("Insurance Depr. Book");
        if DeprBook.Code <> FASetup."Insurance Depr. Book" then
            exit;
        InsCoverageLedgEntry.SetCurrentKey("FA No.");
        InsCoverageLedgEntry.SetRange("FA No.", FA."No.");
        InsCoverageLedgEntry.ModifyAll("Disposed FA", FADeprBook."Disposal Date" > 0D)
    end;

    local procedure CheckForError()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckForError(FALedgEntry2, FAJnlLine, FAPostingTypeSetup, NewAmount, BookValue, SalvageValue, DeprBasis, IsHandled);
        if IsHandled then
            exit;

        case FALedgEntry2."FA Posting Type" of
            FALedgEntry2."FA Posting Type"::"Acquisition Cost":
                if NewAmount < 0 then
                    CreatePostingTypeError();
            FALedgEntry2."FA Posting Type"::Depreciation,
            FALedgEntry2."FA Posting Type"::"Salvage Value":
                if NewAmount > 0 then
                    CreatePostingTypeError();
            FALedgEntry2."FA Posting Type"::"Write-Down",
            FALedgEntry2."FA Posting Type"::Appreciation,
            FALedgEntry2."FA Posting Type"::"Custom 1",
            FALedgEntry2."FA Posting Type"::"Custom 2":
                begin
                    if NewAmount > 0 then
                        if FAPostingTypeSetup.Sign = FAPostingTypeSetup.Sign::Credit then
                            CreatePostingTypeError();
                    if NewAmount < 0 then
                        if FAPostingTypeSetup.Sign = FAPostingTypeSetup.Sign::Debit then
                            CreatePostingTypeError();
                end;
        end;
        if BookValue + SalvageValue < 0 then
            if not DeprBook."Allow Depr. below Zero" or
               (FALedgEntry2."FA Posting Type" <> FALedgEntry2."FA Posting Type"::Depreciation)
            then
                if not DeprBook."Allow Acq. Cost below Zero" or
                   (FALedgEntry2."FA Posting Type" <> FALedgEntry2."FA Posting Type"::"Acquisition Cost") or
                   not FALedgEntry2."Index Entry"
                then begin
                    if FALedgEntry2."Reclassification Entry" and (SalvageValue <> 0) then
                        Error(SalvageValueErr);
                    CreateBookValueError();
                end;
        if DeprBasis < 0 then
            CreateDeprBasisError();
    end;

    procedure CheckDisposalDate(FADeprBook: Record "FA Depreciation Book"; FixedAsset: Record "Fixed Asset")
    begin
        if FADeprBook."Disposal Date" > 0D then
            CreateDisposedError(FixedAsset, FADeprBook."Depreciation Book Code");
    end;

    local procedure CreateAcquisitionCostError()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateAcquisitionCostError(FAJnlLine, FALedgEntry2, IsHandled);
        if IsHandled then
            exit;

        FAJnlLine."FA Posting Type" := FAJnlLine."FA Posting Type"::"Acquisition Cost";
        Error(Text000,
          FAName(), FAJnlLine."FA Posting Type");
    end;

    local procedure CreateDisposedError(FixedAsset: Record "Fixed Asset"; DeprBookCode: Code[10])
    var
        DepreciationCalc: Codeunit "Depreciation Calculation";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateDisposerError(FixedAsset, DeprBookCode, IsHandled, FALedgEntry);
        if not IsHandled then
            Error(Text001, DepreciationCalc.FAName(FixedAsset, DeprBookCode));
    end;

    local procedure CreateDisposalError()
    begin
        FAJnlLine."FA Posting Type" := FAJnlLine."FA Posting Type"::Disposal;
        Error(InvalidDisposalDateErr, FA."No.", FADeprBookName());
    end;

    local procedure CreatePostingTypeError()
    var
        AccumText: Text[30];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreatePostingTypeError(FAJnlLine, FALedgEntry2, DeprBook, IsHandled, NewAmount);
        if IsHandled then
            exit;

        FAJnlLine."FA Posting Type" := "FA Journal Line FA Posting Type".FromInteger(FALedgEntry2.ConvertPostingType());
        if FAJnlLine."FA Posting Type" = FAJnlLine."FA Posting Type"::Depreciation then
            AccumText := StrSubstNo('%1 %2', Text003, '');
        if NewAmount > 0 then
            Error(Text004, FAName(), AccumText, FAJnlLine."FA Posting Type", FALedgEntry."FA Posting Date");
        if NewAmount < 0 then
            Error(Text005, FAName(), AccumText, FAJnlLine."FA Posting Type", FALedgEntry."FA Posting Date");
    end;

    local procedure CreateBookValueError()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateBookValueError(FALedgEntry2, BookValue, SalvageValue, IsHandled);
        if IsHandled then
            exit;

        FAJnlLine."FA Posting Type" := FAJnlLine."FA Posting Type"::"Salvage Value";
        Error(
          Text006,
          FAName(), FADeprBook.FieldCaption("Book Value"), FAJnlLine."FA Posting Type", FALedgEntry."FA Posting Date");
    end;

    local procedure CreateDeprBasisError()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateDeprBasisError(FALedgEntry2, DeprBasis, IsHandled);
        if IsHandled then
            exit;

        Error(
          Text007, FAName(), FADeprBook.FieldCaption("Depreciable Basis"), FALedgEntry."FA Posting Date");
    end;

    local procedure FAName(): Text[200]
    var
        DepreciationCalc: Codeunit "Depreciation Calculation";
    begin
        exit(DepreciationCalc.FAName(FA, DeprBookCode));
    end;

    local procedure FADeprBookName(): Text[200]
    var
        DepreciationCalculation: Codeunit "Depreciation Calculation";
    begin
        exit(DepreciationCalculation.FADeprBookName(DeprBookCode));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckForError(FALedgEntry2: Record "FA Ledger Entry"; var FAJnlLine: Record "FA Journal Line"; FAPostingTypeSetup: Record "FA Posting Type Setup"; NewAmount: Decimal; BookValue: Decimal; SalvageValue: Decimal; DeprBasis: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckNormalPostingOnBeforeCalcSumsForBookValue(var FALedgerEntry: Record "FA Ledger Entry"; FAPostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckNormalPostingOnBeforeFind(var FALedgerEntry: Record "FA Ledger Entry"; FAPostingDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckNormalPostingOnAfterSetFALedgerEntryFilters(var FALedgerEntry: Record "FA Ledger Entry"; FANo: Code[20]; DepreciationBookCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSalesPostingOnAfterSetFALedgerEntryFilters(var FALedgerEntry: Record "FA Ledger Entry"; FANo: Code[20]; DepreciationBookCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSalesPostingOnBeforeFirstFind(var FALedgerEntry: Record "FA Ledger Entry"; FANo: Code[20]; DepreciationBookCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetFAPostingDateOnBeforeFADeprBookModify(var FADepreciationBook: Record "FA Depreciation Book"; var FALedgerEntry: Record "FA Ledger Entry"; MaxDate: Date; MinDate: Date; GLDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDisposerError(FixedAsset: Record "Fixed Asset"; DeprBookCode: code[10]; var IsHandled: Boolean; FALedgerEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePostingTypeError(FAJnlLine: Record "FA Journal Line"; FALedgEntry2: Record "FA Ledger Entry"; DeprBook: Record "Depreciation Book"; var IsHandled: Boolean; NewAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetFAPostingDateOnBeforeSetGLDate(FANo: Code[20]; DepreciationBookCode: Code[10]; var FALedgerEntry: Record "FA Ledger Entry"; var FALedgerEntry2: Record "FA Ledger Entry"; var GLDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetFAPostingDateOnBeforeSetMinDate(FANo: Code[20]; DepreciationBookCode: Code[10]; var FALedgerEntry: Record "FA Ledger Entry"; var FALedgerEntry2: Record "FA Ledger Entry"; var MinDate: Date; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateAcquisitionCostError(FAJournalLine: Record "FA Journal Line"; var FALedgerEntry2: Record "FA Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateBookValueError(FALedgerEntry2: Record "FA Ledger Entry"; BookValue: Decimal; SalvageValue: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesPostingIgnore(var FALedgerEntry: Record "FA Ledger Entry"; FANo: Code[20]; DepreciationBookCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDeprBasisError(FALedgerEntry2: Record "FA Ledger Entry"; DeprBasis: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeCheckSalesPostingCheckOther(var FALedgerEntry: Record "FA Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckNormalPostingOnCalcValues(FANo: Code[20]; DepreciationBookCode: Code[10]; var FALedgerEntry: Record "FA Ledger Entry"; var FALedgerEntry2: Record "FA Ledger Entry"; FAPostingDate: Date; var BookValue: Decimal; var DeprBasis: Decimal; var SalvageValue: Decimal; var NewAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckNormalPostingOnCalcValuesFinal(FANo: Code[20]; DepreciationBookCode: Code[10]; var FALedgerEntry: Record "FA Ledger Entry"; var FALedgerEntry2: Record "FA Ledger Entry"; FAPostingDate: Date; var BookValue: Decimal; var DeprBasis: Decimal; var SalvageValue: Decimal; var NewAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var FALedgerEntry: Record "FA Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetFAPostingDateOnAfterSetFALedgerEntryFilters(FANo: Code[20]; DepreciationBookCode: Code[10]; var FALedgerEntry: Record "FA Ledger Entry"; var FALedgerEntry2: Record "FA Ledger Entry");
    begin
    end;
}

