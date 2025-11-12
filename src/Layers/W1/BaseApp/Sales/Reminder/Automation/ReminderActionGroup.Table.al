// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using System.Threading;

table 6751 "Reminder Action Group"
{
    DataClassification = CustomerContent;
    Caption = 'Reminder Automation Group';
    DrillDownPageId = "Reminder Automation List";
    LookupPageId = "Reminder Automation List";

    fields
    {
        field(1; Code; Code[50])
        {
        }
        field(2; Description; Text[100])
        {
        }
        field(3; Schedule; Enum "Reminder Action Schedule")
        {
        }
        field(4; "Start DateTime"; DateTime)
        {
        }
        field(6; "Next Run Date Formula"; DateFormula)
        {
        }
        field(7; Blocked; Boolean)
        {
        }
        field(12; "Reminder Terms"; Blob)
        {
        }
    }

    keys
    {
        key(Key1; Code)
        {
            Clustered = true;
        }
    }

    procedure GetReminderTermsSelectionFilter(): Text
    var
        SelectionFilterInStream: InStream;
        SelectionFilterText: Text;
    begin
        Clear(SelectionFilterText);
        CalcFields("Reminder Terms");
        Rec."Reminder Terms".CreateInStream(SelectionFilterInStream, TextEncoding::UTF16);
        if not Rec."Reminder Terms".HasValue() then
            exit;

        SelectionFilterInStream.ReadText(SelectionFilterText);
        exit(SelectionFilterText);
    end;

    procedure SetReminderTermsSelectionFilter(SelectionFilterText: Text)
    var
        SelectionFilterOutStream: OutStream;
    begin
        if SelectionFilterText = '' then begin
            Clear(Rec."Reminder Terms");
            Rec.Modify();
            exit;
        end;

        Clear(Rec."Reminder Terms");
        Rec."Reminder Terms".CreateOutStream(SelectionFilterOutStream, TextEncoding::UTF16);
        SelectionFilterOutStream.WriteText(SelectionFilterText);
        Rec.Modify();
    end;

    internal procedure GetNextRunDate(): DateTime
    var
        NextDate: Date;
    begin
        case Rec.Schedule of
            Rec.Schedule::Manual:
                exit(0DT);
            Rec.Schedule::Monthly:
                begin
                    NextDate := CalcDate('<+1M>', DT2Date(Rec."Start DateTime"));
                    exit(CreateDateTime(NextDate, DT2Time(Rec."Start DateTime")));
                end;
            Rec.Schedule::Weekly:
                begin
                    NextDate := CalcDate('<+1W>', DT2Date(Rec."Start DateTime"));
                    exit(CreateDateTime(NextDate, DT2Time(Rec."Start DateTime")));
                end;
            Rec.Schedule::"Custom schedule":
                begin
                    NextDate := CalcDate(Rec."Next Run Date Formula", DT2Date(Rec."Start DateTime"));
                    exit(CreateDateTime(NextDate, DT2Time(Rec."Start DateTime")));
                end;
        end;

        exit(0DT);
    end;

    internal procedure GetLastRunStatusText(): Text
    var
        ReminderActionGroupLog: Record "Reminder Action Group Log";
        ReminderActionProgress: Codeunit "Reminder Action Progress";
    begin
        if not ReminderActionProgress.GetLastEntryForGroup(Rec.Code, ReminderActionGroupLog) then
            exit('');

        exit(StrSubstNo(ReminderActionStatusLbl, ReminderActionGroupLog.Status, Format(ReminderActionGroupLog.SystemCreatedAt)));
    end;

    internal procedure VerifyDefinition()
    var
        ReminderAction: Record "Reminder Action";
        ReminderActionInterface: Interface "Reminder Action";
    begin
        ReminderAction.SetRange("Reminder Action Group Code", Rec.Code);
        if not ReminderAction.FindSet() then
            Error(NoReminderActionsAreDefinedErr);

        if GetReminderTermsSelectionFilter() = '' then
            Error(NoReminderTermsAreDefinedErr);

        repeat
            ReminderActionInterface := ReminderAction.GetReminderActionInterface();
            ReminderActionInterface.Initialize(ReminderAction.SystemId);
            ReminderActionInterface.ValidateSetup();
        until ReminderAction.Next() = 0;
    end;

    internal procedure ShowHistory()
    var
        ReminderActionGroupLog: Record "Reminder Action Group Log";
    begin
        ReminderActionGroupLog.SetCurrentKey("Run Id");
        ReminderActionGroupLog.Ascending(false);
        ReminderActionGroupLog.SetRange("Reminder Action Group ID", Rec.Code);
        Page.Run(Page::"Reminder Action History", ReminderActionGroupLog);
    end;

    procedure ScheduleAutomationJob(var ReminderActionGroup: Record "Reminder Action Group")
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        CreateUniqueJobQueue(ReminderActionGroup, JobQueueEntry);
        JobQueueEntry.SetStatus(JobQueueEntry.Status::Ready);
    end;

    procedure CreateUniqueJobQueue(var ReminderActionGroup: Record "Reminder Action Group"; var JobQueueEntry: Record "Job Queue Entry")
    var
        JobQueueExist: Boolean;
    begin
        JobQueueExist := GetJobQueueEntry(JobQueueEntry);
        if JobQueueExist then
            if JobQueueEntry.Status = JobQueueEntry.Status::"In Process" then
                Error(JobQueueIsRunningErr);

        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"Reminders Automation Job";
        JobQueueEntry."Rerun Delay (sec.)" := 1;
        JobQueueEntry."Maximum No. of Attempts to Run" := 3;
        JobQueueEntry."Recurring Job" := true;
        if ReminderActionGroup.Schedule = ReminderActionGroup.Schedule::Manual then
            JobQueueEntry."Recurring Job" := false;

        JobQueueEntry."Record ID to Process" := ReminderActionGroup.RecordId;
        JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
        JobQueueEntry."Job Queue Category Code" := JobQueueCategoryCodeTxt;
        JobQueueEntry."Earliest Start Date/Time" := Rec.GetNextRunDate();
        Clear(JobQueueEntry."Error Message");
        Clear(JobQueueEntry."Error Message Register Id");
        JobQueueEntry.Description := CopyStr(StrSubstNo(JobQueueEntryDescTxt, ReminderActionGroup.Code), 1, MaxStrLen(JobQueueEntry.Description));
        if JobQueueExist then
            JobQueueEntry.Modify(true)
        else
            JobQueueEntry.Insert(true);
    end;

    internal procedure GetJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry"): Boolean
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Reminders Automation Job");
        JobQueueEntry.SetRange("Record ID to Process", Rec.RecordId);
        exit(JobQueueEntry.FindFirst());
    end;

    internal procedure GetStatus(var StatusMessage: Text; var ErrorText: Text)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if Rec.Blocked then begin
            StatusMessage := BlockedManuallyTxt;
            exit;
        end;

        if GetJobQueueEntry(JobQueueEntry) then
            case JobQueueEntry.Status of
                JobQueueEntry.Status::Error:
                    begin
                        StatusMessage := ErrorTok;
                        ErrorText := JobQueueEntry."Error Message";
                    end;
                JobQueueEntry.Status::"On Hold":
                    StatusMessage := OnHoldTxt;
                JobQueueEntry.Status::Ready:
                    if Rec.Schedule = Rec.Schedule::Manual then
                        StatusMessage := StrSubstNo(ScheduledTxt, SingleRunTxt)
                    else
                        StatusMessage := StrSubstNo(ScheduledTxt, LowerCase(Format(Rec.Schedule)));
                JobQueueEntry.Status::"In Process":
                    StatusMessage := RunningTok;
            end
        else
            StatusMessage := OnHoldTxt;
    end;

    internal procedure InProgress(): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if not GetJobQueueEntry(JobQueueEntry) then
            exit(false);

        exit(JobQueueEntry.Status = JobQueueEntry.Status::"In Process");
    end;

    internal procedure GetNextStartDate(): Text
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if not Rec.GetJobQueueEntry(JobQueueEntry) then
            exit('');

        if JobQueueEntry.Status in [JobQueueEntry.Status::Ready, JobQueueEntry.Status::"In Process"] then
            exit(Format(JobQueueEntry."Earliest Start Date/Time"));

        exit('');
    end;

    internal procedure PauseJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if not Rec.GetJobQueueEntry(JobQueueEntry) then
            exit;

        if JobQueueEntry.Status = JobQueueEntry.Status::"In Process" then
            Error(JobQueueIsRunningErr);

        JobQueueEntry.SetStatus(JobQueueEntry.Status::"On Hold");
    end;

    internal procedure GetNumberOfActiveErrors(): Integer
    var
        ReminderAutomationError: Record "Reminder Automation Error";
    begin
        GetActiveErrors(ReminderAutomationError);
        exit(ReminderAutomationError.Count());
    end;

    internal procedure GetActiveErrors(var ReminderAutomationError: Record "Reminder Automation Error")
    begin
        ReminderAutomationError.SetRange("Reminder Action Group Code", Rec.Code);
        ReminderAutomationError.SetRange(Dismissed, false);
    end;

    internal procedure GetFeatureTelemetryName(): Text
    begin
        exit('Reminder Automation');
    end;

    trigger OnDelete()
    var
        ReminderAction: Record "Reminder Action";
    begin
        ReminderAction.SetRange("Reminder Action Group Code", Rec.Code);
        ReminderAction.DeleteAll(true);
    end;

    var
        OnHoldTxt: Label 'On Hold';
        ErrorTok: Label 'Error';
        JobQueueIsRunningErr: Label 'Job queue entry is running';
        ScheduledTxt: Label 'Scheduled %1', Comment = '%1 - is a text that can be (single run) or (weekly, monthly, custom)';
        SingleRunTxt: Label 'single run';
        RunningTok: Label 'Running';
        BlockedManuallyTxt: Label 'Blocked manually';
        JobQueueCategoryCodeTxt: Label 'REMINDERS', Comment = 'Job Queue Category Code for Reminder Automation, abreviated to 10 characters', MaxLength = 10;
        JobQueueEntryDescTxt: Label 'Reminder Automation - %1.', Comment = '%1 - Code of the Reminder Action Group';
        ReminderActionStatusLbl: Label 'Status: %1. Completed on: %2', Comment = '%1 - Status, succeded, failed etc... %2 - When it was completed';
        NoReminderActionsAreDefinedErr: Label 'No actions are defined for this reminder action group.';
        NoReminderTermsAreDefinedErr: Label 'No reminder terms are selected for this reminder action group. Please select reminder terms under Reminder Terms Filter.';
}