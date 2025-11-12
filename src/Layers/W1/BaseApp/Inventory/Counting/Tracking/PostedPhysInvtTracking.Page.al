// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Tracking;

page 5894 "Posted Phys. Invt. Tracking"
{
    Caption = 'Posted Phys. Invt. Tracking';
    Editable = false;
    PageType = List;
    SourceTable = "Pstd. Phys. Invt. Tracking";

    layout
    {
        area(content)
        {
            repeater(Control40)
            {
                ShowCaption = false;
                field("Document No."; Rec."Document No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the appropriate field of the physical inventory tracking line.';
                }
                field("Item Tracking No."; Rec."Item Tracking No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the value from the same field on the physical inventory tracking line.';
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the value from the same field on the physical inventory tracking line.';
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the value from the same field on the physical inventory tracking line.';
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the value from the same field on the physical inventory tracking line.';
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the serial number of the item that is being handled on the document line.';
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the value from the same field on the physical inventory tracking line.';
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the value from the same field on the physical inventory tracking line.';
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the value from the same field on the physical inventory tracking line.';
                }
            }
        }
    }

    actions
    {
    }
}

