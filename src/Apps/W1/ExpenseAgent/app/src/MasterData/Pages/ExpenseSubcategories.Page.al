// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6973 "Expense Subcategories"
{
    Caption = 'Expense Subcategories';
    PageType = List;
    ApplicationArea = Basic, Suite;
    SourceTable = "Expense Subcategory";

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Code"; Rec."Code")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field("Posting Description"; Rec."Posting Description")
                {
                }
                field("Expense Description Mandatory"; Rec."Expense Description Mandatory")
                {
                }
                field(Inactive; Rec.Inactive)
                {
                }
                field(Refundable; Rec.Refundable)
                {
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                }
                field("Default VAT %"; Rec."Default VAT %")
                {
                }
                field("Default VAT Reclaim %"; Rec."Default VAT Reclaim %")
                {
                }
            }
        }
    }
}