// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

page 484 "Edit Reclas. Dimensions"
{
    Caption = 'Edit Reclas. Dimensions';
    PageType = List;
    SourceTable = "Reclas. Dimension Set Buffer";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Dimension Code"; Rec."Dimension Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies a dimension code to attach a dimension to a journal line.';
                }
                field("Dimension Name"; Rec."Dimension Name")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the descriptive name of the Dimension Code field.';
                    Visible = false;
                }
                field("Dimension Value Code"; Rec."Dimension Value Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the original dimension value to register the transfer of items from the original dimension value to the new dimension value.';
                }
                field("New Dimension Value Code"; Rec."New Dimension Value Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the new dimension value to register the transfer of items, from the original dimension value to the new dimension value.';
                }
                field("Dimension Value Name"; Rec."Dimension Value Name")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the descriptive name of the original Dimension Value Code field.';
                }
                field("New Dimension Value Name"; Rec."New Dimension Value Name")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the descriptive name of the New Dimension Value Code field.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        if FormCaption <> '' then
            CurrPage.Caption := FormCaption;
    end;

    var
        FormCaption: Text[250];

    procedure GetDimensionIDs(var DimSetID: Integer; var NewDimSetId: Integer)
    begin
        DimSetID := Rec.GetDimSetID(Rec);
        NewDimSetId := Rec.GetNewDimSetID(Rec);
    end;

    procedure SetDimensionIDs(DimSetID: Integer; NewDimSetId: Integer)
    var
        DimSetEntry: Record "Dimension Set Entry";
    begin
        Rec.DeleteAll();
        DimSetEntry.SetRange("Dimension Set ID", DimSetID);
        if DimSetEntry.FindSet() then
            repeat
                Rec."Dimension Code" := DimSetEntry."Dimension Code";
                Rec."Dimension Value Code" := DimSetEntry."Dimension Value Code";
                Rec."Dimension Value ID" := DimSetEntry."Dimension Value ID";
                Rec.Insert();
            until DimSetEntry.Next() = 0;
        DimSetEntry.SetRange("Dimension Set ID", NewDimSetId);
        if DimSetEntry.FindSet() then
            repeat
                if not Rec.Get(DimSetEntry."Dimension Code") then begin
                    Rec."Dimension Code" := DimSetEntry."Dimension Code";
                    Rec."Dimension Value Code" := '';
                    Rec."Dimension Value ID" := 0;
                    Rec.Insert();
                end;
                Rec."New Dimension Value Code" := DimSetEntry."Dimension Value Code";
                Rec."New Dimension Value ID" := DimSetEntry."Dimension Value ID";
                Rec.Modify();
            until DimSetEntry.Next() = 0;
    end;

    procedure SetFormCaption(NewFormCaption: Text[250])
    begin
        FormCaption := CopyStr(NewFormCaption + ' - ' + CurrPage.Caption, 1, MaxStrLen(FormCaption));
    end;
}

