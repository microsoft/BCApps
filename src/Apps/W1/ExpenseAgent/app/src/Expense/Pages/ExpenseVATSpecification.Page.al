// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 7084 "Expense VAT Specification"
{
    Caption = 'Expense VAT Specification';
    PageType = List;
    SourceTable = "Expense VAT Specification";
    ApplicationArea = All;
    UsageCategory = None;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Expense No."; Rec."Expense No.")
                {
                    Visible = false;
                }
                field("Line No."; Rec."Line No.")
                {
                    Visible = false;
                }
                field("Expense Category"; Rec."Expense Category")
                {
                }
                field("Expense Subcategory"; Rec."Expense Subcategory")
                {
                }
                field("VAT Bus. Posting Group"; Rec."VAT Bus. Posting Group")
                {
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                }
                field("VAT %"; Rec."VAT %")
                {
                }
                field("Amount"; Rec."Amount")
                {
                }
                field("VAT Base Amount"; Rec."VAT Base Amount")
                {
                }
                field("VAT Amount"; Rec."VAT Amount")
                {
                }
                field("Amount (LCY)"; Rec."Amount (LCY)")
                {
                }
                field("VAT Base Amount (LCY)"; Rec."VAT Base Amount (LCY)")
                {
                }
                field("VAT Amount (LCY)"; Rec."VAT Amount (LCY)")
                {
                }
                field(Source; Rec.Source)
                {
                }
            }
        }
    }

}
