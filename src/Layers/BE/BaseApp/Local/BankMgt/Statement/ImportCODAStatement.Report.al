// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.CODA;

using Microsoft.Bank.BankAccount;
using System.IO;

report 2000030 "Import CODA Statement"
{
    Caption = 'Import CODA Statement';
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        while TxtFile.Pos < TxtFile.Len do begin
            CodBankStmtSrcLine.Init();
            CodBankStmtSrcLine."Bank Account No." := BankAccNo;
            CodBankStmtSrcLine."Statement No." := TempStatementNo;
            LineNo := LineNo + 1;
            CodBankStmtSrcLine."Line No." := LineNo;

            TxtFile.Read(Text);
            CodBankStmtSrcLine.Data := Text;
            PutRecordInDatabase();
        end;
    end;

    trigger OnPreReport()
    begin
        CodaMgmt.InitCodaImport(BankAccNo);
        FirstTime := true;
        InLines := false;
        if CodBankStmtSrcLine.FindLast() then
            TempStatementNo := IncStr(CodBankStmtSrcLine."Statement No.");
        if TempStatementNo = '' then
            TempStatementNo := CopyStr(BankAccNo, 1, 18) + '/1';
        CodBankStmtSrcLine.Reset();

        if FileName = '' then
            FileName := FileMgt.UploadFile('', '*.txt');

        Clear(TxtFile);
        TxtFile.TextMode := true;
        TxtFile.Open(FileName);
    end;

    var
        CodBankStmtSrcLine2: Record "CODA Statement Source Line";
        CodBankStmtSrcLine: Record "CODA Statement Source Line";
        CodaMgmt: Codeunit "Coda Import Management";
        FileMgt: Codeunit "File Management";
        TxtFile: File;
        BankAccNo: Code[20];
        TempStatementNo: Code[20];
        LineNo: Integer;
        FirstTime: Boolean;
        InLines: Boolean;
        VersionCode: Text[1];
        AccountType: Text[1];
        Text000: Label 'Line is not valid\%1.';
        Text: Text[128];

    protected var
        FileName: Text;

    [Scope('OnPrem')]
    procedure SetBankAcc(var Bank: Record "Bank Account")
    begin
        BankAccNo := Bank."No.";
        VersionCode := Bank."Version Code";
    end;

    [Scope('OnPrem')]
    procedure PutRecordInDatabase()
    var
        i: Integer;
    begin
        if not Evaluate(i, CopyStr(CodBankStmtSrcLine.Data, 1, 1)) then begin
            if InLines then
                Error(Text000, CodBankStmtSrcLine.Data);

            CodaMgmt.SkipLine();
            exit;
        end;
        CodBankStmtSrcLine.ID := i;

        if not ((VersionCode = '2') and (CodBankStmtSrcLine.ID = CodBankStmtSrcLine.ID::"Free Message")) then
            CodaMgmt.UpdateLineCounter(CodBankStmtSrcLine);

        case CodBankStmtSrcLine.ID of
            CodBankStmtSrcLine.ID::Header:
                begin
                    CodaMgmt.CheckCodaHeader(CodBankStmtSrcLine);
                    CodBankStmtSrcLine.Insert();
                end;
            CodBankStmtSrcLine.ID::"Old Balance":
                begin
                    CodaMgmt.CheckOldBalance(CodBankStmtSrcLine);
                    if (FirstTime) and (CodBankStmtSrcLine."Statement No." <> TempStatementNo) then begin
                        TempStatementNo :=
                          CodaMgmt.UpdateStatementNo(CodBankStmtSrcLine, TempStatementNo, CodBankStmtSrcLine."Statement No.");
                        AccountType := CopyStr(CodBankStmtSrcLine.Data, 2, 1);
                        FirstTime := false
                    end else
                        TempStatementNo := CodBankStmtSrcLine."Statement No.";
                    CodBankStmtSrcLine.Insert();
                end;
            CodBankStmtSrcLine.ID::Movement, CodBankStmtSrcLine.ID::Information, CodBankStmtSrcLine.ID::"Free Message":
                begin
                    CodaMgmt.CheckCodaRecord(CodBankStmtSrcLine);
                    CodBankStmtSrcLine.Insert();
                end;
            CodBankStmtSrcLine.ID::"New Balance":
                begin
                    CodaMgmt.CheckNewBalance(CodBankStmtSrcLine, AccountType);
                    CodBankStmtSrcLine.Insert();
                end;
            CodBankStmtSrcLine.ID::Trailer:
                begin
                    CodaMgmt.CheckCodaTrailer(CodBankStmtSrcLine);
                    CodaMgmt.Success();

                    CodBankStmtSrcLine2.SetRange("Bank Account No.", BankAccNo);
                    CodBankStmtSrcLine2.SetRange("Statement No.", TempStatementNo);
                    REPORT.RunModal(REPORT::"Initialise CODA Stmt. Lines", false, false, CodBankStmtSrcLine2);
                    CodBankStmtSrcLine2.DeleteAll();
                    TempStatementNo := IncStr(TempStatementNo);
                    FirstTime := true;
                end;
        end;
    end;

    [Scope('OnPrem')]
    procedure InitializeRequest(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;
}

