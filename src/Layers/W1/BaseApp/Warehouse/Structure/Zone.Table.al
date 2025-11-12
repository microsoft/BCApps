// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Structure;

using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Setup;

table 7300 Zone
{
    Caption = 'Zone';
    DataCaptionFields = "Location Code", "Code", Description;
    LookupPageID = "Zone List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            Editable = false;
            NotBlank = true;
            TableRelation = Location;
        }
        field(2; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(10; "Bin Type Code"; Code[10])
        {
            Caption = 'Bin Type Code';
            TableRelation = "Bin Type";

            trigger OnValidate()
            var
                ZoneLocation: Record Location;
            begin
                if Rec."Bin Type Code" <> xRec."Bin Type Code" then
                    if Rec."Bin Type Code" <> '' then begin
                        ZoneLocation.Get(Rec."Location Code");
                        ZoneLocation.TestField("Directed Put-away and Pick", true);
                    end;
            end;
        }
        field(11; "Warehouse Class Code"; Code[10])
        {
            Caption = 'Warehouse Class Code';
            TableRelation = "Warehouse Class";
        }
        field(20; "Special Equipment Code"; Code[10])
        {
            Caption = 'Special Equipment Code';
            TableRelation = "Special Equipment";
        }
        field(21; "Zone Ranking"; Integer)
        {
            Caption = 'Zone Ranking';
        }
        field(40; "Cross-Dock Bin Zone"; Boolean)
        {
            Caption = 'Cross-Dock Bin Zone';
        }
    }

    keys
    {
        key(Key1; "Location Code", "Code")
        {
            Clustered = true;
        }
        key(Key2; "Code")
        {
        }
        key(Key3; Description)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        Bin: Record Bin;
    begin
        Bin.SetCurrentKey("Location Code", "Zone Code");
        Bin.SetRange("Location Code", "Location Code");
        Bin.SetRange("Zone Code", Code);
        OnDeleteOnBeforeDeleteAllBin(Rec, Bin);
        Bin.DeleteAll(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnBeforeDeleteAllBin(var Zone: Record Zone; var Bin: Record Bin)
    begin
    end;
}

