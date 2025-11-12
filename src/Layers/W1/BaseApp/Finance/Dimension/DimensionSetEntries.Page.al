// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

page 479 "Dimension Set Entries"
{
    Caption = 'Dimension Set Entries';
    Editable = false;
    PageType = List;
    SourceTable = "Dimension Set Entry";

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
        area(Processing)
        {
            action(UpdDimSetGlblDimNo)
            {
                ApplicationArea = Dimensions;
                Caption = 'Update Shortcut Dimension No.';
                Image = ChangeDimensions;
                ToolTip = 'Fix incorrect settings for one or more global or shortcut dimensions.';
                Visible = UpdDimSetGlblDimNoVisible;

                trigger OnAction()
                begin
                    Report.Run(Report::"Update Dim. Set Glbl. Dim. No.");
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(UpdDimSetGlblDimNo_Promoted; UpdDimSetGlblDimNo)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if FormCaption <> '' then
            CurrPage.Caption := FormCaption;
    end;

    var
        FormCaption: Text[250];

    procedure SetFormCaption(NewFormCaption: Text[250])
    begin
        FormCaption := CopyStr(NewFormCaption + ' - ' + CurrPage.Caption, 1, MaxStrLen(FormCaption));
    end;

    procedure SetUpdDimSetGlblDimNoVisible()
    begin
        UpdDimSetGlblDimNoVisible := true;
    end;

    var
        UpdDimSetGlblDimNoVisible: Boolean;
}

