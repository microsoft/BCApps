// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7220 EACorpCardBatches
{
    ApplicationArea = Basic, Suite;
    Caption = 'Corp Card Batches';
    PageType = List;
    UsageCategory = Lists;
    SourceTable = EACorpCardBatch;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Batch No."; Rec."Batch No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the import batch number.';
                }
                field("Provider Code"; Rec."Provider Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the provider for this batch.';
                }
                field("Data Exch Entry No."; Rec."Data Exch Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the data exchange entry used for this batch.';
                }
                field("Started DT"; Rec."Started DT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when import processing started.';
                }
                field("Ended DT"; Rec."Ended DT")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when import processing ended.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the batch processing status.';
                }
                field(Imported; Rec.Imported)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of imported transactions.';
                }
                field("Imported Transactions"; Rec."Imported Transactions")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the actual number of transactions currently stored for this batch.';
                }
                field(Rejected; Rec.Rejected)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of rejected transactions.';
                }
                field(Duplicates; Rec.Duplicates)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of duplicate transactions.';
                }
                field(Exceptions; Rec.Exceptions)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of transactions with exceptions.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunMatching)
            {
                Caption = 'Run Matching';
                ApplicationArea = Basic, Suite;
                Image = Calculate;
                ToolTip = 'Runs post-import matching and draft creation for imported transactions in the selected batch.';

                trigger OnAction()
                var
                    PostImportOrch: Codeunit EACorpCardPostImportOrch;
                begin
                    PostImportOrch.ProcessBatchPostImport(Rec."Batch No.");
                    CurrPage.Update(false);
                end;
            }
            action(ShowTransactions)
            {
                Caption = 'Show Transactions';
                ApplicationArea = Basic, Suite;
                Image = List;
                ToolTip = 'Opens corporate card transactions for the selected batch.';

                trigger OnAction()
                var
                    CorpCardTrans: Record EACorpCardTrans;
                begin
                    CorpCardTrans.SetRange("Batch No.", Rec."Batch No.");
                    CorpCardTrans.SetRange("Provider Code", Rec."Provider Code");
                    Page.RunModal(Page::EACorpCardTransList, CorpCardTrans);
                end;
            }
        }
    }
}