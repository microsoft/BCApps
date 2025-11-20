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
                    ToolTip = 'Specifies the number of the item in the requisition line for which untracked planning surplus exists.';
                    Visible = false;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Location;
                    ToolTip = 'Specifies the location code in the requisition line associated with the untracked planning surplus.';
                    Visible = false;
                }
                field(Source; Rec.Source)
                {
                    ApplicationArea = Planning;
                    StyleExpr = SourceEmphasize;
                    ToolTip = 'Specifies what the source of this untracked surplus quantity is.';
                }
                field("Source ID"; Rec."Source ID")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the identification code for the source of the untracked planning quantity.';
                    Visible = false;
                }
                field("Parameter Value"; Rec."Parameter Value")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the value of this planning parameter.';
                }
                field("Track Quantity From"; Rec."Track Quantity From")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies how much the total surplus quantity is, including the quantity from this entry.';
                    Visible = false;
                }
                field("Untracked Quantity"; Rec."Untracked Quantity")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies how much this planning parameter contributed to the total surplus quantity.';
                }
                field("Track Quantity To"; Rec."Track Quantity To")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies what the surplus quantity would be without the quantity from this entry.';
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

