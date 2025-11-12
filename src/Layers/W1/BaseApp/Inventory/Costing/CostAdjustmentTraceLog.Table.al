// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Location;

table 5816 "Cost Adjustment Trace Log"
{
    Caption = 'Cost Adjustment Trace Log';
    DataClassification = CustomerContent;
    InherentPermissions = Rimd;
    LookupPageId = "Cost Adjustment Trace Logs";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Cost Adjustment Run Guid"; Guid)
        {
            Caption = 'Cost Adjustment Run Guid';
        }
        field(3; "Event Name"; Text[250])
        {
            Caption = 'Event Name';
        }
        field(4; "Traced Table ID"; Integer)
        {
            Caption = 'Traced Table ID';
        }
        field(5; "Traced Entry No."; Integer)
        {
            Caption = 'Traced Entry No.';
        }
        field(6; "Item Cost Source/Recipient"; Enum "Item Cost Source/Recipient")
        {
            Caption = 'Cost Source/Recipient';
        }
        field(11; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(12; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(13; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(14; "Valuation Date"; Date)
        {
            Caption = 'Valuation Date';
        }
        field(15; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(21; "Order Type"; Enum "Inventory Order Type")
        {
            Caption = 'Order Type';
        }
        field(22; "Order No."; Code[20])
        {
            Caption = 'Order No.';
        }
        field(23; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
        }
        field(100; "Custom Dimensions"; Text[2048])
        {
            Caption = 'Custom Dimensions';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }

    internal procedure DrillDownEntryNo()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ValueEntry: Record "Value Entry";
    begin
        case "Traced Table ID" of
            Database::"Item Ledger Entry":
                begin
                    ItemLedgerEntry.Get("Traced Entry No.");
                    Page.RunModal(0, ItemLedgerEntry);
                end;
            Database::"Value Entry":
                begin
                    if "Traced Entry No." = 0 then
                        exit;

                    ValueEntry.SetRange("Item Ledger Entry No.", "Traced Entry No.");
                    Page.RunModal(0, ValueEntry);
                end;
        end;
    end;
}