// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Document;

page 5878 "Physical Inventory Order Lines"
{
    Caption = 'Physical Inventory Order Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Phys. Invt. Order Line";

    layout
    {
        area(content)
        {
            repeater(Control2)
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
                    ToolTip = 'Specifies the item to be counted.';
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
                    ToolTip = 'Specifies the expected inventory quantity in the base unit of measure.';
                }
                field("Qty. Exp. Calculated"; Rec."Qty. Exp. Calculated")
                {
                    ApplicationArea = Warehouse;
                }
                field("Qty. Recorded (Base)"; Rec."Qty. Recorded (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the counted quantity in the base unit of measure on the physical inventory order line.';
                }
                field("On Recording Lines"; Rec."On Recording Lines")
                {
                    ApplicationArea = Warehouse;
                }
                field("No. Finished Rec.-Lines"; Rec."No. Finished Rec.-Lines")
                {
                    ApplicationArea = Warehouse;
                }
                field("Recorded Without Order"; Rec."Recorded Without Order")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = Warehouse;
                }
                field("Quantity (Base)"; Rec."Quantity (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the difference between the Qty. Expected (Base) and the Qty. Recorded (Base) fields.';
                }
                field("Unit Amount"; Rec."Unit Amount")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the sum of unit costs for the item quantity on the line.';
                }
                field("Unit Cost"; Rec."Unit Cost")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Shelf No."; Rec."Shelf No.")
                {
                    ApplicationArea = Warehouse;
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
                    RunObject = Page "Physical Inventory Order";
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

