// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.Utilities;

page 6945 "Expense Category Card"
{
    Caption = 'Expense Category';
    PageType = Card;
    RefreshOnActivate = true;
    ApplicationArea = Basic, Suite;
    SourceTable = "Expense Category";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec."Code")
                {
                }
                field(Description; Rec.Description)
                {
                    Caption = 'Agent Skill';
                }
                field("Posting Description"; Rec."Posting Description")
                {
                }
                field("Posting Group"; Rec."Posting Group")
                {
                }
                field("Attachment Enforcement"; Rec."Attachment Enforcement")
                {
                }
                field(AttachmentEnforcementLimit; Rec."Amount Limit for No Receipt")
                {
                    Enabled = Rec."Attachment Enforcement" = Rec."Attachment Enforcement"::"Not needed under limit";
                }
                field("Default Payment Method"; Rec."Default Payment Method")
                {
                }
                field("Expense Group"; Rec."Expense Group")
                {
                }
                field(Inactive; Rec.Inactive)
                {
                }
                field("Prepayment - Cash Advance"; Rec."Prepayment-Cash Advance")
                {
                }
                field(Refundable; Rec.Refundable)
                {
                }
                field("Reimbursement Type"; Rec."Reimbursement Type")
                {
                }
                field("Expense Detail Required"; Rec."Expense Detail Required")
                {
                }
            }
        }
    }
    actions
    {
        area(Navigation)
        {
            group("Category")
            {
                Caption = 'Category';
                Image = Category;
                action(Subcategories)
                {
                    Caption = 'Subcategories';
                    Image = Description;
                    RunObject = Page "Expense Subcategories";
                    RunPageLink = "Expense Category Code" = field(Code);
                    ToolTip = 'Opens the Subcategories page to view and manage subcategories for this category.';
                    Scope = Repeater;
                }
                action(Policies)
                {
                    Caption = 'Policies';
                    Image = SetupList;
                    RunObject = Page "Expense Policies";
                    RunPageLink = "Expense Category Code" = field(Code);
                    ToolTip = 'Opens the Policies page to view and manage policies for this category.';
                    Scope = Repeater;
                }
            }
        }
        area(Promoted)
        {
            actionref("Subcategories_Promoted"; Subcategories) { }
            actionref("Policies_Promoted"; Policies) { }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if not IsDeletingCategory then
            if Rec."Expense Detail Required" = Rec."Expense Detail Required"::Itemize then
                CheckShowConfirmationForSubCategories(Rec);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        IsDeletingCategory := true;
    end;

    var
        IsDeletingCategory: Boolean;
        ContinueWithMissingSubcategoryQst: Label 'You have not added any subcategories for expense category %1 where %2 is %3.\\ It will be required to be added before you can use this expense category.\\ Do you want to continue without adding subcategories ?', Comment = '%1 - Expense Category Code, %2 - Field Name "Expense Detail Required", %3 - Expense Detail Required';

    local procedure CheckShowConfirmationForSubCategories(ExpenseCategory: Record "Expense Category")
    var
        ExpenseSubcategory: Record "Expense Subcategory";
        ConfirmManagement: Codeunit "Confirm Management";
    begin
        if ExpenseCategory.Code = '' then
            exit;

        ExpenseSubcategory.SetRange("Expense Category Code", ExpenseCategory.Code);
        if ExpenseSubcategory.IsEmpty() then
            if not ConfirmManagement.GetResponseOrDefault(StrSubstNo(ContinueWithMissingSubcategoryQst, ExpenseCategory.Code, ExpenseCategory.FieldCaption("Expense Detail Required"), ExpenseCategory."Expense Detail Required"), true) then
                Error('');
    end;
}