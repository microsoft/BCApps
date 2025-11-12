// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Planning;

using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Foundation.UOM;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.MachineCenter;

codeunit 99000819 "Mfg. Planning Line Management"
{
    Permissions = TableData "Manufacturing Setup" = rm,
                  TableData "Routing Header" = r,
                  TableData "Production BOM Header" = r,
                  TableData "Production BOM Line" = r,
                  TableData "Prod. Order Capacity Need" = rd,
                  TableData "Planning Component" = rimd,
                  TableData "Planning Routing Line" = rimd;

    var
        GetPlanningParameters: Codeunit "Planning-Get Parameters";
        MfgCostCalcMgt: Codeunit "Mfg. Cost Calculation Mgt.";
        VersionMgt: Codeunit VersionManagement;
#if not CLEAN27
        PlanningLineManagement: Codeunit "Planning Line Management";
#endif
        Text000: Label 'BOM phantom structure for %1 is higher than 50 levels.';
        Text010: Label 'The line with %1 %2 for %3 %4 or one of its versions, has no %5 defined.';
        Text011: Label '%1 has recalculate set to false.';
        Text012: Label 'You must specify %1 in %2 %3.';
        Text014: Label 'Production BOM Header No. %1 used by Item %2 has BOM levels that exceed 50.';

    internal procedure TransferRouting(var ReqLine: Record "Requisition Line"; var TempPlanningErrorLog: Record "Planning Error Log" temporary; PlanningResiliency: Boolean)
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferRouting(ReqLine, PlanningResiliency, IsHandled);
#if not CLEAN27
        PlanningLineManagement.RunOnBeforeTransferRouting(ReqLine, PlanningResiliency, IsHandled);
#endif
        if IsHandled then
            exit;

        if ReqLine."Routing No." = '' then
            exit;

        RoutingHeader.Get(ReqLine."Routing No.");
        RoutingLine.SetRange("Routing No.", ReqLine."Routing No.");
        RoutingLine.SetRange("Version Code", ReqLine."Routing Version Code");
        if RoutingLine.Find('-') then
            repeat
                if PlanningResiliency and PlanningRoutingLine.Recalculate then
                    TempPlanningErrorLog.SetError(
                      StrSubstNo(Text011, PlanningRoutingLine.TableCaption()),
                      Database::"Routing Header", RoutingHeader.GetPosition());
                PlanningRoutingLine.TestField(Recalculate, false);
                CheckRoutingLine(RoutingHeader, RoutingLine, TempPlanningErrorLog, PlanningResiliency);
                TransferRoutingLine(PlanningRoutingLine, ReqLine, RoutingLine);
            until RoutingLine.Next() = 0;

        OnAfterTransferRouting(ReqLine);
#if not CLEAN27
        PlanningLineManagement.RunOnAfterTransferRouting(ReqLine);
#endif
    end;

    local procedure CheckRoutingLine(RoutingHeader: Record "Routing Header"; RoutingLine: Record "Routing Line"; var TempPlanningErrorLog: Record "Planning Error Log" temporary; PlanningResiliency: Boolean)
    var
        MachineCenter: Record "Machine Center";
    begin
        if PlanningResiliency and (RoutingLine."No." = '') then begin
            RoutingHeader.Get(RoutingLine."Routing No.");
            TempPlanningErrorLog.SetError(
              StrSubstNo(
                Text010,
                RoutingLine.FieldCaption("Operation No."), RoutingLine."Operation No.",
                RoutingHeader.TableCaption(), RoutingHeader."No.",
                RoutingLine.FieldCaption("No.")),
              Database::"Routing Header", RoutingHeader.GetPosition());
        end;
        RoutingLine.TestField("No.");

        if PlanningResiliency and (RoutingLine."Work Center No." = '') then begin
            MachineCenter.Get(RoutingLine."No.");
            TempPlanningErrorLog.SetError(
              StrSubstNo(
                Text012,
                MachineCenter.FieldCaption("Work Center No."),
                MachineCenter.TableCaption(),
                MachineCenter."No."),
              Database::"Machine Center", MachineCenter.GetPosition());
        end;
        RoutingLine.TestField("Work Center No.");
    end;

    local procedure TransferRoutingLine(var PlanningRoutingLine: Record "Planning Routing Line"; ReqLine: Record "Requisition Line"; RoutingLine: Record "Routing Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferRoutingLine(PlanningRoutingLine, ReqLine, RoutingLine, IsHandled);
#if not CLEAN27
        PlanningLineManagement.RunOnBeforeTransferRoutingLine(PlanningRoutingLine, ReqLine, RoutingLine, IsHandled);
#endif
        if IsHandled then
            exit;

        PlanningRoutingLine.TransferFromReqLine(ReqLine);
        PlanningRoutingLine.TransferFromRoutingLine(RoutingLine);

        OnTransferRoutingLineOnBeforeCalcRoutingCostPerUnit(PlanningRoutingLine, ReqLine, RoutingLine);
#if not CLEAN27
        PlanningLineManagement.RunOnTransferRoutingLineOnBeforeCalcRoutingCostPerUnit(PlanningRoutingLine, ReqLine, RoutingLine);
#endif

        MfgCostCalcMgt.CalcRoutingCostPerUnit(
          PlanningRoutingLine.Type, PlanningRoutingLine."No.", PlanningRoutingLine."Direct Unit Cost", PlanningRoutingLine."Indirect Cost %", PlanningRoutingLine."Overhead Rate", PlanningRoutingLine."Unit Cost per", PlanningRoutingLine."Unit Cost Calculation");

        OnTransferRoutingLineOnBeforeValidateDirectUnitCost(ReqLine, RoutingLine, PlanningRoutingLine);
        PlanningRoutingLine.Validate("Direct Unit Cost");

        PlanningRoutingLine.UpdateDatetime();
        OnAfterTransferRtngLine(ReqLine, RoutingLine, PlanningRoutingLine);
#if not CLEAN27
        PlanningLineManagement.RunOnAfterTransferRtngLine(ReqLine, RoutingLine, PlanningRoutingLine);
#endif
        PlanningRoutingLine.Insert();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Planning Line Management", 'OnCalculateOnTransferBOM', '', false, false)]
    local procedure OnCalculateOnTransferBOM(
        var RequisitionLine: Record "Requisition Line"; Item: Record Item; var PlanningComponent: Record "Planning Component";
        var TempPlanningErrorLog: Record "Planning Error Log" temporary; var TempPlanningComponent: Record "Planning Component" temporary;
        SKU: Record "Stockkeeping Unit"; PlanningResiliency: Boolean; var NextPlanningCompLineNo: Integer; Blocked: Boolean)
    var
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        TransferBOM(
            RequisitionLine, RequisitionLine."Production BOM No.", 1, RequisitionLine."Qty. per Unit of Measure",
            UOMMgt.GetQtyPerUnitOfMeasure(
                Item, VersionMgt.GetBOMUnitOfMeasure(RequisitionLine."Production BOM No.", RequisitionLine."Production BOM Version Code")),
            PlanningResiliency, NextPlanningCompLineNo, PlanningComponent, TempPlanningErrorLog, TempPlanningComponent,
            Blocked, SKU);
    end;

    internal procedure TransferBOM(var ReqLine: Record "Requisition Line"; ProdBOMNo: Code[20]; Level: Integer; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal; PlanningResiliency: Boolean; var NextPlanningCompLineNo: Integer; var PlanningComponent: Record "Planning Component"; var TempPlanningErrorLog: Record "Planning Error Log" temporary; var TempPlanningComponent: Record "Planning Component" temporary; Blocked: Boolean; SKU: Record "Stockkeeping Unit")
    var
        BOMHeader: Record "Production BOM Header";
        CompSKU: Record "Stockkeeping Unit";
        PlanningRtngLine2: Record "Planning Routing Line";
        ProdBOMLine: array[50] of Record "Production BOM Line";
        ProductionBOMVersion: Record "Production BOM Version";
        Item: Record Item;
        VersionCode: Code[20];
        ReqQty: Decimal;
        IsHandled: Boolean;
        UpdateCondition: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferBOM(ProdBOMNo, Level, LineQtyPerUOM, ItemQtyPerUOM, ReqLine, Blocked, IsHandled);
#if not CLEAN27
        PlanningLineManagement.RunOnBeforeTransferBOM(ProdBOMNo, Level, LineQtyPerUOM, ItemQtyPerUOM, ReqLine, Blocked, IsHandled);
#endif
        if not IsHandled then begin

            if ReqLine."Production BOM No." = '' then
                exit;

            PlanningComponent.LockTable();

            if Level > 50 then begin
                if PlanningResiliency then begin
                    BOMHeader.Get(ReqLine."Production BOM No.");
                    TempPlanningErrorLog.SetError(
                      StrSubstNo(Text014, ReqLine."Production BOM No.", ReqLine."No."),
                      Database::"Production BOM Header", BOMHeader.GetPosition());
                end;
                Error(Text000, ProdBOMNo);
            end;

            if NextPlanningCompLineNo = 0 then begin
                PlanningComponent.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
                PlanningComponent.SetRange("Worksheet Batch Name", ReqLine."Journal Batch Name");
                PlanningComponent.SetRange("Worksheet Line No.", ReqLine."Line No.");
                if PlanningComponent.Find('+') then
                    NextPlanningCompLineNo := PlanningComponent."Line No.";
                PlanningComponent.Reset();
            end;

            BOMHeader.Get(ProdBOMNo);

            if Level > 1 then
                VersionCode := VersionMgt.GetBOMVersion(ProdBOMNo, ReqLine."Starting Date", true)
            else
                VersionCode := ReqLine."Production BOM Version Code";
            if VersionCode <> '' then begin
                ProductionBOMVersion.Get(ProdBOMNo, VersionCode);
                ProductionBOMVersion.TestField(Status, ProductionBOMVersion.Status::Certified);
            end else
                BOMHeader.TestField(Status, BOMHeader.Status::Certified);

            ProdBOMLine[Level].SetRange("Production BOM No.", ProdBOMNo);
            if Level > 1 then
                ProdBOMLine[Level].SetRange("Version Code", VersionMgt.GetBOMVersion(BOMHeader."No.", ReqLine."Starting Date", true))
            else
                ProdBOMLine[Level].SetRange("Version Code", ReqLine."Production BOM Version Code");
            ProdBOMLine[Level].SetFilter("Starting Date", '%1|..%2', 0D, ReqLine."Starting Date");
            ProdBOMLine[Level].SetFilter("Ending Date", '%1|%2..', 0D, ReqLine."Starting Date");
            OnTransferBOMOnAfterProdBOMLineSetFilters(ProdBOMLine[Level], ReqLine);
#if not CLEAN27
            PlanningLineManagement.RunOnTransferBOMOnAfterProdBOMLineSetFilters(ProdBOMLine[Level], ReqLine);
#endif
            if ProdBOMLine[Level].Find('-') then
                repeat
                    IsHandled := false;
                    OnTransferBOMOnBeforeTransferPlanningComponent(ReqLine, ProdBOMLine[Level], Blocked, IsHandled, Level);
#if not CLEAN27
                    PlanningLineManagement.RunOnTransferBOMOnBeforeTransferPlanningComponent(ReqLine, ProdBOMLine[Level], Blocked, IsHandled, Level);
#endif
                    if not IsHandled then begin
                        if ProdBOMLine[Level]."Routing Link Code" <> '' then begin
                            PlanningRtngLine2.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
                            PlanningRtngLine2.SetRange("Worksheet Batch Name", ReqLine."Journal Batch Name");
                            PlanningRtngLine2.SetRange("Worksheet Line No.", ReqLine."Line No.");
                            PlanningRtngLine2.SetRange("Routing Link Code", ProdBOMLine[Level]."Routing Link Code");
                            OnTransferBOMOnBeforePlanningRtngLineFind(PlanningRtngLine2, ProdBOMLine[Level], ReqLine);
#if not CLEAN27
                            PlanningLineManagement.RunOnTransferBOMOnBeforePlanningRtngLineFind(PlanningRtngLine2, ProdBOMLine[Level], ReqLine);
#endif
                            PlanningRtngLine2.FindFirst();
                            ReqQty :=
                              ProdBOMLine[Level].Quantity *
                              (1 + ProdBOMLine[Level]."Scrap %" / 100) *
                              (1 + PlanningRtngLine2."Scrap Factor % (Accumulated)") *
                              LineQtyPerUOM / ItemQtyPerUOM +
                              PlanningRtngLine2."Fixed Scrap Qty. (Accum.)";
                        end else
                            ReqQty :=
                              ProdBOMLine[Level].Quantity *
                              (1 + ProdBOMLine[Level]."Scrap %" / 100) *
                              LineQtyPerUOM / ItemQtyPerUOM;

                        OnTransferBOMOnAfterCalculateReqQty(ReqQty, ProdBOMLine[Level], PlanningRtngLine2, LineQtyPerUOM, ItemQtyPerUOM);
                        case ProdBOMLine[Level].Type of
                            ProdBOMLine[Level].Type::Item:
                                begin
                                    IsHandled := false;
                                    Item.SetLoadFields(Blocked);
                                    Item.Get(ProdBOMLine[Level]."No.");
                                    UpdateCondition := (ReqQty <> 0) or ((ReqQty = 0) and not (Item.Blocked));
                                    OnTransferBOMOnBeforeUpdatePlanningComp(ProdBOMLine[Level], UpdateCondition, IsHandled, ReqQty);
                                    if not IsHandled then
                                        if UpdateCondition then begin
                                            if not IsPlannedComp(PlanningComponent, ReqLine, ProdBOMLine[Level], SKU) then begin
                                                NextPlanningCompLineNo := NextPlanningCompLineNo + 10000;
                                                CreatePlanningComponentFromProdBOM(
                                                  PlanningComponent, ReqLine, ProdBOMLine[Level], CompSKU, LineQtyPerUOM, ItemQtyPerUOM,
                                                  NextPlanningCompLineNo, SKU, Blocked);
                                            end else begin
                                                PlanningComponent.Reset();
                                                PlanningComponent.BlockDynamicTracking(Blocked);
                                                PlanningComponent.SetRequisitionLine(ReqLine);
                                                PlanningComponent.Validate(
                                                  "Quantity per",
                                                  PlanningComponent."Quantity per" + ProdBOMLine[Level]."Quantity per" * LineQtyPerUOM / ItemQtyPerUOM);
                                                PlanningComponent.Validate("Routing Link Code", ProdBOMLine[Level]."Routing Link Code");
                                                OnBeforeModifyPlanningComponent(ReqLine, ProdBOMLine[Level], PlanningComponent, LineQtyPerUOM, ItemQtyPerUOM);
#if not CLEAN27
                                                PlanningLineManagement.RunOnBeforeModifyPlanningComponent(ReqLine, ProdBOMLine[Level], PlanningComponent, LineQtyPerUOM, ItemQtyPerUOM);
#endif
                                                PlanningComponent.Modify();
                                            end;

                                            // A temporary list of Planning Components handled is sustained:
                                            TempPlanningComponent := PlanningComponent;
                                            if not TempPlanningComponent.Insert() then
                                                TempPlanningComponent.Modify();
                                        end;
                                end;
                            ProdBOMLine[Level].Type::"Production BOM":
                                begin
                                    OnTransferBOMOnBeforeTransferProductionBOM(ReqQty, ProdBOMLine[Level], LineQtyPerUOM, ItemQtyPerUOM, ReqLine);
                                    TransferBOM(
                                        ReqLine, ProdBOMLine[Level]."No.", Level + 1, ReqQty, 1, PlanningResiliency, NextPlanningCompLineNo,
                                        PlanningComponent, TempPlanningErrorLog, TempPlanningComponent, Blocked, SKU);
                                    ProdBOMLine[Level].SetRange("Production BOM No.", ProdBOMNo);
                                    if Level > 1 then
                                        ProdBOMLine[Level].SetRange("Version Code", VersionMgt.GetBOMVersion(ProdBOMNo, ReqLine."Starting Date", true))
                                    else
                                        ProdBOMLine[Level].SetRange("Version Code", ProdBOMLine[Level]."Version Code");
                                    ProdBOMLine[Level].SetFilter("Starting Date", '%1|..%2', 0D, ReqLine."Starting Date");
                                    ProdBOMLine[Level].SetFilter("Ending Date", '%1|%2..', 0D, ReqLine."Starting Date");
                                end;
                        end;
                    end;
                until ProdBOMLine[Level].Next() = 0;
        end;
        OnAfterTransferBOM(ReqLine, ProdBOMNo, Level, LineQtyPerUOM, ItemQtyPerUOM);
#if not CLEAN27
        PlanningLineManagement.RunOnAfterTransferBOM(ReqLine, ProdBOMNo, Level, LineQtyPerUOM, ItemQtyPerUOM);
#endif
    end;

    local procedure CreatePlanningComponentFromProdBOM(var PlanningComponent: Record "Planning Component"; ReqLine: Record "Requisition Line"; ProdBOMLine: Record "Production BOM Line"; CompSKU: Record "Stockkeeping Unit"; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal; var NextPlanningCompLineNo: Integer; SKU: Record "Stockkeeping Unit"; Blocked: Boolean)
    var
        Item2: Record Item;
    begin
        PlanningComponent.Reset();
        PlanningComponent.Init();
        PlanningComponent.BlockDynamicTracking(Blocked);
        PlanningComponent.SetRequisitionLine(ReqLine);
        PlanningComponent."Worksheet Template Name" := ReqLine."Worksheet Template Name";
        PlanningComponent."Worksheet Batch Name" := ReqLine."Journal Batch Name";
        PlanningComponent."Worksheet Line No." := ReqLine."Line No.";
        PlanningComponent."Line No." := NextPlanningCompLineNo;
        PlanningComponent.Validate("Item No.", ProdBOMLine."No.");
        PlanningComponent."Variant Code" := ProdBOMLine."Variant Code";
        PlanningComponent."Location Code" := SKU."Components at Location";
        PlanningComponent.Description := ProdBOMLine.Description;
        PlanningComponent."Planning Line Origin" := ReqLine."Planning Line Origin";
        PlanningComponent.Validate("Unit of Measure Code", ProdBOMLine."Unit of Measure Code");
        PlanningComponent."Quantity per" := ProdBOMLine."Quantity per" * LineQtyPerUOM / ItemQtyPerUOM;
        PlanningComponent.Validate("Routing Link Code", ProdBOMLine."Routing Link Code");
        PlanningComponent.Length := ProdBOMLine.Length;
        PlanningComponent.Width := ProdBOMLine.Width;
        PlanningComponent.Weight := ProdBOMLine.Weight;
        PlanningComponent.Depth := ProdBOMLine.Depth;
        PlanningComponent.Quantity := ProdBOMLine.Quantity;
        PlanningComponent.Position := ProdBOMLine.Position;
        PlanningComponent."Position 2" := ProdBOMLine."Position 2";
        PlanningComponent."Position 3" := ProdBOMLine."Position 3";
        PlanningComponent."Lead-Time Offset" := ProdBOMLine."Lead-Time Offset";
        PlanningComponent.Validate("Scrap %", ProdBOMLine."Scrap %");
        PlanningComponent.Validate("Calculation Formula", ProdBOMLine."Calculation Formula");

        GetPlanningParameters.AtSKU(CompSKU, PlanningComponent."Item No.", PlanningComponent."Variant Code", PlanningComponent."Location Code");
        if Item2.Get(PlanningComponent."Item No.") then
            PlanningComponent.Critical := Item2.Critical;

        PlanningComponent."Flushing Method" := CompSKU."Flushing Method";
        OnTransferBOMOnBeforeGetDefaultBin(PlanningComponent, ProdBOMLine, ReqLine, SKU);
#if not CLEAN27
        PlanningLineManagement.RunOnTransferBOMOnBeforeGetDefaultBin(PlanningComponent, ProdBOMLine, ReqLine, SKU);
#endif
        PlanningComponent.GetDefaultBin();

        if SetPlanningLevelCode(PlanningComponent, ProdBOMLine, SKU, CompSKU) then
            PlanningComponent."Planning Level Code" := ReqLine."Planning Level" + 1;

        PlanningComponent."Ref. Order Type" := ReqLine."Ref. Order Type";
        PlanningComponent."Ref. Order Status" := ReqLine."Ref. Order Status";
        PlanningComponent."Ref. Order No." := ReqLine."Ref. Order No.";
        OnBeforeInsertPlanningComponent(ReqLine, ProdBOMLine, PlanningComponent, LineQtyPerUOM, ItemQtyPerUOM);
#if not CLEAN27
        PlanningLineManagement.RunOnBeforeInsertPlanningComponent(ReqLine, ProdBOMLine, PlanningComponent, LineQtyPerUOM, ItemQtyPerUOM);
#endif
        PlanningComponent.Insert();
    end;

    local procedure SetPlanningLevelCode(var PlanningComponent: Record "Planning Component"; var ProdBOMLine: Record "Production BOM Line"; var SKU: Record "Stockkeeping Unit"; var ComponentSKU: Record "Stockkeeping Unit") Result: Boolean
    begin
        Result :=
            (SKU."Manufacturing Policy" = SKU."Manufacturing Policy"::"Make-to-Order") and
            (ComponentSKU."Manufacturing Policy" = ComponentSKU."Manufacturing Policy"::"Make-to-Order") and
            (ComponentSKU."Replenishment System" = ComponentSKU."Replenishment System"::"Prod. Order");

        OnAfterSetPlanningLevelCode(PlanningComponent, ProdBOMLine, SKU, ComponentSKU, Result);
#if not CLEAN27
        PlanningLineManagement.RunOnAfterSetPlanningLevelCode(PlanningComponent, ProdBOMLine, SKU, ComponentSKU, Result);
#endif
    end;

    local procedure IsPlannedComp(var PlanningComp: Record "Planning Component"; ReqLine: Record "Requisition Line"; ProdBOMLine: Record "Production BOM Line"; SKU: Record "Stockkeeping Unit"): Boolean
    var
        PlanningComp2: Record "Planning Component";
    begin
        PlanningComp2 := PlanningComp;

        PlanningComp.SetCurrentKey("Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.", "Item No.");
        PlanningComp.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
        PlanningComp.SetRange("Worksheet Batch Name", ReqLine."Journal Batch Name");
        PlanningComp.SetRange("Worksheet Line No.", ReqLine."Line No.");
        PlanningComp.SetRange("Item No.", ProdBOMLine."No.");
        if PlanningComp.Find('-') then
            repeat
                if IsPlannedCompFound(PlanningComp, ProdBOMLine, SKU) then
                    exit(true);
            until PlanningComp.Next() = 0;

        PlanningComp := PlanningComp2;
        exit(false);
    end;

    local procedure IsPlannedCompFound(PlanningComp: Record "Planning Component"; ProdBOMLine: Record "Production BOM Line"; SKU: Record "Stockkeeping Unit"): Boolean
    var
        IsFound: Boolean;
    begin
        IsFound :=
            (PlanningComp."Variant Code" = ProdBOMLine."Variant Code") and
            (PlanningComp."Routing Link Code" = ProdBOMLine."Routing Link Code") and
            (PlanningComp.Position = ProdBOMLine.Position) and
            (PlanningComp."Position 2" = ProdBOMLine."Position 2") and
            (PlanningComp."Position 3" = ProdBOMLine."Position 3") and
            (PlanningComp.Length = ProdBOMLine.Length) and
            (PlanningComp.Width = ProdBOMLine.Width) and
            (PlanningComp.Weight = ProdBOMLine.Weight) and
            (PlanningComp.Depth = ProdBOMLine.Depth) and
            (PlanningComp."Unit of Measure Code" = ProdBOMLine."Unit of Measure Code") and
            (PlanningComp."Calculation Formula" = ProdBOMLine."Calculation Formula");
        OnAfterIsPlannedCompFound(PlanningComp, ProdBOMLine, IsFound, SKU);
#if not CLEAN27
        PlanningLineManagement.RunOnAfterIsPlannedCompFound(PlanningComp, ProdBOMLine, IsFound, SKU);
#endif
        exit(IsFound);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Planning Line Management", 'OnCalculateRouting', '', true, true)]
    local procedure OnCalculateRouting(var RequisitionLine: Record "Requisition Line"; var TempPlanningErrorLog: Record "Planning Error Log" temporary; PlanningResiliency: Boolean)
    var
        PlanningRtngLine: Record "Planning Routing Line";
        ProdOrderCapNeed: Record "Prod. Order Capacity Need";
    begin
        PlanningRtngLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRtngLine.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        PlanningRtngLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        PlanningRtngLine.DeleteAll();

        ProdOrderCapNeed.SetCurrentKey(
            "Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.");
        ProdOrderCapNeed.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        ProdOrderCapNeed.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        ProdOrderCapNeed.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        ProdOrderCapNeed.DeleteAll();
        TransferRouting(RequisitionLine, TempPlanningErrorLog, PlanningResiliency);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Planning Line Management", 'OnTransferASMBOMOnAfterSetAsmBOMComp', '', true, true)]
    local procedure OnTransferASMBOMOnAfterSetAsmBOMComp(var PlanningComponent: Record "Planning Component")
    begin
        PlanningComponent.Validate("Routing Link Code");
        PlanningComponent.Validate("Scrap %", 0);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Planning Line Management", 'OnCalculateComponentsOnbeforePlanningComponentModify', '', true, true)]
    local procedure OnCalculateComponentsOnbeforePlanningComponentModify(var PlanningComponent: Record "Planning Component")
    begin
        PlanningComponent.Validate("Routing Link Code");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Planning Line Management", 'OnCheckMultiLevelStructureOnBeforeReqLineModify', '', true, true)]
    local procedure OnCheckMultiLevelStructureOnBeforeReqLineModify(var RequisitionLine: Record "Requisition Line")
    begin
        RequisitionLine.Validate("Production BOM No.");
        RequisitionLine.Validate("Routing No.");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Planning Line Management", 'OnTransferAsmBOMOnBeforePlanningComponentModify', '', true, true)]
    local procedure OnTransferAsmBOMOnBeforePlanningComponentModify(var PlanningComponent: Record "Planning Component")
    begin
        PlanningComponent.Validate("Routing Link Code", '');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsPlannedCompFound(var PlanningComp: Record "Planning Component"; var ProdBOMLine: Record "Production BOM Line"; var IsFound: Boolean; var SKU: Record "Stockkeeping Unit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetPlanningLevelCode(var PlanningComponent: Record "Planning Component"; var ProdBOMLine: Record "Production BOM Line"; var SKU: Record "Stockkeeping Unit"; var ComponentSKU: Record "Stockkeeping Unit"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferRouting(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferRoutingLine(var PlanningRoutingLine: Record "Planning Routing Line"; RequisitionLine: Record "Requisition Line"; RoutingLine: Record "Routing Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferBOMOnBeforePlanningRtngLineFind(var PlanningRoutingLine: Record "Planning Routing Line"; ProductionBOMLine: Record "Production BOM Line"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferRoutingLineOnBeforeCalcRoutingCostPerUnit(var PlanningRoutingLine: Record "Planning Routing Line"; ReqLine: Record "Requisition Line"; RoutingLine: Record "Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferRoutingLineOnBeforeValidateDirectUnitCost(var ReqLine: Record "Requisition Line"; var RoutingLine: Record "Routing Line"; var PlanningRoutingLine: Record "Planning Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferRtngLine(var ReqLine: Record "Requisition Line"; var RoutingLine: Record "Routing Line"; var PlanningRoutingLine: Record "Planning Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferBOM(ProdBOMNo: Code[20]; Level: Integer; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal; var RequisitionLine: Record "Requisition Line"; Blocked: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferBOMOnBeforeGetDefaultBin(var PlanningComponent: Record "Planning Component"; var ProductionBOMLine: Record "Production BOM Line"; RequisitionLine: Record "Requisition Line"; var StockkeepingUnit: Record "Stockkeeping Unit")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferBOMOnAfterProdBOMLineSetFilters(var ProdBOMLine: Record "Production BOM Line"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferBOMOnBeforeTransferPlanningComponent(var RequisitionLine: Record "Requisition Line"; var ProductionBOMLine: Record "Production BOM Line"; Blocked: Boolean; var IsHandled: Boolean; Level: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferBOMOnBeforeTransferProductionBOM(var ReqQty: Decimal; ProductionBOMLine: Record "Production BOM Line"; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferBOMOnBeforeUpdatePlanningComp(var ProductionBOMLine: Record "Production BOM Line"; var UpdateCondition: Boolean; var IsHandled: Boolean; var ReqQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferBOMOnAfterCalculateReqQty(var ReqQty: Decimal; ProductionBOMLine: Record "Production BOM Line"; PlanningRoutingLine: Record "Planning Routing Line"; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferRouting(var RequisitionLine: Record "Requisition Line"; PlanningResilency: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyPlanningComponent(var ReqLine: Record "Requisition Line"; var ProductionBOMLine: Record "Production BOM Line"; var PlanningComponent: Record "Planning Component"; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferBOM(RequisitionLine: Record "Requisition Line"; ProdBOMNo: Code[20]; Level: Integer; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPlanningComponent(var ReqLine: Record "Requisition Line"; var ProductionBOMLine: Record "Production BOM Line"; var PlanningComponent: Record "Planning Component"; LineQtyPerUOM: Decimal; ItemQtyPerUOM: Decimal)
    begin
    end;
}