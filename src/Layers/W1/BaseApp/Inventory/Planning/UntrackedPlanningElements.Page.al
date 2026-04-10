// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Planning;

page 99000855 "Untracked Planning Elements"
{
    Caption = 'Untracked Planning Elements';
    DataCaptionExpression = CaptionText;
    Editable = false;
    PageType = List;
    SourceTable = "Untracked Planning Element";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    Visible = false;
                }
                field(Source; Rec.Source)
                {
                    ApplicationArea = Planning;
                    StyleExpr = SourceEmphasize;
                }
                field("Source ID"; Rec."Source ID")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Parameter Value"; Rec."Parameter Value")
                {
                    ApplicationArea = Planning;
                }
                field("Track Quantity From"; Rec."Track Quantity From")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Untracked Quantity"; Rec."Untracked Quantity")
                {
                    ApplicationArea = Planning;
                }
                field("Track Quantity To"; Rec."Track Quantity To")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        FormatLine();
    end;

    var
        CaptionText: Text;
        SourceEmphasize: Text;

    procedure SetCaption(NewCaption: Text)
    begin
        CaptionText := NewCaption;
    end;

    local procedure FormatLine()
    begin
        if Rec."Warning Level" > 0 then
            SourceEmphasize := 'Strong'
        else
            SourceEmphasize := '';
    end;
}

