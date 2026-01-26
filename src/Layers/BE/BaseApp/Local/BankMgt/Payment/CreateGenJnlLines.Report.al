// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Foundation.NoSeries;

report 2000022 "Create Gen. Jnl. Lines"
{
    Caption = 'Create Gen. Jnl. Lines';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Domiciliation Journal Line"; "Domiciliation Journal Line")
        {

            trigger OnAfterGetRecord()
            begin
                CreateGenJnlLineFromDomJnlLine("Domiciliation Journal Line");
                TotalAmountLCY += "Domiciliation Journal Line"."Amount (LCY)";
            end;
        }
    }

    requestpage
    {

        layout
        {
            area(content)
            {
                field(GenJnlTemplate; GeneralJournalTemplateName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'General Journal Template';
                    TableRelation = "Gen. Journal Template";
                    ToolTip = 'Specifies the general journal template that the entries are placed in.';

                    trigger OnValidate()
                    var
                    begin
                        if GeneralJournalTemplateName = '' then
                            GeneralJournalBatchName := '';
                    end;
                }
                field(GenJnlBatch; GeneralJournalBatchName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'General Journal Batch';
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
                field(PostGenJnlLines; PostGenJnlLines)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Post General Journal Lines';
                    ToolTip = 'Specifies if you want to transfer the postings in the general journal to the general ledger.';
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

    trigger OnPostReport()
    var
        BalancingDomJnlLine: Record "Domiciliation Journal Line";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        BalancingDomJnlLine := "Domiciliation Journal Line";
        BalancingDomJnlLine."Customer No." := GenJnlBatch."Bal. Account No.";
        BalancingDomJnlLine.Amount := -TotalAmountLCY;
        BalancingDomJnlLine."Message 1" := '';
        BalancingDomJnlLine."Applies-to Doc. Type" := BalancingDomJnlLine."Applies-to Doc. Type"::" ";
        BalancingDomJnlLine."Applies-to Doc. No." := '';
        CreateGenJnlLineFromDomJnlLine(BalancingDomJnlLine);

        if PostGenJnlLines then begin
            GenJnlLine.SetRange("Journal Template Name", GeneralJournalTemplateName);
            GenJnlLine.SetRange("Journal Batch Name", GeneralJournalBatchName);
            GenJnlLine.FindFirst();
            CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Post", GenJnlLine);
        end;
    end;

    trigger OnPreReport()
    var
        GLAcc: Record "G/L Account";
    begin
        // Check General Journal
        GenJnlBatch.Reset();
        if not GenJnlBatch.Get(GeneralJournalTemplateName, GeneralJournalBatchName) then
            Error(PostingNotSpecifiedErr, GenJnlBatch.FieldCaption(Name));

        if not (GenJnlBatch."Bal. Account Type" = GenJnlBatch."Bal. Account Type"::"G/L Account") then
            Error(BalAccTypeErr, GenJnlBatch.Name);

        if GenJnlBatch."Bal. Account No." = '' then
            Error(BalAccNoErr, GenJnlBatch.Name);

        if not GLAcc.Get(GenJnlBatch."Bal. Account No.") then
            Error(NotGLAccErr, GenJnlBatch."Bal. Account No.");

        if not (GLAcc."Account Type" = GLAcc."Account Type"::Posting) then
            Error(NotPostingErr, GLAcc."No.");
    end;

    var
        GenJnlBatch: Record "Gen. Journal Batch";
        GeneralJournalTemplateName: Code[10];
        GeneralJournalBatchName: Code[10];
        PostGenJnlLines: Boolean;
        PostingNotSpecifiedErr: Label 'The %1 for posting is not specified.';
        BalAccTypeErr: Label 'The balance account type in %1 must be G/L Account.';
        BalAccNoErr: Label 'The balance account number in %1 is not a valid G/L Account No.';
        NotGLAccErr: Label '%1 in Journal Template is not a G/L Account No.';
        NotPostingErr: Label 'The account type in general ledger account %1 must be Posting.';
        TotalAmountLCY: Decimal;

    [Scope('OnPrem')]
    procedure FindLastGenJnlLine(var LastGenJnlLine: Record "Gen. Journal Line")
    begin
        LastGenJnlLine.SetRange("Journal Template Name", GeneralJournalTemplateName);
        LastGenJnlLine.SetRange("Journal Batch Name", GeneralJournalBatchName);
        if LastGenJnlLine.FindLast() then;
    end;

    [Scope('OnPrem')]
    procedure CreateGenJnlLineFromDomJnlLine(DomJnlLine: Record "Domiciliation Journal Line")
    var
        FileDomiciliations: Report "File Domiciliations";
        GenJnlLine: Record "Gen. Journal Line";
        NoSeries: Codeunit "No. Series";
        DocumentNo: Code[10];
    begin
        DocumentNo := NoSeries.PeekNextNo(GenJnlBatch."No. Series", DomJnlLine."Posting Date");
        FindLastGenJnlLine(GenJnlLine);
        FileDomiciliations.SetGlobalPostingVariables(GenJnlBatch, GenJnlLine, DocumentNo);
        FileDomiciliations.SetGenJnlLine(DomJnlLine);
    end;
}

