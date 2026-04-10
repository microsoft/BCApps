// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Forecast;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;

table 2900 "Forecast Item Variant Loc"
{
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
            TableRelation = Item."No.";
            DataClassification = CustomerContent;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the item.';
            DataClassification = CustomerContent;
        }
        field(4; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(5; "Location Filter"; Code[10])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
            TableRelation = Location;
        }
        field(6; "Variant Filter"; Code[10])
        {
            Caption = 'Variant Filter';
            FieldClass = FlowFilter;
            TableRelation = "Item Variant";
        }
        field(7; "Production Forecast Name"; Code[10])
        {
            Caption = 'Production Forecast Name';
            FieldClass = FlowFilter;
            TableRelation = "Production Forecast Name";
        }
        field(8; "Component Forecast"; Boolean)
        {
            Caption = 'Component Forecast';
            FieldClass = FlowFilter;
        }
        field(9; "Prod. Forecast Quantity (Base)"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Production Forecast Entry"."Forecast Quantity (Base)" where("Item No." = field("No."),
                                                                                            "Production Forecast Name" = field("Production Forecast Name"),
                                                                                            "Forecast Date" = field("Date Filter"),
                                                                                            "Location Code" = field("Location Filter"),
                                                                                            "Component Forecast" = field("Component Forecast"),
                                                                                            "Variant Code" = field("Variant Filter")));
            Caption = 'Prod. Forecast Quantity (Base)';
            DecimalPlaces = 0 : 5;
            FieldClass = FlowField;
        }
        field(10; "Variant Code"; Code[20])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies a variant code of the item.';
            DataClassification = CustomerContent;
        }
        field(11; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies a location code of the item.';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
    }
}
