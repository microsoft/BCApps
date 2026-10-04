// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7433 "EA Corp Card Trans List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Corp Card Transactions';
    Editable = false;
    PageType = List;
    UsageCategory = Lists;
    SourceTable = "EA Corp Card Trans";
    SourceTableView = sorting("Entry No.") order(descending);

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
                field("Statement Entry No."; Rec."Statement Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the statement that contains this transaction.';
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
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction amount posted to the corporate card liability in the local currency.';
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
                field("Posted Expense Report No."; Rec."Posted Expense Report No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posted expense report linked to this transaction.';
                }
                field("Provider Statement No."; Rec."Provider Statement No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the corporate card provider statement linked to this transaction.';
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
                Caption = 'Open matched expense';
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
            action(OpenLevel3Details)
            {
                Caption = 'Show Level 3 details';
                ApplicationArea = Basic, Suite;
                Image = ViewDetails;
                ToolTip = 'Shows imported Level 3 tax detail lines for the selected transaction.';

                trigger OnAction()
                var
                    CorpCardTransDetail: Record "EA Corp Card Trans Detail";
                begin
                    CorpCardTransDetail.SetRange("Trans Entry No.", Rec."Entry No.");
                    Page.RunModal(Page::"EA Corp Card Details", CorpCardTransDetail);
                end;
            }
            action(OpenProviderStatement)
            {
                Caption = 'Open provider statement';
                ApplicationArea = Basic, Suite;
                Image = Document;
                ToolTip = 'Opens the corporate card provider statement linked to the selected transaction.';

                trigger OnAction()
                var
                    CorpCardStatement: Record "EA Corp Card Statement";
                begin
                    if Rec."Statement Entry No." = 0 then
                        Error(NoLinkedStatementErr);

                    CorpCardStatement.Get(Rec."Statement Entry No.");
                    Page.RunModal(Page::"EA Corp Card Statement", CorpCardStatement);
                end;
            }
        }
    }

    var
        NoLinkedExpenseErr: Label 'No linked expense exists for the selected transaction.';
        NoLinkedStatementErr: Label 'No provider statement is linked to the selected transaction.';
}