// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Warehouse.Availability;

codeunit 99000873 "Mfg. Create Pick"
{
    var
        FeatureTelemetry: Codeunit System.Telemetry."Feature Telemetry";
        ProdAsmJobWhseHandlingTelemetryCategoryTok: Label 'Prod/Asm/Project Whse. Handling', Locked = true;
        ProdAsmJobWhseHandlingTelemetryTok: Label 'Prod/Asm/Project Whse. Handling in used for warehouse pick.', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Pick", 'OnAfterCheckOutBound', '', false, false)]
    local procedure OnAfterCheckOutBound(SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; var OutBoundQty: Decimal; SourceSubLineNo: Integer)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        case SourceType of
            Database::"Prod. Order Component":
                begin
                    ProdOrderComponent.SetRange(Status, SourceSubType);
                    ProdOrderComponent.SetRange("Prod. Order No.", SourceNo);
                    ProdOrderComponent.SetRange("Prod. Order Line No.", SourceSubLineNo);
                    ProdOrderComponent.SetRange("Line No.", SourceLineNo);
                    ProdOrderComponent.SetAutoCalcFields("Pick Qty. (Base)");
                    ProdOrderComponent.SetLoadFields("Pick Qty. (Base)", "Qty. Picked (Base)");
                    if ProdOrderComponent.FindFirst() then
                        OutBoundQty := ProdOrderComponent."Pick Qty. (Base)" + ProdOrderComponent."Qty. Picked (Base)"
                    else
                        OutBoundQty := 0;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Pick", 'OnCalcAvailableQtyOnGetLineReservedQty', '', false, false)]
    local procedure OnCalcAvailableQtyOnGetLineReservedQty(WhseSource2: Option; CurrSourceSubType: Integer; CurrSourceNo: Code[20]; CurrSourceLineNo: Integer; CurrSourceSubLineNo: Integer; var LineReservedQty: Decimal; var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary);
    var
        CreatePickParameters: Record "Create Pick Parameters";
        WarehouseAvailabilityMgt: Codeunit "Warehouse Availability Mgt.";
    begin
        case WhseSource2 of
            CreatePickParameters."Whse. Document"::Production:
                LineReservedQty :=
                  WarehouseAvailabilityMgt.CalcLineReservedQtyOnInvt(
                    Database::"Prod. Order Component", CurrSourceSubType, CurrSourceNo, CurrSourceLineNo, CurrSourceSubLineNo, true, TempWarehouseActivityLine);
        end;
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Pick", 'OnFindToBinCodeForCustomWhseSource', '', false, false)]
    local procedure OnFindToBinCodeForCustomWhseSource(WhseSource2: Option; CurrSourceType: Integer; CurrSourceSubType: Integer; CurrSourceNo: Code[20]; CurrSourceLineNo: Integer; CurrSourceSubLineNo: Integer; var ToBinCode: Code[20])
    var
        CreatePickParameters: Record "Create Pick Parameters";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        case WhseSource2 of
            CreatePickParameters."Whse. Document"::Production:
                begin
                    ProdOrderComponent.Get(CurrSourceSubType, CurrSourceNo, CurrSourceLineNo, CurrSourceSubLineNo);
                    ToBinCode := ProdOrderComponent."Bin Code";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Pick", 'OnRunFindBWPickBinLoopOnAfterCheckWhseHandling', '', false, false)]
    local procedure OnRunFindBWPickBinLoopOnAfterCheckWhseHandling(CurrSourceType: Integer; CurrLocation: Record Location; var ShouldExit: Boolean)
    begin
        if (CurrSourceType = Database::"Prod. Order Component") and (CurrLocation.Code <> '') then begin
            FeatureTelemetry.LogUsage('0000KT5', ProdAsmJobWhseHandlingTelemetryCategoryTok, ProdAsmJobWhseHandlingTelemetryTok);
            if not (CurrLocation."Prod. Consump. Whse. Handling" in [CurrLocation."Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)", CurrLocation."Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)"]) then
                exit;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Pick", 'OnCalcMaxQtyForCustomWhseSource', '', false, false)]
    local procedure OnCalcMaxQtyForCustomWhseSource(CustomWhseSourceLine: Variant; var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; var QtytoHandle: Decimal; var QtytoHandleBase: Decimal; BreakBulkNo: Integer; ShouldCalcMaxQty: Boolean; WhseSource2: Option; sender: Codeunit "Create Pick")
    var
        CreatePickParameters: Record "Create Pick Parameters";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        case WhseSource2 of
            CreatePickParameters."Whse. Document"::Production:
                begin
                    ProdOrderComponent := CustomWhseSourceLine;
                    if (TempWarehouseActivityLine."Action Type" <> TempWarehouseActivityLine."Action Type"::Take) or (ProdOrderComponent."Unit of Measure Code" = TempWarehouseActivityLine."Unit of Measure Code") then begin
                        ProdOrderComponent.CalcFields("Pick Qty.", "Pick Qty. (Base)");
                        sender.CalcMaxQty(
                            QtytoHandle,
                            ProdOrderComponent."Expected Quantity" -
                            ProdOrderComponent."Qty. Picked" -
                            ProdOrderComponent."Pick Qty.",
                            QtyToHandleBase,
                            ProdOrderComponent."Expected Qty. (Base)" -
                            ProdOrderComponent."Qty. Picked (Base)" -
                            ProdOrderComponent."Pick Qty. (Base)",
                            TempWarehouseActivityLine."Action Type");
                    end;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Pick", 'OnAfterSetFiltersOnReservEntry', '', false, false)]
    local procedure OnAfterSetFiltersOnReservEntry(var ReservationEntry: Record "Reservation Entry"; SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer)
    begin
        case SourceType of
            Database::Microsoft.Manufacturing.Document."Prod. Order Component":
                begin
                    ReservationEntry.SetRange("Source Type", SourceType);
                    ReservationEntry.SetRange("Source Subtype", SourceSubType);
                    ReservationEntry.SetRange("Source Ref. No.", SourceSubLineNo);
                    ReservationEntry.SetRange("Source Prod. Order Line", SourceLineNo);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Pick", 'OnCreateTempActivityLineForCustomWhseSource', '', false, false)]
    local procedure OnCreateTempActivityLineForCustomWhseSource(CustomWhseSourceLine: Variant; var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; var CreatePickParameters: Record "Create Pick Parameters" temporary)
    var
        ProdOrderWarehouseMgt: Codeunit "Prod. Order Warehouse Mgt.";
    begin
        case CreatePickParameters."Whse. Document" of
            CreatePickParameters."Whse. Document"::Production:
                ProdOrderWarehouseMgt.TransferFromCompLine(TempWarehouseActivityLine, CustomWhseSourceLine);
        end;
    end;
}
