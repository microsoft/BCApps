// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Automation;

using System.Reflection;

table 1516 "Dynamic Request Page Field"
{
    Caption = 'Dynamic Request Page Field';
    LookupPageID = "Dynamic Request Page Fields";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            NotBlank = true;
            TableRelation = "Table Metadata".ID;

            trigger OnValidate()
            begin
                CalcFields("Table Name", "Table Caption");
            end;
        }
        field(2; "Field ID"; Integer)
        {
            Caption = 'Field ID';
            NotBlank = true;
            TableRelation = Field."No." where(TableNo = field("Table ID"));

            trigger OnValidate()
            begin
                CalcFields("Field Name", "Field Caption");
            end;
        }
        field(3; "Table Name"; Text[30])
        {
            CalcFormula = lookup("Table Metadata".Name where(ID = field("Table ID")));
            Caption = 'Table Name';
            FieldClass = FlowField;
        }
        field(4; "Table Caption"; Text[80])
        {
            CalcFormula = lookup("Table Metadata".Caption where(ID = field("Table ID")));
            Caption = 'Table Caption';
            FieldClass = FlowField;
        }
        field(5; "Field Name"; Text[30])
        {
            CalcFormula = lookup(Field.FieldName where(TableNo = field("Table ID"),
                                                        "No." = field("Field ID")));
            Caption = 'Field Name';
            FieldClass = FlowField;
        }
        field(6; "Field Caption"; Text[80])
        {
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Table ID"),
                                                              "No." = field("Field ID")));
            Caption = 'Field Caption';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Table ID", "Field ID")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

