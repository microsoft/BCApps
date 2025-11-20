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
                    ToolTip = 'Specifies the number of the assembly item that the assembly BOM component belongs to.';
                }
                field("BOM Description"; Rec."BOM Description")
                {
                    ApplicationArea = Assembly;
                    DrillDown = false;
                    ToolTip = 'Specifies a description of the assembly BOM if the item on the line is an assembly BOM.';
                }
                field("Quantity per"; Rec."Quantity per")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how many units of the component are required to assemble or produce the parent item.';
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field(Position; Rec.Position)
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the position of the component on the bill of material.';
                }
                field("Position 2"; Rec."Position 2")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the component''s position in the assembly BOM structure.';
                    Visible = false;
                }
                field("Position 3"; Rec."Position 3")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the third reference number for the component position on a bill of material, such as the alternate position number of a component on a print card.';
                    Visible = false;
                }
                field("Machine No."; Rec."Machine No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies a machine that should be used when processing the component on this line of the assembly BOM.';
                    Visible = false;
                }
                field("Lead-Time Offset"; Rec."Lead-Time Offset")
                {
                    ApplicationArea = Assembly;
                    ToolTip = 'Specifies the total number of days required to assemble the item on the assembly BOM line.';
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

