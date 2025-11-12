// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Warehouse.Activity;
using Microsoft.Foundation.UOM;
using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Warehouse.Activity.History;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Structure;
using System.Utilities;

table 5406 "Prod. Order Line"
{
    Caption = 'Prod. Order Line';
    DataCaptionFields = "Prod. Order No.";
    DrillDownPageID = "Prod. Order Line List";
    LookupPageID = "Prod. Order Line List";
    Permissions = TableData "Prod. Order Line" = rimd;
    DataClassification = CustomerContent;

    fields
    {
        field(1; Status; Enum "Production Order Status")
        {
            Caption = 'Status';
        }
        field(2; "Prod. Order No."; Code[20])
        {
            Caption = 'Prod. Order No.';
            TableRelation = "Production Order"."No." where(Status = field(Status));
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(11; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item where(Type = const(Inventory), "Production Blocked" = filter(<> Output));

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnValidateItemNoOnBeforeCheckReservations(Rec, xRec, CurrFieldNo, IsHandled);
                if not IsHandled then begin
                    ProdOrderLineReserve.VerifyChange(Rec, xRec);
                    TestField("Finished Quantity", 0);
                    CalcFields("Reserved Quantity");
                    TestField("Reserved Quantity", 0);
                    ProdOrderWarehouseMgt.ProdOrderLineVerifyChange(Rec, xRec);
                end;
                if ("Item No." <> xRec."Item No.") and ("Line No." <> 0) then begin
                    DeleteRelations();
                    "Variant Code" := '';
                end;
                if "Item No." = '' then
                    Init()
                else begin
                    ProdOrder.Get(Status, "Prod. Order No.");
                    "Starting Date" := ProdOrder."Starting Date";
                    "Starting Time" := ProdOrder."Starting Time";
                    "Ending Date" := ProdOrder."Ending Date";
                    "Ending Time" := ProdOrder."Ending Time";
                    "Due Date" := ProdOrder."Due Date";
                    "Location Code" := ProdOrder."Location Code";
                    "Bin Code" := ProdOrder."Bin Code";

                    GetItem();
                    Item.TestField(Blocked, false);
                    Item.TestField("Inventory Posting Group");
                    "Inventory Posting Group" := Item."Inventory Posting Group";

                    Description := Item.Description;
                    "Description 2" := Item."Description 2";
                    "Production BOM No." := Item."Production BOM No.";
                    "Routing No." := Item."Routing No.";

                    "Scrap %" := Item."Scrap %";
                    "Unit Cost" := Item."Unit Cost";
                    "Indirect Cost %" := Item."Indirect Cost %";
                    "Overhead Rate" := Item."Overhead Rate";
                    IsHandled := false;
                    OnValidateItemNoOnAfterAssignItemValues(Rec, Item, xRec, IsHandled);
                    if not IsHandled then
                        if "Item No." <> xRec."Item No." then begin
                            Validate("Production BOM No.", Item."Production BOM No.");
                            Validate("Routing No.", Item."Routing No.");
                            ValidateUnitofMeasureCodeFromItem();
                        end else
                            if "Routing No." <> xRec."Routing No." then
                                Validate("Routing No.", Item."Routing No.");
                    OnAfterCopyFromItem(Rec, Item, xRec, CurrFieldNo);
                    if ProdOrder."Source Type" = ProdOrder."Source Type"::Family then
                        "Routing Reference No." := "Line No."
                    else
                        if "Line No." = 0 then
                            "Routing Reference No." := -10000
                        else
                            "Routing Reference No." := "Line No.";

                    if "Bin Code" = '' then
                        GetDefaultBin();
                end;
                if "Item No." <> xRec."Item No." then
                    Validate(Quantity);
                GetUpdateFromSKU();

                CreateDimFromDefaultDim();
                DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
            end;
        }
        field(12; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."),
                                                       Code = field("Variant Code"),
                                                       "Production Blocked" = filter(<> Output));

            trigger OnValidate()
            var
                ItemVariant: Record "Item Variant";
            begin
                ProdOrderLineReserve.VerifyChange(Rec, xRec);
                TestField("Finished Quantity", 0);
                CalcFields("Reserved Quantity");
                TestField("Reserved Quantity", 0);
                ProdOrderWarehouseMgt.ProdOrderLineVerifyChange(Rec, xRec);
                OnValidateVariantCodeOnAfterVerifyChange(Rec, xRec, CurrFieldNo);

                ItemVariant.SetLoadFields(Blocked, Description, "Description 2");
                if ItemVariant.Get("Item No.", "Variant Code") then begin
                    ItemVariant.TestField(Blocked, false);
                    Description := ItemVariant.Description;
                    "Description 2" := ItemVariant."Description 2";
                end else begin
                    GetItem();
                    Description := Item.Description;
                    "Description 2" := Item."Description 2";
                end;
                GetUpdateFromSKU();
                GetDefaultBin();
            end;
        }
        field(13; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(14; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(20; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));

            trigger OnValidate()
            var
                ProductionOrder: Record "Production Order";
            begin
                ProductionOrder.SetLoadFields(Status, "No.", "Location Code");
                ProductionOrder.Get(Rec.Status, Rec."Prod. Order No.");
                ProdOrderLineReserve.VerifyChange(Rec, xRec);
                ProdOrderWarehouseMgt.ProdOrderLineVerifyChange(Rec, xRec);
                ProdOrderWarehouseMgt.CompareProdOrderWithProdOrderLinesForLocation(ProductionOrder, Rec);
                ProdOrderWarehouseMgt.ValidateWarehousePutAwayLocation(Rec);
                GetUpdateFromSKU();
                GetDefaultBin();
                OnValidateLocationCodeOnBeforeCreateDim(Rec);
                CreateDimFromDefaultDim();
            end;
        }
        field(21; "Shortcut Dimension 1 Code"; Code[20])
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
        field(22; "Shortcut Dimension 2 Code"; Code[20])
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
        field(23; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = if (Quantity = filter(< 0)) "Bin Content"."Bin Code" where("Location Code" = field("Location Code"),
                                                                                     "Item No." = field("Item No."),
                                                                                     "Variant Code" = field("Variant Code"))
            else
            Bin.Code where("Location Code" = field("Location Code"));

            trigger OnLookup()
            var
                WMSManagement: Codeunit "WMS Management";
                BinCode: Code[20];
            begin
                if Quantity < 0 then
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
            begin
                if "Bin Code" <> '' then begin
                    if Quantity < 0 then
                        WMSManagement.FindBinContent("Location Code", "Bin Code", "Item No.", "Variant Code", '')
                    else
                        WMSManagement.FindBin("Location Code", "Bin Code", '');
                    WhseIntegrationMgt.CheckBinTypeAndCode(
                        Database::"Prod. Order Line", FieldCaption("Bin Code"), "Location Code", "Bin Code", 0);
                    CheckBin();
                end;
            end;
        }
#if not CLEANSCHEMA30
        field(35; "Standard Task Code"; Code[10])
        {
            Caption = 'Standard Task Code';
            TableRelation = "Standard Task";
            ObsoleteReason = 'This field is not required anymore. The standard task code is now defined on the routing line.';
#if CLEAN27
            ObsoleteState = Removed;
            ObsoleteTag = '30.0';
#else
            ObsoleteState = Pending;
            ObsoleteTag = '27.0';
#endif
        }
#endif
        field(40; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQuantity(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                Quantity := UOMMgt.RoundAndValidateQty(Quantity, "Qty. Rounding Precision", FieldCaption(Quantity));
                "Quantity (Base)" := CalcBaseQty(Quantity, FieldCaption(Quantity), FieldCaption("Quantity (Base)"));
                OnValidateQuantityOnAfterCalcBaseQty(Rec, xRec);

                "Remaining Quantity" := Quantity - "Finished Quantity";
                if "Remaining Quantity" < 0 then
                    "Remaining Quantity" := 0;
                "Remaining Qty. (Base)" := CalcBaseQty("Remaining Quantity", FieldCaption("Remaining Quantity"), FieldCaption("Remaining Qty. (Base)"));
                ProdOrderLineReserve.VerifyQuantity(Rec, xRec);
                ProdOrderWarehouseMgt.ProdOrderLineVerifyChange(Rec, xRec);

                UpdateProdOrderComp(xRec."Qty. per Unit of Measure");

                if CurrFieldNo <> 0 then
                    Validate("Ending Time");
                "Cost Amount" := Round(Quantity * "Unit Cost");
            end;
        }
        field(41; "Finished Quantity"; Decimal)
        {
            Caption = 'Finished Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MinValue = 0;
        }
        field(42; "Remaining Quantity"; Decimal)
        {
            Caption = 'Remaining Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            MinValue = 0;
        }
        field(45; "Scrap %"; Decimal)
        {
            Caption = 'Scrap %';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(47; "Due Date"; Date)
        {
            Caption = 'Due Date';
            Editable = false;

            trigger OnValidate()
            begin
                CheckEndingDate(CurrFieldNo <> 0);
            end;
        }
        field(48; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                if "Ending Date" < "Starting Date" then
                    "Ending Date" := "Starting Date";

                Validate("Starting Time");
            end;
        }
        field(49; "Starting Time"; Time)
        {
            Caption = 'Starting Time';

            trigger OnValidate()
            var
                ProdOrderLine: Record "Prod. Order Line";
            begin
                if ProdOrderLine.Get(Status, "Prod. Order No.", "Line No.") then begin
                    Modify();

                    CalcProdOrder.Recalculate(Rec, 0, true);

                    OnAfterRecalculate(Rec, 0, CurrFieldNo);

                    Get(Status, "Prod. Order No.", "Line No.");
                end;
                if CurrFieldNo <> 0 then
                    Validate("Due Date");

                UpdateDatetime();
            end;
        }
        field(50; "Ending Date"; Date)
        {
            Caption = 'Ending Date';

            trigger OnValidate()
            begin
                if CurrFieldNo <> 0 then
                    UpdateManualScheduling();

                Validate("Ending Time");
            end;
        }
        field(51; "Ending Time"; Time)
        {
            Caption = 'Ending Time';

            trigger OnValidate()
            var
                ProdOrderLine: Record "Prod. Order Line";
                IsHandled: Boolean;
            begin
                if ProdOrderLine.Get(Status, "Prod. Order No.", "Line No.") then begin
                    Modify();

                    IsHandled := false;
                    OnValidateEndingTimeOnBeforeRecalculate(Rec, CurrFieldNo, IsHandled);
                    if IsHandled then
                        exit;

                    if (CurrFieldNo <> 0) and (Rec."Manual Scheduling") then
                        CalcProdOrder.Recalculate(Rec, 1, false)
                    else
                        CalcProdOrder.Recalculate(Rec, 1, true);

                    OnAfterRecalculate(Rec, 1, CurrFieldNo);

                    Get(Status, "Prod. Order No.", "Line No.");
                end;
                if CurrFieldNo <> 0 then
                    Validate("Due Date");

                UpdateDatetime();
            end;
        }
        field(52; "Planning Level Code"; Integer)
        {
            Caption = 'Planning Level Code';
            Editable = false;
        }
        field(53; Priority; Integer)
        {
            Caption = 'Priority';
        }
        field(60; "Production BOM No."; Code[20])
        {
            Caption = 'Production BOM No.';
            TableRelation = "Production BOM Header"."No.";

            trigger OnValidate()
            var
                ProdBOMHeader: Record "Production BOM Header";
                IsHandled: Boolean;
            begin
                "Production BOM Version Code" := '';
                if "Production BOM No." = '' then
                    exit;

                Validate("Production BOM Version Code", VersionMgt.GetBOMVersion("Production BOM No.", "Due Date", true));
                if "Production BOM Version Code" = '' then begin
                    ProdBOMHeader.Get("Production BOM No.");
                    IsHandled := false;
                    OnValidateProductionBOMNoOnBeforeTestStatus(Rec, IsHandled);
                    if not IsHandled then
                        ProdBOMHeader.TestField(Status, ProdBOMHeader.Status::Certified);
                    Validate("Unit of Measure Code", ProdBOMHeader."Unit of Measure Code");
                end;
            end;
        }
        field(61; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            TableRelation = "Routing Header"."No.";

            trigger OnValidate()
            var
                RoutingHeader: Record "Routing Header";
                ProdOrderRoutingLine: Record "Prod. Order Routing Line";
                CapLedgEntry: Record "Capacity Ledger Entry";
                PurchLine: Record "Purchase Line";
                ModifyRecord: Boolean;
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateRoutingNo(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                "Routing Version Code" := '';

                if "Routing No." <> xRec."Routing No." then begin
                    if Status = Status::Released then begin
                        if CheckCapLedgEntry() then
                            Error(
                              Text99000004Err,
                              FieldCaption("Routing No."), xRec."Routing No.", CapLedgEntry.TableCaption());

                        if CheckSubcontractPurchOrder() then
                            Error(
                              Text99000004Err,
                              FieldCaption("Routing No."), xRec."Routing No.", PurchLine.TableCaption());
                    end;

                    ModifyRecord := false;
                    OnBeforeDeleteProdOrderRtngLines(Rec, ModifyRecord);
                    if ModifyRecord then
                        Modify();

                    ProdOrderRoutingLine.SetRange(Status, Status);
                    ProdOrderRoutingLine.SetRange("Prod. Order No.", "Prod. Order No.");
                    ProdOrderRoutingLine.SetRange("Routing No.", xRec."Routing No.");
                    ProdOrderRoutingLine.SetRange("Routing Reference No.", "Line No.");
                    ProdOrderRoutingLine.DeleteAll(true);

                    OnAfterDeleteProdOrderRtngLines(Rec);
                end;

                if "Routing No." = '' then
                    exit;

                Validate("Routing Version Code", VersionMgt.GetRtngVersion("Routing No.", "Due Date", true));
                if "Routing Version Code" = '' then begin
                    RoutingHeader.Get("Routing No.");
                    RoutingHeader.TestField(Status, RoutingHeader.Status::Certified);
                    "Routing Type" := RoutingHeader.Type;
                end;

                GetDefaultBin();
            end;
        }
        field(62; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            TableRelation = "Inventory Posting Group";
        }
        field(63; "Routing Reference No."; Integer)
        {
            Caption = 'Routing Reference No.';
            Editable = false;
        }
        field(65; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost';

            trigger OnValidate()
            begin
                TestField("Item No.");
                GetItem();
                Item.TestField("Inventory Value Zero", false);
                if Item."Costing Method" = Item."Costing Method"::Standard then begin
                    if CurrFieldNo = FieldNo("Unit Cost") then
                        Error(
                          Text99000002,
                          FieldCaption("Unit Cost"), Item.FieldCaption("Costing Method"), Item."Costing Method");

                    if GetSKU() then
                        "Unit Cost" := SKU."Unit Cost" * "Qty. per Unit of Measure"
                    else
                        "Unit Cost" := Item."Unit Cost" * "Qty. per Unit of Measure";
                end;

                "Cost Amount" := Round(Quantity * "Unit Cost");
            end;
        }
        field(67; "Cost Amount"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Cost Amount';
            Editable = false;
        }
        field(68; "Reserved Quantity"; Decimal)
        {
            CalcFormula = sum("Reservation Entry".Quantity where("Source ID" = field("Prod. Order No."),
                                                                  "Source Ref. No." = const(0),
                                                                  "Source Type" = const(5406),
#pragma warning disable AL0603
                                                                  "Source Subtype" = field(Status),
#pragma warning restore
                                                                  "Source Batch Name" = const(''),
                                                                  "Source Prod. Order Line" = field("Line No."),
                                                                  "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Quantity';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(70; "Capacity Type Filter"; Enum "Capacity Type")
        {
            Caption = 'Capacity Type Filter';
            FieldClass = FlowFilter;
        }
        field(71; "Capacity No. Filter"; Code[20])
        {
            Caption = 'Capacity No. Filter';
            FieldClass = FlowFilter;
            TableRelation = if ("Capacity Type Filter" = const("Work Center")) "Work Center"
            else
            if ("Capacity Type Filter" = const("Machine Center")) "Machine Center";
        }
        field(72; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(73; "Qty. Rounding Precision"; Decimal)
        {
            Caption = 'Qty. Rounding Precision';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(74; "Qty. Rounding Precision (Base)"; Decimal)
        {
            Caption = 'Qty. Rounding Precision (Base)';
            InitValue = 0;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1;
            Editable = false;
        }
        field(75; "Manual Scheduling"; Boolean)
        {
            Caption = 'Manual Scheduling';
            Editable = false;
            ToolTip = 'Specifies that the End/Due Dates on the production have been scheduled manually.';
        }
        field(80; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));

            trigger OnValidate()
            begin
                GetItem();
                GetGLSetup();
                ProdOrderWarehouseMgt.ProdOrderLineVerifyChange(Rec, xRec);
                OnValidateUnitOfMeasureCodeOnAfterWhseValidateSourceLine(Rec, xRec, CurrFieldNo);

                "Unit Cost" := Item."Unit Cost";

                "Qty. per Unit of Measure" := UOMMgt.GetQtyPerUnitOfMeasure(Item, "Unit of Measure Code");
                "Qty. Rounding Precision" := UOMMgt.GetQtyRoundingPrecision(Item, "Unit of Measure Code");
                "Qty. Rounding Precision (Base)" := UOMMgt.GetQtyRoundingPrecision(Item, Item."Base Unit of Measure");

                "Unit Cost" :=
                  Round(Item."Unit Cost" * "Qty. per Unit of Measure",
                    GLSetup."Unit-Amount Rounding Precision");

                Validate(Quantity);
            end;
        }
        field(81; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;

            trigger OnValidate()
            var
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateQuantityBase(Rec, xRec, CurrFieldNo, IsHandled);
                if IsHandled then
                    exit;

                TestField("Qty. per Unit of Measure", 1);
                Validate(Quantity, "Quantity (Base)");
                "Remaining Quantity" := Quantity - "Finished Quantity";

                Validate("Ending Time");

                "Cost Amount" := Round(Quantity * "Unit Cost");
            end;
        }
        field(82; "Finished Qty. (Base)"; Decimal)
        {
            Caption = 'Finished Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(83; "Remaining Qty. (Base)"; Decimal)
        {
            Caption = 'Remaining Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(84; "Reserved Qty. (Base)"; Decimal)
        {
            CalcFormula = sum("Reservation Entry"."Quantity (Base)" where("Source ID" = field("Prod. Order No."),
                                                                           "Source Ref. No." = const(0),
                                                                           "Source Type" = const(5406),
#pragma warning disable AL0603
                                                                           "Source Subtype" = field(Status),
#pragma warning restore
                                                                           "Source Batch Name" = const(''),
                                                                           "Source Prod. Order Line" = field("Line No."),
                                                                           "Reservation Status" = const(Reservation)));
            Caption = 'Reserved Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(90; "Expected Operation Cost Amt."; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Prod. Order Routing Line"."Expected Operation Cost Amt." where(Status = field(Status),
                                                                                               "Prod. Order No." = field("Prod. Order No."),
                                                                                               "Routing No." = field("Routing No."),
                                                                                               "Routing Reference No." = field("Routing Reference No.")));
            Caption = 'Expected Operation Cost Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(91; "Total Exp. Oper. Output (Qty.)"; Decimal)
        {
            CalcFormula = sum("Prod. Order Line".Quantity where(Status = field(Status),
                                                                 "Prod. Order No." = field("Prod. Order No."),
                                                                 "Routing No." = field("Routing No."),
                                                                 "Routing Reference No." = field("Routing Reference No."),
                                                                 "Ending Date" = field("Date Filter")));
            Caption = 'Total Exp. Oper. Output (Qty.)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(94; "Expected Component Cost Amt."; Decimal)
        {
            AutoFormatType = 1;
            CalcFormula = sum("Prod. Order Component"."Cost Amount" where(Status = field(Status),
                                                                           "Prod. Order No." = field("Prod. Order No."),
                                                                           "Prod. Order Line No." = field("Line No."),
                                                                           "Due Date" = field("Date Filter")));
            Caption = 'Expected Component Cost Amt.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(198; "Starting Date-Time"; DateTime)
        {
            Caption = 'Starting Date-Time';

            trigger OnValidate()
            begin
                "Starting Date" := DT2Date("Starting Date-Time");
                "Starting Time" := DT2Time("Starting Date-Time");
                Validate("Starting Time");
            end;
        }
        field(199; "Ending Date-Time"; DateTime)
        {
            Caption = 'Ending Date-Time';

            trigger OnValidate()
            begin
                if CurrFieldNo <> 0 then
                    UpdateManualScheduling();

                "Ending Date" := DT2Date("Ending Date-Time");
                "Ending Time" := DT2Time("Ending Date-Time");
                Validate("Ending Time");
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
        field(5831; "Cost Amount (ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Cost Amount (ACY)';
            Editable = false;
        }
        field(5832; "Unit Cost (ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            Caption = 'Unit Cost (ACY)';
            Editable = false;
        }
        field(5850; "Qty. Put Away"; Decimal)
        {
            Caption = 'Qty. Put Away';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5851; "Qty. Put Away (Base)"; Decimal)
        {
            Caption = 'Qty. Put Away (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(5852; "Put-away Qty."; Decimal)
        {
            CalcFormula = sum("Warehouse Activity Line"."Qty. Outstanding" where("Activity Type" = const("Put-away"),
                                                                                  "Whse. Document Type" = const(Production),
                                                                                  "Whse. Document No." = field("Prod. Order No."),
                                                                                  "Whse. Document Line No." = field("Line No."),
                                                                                  "Unit of Measure Code" = field("Unit of Measure Code"),
                                                                                  "Action Type" = filter(" " | Take),
                                                                                  "Original Breakbulk" = const(false),
                                                                                  "Lot No." = field("Lot No. Filter"),
                                                                                  "Package No." = field("Package No. Filter"),
                                                                                  "Serial No." = field("Serial No. Filter")));
            Caption = 'Put-away Qty.';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(5853; "Put-away Qty. (Base)"; Decimal)
        {
            CalcFormula = sum("Warehouse Activity Line"."Qty. Outstanding (Base)" where("Activity Type" = const("Put-away"),
                                                                                         "Whse. Document Type" = const(Production),
                                                                                         "Whse. Document No." = field("Prod. Order No."),
                                                                                         "Whse. Document Line No." = field("Line No."),
                                                                                         "Action Type" = filter(" " | Take),
                                                                                         "Original Breakbulk" = const(false),
                                                                                         "Lot No." = field("Lot No. Filter"),
                                                                                         "Package No." = field("Package No. Filter"),
                                                                                         "Serial No." = field("Serial No. Filter")));
            Caption = 'Put-away Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
        }
        field(66; "Put-away Status"; Option)
        {
            Caption = 'Put-away Status';
            Editable = false;
            OptionCaption = ' ,Partially Put Away,Completely Put Away';
            OptionMembers = " ","Partially Put Away","Completely Put Away";
        }
        field(5854; "Lot No. Filter"; Code[50])
        {
            Caption = 'Lot No. Filter';
            FieldClass = FlowFilter;
        }
        field(5855; "Serial No. Filter"; Code[50])
        {
            Caption = 'Serial No. Filter';
            FieldClass = FlowFilter;
        }
        field(5856; "Package No. Filter"; Code[50])
        {
            Caption = 'Package No. Filter';
            FieldClass = FlowFilter;
        }
        field(99000750; "Production BOM Version Code"; Code[20])
        {
            Caption = 'Production BOM Version Code';
            TableRelation = "Production BOM Version"."Version Code" where("Production BOM No." = field("Production BOM No."));

            trigger OnValidate()
            var
                ProdBOMVersion: Record "Production BOM Version";
            begin
                if "Production BOM Version Code" = '' then
                    exit;

                ProdBOMVersion.Get("Production BOM No.", "Production BOM Version Code");
                ProdBOMVersion.TestField(Status, ProdBOMVersion.Status::Certified);
                Validate("Unit of Measure Code", ProdBOMVersion."Unit of Measure Code");
            end;
        }
        field(99000751; "Routing Version Code"; Code[20])
        {
            Caption = 'Routing Version Code';
            TableRelation = "Routing Version"."Version Code" where("Routing No." = field("Routing No."));

            trigger OnValidate()
            var
                RoutingVersion: Record "Routing Version";
            begin
                if "Routing Version Code" = '' then
                    exit;

                RoutingVersion.Get("Routing No.", "Routing Version Code");
                RoutingVersion.TestField(Status, RoutingVersion.Status::Certified);
                "Routing Type" := RoutingVersion.Type;
            end;
        }
        field(99000752; "Routing Type"; Option)
        {
            Caption = 'Routing Type';
            OptionCaption = 'Serial,Parallel';
            OptionMembers = Serial,Parallel;
        }
        field(99000753; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(99000754; "MPS Order"; Boolean)
        {
            Caption = 'MPS Order';
        }
        field(99000755; "Planning Flexibility"; Enum "Reservation Planning Flexibility")
        {
            Caption = 'Planning Flexibility';

            trigger OnValidate()
            begin
                if "Planning Flexibility" <> xRec."Planning Flexibility" then
                    ProdOrderLineReserve.UpdatePlanningFlexibility(Rec);
            end;
        }
        field(99000764; "Indirect Cost %"; Decimal)
        {
            Caption = 'Indirect Cost %';
            DecimalPlaces = 0 : 5;
        }
        field(99000765; "Overhead Rate"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Overhead Rate';
        }
    }

    keys
    {
        key(Key1; Status, "Prod. Order No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Prod. Order No.", "Line No.", Status)
        {
        }
        key(Key3; Status, "Item No.", "Variant Code", "Location Code", "Ending Date")
        {
            SumIndexFields = "Remaining Qty. (Base)", "Cost Amount";
        }
        key(Key4; Status, "Item No.", "Variant Code", "Location Code", "Starting Date")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Remaining Qty. (Base)";
        }
        key(Key5; Status, "Item No.", "Variant Code", "Location Code", "Due Date")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Remaining Qty. (Base)";
        }
        key(Key6; Status, "Item No.", "Variant Code", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Location Code", "Due Date")
        {
            Enabled = false;
            MaintainSIFTIndex = false;
            SumIndexFields = "Remaining Qty. (Base)";
        }
        key(Key7; Status, "Prod. Order No.", "Item No.")
        {
        }
        key(Key8; Status, "Prod. Order No.", "Routing No.", "Routing Reference No.")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = Quantity, "Finished Quantity";
        }
        key(Key9; Status, "Prod. Order No.", "Planning Level Code")
        {
        }
        key(Key10; "Planning Level Code", Priority)
        {
            Enabled = false;
        }
        key(Key11; "Item No.", "Variant Code", "Location Code", Status, "Ending Date")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Remaining Qty. (Base)";
        }
        key(Key12; "Item No.", "Variant Code", "Location Code", Status, "Due Date")
        {
            MaintainSIFTIndex = false;
            SumIndexFields = "Remaining Qty. (Base)";
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        CapLedgEntry: Record "Capacity Ledger Entry";
        PurchLine: Record "Purchase Line";
        RefreshRecord: Boolean;
    begin
        if Status = Status::Finished then
            Error(Text000, Status, TableCaption);

        if Status = Status::Released then begin
            ItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type"::Production);
            ItemLedgEntry.SetRange("Order No.", "Prod. Order No.");
            ItemLedgEntry.SetRange("Order Line No.", "Line No.");
            if not ItemLedgEntry.IsEmpty() then
                Error(
                  Text99000000,
                  TableCaption, "Line No.", ItemLedgEntry.TableCaption());

            if CheckCapLedgEntry() then
                Error(
                  Text99000000,
                  TableCaption, "Line No.", CapLedgEntry.TableCaption());

            if CheckSubcontractPurchOrder() then
                Error(
                  Text99000000,
                  TableCaption, "Line No.", PurchLine.TableCaption());
        end;

        ProdOrderLineReserve.DeleteLine(Rec);

        CalcFields("Reserved Qty. (Base)");
        TestField("Reserved Qty. (Base)", 0);
        ProdOrderWarehouseMgt.ProdOrderLineDelete(Rec);

        DeleteRelations();

        RefreshRecord := false;
        OnAfterOnDelete(Rec, RefreshRecord);
        if RefreshRecord then
            Get(Status, "Prod. Order No.", "Line No.");
    end;

    trigger OnInsert()
    begin
        if Status = Status::Finished then
            Error(Text000, Status, TableCaption);

        ProdOrderLineReserve.VerifyQuantity(Rec, xRec);
        if "Routing Reference No." < 0 then
            "Routing Reference No." := "Line No.";
    end;

    trigger OnModify()
    begin
        if Status = Status::Finished then
            Error(Text000, Status, TableCaption);

        ProdOrderLineReserve.VerifyChange(Rec, xRec);
    end;

    trigger OnRename()
    begin
        Error(Text99000001, TableCaption);
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'A %1 %2 cannot be inserted, modified, or deleted.';
#pragma warning restore AA0470
        Text99000000: Label 'You cannot delete %1 %2 because there is at least one %3 associated with it.', Comment = '%1 = Table Caption; %2 = Field Value; %3 = Table Caption';
#pragma warning disable AA0470
        Text99000001: Label 'You cannot rename a %1.';
        Text99000002: Label 'You cannot change %1 when %2 is %3.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        Text99000004Err: Label 'You cannot modify %1 %2 because there is at least one %3 associated with it.', Comment = '%1 = Field Caption; %2 = Field Value; %3 = Table Caption';
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        ProdOrder: Record "Production Order";
        GLSetup: Record "General Ledger Setup";
        Location: Record Location;
        MfgSetup: Record "Manufacturing Setup";
        ProdOrderLineReserve: Codeunit "Prod. Order Line-Reserve";
        ProdOrderWarehouseMgt: Codeunit "Prod. Order Warehouse Mgt.";
        UOMMgt: Codeunit "Unit of Measure Management";
        VersionMgt: Codeunit VersionManagement;
        CalcProdOrder: Codeunit "Calculate Prod. Order";
        DimMgt: Codeunit DimensionManagement;
        ConfirmManagement: Codeunit "Confirm Management";
        Blocked: Boolean;
        GLSetupRead: Boolean;
        IgnoreErrors: Boolean;
        ErrorOccured: Boolean;
        CalledFromComponent: Boolean;
        CalledFromHeader: Boolean;
        ConfirmUpdateDateIfEndDateIsGreaterOrEqualToDueDateQst: Label '%1 is greater or equal to %2 in %3 Status=%4,Prod. Order No.=%5, Line No.=%6. Do you want to continue?\\ If yes, %7 will be changed to %8.',
                                                                Comment = '%1 = Field Caption , %2 = Field Caption, %3 = Table Caption, %4 = Status , %5 = Production Order No., %6 = Production Order Line No., %7= Field Caption, %8 = New Date';

    procedure DeleteRelations()
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        WhseOutputProdRelease: Codeunit "Whse.-Output Prod. Release";
        IsHandled: Boolean;
    begin
        OnBeforeDeleteRelations(Rec);

        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderLine.SetRange("Routing No.", "Routing No.");
        ProdOrderLine.SetFilter("Line No.", '<>%1', "Line No.");
        ProdOrderLine.SetRange("Routing Reference No.", "Routing Reference No.");
        if ProdOrderLine.IsEmpty() then begin
            ProdOrderRoutingLine.SetRange(Status, Status);
            ProdOrderRoutingLine.SetRange("Prod. Order No.", "Prod. Order No.");
            ProdOrderRoutingLine.SetRange("Routing Reference No.", "Routing Reference No.");
            if ProdOrderRoutingLine.FindSet(true) then
                repeat
                    ProdOrderRoutingLine.SetSkipUpdateOfCompBinCodes(true);
                    IsHandled := false;
                    OnDeleteRelationsOnBeforeProdOrderRoutingLineDelete(ProdOrderRoutingLine, IsHandled);
                    if not IsHandled then
                        ProdOrderRoutingLine.Delete(true);
                until ProdOrderRoutingLine.Next() = 0;
        end;

        ProdOrderComp.Reset();
        ProdOrderComp.SetRange(Status, Status);
        ProdOrderComp.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", "Line No.");
        IsHandled := false;
        OnDeleteRelationsOnBeforeProdOrderCompDeleteAll(ProdOrderComp, Blocked, IsHandled);
        if not IsHandled then begin
            if CalledFromHeader then
                ProdOrderComp.SuspendDeletionCheck(true);
            ProdOrderComp.DeleteAll(true);
        end;

        if not CalledFromComponent then begin
            ProdOrderComp.SetRange("Prod. Order Line No.");
            ProdOrderComp.SetRange("Supplied-by Line No.", "Line No.");
            OnDeleteRelationsNotCalledFromComponentFilter(Rec, ProdOrderComp);
            ProdOrderComp.SetLoadFields("Planning Level Code");
            if ProdOrderComp.Find('-') then
                repeat
                    ProdOrderComp."Supplied-by Line No." := 0;
                    ProdOrderComp."Planning Level Code" -= 1;
                    OnDeleteRelationsNotCalledFromComponentInitFields(ProdOrderComp);
                    ProdOrderComp.Modify();
                until ProdOrderComp.Next() = 0;
        end;

        WhseOutputProdRelease.DeleteLine(Rec);

        OnAfterDeleteRelations(Rec);
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
        Reservation: Page Reservation;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowReservation(Rec, IsHandled);
        if IsHandled then
            exit;

        TestField("Item No.");
        Clear(Reservation);
        Reservation.SetReservSource(Rec);
        Reservation.RunModal();
    end;

    procedure ShowReservationEntries(Modal: Boolean)
    var
        ReservEntry: Record "Reservation Entry";
    begin
        TestField("Item No.");
        ReservEntry.InitSortingAndFilters(true);
        SetReservationFilters(ReservEntry);
        if Modal then
            PAGE.RunModal(PAGE::"Reservation Entries", ReservEntry)
        else
            PAGE.Run(PAGE::"Reservation Entries", ReservEntry);
    end;

    procedure CheckEndingDate(ShowWarning: Boolean)
    var
        MfgReserveCheckDateConfl: Codeunit "Mfg. ReservCheckDateConfl";
    begin
        OnBeforeCheckEndingDate(Rec, ShowWarning);
        if not Blocked then begin
            MfgReserveCheckDateConfl.ProdOrderLineCheck(Rec, ShowWarning);
            ProdOrderLineReserve.AssignForPlanning(Rec);
        end;

        OnAfterCheckEndingDate(Rec);
    end;

    procedure BlockDynamicTracking(SetBlock: Boolean)
    begin
        Blocked := SetBlock;
        ProdOrderLineReserve.Block(Blocked);
        CalcProdOrder.BlockDynamicTracking(Blocked);
    end;

    procedure IsDynamicTrackingBlocked(): Boolean
    begin
        exit(Blocked);
    end;

    procedure CreateDim(DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Dimension Set ID" :=
          DimMgt.GetRecDefaultDimID(
            Rec, CurrFieldNo, DefaultDimSource, '',
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", ProdOrder."Dimension Set ID", DATABASE::Item);

        OnAfterCreateDim(Rec, DefaultDimSource);
    end;

    procedure IsInbound(): Boolean
    begin
        exit("Quantity (Base)" > 0);
    end;

    procedure OpenItemTrackingLines()
    begin
        ProdOrderLineReserve.CallItemTracking(Rec);
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        OldDimSetID: Integer;
    begin
        OnBeforeValidateShortcutDimCode(Rec, xRec, FieldNumber, ShortcutDimCode);

        OldDimSetID := "Dimension Set ID";
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
        if OldDimSetID <> "Dimension Set ID" then begin
            Modify();
            if ProdOrderCompExist() then
                UpdateProdOrderCompDim("Dimension Set ID", OldDimSetID);
        end;

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

    local procedure GetItem()
    begin
        if Item."No." = "Item No." then
            exit;

        Item.Get("Item No.");
        OnAfterGetItem(Item, Rec);
    end;

    procedure GetLinePutAwayStatus(): Integer
    begin
        if "Qty. Put Away" > 0 then
            if "Qty. Put Away" < "Finished Quantity" then
                "Put-away Status" := "Put-away Status"::"Partially Put Away"
            else
                "Put-away Status" := "Put-away Status"::"Completely Put Away";

        exit("Put-away Status");
    end;

    local procedure GetSKU() Result: Boolean
    begin
        if (SKU."Location Code" = "Location Code") and
           (SKU."Item No." = "Item No.") and
           (SKU."Variant Code" = "Variant Code")
        then
            exit(true);

        Result := false;
        if SKU.Get("Location Code", "Item No.", "Variant Code") then
            Result := true;

        OnAfterGetSKU(Rec, Result);
    end;

    procedure GetUpdateFromSKU()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetUpdateFromSKU(Rec, SKU, Item, IsHandled);
        if not IsHandled then begin
            GetItem();
            if GetSKU() then begin
                "Unit Cost" := SKU."Unit Cost";
                if (SKU."Routing No." <> "Routing No.") and (SKU."Routing No." <> '') then begin
                    Validate("Routing No.", SKU."Routing No.");
                    "Cost Amount" := Round(Quantity * "Unit Cost");
                end;
                if (SKU."Production BOM No." <> "Production BOM No.") and (SKU."Production BOM No." <> '') then begin
                    Validate("Production BOM No.", SKU."Production BOM No.");
                    ValidateUnitofMeasureCodeFromItem();
                end;
            end else begin
                "Unit Cost" := Item."Unit Cost";
                "Cost Amount" := Round(Quantity * "Unit Cost");
                "Routing No." := Item."Routing No.";
                "Production BOM No." := Item."Production BOM No.";
            end;
        end;
        OnAfterGetUpdateFromSKU(Rec, Item, SKU);
    end;

    local procedure ValidateUnitofMeasureCodeFromItem()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateUnitofMeasureCodeFromItem(Rec, xRec, Item, ProdOrder, IsHandled);
        if IsHandled then
            exit;

        Validate("Unit of Measure Code", Item."Base Unit of Measure");
    end;

    procedure UpdateDatetime()
    begin
        if ("Starting Date" <> 0D) then
            "Starting Date-Time" := CreateDateTime("Starting Date", "Starting Time")
        else
            "Starting Date-Time" := 0DT;

        if ("Ending Date" <> 0D) then
            "Ending Date-Time" := CreateDateTime("Ending Date", "Ending Time")
        else
            "Ending Date-Time" := 0DT;

        OnAfterUpdateDateTime(Rec, xRec, CurrFieldNo);
    end;

    procedure ShowDimensions()
    var
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            Rec, "Dimension Set ID", StrSubstNo('%1 %2 %3', Status, "Prod. Order No.", "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");

        OnShowDimensionsOnAfterEditDimensionSet(Rec, OldDimSetID);
        if OldDimSetID <> "Dimension Set ID" then begin
            Modify();
            if ProdOrderCompExist() then
                UpdateProdOrderCompDim("Dimension Set ID", OldDimSetID);
        end;
    end;

    local procedure GetGLSetup()
    begin
        if not GLSetupRead then
            GLSetup.Get();
        GLSetupRead := true;
    end;

    local procedure GetAdditionalReportingCurrencyCode(): Code[10]
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            GLSetupRead := true;
        end;
        exit(GLSetup."Additional Reporting Currency");
    end;

    procedure RowID1(): Text[250]
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
    begin
        exit(
          ItemTrackingMgt.ComposeRowID(Database::"Prod. Order Line", Status.AsInteger(), "Prod. Order No.", '', "Line No.", 0));
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure GetDefaultBin()
    var
        WMSManagement: Codeunit "WMS Management";
    begin
        if (Quantity * xRec.Quantity > 0) and
           ("Item No." = xRec."Item No.") and
           ("Location Code" = xRec."Location Code") and
           ("Variant Code" = xRec."Variant Code") and
           ("Routing No." = xRec."Routing No.")
        then
            exit;

        "Bin Code" := '';
        if ("Location Code" <> '') and ("Item No." <> '') then begin
            "Bin Code" :=
                ProdOrderWarehouseMgt.GetLastOperationFromBinCode(
                    "Routing No.", "Routing Version Code", "Location Code", false, Enum::"Flushing Method"::Manual);
            GetLocation("Location Code");
            if "Bin Code" = '' then
                "Bin Code" := Location."From-Production Bin Code";
            if ("Bin Code" = '') and Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then
                WMSManagement.GetDefaultBin("Item No.", "Variant Code", "Location Code", "Bin Code");
        end;
        Validate("Bin Code");
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
    begin
        exit(StrSubstNo('%1 %2 %3 %4', Status, TableCaption(), "Prod. Order No.", "Item No."));
    end;

    procedure SetReservationEntry(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSource(Database::"Prod. Order Line", Status.AsInteger(), "Prod. Order No.", 0, '', "Line No.");
        ReservEntry.SetItemData("Item No.", Description, "Location Code", "Variant Code", "Qty. per Unit of Measure");
        ReservEntry."Expected Receipt Date" := "Due Date";
        ReservEntry."Shipment Date" := "Due Date";
        ReservEntry."Planning Flexibility" := "Planning Flexibility";
    end;

    procedure SetReservationFilters(var ReservEntry: Record "Reservation Entry")
    begin
        ReservEntry.SetSourceFilter(Database::"Prod. Order Line", Status.AsInteger(), "Prod. Order No.", 0, false);
        ReservEntry.SetSourceFilter('', "Line No.");

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

    local procedure CheckBin()
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
            SetFilter("Remaining Qty. (Base)", '>0')
        else
            SetFilter("Remaining Qty. (Base)", '<0');

        OnAfterFilterLinesForReservation(Rec, ReservationEntry, NewStatus, AvailabilityFilter, Positive);
    end;

    procedure SetIgnoreErrors()
    begin
        IgnoreErrors := true;
    end;

    procedure SetCalledFromComponent(NewCalledFromComponent: Boolean)
    begin
        CalledFromComponent := NewCalledFromComponent;
    end;

    procedure HasErrorOccured(): Boolean
    begin
        exit(ErrorOccured);
    end;

    procedure UpdateProdOrderComp(QtyPerUnitOfMeasure: Decimal)
    var
        ProdOrderComp: Record "Prod. Order Component";
        ModifyRecord: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateProdOrderComp(Rec, QtyPerUnitOfMeasure, CurrFieldNo, IsHandled, ProdOrderComp, Blocked);
        if IsHandled then
            exit;

        ProdOrderComp.SetRange(Status, Status);
        ProdOrderComp.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", "Line No.");
        if ProdOrderComp.FindSet() then begin
            ModifyRecord := false;
            OnUpdateProdOrderCompOnAfterFind(Rec, ModifyRecord);
            if ModifyRecord then
                Modify();
            repeat
                if QtyPerUnitOfMeasure <> 0 then
                    ProdOrderComp.Validate(
                      "Quantity per",
                      ProdOrderComp."Quantity per" * "Qty. per Unit of Measure" /
                      QtyPerUnitOfMeasure)
                else
                    ProdOrderComp.Validate("Quantity per", "Qty. per Unit of Measure");
                OnUpdateProdOrderCompOnBeforeModify(Rec, ProdOrderComp);
                ProdOrderComp.Modify();
            until ProdOrderComp.Next() = 0;
        end;
    end;

    local procedure CheckCapLedgEntry(): Boolean
    var
        CapLedgEntry: Record "Capacity Ledger Entry";
    begin
        CapLedgEntry.SetCurrentKey("Order Type", "Order No.", "Order Line No.");
        CapLedgEntry.SetRange("Order Type", CapLedgEntry."Order Type"::Production);
        CapLedgEntry.SetRange("Order No.", "Prod. Order No.");
        CapLedgEntry.SetRange("Order Line No.", "Line No.");

        exit(not CapLedgEntry.IsEmpty);
    end;

    local procedure CheckSubcontractPurchOrder(): Boolean
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.SetCurrentKey(
          "Document Type", Type, "Prod. Order No.", "Prod. Order Line No.", "Routing No.", "Operation No.");
        PurchLine.SetRange("Document Type", PurchLine."Document Type"::Order);
        PurchLine.SetRange(Type, PurchLine.Type::Item);
        PurchLine.SetRange("Prod. Order No.", "Prod. Order No.");
        PurchLine.SetRange("Prod. Order Line No.", "Line No.");

        exit(not PurchLine.IsEmpty);
    end;

    local procedure ProdOrderCompExist(): Boolean
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        ProdOrderComp.SetRange(Status, Status);
        ProdOrderComp.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", "Line No.");
        exit(not ProdOrderComp.IsEmpty);
    end;

    procedure UpdateProdOrderCompDim(NewDimSetID: Integer; OldDimSetID: Integer)
    var
        ProdOrderComp: Record "Prod. Order Component";
        NewCompDimSetID: Integer;
    begin
        if NewDimSetID = OldDimSetID then
            exit;

        ProdOrderComp.Reset();
        ProdOrderComp.SetRange(Status, Status);
        ProdOrderComp.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", "Line No.");
        ProdOrderComp.LockTable();
        if ProdOrderComp.FindSet() then
            repeat
                NewCompDimSetID := DimMgt.GetDeltaDimSetID(ProdOrderComp."Dimension Set ID", NewDimSetID, OldDimSetID);
                if ProdOrderComp."Dimension Set ID" <> NewCompDimSetID then begin
                    ProdOrderComp."Dimension Set ID" := NewCompDimSetID;
                    DimMgt.UpdateGlobalDimFromDimSetID(
                      ProdOrderComp."Dimension Set ID", ProdOrderComp."Shortcut Dimension 1 Code", ProdOrderComp."Shortcut Dimension 2 Code");
                    ProdOrderComp.Modify();
                end;
            until ProdOrderComp.Next() = 0;
    end;

    procedure ShowRouting()
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        LastProdOrderRoutingLine: Record "Prod. Order Routing Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowRouting(Rec, IsHandled);
        if IsHandled then
            exit;

        ProdOrderRoutingLine.SetRange(Status, Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", "Prod. Order No.");
        ProdOrderRoutingLine.SetRange("Routing Reference No.", "Routing Reference No.");
        ProdOrderRoutingLine.SetRange("Routing No.", "Routing No.");

        LastProdOrderRoutingLine.CopyFilters(ProdOrderRoutingLine);
        if LastProdOrderRoutingLine.FindLast() then;

        PAGE.RunModal(PAGE::"Prod. Order Routing", ProdOrderRoutingLine);

        ProdOrderRoutingLine.Reset();
        ProdOrderRoutingLine.CopyFilters(LastProdOrderRoutingLine);
        if ProdOrderRoutingLine.FindLast() and
           (ProdOrderRoutingLine.Type = LastProdOrderRoutingLine.Type) and
           (ProdOrderRoutingLine."No." = LastProdOrderRoutingLine."No.") and
           ("Bin Code" <> '')
        then
            exit;

        IsHandled := false;
        OnShowRoutingOnBeforeFindAndSetProdOrderLineBinCodeFromProdRoutingLines(Rec, IsHandled);
        if not IsHandled then
            CalcProdOrder.FindAndSetProdOrderLineBinCodeFromProdRoutingLines(Status, "Prod. Order No.", "Line No.");
    end;

    procedure SetFilterByReleasedOrderNo(OrderNo: Code[20])
    begin
        Reset();
        SetCurrentKey(Status, "Prod. Order No.", "Line No.", "Item No.");
        SetRange(Status, Status::Released);
        SetRange("Prod. Order No.", OrderNo);
    end;

    procedure TestItemFields(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    begin
        TestField("Item No.", ItemNo);
        TestField("Variant Code", VariantCode);
        TestField("Location Code", LocationCode);
    end;

    [Scope('OnPrem')]
    procedure GetStartingEndingDateAndTime(var StartingTime: Time; var StartingDate: Date; var EndingTime: Time; var EndingDate: Date)
    begin
        StartingTime := DT2Time("Starting Date-Time");
        StartingDate := DT2Date("Starting Date-Time");
        EndingTime := DT2Time("Ending Date-Time");
        EndingDate := DT2Date("Ending Date-Time");
    end;

    local procedure CalcBaseQty(Qty: Decimal; FromFieldName: Text; ToFieldName: Text) Result: Decimal
    begin
        Result := UOMMgt.CalcBaseQty("Item No.", "Variant Code", "Unit of Measure Code", Qty, "Qty. per Unit of Measure", "Qty. Rounding Precision (Base)", FieldCaption("Qty. Rounding Precision"), FromFieldName, ToFieldName);
        OnAfterCalcBaseQty(Rec, xRec, Result, FromFieldName, ToFieldName);
    end;

    procedure IsStatusLessThanReleased(): Boolean
    begin
        exit((Status = Status::Simulated) or (Status = Status::Planned) or (Status = Status::"Firm Planned"));
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

        OnAfterInitDefaultDimensionSources(Rec, DefaultDimSource, CurrFieldNo);
    end;

    procedure SuspendDeletionCheck(Suspend: Boolean)
    begin
        CalledFromHeader := Suspend;
    end;

    procedure GetRemainingPutAwayQty(): Decimal
    begin
        Rec.CalcFields("Put-away Qty. (Base)");
        exit(Rec."Finished Qty. (Base)" - (Rec."Put-away Qty. (Base)" + Rec."Qty. Put Away (Base)"));
    end;

    local procedure GetMfgSetup()
    begin
        MfgSetup.GetRecordOnce();
    end;

    local procedure UpdateManualScheduling()
    begin
        GetMfgSetup();

        Rec.Validate("Manual Scheduling", MfgSetup."Manual Scheduling");
    end;

    procedure ConfirmUpdateDueDateAndEndingDate(NewFieldCaption: Text; NewFieldValue: Date): Boolean
    begin
        if not Rec."Manual Scheduling" then
            exit(true);

        if not ConfirmManagement.GetResponseOrDefault(
            StrSubstNo(
                ConfirmUpdateDateIfEndDateIsGreaterOrEqualToDueDateQst, Rec.FieldCaption("Ending Date"), Rec.FieldCaption("Due Date"), Rec.TableCaption(),
                Rec.Status, Rec."Prod. Order No.", Rec."Line No.", NewFieldCaption, NewFieldValue), false)
        then
            Error('');

        exit(true);
    end;

    internal procedure GetUsedPutAwayQtyPerItemTracking(LotNo: Code[50]; SerialNo: Code[50]; PackageNo: Code[50]): Decimal
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        RegisteredWhseActivityLine.SetRange("Whse. Document Type", RegisteredWhseActivityLine."Whse. Document Type"::Production);
        RegisteredWhseActivityLine.SetRange("Source Document", RegisteredWhseActivityLine."Source Document"::"Prod. Output");
        RegisteredWhseActivityLine.Setrange("Whse. Document No.", Rec."Prod. Order No.");
        RegisteredWhseActivityLine.SetRange("Whse. Document Line No.", Rec."Line No.");
        RegisteredWhseActivityLine.SetRange("Activity Type", RegisteredWhseActivityLine."Activity Type"::"Put-away");
        RegisteredWhseActivityLine.SetFilter("Action Type", '%1|%2', RegisteredWhseActivityLine."Action Type"::Place, RegisteredWhseActivityLine."Action Type"::" ");

        if LotNo <> '' then begin
            Rec.SetRange("Lot No. Filter", LotNo);
            RegisteredWhseActivityLine.SetRange("Lot No.", LotNo);
        end;

        if SerialNo <> '' then begin
            Rec.SetRange("Serial No. Filter", SerialNo);
            RegisteredWhseActivityLine.SetRange("Serial No.", SerialNo);
        end;

        if PackageNo <> '' then begin
            Rec.SetRange("Package No. Filter", PackageNo);
            RegisteredWhseActivityLine.SetRange("Package No.", PackageNo);
        end;

        if not RegisteredWhseActivityLine.IsEmpty() then
            RegisteredWhseActivityLine.CalcSums("Qty. (Base)");
        Rec.CalcFields("Put-away Qty. (Base)");
        exit(Rec."Put-away Qty. (Base)" + RegisteredWhseActivityLine."Qty. (Base)");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var ProdOrderLine: Record "Prod. Order Line"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckEndingDate(var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcBaseQty(var ProdOrderLine: Record "Prod. Order Line"; var xProdOrderLine: Record "Prod. Order Line"; var Result: Decimal; FromFieldName: Text; ToFieldName: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyFromItem(var ProdOrderLine: Record "Prod. Order Line"; Item: Record Item; var xProdOrderLine: Record "Prod. Order Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDim(var ProdOrderLine: Record "Prod. Order Line"; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetItem(var Item: Record Item; var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSKU(ProdOrderLine: Record "Prod. Order Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetUpdateFromSKU(var ProdOrderLine: Record "Prod. Order Line"; var Item: Record Item; var StockkeepingUnit: Record "Stockkeeping Unit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteProdOrderRtngLines(var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterLinesWithItemToPlan(var ProdOrderLine: Record "Prod. Order Line"; var Item: Record Item; IncludeFirmPlanned: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterLinesForReservation(var ProdOrderLine: Record "Prod. Order Line"; ReservationEntry: Record "Reservation Entry"; NewStatus: Option; AvailabilityFilter: Text; Positive: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterOnDelete(var ProdOrderLine: Record "Prod. Order Line"; var RefreshRecord: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecalculate(var ProdOrderLine: Record "Prod. Order Line"; Direction: Option; var CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetReservationFilters(var ReservEntry: Record "Reservation Entry"; ProdOrderLine: Record "Prod. Order Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateDateTime(var ProdOrderLine: Record "Prod. Order Line"; var xProdOrderLine: Record "Prod. Order Line"; CallingFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterValidateShortcutDimCode(var ProdOrderLine: Record "Prod. Order Line"; var xProdOrderLine: Record "Prod. Order Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckEndingDate(var ProdOrderLine: Record "Prod. Order Line"; var ShowWarning: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetUpdateFromSKU(var ProdOrderLine: Record "Prod. Order Line"; var SKU: Record "Stockkeeping Unit"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteRelations(var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteProdOrderRtngLines(var ProdOrderLine: Record "Prod. Order Line"; var ModifyRecord: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowReservation(var ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateShortcutDimCode(var ProdOrderLine: Record "Prod. Order Line"; var xProdOrderLine: Record "Prod. Order Line"; FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateRoutingNo(var ProdOrderLine: Record "Prod. Order Line"; var xProdOrderLine: Record "Prod. Order Line"; FieldNumber: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateUnitofMeasureCodeFromItem(var ProdOrderLine: Record "Prod. Order Line"; xProdOrderLine: Record "Prod. Order Line"; var Item: Record Item; var ProductionOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteRelationsNotCalledFromComponentFilter(var ProdOrderLine: Record "Prod. Order Line"; var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteRelationsNotCalledFromComponentInitFields(var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateProdOrderCompOnAfterFind(var ProdOrderLine: Record "Prod. Order Line"; var ModifyRecord: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateProdOrderCompOnBeforeModify(var ProdOrderLine: Record "Prod. Order Line"; var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantity(var ProdOrderLine: Record "Prod. Order Line"; xProdOrderLine: Record "Prod. Order Line"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateQuantityBase(var ProdOrderLine: Record "Prod. Order Line"; xProdOrderLine: Record "Prod. Order Line"; CurrFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateProdOrderComp(var ProdOrderLine: Record "Prod. Order Line"; QtyPerUnitOfMeasure: Decimal; CurrFieldNo: Integer; var IsHandled: Boolean; var ProdOrderComp: Record "Prod. Order Component"; Blocked: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteRelationsOnBeforeProdOrderCompDeleteAll(var ProdOrderComp: Record "Prod. Order Component"; Blocked: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteRelationsOnBeforeProdOrderRoutingLineDelete(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnAfterAssignItemValues(var ProdOrderLine: Record "Prod. Order Line"; Item: Record Item; xProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateProductionBOMNoOnBeforeTestStatus(var ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateLocationCodeOnBeforeCreateDim(var Rec: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateUnitOfMeasureCodeOnAfterWhseValidateSourceLine(var ProdOrderLine: Record "Prod. Order Line"; xProdOrderLine: Record "Prod. Order Line"; CurrentFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowRouting(var ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateQuantityOnAfterCalcBaseQty(var ProdOrderLine: Record "Prod. Order Line"; xProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateEndingTimeOnBeforeRecalculate(var ProdOrderLine: Record "Prod. Order Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateItemNoOnBeforeCheckReservations(var ProdOrderLine: Record "Prod. Order Line"; xProdOrderLine: Record "Prod. Order Line"; CurrentFieldNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowDimensionsOnAfterEditDimensionSet(var ProdOrderLine: Record "Prod. Order Line"; OldDimSetID: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidateVariantCodeOnAfterVerifyChange(var ProdOrderLine: Record "Prod. Order Line"; xProdOrderLine: Record "Prod. Order Line"; CurrFieldNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteRelations(var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowRoutingOnBeforeFindAndSetProdOrderLineBinCodeFromProdRoutingLines(var ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;
}
