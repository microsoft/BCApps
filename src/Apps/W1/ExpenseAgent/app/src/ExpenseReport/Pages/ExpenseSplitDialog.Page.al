// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7141 "Expense Split Dialog"
{
    Caption = 'Split Expense';
    PageType = StandardDialog;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field(SplitAmount; SplitAmount)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'New Line Amount';
                    AutoFormatType = 0;
                    ToolTip = 'Specifies the amount that will be moved to the new expense line.';
                }
                field(SplitCategoryCode; SplitCategoryCode)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Expense Category';
                    ToolTip = 'Specifies the expense category for the new split line.';
                    TableRelation = "Expense Category".Code where(Inactive = const(false));
                }
            }
        }
    }

    var
        SplitAmount: Decimal;
        SplitCategoryCode: Code[20];
        MaxSplitAmount: Decimal;
        SplitAmountMustBeGreaterThanZeroErr: Label 'New Line Amount must be greater than 0.';
        SplitAmountMustBeLessThanSourceErr: Label 'New Line Amount must be less than the current line amount (%1).', Comment = '%1 = current line amount';
        SplitCategoryMustHaveValueErr: Label 'Expense Category must have a value.';

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [Action::OK, Action::LookupOK] then begin
            if SplitAmount <= 0 then
                Error(SplitAmountMustBeGreaterThanZeroErr);
            if SplitAmount >= MaxSplitAmount then
                Error(SplitAmountMustBeLessThanSourceErr, MaxSplitAmount);
            if SplitCategoryCode = '' then
                Error(SplitCategoryMustHaveValueErr);
        end;

        exit(true);
    end;

    internal procedure SetValues(NewMaxSplitAmount: Decimal; DefaultCategoryCode: Code[20])
    begin
        MaxSplitAmount := NewMaxSplitAmount;
        SplitCategoryCode := DefaultCategoryCode;
        SplitAmount := 0;
    end;

    internal procedure GetValues(var OutSplitAmount: Decimal; var OutCategoryCode: Code[20])
    begin
        OutSplitAmount := SplitAmount;
        OutCategoryCode := SplitCategoryCode;
    end;
}
