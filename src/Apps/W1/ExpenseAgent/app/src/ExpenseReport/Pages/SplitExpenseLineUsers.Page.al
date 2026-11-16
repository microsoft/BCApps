// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7141 "Split Expense Line Users"
{
    PageType = StandardDialog;
    Caption = 'Split Expense - Different Users';
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

                field(OriginalExpenseUserNo; ExpenseReportLine."Expense User No.")
                {
                    Caption = 'Expense User No.';
                    Editable = false;
                    ToolTip = 'Specifies the expense user who owns the line that you split.';
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
                    Caption = 'Allocated Amount';
                    Editable = false;
                    ToolTip = 'Specifies the total amount allocated to other users.';
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
            repeater(Allocations)
            {
                Caption = 'Allocations';

                field("Expense User No."; Rec."Expense User No.")
                {
                    ShowMandatory = true;
                    ToolTip = 'Specifies the expense user to split the expense with. A new expense with status Open is created for the user, who must confirm it before it can be processed.';
                }
                field("Expense User Name"; Rec."Expense User Name")
                {
                    ToolTip = 'Specifies the name of the expense user.';
                }
                field(Amount; Rec.Amount)
                {
                    ShowMandatory = true;
                    ToolTip = 'Specifies the amount of the expense to allocate to the user. The amount of the original line is reduced by this amount.';

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
            ExpenseLineSplit.CheckAllocations(ExpenseReportLine, TempExpenseSplitAllocation);
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

    internal procedure GetAllocations(var TempExpenseSplitAllocation: Record "Expense Split Allocation" temporary)
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
