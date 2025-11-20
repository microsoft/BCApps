// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

using Microsoft.Foundation.Company;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Setup;
using System.IO;

codeunit 99000889 AvailabilityManagement
{
    Permissions = TableData "Order Promising Line" = rimd;

    trigger OnRun()
    begin
    end;

    var
        CompanyInfo: Record "Company Information";
        InvtSetup: Record "Inventory Setup";
        Item: Record Item;
        TempRecordBuffer: Record System.IO."Record Buffer" temporary;
        AvailableToPromise: Codeunit "Available to Promise";
        UOMMgt: Codeunit "Unit of Measure Management";
        CaptionText: Text;
        HasGotCompanyInfo: Boolean;

#pragma warning disable AA0074
        Text001: Label 'The Check-Avail. Period Calc. field cannot be empty in the Company Information card.';
#pragma warning restore AA0074
        IncorrectSourceTableErr: Label 'Incorrect source record table: %1', Comment = '%1 - table name';

    procedure GetCaption(): Text
    begin
        exit(CaptionText);
    end;

    procedure SetSourceRecord(var OrderPromisingLine: Record "Order Promising Line"; SourceRecordVar: Variant)
    var
        SourceRecRef: RecordRef;
        TableID: Integer;
    begin
        SourceRecRef.GetTable(SourceRecordVar);
        TableID := SourceRecRef.Number;

        OnSetSourceRecord(OrderPromisingLine, TableID, SourceRecordVar, CaptionText);

        if CaptionText = '' then
            error(IncorrectSourceTableErr, SourceRecRef.Name);
    end;

#if not CLEAN25
    [Obsolete('Moved to codeunit ServAvailabilityMgt', '25.0')]
    procedure SetSalesHeader(var OrderPromisingLine: Record "Order Promising Line"; var SalesHeader: Record Microsoft.Sales.Document."Sales Header")
    var
        SalesAvailabilityMgt: Codeunit Microsoft.Sales.Document."Sales Availability Mgt.";
    begin
        SalesAvailabilityMgt.SetSalesHeader(OrderPromisingLine, SalesHeader, CaptionText);
    end;
#endif

#if not CLEAN25
    [Obsolete('Moved to codeunit ServAvailabilityMgt', '25.0')]
    procedure SetServHeader(var OrderPromisingLine: Record "Order Promising Line"; var ServHeader: Record Microsoft.Service.Document."Service Header")
    var
        ServAvailabilityMgt: Codeunit Microsoft.Service.Document."Serv. Availability Mgt.";
    begin
        ServAvailabilityMgt.SetServiceHeader(OrderPromisingLine, ServHeader, CaptionText);
    end;
#endif

#if not CLEAN25
    [Obsolete('Moved to codeunit JobPlanningAvailabilityMgt', '25.0')]
    procedure SetJob(var OrderPromisingLine: Record "Order Promising Line"; var Job: Record Microsoft.Projects.Project.Job.Job)
    var
        JobPlanningAvailabilityMgt: Codeunit Microsoft.Projects.Project.Planning."Job Planning Availability Mgt.";
    begin
        JobPlanningAvailabilityMgt.SetJob(OrderPromisingLine, Job, CaptionText);
    end;
#endif

    internal procedure InsertPromisingLine(var OrderPromisingLine: Record "Order Promising Line"; UnavailableQty: Decimal)
    var
        LineItem: Record Item;
        ItemVariant: Record "Item Variant";
    begin
        OrderPromisingLine."Unavailable Quantity (Base)" := UnavailableQty;
        if OrderPromisingLine."Unavailable Quantity (Base)" > 0 then begin
            OrderPromisingLine."Required Quantity (Base)" := OrderPromisingLine."Unavailable Quantity (Base)";
            GetCompanyInfo();
            if Format(CompanyInfo."Check-Avail. Period Calc.") <> '' then
                OrderPromisingLine."Unavailable Quantity (Base)" := -CalcAvailableQty(OrderPromisingLine)
            else
                Error(Text001);
            if InvtSetup."Location Mandatory" then
                OrderPromisingLine.TestField("Location Code");
            LineItem.SetLoadFields("Variant Mandatory if Exists");
            if LineItem.Get(OrderPromisingLine."Item No.") then
                if LineItem.IsVariantMandatory() then begin
                    OrderPromisingLine.TestField("Variant Code");
                    ItemVariant.SetLoadFields(Blocked);
                    ItemVariant.Get(Item."No.", OrderPromisingLine."Variant Code");
                    ItemVariant.TestField(Blocked, false);
                end;
            if OrderPromisingLine."Unavailable Quantity (Base)" < 0 then
                OrderPromisingLine."Unavailable Quantity (Base)" := 0;
            if OrderPromisingLine."Unavailable Quantity (Base)" > OrderPromisingLine."Required Quantity (Base)" then
                OrderPromisingLine."Unavailable Quantity (Base)" := OrderPromisingLine."Required Quantity (Base)";
        end else
            OrderPromisingLine."Unavailable Quantity (Base)" := 0;
        if OrderPromisingLine."Qty. per Unit of Measure" = 0 then
            OrderPromisingLine."Qty. per Unit of Measure" := 1;
        OrderPromisingLine."Unavailable Quantity" :=
          Round(OrderPromisingLine."Unavailable Quantity (Base)" / OrderPromisingLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
        OrderPromisingLine."Required Quantity" :=
          Round(OrderPromisingLine."Required Quantity (Base)" / OrderPromisingLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision());
        OnBeforeOrderPromisingLineInsert(OrderPromisingLine);
        OrderPromisingLine.Insert();
    end;

    procedure CalcAvailableQty(var OrderPromisingLine: Record "Order Promising Line"): Decimal
    var
        GrossRequirement: Decimal;
        ScheduledReceipt: Decimal;
        AvailabilityDate: Date;
    begin
        GetCompanyInfo();

        if Item."No." <> OrderPromisingLine."Item No." then
            Item.Get(OrderPromisingLine."Item No.");
        Item.SetRange("Variant Filter", OrderPromisingLine."Variant Code");
        Item.SetRange("Location Filter", OrderPromisingLine."Location Code");
        Item.SetRange("Date Filter", 0D, OrderPromisingLine."Original Shipment Date");

        if OrderPromisingLine."Original Shipment Date" <> 0D then
            AvailabilityDate := OrderPromisingLine."Original Shipment Date"
        else
            AvailabilityDate := WorkDate();

        OrderPromisingLine."Unavailability Date" :=
          AvailableToPromise.GetPeriodEndingDate(
            CalcDate(CompanyInfo."Check-Avail. Period Calc.", AvailabilityDate), CompanyInfo."Check-Avail. Time Bucket");

        AvailableToPromise.SetPromisingReqShipDate(OrderPromisingLine);
        exit(
          AvailableToPromise.CalcQtyAvailabletoPromise(
            Item, GrossRequirement, ScheduledReceipt, AvailabilityDate,
            CompanyInfo."Check-Avail. Time Bucket", CompanyInfo."Check-Avail. Period Calc."));
    end;

    procedure CalcCapableToPromise(var OrderPromisingLine: Record "Order Promising Line"; var OrderPromisingID: Code[20])
    var
        LastValidLine: Integer;
        IsHandled: Boolean;
    begin
        GetCompanyInfo();

        IsHandled := false;
        OnBeforeCalcCapableToPromise(OrderPromisingLine, CompanyInfo, OrderPromisingID, LastValidLine, IsHandled);
        if IsHandled then
            exit;

        LastValidLine := 1;
        if OrderPromisingLine.Find('-') then
            repeat
                OnCalcCapableToPromiseLine(OrderPromisingLine, CompanyInfo, OrderPromisingID, LastValidLine);
                OnAfterCaseCalcCapableToPromise(OrderPromisingLine, CompanyInfo, OrderPromisingID, LastValidLine);
                OrderPromisingLine.Modify();
                CreateReservations(OrderPromisingLine);
            until OrderPromisingLine.Next() = 0;

        OnAfterCalcCapableToPromise(OrderPromisingID);
    end;

    procedure CalcAvailableToPromise(var OrderPromisingLine: Record "Order Promising Line")
    begin
        GetCompanyInfo();
        OrderPromisingLine.SetCurrentKey(OrderPromisingLine."Requested Shipment Date");
        if OrderPromisingLine.Find('-') then
            repeat
                Clear(OrderPromisingLine."Earliest Shipment Date");
                Clear(OrderPromisingLine."Planned Delivery Date");
                CalcAvailableToPromiseLine(OrderPromisingLine);
            until OrderPromisingLine.Next() = 0;
    end;

    local procedure CalcAvailableToPromiseLine(var OrderPromisingLine: Record "Order Promising Line")
    var
        SourceSalesLine: Record Microsoft.Sales.Document."Sales Line";
        NeededDate: Date;
        FeasibleDate: Date;
        AvailQty: Decimal;
        FeasibleDateFound: Boolean;
    begin
        if Item."No." <> OrderPromisingLine."Item no." then
            Item.Get(OrderPromisingLine."Item No.");
        Item.SetRange("Variant Filter", OrderPromisingLine."Variant Code");
        Item.SetRange("Location Filter", OrderPromisingLine."Location Code");
        OnCalcAvailableToPromiseLineOnAfterSetFilters(Item, OrderPromisingLine);
        if ShouldCalculateAvailableToPromise(OrderPromisingLine) then begin
            if OrderPromisingLine."Requested Shipment Date" <> 0D then
                NeededDate := OrderPromisingLine."Requested Shipment Date"
            else
                NeededDate := WorkDate();
            AvailableToPromise.SetOriginalShipmentDate(OrderPromisingLine);

            OnCalcAvailableToPromiseLineOnAfterSetOriginalShipmentDate(OrderPromisingLine, Item, CompanyInfo, AvailableToPromise);

            FeasibleDateFound := false;
            if OrderPromisingLine."Source Type" = OrderPromisingLine."Source Type"::Sales then
                if SourceSalesLine.Get(OrderPromisingLine."Source Subtype", OrderPromisingLine."Source ID", OrderPromisingLine."Source Line No.") then
                    if SourceSalesLine."Special Order" then begin
                        FeasibleDate := GetExpectedReceiptDateFromSpecialOrder(SourceSalesLine);
                        FeasibleDateFound := true;
                    end;

            if not FeasibleDateFound then
                if OrderPromisingLine."Required Quantity" = 0 then begin
                    FeasibleDate := OrderPromisingLine."Original Shipment Date";
                    FeasibleDateFound := true;
                end;

            if not FeasibleDateFound then begin
                GetCompanyInfo();
                FeasibleDate := AvailableToPromise.CalcEarliestAvailabilityDate(
                    Item, OrderPromisingLine.Quantity, NeededDate, OrderPromisingLine.Quantity, OrderPromisingLine."Original Shipment Date", AvailQty,
                    CompanyInfo."Check-Avail. Time Bucket", CompanyInfo."Check-Avail. Period Calc.");
            end;

            if (FeasibleDate <> 0D) and (FeasibleDate < OrderPromisingLine."Requested Shipment Date") then
                if GetRequestedDeliveryDate(OrderPromisingLine) <> 0D then
                    FeasibleDate := OrderPromisingLine."Requested Shipment Date";
            OrderPromisingLine.Validate(OrderPromisingLine."Earliest Shipment Date", FeasibleDate);
        end;
        OnCalcAvailableToPromiseLineOnBeforeModify(OrderPromisingLine);
        OrderPromisingLine.Modify();
    end;

    local procedure ShouldCalculateAvailableToPromise(var OrderPromisingLine: Record "Order Promising Line") ShouldCalculate: Boolean
    begin
        ShouldCalculate := OrderPromisingLine."Source Type" in [OrderPromisingLine."Source Type"::Sales, OrderPromisingLine."Source Type"::Job];

        OnAfterShouldCalculateAvailableToPromise(OrderPromisingLine, ShouldCalculate);
    end;

    local procedure GetExpectedReceiptDateFromSpecialOrder(SalesLine: Record Microsoft.Sales.Document."Sales Line"): Date
    var
        PurchaseLine: Record Microsoft.Purchases.Document."Purchase Line";
    begin
        if PurchaseLine.Get(
             PurchaseLine."Document Type"::Order, SalesLine."Special Order Purchase No.", SalesLine."Special Order Purch. Line No.")
        then
            exit(PurchaseLine."Expected Receipt Date");
        exit(0D);
    end;

    local procedure GetRequestedDeliveryDate(OrderPromisingLine: Record "Order Promising Line") RequestedDeliveryDate: Date
    var
    begin
        RequestedDeliveryDate := 0D;
        OnGetRequestedDeliveryDate(OrderPromisingLine, RequestedDeliveryDate);
        exit(RequestedDeliveryDate);
    end;

    procedure UpdateSource(var OrderPromisingLine: Record "Order Promising Line")
    begin
        if OrderPromisingLine.Find('-') then
            repeat
                UpdateSourceLine(OrderPromisingLine);
            until OrderPromisingLine.Next() = 0;
    end;

    local procedure UpdateSourceLine(var OrderPromisingLine2: Record "Order Promising Line")
    begin
        OnUpdateSourceLine(OrderPromisingLine2);

        OnAfterUpdateSourceLine(OrderPromisingLine2);
    end;

    local procedure GetCompanyInfo()
    begin
        if HasGotCompanyInfo then
            exit;
        HasGotCompanyInfo := CompanyInfo.Get() and InvtSetup.Get();
    end;

    local procedure CreateReservations(var OrderPromisingLine: Record "Order Promising Line")
    var
        ReqLine: Record "Requisition Line";
        ReservQty: Decimal;
        ReservQtyBase: Decimal;
        NeededQty: Decimal;
        NeededQtyBase: Decimal;
    begin
        OnCreateReservationsOnCalcNeededQuantity(OrderPromisingLine, NeededQty, NeededQtyBase);

        OnCreateReservationsAfterFirstCASE(OrderPromisingLine, NeededQty, NeededQtyBase);

        ReqLine.SetCurrentKey("Order Promising ID", "Order Promising Line ID", "Order Promising Line No.");
        ReqLine.SetRange("Order Promising ID", OrderPromisingLine."Source ID");
        ReqLine.SetRange("Order Promising Line ID", OrderPromisingLine."Source Line No.");
        ReqLine.SetRange(Type, ReqLine.Type::Item);
        ReqLine.SetRange("No.", OrderPromisingLine."Item No.");
        if ReqLine.FindFirst() then begin
            if ReqLine."Quantity (Base)" > NeededQtyBase then begin
                ReservQty := NeededQty;
                ReservQtyBase := NeededQtyBase
            end else begin
                ReservQty := ReqLine.Quantity;
                ReservQtyBase := ReqLine."Quantity (Base)";
            end;

            OnCreateReservationsOnBindToTracking(OrderPromisingLine, ReqLine, ReservQty, ReservQtyBase, TempRecordBuffer);

            OnCreateReservationsAfterSecondCASE(OrderPromisingLine, ReqLine, ReservQty, ReservQtyBase);
        end;
    end;

    procedure CancelReservations()
    begin
        OnCancelReservations(TempRecordBuffer);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCaseCalcCapableToPromise(var OrderPromisingLine: Record "Order Promising Line"; var CompanyInfo: Record "Company Information"; var OrderPromisingID: Code[20]; var LastValidLine: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateSourceLine(var OrderPromisingLine2: Record "Order Promising Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOrderPromisingLineInsert(var OrderPromisingLine: Record "Order Promising Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAvailableToPromiseLineOnAfterSetFilters(var Item: Record Item; var OrderPromisingLine: Record "Order Promising Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAvailableToPromiseLineOnBeforeModify(var OrderPromisingLine: Record "Order Promising Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateReservationsAfterFirstCASE(var OrderPromisingLine: Record "Order Promising Line"; var NeededQty: Decimal; var NeededQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateReservationsAfterSecondCASE(var OrderPromisingLine: Record "Order Promising Line"; var ReqLine: Record "Requisition Line"; var ReservQty: Decimal; var ReservQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcCapableToPromise(var OrderPromisingLine: Record "Order Promising Line"; var CompanyInformation: Record "Company Information"; var OrderPromisingID: Code[20]; var LastValidLine: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnSetSourceRecord(var OrderPromisingLine: Record "Order Promising Line"; TableID: Integer; var SourceRecordVar: Variant; var CaptionText: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCapableToPromiseLine(var OrderPromisingLine: Record "Order Promising Line"; var CompanyInfo: Record "Company Information"; var OrderPromisingID: Code[20]; var LastValidLine: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetRequestedDeliveryDate(var OrderPromisingLine: Record "Order Promising Line"; var RequestedDeliveryDate: Date)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateSourceLine(var OrderPromisingLine: Record "Order Promising Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateReservationsOnCalcNeededQuantity(var OrderPromisingLine: Record "Order Promising Line"; var NeededQty: Decimal; var NeededQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateReservationsOnBindToTracking(var OrderPromisingLine: Record "Order Promising Line"; ReqLine: Record "Requisition Line"; ReservQty: Decimal; ReservQtyBase: Decimal; var TempRecordBuffer: Record "Record Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCancelReservations(var TempRecordBuffer: Record "Record Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShouldCalculateAvailableToPromise(var OrderPromisingLine: Record "Order Promising Line"; var ShouldCalculate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAvailableToPromiseLineOnAfterSetOriginalShipmentDate(var OrderPromisingLine: Record "Order Promising Line"; Item: Record Item; CompanyInformation: Record "Company Information"; var AvailableToPromise: Codeunit "Available to Promise")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcCapableToPromise(OrderPromisingID: Code[20]);
    begin
    end;
}

