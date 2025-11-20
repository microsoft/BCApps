// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Foundation.NoSeries;

table 750 "Standard General Journal"
{
    Caption = 'Standard General Journal';
    LookupPageID = "Standard General Journals";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            NotBlank = true;
            TableRelation = "Gen. Journal Template";
        }
        field(2; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        StdGenJnlLine: Record "Standard General Journal Line";
    begin
        StdGenJnlLine.SetRange("Journal Template Name", "Journal Template Name");
        StdGenJnlLine.SetRange("Standard Journal Code", Code);

        StdGenJnlLine.DeleteAll(true);
    end;

    var
        GenJnlBatch: Record "Gen. Journal Batch";
        LastGenJnlLine: Record "Gen. Journal Line";
        GenJnlLine: Record "Gen. Journal Line";
        Window: Dialog;
        WindowUpdateDateTime: DateTime;
        NoOfJournalsToBeCreated: Integer;
#pragma warning disable AA0074
        Text000: Label 'Getting Standard General Journal Lines @1@@@@@@@';
#pragma warning restore AA0074
        NoOfJournalsCreated: Integer;

    procedure CreateGenJnlFromStdJnl(StdGenJnl: Record "Standard General Journal"; JnlBatchName: Code[10])
    var
        DocumentNo: Code[20];
    begin
        if StdGenJnl.IsZeroAmountJournal() then
            DocumentNo := TryGetNextDocumentNo(StdGenJnl."Journal Template Name", JnlBatchName);

        CreateGenJnl(StdGenJnl, JnlBatchName, DocumentNo, 0D);
    end;

    procedure CreateGenJnlFromStdJnlWithDocNo(StdGenJnl: Record "Standard General Journal"; JnlBatchName: Code[10]; DocumentNo: Code[20]; PostingDate: Date)
    begin
        if DocumentNo = '' then
            CreateGenJnl(StdGenJnl, JnlBatchName, '', PostingDate)
        else
            CreateGenJnl(StdGenJnl, JnlBatchName, DocumentNo, PostingDate);
    end;

    procedure Initialize(var StdGenJnl: Record "Standard General Journal"; JnlBatchName: Code[10])
    begin
        GenJnlLine."Journal Template Name" := StdGenJnl."Journal Template Name";
        GenJnlLine."Journal Batch Name" := JnlBatchName;
        GenJnlLine.SetRange("Journal Template Name", StdGenJnl."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", JnlBatchName);

        LastGenJnlLine.SetRange("Journal Template Name", StdGenJnl."Journal Template Name");
        LastGenJnlLine.SetRange("Journal Batch Name", JnlBatchName);

        if LastGenJnlLine.FindLast() then;

        GenJnlBatch.SetRange("Journal Template Name", StdGenJnl."Journal Template Name");
        GenJnlBatch.SetRange(Name, JnlBatchName);

        if GenJnlBatch.FindFirst() then;
    end;

    local procedure CopyGenJnlFromStdJnl(StdGenJnlLine: Record "Standard General Journal Line"; DocumentNo: Code[20]; PostingDate: date)
    var
        GenJnlManagement: Codeunit GenJnlManagement;
        Balance: Decimal;
        TotalBalance: Decimal;
        ShowBalance: Boolean;
        ShowTotalBalance: Boolean;
    begin
        GenJnlLine.Init();
        GenJnlLine."Line No." := 0;
        GenJnlManagement.CalcBalance(GenJnlLine, LastGenJnlLine, Balance, TotalBalance, ShowBalance, ShowTotalBalance);
        GenJnlLine.SetUpNewLine(LastGenJnlLine, Balance, true);
        if LastGenJnlLine."Line No." <> 0 then
            GenJnlLine."Line No." := LastGenJnlLine."Line No." + 10000
        else
            GenJnlLine."Line No." := 10000;

        OnCopyGenJnlFromStdJnlOnBeforeGenJnlLineTransferFields(GenJnlLine, StdGenJnlLine);
        GenJnlLine.TransferFields(StdGenJnlLine, false);
        if (GenJnlLine."Account Type" <> GenJnlLine."Account Type"::"G/L Account") and (GenJnlLine."Account No." <> '') then
            GenJnlLine.Validate("Account No.");
        if (GenJnlLine."Bal. Account Type" <> GenJnlLine."Bal. Account Type"::"G/L Account") and (GenJnlLine."Bal. Account No." <> '') then
            GenJnlLine.Validate("Bal. Account No.");
        GenJnlLine.UpdateLineBalance();
        GenJnlLine."Currency Factor" := 0;
        GenJnlLine.Validate("Currency Code");

        if GenJnlLine."VAT Prod. Posting Group" <> '' then
            GenJnlLine.Validate("VAT Prod. Posting Group");
        if (GenJnlLine."VAT %" <> 0) and GenJnlBatch."Allow VAT Difference" then
            GenJnlLine.Validate("VAT Amount", StdGenJnlLine."VAT Amount");
        GenJnlLine.Validate("Bal. VAT Prod. Posting Group");
        GenJnlLine."Shortcut Dimension 1 Code" := StdGenJnlLine."Shortcut Dimension 1 Code";
        GenJnlLine."Shortcut Dimension 2 Code" := StdGenJnlLine."Shortcut Dimension 2 Code";
        GenJnlLine."Dimension Set ID" := StdGenJnlLine."Dimension Set ID";
        if GenJnlBatch."Allow VAT Difference" then
            GenJnlLine.Validate("Bal. VAT Amount", StdGenJnlLine."Bal. VAT Amount");
        if DocumentNo <> '' then
            GenJnlLine."Document No." := DocumentNo;
        if PostingDate <> 0D then
            GenJnlLine.Validate("Posting Date", PostingDate);
        GenJnlLine.Validate("Currency Code", StdGenJnlLine."Currency Code");
        OnAfterCopyGenJnlFromStdJnl(GenJnlLine, StdGenJnlLine);
        GenJnlLine.Insert(true);

        OnCopyGenJnlFromStdJnlOnAfterInsertGenJnlLineFrmStandard(GenJnlLine, StdGenJnlLine);

        LastGenJnlLine := GenJnlLine;
    end;

    local procedure CreateGenJnl(StdGenJnl: Record "Standard General Journal"; JnlBatchName: Code[10]; DocumentNo: Code[20]; PostingDate: Date)
    var
        StdGenJnlLine: Record "Standard General Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateGenJnl(StdGenJnl, JnlBatchName, DocumentNo, PostingDate, IsHandled);
        if IsHandled then
            exit;

        Initialize(StdGenJnl, JnlBatchName);

        StdGenJnlLine.SetRange("Journal Template Name", StdGenJnl."Journal Template Name");
        StdGenJnlLine.SetRange("Standard Journal Code", StdGenJnl.Code);
        OpenWindow(Text000, StdGenJnlLine.Count);
        if StdGenJnlLine.Find('-') then
            repeat
                UpdateWindow();
                OnCreateGenJnlOnBeforeCopyGenJnlFromStdJnl(StdGenJnl, StdGenJnlLine);
                CopyGenJnlFromStdJnl(StdGenJnlLine, DocumentNo, PostingDate);
            until StdGenJnlLine.Next() = 0;
    end;

    [Scope('OnPrem')]
    procedure IsZeroAmountJournal(): Boolean
    var
        StandardGeneralJournalLine: Record "Standard General Journal Line";
    begin
        StandardGeneralJournalLine.SetRange("Journal Template Name", "Journal Template Name");
        StandardGeneralJournalLine.SetRange("Standard Journal Code", Code);
        StandardGeneralJournalLine.CalcSums("Debit Amount", "Credit Amount");
        exit((StandardGeneralJournalLine."Debit Amount" = 0) and (StandardGeneralJournalLine."Credit Amount" = 0));
    end;

    local procedure TryGetNextDocumentNo(TemplateName: Code[10]; BatchName: Code[10]): Code[20]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        NoSeries: Codeunit "No. Series";
    begin
        GenJournalBatch.Get(TemplateName, BatchName);
        if GenJournalBatch."No. Series" = '' then
            exit('');

        exit(NoSeries.PeekNextNo(GenJournalBatch."No. Series"));
    end;

    local procedure OpenWindow(DisplayText: Text[250]; NoOfJournalsToBeCreated2: Integer)
    begin
        NoOfJournalsCreated := 0;
        NoOfJournalsToBeCreated := NoOfJournalsToBeCreated2;
        WindowUpdateDateTime := CurrentDateTime;
        Window.Open(DisplayText);
    end;

    local procedure UpdateWindow()
    begin
        NoOfJournalsCreated := NoOfJournalsCreated + 1;
        if CurrentDateTime - WindowUpdateDateTime >= 300 then begin
            WindowUpdateDateTime := CurrentDateTime;
            Window.Update(1, Round(NoOfJournalsCreated / NoOfJournalsToBeCreated * 10000, 1));
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyGenJnlFromStdJnl(var GenJournalLine: Record "Gen. Journal Line"; StdGenJournalLine: Record "Standard General Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyGenJnlFromStdJnlOnBeforeGenJnlLineTransferFields(var GenJournalLine: Record "Gen. Journal Line"; var StdGenJournalLine: Record "Standard General Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyGenJnlFromStdJnlOnAfterInsertGenJnlLineFrmStandard(var GenJournalLine: Record "Gen. Journal Line"; StdGenJournalLine: Record "Standard General Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateGenJnlOnBeforeCopyGenJnlFromStdJnl(var StandardGeneralJournal: Record "Standard General Journal"; var StandardGeneralJournalLine: Record "Standard General Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateGenJnl(var StandardGeneralJournal: Record "Standard General Journal"; var JnlBatchName: Code[10]; var DocumentNo: Code[20]; var PostingDate: Date; var IsHandled: Boolean)
    begin
    end;
}

