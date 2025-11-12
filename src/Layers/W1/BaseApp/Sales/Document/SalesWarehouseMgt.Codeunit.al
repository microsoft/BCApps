// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Tracking;
using Microsoft.Sales.History;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Worksheet;

codeunit 5991 "Sales Warehouse Mgt."
{
    var
        WhseManagement: Codeunit "Whse. Management";
        WhseValidateSourceHeader: Codeunit "Whse. Validate Source Header";
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        WhseCreateSourceDocument: Codeunit "Whse.-Create Source Document";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowSourceDocLine', '', false, false)]
    local procedure OnShowSourceDocLine(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer)
    var
        SalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        if SourceType = Database::"Sales Line" then begin
            SalesLine.Reset();
            SalesLine.SetRange("Document Type", SourceSubType);
            SalesLine.SetRange("Document No.", SourceNo);
            SalesLine.SetRange("Line No.", SourceLineNo);
            IsHandled := false;
            OnBeforeShowSalesLines(SalesLine, SourceSubType, SourceNo, SourceLineNo, IsHandled);
            if not IsHandled then
                ShowSalesLines(SalesLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowSourceDocAttachedLines', '', false, false)]
    local procedure OnShowSourceDocAttachedLines(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer)
    var
        SalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        if SourceType = Database::"Sales Line" then begin
            SalesLine.Reset();
            SalesLine.SetRange("Document Type", SourceSubType);
            SalesLine.SetRange("Document No.", SourceNo);
            SalesLine.SetRange("Attached to Line No.", SourceLineNo);
            IsHandled := false;
            OnBeforeShowAttachedSalesLines(SalesLine, SourceSubType, SourceNo, SourceLineNo, IsHandled);
            if not IsHandled then
                ShowSalesLines(SalesLine);
        end;
    end;

    local procedure ShowSalesLines(var SalesLine: Record "Sales Line")
    begin
        Page.Run(Page::"Sales Lines", SalesLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowPostedSourceDoc', '', false, false)]
    local procedure OnShowPostedSourceDoc(PostedSourceDoc: Option; PostedSourceNo: Code[20]; WarehouseActivitySourceDocument: Enum "Warehouse Activity Source Document")
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
        PostedSourceDocEnum: Enum "Warehouse Shipment Posted Source Document";
    begin
        PostedSourceDocEnum := Enum::"Warehouse Shipment Posted Source Document".FromInteger(PostedSourceDoc);
        case PostedSourceDocEnum of
            PostedSourceDocEnum::"Posted Shipment":
                if WarehouseActivitySourceDocument = WarehouseActivitySourceDocument::"Sales Order" then begin
                    SalesShipmentHeader.Reset();
                    SalesShipmentHeader.SetRange("No.", PostedSourceNo);
                    PAGE.RunModal(PAGE::"Posted Sales Shipment", SalesShipmentHeader);
                end;
            PostedSourceDocEnum::"Posted Return Receipt":
                begin
                    ReturnReceiptHeader.Reset();
                    ReturnReceiptHeader.SetRange("No.", PostedSourceNo);
                    PAGE.RunModal(PAGE::"Posted Return Receipt", ReturnReceiptHeader);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowSourceDocCard', '', false, false)]
    local procedure OnShowSourceDocCard(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        if SourceType = DATABASE::"Sales Line" then begin
            SalesHeader.Reset();
            SalesHeader.SetRange("Document Type", SourceSubType);
            if SalesHeader.Get(SourceSubType, SourceNo) then
                if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then
                    PAGE.RunModal(PAGE::"Sales Order", SalesHeader)
                else
                    PAGE.RunModal(PAGE::"Sales Return Order", SalesHeader);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowSalesLines(var SalesLine: Record "Sales Line"; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowAttachedSalesLines(var SalesLine: Record "Sales Line"; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    procedure SalesLineVerifyChange(var NewSalesLine: Record "Sales Line"; var OldSalesLine: Record "Sales Line")
    var
        NewRecordRef: RecordRef;
        OldRecordRef: RecordRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesLineVerifyChange(NewSalesLine, OldSalesLine, IsHandled);
        if IsHandled then
            exit;

        if not WhseValidateSourceLine.WhseLinesExist(
             DATABASE::"Sales Line", NewSalesLine."Document Type".AsInteger(), NewSalesLine."Document No.", NewSalesLine."Line No.", 0,
             NewSalesLine.Quantity)
        then
            exit;

        NewRecordRef.GetTable(NewSalesLine);
        OldRecordRef.GetTable(OldSalesLine);
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewSalesLine.FieldNo(Type));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewSalesLine.FieldNo("No."));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewSalesLine.FieldNo("Variant Code"));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewSalesLine.FieldNo("Location Code"));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewSalesLine.FieldNo("Unit of Measure Code"));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewSalesLine.FieldNo("Drop Shipment"));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewSalesLine.FieldNo("Purchase Order No."));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewSalesLine.FieldNo("Purch. Order Line No."));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewSalesLine.FieldNo("Job No."));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewSalesLine.FieldNo(Quantity));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewSalesLine.FieldNo("Qty. to Ship"));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewSalesLine.FieldNo("Qty. to Assemble to Order"));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewSalesLine.FieldNo("Shipment Date"));

        OnAfterSalesLineVerifyChange(NewRecordRef, OldRecordRef);
    end;

    procedure SalesLineDelete(var SalesLine: Record "Sales Line")
    begin
        if WhseValidateSourceLine.WhseLinesExist(
             DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.",
             SalesLine."Line No.", 0, SalesLine.Quantity)
        then
            WhseValidateSourceLine.RaiseCannotBeDeletedErr(SalesLine.TableCaption());

        OnAfterSalesLineDelete(SalesLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Validate Source Line", 'OnWhseLineExistOnBeforeCheckReceipt', '', false, false)]
    local procedure OnWhseLineExistOnBeforeCheckReceipt(SourceType: Integer; SourceSubType: Option; SourceQty: Decimal; var CheckReceipt: Boolean)
    begin
        CheckReceipt := CheckReceipt or
           ((SourceType = DATABASE::"Sales Line") and (SourceSubType = 1) and (SourceQty < 0)) or
           ((SourceType = DATABASE::"Sales Line") and (SourceSubType = 5) and (SourceQty >= 0));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Validate Source Line", 'OnWhseLineExistOnBeforeCheckShipment', '', false, false)]
    local procedure OnWhseLineExistOnBeforeCheckShipment(SourceType: Integer; SourceSubType: Option; SourceQty: Decimal; var CheckShipment: Boolean)
    begin
        CheckShipment := CheckShipment or
            ((SourceType = DATABASE::"Sales Line") and (SourceSubType = 1) and (SourceQty >= 0)) or
            ((SourceType = DATABASE::"Sales Line") and (SourceSubType = 5) and (SourceQty < 0));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesLineVerifyChange(var NewRecordRef: RecordRef; var OldRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSalesLineDelete(var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesLineVerifyChange(var NewSalesLine: Record "Sales Line"; var OldSalesLine: Record "Sales Line"; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Request", 'OnShowSourceDocumentCard', '', false, false)]
    local procedure OnShowSourceDocumentCard(var WarehouseRequest: Record "Warehouse Request")
    var
        SalesHeader: Record "Sales Header";
    begin
        case WarehouseRequest."Source Document" of
            "Warehouse Request Source Document"::"Sales Order":
                begin
                    SalesHeader.Get(WarehouseRequest."Source Subtype", WarehouseRequest."Source No.");
                    PAGE.Run(PAGE::"Sales Order", SalesHeader);
                end;
            "Warehouse Request Source Document"::"Sales Return Order":
                begin
                    SalesHeader.Get(WarehouseRequest."Source Subtype", WarehouseRequest."Source No.");
                    PAGE.Run(PAGE::"Sales Return Order", SalesHeader);
                end;
        end;
    end;

    procedure SalesHeaderVerifyChange(var NewSalesHeader: Record "Sales Header"; var OldSalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesHeaderVerifyChange(NewSalesHeader, OldSalesHeader, IsHandled);
        if IsHandled then
            exit;

        if NewSalesHeader."Shipping Advice" = OldSalesHeader."Shipping Advice" then
            exit;

        SalesLine.Reset();
        SalesLine.SetRange("Document Type", OldSalesHeader."Document Type");
        SalesLine.SetRange("Document No.", OldSalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                WhseValidateSourceHeader.ChangeWarehouseLines(
                    DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", 0,
                    NewSalesHeader."Shipping Advice");
            until SalesLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesHeaderVerifyChange(var NewSalesHeader: Record "Sales Header"; var OldSalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Source Filter", 'OnSetFiltersOnSourceTables', '', false, false)]
    local procedure OnSetFiltersOnSourceTables(var WarehouseSourceFilter: Record "Warehouse Source Filter"; var GetSourceDocuments: Report "Get Source Documents"; var WarehouseRequest: Record "Warehouse Request")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        SalesHeader.SetFilter("Sell-to Customer No.", WarehouseSourceFilter."Sell-to Customer No. Filter");

        SalesLine.SetFilter("No.", WarehouseSourceFilter."Item No. Filter");
        SalesLine.SetFilter("Variant Code", WarehouseSourceFilter."Variant Code Filter");
        SalesLine.SetFilter("Unit of Measure Code", WarehouseSourceFilter."Unit of Measure Filter");
        SalesLine.SetFilter("Planned Delivery Date", WarehouseSourceFilter."Planned Delivery Date");
        SalesLine.SetFilter("Planned Shipment Date", WarehouseSourceFilter."Planned Shipment Date");
        SalesLine.SetFilter("Shipment Date", WarehouseSourceFilter."Sales Shipment Date");
        SalesLine.SetFilter("Shipping Agent Code", WarehouseSourceFilter."Shipping Agent Code Filter");
        SalesLine.SetFilter("Shipping Agent Service Code", WarehouseSourceFilter."Shipping Agent Service Filter");

        OnSetFiltersOnSourceTablesOnBeforeSetSalesTableView(WarehouseSourceFilter, WarehouseRequest, SalesHeader, SalesLine);
        GetSourceDocuments.SetTableView(SalesHeader);
        GetSourceDocuments.SetTableView(SalesLine);
    end;

    procedure FromSalesLine2ShptLine(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SalesLine: Record "Sales Line") Result: Boolean
    var
        AssemblyHeader: Record "Assembly Header";
        TotalOutstandingWhseShptQty: Decimal;
        TotalOutstandingWhseShptQtyBase: Decimal;
        ATOWhseShptLineQty: Decimal;
        ATOWhseShptLineQtyBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFromSalesLine2ShptLine(SalesLine, Result, IsHandled, WarehouseShipmentHeader);
        if IsHandled then
            exit(Result);

        SalesLine.CalcFields("Whse. Outstanding Qty.", "ATO Whse. Outstanding Qty.",
          "Whse. Outstanding Qty. (Base)", "ATO Whse. Outstd. Qty. (Base)");
        TotalOutstandingWhseShptQty := Abs(SalesLine."Outstanding Quantity") - SalesLine."Whse. Outstanding Qty.";
        TotalOutstandingWhseShptQtyBase := Abs(SalesLine."Outstanding Qty. (Base)") - SalesLine."Whse. Outstanding Qty. (Base)";
        if SalesLine.AsmToOrderExists(AssemblyHeader) then begin
            ATOWhseShptLineQty := AssemblyHeader."Remaining Quantity" - SalesLine."ATO Whse. Outstanding Qty.";
            ATOWhseShptLineQtyBase := AssemblyHeader."Remaining Quantity (Base)" - SalesLine."ATO Whse. Outstd. Qty. (Base)";
            OnFromSalesLine2ShptLineOnBeforeCreateATOShipmentLine(WarehouseShipmentHeader, AssemblyHeader, SalesLine, ATOWhseShptLineQty, ATOWhseShptLineQtyBase);
            if ATOWhseShptLineQtyBase > 0 then begin
                if not CreateShptLineFromSalesLine(WarehouseShipmentHeader, SalesLine, ATOWhseShptLineQty, ATOWhseShptLineQtyBase, true) then
                    exit(false);
                TotalOutstandingWhseShptQty -= ATOWhseShptLineQty;
                TotalOutstandingWhseShptQtyBase -= ATOWhseShptLineQtyBase;
            end;
        end;

        OnFromSalesLine2ShptLineOnBeforeCreateShipmentLine(WarehouseShipmentHeader, SalesLine, TotalOutstandingWhseShptQty, TotalOutstandingWhseShptQtyBase);

        if TotalOutstandingWhseShptQtyBase > 0 then
            exit(CreateShptLineFromSalesLine(WarehouseShipmentHeader, SalesLine, TotalOutstandingWhseShptQty, TotalOutstandingWhseShptQtyBase, false));
        exit(true);
    end;

    local procedure CreateShptLineFromSalesLine(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SalesLine: Record "Sales Line"; WhseShptLineQty: Decimal; WhseShptLineQtyBase: Decimal; AssembleToOrder: Boolean) Result: Boolean
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        SalesHeader: Record "Sales Header";
        IsHandled, Return : Boolean;
    begin
        IsHandled := false;
        OnCreateShptLineFromSalesLineOnBeforeGetSalesHeader(WarehouseShipmentHeader, SalesLine, WhseShptLineQty, WhseShptLineQtyBase, AssembleToOrder, IsHandled, Result);
        if IsHandled then
            exit(Result);

        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        WarehouseShipmentLine.InitNewLine(WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.SetSource(DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.TestField("Unit of Measure Code");
        WarehouseShipmentLine.SetItemData(
          SalesLine."No.", SalesLine.Description, SalesLine."Description 2", SalesLine."Location Code",
          SalesLine."Variant Code", SalesLine."Unit of Measure Code", SalesLine."Qty. per Unit of Measure",
          SalesLine."Qty. Rounding Precision", SalesLine."Qty. Rounding Precision (Base)");
        IsHandled := false;
        Return := false;
        OnAfterInitNewWhseShptLine(WarehouseShipmentLine, WarehouseShipmentHeader, SalesLine, AssembleToOrder, WhseShptLineQty, WhseShptLineQtyBase, IsHandled, Return);
        if IsHandled then
            exit(Return);
        WhseCreateSourceDocument.SetQtysOnShptLine(WarehouseShipmentLine, WhseShptLineQty, WhseShptLineQtyBase);
        WarehouseShipmentLine."Assemble to Order" := AssembleToOrder;
        if SalesLine."Document Type" = SalesLine."Document Type"::Order then
            WarehouseShipmentLine."Due Date" := SalesLine."Planned Shipment Date";
        if SalesLine."Document Type" = SalesLine."Document Type"::"Return Order" then
            WarehouseShipmentLine."Due Date" := WorkDate();
        if WarehouseShipmentHeader."Shipment Date" = 0D then
            WarehouseShipmentLine."Shipment Date" := SalesLine."Shipment Date"
        else
            WarehouseShipmentLine."Shipment Date" := WarehouseShipmentHeader."Shipment Date";
        WarehouseShipmentLine."Destination Type" := WarehouseShipmentLine."Destination Type"::Customer;
        WarehouseShipmentLine."Destination No." := SalesLine."Sell-to Customer No.";
        WarehouseShipmentLine."Shipping Advice" := SalesHeader."Shipping Advice";
        if WarehouseShipmentLine."Location Code" = WarehouseShipmentHeader."Location Code" then
            WarehouseShipmentLine."Bin Code" := WarehouseShipmentHeader."Bin Code";
        if WarehouseShipmentLine."Bin Code" = '' then
            WarehouseShipmentLine."Bin Code" := SalesLine."Bin Code";
        WhseCreateSourceDocument.UpdateShipmentLine(WarehouseShipmentLine, WarehouseShipmentHeader);
        OnBeforeCreateShptLineFromSalesLine(WarehouseShipmentLine, WarehouseShipmentHeader, SalesLine, SalesHeader);
        WhseCreateSourceDocument.CreateShipmentLine(WarehouseShipmentLine);
        OnAfterCreateShptLineFromSalesLine(WarehouseShipmentLine, WarehouseShipmentHeader, SalesLine, SalesHeader);
        exit(not WarehouseShipmentLine.HasErrorOccured());
    end;

    procedure SalesLine2ReceiptLine(WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SalesLine: Record "Sales Line"): Boolean
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeSalesLine2ReceiptLine(WarehouseReceiptHeader, SalesLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        WarehouseReceiptLine.InitNewLine(WarehouseReceiptHeader."No.");
        WarehouseReceiptLine.SetSource(DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.TestField("Unit of Measure Code");
        WarehouseReceiptLine.SetItemData(
            SalesLine."No.", SalesLine.Description, SalesLine."Description 2", SalesLine."Location Code",
            SalesLine."Variant Code", SalesLine."Unit of Measure Code", SalesLine."Qty. per Unit of Measure",
            SalesLine."Qty. Rounding Precision", SalesLine."Qty. Rounding Precision (Base)");
        OnSalesLine2ReceiptLineOnAfterInitNewLine(WarehouseReceiptLine, WarehouseReceiptHeader, SalesLine);
        case SalesLine."Document Type" of
            SalesLine."Document Type"::Order:
                begin
                    WarehouseReceiptLine.Validate("Qty. Received", Abs(SalesLine."Quantity Shipped"));
                    WarehouseReceiptLine."Due Date" := SalesLine."Planned Shipment Date";
                end;
            SalesLine."Document Type"::"Return Order":
                begin
                    WarehouseReceiptLine.Validate("Qty. Received", Abs(SalesLine."Return Qty. Received"));
                    WarehouseReceiptLine."Due Date" := WorkDate();
                end;
        end;
        WhseCreateSourceDocument.SetQtysOnRcptLine(WarehouseReceiptLine, Abs(SalesLine.Quantity), Abs(SalesLine."Quantity (Base)"));
        WarehouseReceiptLine."Starting Date" := SalesLine."Shipment Date";
        if WarehouseReceiptLine."Location Code" = WarehouseReceiptHeader."Location Code" then
            WarehouseReceiptLine."Bin Code" := WarehouseReceiptHeader."Bin Code";
        if WarehouseReceiptLine."Bin Code" = '' then
            WarehouseReceiptLine."Bin Code" := SalesLine."Bin Code";
        OnSalesLine2ReceiptLineOnBeforeUpdateReceiptLine(WarehouseReceiptLine, SalesLine);
        WhseCreateSourceDocument.UpdateReceiptLine(WarehouseReceiptLine, WarehouseReceiptHeader);
        OnBeforeCreateReceiptLineFromSalesLine(WarehouseReceiptLine, WarehouseReceiptHeader, SalesLine);
        WhseCreateSourceDocument.CreateReceiptLine(WarehouseReceiptLine);
        OnAfterCreateRcptLineFromSalesLine(WarehouseReceiptLine, WarehouseReceiptHeader, SalesLine);
        exit(not WarehouseReceiptLine.HasErrorOccured());
    end;

    procedure CheckIfFromSalesLine2ShptLine(SalesLine: Record "Sales Line"): Boolean
    begin
        exit(CheckIfFromSalesLine2ShptLine(SalesLine, "Reservation From Stock"::" "));
    end;

    procedure CheckIfFromSalesLine2ShptLine(SalesLine: Record "Sales Line"; ReservedFromStock: Enum "Reservation From Stock"): Boolean
    var
        IsHandled: Boolean;
        ReturnValue: Boolean;
    begin
        IsHandled := false;
        ReturnValue := false;
        OnBeforeCheckIfSalesLine2ShptLine(SalesLine, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        if SalesLine.IsNonInventoriableItem() then
            exit(false);

        if not SalesLine.CheckIfSalesLineMeetsReservedFromStockSetting(Abs(SalesLine."Outstanding Qty. (Base)"), ReservedFromStock) then
            exit(false);

        SalesLine.CalcFields("Whse. Outstanding Qty. (Base)");
        exit(Abs(SalesLine."Outstanding Qty. (Base)") > Abs(SalesLine."Whse. Outstanding Qty. (Base)"));
    end;

    procedure CheckIfSalesLine2ReceiptLine(SalesLine: Record "Sales Line"): Boolean
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WhseManagement: Codeunit "Whse. Management";
        IsHandled: Boolean;
        ReturnValue: Boolean;
    begin
        IsHandled := false;
        ReturnValue := false;
        OnBeforeCheckIfSalesLine2ReceiptLine(SalesLine, ReturnValue, IsHandled);
        if IsHandled then
            exit(ReturnValue);

        if SalesLine.IsNonInventoriableItem() then
            exit(false);

        WhseManagement.SetSourceFilterForWhseRcptLine(
          WarehouseReceiptLine, DATABASE::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", false);
        WarehouseReceiptLine.CalcSums("Qty. Outstanding (Base)");
        exit(Abs(SalesLine."Outstanding Qty. (Base)") > Abs(WarehouseReceiptLine."Qty. Outstanding (Base)"));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFromSalesLine2ShptLine(var SalesLine: Record "Sales Line"; var Result: Boolean; var IsHandled: Boolean; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFromSalesLine2ShptLineOnBeforeCreateATOShipmentLine(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; AssemblyHeader: Record "Assembly Header"; var SalesLine: Record "Sales Line"; var ATOWhseShptLineQty: Decimal; var ATOWhseShptLineQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFromSalesLine2ShptLineOnBeforeCreateShipmentLine(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SalesLine: Record "Sales Line"; var TotalOutstandingWhseShptQty: Decimal; var TotalOutstandingWhseShptQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitNewWhseShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SalesLine: Record "Sales Line"; AssembleToOrder: Boolean; var WhseShptLineQty: Decimal; var WhseShptLineQtyBase: Decimal; var IsHandled: Boolean; var Return: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateShptLineFromSalesLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateShptLineFromSalesLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSalesLine2ReceiptLine(WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var SalesLine: Record "Sales Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesLine2ReceiptLineOnAfterInitNewLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSalesLine2ReceiptLineOnBeforeUpdateReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateReceiptLineFromSalesLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateRcptLineFromSalesLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfSalesLine2ShptLine(var SalesLine: Record "Sales Line"; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIfSalesLine2ReceiptLine(var SalesLine: Record "Sales Line"; var ReturnValue: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateShptLineFromSalesLineOnBeforeGetSalesHeader(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SalesLine: Record "Sales Line"; WhseShptLineQty: Decimal; WhseShptLineQtyBase: Decimal; AssembleToOrder: Boolean; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetFiltersOnSourceTablesOnBeforeSetSalesTableView(var WarehouseSourceFilter: Record "Warehouse Source Filter"; var WarehouseRequest: Record "Warehouse Request"; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Management", 'OnAfterGetSrcDocLineQtyOutstanding', '', false, false)]
    local procedure OnAfterGetSrcDocLineQtyOutstanding(SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; var QtyBaseOutstanding: Decimal; var QtyOutstanding: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        if SourceType = Database::"Sales Line" then
            if SalesLine.Get(SourceSubType, SourceNo, SourceLineNo) then begin
                QtyOutstanding := SalesLine."Outstanding Quantity";
                QtyBaseOutstanding := SalesLine."Outstanding Qty. (Base)";
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Management", 'OnAfterGetSourceDocumentType', '', false, false)]
    local procedure WhseManagementGetSourceDocumentType(SourceType: Integer; SourceSubType: Integer; var SourceDocument: Enum "Warehouse Journal Source Document"; var IsHandled: Boolean)
    begin
        if SourceType = Database::"Sales Line" then begin
            case SourceSubtype of
                1:
                    SourceDocument := "Warehouse Journal Source Document"::"S. Order";
                2:
                    SourceDocument := "Warehouse Journal Source Document"::"S. Invoice";
                3:
                    SourceDocument := "Warehouse Journal Source Document"::"S. Credit Memo";
                5:
                    SourceDocument := "Warehouse Journal Source Document"::"S. Return Order";
            end;
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Management", 'OnAfterGetJournalSourceDocument', '', false, false)]
    local procedure WhseManagementGetJournalSourceDocument(SourceType: Integer; SourceSubType: Integer; var SourceDocument: Enum "Warehouse Journal Source Document"; var IsHandled: Boolean)
    begin
        if SourceType = Database::"Sales Line" then begin
            case SourceSubtype of
                1:
                    SourceDocument := SourceDocument::"S. Order";
                2:
                    SourceDocument := SourceDocument::"S. Invoice";
                3:
                    SourceDocument := SourceDocument::"S. Credit Memo";
                5:
                    SourceDocument := SourceDocument::"S. Return Order";
            end;
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Create Pick", 'OnCheckSourceDocument', '', false, false)]
    local procedure CreatePickOnCheckSourceDocument(var PickWhseWkshLine: Record "Whse. Worksheet Line")
    var
        SalesLine: Record "Sales Line";
    begin
        if PickWhseWkshLine."Source Type" = Database::"Sales Line" then begin
            SalesLine.SetRange("Document Type", PickWhseWkshLine."Source Subtype");
            SalesLine.SetRange("Document No.", PickWhseWkshLine."Source No.");
            SalesLine.SetRange("Line No.", PickWhseWkshLine."Source Line No.");
            if SalesLine.IsEmpty() then
                Error(WhseManagement.GetSourceDocumentDoesNotExistErr(), SalesLine.TableCaption(), SalesLine.GetFilters());
        end;
    end;
}
