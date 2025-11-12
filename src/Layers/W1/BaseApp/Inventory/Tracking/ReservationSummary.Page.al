// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

page 505 "Reservation Summary"
{
    Caption = 'Reservation Summary';
    LinksAllowed = false;
    PageType = List;
    SourceTable = "Entry Summary";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Summary Type"; Rec."Summary Type")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies which type of line or entry is summarized in the entry summary.';
                }
                field("Total Quantity"; Rec."Total Quantity")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies the total quantity of the item in inventory.';
                }
                field("Total Reserved Quantity"; Rec."Total Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies the total quantity of the relevant item that is reserved on documents or entries of the type on the line.';
                }
                field("Total Available Quantity"; Rec."Total Available Quantity")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies the quantity available for the user to request, in entries of the type on the line.';
                }
                field("Current Reserved Quantity"; Rec."Current Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                    ToolTip = 'Specifies the quantity of items in the entry that are reserved for the line that the Reservation window is opened from.';
                }
            }
        }
    }

    actions
    {
    }
}

