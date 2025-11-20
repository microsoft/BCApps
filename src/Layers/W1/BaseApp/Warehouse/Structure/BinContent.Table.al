// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Structure;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Tracking;
using Microsoft.Warehouse.Worksheet;
using System.Globalization;
using System.Telemetry;
using System.Utilities;

table 7302 "Bin Content"
{
    Caption = 'Bin Content';
    DrillDownPageID = "Bin Contents List";
    LookupPageID = "Bin Contents List";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            NotBlank = true;
            TableRelation = Location;

            trigger OnValidate()
            begin
                if (CurrFieldNo <> 0) and ("Location Code" <> xRec."Location Code") then begin
                    CheckManualChange(FieldCaption("Location Code"));
                    "Bin Code" := '';
                end;
            end;
        }
        field(2; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
            Editable = false;
            NotBlank = true;
            TableRelation = Zone.Code where("Location Code" = field("Location Code"));

            trigger OnValidate()
            begin
                if (CurrFieldNo <> 0) and ("Zone Code" <> xRec."Zone Code") then
                    CheckManualChange(FieldCaption("Zone Code"));
            end;
        }
        field(3; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            NotBlank = true;
            TableRelation = if ("Zone Code" = filter('')) Bin.Code where("Location Code" = field("Location Code"))
            else
            if ("Zone Code" = filter(<> '')) Bin.Code where("Location Code" = field("Location Code"),
                                                                               "Zone Code" = field("Zone Code"));

            trigger OnValidate()
            begin
                if (CurrFieldNo <> 0) and ("Bin Code" <> xRec."Bin Code") then begin
                    CheckManualChange(FieldCaption("Bin Code"));
                    GetBin("Location Code", "Bin Code");
                    Dedicated := Bin.Dedicated;
                    "Bin Type Code" := Bin."Bin Type Code";
                    "Warehouse Class Code" := Bin."Warehouse Class Code";
                    "Bin Ranking" := Bin."Bin Ranking";
                    "Block Movement" := Bin."Block Movement";
                    "Zone Code" := Bin."Zone Code";
                    OnAfterValidateBinCode(Rec, xRec, Bin);
                end;
            end;
        }
        field(4; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            NotBlank = true;
            TableRelation = Item where(Type = const(Inventory));

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                if (CurrFieldNo <> 0) and ("Item No." <> xRec."Item No.") then begin
                    CheckManualChange(FieldCaption("Item No."));
                    IsHandled := false;
                    OnValidateItemNoOnBeforeValidateVariantCode(Rec, IsHandled);
                    if not IsHandled then
                        "Variant Code" := '';
                end;

                if ("Item No." <> xRec."Item No.") and ("Item No." <> '') then begin
                    GetItem("Item No.");
                    Validate("Unit of Measure Code", Item."Base Unit of Measure");
                    OnValidateItemNoOnAfterValidateUoMCode(Rec, Item);
                end;
            end;
        }
        field(10; "Bin Type Code"; Code[10])
        {
            Caption = 'Bin Type Code';
            Editable = false;
            TableRelation = "Bin Type";
        }
        field(11; "Warehouse Class Code"; Code[10])
        {
            Caption = 'Warehouse Class Code';
            Editable = false;
            TableRelation = "Warehouse Class";
        }
        field(12; "Block Movement"; Option)
        {
            Caption = 'Block Movement';
            OptionCaption = ' ,Inbound,Outbound,All';
            OptionMembers = " ",Inbound,Outbound,All;
        }
        field(15; "Min. Qty."; Decimal)
        {
            Caption = 'Min. Qty.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(16; "Max. Qty."; Decimal)
        {
            Caption = 'Max. Qty.';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                if "Max. Qty." <> xRec."Max. Qty." then
                    CheckBinMaxCubageAndWeight();
            end;
        }
        field(21; "Bin Ranking"; Integer)
        {
            Caption = 'Bin Ranking';
            Editable = false;
        }
        field(26; Quantity; Decimal)
        {
            CalcFormula = sum("Warehouse Entry".Quantity where("Location Code" = field("Location Code"),
                                                                "Bin Code" = field("Bin Code"),
                                                                "Item No." = field("Item No."),
                                                                "Variant Code" = field("Variant Code"),
                                                                "Unit of Measure Code" = field("Unit of Measure Code"),
                                                                "Lot No." = field("Lot No. Filter"),
                                                                "Serial No." = field("Serial No. Filter"),
                                                                "Package No." = field("Package No. Filter")));
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(29; "Pick Qty."; Decimal)
        {
            CalcFormula = sum("Warehouse Activity Line"."Qty. Outstanding" where("Location Code" = field("Location Code"),
                                                                                  "Bin Code" = field("Bin Code"),
                                                                                  "Item No." = field("Item No."),
                                                                                  "Variant Code" = field("Variant Code"),
                                                                                  "Unit of Measure Code" = field("Unit of Measure Code"),
                                                                                  "Action Type" = const(Take),
                                                                                  "Lot No." = field("Lot No. Filter"),
                                                                                  "Serial No." = field("Serial No. Filter"),
                                                                                  "Package No." = field("Package No. Filter"),
                                                                                  "Assemble to Order" = const(false)));
            Caption = 'Pick Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(30; "Neg. Adjmt. Qty."; Decimal)
        {
            CalcFormula = sum("Warehouse Journal Line"."Qty. (Absolute)" where("Location Code" = field("Location Code"),
                                                                                "From Bin Code" = field("Bin Code"),
                                                                                "Item No." = field("Item No."),
                                                                                "Variant Code" = field("Variant Code"),
                                                                                "Unit of Measure Code" = field("Unit of Measure Code"),
                                                                                "Lot No." = field("Lot No. Filter"),
                                                                                "Serial No." = field("Serial No. Filter"),
                                                                                "Package No." = field("Package No. Filter")));
            Caption = 'Neg. Adjmt. Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(31; "Put-away Qty."; Decimal)
        {
            CalcFormula = sum("Warehouse Activity Line"."Qty. Outstanding" where("Location Code" = field("Location Code"),
                                                                                  "Bin Code" = field("Bin Code"),
                                                                                  "Item No." = field("Item No."),
                                                                                  "Variant Code" = field("Variant Code"),
                                                                                  "Unit of Measure Code" = field("Unit of Measure Code"),
                                                                                  "Action Type" = const(Place),
                                                                                  "Lot No." = field("Lot No. Filter"),
                                                                                  "Serial No." = field("Serial No. Filter"),
                                                                                  "Package No." = field("Package No. Filter")));
            Caption = 'Put-away Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(32; "Pos. Adjmt. Qty."; Decimal)
        {
            CalcFormula = sum("Warehouse Journal Line"."Qty. (Absolute)" where("Location Code" = field("Location Code"),
                                                                                "To Bin Code" = field("Bin Code"),
                                                                                "Item No." = field("Item No."),
                                                                                "Variant Code" = field("Variant Code"),
                                                                                "Unit of Measure Code" = field("Unit of Measure Code"),
                                                                                "Lot No." = field("Lot No. Filter"),
                                                                                "Serial No." = field("Serial No. Filter"),
                                                                                "Package No." = field("Package No. Filter")));
            Caption = 'Pos. Adjmt. Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(37; "Fixed"; Boolean)
        {
            Caption = 'Fixed';
        }
        field(40; "Cross-Dock Bin"; Boolean)
        {
            Caption = 'Cross-Dock Bin';
        }
        field(41; Default; Boolean)
        {
            Caption = 'Default';

            trigger OnValidate()
            begin
                if (xRec.Default <> Default) and Default then
                    if WMSManagement.CheckDefaultBin(
                         "Item No.", "Variant Code", "Location Code", "Bin Code")
                    then
                        Error(Text010, "Location Code", "Item No.", "Variant Code");
            end;
        }
        field(50; "Quantity (Base)"; Decimal)
        {
            CalcFormula = sum("Warehouse Entry"."Qty. (Base)" where("Location Code" = field("Location Code"),
                                                                     "Bin Code" = field("Bin Code"),
                                                                     "Item No." = field("Item No."),
                                                                     "Variant Code" = field("Variant Code"),
                                                                     "Unit of Measure Code" = field("Unit of Measure Code"),
                                                                     "Lot No." = field("Lot No. Filter"),
                                                                     "Serial No." = field("Serial No. Filter"),
                                                                     "Package No." = field("Package No. Filter")));
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(51; "Pick Quantity (Base)"; Decimal)
        {
            CalcFormula = sum("Warehouse Activity Line"."Qty. Outstanding (Base)" where("Location Code" = field("Location Code"),
                                                                                         "Bin Code" = field("Bin Code"),
                                                                                         "Item No." = field("Item No."),
                                                                                         "Variant Code" = field("Variant Code"),
                                                                                         "Unit of Measure Code" = field("Unit of Measure Filter"),
                                                                                         "Action Type" = const(Take),
                                                                                         "Lot No." = field("Lot No. Filter"),
                                                                                         "Serial No." = field("Serial No. Filter"),
                                                                                         "Package No." = field("Package No. Filter"),
                                                                                         "Assemble to Order" = const(false)));
            Caption = 'Pick Quantity (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(52; "Negative Adjmt. Qty. (Base)"; Decimal)
        {
            CalcFormula = sum("Warehouse Journal Line"."Qty. (Absolute, Base)" where("Location Code" = field("Location Code"),
                                                                                      "From Bin Code" = field("Bin Code"),
                                                                                      "Item No." = field("Item No."),
                                                                                      "Variant Code" = field("Variant Code"),
                                                                                      "Unit of Measure Code" = field("Unit of Measure Code"),
                                                                                      "Lot No." = field("Lot No. Filter"),
                                                                                      "Serial No." = field("Serial No. Filter"),
                                                                                      "Package No." = field("Package No. Filter")));
            Caption = 'Negative Adjmt. Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(53; "Put-away Quantity (Base)"; Decimal)
        {
            CalcFormula = sum("Warehouse Activity Line"."Qty. Outstanding (Base)" where("Location Code" = field("Location Code"),
                                                                                         "Bin Code" = field("Bin Code"),
                                                                                         "Item No." = field("Item No."),
                                                                                         "Variant Code" = field("Variant Code"),
                                                                                         "Unit of Measure Code" = field("Unit of Measure Code"),
                                                                                         "Action Type" = const(Place),
                                                                                         "Lot No." = field("Lot No. Filter"),
                                                                                         "Serial No." = field("Serial No. Filter"),
                                                                                         "Package No." = field("Package No. Filter")));
            Caption = 'Put-away Quantity (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(54; "Positive Adjmt. Qty. (Base)"; Decimal)
        {
            CalcFormula = sum("Warehouse Journal Line"."Qty. (Absolute, Base)" where("Location Code" = field("Location Code"),
                                                                                      "To Bin Code" = field("Bin Code"),
                                                                                      "Item No." = field("Item No."),
                                                                                      "Variant Code" = field("Variant Code"),
                                                                                      "Unit of Measure Code" = field("Unit of Measure Code"),
                                                                                      "Lot No." = field("Lot No. Filter"),
                                                                                      "Serial No." = field("Serial No. Filter"),
                                                                                      "Package No." = field("Package No. Filter")));
            Caption = 'Positive Adjmt. Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(55; "ATO Components Pick Qty."; Decimal)
        {
            CalcFormula = sum("Warehouse Activity Line"."Qty. Outstanding" where("Location Code" = field("Location Code"),
                                                                                  "Bin Code" = field("Bin Code"),
                                                                                  "Item No." = field("Item No."),
                                                                                  "Variant Code" = field("Variant Code"),
                                                                                  "Unit of Measure Code" = field("Unit of Measure Code"),
                                                                                  "Action Type" = const(Take),
                                                                                  "Lot No." = field("Lot No. Filter"),
                                                                                  "Serial No." = field("Serial No. Filter"),
                                                                                  "Package No." = field("Package No. Filter"),
                                                                                  "Assemble to Order" = const(true),
                                                                                  "ATO Component" = const(true)));
            Caption = 'ATO Components Pick Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(56; "ATO Components Pick Qty (Base)"; Decimal)
        {
            CalcFormula = sum("Warehouse Activity Line"."Qty. Outstanding (Base)" where("Location Code" = field("Location Code"),
                                                                                         "Bin Code" = field("Bin Code"),
                                                                                         "Item No." = field("Item No."),
                                                                                         "Variant Code" = field("Variant Code"),
                                                                                         "Unit of Measure Code" = field("Unit of Measure Code"),
                                                                                         "Action Type" = const(Take),
                                                                                         "Lot No." = field("Lot No. Filter"),
                                                                                         "Serial No." = field("Serial No. Filter"),
                                                                                         "Package No." = field("Package No. Filter"),
                                                                                         "Assemble to Order" = const(true),
                                                                                         "ATO Component" = const(true)));
            Caption = 'ATO Components Pick Qty (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            begin
                if (CurrFieldNo <> 0) and ("Variant Code" <> xRec."Variant Code") then
                    CheckManualChange(FieldCaption("Variant Code"));
            end;
        }
        field(5404; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            NotBlank = true;
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            begin
                if (CurrFieldNo <> 0) and ("Unit of Measure Code" <> xRec."Unit of Measure Code") then
                    CheckManualChange(FieldCaption("Unit of Measure Code"));

                GetItem("Item No.");
                "Qty. per Unit of Measure" :=
                  UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
            end;
        }
        field(6500; "Lot No. Filter"; Code[50])
        {
            Caption = 'Lot No. Filter';
            FieldClass = FlowFilter;
        }
        field(6501; "Serial No. Filter"; Code[50])
        {
            Caption = 'Serial No. Filter';
            FieldClass = FlowFilter;
        }
        field(6515; "Package No. Filter"; Code[50])
        {
            Caption = 'Package No. Filter';
            CaptionClass = '6,3';
            FieldClass = FlowFilter;
        }
        field(6502; Dedicated; Boolean)
        {
            Caption = 'Dedicated';
            Editable = false;
        }
        field(6503; "Unit of Measure Filter"; Code[10])
        {
            Caption = 'Unit of Measure Filter';
            FieldClass = FlowFilter;
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
    }

    keys
    {
        key(Key1; "Location Code", "Bin Code", "Item No.", "Variant Code", "Unit of Measure Code")
        {
            Clustered = true;
        }
        key(Key2; "Bin Type Code")
        {
            IncludedFields = Dedicated, "Block Movement";
        }
        key(Key3; "Location Code", "Item No.", "Variant Code", "Cross-Dock Bin", "Qty. per Unit of Measure", "Bin Ranking")
        {
        }
        key(Key4; "Location Code", "Warehouse Class Code", "Fixed", "Bin Ranking")
        {
        }
        key(Key5; "Location Code", "Item No.", "Variant Code", "Warehouse Class Code", "Fixed", "Bin Ranking")
        {
        }
        key(Key6; "Item No.")
        {
        }
        key(Key7; Default, "Location Code", "Item No.", "Variant Code", "Bin Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Location Code", "Bin Code", "Item No.", "Variant Code", "Unit of Measure Code")
        {
        }
        fieldgroup(Brick; "Location Code", "Bin Code", "Zone Code", "Item No.", Quantity)
        { }
    }

    trigger OnDelete()
    var
        BinContent: Record "Bin Content";
    begin
        BinContent := Rec;
        BinContent.CalcFields(
          "Quantity (Base)", "Pick Quantity (Base)", "Negative Adjmt. Qty. (Base)",
          "Put-away Quantity (Base)", "Positive Adjmt. Qty. (Base)");
        if BinContent."Quantity (Base)" <> 0 then
            Error(Text000, TableCaption);

        if (BinContent."Pick Quantity (Base)" <> 0) or (BinContent."Negative Adjmt. Qty. (Base)" <> 0) or
           (BinContent."Put-away Quantity (Base)" <> 0) or (BinContent."Positive Adjmt. Qty. (Base)" <> 0)
        then
            Error(Text001, TableCaption);
    end;

    trigger OnInsert()
    begin
        if Default then
            if WMSManagement.CheckDefaultBin(
                 "Item No.", "Variant Code", "Location Code", "Bin Code")
            then
                Error(Text010, "Location Code", "Item No.", "Variant Code");

        GetLocation("Location Code");
        if Location."Directed Put-away and Pick" then
            TestField("Zone Code");

        if "Min. Qty." > "Max. Qty." then
            Error(
              Text005,
              FieldCaption("Max. Qty."), "Max. Qty.",
              FieldCaption("Min. Qty."), "Min. Qty.");
    end;

    trigger OnModify()
    begin
        if Default then
            if WMSManagement.CheckDefaultBin(
                 "Item No.", "Variant Code", "Location Code", "Bin Code")
            then
                Error(Text010, "Location Code", "Item No.", "Variant Code");

        GetLocation("Location Code");
        if Location."Directed Put-away and Pick" then
            TestField("Zone Code");

        if "Min. Qty." > "Max. Qty." then
            Error(
              Text005,
              FieldCaption("Max. Qty."), "Max. Qty.",
              FieldCaption("Min. Qty."), "Min. Qty.");
    end;

    var
        Item: Record Item;
        Location: Record Location;
        Bin: Record Bin;
        UOMMgt: Codeunit "Unit of Measure Management";
        WMSManagement: Codeunit "WMS Management";
        StockProposal: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot delete this %1, because the %1 contains items.';
        Text001: Label 'You cannot delete this %1, because warehouse document lines have items allocated to this %1.';
        Text002: Label 'The total cubage %1 of the %2 for the %5 exceeds the %3 %4 of the %5.\Do you still want enter this %2?';
        Text003: Label 'The total weight %1 of the %2 for the %5 exceeds the %3 %4 of the %5.\Do you still want enter this %2?';
#pragma warning restore AA0470
        Text004: Label 'Cancelled.';
#pragma warning disable AA0470
        Text005: Label 'The %1 %2 must not be less than the %3 %4.';
        Text006: Label 'available must not be less than %1';
        Text007: Label 'You cannot modify the %1, because the %2 contains items.';
        Text008: Label 'You cannot modify the %1, because warehouse document lines have items allocated to this %2.';
        Text010: Label 'There is already a default bin content for location code %1, item no. %2 and variant code %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure SetUpNewLine()
    begin
        GetBin("Location Code", "Bin Code");
        Dedicated := Bin.Dedicated;
        "Bin Type Code" := Bin."Bin Type Code";
        "Warehouse Class Code" := Bin."Warehouse Class Code";
        "Bin Ranking" := Bin."Bin Ranking";
        "Block Movement" := Bin."Block Movement";
        "Zone Code" := Bin."Zone Code";
        "Cross-Dock Bin" := Bin."Cross-Dock Bin";
        OnAfterSetUpNewLine(Rec, Bin)
    end;

    local procedure CheckManualChange(CaptionField: Text[80])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckManualChange(Rec, xRec, CaptionField, IsHandled);
        if IsHandled then
            exit;

        if not IsNullGuid(xRec.SystemId) then begin // if xRec exist
            xRec.CalcFields(
                "Quantity (Base)", "Positive Adjmt. Qty. (Base)", "Put-away Quantity (Base)",
                "Negative Adjmt. Qty. (Base)", "Pick Quantity (Base)");
            if xRec."Quantity (Base)" <> 0 then
                Error(Text007, CaptionField, TableCaption);
            if (xRec."Positive Adjmt. Qty. (Base)" <> 0) or (xRec."Put-away Quantity (Base)" <> 0) or
                (xRec."Negative Adjmt. Qty. (Base)" <> 0) or (xRec."Pick Quantity (Base)" <> 0)
            then
                Error(Text008, CaptionField, TableCaption);
        end;
    end;

    procedure CalcQtyAvailToTake(ExcludeQtyBase: Decimal): Decimal
    var
        QtyAvailToTake: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcQtyAvailToTake(Rec, ExcludeQtyBase, QtyAvailToTake, IsHandled);
        if IsHandled then
            exit(QtyAvailToTake);

        if Rec.ReadIsolation() <> IsolationLevel::UpdLock then
            Rec.ReadIsolation(IsolationLevel::ReadCommitted);

        SetFilterOnUnitOfMeasure();
        CalcFields("Quantity (Base)", "Negative Adjmt. Qty. (Base)", "Pick Quantity (Base)", "ATO Components Pick Qty (Base)");
        exit(
          "Quantity (Base)" -
          (("Pick Quantity (Base)" + "ATO Components Pick Qty (Base)") - ExcludeQtyBase + "Negative Adjmt. Qty. (Base)"));
    end;

    procedure CalcQtyAvailToTakeUOM() Result: Decimal
    begin
        if Rec.ReadIsolation() <> IsolationLevel::UpdLock then
            Rec.ReadIsolation(IsolationLevel::ReadCommitted);

        GetItem("Item No.");
        if Item."No." <> '' then
            Result := Round(CalcQtyAvailToTake(0) / UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code"), UOMMgt.QtyRndPrecision());
        OnAfterCalcQtyAvailToTakeUOM(Rec, Result);
    end;

    local procedure CalcTotalQtyAvailToTake(ExcludeQtyBase: Decimal) Result: Decimal
    var
        TotalQtyBase: Decimal;
        TotalNegativeAdjmtQtyBase: Decimal;
        TotalATOComponentsPickQtyBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcTotalQtyAvailToTake(Rec, ExcludeQtyBase, Result, IsHandled);
        if IsHandled then
            exit(Result);

        TotalQtyBase := CalcTotalQtyBase();
        TotalNegativeAdjmtQtyBase := CalcTotalNegativeAdjmtQtyBase();
        TotalATOComponentsPickQtyBase := CalcTotalATOComponentsPickQtyBase();
        SetFilterOnUnitOfMeasure();
        CalcFields("Pick Quantity (Base)");
        OnCalcTotalQtyAvailToTakeOnAfterCalcPickQuantityBase(Rec, ExcludeQtyBase, TotalNegativeAdjmtQtyBase);
        exit(
          TotalQtyBase -
          ("Pick Quantity (Base)" + TotalATOComponentsPickQtyBase - ExcludeQtyBase + TotalNegativeAdjmtQtyBase));
    end;

    procedure CalcQtyAvailToPick(ExcludeQtyBase: Decimal) Result: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcQtyAvailToPick(Rec, Result, IsHandled, ExcludeQtyBase);
        if IsHandled then
            exit;

        if Rec.ReadIsolation() <> IsolationLevel::UpdLock then
            Rec.ReadIsolation(IsolationLevel::ReadCommitted);

        if (not Dedicated) and (not ("Block Movement" in ["Block Movement"::Outbound, "Block Movement"::All])) then
            exit(CalcQtyAvailToTake(ExcludeQtyBase) - CalcQtyWithBlockedItemTracking());
    end;

    procedure CalcQtyAvailToPickIncludingDedicated(ExcludeQtyBase: Decimal) Result: Decimal
    begin
        if Rec.ReadIsolation() <> IsolationLevel::UpdLock then
            Rec.ReadIsolation(IsolationLevel::ReadCommitted);

        if not ("Block Movement" in ["Block Movement"::Outbound, "Block Movement"::All]) then
            Result := CalcQtyAvailToTake(ExcludeQtyBase) - CalcQtyWithBlockedItemTracking();
        OnAfterCalcQtyAvailToPickIncludingDedicated(Rec, ExcludeQtyBase, Result);
    end;

    procedure CalcQtyWithBlockedItemTracking(): Decimal
    var
        SerialNoInfo: Record "Serial No. Information";
        LotNoInfo: Record "Lot No. Information";
        XBinContent: Record "Bin Content";
        QtySNBlocked: Decimal;
        QtyLNBlocked: Decimal;
        QtySNAndLNBlocked: Decimal;
        QtyWithBlockedItemTracking: Decimal;
        SNGiven: Boolean;
        LNGiven: Boolean;
        NoITGiven: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcQtyWithBlockedItemTracking(Rec, QtyWithBlockedItemTracking, IsHandled);
        if IsHandled then
            exit(QtyWithBlockedItemTracking);

        SerialNoInfo.SetRange("Item No.", "Item No.");
        SerialNoInfo.SetRange("Variant Code", "Variant Code");
        CopyFilter("Serial No. Filter", SerialNoInfo."Serial No.");
        SerialNoInfo.SetRange(Blocked, true);

        LotNoInfo.SetRange("Item No.", "Item No.");
        LotNoInfo.SetRange("Variant Code", "Variant Code");
        CopyFilter("Lot No. Filter", LotNoInfo."Lot No.");
        LotNoInfo.SetRange(Blocked, true);

        if SerialNoInfo.IsEmpty() and LotNoInfo.IsEmpty() then
            exit;

        SNGiven := not (GetFilter("Serial No. Filter") = '');
        LNGiven := not (GetFilter("Lot No. Filter") = '');

        XBinContent.Copy(Rec);
        ClearTrackingFilters();

        if Rec.ReadIsolation() <> IsolationLevel::UpdLock then
            Rec.ReadIsolation(IsolationLevel::ReadCommitted);

        NoITGiven := not SNGiven and not LNGiven;
        if SNGiven or NoITGiven then
            if SerialNoInfo.FindSet() then
                repeat
                    SetRange("Serial No. Filter", SerialNoInfo."Serial No.");
                    CalcFields("Quantity (Base)");
                    QtySNBlocked += "Quantity (Base)";
                    SetRange("Serial No. Filter");
                until SerialNoInfo.Next() = 0;

        if LNGiven or NoITGiven then
            if LotNoInfo.FindSet() then
                repeat
                    SetRange("Lot No. Filter", LotNoInfo."Lot No.");
                    CalcFields("Quantity (Base)");
                    QtyLNBlocked += "Quantity (Base)";
                    SetRange("Lot No. Filter");
                until LotNoInfo.Next() = 0;

        if (SNGiven and LNGiven) or NoITGiven then
            if SerialNoInfo.FindSet() then
                repeat
                    if LotNoInfo.FindSet() then
                        repeat
                            SetRange("Serial No. Filter", SerialNoInfo."Serial No.");
                            SetRange("Lot No. Filter", LotNoInfo."Lot No.");
                            CalcFields("Quantity (Base)");
                            QtySNAndLNBlocked += "Quantity (Base)";
                        until LotNoInfo.Next() = 0;
                until SerialNoInfo.Next() = 0;

        Copy(XBinContent);
        exit(QtySNBlocked + QtyLNBlocked - QtySNAndLNBlocked);
    end;

    procedure CalcQtyAvailToPutAway(ExcludeQtyBase: Decimal) Result: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcQtyAvailToPutAway(Rec, ExcludeQtyBase, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if Rec.ReadIsolation() <> IsolationLevel::UpdLock then
            Rec.ReadIsolation(IsolationLevel::ReadCommitted);

        CalcFields("Quantity (Base)", "Positive Adjmt. Qty. (Base)", "Put-away Quantity (Base)");
        exit(
          Round("Max. Qty." * "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision()) -
          ("Quantity (Base)" + "Put-away Quantity (Base)" - ExcludeQtyBase + "Positive Adjmt. Qty. (Base)"));
    end;

    procedure NeedToReplenish(ExcludeQtyBase: Decimal) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeNeedToReplenish(Rec, ExcludeQtyBase, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if Rec.ReadIsolation() <> IsolationLevel::UpdLock then
            Rec.ReadIsolation(IsolationLevel::ReadCommitted);

        CalcFields("Quantity (Base)", "Positive Adjmt. Qty. (Base)", "Put-away Quantity (Base)");
        exit(
          Round("Min. Qty." * "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision()) >
          "Quantity (Base)" +
          Abs("Put-away Quantity (Base)" - ExcludeQtyBase + "Positive Adjmt. Qty. (Base)") +
          CalcWorksheetQty());

    end;

    procedure CalcQtyToReplenish(ExcludeQtyBase: Decimal) Result: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcQtyToReplenish(Rec, ExcludeQtyBase, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if Rec.ReadIsolation() <> IsolationLevel::UpdLock then
            Rec.ReadIsolation(IsolationLevel::ReadCommitted);

        CalcFields("Quantity (Base)", "Positive Adjmt. Qty. (Base)", "Put-away Quantity (Base)");
        exit(
          Round("Max. Qty." * "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision()) -
          ("Quantity (Base)" + "Put-away Quantity (Base)" - ExcludeQtyBase + "Positive Adjmt. Qty. (Base)"));
    end;

    local procedure CheckBinMaxCubageAndWeight()
    var
        BinContent: Record "Bin Content";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        WMSMgt: Codeunit "WMS Management";
        TotalCubage: Decimal;
        TotalWeight: Decimal;
        Cubage: Decimal;
        Weight: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBinMaxCubageAndWeight(BinContent, Bin, IsHandled);
        if IsHandled then
            exit;

        GetBin("Location Code", "Bin Code");
        if (Bin."Maximum Cubage" <> 0) or (Bin."Maximum Weight" <> 0) then begin
            BinContent.SetRange("Location Code", "Location Code");
            BinContent.SetRange("Bin Code", "Bin Code");
            if BinContent.Find('-') then
                repeat
                    if (BinContent."Location Code" = "Location Code") and
                       (BinContent."Bin Code" = "Bin Code") and
                       (BinContent."Item No." = "Item No.") and
                       (BinContent."Variant Code" = "Variant Code") and
                       (BinContent."Unit of Measure Code" = "Unit of Measure Code")
                    then
                        WMSMgt.CalcCubageAndWeight(
                          "Item No.", "Unit of Measure Code", "Max. Qty.", Cubage, Weight)
                    else
                        WMSMgt.CalcCubageAndWeight(
                          BinContent."Item No.", BinContent."Unit of Measure Code",
                          BinContent."Max. Qty.", Cubage, Weight);
                    TotalCubage := TotalCubage + Cubage;
                    TotalWeight := TotalWeight + Weight;
                until BinContent.Next() = 0;

            ItemUnitOfMeasure.SetLoadFields(Cubage, Weight);
            ItemUnitOfMeasure.Get("Item No.", "Unit of Measure Code");
            if ItemUnitOfMeasure.Cubage > 0 then
                if (Bin."Maximum Cubage" > 0) and (Bin."Maximum Cubage" - TotalCubage < 0) then
                    if not Confirm(
                         Text002,
                         false, TotalCubage, FieldCaption("Max. Qty."),
                         Bin.FieldCaption("Maximum Cubage"), Bin."Maximum Cubage", Bin.TableCaption())
                    then
                        Error(Text004);
            if ItemUnitOfMeasure.Weight > 0 then
                if (Bin."Maximum Weight" > 0) and (Bin."Maximum Weight" - TotalWeight < 0) then
                    if not Confirm(
                         Text003,
                         false, TotalWeight, FieldCaption("Max. Qty."),
                         Bin.FieldCaption("Maximum Weight"), Bin."Maximum Weight", Bin.TableCaption())
                    then
                        Error(Text004);
        end;
    end;

    procedure CheckDecreaseBinContent(Qty: Decimal; var QtyBase: Decimal; DecreaseQtyBase: Decimal)
    var
        WhseActivLine: Record "Warehouse Activity Line";
        QtyAvailToPickBase: Decimal;
        QtyAvailToPick: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDecreaseBinContent(Qty, QtyBase, DecreaseQtyBase, IsHandled);
        if IsHandled then
            exit;

        if "Block Movement" in ["Block Movement"::Outbound, "Block Movement"::All] then
            FieldError("Block Movement");

        GetLocation("Location Code");
        if "Bin Code" = Location."Adjustment Bin Code" then
            exit;

        if Rec.ReadIsolation() <> IsolationLevel::UpdLock then
            Rec.ReadIsolation(IsolationLevel::ReadCommitted);

        WhseActivLine.ReadIsolation(IsolationLevel::ReadUnCommitted);
        WhseActivLine.SetRange("Item No.", "Item No.");
        WhseActivLine.SetRange("Bin Code", "Bin Code");
        WhseActivLine.SetRange("Location Code", "Location Code");
        WhseActivLine.SetRange("Unit of Measure Code", "Unit of Measure Code");
        WhseActivLine.SetRange("Variant Code", "Variant Code");

        if Location."Allow Breakbulk" then begin
            WhseActivLine.SetRange("Action Type", WhseActivLine."Action Type"::Take);
            WhseActivLine.SetRange("Original Breakbulk", true);
            WhseActivLine.SetRange("Breakbulk No.", 0);
            WhseActivLine.CalcSums("Qty. (Base)");
            DecreaseQtyBase := DecreaseQtyBase + WhseActivLine."Qty. (Base)";
        end;

        QtyAvailToPickBase := CalcTotalQtyAvailToTake(DecreaseQtyBase);
        OnCheckDecreaseBinContentOnAfterCalcTotalQtyAvailToTake(WhseActivLine, QtyAvailToPickBase, DecreaseQtyBase, Rec);
        if QtyAvailToPickBase < QtyBase then begin
            GetItem("Item No.");
            QtyAvailToPick :=
              Round(QtyAvailToPickBase / UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code"), UOMMgt.QtyRndPrecision());
            if QtyAvailToPick = Qty then
                QtyBase := QtyAvailToPickBase // rounding issue- qty is same, but not qty (base)
            else
                FieldError("Quantity (Base)", StrSubstNo(Text006, Abs(QtyBase)));
        end;
    end;

    procedure CheckIncreaseBinContent(QtyBase: Decimal; DeductQtyBase: Decimal; DeductCubage: Decimal; DeductWeight: Decimal; PutawayCubage: Decimal; PutawayWeight: Decimal; CalledbyPosting: Boolean; IgnoreError: Boolean) Result: Boolean
    var
        WhseActivLine: Record "Warehouse Activity Line";
        WMSMgt: Codeunit "WMS Management";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        Math: Codeunit Math;
        QtyAvailToPutAwayBase: Decimal;
        AvailableWeight: Decimal;
        AvailableCubage: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckIncreaseBinContent(Rec, QtyBase, DeductQtyBase, DeductCubage, DeductWeight, PutawayCubage, PutawayWeight, CalledbyPosting, IgnoreError, Result, IsHandled);
        if IsHandled then
            exit;

        if "Block Movement" in ["Block Movement"::Inbound, "Block Movement"::All] then
            if not StockProposal then
                FieldError("Block Movement");

        GetLocation("Location Code");
        if not Location."Directed Put-away and Pick" then
            FeatureTelemetry.LogUsage('0000JNO', 'Bin Capacity', 'check Bin Capacity for basic warehouse');

        if "Bin Code" = Location."Adjustment Bin Code" then
            exit;

        if Location."Check Whse. Class" then
            if not CheckWhseClass(IgnoreError) then
                exit(false);

        if QtyBase <> 0 then
            if Location."Bin Capacity Policy" in
               [Location."Bin Capacity Policy"::"Allow More Than Max. Capacity",
                Location."Bin Capacity Policy"::"Prohibit More Than Max. Cap."]
            then begin
                GetBin("Location Code", "Bin Code");
                if "Max. Qty." <> 0 then begin
                    QtyAvailToPutAwayBase := CalcQtyAvailToPutAway(DeductQtyBase);
                    if Location."Bin Capacity Policy" = Location."Bin Capacity Policy"::"Prohibit More Than Max. Cap." then
                        WMSMgt.CheckPutAwayAvailability(
                            "Bin Code", WhseActivLine.FieldCaption("Qty. (Base)"), TableCaption(), QtyBase, Math.Min(QtyAvailToPutAwayBase, "Max. Qty."),
                            (Location."Bin Capacity Policy" = Location."Bin Capacity Policy"::"Prohibit More Than Max. Cap.") and CalledbyPosting)
                    else
                        WMSMgt.CheckPutAwayAvailability(
                            "Bin Code", WhseActivLine.FieldCaption("Qty. (Base)"), TableCaption(), QtyBase, Math.Min(QtyAvailToPutAwayBase, ("Max. Qty." * "Qty. per Unit of Measure")),
                            (Location."Bin Capacity Policy" = Location."Bin Capacity Policy"::"Prohibit More Than Max. Cap.") and CalledbyPosting);
                end;
                if (Bin."Maximum Cubage" <> 0) or (Bin."Maximum Weight" <> 0) then begin
                    Bin.CalcCubageAndWeight(AvailableCubage, AvailableWeight, CalledbyPosting);
                    if not CalledbyPosting then begin
                        AvailableCubage := AvailableCubage + DeductCubage;
                        AvailableWeight := AvailableWeight + DeductWeight;
                    end;

                    if (Bin."Maximum Cubage" <> 0) and (PutawayCubage > AvailableCubage) then
                        WMSMgt.CheckPutAwayAvailability(
                          "Bin Code", WhseActivLine.FieldCaption(Cubage), Bin.TableCaption(), PutawayCubage, AvailableCubage,
                          (Location."Bin Capacity Policy" =
                           Location."Bin Capacity Policy"::"Prohibit More Than Max. Cap.") and CalledbyPosting);

                    if (Bin."Maximum Weight" <> 0) and (PutawayWeight > AvailableWeight) then
                        WMSMgt.CheckPutAwayAvailability(
                          "Bin Code", WhseActivLine.FieldCaption(Weight), Bin.TableCaption(), PutawayWeight, AvailableWeight,
                          (Location."Bin Capacity Policy" =
                           Location."Bin Capacity Policy"::"Prohibit More Than Max. Cap.") and CalledbyPosting);
                end;
            end;
        exit(true);
    end;

    procedure CheckWhseClass(IgnoreError: Boolean) Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWhseClass(Rec, Result, IsHandled, IgnoreError);
        if IsHandled then
            exit(Result);

        GetItem("Item No.");
        if IgnoreError then
            exit("Warehouse Class Code" = Item."Warehouse Class Code");
        TestField("Warehouse Class Code", Item."Warehouse Class Code");
        exit(true);
    end;

    procedure ShowBinContents(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; BinCode: Code[20])
    var
        BinContent: Record "Bin Content";
        BinContentLookup: Page "Bin Contents List";
    begin
        if BinCode <> '' then
            BinContent.SetRange("Bin Code", BinCode)
        else
            BinContent.SetCurrentKey("Location Code", "Item No.", "Variant Code");
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.SetRange("Variant Code", VariantCode);
        BinContentLookup.SetTableView(BinContent);
        BinContentLookup.Initialize(LocationCode);
        BinContentLookup.RunModal();
        Clear(BinContentLookup);
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if Location.Code <> LocationCode then
            Location.Get(LocationCode);
    end;

    local procedure GetBin(LocationCode: Code[10]; BinCode: Code[20])
    begin
        if (LocationCode = '') or (BinCode = '') then
            Bin.Init()
        else
            if (Bin."Location Code" <> LocationCode) or
               (Bin.Code <> BinCode)
            then
                Bin.Get(LocationCode, BinCode);
    end;

    local procedure GetItem(ItemNo: Code[20])
    begin
        if Item."No." = ItemNo then
            exit;

        if ItemNo = '' then
            Clear(Item)
        else begin
            Item.SetLoadFields("No.", Description, "Base Unit of Measure", "Warehouse Class Code");
            Item.Get(ItemNo);
        end;
    end;

    procedure GetItemDescr(ItemNo: Code[20]; VariantCode: Code[10]; var ItemDescription: Text[100])
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        OldItemNo: Code[20];
    begin
        OldItemNo := '';
        ItemDescription := '';
        if ItemNo <> OldItemNo then begin
            ItemDescription := '';
            if ItemNo <> '' then begin
                if Item.Get(ItemNo) then
                    ItemDescription := Item.Description;
                if VariantCode <> '' then
                    if ItemVariant.Get(ItemNo, VariantCode) then
                        ItemDescription := ItemVariant.Description;
            end;
            OldItemNo := ItemNo;
        end;
    end;

    procedure GetWhseLocation(var CurrentLocationCode: Code[10]; var CurrentZoneCode: Code[10])
    var
        Location: Record Location;
        WhseEmployee: Record "Warehouse Employee";
        WMSMgt: Codeunit "WMS Management";
        IsHandled: Boolean;
    begin
        if UserId <> '' then begin
            IsHandled := false;
            OnBeforeGetWhseLocation(CurrentLocationCode, CurrentZoneCode, IsHandled);
            if not IsHandled then
                WMSManagement.CheckUserIsWhseEmployee();
            if CurrentLocationCode <> '' then begin
                if not Location.Get(CurrentLocationCode) then begin
                    CurrentLocationCode := '';
                    CurrentZoneCode := '';
                end else
                    if not Location."Bin Mandatory" then begin
                        CurrentLocationCode := '';
                        CurrentZoneCode := '';
                    end else begin
                        WhseEmployee.SetRange("Location Code", CurrentLocationCode);
                        if WhseEmployee.IsEmpty() then begin
                            CurrentLocationCode := '';
                            CurrentZoneCode := '';
                        end;
                    end
                    ;
                if CurrentLocationCode = '' then begin
                    CurrentLocationCode := WMSMgt.GetDefaultLocation();
                    if CurrentLocationCode <> '' then begin
                        Location.Get(CurrentLocationCode);
                        if not Location."Bin Mandatory" then
                            CurrentLocationCode := '';
                    end;
                end;
            end;
        end;
        FilterGroup := 2;
        if CurrentLocationCode <> '' then
            SetRange("Location Code", CurrentLocationCode)
        else
            SetRange("Location Code");
        if CurrentZoneCode <> '' then
            SetRange("Zone Code", CurrentZoneCode)
        else
            SetRange("Zone Code");
        FilterGroup := 0;
    end;

    procedure CalcQtyonAdjmtBin(): Decimal
    var
        WhseEntry: Record "Warehouse Entry";
    begin
        GetLocation("Location Code");
        WhseEntry.SetRange("Item No.", "Item No.");
        WhseEntry.SetRange("Bin Code", Location."Adjustment Bin Code");
        WhseEntry.SetRange("Location Code", "Location Code");
        WhseEntry.SetRange("Variant Code", "Variant Code");
        WhseEntry.SetRange("Unit of Measure Code", "Unit of Measure Code");
        WhseEntry.CalcSums("Qty. (Base)");
        exit(WhseEntry."Qty. (Base)");
    end;

    procedure CalcQtyBase(): Decimal
    var
        WhseActivLine: Record "Warehouse Activity Line";
        WhseJnlLine: Record "Warehouse Journal Line";
    begin
        WhseActivLine.ReadIsolation(IsolationLevel::ReadUnCommitted);
        WhseActivLine.SetRange("Item No.", "Item No.");
        WhseActivLine.SetRange("Bin Code", "Bin Code");
        WhseActivLine.SetRange("Location Code", "Location Code");
        WhseActivLine.SetRange("Variant Code", "Variant Code");
        WhseActivLine.SetRange("Unit of Measure Code", "Unit of Measure Code");
        WhseActivLine.SetTrackingFilterFromBinContent(Rec);
        OnCalcQtyBaseOnAfterSetFiltersForWhseActivLine(WhseActivLine, Rec);
        WhseActivLine.CalcSums("Qty. Outstanding (Base)");

        WhseJnlLine.ReadIsolation(IsolationLevel::ReadUnCommitted);
        WhseJnlLine.SetRange("Item No.", "Item No.");
        WhseJnlLine.SetRange("From Bin Code", "Bin Code");
        WhseJnlLine.SetRange("Location Code", "Location Code");
        WhseJnlLine.SetRange("Variant Code", "Variant Code");
        WhseJnlLine.SetRange("Unit of Measure Code", "Unit of Measure Code");
        WhseJnlLine.SetTrackingFilterFromBinContent(Rec);
        OnCalcQtyBaseOnAfterSetFiltersForWhseJnlLine(WhseJnlLine, Rec);
        WhseJnlLine.CalcSums("Qty. (Absolute, Base)");

        if Rec.ReadIsolation() <> IsolationLevel::UpdLock then
            Rec.ReadIsolation(IsolationLevel::ReadCommitted);

        CalcFields("Quantity (Base)");
        exit(
          "Quantity (Base)" +
          WhseActivLine."Qty. Outstanding (Base)" +
          WhseJnlLine."Qty. (Absolute, Base)");
    end;

    procedure CalcQtyUOM() Result: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcQtyUOM(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if Rec.ReadIsolation() <> IsolationLevel::UpdLock then
            Rec.ReadIsolation(IsolationLevel::ReadCommitted);

        GetItem("Item No.");
        CalcFields("Quantity (Base)");
        if Item."No." <> '' then
            exit(
              Round("Quantity (Base)" / UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code"), UOMMgt.QtyRndPrecision()));
    end;

    procedure GetCaption(): Text
    var
        ObjTransl: Record "Object Translation";
        ReservEntry: Record "Reservation Entry";
        FormCaption: Text;
        "Filter": Text;
    begin
        FormCaption :=
          StrSubstNo(
            '%1 %2',
            ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, DATABASE::Location),
            "Location Code");

        case true of
            GetFieldFilter(GetFilter("Serial No. Filter"), Filter):
                GetPageCaption(FormCaption, FieldNo("Serial No. Filter"), Filter, -1, ReservEntry.FieldCaption("Serial No."));
            GetFieldFilter(GetFilter("Lot No. Filter"), Filter):
                GetPageCaption(FormCaption, FieldNo("Lot No. Filter"), Filter, -1, ReservEntry.FieldCaption("Lot No."));
            GetFieldFilter(GetFilter("Package No. Filter"), Filter):
                GetPageCaption(FormCaption, FieldNo("Package No. Filter"), Filter, -1, ReservEntry.FieldCaption("Package No."));
            GetFieldFilter(GetFilter("Bin Code"), Filter):
                GetPageCaption(FormCaption, FieldNo("Bin Code"), Filter, DATABASE::Bin, '');
            GetFieldFilter(GetFilter("Variant Code"), Filter):
                GetPageCaption(FormCaption, FieldNo("Variant Code"), Filter, DATABASE::"Item Variant", '');
            GetFieldFilter(GetFilter("Item No."), Filter):
                GetPageCaption(FormCaption, FieldNo("Item No."), Filter, DATABASE::Item, '');
        end;

        exit(FormCaption);
    end;

    procedure SetProposalMode(NewValue: Boolean)
    begin
        StockProposal := NewValue;
    end;

    local procedure GetFieldFilter(FieldFilter: Text; var "Filter": Text): Boolean
    begin
        Filter := FieldFilter;
        exit(StrLen(Filter) > 0);
    end;

    local procedure GetPageCaption(var PageCaption: Text; FieldNo: Integer; "Filter": Text; TableId: Integer; CustomDetails: Text)
    var
        ObjectTranslation: Record "Object Translation";
        FieldRef: FieldRef;
        RecRef: RecordRef;
        Value: Text;
    begin
        RecRef.GetTable(Rec);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.SetFilter(Filter);

        if RecRef.FindFirst() then
            Value := FieldRef.Value
        else
            Value := FieldRef.GetFilter();
        if TableId > 0 then
            CustomDetails := ObjectTranslation.TranslateObject(ObjectTranslation."Object Type"::Table, TableId);
        PageCaption := StrSubstNo('%1 %2 %3', PageCaption, CustomDetails, Value);
    end;

    procedure SetFilterOnUnitOfMeasure()
    begin
        GetLocation("Location Code");
        if Location."Directed Put-away and Pick" then
            SetRange("Unit of Measure Filter", "Unit of Measure Code")
        else
            SetRange("Unit of Measure Filter");
    end;

    procedure CalcTotalQtyBase(): Decimal
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.ReadIsolation(IsolationLevel::UpdLock);  // to prevent overcommitment
        WarehouseEntry.SetRange("Location Code", "Location Code");
        WarehouseEntry.SetRange("Bin Code", "Bin Code");
        WarehouseEntry.SetRange("Item No.", "Item No.");
        WarehouseEntry.SetRange("Variant Code", "Variant Code");
        WarehouseEntry.SetTrackingFilterFromBinContent(Rec);
        OnCalcTotalQtyBaseOnAfterSetFilters(WarehouseEntry, Rec);
        WarehouseEntry.CalcSums("Qty. (Base)");
        exit(WarehouseEntry."Qty. (Base)");
    end;

    local procedure CalcTotalNegativeAdjmtQtyBase() TotalNegativeAdjmtQtyBase: Decimal
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcTotalNegativeAdjmtQtyBase(Rec, TotalNegativeAdjmtQtyBase, IsHandled);
        WarehouseJournalLine.ReadIsolation(IsolationLevel::ReadUnCommitted);
        WhseItemTrackingLine.ReadIsolation(IsolationLevel::ReadUnCommitted);
        if not IsHandled then begin
            WarehouseJournalLine.SetRange("Location Code", "Location Code");
            WarehouseJournalLine.SetRange("From Bin Code", "Bin Code");
            WarehouseJournalLine.SetRange("Item No.", "Item No.");
            WarehouseJournalLine.SetRange("Variant Code", "Variant Code");
            OnCalcTotalNegativeAdjmtQtyBaseOnAfterSetFilters(WarehouseJournalLine, Rec);
            if not TrackingFiltersExist() then begin
                WarehouseJournalLine.CalcSums("Qty. (Absolute, Base)");
                TotalNegativeAdjmtQtyBase := WarehouseJournalLine."Qty. (Absolute, Base)";
            end else begin
                WhseItemTrackingLine.SetRange("Location Code", "Location Code");
                WhseItemTrackingLine.SetRange("Item No.", "Item No.");
                WhseItemTrackingLine.SetRange("Variant Code", "Variant Code");
                WhseItemTrackingLine.SetTrackingFilterFromBinContent(Rec);
                WhseItemTrackingLine.SetRange("Source Type", DATABASE::"Warehouse Journal Line");
                if WarehouseJournalLine.FindSet() then
                    repeat
                        WhseItemTrackingLine.SetRange("Source ID", WarehouseJournalLine."Journal Batch Name");
                        WhseItemTrackingLine.SetRange("Source Batch Name", WarehouseJournalLine."Journal Template Name");
                        WhseItemTrackingLine.SetRange("Source Ref. No.", WarehouseJournalLine."Line No.");
                        WhseItemTrackingLine.CalcSums("Quantity (Base)");
                        TotalNegativeAdjmtQtyBase += WhseItemTrackingLine."Quantity (Base)";
                    until WarehouseJournalLine.Next() = 0;
            end;
        end;
        OnAfterCalcTotalNegativeAdjmtQtyBase(Rec, WarehouseJournalLine, TotalNegativeAdjmtQtyBase);
    end;

    local procedure CalcTotalATOComponentsPickQtyBase(): Decimal
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        GetLocation("Location Code");
        WarehouseActivityLine.ReadIsolation(IsolationLevel::ReadUncommitted);
        WarehouseActivityLine.SetRange("Location Code", "Location Code");
        WarehouseActivityLine.SetRange("Bin Code", "Bin Code");
        WarehouseActivityLine.SetRange("Item No.", "Item No.");
        WarehouseActivityLine.SetRange("Variant Code", "Variant Code");
        if Location."Allow Breakbulk" then
            WarehouseActivityLine.SetRange("Unit of Measure Code", "Unit of Measure Code");
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::Pick);
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.SetRange("Assemble to Order", true);
        WarehouseActivityLine.SetRange("ATO Component", true);
        WarehouseActivityLine.SetTrackingFilterFromBinContent(Rec);
        OnCalcTotalATOComponentsPickQtyBaseOnAfterSetFilters(WarehouseActivityLine, Rec);
        WarehouseActivityLine.CalcSums("Qty. Outstanding (Base)");
        exit(WarehouseActivityLine."Qty. Outstanding (Base)");
    end;

    procedure GetBinContent(ItemNo: Code[20]; VariantCode: Code[10]; UOMCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20]; UseCrossDock: Boolean; UseRanking: Boolean; UseTracking: Boolean; WhseItemTrackingSetup: Record "Item Tracking Setup"): Boolean
    begin
        SetCurrentKey("Location Code", "Item No.", "Variant Code", "Cross-Dock Bin", "Qty. per Unit of Measure", "Bin Ranking");
        SetRange("Location Code", LocationCode);
        SetRange("Item No.", ItemNo);
        SetRange("Variant Code", VariantCode);
        SetRange("Cross-Dock Bin", UseCrossDock);
        SetRange("Unit of Measure Code", UOMCode);
        if UseRanking then begin
            GetBin(LocationCode, BinCode);
            SetFilter("Bin Ranking", '<%1', Bin."Bin Ranking");
        end;
        if UseTracking then
            SetTrackingFilterFromItemTrackingSetupIfRequiredWithBlank(WhseItemTrackingSetup);
        Ascending(false);
        OnAfterBinContentExists(Rec);
        exit(FindSet());
    end;

    procedure ClearTrackingFilters()
    begin
        SetRange("Serial No. Filter");
        SetRange("Lot No. Filter");

        OnAfterClearTrackingFilters(Rec);
    end;

    procedure SetTrackingFilterFromTrackingSpecification(TrackingSpecification: Record "Tracking Specification")
    begin
        SetRange("Serial No. Filter", TrackingSpecification."Serial No.");
        SetRange("Lot No. Filter", TrackingSpecification."Lot No.");

        OnAfterSetTrackingFilterFromTrackingSpecification(Rec, TrackingSpecification);
    end;

    procedure SetTrackingFilterFromWhseEntryIfNotBlank(WhseEntry: Record "Warehouse Entry")
    begin
        if WhseEntry."Serial No." <> '' then
            SetRange("Serial No. Filter", WhseEntry."Serial No.");
        if WhseEntry."Lot No." <> '' then
            SetRange("Lot No. Filter", WhseEntry."Lot No.");

        OnAfterSetTrackingFilterFromWhsEntryIfNotBlank(Rec, WhseEntry);
    end;

    procedure SetTrackingFilterFromWhseActivityLineIfNotBlank(WhseActivityLine: Record "Warehouse Activity Line")
    begin
        if WhseActivityLine."Serial No." <> '' then
            SetRange("Serial No. Filter", WhseActivityLine."Serial No.");
        if WhseActivityLine."Lot No." <> '' then
            SetRange("Lot No. Filter", WhseActivityLine."Lot No.");

        OnAfterSetTrackingFilterFromWhseActivityLineIfNotBlank(Rec, WhseActivityLine);
    end;

    procedure SetTrackingFilterFromWhseItemTrackingLine(WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        SetRange("Serial No. Filter", WhseItemTrackingLine."Serial No.");
        SetRange("Lot No. Filter", WhseItemTrackingLine."Lot No.");

        OnAfterSetTrackingFilterFromWhseItemTrackingLine(Rec, WhseItemTrackingLine);
    end;

    procedure SetTrackingFilterFromWhseItemTrackingSetup(WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        SetRange("Serial No. Filter", WhseItemTrackingSetup."Serial No.");
        SetRange("Lot No. Filter", WhseItemTrackingSetup."Lot No.");

        OnAfterSetTrackingFilterFromWhseItemTrackingSetup(Rec, WhseItemTrackingSetup);
    end;

    procedure SetTrackingFilterFromItemTrackingSetupIfNotBlank(WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Serial No." <> '' then
            SetRange("Serial No. Filter", WhseItemTrackingSetup."Serial No.");
        if WhseItemTrackingSetup."Lot No." <> '' then
            SetRange("Lot No. Filter", WhseItemTrackingSetup."Lot No.");

        OnAfterSetTrackingFilterFromItemTrackingSetupIfNotBlank(Rec, WhseItemTrackingSetup);
    end;

    procedure SetTrackingFilterFromItemTrackingSetupIfRequired(WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Serial No. Required" then
            SetRange("Serial No. Filter", WhseItemTrackingSetup."Serial No.");
        if WhseItemTrackingSetup."Lot No. Required" then
            SetRange("Lot No. Filter", WhseItemTrackingSetup."Lot No.");

        OnAfterSetTrackingFilterFromItemTrackingSetupIfRequired(Rec, WhseItemTrackingSetup);
    end;

    procedure SetTrackingFilterFromItemTrackingSetupIfNotBlankIfRequired(WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Serial No." <> '' then
            if WhseItemTrackingSetup."Serial No. Required" then
                SetRange("Serial No. Filter", WhseItemTrackingSetup."Serial No.");
        if WhseItemTrackingSetup."Lot No." <> '' then
            if WhseItemTrackingSetup."Lot No. Required" then
                SetRange("Lot No. Filter", WhseItemTrackingSetup."Lot No.");

        OnAfterSetTrackingFilterFromItemTrackingSetupIfNotBlankIfRequired(Rec, WhseItemTrackingSetup);
    end;

    procedure SetTrackingFilterFromItemTrackingSetupIfRequiredWithBlank(WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Serial No. Required" then
            SetRange("Serial No. Filter", WhseItemTrackingSetup."Serial No.")
        else
            SetFilter("Serial No. Filter", '%1|%2', WhseItemTrackingSetup."Serial No.", '');
        if WhseItemTrackingSetup."Lot No. Required" then
            SetRange("Lot No. Filter", WhseItemTrackingSetup."Lot No.")
        else
            SetFilter("Lot No. Filter", '%1|%2', WhseItemTrackingSetup."Lot No.", '');

        OnAfterSetTrackingFilterFromItemTrackingSetupIfRequiredWithBlank(Rec, WhseItemTrackingSetup);
    end;

    procedure SetTrackingFilterFromItemTrackingSetupIfWhseRequiredIfNotBlank(ItemTrackingSetup: Record "Item Tracking Setup");
    begin
        if ItemTrackingSetup."Serial No. Required" then
            if ItemTrackingSetup."Serial No." <> '' then
                SetRange("Serial No. Filter", ItemTrackingSetup."Serial No.");
        if ItemTrackingSetup."Lot No. Required" then
            if ItemTrackingSetup."Lot No." <> '' then
                SetRange("Lot No. Filter", ItemTrackingSetup."Lot No.");

        OnAfterSetTrackingFilterFromItemTrackingSetupIfWhseRequiredIfNotBlank(Rec, ItemTrackingSetup);
    end;

    procedure SetTrackingFilterFromBinContentBufferIfRequired(WhseItemTrackingSetup: Record "Item Tracking Setup"; BinContentBuffer: Record "Bin Content Buffer")
    begin
        if WhseItemTrackingSetup."Serial No. Required" then
            SetRange("Serial No. Filter", BinContentBuffer."Serial No.");
        if WhseItemTrackingSetup."Lot No. Required" then
            SetRange("Lot No. Filter", BinContentBuffer."Lot No.");

        OnAfterSetTrackingFilterFromBinContentBufferIfRequired(Rec, WhseItemTrackingSetup, BinContentBuffer);
    end;

    procedure TrackingFiltersExist() IsTrackingFiltersExist: Boolean
    begin
        IsTrackingFiltersExist := (GetFilter("Lot No. Filter") <> '') or (GetFilter("Serial No. Filter") <> '');
        OnAfterTrackingFiltersExist(Rec, IsTrackingFiltersExist);
    end;

    local procedure CalcWorksheetQty(): Decimal
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        WhseWorksheetLine.SetRange("Item No.", "Item No.");
        WhseWorksheetLine.SetRange("To Zone Code", "Zone Code");
        WhseWorksheetLine.SetRange("Location Code", "Location Code");
        WhseWorksheetLine.SetRange("Variant Code", "Variant Code");
        WhseWorksheetLine.SetRange("Unit of Measure Code", "Unit of Measure Code");
        WhseWorksheetLine.SetRange("To Bin Code", "Bin Code");
        WhseWorksheetLine.CalcSums("Qty. Outstanding (Base)");
        exit(WhseWorksheetLine."Qty. Outstanding (Base)");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterBinContentExists(var BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcQtyAvailToPickIncludingDedicated(BinContent: Record "Bin Content"; ExcludeQtyBase: Decimal; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcQtyAvailToTakeUOM(BinContent: Record "Bin Content"; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearTrackingFilters(var BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromWhseActivityLineIfNotBlank(var BinContent: Record "Bin Content"; WhseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromWhsEntryIfNotBlank(var BinContent: Record "Bin Content"; WarehouseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromWhseItemTrackingLine(var BinContent: Record "Bin Content"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromWhseItemTrackingSetup(var BinContent: Record "Bin Content"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemTrackingSetupIfNotBlank(var BinContent: Record "Bin Content"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemTrackingSetupIfRequired(var BinContent: Record "Bin Content"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemTrackingSetupIfNotBlankIfRequired(var BinContent: Record "Bin Content"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemTrackingSetupIfRequiredWithBlank(var BinContent: Record "Bin Content"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemTrackingSetupIfWhseRequiredIfNotBlank(var BinContent: Record "Bin Content"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromBinContentBufferIfRequired(var BinContent: Record "Bin Content"; WhseItemTrackingSetup: Record "Item Tracking Setup"; BinContentBuffer: Record "Bin Content Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromTrackingSpecification(var BinContent: Record "Bin Content"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTrackingFiltersExist(var BinContent: Record "Bin Content"; var IsTrackingFiltersExist: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var BinContent: Record "Bin Content"; Bin: Record Bin)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateBinCode(var BinContent: Record "Bin Content"; xBinContent: Record "Bin Content"; Bin: Record Bin)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcQtyAvailToPutAway(var BinContent: Record "Bin Content"; ExcludeQtyBase: Decimal; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcQtyToReplenish(var BinContent: Record "Bin Content"; ExcludeQtyBase: Decimal; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcTotalQtyAvailToTake(var BinContent: Record "Bin Content"; ExcludeQtyBase: Decimal; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcQtyUOM(var BinContent: Record "Bin Content"; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckManualChange(var BinContent: Record "Bin Content"; xBinContent: Record "Bin Content"; CaptionField: Text[80]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIncreaseBinContent(var BinContent: Record "Bin Content"; QtyBase: Decimal; DeductQtyBase: Decimal; DeductCubage: Decimal; DeductWeight: Decimal; PutawayCubage: Decimal; PutawayWeight: Decimal; CalledbyPosting: Boolean; IgnoreError: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDecreaseBinContent(Qty: Decimal; var QtyBase: Decimal; DecreaseQtyBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWhseClass(var BinContent: Record "Bin Content"; var Result: Boolean; var IsHandled: Boolean; IgnoreError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetWhseLocation(LocationCode: Code[10]; ZoneCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcQtyAvailToTake(var BinContent: Record "Bin Content"; ExcludeQtyBase: Decimal; var QtyAvailToTake: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcTotalNegativeAdjmtQtyBase(var BinContent: Record "Bin Content"; var TotalNegativeAdjmtQtyBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNeedToReplenish(var BinContent: Record "Bin Content"; ExcludeQtyBase: Decimal; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyBaseOnAfterSetFiltersForWhseActivLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcQtyBaseOnAfterSetFiltersForWhseJnlLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; var BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcTotalATOComponentsPickQtyBaseOnAfterSetFilters(var WarehouseActivityLine: Record "Warehouse Activity Line"; var BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcTotalNegativeAdjmtQtyBaseOnAfterSetFilters(var WarehouseJournalLine: Record "Warehouse Journal Line"; var BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcTotalQtyBaseOnAfterSetFilters(var WarehouseEntry: Record "Warehouse Entry"; var BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcTotalQtyAvailToTakeOnAfterCalcPickQuantityBase(BinContent: Record "Bin Content"; var ExcludeQtyBase: Decimal; var TotalNegativeAdjmtQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckDecreaseBinContentOnAfterCalcTotalQtyAvailToTake(var WarehouseActivityLine: Record "Warehouse Activity Line"; var QtyAvailToPickBase: Decimal; var DecreaseQtyBase: Decimal; var BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnAfterValidateUoMCode(var BinContent: Record "Bin Content"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnBeforeValidateVariantCode(var BinContent: Record "Bin Content"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBinMaxCubageAndWeight(var BinContent: Record "Bin Content"; var Bin: Record Bin; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcQtyWithBlockedItemTracking(var BinContent: Record "Bin Content"; var QtyWithBlockedItemTracking: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcQtyAvailToPick(BinContent: Record "Bin Content"; var Result: Decimal; var IsHandled: Boolean; ExcludeQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcTotalNegativeAdjmtQtyBase(var BinContent: Record "Bin Content"; var WarehouseJournalLine: Record "Warehouse Journal Line"; var TotalNegativeAdjmtQtyBase: Decimal)
    begin
    end;
}

