// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Job;

using Microsoft.Foundation.UOM;
using Microsoft.Projects.Project.Journal;
using Microsoft.Assembly.History;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.Posting;
using Microsoft.Projects.Resources.Resource;

codeunit 1026 "Job Link Usage"
{
    Permissions = TableData "Job Usage Link" = rimd;

    trigger OnRun()
    begin
    end;

    var
        UOMMgt: Codeunit "Unit of Measure Management";
        CalledFromInvtPutawayPick: Boolean;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'The specified %1 does not have %2 enabled.', Comment = 'The specified Project Planning Line does not have Usage Link enabled.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ConfirmUsageWithBlankLineTypeQst: Label 'Usage will not be linked to the project planning line because the Line Type field is empty.\\Do you want to continue?';

    internal procedure ApplyUsage(JobLedgerEntry: Record "Job Ledger Entry"; JobJournalLine: Record "Job Journal Line"; IsCalledFromInventoryPutawayPick: Boolean)
    begin
        CalledFromInvtPutawayPick := IsCalledFromInventoryPutawayPick;
        ApplyUsage(JobLedgerEntry, JobJournalLine);
    end;

    procedure ApplyUsage(JobLedgerEntry: Record "Job Ledger Entry"; JobJournalLine: Record "Job Journal Line")
    begin
        if JobJournalLine."Job Planning Line No." = 0 then
            MatchUsageUnspecified(JobLedgerEntry, JobJournalLine."Line Type" = JobJournalLine."Line Type"::" ")
        else
            MatchUsageSpecified(JobLedgerEntry, JobJournalLine);

        OnAfterApplyUsage(JobLedgerEntry, JobJournalLine);
    end;

    local procedure MatchUsageUnspecified(JobLedgerEntry: Record "Job Ledger Entry"; EmptyLineType: Boolean)
    var
        JobPlanningLine: Record "Job Planning Line";
        JobUsageLink: Record "Job Usage Link";
        Confirmed, IsHandled : Boolean;
        MatchedQty: Decimal;
        MatchedTotalCost: Decimal;
        MatchedLineAmount: Decimal;
        RemainingQtyToMatch, RemainingQtyToMatchPerUoM : Decimal;
    begin
        RemainingQtyToMatch := JobLedgerEntry."Quantity (Base)";
        repeat
            if not FindMatchingJobPlanningLine(JobPlanningLine, JobLedgerEntry) then
                if EmptyLineType then begin
                    OnMatchUsageUnspecifiedOnBeforeConfirm(JobPlanningLine, JobLedgerEntry, Confirmed);
                    if not Confirmed then
                        Confirmed := Confirm(ConfirmUsageWithBlankLineTypeQst, false);
                    if not Confirmed then
                        Error('');
                    RemainingQtyToMatch := 0;
                end else
                    CreateJobPlanningLine(JobPlanningLine, JobLedgerEntry, RemainingQtyToMatch);

            IsHandled := false;
            OnMatchUsageUnspecifiedOnBeforeCheckPostedQty(JobPlanningLine, JobLedgerEntry, RemainingQtyToMatch, IsHandled);
            if not IsHandled then begin
                RemainingQtyToMatchPerUoM := UOMMgt.CalcQtyFromBase(RemainingQtyToMatch, JobPlanningLine."Qty. per Unit of Measure");
                if (RemainingQtyToMatchPerUoM = JobPlanningLine."Qty. Posted") and (JobPlanningLine."Remaining Qty. (Base)" = 0) then
                    exit;
            end;

            if RemainingQtyToMatch <> 0 then begin
                JobUsageLink.Create(JobPlanningLine, JobLedgerEntry);
                if Abs(RemainingQtyToMatch) > Abs(JobPlanningLine."Remaining Qty. (Base)") then
                    MatchedQty := JobPlanningLine."Remaining Qty. (Base)"
                else
                    MatchedQty := RemainingQtyToMatch;
                OnMatchUsageUnspecifiedOnAfterCalcMatchedQty(JobLedgerEntry, MatchedQty);
                MatchedTotalCost := (JobLedgerEntry."Total Cost" / JobLedgerEntry."Quantity (Base)") * MatchedQty;
                MatchedLineAmount := (JobLedgerEntry."Line Amount" / JobLedgerEntry."Quantity (Base)") * MatchedQty;

                OnBeforeJobPlanningLineUse(JobPlanningLine, JobLedgerEntry);
                JobPlanningLine.Use(
                    UOMMgt.CalcQtyFromBase(
                        JobPlanningLine."No.", JobPlanningLine."Variant Code", JobPlanningLine."Unit of Measure Code",
                        MatchedQty, JobPlanningLine."Qty. per Unit of Measure"),
                    MatchedTotalCost, MatchedLineAmount, JobLedgerEntry."Posting Date", JobLedgerEntry."Currency Factor");
                RemainingQtyToMatch -= MatchedQty;
                OnMatchUsageUnspecifiedOnAfterUpdateRemainingQtyToMatch(JobLedgerEntry, RemainingQtyToMatch);
            end;
        until RemainingQtyToMatch = 0;
    end;

    local procedure MatchUsageSpecified(JobLedgerEntry: Record "Job Ledger Entry"; JobJournalLine: Record "Job Journal Line")
    var
        JobPlanningLine: Record "Job Planning Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMatchUsageSpecified(JobPlanningLine, JobJournalLine, JobLedgerEntry, IsHandled);
        if IsHandled then
            exit;

        JobPlanningLine.Get(JobLedgerEntry."Job No.", JobLedgerEntry."Job Task No.", JobJournalLine."Job Planning Line No.");
        if not JobPlanningLine."Usage Link" then
            Error(Text001, JobPlanningLine.TableCaption(), JobPlanningLine.FieldCaption("Usage Link"));

        HandleMatchUsageSpecifiedJobPlanningLine(JobPlanningLine, JobJournalLine, JobLedgerEntry);

        OnAfterMatchUsageSpecified(JobPlanningLine, JobJournalLine, JobLedgerEntry);
    end;

    procedure HandleMatchUsageSpecifiedJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; JobJournalLine: Record "Job Journal Line"; JobLedgerEntry: Record "Job Ledger Entry")
    var
        JobUsageLink: Record "Job Usage Link";
        PostedQtyBase: Decimal;
        TotalQtyBase: Decimal;
        TotalRemainingQtyPrePostBase: Decimal;
        PartialJobPlanningLineQuantityPosting, UpdateQuantity : Boolean;
    begin
        if JobPlanningLine."Assemble to Order" then begin
            PostedQtyBase := AssembledQtyBase(JobPlanningLine);
            TotalRemainingQtyPrePostBase := JobPlanningLine."Qty. to Assemble (Base)" - AssembledQtyBase(JobPlanningLine);
        end else begin
            PostedQtyBase := JobPlanningLine."Quantity (Base)" - JobPlanningLine."Remaining Qty. (Base)";
            TotalRemainingQtyPrePostBase := JobJournalLine."Quantity (Base)" + JobJournalLine."Remaining Qty. (Base)";
        end;
        TotalQtyBase := PostedQtyBase + TotalRemainingQtyPrePostBase;
        OnBeforeHandleMatchUsageSpecifiedJobPlanningLine(PostedQtyBase, TotalRemainingQtyPrePostBase, TotalQtyBase, JobPlanningLine, JobJournalLine);
        JobPlanningLine.SetBypassQtyValidation(true);

        if Abs(UOMMgt.CalcQtyFromBase(JobPlanningLine."No.", JobPlanningLine."Variant Code", JobPlanningLine."Unit of Measure Code", TotalQtyBase, JobPlanningLine."Qty. per Unit of Measure")) < Abs(JobPlanningLine.Quantity) then begin
            PartialJobPlanningLineQuantityPosting := (JobLedgerEntry."Serial No." <> '') or (JobLedgerEntry."Lot No." <> '');
            HandleMatchUsageSpecifiedJobPlanningLineOnAfterCalcPartialJobPlanningLineQuantityPosting(JobPlanningLine, JobJournalLine, JobLedgerEntry, PartialJobPlanningLineQuantityPosting);
        end;
        // CalledFromInvtPutawayPick - Skip this quantity validation for Inventory Pick posting as quantity cannot be updated with an active Warehouse Activity Line.
        UpdateQuantity := not (CalledFromInvtPutawayPick or PartialJobPlanningLineQuantityPosting);
        OnHandleMatchUsageSpecifiedJobPlanningLineOnBeforeUpdateQuantity(JobPlanningLine, JobJournalLine, UpdateQuantity);
        if UpdateQuantity then
            if (TotalQtyBase > JobPlanningLine.Quantity) or (JobPlanningLine.Quantity = 0) then
                JobPlanningLine.Validate(Quantity,
                    UOMMgt.CalcQtyFromBase(
                        JobPlanningLine."No.", JobPlanningLine."Variant Code", JobPlanningLine."Unit of Measure Code",
                        TotalQtyBase, JobPlanningLine."Qty. per Unit of Measure"));

        JobPlanningLine.CopyTrackingFromJobLedgEntry(JobLedgerEntry);
        OnHandleMatchUsageSpecifiedJobPlanningLineOnBeforeJobPlanningLineUse(JobPlanningLine, JobJournalLine, JobLedgerEntry);
        JobPlanningLine.Use(
            UOMMgt.CalcQtyFromBase(
                JobPlanningLine."No.", JobPlanningLine."Variant Code", JobPlanningLine."Unit of Measure Code",
                JobLedgerEntry."Quantity (Base)", JobPlanningLine."Qty. per Unit of Measure"),
            JobLedgerEntry."Total Cost", JobLedgerEntry."Line Amount", JobLedgerEntry."Posting Date", JobLedgerEntry."Currency Factor");
        OnHandleMatchUsageSpecifiedJobPlanningLineOnAfterJobPlanningLineUse(JobPlanningLine, JobJournalLine, JobLedgerEntry);
        JobUsageLink.Create(JobPlanningLine, JobLedgerEntry);
    end;

    procedure FindMatchingJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; JobLedgerEntry: Record "Job Ledger Entry"): Boolean
    var
        Resource: Record Resource;
        "Filter": Text;
        JobPlanningLineFound: Boolean;
    begin
        JobPlanningLine.Reset();
        JobPlanningLine.SetCurrentKey("Job No.", "Schedule Line", Type, "No.", "Planning Date");
        JobPlanningLine.SetRange("Job No.", JobLedgerEntry."Job No.");
        JobPlanningLine.SetRange("Job Task No.", JobLedgerEntry."Job Task No.");
        JobPlanningLine.SetRange(Type, JobLedgerEntry.Type);
        JobPlanningLine.SetRange("No.", JobLedgerEntry."No.");
        JobPlanningLine.SetRange("Location Code", JobLedgerEntry."Location Code");
        JobPlanningLine.SetRange("Schedule Line", true);
        JobPlanningLine.SetRange("Usage Link", true);

        if JobLedgerEntry.Type = JobLedgerEntry.Type::Resource then begin
            Filter := Resource.GetUnitOfMeasureFilter(JobLedgerEntry."No.", JobLedgerEntry."Unit of Measure Code");
            JobPlanningLine.SetFilter("Unit of Measure Code", Filter);
        end;

        if (JobLedgerEntry."Line Type" = JobLedgerEntry."Line Type"::Billable) or
           (JobLedgerEntry."Line Type" = JobLedgerEntry."Line Type"::"Both Budget and Billable")
        then
            JobPlanningLine.SetRange("Contract Line", true);

        if JobLedgerEntry.Quantity > 0 then
            JobPlanningLine.SetFilter("Remaining Qty.", '>0')
        else
            JobPlanningLine.SetFilter("Remaining Qty.", '<0');

        case JobLedgerEntry.Type of
            JobLedgerEntry.Type::Item:
                JobPlanningLine.SetRange("Variant Code", JobLedgerEntry."Variant Code");
            JobLedgerEntry.Type::Resource:
                JobPlanningLine.SetRange("Work Type Code", JobLedgerEntry."Work Type Code");
        end;

        // Match most specific Job Planning Line.
        OnFindMatchingJobPlanningLineOnBeforeMatchSpecificJobPlanningLine(JobPlanningLine, JobLedgerEntry);
        if JobPlanningLine.FindFirst() then
            exit(true);

        JobPlanningLine.SetRange("Variant Code", '');
        JobPlanningLine.SetRange("Work Type Code", '');

        // Match Location Code, while Variant Code and Work Type Code are blank.
        OnFindMatchingJobPlanningLineOnBeforeMatchJobPlanningLineLocation(JobPlanningLine, JobLedgerEntry);
        if JobPlanningLine.FindFirst() then
            exit(true);

        JobPlanningLine.SetRange("Location Code", '');

        case JobLedgerEntry.Type of
            JobLedgerEntry.Type::Item:
                JobPlanningLine.SetRange("Variant Code", JobLedgerEntry."Variant Code");
            JobLedgerEntry.Type::Resource:
                JobPlanningLine.SetRange("Work Type Code", JobLedgerEntry."Work Type Code");
        end;

        // Match Variant Code / Work Type Code, while Location Code is blank.
        if JobPlanningLine.FindFirst() then
            exit(true);

        JobPlanningLine.SetRange("Variant Code", '');
        JobPlanningLine.SetRange("Work Type Code", '');

        // Match unspecific Job Planning Line.
        if JobPlanningLine.FindFirst() then
            exit(true);

        JobPlanningLineFound := false;
        OnAfterFindMatchingJobPlanningLine(JobPlanningLine, JobLedgerEntry, JobPlanningLineFound);
        exit(JobPlanningLineFound);
    end;

    local procedure CreateJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; JobLedgerEntry: Record "Job Ledger Entry"; RemainingQtyToMatch: Decimal)
    var
        Job: Record Job;
        JobPostLine: Codeunit "Job Post-Line";
    begin
        RemainingQtyToMatch :=
            UOMMgt.CalcQtyFromBase(
                JobLedgerEntry."No.", JobLedgerEntry."Variant Code", JobLedgerEntry."Unit of Measure Code",
                RemainingQtyToMatch, JobLedgerEntry."Qty. per Unit of Measure");

        case JobLedgerEntry."Line Type" of
            JobLedgerEntry."Line Type"::" ":
                JobLedgerEntry."Line Type" := JobLedgerEntry."Line Type"::Budget;
            JobLedgerEntry."Line Type"::Billable:
                JobLedgerEntry."Line Type" := JobLedgerEntry."Line Type"::"Both Budget and Billable";
        end;
        JobPlanningLine.Reset();
        JobPostLine.InsertPlLineFromLedgEntry(JobLedgerEntry);
        // Retrieve the newly created Job PlanningLine.
        JobPlanningLine.SetRange("Job No.", JobLedgerEntry."Job No.");
        JobPlanningLine.SetRange("Job Task No.", JobLedgerEntry."Job Task No.");
        JobPlanningLine.SetRange("Schedule Line", true);
        JobPlanningLine.FindLast();
        JobPlanningLine.Validate("Usage Link", true);
        JobPlanningLine.Validate(Quantity, RemainingQtyToMatch);
        OnBeforeModifyJobPlanningLine(JobPlanningLine, JobLedgerEntry);
        JobPlanningLine.Modify();

        // If type is Both Budget And Billable and that type isn't allowed,
        // retrieve the Billabe line and modify the quantity as well.
        // Do the same if the type is G/L Account (Job Planning Lines will always be split in one Budget and one Billable line).
        Job.Get(JobLedgerEntry."Job No.");
        if (JobLedgerEntry."Line Type" = JobLedgerEntry."Line Type"::"Both Budget and Billable") and
           ((not Job."Allow Schedule/Contract Lines") or (JobLedgerEntry.Type = JobLedgerEntry.Type::"G/L Account"))
        then begin
            JobPlanningLine.Get(JobLedgerEntry."Job No.", JobLedgerEntry."Job Task No.", JobPlanningLine."Line No." + 10000);
            JobPlanningLine.Validate(Quantity, RemainingQtyToMatch);
            JobPlanningLine.Modify();
            JobPlanningLine.Get(JobLedgerEntry."Job No.", JobLedgerEntry."Job Task No.", JobPlanningLine."Line No." - 10000);
        end;
    end;

    local procedure AssembledQtyBase(var JobPlanningLine: Record "Job Planning Line") AssembledQty: Decimal
    var
        PostedATOLink: Record "Posted Assemble-to-Order Link";
    begin
        PostedATOLink.SetCurrentKey("Job No.", "Job Task No.", "Document Line No.");
        PostedATOLink.SetRange("Job No.", JobPlanningLine."Job No.");
        PostedATOLink.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        PostedATOLink.SetRange("Document Line No.", JobPlanningLine."Line No.");
        if PostedATOLink.FindSet() then
            repeat
                AssembledQty += PostedATOLink."Assembled Quantity (Base)";
            until PostedATOLink.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindMatchingJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; JobLedgerEntry: Record "Job Ledger Entry"; var JobPlanningLineFound: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterMatchUsageSpecified(var JobPlanningLine: Record "Job Planning Line"; var JobJournalLine: Record "Job Journal Line"; var JobLedgerEntry: Record "Job Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; JobLedgerEntry: Record "Job Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeJobPlanningLineUse(var JobPlanningLine: Record "Job Planning Line"; JobLedgerEntry: Record "Job Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMatchUsageSpecified(var JobPlanningLine: Record "Job Planning Line"; var JobJournalLine: Record "Job Journal Line"; var JobLedgerEntry: Record "Job Ledger Entry"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleMatchUsageSpecifiedJobPlanningLineOnAfterJobPlanningLineUse(var JobPlanningLine: Record "Job Planning Line"; JobJournalLine: Record "Job Journal Line"; JobLedgerEntry: Record "Job Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleMatchUsageSpecifiedJobPlanningLineOnBeforeJobPlanningLineUse(var JobPlanningLine: Record "Job Planning Line"; JobJournalLine: Record "Job Journal Line"; JobLedgerEntry: Record "Job Ledger Entry");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMatchUsageUnspecifiedOnBeforeConfirm(JobPlanningLine: Record "Job Planning Line"; JobLedgerEntry: Record "Job Ledger Entry"; var Confirmed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMatchUsageUnspecifiedOnAfterCalcMatchedQty(var JobLedgerEntry: Record "Job Ledger Entry"; var MatchedQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMatchUsageUnspecifiedOnAfterUpdateRemainingQtyToMatch(var JobLedgerEntry: Record "Job Ledger Entry"; var RemainingQtyToMatch: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindMatchingJobPlanningLineOnBeforeMatchSpecificJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; JobLedgerEntry: Record "Job Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindMatchingJobPlanningLineOnBeforeMatchJobPlanningLineLocation(var JobPlanningLine: Record "Job Planning Line"; JobLedgerEntry: Record "Job Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure HandleMatchUsageSpecifiedJobPlanningLineOnAfterCalcPartialJobPlanningLineQuantityPosting(JobPlanningLine: Record "Job Planning Line"; JobJournalLine: Record "Job Journal Line"; JobLedgerEntry: Record "Job Ledger Entry"; var PartialJobPlanningLineQuantityPosting: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandleMatchUsageSpecifiedJobPlanningLine(var PostedQtyBase: Decimal; var TotalQtyBase: Decimal; var TotalRemainingQtyPrePostBase: Decimal; JobPlanningLine: Record "Job Planning Line"; JobJournalLine: Record "Job Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnHandleMatchUsageSpecifiedJobPlanningLineOnBeforeUpdateQuantity(var JobPlanningLine: Record "Job Planning Line"; JobJournalLine: Record "Job Journal Line"; var UpdateQuantity: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMatchUsageUnspecifiedOnBeforeCheckPostedQty(JobPlanningLine: Record "Job Planning Line"; JobLedgerEntry: Record "Job Ledger Entry"; RemainingQtyToMatch: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterApplyUsage(var JobLedgerEntry: Record "Job Ledger Entry"; var JobJournalLine: Record "Job Journal Line")
    begin
    end;
}

