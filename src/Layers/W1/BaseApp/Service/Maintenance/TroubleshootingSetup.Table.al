// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Maintenance;

using Microsoft.Inventory.Item;
using Microsoft.Service.Item;

table 5945 "Troubleshooting Setup"
{
    Caption = 'Troubleshooting Setup';
    DataCaptionFields = "No.";
    DrillDownPageID = "Troubleshooting Setup";
    LookupPageID = "Troubleshooting Setup";
    DataClassification = CustomerContent;

    fields
    {
        field(1; Type; Enum "Troubleshooting Item Type")
        {
            Caption = 'Type';

            trigger OnValidate()
            begin
                if Type <> xRec.Type then
                    "No." := '';
            end;
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const("Service Item Group")) "Service Item Group"
            else
            if (Type = const(Item)) Item
            else
            if (Type = const("Service Item")) "Service Item";
        }
        field(3; "Troubleshooting No."; Code[20])
        {
            Caption = 'Troubleshooting No.';
            NotBlank = true;
            TableRelation = "Troubleshooting Header";

            trigger OnValidate()
            begin
                CalcFields("Troubleshooting Description");
            end;
        }
        field(4; "Troubleshooting Description"; Text[100])
        {
            CalcFormula = lookup("Troubleshooting Header".Description where("No." = field("Troubleshooting No.")));
            Caption = 'Troubleshooting Description';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; Type, "No.", "Troubleshooting No.")
        {
            Clustered = true;
        }
        key(Key2; "Troubleshooting No.", Type, "No.")
        {
        }
    }

    fieldgroups
    {
    }
}

