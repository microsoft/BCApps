// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

table 260 "Tariff Number"
{
    Caption = 'Tariff Number';
    LookupPageID = "Tariff Numbers";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Supplementary Units"; Boolean)
        {
            Caption = 'Supplementary Units';

            trigger OnValidate()
            begin
                if not "Supplementary Units" then begin
                    "Conversion Factor" := 0;
                    "Unit of Measure" := '';
                end;
            end;
        }
        field(11315; "Conversion Factor"; Decimal)
        {
            Caption = 'Conversion Factor';

            trigger OnValidate()
            begin
                TestField("Supplementary Units", true);
            end;
        }
        field(11316; "Unit of Measure"; Text[10])
        {
            Caption = 'Unit of Measure';

            trigger OnValidate()
            begin
                TestField("Supplementary Units", true);
            end;
        }
        field(11317; "Weight Mandatory"; Boolean)
        {
            Caption = 'Weight Mandatory';
            InitValue = true;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description)
        {
        }
    }
}

