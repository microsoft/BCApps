// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.FixedAssets.Ledger;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.FixedAssets.Depreciation;
using Microsoft.FixedAssets.FixedAsset;
using Microsoft.FixedAssets.Journal;
using Microsoft.FixedAssets.Setup;

report 5688 "Cancel FA Ledger Entries"
{
    Caption = 'Cancel FA Ledger Entries';
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
                FALedgEntry.SetRange("FA No.", "No.");
                if FALedgEntry.Find('+') then
                    repeat
                        SetJournalType(FALedgEntry);
                        if NewPostingDate > 0D then
                            FALedgEntry."Posting Date" := NewPostingDate;
                        case JournalType of
                            JournalType::SkipType:
                                ;
                            JournalType::GenJnlType:
                                InsertGenJnlLine(FALedgEntry);
                            JournalType::FAJnlType:
                                InsertFAJnlLine(FALedgEntry);
                        end;
                    until FALedgEntry.Next(-1) = 0;
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
                    field(CancelBook; DeprBookCode)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Cancel Book';
                        TableRelation = "Depreciation Book";
                        ToolTip = 'Specifies the depreciation book where entries will be removed by the batch job.';
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
                    field(UseNewPostingDate; UseNewPostingDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Use New Posting Date';
                        ToolTip = 'Specifies that a new posting date is applied to the journal entries created by the batch job. If the field is cleared, the posting date of the fixed asset ledger entries to be canceled is copied to the journal entries that the batch job creates.';
                    }
                    field(NewPostingDate; NewPostingDate)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'New Posting Date';
                        ToolTip = 'Specifies the posting date to be applied to the journal entries created by the batch job when the Use New Posting Date field is selected.';
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
                    field(BalAccount; BalAccount)
                    {
                        ApplicationArea = FixedAssets;
                        Caption = 'Insert Bal. Account';
                        ToolTip = 'Specifies if you want the batch job to automatically insert fixed asset entries with balancing accounts.';
                    }
                    group(Cancel)
                    {
                        Caption = 'Cancel';
                        field("CancelChoices[1]"; CancelChoices[1])
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Acquisition Cost';
                            ToolTip = 'Specifies if related acquisition cost entries are included in the batch job .';
                        }
                        field("CancelChoices[2]"; CancelChoices[2])
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Depreciation';
                            ToolTip = 'Specifies if related depreciation entries are included in the batch job .';
                        }
                        field("CancelChoices[3]"; CancelChoices[3])
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Write-Down';
                            ToolTip = 'Specifies if related write-down entries are included in the batch job .';
                        }
                        field("CancelChoices[4]"; CancelChoices[4])
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Appreciation';
                            ToolTip = 'Specifies if related appreciation entries are included in the batch job .';
                        }
                        field("CancelChoices[5]"; CancelChoices[5])
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Custom 1';
                            ToolTip = 'Specifies if related custom 1 entries are included in the batch job .';
                        }
                        field("CancelChoices[6]"; CancelChoices[6])
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Custom 2';
                            ToolTip = 'Specifies if related custom 2 entries are included in the batch job .';
                        }
                        field("CancelChoices[9]"; CancelChoices[9])
                        {
                            ApplicationArea = FixedAssets;
                            Caption = 'Salvage Value';
                            ToolTip = 'Specifies if related salvage value entries are included in the batch job .';
                        }
                        field(Disposal; CancelChoices[7])
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
        if UseNewPostingDate then
            if NewPostingDate = 0D then
                Error(Text002);
        if not UseNewPostingDate then
            if NewPostingDate > 0D then
                Error(Text003);
        if NewPostingDate > 0D then
            if NormalDate(NewPostingDate) <> NewPostingDate then
                Error(Text004);

        if EndingDate = 0D then
            EndingDate2 := DMY2Date(31, 12, 9999)
        else
            EndingDate2 := EndingDate;
        DeprBook.Get(DeprBookCode);
        if UseNewPostingDate then
            DeprBook.TestField("Use Same FA+G/L Posting Dates", false);
        DeprBook.IndexGLIntegration(GLIntegration);
        FirstGenJnl := true;
        FirstFAJnl := true;
        Window.Open(Text001);
    end;

    var
        GenJnlLine: Record "Gen. Journal Line";
        FASetup: Record "FA Setup";
        FAJnlLine: Record "FA Journal Line";
        FADeprBook: Record "FA Depreciation Book";
        DeprBook: Record "Depreciation Book";
        FAJnlSetup: Record "FA Journal Setup";
        DepreciationCalc: Codeunit "Depreciation Calculation";
        Window: Dialog;
        CancelChoices: array[9] of Boolean;
        GLIntegration: array[9] of Boolean;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        DocumentNo3: Code[20];
        NoSeries2: Code[20];
        NoSeries3: Code[20];
        PostingDescription: Text[100];
        JournalType: Option SkipType,GenJnlType,FAJnlType;
        DeprBookCode: Code[10];
        BalAccount: Boolean;
        StartingDate: Date;
        EndingDate: Date;
        EndingDate2: Date;
        FirstGenJnl: Boolean;
        FirstFAJnl: Boolean;
        FAJnlNextLineNo: Integer;
        GenJnlNextLineNo: Integer;
        UseNewPostingDate: Boolean;
        NewPostingDate: Date;

#pragma warning disable AA0074
        Text000: Label 'The Starting Date is later than the Ending Date.';
#pragma warning disable AA0470
        Text001: Label 'Canceling fixed asset    #1##########';
#pragma warning restore AA0470
        Text002: Label 'You must specify New Posting Date.';
        Text003: Label 'You must not specify New Posting Date.';
        Text004: Label 'You must not specify a closing date.';
#pragma warning restore AA0074

    protected var
        FALedgEntry: Record "FA Ledger Entry";

    local procedure InsertGenJnlLine(var FALedgEntry: Record "FA Ledger Entry")
    var
        FAInsertGLAcc: Codeunit "FA Insert G/L Account";
    begin
        if FirstGenJnl then begin
            GenJnlLine.LockTable();
            FAJnlSetup.GenJnlName(DeprBook, GenJnlLine, GenJnlNextLineNo);
            NoSeries2 := FAJnlSetup.GetGenNoSeries(GenJnlLine);
            if DocumentNo = '' then
                DocumentNo2 := FAJnlSetup.GetGenJnlDocumentNo(GenJnlLine, GetPostingDate(FALedgEntry."FA Posting Date"), true)
            else
                DocumentNo2 := DocumentNo;
        end;
        FirstGenJnl := false;

        FALedgEntry.MoveToGenJnl(GenJnlLine);
        GenJnlLine."Shortcut Dimension 1 Code" := FALedgEntry."Global Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := FALedgEntry."Global Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := FALedgEntry."Dimension Set ID";
        GenJnlLine.Validate("Depreciation Book Code", DeprBookCode);
        GenJnlLine.Validate(Amount, -GenJnlLine.Amount);
        GenJnlLine."FA Error Entry No." := FALedgEntry."Entry No.";
        GenJnlLine.Validate(Correction, DeprBook."Mark Errors as Corrections");
        GenJnlLine."Document No." := DocumentNo2;
        GenJnlLine."Posting No. Series" := NoSeries2;
        GenJnlLine."Document Type" := GenJnlLine."Document Type"::" ";
        GenJnlLine."External Document No." := '';
        if PostingDescription <> '' then
            GenJnlLine.Description := PostingDescription;
        GenJnlNextLineNo := GenJnlNextLineNo + 10000;
        GenJnlLine."Line No." := GenJnlNextLineNo;
        OnInsertGenJnlLineOnBeforeInsert(GenJnlLine, FALedgEntry, BalAccount);
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
            FAJnlSetup.FAJnlName(DeprBook, FAJnlLine, FAJnlNextLineNo);
            NoSeries3 := FAJnlSetup.GetFANoSeries(FAJnlLine);
            if DocumentNo = '' then
                DocumentNo3 := FAJnlSetup.GetFAJnlDocumentNo(FAJnlLine, GetPostingDate(FALedgEntry."FA Posting Date"), true)
            else
                DocumentNo3 := DocumentNo;
        end;
        FirstFAJnl := false;

        FALedgEntry.MoveToFAJnl(FAJnlLine);
        FAJnlLine."Shortcut Dimension 1 Code" := FALedgEntry."Global Dimension 1 Code";
        FAJnlLine."Shortcut Dimension 2 Code" := FALedgEntry."Global Dimension 2 Code";
        FAJnlLine."Dimension Set ID" := FALedgEntry."Dimension Set ID";
        FAJnlLine.Validate("Depreciation Book Code", DeprBookCode);
        FAJnlLine.Validate(Amount, -FAJnlLine.Amount);
        FAJnlLine."FA Error Entry No." := FALedgEntry."Entry No.";
        FAJnlLine.Validate(Correction, DeprBook."Mark Errors as Corrections");
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
    begin
        Index := FALedgEntry.ConvertPostingType() + 1;
        if CancelChoices[Index] then begin
            if GLIntegration[Index] and not "Fixed Asset"."Budgeted Asset" then
                JournalType := JournalType::GenJnlType
            else
                JournalType := JournalType::FAJnlType
        end else
            JournalType := JournalType::SkipType;
        OnAfterSetJournalType(FALedgEntry, CancelChoices, "Fixed Asset", DeprBookCode, JournalType);
    end;

    procedure InitializeRequest(DeprBookCodeFrom: Code[10]; StartingDateFrom: Date; EndingDateFrom: Date; UseNewPostingDateFrom: Boolean; NewPostingDateFrom: Date; DocumentNoFrom: Code[20]; PostingDescriptionFrom: Text[100]; BalAccountFrom: Boolean)
    begin
        DeprBookCode := DeprBookCodeFrom;
        StartingDate := StartingDateFrom;
        EndingDate := EndingDateFrom;
        UseNewPostingDate := UseNewPostingDateFrom;
        NewPostingDate := NewPostingDateFrom;
        DocumentNo := DocumentNoFrom;
        PostingDescription := PostingDescriptionFrom;
        BalAccount := BalAccountFrom;
    end;

    procedure SetCancelDepreciation(Choice: Boolean)
    begin
        CancelChoices[2] := Choice;
    end;

    procedure SetCancelAcquisitionCost(Choice: Boolean)
    begin
        CancelChoices[1] := Choice;
    end;

    local procedure GetPostingDate(FAPostingDate: Date): Date
    begin
        if NewPostingDate <> 0D then
            exit(NewPostingDate);
        exit(FAPostingDate);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterSetJournalType(FALedgerEntry: Record "FA Ledger Entry"; CancelChoices: array[9] of Boolean; "Fixed Asset": Record "Fixed Asset"; DeprBookCode: Code[10]; var JournalType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertGenJnlLineOnBeforeInsert(var GenJnlLine: Record "Gen. Journal Line"; FALedgEntry: Record "FA Ledger Entry"; var BalAccount: Boolean)
    begin
    end;
}

