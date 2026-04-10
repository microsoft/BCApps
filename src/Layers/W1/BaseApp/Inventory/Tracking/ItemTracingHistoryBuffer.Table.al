// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

table 6521 "Item Tracing History Buffer"
{
    Caption = 'Item Tracing History Buffer';
    ReplicateData = false;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; Level; Integer)
        {
            Caption = 'Level';
            DataClassification = SystemMetadata;
        }
        field(10; "Serial No. Filter"; Code[250])
        {
            Caption = 'Serial No. Filter';
            DataClassification = SystemMetadata;
        }
        field(11; "Lot No. Filter"; Code[250])
        {
            Caption = 'Lot No. Filter';
            DataClassification = SystemMetadata;
        }
        field(12; "Item No. Filter"; Code[250])
        {
            Caption = 'Item No. Filter';
            DataClassification = SystemMetadata;
        }
        field(13; "Variant Filter"; Code[250])
        {
            Caption = 'Variant Filter';
            DataClassification = SystemMetadata;
        }
        field(14; "Trace Method"; Option)
        {
            Caption = 'Trace Method';
            DataClassification = SystemMetadata;
            OptionCaption = 'Origin->Usage,Usage->Origin';
            OptionMembers = "Origin->Usage","Usage->Origin";
        }
        field(15; "Show Components"; Option)
        {
            Caption = 'Show Components';
            DataClassification = SystemMetadata;
            OptionCaption = 'No,Item-tracked only,All';
            OptionMembers = No,"Item-tracked only",All;
        }
        field(16; "Package No. Filter"; Code[250])
        {
            Caption = 'Package No. Filter';
            CaptionClass = '6,3';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "Entry No.", Level)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

