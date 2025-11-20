// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Planning;

using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Projects.Project.Job;
using Microsoft.Inventory.Tracking;
using Microsoft.Foundation.Company;
using System.IO;

codeunit 99000871 "Job Planning Availability Mgt."
{
    var
        AvailabilityManagement: Codeunit AvailabilityManagement;
        ProjectTxt: Label 'Project';
        ProjectOrderTxt: Label 'Project Order';
        ProjectDocumentTxt: Label 'Project %1', Comment = '%1 - status';

    // Codeunit AvailabilityManagement

    [EventSubscriber(ObjectType::Codeunit, Codeunit::AvailabilityManagement, 'OnSetSourceRecord', '', false, false)]
    local procedure OnSetSourceRecord(var OrderPromisingLine: Record "Order Promising Line"; var SourceRecordVar: Variant; var CaptionText: Text; TableID: Integer; var sender: Codeunit AvailabilityManagement)
    var
        Job: Record Job;
    begin
        case TableID of
            Database::Job:
                begin
                    AvailabilityManagement := sender;
                    Job := SourceRecordVar;
                    SetJob(OrderPromisingLine, Job, CaptionText);
                end;
        end;
    end;

    procedure SetJob(var OrderPromisingLine: Record "Order Promising Line"; var Job: Record Job; var CaptionText: Text)
    var
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningAvailabilityMgt: Codeunit "Job Planning Availability Mgt.";
    begin
        CaptionText := ProjectOrderTxt;
        OrderPromisingLine.DeleteAll();
        JobPlanningLine.SetRange("Job No.", Job."No.");
        JobPlanningLine.SetRange(Status, Job.Status);
        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.SetFilter("Remaining Qty.", '>0');
        OnSetJobOnAfterFilterJobPlanningLine(JobPlanningLine, Job);
        if JobPlanningLine.Find('-') then
            repeat
                if JobPlanningLineIsInventoryItem(JobPlanningLine."No.") then begin
                    OrderPromisingLine."Entry No." := OrderPromisingLine.GetLastEntryNo() + 10000;
                    JobPlanningAvailabilityMgt.TransferToOrderPromisingLine(OrderPromisingLine, JobPlanningLine);
                    JobPlanningLine.CalcFields("Reserved Qty. (Base)");
                    AvailabilityManagement.InsertPromisingLine(
                        OrderPromisingLine, JobPlanningLine."Remaining Qty. (Base)" - JobPlanningLine."Reserved Qty. (Base)");
                end;
            until JobPlanningLine.Next() = 0;
    end;

    local procedure JobPlanningLineIsInventoryItem(ItemNo: Code[20]): Boolean
    var
        JobItem: Record Item;
    begin
        JobItem.Get(ItemNo);
        exit(JobItem.Type = JobItem.Type::Inventory);
    end;

    procedure ShowItemAvailabilityFromJobPlanningLines(var JobPlanningLine: Record "Job Planning Line"; AvailabilityType: Enum "Item Availability Type")
    var
        Item: Record Item;
        ItemAvailabilityFormsMgt: Codeunit "Item Availability Forms Mgt";
        NewDate: Date;
        NewVariantCode: Code[10];
        NewLocationCode: Code[10];
        NewUnitOfMeasureCode: Code[10];
    begin
        JobPlanningLine.TestField(Type, JobPlanningLine.Type::Item);
        JobPlanningLine.TestField("No.");

        Item.Reset();
        Item.Get(JobPlanningLine."No.");
        ItemAvailabilityFormsMgt.FilterItem(Item, JobPlanningLine."Location Code", JobPlanningLine."Variant Code", JobPlanningLine."Planning Date");

        OnBeforeShowItemAvailabilityFromJobPlanningLines(Item, JobPlanningLine, AvailabilityType);

        case AvailabilityType of
            AvailabilityType::Period:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByPeriod(Item, JobPlanningLine.FieldCaption(JobPlanningLine."Planning Date"), JobPlanningLine."Planning Date", NewDate) then
                    JobPlanningLine.Validate(JobPlanningLine."Planning Date", NewDate);
            AvailabilityType::Variant:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByVariant(Item, JobPlanningLine.FieldCaption(JobPlanningLine."Variant Code"), JobPlanningLine."Variant Code", NewVariantCode) then
                    JobPlanningLine.Validate(JobPlanningLine."Variant Code", NewVariantCode);
            AvailabilityType::Location:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByLocation(Item, JobPlanningLine.FieldCaption(JobPlanningLine."Location Code"), JobPlanningLine."Location Code", NewLocationCode) then
                    JobPlanningLine.Validate(JobPlanningLine."Location Code", NewLocationCode);
            AvailabilityType::"Event":
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByEvent(Item, JobPlanningLine.FieldCaption(JobPlanningLine."Planning Date"), JobPlanningLine."Planning Date", NewDate, false) then
                    JobPlanningLine.Validate(JobPlanningLine."Planning Date", NewDate);
            AvailabilityType::BOM:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByBOMLevel(Item, JobPlanningLine.FieldCaption(JobPlanningLine."Planning Date"), JobPlanningLine."Planning Date", NewDate) then
                    JobPlanningLine.Validate(JobPlanningLine."Planning Date", NewDate);
            AvailabilityType::UOM:
                if ItemAvailabilityFormsMgt.ShowItemAvailabilityByUOM(Item, JobPlanningLine.FieldCaption(JobPlanningLine."Unit of Measure Code"), JobPlanningLine."Unit of Measure Code", NewUnitOfMeasureCode) then
                    JobPlanningLine.Validate(JobPlanningLine."Unit of Measure Code", NewUnitOfMeasureCode);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::AvailabilityManagement, 'OnCalcCapableToPromiseLine', '', false, false)]
    local procedure OnCalcCapableToPromiseLine(var OrderPromisingLine: Record "Order Promising Line"; var CompanyInfo: Record "Company Information"; var OrderPromisingID: Code[20]; var LastValidLine: Integer)
    var
        JobPlanningLine: Record "Job Planning Line";
        CapableToPromise: Codeunit "Capable to Promise";
        QtyReservedTotal: Decimal;
        OldCTPQty: Decimal;
        FeasibleDate: Date;
    begin
        case OrderPromisingLine."Source Type" of
            OrderPromisingLine."Source Type"::Job:
                begin
                    Clear(OrderPromisingLine."Earliest Shipment Date");
                    Clear(OrderPromisingLine."Planned Delivery Date");
                    JobPlanningLine.Reset();
                    JobPlanningLine.SetRange(Status, OrderPromisingLine."Source Subtype");
                    JobPlanningLine.SetRange("Job No.", OrderPromisingLine."Source ID");
                    JobPlanningLine.SetRange("Job Contract Entry No.", OrderPromisingLine."Source Line No.");
                    JobPlanningLine.FindFirst();
                    JobPlanningLine.CalcFields("Reserved Quantity");
                    QtyReservedTotal := JobPlanningLine."Reserved Quantity";
                    CapableToPromise.RemoveReqLines(JobPlanningLine."Job No.", JobPlanningLine."Job Contract Entry No.", 0, false);
                    JobPlanningLine.CalcFields("Reserved Quantity");
                    OldCTPQty := QtyReservedTotal - JobPlanningLine."Reserved Quantity";
                    FeasibleDate :=
                        CapableToPromise.CalcCapableToPromiseDate(
                        OrderPromisingLine."Item No.", OrderPromisingLine."Variant Code", OrderPromisingLine."Location Code",
                        OrderPromisingLine."Original Shipment Date",
                        OrderPromisingLine."Unavailable Quantity" + OldCTPQty, OrderPromisingLine."Unit of Measure Code",
                        OrderPromisingID, OrderPromisingLine."Source Line No.",
                        LastValidLine, CompanyInfo."Check-Avail. Time Bucket",
                        CompanyInfo."Check-Avail. Period Calc.");
                    if FeasibleDate <> OrderPromisingLine."Original Shipment Date" then
                        OrderPromisingLine.Validate(OrderPromisingLine."Earliest Shipment Date", FeasibleDate)
                    else
                        OrderPromisingLine.Validate(OrderPromisingLine."Earliest Shipment Date", OrderPromisingLine."Original Shipment Date");
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::AvailabilityManagement, 'OnGetRequestedDeliveryDate', '', false, false)]
    local procedure OnGetRequestedDeliveryDate(var OrderPromisingLine: Record "Order Promising Line"; var RequestedDeliveryDate: Date)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        case OrderPromisingLine."Source Type" of
            OrderPromisingLine."Source Type"::Job:
                begin
                    JobPlanningLine.SetRange(Status, OrderPromisingLine."Source Subtype");
                    JobPlanningLine.SetRange("Job No.", OrderPromisingLine."Source ID");
                    JobPlanningLine.SetRange("Job Contract Entry No.", OrderPromisingLine."Source Line No.");
                    if JobPlanningLine.FindFirst() then
                        RequestedDeliveryDate := JobPlanningLine."Requested Delivery Date";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::AvailabilityManagement, 'OnUpdateSourceLine', '', false, false)]
    local procedure OnUpdateSourceLine(var OrderPromisingLine: Record "Order Promising Line")
    var
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLineReserve: Codeunit "Job Planning Line-Reserve";
        ReservationManagement: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
        QtyToReserve: Decimal;
        QtyToReserveBase: Decimal;
    begin
        case OrderPromisingLine."Source Type" of
            OrderPromisingLine."Source Type"::Job:
                begin
                    JobPlanningLine.SetRange(Status, OrderPromisingLine."Source Subtype");
                    JobPlanningLine.SetRange("Job No.", OrderPromisingLine."Source ID");
                    JobPlanningLine.SetRange("Job Contract Entry No.", OrderPromisingLine."Source Line No.");
                    JobPlanningLine.FindFirst();
                    if OrderPromisingLine."Earliest Shipment Date" <> 0D then
                        JobPlanningLine.Validate("Planning Date", OrderPromisingLine."Earliest Shipment Date");

                    JobPlanningLineReserve.ReservQuantity(JobPlanningLine, QtyToReserve, QtyToReserveBase);
                    if (JobPlanningLine."Planning Date" <> 0D) and
                       (JobPlanningLine.Reserve = JobPlanningLine.Reserve::Always) and
                       (QtyToReserveBase <> 0)
                    then begin
                        ReservationManagement.SetReservSource(JobPlanningLine);
                        ReservationManagement.AutoReserve(
                          FullAutoReservation, '', JobPlanningLine."Planning Date", QtyToReserve, QtyToReserveBase);
                        JobPlanningLine.CalcFields("Reserved Quantity");
                    end;
                    JobPlanningLine.Modify();
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::AvailabilityManagement, 'OnCreateReservationsOnCalcNeededQuantity', '', false, false)]
    local procedure OnCreateReservationsOnCalcNeededQuantity(var OrderPromisingLine: Record "Order Promising Line"; var NeededQty: Decimal; var NeededQtyBase: Decimal)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        case OrderPromisingLine."Source Type" of
            OrderPromisingLine."Source Type"::Job:
                begin
                    JobPlanningLine.SetRange(Status, OrderPromisingLine."Source Subtype");
                    JobPlanningLine.SetRange("Job No.", OrderPromisingLine."Source ID");
                    JobPlanningLine.SetRange("Job Contract Entry No.", OrderPromisingLine."Source Line No.");
                    JobPlanningLine.FindFirst();
                    JobPlanningLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
                    NeededQty := JobPlanningLine."Remaining Qty." - JobPlanningLine."Reserved Quantity";
                    NeededQtyBase := JobPlanningLine."Remaining Qty. (Base)" - JobPlanningLine."Reserved Qty. (Base)";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::AvailabilityManagement, 'OnCreateReservationsOnBindToTracking', '', false, false)]
    local procedure OnCreateReservationsOnBindToTracking(var OrderPromisingLine: Record "Order Promising Line"; ReqLine: Record "Requisition Line"; ReservQty: Decimal; ReservQtyBase: Decimal; var TempRecordBuffer: Record "Record Buffer" temporary)
    var
        JobPlanningLine: Record "Job Planning Line";
        TrackingSpecification: Record "Tracking Specification";
        JobPlanningLineReserve: Codeunit "Job Planning Line-Reserve";
        SourceRecRef: RecordRef;
    begin
        case OrderPromisingLine."Source Type" of
            OrderPromisingLine."Source Type"::Job:
                begin
                    JobPlanningLine.SetRange(Status, OrderPromisingLine."Source Subtype");
                    JobPlanningLine.SetRange("Job No.", OrderPromisingLine."Source ID");
                    JobPlanningLine.SetRange("Job Contract Entry No.", OrderPromisingLine."Source Line No.");
                    JobPlanningLine.FindFirst();
                    TrackingSpecification.InitTrackingSpecification(
                        DATABASE::"Requisition Line",
                        0, ReqLine."Worksheet Template Name", ReqLine."Journal Batch Name", 0, ReqLine."Line No.",
                        ReqLine."Variant Code", ReqLine."Location Code", ReqLine."Qty. per Unit of Measure");
                    JobPlanningLineReserve.BindToTracking(
                        JobPlanningLine, TrackingSpecification, ReqLine.Description, ReqLine."Due Date", ReservQty, ReservQtyBase);
                    if JobPlanningLine.Reserve = JobPlanningLine.Reserve::Never then begin
                        SourceRecRef.GetTable(JobPlanningLine);
                        TempRecordBuffer.InsertRecordBuffer(SourceRecRef);
                    end;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::AvailabilityManagement, 'OnCancelReservations', '', false, false)]
    local procedure OnCancelReservations(var TempRecordBuffer: Record "Record Buffer" temporary)
    var
        JobPlanningLine: Record "Job Planning Line";
        ReservationEntry: Record "Reservation Entry";
        ReservationEngineMgt: Codeunit "Reservation Engine Mgt.";
        SourceRecRef: RecordRef;
    begin
        TempRecordBuffer.SetRange("Table No.", Database::"Job Planning Line");
        if TempRecordBuffer.FindSet() then
            repeat
                SourceRecRef := TempRecordBuffer."Record Identifier".GetRecord();
                SourceRecRef.SetTable(JobPlanningLine);
                JobPlanningLine.Find();
                JobPlanningLine.Reserve := JobPlanningLine.Reserve::Optional;
                JobPlanningLine.Modify();
                ReservationEngineMgt.InitFilterAndSortingFor(ReservationEntry, true);
                JobPlanningLine.SetReservationFilters(ReservationEntry);
                if ReservationEntry.FindSet() then
                    repeat
                        ReservationEngineMgt.CancelReservation(ReservationEntry);
                    until ReservationEntry.Next() = 0;
                JobPlanningLine.Reserve := JobPlanningLine.Reserve::Never;
                JobPlanningLine.Modify();
            until TempRecordBuffer.Next() = 0;
    end;

    // Page "Demand Overview"

    [EventSubscriber(ObjectType::Page, Page::"Demand Overview", 'OnLookupDemandNo', '', false, false)]
    local procedure OnLookupDemandNo(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; DemandType: Enum "Demand Order Source Type"; var Result: Boolean; var Text: Text);
    var
        Job: Record Job;
        JobList: Page "Job List";
    begin
        if DemandType = DemandType::"Job Demand" then begin
            Job.SetRange(Status, Job.Status::Open);
            JobList.SetTableView(Job);
            JobList.LookupMode := true;
            if JobList.RunModal() = ACTION::LookupOK then begin
                JobList.GetRecord(Job);
                Text := Job."No.";
                Result := true;
            end;
            Result := false;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Demand Overview", 'OnSourceTypeTextOnFormat', '', false, false)]
    local procedure OnSourceTypeTextOnFormat(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Text: Text)
    begin
        case AvailabilityCalcOverview."Source Type" of
            Database::"Job Planning Line":
                Text := ProjectTxt;
        end;
    end;

    // Codeunit "Calc. Availability Overview"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnGetDemandDates', '', false, false)]
    local procedure OnGetDemandDates(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Item: Record Item; var sender: Codeunit "Calc. Availability Overview")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.FilterLinesWithItemToPlan(Item);
        if JobPlanningLine.FindFirst() then
            repeat
                JobPlanningLine.SetRange("Location Code", JobPlanningLine."Location Code");
                JobPlanningLine.SetRange("Variant Code", JobPlanningLine."Variant Code");
                JobPlanningLine.SetRange("Planning Date", JobPlanningLine."Planning Date");

                sender.InsertAvailabilityEntry(
                  AvailabilityCalcOverview, AvailabilityCalcOverview.Type::"As of Date",
                  JobPlanningLine."Planning Date", JobPlanningLine."Location Code", JobPlanningLine."Variant Code");

                JobPlanningLine.FindLast();
                JobPlanningLine.SetFilter("Location Code", Item.GetFilter("Location Filter"));
                JobPlanningLine.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
                JobPlanningLine.SetFilter("Planning Date", Item.GetFilter("Date Filter"));
            until JobPlanningLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnGetDemandEntries', '', false, false)]
    local procedure OnGetDemandEntries(var AvailabilityCalcOverview: Record "Availability Calc. Overview"; var Item: Record Item; var sender: Codeunit "Calc. Availability Overview")
    var
        JobPlanningLine: Record "Job Planning Line";
        Job: Record Job;
    begin
        if JobPlanningLine.FindLinesWithItemToPlan(Item) then
            repeat
                Job.Get(JobPlanningLine."Job No.");
                JobPlanningLine.CalcFields("Reserved Qty. (Base)");
                sender.InsertAvailabilityEntry(
                    AvailabilityCalcOverview,
                    AvailabilityCalcOverview.Type::Demand, JobPlanningLine."Planning Date", JobPlanningLine."Location Code", JobPlanningLine."Variant Code",
                    -JobPlanningLine."Remaining Qty. (Base)", -JobPlanningLine."Reserved Qty. (Base)",
                    Database::"Job Planning Line", JobPlanningLine.Status.AsInteger(), JobPlanningLine."Job No.", Job."Bill-to Name",
                    Enum::"Demand Order Source Type"::"Job Demand");
            until JobPlanningLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnCheckItemInRange', '', false, false)]
    local procedure OnCheckItemInRange(var Item: Record Item; DemandType: Enum "Demand Order Source Type"; DemandNo: Code[20]; var Found: Boolean)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        if DemandType = DemandType::"Job Demand" then
            if JobPlanningLine.LinesWithItemToPlanExist(Item) then
                if DemandNo <> '' then begin
                    JobPlanningLine.SetRange("Job No.", DemandNo);
                    Found := not JobPlanningLine.IsEmpty();
                end else
                    Found := true;
    end;

    // Table "Order Promising Line"

    procedure TransferToOrderPromisingLine(var OrderPromisingLine: Record "Order Promising Line"; var JobPlanningLine: Record "Job Planning Line")
    begin
        OrderPromisingLine."Source Type" := OrderPromisingLine."Source Type"::Job;
        OrderPromisingLine."Source Subtype" := JobPlanningLine.Status.AsInteger();
        OrderPromisingLine."Source ID" := JobPlanningLine."Job No.";
        OrderPromisingLine."Source Line No." := JobPlanningLine."Job Contract Entry No.";

        OrderPromisingLine."Item No." := JobPlanningLine."No.";
        OrderPromisingLine."Variant Code" := JobPlanningLine."Variant Code";
        OrderPromisingLine."Location Code" := JobPlanningLine."Location Code";
        OrderPromisingLine.Validate("Requested Delivery Date", JobPlanningLine."Requested Delivery Date");
        OrderPromisingLine."Original Shipment Date" := JobPlanningLine."Planning Date";
        OrderPromisingLine.Description := JobPlanningLine.Description;
        OrderPromisingLine.Quantity := JobPlanningLine."Remaining Qty.";
        OrderPromisingLine."Unit of Measure Code" := JobPlanningLine."Unit of Measure Code";
        OrderPromisingLine."Qty. per Unit of Measure" := JobPlanningLine."Qty. per Unit of Measure";
        OrderPromisingLine."Quantity (Base)" := JobPlanningLine."Remaining Qty. (Base)";

        OnAfterTransferToOrderPromisingLine(OrderPromisingLine, JobPlanningLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferToOrderPromisingLine(var OrderPromisingLine: Record "Order Promising Line"; var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Order Promising Line", 'OnValidateRequestedDeliveryDate', '', false, false)]
    local procedure OnValidateRequestedDeliveryDate(var OrderPromisingLine: Record "Order Promising Line")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        if OrderPromisingLine."Source Type" = OrderPromisingLine."Source Type"::Job then begin
            JobPlanningLine.SetRange("Job No.", OrderPromisingLine."Source ID");
            JobPlanningLine.SetRange("Job Contract Entry No.", OrderPromisingLine."Source Line No.");
            JobPlanningLine.FindFirst();
            OrderPromisingLine."Requested Shipment Date" := JobPlanningLine."Planning Date";
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Order Promising Line", 'OnValidatePlannedDeliveryDate', '', false, false)]
    local procedure OnValidatePlannedDeliveryDate(var OrderPromisingLine: Record "Order Promising Line")
    begin
        if OrderPromisingLine."Source Type" = OrderPromisingLine."Source Type"::Job then
            OrderPromisingLine."Earliest Shipment Date" := OrderPromisingLine."Planned Delivery Date";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Order Promising Line", 'OnValidateEarliestDeliveryDate', '', false, false)]
    local procedure OnValidateEarliestDeliveryDate(var OrderPromisingLine: Record "Order Promising Line")
    begin
        if OrderPromisingLine."Source Type" = OrderPromisingLine."Source Type"::Job then
            if OrderPromisingLine."Earliest Shipment Date" <> 0D then
                OrderPromisingLine."Planned Delivery Date" := OrderPromisingLine."Earliest Shipment Date";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Availability Overview", 'OnDemandExist', '', false, false)]
    local procedure OnDemandExist(var Item: Record Item; var Exists: Boolean)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        Exists := Exists or JobPlanningLine.LinesWithItemToPlanExist(Item);
    end;

    // Page "Order Promising Lines"

    [EventSubscriber(ObjectType::Page, Page::"Order Promising Lines", 'OnOpenPageOnSetSource', '', false, false)]
    local procedure OnOpenPageOnSetSource(var OrderPromisingLine: Record "Order Promising Line"; var CrntSourceType: Enum "Order Promising Line Source Type"; var CrntSourceID: Code[20]; var AvailabilityMgt: Codeunit AvailabilityManagement)
    var
        Job: Record Job;
    begin
        if CrntSourceType = OrderPromisingLine."Source Type"::"Job" then begin
            Job.Get(OrderPromisingLine.GetRangeMin("Source ID"));
            AvailabilityMgt.SetSourceRecord(OrderPromisingLine, Job);
            CrntSourceType := CrntSourceType::Job;
            CrntSourceID := Job."No.";
        end;
    end;

    // Codeunit "Calc. Item Availability"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Item Availability", 'OnAfterGetDocumentEntries', '', false, false)]
    local procedure OnAfterGetDocumentEntries(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item; var sender: Codeunit "Calc. Item Availability")
    begin
        TryGetJobOrdersDemandEntries(InvtEventBuf, Item, sender);
    end;

    local procedure TryGetJobOrdersDemandEntries(var InvtEventBuf: Record "Inventory Event Buffer"; var Item: Record Item; var sender: Codeunit "Calc. Item Availability")
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        JobPlanningLine: Record "Job Planning Line";
    begin
        if not JobPlanningLine.ReadPermission then
            exit;

        if JobPlanningLine.FindLinesWithItemToPlan(Item) then
            repeat
                TransferFromJobNeed(InvtEventBuf, JobPlanningLine);
                sender.InsertEntry(InvtEventBuf);
            until JobPlanningLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Item Availability", 'OnAfterGetSourceReferences', '', false, false)]
    local procedure OnAfterGetSourceReferences(FromRecordID: RecordId; var SourceType: Integer; var SourceSubtype: Integer; var SourceID: Code[20]; var SourceRefNo: Integer; var IsHandled: Boolean; RecRef: RecordRef)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        if RecRef.Number = Database::"Job Planning Line" then begin
            RecRef.SetTable(JobPlanningLine);
            SourceType := Database::"Job Planning Line";
            JobPlanningLine.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.", JobPlanningLine."Line No.");
            SourceSubtype := JobPlanningLine.Status.AsInteger();
            SourceID := JobPlanningLine."Job No.";
            SourceRefNo := JobPlanningLine."Job Contract Entry No.";
            IsHandled := true;
        end;
    end;

    // Table "Availability Info. Buffer" 

    [EventSubscriber(ObjectType::Table, Database::"Availability Info. Buffer", 'OnLookupAvailableInventory', '', false, false)]
    local procedure OnLookupAvailableInventory(var TempReservationEntry: Record "Reservation Entry" temporary; var sender: Record "Availability Info. Buffer")
    begin
        LookupReservationEntryForQtyOnJobOrder(TempReservationEntry, sender);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Availability Info. Buffer", 'OnLookupGrossRequirement', '', false, false)]
    local procedure OnLookupGrossRequirement(var TempReservationEntry: Record "Reservation Entry" temporary; var sender: Record "Availability Info. Buffer")
    begin
        LookupReservationEntryForQtyOnJobOrder(TempReservationEntry, sender);
    end;

    local procedure LookupReservationEntryForQtyOnJobOrder(var TempReservationEntry: Record "Reservation Entry" temporary; var AvailabilityInfoBuffer: Record "Availability Info. Buffer")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        AvailabilityInfoBuffer.AddEntriesForLookUp(
            TempReservationEntry,
            Database::"Job Planning Line",
            Format(ReservationEntry."Source Subtype"::"2"),
            AvailabilityInfoBuffer.GetOptionFilter(
                ReservationEntry."Reservation Status"::Reservation,
                ReservationEntry."Reservation Status"::Tracking,
                ReservationEntry."Reservation Status"::Surplus
            ),
            "Reservation Date Filter"::"Shipment Date"
        );
    end;

    // Codeunit "Item Availability Forms Mgt"

    procedure ShowJobPlanningLines(var Item: Record Item)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.FindLinesWithItemToPlan(Item);
        PAGE.Run(0, JobPlanningLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Availability Forms Mgt", 'OnAfterCalcItemPlanningFields', '', false, false)]
    local procedure OnAfterCalcItemPlanningFields(var Item: Record Item)
    begin
        Item.CalcFields(
            "Qty. on Job Order");
    end;

    // Codeunit "Calc. Inventory Page Data"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Calc. Inventory Page Data", 'OnTransferToPeriodDetailsElseCase', '', false, false)]
    local procedure OnTransferToPeriodDetailsElseCase(var InventoryPageData: Record "Inventory Page Data"; InventoryEventBuffer: Record "Inventory Event Buffer"; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; var IsHandled: Boolean; SourceRefNo: Integer)
    begin
        if SourceType = Database::"Job Planning Line" then begin
            TransferJobPlanningLine(InventoryEventBuffer, InventoryPageData, SourceID);
            IsHandled := true;
        end;
    end;

    local procedure TransferJobPlanningLine(InventoryEventBuffer: Record "Inventory Event Buffer"; var InventoryPageData: Record "Inventory Page Data"; SourceID: Code[20])
    var
        Job: Record Job;
        RecRef: RecordRef;
    begin
        Job.Get(SourceID);
        RecRef.GetTable(Job);
        InventoryPageData."Source Document ID" := RecRef.RecordId;
        InventoryPageData."Document No." := Job."No.";
        InventoryPageData.Type := InventoryPageData.Type::Job;
        InventoryPageData.Description := Job."Bill-to Customer No.";
        InventoryPageData.Source := StrSubstNo(ProjectDocumentTxt, Format(Job.Status));
        InventoryPageData."Gross Requirement" := InventoryEventBuffer."Remaining Quantity (Base)";
        InventoryPageData."Reserved Requirement" := InventoryEventBuffer."Reserved Quantity (Base)";
    end;

    // Page "Item Availability Line List"

    [EventSubscriber(ObjectType::Page, Page::"Item Availability Line List", 'OnAfterMakeEntries', '', false, false)]
    local procedure OnAfterMakeEntries(var Item: Record Item; var ItemAvailabilityLine: Record "Item Availability Line"; AvailabilityType: Option "Gross Requirement","Planned Order Receipt","Scheduled Order Receipt","Planned Order Release",All; Sign: Decimal; QtyByUnitOfMeasure: Decimal)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        case AvailabilityType of
            AvailabilityType::"Gross Requirement":
                ItemAvailabilityLine.InsertEntry(
                    Database::"Job Planning Line", Item.FieldNo("Qty. on Job Order"),
                    JobPlanningLine.TableCaption(), Item."Qty. on Job Order", QtyByUnitOfMeasure, Sign);
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Item Availability Line List", 'OnAfterLookupEntries', '', false, false)]
    local procedure OnAfterLookupEntries(var Item: Record Item; ItemAvailabilityLine: Record "Item Availability Line");
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        case ItemAvailabilityLine."Table No." of
            Database::"Job Planning Line":
                begin
                    JobPlanningLine.FindLinesWithItemToPlan(Item);
                    PAGE.RunModal(0, JobPlanningLine);
                end;
        end;
    end;

    // Table "Inventory Event Buffer"

    procedure TransferFromJobNeed(var InventoryEventBuffer: Record "Inventory Event Buffer"; JobPlanningLine: Record "Job Planning Line")
    var
        RecRef: RecordRef;
    begin
        if JobPlanningLine.Type <> JobPlanningLine.Type::Item then
            exit;

        InventoryEventBuffer.Init();
        RecRef.GetTable(JobPlanningLine);
        InventoryEventBuffer."Source Line ID" := RecRef.RecordId;
        InventoryEventBuffer."Item No." := JobPlanningLine."No.";
        InventoryEventBuffer."Variant Code" := JobPlanningLine."Variant Code";
        InventoryEventBuffer."Location Code" := JobPlanningLine."Location Code";
        InventoryEventBuffer."Availability Date" := JobPlanningLine."Planning Date";
        InventoryEventBuffer.Type := InventoryEventBuffer.Type::Job;
        JobPlanningLine.CalcFields("Reserved Qty. (Base)");
        InventoryEventBuffer."Remaining Quantity (Base)" := -JobPlanningLine."Remaining Qty. (Base)";
        InventoryEventBuffer."Reserved Quantity (Base)" := -JobPlanningLine."Reserved Qty. (Base)";
        InventoryEventBuffer.Positive := not (InventoryEventBuffer."Remaining Quantity (Base)" < 0);

        OnAfterTransferFromJobNeed(InventoryEventBuffer, JobPlanningLine);
#if not CLEAN25
        InventoryEventBuffer.RunOnAfterTransferFromJobNeed(InventoryEventBuffer, JobPlanningLine);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferFromJobNeed(var InventoryEventBuffer: Record "Inventory Event Buffer"; JobPlanningLine: Record Microsoft.Projects.Project.Planning."Job Planning Line")
    begin
    end;

    // Codeunit "Available to Promise"

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Available to Promise", 'OnAfterCalculateAvailability', '', false, false)]
    local procedure OnAfterCalculateAvailability(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item; var sender: Codeunit "Available to Promise")
    begin
        UpdateJobOrderAvail(AvailabilityAtDate, Item, sender);
    end;

    local procedure UpdateJobOrderAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item; var AvailableToPromise: Codeunit "Available to Promise")
    var
        JobPlanningLine: Record "Job Planning Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateJobOrderAvail(AvailabilityAtDate, Item, IsHandled);
        if IsHandled then
            exit;

        if JobPlanningLine.FindLinesWithItemToPlan(Item) then
            repeat
                JobPlanningLine.CalcFields("Reserved Qty. (Base)");
                AvailableToPromise.UpdateGrossRequirement(
                    AvailabilityAtDate, JobPlanningLine."Planning Date", JobPlanningLine."Remaining Qty. (Base)" - JobPlanningLine."Reserved Qty. (Base)");
            until JobPlanningLine.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateJobOrderAvail(var AvailabilityAtDate: Record "Availability at Date"; var Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemAvailabilityFromJobPlanningLines(var Item: Record Item; var JobPlanningLine: Record "Job Planning Line"; AvailabilityType: Enum "Item Availability Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetJobOnAfterFilterJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; var Job: Record Job)
    begin
    end;
}
