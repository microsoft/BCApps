// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Setup;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;

page 9109 "Item Warehouse FactBox"
{
    Caption = 'Item Details - Warehouse';
    PageType = CardPart;
    SourceTable = Item;

    layout
    {
        area(content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = Suite;
                Caption = 'Item No.';
                ToolTip = 'Specifies the number of the item.';

                trigger OnDrillDown()
                begin
                    ShowDetails();
                end;
            }
            field("Identifier Code"; Rec."Identifier Code")
            {
                ApplicationArea = Warehouse;
                ToolTip = 'Specifies a unique code for the item in terms that are useful for automatic data capture.';
            }
            field("Base Unit of Measure"; Rec."Base Unit of Measure")
            {
                ApplicationArea = Suite;
                ToolTip = 'Specifies the unit in which the item is held in inventory.';
            }
            field("Put-away Unit of Measure Code"; Rec."Put-away Unit of Measure Code")
            {
                ApplicationArea = Warehouse;
                ToolTip = 'Specifies the code of the item unit of measure in which the program will put the item away.';
            }
            field("Purch. Unit of Measure"; Rec."Purch. Unit of Measure")
            {
                ApplicationArea = Suite;
                ToolTip = 'Specifies the unit of measure code used when you purchase the item.';
            }
            field("Item Tracking Code"; Rec."Item Tracking Code")
            {
                ApplicationArea = ItemTracking;
                ToolTip = 'Specifies how serial, lot or package numbers assigned to the item are tracked in the supply chain.';

                trigger OnDrillDown()
                var
                    ItemTrackCode: Record "Item Tracking Code";
                begin
                    ItemTrackCode.SetFilter(Code, Rec."Item Tracking Code");

                    PAGE.Run(PAGE::"Item Tracking Code Card", ItemTrackCode);
                end;
            }
            field("Special Equipment Code"; Rec."Special Equipment Code")
            {
                ApplicationArea = Warehouse;
                ToolTip = 'Specifies the code of the equipment that warehouse employees must use when handling the item.';
            }
            field("Last Phys. Invt. Date"; Rec."Last Phys. Invt. Date")
            {
                ApplicationArea = Warehouse;
                ToolTip = 'Specifies the date on which you last posted the results of a physical inventory for the item to the item ledger.';
            }
            field(NetWeight; GetNetWeight())
            {
                ApplicationArea = Suite;
                Caption = 'Net Weight';
                ToolTip = 'Specifies the total net weight of the items that should be shipped.';
            }
            field("Warehouse Class Code"; Rec."Warehouse Class Code")
            {
                ApplicationArea = Warehouse;
                Caption = 'Warehouse Class Code';
                ToolTip = 'Specifies the warehouse class code that defines the item.';
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        GetNetWeight();
    end;

    local procedure ShowDetails()
    begin
        PAGE.Run(PAGE::"Item Card", Rec);
    end;

    local procedure GetNetWeight(): Decimal
    var
        ItemBaseUOM: Record "Item Unit of Measure";
    begin
        if ItemBaseUOM.Get(Rec."No.", Rec."Base Unit of Measure") then
            exit(ItemBaseUOM.Weight);

        exit(0);
    end;
}

