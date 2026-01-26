// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Bank.Reports;

using Microsoft.Bank.BankAccount;
using Microsoft.Bank.Payment;
using Microsoft.Bank.Setup;
using System.IO;
using System.Utilities;

report 32000000 "Import Ref. Payment"
{
    Caption = 'Import Ref. Payment';
    ProcessingOnly = true;

    dataset
    {
        dataitem(BankPayments; "Ref. Payment - Imported")
        {
            DataItemTableView = sorting("No.") order(ascending);

            trigger OnPostDataItem()
            var
                FileMgt: Codeunit "File Management";
                ServerTempFileName: Text;
                DownloadToFileName: Text;
            begin
                BackUp := '.000';
                DownloadToFileName := FileMgt.GetFileName(FileName) + BackUp;

                ServerTempFileName := FileMgt.ServerTempFileName('');
                FileMgt.BLOBExportToServerFile(TempBlob, ServerTempFileName);
                FileMgt.DownloadHandler(ServerTempFileName, '', '', '', DownloadToFileName);

                MatchPayments.MatchLines(TemplateName, BatchName);
            end;

            trigger OnPreDataItem()
            var
                FileMgt: Codeunit "File Management";
                FileInStream: InStream;
                Year: Integer;
                Month: Integer;
                Day: Integer;
                Line: Text;
            begin
                if FindSet() then
                    repeat
                        RefPmtImportTemp := BankPayments;
                        RefPmtImportTemp.Insert();
                    until Next() = 0;
                MatchPayments.GetRefPmtImportTemp(RefPmtImportTemp);
                if BankAccCode = '' then
                    Error(Text1090000);
                FileSetup.SetFilter("No.", BankAccCode);
                if not FileSetup.FindFirst() then
                    Error(Text1090002, BankAccCode);

                if FileName = '' then begin
                    FileName := FileMgt.UploadFile(OpenRefFileTxt, '');
                    if FileName = '' then
                        CurrReport.Quit();
                end;

                if RefPmtImport.FindLast() then begin
                    LineNo := RefPmtImport."No." + 1;
                    BatchNo := RefPmtImport."Batch No." + 1;
                end;

                FileMgt.BLOBImportFromServerFile(TempBlob, FileName);
                if not TempBlob.HasValue() then
                    exit;
                TempBlob.CreateInStream(FileInStream);

                while not FileInStream.EOS() do begin
                    FileInStream.ReadText(Line);
                    LineCode := CopyStr(Line, 1, 1);

                    if LineCode = '0' then begin
                        CheckAccount := true;
                        Init();
                        "No." := LineNo;
                        "Record ID" := 0;
                        "Filing Code" := '';
                        "Reference No." := '';
                        "Bank Code" := CopyStr(Line, 12, 2);
                        "Agent Code" := CopyStr(Line, 14, 9);
                        "Currency Code" := CopyStr(Line, 23, 1);
                        "Account Owner Code" := CopyStr(Line, 24, 9);
                        "Bank Account Code" := '';
                        "Batch No." := BatchNo;
                        Insert();
                        LineNo := LineNo + 1;
                    end
                    else
                        if (LineCode = '3') or (LineCode = '5') then begin
                            LineAccountNo := CopyStr(Line, 2, 14);
                            if CheckAccount then
                                BankAccCode := SelectBankAccount(LineAccountNo);

                            LineReference := CopyStr(Line, 44, 20);
                            ClearReferenceZeros(LineReference);

                            Evaluate(Day, CopyStr(Line, 20, 2));
                            Evaluate(Month, CopyStr(Line, 18, 2));
                            Evaluate(Year, CopyStr(Line, 16, 2));
                            LinePostingDate := DMY2Date(Day, Month, 2000 + Year);

                            Evaluate(Day, CopyStr(Line, 26, 2));
                            Evaluate(Month, CopyStr(Line, 24, 2));
                            Evaluate(Year, CopyStr(Line, 22, 2));
                            LinePaymentDate := DMY2Date(Day, Month, 2000 + Year);

                            Evaluate(LineAmount, CopyStr(Line, 78, 10));

                            "No." := LineNo;
                            Init();
                            case LineCode of
                                '3':
                                    "Record ID" := 3;
                                '5':
                                    "Record ID" := 5;
                            end;
                            "Account No." := LineAccountNo;
                            "Banks Posting Date" := LinePostingDate;
                            "Banks Payment Date" := LinePaymentDate;
                            "Filing Code" := CopyStr(Line, 28, 16);
                            "Reference No." := LineReference;
                            "Payers Name" := CopyStr(Line, 64, 12);
                            "Currency Code 2" := CopyStr(Line, 76, 1);
                            "Name Source" := CopyStr(Line, 77, 1);
                            "Correction Code" := CopyStr(Line, 88, 1);
                            "Delivery Method" := CopyStr(Line, 89, 1);
                            "Feedback Code" := CopyStr(Line, 90, 1);
                            Amount := LineAmount / 100;
                            "Bank Account Code" := BankAccCode;
                            "Batch No." := BatchNo;
                            Insert();
                            LineNo := LineNo + 1;
                        end
                        else
                            if LineCode = '9' then begin
                                Evaluate(LineAmountAll, CopyStr(Line, 8, 11));
                                Evaluate(LineAmountCor, CopyStr(Line, 25, 11));
                                Evaluate(LineAmountFaild, CopyStr(Line, 42, 11));

                                Init();
                                "No." := LineNo;
                                "Record ID" := 9;
                                "Filing Code" := '';
                                "Reference No." := '';
                                "Bank Account Code" := '';
                                "Transaction Qty." := CopyStr(Line, 2, 6);
                                "Corrections Qty." := CopyStr(Line, 19, 6);
                                "Failed Direct Debiting Qty." := CopyStr(Line, 36, 6);
                                "Payments Qty." := LineAmountAll / 100;
                                "Corrections Amount" := LineAmountCor / 100;
                                "Failed Direct Debiting Amount" := LineAmountFaild / 100;
                                "Batch No." := BatchNo;
                                Insert();
                                LineNo := LineNo + 1;
                                BatchNo := BatchNo + 1;
                            end;
                end;
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(BankAccCode; BankAccCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Bank Account';
                        TableRelation = "Bank Account"."No.";
                        ToolTip = 'Specifies the bank account from which to get material. If the transfer file contains material from several bank accounts, all transactions for all accounts in that bank are imported.';
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    var
        BankAccount: Record "Bank Account";
        FileSetup: Record "Reference File Setup";
        RefPmtImport: Record "Ref. Payment - Imported";
        RefPmtImportTemp: Record "Ref. Payment - Imported" temporary;
        TempBlob: Codeunit "Temp Blob";
        BankAccFormat: Codeunit "Bank Nos Check";
        MatchPayments: Codeunit "Ref. Payment Management";
        LineAmount: Integer;
        LineAmountAll: Integer;
        LineAmountFaild: Integer;
        LineAmountCor: Integer;
        LineCode: Text[1];
        LineAccountNo: Text[15];
        LinePostingDate: Date;
        LinePaymentDate: Date;
        LineReference: Text[20];
        RefCounter: Integer;
        RefStartPos: Integer;
        BankAccCode: Code[20];
        Text1090000: Label 'Select Bank Account Code.';
        Text1090002: Label 'Set Transfer File settings for Bank Account %1.';
        CheckAccount: Boolean;
        BackUp: Code[10];
        BatchName: Code[20];
        TemplateName: Code[20];
        LineNo: Integer;
        BatchNo: Integer;
        FileName: Text;
        OpenRefFileTxt: Label 'Open reference file';

    [Scope('OnPrem')]
    procedure SelectBankAccount(LineBankAcctNo: Text[15]) AccountCode: Code[10]
    begin
        Clear(AccountCode);
        BankAccount.Reset();
        BankAccount.SetFilter("Bank Account No.", '<>%1', '');
        CheckAccount := false;
        if BankAccount.FindSet() then
            repeat
                BankAccFormat.ConvertBankAcc(BankAccount."Bank Account No.", BankAccount."No.");
                if LineBankAcctNo = BankAccount."Bank Account No." then
                    AccountCode := BankAccount."No.";
            until BankAccount.Next() = 0;
    end;

    procedure ClearReferenceZeros(var ReferenceNum: Text[20])
    begin
        RefCounter := 1;
        repeat
            if CopyStr(ReferenceNum, RefCounter, 1) <> '0' then begin
                RefStartPos := RefCounter;
                RefCounter := 19;
            end;
            RefCounter := RefCounter + 1;
        until RefCounter = 20;
        ReferenceNum := CopyStr(ReferenceNum, RefStartPos);
    end;

    [Scope('OnPrem')]
    procedure SetLedgerNames(Batch: Code[20]; Template: Code[20])
    begin
        BatchName := Batch;
        TemplateName := Template;
    end;

    procedure InitializeRequest(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;
}

