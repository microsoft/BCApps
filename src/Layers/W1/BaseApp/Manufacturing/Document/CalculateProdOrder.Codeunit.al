// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;

codeunit 99000773 "Calculate Prod. Order"
{
    Permissions = TableData Item = r,
                  TableData "Prod. Order Line" = rimd,
                  TableData "Prod. Order Component" = rimd,
                  TableData "Manufacturing Setup" = r,
                  TableData "Production BOM Line" = rimd,
                  TableData "Production BOM Comment Line" = rimd,
                  TableData "Production Order" = rimd,
                  TableData "Prod. Order Comp. Cmt Line" = rimd;

    trigger OnRun()
    begin
    end;

    var
        Item: Record Item;
        Location: Record Location;
        SKU: Record "Stockkeeping Unit";
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderRoutingLine2: Record "Prod. Order Routing Line";
        ProdBOMLine: array[99] of Record "Production BOM Line";
        ProdLineItem: Record Item;
        UOMMgt: Codeunit "Unit of Measure Management";
        MfgCostCalcMgt: Codeunit "Mfg. Cost Calculation Mgt.";
        VersionMgt: Codeunit VersionManagement;
        ProdOrderRouteMgt: Codeunit "Prod. Order Route Management";
        GetPlanningParameters: Codeunit "Planning-Get Parameters";
        LeadTimeMgt: Codeunit "Lead-Time Management";
        CalendarMgt: Codeunit "Shop Calendar Management";
        ProdOrderWarehouseMgt: Codeunit "Prod. Order Warehouse Mgt.";
        NextProdOrderCompLineNo: Integer;
        Blocked: Boolean;
        ProdOrderModify: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'BOM phantom structure for %1 is higher than 50 levels.';
        Text001: Label '%1 %2 %3 can not be calculated, if at least one %4 has been posted.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        OperationCannotFollowErr: Label 'Operation No. %1 cannot follow another operation in the routing of this Prod. Order Line.', Comment = '%1 = Operation No.';
        OperationCannotPrecedeErr: Label 'Operation No. %1 cannot precede another operation in the routing of this Prod. Order Line.', Comment = '%1 = Operation No.';

    local procedure TransferRouting()
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferRouting(ProdOrder, ProdOrderLine, IsHandled);
        if IsHandled then
            exit;

        if ProdOrderLine."Routing No." = '' then
            exit;

        RoutingHeader.Get(ProdOrderLine."Routing No.");

        ProdOrderRoutingLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        ProdOrderRoutingLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        if not ProdOrderRoutingLine.IsEmpty() then
            exit;

        RoutingLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        RoutingLine.SetRange("Version Code", ProdOrderLine."Routing Version Code");
        if RoutingLine.Find('-') then
            repeat
                ProcessRoutingLine(RoutingLine, ProdOrderRoutingLine);
            until RoutingLine.Next() = 0;

        OnAfterTransferRouting(ProdOrderLine);
    end;

    local procedure ProcessRoutingLine(var RoutingLine: Record "Routing Line"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeProcessRoutingLine(RoutingLine, ProdOrderRoutingLine, ProdOrderLine, ProdOrder, IsHandled);
        if IsHandled then
            exit;

        RoutingLine.TestField(Recalculate, false);
        InitProdOrderRoutingLine(ProdOrderRoutingLine, RoutingLine);
        TransferTaskInfo(ProdOrderRoutingLine, ProdOrderLine."Routing Version Code");
    end;

    procedure InitProdOrderRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; RoutingLine: Record "Routing Line")
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
    begin
        ProdOrderRoutingLine.Init();
        ProdOrderRoutingLine.Status := ProdOrderLine.Status;
        ProdOrderRoutingLine."Prod. Order No." := ProdOrderLine."Prod. Order No.";
        ProdOrderRoutingLine."Routing Reference No." := ProdOrderLine."Routing Reference No.";
        ProdOrderRoutingLine."Routing No." := ProdOrderLine."Routing No.";
        ProdOrderRoutingLine.CopyFromRoutingLine(RoutingLine);
        case ProdOrderRoutingLine.Type of
            ProdOrderRoutingLine.Type::"Work Center":
                begin
                    WorkCenter.Get(RoutingLine."Work Center No.");
                    ProdOrderRoutingLine."Flushing Method" := WorkCenter."Flushing Method";
                end;
            ProdOrderRoutingLine.Type::"Machine Center":
                begin
                    MachineCenter.Get(ProdOrderRoutingLine."No.");
                    ProdOrderRoutingLine."Flushing Method" := MachineCenter."Flushing Method";
                end;
        end;

        OnTransferRoutingOnBeforeCalcRoutingCostPerUnit(ProdOrderRoutingLine, ProdOrderLine, RoutingLine);
        MfgCostCalcMgt.CalcRoutingCostPerUnit(
            ProdOrderRoutingLine.Type, ProdOrderRoutingLine."No.",
            ProdOrderRoutingLine."Direct Unit Cost", ProdOrderRoutingLine."Indirect Cost %", ProdOrderRoutingLine."Overhead Rate",
            ProdOrderRoutingLine."Unit Cost per", ProdOrderRoutingLine."Unit Cost Calculation");

        OnTransferRoutingOnbeforeValidateDirectUnitCost(ProdOrderRoutingLine, ProdOrderLine, RoutingLine);

        ProdOrderRoutingLine.Validate("Direct Unit Cost");
        ProdOrderRoutingLine."Starting Time" := ProdOrderLine."Starting Time";
        ProdOrderRoutingLine."Starting Date" := ProdOrderLine."Starting Date";
        ProdOrderRoutingLine."Ending Time" := ProdOrderLine."Ending Time";
        ProdOrderRoutingLine."Ending Date" := ProdOrderLine."Ending Date";
        ProdOrderRoutingLine.UpdateDatetime();
        OnAfterTransferRoutingLine(ProdOrderLine, RoutingLine, ProdOrderRoutingLine);
        ProdOrderRoutingLine.Insert();
        OnAfterInsertProdRoutingLine(ProdOrderRoutingLine, ProdOrderLine);
    end;

    procedure TransferTaskInfo(var FromProdOrderRoutingLine: Record "Prod. Order Routing Line"; VersionCode: Code[20])
    begin
        CopyRoutingTools(FromProdOrderRoutingLine, VersionCode);
        CopyRoutingPersonnel(FromProdOrderRoutingLine, VersionCode);
        CopyRoutingQualityMeasures(FromProdOrderRoutingLine, VersionCode);
        CopyRoutingComments(FromProdOrderRoutingLine, VersionCode);

        OnAfterTransferTaskInfo(FromProdOrderRoutingLine, VersionCode);
    end;

    procedure TransferBOM(ProdBOMNo: Code[20]; Level: Integer; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal): Boolean
    var
        BOMHeader: Record "Production BOM Header";
        ProductionBOMVersion: Record "Production BOM Version";
        ReqQty: Decimal;
        ErrorOccured: Boolean;
        VersionCode: Code[20];
        IsHandled: Boolean;
        SkipTransfer: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferBOM(ProdOrder, ProdOrderLine, ProdBOMNo, Level, LineQtyPerUOM, ItemQtyPerUOM, Blocked, ErrorOccured, IsHandled);
        if IsHandled then
            exit(not ErrorOccured);

        if ProdBOMNo = '' then
            exit;

        ProdOrderComp.LockTable();

        if Level > 50 then
            Error(
              Text000,
              ProdBOMNo);

        BOMHeader.Get(ProdBOMNo);

        if Level > 1 then
            VersionCode := VersionMgt.GetBOMVersion(ProdBOMNo, ProdOrderLine."Starting Date", true)
        else
            VersionCode := ProdOrderLine."Production BOM Version Code";

        if VersionCode <> '' then begin
            ProductionBOMVersion.Get(ProdBOMNo, VersionCode);
            ProductionBOMVersion.TestField(Status, ProductionBOMVersion.Status::Certified);
        end else
            BOMHeader.TestField(Status, BOMHeader.Status::Certified);

        ProdBOMLine[Level].SetRange("Production BOM No.", ProdBOMNo);
        ProdBOMLine[Level].SetRange("Version Code", VersionCode);
        ProdBOMLine[Level].SetFilter("Starting Date", '%1|..%2', 0D, ProdOrderLine."Starting Date");
        ProdBOMLine[Level].SetFilter("Ending Date", '%1|%2..', 0D, ProdOrderLine."Starting Date");
        OnTransferBOMOnAfterSetFiltersProdBOMLine(ProdBOMLine[Level], ProdOrderLine);
        if ProdBOMLine[Level].Find('-') then
            repeat
                IsHandled := false;
                OnBeforeTransferBOMComponent(ProdOrder, ProdOrderLine, ProdBOMLine[Level], ErrorOccured, IsHandled, Level);
                if not IsHandled then begin
                    if ProdBOMLine[Level]."Routing Link Code" <> '' then begin
                        IsHandled := false;
                        OnBeforeFindProdOrderRoutingLine(ProdOrderLine, ProdBOMLine[Level], IsHandled, ReqQty);
                        if not IsHandled then begin
                            ProdOrderRoutingLine2.SetRange(Status, ProdOrderLine.Status);
                            ProdOrderRoutingLine2.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
                            ProdOrderRoutingLine2.SetRange("Routing Link Code", ProdBOMLine[Level]."Routing Link Code");
                            ProdOrderRoutingLine2.FindFirst();
                            ReqQty :=
                              ProdBOMLine[Level].Quantity * (1 + ProdBOMLine[Level]."Scrap %" / 100) *
                              (1 + ProdOrderRoutingLine2."Scrap Factor % (Accumulated)") * LineQtyPerUOM / ItemQtyPerUOM +
                              ProdOrderRoutingLine2."Fixed Scrap Qty. (Accum.)";
                        end;
                    end else
                        ReqQty :=
                          ProdBOMLine[Level].Quantity * (1 + ProdBOMLine[Level]."Scrap %" / 100) * LineQtyPerUOM / ItemQtyPerUOM;

                    OnTransferBOMOnAfterCalcReqQty(
                      ProdBOMLine[Level], ProdOrderRoutingLine2, ProdOrderLine, ReqQty, LineQtyPerUOM, ItemQtyPerUOM);

                    case ProdBOMLine[Level].Type of
                        ProdBOMLine[Level].Type::Item:
                            begin
                                SkipTransfer := false;
                                OnTransferBOMOnBeforeProcessItem(ProdBOMLine[Level], ReqQty, SkipTransfer);
                                if not SkipTransfer then
                                    TransferBOMProcessItem(Level, LineQtyPerUOM, ItemQtyPerUOM, ErrorOccured);
                            end;
                        ProdBOMLine[Level].Type::"Production BOM":
                            begin
                                OnTransferBOMOnBeforeProcessProdBOM(ProdBOMLine[Level], LineQtyPerUOM, ItemQtyPerUOM, ReqQty, ProdOrderLine);
                                TransferBOM(ProdBOMLine[Level]."No.", Level + 1, ReqQty, 1);
                                ProdBOMLine[Level].SetRange("Production BOM No.", ProdBOMNo);
                                if Level > 1 then
                                    ProdBOMLine[Level].SetRange("Version Code", VersionMgt.GetBOMVersion(ProdBOMNo, ProdOrderLine."Starting Date", true))
                                else
                                    ProdBOMLine[Level].SetRange("Version Code", ProdOrderLine."Production BOM Version Code");
                                ProdBOMLine[Level].SetFilter("Starting Date", '%1|..%2', 0D, ProdOrderLine."Starting Date");
                                ProdBOMLine[Level].SetFilter("Ending Date", '%1|%2..', 0D, ProdOrderLine."Starting Date");
                            end;
                    end;
                end;
            until ProdBOMLine[Level].Next() = 0;

        OnAfterTransferBOM(ProdOrder, ProdOrderLine, ProdBOMNo, Level, LineQtyPerUOM, ItemQtyPerUOM, Blocked, ErrorOccured);

        exit(not ErrorOccured);
    end;

    local procedure TransferBOMProcessItem(Level: Integer; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal; var ErrorOccured: Boolean)
    var
        Item2: Record Item;
        ComponentSKU: Record "Stockkeeping Unit";
        IsHandled: Boolean;
        QtyRoundPrecision: Decimal;
    begin
        ProdOrderComp.Reset();
        ProdOrderComp.SetCurrentKey(Status, "Prod. Order No.", "Prod. Order Line No.", "Item No.");
        ProdOrderComp.SetRange(Status, ProdOrderLine.Status);
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        ProdOrderComp.SetFilterFromProdBOMLine(ProdBOMLine[Level]);
        OnAfterProdOrderCompFilter(ProdOrderComp, ProdBOMLine[Level]);
        if not ProdOrderComp.FindFirst() then begin
            ProdOrderComp.Reset();
            ProdOrderComp.SetRange(Status, ProdOrderLine.Status);
            ProdOrderComp.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
            ProdOrderComp.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
            if ProdOrderComp.FindLast() then
                NextProdOrderCompLineNo := ProdOrderComp."Line No." + 10000
            else
                NextProdOrderCompLineNo := 10000;

            ProdOrderComp.Init();
            ProdOrderComp.SetIgnoreErrors();
            ProdOrderComp.BlockDynamicTracking(Blocked);
            ProdOrderComp.Status := ProdOrderLine.Status;
            ProdOrderComp."Prod. Order No." := ProdOrderLine."Prod. Order No.";
            ProdOrderComp."Prod. Order Line No." := ProdOrderLine."Line No.";
            ProdOrderComp."Line No." := NextProdOrderCompLineNo;
            ProdOrderComp.Validate("Item No.", ProdBOMLine[Level]."No.");
            ProdOrderComp."Variant Code" := ProdBOMLine[Level]."Variant Code";
            ProdOrderComp."Location Code" := SKU."Components at Location";
            ProdOrderComp."Bin Code" := GetDefaultBin();
            ProdOrderComp.Description := ProdBOMLine[Level].Description;
            ProdOrderComp.Validate("Unit of Measure Code", ProdBOMLine[Level]."Unit of Measure Code");
            if (ProdOrderComp."Item No." <> '') and Item2.Get(ProdOrderComp."Item No.") then
                QtyRoundPrecision := UOMMgt.GetQtyRoundingPrecision(Item2, ProdBOMLine[Level]."Unit of Measure Code");
            CheckingRoundingPrecision(Item2, ProdLineItem, QtyRoundPrecision, Level);
            if (QtyRoundPrecision <> 0) and (QtyRoundPrecision < 1) then
                ProdOrderComp."Quantity per" := Round(ProdBOMLine[Level]."Quantity per" * LineQtyPerUOM / ItemQtyPerUOM, QtyRoundPrecision)
            else
                ProdOrderComp."Quantity per" := ProdBOMLine[Level]."Quantity per" * LineQtyPerUOM / ItemQtyPerUOM;
            ProdOrderComp.Length := ProdBOMLine[Level].Length;
            ProdOrderComp.Width := ProdBOMLine[Level].Width;
            ProdOrderComp.Weight := ProdBOMLine[Level].Weight;
            ProdOrderComp.Depth := ProdBOMLine[Level].Depth;
            ProdOrderComp.Position := ProdBOMLine[Level].Position;
            ProdOrderComp."Position 2" := ProdBOMLine[Level]."Position 2";
            ProdOrderComp."Position 3" := ProdBOMLine[Level]."Position 3";
            ProdOrderComp."Lead-Time Offset" := ProdBOMLine[Level]."Lead-Time Offset";
            ProdOrderComp.Validate("Routing Link Code", ProdBOMLine[Level]."Routing Link Code");
            ProdOrderComp.Validate("Scrap %", ProdBOMLine[Level]."Scrap %");
            ProdOrderComp.Validate("Calculation Formula", ProdBOMLine[Level]."Calculation Formula");

            OnTransferBOMProcessItemOnBeforeGetPlanningParameters(ProdOrderComp, ProdBOMLine[Level], SKU);
            GetPlanningParameters.AtSKU(
              ComponentSKU, ProdOrderComp."Item No.", ProdOrderComp."Variant Code", ProdOrderComp."Location Code");
            OnTransferBOMProcessItemOnAfterGetPlanningParameters(ProdOrderLine, ComponentSKU);

            IsHandled := false;
            OnTransferBOMProcessItemOnBeforeSetFlushingMethod(ProdOrderLine, ComponentSKU, ProdOrderComp, ProdBOMLine[Level], IsHandled);
            if not IsHandled then
                ProdOrderComp."Flushing Method" := ComponentSKU."Flushing Method";

            if SetPlanningLevelCode(ProdOrderComp, ProdBOMLine[Level], SKU, ComponentSKU) then begin
                if ProdOrderComp."Quantity per" = 0 then
                    exit;
                ProdOrderComp."Planning Level Code" := ProdOrderLine."Planning Level Code" + 1;
                Item2.Get(ProdOrderComp."Item No.");
                ProdOrderComp."Item Low-Level Code" := Item2."Low-Level Code";
            end;
            ProdOrderComp.GetDefaultBin();
            OnAfterTransferBOMComponent(ProdOrderLine, ProdBOMLine[Level], ProdOrderComp, LineQtyPerUOM, ItemQtyPerUOM);
            ProdOrderComp.Insert(true);
            OnAfterProdOrderCompInsert(ProdOrderComp, ProdBOMLine[Level]);
        end else begin
            ProdOrderComp.SetIgnoreErrors();
            ProdOrderComp.SetCurrentKey(Status, "Prod. Order No."); // Reset key
            ProdOrderComp.BlockDynamicTracking(Blocked);
            ProdOrderComp.Validate(
              "Quantity per",
              ProdOrderComp."Quantity per" + ProdBOMLine[Level]."Quantity per" * LineQtyPerUOM / ItemQtyPerUOM);
            ProdOrderComp.Validate("Routing Link Code", ProdBOMLine[Level]."Routing Link Code");
            OnBeforeProdOrderCompModify(ProdOrderComp, ProdBOMLine[Level], LineQtyPerUOM, ItemQtyPerUOM);
            ProdOrderComp.Modify();
        end;
        if ProdOrderComp.HasErrorOccured() then
            ErrorOccured := true;
        ProdOrderComp.AutoReserve();
        CopyProdBOMComments(ProdBOMLine[Level]);
    end;

    local procedure SetPlanningLevelCode(var ProdOrderComponent: Record "Prod. Order Component"; var ProductionBOMLine: Record "Production BOM Line"; var SKU: Record "Stockkeeping Unit"; var ComponentSKU: Record "Stockkeeping Unit") Result: Boolean
    begin
        Result :=
            (SKU."Manufacturing Policy" = SKU."Manufacturing Policy"::"Make-to-Order") and
            (ComponentSKU."Manufacturing Policy" = ComponentSKU."Manufacturing Policy"::"Make-to-Order") and
            (ComponentSKU."Replenishment System" = ComponentSKU."Replenishment System"::"Prod. Order");

        OnAfterSetPlanningLevelCode(ProdOrderComponent, ProductionBOMLine, SKU, ComponentSKU, Result);
    end;

    procedure CalculateComponents()
    var
        ProdOrderComp: Record "Prod. Order Component";
        IsHandled: Boolean;
    begin
        ProdOrderComp.SetRange(Status, ProdOrderLine.Status);
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");
        if ProdOrderComp.Find('-') then begin
            repeat
                ProdOrderComp.BlockDynamicTracking(Blocked);
                IsHandled := false;
                OnCalculateComponentsOnBeforeUpdateRoutingLinkCode(ProdOrderComp, ProdOrderLine, IsHandled);
                if not IsHandled then begin
                    ProdOrderComp.Validate("Routing Link Code");
                    ProdOrderComp.Modify();
                    ProdOrderComp.AutoReserve();
                end;
            until ProdOrderComp.Next() = 0;
            OnAfterCalculateComponents(ProdOrderLine);
        end;
    end;

    procedure CalculateRoutingFromActual(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; Direction: Option Forward,Backward; CalcStartEndDate: Boolean)
    var
        CalculateRoutingLine: Codeunit "Calculate Routing Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculateRoutingFromActual(ProdOrderRoutingLine, Direction, CalcStartEndDate, IsHandled);
        if IsHandled then
            exit;

        if ProdOrderRouteMgt.NeedsCalculation(
             ProdOrderRoutingLine.Status,
             ProdOrderRoutingLine."Prod. Order No.",
             ProdOrderRoutingLine."Routing Reference No.",
             ProdOrderRoutingLine."Routing No.")
        then begin
            ProdOrderLine.SetRange(Status, ProdOrderRoutingLine.Status);
            ProdOrderLine.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
            ProdOrderLine.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
            ProdOrderLine.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
            ProdOrderLine.FindFirst();
            ProdOrderRouteMgt.Calculate(ProdOrderLine);
            ProdOrderRoutingLine.Get(
              ProdOrderRoutingLine.Status,
              ProdOrderRoutingLine."Prod. Order No.",
              ProdOrderRoutingLine."Routing Reference No.",
              ProdOrderRoutingLine."Routing No.",
              ProdOrderRoutingLine."Operation No.");
        end;
        if Direction = Direction::Forward then
            ProdOrderRoutingLine.SetCurrentKey(Status, "Prod. Order No.", "Routing Reference No.",
              "Routing No.", "Sequence No. (Forward)")
        else
            ProdOrderRoutingLine.SetCurrentKey(Status, "Prod. Order No.", "Routing Reference No.",
              "Routing No.", "Sequence No. (Backward)");

        ProdOrderRoutingLine.SetRange(Status, ProdOrderRoutingLine.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        ProdOrderRoutingLine.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        ProdOrderRoutingLine.SetFilter("Routing Status", '<>%1', ProdOrderRoutingLine."Routing Status"::Finished);
        OnCalculateRoutingFromActualOnAfterSetProdOrderRoutingLineFilters(ProdOrderRoutingLine);
        repeat
            OnCalculateRoutingFromActualOnBeforeCalcStartEndDate(ProdOrderRoutingLine, CalcStartEndDate);
            if CalcStartEndDate and not ProdOrderRoutingLine."Schedule Manually" then
                if ((Direction = Direction::Forward) and (ProdOrderRoutingLine."Previous Operation No." <> '')) or
                   ((Direction = Direction::Backward) and (ProdOrderRoutingLine."Next Operation No." <> ''))
                then begin
                    ProdOrderRoutingLine."Starting Time" := 0T;
                    ProdOrderRoutingLine."Starting Date" := 0D;
                    ProdOrderRoutingLine."Ending Time" := 235959T;
                    ProdOrderRoutingLine."Ending Date" := CalendarMgt.GetMaxDate();
                end;
            Clear(CalculateRoutingLine);
            CalculateRoutingLine.CalculateRoutingLine(ProdOrderRoutingLine, Direction, CalcStartEndDate);
            OnCalculateRoutingFromActualOnAfterCalculateRoutingLine(ProdOrderRoutingLine);
            CalcStartEndDate := true;
        until ProdOrderRoutingLine.Next() = 0;
    end;

    local procedure CalculateRouting(Direction: Option Forward,Backward; LetDueDateDecrease: Boolean)
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        IsHandled: Boolean;
    begin
        if ProdOrderRouteMgt.NeedsCalculation(
             ProdOrderLine.Status,
             ProdOrderLine."Prod. Order No.",
             ProdOrderLine."Routing Reference No.",
             ProdOrderLine."Routing No.")
        then
            ProdOrderRouteMgt.Calculate(ProdOrderLine);

        if Direction = Direction::Forward then
            ProdOrderRoutingLine.SetCurrentKey(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.",
              "Sequence No. (Forward)")
        else
            ProdOrderRoutingLine.SetCurrentKey(Status, "Prod. Order No.", "Routing Reference No.", "Routing No.",
              "Sequence No. (Backward)");

        ProdOrderRoutingLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        ProdOrderRoutingLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        ProdOrderRoutingLine.SetFilter("Routing Status", '<>%1', ProdOrderRoutingLine."Routing Status"::Finished);
        if not ProdOrderRoutingLine.FindFirst() then begin
            OnCalculateRoutingOnBeforeSetLeadTime(ProdOrderLine);
            CalculateLeadTime(ProdOrderLine, Direction, LetDueDateDecrease);
            exit;
        end;

        IsHandled := false;
        OnCalculateRoutingOnBeforeUpdateProdOrderRoutingLineDates(ProdOrderRoutingLine, ProdOrderLine, IsHandled);
        if IsHandled then
            exit;

        if Direction = Direction::Forward then begin
            ProdOrderRoutingLine."Starting Date" := ProdOrderLine."Starting Date";
            ProdOrderRoutingLine."Starting Time" := ProdOrderLine."Starting Time";
        end else begin
            ProdOrderRoutingLine."Ending Date" := ProdOrderLine."Ending Date";
            ProdOrderRoutingLine."Ending Time" := ProdOrderLine."Ending Time";
        end;
        ProdOrderRoutingLine.UpdateDatetime();
        CalculateRoutingFromActual(ProdOrderRoutingLine, Direction, false);

        CalculateProdOrderDates(ProdOrderLine, LetDueDateDecrease);
    end;

    procedure CalculateProdOrderDates(var ProdOrderLine: Record "Prod. Order Line"; LetDueDateDecrease: Boolean)
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        NewDueDate: Date;
        IsHandled: Boolean;
    begin
        OnBeforeCalculateProdOrderDates(ProdOrderLine);

        ProdOrder.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.");

        ProdOrderRoutingLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRoutingLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        if ProdOrder."Source Type" <> ProdOrder."Source Type"::Family then
            ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLine."Line No.")
        else
            ProdOrderRoutingLine.SetRange("Routing Reference No.", 0);
        ProdOrderRoutingLine.SetFilter("Routing Status", '<>%1', ProdOrderRoutingLine."Routing Status"::Finished);
        ProdOrderRoutingLine.SetFilter("Next Operation No.", '%1', '');
        OnCalculateProdOrderDatesOnAfterSetFilters(ProdOrderRoutingLine, ProdOrder, ProdOrderLine);

        if ProdOrderRoutingLine.FindFirst() then begin
            ProdOrderLine."Ending Date" := ProdOrderRoutingLine."Ending Date";
            ProdOrderLine."Ending Time" := ProdOrderRoutingLine."Ending Time";
        end;

        ProdOrderRoutingLine.SetRange("Next Operation No.");
        ProdOrderRoutingLine.SetFilter("Previous Operation No.", '%1', '');

        if ProdOrderRoutingLine.FindFirst() then begin
            ProdOrderLine."Starting Date" := ProdOrderRoutingLine."Starting Date";
            ProdOrderLine."Starting Time" := ProdOrderRoutingLine."Starting Time";
        end;

        LeadTimeMgt.SetManualScheduling(ProdOrderLine."Manual Scheduling");
        IsHandled := false;
        OnCalculateProdOrderDatesOnSetBeforeDueDate(ProdOrderLine, IsHandled);
        if not IsHandled then begin
            if ProdOrderLine."Planning Level Code" = 0 then
                NewDueDate :=
                  LeadTimeMgt.GetPlannedDueDate(
                    ProdOrderLine."Item No.", ProdOrderLine."Location Code", ProdOrderLine."Variant Code",
                    ProdOrderLine."Ending Date", '', "Requisition Ref. Order Type"::"Prod. Order")
            else
                NewDueDate := ProdOrderLine."Ending Date";

            if LetDueDateDecrease or (NewDueDate > ProdOrderLine."Due Date") then
                if ProdOrderLine.ConfirmUpdateDueDateAndEndingDate(ProdOrderLine.FieldCaption("Due Date"), NewDueDate) then
                    ProdOrderLine."Due Date" := NewDueDate;
        end;

        OnCalculateProdOrderDatesOnBeforeUpdateDatetime(ProdOrderLine, NewDueDate, LetDueDateDecrease);
        ProdOrderLine.UpdateDatetime();
        ProdOrderLine.Modify();

        OnBeforeUpdateProdOrderDates(ProdOrder, ProdOrderLine, ProdOrderModify);

        if not ProdOrderModify then begin
            ProdOrder.Validate("Manual Scheduling", ProdOrderLine."Manual Scheduling");
            ProdOrder.AdjustStartEndingDate();
            ProdOrder.Modify();
        end;
    end;

    procedure Calculate(ProdOrderLine2: Record "Prod. Order Line"; Direction: Option Forward,Backward; CalcRouting: Boolean; CalcComponents: Boolean; DeleteRelations: Boolean; LetDueDateDecrease: Boolean): Boolean
    var
        CapLedgEntry: Record "Capacity Ledger Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        ProdOrderRoutingLine3: Record "Prod. Order Routing Line";
        ProdOrderRoutingLine4: Record "Prod. Order Routing Line";
        RoutingHeader: Record "Routing Header";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ErrorOccured: Boolean;
        IsHandled: Boolean;
        ShouldCheckIfEntriesExist: Boolean;
        SkipCalcComponents: Boolean;
    begin
        ProdOrderLine := ProdOrderLine2;

        IsHandled := false;
        OnBeforeCalculate(ItemLedgEntry, CapLedgEntry, Direction, CalcRouting, CalcComponents, DeleteRelations, LetDueDateDecrease, IsHandled, ProdOrderLine, ErrorOccured);
        if IsHandled then
            exit(not ErrorOccured);

        ShouldCheckIfEntriesExist := ProdOrderLine.Status = ProdOrderLine.Status::Released;
        OnCalculateOnAfterCalcShouldCheckIfEntriesExist(ProdOrderLine, CalcRouting, ShouldCheckIfEntriesExist);
        if ShouldCheckIfEntriesExist then begin
            ItemLedgEntry.SetCurrentKey("Order Type", "Order No.");
            ItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type"::Production);
            ItemLedgEntry.SetRange("Order No.", ProdOrderLine."Prod. Order No.");
            OnCalculateOnAfterItemLedgEntrySetFilters(ProdOrderLine, ItemLedgEntry);
            if not ItemLedgEntry.IsEmpty() then
                Error(
                  Text001,
                  ProdOrderLine.Status, ProdOrderLine.TableCaption(), ProdOrderLine."Prod. Order No.",
                  ItemLedgEntry.TableCaption());

            CapLedgEntry.SetCurrentKey("Order Type", "Order No.");
            CapLedgEntry.SetRange("Order Type", CapLedgEntry."Order Type"::Production);
            CapLedgEntry.SetRange("Order No.", ProdOrderLine."Prod. Order No.");
            if not CapLedgEntry.IsEmpty() then
                Error(
                  Text001,
                  ProdOrderLine.Status, ProdOrderLine.TableCaption(), ProdOrderLine."Prod. Order No.",
                  CapLedgEntry.TableCaption());
        end;

        CheckProdOrderLineQuantity(ProdOrderLine);
        if Direction = Direction::Backward then
            ProdOrderLine.TestField("Ending Date")
        else
            ProdOrderLine.TestField("Starting Date");

        if DeleteRelations then
            ProdOrderLine.DeleteRelations();

        if CalcRouting then begin
            TransferRouting();
            if not CalcComponents then begin // components will not be calculated later- update bin code
                ProdOrderRoutingLine.SetRange(Status, ProdOrderLine.Status);
                ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
                ProdOrderRoutingLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
                ProdOrderRoutingLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
                if not ProdOrderRouteMgt.UpdateComponentsBin(ProdOrderRoutingLine, true) then
                    ErrorOccured := true;
            end;
        end else
            if RoutingHeader.Get(ProdOrderLine2."Routing No.") or (ProdOrderLine2."Routing No." = '') then
                if RoutingHeader.Type <> RoutingHeader.Type::Parallel then begin
                    ProdOrderRoutingLine3.SetRange(Status, ProdOrderLine2.Status);
                    ProdOrderRoutingLine3.SetRange("Prod. Order No.", ProdOrderLine2."Prod. Order No.");
                    ProdOrderRoutingLine3.SetRange("Routing Reference No.", ProdOrderLine2."Routing Reference No.");
                    ProdOrderRoutingLine3.SetRange("Routing No.", ProdOrderLine2."Routing No.");
                    ProdOrderRoutingLine3.SetFilter("Routing Status", '<>%1', ProdOrderRoutingLine3."Routing Status"::Finished);
                    ProdOrderRoutingLine4.CopyFilters(ProdOrderRoutingLine3);
                    if ProdOrderRoutingLine3.Find('-') then
                        repeat
                            if ProdOrderRoutingLine3."Next Operation No." <> '' then begin
                                ProdOrderRoutingLine4.SetRange("Operation No.", ProdOrderRoutingLine3."Next Operation No.");
                                if ProdOrderRoutingLine4.IsEmpty() then begin
                                    IsHandled := false;
                                    OnCalculateOnBeforeCheckNextOperation(ProdOrder, ProdOrderLine2, ProdOrderRoutingLine3, IsHandled);
                                    if not IsHandled then
                                        Error(OperationCannotFollowErr, ProdOrderRoutingLine3."Next Operation No.");
                                end;
                            end;
                            if ProdOrderRoutingLine3."Previous Operation No." <> '' then begin
                                ProdOrderRoutingLine4.SetRange("Operation No.", ProdOrderRoutingLine3."Previous Operation No.");
                                if ProdOrderRoutingLine4.IsEmpty() then begin
                                    IsHandled := false;
                                    OnCalculateOnBeforeCheckPrevOperation(ProdOrder, ProdOrderLine2, ProdOrderRoutingLine3, IsHandled);
                                    if not IsHandled then
                                        Error(OperationCannotPrecedeErr, ProdOrderRoutingLine3."Previous Operation No.");
                                end;
                            end;
                        until ProdOrderRoutingLine3.Next() = 0;
                end;

        SkipCalcComponents := false;
        OnCalculateOnBeforeCalcComponents(ProdOrderLine, CalcComponents, SkipCalcComponents);
        if CalcComponents and not SkipCalcComponents then
            if ProdOrderLine."Production BOM No." <> '' then begin
                Item.Get(ProdOrderLine."Item No.");
                GetPlanningParameters.AtSKU(
                  SKU,
                  ProdOrderLine."Item No.",
                  ProdOrderLine."Variant Code",
                  ProdOrderLine."Location Code");
                OnCalculateOnAfterGetpLanningParameterAtSKUCalcComponents(ProdOrderLine, SKU);

                CalculateLeadTime(ProdOrderLine, Direction, LetDueDateDecrease);
                CalculateRouting(Direction, LetDueDateDecrease);
                if not TransferBOM(
                     ProdOrderLine."Production BOM No.",
                     1,
                     ProdOrderLine."Qty. per Unit of Measure",
                     UOMMgt.GetQtyPerUnitOfMeasure(
                       Item,
                       VersionMgt.GetBOMUnitOfMeasure(
                         ProdOrderLine."Production BOM No.",
                         ProdOrderLine."Production BOM Version Code")))
                then
                    ErrorOccured := true;
            end;
        Recalculate(ProdOrderLine, Direction, LetDueDateDecrease, CalcRouting, CalcComponents);

        OnAfterCalculate(ProdOrderLine, ErrorOccured);

        exit(not ErrorOccured);
    end;

    local procedure CopyProdBOMComments(ProdBOMLine: Record "Production BOM Line")
    var
        ProdBOMCommentLine: Record "Production BOM Comment Line";
        ProdOrderCompCmtLine: Record "Prod. Order Comp. Cmt Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyProdBOMComments(ProdBOMCommentLine, ProdBOMLine, IsHandled);
        if IsHandled then
            exit;

        ProdBOMCommentLine.SetRange("Production BOM No.", ProdBOMLine."Production BOM No.");
        ProdBOMCommentLine.SetRange("BOM Line No.", ProdBOMLine."Line No.");
        ProdBOMCommentLine.SetRange("Version Code", ProdBOMLine."Version Code");
        if ProdBOMCommentLine.FindSet() then
            repeat
                ProdOrderCompCmtLine.CopyFromProdBOMComponent(ProdBOMCommentLine, ProdOrderComp);
                if not ProdOrderCompCmtLine.Insert() then
                    ProdOrderCompCmtLine.Modify();
            until ProdBOMCommentLine.Next() = 0;
    end;

    local procedure CopyRoutingComments(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; VersionCode: Code[20])
    var
        RoutingCommentLine: Record "Routing Comment Line";
        ProdOrderRtngCommentLine: Record "Prod. Order Rtng Comment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyRoutingComments(RoutingCommentLine, ProdOrderRoutingLine, VersionCode, IsHandled);
        if IsHandled then
            exit;

        RoutingCommentLine.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        RoutingCommentLine.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        RoutingCommentLine.SetRange("Version Code", VersionCode);
        if RoutingCommentLine.Find('-') then
            repeat
                ProdOrderRtngCommentLine.TransferFields(RoutingCommentLine);
                ProdOrderRtngCommentLine.Status := ProdOrderRoutingLine.Status;
                ProdOrderRtngCommentLine."Prod. Order No." := ProdOrderRoutingLine."Prod. Order No.";
                ProdOrderRtngCommentLine."Routing Reference No." := ProdOrderRoutingLine."Routing Reference No.";
                ProdOrderRtngCommentLine.Insert();
            until RoutingCommentLine.Next() = 0;
    end;

    local procedure CopyRoutingPersonnel(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; VersionCode: Code[20])
    var
        RoutingPersonnel: Record "Routing Personnel";
        ProdOrderRoutingPersonnel: Record "Prod. Order Routing Personnel";
    begin
        RoutingPersonnel.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        RoutingPersonnel.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        RoutingPersonnel.SetRange("Version Code", VersionCode);
        if RoutingPersonnel.Find('-') then
            repeat
                ProdOrderRoutingPersonnel.TransferFields(RoutingPersonnel);
                ProdOrderRoutingPersonnel.Status := ProdOrderRoutingLine.Status;
                ProdOrderRoutingPersonnel."Prod. Order No." := ProdOrderRoutingLine."Prod. Order No.";
                ProdOrderRoutingPersonnel."Routing Reference No." := ProdOrderRoutingLine."Routing Reference No.";
                ProdOrderRoutingPersonnel.Insert();
            until RoutingPersonnel.Next() = 0;
    end;

    local procedure CopyRoutingQualityMeasures(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; VersionCode: Code[20])
    var
        RoutingQualityMeasure: Record "Routing Quality Measure";
        ProdOrderRtngQltyMeas: Record "Prod. Order Rtng Qlty Meas.";
    begin
        RoutingQualityMeasure.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        RoutingQualityMeasure.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        RoutingQualityMeasure.SetRange("Version Code", VersionCode);
        if RoutingQualityMeasure.Find('-') then
            repeat
                ProdOrderRtngQltyMeas.TransferFields(RoutingQualityMeasure);
                ProdOrderRtngQltyMeas.Status := ProdOrderRoutingLine.Status;
                ProdOrderRtngQltyMeas."Prod. Order No." := ProdOrderRoutingLine."Prod. Order No.";
                ProdOrderRtngQltyMeas."Routing Reference No." := ProdOrderRoutingLine."Routing Reference No.";
                ProdOrderRtngQltyMeas.Insert();
            until RoutingQualityMeasure.Next() = 0;
    end;

    local procedure CopyRoutingTools(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; VersionCode: Code[20])
    var
        RoutingTool: Record "Routing Tool";
        ProdOrderRoutingTool: Record "Prod. Order Routing Tool";
    begin
        RoutingTool.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        RoutingTool.SetRange("Operation No.", ProdOrderRoutingLine."Operation No.");
        RoutingTool.SetRange("Version Code", VersionCode);
        OnCopyRoutingToolsOnAfterRoutingToolSetFilters(RoutingTool, ProdOrderRoutingLine, VersionCode);
        if RoutingTool.Find('-') then
            repeat
                ProdOrderRoutingTool.TransferFields(RoutingTool);
                ProdOrderRoutingTool.Status := ProdOrderRoutingLine.Status;
                ProdOrderRoutingTool."Prod. Order No." := ProdOrderRoutingLine."Prod. Order No.";
                ProdOrderRoutingTool."Routing Reference No." := ProdOrderRoutingLine."Routing Reference No.";
                ProdOrderRoutingTool.Insert();
            until RoutingTool.Next() = 0;
    end;

    local procedure Recalculate(var ProdOrderLine: Record "Prod. Order Line"; Direction: Option; LetDueDateDecrease: Boolean; CalcRouting: Boolean; CalcComponents: Boolean)
    begin
        OnBeforeRecalculate(ProdOrderLine, CalcRouting, CalcComponents);
        Recalculate(ProdOrderLine, Direction, LetDueDateDecrease);
        OnAfterRecalculate(ProdOrderLine, CalcRouting, CalcComponents);
    end;

    procedure Recalculate(var ProdOrderLine2: Record "Prod. Order Line"; Direction: Option Forward,Backward; LetDueDateDecrease: Boolean)
    var
        IsHandled: Boolean;
    begin
        ProdOrderLine := ProdOrderLine2;
        ProdOrderLine.BlockDynamicTracking(Blocked);

        IsHandled := false;
        OnRecalculateOnBeforeCalculateRouting(ProdOrderLine, IsHandled);
        if not IsHandled then
            CalculateRouting(Direction, LetDueDateDecrease);
        CalculateComponents();
        ProdOrderLine2 := ProdOrderLine;

        OnAfterRecalculateProcedure(ProdOrderLine2);
    end;

    procedure BlockDynamicTracking(SetBlock: Boolean)
    begin
        Blocked := SetBlock;
    end;

    procedure SetParameter(NewProdOrderModify: Boolean)
    begin
        ProdOrderModify := NewProdOrderModify;
    end;

    local procedure GetDefaultBin() BinCode: Code[20]
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetDefaultBin(ProdOrderComp, Location, Item, ProdOrderWarehouseMgt, BinCode, IsHandled);
        if IsHandled then
            exit;

        if ProdOrderComp."Location Code" <> '' then begin
            if Location.Code <> ProdOrderComp."Location Code" then
                Location.Get(ProdOrderComp."Location Code");
            if Location."Bin Mandatory" and (not Location."Directed Put-away and Pick") then
                ProdOrderWarehouseMgt.GetDefaultBin(ProdOrderComp."Item No.", ProdOrderComp."Variant Code", ProdOrderComp."Location Code", BinCode);
        end;
    end;

    procedure SetProdOrderLineBinCodeFromRoute(var ProdOrderLine: Record "Prod. Order Line"; ParentLocationCode: Code[10]; RoutingNo: Code[20])
    var
        RouteBinCode: Code[20];
    begin
        RouteBinCode :=
          ProdOrderWarehouseMgt.GetLastOperationFromBinCode(
            RoutingNo,
            ProdOrderLine."Routing Version Code",
            ProdOrderLine."Location Code",
            false,
            "Flushing Method"::Manual);
        SetProdOrderLineBinCode(ProdOrderLine, RouteBinCode, ParentLocationCode);
    end;

    procedure SetProdOrderLineBinCodeFromProdRtngLines(var ProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrderRoutingLineBinCode: Code[20];
    begin
        if ProdOrderLine."Planning Level Code" > 0 then
            exit;

        ProdOrderRoutingLineBinCode :=
            ProdOrderWarehouseMgt.GetProdRoutingLastOperationFromBinCode(
                ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.",
                ProdOrderLine."Routing No.", ProdOrderLine."Location Code");
        SetProdOrderLineBinCode(ProdOrderLine, ProdOrderRoutingLineBinCode, ProdOrderLine."Location Code");
    end;

    procedure SetProdOrderLineBinCodeFromPlanningRtngLines(var ProdOrderLine: Record "Prod. Order Line"; ReqLine: Record "Requisition Line")
    var
        PlanningLinesBinCode: Code[20];
    begin
        if ProdOrderLine."Planning Level Code" > 0 then
            exit;

        PlanningLinesBinCode :=
          ProdOrderWarehouseMgt.GetPlanningRtngLastOperationFromBinCode(
            ReqLine."Worksheet Template Name",
            ReqLine."Journal Batch Name",
            ReqLine."Line No.",
            ReqLine."Location Code");
        SetProdOrderLineBinCode(ProdOrderLine, PlanningLinesBinCode, ReqLine."Location Code");
    end;

    local procedure SetProdOrderLineBinCode(var ProdOrderLine: Record "Prod. Order Line"; ParentBinCode: Code[20]; ParentLocationCode: Code[10])
    var
        Location: Record Location;
        FromProdBinCode: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetProdOrderLineBinCode(ProdOrderLine, ParentBinCode, ParentLocationCode, IsHandled);
        if IsHandled then
            exit;

        ProdOrder.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.");
        if (ProdOrder."Location Code" = ProdOrderLine."Location Code") and (ProdOrder."Bin Code" <> '') then begin
            ProdOrderLine.Validate("Bin Code", ProdOrder."Bin Code");
            exit;
        end;

        if ParentBinCode <> '' then
            ProdOrderLine.Validate("Bin Code", ParentBinCode)
        else
            if ProdOrderLine."Bin Code" = '' then begin
                if Location.Get(ParentLocationCode) then
                    FromProdBinCode := Location."From-Production Bin Code";
                if FromProdBinCode <> '' then
                    ProdOrderLine.Validate("Bin Code", FromProdBinCode)
                else
                    if Location."Bin Mandatory" and not Location."Directed Put-away and Pick" then
                        if ProdOrderWarehouseMgt.GetDefaultBin(ProdOrderLine."Item No.", ProdOrderLine."Variant Code", Location.Code, FromProdBinCode) then
                            ProdOrderLine.Validate("Bin Code", FromProdBinCode);
            end;
    end;

    procedure FindAndSetProdOrderLineBinCodeFromProdRoutingLines(ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20]; ProdOrderLineNo: Integer)
    begin
        if ProdOrderLine.Get(ProdOrderStatus, ProdOrderNo, ProdOrderLineNo) then begin
            SetProdOrderLineBinCodeFromProdRtngLines(ProdOrderLine);
            ProdOrderLine.Modify();
        end;
    end;

    procedure AssignProdOrderLineBinCodeFromProdRtngLineMachineCenter(var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        MachineCenter: Record "Machine Center";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAssignProdOrderLineBinCodeFromProdRtngLineMachineCenter(ProdOrderRoutingLine, MachineCenter, IsHandled);
        if IsHandled then
            exit;

        MachineCenter.SetRange("Work Center No.", ProdOrderRoutingLine."Work Center No.");
        if PAGE.RunModal(PAGE::"Machine Center List", MachineCenter) = ACTION::LookupOK then
            if (ProdOrderRoutingLine."No." <> MachineCenter."No.") or
               (ProdOrderRoutingLine.Type = ProdOrderRoutingLine.Type::"Work Center")
            then begin
                ProdOrderRoutingLine.Type := ProdOrderRoutingLine.Type::"Machine Center";
                ProdOrderRoutingLine.Validate("No.", MachineCenter."No.");
                FindAndSetProdOrderLineBinCodeFromProdRoutingLines(
                  ProdOrderRoutingLine.Status, ProdOrderRoutingLine."Prod. Order No.", ProdOrderRoutingLine."Routing Reference No.");
            end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculate(ProdOrderLine: Record "Prod. Order Line"; var ErrorOccured: Boolean)
    begin
    end;

    local procedure CalculateLeadTime(ProdOrderLine2: Record "Prod. Order Line"; Direction: Option Forward,Backward; LetDueDateDecrease: Boolean)
    var
        LeadTime: Code[20];
    begin
        ProdOrderLine := ProdOrderLine2;

        LeadTimeMgt.SetManualScheduling(ProdOrderLine2."Manual Scheduling");
        LeadTime :=
          LeadTimeMgt.ManufacturingLeadTime(
            ProdOrderLine."Item No.", ProdOrderLine."Location Code", ProdOrderLine."Variant Code");

        if Direction = Direction::Forward then
            // Ending Date calculated forward from Starting Date
            ProdOrderLine."Ending Date" :=
            LeadTimeMgt.GetPlannedEndingDate(
              ProdOrderLine."Item No.", ProdOrderLine."Location Code", ProdOrderLine."Variant Code", '',
              LeadTime, "Requisition Ref. Order Type"::"Prod. Order", ProdOrderLine."Starting Date")
        else
            // Starting Date calculated backward from Ending Date
            ProdOrderLine."Starting Date" :=
            LeadTimeMgt.GetPlannedStartingDate(
              ProdOrderLine."Item No.", ProdOrderLine."Location Code", ProdOrderLine."Variant Code", '',
              LeadTime, "Requisition Ref. Order Type"::"Prod. Order", ProdOrderLine."Ending Date");

        CalculateProdOrderDates(ProdOrderLine, LetDueDateDecrease);

        ProdOrderLine2 := ProdOrderLine;
    end;

    local procedure CheckProdOrderLineQuantity(var ProdOrderLineToCheck: Record "Prod. Order Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckProdOrderLineQuantity(ProdOrderLineToCheck, IsHandled);
        if not IsHandled then
            ProdOrderLineToCheck.TestField(Quantity);
    end;

    local procedure CheckingRoundingPrecision(ChildItem: Record Item; ProdLineItem: Record Item; var QtyRoundPrecision: Decimal; Level: Integer)
    begin
        if (ChildItem."Rounding Precision" = 0) or (QtyRoundPrecision = 0) then
            exit;

        if (not ProdLineItem.Get(ProdOrderLine."Item No.")) or (ProdLineItem."Replenishment System" <> ProdLineItem."Replenishment System"::"Prod. Order") then
            exit;

        if (ChildItem."Base Unit of Measure" <> ProdBOMLine[Level]."Unit of Measure Code") then
            exit;
        QtyRoundPrecision := ChildItem."Rounding Precision";
        ProdOrderComp."Qty. Rounding Precision" := ChildItem."Rounding Precision";
        ProdOrderComp."Qty. Rounding Precision (Base)" := ChildItem."Rounding Precision";
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertProdRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferBOM(ProdOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line"; ProdBOMNo: Code[20]; Level: Integer; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal; Blocked: Boolean; var ErrorOccured: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferTaskInfo(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; VersionCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferRouting(var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferRoutingLine(var ProdOrderLine: Record "Prod. Order Line"; var RoutingLine: Record "Routing Line"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferBOMComponent(var ProdOrderLine: Record "Prod. Order Line"; var ProductionBOMLine: Record "Production BOM Line"; var ProdOrderComponent: Record "Prod. Order Component"; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProdOrderCompFilter(var ProdOrderComp: Record "Prod. Order Component"; ProdBOMLine: Record "Production BOM Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProdOrderCompInsert(var ProdOrderComponent: Record "Prod. Order Component"; ProductionBOMLine: Record "Production BOM Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAssignProdOrderLineBinCodeFromProdRtngLineMachineCenter(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var MachineCenter: Record "Machine Center"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculate(var ItemLedgerEntry: Record "Item Ledger Entry"; var CapacityLedgerEntry: Record "Capacity Ledger Entry"; Direction: Option Forward,Backward; CalcRouting: Boolean; CalcComponents: Boolean; var DeleteRelations: Boolean; LetDueDateDecrease: Boolean; var IsHandled: Boolean; var ProdOrderLine: Record "Prod. Order Line"; var ErrorOccured: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateRoutingFromActual(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; Direction: Option; CalcStartEndDate: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculateProdOrderDates(var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyProdBOMComments(var ProductionBOMCommentLine: Record "Production BOM Comment Line"; var ProductionBOMLine: Record "Production BOM Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProdOrderCompModify(var ProdOrderComp: Record "Prod. Order Component"; var ProdBOMLine: Record "Production BOM Line"; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetProdOrderLineBinCode(var ProdOrderLine: Record "Prod. Order Line"; ParentBinCode: Code[20]; ParentLocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferBOM(var ProdOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; ProdBOMNo: Code[20]; Level: Integer; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal; Blocked: Boolean; var ErrorOccured: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferBOMComponent(ProdOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line"; var ProdBOMLine: Record "Production BOM Line"; var ErrorOccured: Boolean; var IsHandled: Boolean; Level: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferRouting(var ProdOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateProdOrderDates(var ProductionOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; var ProdOrderModify: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateOnAfterGetpLanningParameterAtSKUCalcComponents(var ProdOrderLine: Record "Prod. Order Line"; var SKU: Record "Stockkeeping Unit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateOnAfterCalcShouldCheckIfEntriesExist(var ProdOrderLine: Record "Prod. Order Line"; var CalcRouting: Boolean; var ShouldCheckIfEntriesExist: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateOnAfterItemLedgEntrySetFilters(ProdOrderLine: Record "Prod. Order Line"; var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateOnBeforeCheckNextOperation(ProdOrder: Record "Production Order"; ProdOrderLine2: Record "Prod. Order Line"; var ProdOrderRoutingLine3: Record "Prod. Order Routing Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateOnBeforeCheckPrevOperation(ProdOrder: Record "Production Order"; ProdOrderLine2: Record "Prod. Order Line"; var ProdOrderRoutingLine3: Record "Prod. Order Routing Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateComponentsOnBeforeUpdateRoutingLinkCode(var ProdOrderComp: Record "Prod. Order Component"; ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateProdOrderDatesOnAfterSetFilters(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProductionOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateProdOrderDatesOnSetBeforeDueDate(var ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateProdOrderDatesOnBeforeUpdateDatetime(var ProdOrderLine: Record "Prod. Order Line"; NewDueDate: Date; LetDueDateDecreate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateRoutingFromActualOnAfterSetProdOrderRoutingLineFilters(var ProdOrderRoutingLine: Record "Prod. Order Routing Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateRoutingFromActualOnBeforeCalcStartEndDate(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var CalcStartEndDate: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyRoutingToolsOnAfterRoutingToolSetFilters(var RoutingTool: Record "Routing Tool"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; VersionCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferBOMOnAfterCalcReqQty(ProductionBOMLine: Record "Production BOM Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderLine: Record "Prod. Order Line"; var ReqQty: Decimal; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferBOMOnAfterSetFiltersProdBOMLine(var ProdBOMLine: Record "Production BOM Line"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferBOMOnBeforeProcessItem(ProdBOMLine: Record "Production BOM Line"; ReqQty: Decimal; var SkipTransfer: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferBOMOnBeforeProcessProdBOM(ProdBOMLine: Record "Production BOM Line"; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal; var ReqQty: Decimal; var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferBOMProcessItemOnAfterGetPlanningParameters(var ProdOrderLine: Record "Prod. Order Line"; var ComponentSKU: Record "Stockkeeping Unit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferBOMProcessItemOnBeforeGetPlanningParameters(var ProdOrderComponent: Record "Prod. Order Component"; ProductionBOMLine: Record "Production BOM Line"; StockkeepingUnit: Record "Stockkeeping Unit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferRoutingOnbeforeValidateDirectUnitCost(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderLine: Record "Prod. Order Line"; RoutingLine: Record "Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnTransferRoutingOnBeforeCalcRoutingCostPerUnit(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderLine: Record "Prod. Order Line"; RoutingLine: Record "Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateRoutingOnBeforeSetLeadTime(var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateComponents(ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRecalculate(var ProdOrderLine: Record "Prod. Order Line"; CalcRouting: Boolean; CalcComponents: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecalculate(var ProdOrderLine: Record "Prod. Order Line"; CalcRouting: Boolean; CalcComponents: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRecalculateProcedure(var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnRecalculateOnBeforeCalculateRouting(var ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferBOMProcessItemOnBeforeSetFlushingMethod(var ProdOrderLine: Record "Prod. Order Line"; var ComponentSKU: Record "Stockkeeping Unit"; var ProdOrderComp: Record "Prod. Order Component"; ProdBOMLine: Record "Production BOM Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPlanningLevelCode(var ProdOrderComponent: Record "Prod. Order Component"; var ProductionBOMLine: Record "Production BOM Line"; var SKU: Record "Stockkeeping Unit"; var ComponentSKU: Record "Stockkeeping Unit"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcessRoutingLine(var RoutingLine: Record "Routing Line"; var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyRoutingComments(var RoutingCommentLine: Record "Routing Comment Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line"; VersionCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateRoutingOnBeforeUpdateProdOrderRoutingLineDates(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckProdOrderLineQuantity(ProdOrderLine: Record "Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateOnBeforeCalcComponents(ProdOrderLine: Record "Prod. Order Line"; CalcComponents: Boolean; var SkipCalcComponents: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetDefaultBin(var ProdOrderComponent: Record "Prod. Order Component"; var Location: Record Location; var Item: Record Item; var ProdOrderWarehouseMgt: Codeunit "Prod. Order Warehouse Mgt."; var BinCode: Code[20]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindProdOrderRoutingLine(var ProdOrderLine: Record "Prod. Order Line"; var ProductionBOMLine: Record "Production BOM Line"; var IsHandled: Boolean; var ReqQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateRoutingFromActualOnAfterCalculateRoutingLine(var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
    end;
}

