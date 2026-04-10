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
                }
                field("Item Tracking No."; Rec."Item Tracking No.")
                {
                    ApplicationArea = ItemTracking;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = ItemTracking;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = ItemTracking;
                }
                field("Location Code"; Rec."Location Code")
                {
                    ApplicationArea = ItemTracking;
                }
                field("Bin Code"; Rec."Bin Code")
                {
                    ApplicationArea = ItemTracking;
                }
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = ItemTracking;
                }
                field("Entry Type"; Rec."Entry Type")
                {
                    ApplicationArea = ItemTracking;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = ItemTracking;
                }
            }
        }
    }

    actions
    {
    }
}

