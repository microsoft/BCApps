// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location;

using Microsoft.Inventory.Item;

table 5701 "Stockkeeping Unit Comment Line"
{
    Caption = 'Stockkeeping Unit Comment Line';
    DrillDownPageID = "Stockkeeping Unit Comment List";
    LookupPageID = "Stockkeeping Unit Comment List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            NotBlank = true;
            TableRelation = Item;
        }
        field(2; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(3; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(4; "Line No."; Integer)
        {
            BlankZero = false;
            Caption = 'Line No.';
        }
        field(5; Date; Date)
        {
            Caption = 'Date';
        }
        field(6; "Code"; Code[10])
        {
            Caption = 'Code';
        }
        field(7; Comment; Text[80])
        {
            Caption = 'Comment';
        }
    }

    keys
    {
        key(Key1; "Item No.", "Variant Code", "Location Code", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure SetUpNewLine()
    var
        StockkeepingUnitCommentLine: Record "Stockkeeping Unit Comment Line";
    begin
        StockkeepingUnitCommentLine.SetRange("Item No.", "Item No.");
        StockkeepingUnitCommentLine.SetRange("Variant Code", "Variant Code");
        StockkeepingUnitCommentLine.SetRange("Location Code", "Location Code");
        StockkeepingUnitCommentLine.SetRange(Date, WorkDate());
        if not StockkeepingUnitCommentLine.FindFirst() then
            Date := WorkDate();

        OnAfterSetUpNewLine(Rec, StockkeepingUnitCommentLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var StockkeepingUnitCommentLineRec: Record "Stockkeeping Unit Comment Line"; var StockkeepingUnitCommentLineFilter: Record "Stockkeeping Unit Comment Line")
    begin
    end;
}

