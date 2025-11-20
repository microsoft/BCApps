// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Integration;

using Microsoft.Finance.Dimension;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Posting;
using Microsoft.Purchases.Reports;
using Microsoft.Manufacturing.WorkCenter;

codeunit 99000789 "Mfg. Purchase Document Mgt."
{
    var
        DimMgt: Codeunit DimensionManagement;
        CannotDefineItemTrackingErr: Label 'You cannot define item tracking on this line because it is linked to production order %1.', Comment = '%1 - production order number';
        CannotChangePurchaseOrderErr: Label 'You cannot change %1 because this purchase order is associated with %2 %3.', Comment = '%1 - type, %2 - production order, %3 - number';

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterInitPurchaseLineDefaultDimSource', '', false, false)]
    local procedure OnAfterInitPurchaseLineDefaultDimSource(var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; SourcePurchaseLine: Record "Purchase Line")
    begin
        DimMgt.AddDimSource(DefaultDimSource, Database::"Work Center", SourcePurchaseLine."Work Center No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnTransferSavedFieldsOnAfterSetVariantCode', '', false, false)]
    local procedure OnTransferSavedFieldsOnAfterSetVariantCode(var DestinationPurchaseLine: Record "Purchase Line"; SourcePurchaseLine: Record "Purchase Line")
    begin
        DestinationPurchaseLine."Prod. Order No." := SourcePurchaseLine."Prod. Order No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnAfterTransferSavedFields', '', false, false)]
    local procedure OnAfterTransferSavedFields(var DestinationPurchaseLine: Record "Purchase Line"; SourcePurchaseLine: Record "Purchase Line")
    begin
        DestinationPurchaseLine."Prod. Order Line No." := SourcePurchaseLine."Prod. Order Line No.";
        DestinationPurchaseLine."Routing No." := SourcePurchaseLine."Routing No.";
        DestinationPurchaseLine."Routing Reference No." := SourcePurchaseLine."Routing Reference No.";
        DestinationPurchaseLine."Operation No." := SourcePurchaseLine."Operation No.";
        DestinationPurchaseLine."Work Center No." := SourcePurchaseLine."Work Center No.";
        DestinationPurchaseLine."Overhead Rate" := SourcePurchaseLine."Overhead Rate";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnInsertTempPurchLineInBufferOnBeforeTempPurchLineInsert', '', false, false)]
    local procedure OnInsertTempPurchLineInBufferOnBeforeTempPurchLineInsert(var TempPurchaseLine: Record "Purchase Line" temporary; PurchaseLine: Record "Purchase Line")
    begin
        TempPurchaseLine."Work Center No." := PurchaseLine."Work Center No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnCollectParamsInBufferForCreateDimSetOnAfterSetTempPurchLineFilters', '', false, false)]
    local procedure OnCollectParamsInBufferForCreateDimSetOnAfterSetTempPurchLineFilters(var TempPurchaseLine: Record "Purchase Line" temporary; PurchaseLine: Record "Purchase Line")
    begin
        TempPurchaseLine.SetRange("Work Center No.", PurchaseLine."Work Center No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterInitDefaultDimensionSources', '', false, false)]
    local procedure OnAfterInitDefaultDimensionSources(var PurchaseLine: Record "Purchase Line"; var DefaultDimSource: List of [Dictionary of [Integer, Code[20]]]; FieldNo: Integer)
    begin
        DimMgt.AddDimSource(DefaultDimSource, Database::"Work Center", PurchaseLine."Work Center No.", FieldNo = PurchaseLine.FieldNo("Work Center No."));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnIsProdOrder', '', false, false)]
    local procedure OnIsProdOrder(var PurchaseLine: Record "Purchase Line"; var Result: Boolean)
    begin
        Result := PurchaseLine."Prod. Order No." <> '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnIsWorkCenter', '', false, false)]
    local procedure OnIsWorkCenter(var PurchaseLine: Record "Purchase Line"; var Result: Boolean)
    begin
        Result := PurchaseLine."Work Center No." <> '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnIsSubcontractingCreditMemo', '', false, false)]
    local procedure OnIsSubcontractingCreditMemo(var PurchaseLine: Record "Purchase Line"; var Result: Boolean)
    begin
        if (PurchaseLine."Document Type" = PurchaseLine."Document Type"::"Credit Memo") and PurchaseLine.IsProdOrder() and
           (PurchaseLine."Operation No." <> '') and (PurchaseLine."Work Center No." <> '') then
            Result := true
        else
            Result := false;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnOpenItemTrackingLinesOnAfterCheck', '', false, false)]
    local procedure OnOpenItemTrackingLinesOnAfterCheck(var PurchaseLine: Record "Purchase Line")
    begin
        if PurchaseLine."Prod. Order No." <> '' then
            Error(CannotDefineItemTrackingErr, PurchaseLine."Prod. Order No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnAfterCheckAssosiatedProdOrder', '', false, false)]
    local procedure OnAfterCheckAssosiatedProdOrder(var PurchaseLine: Record "Purchase Line")
    begin
        if PurchaseLine."Prod. Order No." <> '' then
            Error(CannotChangePurchaseOrderErr, PurchaseLine.FieldCaption(Type), PurchaseLine.FieldCaption("Prod. Order No."), PurchaseLine."Prod. Order No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnTestProdOrderNo', '', false, false)]
    local procedure OnTestProdOrderNo(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.TestField("Prod. Order No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Line", 'OnTestWorkCenterNo', '', false, false)]
    local procedure OnTestWorkCenterNo(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.TestField("Work Center No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Inv. Line", 'OnGetItemLedgEntryOnShouldExit', '', false, false)]
    local procedure OnGetItemLedgEntryOnShouldExit(var PurchInvLine: Record "Purch. Inv. Line"; var ShouldExit: Boolean);
    begin
        if PurchInvLine."Work Center No." <> '' then
            ShouldExit := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Inv. Line", 'OnIsProdOrder', '', false, false)]
    local procedure PurchInvLineOnIsProdOrder(var PurchInvLine: Record "Purch. Inv. Line"; var Result: Boolean)
    begin
        Result := PurchInvLine."Prod. Order No." <> '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Rcpt. Line", 'OnIsProdOrder', '', false, false)]
    local procedure PurchRcptLineOnIsProdOrder(var PurchRcptLine: Record "Purch. Rcpt. Line"; var Result: Boolean)
    begin
        Result := PurchRcptLine."Prod. Order No." <> '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Return Shipment Line", 'OnIsProdOrder', '', false, false)]
    local procedure ReturnShipmentLineOnIsProdOrder(var ReturnShipmentLine: Record "Return Shipment Line"; var Result: Boolean)
    begin
        Result := ReturnShipmentLine."Prod. Order No." <> '';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purch. Rcpt. Line", 'OnTestWorkCenterNo', '', false, false)]
    local procedure PurchRcptLineOnTestWorkCenterNo(var PurchRcptLine: Record "Purch. Rcpt. Line"; var Result: Boolean)
    begin
        PurchRcptLine.TestField("Work Center No.", '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Return Shipment Line", 'OnTestProdOrder', '', false, false)]
    local procedure ReturnShipmentLineOnTestProdOrder(var ReturnShipmentLine: Record "Return Shipment Line"; var Result: Boolean)
    begin
        ReturnShipmentLine.TestField("Prod. Order No.", '');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purchase-Post Prepayments", 'OnCreateDimensionsOnAfterAddDimSources', '', false, false)]
    local procedure OnCreateDimensionsOnAfterAddDimSources(var PurchaseLine: Record "Purchase Line"; DefaultDimSource: List of [Dictionary of [Integer, Code[20]]])
    begin
        DimMgt.AddDimSource(DefaultDimSource, Database::"Work Center", PurchaseLine."Work Center No.");
    end;

    [EventSubscriber(ObjectType::Report, Report::"Purchase Document - Test", 'OnBeforeCheckDimValuePostingLine', '', false, false)]
    local procedure OnBeforeCheckDimValuePostingLine(var PurchaseLine: Record "Purchase Line"; var TableID: array[10] of Integer; var No: array[10] of Code[20]);
    begin
        TableID[3] := Database::"Work Center";
        No[3] := PurchaseLine."Work Center No.";
    end;

}
