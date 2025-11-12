// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.InternalDocument;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;
using Microsoft.Warehouse.Worksheet;

table 7347 "Internal Movement Line"
{
    Caption = 'Internal Movement Line';
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
                if "Location Code" <> '' then
                    InternalMovementHeader.CheckLocationSettings("Location Code");
            end;
        }
        field(11; "Shelf No."; Code[10])
        {
            Caption = 'Shelf No.';
        }
        field(12; "From Bin Code"; Code[20])
        {
            Caption = 'From Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));

            trigger OnLookup()
            begin
                SelectLookUp(FieldNo("From Bin Code"));
                CheckBin("Location Code", "From Bin Code", false);
            end;

            trigger OnValidate()
            begin
                if xRec."From Bin Code" <> "From Bin Code" then
                    if "From Bin Code" <> '' then begin
                        GetLocation("Location Code");
                        Location.TestField("Bin Mandatory");
                        CheckBin("Location Code", "From Bin Code", false);
                        Validate(Quantity, 0);
                    end;
            end;
        }
        field(13; "To Bin Code"; Code[20])
        {
            Caption = 'To Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));

            trigger OnLookup()
            var
                Bin: Record Bin;
            begin
                GetLocation("Location Code");
                if Location."Bin Mandatory" then begin
                    Bin.FilterGroup(2);
                    Bin.SetRange("Location Code", Location.Code);
                    Bin.FilterGroup(0);
                    if PAGE.RunModal(0, Bin) = ACTION::LookupOK then begin
                        "To Bin Code" := Bin.Code;
                        CheckBin("Location Code", "To Bin Code", true);
                    end;
                end;
            end;

            trigger OnValidate()
            begin
                CheckBin("Location Code", "To Bin Code", true);
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
                if "Item No." <> xRec."Item No." then
                    "Variant Code" := '';

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
                OnValidateItemNoOnAfterSetItemFields(Rec, Item, ItemUnitOfMeasure);

                if InternalMovementHeader.Get("No.") then begin
                    if "Location Code" = '' then
                        Validate("Location Code", InternalMovementHeader."Location Code");
                    if "To Bin Code" = '' then
                        Validate("To Bin Code", InternalMovementHeader."To Bin Code");
                end;
            end;
        }
        field(15; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                "Qty. (Base)" :=
                    UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", Quantity, "Qty. per Unit of Measure");

                if CurrFieldNo = FieldNo(Quantity) then
                    CheckBinContentQty();

                if not xRec.IsEmpty() then
                    if not CheckQtyItemTrackingLines() then
                        Error(ItemTrackingErr, "Item No.", TableCaption);
            end;
        }
        field(16; "Qty. (Base)"; Decimal)
        {
            Caption = 'Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(29; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));

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
                OnValidateVariantCodeOnAfterSetItemVariantFields(Rec, ItemVariant);
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
            IncludedFields = "Qty. (Base)";
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        ItemTrackingMgt.DeleteWhseItemTrkgLines(
          Database::"Internal Movement Line", 0, "No.", '', 0, "Line No.", "Location Code", true);
    end;

    trigger OnInsert()
    begin
        TestField("Item No.");
        "Sorting Sequence No." := GetSortSeqNo();
    end;

    trigger OnModify()
    begin
        TestField("Item No.");
        "Sorting Sequence No." := GetSortSeqNo();
    end;

    trigger OnRename()
    begin
        Error(Text002, TableCaption);
    end;

    var
        InternalMovementHeader: Record "Internal Movement Header";
        Location: Record Location;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        UOMMgt: Codeunit "Unit of Measure Management";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'must not be greater than %1 units';
        Text002: Label 'You cannot rename a %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        LastLineNo: Integer;
#pragma warning disable AA0470
        ItemTrackingErr: Label 'Item tracking numbers defined for item %1 in the %2 are higher than the item quantity.\\Adjust the item tracking numbers and then increase the item quantity, if relevant.', Comment = 'Item tracking numbers should not be higher than the item quantity.';
#pragma warning restore AA0470

    procedure SetUpNewLine(LastInternalMovementLine: Record "Internal Movement Line")
    var
        InternalMovementLine: Record "Internal Movement Line";
    begin
        GetInternalMovementHeader("No.");
        InternalMovementLine.SetRange("No.", InternalMovementHeader."No.");
        if not InternalMovementLine.IsEmpty() then
            LastLineNo := LastInternalMovementLine."Line No."
        else
            LastLineNo := 0;
        "Line No." := GetNextLineNo();
        Validate("Location Code", InternalMovementHeader."Location Code");
        "To Bin Code" := InternalMovementHeader."To Bin Code";
        "Due Date" := InternalMovementHeader."Due Date";
    end;

    protected procedure CheckBinContentQty()
    var
        BinContent: Record "Bin Content";
        InternalMovementLine: Record "Internal Movement Line";
        AvailQtyBase: Decimal;
    begin
        GetLocation("Location Code");

        if Location."Bin Mandatory" and
           ("Location Code" <> '') and ("From Bin Code" <> '') and
           ("Item No." <> '') and ("Unit of Measure Code" <> '')
        then begin
            BinContent."Location Code" := "Location Code";
            BinContent."Bin Code" := "From Bin Code";
            BinContent."Item No." := "Item No.";
            BinContent."Variant Code" := "Variant Code";
            BinContent."Unit of Measure Code" := "Unit of Measure Code";
            OnCheckBinContentQtyOnAfterInitBinContent(Rec, BinContent);

            AvailQtyBase := BinContent.CalcQtyAvailToTake(0);
            InternalMovementLine.SetCurrentKey(
              "Item No.", "From Bin Code", "Location Code", "Unit of Measure Code", "Variant Code");
            InternalMovementLine.SetRange("Item No.", "Item No.");
            InternalMovementLine.SetRange("From Bin Code", "From Bin Code");
            InternalMovementLine.SetRange("Location Code", "Location Code");
            InternalMovementLine.SetRange("Unit of Measure Code", "Unit of Measure Code");
            InternalMovementLine.SetRange("Variant Code", "Variant Code");
            InternalMovementLine.SetFilter("Line No.", '<>%1', "Line No.");
            OnCheckBinContentQtyOnAfterInternalMovementLineSetFilters(Rec, InternalMovementLine);
            InternalMovementLine.CalcSums("Qty. (Base)");
            if AvailQtyBase - InternalMovementLine."Qty. (Base)" < "Qty. (Base)" then
                FieldError(
                  "Qty. (Base)",
                  StrSubstNo(
                    Text001, AvailQtyBase - InternalMovementLine."Qty. (Base)"));
        end;
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

    local procedure GetInternalMovementHeader(InternalMovementNo: Code[20])
    begin
        if InternalMovementNo <> '' then
            InternalMovementHeader.Get(InternalMovementNo);
    end;

    local procedure LookUpBinContent()
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.FilterGroup(2);
        BinContent.SetRange("Location Code", "Location Code");
        BinContent.FilterGroup(0);
        if "Item No." <> '' then
            BinContent.SetRange("Item No.", "Item No.");
        if "Variant Code" <> '' then begin
            TestField("Item No.");
            BinContent.SetRange("Variant Code", "Variant Code");
        end;
        if "Unit of Measure Code" <> '' then
            TestField("Item No.");
        OnLookUpBinContentOnAfterBinContentSetFilters(Rec, BinContent);
        if PAGE.RunModal(0, BinContent) = ACTION::LookupOK then begin
            if BinContent."Block Movement" in [BinContent."Block Movement"::Outbound, BinContent."Block Movement"::All]
            then
                BinContent.FieldError("Block Movement");
            Validate("Location Code");
            Validate(Quantity, 0);
            Validate("From Bin Code", BinContent."Bin Code");
            Validate("Item No.", BinContent."Item No.");
            Validate("Variant Code", BinContent."Variant Code");
            Validate("Unit of Measure Code", BinContent."Unit of Measure Code");
        end;
    end;

    local procedure SelectLookUp(CurrentFieldNo: Integer)
    var
        ItemVariant: Record "Item Variant";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSelectLookUp(Rec, CurrentFieldNo, IsHandled);
        if IsHandled then
            exit;

        GetLocation("Location Code");
        if Location."Bin Mandatory" then
            LookUpBinContent()
        else begin
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
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseItemTrackingLinesForm: Page "Whse. Item Tracking Lines";
    begin
        TestField("Item No.");
        TestField("Qty. (Base)");
        WhseWorksheetLine.InitNewLineWithItem(
          "Warehouse Worksheet Document Type"::"Internal Movement", "No.", "Line No.",
          "Location Code", "Item No.", "Variant Code", "Qty. (Base)", "Qty. (Base)", "Qty. per Unit of Measure");

        WhseItemTrackingLinesForm.SetSource(WhseWorksheetLine, Database::"Internal Movement Line");
        WhseItemTrackingLinesForm.RunModal();
    end;

    local procedure CheckQtyItemTrackingLines() Result: Boolean
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        TotalWhseItemTrackingLine: Record "Whse. Item Tracking Line";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        SourceQuantityArray: array[2] of Decimal;
        UndefinedQtyArray: array[2] of Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckQtyItemTrackingLines(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if ItemTrackingMgt.GetWhseItemTrkgSetup("Item No.") then begin
            WhseWorksheetLine.InitNewLineWithItem(
              "Warehouse Worksheet Document Type"::"Internal Movement", "No.", "Line No.",
              "Location Code", "Item No.", "Variant Code", "Qty. (Base)", "Qty. (Base)", "Qty. per Unit of Measure");
            exit(
              ItemTrackingMgt.UpdateQuantities(
                WhseWorksheetLine, TotalWhseItemTrackingLine, SourceQuantityArray, UndefinedQtyArray, Database::"Internal Movement Line"));
        end;
        exit(true);
    end;

    procedure CheckBin(LocationCode: Code[10]; BinCode: Code[20]; Inbound: Boolean)
    var
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBin(Rec, LocationCode, BinCode, Inbound, IsHandled);
        if IsHandled then
            exit;

        GetLocation(LocationCode);
        if not Location."Bin Mandatory" then
            exit;

        if not Bin.Get(LocationCode, BinCode) then
            exit;

        Bin.CalcFields("Adjustment Bin");
        Bin.TestField("Adjustment Bin", false);

        if Inbound then begin
            if BinContent.Get(LocationCode, BinCode, "Item No.", "Variant Code", "Unit of Measure Code") then begin
                if BinContent."Block Movement" in [BinContent."Block Movement"::Inbound, BinContent."Block Movement"::All] then
                    BinContent.FieldError("Block Movement");
            end else
                if Bin."Block Movement" in [Bin."Block Movement"::Inbound, Bin."Block Movement"::All] then
                    Bin.FieldError("Block Movement");
        end else
            if BinContent.Get(LocationCode, BinCode, "Item No.", "Variant Code", "Unit of Measure Code") then begin
                if BinContent."Block Movement" in [BinContent."Block Movement"::Outbound, BinContent."Block Movement"::All] then
                    BinContent.FieldError("Block Movement");
            end else
                if Bin."Block Movement" in [Bin."Block Movement"::Outbound, Bin."Block Movement"::All] then
                    Bin.FieldError("Block Movement");
    end;

    local procedure GetNextLineNo(): Integer
    var
        InternalMovementLine: Record "Internal Movement Line";
        HigherLineNo: Integer;
        LowerLineNo: Integer;
    begin
        InternalMovementLine.SetRange("No.", InternalMovementHeader."No.");
        if InternalMovementHeader."Sorting Method" <> InternalMovementHeader."Sorting Method"::None then
            exit(GetLastLineNo() + 10000);

        InternalMovementLine."No." := InternalMovementHeader."No.";
        InternalMovementLine."Line No." := LastLineNo;
        if InternalMovementLine.Find('<') then
            LowerLineNo := InternalMovementLine."Line No."
        else begin
            if InternalMovementLine.Find('>') then
                exit(LastLineNo div 2);

            exit(LastLineNo + 10000);
        end;

        InternalMovementLine."No." := InternalMovementHeader."No.";
        InternalMovementLine."Line No." := LastLineNo;
        if InternalMovementLine.Find('>') then
            HigherLineNo := LastLineNo
        else
            exit(LastLineNo + 10000);

        exit(LowerLineNo + (HigherLineNo - LowerLineNo) div 2);
    end;

    local procedure GetLastLineNo(): Integer
    var
        InternalMovementLine: Record "Internal Movement Line";
    begin
        InternalMovementLine.SetRange("No.", InternalMovementHeader."No.");
        if InternalMovementLine.FindLast() then
            exit(InternalMovementLine."Line No.");

        exit(0);
    end;

    local procedure GetSortSeqNo(): Integer
    var
        InternalMovementLine: Record "Internal Movement Line";
        HigherSeqNo: Integer;
        LowerSeqNo: Integer;
        LastSeqNo: Integer;
    begin
        GetInternalMovementHeader("No.");

        InternalMovementLine.SetRange("No.", "No.");
        case InternalMovementHeader."Sorting Method" of
            InternalMovementHeader."Sorting Method"::None:
                InternalMovementLine.SetCurrentKey("No.", "Line No.");
            InternalMovementHeader."Sorting Method"::Item:
                InternalMovementLine.SetCurrentKey("No.", "Item No.");
            InternalMovementHeader."Sorting Method"::"Shelf or Bin":
                begin
                    GetLocation("Location Code");
                    if Location."Bin Mandatory" then
                        InternalMovementLine.SetCurrentKey("No.", "From Bin Code")
                    else
                        InternalMovementLine.SetCurrentKey("No.", "Shelf No.");
                end;
            InternalMovementHeader."Sorting Method"::"Due Date":
                InternalMovementLine.SetCurrentKey("No.", "Due Date");
            else
                exit("Line No.");
        end;

        InternalMovementLine := Rec;
        LastSeqNo := GetLastSeqNo(InternalMovementLine);
        if InternalMovementLine.Find('<') then
            LowerSeqNo := InternalMovementLine."Sorting Sequence No."
        else
            if InternalMovementLine.Find('>') then
                exit(InternalMovementLine."Sorting Sequence No." div 2);

        LowerSeqNo := 10000;

        InternalMovementLine := Rec;
        if InternalMovementLine.Find('>') then
            HigherSeqNo := InternalMovementLine."Sorting Sequence No."
        else
            if InternalMovementLine.Find('<') then
                exit(LastSeqNo + 10000);

        HigherSeqNo := LastSeqNo;
        exit(LowerSeqNo + (HigherSeqNo - LowerSeqNo) div 2);
    end;

    local procedure GetLastSeqNo(InternalMovementLine: Record "Internal Movement Line"): Integer
    begin
        InternalMovementLine.SetRecFilter();
        InternalMovementLine.SetRange("Line No.");
        InternalMovementLine.SetCurrentKey("No.", "Sorting Sequence No.");
        if InternalMovementLine.FindLast() then
            exit(InternalMovementLine."Sorting Sequence No.");

        exit(0);
    end;

    procedure SetItemTrackingLines(WhseEntry: Record "Warehouse Entry"; QtyToEmpty: Decimal)
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        WhseItemTrackingLinesLines: Page "Whse. Item Tracking Lines";
    begin
        TestField("Item No.");
        TestField("Qty. (Base)");
        WhseWorksheetLine.InitNewLineWithItem(
          "Warehouse Worksheet Document Type"::"Internal Movement", "No.", "Line No.",
          "Location Code", "Item No.", "Variant Code", "Qty. (Base)", "Qty. (Base)", "Qty. per Unit of Measure");

        Clear(WhseItemTrackingLinesLines);
        OnSetItemTrackingLinesOnBeforeSetSource(Rec, WhseWorksheetLine);
        WhseItemTrackingLinesLines.SetSource(WhseWorksheetLine, Database::"Internal Movement Line");
        WhseItemTrackingLinesLines.InsertItemTrackingLine(WhseWorksheetLine, WhseEntry, QtyToEmpty);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckBinContentQtyOnAfterInitBinContent(var InternalMovementLine: Record "Internal Movement Line"; var BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBin(InternalMovementLine: Record "Internal Movement Line"; LocationCode: Code[10]; BinCode: Code[20]; Inbound: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckQtyItemTrackingLines(var Rec: Record "Internal Movement Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectLookUp(var InternalMovementLine: Record "Internal Movement Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckBinContentQtyOnAfterInternalMovementLineSetFilters(var InternalMovementLine: Record "Internal Movement Line"; var FilteredInternalMovementLine: Record "Internal Movement Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookUpBinContentOnAfterBinContentSetFilters(var InternalMovementLine: Record "Internal Movement Line"; var BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetItemTrackingLinesOnBeforeSetSource(var InternalMovementLine: Record "Internal Movement Line"; var WhseWorksheetLine: Record "Whse. Worksheet Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnAfterSetItemFields(var InternalMovementLine: Record "Internal Movement Line"; Item: Record Item; ItemUnitOfMeasure: Record "Item Unit of Measure")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVariantCodeOnAfterSetItemVariantFields(var InternalMovementLine: Record "Internal Movement Line"; ItemVariant: Record "Item Variant")
    begin
    end;
}

