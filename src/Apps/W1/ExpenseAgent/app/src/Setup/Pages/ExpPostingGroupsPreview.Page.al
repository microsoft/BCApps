// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6985 "Exp. Posting Groups Preview"
{
    Caption = 'Expense posting groups';
    PageType = List;
    ApplicationArea = Basic, Suite;
    SourceTable = "Expense Posting Group";
    SourceTableTemporary = true;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    RefreshOnActivate = true;
    Extensible = false;
    InstructionalText = 'Lists existing expense posting groups together with the defaults that will be created when you apply the setup.';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Code"; Rec."Code")
                {
                    ToolTip = 'Specifies the posting group code.';
                    StyleExpr = StyleExpr;
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies a short description of the posting group.';
                }
                field("Refundable Debit Account"; Rec."Refundable Debit Account")
                {
                    ToolTip = 'Specifies the refundable debit account for this posting group.';
                }
                field("Non-Refundable Debit Account"; Rec."Non-Refundable Debit Account")
                {
                    ToolTip = 'Specifies the non-refundable debit account for this posting group.';
                }
                field("Prepayment Credit Account"; Rec."Prepayment Credit Account")
                {
                    ToolTip = 'Specifies the prepayment credit account for this posting group.';
                }
                field("Debit Rounding Account"; Rec."Debit Rounding Account")
                {
                    ToolTip = 'Specifies the rounding debit account for this posting group.';
                }
                field("Credit Rounding Account"; Rec."Credit Rounding Account")
                {
                    ToolTip = 'Specifies the rounding credit account for this posting group.';
                }
                field(Status; StatusText)
                {
                    Caption = 'Status';
                    ToolTip = 'Specifies whether the row is a new default that will be added or already exists.';
                    StyleExpr = StyleExpr;
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        ReloadPreview();
    end;

    trigger OnAfterGetRecord()
    var
        ExpensePostingGroup: Record "Expense Posting Group";
    begin
        if ExpensePostingGroup.Get(Rec."Code") then begin
            StatusText := ExistingLbl;
            StyleExpr := '';
        end else begin
            StatusText := NewLbl;
            StyleExpr := 'Favorable';
        end;
    end;

    local procedure ReloadPreview()
    var
        TempPostingGroup: Record "Expense Posting Group" temporary;
        CreateExpenseCategories: Codeunit "Create Expense Categories";
    begin
        CreateExpenseCategories.LoadPostingGroupsPreview(TempPostingGroup);

        Rec.Reset();
        Rec.DeleteAll();

        if TempPostingGroup.FindSet() then
            repeat
                Rec := TempPostingGroup;
                Rec.Insert();
            until TempPostingGroup.Next() = 0;

        if Rec.FindFirst() then;
    end;

    var
        StatusText: Text;
        StyleExpr: Text;
        NewLbl: Label 'New';
        ExistingLbl: Label 'Existing';
}
