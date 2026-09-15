codeunit 117082 "Create Job Queue Entries"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        CreateWorkFlowJobQueue();
        CreateRemoveOrphanRecordLinksJobQueueEntry();
    end;

    var
        CreateJQE: Codeunit "Create Job Queue Entries";
        RemoveOrphanRecordLinksTxt: Label 'Remove orphaned record links';

    local procedure CreateWorkFlowJobQueue()
    var
        JobQueueEntry: Record "Job Queue Entry";
        WorkflowSetup: Codeunit "Workflow Setup";
    begin
        BindSubscription(CreateJQE);

        WorkflowSetup.CreateJobQueueEntry(
            JobQueueEntry."Object Type to Run"::Codeunit, CODEUNIT::"ServOrder-Check Response Time", '', CreateDateTime(Today + 1, 080000T), 60);

        UnbindSubscription(CreateJQE);

        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", CODEUNIT::"ServOrder-Check Response Time");
        if JobQueueEntry.FindFirst() then begin
            JobQueueEntry."User ID" := '';
            JobQueueEntry.Modify();
            JobQueueEntry.SetStatus(JobQueueEntry.Status::"On Hold");
        end;
    end;

    local procedure CreateRemoveOrphanRecordLinksJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Remove Orphaned Record Links");
        JobQueueEntry.SetRange("Recurring Job", TRUE);
        if not JobQueueEntry.IsEmpty() then
            exit;

        BindSubscription(CreateJQE);

        JobQueueEntry.InitRecurringJob(43200); // once every 30 days
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"Remove Orphaned Record Links";
        JobQueueEntry."Report Output Type" := JobQueueEntry."Report Output Type"::"None (Processing only)";
        JobQueueEntry."Maximum No. of Attempts to Run" := 3;
        JobQueueEntry.Description := RemoveOrphanRecordLinksTxt;

        Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry);
        JobQueueEntry.SetStatus(JobQueueEntry.Status::"On Hold");

        UnbindSubscription(CreateJQE);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue - Enqueue", 'OnBeforeJobQueueScheduleTask', '', false, false)]
    local procedure OnBeforeJobQueueScheduleTask(var JobQueueEntry: Record "Job Queue Entry"; var DoNotScheduleTask: Boolean)
    begin
        DoNotScheduleTask := true;
    end;
}

