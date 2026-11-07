// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.DirectDebit;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Foundation.NoSeries;
using Microsoft.Sales.Receivables;

/// <summary>
/// Posts direct debit collection entries by creating general journal lines and processing payments.
/// Handles the posting of successfully exported direct debit collections, updating mandate counters,
/// and generating payment journal entries for bank reconciliation.
/// </summary>
report 1201 "Post Direct Debit Collection"
{
    Caption = 'Post Direct Debit Collection';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Direct Debit Collection Entry"; "Direct Debit Collection Entry")
        {
            DataItemTableView = sorting("Direct Debit Collection No.", "Entry No.");

            trigger OnAfterGetRecord()
            begin
                CurrCount += 1;
                Window.Update(1, CurrCount * 10000 div TotalCount);
                if CreateJnlLine("Direct Debit Collection Entry") then begin
                    Status := Status::Posted;
                    Modify();
                end else
                    SkippedCount += 1;
            end;

            trigger OnPreDataItem()
            begin
                SetRange("Direct Debit Collection No.", DirectDebitCollectionNo);
                SetRange(Status, Status::"File Created");
                TotalCount := Count;
                Window.Open(ProgressMsg);
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
                field(DirectDebitCollectionNo; DirectDebitCollectionNo)
                {
                    ApplicationArea = Suite;
                    Caption = 'Direct Debit Collection No.';
                    TableRelation = "Direct Debit Collection";
                    ToolTip = 'Specifies the direct debit collection that you want to post payment receipt for.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        DirectDebitCollections: Page "Direct Debit Collections";
                    begin
                        DirectDebitCollection.SetRange(Status, DirectDebitCollection.Status::"File Created");
                        if DirectDebitCollectionNo = 0 then
                            DirectDebitCollection.FindLast()
                        else
                            if DirectDebitCollection.Get(DirectDebitCollectionNo) then;
                        DirectDebitCollections.LookupMode := true;
                        DirectDebitCollections.SetRecord(DirectDebitCollection);
                        DirectDebitCollections.SetTableView(DirectDebitCollection);
                        if DirectDebitCollections.RunModal() = ACTION::LookupOK then begin
                            DirectDebitCollections.GetRecord(DirectDebitCollection);
                            DirectDebitCollectionNo := DirectDebitCollection."No.";
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        DirectDebitCollection.Get(DirectDebitCollectionNo);
                        DirectDebitCollection.TestField(Status, DirectDebitCollection.Status::"File Created");
                    end;
                }
                field("DirectDebitCollection.Identifier"; DirectDebitCollection.Identifier)
                {
                    ApplicationArea = Suite;
                    Caption = 'Identifier';
                    Editable = false;
                    ToolTip = 'Specifies the collection.';
                }
                field("DirectDebitCollection.Status"; DirectDebitCollection.Status)
                {
                    ApplicationArea = Suite;
                    Caption = 'Status';
                    Editable = false;
                    ToolTip = 'Specifies the status of the collection.';
                }
#pragma warning disable AA0100
                field("DirectDebitCollection.""To Bank Account No."""; DirectDebitCollection."To Bank Account No.")
#pragma warning restore AA0100
                {
                    ApplicationArea = Suite;
                    Caption = 'Bank Account No.';
                    Editable = false;
                    ToolTip = 'Specifies which of your company''s bank accounts the collected payment will be transferred to from the customer''s bank account.';
                }
                field(GeneralJournalTemplateName; GeneralJournalTemplateName)
                {
                    ApplicationArea = Suite;
                    Caption = 'General Journal Template';
                    TableRelation = "Gen. Journal Template";
                    ToolTip = 'Specifies the general journal template that the entries are placed in.';

                    trigger OnValidate()
                    var
                        GenJournalTemplate: Record "Gen. Journal Template";
                    begin
                        if GeneralJournalTemplateName = '' then begin
                            GeneralJournalBatchName := '';
                            exit;
                        end;
                        GenJournalTemplate.Get(GeneralJournalTemplateName);
                        if not (GenJournalTemplate.Type in
                                [GenJournalTemplate.Type::General, GenJournalTemplate.Type::Purchases, GenJournalTemplate.Type::Payments,
                                 GenJournalTemplate.Type::Sales, GenJournalTemplate.Type::"Cash Receipts"])
                        then
                            Error(
                              TemplateTypeErr,
                              GenJournalTemplate.Type::General, GenJournalTemplate.Type::Purchases, GenJournalTemplate.Type::Payments,
                              GenJournalTemplate.Type::Sales, GenJournalTemplate.Type::"Cash Receipts");

                        GenJournalTemplate.TestField("No. Series");
                    end;
                }
                field(GeneralJournalBatchName; GeneralJournalBatchName)
                {
                    ApplicationArea = Suite;
                    Caption = 'General Journal Batch';
                    TableRelation = "Gen. Journal Batch";
                    ToolTip = 'Specifies the general journal batch that the entries are placed in.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        GenJournalBatch: Record "Gen. Journal Batch";
                        GeneralJournalBatches: Page "General Journal Batches";
                    begin
                        GenJournalBatch.SetRange("Journal Template Name", GeneralJournalTemplateName);
                        GeneralJournalBatches.SetTableView(GenJournalBatch);
                        if GeneralJournalBatches.RunModal() = ACTION::OK then begin
                            GeneralJournalBatches.GetRecord(GenJournalBatch);
                            GeneralJournalBatchName := GenJournalBatch.Name;
                        end;
                    end;

                    trigger OnValidate()
                    var
                        GenJournalBatch: Record "Gen. Journal Batch";
                    begin
                        GenJournalBatch.Get(GeneralJournalTemplateName, GeneralJournalBatchName);
                        GenJournalBatch.TestField(Recurring, false);
                        GenJournalBatch.TestField("No. Series");
                    end;
                }
                field(CreateJnlOnly; CreateJnlOnly)
                {
                    ApplicationArea = Suite;
                    Caption = 'Create Journal Only';
                    ToolTip = 'Specifies if you want to post the payment receipt when you choose the OK button. The payment receipt will be prepared in the specified journal and will not be posted until someone posts the journal lines in question.';
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if DirectDebitCollectionNo <> 0 then
                if DirectDebitCollection.Get(DirectDebitCollectionNo) then;
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        Window.Close();
        if CreateJnlOnly then
            Message(JnlCreatedMsg, TotalCount - SkippedCount, SkippedCount)
        else
            Message(PostedMsg, TotalCount - SkippedCount, SkippedCount);

        if SkippedCount = 0 then begin
            DirectDebitCollection.Get(DirectDebitCollectionNo);
            DirectDebitCollection.Status := DirectDebitCollection.Status::Posted;
            DirectDebitCollection.Modify();
        end;
    end;

    trigger OnPreReport()
    begin
        GenJnlBatch.Get(GeneralJournalTemplateName, GeneralJournalBatchName);
        GenJnlLine.SetRange("Journal Template Name", GeneralJournalTemplateName);
        GenJnlLine.SetRange("Journal Batch Name", GeneralJournalBatchName);
        if GenJnlLine.FindLast() then;
        LastLineNo := GenJnlLine."Line No.";
    end;

    var
#pragma warning disable AA0470
        TemplateTypeErr: Label 'Only General Journal templates of type %1, %2, %3, %4, or %5 are allowed.', Comment = '%1..5 lists Type=General,Purchases,Payments,Sales,Cash Receipts';
#pragma warning restore AA0470
        DirectDebitCollection: Record "Direct Debit Collection";
        GenJnlLine: Record "Gen. Journal Line";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
        DimMgt: Codeunit DimensionManagement;
        Window: Dialog;
        DirectDebitCollectionNo: Integer;
        GeneralJournalTemplateName: Code[10];
        GeneralJournalBatchName: Code[10];
        LastLineNo: Integer;
        PostingTxt: Label '%1 %2 Direct Debit', Comment = '%1=Doc. type, %2=Doc. No. E.g. Invoice 234 Direct Debit';
        CreateJnlOnly: Boolean;
        TotalCount: Integer;
        CurrCount: Integer;
#pragma warning disable AA0470
        ProgressMsg: Label '#1##################';
#pragma warning restore AA0470
        JnlCreatedMsg: Label '%1 journal lines were created. %2 lines were skipped.', Comment = '%1 and %2 are both numbers / count.';
        PostedMsg: Label '%1 payments were posted. %2 lines were skipped.', Comment = '%1 and %2 are both numbers / count.';
        SkippedCount: Integer;

    /// <summary>
    /// Sets the direct debit collection to process for posting.
    /// </summary>
    /// <param name="NewCollectionEntry">Collection number to process</param>
    procedure SetCollectionEntry(NewCollectionEntry: Integer)
    begin
        DirectDebitCollectionNo := NewCollectionEntry;
        DirectDebitCollection.Get(DirectDebitCollectionNo);
    end;

    /// <summary>
    /// Sets the journal template and batch names for posting operations.
    /// </summary>
    /// <param name="NewGenJnlTemplateName">General journal template name to use</param>
    /// <param name="NewGenJnlBachName">General journal batch name to use</param>
    procedure SetJnlBatch(NewGenJnlTemplateName: Code[10]; NewGenJnlBachName: Code[10])
    begin
        GeneralJournalTemplateName := NewGenJnlTemplateName;
        GeneralJournalBatchName := NewGenJnlBachName;
        CurrReport.UseRequestPage := false;
    end;

    /// <summary>
    /// Controls whether the operation only creates journal lines without posting.
    /// </summary>
    /// <param name="NewCreateJnlOnly">True to only create journal lines, false to also post them</param>
    procedure SetCreateJnlOnly(NewCreateJnlOnly: Boolean)
    begin
        CreateJnlOnly := NewCreateJnlOnly;
    end;

    local procedure CreateJnlLine(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry") Result: Boolean
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        GenJournalTemplate: Record "Gen. Journal Template";
        NoSeries: Codeunit "No. Series";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateJnlLine(GenJnlLine, DirectDebitCollectionEntry, IsHandled, Result);
        if IsHandled then
            exit(Result);

        CustLedgEntry.Get(DirectDebitCollectionEntry."Applies-to Entry No.");
        CustLedgEntry.CalcFields("Remaining Amount");
        if not CustLedgEntry.Open or (CustLedgEntry."Remaining Amount" < DirectDebitCollectionEntry."Transfer Amount") then
            exit(false);

        LastLineNo += 10000;
        GenJnlLine."Journal Template Name" := GeneralJournalTemplateName;
        GenJnlLine."Journal Batch Name" := GeneralJournalBatchName;
        GenJnlLine."Line No." := LastLineNo;
        if GenJnlBatch."No. Series" <> '' then
            if CreateJnlOnly then
                GenJnlLine.SetUpNewLine(GenJnlLine, GenJnlLine."Balance (LCY)", true)
            else begin
                GenJnlLine."Document No." := NoSeries.GetNextNo(GenJnlBatch."No. Series", GenJnlLine."Posting Date");
                GenJournalTemplate.Get(GeneralJournalTemplateName);
                GenJnlLine."Source Code" := GenJournalTemplate."Source Code";
                if GenJnlBatch."Posting No. Series" <> '' then
                    GenJnlLine."Posting No. Series" := GenJnlBatch."Posting No. Series"
                else
                    GenJnlLine."Posting No. Series" := GenJnlBatch."No. Series";
            end;

        GenJnlLine.SetSuppressCommit(true);
        GenJnlLine.Validate("Document Type", GenJnlLine."Document Type"::Payment);
        GenJnlLine.Validate("Account Type", GenJnlLine."Account Type"::Customer);
        GenJnlLine.Validate("Account No.", DirectDebitCollectionEntry."Customer No.");
        GenJnlLine.Validate("Bal. Account Type", GenJnlLine."Bal. Account Type"::"Bank Account");
        GenJnlLine.Validate("Bal. Account No.", DirectDebitCollection."To Bank Account No.");
        SetGenJnlLineDim(CustLedgEntry);

        GenJnlLine.Validate("Posting Date", DirectDebitCollectionEntry."Transfer Date");
        GenJnlLine.Description :=
          CopyStr(
            StrSubstNo(
              PostingTxt, CustLedgEntry."Document Type", CustLedgEntry."Document No."), 1, MaxStrLen(GenJnlLine.Description));
        GenJnlLine.Validate("Currency Code", CustLedgEntry."Currency Code");
        GenJnlLine.Validate(Amount, -DirectDebitCollectionEntry."Transfer Amount");
        GenJnlLine."Applies-to Doc. Type" := CustLedgEntry."Document Type";
        GenJnlLine.Validate("Applies-to Doc. No.", CustLedgEntry."Document No.");
        GenJnlLine.SetSuppressCommit(false);

        OnAfterCreateJnlLine(GenJnlLine, DirectDebitCollectionEntry);

        if CreateJnlOnly then
            GenJnlLine.Insert(true)
        else
            GenJnlPostLine.RunWithCheck(GenJnlLine);
        exit(true);
    end;

    local procedure SetGenJnlLineDim(CustLedgEntry: Record "Cust. Ledger Entry")
    var
        DimensionSetIDArr: array[10] of Integer;
    begin
        DimensionSetIDArr[1] := GenJnlLine."Dimension Set ID";
        DimensionSetIDArr[2] := CustLedgEntry."Dimension Set ID";
        GenJnlLine."Dimension Set ID" :=
          DimMgt.GetCombinedDimensionSetID(
            DimensionSetIDArr, GenJnlLine."Shortcut Dimension 1 Code", GenJnlLine."Shortcut Dimension 2 Code");

        OnAfterSetGenJnlLineDim(GenJnlLine, CustLedgEntry);
    end;

    /// <summary>
    /// Integration event raised after creating a general journal line from direct debit collection entry.
    /// Enables custom processing or field updates after journal line creation.
    /// </summary>
    /// <param name="GenJournalLine">General journal line that was created</param>
    /// <param name="DirectDebitCollectionEntry">Source direct debit collection entry</param>
    /// <remarks>
    /// Raised from CreateJnlLine procedure after creating and populating journal line.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateJnlLine(var GenJournalLine: Record "Gen. Journal Line"; DirectDebitCollectionEntry: Record "Direct Debit Collection Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised after setting dimensions on general journal line during direct debit processing.
    /// Enables custom dimension handling or validation after standard dimension assignment.
    /// </summary>
    /// <param name="GenJournalLine">General journal line with assigned dimensions</param>
    /// <param name="CustLedgEntry">Customer ledger entry providing dimension context</param>
    /// <remarks>
    /// Raised from CreateJnlLine procedure after copying dimensions from customer ledger entry.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnAfterSetGenJnlLineDim(var GenJournalLine: Record "Gen. Journal Line"; CustLedgEntry: Record "Cust. Ledger Entry")
    begin
    end;

    /// <summary>
    /// Integration event raised before creating general journal line from direct debit collection entry.
    /// Enables custom journal line creation or validation before standard processing.
    /// </summary>
    /// <param name="GenJournalLine">General journal line to be created</param>
    /// <param name="DirectDebitCollectionEntry">Source direct debit collection entry</param>
    /// <param name="IsHandled">Set to true to skip standard journal line creation</param>
    /// <param name="Result">Set to true if custom processing was successful</param>
    /// <remarks>
    /// Raised from CreateJnlLine procedure before creating and populating journal line.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateJnlLine(var GenJournalLine: Record "Gen. Journal Line"; DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;
}

