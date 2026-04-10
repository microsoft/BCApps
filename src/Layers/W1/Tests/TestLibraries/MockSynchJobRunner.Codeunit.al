codeunit 131032 "Mock Synch. Job Runner"
{
    // it is a mock of COD5339 to be called by COD449 and simulate different values of inactivity flag:
    // the flag to be set by SetJobWasActive() and
    // passed back to COD449 via [EventSubscriber] OnAfterRunJobQueueStartCodeunit()

    EventSubscriberInstance = Manual;
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
    end;

    var
        JobWasActive: Boolean;
        JobDescriptionToBeRun: Text;

    procedure SetJobWasActive()
    begin
        JobWasActive := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue Start Codeunit", 'OnAfterRun', '', false, false)]
    procedure OnAfterRunJobQueueStartCodeunit(var JobQueueEntry: Record "Job Queue Entry")
    begin
        if not JobWasActive then
            if JobQueueEntry."Recurring Job" then
                JobQueueEntry.Status := JobQueueEntry.Status::"On Hold with Inactivity Timeout"
            else
                JobQueueEntry.Status := JobQueueEntry.Status::"On Hold";
        VerifyJobLogEntryIsInProcess(JobQueueEntry.GetLastLogEntryNo());
    end;

    local procedure VerifyJobLogEntryIsInProcess(LogEntryNo: Integer)
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
    begin
        // Job Queue Log Entry should be inserted before job execution
        JobQueueLogEntry.Get(LogEntryNo);
        JobQueueLogEntry.TestField("Start Date/Time");
        JobQueueLogEntry.TestField("End Date/Time", 0DT);
        JobQueueLogEntry.TestField(Status, JobQueueLogEntry.Status::"In Process");
    end;

    procedure SetDescriptionOfJobToBeRun(JobDescription: Text)
    begin
        // By the description we define jobs that require reactivation
        JobDescriptionToBeRun := JobDescription;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnFindingIfJobNeedsToBeRun', '', false, false)]
    local procedure OnFindingIfJobToBeRun(var Sender: Record "Job Queue Entry"; var Result: Boolean)
    begin
        Result := StrPos(Sender.Description, JobDescriptionToBeRun) > 0;
    end;
}

