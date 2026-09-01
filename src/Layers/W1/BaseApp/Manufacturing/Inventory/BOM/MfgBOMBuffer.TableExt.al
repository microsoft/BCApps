// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.BOM;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.WorkCenter;

tableextension 99000820 "Mfg. BOM Buffer" extends "BOM Buffer"
{
    fields
    {
        modify("No.")
        {
            TableRelation =
            if (Type = const("Machine Center")) "Machine Center"
            else
            if (Type = const("Work Center")) "Work Center";
        }
        field(15; "Routing No."; Code[20])
        {
            Caption = 'Routing No.';
            DataClassification = SystemMetadata;
            TableRelation = "Routing Header";
        }
        field(16; "Production BOM No."; Code[20])
        {
            Caption = 'Production BOM No.';
            DataClassification = SystemMetadata;
            TableRelation = "Production BOM Header";
        }
    }

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text003: Label 'Routing %1 has not been certified.';
        Text004: Label 'Production BOM %1 has not been certified.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure TransferFromProdComp(var EntryNo: Integer; ProdBOMLine: Record "Production BOM Line"; NewIndentation: Integer; ParentQtyPer: Decimal; ParentScrapQtyPer: Decimal; ParentScrapPct: Decimal; NeedByDate: Date; ParentLocationCode: Code[10]; ParentItem: Record Item; BOMQtyPerUOM: Decimal)
    var
        BOMItem: Record Item;
        OriginalItem: Record Item;
        MfgCostCalcMgt: Codeunit "Mfg. Cost Calculation Mgt.";
        UOMMgt: Codeunit "Unit of Measure Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferFromProdComp(EntryNo, ProdBOMLine, NewIndentation, ParentQtyPer, ParentScrapQtyPer, ParentScrapPct, NeedByDate, ParentLocationCode, ParentItem, BOMQtyPerUOM, IsHandled);
        if not IsHandled then begin
            Init();
            EntryNo += 1;
            "Entry No." := EntryNo;
            Type := Type::Item;

            OriginalItem.Get(ParentItem."No."); // to assign "Routing No." 

            BOMItem.Get(ProdBOMLine."No.");
            InitFromItem(BOMItem);

            if ParentItem."Lot Size" = 0 then
                ParentItem."Lot Size" := 1;

            Description := ProdBOMLine.Description;
            "Qty. per Parent" :=
              MfgCostCalcMgt.CalcCompItemQtyBase(
                ProdBOMLine, WorkDate(),
                MfgCostCalcMgt.CalcQtyAdjdForBOMScrap(ParentItem."Lot Size", ParentScrapPct), OriginalItem."Routing No.", true) /
              UOMMgt.GetQtyPerUnitOfMeasure(BOMItem, ProdBOMLine."Unit of Measure Code") /
              BOMQtyPerUOM / ParentItem."Lot Size";
            "Qty. per Top Item" := Round(ParentQtyPer * "Qty. per Parent", UOMMgt.QtyRndPrecision());
            "Qty. per Parent" := Round("Qty. per Parent", UOMMgt.QtyRndPrecision());

            "Scrap Qty. per Parent" := "Qty. per Parent" - (ProdBOMLine.Quantity / BOMQtyPerUOM);
            "Scrap Qty. per Top Item" :=
              "Qty. per Top Item" -
              Round((ParentQtyPer - ParentScrapQtyPer) * ("Qty. per Parent" - "Scrap Qty. per Parent"), UOMMgt.QtyRndPrecision());
            "Scrap Qty. per Parent" := Round("Scrap Qty. per Parent", UOMMgt.QtyRndPrecision());

            "Qty. per BOM Line" := ProdBOMLine."Quantity per";
            "Unit of Measure Code" := ProdBOMLine."Unit of Measure Code";
            "Variant Code" := ProdBOMLine."Variant Code";
            "Location Code" := ParentLocationCode;
            "Lead-Time Offset" := ProdBOMLine."Lead-Time Offset";
            "Needed by Date" := NeedByDate;
            Indentation := NewIndentation;
            if ProdBOMLine."Calculation Formula" = ProdBOMLine."Calculation Formula"::"Fixed Quantity" then
                "Calculation Formula" := ProdBOMLine."Calculation Formula";

            OnTransferFromProdCompCopyFields(Rec, ProdBOMLine, ParentItem, ParentQtyPer, ParentScrapQtyPer);
            Insert(true);
        end;
        OnAfterTransferFromProdComp(Rec, ProdBOMLine, ParentItem, EntryNo)
    end;

    procedure TransferFromProdOrderLine(var EntryNo: Integer; ProdOrderLine: Record "Prod. Order Line")
    var
        BOMItem: Record Item;
    begin
        Init();
        EntryNo += 1;
        "Entry No." := EntryNo;
        Type := Type::Item;

        BOMItem.Get(ProdOrderLine."Item No.");
        InitFromItem(BOMItem);

        "Scrap %" := ProdOrderLine."Scrap %";
        "Production BOM No." := ProdOrderLine."Production BOM No.";
        "Qty. per Parent" := 1;
        "Qty. per Top Item" := 1;
        "Unit of Measure Code" := ProdOrderLine."Unit of Measure Code";
        "Variant Code" := ProdOrderLine."Variant Code";
        "Location Code" := ProdOrderLine."Location Code";
        "Needed by Date" := ProdOrderLine."Due Date";
        Indentation := 0;

        OnTransferFromProdOrderLineCopyFields(Rec, ProdOrderLine);
        Insert(true);
    end;

    procedure TransferFromProdOrderComp(var EntryNo: Integer; ProdOrderComp: Record "Prod. Order Component")
    var
        BOMItem: Record Item;
    begin
        Init();
        EntryNo += 1;
        "Entry No." := EntryNo;
        Type := Type::Item;

        BOMItem.Get(ProdOrderComp."Item No.");
        InitFromItem(BOMItem);

        "Qty. per Parent" := ProdOrderComp."Quantity per";
        "Qty. per Top Item" := ProdOrderComp."Quantity per";
        "Unit of Measure Code" := ProdOrderComp."Unit of Measure Code";
        "Variant Code" := ProdOrderComp."Variant Code";
        "Location Code" := ProdOrderComp."Location Code";
        "Needed by Date" := ProdOrderComp."Due Date";
        "Lead-Time Offset" := ProdOrderComp."Lead-Time Offset";
        Indentation := 1;

        OnTransferFromProdOrderCompCopyFields(Rec, ProdOrderComp);
        Insert(true);
    end;

    procedure TransferFromProdRouting(var EntryNo: Integer; RoutingLine: Record "Routing Line"; NewIndentation: Integer; ParentQtyPer: Decimal; NeedByDate: Date; ParentLocationCode: Code[10])
    var
        MachineCenter: Record "Machine Center";
        WorkCenter: Record "Work Center";
        RunTimeQty: Decimal;
        SetupWaitMoveTimeQty: Decimal;
    begin
        Init();
        EntryNo += 1;
        "Entry No." := EntryNo;

        case RoutingLine.Type of
            RoutingLine.Type::"Machine Center":
                begin
                    MachineCenter.Get(RoutingLine."No.");
                    InitFromMachineCenter(MachineCenter);
                end;
            RoutingLine.Type::"Work Center":
                begin
                    WorkCenter.Get(RoutingLine."No.");
                    InitFromWorkCenter(WorkCenter);
                end;
        end;

        Description := RoutingLine.Description;
        CalcQtyPerParentFromProdRouting(RoutingLine, RunTimeQty, SetupWaitMoveTimeQty);
        "Qty. per Parent" := SetupWaitMoveTimeQty + RunTimeQty;
        "Qty. per Top Item" := SetupWaitMoveTimeQty + RunTimeQty * ParentQtyPer;
        "Location Code" := ParentLocationCode;
        "Needed by Date" := NeedByDate;
        Indentation := NewIndentation;

        OnTransferFromProdRoutingCopyFields(Rec, RoutingLine);
        Insert(true);
    end;

    procedure InitFromMachineCenter(MachineCenter: Record "Machine Center")
    var
        WorkCenter: Record "Work Center";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitFromMachineCenter(Rec, MachineCenter, IsHandled);
        if IsHandled then
            exit;

        Type := Type::"Machine Center";
        "No." := MachineCenter."No.";
        Description := MachineCenter.Name;
        if MachineCenter."Work Center No." <> '' then begin
            WorkCenter.Get(MachineCenter."Work Center No.");
            "Unit of Measure Code" := WorkCenter."Unit of Measure Code";
        end;

        "Replenishment System" := "Replenishment System"::Transfer;
        "Is Leaf" := true;

        OnAfterInitFromMachineCenter(Rec, MachineCenter);
    end;

    procedure InitFromWorkCenter(WorkCenter: Record "Work Center")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInitFromWorkCenter(Rec, WorkCenter, IsHandled);
        if IsHandled then
            exit;

        Type := Type::"Work Center";
        "No." := WorkCenter."No.";
        Description := WorkCenter.Name;
        "Unit of Measure Code" := WorkCenter."Unit of Measure Code";

        "Replenishment System" := "Replenishment System"::Transfer;
        "Is Leaf" := true;

        OnAfterInitFromWorkCenter(Rec, WorkCenter);
    end;

    local procedure CalcQtyPerParentFromProdRouting(RoutingLine: Record "Routing Line"; var RunTimeQty: Decimal; var SetupWaitMoveTimeQty: Decimal)
    var
        WorkCenter: Record "Work Center";
        CalendarMgt: Codeunit "Shop Calendar Management";
        SetupTimeFactor: Decimal;
        RunTimeFactor: Decimal;
        WaitTimeFactor: Decimal;
        MoveTimeFactor: Decimal;
        CurrentTimeFactor: Decimal;
        LotSizeFactor: Decimal;
    begin
        SetupTimeFactor := CalendarMgt.TimeFactor(RoutingLine."Setup Time Unit of Meas. Code");
        RunTimeFactor := CalendarMgt.TimeFactor(RoutingLine."Run Time Unit of Meas. Code");
        WaitTimeFactor := CalendarMgt.TimeFactor(RoutingLine."Wait Time Unit of Meas. Code");
        MoveTimeFactor := CalendarMgt.TimeFactor(RoutingLine."Move Time Unit of Meas. Code");

        if RoutingLine."Lot Size" = 0 then
            LotSizeFactor := 1
        else
            LotSizeFactor := RoutingLine."Lot Size";

        RunTimeQty := RoutingLine."Run Time" * RunTimeFactor / LotSizeFactor;
        SetupWaitMoveTimeQty :=
          (RoutingLine."Setup Time" * SetupTimeFactor + RoutingLine."Wait Time" * WaitTimeFactor +
          RoutingLine."Move Time" * MoveTimeFactor) / LotSizeFactor;

        if "Unit of Measure Code" = '' then begin
            // select base UOM from Setup/Run/Wait/Move UOMs
            CurrentTimeFactor := SetupTimeFactor;
            "Unit of Measure Code" := RoutingLine."Setup Time Unit of Meas. Code";
            if CurrentTimeFactor > RunTimeFactor then begin
                CurrentTimeFactor := RunTimeFactor;
                "Unit of Measure Code" := RoutingLine."Run Time Unit of Meas. Code";
            end;
            if CurrentTimeFactor > WaitTimeFactor then begin
                CurrentTimeFactor := WaitTimeFactor;
                "Unit of Measure Code" := RoutingLine."Wait Time Unit of Meas. Code";
            end;
            if CurrentTimeFactor > MoveTimeFactor then begin
                CurrentTimeFactor := MoveTimeFactor;
                "Unit of Measure Code" := RoutingLine."Move Time Unit of Meas. Code";
            end;
        end;

        if not WorkCenter.Get(RoutingLine."Work Center No.") then
            WorkCenter.Init();

        RunTimeQty :=
          Round(RunTimeQty / CalendarMgt.TimeFactor("Unit of Measure Code"), WorkCenter."Calendar Rounding Precision");
        SetupWaitMoveTimeQty :=
          Round(SetupWaitMoveTimeQty / CalendarMgt.TimeFactor("Unit of Measure Code"), WorkCenter."Calendar Rounding Precision");
    end;

    procedure IsProdBOMOk(LogWarning: Boolean; var BOMWarningLog: Record "BOM Warning Log"): Boolean
    var
        ProdBOMHeader: Record "Production BOM Header";
    begin
        if "Production BOM No." = '' then
            exit(true);
        ProdBOMHeader.Get("Production BOM No.");
        if ProdBOMHeader.Status = ProdBOMHeader.Status::Certified then
            exit(true);

        if LogWarning then
            BOMWarningLog.SetWarning(
                StrSubstNo(Text004, ProdBOMHeader."No."), DATABASE::"Production BOM Header", CopyStr(ProdBOMHeader.GetPosition(), 1, 250));
    end;

    procedure IsRoutingOk(LogWarning: Boolean; var BOMWarningLog: Record "BOM Warning Log"): Boolean
    var
        RoutingHeader: Record "Routing Header";
    begin
        if "Routing No." = '' then
            exit(true);
        RoutingHeader.Get("Routing No.");
        if RoutingHeader.Status = RoutingHeader.Status::Certified then
            exit(true);

        if LogWarning then
            BOMWarningLog.SetWarning(
                StrSubstNo(Text003, RoutingHeader."No."), DATABASE::"Routing Header", CopyStr(RoutingHeader.GetPosition(), 1, 250));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromMachineCenter(var BOMBuffer: Record "BOM Buffer"; MachineCenter: Record "Machine Center");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromWorkCenter(var BOMBuffer: Record "BOM Buffer"; WorkCenter: Record "Work Center");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromProdComp(var BOMBuffer: Record "BOM Buffer"; ProductionBOMLine: Record "Production BOM Line"; ParentItem: Record Item; var EntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitFromMachineCenter(var BOMBuffer: Record "BOM Buffer"; MachineCenter: Record "Machine Center"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnbeforeInitFromWorkCenter(var BOMBuffer: Record "BOM Buffer"; WorkCenter: Record "Work Center"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferFromProdComp(var EntryNo: Integer; ProductionBOMLine: Record "Production BOM Line"; NewIndentation: Integer; ParentQtyPer: Decimal; ParentScrapQtyPer: Decimal; ParentScrapPct: Decimal; NeedByDate: Date; ParentLocationCode: Code[10]; ParentItem: Record Item; BOMQtyPerUOM: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferFromProdCompCopyFields(var BOMBuffer: Record "BOM Buffer"; ProductionBOMLine: Record "Production BOM Line"; ParentItem: Record Item; ParentQtyPer: Decimal; ParentScrapQtyPer: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferFromProdOrderLineCopyFields(var BOMBuffer: Record "BOM Buffer"; ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferFromProdOrderCompCopyFields(var BOMBuffer: Record "BOM Buffer"; ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferFromProdRoutingCopyFields(var BOMBuffer: Record "BOM Buffer"; RoutingLine: Record "Routing Line")
    begin
    end;

}
