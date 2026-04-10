// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.History;

page 5890 "Posted Phys. Invt. Rec. Lines"
{
    Caption = 'Posted Phys. Invt. Rec. Lines';
    Editable = false;
    PageType = List;
    SourceTable = "Pstd. Phys. Invt. Record Line";

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
                }
                field("Recording No."; Rec."Recording No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Order Line No."; Rec."Order Line No.")
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
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = Warehouse;
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = Warehouse;
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = Warehouse;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = Warehouse;
                }
                field("Quantity (Base)"; Rec."Quantity (Base)")
                {
                    ApplicationArea = Warehouse;
                    ToolTip = 'Specifies the Quantity (Base) of the table physical inventory recording line.';
                    Visible = false;
                }
                field("Date Recorded"; Rec."Date Recorded")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Time Recorded"; Rec."Time Recorded")
                {
                    ApplicationArea = Warehouse;
                    Visible = false;
                }
                field("Person Recorded"; Rec."Person Recorded")
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
                    RunObject = Page "Posted Phys. Invt. Recording";
                    RunPageLink = "Order No." = field("Order No."),
                                  "Recording No." = field("Recording No.");
                    RunPageView = sorting("Order No.", "Recording No.");
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'Show posted inventory count order recording.';
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

