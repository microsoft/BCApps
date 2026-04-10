// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Resources;

using Microsoft.Inventory.Location;
using Microsoft.Projects.Resources.Resource;

table 5952 "Resource Location"
{
    Caption = 'Resource Location';
    DrillDownPageID = "Resource Locations";
    LookupPageID = "Resource Locations";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the location code of the resource.';
            TableRelation = Location;

            trigger OnValidate()
            begin
                CalcFields("Location Name");
            end;
        }
        field(2; "Location Name"; Text[100])
        {
            CalcFormula = lookup(Location.Name where(Code = field("Location Code")));
            Caption = 'Location Name';
            Editable = false;
            FieldClass = FlowField;
        }
        field(3; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            ToolTip = 'Specifies the number of the resource in the location.';
            TableRelation = Resource;

            trigger OnValidate()
            begin
                CalcFields("Resource Name");
            end;
        }
        field(4; "Resource Name"; Text[100])
        {
            CalcFormula = lookup(Resource.Name where("No." = field("Resource No.")));
            Caption = 'Resource Name';
            ToolTip = 'Specifies the name of the resource.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            ToolTip = 'Specifies the date when the resource becomes available in this location.';
        }
    }

    keys
    {
        key(Key1; "Location Code", "Resource No.", "Starting Date")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

