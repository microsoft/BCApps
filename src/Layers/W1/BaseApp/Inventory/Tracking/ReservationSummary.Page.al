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
                }
                field("Total Quantity"; Rec."Total Quantity")
                {
                    ApplicationArea = Reservation;
                }
                field("Total Reserved Quantity"; Rec."Total Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                }
                field("Total Available Quantity"; Rec."Total Available Quantity")
                {
                    ApplicationArea = Reservation;
                }
                field("Current Reserved Quantity"; Rec."Current Reserved Quantity")
                {
                    ApplicationArea = Reservation;
                }
            }
        }
    }

    actions
    {
    }
}

