// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

using Microsoft.Service.Document;
using Microsoft.Service.Setup;
using Microsoft.Service.History;

codeunit 6451 "Serv. Time Sheet Mgt."
{
    var
        TimesheetManagement: Codeunit "Time Sheet Management";
        CannotReopenLineErr: Label 'Time sheet line cannot be reopened because there are linked service lines.';
        CannotBeGreaterErr: Label 'cannot be greater than %1 %2.', Comment = '%1 - Quantity, %2 - Unit of measure. Example: Quantity cannot be greater than 8 HOUR.';

    [EventSubscriber(ObjectType::Table, Database::"Time Sheet Detail", 'OnAfterCopyFromTimeSheetLine', '', false, false)]
    local procedure OnAfterCopyFromTimeSheetLine(var TimeSheetDetail: Record "Time Sheet Detail"; TimeSheetLine: Record "Time Sheet Line")
    begin
        TimeSheetDetail."Service Order No." := TimeSheetLine."Service Order No.";
        TimeSheetDetail."Service Order Line No." := TimeSheetLine."Service Order Line No.";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Time Sheet Line", 'OnValidateTypeOnAfterClearFields', '', false, false)]
    local procedure OnValidateTypeOnAfterClearFields(var TimeSheetLine: Record "Time Sheet Line")
    begin
        TimeSheetLine."Service Order No." := '';
        TimeSheetLine."Service Order Line No." := 0;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Activity Details FactBox", 'OnLookupActivity', '', false, false)]
    local procedure OnLookupActivity(var TimeSheetLine: Record "Time Sheet Line")
    var
        ServiceHeader: Record "Service Header";
        ServiceOrders: Page "Service Orders";
    begin
        case TimeSheetLine.Type of
            TimeSheetLine.Type::Service:
                begin
                    Clear(ServiceOrders);
                    if TimeSheetLine."Service Order No." <> '' then
                        if ServiceHeader.Get(ServiceHeader."Document Type"::Order, TimeSheetLine."Service Order No.") then
                            ServiceOrders.SetRecord(ServiceHeader);
                    ServiceOrders.RunModal();
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Time Sheet Approval Management", 'OnReopenApprovedOnBeforeCheckLinkedDoc', '', false, false)]
    local procedure OnReopenApprovedOnBeforeCheckLinkedDoc(var TimeSheetLine: Record "Time Sheet Line")
    begin
        CheckLinkedServiceDoc(TimeSheetLine);
    end;

    local procedure CheckLinkedServiceDoc(var TimeSheetLine: Record "Time Sheet Line")
    var
        ServiceLine: Record "Service Line";
    begin
        if TimeSheetLine."Service Order No." = '' then
            exit;

        ServiceLine.SetRange("Document Type", ServiceLine."Document Type"::Order);
        ServiceLine.SetRange("Document No.", TimeSheetLine."Service Order No.");
        ServiceLine.SetRange("Time Sheet No.", TimeSheetLine."Time Sheet No.");
        ServiceLine.SetRange("Time Sheet Line No.", TimeSheetLine."Line No.");
        if not ServiceLine.IsEmpty() then
            Error(CannotReopenLineErr);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Time Sheet Approval Management", 'OnAfterApprove', '', false, false)]
    local procedure OnAfterApprove(var TimeSheetLine: Record "Time Sheet Line")
    begin
        ApproveServiceOrderTimeSheetEntries(TimeSheetLine);
    end;

    local procedure ApproveServiceOrderTimeSheetEntries(var TimeSheetLine: Record "Time Sheet Line")
    var
        ServiceHeader: Record "Service Header";
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        if TimeSheetLine.Type <> TimeSheetLine.Type::Service then
            exit;

        if ServiceMgtSetup.Get() and ServiceMgtSetup."Copy Time Sheet to Order" then begin
            ServiceHeader.Get(ServiceHeader."Document Type"::Order, TimeSheetLine."Service Order No.");
            CreateServDocLinesFromTSLine(ServiceHeader, TimeSheetLine);
        end;
    end;

    // codeunit Time Sheet Management

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Time Sheet Management", 'OnBeforeCheckTimeSheetLineFieldsVisible', '', false, false)]
    local procedure OnBeforeCheckTimeSheetLineFieldsVisible(var ServiceOrderNoVisible: Boolean)
    var
        ServiceHeader: Record "Service Header";
    begin
        ServiceOrderNoVisible := not ServiceHeader.IsEmpty(); //set with ApplicationArea
    end;

    procedure CreateServDocLinesFromTS(ServiceHeader: Record "Service Header")
    var
        TimeSheetLine: Record "Time Sheet Line";
    begin
        CreateServLinesFromTS(ServiceHeader, TimeSheetLine, false);
    end;

    procedure CreateServDocLinesFromTSLine(ServiceHeader: Record "Service Header"; var TimeSheetLine: Record "Time Sheet Line")
    begin
        CreateServLinesFromTS(ServiceHeader, TimeSheetLine, true);
    end;

    local procedure GetFirstServiceItemNo(ServiceHeader: Record "Service Header"): Code[20]
    var
        ServiceItemLine: Record "Service Item Line";
    begin
        ServiceItemLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceItemLine.FindFirst();
        exit(ServiceItemLine."Service Item No.");
    end;

    procedure CreateTSLineFromServiceLine(ServiceLine: Record "Service Line"; DocumentNo: Code[20]; Chargeable: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateTSLineFromServiceLine(ServiceLine, IsHandled);
#if not CLEAN25
        TimesheetManagement.RunOnBeforeCreateTSLineFromServiceLine(ServiceLine, IsHandled);
#endif
        if IsHandled then
            exit;

        if ServiceLine."Time Sheet No." = '' then
            TimesheetManagement.CreateTSLineFromDocLine(
              DATABASE::"Service Line", ServiceLine."No.", ServiceLine."Posting Date", DocumentNo, ServiceLine."Document No.", ServiceLine."Line No.",
              ServiceLine."Work Type Code", Chargeable, ServiceLine.Description, -ServiceLine."Qty. to Ship");
    end;

    procedure CreateTSLineFromServiceShptLine(ServiceShipmentLine: Record "Service Shipment Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateTSLineFromServiceShptLine(ServiceShipmentLine, IsHandled);
#if not CLEAN25
        TimesheetManagement.RunOnBeforeCreateTSLineFromServiceShptLine(ServiceShipmentLine, IsHandled);
#endif
        if IsHandled then
            exit;

        if ServiceShipmentLine."Time Sheet No." = '' then
            TimesheetManagement.CreateTSLineFromDocLine(
              DATABASE::"Service Shipment Line", ServiceShipmentLine."No.", ServiceShipmentLine."Posting Date", ServiceShipmentLine."Document No.", ServiceShipmentLine."Order No.", ServiceShipmentLine."Order Line No.",
              ServiceShipmentLine."Work Type Code", true, ServiceShipmentLine.Description, -ServiceShipmentLine."Qty. Shipped Not Invoiced");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Time Sheet Management", 'OnCreateTSLineFromDocLineOnBeforeTimeSheetLineInsert', '', false, false)]
    local procedure OnCreateTSLineFromDocLineOnBeforeTimeSheetLineInsert(var TimeSheetLine: Record "Time Sheet Line"; TableID: Integer; OrderNo: Code[20]; OrderLineNo: Integer)
    begin
        case TableID of
            DATABASE::"Service Line",
            DATABASE::"Service Shipment Line":
                begin
                    TimeSheetLine.Type := TimeSheetLine.Type::Service;
                    TimeSheetLine."Service Order No." := OrderNo;
                    TimeSheetLine."Service Order Line No." := OrderLineNo;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Time Sheet Management", 'OnGetActivityInfoCaseTypeElse', '', false, false)]
    local procedure OnGetActivityInfoCaseTypeElse(var TimeSheetLine: Record "Time Sheet Line"; var ActivityCaption: Text[30]; var ActivityID: Code[20])
    begin
        case TimeSheetLine.Type of
            TimeSheetLine.Type::Service:
                begin
                    ActivityCaption := CopyStr(TimeSheetLine.FieldCaption("Service Order No."), 1, 30);
                    ActivityID := TimeSheetLine."Service Order No.";
                end;
        end;
    end;

    procedure CheckServiceLine(ServiceLine: Record "Service Line")
    var
        MaxAvailableQty: Decimal;
    begin
        ServiceLine.TestField("Qty. per Unit of Measure");
        if not TimesheetManagement.CheckTSLineDetailPosting(
             ServiceLine."Time Sheet No.",
             ServiceLine."Time Sheet Line No.",
             ServiceLine."Time Sheet Date",
             ServiceLine."Qty. to Ship",
             ServiceLine."Qty. per Unit of Measure",
             MaxAvailableQty)
        then
            ServiceLine.FieldError(Quantity, StrSubstNo(CannotBeGreaterErr, MaxAvailableQty, ServiceLine."Unit of Measure Code"));
    end;

    procedure CreateServLinesFromTS(ServiceHeader: Record "Service Header"; var TimeSheetLine: Record "Time Sheet Line"; AddBySelectedTimesheetLine: Boolean)
    var
        TimeSheetDetail: Record "Time Sheet Detail";
        TempTimeSheetDetail: Record "Time Sheet Detail" temporary;
        ServiceLine: Record "Service Line";
        LineNo: Integer;
    begin
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        if ServiceLine.FindLast() then;
        LineNo := ServiceLine."Line No." + 10000;

        ServiceLine.SetFilter("Time Sheet No.", '<>%1', '');
        if ServiceLine.FindSet() then
            repeat
                if not TempTimeSheetDetail.Get(
                     ServiceLine."Time Sheet No.",
                     ServiceLine."Time Sheet Line No.",
                     ServiceLine."Time Sheet Date")
                then
                    if TimeSheetDetail.Get(
                         ServiceLine."Time Sheet No.",
                         ServiceLine."Time Sheet Line No.",
                         ServiceLine."Time Sheet Date")
                    then begin
                        TempTimeSheetDetail := TimeSheetDetail;
                        TempTimeSheetDetail.Insert();
                    end;
            until ServiceLine.Next() = 0;

        TimeSheetDetail.SetRange("Service Order No.", ServiceHeader."No.");
        TimeSheetDetail.SetRange(Status, TimeSheetDetail.Status::Approved);
        if AddBySelectedTimesheetLine = true then begin
            TimeSheetDetail.SetRange("Time Sheet No.", TimeSheetLine."Time Sheet No.");
            TimeSheetDetail.SetRange("Time Sheet Line No.", TimeSheetLine."Line No.");
        end;
        TimeSheetDetail.SetRange(Posted, false);
        if TimeSheetDetail.FindSet() then
            repeat
                if not TempTimeSheetDetail.Get(
                     TimeSheetDetail."Time Sheet No.",
                     TimeSheetDetail."Time Sheet Line No.",
                     TimeSheetDetail.Date)
                then begin
                    AddServLinesFromTSDetail(ServiceHeader, TimeSheetDetail, LineNo);
                    LineNo := LineNo + 10000;
                end;
            until TimeSheetDetail.Next() = 0;
    end;

    local procedure AddServLinesFromTSDetail(ServiceHeader: Record "Service Header"; var TimeSheetDetail: Record "Time Sheet Detail"; LineNo: Integer)
    var
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        ServiceLine: Record "Service Line";
        QtyToPost: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAddServLinesFromTSDetail(ServiceHeader, TimeSheetDetail, LineNo, IsHandled);
#if not CLEAN25
        TimesheetManagement.RunOnBeforeAddServLinesFromTSDetail(ServiceHeader, TimeSheetDetail, LineNo, IsHandled);
#endif
        if IsHandled then
            exit;

        QtyToPost := TimeSheetDetail.GetMaxQtyToPost();
        if QtyToPost <> 0 then begin
            ServiceLine.Init();
            ServiceLine."Document Type" := ServiceHeader."Document Type";
            ServiceLine."Document No." := ServiceHeader."No.";
            ServiceLine."Line No." := LineNo;
            ServiceLine.Validate("Service Item No.", GetFirstServiceItemNo(ServiceHeader));
            ServiceLine."Time Sheet No." := TimeSheetDetail."Time Sheet No.";
            ServiceLine."Time Sheet Line No." := TimeSheetDetail."Time Sheet Line No.";
            ServiceLine."Time Sheet Date" := TimeSheetDetail.Date;
            ServiceLine.Type := ServiceLine.Type::Resource;
            TimeSheetHeader.Get(TimeSheetDetail."Time Sheet No.");
            ServiceLine.Validate("No.", TimeSheetHeader."Resource No.");
            ServiceLine.Validate(Quantity, TimeSheetDetail.Quantity);
            TimeSheetLine.Get(TimeSheetDetail."Time Sheet No.", TimeSheetDetail."Time Sheet Line No.");
            if not TimeSheetLine.Chargeable then
                ServiceLine.Validate("Qty. to Consume", QtyToPost);
            ServiceLine."Planned Delivery Date" := TimeSheetDetail.Date;
            ServiceLine.Validate("Work Type Code", TimeSheetLine."Work Type Code");
            OnAddServLinesFromTSDetailOnBeforeInsertServiceLine(ServiceLine, LineNo, ServiceHeader, TimeSheetDetail);
#if not CLEAN25
            TimesheetManagement.RunOnAddServLinesFromTSDetailOnBeforeInsertServiceLine(ServiceLine, LineNo, ServiceHeader, TimeSheetDetail);
#endif
            ServiceLine.Insert();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddServLinesFromTSDetail(ServiceHeader: Record Microsoft.Service.Document."Service Header"; var TimeSheetDetail: Record "Time Sheet Detail"; LineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTSLineFromServiceShptLine(var ServiceShipmentLine: Record Microsoft.Service.History."Service Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTSLineFromServiceLine(var ServiceLine: Record Microsoft.Service.Document."Service Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddServLinesFromTSDetailOnBeforeInsertServiceLine(var ServiceLine: Record Microsoft.Service.Document."Service Line"; var LineNo: Integer; ServiceHeader: Record Microsoft.Service.Document."Service Header"; TimeSheetDetail: Record "Time Sheet Detail")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Time Sheet Line", 'OnBeforeShowLineDetails', '', false, false)]
    local procedure OnBeforeShowLineDetails(var TimeSheetLine: Record "Time Sheet Line"; var IsHandled: Boolean; ManagerRole: Boolean)
    var
        TimeSheetLineServiceDetail: Page "Time Sheet Line Service Detail";
    begin
        case TimeSheetLine.Type of
            TimeSheetLine.Type::Service:
                begin
                    TimeSheetLineServiceDetail.SetParameters(TimeSheetLine, ManagerRole);
                    if TimeSheetLineServiceDetail.RunModal() = ACTION::OK then
                        TimeSheetLineServiceDetail.GetRecord(TimeSheetLine);
                    IsHandled := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Time Sheet Line", 'OnAfterSetExclusionTypeFilter', '', false, false)]
    local procedure TimeSheetLineOnAfterSetExclusionTypeFilter(var TimeSheetLine: Record "Time Sheet Line")
    var
        FilterString: Text;
    begin
        FilterString := TimeSheetLine.GetFilter(Type);
        if FilterString <> '' then begin
            FilterString += StrSubstNo('&<>%1', Format(TimeSheetLine.Type::Service));
            TimeSheetLine.SetFilter(Type, FilterString);
        end else
            TimeSheetLine.SetFilter(Type, '&<>%1', TimeSheetLine.Type::Service);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Time Sheet Line Archive", 'OnAfterSetExclusionTypeFilter', '', false, false)]
    local procedure TimeSheetLineArchiveOnAfterSetExclusionTypeFilter(var TimeSheetLineArchive: Record "Time Sheet Line Archive")
    var
        FilterString: Text;
    begin
        FilterString := TimeSheetLineArchive.GetFilter(Type);
        if FilterString <> '' then begin
            FilterString += StrSubstNo('&<>%1', Format(TimeSheetLineArchive.Type::Service));
            TimeSheetLineArchive.SetFilter(Type, FilterString);
        end else
            TimeSheetLineArchive.SetFilter(Type, '&<>%1', TimeSheetLineArchive.Type::Service);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Time Sheet Approval Management", 'OnSubmitOnAfterCheck', '', false, false)]
    local procedure OnSubmitOnAfterCheck(var TimeSheetLine: Record "Time Sheet Line")
    begin
        case TimeSheetLine.Type of
            TimeSheetLine.Type::Service:
                TimeSheetLine.TestField("Service Order No.");
        end;
    end;

}