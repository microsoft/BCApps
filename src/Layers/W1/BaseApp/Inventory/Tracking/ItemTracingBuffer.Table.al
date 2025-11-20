// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Security.AccessControl;

table 6520 "Item Tracing Buffer"
{
    Caption = 'Item Tracing Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Parent Item Ledger Entry No."; Integer)
        {
            Caption = 'Parent Item Ledger Entry No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(3; Level; Integer)
        {
            Caption = 'Level';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(4; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = Item;
        }
        field(5; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(6; "Entry Type"; Enum "Item Ledger Entry Type")
        {
            Caption = 'Entry Type';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(7; "Source Type"; Enum "Analysis Source Type")
        {
            Caption = 'Source Type';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(8; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = if ("Source Type" = const(Customer)) Customer
            else
            if ("Source Type" = const(Vendor)) Vendor
            else
            if ("Source Type" = const(Item)) Item;
        }
        field(9; "Source Name"; Text[100])
        {
            Caption = 'Source Name';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(10; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(11; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
            Editable = false;

            trigger OnLookup()
            begin
                WhereUsedMgt.ShowDocument("Record Identifier");
            end;
        }
        field(12; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = Location;
        }
        field(13; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(14; "Remaining Quantity"; Decimal)
        {
            Caption = 'Remaining Quantity';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(16; Open; Boolean)
        {
            Caption = 'Open';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(17; Positive; Boolean)
        {
            Caption = 'Positive';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(18; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(19; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            DataClassification = SystemMetadata;
            Editable = false;

            trigger OnLookup()
            begin
                ItemTrackingMgt.LookupTrackingNoInfo("Item No.", "Variant Code", ItemTrackingType::"Serial No.", "Serial No.");
            end;
        }
        field(20; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
            DataClassification = SystemMetadata;
            Editable = false;

            trigger OnLookup()
            begin
                ItemTrackingMgt.LookupTrackingNoInfo("Item No.", "Variant Code", ItemTrackingType::"Lot No.", "Lot No.");
            end;
        }
        field(21; "Item Ledger Entry No."; Integer)
        {
            Caption = 'Item Ledger Entry No.';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = "Item Ledger Entry";
        }
        field(22; "Created by"; Code[50])
        {
            Caption = 'Created by';
            DataClassification = SystemMetadata;
            Editable = false;
            TableRelation = User."User Name";
        }
        field(23; "Created on"; Date)
        {
            Caption = 'Created on';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(24; "Record Identifier"; RecordID)
        {
            Caption = 'Record Identifier';
            DataClassification = CustomerContent;
            Editable = false;
        }
        field(25; "Item Description"; Text[100])
        {
            Caption = 'Item Description';
            DataClassification = SystemMetadata;
        }
        field(26; "Already Traced"; Boolean)
        {
            Caption = 'Already Traced';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(6515; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            CaptionClass = '6,1';
            DataClassification = SystemMetadata;
            Editable = false;

            trigger OnLookup()
            begin
                ItemTrackingMgt.LookupTrackingNoInfo("Item No.", "Variant Code", "Item Tracking Type"::"Package No.", "Package No.");
            end;
        }
    }

    keys
    {
        key(Key1; "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Item Ledger Entry No.")
        {
        }
        key(Key3; "Serial No.", "Item Ledger Entry No.")
        {
        }
        key(Key4; "Lot No.", "Item Ledger Entry No.")
        {
        }
        key(Key5; "Item No.", "Item Ledger Entry No.")
        {
        }
        key(Key6; "Package No.", "Item Ledger Entry No.")
        {
        }
    }

    fieldgroups
    {
    }

    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        WhereUsedMgt: Codeunit "Item Tracing Mgt.";
        ItemTrackingType: Enum "Item Tracking Type";

    procedure CopyTrackingFromItemLedgEntry(ItemLedgEntry: Record "Item Ledger Entry")
    begin
        "Serial No." := ItemLedgEntry."Serial No.";
        "Lot No." := ItemLedgEntry."Lot No.";

        OnAfterCopyTrackingFromItemLedgEntry(Rec, ItemLedgEntry);
    end;

    procedure SetDescription(Description2: Text[100])
    begin
        Description := Format(Description2, -MaxStrLen(Description));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemLedgEntry(var ItemTracingBuffer: Record "Item Tracing Buffer"; ItemLedgEntry: Record "Item Ledger Entry")
    begin
    end;
}

