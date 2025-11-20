// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Posting;

using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.TimeSheet;
using Microsoft.Warehouse.Request;
using System.Security.User;

codeunit 1011 "Job Jnl.-Check Line"
{
    TableNo = "Job Journal Line";

    trigger OnRun()
    begin
        RunCheck(Rec);
    end;

    var
        Location: Record Location;
        DimMgt: Codeunit DimensionManagement;
        TimeSheetMgt: Codeunit "Time Sheet Management";
        CalledFromInvtPutawayPick: Boolean;
        CalledFromPurchase: Boolean;

#pragma warning disable AA0074
        Text000: Label 'cannot be a closing date.';
        Text001: Label 'is not within your range of allowed posting dates.';
#pragma warning restore AA0074
        CombinationBlockedErr: Label 'The combination of dimensions used in %1 %2, %3, %4 is blocked. %5.', Comment = '%1 = table name, %2 = template name, %3 = batch name, %4 = line no., %5 - error text';
        DimensionCausedErr: Label 'A dimension used in %1 %2, %3, %4 has caused an error. %5.', Comment = '%1 = table name, %2 = template name, %3 = batch name, %4 = line no., %5 - error text';
#pragma warning disable AA0074
        Text004: Label 'You must post more usage of %1 %2 in %3 %4 before you can post project journal %5 %6 = %7.', Comment = '%1=Item;%2=ProjectJnlline."No.";%3=Project;%4=ProjectJnlline."Project No.";%5=ProjectJnlline."Journal Batch Name";%6="Line No";%7=ProjectJnlline."Line No."';
#pragma warning restore AA0074
        WhseRemainQtyPickedErr: Label 'You cannot post usage for project number %1 with project planning line %2 because a quantity of %3 remains to be picked.', Comment = '%1 = 12345, %2 = 1000, %3 = 5';

    procedure RunCheck(var JobJnlLine: Record "Job Journal Line")
    begin
        OnBeforeRunCheck(JobJnlLine);

        if JobJnlLine.EmptyLine() then
            exit;

        TestJobJnlLine(JobJnlLine);

        TestJobStatusOpen(JobJnlLine);

        CheckPostingDate(JobJnlLine);

        CheckDocumentDate(JobJnlLine);

        if JobJnlLine."Time Sheet No." <> '' then
            TimeSheetMgt.CheckJobJnlLine(JobJnlLine);

        CheckDim(JobJnlLine);

        CheckItemQuantityAndBinCode(JobJnlLine);

        TestJobJnlLineChargeable(JobJnlLine);

        CheckWhseQtyPicked(JobJnlLine);

        OnAfterRunCheck(JobJnlLine);
    end;

    internal procedure SetCalledFromInvtPutawayPick(NewCalledFromInvtPutawayPick: Boolean)
    begin
        CalledFromInvtPutawayPick := NewCalledFromInvtPutawayPick;
    end;

    internal procedure SetCalledFromPurchase(NewCalledFromPurchase: Boolean)
    begin
        CalledFromPurchase := NewCalledFromPurchase;
    end;

    local procedure CheckItemQuantityAndBinCode(var JobJournalLine: Record "Job Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemQuantityAndBinCode(JobJournalLine, IsHandled);
        if IsHandled then
            exit;

        if JobJournalLine.Type <> JobJournalLine.Type::Item then
            exit;

        if (JobJournalLine."Quantity (Base)" < 0) and (JobJournalLine."Entry Type" = JobJournalLine."Entry Type"::Usage) then
            CheckItemQuantityJobJnl(JobJournalLine);
        GetLocation(JobJournalLine."Location Code");

        IsHandled := false;
        OnCheckItemQuantityAndBinCodeOnBeforeCheckBinCode(JobJournalLine, IsHandled);
        if not IsHandled then
            if Location."Bin Mandatory" and JobJournalLine.IsInventoriableItem() then
                JobJournalLine.TestField("Bin Code", ErrorInfo.Create());
    end;

    local procedure TestJobStatusOpen(var JobJnlLine: Record "Job Journal Line")
    var
        Job: Record Job;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnRunCheckOnBeforeTestFieldJobStatus(IsHandled, JobJnlLine);
        if IsHandled then
            exit;

        Job.Get(JobJnlLine."Job No.");
        Job.TestField(Status, Job.Status::Open, ErrorInfo.Create());
    end;

    local procedure TestJobJnlLineChargeable(JobJnlLine: Record "Job Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestChargeable(JobJnlLine, IsHandled);
        if IsHandled then
            exit;

        if JobJnlLine."Line Type" in [JobJnlLine."Line Type"::Billable, JobJnlLine."Line Type"::"Both Budget and Billable"] then
            JobJnlLine.TestField(Chargeable, true, ErrorInfo.Create());
    end;

    local procedure CheckDocumentDate(JobJnlLine: Record "Job Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDocumentDate(JobJnlLine, IsHandled);
        if IsHandled then
            exit;

        if (JobJnlLine."Document Date" <> 0D) and (JobJnlLine."Document Date" <> NormalDate(JobJnlLine."Document Date")) then
            JobJnlLine.FieldError("Document Date", ErrorInfo.Create(Text000, true));
    end;

    local procedure CheckPostingDate(JobJnlLine: Record "Job Journal Line")
    var
        UserSetupManagement: Codeunit "User Setup Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckPostingDate(JobJnlLine, IsHandled);
        if IsHandled then
            exit;

        if NormalDate(JobJnlLine."Posting Date") <> JobJnlLine."Posting Date" then
            JobJnlLine.FieldError("Posting Date", ErrorInfo.Create(Text000, true));
        if not UserSetupManagement.IsPostingDateValid(JobJnlLine."Posting Date") then
            JobJnlLine.FieldError("Posting Date", ErrorInfo.Create(Text001, true));
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if Location.Code <> LocationCode then
                Location.Get(LocationCode);
    end;

    local procedure CheckDim(JobJnlLine: Record "Job Journal Line")
    var
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckDim(JobJnlLine, IsHandled);
        if IsHandled then
            exit;

        if not DimMgt.CheckDimIDComb(JobJnlLine."Dimension Set ID") then
            Error(
                CombinationBlockedErr,
                JobJnlLine.TableCaption(), JobJnlLine."Journal Template Name", JobJnlLine."Journal Batch Name", JobJnlLine."Line No.",
                DimMgt.GetDimCombErr());

        TableID[1] := DATABASE::Job;
        No[1] := JobJnlLine."Job No.";
        TableID[2] := DimMgt.TypeToTableID2(JobJnlLine.Type.AsInteger());
        No[2] := JobJnlLine."No.";
        TableID[3] := DATABASE::"Resource Group";
        No[3] := JobJnlLine."Resource Group No.";
        TableID[4] := Database::Location;
        No[4] := JobJnlLine."Location Code";
        OnCheckDimOnAfterCreateDimTableID(JobJnlLine, TableID, No);

        if not DimMgt.CheckDimValuePosting(TableID, No, JobJnlLine."Dimension Set ID") then begin
            if JobJnlLine."Line No." <> 0 then
                Error(
                    ErrorInfo.Create(
                        StrSubstNo(
                            DimensionCausedErr,
                            JobJnlLine.TableCaption(), JobJnlLine."Journal Template Name", JobJnlLine."Journal Batch Name", JobJnlLine."Line No.",
                            DimMgt.GetDimValuePostingErr()),
                        true));
            Error(ErrorInfo.Create(DimMgt.GetDimValuePostingErr(), true));
        end;
    end;

    local procedure CheckItemQuantityJobJnl(var JobJnlline: Record "Job Journal Line")
    var
        Item: Record Item;
        Job: Record Job;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckItemQuantityJobJnl(JobJnlline, IsHandled);
        if IsHandled then
            exit;

        if JobJnlline.IsNonInventoriableItem() then
            exit;

        Job.Get(JobJnlline."Job No.");
        if (Job.GetQuantityAvailable(JobJnlline."No.", JobJnlline."Location Code", JobJnlline."Variant Code", 0, 2) +
            JobJnlline."Quantity (Base)") < 0
        then
            Error(
                ErrorInfo.Create(
                    StrSubstNo(
                        Text004, Item.TableCaption(), JobJnlline."No.", Job.TableCaption(),
                        JobJnlline."Job No.", JobJnlline."Journal Batch Name",
                        JobJnlline.FieldCaption("Line No."), JobJnlline."Line No."),
                    true));
    end;

    local procedure CheckWhseQtyPicked(var JobJournalLine: Record "Job Journal Line")
    var
        JobPlanningLine: Record "Job Planning Line";
        WhseValidateSourceLine: Codeunit "Whse. Validate Source Line";
        ShouldCheckWhseQtyPicked: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWhseQtyPicked(JobJournalLine, IsHandled);
        if IsHandled then
            exit;

        if CalledFromInvtPutawayPick or CalledFromPurchase then
            exit;

        ShouldCheckWhseQtyPicked := WhseValidateSourceLine.IsWhsePickRequiredForJobJnlLine(JobJournalLine);
        if not ShouldCheckWhseQtyPicked then
            ShouldCheckWhseQtyPicked := WhseValidateSourceLine.IsInventoryPickRequiredForJobJnlLine(JobJournalLine);
        if ShouldCheckWhseQtyPicked then begin
            JobPlanningLine.SetLoadFields(Quantity, "Qty. Picked", "Qty. Posted", "Qty. to Assemble");
            if JobPlanningLine.Get(JobJournalLine."Job No.", JobJournalLine."Job Task No.", JobJournalLine."Job Planning Line No.") and (JobPlanningLine."Qty. Picked" - JobPlanningLine."Qty. Posted" < JobJournalLine.Quantity - JobPlanningLine."Qty. to Assemble") then
                JobPlanningLine.FieldError("Qty. Picked", ErrorInfo.Create(StrSubstNo(WhseRemainQtyPickedErr, JobPlanningLine."Job No.", JobPlanningLine."Line No.", JobJournalLine.Quantity + JobPlanningLine."Qty. Posted" - JobPlanningLine."Qty. Picked" - JobPlanningLine."Qty. to Assemble"), true));
        end;
    end;

    local procedure TestJobJnlLine(JobJournalLine: Record "Job Journal Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTestJobJnlLine(JobJournalLine, IsHandled);
        if IsHandled then
            exit;

        JobJournalLine.TestField("Job No.", ErrorInfo.Create());
        JobJournalLine.TestField("Job Task No.", ErrorInfo.Create());
        JobJournalLine.TestField("No.", ErrorInfo.Create());
        JobJournalLine.TestField("Posting Date", ErrorInfo.Create());
        JobJournalLine.TestField(Quantity, ErrorInfo.Create());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRunCheck(var JobJnlLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDocumentDate(var JobJnlLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckPostingDate(var JobJnlLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWhseQtyPicked(var JobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunCheck(var JobJnlLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckDim(var JobJnlLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemQuantityAndBinCode(JobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckItemQuantityJobJnl(var JobJnlLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestJobJnlLine(JobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTestChargeable(JobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckDimOnAfterCreateDimTableID(JobJournalLine: Record "Job Journal Line"; var TableID: array[10] of Integer; var No: array[10] of Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunCheckOnBeforeTestFieldJobStatus(var IsHandled: Boolean; var JobJnlLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckItemQuantityAndBinCodeOnBeforeCheckBinCode(JobJournalLine: Record "Job Journal Line"; var IsHandled: Boolean)
    begin
    end;
}

