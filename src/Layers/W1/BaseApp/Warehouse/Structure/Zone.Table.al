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
            ToolTip = 'Specifies the location code of the zone.';
            Editable = false;
            NotBlank = true;
            TableRelation = Location;
        }
        field(2; "Code"; Code[10])
        {
            Caption = 'Code';
            ToolTip = 'Specifies the code of the zone.';
            NotBlank = true;
        }
        field(5; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the zone.';
        }
        field(10; "Bin Type Code"; Code[10])
        {
            Caption = 'Bin Type Code';
            ToolTip = 'Specifies the bin type code for the zone. The bin type determines the inbound and outbound flow of items.';
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
            ToolTip = 'Specifies the warehouse class code of the zone. You can store items with the same warehouse class code in this zone.';
            TableRelation = "Warehouse Class";
        }
        field(20; "Special Equipment Code"; Code[10])
        {
            Caption = 'Special Equipment Code';
            ToolTip = 'Specifies the code of the special equipment to be used when you work in this zone.';
            TableRelation = "Special Equipment";
        }
        field(21; "Zone Ranking"; Integer)
        {
            Caption = 'Zone Ranking';
            ToolTip = 'Specifies the ranking of the zone, which is copied to all bins created within the zone.';
        }
        field(40; "Cross-Dock Bin Zone"; Boolean)
        {
            Caption = 'Cross-Dock Bin Zone';
            ToolTip = 'Specifies if this is a cross-dock zone.';
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

