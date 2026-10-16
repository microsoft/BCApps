// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7140 "Expense Split Allocations"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Split Expense - Different Users';
    DelayedInsert = true;
    MultipleNewLines = true;
    PageType = List;
    SourceTable = "Expense Split Allocation";
    SourceTableTemporary = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Expense User No."; Rec."Expense User No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the expense user who will receive a new expense from this split.';
                }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the amount allocated to this user.';
                    AutoFormatType = 0;
                }
            }
        }
    }

    var
        MaxSplitAmount: Decimal;
        SourceExpenseUserNo: Code[20];
        TotalAmount: Decimal;
        DuplicateUserErr: Label 'User %1 is entered more than once.', Comment = '%1 = Expense User No.';
        MustBeDifferentUserErr: Label 'User %1 is the same as the source user. Use Split Expense -> Same user for this case.', Comment = '%1 = Expense User No.';
        AmountMustBeGreaterThanZeroErr: Label 'Amount for user %1 must be greater than 0.', Comment = '%1 = Expense User No.';
        TotalAmountMustBeGreaterThanZeroErr: Label 'At least one allocation line must be entered.';
        TotalAmountMustBeLessThanSourceErr: Label 'Total allocated amount must be less than the current line amount (%1).', Comment = '%1 = current line amount';

    trigger OnOpenPage()
    begin
        if Rec.IsEmpty() then
            InsertNewLine();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [Action::OK, Action::LookupOK] then
            ValidateAllocations();

        exit(true);
    end;

    internal procedure Initialize(NewSourceExpenseUserNo: Code[20]; NewMaxSplitAmount: Decimal)
    begin
        SourceExpenseUserNo := NewSourceExpenseUserNo;
        MaxSplitAmount := NewMaxSplitAmount;
    end;

    internal procedure GetAllocations(var TempSplitAllocation: Record "Expense Split Allocation" temporary)
    begin
        TempSplitAllocation.DeleteAll();
        if Rec.FindSet() then
            repeat
                TempSplitAllocation := Rec;
                TempSplitAllocation.Insert();
            until Rec.Next() = 0;
    end;

    local procedure ValidateAllocations()
    var
        SeenUsers: Dictionary of [Code[20], Boolean];
    begin
        TotalAmount := 0;
        if Rec.FindSet() then
            repeat
                Rec.TestField("Expense User No.");
                if Rec."Expense User No." = SourceExpenseUserNo then
                    Error(MustBeDifferentUserErr, Rec."Expense User No.");
                if Rec.Amount <= 0 then
                    Error(AmountMustBeGreaterThanZeroErr, Rec."Expense User No.");
                if SeenUsers.ContainsKey(Rec."Expense User No.") then
                    Error(DuplicateUserErr, Rec."Expense User No.");
                SeenUsers.Add(Rec."Expense User No.", true);

                TotalAmount += Rec.Amount;
            until Rec.Next() = 0;
        if TotalAmount <= 0 then
            Error(TotalAmountMustBeGreaterThanZeroErr);
        if TotalAmount >= MaxSplitAmount then
            Error(TotalAmountMustBeLessThanSourceErr, MaxSplitAmount);
    end;

    local procedure InsertNewLine()
    begin
        Rec.Init();
        Rec."Line No." := GetNextLineNo();
        Rec.Insert();
    end;

    local procedure GetNextLineNo(): Integer
    var
        TempSplitAllocation: Record "Expense Split Allocation" temporary;
    begin
        TempSplitAllocation.Copy(Rec, true);
        if TempSplitAllocation.FindLast() then
            exit(TempSplitAllocation."Line No." + 10000);

        exit(10000);
    end;
}
