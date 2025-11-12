// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

page 480 "Edit Dimension Set Entries"
{
    Caption = 'Edit Dimension Set Entries';
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Dimension Set Entry";
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
                    Editable = Rec."Dimension Value Code" = '';
                    ToolTip = 'Specifies the dimension.';
                }
                field("Dimension Name"; Rec."Dimension Name")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the descriptive name of the Dimension Code field.';
                    Visible = false;
                }
                field(DimensionValueCode; Rec."Dimension Value Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the dimension value.';
                }
                field("Dimension Value Name"; Rec."Dimension Value Name")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the descriptive name of the Dimension Value Code field.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnClosePage()
    begin
        DimSetID := DimMgt.GetDimensionSetID(Rec);
    end;

    trigger OnOpenPage()
    begin
        DimSetID := Rec.GetRangeMin("Dimension Set ID");
        DimMgt.GetDimensionSet(Rec, DimSetID);
        if FormCaption <> '' then
            CurrPage.Caption := FormCaption;
    end;

    var
        DimMgt: Codeunit DimensionManagement;
        DimSetID: Integer;
        FormCaption: Text[250];

    procedure GetDimensionID(): Integer
    begin
        exit(DimSetID);
    end;

    procedure SetFormCaption(NewFormCaption: Text[250])
    begin
        FormCaption := CopyStr(NewFormCaption + ' - ' + CurrPage.Caption, 1, MaxStrLen(FormCaption));
    end;
}

