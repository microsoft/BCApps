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
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;
using Microsoft.Warehouse.Worksheet;

table 7332 "Whse. Internal Put-away Line"
{
    Caption = 'Whse. Internal Put-away Line';
    LookupPageID = "Whse. Internal Put-away Lines";
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

            trigger OnValidate()
            begin
                GetLocation("Location Code");
            end;
        }
        field(11; "Shelf No."; Code[10])
        {
            Caption = 'Shelf No.';
        }
        field(12; "From Bin Code"; Code[20])
        {
            Caption = 'From Bin Code';

            trigger OnLookup()
            begin
                SelectLookUp(FieldNo("From Bin Code"));
            end;

            trigger OnValidate()
            var
                BinContent: Record "Bin Content";
            begin
                TestReleased();
                if xRec."From Bin Code" <> "From Bin Code" then
                    if "From Bin Code" <> '' then begin
                        GetLocation("Location Code");
                        Location.TestField("Bin Mandatory");
                        if "From Bin Code" = Location."Adjustment Bin Code" then
                            FieldError(
                              "From Bin Code",
                              StrSubstNo(
                                Text000, Location.FieldCaption("Adjustment Bin Code"),
                                Location.TableCaption()));
                        if Location."Directed Put-away and Pick" then
                            CheckBlocking(BinContent);
                    end;
            end;
        }
        field(13; "From Zone Code"; Code[10])
        {
            Caption = 'From Zone Code';

            trigger OnLookup()
            begin
                SelectLookUp(FieldNo("From Zone Code"));
                Location.TestField("Directed Put-away and Pick");
            end;

            trigger OnValidate()
            begin
                TestReleased();
                if "From Zone Code" <> xRec."From Zone Code" then begin
                    GetLocation("Location Code");
                    Location.TestField("Directed Put-away and Pick");
                    "From Bin Code" := '';
                end;
            end;
        }
        field(14; "Item No."; Code[20])
        {
            Caption = 'Item No.';

            trigger OnLookup()
            begin
                SelectLookUp(FieldNo("Item No."));
            end;

            trigger OnValidate()
            begin
                TestReleased();
                TestField("Qty. Put Away", 0);
                if "Item No." <> xRec."Item No." then
                    "Variant Code" := '';

                SetItemFields();

                if WhseInternalPutAwayHeader.Get("No.") then begin
                    if "Location Code" = '' then
                        Validate("Location Code", WhseInternalPutAwayHeader."Location Code");
                    if "From Zone Code" = '' then
                        Validate("From Zone Code", WhseInternalPutAwayHeader."From Zone Code");
                    if "From Bin Code" = '' then
                        Validate("From Bin Code", WhseInternalPutAwayHeader."From Bin Code");
                end;
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
                TestField("Qty. Put Away", 0);
                CalcFields("Put-away Qty.");
                if Quantity < "Qty. Put Away" + "Put-away Qty." then
                    FieldError(Quantity, StrSubstNo(Text001, "Qty. Put Away" + "Put-away Qty."));

                "Qty. (Base)" :=
                    UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", Quantity, "Qty. per Unit of Measure");
                if CurrFieldNo = FieldNo(Quantity) then
                    CheckBinContentQty();

                Validate("Qty. Outstanding", (Quantity - "Qty. Put Away"));
                Status := CalcStatusPutAwayLine();
                if Status <> xRec.Status then begin
                    GetInternalPutAwayHeader("No.");
                    DocStatus := WhseInternalPutAwayHeader.GetDocumentStatus(0);
                    if DocStatus <> WhseInternalPutAwayHeader."Document Status" then begin
                        WhseInternalPutAwayHeader.Validate("Document Status", DocStatus);
                        WhseInternalPutAwayHeader.Modify();
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
            begin
                "Qty. Outstanding (Base)" :=
                    UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", "Qty. Outstanding", "Qty. per Unit of Measure");
            end;
        }
        field(20; "Qty. Outstanding (Base)"; Decimal)
        {
            Caption = 'Qty. Outstanding (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(23; "Qty. Put Away"; Decimal)
        {
            Caption = 'Qty. Put Away';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                "Qty. Put Away (Base)" :=
                    UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", "Qty. Put Away", "Qty. per Unit of Measure");
            end;
        }
        field(24; "Qty. Put Away (Base)"; Decimal)
        {
            Caption = 'Qty. Put Away (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(25; "Put-away Qty."; Decimal)
        {
            CalcFormula = sum("Warehouse Activity Line"."Qty. Outstanding" where("Activity Type" = const("Put-away"),
                                                                                  "Whse. Document Type" = const("Internal Put-away"),
                                                                                  "Whse. Document No." = field("No."),
                                                                                  "Whse. Document Line No." = field("Line No."),
                                                                                  "Unit of Measure Code" = field("Unit of Measure Code"),
                                                                                  "Action Type" = filter(" " | Take),
                                                                                  "Original Breakbulk" = const(false)));
            Caption = 'Put-away Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(26; "Put-away Qty. (Base)"; Decimal)
        {
            CalcFormula = sum("Warehouse Activity Line"."Qty. Outstanding (Base)" where("Activity Type" = const("Put-away"),
                                                                                         "Whse. Document Type" = const("Internal Put-away"),
                                                                                         "Whse. Document No." = field("No."),
                                                                                         "Whse. Document Line No." = field("Line No."),
                                                                                         "Action Type" = filter(" " | Take),
                                                                                         "Original Breakbulk" = const(false)));
            Caption = 'Put-away Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(27; Status; Option)
        {
            Caption = 'Status';
            Editable = false;
            OptionCaption = ' ,Partially Put Away,Completely Put Away';
            OptionMembers = " ","Partially Put Away","Completely Put Away";
        }
        field(29; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            Editable = false;

            trigger OnLookup()
            begin
                SelectLookUp(FieldNo("Unit of Measure Code"));
            end;

            trigger OnValidate()
            begin
                if "Item No." <> '' then begin
                    GetItemUnitOfMeasure();
                    "Qty. per Unit of Measure" := ItemUnitOfMeasure."Qty. per Unit of Measure";
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
            Editable = true;
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));

            trigger OnLookup()
            begin
                SelectLookUp(FieldNo("Variant Code"));
            end;

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
        key(Key2; "No.", "Item No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key3; "No.", "From Bin Code")
        {
            MaintainSQLIndex = false;
        }
        key(Key4; "No.", "Shelf No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key5; "No.", "Sorting Sequence No.")
        {
        }
        key(Key6; "No.", "Due Date")
        {
            MaintainSQLIndex = false;
        }
        key(Key7; "Item No.", "From Bin Code", "Location Code", "Unit of Measure Code", "Variant Code")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Qty. (Base)";
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

        if ("Qty. Put Away" > 0) and (Quantity > "Qty. Put Away") then
            if not HideValidationDialog then
                if not Confirm(
                     StrSubstNo(
                       Text004,
                       FieldCaption("Qty. Put Away"), "Qty. Put Away",
                       FieldCaption(Quantity), Quantity, TableCaption), false)
                then
                    Error(Text005);

        ItemTrackingMgt.DeleteWhseItemTrkgLines(
          Database::"Whse. Internal Put-away Line", 0, "No.", '', 0, "Line No.", "Location Code", true);

        DocStatus :=
          WhseInternalPutAwayHeader.GetDocumentStatus("Line No.");
        if DocStatus <> WhseInternalPutAwayHeader."Document Status" then begin
            WhseInternalPutAwayHeader.Validate("Document Status", DocStatus);
            WhseInternalPutAwayHeader.Modify();
        end;
    end;

    trigger OnInsert()
    begin
        TestField("Item No.");
        "Sorting Sequence No." := GetSortSeqNo();
    end;

    trigger OnModify()
    begin
        TestField("Item No.");
        xRec.TestField("Qty. Put Away", 0);
        "Sorting Sequence No." := GetSortSeqNo();
    end;

    trigger OnRename()
    begin
        Error(Text003, TableCaption);
    end;

    var
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
        Location: Record Location;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        UOMMgt: Codeunit "Unit of Measure Management";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'must not be the %1 of the %2';
        Text001: Label 'must be greater than %1';
        Text002: Label 'must not be greater than %1 units';
        Text003: Label 'You cannot rename a %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        LastLineNo: Integer;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text004: Label '%1 = %2 is less than the %3 = %4.\Do you really want to delete the %5?';
#pragma warning restore AA0470
        Text005: Label 'Cancelled.';
        Text006: Label 'Nothing to handle.';
#pragma warning restore AA0074

    protected var
        HideValidationDialog: Boolean;

    procedure SetUpNewLine(LastWhseInternalPutAwayLine: Record "Whse. Internal Put-away Line")
    var
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
    begin
        GetInternalPutAwayHeader("No.");
        WhseInternalPutAwayLine.SetRange("No.", WhseInternalPutAwayHeader."No.");
        if not WhseInternalPutAwayLine.IsEmpty() then
            LastLineNo := LastWhseInternalPutAwayLine."Line No."
        else
            LastLineNo := 0;
        "Line No." := GetNextLineNo();
        Validate("Location Code", WhseInternalPutAwayHeader."Location Code");
        "From Zone Code" := WhseInternalPutAwayHeader."From Zone Code";
        "From Bin Code" := WhseInternalPutAwayHeader."From Bin Code";
        "Due Date" := WhseInternalPutAwayHeader."Due Date";
    end;

    local procedure TestReleased()
    begin
        TestField("No.");
        GetInternalPutAwayHeader("No.");
        WhseInternalPutAwayHeader.TestField(Status, 0);
    end;

    local procedure SetItemFields()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetItemFields(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Item No." <> '' then begin
            GetItemUnitOfMeasure();
            Description := Item.Description;
            "Description 2" := Item."Description 2";
            "Shelf No." := Item."Shelf No.";
            Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        end else begin
            Description := '';
            "Description 2" := '';
            "Variant Code" := '';
            "Shelf No." := '';
            Validate("Unit of Measure Code", '');
        end;
    end;

    procedure CalcStatusPutAwayLine(): Integer
    begin
        if (Quantity <> 0) and (Quantity = "Qty. Put Away") then
            exit(Status::"Completely Put Away");
        if "Qty. Put Away" > 0 then
            exit(Status::"Partially Put Away");
        exit(Status::" ");
    end;

    protected procedure CheckBinContentQty()
    var
        BinContent: Record "Bin Content";
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        AvailQtyBase: Decimal;
    begin
        GetLocation("Location Code");

        if Location."Bin Mandatory" and
           ("Location Code" <> '') and ("From Bin Code" <> '') and
           ("Item No." <> '') and ("Unit of Measure Code" <> '')
        then begin
            if Location."Directed Put-away and Pick" then
                CheckBlocking(BinContent);
            AvailQtyBase := BinContent.CalcQtyAvailToTake(0);
            WhseInternalPutAwayLine.SetCurrentKey(
              "Item No.", "From Bin Code", "Location Code", "Unit of Measure Code", "Variant Code");
            WhseInternalPutAwayLine.SetRange("Item No.", "Item No.");
            WhseInternalPutAwayLine.SetRange("From Bin Code", "From Bin Code");
            WhseInternalPutAwayLine.SetRange("Location Code", "Location Code");
            WhseInternalPutAwayLine.SetRange("Unit of Measure Code", "Unit of Measure Code");
            WhseInternalPutAwayLine.SetRange("Variant Code", "Variant Code");
            WhseInternalPutAwayLine.SetFilter("Line No.", '<>%1', "Line No.");
            OnCheckBinContentQtyOnAfterWhseInternalPutAwayLineSetFilter(Rec, WhseInternalPutAwayLine);
            WhseInternalPutAwayLine.CalcSums("Qty. (Base)");
            if AvailQtyBase - WhseInternalPutAwayLine."Qty. (Base)" < "Qty. (Base)" then
                FieldError(
                  "Qty. (Base)",
                  StrSubstNo(
                    Text002, AvailQtyBase - WhseInternalPutAwayLine."Qty. (Base)"));
        end;
    end;

    local procedure CheckBlocking(var BinContent: Record "Bin Content")
    var
        Bin: Record Bin;
        BinType: Record "Bin Type";
    begin
        if BinContent.Get(
             "Location Code", "From Bin Code", "Item No.", "Variant Code", "Unit of Measure Code")
        then begin
            if BinContent."Bin Type Code" <> '' then
                if BinType.Get(Bin."Bin Type Code") then
                    BinType.TestField(Receive, false);
            if BinContent."Block Movement" in [
                                               BinContent."Block Movement"::Outbound, BinContent."Block Movement"::All]
            then
                BinContent.FieldError("Block Movement");

            "From Zone Code" := BinContent."Zone Code";
        end else begin
            Bin.Get("Location Code", "From Bin Code");
            if Bin."Bin Type Code" <> '' then
                if BinType.Get(Bin."Bin Type Code") then
                    BinType.TestField(Receive, false);

            if Bin."Block Movement" in [
                                        Bin."Block Movement"::Outbound, Bin."Block Movement"::All]
            then
                Bin.FieldError("Block Movement");
            "From Zone Code" := Bin."Zone Code";
        end;

        OnAfterCheckBlocking(Rec);
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    local procedure GetItemUnitOfMeasure()
    begin
        GetItem();
        Item.TestField("No.");
        if (Item."No." <> ItemUnitOfMeasure."Item No.") or
           ("Unit of Measure Code" <> ItemUnitOfMeasure.Code)
        then
            if not ItemUnitOfMeasure.Get(Item."No.", "Unit of Measure Code") then
                ItemUnitOfMeasure.Get(Item."No.", Item."Base Unit of Measure");
    end;

    local procedure GetItem()
    begin
        if Item."No." <> "Item No." then
            Item.Get("Item No.");
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure GetInternalPutAwayHeader(InternalPutAwayNo: Code[20])
    begin
        if InternalPutAwayNo <> '' then
            WhseInternalPutAwayHeader.Get(InternalPutAwayNo);
    end;

    local procedure LookUpBinContent()
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.FilterGroup(2);
        BinContent.SetRange("Location Code", "Location Code");
        BinContent.FilterGroup(0);
        BinContent."Location Code" := "Location Code";
        BinContent."Zone Code" := "From Zone Code";
        BinContent."Bin Code" := "From Bin Code";
        BinContent."Item No." := "Item No.";
        if "Variant Code" <> '' then begin
            TestField("Item No.");
            BinContent."Variant Code" := "Variant Code";
        end;
        if "Unit of Measure Code" <> '' then begin
            TestField("Item No.");
            BinContent."Unit of Measure Code" := "Unit of Measure Code";
        end;
        OnLookupBinContentOnBeforeRunPage(Rec, BinContent);
        if PAGE.RunModal(0, BinContent) = ACTION::LookupOK then begin
            if BinContent."Block Movement" in [
                                               BinContent."Block Movement"::Outbound, BinContent."Block Movement"::All]
            then
                BinContent.FieldError("Block Movement");
            Validate("Location Code", BinContent."Location Code");
            Validate(Quantity, 0);
            Validate("From Bin Code", BinContent."Bin Code");
            Validate("Item No.", BinContent."Item No.");
            Validate("Variant Code", BinContent."Variant Code");
            Validate("Unit of Measure Code", BinContent."Unit of Measure Code");
        end;

        OnAfterLookUpBinContent(Rec, BinContent);
    end;

    procedure CreatePutAwayDoc(var WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line")

    begin
        GetInternalPutAwayHeader("No.");
        WhseInternalPutAwayHeader.CheckPutawayRequired(WhseInternalPutAwayLine."Location Code");
        WhseInternalPutAwayHeader.TestField(
          Status, WhseInternalPutAwayHeader.Status::Released);
        WhseInternalPutAwayLine.SetFilter(Quantity, '>0');
        WhseInternalPutAwayLine.SetFilter(
          Status, '<>%1', WhseInternalPutAwayLine.Status::"Completely Put Away");
        if WhseInternalPutAwayLine.Find('-') then
            RunCreatePutAwayFromWhseSource()
        else
            if not HideValidationDialog then
                Message(Text006);
    end;

    local procedure RunCreatePutAwayFromWhseSource()
    var
        CreatePutAwayFromWhseSource: Report "Whse.-Source - Create Document";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunCreatePutAwayFromWhseSource(WhseInternalPutAwayHeader, HideValidationDialog, IsHandled);
        if IsHandled then
            exit;

        CreatePutAwayFromWhseSource.SetWhseInternalPutAway(WhseInternalPutAwayHeader);
        CreatePutAwayFromWhseSource.SetHideValidationDialog(HideValidationDialog);
        CreatePutAwayFromWhseSource.UseRequestPage(not HideValidationDialog);
        CreatePutAwayFromWhseSource.RunModal();
        CreatePutAwayFromWhseSource.GetResultMessage(1);
    end;

    local procedure SelectLookUp(CurrentFieldNo: Integer)
    var
        ItemVariant: Record "Item Variant";
    begin
        GetLocation("Location Code");
        if Location."Bin Mandatory" then
            LookUpBinContent()
        else begin
            if CurrentFieldNo = FieldNo("From Zone Code") then
                Location.TestField("Bin Mandatory");
            if CurrentFieldNo = FieldNo("From Bin Code") then
                Location.TestField("Bin Mandatory");
            if CurrentFieldNo = FieldNo("Item No.") then begin
                Item."No." := "Item No.";
                if PAGE.RunModal(0, Item) = ACTION::LookupOK then
                    Validate("Item No.", Item."No.");
            end;
            if CurrentFieldNo = FieldNo("Variant Code") then begin
                TestField("Item No.");
                ItemVariant.FilterGroup(2);
                ItemVariant.SetRange("Item No.", "Item No.");
                ItemVariant.FilterGroup(0);
                ItemVariant."Item No." := "Item No.";
                ItemVariant.Code := "Variant Code";
                if PAGE.RunModal(0, ItemVariant) = ACTION::LookupOK then
                    Validate("Variant Code", ItemVariant.Code);
            end;
            if CurrentFieldNo = FieldNo("Unit of Measure Code") then begin
                TestField("Item No.");
                ItemUnitOfMeasure.FilterGroup(2);
                ItemUnitOfMeasure.SetRange("Item No.", "Item No.");
                ItemUnitOfMeasure.FilterGroup(0);
                ItemUnitOfMeasure."Item No." := "Item No.";
                ItemUnitOfMeasure.Code := "Unit of Measure Code";
                if PAGE.RunModal(0, ItemUnitOfMeasure) = ACTION::LookupOK then
                    Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
            end;
        end;
    end;

    procedure OpenItemTrackingLines()
    var
        TempWhseWorksheetLine: Record "Whse. Worksheet Line" temporary;
        WhseItemTrackingLines: Page "Whse. Item Tracking Lines";
    begin
        OnBeforeOpenItemTrackingLines(Rec);

        TestField("Item No.");
        TestField("Qty. (Base)");
        TempWhseWorksheetLine.InitNewLineWithItem(
          "Warehouse Worksheet Document Type"::"Internal Put-away", "No.", "Line No.",
          "Location Code", "Item No.", "Variant Code",
          "Qty. (Base)", "Qty. (Base)" - "Qty. Put Away (Base)" - "Put-away Qty. (Base)", "Qty. per Unit of Measure");

        OnOpenItemTrackingLinesOnBeforeSetSource(Rec, TempWhseWorksheetLine);
        WhseItemTrackingLines.SetSource(TempWhseWorksheetLine, Database::"Whse. Internal Put-away Line");
        WhseItemTrackingLines.RunModal();
        Clear(WhseItemTrackingLines);
    end;

    local procedure GetNextLineNo(): Integer
    var
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        HigherLineNo: Integer;
        LowerLineNo: Integer;
    begin
        WhseInternalPutAwayLine.SetRange("No.", WhseInternalPutAwayHeader."No.");
        if WhseInternalPutAwayHeader."Sorting Method" <> WhseInternalPutAwayHeader."Sorting Method"::None then
            exit(GetLastLineNo() + 10000);

        WhseInternalPutAwayLine."No." := WhseInternalPutAwayHeader."No.";
        WhseInternalPutAwayLine."Line No." := LastLineNo;
        if WhseInternalPutAwayLine.Find('<') then
            LowerLineNo := WhseInternalPutAwayLine."Line No."
        else
            if WhseInternalPutAwayLine.Find('>') then
                exit(LastLineNo div 2)
            else
                exit(LastLineNo + 10000);

        WhseInternalPutAwayLine."No." := WhseInternalPutAwayHeader."No.";
        WhseInternalPutAwayLine."Line No." := LastLineNo;
        if WhseInternalPutAwayLine.Find('>') then
            HigherLineNo := LastLineNo
        else
            exit(LastLineNo + 10000);
        exit(LowerLineNo + (HigherLineNo - LowerLineNo) div 2);
    end;

    local procedure GetLastLineNo(): Integer
    var
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
    begin
        WhseInternalPutAwayLine.SetRange("No.", WhseInternalPutAwayHeader."No.");
        if WhseInternalPutAwayLine.FindLast() then
            exit(WhseInternalPutAwayLine."Line No.");
        exit(0);
    end;

    local procedure GetSortSeqNo(): Integer
    var
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        HigherSeqNo: Integer;
        LowerSeqNo: Integer;
        LastSeqNo: Integer;
    begin
        GetInternalPutAwayHeader("No.");

        WhseInternalPutAwayLine.SetRange("No.", "No.");
        case WhseInternalPutAwayHeader."Sorting Method" of
            WhseInternalPutAwayHeader."Sorting Method"::None:
                WhseInternalPutAwayLine.SetCurrentKey("No.", "Line No.");
            WhseInternalPutAwayHeader."Sorting Method"::Item:
                WhseInternalPutAwayLine.SetCurrentKey("No.", "Item No.");
            WhseInternalPutAwayHeader."Sorting Method"::"Shelf or Bin":
                begin
                    GetLocation("Location Code");
                    if Location."Bin Mandatory" then
                        WhseInternalPutAwayLine.SetCurrentKey("No.", "From Bin Code")
                    else
                        WhseInternalPutAwayLine.SetCurrentKey("No.", "Shelf No.");
                end;
            WhseInternalPutAwayHeader."Sorting Method"::"Due Date":
                WhseInternalPutAwayLine.SetCurrentKey("No.", "Due Date");
            else
                exit("Line No.");
        end;

        WhseInternalPutAwayLine := Rec;
        LastSeqNo := GetLastSeqNo(WhseInternalPutAwayLine);
        if WhseInternalPutAwayLine.Find('<') then
            LowerSeqNo := WhseInternalPutAwayLine."Sorting Sequence No."
        else
            if WhseInternalPutAwayLine.Find('>') then
                exit(WhseInternalPutAwayLine."Sorting Sequence No." div 2)
            else
                LowerSeqNo := 10000;

        WhseInternalPutAwayLine := Rec;
        if WhseInternalPutAwayLine.Find('>') then
            HigherSeqNo := WhseInternalPutAwayLine."Sorting Sequence No."
        else
            if WhseInternalPutAwayLine.Find('<') then
                exit(LastSeqNo + 10000)
            else
                HigherSeqNo := LastSeqNo;
        exit(LowerSeqNo + (HigherSeqNo - LowerSeqNo) div 2);
    end;

    local procedure GetLastSeqNo(WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line"): Integer
    begin
        WhseInternalPutAwayLine.SetRecFilter();
        WhseInternalPutAwayLine.SetRange("Line No.");
        WhseInternalPutAwayLine.SetCurrentKey("No.", "Sorting Sequence No.");
        if WhseInternalPutAwayLine.FindLast() then
            exit(WhseInternalPutAwayLine."Sorting Sequence No.");
        exit(0);
    end;

    procedure SetItemTrackingLines(WhseEntry: Record "Warehouse Entry"; QtyToEmpty: Decimal)
    var
        TempWhseWorksheetLine: Record "Whse. Worksheet Line" temporary;
        WhseItemTrackingLines: Page "Whse. Item Tracking Lines";
    begin
        TestField("Item No.");
        TestField("Qty. (Base)");
        TempWhseWorksheetLine.InitNewLineWithItem(
          "Warehouse Worksheet Document Type"::"Internal Put-away", "No.", "Line No.",
          "Location Code", "Item No.", "Variant Code",
          "Qty. (Base)", "Qty. (Base)" - "Qty. Put Away (Base)" - "Put-away Qty. (Base)", "Qty. per Unit of Measure");

        Clear(WhseItemTrackingLines);
        OnSetItemTrackingLinesOnBeforeSetSource(Rec, TempWhseWorksheetLine);
        WhseItemTrackingLines.SetSource(TempWhseWorksheetLine, Database::"Whse. Internal Put-away Line");
        WhseItemTrackingLines.InsertItemTrackingLine(TempWhseWorksheetLine, WhseEntry, QtyToEmpty);
    end;

    procedure CheckCurrentLineQty()
    var
        BinContent: Record "Bin Content";
        AvailQtyBase: Decimal;
    begin
        GetLocation("Location Code");

        if Location."Bin Mandatory" and
           ("Location Code" <> '') and ("From Bin Code" <> '') and
           ("Item No." <> '') and ("Unit of Measure Code" <> '')
        then begin
            if Location."Directed Put-away and Pick" then
                CheckBlocking(BinContent);
            AvailQtyBase := BinContent.CalcQtyAvailToTake(0);
            if AvailQtyBase < "Qty. (Base)" then
                FieldError("Qty. (Base)", StrSubstNo(Text002, AvailQtyBase));
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenItemTrackingLines(var WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupBinContentOnBeforeRunPage(var WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line"; var BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckBinContentQtyOnAfterWhseInternalPutAwayLineSetFilter(var WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line"; var FilteredWhseInternalPutawayLine: Record "Whse. Internal Put-away Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenItemTrackingLinesOnBeforeSetSource(var WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line"; var WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetItemTrackingLinesOnBeforeSetSource(var WhseInternalPutawayLine: Record "Whse. Internal Put-away Line"; var TempWhseWorksheetLine: Record "Whse. Worksheet Line" temporary);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckBlocking(var WhseInternalPutawayLine: Record "Whse. Internal Put-away Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookUpBinContent(var WhseInternalPutawayLine: Record "Whse. Internal Put-away Line"; BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetItemFields(var WhseInternalPutawayLine: Record "Whse. Internal Put-away Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunCreatePutAwayFromWhseSource(var WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header"; HideValidationDialog: Boolean; var IsHandled: Boolean)
    begin
    end;
}

