// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Inventory;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Family;
using Microsoft.Manufacturing.Setup;
using Microsoft.Sales.Document;

codeunit 99000787 "Create Prod. Order Lines"
{
    Permissions = TableData Item = r,
                  TableData "Sales Header" = r,
                  TableData "Sales Line" = r,
                  TableData "Prod. Order Line" = rimd,
                  TableData "Prod. Order Component" = rimd,
                  TableData "Manufacturing Setup" = rim,
                  TableData "Family Line" = r,
                  TableData "Production Order" = r;

    trigger OnRun()
    begin
    end;

    var
        SalesLine: Record "Sales Line";
        MfgSetup: Record "Manufacturing Setup";
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        TempOldProdOrderComp: Record "Prod. Order Component" temporary;
        CalcProdOrder: Codeunit "Calculate Prod. Order";
        NextProdOrderLineNo: Integer;
        InsertNew: Boolean;
        SalesLineIsSet: Boolean;

    procedure CheckStructure(Status: Option; ProdOrderNo: Code[20]; Direction: Option Forward,Backward; MultiLevel: Boolean; LetDueDateDecrease: Boolean)
    begin
        ProdOrder.Get(Status, ProdOrderNo);
        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
        if ProdOrderLine.Find('+') then
            NextProdOrderLineNo := ProdOrderLine."Line No." + 10000
        else
            NextProdOrderLineNo := 10000;

        CheckMultiLevelStructure(Direction, MultiLevel, LetDueDateDecrease);
    end;

    procedure Copy(ProdOrder2: Record "Production Order"; Direction: Option Forward,Backward; VariantCode: Code[10]; LetDueDateDecrease: Boolean): Boolean
    var
        ErrorOccured: Boolean;
        IsHandled: Boolean;
    begin
        OnBeforeCopy(ProdOrder2, Direction, VariantCode, LetDueDateDecrease, ErrorOccured, IsHandled);
        if IsHandled then
            exit(not ErrorOccured);

        MfgSetup.Get();

        ProdOrder2.TestField("Source No.");
        ProdOrder2.TestField("Starting Time");
        ProdOrder2.TestField("Starting Date");
        ProdOrder2.TestField("Ending Time");
        ProdOrder2.TestField("Ending Date");
        if Direction = Direction::Backward then
            ProdOrder2.TestField("Due Date");

        ProdOrder := ProdOrder2;

        CreateProdOrderLine(ProdOrder, VariantCode, ErrorOccured);

        if not ProcessProdOrderLines(Direction, LetDueDateDecrease) then
            ErrorOccured := true;

        CheckMultiLevelStructure(Direction, true, LetDueDateDecrease);

        OnAfterCopy(ProdOrder, ErrorOccured);

        exit(not ErrorOccured);
    end;

    local procedure CopyFromFamily(): Boolean
    var
        Family: Record Family;
        FamilyLine: Record "Family Line";
        ErrorOccured: Boolean;
    begin
        Family.Get(ProdOrder."Source No.");
        FamilyLine.SetCurrentKey("Low-Level Code");
        FamilyLine.SetRange("Family No.", ProdOrder."Source No.");
        OnCopyFromFamilyOnAfterFamilyLineSetFilters(FamilyLine, ProdOrder);

        if FamilyLine.FindSet() then
            repeat
                if FamilyLine."Item No." <> '' then begin
                    InitProdOrderLine(FamilyLine."Item No.", '', ProdOrder."Location Code");
                    OnCopyFromFamilyOnAfterInitProdOrderLine(ProdOrder, FamilyLine, ProdOrderLine);
                    ProdOrderLine.Description := FamilyLine.Description;
                    ProdOrderLine."Description 2" := FamilyLine."Description 2";
                    ProdOrderLine.Validate("Unit of Measure Code", FamilyLine."Unit of Measure Code");
                    ProdOrderLine.Validate(Quantity, FamilyLine.Quantity * ProdOrder.Quantity);
                    ProdOrderLine."Routing No." := Family."Routing No.";
                    ProdOrderLine."Routing Reference No." := 0;
                    ProdOrderLine.UpdateDatetime();
                    OnCopyFromFamilyOnBeforeInsertProdOrderLine(ProdOrderLine, FamilyLine);
                    InsertProdOrderLine();
                    if ProdOrderLine.HasErrorOccured() then
                        ErrorOccured := true;
                    OnCopyFromFamilyOnAfterInsertProdOrderLine(ProdOrderLine);
                end;
            until FamilyLine.Next() = 0;
        exit(not ErrorOccured);
    end;

    procedure CopyFromSalesOrder(SalesHeader: Record "Sales Header"): Boolean
    var
        TempSalesPlanningLine: Record "Sales Planning Line" temporary;
        TrackingSpecification: Record "Tracking Specification";
        Location: Record Location;
        LeadTimeMgt: Codeunit "Lead-Time Management";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        ErrorOccured: Boolean;
        ShouldCreateTempSalesPlanningLines: Boolean;
        QuantityBase: Decimal;
    begin
        OnBeforeCopyFromSalesOrder(SalesHeader, SalesLine, ProdOrder, NextProdOrderLineNo);

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                SalesLine.CalcFields("Reserved Quantity");
                ShouldCreateTempSalesPlanningLines := (SalesLine.Type = SalesLine.Type::Item) and
                   (SalesLine."No." <> '') and
                   ((SalesLine."Outstanding Quantity" - SalesLine."Reserved Quantity") <> 0);
                OnCopyFromSalesOrderOnAfterCalcShouldCreateTempSalesPlanningLines(SalesLine, ShouldCreateTempSalesPlanningLines);
                if ShouldCreateTempSalesPlanningLines then
                    if IsReplSystemProdOrder(SalesLine."No.", SalesLine."Variant Code", SalesLine."Location Code") then begin
                        TempSalesPlanningLine.Init();
                        TempSalesPlanningLine."Sales Order No." := SalesLine."Document No.";
                        TempSalesPlanningLine."Sales Order Line No." := SalesLine."Line No.";
                        TempSalesPlanningLine.Validate("Item No.", SalesLine."No.");
                        OnCopyFromSalesOrderOnBeforeSalesPlanLineInsert(SalesLine, TempSalesPlanningLine);
                        TempSalesPlanningLine.Insert();
                    end;
            until SalesLine.Next() = 0;
        OnCopyFromSalesOrderOnAfterSalesPlanLinesInsert(SalesHeader, SalesLine);

        TempSalesPlanningLine.SetCurrentKey("Low-Level Code");
        if TempSalesPlanningLine.FindSet() then
            repeat
                SalesLine.Get(SalesHeader."Document Type", TempSalesPlanningLine."Sales Order No.", TempSalesPlanningLine."Sales Order Line No.");
                SalesLine.CalcFields("Reserved Quantity");

                InitProdOrderLine(SalesLine."No.", SalesLine."Variant Code", SalesLine."Location Code");
                ProdOrderLine.Description := SalesLine.Description;
                ProdOrderLine."Description 2" := SalesLine."Description 2";
                SalesLine.CalcFields("Reserved Qty. (Base)");
                QuantityBase := SalesLine."Outstanding Qty. (Base)" - SalesLine."Reserved Qty. (Base)";
                OnCopyFromSalesOrderOnAfterCalcQuantityBase(ProdOrderLine, SalesLineIsSet, SalesLine, QuantityBase);
                ProdOrderLine.Validate("Quantity (Base)", QuantityBase);

                if Location.Get(ProdOrderLine."Location Code") and not Location."Require Pick" and (SalesLine."Bin Code" <> '') then
                    ProdOrderLine."Bin Code" := SalesLine."Bin Code";

                ProdOrderLine."Due Date" := SalesLine."Shipment Date";
                ProdOrderLine."Ending Date" :=
                  LeadTimeMgt.GetPlannedEndingDate(
                    ProdOrderLine."Item No.", ProdOrderLine."Location Code", ProdOrderLine."Variant Code",
                    ProdOrderLine."Due Date", '', Enum::"Requisition Ref. Order Type"::"Prod. Order");
                ProdOrderLine.Validate("Ending Date");

                OnBeforeProdOrderLineInsert(ProdOrderLine, ProdOrder, true, SalesLine);
                InsertProdOrderLine();
                if ProdOrderLine.HasErrorOccured() then
                    ErrorOccured := true;
                ItemTrackingMgt.CopyItemTracking(SalesLine.RowID1(), ProdOrderLine.RowID1(), true, true);

                if SalesLine."Document Type" = SalesLine."Document Type"::Order then begin // Not simulated
                    ProdOrderLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
                    TrackingSpecification.InitTrackingSpecification(
                        Database::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.", 0,
                        ProdOrderLine."Variant Code", ProdOrderLine."Location Code", ProdOrderLine."Qty. per Unit of Measure");
                    SalesLineReserve.BindToTracking(
                        SalesLine, TrackingSpecification, ProdOrderLine.Description, ProdOrderLine."Ending Date",
                        ProdOrderLine."Remaining Quantity" - ProdOrderLine."Reserved Quantity",
                        ProdOrderLine."Remaining Qty. (Base)" - ProdOrderLine."Reserved Qty. (Base)");
                end;
                CopyDimFromSalesLine(SalesLine, ProdOrderLine);
                OnCopyFromSalesOrderOnBeforeProdOrderLineModify(ProdOrderLine, SalesLine, TempSalesPlanningLine, NextProdOrderLineNo);
                ProdOrderLine.Modify();
                OnCopyFromSalesOrderOnAfterProdOrderLineModify(ProdOrderLine, SalesLine);
            until (TempSalesPlanningLine.Next() = 0);
        exit(not ErrorOccured);
    end;

    local procedure CreateProdOrderLine(ProdOrder: Record "Production Order"; VariantCode: Code[10]; var ErrorOccured: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        DeleteLinesForProductionOrder(ProdOrder);

        NextProdOrderLineNo := 10000;

        InsertNew := false;

        case ProdOrder."Source Type" of
            ProdOrder."Source Type"::Item:
                begin
                    OnCreateProdOrderLineOnBeforeInitProdOrderLine(InsertNew);
                    InitProdOrderLine(ProdOrder."Source No.", VariantCode, ProdOrder."Location Code");
                    ProdOrderLine.Description := ProdOrder.Description;
                    ProdOrderLine."Description 2" := ProdOrder."Description 2";
                    ProdOrderLine.Validate(Quantity, ProdOrder.Quantity);
                    ProdOrderLine.UpdateDatetime();
                    if SalesLineIsSet then
                        CopyDimFromSalesLine(SalesLine, ProdOrderLine);
                    OnBeforeProdOrderLineInsert(ProdOrderLine, ProdOrder, SalesLineIsSet, SalesLine);
                    ProdOrderLine.Insert();
                    if ProdOrderLine.HasErrorOccured() then
                        ErrorOccured := true;

                    OnAfterProdOrderLineInsert(ProdOrder, ProdOrderLine, NextProdOrderLineNo);
                end;
            ProdOrder."Source Type"::Family:
                if not CopyFromFamily() then
                    ErrorOccured := true;
            ProdOrder."Source Type"::"Sales Header":
                begin
                    InsertNew := true;
                    if ProdOrder.Status <> ProdOrder.Status::Simulated then
                        SalesHeader.Get(SalesHeader."Document Type"::Order, ProdOrder."Source No.")
                    else
                        SalesHeader.Get(SalesHeader."Document Type"::Quote, ProdOrder."Source No.");
                    if not CopyFromSalesOrder(SalesHeader) then
                        ErrorOccured := true;
                end;
        end;

        OnAfterCreateProdOrderLine(ProdOrder, VariantCode, ErrorOccured);
    end;

    local procedure DeleteLinesForProductionOrder(ProductionOrder: Record "Production Order")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteLinesForProductionOrder(ProductionOrder, NextProdOrderLineNo, IsHandled);
        if IsHandled then
            exit;

        ProdOrderLine.LockTable();
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.DeleteAll(true);
    end;

    procedure InitProdOrderLine(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    var
        Item: Record Item;
        ProdOrderWarehouseMgt: Codeunit "Prod. Order Warehouse Mgt.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitProdOrderLine(ProdOrder, SalesLine, ItemNo, VariantCode, LocationCode, IsHandled);
        if IsHandled then
            exit;

        ProdOrderLine.Init();
        ProdOrderLine.SetIgnoreErrors();
        ProdOrderLine.Status := ProdOrder.Status;
        ProdOrderLine."Prod. Order No." := ProdOrder."No.";
        ProdOrderLine."Line No." := NextProdOrderLineNo;
        ProdOrderLine."Routing Reference No." := ProdOrderLine."Line No.";
        OnInitProdOrderLineBeforeAssignItemNo(ProdOrderLine, ItemNo, VariantCode, LocationCode);
        ProdOrderLine.Validate("Item No.", ItemNo);
        ProdOrderLine."Location Code" := LocationCode;
        ProdOrderWarehouseMgt.CompareProdOrderWithProdOrderLinesForLocation(ProdOrder, ProdOrderLine);
        ProdOrderWarehouseMgt.ValidateWarehousePutAwayLocation(ProdOrderLine);
        ProdOrderLine.Validate("Variant Code", VariantCode);
        OnInitProdOrderLineAfterVariantCode(ProdOrderLine, VariantCode);
        if (LocationCode = ProdOrder."Location Code") and (ProdOrder."Bin Code" <> '') then
            ProdOrderLine.Validate("Bin Code", ProdOrder."Bin Code")
        else
            CalcProdOrder.SetProdOrderLineBinCodeFromRoute(ProdOrderLine, ProdOrderLine."Location Code", ProdOrderLine."Routing No.");

        Item.Get(ItemNo);
        ProdOrderLine."Scrap %" := Item."Scrap %";
        OnInitProdOrderLineAfterScrap(ProdOrderLine, ProdOrder);
        ProdOrderLine."Due Date" := ProdOrder."Due Date";
        ProdOrderLine."Starting Date" := ProdOrder."Starting Date";
        ProdOrderLine."Starting Time" := ProdOrder."Starting Time";
        ProdOrderLine."Ending Date" := ProdOrder."Ending Date";
        ProdOrderLine."Ending Time" := ProdOrder."Ending Time";
        ProdOrderLine."Planning Level Code" := 0;
        ProdOrderLine."Inventory Posting Group" := Item."Inventory Posting Group";
        ProdOrderLine.UpdateDatetime();
        ProdOrderLine.Validate("Unit Cost");

        OnAfterInitProdOrderLine(ProdOrderLine, ProdOrder, SalesLine);

        NextProdOrderLineNo := NextProdOrderLineNo + 10000;
    end;

    procedure InsertProdOrderLine(): Boolean
    var
        ProdOrderLine3: Record "Prod. Order Line";
        IsHandled: Boolean;
    begin
        ProdOrderLine3 := ProdOrderLine;
        ProdOrderLine3.SetRange(Status, ProdOrderLine.Status);
        ProdOrderLine3.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderLine3.SetRange("Item No.", ProdOrderLine."Item No.");
        ProdOrderLine3.SetRange("Unit of Measure Code", ProdOrderLine."Unit of Measure Code");
        ProdOrderLine3.SetRange("Variant Code", ProdOrderLine."Variant Code");
        ProdOrderLine3.SetRange("Location Code", ProdOrderLine."Location Code");
        ProdOrderLine3.SetRange("Planning Level Code", ProdOrderLine."Planning Level Code");
        IsHandled := false;
        OnBeforeInsertProdOrderLine(ProdOrderLine, ProdOrderLine3, InsertNew, IsHandled);
        if not IsHandled then
            if (not InsertNew) and ProdOrderLine3.FindFirst() then begin
                CopyProdOrderCompToTemp(ProdOrderLine3);
                ProdOrderLine3.Validate(Quantity, ProdOrderLine3.Quantity + ProdOrderLine.Quantity);
                AdjustDateAndTime(ProdOrderLine3, ProdOrderLine."Due Date", ProdOrderLine."Ending Date", ProdOrderLine."Ending Time");

                if ProdOrderLine3."Planning Level Code" < ProdOrderLine."Planning Level Code" then begin
                    ProdOrderLine3."Planning Level Code" := ProdOrderLine."Planning Level Code";
                    UpdateCompPlanningLevel(ProdOrderLine3);
                end;
                OnBeforeProdOrderLine3Modify(ProdOrderLine3, ProdOrderLine);
                ProdOrderLine3.Modify();
                ProdOrderLine := ProdOrderLine3;
                exit(false);
            end;
        ProdOrderLine.Insert();
        OnAfterProdOrderLineInsert(ProdOrder, ProdOrderLine, NextProdOrderLineNo);
        exit(true);
    end;

    local procedure ProcessProdOrderLines(Direction: Option Forward,Backward; LetDueDateDecrease: Boolean): Boolean
    var
        ErrorOccured: Boolean;
        IsHandled: Boolean;
    begin
        ProdOrderLine.SetRange(Status, ProdOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrder."No.");
        if ProdOrderLine.FindSet(true) then
            repeat
                IsHandled := false;
                OnBeforeProcessProdOrderLine(ProdOrderLine, ProdOrder, Direction, LetDueDateDecrease, ErrorOccured, IsHandled);
                if not IsHandled then begin
                    CalcProdOrder.SetParameter(true);
                    if not CalcProdOrder.Calculate(ProdOrderLine, Direction, true, true, true, LetDueDateDecrease) then
                        ErrorOccured := true;
                end;
                OnAfterProcessProdOrderLine(ProdOrderLine, Direction, LetDueDateDecrease);
            until ProdOrderLine.Next() = 0;
        OnProcessProdOrderLinesOnBeforeAdjustStartEndingDate(ProdOrder);
        ProdOrder.AdjustStartEndingDate();
        ProdOrder.Modify();

        exit(not ErrorOccured);
    end;

    local procedure CheckMultiLevelStructure(Direction: Option Forward,Backward; MultiLevel: Boolean; LetDueDateDecrease: Boolean)
    var
        MultiLevelStructureCreated: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckMultiLevelStructure(ProdOrder, Direction, IsHandled);
        if IsHandled then
            exit;

        ProdOrderComp.SetCurrentKey(Status, "Prod. Order No.", "Prod. Order Line No.", "Item Low-Level Code");
        ProdOrderComp.SetRange(Status, ProdOrder.Status);
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComp.SetFilter("Item No.", '<>%1', '');
        if ProdOrderComp.FindSet(true) then
            repeat
                if ProdOrderComp."Planning Level Code" = 0 then
                    if ShouldIncreasePlanningLevel(ProdOrderComp) then begin
                        ProdOrderComp."Planning Level Code" := 1;
                        ProdOrderComp.Modify(true);
                    end;
                if ProdOrderComp."Planning Level Code" > 0 then
                    MultiLevelStructureCreated :=
                      MultiLevelStructureCreated or
                      CheckMakeOrderLine(ProdOrderComp, ProdOrderLine, Direction, MultiLevel, LetDueDateDecrease);
            until ProdOrderComp.Next() = 0;
        if MultiLevelStructureCreated then
            ReserveMultiLevelStructure(ProdOrderComp);
    end;

    local procedure ShouldIncreasePlanningLevel(ProdOrderComp: Record "Prod. Order Component") IncreasePlanningLevel: Boolean
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        if StockkeepingUnit.Get(ProdOrderComp."Location Code", ProdOrderComp."Item No.", ProdOrderComp."Variant Code") then
            IncreasePlanningLevel :=
              (StockkeepingUnit."Manufacturing Policy" = StockkeepingUnit."Manufacturing Policy"::"Make-to-Order") and
              (StockkeepingUnit.IsMfgSKU())
        else begin
            Item.Get(ProdOrderComp."Item No.");
            IncreasePlanningLevel :=
              (Item."Manufacturing Policy" = Item."Manufacturing Policy"::"Make-to-Order") and Item.IsMfgItem();
        end;
        OnAfterShouldIncreasePlanningLevel(ProdOrderComp, StockkeepingUnit, IncreasePlanningLevel);
    end;

    procedure CheckMakeOrderLine(var ProdOrderComp: Record "Prod. Order Component"; var ProdOrderLine: Record "Prod. Order Line"; Direction: Option Forward,Backward; MultiLevel: Boolean; LetDueDateDecrease: Boolean): Boolean
    var
        Item: Record Item;
        ParentItem: Record Item;
        ParentSKU: Record "Stockkeeping Unit";
        SKU: Record "Stockkeeping Unit";
        ProdOrderLine2: Record "Prod. Order Line";
        MakeProdOrder: Boolean;
        Inserted: Boolean;
    begin
        ProdOrderLine2.Get(ProdOrderComp.Status, ProdOrderComp."Prod. Order No.", ProdOrderComp."Prod. Order Line No.");
        if ParentSKU.Get(ProdOrderLine2."Location Code", ProdOrderLine2."Item No.", ProdOrderLine2."Variant Code") then
            MakeProdOrder := ParentSKU."Manufacturing Policy" = ParentSKU."Manufacturing Policy"::"Make-to-Order"
        else begin
            ParentItem.Get(ProdOrderLine2."Item No.");
            MakeProdOrder := ParentItem."Manufacturing Policy" = ParentItem."Manufacturing Policy"::"Make-to-Order";
        end;

        OnCheckMakeOrderLineBeforeIf(ProdOrder, ProdOrderLine2, ProdOrderComp, MakeProdOrder);

        if not MakeProdOrder then
            exit(false);

        Item.Get(ProdOrderComp."Item No.");

        if SKU.Get(ProdOrderComp."Location Code", ProdOrderComp."Item No.", ProdOrderComp."Variant Code") then
            MakeProdOrder :=
              SKU.IsMfgSKU() and (SKU."Manufacturing Policy" = SKU."Manufacturing Policy"::"Make-to-Order")
        else
            MakeProdOrder :=
              Item.IsMfgItem() and (Item."Manufacturing Policy" = Item."Manufacturing Policy"::"Make-to-Order");

        OnCheckMakeOrderLineBeforeIf(ProdOrder, ProdOrderLine2, ProdOrderComp, MakeProdOrder);

        if not MakeProdOrder then
            exit(false);

        InitProdOrderLine(ProdOrderComp."Item No.", ProdOrderComp."Variant Code", ProdOrderComp."Location Code");
        ProdOrderLine.Validate("Unit of Measure Code", ProdOrderComp."Unit of Measure Code");
        ProdOrderLine."Qty. per Unit of Measure" := ProdOrderComp."Qty. per Unit of Measure";
        ProdOrderLine."Bin Code" := ProdOrderComp."Bin Code";
        ProdOrderLine.Description := ProdOrderComp.Description;
        ProdOrderLine."Description 2" := Item."Description 2";
        ProdOrderComp.CalcFields("Reserved Quantity");
        ProdOrderLine.Validate(Quantity, ProdOrderComp."Expected Quantity" - ProdOrderComp."Reserved Quantity");
        if ProdOrderLine."Quantity (Base)" = 0 then
            exit(false);
        ProdOrderLine."Planning Level Code" := ProdOrderComp."Planning Level Code";
        ProdOrderLine."Due Date" := ProdOrderComp."Due Date";
        ProdOrderLine."Ending Date" := ProdOrderComp."Due Date";
        ProdOrderLine."Ending Time" := ProdOrderComp."Due Time";
        ProdOrderLine.UpdateDatetime();
        // this InsertNew is responsible for controlling if same POLine is added up or new POLine is created
        InsertNew := InsertNew and (ProdOrderComp."Planning Level Code" > 1);

        OnCheckMakeOrderLineBeforeInsert(ProdOrderLine, ProdOrderComp, InsertNew);
        Inserted := InsertProdOrderLine();
        if MultiLevel then begin
            if Inserted then
                CalcProdOrder.Calculate(ProdOrderLine, Direction::Backward, true, true, true, LetDueDateDecrease)
            else begin
                CalcProdOrder.Recalculate(ProdOrderLine, Direction::Backward, LetDueDateDecrease);
                if ProdOrderLine."Line No." < ProdOrderComp."Prod. Order Line No." then
                    UpdateProdOrderLine(ProdOrderLine, Direction, LetDueDateDecrease);
            end;
            OnCheckMakeOrderLineOnAfterUpdateProdOrderLine(ProdOrderLine);
        end else
            exit(false);
        ProdOrderComp."Supplied-by Line No." := ProdOrderLine."Line No.";
        ProdOrderComp.Modify();
        exit(true);
    end;

    procedure ReserveMultiLevelStructure(var ProdOrderComp2: Record "Prod. Order Component")
    var
        ProdOrderComp3: Record "Prod. Order Component";
        ProdOrderLine3: Record "Prod. Order Line";
        TrackingSpecification: Record "Tracking Specification";
        ProdOrderCompReserve: Codeunit "Prod. Order Comp.-Reserve";
        IsHandled: Boolean;
    begin
        ProdOrderComp3.Copy(ProdOrderComp2);
        ProdOrderComp3.SetCurrentKey(Status, "Prod. Order No.", "Prod. Order Line No.", "Due Date");
        ProdOrderComp3.SetFilter("Supplied-by Line No.", '<>0');
        if ProdOrderComp3.Find('+') then
            repeat
                IsHandled := false;
                OnBeforeReserveMultiLevelStructureComp(ProdOrderComp3, ProdOrderLine3, IsHandled);
                if not IsHandled then
                    if ProdOrderLine3.Get(
                         ProdOrderComp3.Status, ProdOrderComp3."Prod. Order No.", ProdOrderComp3."Supplied-by Line No.")
                    then begin
                        ProdOrderComp3.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
                        TrackingSpecification.InitTrackingSpecification(
                            Database::"Prod. Order Line", ProdOrderLine3.Status.AsInteger(), ProdOrderLine3."Prod. Order No.", '', ProdOrderLine3."Line No.", 0,
                            ProdOrderLine3."Variant Code", ProdOrderLine3."Location Code", ProdOrderLine3."Qty. per Unit of Measure");
                        ProdOrderCompReserve.BindToTracking(
                            ProdOrderComp3, TrackingSpecification, ProdOrderLine3.Description, ProdOrderLine3."Ending Date",
                            ProdOrderComp3."Remaining Quantity" - ProdOrderComp3."Reserved Quantity",
                            ProdOrderComp3."Remaining Qty. (Base)" - ProdOrderComp3."Reserved Qty. (Base)");
                    end;
                OnAfterReserveMultiLevelStructureComp(ProdOrderLine3, ProdOrderComp3);
            until ProdOrderComp3.Next(-1) = 0;
    end;

    procedure CopyDimFromSalesLine(SalesLine: Record "Sales Line"; var ProdOrderLine: Record "Prod. Order Line")
    begin
        ProdOrderLine."Shortcut Dimension 1 Code" := SalesLine."Shortcut Dimension 1 Code";
        ProdOrderLine."Shortcut Dimension 2 Code" := SalesLine."Shortcut Dimension 2 Code";
        ProdOrderLine."Dimension Set ID" := SalesLine."Dimension Set ID";
    end;

    procedure SetSalesLine(SalesLine2: Record "Sales Line")
    begin
        SalesLine := SalesLine2;
        SalesLineIsSet := true;
    end;

    local procedure AdjustDateAndTime(var ProdOrderLine3: Record "Prod. Order Line"; DueDate: Date; EndingDate: Date; EndingTime: Time)
    begin
        if ProdOrderLine3."Due Date" > DueDate then
            ProdOrderLine3."Due Date" := DueDate;

        if ProdOrderLine3."Ending Date" > EndingDate then begin
            ProdOrderLine3."Ending Date" := EndingDate;
            ProdOrderLine3."Ending Time" := EndingTime;
        end else
            if (ProdOrderLine3."Ending Date" = EndingDate) and
               (ProdOrderLine3."Ending Time" > EndingTime)
            then
                ProdOrderLine3."Ending Time" := EndingTime;
        ProdOrderLine3.UpdateDatetime();
    end;

    local procedure UpdateCompPlanningLevel(ProdOrderLine3: Record "Prod. Order Line")
    var
        ProdOrderComp3: Record "Prod. Order Component";
    begin
        // update planning level code of component
        ProdOrderComp3.SetRange(Status, ProdOrderLine3.Status);
        ProdOrderComp3.SetRange("Prod. Order No.", ProdOrderLine3."Prod. Order No.");
        ProdOrderComp3.SetRange("Prod. Order Line No.", ProdOrderLine3."Line No.");
        ProdOrderComp3.SetFilter("Planning Level Code", '>0');
        if ProdOrderComp3.FindSet(true) then
            repeat
                ProdOrderComp3."Planning Level Code" := ProdOrderLine3."Planning Level Code" + 1;
                ProdOrderComp3.Modify();
            until ProdOrderComp3.Next() = 0;
    end;

    local procedure UpdateProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; Direction: Option Forward,Backward; LetDueDateDecrease: Boolean)
    var
        ProdOrderLine3: Record "Prod. Order Line";
        ProdOrderComp3: Record "Prod. Order Component";
    begin
        ProdOrderComp3.SetRange(Status, ProdOrderLine.Status);
        ProdOrderComp3.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderComp3.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        if ProdOrderComp3.FindSet() then
            repeat
                ProdOrderLine3.CopyFilters(ProdOrderLine);
                ProdOrderLine3.SetRange("Item No.", ProdOrderComp3."Item No.");
                ProdOrderLine3.SetRange("Variant Code", ProdOrderComp3."Variant Code");
                if ProdOrderLine3.FindFirst() then begin
                    ProdOrderComp3.CalcFields("Reserved Quantity");
                    TempOldProdOrderComp.Get(ProdOrderComp3.Status, ProdOrderComp3."Prod. Order No.",
                      ProdOrderComp3."Prod. Order Line No.", ProdOrderComp3."Line No.");
                    ProdOrderLine3.Validate(Quantity,
                      ProdOrderLine3.Quantity - TempOldProdOrderComp."Expected Quantity" +
                      ProdOrderComp3."Expected Quantity" - ProdOrderComp3."Reserved Quantity");
                    if ProdOrderLine3."Planning Level Code" < ProdOrderComp3."Planning Level Code" then
                        ProdOrderLine3."Planning Level Code" := ProdOrderComp3."Planning Level Code";
                    AdjustDateAndTime(ProdOrderLine3, ProdOrderComp3."Due Date", ProdOrderComp3."Due Date", ProdOrderComp3."Due Time");
                    UpdateCompPlanningLevel(ProdOrderLine3);
                    CalcProdOrder.Recalculate(ProdOrderLine3, Direction::Backward, LetDueDateDecrease);
                    ProdOrderLine3.Modify();
                end;
            until ProdOrderComp3.Next() = 0;
        TempOldProdOrderComp.DeleteAll();

        OnAfterUpdateProdOrderLine(ProdOrderLine, Direction, LetDueDateDecrease);
    end;

    local procedure CopyProdOrderCompToTemp(ProdOrderLine3: Record "Prod. Order Line")
    var
        ProdOrderComp2: Record "Prod. Order Component";
    begin
        TempOldProdOrderComp.DeleteAll();
        ProdOrderComp2.SetRange(Status, ProdOrderLine3.Status);
        ProdOrderComp2.SetRange("Prod. Order No.", ProdOrderLine3."Prod. Order No.");
        ProdOrderComp2.SetRange("Prod. Order Line No.", ProdOrderLine3."Line No.");
        if ProdOrderComp2.FindSet() then
            repeat
                TempOldProdOrderComp := ProdOrderComp2;
                TempOldProdOrderComp.Insert();
            until ProdOrderComp2.Next() = 0;
    end;

    local procedure IsReplSystemProdOrder(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]): Boolean
    var
        IsHandled: Boolean;
        ReplanSystemProdOrder: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsReplSystemProdOrder(SalesLine, ReplanSystemProdOrder, IsHandled);
        if IsHandled then
            exit(ReplanSystemProdOrder);

        exit(CheckReplenishmentSystemProdOrderAndNotProductionBlocked(ItemNo, VariantCode, LocationCode));
    end;

    internal procedure CheckReplenishmentSystemProdOrderAndNotProductionBlocked(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]) ReplenishmentSystemProdOrderAndNotProductionBlocked: Boolean
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        StockkeepingUnit.SetLoadFields("Replenishment System");
        if StockkeepingUnit.Get(LocationCode, ItemNo, VariantCode) then
            ReplenishmentSystemProdOrderAndNotProductionBlocked := StockkeepingUnit."Replenishment System" = StockkeepingUnit."Replenishment System"::"Prod. Order";

        Item.SetLoadFields("Replenishment System", Blocked, "Production Blocked");
        Item.Get(ItemNo);
        if not ReplenishmentSystemProdOrderAndNotProductionBlocked then
            ReplenishmentSystemProdOrderAndNotProductionBlocked := Item."Replenishment System" = Item."Replenishment System"::"Prod. Order";

        if ReplenishmentSystemProdOrderAndNotProductionBlocked then
            ReplenishmentSystemProdOrderAndNotProductionBlocked := (not Item.Blocked) and (Item."Production Blocked" <> Item."Production Blocked"::Output);

        if ReplenishmentSystemProdOrderAndNotProductionBlocked and (VariantCode <> '') then begin
            ItemVariant.SetLoadFields(Blocked, "Production Blocked");
            ItemVariant.Get(ItemNo, VariantCode);
            ReplenishmentSystemProdOrderAndNotProductionBlocked := (not ItemVariant.Blocked) and (ItemVariant."Production Blocked" <> ItemVariant."Production Blocked"::Output);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopy(var ProdOrder: Record "Production Order"; var ErrorOccured: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCreateProdOrderLine(ProdOrder: Record "Production Order"; VariantCode: Code[10]; var ErrorOccured: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrder: Record "Production Order"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterProdOrderLineInsert(var ProdOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; var NextProdOrderLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProcessProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; Direction: Option Forward,Backward; LetDueDateDecrease: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReserveMultiLevelStructureComp(var ProdOrderLine: Record "Prod. Order Line"; var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShouldIncreasePlanningLevel(ProdOrderComp: Record "Prod. Order Component"; StockkeepingUnit: Record "Stockkeeping Unit"; var IncreasePlanningLevel: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; Direction: Option Forward,Backward; LetDueDateDecrease: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckMultiLevelStructure(ProductionOrder: Record "Production Order"; Direction: Option Forward,Backward; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopy(var ProductionOrder: Record "Production Order"; Direction: Option Forward,Backward; VariantCode: Code[10]; LetDueDateDecrease: Boolean; var ErrorOccured: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyFromSalesOrder(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ProductionOrder: Record "Production Order"; var NextProdOrderLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteLinesForProductionOrder(ProductionOrder: Record "Production Order"; var NextProdOrderLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; var ProdOrderLine3: Record "Prod. Order Line"; var InsertNew: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitProdOrderLine(ProductionOrder: Record "Production Order"; SalesLine: Record "Sales Line"; var ItemNo: Code[20]; var VariantCode: Code[10]; var LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order"; Direction: Option Forward,Backward; LetDueDateDecrease: Boolean; var ErrorOccured: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProdOrderLineInsert(var ProdOrderLine: Record "Prod. Order Line"; var ProductionOrder: Record "Production Order"; SalesLineIsSet: Boolean; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProdOrderLine3Modify(var ProdOrderLine3: Record "Prod. Order Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReserveMultiLevelStructureComp(var ProdOrderComponent: Record "Prod. Order Component"; var ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromFamilyOnAfterInitProdOrderLine(ProductionOrder: Record "Production Order"; FamilyLine: Record "Family Line"; var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromFamilyOnAfterInsertProdOrderLine(var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromFamilyOnAfterFamilyLineSetFilters(var FamilyLine: Record "Family Line"; ProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromFamilyOnBeforeInsertProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; FamilyLine: Record "Family Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromSalesOrderOnBeforeSalesPlanLineInsert(var SalesLine: Record "Sales Line"; var SalesPlanningLine: Record "Sales Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromSalesOrderOnBeforeProdOrderLineModify(var ProdOrderLine: Record "Prod. Order Line"; SalesLine: Record "Sales Line"; SalesPlanningLine: Record "Sales Planning Line"; var NextProdOrderLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromSalesOrderOnAfterCalcQuantityBase(var ProdOrderLine: Record "Prod. Order Line"; SalesLineIsSet: Boolean; var SalesLine: Record "Sales Line"; var QuantityBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromSalesOrderOnAfterCalcShouldCreateTempSalesPlanningLines(var SalesLine: Record "Sales Line"; var ShouldCreateTempSalesPlanningLines: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromSalesOrderOnAfterSalesPlanLinesInsert(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitProdOrderLineAfterVariantCode(var ProdOrderLine: Record "Prod. Order Line"; VariantCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitProdOrderLineAfterScrap(var ProdOrderLine: Record "Prod. Order Line"; var ProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitProdOrderLineBeforeAssignItemNo(var ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckMakeOrderLineBeforeIf(var ProductionOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; var ProdOrderComponent: Record "Prod. Order Component"; var MakeProdOrder: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckMakeOrderLineBeforeInsert(var ProdOrderLine: Record "Prod. Order Line"; var ProdOrderComponent: Record "Prod. Order Component"; var InsertNew: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckMakeOrderLineOnAfterUpdateProdOrderLine(var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsReplSystemProdOrder(SalesLine: Record "Sales Line"; var ReplanSystemProdOrder: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateProdOrderLineOnBeforeInitProdOrderLine(var InsertNew: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProcessProdOrderLinesOnBeforeAdjustStartEndingDate(var ProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyFromSalesOrderOnAfterProdOrderLineModify(var ProdOrderLine: Record "Prod. Order Line"; var SalesLine: Record "Sales Line")
    begin
    end;
}

