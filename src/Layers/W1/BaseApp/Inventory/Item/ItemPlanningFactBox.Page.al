// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

page 9091 "Item Planning FactBox"
{
    Caption = 'Item Details - Planning';
    PageType = CardPart;
    SourceTable = Item;

    layout
    {
        area(content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = Planning;
                Caption = 'Item No.';

                trigger OnDrillDown()
                begin
                    ShowDetails();
                end;
            }
            field("Reordering Policy"; Rec."Reordering Policy")
            {
                ApplicationArea = Planning;
            }
            field("Reorder Point"; Rec."Reorder Point")
            {
                ApplicationArea = Planning;
            }
            field("Reorder Quantity"; Rec."Reorder Quantity")
            {
                ApplicationArea = Planning;
            }
            field("Maximum Inventory"; Rec."Maximum Inventory")
            {
                ApplicationArea = Planning;
            }
            field("Overflow Level"; Rec."Overflow Level")
            {
                ApplicationArea = Planning;
            }
            field("Time Bucket"; Rec."Time Bucket")
            {
                ApplicationArea = Planning;
            }
            field("Lot Accumulation Period"; Rec."Lot Accumulation Period")
            {
                ApplicationArea = Planning;
            }
            field("Rescheduling Period"; Rec."Rescheduling Period")
            {
                ApplicationArea = Planning;
            }
            field("Safety Lead Time"; Rec."Safety Lead Time")
            {
                ApplicationArea = Planning;
            }
            field("Safety Stock Quantity"; Rec."Safety Stock Quantity")
            {
                ApplicationArea = Planning;
            }
            field("Minimum Order Quantity"; Rec."Minimum Order Quantity")
            {
                ApplicationArea = Planning;
            }
            field("Maximum Order Quantity"; Rec."Maximum Order Quantity")
            {
                ApplicationArea = Planning;
            }
            field("Order Multiple"; Rec."Order Multiple")
            {
                ApplicationArea = Planning;
            }
            field("Dampener Period"; Rec."Dampener Period")
            {
                ApplicationArea = Planning;
            }
            field("Dampener Quantity"; Rec."Dampener Quantity")
            {
                ApplicationArea = Planning;
            }
        }
    }

    actions
    {
    }

    local procedure ShowDetails()
    begin
        PAGE.Run(PAGE::"Item Card", Rec);
    end;
}

