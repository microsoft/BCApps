// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6974 "Per Diem Expenses"
{
    Caption = 'Per Diem Expenses';
    PageType = List;
    SourceTable = "Expense Per Diem";
    InsertAllowed = false;
    DeleteAllowed = false;
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies a short description of this per diem entry. Editable until a rule is applied to the expense.';
                }
                field("Date"; Rec."Date")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the date covered by this per diem entry. Editable until a rule is applied to the expense.';
                }
                field(Breakfast; Rec.Breakfast)
                {
                    Caption = 'Breakfast Provided';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether breakfast was provided; reduces the per diem.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field(Lunch; Rec.Lunch)
                {
                    Caption = 'Lunch Provided';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether lunch was provided; reduces the per diem.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field(Dinner; Rec.Dinner)
                {
                    Caption = 'Dinner Provided';
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether dinner was provided; reduces the per diem.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Per Diem Amount"; Rec."Per Diem Amount")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    ToolTip = 'Specifies the per diem amount for the day based on policy and meals provided. Editable until a rule is applied to the expense.';
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        Expense: Record Expense;
    begin
        Expense.Get(Rec.GetFilter("Expense No."));

        if Expense."Expense Location" = '' then
            Rec.SendMissingExpenseLocationNotification(Expense);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Expense: Record Expense;
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
    begin
        if CloseAction in [Action::OK, Action::LookupOK] then begin
            Expense.Get(Rec."Expense No.");

            ExpenseRuleValidation.ValidateExpenseAgainstRule(Expense);
        end;
    end;
}
