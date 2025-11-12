// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Worksheet;

codeunit 5993 "Transfer Warehouse Mgt."
{
    var
        WhseManagement: Codeunit "Whse. Management";
        WhseValidateSourceHeader: Codeunit "Whse. Validate Source Header";
        WhseCreateSourceDocument: Codeunit "Whse.-Create Source Document";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowSourceDocLine', '', false, false)]
    local procedure OnShowSourceDocLine(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer)
    var
        TransferLine: Record "Transfer Line";
        IsHandled: Boolean;
    begin
        if SourceType = Database::"Transfer Line" then begin
            TransferLine.Reset();
            TransferLine.SetRange("Document No.", SourceNo);
            TransferLine.SetRange("Line No.", SourceLineNo);
            IsHandled := false;
            OnBeforeShowTransferLines(TransferLine, SourceNo, SourceLineNo, IsHandled);
            if not IsHandled then
                ShowTransferLines(TransferLine);
        end;
    end;

    local procedure ShowTransferLines(var TransferLine: Record "Transfer Line")
    begin
        Page.Run(Page::"Transfer Lines", TransferLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowSourceDocCard', '', false, false)]
    local procedure OnShowSourceDocCard(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20])
    var
        TransferHeader: Record "Transfer Header";
    begin
        if SourceType = DATABASE::"Transfer Line" then
            if TransferHeader.Get(SourceNo) then
                PAGE.RunModal(PAGE::"Transfer Order", TransferHeader);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowPostedSourceDoc', '', false, false)]
    local procedure OnShowPostedSourceDoc(PostedSourceDoc: Option; PostedSourceNo: Code[20])
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferReceiptHeader: Record "Transfer Receipt Header";
        PostedSourceDocEnum: Enum "Warehouse Shipment Posted Source Document";
    begin
        PostedSourceDocEnum := Enum::"Warehouse Shipment Posted Source Document".FromInteger(PostedSourceDoc);
        case PostedSourceDocEnum of
            PostedSourceDocEnum::"Posted Transfer Shipment":
                begin
                    TransferShipmentHeader.Reset();
                    TransferShipmentHeader.SetRange("No.", PostedSourceNo);
                    PAGE.RunModal(PAGE::"Posted Transfer Shipment", TransferShipmentHeader);
                end;
            PostedSourceDocEnum::"Posted Transfer Receipt":
                begin
                    TransferReceiptHeader.Reset();
                    TransferReceiptHeader.SetRange("No.", PostedSourceNo);
                    PAGE.RunModal(PAGE::"Posted Transfer Receipt", TransferReceiptHeader);
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowTransferLines(var TransferLine: Record "Transfer Line"; SourceNo: Code[20]; SourceLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Validate Source Line", 'OnWhseLineExistOnBeforeCheckReceipt', '', false, false)]
    local procedure OnWhseLineExistOnBeforeCheckReceipt(SourceType: Integer; SourceSubType: Option; SourceQty: Decimal; var CheckReceipt: Boolean)
    begin
        CheckReceipt := CheckReceipt or
           ((SourceType = DATABASE::"Transfer Line") and (SourceSubType = 1));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Validate Source Line", 'OnWhseLineExistOnBeforeCheckShipment', '', false, false)]
    local procedure OnWhseLineExistOnBeforeCheckShipment(SourceType: Integer; SourceSubType: Option; SourceQty: Decimal; var CheckShipment: Boolean)
    begin
        CheckShipment := CheckShipment or
            ((SourceType = DATABASE::"Transfer Line") and (SourceSubType = 0));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Request", 'OnShowSourceDocumentCard', '', false, false)]
    local procedure OnShowSourceDocumentCard(var WarehouseRequest: Record "Warehouse Request")
    var
        TransferHeader: Record "Transfer Header";
    begin
        case WarehouseRequest."Source Document" of
            "Warehouse Request Source Document"::"Inbound Transfer",
            "Warehouse Request Source Document"::"Outbound Transfer":
                begin
                    TransferHeader.Get(WarehouseRequest."Source No.");
                    PAGE.Run(PAGE::"Transfer Order", TransferHeader);
                end;
        end;
    end;

    procedure TransHeaderVerifyChange(var NewTransferHeader: Record "Transfer Header"; var OldTransferHeader: Record "Transfer Header")
    var
        TransferLine: Record "Transfer Line";
    begin
        if NewTransferHeader."Shipping Advice" = OldTransferHeader."Shipping Advice" then
            exit;

        TransferLine.Reset();
        TransferLine.SetRange("Document No.", OldTransferHeader."No.");
        if TransferLine.Find('-') then
            repeat
                WhseValidateSourceHeader.ChangeWarehouseLines(
                    DATABASE::"Transfer Line", 0,// Outbound Transfer
                    TransferLine."Document No.", TransferLine."Line No.", 0, NewTransferHeader."Shipping Advice");
            until TransferLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Source Filter", 'OnSetFiltersOnSourceTables', '', false, false)]
    local procedure OnSetFiltersOnSourceTables(var WarehouseSourceFilter: Record "Warehouse Source Filter"; var GetSourceDocuments: Report "Get Source Documents"; var WarehouseRequest: Record "Warehouse Request")
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetFilter("Item No.", WarehouseSourceFilter."Item No. Filter");
        TransferLine.SetFilter("Variant Code", WarehouseSourceFilter."Variant Code Filter");
        TransferLine.SetFilter("Unit of Measure Code", WarehouseSourceFilter."Unit of Measure Filter");
        TransferLine.SetFilter("In-Transit Code", WarehouseSourceFilter."In-Transit Code Filter");
        TransferLine.SetFilter("Transfer-from Code", WarehouseSourceFilter."Transfer-from Code Filter");
        TransferLine.SetFilter("Transfer-to Code", WarehouseSourceFilter."Transfer-to Code Filter");
        TransferLine.SetFilter("Shipment Date", WarehouseSourceFilter."Shipment Date");
        TransferLine.SetFilter("Receipt Date", WarehouseSourceFilter."Receipt Date");
        TransferLine.SetFilter("Shipping Agent Code", WarehouseSourceFilter."Shipping Agent Code Filter");
        TransferLine.SetFilter("Shipping Agent Service Code", WarehouseSourceFilter."Shipping Agent Service Filter");

        OnSetFiltersOnSourceTablesOnBeforeSetTransferTableView(WarehouseSourceFilter, WarehouseRequest, TransferLine);
        GetSourceDocuments.SetTableView(TransferLine);
    end;

    procedure FromTransLine2ShptLine(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; TransferLine: Record "Transfer Line") Result: Boolean
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        TransferHeader: Record "Transfer Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFromTransLine2ShptLine(TransferLine, Result, IsHandled, WarehouseShipmentHeader);
        if IsHandled then
            exit(Result);

        WarehouseShipmentLine.InitNewLine(WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.SetSource(DATABASE::"Transfer Line", 0, TransferLine."Document No.", TransferLine."Line No.");
        TransferLine.TestField("Unit of Measure Code");
        WarehouseShipmentLine.SetItemData(
          TransferLine."Item No.", TransferLine.Description, TransferLine."Description 2", TransferLine."Transfer-from Code",
          TransferLine."Variant Code", TransferLine."Unit of Measure Code", TransferLine."Qty. per Unit of Measure",
          TransferLine."Qty. Rounding Precision", TransferLine."Qty. Rounding Precision (Base)");
        IsHandled := false;
        OnFromTransLine2ShptLineOnAfterInitNewLine(WarehouseShipmentLine, WarehouseShipmentHeader, TransferLine, IsHandled);
        if not IsHandled then
            WhseCreateSourceDocument.SetQtysOnShptLine(WarehouseShipmentLine, TransferLine."Outstanding Quantity", TransferLine."Outstanding Qty. (Base)");
        WarehouseShipmentLine."Due Date" := TransferLine."Shipment Date";
        if WarehouseShipmentHeader."Shipment Date" = 0D then
            WarehouseShipmentLine."Shipment Date" := WorkDate()
        else
            WarehouseShipmentLine."Shipment Date" := WarehouseShipmentHeader."Shipment Date";
        WarehouseShipmentLine."Destination Type" := WarehouseShipmentLine."Destination Type"::Location;
        WarehouseShipmentLine."Destination No." := TransferLine."Transfer-to Code";
        if TransferHeader.Get(TransferLine."Document No.") then
            WarehouseShipmentLine."Shipping Advice" := TransferHeader."Shipping Advice";
        if WarehouseShipmentLine."Location Code" = WarehouseShipmentHeader."Location Code" then
            WarehouseShipmentLine."Bin Code" := WarehouseShipmentHeader."Bin Code";
        if WarehouseShipmentLine."Bin Code" = '' then
            WarehouseShipmentLine."Bin Code" := TransferLine."Transfer-from Bin Code";
        WhseCreateSourceDocument.UpdateShipmentLine(WarehouseShipmentLine, WarehouseShipmentHeader);
        OnBeforeCreateShptLineFromTransLine(WarehouseShipmentLine, WarehouseShipmentHeader, TransferLine, TransferHeader);
        WhseCreateSourceDocument.CreateShipmentLine(WarehouseShipmentLine);
        OnAfterCreateShptLineFromTransLine(WarehouseShipmentLine, WarehouseShipmentHeader, TransferLine, TransferHeader);
        exit(not WarehouseShipmentLine.HasErrorOccured());
    end;

    procedure TransLine2ReceiptLine(WarehouseReceiptHeader: Record "Warehouse Receipt Header"; TransferLine: Record "Transfer Line") Result: Boolean
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        UnitOfMeasureManagement: Codeunit "Unit of Measure Management";
        WhseInbndOtsdgQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransLine2ReceiptLine(WarehouseReceiptHeader, TransferLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        WarehouseReceiptLine.InitNewLine(WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.SetSource(DATABASE::"Transfer Line", 1, TransferLine."Document No.", TransferLine."Line No.");
        TransferLine.TestField("Unit of Measure Code");
        WarehouseReceiptLine.SetItemData(
          TransferLine."Item No.", TransferLine.Description, TransferLine."Description 2", TransferLine."Transfer-to Code",
          TransferLine."Variant Code", TransferLine."Unit of Measure Code", TransferLine."Qty. per Unit of Measure",
          TransferLine."Qty. Rounding Precision", TransferLine."Qty. Rounding Precision (Base)");
        OnTransLine2ReceiptLineOnAfterInitNewLine(WarehouseReceiptLine, WarehouseReceiptHeader, TransferLine);
        WarehouseReceiptLine.Validate(WarehouseReceiptLine."Qty. Received", TransferLine."Quantity Received");
        TransferLine.CalcFields("Whse. Inbnd. Otsdg. Qty (Base)");
        WhseInbndOtsdgQty :=
          UnitOfMeasureManagement.CalcQtyFromBase(
            TransferLine."Item No.", TransferLine."Variant Code", TransferLine."Unit of Measure Code",
            TransferLine."Whse. Inbnd. Otsdg. Qty (Base)", TransferLine."Qty. per Unit of Measure");
        WhseCreateSourceDocument.SetQtysOnRcptLine(
           WarehouseReceiptLine,
           TransferLine."Quantity Received" + TransferLine."Qty. in Transit" - WhseInbndOtsdgQty,
           TransferLine."Qty. Received (Base)" + TransferLine."Qty. in Transit (Base)" - TransferLine."Whse. Inbnd. Otsdg. Qty (Base)");
        WarehouseReceiptLine."Due Date" := TransferLine."Receipt Date";
        WarehouseReceiptLine."Starting Date" := WorkDate();
        if WarehouseReceiptLine."Location Code" = WarehouseReceiptHeader."Location Code" then
            WarehouseReceiptLine."Bin Code" := WarehouseReceiptHeader."Bin Code";
        if WarehouseReceiptLine."Bin Code" = '' then
            WarehouseReceiptLine."Bin Code" := TransferLine."Transfer-To Bin Code";
        OnBeforeUpdateRcptLineFromTransLine(WarehouseReceiptLine, TransferLine);
        WhseCreateSourceDocument.UpdateReceiptLine(WarehouseReceiptLine, WarehouseReceiptHeader);
        WhseCreateSourceDocument.CreateReceiptLine(WarehouseReceiptLine);
        OnAfterCreateRcptLineFromTransLine(WarehouseReceiptLine, WarehouseReceiptHeader, TransferLine);
        exit(not WarehouseReceiptLine.HasErrorOccured());
    end;

    procedure CheckIfFromTransLine2ShptLine(TransferLine: Record "Transfer Line"): Boolean
    begin
        exit(CheckIfFromTransLine2ShptLine(TransferLine, "Reservation From Stock"::" "));
    end;

    procedure CheckIfFromTransLine2ShptLine(TransferLine: Record "Transfer Line"; ReservedFromStock: Enum "Reservation From Stock"): Boolean
    var
        Location: Record Location;
        IsHandled: Boolean;
        ReturnValue: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckIfTransLine2ShipmentLine(TransferLine, IsHandled, ReturnValue);
        if IsHandled then
            exit(ReturnValue);

        if Location.GetLocationSetup(TransferLine."Transfer-from Code", Location) then
            if Location."Use As In-Transit" then
                exit(false);

        if not TransferLine.CheckIfTransferLineMeetsReservedFromStockSetting(TransferLine."Outstanding Qty. (Base)", ReservedFromStock) then
            exit(false);

        TransferLine.CalcFields("Whse Outbnd. Otsdg. Qty (Base)");
        exit(TransferLine."Outstanding Qty. (Base)" > TransferLine."Whse Outbnd. Otsdg. Qty (Base)");
    end;

    procedure CheckIfTransLine2ReceiptLine(TransferLine: Record "Transfer Line"): Boolean
    var
        Location: Record Location;
        IsHandled: Boolean;
        ReturnValue: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckIfTransLine2ReceiptLine(TransferLine, IsHandled, ReturnValue);
        if IsHandled then
            exit(ReturnValue);

        TransferLine.CalcFields("Whse. Inbnd. Otsdg. Qty (Base)");
        if Location.GetLocationSetup(TransferLine."Transfer-to Code", Location) then
            if Location."Use As In-Transit" then
                exit(false);
        exit(TransferLine."Qty. in Transit (Base)" > TransferLine."Whse. Inbnd. Otsdg. Qty (Base)");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFromTransLine2ShptLine(var TransferLine: Record "Transfer Line"; var Result: Boolean; var IsHandled: Boolean; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFromTransLine2ShptLineOnAfterInitNewLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; TransferLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateShptLineFromTransLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateShptLineFromTransLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransLine2ReceiptLine(WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var TransferLine: Record "Transfer Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransLine2ReceiptLineOnAfterInitNewLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateRcptLineFromTransLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateRcptLineFromTransLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfTransLine2ShipmentLine(var TransferLine: Record "Transfer Line"; var IsHandled: Boolean; var ReturnValue: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfTransLine2ReceiptLine(var TransferLine: Record "Transfer Line"; var IsHandled: Boolean; var ReturnValue: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetFiltersOnSourceTablesOnBeforeSetTransferTableView(var WarehouseSourceFilter: Record "Warehouse Source Filter"; var WarehouseRequest: Record "Warehouse Request"; var TransferLine: Record "Transfer Line")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Management", 'OnAfterGetSrcDocLineQtyOutstanding', '', false, false)]
    local procedure OnAfterGetSrcDocLineQtyOutstanding(SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; var QtyBaseOutstanding: Decimal; var QtyOutstanding: Decimal)
    var
        TransferLine: Record "Transfer Line";
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        if SourceType = Database::"Transfer Line" then
            if TransferLine.Get(SourceNo, SourceLineNo) then
                case SourceSubType of
                    "Transfer Direction"::Outbound.AsInteger():
                        begin
                            QtyOutstanding :=
                                Round(
                                    TransferLine."Whse Outbnd. Otsdg. Qty (Base)" / (QtyOutstanding / QtyBaseOutstanding),
                                    UOMMgt.QtyRndPrecision());
                            QtyBaseOutstanding := TransferLine."Whse Outbnd. Otsdg. Qty (Base)";
                        end;
                    "Transfer Direction"::Inbound.AsInteger():
                        begin
                            QtyOutstanding :=
                                Round(
                                    TransferLine."Whse. Inbnd. Otsdg. Qty (Base)" / (QtyOutstanding / QtyBaseOutstanding),
                                    UOMMgt.QtyRndPrecision());
                            QtyBaseOutstanding := TransferLine."Whse. Inbnd. Otsdg. Qty (Base)";
                        end;
                end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Management", 'OnAfterGetSourceDocumentType', '', false, false)]
    local procedure WhseManagementGetSourceDocumentType(SourceType: Integer; SourceSubType: Integer; var SourceDocument: Enum "Warehouse Journal Source Document"; var IsHandled: Boolean)
    begin
        if SourceType = Database::"Transfer Line" then begin
            case SourceSubtype of
                0:
                    SourceDocument := "Warehouse Journal Source Document"::"Outb. Transfer";
                1:
                    SourceDocument := "Warehouse Journal Source Document"::"Inb. Transfer";
            end;
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Management", 'OnAfterGetJournalSourceDocument', '', false, false)]
    local procedure WhseManagementGetJournalSourceDocument(SourceType: Integer; SourceSubType: Integer; var SourceDocument: Enum "Warehouse Journal Source Document"; var IsHandled: Boolean)
    begin
        if SourceType = Database::"Transfer Line" then begin
            case SourceSubtype of
                0:
                    SourceDocument := SourceDocument::"Outb. Transfer";
                1:
                    SourceDocument := SourceDocument::"Inb. Transfer";
            end;
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Create Pick", 'OnCheckSourceDocument', '', false, false)]
    local procedure CreatePickOnCheckSourceDocument(var PickWhseWkshLine: Record "Whse. Worksheet Line")
    var
        TransferLine: Record "Transfer Line";
    begin
        if PickWhseWkshLine."Source Type" = Database::"Transfer Line" then begin
            TransferLine.SetRange("Document No.", PickWhseWkshLine."Source No.");
            TransferLine.SetRange("Line No.", PickWhseWkshLine."Source Line No.");
            if TransferLine.IsEmpty() then
                Error(WhseManagement.GetSourceDocumentDoesNotExistErr(), TransferLine.TableCaption(), TransferLine.GetFilters());
        end;
    end;
}
