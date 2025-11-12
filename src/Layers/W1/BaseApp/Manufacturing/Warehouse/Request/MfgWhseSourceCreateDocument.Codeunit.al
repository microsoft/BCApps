// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Request;

using Microsoft.Manufacturing.Document;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Worksheet;

codeunit 99000984 "Mfg. WhseSourceCreateDocument"
{
    SingleInstance = true;

    var
        MfgCreatePutaway: Codeunit "Mfg. Create Put-away";
        CannotHandleMoreThanProdOrderLineQtyErr: Label 'You cannot handle more than %1 quantity in Production Order No. %2, Line No. %3', Comment = '%1 = Quantity, %2 - Production Order No., %3 - Production Order Line No.';

    [EventSubscriber(ObjectType::Report, Report::"Whse.-Source - Create Document", 'OnCreatePutawayFromProduction', '', true, true)]
    local procedure OnCreatePutawayFromProduction(var WhsePutawayWorksheetLine: Record "Whse. Worksheet Line"; SourceType: Integer; var EverythingHandled: Boolean; var QtyHandledBase: Decimal)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        CheckAndUpdateFinishedQtyOnProdOrderLineFromPutAway(ProdOrderLine, WhsePutawayWorksheetLine, SourceType);

        if ProdOrderLine."Finished Qty. (Base)" > 0 then begin
            MfgCreatePutAway.SetCalledFromPutAwayWorksheet(true);
            MfgCreatePutAway.CreateWhsePutAwayForProdOrderOutputLine(ProdOrderLine);
            MfgCreatePutAway.SetCalledFromPutAwayWorksheet(false);
        end;
        if WhsePutawayWorksheetLine."Qty. to Handle" <> WhsePutawayWorksheetLine."Qty. Outstanding" then
            EverythingHandled := false;
        if EverythingHandled then
            EverythingHandled := MfgCreatePutAway.EverythingIsHandled();
        QtyHandledBase := ProdOrderLine."Finished Qty. (Base)";
    end;

    local procedure CheckAndUpdateFinishedQtyOnProdOrderLineFromPutAway(var ProdOrderLine: Record "Prod. Order Line"; WhseWorksheetLine: Record "Whse. Worksheet Line"; var SourceType: Integer)
    begin
        ProdOrderLine.Get(WhseWorksheetLine."Source Subtype", WhseWorksheetLine."Whse. Document No.", WhseWorksheetLine."Whse. Document Line No.");
        if ProdOrderLine.GetRemainingPutAwayQty() < WhseWorksheetLine."Qty. to Handle" then
            Error(CannotHandleMoreThanProdOrderLineQtyErr, ProdOrderLine.GetRemainingPutAwayQty(), ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");

        ProdOrderLine.TestField(ProdOrderLine."Qty. per Unit of Measure");
        ProdOrderLine."Finished Quantity" := WhseWorksheetLine."Qty. to Handle";
        ProdOrderLine."Finished Qty. (Base)" := WhseWorksheetLine."Qty. to Handle (Base)";
        SourceType := Database::"Prod. Order Line";
    end;

    [EventSubscriber(ObjectType::Report, Report::"Whse.-Source - Create Document", 'OnAfterCreatePutawaySetValues', '', true, true)]
    local procedure OnAfterCreatePutawaySetValues(NewAssignedID: Code[50]; NewSortActivity: Enum "Whse. Activity Sorting Method"; NewDoNotFillQtytoHandle: Boolean; NewBreakbulkFilter: Boolean)
    begin
        Clear(MfgCreatePutaway);
        MfgCreatePutaway.SetValues(NewAssignedID, NewSortActivity, NewDoNotFillQtytoHandle, NewBreakbulkFilter);
    end;

    [EventSubscriber(ObjectType::Report, Report::"Whse.-Source - Create Document", 'OnGetProductionMessageText', '', true, true)]
    local procedure OnGetProductionMessageText(var CreateErrorText: Text)
    begin
        MfgCreatePutAway.GetMessageText(CreateErrorText);
    end;

    [EventSubscriber(ObjectType::Report, Report::"Whse.-Source - Create Document", 'OnAfterCreatePutawayGetWhseActivHeaderNo', '', true, true)]
    local procedure OnAfterCreatePutawayGetWhseActivHeaderNo(var FirstActivityNo: Code[20]; var LastActivityNo: Code[20])
    begin
        if FirstActivityNo = '' then
            MfgCreatePutAway.GetWhseActivHeaderNo(FirstActivityNo, LastActivityNo);
    end;

    [EventSubscriber(ObjectType::Report, Report::"Whse.-Source - Create Document", 'OnAfterCreatePutAwayDeleteBlankBinContent', '', true, true)]
    local procedure OnAfterCreatePutAwayDeleteBlankBinContent(var WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
        MfgCreatePutAway.DeleteBlankBinContent(WarehouseActivityHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Get Source Doc. Outbound", 'OnGetSingleOutboundDocOnSetFilterGroupFilters', '', true, true)]
    local procedure OnGetSingleOutboundDocOnSetFilterGroupFilters(var WhseRqst: Record "Warehouse Request")
    begin
        WhseRqst.SetFilter("Source Document", '<>%1', WhseRqst."Source Document"::"Prod. Consumption");
    end;

}