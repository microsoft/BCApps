// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Sales.Customer;
using System.Reflection;

table 346 "Reservation Wksh. Line"
{
    Caption = 'Reservation Wksh. Line';
    DataCaptionFields = "Journal Batch Name", "Line No.";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Reservation Wksh. Batch";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(10; "Source Type"; Integer)
        {
            Caption = 'Source Type';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
        }
        field(11; "Source Subtype"; Integer)
        {
            Caption = 'Source Subtype';
            MinValue = 0;
            MaxValue = 10;
        }
        field(12; "Source ID"; Code[20])
        {
            Caption = 'Source ID';
        }
        field(13; "Source Batch Name"; Code[10])
        {
            Caption = 'Source Batch Name';
        }
        field(14; "Source Prod. Order Line"; Integer)
        {
            Caption = 'Source Prod. Order Line';
        }
        field(15; "Source Ref. No."; Integer)
        {
            Caption = 'Source Ref. No.';
        }
        field(17; "Record ID"; RecordId)
        {
            Caption = 'Record ID';
        }
        field(21; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(22; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(23; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(24; "Sell-to Customer No."; Code[20])
        {
            Caption = 'Sell-to Customer No.';
            TableRelation = Customer."No.";
        }
        field(25; "Sell-to Customer Name"; Text[100])
        {
            Caption = 'Sell-to Customer Name';
            TableRelation = Customer.Name;
        }
        field(26; Priority; Integer)
        {
            Caption = 'Priority';
        }
        field(29; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(30; "Description 2"; Text[100])
        {
            Caption = 'Description 2';
        }
        field(31; "Demand Date"; Date)
        {
            Caption = 'Demand Date';
        }
        field(32; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            NotBlank = true;
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            begin
                GetItemUnitOfMeasure();
                "Qty. per Unit of Measure" := ItemUnitOfMeasure."Qty. per Unit of Measure";
            end;
        }
        field(33; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            InitValue = 1;
        }
        field(41; "Remaining Qty. to Reserve"; Decimal)
        {
            Caption = 'Remaining Qty. to Reserve';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                "Rem. Qty. to Reserve (Base)" :=
                  UnitOfMeasureManagement.CalcBaseQty("Remaining Qty. to Reserve", "Qty. per Unit of Measure");
            end;
        }
        field(42; "Rem. Qty. to Reserve (Base)"; Decimal)
        {
            Caption = 'Rem. Qty. to Reserve (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                "Remaining Qty. to Reserve" :=
                  UnitOfMeasureManagement.CalcQtyFromBase("Rem. Qty. to Reserve (Base)", "Qty. per Unit of Measure");
            end;
        }
        field(43; "Qty. to Reserve"; Decimal)
        {
            Caption = 'Qty. to Reserve';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Qty. to Reserve" > "Remaining Qty. to Reserve" then
                    Error(ExceedingQtyErr, FieldCaption("Qty. to Reserve"), FieldCaption("Remaining Qty. to Reserve"));

                "Qty. to Reserve (Base)" :=
                  UnitOfMeasureManagement.CalcBaseQty("Qty. to Reserve", "Qty. per Unit of Measure");

                "Available Qty. to Reserve" := "Available Qty. to Reserve" - ("Qty. to Reserve" - xRec."Qty. to Reserve");
                "Avail. Qty. to Reserve (Base)" := "Avail. Qty. to Reserve (Base)" - ("Qty. to Reserve (Base)" - xRec."Qty. to Reserve (Base)");

                if "Available Qty. to Reserve" < 0 then
                    Error(ExceedingQtyErr, FieldCaption("Qty. to Reserve"), FieldCaption("Available Qty. to Reserve"));

                AdjustAvailableQtyToReserveOnOtherLines();

                Accept := Rec."Remaining Qty. to Reserve" = Rec."Qty. to Reserve";
            end;
        }
        field(44; "Qty. to Reserve (Base)"; Decimal)
        {
            Caption = 'Qty. to Reserve (Base)';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                "Qty. to Reserve" :=
                    UnitOfMeasureManagement.CalcQtyFromBase("Qty. to Reserve (Base)", "Qty. per Unit of Measure");

                if "Qty. to Reserve" > "Remaining Qty. to Reserve" then
                    Error(ExceedingQtyErr, FieldCaption("Qty. to Reserve"), FieldCaption("Remaining Qty. to Reserve"));

                "Available Qty. to Reserve" := "Available Qty. to Reserve" - ("Qty. to Reserve" - xRec."Qty. to Reserve");
                "Avail. Qty. to Reserve (Base)" := "Avail. Qty. to Reserve (Base)" - ("Qty. to Reserve (Base)" - xRec."Qty. to Reserve (Base)");

                if "Available Qty. to Reserve" < 0 then
                    Error(ExceedingQtyErr, FieldCaption("Qty. to Reserve"), FieldCaption("Available Qty. to Reserve"));

                AdjustAvailableQtyToReserveOnOtherLines();

                Accept := Rec."Remaining Qty. to Reserve" = Rec."Qty. to Reserve";
            end;
        }
        field(51; "Available Qty. to Reserve"; Decimal)
        {
            Caption = 'Available Qty. to Reserve';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                "Avail. Qty. to Reserve (Base)" :=
                  UnitOfMeasureManagement.CalcBaseQty("Available Qty. to Reserve", "Qty. per Unit of Measure");
            end;
        }
        field(52; "Avail. Qty. to Reserve (Base)"; Decimal)
        {
            Caption = 'Avail. Qty. to Reserve (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                "Available Qty. to Reserve" :=
                  UnitOfMeasureManagement.CalcQtyFromBase("Avail. Qty. to Reserve (Base)", "Qty. per Unit of Measure");
            end;
        }
        field(61; "Qty. in Stock"; Decimal)
        {
            Caption = 'Qty. in Stock';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                "Qty. in Stock (Base)" :=
                  UnitOfMeasureManagement.CalcBaseQty("Qty. in Stock", "Qty. per Unit of Measure");
            end;
        }
        field(62; "Qty. in Stock (Base)"; Decimal)
        {
            Caption = 'Qty. in Stock (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                "Qty. in Stock" :=
                  UnitOfMeasureManagement.CalcQtyFromBase("Qty. in Stock (Base)", "Qty. per Unit of Measure");
            end;
        }
        field(63; "Qty. Reserved in Stock"; Decimal)
        {
            Caption = 'Qty. Reserved from Stock';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                "Qty. Reserv. in Stock (Base)" :=
                  UnitOfMeasureManagement.CalcBaseQty("Qty. Reserved in Stock", "Qty. per Unit of Measure");
            end;
        }
        field(64; "Qty. Reserv. in Stock (Base)"; Decimal)
        {
            Caption = 'Qty. Reserved from Stock (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                "Qty. Reserved in Stock" :=
                  UnitOfMeasureManagement.CalcQtyFromBase("Qty. Reserv. in Stock (Base)", "Qty. per Unit of Measure");
            end;
        }
        field(65; "Qty. in Whse. Handling"; Decimal)
        {
            Caption = 'Qty. in Warehouse Handling';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                "Qty. in Whse. Handling (Base)" :=
                  UnitOfMeasureManagement.CalcBaseQty("Qty. in Whse. Handling", "Qty. per Unit of Measure");
            end;
        }
        field(66; "Qty. in Whse. Handling (Base)"; Decimal)
        {
            Caption = 'Qty. in Warehouse Handling (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                "Qty. in Whse. Handling" :=
                  UnitOfMeasureManagement.CalcQtyFromBase("Qty. in Whse. Handling (Base)", "Qty. per Unit of Measure");
            end;
        }
        field(100; Accept; Boolean)
        {
            Caption = 'Accept';
        }
        field(6501; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
        }
        field(6502; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
        }
        field(6503; "Package No."; Code[50])
        {
            Caption = 'Package No.';
        }
    }

    keys
    {
        key(Key1; "Journal Batch Name", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Journal Batch Name", "Source Type", "Source Subtype", "Source ID", "Source Ref. No.", "Source Batch Name", "Source Prod. Order Line")
        {

        }
        key(Key3; "Journal Batch Name", "Item No.", "Variant Code", "Location Code")
        {
            IncludedFields = Priority;
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Item No.", Description, "Remaining Qty. to Reserve", "Source ID", "Demand Date")
        { }
    }
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        UnitOfMeasureManagement: Codeunit "Unit of Measure Management";
        ExceedingQtyErr: Label '%1 cannot exceed %2.', Comment = '%1: Qty. to Reserve, %2: Remaining Qty. to Reserve or Available Qty. to Reserve';

    procedure IsOutdated() Outdated: Boolean
    var
    begin
        Outdated := false;
        OnIsOutdated(Rec, Outdated);
        if Outdated then
            exit(true);

        exit(false);
    end;

    local procedure GetItem()
    begin
        if "Item No." <> Item."No." then
            Item.Get("Item No.");
    end;

    local procedure GetItemUnitOfMeasure()
    begin
        GetItem();
        if (Item."No." <> ItemUnitOfMeasure."Item No.") or
           ("Unit of Measure Code" <> ItemUnitOfMeasure.Code)
        then
            if not ItemUnitOfMeasure.Get(Item."No.", "Unit of Measure Code") then
                ItemUnitOfMeasure.Get(Item."No.", Item."Base Unit of Measure");
    end;

    procedure GetLastLineNo(): Integer
    var
        ReservationWkshLine: Record "Reservation Wksh. Line";
    begin
        ReservationWkshLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");
        if ReservationWkshLine.FindLast() then
            exit(ReservationWkshLine."Line No.");

        exit(0);
    end;

    local procedure AdjustAvailableQtyToReserveOnOtherLines()
    var
        ReservationWkshLine: Record "Reservation Wksh. Line";
    begin
        ReservationWkshLine.SetRange("Journal Batch Name", Rec."Journal Batch Name");
        ReservationWkshLine.SetFilter("Line No.", '<>%1', Rec."Line No.");
        ReservationWkshLine.SetRange("Item No.", Rec."Item No.");
        ReservationWkshLine.SetRange("Variant Code", Rec."Variant Code");
        ReservationWkshLine.SetRange("Location Code", Rec."Location Code");
        if ReservationWkshLine.FindSet() then
            repeat
                ReservationWkshLine.Validate("Avail. Qty. to Reserve (Base)", Rec."Avail. Qty. to Reserve (Base)");
                ReservationWkshLine.Modify();
            until ReservationWkshLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnIsOutdated(ReservationWkshLine: Record "Reservation Wksh. Line"; var Outdated: Boolean)
    begin
    end;
}
