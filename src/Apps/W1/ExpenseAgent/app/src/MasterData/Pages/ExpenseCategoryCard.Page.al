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
                    ToolTip = 'Specifies the code for expense category.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies a concise description that identifies the purpose or usage of this expense category.';
                }
                field("Posting Description"; Rec."Posting Description")
                {
                    ToolTip = 'Specifies the description used for posting to the general ledger.';
                }
                field("Posting Group"; Rec."Posting Group")
                {
                    ToolTip = 'Specifies the posting group on the expense category that is used for accounting. The posting group links expense transactions to general ledger accounts.';
                }
                field("Attachment Enforcement"; Rec."Attachment Enforcement")
                {
                    ToolTip = 'Specifies whether an attachment is required for expenses in this category.';
                }
                field("Default Payment Method"; Rec."Default Payment Method")
                {
                    ToolTip = 'Specifies the default payment method applied to expenses in this category.';
                }
                field("Expense Group"; Rec."Expense Group")
                {
                    ToolTip = 'Specifies the expense group for classification.';
                }
                field(Inactive; Rec.Inactive)
                {
                    ToolTip = 'Specifies whether the category is inactive. If inactive, the category can''t be used on new expenses.';
                }
                field("Prepayment - Cash Advance"; Rec."Prepayment-Cash Advance")
                {
                    ToolTip = 'Specifies whether expenses in this category require prepayment or cash advance.';
                }
                field(Refundable; Rec.Refundable)
                {
                    ToolTip = 'Specifies whether expenses in this category are refundable by default. This can be changed on the expense report.';
                }
                field("Reimbursement Type"; Rec."Reimbursement Type")
                {
                    ToolTip = 'Specifies how expenses in this category are reimbursed.';
                }
                field("Expense Detail Required"; Rec."Expense Detail Required")
                {
                    ToolTip = 'Specifies additional details required for expenses in the category, such as itemization, per-diem, or participants.';
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
            }
        }
        area(Promoted)
        {
            actionref("Subcategories_Promoted"; Subcategories) { }
        }
    }

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if Rec."Expense Detail Required" = Rec."Expense Detail Required"::Itemize then
            CheckShowConfirmationForSubCategories(Rec);
    end;

    var
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