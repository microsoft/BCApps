// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Structure;

using Microsoft.Inventory.Location;

table 7337 "Bin Creation Wksh. Name"
{
    Caption = 'Bin Creation Wksh. Name';
    DataCaptionFields = Name, Description;
    LookupPageID = "Bin Creation Wksh. Names";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Worksheet Template Name"; Code[10])
        {
            Caption = 'Worksheet Template Name';
            NotBlank = true;
            TableRelation = "Bin Creation Wksh. Template";
        }
        field(2; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(7; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            NotBlank = true;
            TableRelation = Location;

            trigger OnValidate()
            var
                Location: Record Location;
            begin
                Location.Get("Location Code");
                Location.TestField("Bin Mandatory", true);
            end;
        }
        field(21; "Template Type"; Option)
        {
            CalcFormula = lookup("Bin Creation Wksh. Template".Type where(Name = field("Worksheet Template Name")));
            Caption = 'Template Type';
            Editable = false;
            FieldClass = FlowField;
            OptionCaption = 'Put-away,Pick,Movement';
            OptionMembers = "Put-away",Pick,Movement;
        }
    }

    keys
    {
        key(Key1; "Worksheet Template Name", Name, "Location Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        BinCreateWkshLine.SetRange("Worksheet Template Name", "Worksheet Template Name");
        BinCreateWkshLine.SetRange(Name, Name);
        BinCreateWkshLine.SetRange("Location Code", "Location Code");
        BinCreateWkshLine.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        LockTable();
        BinCreateWkshTemplate.Get("Worksheet Template Name");
    end;

    trigger OnRename()
    begin
        BinCreateWkshLine.SetRange("Worksheet Template Name", xRec."Worksheet Template Name");
        BinCreateWkshLine.SetRange(Name, xRec.Name);
        BinCreateWkshLine.SetRange("Location Code", xRec."Location Code");
        while BinCreateWkshLine.FindFirst() do
            BinCreateWkshLine.Rename("Worksheet Template Name", Name, "Location Code", BinCreateWkshLine."Line No.");
    end;

    var
        BinCreateWkshTemplate: Record "Bin Creation Wksh. Template";
        BinCreateWkshLine: Record "Bin Creation Worksheet Line";

    procedure SetupNewName()
    begin
        BinCreateWkshTemplate.Get("Worksheet Template Name");
    end;
}

