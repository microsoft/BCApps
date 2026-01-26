// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocument;

using System.Telemetry;
using System.Threading;

codeunit 10751 "SII Job Management"
{

    trigger OnRun()
    begin
    end;

    var
        JobQueueManagement: Codeunit "Job Queue Management";
        JobQueueEntryStartedTxt: Label 'The job queue entry for detection of missing SII entries has started.';
        HandlePendingEntriesJobQueueEntryScheduledTxt: Label 'Job queue entry of type HandlePendingEntries has been scheduled.', Locked = true;
        SIIFeatureNameTok: Label 'SII', Locked = true;

    procedure RenewJobQueueEntry(JobType: Option HandlePending,HandleCommError,InitialUpload)
    var
        TempJobQueueEntry: Record "Job Queue Entry" temporary;
        SIISetup: Record "SII Setup";
    begin
        SIISetup.Get();
        if SIISetup."Do Not Schedule JQ Entry" then
            exit;
        if SIISetup."New Automatic Sending Exp." and (JobType = JobType::HandlePending) then begin
            SchedulePendingEntriesHandling();
            exit;
        end;
        if JobQueueEntryExists(JobType, TempJobQueueEntry) then begin
            if TempJobQueueEntry.Scheduled then
                exit;
            JobQueueManagement.DeleteJobQueueEntries(TempJobQueueEntry."Object Type to Run", TempJobQueueEntry."Object ID to Run");
        end;
        CreateJobQueueEntry(JobType);
    end;

    procedure TriggerNextHandlePendingJobQueueEntry()
    var
        SIISetup: Record "SII Setup";
        SIISendingState: Record "SII Sending State";
    begin
        SIISetup.Get();
        if not SIISetup."New Automatic Sending Exp." then
            exit;
        SIISendingState.InitRecord();
        if not SIISendingState."Schedule One More When Finish" then
            exit;
        SIISendingState.ResetSending();
        SchedulePendingEntriesHandling();
    end;

    local procedure JobQueueEntryExists(JobType: Option HandlePending,HandleCommError,InitialUpload; var TempJobQueueEntryFound: Record "Job Queue Entry" temporary): Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.ReadIsolation(IsolationLevel::UpdLock);
        JobQueueEntry.Reset();
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);

        case JobType of
            JobType::HandlePending:
                JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"SII Job Upload Pending Docs.");
            JobType::HandleCommError:
                JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"SII Job Retry Comm. Error");
            JobType::InitialUpload:
                JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"SII Initial Doc. Upload");
        end;

        if JobQueueEntry.FindFirst() then begin
            TempJobQueueEntryFound.Copy(JobQueueEntry);
            exit(true);
        end;

        exit(false);
    end;

    local procedure CreateJobQueueEntry(JobType: Option HandlePending,HandleCommError,InitialUpload): Guid
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry."Recurring Job" := false;
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;

        case JobType of
            JobType::HandlePending:
                JobQueueEntry."Object ID to Run" := CODEUNIT::"SII Job Upload Pending Docs.";
            JobType::HandleCommError:
                JobQueueEntry."Object ID to Run" := CODEUNIT::"SII Job Retry Comm. Error";
            JobType::InitialUpload:
                JobQueueEntry."Object ID to Run" := CODEUNIT::"SII Initial Doc. Upload";
        end;

        JobQueueEntry."Earliest Start Date/Time" := CurrentDateTime + PeriodInSeconds(JobType) * 1000;
        JobQueueEntry."Report Output Type" := JobQueueEntry."Report Output Type"::"None (Processing only)";
        JobQueueManagement.CreateJobQueueEntry(JobQueueEntry);
        JobQueueEntry.Validate("Notify On Success", false);
        JobQueueEntry.Modify(true);

        JobQueueManagement.StartInactiveJobQueueEntries(
          JobQueueEntry."Object Type to Run", JobQueueEntry."Object ID to Run");
        exit(JobQueueEntry.ID);
    end;

    local procedure PeriodInSeconds(JobType: Option HandlePending,HandleCommError,InitialUpload): Integer
    begin
        case JobType of
            JobType::HandlePending:
                exit(5);
            JobType::HandleCommError:
                exit(24 * 3600);
            JobType::InitialUpload:
                exit(5);
        end;
    end;

    procedure CreateAndStartJobQueueEntryForMissingEntryDetection(UpdateFrequency: Option Never,Daily,Weekly)
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueManagement: Codeunit "Job Queue Management";
        SIIRecreateMissingEntries: Codeunit "SII Recreate Missing Entries";
    begin
        if UpdateFrequency = UpdateFrequency::Never then
            exit;

        if JobQueueEntryForMissingEntryDetectionExists(JobQueueEntry) then
            exit;

        Clear(JobQueueEntry);
        JobQueueEntry."Earliest Start Date/Time" := CurrentDateTime + 1000;
        JobQueueEntry."No. of Minutes between Runs" := UpdateFrequencyToNoOfMinutes(UpdateFrequency);
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"SII Recreate Missing Entries";
        JobQueueEntry."Maximum No. of Attempts to Run" := 2;
        JobQueueEntry.Status := JobQueueEntry.Status::Ready;
        JobQueueEntry."Rerun Delay (sec.)" := 30;
        JobQueueManagement.CreateJobQueueEntry(JobQueueEntry);
        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
        SIIRecreateMissingEntries.SendTraceTagOn(JobQueueEntryStartedTxt);
    end;

    procedure DeleteJobQueueEntriesForMissingEntryDetection()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueManagement: Codeunit "Job Queue Management";
    begin
        JobQueueManagement.DeleteJobQueueEntries(JobQueueEntry."Object Type to Run"::Codeunit, CODEUNIT::"SII Recreate Missing Entries");
    end;

    procedure JobQueueEntryForMissingEntryDetectionExists(var JobQueueEntry: Record "Job Queue Entry"): Boolean
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"SII Recreate Missing Entries");
        exit(JobQueueEntry.FindFirst())
    end;

    procedure RestartJobQueueEntryForMissingEntryCheck(AutomaticMissingEntryCheck: Option)
    begin
        DeleteJobQueueEntriesForMissingEntryDetection();
        CreateAndStartJobQueueEntryForMissingEntryDetection(AutomaticMissingEntryCheck);
    end;

    local procedure UpdateFrequencyToNoOfMinutes(UpdateFrequency: Option Never,Daily,Weekly): Integer
    begin
        case UpdateFrequency of
            UpdateFrequency::Daily:
                exit(60 * 24);
            UpdateFrequency::Weekly:
                exit(60 * 24 * 7);
        end;
    end;

    local procedure SchedulePendingEntriesHandling()
    var
        SIISendingState: Record "SII Sending State";
        JobQueueEntry: Record "Job Queue Entry";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        Schedule: Boolean;
        JobType: Option HandlePending,HandleCommError,InitialUpload;
    begin
        SIISendingState.ReadIsolation(IsolationLevel::UpdLock);
        SIISendingState.InitRecord();
        if IsNullGuid(SIISendingState."Job Queue Entry ID") then
            Schedule := true
        else
            if not JobQueueEntry.Get(SIISendingState."Job Queue Entry ID") then
                Schedule := true
            else begin
                Schedule := JobQueueEntry.Status in [JobQueueEntry.Status::Error, JobQueueEntry.Status::Finished];
                if not Schedule then begin
                    SIISendingState.Validate("Schedule One More When Finish", true);
                    SIISendingState.Modify(true);
                end;
            end;
        if not Schedule then
            exit;
        SIISendingState.Validate("Job Queue Entry ID", CreateJobQueueEntry(JobType::HandlePending));
        SIISendingState.Validate("Schedule One More When Finish", false);
        SIISendingState.Modify(true);
        FeatureTelemetry.LogUsage('0000M83', SIIFeatureNameTok, HandlePendingEntriesJobQueueEntryScheduledTxt);
    end;
}

