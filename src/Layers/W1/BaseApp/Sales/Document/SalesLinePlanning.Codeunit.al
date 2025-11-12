// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;

codeunit 99000850 "Sales Line-Planning"
{
    var
        SalesHeader: Record "Sales Header";
        SalesTxt: Label 'Sales';

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnSetDemandTypeFromUnplannedDemand', '', false, false)]
    local procedure ReqLineOnSetDemandTypeFromUnplannedDemand(var RequisitionLine: Record "Requisition Line"; UnplannedDemand: Record "Unplanned Demand")
    begin
        if UnplannedDemand."Demand Type" = UnplannedDemand."Demand Type"::Sales then
            RequisitionLine."Demand Type" := Database::"Sales Line";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Unplanned Demand", 'OnValidateDemandOrderNoOnGetSourceFields', '', false, false)]
    local procedure OnValidateDemandOrderNoOnGetSourceFields(var UnplannedDemand: Record "Unplanned Demand")
    var
        SalesHeader: Record "Sales Header";
    begin
        case UnplannedDemand."Demand Type" of
            UnplannedDemand."Demand Type"::Sales:
                begin
                    SalesHeader.Get(UnplannedDemand."Demand SubType", UnplannedDemand."Demand Order No.");
                    UnplannedDemand."Sell-to Customer No." := SalesHeader."Sell-to Customer No.";
                    UnplannedDemand.Description := SalesHeader."Sell-to Customer Name";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Carry Out Action Msg. - Plan.", 'OnCheckDemandType', '', false, false)]
    local procedure CarryOutActionMsgPlanOnCheckDemandType(RequisitionLine: Record "Requisition Line")
    var
        SalesLine: Record "Sales Line";
    begin
        if RequisitionLine."Demand Type" = Database::"Sales Line" then begin
            SalesLine.Get(RequisitionLine."Demand Subtype", RequisitionLine."Demand Order No.", RequisitionLine."Demand Line No.");
            SalesLine.TestField(Type, SalesLine.Type::Item);
            if not ((RequisitionLine."Demand Date" = WorkDate()) and (SalesLine."Shipment Date" in [0D, WorkDate()])) then
                RequisitionLine.TestField("Demand Date", SalesLine."Shipment Date");
            RequisitionLine.TestField("No.", SalesLine."No.");
            RequisitionLine.TestField("Qty. per UOM (Demand)", SalesLine."Qty. per Unit of Measure");
            RequisitionLine.TestField("Variant Code", SalesLine."Variant Code");
            RequisitionLine.TestField("Location Code", SalesLine."Location Code");
            SalesLine.CalcFields("Reserved Qty. (Base)");
            RequisitionLine.TestField(
                RequisitionLine."Demand Quantity (Base)",
                -SalesLine.SignedXX(SalesLine."Outstanding Qty. (Base)" - SalesLine."Reserved Qty. (Base)"))
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Order Planning Mgt.", 'OnInsertDemandLinesOnCopyItemTracking', '', false, false)]
    local procedure OnInsertDemandLinesOnCopyItemTracking(var RequisitionLine: Record "Requisition Line"; UnplannedDemand: Record "Unplanned Demand")
    var
        SalesLine: Record "Sales Line";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
    begin
        if UnplannedDemand."Demand Type" = UnplannedDemand."Demand Type"::Sales then begin
            SalesLine.Get(UnplannedDemand."Demand SubType", UnplannedDemand."Demand Order No.", UnplannedDemand."Demand Line No.");
            ItemTrackingManagement.CopyItemTracking(SalesLine.RowID1(), RequisitionLine.RowID1(), true);
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnBeforeShowDemandOrder', '', false, false)]
    local procedure OrderPlanningOnBeforeShowDemandOrder(RequisitionLine: Record "Requisition Line")
    begin
        if RequisitionLine."Demand Type" = Database::"Sales Line" then begin
            SalesHeader.Get(RequisitionLine."Demand Subtype", RequisitionLine."Demand Order No.");
            case SalesHeader."Document Type" of
                SalesHeader."Document Type"::Order:
                    PAGE.Run(PAGE::"Sales Order", SalesHeader);
                SalesHeader."Document Type"::"Return Order":
                    PAGE.Run(PAGE::"Sales Return Order", SalesHeader);
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnSetRecDemandFilter', '', false, false)]
    local procedure OnSetRecDemandFilter(var RequisitionLine: Record "Requisition Line"; DemandOrderFilter: Enum "Demand Order Source Type")
    begin
        if DemandOrderFilter = DemandOrderFilter::"Service Demand" then begin
            RequisitionLine.SetRange("Demand Type", Database::"Sales Line");
            RequisitionLine.SetCurrentKey("User ID", "Demand Type", "Worksheet Template Name", "Journal Batch Name", "Line No.");
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnAfterStatusTextOnFormat', '', false, false)]
    local procedure OnAfterStatusTextOnFormat(var RequisitionLine: Record "Requisition Line"; var Text: Text)
    begin
        if RequisitionLine."Demand Line No." = 0 then
            if RequisitionLine."Demand Type" = Database::"Sales Line" then
                Text := Format(Enum::"Sales Document Status".FromInteger(RequisitionLine.Status));
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnAfterDemandTypeTextOnFormat', '', false, false)]
    local procedure OnAfterDemandTypeTextOnFormat(var RequisitionLine: Record "Requisition Line"; var Text: Text)
    begin
        if RequisitionLine."Demand Line No." = 0 then
            if RequisitionLine."Demand Type" = Database::"Sales Line" then
                Text := SalesTxt;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnAfterDemandSubtypeTextOnFormat', '', false, false)]
    local procedure OnAfterDemandSubtypeTextOnFormat(var RequisitionLine: Record "Requisition Line"; var Text: Text)
    begin
        if RequisitionLine."Demand Type" = Database::"Sales Line" then
            Text := Format(Enum::"Sales Document Type".FromInteger(RequisitionLine."Demand Subtype"));
    end;
}