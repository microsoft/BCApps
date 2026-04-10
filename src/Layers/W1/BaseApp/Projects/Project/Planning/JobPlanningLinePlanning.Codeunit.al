// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Planning;

using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Requisition;
using Microsoft.Projects.Project.Job;

codeunit 99000852 "Job Planning Line-Planning"
{
    var
        Job: Record Job;
        ProjectsTxt: Label 'Projects';

    [EventSubscriber(ObjectType::Table, Database::"Requisition Line", 'OnSetDemandTypeFromUnplannedDemand', '', false, false)]
    local procedure ReqLineOnSetDemandTypeFromUnplannedDemand(var RequisitionLine: Record "Requisition Line"; UnplannedDemand: Record "Unplanned Demand")
    begin
        if UnplannedDemand."Demand Type" = UnplannedDemand."Demand Type"::Job then
            RequisitionLine."Demand Type" := Database::"Job Planning Line";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Unplanned Demand", 'OnValidateDemandOrderNoOnGetSourceFields', '', false, false)]
    local procedure OnValidateDemandOrderNoOnGetSourceFields(var UnplannedDemand: Record "Unplanned Demand")
    var
        Job: Record Job;
    begin
        case UnplannedDemand."Demand Type" of
            UnplannedDemand."Demand Type"::Job:
                begin
                    Job.Get(UnplannedDemand."Demand Order No.");
                    UnplannedDemand."Sell-to Customer No." := Job."Bill-to Customer No.";
                    UnplannedDemand.Description := Job.Description;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Carry Out Action Msg. - Plan.", 'OnCheckDemandType', '', false, false)]
    local procedure CarryOutActionMsgPlanOnCheckDemandType(RequisitionLine: Record "Requisition Line")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        if RequisitionLine."Demand Type" = Database::"Job Planning Line" then begin
            JobPlanningLine.SetRange("Job Contract Entry No.", RequisitionLine."Demand Line No.");
            JobPlanningLine.FindFirst();
            JobPlanningLine.TestField(Type, JobPlanningLine.Type::Item);
            JobPlanningLine.TestField("Job No.");
            JobPlanningLine.TestField(Status, JobPlanningLine.Status::Order);
            if not ((RequisitionLine."Demand Date" = WorkDate()) and (JobPlanningLine."Planning Date" in [0D, WorkDate()])) then
                RequisitionLine.TestField("Demand Date", JobPlanningLine."Planning Date");
            RequisitionLine.TestField("No.", JobPlanningLine."No.");
            RequisitionLine.TestField("Qty. per UOM (Demand)", JobPlanningLine."Qty. per Unit of Measure");
            RequisitionLine.TestField("Variant Code", JobPlanningLine."Variant Code");
            RequisitionLine.TestField("Location Code", JobPlanningLine."Location Code");
            JobPlanningLine.CalcFields("Reserved Qty. (Base)");
            RequisitionLine.TestField(
                RequisitionLine."Demand Quantity (Base)",
                JobPlanningLine."Remaining Qty. (Base)" - JobPlanningLine."Reserved Qty. (Base)")
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnBeforeShowDemandOrder', '', false, false)]
    local procedure OrderPlanningOnBeforeShowDemandOrder(RequisitionLine: Record "Requisition Line")
    begin
        if RequisitionLine."Demand Type" = Database::"Job Planning Line" then begin
            Job.Get(RequisitionLine."Demand Order No.");
            case Job.Status of
                Job.Status::Open:
                    PAGE.Run(PAGE::"Job Card", Job);
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnSetRecDemandFilter', '', false, false)]
    local procedure OnSetRecDemandFilter(var RequisitionLine: Record "Requisition Line"; DemandOrderFilter: Enum "Demand Order Source Type")
    begin
        if DemandOrderFilter = DemandOrderFilter::"Job Demand" then begin
            RequisitionLine.SetRange("Demand Type", Database::"Job Planning Line");
            RequisitionLine.SetCurrentKey("User ID", "Demand Type", "Worksheet Template Name", "Journal Batch Name", "Line No.");
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnAfterStatusTextOnFormat', '', false, false)]
    local procedure OnAfterStatusTextOnFormat(var RequisitionLine: Record "Requisition Line"; var Text: Text)
    begin
        if RequisitionLine."Demand Line No." = 0 then
            if RequisitionLine."Demand Type" = Database::"Job Planning Line" then
                Text := Format("Job Status".FromInteger(RequisitionLine.Status));
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnAfterDemandTypeTextOnFormat', '', false, false)]
    local procedure OnAfterDemandTypeTextOnFormat(var RequisitionLine: Record "Requisition Line"; var Text: Text)
    begin
        if RequisitionLine."Demand Line No." = 0 then
            if RequisitionLine."Demand Type" = Database::"Job Planning Line" then
                Text := ProjectsTxt;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Order Planning", 'OnAfterDemandSubtypeTextOnFormat', '', false, false)]
    local procedure OnAfterDemandSubtypeTextOnFormat(var RequisitionLine: Record "Requisition Line"; var Text: Text)
    begin
        if RequisitionLine."Demand Type" = Database::"Job Planning Line" then
            Text := Format("Job Status".FromInteger(RequisitionLine.Status));
    end;
}