// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

using Microsoft.Foundation.NoSeries;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Journal;
using Microsoft.Projects.Project.Setup;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Projects.Resources.Setup;

report 952 "Suggest Job Jnl. Lines"
{
    Caption = 'Suggest Project Jnl. Lines';
    ProcessingOnly = true;

    dataset
    {
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(StartingDate; StartingDate)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Starting Date';
                        ToolTip = 'Specifies the date from which the report or batch job processes information.';
                    }
                    field(EndingDate; EndingDate)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Ending Date';
                        ToolTip = 'Specifies the date to which the report or batch job processes information.';
                    }
                    field(ResourceNoFilter; ResourceNoFilter)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Resource No. Filter';
                        TableRelation = Resource;
                        ToolTip = 'Specifies the resource number that the batch job will suggest project lines for.';
                    }
                    field(JobNoFilter; JobNoFilter)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Project No. Filter';
                        TableRelation = Job;
                        ToolTip = 'Specifies a filter for the project numbers that will be included in the report.';
                    }
                    field(JobTaskNoFilter; JobTaskNoFilter)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Project Task No. Filter';
                        ToolTip = 'Specifies a filter for the project task numbers that will be included in the report.';

                        trigger OnLookup(var Text: Text): Boolean
                        var
                            JobTask: Record "Job Task";
                        begin
                            JobTask.FilterGroup(2);
                            if JobNoFilter <> '' then
                                JobTask.SetFilter("Job No.", JobNoFilter);
                            JobTask.FilterGroup(0);
                            if PAGE.RunModal(PAGE::"Job Task List", JobTask) = ACTION::LookupOK then
                                JobTask.TestField("Job Task Type", JobTask."Job Task Type"::Posting);
                            JobTaskNoFilter := JobTask."Job Task No.";
                        end;
                    }
                }
            }
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    var
        JobsSetup: Record "Jobs Setup";
        NoSeries: Codeunit "No. Series";
        TimeSheetMgt: Codeunit "Time Sheet Management";
        NextDocNo: Code[20];
        LineNo: Integer;
        QtyToPost: Decimal;
    begin
        DateFilter := TimeSheetMgt.GetDateFilter(StartingDate, EndingDate);
        FillTimeSheetLineBuffer();

        if TempTimeSheetLine.FindSet() then begin
            JobJnlLine.LockTable();
            JobJnlTemplate.Get(JobJnlLine."Journal Template Name");
            JobJnlBatch.Get(JobJnlLine."Journal Template Name", JobJnlLine."Journal Batch Name");
            JobsSetup.SetLoadFields("Document No. Is Job No.");
            JobsSetup.Get();
            if not JobsSetup."Document No. Is Job No." then
                if JobJnlBatch."No. Series" = '' then
                    NextDocNo := ''
                else
                    NextDocNo := NoSeries.PeekNextNo(JobJnlBatch."No. Series", TempTimeSheetLine."Time Sheet Starting Date");

            JobJnlLine.SetRange("Journal Template Name", JobJnlLine."Journal Template Name");
            JobJnlLine.SetRange("Journal Batch Name", JobJnlLine."Journal Batch Name");
            if JobJnlLine.FindLast() then;
            LineNo := JobJnlLine."Line No.";

            repeat
                TimeSheetHeader.Get(TempTimeSheetLine."Time Sheet No.");
                TimeSheetDetail.SetRange("Time Sheet No.", TempTimeSheetLine."Time Sheet No.");
                TimeSheetDetail.SetRange("Time Sheet Line No.", TempTimeSheetLine."Line No.");
                if DateFilter <> '' then
                    TimeSheetDetail.SetFilter(Date, DateFilter);
                TimeSheetDetail.SetFilter(Quantity, '<>0');
                TimeSheetDetail.SetRange(Posted, false);
                if TimeSheetDetail.FindSet() then
                    repeat
                        QtyToPost := TimeSheetDetail.GetMaxQtyToPost();
                        if QtyToPost <> 0 then begin
                            JobJnlLine.Init();
                            LineNo := LineNo + 10000;
                            JobJnlLine."Line No." := LineNo;
                            JobJnlLine."Time Sheet No." := TimeSheetDetail."Time Sheet No.";
                            JobJnlLine."Time Sheet Line No." := TimeSheetDetail."Time Sheet Line No.";
                            JobJnlLine."Time Sheet Date" := TimeSheetDetail.Date;
                            JobJnlLine.Validate("Job No.", TimeSheetDetail."Job No.");
                            JobJnlLine."Source Code" := JobJnlTemplate."Source Code";
                            if TimeSheetDetail."Job Task No." <> '' then
                                JobJnlLine.Validate("Job Task No.", TimeSheetDetail."Job Task No.");
                            JobJnlLine.Validate(Type, JobJnlLine.Type::Resource);
                            JobJnlLine.Validate("No.", TimeSheetHeader."Resource No.");
                            if TempTimeSheetLine."Work Type Code" <> '' then
                                JobJnlLine.Validate("Work Type Code", TempTimeSheetLine."Work Type Code");
                            JobJnlLine.Validate("Posting Date", TimeSheetDetail.Date);
                            if not JobsSetup."Document No. Is Job No." then begin
                                JobJnlLine."Document No." := NextDocNo;
                                NextDocNo := IncStr(NextDocNo);
                            end;
                            JobJnlLine."Posting No. Series" := JobJnlBatch."Posting No. Series";
                            SetJobJournalLineDescription(TempTimeSheetLine.Description, TimeSheetDetail);
                            JobJnlLine.Validate(Quantity, QtyToPost);
                            JobJnlLine.Validate(Chargeable, TempTimeSheetLine.Chargeable);
                            JobJnlLine."Reason Code" := JobJnlBatch."Reason Code";
                            OnAfterTransferTimeSheetDetailToJobJnlLine(JobJnlLine, JobJnlTemplate, TempTimeSheetLine, TimeSheetDetail, JobJnlBatch, LineNo);
                            JobJnlLine.Insert();
                        end;
                    until TimeSheetDetail.Next() = 0;
                OnOnPostReportOnTempTimeSheetLineEndLoop(JobJnlLine, NextDocNo, LineNo);
            until TempTimeSheetLine.Next() = 0;
        end;
    end;

    var
        JobJnlLine: Record "Job Journal Line";
        JobJnlBatch: Record "Job Journal Batch";
        JobJnlTemplate: Record "Job Journal Template";
        TimeSheetHeader: Record "Time Sheet Header";
        TimeSheetLine: Record "Time Sheet Line";
        TempTimeSheetLine: Record "Time Sheet Line" temporary;
        TimeSheetDetail: Record "Time Sheet Detail";
        ResourceNoFilter: Code[1024];
        JobNoFilter: Code[1024];
        JobTaskNoFilter: Code[1024];
        StartingDate: Date;
        EndingDate: Date;
        DateFilter: Text[30];

    procedure SetJobJnlLine(NewJobJnlLine: Record "Job Journal Line")
    begin
        JobJnlLine := NewJobJnlLine;
    end;

    procedure InitParameters(NewJobJnlLine: Record "Job Journal Line"; NewResourceNoFilter: Code[1024]; NewJobNoFilter: Code[1024]; NewJobTaskNoFilter: Code[1024]; NewStartingDate: Date; NewEndingDate: Date)
    begin
        JobJnlLine := NewJobJnlLine;
        ResourceNoFilter := NewResourceNoFilter;
        JobNoFilter := NewJobNoFilter;
        JobTaskNoFilter := NewJobTaskNoFilter;
        StartingDate := NewStartingDate;
        EndingDate := NewEndingDate;
    end;

    local procedure FillTimeSheetLineBuffer()
    var
        SkipLine: Boolean;
    begin
        if ResourceNoFilter <> '' then
            TimeSheetHeader.SetFilter("Resource No.", ResourceNoFilter);
        if DateFilter <> '' then begin
            TimeSheetHeader.SetFilter("Starting Date", DateFilter);
            TimeSheetHeader.SetFilter("Starting Date", '..%1', TimeSheetHeader.GetRangeMax("Starting Date"));
            TimeSheetHeader.SetFilter("Ending Date", DateFilter);
            TimeSheetHeader.SetFilter("Ending Date", '%1..', TimeSheetHeader.GetRangeMin("Ending Date"));
        end;

        if TimeSheetHeader.FindSet() then
            repeat
                TimeSheetLine.SetRange("Time Sheet No.", TimeSheetHeader."No.");
                TimeSheetLine.SetRange(Type, TimeSheetLine.Type::Job);
                TimeSheetLine.SetRange(Status, TimeSheetLine.Status::Approved);
                if JobNoFilter <> '' then
                    TimeSheetLine.SetFilter("Job No.", JobNoFilter);
                if JobTaskNoFilter <> '' then
                    TimeSheetLine.SetFilter("Job Task No.", JobTaskNoFilter);
                TimeSheetLine.SetRange(Posted, false);
                if TimeSheetLine.FindSet() then
                    repeat
                        TempTimeSheetLine := TimeSheetLine;
                        OnBeforeInsertTempTimeSheetLine(JobJnlLine, TimeSheetHeader, TempTimeSheetLine, SkipLine);
                        if not SkipLine then
                            TempTimeSheetLine.Insert();
                    until TimeSheetLine.Next() = 0;
            until TimeSheetHeader.Next() = 0;
    end;

    local procedure SetJobJournalLineDescription(TimeSheetDescription: Text[100]; TimeSheetDetail: Record "Time Sheet Detail")
    var
        ResourcesSetup: Record "Resources Setup";
        IsHandled: Boolean;
        TimeSheetDescriptionWithDateTok: Label '%1, %2', Locked = true;
    begin
        OnBeforeSetJobJournalLineDescription(JobJnlLine, TimeSheetDescription, TimeSheetDetail, IsHandled);
        if IsHandled then
            exit;

        ResourcesSetup.ReadIsolation(IsolationLevel::ReadCommitted);
        ResourcesSetup.SetLoadFields("Incl. Time Sheet Date in Jnl.");
        ResourcesSetup.Get();

        if ResourcesSetup."Incl. Time Sheet Date in Jnl." then
            JobJnlLine.Description := CopyStr(StrSubstNo(TimeSheetDescriptionWithDateTok, TimeSheetDetail.Date, TimeSheetDescription), 1, MaxStrLen(JobJnlLine.Description))
        else
            JobJnlLine.Description := CopyStr(TimeSheetDescription, 1, MaxStrLen(JobJnlLine.Description));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTempTimeSheetLine(JobJournalLine: Record "Job Journal Line"; TimeSheetHeader: Record "Time Sheet Header"; var TempTimeSheetLine: Record "Time Sheet Line" temporary; var SkipLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferTimeSheetDetailToJobJnlLine(var JobJournalLine: Record "Job Journal Line"; JobJournalTemplate: Record "Job Journal Template"; var TempTimeSheetLine: Record "Time Sheet Line" temporary; TimeSheetDetail: Record "Time Sheet Detail"; JobJournalBatch: Record "Job Journal Batch"; var LineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOnPostReportOnTempTimeSheetLineEndLoop(var JobJournalLine: Record "Job Journal Line"; var NextDocNo: Code[20]; var LineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetJobJournalLineDescription(var JobJournalLine: Record "Job Journal Line"; TimeSheetDescription: Text[100]; TimeSheetDetail: Record "Time Sheet Detail"; var IsHandled: Boolean)
    begin
    end;
}

