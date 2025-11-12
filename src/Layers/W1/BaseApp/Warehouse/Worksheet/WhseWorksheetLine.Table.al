// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Worksheet;

using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Availability;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;
using System.Reflection;
using System.Telemetry;

table 7326 "Whse. Worksheet Line"
{
    Caption = 'Whse. Worksheet Line';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Worksheet Template Name"; Code[10])
        {
            Caption = 'Worksheet Template Name';
            NotBlank = true;
            TableRelation = "Whse. Worksheet Template";
        }
        field(2; Name; Code[10])
        {
            Caption = 'Name';
            NotBlank = true;
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
            Editable = false;
        }
        field(4; "Source Type"; Integer)
        {
            Caption = 'Source Type';
            Editable = false;
        }
        field(5; "Source Subtype"; Option)
        {
            Caption = 'Source Subtype';
            Editable = false;
            OptionCaption = '0,1,2,3,4,5,6,7,8,9,10';
            OptionMembers = "0","1","2","3","4","5","6","7","8","9","10";
        }
        field(6; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            Editable = false;
        }
        field(7; "Source Line No."; Integer)
        {
            BlankZero = true;
            Caption = 'Source Line No.';
            Editable = false;
        }
        field(8; "Source Subline No."; Integer)
        {
            BlankZero = true;
            Caption = 'Source Subline No.';
            Editable = false;
        }
        field(9; "Source Document"; Enum "Warehouse Activity Source Document")
        {
            BlankZero = true;
            Caption = 'Source Document';
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
        field(12; "From Zone Code"; Code[10])
        {
            Caption = 'From Zone Code';
            TableRelation = Zone.Code where("Location Code" = field("Location Code"));

            trigger OnValidate()
            begin
                if "From Zone Code" <> xRec."From Zone Code" then
                    "From Bin Code" := '';
            end;
        }
        field(13; "From Bin Code"; Code[20])
        {
            Caption = 'From Bin Code';

            trigger OnLookup()
            begin
                LookupFromBinCode();
            end;

            trigger OnValidate()
            var
                WMSMgt: Codeunit "WMS Management";
            begin
                if "From Bin Code" <> '' then
                    WMSMgt.FindBinContent("Location Code", "From Bin Code", "Item No.", "Variant Code", "From Zone Code");

                if CurrFieldNo = FieldNo("From Bin Code") then
                    CheckBin("Location Code", "From Bin Code", false);

                if "From Bin Code" <> '' then begin
                    GetBin("Location Code", "From Bin Code");
                    "From Zone Code" := Bin."Zone Code";
                end;
            end;
        }
        field(14; "To Bin Code"; Code[20])
        {
            Caption = 'To Bin Code';
            TableRelation = if ("To Zone Code" = filter('')) Bin.Code where("Location Code" = field("Location Code"),
                                                                            Code = field("To Bin Code"))
            else
            if ("To Zone Code" = filter(<> '')) Bin.Code where("Location Code" = field("Location Code"),
                                                               "Zone Code" = field("To Zone Code"),
                                                               Code = field("To Bin Code"));

            trigger OnValidate()
            begin
                if CurrFieldNo = FieldNo("To Bin Code") then
                    CheckBin("Location Code", "To Bin Code", true);

                if "To Bin Code" <> '' then begin
                    GetBin("Location Code", "To Bin Code");
                    "To Zone Code" := Bin."Zone Code";
                end;
            end;
        }
        field(15; "To Zone Code"; Code[10])
        {
            Caption = 'To Zone Code';
            TableRelation = Zone.Code where("Location Code" = field("Location Code"));

            trigger OnValidate()
            begin
                if "To Zone Code" <> xRec."To Zone Code" then
                    "To Bin Code" := '';
            end;
        }
        field(16; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item where(Type = const(Inventory));

            trigger OnValidate()
            begin
                if "Item No." <> '' then begin
                    GetItemUnitOfMeasure();
                    Description := Item.Description;
                    Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
                end else begin
                    Description := '';
                    "Variant Code" := '';
                    Validate("Unit of Measure Code", '');
                end;
            end;
        }
        field(17; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                if Quantity < "Qty. Handled" then
                    FieldError(Quantity, StrSubstNo(Text010, "Qty. Handled"));

                if not IsProdOrder(Rec."Source Type") then
                    Validate("Qty. Outstanding", (Quantity - "Qty. Handled"))
                else
                    UpdateQtyHandledForProdOrderOutput();

                "Qty. (Base)" := CalcBaseQty(Quantity, FieldCaption(Quantity), FieldCaption("Qty. (Base)"));
            end;
        }
        field(18; "Qty. (Base)"; Decimal)
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
                "Qty. Outstanding (Base)" := CalcBaseQty("Qty. Outstanding", FieldCaption("Qty. Outstanding"), FieldCaption("Qty. Outstanding (Base)"));
                Validate("Qty. to Handle", "Qty. Outstanding");
            end;
        }
        field(20; "Qty. Outstanding (Base)"; Decimal)
        {
            Caption = 'Qty. Outstanding (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(21; "Qty. to Handle"; Decimal)
        {
            Caption = 'Qty. to Handle';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            var
                WhseWkshTemplate: Record "Whse. Worksheet Template";
                Confirmed: Boolean;
                AvailableQty: Decimal;
            begin
                if "Qty. to Handle" > "Qty. Outstanding" then
                    Error(
                      Text000,
                      "Qty. Outstanding");

                "Qty. to Handle (Base)" := CalcBaseQty("Qty. to Handle", FieldCaption("Qty. to Handle"), FieldCaption("Qty. to Handle (Base)"));
                if "Qty. to Handle (Base)" > 0 then begin
                    WhseWkshTemplate.Get("Worksheet Template Name");
                    if WhseWkshTemplate.Type = WhseWkshTemplate.Type::Pick then begin
                        Confirmed := true;
                        if (CurrFieldNo = FieldNo("Qty. to Handle")) and
                           ("Shipping Advice" = "Shipping Advice"::Complete) and
                           ("Qty. to Handle" <> "Qty. Outstanding")
                        then
                            Confirmed := Confirm(
                                Text001 +
                                Text002,
                                false,
                                FieldCaption("Shipping Advice"),
                                "Shipping Advice",
                                FieldCaption("Qty. to Handle"),
                                "Qty. Outstanding");

                        if not Confirmed then
                            Error(Text003);

                        UpdatePickQtyToHandleBase();
                    end else
                        if WhseWkshTemplate.Type = WhseWkshTemplate.Type::Movement then
                            if CurrFieldNo <> FieldNo("Qty. to Handle") then begin
                                AvailableQty := CheckAvailQtytoMove();
                                OnValidateQtyToHandleOnAfterCalcQtyAvailToMove(Rec, xRec, AvailableQty);
                                if AvailableQty < 0 then
                                    "Qty. to Handle (Base)" := 0
                                else
                                    if "Qty. to Handle (Base)" > AvailableQty then
                                        "Qty. to Handle (Base)" := AvailableQty;
                            end;

                    CheckBin("Location Code", "From Bin Code", false);
                    CheckBin("Location Code", "To Bin Code", true);
                end;

                TestField("Qty. per Unit of Measure");
                if "Qty. to Handle (Base)" = "Qty. Outstanding (Base)" then
                    "Qty. to Handle" := "Qty. Outstanding"
                else
                    "Qty. to Handle" := Round("Qty. to Handle (Base)" / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision()); // what about this???
            end;
        }
        field(22; "Qty. to Handle (Base)"; Decimal)
        {
            Caption = 'Qty. to Handle (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure", 1);
                Validate("Qty. to Handle", "Qty. to Handle (Base)");
            end;
        }
        field(23; "Qty. Handled"; Decimal)
        {
            Caption = 'Qty. Handled';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                "Qty. Handled (Base)" := CalcBaseQty("Qty. Handled", FieldCaption("Qty. Handled"), FieldCaption("Qty. Handled (Base)"));

                if not IsProdOrder(Rec."Source Type") then
                    Validate("Qty. Outstanding", Quantity - "Qty. Handled")
                else
                    UpdateQtyHandledForProdOrderOutput();
            end;
        }
        field(24; "Qty. Handled (Base)"; Decimal)
        {
            Caption = 'Qty. Handled (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                "Qty. Handled" := CalcQty("Qty. Handled (Base)");

                if not IsProdOrder(Rec."Source Type") then
                    Validate("Qty. Outstanding", Quantity - "Qty. Handled")
                else
                    UpdateQtyHandledForProdOrderOutput();
            end;
        }
        field(27; "From Unit of Measure Code"; Code[10])
        {
            Caption = 'From Unit of Measure Code';
            NotBlank = true;
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            var
                FromItemUnitOfMeasure: Record "Item Unit of Measure";
            begin
                if "Item No." <> '' then begin
                    GetItemUnitOfMeasure();
                    if not FromItemUnitOfMeasure.Get(Item."No.", "From Unit of Measure Code") then
                        FromItemUnitOfMeasure.Get(Item."No.", Item."Base Unit of Measure");
                    "Qty. per From Unit of Measure" := FromItemUnitOfMeasure."Qty. per Unit of Measure";
                end else
                    "Qty. per From Unit of Measure" := 1;
            end;
        }
        field(28; "Qty. per From Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per From Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
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
                    "Qty. per Unit of Measure" := ItemUnitOfMeasure."Qty. per Unit of Measure";
                    "Qty. Rounding Precision" := UOMMgt.GetQtyRoundingPrecision(Item, ItemUnitOfMeasure.Code);
                    "Qty. Rounding Precision (Base)" := UOMMgt.GetQtyRoundingPrecision(Item, Item."Base Unit of Measure");
                end else
                    "Qty. per Unit of Measure" := 1;

                "From Unit of Measure Code" := "Unit of Measure Code";
                "Qty. per From Unit of Measure" := "Qty. per Unit of Measure";
                ValidateQty();
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
                if "Variant Code" <> '' then begin
                    ItemVariant.Get("Item No.", "Variant Code");
                    Description := ItemVariant.Description;
                    "Description 2" := ItemVariant."Description 2";
                end else
                    GetItem("Item No.", Description);
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
        field(39; "Destination Type"; Enum "Warehouse Destination Type")
        {
            Caption = 'Destination Type';
            Editable = false;
        }
        field(40; "Destination No."; Code[20])
        {
            Caption = 'Destination No.';
            Editable = false;
            TableRelation = if ("Destination Type" = const(Customer)) Customer."No."
            else
            if ("Destination Type" = const(Vendor)) Vendor."No."
            else
            if ("Destination Type" = const(Location)) Location.Code;
        }
        field(41; "Shipping Agent Code"; Code[10])
        {
            AccessByPermission = TableData "Shipping Agent Services" = R;
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";
        }
        field(42; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent Code"));
        }
        field(43; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            TableRelation = "Shipment Method";
        }
        field(44; "Shipping Advice"; Enum "Sales Header Shipping Advice")
        {
            Caption = 'Shipping Advice';
            Editable = false;
        }
        field(45; "Shipment Date"; Date)
        {
            Caption = 'Shipment Date';
        }
        field(46; "Whse. Document Type"; Enum "Warehouse Worksheet Document Type")
        {
            Caption = 'Whse. Document Type';
            Editable = false;
        }
        field(47; "Whse. Document No."; Code[20])
        {
            Caption = 'Whse. Document No.';
            Editable = false;
            TableRelation = if ("Whse. Document Type" = const(Receipt)) "Posted Whse. Receipt Header"."No." where("No." = field("Whse. Document No."))
            else
            if ("Whse. Document Type" = const(Shipment)) "Warehouse Shipment Header"."No." where("No." = field("Whse. Document No."))
            else
            if ("Whse. Document Type" = const("Internal Put-away")) "Whse. Internal Put-away Header"."No." where("No." = field("Whse. Document No."))
            else
            if ("Whse. Document Type" = const("Internal Pick")) "Whse. Internal Pick Header"."No." where("No." = field("Whse. Document No."))
            else
            if ("Whse. Document Type" = const(Job)) Job."No." where("No." = field("Whse. Document No."));
        }
        field(48; "Whse. Document Line No."; Integer)
        {
            BlankZero = true;
            Caption = 'Whse. Document Line No.';
            Editable = false;
            TableRelation = if ("Whse. Document Type" = const(Receipt)) "Posted Whse. Receipt Line"."Line No." where("No." = field("Whse. Document No."),
                                                                                                                     "Line No." = field("Whse. Document Line No."))
            else
            if ("Whse. Document Type" = const(Shipment)) "Warehouse Shipment Line"."Line No." where("No." = field("Whse. Document No."),
                                                                                                    "Line No." = field("Whse. Document Line No."))
            else
            if ("Whse. Document Type" = const("Internal Put-away")) "Whse. Internal Put-away Line"."Line No." where("No." = field("Whse. Document No."),
                                                                                                                    "Line No." = field("Whse. Document Line No."))
            else
            if ("Whse. Document Type" = const("Internal Pick")) "Whse. Internal Pick Line"."Line No." where("No." = field("Whse. Document No."),
                                                                                                            "Line No." = field("Whse. Document Line No."))
            else
            if ("Whse. Document Type" = const(Job)) "Job Planning Line"."Job Contract Entry No." where("Job No." = field("Whse. Document No."),
                                                                                                       "Job Contract Entry No." = field("Whse. Document Line No."));
        }
        field(50; "Qty. Rounding Precision"; Decimal)
        {
            Caption = 'Qty. Rounding Precision';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(51; "Qty. Rounding Precision (Base)"; Decimal)
        {
            Caption = 'Qty. Rounding Precision (Base)';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Worksheet Template Name", Name, "Location Code", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Worksheet Template Name", Name, "Location Code", "Sorting Sequence No.")
        {
        }
        key(Key3; "Item No.", "Location Code", "Worksheet Template Name", "Variant Code", "Unit of Measure Code")
        {
            IncludedFields = "Qty. to Handle (Base)";
        }
        key(Key4; "Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.")
        {
        }
        key(Key5; "Worksheet Template Name", Name, "Location Code", "Item No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key6; "Worksheet Template Name", Name, "Location Code", "Due Date")
        {
            MaintainSQLIndex = false;
        }
        key(Key7; "Worksheet Template Name", Name, "Location Code", "Destination Type", "Destination No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key8; "Worksheet Template Name", Name, "Location Code", "Source Document", "Source No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key9; "Worksheet Template Name", Name, "Location Code", "To Bin Code")
        {
            MaintainSQLIndex = false;
        }
        key(Key10; "Worksheet Template Name", Name, "Location Code", "Shelf No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key11; "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.")
        {
        }
        key(Key12; "Item No.", "From Bin Code", "Location Code", "Variant Code", "From Unit of Measure Code")
        {
            IncludedFields = "Qty. to Handle", "Qty. to Handle (Base)";
        }
    }

    fieldgroups
    {
        fieldgroup(Brick; "Item No.", Description, Quantity, "Source No.", "Due Date")
        { }
    }

    trigger OnDelete()
    var
        WhseWkshTemplate: Record "Whse. Worksheet Template";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        WhseWkshTemplate.Get("Worksheet Template Name");
        if WhseWkshTemplate.Type = WhseWkshTemplate.Type::Movement then begin
            UpdateMovActivLines();
            ItemTrackingMgt.DeleteWhseItemTrkgLines(
              Database::"Whse. Worksheet Line", 0, Name, "Worksheet Template Name", 0, "Line No.", "Location Code", true);
        end;
    end;

    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
        Location: Record Location;
        Item: Record Item;
        Bin: Record Bin;
        BinType: Record "Bin Type";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        CreatePick: Codeunit "Create Pick";
        WhseAvailMgt: Codeunit "Warehouse Availability Mgt.";
        UOMMgt: Codeunit "Unit of Measure Management";
        LastLineNo: Integer;
        OpenFromBatch: Boolean;
        CurrentFieldNo: Integer;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You cannot handle more than the outstanding %1 units.';
        Text001: Label '%1 is set to %2. %3 should be %4.\\';
#pragma warning restore AA0470
        Text002: Label 'Accept the entered value?';
        Text003: Label 'The update was interrupted to respect the warning.';
#pragma warning disable AA0470
        Text004: Label 'You cannot handle more than the available %1 units.';
#pragma warning restore AA0470
        Text005: Label 'DEFAULT';
#pragma warning disable AA0470
        Text006: Label 'Default %1 Worksheet';
#pragma warning restore AA0470
#pragma warning restore AA0074
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text008: Label '%1 Worksheet';
        Text009: Label 'The location %1 of %2 %3 is not enabled for user %4.';
        Text010: Label 'must not be less than %1 units';
#pragma warning restore AA0470
        Text011: Label 'Quantity available to pick is not enough to fill in all the lines.';
#pragma warning restore AA0074

    protected var
        HideValidationDialog: Boolean;

    procedure CalcBaseQty(Qty: Decimal): Decimal
    begin
        TestField("Qty. per Unit of Measure");
        exit(UOMMgt.RoundQty(Qty * "Qty. per Unit of Measure", "Qty. Rounding Precision (Base)"));
    end;

    local procedure CalcBaseQty(Qty: Decimal; FromFieldName: Text; ToFieldName: Text): Decimal
    begin
        TestField("Qty. per Unit of Measure");
        exit(UOMMgt.CalcBaseQty(
            "Item No.", "Variant Code", "Unit of Measure Code", Qty, "Qty. per Unit of Measure", "Qty. Rounding Precision (Base)", FieldCaption("Qty. Rounding Precision"), FromFieldName, ToFieldName));
    end;

    procedure CalcQty(QtyBase: Decimal): Decimal
    begin
        TestField("Qty. per Unit of Measure");
        exit(Round(QtyBase / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision()));
    end;

    procedure AutofillQtyToHandle(var WhseWkshLine: Record "Whse. Worksheet Line")
    var
        NotEnough: Boolean;
    begin
        NotEnough := false;
        WhseWkshLine.SetHideValidationDialog(true);
        WhseWkshLine.LockTable();
        if WhseWkshLine.Find('-') then
            repeat
                if WhseWkshLine."Qty. to Handle" <> WhseWkshLine."Qty. Outstanding" then begin
                    WhseWkshLine.Validate(WhseWkshLine."Qty. to Handle", WhseWkshLine."Qty. Outstanding");
                    if WhseWkshLine."Qty. to Handle" <> xRec."Qty. to Handle" then begin
                        OnAutofillQtyToHandleOnbeforeModify(WhseWkshLine);
                        WhseWkshLine.Modify();
                        if not NotEnough then
                            if WhseWkshLine."Qty. to Handle" < WhseWkshLine."Qty. Outstanding" then
                                NotEnough := true;
                    end;
                end;
            until WhseWkshLine.Next() = 0;
        WhseWkshLine.SetHideValidationDialog(false);
        if NotEnough then
            Message(Text011);

        OnAfterAutofillQtyToHandle(WhseWkshLine);
    end;

    procedure DeleteQtyToHandle(var WhseWkshLine: Record "Whse. Worksheet Line")
    begin
        WhseWkshLine.LockTable();
        if WhseWkshLine.Find('-') then
            repeat
                WhseWkshLine.Validate(WhseWkshLine."Qty. to Handle", 0);
                WhseWkshLine.OnDeleteQtyToHandleOnBeforeModify(WhseWkshLine);
                WhseWkshLine.Modify();
            until WhseWkshLine.Next() = 0;
    end;

    procedure AssignedQtyOnReservedLines(): Decimal
    var
        WhseWkshLine: Record "Whse. Worksheet Line";
        TempWhseActivLine: Record "Warehouse Activity Line" temporary;
        LineReservedQtyBase: Decimal;
        TotalReservedAndAssignedBase: Decimal;
        ReservedAndAssignedBase: Decimal;
    begin
        WhseWkshLine.SetCurrentKey(
          "Item No.", "Location Code", "Worksheet Template Name", "Variant Code");
        WhseWkshLine.SetRange("Item No.", "Item No.");
        WhseWkshLine.SetRange("Location Code", "Location Code");
        WhseWkshLine.SetRange("Worksheet Template Name", "Worksheet Template Name");
        WhseWkshLine.SetRange("Variant Code", "Variant Code");
        OnAssignedQtyOnReservedLinesOnAfterWhseWkshLineSetFilters(Rec, WhseWkshLine);
        if WhseWkshLine.Find('-') then
            repeat
                if RecordId <> WhseWkshLine.RecordId then begin
                    LineReservedQtyBase :=
                      Abs(
                        WhseAvailMgt.CalcLineReservedQtyOnInvt(
                          WhseWkshLine."Source Type", WhseWkshLine."Source Subtype",
                          WhseWkshLine."Source No.", WhseWkshLine."Source Line No.",
                          WhseWkshLine."Source Subline No.",
                          true, TempWhseActivLine));
                    if LineReservedQtyBase > 0 then begin
                        if LineReservedQtyBase <= WhseWkshLine."Qty. to Handle (Base)" then
                            ReservedAndAssignedBase := LineReservedQtyBase
                        else
                            ReservedAndAssignedBase := WhseWkshLine."Qty. to Handle (Base)";
                        TotalReservedAndAssignedBase := TotalReservedAndAssignedBase + ReservedAndAssignedBase;
                    end;
                end;
            until WhseWkshLine.Next() = 0;
        exit(TotalReservedAndAssignedBase);
    end;

    procedure CalcAvailableQtyBase() AvailableQty: Decimal
    var
        DummyWhseItemTrackingLine: Record "Whse. Item Tracking Line";
        AvailQtyBase: Decimal;
        QtyAssgndOnWkshBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcAvailableQtyBase(Rec, AvailableQty, IsHandled);
        if IsHandled then
            exit(AvailableQty);

        GetItem("Item No.");
        GetLocation("Location Code");

        if Location."Directed Put-away and Pick" then begin
            QtyAssgndOnWkshBase := WhseAvailMgt.CalcQtyAssgndOnWksh(Rec, not Location."Allow Breakbulk", true);

            // Adjust the available quantity to pick with the QtyAssgndOnWkshBase and AssignedQtyOnReservedLines from the other active worksheet lines.
            AvailableQty := CreatePick.CalcTotalAvailQtyToPickForDirectedPutAwayPick("Location Code", "Item No.", "Variant Code", DummyWhseItemTrackingLine, "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.", "Qty. to Handle (Base)", QtyAssgndOnWkshBase, AssignedQtyOnReservedLines());

        end else begin
            QtyAssgndOnWkshBase := WhseAvailMgt.CalcQtyAssgndOnWksh(Rec, true, true);

            AvailQtyBase := WhseAvailMgt.CalcQtyAvailToTakeOnWhseWorksheetLine(Rec);

            AvailableQty := AvailQtyBase - QtyAssgndOnWkshBase + AssignedQtyOnReservedLines();
        end;
    end;

    procedure CalcReservedNotFromILEQty(QtyBaseAvailToPick: Decimal; var QtyToPick: Decimal; var QtyToPickBase: Decimal)
    begin
        CreatePick.CheckReservation(
            QtyBaseAvailToPick, "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.", false,
            "Qty. per Unit of Measure", QtyToPick, QtyToPickBase);
    end;

    procedure CheckAvailQtytoMove() AvailableQtyToMoveBase: Decimal
    begin
        AvailableQtyToMoveBase := CalcAvailQtyToMove() + xRec."Qty. to Handle (Base)";
        OnAfterCheckAvailQtytoMove(Rec, xRec, AvailableQtyToMoveBase);
    end;

    local procedure CalcAvailQtyToMove() QtyAvailToMoveBase: Decimal
    var
        BinContent: Record "Bin Content";
        WhseWkshLine: Record "Whse. Worksheet Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcAvailQtyToMove(Rec, QtyAvailToMoveBase, IsHandled);
        if IsHandled then
            exit(QtyAvailToMoveBase);

        if ("Location Code" <> '') and ("From Bin Code" <> '') and
           ("Item No." <> '') and ("From Unit of Measure Code" <> '')
        then begin
            GetLocation("Location Code");
            if BinContent.Get(
                 "Location Code", "From Bin Code", "Item No.", "Variant Code", "From Unit of Measure Code")
            then begin
                QtyAvailToMoveBase := BinContent.CalcQtyAvailToTake(0);
                WhseWkshLine.SetCurrentKey(
                  "Item No.", "From Bin Code", "Location Code", "Variant Code", "From Unit of Measure Code");
                WhseWkshLine.SetRange("Item No.", "Item No.");
                WhseWkshLine.SetRange("From Bin Code", "From Bin Code");
                WhseWkshLine.SetRange("Location Code", "Location Code");
                WhseWkshLine.SetRange("Variant Code", "Variant Code");
                WhseWkshLine.SetRange("From Unit of Measure Code", "From Unit of Measure Code");
                OnCalcAvailQtyToMoveOnAfterSetFilters(WhseWkshLine, Rec);
                WhseWkshLine.CalcSums("Qty. to Handle (Base)");
                QtyAvailToMoveBase := QtyAvailToMoveBase - WhseWkshLine."Qty. to Handle (Base)";
            end;
        end;
    end;

    local procedure UpdateQtyHandledForProdOrderOutput()
    begin
        OnUpdateQtyHandledForProdOrderOutput(Rec);
    end;

    local procedure IsProdOrder(SourceType: Integer): Boolean
    begin
        exit(SourceType = 5406); // Database::"Prod. Order Line"
    end;

    procedure SortWhseWkshLines(WhseWkshTemplate: Code[10]; WhseWkshName: Code[10]; LocationCode: Code[10]; SortingMethod: Enum "Whse. Activity Sorting Method")
    var
        WhseWkshLine: Record "Whse. Worksheet Line";
        SequenceNo: Integer;
    begin
        WhseWkshLine.SetRange("Worksheet Template Name", WhseWkshTemplate);
        WhseWkshLine.SetRange(Name, WhseWkshName);
        WhseWkshLine.SetRange("Location Code", LocationCode);
        case SortingMethod of
            SortingMethod::Item:
                WhseWkshLine.SetCurrentKey(
                  "Worksheet Template Name", Name, "Location Code", "Item No.");
            SortingMethod::Document:
                WhseWkshLine.SetCurrentKey(
                  "Worksheet Template Name", Name, "Location Code", "Source Document", "Source No.");
            SortingMethod::"Shelf or Bin":
                begin
                    GetLocation(LocationCode);
                    if Location."Bin Mandatory" then
                        WhseWkshLine.SetCurrentKey(
                          "Worksheet Template Name", Name, "Location Code", "To Bin Code", "Shelf No.")
                    else
                        WhseWkshLine.SetCurrentKey(
                          "Worksheet Template Name", Name, "Location Code", "Shelf No.");
                end;
            SortingMethod::"Due Date":
                WhseWkshLine.SetCurrentKey(
                  "Worksheet Template Name", Name, "Location Code", "Due Date");
            SortingMethod::"Ship-To":
                WhseWkshLine.SetCurrentKey(
                  "Worksheet Template Name", Name, "Location Code", "Destination Type", "Destination No.");
            else
                OnSortWhseWkshLinesOnCaseElse(WhseWkshLine, SortingMethod);
        end;

        if WhseWkshLine.Find('-') then begin
            SequenceNo := 10000;
            repeat
                WhseWkshLine."Sorting Sequence No." := SequenceNo;
                WhseWkshLine.Modify();
                SequenceNo := SequenceNo + 10000;
            until WhseWkshLine.Next() = 0;
        end;
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if Location.Code <> LocationCode then
            if LocationCode = '' then
                Location.GetLocationSetup(LocationCode, Location)
            else
                Location.Get(LocationCode);
    end;

    procedure GetItem(ItemNo: Code[20]; var ItemDescription: Text[100])
    begin
        if ItemNo = '' then
            ItemDescription := ''
        else
            if ItemNo <> Item."No." then begin
                ItemDescription := '';
                if Item.Get(ItemNo) then
                    ItemDescription := Item.Description;
            end else
                ItemDescription := Item.Description;

        OnAfterGetItem(Rec, Item, ItemDescription);
    end;

    local procedure GetItem(ItemNo: Code[20])
    var
        ItemDescription: Text[100];
    begin
        GetItem(ItemNo, ItemDescription);
    end;

    local procedure GetItemUnitOfMeasure()
    begin
        GetItem("Item No.", Description);
        if (Item."No." <> ItemUnitOfMeasure."Item No.") or
           ("Unit of Measure Code" <> ItemUnitOfMeasure.Code)
        then
            if not ItemUnitOfMeasure.Get(Item."No.", "Unit of Measure Code") then
                ItemUnitOfMeasure.Get(Item."No.", Item."Base Unit of Measure");
    end;

    local procedure GetBin(LocationCode: Code[10]; BinCode: Code[20])
    begin
        if (LocationCode = '') or (BinCode = '') then
            Clear(Bin)
        else
            if (Bin."Location Code" <> LocationCode) or
               (Bin.Code <> BinCode)
            then
                Bin.Get(LocationCode, BinCode);
    end;

    procedure CheckBin(LocationCode: Code[10]; BinCode: Code[20]; Inbound: Boolean)
    var
        WhseWkshTemplate: Record "Whse. Worksheet Template";
        BinContent: Record "Bin Content";
        WMSMgt: Codeunit "WMS Management";
        Cubage: Decimal;
        Weight: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBin(Rec, LocationCode, BinCode, Inbound, IsHandled);
        if IsHandled then
            exit;

        GetLocation(LocationCode);
        GetBin(LocationCode, BinCode);

        if Location."Directed Put-away and Pick" then begin
            Bin.CalcFields("Adjustment Bin");
            Bin.TestField("Adjustment Bin", false);
        end;
        if (BinCode <> '') and ("Item No." <> '') then begin
            if Location."Directed Put-away and Pick" then
                if Bin."Bin Type Code" <> '' then begin
                    WhseWkshTemplate.Get("Worksheet Template Name");
                    if WhseWkshTemplate.Type = WhseWkshTemplate.Type::Movement then begin
                        GetBinType(Bin."Bin Type Code");
                        BinType.TestField(Receive, false);
                    end;
                end;
            if Inbound then begin
                if Location."Bin Capacity Policy" <> Location."Bin Capacity Policy"::"Never Check Capacity" then begin
                    WMSMgt.CalcCubageAndWeight(
                      "Item No.", "Unit of Measure Code", "Qty. to Handle", Cubage, Weight);
                    CheckIncreaseBin(BinCode, Cubage, Weight);
                end else
                    if Location."Check Whse. Class" then
                        CheckWhseClass(BinCode);
            end else
                if Location."Directed Put-away and Pick" then begin
                    BinContent.Get("Location Code", BinCode, "Item No.", "Variant Code", "From Unit of Measure Code");
                    if BinContent."Block Movement" in [BinContent."Block Movement"::Outbound, BinContent."Block Movement"::All] then
                        BinContent.FieldError("Block Movement");
                end;
        end;
    end;

    local procedure CheckIncreaseBin(BinCode: Code[20]; Cubage: Decimal; Weight: Decimal)
    var
        BinContent: Record "Bin Content";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckIncreaseBin(Rec, Bin, BinCode, Cubage, Weight, IsHandled);
        if IsHandled then
            exit;

        if BinContent.Get(
             "Location Code", BinCode, "Item No.", "Variant Code", "Unit of Measure Code")
        then
            BinContent.CheckIncreaseBinContent(
              "Qty. to Handle (Base)", 0, 0, 0, Cubage, Weight, false, false)
        else
            Bin.CheckIncreaseBin(BinCode, "Item No.", "Qty. to Handle", 0, 0, Cubage, Weight, false, false);
    end;

    local procedure CheckWhseClass(BinCode: Code[20])
    var
        BinContent: Record "Bin Content";
    begin
        if BinContent.Get(
             "Location Code", BinCode, "Item No.", "Variant Code", "Unit of Measure Code")
        then
            BinContent.CheckWhseClass(false)
        else
            Bin.CheckWhseClass("Item No.", false);
    end;

    local procedure GetBinType(BinTypeCode: Code[10])
    begin
        if BinTypeCode = '' then begin
            Clear(BinType);
            BinType.Init();
        end else
            if BinType.Code <> BinTypeCode then
                BinType.Get(BinTypeCode);
    end;

    procedure PutAwayCreate(var WhsePutAwayWkshLine: Record "Whse. Worksheet Line")
    var
        CreatePutAwayFromWhseSource: Report "Whse.-Source - Create Document";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePutAwayCreate(WhsePutAwayWkshLine, IsHandled, HideValidationDialog);
        if IsHandled then
            exit;

        CreatePutAwayFromWhseSource.SetWhseWkshLine(WhsePutAwayWkshLine);
        CreatePutAwayFromWhseSource.RunModal();
        CreatePutAwayFromWhseSource.GetResultMessage(1);
        Clear(CreatePutAwayFromWhseSource);
    end;

    procedure MovementCreate(var WhseWkshLine: Record "Whse. Worksheet Line")
    var
        WhseSourceCreateDocument: Report "Whse.-Source - Create Document";
        CreateInventoryPickMovement: Codeunit "Create Inventory Pick/Movement";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMovementCreate(WhseWkshLine, IsHandled);
        if IsHandled then
            exit;

        if WhseWkshLine."Location Code" <> '' then begin
            GetLocation(WhseWkshLine."Location Code");
            if not Location."Directed Put-away and Pick" then begin
                FeatureTelemetry.LogUsage('0000JNP', 'Warehouse Movement', 'create movement document for basic warehouse');
                CreateInventoryPickMovement.SetHideDialogForTracking(true);
                CreateInventoryPickMovement.CreateInvtMvntWithoutSource(WhseWkshLine);
                exit;
            end;
        end;

        WhseSourceCreateDocument.SetWhseWkshLine(WhseWkshLine);
        WhseSourceCreateDocument.RunModal();
        WhseSourceCreateDocument.GetResultMessage(3);
        Clear(WhseSourceCreateDocument);
    end;

    local procedure ValidateQty()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateQty(Rec, IsHandled);
        if IsHandled then
            exit;

        Validate(Quantity);
    end;

    procedure TemplateSelection(PageID: Integer; PageTemplate: Option "Put-away",Pick,Movement; var WhseWkshLine: Record "Whse. Worksheet Line"; var WhseWkshSelected: Boolean)
    var
        WhseWkshTemplate: Record "Whse. Worksheet Template";
    begin
        WhseWkshSelected := true;

        WhseWkshTemplate.Reset();
        WhseWkshTemplate.SetRange("Page ID", PageID);
        WhseWkshTemplate.SetRange(Type, PageTemplate);

        case WhseWkshTemplate.Count of
            0:
                begin
                    WhseWkshTemplate.Init();
                    WhseWkshTemplate.Validate(Type, PageTemplate);
                    WhseWkshTemplate.Validate("Page ID");
                    WhseWkshTemplate.Name :=
                      Format(WhseWkshTemplate.Type, MaxStrLen(WhseWkshTemplate.Name));
                    WhseWkshTemplate.Description := StrSubstNo(Text008, WhseWkshTemplate.Type);
                    WhseWkshTemplate.Insert();
                    Commit();
                end;
            1:
                WhseWkshTemplate.FindFirst();
            else
                WhseWkshSelected := Page.RunModal(0, WhseWkshTemplate) = Action::LookupOK;
        end;
        if WhseWkshSelected then begin
            WhseWkshLine.FilterGroup := 2;
            WhseWkshLine.SetRange("Worksheet Template Name", WhseWkshTemplate.Name);
            WhseWkshLine.FilterGroup := 0;
            if OpenFromBatch then begin
                WhseWkshLine."Worksheet Template Name" := '';
                Page.Run(WhseWkshTemplate."Page ID", WhseWkshLine);
            end;
        end;
    end;

    procedure TemplateSelectionFromBatch(var WhseWkshName: Record "Whse. Worksheet Name")
    var
        WhseWkshLine: Record "Whse. Worksheet Line";
        WhseWkshTemplate: Record "Whse. Worksheet Template";
    begin
        OpenFromBatch := true;
        WhseWkshTemplate.Get(WhseWkshName."Worksheet Template Name");
        WhseWkshTemplate.TestField("Page ID");
        WhseWkshName.TestField(Name);

        WhseWkshLine.FilterGroup := 2;
        WhseWkshLine.SetRange("Worksheet Template Name", WhseWkshTemplate.Name);
        WhseWkshLine.FilterGroup := 0;

        WhseWkshLine."Worksheet Template Name" := '';
        WhseWkshLine.Name := WhseWkshName.Name;
        WhseWkshLine."Location Code" := WhseWkshName."Location Code";
        Page.Run(WhseWkshTemplate."Page ID", WhseWkshLine);
    end;

    procedure OpenWhseWksh(var WhseWkshLine: Record "Whse. Worksheet Line"; var CurrentWkshTemplateName: Code[10]; var CurrentWkshName: Code[10]; var CurrentLocationCode: Code[10])
    begin
        CurrentWkshTemplateName := WhseWkshLine.GetRangeMax("Worksheet Template Name");
        CheckTemplateName(CurrentWkshTemplateName, CurrentWkshName, CurrentLocationCode);
        WhseWkshLine.FilterGroup := 2;
        WhseWkshLine.SetRange(Name, CurrentWkshName);
        if CurrentLocationCode <> '' then
            WhseWkshLine.SetRange("Location Code", CurrentLocationCode);
        WhseWkshLine.FilterGroup := 0;
    end;

    procedure OpenWhseWkshBatch(var WhseWkshName: Record "Whse. Worksheet Name")
    var
        WhseWkshTemplate: Record "Whse. Worksheet Template";
        WhseWkshLine: Record "Whse. Worksheet Line";
        WmsMgt: Codeunit "WMS Management";
        JnlSelected: Boolean;
    begin
        if WhseWkshName.GetFilter("Worksheet Template Name") <> '' then
            exit;
        WhseWkshName.FilterGroup(2);
        if WhseWkshName.GetFilter("Worksheet Template Name") <> '' then begin
            WhseWkshName.FilterGroup(0);
            exit;
        end;
        WhseWkshName.FilterGroup(0);

        if not WhseWkshName.Find('-') then
            for WhseWkshTemplate.Type := WhseWkshTemplate.Type::"Put-away" to WhseWkshTemplate.Type::Movement do begin
                WhseWkshTemplate.SetRange(Type, WhseWkshTemplate.Type);
                if not WhseWkshTemplate.FindFirst() then
                    TemplateSelection(0, WhseWkshTemplate.Type.AsInteger(), WhseWkshLine, JnlSelected);
                if WhseWkshTemplate.FindFirst() then begin
                    if WhseWkshName."Location Code" = '' then
                        WhseWkshName."Location Code" := WmsMgt.GetDefaultLocation();
                    CheckTemplateName(WhseWkshTemplate.Name, WhseWkshName.Name, WhseWkshName."Location Code");
                end;
            end;

        WhseWkshName.Find('-');
        JnlSelected := true;
        WhseWkshName.CalcFields("Template Type");
        WhseWkshTemplate.SetRange(Type, WhseWkshName."Template Type");
        if WhseWkshName.GetFilter("Worksheet Template Name") <> '' then
            WhseWkshTemplate.SetRange(Name, WhseWkshName.GetFilter("Worksheet Template Name"));
        case WhseWkshTemplate.Count of
            1:
                WhseWkshTemplate.FindFirst();
            else
                JnlSelected := Page.RunModal(0, WhseWkshTemplate) = Action::LookupOK;
        end;
        if not JnlSelected then
            Error('');

        WhseWkshName.FilterGroup(0);
        WhseWkshName.SetRange("Worksheet Template Name", WhseWkshTemplate.Name);
        WhseWkshName.FilterGroup(2);
    end;

    local procedure CheckTemplateName(CurrentWkshTemplateName: Code[10]; var CurrentWkshName: Code[10]; var CurrentLocationCode: Code[10])
    var
        WhseWkshTemplate: Record "Whse. Worksheet Template";
        WhseWkshName: Record "Whse. Worksheet Name";
        WhseEmployee: Record "Warehouse Employee";
        WmsMgt: Codeunit "WMS Management";
        FoundLocation: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckTemplateName(CurrentWkshTemplateName, CurrentWkshName, CurrentLocationCode, IsHandled);
        if IsHandled then
            exit;

        WhseWkshTemplate.Get(CurrentWkshTemplateName);
        WhseWkshName.SetRange("Worksheet Template Name", CurrentWkshTemplateName);
        if not WhseWkshName.Get(CurrentWkshTemplateName, CurrentWkshName, CurrentLocationCode) or
           ((UserId <> '') and not WhseEmployee.Get(UserId, CurrentLocationCode))
        then begin
            if UserId <> '' then begin
                CurrentLocationCode := WmsMgt.GetDefaultLocation();
                WhseWkshName.SetRange("Location Code", CurrentLocationCode);
            end;
            if not WhseWkshName.FindFirst() then begin
                if UserId <> '' then begin
                    WhseEmployee.SetCurrentKey(Default);
                    WhseEmployee.SetRange(Default, false);
                    WhseEmployee.SetRange("User ID", UserId);
                    if WhseEmployee.Find('-') then
                        repeat
                            WhseWkshName.SetRange("Location Code", WhseEmployee."Location Code");
                            FoundLocation := WhseWkshName.FindFirst();
                        until (WhseEmployee.Next() = 0) or FoundLocation;
                end;
                if not FoundLocation then begin
                    WhseWkshName.Init();
                    WhseWkshName."Worksheet Template Name" := CurrentWkshTemplateName;
                    WhseWkshName.SetupNewName();
                    WhseWkshName.Name := Text005;
                    WhseWkshName.Description :=
                      StrSubstNo(Text006, WhseWkshTemplate.Type);
                    WhseWkshName.Insert(true);
                end;
                CurrentLocationCode := WhseWkshName."Location Code";
                Commit();
            end;
            CurrentWkshName := WhseWkshName.Name;
            CurrentLocationCode := WhseWkshName."Location Code";
        end;
    end;

    procedure CheckWhseWkshName(CurrentWkshName: Code[10]; CurrentLocationCode: Code[10]; var WhseWkshLine: Record "Whse. Worksheet Line")
    var
        WhseWkshName: Record "Whse. Worksheet Name";
        WhseEmployee: Record "Warehouse Employee";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWhseWkshName(CurrentWkshName, CurrentLocationCode, IsHandled);
        if IsHandled then
            exit;

        WhseWkshName.Get(
          WhseWkshLine.GetRangeMax("Worksheet Template Name"), CurrentWkshName, CurrentLocationCode);
        if (UserId <> '') and not WhseEmployee.Get(UserId, CurrentLocationCode) then
            Error(Text009, CurrentLocationCode, WhseWkshName.TableCaption(), CurrentWkshName, UserId);
    end;

    procedure SetWhseWkshName(CurrentWkshName: Code[10]; CurrentLocationCode: Code[10]; var WhseWkshLine: Record "Whse. Worksheet Line")
    begin
        WhseWkshLine.FilterGroup := 2;
        WhseWkshLine.SetRange(Name, CurrentWkshName);
        WhseWkshLine.SetRange("Location Code", CurrentLocationCode);
        WhseWkshLine.FilterGroup := 0;
        if WhseWkshLine.Find('-') then;
    end;

    procedure LookupWhseWkshName(var WhseWkshLine: Record "Whse. Worksheet Line"; var CurrentWkshName: Code[10]; var CurrentLocationCode: Code[10])
    var
        WhseWkshName: Record "Whse. Worksheet Name";
    begin
        Commit();
        WhseWkshName."Worksheet Template Name" := WhseWkshLine.GetRangeMax("Worksheet Template Name");
        WhseWkshName.Name := WhseWkshLine.GetRangeMax(Name);
        WhseWkshName.FilterGroup(2);
        WhseWkshName.SetRange("Worksheet Template Name", WhseWkshName."Worksheet Template Name");
        WhseWkshName.FilterGroup(0);
        OnLookupWhseWkshNameOnBeforeRunModal(WhseWkshName);
        if Page.RunModal(0, WhseWkshName) = Action::LookupOK then begin
            CurrentWkshName := WhseWkshName.Name;
            CurrentLocationCode := WhseWkshName."Location Code";
            SetWhseWkshName(CurrentWkshName, WhseWkshName."Location Code", WhseWkshLine);
        end;
    end;

    local procedure UpdatePickQtyToHandleBase()
    var
        TypeHelper: Codeunit "Type Helper";
        AvailableQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdatePickQtyToHandleBase(Rec, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        GetLocation("Location Code");
        if Location."Bin Mandatory" then begin
            if CurrFieldNo <> FieldNo("Qty. to Handle") then
                if not Location."Always Create Pick Line" then begin
                    AvailableQty := CalcAvailableQtyBase();
                    if "Qty. to Handle (Base)" > AvailableQty then
                        if ("Shipping Advice" = "Shipping Advice"::Complete) then
                            "Qty. to Handle (Base)" := 0
                        else
                            "Qty. to Handle (Base)" := TypeHelper.Maximum(0, AvailableQty);
                end
        end else begin
            AvailableQty := CalcAvailableQtyBase();
            if "Qty. to Handle (Base)" > AvailableQty then begin
                if ("Shipping Advice" = "Shipping Advice"::Complete) or
                   (AvailableQty < 0)
                then
                    "Qty. to Handle (Base)" := 0
                else
                    "Qty. to Handle (Base)" := AvailableQty;

                if (not HideValidationDialog) and (CurrFieldNo = FieldNo("Qty. to Handle")) then
                    Error(
                      Text004,
                      AvailableQty);
            end;
        end;
    end;

    local procedure UpdateMovActivLines()
    var
        WhseActivLine: Record "Warehouse Activity Line";
        WhseActivLine2: Record "Warehouse Activity Line";
    begin
        WhseActivLine.SetCurrentKey(
          "Whse. Document No.", "Whse. Document Type", "Activity Type", "Whse. Document Line No.");
        WhseActivLine.SetRange("Whse. Document No.", Name);
        WhseActivLine.SetRange("Whse. Document Type", WhseActivLine."Whse. Document Type"::"Movement Worksheet");
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Movement);
        WhseActivLine.SetRange("Whse. Document Line No.", "Line No.");
        WhseActivLine.SetRange("Source Type", Database::"Whse. Worksheet Line");
        WhseActivLine.SetRange("Source No.", "Worksheet Template Name");
        WhseActivLine.SetRange("Location Code", "Location Code");
        if WhseActivLine.Find('-') then
            repeat
                WhseActivLine2.Copy(WhseActivLine);
                WhseActivLine2."Source Type" := 0;
                WhseActivLine2."Source No." := '';
                WhseActivLine2."Source Line No." := 0;
                WhseActivLine2.Modify();
            until WhseActivLine.Next() = 0;
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;

    procedure OpenItemTrackingLines()
    var
        WhseItemTrackingLines: Page "Whse. Item Tracking Lines";
    begin
        OnBeforeOpenItemTrackingLines(Rec);

        TestField("Item No.");
        TestField("Qty. (Base)");

        WhseItemTrackingLinesSetSource(WhseItemTrackingLines);
        WhseItemTrackingLines.RunModal();
    end;

    local procedure WhseItemTrackingLinesSetSource(var WhseItemTrackingLines: Page "Whse. Item Tracking Lines")
    var
        IsHandled: Boolean;
    begin
        case "Whse. Document Type" of
            "Whse. Document Type"::Receipt:
                WhseItemTrackingLines.SetSource(Rec, Database::"Posted Whse. Receipt Line");
            "Whse. Document Type"::Shipment:
                WhseItemTrackingLines.SetSource(Rec, Database::"Warehouse Shipment Line");
            "Whse. Document Type"::"Internal Put-away":
                WhseItemTrackingLines.SetSource(Rec, Database::"Whse. Internal Put-away Line");
            "Whse. Document Type"::"Internal Pick":
                WhseItemTrackingLines.SetSource(Rec, Database::"Whse. Internal Pick Line");
            else begin
                IsHandled := false;
                OnWhseItemTrackingLinesSetSource(Rec, WhseItemTrackingLines, IsHandled);
                if not IsHandled then
                    WhseItemTrackingLines.SetSource(Rec, Database::"Whse. Worksheet Line");
            end;
        end;
    end;

    procedure AvailableQtyToPick(): Decimal
    begin
        if "Qty. per Unit of Measure" <> 0 then
            exit(Round(CalcAvailableQtyBase() / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision()));
        exit(0);
    end;

    internal procedure AvailableQtyToPickForCurrentLine(): Decimal
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        exit(TypeHelper.Minimum(Rec."Qty. (Base)", AvailableQtyToPick()));
    end;

    procedure InitNewLineWithItem(DocumentType: Enum "Warehouse Worksheet Document Type"; DocumentNo: Code[20];
                                                    DocumentLineNo: Integer;
                                                    LocationCode: Code[10];
                                                    ItemNo: Code[20];
                                                    VariantCode: Code[10];
                                                    Qty: Decimal;
                                                    QtyToHandle: Decimal;
                                                    QtyPerUoM: Decimal)
    begin
        Init();
        "Whse. Document Type" := DocumentType;
        "Whse. Document No." := DocumentNo;
        "Whse. Document Line No." := DocumentLineNo;
        "Location Code" := LocationCode;
        "Item No." := ItemNo;
        "Variant Code" := VariantCode;
        "Qty. (Base)" := Qty;
        "Qty. to Handle (Base)" := QtyToHandle;
        "Qty. per Unit of Measure" := QtyPerUoM;
        OnAfterInitLineWithItem();
    end;

    procedure SetUpNewLine(WhseWkshTemplate: Code[10]; WhseWkshName: Code[10]; LocationCode: Code[10]; SortingMethod: Enum "Whse. Activity Sorting Method"; LineNo: Integer)
    begin
        WhseWorksheetLine.Reset();
        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWkshTemplate);
        WhseWorksheetLine.SetRange(Name, WhseWkshName);
        WhseWorksheetLine.SetRange("Location Code", LocationCode);
        if WhseWorksheetLine.Count = 0 then
            LastLineNo := 0
        else
            LastLineNo := LineNo;

        "Worksheet Template Name" := WhseWkshTemplate;
        Name := WhseWkshName;
        "Location Code" := LocationCode;
        "Line No." := GetNextLineNo(SortingMethod);
        "Whse. Document Type" := "Whse. Document Type"::"Whse. Mov.-Worksheet";
        "Whse. Document No." := WhseWkshName;
        "Whse. Document Line No." := "Line No.";
    end;

    local procedure GetNextLineNo(SortMethod: Enum "Whse. Activity Sorting Method"): Integer
    var
        WhseWorksheetLine2: Record "Whse. Worksheet Line";
        HigherLineNo: Integer;
        LowerLineNo: Integer;
    begin
        WhseWorksheetLine2.Copy(WhseWorksheetLine);
        if SortMethod <> SortMethod::None then
            exit(GetLastLineNo() + 10000);

        WhseWorksheetLine2 := Rec;
        WhseWorksheetLine2."Line No." := LastLineNo;
        if WhseWorksheetLine2.Find('<') then
            LowerLineNo := WhseWorksheetLine2."Line No."
        else
            if WhseWorksheetLine2.Find('>') then
                exit(LastLineNo div 2)
            else
                exit(LastLineNo + 10000);

        WhseWorksheetLine2 := Rec;
        WhseWorksheetLine2."Line No." := LastLineNo;
        if WhseWorksheetLine2.Find('>') then
            HigherLineNo := LastLineNo
        else
            exit(LastLineNo + 10000);
        exit(LowerLineNo + (HigherLineNo - LowerLineNo) div 2);
    end;

    local procedure GetLastLineNo(): Integer
    var
        WhseWorksheetLine2: Record "Whse. Worksheet Line";
    begin
        WhseWorksheetLine2.CopyFilters(WhseWorksheetLine);
        if WhseWorksheetLine2.FindLast() then
            exit(WhseWorksheetLine2."Line No.");
        exit(0);
    end;

    procedure GetSortSeqNo(SortMethod: Enum "Whse. Activity Sorting Method"): Integer
    var
        WhseWorksheetLine2: Record "Whse. Worksheet Line";
        HigherSeqNo: Integer;
        LowerSeqNo: Integer;
        LastSeqNo: Integer;
    begin
        WhseWorksheetLine2 := Rec;
        WhseWorksheetLine2.SetRecFilter();
        WhseWorksheetLine2.SetRange("Line No.");

        case SortMethod of
            SortMethod::None:
                WhseWorksheetLine2.SetCurrentKey(
                  "Worksheet Template Name", Name, "Location Code", "Line No.");
            SortMethod::Item:
                WhseWorksheetLine2.SetCurrentKey(
                  "Worksheet Template Name", Name, "Location Code", "Item No.");
            SortMethod::Document:
                WhseWorksheetLine2.SetCurrentKey(
                  "Worksheet Template Name", Name, "Location Code", "Source Document", "Source No.");
            SortMethod::"Shelf or Bin":
                begin
                    GetLocation("Location Code");
                    if Location."Bin Mandatory" then
                        WhseWorksheetLine2.SetCurrentKey(
                          "Worksheet Template Name", Name, "Location Code", "To Bin Code")
                    else
                        WhseWorksheetLine2.SetCurrentKey(
                          "Worksheet Template Name", Name, "Location Code", "Shelf No.");
                end;
            SortMethod::"Due Date":
                WhseWorksheetLine2.SetCurrentKey(
                  "Worksheet Template Name", Name, "Location Code", "Due Date");
            SortMethod::"Ship-To":
                WhseWorksheetLine2.SetCurrentKey(
                  "Worksheet Template Name", Name, "Location Code", "Destination Type", "Destination No.")
            else
                OnGetSortSeqNoOnCaseElse(WhseWorksheetLine2, SortMethod);
        end;

        LastSeqNo := GetLastSeqNo(WhseWorksheetLine2);
        if WhseWorksheetLine2.Find('<') then
            LowerSeqNo := WhseWorksheetLine2."Sorting Sequence No."
        else
            if WhseWorksheetLine2.Find('>') then
                exit(WhseWorksheetLine2."Sorting Sequence No." div 2)
            else
                LowerSeqNo := 10000;

        WhseWorksheetLine2 := Rec;
        if WhseWorksheetLine2.Find('>') then
            HigherSeqNo := WhseWorksheetLine2."Sorting Sequence No."
        else
            if WhseWorksheetLine2.Find('<') then
                exit(LastSeqNo + 10000)
            else
                HigherSeqNo := LastSeqNo;
        exit(LowerSeqNo + (HigherSeqNo - LowerSeqNo) div 2);
    end;

    local procedure GetLastSeqNo(WhseWorksheetLine2: Record "Whse. Worksheet Line"): Integer
    begin
        WhseWorksheetLine2.SetRecFilter();
        WhseWorksheetLine2.SetRange("Line No.");
        WhseWorksheetLine2.SetCurrentKey("Worksheet Template Name", Name, "Location Code", "Sorting Sequence No.");
        if WhseWorksheetLine2.FindLast() then
            exit(WhseWorksheetLine2."Sorting Sequence No.");
        exit(0);
    end;

    procedure SetItemTrackingLines(WhseEntry: Record "Warehouse Entry"; QtyToEmpty: Decimal)
    var
        WhseItemTrackingLines: Page "Whse. Item Tracking Lines";
    begin
        TestField("Item No.");
        TestField("Qty. (Base)");

        Clear(WhseItemTrackingLines);
        WhseItemTrackingLinesSetSource(WhseItemTrackingLines);
        WhseItemTrackingLines.InsertItemTrackingLine(Rec, WhseEntry, QtyToEmpty);
    end;

    procedure SetCurrentFieldNo(FieldNo: Integer)
    begin
        if CurrentFieldNo <> CurrFieldNo then
            CurrentFieldNo := FieldNo;
    end;

    procedure SetSourceFilter(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SetKey: Boolean)
    begin
        if SetKey then
            SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.");
        SetRange("Source Type", SourceType);
        if SourceSubType >= 0 then
            SetRange("Source Subtype", SourceSubType);
        SetRange("Source No.", SourceNo);
        if SourceLineNo >= 0 then
            SetRange("Source Line No.", SourceLineNo);

        OnAfterSetSourceFilter(Rec, SourceType, SourceSubtype, SourceNo, SourceLineNo, SetKey);
    end;

    local procedure LookupFromBinCode()
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        WMSMgt: Codeunit "WMS Management";
        BinCode: Code[20];
    begin
        LookupItemTracking(WhseItemTrackingSetup);
        BinCode :=
          WMSMgt.BinContentLookUp("Location Code", "Item No.", "Variant Code", "From Zone Code", WhseItemTrackingSetup, "From Bin Code");
        if BinCode <> '' then
            Validate("From Bin Code", BinCode);
    end;

    procedure LookupItemTracking(var WhseItemTrackingSetup: Record "Item Tracking Setup")
    var
        WhseItemTrkgLine: Record "Whse. Item Tracking Line";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        if ItemTrackingMgt.WhseItemTrackingLineExists(
            "Worksheet Template Name", Name, "Location Code", "Line No.", WhseItemTrkgLine)
        then
            // Don't step in if more than one Tracking Definition exists:
            if WhseItemTrkgLine.Count = 1 then begin
                WhseItemTrkgLine.FindFirst();
                if WhseItemTrkgLine."Quantity (Base)" = "Qty. (Base)" then
                    WhseItemTrackingSetup.CopyTrackingFromWhseItemTrackingLine(WhseItemTrkgLine);
            end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAutofillQtyToHandle(var WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInitLineWithItem()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckAvailQtytoMove(var WhseWorksheetLine: Record "Whse. Worksheet Line"; xWhseWorksheetLine: Record "Whse. Worksheet Line"; var QtyAvailToMoveBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetItem(var WhseWorksheetLine: Record "Whse. Worksheet Line"; var Item: Record Item; var ItemDescription: Text[100])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAssignedQtyOnReservedLinesOnAfterWhseWkshLineSetFilters(var WhseWorksheetLine: Record "Whse. Worksheet Line"; var FilteredWhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAutofillQtyToHandleOnBeforeModify(var WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcAvailQtyToMove(var WhseWorksheetLine: Record "Whse. Worksheet Line"; var QtyAvailToMoveBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBin(WhseWorksheetLine: Record "Whse. Worksheet Line"; LocationCode: Code[10]; BinCode: Code[20]; Inbound: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIncreaseBin(var WhseWorksheetLine: Record "Whse. Worksheet Line"; var Bin: Record Bin; BinCode: Code[20]; Cubage: Decimal; Weight: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckTemplateName(var WkshTemplateName: Code[10]; var WkshName: Code[10]; var LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWhseWkshName(var WkshTemplateName: Code[10]; var LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMovementCreate(var WhseWkshLine: Record "Whse. Worksheet Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenItemTrackingLines(var WhseWkshLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePutAwayCreate(var PutAwayWhseWorksheetLine: Record "Whse. Worksheet Line"; var IsHandled: Boolean; HideValidationDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdatePickQtyToHandleBase(var WhseWorksheetLine: Record "Whse. Worksheet Line"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQty(var PutAwayWhseWorksheetLine: Record "Whse. Worksheet Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAvailQtyToMoveOnAfterSetFilters(var NewWhseWorksheetLine: Record "Whse. Worksheet Line"; var WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcAvailableQtyBase(var WhseWorksheetLine: Record "Whse. Worksheet Line"; var AvailableQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnDeleteQtyToHandleOnBeforeModify(var WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookupWhseWkshNameOnBeforeRunModal(var WhseWkshName: Record "Whse. Worksheet Name")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSortSeqNoOnCaseElse(var WhseWorksheetLine: Record "Whse. Worksheet Line"; SortMethod: Enum "Whse. Activity Sorting Method")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSortWhseWkshLinesOnCaseElse(var WhseWorksheetLine: Record "Whse. Worksheet Line"; SortingMethod: Enum "Whse. Activity Sorting Method")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQtyToHandleOnAfterCalcQtyAvailToMove(var WhseWorksheetLine: Record "Whse. Worksheet Line"; xWhseWorksheetLine: Record "Whse. Worksheet Line"; var QtyAvailToMoveBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSourceFilter(var WhseWorksheetLine: Record "Whse. Worksheet Line"; SourceType: Integer; SourceSubtype: Option; SourceNo: Code[20]; SourceLineNo: Integer; SetKey: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWhseItemTrackingLinesSetSource(var WhseWorksheetLine: Record "Whse. Worksheet Line"; var WhseItemTrackingLines: Page "Whse. Item Tracking Lines"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateQtyHandledForProdOrderOutput(var WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
    end;
}

