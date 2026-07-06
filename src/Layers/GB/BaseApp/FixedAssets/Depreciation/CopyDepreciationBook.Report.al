// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Depreciation;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Setup;

report 5687 "Copy Depreciation Book"
{
    Caption = 'Copy Depreciation Book';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Fixed Asset"; "Fixed Asset")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "FA Class Code", "FA Subclass Code";

            trigger OnAfterGetRecord()
            begin
                Window.Update(1, "No.");
                if Inactive or Blocked then
                    CurrReport.Skip();
                if not FADeprBook.Get("No.", DeprBookCode) then
                    CurrReport.Skip();
                if not FADeprBook2.Get("No.", DeprBookCode2) then begin
                    FADeprBook2 := FADeprBook;
                    FADeprBook2."Depreciation Book Code" := DeprBookCode2;
                    if FADeprBook2."Depreciation Method" <> FADeprBook2."Depreciation Method"::"Straight-Line" then begin
                        DeprBook.Get(FADeprBook2."Depreciation Book Code");
                        if DeprBook."Use Accounting Period" then
                            Error(MustBeStraightLineTxt, FADeprBook2.FieldCaption("Depreciation Method"), DeprBook.FieldCaption("Use Accounting Period"), true,
                              DeprBook.TableCaption(), DeprBook.Code);
                    end;
                    FADeprBook2.Insert(true);
                end;
                FALedgEntry.SetRange("FA No.", "No.");
                if FALedgEntry.Find('-') then
                    repeat
                        SetJournalType(FALedgEntry);
                        case JournalType of
                            JournalType::SkipType:
                                ;
                            JournalType::GenJnlType:
                                InsertGenJnlLine(FALedgEntry);
                            JournalType::FAJnlType:
                                InsertFAJnlLine(FALedgEntry);
                        end;
                    until FALedgEntry.Next() = 0;
            end;

            trigger OnPreDataItem()
            begin
                DepreciationCalc.SetFAFilter(FALedgEntry, '', DeprBookCode, false);
                FALedgEntry.SetRange("FA Posting Category", FALedgEntry."FA Posting Category"::" ");
                FALedgEntry.SetRange(
                  "FA Posting Type",
                  FALedgEntry."FA Posting Type"::"Acquisition Cost", FALedgEntry."FA Posting Type"::"Salvage Value");
                FALedgEntry.SetRange("FA Posting Date", StartingDate, EndingDate2);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(CopyFromBook; DeprBookCode)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Copy from Book';
                        TableRelation = "Depreciation Book";
                        ToolTip = 'Specifies the code of the depreciation book you want to copy from.';
                    }
                    field(CopyToBook; DeprBookCode2)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Copy to Book';
                        TableRelation = "Depreciation Book";
                        ToolTip = 'Specifies the code of the depreciation book you want to copy to.';
                    }
                    field(StartingDate; StartingDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date when you want the report to start.';
                    }
                    field(EndingDate; EndingDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the date when you want the report to end.';
                    }
                    field(DocumentNo; DocumentNo)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies, if you leave the field empty, the next available number on the resulting journal line. If a number series is not set up, enter the document number that you want assigned to the resulting journal line.';
                    }
                    field(PostingDescription; PostingDescription)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Posting Description';
                        ToolTip = 'Specifies the posting date to be used by the batch job as a filter.';
                    }
                    field(InsertBalAccount; BalAccount)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Insert Bal. Account';
                        ToolTip = 'Specifies if you want the batch job to automatically insert fixed asset entries with balancing accounts.';
                    }
                    group(Copy)
                    {
                        Caption = 'Copy';
                        field("CopyChoices[1]"; CopyChoices[1])
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Acquisition Cost';
                            ToolTip = 'Specifies if related acquisition cost entries are included in the batch job .';
                        }
                        field("CopyChoices[2]"; CopyChoices[2])
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Depreciation';
                            ToolTip = 'Specifies if related depreciation entries are included in the batch job .';
                        }
                        field("CopyChoices[3]"; CopyChoices[3])
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Write-Down';
                            ToolTip = 'Specifies if related write-down entries are included in the batch job .';
                        }
                        field("CopyChoices[4]"; CopyChoices[4])
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Appreciation';
                            ToolTip = 'Specifies if related appreciation entries are included in the batch job .';
                        }
                        field("CopyChoices[5]"; CopyChoices[5])
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Custom 1';
                            ToolTip = 'Specifies if related custom 1 entries are included in the batch job .';
                        }
                        field("CopyChoices[6]"; CopyChoices[6])
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Custom 2';
                            ToolTip = 'Specifies if related custom 2 entries are included in the batch job .';
                        }
                        field("CopyChoices[9]"; CopyChoices[9])
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Salvage Value';
                            ToolTip = 'Specifies if related salvage value entries are included in the batch job .';
                        }
                        field("CopyChoices[7]"; CopyChoices[7])
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Disposal';
                            ToolTip = 'Specifies if related disposal entries are included in the batch job .';
                        }
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if DeprBookCode = '' then begin
                FASetup.Get();
                DeprBookCode := FASetup."Default Depr. Book";
            end;
        end;
    }

    labels
    {
    }

    trigger OnPreReport()
    begin
        if (EndingDate > 0D) and (StartingDate > EndingDate) then
            Error(Text000);
        if EndingDate = 0D then
            EndingDate2 := DMY2Date(31, 12, 9999)
        else
            EndingDate2 := EndingDate;
        DeprBook.Get(DeprBookCode);
        DeprBook2.Get(DeprBookCode2);
        ExchangeRate := GetExchangeRate();
        DeprBook2.IndexGLIntegration(GLIntegration);
        FirstGenJnl := true;
        FirstFAJnl := true;
        Window.Open(Text001);
    end;

    var
        GenJnlLine: Record "Gen. Journal Line";
        FASetup: Record "FA Setup";
        FAJnlLine: Record "FA Journal Line";
        FADeprBook: Record "FA Depreciation Book";
        FADeprBook2: Record "FA Depreciation Book";
        DeprBook: Record "Depreciation Book";
        DeprBook2: Record "Depreciation Book";
        FALedgEntry: Record "FA Ledger Entry";
        FAJnlSetup: Record "FA Journal Setup";
        DepreciationCalc: Codeunit "Depreciation Calculation";
        Window: Dialog;
        ExchangeRate: Decimal;
        CopyChoices: array[9] of Boolean;
        GLIntegration: array[9] of Boolean;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        DocumentNo3: Code[20];
        NoSeries2: Code[20];
        NoSeries3: Code[20];
        PostingDescription: Text[100];
        JournalType: Option SkipType,GenJnlType,FAJnlType;
        DeprBookCode: Code[10];
        DeprBookCode2: Code[10];
        BalAccount: Boolean;
        StartingDate: Date;
        EndingDate: Date;
        EndingDate2: Date;
        FirstGenJnl: Boolean;
        FirstFAJnl: Boolean;
        FAJnlNextLineNo: Integer;
        GenJnlNextLineNo: Integer;
        MustBeStraightLineTxt: Label '%1 must be Straight-Line if %2 is %3 in %4: %5.', Comment = '%1="Depreciation Method" Field Caption %2="Use Accounting Period" Field Caption %3="Use Accounting Period" Field Value %4="Depreciation Book" Table Caption %5="Depreciation Book" Value of field Code';

#pragma warning disable AA0074
        Text000: Label 'The Starting Date is later than the Ending Date.';
#pragma warning disable AA0470
        Text001: Label 'Copying fixed asset    #1##########';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure InsertGenJnlLine(var FALedgEntry: Record "FA Ledger Entry")
    var
        FAInsertGLAcc: Codeunit "FA Insert G/L Account";
    begin
        if FirstGenJnl then begin
            GenJnlLine.LockTable();
            FAJnlSetup.GenJnlName(DeprBook2, GenJnlLine, GenJnlNextLineNo);
            NoSeries2 := FAJnlSetup.GetGenNoSeries(GenJnlLine);
            if DocumentNo = '' then
                DocumentNo2 := FAJnlSetup.GetGenJnlDocumentNo(GenJnlLine, FALedgEntry."FA Posting Date", true)
            else
                DocumentNo2 := DocumentNo;
        end;
        FirstGenJnl := false;

        FALedgEntry.MoveToGenJnl(GenJnlLine);
        GenJnlLine.Validate("Depreciation Book Code", DeprBookCode2);
        GenJnlLine.Validate(Amount, Round(GenJnlLine.Amount * ExchangeRate));
        GenJnlLine."Document No." := DocumentNo2;
        GenJnlLine."Posting No. Series" := NoSeries2;
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
        GenJnlLine."External Document No." := '';
        if PostingDescription <> '' then
            GenJnlLine.Description := PostingDescription;
        GenJnlNextLineNo := GenJnlNextLineNo + 10000;
        GenJnlLine."Line No." := GenJnlNextLineNo;
        GenJnlLine.Insert(true);
        if BalAccount then begin
            FAInsertGLAcc.GetBalAcc(GenJnlLine);
            if GenJnlLine.FindLast() then;
            GenJnlNextLineNo := GenJnlLine."Line No.";
        end;
    end;

    local procedure InsertFAJnlLine(var FALedgEntry: Record "FA Ledger Entry")
    begin
        if FirstFAJnl then begin
            FAJnlLine.LockTable();
            FAJnlSetup.FAJnlName(DeprBook2, FAJnlLine, FAJnlNextLineNo);
            NoSeries3 := FAJnlSetup.GetFANoSeries(FAJnlLine);
            if DocumentNo = '' then
                DocumentNo3 := FAJnlSetup.GetFAJnlDocumentNo(FAJnlLine, FALedgEntry."FA Posting Date", true)
            else
                DocumentNo3 := DocumentNo;
        end;
        FirstFAJnl := false;

        FALedgEntry.MoveToFAJnl(FAJnlLine);
        FAJnlLine.Validate("Depreciation Book Code", DeprBookCode2);
        FAJnlLine.Validate(Amount, Round(FAJnlLine.Amount * ExchangeRate));
        FAJnlLine."Document No." := DocumentNo3;
        FAJnlLine."Posting No. Series" := NoSeries3;
        FAJnlLine."Document Type" := FAJnlLine."Document Type"::" ";
        FAJnlLine."External Document No." := '';
        if PostingDescription <> '' then
            FAJnlLine.Description := PostingDescription;
        FAJnlNextLineNo := FAJnlNextLineNo + 10000;
        FAJnlLine."Line No." := FAJnlNextLineNo;
        FAJnlLine.Insert(true);
    end;

    local procedure SetJournalType(var FALedgEntry: Record "FA Ledger Entry")
    var
        Index: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetJournalType("Fixed Asset", CopyChoices, FALedgEntry, JournalType, IsHandled);
        if IsHandled then
            exit;

        Index := FALedgEntry.ConvertPostingType() + 1;
        if CopyChoices[Index] then begin
            if GLIntegration[Index] and not "Fixed Asset"."Budgeted Asset" then
                JournalType := JournalType::GenJnlType
            else
                JournalType := JournalType::FAJnlType
        end else
            JournalType := JournalType::SkipType;
    end;

    local procedure GetExchangeRate(): Decimal
    var
        ExchangeRate2: Decimal;
        ExchangeRate3: Decimal;
    begin
        ExchangeRate2 := DeprBook."Default Exchange Rate";
        if ExchangeRate2 <= 0 then
            ExchangeRate2 := 100;
        if not DeprBook."Use FA Exch. Rate in Duplic." then
            ExchangeRate2 := 100;

        ExchangeRate3 := DeprBook2."Default Exchange Rate";
        if ExchangeRate3 <= 0 then
            ExchangeRate3 := 100;
        if not DeprBook2."Use FA Exch. Rate in Duplic." then
            ExchangeRate3 := 100;

        exit(ExchangeRate2 / ExchangeRate3);
    end;

    procedure InitializeRequest(DeprBookCodeFrom: Code[10]; DeprBookCode2From: Code[10]; StartingDateFrom: Date; EndingDateFrom: Date; DocumentNoFrom: Code[20]; PostingDescriptionFrom: Text[100]; BalAccountFrom: Boolean)
    begin
        DeprBookCode := DeprBookCodeFrom;
        DeprBookCode2 := DeprBookCode2From;
        StartingDate := StartingDateFrom;
        EndingDate := EndingDateFrom;
        DocumentNo := DocumentNoFrom;
        PostingDescription := PostingDescriptionFrom;
        BalAccount := BalAccountFrom;
    end;

    procedure SetCopyAcquisitionCost(Choice: Boolean)
    begin
        CopyChoices[1] := Choice;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetJournalType(FixedAsset: Record "Fixed Asset"; CopyChoices: array[9] of Boolean; var FALedgerEntry: Record "FA Ledger Entry"; var JournalType: Option; var IsHandled: Boolean)
    begin
    end;
}

