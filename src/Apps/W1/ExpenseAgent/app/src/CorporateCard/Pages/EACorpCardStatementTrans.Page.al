// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7446 "EA Corp Card Statement Trans"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Statement Transactions';
    Editable = false;
    PageType = ListPart;
    SourceTable = "EA Corp Card Trans";

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the imported transaction entry number.';
                }
                field("Provider Trans Id"; Rec."Provider Trans Id")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction identifier assigned by the corporate card provider.';
                }
                field("Card Id"; Rec."Card Id")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the internal corporate card identifier resolved in Business Central, not a card number supplied by the provider.';
                }
                field("Card Last 4"; Rec."Card Last 4")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Trans Date"; Rec."Trans Date")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction date reported by the provider.';
                }
                field("Merchant Raw"; Rec."Merchant Raw")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction description reported by the provider.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the transaction amount reported by the provider.';
                }
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the currency of the provider transaction.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the processing status of the statement transaction.';
                }
                field("Expense No."; Rec."Expense No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expense linked to the imported transaction.';
                }
                field("Posted Expense Report No."; Rec."Posted Expense Report No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the posted expense report linked to the imported transaction.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ShowNotPosted)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Not posted';
                Image = FilterLines;
                ToolTip = 'Shows only the statement transactions whose expense has not been posted yet, including transactions without an expense.';

                trigger OnAction()
                begin
                    Rec.SetRange("Expense No.");
                    Rec.SetFilter(Status, '<>%1', Rec.Status::Posted);
                    CurrPage.Update(false);
                end;
            }
            action(ShowWithoutExpense)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Without expense';
                Image = FilterLines;
                ToolTip = 'Shows only the statement transactions that are not linked to an expense yet.';

                trigger OnAction()
                begin
                    Rec.SetRange(Status);
                    Rec.SetRange("Expense No.", '');
                    CurrPage.Update(false);
                end;
            }
            action(ShowAll)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show all';
                Image = ClearFilter;
                ToolTip = 'Removes the filter and shows all statement transactions.';

                trigger OnAction()
                begin
                    Rec.SetRange(Status);
                    Rec.SetRange("Expense No.");
                    CurrPage.Update(false);
                end;
            }
        }
    }
}
