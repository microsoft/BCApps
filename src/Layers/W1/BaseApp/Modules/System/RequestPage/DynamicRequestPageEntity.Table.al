// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Automation;

using System.Reflection;

table 1515 "Dynamic Request Page Entity"
{
    Caption = 'Dynamic Request Page Entity';
    LookupPageID = "Dynamic Request Page Entities";
    DataClassification = CustomerContent;

    fields
    {
        field(1; Name; Code[20])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(2; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(3; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            TableRelation = "Table Metadata".ID;

            trigger OnValidate()
            begin
                CalcFields("Table Name", "Table Caption");
            end;
        }
        field(4; "Table Name"; Text[30])
        {
            CalcFormula = lookup("Table Metadata".Name where(ID = field("Table ID")));
            Caption = 'Table Name';
            FieldClass = FlowField;
        }
        field(5; "Table Caption"; Text[80])
        {
            CalcFormula = lookup("Table Metadata".Caption where(ID = field("Table ID")));
            Caption = 'Table Caption';
            FieldClass = FlowField;
        }
        field(6; "Related Table ID"; Integer)
        {
            Caption = 'Related Table ID';
            TableRelation = "Table Metadata".ID;

            trigger OnValidate()
            begin
                if "Related Table ID" = "Table ID" then
                    FieldError("Related Table ID");
                CalcFields("Related Table Name", "Related Table Caption");
            end;
        }
        field(7; "Related Table Name"; Text[30])
        {
            CalcFormula = lookup("Table Metadata".Name where(ID = field("Related Table ID")));
            Caption = 'Related Table Name';
            FieldClass = FlowField;
        }
        field(8; "Related Table Caption"; Text[80])
        {
            CalcFormula = lookup("Table Metadata".Caption where(ID = field("Related Table ID")));
            Caption = 'Related Table Caption';
            FieldClass = FlowField;
        }
        field(9; "Sequence No."; Integer)
        {
            Caption = 'Sequence No.';
            MinValue = 1;
        }
    }

    keys
    {
        key(Key1; Name, "Table ID", "Sequence No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    var
        DynamicRequestPageEntity: Record "Dynamic Request Page Entity";
        SequenceNo: Integer;
    begin
        if "Sequence No." = 0 then begin
            SequenceNo := 1;
            DynamicRequestPageEntity.SetRange(Name, Name);
            DynamicRequestPageEntity.SetRange("Table ID", "Table ID");
            if DynamicRequestPageEntity.FindLast() then
                SequenceNo := DynamicRequestPageEntity."Sequence No." + 1;
            Validate("Sequence No.", SequenceNo);
        end;
    end;
}

