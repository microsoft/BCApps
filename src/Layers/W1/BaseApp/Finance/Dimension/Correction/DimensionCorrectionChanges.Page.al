// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension.Correction;

using Microsoft.Finance.Dimension;

page 2590 "Dimension Correction Changes"
{
    PageType = ListPart;
    DeleteAllowed = false;
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
                    StyleExpr = FieldStyle;
                    ToolTip = 'Specifies the Dimension Code.';
                }

                field(DimensionValueCode; DimensionValueText)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Dimension Value Code';
                    StyleExpr = FieldStyle;
                    ToolTip = 'Specifies the current Dimension Value Code.';

                    trigger OnDrillDown()
                    var
                        DimensionValue: Record "Dimension Value";
                        DimensionValueIDFilter: Text;
                    begin
                        DimensionValueIDFilter := Rec.GetDimensionValues();
                        if DimensionValueIDFilter = '' then
                            exit;

                        DimensionValue.SetFilter("Dimension Value Id", DimensionValueIDFilter);
                        Page.RunModal(Page::"Dim Corr Values Overview", DimensionValue);
                    end;
                }

                field(NewValue; NewValueText)
                {
                    ApplicationArea = All;
                    TableRelation = "Dimension Value".Code where("Dimension Code" = field("Dimension Code"));
                    Caption = 'New Dimension Value Code';
                    ToolTip = 'Specifies the new value for the dimension';
                    StyleExpr = FieldStyle;
                    Editable = NewValueEditable;

                    trigger OnValidate()
                    begin
                        Rec.Validate("New Value", NewValueText);
                        Rec.Modify();
                        UpdateRow();
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RevertAll)
            {
                ApplicationArea = All;
                Image = Undo;
                Caption = 'Revert All Changes';
                ToolTip = 'Revert all changes made to the dimensions.';

                trigger OnAction()
                begin
                    VerifyCanChangePart();
                    Rec.SetRange("Change Type", Rec."Change Type"::Add);
                    Rec.DeleteAll();
                    Rec.SetRange("Change Type");
                    Rec.ModifyAll(Rec."Change Type", Rec."Change Type"::"No Change", true);
                    CurrPage.Update(false);
                end;
            }

            action(DeleteRow)
            {
                ApplicationArea = All;
                Scope = Repeater;
                Image = Delete;
                Caption = 'Remove Dimension';
                ToolTip = 'Remove the dimension.';

                trigger OnAction()
                begin
                    VerifyCanChangePart();
                    Rec.Validate("Change Type", Rec."Change Type"::Remove);
                    Rec.Modify();
                    UpdateRow();
                end;
            }

            action(RevertRow)
            {
                ApplicationArea = All;
                Scope = Repeater;
                Image = Undo;
                Caption = 'Revert Change';
                ToolTip = 'Revert the selected dimension change.';

                trigger OnAction()
                begin
                    VerifyCanChangePart();
                    Rec.Validate("Change Type", Rec."Change Type"::"No Change");
                    Rec.Modify();
                    UpdateRow();
                end;
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

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Change Type" := Rec."Change Type"::Add;
        Clear(Rec."Dimension Code");
    end;

    local procedure UpdateRow()
    begin
        SetNewValueDisplayText();
        SetDimensionValueDisplayText();
        SetStyleAndEditableControls();
    end;

    local procedure VerifyCanChangePart()
    var
        DimensionCorrectionMgt: Codeunit "Dimension Correction Mgt";
    begin
        DimensionCorrectionMgt.VerifyCanModifyDraftEntry(Rec."Dimension Correction Entry No.");
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

        if Rec."Dimension Value Count" > 1 then
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

        NewValueEditable := Rec."Change Type" in [Rec."Change Type"::Add, Rec."Change Type"::Change, Rec."Change Type"::"No Change"];
    end;

    var
        FieldStyle: Text;
        NewValueEditable: Boolean;
        DimensionValueText: Text;
        NewValueText: Text;
        NewValueDisplayTextPlaceHolderLbl: Label '%1 - %2', Locked = true, Comment = '%1 Change type, %2 New value';
        DimensionValueDisplayTxt: Label 'Multiple - Number of different values (%1)', Comment = '%1 Number of different dimension values';
}
