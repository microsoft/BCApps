namespace System.Threading;

using System.IO;

codeunit 448 "Job Queue Dispatcher"
{
    InherentPermissions = X;

    Permissions = TableData "Job Queue Entry" = rimd,
                  TableData "Job Queue Category" = rm;
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        Skip: Boolean;
    begin
        OnBeforeRun(Rec, Skip);
        if Skip then begin
            JobQueueTelemetry.SendJobQueueSkippedTelemetry(Rec);
            exit;
        end;

        if Rec.Status = Rec.Status::"In Process" then
            RunCleanupForCurrentJob(Rec);

        if not Rec.IsReadyToStart() then begin
            JobQueueTelemetry.SendJobQueueNotReadyToStartTelemetry(Rec);
            exit;
        end;

        Rec.RefreshLocked();

        if Rec.IsExpired(CurrentDateTime) then begin
            JobQueueTelemetry.SendJobQueueExpiredTelemetry(Rec);
            Rec.DeleteTask();
        end
        else
            if not IsWithinStartEndTime(Rec) then begin
                Reschedule(Rec);
                JobQueueTelemetry.SendJobQueueRescheduledDueToStartEndTimeTelemetry(Rec);
            end
            else
                if WaitForOthersWithSameCategory(Rec) then begin
                    RescheduleAsWaiting(Rec);
                    JobQueueTelemetry.SendJobQueueRescheduleAsWaitingTelemetry(Rec);
                end
                else begin
                    HandleRequest(Rec);
                    if Rec."Job Queue Category Code" <> '' then begin
                        Commit();
                        Rec.ActivateNextJobInCategoryIfAny();
                    end;
                end;
        Commit();
        CleanupCurrentUsersJobsWithSameCategory(Rec);
        CleanupStaleJobs();
    end;

    var
        JobQueueTelemetry: Codeunit "Job Queue Telemetry";
        TestMode: Boolean;
        JobQueueEntryFailedtoGetBeforeFinalizingTxt: Label 'Failed to get Job Queue Entry before finalizing record.', Locked = true;
        JobQueueEntryFailedtoGetBeforeUpdatingStatusTxt: Label 'Failed to get Job Queue Entry before updating status.', Locked = true;
        JobQueueEntriesCategoryTxt: Label 'AL JobQueueEntries', Locked = true;

    /// <summary>
    /// This is used to run the cleanup tasks for the current job queue entry when the job queue fails but is retriable.
    /// The prior Job Queue Log Entry would still be in the "In Process" state.
    /// </summary>
    /// <param name="JobQueueEntry">The Job Queue Entry that is running.</param>
    local procedure RunCleanupForCurrentJob(var JobQueueEntry: Record "Job Queue Entry")
    begin
        TaskScheduler.CreateTask(Codeunit::"Job Queue Cleanup Tasks", 0, true, CompanyName(), CurrentDateTime(), JobQueueEntry.RecordId);
    end;

    local procedure HandleRequest(var JobQueueEntry: Record "Job Queue Entry")
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
        PrevStatus: Option;
        JobQueueStartTime: DateTime;
        JobQueueExecutionTimeInMs: Integer;
    begin
        OnBeforeHandleRequest(JobQueueEntry);

        // Always update the JQE because if the session dies and the task is rerun, it should have the latest information
        JobQueueEntry.Status := JobQueueEntry.Status::"In Process";
        JobQueueEntry."Error Message" := '';
        Clear(JobQueueEntry."Error Message Register Id");
        JobQueueEntry."User Session Started" := CurrentDateTime();
        JobQueueEntry."User Session ID" := SessionId();
        JobQueueEntry."User Service Instance ID" := ServiceInstanceId();
        JobQueueEntry.Modify();
        Commit();

        JobQueueEntry.InsertLogEntry(JobQueueLogEntry);
        // Codeunit.Run is limited during write transactions because one or more tables will be locked.
        // To avoid NavCSideException we have either to add the COMMIT before the call or do not use a returned value.
        Commit();
        OnBeforeExecuteJob(JobQueueEntry);

        JobQueueStartTime := CurrentDateTime();
        Codeunit.Run(Codeunit::"Job Queue Start Codeunit", JobQueueEntry);
        JobQueueExecutionTimeInMs := CurrentDateTime() - JobQueueStartTime;

        OnAfterSuccessExecuteJob(JobQueueEntry);
        PrevStatus := JobQueueEntry.Status;

        // user may have deleted it in the meantime
        if JobQueueEntry.DoesExistLocked() then
            JobQueueEntry.SetResult(PrevStatus)
        else begin
            SendTraceOnFailedtoGetRecordBeforeUpdatingStatus(JobQueueEntry);
            JobQueueEntry.SetResultDeletedEntry();
        end;
        Commit();

        JobQueueEntry.FinalizeLogEntry(JobQueueLogEntry);

        if JobQueueEntry.DoesExistLocked() then
            JobQueueEntry.FinalizeRun()
        else
            SendTraceOnFailedToGetRecordBeforeFinalizingRecord(JobQueueEntry);

        OnAfterSuccessHandleRequest(JobQueueEntry, JobQueueExecutionTimeInMs, JobQueueLogEntry."System Task Id");
    end;

    /// <summary>
    /// Checks if the current time is within the start and end time of the job queue entry.
    /// </summary>
    /// <param name="CurrJobQueueEntry">The Job Queue Entry to check.</param>
    /// <returns>True if the current time is within the start and end time, otherwise false.</returns>
    procedure IsWithinStartEndTime(var CurrJobQueueEntry: Record "Job Queue Entry"): Boolean
    var
        CurrTime: Time;
    begin
        // No start and end time set, always run
        if (CurrJobQueueEntry."Starting Time" = 0T) and (CurrJobQueueEntry."Ending Time" = 0T) then
            exit(true);

        CurrTime := DT2Time(CurrentDateTime);

        // Starting time > Ending time -> roll-over midnight, e.g. from 23:00 - 02:00
        if (CurrJobQueueEntry."Ending Time" <> 0T) and (CurrJobQueueEntry."Starting Time" > CurrJobQueueEntry."Ending Time") then
            exit((CurrTime >= CurrJobQueueEntry."Starting Time") or (CurrTime <= CurrJobQueueEntry."Ending Time"));

        // Start and end time set, check if current time is within the range
        if (CurrJobQueueEntry."Starting Time" <> 0T) and (CurrJobQueueEntry."Ending Time" <> 0T) then
            if CurrJobQueueEntry."Starting Time" <> CurrJobQueueEntry."Ending Time" then
                exit((CurrJobQueueEntry."Starting Time" <= CurrTime) and (CurrTime <= CurrJobQueueEntry."Ending Time"));

        // If start and end time are the same, treat it as only starting time is set.
        // Only start time set, check if current time is after start time
        if (CurrJobQueueEntry."Starting Time" <> 0T) then
            exit(CurrJobQueueEntry."Starting Time" <= CurrTime);

        // Only end time set, check if current time is before end time
        if (CurrJobQueueEntry."Ending Time" <> 0T) then
            exit(CurrTime <= CurrJobQueueEntry."Ending Time");
    end;

    procedure WaitForOthersWithSameCategory(var CurrJobQueueEntry: Record "Job Queue Entry") Result: Boolean
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueCategory: Record "Job Queue Category";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeWaitForOthersWithSameCategory(CurrJobQueueEntry, JobQueueEntry, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if CurrJobQueueEntry."Job Queue Category Code" = '' then
            exit(false);

        // Use the Job Queue Category as a semaphore so only one checks at the time.
        JobQueueCategory.ReadIsolation(IsolationLevel::UpdLock);
        if not JobQueueCategory.Get(CurrJobQueueEntry."Job Queue Category Code") then
            exit(false);

        SelectLatestVersion();  // bypasses the cache on the NST
        JobQueueEntry.ReadIsolation(JobQueueEntry.ReadIsolation::ReadCommitted);
        JobQueueEntry.SetFilter(ID, '<>%1', CurrJobQueueEntry.ID);
        JobQueueEntry.SetRange("Job Queue Category Code", CurrJobQueueEntry."Job Queue Category Code");
        JobQueueEntry.SetRange(Status, JobQueueEntry.Status::"In Process");
        JobQueueEntry.SetRange(Scheduled, true);
        JobQueueEntry.SetCurrentKey("Job Queue Category Code", "Priority Within Category", "Entry No.");
        if not JobQueueEntry.IsEmpty() then
            exit(true);

        if TestMode then begin
            JobQueueEntry.SetRange(Scheduled, false);
            if not JobQueueEntry.IsEmpty() then
                exit(true);
        end;
        exit(false);
    end;

    local procedure CleanupCurrentUsersJobsWithSameCategory(var CurrJobQueueEntry: Record "Job Queue Entry")
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueEntryCheck: Record "Job Queue Entry";
    begin
        if CurrJobQueueEntry."Job Queue Category Code" = '' then
            exit;
        SelectLatestVersion();  // bypasses the cache on the NST
        JobQueueEntry.SetLoadFields(ID);
        JobQueueEntry.ReadIsolation(JobQueueEntry.ReadIsolation::ReadUnCommitted);
        JobQueueEntry.SetFilter(ID, '<>%1', CurrJobQueueEntry.ID);
        JobQueueEntry.SetRange("Job Queue Category Code", CurrJobQueueEntry."Job Queue Category Code");
        JobQueueEntry.SetRange(Status, JobQueueEntry.Status::"In Process");
        JobQueueEntry.SetRange(Scheduled, false);
        JobQueueEntry.SetRange("User ID", UserId());
        JobQueueEntryCheck.ReadIsolation(IsolationLevel::UpdLock);
        JobQueueEntryCheck.SetAutoCalcFields(Scheduled);
        if JobQueueEntry.FindSet() then
            repeat
                if JobQueueEntryCheck.Get(JobQueueEntry.ID) then
                    if not JobQueueEntryCheck.Scheduled then
                        if JobQueueEntryCheck.IsExpired(CurrentDateTime) then
                            JobQueueEntryCheck.DeleteTask()
                        else
                            Reschedule(JobQueueEntryCheck);
            until JobQueueEntry.Next() = 0;
    end;

    local procedure CleanupStaleJobs()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobDescrLbl: Label 'Clean up failed jobs';
    begin
        JobQueueEntry.ReadIsolation(IsolationLevel::ReadUncommitted);
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Job Queue Cleanup Tasks");
        JobQueueEntry.SetAutoCalcFields(Scheduled);
        if not JobQueueEntry.FindFirst() then begin
            JobQueueEntry.Reset();
            JobQueueEntry.ReadIsolation(IsolationLevel::UpdLock);
            if JobQueueEntry.FindLast() then; // semaphore lock to avoid creating several jobs
            JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
            JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Job Queue Cleanup Tasks");
            if JobQueueEntry.FindFirst() then
                exit;
            Clear(JobQueueEntry);
            JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
            JobQueueEntry."Object ID to Run" := Codeunit::"Job Queue Cleanup Tasks";
            JobQueueEntry.Description := CopyStr(JobDescrLbl, 1, MaxStrLen(JobQueueEntry.Description));
            JobQueueEntry.Validate("Run on Mondays", true);
            JobQueueEntry.Validate("Run on Tuesdays", true);
            JobQueueEntry.Validate("Run on Wednesdays", true);
            JobQueueEntry.Validate("Run on Thursdays", true);
            JobQueueEntry.Validate("Run on Fridays", true);
            JobQueueEntry.Validate("Run on Saturdays", true);
            JobQueueEntry.Validate("Run on Sundays", true);
            JobQueueEntry.Validate("Starting Time", DT2Time(CurrentDateTime())); // to spread the load for all tenants
            JobQueueEntry."Earliest Start Date/Time" := CalcInitialRunTime(JobQueueEntry, CurrentDateTime());
            Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry);
        end else
            if not JobQueueEntry.Scheduled or (JobQueueEntry.Status = JobQueueEntry.Status::Error) then
                JobQueueEntry.Restart()
            else
                if (JobQueueEntry."Starting Time" = 0T) and (DT2Time(JobQueueEntry."Earliest Start Date/Time") = 000000T) then begin
                    JobQueueEntry.GetRecLockedExtendedTimeout();
                    JobQueueEntry.SetStatus(JobQueueEntry.Status::"On Hold");
                    JobQueueEntry.Validate("Starting Time", DT2Time(CurrentDateTime())); // to spread the load for all tenants
                    JobQueueEntry."Earliest Start Date/Time" := CalcInitialRunTime(JobQueueEntry, CurrentDateTime());
                    JobQueueEntry.Modify();
                    JobQueueEntry.SetStatus(JobQueueEntry.Status::Ready);
                end;
    end;

    [Scope('OnPrem')]
    procedure MockTaskScheduler()
    begin
        TestMode := true;
    end;

    local procedure Reschedule(var JobQueueEntry: Record "Job Queue Entry")
    begin
        Clear(JobQueueEntry."System Task ID"); // to avoid canceling this task, which has already been executed
        JobQueueEntry."Earliest Start Date/Time" := CalcInitialRunTime(JobQueueEntry, CurrentDateTime());
        OnRescheduleOnBeforeJobQueueEnqueue(JobQueueEntry);
        JobQueueEntry."System Task ID" := TASKSCHEDULER.CreateTask(CODEUNIT::"Job Queue Dispatcher", CODEUNIT::"Job Queue Error Handler", true, JobQueueEntry.CurrentCompany(), JobQueueEntry."Earliest Start Date/Time", JobQueueEntry.RecordId());
        JobQueueEntry.Status := JobQueueEntry.Status::Ready;
        JobQueueEntry.Modify();
    end;

    local procedure RescheduleAsWaiting(var JobQueueEntry: Record "Job Queue Entry")
    begin
        Clear(JobQueueEntry."System Task ID"); // to avoid canceling this task, which has already been executed
#if not CLEAN27
        OnRescheduleOnBeforeJobQueueEnqueue(JobQueueEntry);
#endif
        OnRescheduleOnBeforeJobQueueEnqueueAsWaiting(JobQueueEntry);
        JobQueueEntry."System Task ID" := TASKSCHEDULER.CreateTask(CODEUNIT::"Job Queue Dispatcher", CODEUNIT::"Job Queue Error Handler", false, JobQueueEntry.CurrentCompany(), JobQueueEntry."Earliest Start Date/Time", JobQueueEntry.RecordId());
        JobQueueEntry.Status := JobQueueEntry.Status::Waiting;
        JobQueueEntry.Modify();
    end;

    internal procedure ActivateNextJobInCategory(var JobQueueEntry: Record "Job Queue Entry")
    var
        JobQueueEntryToActivate: Record "Job Queue Entry";
    begin
        if JobQueueEntry."Job Queue Category Code" = '' then
            exit;
        JobQueueEntryToActivate.SetLoadFields(ID, "Job Queue Category Code", Status, "Entry No.", "Priority Within Category", "System Task ID");
        JobQueueEntryToActivate.ReadIsolation(IsolationLevel::ReadCommitted);
        JobQueueEntryToActivate.SetRange("Job Queue Category Code", JobQueueEntry."Job Queue Category Code");
        JobQueueEntryToActivate.SetRange(Status, JobQueueEntry.Status::Waiting);
        JobQueueEntryToActivate.SetFilter(ID, '<>%1', JobQueueEntry.ID);
        JobQueueEntryToActivate.SetCurrentKey("Job Queue Category Code", "Priority Within Category", "Entry No.");
        if JobQueueEntryToActivate.FindFirst() then
            if TaskScheduler.TaskExists(JobQueueEntryToActivate."System Task ID") then begin
                TaskScheduler.SetTaskReady(JobQueueEntryToActivate."System Task ID");
                JobQueueEntryToActivate.Status := JobQueueEntryToActivate.Status::Ready;
                JobQueueEntryToActivate.Modify();
            end;
    end;

    procedure CalcNextRunTimeForRecurringJob(var JobQueueEntry: Record "Job Queue Entry"; StartingDateTime: DateTime): DateTime
    var
        NewRunDateTime: DateTime;
        NewRunDate: Date;
        IsHandled: Boolean;
    begin
        if IsNextRecurringRunTimeCalculated(JobQueueEntry, StartingDateTime, NewRunDateTime) then
            exit(NewRunDateTime);

        if JobQueueEntry.IsNextRunDateFormulaSet() then begin
            NewRunDate := CalcDate(JobQueueEntry."Next Run Date Formula", DT2Date(StartingDateTime));
            exit(CreateDateTime(NewRunDate, JobQueueEntry."Starting Time"));
        end;

        if JobQueueEntry."No. of Minutes between Runs" > 0 then
            NewRunDateTime := AddMinutesToDateTime(StartingDateTime, JobQueueEntry."No. of Minutes between Runs")
        else begin
            if JobQueueEntry."Earliest Start Date/Time" <> 0DT then
                StartingDateTime := JobQueueEntry."Earliest Start Date/Time";
            NewRunDateTime := CreateDateTime(DT2Date(StartingDateTime) + 1, 0T);
        end;

        IsHandled := false;
        OnCalcNextRunTimeForRecurringJobOnAfterCalcNewRunDateTime(JobQueueEntry, NewRunDateTime, IsHandled, StartingDateTime);
        if IsHandled then
            exit(NewRunDateTime);

        exit(CalcRunTimeForRecurringJob(JobQueueEntry, NewRunDateTime));
    end;

    procedure CalcNextRunTimeHoldDuetoInactivityJob(var JobQueueEntry: Record "Job Queue Entry"; StartingDateTime: DateTime): DateTime
    var
        NewRunDateTime: DateTime;
    begin
        NewRunDateTime := AddMinutesToDateTime(StartingDateTime, JobQueueEntry."Inactivity Timeout Period");
        exit(CalcRunTimeForRecurringJob(JobQueueEntry, NewRunDateTime));
    end;

    procedure CalcNextReadyStateMoment(JobQueueEntry: Record "Job Queue Entry"): DateTime
    begin
        exit(AddMinutesToDateTime(JobQueueEntry."Last Ready State", JobQueueEntry."No. of Minutes between Runs"));
    end;

    procedure CalcInitialRunTime(var JobQueueEntry: Record "Job Queue Entry"; StartingDateTime: DateTime): DateTime
    var
        EarliestPossibleRunTime: DateTime;
        IsHandled: Boolean;
    begin
        if (JobQueueEntry."Earliest Start Date/Time" <> 0DT) and (JobQueueEntry."Earliest Start Date/Time" > StartingDateTime) then
            EarliestPossibleRunTime := JobQueueEntry."Earliest Start Date/Time"
        else
            EarliestPossibleRunTime := StartingDateTime;

        IsHandled := false;
        OnCalcInitialRunTimeOnAfterCalcEarliestPossibleRunTime(JobQueueEntry, EarliestPossibleRunTime, IsHandled);
        if IsHandled then
            exit(EarliestPossibleRunTime);

        if JobQueueEntry."Recurring Job" and not JobQueueEntry.IsNextRunDateFormulaSet() then
            exit(CalcRunTimeForRecurringJob(JobQueueEntry, EarliestPossibleRunTime));

        exit(EarliestPossibleRunTime);
    end;

    local procedure CalcRunTimeForRecurringJob(var JobQueueEntry: Record "Job Queue Entry"; StartingDateTime: DateTime) NewRunDateTime: DateTime
    var
        RunOnDate: array[7] of Boolean;
        StartingWeekDay: Integer;
        NoOfExtraDays: Integer;
        NoOfDays: Integer;
        Found: Boolean;
        RunCrossMidnight: Boolean;
        NewRunTime: Time;
    begin
        JobQueueEntry.TestField("Recurring Job");
        RunOnDate[1] := JobQueueEntry."Run on Mondays";
        RunOnDate[2] := JobQueueEntry."Run on Tuesdays";
        RunOnDate[3] := JobQueueEntry."Run on Wednesdays";
        RunOnDate[4] := JobQueueEntry."Run on Thursdays";
        RunOnDate[5] := JobQueueEntry."Run on Fridays";
        RunOnDate[6] := JobQueueEntry."Run on Saturdays";
        RunOnDate[7] := JobQueueEntry."Run on Sundays";
        OnCalcRunTimeForRecurringJobOnAfterInitDays(JobQueueEntry, StartingDateTime);
        NewRunDateTime := StartingDateTime;
        NewRunTime := DT2Time(NewRunDateTime);

        NoOfDays := 0;

        // Starting time > Ending time -> roll-over midnight, e.g. from 23:00 - 02:00?  now: 16:05
        RunCrossMidnight := (JobQueueEntry."Ending Time" <> 0T) and (JobQueueEntry."Starting Time" > JobQueueEntry."Ending Time");
        if RunCrossMidnight and (NewRunTime < JobQueueEntry."Starting Time") and (NewRunTime > JobQueueEntry."Ending Time") or
           not RunCrossMidnight and (JobQueueEntry."Ending Time" <> 0T) and (NewRunTime > JobQueueEntry."Ending Time")  // e.g. when 08:00 - 16:00
        then
            NewRunDateTime := JobQueueEntry.GetStartingDateTime(NewRunDateTime);

        if not RunCrossMidnight and (JobQueueEntry."Ending Time" <> 0T) and (NewRunTime > JobQueueEntry."Ending Time") then
            NoOfDays := NoOfDays + 1;

        StartingWeekDay := Date2DWY(DT2Date(StartingDateTime), 1);
        Found := RunOnDate[(StartingWeekDay - 1 + NoOfDays) mod 7 + 1];
        OnCalcRunTimeForRecurringJob(JobQueueEntry, RunOnDate, Found, StartingWeekDay, NoOfDays);
        NoOfExtraDays := 0;
        while not Found and (NoOfExtraDays < 7) do begin
            NoOfExtraDays := NoOfExtraDays + 1;
            NoOfDays := NoOfDays + 1;
            Found := RunOnDate[(StartingWeekDay - 1 + NoOfDays) mod 7 + 1];
        end;

        if not RunCrossMidnight and (JobQueueEntry."Starting Time" <> 0T) and (NewRunDateTime < JobQueueEntry.GetStartingDateTime(NewRunDateTime)) or
            RunCrossMidnight and (NewRunDateTime > JobQueueEntry.GetEndingDateTime(NewRunDateTime))
        then
            NewRunDateTime := JobQueueEntry.GetStartingDateTime(NewRunDateTime);

        if (NoOfDays > 0) and (NewRunDateTime > JobQueueEntry.GetStartingDateTime(NewRunDateTime)) then
            NewRunDateTime := JobQueueEntry.GetStartingDateTime(NewRunDateTime);

        if (JobQueueEntry."Starting Time" = 0T) and (NoOfExtraDays > 0) and (JobQueueEntry."No. of Minutes between Runs" <> 0) then
            NewRunDateTime := CreateDateTime(DT2Date(NewRunDateTime), 0T);

        if Found and (NoOfDays > 0) then
            NewRunDateTime := CreateDateTime(DT2Date(NewRunDateTime) + NoOfDays, DT2Time(NewRunDateTime));

        OnAfterCalcRunTimeForRecurringJob(JobQueueEntry, Found, StartingDateTime, NewRunDateTime);
    end;

    local procedure IsNextRecurringRunTimeCalculated(JobQueueEntry: Record "Job Queue Entry"; StartingDateTime: DateTime; var NewRunDateTime: DateTime) IsHandled: Boolean
    begin
        OnBeforeCalcNextRunTimeForRecurringJob(JobQueueEntry, StartingDateTime, NewRunDateTime, IsHandled);
    end;

    local procedure SendTraceOnFailedToGetRecordBeforeFinalizingRecord(JobQueueEntry: Record "Job Queue Entry")
    var
        TranslationHelper: Codeunit "Translation Helper";
        Dimensions: Dictionary of [Text, Text];
    begin
        TranslationHelper.SetGlobalLanguageToDefault();

        // Failed to get record but insert all last known information into custom dimensions
        Dimensions.Add('Category', JobQueueEntriesCategoryTxt);
        Dimensions.Add('JobQueueId', Format(JobQueueEntry.ID, 0, 4));
        Dimensions.Add('JobQueueObjectType', Format(JobQueueEntry."Object Type to Run"));
        Dimensions.Add('JobQueueObjectId', Format(JobQueueEntry."Object ID to Run"));
        Dimensions.Add('JobQueueStatus', Format(JobQueueEntry.Status));
        Dimensions.Add('JobQueueIsRecurring', Format(JobQueueEntry."Recurring Job"));
        Dimensions.Add('JobQueueEarliestStartDateTime', Format(JobQueueEntry."Earliest Start Date/Time"));
        Dimensions.Add('JobQueueCompanyName', JobQueueEntry.CurrentCompany());
        Dimensions.Add('JobQueueScheduledTaskId', Format(JobQueueEntry."System Task ID", 0, 4));

        Session.LogMessage('0000HAI', JobQueueEntryFailedtoGetBeforeFinalizingTxt, Verbosity::Warning, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::All, Dimensions);

        TranslationHelper.RestoreGlobalLanguage();
    end;

    local procedure SendTraceOnFailedtoGetRecordBeforeUpdatingStatus(JobQueueEntry: Record "Job Queue Entry")
    var
        TranslationHelper: Codeunit "Translation Helper";
        Dimensions: Dictionary of [Text, Text];
    begin
        TranslationHelper.SetGlobalLanguageToDefault();

        // Failed to get record but insert all last known information into custom dimensions
        Dimensions.Add('Category', JobQueueEntriesCategoryTxt);
        Dimensions.Add('JobQueueId', Format(JobQueueEntry.ID, 0, 4));
        Dimensions.Add('JobQueueObjectType', Format(JobQueueEntry."Object Type to Run"));
        Dimensions.Add('JobQueueObjectId', Format(JobQueueEntry."Object ID to Run"));
        Dimensions.Add('JobQueueStatus', Format(JobQueueEntry.Status));
        Dimensions.Add('JobQueueIsRecurring', Format(JobQueueEntry."Recurring Job"));
        Dimensions.Add('JobQueueEarliestStartDateTime', Format(JobQueueEntry."Earliest Start Date/Time"));
        Dimensions.Add('JobQueueCompanyName', JobQueueEntry.CurrentCompany());
        Dimensions.Add('JobQueueScheduledTaskId', Format(JobQueueEntry."System Task ID", 0, 4));

        Session.LogMessage('0000HAK', JobQueueEntryFailedtoGetBeforeUpdatingStatusTxt, Verbosity::Warning, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::All, Dimensions);

        TranslationHelper.RestoreGlobalLanguage();
    end;

    [Scope('OnPrem')]
    procedure AddMinutesToDateTime(SourceDateTime: DateTime; NoOfMinutes: Integer) NewDateTime: DateTime
    var
        MillisecondsToAdd: BigInteger;
    begin
        MillisecondsToAdd := NoOfMinutes;
        MillisecondsToAdd := MillisecondsToAdd * 60000;
        NewDateTime := SourceDateTime + MillisecondsToAdd;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcRunTimeForRecurringJob(var JobQueueEntry: Record "Job Queue Entry"; Found: Boolean; StartingDateTime: DateTime; var NewRunDateTime: DateTime)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcNextRunTimeForRecurringJob(JobQueueEntry: Record "Job Queue Entry"; StartingDateTime: DateTime; var NewRunDateTime: DateTime; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSuccessHandleRequest(var JobQueueEntry: Record "Job Queue Entry"; JobQueueExecutionTime: Integer; PreviousTaskId: Guid)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSuccessExecuteJob(var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandleRequest(var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExecuteJob(var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var JobQueueEntry: Record "Job Queue Entry"; var Skip: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWaitForOthersWithSameCategory(var CurrJobQueueEntry: Record "Job Queue Entry"; var JobQueueEntry: Record "Job Queue Entry"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcNextRunTimeForRecurringJobOnAfterCalcNewRunDateTime(var JobQueueEntry: Record "Job Queue Entry"; var NewRunDateTime: DateTime; var IsHandled: Boolean; StartingDateTime: DateTime)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcInitialRunTimeOnAfterCalcEarliestPossibleRunTime(var JobQueueEntry: Record "Job Queue Entry"; var EarliestPossibleRunTime: DateTime; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRescheduleOnBeforeJobQueueEnqueue(var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRescheduleOnBeforeJobQueueEnqueueAsWaiting(var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcRunTimeForRecurringJobOnAfterInitDays(var JobQueueEntry: Record "Job Queue Entry"; var StartingDateTime: DateTime)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcRunTimeForRecurringJob(var JobQueueEntry: Record "Job Queue Entry"; var RunOnDate: array[7] of Boolean; var Found: Boolean; var StartingWeekDay: Integer; var NoOfDays: Integer)
    begin
    end;
}

