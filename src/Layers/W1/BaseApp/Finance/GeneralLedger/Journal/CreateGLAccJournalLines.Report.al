// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Finance.GeneralLedger.Account;

report 8610 "Create G/L Acc. Journal Lines"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Create G/L Account Journal Lines';
    ProcessingOnly = true;
    UsageCategory = Tasks;

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Account Type", Blocked, "Direct Posting", "No. 2";

            trigger OnAfterGetRecord()
            var
                StdGenJournalLine: Record "Standard General Journal Line";
            begin
                GenJnlLine.Init();
                if GetStandardJournalLine() then begin
                    Initialize(StdGenJournal, GenJnlBatch.Name);

                    StdGenJournalLine.SetRange("Journal Template Name", StdGenJournal."Journal Template Name");
                    StdGenJournalLine.SetRange("Standard Journal Code", StdGenJournal.Code);
                    if StdGenJournalLine.FindSet() then
                        repeat
                            CopyGenJnlFromStdJnl(StdGenJournalLine, GenJnlLine);
                            GenJnlLine.Validate("Document Type", DocumentTypes);
                            GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"G/L Account");
                            GenJnlLine.Validate("Account No.", "No.");
                            GenJnlLine.Validate("Bal. Account No.", GenJnlBatch."Bal. Account No.");
                            if PostingDate <> 0D then
                                GenJnlLine.Validate("Posting Date", PostingDate);
                            GenJnlLine.Modify(true);
                        until StdGenJournalLine.Next() = 0;
                end else begin
                    GenJnlLine.Validate("Journal Template Name", JournalTemplate);
                    GenJnlLine.Validate("Journal Batch Name", BatchName);
                    GenJnlLine."Line No." := LineNo;
                    GenJnlLine.SetUpNewLine(LastGenJnlLine, 0, true);
                    LineNo := LineNo + 10000;

                    GenJnlLine.Validate("Document Type", DocumentTypes);
                    if (GenJnlLine."Document No." = '') and (DocumentNo <> '') then
                        GenJnlLine.Validate("Document No.", DocumentNo);
                    GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::"G/L Account");
                    GenJnlLine.Validate("Account No.", "No.");
                    GenJnlLine.Validate("Bal. Account No.", GenJnlBatch."Bal. Account No.");

                    if PostingDate <> 0D then
                        GenJnlLine.Validate("Posting Date", PostingDate);

                    if not GenJnlLine.Insert(true) then
                        GenJnlLine.Modify(true);
                end;
            end;

            trigger OnPreDataItem()
            begin
                CheckJournalTemplate();
                CheckBatchName();
                CheckPostingDate();

                GenJnlLine.SetRange("Journal Template Name", JournalTemplate);
                GenJnlLine.SetRange("Journal Batch Name", BatchName);
                if GenJnlLine.FindLast() then
                    LineNo := GenJnlLine."Line No." + 10000
                else
                    LineNo := 10000;

                GenJnlBatch.Get(JournalTemplate, BatchName);
                if TemplateCode <> '' then
                    StdGenJournal.Get(JournalTemplate, TemplateCode);
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
                    field(DocumentTypes; DocumentTypes)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document Type';
                        ToolTip = 'Specifies the document type of the journal line.';
                    }
                    field(DocumentNo; DocumentNo)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Document No.';
                        ToolTip = 'Specifies the default document number of the journal line.';
                    }
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Posting Date';
                        ToolTip = 'Specifies the posting date of the journal line.';

                        trigger OnValidate()
                        begin
                            CheckPostingDate();
                        end;
                    }
                    field(JournalTemplate; JournalTemplate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Journal Template';
                        TableRelation = "Gen. Journal Template".Name;
                        ToolTip = 'Specifies the name of journal to which the lines will be added.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            GenJnlTemplate: Record "Gen. Journal Template";
                            GenJnlTemplates: Page "General Journal Templates";
                        begin
                            GenJnlTemplate.SetRange(Type, GenJnlTemplate.Type::General);
                            GenJnlTemplate.SetRange(Recurring, false);
                            GenJnlTemplates.SetTableView(GenJnlTemplate);

                            GenJnlTemplates.LookupMode := true;
                            GenJnlTemplates.Editable := false;
                            if GenJnlTemplates.RunModal() = ACTION::LookupOK then begin
                                GenJnlTemplates.GetRecord(GenJnlTemplate);
                                JournalTemplate := GenJnlTemplate.Name;
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            CheckJournalTemplate();
                        end;
                    }
                    field(BatchName; BatchName)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Batch Name';
                        TableRelation = "Gen. Journal Batch".Name;
                        ToolTip = 'Specifies the name of the journal batch, a personalized journal layout, that the journal is based on.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            GenJnlBatches: Page "General Journal Batches";
                        begin
                            if JournalTemplate <> '' then begin
                                GenJnlBatch.SetRange("Journal Template Name", JournalTemplate);
                                GenJnlBatches.SetTableView(GenJnlBatch);
                            end;

                            GenJnlBatches.LookupMode := true;
                            GenJnlBatches.Editable := false;
                            if GenJnlBatches.RunModal() = ACTION::LookupOK then begin
                                GenJnlBatches.GetRecord(GenJnlBatch);
                                BatchName := GenJnlBatch.Name;
                            end;
                        end;

                        trigger OnValidate()
                        begin
                            CheckBatchName();
                        end;
                    }
                    field(TemplateCode; TemplateCode)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Standard General Journal';
                        TableRelation = "Standard General Journal".Code;
                        ToolTip = 'Specifies the general journal for which you are creating lines.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            StdGenJournal1: Record "Standard General Journal";
                            StdGenJnls: Page "Standard General Journals";
                        begin
                            if JournalTemplate <> '' then begin
                                StdGenJournal1.SetRange("Journal Template Name", JournalTemplate);
                                StdGenJnls.SetTableView(StdGenJournal1);
                            end;

                            StdGenJnls.LookupMode := true;
                            StdGenJnls.Editable := false;
                            if StdGenJnls.RunModal() = ACTION::LookupOK then begin
                                StdGenJnls.GetRecord(StdGenJournal1);
                                TemplateCode := StdGenJournal1.Code;
                            end;
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if PostingDate = 0D then
                PostingDate := WorkDate();
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        Message(Text004);
    end;

    var
        StdGenJournal: Record "Standard General Journal";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        LastGenJnlLine: Record "Gen. Journal Line";
        DocumentTypes: Option " ",Payment,Invoice,"Credit Memo","Finance Charge Memo",Reminder,Refund;
        PostingDate: Date;
        BatchName: Code[10];
        TemplateCode: Code[20];
        LineNo: Integer;
#pragma warning disable AA0074
        Text001: Label 'Gen. Journal Template name is blank.';
        Text002: Label 'Gen. Journal Batch name is blank.';
#pragma warning restore AA0074
        JournalTemplate: Text[10];
#pragma warning disable AA0074
        Text004: Label 'General journal lines are successfully created.';
#pragma warning restore AA0074
        PostingDateIsEmptyErr: Label 'The posting date is empty.';
        DocumentNo: Code[20];

    local procedure GetStandardJournalLine(): Boolean
    var
        StdGenJounalLine: Record "Standard General Journal Line";
    begin
        if TemplateCode = '' then
            exit;
        StdGenJounalLine.SetRange("Journal Template Name", StdGenJournal."Journal Template Name");
        StdGenJounalLine.SetRange("Standard Journal Code", StdGenJournal.Code);
        exit(not StdGenJounalLine.IsEmpty());
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

    local procedure CopyGenJnlFromStdJnl(StdGenJnlLine: Record "Standard General Journal Line"; var GenJnlLine: Record "Gen. Journal Line")
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

        GenJnlLine.TransferFields(StdGenJnlLine, false);
        GenJnlLine.UpdateLineBalance();
        GenJnlLine.Validate("Currency Code");

        if GenJnlLine."VAT Prod. Posting Group" <> '' then
            GenJnlLine.Validate("VAT Prod. Posting Group");
        if (GenJnlLine."VAT %" <> 0) and GenJnlBatch."Allow VAT Difference" then
            GenJnlLine.Validate("VAT Amount", StdGenJnlLine."VAT Amount");
        GenJnlLine.Validate("Bal. VAT Prod. Posting Group");

        if GenJnlBatch."Allow VAT Difference" then
            GenJnlLine.Validate("Bal. VAT Amount", StdGenJnlLine."Bal. VAT Amount");
        GenJnlLine.Insert(true);

        LastGenJnlLine := GenJnlLine;
    end;

    procedure InitializeRequest(DocumentTypesFrom: Option; PostingDateFrom: Date; JournalTemplateFrom: Text[10]; BatchNameFrom: Code[10]; StandardTemplateCodeFrom: Code[20])
    begin
        DocumentTypes := DocumentTypesFrom;
        PostingDate := PostingDateFrom;
        JournalTemplate := JournalTemplateFrom;
        BatchName := BatchNameFrom;
        TemplateCode := StandardTemplateCodeFrom;
    end;

    procedure SetDefaultDocumentNo(NewDocumentNo: Code[20])
    begin
        DocumentNo := NewDocumentNo;
    end;

    local procedure CheckPostingDate()
    begin
        if PostingDate = 0D then
            Error(PostingDateIsEmptyErr);
    end;

    local procedure CheckBatchName()
    begin
        if BatchName = '' then
            Error(Text002);
    end;

    local procedure CheckJournalTemplate()
    begin
        if JournalTemplate = '' then
            Error(Text001);
    end;
}

