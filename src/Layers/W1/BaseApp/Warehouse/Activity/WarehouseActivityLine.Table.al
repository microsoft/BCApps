// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Assembly.Document;
using Microsoft.Foundation.Shipping;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Activity.History;
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
using Microsoft.Warehouse.Worksheet;
using System.Environment.Configuration;
using System.Utilities;

table 5767 "Warehouse Activity Line"
{
    Caption = 'Warehouse Activity Line';
    DrillDownPageID = "Warehouse Activity Lines";
    LookupPageID = "Warehouse Activity Lines";
    Permissions = TableData "Whse. Item Tracking Line" = rmd;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Activity Type"; Enum "Warehouse Activity Type")
        {
            Caption = 'Activity Type';
            Editable = false;
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            Editable = false;
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
        field(11; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            Editable = false;
            TableRelation = Location;
        }
        field(12; "Shelf No."; Code[10])
        {
            Caption = 'Shelf No.';
        }
        field(13; "Sorting Sequence No."; Integer)
        {
            Caption = 'Sorting Sequence No.';
            Editable = false;
        }
        field(14; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            Editable = false;
            TableRelation = Item;

            trigger OnValidate()
            begin
                if "Item No." <> xRec."Item No." then
                    "Variant Code" := '';

                if "Item No." <> '' then begin
                    GetItemUnitOfMeasure();
                    Description := Item.Description;
                    "Description 2" := Item."Description 2";
                    Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
                    OnValidateItemNoOnAfterValidateUoMCode(Rec, Item, CurrFieldNo);
                end else begin
                    Description := '';
                    "Description 2" := '';
                    "Variant Code" := '';
                    Validate("Unit of Measure Code", '');
                end;
            end;
        }
        field(15; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            Editable = false;
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            var
                ItemVariant: Record "Item Variant";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateVariantCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                if Rec."Variant Code" = '' then
                    Validate("Item No.")
                else begin
                    ItemVariant.Get("Item No.", "Variant Code");
                    IsHandled := false;
                    OnValidateVariantCodeOnAfterGetItemVariant(Rec, ItemVariant, IsHandled);
                    if not IsHandled then begin
                        Description := ItemVariant.Description;
                        "Description 2" := ItemVariant."Description 2";
                    end;
                end;
            end;
        }
        field(16; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            Editable = false;
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            begin
                if "Item No." <> '' then begin
                    GetItemUnitOfMeasure();
                    "Qty. per Unit of Measure" := ItemUnitOfMeasure."Qty. per Unit of Measure";
                    "Qty. Rounding Precision" := UOMMgt.GetQtyRoundingPrecision(Item, "Unit of Measure Code");
                    "Qty. Rounding Precision (Base)" := UOMMgt.GetQtyRoundingPrecision(Item, Item."Base Unit of Measure");
                end else
                    "Qty. per Unit of Measure" := 1;

                Validate(Quantity);
                Validate("Qty. Outstanding");
                Validate("Qty. to Handle");
            end;
        }
        field(17; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            InitValue = 1;
        }
        field(18; Description; Text[100])
        {
            Caption = 'Description';
            Editable = false;
        }
        field(19; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
            Editable = false;
        }
        field(20; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                QuantityNotRounded: Decimal;
            begin
                QuantityNotRounded := Quantity;
                Quantity := UOMMgt.RoundAndValidateQty(Quantity, "Qty. Rounding Precision", FieldCaption(Quantity));
                "Qty. (Base)" := CalcBaseQty(QuantityNotRounded, FieldCaption(Quantity), FieldCaption("Qty. (Base)"));
                Validate("Qty. Outstanding", (QuantityNotRounded - "Qty. Handled"));

                UpdateQtyOnRelatedPlaceLine(Rec, xRec);
            end;
        }
        field(21; "Qty. (Base)"; Decimal)
        {
            Caption = 'Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQtyBase(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestField("Qty. per Unit of Measure", 1);
                Validate(Quantity, "Qty. (Base)");
            end;
        }
        field(24; "Qty. Outstanding"; Decimal)
        {
            Caption = 'Qty. Outstanding';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            var
                QuantityNotRounded: Decimal;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQtyOutstanding(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;
                QuantityNotRounded := "Qty. Outstanding";
                "Qty. Outstanding" := UOMMgt.RoundAndValidateQty("Qty. Outstanding", "Qty. Rounding Precision", FieldCaption("Qty. Outstanding"));
                "Qty. Outstanding (Base)" :=
                    CalcBaseQty(QuantityNotRounded, FieldCaption("Qty. Outstanding"), FieldCaption("Qty. Outstanding (Base)"));
                Validate("Qty. to Handle", QuantityNotRounded);
            end;
        }
        field(25; "Qty. Outstanding (Base)"; Decimal)
        {
            Caption = 'Qty. Outstanding (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                TestField("Qty. per Unit of Measure", 1);
                Validate("Qty. Outstanding", "Qty. Outstanding (Base)");
            end;
        }
        field(26; "Qty. to Handle"; Decimal)
        {
            Caption = 'Qty. to Handle';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            var
                BinContent: Record "Bin Content";
                QtyToHandleBase: Decimal;
                QuantityNotRounded, QuantityRounded : Decimal;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQtyToHandle(Rec, IsHandled);
                if not IsHandled then begin
                    QuantityRounded := UOMMgt.RoundAndValidateQty("Qty. to Handle", "Qty. Rounding Precision", FieldCaption("Qty. to Handle"));
                    if QuantityRounded > "Qty. Outstanding" then
                        Error(Text002, "Qty. Outstanding");
                end;

                GetLocation("Location Code");
                if Location."Bin Capacity Policy" <> Location."Bin Capacity Policy"::"Never Check Capacity" then
                    WMSMgt.CalcCubageAndWeight(
                      "Item No.", "Unit of Measure Code", "Qty. to Handle", Cubage, Weight);

                if (CurrFieldNo <> 0) and
                   ("Action Type" = "Action Type"::Place) and
                   ("Breakbulk No." = 0) and
                   ("Qty. to Handle" > 0)
                then
                    if GetBin("Location Code", "Bin Code") then
                        if Location."Bin Capacity Policy" <> Location."Bin Capacity Policy"::"Never Check Capacity" then
                            CheckIncreaseCapacity(true)
                        else
                            if ("Item No." <> '') and Location."Check Whse. Class" then
                                if BinContent.Get("Location Code", "Bin Code", "Item No.", "Variant Code", "Unit of Measure Code") then
                                    BinContent.CheckWhseClass(false)
                                else
                                    Bin.CheckWhseClass("Item No.", false);

                OnValidateQtyToHandleOnBeforeCalcQtyToHandleBase(Rec, xRec, Location, CurrFieldNo);

                if not UseBaseQty then begin
                    QuantityNotRounded := "Qty. to Handle";
                    "Qty. to Handle" :=
                        UOMMgt.RoundAndValidateQty("Qty. to Handle", "Qty. Rounding Precision", FieldCaption("Qty. to Handle"));
                    "Qty. to Handle (Base)" :=
                        CalcBaseQty(QuantityNotRounded, FieldCaption("Qty. to Handle"), FieldCaption("Qty. to Handle (Base)"));

                    if (("Qty. to Handle" = "Qty. Outstanding") and ("Qty. to Handle (Base)" < "Qty. Outstanding (Base)")) then // Rounding fix (Round Down)- Qty same, not Base Qty
                        "Qty. to Handle (Base)" := "Qty. Outstanding (Base)";

                    if "Qty. to Handle (Base)" > "Qty. Outstanding (Base)" then begin // Rounding fix (Round Up)- Qty same, not Base Qty
                        QtyToHandleBase := "Qty. Outstanding (Base)";
                        OnValidateQtyToHandleOnAfterCalcQtyToHandleBase(Rec, "Qty. To Handle (Base)", QtyToHandleBase);
                        "Qty. to Handle (Base)" := QtyToHandleBase;
                    end;
                    ValidateQuantityIsBalanced();
                end;

                if ("Activity Type" = "Activity Type"::"Put-away") and
                   ("Action Type" = "Action Type"::Take) and
                   (CurrFieldNo <> 0)
                then
                    if ("Breakbulk No." <> 0) or "Original Breakbulk" then
                        UpdateBreakbulkQtytoHandle();

                if ("Activity Type" in ["Activity Type"::Pick, "Activity Type"::"Invt. Pick"]) and
                   ("Action Type" <> "Action Type"::Place) and ("Lot No." <> '') and (CurrFieldNo <> 0)
                then
                    CheckReservedItemTrkg(ItemTrackingType::"Lot No.", "Lot No.");
            end;
        }
        field(27; "Qty. to Handle (Base)"; Decimal)
        {
            Caption = 'Qty. to Handle (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                UseBaseQty := true;
                Validate("Qty. to Handle", CalcQty("Qty. to Handle (Base)"));
            end;
        }
        field(28; "Qty. Handled"; Decimal)
        {
            Caption = 'Qty. Handled';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                "Qty. Handled" := UOMMgt.RoundAndValidateQty("Qty. Handled", "Qty. Rounding Precision", FieldCaption("Qty. Handled"));
                "Qty. Handled (Base)" :=
                    CalcBaseQty("Qty. Handled", FieldCaption("Qty. Handled"), FieldCaption("Qty. Handled (Base)"));
            end;
        }
        field(29; "Qty. Handled (Base)"; Decimal)
        {
            Caption = 'Qty. Handled (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(31; "Shipping Advice"; Enum "Sales Header Shipping Advice")
        {
            Caption = 'Shipping Advice';
            Editable = false;
            FieldClass = Normal;
        }
        field(34; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(39; "Destination Type"; enum "Warehouse Destination Type")
        {
            Caption = 'Destination Type';
            Editable = false;
        }
        field(40; "Destination No."; Code[20])
        {
            Caption = 'Destination No.';
            Editable = false;
            TableRelation = if ("Destination Type" = const(Vendor)) Vendor
            else
            if ("Destination Type" = const(Customer)) Customer
            else
            if ("Destination Type" = const(Location)) Location
            else
            if ("Destination Type" = const(Item)) Item
            else
            if ("Destination Type" = const("Sales Order")) "Sales Header"."No." where("Document Type" = const(Order));
        }
        field(42; "Shipping Agent Code"; Code[10])
        {
            Caption = 'Shipping Agent Code';
            TableRelation = "Shipping Agent";
        }
        field(43; "Shipping Agent Service Code"; Code[10])
        {
            Caption = 'Shipping Agent Service Code';
            TableRelation = "Shipping Agent Services".Code where("Shipping Agent Code" = field("Shipping Agent Code"));
        }
        field(44; "Shipment Method Code"; Code[10])
        {
            Caption = 'Shipment Method Code';
            TableRelation = "Shipment Method";
        }
        field(47; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
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
        field(900; "Assemble to Order"; Boolean)
        {
            AccessByPermission = TableData "BOM Component" = R;
            Caption = 'Assemble to Order';
            Editable = false;
        }
        field(901; "ATO Component"; Boolean)
        {
            Caption = 'ATO Component';
            Editable = false;
        }
        field(6500; "Serial No."; Code[50])
        {
            Caption = 'Serial No.';
            ExtendedDatatype = Barcode;

            trigger OnLookup()
            begin
                LookUpTrackingSummary(Rec, ShouldLookUpBinContent(), -1, ItemTrackingType::"Serial No.");
            end;

            trigger OnValidate()
            var
                WhseItemTrackingSetup: Record "Item Tracking Setup";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateSerialNo(Rec, IsHandled);
                if IsHandled then
                    exit;
                if "Serial No." <> '' then begin
                    ItemTrackingMgt.CheckWhseItemTrkgSetup("Item No.");
                    TestField("Qty. (Base)", 1);

                    if "Activity Type" in ["Activity Type"::Pick, "Activity Type"::"Invt. Pick"] then
                        CheckReservedItemTrkg(ItemTrackingType::"Serial No.", "Serial No.");

                    CheckSNSpecificationExists();

                    ItemTrackingMgt.GetWhseItemTrkgSetup("Item No.", WhseItemTrackingSetup);
                    if WhseItemTrackingSetup."Serial No. Required" then
                        FindLotAndPackageNoBySerialNo(WhseItemTrackingSetup);
                end;

                if "Serial No." <> xRec."Serial No." then
                    "Expiration Date" := 0D;

                if CurrFieldNo = FieldNo("Serial No.") then
                    CopyItemTrackingToRelatedLine(xRec, FieldNo("Serial No."));
            end;
        }
        field(6501; "Lot No."; Code[50])
        {
            Caption = 'Lot No.';
            ExtendedDatatype = Barcode;

            trigger OnLookup()
            begin
                LookUpTrackingSummary(Rec, ShouldLookUpBinContent(), -1, ItemTrackingType::"Lot No.");
            end;

            trigger OnValidate()
            begin
                OnBeforeValidateLotNo(Rec);
                if "Lot No." <> '' then begin
                    ItemTrackingMgt.CheckWhseItemTrkgSetup("Item No.");

                    if "Activity Type" in ["Activity Type"::Pick, "Activity Type"::"Invt. Pick"] then
                        CheckReservedItemTrkg(ItemTrackingType::"Lot No.", "Lot No.");
                end;

                if "Lot No." <> xRec."Lot No." then
                    "Expiration Date" := 0D;

                if CurrFieldNo = FieldNo("Lot No.") then
                    CopyItemTrackingToRelatedLine(xRec, FieldNo("Lot No."));
            end;
        }
        field(6502; "Warranty Date"; Date)
        {
            Caption = 'Warranty Date';
        }
        field(6503; "Expiration Date"; Date)
        {
            Caption = 'Expiration Date';

            trigger OnValidate()
            var
                WarehouseActivityLine: Record "Warehouse Activity Line";
            begin
                if (Rec."Lot No." <> '') and (Rec."Expiration Date" <> 0D) then begin
                    WarehouseActivityLine.SetCurrentKey("No.", "Line No.", "Activity Type");
                    WarehouseActivityLine.SetRange("No.", Rec."No.");
                    WarehouseActivityLine.SetRange("Item No.", Rec."Item No.");
                    WarehouseActivityLine.SetRange("Lot No.", Rec."Lot No.");
                    WarehouseActivityLine.SetFilter("Line No.", '<>%1', Rec."Line No.");
                    WarehouseActivityLine.SetFilter("Expiration Date", '<>%1&<>%2', 0D, Rec."Expiration Date");
                    if not WarehouseActivityLine.IsEmpty() then
                        Rec.FieldError("Expiration Date");
                end;
            end;
        }
        field(6504; "Serial No. Blocked"; Boolean)
        {
            CalcFormula = lookup("Serial No. Information".Blocked where("Item No." = field("Item No."),
                                                                        "Variant Code" = field("Variant Code"),
                                                                        "Serial No." = field("Serial No.")));
            Caption = 'Serial No. Blocked';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6505; "Lot No. Blocked"; Boolean)
        {
            CalcFormula = lookup("Lot No. Information".Blocked where("Item No." = field("Item No."),
                                                                     "Variant Code" = field("Variant Code"),
                                                                     "Lot No." = field("Lot No.")));
            Caption = 'Lot No. Blocked';
            Editable = false;
            FieldClass = FlowField;
        }
        field(6515; "Package No."; Code[50])
        {
            Caption = 'Package No.';
            CaptionClass = '6,1';
            ExtendedDatatype = Barcode;

            trigger OnLookup()
            begin
                LookUpTrackingSummary(Rec, ShouldLookUpBinContent(), -1, Enum::"Item Tracking Type"::"Package No.");
            end;

            trigger OnValidate()
            begin
                if "Package No." <> '' then begin
                    ItemTrackingMgt.CheckWhseItemTrkgSetup("Item No.");

                    if "Activity Type" in ["Activity Type"::Pick, "Activity Type"::"Invt. Pick"] then
                        CheckReservedItemTrkg(Enum::"Item Tracking Type"::"Package No.", "Package No.");
                end;

                if CurrFieldNo = FieldNo("Package No.") then
                    CopyItemTrackingToRelatedLine(xRec, FieldNo("Package No."));
            end;
        }
        field(7300; "Bin Code"; Code[20])
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'Bin Code';
            TableRelation = if ("Zone Code" = filter('')) Bin.Code where("Location Code" = field("Location Code"))
            else
            if ("Zone Code" = filter(<> '')) Bin.Code where("Location Code" = field("Location Code"),
                                                            "Zone Code" = field("Zone Code"));

            trigger OnLookup()
            var
                BinCode: Code[20];
            begin
                BinCode := FindBinCode();

                if BinCode <> '' then begin
                    Validate("Bin Code", BinCode);
                    Modify();
                end;
            end;

            trigger OnValidate()
            var
                BinContent: Record "Bin Content";
                BinType: Record "Bin Type";
                WhseItemTrackingLine: Record "Whse. Item Tracking Line";
                QtyAvailBase: Decimal;
                AvailableQtyBase: Decimal;
                UOMCode: Code[10];
                NewBinCode: Code[20];
                IsHandled: Boolean;
            begin
                CheckBinInSourceDoc();

                if "Bin Code" <> '' then
                    FindBinContent();

                if "Bin Code" <> xRec."Bin Code" then begin
                    CheckInvalidBinCode();
                    IsHandled := false;
                    OnValidateBinCodeOnAfterCheckInvalidBinCode(Rec, xRec, CurrFieldNo, IsHandled);
                    if IsHandled then
                        exit;
                    if GetBin("Location Code", "Bin Code") then begin
                        if CurrFieldNo <> 0 then begin
                            if ("Activity Type" = "Activity Type"::"Put-away") and
                               ("Breakbulk No." <> 0)
                            then
                                Error(Text005, FieldCaption("Bin Code"));
                            CheckWhseDocLine();
                            if "Action Type" = "Action Type"::Take then begin
                                if (("Whse. Document Type" <> "Whse. Document Type"::Receipt) and
                                    (Bin."Bin Type Code" <> ''))
                                then
                                    if BinType.Get(Bin."Bin Type Code") then
                                        BinType.TestField(Receive, false);
                                GetLocation("Location Code");
                                UOMCode := GetUOMCode();
                                NewBinCode := "Bin Code";
                                if BinContent.Get("Location Code", "Bin Code", "Item No.", "Variant Code", UOMCode) then begin
                                    if "Activity Type" in ["Activity Type"::Pick, "Activity Type"::"Invt. Pick", "Activity Type"::"Invt. Movement"] then
                                        QtyAvailBase := BinContent.CalcQtyAvailToPick(0)
                                    else
                                        QtyAvailBase := BinContent.CalcQtyAvailToTake(0);
                                    if Location."Directed Put-away and Pick" then begin
                                        CreatePick.SetCrossDock(Bin."Cross-Dock Bin");
                                        WhseItemTrackingLine.CopyTrackingFromWhseActivityLine(Rec);
                                        AvailableQtyBase :=
                                          CreatePick.CalcTotalAvailQtyToPick(
                                            "Location Code", "Item No.", "Variant Code", WhseItemTrackingLine,
                                            "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.", 0, false);
                                        AvailableQtyBase += "Qty. Outstanding (Base)";
                                        if AvailableQtyBase < 0 then
                                            AvailableQtyBase := 0;

                                        if AvailableQtyBase = 0 then
                                            Error(Text015);
                                    end else
                                        AvailableQtyBase := QtyAvailBase;

                                    if AvailableQtyBase < QtyAvailBase then
                                        QtyAvailBase := AvailableQtyBase;

                                    OnValidateBinCodeOnAfterCalcQtyAvailBase(Rec, QtyAvailBase, NewBinCode);
                                end;

                                CheckExceedQtyAvailBase(BinContent, QtyAvailBase, NewBinCode);
                            end else begin
                                if "Qty. to Handle" > 0 then
                                    CheckIncreaseCapacity(false);
                                xRec.DeleteBinContent(Enum::"Warehouse Action Type"::Place.AsInteger());
                            end;
                        end;

                        if "Action Type" = "Action Type"::Place then
                            if (("Whse. Document Type" = "Whse. Document Type"::Receipt) and (Bin."Bin Type Code" <> '')) then
                                if BinType.Get(Bin."Bin Type Code") then
                                    if BinType.Receive then
                                        BinType.TestField(Receive, false);

                        Dedicated := Bin.Dedicated;
                        "Bin Ranking" := Bin."Bin Ranking";
                        "Zone Code" := Bin."Zone Code";
                        if Location."Directed Put-away and Pick" then
                            "Bin Type Code" := Bin."Bin Type Code";

                        UpdateSpecialEquipment();
                        OnValidateBinCodeOnAfterGetBin(Rec, Bin);
                    end else begin
                        xRec.DeleteBinContent(xRec."Action Type"::Place.AsInteger());
                        Dedicated := false;
                        "Bin Ranking" := 0;
                        "Bin Type Code" := '';
                    end;
                end;
            end;
        }
        field(7301; "Zone Code"; Code[10])
        {
            Caption = 'Zone Code';
            TableRelation = Zone.Code where("Location Code" = field("Location Code"));

            trigger OnValidate()
            begin
                if xRec."Zone Code" <> "Zone Code" then begin
                    GetLocation("Location Code");
                    xRec.DeleteBinContent(xRec."Action Type"::Place.AsInteger());
                    "Bin Code" := '';
                    "Bin Ranking" := 0;
                    "Bin Type Code" := '';
                end;
            end;
        }
        field(7305; "Action Type"; Enum "Warehouse Action Type")
        {
            Caption = 'Action Type';
            Editable = false;
        }
        field(7306; "Whse. Document Type"; Enum "Warehouse Activity Document Type")
        {
            Caption = 'Whse. Document Type';
            Editable = false;
        }
        field(7307; "Whse. Document No."; Code[20])
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
            if ("Whse. Document Type" = const(Assembly)) "Assembly Header"."No." where("Document Type" = const(Order),
                                                                                       "No." = field("Whse. Document No."))
            else
            if ("Whse. Document Type" = const(Job)) "Job"."No." where("No." = field("Whse. Document No."));
        }
        field(7308; "Whse. Document Line No."; Integer)
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
            if ("Whse. Document Type" = const(Assembly)) "Assembly Line"."Line No." where("Document Type" = const(Order),
                                                                                          "Document No." = field("Whse. Document No."),
                                                                                          "Line No." = field("Whse. Document Line No."))
            else
            if ("Whse. Document Type" = const(Job)) "Job Planning Line"."Job Contract Entry No." where("Job No." = field("Whse. Document No."),
                                                                                                       "Job Contract Entry No." = field("Whse. Document Line No."));
        }
        field(7309; "Bin Ranking"; Integer)
        {
            Caption = 'Bin Ranking';
            Editable = false;
        }
        field(7310; Cubage; Decimal)
        {
            Caption = 'Cubage';
            DecimalPlaces = 0 : 5;
        }
        field(7311; Weight; Decimal)
        {
            Caption = 'Weight';
            DecimalPlaces = 0 : 5;
        }
        field(7312; "Special Equipment Code"; Code[10])
        {
            Caption = 'Special Equipment Code';
            TableRelation = "Special Equipment";
        }
        field(7313; "Bin Type Code"; Code[10])
        {
            Caption = 'Bin Type Code';
            TableRelation = "Bin Type";
        }
        field(7314; "Breakbulk No."; Integer)
        {
            BlankZero = true;
            Caption = 'Breakbulk No.';
        }
        field(7315; "Original Breakbulk"; Boolean)
        {
            Caption = 'Original Breakbulk';
        }
        field(7316; Breakbulk; Boolean)
        {
            Caption = 'Breakbulk';
        }
        field(7317; "Cross-Dock Information"; Option)
        {
            Caption = 'Cross-Dock Information';
            OptionCaption = ' ,Cross-Dock Items,Some Items Cross-Docked';
            OptionMembers = " ","Cross-Dock Items","Some Items Cross-Docked";
        }
        field(7318; Dedicated; Boolean)
        {
            Caption = 'Dedicated';
            Editable = false;
        }
        field(7319; "Over-Receipt Quantity"; Decimal)
        {
            Caption = 'Over-Receipt Quantity';
            DecimalPlaces = 0 : 5;
            BlankZero = false;
            MinValue = 0;

            trigger OnValidate()
            var
                PurchaseLine: Record "Purchase Line";
                OverReceiptMgt: Codeunit "Over-Receipt Mgt.";
            begin
                if not OverReceiptMgt.IsOverReceiptAllowed() then begin
                    "Over-Receipt Quantity" := 0;
                    exit;
                end;

                TestField("Source Document", "Source Document"::"Purchase Order");

                if xRec."Over-Receipt Quantity" = "Over-Receipt Quantity" then
                    exit;

                if "Over-Receipt Quantity" <> 0 then begin
                    if "Over-Receipt Code" = '' then begin
                        PurchaseLine.Get("Source Subtype", "Source No.", "Source Line No.");
                        "Over-Receipt Code" := OverReceiptMgt.GetDefaultOverReceiptCode(PurchaseLine);
                    end;
                    TestField("Over-Receipt Code");
                end;

                Validate(Quantity, Quantity - xRec."Over-Receipt Quantity" + "Over-Receipt Quantity");
                Modify();

                OverReceiptMgt.UpdatePurchaseLineOverReceiptQuantityFromWarehouseActivityLine(Rec, CurrFieldNo);
            end;
        }
        field(7320; "Over-Receipt Code"; Code[20])
        {
            Caption = 'Over-Receipt Code';
            TableRelation = "Over-Receipt Code";

            trigger OnValidate()
            begin
                if ((Rec."Over-Receipt Code" = '') and (xRec."Over-Receipt Code" <> '')) then
                    Validate("Over-Receipt Quantity", 0);
            end;
        }
        field(7321; "Warehouse Reason Code"; Code[10])
        {
            Caption = 'Warehouse Reason Code';
            TableRelation = "Warehouse Reason Code";
        }
    }
    keys
    {
        key(Key1; "Activity Type", "No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "No.", "Line No.", "Activity Type")
        {
        }
        key(Key3; "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.", "Unit of Measure Code", "Action Type", "Breakbulk No.", "Original Breakbulk", "Activity Type", "Assemble to Order")
        {
            IncludedFields = "Qty. Outstanding", "Qty. Outstanding (Base)";
        }
        key(Key4; "Activity Type", "No.", "Sorting Sequence No.")
        {
            IncludedFields = "Shelf No.";
        }
#pragma warning disable AS0009
        key(Key14; "Whse. Document No.", "Whse. Document Type", "Activity Type", "Whse. Document Line No.", "Action Type", "Unit of Measure Code", "Original Breakbulk", "Breakbulk No.", "Lot No.", "Serial No.", "Assemble to Order", "Package No.")
#pragma warning restore AS0009
        {
            IncludedFields = "Qty. Outstanding (Base)", "Qty. Outstanding";
        }
        key(Key15; "Item No.", "Bin Code", "Location Code", "Action Type", "Variant Code", "Unit of Measure Code", "Breakbulk No.", "Activity Type", "Lot No.", "Serial No.", "Original Breakbulk", "Assemble to Order", "ATO Component")
        {
            IncludedFields = Quantity, "Qty. (Base)", "Qty. Outstanding", "Qty. Outstanding (Base)", Cubage, Weight;
        }
#pragma warning disable AS0009
        key(Key16; "Item No.", "Location Code", "Activity Type", "Bin Type Code", "Unit of Measure Code", "Variant Code", "Breakbulk No.", "Action Type", "Lot No.", "Serial No.", "Assemble to Order", "Package No.")
#pragma warning restore AS0009
        {
            IncludedFields = "Qty. Outstanding (Base)";
        }
        key(Key17; "Bin Code", "Location Code", "Action Type", "Breakbulk No.")
        {
            IncludedFields = Cubage, Weight;
        }
        key(Key18; "Location Code", "Activity Type")
        {
        }
        key(Key19; "Source No.", "Source Line No.", "Source Subline No.")
        {
            IncludedFields = "Serial No.", "Lot No.", "Package No.";
        }
    }
    fieldgroups
    {
        fieldgroup(Brick; "Action Type", "Item No.", Quantity, Description, "Unit of Measure Code", "Bin Code")
        {
        }
    }

    trigger OnDelete()
    begin
        DeleteRelatedWhseActivLines(Rec, false);
    end;

    trigger OnRename()
    begin
        Error(Text001, TableCaption);
    end;

    var
        Location: Record Location;
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        Bin: Record Bin;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        ItemTrackingDataCollection: Codeunit "Item Tracking Data Collection";
        WarehouseAvailabilityMgt: Codeunit "Warehouse Availability Mgt.";
        WMSMgt: Codeunit "WMS Management";
        CreatePick: Codeunit "Create Pick";
        UOMMgt: Codeunit "Unit of Measure Management";
        ItemTrackingType: Enum "Item Tracking Type";
        UseBaseQty: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'You cannot rename a %1.';
        Text002: Label 'You cannot handle more than the outstanding %1 units.';
        Text003: Label 'must not be %1';
        Text004: Label 'If you delete %1 %2, %3 %4, %5 %6\the quantity to %7 will be imbalanced.\Do you still want to delete the %8?';
        Text005: Label 'You must not change the %1 in breakbulk lines.';
#pragma warning restore AA0470
        Text006: Label 'The update was interrupted to respect the warning.';
#pragma warning restore AA0074        
#pragma warning disable AA0074
        Text007: Label 'You must not split breakbulk lines.';
        Text008: Label 'Quantity available to pick is not enough to fill in all the lines.';
#pragma warning disable AA0470
        Text009: Label 'If you delete the %1\you must recreate related Warehouse Worksheet Lines manually.\\Do you want to delete the %1?';
        Text011: Label 'You cannot enter the %1 of the %2 as %3.';
        Text012: Label 'The %1 %2 exceeds the quantity available to pick %3 of the %4.\Do you still want to enter this %5?';
#pragma warning restore AA0470
        Text013: Label 'All related Warehouse Activity Lines are deleted.';
#pragma warning disable AA0470
        Text014: Label '%1 %2 has already been reserved for another document.';
#pragma warning restore AA0470
        Text015: Label 'The total available quantity has already been applied.';
#pragma warning restore AA0074
        InventoryNotAvailableErr: Label '%1 %2 is not available in inventory, it has already been reserved for another document, or the quantity available is lower than the quantity to handle specified on the line.', Comment = '%1 = CD No. Caption; %2 = CD No. Value';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text018: Label '%1 already exists with %2 %3.', Comment = 'Warehouse Activity Line already exists with Serial No. XXX';
        Text019: Label 'The %1 bin code must be different from the %2 bin code on location %3.';
        Text020: Label 'The %1 bin code must not be the Receipt Bin Code or the Shipment Bin Code that are set up on location %2.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ValidValuesIfSNDefinedErr: Label 'Field %1 can only have values -1, 0 or 1 when serial no. is defined. Current value is %2.', Comment = '%1 = field name, %2 = field value';
        NotEnoughQtyToPickMsg: Label 'Quantity available to pick is not enough.';
        OutstandingQtyCannotbeLessThanZeroErr: Label 'Outstanding Qty. base cannot be less than 0.';

    procedure CalcQty(QtyBase: Decimal): Decimal
    begin
        OnBeforeCalcQty(Rec, QtyBase);
        TestField("Qty. per Unit of Measure");
        exit(Round(QtyBase / "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision()));
    end;

    procedure AutofillQtyToHandle(var WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        NotEnough: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAutofillQtyToHandle(WarehouseActivityLine, IsHandled);
        if not IsHandled then begin
            UpdateDoNotFillQtyToHandle(WarehouseActivityLine);
            NotEnough := false;
            if WarehouseActivityLine.Find('-') then
                repeat
                    WarehouseActivityLine.Validate("Qty. to Handle", WarehouseActivityLine."Qty. Outstanding");
                    if WarehouseActivityLine."Qty. to Handle (Base)" <> WarehouseActivityLine."Qty. Outstanding (Base)" then
                        WarehouseActivityLine.Validate("Qty. to Handle (Base)", WarehouseActivityLine."Qty. Outstanding (Base)");
                    WarehouseActivityLine.Modify();
                    OnAfterAutofillQtyToHandleLine(WarehouseActivityLine);

                    if not NotEnough then
                        if WarehouseActivityLine."Qty. to Handle" < WarehouseActivityLine."Qty. Outstanding" then
                            NotEnough := true;
                until WarehouseActivityLine.Next() = 0;

            if GuiAllowed() and NotEnough then
                Message(Text008);
        end;

        OnAfterAutofillQtyToHandle(WarehouseActivityLine);
    end;

    procedure DeleteQtyToHandle(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        OnBeforeDeleteQtyToHandle(WarehouseActivityLine);
        if WarehouseActivityLine.Find('-') then
            repeat
                WarehouseActivityLine.Validate("Qty. to Handle", 0);
                WarehouseActivityLine.Modify();
                OnAfterUpdateQtyToHandleWhseActivLine(WarehouseActivityLine);
            until WarehouseActivityLine.Next() = 0;

        OnAfterDeleteQtyToHandle(WarehouseActivityLine);
    end;

    procedure AutofillQtyToHandleOnLine(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        WarehouseActivityLine.Validate("Qty. to Handle", WarehouseActivityLine."Qty. Outstanding");
        if WarehouseActivityLine."Qty. to Handle (Base)" <> WarehouseActivityLine."Qty. Outstanding (Base)" then
            WarehouseActivityLine.Validate("Qty. to Handle (Base)", WarehouseActivityLine."Qty. Outstanding (Base)");
        WarehouseActivityLine.Modify();

        if WarehouseActivityLine."Qty. to Handle" < WarehouseActivityLine."Qty. Outstanding" then
            if GuiAllowed() then
                Message(NotEnoughQtyToPickMsg);
    end;

    procedure DeleteQtyToHandleOnLine(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        WarehouseActivityLine.Validate("Qty. to Handle", 0);
        WarehouseActivityLine.Modify();
    end;

    local procedure GetItem()
    begin
        if Item."No." = "Item No." then
            exit;

        Item.Get("Item No.");
        if Item."Item Tracking Code" <> '' then
            ItemTrackingCode.Get(Item."Item Tracking Code")
        else
            Clear(ItemTrackingCode);
    end;

    procedure DeleteRelatedWhseActivLines(WarehouseActivityLine: Record "Warehouse Activity Line"; CalledFromHeader: Boolean)
    var
        WarehouseActivityLine2: Record "Warehouse Activity Line";
        WhseWkshLine: Record "Whse. Worksheet Line";
        Confirmed: Boolean;
        DeleteLineConfirmed: Boolean;
    begin
        OnBeforeDeleteRelatedWhseActivLines(WarehouseActivityLine, CalledFromHeader);

        if (WarehouseActivityLine."Activity Type" in [WarehouseActivityLine."Activity Type"::"Invt. Put-away", WarehouseActivityLine."Activity Type"::"Invt. Pick"]) and
            (not CalledFromHeader)
        then
            exit;

        WarehouseActivityLine2.SetCurrentKey(
          "Activity Type", "No.", "Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
        WarehouseActivityLine2.SetRange("Activity Type", WarehouseActivityLine."Activity Type");
        WarehouseActivityLine2.SetRange("No.", WarehouseActivityLine."No.");
        WhseWkshLine.SetCurrentKey("Whse. Document Type", "Whse. Document No.", "Whse. Document Line No.");
        if WarehouseActivityLine2.Find('-') then
            repeat
                Confirmed := ConfirmWhseActivLinesDeletionRecreate(WarehouseActivityLine2, WhseWkshLine);
            until (WarehouseActivityLine2.Next() = 0) or Confirmed;

        OnDeleteRelatedWhseActivLinesOnBeforeConfirmWhseActivLinesDeletionOutOfBalance(WarehouseActivityLine, CalledFromHeader, DeleteLineConfirmed);
        if DeleteLineConfirmed then
            exit;

        if (not CalledFromHeader) and (WarehouseActivityLine."Action Type" <> WarehouseActivityLine."Action Type"::" ") then begin
            ConfirmWhseActivLinesDeletionOutOfBalance(WarehouseActivityLine, WarehouseActivityLine2, DeleteLineConfirmed);
            if DeleteLineConfirmed then
                exit;
        end;

        if not CalledFromHeader then
            if WarehouseActivityLine."Action Type" <> WarehouseActivityLine."Action Type"::" " then
                WarehouseActivityLine2.SetFilter("Line No.", '<>%1', WarehouseActivityLine."Line No.")
            else
                WarehouseActivityLine2.SetRange("Line No.", WarehouseActivityLine."Line No.");
        OnDeleteRelatedWhseActivLinesOnBeforeWhseActivLine2Find(WarehouseActivityLine, WarehouseActivityLine2);
        if WarehouseActivityLine2.Find('-') then
            repeat
                OnDeleteRelatedWhseActivLinesOnBeforeDeleteWhseActivLine2(WarehouseActivityLine, WarehouseActivityLine2, CalledFromHeader);
                DeleteWarehouseActivityLine2(WarehouseActivityLine2, CalledFromHeader);
                WarehouseActivityLine2.DeleteBinContent(Enum::"Warehouse Action Type"::Place.AsInteger());
                WarehouseActivityLine.UpdateRelatedItemTrkg(WarehouseActivityLine2);
                OnDeleteRelatedWhseActivLinesOnAfterUpdateRelatedItemTrkg(WarehouseActivityLine, WarehouseActivityLine2, CalledFromHeader);
            until WarehouseActivityLine2.Next() = 0;

        if (not CalledFromHeader) and (WarehouseActivityLine."Action Type" <> WarehouseActivityLine."Action Type"::" ") then
            ShowDeletedMessage(WarehouseActivityLine);
    end;

    local procedure DeleteWarehouseActivityLine2(var WarehouseActivityLine2: Record "Warehouse Activity Line"; CalledFromHeader: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteWhseActivLine2(WarehouseActivityLine2, CalledFromHeader, IsHandled);
        if IsHandled then
            exit;

        WarehouseActivityLine2.Delete(); // to ensure correct item tracking update
    end;

    procedure CheckWhseDocLine()
    var
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WhseInternalPutAwayLine: Record "Whse. Internal Put-away Line";
        WhseInternalPickLine: Record "Whse. Internal Pick Line";
        AssemblyLine: Record "Assembly Line";
        JobPlanningLine: Record "Job Planning Line";
        WhseDocType2: Enum "Warehouse Activity Document Type";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWhseDocLine(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Bin Code" <> '' then begin
            if "Breakbulk No." <> 0 then
                exit;
            if ("Activity Type" = "Activity Type"::Pick) and ("Action Type" = "Action Type"::Place) then begin
                if ("Whse. Document Type" = "Whse. Document Type"::Shipment) and "Assemble to Order" then
                    WhseDocType2 := "Whse. Document Type"::Assembly
                else
                    WhseDocType2 := "Whse. Document Type";

                case WhseDocType2 of
                    "Whse. Document Type"::Shipment:
                        begin
                            WarehouseShipmentLine.Get("Whse. Document No.", "Whse. Document Line No.");
                            CheckBinCodeFromWhseShptLine(WarehouseShipmentLine);
                        end;
                    "Whse. Document Type"::"Internal Pick":
                        begin
                            WhseInternalPickLine.SetLoadFields("To Bin Code");
                            WhseInternalPickLine.Get("Whse. Document No.", "Whse. Document Line No.");
                            TestField("Bin Code", WhseInternalPickLine."To Bin Code");
                        end;
                    "Whse. Document Type"::Assembly:
                        begin
                            GetLocation("Location Code");
                            if Location."Directed Put-away and Pick" then begin
                                AssemblyLine.SetLoadFields("Bin Code");
                                AssemblyLine.Get("Source Subtype", "Source No.", "Source Line No.");
                                TestField("Bin Code", AssemblyLine."Bin Code");
                            end;
                        end;
                    "Whse. Document Type"::Job:
                        begin
                            GetLocation("Location Code");
                            if Location."Directed Put-away and Pick" then begin
                                JobPlanningLine.SetRange("Job Contract Entry No.", "Source Line No.");
                                JobPlanningLine.SetLoadFields("Bin Code");
                                if JobPlanningLine.FindFirst() then
                                    TestField("Bin Code", JobPlanningLine."Bin Code");
                            end;
                        end;
                    else
                        CheckWhseDocLineOnCheckSourceDocument(Rec, WhseDocType2);
                end;
            end;

            if ("Activity Type" = "Activity Type"::"Put-away") and ("Action Type" = "Action Type"::Take) then
                case "Whse. Document Type" of
                    "Whse. Document Type"::Receipt:
                        begin
                            PostedWhseReceiptLine.SetLoadFields("Bin Code");
                            PostedWhseReceiptLine.Get("Whse. Document No.", "Whse. Document Line No.");
                            TestField("Bin Code", PostedWhseReceiptLine."Bin Code");
                        end;
                    "Whse. Document Type"::"Internal Put-away":
                        begin
                            WhseInternalPutAwayLine.SetLoadFields("From Bin Code");
                            WhseInternalPutAwayLine.Get("Whse. Document No.", "Whse. Document Line No.");
                            TestField("Bin Code", WhseInternalPutAwayLine."From Bin Code");
                        end;
                end;
        end;
    end;

    procedure CheckBinInSourceDoc()
    var
        AssemblyLine: Record "Assembly Line";
        JobPlanningLine: Record "Job Planning Line";
        IsHandled: Boolean;
    begin
        if not (("Activity Type" = "Activity Type"::"Invt. Movement") and ("Action Type" = "Action Type"::Place) and ("Source Type" <> 0))
        then
            exit;

        IsHandled := false;
        OnBeforeCheckBinInSourceDoc(Rec, IsHandled);
        if IsHandled then
            exit;

        case "Source Type" of
            Database::"Assembly Line":
                begin
                    AssemblyLine.SetLoadFields("Bin Code");
                    AssemblyLine.Get("Source Subtype", "Source No.", "Source Line No.");
                    TestField("Bin Code", AssemblyLine."Bin Code");
                end;
            Database::Job:
                begin
                    JobPlanningLine.SetRange("Job Contract Entry No.", "Source Line No.");
                    JobPlanningLine.SetLoadFields("Bin Code");
                    if JobPlanningLine.FindFirst() then
                        TestField("Bin Code", JobPlanningLine."Bin Code");
                end;
            else
                OnCheckBinInSourceDoc(Rec);
        end;
    end;

    procedure GetBin(LocationCode: Code[10]; BinCode: Code[20]): Boolean
    begin
        if (Bin."Location Code" <> LocationCode) or
           (Bin.Code <> BinCode)
        then begin
            GetLocation(LocationCode);
            if Bin.Get(LocationCode, BinCode) then begin
                if not Location."Directed Put-away and Pick" then
                    exit(true);
                CheckBin();
                exit(true);
            end;
            exit(false);
        end;

        CheckBin();
        exit(true);
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

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure GetUOMCode() UOMCode: Code[10];
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetUOMCode(Rec, UOMCode, IsHandled, Location);
        if IsHandled then
            exit(UOMCode);

        if Location."Directed Put-away and Pick" then
            UOMCode := "Unit of Measure Code"
        else
            UOMCode := WMSMgt.GetBaseUOM("Item No.");
    end;

    local procedure CheckBin()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBin(Bin, IsHandled);
        if IsHandled then
            exit;

        GetLocation("Location Code");
        if Location."Directed Put-away and Pick" then
            if Location."Adjustment Bin Code" <> '' then
                if "Bin Code" = Location."Adjustment Bin Code" then
                    Error(
                      Text011,
                      Location.FieldCaption("Adjustment Bin Code"), Location.TableCaption(),
                      FieldCaption("Bin Code"));
    end;

    procedure CheckIncreaseCapacity(DeductLineCapacity: Boolean)
    begin
        CheckIncreaseCapacity(DeductLineCapacity, true);
    end;

    internal procedure CheckIncreaseCapacity(DeductLineCapacity: Boolean; CalledByPosting: Boolean)
    var
        BinContent: Record "Bin Content";
        DeductCubage: Decimal;
        DeductWeight: Decimal;
        IsHandled: Boolean;
    begin
        if DeductLineCapacity then begin
            DeductCubage := xRec.Cubage;
            DeductWeight := xRec.Weight;
        end;

        IsHandled := false;
        OnCheckIncreaseCapacityOnBeforeCheckIncreaseBinContent(Rec, Bin, DeductCubage, DeductWeight, IsHandled);
        if IsHandled then
            exit;

        if BinContent.Get("Location Code", "Bin Code", "Item No.", "Variant Code", "Unit of Measure Code") then
            BinContent.CheckIncreaseBinContent(
              "Qty. to Handle (Base)", "Qty. Outstanding (Base)",
              DeductCubage, DeductWeight, Cubage, Weight, CalledByPosting, false)
        else
            if GetBin("Location Code", "Bin Code") then
                Bin.CheckIncreaseBin(
                  "Bin Code", "Item No.", "Qty. to Handle",
                  DeductCubage, DeductWeight, Cubage, Weight, CalledByPosting, false);
    end;

    local procedure CheckExceedQtyAvailBase(BinContent: Record "Bin Content"; QtyAvailBase: Decimal; NewBinCode: Code[20])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckExceedQtyAvailBase(Rec, QtyAvailBase, NewBinCode, IsHandled);
        if IsHandled then
            exit;

        if (QtyAvailBase < "Qty. Outstanding (Base)") and not "Assemble to Order" then begin
            if not
               Confirm(
                 StrSubstNo(
                   Text012,
                   FieldCaption("Qty. Outstanding (Base)"), "Qty. Outstanding (Base)",
                   QtyAvailBase, BinContent.TableCaption(), FieldCaption("Bin Code")),
                 false)
            then
                Error(Text006);

            "Bin Code" := NewBinCode;
            Modify();
        end;
    end;

    local procedure CheckBinCodeFromWhseShptLine(WarehouseShipmentLine: Record "Warehouse Shipment Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckBinCodeFromWhseShptLine(Rec, WarehouseShipmentLine, IsHandled);
        if IsHandled then
            exit;

        TestField("Bin Code", WarehouseShipmentLine."Bin Code");
    end;

    procedure SplitLine(var WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        NewWarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        SplitLine(WarehouseActivityLine, NewWarehouseActivityLine);
    end;

    procedure SplitLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var NewWarehouseActivityLine: Record "Warehouse Activity Line")
    var
        LineSpacing: Integer;
        NewLineNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSplitLines(WarehouseActivityLine, IsHandled);
        if IsHandled then
            exit;

        CheckSplitLine(WarehouseActivityLine);

        NewWarehouseActivityLine := WarehouseActivityLine;
        NewWarehouseActivityLine.SetRange("No.", WarehouseActivityLine."No.");
        if NewWarehouseActivityLine.Find('>') then
            LineSpacing :=
              (NewWarehouseActivityLine."Line No." - WarehouseActivityLine."Line No.") div 2
        else
            LineSpacing := 10000;

        OnSplitLineOnBeforeRenumberAllLines(WarehouseActivityLine, LineSpacing);
        if LineSpacing = 0 then
            ReNumberWhseActivityLines(NewWarehouseActivityLine, WarehouseActivityLine, NewLineNo, LineSpacing);

        NewWarehouseActivityLine.Reset();
        NewWarehouseActivityLine.Init();
        NewWarehouseActivityLine := WarehouseActivityLine;
        NewWarehouseActivityLine."Line No." := NewWarehouseActivityLine."Line No." + LineSpacing;
        NewWarehouseActivityLine.Quantity :=
          WarehouseActivityLine."Qty. Outstanding" - WarehouseActivityLine."Qty. to Handle";
        NewWarehouseActivityLine."Qty. (Base)" :=
          WarehouseActivityLine."Qty. Outstanding (Base)" - WarehouseActivityLine."Qty. to Handle (Base)";
        NewWarehouseActivityLine."Qty. Outstanding" := NewWarehouseActivityLine.Quantity;
        NewWarehouseActivityLine."Qty. Outstanding (Base)" := NewWarehouseActivityLine."Qty. (Base)";
        UpdateQtyToHandleOnSplitLine(NewWarehouseActivityLine);
        NewWarehouseActivityLine."Qty. Handled" := 0;
        NewWarehouseActivityLine."Qty. Handled (Base)" := 0;
        OnSplitLineOnAfterInitNewWhseActivLine(NewWarehouseActivityLine);
        GetLocation("Location Code");
        if Location."Bin Capacity Policy" <> Location."Bin Capacity Policy"::"Never Check Capacity" then
            WMSMgt.CalcCubageAndWeight(
              NewWarehouseActivityLine."Item No.", NewWarehouseActivityLine."Unit of Measure Code",
              NewWarehouseActivityLine."Qty. to Handle", NewWarehouseActivityLine.Cubage, NewWarehouseActivityLine.Weight);

        if Location."Directed Put-away and Pick" then
            if not
               (((NewWarehouseActivityLine."Activity Type" = NewWarehouseActivityLine."Activity Type"::"Put-away") and
                 (NewWarehouseActivityLine."Action Type" = NewWarehouseActivityLine."Action Type"::Take)) or
                ((NewWarehouseActivityLine."Activity Type" = NewWarehouseActivityLine."Activity Type"::Pick) and
                 (NewWarehouseActivityLine."Action Type" = NewWarehouseActivityLine."Action Type"::Place)) or
                ("Breakbulk No." <> 0))
            then begin
                NewWarehouseActivityLine."Zone Code" := '';
                NewWarehouseActivityLine."Bin Code" := '';
            end;

        OnBeforeInsertNewWhseActivLine(NewWarehouseActivityLine, WarehouseActivityLine);
        NewWarehouseActivityLine.Insert();

        WarehouseActivityLine.Quantity := WarehouseActivityLine."Qty. to Handle" + WarehouseActivityLine."Qty. Handled";
        WarehouseActivityLine."Qty. (Base)" :=
          WarehouseActivityLine."Qty. to Handle (Base)" + WarehouseActivityLine."Qty. Handled (Base)";
        WarehouseActivityLine."Qty. Outstanding" := WarehouseActivityLine."Qty. to Handle";
        WarehouseActivityLine."Qty. Outstanding (Base)" := WarehouseActivityLine."Qty. to Handle (Base)";
        if Location."Bin Capacity Policy" <> Location."Bin Capacity Policy"::"Never Check Capacity" then
            WMSMgt.CalcCubageAndWeight(
              WarehouseActivityLine."Item No.", WarehouseActivityLine."Unit of Measure Code",
              WarehouseActivityLine."Qty. to Handle", WarehouseActivityLine.Cubage, WarehouseActivityLine.Weight);
        OnBeforeModifyOldWhseActivLine(WarehouseActivityLine);
        WarehouseActivityLine.Modify();

        OnAfterSplitLines(WarehouseActivityLine, NewWarehouseActivityLine);
    end;

    local procedure CheckSplitLine(WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckLine(WarehouseActivityLine, IsHandled);
        if not IsHandled then begin
            WarehouseActivityLine.TestField("Qty. to Handle");
            if WarehouseActivityLine."Activity Type" = WarehouseActivityLine."Activity Type"::"Put-away" then begin
                if WarehouseActivityLine."Breakbulk No." <> 0 then
                    Error(Text007);

                IsHandled := false;
                OnCheckSplitLineOnBeforeTestFieldActionType(WarehouseActivityLine, IsHandled);
                if not IsHandled then
                    WarehouseActivityLine.TestField("Action Type", WarehouseActivityLine."Action Type"::Place);
            end;
            if WarehouseActivityLine."Qty. to Handle" = WarehouseActivityLine."Qty. Outstanding" then
                WarehouseActivityLine.FieldError(
                "Qty. to Handle", StrSubstNo(Text003, WarehouseActivityLine.FieldCaption("Qty. Outstanding")));
        end;
    end;

    procedure FindBinCode() BinCode: Code[20]
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindBinCode(Rec, Item, BinCode, IsHandled);
        if IsHandled then
            exit(BinCode);

        if "Action Type" = "Action Type"::Take then begin
            WhseItemTrackingSetup.CopyTrackingFromWhseActivityLine(Rec);
            BinCode :=
                WMSMgt.BinContentLookUp(
                    "Location Code", "Item No.", "Variant Code", "Zone Code", WhseItemTrackingSetup, "Bin Code")
        end else
            BinCode := WMSMgt.BinLookUp("Location Code", "Item No.", "Variant Code", "Zone Code");
    end;

    procedure FindBinContent()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindBinContent(Rec, IsHandled);
        if IsHandled then
            exit;

        if not "Assemble to Order" and ("Action Type" = "Action Type"::Take) then
            WMSMgt.FindBinContent("Location Code", "Bin Code", "Item No.", "Variant Code", "Zone Code")
        else
            WMSMgt.FindBin("Location Code", "Bin Code", "Zone Code");
    end;

    procedure UpdateBreakbulkQtytoHandle()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetCurrentKey(
          "Activity Type", "No.", "Whse. Document Type",
          "Whse. Document No.", "Whse. Document Line No.");
        WarehouseActivityLine.SetRange("Activity Type", "Activity Type");
        WarehouseActivityLine.SetRange("No.", "No.");
        WarehouseActivityLine.SetRange("Whse. Document Type", "Whse. Document Type");
        WarehouseActivityLine.SetRange("Whse. Document No.", "Whse. Document No.");
        WarehouseActivityLine.SetRange("Whse. Document Line No.", "Whse. Document Line No.");
        WarehouseActivityLine.SetTrackingFilterFromWhseActivityLine(Rec);
        if "Original Breakbulk" then
            WarehouseActivityLine.SetRange("Original Breakbulk", true)
        else
            WarehouseActivityLine.SetRange("Breakbulk No.", "Breakbulk No.");
        WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
        if WarehouseActivityLine.FindFirst() then begin
            UpdateQtyToHandle(WarehouseActivityLine);

            WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Take);
            if "Original Breakbulk" then begin
                WarehouseActivityLine.SetRange("Original Breakbulk");
                WarehouseActivityLine.SetRange("Breakbulk No.", WarehouseActivityLine."Breakbulk No.")
            end else begin
                WarehouseActivityLine.SetRange("Breakbulk No.");
                WarehouseActivityLine.SetRange("Original Breakbulk", true);
            end;
            if WarehouseActivityLine.FindFirst() then
                UpdateQtyToHandle(WarehouseActivityLine);
        end;
    end;

    local procedure UpdateQtyToHandle(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        WarehouseActivityLine."Qty. to Handle (Base)" := "Qty. to Handle (Base)";
        WarehouseActivityLine."Qty. to Handle" := WarehouseActivityLine.CalcQty("Qty. to Handle (Base)");
        WMSMgt.CalcCubageAndWeight(
            WarehouseActivityLine."Item No.", WarehouseActivityLine."Unit of Measure Code",
            WarehouseActivityLine."Qty. to Handle", WarehouseActivityLine.Cubage, WarehouseActivityLine.Weight);
        OnUpdateQtyToHandleOnBeforeWhseActivLineModify(WarehouseActivityLine);
        WarehouseActivityLine.Modify();
    end;

    local procedure UpdateQtyToHandleOnSplitLine(var WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateQtyToHandleOnSplitLine(WarehouseActivityLine, IsHandled);
        if IsHandled then
            exit;

        WarehouseActivityLine."Qty. to Handle" := WarehouseActivityLine.Quantity;
        WarehouseActivityLine."Qty. to Handle (Base)" := WarehouseActivityLine."Qty. (Base)";
    end;

    procedure ShowWhseDoc()
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        PostedWhseReceiptHeader: Record "Posted Whse. Receipt Header";
        WhseInternalPickHeader: Record "Whse. Internal Pick Header";
        WhseInternalPutAwayHeader: Record "Whse. Internal Put-away Header";
        AssemblyHeader: Record "Assembly Header";
        Job: Record Job;
        WarehouseShipmentCard: Page "Warehouse Shipment";
        PostedWhseReceiptCard: Page "Posted Whse. Receipt";
        WhseInternalPickCard: Page "Whse. Internal Pick";
        WhseInternalPutawayCard: Page "Whse. Internal Put-away";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowWhseDoc(Rec, IsHandled);
        if IsHandled then
            exit;

        case "Whse. Document Type" of
            "Whse. Document Type"::Shipment:
                begin
                    WarehouseShipmentHeader.SetRange("No.", "Whse. Document No.");
                    WarehouseShipmentCard.SetTableView(WarehouseShipmentHeader);
                    WarehouseShipmentCard.RunModal();
                end;
            "Whse. Document Type"::Receipt:
                begin
                    PostedWhseReceiptHeader.SetRange("No.", "Whse. Document No.");
                    PostedWhseReceiptCard.SetTableView(PostedWhseReceiptHeader);
                    PostedWhseReceiptCard.RunModal();
                end;
            "Whse. Document Type"::"Internal Pick":
                begin
                    WhseInternalPickHeader.SetRange("No.", "Whse. Document No.");
                    WhseInternalPickHeader.FindFirst();
                    WhseInternalPickCard.SetRecord(WhseInternalPickHeader);
                    WhseInternalPickCard.SetTableView(WhseInternalPickHeader);
                    WhseInternalPickCard.RunModal();
                end;
            "Whse. Document Type"::"Internal Put-away":
                begin
                    WhseInternalPutAwayHeader.SetRange("No.", "Whse. Document No.");
                    WhseInternalPutAwayHeader.FindFirst();
                    WhseInternalPutawayCard.SetRecord(WhseInternalPutAwayHeader);
                    WhseInternalPutawayCard.SetTableView(WhseInternalPutAwayHeader);
                    WhseInternalPutawayCard.RunModal();
                end;
            "Whse. Document Type"::Assembly:
                begin
                    AssemblyHeader.SetRange("Document Type", "Source Subtype");
                    AssemblyHeader.SetRange("No.", "Source No.");
                    Page.RunModal(Page::"Assembly Order", AssemblyHeader);
                end;
            "Whse. Document Type"::Job:
                begin
                    Job.SetRange("No.", "Source No.");
                    Page.RunModal(Page::"Job Card", Job);
                end;
            else
                OnShowWhseDoc(Rec);
        end;
    end;

    procedure ShowActivityDoc()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehousePutAwayCard: Page "Warehouse Put-away";
        WarehouseMovementCard: Page "Warehouse Movement";
        InventoryPickCard: Page "Inventory Pick";
        InventoryPutAwayCard: Page "Inventory Put-away";
    begin
        WarehouseActivityHeader.SetRange(Type, "Activity Type");
        WarehouseActivityHeader.SetRange("No.", "No.");
        case "Activity Type" of
            "Activity Type"::Pick:
                RunWhsePickCard(WarehouseActivityHeader);
            "Activity Type"::"Put-away":
                begin
                    WarehousePutAwayCard.SetTableView(WarehouseActivityHeader);
                    WarehousePutAwayCard.RunModal();
                end;
            "Activity Type"::Movement:
                begin
                    WarehouseMovementCard.SetTableView(WarehouseActivityHeader);
                    WarehouseMovementCard.RunModal();
                end;
            "Activity Type"::"Invt. Pick":
                begin
                    InventoryPickCard.SetTableView(WarehouseActivityHeader);
                    InventoryPickCard.RunModal();
                end;
            "Activity Type"::"Invt. Put-away":
                begin
                    InventoryPutAwayCard.SetTableView(WarehouseActivityHeader);
                    InventoryPutAwayCard.RunModal();
                end;
            "Activity Type"::"Invt. Movement":
                Page.RunModal(Page::"Inventory Movement", WarehouseActivityHeader);
        end;
    end;

    procedure ChangeUOMCode(var WarehouseActivityLine: Record "Warehouse Activity Line"; var WarehouseActivityLine2: Record "Warehouse Activity Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeChangeUOMCode(WarehouseActivityLine, WarehouseActivityLine2, IsHandled);
        if IsHandled then
            exit;

        if "Breakbulk No." = 0 then
            if (Quantity <> "Qty. to Handle") or ("Qty. Handled" <> 0) then
                CreateNewUOMLine("Action Type", WarehouseActivityLine, WarehouseActivityLine2)
            else begin
                Rec := WarehouseActivityLine2;
                GetLocation("Location Code");
                if Location."Bin Capacity Policy" <> Location."Bin Capacity Policy"::"Never Check Capacity" then
                    WMSMgt.CalcCubageAndWeight(
                      "Item No.", "Unit of Measure Code", "Qty. to Handle", Cubage, Weight);
                OnChangeUOMCodeOnBeforeRecModify(Rec, Location);
                Modify();
            end;
    end;

    local procedure CreateNewUOMLine(ActType: Enum "Warehouse Action Type"; WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityLine2: Record "Warehouse Activity Line")
    var
        NewWarehouseActivityLine: Record "Warehouse Activity Line";
        LineSpacing: Integer;
    begin
        NewWarehouseActivityLine := WarehouseActivityLine;
        if NewWarehouseActivityLine.Find('>') then
            LineSpacing := (NewWarehouseActivityLine."Line No." - WarehouseActivityLine."Line No.") div 2
        else
            LineSpacing := 10000;

        NewWarehouseActivityLine.Reset();
        NewWarehouseActivityLine.Init();
        NewWarehouseActivityLine := WarehouseActivityLine2;
        NewWarehouseActivityLine."Line No." := NewWarehouseActivityLine."Line No." + LineSpacing;
        GetLocation("Location Code");
        if Location."Bin Capacity Policy" <> Location."Bin Capacity Policy"::"Never Check Capacity" then
            WMSMgt.CalcCubageAndWeight(
              NewWarehouseActivityLine."Item No.", NewWarehouseActivityLine."Unit of Measure Code",
              NewWarehouseActivityLine."Qty. to Handle", NewWarehouseActivityLine.Cubage, NewWarehouseActivityLine.Weight);
        NewWarehouseActivityLine."Action Type" := ActType;
        NewWarehouseActivityLine.Validate("Qty. Handled", 0);
        OnCreateNewUOMLineOnBeforeNewWhseActivLineInsert(NewWarehouseActivityLine, WarehouseActivityLine);
        NewWarehouseActivityLine.Insert();

        WarehouseActivityLine."Qty. Outstanding" :=
          WarehouseActivityLine."Qty. Outstanding" - WarehouseActivityLine."Qty. to Handle";
        WarehouseActivityLine."Qty. Outstanding (Base)" :=
          WarehouseActivityLine."Qty. Outstanding (Base)" - WarehouseActivityLine."Qty. to Handle (Base)";
        WarehouseActivityLine.Quantity :=
          WarehouseActivityLine.Quantity - WarehouseActivityLine."Qty. to Handle";
        WarehouseActivityLine."Qty. (Base)" :=
          WarehouseActivityLine."Qty. (Base)" - WarehouseActivityLine."Qty. to Handle (Base)";
        WarehouseActivityLine.Validate("Qty. to Handle", WarehouseActivityLine."Qty. Outstanding");
        if Location."Bin Capacity Policy" <> Location."Bin Capacity Policy"::"Never Check Capacity" then
            WMSMgt.CalcCubageAndWeight(
              WarehouseActivityLine."Item No.", WarehouseActivityLine."Unit of Measure Code",
              WarehouseActivityLine."Qty. to Handle", WarehouseActivityLine.Cubage, WarehouseActivityLine.Weight);
        OnCreateNewUOMLineOnBeforeNewWhseActivLineModify(NewWarehouseActivityLine, WarehouseActivityLine);
        WarehouseActivityLine.Modify();
    end;

    procedure UpdateRelatedItemTrkg(WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        WhseDocType2: Enum "Warehouse Activity Document Type";
    begin
        if WarehouseActivityLine.TrackingExists() then begin
            WhseItemTrackingLine.SetTrackingKey();
            WhseItemTrackingLine.SetTrackingFilterFromWhseActivityLine(WarehouseActivityLine);
            if (WarehouseActivityLine."Whse. Document Type" = WarehouseActivityLine."Whse. Document Type"::Shipment) and
               WarehouseActivityLine."Assemble to Order"
            then
                WhseDocType2 := WarehouseActivityLine."Whse. Document Type"::Assembly
            else
                WhseDocType2 := WarehouseActivityLine."Whse. Document Type";
            case WhseDocType2 of
                WarehouseActivityLine."Whse. Document Type"::Shipment:
                    SetWhseItemTrkgLineFiltersWhseShipment(WhseItemTrackingLine, WarehouseActivityLine);
                WarehouseActivityLine."Whse. Document Type"::"Internal Pick":
                    begin
                        WhseItemTrackingLine.SetRange("Source Type", Database::"Whse. Internal Pick Line");
                        WhseItemTrackingLine.SetRange("Source ID", WarehouseActivityLine."Whse. Document No.");
                        WhseItemTrackingLine.SetRange("Source Ref. No.", WarehouseActivityLine."Whse. Document Line No.");
                    end;
                WarehouseActivityLine."Whse. Document Type"::"Internal Put-away":
                    begin
                        WhseItemTrackingLine.SetRange("Source Type", Database::"Whse. Internal Put-away Line");
                        WhseItemTrackingLine.SetRange("Source ID", WarehouseActivityLine."Whse. Document No.");
                        WhseItemTrackingLine.SetRange("Source Ref. No.", WarehouseActivityLine."Whse. Document Line No.");
                    end;
                WarehouseActivityLine."Whse. Document Type"::Production:
                    begin
                        WhseItemTrackingLine.SetRange("Source Type", WarehouseActivityLine."Source Type");
                        WhseItemTrackingLine.SetRange("Source Subtype", WarehouseActivityLine."Source Subtype");
                        WhseItemTrackingLine.SetRange("Source ID", WarehouseActivityLine."Source No.");
                        WhseItemTrackingLine.SetRange("Source Prod. Order Line", WarehouseActivityLine."Source Line No.");
                        WhseItemTrackingLine.SetRange("Source Ref. No.", WarehouseActivityLine."Source Subline No.");
                    end;
                WarehouseActivityLine."Whse. Document Type"::Assembly:
                    begin
                        WhseItemTrackingLine.SetRange("Source Type", WarehouseActivityLine."Source Type");
                        WhseItemTrackingLine.SetRange("Source Subtype", WarehouseActivityLine."Source Subtype");
                        WhseItemTrackingLine.SetRange("Source ID", WarehouseActivityLine."Source No.");
                        WhseItemTrackingLine.SetRange("Source Ref. No.", WarehouseActivityLine."Source Line No.");
                    end;
                WarehouseActivityLine."Whse. Document Type"::Job:
                    begin
                        WhseItemTrackingLine.SetFilter("Source Type", '%1|%2', WarehouseActivityLine."Source Type", Database::"Job Planning Line");
                        WhseItemTrackingLine.SetRange("Source ID", WarehouseActivityLine."Source No.");
                        WhseItemTrackingLine.SetRange("Source Ref. No.", WarehouseActivityLine."Source Line No.");
                    end;
            end;
            if WarehouseActivityLine."Activity Type" = WarehouseActivityLine."Activity Type"::"Invt. Movement" then
                case WarehouseActivityLine."Source Type" of
                    Database::"Assembly Line":
                        begin
                            WhseItemTrackingLine.SetRange("Source Type", Database::"Assembly Line");
                            WhseItemTrackingLine.SetRange("Source Subtype", WarehouseActivityLine."Source Subtype");
                            WhseItemTrackingLine.SetRange("Source ID", WarehouseActivityLine."Source No.");
                            WhseItemTrackingLine.SetRange("Source Ref. No.", WarehouseActivityLine."Source Line No.");
                        end;
                    else
                        OnUpdateRelatedItemTrkgForInvtMovement(WarehouseActivityLine, WhseItemTrackingLine);
                end;
            if WhseItemTrackingLine.Find('-') then
                repeat
                    ItemTrackingMgt.CalcWhseItemTrkgLine(WhseItemTrackingLine);
                    UpdateReservation(WarehouseActivityLine, true);
                    if (WarehouseActivityLine."Whse. Document Type" in
                        [WarehouseActivityLine."Whse. Document Type"::Production, WarehouseActivityLine."Whse. Document Type"::Assembly, WarehouseActivityLine."Whse. Document Type"::Job]) and
                       not WarehouseActivityLine."Assemble to Order"
                    then
                        if WhseItemTrackingLine."Quantity Handled (Base)" = 0 then
                            WhseItemTrackingLine.Delete()
                        else begin
                            WhseItemTrackingLine.Validate("Quantity (Base)", WhseItemTrackingLine."Quantity Handled (Base)");
                            WhseItemTrackingLine.Modify();
                        end
                    else
                        if (WarehouseActivityLine."Activity Type" = WarehouseActivityLine."Activity Type"::"Invt. Movement") and
                           (WhseItemTrackingLine."Quantity Handled (Base)" = 0)
                        then
                            WhseItemTrackingLine.Delete()
                        else
                            WhseItemTrackingLine.Modify();
                until WhseItemTrackingLine.Next() = 0;
        end;
    end;

    local procedure SetWhseItemTrkgLineFiltersWhseShipment(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetWhseItemTrkgLineFiltersWhseShipment(Rec, WhseItemTrackingLine, WarehouseActivityLine, IsHandled);
        if IsHandled then
            exit;

        WhseItemTrackingLine.SetRange("Source Type", Database::"Warehouse Shipment Line");
        WhseItemTrackingLine.SetRange("Source ID", WarehouseActivityLine."Whse. Document No.");
        WhseItemTrackingLine.SetRange("Source Ref. No.", WarehouseActivityLine."Whse. Document Line No.");
    end;

    procedure LookUpTrackingSummary(var WarehouseActivityLine: Record "Warehouse Activity Line"; SearchForSupply: Boolean; SignFactor: Integer; TrackingType: Enum "Item Tracking Type")
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeLookUpTrackingSummary(WarehouseActivityLine, TrackingType, IsHandled);
        if IsHandled then
            exit;

        InitTrackingSpecFromWhseActivLine(TempTrackingSpecification, WarehouseActivityLine);
        TempTrackingSpecification."Quantity (Base)" := WarehouseActivityLine."Qty. Outstanding (Base)";
        TempTrackingSpecification."Qty. to Handle" := WarehouseActivityLine."Qty. Outstanding";
        TempTrackingSpecification."Qty. to Handle (Base)" := WarehouseActivityLine."Qty. Outstanding (Base)";
        TempTrackingSpecification."Qty. to Invoice" := 0;
        TempTrackingSpecification."Qty. to Invoice (Base)" := 0;
        TempTrackingSpecification."Quantity Handled (Base)" := 0;
        TempTrackingSpecification."Quantity Invoiced (Base)" := 0;

        GetItem();
        if not ItemTrackingDataCollection.CurrentDataSetMatches(
            WarehouseActivityLine."Item No.", WarehouseActivityLine."Variant Code", WarehouseActivityLine."Location Code")
        then
            Clear(ItemTrackingDataCollection);
        OnLookUpTrackingSummaryOnAfterCheckDataSet(WarehouseActivityLine, Item, TempTrackingSpecification);
        ItemTrackingDataCollection.SetCurrentBinAndItemTrkgCode(WarehouseActivityLine."Bin Code", ItemTrackingCode);
        ItemTrackingDataCollection.AssistEditTrackingNo(
            TempTrackingSpecification, SearchForSupply, SignFactor, TrackingType, WarehouseActivityLine."Qty. Outstanding");

        OnLookUpTrackingSummaryOnAfterAssistEditTrackingNo(WarehouseActivityLine, TempTrackingSpecification, TrackingType);

        case TrackingType of
            TrackingType::"Serial No.":
                if TempTrackingSpecification."Serial No." <> '' then begin
                    WarehouseActivityLine.Validate("Serial No.", TempTrackingSpecification."Serial No.");
                    WarehouseActivityLine.Validate("Lot No.", TempTrackingSpecification."Lot No.");
                    OnLookUpTrackingSummaryOnAfterAssignSerialNoTracking(WarehouseActivityLine, TempTrackingSpecification);
                    WarehouseActivityLine.Validate("Expiration Date", TempTrackingSpecification."Expiration Date");
                    WarehouseActivityLine.Validate("Warranty Date", TempTrackingSpecification."Warranty Date");
                    WarehouseActivityLine.Modify();
                end;
            TrackingType::"Lot No.":
                if TempTrackingSpecification."Lot No." <> '' then begin
                    WarehouseActivityLine.Validate("Lot No.", TempTrackingSpecification."Lot No.");
                    OnLookUpTrackingSummaryOnAfterAssignLotNoTracking(WarehouseActivityLine, TempTrackingSpecification);
                    WarehouseActivityLine.Validate("Expiration Date", TempTrackingSpecification."Expiration Date");
                    WarehouseActivityLine.Modify();
                end;
        end;

        OnAfterLookupTrackingSummary(WarehouseActivityLine, TempTrackingSpecification, TrackingType);
    end;

    procedure CheckItemTrackingAvailability(): Boolean
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
    begin
        InitTrackingSpecFromWhseActivLine(TempTrackingSpecification, Rec);
        TempTrackingSpecification."Quantity (Base)" := "Qty. Outstanding (Base)";
        TempTrackingSpecification."Qty. to Handle" := "Qty. Outstanding";
        TempTrackingSpecification."Qty. to Handle (Base)" := "Qty. Outstanding (Base)";
        TempTrackingSpecification.Insert();

        GetItem();
        Clear(ItemTrackingDataCollection);
        ItemTrackingDataCollection.SetCurrentBinAndItemTrkgCode("Bin Code", ItemTrackingCode);
        exit(ItemTrackingDataCollection.CheckAvailableTrackingQuantity(TempTrackingSpecification));
    end;

    procedure CheckReservedItemTrkg(CheckType: Enum "Item Tracking Type"; ItemTrkgCode: Code[50])
    var
        IsHandled: Boolean;
    begin
        IsHandled := ("Activity Type" = "Activity Type"::"Invt. Pick") and "Assemble to Order";
        OnBeforeCheckReservedItemTrkg(Rec, CheckType, ItemTrkgCode, IsHandled);
        if IsHandled then
            exit;

        case CheckType of
            CheckType::"Serial No.":
                CheckReservedItemTrkgForSerialNo(ItemTrkgCode);
            CheckType::"Lot No.":
                CheckReservedItemTrkgForLotNo(ItemTrkgCode);
            else
                OnCheckReservedItemTrkgOnCheckTypeElseCase(Rec, CheckType, ItemTrkgCode);
        end;
    end;

    local procedure CheckReservedItemTrkgForSerialNo(ItemTrkgCode: Code[50])
    var
        ReservEntry: Record "Reservation Entry";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
    begin
        ItemTrackingMgt.GetWhseItemTrkgSetup("Item No.", WhseItemTrackingSetup);
        if not WhseItemTrackingSetup."Serial No. Required" then
            exit;

        ReservEntry.SetCurrentKey("Item No.", "Variant Code", "Location Code", "Reservation Status");
        ReservEntry.SetRange("Item No.", "Item No.");
        ReservEntry.SetRange("Variant Code", "Variant Code");
        ReservEntry.SetRange("Location Code", "Location Code");
        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation);
        ReservEntry.SetRange("Serial No.", ItemTrkgCode);
        ReservEntry.SetRange(Positive, false);
        if ReservEntry.FindFirst() and
            ((ReservEntry."Source Type" <> "Source Type") or
            (ReservEntry."Source Subtype" <> "Source Subtype") or
            (ReservEntry."Source ID" <> "Source No.") or
            (((ReservEntry."Source Ref. No." <> "Source Line No.") and
                (ReservEntry."Source Type" <> ProdOrderComponentSourceID())) or
                (((ReservEntry."Source Prod. Order Line" <> "Source Line No.") or
                (ReservEntry."Source Ref. No." <> "Source Subline No.")) and
                (ReservEntry."Source Type" = ProdOrderComponentSourceID()))))
        then
            Error(Text014, FieldCaption("Serial No."), ItemTrkgCode);
    end;

    local procedure ProdOrderComponentSourceID(): Integer
    begin
        exit(5407);
    end;

    local procedure CheckReservedItemTrkgForLotNo(ItemTrkgCode: Code[50])
    var
        Item: Record Item;
        ReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary;
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        WhseAvailMgt: Codeunit "Warehouse Availability Mgt.";
        LineReservedQty: Decimal;
        AvailQtyFromOtherResvLines: Decimal;
    begin
        ItemTrackingMgt.GetWhseItemTrkgSetup("Item No.", WhseItemTrackingSetup);
        if not WhseItemTrackingSetup."Lot No. Required" then
            exit;

        Item.Get("Item No.");
        Item.SetRange("Location Filter", "Location Code");
        Item.SetRange("Variant Filter", "Variant Code");
        Item.SetRange("Lot No. Filter", ItemTrkgCode);
        Item.CalcFields(Inventory, "Reserved Qty. on Inventory");
        WhseItemTrackingSetup."Lot No." := ItemTrkgCode;
        ReservEntry.SetCurrentKey("Item No.", "Variant Code", "Location Code", "Reservation Status");
        ReservEntry.SetRange("Item No.", "Item No.");
        ReservEntry.SetRange("Variant Code", "Variant Code");
        ReservEntry.SetRange("Location Code", "Location Code");
        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation);
        ReservEntry.SetRange("Lot No.", ItemTrkgCode);
        ReservEntry.SetRange(Positive, true);
        if ReservEntry.Find('-') then
            repeat
                ReservEntry2.Get(ReservEntry."Entry No.", false);
                if ((ReservEntry2."Source Type" <> "Source Type") or
                    (ReservEntry2."Source Subtype" <> "Source Subtype") or
                    (ReservEntry2."Source ID" <> "Source No.") or
                    (((ReservEntry2."Source Ref. No." <> "Source Line No.") and
                        (ReservEntry2."Source Type" <> ProdOrderComponentSourceID())) or
                        (((ReservEntry2."Source Prod. Order Line" <> "Source Line No.") or
                        (ReservEntry2."Source Ref. No." <> "Source Subline No.")) and
                        (ReservEntry2."Source Type" = ProdOrderComponentSourceID())))) and
                    (ReservEntry2."Lot No." = '')
                then
                    AvailQtyFromOtherResvLines := AvailQtyFromOtherResvLines + Abs(ReservEntry2."Quantity (Base)");
            until ReservEntry.Next() = 0;

        TempWarehouseActivityLine := Rec;
        TempWarehouseActivityLine."Qty. Outstanding (Base)" *= -1;
        TempWarehouseActivityLine.Insert();

        LineReservedQty :=
            WhseAvailMgt.CalcLineReservedQtyOnInvt(
            "Source Type", "Source Subtype", "Source No.", "Source Line No.", "Source Subline No.", true, WhseItemTrackingSetup, TempWarehouseActivityLine);

        if (Item.Inventory - Abs(Item."Reserved Qty. on Inventory") +
            LineReservedQty + AvailQtyFromOtherResvLines +
            WhseAvailMgt.CalcReservQtyOnPicksShips("Location Code", "Item No.", "Variant Code", TempWarehouseActivityLine)) <
            "Qty. to Handle (Base)"
        then
            Error(InventoryNotAvailableErr, FieldCaption("Lot No."), ItemTrkgCode);

        OnAfterCheckReservedItemTrkg(Rec, xRec, CurrFieldNo, 0, LineReservedQty);
    end;

    procedure DeleteBinContent(ActionType: Option)
    var
        BinContent: Record "Bin Content";
        IsHandled: Boolean;
    begin
        if "Action Type".AsInteger() <> ActionType then
            exit;

        IsHandled := false;
        OnBeforeDeleteBinContent(Rec, IsHandled);
        if IsHandled then
            exit;

        BinContent.ReadIsolation(IsolationLevel::ReadCommitted);
        if BinContent.Get("Location Code", "Bin Code", "Item No.", "Variant Code", "Unit of Measure Code") then
            if not BinContent.Fixed and
               (BinContent."Min. Qty." = 0) and (BinContent."Max. Qty." = 0)
            then begin
                BinContent.CalcFields("Quantity (Base)", "Positive Adjmt. Qty. (Base)", "Put-away Quantity (Base)");
                if (BinContent."Quantity (Base)" = 0) and
                   (BinContent."Positive Adjmt. Qty. (Base)" = 0) and
                   (BinContent."Put-away Quantity (Base)" - "Qty. Outstanding (Base)" <= 0)
                then
                    BinContent.Delete();
            end;
    end;

    local procedure UpdateReservation(TempWarehouseActivityLine2: Record "Warehouse Activity Line" temporary; Deletion: Boolean)
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
    begin
        if (TempWarehouseActivityLine2."Action Type" <> TempWarehouseActivityLine2."Action Type"::Take) and (TempWarehouseActivityLine2."Breakbulk No." = 0) and
           (TempWarehouseActivityLine2."Whse. Document Type" = TempWarehouseActivityLine2."Whse. Document Type"::Shipment)
        then begin
            InitTrackingSpecFromWhseActivLine(TempTrackingSpecification, TempWarehouseActivityLine2);
            TempTrackingSpecification."Qty. to Handle (Base)" := 0;
            TempTrackingSpecification."Entry No." := TempTrackingSpecification."Entry No." + 1;
            TempTrackingSpecification."Creation Date" := Today;
            TempTrackingSpecification."Warranty Date" := TempWarehouseActivityLine2."Warranty Date";
            TempTrackingSpecification."Expiration Date" := TempWarehouseActivityLine2."Expiration Date";
            TempTrackingSpecification.Correction := true;
            OnUpdateReservationOnBeforeTempTrackingSpecificationInsert(TempTrackingSpecification, TempWarehouseActivityLine2);
            TempTrackingSpecification.Insert();
        end;
        ItemTrackingMgt.SetPick(TempWarehouseActivityLine2."Activity Type" = TempWarehouseActivityLine2."Activity Type"::Pick);
        ItemTrackingMgt.SynchronizeWhseItemTracking(TempTrackingSpecification, '', Deletion);
    end;

    procedure TransferFromPickWkshLine(WhseWkshLine: Record "Whse. Worksheet Line")
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        AssembleToOrderLink: Record "Assemble-to-Order Link";
    begin
        "Activity Type" := "Activity Type"::Pick;
        "Source Type" := WhseWkshLine."Source Type";
        "Source Subtype" := WhseWkshLine."Source Subtype";
        "Source No." := WhseWkshLine."Source No.";
        "Source Line No." := WhseWkshLine."Source Line No.";
        "Source Subline No." := WhseWkshLine."Source Subline No.";
        "Shelf No." := WhseWkshLine."Shelf No.";
        "Item No." := WhseWkshLine."Item No.";
        "Variant Code" := WhseWkshLine."Variant Code";
        Description := WhseWkshLine.Description;
        "Description 2" := WhseWkshLine."Description 2";
        "Due Date" := WhseWkshLine."Due Date";
        "Starting Date" := WorkDate();
        "Destination Type" := WhseWkshLine."Destination Type";
        "Destination No." := WhseWkshLine."Destination No.";
        "Shipping Agent Code" := WhseWkshLine."Shipping Agent Code";
        "Shipping Agent Service Code" := WhseWkshLine."Shipping Agent Service Code";
        "Shipment Method Code" := WhseWkshLine."Shipment Method Code";
        "Shipping Advice" := WhseWkshLine."Shipping Advice";
        "Whse. Document Type" := WhseWkshLine."Whse. Document Type";
        "Whse. Document No." := WhseWkshLine."Whse. Document No.";
        "Whse. Document Line No." := WhseWkshLine."Whse. Document Line No.";

        case "Whse. Document Type" of
            "Whse. Document Type"::Shipment:
                begin
                    WarehouseShipmentLine.SetLoadFields("Assemble to Order");
                    WarehouseShipmentLine.Get("Whse. Document No.", "Whse. Document Line No.");
                    "Assemble to Order" := WarehouseShipmentLine."Assemble to Order";
                    "ATO Component" := WarehouseShipmentLine."Assemble to Order";
                end;
            "Whse. Document Type"::Assembly:
                begin
                    AssembleToOrderLink.SetLoadFields("Assembly Document Type", "Assembly Document No.");
                    "Assemble to Order" := AssembleToOrderLink.Get("Source Subtype", "Source No.");
                    "ATO Component" := true;
                end;
        end;

        OnAfterTransferFromPickWkshLine(Rec, WhseWkshLine);
    end;

    procedure TransferFromShptLine(WhseShptLine: Record "Warehouse Shipment Line")
    begin
        "Activity Type" := "Activity Type"::Pick;
        "Source Type" := WhseShptLine."Source Type";
        "Source Subtype" := WhseShptLine."Source Subtype";
        "Source No." := WhseShptLine."Source No.";
        "Source Line No." := WhseShptLine."Source Line No.";
        "Shelf No." := WhseShptLine."Shelf No.";
        "Item No." := WhseShptLine."Item No.";
        "Variant Code" := WhseShptLine."Variant Code";
        Description := WhseShptLine.Description;
        "Description 2" := WhseShptLine."Description 2";
        "Due Date" := WhseShptLine."Due Date";
        "Starting Date" := WhseShptLine."Shipment Date";
        "Destination Type" := WhseShptLine."Destination Type";
        "Destination No." := WhseShptLine."Destination No.";
        "Shipping Advice" := WhseShptLine."Shipping Advice";
        "Whse. Document Type" := "Whse. Document Type"::Shipment;
        "Whse. Document No." := WhseShptLine."No.";
        "Whse. Document Line No." := WhseShptLine."Line No.";

        OnAfterTransferFromShptLine(Rec, WhseShptLine);
    end;

    procedure TransferFromATOShptLine(WhseShptLine: Record "Warehouse Shipment Line"; AssemblyLine: Record "Assembly Line")
    begin
        WhseShptLine.TestField("Assemble to Order", true);
        TransferFromShptLine(WhseShptLine);
        TransferAllButWhseDocDetailsFromAssemblyLine(AssemblyLine);
    end;

    procedure TransferFromATOJobPlanningLine(JobPlanningLine: Record "Job Planning Line"; AssemblyLine: Record "Assembly Line")
    begin
        JobPlanningLine.TestField("Assemble to Order", true);
        TransferFromJobPlanningLine(JobPlanningLine);
        TransferAllButWhseDocDetailsFromAssemblyLine(AssemblyLine);
    end;

    procedure TransferFromIntPickLine(WhseInternalPickLine: Record "Whse. Internal Pick Line")
    begin
        "Activity Type" := "Activity Type"::Pick;
        "Shelf No." := WhseInternalPickLine."Shelf No.";
        "Item No." := WhseInternalPickLine."Item No.";
        "Variant Code" := WhseInternalPickLine."Variant Code";
        Description := WhseInternalPickLine.Description;
        "Description 2" := WhseInternalPickLine."Description 2";
        "Due Date" := WhseInternalPickLine."Due Date";
        "Starting Date" := WorkDate();
        "Source Type" := Database::"Whse. Internal Pick Line";
        "Source No." := WhseInternalPickLine."No.";
        "Source Line No." := WhseInternalPickLine."Line No.";
        "Whse. Document Type" := "Whse. Document Type"::"Internal Pick";
        "Whse. Document No." := WhseInternalPickLine."No.";
        "Whse. Document Line No." := WhseInternalPickLine."Line No.";

        OnAfterTransferFromIntPickLine(Rec, WhseInternalPickLine);
    end;

#if not CLEAN26
    [Obsolete('Moved to codeunit ProdOrderWarehouseMgt', '26.0')]
    procedure TransferFromCompLine(ProdOrderCompLine: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    var
        ProdOrderWarehouseMgt: Codeunit Microsoft.Manufacturing.Document."Prod. Order Warehouse Mgt.";
    begin
        ProdOrderWarehouseMgt.TransferFromCompLine(Rec, ProdOrderCompLine);
    end;
#endif

    procedure TransferFromAssemblyLine(AssemblyLine: Record "Assembly Line")
    begin
        TransferAllButWhseDocDetailsFromAssemblyLine(AssemblyLine);
        "Whse. Document Type" := "Whse. Document Type"::Assembly;
        "Whse. Document No." := AssemblyLine."Document No.";
        "Whse. Document Line No." := AssemblyLine."Line No.";

        OnAfterTransferFromAssemblyLine(Rec, AssemblyLine);
    end;

    procedure TransferFromJobPlanningLine(JobPlanningLine: Record "Job Planning Line")
    var
        Job: Record Job;
    begin
        "Activity Type" := "Activity Type"::Pick;
        "Source Type" := Database::Job;
        "Source Subtype" := 0;
        "Source No." := JobPlanningLine."Job No.";
        "Source Line No." := JobPlanningLine."Job Contract Entry No.";
        "Source Subline No." := JobPlanningLine."Line No.";
        JobPlanningLine.TestField(Type, JobPlanningLine.Type::Item);
        "Item No." := JobPlanningLine."No.";
        "Variant Code" := JobPlanningLine."Variant Code";
        Description := JobPlanningLine.Description;
        "Due Date" := JobPlanningLine."Planning Due Date";
        "Whse. Document Type" := "Whse. Document Type"::Job;
        "Whse. Document No." := JobPlanningLine."Job No.";
        "Whse. Document Line No." := JobPlanningLine."Job Contract Entry No.";
        "Destination Type" := "Destination Type"::Customer;

        Job.SetLoadFields("Sell-to Customer No.");
        Job.Get(JobPlanningLine."Job No.");
        "Destination No." := Job."Sell-to Customer No.";

        OnAfterTransferFromJobPlanningLine(Rec, JobPlanningLine);
    end;

    procedure TransferFromMovWkshLine(WhseWkshLine: Record "Whse. Worksheet Line")
    begin
        "Activity Type" := "Activity Type"::Movement;
        "Item No." := WhseWkshLine."Item No.";
        "Variant Code" := WhseWkshLine."Variant Code";
        "Starting Date" := WorkDate();
        Description := WhseWkshLine.Description;
        "Description 2" := WhseWkshLine."Description 2";
        "Due Date" := WhseWkshLine."Due Date";
        Dedicated := Bin.Dedicated;
        "Zone Code" := Bin."Zone Code";
        "Bin Ranking" := Bin."Bin Ranking";
        "Bin Type Code" := Bin."Bin Type Code";
        "Whse. Document Type" := "Whse. Document Type"::"Movement Worksheet";
        "Whse. Document No." := WhseWkshLine.Name;
        "Whse. Document Line No." := WhseWkshLine."Line No.";

        OnAfterTransferFromMovWkshLine(Rec, WhseWkshLine);
    end;

    local procedure TransferAllButWhseDocDetailsFromAssemblyLine(AssemblyLine: Record "Assembly Line")
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        "Activity Type" := "Activity Type"::Pick;
        "Source Type" := Database::"Assembly Line";
        "Source Subtype" := AssemblyLine."Document Type".AsInteger();
        "Source No." := AssemblyLine."Document No.";
        "Source Line No." := AssemblyLine."Line No.";
        "Source Subline No." := 0;
        AssemblyLine.TestField(Type, AssemblyLine.Type::Item);
        "Item No." := AssemblyLine."No.";
        "Variant Code" := AssemblyLine."Variant Code";
        Description := AssemblyLine.Description;
        "Description 2" := AssemblyLine."Description 2";
        "Due Date" := AssemblyLine."Due Date";
        AssemblyHeader.SetAutoCalcFields("Assemble to Order");
        AssemblyHeader.Get(AssemblyLine."Document Type", AssemblyLine."Document No.");
        "Assemble to Order" := AssemblyHeader."Assemble to Order";
        "ATO Component" := true;
        Item."No." := "Item No.";
        Item.ItemSKUGet(Item, "Location Code", "Variant Code");
        "Shelf No." := Item."Shelf No.";

        OnAfterTransferAllButWhseDocDetailsFromAssemblyLine(Rec, AssemblyLine);
    end;

    local procedure CheckSNSpecificationExists()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSNSpecificationExists(Rec, IsHandled);
        if IsHandled then
            exit;

        if "Serial No." <> '' then begin
            WarehouseActivityLine.SetCurrentKey("Item No.");
            WarehouseActivityLine.SetRange("Activity Type", "Activity Type");
            WarehouseActivityLine.SetRange("Action Type", "Action Type");
            WarehouseActivityLine.SetRange("No.", "No.");
            WarehouseActivityLine.SetRange("Item No.", "Item No.");
            WarehouseActivityLine.SetRange("Variant Code", "Variant Code");
            WarehouseActivityLine.SetFilter("Line No.", '<>%1', "Line No.");
            WarehouseActivityLine.SetRange("Serial No.", "Serial No.");
            if not WarehouseActivityLine.IsEmpty() then
                Error(Text018, TableCaption(), FieldCaption("Serial No."), "Serial No.");
        end;
    end;

    local procedure InitTrackingSpecFromWhseActivLine(var TrackingSpecification: Record "Tracking Specification"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        TrackingSpecification.Init();
        if WarehouseActivityLine."Source Type" = ProdOrderComponentSourceID() then
            TrackingSpecification.SetSource(
              WarehouseActivityLine."Source Type", WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.", WarehouseActivityLine."Source Subline No.", '', WarehouseActivityLine."Source Line No.")
        else
            TrackingSpecification.SetSource(
              WarehouseActivityLine."Source Type", WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.", WarehouseActivityLine."Source Line No.", '', 0);

        TrackingSpecification."Item No." := WarehouseActivityLine."Item No.";
        TrackingSpecification."Location Code" := WarehouseActivityLine."Location Code";
        TrackingSpecification.Description := WarehouseActivityLine.Description;
        TrackingSpecification."Variant Code" := WarehouseActivityLine."Variant Code";
        TrackingSpecification."Qty. per Unit of Measure" := WarehouseActivityLine."Qty. per Unit of Measure";
        TrackingSpecification.CopyTrackingFromWhseActivityLine(WarehouseActivityLine);
        TrackingSpecification."Expiration Date" := WarehouseActivityLine."Expiration Date";
        TrackingSpecification."Bin Code" := WarehouseActivityLine."Bin Code";
        TrackingSpecification."Qty. to Handle (Base)" := WarehouseActivityLine."Qty. to Handle (Base)";

        OnAfterInitTrackingSpecFromWhseActivLine(TrackingSpecification, WarehouseActivityLine);
    end;

    local procedure FindLotAndPackageNoBySerialNo(WhseItemTrackingSetup: Record "Item Tracking Setup")
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        CheckGlobalEntrySummary: Boolean;
        LotNo: Code[50];
        PackageNo: Code[50];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindLotNoBySerialNo(Rec, IsHandled);
        if IsHandled then
            exit;

        InitTrackingSpecFromWhseActivLine(TempTrackingSpecification, Rec);
        CheckGlobalEntrySummary :=
          ("Activity Type" <> "Activity Type"::"Put-away") and
          (not ("Source Document" in
                ["Source Document"::"Purchase Order", "Source Document"::"Prod. Output", "Source Document"::"Assembly Order", "Source Document"::"Job Usage"]));
        if CheckGlobalEntrySummary then begin
            if WhseItemTrackingSetup."Lot No. Required" then
                Validate("Lot No.", ItemTrackingDataCollection.FindLotNoBySN(TempTrackingSpecification));
            if WhseItemTrackingSetup."Package No. Required" then
                Validate("Package No.", ItemTrackingDataCollection.FindPackageNoBySN(TempTrackingSpecification));
        end else begin
            if not ItemTrackingDataCollection.FindLotNoBySNSilent(LotNo, TempTrackingSpecification) then
                LotNo := TempTrackingSpecification."Lot No.";
            if not ItemTrackingDataCollection.FindPackageNoBySNSilent(PackageNo, TempTrackingSpecification) then
                PackageNo := TempTrackingSpecification."Package No.";
            Validate("Lot No.", LotNo);
            Validate("Package No.", PackageNo);
        end;
    end;

    local procedure CheckInvalidBinCode()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        Location: Record Location;
        Direction: Text[1];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckInvalidBinCode(Rec, IsHandled);
        if IsHandled then
            exit;

        Location.Get("Location Code");
        if ("Action Type" = "Action Type"::" ") or (not Location."Bin Mandatory") then
            exit;
        WarehouseActivityLine := Rec;
        WarehouseActivityLine.SetRange("Activity Type", "Activity Type");
        WarehouseActivityLine.SetRange("No.", "No.");
        WarehouseActivityLine.SetRange("Whse. Document Line No.", "Whse. Document Line No.");
        WarehouseActivityLine.SetFilter("Action Type", '<>%1', "Action Type");
        if "Action Type" = "Action Type"::Take then
            Direction := '>'
        else
            Direction := '<';
        if WarehouseActivityLine.Find(Direction) then begin
            if ("Location Code" = WarehouseActivityLine."Location Code") and
               ("Bin Code" = WarehouseActivityLine."Bin Code") and
               ("Unit of Measure Code" = WarehouseActivityLine."Unit of Measure Code")
            then
                Error(Text019, Format("Action Type"), Format(WarehouseActivityLine."Action Type"), Location.Code);

            if (("Activity Type" = "Activity Type"::"Put-away") and ("Action Type" = "Action Type"::Place) and
                Location.IsBWReceive() or ("Activity Type" = "Activity Type"::Pick) and
                ("Action Type" = "Action Type"::Take) and Location.IsBWShip()) and Location.IsBinBWReceiveOrShip("Bin Code")
            then
                Error(Text020, Format("Action Type"), Location.Code);
        end;
    end;

    local procedure RegisteredWhseActLineIsEmpty(): Boolean
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        RegisteredWhseActivityLine.SetRange("Activity Type", "Activity Type"::Pick);
        RegisteredWhseActivityLine.SetRange("Source No.", "Source No.");
        RegisteredWhseActivityLine.SetRange("Source Line No.", "Source Line No.");
        RegisteredWhseActivityLine.SetRange("Source Type", "Source Type");
        RegisteredWhseActivityLine.SetRange("Source Subtype", "Source Subtype");
        RegisteredWhseActivityLine.SetTrackingFilterFromWhseActivityLine(Rec);
        exit(RegisteredWhseActivityLine.IsEmpty());
    end;

    internal procedure UpdateSpecialEquipment()
    begin
        Validate("Special Equipment Code", GetSpecialEquipment());
    end;

    local procedure GetSpecialEquipment(): Code[10]
    begin
        GetLocation("Location Code");
        case Location."Special Equipment" of
            Location."Special Equipment"::"According to Bin":
                begin
                    if GetBin(Location.Code, "Bin Code") then
                        if Bin."Special Equipment Code" <> '' then
                            exit(Bin."Special Equipment Code");

                    if GetSKU("Location Code", "Item No.", "Variant Code") then
                        if SKU."Special Equipment Code" <> '' then
                            exit(SKU."Special Equipment Code");

                    GetItem();
                    exit(Item."Special Equipment Code");
                end;

            Location."Special Equipment"::"According to SKU/Item":
                begin
                    if GetSKU("Location Code", "Item No.", "Variant Code") then
                        if SKU."Special Equipment Code" <> '' then
                            exit(SKU."Special Equipment Code");

                    GetItem();
                    if Item."Special Equipment Code" <> '' then
                        exit(Item."Special Equipment Code");

                    if GetBin(Location.Code, "Bin Code") then
                        exit(Bin."Special Equipment Code")
                end
        end;
    end;

    local procedure GetSKU(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]): Boolean
    begin
        if (SKU."Location Code" <> LocationCode) or (SKU."Item No." <> ItemNo) or (SKU."Variant Code" <> VariantCode) then begin
            SKU.SetLoadFields("Location Code", "Item No.", "Variant Code", "Special Equipment Code");
            if not SKU.Get(LocationCode, ItemNo, VariantCode) then begin
                Clear(SKU);
                exit(false);
            end;
        end;
        exit(true);
    end;

    procedure ShowItemAvailabilityByPeriod()
    begin
        WarehouseAvailabilityMgt.ShowItemAvailabilityFromWhseActivLine(Rec, "Item Availability Type"::Period);
    end;

    procedure ShowItemAvailabilityByVariant()
    begin
        WarehouseAvailabilityMgt.ShowItemAvailabilityFromWhseActivLine(Rec, "Item Availability Type"::Variant);
    end;

    procedure ShowItemAvailabilityByLocation()
    begin
        WarehouseAvailabilityMgt.ShowItemAvailabilityFromWhseActivLine(Rec, "Item Availability Type"::Location);
    end;

    procedure ShowItemAvailabilityByEvent()
    begin
        WarehouseAvailabilityMgt.ShowItemAvailabilityFromWhseActivLine(Rec, "Item Availability Type"::"Event");
    end;

    local procedure ShowDeletedMessage(WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        WarehouseActivityLine2: Record "Warehouse Activity Line";
        IsHandled: Boolean;
    begin
        WarehouseActivityLine2.Reset();
        WarehouseActivityLine2.SetRange("Activity Type", WarehouseActivityLine."Activity Type");
        WarehouseActivityLine2.SetRange("No.", WarehouseActivityLine."No.");
        if not WarehouseActivityLine2.IsEmpty() then begin
            IsHandled := false;
            OnBeforeShowDeletedMessage(WarehouseActivityLine2, IsHandled);
            if not IsHandled then
                SendDeleteWarehouseActivityLineNotification();
        end;

        OnAfterShowDeletedMessage(WarehouseActivityLine2);
    end;

    local procedure ConfirmWhseActivLinesDeletionRecreate(WarehouseActivityLine: Record "Warehouse Activity Line"; var WhseWorksheetLine: Record "Whse. Worksheet Line"): Boolean
    var
        IsHandled: Boolean;
    begin
        WhseWorksheetLine.SetRange("Whse. Document Type", WarehouseActivityLine."Whse. Document Type");
        WhseWorksheetLine.SetRange("Whse. Document No.", WarehouseActivityLine."Whse. Document No.");
        WhseWorksheetLine.SetRange("Whse. Document Line No.", WarehouseActivityLine."Whse. Document Line No.");
        if not WhseWorksheetLine.IsEmpty() then begin
            IsHandled := false;
            OnBeforeConfirmWhseActivLinesDeletionRecreate(WarehouseActivityLine, IsHandled);
            if not IsHandled then
                if not Confirm(Text009, false, WarehouseActivityLine.TableCaption()) then
                    Error(Text006);
            exit(true);
        end;
        exit(false);
    end;

    local procedure ConfirmWhseActivLinesDeletionOutOfBalance(WarehouseActivityLine: Record "Warehouse Activity Line"; var WarehouseActivityLine2: Record "Warehouse Activity Line"; var DeleteLineConfirmed: Boolean)
    var
        WarehouseActivityLine3: Record "Warehouse Activity Line";
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        WarehouseActivityLine2.SetRange("Whse. Document Type", WarehouseActivityLine."Whse. Document Type");
        WarehouseActivityLine2.SetRange("Whse. Document No.", WarehouseActivityLine."Whse. Document No.");
        WarehouseActivityLine2.SetRange("Whse. Document Line No.", WarehouseActivityLine."Whse. Document Line No.");
        WarehouseActivityLine2.SetRange("Breakbulk No.", WarehouseActivityLine."Breakbulk No.");
        WarehouseActivityLine2.SetRange("Source No.", WarehouseActivityLine."Source No.");
        WarehouseActivityLine2.SetRange("Source Line No.", WarehouseActivityLine."Source Line No.");
        WarehouseActivityLine2.SetRange("Source Subline No.", WarehouseActivityLine."Source Subline No.");
        WarehouseActivityLine2.SetTrackingFilterFromWhseActivityLine(WarehouseActivityLine);
        if WarehouseActivityLine2.Find('-') then begin
            WarehouseActivityLine3.Copy(WarehouseActivityLine2);
            WarehouseActivityLine3.SetRange("Action Type", WarehouseActivityLine."Action Type");
            WarehouseActivityLine3.SetFilter("Line No.", '<>%1', WarehouseActivityLine."Line No.");
            OnConfirmWhseActivLinesDeletionOutOfBalanceOnAfterWhseActivLine3SetFilters(WarehouseActivityLine, WarehouseActivityLine2, WarehouseActivityLine3);
            if not WarehouseActivityLine3.IsEmpty() then begin
                IsHandled := false;
                OnBeforeConfirmWhseActivLinesDeletionOutOfBalance(WarehouseActivityLine2, IsHandled);
                if not IsHandled then
                    if not DeleteLineConfirmed then
                        if not ConfirmManagement.GetResponseOrDefault(
                             StrSubstNo(
                               Text004,
                               WarehouseActivityLine.FieldCaption("Activity Type"), WarehouseActivityLine."Activity Type", WarehouseActivityLine2.FieldCaption(WarehouseActivityLine2."No."), WarehouseActivityLine2."No.",
                               WarehouseActivityLine.FieldCaption("Line No."), WarehouseActivityLine."Line No.", WarehouseActivityLine."Action Type",
                               WarehouseActivityLine.TableCaption()),
                             false)
                        then
                            Error(Text006);

                DeleteLineConfirmed := true;
            end;
        end;
    end;

    procedure ActivityExists(SourceType: Integer; SourceSubtype: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer; ActivityType: Option): Boolean
    begin
        if ActivityType <> 0 then
            SetRange("Activity Type", ActivityType);
        SetSourceFilter(SourceType, SourceSubtype, SourceNo, SourceLineNo, SourceSublineNo, false);
        exit(not IsEmpty());
    end;

    procedure TrackingExists() IsTrackingExist: Boolean
    begin
        IsTrackingExist := ("Lot No." <> '') or ("Serial No." <> '');

        OnAfterTrackingExists(Rec, IsTrackingExist);
    end;

    procedure SetSource(SourceType: Integer; SourceSubtype: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer)
    begin
        "Source Type" := SourceType;
        "Source Subtype" := SourceSubtype;
        "Source No." := SourceNo;
        "Source Line No." := SourceLineNo;
        "Source Subline No." := SourceSublineNo;
    end;

    procedure SetSourceFilter(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; SetKey: Boolean)
    begin
        if SetKey then
            SetCurrentKey(Rec."Source Type", Rec."Source Subtype", Rec."Source No.", Rec."Source Line No.", Rec."Source Subline No.");
        SetRange("Source Type", SourceType);
        if SourceSubType >= 0 then
            SetRange("Source Subtype", SourceSubType);
        SetRange("Source No.", SourceNo);
        SetRange("Source Line No.", SourceLineNo);
        if SourceSubLineNo >= 0 then
            SetRange("Source Subline No.", SourceSubLineNo);

        OnAfterSetSourceFilter(Rec, SourceType, SourceSubtype, SourceNo, SourceLineNo, SourceSubLineNo, SetKey);
    end;

    procedure SetSumLinesFilters(WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        SetCurrentKey("Activity Type", "No.", "Bin Code", "Breakbulk No.", "Action Type");
        SetRange("Activity Type", WarehouseActivityLine."Activity Type");
        SetRange("No.", WarehouseActivityLine."No.");
        SetRange("Bin Code", WarehouseActivityLine."Bin Code");
        SetRange("Item No.", WarehouseActivityLine."Item No.");
        SetRange("Action Type", WarehouseActivityLine."Action Type");
        SetRange("Variant Code", WarehouseActivityLine."Variant Code");
        SetRange("Unit of Measure Code", WarehouseActivityLine."Unit of Measure Code");
        SetRange("Due Date", WarehouseActivityLine."Due Date");
    end;

    procedure ClearSourceFilter()
    begin
        SetRange("Source Type");
        SetRange("Source Subtype");
        SetRange("Source No.");
        SetRange("Source Line No.");
        SetRange("Source Subline No.");
    end;

    procedure ClearTracking()
    begin
        "Serial No." := '';
        "Lot No." := '';
        "Expiration Date" := 0D;

        OnAfterClearTracking(Rec);
    end;

    procedure ClearTrackingFilter()
    begin
        SetRange("Serial No.");
        SetRange("Lot No.");

        OnAfterClearTrackingFilter(Rec);
    end;

    procedure CopyTrackingFromSpec(TrackingSpecification: Record "Tracking Specification")
    begin
        "Serial No." := TrackingSpecification."Serial No.";
        "Lot No." := TrackingSpecification."Lot No.";
        "Expiration Date" := TrackingSpecification."Expiration Date";

        OnAfterCopyTrackingFromSpec(Rec, TrackingSpecification);
    end;

    procedure CopyTrackingFromItemTrackingSetup(WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        "Serial No." := WhseItemTrackingSetup."Serial No.";
        "Lot No." := WhseItemTrackingSetup."Lot No.";

        OnAfterCopyTrackingFromItemTrackingSetup(Rec, WhseItemTrackingSetup);
    end;

    procedure CopyTrackingFromPostedWhseRcptLine(PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
        "Serial No." := PostedWhseReceiptLine."Serial No.";
        "Lot No." := PostedWhseReceiptLine."Lot No.";

        OnAfterCopyTrackingFromPostedWhseRcptLine(Rec, PostedWhseReceiptLine);
    end;

    procedure CopyTrackingFromWhseItemTrackingLine(WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        "Serial No." := WhseItemTrackingLine."Serial No.";
        "Lot No." := WhseItemTrackingLine."Lot No.";

        OnAfterCopyTrackingFromWhseItemTrackingLine(Rec, WhseItemTrackingLine);
    end;

    procedure CopyTrackingFromWhseActivityLine(WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        "Serial No." := WarehouseActivityLine."Serial No.";
        "Lot No." := WarehouseActivityLine."Lot No.";

        OnAfterCopyTrackingFromWhseActivityLine(Rec, WarehouseActivityLine);
    end;

    procedure SetTrackingFilterIfNotEmpty()
    begin
        if "Serial No." <> '' then
            SetRange("Serial No.", "Serial No.");
        if "Lot No." <> '' then
            SetRange("Lot No.", "Lot No.");

        OnAfterSetTrackingFilterIfNotEmpty(Rec);
    end;

    procedure SetTrackingFilterFromBinContent(var BinContent: Record "Bin Content")
    begin
        SetFilter("Serial No.", BinContent.GetFilter("Serial No. Filter"));
        SetFilter("Lot No.", BinContent.GetFilter("Lot No. Filter"));

        OnAfterSetTrackingFilterFromBinContent(Rec, BinContent);
    end;

    procedure SetTrackingFilterFromBinContentBuffer(BinContentBuffer: Record "Bin Content Buffer")
    begin
        SetRange("Serial No.", BinContentBuffer."Serial No.");
        SetRange("Lot No.", BinContentBuffer."Lot No.");

        OnAfterSetTrackingFilterFromBinContentBuffer(Rec, BinContentBuffer);
    end;

    procedure SetTrackingFilterFromItemTrackingSetup(ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        SetRange("Serial No.", ItemTrackingSetup."Serial No.");
        SetRange("Lot No.", ItemTrackingSetup."Lot No.");

        OnAfterSetTrackingFilterFromItemTrackingSetup(Rec, ItemTrackingSetup);
    end;

    procedure SetTrackingFilterFromReservEntry(ReservationEntry: Record "Reservation Entry")
    begin
        SetRange("Serial No.", ReservationEntry."Serial No.");
        SetRange("Lot No.", ReservationEntry."Lot No.");

        OnAfterSetTrackingFilterFromReservEntry(Rec, ReservationEntry);
    end;

    procedure SetTrackingFilterFromReservEntryIfRequired(ReservationEntry: Record "Reservation Entry")
    begin
        if ReservationEntry."Serial No." <> '' then
            SetRange("Serial No.", ReservationEntry."Serial No.");
        if ReservationEntry."Lot No." <> '' then
            SetRange("Lot No.", ReservationEntry."Lot No.");

        OnAfterSetTrackingFilterFromReservEntryIfRequired(Rec, ReservationEntry);
    end;

    procedure SetTrackingFilterFromWhseItemTrackingLineIfNotBlank(WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
        if WhseItemTrackingLine."Serial No." <> '' then
            SetRange("Serial No.", WhseItemTrackingLine."Serial No.");
        if WhseItemTrackingLine."Lot No." <> '' then
            SetRange("Lot No.", WhseItemTrackingLine."Lot No.");

        OnAfterSetTrackingFilterFromWhseItemTrackingLineIfNotBlank(Rec, WhseItemTrackingLine);
    end;

    procedure SetTrackingFilterFromWhseActivityLine(WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        SetRange("Serial No.", WarehouseActivityLine."Serial No.");
        SetRange("Lot No.", WarehouseActivityLine."Lot No.");

        OnAfterSetTrackingFilterFromWhseActivityLine(Rec, WarehouseActivityLine);
    end;

    procedure SetTrackingFilterFromWhseItemTrackingSetup(WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Serial No. Required" then
            SetRange("Serial No.", WhseItemTrackingSetup."Serial No.")
        else
            SetFilter("Serial No.", '%1|%2', WhseItemTrackingSetup."Serial No.", '');
        if WhseItemTrackingSetup."Lot No. Required" then
            SetRange("Lot No.", WhseItemTrackingSetup."Lot No.")
        else
            SetFilter("Lot No.", '%1|%2', WhseItemTrackingSetup."Lot No.", '');

        OnAfterSetTrackingFilterFromWhseItemTrackingSetup(Rec, WhseItemTrackingSetup);
    end;

    procedure SetTrackingFilterFromWhseItemTrackingSetupifNotBlank(WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Serial No." <> '' then
            if WhseItemTrackingSetup."Serial No. Required" then
                SetRange("Serial No.", WhseItemTrackingSetup."Serial No.")
            else
                SetFilter("Serial No.", '%1|%2', WhseItemTrackingSetup."Serial No.", '');
        if WhseItemTrackingSetup."Lot No." <> '' then
            if WhseItemTrackingSetup."Lot No. Required" then
                SetRange("Lot No.", WhseItemTrackingSetup."Lot No.")
            else
                SetFilter("Lot No.", '%1|%2', WhseItemTrackingSetup."Lot No.", '');

        OnAfterSetTrackingFilterFromWhseItemTrackingSetupifNotBlank(Rec, WhseItemTrackingSetup);
    end;

    procedure SetTrackingFilterToItemIfRequired(var Item: Record Item; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if "Lot No." <> '' then begin
            if WhseItemTrackingSetup."Lot No. Required" then
                Item.SetRange("Lot No. Filter", "Lot No.")
            else
                Item.SetFilter("Lot No. Filter", '%1|%2', "Lot No.", '')
        end else
            Item.SetRange("Lot No. Filter");
        if "Serial No." <> '' then begin
            if WhseItemTrackingSetup."Serial No. Required" then
                Item.SetRange("Serial No. Filter", "Serial No.")
            else
                Item.SetFilter("Serial No. Filter", '%1|%2', "Serial No.", '');
        end else
            Item.SetRange("Serial No. Filter");

        OnAfterSetTrackingFilterToItemIfRequired(Rec, Item, WhseItemTrackingSetup);
    end;

    procedure SetTrackingFilterToItemLedgEntryIfRequired(var ItemLedgerEntry: Record "Item Ledger Entry"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if "Serial No." <> '' then
            if WhseItemTrackingSetup."Serial No. Required" then
                ItemLedgerEntry.SetRange("Serial No.", "Serial No.")
            else
                ItemLedgerEntry.SetFilter("Serial No.", '%1|%2', "Serial No.", '');
        if "Lot No." <> '' then
            if WhseItemTrackingSetup."Lot No. Required" then
                ItemLedgerEntry.SetRange("Lot No.", "Lot No.")
            else
                ItemLedgerEntry.SetFilter("Lot No.", '%1|%2', "Lot No.", '');

        OnAfterSetTrackingFilterToItemLedgEntryIfRequired(Rec, ItemLedgerEntry, WhseItemTrackingSetup);
    end;

    procedure SetTrackingFilterToWhseEntryIfRequired(var WhseEntry: Record "Warehouse Entry"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if "Serial No." <> '' then
            if WhseItemTrackingSetup."Serial No. Required" then
                WhseEntry.SetRange("Serial No.", "Serial No.")
            else
                WhseEntry.SetFilter("Serial No.", '%1|%2', "Serial No.", '');
        if "Lot No." <> '' then
            if WhseItemTrackingSetup."Lot No. Required" then
                WhseEntry.SetRange("Lot No.", "Lot No.")
            else
                WhseEntry.SetFilter("Lot No.", '%1|%2', "Lot No.", '');

        OnAfterSetTrackingFilterToWhseEntryIfRequired(Rec, WhseEntry, WhseItemTrackingSetup);
    end;

    procedure TestTrackingIfRequired(WhseItemTrackingSetup: Record "Item Tracking Setup")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestTrackingIfRequired(Rec, WhseItemTrackingSetup, IsHandled);
        if not IsHandled then begin
            if WhseItemTrackingSetup."Serial No. Required" then begin
                TestField("Serial No.");
                TestField("Qty. (Base)", 1);
            end;
            if WhseItemTrackingSetup."Lot No. Required" then
                TestField("Lot No.");
        end;

        OnAfterTestTrackingIfRequired(Rec, WhseItemTrackingSetup);
    end;

    procedure HasRequiredTracking(WhseItemTrackingSetup: Record "Item Tracking Setup") Result: Boolean
    begin
        Result := true;

        if WhseItemTrackingSetup."Serial No. Required" <> ("Serial No." <> '') then
            Result := false;
        if WhseItemTrackingSetup."Lot No. Required" <> ("Lot No." <> '') then
            Result := false;

        OnAfterHasRequiredTracking(Rec, WhseItemTrackingSetup, Result);
    end;

    local procedure ReNumberWhseActivityLines(var NewWarehouseActivityLine: Record "Warehouse Activity Line"; var WarehouseActivityLine: Record "Warehouse Activity Line"; var NewLineNo: Integer; var LineSpacing: Integer)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReNumberWhseActivityLines(NewWarehouseActivityLine, WarehouseActivityLine, NewLineNo, LineSpacing, IsHandled);
        if IsHandled then
            exit;

        ReNumberAllLines(NewWarehouseActivityLine, WarehouseActivityLine."Line No.", NewLineNo);
        WarehouseActivityLine.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.", NewLineNo);
        LineSpacing := 5000;
    end;

    local procedure ReNumberAllLines(var NewWarehouseActivityLine: Record "Warehouse Activity Line"; OldLineNo: Integer; var NewLineNo: Integer)
    var
        TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary;
        OldLineNos: Dictionary of [Integer, Integer];
        LineNo: Integer;
    begin
        NewWarehouseActivityLine.FindSet();
        repeat
            LineNo += 10000;
            TempWarehouseActivityLine := NewWarehouseActivityLine;
            TempWarehouseActivityLine."Line No." := LineNo;
            TempWarehouseActivityLine.Insert();
            if not OldLineNos.ContainsKey(NewWarehouseActivityLine."Line No.") then
                OldLineNos.Add(LineNo, NewWarehouseActivityLine."Line No.");
            if NewWarehouseActivityLine."Line No." = OldLineNo then
                NewLineNo := LineNo;
        until NewWarehouseActivityLine.Next() = 0;
        NewWarehouseActivityLine.DeleteAll();

        TempWarehouseActivityLine.FindSet();
        repeat
            NewWarehouseActivityLine := TempWarehouseActivityLine;
            NewWarehouseActivityLine.Insert();
            if OldLineNos.ContainsKey(NewWarehouseActivityLine."Line No.") then
                OnAfterReNumberWhseActivLine(NewWarehouseActivityLine, OldLineNos.Get(NewWarehouseActivityLine."Line No."));
        until TempWarehouseActivityLine.Next() = 0;
    end;

    procedure TrackingFilterExists() IsTrackingFilterExist: Boolean
    begin
        IsTrackingFilterExist := (GetFilter("Serial No.") <> '') or (GetFilter("Lot No.") <> '');
        OnAfterTrackingFilterExists(Rec, IsTrackingFilterExist);
    end;

    procedure ValidateQtyWhenSNDefined()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateQtyWhenSNDefined(Rec, IsHandled);
        if IsHandled then
            exit;

        if Rec."Serial No." = '' then
            exit;

        if not (Rec."Qty. (Base)" in [-1, 0, 1]) then
            Error(ValidValuesIfSNDefinedErr, Rec.FieldCaption("Qty. (Base)"), Rec."Qty. (Base)");

        if not (Rec."Qty. to Handle (Base)" in [-1, 0, 1]) then
            Error(ValidValuesIfSNDefinedErr, Rec.FieldCaption("Qty. to Handle (Base)"), Rec."Qty. to Handle (Base)");
    end;

    local procedure ValidateQuantityIsBalanced()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateQuantityIsBalanced(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        UOMMgt.ValidateQtyIsBalanced(Quantity, "Qty. (Base)", "Qty. to Handle", "Qty. to Handle (Base)", "Qty. Handled", "Qty. Handled (Base)");
    end;

    local procedure RunWhsePickCard(var WarehouseActivityHeader: Record "Warehouse Activity Header")
    var
        WarehousePick: Page "Warehouse Pick";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRunWhsePickCard(WarehouseActivityHeader, IsHandled);
        if IsHandled then
            exit;

        WarehousePick.SetTableView(WarehouseActivityHeader);
        WarehousePick.RunModal();
    end;

    local procedure CalcBaseQty(Qty: Decimal; FromFieldName: Text; ToFieldName: Text): Decimal
    begin
        OnBeforeCalcBaseQty(Rec, Qty, FromFieldName, ToFieldName);

        exit(
            UOMMgt.CalcBaseQty(
                "Item No.", "Variant Code", "Unit of Measure Code", Qty, "Qty. per Unit of Measure", "Qty. Rounding Precision (Base)", FieldCaption("Qty. Rounding Precision"), FromFieldName, ToFieldName));
    end;

    local procedure ShouldLookupBinContent(): Boolean
    begin
        exit(
            ("Activity Type".AsInteger() <= "Activity Type"::Movement.AsInteger()) or
            ("Action Type" <> "Action Type"::Place));
    end;

    procedure Lock()
    begin
        LockTable();
        if FindLast() then;
    end;

    procedure ResetQtyToHandleOnReservation()
    begin
        if ("Qty. to Handle" = 0) and TrackingExists() then
            if RegisteredWhseActLineIsEmpty() then
                if ItemTrackingMgt.GetWhseItemTrkgSetup("Item No.") then
                    UpdateReservation(Rec, false);
    end;

    procedure TestNonSpecificItemTracking()
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        ItemTrackingSetup: Record "Item Tracking Setup";
        NonWhseItemTrackingSetup: Record "Item Tracking Setup";
        ItemLedgerEntryType: Enum "Item Ledger Entry Type";
    begin
        case "Source Document" of
            "Source Document"::"Sales Order":
                ItemLedgerEntryType := ItemLedgerEntryType::Sale;
            "Source Document"::"Purchase Return Order":
                ItemLedgerEntryType := ItemLedgerEntryType::Purchase;
            "Source Document"::"Outbound Transfer":
                ItemLedgerEntryType := ItemLedgerEntryType::Transfer;
            "Source Document"::"Prod. Consumption":
                ItemLedgerEntryType := ItemLedgerEntryType::Consumption;
            "Source Document"::"Assembly Consumption":
                ItemLedgerEntryType := ItemLedgerEntryType::"Assembly Consumption";
            else
                exit;
        end;

        GetItem();
        ItemTrackingMgt.GetWhseItemTrkgSetup("Item No.", WhseItemTrackingSetup);
        ItemTrackingMgt.GetItemTrackingSetup(ItemTrackingCode, ItemLedgerEntryType, false, ItemTrackingSetup);

        NonWhseItemTrackingSetup.Code := ItemTrackingCode.Code;
        NonWhseItemTrackingSetup.GetNonWarehouseTrackingRequirements(WhseItemTrackingSetup, ItemTrackingSetup);

        TestTrackingIfRequired(NonWhseItemTrackingSetup);
    end;

    internal procedure CopyItemTrackingToRelatedLine(xWhseActivLine: Record "Warehouse Activity Line"; FieldNo: Integer)
    var
        WarehouseActivityLine2: Record "Warehouse Activity Line";
        IsHandled: Boolean;
    begin
        OnBeforeCopyItemTrackingToRelatedLine(Rec, xWhseActivLine, FieldNo, IsHandled);
        if IsHandled then
            exit;

        if ("Activity Type" in ["Activity Type"::"Invt. Put-away", "Activity Type"::"Invt. Pick"]) then
            exit;

        if "Action Type" <> "Action Type"::Take then
            exit;

        if "Sorting Sequence No." <> 0 then
            WarehouseActivityLine2.SetCurrentKey("Activity Type", "No.", "Sorting Sequence No.");
        WarehouseActivityLine2."Activity Type" := "Activity Type";
        WarehouseActivityLine2."No." := "No.";
        WarehouseActivityLine2."Line No." := "Line No.";
        WarehouseActivityLine2."Sorting Sequence No." := "Sorting Sequence No.";
        WarehouseActivityLine2.SetRange("Whse. Document Type", "Whse. Document Type");
        WarehouseActivityLine2.SetRange("Whse. Document No.", "Whse. Document No.");
        WarehouseActivityLine2.SetRange("Whse. Document Line No.", "Whse. Document Line No.");
        WarehouseActivityLine2.SetRange("Breakbulk No.", "Breakbulk No.");
        WarehouseActivityLine2.SetRange("Source No.", "Source No.");
        WarehouseActivityLine2.SetRange("Source Line No.", "Source Line No.");
        WarehouseActivityLine2.SetRange("Source Subline No.", "Source Subline No.");
        WarehouseActivityLine2.SetRange("Action Type", WarehouseActivityLine2."Action Type"::Place);
        WarehouseActivityLine2.SetTrackingFilterFromWhseActivityLine(xWhseActivLine);
        WarehouseActivityLine2.SetRange("Qty. (Base)", "Qty. (Base)");
        if WarehouseActivityLine2.Find('><') then begin
            WarehouseActivityLine2.CopyTrackingFromWhseActivityLine(Rec);
            WarehouseActivityLine2."Expiration Date" := 0D;
            WarehouseActivityLine2.UpdateExpirationDate(FieldNo);
            WarehouseActivityLine2."Warranty Date" := "Warranty Date";
            WarehouseActivityLine2.Modify();
        end;
    end;

    procedure UpdateExpirationDate(FieldNo: Integer)
    var
        ExpDate: Date;
        EntriesExist: Boolean;
    begin
        if (FieldNo = FieldNo("Lot No.")) and ("Lot No." <> '') or
           (FieldNo = FieldNo("Serial No.")) and ("Serial No." <> '') or
           (FieldNo = FieldNo("Package No.")) and ("Package No." <> '')
        then
            ExpDate := ItemTrackingMgt.ExistingExpirationDate(Rec, false, EntriesExist);

        if ExpDate <> 0D then
            "Expiration Date" := ExpDate;
    end;

    local procedure GetDeleteWarehouseActivityLineNotificationID(): Guid
    begin
        exit('963A9FD3-11E8-4CAA-BE3A-7F8CEC9EF8ED');
    end;

    local procedure SendDeleteWarehouseActivityLineNotification()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        NotificationToSend: Notification;
    begin
        if not GuiAllowed() then
            exit;

        NotificationToSend.Id := GetDeleteWarehouseActivityLineNotificationID();
        NotificationToSend.Recall();
        NotificationToSend.Message := Text013;
        NotificationLifecycleMgt.SendNotification(NotificationToSend, RecordId());
    end;

    local procedure UpdateDoNotFillQtyToHandle(WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        if not WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.") then
            exit;

        if not WarehouseActivityHeader."Do Not Fill Qty. to Handle" then
            exit;

        WarehouseActivityHeader."Do Not Fill Qty. to Handle" := false;
        WarehouseActivityHeader.Modify();
    end;

    local procedure UpdateQtyOnRelatedPlaceLine(FromWhseActivityLine: Record "Warehouse Activity Line"; xWhseActivityLine: Record "Warehouse Activity Line")
    var
        Item: Record Item;
        WhseActivityLine: Record "Warehouse Activity Line";
        QuantityUpdated: Boolean;
    begin
        if CurrFieldNo = 0 then
            exit;

        if FromWhseActivityLine."Source Document" <> FromWhseActivityLine."Source Document"::"Prod. Consumption" then
            exit;

        if FromWhseActivityLine."Activity Type" <> FromWhseActivityLine."Activity Type"::Pick then
            exit;

        if (xWhseActivityLine.Quantity = 0) and (FromWhseActivityLine.Quantity <> 0) then
            exit;

        if (xWhseActivityLine.Quantity <> 0) and (FromWhseActivityLine.Quantity = 0) then
            FromWhseActivityLine.TestField(Quantity);

        if FromWhseActivityLine."Qty. Outstanding (Base)" < 0 then
            Error(OutstandingQtyCannotbeLessThanZeroErr);

        Item.SetLoadFields("No.", "Allow Whse. Overpick");
        Item.Get(FromWhseActivityLine."Item No.");
        Item.TestField("Allow Whse. Overpick");

        SetFilterFromWhseActivityLineToUpdateQty(WhseActivityLine, FromWhseActivityLine, xWhseActivityLine, QuantityUpdated);
        if QuantityUpdated then
            WhseActivityLine.Modify(true);
    end;

    local procedure SetFilterFromWhseActivityLineToUpdateQty(
        var WhseActivityLine: Record "Warehouse Activity Line";
        FromWhseActivityLine: Record "Warehouse Activity Line";
        xWhseActivityLine: Record "Warehouse Activity Line";
        var QuantityUpdated: Boolean)
    begin
        WhseActivityLine.SetLoadFields("Activity Type", "No.", "Line No.", "Item No.", "Variant Code", "Location Code", "Action Type", Quantity, "Lot No.", "Serial No.", "Source No.", "Source Line No.", "Source Document");
        WhseActivityLine.SetRange("Activity Type", FromWhseActivityLine."Activity Type");
        WhseActivityLine.SetRange("No.", FromWhseActivityLine."No.");
        WhseActivityLine.SetFilter("Line No.", '>%1', FromWhseActivityLine."Line No.");
        WhseActivityLine.SetRange("Item No.", FromWhseActivityLine."Item No.");
        WhseActivityLine.SetRange("Variant Code", FromWhseActivityLine."Variant Code");
        WhseActivityLine.SetRange("Location Code", FromWhseActivityLine."Location Code");
        WhseActivityLine.SetRange("Action Type", WhseActivityLine."Action Type"::Place);
        WhseActivityLine.SetRange(Quantity, xWhseActivityLine.Quantity);
        WhseActivityLine.SetRange("Lot No.", FromWhseActivityLine."Lot No.");
        WhseActivityLine.SetRange("Serial No.", FromWhseActivityLine."Serial No.");
        WhseActivityLine.SetRange("Source Document", FromWhseActivityLine."Source Document");
        WhseActivityLine.SetRange("Source No.", FromWhseActivityLine."Source No.");
        WhseActivityLine.SetRange("Source Line No.", FromWhseActivityLine."Source Line No.");
        if WhseActivityLine.FindFirst() then begin
            WhseActivityLine.Validate(Quantity, FromWhseActivityLine.Quantity);
            QuantityUpdated := true;
            exit;
        end;

        WhseActivityLine.SetRange("Line No.");
        WhseActivityLine.SetFilter("Line No.", '<>%1', FromWhseActivityLine."Line No.");
        if WhseActivityLine.FindFirst() then begin
            WhseActivityLine.Validate(Quantity, FromWhseActivityLine.Quantity);
            QuantityUpdated := true;
        end
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAutofillQtyToHandle(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAutofillQtyToHandleLine(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearTracking(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterClearTrackingFilter(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromSpec(var WarehouseActivityLine: Record "Warehouse Activity Line"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromItemTrackingSetup(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromPostedWhseRcptLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; PostedWhseRcptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromWhseItemTrackingLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyTrackingFromWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; FromWarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteQtyToHandle(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitTrackingSpecFromWhseActivLine(var TrackingSpecification: Record "Tracking Specification"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLookupTrackingSummary(var WarehouseActivityLine: Record "Warehouse Activity Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; TrackingType: Enum "Item Tracking Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterIfNotEmpty(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromItemTrackingSetup(var WarehouseActivityLine: Record "Warehouse Activity Line"; ItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromBinContent(var WarehouseActivityLine: Record "Warehouse Activity Line"; var BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromBinContentBuffer(var WarehouseActivityLine: Record "Warehouse Activity Line"; var BinContentBuffer: Record "Bin Content Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromReservEntry(var WarehouseActivityLine: Record "Warehouse Activity Line"; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromReservEntryIfRequired(var WarehouseActivityLine: Record "Warehouse Activity Line"; ReservEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; FromWarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromWhseItemTrackingLineIfNotBlank(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromWhseItemTrackingSetupifNotBlank(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterFromWhseItemTrackingSetup(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterToItemIfRequired(var WarehouseActivityLine: Record "Warehouse Activity Line"; var Item: Record Item; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterToItemLedgEntryIfRequired(var WarehouseActivityLine: Record "Warehouse Activity Line"; var ItemLedgerEntry: Record "Item Ledger Entry"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetTrackingFilterToWhseEntryIfRequired(var WarehouseActivityLine: Record "Warehouse Activity Line"; var WhseEntry: Record "Warehouse Entry"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDeletedMessage(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSplitLines(var WarehouseActivityLine: Record "Warehouse Activity Line"; NewWarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTrackingFilterExists(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsTrackingFilterExist: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromShptLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromIntPickLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseInternalPickLine: Record "Whse. Internal Pick Line")
    begin
    end;

#if not CLEAN26
    internal procedure RunOnAfterTransferFromCompLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
        OnAfterTransferFromCompLine(WarehouseActivityLine, ProdOrderComponent);
    end;

    [Obsolete('Moved to codeunit ProdOrderWarehouseMgt', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromCompLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromAssemblyLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferAllButWhseDocDetailsFromAssemblyLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromMovWkshLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromPickWkshLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestTrackingIfRequired(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHasRequiredTracking(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTrackingExists(WarehouseActivityLine: Record "Warehouse Activity Line"; var IsTrackingExist: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateQtyToHandleWhseActivLine(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutofillQtyToHandle(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcQty(var WarehouseActivityLine: Record "Warehouse Activity Line"; QtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBinInSourceDoc(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckBinInSourceDoc(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckReservedItemTrkg(var WarehouseActivityLine: Record "Warehouse Activity Line"; CheckType: Enum "Item Tracking Type"; ItemTrkgCode: Code[50]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckExceedQtyAvailBase(var WarehouseActivityLine: Record "Warehouse Activity Line"; QtyAvailBase: Decimal; NewBinCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN26
    internal procedure RunOnBeforeCheckBinCodeFromProdOrderCompLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ProdOrderCompLine: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var IsHandled: Boolean)
    begin
        OnBeforeCheckBinCodeFromProdOrderCompLine(WarehouseActivityLine, ProdOrderCompLine, IsHandled);
    end;

    [Obsolete('Moved to codeunit ProdOrderWarehouseMgt', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBinCodeFromProdOrderCompLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; ProdOrderCompLine: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckBinCodeFromWhseShptLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseShptLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckInvalidBinCode(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckLine(WhseActivLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWhseDocLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSNSpecificationExists(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmWhseActivLinesDeletionRecreate(WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConfirmWhseActivLinesDeletionOutOfBalance(WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSplitLines(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteRelatedWhseActivLines(var WhseActivLine: Record "Warehouse Activity Line"; CalledFromHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteQtyToHandle(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteWhseActivLine2(var WarehouseActivityLine2: Record "Warehouse Activity Line"; CalledFromHeader: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindBinCode(var WarehouseActivityLine: Record "Warehouse Activity Line"; var Item: Record Item; var BinCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindBinContent(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindLotNoBySerialNo(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetUOMCode(var WarehouseActivityLine: Record "Warehouse Activity Line"; var UOMCode: Code[10]; var IsHandled: Boolean; Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertNewWhseActivLine(var NewWarehouseActivityLine: Record "Warehouse Activity Line"; var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookUpTrackingSummary(WhseActivLine: Record "Warehouse Activity Line"; TrackingType: Enum "Item Tracking Type"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyOldWhseActivLine(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetWhseItemTrkgLineFiltersWhseShipment(var WarehouseActivityLine: Record "Warehouse Activity Line"; var WhseItemTrkgLine: Record "Whse. Item Tracking Line"; WhseActivLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDeletedMessage(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowWhseDoc(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowWhseDoc(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQtyToHandle(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateSerialNo(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateLotNo(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQtyOutstanding(var WarehouseActivityLine: Record "Warehouse Activity Line"; xWarehouseActivityLine: Record "Warehouse Activity Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateVariantCode(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQtyBase(var WarehouseActivityLine: Record "Warehouse Activity Line"; xWarehouseActivityLine: Record "Warehouse Activity Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnChangeUOMCodeOnBeforeRecModify(var WarehouseActivityLine: Record "Warehouse Activity Line"; Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateNewUOMLineOnBeforeNewWhseActivLineInsert(var NewWarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateNewUOMLineOnBeforeNewWhseActivLineModify(var NewWarehouseActivityLine: Record "Warehouse Activity Line"; var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookUpTrackingSummaryOnAfterAssistEditTrackingNo(var WarehouseActivityLine: Record "Warehouse Activity Line"; var TrackingSpecification: Record "Tracking Specification"; TrackingType: Enum "Item Tracking Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookUpTrackingSummaryOnAfterCheckDataSet(WarehouseActivityLine: Record "Warehouse Activity Line"; Item: Record Item; var TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookUpTrackingSummaryOnAfterAssignSerialNoTracking(var WarehouseActivityLine: Record "Warehouse Activity Line"; TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLookUpTrackingSummaryOnAfterAssignLotNoTracking(var WarehouseActivityLine: Record "Warehouse Activity Line"; TempTrackingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBinCodeOnAfterGetBin(var WarehouseActivityLine: Record "Warehouse Activity Line"; Bin: Record Bin)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBinCodeOnAfterCalcQtyAvailBase(var WarehouseActivityLine: Record "Warehouse Activity Line"; QtyAvailBase: Decimal; NewBinCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnAfterValidateUoMCode(var WarehouseActivityLine: Record "Warehouse Activity Line"; Item: Record Item; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQtyToHandleOnAfterCalcQtyToHandleBase(var WarehouseActivityLine: Record "Warehouse Activity Line"; QtyToHandleBase: Decimal; var NewQtyToHandleBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQtyToHandleOnBeforeCalcQtyToHandleBase(var WarehouseActivityLine: Record "Warehouse Activity Line"; var xWarehouseActivityLine: Record "Warehouse Activity Line"; Location: Record Location; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVariantCodeOnAfterGetItemVariant(var WarehouseActivityLine: Record "Warehouse Activity Line"; ItemVariant: Record "Item Variant"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCheckBin(var Bin: Record Bin; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeChangeUOMCode(var WhseActivLine: Record "Warehouse Activity Line"; var WhseActivLine2: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeReNumberWhseActivityLines(var NewWarehouseActivityLine: Record "Warehouse Activity Line"; var WarehouseActivityLine: Record "Warehouse Activity Line"; var NewLineNo: Integer; var LineSpacing: Integer; var sHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantityIsBalanced(var WhseActivLine: Record "Warehouse Activity Line"; xWhseActivLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQtyWhenSNDefined(WhseActivLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckReservedItemTrkgOnCheckTypeElseCase(var WarehouseActivityLine: Record "Warehouse Activity Line"; CheckType: Enum "Item Tracking Type"; ItemTrkgCode: Code[50])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteRelatedWhseActivLinesOnBeforeWhseActivLine2Find(var WhseActivLine: Record "Warehouse Activity Line"; var WhseActivLine2: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteRelatedWhseActivLinesOnBeforeConfirmWhseActivLinesDeletionOutOfBalance(WhseActivLine: record "Warehouse Activity Line"; CalledFromHeader: Boolean; var DeleteLineConfirmed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteRelatedWhseActivLinesOnBeforeDeleteWhseActivLine2(var WarehouseActivityLine: Record "Warehouse Activity Line"; var WarehouseActivityLine2: Record "Warehouse Activity Line"; var CalledFromHeader: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckIncreaseCapacityOnBeforeCheckIncreaseBinContent(var WarehouseActivityLine: Record "Warehouse Activity Line"; var Bin: Record Bin; DeductCubage: Decimal; DeductWeight: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateBinCodeOnAfterCheckInvalidBinCode(var WarehouseActivityLine: Record "Warehouse Activity Line"; xWarehouseActivityLine: Record "Warehouse Activity Line"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunWhsePickCard(var WhseActivHeader: Record "Warehouse Activity Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnConfirmWhseActivLinesDeletionOutOfBalanceOnAfterWhseActivLine3SetFilters(var WhseActivLine: Record "Warehouse Activity Line"; var WhseActivLine2: Record "Warehouse Activity Line"; var WhseActivLine3: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckReservedItemTrkg(var WarehouseActivityLine: Record "Warehouse Activity Line"; xRec: Record "Warehouse Activity Line"; CurrFieldNo: Integer; LineReservedQty: Integer; ReservedQty: Decimal)
    begin
        // use ReservedQty parameter instead of LineReservedQty for the same purpose
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitLineOnBeforeRenumberAllLines(var WarehouseActivityLine: Record "Warehouse Activity Line"; var LineSpacing: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSplitLineOnAfterInitNewWhseActivLine(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateReservationOnBeforeTempTrackingSpecificationInsert(var TempTrackingSpecification: Record "Tracking Specification" temporary; var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnUpdateQtyToHandleOnBeforeWhseActivLineModify(var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteBinContent(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromJobPlanningLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetSourceFilter(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceType: Integer; SourceSubtype: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; SetKey: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcBaseQty(var WarehouseActivityLine: Record "Warehouse Activity Line"; var Qty: Decimal; FromFieldName: Text; ToFieldName: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteRelatedWhseActivLinesOnAfterUpdateRelatedItemTrkg(var WarehouseActivityLine: Record "Warehouse Activity Line"; var WarehouseActivityLine2: Record "Warehouse Activity Line"; var CalledFromHeader: Boolean)
    begin
    end;

#pragma warning disable AS0077
    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestTrackingIfRequired(WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup"; var IsHandled: Boolean)
    begin
    end;
#pragma warning restore AS0077

    [IntegrationEvent(false, false)]
    local procedure OnCheckSplitLineOnBeforeTestFieldActionType(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure CheckWhseDocLineOnCheckSourceDocument(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseDocType: Enum "Warehouse Activity Document Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateRelatedItemTrkgForInvtMovement(var WarehouseActivityLine: Record "Warehouse Activity Line"; var WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateQtyToHandleOnSplitLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterReNumberWhseActivLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; OldLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyItemTrackingToRelatedLine(WarehouseActivityLine: Record "Warehouse Activity Line"; xWarehouseActivityLine: Record "Warehouse Activity Line"; FieldNo: Integer; var IsHandled: Boolean)
    begin
    end;
}

