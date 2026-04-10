// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Document;

using Microsoft.Inventory.Item;

page 911 "Component - Item Details"
{
    Caption = 'Component - Item Details';
    PageType = CardPart;
    SourceTable = Item;

    layout
    {
        area(content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = Assembly;
                Caption = 'Item No.';
                ToolTip = 'Specifies the number of the item.';

                trigger OnDrillDown()
                var
                    Item: Record Item;
                begin
                    if Rec."No." = '' then
                        exit;

                    if not Item.Get(Rec."No.") then
                        exit;

                    Page.RunModal(Page::"Item Card", Item);
                end;
            }
            field("Base Unit of Measure"; Rec."Base Unit of Measure")
            {
                ApplicationArea = Assembly;
                ToolTip = 'Specifies the base unit used to measure the item, such as piece, box, or pallet. The base unit of measure also serves as the conversion basis for alternate units of measure.';
            }
            field("Unit Price"; Rec."Unit Price")
            {
                ApplicationArea = Assembly;
                ToolTip = 'Specifies the price of one unit of the item or resource. You can enter a price manually or have it entered according to the Price/Profit Calculation field on the related card.';
            }
            field("Unit Cost"; Rec."Unit Cost")
            {
                ApplicationArea = Assembly;
                ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
            }
            field("Standard Cost"; Rec."Standard Cost")
            {
                ApplicationArea = Assembly;
                ToolTip = 'Specifies the unit cost that is used as an estimation to be adjusted with variances later. It is typically used in assembly and production where costs can vary.';
            }
            field("No. of Substitutes"; Rec."No. of Substitutes")
            {
                ApplicationArea = Assembly;
                ToolTip = 'Specifies the number of substitutions that have been registered for the item.';
            }
            field("Replenishment System"; Rec."Replenishment System")
            {
                ApplicationArea = Assembly;
                ToolTip = 'Specifies the type of supply order created by the planning system when the item needs to be replenished.';
            }
            field("Vendor No."; Rec."Vendor No.")
            {
                ApplicationArea = Assembly;
                ToolTip = 'Specifies the vendor code of who supplies this item by default.';
            }
        }
    }

    actions
    {
    }
}

