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
        }
        field(2; "Supplied by"; Text[80])
        {
            Caption = 'Supplied by';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(3; "Demanded by"; Text[80])
        {
            Caption = 'Demanded by';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(8; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
        }
        field(9; "Expected Receipt Date"; Date)
        {
            Caption = 'Expected Receipt Date';
        }
        field(11; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(13; Quantity; Decimal)
        {
            Caption = 'Quantity';
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
        }
        field(41; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
        }
        field(42; Name; Text[80])
        {
            Caption = 'Name';
        }
        field(43; Warning; Boolean)
        {
            Caption = 'Warning';
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

