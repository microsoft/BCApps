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

table 6505 "Lot No. Information"
{
    Caption = 'Lot No. Information';
    DataCaptionFields = "Item No.", "Variant Code", "Lot No.", Description;
    DrillDownPageID = "Lot No. Information List";
    LookupPageID = "Lot No. Information List";
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
        field(3; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
            OptimizeForTextSearch = true;
            ExtendedDatatype = Barcode;
            NotBlank = true;
        }
        field(10; Description; Text[100])
        {
            Caption = 'Description';
            OptimizeForTextSearch = true;
        }
        field(11; "Test Quality"; Option)
        {
            Caption = 'Test Quality';
            OptionCaption = ' ,Good,Average,Bad';
            OptionMembers = " ",Good,"Average",Bad;
        }
        field(12; "Certificate Number"; Code[20])
        {
            Caption = 'Certificate Number';
        }
        field(13; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(14; Comment; Boolean)
        {
            CalcFormula = exist("Item Tracking Comment" where(Type = const("Lot No."),
                                                               "Item No." = field("Item No."),
                                                               "Variant Code" = field("Variant Code"),
                                                               "Serial/Lot No." = field("Lot No.")));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(20; Inventory; Decimal)
        {
            CalcFormula = sum("Item Ledger Entry".Quantity where("Item No." = field("Item No."),
                                                                  "Variant Code" = field("Variant Code"),
                                                                  "Lot No." = field("Lot No."),
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
                                                                              "Lot No." = field("Lot No."),
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
        key(Key1; "Item No.", "Variant Code", "Lot No.")
        {
            Clustered = true;
        }
        key(Key2; "Lot No.")
        {
            Enabled = false;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Item No.", "Variant Code", "Lot No.")
        {
        }
    }

    trigger OnDelete()
    begin
        ItemTrackingComment.SetRange(Type, ItemTrackingComment.Type::"Lot No.");
        ItemTrackingComment.SetRange("Item No.", "Item No.");
        ItemTrackingComment.SetRange("Variant Code", "Variant Code");
        ItemTrackingComment.SetRange("Serial/Lot No.", "Lot No.");
        ItemTrackingComment.DeleteAll();
    end;

    var
        ItemTrackingComment: Record "Item Tracking Comment";

    procedure ShowCard(LotNo: Code[50]; TrackingSpecification: Record "Tracking Specification")
    var
        LotNoInfoNew: Record "Lot No. Information";
        LotNoInfoForm: Page "Lot No. Information Card";
    begin
        Clear(LotNoInfoForm);
        LotNoInfoForm.Init(TrackingSpecification);

        LotNoInfoNew.SetRange("Item No.", TrackingSpecification."Item No.");
        LotNoInfoNew.SetRange("Variant Code", TrackingSpecification."Variant Code");
        LotNoInfoNew.SetRange("Lot No.", LotNo);
        OnShowCardOnAfterLotNoInfoNewSetFilters(LotNoInfoNew, TrackingSpecification);

        LotNoInfoForm.SetTableView(LotNoInfoNew);
        LotNoInfoForm.Run();
    end;

    procedure ShowCard(LotNo: Code[50]; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    var
        LotNoInfoNew: Record "Lot No. Information";
        LotNoInfoForm: Page "Lot No. Information Card";
    begin
        Clear(LotNoInfoForm);
        LotNoInfoForm.InitWhse(WhseItemTrackingLine);

        LotNoInfoNew.SetRange("Item No.", WhseItemTrackingLine."Item No.");
        LotNoInfoNew.SetRange("Variant Code", WhseItemTrackingLine."Variant Code");
        LotNoInfoNew.SetRange("Lot No.", LotNo);

        LotNoInfoForm.SetTableView(LotNoInfoNew);
        LotNoInfoForm.Run();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowCardOnAfterLotNoInfoNewSetFilters(var LotNoInformation: Record "Lot No. Information"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;
}

