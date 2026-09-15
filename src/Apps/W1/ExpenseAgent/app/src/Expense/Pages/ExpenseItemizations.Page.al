// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6975 "Expense Itemizations"
{
    Caption = 'Expense Itemizations';
    PageType = List;
    ApplicationArea = Basic, Suite;
    RefreshOnActivate = true;
    SourceTable = "Expense Itemization";
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Expense Subcategory Code"; Rec."Expense Subcategory Code")
                {
                    ToolTip = 'Specifies the expense subcategory for this itemization.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies a short description of the itemized charge.';
                }
                field("Start Date"; Rec."Start Date")
                {
                    ToolTip = 'Specifies the start date for this itemized expense.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ToolTip = 'Specifies the number of units for this itemization.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Daily Rate"; Rec."Daily Rate")
                {
                    ToolTip = 'Specifies the daily rate used to calculate the amount.';
                }
                field(Amount; Rec.Amount)
                {
                    ToolTip = 'Specifies the calculated amount for this itemization.';
                }
            }
            group(Totals)
            {
                Caption = 'Totals';
                field(TotalAmount; TotalAmount)
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    ApplicationArea = Basic, Suite;
                    Caption = 'Total Amount';
                    Editable = false;
                    ToolTip = 'Specifies the sum of all itemizations for this expense.';
                }
                field(ExpenseAmount; ExpenseAmount)
                {
                    AutoFormatType = 1;
                    AutoFormatExpression = '';
                    ApplicationArea = Basic, Suite;
                    Caption = 'Expense Amount';
                    Editable = false;
                    ToolTip = 'Specifies the original amount entered on the expense.';
                }
            }
        }
    }

    var
        Expense: Record Expense;
        TotalAmount: Decimal;
        ExpenseAmount: Decimal;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        if Expense.Get(Rec.GetFilter("Expense No.")) then
            Rec."Expense Category Code" := Expense."Expense Category";
    end;

    trigger OnAfterGetCurrRecord()
    var
        Itemization: Record "Expense Itemization";
    begin
        Itemization.SetRange("Expense No.", Rec."Expense No.");
        Itemization.CalcSums(Amount);

        TotalAmount := Itemization.Amount;

        if Expense."No." = '' then
            Expense.Get(Rec.GetFilter("Expense No."));
        ExpenseAmount := Expense.Amount;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        ExpenseRecord: Record Expense;
        ExpenseRuleValidation: Codeunit "Expense Rule Validation";
    begin
        if CloseAction in [Action::OK, Action::LookupOK] then begin
            ExpenseRecord.Get(Rec."Expense No.");

            ExpenseRuleValidation.ValidateExpenseAgainstRule(ExpenseRecord);
            ExpenseRuleValidation.ValidateItemizationAmount(Rec."Expense No.", true);
        end;
    end;
}
