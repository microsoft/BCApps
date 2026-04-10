codeunit 132458 "Library - Job Queue"
{
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        TempJobQueueEntry: Record "Job Queue Entry" temporary;
        DoNotHandleCodeunitJobQueueEnqueueEvent: Boolean;
        DoNotHandleTableJobQueueEntryEvent: Boolean;
        DoNotHandleSendNotificationEvent: Boolean;
        DoNotHandleJobsNeedToBeRunEvent: Boolean;
        TrackingJobQueueEntryID: Guid;
        MultipleTrackJobQueueEntryErr: Label 'Can''t track multiple job queue entries';
        DoNotSkipProcessBatchInBackground: Boolean;

    [Scope('OnPrem')]
    procedure SetDoNotHandleJobsNeedToBeRunEvent(NewDoNotHandleJobsNeedToBeRunEvent: Boolean)
    begin
        DoNotHandleJobsNeedToBeRunEvent := NewDoNotHandleJobsNeedToBeRunEvent;
    end;

    [Scope('OnPrem')]
    procedure SetDoNotHandleCodeunitJobQueueEnqueueEvent(NewDoNotHandleCodeunitJobQueueEnqueueEvent: Boolean)
    begin
        DoNotHandleCodeunitJobQueueEnqueueEvent := NewDoNotHandleCodeunitJobQueueEnqueueEvent;
    end;

    [Scope('OnPrem')]
    procedure SetDoNotHandleTableJobQueueEntryEvent(NewDoNotHandleTableJobQueueEntryEvent: Boolean)
    begin
        DoNotHandleTableJobQueueEntryEvent := NewDoNotHandleTableJobQueueEntryEvent;
    end;

    [Scope('OnPrem')]
    procedure SetDoNotHandleSendNotificationEvent(NewDoNotHandleSendNotificationEvent: Boolean)
    begin
        DoNotHandleSendNotificationEvent := NewDoNotHandleSendNotificationEvent;
    end;

    [Scope('OnPrem')]
    procedure SetTrackingJobQueueEntry(JobQueueEntry: Record "Job Queue Entry")
    begin
        if not IsNullGuid(TrackingJobQueueEntryID) then
            Error(MultipleTrackJobQueueEntryErr);

        TrackingJobQueueEntryID := JobQueueEntry.ID;
    end;

    [Scope('OnPrem')]
    procedure GetCollectedJobQueueEntries(var TempJobQueueEntryDst: Record "Job Queue Entry" temporary)
    begin
        TempJobQueueEntryDst.Copy(TempJobQueueEntry, true);
    end;

    [Scope('OnPrem')]
    procedure FindAndRunJobQueueEntryByRecordId(RecordIdToProcess: RecordId)
    begin
        FindAndRunJobQueueEntryByRecordId(RecordIdToProcess, false);
    end;

    [Scope('OnPrem')]
    procedure FindAndRunJobQueueEntryByRecordId(RecordIdToProcess: RecordId; WithErrorHandler: Boolean)
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Record ID to Process", RecordIdToProcess);
        JobQueueEntry.FindSet();
        JobQueueEntry.Status := JobQueueEntry.Status::Ready;
        JobQueueEntry.Modify();
        if WithErrorHandler then begin
            asserterror RunJobQueueDispatcher(JobQueueEntry);
            RunJobQueueErrorHandler(JobQueueEntry);
        end
        else
            RunJobQueueDispatcher(JobQueueEntry);
    end;

    [Scope('OnPrem')]
    procedure RunJobQueueDispatcher(var JobQueueEntry: Record "Job Queue Entry")
    begin
        Codeunit.Run(Codeunit::"Job Queue Dispatcher", JobQueueEntry);
    end;

    [Scope('OnPrem')]
    procedure RunJobQueueErrorHandler(var JobQueueEntry: Record "Job Queue Entry")
    begin
        Codeunit.Run(Codeunit::"Job Queue Error Handler", JobQueueEntry);
    end;

    [Scope('OnPrem')]
    procedure RunSendNotification(JobQueueEntry: Record "Job Queue Entry")
    begin
        Codeunit.Run(Codeunit::"Job Queue - Send Notification", JobQueueEntry);
    end;

    procedure SetDoNotSkipProcessBatchInBackground(NewDoNotSkipProcessBatchInBackground: Boolean)
    begin
        DoNotSkipProcessBatchInBackground := NewDoNotSkipProcessBatchInBackground;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Job Queue - Enqueue", 'OnBeforeJobQueueScheduleTask', '', false, false)]
    local procedure HandleCodeunitJobQueueEnqueueEventOnBeforeJobQueueScheduleTask(var JobQueueEntry: Record "Job Queue Entry"; var DoNotScheduleTask: Boolean)
    begin
        if DoNotHandleCodeunitJobQueueEnqueueEvent then
            exit;

        DoNotScheduleTask := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnBeforeScheduleTask', '', false, false)]
    local procedure HandleTableJobQueueEntryEventOnBeforeJobQueueScheduleTask(var JobQueueEntry: Record "Job Queue Entry"; var TaskGUID: Guid)
    begin
        if DoNotHandleTableJobQueueEntryEvent then
            exit;

        TaskGUID := CreateGuid();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnAfterInsertEvent', '', false, false)]
    local procedure CollectJobQueueEntryOnAfterInsertEvent(var Rec: Record "Job Queue Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;

        if not IsNullGuid(TrackingJobQueueEntryID) then
            exit;

        TempJobQueueEntry.TransferFields(Rec);
        TempJobQueueEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnAfterModifyEvent', '', false, false)]
    local procedure CollectJobQueueEntryOnAfterModifyEvent(var Rec: Record "Job Queue Entry"; var xRec: Record "Job Queue Entry"; RunTrigger: Boolean)
    var
        IsRecRegistered: Boolean;
    begin
        if Rec.IsTemporary then
            exit;

        if not IsNullGuid(TrackingJobQueueEntryID) then
            exit;

        IsRecRegistered := TempJobQueueEntry.Get(Rec.ID);
        TempJobQueueEntry.TransferFields(Rec);
        if IsRecRegistered then
            TempJobQueueEntry.Modify()
        else
            TempJobQueueEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnAfterInsertEvent', '', false, false)]
    local procedure CollectTrackingJobQueueEntryOnAfterInsertEvent(var Rec: Record "Job Queue Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;

        if IsNullGuid(TrackingJobQueueEntryID) then
            exit;

        if Rec.ID <> TrackingJobQueueEntryID then
            exit;

        TempJobQueueEntry.TransferFields(Rec);
        TempJobQueueEntry.ID := CreateGuid();
        TempJobQueueEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnAfterModifyEvent', '', false, false)]
    local procedure CollectTrackingJobQueueEntryOnAfterModifyEvent(var Rec: Record "Job Queue Entry"; var xRec: Record "Job Queue Entry"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;

        if IsNullGuid(TrackingJobQueueEntryID) then
            exit;

        if Rec.ID <> TrackingJobQueueEntryID then
            exit;

        TempJobQueueEntry.TransferFields(Rec);
        TempJobQueueEntry.ID := CreateGuid();
        TempJobQueueEntry.Insert();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Batch Processing Mgt.", 'OnBeforeBatchShouldBeProcessedInBackground', '', false, false)]
    local procedure OnBeforeBatchShouldBeProcessedInBackgroundHandler(var IsProcessed: Boolean)
    begin
        IsProcessed := not DoNotSkipProcessBatchInBackground;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnBeforeTryRunJobQueueSendNotification', '', false, false)]
    local procedure OnBeforeTryRunJobQueueSendNotification(var JobQueueEntry: Record "Job Queue Entry"; var IsHandled: Boolean)
    begin
        if DoNotHandleSendNotificationEvent then
            exit;

        IsHandled := true;
        RunSendNotification(JobQueueEntry);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Job Queue Entry", 'OnFindingIfJobNeedsToBeRun', '', false, false)]
    local procedure OnFindingIfJobNeedsToBeRun(var Result: Boolean)
    begin
        if DoNotHandleJobsNeedToBeRunEvent then
            exit;

        Result := true;
    end;
}

