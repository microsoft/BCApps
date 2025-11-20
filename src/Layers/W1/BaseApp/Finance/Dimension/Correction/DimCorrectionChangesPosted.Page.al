// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension.Correction;

using Microsoft.Finance.Dimension;

page 2581 "Dim Correction Changes Posted"
{
    PageType = ListPart;
    DeleteAllowed = false;
    Editable = false;
    SourceTable = "Dim Correction Change";
    MultipleNewLines = false;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(DimensionCode; Rec."Dimension Code")
                {
                    ApplicationArea = All;
                    Caption = 'Dimension Code';
                    ToolTip = 'Specifies the code of the dimension change.';
                    StyleExpr = FieldStyle;
                }

                field(DimensionValueCode; DimensionValueText)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Dimension Value Code';
                    ToolTip = 'Specifies the current value of the dimension changed.';
                    StyleExpr = FieldStyle;
                }

                field(NewValue; NewValueText)
                {
                    ApplicationArea = All;
                    TableRelation = "Dimension Value".Code where("Dimension Code" = field("Dimension Code"));
                    Caption = 'New Dimension Value Code';
                    ToolTip = 'Specifies the new value for the dimension';
                    StyleExpr = FieldStyle;
                    Editable = false;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        UpdateRow();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateRow();
    end;

    local procedure UpdateRow()
    begin
        SetNewValueDisplayText();
        SetDimensionValueDisplayText();
        SetStyleAndEditableControls();
    end;

    local procedure SetNewValueDisplayText()
    begin
        NewValueText := Format(Rec."Change Type");
        if Rec."Change Type" in [Rec."Change Type"::Add, Rec."Change Type"::Change] then begin
            if Rec."Change Type" = Rec."Change Type"::Add then
                if Rec."New Value" = '' then begin
                    NewValueText := '';
                    exit;
                end;
            NewValueText := StrSubstNo(NewValueDisplayTextPlaceHolderLbl, NewValueText, Rec."New Value")
        end;
    end;

    local procedure SetDimensionValueDisplayText()
    begin
        DimensionValueText := '';

        if Rec."Change Type" = Rec."Change Type"::Add then
            exit;

        if Rec."Dimension Value Count" > 0 then
            DimensionValueText := StrSubstNo(DimensionValueDisplayTxt, Rec."Dimension Value Count");

        if Rec."Dimension Value" <> '' then
            DimensionValueText := Rec."Dimension Value";
    end;

    local procedure SetStyleAndEditableControls()
    begin
        if Rec."Change Type" = Rec."Change Type"::"No Change" then
            FieldStyle := 'Standard'
        else
            FieldStyle := 'Strong';
    end;

    var
        FieldStyle: Text;
        DimensionValueText: Text;
        NewValueText: Text;
        NewValueDisplayTextPlaceHolderLbl: Label '%1 - %2', Locked = true, Comment = '%1 Change type, %2 New value';
        DimensionValueDisplayTxt: Label 'Multiple - Number of different values (%1)', Comment = '%1 Number of different dimension values';
}
