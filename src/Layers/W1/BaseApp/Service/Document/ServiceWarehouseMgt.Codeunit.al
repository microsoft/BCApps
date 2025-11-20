// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.CrossDock;
using Microsoft.Warehouse.Document;
using Microsoft.Service.History;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Worksheet;
using System.Security.User;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Warehouse.History;

codeunit 5995 "Service Warehouse Mgt."
{
    var
        WhseManagement: Codeunit "Whse. Management";
        WhseValidateSourceHeader: Codeunit "Whse. Validate Source Header";
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        MustNotBeGreaterErr: Label 'must not be greater than %1 units', Comment = '%1 - Quantity';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowSourceDocLine', '', false, false)]
    local procedure OnShowSourceDocLine(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer)
    var
        ServiceLine: Record "Service Line";
        IsHandled: Boolean;
    begin
        if SourceType = Database::"Service Line" then begin
            ServiceLine.Reset();
            ServiceLine.SetRange("Document Type", SourceSubType);
            ServiceLine.SetRange("Document No.", SourceNo);
            ServiceLine.SetRange("Line No.", SourceLineNo);
            IsHandled := false;
            OnBeforeShowServiceLines(ServiceLine, SourceSubType, SourceNo, SourceLineNo, IsHandled);
            if not IsHandled then
                ShowServiceLines(ServiceLine);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowSourceDocAttachedLines', '', false, false)]
    local procedure OnShowSourceDocAttachedLines(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer)
    var
        ServiceLine: Record "Service Line";
        IsHandled: Boolean;
    begin
        if SourceType = Database::"Service Line" then begin
            ServiceLine.Reset();
            ServiceLine.SetRange("Document Type", SourceSubType);
            ServiceLine.SetRange("Document No.", SourceNo);
            ServiceLine.SetRange("Attached to Line No.", SourceLineNo);
            IsHandled := false;
            OnBeforeShowAttachedServiceLines(ServiceLine, SourceSubType, SourceNo, SourceLineNo, IsHandled);
            if not IsHandled then
                ShowServiceLines(ServiceLine);
        end;
    end;

    local procedure ShowServiceLines(var ServiceLine: Record "Service Line")
    begin
        Page.Run(Page::"Service Line List", ServiceLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowServiceLines(var ServiceLine: Record "Service Line"; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowAttachedServiceLines(var ServiceLine: Record "Service Line"; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    procedure ServiceLineVerifyChange(var NewServiceLine: Record "Service Line"; var OldServiceLine: Record "Service Line")
    var
        NewRecordRef: RecordRef;
        OldRecordRef: RecordRef;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeServiceLineVerifyChange(NewServiceLine, OldServiceLine, IsHandled);
        if IsHandled then
            exit;

        if not WhseValidateSourceLine.WhseLinesExist(
             DATABASE::"Service Line", NewServiceLine."Document Type".AsInteger(), NewServiceLine."Document No.", NewServiceLine."Line No.", 0,
             NewServiceLine.Quantity)
        then
            exit;

        NewRecordRef.GetTable(NewServiceLine);
        OldRecordRef.GetTable(OldServiceLine);
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewServiceLine.FieldNo(Type));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewServiceLine.FieldNo("No."));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewServiceLine.FieldNo("Location Code"));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewServiceLine.FieldNo(Quantity));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewServiceLine.FieldNo("Variant Code"));
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, NewServiceLine.FieldNo("Unit of Measure Code"));

        OnAfterServiceLineVerifyChange(NewRecordRef, OldRecordRef);
    end;

    procedure ServiceLineDelete(var ServiceLine: Record "Service Line")
    begin
        if WhseValidateSourceLine.WhseLinesExist(
             DATABASE::"Service Line", ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.",
             ServiceLine."Line No.", 0, ServiceLine.Quantity)
        then
            WhseValidateSourceLine.RaiseCannotBeDeletedErr(ServiceLine.TableCaption());

        OnAfterServiceLineDelete(ServiceLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Validate Source Line", 'OnWhseLineExistOnBeforeCheckShipment', '', false, false)]
    local procedure OnWhseLineExistOnBeforeCheckShipment(SourceType: Integer; SourceSubType: Option; SourceQty: Decimal; var CheckShipment: Boolean)
    begin
        CheckShipment := CheckShipment or
            ((SourceType = DATABASE::"Service Line") and (SourceSubType = 1));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServiceLineVerifyChange(var NewRecordRef: RecordRef; var OldRecordRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterServiceLineDelete(var ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeServiceLineVerifyChange(var NewServiceLine: Record "Service Line"; var OldServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowPostedSourceDoc', '', false, false)]
    local procedure OnShowPostedSourceDoc(PostedSourceDoc: Option; PostedSourceNo: Code[20]; WarehouseActivitySourceDocument: Enum "Warehouse Activity Source Document")
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
        WarehouseShipmentPostedSourceDocument: Enum "Warehouse Shipment Posted Source Document";
    begin
        if WarehouseActivitySourceDocument <> WarehouseActivitySourceDocument::"Service Order" then
            exit;

        WarehouseShipmentPostedSourceDocument := Enum::"Warehouse Shipment Posted Source Document".FromInteger(PostedSourceDoc);
        case WarehouseShipmentPostedSourceDocument of
            WarehouseShipmentPostedSourceDocument::"Posted Shipment":
                if ServiceShipmentHeader.Get(PostedSourceNo) then
                    Page.RunModal(Page::"Posted Service Shipment", ServiceShipmentHeader);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Request", 'OnShowSourceDocumentCard', '', false, false)]
    local procedure OnShowSourceDocumentCard(var WarehouseRequest: Record "Warehouse Request")
    var
        ServiceHeader: Record "Service Header";
    begin
        case WarehouseRequest."Source Document" of
            "Warehouse Request Source Document"::"Service Order":
                begin
                    ServiceHeader.Get(WarehouseRequest."Source Subtype", WarehouseRequest."Source No.");
                    PAGE.Run(PAGE::"Service Order", ServiceHeader);
                end;
        end;
    end;

    procedure ServiceHeaderVerifyChange(var NewServiceHeader: Record "Service Header"; var OldServiceHeader: Record "Service Header")
    var
        ServiceLine: Record "Service Line";
    begin
        if NewServiceHeader."Shipping Advice" = OldServiceHeader."Shipping Advice" then
            exit;

        ServiceLine.Reset();
        ServiceLine.SetRange("Document Type", OldServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", OldServiceHeader."No.");
        if ServiceLine.Find('-') then
            repeat
                WhseValidateSourceHeader.ChangeWarehouseLines(
                    DATABASE::"Service Line", ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.", ServiceLine."Line No.", 0,
                    NewServiceHeader."Shipping Advice");
            until ServiceLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Source Filter", 'OnSetFiltersOnSourceTables', '', false, false)]
    local procedure OnSetFiltersOnSourceTables(var WarehouseSourceFilter: Record "Warehouse Source Filter"; var GetSourceDocuments: Report "Get Source Documents"; var WarehouseRequest: Record "Warehouse Request")
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        ServiceHeader.SetFilter("Customer No.", WarehouseSourceFilter."Customer No. Filter");

        ServiceLine.SetRange(Type, ServiceLine.Type::Item);
        ServiceLine.SetFilter("No.", WarehouseSourceFilter."Item No. Filter");
        ServiceLine.SetFilter("Variant Code", WarehouseSourceFilter."Variant Code Filter");
        ServiceLine.SetFilter("Unit of Measure Code", WarehouseSourceFilter."Unit of Measure Filter");
        ServiceLine.SetFilter("Planned Delivery Date", WarehouseSourceFilter."Planned Delivery Date");
        ServiceLine.SetFilter("Shipping Agent Code", WarehouseSourceFilter."Shipping Agent Code Filter");
        ServiceLine.SetFilter("Shipping Agent Service Code", WarehouseSourceFilter."Shipping Agent Service Filter");

        OnSetFiltersOnSourceTablesOnBeforeSetServiceTableView(WarehouseSourceFilter, WarehouseRequest, ServiceHeader, ServiceLine);
        GetSourceDocuments.SetTableView(ServiceHeader);
        GetSourceDocuments.SetTableView(ServiceLine);
    end;

    procedure FromServiceLine2ShptLine(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; ServiceLine: Record "Service Line"): Boolean
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        ServiceHeader: Record "Service Header";
        WhseCreateSourceDocument: Codeunit "Whse.-Create Source Document";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeFromService2ShptLine(WarehouseShipmentHeader, ServiceLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");

        OnBeforeFromService2ShptLineOnAfterGetServiceHeader(ServiceHeader, WarehouseShipmentHeader);

        WarehouseShipmentLine.InitNewLine(WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.SetSource(DATABASE::"Service Line", ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.", ServiceLine."Line No.");
        ServiceLine.TestField("Unit of Measure Code");
        WarehouseShipmentLine.SetItemData(
            ServiceLine."No.", ServiceLine.Description, ServiceLine."Description 2", ServiceLine."Location Code",
            ServiceLine."Variant Code", ServiceLine."Unit of Measure Code", ServiceLine."Qty. per Unit of Measure",
            ServiceLine."Qty. Rounding Precision", ServiceLine."Qty. Rounding Precision (Base)");
        OnFromServiceLine2ShptLineOnAfterInitNewLine(WarehouseShipmentLine, WarehouseShipmentHeader, ServiceLine);
        WhseCreateSourceDocument.SetQtysOnShptLine(
            WarehouseShipmentLine, Abs(ServiceLine."Outstanding Quantity"), Abs(ServiceLine."Outstanding Qty. (Base)"));
        if ServiceLine."Document Type" = ServiceLine."Document Type"::Order then
            WarehouseShipmentLine."Due Date" := ServiceLine.GetDueDate();
        if WarehouseShipmentHeader."Shipment Date" = 0D then
            WarehouseShipmentLine."Shipment Date" := ServiceLine.GetShipmentDate()
        else
            WarehouseShipmentLine."Shipment Date" := WarehouseShipmentHeader."Shipment Date";
        WarehouseShipmentLine."Destination Type" := WarehouseShipmentLine."Destination Type"::Customer;
        WarehouseShipmentLine."Destination No." := ServiceLine."Customer No.";
        WarehouseShipmentLine."Shipping Advice" := ServiceHeader."Shipping Advice";
        if WarehouseShipmentLine."Location Code" = WarehouseShipmentHeader."Location Code" then
            WarehouseShipmentLine."Bin Code" := WarehouseShipmentHeader."Bin Code";
        if WarehouseShipmentLine."Bin Code" = '' then
            WarehouseShipmentLine."Bin Code" := ServiceLine."Bin Code";
        WhseCreateSourceDocument.UpdateShipmentLine(WarehouseShipmentLine, WarehouseShipmentHeader);
        OnFromServiceLine2ShptLineOnBeforeCreateShptLine(WarehouseShipmentLine, WarehouseShipmentHeader, ServiceHeader, ServiceLine);
        WhseCreateSourceDocument.CreateShipmentLine(WarehouseShipmentLine);
        OnAfterCreateShptLineFromServiceLine(WarehouseShipmentLine, WarehouseShipmentHeader, ServiceLine);
        exit(not WarehouseShipmentLine.HasErrorOccured());
    end;

    procedure CheckIfFromServiceLine2ShptLine(ServiceLine: Record "Service Line"): Boolean
    begin
        exit(CheckIfFromServiceLine2ShptLine(ServiceLine, "Reservation From Stock"::" "));
    end;

    procedure CheckIfFromServiceLine2ShptLine(ServiceLine: Record "Service Line"; ReservedFromStock: Enum "Reservation From Stock"): Boolean
    begin
        if not ServiceLine.CheckIfServiceLineMeetsReservedFromStockSetting(Abs(ServiceLine."Outstanding Qty. (Base)"), ReservedFromStock) then
            exit(false);

        ServiceLine.CalcFields("Whse. Outstanding Qty. (Base)");
        exit(
          (Abs(ServiceLine."Outstanding Qty. (Base)") > Abs(ServiceLine."Whse. Outstanding Qty. (Base)")) and
          (ServiceLine."Qty. to Consume (Base)" = 0));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateShptLineFromServiceLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFromService2ShptLine(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; ServiceLine: Record "Service Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFromServiceLine2ShptLineOnAfterInitNewLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFromServiceLine2ShptLineOnBeforeCreateShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFromService2ShptLineOnAfterGetServiceHeader(ServiceHeader: Record "Service Header"; var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetFiltersOnSourceTablesOnBeforeSetServiceTableView(var WarehouseSourceFilter: Record "Warehouse Source Filter"; var WarehouseRequest: Record "Warehouse Request"; var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Management", 'OnAfterGetSrcDocLineQtyOutstanding', '', false, false)]
    local procedure OnAfterGetSrcDocLineQtyOutstanding(SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; var QtyBaseOutstanding: Decimal; var QtyOutstanding: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        if SourceType = Database::"Service Line" then
            if ServiceLine.Get(SourceSubType, SourceNo, SourceLineNo) then begin
                QtyOutstanding := ServiceLine."Outstanding Quantity";
                QtyBaseOutstanding := ServiceLine."Outstanding Qty. (Base)";
            end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Management", 'OnAfterGetSourceDocumentType', '', false, false)]
    local procedure WhseManagementGetSourceDocumentType(SourceType: Integer; SourceSubType: Integer; var SourceDocument: Enum "Warehouse Journal Source Document"; var IsHandled: Boolean)
    begin
        if SourceType = Database::"Service Line" then begin
            SourceDocument := SourceDocument::"Serv. Order";
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Management", 'OnAfterGetJournalSourceDocument', '', false, false)]
    local procedure WhseManagementGetJournalSourceDocument(SourceType: Integer; SourceSubType: Integer; var SourceDocument: Enum "Warehouse Journal Source Document"; var IsHandled: Boolean)
    begin
        if SourceType = Database::"Service Line" then begin
            SourceDocument := SourceDocument::"Serv. Order";
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Management", 'OnAfterGetWhseRqstSourceDocument', '', false, false)]
    local procedure OnAfterGetWhseRqstSourceDocument(WhseJournalSourceDocument: Enum "Warehouse Journal Source Document"; var SourceDocument: Enum "Warehouse Request Source Document")
    begin
        case WhseJournalSourceDocument of
            WhseJournalSourceDocument::"Serv. Order":
                SourceDocument := "Warehouse Request Source Document"::"Service Order";
        end;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Create Pick", 'OnCheckSourceDocument', '', false, false)]
    local procedure CreatePickOnCheckSourceDocument(var PickWhseWkshLine: Record "Whse. Worksheet Line")
    var
        ServiceLine: Record "Service Line";
    begin
        if PickWhseWkshLine."Source Type" = Database::"Service Line" then begin
            ServiceLine.SetRange("Document Type", PickWhseWkshLine."Source Subtype");
            ServiceLine.SetRange("Document No.", PickWhseWkshLine."Source No.");
            ServiceLine.SetRange("Line No.", PickWhseWkshLine."Source Line No.");
            if ServiceLine.IsEmpty() then
                Error(WhseManagement.GetSourceDocumentDoesNotExistErr(), ServiceLine.TableCaption(), ServiceLine.GetFilters());
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Cross-Dock Management", 'OnCalcCrossDockToServiceOrder', '', false, false)]
    local procedure OnCalcCrossDockToServiceOrder(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer; var sender: Codeunit "Whse. Cross-Dock Management")
    begin
        CalcCrossDockToServiceOrder(WhseCrossDockOpportunity, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo, sender);
    end;

    local procedure CalcCrossDockToServiceOrder(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer; var sender: Codeunit "Whse. Cross-Dock Management")
    var
        ServiceLine: Record "Service Line";
        WarehouseRequest: Record "Warehouse Request";
        QtyOnPickBase: Decimal;
        QtyPickedBase: Decimal;
        IsHandled: Boolean;
    begin
#if not CLEAN25
        IsHandled := false;
        sender.RunOnBeforeCalcCrossDockToServiceOrder(WhseCrossDockOpportunity, ItemNo, VariantCode, LocationCode, CrossDockDate, QtyOnPick, QtyPicked, LineNo, IsHandled);
        if IsHandled then
            exit;
#endif
        IsHandled := false;
        OnBeforeCalcCrossDockToServiceOrder(WhseCrossDockOpportunity, ItemNo, VariantCode, LocationCode, CrossDockDate, QtyOnPick, QtyPicked, LineNo, IsHandled);
        if IsHandled then
            exit;

        ServiceLine.SetRange("Document Type", "Service Document Type"::Order);
        ServiceLine.SetRange(Type, "Service Line Type"::Item);
        ServiceLine.SetRange("No.", ItemNo);
        ServiceLine.SetRange("Variant Code", VariantCode);
        ServiceLine.SetRange("Location Code", LocationCode);
        ServiceLine.SetRange("Needed by Date", 0D, CrossDockDate);
        ServiceLine.SetFilter("Outstanding Qty. (Base)", '>0');
#if not CLEAN25
        sender.RunOnCalcCrossDockToServiceOrderOnAfterServiceLineSetFilters(ServiceLine, WhseCrossDockOpportunity, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
#endif
        OnCalcCrossDockToServiceOrderOnAfterServiceLineSetFilters(ServiceLine, WhseCrossDockOpportunity, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
        if ServiceLine.Find('-') then
            repeat
                if WarehouseRequest.Get(
                    WarehouseRequest.Type::Outbound, ServiceLine."Location Code", Database::"Service Line", ServiceLine."Document Type", ServiceLine."Document No.") and
                   (WarehouseRequest."Document Status" = WarehouseRequest."Document Status"::Released)
                then begin
                    sender.CalculatePickQty(
                        Database::"Service Line", ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.", ServiceLine."Line No.",
                        QtyOnPick, QtyOnPickBase, QtyPicked, QtyPickedBase, ServiceLine.Quantity, ServiceLine."Quantity (Base)",
                        ServiceLine."Outstanding Quantity", ServiceLine."Outstanding Qty. (Base)");
#if not CLEAN25
                    sender.RunOnCalcCrossDockToServiceOrderOnBeforeInsertCrossDockLine(ServiceLine, WhseCrossDockOpportunity, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
#endif
                    OnCalcCrossDockToServiceOrderOnBeforeInsertCrossDockLine(ServiceLine, WhseCrossDockOpportunity, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
                    sender.InsertCrossDockOpp(
                        WhseCrossDockOpportunity,
                        Database::"Service Line", ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.", ServiceLine."Line No.", 0,
                        ServiceLine.Quantity, ServiceLine."Quantity (Base)",
                        QtyOnPick, QtyOnPickBase, QtyPicked, QtyPickedBase,
                        ServiceLine."Unit of Measure Code", ServiceLine."Qty. per Unit of Measure", ServiceLine."Needed by Date",
                        ServiceLine."No.", ServiceLine."Variant Code", LineNo);
#if not CLEAN25
                    sender.RunOnCalcCrossDockToServiceOrderOnAfterInsertCrossDockLine(ServiceLine, WhseCrossDockOpportunity, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
#endif
                    OnCalcCrossDockToServiceOrderOnAfterInsertCrossDockLine(ServiceLine, WhseCrossDockOpportunity, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
                end;
            until ServiceLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcCrossDockToServiceOrder(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; var QtyOnPick: Decimal; var QtyPicked: Decimal; LineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCrossDockToServiceOrderOnAfterServiceLineSetFilters(var ServiceLine: Record "Service Line"; var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCrossDockToServiceOrderOnAfterInsertCrossDockLine(ServiceLine: Record "Service Line"; var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCrossDockToServiceOrderOnBeforeInsertCrossDockLine(ServiceLine: Record "Service Line"; var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Integration Management", 'OnCheckBinTypeAndCode', '', false, false)]
    local procedure OnCheckBinTypeAndCode(BinType: Record "Bin Type"; AdditionalIdentifier: Option)
    begin
        if AdditionalIdentifier = "Service Document Type"::Invoice.AsInteger() then
            BinType.TestField(Pick, true);
    end;

    // Report "Create Warehouse Shipment"

    [EventSubscriber(ObjectType::Report, Report::"Create Warehouse Shipment", 'OnWarehouseRequestOnAfterGetRecord', '', false, false)]
    local procedure OnWarehouseRequestOnAfterGetRecord(WarehouseRequest: Record "Warehouse Request"; sender: Report "Create Warehouse Shipment")
    var
        ServiceHeader: Record "Service Header";
    begin
        if WarehouseRequest."Source Document" <> WarehouseRequest."Source Document"::"Service Order" then
            exit;

        ServiceHeader.Get(ServiceHeader."Document Type"::Order, WarehouseRequest."Source No.");
        if ServiceHeader."Release Status" <> ServiceHeader."Release Status"::"Released to Ship" then
            exit;

        sender.CreateWarehouseShipmentFromWhseRequest(WarehouseRequest);
    end;

    // Table "Warehouse Shipment Line"

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Shipment Line", 'OnCheckSourceDocLineQtyOnSetQtyOutstandingBase', '', false, false)]
    local procedure OnCheckSourceDocLineQtyOnSetQtyOutstandingBase(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; QuantityBase: Decimal; WhseQtyOutstandingBase: Decimal; var QtyOutstandingBase: Decimal)
    var
        ServiceLine: Record "Service Line";
    begin
        case WarehouseShipmentLine."Source Type" of
            Database::"Service Line":
                begin
                    ServiceLine.Get(WarehouseShipmentLine."Source Subtype", WarehouseShipmentLine."Source No.", WarehouseShipmentLine."Source Line No.");
                    if Abs(ServiceLine."Outstanding Qty. (Base)") < WhseQtyOutstandingBase + QuantityBase then
                        WarehouseShipmentLine.FieldError(Quantity, StrSubstNo(MustNotBeGreaterErr, WarehouseShipmentLine.CalcQty(ServiceLine."Outstanding Qty. (Base)" - WhseQtyOutstandingBase)));
                    QtyOutstandingBase := Abs(ServiceLine."Outstanding Qty. (Base)");
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Shipment Line", 'OnOpenItemTrackingLines', '', false, false)]
    local procedure OnOpenItemTrackingLines(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    var
        ServiceLine: Record "Service Line";
        ServiceLineReserve: Codeunit "Service Line-Reserve";
    begin
        case WarehouseShipmentLine."Source Type" of
            Database::"Service Line":
                if ServiceLine.Get(WarehouseShipmentLine."Source Subtype", WarehouseShipmentLine."Source No.", WarehouseShipmentLine."Source Line No.") then
                    ServiceLineReserve.CallItemTracking(ServiceLine);
        end;
    end;

    // Codeunit "Whse. Undo Quantity"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Undo Quantity", 'OnAfterIsShipmentLine', '', false, false)]
    local procedure OnAfterIsSalesShipmentLine(UndoType: Integer; var IsShipment: Boolean)
    begin
        IsShipment := IsShipment or (UndoType = Database::"Service Shipment Line");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Source Filter", 'OnAfterCheckType', '', false, false)]
    local procedure OnAfterCheckType(var WarehouseSourceFilter: Record "Warehouse Source Filter")
    begin
        if WarehouseSourceFilter.Type = WarehouseSourceFilter.Type::Inbound then
            WarehouseSourceFilter."Service Orders" := false;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Source Filter", 'OnSetFiltersOnAfterSetSourceFilters', '', false, false)]
    local procedure OnSetFiltersOnAfterSetSourceFilters(var WarehouseSourceFilter: Record "Warehouse Source Filter"; var WarehouseRequest: Record "Warehouse Request")
    begin
        if WarehouseSourceFilter."Service Orders" then begin
            WarehouseRequest."Source Document" := WarehouseRequest."Source Document"::"Service Order";
            AddFilter(WarehouseSourceFilter."Source Document", Format(WarehouseRequest."Source Document"));
        end;
    end;

    local procedure AddFilter(var CodeField: Code[250]; NewFilter: Text[100])
    begin
        if CodeField = '' then
            CodeField := NewFilter
        else
            CodeField := CodeField + '|' + NewFilter;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Posting Selection Management", 'OnAfterGetInvoicePostingPolicy', '', false, false)]
    local procedure OnAfterGetInvoicePostingPolicy(SourceDocument: Enum "Warehouse Activity Source Document"; var Ship: Boolean; var Invoice: Boolean)
    var
        UserSetupManagement: Codeunit "User Setup Management";
        Consume: Boolean;
    begin
        if SourceDocument = SourceDocument::"Service Order" then
            UserSetupManagement.GetServiceInvoicePostingPolicy(Ship, Consume, Invoice);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnAfterGetWhseJnlLineBinCode', '', false, false)]
    local procedure OnAfterGetWhseJnlLineBinCode(BinCode: Code[20]; SourceCode: Code[10]; var Result: Code[20]; SourceCodeSetup: Record "Source Code Setup")
    begin
        if BinCode <> '' then
            if SourceCode = SourceCodeSetup."Service Management" then
                Result := BinCode;
    end;
}
