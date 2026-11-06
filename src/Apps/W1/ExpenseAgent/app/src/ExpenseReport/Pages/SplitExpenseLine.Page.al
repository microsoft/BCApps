// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7142 "Split Expense Line"
{
    PageType = StandardDialog;
    Caption = 'Split Expense - Same User';
    ApplicationArea = Basic, Suite;
    SourceTable = "Expense Split Allocation";
    SourceTableTemporary = true;
    AutoSplitKey = true;
    DelayedInsert = true;
    Extensible = false;

    layout
    {
        area(Content)
        {
            group(OriginalLine)
            {
                Caption = 'Original Line';

                field(OriginalExpenseCategory; ExpenseReportLine."Expense Category")
                {
                    Caption = 'Expense Category';
                    Editable = false;
                    ToolTip = 'Specifies the expense category of the line that you split.';
                }
                field(OriginalDescription; ExpenseReportLine.Description)
                {
                    Caption = 'Description';
                    Editable = false;
                    ToolTip = 'Specifies the description of the line that you split.';
                }
                field(OriginalAmount; OriginalAmount)
                {
                    AutoFormatExpression = ExpenseReportLine."Expense Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Original Amount';
                    Editable = false;
                    ToolTip = 'Specifies the amount of the expense before any split.';
                }
                field(CurrentAmount; ExpenseReportLine.Amount)
                {
                    AutoFormatExpression = ExpenseReportLine."Expense Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Current Amount';
                    Editable = false;
                    ToolTip = 'Specifies the current amount of the line that you split.';
                }
                field(AllocatedAmount; AllocatedAmount)
                {
                    AutoFormatExpression = ExpenseReportLine."Expense Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Split Amount';
                    Editable = false;
                    ToolTip = 'Specifies the total amount moved to new lines.';
                }
                field(RemainingAmount; RemainingAmount)
                {
                    AutoFormatExpression = ExpenseReportLine."Expense Currency Code";
                    AutoFormatType = 1;
                    Caption = 'Remaining Amount';
                    Editable = false;
                    ToolTip = 'Specifies the amount that remains on the line after the split.';
                }
            }
            repeater(SplitLines)
            {
                Caption = 'New Lines';

                field("Expense Category"; Rec."Expense Category")
                {
                    ShowMandatory = true;
                    ToolTip = 'Specifies the expense category of the new line.';

                    trigger OnValidate()
                    begin
                        if Rec."Expense Category" <> '' then
                            ExpenseLineSplit.CheckSplitCategory(Rec."Expense Category", '');
                    end;
                }
                field("Expense Subcategory Code"; Rec."Expense Subcategory Code")
                {
                    ToolTip = 'Specifies the expense subcategory of the new line.';

                    trigger OnValidate()
                    begin
                        if Rec."Expense Subcategory Code" <> '' then
                            ExpenseLineSplit.CheckSplitCategory(Rec."Expense Category", Rec."Expense Subcategory Code");
                    end;
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the description of the new line. If you leave it blank, the posting description of the expense category is used.';
                }
                field(Amount; Rec.Amount)
                {
                    ShowMandatory = true;
                    ToolTip = 'Specifies the amount to move to the new line. The amount of the original line is reduced by this amount.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Currency Code" := ExpenseReportLine."Expense Currency Code";
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateTotals();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        TempExpenseSplitAllocation: Record "Expense Split Allocation" temporary;
    begin
        if CloseAction = Action::OK then begin
            TempExpenseSplitAllocation.Copy(Rec, true);
            ExpenseLineSplit.CheckSplitLines(ExpenseReportLine, TempExpenseSplitAllocation);
        end;
        exit(true);
    end;

    var
        ExpenseReportLine: Record "Expense Report Line";
        ExpenseLineSplit: Codeunit "Expense Line Split";
        OriginalAmount: Decimal;
        AllocatedAmount: Decimal;
        RemainingAmount: Decimal;

    internal procedure SetExpenseReportLine(SourceExpenseReportLine: Record "Expense Report Line")
    begin
        ExpenseReportLine := SourceExpenseReportLine;
        OriginalAmount := ExpenseReportLine."Original Amount";
        if OriginalAmount = 0 then
            OriginalAmount := ExpenseReportLine.Amount;
        RemainingAmount := ExpenseReportLine.Amount;
    end;

    internal procedure GetSplitLines(var TempExpenseSplitAllocation: Record "Expense Split Allocation" temporary)
    begin
        TempExpenseSplitAllocation.Copy(Rec, true);
    end;

    local procedure UpdateTotals()
    var
        TempExpenseSplitAllocation: Record "Expense Split Allocation" temporary;
    begin
        TempExpenseSplitAllocation.Copy(Rec, true);
        TempExpenseSplitAllocation.Reset();
        TempExpenseSplitAllocation.CalcSums(Amount);
        AllocatedAmount := TempExpenseSplitAllocation.Amount;
        RemainingAmount := ExpenseReportLine.Amount - AllocatedAmount;
    end;
}
