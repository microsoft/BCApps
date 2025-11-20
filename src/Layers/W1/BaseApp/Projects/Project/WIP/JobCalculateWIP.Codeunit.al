// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.WIP;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using System.Utilities;

codeunit 1000 "Job Calculate WIP"
{
    Permissions = TableData "Job Ledger Entry" = rm,
                  TableData "Job Task" = rimd,
                  TableData "Job Planning Line" = r,
                  TableData "Job WIP Entry" = rimd,
                  TableData "Job WIP G/L Entry" = rimd;

    trigger OnRun()
    begin
    end;

    var
        TempJobWIPBuffer: array[2] of Record "Job WIP Buffer" temporary;
        GLSetup: Record "General Ledger Setup";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnPostLine: Codeunit "Gen. Jnl.-Post Line";
        DimMgt: Codeunit DimensionManagement;
        ErrorMessageMgt: Codeunit "Error Message Management";
        ErrorContextElement: Codeunit "Error Context Element";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        WIPPostingDate: Date;
        DocNo: Code[20];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'WIP %1', Comment = 'WIP GUILDFORD, 10 CR';
        Text002: Label 'Recognition %1', Comment = 'Recognition GUILDFORD, 10 CR';
        Text003: Label 'Completion %1', Comment = 'Completion GUILDFORD, 10 CR';
#pragma warning restore AA0470
#pragma warning restore AA0074
        JobComplete: Boolean;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text004: Label 'WIP G/L entries posted for Project %1 cannot be reversed at an earlier date than %2.';
        Text005: Label '..%1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        HasGotGLSetup: Boolean;
        JobWIPTotalChanged: Boolean;
        WIPAmount: Decimal;
        RecognizedAllocationPercentage: Decimal;
        CannotModifyAssociatedEntriesErr: Label 'The %1 cannot be modified because the project has associated project WIP entries.', Comment = '%1=The project task table name.';

    procedure JobCalcWIP(var Job: Record Job; WIPPostingDate2: Date; DocNo2: Code[20])
    var
        JobTask: Record "Job Task";
        JobLedgEntry: Record "Job Ledger Entry";
        JobLedgerEntry2: Record "Job Ledger Entry";
        JobPlanningLine: Record "Job Planning Line";
        JobWIPEntry: Record "Job WIP Entry";
        JobWIPGLEntry: Record "Job WIP G/L Entry";
        FromJobTask: Code[20];
        First: Boolean;
    begin
        ClearAll();
        TempJobWIPBuffer[1].DeleteAll();

        JobPlanningLine.LockTable();
        JobLedgEntry.LockTable();
        JobWIPEntry.LockTable();
        JobTask.LockTable();
        Job.LockTable();

        JobWIPGLEntry.SetCurrentKey("Job No.", Reversed, "Job Complete");
        JobWIPGLEntry.SetRange("Job No.", Job."No.");
        JobWIPGLEntry.SetRange("Job Complete", true);
        if JobWIPGLEntry.FindFirst() then begin
            JobWIPEntry.DeleteEntriesForJob(Job);
            exit;
        end;

        if WIPPostingDate2 = 0D then
            WIPPostingDate := WorkDate()
        else
            WIPPostingDate := WIPPostingDate2;
        DocNo := DocNo2;

        ActivateErrorMessageHandling(Job);

        Job.TestBlocked();
        Job.TestField("WIP Method");
        Job."WIP Posting Date" := WIPPostingDate;
        if (Job."Ending Date" = 0D) and Job.Complete then
            Job.Validate("Ending Date", WIPPostingDate);
        JobComplete := Job.Complete and (WIPPostingDate >= Job."Ending Date");
        OnJobCalcWIPOnBeforeJobModify(Job, JobComplete);
        Job.Modify();

        DeleteWIP(Job);
        AssignWIPTotalAndMethodToJobTask(JobTask, Job);
        First := true;
        if JobTask.Find('-') then
            repeat
                if First then
                    FromJobTask := JobTask."Job Task No.";
                First := false;
                if JobTask."WIP-Total" = JobTask."WIP-Total"::Total then begin
                    JobTaskCalcWIP(Job, FromJobTask, JobTask."Job Task No.");
                    First := true;
                    AssignWIPTotalAndMethodToRemainingJobTask(JobTask, Job);
                    // Balance job ledger entry when used quantity on a task is returned
                    if (JobTask."Recognized Sales Amount" = 0) and (JobTask."Recognized Sales G/L Amount" <> 0) then begin
                        JobLedgerEntry2.SetRange("Job No.", JobTask."Job No.");
                        JobLedgerEntry2.SetRange("Job Task No.", JobTask."Job Task No.");
                        JobLedgerEntry2.SetRange("Entry Type", JobLedgerEntry2."Entry Type"::Sale);
                        JobLedgerEntry2.SetLoadFields("Line Amount (LCY)", "Amt. to Post to G/L", "Amt. Posted to G/L");
                        if JobLedgerEntry2.FindSet(true) then
                            repeat
                                if (JobLedgerEntry2."Line Amount (LCY)" <> 0) and (JobLedgerEntry2."Amt. to Post to G/L" = 0) and (JobLedgerEntry2."Amt. Posted to G/L" = 0) then begin
                                    JobLedgerEntry2.Validate("Amt. to Post to G/L", JobLedgerEntry2."Line Amount (LCY)");
                                    JobLedgerEntry2.Modify(true);
                                end;
                            until JobLedgerEntry2.Next() = 0;
                    end;
                end;
            until JobTask.Next() = 0;
        CreateWIPEntries(Job."No.");

        if ErrorMessageHandler.HasErrors() then
            if ErrorMessageHandler.ShowErrors() then
                Error('');
    end;

    local procedure ActivateErrorMessageHandling(var Job: Record Job)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeActivateErrorMessageHandling(Job, ErrorMessageMgt, ErrorMessageHandler, ErrorContextElement, IsHandled);
        if IsHandled then
            exit;

        if GuiAllowed then begin
            ErrorMessageMgt.Activate(ErrorMessageHandler);
            ErrorMessageMgt.PushContext(ErrorContextElement, Job.RecordId, 0, '');
        end;
    end;

    procedure DeleteWIP(Job: Record Job)
    var
        JobTask: Record "Job Task";
        JobWIPEntry: Record "Job WIP Entry";
        JobLedgerEntry: Record "Job Ledger Entry";
    begin
        JobTask.SetRange("Job No.", Job."No.");
        if JobTask.Find('-') then
            repeat
                JobTask.InitWIPFields();
            until JobTask.Next() = 0;

        JobWIPEntry.DeleteEntriesForJob(Job);

        JobLedgerEntry.SetRange("Job No.", Job."No.");
        JobLedgerEntry.ModifyAll("Amt. to Post to G/L", 0);
    end;

    local procedure JobTaskCalcWIP(var Job: Record Job; FromJobTask: Code[20]; ToJobTask: Code[20])
    var
        AccruedCostsJobTask: Record "Job Task";
        AccruedCostsJobWIPTotal: Record "Job WIP Total";
        JobTask: Record "Job Task";
        JobWIPTotal: Record "Job WIP Total";
        JobWIPWarning: Record "Job WIP Warning";
        RecognizedCostAmount: Decimal;
        UsageTotalCost: Decimal;
        IsHandled: Boolean;
    begin
        RecognizedCostAmount := 0;
        UsageTotalCost := 0;

        JobTask.SetRange("Job No.", Job."No.");
        JobTask.SetRange("Job Task No.", FromJobTask, ToJobTask);
        JobTask.SetFilter("WIP-Total", '<> %1', JobTask."WIP-Total"::Excluded);

        if Job.GetFilter("Posting Date Filter") <> '' then
            JobTask.SetFilter("Posting Date Filter", Job.GetFilter("Posting Date Filter"))
        else
            JobTask.SetFilter("Posting Date Filter", StrSubstNo(Text005, WIPPostingDate));

        JobTask.SetFilter("Planning Date Filter", Job.GetFilter("Planning Date Filter"));

        CreateJobWIPTotal(JobTask, JobWIPTotal);

        if JobTask.Find('-') then
            repeat
                if JobTask."Job Task Type" = JobTask."Job Task Type"::Posting then begin
                    JobTask.CalcFields(
                      "Schedule (Total Cost)",
                      "Schedule (Total Price)",
                      "Usage (Total Cost)",
                      "Usage (Total Price)",
                      "Contract (Total Cost)",
                      "Contract (Total Price)",
                      "Contract (Invoiced Price)",
                      "Contract (Invoiced Cost)");

                    OnJobTaskCalcWIPOnBeforeCalcWIP(JobTask);

                    CalcWIP(JobTask, JobWIPTotal);
                    JobTask.Modify();

                    JobWIPTotal."Calc. Recog. Costs Amount" += JobTask."Recognized Costs Amount";
                    JobWIPTotal."Calc. Recog. Sales Amount" += JobTask."Recognized Sales Amount";
                    IsHandled := false;
                    OnJobTaskCalcWIPOnBeforeCreateTempJobWIPBuffer(JobTask, JobWIPTotal, IsHandled);
                    if not IsHandled then
                        CreateTempJobWIPBuffers(JobTask, JobWIPTotal);
                    if (JobTask."Recognized Costs Amount" <> 0) and (AccruedCostsJobTask."Job Task No." = '') then begin
                        AccruedCostsJobTask := JobTask;
                        AccruedCostsJobWIPTotal := JobWIPTotal;
                    end;

                    IsHandled := false;
                    OnJobTaskCalcWIPOnBeforeSumJobTaskCosts(JobTask, RecognizedCostAmount, UsageTotalCost, IsHandled);
                    if not IsHandled then begin
                        RecognizedCostAmount += JobTask."Recognized Costs Amount";
                        UsageTotalCost += JobTask."Usage (Total Cost)";
                    end;

                    JobWIPTotalChanged := false;
                    WIPAmount := 0;
                end;
            until JobTask.Next() = 0;
        JobTaskCalcAccruedCostsWIP(Job, AccruedCostsJobWIPTotal, AccruedCostsJobTask, RecognizedCostAmount, UsageTotalCost);
        CalcCostInvoicePercentage(JobWIPTotal);
        OnJobTaskCalcWIPOnBeforeJobWIPTotalModify(Job, JobWIPTotal);
        JobWIPTotal.Modify();
        OnJobTaskCalcWIPOnAfterJobWIPTotalModify(Job, JobWIPTotal);
        JobWIPWarning.CreateEntries(JobWIPTotal);

        OnAfterJobTaskCalcWIP(Job, FromJobTask, ToJobTask, JobWIPTotal);
    end;

    local procedure JobTaskCalcAccruedCostsWIP(Job: Record Job; AccruedCostsJobWIPTotal: Record "Job WIP Total"; AccruedCostsJobTask: Record "Job Task"; RecognizedCostAmount: Decimal; UsageTotalCost: Decimal)
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        if (not JobComplete) and (RecognizedCostAmount > UsageTotalCost) and (AccruedCostsJobTask."Job Task No." <> '') then begin
            JobWIPMethod.Get(AccruedCostsJobWIPTotal."WIP Method");
            InitWIPBufferEntryFromTask(
              AccruedCostsJobTask, AccruedCostsJobWIPTotal, Enum::"Job WIP Buffer Type"::"Accrued Costs",
              GetAccruedCostsAmount(JobWIPMethod, RecognizedCostAmount, UsageTotalCost));
            UpdateWIPBufferEntryFromTask(AccruedCostsJobTask, AccruedCostsJobWIPTotal);
            if Job."WIP Posting Method" = Job."WIP Posting Method"::"Per Job Ledger Entry" then begin
                InitWIPBufferEntryFromTask(
                  AccruedCostsJobTask, AccruedCostsJobWIPTotal, Enum::"Job WIP Buffer Type"::"Applied Costs",
                  GetAppliedCostsAmount(RecognizedCostAmount, UsageTotalCost, JobWIPMethod, true));
                UpdateWIPBufferEntryFromTask(AccruedCostsJobTask, AccruedCostsJobWIPTotal);
            end;
        end;
    end;

    local procedure CreateJobWIPTotal(var JobTask: Record "Job Task"; var JobWIPTotal: Record "Job WIP Total")
    var
        IsHandled: Boolean;
    begin
        OnBeforeCreateJobWIPTotal(JobTask);
        JobWIPTotalChanged := true;
        WIPAmount := 0;
        RecognizedAllocationPercentage := 0;

        JobWIPTotal.Init();
        IsHandled := false;
        OnCreateJobWIPTotalOnBeforeLoopJobTask(JobTask, JobWIPTotal, IsHandled);
        if not IsHandled then
            if JobTask.Find('-') then
                repeat
                    if JobTask."Job Task Type" = JobTask."Job Task Type"::Posting then begin
                        JobTask.CalcFields(
                        "Schedule (Total Cost)",
                        "Schedule (Total Price)",
                        "Usage (Total Cost)",
                        "Usage (Total Price)",
                        "Contract (Total Cost)",
                        "Contract (Total Price)",
                        "Contract (Invoiced Price)",
                        "Contract (Invoiced Cost)");

                        JobWIPTotal."Schedule (Total Cost)" += JobTask."Schedule (Total Cost)";
                        JobWIPTotal."Schedule (Total Price)" += JobTask."Schedule (Total Price)";
                        JobWIPTotal."Usage (Total Cost)" += JobTask."Usage (Total Cost)";
                        JobWIPTotal."Usage (Total Price)" += JobTask."Usage (Total Price)";
                        JobWIPTotal."Contract (Total Cost)" += JobTask."Contract (Total Cost)";
                        JobWIPTotal."Contract (Total Price)" += JobTask."Contract (Total Price)";
                        JobWIPTotal."Contract (Invoiced Price)" += JobTask."Contract (Invoiced Price)";
                        JobWIPTotal."Contract (Invoiced Cost)" += JobTask."Contract (Invoiced Cost)";

                        OnCreateJobWIPTotalOnAfterUpdateJobWIPTotal(JobTask, JobWIPTotal);
                    end;
                until JobTask.Next() = 0;

        // Get values from the "WIP-Total"::Total Job Task, which always is the last entry in the range:
        JobWIPTotal."Job No." := JobTask."Job No.";
        JobWIPTotal."Job Task No." := JobTask."Job Task No.";
        JobWIPTotal."WIP Posting Date" := WIPPostingDate;
        JobWIPTotal."WIP Posting Date Filter" :=
          CopyStr(JobTask.GetFilter("Posting Date Filter"), 1, MaxStrLen(JobWIPTotal."WIP Posting Date Filter"));
        JobWIPTotal."WIP Planning Date Filter" :=
          CopyStr(JobTask.GetFilter("Planning Date Filter"), 1, MaxStrLen(JobWIPTotal."WIP Planning Date Filter"));
        JobWIPTotal."WIP Method" := JobTask."WIP Method";
        JobWIPTotal.Insert();
    end;

    local procedure CalcWIP(var JobTask: Record "Job Task"; JobWIPTotal: Record "Job WIP Total")
    var
        JobWIPMethod: Record "Job WIP Method";
    begin
        OnBeforeCalcWIP(JobTask, JobWIPTotal, JobComplete, RecognizedAllocationPercentage, JobWIPTotalChanged);

        if JobComplete then begin
            JobTask."Recognized Sales Amount" := JobTask."Contract (Invoiced Price)";
            JobTask."Recognized Costs Amount" := JobTask."Usage (Total Cost)";
            OnCaclWIPOnAfterRecognizedAmounts(JobTask);
            exit;
        end;

        JobWIPMethod.Get(JobWIPTotal."WIP Method");
        CalcRecognizedCosts(JobTask, JobWIPTotal, JobWIPMethod);
        CalcRecognizedSales(JobTask, JobWIPTotal, JobWIPMethod);
        OnAfterCalcWIP(JobTask, JobWIPTotal, JobComplete, RecognizedAllocationPercentage, JobWIPTotalChanged);
    end;

    local procedure CalcRecognizedCosts(var JobTask: Record "Job Task"; JobWIPTotal: Record "Job WIP Total"; JobWIPMethod: Record "Job WIP Method")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcRecognizedCosts(JobTask, JobWIPTotal, JobWIPMethod, IsHandled);
        if IsHandled then
            exit;

        case JobWIPMethod."Recognized Costs" of
            JobWIPMethod."Recognized Costs"::"Cost of Sales":
                CalcCostOfSales(JobTask, JobWIPTotal);
            JobWIPMethod."Recognized Costs"::"Cost Value":
                CalcCostValue(JobTask, JobWIPTotal);
            JobWIPMethod."Recognized Costs"::"Contract (Invoiced Cost)":
                CalcContractInvoicedCost(JobTask);
            JobWIPMethod."Recognized Costs"::"Usage (Total Cost)":
                CalcUsageTotalCostCosts(JobTask);
        end;
    end;

    local procedure CalcRecognizedSales(var JobTask: Record "Job Task"; JobWIPTotal: Record "Job WIP Total"; JobWIPMethod: Record "Job WIP Method")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcRecognizedSales(JobTask, JobWIPTotal, JobWIPMethod, IsHandled);
        if IsHandled then
            exit;

        case JobWIPMethod."Recognized Sales" of
            JobWIPMethod."Recognized Sales"::"Contract (Invoiced Price)":
                CalcContractInvoicedPrice(JobTask);
            JobWIPMethod."Recognized Sales"::"Usage (Total Cost)":
                CalcUsageTotalCostSales(JobTask);
            JobWIPMethod."Recognized Sales"::"Usage (Total Price)":
                CalcUsageTotalPrice(JobTask);
            JobWIPMethod."Recognized Sales"::"Percentage of Completion":
                CalcPercentageofCompletion(JobTask, JobWIPTotal);
            JobWIPMethod."Recognized Sales"::"Sales Value":
                CalcSalesValue(JobTask, JobWIPTotal);
        end;
    end;

    local procedure CalcCostOfSales(var JobTask: Record "Job Task"; JobWIPTotal: Record "Job WIP Total")
    begin
        if JobWIPTotal."Contract (Total Price)" = 0 then
            exit;

        if JobWIPTotalChanged then begin
            WIPAmount := JobWIPTotal."Usage (Total Cost)" -
              ((JobWIPTotal."Contract (Invoiced Price)" / JobWIPTotal."Contract (Total Price)") *
               JobWIPTotal."Schedule (Total Cost)");
            if JobWIPTotal."Usage (Total Cost)" <> 0 then
                RecognizedAllocationPercentage := WIPAmount / JobWIPTotal."Usage (Total Cost)";
        end;

        if RecognizedAllocationPercentage <> 0 then
            WIPAmount := Round(JobTask."Usage (Total Cost)" * RecognizedAllocationPercentage);
        JobTask."Recognized Costs Amount" := JobTask."Usage (Total Cost)" - WIPAmount;
    end;

    local procedure CalcCostValue(var JobTask: Record "Job Task"; JobWIPTotal: Record "Job WIP Total")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcCostValue(JobTask, JobWIPTotal, WIPAmount, RecognizedAllocationPercentage, JobWIPTotalChanged, IsHandled);
        if IsHandled then
            exit;

        if JobWIPTotal."Schedule (Total Price)" = 0 then
            exit;

        if JobWIPTotalChanged then begin
            WIPAmount :=
              (JobWIPTotal."Usage (Total Cost)" *
               JobWIPTotal."Contract (Total Price)" /
               JobWIPTotal."Schedule (Total Price)") -
              JobWIPTotal."Schedule (Total Cost)" *
              JobWIPTotal."Contract (Invoiced Price)" /
              JobWIPTotal."Schedule (Total Price)";
            if JobWIPTotal."Usage (Total Cost)" <> 0 then
                RecognizedAllocationPercentage := WIPAmount / JobWIPTotal."Usage (Total Cost)";
        end;

        if RecognizedAllocationPercentage <> 0 then
            WIPAmount := Round(JobTask."Usage (Total Cost)" * RecognizedAllocationPercentage);
        JobTask."Recognized Costs Amount" := JobTask."Usage (Total Cost)" - WIPAmount;
    end;

    local procedure CalcContractInvoicedCost(var JobTask: Record "Job Task")
    begin
        JobTask."Recognized Costs Amount" := JobTask."Contract (Invoiced Cost)";
    end;

    local procedure CalcUsageTotalCostCosts(var JobTask: Record "Job Task")
    begin
        JobTask."Recognized Costs Amount" := JobTask."Usage (Total Cost)";
        OnAfterCalcUsageTotalCostCosts(JobTask);
    end;

    local procedure CalcContractInvoicedPrice(var JobTask: Record "Job Task")
    begin
        JobTask."Recognized Sales Amount" := JobTask."Contract (Invoiced Price)";
    end;

    local procedure CalcUsageTotalCostSales(var JobTask: Record "Job Task")
    begin
        JobTask."Recognized Sales Amount" := JobTask."Usage (Total Cost)";
    end;

    local procedure CalcUsageTotalPrice(var JobTask: Record "Job Task")
    begin
        JobTask."Recognized Sales Amount" := JobTask."Usage (Total Price)";
    end;

    local procedure CalcPercentageofCompletion(var JobTask: Record "Job Task"; JobWIPTotal: Record "Job WIP Total")
    var
        IsHandled: Boolean;
    begin
        OnBeforeCalcPercentageOfCompletion(
          JobTask, JobWIPTotal, JobWIPTotalChanged, WIPAmount, RecognizedAllocationPercentage, IsHandled);
        if IsHandled then
            exit;

        if JobWIPTotal."Schedule (Total Cost)" = 0 then
            exit;

        if JobWIPTotalChanged then begin
            if JobWIPTotal."Usage (Total Cost)" <= JobWIPTotal."Schedule (Total Cost)" then
                WIPAmount :=
                  (JobWIPTotal."Usage (Total Cost)" / JobWIPTotal."Schedule (Total Cost)") *
                  JobWIPTotal."Contract (Total Price)"
            else
                WIPAmount := JobWIPTotal."Contract (Total Price)";
            if JobWIPTotal."Contract (Total Price)" <> 0 then
                RecognizedAllocationPercentage := WIPAmount / JobWIPTotal."Contract (Total Price)";
        end;

        if RecognizedAllocationPercentage <> 0 then
            WIPAmount := Round(JobTask."Contract (Total Price)" * RecognizedAllocationPercentage);
        JobTask."Recognized Sales Amount" := WIPAmount;
    end;

    local procedure CalcSalesValue(var JobTask: Record "Job Task"; JobWIPTotal: Record "Job WIP Total")
    begin
        if JobWIPTotal."Schedule (Total Price)" = 0 then
            exit;

        if JobWIPTotalChanged then begin
            WIPAmount :=
              (JobWIPTotal."Usage (Total Price)" *
               JobWIPTotal."Contract (Total Price)" /
               JobWIPTotal."Schedule (Total Price)") -
              JobWIPTotal."Contract (Invoiced Price)";
            if JobWIPTotal."Usage (Total Price)" <> 0 then
                RecognizedAllocationPercentage := WIPAmount / JobWIPTotal."Usage (Total Price)";
        end;

        if RecognizedAllocationPercentage <> 0 then
            WIPAmount := Round(JobTask."Usage (Total Price)" * RecognizedAllocationPercentage);
        JobTask."Recognized Sales Amount" := (JobTask."Contract (Invoiced Price)" + WIPAmount);
    end;

    local procedure CalcCostInvoicePercentage(var JobWIPTotal: Record "Job WIP Total")
    begin
        if JobWIPTotal."Schedule (Total Cost)" <> 0 then
            JobWIPTotal."Cost Completion %" := Round(100 * JobWIPTotal."Usage (Total Cost)" / JobWIPTotal."Schedule (Total Cost)", 0.00001)
        else
            JobWIPTotal."Cost Completion %" := 0;
        if JobWIPTotal."Contract (Total Price)" <> 0 then
            JobWIPTotal."Invoiced %" := Round(100 * JobWIPTotal."Contract (Invoiced Price)" / JobWIPTotal."Contract (Total Price)", 0.00001)
        else
            JobWIPTotal."Invoiced %" := 0;
    end;

    local procedure CreateTempJobWIPBuffers(var JobTask: Record "Job Task"; var JobWIPTotal: Record "Job WIP Total")
    var
        Job: Record Job;
        JobWIPMethod: Record "Job WIP Method";
    begin
        Job.Get(JobTask."Job No.");
        JobWIPMethod.Get(JobWIPTotal."WIP Method");
        if not JobComplete then begin
            if JobTask."Recognized Costs Amount" <> 0 then begin
                CreateWIPBufferEntryFromTask(JobTask, JobWIPTotal, Enum::"Job WIP Buffer Type"::"Recognized Costs", false);
                if Job."WIP Posting Method" = Job."WIP Posting Method"::"Per Job" then
                    CreateWIPBufferEntryFromTask(JobTask, JobWIPTotal, Enum::"Job WIP Buffer Type"::"Applied Costs", false)
                else
                    FindJobLedgerEntriesByJobTask(JobTask, JobWIPTotal, Enum::"Job WIP Buffer Type"::"Applied Costs");
            end;
            if JobTask."Recognized Sales Amount" <> 0 then begin
                CreateWIPBufferEntryFromTask(JobTask, JobWIPTotal, Enum::"Job WIP Buffer Type"::"Recognized Sales", false);
                if (Job."WIP Posting Method" = Job."WIP Posting Method"::"Per Job") or
                    (JobWIPMethod."Recognized Sales" = JobWIPMethod."Recognized Sales"::"Percentage of Completion")
                then
                    CreateWIPBufferEntryFromTask(
                        JobTask, JobWIPTotal, Enum::"Job WIP Buffer Type"::"Applied Sales",
                        ((JobTask."Contract (Invoiced Price)" > JobTask."Recognized Sales Amount") and
                        (JobWIPMethod."Recognized Sales" = JobWIPMethod."Recognized Sales"::"Percentage of Completion")))
                else
                    FindJobLedgerEntriesByJobTask(JobTask, JobWIPTotal, Enum::"Job WIP Buffer Type"::"Applied Sales");
                if JobTask."Recognized Sales Amount" > JobTask."Contract (Invoiced Price)" then
                    CreateWIPBufferEntryFromTask(JobTask, JobWIPTotal, Enum::"Job WIP Buffer Type"::"Accrued Sales", false);
            end;
            if (JobTask."Recognized Costs Amount" = 0) and (JobTask."Usage (Total Cost)" <> 0) then
                if Job."WIP Posting Method" = Job."WIP Posting Method"::"Per Job" then
                    CreateWIPBufferEntryFromTask(JobTask, JobWIPTotal, Enum::"Job WIP Buffer Type"::"Applied Costs", false)
                else
                    FindJobLedgerEntriesByJobTask(JobTask, JobWIPTotal, Enum::"Job WIP Buffer Type"::"Applied Costs");
            if (JobTask."Recognized Sales Amount" = 0) and (JobTask."Contract (Invoiced Price)" <> 0) then
                if Job."WIP Posting Method" = Job."WIP Posting Method"::"Per Job" then
                    CreateWIPBufferEntryFromTask(JobTask, JobWIPTotal, Enum::"Job WIP Buffer Type"::"Applied Sales", false)
                else
                    FindJobLedgerEntriesByJobTask(JobTask, JobWIPTotal, Enum::"Job WIP Buffer Type"::"Applied Sales");
        end else begin
            if Job."WIP Posting Method" = Job."WIP Posting Method"::"Per Job Ledger Entry" then begin
                FindJobLedgerEntriesByJobTask(JobTask, JobWIPTotal, Enum::"Job WIP Buffer Type"::"Applied Costs");
                FindJobLedgerEntriesByJobTask(JobTask, JobWIPTotal, Enum::"Job WIP Buffer Type"::"Applied Sales");
            end;

            if JobTask."Recognized Costs Amount" <> 0 then
                CreateWIPBufferEntryFromTask(JobTask, JobWIPTotal, Enum::"Job WIP Buffer Type"::"Recognized Costs", false);
            if JobTask."Recognized Sales Amount" <> 0 then
                CreateWIPBufferEntryFromTask(JobTask, JobWIPTotal, Enum::"Job WIP Buffer Type"::"Recognized Sales", false);
        end;
    end;

    procedure CreateWIPBufferEntryFromTask(var JobTask: Record "Job Task"; var JobWIPTotal: Record "Job WIP Total"; JobWIPBufferType: Enum "Job WIP Buffer Type"; AppliedAccrued: Boolean)
    begin
        InitWIPBufferEntryFromTask(
          JobTask, JobWIPTotal, JobWIPBufferType, GetWIPEntryAmount(JobWIPBufferType, JobTask, JobWIPTotal."WIP Method", AppliedAccrued));
        UpdateWIPBufferEntryFromTask(JobTask, JobWIPTotal);
    end;

    local procedure InitWIPBufferEntryFromTask(var JobTask: Record "Job Task"; var JobWIPTotal: Record "Job WIP Total"; JobWIPBufferType: Enum "Job WIP Buffer Type"; WIPEntryAmount: Decimal)
    var
        JobTaskDimension: Record "Job Task Dimension";
        TempDimensionBuffer: Record "Dimension Buffer" temporary;
        Job: Record Job;
        JobPostingGroup: Record "Job Posting Group";
        JobWIPMethod: Record "Job WIP Method";
    begin
        Clear(TempJobWIPBuffer);
        TempDimensionBuffer.Reset();
        TempDimensionBuffer.DeleteAll();

        JobTaskDimension.SetRange("Job No.", JobTask."Job No.");
        JobTaskDimension.SetRange("Job Task No.", JobTask."Job Task No.");
        if JobTaskDimension.FindSet() then
            repeat
                TempDimensionBuffer."Dimension Code" := JobTaskDimension."Dimension Code";
                TempDimensionBuffer."Dimension Value Code" := JobTaskDimension."Dimension Value Code";
                TempDimensionBuffer.Insert();
            until JobTaskDimension.Next() = 0;
        if not DimMgt.CheckDimBuffer(TempDimensionBuffer) then
            Error(DimMgt.GetDimCombErr());
        OnInitWIPBufferEntryFromTaskOnBeforeSetDimCombinationID(TempDimensionBuffer, JobTask);
        TempJobWIPBuffer[1]."Dim Combination ID" := DimMgt.CreateDimSetIDFromDimBuf(TempDimensionBuffer);

        Job.Get(JobTask."Job No.");
        if JobTask."Job Posting Group" = '' then begin
            Job.TestField("Job Posting Group");
            JobTask."Job Posting Group" := Job."Job Posting Group";
        end;
        JobPostingGroup.Get(JobTask."Job Posting Group");
        JobWIPMethod.Get(JobWIPTotal."WIP Method");

        case JobWIPBufferType of
            Enum::"Job WIP Buffer Type"::"Applied Costs":
                begin
                    TempJobWIPBuffer[1].Type := TempJobWIPBuffer[1].Type::"Applied Costs";
                    TempJobWIPBuffer[1]."G/L Account No." := JobPostingGroup.GetJobCostsAppliedAccount();
                    TempJobWIPBuffer[1]."Bal. G/L Account No." := JobPostingGroup.GetWIPCostsAccount();
                end;
            Enum::"Job WIP Buffer Type"::"Applied Sales":
                begin
                    TempJobWIPBuffer[1].Type := TempJobWIPBuffer[1].Type::"Applied Sales";
                    TempJobWIPBuffer[1]."G/L Account No." := JobPostingGroup.GetJobSalesAppliedAccount();
                    TempJobWIPBuffer[1]."Bal. G/L Account No." := JobPostingGroup.GetWIPInvoicedSalesAccount();
                end;
            Enum::"Job WIP Buffer Type"::"Recognized Costs":
                begin
                    TempJobWIPBuffer[1].Type := TempJobWIPBuffer[1].Type::"Recognized Costs";
                    TempJobWIPBuffer[1]."G/L Account No." := JobPostingGroup.GetRecognizedCostsAccount();
                    TempJobWIPBuffer[1]."Bal. G/L Account No." := GetRecognizedCostsBalGLAccountNo(Job, JobPostingGroup);
                    TempJobWIPBuffer[1]."Job Complete" := JobComplete;
                end;
            Enum::"Job WIP Buffer Type"::"Recognized Sales":
                begin
                    TempJobWIPBuffer[1].Type := TempJobWIPBuffer[1].Type::"Recognized Sales";
                    TempJobWIPBuffer[1]."G/L Account No." := JobPostingGroup.GetRecognizedSalesAccount();
                    TempJobWIPBuffer[1]."Bal. G/L Account No." := GetRecognizedSalesBalGLAccountNo(Job, JobPostingGroup, JobWIPMethod);
                    TempJobWIPBuffer[1]."Job Complete" := JobComplete;
                end;
            Enum::"Job WIP Buffer Type"::"Accrued Costs":
                begin
                    TempJobWIPBuffer[1].Type := TempJobWIPBuffer[1].Type::"Accrued Costs";
                    TempJobWIPBuffer[1]."G/L Account No." := JobPostingGroup.GetJobCostsAdjustmentAccount();
                    TempJobWIPBuffer[1]."Bal. G/L Account No." := JobPostingGroup.GetWIPAccruedCostsAccount();
                end;
            Enum::"Job WIP Buffer Type"::"Accrued Sales":
                begin
                    TempJobWIPBuffer[1].Type := TempJobWIPBuffer[1].Type::"Accrued Sales";
                    TempJobWIPBuffer[1]."G/L Account No." := JobPostingGroup.GetJobSalesAdjustmentAccount();
                    TempJobWIPBuffer[1]."Bal. G/L Account No." := JobPostingGroup.GetWIPAccruedSalesAccount();
                end;
        end;
        TempJobWIPBuffer[1]."WIP Entry Amount" := WIPEntryAmount;
    end;

    local procedure UpdateWIPBufferEntryFromTask(var JobTask: Record "Job Task"; var JobWIPTotal: Record "Job WIP Total")
    begin
        if TempJobWIPBuffer[1]."WIP Entry Amount" <> 0 then begin
            TempJobWIPBuffer[1].Reverse := true;
            TransferJobTaskToTempJobWIPBuf(JobTask, JobWIPTotal);
            UpdateTempJobWIPBufferEntry();
        end;
    end;

    procedure FindJobLedgerEntriesByJobTask(var JobTask: Record "Job Task"; var JobWIPTotal: Record "Job WIP Total"; JobWIPBufferType: Enum "Job WIP Buffer Type")
    var
        JobLedgerEntry: Record "Job Ledger Entry";
        JobWIPMethod: Record "Job WIP Method";
    begin
        JobLedgerEntry.SetRange("Job No.", JobTask."Job No.");
        JobLedgerEntry.SetRange("Job Task No.", JobTask."Job Task No.");
        JobLedgerEntry.SetFilter("Posting Date", JobTask.GetFilter("Posting Date Filter"));
        if JobWIPBufferType = Enum::"Job WIP Buffer Type"::"Applied Costs" then
            JobLedgerEntry.SetRange("Entry Type", JobLedgerEntry."Entry Type"::Usage);
        if JobWIPBufferType = Enum::"Job WIP Buffer Type"::"Applied Sales" then begin
            JobLedgerEntry.SetRange("Entry Type", JobLedgerEntry."Entry Type"::Sale);
            if JobWIPMethod.Get(JobWIPTotal."WIP Method") then
                if JobWIPMethod."Recognized Sales" = JobWIPMethod."Recognized Sales"::"Usage (Total Price)" then
                    if JobTask."Contract (Invoiced Price)" < JobTask."Recognized Sales Amount" then
                        JobLedgerEntry.SetRange("Entry Type", JobLedgerEntry."Entry Type"::Usage);
        end;
        if JobLedgerEntry.FindSet() then
            repeat
                CreateWIPBufferEntryFromLedger(JobLedgerEntry, JobTask, JobWIPTotal, JobWIPBufferType)
            until JobLedgerEntry.Next() = 0;
    end;

    procedure CreateWIPBufferEntryFromLedger(var JobLedgerEntry: Record "Job Ledger Entry"; var JobTask: Record "Job Task"; var JobWIPTotal: Record "Job WIP Total"; JobWIPBufferType: Enum "Job WIP Buffer Type")
    var
        Job: Record Job;
        JobPostingGroup: Record "Job Posting Group";
    begin
        Clear(TempJobWIPBuffer);
        TempJobWIPBuffer[1]."Dim Combination ID" := JobLedgerEntry."Dimension Set ID";
        TempJobWIPBuffer[1]."Job Complete" := JobComplete;
        OnBeforeCreateWIPBufferEntryFromLedgerOnBeforeAssignPostingGroup(TempJobWIPBuffer[1], JobLedgerEntry, JobComplete);
        if JobTask."Job Posting Group" = '' then begin
            Job.Get(JobTask."Job No.");
            Job.TestField("Job Posting Group");
            JobTask."Job Posting Group" := Job."Job Posting Group";
        end;
        JobPostingGroup.Get(JobTask."Job Posting Group");

        case JobWIPBufferType of
            Enum::"Job WIP Buffer Type"::"Applied Costs":
                begin
                    TempJobWIPBuffer[1].Type := TempJobWIPBuffer[1].Type::"Applied Costs";
                    case JobLedgerEntry.Type of
                        JobLedgerEntry.Type::Item:
                            TempJobWIPBuffer[1]."G/L Account No." := JobPostingGroup.GetItemCostsAppliedAccount();
                        JobLedgerEntry.Type::Resource:
                            TempJobWIPBuffer[1]."G/L Account No." := JobPostingGroup.GetResourceCostsAppliedAccount();
                        JobLedgerEntry.Type::"G/L Account":
                            TempJobWIPBuffer[1]."G/L Account No." := JobPostingGroup.GetGLCostsAppliedAccount();
                    end;
                    TempJobWIPBuffer[1]."Bal. G/L Account No." := JobPostingGroup.GetWIPCostsAccount();
                    TempJobWIPBuffer[1]."WIP Entry Amount" := -JobLedgerEntry."Total Cost (LCY)";
                    JobLedgerEntry."Amt. to Post to G/L" := JobLedgerEntry."Total Cost (LCY)" - JobLedgerEntry."Amt. Posted to G/L";
                end;
            Enum::"Job WIP Buffer Type"::"Applied Sales":
                begin
                    TempJobWIPBuffer[1].Type := TempJobWIPBuffer[1].Type::"Applied Sales";
                    TempJobWIPBuffer[1]."G/L Account No." := JobPostingGroup.GetJobSalesAppliedAccount();
                    TempJobWIPBuffer[1]."Bal. G/L Account No." := JobPostingGroup.GetWIPInvoicedSalesAccount();
                    if JobLedgerEntry."Entry Type" = JobLedgerEntry."Entry Type"::Sale then
                        TempJobWIPBuffer[1]."WIP Entry Amount" := -JobLedgerEntry."Line Amount (LCY)"
                    else
                        TempJobWIPBuffer[1]."WIP Entry Amount" := JobLedgerEntry."Line Amount (LCY)";
                    JobLedgerEntry."Amt. to Post to G/L" := JobLedgerEntry."Line Amount (LCY)" - JobLedgerEntry."Amt. Posted to G/L";
                end;
        end;
        OnCreateWIPBufferEntryFromLedgerOnBeforeModifyJobLedgerEntry(JobLedgerEntry, TempJobWIPBuffer, JobWIPBufferType);
        JobLedgerEntry.Modify();

        if TempJobWIPBuffer[1]."WIP Entry Amount" <> 0 then begin
            TempJobWIPBuffer[1].Reverse := true;
            TransferJobTaskToTempJobWIPBuf(JobTask, JobWIPTotal);
            UpdateTempJobWIPBufferEntry();
        end;
    end;

    local procedure TransferJobTaskToTempJobWIPBuf(JobTask: Record "Job Task"; JobWIPTotal: Record "Job WIP Total")
    var
        Job: Record Job;
    begin
        Job.Get(JobTask."Job No.");
        TempJobWIPBuffer[1]."WIP Posting Method Used" := Job."WIP Posting Method";
        TempJobWIPBuffer[1]."Job No." := JobTask."Job No.";
        TempJobWIPBuffer[1]."Posting Group" := JobTask."Job Posting Group";
        TempJobWIPBuffer[1]."WIP Method" := JobWIPTotal."WIP Method";
        TempJobWIPBuffer[1]."Job WIP Total Entry No." := JobWIPTotal."Entry No.";
    end;

    local procedure UpdateTempJobWIPBufferEntry()
    begin
        TempJobWIPBuffer[2] := TempJobWIPBuffer[1];
        if TempJobWIPBuffer[2].Find() then begin
            TempJobWIPBuffer[2]."WIP Entry Amount" += TempJobWIPBuffer[1]."WIP Entry Amount";
            TempJobWIPBuffer[2].Modify();
        end else
            TempJobWIPBuffer[1].Insert();
    end;

    local procedure CreateWIPEntries(JobNo: Code[20])
    var
        JobWIPEntry: Record "Job WIP Entry";
        JobWIPMethod: Record "Job WIP Method";
        NextEntryNo: Integer;
        CreateEntry: Boolean;
    begin
        NextEntryNo := JobWIPEntry.GetLastEntryNo() + 1;

        GetGLSetup();
        if TempJobWIPBuffer[1].Find('-') then
            repeat
                CreateEntry := true;

                JobWIPMethod.Get(TempJobWIPBuffer[1]."WIP Method");
                if not JobWIPMethod."WIP Cost" and
                   ((TempJobWIPBuffer[1].Type = TempJobWIPBuffer[1].Type::"Recognized Costs") or
                    (TempJobWIPBuffer[1].Type = TempJobWIPBuffer[1].Type::"Applied Costs"))
                then
                    CreateEntry := false;

                if not JobWIPMethod."WIP Sales" and
                   ((TempJobWIPBuffer[1].Type = TempJobWIPBuffer[1].Type::"Recognized Sales") or
                    (TempJobWIPBuffer[1].Type = TempJobWIPBuffer[1].Type::"Applied Sales"))
                then
                    CreateEntry := false;

                if TempJobWIPBuffer[1]."WIP Entry Amount" = 0 then
                    CreateEntry := false;

                if CreateEntry then begin
                    Clear(JobWIPEntry);
                    JobWIPEntry."Job No." := JobNo;
                    JobWIPEntry."WIP Posting Date" := WIPPostingDate;
                    JobWIPEntry."Document No." := DocNo;
                    JobWIPEntry.Type := TempJobWIPBuffer[1].Type;
                    JobWIPEntry."Job Posting Group" := TempJobWIPBuffer[1]."Posting Group";
                    JobWIPEntry."G/L Account No." := TempJobWIPBuffer[1]."G/L Account No.";
                    JobWIPEntry."G/L Bal. Account No." := TempJobWIPBuffer[1]."Bal. G/L Account No.";
                    JobWIPEntry."WIP Method Used" := TempJobWIPBuffer[1]."WIP Method";
                    JobWIPEntry."Job Complete" := TempJobWIPBuffer[1]."Job Complete";
                    JobWIPEntry."Job WIP Total Entry No." := TempJobWIPBuffer[1]."Job WIP Total Entry No.";
                    JobWIPEntry."WIP Entry Amount" := Round(TempJobWIPBuffer[1]."WIP Entry Amount");
                    JobWIPEntry.Reverse := TempJobWIPBuffer[1].Reverse;
                    JobWIPEntry."WIP Posting Method Used" := TempJobWIPBuffer[1]."WIP Posting Method Used";
                    JobWIPEntry."Entry No." := NextEntryNo;
                    JobWIPEntry."Dimension Set ID" := TempJobWIPBuffer[1]."Dim Combination ID";
                    DimMgt.UpdateGlobalDimFromDimSetID(JobWIPEntry."Dimension Set ID", JobWIPEntry."Global Dimension 1 Code",
                      JobWIPEntry."Global Dimension 2 Code");
                    OnCreateWIPEntriesOnBeforeJobWIPEntryInsert(JobWIPEntry);
                    JobWIPEntry.Insert(true);
                    NextEntryNo := NextEntryNo + 1;
                end;
            until TempJobWIPBuffer[1].Next() = 0;
    end;

    procedure CalcGLWIP(JobNo: Code[20]; JustReverse: Boolean; DocNo: Code[20]; PostingDate: Date; NewPostDate: Boolean)
    var
        SourceCodeSetup: Record "Source Code Setup";
        GLEntry: Record "G/L Entry";
        Job: Record Job;
        JobWIPEntry: Record "Job WIP Entry";
        JobWIPGLEntry: Record "Job WIP G/L Entry";
        JobWIPTotal: Record "Job WIP Total";
        JobLedgerEntry: Record "Job Ledger Entry";
        JobTask: Record "Job Task";
        NextEntryNo: Integer;
        NextTransactionNo: Integer;
    begin
        JobWIPGLEntry.LockTable();
        JobWIPEntry.LockTable();
        Job.LockTable();

        JobWIPGLEntry.SetCurrentKey("Job No.", Reversed, "Job Complete");
        JobWIPGLEntry.SetRange("Job No.", JobNo);
        JobWIPGLEntry.SetRange("Job Complete", true);
        if not JobWIPGLEntry.IsEmpty() then
            exit;
        JobWIPGLEntry.Reset();

        Job.Get(JobNo);
        Job.TestBlocked();
        if NewPostDate then
            Job."WIP G/L Posting Date" := PostingDate;
        if JustReverse then
            Job."WIP G/L Posting Date" := 0D;
        Job.Modify();

        NextEntryNo := JobWIPGLEntry.GetLastEntryNo() + 1;

        JobWIPGLEntry.SetCurrentKey("WIP Transaction No.");
        if JobWIPGLEntry.FindLast() then
            NextTransactionNo := JobWIPGLEntry."WIP Transaction No." + 1
        else
            NextTransactionNo := 1;

        SourceCodeSetup.Get();

        // Reverse Entries
        JobWIPGLEntry.SetCurrentKey("Job No.", Reversed);
        JobWIPGLEntry.SetRange("Job No.", JobNo);
        JobWIPGLEntry.SetRange(Reverse, true);
        JobWIPGLEntry.SetRange(Reversed, false);
        if JobWIPGLEntry.Find('-') then
            repeat
                if JobWIPGLEntry."Posting Date" > PostingDate then
                    Error(Text004, JobWIPGLEntry."Job No.", JobWIPGLEntry."Posting Date");
            until JobWIPGLEntry.Next() = 0;
        if JobWIPGLEntry.Find('-') then
            repeat
                PostWIPGL(JobWIPGLEntry, true, DocNo, SourceCodeSetup."Job G/L WIP", PostingDate);
            until JobWIPGLEntry.Next() = 0;
        JobWIPGLEntry.ModifyAll("Reverse Date", PostingDate);
        JobWIPGLEntry.ModifyAll(Reversed, true);

        JobTask.SetRange("Job No.", Job."No.");
        if JobTask.FindSet() then
            repeat
                JobTask."Recognized Sales G/L Amount" := JobTask."Recognized Sales Amount";
                JobTask."Recognized Costs G/L Amount" := JobTask."Recognized Costs Amount";
                JobTask.Modify();
            until JobTask.Next() = 0;

        if JustReverse then
            exit;

        JobWIPEntry.SetRange("Job No.", JobNo);
        if JobWIPEntry.Find('-') then
            repeat
                Clear(JobWIPGLEntry);
                JobWIPGLEntry."Job No." := JobWIPEntry."Job No.";
                JobWIPGLEntry."Document No." := JobWIPEntry."Document No.";
                JobWIPGLEntry."G/L Account No." := JobWIPEntry."G/L Account No.";
                JobWIPGLEntry."G/L Bal. Account No." := JobWIPEntry."G/L Bal. Account No.";
                JobWIPGLEntry.Type := JobWIPEntry.Type;
                JobWIPGLEntry."WIP Posting Date" := JobWIPEntry."WIP Posting Date";
                if NewPostDate then
                    JobWIPGLEntry."Posting Date" := PostingDate
                else
                    JobWIPGLEntry."Posting Date" := JobWIPEntry."WIP Posting Date";
                JobWIPGLEntry."Job Posting Group" := JobWIPEntry."Job Posting Group";
                JobWIPGLEntry."WIP Method Used" := JobWIPEntry."WIP Method Used";
                if not NewPostDate then begin
                    Job."WIP G/L Posting Date" := JobWIPEntry."WIP Posting Date";
                    Job.Modify();
                end;
                JobWIPGLEntry.Reversed := false;
                JobWIPGLEntry."Job Complete" := JobWIPEntry."Job Complete";
                JobWIPGLEntry."WIP Transaction No." := NextTransactionNo;
                if JobWIPGLEntry.Type in [JobWIPGLEntry.Type::"Recognized Costs", JobWIPGLEntry.Type::"Recognized Sales"] then begin
                    if JobWIPGLEntry."Job Complete" then
                        JobWIPGLEntry.Description := StrSubstNo(Text003, JobNo)
                    else
                        JobWIPGLEntry.Description := StrSubstNo(Text002, JobNo);
                end else
                    JobWIPGLEntry.Description := StrSubstNo(Text001, JobNo);
                JobWIPGLEntry."WIP Entry Amount" := JobWIPEntry."WIP Entry Amount";
                JobWIPGLEntry.Reverse := JobWIPEntry.Reverse;
                JobWIPGLEntry."WIP Posting Method Used" := JobWIPEntry."WIP Posting Method Used";
                JobWIPGLEntry."Job WIP Total Entry No." := JobWIPEntry."Job WIP Total Entry No.";
                JobWIPGLEntry."Global Dimension 1 Code" := JobWIPEntry."Global Dimension 1 Code";
                JobWIPGLEntry."Global Dimension 2 Code" := JobWIPEntry."Global Dimension 2 Code";
                JobWIPGLEntry."Dimension Set ID" := JobWIPEntry."Dimension Set ID";
                JobWIPGLEntry."Entry No." := NextEntryNo;
                NextEntryNo := NextEntryNo + 1;
                PostWIPGL(JobWIPGLEntry,
                  false,
                  JobWIPGLEntry."Document No.",
                  SourceCodeSetup."Job G/L WIP",
                  JobWIPGLEntry."Posting Date");
                JobWIPGLEntry."G/L Entry No." := GLEntry.GetLastEntryNo();
                JobWIPGLEntry.Insert();
                JobWIPTotal.Get(JobWIPGLEntry."Job WIP Total Entry No.");
                JobWIPTotal."Posted to G/L" := true;
                JobWIPTotal.Modify();
            until JobWIPEntry.Next() = 0;

        JobLedgerEntry.SetRange("Job No.", Job."No.");
        JobLedgerEntry.SetFilter("Amt. to Post to G/L", '<>%1', 0);
        if JobLedgerEntry.FindSet() then
            repeat
                JobLedgerEntry."Amt. Posted to G/L" += JobLedgerEntry."Amt. to Post to G/L";
                JobLedgerEntry.Modify();
            until JobLedgerEntry.Next() = 0;

        DeleteWIP(Job);
    end;

    local procedure PostWIPGL(JobWIPGLEntry: Record "Job WIP G/L Entry"; Reversed: Boolean; JnlDocNo: Code[20]; SourceCode: Code[10]; JnlPostingDate: Date)
    var
        GLAmount: Decimal;
    begin
        CheckJobGLAcc(JobWIPGLEntry."G/L Account No.");
        CheckJobGLAcc(JobWIPGLEntry."G/L Bal. Account No.");
        GLAmount := JobWIPGLEntry."WIP Entry Amount";
        if Reversed then
            GLAmount := -GLAmount;

        InsertWIPGL(JobWIPGLEntry."G/L Account No.", JobWIPGLEntry."G/L Bal. Account No.", JnlPostingDate, JnlDocNo, SourceCode,
          GLAmount, JobWIPGLEntry.Description, JobWIPGLEntry."Job No.", JobWIPGLEntry."Dimension Set ID", Reversed, JobWIPGLEntry);
    end;

    local procedure InsertWIPGL(AccNo: Code[20]; BalAccNo: Code[20]; JnlPostingDate: Date; JnlDocNo: Code[20]; SourceCode: Code[10]; GLAmount: Decimal; JnlDescription: Text[100]; JobNo: Code[20]; JobWIPGLEntryDimSetID: Integer; Reversed: Boolean; JobWIPGLEntry: Record "Job WIP G/L Entry")
    var
        GenJnlLine: Record "Gen. Journal Line";
        GLAcc: Record "G/L Account";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertWIPGL(JnlPostingDate, JnlDocNo, SourceCode, GLAmount, JobWIPGLEntry, Reversed, IsHandled);
        if not IsHandled then begin
            GLAcc.Get(AccNo);
            GenJnlLine.Init();
            GenJnlLine."Posting Date" := JnlPostingDate;
            GenJnlLine."Account No." := AccNo;
            GenJnlLine."Bal. Account No." := BalAccNo;
            GenJnlLine."Tax Area Code" := GLAcc."Tax Area Code";
            GenJnlLine."Tax Liable" := GLAcc."Tax Liable";
            GenJnlLine."Tax Group Code" := GLAcc."Tax Group Code";
            GenJnlLine.Amount := GLAmount;
            GenJnlLine."Document No." := JnlDocNo;
            GenJnlLine."Source Code" := SourceCode;
            GenJnlLine.Description := JnlDescription;
            GenJnlLine."Job No." := JobNo;
            GenJnlLine."System-Created Entry" := true;
            GenJnlLine."Dimension Set ID" := JobWIPGLEntryDimSetID;
            GetGLSetup();
            if GLSetup."Journal Templ. Name Mandatory" then begin
                GenJnlLine."Journal Template Name" := GenJnlBatch."Journal Template Name";
                GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
            end;
            Clear(DimMgt);
            DimMgt.UpdateGlobalDimFromDimSetID(GenJnlLine."Dimension Set ID", GenJnlLine."Shortcut Dimension 1 Code",
              GenJnlLine."Shortcut Dimension 2 Code");

            OnInsertWIPGLOnBeforeGenJnPostLine(GenJnlLine, Reversed);
            GenJnPostLine.RunWithCheck(GenJnlLine);
        end;
    end;

    local procedure CheckJobGLAcc(AccNo: Code[20])
    var
        GLAcc: Record "G/L Account";
        IsHandled: Boolean;
    begin
        OnBeforeCheckJobGLAcc(AccNo, IsHandled);
        if IsHandled then
            exit;

        GLAcc.Get(AccNo);
        GLAcc.CheckGLAcc();
        GLAcc.TestField("Gen. Posting Type", GLAcc."Gen. Posting Type"::" ");
        GLAcc.TestField("Gen. Bus. Posting Group", '');
        GLAcc.TestField("Gen. Prod. Posting Group", '');
        GLAcc.TestField("VAT Bus. Posting Group", '');
        GLAcc.TestField("VAT Prod. Posting Group", '');
    end;

    local procedure GetGLSetup()
    begin
        if not HasGotGLSetup then begin
            GLSetup.Get();
            HasGotGLSetup := true;
        end;
    end;

    procedure ReOpenJob(JobNo: Code[20])
    var
        Job: Record Job;
        JobWIPGLEntry: Record "Job WIP G/L Entry";
    begin
        Job.Get(JobNo);
        DeleteWIP(Job);
        JobWIPGLEntry.SetCurrentKey("Job No.", Reversed, "Job Complete");
        JobWIPGLEntry.SetRange("Job No.", JobNo);
        JobWIPGLEntry.ModifyAll("Job Complete", false);
    end;

    local procedure GetRecognizedCostsBalGLAccountNo(Job: Record Job; JobPostingGroup: Record "Job Posting Group"): Code[20]
    begin
        if not JobComplete or (Job."WIP Posting Method" = Job."WIP Posting Method"::"Per Job Ledger Entry") then
            exit(JobPostingGroup.GetWIPCostsAccount());

        exit(JobPostingGroup.GetJobCostsAppliedAccount());
    end;

    local procedure GetRecognizedSalesBalGLAccountNo(Job: Record Job; JobPostingGroup: Record "Job Posting Group"; JobWIPMethod: Record "Job WIP Method"): Code[20]
    begin
        case true of
            not JobComplete and
          (JobWIPMethod."Recognized Sales" = JobWIPMethod."Recognized Sales"::"Percentage of Completion"):
                exit(JobPostingGroup.GetWIPAccruedSalesAccount());
            not JobComplete or (Job."WIP Posting Method" = Job."WIP Posting Method"::"Per Job Ledger Entry"):
                exit(JobPostingGroup.GetWIPInvoicedSalesAccount());
            else
                exit(JobPostingGroup.GetJobSalesAppliedAccount());
        end;
    end;

    local procedure GetAppliedCostsWIPEntryAmount(JobTask: Record "Job Task"; JobWIPMethod: Record "Job WIP Method"; AppliedAccrued: Boolean): Decimal
    var
        IsHandled: Boolean;
        Result: Decimal;
    begin
        IsHandled := false;
        Result := 0;
        OnBeforeGetAppliedCostsWIPEntryAmount(JobTask, JobWIPMethod, AppliedAccrued, Result, IsHandled);
        if IsHandled then
            exit(Result);

        exit(GetAppliedCostsAmount(JobTask."Recognized Costs Amount", JobTask."Usage (Total Cost)", JobWIPMethod, AppliedAccrued));
    end;

    local procedure GetAppliedCostsAmount(RecognizedCostsAmount: Decimal; UsageTotalCost: Decimal; JobWIPMethod: Record "Job WIP Method"; AppliedAccrued: Boolean) AppliedCostsWIPEntryAmount: Decimal
    begin
        if AppliedAccrued then
            exit(UsageTotalCost - RecognizedCostsAmount);

        if IsAccruedCostsWIPMethod(JobWIPMethod) and (RecognizedCostsAmount <> 0) then begin
            AppliedCostsWIPEntryAmount := GetMAX(Abs(RecognizedCostsAmount), Abs(UsageTotalCost));
            if RecognizedCostsAmount > 0 then
                AppliedCostsWIPEntryAmount := -AppliedCostsWIPEntryAmount;
            exit(AppliedCostsWIPEntryAmount);
        end;

        exit(-UsageTotalCost);
    end;

    local procedure GetAppliedSalesWIPEntryAmount(JobTask: Record "Job Task"; JobWIPMethod: Record "Job WIP Method"; AppliedAccrued: Boolean) SalesAmount: Decimal
    begin
        if AppliedAccrued then begin
            SalesAmount := JobTask."Recognized Sales Amount" - JobTask."Contract (Invoiced Price)";
            if SalesAmount < 0 then
                exit(JobTask."Contract (Invoiced Price)");
            exit(SalesAmount);
        end;

        if IsAccruedSalesWIPMethod(JobWIPMethod) then
            exit(GetMAX(JobTask."Recognized Sales Amount", JobTask."Contract (Invoiced Price)"));

        exit(JobTask."Contract (Invoiced Price)");
    end;

    local procedure GetAccruedCostsAmount(JobWIPMethod: Record "Job WIP Method"; RecognizedCostsAmount: Decimal; UsageTotalCost: Decimal): Decimal
    begin
        if IsAccruedCostsWIPMethod(JobWIPMethod) then
            exit(RecognizedCostsAmount - UsageTotalCost);
        exit(0);
    end;

    local procedure GetAccruedSalesWIPEntryAmount(JobTask: Record "Job Task"; JobWIPMethod: Record "Job WIP Method"): Decimal
    begin
        if IsAccruedSalesWIPMethod(JobWIPMethod) then
            exit(-JobTask."Recognized Sales Amount" + JobTask."Contract (Invoiced Price)");
        exit(0);
    end;

    local procedure GetMAX(Value1: Decimal; Value2: Decimal): Decimal
    begin
        if Value1 > Value2 then
            exit(Value1);
        exit(Value2);
    end;

    local procedure GetWIPEntryAmount(JobWIPBufferType: Enum "Job WIP Buffer Type"; JobTask: Record "Job Task"; WIPMethodCode: Code[20]; AppliedAccrued: Boolean): Decimal
    var
        JobWIPMethod: Record "Job WIP Method";
        IsHandled: Boolean;
        Result: Decimal;
    begin
        JobWIPMethod.Get(WIPMethodCode);
        IsHandled := false;
        Result := 0;
        OnBeforeGetWIPEntryAmount(JobWIPBufferType, JobTask, JobWIPMethod, AppliedAccrued, Result, IsHandled);
        if IsHandled then
            exit(Result);
        case JobWIPBufferType of
            Enum::"Job WIP Buffer Type"::"Applied Costs":
                exit(GetAppliedCostsWIPEntryAmount(JobTask, JobWIPMethod, AppliedAccrued));
            Enum::"Job WIP Buffer Type"::"Applied Sales":
                exit(GetAppliedSalesWIPEntryAmount(JobTask, JobWIPMethod, AppliedAccrued));
            Enum::"Job WIP Buffer Type"::"Recognized Costs":
                exit(JobTask."Recognized Costs Amount");
            Enum::"Job WIP Buffer Type"::"Recognized Sales":
                exit(-JobTask."Recognized Sales Amount");
            Enum::"Job WIP Buffer Type"::"Accrued Sales":
                exit(GetAccruedSalesWIPEntryAmount(JobTask, JobWIPMethod));
        end;
    end;

    local procedure AssignWIPTotalAndMethodToRemainingJobTask(var JobTask: Record "Job Task"; Job: Record Job)
    var
        RemainingJobTask: Record "Job Task";
    begin
        RemainingJobTask.Copy(JobTask);
        RemainingJobTask.SetFilter("Job Task No.", '>%1', JobTask."Job Task No.");
        AssignWIPTotalAndMethodToJobTask(RemainingJobTask, Job);
    end;

    local procedure AssignWIPTotalAndMethodToJobTask(var JobTask: Record "Job Task"; Job: Record Job)
    begin
        JobTask.SetRange("Job No.", Job."No.");
        JobTask.SetRange("WIP-Total", JobTask."WIP-Total"::Total);
        if not JobTask.FindFirst() then begin
            JobTask.SetFilter("WIP-Total", '<> %1', JobTask."WIP-Total"::Excluded);
            if JobTask.FindLast() then begin
                JobTask.Validate("WIP-Total", JobTask."WIP-Total"::Total);
                JobTask.Modify();
            end;
        end;

        JobTask.SetRange("WIP-Total", JobTask."WIP-Total"::Total);
        JobTask.SetRange("WIP Method", '');
        if JobTask.FindFirst() then
            JobTask.ModifyAll("WIP Method", Job."WIP Method");

        JobTask.SetRange("WIP-Total");
        JobTask.SetRange("WIP Method");
    end;

    local procedure IsAccruedCostsWIPMethod(JobWIPMethod: Record "Job WIP Method"): Boolean
    begin
        exit(
          JobWIPMethod."Recognized Costs" in
          [JobWIPMethod."Recognized Costs"::"Cost Value",
           JobWIPMethod."Recognized Costs"::"Cost of Sales",
           JobWIPMethod."Recognized Costs"::"Contract (Invoiced Cost)"]);
    end;

    local procedure IsAccruedSalesWIPMethod(JobWIPMethod: Record "Job WIP Method"): Boolean
    begin
        exit(
          JobWIPMethod."Recognized Sales" in
          [JobWIPMethod."Recognized Sales"::"Sales Value",
           JobWIPMethod."Recognized Sales"::"Usage (Total Price)"]);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Task", 'OnBeforeModifyEvent', '', false, false)]
    procedure VerifyJobWIPEntryOnBeforeModify(var Rec: Record "Job Task"; var xRec: Record "Job Task"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;

        if not RunTrigger then
            exit;

        if JobTaskWIPRelatedFieldsAreModified(Rec) then
            VerifyJobWIPEntryIsEmpty(Rec."Job No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Task", 'OnBeforeRenameEvent', '', false, false)]
    procedure VerifyJobWIPEntryOnBeforeRename(var Rec: Record "Job Task"; var xRec: Record "Job Task"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;

        if not RunTrigger then
            exit;

        VerifyJobWIPEntryIsEmpty(Rec."Job No.");
    end;

    local procedure JobTaskWIPRelatedFieldsAreModified(JobTask: Record "Job Task") Result: Boolean
    var
        OldJobTask: Record "Job Task";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeJobTaskWIPRelatedFieldsAreModified(JobTask, Result, IsHandled);
        if IsHandled then
            exit(Result);

        OldJobTask.Get(JobTask."Job No.", JobTask."Job Task No.");
        exit(
          (OldJobTask."Job Task Type" <> JobTask."Job Task Type") or
          (OldJobTask."WIP-Total" <> JobTask."WIP-Total") or
          (OldJobTask."Job Posting Group" <> JobTask."Job Posting Group") or
          (OldJobTask."WIP Method" <> JobTask."WIP Method") or
          (OldJobTask.Totaling <> JobTask.Totaling));
    end;

    local procedure VerifyJobWIPEntryIsEmpty(JobNo: Code[20])
    var
        JobWIPEntry: Record "Job WIP Entry";
        JobTask: Record "Job Task";
    begin
        OnBeforeVerifyJobWIPEntryIsEmpty(JobWIPEntry);
        JobWIPEntry.SetRange("Job No.", JobNo);
        if not JobWIPEntry.IsEmpty() then
            Error(CannotModifyAssociatedEntriesErr, JobTask.TableCaption());
    end;

    procedure SetGenJnlBatch(NewGenJnlBatch: Record "Gen. Journal Batch")
    begin
        GenJnlBatch := NewGenJnlBatch;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcUsageTotalCostCosts(var JobTask: Record "Job Task")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcWIP(var JobTask: Record "Job Task"; JobWIPTotal: Record "Job WIP Total"; JobComplete: Boolean; var RecognizedAllocationPercentage: Decimal; var JobWIPTotalChanged: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeActivateErrorMessageHandling(var Job: Record Job; var ErrorMessageMgt: Codeunit "Error Message Management"; var ErrorMessageHandler: Codeunit "Error Message Handler"; var ErrorContextElement: Codeunit "Error Context Element"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcPercentageOfCompletion(var JobTask: Record "Job Task"; JobWIPTotal: Record "Job WIP Total"; var JobWIPTotalChanged: Boolean; var WIPAmount: Decimal; var RecognizedAllocationPercentage: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcRecognizedCosts(var JobTask: Record "Job Task"; var JobWIPTotal: Record "Job WIP Total"; var JobWIPMethod: Record "Job WIP Method"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcRecognizedSales(var JobTask: Record "Job Task"; var JobWIPTotal: Record "Job WIP Total"; var JobWIPMethod: Record "Job WIP Method"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcCostValue(var JobTask: Record "Job Task"; JobWIPTotal: Record "Job WIP Total"; var WIPAmount: Decimal; var RecognizedAllocationPercentage: Decimal; var JobWIPTotalChanged: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeJobTaskWIPRelatedFieldsAreModified(JobTask: Record "Job Task"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyJobWIPEntryIsEmpty(var JobWIPEntry: Record "Job WIP Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWIPEntriesOnBeforeJobWIPEntryInsert(var JobWIPEntry: Record "Job WIP Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateJobWIPTotalOnAfterUpdateJobWIPTotal(var JobTask: Record "Job Task"; var JobWIPTotal: Record "Job WIP Total")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateJobWIPTotal(var JobTask: Record "Job Task")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitWIPBufferEntryFromTaskOnBeforeSetDimCombinationID(var TempDimensionBuffer: Record "Dimension Buffer" temporary; JobTask: Record "Job Task")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertWIPGLOnBeforeGenJnPostLine(var GenJournalLine: Record "Gen. Journal Line"; Reversed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnJobTaskCalcWIPOnAfterJobWIPTotalModify(var Job: Record Job; var JobWIPTotal: Record "Job WIP Total")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnJobCalcWIPOnBeforeJobModify(var Job: Record Job; var JobComplete: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnJobTaskCalcWIPOnBeforeJobWIPTotalModify(var Job: Record Job; var JobWIPTotal: Record "Job WIP Total")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterJobTaskCalcWIP(var Job: Record Job; FromJobTask: Code[20]; ToJobTask: Code[20]; var JobWIPTotal: Record "Job WIP Total")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcWIP(var JobTask: Record "Job Task"; JobWIPTotal: Record "Job WIP Total"; JobComplete: Boolean; var RecognizedAllocationPercentage: Decimal; var JobWIPTotalChanged: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnJobTaskCalcWIPOnBeforeCreateTempJobWIPBuffer(var JobTask: Record "Job Task"; var JobWIPTotal: Record "Job WIP Total"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnJobTaskCalcWIPOnBeforeCalcWIP(var JobTask: Record "Job Task")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCaclWIPOnAfterRecognizedAmounts(var JobTask: Record "Job Task")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWIPBufferEntryFromLedgerOnBeforeModifyJobLedgerEntry(var JobLedgerEntry: Record "Job Ledger Entry"; var TempJobWIPBuffer: array[2] of Record "Job WIP Buffer" temporary; JobWIPBufferType: Enum "Job WIP Buffer Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetAppliedCostsWIPEntryAmount(JobTask: Record "Job Task"; JobWIPMethod: Record "Job WIP Method"; AppliedAccrued: Boolean; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWIPBufferEntryFromLedgerOnBeforeAssignPostingGroup(var TempJobWIPBuffer: Record "Job WIP Buffer"; var JobLedgerEntry: Record "Job Ledger Entry"; JobComplete: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertWIPGL(JnlPostingDate: Date; JnlDocNo: Code[20]; SourceCode: Code[10]; GLAmount: Decimal; JobWIPGLEntry: Record "Job WIP G/L Entry"; Reversed: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnJobTaskCalcWIPOnBeforeSumJobTaskCosts(var JobTask: Record "Job Task"; var RecognizedCostAmount: Decimal; var UsageTotalCost: Decimal; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateJobWIPTotalOnBeforeLoopJobTask(var JobTask: Record "Job Task"; var JobWIPTotal: Record "Job WIP Total"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetWIPEntryAmount(JobWIPBufferType: Enum "Job WIP Buffer Type"; JobTask: Record "Job Task"; JobWIPMethod: Record "Job WIP Method"; AppliedAccrued: Boolean; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckJobGLAcc(AccNo: Code[20]; var IsHandled: Boolean)
    begin
    end;
}

