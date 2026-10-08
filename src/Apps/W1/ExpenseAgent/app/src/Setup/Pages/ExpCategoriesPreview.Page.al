// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6966 "Exp. Categories Preview"
{
    Caption = 'Expense categories';
    PageType = List;
    ApplicationArea = Basic, Suite;
    SourceTable = "Expense Category";
    SourceTableTemporary = true;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    RefreshOnActivate = true;
    Extensible = false;
    InstructionalText = 'Lists existing expense categories together with the defaults that will be created when you apply the setup. Select a category to see its subcategories.';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Code"; Rec."Code")
                {
                    ToolTip = 'Specifies the category code.';
                    StyleExpr = StyleExpr;
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies a short description of the category.';
                }
                field("Expense Group"; Rec."Expense Group")
                {
                    ToolTip = 'Specifies the expense group the category belongs to.';
                }
                field("Posting Group"; Rec."Posting Group")
                {
                    ToolTip = 'Specifies the posting group used for this category.';
                }
                field("Default Payment Method"; Rec."Default Payment Method")
                {
                    ToolTip = 'Specifies the default payment method for this category.';
                }
                field(Refundable; Rec.Refundable)
                {
                    ToolTip = 'Specifies whether expenses in this category are refundable.';
                }
                field("Prepayment-Cash Advance"; Rec."Prepayment-Cash Advance")
                {
                    ToolTip = 'Specifies whether this category represents a prepayment or cash advance.';
                }
                field("Attachment Enforcement"; Rec."Attachment Enforcement")
                {
                    ToolTip = 'Specifies how strictly attachments are enforced for this category.';
                }
                field("Expense Detail Required"; Rec."Expense Detail Required")
                {
                    ToolTip = 'Specifies the kind of additional expense detail required.';
                }
                field(Status; StatusText)
                {
                    Caption = 'Status';
                    ToolTip = 'Specifies whether the row is a new default that will be added or already exists.';
                    StyleExpr = StyleExpr;
                }
            }
            part(Subcategories; "Exp. Subcategories Preview")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Subcategories';
                SubPageLink = "Expense Category Code" = field(Code);
            }
        }
    }

    trigger OnOpenPage()
    begin
        ReloadPreview();
    end;

    trigger OnAfterGetRecord()
    var
        ExpenseCategory: Record "Expense Category";
    begin
        if ExpenseCategory.Get(Rec."Code") then begin
            StatusText := ExistingLbl;
            StyleExpr := '';
        end else begin
            StatusText := NewLbl;
            StyleExpr := 'Favorable';
        end;
    end;

    local procedure ReloadPreview()
    var
        TempCategory: Record "Expense Category" temporary;
        TempSubcategory: Record "Expense Subcategory" temporary;
        CreateExpenseCategories: Codeunit "Create Expense Categories";
    begin
        CreateExpenseCategories.LoadCategoriesPreview(TempCategory, TempSubcategory);

        Rec.Reset();
        Rec.DeleteAll();

        if TempCategory.FindSet() then
            repeat
                Rec := TempCategory;
                Rec.Insert();
            until TempCategory.Next() = 0;

        if Rec.FindFirst() then;

        CurrPage.Subcategories.Page.Load(TempSubcategory);
    end;

    var
        StatusText: Text;
        StyleExpr: Text;
        NewLbl: Label 'New';
        ExistingLbl: Label 'Existing';
}
