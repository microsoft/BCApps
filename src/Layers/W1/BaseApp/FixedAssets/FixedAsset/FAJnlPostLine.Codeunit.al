// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Posting;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Insurance;
using Microsoft.Finance.VAT.Calculation;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;

codeunit 5632 "FA Jnl.-Post Line"
{
    Permissions = TableData "FA Ledger Entry" = r,
                  TableData "FA Register" = rm,
                  TableData "Maintenance Ledger Entry" = r,
                  TableData "Ins. Coverage Ledger Entry" = r;

    trigger OnRun()
    begin
    end;

    var
        FA: Record "Fixed Asset";
        FA2: Record "Fixed Asset";
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        FALedgEntry: Record "FA Ledger Entry";
        MaintenanceLedgEntry: Record "Maintenance Ledger Entry";
        FAInsertLedgEntry: Codeunit "FA Insert Ledger Entry";
        FAJnlCheckLine: Codeunit "FA Jnl.-Check Line";
        DuplicateDeprBook: Codeunit "Duplicate Depr. Book";
        CalculateDisposal: Codeunit "Calculate Disposal";
        CalculateDepr: Codeunit "Calculate Depreciation";
        CalculateAcqCostDepr: Codeunit "Calculate Acq. Cost Depr.";
        MakeFALedgEntry: Codeunit "Make FA Ledger Entry";
        MakeMaintenanceLedgEntry: Codeunit "Make Maintenance Ledger Entry";
        NonDeductibleVAT: Codeunit "Non-Deductible VAT";
        FANo: Code[20];
        BudgetNo: Code[20];
        DeprBookCode: Code[10];
        FAPostingType: Enum "FA Journal Line FA Posting Type";
        FAPostingDate: Date;
        Amount2: Decimal;
        SalvageValue: Decimal;
        DeprUntilDate: Boolean;
        DeprAcqCost: Boolean;
        ErrorEntryNo: Integer;
        ResultOnDisposal: Integer;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%2 must not be %3 in %4 %5 = %6 for %1.';
        Text001: Label '%2 = %3 must be canceled first for %1.';
        Text002: Label '%1 is not a %2.';
        Text003: Label '%1 = %2 already exists for %5 (%3 = %4).';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure FAJnlPostLine(FAJnlLine: Record "FA Journal Line"; CheckLine: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFAJnlPostLine(FAJnlLine, FAInsertLedgEntry, CheckLine, IsHandled);
        if not IsHandled then begin
            FAInsertLedgEntry.SetGLRegisterNo(0);
            if FAJnlLine."FA No." = '' then
                exit;
            if FAJnlLine."Posting Date" = 0D then
                FAJnlLine."Posting Date" := FAJnlLine."FA Posting Date";
            if CheckLine then
                FAJnlCheckLine.CheckFAJnlLine(FAJnlLine);
            DuplicateDeprBook.DuplicateFAJnlLine(FAJnlLine);
            FANo := FAJnlLine."FA No.";
            BudgetNo := FAJnlLine."Budgeted FA No.";
            DeprBookCode := FAJnlLine."Depreciation Book Code";
            FAPostingType := FAJnlLine."FA Posting Type";
            FAPostingDate := FAJnlLine."FA Posting Date";
            Amount2 := FAJnlLine.Amount;
            SalvageValue := FAJnlLine."Salvage Value";
            DeprUntilDate := FAJnlLine."Depr. until FA Posting Date";
            DeprAcqCost := FAJnlLine."Depr. Acquisition Cost";
            ErrorEntryNo := FAJnlLine."FA Error Entry No.";
            if FAJnlLine."FA Posting Type" = FAJnlLine."FA Posting Type"::Maintenance then begin
                MakeMaintenanceLedgEntry.CopyFromFAJnlLine(MaintenanceLedgEntry, FAJnlLine);
                PostMaintenance();
            end else begin
                MakeFALedgEntry.CopyFromFAJnlLine(FALedgEntry, FAJnlLine);
                PostFixedAsset();
            end;
        end;

        OnAfterFAJnlPostLine(FAJnlLine);
    end;

    procedure GenJnlPostLine(GenJnlLine: Record "Gen. Journal Line"; FAAmount: Decimal; VATAmount: Decimal; NextTransactionNo: Integer; NextGLEntryNo: Integer; GLRegisterNo: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGenJnlPostLine(GenJnlLine, FAInsertLedgEntry, FAAmount, VATAmount, NextTransactionNo, NextGLEntryNo, GLRegisterNo, IsHandled);
        if not IsHandled then begin
            FAInsertLedgEntry.SetGLRegisterNo(GLRegisterNo);
            FAInsertLedgEntry.DeleteAllGLAcc();
            if GenJnlLine."Account No." = '' then
                exit;
            if GenJnlLine."FA Posting Date" = 0D then
                GenJnlLine."FA Posting Date" := GenJnlLine."Posting Date";
            if GenJnlLine."Journal Template Name" = '' then
                GenJnlLine.Quantity := 0;
            DuplicateDeprBook.DuplicateGenJnlLine(GenJnlLine, FAAmount);
            FANo := GenJnlLine."Account No.";
            BudgetNo := GenJnlLine."Budgeted FA No.";
            DeprBookCode := GenJnlLine."Depreciation Book Code";
            FAPostingType := Enum::"FA Journal Line FA Posting Type".FromInteger(GenJnlLine."FA Posting Type".AsInteger() - 1);
            FAPostingDate := GenJnlLine."FA Posting Date";
            Amount2 := FAAmount;
            SalvageValue := GenJnlLine.ConvertAmtFCYToLCYForSourceCurrency(GenJnlLine."Salvage Value");
            DeprUntilDate := GenJnlLine."Depr. until FA Posting Date";
            DeprAcqCost := GenJnlLine."Depr. Acquisition Cost";
            ErrorEntryNo := GenJnlLine."FA Error Entry No.";
            if GenJnlLine."FA Posting Type" = GenJnlLine."FA Posting Type"::Maintenance then begin
                MakeMaintenanceLedgEntry.CopyFromGenJnlLine(MaintenanceLedgEntry, GenJnlLine);
                MaintenanceLedgEntry.Amount := FAAmount;
                MaintenanceLedgEntry."VAT Amount" := VATAmount;
                MaintenanceLedgEntry."Transaction No." := NextTransactionNo;
                MaintenanceLedgEntry."G/L Entry No." := NextGLEntryNo;
                OnBeforePostMaintenanceFromGenJnlLine(GenJnlLine, FALedgEntry, FAAmount, VATAmount);
                PostMaintenance();
            end else begin
                MakeFALedgEntry.CopyFromGenJnlLine(FALedgEntry, GenJnlLine);
                FALedgEntry.Amount := FAAmount;
                FALedgEntry."VAT Amount" := VATAmount;
                FALedgEntry."Transaction No." := NextTransactionNo;
                FALedgEntry."G/L Entry No." := NextGLEntryNo;
                OnBeforePostFixedAssetFromGenJnlLine(GenJnlLine, FALedgEntry, FAAmount, VATAmount, GLRegisterNo);
                PostFixedAsset();
            end;

            FAInsertLedgEntry.CopyRecordLinksToFALedgEntry(GenJnlLine);
        end;

        OnAfterGenJnlPostLine(GenJnlLine);
    end;

    local procedure PostFixedAsset()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostFixedAsset(FANo, DeprBookCode, FAPostingType, FALedgEntry, IsHandled);
        if IsHandled then
            exit;

        FA.LockTable();
        DeprBook.Get(DeprBookCode);
        FA.Get(FANo);
        IsHandled := false;
        OnPostFixedAssetOnBeforeFixedAssetTestField(FALedgEntry, Amount2, IsHandled);
        if not IsHandled then begin
            FA.TestField(Blocked, false);
            FA.TestField(Inactive, false);
        end;
        FADeprBook.Get(FANo, DeprBookCode);
        MakeFALedgEntry.CopyFromFACard(FALedgEntry, FA, FADeprBook);
        FAInsertLedgEntry.SetLastEntryNo(true);
        if (FALedgEntry."FA Posting Group" = '') and (FALedgEntry."G/L Entry No." > 0) then begin
            FADeprBook.TestField("FA Posting Group");
            FALedgEntry."FA Posting Group" := FADeprBook."FA Posting Group";
        end;
        if DeprUntilDate then
            PostDeprUntilDate(FALedgEntry, 0);
        if FAPostingType = FAPostingType::Disposal then
            PostDisposalEntry(FALedgEntry)
        else begin
            IsHandled := false;
            OnPostFixedAssetPostDisposalEntryForOtherFAPostingType(FAPostingType, IsHandled);
            if IsHandled then
                PostDisposalEntry(FALedgEntry)
            else begin
                if PostBudget() then
                    SetBudgetAssetNo();
                if not DeprLine() then begin
                    OnPostFixedAssetOnBeforeInsertEntry(FALedgEntry);
                    FAInsertLedgEntry.SetOrgGenJnlLine(true);
                    FAInsertLedgEntry.InsertFA(FALedgEntry);
                    FAInsertLedgEntry.SetOrgGenJnlLine(false);
                end;
                PostSalvageValue(FALedgEntry);
            end;
        end;
        if DeprAcqCost then
            PostDeprUntilDate(FALedgEntry, 1);
        FAInsertLedgEntry.SetLastEntryNo(false);
        if PostBudget() then
            PostBudgetAsset();

        OnAfterPostFixedAsset(FA, FALedgEntry);
    end;

    local procedure PostMaintenance()
    begin
        FA.LockTable();
        DeprBook.Get(DeprBookCode);
        FA.Get(FANo);
        FADeprBook.Get(FANo, DeprBookCode);
        MakeMaintenanceLedgEntry.CopyFromFACard(MaintenanceLedgEntry, FA, FADeprBook);
        if not DeprBook."Allow Identical Document No." and (MaintenanceLedgEntry."Journal Batch Name" <> '') then
            CheckMaintDocNo(MaintenanceLedgEntry);
        if (MaintenanceLedgEntry."FA Posting Group" = '') and (MaintenanceLedgEntry."G/L Entry No." > 0) then begin
            FADeprBook.TestField("FA Posting Group");
            MaintenanceLedgEntry."FA Posting Group" := FADeprBook."FA Posting Group";
        end;
        if PostBudget() then
            SetBudgetAssetNo();
        OnPostMaintenanceOnBeforeInsertEntry(MaintenanceLedgEntry);
        FAInsertLedgEntry.SetOrgGenJnlLine(true);
        FAInsertLedgEntry.InsertMaintenance(MaintenanceLedgEntry);
        FAInsertLedgEntry.SetOrgGenJnlLine(false);
        if PostBudget() then
            PostBudgetAsset();
    end;

    local procedure PostDisposalEntry(var FALedgEntry: Record "FA Ledger Entry")
    var
        MaxDisposalNo: Integer;
        SalesEntryNo: Integer;
        DisposalType: Option FirstDisposal,SecondDisposal,ErrorDisposal,LastErrorDisposal;
        OldDisposalMethod: Option " ",Net,Gross;
        EntryAmounts: array[14] of Decimal;
        EntryNumbers: array[14] of Integer;
        i: Integer;
        j: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostDisposalEntry(FALedgEntry, DeprBook, FANo, ErrorEntryNo, IsHandled, FAInsertLedgEntry);
        if IsHandled then
            exit;

        FALedgEntry."Disposal Calculation Method" := DeprBook."Disposal Calculation Method" + 1;
        CalculateDisposal.GetDisposalType(
          FANo, DeprBookCode, ErrorEntryNo, DisposalType,
          OldDisposalMethod, MaxDisposalNo, SalesEntryNo);
        if (MaxDisposalNo > 0) and
           (FALedgEntry."Disposal Calculation Method" <> OldDisposalMethod)
        then
            Error(
              Text000,
              FAName(), DeprBook.FieldCaption("Disposal Calculation Method"), FALedgEntry."Disposal Calculation Method",
              DeprBook.TableCaption(), DeprBook.FieldCaption(Code), DeprBook.Code);
        if ErrorEntryNo = 0 then
            FALedgEntry."Disposal Entry No." := MaxDisposalNo + 1
        else
            if SalesEntryNo <> ErrorEntryNo then
                Error(Text001,
                  FAName(), FALedgEntry.FieldCaption("Disposal Entry No."), MaxDisposalNo);
        if DisposalType = DisposalType::FirstDisposal then
            PostReverseType(FALedgEntry);
        if DeprBook."Disposal Calculation Method" = DeprBook."Disposal Calculation Method"::Gross then
            FAInsertLedgEntry.SetOrgGenJnlLine(true);
        FAInsertLedgEntry.InsertFA(FALedgEntry);
        FAInsertLedgEntry.SetOrgGenJnlLine(false);
        FALedgEntry."Automatic Entry" := true;
        FAInsertLedgEntry.SetNetdisposal(false);
        if (DeprBook."Disposal Calculation Method" =
            DeprBook."Disposal Calculation Method"::Net) and
           DeprBook."VAT on Net Disposal Entries"
        then
            FAInsertLedgEntry.SetNetdisposal(true);

        if DisposalType = DisposalType::FirstDisposal then begin
            CalculateDisposal.CalcGainLoss(FANo, DeprBookCode, EntryAmounts);
            for i := 1 to 14 do
                if EntryAmounts[i] <> 0 then begin
                    FALedgEntry."FA Posting Category" := CalculateDisposal.SetFALedgerPostingCategory(i);
                    FALedgEntry."FA Posting Type" := "FA Ledger Entry FA Posting Type".FromInteger(CalculateDisposal.SetFAPostingType(i));
                    FALedgEntry.Amount := EntryAmounts[i];
                    if i = 1 then
                        FALedgEntry."Result on Disposal" := FALedgEntry."Result on Disposal"::Gain;
                    if i = 2 then
                        FALedgEntry."Result on Disposal" := FALedgEntry."Result on Disposal"::Loss;
                    if i > 2 then
                        FALedgEntry."Result on Disposal" := FALedgEntry."Result on Disposal"::" ";
                    if i = 10 then
                        SetResultOnDisposal(FALedgEntry);
                    FAInsertLedgEntry.InsertFA(FALedgEntry);
                    PostAllocation(FALedgEntry);
                end;
        end;
        if DisposalType = DisposalType::SecondDisposal then begin
            CalculateDisposal.CalcSecondGainLoss(FANo, DeprBookCode, FALedgEntry.Amount, EntryAmounts);
            for i := 1 to 2 do
                if EntryAmounts[i] <> 0 then begin
                    FALedgEntry."FA Posting Category" := CalculateDisposal.SetFALedgerPostingCategory(i);
                    FALedgEntry."FA Posting Type" := "FA Ledger Entry FA Posting Type".FromInteger(CalculateDisposal.SetFAPostingType(i));
                    FALedgEntry.Amount := EntryAmounts[i];
                    if i = 1 then
                        FALedgEntry."Result on Disposal" := FALedgEntry."Result on Disposal"::Gain;
                    if i = 2 then
                        FALedgEntry."Result on Disposal" := FALedgEntry."Result on Disposal"::Loss;
                    FAInsertLedgEntry.InsertFA(FALedgEntry);
                    PostAllocation(FALedgEntry);
                end;
        end;
        if DisposalType in
           [DisposalType::ErrorDisposal, DisposalType::LastErrorDisposal]
        then begin
            CalculateDisposal.GetErrorDisposal(
              FANo, DeprBookCode, DisposalType = DisposalType::ErrorDisposal, MaxDisposalNo,
              EntryAmounts, EntryNumbers);
            if DisposalType = DisposalType::ErrorDisposal then
                j := 2
            else begin
                j := 14;
                ResultOnDisposal := CalcResultOnDisposal(FANo, DeprBookCode);
            end;
            for i := 1 to j do
                if EntryNumbers[i] <> 0 then begin
                    FALedgEntry.Amount := EntryAmounts[i];
                    FALedgEntry."Entry No." := EntryNumbers[i];
                    FALedgEntry."FA Posting Category" := CalculateDisposal.SetFALedgerPostingCategory(i);
                    FALedgEntry."FA Posting Type" := "FA Ledger Entry FA Posting Type".FromInteger(CalculateDisposal.SetFAPostingType(i));
                    if i = 1 then
                        FALedgEntry."Result on Disposal" := FALedgEntry."Result on Disposal"::Gain;
                    if i = 2 then
                        FALedgEntry."Result on Disposal" := FALedgEntry."Result on Disposal"::Loss;
                    if i > 2 then
                        FALedgEntry."Result on Disposal" := FALedgEntry."Result on Disposal"::" ";
                    if i = 10 then
                        FALedgEntry."Result on Disposal" := ResultOnDisposal;
                    FAInsertLedgEntry.InsertFA(FALedgEntry);
                    PostAllocation(FALedgEntry);
                end;
        end;
        OnPostDisposalEntryOnAfterPostDisposalType(FAInsertLedgEntry, FALedgEntry, DisposalType, EntryAmounts);
        FAInsertLedgEntry.CorrectEntries();
        FAInsertLedgEntry.SetNetdisposal(false);

        OnAfterPostDisposalEntry(FALedgEntry, DeprBook, FANo, FAInsertLedgEntry);
    end;

    local procedure PostDeprUntilDate(FALedgEntry: Record "FA Ledger Entry"; Type: Option UntilDate,AcqCost)
    var
        DepreciationAmount: Decimal;
        Custom1Amount: Decimal;
        NumberOfDays: Integer;
        Custom1NumberOfDays: Integer;
        DummyEntryAmounts: array[4] of Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostDeprUntilDate(FALedgEntry, FAPostingDate, Type, IsHandled);
        if IsHandled then
            exit;
        if NonDeductibleVAT.IsNonDedFALedgEntryInFirstAcquisition(FALedgEntry) then
            exit;
        FALedgEntry."Automatic Entry" := true;
        FALedgEntry."FA No./Budgeted FA No." := '';
        FALedgEntry."FA Posting Category" := FALedgEntry."FA Posting Category"::" ";
        FALedgEntry."No. of Depreciation Days" := 0;
        if Type = Type::UntilDate then
            CalculateDepr.Calculate(
              DepreciationAmount, Custom1Amount, NumberOfDays, Custom1NumberOfDays,
              FANo, DeprBookCode, FAPostingDate, DummyEntryAmounts, 0D, 0)
        else
            CalculateAcqCostDepr.DeprCalc(
              DepreciationAmount, Custom1Amount, FANo, DeprBookCode,
              Amount2 + SalvageValue, Amount2);
        if Custom1Amount <> 0 then begin
            FALedgEntry."FA Posting Type" := FALedgEntry."FA Posting Type"::"Custom 1";
            FALedgEntry.Amount := Custom1Amount;
            FALedgEntry."No. of Depreciation Days" := Custom1NumberOfDays;
            FAInsertLedgEntry.InsertFA(FALedgEntry);
            if FALedgEntry."G/L Entry No." > 0 then
                FAInsertLedgEntry.InsertBalAcc(FALedgEntry);
        end;
        if DepreciationAmount <> 0 then begin
            FALedgEntry."FA Posting Type" := FALedgEntry."FA Posting Type"::Depreciation;
            FALedgEntry.Amount := DepreciationAmount;
            FALedgEntry."No. of Depreciation Days" := NumberOfDays;
            FAInsertLedgEntry.InsertFA(FALedgEntry);
            if FALedgEntry."G/L Entry No." > 0 then
                FAInsertLedgEntry.InsertBalAcc(FALedgEntry);
        end;
    end;

    local procedure PostSalvageValue(FALedgEntry: Record "FA Ledger Entry")
    begin
        if (SalvageValue = 0) or (FAPostingType <> FAPostingType::"Acquisition Cost") then
            exit;
        FALedgEntry."Entry No." := 0;
        FALedgEntry."Automatic Entry" := true;
        FALedgEntry.Amount := SalvageValue;
        FALedgEntry."FA Posting Type" := FALedgEntry."FA Posting Type"::"Salvage Value";
        OnPostSalvageValueOnBeforeInsertEntry(FALedgEntry);
        FAInsertLedgEntry.InsertFA(FALedgEntry);
    end;

    local procedure PostBudget(): Boolean
    begin
        exit(BudgetNo <> '');
    end;

    local procedure SetBudgetAssetNo()
    begin
        FA2.Get(BudgetNo);
        if not FA2."Budgeted Asset" then begin
            FA."No." := FA2."No.";
            DeprBookCode := '';
            Error(Text002, FAName(), FA.FieldCaption("Budgeted Asset"));
        end;
        if FAPostingType = FAPostingType::Maintenance then
            MaintenanceLedgEntry."FA No./Budgeted FA No." := BudgetNo
        else
            FALedgEntry."FA No./Budgeted FA No." := BudgetNo;
    end;

    local procedure PostBudgetAsset()
    var
        FA2: Record "Fixed Asset";
        FAPostingType2: Enum "FA Ledger Entry FA Posting Type";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostBudgetAsset(FALedgEntry, BudgetNo, IsHandled);
        if IsHandled then
            exit;

        FA2.Get(BudgetNo);
        FA2.TestField(Blocked, false);
        FA2.TestField(Inactive, false);
        if FAPostingType = FAPostingType::Maintenance then begin
            MaintenanceLedgEntry."Automatic Entry" := true;
            MaintenanceLedgEntry."G/L Entry No." := 0;
            MaintenanceLedgEntry."FA No./Budgeted FA No." := MaintenanceLedgEntry."FA No.";
            MaintenanceLedgEntry."FA No." := BudgetNo;
            MaintenanceLedgEntry.Amount := -Amount2;
            OnPostBudgetAssetOnBeforeInsertMaintenanceLedgEntry(MaintenanceLedgEntry);
            FAInsertLedgEntry.InsertMaintenance(MaintenanceLedgEntry);
        end else begin
            FALedgEntry."Automatic Entry" := true;
            FALedgEntry."G/L Entry No." := 0;
            FALedgEntry."FA No./Budgeted FA No." := FALedgEntry."FA No.";
            FALedgEntry."FA No." := BudgetNo;
            if SalvageValue <> 0 then begin
                FALedgEntry.Amount := -SalvageValue;
                FAPostingType2 := FALedgEntry."FA Posting Type";
                FALedgEntry."FA Posting Type" := FALedgEntry."FA Posting Type"::"Salvage Value";
                FAInsertLedgEntry.InsertFA(FALedgEntry);
                FALedgEntry."FA Posting Type" := FAPostingType2;
            end;
            FALedgEntry.Amount := -Amount2;
            OnPostBudgetAssetOnBeforeInsertFAEntry(FALedgEntry);
            FAInsertLedgEntry.InsertFA(FALedgEntry);
        end;
    end;

    procedure PostReverseType(FALedgEntry: Record "FA Ledger Entry")
    var
        EntryAmounts: array[4] of Decimal;
        i: Integer;
    begin
        OnBeforePostReverseType(FALedgEntry);
        CalculateDisposal.CalcReverseAmounts(FANo, DeprBookCode, EntryAmounts);
        FALedgEntry."FA Posting Category" := FALedgEntry."FA Posting Category"::" ";
        FALedgEntry."Automatic Entry" := true;
        for i := 1 to 4 do
            if EntryAmounts[i] <> 0 then begin
                FALedgEntry.Amount := EntryAmounts[i];
                FALedgEntry."FA Posting Type" := "FA Ledger Entry FA Posting Type".FromInteger(CalculateDisposal.SetReverseType(i));
                FAInsertLedgEntry.InsertFA(FALedgEntry);
                if FALedgEntry."G/L Entry No." > 0 then
                    FAInsertLedgEntry.InsertBalAcc(FALedgEntry);
            end;
    end;

    procedure PostGLBalAcc(FALedgEntry: Record "FA Ledger Entry"; AllocatedPct: Decimal)
    begin
        OnBeforePostGLBalAcc(FALedgEntry, AllocatedPct);
        if AllocatedPct > 0 then begin
            FALedgEntry."Entry No." := 0;
            FALedgEntry."Automatic Entry" := true;
            FALedgEntry.Amount := -FALedgEntry.Amount;
            FALedgEntry.Correction := not FALedgEntry.Correction;
            FAInsertLedgEntry.InsertBalDisposalAcc(FALedgEntry);
            FALedgEntry.Correction := not FALedgEntry.Correction;
            FAInsertLedgEntry.InsertBalAcc(FALedgEntry);
        end;
    end;

    local procedure PostAllocation(var FALedgEntry: Record "FA Ledger Entry")
    var
        FAPostingGr: Record "FA Posting Group";
        IsHandled: Boolean;
    begin
        OnBeforePostAllocation(FALedgEntry, IsHandled);
        if IsHandled then
            exit;

        if FALedgEntry."G/L Entry No." = 0 then
            exit;
        case FALedgEntry."FA Posting Type" of
            FALedgEntry."FA Posting Type"::"Gain/Loss":
                if DeprBook."Disposal Calculation Method" = DeprBook."Disposal Calculation Method"::Net then begin
                    FAPostingGr.GetPostingGroup(FALedgEntry."FA Posting Group", DeprBook.Code);
                    FAPostingGr.CalcFields("Allocated Gain %", "Allocated Loss %");
                    if FALedgEntry."Result on Disposal" = FALedgEntry."Result on Disposal"::Gain then
                        PostGLBalAcc(FALedgEntry, FAPostingGr."Allocated Gain %")
                    else
                        PostGLBalAcc(FALedgEntry, FAPostingGr."Allocated Loss %");
                end;
            FALedgEntry."FA Posting Type"::"Book Value on Disposal":
                begin
                    FAPostingGr.GetPostingGroup(FALedgEntry."FA Posting Group", DeprBook.Code);
                    FAPostingGr.CalcFields("Allocated Book Value % (Gain)", "Allocated Book Value % (Loss)");
                    if FALedgEntry."Result on Disposal" = FALedgEntry."Result on Disposal"::Gain then
                        PostGLBalAcc(FALedgEntry, FAPostingGr."Allocated Book Value % (Gain)")
                    else
                        PostGLBalAcc(FALedgEntry, FAPostingGr."Allocated Book Value % (Loss)");
                end;
        end;
        OnAfterPostAllocation(FALedgEntry);
    end;

    local procedure DeprLine(): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        Result := false;
        OnBeforeDeprLine(FAPostingType, DeprUntilDate, Amount2, IsHandled, Result);
        if IsHandled then
            exit(Result);
        exit((Amount2 = 0) and (FAPostingType = FAPostingType::Depreciation) and DeprUntilDate);
    end;

    procedure FindFirstGLAcc(var FAGLPostBuf: Record "FA G/L Posting Buffer"): Boolean
    begin
        exit(FAInsertLedgEntry.FindFirstGLAcc(FAGLPostBuf));
    end;

    procedure GetNextGLAcc(var FAGLPostBuf: Record "FA G/L Posting Buffer"): Integer
    begin
        exit(FAInsertLedgEntry.GetNextGLAcc(FAGLPostBuf));
    end;

    local procedure FAName(): Text[200]
    var
        DepreciationCalc: Codeunit "Depreciation Calculation";
    begin
        exit(DepreciationCalc.FAName(FA, DeprBookCode));
    end;

    procedure SetResultOnDisposal(var FALedgEntry: Record "FA Ledger Entry")
    var
        FADeprBook: Record "FA Depreciation Book";
    begin
        FADeprBook."FA No." := FALedgEntry."FA No.";
        FADeprBook."Depreciation Book Code" := FALedgEntry."Depreciation Book Code";
        FADeprBook.CalcFields("Gain/Loss");
        OnSetResultOnDisposalOnAfterCalcGainLoss(FADeprBook);
        if FADeprBook."Gain/Loss" <= 0 then
            FALedgEntry."Result on Disposal" := FALedgEntry."Result on Disposal"::Gain
        else
            FALedgEntry."Result on Disposal" := FALedgEntry."Result on Disposal"::Loss;
    end;

    local procedure CalcResultOnDisposal(FANo: Code[20]; DeprBookCode: Code[10]): Integer
    var
        FADeprBook: Record "FA Depreciation Book";
        FALedgEntry: Record "FA Ledger Entry";
    begin
        FADeprBook."FA No." := FANo;
        FADeprBook."Depreciation Book Code" := DeprBookCode;
        FADeprBook.CalcFields("Gain/Loss");
        OnCalcResultOnDisposalOnAfterCalcGainLoss(FADeprBook);
        if FADeprBook."Gain/Loss" <= 0 then
            exit(FALedgEntry."Result on Disposal"::Gain);

        exit(FALedgEntry."Result on Disposal"::Loss);
    end;

    local procedure CheckMaintDocNo(MaintenanceLedgEntry: Record "Maintenance Ledger Entry")
    var
        OldMaintenanceLedgEntry: Record "Maintenance Ledger Entry";
        FAJnlLine2: Record "FA Journal Line";
    begin
        OldMaintenanceLedgEntry.SetCurrentKey("FA No.", "Depreciation Book Code", "Document No.");
        OldMaintenanceLedgEntry.SetRange("FA No.", MaintenanceLedgEntry."FA No.");
        OldMaintenanceLedgEntry.SetRange("Depreciation Book Code", MaintenanceLedgEntry."Depreciation Book Code");
        OldMaintenanceLedgEntry.SetRange("Document No.", MaintenanceLedgEntry."Document No.");
        if OldMaintenanceLedgEntry.FindFirst() then begin
            FAJnlLine2."FA Posting Type" := FAJnlLine2."FA Posting Type"::Maintenance;
            Error(
              Text003,
              OldMaintenanceLedgEntry.FieldCaption("Document No."),
              OldMaintenanceLedgEntry."Document No.",
              FAJnlLine2.FieldCaption("FA Posting Type"),
              FAJnlLine2."FA Posting Type",
              FAName());
        end;
    end;

    procedure UpdateRegNo(GLRegNo: Integer)
    var
        FAReg: Record "FA Register";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateRegNo(GLRegNo, IsHandled);
        if IsHandled then
            exit;
        if FAReg.FindLast() then begin
            FAReg."G/L Register No." := GLRegNo;
            FAReg.Modify();
        end;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterFAJnlPostLine(var FAJournalLine: Record "FA Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterPostDisposalEntry(var FALedgEntry: Record "FA Ledger Entry"; DeprBook: Record "Depreciation Book"; FANo: Code[20]; var FAInsertLedgEntry: Codeunit "FA Insert Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostFixedAsset(var FA: Record "Fixed Asset"; FALedgEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeFAJnlPostLine(var FAJournalLine: Record "FA Journal Line"; var FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry"; CheckLine: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeGenJnlPostLine(var GenJournalLine: Record "Gen. Journal Line"; var FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry"; FAAmount: Decimal; VATAmount: Decimal; NextTransactionNo: Integer; NextGLEntryNo: Integer; GLRegisterNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePostAllocation(var FALedgEntry: Record "FA Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostBudgetAsset(var FALedgerEntry: Record "FA Ledger Entry"; BudgetNo: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostReverseType(var FALedgEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePostDeprUntilDate(var FALedgEntry: Record "FA Ledger Entry"; var FAPostingDate: Date; Type: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforePostDisposalEntry(var FALedgEntry: Record "FA Ledger Entry"; DeprBook: Record "Depreciation Book"; FANo: Code[20]; ErrorEntryNo: Integer; var IsHandled: Boolean; var FAInsertLedgEntry: Codeunit "FA Insert Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostFixedAsset(FANo: Code[20]; DeprBookCode: Code[10]; FAPostingType: Enum "FA Journal Line FA Posting Type"; FALedgEntry: Record "FA Ledger Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostMaintenanceFromGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; var FALedgerEntry: Record "FA Ledger Entry"; FAAmount: Decimal; VATAmount: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostFixedAssetFromGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; var FALedgerEntry: Record "FA Ledger Entry"; FAAmount: Decimal; VATAmount: Decimal; GLRegisterNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostFixedAssetOnBeforeInsertEntry(var FALedgEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostSalvageValueOnBeforeInsertEntry(var FALedgEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostMaintenanceOnBeforeInsertEntry(var MaintenanceLedgEntry: Record "Maintenance Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBudgetAssetOnBeforeInsertMaintenanceLedgEntry(var MaintenanceLedgEntry: Record "Maintenance Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostBudgetAssetOnBeforeInsertFAEntry(var FALedgEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostAllocation(var FALedgerEntry: Record "FA Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostGLBalAcc(FALedgerEntry: Record "FA Ledger Entry"; var AllocatedPct: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostFixedAssetPostDisposalEntryForOtherFAPostingType(FAPostingType: Enum "FA Journal Line FA Posting Type"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeprLine(FAPostingType: Enum "FA Journal Line FA Posting Type"; DeprUntilDate: Boolean; Amount2: Decimal; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateRegNo(GLRegNo: Integer; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostFixedAssetOnBeforeFixedAssetTestField(FALedgerEntry: Record "FA Ledger Entry"; Amount2: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDisposalEntryOnAfterPostDisposalType(var FAInsertLedgerEntry: Codeunit "FA Insert Ledger Entry"; var FALedgerEntry: Record "FA Ledger Entry"; DisposalType: Option; EntryAmounts: array[14] of Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetResultOnDisposalOnAfterCalcGainLoss(var FADepreciationBook: Record "FA Depreciation Book")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcResultOnDisposalOnAfterCalcGainLoss(var FADepreciationBook: Record "FA Depreciation Book")
    begin
    end;
}

