// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Request;

using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.Structure;

table 7324 "Whse. Put-away Request"
{
    Caption = 'Whse. Put-away Request';
    LookupPageID = "Put-away Selection";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Type"; Enum "Warehouse Put-away Request Document Type")
        {
            Caption = 'Document Type';
        }
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = if ("Document Type" = const(Receipt)) "Posted Whse. Receipt Header"."No."
            else
            if ("Document Type" = const("Internal Put-away")) "Whse. Internal Put-away Header"."No.";

            trigger OnLookup()
            var
                PostedWhseRcptHeader: Record "Posted Whse. Receipt Header";
                WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
                PostedWhseRcptList: Page "Posted Whse. Receipt List";
                WhseInternalPutAwayList: Page "Whse. Internal Put-away List";
            begin
                if "Document Type" = "Document Type"::Receipt then begin
                    if PostedWhseRcptHeader.Get("Document No.") then
                        PostedWhseRcptList.SetRecord(PostedWhseRcptHeader);
                    PostedWhseRcptList.RunModal();
                    Clear(PostedWhseRcptList);
                end else begin
                    if WhseInternalPutAwayHeader.Get("Document No.") then
                        WhseInternalPutAwayList.SetRecord(WhseInternalPutAwayHeader);
                    WhseInternalPutAwayList.RunModal();
                    Clear(WhseInternalPutAwayList);
                end;
            end;
        }
        field(3; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(4; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
            TableRelation = Zone.Code where("Location Code" = field("Location Code"));
        }
        field(5; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = if ("Zone Code" = filter('')) Bin.Code where("Location Code" = field("Location Code"))
            else
            if ("Zone Code" = filter(<> '')) Bin.Code where("Location Code" = field("Location Code"),
                                                                               "Zone Code" = field("Zone Code"));
        }
        field(7; "Completely Put Away"; Boolean)
        {
            Caption = 'Completely Put Away';
        }
        field(8; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Open,Released';
            OptionMembers = Open,Released;
        }
    }

    keys
    {
        key(Key1; "Document Type", "Document No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
}

