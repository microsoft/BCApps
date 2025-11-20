// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Structure;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Setup;
using System.Telemetry;

table 7354 Bin
{
    Caption = 'Bin';
    DataCaptionFields = "Location Code", "Zone Code", "Code";
    LookupPageID = "Bin List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            Editable = false;
            NotBlank = true;
            TableRelation = Location;
        }
        field(2; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
            Editable = false;
            TableRelation = Zone.Code where("Location Code" = field("Location Code"));

            trigger OnValidate()
            begin
                if "Zone Code" <> xRec."Zone Code" then begin
                    CheckEmptyBin(Text007);
                    if (Code = '') or (not IsBinPropertiesAlreadySet(Rec)) then
                        SetUpNewLine();
                    BinContent.Reset();
                    BinContent.SetRange("Location Code", "Location Code");
                    BinContent.SetRange("Bin Code", Code);
                    BinContent.ModifyAll("Zone Code", "Zone Code");
                end;
            end;
        }
        field(5; "Adjustment Bin"; Boolean)
        {
            CalcFormula = exist(Location where(Code = field("Location Code"),
                                                "Adjustment Bin Code" = field(Code)));
            Caption = 'Adjustment Bin';
            Editable = false;
            FieldClass = FlowField;
        }
        field(10; "Bin Type Code"; Code[10])
        {
            Caption = 'Bin Type Code';
            TableRelation = "Bin Type";

            trigger OnValidate()
            begin
                if "Bin Type Code" <> xRec."Bin Type Code" then begin
                    CheckEmptyBin(Text007);
                    BinContent.Reset();
                    BinContent.SetRange("Location Code", "Location Code");
                    BinContent.SetRange("Bin Code", Code);
                    BinContent.ModifyAll("Bin Type Code", "Bin Type Code");
                end;
            end;
        }
        field(11; "Warehouse Class Code"; Code[10])
        {
            Caption = 'Warehouse Class Code';
            TableRelation = "Warehouse Class";

            trigger OnValidate()
            begin
                if "Warehouse Class Code" <> xRec."Warehouse Class Code" then begin
                    CheckEmptyBin(Text007);
                    BinContent.Reset();
                    BinContent.SetRange("Location Code", "Location Code");
                    BinContent.SetRange("Bin Code", Code);
                    BinContent.ModifyAll("Warehouse Class Code", "Warehouse Class Code");
                end;
            end;
        }
        field(12; "Block Movement"; Option)
        {
            Caption = 'Block Movement';
            OptionCaption = ' ,Inbound,Outbound,All';
            OptionMembers = " ",Inbound,Outbound,All;

            trigger OnValidate()
            begin
                if "Block Movement" <> xRec."Block Movement" then begin
                    BinContent.Reset();
                    BinContent.SetRange("Location Code", "Location Code");
                    BinContent.SetRange("Bin Code", Code);
                    BinContent.ModifyAll("Block Movement", "Block Movement");
                end;
            end;
        }
        field(20; "Special Equipment Code"; Code[10])
        {
            Caption = 'Special Equipment Code';
            TableRelation = "Special Equipment";
        }
        field(21; "Bin Ranking"; Integer)
        {
            Caption = 'Bin Ranking';

            trigger OnValidate()
            var
                WhseActivLine: Record "Warehouse Activity Line";
            begin
                if "Bin Ranking" <> xRec."Bin Ranking" then begin
                    BinContent.Reset();
                    BinContent.SetRange("Location Code", "Location Code");
                    BinContent.SetRange("Bin Code", Code);
                    BinContent.ModifyAll("Bin Ranking", "Bin Ranking");

                    WhseActivLine.SetCurrentKey("Bin Code", "Location Code");
                    WhseActivLine.SetRange("Bin Code", Code);
                    WhseActivLine.SetRange("Location Code", "Location Code");
                    WhseActivLine.ModifyAll("Bin Ranking", "Bin Ranking");
                end;
            end;
        }
        field(22; "Maximum Cubage"; Decimal)
        {
            BlankZero = true;
            Caption = 'Maximum Cubage';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                CheckMaxQtyBinContent(false);
            end;
        }
        field(23; "Maximum Weight"; Decimal)
        {
            BlankZero = true;
            Caption = 'Maximum Weight';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                CheckMaxQtyBinContent(true);
            end;
        }
        field(30; Empty; Boolean)
        {
            Caption = 'Empty';
            Editable = false;
            InitValue = true;
        }
        field(32; "Item Filter"; Code[20])
        {
            Caption = 'Item Filter';
            FieldClass = FlowFilter;
            TableRelation = Item;
        }
        field(33; "Variant Filter"; Code[10])
        {
            Caption = 'Variant Filter';
            FieldClass = FlowFilter;
            TableRelation = "Stockkeeping Unit"."Variant Code" where("Location Code" = field("Location Code"),
                                                                      "Item No." = field("Item Filter"));
        }
        field(34; Default; Boolean)
        {
            CalcFormula = exist("Bin Content" where("Location Code" = field("Location Code"),
                                                     "Bin Code" = field(Code),
                                                     "Item No." = field("Item Filter"),
                                                     "Variant Code" = field("Variant Filter"),
                                                     Default = const(true)));
            Caption = 'Default';
            Editable = false;
            FieldClass = FlowField;
        }
        field(40; "Cross-Dock Bin"; Boolean)
        {
            Caption = 'Cross-Dock Bin';

            trigger OnValidate()
            begin
                if "Cross-Dock Bin" <> xRec."Cross-Dock Bin" then begin
                    BinContent.Reset();
                    BinContent.SetRange("Location Code", "Location Code");
                    BinContent.SetRange("Bin Code", Code);
                    BinContent.ModifyAll("Cross-Dock Bin", "Cross-Dock Bin");
                end;
            end;
        }
        field(41; Dedicated; Boolean)
        {
            Caption = 'Dedicated';

            trigger OnValidate()
            begin
                if Dedicated <> xRec.Dedicated then begin
                    CheckEmptyBin(Text007);
                    BinContent.Reset();
                    BinContent.SetRange("Location Code", "Location Code");
                    BinContent.SetRange("Bin Code", Code);
                    BinContent.ModifyAll(Dedicated, Dedicated);
                end;
            end;
        }
    }

    keys
    {
        key(Key1; "Location Code", "Code")
        {
            Clustered = true;
        }
        key(Key2; "Bin Type Code")
        {
        }
        key(Key3; "Location Code", "Warehouse Class Code", "Bin Ranking")
        {
        }
        key(Key4; "Location Code", "Zone Code", "Code")
        {
        }
        key(Key5; "Code")
        {
        }
        key(Key6; "Bin Ranking")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description, "Zone Code", "Bin Type Code", Empty, Default)
        {
        }
    }

    trigger OnDelete()
    var
        Location: Record Location;
        ItemJnlLine: Record "Item Journal Line";
    begin
        CheckEmptyBin(Text008);

        Location.Get("Location Code");
        if Location."Adjustment Bin Code" = Code then begin
            ItemJnlLine.SetCurrentKey("Entry Type", "Item No.", "Variant Code", "Location Code");
            ItemJnlLine.SetFilter("Entry Type", '%1|%2|%3|%4',
              ItemJnlLine."Entry Type"::"Negative Adjmt.", ItemJnlLine."Entry Type"::Sale,
              ItemJnlLine."Entry Type"::"Positive Adjmt.", ItemJnlLine."Entry Type"::Purchase);
            ItemJnlLine.SetRange("Location Code", "Location Code");
            if ItemJnlLine.FindFirst() then
                if not Confirm(
                     Text002, false, StrSubstNo(ItemJnlLine.TableCaption(), TableCaption))
                then
                    Error(Text003);
        end;

        BinContent.Reset();
        BinContent.SetRange("Location Code", "Location Code");
        BinContent.SetRange("Bin Code", Code);
        BinContent.DeleteAll();
    end;

    trigger OnInsert()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnInsert(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField("Location Code");
        TestField(Code);
        GetLocation("Location Code");
        if Location."Directed Put-away and Pick" then begin
            TestField("Zone Code");
            TestField("Bin Type Code");
        end else
            TestField("Bin Type Code", '');
    end;

    trigger OnModify()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnModify(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        GetLocation("Location Code");
        if Location."Directed Put-away and Pick" then begin
            TestField("Zone Code");
            TestField("Bin Type Code");
        end else
            TestField("Bin Type Code", '');
    end;

    var
        Location: Record Location;
        Zone: Record Zone;
        BinContent: Record "Bin Content";
        Item: Record Item;
        WMSMgt: Codeunit "WMS Management";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot %1 the %2 with %3 = %4, %5 = %6, because the %2 contains items.';
        Text001: Label 'You cannot %1 the %2 with %3 = %4, %5 = %6, because one or more %7 exists for this %2.';
        Text002: Label 'One or more %1 exists for this bin. Do you still want to delete this %2?';
#pragma warning restore AA0470
        Text003: Label 'Cancelled.';
#pragma warning disable AA0470
        Text005: Label 'The total cubage %1 of the %2 in the bin contents exceeds the entered %3 %4.\Do you still want to enter this %3?';
        Text006: Label 'The total weight %1 of the %2 in the bin contents exceeds the entered %3 %4.\Do you still want to enter this %3?';
#pragma warning restore AA0470
        Text007: Label 'modify';
        Text008: Label 'delete';
#pragma warning restore AA0074

    procedure SetUpNewLine()
    begin
        GetLocation("Location Code");
        if "Zone Code" <> '' then
            if GetZone("Location Code", "Zone Code") then begin
                "Bin Type Code" := Zone."Bin Type Code";
                "Warehouse Class Code" := Zone."Warehouse Class Code";
                "Special Equipment Code" := Zone."Special Equipment Code";
                "Bin Ranking" := Zone."Zone Ranking";
                "Cross-Dock Bin" := Zone."Cross-Dock Bin Zone";
            end;

        OnAfterSetUpNewLine(Rec);
    end;

    local procedure GetZone(LocationCode: Code[10]; ZoneCode: Code[10]): Boolean
    begin
        if (LocationCode = '') or (ZoneCode = '') then
            exit(false);
        if (Zone."Location Code" <> LocationCode) or
           (Zone.Code <> ZoneCode)
        then
            if not Zone.Get("Location Code", "Zone Code") then
                exit(false);

        exit(true);
    end;

    procedure CalcCubageAndWeight(var Cubage: Decimal; var Weight: Decimal; CalledbyPosting: Boolean)
    var
        PostedCubage: Decimal;
        PostedWeight: Decimal;
        WhseActivityWeight: Decimal;
        WhseActivityCubage: Decimal;
        JournalWeight: Decimal;
        JournalCubage: Decimal;
        WhseRcptWeight: Decimal;
        WhseRcptCubage: Decimal;
        WhseShptWeight: Decimal;
        WhseShptCubage: Decimal;
        WhseIntPickWeight: Decimal;
        WhseIntPickCubage: Decimal;
    begin
        if ("Maximum Cubage" <> 0) or ("Maximum Weight" <> 0) then begin
            CalcPostedCubageAndWeight(PostedCubage, PostedWeight);
            if not CalledbyPosting then begin
                CalcPutAwayOnWhseActivity(WhseActivityWeight, WhseActivityCubage);
                CalcPutAwayOnWhseJnl(JournalWeight, JournalCubage);
                CalcPutAwayOnWhseRcpt(WhseRcptWeight, WhseRcptCubage);
                CalcPutAwayOnWhseShpt(WhseShptWeight, WhseShptCubage);
                CalcPutAwayOnWhseIntPick(WhseIntPickWeight, WhseIntPickCubage);
            end;
            if "Maximum Cubage" <> 0 then
                Cubage :=
                  "Maximum Cubage" -
                  (PostedCubage + WhseActivityCubage + JournalCubage +
                   WhseRcptCubage + WhseShptCubage + WhseIntPickCubage);

            if "Maximum Weight" <> 0 then
                Weight :=
                  "Maximum Weight" -
                  (PostedWeight + WhseActivityWeight + JournalWeight +
                   WhseRcptWeight + WhseShptWeight + WhseIntPickWeight);
        end;

        OnAfterCalcCubageAndWeight(Rec, CalledbyPosting, Cubage, Weight);
    end;

    local procedure CalcPostedCubageAndWeight(var PostedCubage: Decimal; var PostedWeight: Decimal)
    var
        WhseEntry: Record "Warehouse Entry";
    begin
        WhseEntry.ReadIsolation(IsolationLevel::ReadUnCommitted);
        WhseEntry.SetRange("Bin Code", Code);
        WhseEntry.SetRange("Location Code", "Location Code");
        WhseEntry.CalcSums(Cubage, Weight);
        PostedCubage := WhseEntry.Cubage;
        PostedWeight := WhseEntry.Weight;
    end;

    local procedure CalcPutAwayOnWhseActivity(var WhseActivWeight: Decimal; var WhseActivCubage: Decimal)
    var
        WhseActivLine: Record "Warehouse Activity Line";
    begin
        WhseActivLine.SetCurrentKey("Bin Code", "Location Code", "Action Type");
        WhseActivLine.SetRange("Bin Code", Code);
        WhseActivLine.SetRange("Location Code", "Location Code");
        WhseActivLine.SetRange("Action Type", WhseActivLine."Action Type"::Place);
        WhseActivLine.CalcSums(Cubage, Weight);
        WhseActivCubage := WhseActivLine.Cubage;
        WhseActivWeight := WhseActivLine.Weight;

        WhseActivLine.SetRange("Action Type", WhseActivLine."Action Type"::Take);
        WhseActivLine.SetFilter("Breakbulk No.", '<>0');
        WhseActivLine.CalcSums(Cubage, Weight);
        WhseActivCubage := WhseActivCubage - WhseActivLine.Cubage;
        WhseActivWeight := WhseActivWeight - WhseActivLine.Weight;
    end;

    local procedure CalcPutAwayOnWhseJnl(var JournalWeight: Decimal; var JournalCubage: Decimal)
    var
        WhseJnlLine: Record "Warehouse Journal Line";
    begin
        WhseJnlLine.SetCurrentKey("To Bin Code", "Location Code");
        WhseJnlLine.SetRange("To Bin Code", Code);
        WhseJnlLine.SetRange("Location Code", "Location Code");
        WhseJnlLine.CalcSums(Cubage, Weight);
        JournalCubage := WhseJnlLine.Cubage;
        JournalWeight := WhseJnlLine.Weight;
    end;

    local procedure CalcPutAwayOnWhseRcpt(var WhseRcptWeight: Decimal; var WhseRcptCubage: Decimal)
    var
        WhseRcptLine: Record "Warehouse Receipt Line";
    begin
        WhseRcptLine.SetCurrentKey("Bin Code", "Location Code");
        WhseRcptLine.SetRange("Bin Code", Code);
        WhseRcptLine.SetRange("Location Code", "Location Code");
        WhseRcptLine.CalcSums(Cubage, Weight);
        WhseRcptCubage := WhseRcptLine.Cubage;
        WhseRcptWeight := WhseRcptLine.Weight;
    end;

    local procedure CalcPutAwayOnWhseShpt(var WhseShptWeight: Decimal; var WhseShptCubage: Decimal)
    var
        WhseShptLine: Record "Warehouse Shipment Line";
    begin
        WhseShptLine.SetCurrentKey("Bin Code", "Location Code");
        WhseShptLine.SetRange("Bin Code", Code);
        WhseShptLine.SetRange("Location Code", "Location Code");
        WhseShptLine.CalcSums(Cubage, Weight);
        WhseShptCubage := WhseShptLine.Cubage;
        WhseShptWeight := WhseShptLine.Weight;
    end;

    local procedure CalcPutAwayOnWhseIntPick(var WhseIntPickWeight: Decimal; var WhseIntPickCubage: Decimal)
    var
        WhseIntPickLine: Record "Whse. Internal Pick Line";
    begin
        WhseIntPickLine.SetCurrentKey("To Bin Code", "Location Code");
        WhseIntPickLine.SetRange("To Bin Code", Code);
        WhseIntPickLine.SetRange("Location Code", "Location Code");
        WhseIntPickLine.CalcSums(Cubage, Weight);
        WhseIntPickCubage := WhseIntPickLine.Cubage;
        WhseIntPickWeight := WhseIntPickLine.Weight;
    end;

    local procedure GetItem(ItemNo: Code[20])
    begin
        if ItemNo <> Item."No." then
            Item.Get(ItemNo);
    end;

    local procedure CheckMaxQtyBinContent(CheckWeight: Boolean)
    var
        TotalCubage: Decimal;
        TotalWeight: Decimal;
        Cubage: Decimal;
        Weight: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckMaxQtyBinContent(Rec, CheckWeight, IsHandled);
        if IsHandled then
            exit;

        if ("Maximum Cubage" <> 0) or ("Maximum Weight" <> 0) then begin
            BinContent.Reset();
            BinContent.SetRange("Location Code", "Location Code");
            BinContent.SetRange("Bin Code", Code);
            if BinContent.Find('-') then
                repeat
                    WMSMgt.CalcCubageAndWeight(
                      BinContent."Item No.", BinContent."Unit of Measure Code",
                      BinContent."Max. Qty.", Cubage, Weight);
                    TotalCubage := TotalCubage + Cubage;
                    TotalWeight := TotalWeight + Weight;
                until BinContent.Next() = 0;

            if (not CheckWeight) and ("Maximum Cubage" > 0) and ("Maximum Cubage" - TotalCubage < 0) then
                if not Confirm(Text005, false,
                     TotalCubage, BinContent.FieldCaption("Max. Qty."),
                     FieldCaption("Maximum Cubage"), "Maximum Cubage")
                then
                    Error(Text003);
            if CheckWeight and ("Maximum Weight" > 0) and ("Maximum Weight" - TotalWeight < 0) then
                if not Confirm(Text006, false,
                     TotalWeight, BinContent.FieldCaption("Max. Qty."),
                     FieldCaption("Maximum Weight"), "Maximum Weight")
                then
                    Error(Text003);
        end;
    end;

    procedure CheckWhseClass(ItemNo: Code[20]; IgnoreError: Boolean): Boolean
    var
        IsHandled: Boolean;
        ResultValue: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWhseClass(Rec, ItemNo, ResultValue, IsHandled, IgnoreError);
        if IsHandled then
            exit(ResultValue);

        GetItem(ItemNo);
        if IgnoreError then
            exit("Warehouse Class Code" = Item."Warehouse Class Code");
        TestField("Warehouse Class Code", Item."Warehouse Class Code");
        exit(true);
    end;

    local procedure CheckEmptyBin(ErrorText: Text[250])
    var
        WarehouseEntry: Record "Warehouse Entry";
        WarehouseJnl: Record "Warehouse Journal Line";
        WhseActivLine: Record "Warehouse Activity Line";
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhseShptLine: Record "Warehouse Shipment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckEmptyBin(Rec, ErrorText, IsHandled);
        if IsHandled then
            exit;

        WarehouseEntry.SetCurrentKey("Bin Code", "Location Code");
        WarehouseEntry.SetRange("Bin Code", Code);
        WarehouseEntry.SetRange("Location Code", "Location Code");
        WarehouseEntry.CalcSums("Qty. (Base)");
        if WarehouseEntry."Qty. (Base)" <> 0 then
            Error(
              Text000,
              ErrorText, TableCaption(), FieldCaption("Location Code"),
              "Location Code", FieldCaption(Code), Code);

        WhseActivLine.SetRange("Bin Code", Code);
        WhseActivLine.SetRange("Location Code", "Location Code");
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Movement);
        if not WhseActivLine.IsEmpty() then
            Error(
              Text001,
              ErrorText, TableCaption(), FieldCaption("Location Code"), "Location Code",
              FieldCaption(Code), Code, WhseActivLine.TableCaption());

        WarehouseJnl.SetRange("Location Code", "Location Code");
        WarehouseJnl.SetRange("From Bin Code", Code);
        if not WarehouseJnl.IsEmpty() then
            Error(
              Text001,
              ErrorText, TableCaption(), FieldCaption("Location Code"), "Location Code",
              FieldCaption(Code), Code, WarehouseJnl.TableCaption());

        WarehouseJnl.Reset();
        WarehouseJnl.SetRange("To Bin Code", Code);
        WarehouseJnl.SetRange("Location Code", "Location Code");
        if not WarehouseJnl.IsEmpty() then
            Error(
              Text001,
              ErrorText, TableCaption(), FieldCaption("Location Code"), "Location Code",
              FieldCaption(Code), Code, WarehouseJnl.TableCaption());

        WhseRcptLine.SetRange("Bin Code", Code);
        WhseRcptLine.SetRange("Location Code", "Location Code");
        if not WhseRcptLine.IsEmpty() then
            Error(
              Text001,
              ErrorText, TableCaption(), FieldCaption("Location Code"), "Location Code",
              FieldCaption(Code), Code, WhseRcptLine.TableCaption());

        WhseShptLine.SetRange("Bin Code", Code);
        WhseShptLine.SetRange("Location Code", "Location Code");
        if not WhseShptLine.IsEmpty() then
            Error(
              Text001,
              ErrorText, TableCaption(), FieldCaption("Location Code"), "Location Code",
              FieldCaption(Code), Code, WhseShptLine.TableCaption());

        OnAfterCheckEmptyBin(Rec);
    end;

    procedure CheckIncreaseBin(BinCode: Code[20]; ItemNo: Code[20]; Qty: Decimal; DeductCubage: Decimal; DeductWeight: Decimal; PutawayCubage: Decimal; PutawayWeight: Decimal; CalledbyPosting: Boolean; IgnoreError: Boolean): Boolean
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        AvailableWeight: Decimal;
        AvailableCubage: Decimal;
    begin
        if "Block Movement" in ["Block Movement"::Inbound, "Block Movement"::All] then
            FieldError("Block Movement");

        GetLocation("Location Code");
        if not Location."Directed Put-away and Pick" then
            FeatureTelemetry.LogUsage('0000JNN', 'Bin Capacity', 'check Bin Capacity for basic warehouse');

        if Code = Location."Adjustment Bin Code" then
            exit;

        if ItemNo <> '' then
            if Location."Check Whse. Class" then
                if not CheckWhseClass(ItemNo, IgnoreError) then
                    exit(false);

        if (Qty <> 0) and (("Maximum Cubage" <> 0) or ("Maximum Weight" <> 0)) then
            if Location."Bin Capacity Policy" in
               [Location."Bin Capacity Policy"::"Allow More Than Max. Capacity",
                Location."Bin Capacity Policy"::"Prohibit More Than Max. Cap."]
            then begin
                CalcCubageAndWeight(AvailableCubage, AvailableWeight, CalledbyPosting);
                if not CalledbyPosting then begin
                    AvailableCubage := AvailableCubage + DeductCubage;
                    AvailableWeight := AvailableWeight + DeductWeight;
                end;

                if ("Maximum Cubage" <> 0) and (PutawayCubage > AvailableCubage) then
                    WMSMgt.CheckPutAwayAvailability(
                      BinCode, WarehouseActivityLine.FieldCaption(Cubage), TableCaption(), PutawayCubage, AvailableCubage,
                      (Location."Bin Capacity Policy" =
                       Location."Bin Capacity Policy"::"Prohibit More Than Max. Cap.") and CalledbyPosting);

                if ("Maximum Weight" <> 0) and (PutawayWeight > AvailableWeight) then
                    WMSMgt.CheckPutAwayAvailability(
                      BinCode, WarehouseActivityLine.FieldCaption(Weight), TableCaption(), PutawayWeight, AvailableWeight,
                      (Location."Bin Capacity Policy" =
                       Location."Bin Capacity Policy"::"Prohibit More Than Max. Cap.") and CalledbyPosting);
            end;
        exit(true);
    end;

    local procedure IsBinPropertiesAlreadySet(Bin: Record Bin): Boolean
    begin
        if Bin."Bin Ranking" <> 0 then
            exit(true);

        if Bin."Bin Type Code" <> '' then
            exit(true);

        if Bin."Warehouse Class Code" <> '' then
            exit(true);

        if Bin."Special Equipment Code" <> '' then
            exit(true);
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if Location.Code <> LocationCode then
            Location.Get(LocationCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckEmptyBin(var Bin: Record Bin)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcCubageAndWeight(Bin: Record Bin; CalledByPosting: Boolean; var Cubage: Decimal; var Weight: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var Bin: Record Bin)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckMaxQtyBinContent(var Bin: Record Bin; CheckWeight: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWhseClass(Bin: Record Bin; ItemNo: Code[20]; var ResultValue: Boolean; var IsHandled: Boolean; IgnoreError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnInsert(var Bin: Record Bin; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnModify(var Bin: Record Bin; var xBin: Record Bin; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckEmptyBin(var Bin: Record Bin; ErrorText: Text[250]; var IsHandled: Boolean)
    begin
    end;
}

