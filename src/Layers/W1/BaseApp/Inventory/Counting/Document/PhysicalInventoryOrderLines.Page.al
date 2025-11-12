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
                    ToolTip = 'Specifies the document number.';
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the line.';
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
                    ToolTip = 'Specifies the variant of the item on the line.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the description of the item.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies an additional description of the item.';
                    Visible = false;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the location where the item must be counted.';
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the unit of measure, such as bottle or piece, that is currently used for the item.';
                    Visible = false;
                }
                field("Base Unit of Measure Code"; Rec."Base Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the unit of measure, such as bottle or piece, that is currently used for the item.';
                }
                field("Qty. Expected (Base)"; Rec."Qty. Expected (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the expected inventory quantity in the base unit of measure.';
                }
                field("Qty. Exp. Calculated"; Rec."Qty. Exp. Calculated")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies if the Qty. Expected (Base) field has been updated with the Calculate Expected Qty. function.';
                }
                field("Qty. Recorded (Base)"; Rec."Qty. Recorded (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the counted quantity in the base unit of measure on the physical inventory order line.';
                }
                field("On Recording Lines"; Rec."On Recording Lines")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies if the item exists on one or more physical inventory recording lines.';
                }
                field("No. Finished Rec.-Lines"; Rec."No. Finished Rec.-Lines")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how many of the related physical inventory recordings are closed.';
                }
                field("Recorded Without Order"; Rec."Recorded Without Order")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies whether the Inventory Order Line was automatically created by finishing a Phys. Inventory.';
                    Visible = false;
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies if the difference in the Quantity (Base) field on the related closed recording is positive or negative.';
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
                    ToolTip = 'Specifies the unit costs of the item, which will be used when posting the physical inventory.';
                    Visible = false;
                }
                field("Shelf No."; Rec."Shelf No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the shelf number where the item can be found normally.';
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

