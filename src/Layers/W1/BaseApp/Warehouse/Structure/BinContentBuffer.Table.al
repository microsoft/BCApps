// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Structure;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Activity;

table 7330 "Bin Content Buffer"
{
    Caption = 'Bin Content Buffer';
    ReplicateData = false;
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = SystemMetadata;
            NotBlank = true;
            TableRelation = Location;
        }
        field(2; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
            DataClassification = SystemMetadata;
            NotBlank = true;
            TableRelation = Zone.Code where("Location Code" = field("Location Code"));
        }
        field(3; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            DataClassification = SystemMetadata;
            NotBlank = true;
            TableRelation = if ("Zone Code" = filter('')) Bin.Code where("Location Code" = field("Location Code"))
            else
            if ("Zone Code" = filter(<> '')) Bin.Code where("Location Code" = field("Location Code"),
                                                                               "Zone Code" = field("Zone Code"));
        }
        field(4; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = SystemMetadata;
            NotBlank = true;
            TableRelation = Item;
        }
        field(5; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = SystemMetadata;
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(6; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            DataClassification = SystemMetadata;
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(10; Cubage; Decimal)
        {
            Caption = 'Cubage';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        field(11; Weight; Decimal)
        {
            Caption = 'Weight';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        field(12; "Base Unit of Measure"; Code[10])
        {
            Caption = 'Base Unit of Measure';
            DataClassification = SystemMetadata;
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(50; "Qty. to Handle (Base)"; Decimal)
        {
            Caption = 'Qty. to Handle (Base)';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(51; "Qty. Outstanding (Base)"; Decimal)
        {
            Caption = 'Qty. Outstanding (Base)';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
        }
        field(6500; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
            DataClassification = SystemMetadata;
        }
        field(6501; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            DataClassification = SystemMetadata;
        }
        field(6515; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            DataClassification = SystemMetadata;
        }
        field(7382; Dedicated; Boolean)
        {
            Caption = 'Dedicated';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Location Code", "Bin Code", "Item No.", "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.", "Package No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure UpdateBuffer(LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"; QtyBase: Decimal)
    begin
        if Get(
            LocationCode, BinCode, ItemNo, VariantCode, UnitOfMeasureCode,
            WhseItemTrackingSetup."Lot No.", WhseItemTrackingSetup."Serial No.", WhseItemTrackingSetup."Package No.")
        then begin
            "Qty. to Handle (Base)" += QtyBase;
            Modify();
        end else begin
            Init();
            "Location Code" := LocationCode;
            "Bin Code" := BinCode;
            "Item No." := ItemNo;
            "Variant Code" := VariantCode;
            "Unit of Measure Code" := UnitOfMeasureCode;
            CopyTrackingFromWhseItemTrackingSetup(WhseItemTrackingSetup);
            "Qty. to Handle (Base)" := QtyBase;
            Insert();
        end;
    end;

    procedure CopyTrackingFromWhseActivityLine(WhseActivityLine: Record "Warehouse Activity Line")
    begin
        "Serial No." := WhseActivityLine."Serial No.";
        "Lot No." := WhseActivityLine."Lot No.";

        OnAfterCopyTrackingFromWhseActivityLine(Rec, WhseActivityLine);
    end;

    procedure CopyTrackingFromWhseItemTrackingSetup(WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        "Serial No." := WhseItemTrackingSetup."Serial No.";
        "Lot No." := WhseItemTrackingSetup."Lot No.";

        OnAfterCopyTrackingFromWhseItemTrackingSetup(Rec, WhseItemTrackingSetup);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromWhseActivityLine(var BinContentBuffer: Record "Bin Content Buffer"; WhseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromWhseItemTrackingSetup(var BinContentBuffer: Record "Bin Content Buffer"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;
}

