// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7223 EACorpCardTransList
{
    ApplicationArea = Basic, Suite;
    Caption = 'Corp Card Transactions';
    PageType = List;
    UsageCategory = Lists;
    SourceTable = EACorpCardTrans;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction entry number.';
                }
                field("Batch No."; Rec."Batch No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the import batch number.';
                }
                field("Provider Code"; Rec."Provider Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the provider code for this transaction.';
                }
                field("Card Id"; Rec."Card Id")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the mapped corporate card identifier.';
                }
                field("Provider Trans Id"; Rec."Provider Trans Id")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the provider transaction identifier.';
                }
                field("Trans Date"; Rec."Trans Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction date.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction amount.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction currency code.';
                }
                field(MCC; Rec.MCC)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the merchant category code for this transaction.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the processing status for this transaction.';
                }
                field("Expense No."; Rec."Expense No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the linked expense number if created.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenMatchedExpense)
            {
                Caption = 'Open Matched Expense';
                ApplicationArea = Basic, Suite;
                Image = Navigate;
                Enabled = Rec."Expense No." <> '';
                ToolTip = 'Opens the linked expense card for the selected transaction.';

                trigger OnAction()
                var
                    Expense: Record Expense;
                begin
                    if Rec."Expense No." = '' then
                        Error(NoLinkedExpenseErr);

                    Expense.Get(Rec."Expense No.");
                    Page.RunModal(Page::Expense, Expense);
                end;
            }
        }
    }

    var
        NoLinkedExpenseErr: Label 'No linked expense exists for the selected transaction.';
}