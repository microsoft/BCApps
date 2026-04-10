// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Planning;

page 99000861 "Planning Component List"
{
    Caption = 'Planning Component List';
    DataCaptionExpression = Rec.Caption();
    Editable = false;
    PageType = List;
    SourceTable = "Planning Component";

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
                field("Due Date"; Rec."Due Date")
                {
                    ApplicationArea = Planning;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Planning;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Calculation Formula"; Rec."Calculation Formula")
                {
                    ApplicationArea = Planning;
                }
                field(Length; Rec.Length)
                {
                    ApplicationArea = Planning;
                }
                field(Width; Rec.Width)
                {
                    ApplicationArea = Planning;
                }
                field(Weight; Rec.Weight)
                {
                    ApplicationArea = Planning;
                }
                field(Depth; Rec.Depth)
                {
                    ApplicationArea = Planning;
                }
                field("Quantity per"; Rec."Quantity per")
                {
                    ApplicationArea = Planning;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Expected Quantity"; Rec."Expected Quantity")
                {
                    ApplicationArea = Planning;
                }
                field("Expected Quantity (Base)"; Rec."Expected Quantity (Base)")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the contents of the Expected Quantity field on the line, in base units of measure.';
                }
                field("Shortcut Dimension 1 Code"; Rec."Shortcut Dimension 1 Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Shortcut Dimension 2 Code"; Rec."Shortcut Dimension 2 Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Cost Amount"; Rec."Cost Amount")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field(Position; Rec.Position)
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Position 2"; Rec."Position 2")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Position 3"; Rec."Position 3")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Lead-Time Offset"; Rec."Lead-Time Offset")
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
        area(navigation)
        {
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action("Item &Tracking Lines")
                {
                    ApplicationArea = Planning;
                    Caption = 'Item &Tracking Lines';
                    Image = ItemTrackingLines;
                    ShortCutKey = 'Ctrl+Alt+I';
                    ToolTip = 'View or edit serial, lot and package numbers that are assigned to the item on the document or journal line.';

                    trigger OnAction()
                    begin
                        Rec.OpenItemTrackingLines();
                    end;
                }
            }
        }
    }
}

