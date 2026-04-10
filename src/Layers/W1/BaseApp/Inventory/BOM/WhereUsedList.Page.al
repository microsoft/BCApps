// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.BOM;

page 37 "Where-Used List"
{
    Caption = 'Where-Used List';
    DataCaptionFields = "No.";
    Editable = false;
    PageType = List;
    RefreshOnActivate = true;
    SourceTable = "BOM Component";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Parent Item No."; Rec."Parent Item No.")
                {
                    ApplicationArea = Assembly;
                }
                field("BOM Description"; Rec."BOM Description")
                {
                    ApplicationArea = Assembly;
                    DrillDown = false;
                }
                field("Quantity per"; Rec."Quantity per")
                {
                    ApplicationArea = Assembly;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Assembly;
                }
                field(Position; Rec.Position)
                {
                    ApplicationArea = Assembly;
                }
                field("Position 2"; Rec."Position 2")
                {
                    ApplicationArea = Assembly;
                    Visible = false;
                }
                field("Position 3"; Rec."Position 3")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Machine No."; Rec."Machine No.")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Lead-Time Offset"; Rec."Lead-Time Offset")
                {
                    ApplicationArea = Assembly;
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
}

