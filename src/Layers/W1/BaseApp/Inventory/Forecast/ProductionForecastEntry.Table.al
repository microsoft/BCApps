// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Forecast;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Utilities;

table 99000852 "Production Forecast Entry"
{
    Caption = 'Demand Forecast Entry';
    DrillDownPageID = "Demand Forecast Entries";
    LookupPageID = "Demand Forecast Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Production Forecast Name"; Code[10])
        {
            Caption = 'Demand Forecast Name';
            NotBlank = true;
            TableRelation = "Production Forecast Name";
        }
        field(2; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(4; "Forecast Date"; Date)
        {
            Caption = 'Forecast Date';
        }
        field(5; "Forecast Quantity"; Decimal)
        {
            Caption = 'Forecast Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if "Unit of Measure Code" = '' then begin
                    Item.Get("Item No.");
                    "Unit of Measure Code" := Item."Sales Unit of Measure";
                    ItemUnitofMeasure.Get("Item No.", "Unit of Measure Code");
                    "Qty. per Unit of Measure" := ItemUnitofMeasure."Qty. per Unit of Measure";
                end;
                "Forecast Quantity (Base)" := "Forecast Quantity" * "Qty. per Unit of Measure";
            end;
        }
        field(6; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            begin
                ItemUnitofMeasure.Get("Item No.", "Unit of Measure Code");
                "Qty. per Unit of Measure" := ItemUnitofMeasure."Qty. per Unit of Measure";
                "Forecast Quantity" := "Forecast Quantity (Base)" / "Qty. per Unit of Measure";
            end;
        }
        field(7; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(8; "Forecast Quantity (Base)"; Decimal)
        {
            Caption = 'Forecast Quantity (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if "Unit of Measure Code" = '' then begin
                    Item.Get("Item No.");
                    "Unit of Measure Code" := Item."Sales Unit of Measure";
                    ItemUnitofMeasure.Get("Item No.", "Unit of Measure Code");
                    "Qty. per Unit of Measure" := ItemUnitofMeasure."Qty. per Unit of Measure";
                end;
                Validate("Unit of Measure Code");
            end;
        }
        field(10; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(11; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(12; "Component Forecast"; Boolean)
        {
            Caption = 'Component Forecast';
        }
        field(13; Description; Text[100])
        {
            Caption = 'Description';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Production Forecast Name", "Item No.", "Location Code", "Forecast Date", "Component Forecast", "Variant Code")
        {
            SumIndexFields = "Forecast Quantity (Base)";
        }
        key(Key3; "Production Forecast Name", "Item No.", "Component Forecast", "Forecast Date", "Location Code", "Variant Code")
        {
            SumIndexFields = "Forecast Quantity (Base)";
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    var
        ForecastEntry: Record "Production Forecast Entry";
    begin
        TestField("Forecast Date");
        TestField("Production Forecast Name");
        LockTable();
        if "Entry No." = 0 then
            "Entry No." := ForecastEntry.GetLastEntryNo() + 1;
        CallPlanningAssignmentAssignOne();
    end;

    trigger OnModify()
    begin
        CallPlanningAssignmentAssignOne();
    end;

    var
        ItemUnitofMeasure: Record "Item Unit of Measure";
        Item: Record Item;

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    local procedure CallPlanningAssignmentAssignOne()
    var
        PlanningAssignment: Record "Planning Assignment";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCallPlanningAssignmentAssignOne(Rec, PlanningAssignment, IsHandled);
        if IsHandled then
            exit;

        PlanningAssignment.AssignOne("Item No.", "Variant Code", "Location Code", "Forecast Date");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCallPlanningAssignmentAssignOne(var ProductionForecastEntry: Record "Production Forecast Entry"; var PlanningAssignment: Record "Planning Assignment"; var IsHandled: Boolean)
    begin
    end;
}

