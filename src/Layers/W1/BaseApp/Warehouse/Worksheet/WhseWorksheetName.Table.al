// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Worksheet;

using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Journal;

table 7327 "Whse. Worksheet Name"
{
    Caption = 'Whse. Worksheet Name';
    DataCaptionFields = Name, Description, "Location Code";
    LookupPageID = "Worksheet Names List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Worksheet Template Name"; Code[10])
        {
            Caption = 'Worksheet Template Name';
            TableRelation = "Whse. Worksheet Template";
        }
        field(2; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(3; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(4; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(21; "Template Type"; Enum "Warehouse Worksheet Template Type")
        {
            CalcFormula = lookup("Whse. Worksheet Template".Type where(Name = field("Worksheet Template Name")));
            Caption = 'Template Type';
            Editable = false;
            FieldClass = FlowField;
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
    var
        WhseWkshLine: Record "Whse. Worksheet Line";
    begin
        WhseWkshLine.SetRange("Worksheet Template Name", "Worksheet Template Name");
        WhseWkshLine.SetRange(Name, Name);
        WhseWkshLine.SetRange("Location Code", "Location Code");
        WhseWkshLine.DeleteAll(true);
    end;

    trigger OnInsert()
    begin
        TestWMSLocation();
    end;

    trigger OnModify()
    begin
        TestWMSLocation();
    end;

    trigger OnRename()
    var
        WhseWkshLine: Record "Whse. Worksheet Line";
    begin
        TestWMSLocation();
        WhseWkshLine.SetRange("Worksheet Template Name", xRec."Worksheet Template Name");
        WhseWkshLine.SetRange(Name, xRec.Name);
        WhseWkshLine.SetRange("Location Code", xRec."Location Code");
        while WhseWkshLine.FindFirst() do
            WhseWkshLine.Rename("Worksheet Template Name", Name, "Location Code", WhseWkshLine."Line No.");
    end;

    var
        Location: Record Location;
        WhseWkshTemplate: Record "Whse. Worksheet Template";

    procedure SetupNewName()
    var
        WMSMgt: Codeunit "WMS Management";
    begin
        if UserId <> '' then
            GetLocation(WMSMgt.GetDefaultLocation());

        "Location Code" := Location.Code;
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Location.Init()
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure TestWMSLocation()
    begin
        WhseWkshTemplate.Get("Worksheet Template Name");
        if WhseWkshTemplate.Type = WhseWkshTemplate.Type::Movement then begin
            TestField("Location Code");
            GetLocation("Location Code");
            Location.TestField("Bin Mandatory");
        end;
    end;
}

