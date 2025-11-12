// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using System.Utilities;

codeunit 5531 "Calc. Inventory Page Data"
{

    trigger OnRun()
    begin
    end;

    var
        TempInvtEventBuf: Record "Inventory Event Buffer" temporary;
        CalcItemAvailability: Codeunit "Calc. Item Availability";
        RecRef: RecordRef;
        PageLineNo: Integer;
        UnsupportedEntitySourceErr: Label 'Unsupported Entity Source Type = %1, Source Subtype = %2.', Comment = '%1 = source type, %2 = source subtype';
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text0032: Label 'Current Qty. on Hand';
        Text5407: Label 'Component %1';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure Initialize(var Item: Record Item; ForecastName: Code[10]; IncludeBlanketOrders: Boolean; ExcludeForecastBefore: Date; IncludePlan: Boolean)
    begin
        OnBeforeInitialize(Item, ForecastName, IncludeBlanketOrders, ExcludeForecastBefore, IncludePlan);

        TempInvtEventBuf.Reset();
        TempInvtEventBuf.DeleteAll();

        CalcItemAvailability.CalcNewInvtEventBuf(Item, ForecastName, IncludeBlanketOrders, ExcludeForecastBefore, IncludePlan);
        CalcItemAvailability.GetInvEventBuffer(TempInvtEventBuf);

        OnAfterInitialize(Item, ForecastName, IncludeBlanketOrders, ExcludeForecastBefore, IncludePlan);
    end;

    procedure CreatePeriodEntries(var InvtPageData: Record "Inventory Page Data"; PeriodType: Option Day,Week,Month,Quarter,Year)
    var
        Date: Record Date;
        LastDateInPeriod: Date;
    begin
        TempInvtEventBuf.Reset();
        TempInvtEventBuf.SetCurrentKey("Availability Date", Type);
        if TempInvtEventBuf.Find('-') then
            repeat
                if TempInvtEventBuf.Type = TempInvtEventBuf.Type::Inventory then begin
                    InvtPageData.Init();
                    InvtPageData.Code := '';
                    InvtPageData."Line No." := NextPageLineNo();
                    InvtPageData."Period Type" := Date."Period Type";
                    InvtPageData."Period Start" := TempInvtEventBuf."Availability Date";
                    InvtPageData.Description := Format(TempInvtEventBuf.Type);
                    InvtPageData.Level := 0;
                    OnCreatePeriodEntriesOnBeforeInvtPageDataInsert(InvtPageData, TempInvtEventBuf);
                    InvtPageData.Insert();
                    LastDateInPeriod := TempInvtEventBuf."Availability Date";
                end else begin
                    Date.SetRange("Period Type", PeriodType);
                    Date.SetFilter("Period Start", '<=%1', TempInvtEventBuf."Availability Date");
                    if Date.FindLast() then begin
                        InvtPageData.Init();
                        InvtPageData.Code := Format(Date."Period Start");
                        InvtPageData."Line No." := NextPageLineNo();
                        InvtPageData."Period Type" := Date."Period Type";
                        InvtPageData."Period Start" := Date."Period Start";
                        InvtPageData."Period End" := Date."Period End";
                        InvtPageData.Description := FormatPeriodDescription(Date);
                        InvtPageData.Level := 0;
                        InvtPageData.Insert();
                        LastDateInPeriod := Date."Period End";
                    end;
                end;
                TempInvtEventBuf.SetFilter("Availability Date", '<=%1', LastDateInPeriod);
                TempInvtEventBuf.Find('+');
                TempInvtEventBuf.SetRange("Availability Date");
            until TempInvtEventBuf.Next() = 0;
        TempInvtEventBuf.Reset();
    end;

    procedure DetailsForPeriodEntry(var InvtPageData: Record "Inventory Page Data"; Positive: Boolean)
    var
        PeriodInvtPageData: Record "Inventory Page Data";
        IsHandled: Boolean;
    begin
        PeriodInvtPageData.Copy(InvtPageData);
        TempInvtEventBuf.Reset();
        TempInvtEventBuf.SetCurrentKey("Availability Date", Type);
        TempInvtEventBuf.SetRange("Availability Date", InvtPageData."Period Start", InvtPageData."Period End");
        TempInvtEventBuf.SetRange(Positive, Positive);
        if TempInvtEventBuf.Find('-') then
            repeat
                TransferToPeriodDetails(InvtPageData, TempInvtEventBuf);
                UpdateInventory(InvtPageData, TempInvtEventBuf);
                InvtPageData."Line No." := NextPageLineNo();
                IsHandled := false;
                OnDetailsForPeriodEntryOnBeforeInvtPageDataInsert(InvtPageData, IsHandled);
                if not IsHandled then
                    InvtPageData.Insert();
                UpdatePeriodTotals(PeriodInvtPageData, InvtPageData);
                UpdateInventory(PeriodInvtPageData, TempInvtEventBuf);
            until TempInvtEventBuf.Next() = 0;
        InvtPageData.Copy(PeriodInvtPageData);

        OnDetailsForPeriodEntryOnBeforeInvtPageDataModify(InvtPageData);
        InvtPageData.Modify();
    end;

    local procedure TransferToPeriodDetails(var InventoryPageData: Record "Inventory Page Data"; var FromInvtEventBuf: Record "Inventory Event Buffer")
    var
        SourceType: Integer;
        SourceSubtype: Integer;
        SourceID: Code[20];
        SourceBatchName: Code[10];
        SourceProdOrderLine: Integer;
        SourceRefNo: Integer;
        IsHandled: Boolean;
    begin
        InventoryPageData.Init();

        InventoryPageData.Code := Format(FromInvtEventBuf."Availability Date");
        InventoryPageData."Period Start" := FromInvtEventBuf."Availability Date";
        InventoryPageData."Availability Date" := FromInvtEventBuf."Availability Date";
        InventoryPageData.Level := 1;
        InventoryPageData."Source Line ID" := FromInvtEventBuf."Source Line ID";
        InventoryPageData."Item No." := FromInvtEventBuf."Item No.";
        InventoryPageData."Variant Code" := FromInvtEventBuf."Variant Code";
        InventoryPageData."Location Code" := FromInvtEventBuf."Location Code";
        InventoryPageData."Remaining Quantity (Base)" := FromInvtEventBuf."Remaining Quantity (Base)";
        InventoryPageData.Positive := FromInvtEventBuf.Positive;
        CalcItemAvailability.GetSourceReferences(
            FromInvtEventBuf."Source Line ID", FromInvtEventBuf."Transfer Direction",
            SourceType, SourceSubtype, SourceID, SourceBatchName, SourceProdOrderLine, SourceRefNo);
        case SourceType of
            DATABASE::"Item Ledger Entry":
                TransferInventory(FromInvtEventBuf, InventoryPageData);
            DATABASE::"Requisition Line":
                TransferReqLine(FromInvtEventBuf, InventoryPageData, SourceID, SourceBatchName, SourceRefNo);
            DATABASE::"Planning Component":
                TransferPlanningComp(FromInvtEventBuf, InventoryPageData, SourceID, SourceBatchName, SourceProdOrderLine);
            else begin
                OnTransferToPeriodDetailsElseCase(InventoryPageData, FromInvtEventBuf, IsHandled, SourceType, SourceSubtype, SourceID, SourceRefNo);
                if not IsHandled then
                    Error(UnsupportedEntitySourceErr, SourceType, SourceSubtype);
            end;
        end;
        OnAfterTransferToPeriodDetails(InventoryPageData, FromInvtEventBuf, SourceType, SourceSubtype);
    end;

    local procedure TransferInventory(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data")
    begin
        InventoryPageData.Type := InventoryPageData.Type::" ";
        InventoryPageData.Description := Text0032;
        InventoryPageData.Source := InventoryEventBuffer."Location Code" + ' ' + InventoryEventBuffer."Variant Code";
        InventoryPageData."Scheduled Receipt" := InventoryEventBuffer."Remaining Quantity (Base)";
        InventoryPageData."Reserved Receipt" := InventoryEventBuffer."Reserved Quantity (Base)";
    end;

    local procedure TransferReqLine(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceID: Code[20]; SourceBatchName: Code[10]; SourceRefNo: Integer)
    var
        ReqLine: Record "Requisition Line";
    begin
        ReqLine.Get(SourceID, SourceBatchName, SourceRefNo);
        RecRef.GetTable(ReqLine);
        InventoryPageData."Source Document ID" := RecRef.RecordId;
        InventoryPageData."Document No." := ReqLine."Ref. Order No.";
        InventoryPageData.Type := InventoryPageData.Type::Plan;
        InventoryPageData.Source := Format(InventoryEventBuffer."Ref. Order Type") + ' ' + Format(InventoryEventBuffer."Action Message");
        InventoryPageData.Description := ReqLine.Description;
        InventoryPageData."Action Message Qty." := InventoryEventBuffer."Remaining Quantity (Base)";
        InventoryPageData."Action Message" := InventoryEventBuffer."Action Message";
    end;

    local procedure TransferPlanningComp(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceID: Code[20]; SourceBatchName: Code[10]; SourceProdOrderLine: Integer)
    var
        ReqLine: Record "Requisition Line";
    begin
        ReqLine.Get(SourceID, SourceBatchName, SourceProdOrderLine);
        RecRef.GetTable(ReqLine);
        InventoryPageData."Source Document ID" := InventoryEventBuffer."Source Line ID";
        InventoryPageData."Document No." := ReqLine."Ref. Order No.";
        InventoryPageData.Type := InventoryPageData.Type::Plan;
        InventoryPageData.Description := ReqLine.Description;
        InventoryPageData.Source := StrSubstNo(Text5407, Format(InventoryEventBuffer."Action Message"));
        InventoryPageData."Action Message Qty." := InventoryEventBuffer."Remaining Quantity (Base)";
        InventoryPageData."Action Message" := InventoryEventBuffer."Action Message";
        OnAfterTransferPlanningComp(InventoryPageData, ReqLine);
    end;

    local procedure UpdatePeriodTotals(var PeriodInvtPageData: Record "Inventory Page Data"; var DetailInvtPageData: Record "Inventory Page Data")
    begin
        PeriodInvtPageData."Remaining Quantity (Base)" += DetailInvtPageData."Remaining Quantity (Base)";
        PeriodInvtPageData."Gross Requirement" += DetailInvtPageData."Gross Requirement";
        PeriodInvtPageData."Reserved Requirement" += DetailInvtPageData."Reserved Requirement";
        PeriodInvtPageData."Scheduled Receipt" += DetailInvtPageData."Scheduled Receipt";
        PeriodInvtPageData."Reserved Receipt" += DetailInvtPageData."Reserved Receipt";
        PeriodInvtPageData.Forecast += DetailInvtPageData.Forecast;
        PeriodInvtPageData."Remaining Forecast" += DetailInvtPageData."Remaining Forecast";
        PeriodInvtPageData."Action Message Qty." += DetailInvtPageData."Action Message Qty.";

        OnAfterUpdatePeriodTotals(PeriodInvtPageData, DetailInvtPageData);
    end;

    local procedure UpdateInventory(var InvtPageData: Record "Inventory Page Data"; var InvtEventBuf: Record "Inventory Event Buffer")
    begin
        if InvtEventBuf."Action Message" <> InvtEventBuf."Action Message"::" " then
            InvtPageData."Suggested Projected Inventory" += InvtEventBuf."Remaining Quantity (Base)"
        else
            if InvtEventBuf.Type = InvtEventBuf.Type::Forecast then
                InvtPageData."Forecasted Projected Inventory" += InvtEventBuf."Remaining Quantity (Base)"
            else
                InvtPageData."Projected Inventory" += InvtEventBuf."Remaining Quantity (Base)";

        OnAfterUpdateInventory(InvtPageData, InvtEventBuf);
    end;

    local procedure NextPageLineNo(): Integer
    begin
        PageLineNo += 1;
        exit(PageLineNo);
    end;

    procedure ShowDocument(RecID: RecordID)
    begin
        CalcItemAvailability.ShowDocument(RecID);
    end;

    local procedure FormatPeriodDescription(Date: Record Date) PeriodDescription: Text[50]
    begin
        case Date."Period Type" of
            Date."Period Type"::Week,
          Date."Period Type"::Quarter,
          Date."Period Type"::Year:
                PeriodDescription := StrSubstNo('%1 %2', Format(Date."Period Type"), Date."Period Name");
            else
                PeriodDescription := Date."Period Name";
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitialize(var Item: Record Item; var ForecastName: Code[10]; var IncludeBlanketOrders: Boolean; var ExcludeForecastBefore: Date; var IncludePlan: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferToPeriodDetails(var InventoryPageData: Record "Inventory Page Data"; var InventoryEventBuffer: Record "Inventory Event Buffer"; SourceType: Integer; SourceSubtype: Integer)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnAfterTransferTransLine(var InventoryPageData: Record "Inventory Page Data"; var TransferHeader: Record Microsoft.Inventory.Transfer."Transfer Header")
    begin
        OnAfterTransferTransLine(InventoryPageData, TransferHeader);
    end;

    [Obsolete('Replaced by same event in codeunit TransferAvailabilityMgt', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferTransLine(var InventoryPageData: Record "Inventory Page Data"; var TransferHeader: Record Microsoft.Inventory.Transfer."Transfer Header")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnAfterTransferProdOrderComp(var InventoryPageData: Record "Inventory Page Data"; var ProductionOrder: Record Microsoft.Manufacturing.Document."Production Order")
    begin
        OnAfterTransferProdOrderComp(InventoryPageData, ProductionOrder);
    end;

    [Obsolete('Replaced by same event in codeunit ProdOrderAvailabilityMgt', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferProdOrderComp(var InventoryPageData: Record "Inventory Page Data"; var ProductionOrder: Record Microsoft.Manufacturing.Document."Production Order")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferPlanningComp(var InventoryPageData: Record "Inventory Page Data"; var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateInventory(var InvtPageData: Record "Inventory Page Data"; var InvtEventBuf: Record "Inventory Event Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdatePeriodTotals(var PeriodInvtPageData: Record "Inventory Page Data"; DetailInvtPageData: Record "Inventory Page Data")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDetailsForPeriodEntryOnBeforeInvtPageDataInsert(var InventoryPageData: Record "Inventory Page Data"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDetailsForPeriodEntryOnBeforeInvtPageDataModify(var InventoryPageData: Record "Inventory Page Data")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferToPeriodDetailsElseCase(var InventoryPageData: Record "Inventory Page Data"; InventoryEventBuffer: Record "Inventory Event Buffer"; var IsHandled: Boolean; SourceType: Integer; SourceSubType: Integer; SourceID: Code[20]; SourceRefNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitialize(var Item: Record Item; var ForecastName: Code[10]; var IncludeBlanketOrders: Boolean; var ExcludeForecastBefore: Date; var IncludePlan: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePeriodEntriesOnBeforeInvtPageDataInsert(var InventoryPageData: Record "Inventory Page Data"; var TempInventoryEventBuffer: Record "Inventory Event Buffer" temporary)
    begin
    end;
}

