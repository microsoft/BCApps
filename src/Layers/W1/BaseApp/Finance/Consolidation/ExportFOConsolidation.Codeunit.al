// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Consolidation;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;

codeunit 439 "Export F/O Consolidation"
{
    trigger OnRun()
    begin

    end;

    var
        TempGLAcc: Record "G/L Account" temporary;
        TempGLEntry: Record "G/L Entry" temporary;
        TempGLBudgetEntry: Record "G/L Budget Entry" temporary;
        TempDimBuf: Record "Dimension Buffer" temporary;
        TempDimensionIDBuffer: Record "Dimension ID Buffer" temporary;
        CompanyCurrencyCode: Code[10];
        FOLegalEntityID: Code[4];
        DimConflictErr: Label 'It is not possible to consolidate ledger entry dimensions for G/L Entry No. %1, because there are conflicting dimension values %2 and %3 for consolidation dimension %4.', Comment = '%1 - entry number, %2 and %3 - dimension values, %4 - dimension code';
        LegalEntityIDLineTok: Label '4,"%1"', Comment = '%1  text value';
        DimensionLineTok: Label '6,"%1",%2', Comment = '%2 - number, %1 - text value';
        DimensionValueLineTok: Label '7,"%1",%2,%3', Comment = '%1 text value, %2, %3 - number';
        GLEntryLineTok: Label '2,"%1","%2",%3,"%4",%5,%6,%7,%8,%9', Comment = '%3, %5, %6, %7, %8, %9 - numbers, %1,%4 - text value, %2 - date';
        GLAccountLineTok: Label '1,"%1","%2",%3', Comment = '%1, %2 - text value, %3 - number';

    procedure SetFOLegalEntityID(NewFOLegalEntityID: Code[4])
    begin
        FOLegalEntityID := NewFOLegalEntityID;
    end;

    procedure InsertGLEntry(NewGLEntry: Record "G/L Entry"): Integer
    var
        GLAccount: Record "G/L Account";
        NextEntryNo: Integer;
    begin
        NextEntryNo := TempGLEntry.GetLastEntryNo() + 1;

        TempGLEntry.Init();
        TempGLEntry."Entry No." := NextEntryNo;
        GLAccount.Get(NewGLEntry."G/L Account No.");
        if NewGLEntry."Debit Amount" <> 0 then begin
            GLAccount.TestField("Consol. Debit Acc.");
            TempGLEntry."G/L Account No." := GLAccount."Consol. Debit Acc.";
        end else begin
            GLAccount.TestField("Consol. Credit Acc.");
            TempGLEntry."G/L Account No." := GLAccount."Consol. Credit Acc.";
        end;

        InsertGLAccount(TempGLEntry."G/L Account No.", GLAccount.Name);

        TempGLEntry."Posting Date" := NewGLEntry."Posting Date";
        TempGLEntry.Amount := NewGLEntry.Amount;
        TempGLEntry."Debit Amount" := NewGLEntry."Debit Amount";
        TempGLEntry."Credit Amount" := NewGLEntry."Credit Amount";
        TempGLEntry.Insert();
        exit(NextEntryNo);
    end;

    local procedure InsertGLAccount(AccountNo: Code[20]; AccountName: Text[100])
    begin
        if not TempGLAcc.Get(AccountNo) then begin
            TempGLAcc.Init();
            TempGLAcc."No." := AccountNo;
            TempGLAcc.Name := AccountName;
            TempGLAcc.Insert();
        end;
    end;

    procedure InsertEntryDim(NewDimBuf: Record "Dimension Buffer"; GLEntryNo: Integer)
    begin
        if TempDimBuf.Get(NewDimBuf."Table ID", GLEntryNo, NewDimBuf."Dimension Code") then begin
            if NewDimBuf."Dimension Value Code" <> TempDimBuf."Dimension Value Code" then
                Error(
                  DimConflictErr, GLEntryNo, NewDimBuf."Dimension Value Code", TempDimBuf."Dimension Value Code",
                  NewDimBuf."Dimension Code");
        end else begin
            TempDimBuf.Init();
            TempDimBuf := NewDimBuf;
            TempDimBuf."Entry No." := GLEntryNo;
            TempDimBuf.Insert();
        end;
    end;

    local procedure CreateDimensionBuffer()
    var
        Id: Integer;
    begin
        if TempDimBuf.FindSet() then
            repeat
                if not TempDimensionIDBuffer.get(0, TempDimBuf."Dimension Code", '') then begin
                    Id += 1;
                    TempDimensionIDBuffer.Init();
                    TempDimensionIDBuffer."Dimension Code" := TempDimBuf."Dimension Code";
                    TempDimensionIDBuffer.ID := Id;
                    TempDimensionIDBuffer.Insert();
                end;
            until TempDimBuf.Next() = 0;
    end;

    procedure ProcessGLBugdetEntries(AccountNo: Code[20]; StartDate: Date; EndDate: Date)
    var
        GLBudgetEntry: Record "G/L Budget Entry";
        GLAccount: Record "G/L Account";
    begin
        GLBudgetEntry.SetRange(Date, StartDate, EndDate);
        GLBudgetEntry.SetRange("G/L Account No.", AccountNo);
        if GLBudgetEntry.FindSet() then
            repeat
                TempGLBudgetEntry := GLBudgetEntry;
                if GLBudgetEntry.Amount > 0 then begin
                    GLAccount.Get(GLBudgetEntry."G/L Account No.");
                    GLAccount.TestField("Consol. Debit Acc.");
                    TempGLBudgetEntry."G/L Account No." := GLAccount."Consol. Debit Acc.";
                end else begin
                    GLAccount.Get(GLBudgetEntry."G/L Account No.");
                    GLAccount.TestField("Consol. Credit Acc.");
                    TempGLBudgetEntry."G/L Account No." := GLAccount."Consol. Credit Acc.";
                end;
                TempGLBudgetEntry.Insert();
            until GLBudgetEntry.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure ExportFile(FileName: Text)
    var
        OutputFile: File;
    begin
        CreateDimensionBuffer();
        CompanyCurrencyCode := GetCompanyCurrencyCode();

        OutputFile.TextMode(true);
        OutputFile.WriteMode(true);
        OutputFile.Create(FileName);

        WriteHeader(OutputFile);
        WriteDimensions(OutputFile);
        WriteGLEntries(OutputFile);
        WriteDimensionValues(OutputFile);
        WriteGLAccounts(OutputFile);

        OutputFile.Close();
    end;

    local procedure WriteHeader(var OutputFile: File)
    begin
        OutputFile.Write(StrSubstNo(LegalEntityIDLineTok, FOLegalEntityID));
    end;

    local procedure WriteDimensions(var OutputFile: File)
    var
        Dimension: Record Dimension;
    begin
        if TempDimensionIDBuffer.FindSet() then
            repeat
                Dimension.Get(TempDimBuf."Dimension Code");
                OutputFile.Write(StrSubstNo(DimensionLineTok, Dimension.Name, TempDimensionIDBuffer.ID));
            until TempDimensionIDBuffer.Next() = 0;
    end;

    local procedure WriteDimensionValues(var OutputFile: File)
    begin
        if TempGLEntry.FindSet() then
            repeat
                TempDimBuf.SetRange("Entry No.", TempGLEntry."Entry No.");
                if TempDimBuf.FindSet() then
                    repeat
                        TempDimensionIDBuffer.get(0, TempDimBuf."Dimension Code", '');
                        OutputFile.Write(
                            StrSubstNo(
                                DimensionValueLineTok,
                                TempDimBuf."Dimension Value Code",
                                TempDimensionIDBuffer.ID,
                                TempGLEntry."Entry No."));
                    until TempDimBuf.Next() = 0;
            until TempGLEntry.Next() = 0;
    end;

    local procedure WriteGLEntries(var OutputFile: File)
    begin
        if TempGLEntry.FindSet() then
            repeat
                OutputFile.Write(
                    StrSubstNo(
                        GLEntryLineTok,
                        TempGLEntry."G/L Account No.",
                        FormatDate(TempGLEntry."Posting Date"),
                        GetFiscalPeriodType(),
                        CompanyCurrencyCode,
                        BooleanToInt(TempGLEntry."Debit Amount" <> 0),
                        GetPostingLayer(),
                        FormatDecimal(TempGLEntry.Amount),
                        FormatDecimal(TempGLEntry.Quantity),
                        TempGLEntry."Entry No."));
            until TempGLEntry.Next() = 0;
    end;

    local procedure WriteGLAccounts(var OutputFile: File)
    begin
        if TempGLAcc.FindSet() then
            repeat
                OutputFile.Write(
                    StrSubstNo(
                        GLAccountLineTok,
                        TempGLAcc."No.",
                        TempGLAcc.Name,
                        GetGLAccountType()));
            until TempGLAcc.Next() = 0;
    end;

    local procedure FormatDate(DateToFormat: Date): Text
    begin
        exit(Format(DateToFormat, 0, '<Year4>/<Month,2>/<Day,2>'));
    end;

    local procedure FormatDecimal(Amount: Decimal): Text
    begin
        exit(Format(Amount, 0, 9));
    end;

    local procedure GetFiscalPeriodType(): Integer
    begin
        exit(1);
    end;

    local procedure GetGLAccountType(): Integer
    begin
        exit(1);
    end;

    local procedure GetPostingLayer(): Integer
    begin
        exit(0);
    end;

    local procedure GetCompanyCurrencyCode(): Code[10]
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.TestField("LCY Code");
        exit(GLSetup."LCY Code");
    end;

    local procedure BooleanToInt(IsPositive: Boolean): Integer
    begin
        if IsPositive then
            exit(0);

        exit(1);
    end;
}
