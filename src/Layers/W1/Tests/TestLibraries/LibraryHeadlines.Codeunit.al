codeunit 130626 "Library - Headlines"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"RC Headlines Executor", 'OnTaskSchedulerUnavailable', '', false, false)]
    local procedure OnTaskSchedulerUnavailable(JobQueueEntry: Record "Job Queue Entry")
    begin
        Codeunit.Run(Codeunit::"RC Headlines Executor", JobQueueEntry);
    end;
}

