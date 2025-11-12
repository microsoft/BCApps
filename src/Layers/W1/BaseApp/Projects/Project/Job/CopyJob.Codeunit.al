// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Job;

using Microsoft.Finance.Currency;
using Microsoft.Finance.Dimension;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;

codeunit 1006 "Copy Job"
{

    trigger OnRun()
    begin
    end;

    var
        CopyPrices: Boolean;
        CopyQuantity: Boolean;
        CopyDimensions: Boolean;
        JobPlanningLineSource: Option "Job Planning Lines","Job Ledger Entries";
        JobPlanningLineType: Option " ",Budget,Billable;
        JobLedgerEntryType: Option " ",Usage,Sale;
        JobTaskRangeFrom: Code[20];
        JobTaskRangeTo: Code[20];
        JobTaskDateRangeFrom: Date;
        JobTaskDateRangeTo: Date;

    procedure CopyJob(
        SourceJob: Record Job;
        TargetJobNo: Code[20];
        TargetJobDescription: Text[100];
        TargetJobSellToCustomer: Code[20];
        TargetJobBillToCustomer: Code[20]
    )
    var
        TargetJob: Record Job;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyJob(SourceJob, TargetJobNo, TargetJobDescription, TargetJobSellToCustomer, TargetJobBillToCustomer, CopyDimensions, CopyPrices, IsHandled);
        if IsHandled then
            exit;

        TargetJob.SetHideValidationDialog(true);
        TargetJob."No." := TargetJobNo;
        TargetJob.TransferFields(SourceJob, false);
        OnCopyJobOnBeforeTargetJobInsert(TargetJob, SourceJob);
        TargetJob.Insert(true);
        if TargetJobDescription <> '' then
            TargetJob.Validate(Description, TargetJobDescription);
        if TargetJobSellToCustomer <> '' then
            TargetJob.Validate("Sell-to Customer No.", TargetJobSellToCustomer);
        if TargetJobBillToCustomer <> '' then
            TargetJob.Validate("Bill-to Customer No.", TargetJobBillToCustomer);
        TargetJob.Validate(Status, TargetJob.Status::Planning);
        if CopyDimensions then
            CopyJobDimensions(SourceJob, TargetJob);
        CopyJobTasks(SourceJob, TargetJob);

        if CopyPrices then
            OnBeforeCopyJobPrices(SourceJob, TargetJob);

        OnAfterCopyJob(TargetJob, SourceJob);
        TargetJob.Modify();
    end;

    procedure CopyJobTasks(SourceJob: Record Job; TargetJob: Record Job)
    var
        SourceJobTask: Record "Job Task";
        TargetJobTask: Record "Job Task";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyJobTasks(SourceJob, TargetJob, IsHandled, CopyDimensions, CopyQuantity, CopyPrices, JobTaskRangeFrom, JobTaskRangeTo, JobPlanningLineSource, JobLedgerEntryType);
        if IsHandled then
            exit;

        SourceJobTask.SetRange("Job No.", SourceJob."No.");
        case true of
            (JobTaskRangeFrom <> '') and (JobTaskRangeTo <> ''):
                SourceJobTask.SetRange("Job Task No.", JobTaskRangeFrom, JobTaskRangeTo);
            (JobTaskRangeFrom <> '') and (JobTaskRangeTo = ''):
                SourceJobTask.SetFilter("Job Task No.", '%1..', JobTaskRangeFrom);
            (JobTaskRangeFrom = '') and (JobTaskRangeTo <> ''):
                SourceJobTask.SetFilter("Job Task No.", '..%1', JobTaskRangeTo);
        end;
        OnCopyJobTasksOnAfterSourceJobTaskSetFilters(SourceJobTask, SourceJob);

        if SourceJobTask.FindSet() then
            repeat
                TargetJobTask.Init();
                TargetJobTask.Validate("Job No.", TargetJob."No.");
                TargetJobTask.Validate("Job Task No.", SourceJobTask."Job Task No.");
                TargetJobTask.TransferFields(SourceJobTask, false);
                if SourceJob."Task Billing Method" = SourceJob."Task Billing Method"::"Multiple customers" then begin
                    TargetJobTask.SetHideValidationDialog(true);
                    TargetJobTask.Validate("Sell-to Customer No.", '');
                end;
                if TargetJobTask."WIP Method" <> '' then begin
                    TargetJobTask.Validate("WIP-Total", TargetJobTask."WIP-Total"::Total);
                    TargetJobTask.Validate("WIP Method", TargetJob."WIP Method");
                end;
                TargetJobTask.Validate("Recognized Sales Amount", 0);
                TargetJobTask.Validate("Recognized Costs Amount", 0);
                TargetJobTask.Validate("Recognized Sales G/L Amount", 0);
                TargetJobTask.Validate("Recognized Costs G/L Amount", 0);
                IsHandled := false;
                OnCopyJobTasksOnBeforeTargetJobTaskInsert(TargetJobTask, SourceJobTask, IsHandled);
                if not IsHandled then
                    TargetJobTask.Insert(true);
                case true of
                    JobPlanningLineSource = JobPlanningLineSource::"Job Planning Lines":
                        CopyJobPlanningLines(SourceJobTask, TargetJobTask);
                    JobPlanningLineSource = JobPlanningLineSource::"Job Ledger Entries":
                        CopyJLEsToJobPlanningLines(SourceJobTask, TargetJobTask);
                end;
                if CopyDimensions then
                    CopyJobTaskDimensions(SourceJobTask, TargetJobTask);
                OnAfterCopyJobTask(TargetJobTask, SourceJobTask, CopyPrices, CopyQuantity);
            until SourceJobTask.Next() = 0;
    end;

    procedure CopyJobPlanningLines(SourceJobTask: Record "Job Task"; TargetJobTask: Record "Job Task")
    var
        SourceJobPlanningLine: Record "Job Planning Line";
        TargetJobPlanningLine: Record "Job Planning Line";
        SourceJob: Record Job;
        NextPlanningLineNo: Integer;
        IsHandled: Boolean;
    begin
        SourceJob.Get(SourceJobTask."Job No.");

        case true of
            (JobTaskDateRangeFrom <> 0D) and (JobTaskDateRangeTo <> 0D):
                SourceJobTask.SetRange("Planning Date Filter", JobTaskDateRangeFrom, JobTaskDateRangeTo);
            (JobTaskDateRangeFrom <> 0D) and (JobTaskDateRangeTo = 0D):
                SourceJobTask.SetFilter("Planning Date Filter", '%1..', JobTaskDateRangeFrom);
            (JobTaskDateRangeFrom = 0D) and (JobTaskDateRangeTo <> 0D):
                SourceJobTask.SetFilter("Planning Date Filter", '..%1', JobTaskDateRangeTo);
        end;

        SourceJobPlanningLine.SetRange("Job No.", SourceJobTask."Job No.");
        SourceJobPlanningLine.SetRange("Job Task No.", SourceJobTask."Job Task No.");
        case JobPlanningLineType of
            JobPlanningLineType::Budget:
                SourceJobPlanningLine.SetRange("Line Type", SourceJobPlanningLine."Line Type"::Budget);
            JobPlanningLineType::Billable:
                SourceJobPlanningLine.SetRange("Line Type", SourceJobPlanningLine."Line Type"::Billable);
        end;
        SourceJobPlanningLine.SetFilter("Planning Date", SourceJobTask.GetFilter("Planning Date Filter"));
        if not SourceJobPlanningLine.FindLast() then
            exit;
        NextPlanningLineNo := 0;
        SourceJobPlanningLine.SetRange("Line No.", 0, SourceJobPlanningLine."Line No.");
        OnCopyJobPlanningLinesOnAfterSourceJobPlanningLineSetFilters(SourceJobPlanningLine, CopyPrices);
        if SourceJobPlanningLine.FindSet() then
            repeat
                IsHandled := false;
                OnCopyJobPlanningLinesOnBeforeTargetJobPlanningLineInit(TargetJobPlanningLine, SourceJobPlanningLine, TargetJobTask, IsHandled);
                if not IsHandled then begin
                    TargetJobPlanningLine.Init();
                    TargetJobPlanningLine.Validate("Job No.", TargetJobTask."Job No.");
                    TargetJobPlanningLine.Validate("Job Task No.", TargetJobTask."Job Task No.");
                    if NextPlanningLineNo = 0 then
                        NextPlanningLineNo := FindLastJobPlanningLine(TargetJobPlanningLine);
                    NextPlanningLineNo += 10000;
                    TargetJobPlanningLine.Validate("Line No.", NextPlanningLineNo);
                    TargetJobPlanningLine.TransferFields(SourceJobPlanningLine, false);
                    if not CopyPrices then
                        TargetJobPlanningLine.UpdateAllAmounts();

                    TargetJobPlanningLine."Remaining Qty." := 0;
                    TargetJobPlanningLine."Remaining Qty. (Base)" := 0;
                    TargetJobPlanningLine."Remaining Total Cost" := 0;
                    TargetJobPlanningLine."Remaining Total Cost (LCY)" := 0;
                    TargetJobPlanningLine."Remaining Line Amount" := 0;
                    TargetJobPlanningLine."Remaining Line Amount (LCY)" := 0;
                    TargetJobPlanningLine."Qty. Posted" := 0;
                    TargetJobPlanningLine."Qty. to Transfer to Journal" := 0;
                    TargetJobPlanningLine."Posted Total Cost" := 0;
                    TargetJobPlanningLine."Posted Total Cost (LCY)" := 0;
                    TargetJobPlanningLine."Posted Line Amount" := 0;
                    TargetJobPlanningLine."Posted Line Amount (LCY)" := 0;
                    TargetJobPlanningLine."Qty. to Transfer to Invoice" := 0;
                    TargetJobPlanningLine."Qty. to Invoice" := 0;
                    TargetJobPlanningLine."Qty. Picked" := 0;
                    TargetJobPlanningLine."Qty. Picked (Base)" := 0;
                    TargetJobPlanningLine."Completely Picked" := false;
                    TargetJobPlanningLine."Ledger Entry No." := 0;
                    TargetJobPlanningLine."Ledger Entry Type" := TargetJobPlanningLine."Ledger Entry Type"::" ";
                    TargetJobPlanningLine."System-Created Entry" := false;
                    OnCopyJobPlanningLinesOnBeforeTargetJobPlanningLineInsert(TargetJobPlanningLine, SourceJobPlanningLine);
                    TargetJobPlanningLine.Insert(true);
                    OnCopyJobPlanningLinesOnAfterTargetJobPlanningLineInsert(TargetJobPlanningLine, SourceJobPlanningLine);
                    if TargetJobPlanningLine.Type <> TargetJobPlanningLine.Type::Text then begin
                        ExchangeJobPlanningLineAmounts(TargetJobPlanningLine, SourceJob."Currency Code");
                        if not CopyQuantity then
                            TargetJobPlanningLine.Validate(Quantity, 0)
                        else
                            TargetJobPlanningLine.Validate(Quantity);
                        OnCopyJobPlanningLinesOnBeforeModifyTargetJobPlanningLine(TargetJobPlanningLine);
                        TargetJobPlanningLine.Modify();
                    end;
                end;
                OnCopyJobPlanningLinesOnAfterCopyTargetJobPlanningLine(TargetJobPlanningLine, SourceJobPlanningLine);
            until SourceJobPlanningLine.Next() = 0;
    end;

    local procedure CopyJLEsToJobPlanningLines(SourceJobTask: Record "Job Task"; TargetJobTask: Record "Job Task")
    var
        TargetJobPlanningLine: Record "Job Planning Line";
        JobLedgEntry: Record "Job Ledger Entry";
        SourceJob: Record Job;
        JobTransferLine: Codeunit "Job Transfer Line";
        NextPlanningLineNo: Integer;
        IsHandled: Boolean;
    begin
        SourceJob.Get(SourceJobTask."Job No.");
        TargetJobPlanningLine.SetRange("Job No.", TargetJobTask."Job No.");
        TargetJobPlanningLine.SetRange("Job Task No.", TargetJobTask."Job Task No.");
        if TargetJobPlanningLine.FindLast() then
            NextPlanningLineNo := TargetJobPlanningLine."Line No." + 10000
        else
            NextPlanningLineNo := 10000;

        JobLedgEntry.SetRange("Job No.", SourceJobTask."Job No.");
        JobLedgEntry.SetRange("Job Task No.", SourceJobTask."Job Task No.");
        case true of
            JobLedgerEntryType = JobLedgerEntryType::Usage:
                JobLedgEntry.SetRange("Entry Type", JobLedgEntry."Entry Type"::Usage);
            JobLedgerEntryType = JobLedgerEntryType::Sale:
                JobLedgEntry.SetRange("Entry Type", JobLedgEntry."Entry Type"::Sale);
        end;
        JobLedgEntry.SetFilter("Posting Date", SourceJobTask.GetFilter("Planning Date Filter"));
        if JobLedgEntry.FindSet() then
            repeat
                TargetJobPlanningLine.Init();
                JobTransferLine.FromJobLedgEntryToPlanningLine(JobLedgEntry, TargetJobPlanningLine);
                TargetJobPlanningLine."Job No." := TargetJobTask."Job No.";
                TargetJobPlanningLine.Validate("Line No.", NextPlanningLineNo);
                TargetJobPlanningLine.Insert(true);
                if JobLedgEntry."Entry Type" = JobLedgEntry."Entry Type"::Usage then
                    TargetJobPlanningLine.Validate("Line Type", TargetJobPlanningLine."Line Type"::Budget)
                else begin
                    TargetJobPlanningLine.Validate("Line Type", TargetJobPlanningLine."Line Type"::Billable);
                    TargetJobPlanningLine.Validate(Quantity, -JobLedgEntry.Quantity);
                    TargetJobPlanningLine.Validate("Unit Cost (LCY)", JobLedgEntry."Unit Cost (LCY)");
                    TargetJobPlanningLine.Validate("Unit Price (LCY)", JobLedgEntry."Unit Price (LCY)");
                    TargetJobPlanningLine.Validate("Line Discount %", JobLedgEntry."Line Discount %");
                end;
                ExchangeJobPlanningLineAmounts(TargetJobPlanningLine, SourceJob."Currency Code");
                IsHandled := false;
                OnCopyJLEsToJobPlanningLinesOnBeforeValidateQuantity(TargetJobPlanningLine, CopyQuantity, IsHandled);
                if not IsHandled then
                    if not CopyQuantity then
                        TargetJobPlanningLine.Validate(Quantity, 0);
                NextPlanningLineNo += 10000;
                TargetJobPlanningLine.Modify();
            until JobLedgEntry.Next() = 0;
    end;

    local procedure CopyJobDimensions(SourceJob: Record Job; var TargetJob: Record Job)
    var
        DefaultDimension: Record "Default Dimension";
        NewDefaultDimension: Record "Default Dimension";
        DimMgt: Codeunit DimensionManagement;
    begin
        DefaultDimension.SetRange("Table ID", DATABASE::Job);
        DefaultDimension.SetRange("No.", TargetJob."No.");
        if DefaultDimension.FindSet() then
            repeat
                DimMgt.DefaultDimOnDelete(DefaultDimension);
                DefaultDimension.Delete();
            until DefaultDimension.Next() = 0;

        DefaultDimension.SetRange("No.", SourceJob."No.");
        if DefaultDimension.FindSet() then
            repeat
                NewDefaultDimension.Init();
                NewDefaultDimension."Table ID" := DATABASE::Job;
                NewDefaultDimension."No." := TargetJob."No.";
                NewDefaultDimension."Dimension Code" := DefaultDimension."Dimension Code";
                NewDefaultDimension.TransferFields(DefaultDimension, false);
                NewDefaultDimension.Insert();
                DimMgt.DefaultDimOnInsert(NewDefaultDimension);
            until DefaultDimension.Next() = 0;

        DimMgt.UpdateDefaultDim(
          DATABASE::Job, TargetJob."No.", TargetJob."Global Dimension 1 Code", TargetJob."Global Dimension 2 Code");

        OnAfterCopyJobDimensions(SourceJob, TargetJob);
    end;

    local procedure CopyJobTaskDimensions(SourceJobTask: Record "Job Task"; TargetJobTask: Record "Job Task")
    var
        DimensionManagement: Codeunit DimensionManagement;
    begin
        DimensionManagement.CopyJobTaskDimToJobTaskDim(SourceJobTask."Job No.",
          SourceJobTask."Job Task No.",
          TargetJobTask."Job No.",
          TargetJobTask."Job Task No.");

        OnAfterCopyJobTaskDimensions(SourceJobTask, TargetJobTask);
    end;

    local procedure ExchangeJobPlanningLineAmounts(var JobPlanningLine: Record "Job Planning Line"; CurrencyCode: Code[10])
    var
        Job: Record Job;
        CurrExchRate: Record "Currency Exchange Rate";
        Currency: Record Currency;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeExchangeJobPlanningLineAmounts(JobPlanningLine, CurrencyCode, IsHandled);
        if IsHandled then
            exit;

        Job.Get(JobPlanningLine."Job No.");
        if CurrencyCode <> Job."Currency Code" then
            if (CurrencyCode = '') and (Job."Currency Code" <> '') then begin
                JobPlanningLine."Currency Code" := Job."Currency Code";
                JobPlanningLine.UpdateCurrencyFactor();
                Currency.Get(JobPlanningLine."Currency Code");
                Currency.TestField("Unit-Amount Rounding Precision");
                JobPlanningLine."Unit Cost" := Round(
                    CurrExchRate.ExchangeAmtLCYToFCY(
                      JobPlanningLine."Currency Date", JobPlanningLine."Currency Code",
                      JobPlanningLine."Unit Cost (LCY)", JobPlanningLine."Currency Factor"),
                    Currency."Unit-Amount Rounding Precision");
                JobPlanningLine."Unit Price" := Round(
                    CurrExchRate.ExchangeAmtLCYToFCY(
                      JobPlanningLine."Currency Date", JobPlanningLine."Currency Code",
                      JobPlanningLine."Unit Price (LCY)", JobPlanningLine."Currency Factor"),
                    Currency."Unit-Amount Rounding Precision");
                JobPlanningLine.Validate("Currency Date");
            end else
                if (CurrencyCode <> '') and (Job."Currency Code" = '') then begin
                    JobPlanningLine."Currency Code" := '';
                    JobPlanningLine."Currency Date" := 0D;
                    JobPlanningLine.UpdateCurrencyFactor();
                    JobPlanningLine."Unit Cost" := JobPlanningLine."Unit Cost (LCY)";
                    JobPlanningLine."Unit Price" := JobPlanningLine."Unit Price (LCY)";
                    JobPlanningLine.Validate("Currency Date");
                end else
                    if (CurrencyCode <> '') and (Job."Currency Code" <> '') then begin
                        JobPlanningLine."Currency Code" := Job."Currency Code";
                        JobPlanningLine.UpdateCurrencyFactor();
                        Currency.Get(JobPlanningLine."Currency Code");
                        Currency.TestField("Unit-Amount Rounding Precision");
                        JobPlanningLine."Unit Cost" := Round(
                            CurrExchRate.ExchangeAmtFCYToFCY(
                              JobPlanningLine."Currency Date", CurrencyCode,
                              JobPlanningLine."Currency Code", JobPlanningLine."Unit Cost"),
                            Currency."Unit-Amount Rounding Precision");
                        JobPlanningLine."Unit Price" := Round(
                            CurrExchRate.ExchangeAmtFCYToFCY(
                              JobPlanningLine."Currency Date", CurrencyCode,
                              JobPlanningLine."Currency Code", JobPlanningLine."Unit Price"),
                            Currency."Unit-Amount Rounding Precision");
                        JobPlanningLine.Validate("Currency Date");
                    end;
    end;

    procedure SetCopyQuantity(CopyQuantity2: Boolean)
    begin
        CopyQuantity := CopyQuantity2;
    end;

    procedure SetCopyPrices(CopyPrices2: Boolean)
    begin
        CopyPrices := CopyPrices2;
    end;

    procedure SetCopyJobPlanningLineType(JobPlanningLineType2: Option " ",Budget,Billable)
    begin
        JobPlanningLineType := JobPlanningLineType2;
    end;

    procedure SetCopyOptions(CopyPrices2: Boolean; CopyQuantity2: Boolean; CopyDimensions2: Boolean; JobPlanningLineSource2: Option "Job Planning Lines","Job Ledger Entries"; JobPlanningLineType2: Option " ",Budget,Billable; JobLedgerEntryType2: Option " ",Usage,Sale)
    begin
        CopyPrices := CopyPrices2;
        CopyQuantity := CopyQuantity2;
        CopyDimensions := CopyDimensions2;
        JobPlanningLineSource := JobPlanningLineSource2;
        JobPlanningLineType := JobPlanningLineType2;
        JobLedgerEntryType := JobLedgerEntryType2;
    end;

    procedure SetJobTaskRange(JobTaskRangeFrom2: Code[20]; JobTaskRangeTo2: Code[20])
    begin
        JobTaskRangeFrom := JobTaskRangeFrom2;
        JobTaskRangeTo := JobTaskRangeTo2;
    end;

    procedure SetJobTaskDateRange(JobTaskDateRangeFrom2: Date; JobTaskDateRangeTo2: Date)
    begin
        JobTaskDateRangeFrom := JobTaskDateRangeFrom2;
        JobTaskDateRangeTo := JobTaskDateRangeTo2;
    end;

    procedure GetJobTaskDateRange(var JobTaskDateRangeFrom2: Date; var JobTaskDateRangeTo2: Date)
    begin
        JobTaskDateRangeFrom2 := JobTaskDateRangeFrom;
        JobTaskDateRangeTo2 := JobTaskDateRangeTo;
    end;

    local procedure FindLastJobPlanningLine(JobPlanningLine: Record "Job Planning Line"): Integer
    begin
        JobPlanningLine.SetRange("Job No.", JobPlanningLine."Job No.");
        JobPlanningLine.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        if JobPlanningLine.FindLast() then
            exit(JobPlanningLine."Line No.");
        exit(0);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyJob(var TargetJob: Record Job; SourceJob: Record Job)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCopyJob(SourceJob: Record Job; TargetJobNo: Code[20]; TargetJobDescription: Text[100]; TargetJobSellToCustomer: Code[20]; TargetJobBillToCustomer: Code[20]; CopyDimensions: Boolean; CopyPrices: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExchangeJobPlanningLineAmounts(var JobPlanningLine: Record "Job Planning Line"; CurrencyCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyJobTask(var TargetJobTask: Record "Job Task"; SourceJobTask: Record "Job Task"; CopyPrices: Boolean; CopyQuantity: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyJobDimensions(SourceJob: Record Job; var TargetJob: Record Job)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyJobTaskDimensions(SourceJobTask: Record "Job Task"; TargetJobTask: Record "Job Task")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyJobPrices(var SourceJob: Record Job; var TargetJob: Record Job)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCopyJobTasks(var SourceJob: Record Job; var TargetJob: Record Job; var IsHandled: Boolean; CopyDimensions: Boolean; CopyQuantity: Boolean; CopyPrices: Boolean; JobTaskRangeFrom: Code[20]; JobTaskRangeTo: Code[20]; JobPlanningLineSource: Option; JobLedgerEntryType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyJobPlanningLinesOnBeforeModifyTargetJobPlanningLine(var TargetJobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyJobPlanningLinesOnAfterCopyTargetJobPlanningLine(var TargetJobPlanningLine: Record "Job Planning Line"; SourceJobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyJobPlanningLinesOnAfterSourceJobPlanningLineSetFilters(var SourceJobPlanningLine: Record "Job Planning Line"; CopyPrices: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyJobPlanningLinesOnAfterTargetJobPlanningLineInsert(var TargetJobPlanningLine: Record "Job Planning Line"; SourceJobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyJobPlanningLinesOnBeforeTargetJobPlanningLineInsert(var TargetJobPlanningLine: Record "Job Planning Line"; SourceJobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyJobTasksOnBeforeTargetJobTaskInsert(var TargetJobTask: Record "Job Task"; SourceJobTask: Record "Job Task"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyJobTasksOnAfterSourceJobTaskSetFilters(var SourceJobTask: Record "Job Task"; SourceJob: Record Job)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCopyJobPlanningLinesOnBeforeTargetJobPlanningLineInit(var TargetJobPlanningLine: Record "Job Planning Line"; SourceJobPlanningLine: Record "Job Planning Line"; TargetJobTask: Record "Job Task"; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCopyJLEsToJobPlanningLinesOnBeforeValidateQuantity(var TargetJobPlanningLine: Record "Job Planning Line"; var CopyQuantity: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCopyJobOnBeforeTargetJobInsert(var TargetJob: Record Job; var SourceJob: Record Job)
    begin
    end;
}

