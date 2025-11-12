// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Depreciation;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Ledger;

codeunit 5615 "Budget Depreciation"
{

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'In a budget report, %1 must be %2 in %3.';
        Text001: Label 'Budget calculation has not been done on fixed assets with %1 %2, %3 or %4.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        NoOfErrors: Integer;
        CallNo: Integer;

    procedure Calculate(FANo: Code[20]; EndingDate1: Date; EndingDate2: Date; DeprBookCode: Code[10]; var DeprAmount1: Decimal; var DeprAmount2: Decimal)
    var
        DeprBook: Record "Depreciation Book";
        FADeprBook: Record "FA Depreciation Book";
        CalculateNormalDepr: Codeunit "Calculate Normal Depreciation";
        NumberOfDays: Integer;
        DummyEntryAmounts: array[4] of Decimal;
        IsHandled: Boolean;
    begin
        DeprAmount1 := 0;
        DeprAmount2 := 0;
        if CallNo = 0 then begin
            CallNo := 1;
            DeprBook.Get(DeprBookCode);
            if DeprBook."Use Custom 1 Depreciation" then
                Error(
                  Text000,
                  DeprBook.FieldCaption("Use Custom 1 Depreciation"), false, DeprBook.TableCaption());
        end;

        IsHandled := false;
        OnCalculateOnAfterCallNoCheck(FANo, EndingDate1, EndingDate2, DeprBookCode, DeprAmount1, DeprAmount2, IsHandled);
        if IsHandled then
            exit;

        if not FADeprBook.Get(FANo, DeprBookCode) then
            exit;
        case FADeprBook."Depreciation Method" of
            FADeprBook."Depreciation Method"::"Declining-Balance 1",
            FADeprBook."Depreciation Method"::"DB1/SL",
            FADeprBook."Depreciation Method"::"DB2/SL":
                if NoOfErrors = 0 then begin
                    CreateMessage();
                    NoOfErrors := 1;
                end;
            else begin
                if EndingDate1 > 0D then
                    CalculateNormalDepr.Calculate(
                      DeprAmount1, NumberOfDays, FANo, DeprBookCode, EndingDate1, DummyEntryAmounts, 0D, 0);
                if EndingDate2 > 0D then
                    CalculateNormalDepr.Calculate(
                      DeprAmount2, NumberOfDays, FANo, DeprBookCode, EndingDate2, DummyEntryAmounts, 0D, 0);
            end;
        end;
    end;

    local procedure CreateMessage()
    var
        FADeprBook2: Record "FA Depreciation Book";
        FADeprBook3: Record "FA Depreciation Book";
        FADeprBook4: Record "FA Depreciation Book";
    begin
        FADeprBook2."Depreciation Method" := FADeprBook2."Depreciation Method"::"Declining-Balance 1";
        FADeprBook3."Depreciation Method" := FADeprBook3."Depreciation Method"::"DB1/SL";
        FADeprBook4."Depreciation Method" := FADeprBook4."Depreciation Method"::"DB2/SL";
        Message(
          Text001,
          FADeprBook2.FieldCaption("Depreciation Method"),
          FADeprBook2."Depreciation Method",
          FADeprBook3."Depreciation Method",
          FADeprBook4."Depreciation Method");
    end;

    procedure CopyProjectedValueToBudget(FADeprBook: Record "FA Depreciation Book"; BudgetNameCode: Code[10]; PostingDate: Date; DeprAmount: Decimal; Custom1Amount: Decimal; BalAccount: Boolean)
    var
        FA: Record "Fixed Asset";
        FALedgEntry: Record "FA Ledger Entry";
        BudgetText: Text[150];
    begin
        FADeprBook.TestField("FA Posting Group");
        FALedgEntry."FA No." := FADeprBook."FA No.";
        FALedgEntry."Depreciation Book Code" := FADeprBook."Depreciation Book Code";
        FALedgEntry."FA Posting Group" := FADeprBook."FA Posting Group";
        FALedgEntry."Posting Date" := PostingDate;
        FALedgEntry."FA Posting Date" := PostingDate;
        FALedgEntry."FA Posting Type" := FALedgEntry."FA Posting Type"::Depreciation;
        FALedgEntry.Amount := DeprAmount;
        BudgetText :=
          StrSubstNo('%1 %2: %3', FA.TableCaption(), FADeprBook."FA No.", FALedgEntry."FA Posting Type");
        if FALedgEntry.Amount <> 0 then
            CopyFAToBudget(FALedgEntry, BudgetNameCode, BalAccount, BudgetText);

        FALedgEntry."FA Posting Type" := FALedgEntry."FA Posting Type"::"Custom 1";
        FALedgEntry.Amount := Custom1Amount;
        BudgetText :=
          StrSubstNo('%1 %2: %3', FA.TableCaption(), FADeprBook."FA No.", FALedgEntry."FA Posting Type");

        if FALedgEntry.Amount <> 0 then
            CopyFAToBudget(FALedgEntry, BudgetNameCode, BalAccount, BudgetText);
    end;

    procedure CopyFAToBudget(FALedgEntry: Record "FA Ledger Entry"; BudgetNameCode: Code[10]; BalAccount: Boolean; BudgetText: Text[150])
    var
        BudgetName: Record "G/L Budget Name";
        GLBudgetEntry: Record "G/L Budget Entry";
        FAGLPostBuf: Record "FA G/L Posting Buffer";
        FAInsertGLAcc: Codeunit "FA Insert G/L Account";
        NextEntryNo: Integer;
    begin
        GLBudgetEntry.LockTable();
        BudgetName.LockTable();

        BudgetName.Get(BudgetNameCode);
        BudgetName.TestField(Blocked, false);
        NextEntryNo := GLBudgetEntry.GetLastEntryNo() + 1;
        GLBudgetEntry.Init();
        GLBudgetEntry."Budget Name" := BudgetNameCode;
        FALedgEntry."G/L Entry No." := NextEntryNo;
        FAInsertGLAcc.DeleteAllGLAcc();
        FAInsertGLAcc.Run(FALedgEntry);
        if BalAccount then
            FAInsertGLAcc.InsertBalAcc(FALedgEntry);
        if FAInsertGLAcc.FindFirstGLAcc(FAGLPostBuf) then
            repeat
                GLBudgetEntry."Entry No." := FAGLPostBuf."Entry No.";
                GLBudgetEntry."G/L Account No." := FAGLPostBuf."Account No.";
                GLBudgetEntry.Amount := FAGLPostBuf.Amount;
                GLBudgetEntry.Date := FALedgEntry."Posting Date";
                GLBudgetEntry.Description := FALedgEntry.Description;
                if BudgetText <> '' then
                    GLBudgetEntry.Description := CopyStr(BudgetText, 1, MaxStrLen(GLBudgetEntry.Description));
                GLBudgetEntry."User ID" := CopyStr(UserId(), 1, MaxStrLen(GLBudgetEntry."User ID"));

                if FAGLPostBuf."FA Posting Group" <> '' then
                    GLBudgetEntry."Dimension Set ID" := FAGLPostBuf."Dimension Set ID"
                else
                    GLBudgetEntry."Dimension Set ID" := GetFADefaultDimSetID(FALedgEntry);
                UpdateDimCodesFromDimSetID(GLBudgetEntry, BudgetName);
                OnBeforeGLBudgetEntryInsert(GLBudgetEntry, FALedgEntry, FAGLPostBuf, BudgetName);
                GLBudgetEntry.Insert();
            until FAInsertGLAcc.GetNextGLAcc(FAGLPostBuf) = 0;
    end;

    local procedure GetFADefaultDimSetID(var FALedgerEntry: Record "FA Ledger Entry"): Integer
    var
        DefaultDim: Record "Default Dimension";
        TempDimSetEntry: Record "Dimension Set Entry" temporary;
        DimVal: Record "Dimension Value";
        DimMgt: Codeunit DimensionManagement;
    begin
        DefaultDim.SetRange("Table ID", DATABASE::"Fixed Asset");
        DefaultDim.SetRange("No.", FALedgerEntry."FA No.");
        if DefaultDim.FindSet() then
            repeat
                DimVal.Get(DefaultDim."Dimension Code", DefaultDim."Dimension Value Code");
                TempDimSetEntry."Dimension Code" := DimVal."Dimension Code";
                TempDimSetEntry."Dimension Value Code" := DimVal.Code;
                TempDimSetEntry."Dimension Value ID" := DimVal."Dimension Value ID";
                TempDimSetEntry.Insert();
            until DefaultDim.Next() = 0;

        exit(DimMgt.GetDimensionSetID(TempDimSetEntry));
    end;

    local procedure UpdateDimCodesFromDimSetID(var GLBudgetEntry: Record "G/L Budget Entry"; GLBudgetName: Record "G/L Budget Name")
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.UpdateGlobalDimFromDimSetID(GLBudgetEntry."Dimension Set ID", GLBudgetEntry."Global Dimension 1 Code", GLBudgetEntry."Global Dimension 2 Code");
        UpdateBudgetDimFromDimSetID(GLBudgetEntry."Budget Dimension 1 Code", GLBudgetEntry."Dimension Set ID", GLBudgetName."Budget Dimension 1 Code");
        UpdateBudgetDimFromDimSetID(GLBudgetEntry."Budget Dimension 2 Code", GLBudgetEntry."Dimension Set ID", GLBudgetName."Budget Dimension 2 Code");
        UpdateBudgetDimFromDimSetID(GLBudgetEntry."Budget Dimension 3 Code", GLBudgetEntry."Dimension Set ID", GLBudgetName."Budget Dimension 3 Code");
        UpdateBudgetDimFromDimSetID(GLBudgetEntry."Budget Dimension 4 Code", GLBudgetEntry."Dimension Set ID", GLBudgetName."Budget Dimension 4 Code");
    end;

    local procedure UpdateBudgetDimFromDimSetID(var BudgetDimensionValue: Code[20]; DimSetID: Integer; BudgetDimensionCode: Code[20])
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        if DimensionSetEntry.Get(DimSetID, BudgetDimensionCode) then
            BudgetDimensionValue := DimensionSetEntry."Dimension Value Code";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGLBudgetEntryInsert(var GLBudgetEntry: Record "G/L Budget Entry"; var FALedgerEntry: Record "FA Ledger Entry"; var FAGLPostingBuffer: Record "FA G/L Posting Buffer"; var GLBudgetName: Record "G/L Budget Name")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateOnAfterCallNoCheck(FANo: Code[20]; EndingDate1: Date; EndingDate2: Date; DeprBookCode: Code[10]; var DeprAmount1: Decimal; var DeprAmount2: Decimal; var IsHandled: Boolean);
    begin
    end;
}

