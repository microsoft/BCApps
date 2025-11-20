// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Resource;

table 160 "Res. Capacity Entry"
{
    Caption = 'Res. Capacity Entry';
    DrillDownPageID = "Res. Capacity Entries";
    LookupPageID = "Res. Capacity Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            TableRelation = Resource;

            trigger OnValidate()
            begin
                Res.Get("Resource No.");
                "Resource Group No." := Res."Resource Group No.";
            end;
        }
        field(3; "Resource Group No."; Code[20])
        {
            Caption = 'Resource Group No.';
            TableRelation = "Resource Group";
        }
        field(4; Date; Date)
        {
            Caption = 'Date';
        }
        field(5; Capacity; Decimal)
        {
            Caption = 'Capacity';
            DecimalPlaces = 0 : 5;
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Resource No.", Date)
        {
            SumIndexFields = Capacity;
        }
        key(Key3; "Resource Group No.", Date)
        {
            SumIndexFields = Capacity;
        }
    }

    fieldgroups
    {
    }

    var
        Res: Record Resource;
}

