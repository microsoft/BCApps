// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6967 "Exp. Subcategories Preview"
{
    Caption = 'Subcategories';
    PageType = ListPart;
    ApplicationArea = Basic, Suite;
    SourceTable = "Expense Subcategory";
    SourceTableTemporary = true;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Code"; Rec."Code")
                {
                    ToolTip = 'Specifies the subcategory code.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies a short description of the subcategory.';
                }
                field("Posting Description"; Rec."Posting Description")
                {
                    ToolTip = 'Specifies the description used when posting.';
                }
                field(Refundable; Rec.Refundable)
                {
                    ToolTip = 'Specifies whether the subcategory is refundable.';
                }
                field("Expense Description Mandatory"; Rec."Expense Description Mandatory")
                {
                    ToolTip = 'Specifies whether an expense description is mandatory.';
                }
            }
        }
    }

    internal procedure Load(var TempSubcategory: Record "Expense Subcategory" temporary)
    begin
        Rec.Reset();
        Rec.DeleteAll();

        if TempSubcategory.FindSet() then
            repeat
                Rec := TempSubcategory;
                Rec.Insert();
            until TempSubcategory.Next() = 0;

        if Rec.FindFirst() then;
        CurrPage.Update(false);
    end;
}
