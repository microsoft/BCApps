// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Ledger;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.Foundation.AuditCodes;

codeunit 5601 "FA Insert G/L Account"
{
    TableNo = "FA Ledger Entry";

    trigger OnRun()
    var
        DisposalEntry: Boolean;
        IsHandled: Boolean;
    begin
        Clear(FAGLPostBuf);
        DisposalEntry :=
          (Rec."FA Posting Category" = Rec."FA Posting Category"::" ") and
          (Rec."FA Posting Type" = Rec."FA Posting Type"::"Proceeds on Disposal");
        if not BookValueEntry then
            BookValueEntry :=
              (Rec."FA Posting Category" = Rec."FA Posting Category"::Disposal) and
              (Rec."FA Posting Type" = Rec."FA Posting Type"::"Book Value on Disposal");

        IsHandled := false;
        OnBeforeFAInsertGLAccount(
            Rec, TempFAGLPostBuf, FAGLPostBuf, DisposalEntry, BookValueEntry, NextEntryNo, GLEntryNo, OrgGenJnlLine,
            NetDisp, NumberOfEntries, DisposalEntryNo, DisposalAmount, GainLossAmount, FAPostingGr2, IsHandled);
        if IsHandled then
            exit;

        if not DisposalEntry then
            FAGLPostBuf."Account No." := FAGetGLAccNo.GetAccNo(Rec);
        FAGLPostBuf.Amount := Rec.Amount;
        FAGLPostBuf.Correction := Rec.Correction;
        FAGLPostBuf."Global Dimension 1 Code" := Rec."Global Dimension 1 Code";
        FAGLPostBuf."Global Dimension 2 Code" := Rec."Global Dimension 2 Code";
        FAGLPostBuf."Dimension Set ID" := Rec."Dimension Set ID";
        FAGLPostBuf."FA Entry No." := Rec."Entry No.";
        OnAfterCopyFAGLPostBufFromFALederEntry(FAGLPostBuf, Rec);

        if Rec."Entry No." > 0 then
            FAGLPostBuf."FA Entry Type" := FAGLPostBuf."FA Entry Type"::"Fixed Asset";
        FAGLPostBuf."Automatic Entry" := Rec."Automatic Entry";
        GLEntryNo := Rec."G/L Entry No.";
        InsertBufferEntry();
        Rec."G/L Entry No." := TempFAGLPostBuf."Entry No.";
        if DisposalEntry then
            CalcDisposalAmount(Rec);

        OnAfterRun(Rec, TempFAGLPostBuf, NumberOfEntries, OrgGenJnlLine, NetDisp,
                    FAGLPostBuf, DisposalEntry, BookValueEntry, NextEntryNo, GLEntryNo,
                    DisposalEntryNo, DisposalAmount, GainLossAmount, FAPostingGr2
        );
    end;

    var
        TempFAGLPostBuf: Record "FA G/L Posting Buffer" temporary;
        FAGLPostBuf: Record "FA G/L Posting Buffer";
        FAAlloc: Record "FA Allocation";
        FAPostingGr: Record "FA Posting Group";
        FAPostingGr2: Record "FA Posting Group";
        FADeprBook: Record "FA Depreciation Book";
        FAGetGLAccNo: Codeunit "FA Get G/L Account No.";
        DepreciationCalc: Codeunit "Depreciation Calculation";
        NextEntryNo: Integer;
        GLEntryNo: Integer;
        TotalAllocAmount: Decimal;
        NewAmount: Decimal;
        TotalPercent: Decimal;
        NumberOfEntries: Integer;
        NextLineNo: Integer;
        NoOfEmptyLines: Integer;
        NoOfEmptyLines2: Integer;
        OrgGenJnlLine: Boolean;
        DisposalEntryNo: Integer;
        GainLossAmount: Decimal;
        DisposalAmount: Decimal;
        BookValueEntry: Boolean;
        NetDisp: Boolean;

#pragma warning disable AA0074
        Text000: Label 'must not be more than 100';
        Text001: Label 'There is not enough space to insert the balance accounts.';
#pragma warning restore AA0074
        TemporaryRecordExpectedErr: Label 'Use a temporary record as a parameter for GetBalAccBuffer.';

    procedure InsertMaintenanceAccNo(var MaintenanceLedgEntry: Record "Maintenance Ledger Entry")
    begin
        Clear(FAGLPostBuf);
        FAGLPostBuf."Account No." := FAGetGLAccNo.GetMaintenanceAccNo(MaintenanceLedgEntry);
        FAGLPostBuf.Amount := MaintenanceLedgEntry.Amount;
        FAGLPostBuf.Correction := MaintenanceLedgEntry.Correction;
        FAGLPostBuf."Global Dimension 1 Code" := MaintenanceLedgEntry."Global Dimension 1 Code";
        FAGLPostBuf."Global Dimension 2 Code" := MaintenanceLedgEntry."Global Dimension 2 Code";
        FAGLPostBuf."Dimension Set ID" := MaintenanceLedgEntry."Dimension Set ID";
        FAGLPostBuf."FA Entry No." := MaintenanceLedgEntry."Entry No.";
        FAGLPostBuf."FA Entry Type" := FAGLPostBuf."FA Entry Type"::Maintenance;
        GLEntryNo := MaintenanceLedgEntry."G/L Entry No.";
        OnInsertMaintenanceAccNoOnBeforeInsertBufferEntry(FAGLPostBuf, MaintenanceLedgEntry);
        InsertBufferEntry();
        MaintenanceLedgEntry."G/L Entry No." := TempFAGLPostBuf."Entry No.";

        OnAfterInsertMaintenanceAccNo(MaintenanceLedgEntry, FAGLPostBuf);
    end;

    procedure InsertBufferBalAcc(FAPostingType: Enum "FA Posting Group Account Type"; AllocAmount: Decimal; DeprBookCode: Code[10]; PostingGrCode: Code[20]; GlobalDim1Code: Code[20]; GlobalDim2Code: Code[20]; DimSetID: Integer; AutomaticEntry: Boolean; Correction: Boolean)
    var
        GLAccNo: Code[20];
        DimensionSetIDArr: array[10] of Integer;
        IsHandled: Boolean;
    begin
        NumberOfEntries := 0;
        TotalAllocAmount := 0;
        NewAmount := 0;
        TotalPercent := 0;
        FAPostingGr.Reset();
        FAPostingGr.GetPostingGroup(PostingGrCode, DeprBookCode);
        OnInsertBufferBalAccOnAfterGetFAPostingGroup(FAPostingGr);
        GLAccNo := GetGLAccNoFromFAPostingGroup(FAPostingGr, FAPostingType);

        DimensionSetIDArr[1] := DimSetID;

        OnBeforeFillAllocationBuffer(
            TempFAGLPostBuf, NextEntryNo, GLEntryNo, NumberOfEntries, OrgGenJnlLine, NetDisp, GLAccNo,
            FAPostingType.AsInteger(), AllocAmount, DeprBookCode, PostingGrCode, GlobalDim1Code, GlobalDim2Code,
            DimSetID, AutomaticEntry, Correction, IsHandled);
        if IsHandled then
            exit;

        FAAlloc.Reset();
        FAAlloc.SetRange(Code, PostingGrCode);
        FAAlloc.SetRange("Allocation Type", FAPostingType);
        OnInsertBufferBalAccOnAfterFAAllocSetFilters(FAAlloc);
        if FAAlloc.Find('-') then
            repeat
                if (FAAlloc."Account No." = '') and (FAAlloc."Allocation %" > 0) then
                    FAAlloc.TestField("Account No.");
                TotalPercent := TotalPercent + FAAlloc."Allocation %";
                NewAmount :=
                    DepreciationCalc.CalcRounding(DeprBookCode, AllocAmount * TotalPercent / 100) - TotalAllocAmount;
                TotalAllocAmount := TotalAllocAmount + NewAmount;
                if Abs(TotalAllocAmount) > Abs(AllocAmount) then
                    NewAmount := AllocAmount - (TotalAllocAmount - NewAmount);
                Clear(FAGLPostBuf);
                FAGLPostBuf."Account No." := FAAlloc."Account No.";

                SetCombinedDimensionSetID(DimensionSetIDArr);

                FAGLPostBuf.Amount := NewAmount;
                FAGLPostBuf."Automatic Entry" := AutomaticEntry;
                FAGLPostBuf.Correction := Correction;
                FAGLPostBuf."FA Posting Group" := FAAlloc.Code;
                FAGLPostBuf."FA Allocation Type" := FAAlloc."Allocation Type";
                FAGLPostBuf."FA Allocation Line No." := FAAlloc."Line No.";
                OnInsertBufferBalAccOnAfterAssignFromFAAllocAcc(FAAlloc, FAGLPostBuf);
                if NewAmount <> 0 then begin
                    InsertBufferEntry();
                    OnInsertBufferBalAccOnAfterInsertBufferEntryFromFAAllocAcc(FAAlloc, TempFAGLPostBuf, FAPostingType, DeprBookCode, PostingGrCode, NewAmount, AutomaticEntry, Correction, NumberOfEntries, OrgGenJnlLine, NetDisp);
                end;

            until FAAlloc.Next() = 0;

        if Abs(TotalAllocAmount) < Abs(AllocAmount) then begin
            NewAmount := AllocAmount - TotalAllocAmount;
            Clear(FAGLPostBuf);
            FAGLPostBuf."Account No." := GLAccNo;
            FAGLPostBuf.Amount := NewAmount;
            FAGLPostBuf."Global Dimension 1 Code" := GlobalDim1Code;
            FAGLPostBuf."Global Dimension 2 Code" := GlobalDim2Code;
            SetDefaultDimID(GLAccNo, DimSetID);
            FAGLPostBuf."Automatic Entry" := AutomaticEntry;
            FAGLPostBuf.Correction := Correction;
            OnInsertBufferBalAccOnAfterAssignFromFAPostingGrAcc(FAAlloc, FAGLPostBuf, FAPostingType, AllocAmount);
            if NewAmount <> 0 then begin
                InsertBufferEntry();
                OnInsertBufferBalAccOnAfterInsertBufferEntryFromFAPostingGrAcc(FAAlloc, TempFAGLPostBuf, FAPostingType, DeprBookCode, PostingGrCode, AllocAmount, TotalAllocAmount, GLAccNo, GlobalDim1Code, GlobalDim2Code, DimSetID, AutomaticEntry, Correction, NumberOfEntries, OrgGenJnlLine, NetDisp);
            end;
        end;
        OnAfterInsertBufferBalAcc(FAGLPostBuf, TempFAGLPostBuf, GLEntryNo, NextEntryNo, NumberOfEntries, OrgGenJnlLine, NetDisp, FAPostingType);
    end;

    local procedure SetCombinedDimensionSetID(var DimensionSetIDArr: array[10] of Integer)
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimensionSetIDArr[2] := FAAlloc."Dimension Set ID";
        FAGLPostBuf."Dimension Set ID" :=
            DimMgt.GetCombinedDimensionSetID(
                DimensionSetIDArr, FAGLPostBuf."Global Dimension 1 Code", FAGLPostBuf."Global Dimension 2 Code");

        OnAfterSetCombinedDimensionSetID(FAGLPostBuf, FAAlloc, DimensionSetIDArr);
    end;

    local procedure SetDefaultDimID(GLAccNo: Code[20]; DimSetID: Integer)
    var
        SourceCodeSetup: Record "Source Code Setup";
        DimMgt: Codeunit DimensionManagement;
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        SourceCodeSetup.Get();
        DimMgt.AddDimSource(DefaultDimSource, Database::"G/L Account", GLAccNo);
        FAGLPostBuf."Dimension Set ID" :=
            DimMgt.GetDefaultDimID(
                DefaultDimSource, SourceCodeSetup."Fixed Asset G/L Journal", FAGLPostBuf."Global Dimension 1 Code",
                FAGLPostBuf."Global Dimension 2 Code", DimSetID, Database::"Fixed Asset");

        OnAfterSetDefaultDimID(FAGLPostBuf, GLAccNo, DimSetID);
    end;

    procedure InsertBalAcc(var FALedgEntry: Record "FA Ledger Entry")
    begin
        OnBeforeInsertBalAcc(FALedgEntry);
        // Called from codeunit 5632
        InsertBufferBalAcc(
            GetPostingType(FALedgEntry), -FALedgEntry.Amount, FALedgEntry."Depreciation Book Code",
            FALedgEntry."FA Posting Group", FALedgEntry."Global Dimension 1 Code", FALedgEntry."Global Dimension 2 Code", FALedgEntry."Dimension Set ID", FALedgEntry."Automatic Entry", FALedgEntry.Correction);
        OnAfterInsertBalAcc(FALedgEntry);
    end;

    procedure GetPostingType(var FALedgEntry: Record "FA Ledger Entry"): Enum "FA Posting Group Account Type"
    var
        FAPostingGroupAccountType: Enum "FA Posting Group Account Type";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetPostingType(FALedgEntry, FAPostingGroupAccountType, IsHandled);
        if IsHandled then
            exit(FAPostingGroupAccountType);

        case FALedgEntry."FA Posting Type" of
            FALedgEntry."FA Posting Type"::"Gain/Loss":
                begin
                    if FALedgEntry."Result on Disposal" = FALedgEntry."Result on Disposal"::Gain then
                        exit("FA Posting Group Account Type"::Gain);

                    exit("FA Posting Group Account Type"::Loss);
                end;
            FALedgEntry."FA Posting Type"::"Book Value on Disposal":
                begin
                    if FALedgEntry."Result on Disposal" = FALedgEntry."Result on Disposal"::Gain then
                        exit("FA Posting Group Account Type"::"Book Value Gain");

                    exit("FA Posting Group Account Type"::"Book Value Loss");
                end
            else
                exit("FA Posting Group Account Type".FromInteger(FALedgEntry.ConvertPostingType()));
        end;
    end;

    local procedure GetBalAccLocal(var GenJnlLine: Record "Gen. Journal Line"): Integer
    var
        TempGenJnlLine: Record "Gen. Journal Line" temporary;
        NonBlankFAPostingType: Option;
        SkipInsert: Boolean;
    begin
        OnBeforeGetBalAccLocal(GenJnlLine);
        TempFAGLPostBuf.DeleteAll();
        TempGenJnlLine.Init();
        GenJnlLine.Reset();
        GenJnlLine.Find();
        GenJnlLine.TestField("Bal. Account No.", '');
        CheckAccountType(GenJnlLine);
        GenJnlLine.TestField("Account No.");
        GenJnlLine.TestField("Depreciation Book Code");
        GenJnlLine.TestField("Posting Group");
        GenJnlLine.TestField("FA Posting Type");
        TempGenJnlLine.Description := GenJnlLine.Description;
        TempGenJnlLine."FA Add.-Currency Factor" := GenJnlLine."FA Add.-Currency Factor";
        SkipInsert := false;
        OnGetBalAccAfterSaveGenJnlLineFields(TempGenJnlLine, GenJnlLine, SkipInsert);
        if not SkipInsert then begin
            NonBlankFAPostingType := GenJnlLine."FA Posting Type".AsInteger() - 1;
            InsertBufferBalAcc(
              "FA Posting Group Account Type".FromInteger(NonBlankFAPostingType), -GenJnlLine.Amount, GenJnlLine."Depreciation Book Code",
              GenJnlLine."Posting Group", GenJnlLine."Shortcut Dimension 1 Code", GenJnlLine."Shortcut Dimension 2 Code", GenJnlLine."Dimension Set ID", false, false);
        end;
        CalculateNoOfEmptyLines(GenJnlLine, NumberOfEntries);
        GenJnlLine."Account Type" := GenJnlLine."Account Type"::"G/L Account";
        GenJnlLine."Depreciation Book Code" := '';
        GenJnlLine."Posting Group" := '';
        GenJnlLine.Validate("FA Posting Type", GenJnlLine."FA Posting Type"::" ");
        if TempFAGLPostBuf.FindFirst() then
            repeat
                GenJnlLine."Line No." := 0;
                GenJnlLine.Validate("Account No.", TempFAGLPostBuf."Account No.");
                GenJnlLine.Validate(Amount, TempFAGLPostBuf.Amount);
                GenJnlLine.Validate("Depreciation Book Code", '');
                GenJnlLine."Shortcut Dimension 1 Code" := TempFAGLPostBuf."Global Dimension 1 Code";
                GenJnlLine."Shortcut Dimension 2 Code" := TempFAGLPostBuf."Global Dimension 2 Code";
                GenJnlLine."Dimension Set ID" := TempFAGLPostBuf."Dimension Set ID";
                GenJnlLine.Description := TempGenJnlLine.Description;
                GenJnlLine."FA Add.-Currency Factor" := TempGenJnlLine."FA Add.-Currency Factor";
                OnGetBalAccAfterRestoreGenJnlLineFields(GenJnlLine, TempGenJnlLine, TempFAGLPostBuf);
                InsertGenJnlLine(GenJnlLine);
                OnGetBalAccLocalOnAfterInsertGenJnlLine(GenJnlLine, TempFAGLPostBuf);
            until TempFAGLPostBuf.Next() = 0;
        TempFAGLPostBuf.DeleteAll();
        exit(GenJnlLine."Line No.");
    end;

    local procedure CheckAccountType(var GenJnlLine: Record "Gen. Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckAccountType(GenJnlLine, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine.TestField("Account Type", Enum::"Gen. Journal Account Type"::"Fixed Asset");
    end;

    procedure GetBalAccBuffer(var GenJnlLine: Record "Gen. Journal Line"): Integer
    begin
        if not GenJnlLine.IsTemporary() then
            Error(TemporaryRecordExpectedErr);
        exit(GetBalAccLocal(GenJnlLine));
    end;

    procedure GetBalAcc(GenJnlLine: Record "Gen. Journal Line"): Integer
    begin
        exit(GetBalAccLocal(GenJnlLine));
    end;

    procedure GetBalAcc(var GenJnlLine: Record "Gen. Journal Line"; var NextLineNo2: Integer)
    begin
        NoOfEmptyLines2 := 1000;
        GetBalAcc(GenJnlLine);
        NextLineNo2 := NextLineNo;
    end;

    procedure GetBalAccWithBalAccountInfo(GenJnlLine: Record "Gen. Journal Line"; BalAccountType: Option; BalAccountNo: Code[20])
    var
        LineNo: Integer;
    begin
        LineNo := GetBalAcc(GenJnlLine);
        GenJnlLine.Get(GenJnlLine."Journal Template Name", GenJnlLine."Journal Batch Name", LineNo);
        GenJnlLine.Validate("Account Type", BalAccountType);
        GenJnlLine.Validate("Account No.", BalAccountNo);
        GenJnlLine.Modify(true);
    end;

    local procedure GetGLAccNoFromFAPostingGroup(FAPostingGr: Record "FA Posting Group"; FAPostingType: Enum "FA Posting Group Account Type") GLAccNo: Code[20]
    var
        FieldErrorText: Text[50];
        IsHandled: Boolean;
    begin
        GLAccNo := '';
        IsHandled := false;
        OnBeforeGetGLAccNoFromFAPostingGroup(FAPostingGr, FAPostingType, GLAccNo, IsHandled);
        if IsHandled then
            exit(GlAccNo);

        FieldErrorText := Text000;
        case FAPostingType of
            FAPostingType::"Acquisition Cost":
                begin
                    GLAccNo := FAPostingGr.GetAcquisitionCostBalanceAccount();
                    FAPostingGr.CalcFields("Allocated Acquisition Cost %");
                    if FAPostingGr."Allocated Acquisition Cost %" > 100 then
                        FAPostingGr.FieldError("Allocated Acquisition Cost %", FieldErrorText);
                end;
            FAPostingType::Depreciation:
                begin
                    GLAccNo := FAPostingGr.GetDepreciationExpenseAccount();
                    FAPostingGr.CalcFields("Allocated Depreciation %");
                    if FAPostingGr."Allocated Depreciation %" > 100 then
                        FAPostingGr.FieldError("Allocated Depreciation %", FieldErrorText);
                end;
            FAPostingType::"Write-Down":
                begin
                    GLAccNo := FAPostingGr.GetWriteDownExpenseAccount();
                    FAPostingGr.CalcFields("Allocated Write-Down %");
                    if FAPostingGr."Allocated Write-Down %" > 100 then
                        FAPostingGr.FieldError("Allocated Write-Down %", FieldErrorText);
                end;
            FAPostingType::Appreciation:
                begin
                    GLAccNo := FAPostingGr.GetAppreciationBalanceAccount();
                    FAPostingGr.CalcFields("Allocated Appreciation %");
                    if FAPostingGr."Allocated Appreciation %" > 100 then
                        FAPostingGr.FieldError("Allocated Appreciation %", FieldErrorText);
                end;
            FAPostingType::"Custom 1":
                begin
                    GLAccNo := FAPostingGr.GetCustom1ExpenseAccount();
                    FAPostingGr.CalcFields("Allocated Custom 1 %");
                    if FAPostingGr."Allocated Custom 1 %" > 100 then
                        FAPostingGr.FieldError("Allocated Custom 1 %", FieldErrorText);
                end;
            FAPostingType::"Custom 2":
                begin
                    GLAccNo := FAPostingGr.GetCustom2ExpenseAccount();
                    FAPostingGr.CalcFields("Allocated Custom 2 %");
                    if FAPostingGr."Allocated Custom 2 %" > 100 then
                        FAPostingGr.FieldError("Allocated Custom 2 %", FieldErrorText);
                end;
            FAPostingType::"Proceeds on Disposal":
                begin
                    GLAccNo := FAPostingGr.GetSalesBalanceAccount();
                    FAPostingGr.CalcFields("Allocated Sales Price %");
                    if FAPostingGr."Allocated Sales Price %" > 100 then
                        FAPostingGr.FieldError("Allocated Sales Price %", FieldErrorText);
                end;
            FAPostingType::Maintenance:
                begin
                    GLAccNo := FAPostingGr.GetMaintenanceBalanceAccount();
                    FAPostingGr.CalcFields("Allocated Maintenance %");
                    if FAPostingGr."Allocated Maintenance %" > 100 then
                        FAPostingGr.FieldError("Allocated Maintenance %", FieldErrorText);
                end;
            FAPostingType::Gain:
                begin
                    GLAccNo := FAPostingGr.GetGainsAccountOnDisposal();
                    FAPostingGr.CalcFields("Allocated Gain %");
                    if FAPostingGr."Allocated Gain %" > 100 then
                        FAPostingGr.FieldError("Allocated Gain %", FieldErrorText);
                end;
            FAPostingType::Loss:
                begin
                    GLAccNo := FAPostingGr.GetLossesAccountOnDisposal();
                    FAPostingGr.CalcFields("Allocated Loss %");
                    if FAPostingGr."Allocated Loss %" > 100 then
                        FAPostingGr.FieldError("Allocated Loss %", FieldErrorText);
                end;
            FAPostingType::"Book Value Gain":
                begin
                    GLAccNo := FAPostingGr.GetBookValueAccountOnDisposalGain();
                    FAPostingGr.CalcFields("Allocated Book Value % (Gain)");
                    if FAPostingGr."Allocated Book Value % (Gain)" > 100 then
                        FAPostingGr.FieldError("Allocated Book Value % (Gain)", FieldErrorText);
                end;
            FAPostingType::"Book Value Loss":
                begin
                    GLAccNo := FAPostingGr.GetBookValueAccountOnDisposalLoss();
                    FAPostingGr.CalcFields("Allocated Book Value % (Loss)");
                    if FAPostingGr."Allocated Book Value % (Loss)" > 100 then
                        FAPostingGr.FieldError("Allocated Book Value % (Loss)", FieldErrorText);
                end;
        end;

        OnAfterGetGLAccNoFromFAPostingGroup(FAPostingGr, FAPostingType, GLAccNo);
    end;

    local procedure CalculateNoOfEmptyLines(var GenJnlLine: Record "Gen. Journal Line"; NumberOfEntries: Integer)
    var
        GenJnlLine2: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateNoOfEmptyLines(GenJnlLine, TempFAGLPostBuf, NextLineNo, NoOfEmptyLines, NoOfEmptyLines2, NumberOfEntries, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine2."Journal Template Name" := GenJnlLine."Journal Template Name";
        GenJnlLine2."Journal Batch Name" := GenJnlLine."Journal Batch Name";
        GenJnlLine2."Line No." := GenJnlLine."Line No.";
        GenJnlLine2.SetRange("Journal Template Name", GenJnlLine."Journal Template Name");
        GenJnlLine2.SetRange("Journal Batch Name", GenJnlLine."Journal Batch Name");
        NextLineNo := GenJnlLine."Line No.";
        if NoOfEmptyLines2 > 0 then
            NoOfEmptyLines := NoOfEmptyLines2
        else begin
            if GenJnlLine2.Next() = 0 then
                NoOfEmptyLines := 1000
            else
                NoOfEmptyLines := (GenJnlLine2."Line No." - NextLineNo) div (NumberOfEntries + 1);
            if NoOfEmptyLines < 1 then
                Error(Text001);
        end;
    end;

    local procedure InsertGenJnlLine(var GenJnlLine: Record "Gen. Journal Line")
    var
        FAJnlSetup: Record "FA Journal Setup";
    begin
        NextLineNo := NextLineNo + NoOfEmptyLines;
        GenJnlLine."Line No." := NextLineNo;
        FAJnlSetup.SetGenJnlTrailCodes(GenJnlLine);
        GenJnlLine.Insert(true);
    end;

    local procedure InsertBufferEntry()
    begin
        if TempFAGLPostBuf.IsEmpty() then
            NextEntryNo := GLEntryNo
        else
            NextEntryNo := TempFAGLPostBuf.GetLastEntryNo() + 1;

        TempFAGLPostBuf := FAGLPostBuf;
        TempFAGLPostBuf."Entry No." := NextEntryNo;
        TempFAGLPostBuf."Original General Journal Line" := OrgGenJnlLine;
        TempFAGLPostBuf."Net Disposal" := NetDisp;
        OnInsertBufferEntryOnBeforeBufferInsert(TempFAGLPostBuf, FAGLPostBuf);
        TempFAGLPostBuf.Insert();
        NumberOfEntries := NumberOfEntries + 1;
    end;

    procedure FindFirstGLAcc(var FAGLPostBuf: Record "FA G/L Posting Buffer"): Boolean
    var
        ReturnValue: Boolean;
    begin
        OnBeforeFindFirstGLAcc(TempFAGLPostBuf);
        ReturnValue := TempFAGLPostBuf.Find('-');
        FAGLPostBuf := TempFAGLPostBuf;
        exit(ReturnValue);
    end;

    procedure GetNextGLAcc(var FAGLPostBuf: Record "FA G/L Posting Buffer"): Integer
    var
        ReturnValue: Integer;
    begin
        ReturnValue := TempFAGLPostBuf.Next();
        FAGLPostBuf := TempFAGLPostBuf;
        exit(ReturnValue);
    end;

    procedure DeleteAllGLAcc()
    begin
        TempFAGLPostBuf.DeleteAll();
        DisposalEntryNo := 0;
        BookValueEntry := false;
    end;

    procedure SetOrgGenJnlLine(OrgGenJnlLine2: Boolean)
    begin
        OrgGenJnlLine := OrgGenJnlLine2;
    end;

    local procedure CalcDisposalAmount(FALedgEntry: Record "FA Ledger Entry")
    begin
        DisposalEntryNo := TempFAGLPostBuf."Entry No.";
        FADeprBook.Get(FALedgEntry."FA No.", FALedgEntry."Depreciation Book Code");
        FADeprBook.CalcFields("Proceeds on Disposal", "Gain/Loss");
        OnCalcDisposalAmountOnAfterCalcFields(FADeprBook);
        DisposalAmount := FADeprBook."Proceeds on Disposal";
        GainLossAmount := FADeprBook."Gain/Loss";
        FAPostingGr2.Get(FALedgEntry."FA Posting Group");

        OnAfterCalcDisposalAmount(FAPostingGr2);
    end;

    procedure CorrectEntries()
    begin
        if DisposalEntryNo = 0 then
            exit;

        CorrectDisposalEntry();
        if not BookValueEntry then
            CorrectBookValueEntry();
    end;

    local procedure CorrectDisposalEntry()
    var
        LastDisposal, IsHandled : Boolean;
        GLAmount: Decimal;
    begin
        TempFAGLPostBuf.Get(DisposalEntryNo);
        FADeprBook.CalcFields("Gain/Loss");
        OnCorrectDisposalEntryOnAfterCalcGainLoss(FADeprBook);
        LastDisposal := CalcLastDisposal(FADeprBook);
        if LastDisposal then
            GLAmount := GainLossAmount
        else
            GLAmount := FADeprBook."Gain/Loss";
        IsHandled := false;
        OnCorrectDisposalEntryOnBeforeSetGainLossAccount(FADeprBook, FAPostingGr2, TempFAGLPostBuf, GLAmount, IsHandled);
        if not IsHandled then
            if GLAmount <= 0 then
                TempFAGLPostBuf."Account No." := FAPostingGr2.GetSalesAccountOnDisposalGain()
            else
                TempFAGLPostBuf."Account No." := FAPostingGr2.GetSalesAccountOnDisposalLoss();
        OnBeforeTempFAGLPostBufModify(FAPostingGr2, TempFAGLPostBuf, GLAmount);
        TempFAGLPostBuf.Modify();
        FAGLPostBuf := TempFAGLPostBuf;
        if LastDisposal then
            exit;
        if IdenticalSign(FADeprBook."Gain/Loss", GainLossAmount, DisposalAmount) then
            exit;
        if FAPostingGr2.GetSalesAccountOnDisposalGain() = FAPostingGr2.GetSalesAccountOnDisposalLoss() then
            exit;
        IsHandled := false;
        OnCorrectDisposalEntryOnAfterCheckIdenticalAccountGainLoss(FADeprBook, FAPostingGr2, IsHandled);
        if IsHandled then
            exit;

        FAGLPostBuf."FA Entry No." := 0;
        FAGLPostBuf."FA Entry Type" := FAGLPostBuf."FA Entry Type"::" ";
        FAGLPostBuf."Automatic Entry" := true;
        OrgGenJnlLine := false;
        if FADeprBook."Gain/Loss" <= 0 then begin
            IsHandled := false;
            OnCorrectDisposalEntryNonPositiveGainLossOnBeforeSetAccountGain(FADeprBook, FAPostingGr2, FAGLPostBuf, IsHandled);
            if not IsHandled then
                FAGLPostBuf."Account No." := FAPostingGr2.GetSalesAccountOnDisposalGain();

            FAGLPostBuf.Amount := DisposalAmount;
            InsertBufferEntry();

            IsHandled := false;
            OnCorrectDisposalEntryNonPositiveGainLossOnBeforeSetAccountLoss(FADeprBook, FAPostingGr2, FAGLPostBuf, IsHandled);
            if not IsHandled then
                FAGLPostBuf."Account No." := FAPostingGr2.GetSalesAccountOnDisposalLoss();

            FAGLPostBuf.Amount := -DisposalAmount;
            FAGLPostBuf.Correction := not FAGLPostBuf.Correction;
            InsertBufferEntry();
        end else begin
            IsHandled := false;
            OnCorrectDisposalEntryPositiveGainLossOnBeforeSetAccountLoss(FADeprBook, FAPostingGr2, FAGLPostBuf, IsHandled);
            if not IsHandled then
                FAGLPostBuf."Account No." := FAPostingGr2.GetSalesAccountOnDisposalLoss();

            FAGLPostBuf.Amount := DisposalAmount;
            InsertBufferEntry();

            IsHandled := false;
            OnCorrectDisposalEntryPositiveGainLossOnBeforeSetAccountGain(FADeprBook, FAPostingGr2, FAGLPostBuf, IsHandled);
            if not IsHandled then
                FAGLPostBuf."Account No." := FAPostingGr2.GetSalesAccountOnDisposalGain();

            FAGLPostBuf.Amount := -DisposalAmount;
            FAGLPostBuf.Correction := not FAGLPostBuf.Correction;
            InsertBufferEntry();
        end;
    end;

    local procedure CorrectBookValueEntry()
    var
        FALedgEntry: Record "FA Ledger Entry";
        FAGLPostBuf: Record "FA G/L Posting Buffer";
        DepreciationCalc: Codeunit "Depreciation Calculation";
        BookValueAmount: Decimal;
        IsHandled: Boolean;
    begin
        DepreciationCalc.SetFAFilter(
          FALedgEntry, FADeprBook."FA No.", FADeprBook."Depreciation Book Code", true);
        FALedgEntry.SetRange("FA Posting Category", FALedgEntry."FA Posting Category"::Disposal);
        FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Book Value on Disposal");
        OnCorrectBookValueEntryOnAfterSetFilterFALedgEntry(FALedgEntry);
        FALedgEntry.CalcSums(Amount);
        BookValueAmount := FALedgEntry.Amount;
        TempFAGLPostBuf.Get(DisposalEntryNo);
        FAGLPostBuf := TempFAGLPostBuf;
        if IdenticalSign(FADeprBook."Gain/Loss", GainLossAmount, BookValueAmount) then
            exit;

        IsHandled := false;
        OnCorrectBookValueEntryOnAfterCheckIdenticalGainLossAmtSign(FADeprBook, FAPostingGr2, IsHandled);
        if IsHandled then
            exit;

        if FAPostingGr2.GetBookValueAccountOnDisposalGain() = FAPostingGr2.GetBookValueAccountOnDisposalLoss() then
            exit;
        OrgGenJnlLine := false;
        OnCorrectBookValueEntryOnBeforeInsertBufferBalAcc(FAGLPostBuf);
        if FADeprBook."Gain/Loss" <= 0 then begin
            InsertBufferBalAcc(
              "FA Posting Group Account Type"::"Book Value Gain",
              BookValueAmount,
              FADeprBook."Depreciation Book Code",
              FAPostingGr2.Code,
              FAGLPostBuf."Global Dimension 1 Code",
              FAGLPostBuf."Global Dimension 2 Code",
              FAGLPostBuf."Dimension Set ID",
              true, FAGLPostBuf.Correction);

            InsertBufferBalAcc(
              "FA Posting Group Account Type"::"Book Value Loss",
              -BookValueAmount,
              FADeprBook."Depreciation Book Code",
              FAPostingGr2.Code,
              FAGLPostBuf."Global Dimension 1 Code",
              FAGLPostBuf."Global Dimension 2 Code",
              FAGLPostBuf."Dimension Set ID",
              true, not FAGLPostBuf.Correction);
        end else begin
            InsertBufferBalAcc(
              "FA Posting Group Account Type"::"Book Value Loss",
              BookValueAmount,
              FADeprBook."Depreciation Book Code",
              FAPostingGr2.Code,
              FAGLPostBuf."Global Dimension 1 Code",
              FAGLPostBuf."Global Dimension 2 Code",
              FAGLPostBuf."Dimension Set ID",
              true, FAGLPostBuf.Correction);

            InsertBufferBalAcc(
              "FA Posting Group Account Type"::"Book Value Gain",
              -BookValueAmount,
              FADeprBook."Depreciation Book Code",
              FAPostingGr2.Code,
              FAGLPostBuf."Global Dimension 1 Code",
              FAGLPostBuf."Global Dimension 2 Code",
              FAGLPostBuf."Dimension Set ID",
              true, not FAGLPostBuf.Correction);
        end;

        OnAfterCorrectBookValueEntry(FAGLPostBuf);
    end;

    local procedure IdenticalSign(A: Decimal; B: Decimal; C: Decimal): Boolean
    begin
        exit(((A <= 0) = (B <= 0)) or (C = 0));
    end;

    procedure SetNetDisposal(NetDisp2: Boolean)
    begin
        NetDisp := NetDisp2;
    end;

    local procedure CalcLastDisposal(FADeprBook: Record "FA Depreciation Book"): Boolean
    var
        FALedgEntry: Record "FA Ledger Entry";
        DepreciationCalc: Codeunit "Depreciation Calculation";
    begin
        DepreciationCalc.SetFAFilter(
          FALedgEntry, FADeprBook."FA No.", FADeprBook."Depreciation Book Code", true);
        FALedgEntry.SetRange("FA Posting Type", FALedgEntry."FA Posting Type"::"Proceeds on Disposal");
        OnCalcLastDisposalOnAfterSetFilter(FALedgEntry);
        exit(not FALedgEntry.FindFirst());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFAGLPostBufFromFALederEntry(var FAGLPostingBuffer: Record "FA G/L Posting Buffer"; FALedgerEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCorrectBookValueEntry(var FAGLPostingBuffer: Record "FA G/L Posting Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcDisposalAmount(var FAPostingGroup: Record "FA Posting Group")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetGLAccNoFromFAPostingGroup(FAPostingGroup: Record "FA Posting Group"; FAPostingType: Enum "FA Posting Group Account Type"; var GLAccNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertBalAcc(var FALedgerEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRun(var FALedgerEntry: Record "FA Ledger Entry"; var TempFAGLPostingBuffer: Record "FA G/L Posting Buffer" temporary; var NumberOfEntries: Integer; var OrgGenJnlLine: Boolean; var NetDisp: Boolean;
                                var FAGLPostingBuffer: Record "FA G/L Posting Buffer"; var DisposalEntry: Boolean; var BookValueEntry: Boolean; var NextEntryNo: Integer;
                                var GLEntryNo: Integer; var DisposalEntryNo: Integer;
                                var DisposalAmount: Decimal; var GainLossAmount: Decimal; var FAPostingGroup2: Record "FA Posting Group")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetCombinedDimensionSetID(var FAGLPostBuf: Record "FA G/L Posting Buffer"; FAAlloc: Record "FA Allocation"; DimensionSetIDArr: array[10] of Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetDefaultDimID(var FAGLPostBuf: Record "FA G/L Posting Buffer"; GLAccNo: Code[20]; DimSetID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAccountType(var GenJnlLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFillAllocationBuffer(var TempFAGLPostingBuffer: Record "FA G/L Posting Buffer" temporary; var NextEntryNo: Integer; var GLEntryNo: Integer; var NumberOfEntries: Integer; var OrgGenJnlLine: Boolean; var NetDisp: Boolean; GLAccNo: Code[20]; FAPostingType: Option Acquisition,Depr,WriteDown,Appr,Custom1,Custom2,Disposal,Maintenance,Gain,Loss,"Book Value Gain","Book Value Loss"; AllocAmount: Decimal; DeprBookCode: Code[10]; PostingGrCode: Code[20]; GlobalDim1Code: Code[20]; GlobalDim2Code: Code[20]; DimSetID: Integer; AutomaticEntry: Boolean; Correction: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetBalAccLocal(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertBalAcc(var FALedgerEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertMaintenanceAccNoOnBeforeInsertBufferEntry(var FAGLPostBuf: Record "FA G/L Posting Buffer"; var MaintenanceLedgEntry: Record "Maintenance Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertBufferBalAccOnAfterFAAllocSetFilters(var FAAllocation: Record "FA Allocation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempFAGLPostBufModify(var FAPostingGroup: Record "FA Posting Group"; var TempFAGLPostingBuffer: Record "FA G/L Posting Buffer" temporary; GLAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCorrectBookValueEntryOnBeforeInsertBufferBalAcc(var FAGLPostBuf: Record "FA G/L Posting Buffer")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnGetBalAccAfterSaveGenJnlLineFields(var ToGenJnlLine: Record "Gen. Journal Line"; FromGenJnlLine: Record "Gen. Journal Line"; var SkipInsert: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetBalAccAfterRestoreGenJnlLineFields(var ToGenJnlLine: Record "Gen. Journal Line"; FromGenJnlLine: Record "Gen. Journal Line"; var TempFAGLPostBuf: Record "FA G/L Posting Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetBalAccLocalOnAfterInsertGenJnlLine(var GenJnlLine: Record "Gen. Journal Line"; var TempFAGLPostBuf: Record "FA G/L Posting Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertBufferBalAccOnAfterAssignFromFAAllocAcc(FAAllocation: Record "FA Allocation"; var FAGLPostBuf: Record "FA G/L Posting Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertBufferBalAccOnAfterAssignFromFAPostingGrAcc(FAAllocation: Record "FA Allocation"; var FAGLPostBuf: Record "FA G/L Posting Buffer"; FAPostingType: Enum "FA Posting Group Account Type"; AllocAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertBufferBalAccOnAfterGetFAPostingGroup(var FAPostingGr: Record "FA Posting Group")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertBufferEntryOnBeforeBufferInsert(var TempFAGLPostBuf: Record "FA G/L Posting Buffer" temporary; FAGLPostBuf: Record "FA G/L Posting Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFAInsertGLAccount(var FALedgerEntry: Record "FA Ledger Entry"; var TempFAGLPostBuf: Record "FA G/L Posting Buffer" temporary;
                                              var FAGLPostBuf: Record "FA G/L Posting Buffer"; var DisposalEntry: Boolean; var BookValueEntry: Boolean; var NextEntryNo: Integer;
                                              var GLEntryNo: Integer; var OrgGenJnlLine: Boolean; var NetDisp: Boolean; var NumberOfEntries: Integer; var DisposalEntryNo: Integer;
                                              var DisposalAmount: Decimal; var GainLossAmount: Decimal; var FAPostingGr2: Record "FA Posting Group"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertMaintenanceAccNo(var MaintenanceLedgEntry: Record "Maintenance Ledger Entry"; var FAGLPostBuf: Record "FA G/L Posting Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateNoOfEmptyLines(var GenJnlLine: Record "Gen. Journal Line"; var TempFAGLPostingBuffer: Record "FA G/L Posting Buffer" temporary; var NextLineNo: Integer; var NoOfEmptyLines: Integer; var NoOfEmptyLines2: Integer; var NumberOfEntries: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertBufferBalAccOnAfterInsertBufferEntryFromFAAllocAcc(FAAllocation: Record "FA Allocation"; var TempFAGLPostBuf: Record "FA G/L Posting Buffer" temporary; FAPostingType: Enum "FA Posting Group Account Type"; DeprBookCode: Code[10];
                                                                                                                                                                                                       PostingGrCode: Code[20];
                                                                                                                                                                                                       NewAmount: Decimal;
                                                                                                                                                                                                       AutomaticEntry: Boolean;
                                                                                                                                                                                                       Correction: Boolean; var NumberOfEntries: Integer; OrgGenJnlLine: Boolean; NetDisp: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertBufferBalAccOnAfterInsertBufferEntryFromFAPostingGrAcc(FAAllocation: Record "FA Allocation"; var TempFAGLPostBuf: Record "FA G/L Posting Buffer" temporary; FAPostingType: Enum "FA Posting Group Account Type"; DeprBookCode: Code[10];
                                                                                                                                                                                                           PostingGrCode: Code[20];
                                                                                                                                                                                                           AllocAmount: Decimal;
                                                                                                                                                                                                           TotalAllocAmount: Decimal;
                                                                                                                                                                                                           GLAccNo: Code[20];
                                                                                                                                                                                                           GlobalDim1Code: Code[20];
                                                                                                                                                                                                           GlobalDim2Code: Code[20];
                                                                                                                                                                                                           DimSetID: Integer;
                                                                                                                                                                                                           AutomaticEntry: Boolean;
                                                                                                                                                                                                           Correction: Boolean; var NumberOfEntries: Integer; OrgGenJnlLine: Boolean; NetDisp: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindFirstGLAcc(var TempFAGLPostingBuffer: Record "FA G/L Posting Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetGLAccNoFromFAPostingGroup(FAPostingGroup: Record "FA Posting Group"; FAPostingGroupAccountType: Enum "FA Posting Group Account Type"; var GLAccNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetPostingType(FALedgerEntry: Record "FA Ledger Entry"; var FAPostingGroupAccountType: Enum "FA Posting Group Account Type"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertBufferBalAcc(FAGLPostingBuffer: Record "FA G/L Posting Buffer"; var TempFAGLPostingBuffer: Record "FA G/L Posting Buffer" temporary;
                                              GLEntryNo: Integer; var NextEntryNo: Integer; var NumberOfEntries: Integer;
                                              OrgGenJnlLine: Boolean; NetDisp: Boolean; FAPostingType: Enum "FA Posting Group Account Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCorrectDisposalEntryNonPositiveGainLossOnBeforeSetAccountGain(FADepreciationBook: Record "FA Depreciation Book"; FAPostingGroup: Record "FA Posting Group";
                                                                    var FAGLPostingBuffer: Record "FA G/L Posting Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCorrectDisposalEntryPositiveGainLossOnBeforeSetAccountGain(FADepreciationBook: Record "FA Depreciation Book"; FAPostingGroup: Record "FA Posting Group";
                                                                    var FAGLPostingBuffer: Record "FA G/L Posting Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCorrectDisposalEntryOnAfterCheckIdenticalAccountGainLoss(FADepreciationBook: Record "FA Depreciation Book"; FAPostingGroup: Record "FA Posting Group"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCorrectDisposalEntryNonPositiveGainLossOnBeforeSetAccountLoss(FADepreciationBook: Record "FA Depreciation Book"; FAPostingGroup: Record "FA Posting Group";
                                                        var FAGLPostingBuffer: Record "FA G/L Posting Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCorrectDisposalEntryPositiveGainLossOnBeforeSetAccountLoss(FADepreciationBook: Record "FA Depreciation Book"; FAPostingGroup: Record "FA Posting Group";
                                                        var FAGLPostingBuffer: Record "FA G/L Posting Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCorrectDisposalEntryOnBeforeSetGainLossAccount(FADepreciationBook: Record "FA Depreciation Book"; FAPostingGroup: Record "FA Posting Group";
                                                   var TempFAGLPostingBuffer: Record "FA G/L Posting Buffer"; GLAmount: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCorrectBookValueEntryOnAfterSetFilterFALedgEntry(var FALedgerEntry: Record "FA Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcLastDisposalOnAfterSetFilter(var FALedgerEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCorrectBookValueEntryOnAfterCheckIdenticalGainLossAmtSign(FADepreciationBook: Record "FA Depreciation Book"; FAPostingGroup: Record "FA Posting Group"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcDisposalAmountOnAfterCalcFields(var FADepreciationBook: Record "FA Depreciation Book")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCorrectDisposalEntryOnAfterCalcGainLoss(var FADepreciationBook: Record "FA Depreciation Book")
    begin
    end;
}

