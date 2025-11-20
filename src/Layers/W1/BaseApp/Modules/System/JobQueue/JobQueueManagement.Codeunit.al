namespace System.Threading;

using System.Utilities;
using System.Environment;
using System.Security.User;

codeunit 456 "Job Queue Management"
{
    var
        JobQueueTelemetry: Codeunit "Job Queue Telemetry";
        RunOnceQst: label 'This will create a temporary non-recurrent copy of this job and will run it once in the foreground.\Do you want to continue?';
        ExecuteBeginMsg: label 'Executing job queue entry...';
        ExecuteEndSuccessMsg: label 'Job finished executing.\Status: %1', Comment = '%1 is a status value, e.g. Success';
        ExecuteEndErrorMsg: label 'Job finished executing.\Status: %1\Error: %2', Comment = '%1 is a status value, e.g. Success, %2=Error message';
        JobSomethingWentWrongMsg: Label 'Something went wrong and the job has stopped. Likely causes are system updates or routine maintenance processes. To restart the job, set the status to Ready.';
        JobSomethingWentWrongMsgErr: Label 'Something went wrong and the job has stopped. Likely causes are system updates or routine maintenance processes. The job will automatically run again.';
        JobQueueStatusChangeTxt: Label 'The status for Job Queue Entry: %1 has changed.', Comment = '%1 is the Job Queue Entry Id', Locked = true;
        TelemetryStaleJobQueueEntryTxt: Label 'Updated Job Queue Entry status to error as it is stale. Please investigate associated Task Id for error.', Locked = true;
        TelemetryStaleJobQueueLogEntryTxt: Label 'Updated Job Queue Log Entry status to error as it is stale. Please investigate associated Task Id for error.', Locked = true;
        TelemetryStaleRetriableJobQueueLogEntryTxt: Label 'Updated Job Queue Log Entry status to error as it is was retriable by platform.', Locked = true;
        RunJobQueueOnceTxt: Label 'Running job queue once.', Locked = true;
        TooManyScheduledTasksLinkTxt: Label 'Learn more';
        TooManyScheduledTasksNotificationMsg: Label 'There are more than 100,000 scheduled tasks in the system. This can prevent Job Queues and tasks from running in a timely manner. Please contact your system administrator.';
        TooManyScheduledTasksNotificationGuidLbl: Label 'cedc5167-e04c-4127-b7dd-114d1749700a', Locked = true;

    trigger OnRun()
    begin
    end;

    internal procedure CheckUserInJobQueueAdminList(UserName: Text): Boolean
    var
        JobQueueAdminList: Record "Job Queue Notified Admin";
    begin
        exit(JobQueueAdminList.Get(UserName));
    end;

    procedure CreateJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry")
    var
        EarliestStartDateTime: DateTime;
        ReportOutputType: Enum "Job Queue Report Output Type";
        ObjectTypeToRun: Option;
        ObjectIdToRun: Integer;
        NoOfMinutesBetweenRuns: Integer;
        RecurringJob: Boolean;
    begin
        NoOfMinutesBetweenRuns := JobQueueEntry."No. of Minutes between Runs";
        EarliestStartDateTime := JobQueueEntry."Earliest Start Date/Time";
        ReportOutputType := JobQueueEntry."Report Output Type";
        ObjectTypeToRun := JobQueueEntry."Object Type to Run";
        ObjectIdToRun := JobQueueEntry."Object ID to Run";

        JobQueueEntry.SetRange("Object Type to Run", ObjectTypeToRun);
        JobQueueEntry.SetRange("Object ID to Run", ObjectIdToRun);
        if NoOfMinutesBetweenRuns <> 0 then
            RecurringJob := true
        else
            RecurringJob := false;
        JobQueueEntry.SetRange("Recurring Job", RecurringJob);
        if not JobQueueEntry.IsEmpty() then
            exit;

        JobQueueEntry.Init();
        JobQueueEntry.Validate("Object Type to Run", ObjectTypeToRun);
        JobQueueEntry.Validate("Object ID to Run", ObjectIdToRun);
        JobQueueEntry."Earliest Start Date/Time" := CurrentDateTime;
        if NoOfMinutesBetweenRuns <> 0 then begin
            JobQueueEntry.Validate("Run on Mondays", true);
            JobQueueEntry.Validate("Run on Tuesdays", true);
            JobQueueEntry.Validate("Run on Wednesdays", true);
            JobQueueEntry.Validate("Run on Thursdays", true);
            JobQueueEntry.Validate("Run on Fridays", true);
            JobQueueEntry.Validate("Run on Saturdays", true);
            JobQueueEntry.Validate("Run on Sundays", true);
            JobQueueEntry.Validate("Recurring Job", RecurringJob);
            JobQueueEntry."No. of Minutes between Runs" := NoOfMinutesBetweenRuns;
        end;
        JobQueueEntry."Maximum No. of Attempts to Run" := 3;
        JobQueueEntry."Notify On Success" := true;
        JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
        JobQueueEntry."Earliest Start Date/Time" := EarliestStartDateTime;
        JobQueueEntry."Report Output Type" := ReportOutputType;
        JobQueueEntry.Insert(true);
    end;

    procedure DeleteJobQueueEntries(ObjectTypeToDelete: Option; ObjectIdToDelete: Integer)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", ObjectTypeToDelete);
        JobQueueEntry.SetRange("Object ID to Run", ObjectIdToDelete);
        if JobQueueEntry.FindSet() then
            repeat
                if JobQueueEntry.Status = JobQueueEntry.Status::"In Process" then begin
                    // Non-recurring jobs will be auto-deleted after execution has completed.
                    JobQueueEntry."Recurring Job" := false;
                    JobQueueEntry.Modify();
                end else
                    JobQueueEntry.Delete();
            until JobQueueEntry.Next() = 0;
    end;

    procedure StartInactiveJobQueueEntries(ObjectTypeToStart: Option; ObjectIdToStart: Integer)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", ObjectTypeToStart);
        JobQueueEntry.SetRange("Object ID to Run", ObjectIdToStart);
        JobQueueEntry.SetRange(Status, JobQueueEntry.Status::"On Hold");
        if JobQueueEntry.FindSet() then
            repeat
                JobQueueEntry.SetStatus(JobQueueEntry.Status::Ready);
            until JobQueueEntry.Next() = 0;
    end;

    procedure SetJobQueueEntriesOnHold(ObjectTypeToSetOnHold: Option; ObjectIdToSetOnHold: Integer)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", ObjectTypeToSetOnHold);
        JobQueueEntry.SetRange("Object ID to Run", ObjectIdToSetOnHold);
        if JobQueueEntry.FindSet() then
            repeat
                JobQueueEntry.SetStatus(JobQueueEntry.Status::"On Hold");
            until JobQueueEntry.Next() = 0;
    end;

    procedure SetRecurringJobsOnHold(CompanyName: Text)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.ChangeCompany(CompanyName);
        JobQueueEntry.SetRange("Recurring Job", true);
        JobQueueEntry.SetRange(Status, JobQueueEntry.Status::Ready);
        if JobQueueEntry.FindSet(true) then
            repeat
                JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
                JobQueueEntry.Modify();
            until JobQueueEntry.Next() = 0;
    end;

    procedure SetStatusToOnHoldIfInstanceInactiveFor(PeriodType: Option Day,Week,Month,Quarter,Year; NoOfPeriods: Integer; ObjectTypeToSetOnHold: Option; ObjectIdToSetOnHold: Integer): Boolean
    var
        UserLoginTimeTracker: Codeunit "User Login Time Tracker";
        PeriodFirstLetter: Text;
        FromDate: Date;
    begin
        PeriodFirstLetter := CopyStr(Format(PeriodType, 0, 0), 1, 1);
        FromDate := CalcDate(StrSubstNo('<-%1%2>', NoOfPeriods, PeriodFirstLetter));

        if not UserLoginTimeTracker.AnyUserLoggedInSinceDate(FromDate) then begin
            SetJobQueueEntriesOnHold(ObjectTypeToSetOnHold, ObjectIdToSetOnHold);
            exit(true);
        end;

        exit(false);
    end;

    procedure RunJobQueueEntryOnce(var SelectedJobQueueEntry: Record "Job Queue Entry")
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        SuccessDispatcher: Boolean;
        SuccessErrorHandler: Boolean;
        Window: Dialog;
        CurrentLanguage: Integer;
        Dimensions: Dictionary of [Text, Text];
    begin
        if not Confirm(RunOnceQst, false) then
            exit;

        Window.Open(ExecuteBeginMsg);
        SelectedJobQueueEntry.CalcFields(XML);
        JobQueueEntry := SelectedJobQueueEntry;
        JobQueueEntry.ID := CreateGuid();
        JobQueueEntry."User ID" := copystr(UserId(), 1, MaxStrLen(JobQueueEntry."User ID"));
        JobQueueEntry."Recurring Job" := false;
        JobQueueEntry.Status := JobQueueEntry.Status::"Ready";
        JobQueueEntry."Job Queue Category Code" := '';
        JobQueueEntry."Starting Time" := 0T;
        JobQueueEntry."Ending Time" := 0T;
        clear(JobQueueEntry."Expiration Date/Time");
        clear(JobQueueEntry."System Task ID");
        JobQueueEntry.Insert(true);
        OnRunJobQueueEntryOnceOnAfterJobQueueEntryInsert(SelectedJobQueueEntry, JobQueueEntry);
        Commit();

        CurrentLanguage := GlobalLanguage();
        GlobalLanguage(1033);

        JobQueueTelemetry.SetJobQueueTelemetryDimensions(JobQueueEntry, Dimensions);

        Session.LogMessage('0000FMG', RunJobQueueOnceTxt, Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::All, Dimensions);
        GlobalLanguage(CurrentLanguage);

        // Run the job queue
        SuccessDispatcher := Codeunit.run(Codeunit::"Job Queue Dispatcher", JobQueueEntry);

        // If JQ fails, run the error handler
        if not SuccessDispatcher then begin
            SuccessErrorHandler := Codeunit.run(Codeunit::"Job Queue Error Handler", JobQueueEntry);

            // If the error handler fails, save the error (Non-AL errors will automatically surface to end-user)
            // If it is unable to save the error (No permission etc), it should also just be surfaced to the end-user.
            if not SuccessErrorHandler then begin
                JobQueueEntry.SetError(GetLastErrorText());
                JobQueueEntry.InsertLogEntry(JobQueueLogEntry);
                JobQueueEntry.FinalizeLogEntry(JobQueueLogEntry, GetLastErrorCallStack());
                Commit();
            end;
        end;

        Window.Close();
        if JobQueueEntry.Find() then
            if JobQueueEntry.Delete() then;
        JobQueueLogEntry.SetRange(ID, JobQueueEntry.ID);
        if JobQueueLogEntry.FindFirst() then
            if JobQueueLogEntry.Status = JobQueueLogEntry.Status::Success then
                Message(ExecuteEndSuccessMsg, JobQueueLogEntry.Status)
            else
                Message(ExecuteEndErrorMsg, JobQueueLogEntry.Status, JobQueueLogEntry."Error Message");
    end;

    procedure CheckAndRefreshCategoryRecoveryTasks()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueCategory: Record "Job Queue Category";
        Categories: List of [Code[10]];
        Category: Code[10];
    begin
        if not JobQueueEntry.WritePermission() then
            exit;
        if not JobQueueCategory.WritePermission() then
            exit;

        JobQueueEntry.ReadIsolation(IsolationLevel::ReadUnCommitted);
        JobQueueEntry.SetFilter("Job Queue Category Code", '<>''''');
        JobQueueEntry.SetRange(Status, JobQueueEntry.Status::Waiting);
        JobQueueEntry.SetLoadFields("Job Queue Category Code");
        if not JobQueueEntry.FindSet() then
            exit;

        repeat
            if not Categories.Contains(JobQueueEntry."Job Queue Category Code") then
                Categories.Add(JobQueueEntry."Job Queue Category Code");
        until JobQueueEntry.Next() = 0;

        JobQueueCategory.ReadIsolation(IsolationLevel::ReadUncommitted);
        foreach Category in Categories do
            if JobQueueCategory.Get(Category) then
                if not IsNullGuid(JobQueueCategory."Recovery Task Id") then
                    if not TaskScheduler.TaskExists(JobQueueCategory."Recovery Task Id") then
                        JobQueueEntry.RefreshRecoveryTask(JobQueueCategory);
    end;

    /// <summary>
    /// To find stale jobs (in process jobs with no scheduled tasks) and set them to error state.
    /// For both JQE and JQLE
    /// </summary>
    [InherentPermissions(PermissionObjectType::TableData, Database::"Job Queue Entry", 'RM')]
    [InherentPermissions(PermissionObjectType::TableData, Database::"Job Queue Log Entry", 'RM')]
    procedure FindStaleJobsAndSetError()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobQueueLogEntry: Record "Job Queue Log Entry";
        JobQueueEntry2: Record "Job Queue Entry";
        JobQueueLogEntry2: Record "Job Queue Log Entry";
        DidSessionStart: Boolean;
        DidSessionStop: Boolean;
    begin
        // Find all in process job queue entries
        JobQueueEntry.ReadIsolation(IsolationLevel::ReadUnCommitted);
        JobQueueEntry.SetLoadFields(ID, "System Task ID", "User Service Instance ID", "User Session ID", Status, "User Session Started");
        JobQueueEntry.SetFilter(Status, '%1|%2', JobQueueEntry.Status::Ready, JobQueueEntry.Status::"In Process");
        JobQueueEntry.SetRange(Scheduled, false);
        JobQueueEntry.SetFilter(SystemModifiedAt, '<%1', CurrentDateTime() - GetCheckDelayInMilliseconds());  // Not modified in the last 10 minutes
        JobQueueEntry2.ReadIsolation(IsolationLevel::UpdLock);
        if JobQueueEntry.FindSet() then
            repeat
                // Check if job is still running or stale
                // JQE is stale if it has task no longer exists
                // If stale, set to error
                if not TaskScheduler.TaskExists(JobQueueEntry."System Task ID") then begin
                    DidSessionStart := SessionStarted(JobQueueEntry."User Service Instance ID", JobQueueEntry."User Session ID", JobQueueEntry."User Session Started");
                    if DidSessionStart then
                        DidSessionStop := SessionStopped(JobQueueEntry."User Service Instance ID", JobQueueEntry."User Session ID", JobQueueEntry."User Session Started");
                    if not DidSessionStart or DidSessionStart and DidSessionStop then begin
                        JobQueueEntry2.Get(JobQueueEntry.ID);
                        JobQueueEntry2.SetError(JobSomethingWentWrongMsg);
                        OnFindStaleJobsAndSetErrorOnAfterSetError(JobQueueEntry2);

                        StaleJobQueueEntryTelemetry(JobQueueEntry2);
                    end;
                end;
            until JobQueueEntry.Next() = 0;

        // Find all in process job queue log entries
        JobQueueLogEntry.ReadIsolation(IsolationLevel::ReadUnCommitted);
        JobQueueLogEntry.SetLoadFields("Entry No.", ID);
        JobQueueLogEntry.SetRange(Status, JobQueueLogEntry.Status::"In Process");
        JobQueueLogEntry.SetFilter(SystemModifiedAt, '<%1', CurrentDateTime() - GetCheckDelayInMilliseconds());  // Not modified in the last 10 minutes
        JobQueueLogEntry2.ReadIsolation(IsolationLevel::UpdLock);
        JobQueueEntry.SetAutoCalcFields(Scheduled);
        JobQueueEntry.SetLoadFields(ID, Status, Scheduled);
        if JobQueueLogEntry.FindSet() then
            repeat
                if not JobQueueEntry.Get(JobQueueLogEntry.ID) or (JobQueueEntry.Status = JobQueueEntry.Status::Error) or not JobQueueEntry.Scheduled then begin
                    JobQueueLogEntry2.Get(JobQueueLogEntry."Entry No.");
                    JobQueueLogEntry2.Status := JobQueueLogEntry2.Status::Error;
                    JobQueueLogEntry2."Error Message" := JobSomethingWentWrongMsg;
                    if JobQueueLogEntry2."End Date/Time" = 0DT then
                        JobQueueLogEntry2."End Date/Time" := JobQueueLogEntry2."Start Date/Time";
                    JobQueueLogEntry2.Modify();

                    StaleJobQueueLogEntryTelemetry(JobQueueLogEntry2);
                end;
            until JobQueueLogEntry.Next() = 0;
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Job Queue Log Entry", 'RM')]
    internal procedure UpdateRetriableFailedJobQueueLogEntry(var JobQueueEntry: Record "Job Queue Entry")
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        JobQueueLogEntry.SetRange(ID, JobQueueEntry.ID);
        JobQueueLogEntry.SetRange(Status, JobQueueLogEntry.Status::"In Process");
        JobQueueLogEntry.SetFilter("User Service Instance ID", '<>%1', JobQueueEntry."User Service Instance ID");
        JobQueueLogEntry.SetFilter("User Session ID", '<>%1', JobQueueEntry."User Session ID");

        if not JobQueueLogEntry.FindSet() then
            exit;

        repeat
            JobQueueLogEntry.Status := JobQueueLogEntry.Status::Error;
            JobQueueLogEntry."Error Message" := CopyStr(JobSomethingWentWrongMsgErr, 1, MaxStrLen(JobQueueLogEntry."Error Message"));
            JobQueueLogEntry.Modify();

            StaleRetriableJobQueueLogEntryTelemetry(JobQueueLogEntry);
        until JobQueueLogEntry.Next() = 0;
        Commit();
    end;

    local procedure GetCheckDelayInMilliseconds(): Integer
    var
        DelayInMinutes: Integer;
    begin
        DelayInMinutes := 10;
        OnGetCheckDelayInMinutes(DelayInMinutes);
        if DelayInMinutes < 0 then
            DelayInMinutes := 0;
        exit(1000 * 60 * DelayInMinutes); // 10 minutes
    end;

    local procedure SessionStarted(ServerInstanceID: Integer; SessionID: Integer; AfterDateTime: DateTime): Boolean
    var
        SessionEvent: Record "Session Event";
    begin
        exit(SessionExists(ServerInstanceID, SessionID, AfterDateTime, SessionEvent."Event Type"::Logon));
    end;

    local procedure SessionStopped(ServerInstanceID: Integer; SessionID: Integer; AfterDateTime: DateTime): Boolean
    var
        SessionEvent: Record "Session Event";
    begin
        exit(SessionExists(ServerInstanceID, SessionID, AfterDateTime, SessionEvent."Event Type"::Logoff));
    end;

    local procedure SessionExists(ServerInstanceID: Integer; SessionID: Integer; AfterDateTime: DateTime; EventType: Option): Boolean
    var
        SessionEvent: Record "Session Event";
    begin
        if AfterDateTime = 0DT then
            AfterDateTime := CurrentDateTime - 24 * 60 * 60 * 1000;     // 24hrs ago
        SessionEvent.SetRange("Server Instance ID", ServerInstanceID);
        SessionEvent.SetRange("Session ID", SessionID);
        SessionEvent.SetFilter("Event Datetime", '>%1', AfterDateTime - 600000);  // because session id's start from 1 after server restart
        SessionEvent.SetRange("Event Type", EventType);
        exit(not SessionEvent.IsEmpty());
    end;

    local procedure StaleJobQueueEntryTelemetry(JobQueueEntry: Record "Job Queue Entry")
    var
        CurrentLanguage: Integer;
        Dimensions: Dictionary of [Text, Text];
    begin
        CurrentLanguage := GlobalLanguage();
        GlobalLanguage(1033);

        JobQueueTelemetry.SetJobQueueTelemetryDimensions(JobQueueEntry, Dimensions);

        Session.LogMessage('0000FMH', TelemetryStaleJobQueueEntryTxt, Verbosity::Warning, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, Dimensions);

        GlobalLanguage(CurrentLanguage);
    end;

    local procedure StaleJobQueueLogEntryTelemetry(JobQueueLogEntry: Record "Job Queue Log Entry")
    var
        CurrentLanguage: Integer;
        Dimensions: Dictionary of [Text, Text];
    begin
        CurrentLanguage := GlobalLanguage();
        GlobalLanguage(1033);

        JobQueueTelemetry.SetJobQueueTelemetryDimensions(JobQueueLogEntry, Dimensions);

        Session.LogMessage('0000FMI', TelemetryStaleJobQueueLogEntryTxt, Verbosity::Warning, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, Dimensions);

        GlobalLanguage(CurrentLanguage);
    end;

    local procedure StaleRetriableJobQueueLogEntryTelemetry(JobQueueLogEntry: Record "Job Queue Log Entry")
    var
        CurrentLanguage: Integer;
        Dimensions: Dictionary of [Text, Text];
    begin
        CurrentLanguage := GlobalLanguage();
        GlobalLanguage(1033);

        JobQueueTelemetry.SetJobQueueTelemetryDimensions(JobQueueLogEntry, Dimensions);

        Session.LogMessage('0000PCR', TelemetryStaleRetriableJobQueueLogEntryTxt, Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, Dimensions);

        GlobalLanguage(CurrentLanguage);
    end;

    internal procedure TooManyScheduledTasksNotification()
    var
        ScheduledTaskNotification: Notification;
        NoOfScheduledTasks: Integer;
    begin
        NoOfScheduledTasks := GetNumberOfScheduledTasks();
        if NoOfScheduledTasks >= 100000 then begin
            ScheduledTaskNotification.Id := TooManyScheduledTasksNotificationGuidLbl;
            ScheduledTaskNotification.Message := TooManyScheduledTasksNotificationMsg;
            ScheduledTaskNotification.Scope := NOTIFICATIONSCOPE::LocalScope;
            ScheduledTaskNotification.AddAction(
              TooManyScheduledTasksLinkTxt, CODEUNIT::"Job Queue Management", 'TooManyScheduledTasksDocs');
            ScheduledTaskNotification.Send();
        end;
    end;

    internal procedure GetScheduledTasks(): Integer
    begin
        exit(GetNumberOfScheduledTasks())
    end;

    internal procedure GetScheduledTasksForUser(UserId: Guid): Integer
    begin
        exit(GetNumberOfScheduledTasksForUser(UserId))
    end;

    internal procedure TooManyScheduledTasksDocs(ScheduledTaskNotification: Notification)
    begin
        Hyperlink('https://aka.ms/JobQueueDocs');
    end;

    local procedure GetNumberOfScheduledTasksForUser(UserId: Guid): Integer
    var
        ScheduledTasks: Record "Scheduled Task";
    begin
        if ScheduledTasks.ReadPermission() then begin
            ScheduledTasks.SetRange("Is Ready", true);
            ScheduledTasks.SetRange("User ID", UserId);
            exit(ScheduledTasks.Count());
        end;

        exit(0);
    end;

    local procedure GetNumberOfScheduledTasks(): Integer
    var
        ScheduledTasks: Record "Scheduled Task";
    begin
        if ScheduledTasks.ReadPermission() then begin
            ScheduledTasks.SetRange("Is Ready", true);
            exit(ScheduledTasks.Count());
        end;

        exit(0);
    end;

    local procedure DeleteErrorMessageRegister(RegisterId: Guid)
    var
        ErrorMessageRegister: Record "Error Message Register";
    begin
        if IsNullGuid(RegisterId) then
            exit;

        ErrorMessageRegister.SetRange(ID, RegisterId);
        ErrorMessageRegister.DeleteAll(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'ScheduleReport', '', false, false)]
    local procedure ScheduleReport(ReportId: Integer; RequestPageXml: Text; var Scheduled: Boolean)
    var
        ScheduleAReport: Page "Schedule a Report";
    begin
        Scheduled := ScheduleAReport.ScheduleAReport(ReportId, RequestPageXml);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnStatusChanged(Rec: Record "Job Queue Entry"; xRec: Record "Job Queue Entry"; RunTrigger: Boolean)
    var
        CurrentLanguage: Integer;
        Dimensions: Dictionary of [Text, Text];
    begin
        if Rec.IsTemporary() then
            exit;

        if Rec.Status = xRec.Status then
            exit;

        CurrentLanguage := GlobalLanguage();
        GlobalLanguage(1033);

        JobQueueTelemetry.SetJobQueueTelemetryDimensions(Rec, Dimensions);
        Dimensions.Add('JobQueueOldStatus', Format(xRec.Status));

        Session.LogMessage('0000FNM', JobQueueStatusChangeTxt, Verbosity::Normal, DataClassification::OrganizationIdentifiableInformation, TelemetryScope::ExtensionPublisher, Dimensions);

        GlobalLanguage(CurrentLanguage);

        if Rec."Error Message Register Id" <> xRec."Error Message Register Id" then
            DeleteErrorMessageRegister(xRec."Error Message Register Id");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure OnBeforeDeleteJobQueueEntry(var Rec: Record "Job Queue Entry"; RunTrigger: Boolean)
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        if IsNullGuid(Rec."Error Message Register Id") then
            exit;

        JobQueueLogEntry.SetRange("Error Message Register Id", Rec."Error Message Register Id");
        if JobQueueLogEntry.IsEmpty() then
            DeleteErrorMessageRegister(Rec."Error Message Register Id");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Log Entry", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure OnBeforeDeleteJobQueueLogEntry(var Rec: Record "Job Queue Log Entry"; RunTrigger: Boolean)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if IsNullGuid(Rec."Error Message Register Id") then
            exit;

        JobQueueEntry.SetRange("Error Message Register Id", Rec."Error Message Register Id");
        if JobQueueEntry.IsEmpty() then
            DeleteErrorMessageRegister(Rec."Error Message Register Id");
    end;

    /// <Summary>Used for test. Sets the minimum age of stale job queue entries and job queue log entries.</Summary>
    /// <Parameters>DelayInMinutes defaults to 10 minutes but can be overridden to a longer or shorter time, including 0</Parameters>
    [IntegrationEvent(false, false)]
    local procedure OnGetCheckDelayInMinutes(var DelayInMinutes: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunJobQueueEntryOnceOnAfterJobQueueEntryInsert(SelectedJobQueueEntry: Record "Job Queue Entry"; JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindStaleJobsAndSetErrorOnAfterSetError(var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;
}

