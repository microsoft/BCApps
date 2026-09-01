namespace System.Threading;

using System.Utilities;

codeunit 450 "Job Queue Error Handler"
{
    Permissions = TableData "Job Queue Entry" = rimd,
                    TableData "Job Queue Log Entry" = rm;
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        if Rec."Job Queue Category Code" <> '' then
            Rec.ActivateNextJobInCategoryIfAny();
        if Rec.GetRecLockedExtendedTimeout() then begin
            Rec.Status := Rec.Status::Error;
            LogError(Rec);
        end;
    end;

    var
        JobQueueContextTxt: Label 'Job Queue', Locked = true;

    local procedure LogError(var JobQueueEntry: Record "Job Queue Entry")
    var
        JobQueueLogEntry: Record "Job Queue Log Entry";
        ErrorMessages: Record "Error Message";
        ErrorMessageManagement: Codeunit "Error Message Management";
        ErrorMessageHandler: Codeunit "Error Message Handler";
        ErrorContextElement: Codeunit "Error Context Element";
    begin
        JobQueueLogEntry.SetErrorCallStack(GetLastErrorCallStack()); // Set callstack for telemetry
        OnBeforeLogError(JobQueueLogEntry, JobQueueEntry);

        if IsNullGuid(JobQueueEntry."Error Message Register Id") then begin
            ErrorMessageManagement.Activate(ErrorMessageHandler, false);
            ErrorMessageManagement.PushContext(ErrorContextElement, JobQueueEntry.RecordId(), 0, JobQueueContextTxt);
            JobQueueEntry."Error Message Register Id" := ErrorMessageHandler.RegisterErrorMessages(false);
            ErrorMessageManagement.PopContext(ErrorContextElement);
        end;

        ErrorMessages.SetFilter("Register ID", JobQueueEntry."Error Message Register Id");
        if ErrorMessages.FindFirst() then;

        JobQueueEntry."Error Message" := ErrorMessages."Message";
        JobQueueEntry.Modify();

        JobQueueLogEntry.SetRange(ID, JobQueueEntry.ID);
        JobQueueLogEntry.SetRange(Status, JobQueueLogEntry.Status::"In Process");
        if JobQueueLogEntry.FindFirst() then begin
            JobQueueLogEntry."Error Message Register Id" := JobQueueEntry."Error Message Register Id";
            JobQueueLogEntry."Error Message" := JobQueueEntry."Error Message";
            JobQueueLogEntry.SetErrorCallStack(GetLastErrorCallStack()); // Need to save callstack before deleted above
            JobQueueLogEntry.Status := JobQueueLogEntry.Status::Error;
            if JobQueueLogEntry."End Date/Time" = 0DT then
                JobQueueLogEntry."End Date/Time" := CurrentDateTime();
            JobQueueLogEntry.Modify();
        end;

        OnAfterLogError(JobQueueEntry, JobQueueLogEntry);

        JobQueueEntry.FinalizeRun();
        Commit();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterLogError(var JobQueueEntry: Record "Job Queue Entry"; var JobQueueLogEntry: Record "Job Queue Log Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLogError(var JobQueueLogEntry: Record "Job Queue Log Entry"; var JobQueueEntry: Record "Job Queue Entry")
    begin
    end;

}
