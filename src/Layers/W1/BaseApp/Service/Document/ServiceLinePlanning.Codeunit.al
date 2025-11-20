// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;

codeunit 99000853 "Service Line-Planning"
{
    Permissions = tabledata "Service Header" = r;

    var
        ServiceTxt: Label 'Service';

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnSetDemandTypeFromUnplannedDemand', '', false, false)]
    local procedure ReqLineOnSetDemandTypeFromUnplannedDemand(var RequisitionLine: Record "Requisition Line"; UnplannedDemand: Record "Unplanned Demand")
    begin
        if UnplannedDemand."Demand Type" = UnplannedDemand."Demand Type"::Service then
            RequisitionLine."Demand Type" := Database::"Service Line";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Unplanned Demand", 'OnValidateDemandOrderNoOnGetSourceFields', '', false, false)]
    local procedure OnValidateDemandOrderNoOnGetSourceFields(var UnplannedDemand: Record "Unplanned Demand")
    var
        ServiceHeader: Record "Service Header";
    begin
        case UnplannedDemand."Demand Type" of
            UnplannedDemand."Demand Type"::Service:
                begin
                    ServiceHeader.Get(UnplannedDemand."Demand SubType", UnplannedDemand."Demand Order No.");
                    UnplannedDemand."Sell-to Customer No." := ServiceHeader."Customer No.";
                    UnplannedDemand.Description := ServiceHeader.Name;
                end;
        end;
    end;

    // Codeunit "Get Unplanned Demand"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Get Unplanned Demand", 'OnBeforeOpenWindow', '', false, false)]
    local procedure OnBeforeOpenWindow(var RecordCounter: Integer)
    var
        ServiceLine: Record "Service Line";
    begin
        ServiceLine.SetRange("Document Type", "Service Document Type"::Order);
        RecordCounter += ServiceLine.Count();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Get Unplanned Demand", 'OnAfterGetUnplanned', '', false, false)]
    local procedure OnAfterGetUnplanned(var UnplannedDemand: Record "Unplanned Demand"; ItemFilter: TextBuilder; var sender: Codeunit "Get Unplanned Demand")
    begin
        GetUnplannedServLine(UnplannedDemand, ItemFilter, sender);
    end;

    local procedure GetUnplannedServLine(var UnplannedDemand: Record "Unplanned Demand"; ItemFilter: TextBuilder; var sender: Codeunit "Get Unplanned Demand")
    var
        ServiceHeader2: Record "Service Header";
        ServiceLine: Record "Service Line";
#if not CLEAN25
        GetUnplannedDemand: Codeunit "Get Unplanned Demand";
#endif
        DemandQtyBase: Decimal;
    begin
        OnBeforeGetUnplannedServLine(UnplannedDemand, ServiceLine);
#if not CLEAN25
        GetUnplannedDemand.RunOnBeforeGetUnplannedServLine(UnplannedDemand, ServiceLine);
#endif

        ServiceLine.SetRange("Document Type", "Service Document Type"::Order);
        ServiceLine.SetFilter("No.", ItemFilter.ToText());
        if ServiceLine.FindSet() then
            repeat
                sender.UpdateWindow();
                DemandQtyBase := GetServLineNeededQty(ServiceLine);
                if DemandQtyBase > 0 then begin
                    if not ((ServiceLine."Document Type".AsInteger() = UnplannedDemand."Demand SubType") and
                            (ServiceLine."Document No." = UnplannedDemand."Demand Order No."))
                    then begin
                        ServiceHeader2.Get(ServiceLine."Document Type", ServiceLine."Document No.");
                        sender.InsertUnplannedDemand(
                          UnplannedDemand, UnplannedDemand."Demand Type"::Service, ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.", ServiceHeader2.Status.AsInteger());
                        OnGetUnplannedServLineOnAfterInsertUnplannedDemand(UnplannedDemand);
#if not CLEAN25
                        GetUnplannedDemand.RunOnGetUnplannedServLineOnAfterInsertUnplannedDemand(UnplannedDemand);
#endif
                    end;
                    InsertServiceLine(UnplannedDemand, ServiceLine, DemandQtyBase);
                end;
            until ServiceLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetUnplannedServLine(var UnplannedDemand: Record "Unplanned Demand"; var ServiceLine: Record Microsoft.Service.Document."Service Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetUnplannedServLineOnAfterInsertUnplannedDemand(var UnplannedDemand: Record "Unplanned Demand")
    begin
    end;

    local procedure InsertServiceLine(var UnplannedDemand: Record "Unplanned Demand"; var ServiceLine: Record "Service Line"; DemandQtyBase: Decimal)
    var
        UnplannedDemand2: Record "Unplanned Demand";
#if not CLEAN25
        GetUnplannedDemand: Codeunit "Get Unplanned Demand";
#endif
    begin
        UnplannedDemand2.Copy(UnplannedDemand);
        UnplannedDemand.InitRecord(
          ServiceLine."Line No.", 0, ServiceLine."No.", ServiceLine.Description, ServiceLine."Variant Code", ServiceLine."Location Code",
          ServiceLine."Bin Code", ServiceLine."Unit of Measure Code", ServiceLine."Qty. per Unit of Measure",
          DemandQtyBase, ServiceLine."Needed by Date");
        UnplannedDemand.Reserve := ServiceLine.Reserve = ServiceLine.Reserve::Always;
        OnInsertServiceLineOnBeforeInsert(UnplannedDemand, ServiceLine);
#if not CLEAN25
        GetUnplannedDemand.RunOnInsertServLineOnBeforeInsert(UnplannedDemand, ServiceLine);
#endif
        UnplannedDemand.Insert();
        UnplannedDemand.Copy(UnplannedDemand2);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertServiceLineOnBeforeInsert(var UnplannedDemand: Record "Unplanned Demand"; ServiceLine: Record Microsoft.Service.Document."Service Line")
    begin
    end;

    local procedure GetServLineNeededQty(ServiceLine: Record "Service Line"): Decimal
    begin
        if ServiceLine.Planned or (ServiceLine."No." = '') or (ServiceLine.Type <> ServiceLine.Type::Item) then
            exit(0);

        ServiceLine.CalcFields(ServiceLine."Reserved Qty. (Base)");
        exit(-ServiceLine.SignedXX(ServiceLine."Outstanding Qty. (Base)" - ServiceLine."Reserved Qty. (Base)"));
    end;


    // Report "Carry Out Action Msg. - Plan."

    [EventSubscriber(ObjectType::Report, Report::"Carry Out Action Msg. - Plan.", 'OnCheckDemandType', '', false, false)]
    local procedure CarryOutActionMsgPlanOnCheckDemandType(RequisitionLine: Record "Requisition Line")
    var
        ServiceLine: Record "Service Line";
    begin
        if RequisitionLine."Demand Type" = Database::"Service Line" then begin
            ServiceLine.Get(RequisitionLine."Demand Subtype", RequisitionLine."Demand Order No.", RequisitionLine."Demand Line No.");
            ServiceLine.TestField(Type, ServiceLine.Type::Item);
            if not ((RequisitionLine."Demand Date" = WorkDate()) and (ServiceLine."Needed by Date" in [0D, WorkDate()])) then
                RequisitionLine.TestField("Demand Date", ServiceLine."Needed by Date");
            RequisitionLine.TestField("No.", ServiceLine."No.");
            RequisitionLine.TestField("Qty. per UOM (Demand)", ServiceLine."Qty. per Unit of Measure");
            RequisitionLine.TestField("Variant Code", ServiceLine."Variant Code");
            RequisitionLine.TestField("Location Code", ServiceLine."Location Code");
            ServiceLine.CalcFields("Reserved Qty. (Base)");
            RequisitionLine.TestField(
                RequisitionLine."Demand Quantity (Base)",
                -ServiceLine.SignedXX(ServiceLine."Outstanding Qty. (Base)" - ServiceLine."Reserved Qty. (Base)"))
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Order Planning Mgt.", 'OnInsertDemandLinesOnCopyItemTracking', '', false, false)]
    local procedure OnInsertDemandLinesOnCopyItemTracking(var RequisitionLine: Record "Requisition Line"; UnplannedDemand: Record "Unplanned Demand")
    var
        ServiceLine: Record "Service Line";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
    begin
        if UnplannedDemand."Demand Type" = UnplannedDemand."Demand Type"::Service then begin
            ServiceLine.Get(UnplannedDemand."Demand SubType", UnplannedDemand."Demand Order No.", UnplannedDemand."Demand Line No.");
            ItemTrackingManagement.CopyItemTracking(ServiceLine.RowID1(), RequisitionLine.RowID1(), true);
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnBeforeShowDemandOrder', '', false, false)]
    local procedure OrderPlanningOnBeforeShowDemandOrder(RequisitionLine: Record "Requisition Line")
    var
        ServiceHeader: Record "Service Header";
    begin
        if RequisitionLine."Demand Type" = Database::"Service Line" then begin
            ServiceHeader.Get(RequisitionLine."Demand Subtype", RequisitionLine."Demand Order No.");
            case ServiceHeader."Document Type" of
                ServiceHeader."Document Type"::Order:
                    PAGE.Run(PAGE::"Service Order", ServiceHeader);
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnSetRecDemandFilter', '', false, false)]
    local procedure OnSetRecDemandFilter(var RequisitionLine: Record "Requisition Line"; DemandOrderFilter: Enum "Demand Order Source Type")
    begin
        if DemandOrderFilter = DemandOrderFilter::"Service Demand" then begin
            RequisitionLine.SetRange("Demand Type", Database::"Service Line");
            RequisitionLine.SetCurrentKey("User ID", "Demand Type", "Worksheet Template Name", "Journal Batch Name", "Line No.");
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnAfterStatusTextOnFormat', '', false, false)]
    local procedure OnAfterStatusTextOnFormat(var RequisitionLine: Record "Requisition Line"; var Text: Text)
    begin
        if RequisitionLine."Demand Line No." = 0 then
            if RequisitionLine."Demand Type" = Database::"Service Line" then
                Text := Format(Enum::"Service Document Status".FromInteger(RequisitionLine.Status));
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnAfterDemandTypeTextOnFormat', '', false, false)]
    local procedure OnAfterDemandTypeTextOnFormat(var RequisitionLine: Record "Requisition Line"; var Text: Text)
    begin
        if RequisitionLine."Demand Line No." = 0 then
            if RequisitionLine."Demand Type" = Database::"Service Line" then
                Text := ServiceTxt;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnAfterDemandSubtypeTextOnFormat', '', false, false)]
    local procedure OnAfterDemandSubtypeTextOnFormat(var RequisitionLine: Record "Requisition Line"; var Text: Text)
    begin
        if RequisitionLine."Demand Type" = Database::"Service Line" then
            Text := Format(Enum::"Service Document Type".FromInteger(RequisitionLine."Demand Subtype"));
    end;
}
