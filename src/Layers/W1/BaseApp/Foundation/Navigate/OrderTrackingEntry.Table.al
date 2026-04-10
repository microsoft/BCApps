// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Navigate;

using Microsoft.Inventory.Item;

table 99000799 "Order Tracking Entry"
{
    Caption = 'Order Tracking Entry';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
        }
        field(2; "Supplied by"; Text[80])
        {
            Caption = 'Supplied by';
            ToolTip = 'Specifies the source of the supply that fills the demand you track from, such as, a production order line.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(3; "Demanded by"; Text[80])
        {
            Caption = 'Demanded by';
            ToolTip = 'Specifies the source of the demand that the supply is tracked from.';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(8; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
            ToolTip = 'Specifies when items on the document are shipped or were shipped. A shipment date is usually calculated from a requested delivery date plus lead time.';
        }
        field(9; "Expected Receipt Date"; Date)
        {
            Caption = 'Expected Receipt Date';
            ToolTip = 'Specifies the date when the tracked items are expected to enter the inventory.';
        }
        field(11; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the number of the item that has been tracked in this entry.';
            TableRelation = Item;
        }
        field(13; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            ToolTip = 'Specifies the quantity, in the base unit of measure, of the item that has been tracked in this entry.';
            DecimalPlaces = 0 : 5;
        }
        field(14; Level; Integer)
        {
            Caption = 'Level';
        }
        field(20; "For Type"; Integer)
        {
            Caption = 'For Type';
        }
        field(21; "For Subtype"; Integer)
        {
            Caption = 'For Subtype';
        }
        field(22; "For ID"; Code[20])
        {
            Caption = 'For ID';
        }
        field(23; "For Batch Name"; Code[10])
        {
            Caption = 'For Batch Name';
        }
        field(24; "For Prod. Order Line"; Integer)
        {
            Caption = 'For Prod. Order Line';
        }
        field(25; "For Ref. No."; Integer)
        {
            Caption = 'For Ref. No.';
        }
        field(26; "From Type"; Integer)
        {
            Caption = 'From Type';
        }
        field(27; "From Subtype"; Integer)
        {
            Caption = 'From Subtype';
        }
        field(28; "From ID"; Code[20])
        {
            Caption = 'From ID';
        }
        field(29; "From Batch Name"; Code[10])
        {
            Caption = 'From Batch Name';
        }
        field(30; "From Prod. Order Line"; Integer)
        {
            Caption = 'From Prod. Order Line';
        }
        field(31; "From Ref. No."; Integer)
        {
            Caption = 'From Ref. No.';
        }
        field(40; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            ToolTip = 'Specifies the starting date of the line that the items are tracked from.';
        }
        field(41; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            ToolTip = 'Specifies the ending date of the line that the items are tracked from.';
        }
        field(42; Name; Text[80])
        {
            Caption = 'Name';
            ToolTip = 'Specifies the name of the line that the items are tracked from.';
        }
        field(43; Warning; Boolean)
        {
            Caption = 'Warning';
            ToolTip = 'Specifies there is a date conflict in the order tracking entries for this line.';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

