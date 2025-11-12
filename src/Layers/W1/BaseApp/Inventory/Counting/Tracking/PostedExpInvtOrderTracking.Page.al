// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Tracking;

page 6026 "Posted.Exp.Invt.Order.Tracking"
{
    Caption = 'Posted Exp. Invt. Order Tracking';
    Editable = false;
    PageType = List;
    SourceTable = "Pstd.Exp.Invt.Order.Tracking";

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
                    ToolTip = 'Specifies the expected Serial No.';
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the expected Lot No.';
                }
                field("Package No."; Rec."Package No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the expected Package No.';
                }
                field("Expiration Date"; Rec."Expiration Date")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the expected Expiration Date';
                }
                field("Quantity (Base)"; Rec."Quantity (Base)")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the expected quantity of Serial No., Lot No. and Package No. that relates to the Base Unit of Measure Code, in the Posted Inventory Order Line.';
                }
                field("Order No"; Rec."Order No")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the document number of the Posted Inventory Order.';
                }
                field("Order Line No."; Rec."Order Line No.")
                {
                    ApplicationArea = ItemTracking;
                    ToolTip = 'Specifies the line number of the Posted Inventory Order Line.';
                }
            }
        }
    }

    actions
    {
    }
}

