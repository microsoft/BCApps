// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Ledger;

using Microsoft.Inventory.Item;

page 9125 "Item Application FactBox"
{
    Caption = 'Item Application';
    Editable = false;
    PageType = CardPart;
    SourceTable = "Item Ledger Entry";

    layout
    {
        area(content)
        {
            field("Entry No."; Rec."Entry No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
            }
            field("Item No."; Rec."Item No.")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the number of the item in the entry.';
            }
#pragma warning disable AA0100
            field("Item.""Costing Method"""; Item."Costing Method")
#pragma warning restore AA0100
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Costing Method';
                ToolTip = 'Specifies which costing method applies to the item number.';
            }
            field("Posting Date"; Rec."Posting Date")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the entry''s posting date.';
            }
            field("Entry Type"; Rec."Entry Type")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies which type of transaction that the entry is created from.';
            }
            field(Quantity; Rec.Quantity)
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the number of units of the item in the item entry.';
            }
            field("Reserved Quantity"; Rec."Reserved Quantity")
            {
                ApplicationArea = Reservation;
                ToolTip = 'Specifies how many units of the item on the line have been reserved.';
            }
            field("Remaining Quantity"; Rec."Remaining Quantity")
            {
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the quantity in the Quantity field that remains to be processed.';
            }
            field(Available; Available)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Available';
                DecimalPlaces = 0 : 5;
                ToolTip = 'Specifies the number available for the relevant entry.';
            }
            field(Applied; Applied)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Applied';
                DecimalPlaces = 0 : 5;
                ToolTip = 'Specifies the number applied to the relevant entry.';
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("Reserved Quantity");
        Available := Rec.Quantity - Rec."Reserved Quantity";
        Applied := ItemApplnEntry.OutboundApplied(Rec."Entry No.", false) - ItemApplnEntry.InboundApplied(Rec."Entry No.", false);

        if not Item.Get(Rec."Item No.") then
            Item.Reset();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        Available := 0;
        Applied := 0;
        Clear(Item);

        exit(Rec.Find(Which));
    end;

    var
        Item: Record Item;
        ItemApplnEntry: Record "Item Application Entry";
        Available: Decimal;
        Applied: Decimal;
}

