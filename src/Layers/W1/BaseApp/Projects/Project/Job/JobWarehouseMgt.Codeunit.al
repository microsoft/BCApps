// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Job;

using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Planning;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Worksheet;

codeunit 5998 "Job Warehouse Mgt."
{
    var
        WhseManagement: Codeunit "Whse. Management";
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowSourceDocLine', '', false, false)]
    local procedure OnShowSourceDocLine(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer)
    begin
        if SourceType = Database::"Job Planning Line" then
            ShowJobPlanningLine(SourceLineNo);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowSourceDocCard', '', false, false)]
    local procedure OnShowSourceDocCard(SourceType: Integer; SourceSubType: Option; SourceNo: Code[20])
    var
        Job: Record Job;
    begin
        if SourceType = Database::Job then
            if Job.Get(SourceNo) then
                Page.RunModal(Page::"Job Card", Job);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"WMS Management", 'OnShowWhseActivityDocLine', '', false, false)]
    local procedure OnAfterShowWhseActivityDocLine(WhseActivityDocType: Enum "Warehouse Activity Document Type"; WhseDocNo: Code[20]; WhseDocLineNo: Integer)
    begin
        if WhseActivityDocType = WhseActivityDocType::Job then
            ShowJobPlanningLine(WhseDocLineNo);
    end;

    local procedure ShowJobPlanningLine(WhseDocLineNo: Integer)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.SetRange("Job Contract Entry No.", WhseDocLineNo);
        Page.RunModal(Page::"Job Planning Lines", JobPlanningLine);
    end;

    procedure JobPlanningLineVerifyChange(var NewJobPlanningLine: Record "Job Planning Line"; var OldJobPlanningLine: Record "Job Planning Line"; FieldNo: Integer)
    var
        NewRecordRef: RecordRef;
        OldRecordRef: RecordRef;
    begin
        if not WhseValidateSourceLine.WhseLinesExist(
             Database::Job, 0, NewJobPlanningLine."Job No.", NewJobPlanningLine."Job Contract Entry No.", NewJobPlanningLine."Line No.", NewJobPlanningLine.Quantity)
        then
            if not WhseValidateSourceLine.WhseWorkSheetLinesExist(
                Database::Job, 0, NewJobPlanningLine."Job No.", NewJobPlanningLine."Job Contract Entry No.", NewJobPlanningLine."Line No.", NewJobPlanningLine.Quantity)
            then
                exit;

        NewRecordRef.GetTable(NewJobPlanningLine);
        OldRecordRef.GetTable(OldJobPlanningLine);
        WhseValidateSourceLine.VerifyFieldNotChanged(NewRecordRef, OldRecordRef, FieldNo);
    end;

    procedure JobPlanningLineDelete(var JobPlanningLine: Record "Job Planning Line")
    begin
        if WhseValidateSourceLine.WhseLinesExist(Database::Job, 0, JobPlanningLine."Job No.", JobPlanningLine."Job Contract Entry No.", JobPlanningLine."Line No.", JobPlanningLine.Quantity) then
            WhseValidateSourceLine.RaiseCannotBeDeletedErr(JobPlanningLine.TableCaption());

        if WhseValidateSourceLine.WhseWorkSheetLinesExist(Database::Job, 0, JobPlanningLine."Job No.", JobPlanningLine."Job Contract Entry No.", JobPlanningLine."Line No.", JobPlanningLine.Quantity) then
            WhseValidateSourceLine.RaiseCannotBeDeletedErr(JobPlanningLine.TableCaption());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Management", 'OnAfterGetSrcDocLineQtyOutstanding', '', false, false)]
    local procedure OnAfterGetSrcDocLineQtyOutstanding(SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; var QtyBaseOutstanding: Decimal; var QtyOutstanding: Decimal)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        if SourceType in [Database::Job, Database::"Job Planning Line"] then begin
            JobPlanningLine.Setrange(Status, "Job Planning Line Status"::Order);
            JobPlanningLine.SetRange("Job No.", SourceNo);
            JobPlanningLine.SetRange("Job Contract Entry No.", SourceLineNo);
            JobPlanningLine.SetLoadFields("Remaining Qty.", "Remaining Qty. (Base)");
            if JobPlanningLine.FindFirst() then begin
                QtyOutstanding := JobPlanningLine."Remaining Qty.";
                QtyBaseOutstanding := JobPlanningLine."Remaining Qty. (Base)";
            end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Management", 'OnAfterGetSourceDocumentType', '', false, false)]
    local procedure WhseManagementGetSourceDocumentType(SourceType: Integer; SourceSubType: Integer; var SourceDocument: Enum "Warehouse Journal Source Document"; var IsHandled: Boolean)
    begin
        case SourceType of
            Database::"Job Journal Line":
                begin
                    SourceDocument := "Warehouse Journal Source Document"::"Job Jnl.";
                    IsHandled := true;
                end;
            Database::Job:
                begin
                    SourceDocument := "Warehouse Journal Source Document"::"Job Usage";
                    IsHandled := true;
                end;
            Database::"Job Planning Line":
                begin
                    SourceDocument := "Warehouse Journal Source Document"::"Job Usage";
                    IsHandled := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Management", 'OnAfterGetJournalSourceDocument', '', false, false)]
    local procedure WhseManagementGetJournalSourceDocument(SourceType: Integer; SourceSubType: Integer; var SourceDocument: Enum "Warehouse Journal Source Document"; var IsHandled: Boolean)
    begin
        if SourceType = Database::"Job Journal Line" then begin
            SourceDocument := SourceDocument::"Job Jnl.";
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Management", 'OnBeforeGetSourceType', '', false, false)]
    local procedure WhseManagementOnBeforeGetSourceType(WhseWorksheetLine: Record "Whse. Worksheet Line"; var SourceType: Integer; var IsHandled: Boolean)
    begin
        if WhseWorksheetLine."Whse. Document Type" = WhseWorksheetLine."Whse. Document Type"::Job then begin
            SourceType := Database::Job;
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Report, Report::"Create Pick", 'OnCheckSourceDocument', '', false, false)]
    local procedure CreatePickOnCheckSourceDocument(var PickWhseWkshLine: Record "Whse. Worksheet Line")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        if PickWhseWkshLine."Source Type" = Database::"Job Planning Line" then begin
            JobPlanningLine.SetRange("Job Contract Entry No.", PickWhseWkshLine."Source Line No.");
            if JobPlanningLine.IsEmpty() then
                Error(WhseManagement.GetSourceDocumentDoesNotExistErr(), JobPlanningLine.TableCaption(), JobPlanningLine.GetFilters());
            JobPlanningLine.TestStatusOpen();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse. Integration Management", 'OnCheckBinTypeAndCode', '', false, false)]
    local procedure OnCheckBinTypeAndCode(BinType: Record "Bin Type"; AdditionalIdentifier: Option; SourceTable: Integer)
    begin
        case SourceTable of
            Database::"Job Planning Line":
                BinType.AllowPutawayOrQCBinsOnly();
        end;
    end;
}
