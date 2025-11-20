// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;

table 6504 "Serial No. Information"
{
    Caption = 'Serial No. Information';
    DataCaptionFields = "Item No.", "Variant Code", "Serial No.", Description;
    DrillDownPageID = "Serial No. Information List";
    LookupPageID = "Serial No. Information List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            OptimizeForTextSearch = true;
            NotBlank = true;
            TableRelation = Item;
        }
        field(2; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(3; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            OptimizeForTextSearch = true;
            ExtendedDatatype = Barcode;
            NotBlank = true;
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
            OptimizeForTextSearch = true;
        }
        field(13; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(14; Comment; Boolean)
        {
            CalcFormula = exist("Item Tracking Comment" where(Type = const("Serial No."),
                                                               "Item No." = field("Item No."),
                                                               "Variant Code" = field("Variant Code"),
                                                               "Serial/Lot No." = field("Serial No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; Inventory; Decimal)
        {
            CalcFormula = sum("Item Ledger Entry".Quantity where("Item No." = field("Item No."),
                                                                  "Variant Code" = field("Variant Code"),
                                                                  "Serial No." = field("Serial No."),
                                                                  "Location Code" = field("Location Filter")));
            Caption = 'Inventory';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(21; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(22; "Location Filter"; Code[10])
        {
            Caption = 'Location Filter';
            FieldClass = FlowFilter;
            TableRelation = Location;
        }
        field(23; "Bin Filter"; Code[20])
        {
            Caption = 'Bin Filter';
            FieldClass = FlowFilter;
            TableRelation = Bin.Code where("Location Code" = field("Location Filter"));
        }
        field(24; "Expired Inventory"; Decimal)
        {
            CalcFormula = sum("Item Ledger Entry"."Remaining Quantity" where("Item No." = field("Item No."),
                                                                              "Variant Code" = field("Variant Code"),
                                                                              "Serial No." = field("Serial No."),
                                                                              "Location Code" = field("Location Filter"),
                                                                              "Expiration Date" = field("Date Filter"),
                                                                              Open = const(true),
                                                                              Positive = const(true)));
            Caption = 'Expired Inventory';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Item No.", "Variant Code", "Serial No.")
        {
            Clustered = true;
        }
        key(Key2; "Serial No.")
        {
            Enabled = false;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Item No.", "Variant Code", "Serial No.")
        {
        }
    }

    trigger OnDelete()
    begin
        ItemTrackingComment.SetRange(Type, ItemTrackingComment.Type::"Serial No.");
        ItemTrackingComment.SetRange("Item No.", "Item No.");
        ItemTrackingComment.SetRange("Variant Code", "Variant Code");
        ItemTrackingComment.SetRange("Serial/Lot No.", "Serial No.");
        ItemTrackingComment.DeleteAll();
    end;

    var
        ItemTrackingComment: Record "Item Tracking Comment";

    procedure ShowCard(SerialNo: Code[50]; TrackingSpecification: Record "Tracking Specification")
    var
        SerialNoInfoNew: Record "Serial No. Information";
        SerialNoInfoForm: Page "Serial No. Information Card";
    begin
        Clear(SerialNoInfoForm);
        SerialNoInfoForm.Init(TrackingSpecification);

        SerialNoInfoNew.SetRange("Item No.", TrackingSpecification."Item No.");
        SerialNoInfoNew.SetRange("Variant Code", TrackingSpecification."Variant Code");
        SerialNoInfoNew.SetRange("Serial No.", SerialNo);

        SerialNoInfoForm.SetTableView(SerialNoInfoNew);
        SerialNoInfoForm.Run();
    end;

    procedure ShowCard(SerialNo: Code[50]; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    var
        SerialNoInfoNew: Record "Serial No. Information";
        SerialNoInfoForm: Page "Serial No. Information Card";
    begin
        Clear(SerialNoInfoForm);
        SerialNoInfoForm.InitWhse(WhseItemTrackingLine);

        SerialNoInfoNew.SetRange("Item No.", WhseItemTrackingLine."Item No.");
        SerialNoInfoNew.SetRange("Variant Code", WhseItemTrackingLine."Variant Code");
        SerialNoInfoNew.SetRange("Serial No.", SerialNo);

        SerialNoInfoForm.SetTableView(SerialNoInfoNew);
        SerialNoInfoForm.Run();
    end;
}

