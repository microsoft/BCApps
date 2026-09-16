// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6946 "Expense Categories"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Expense Categories';
    PageType = List;
    CardPageID = "Expense Category Card";
    Editable = false;
    UsageCategory = Administration;
    RefreshOnActivate = true;
    SourceTable = "Expense Category";

    AboutTitle = 'About expense categories';
    AboutText = 'An expense category represents a type of expense that an employee can incur on the company''s behalf and select when registering an expense. For each category, you can set posting groups, payment methods, refundability, and detail requirements. They can be used in expense management rules and include subcategories for more specific classifications.';
    AdditionalSearchTerms = 'Expense Type, Category, Expense Class, Expense Classification, Expense Purpose, Spend Category';

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Code"; Rec."Code")
                {
                    ToolTip = 'Specifies the category code.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the category description.';
                }
                field("Posting Group"; Rec."Posting Group")
                {
                    ToolTip = 'Specifies the posting group used for accounting.';
                }
                field("Default Payment Method"; Rec."Default Payment Method")
                {
                    ToolTip = 'Specifies the default payment method for this category.';
                }
                field(Refundable; Rec.Refundable)
                {
                    ToolTip = 'Specifies whether expenses in this category are refundable.';
                }
                field("Expense Detail Required"; Rec."Expense Detail Required")
                {
                    ToolTip = 'Specifies the detail required for expenses, such as itemization or participants.';
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ToolTip = 'Specifies the VAT product posting group for this category.';
                    Visible = AllowVATReclaim;
                }
                field("Default VAT %"; Rec."Default VAT %")
                {
                    ToolTip = 'Specifies the default VAT percentage for this category.';
                    Visible = AllowVATReclaim;
                }
                field("Default VAT Reclaim %"; Rec."Default VAT Reclaim %")
                {
                    ToolTip = 'Specifies the default VAT reclaim percentage for this category.';
                    Visible = AllowVATReclaim;
                }
            }
        }
    }
    actions
    {
        area(navigation)
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

    trigger OnOpenPage()
    begin
        ExpenseAgentSetup.Get();
        AllowVATReclaim := ExpenseAgentSetup."Allow VAT Reclaim";
    end;

    var
        ExpenseAgentSetup: Record "Expense Agent Setup";
        AllowVATReclaim: Boolean;
}