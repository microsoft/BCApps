// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Comment;

using Microsoft.Warehouse.Activity;

table 5770 "Warehouse Comment Line"
{
    Caption = 'Warehouse Comment Line';
    DrillDownPageID = "Warehouse Comment List";
    LookupPageID = "Warehouse Comment List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table Name"; Option)
        {
            Caption = 'Table Name';
            OptionCaption = 'Whse. Activity Header,Whse. Receipt,Whse. Shipment,Internal Put-away,Internal Pick,Rgstrd. Whse. Activity Header,Posted Whse. Receipt,Posted Whse. Shipment,Posted Invt. Put-Away,Posted Invt. Pick,Registered Invt. Movement,Internal Movement';
            OptionMembers = "Whse. Activity Header","Whse. Receipt","Whse. Shipment","Internal Put-away","Internal Pick","Rgstrd. Whse. Activity Header","Posted Whse. Receipt","Posted Whse. Shipment","Posted Invt. Put-Away","Posted Invt. Pick","Registered Invt. Movement","Internal Movement";
        }
        field(2; Type; Enum "Warehouse Activity Type")
        {
            Caption = 'Type';
        }
        field(3; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(4; "Line No."; Integer)
        {
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
        key(Key1; "Table Name", Type, "No.", "Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure SetUpNewLine()
    var
        WhseCommentLine: Record "Warehouse Comment Line";
    begin
        WhseCommentLine.SetRange("Table Name", "Table Name");
        WhseCommentLine.SetRange(Type, Type);
        WhseCommentLine.SetRange("No.", "No.");
        WhseCommentLine.SetRange(Date, WorkDate());
        if WhseCommentLine.IsEmpty() then
            Date := WorkDate();

        OnAfterSetUpNewLine(Rec, WhseCommentLine);
    end;

    procedure FormCaption(): Text
    begin
        if ("Table Name" = "Table Name"::"Whse. Activity Header") or
           ("Table Name" = "Table Name"::"Rgstrd. Whse. Activity Header")
        then
            exit(Format(Type) + ' ' + "No.");

        exit(Format("Table Name") + ' ' + "No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var WarehouseCommentLineRec: Record "Warehouse Comment Line"; var WarehouseCommentLineFilter: Record "Warehouse Comment Line")
    begin
    end;
}

