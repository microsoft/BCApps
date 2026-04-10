// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.History;

page 5886 "Posted Phys. Invt. Order Lines"
{
    Caption = 'Posted Phys. Invt. Order Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Pstd. Phys. Invt. Order Line";

    layout
    {
        area(content)
        {
            repeater(Control40)
            {
                ShowCaption = false;
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Base Unit of Measure Code"; Rec."Base Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("Qty. Expected (Base)"; Rec."Qty. Expected (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the expected inventory quantity in the base unit of measure on the physical inventory order line.';
                }
                field("Qty. Recorded (Base)"; Rec."Qty. Recorded (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Qty. Recorded (Base) of the physical inventory order line.';
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = Warehouse;
                }
                field("Quantity (Base)"; Rec."Quantity (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity in the base unit of measure on the physical inventory order line.';
                }
                field("No. Finished Rec.-Lines"; Rec."No. Finished Rec.-Lines")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how many finished physical inventory recording lines exist for the physical inventory order line.';
                }
                field("Recorded Without Order"; Rec."Recorded Without Order")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Unit Amount"; Rec."Unit Amount")
                {
                    ApplicationArea = Warehouse;
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Shelf No."; Rec."Shelf No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the shelf number of the item on the physical inventory order line.';
                    Visible = false;
                }
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
                action("Show Document")
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Show Document';
                    Image = View;
                    RunObject = Page "Posted Phys. Invt. Order";
                    RunPageLink = "No." = field("Document No.");
                    RunPageView = sorting("No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Open the document that the selected line exists on.';
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Show Document_Promoted"; "Show Document")
                {
                }
            }
        }
    }
}

