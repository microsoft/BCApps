// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Worksheet;

table 5407 "Prod. Order Component"
{
    Caption = 'Prod. Order Component';
    DataCaptionFields = Status, "Prod. Order No.";
    DrillDownPageID = "Prod. Order Comp. Line List";
    LookupPageID = "Prod. Order Comp. Line List";
    Permissions = TableData "Prod. Order Component" = rimd;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Status; Enum "Production Order Status")
        {
            Caption = 'Status';

            trigger OnValidate()
            begin
                ProdOrderWarehouseMgt.ProdComponentVerifyChange(Rec, xRec);
            end;
        }
        field(2; "Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No.';
            TableRelation = "Production Order"."No." where(Status = field(Status));
        }
        field(3; "Prod. Order Line No."; Integer)
        {
            Caption = 'Prod. Order Line No.';
            TableRelation = "Prod. Order Line"."Line No." where(Status = field(Status),
                                                                 "Prod. Order No." = field("Prod. Order No."));
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(11; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item where(Type = filter(Inventory | "Non-Inventory"));

            trigger OnValidate()
            begin
                if xRec.Find() then begin
                    CalcFields("Act. Consumption (Qty)");
                    TestField("Act. Consumption (Qty)", 0);
                end;
                ProdOrderWarehouseMgt.ProdComponentVerifyChange(Rec, xRec);
                ProdOrderCompReserve.VerifyChange(Rec, xRec);
                CalcFields("Reserved Qty. (Base)");
                TestField("Reserved Qty. (Base)", 0);
                TestField("Remaining Qty. (Base)", "Expected Qty. (Base)");
                if "Item No." = '' then begin
                    CreateDimFromDefaultDim();
                    exit;
                end;

                Item.Get("Item No.");
                Item.TestField(Blocked, false);
                if "Item No." <> xRec."Item No." then begin
                    "Variant Code" := '';
                    OnValidateItemNoOnBeforeGetDefaultBin(Rec, Item);
                    GetDefaultBin();
                    ClearCalcFormula();
                    if "Quantity per" <> 0 then
                        Validate("Quantity per");
                end;
                Description := Item.Description;
                UpdateUOMFromItem(Item);
                OnValidateItemNoOnAfterUpdateUOMFromItem(Rec, xRec, Item);
                GetUpdateFromSKU();
                CreateDimFromDefaultDim();
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(12; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(13; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            begin
                ProdOrderWarehouseMgt.ProdComponentVerifyChange(Rec, xRec);

                Item.Get("Item No.");
                GetGLSetup();

                "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
                "Qty. Rounding Precision" := UOMMgt.GetQtyRoundingPrecision(Item, "Unit of Measure Code");
                "Qty. Rounding Precision (Base)" := UOMMgt.GetQtyRoundingPrecision(Item, Item."Base Unit of Measure");

                "Quantity (Base)" := CalcBaseQty(Quantity, FieldCaption(Quantity), FieldCaption("Quantity (Base)"));

                UpdateUnitCost();

                UpdateExpectedQuantity();
            end;
        }
        field(14; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(15; Position; Code[10])
        {
            Caption = 'Position';
        }
        field(16; "Position 2"; Code[10])
        {
            Caption = 'Position 2';
        }
        field(17; "Position 3"; Code[10])
        {
            Caption = 'Position 3';
        }
        field(18; "Lead-Time Offset"; DateFormula)
        {
            Caption = 'Lead-Time Offset';
        }
        field(19; "Routing Link Code"; Code[10])
        {
            Caption = 'Routing Link Code';
            TableRelation = "Routing Link";

            trigger OnValidate()
            var
                ProdOrderLine: Record "Prod. Order Line";
                ProdOrderRoutingLine: Record "Prod. Order Routing Line";
                IsHandled: Boolean;
            begin
                UpdateExpectedQuantity();

                ProdOrderLine.Get(Status, "Prod. Order No.", "Prod. Order Line No.");

                IsHandled := false;
                OnValidateRoutingLinkCodeOnBeforeUpdateDueDateAndTime(Rec, ProdOrderLine, ProdOrderRoutingLine, IsHandled);
                if not IsHandled then begin
                    "Due Date" := ProdOrderLine."Starting Date";
                    "Due Time" := ProdOrderLine."Starting Time";
                    if "Routing Link Code" <> '' then begin
                        ProdOrderRoutingLine.SetRange(Status, Status);
                        ProdOrderRoutingLine.SetRange("Prod. Order No.", "Prod. Order No.");
                        ProdOrderRoutingLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
                        ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
                        ProdOrderRoutingLine.SetRange("Routing Link Code", "Routing Link Code");
                        if ProdOrderRoutingLine.FindFirst() then begin
                            "Due Date" := ProdOrderRoutingLine."Starting Date";
                            "Due Time" := ProdOrderRoutingLine."Starting Time";
                        end;
                    end;
                end;
                if Format("Lead-Time Offset") <> '' then begin
                    "Due Date" :=
                      "Due Date" -
                      (CalcDate("Lead-Time Offset", WorkDate()) - WorkDate());
                    "Due Time" := 0T;
                end;

                OnValidateRoutingLinkCodeBeforeValidateDueDate(Rec, ProdOrderLine, ProdOrderRoutingLine);
                Validate("Due Date");

                if "Routing Link Code" <> xRec."Routing Link Code" then
                    UpdateBin(Rec, FieldNo("Routing Link Code"), FieldCaption("Routing Link Code"));
            end;
        }
        field(20; "Scrap %"; Decimal)
        {
            Caption = 'Scrap %';
            DecimalPlaces = 0 : 5;
            MaxValue = 100;
            MinValue = 0;

            trigger OnValidate()
            begin
                Validate("Calculation Formula");
            end;
        }
        field(21; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            begin
                if Item."No." <> "Item No." then
                    Item.Get("Item No.");
                AssignDescriptionFromItemOrVariantAndCheckVariantNotBlocked();
                GetDefaultBin();
                ProdOrderWarehouseMgt.ProdComponentVerifyChange(Rec, xRec);
                ProdOrderCompReserve.VerifyChange(Rec, xRec);
                CalcFields("Reserved Qty. (Base)");
                TestField("Reserved Qty. (Base)", 0);
                TestField("Remaining Qty. (Base)", "Expected Qty. (Base)");
                UpdateUnitCost();
                Validate("Expected Quantity");
                GetUpdateFromSKU();
            end;
        }
        field(22; "Qty. Rounding Precision"; Decimal)
        {
            Caption = 'Qty. Rounding Precision';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(23; "Qty. Rounding Precision (Base)"; Decimal)
        {
            Caption = 'Qty. Rounding Precision (Base)';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(25; "Expected Quantity"; Decimal)
        {
            Caption = 'Expected Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            var
                ItemUnitOfMeasure: Record "Item Unit of Measure";
                UnroundedExpectedQuantity: Decimal;
                ItemPrecRoundedExpectedQuantity: Decimal;
                BaseUOMPrecRoundedExpectedQuantity: Decimal;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateExpectedQuantity(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                UnroundedExpectedQuantity := "Expected Quantity";
                if Item.Get("Item No.") then
                    if Item."Rounding Precision" > 0 then
                        RoundExpectedQuantity();

                ItemPrecRoundedExpectedQuantity := "Expected Quantity";

                BaseUOMPrecRoundedExpectedQuantity := UOMMgt.RoundQty("Expected Quantity", "Qty. Rounding Precision");

                if ("Qty. Rounding Precision" > 0) and (BaseUOMPrecRoundedExpectedQuantity <> ItemPrecRoundedExpectedQuantity) then
                    if UnroundedExpectedQuantity <> ItemPrecRoundedExpectedQuantity then
                        Error(WrongPrecisionItemAndUOMExpectedQtyErr, Item.FieldCaption("Rounding Precision"), Item.TableCaption(), ItemUnitOfMeasure.FieldCaption("Qty. Rounding Precision"), ItemUnitOfMeasure.TableCaption(), Rec.FieldCaption("Expected Quantity"))
                    else
                        Error(WrongPrecOnUOMExpectedQtyErr, ItemUnitOfMeasure.FieldCaption("Qty. Rounding Precision"), ItemUnitOfMeasure.TableCaption(), Rec.FieldCaption("Expected Quantity"));

                "Expected Quantity" := BaseUOMPrecRoundedExpectedQuantity;
                "Expected Qty. (Base)" := CalcBaseQty("Expected Quantity", FieldCaption("Expected Quantity"), FieldCaption("Expected Qty. (Base)"));

                // Recalculate 'Expected Quantity' based on the base value to make sure values are consistent
                "Expected Quantity" := UOMMgt.RoundQty("Expected Qty. (Base)" / "Qty. per Unit of Measure", "Qty. Rounding Precision");

                if (Status in [Status::Released, Status::Finished]) and
                   (xRec."Item No." <> '') and
                   ("Line No." <> 0)
                then
                    CalcFields("Act. Consumption (Qty)");

                OnValidateExpectedQuantityOnAfterCalcActConsumptionQty(Rec, xRec);
                "Remaining Quantity" := "Expected Quantity" - "Act. Consumption (Qty)" / "Qty. per Unit of Measure";
                "Remaining Quantity" := UOMMgt.RoundQty("Remaining Quantity", "Qty. Rounding Precision");

                if ("Remaining Quantity" * "Expected Quantity") <= 0 then
                    "Remaining Quantity" := 0;
                "Remaining Qty. (Base)" := CalcBaseQty("Remaining Quantity", FieldCaption("Remaining Quantity"), FieldCaption("Remaining Qty. (Base)"));
                UpdateCompletelyPicked();

                ProdOrderCompReserve.VerifyQuantity(Rec, xRec);

                "Cost Amount" := Round("Expected Quantity" * "Unit Cost");
                "Overhead Amount" :=
                  Round(
                    "Expected Quantity" *
                    (("Direct Unit Cost" * "Indirect Cost %" / 100) + "Overhead Rate"));
                "Direct Cost Amount" := Round("Expected Quantity" * "Direct Unit Cost");
            end;
        }
        field(26; "Remaining Quantity"; Decimal)
        {
            Caption = 'Remaining Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(27; "Act. Consumption (Qty)"; Decimal)
        {
            AccessByPermission = TableData "Production Order" = R;
            CalcFormula = - sum("Item Ledger Entry".Quantity where("Entry Type" = const(Consumption),
                                                                   "Order Type" = const(Production),
                                                                   "Order No." = field("Prod. Order No."),
                                                                   "Order Line No." = field("Prod. Order Line No."),
                                                                   "Prod. Order Comp. Line No." = field("Line No.")));
            Caption = 'Act. Consumption (Qty)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(28; "Flushing Method"; Enum "Flushing Method")
        {
            Caption = 'Flushing Method';

            trigger OnValidate()
            var
                ItemLedgEntry: Record "Item Ledger Entry";
                PickWhseWorksheetLine: Record "Whse. Worksheet Line";
#if not CLEAN26
                ManufacturingSetup: Record "Manufacturing Setup";
#endif
                PickQtyCheckNeeded, WhseWorksheetLineExistCheckNeeded : Boolean;
            begin
                if ("Flushing Method" = "Flushing Method"::Backward) and (Status = Status::Released) then begin
                    ItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type"::Production);
                    ItemLedgEntry.SetRange("Order No.", "Prod. Order No.");
                    ItemLedgEntry.SetRange("Order Line No.", "Prod. Order Line No.");
                    ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Consumption);
                    ItemLedgEntry.SetRange("Prod. Order Comp. Line No.", "Line No.");
                    if "Line No." = 0 then
                        ItemLedgEntry.SetRange("Item No.", "Item No.");
                    if not ItemLedgEntry.IsEmpty() then
                        Error(Text99000002, "Flushing Method", ItemLedgEntry.TableCaption());
                end;

#if not CLEAN26
                if not ManufacturingSetup.IsFeatureKeyFlushingMethodManualWithoutPickEnabled() then begin
                    PickQtyCheckNeeded :=
                        ("Flushing Method" <> xRec."Flushing Method") and
                        (xRec."Flushing Method" in
                            [xRec."Flushing Method"::Manual, xRec."Flushing Method"::"Pick + Manual", xRec."Flushing Method"::"Pick + Forward", xRec."Flushing Method"::"Pick + Backward"]);
                    WhseWorksheetLineExistCheckNeeded :=
                        (xRec."Flushing Method" in
                            [xRec."Flushing Method"::Manual, xRec."Flushing Method"::"Pick + Manual", xRec."Flushing Method"::"Pick + Forward", xRec."Flushing Method"::"Pick + Backward"]) and
                        ("Flushing Method" in
                            ["Flushing Method"::Forward, "Flushing Method"::Backward]);
                end else begin
#endif
                    PickQtyCheckNeeded :=
                        ("Flushing Method" <> xRec."Flushing Method") and
                        (xRec."Flushing Method" in
                            [xRec."Flushing Method"::"Pick + Manual", xRec."Flushing Method"::"Pick + Forward", xRec."Flushing Method"::"Pick + Backward"]);
                    WhseWorksheetLineExistCheckNeeded :=
                        (xRec."Flushing Method" in
                            [xRec."Flushing Method"::"Pick + Manual", xRec."Flushing Method"::"Pick + Forward", xRec."Flushing Method"::"Pick + Backward"]) and
                        ("Flushing Method" in
                            ["Flushing Method"::Manual, "Flushing Method"::Forward, "Flushing Method"::Backward]);
#if not CLEAN26
                end;
#endif
                if PickQtyCheckNeeded then begin
                    CalcFields("Pick Qty.");
                    if "Pick Qty." <> 0 then
                        Error(Text99000007, "Flushing Method", "Item No.");

                    if "Qty. Picked" <> 0 then
                        Error(Text99000008, "Flushing Method", "Item No.");

                    if WhseWorksheetLineExistCheckNeeded then begin
                        PickWhseWorksheetLine.SetRange("Source Type", Database::"Prod. Order Component");
                        PickWhseWorksheetLine.SetRange("Source No.", "Prod. Order No.");
                        PickWhseWorksheetLine.SetRange("Source Line No.", "Prod. Order Line No.");
                        PickWhseWorksheetLine.SetRange("Source Subline No.", "Line No.");
                        if not PickWhseWorksheetLine.IsEmpty() then
                            Error(Text99000002, "Flushing Method", PickWhseWorksheetLine.TableCaption());
                    end;
                end;

                if "Flushing Method" <> xRec."Flushing Method" then
                    UpdateBin(Rec, FieldNo("Flushing Method"), FieldCaption("Flushing Method"));
            end;
        }
        field(30; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));

            trigger OnValidate()
            begin
                if Item."No." <> "Item No." then
                    Item.Get("Item No.");

                UpdateUnitCost();
                Validate("Expected Quantity");

                if Item.IsInventoriableType() then begin
                    GetDefaultBin();
                    ProdOrderWarehouseMgt.ProdComponentVerifyChange(Rec, xRec);
                end;
                ProdOrderCompReserve.VerifyChange(Rec, xRec);
                GetUpdateFromSKU();
                CreateDimFromDefaultDim();
            end;
        }
        field(31; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(32; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2),
                                                          Blocked = const(false));

            trigger OnValidate()
            begin
                Rec.ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(33; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));

            trigger OnLookup()
            var
                WMSManagement: Codeunit "WMS Management";
                BinCode: Code[20];
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeBinCodeOnLookup(Rec, IsHandled);
                if IsHandled then
                    exit;

                if Item.Get(Rec."Item No.") then
                    if BinCode <> '' then
                        Item.TestField(Type, Item.Type::Inventory);

                if Quantity > 0 then
                    BinCode := WMSManagement.BinContentLookUp("Location Code", "Item No.", "Variant Code", '', "Bin Code")
                else
                    BinCode := WMSManagement.BinLookUp("Location Code", "Item No.", "Variant Code", '');

                if BinCode <> '' then
                    Validate("Bin Code", BinCode);
            end;

            trigger OnValidate()
            var
                WMSManagement: Codeunit "WMS Management";
                WhseIntegrationMgt: Codeunit "Whse. Integration Management";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateBinCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                if "Bin Code" <> '' then begin
                    TestField("Location Code");
                    WMSManagement.FindBin("Location Code", "Bin Code", '');
                    WhseIntegrationMgt.CheckBinTypeAndCode(
                        Database::"Prod. Order Component", FieldCaption("Bin Code"), "Location Code", "Bin Code", 0);
                    CheckBin();
                end;
            end;
        }
        field(35; "Supplied-by Line No."; Integer)
        {
            Caption = 'Supplied-by Line No.';
            TableRelation = "Prod. Order Line"."Line No." where(Status = field(Status),
                                                                 "Prod. Order No." = field("Prod. Order No."),
                                                                 "Line No." = field("Supplied-by Line No."));
        }
        field(36; "Planning Level Code"; Integer)
        {
            Caption = 'Planning Level Code';
            Editable = false;
        }
        field(37; "Item Low-Level Code"; Integer)
        {
            Caption = 'Item Low-Level Code';
        }
        field(40; Length; Decimal)
        {
            Caption = 'Length';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Validate("Calculation Formula");
            end;
        }
        field(41; Width; Decimal)
        {
            Caption = 'Width';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Validate("Calculation Formula");
            end;
        }
        field(42; Weight; Decimal)
        {
            Caption = 'Weight';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Validate("Calculation Formula");
            end;
        }
        field(43; Depth; Decimal)
        {
            Caption = 'Depth';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Validate("Calculation Formula");
            end;
        }
        field(44; "Calculation Formula"; Enum "Quantity Calculation Formula")
        {
            Caption = 'Calculation Formula';

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateCalculationFormula(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                CalculateQuantity(Quantity);
                if "Qty. Rounding Precision" < 1 then
                    Quantity := UOMMgt.RoundAndValidateQty(Quantity, "Qty. Rounding Precision", FieldCaption(Quantity))
                else
                    Quantity := UOMMgt.RoundToItemRndPrecision(Quantity, "Qty. Rounding Precision");

                OnValidateCalculationFormulaOnAfterSetQuantity(Rec);
                "Quantity (Base)" := CalcBaseQty(Quantity, FieldCaption(Quantity), FieldCaption("Quantity (Base)"));
                UpdateExpectedQuantity();
            end;
        }
        field(45; "Quantity per"; Decimal)
        {
            Caption = 'Quantity per';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQuantityper(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                ProdOrderWarehouseMgt.ProdComponentVerifyChange(Rec, xRec);
                TestField("Item No.");
                Validate("Calculation Formula");
            end;
        }
        field(50; "Unit Cost"; Decimal)
        {
            Caption = 'Unit Cost';
            DecimalPlaces = 2 : 5;

            trigger OnValidate()
            begin
                TestField("Item No.");

                Item.Get("Item No.");
                GetGLSetup();
                if Item."Costing Method" = Item."Costing Method"::Standard then begin
                    if CurrFieldNo = FieldNo("Unit Cost") then
                        Error(
                          Text99000003,
                          FieldCaption("Unit Cost"), Item.FieldCaption("Costing Method"), Item."Costing Method");
                    UpdateUnitCost();
                end;
                Validate("Calculation Formula");
            end;
        }
        field(51; "Cost Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Cost Amount';
            Editable = false;
        }
        field(52; "Due Date"; Date)
        {
            Caption = 'Due Date';

            trigger OnValidate()
            var
                MfgReservCheckDateConfl: Codeunit "Mfg. ReservCheckDateConfl";
            begin
                ProdOrderWarehouseMgt.ProdComponentVerifyChange(Rec, xRec);
                if not Blocked then
                    if CurrFieldNo <> 0 then
                        MfgReservCheckDateConfl.ProdOrderComponentCheck(Rec, true, true)
                    else
                        if MfgReservCheckDateConfl.ProdOrderComponentCheck(Rec, not WarningRaised, false) then
                            WarningRaised := true;
                UpdateDatetime();
            end;
        }
        field(53; "Due Time"; Time)
        {
            Caption = 'Due Time';

            trigger OnValidate()
            begin
                UpdateDatetime();
            end;
        }
        field(60; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(61; "Remaining Qty. (Base)"; Decimal)
        {
            Caption = 'Remaining Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(62; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
        }
        field(63; "Reserved Qty. (Base)"; Decimal)
        {
            CalcFormula = - sum("Reservation Entry"."Quantity (Base)" where("Source ID" = field("Prod. Order No."),
                                                                            "Source Ref. No." = field("Line No."),
                                                                            "Source Type" = const(5407),
#pragma warning disable AL0603
                                                                            "Source Subtype" = field(Status),
#pragma warning restore
                                                                            "Source Batch Name" = const(''),
                                                                            "Source Prod. Order Line" = field("Prod. Order Line No."),
                                                                            "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = true;
            FieldClass = FlowField;
        }
        field(71; "Reserved Quantity"; Decimal)
        {
            CalcFormula = - sum("Reservation Entry".Quantity where("Source ID" = field("Prod. Order No."),
                                                                   "Source Ref. No." = field("Line No."),
                                                                   "Source Type" = const(5407),
#pragma warning disable AL0603
                                                                   "Source Subtype" = field(Status),
#pragma warning restore
                                                                   "Source Batch Name" = const(''),
                                                                   "Source Prod. Order Line" = field("Prod. Order Line No."),
                                                                   "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(73; "Expected Qty. (Base)"; Decimal)
        {
            Caption = 'Expected Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateExpectedQtyBase(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                if Status <> Status::Simulated then begin
                    if Status in [Status::Released, Status::Finished] then
                        CalcFields("Act. Consumption (Qty)");
                    OnValidateExpectedQtyBaseOnAfterCalcActConsumptionQty(Rec, xRec);
                    "Remaining Quantity" := "Expected Quantity" - "Act. Consumption (Qty)";
                    OnValidateExpectedQtyBaseOnAfterCalcRemainingQuantity(Rec, xRec);
                    "Remaining Qty. (Base)" := Round("Remaining Quantity" * "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
                end;
                "Cost Amount" := Round("Expected Quantity" * "Unit Cost");
                "Overhead Amount" :=
                  Round(
                    "Expected Quantity" *
                    (("Direct Unit Cost" * "Indirect Cost %" / 100) + "Overhead Rate"));
                "Direct Cost Amount" := Round("Expected Quantity" * "Direct Unit Cost");
            end;
        }
        field(76; "Due Date-Time"; DateTime)
        {
            Caption = 'Due Date-Time';

            trigger OnValidate()
            begin
                "Due Date" := DT2Date("Due Date-Time");
                "Due Time" := DT2Time("Due Date-Time");
                Validate("Due Date");
            end;
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;

            trigger OnValidate()
            begin
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(5702; "Substitution Available"; Boolean)
        {
            CalcFormula = exist("Item Substitution" where(Type = const(Item),
                                                           "Substitute Type" = const(Item),
                                                           "No." = field("Item No."),
                                                           "Variant Code" = field("Variant Code")));
            Caption = 'Substitution Available';
            Editable = false;
            FieldClass = FlowField;
        }
        field(5703; "Original Item No."; Code[20])
        {
            Caption = 'Original Item No.';
            Editable = false;
            TableRelation = Item;
        }
        field(5704; "Original Variant Code"; Code[10])
        {
            Caption = 'Original Variant Code';
            Editable = false;
            TableRelation = "Item Variant".Code where("Item No." = field("Original Item No."));
        }
        field(5750; "Pick Qty."; Decimal)
        {
            CalcFormula = sum("Warehouse Activity Line"."Qty. Outstanding" where("Activity Type" = filter(<> "Put-away"),
                                                                                  "Source Type" = const(5407),
#pragma warning disable AL0603
                                                                                  "Source Subtype" = field(Status),
#pragma warning restore
                                                                                  "Source No." = field("Prod. Order No."),
                                                                                  "Source Line No." = field("Prod. Order Line No."),
                                                                                  "Source Subline No." = field("Line No."),
                                                                                  "Unit of Measure Code" = field("Unit of Measure Code"),
                                                                                  "Action Type" = filter(" " | Place),
                                                                                  "Original Breakbulk" = const(false),
                                                                                  "Breakbulk No." = const(0)));
            Caption = 'Pick Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(7300; "Qty. Picked"; Decimal)
        {
            Caption = 'Qty. Picked';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                "Qty. Picked (Base)" :=
                    UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", "Qty. Picked", "Qty. per Unit of Measure");
                UpdateCompletelyPicked();
            end;
        }
        field(7301; "Qty. Picked (Base)"; Decimal)
        {
            Caption = 'Qty. Picked (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;

            trigger OnValidate()
            begin
                "Qty. Picked" :=
                  UOMMgt.CalcQtyFromBase("Item No.", "Variant Code", "Unit of Measure Code", "Qty. Picked (Base)", "Qty. per Unit of Measure");
                UpdateCompletelyPicked();
            end;
        }
        field(7302; "Completely Picked"; Boolean)
        {
            Caption = 'Completely Picked';
            Editable = false;
        }
        field(7303; "Pick Qty. (Base)"; Decimal)
        {
            CalcFormula = sum("Warehouse Activity Line"."Qty. Outstanding (Base)" where("Activity Type" = filter(<> "Put-away"),
                                                                                         "Source Type" = const(5407),
#pragma warning disable AL0603
                                                                                         "Source Subtype" = field(Status),
#pragma warning restore
                                                                                         "Source No." = field("Prod. Order No."),
                                                                                         "Source Line No." = field("Prod. Order Line No."),
                                                                                         "Source Subline No." = field("Line No."),
                                                                                         "Action Type" = filter(" " | Place),
                                                                                         "Original Breakbulk" = const(false),
                                                                                         "Breakbulk No." = const(0)));
            Caption = 'Pick Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(99000754; "Direct Unit Cost"; Decimal)
        {
            Caption = 'Direct Unit Cost';
            DecimalPlaces = 2 : 5;
        }
        field(99000755; "Indirect Cost %"; Decimal)
        {
            Caption = 'Indirect Cost %';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                "Direct Unit Cost" :=
                  Round(("Unit Cost" - "Overhead Rate") / (1 + "Indirect Cost %" / 100));

                Validate("Unit Cost");
            end;
        }
        field(99000756; "Overhead Rate"; Decimal)
        {
            Caption = 'Overhead Rate';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            begin
                Validate("Indirect Cost %");
            end;
        }
        field(99000757; "Direct Cost Amount"; Decimal)
        {
            Caption = 'Direct Cost Amount';
            DecimalPlaces = 2 : 2;
        }
        field(99000758; "Overhead Amount"; Decimal)
        {
            Caption = 'Overhead Amount';
            DecimalPlaces = 2 : 2;
        }
    }

    keys
    {
        key(Key1; Status, "Prod. Order No.", "Prod. Order Line No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Prod. Order No.", "Prod. Order Line No.", "Line No.", Status)
        {
        }
        key(Key3; Status, "Prod. Order No.", "Prod. Order Line No.", "Due Date")
        {
            SumIndexFields = "Expected Quantity", "Cost Amount";
        }
        key(Key4; Status, "Prod. Order No.", "Prod. Order Line No.", "Item No.", "Line No.")
        {
            MaintainSQLIndex = false;
        }
        key(Key5; Status, "Item No.", "Variant Code", "Location Code", "Due Date")
        {
            SumIndexFields = "Expected Quantity", "Remaining Qty. (Base)", "Cost Amount", "Overhead Amount";
        }
        key(Key6; "Item No.", "Variant Code", "Location Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Due Date")
        {
            Enabled = false;
            SumIndexFields = "Expected Quantity", "Remaining Qty. (Base)", "Cost Amount", "Overhead Amount";
        }
        key(Key7; Status, "Prod. Order No.", "Routing Link Code", "Flushing Method")
        {
        }
        key(Key8; Status, "Prod. Order No.", "Location Code")
        {
        }
        key(Key9; "Item No.", "Variant Code", "Location Code", Status, "Due Date")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Expected Qty. (Base)", "Remaining Qty. (Base)", "Cost Amount", "Overhead Amount", "Qty. Picked (Base)";
        }
        key(Key10; Status, "Prod. Order No.", "Prod. Order Line No.", "Item Low-Level Code")
        {
            MaintainSQLIndex = false;
        }
        key(Key11; "Supplied-by Line No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderBOMComment: Record "Prod. Order Comp. Cmt Line";
        ItemLedgEntry: Record "Item Ledger Entry";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        NewQuantity: Decimal;
        IsHandled: Boolean;
    begin
        if Status = Status::Finished then
            Error(Text000);
        if Status = Status::Released then begin
            ItemLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.", "Entry Type", "Prod. Order Comp. Line No.");
            ItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type"::Production);
            ItemLedgEntry.SetRange("Order No.", "Prod. Order No.");
            ItemLedgEntry.SetRange("Order Line No.", "Prod. Order Line No.");
            ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::Consumption);
            ItemLedgEntry.SetRange("Prod. Order Comp. Line No.", "Line No.");
            if not ItemLedgEntry.IsEmpty() then
                Error(Text99000000, "Item No.", "Line No.");

            ConfirmDeletion();
        end;

        ProdOrderWarehouseMgt.ProdComponentDelete(Rec);
        ProdOrderCompReserve.DeleteLine(Rec);

        CalcFields("Reserved Qty. (Base)");
        TestField("Reserved Qty. (Base)", 0);

        if "Supplied-by Line No." > 0 then begin
            IsHandled := false;
            OnDeleteOnBeforeGetProdOrderLine(Rec, IsHandled);
            if not IsHandled then
                if ProdOrderLine.Get(Status, "Prod. Order No.", "Supplied-by Line No.") then begin
                    NewQuantity := ProdOrderLine.Quantity - "Expected Quantity";
                    if (NewQuantity = 0) or IsLineRequiredForSingleDemand(ProdOrderLine, "Prod. Order Line No.") then begin
                        ProdOrderLine.SetCalledFromComponent(true);
                        ProdOrderLine.Delete(true);
                    end else begin
                        ProdOrderLine.Validate(Quantity, NewQuantity);
                        ProdOrderLine.Modify();
                        ProdOrderLine.UpdateProdOrderComp(ProdOrderLine."Qty. per Unit of Measure");
                    end;
                end;
        end;

        ProdOrderBOMComment.SetRange(Status, Status);
        ProdOrderBOMComment.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderBOMComment.SetRange("Prod. Order Line No.", "Prod. Order Line No.");
        ProdOrderBOMComment.SetRange("Prod. Order BOM Line No.", "Line No.");
        ProdOrderBOMComment.DeleteAll();

        WhseProdRelease.DeleteLine(Rec);

        ItemTrackingMgt.DeleteWhseItemTrkgLines(
            Database::"Prod. Order Component", Status.AsInteger(), "Prod. Order No.", '', "Prod. Order Line No.", "Line No.", "Location Code", true);
    end;

    trigger OnInsert()
    begin
        if Status = Status::Finished then
            Error(Text000);

        ProdOrderCompReserve.VerifyQuantity(Rec, xRec);

        if Status = Status::Released then
            WhseProdRelease.ReleaseLine(Rec, xRec);
    end;

    trigger OnModify()
    begin
        if Status = Status::Finished then
            Error(Text000);

        ProdOrderWarehouseMgt.ProdComponentVerifyChange(Rec, xRec);
        ProdOrderCompReserve.VerifyChange(Rec, xRec);
        if Status = Status::Released then
            WhseProdRelease.ReleaseLine(Rec, xRec);
    end;

    trigger OnRename()
    begin
        Error(Text99000001, TableCaption);
    end;

    var
#pragma warning disable AA0074
        Text000: Label 'A finished production order component cannot be inserted, modified, or deleted.';
#pragma warning disable AA0470
        Text001: Label 'The changed %1 now points to bin %2. Do you want to update the bin on this line?';
        Text99000000: Label 'You cannot delete item %1 in line %2 because at least one item ledger entry is associated with it.';
        Text99000001: Label 'You cannot rename a %1.';
        Text99000002: Label 'You cannot change flushing method to %1 when there is at least one record in table %2 associated with it.';
        Text99000003: Label 'You cannot change %1 when %2 is %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        WrongPrecisionItemAndUOMExpectedQtyErr: Label 'The value in the %1 field on the %2 page, and %3 field on the %4 page, are causing the rounding precision for the %5 field to be incorrect.', Comment = '%1 = field caption, %2 = table caption, %3 field caption, %4 = table caption, %5 = field caption';
        WrongPrecOnUOMExpectedQtyErr: Label 'The value in the %1 field on the %2 page is causing the rounding precision for the %3 field to be incorrect.', Comment = '%1 = field caption, %2 = table caption, %3 field caption';
        Item: Record Item;
        ReservEntry: Record "Reservation Entry";
        GLSetup: Record "General Ledger Setup";
        Location: Record Location;
        SKU: Record "Stockkeeping Unit";
        ReservMgt: Codeunit "Reservation Management";
        ProdOrderCompReserve: Codeunit "Prod. Order Comp.-Reserve";
        ProdOrderWarehouseMgt: Codeunit "Prod. Order Warehouse Mgt.";
        UOMMgt: Codeunit "Unit of Measure Management";
        DimMgt: Codeunit DimensionManagement;
        WhseProdRelease: Codeunit "Whse.-Production Release";
        Reservation: Page Reservation;
        Blocked: Boolean;
        GLSetupRead: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text99000007: Label 'You cannot change flushing method to %1 because a pick has already been created for production order component %2.';
        Text99000008: Label 'You cannot change flushing method to %1 because production order component %2 has already been picked.';
#pragma warning restore AA0470
        Text99000009: Label 'Automatic reservation is not possible.\Do you want to reserve items manually?';
#pragma warning restore AA0074
        ConfirmDeleteQst: Label '%1 = %2 is greater than %3 = %4. If you delete the %5, the items will remain in the operation area until you put them away.\Any related item tracking information defined during the pick process will be deleted.\Do you still want to delete the %5?', Comment = '%1 = FieldCaption("Qty. Picked"), %2 = "Qty. Picked", %3 = Qty. Posted, %4 = ("Expected Quantity" - "Remaining Quantity"), %5 = TableCaption';
        IgnoreErrors: Boolean;
        ErrorOccured: Boolean;
        WarningRaised: Boolean;
        CalledFromHeader: Boolean;

    procedure Caption(): Text
    var
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if not ProdOrder.Get(Status, "Prod. Order No.") then
            exit('');

        if not ProdOrderLine.Get(Status, "Prod. Order No.", "Prod. Order Line No.") then
            Clear(ProdOrderLine);

        exit(
          StrSubstNo('%1 %2 %3',
            "Prod. Order No.", ProdOrder.Description, ProdOrderLine."Item No."));
    end;

    local procedure UpdateCompletelyPicked()
    begin
        "Completely Picked" := ("Qty. Picked" >= "Expected Quantity") and ("Expected Quantity" >= 0);
    end;

    procedure ProdOrderNeeds(): Decimal
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        NeededQty: Decimal;
    begin
        ProdOrderLine.Get(Status, "Prod. Order No.", "Prod. Order Line No.");

        if "Due Date" = 0D then begin
            "Due Date" := ProdOrderLine."Starting Date";
            "Due Time" := ProdOrderLine."Starting Time";
            UpdateDatetime();
        end;

        ProdOrderRtngLine.Reset();
        ProdOrderRtngLine.SetRange(Status, Status);
        ProdOrderRtngLine.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderRtngLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        if "Routing Link Code" <> '' then
            ProdOrderRtngLine.SetRange("Routing Link Code", "Routing Link Code");
        if ProdOrderRtngLine.FindFirst() then
            NeededQty :=
              ProdOrderLine.Quantity * (1 + ProdOrderLine."Scrap %" / 100) *
              (1 + ProdOrderRtngLine."Scrap Factor % (Accumulated)") * (1 + "Scrap %" / 100) +
              ProdOrderRtngLine."Fixed Scrap Qty. (Accum.)"
        else
            NeededQty :=
              ProdOrderLine.Quantity * (1 + ProdOrderLine."Scrap %" / 100) * (1 + "Scrap %" / 100);

        OnAfterProdOrderNeeds(Rec, ProdOrderLine, ProdOrderRtngLine, NeededQty);

        exit(NeededQty);
    end;

    procedure GetNeededQty(CalcBasedOn: Option "Actual Output","Expected Output"; IncludePreviousPosting: Boolean): Decimal
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        CapLedgEntry: Record "Capacity Ledger Entry";
        MfgCostCalcMgt: Codeunit "Mfg. Cost Calculation Mgt.";
        OutputQtyBase: Decimal;
        CompQtyBase: Decimal;
        NeededQty: Decimal;
        RoundingPrecision: Decimal;
        IsHandled: Boolean;
    begin
        Item.Get("Item No.");
        RoundingPrecision := Item."Rounding Precision";
        if RoundingPrecision = 0 then
            RoundingPrecision := UOMMgt.QtyRndPrecision();

        OnGetNeededQtyOnBeforeCalcBasedOn(Rec, RoundingPrecision);
        if CalcBasedOn = CalcBasedOn::"Actual Output" then begin
            ProdOrderLine.Get(Status, "Prod. Order No.", "Prod. Order Line No.");

            ProdOrderRtngLine.SetRange(Status, Status);
            ProdOrderRtngLine.SetRange("Prod. Order No.", "Prod. Order No.");
            ProdOrderRtngLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
            ProdOrderRtngLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
            ProdOrderRtngLine.SetRange("Routing Link Code", "Routing Link Code");
            if not ProdOrderRtngLine.FindFirst() or ("Routing Link Code" = '') then begin
                ProdOrderRtngLine.SetRange("Routing Link Code");
                ProdOrderRtngLine.SetFilter("Next Operation No.", '%1', '');
                if not ProdOrderRtngLine.FindFirst() then
                    ProdOrderRtngLine."Operation No." := '';
                OnGetNeededQtyOnAfterLastOperationFound(Rec, ProdOrderRtngLine);
            end;
            if Status in [Status::Released, Status::Finished] then begin
                CapLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.");
                CapLedgEntry.SetRange("Order Type", CapLedgEntry."Order Type"::Production);
                CapLedgEntry.SetRange("Order No.", "Prod. Order No.");
                CapLedgEntry.SetRange("Order Line No.", "Prod. Order Line No.");
                CapLedgEntry.SetRange("Operation No.", ProdOrderRtngLine."Operation No.");
                if CapLedgEntry.Find('-') then
                    repeat
                        IsHandled := false;
                        OnGetNeededQtyOnBeforeAddOutputQtyBase(CapLedgEntry, OutputQtyBase, IsHandled, Rec);
                        if not IsHandled then
                            OutputQtyBase := OutputQtyBase + CapLedgEntry."Output Quantity" + CapLedgEntry."Scrap Quantity";
                    until CapLedgEntry.Next() = 0;
            end;

            CompQtyBase := MfgCostCalcMgt.CalcActNeededQtyBase(ProdOrderLine, Rec, OutputQtyBase);
            OnGetNeededQtyAfterCalcCompQtyBase(Rec, CompQtyBase, OutputQtyBase);

            NeededQty := UOMMgt.RoundToItemRndPrecision(CompQtyBase / "Qty. per Unit of Measure", RoundingPrecision);
            if IncludePreviousPosting then begin
                if Status in [Status::Released, Status::Finished] then
                    CalcFields("Act. Consumption (Qty)");
                OnGetNeededQtyAfterCalcActConsumptionQty(Rec);
                exit(NeededQty -
                  UOMMgt.RoundToItemRndPrecision("Act. Consumption (Qty)" / "Qty. per Unit of Measure", RoundingPrecision));
            end;
            exit(NeededQty);
        end;
        OnGetNeededQtyOnAfterCalcBasedOn(Rec);
        exit(Round("Remaining Quantity", RoundingPrecision));
    end;

    procedure ShowOrderTracking()
    var
        OrderTracking: Page "Order Tracking";
    begin
        OrderTracking.SetVariantRec(Rec, Rec."Item No.", Rec."Remaining Qty. (Base)", Rec."Due Date", Rec."Due Date");
        OrderTracking.RunModal();
    end;

    procedure ShowReservation()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowReservation(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField("Item No.");
        Item.Get("Item No.");
        Item.TestField(Reserve);
        Clear(Reservation);
        Reservation.SetReservSource(Rec);
        Reservation.RunModal();
    end;

    procedure ShowReservationEntries(Modal: Boolean)
    begin
        TestField("Item No.");
        ReservEntry.InitSortingAndFilters(true);
        SetReservationFilters(ReservEntry);
        if Modal then
            PAGE.RunModal(PAGE::"Reservation Entries", ReservEntry)
        else
            PAGE.Run(PAGE::"Reservation Entries", ReservEntry);
    end;

    procedure CopyFromPlanningComp(PlanningComponent: Record "Planning Component")
    begin
        "Line No." := PlanningComponent."Line No.";
        "Item No." := PlanningComponent."Item No.";
        Description := PlanningComponent.Description;
        "Unit of Measure Code" := PlanningComponent."Unit of Measure Code";
        "Quantity per" := PlanningComponent."Quantity per";
        Quantity := PlanningComponent.Quantity;
        Position := PlanningComponent.Position;
        "Position 2" := PlanningComponent."Position 2";
        "Position 3" := PlanningComponent."Position 3";
        "Lead-Time Offset" := PlanningComponent."Lead-Time Offset";
        "Routing Link Code" := PlanningComponent."Routing Link Code";
        "Scrap %" := PlanningComponent."Scrap %";
        "Variant Code" := PlanningComponent."Variant Code";
        "Flushing Method" := PlanningComponent."Flushing Method";
        "Location Code" := PlanningComponent."Location Code";
        if PlanningComponent."Bin Code" <> '' then
            "Bin Code" := PlanningComponent."Bin Code"
        else
            GetDefaultBin();
        Length := PlanningComponent.Length;
        Width := PlanningComponent.Width;
        Weight := PlanningComponent.Weight;
        Depth := PlanningComponent.Depth;
        "Calculation Formula" := PlanningComponent."Calculation Formula";
        "Qty. per Unit of Measure" := PlanningComponent."Qty. per Unit of Measure";
        "Quantity (Base)" := PlanningComponent."Quantity (Base)";
        "Due Date" := PlanningComponent."Due Date";
        "Due Time" := PlanningComponent."Due Time";
        "Unit Cost" := PlanningComponent."Unit Cost";
        "Direct Unit Cost" := PlanningComponent."Direct Unit Cost";
        "Indirect Cost %" := PlanningComponent."Indirect Cost %";
        "Variant Code" := PlanningComponent."Variant Code";
        "Overhead Rate" := PlanningComponent."Overhead Rate";
        "Expected Quantity" := PlanningComponent."Expected Quantity";
        "Expected Qty. (Base)" := PlanningComponent."Expected Quantity (Base)";
        "Cost Amount" := PlanningComponent."Cost Amount";
        "Overhead Amount" := PlanningComponent."Overhead Amount";
        "Direct Cost Amount" := PlanningComponent."Direct Cost Amount";
        "Planning Level Code" := PlanningComponent."Planning Level Code";
        if Status in [Status::Released, Status::Finished] then
            CalcFields("Act. Consumption (Qty)");
        "Remaining Quantity" := "Expected Quantity" - "Act. Consumption (Qty)";
        "Remaining Qty. (Base)" := Round("Remaining Quantity" * "Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
        "Shortcut Dimension 1 Code" := PlanningComponent."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := PlanningComponent."Shortcut Dimension 2 Code";
        "Dimension Set ID" := PlanningComponent."Dimension Set ID";
        "Qty. Rounding Precision" := PlanningComponent."Qty. Rounding Precision";
        "Qty. Rounding Precision (Base)" := PlanningComponent."Qty. Rounding Precision (Base)";

        OnAfterCopyFromPlanningComp(Rec, PlanningComponent);
    end;

    procedure AdjustQtyToQtyPicked(var QtyToPost: Decimal)
    var
        AdjustedQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAdjustQtyToQtyPicked(Rec, QtyToPost, IsHandled);
        if IsHandled then
            exit;

        AdjustedQty :=
          "Qty. Picked" + ProdOrderWarehouseMgt.CalcNextLevelProdOutput(Rec) -
          ("Expected Quantity" - "Remaining Quantity");

        if QtyToPost > AdjustedQty then
            QtyToPost := AdjustedQty;
    end;

    procedure AdjustQtyToReservedFromInventory(var QtyToPost: Decimal; ReservedFromStock: Enum "Reservation From Stock")
    var
        QtyReservedFromStock: Decimal;
    begin
        if ReservedFromStock = ReservedFromStock::" " then
            exit;

        QtyReservedFromStock := ProdOrderCompReserve.GetReservedQtyFromInventory(Rec);

        case ReservedFromStock of
            ReservedFromStock::Full:
                if QtyToPost <> QtyReservedFromStock then
                    QtyToPost := 0;
            ReservedFromStock::"Full and Partial":
                if QtyReservedFromStock = 0 then
                    QtyToPost := 0;
            else
                OnAdjustQtyToReservedFromInventory(QtyToPost, ReservedFromStock);
        end;
    end;

    procedure BlockDynamicTracking(SetBlock: Boolean)
    begin
        Blocked := SetBlock;
        ProdOrderCompReserve.Block(Blocked);
    end;

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    var
        SourceCodeSetup: Record "Source Code Setup";
        ProdOrderLine: Record "Prod. Order Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateDim(Rec, DefaultDimSource, CurrFieldNo, IsHandled);
        if IsHandled then
            exit;

        SourceCodeSetup.Get();
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        ProdOrderLine.Get(Status, "Prod. Order No.", "Prod. Order Line No.");
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, SourceCodeSetup."Production Order",
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", ProdOrderLine."Dimension Set ID",
            Database::"Prod. Order Line");

        OnAfterCreateDim(Rec, DefaultDimSource);
    end;

    procedure IsInbound(): Boolean
    begin
        exit("Quantity (Base)" < 0);
    end;

    procedure OpenItemTrackingLines()
    begin
        ProdOrderCompReserve.CallItemTracking(Rec);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");

        OnAfterValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);
    end;

    procedure LookupShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber, ShortcutDimCode);
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    /// <summary>
    /// Opens a page for selecting multiple items to add to the document.
    /// Selected items are added to the document.
    /// </summary>
    procedure SelectMultipleItems()
    var
        ItemListPage: Page "Item List";
        SelectionFilter: Text;
    begin
        SelectionFilter := ItemListPage.SelectActiveItems();

        if SelectionFilter <> '' then
            AddItems(SelectionFilter);
    end;

    /// <summary>
    /// Adds items to the document based on the provided selection filter.
    /// </summary>
    /// <param name="SelectionFilter">The filter to use for selecting items.</param>
    procedure AddItems(SelectionFilter: Text)
    var
        Item: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        InitNewLine(ProdOrderComponent);
        Item.SetLoadFields("No.");
        Item.SetFilter("No.", SelectionFilter);
        if Item.FindSet() then
            repeat
                AddItem(ProdOrderComponent, Item."No.");
            until Item.Next() = 0;
    end;

    /// <summary>
    /// Adds an item to the document.
    /// </summary>
    /// <remarks>
    /// After the line is added, assembly order is automatically created if required.
    /// If the item has extended text, the text is added as a line.
    /// </remarks>
    /// <param name="ProdOrderComponent">Return value: The added Prod. Order Component. Prod. Order Component must have the number set.</param>
    /// <param name="ItemNo">Return value: The number of the item to add.</param>
    procedure AddItem(var ProdOrderComponent: Record "Prod. Order Component"; ItemNo: Code[20])
    begin
        ProdOrderComponent.Init();
        ProdOrderComponent."Line No." += 10000;
        ProdOrderComponent.Validate("Item No.", ItemNo);
        ProdOrderComponent.Insert(true);
    end;

    /// <summary>
    /// Initializes a new Prod. Order Component based on the current Prod. Order Component.
    /// </summary>
    /// <param name="NewProdOrderComponent">Return value: The new Prod. Order Component.</param>
    procedure InitNewLine(var NewProdOrderComponent: Record "Prod. Order Component")
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        NewProdOrderComponent.Copy(Rec);
        ProdOrderComponent.SetLoadFields("Line No.");
        ProdOrderComponent.SetRange(Status, NewProdOrderComponent.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", NewProdOrderComponent."Prod. Order No.");
        ProdOrderComponent.SetRange("Prod. Order Line No.", NewProdOrderComponent."Prod. Order Line No.");
        if ProdOrderComponent.FindLast() then
            NewProdOrderComponent."Line No." := ProdOrderComponent."Line No."
        else
            NewProdOrderComponent."Line No." := 0;
    end;

    local procedure GetUpdateFromSKU()
    var
        SKU: Record "Stockkeeping Unit";
        GetPlanningParameters: Codeunit "Planning-Get Parameters";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetUpdateFromSKU(Rec, IsHandled);
        if IsHandled then
            exit;

        GetPlanningParameters.AtSKU(SKU, "Item No.", "Variant Code", "Location Code");
        Validate("Flushing Method", SKU."Flushing Method");
    end;

    local procedure RoundExpectedQuantity()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRoundExpectedQuantity(Rec, IsHandled);
        if IsHandled then
            exit;

        "Expected Quantity" := UOMMgt.RoundToItemRndPrecision("Expected Quantity", Item."Rounding Precision");

        OnAfterRoundExpectedQuantity(Rec);
    end;

    local procedure UpdateUOMFromItem(Item: Record Item)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateUOMFromItem(Rec, Item, IsHandled);
        if IsHandled then
            exit;

        Item.TestField("Base Unit of Measure");
        Validate("Unit of Measure Code", Item."Base Unit of Measure");
    end;

    procedure UpdateDatetime()
    begin
        if ("Due Date" <> 0D) and ("Due Time" <> 0T) then
            "Due Date-Time" := CreateDateTime("Due Date", "Due Time")
        else
            "Due Date-Time" := 0DT;

        OnAfterUpdateDateTime(Rec);
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get();
        GLSetupRead := true;
    end;

    procedure RowID1(): Text[250]
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        exit(
          ItemTrackingMgt.ComposeRowID(
              Database::"Prod. Order Component", Status.AsInteger(), "Prod. Order No.", '', "Prod. Order Line No.", "Line No."));
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    procedure GetDefaultBin()
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDefaultBin(Rec, xRec, IsHandled);
        if IsHandled then
            exit;

        if (Quantity * xRec.Quantity > 0) and
           ("Item No." = xRec."Item No.") and
           ("Location Code" = xRec."Location Code") and
           ("Variant Code" = xRec."Variant Code") and
           ("Routing Link Code" = xRec."Routing Link Code")
        then
            exit;

        "Bin Code" := '';
        if ("Location Code" <> '') and ("Item No." <> '') then begin
            if Item."No." <> "Item No." then
                Item.Get("Item No.");
            if Item.IsInventoriableType() then
                Validate("Bin Code", GetDefaultConsumptionBin(ProdOrderRtngLine));
        end;
    end;

    procedure GetDefaultConsumptionBin(var ProdOrderRtngLine: Record "Prod. Order Routing Line") BinCode: Code[20]
    var
        ProdOrderLine: Record "Prod. Order Line";
        WMSManagement: Codeunit "WMS Management";
    begin
        OnBeforeGetDefaultConsumptionBin(Rec, ProdOrderRtngLine, BinCode);

        ProdOrderLine.Get(Status, "Prod. Order No.", "Prod. Order Line No.");
        if "Location Code" = ProdOrderLine."Location Code" then
            if FindFirstRtngLine(ProdOrderRtngLine, ProdOrderLine) then
                BinCode := GetBinCodeFromRtngLine(ProdOrderRtngLine);

        OnGetDefaultConsumptionBinOnAfterGetBinCodeFromRtngLine(Rec, ProdOrderRtngLine, BinCode);
        if BinCode <> '' then
            exit;

        BinCode := GetBinCodeFromLocation("Location Code");

        if BinCode <> '' then
            exit;

        GetLocation("Location Code");
        if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then
            WMSManagement.GetDefaultBin("Item No.", "Variant Code", "Location Code", BinCode);
    end;

    local procedure FindFirstRtngLine(var ProdOrderRtngLine: Record "Prod. Order Routing Line"; ProdOrderLine: Record "Prod. Order Line"): Boolean
    begin
        ProdOrderRtngLine.Reset();
        ProdOrderRtngLine.SetCurrentKey(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.", "Operation No.");
        ProdOrderRtngLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrderRtngLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRtngLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        ProdOrderRtngLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        ProdOrderRtngLine.SetRange("Location Code", ProdOrderLine."Location Code");
        ProdOrderRtngLine.SetFilter("No.", '<>%1', ''); // empty No. implies blank bin codes - ignore these
        ProdOrderRtngLine.SetRange("Previous Operation No.", ''); // first operation
        if "Routing Link Code" <> '' then begin
            ProdOrderRtngLine.SetRange("Routing Link Code", "Routing Link Code");
            ProdOrderRtngLine.SetRange("Previous Operation No.");
            if ProdOrderRtngLine.Count = 0 then begin // no routing line with Routing Link Code found- use 1st op
                ProdOrderRtngLine.SetRange("Routing Link Code");
                ProdOrderRtngLine.SetRange("Previous Operation No.", '');
            end;
        end;

        exit(ProdOrderRtngLine.FindFirst());
    end;

    local procedure GetBinCodeFromRtngLine(ProdOrderRtngLine: Record "Prod. Order Routing Line") BinCode: Code[20]
#if not CLEAN26
    var
        ManufacturingSetup: Record "Manufacturing Setup";
#endif
    begin
#if not CLEAN26
        if not ManufacturingSetup.IsFeatureKeyFlushingMethodManualWithoutPickEnabled() then
            case "Flushing Method" of
                "Flushing Method"::Manual,
                "Flushing Method"::"Pick + Manual",
                "Flushing Method"::"Pick + Forward",
                "Flushing Method"::"Pick + Backward":
                    BinCode := ProdOrderRtngLine."To-Production Bin Code";
                "Flushing Method"::Forward,
                "Flushing Method"::Backward:
                    BinCode := ProdOrderRtngLine."Open Shop Floor Bin Code";
            end
        else
#endif
            case "Flushing Method" of
                "Flushing Method"::"Pick + Manual",
                "Flushing Method"::"Pick + Forward",
                "Flushing Method"::"Pick + Backward":
                    BinCode := ProdOrderRtngLine."To-Production Bin Code";
                "Flushing Method"::Manual,
                "Flushing Method"::Forward,
                "Flushing Method"::Backward:
                    BinCode := ProdOrderRtngLine."Open Shop Floor Bin Code";
            end;
    end;

    local procedure GetBinCodeFromLocation(LocationCode: Code[10]) BinCode: Code[20]
#if not CLEAN26
    var
        ManufacturingSetup: Record "Manufacturing Setup";
#endif
    begin
        GetLocation(LocationCode);
#if not CLEAN26
        if not ManufacturingSetup.IsFeatureKeyFlushingMethodManualWithoutPickEnabled() then
            case "Flushing Method" of
                "Flushing Method"::Manual,
                "Flushing Method"::"Pick + Manual",
                "Flushing Method"::"Pick + Forward",
                "Flushing Method"::"Pick + Backward":
                    BinCode := Location."To-Production Bin Code";
                "Flushing Method"::Forward,
                "Flushing Method"::Backward:
                    BinCode := Location."Open Shop Floor Bin Code";
            end
        else
#endif
            case "Flushing Method" of
                "Flushing Method"::"Pick + Manual",
                "Flushing Method"::"Pick + Forward",
                "Flushing Method"::"Pick + Backward":
                    BinCode := Location."To-Production Bin Code";
                "Flushing Method"::Manual,
                "Flushing Method"::Forward,
                "Flushing Method"::Backward:
                    BinCode := Location."Open Shop Floor Bin Code";
            end;

        OnAfterGetBinCodeFromLocation(Rec, Location, BinCode);
    end;

    procedure GetRemainingQty(var RemainingQty: Decimal; var RemainingQtyBase: Decimal)
    begin
        CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        RemainingQty := "Remaining Quantity" - Abs("Reserved Quantity");
        RemainingQtyBase := "Remaining Qty. (Base)" - Abs("Reserved Qty. (Base)");
    end;

    procedure GetReservationQty(var QtyReserved: Decimal; var QtyReservedBase: Decimal; var QtyToReserve: Decimal; var QtyToReserveBase: Decimal): Decimal
    begin
        CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        QtyReserved := "Reserved Quantity";
        QtyReservedBase := "Reserved Qty. (Base)";
        QtyToReserve := "Remaining Quantity";
        QtyToReserveBase := "Remaining Qty. (Base)";
        exit("Qty. per Unit of Measure");
    end;

    procedure GetSourceCaption(): Text
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.Get(Status, "Prod. Order No.", "Prod. Order Line No.");
        exit(StrSubstNo('%1 %2 %3 %4 %5', Status, TableCaption(), "Prod. Order No.", "Item No.", ProdOrderLine."Item No."));
    end;

    procedure SetReservationEntry(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSource(Database::"Prod. Order Component", Status.AsInteger(), "Prod. Order No.", "Line No.", '', "Prod. Order Line No.");
        ReservEntry.SetItemData("Item No.", Description, "Location Code", "Variant Code", "Qty. per Unit of Measure");
        ReservEntry."Expected Receipt Date" := "Due Date";
        ReservEntry."Shipment Date" := "Due Date";
    end;

    procedure SetReservationFilters(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSourceFilter(Database::"Prod. Order Component", Status.AsInteger(), "Prod. Order No.", "Line No.", false);
        ReservEntry.SetSourceFilter('', "Prod. Order Line No.");

        OnAfterSetReservationFilters(ReservEntry, Rec);
    end;

    procedure ReservEntryExist(): Boolean
    var
        ReservEntry: Record "Reservation Entry";
    begin
        ReservEntry.InitSortingAndFilters(false);
        SetReservationFilters(ReservEntry);
        exit(not ReservEntry.IsEmpty);
    end;

    local procedure UpdateBin(var ProdOrderComp: Record "Prod. Order Component"; FieldNo: Integer; FieldCaption: Text[30])
    var
        ProdOrderComp2: Record "Prod. Order Component";
        OverwriteBinCode, IsHandled : Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateBin(ProdOrderComp, FieldNo, FieldCaption, IsHandled);
        if IsHandled then
            exit;

        ProdOrderComp2 := ProdOrderComp;
        ProdOrderComp2.GetDefaultBin();
        if ProdOrderComp."Bin Code" <> ProdOrderComp2."Bin Code" then
            if CurrFieldNo = FieldNo then begin
                if Confirm(Text001, false, FieldCaption, ProdOrderComp2."Bin Code") then
                    OverwriteBinCode := true;
            end else
                OverwriteBinCode := true;
        if OverwriteBinCode then
            ProdOrderComp."Bin Code" := ProdOrderComp2."Bin Code";
    end;

    local procedure UpdateExpectedQuantity()
    var
        CalculatedQuantity: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateExpectedQuantity(Rec, IsHandled);
        if IsHandled then
            exit;

        CalculateQuantity(CalculatedQuantity);
        if "Calculation Formula" = "Calculation Formula"::"Fixed Quantity" then
            Validate("Expected Quantity", CalculatedQuantity)
        else
            Validate("Expected Quantity", CalculatedQuantity * ProdOrderNeeds());

    end;

    procedure CheckBin()
    var
        BinContent: Record "Bin Content";
        Bin: Record Bin;
    begin
        if "Bin Code" <> '' then begin
            GetLocation("Location Code");
            if not Location."Check Whse. Class" then
                exit;

            if BinContent.Get(
                 "Location Code", "Bin Code",
                 "Item No.", "Variant Code", "Unit of Measure Code")
            then begin
                if not BinContent.CheckWhseClass(IgnoreErrors) then
                    ErrorOccured := true;
            end else begin
                Bin.Get("Location Code", "Bin Code");
                if not Bin.CheckWhseClass("Item No.", IgnoreErrors) then
                    ErrorOccured := true;
            end;
        end;
        if ErrorOccured then
            "Bin Code" := '';
    end;

    procedure AutoReserve()
    var
        Item: Record Item;
        FullAutoReservation: Boolean;
        IsHandled: Boolean;
    begin
        if Status in [Status::Simulated, Status::Finished] then
            exit;

        TestField("Item No.");
        Item.Get("Item No.");

        IsHandled := false;
        OnBeforeAutoReserve(Item, Rec, IsHandled);
        if not IsHandled then begin
            if Item.Reserve <> Item.Reserve::Always then
                exit;

            if "Remaining Qty. (Base)" <> 0 then begin
                TestField("Due Date");
                ReservMgt.SetReservSource(Rec);
                ReservMgt.AutoReserve(FullAutoReservation, '', "Due Date", "Remaining Quantity", "Remaining Qty. (Base)");
                CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
                Find();
                if not FullAutoReservation and
                   (CurrFieldNo <> 0)
                then
                    if Confirm(Text99000009, true) then begin
                        Commit();
                        Rec.ShowReservation();
                        Find();
                    end;
            end;
        end;

        OnAfterAutoReserve(Item, Rec);
    end;

    procedure ShowItemSub()
    var
        MfgItemSubstitution: Codeunit "Mfg. Item Substitution";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowItemSub(Rec, IsHandled);
        if IsHandled then
            exit;

        MfgItemSubstitution.GetProdOrderCompSubst(Rec);
    end;

    local procedure GetSKU() Result: Boolean
    begin
        if (SKU."Location Code" = "Location Code") and
           (SKU."Item No." = "Item No.") and
           (SKU."Variant Code" = "Variant Code")
        then
            exit(true);
        if SKU.Get("Location Code", "Item No.", "Variant Code") then
            exit(true);

        Result := false;
        OnAfterGetSKU(Rec, Result);
    end;

    local procedure ClearCalcFormula()
    begin
        "Calculation Formula" := "Calculation Formula"::" ";
        Length := 0;
        Width := 0;
        Weight := 0;
        Depth := 0;
    end;

    local procedure UpdateUnitCost()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateUnitCost(Rec, GLSetup, IsHandled);
        if IsHandled then
            exit;

        if GetSKU() then
            "Unit Cost" := SKU."Unit Cost"
        else
            "Unit Cost" := Item."Unit Cost";

        "Unit Cost" :=
          Round("Unit Cost" * "Qty. per Unit of Measure",
            GLSetup."Unit-Amount Rounding Precision");

        "Indirect Cost %" := Round(Item."Indirect Cost %", UOMMgt.QtyRndPrecision());

        "Overhead Rate" :=
          Round(Item."Overhead Rate" * "Qty. per Unit of Measure",
            GLSetup."Unit-Amount Rounding Precision");

        "Direct Unit Cost" :=
          Round(
            ("Unit Cost" - "Overhead Rate") / (1 + "Indirect Cost %" / 100),
            GLSetup."Unit-Amount Rounding Precision");

        OnAfterUpdateUnitCost(Rec, GLSetup);
    end;

    procedure FilterLinesWithItemToPlan(var Item: Record Item; IncludeFirmPlanned: Boolean)
    begin
        Reset();
        SetCurrentKey("Item No.", "Variant Code", "Location Code", Status, "Due Date");
        if IncludeFirmPlanned then
            SetRange(Status, Status::Planned, Status::Released)
        else
            SetFilter(Status, '%1|%2', Status::Planned, Status::Released);
        SetRange("Item No.", Item."No.");
        SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
        SetFilter("Location Code", Item.GetFilter("Location Filter"));
        SetFilter("Due Date", Item.GetFilter("Date Filter"));
        SetFilter("Shortcut Dimension 1 Code", Item.GetFilter("Global Dimension 1 Filter"));
        SetFilter("Shortcut Dimension 2 Code", Item.GetFilter("Global Dimension 2 Filter"));
        SetFilter("Remaining Qty. (Base)", '<>0');
        SetFilter("Unit of Measure Code", Item.GetFilter("Unit of Measure Filter"));
        OnAfterFilterLinesWithItemToPlan(Rec, Item, IncludeFirmPlanned);
    end;

    procedure FindLinesWithItemToPlan(var Item: Record Item; IncludeFirmPlanned: Boolean): Boolean
    begin
        FilterLinesWithItemToPlan(Item, IncludeFirmPlanned);
        exit(Find('-'));
    end;

    procedure LinesWithItemToPlanExist(var Item: Record Item; IncludeFirmPlanned: Boolean): Boolean
    begin
        FilterLinesWithItemToPlan(Item, IncludeFirmPlanned);
        exit(not IsEmpty);
    end;

    procedure FilterLinesForReservation(ReservationEntry: Record "Reservation Entry"; NewStatus: Option; AvailabilityFilter: Text; Positive: Boolean)
    begin
        Reset();
        SetCurrentKey(Status, "Item No.", "Variant Code", "Location Code", "Due Date");
        SetRange(Status, NewStatus);
        SetRange("Item No.", ReservationEntry."Item No.");
        SetRange("Variant Code", ReservationEntry."Variant Code");
        SetRange("Location Code", ReservationEntry."Location Code");
        SetFilter("Due Date", AvailabilityFilter);
        if Positive then
            SetFilter("Remaining Qty. (Base)", '<0')
        else
            SetFilter("Remaining Qty. (Base)", '>0');

        OnAfterFilterLinesForReservation(Rec, ReservationEntry, NewStatus, AvailabilityFilter, Positive);
    end;

    procedure ShowDimensions()
    begin
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            Rec, "Dimension Set ID", StrSubstNo('%1 %2 %3', Status, "Prod. Order No.", "Prod. Order Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        OnAfterShowDimensions(Rec, xRec);
    end;

    procedure SetIgnoreErrors()
    begin
        IgnoreErrors := true;
    end;

    procedure HasErrorOccured(): Boolean
    begin
        exit(ErrorOccured);
    end;

    procedure SetFilterByReleasedOrderNo(OrderNo: Code[20])
    begin
        Reset();
        SetCurrentKey(Status, "Prod. Order No.", "Prod. Order Line No.", "Item No.", "Line No.");
        SetRange(Status, Status::Released);
        SetRange("Prod. Order No.", OrderNo);
    end;

    procedure SetFilterFromProdBOMLine(ProdBOMLine: Record "Production BOM Line")
    begin
        SetRange("Item No.", ProdBOMLine."No.");
        SetRange("Variant Code", ProdBOMLine."Variant Code");
        SetRange("Routing Link Code", ProdBOMLine."Routing Link Code");
        SetRange(Position, ProdBOMLine.Position);
        SetRange("Position 2", ProdBOMLine."Position 2");
        SetRange("Position 3", ProdBOMLine."Position 3");
        SetRange(Length, ProdBOMLine.Length);
        SetRange(Width, ProdBOMLine.Width);
        SetRange(Weight, ProdBOMLine.Weight);
        SetRange(Depth, ProdBOMLine.Depth);
        SetRange("Unit of Measure Code", ProdBOMLine."Unit of Measure Code");
        SetRange("Calculation Formula", ProdBOMLine."Calculation Formula");

        OnAfterSetFilterFromProdBOMLine(Rec, ProdBOMLine);
    end;

    local procedure AssignDescriptionFromItemOrVariantAndCheckVariantNotBlocked()
    var
        ItemVariant: Record "Item Variant";
    begin
        if Rec."Variant Code" = '' then
            Description := Item.Description
        else begin
            ItemVariant.SetLoadFields(Description, Blocked);
            ItemVariant.Get("Item No.", "Variant Code");
            ItemVariant.TestField(Blocked, false);
            Description := ItemVariant.Description;
        end;
        OnAfterAssignDecsriptionFromItemOrVariant(Rec, xRec, Item, ItemVariant);
    end;

    local procedure IsLineRequiredForSingleDemand(ProdOrderLine: Record "Prod. Order Line"; DemandLineNo: Integer): Boolean
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(Status, ProdOrderLine.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderComponent.SetFilter("Prod. Order Line No.", '<>%1', DemandLineNo);
        ProdOrderComponent.SetRange("Supplied-by Line No.", ProdOrderLine."Line No.");
        exit(ProdOrderComponent.IsEmpty);
    end;

    procedure TestItemFields(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    begin
        TestField("Item No.", ItemNo);
        TestField("Variant Code", VariantCode);
        TestField("Location Code", LocationCode);
    end;

    procedure CalcBaseQty(Qty: Decimal; FromFieldName: Text; ToFieldName: Text) Result: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcBaseQty(Rec, CurrFieldNo, Qty, FromFieldName, ToFieldName, Result, IsHandled);
        if IsHandled then
            exit;

        exit(UOMMgt.CalcBaseQty(
            "Item No.", "Variant Code", "Unit of Measure Code", Qty, "Qty. per Unit of Measure", "Qty. Rounding Precision (Base)", FieldCaption("Qty. Rounding Precision"), FromFieldName, ToFieldName));
    end;

    procedure CreateDimFromDefaultDim()
    var
        DefaultDimSource: List of [Dictionary of [Integer, Code[20]]];
    begin
        InitDefaultDimensionSources(DefaultDimSource);
        CreateDim(DefaultDimSource);
    end;

    local procedure InitDefaultDimensionSources(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
        DimMgt.AddDimSource(DefaultDimSource, Database::Item, Rec."Item No.");
        DimMgt.AddDimSource(DefaultDimSource, Database::Location, Rec."Location Code");

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource);
    end;

    local procedure CalculateQuantity(var CalculatedQuantity: Decimal)
    var
        OldQuantity: Decimal;
    begin
        case "Calculation Formula" of
            "Calculation Formula"::" ":
                CalculatedQuantity := "Quantity per";
            "Calculation Formula"::Length:
                CalculatedQuantity := Round(Length * "Quantity per", UOMMgt.QtyRndPrecision());
            "Calculation Formula"::"Length * Width":
                CalculatedQuantity := Round(Length * Width * "Quantity per", UOMMgt.QtyRndPrecision());
            "Calculation Formula"::"Length * Width * Depth":
                CalculatedQuantity := Round(Length * Width * Depth * "Quantity per", UOMMgt.QtyRndPrecision());
            "Calculation Formula"::Weight:
                CalculatedQuantity := Round(Weight * "Quantity per", UOMMgt.QtyRndPrecision());
            "Calculation Formula"::"Fixed Quantity":
                CalculatedQuantity := "Quantity per";
            else begin
                OldQuantity := Quantity;
                OnValidateCalculationFormulaEnumExtension(Rec);
                CalculatedQuantity := Quantity;
                Quantity := OldQuantity;
            end;
        end;
    end;

    procedure CheckIfProdOrderCompMeetsReservedFromStockSetting(QtyToPost: Decimal; ReservedFromStock: Enum "Reservation From Stock") Result: Boolean
    var
        QtyReservedFromStock: Decimal;
    begin
        Result := true;

        if ReservedFromStock = ReservedFromStock::" " then
            exit(true);

        if Item."No." <> "Item No." then
            Item.Get("Item No.");
        if not Item.IsInventoriableType() then
            exit(true);

        QtyReservedFromStock := ProdOrderCompReserve.GetReservedQtyFromInventory(Rec);

        case ReservedFromStock of
            ReservedFromStock::Full:
                if QtyToPost <> QtyReservedFromStock then
                    Result := false;
            ReservedFromStock::"Full and Partial":
                if QtyReservedFromStock = 0 then
                    Result := false;
            else
                OnCheckIfProdOrderCompMeetsReservedFromStockSetting(QtyToPost, ReservedFromStock, Result);
        end;

        exit(Result);
    end;

    procedure IsInventoriableItem(): Boolean
    begin
        if "Item No." = '' then
            exit(false);
        if Item."No." <> "Item No." then
            Item.Get("Item No.");
        exit(Item.IsInventoriableType());
    end;

    local procedure ConfirmDeletion()
    begin
        if CalledFromHeader then
            exit;

        if ("Expected Quantity" - "Remaining Quantity") < "Qty. Picked" then begin
            if "Location Code" <> '' then begin
                GetLocation("Location Code");
                if Location."Prod. Output Whse. Handling" = Location."Prod. Consump. Whse. Handling"::"No Warehouse Handling" then
                    exit;
            end;

            if not Confirm(
                StrSubstNo(
                    ConfirmDeleteQst,
                    FieldCaption("Qty. Picked"),
                    "Qty. Picked",
                    'Qty. Posted',
                    ("Expected Qty. (Base)" - "Remaining Qty. (Base)"),
                    TableCaption),
                false)
            then
                Error('');
        end;
    end;

    procedure SuspendDeletionCheck(Suspend: Boolean)
    begin
        CalledFromHeader := Suspend;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var ProdOrderComponent: Record "Prod. Order Component"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAutoReserve(var Item: Record Item; var ProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAssignDecsriptionFromItemOrVariant(var ProdOrderComponent: Record "Prod. Order Component"; xProdOrderComponent: Record "Prod. Order Component"; Item: Record Item; ItemVariant: Record "Item Variant")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDim(var ProdOrderComponent: Record "Prod. Order Component"; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromPlanningComp(var ProdOrderComponent: Record "Prod. Order Component"; PlanningComponent: Record "Planning Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterLinesWithItemToPlan(var ProdOrderComponent: Record "Prod. Order Component"; var Item: Record Item; IncludeFirmPlanned: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterLinesForReservation(var ProdOrderComponent: Record "Prod. Order Component"; ReservationEntry: Record "Reservation Entry"; NewStatus: Option; AvailabilityFilter: Text; Positive: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetBinCodeFromLocation(var ProdOrderComponent: Record "Prod. Order Component"; Location: Record Location; var BinCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSKU(ProdOrderComponent: Record "Prod. Order Component"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilterFromProdBOMLine(var ProdOrderComponent: Record "Prod. Order Component"; ProdBOMLine: Record "Production BOM Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateUnitCost(var ProdOrderComp: Record "Prod. Order Component"; GeneralLedgerSetup: Record "General Ledger Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProdOrderNeeds(ProdOrderComponent: Record "Prod. Order Component"; ProdOrderLine: Record "Prod. Order Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var NeededQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRoundExpectedQuantity(var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReservationFilters(var ReservEntry: Record "Reservation Entry"; ProdOrderComponent: Record "Prod. Order Component");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDateTime(var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var ProdOrderComponent: Record "Prod. Order Component"; var xProdOrderComponent: Record "Prod. Order Component"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAdjustQtyToQtyPicked(var ProdOrderComponent: Record "Prod. Order Component"; var QtyToPost: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoReserve(var Item: Record Item; var ProdOrderComp: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeBinCodeOnLookup(var ProdOrderComponent: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcBaseQty(var ProdOrderComponent: Record "Prod. Order Component"; CurrentFieldNo: integer; Qty: Decimal; FromFieldName: Text; ToFieldName: Text; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateExpectedQuantity(var ProdOrderComponent: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateCalculationFormula(var ProdOrderComponent: Record "Prod. Order Component"; xProdOrderComponent: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var ProdOrderComponent: Record "Prod. Order Component"; var xProdOrderComponent: Record "Prod. Order Component"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantityper(var ProdOrderComponent: Record "Prod. Order Component"; xProdOrderComponent: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDefaultConsumptionBin(var ProdOrderComponent: Record "Prod. Order Component"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var BinCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetUpdateFromSKU(var ProdOrderComponent: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateUnitCost(var ProdOrderComponent: Record "Prod. Order Component"; GLSetup: Record "General Ledger Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateUOMFromItem(var ProdOrderComponent: Record "Prod. Order Component"; Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteOnBeforeGetProdOrderLine(var ProdOrderComponent: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetDefaultConsumptionBinOnAfterGetBinCodeFromRtngLine(var ProdOrderComponent: Record "Prod. Order Component"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var BinCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetNeededQtyAfterCalcCompQtyBase(var ProdOrderComp: Record "Prod. Order Component"; var CompQtyBase: Decimal; OutputQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetNeededQtyAfterCalcActConsumptionQty(var ProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetNeededQtyOnAfterCalcBasedOn(var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetNeededQtyOnAfterLastOperationFound(var ProdOrderComponent: Record "Prod. Order Component"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetNeededQtyOnBeforeAddOutputQtyBase(var CapacityLedgerEntry: Record "Capacity Ledger Entry"; var OutputQtyBase: Decimal; var IsHandled: Boolean; var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetNeededQtyOnBeforeCalcBasedOn(var ProdOrderComponent: Record "Prod. Order Component"; var RoundingPrecision: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateCalculationFormulaEnumExtension(var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateCalculationFormulaOnAfterSetQuantity(var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateExpectedQuantityOnAfterCalcActConsumptionQty(var ProdOrderComp: Record "Prod. Order Component"; xProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateExpectedQtyBaseOnAfterCalcActConsumptionQty(var ProdOrderComp: Record "Prod. Order Component"; xProdOrderComp: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnBeforeGetDefaultBin(var ProdOrderComponent: Record "Prod. Order Component"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateRoutingLinkCodeBeforeValidateDueDate(var ProdOrderComponent: Record "Prod. Order Component"; var ProdOrderLine: Record "Prod. Order Line"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemSub(var ProdOrderComponent: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateBinCode(var Rec: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateExpectedQuantity(var ProdOrderComponent: Record "Prod. Order Component"; xProdOrderComponent: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateExpectedQtyBase(var ProdOrderComponent: Record "Prod. Order Component"; xProdOrderComponent: Record "Prod. Order Component"; FieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDefaultBin(var ProdOrderComponent: Record "Prod. Order Component"; var xProdOrderComponent: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRoundExpectedQuantity(var ProdOrderComponent: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowReservation(var ProdOrderComponent: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateExpectedQtyBaseOnAfterCalcRemainingQuantity(var ProdOrderComponent: Record "Prod. Order Component"; xProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnAfterUpdateUOMFromItem(var ProdOrderComponent: Record "Prod. Order Component"; xProdOrderComponent: Record "Prod. Order Component"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateBin(var ProdOrderComponent: Record "Prod. Order Component"; FieldNo: Integer; FieldCaption: Text[30]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAdjustQtyToReservedFromInventory(var QtyToPost: Decimal; ReservedFromStock: Enum "Reservation From Stock")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckIfProdOrderCompMeetsReservedFromStockSetting(QtyToPost: Decimal; ReservedFromStock: Enum "Reservation From Stock"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowDimensions(var ProdOrderComponent: Record "Prod. Order Component"; xProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateRoutingLinkCodeOnBeforeUpdateDueDateAndTime(var ProdOrderComponent: Record "Prod. Order Component"; var ProdOrderLine: Record "Prod. Order Line"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateDim(var ProdOrderComponent: Record "Prod. Order Component"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;
}

