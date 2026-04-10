// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location;

table 5712 "Copy Location Buffer"
{
    Caption = 'Copy Location Buffer';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Source Location Code"; Code[10])
        {
            Caption = 'Source Location Code';
            TableRelation = Location;
            DataClassification = SystemMetadata;
        }
        field(3; "Target Location Code"; Code[10])
        {
            Caption = 'Target Location Code';
            DataClassification = SystemMetadata;
        }
        field(11; Zones; Boolean)
        {
            Caption = 'Zones';
            DataClassification = SystemMetadata;
        }
        field(12; Bins; Boolean)
        {
            Caption = 'Bins';
            DataClassification = SystemMetadata;
        }
        field(13; "Warehouse Employees"; Boolean)
        {
            Caption = 'Warehouse Employees';
            DataClassification = SystemMetadata;
        }
        field(14; "Inventory Posting Setup"; Boolean)
        {
            Caption = 'Inventory Posting Setup';
            DataClassification = SystemMetadata;
        }
        field(15; Dimensions; Boolean)
        {
            Caption = 'Dimensions';
            DataClassification = SystemMetadata;
        }
        field(16; "Transfer Routes"; Boolean)
        {
            Caption = 'Transfer Routes';
            DataClassification = SystemMetadata;
        }
        field(100; "Show Created Location"; Boolean)
        {
            Caption = 'Show Created Location';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}
