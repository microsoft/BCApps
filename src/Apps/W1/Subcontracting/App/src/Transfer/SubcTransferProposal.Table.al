// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;

table 20586 "Subc. Transfer Proposal"
{
    Caption = 'Subcontracting Transfer Proposal';
    TableType = Temporary;
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Purchase Order No."; Code[20]) { }
        field(3; "Purchase Line No."; Integer) { }
        field(4; "Item No."; Code[20]) { Caption = 'Item No.'; }
        field(5; "Variant Code"; Code[10]) { Caption = 'Variant Code'; }
        field(6; "Production Order No."; Code[20]) { Caption = 'Production Order No.'; }
        field(7; "Production Order Line No."; Integer) { Caption = 'Production Order Line No.'; }
        field(8; "Operation No."; Code[10]) { Caption = 'Operation No.'; }
        field(9; "Work Center No."; Code[20]) { Caption = 'Work Center No.'; }
        field(10; "Routing No."; Code[20]) { }
        field(11; "Routing Reference No."; Integer) { }
        field(12; "Component Line No."; Integer) { }
        field(13; "WIP Item"; Boolean) { }
        field(14; "State Tracked"; Boolean) { }
        field(15; "WIP State"; Enum "Subc. WIP Processing State") { }
        field(16; "WIP Status"; Text[20]) { Caption = 'WIP Status'; }
        field(17; "Transfer-from Code"; Code[10]) { }
        field(18; "Transfer-to Code"; Code[10]) { }
        field(19; "Unit of Measure Code"; Code[10]) { Caption = 'Unit of Measure Code'; }
        field(20; "Qty. per Unit of Measure"; Decimal) { }
        field(21; "Available Quantity"; Decimal) { Caption = 'Available Quantity'; DecimalPlaces = 0 : 5; }
        field(22; "Quantity on Transfer"; Decimal) { Caption = 'Quantity on Transfer'; DecimalPlaces = 0 : 5; }
        field(23; "Quantity to Transfer"; Decimal)
        {
            Caption = 'Quantity to Transfer';
            DecimalPlaces = 0 : 5;
            trigger OnValidate()
            begin
                CheckQuantity();
            end;
        }
        field(24; "Available Quantity (Base)"; Decimal) { }
        field(25; "Source Position No."; Integer) { }
        field(26; "Supply Lot ID"; Guid) { }
        field(27; "Previous Operation No."; Code[10]) { }
        field(28; "WIP Cohort"; Text[30]) { Caption = 'WIP Cohort'; }
    }
    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
        key(Source; "Source Position No.", "Entry No.") { }
        key(Production; "Production Order No.", "Production Order Line No.", "Entry No.") { }
    }
    var
        InvalidQuantityErr: Label 'The quantity to transfer must be between zero and the available quantity.';

    internal procedure QuantityBase(): Decimal
    var
        Line: Record "Transfer Line" temporary;
    begin
        Line."Item No." := "Item No.";
        Line."Unit of Measure Code" := "Unit of Measure Code";
        Line."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
        exit(Line.CalcBaseQty("Quantity to Transfer"));
    end;

    internal procedure CheckQuantity()
    begin
        if ("Quantity to Transfer" < 0) or (QuantityBase() > "Available Quantity (Base)") then
            Error(InvalidQuantityErr);
    end;
}
