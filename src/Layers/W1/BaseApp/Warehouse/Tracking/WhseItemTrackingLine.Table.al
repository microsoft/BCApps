// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Tracking;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Utilities;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Worksheet;

table 6550 "Whse. Item Tracking Line"
{
    Caption = 'Whse. Item Tracking Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(3; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(4; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if "Quantity (Base)" < 0 then
                    FieldError("Quantity (Base)", Text004);

                if "Quantity (Base)" < "Quantity Handled (Base)" then
                    FieldError("Quantity (Base)", StrSubstNo(Text002, FieldCaption("Quantity Handled (Base)")));

                CheckSerialNoQty();

                InitQtyToHandle();
            end;
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(10; "Source Type"; Integer)
        {
            Caption = 'Source Type';
        }
        field(11; "Source Subtype"; Option)
        {
            Caption = 'Source Subtype';
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(12; "Source ID"; Code[20])
        {
            Caption = 'Source ID';
        }
        field(13; "Source Batch Name"; Code[10])
        {
            Caption = 'Source Batch Name';
        }
        field(14; "Source Prod. Order Line"; Integer)
        {
            Caption = 'Source Prod. Order Line';
        }
        field(15; "Source Ref. No."; Integer)
        {
            Caption = 'Source Ref. No.';
        }
        field(24; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';

            trigger OnValidate()
            begin
                if "Serial No." <> xRec."Serial No." then begin
                    TestField("Quantity Handled (Base)", 0);
                    if IsReclass("Source Type", "Source Batch Name") then
                        "New Serial No." := "Serial No.";
                    CheckSerialNoQty();
                    InitExpirationDate();
                end;
            end;
        }
        field(29; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(40; "Warranty Date"; Date)
        {
            Caption = 'Warranty Date';
        }
        field(41; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';

            trigger OnValidate()
            begin
                "New Expiration Date" := "Expiration Date";
            end;
        }
        field(50; "Qty. to Handle (Base)"; Decimal)
        {
            Caption = 'Qty. to Handle (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                if "Qty. to Handle (Base)" < 0 then
                    FieldError("Qty. to Handle (Base)", Text004);

                if "Qty. to Handle (Base)" > ("Quantity (Base)" - "Quantity Handled (Base)")
                then
                    Error(
                      Text001,
                      "Quantity (Base)" - "Quantity Handled (Base)");

                "Qty. to Handle" := CalcQty("Qty. to Handle (Base)");
            end;
        }
        field(51; "Qty. to Invoice (Base)"; Decimal)
        {
            Caption = 'Qty. to Invoice (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(52; "Quantity Handled (Base)"; Decimal)
        {
            Caption = 'Quantity Handled (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(53; "Quantity Invoiced (Base)"; Decimal)
        {
            Caption = 'Quantity Invoiced (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(60; "Qty. to Handle"; Decimal)
        {
            Caption = 'Qty. to Handle';
            DecimalPlaces = 0 : 5;
        }
        field(70; "Buffer Status"; Option)
        {
            Caption = 'Buffer Status';
            Editable = false;
            OptionCaption = ' ,MODIFY';
            OptionMembers = " ",MODIFY;
        }
        field(71; "Buffer Status2"; Option)
        {
            Caption = 'Buffer Status2';
            Editable = false;
            OptionCaption = ',ExpDate blocked';
            OptionMembers = ,"ExpDate blocked";
        }
        field(80; "New Serial No."; Code[50])
        {
            Caption = 'New Serial No.';

            trigger OnValidate()
            begin
                CheckSerialNoQty();
            end;
        }
        field(81; "New Lot No."; Code[50])
        {
            Caption = 'New Lot No.';
        }
        field(90; "Source Type Filter"; Option)
        {
            Caption = 'Source Type Filter';
            FieldClass = FlowFilter;
            OptionCaption = ' ,Receipt,Shipment,Internal Put-away,Internal Pick,Production,Movement Worksheet,Assembly,Project';
            OptionMembers = " ",Receipt,Shipment,"Internal Put-away","Internal Pick",Production,"Movement Worksheet",Assembly,Job;
        }
        field(91; "Qty. Registered (Base)"; Decimal)
        {
            Caption = 'Qty. Registered (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(92; "Put-away Qty. (Base)"; Decimal)
        {
            CalcFormula = sum("Warehouse Activity Line"."Qty. Outstanding (Base)" where("Activity Type" = filter("Put-away"),
#pragma warning disable AL0603
                                                                                         "Whse. Document Type" = field("Source Type Filter"),
#pragma warning restore AL0603
                                                                                         "Whse. Document No." = field("Source ID"),
                                                                                         "Whse. Document Line No." = field("Source Ref. No."),
                                                                                         "Serial No." = field("Serial No."),
                                                                                         "Lot No." = field("Lot No."),
                                                                                         "Package No." = field("Package No."),
                                                                                         "Action Type" = filter(" " | Take)));
            Caption = 'Put-away Qty. (Base)';
            DecimalPlaces = 0 : 5;
            FieldClass = FlowField;
        }
        field(93; "Pick Qty. (Base)"; Decimal)
        {
            CalcFormula = sum("Warehouse Activity Line"."Qty. Outstanding (Base)" where("Activity Type" = filter(Pick | Movement),
#pragma warning disable AL0603
                                                                                         "Whse. Document Type" = field("Source Type Filter"),
#pragma warning restore AL0603
                                                                                         "Whse. Document No." = field("Source ID"),
                                                                                         "Whse. Document Line No." = field("Source Ref. No."),
                                                                                         "Serial No." = field("Serial No."),
                                                                                         "Lot No." = field("Lot No."),
                                                                                         "Package No." = field("Package No."),
                                                                                         "Action Type" = filter(" " | Place)));
            Caption = 'Pick Qty. (Base)';
            DecimalPlaces = 0 : 5;
            FieldClass = FlowField;
        }
        field(94; "Created by Whse. Activity Line"; Boolean)
        {
            Caption = 'Created by Whse. Activity Line';
        }
        field(5400; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';

            trigger OnValidate()
            begin
                if "Lot No." <> xRec."Lot No." then begin
                    TestField("Quantity Handled (Base)", 0);
                    if IsReclass("Source Type", "Source Batch Name") then
                        "New Lot No." := "Lot No.";
                    InitExpirationDate();
                end;
            end;
        }
        field(5401; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(6505; "New Expiration Date"; Date)
        {
            Caption = 'New Expiration Date';
        }
        field(6515; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            CaptionClass = '6,1';

            trigger OnValidate()
            begin
                if "Package No." <> xRec."Package No." then begin
                    TestField("Quantity Handled (Base)", 0);
                    if IsReclass("Source Type", "Source Batch Name") then
                        "New Package No." := "Package No.";
                end;
            end;
        }
        field(6516; "New Package No."; Code[50])
        {
            Caption = 'New Package No.';
            CaptionClass = '6,2';
        }
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Source ID", "Source Type", "Source Subtype", "Source Batch Name", "Source Prod. Order Line", "Source Ref. No.", "Location Code")
        {
            IncludedFields = "Quantity (Base)", "Qty. to Handle (Base)", "Qty. to Invoice (Base)", "Quantity Handled (Base)", "Quantity Invoiced (Base)";
        }
#pragma warning disable AS0009
        key(Key3; "Serial No.", "Lot No.", "Package No.")
#pragma warning restore AS0009
        {
        }
        key(Key4; "Item No.", "Variant Code", "Location Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Lot No.", "Serial No.", "Quantity (Base)", "Package No.", "Expiration Date")
        { }
    }

    trigger OnDelete()
    begin
        TestField("Quantity Handled (Base)", 0);
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'You cannot handle more than %1 units.';
        Text002: Label 'must not be less than %1';
        Text003: Label '%1 must be 0 or 1 when %2 is stated.';
#pragma warning restore AA0470
        Text004: Label 'must not be negative';
#pragma warning restore AA0074

    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    local procedure CheckSerialNoQty()
    var
        IsHandled: Boolean;
    begin
        if ("Serial No." = '') and ("New Serial No." = '') then
            exit;

        IsHandled := false;
        OnBeforeCheckSerialNoQty(Rec, IsHandled);
        if not IsHandled then
            if not ("Quantity (Base)" in [0, 1]) then
                Error(Text003, FieldCaption("Quantity (Base)"), FieldCaption("Serial No."));
    end;

    local procedure CalcQty(BaseQty: Decimal): Decimal
    var
        UnitOfMeasureManagement: Codeunit "Unit of Measure Management";
    begin
        if "Qty. per Unit of Measure" = 0 then
            "Qty. per Unit of Measure" := 1;
        exit(Round(BaseQty / "Qty. per Unit of Measure", UnitOfMeasureManagement.QtyRndPrecision()));
    end;

    procedure InitQtyToHandle()
    begin
        "Qty. to Handle (Base)" := "Quantity (Base)" - "Quantity Handled (Base)";
        "Qty. to Handle" := CalcQty("Qty. to Handle (Base)");

        OnAfterInitQtyToHandle(Rec, xRec, CurrFieldNo);
    end;

    procedure InitExpirationDate()
    var
        Location: Record Location;
        ItemTrackingSetup: Record "Item Tracking Setup";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        ExpDate: Date;
        WarDate: Date;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitExpirationDate(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if xRec.HasSameTracking(Rec) then
            exit;

        "Expiration Date" := 0D;
        "Buffer Status2" := 0;

        Location.Init();
        if "Location Code" <> '' then
            Location.Get("Location Code");

        ItemTrackingSetup.CopyTrackingFromWhseItemTrackingLine(Rec);

        if ItemTrackingManagement.GetWhseExpirationDate("Item No.", "Variant Code", Location, ItemTrackingSetup, ExpDate) then begin
            "Expiration Date" := ExpDate;
            "Buffer Status2" := "Buffer Status2"::"ExpDate blocked";
        end;

        if IsReclass("Source Type", "Source Batch Name") then begin
            "New Expiration Date" := "Expiration Date";
            if ItemTrackingManagement.GetWhseWarrantyDate("Item No.", "Variant Code", Location, ItemTrackingSetup, WarDate) then
                "Warranty Date" := WarDate;
        end;
    end;

    procedure IsReclass(SourceType: Integer; SourceBatchName: Code[10]): Boolean
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        if SourceType = Database::"Warehouse Journal Line" then
            exit(WarehouseJournalLine.IsReclass(SourceBatchName));

        exit(false);
    end;

    procedure LookUpTrackingSummary(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; TrackingType: Enum "Item Tracking Type"; MaxQuantity: Decimal; SignFactor: Integer; SearchForSupply: Boolean)
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseInternalPutawayLine: Record "Whse. Internal Put-away Line";
        InternalMovementLine: Record "Internal Movement Line";
        ItemTrackingDataCollection: Codeunit "Item Tracking Data Collection";
        BinCode: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookUpTrackingSummary(WhseItemTrackingLine, TrackingType, MaxQuantity, SignFactor, true, IsHandled);
        if IsHandled then
            exit;

        case WhseItemTrackingLine."Source Type" of
            Database::"Warehouse Journal Line":
                begin
                    WarehouseJournalLine.Get(
                        WhseItemTrackingLine."Source Batch Name", WhseItemTrackingLine."Source ID",
                        WhseItemTrackingLine."Location Code", WhseItemTrackingLine."Source Ref. No.");
                    BinCode := WarehouseJournalLine."Bin Code";
                end;
            Database::"Whse. Worksheet Line":
                begin
                    WhseWorksheetLine.Get(
                        WhseItemTrackingLine."Source Batch Name", WhseItemTrackingLine."Source ID",
                        WhseItemTrackingLine."Location Code", WhseItemTrackingLine."Source Ref. No.");
                    BinCode := WhseWorksheetLine."From Bin Code";
                end;
            Database::"Whse. Internal Put-away Line":
                begin
                    WhseInternalPutawayLine.Get(
                        WhseItemTrackingLine."Source ID", WhseItemTrackingLine."Source Ref. No.");
                    BinCode := WhseInternalPutawayLine."From Bin Code";
                end;
            Database::"Internal Movement Line":
                begin
                    InternalMovementLine.Get(
                        WhseItemTrackingLine."Source ID", WhseItemTrackingLine."Source Ref. No.");
                    BinCode := InternalMovementLine."From Bin Code";
                end;
            else
                exit;
        end;

        TempTrackingSpecification.Init();
        TempTrackingSpecification.SetItemData(
            WhseItemTrackingLine."Item No.", WhseItemTrackingLine.Description, WhseItemTrackingLine."Location Code",
            WhseItemTrackingLine."Variant Code", BinCode, WhseItemTrackingLine."Qty. per Unit of Measure");
        TempTrackingSpecification.SetSource(
            WhseItemTrackingLine."Source Type", WhseItemTrackingLine."Source Subtype", WhseItemTrackingLine."Source ID",
            WhseItemTrackingLine."Source Ref. No.", WhseItemTrackingLine."Source Batch Name", WhseItemTrackingLine."Source Prod. Order Line");
        TempTrackingSpecification."Quantity (Base)" := WhseItemTrackingLine."Quantity (Base)";
        TempTrackingSpecification."Qty. to Handle" := WhseItemTrackingLine."Qty. to Handle";
        TempTrackingSpecification."Qty. to Handle (Base)" := WhseItemTrackingLine."Qty. to Handle (Base)";
        Clear(ItemTrackingDataCollection);
        ItemTrackingDataCollection.AssistEditTrackingNo(
            TempTrackingSpecification, SearchForSupply, SignFactor, TrackingType, MaxQuantity);
        WhseItemTrackingLine.Validate("Quantity (Base)", TempTrackingSpecification."Quantity (Base)");
        case TrackingType of
            TrackingType::"Serial No.":
                if TempTrackingSpecification."Serial No." <> '' then
                    WhseItemTrackingLine.Validate("Serial No.", TempTrackingSpecification."Serial No.");
            TrackingType::"Lot No.":
                if TempTrackingSpecification."Lot No." <> '' then
                    WhseItemTrackingLine.Validate("Lot No.", TempTrackingSpecification."Lot No.");
        end;

        OnAfterLookUpTrackingSummary(WhseItemTrackingLine, TrackingType, TempTrackingSpecification);
    end;

    procedure CheckTrackingIfRequired(WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Serial No. Required" then
            TestField("Serial No.");
        if WhseItemTrackingSetup."Lot No. Required" then
            TestField("Lot No.");

        OnAfterCheckTrackingIfRequired(Rec, WhseItemTrackingSetup);
    end;

    procedure SetTrackingFilterFromItemTrackingSetupIfNotBlank(ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if ItemTrackingSetup."Serial No." <> '' then
            SetRange("Serial No.", ItemTrackingSetup."Serial No.");
        if ItemTrackingSetup."Lot No." <> '' then
            SetRange("Lot No.", ItemTrackingSetup."Lot No.");

        OnAfterSetTrackingFilterFromItemTrackingSetupIfNotBlank(Rec, ItemTrackingSetup);
    end;

    procedure ClearTrackingFilter()
    begin
        SetRange("Serial No.");
        SetRange("Lot No.");

        OnAfterClearTrackingFilter(Rec);
    end;

    procedure CopyTrackingFromEntrySummary(EntrySummary: Record "Entry Summary")
    begin
        "Serial No." := EntrySummary."Serial No.";
        "Lot No." := EntrySummary."Lot No.";

        OnAfterCopyTrackingFromEntrySummary(Rec, EntrySummary);
    end;

    procedure CopyTrackingFromItemLedgEntry(ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        "Serial No." := ItemLedgerEntry."Serial No.";
        "Lot No." := ItemLedgerEntry."Lot No.";
        "Warranty Date" := ItemLedgerEntry."Warranty Date";
        "Expiration Date" := ItemLedgerEntry."Expiration Date";

        OnAfterCopyTrackingFromItemLedgEntry(Rec, ItemLedgerEntry);
    end;

    procedure CopyTrackingFromPostedWhseReceiptLine(PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
        "Serial No." := PostedWhseReceiptLine."Serial No.";
        "Lot No." := PostedWhseReceiptLine."Lot No.";

        OnAfterCopyTrackingFromPostedWhseReceiptine(Rec, PostedWhseReceiptLine);
    end;

    procedure CopyTrackingFromReservEntry(ReservationEntry: Record "Reservation Entry")
    begin
        "Serial No." := ReservationEntry."Serial No.";
        "Lot No." := ReservationEntry."Lot No.";
        "Warranty Date" := ReservationEntry."Warranty Date";
        "Expiration Date" := ReservationEntry."Expiration Date";

        OnAfterCopyTrackingFromReservEntry(Rec, ReservationEntry);
    end;

    procedure CopyTrackingFromPostedWhseRcptLine(PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
        "Serial No." := PostedWhseReceiptLine."Serial No.";
        "Lot No." := PostedWhseReceiptLine."Lot No.";

        OnAfterCopyTrackingFromPostedWhseRcptLine(Rec, PostedWhseReceiptLine);
    end;

    procedure CopyTrackingFromWhseActivityLine(WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        "Serial No." := WarehouseActivityLine."Serial No.";
        "Lot No." := WarehouseActivityLine."Lot No.";

        OnAfterCopyTrackingFromWhseActivityLine(Rec, WarehouseActivityLine);
    end;

    procedure CopyTrackingFromWhseEntry(WarehouseEntry: Record "Warehouse Entry")
    begin
        "Serial No." := WarehouseEntry."Serial No.";
        "Lot No." := WarehouseEntry."Lot No.";

        OnAfterCopyTrackingFromWhseEntry(Rec, WarehouseEntry);
    end;

    procedure CopyTrackingFromWhseItemTrackingLine(WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        "Serial No." := WhseItemTrackingLine."Serial No.";
        "Lot No." := WhseItemTrackingLine."Lot No.";

        OnAfterCopyTrackingFromWhseItemTrackingLine(Rec, WhseItemTrackingLine);
    end;

    procedure CopyTrackingFromRelation(WhseItemEntryRelation: Record "Whse. Item Entry Relation")
    begin
        "Serial No." := WhseItemEntryRelation."Serial No.";
        "Lot No." := WhseItemEntryRelation."Lot No.";

        OnAfterCopyTrackingFromRelation(Rec, WhseItemEntryRelation);
    end;

    procedure SetSource(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; SourceBatchName: Code[10]; SourceProdOrderLine: Integer)
    begin
        "Source Type" := SourceType;
        "Source Subtype" := SourceSubtype;
        "Source ID" := SourceID;
        "Source Ref. No." := SourceRefNo;
        "Source Batch Name" := SourceBatchName;
        "Source Prod. Order Line" := SourceProdOrderLine;
    end;

    procedure SetSourceFilter(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; SourceKey: Boolean)
    begin
        if SourceKey then
            SetCurrentKey(
              "Source ID", "Source Type", "Source Subtype", "Source Batch Name",
              "Source Prod. Order Line", "Source Ref. No.");
        SetRange("Source Type", SourceType);
        if SourceSubtype >= 0 then
            SetRange("Source Subtype", SourceSubtype);
        SetRange("Source ID", SourceID);
        if SourceRefNo >= 0 then
            SetRange("Source Ref. No.", SourceRefNo);

        OnAfterSetSourceFilter(Rec, SourceType, SourceSubtype, SourceID, SourceRefNo, SourceKey);
    end;

    procedure SetSourceFilter(SourceBatchName: Code[10]; SourceProdOrderLine: Integer)
    begin
        SetRange("Source Batch Name", SourceBatchName);
        if SourceProdOrderLine >= 0 then
            SetRange("Source Prod. Order Line", SourceProdOrderLine);
    end;

    procedure SetTrackingFilterFromBinContent(var BinContent: Record "Bin Content")
    begin
        SetFilter("Lot No.", BinContent.GetFilter("Lot No. Filter"));
        SetFilter("Serial No.", BinContent.GetFilter("Serial No. Filter"));

        OnAfterSetTrackingFilterFromBinContent(Rec, BinContent);
    end;

    procedure SetTrackingFilterFromItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        SetFilter("Lot No.", ItemLedgerEntry."Lot No.");
        SetFilter("Serial No.", ItemLedgerEntry."Serial No.");

        OnAfterSetTrackingFilterFromItemLedgerEntry(Rec, ItemLedgerEntry);
    end;

    procedure SetTrackingFilterFromPostedWhseReceiptLine(PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
        SetRange("Serial No.", PostedWhseReceiptLine."Serial No.");
        SetRange("Lot No.", PostedWhseReceiptLine."Lot No.");

        OnAfterSetTrackingFilterFromPostedWhseReceiptLine(Rec, PostedWhseReceiptLine);
    end;

    procedure SetTrackingFilterFromRelation(WhseItemEntryRelation: Record "Whse. Item Entry Relation")
    begin
        SetRange("Serial No.", WhseItemEntryRelation."Serial No.");
        SetRange("Lot No.", WhseItemEntryRelation."Lot No.");

        OnAfterSetTrackingFilterFromRelation(Rec, WhseItemEntryRelation);
    end;

    procedure SetTrackingFilterFromReservEntry(ReservationEntry: Record "Reservation Entry")
    begin
        SetRange("Serial No.", ReservationEntry."Serial No.");
        SetRange("Lot No.", ReservationEntry."Lot No.");

        OnAfterSetTrackingFilterFromReservEntry(Rec, ReservationEntry);
    end;

    procedure SetTrackingFilterFromSpec(WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        SetRange("Serial No.", WhseItemTrackingLine."Serial No.");
        SetRange("Lot No.", WhseItemTrackingLine."Lot No.");

        OnAfterSetTrackingFilterFromSpec(Rec, WhseItemTrackingLine);
    end;

    procedure SetTrackingFilterFromWhseActivityLine(WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        SetRange("Serial No.", WarehouseActivityLine."Serial No.");
        SetRange("Lot No.", WarehouseActivityLine."Lot No.");

        OnAfterSetTrackingFilterFromWhseActivityLine(Rec, WarehouseActivityLine);
    end;

    procedure SetTrackingFilterFromWhseItemTrackingLine(WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        SetRange("Serial No.", WhseItemTrackingLine."Serial No.");
        SetRange("Lot No.", WhseItemTrackingLine."Lot No.");

        OnAfterSetTrackingFilterFromWhseItemTrackingLine(Rec, WhseItemTrackingLine);
    end;

    procedure SetTrackingKey()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetTrackingKey(Rec, IsHandled);
        if not IsHandled then
            SetCurrentKey("Serial No.", "Lot No.", "Package No.");
    end;

    procedure HasSameTracking(WhseItemTrackingLine: Record "Whse. Item Tracking Line") IsSameTracking: Boolean
    begin
        IsSameTracking :=
            ("Lot No." = WhseItemTrackingLine."Lot No.") and ("Serial No." = WhseItemTrackingLine."Serial No.");

        OnAfterHasSameTracking(Rec, WhseItemTrackingLine, IsSameTracking);
    end;

    procedure HasSameNewTracking() IsSameTracking: Boolean
    begin
        IsSameTracking := ("New Lot No." = "Lot No.") and ("New Serial No." = "Serial No.");

        OnAfterHasSameNewTracking(Rec, IsSameTracking);
    end;

    procedure HasSameTrackingWithItemEntryRelation(WhseItemEntryRelation: Record "Whse. Item Entry Relation") IsSameTracking: Boolean
    begin
        IsSameTracking :=
            (WhseItemEntryRelation."Lot No." = "Lot No.") and (WhseItemEntryRelation."Serial No." = "Serial No.");

        OnAfterHasSameTrackingWithItemEntryRelation(Rec, WhseItemEntryRelation, IsSameTracking);
    end;

    procedure HasSameTrackingWithItemLedgerEntry(ItemLedgerEntry: Record "Item Ledger Entry") IsSameTracking: Boolean
    begin
        IsSameTracking :=
            (ItemLedgerEntry."Lot No." = "Lot No.") and (ItemLedgerEntry."Serial No." = "Serial No.") and (ItemLedgerEntry."Package No." = "Package No.");
    end;

    procedure TrackingExists() IsTrackingExist: Boolean
    begin
        IsTrackingExist := ("Lot No." <> '') or ("Serial No." <> '');
        OnAfterTrackingExists(Rec, IsTrackingExist);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckTrackingIfRequired(WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearTrackingFilter(var WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromEntrySummary(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; EntrySummary: Record "Entry Summary")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemLedgEntry(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromPostedWhseReceiptine(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromRelation(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WhseItemEntryRelation: Record "Whse. Item Entry Relation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromReservEntry(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromPostedWhseRcptLine(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; PostedWhseRcptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromWhseActivityLine(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WhseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromWhseEntry(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WhseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromWhseItemTrackingLine(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; FromWhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHasSameTracking(WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WhseItemTrackingLine2: Record "Whse. Item Tracking Line"; var IsSameTracking: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHasSameNewTracking(WhseItemTrackingLine: Record "Whse. Item Tracking Line"; var IsSameTracking: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHasSameTrackingWithItemEntryRelation(WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WhseItemEntryRelation: Record "Whse. Item Entry Relation"; var IsSameTracking: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitQtyToHandle(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; xWhseItemTrackingLine: Record "Whse. Item Tracking Line"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookUpTrackingSummary(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; TrackingType: Enum "Item Tracking Type"; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromBinContent(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; var BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemLedgerEntry(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemTrackingSetupIfNotBlank(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromPostedWhseReceiptLine(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromRelation(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WhseItemEntryRelation: Record "Whse. Item Entry Relation")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromReservEntry(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromSpec(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; FromWhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromWhseActivityLine(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WhseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromWhseItemTrackingLine(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; FromWhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTrackingExists(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; var IsTrackingExist: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSerialNoQty(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookUpTrackingSummary(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; TrackingType: Enum "Item Tracking Type"; MaxQuantity: Decimal; SignFactor: Integer; SearchForSupply: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitExpirationDate(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; xWhseItemTrackingLine: Record "Whse. Item Tracking Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetTrackingKey(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSourceFilter(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; SourceKey: Boolean)
    begin
    end;
}

