// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Tracking;

page 6025 "Exp. Invt. Order Tracking"
{
    Caption = 'Exp. Invt. Order Tracking';
    Editable = false;
    PageType = List;
    SourceTable = "Exp. Invt. Order Tracking";

    layout
    {
        area(content)
        {
            repeater(Control40)
            {
                ShowCaption = false;
                field("Serial No."; Rec."Serial No.")
                {
                    ApplicationArea = ItemTracking;
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = ItemTracking;
                }
                field("Package No."; Rec."Package No.")
                {
                    ApplicationArea = ItemTracking;
                }
                field("Expiration Date"; Rec."Expiration Date")
                {
                    ApplicationArea = ItemTracking;
                }
                field("Quantity (Base)"; Rec."Quantity (Base)")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the expected quantity of Serial No., Lot No. and Package No. that relates to the Base Unit of Measure Code, in the Inventory Order Line.';
                }
                field("Order No"; Rec."Order No")
                {
                    ApplicationArea = ItemTracking;
                }
                field("Order Line No."; Rec."Order Line No.")
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
