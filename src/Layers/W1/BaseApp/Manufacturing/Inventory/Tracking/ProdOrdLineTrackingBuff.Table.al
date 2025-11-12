// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Ledger;
using Microsoft.Manufacturing.Document;

table 5408 "Prod. Ord. Line Tracking Buff."
{
    Caption = 'Prod. Order Line Item Tracking Buffer';
    ReplicateData = false;
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Prod. Order Status"; Enum "Production Order Status")
        {
            Caption = 'Production Order Status';
        }
        field(2; "Prod. Order No."; Code[20])
        {
            Caption = 'Production Order No.';
            TableRelation = "Production Order"."No." where(Status = field("Prod. Order Status"));
        }
        field(3; "Prod. Order Line No."; Integer)
        {
            Caption = 'Production Order Line No.';
        }
        field(5; "Buffer Entry No."; Integer)
        {
            Caption = 'Buffer Entry No.';
        }
        field(11; "Item No."; Code[20])
        {
            Caption = 'Item No.';
        }
        field(12; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
        }
        field(40; "Qty. split for Put Away"; Decimal)
        {
            Caption = 'Qty. split for Put Away';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(41; "Qty. split for Put Away (Base)"; Decimal)
        {
            Caption = 'Qty. split for Put Away (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(73; "Qty. Rounding Precision"; Decimal)
        {
            Caption = 'Qty. Rounding Precision';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
        }
        field(74; "Qty. Rounding Precision (Base)"; Decimal)
        {
            Caption = 'Qty. Rounding Precision (Base)';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
        }
        field(80; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
        }
        field(6500; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
        }
        field(6501; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
        }
        field(6502; "Warranty Date"; Date)
        {
            Caption = 'Warranty Date';
        }
        field(6503; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';
        }
        field(6515; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            CaptionClass = '6,1';
        }
        field(99000753; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
        }
    }

    keys
    {
        key(Key1; "Prod. Order Status", "Prod. Order No.", "Prod. Order Line No.", "Buffer Entry No.")
        {
            Clustered = true;
        }
    }

    internal procedure CopyTrackingFromItemLedgerEntry(ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        "Serial No." := ItemLedgerEntry."Serial No.";
        "Lot No." := ItemLedgerEntry."Lot No.";
        "Package No." := ItemLedgerEntry."Package No.";
        OnAfterCopyTrackingFromItemLedgerEntry(Rec, ItemLedgerEntry);
    end;

    internal procedure SetTrackingFilterFromItemLedgerEntry(ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        SetRange("Serial No.", ItemLedgerEntry."Serial No.");
        SetRange("Lot No.", ItemLedgerEntry."Lot No.");
        SetRange("Package No.", ItemLedgerEntry."Package No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemLedgerEntry(var ProdOrdLineTrackingBuff: Record "Prod. Ord. Line Tracking Buff."; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;
}