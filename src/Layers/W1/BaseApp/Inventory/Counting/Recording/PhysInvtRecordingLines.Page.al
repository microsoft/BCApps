// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Recording;

page 5882 "Phys. Invt. Recording Lines"
{
    Caption = 'Phys. Invt. Recording Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Phys. Invt. Record Line";

    layout
    {
        area(content)
        {
            repeater(Control40)
            {
                ShowCaption = false;
                field("Order No."; Rec."Order No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the order number.';
                }
                field("Recording No."; Rec."Recording No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a number that is assigned to the physical inventory recording.';
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the line.';
                    Visible = false;
                }
                field("Order Line No."; Rec."Order Line No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Line No. of the linked physical inventory order line.';
                    Visible = false;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the number of the item that was counted when taking the physical inventory.';
                }
                field("Item Reference No."; Rec."Item Reference No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies a reference to the item number as defined by the item''s barcode.';
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
                    ToolTip = 'Specifies the additional description of the item.';
                    Visible = false;
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the unit of measure used for the item, for example bottle or piece.';
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies how each unit of the item or resource is measured, such as in pieces or hours. By default, the value in the Base Unit of Measure field on the item or resource card is inserted.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the location where the item was counted during taking the physical inventory.';
                }
                field("Use Item Tracking"; Rec."Use Item Tracking")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies if it is necessary to record the item using serial, lot or package numbers.';
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the serial number of the entered item.';
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the lot number of the entered item.';
                }
                field("Package No."; Rec."Package No.")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the package number of the entered item.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the quantity of the item of the physical inventory recording line.';
                }
                field("Quantity (Base)"; Rec."Quantity (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Quantity on the line, expressed in base units of measure.';
                    Visible = false;
                }
                field(Recorded; Rec.Recorded)
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies if a value was entered in Quantity of the physical inventory recording line.';
                }
                field("Date Recorded"; Rec."Date Recorded")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the date when the physical inventory was taken.';
                    Visible = false;
                }
                field("Time Recorded"; Rec."Time Recorded")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the time when the physical inventory was taken.';
                    Visible = false;
                }
                field("Person Recorded"; Rec."Person Recorded")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the code of the person who performed the physical inventory.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
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
                    RunObject = Page "Phys. Inventory Recording";
                    RunPageLink = "Order No." = field("Order No."),
                                  "Recording No." = field("Recording No.");
                    RunPageView = sorting("Order No.", "Recording No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Show inventory count recording.';
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

