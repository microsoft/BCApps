// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.InternalDocument;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;
using Microsoft.Warehouse.Worksheet;

table 7334 "Whse. Internal Pick Line"
{
    Caption = 'Whse. Internal Pick Line';
    LookupPageID = "Whse. Internal Pick Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
            Editable = false;
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        field(10; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            Editable = false;
            TableRelation = Location;
        }
        field(11; "Shelf No."; Code[10])
        {
            Caption = 'Shelf No.';
        }
        field(12; "To Bin Code"; Code[20])
        {
            Caption = 'To Bin Code';
            TableRelation = if ("To Zone Code" = filter('')) Bin.Code where("Location Code" = field("Location Code"))
            else
            if ("To Zone Code" = filter(<> '')) Bin.Code where("Location Code" = field("Location Code"),
                                                                                  "Zone Code" = field("To Zone Code"));

            trigger OnValidate()
            begin
                TestReleased();
                if xRec."To Bin Code" <> "To Bin Code" then
                    if "To Bin Code" <> '' then begin
                        GetLocation("Location Code");
                        Location.TestField("Bin Mandatory");
                        if Location."Directed Put-away and Pick" then begin
                            if "To Bin Code" = Location."Adjustment Bin Code" then
                                FieldError(
                                  "To Bin Code",
                                  StrSubstNo(
                                    Text004, Location.FieldCaption("Adjustment Bin Code"),
                                    Location.TableCaption()));

                            CheckBin(true);
                        end;
                    end;
            end;
        }
        field(13; "To Zone Code"; Code[10])
        {
            Caption = 'To Zone Code';
            TableRelation = Zone.Code where("Location Code" = field("Location Code"));

            trigger OnValidate()
            begin
                TestReleased();
                if xRec."To Zone Code" <> "To Zone Code" then begin
                    if "To Zone Code" <> '' then begin
                        GetLocation("Location Code");
                        Location.TestField("Directed Put-away and Pick");
                    end;
                    "To Bin Code" := '';
                end;
            end;
        }
        field(14; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;

            trigger OnValidate()
            begin
                if "Item No." <> xRec."Item No." then
                    "Variant Code" := '';

                GetInternalPickHeader("No.");
                "Location Code" := WhseInternalPickHeader."Location Code";
                if WhseInternalPickHeader."To Zone Code" <> '' then
                    "To Zone Code" := WhseInternalPickHeader."To Zone Code";
                if WhseInternalPickHeader."To Bin Code" <> '' then
                    "To Bin Code" := WhseInternalPickHeader."To Bin Code";

                InitItemFields();
            end;
        }
        field(15; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            var
                DocStatus: Option;
            begin
                TestReleased();
                CalcFields("Pick Qty.");
                if Quantity < "Qty. Picked" + "Pick Qty." then
                    FieldError(Quantity, StrSubstNo(Text001, "Qty. Picked" + "Pick Qty."));

                Validate("Qty. Outstanding", (Quantity - "Qty. Picked"));
                "Qty. (Base)" :=
                    UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", Quantity, "Qty. per Unit of Measure");

                CheckBin(true);

                Status := CalcStatusPickLine();
                if Status <> xRec.Status then begin
                    GetInternalPickHeader("No.");
                    DocStatus := WhseInternalPickHeader.GetDocumentStatus(0);
                    if DocStatus <> WhseInternalPickHeader."Document Status" then begin
                        WhseInternalPickHeader.Validate("Document Status", DocStatus);
                        WhseInternalPickHeader.Modify();
                    end;
                end;
            end;
        }
        field(16; "Qty. (Base)"; Decimal)
        {
            Caption = 'Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(19; "Qty. Outstanding"; Decimal)
        {
            Caption = 'Qty. Outstanding';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            var
                WMSMgt: Codeunit "WMS Management";
            begin
                "Qty. Outstanding (Base)" :=
                    UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", "Qty. Outstanding", "Qty. per Unit of Measure");

                WMSMgt.CalcCubageAndWeight(
                  "Item No.", "Unit of Measure Code", "Qty. Outstanding", Cubage, Weight);
            end;
        }
        field(20; "Qty. Outstanding (Base)"; Decimal)
        {
            Caption = 'Qty. Outstanding (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(23; "Qty. Picked"; Decimal)
        {
            Caption = 'Qty. Picked';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = Normal;

            trigger OnValidate()
            begin
                "Qty. Picked (Base)" :=
                    UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", "Qty. Picked", "Qty. per Unit of Measure");
            end;
        }
        field(24; "Qty. Picked (Base)"; Decimal)
        {
            Caption = 'Qty. Picked (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(27; "Pick Qty."; Decimal)
        {
            CalcFormula = sum("Warehouse Activity Line"."Qty. Outstanding" where("Activity Type" = const(Pick),
                                                                                  "Whse. Document Type" = const("Internal Pick"),
                                                                                  "Whse. Document No." = field("No."),
                                                                                  "Whse. Document Line No." = field("Line No."),
                                                                                  "Action Type" = filter(" " | Place),
                                                                                  "Unit of Measure Code" = field("Unit of Measure Code"),
                                                                                  "Original Breakbulk" = const(false),
                                                                                  "Breakbulk No." = const(0)));
            Caption = 'Pick Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(28; "Pick Qty. (Base)"; Decimal)
        {
            CalcFormula = sum("Warehouse Activity Line"."Qty. Outstanding (Base)" where("Activity Type" = const(Pick),
                                                                                         "Whse. Document Type" = const("Internal Pick"),
                                                                                         "Whse. Document No." = field("No."),
                                                                                         "Whse. Document Line No." = field("Line No."),
                                                                                         "Action Type" = filter(" " | Place),
                                                                                         "Original Breakbulk" = const(false),
                                                                                         "Breakbulk No." = const(0)));
            Caption = 'Pick Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(29; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            NotBlank = true;
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            begin
                if "Item No." <> '' then begin
                    GetItemUnitOfMeasure();
                    "Qty. per Unit of Measure" := ItemUnitofMeasure."Qty. per Unit of Measure";
                end else
                    "Qty. per Unit of Measure" := 1;

                Validate(Quantity);
                Validate("Qty. Outstanding");
            end;
        }
        field(30; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(31; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            var
                ItemVariant: Record "Item Variant";
            begin
                if Rec."Variant Code" = '' then
                    Validate("Item No.")
                else begin
                    ItemVariant.Get("Item No.", "Variant Code");
                    Description := ItemVariant.Description;
                end;
            end;
        }
        field(32; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(33; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(34; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = ' ,Partially Picked,Completely Picked';
            OptionMembers = " ","Partially Picked","Completely Picked";
        }
        field(35; "Sorting Sequence No."; Integer)
        {
            Caption = 'Sorting Sequence No.';
            Editable = false;
        }
        field(36; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(37; Cubage; Decimal)
        {
            Caption = 'Cubage';
            DecimalPlaces = 0 : 5;
        }
        field(38; Weight; Decimal)
        {
            Caption = 'Weight';
            DecimalPlaces = 0 : 5;
        }
    }

    keys
    {
        key(Key1; "No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "No.", "Sorting Sequence No.")
        {
        }
        key(Key3; "No.", "Item No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key4; "No.", "Shelf No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key5; "No.", "To Bin Code")
        {
            MaintainSQLIndex = false;
        }
        key(Key6; "No.", "Due Date")
        {
            MaintainSQLIndex = false;
        }
        key(Key7; "To Bin Code", "Location Code")
        {
            IncludedFields = "Qty. Outstanding", Cubage, Weight;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        DocStatus: Option;
    begin
        TestReleased();

        if ("Qty. Picked" > 0) and (Quantity > "Qty. Picked") then
            if not HideValidationDialog then
                if not Confirm(
                     StrSubstNo(
                       Text002,
                       FieldCaption("Qty. Picked"), "Qty. Picked",
                       FieldCaption(Quantity), Quantity, TableCaption), false)
                then
                    Error(Text003);

        ItemTrackingMgt.DeleteWhseItemTrkgLines(
          Database::"Whse. Internal Pick Line", 0, "No.", '', 0, "Line No.", "Location Code", true);

        DocStatus :=
          WhseInternalPickHeader.GetDocumentStatus("Line No.");
        if DocStatus <> WhseInternalPickHeader."Document Status" then begin
            WhseInternalPickHeader.Validate("Document Status", DocStatus);
            WhseInternalPickHeader.Modify();
        end;
    end;

    trigger OnInsert()
    begin
        "Sorting Sequence No." := GetSortSeqNo();
    end;

    trigger OnModify()
    begin
        "Sorting Sequence No." := GetSortSeqNo();
    end;

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
        Location: Record Location;
        Item: Record Item;
        ItemUnitofMeasure: Record "Item Unit of Measure";
        WhseInternalPickHeader: Record "Whse. Internal Pick Header";
        UOMMgt: Codeunit "Unit of Measure Management";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot rename a %1.';
        Text001: Label 'must not be less than %1 units';
        Text002: Label '%1 = %2 is less than the %3 = %4.\Do you really want to delete the %5?';
#pragma warning restore AA0470
        Text003: Label 'Cancelled.';
#pragma warning disable AA0470
        Text004: Label 'must not be the %1 of the %2';
#pragma warning restore AA0470
#pragma warning restore AA0074
        LastLineNo: Integer;
#pragma warning disable AA0074
        Text005: Label 'Nothing to handle.';
#pragma warning restore AA0074

    protected var
        HideValidationDialog: Boolean;

    procedure SetUpNewLine(LastWhseInternalPickLine: Record "Whse. Internal Pick Line")
    var
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
    begin
        if GetInternalPickHeader("No.") then begin
            WhseInternalPickLine.SetRange("No.", WhseInternalPickHeader."No.");
            if not WhseInternalPickLine.IsEmpty() then
                LastLineNo := LastWhseInternalPickLine."Line No."
            else
                LastLineNo := 0;
            "Line No." := GetNextLineNo();
            "To Zone Code" := WhseInternalPickHeader."To Zone Code";
            "To Bin Code" := WhseInternalPickHeader."To Bin Code";
            "Due Date" := WhseInternalPickHeader."Due Date";
        end;
        "Location Code" := WhseInternalPickHeader."Location Code";
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure TestReleased()
    begin
        TestField("No.");
        GetInternalPickHeader("No.");
        WhseInternalPickHeader.TestField(Status, WhseInternalPickHeader.Status::Open);
    end;

    procedure CalcStatusPickLine(): Integer
    begin
        if (Quantity <> 0) and (Quantity = "Qty. Picked") then
            exit(Status::"Completely Picked");
        if "Qty. Picked" > 0 then
            exit(Status::"Partially Picked");
        exit(Status::" ");
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    local procedure GetItem()
    begin
        if Item."No." <> "Item No." then
            Item.Get("Item No.");
    end;

    local procedure GetItemUnitOfMeasure()
    begin
        GetItem();
        Item.TestField("No.");
        if (Item."No." <> ItemUnitofMeasure."Item No.") or
           ("Unit of Measure Code" <> ItemUnitofMeasure.Code)
        then
            if not ItemUnitofMeasure.Get(Item."No.", "Unit of Measure Code") then
                ItemUnitofMeasure.Get(Item."No.", Item."Base Unit of Measure");
    end;

    local procedure GetInternalPickHeader(InternalPickNo: Code[20]): Boolean
    begin
        if not WhseInternalPickHeader.Get(InternalPickNo) then
            exit(false);
        exit(true);
    end;

    local procedure InitItemFields()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitItemFields(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Item No." <> '' then begin
            GetItemUnitOfMeasure();
            Description := Item.Description;
            "Description 2" := Item."Description 2";
            "Shelf No." := Item."Shelf No.";
            Validate("Unit of Measure Code", ItemUnitofMeasure.Code);
        end else begin
            Description := '';
            "Description 2" := '';
            "Variant Code" := '';
            "Shelf No." := '';
            Validate("Unit of Measure Code", '');
        end;
    end;

    procedure CreatePickDoc(var WhseInternalPickLine: Record "Whse. Internal Pick Line"; WhseInternalPickHeader2: Record "Whse. Internal Pick Header")
    begin
        WhseInternalPickHeader2.CheckPickRequired(WhseInternalPickHeader2."Location Code");
        WhseInternalPickHeader2.TestField(Status, WhseInternalPickHeader2.Status::Released);
        WhseInternalPickLine.SetFilter(Quantity, '>0');
        WhseInternalPickLine.SetFilter(
          Status, '<>%1', WhseInternalPickLine.Status::"Completely Picked");
        if WhseInternalPickLine.Find('-') then
            RunCreatePickFromWhseSource(WhseInternalPickLine, WhseInternalPickHeader2)
        else
            if not HideValidationDialog then
                Message(Text005);
    end;

    local procedure RunCreatePickFromWhseSource(var WhseInternalPickLine: Record "Whse. Internal Pick Line"; WhseInternalPickHeader2: Record "Whse. Internal Pick Header")
    var
        CreatePickFromWhseSource: Report "Whse.-Source - Create Document";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunCreatePickFromWhseSource(WhseInternalPickLine, WhseInternalPickHeader2, HideValidationDialog, IsHandled);
        if IsHandled then
            exit;

        CreatePickFromWhseSource.SetWhseInternalPickLine(
            WhseInternalPickLine, WhseInternalPickHeader2."Assigned User ID");
        CreatePickFromWhseSource.SetHideValidationDialog(HideValidationDialog);
        CreatePickFromWhseSource.UseRequestPage(not HideValidationDialog);
        CreatePickFromWhseSource.RunModal();
        CreatePickFromWhseSource.GetResultMessage(2);
    end;

    procedure OpenItemTrackingLines()
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseItemTrackingLines: Page "Whse. Item Tracking Lines";
    begin
        TestField("Item No.");
        TestField("Qty. (Base)");
        WhseWorksheetLine.Init();
        WhseWorksheetLine."Whse. Document Type" :=
          WhseWorksheetLine."Whse. Document Type"::"Internal Pick";
        WhseWorksheetLine."Whse. Document No." := "No.";
        WhseWorksheetLine."Whse. Document Line No." := "Line No.";
        WhseWorksheetLine."Location Code" := "Location Code";
        WhseWorksheetLine."Item No." := "Item No.";
        WhseWorksheetLine."Qty. (Base)" := "Qty. (Base)";
        WhseWorksheetLine."Qty. to Handle (Base)" :=
          "Qty. (Base)" - "Qty. Picked (Base)" - "Pick Qty. (Base)";

        OnOpenItemTrackingLinesOnBeforeSetSource(Rec, WhseWorksheetLine);
        WhseItemTrackingLines.SetSource(WhseWorksheetLine, Database::"Whse. Internal Pick Line");
        WhseItemTrackingLines.RunModal();
        Clear(WhseItemTrackingLines);
    end;

    procedure CheckBin(CalcDeduction: Boolean)
    var
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
    begin
        if "To Bin Code" <> '' then begin
            GetLocation("Location Code");
            if Location."Bin Capacity Policy" = Location."Bin Capacity Policy"::"Never Check Capacity" then begin
                if Location."Check Whse. Class" then
                    if BinContent.Get("Location Code", "To Bin Code", "Item No.", "Variant Code", "Unit of Measure Code") then
                        BinContent.CheckWhseClass(false)
                    else begin
                        Bin.Get("Location Code", "To Bin Code");
                        Bin.CheckWhseClass("Item No.", false);
                    end;
                exit;
            end;

            if (Location."Bin Capacity Policy" in
                [Location."Bin Capacity Policy"::"Allow More Than Max. Capacity",
                 Location."Bin Capacity Policy"::"Prohibit More Than Max. Cap."]) and
               CalcDeduction
            then begin
                WhseInternalPickLine.SetCurrentKey("To Bin Code", "Location Code");
                WhseInternalPickLine.SetRange("To Bin Code", "To Bin Code");
                WhseInternalPickLine.SetRange("Location Code", "Location Code");
                WhseInternalPickLine.SetRange("No.", "No.");
                WhseInternalPickLine.SetRange("Line No.", "Line No.");
                WhseInternalPickLine.CalcSums("Qty. Outstanding", Cubage, Weight);
            end;
            if BinContent.Get(
                 "Location Code", "To Bin Code", "Item No.", "Variant Code", "Unit of Measure Code")
            then begin
                if Location."Directed Put-away and Pick" then
                    BinContent.TestField("Bin Type Code");
                BinContent.CheckIncreaseBinContent(
                  "Qty. Outstanding", WhseInternalPickLine.Quantity,
                  WhseInternalPickLine.Cubage, WhseInternalPickLine.Weight,
                  Cubage, Weight, false, false);
                "To Zone Code" := BinContent."Zone Code";
            end else begin
                Bin.Get("Location Code", "To Bin Code");
                CheckIncreaseBin(Bin, WhseInternalPickLine);
                if Location."Directed Put-away and Pick" then
                    Bin.TestField("Bin Type Code");
                "To Zone Code" := Bin."Zone Code";
            end;
        end;
    end;

    local procedure CheckIncreaseBin(Bin: Record Bin; WhseInternalPickLine: Record "Whse. Internal Pick Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckIncreaseBin(Rec, Bin, WhseInternalPickLine, IsHandled);
        if IsHandled then
            exit;

        Bin.CheckIncreaseBin(
          "To Bin Code", "Item No.", "Qty. Outstanding",
          WhseInternalPickLine.Cubage, WhseInternalPickLine.Weight,
          Cubage, Weight, false, false);
    end;

    local procedure GetNextLineNo(): Integer
    var
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
        HigherLineNo: Integer;
        LowerLineNo: Integer;
    begin
        WhseInternalPickLine.SetRange("No.", WhseInternalPickHeader."No.");
        if WhseInternalPickHeader."Sorting Method" <> WhseInternalPickHeader."Sorting Method"::"None" then
            exit(GetLastLineNo() + 10000);

        WhseInternalPickLine."No." := WhseInternalPickHeader."No.";
        WhseInternalPickLine."Line No." := LastLineNo;
        if WhseInternalPickLine.Find('<') then
            LowerLineNo := WhseInternalPickLine."Line No."
        else
            if WhseInternalPickLine.Find('>') then
                exit(LastLineNo div 2)
            else
                exit(LastLineNo + 10000);

        WhseInternalPickLine."No." := WhseInternalPickHeader."No.";
        WhseInternalPickLine."Line No." := LastLineNo;
        if WhseInternalPickLine.Find('>') then
            HigherLineNo := LastLineNo
        else
            exit(LastLineNo + 10000);
        exit(LowerLineNo + (HigherLineNo - LowerLineNo) div 2);
    end;

    local procedure GetLastLineNo(): Integer
    var
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
    begin
        WhseInternalPickLine.SetRange("No.", WhseInternalPickHeader."No.");
        if WhseInternalPickLine.FindLast() then
            exit(WhseInternalPickLine."Line No.");
        exit(0);
    end;

    local procedure GetSortSeqNo(): Integer
    var
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
        HigherSeqNo: Integer;
        LowerSeqNo: Integer;
        LastSeqNo: Integer;
    begin
        GetInternalPickHeader("No.");

        WhseInternalPickLine.SetRange("No.", "No.");
        case WhseInternalPickHeader."Sorting Method" of
            WhseInternalPickHeader."Sorting Method"::"None":
                WhseInternalPickLine.SetCurrentKey("No.", "Line No.");
            WhseInternalPickHeader."Sorting Method"::Item:
                WhseInternalPickLine.SetCurrentKey("No.", "Item No.");
            WhseInternalPickHeader."Sorting Method"::"Shelf or Bin":
                begin
                    GetLocation("Location Code");
                    if Location."Bin Mandatory" then
                        WhseInternalPickLine.SetCurrentKey("No.", "To Bin Code")
                    else
                        WhseInternalPickLine.SetCurrentKey("No.", "Shelf No.");
                end;
            WhseInternalPickHeader."Sorting Method"::"Due Date":
                WhseInternalPickLine.SetCurrentKey("No.", "Due Date");
            else
                exit("Line No.")
        end;

        WhseInternalPickLine := Rec;
        LastSeqNo := GetLastSeqNo(WhseInternalPickLine);
        if WhseInternalPickLine.Find('<') then
            LowerSeqNo := WhseInternalPickLine."Sorting Sequence No."
        else
            if WhseInternalPickLine.Find('>') then
                exit(WhseInternalPickLine."Sorting Sequence No." div 2)
            else
                LowerSeqNo := 10000;

        WhseInternalPickLine := Rec;
        if WhseInternalPickLine.Find('>') then
            HigherSeqNo := WhseInternalPickLine."Sorting Sequence No."
        else
            if WhseInternalPickLine.Find('<') then
                exit(LastSeqNo + 10000)
            else
                HigherSeqNo := LastSeqNo;
        exit(LowerSeqNo + (HigherSeqNo - LowerSeqNo) div 2);
    end;

    local procedure GetLastSeqNo(WhseInternalPickLine: Record "Whse. Internal Pick Line"): Integer
    begin
        WhseInternalPickLine.SetRecFilter();
        WhseInternalPickLine.SetRange("Line No.");
        WhseInternalPickLine.SetCurrentKey("No.", "Sorting Sequence No.");
        if WhseInternalPickLine.FindLast() then
            exit(WhseInternalPickLine."Sorting Sequence No.");
        exit(0);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIncreaseBin(var RecWhseInternalPickLine: Record "Whse. Internal Pick Line"; var Bin: Record Bin; WhseInternalPickLine: Record "Whse. Internal Pick Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitItemFields(var RecWhseInternalPickLine: Record "Whse. Internal Pick Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunCreatePickFromWhseSource(var WhseInternalPickLine: Record "Whse. Internal Pick Line"; var WhseInternalPickHeader2: Record "Whse. Internal Pick Header"; HideValidationDialog: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenItemTrackingLinesOnBeforeSetSource(var WhseInternalPickLine: Record "Whse. Internal Pick Line"; var WhseWorksheetLine: Record "Whse. Worksheet Line");
    begin
    end;
}

