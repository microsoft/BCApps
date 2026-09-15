// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

page 6970 "Exp. Locations Preview"
{
    Caption = 'Expense locations';
    PageType = List;
    ApplicationArea = Basic, Suite;
    SourceTable = "Expense Location";
    SourceTableTemporary = true;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    RefreshOnActivate = true;
    Extensible = false;
    InstructionalText = 'Lists existing expense locations together with the defaults that will be created when you apply the setup.';

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("No."; Rec."No.")
                {
                    ToolTip = 'Specifies the location code.';
                    StyleExpr = StyleExpr;
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies a short description of the location.';
                }
                field("Country/Region Code"; Rec."Country/Region Code")
                {
                    ToolTip = 'Specifies the country or region of the location.';
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
        ExpenseLocation: Record "Expense Location";
    begin
        if ExpenseLocation.Get(Rec."No.") then begin
            StatusText := ExistingLbl;
            StyleExpr := '';
        end else begin
            StatusText := NewLbl;
            StyleExpr := 'Favorable';
        end;
    end;

    local procedure ReloadPreview()
    var
        TempExpenseLocation: Record "Expense Location" temporary;
        CreateExpenseCategories: Codeunit "Create Expense Categories";
    begin
        CreateExpenseCategories.LoadLocationsPreview(TempExpenseLocation);

        Rec.Reset();
        Rec.DeleteAll();

        TempExpenseLocation.Reset();
        if TempExpenseLocation.FindSet() then
            repeat
                Rec := TempExpenseLocation;
                Rec.Insert();
            until TempExpenseLocation.Next() = 0;

        if Rec.FindFirst() then;
    end;

    var
        StatusText: Text;
        StyleExpr: Text;
        NewLbl: Label 'New';
        ExistingLbl: Label 'Existing';
}
