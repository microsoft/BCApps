// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Journal;

table 1019 "Job Difference Buffer"
{
    Caption = 'Project Difference Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Job Task No."; Code[20])
        {
            Caption = 'Project Task No.';
            DataClassification = SystemMetadata;
        }
        field(3; Type; Enum "Job Journal Line Type")
        {
            Caption = 'Type';
            DataClassification = SystemMetadata;
        }
        field(4; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            DataClassification = SystemMetadata;
        }
        field(5; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = SystemMetadata;
        }
        field(6; "Unit of Measure code"; Code[10])
        {
            Caption = 'Unit of Measure code';
            DataClassification = SystemMetadata;
        }
        field(7; "Entry type"; Option)
        {
            Caption = 'Entry type';
            DataClassification = SystemMetadata;
            OptionCaption = 'Budget,Usage';
            OptionMembers = Budget,Usage;
        }
        field(8; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            DataClassification = SystemMetadata;
        }
        field(9; "No."; Code[20])
        {
            Caption = 'No.';
            DataClassification = SystemMetadata;
        }
        field(10; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DataClassification = SystemMetadata;
        }
        field(11; "Total Cost"; Decimal)
        {
            Caption = 'Total Cost';
            DataClassification = SystemMetadata;
        }
        field(12; "Line Amount"; Decimal)
        {
            Caption = 'Line Amount';
            DataClassification = SystemMetadata;
        }
        field(10010; "Budgeted Quantity"; Decimal)
        {
            Caption = 'Budgeted Quantity';
            DataClassification = SystemMetadata;
        }
        field(10011; "Budgeted Total Cost"; Decimal)
        {
            Caption = 'Budgeted Total Cost';
            DataClassification = SystemMetadata;
        }
        field(10012; "Budgeted Line Amount"; Decimal)
        {
            Caption = 'Budgeted Line Amount';
            DataClassification = SystemMetadata;
        }
        field(10013; Description; Text[50])
        {
            Caption = 'Description';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Job No.", "Job Task No.", Type, "Entry type", "No.", "Location Code", "Variant Code", "Unit of Measure code", "Work Type Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

