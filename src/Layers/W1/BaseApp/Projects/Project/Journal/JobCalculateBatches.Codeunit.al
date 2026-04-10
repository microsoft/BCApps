// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Journal;

using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.Posting;

codeunit 1005 "Job Calculate Batches"
{

    trigger OnRun()
    begin
    end;

    var
        JobDiffBuffer: array[2] of Record "Job Difference Buffer" temporary;
        PeriodLength2: DateFormula;

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 lines were successfully transferred to the journal.';
#pragma warning restore AA0470
        Text001: Label 'There is no remaining usage on the project(s).';
        Text002: Label 'The lines were successfully changed.';
        Text003: Label 'The From Date is later than the To Date.';
#pragma warning disable AA0470
        Text004: Label 'You must specify %1.';
#pragma warning restore AA0470
        Text005: Label 'There is nothing to invoice.';
        Text006: Label '1 invoice is created.';
#pragma warning disable AA0470
        Text007: Label '%1 invoices are created.';
#pragma warning restore AA0470
        Text008: Label 'The selected entries were successfully transferred to planning lines.';
        Text009: Label 'Total Cost,Total Price,Line Discount Amount,Line Amount';
#pragma warning restore AA0074

    procedure SplitLines(var JT2: Record "Job Task"): Integer
    var
        JT: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        NoOfLinesSplitted: Integer;
    begin
        JobPlanningLine.LockTable();
        JT.LockTable();
        JT := JT2;
        JT.Find();
        JobPlanningLine.SetRange("Job No.", JT."Job No.");
        JobPlanningLine.SetRange("Job Task No.", JT."Job Task No.");
        JobPlanningLine.SetFilter("Planning Date", JT2.GetFilter("Planning Date Filter"));
        if JobPlanningLine.Find('-') then
            repeat
                if JobPlanningLine."Line Type" = JobPlanningLine."Line Type"::"Both Budget and Billable" then
                    if SplitOneLine(JobPlanningLine) then
                        NoOfLinesSplitted += 1;
            until JobPlanningLine.Next() = 0;
        exit(NoOfLinesSplitted);
    end;

    local procedure SplitOneLine(JobPlanningLine: Record "Job Planning Line"): Boolean
    var
        JobPlanningLine2: Record "Job Planning Line";
        NextLineNo: Integer;
    begin
        JobPlanningLine.TestField("Job No.");
        JobPlanningLine.TestField("Job Task No.");
        JobPlanningLine2 := JobPlanningLine;
        JobPlanningLine2.SetRange("Job No.", JobPlanningLine2."Job No.");
        JobPlanningLine2.SetRange("Job Task No.", JobPlanningLine2."Job Task No.");
        NextLineNo := JobPlanningLine."Line No." + 10000;
        if JobPlanningLine2.Next() <> 0 then
            NextLineNo := (JobPlanningLine."Line No." + JobPlanningLine2."Line No.") div 2;
        JobPlanningLine.Validate("Line Type", JobPlanningLine."Line Type"::Billable);
        JobPlanningLine.Modify();
        JobPlanningLine.Validate("Line Type", JobPlanningLine."Line Type"::Budget);
        JobPlanningLine.ClearTracking();
        JobPlanningLine."Line No." := NextLineNo;
        JobPlanningLine.InitJobPlanningLine();
        OnBeforeJobPlanningLineInsert(JobPlanningLine);
        JobPlanningLine.Insert(true);
        exit(true);
    end;

    procedure TransferToPlanningLine(var JobLedgEntry: Record "Job Ledger Entry"; LineType: Integer)
    var
        JobPostLine: Codeunit "Job Post-Line";
    begin
        JobLedgEntry.LockTable();
        if JobLedgEntry.Find('-') then
            repeat
                OnBeforeTransferToPlanningLine(JobLedgEntry);
                JobLedgEntry.TestField("Job No.");
                JobLedgEntry.TestField("Job Task No.");
                JobLedgEntry.TestField("Entry Type", JobLedgEntry."Entry Type"::Usage);
                JobLedgEntry."Line Type" := Enum::"Job Line Type".FromInteger(LineType);
                Clear(JobPostLine);
                JobPostLine.InsertPlLineFromLedgEntry(JobLedgEntry);
            until JobLedgEntry.Next() = 0;
        Commit();
        Message(Text008);
    end;

    procedure ChangePlanningDates(JT: Record "Job Task"; ScheduleLine: Boolean; ContractLine: Boolean; PeriodLength: DateFormula; FixedDate: Date; StartingDate: Date; EndingDate: Date)
    var
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
    begin
        JobPlanningLine.LockTable();
        JT.LockTable();

        if EndingDate = 0D then
            EndingDate := DMY2Date(31, 12, 9999);
        if EndingDate < StartingDate then
            Error(Text003);
        JT.TestField("Job No.");
        JT.TestField("Job Task No.");
        Job.Get(JT."Job No.");
        if Job.Blocked = Job.Blocked::All then
            Job.TestBlocked();
        JT.Find();
        JobPlanningLine.SetCurrentKey("Job No.", "Job Task No.");
        JobPlanningLine.SetRange("Job No.", Job."No.");
        JobPlanningLine.SetRange("Job Task No.", JT."Job Task No.");

        if ScheduleLine and not ContractLine then
            JobPlanningLine.SetRange("Schedule Line", true);
        if not ScheduleLine and ContractLine then
            JobPlanningLine.SetRange("Contract Line", true);
        JobPlanningLine.SetRange("Planning Date", StartingDate, EndingDate);
        if JobPlanningLine.Find('-') then
            repeat
                JobPlanningLine.CalcFields("Qty. Transferred to Invoice");
                if JobPlanningLine."Qty. Transferred to Invoice" = 0 then begin
                    JobPlanningLine.TestField("Planning Date");
                    if FixedDate > 0D then
                        JobPlanningLine."Planning Date" := FixedDate
                    else
                        if PeriodLength <> PeriodLength2 then
                            JobPlanningLine."Planning Date" :=
                              CalcDate(PeriodLength, JobPlanningLine."Planning Date");
                    JobPlanningLine."Last Date Modified" := Today;
                    JobPlanningLine."User ID" := CopyStr(UserId(), 1, MaxStrLen(JobPlanningLine."User ID"));
                    OnChangePlanningDatesOnBeforeJobPlanningLineModify(JobPlanningLine);
                    JobPlanningLine.Modify();
                end;
            until JobPlanningLine.Next() = 0;
    end;

    procedure ChangeCurrencyDates(JT: Record "Job Task"; scheduleLine: Boolean; ContractLine: Boolean; PeriodLength: DateFormula; FixedDate: Date; StartingDate: Date; EndingDate: Date)
    var
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        ForceDateUpdate: Boolean;
    begin
        if EndingDate = 0D then
            EndingDate := DMY2Date(31, 12, 9999);
        if EndingDate < StartingDate then
            Error(Text003);
        JT.TestField("Job No.");
        JT.TestField("Job Task No.");
        Job.Get(JT."Job No.");
        if Job.Blocked = Job.Blocked::All then
            Job.TestBlocked();
        JT.Find();
        JobPlanningLine.SetCurrentKey("Job No.", "Job Task No.");
        JobPlanningLine.SetRange("Job No.", Job."No.");
        JobPlanningLine.SetRange("Job Task No.", JT."Job Task No.");

        if scheduleLine and not ContractLine then
            JobPlanningLine.SetRange("Schedule Line", true);
        if not scheduleLine and ContractLine then
            JobPlanningLine.SetRange("Contract Line", true);
        JobPlanningLine.SetRange("Currency Date", StartingDate, EndingDate);
        if JobPlanningLine.Find('-') then
            repeat
                JobPlanningLine.CalcFields("Qty. Transferred to Invoice");
                ForceDateUpdate := false;
                OnChangeCurrencyDatesOnBeforeChangeCurrencyDate(JobPlanningLine, ForceDateUpdate);
                if (JobPlanningLine."Qty. Transferred to Invoice" = 0) or ForceDateUpdate then begin
                    JobPlanningLine.TestField("Planning Date");
                    JobPlanningLine.TestField("Currency Date");
                    if FixedDate > 0D then begin
                        JobPlanningLine."Currency Date" := FixedDate;
                        JobPlanningLine."Document Date" := FixedDate;
                    end else
                        if PeriodLength <> PeriodLength2 then begin
                            JobPlanningLine."Currency Date" :=
                              CalcDate(PeriodLength, JobPlanningLine."Currency Date");
                            JobPlanningLine."Document Date" :=
                              CalcDate(PeriodLength, JobPlanningLine."Document Date");
                        end;
                    JobPlanningLine.Validate("Currency Date");
                    JobPlanningLine."Last Date Modified" := Today;
                    JobPlanningLine."User ID" := CopyStr(UserId(), 1, MaxStrLen(JobPlanningLine."User ID"));
                    OnChangeCurrencyDatesOnBeforeJobPlanningLineModify(JobPlanningLine);
                    JobPlanningLine.Modify(true);
                end;
            until JobPlanningLine.Next() = 0;
    end;

    procedure ChangeDatesEnd()
    begin
        Commit();
        Message(Text002);
    end;

    procedure CreateJT(JobPlanningLine: Record "Job Planning Line")
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateJT(IsHandled, JobPlanningLine);
        if IsHandled then
            exit;

        if JobPlanningLine.Type = JobPlanningLine.Type::Text then
            exit;
        if not JobPlanningLine."Schedule Line" then
            exit;
        Job.Get(JobPlanningLine."Job No.");
        JobTask.Get(JobPlanningLine."Job No.", JobPlanningLine."Job Task No.");
        JobDiffBuffer[1]."Job No." := JobPlanningLine."Job No.";
        JobDiffBuffer[1]."Job Task No." := JobPlanningLine."Job Task No.";
        JobDiffBuffer[1].Type := JobPlanningLine.Type;
        JobDiffBuffer[1]."No." := JobPlanningLine."No.";
        JobDiffBuffer[1]."Location Code" := JobPlanningLine."Location Code";
        JobDiffBuffer[1]."Variant Code" := JobPlanningLine."Variant Code";
        JobDiffBuffer[1]."Unit of Measure code" := JobPlanningLine."Unit of Measure Code";
        JobDiffBuffer[1]."Work Type Code" := JobPlanningLine."Work Type Code";
        JobDiffBuffer[1].Quantity := JobPlanningLine.Quantity;
        JobDiffBuffer[1]."Line Amount" := JobPlanningLine."Line Amount";
        OnCreateJTOnBeforeAssigneJobDiffBuffer2(JobDiffBuffer, JobPlanningLine);
        JobDiffBuffer[2] := JobDiffBuffer[1];
        if JobDiffBuffer[2].Find() then begin
            JobDiffBuffer[2].Quantity := JobDiffBuffer[2].Quantity + JobDiffBuffer[1].Quantity;
            JobDiffBuffer[2].Modify();
        end else
            JobDiffBuffer[1].Insert();
    end;

    procedure InitDiffBuffer()
    begin
        Clear(JobDiffBuffer);
        JobDiffBuffer[1].DeleteAll();
    end;

    procedure PostDiffBuffer(DocNo: Code[20]; PostingDate: Date; TemplateName: Code[10]; BatchName: Code[10])
    var
        JobLedgEntry: Record "Job Ledger Entry";
        JobJnlLine: Record "Job Journal Line";
        JobJnlTemplate: Record "Job Journal Template";
        JobJnlBatch: Record "Job Journal Batch";
        NextLineNo: Integer;
        LineNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostDiffBuffer(JobDiffBuffer, IsHandled);
        if IsHandled then
            exit;

        if JobDiffBuffer[1].Find('-') then
            repeat
                JobLedgEntry.SetCurrentKey("Job No.", "Job Task No.");
                JobLedgEntry.SetRange("Job No.", JobDiffBuffer[1]."Job No.");
                JobLedgEntry.SetRange("Job Task No.", JobDiffBuffer[1]."Job Task No.");
                JobLedgEntry.SetRange("Entry Type", JobLedgEntry."Entry Type"::Usage);
                JobLedgEntry.SetRange(Type, JobDiffBuffer[1].Type);
                JobLedgEntry.SetRange("No.", JobDiffBuffer[1]."No.");
                JobLedgEntry.SetRange("Location Code", JobDiffBuffer[1]."Location Code");
                JobLedgEntry.SetRange("Variant Code", JobDiffBuffer[1]."Variant Code");
                JobLedgEntry.SetRange("Unit of Measure Code", JobDiffBuffer[1]."Unit of Measure code");
                JobLedgEntry.SetRange("Work Type Code", JobDiffBuffer[1]."Work Type Code");
                OnPostDiffBufferOnAfterSetFilters(JobLedgEntry, JobDiffBuffer[1]);
                if JobLedgEntry.Find('-') then
                    repeat
                        JobDiffBuffer[1].Quantity := JobDiffBuffer[1].Quantity - JobLedgEntry.Quantity;
                    until JobLedgEntry.Next() = 0;
                OnPostDiffBufferOnBeforeModify(JobLedgEntry, JobDiffBuffer[1]);
                JobDiffBuffer[1].Modify();
            until JobDiffBuffer[1].Next() = 0;
        JobJnlLine.LockTable();
        JobJnlLine.Validate("Journal Template Name", TemplateName);
        JobJnlLine.Validate("Journal Batch Name", BatchName);
        JobJnlLine.SetRange("Journal Template Name", JobJnlLine."Journal Template Name");
        JobJnlLine.SetRange("Journal Batch Name", JobJnlLine."Journal Batch Name");
        if JobJnlLine.FindLast() then
            NextLineNo := JobJnlLine."Line No." + 10000
        else
            NextLineNo := 10000;

        if JobDiffBuffer[1].Find('-') then
            repeat
                if JobDiffBuffer[1].Quantity <> 0 then begin
                    Clear(JobJnlLine);
                    JobJnlLine."Journal Template Name" := TemplateName;
                    JobJnlLine."Journal Batch Name" := BatchName;
                    JobJnlTemplate.Get(TemplateName);
                    JobJnlBatch.Get(TemplateName, BatchName);
                    JobJnlLine."Source Code" := JobJnlTemplate."Source Code";
                    JobJnlLine."Reason Code" := JobJnlBatch."Reason Code";
                    JobJnlLine.DontCheckStdCost();
                    JobJnlLine.Validate("Job No.", JobDiffBuffer[1]."Job No.");
                    JobJnlLine.Validate("Job Task No.", JobDiffBuffer[1]."Job Task No.");
                    JobJnlLine.Validate("Posting Date", PostingDate);
                    JobJnlLine.Validate(Type, JobDiffBuffer[1].Type);
                    JobJnlLine.Validate("No.", JobDiffBuffer[1]."No.");
                    JobJnlLine.Validate("Variant Code", JobDiffBuffer[1]."Variant Code");
                    JobJnlLine.Validate("Unit of Measure Code", JobDiffBuffer[1]."Unit of Measure code");
                    JobJnlLine.Validate("Location Code", JobDiffBuffer[1]."Location Code");
                    if JobDiffBuffer[1].Type = JobDiffBuffer[1].Type::Resource then
                        JobJnlLine.Validate("Work Type Code", JobDiffBuffer[1]."Work Type Code");
                    JobJnlLine."Document No." := DocNo;
                    JobJnlLine.Validate(Quantity, JobDiffBuffer[1].Quantity);
                    JobJnlLine.Validate("Unit Price", JobDiffBuffer[1]."Line Amount" / JobDiffBuffer[1].Quantity);
                    JobJnlLine."Line No." := NextLineNo;
                    NextLineNo := NextLineNo + 10000;
                    JobJnlLine.Insert(true);
                    OnPostDiffBufferOnAfterInsertJobJnlLine(JobJnlLine, JobDiffBuffer[1]);
                    LineNo := LineNo + 1;
                end;
            until JobDiffBuffer[1].Next() = 0;
        Commit();
        if LineNo = 0 then
            Message(Text001)
        else
            Message(Text000, LineNo);
    end;

    procedure BatchError(PostingDate: Date; DocNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        if PostingDate = 0D then
            Error(Text004, GLEntry.FieldCaption("Posting Date"));
        if DocNo = '' then
            Error(Text004, GLEntry.FieldCaption("Document No."));
    end;

    procedure EndCreateInvoice(NoOfInvoices: Integer)
    var
        IsHandled: Boolean;
    begin
        OnBeforeEndCreateInvoice(NoOfInvoices, IsHandled);
        if IsHandled then
            exit;

        Commit();
        if NoOfInvoices <= 0 then
            Message(Text005);
        if NoOfInvoices = 1 then
            Message(Text006);
        if NoOfInvoices > 1 then
            Message(Text007, NoOfInvoices);
    end;

    procedure CalculateActualToBudget(var Job: Record Job; JT: Record "Job Task"; var JobDiffBuffer2: Record "Job Difference Buffer"; var JobDiffBuffer3: Record "Job Difference Buffer"; CurrencyType: Option LCY,FCY)
    var
        JobPlanningLine: Record "Job Planning Line";
        JobLedgEntry: Record "Job Ledger Entry";
    begin
        ClearAll();
        Clear(JobDiffBuffer);
        Clear(JobDiffBuffer2);
        Clear(JobDiffBuffer3);

        JobDiffBuffer[1].DeleteAll();
        JobDiffBuffer2.DeleteAll();
        JobDiffBuffer3.DeleteAll();

        JT.Find();
        JobPlanningLine.SetRange("Job No.", JT."Job No.");
        JobPlanningLine.SetRange("Job Task No.", JT."Job Task No.");
        JobPlanningLine.SetFilter("Planning Date", Job.GetFilter("Planning Date Filter"));

        JobLedgEntry.SetRange("Job No.", JT."Job No.");
        JobLedgEntry.SetRange("Job Task No.", JT."Job Task No.");
        JobLedgEntry.SetFilter("Posting Date", Job.GetFilter("Posting Date Filter"));

        if JobPlanningLine.Find('-') then
            repeat
                InsertDiffBuffer(JobLedgEntry, JobPlanningLine, 0, CurrencyType);
            until JobPlanningLine.Next() = 0;

        if JobLedgEntry.Find('-') then
            repeat
                InsertDiffBuffer(JobLedgEntry, JobPlanningLine, 1, CurrencyType);
            until JobLedgEntry.Next() = 0;

        if JobDiffBuffer[1].Find('-') then
            repeat
                if JobDiffBuffer[1]."Entry type" = JobDiffBuffer[1]."Entry type"::Budget then begin
                    JobDiffBuffer2 := JobDiffBuffer[1];
                    JobDiffBuffer2.Insert();
                end else begin
                    JobDiffBuffer3 := JobDiffBuffer[1];
                    JobDiffBuffer3."Entry type" := JobDiffBuffer3."Entry type"::Budget;
                    JobDiffBuffer3.Insert();
                end;
            until JobDiffBuffer[1].Next() = 0;
    end;

    local procedure InsertDiffBuffer(var JobLedgEntry: Record "Job Ledger Entry"; var JobPlanningLine: Record "Job Planning Line"; LineType: Option Schedule,Usage; CurrencyType: Option LCY,FCY)
    begin
        OnBeforeInsertDiffBuffer(JobLedgEntry, JobPlanningLine, JobDiffBuffer, LineType, CurrencyType);

        if LineType = LineType::Schedule then begin
            if JobPlanningLine.Type = JobPlanningLine.Type::Text then
                exit;
            if not JobPlanningLine."Schedule Line" then
                exit;
            JobDiffBuffer[1].Type := JobPlanningLine.Type;
            JobDiffBuffer[1]."No." := JobPlanningLine."No.";
            JobDiffBuffer[1]."Entry type" := JobDiffBuffer[1]."Entry type"::Budget;
            JobDiffBuffer[1]."Unit of Measure code" := JobPlanningLine."Unit of Measure Code";
            JobDiffBuffer[1]."Work Type Code" := JobPlanningLine."Work Type Code";
            JobDiffBuffer[1].Quantity := JobPlanningLine.Quantity;
            if CurrencyType = CurrencyType::LCY then begin
                JobDiffBuffer[1]."Total Cost" := JobPlanningLine."Total Cost (LCY)";
                JobDiffBuffer[1]."Line Amount" := JobPlanningLine."Line Amount (LCY)";
            end else begin
                JobDiffBuffer[1]."Total Cost" := JobPlanningLine."Total Cost";
                JobDiffBuffer[1]."Line Amount" := JobPlanningLine."Line Amount";
            end;
            JobDiffBuffer[2] := JobDiffBuffer[1];
            if JobDiffBuffer[2].Find() then begin
                JobDiffBuffer[2].Quantity :=
                    JobDiffBuffer[2].Quantity + JobDiffBuffer[1].Quantity;
                JobDiffBuffer[2]."Total Cost" :=
                    JobDiffBuffer[2]."Total Cost" + JobDiffBuffer[1]."Total Cost";
                JobDiffBuffer[2]."Line Amount" :=
                    JobDiffBuffer[2]."Line Amount" + JobDiffBuffer[1]."Line Amount";
                JobDiffBuffer[2].Modify();
            end else
                JobDiffBuffer[1].Insert();
        end;

        if LineType = LineType::Usage then begin
            if JobLedgEntry."Entry Type" <> JobLedgEntry."Entry Type"::Usage then
                exit;
            JobDiffBuffer[1].Type := JobLedgEntry.Type;
            JobDiffBuffer[1]."No." := JobLedgEntry."No.";
            JobDiffBuffer[1]."Entry type" := JobDiffBuffer[1]."Entry type"::Usage;
            JobDiffBuffer[1]."Unit of Measure code" := JobLedgEntry."Unit of Measure Code";
            JobDiffBuffer[1]."Work Type Code" := JobLedgEntry."Work Type Code";
            JobDiffBuffer[1].Quantity := JobLedgEntry.Quantity;
            if CurrencyType = CurrencyType::LCY then begin
                JobDiffBuffer[1]."Total Cost" := JobLedgEntry."Total Cost (LCY)";
                JobDiffBuffer[1]."Line Amount" := JobLedgEntry."Line Amount (LCY)";
            end else begin
                JobDiffBuffer[1]."Total Cost" := JobLedgEntry."Total Cost";
                JobDiffBuffer[1]."Line Amount" := JobLedgEntry."Line Amount";
            end;
            JobDiffBuffer[2] := JobDiffBuffer[1];
            if JobDiffBuffer[2].Find() then begin
                JobDiffBuffer[2].Quantity :=
                    JobDiffBuffer[2].Quantity + JobDiffBuffer[1].Quantity;
                JobDiffBuffer[2]."Total Cost" :=
                    JobDiffBuffer[2]."Total Cost" + JobDiffBuffer[1]."Total Cost";
                JobDiffBuffer[2]."Line Amount" :=
                    JobDiffBuffer[2]."Line Amount" + JobDiffBuffer[1]."Line Amount";
                JobDiffBuffer[2].Modify();
            end else
                JobDiffBuffer[1].Insert();
        end;

        OnAfterInsertDiffBuffer(JobLedgEntry, JobPlanningLine, JobDiffBuffer, LineType, CurrencyType);
    end;

    procedure GetCurrencyCode(var Job: Record Job; Type: Option "0","1","2","3"; CurrencyType: Option "Local Currency","Foreign Currency"): Text[50]
    var
        GLSetup: Record "General Ledger Setup";
        CurrencyCode: Code[20];
    begin
        GLSetup.Get();
        if CurrencyType = CurrencyType::"Local Currency" then
            CurrencyCode := GLSetup."LCY Code"
        else
            if Job."Currency Code" <> '' then
                CurrencyCode := Job."Currency Code"
            else
                CurrencyCode := GLSetup."LCY Code";
        exit(SelectStr(Type + 1, Text009) + ' (' + CurrencyCode + ')');
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeJobPlanningLineInsert(var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostDiffBuffer(var JobDiffBuffer: array[2] of Record "Job Difference Buffer" temporary; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferToPlanningLine(var JobLedgerEntry: Record "Job Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateJTOnBeforeAssigneJobDiffBuffer2(var JobDiffBuffer: array[2] of Record "Job Difference Buffer" temporary; JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnChangeCurrencyDatesOnBeforeJobPlanningLineModify(var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnChangePlanningDatesOnBeforeJobPlanningLineModify(var JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDiffBufferOnAfterInsertJobJnlLine(var JobJnlLine: Record "Job Journal Line"; var JobDiffBuffer: Record "Job Difference Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDiffBufferOnBeforeModify(var JobLedgEntry: Record "Job Ledger Entry"; var JobDiffBuffer: Record "Job Difference Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostDiffBufferOnAfterSetFilters(var JobLedgerEntry: Record "Job Ledger Entry"; var JobDifferenceBuffer: Record "Job Difference Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateJT(var IsHanlded: Boolean; JobPlanningLine: Record "Job Planning Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertDiffBuffer(var JobLedgerEntry: Record "Job Ledger Entry"; var JobPlanningLine: Record "Job Planning Line"; var JobDiffBuffer: array[2] of Record "Job Difference Buffer" temporary; LineType: Option Schedule,Usage; CurrencyType: Option LCY,FCY)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertDiffBuffer(var JobLedgerEntry: Record "Job Ledger Entry"; var JobPlanningLine: Record "Job Planning Line"; var JobDiffBuffer: array[2] of Record "Job Difference Buffer" temporary; LineType: Option Schedule,Usage; CurrencyType: Option LCY,FCY)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnChangeCurrencyDatesOnBeforeChangeCurrencyDate(var JobPlanningLine: Record "Job Planning Line"; var ForceDateUpdate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeEndCreateInvoice(var NoOfInvoices: Integer; var IsHandled: Boolean)
    begin
    end;
}

