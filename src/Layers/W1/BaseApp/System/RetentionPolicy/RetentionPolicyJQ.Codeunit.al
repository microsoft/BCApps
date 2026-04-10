namespace System.DataAdministration;

using System.Threading;

codeunit 3997 "Retention Policy JQ"
{
    Access = Internal;
    EventSubscriberInstance = Manual;

    var
        CurrSessionId: Integer;
        RetentionPolicyLogCategory: Enum "Retention Policy Log Category";
        StartApplyRetentionPolicyFromJobQueueLbl: Label 'The job queue entry that applies retention policies started.';
        EndApplyRetentionPolicyFromJobQueueLbl: Label 'The job queue entry that applies retention policies finished.';
        RescheduleOnLimitExceededLbl: Label 'The maximum number of records that you are allowed to delete at the same time has been reached. The job queue entry was scheduled to run again.';
        SkipRescheduleOnLimitExceededLbl: Label 'Wrong session ID for job queue. Did not reschedule the job queue entry. Session ID: %1, Expected Session ID %2.', Comment = '%1, %2 = integer';
        JQNotRecheduledBecauseHandledLbl: Label 'The event was handled by another subscriber. Did not reschedule the job queue entry.';
        JQNotRecheduledBecauseUserInvokedRunLbl: Label 'The user invoked the retention policy run. Did not reschedule the job queue entry.';
        JQNotRecheduledBecauseOutsideTimeWindowLbl: Label 'Event occurs outside allowed time window. Did not reschedule the job queue entry.';
        JobQueueCategoryTok: Label 'RETENTION', Locked = true, Comment = 'Max Length 10';

    trigger OnRun()
    var
        RetentionPolicyJQ: Codeunit "Retention Policy JQ";
        RetentionPolicyLog: Codeunit "Retention Policy Log";
    begin
        BindSubscription(RetentionPolicyJQ);
        RetentionPolicyJQ.SetSessionId(Database.SessionId());
        RetentionPolicyLog.LogInfo(RetentionPolicyLogCategory::"Retention Policy - Schedule", StartApplyRetentionPolicyFromJobQueueLbl);

        Codeunit.Run(Codeunit::"Apply Retention Policy");

        RetentionPolicyLog.LogInfo(RetentionPolicyLogCategory::"Retention Policy - Schedule", EndApplyRetentionPolicyFromJobQueueLbl);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Apply Retention Policy", 'OnApplyRetentionPolicyRecordLimitExceeded', '', true, true)]
    local procedure ScheduleJobQueueEntryOnApplyRetentionPolicyRecordLimitExceeded(ApplyAllRetentionPolicies: Boolean; UserInvokedRun: Boolean; var Handled: Boolean)
    var
        JobQueueEntry: Record "Job Queue Entry";
        RetentionPolicyLog: Codeunit "Retention Policy Log";
    begin
        if Handled then begin
            RetentionPolicyLog.LogInfo(RetentionPolicyLogCategory::"Retention Policy - Schedule", JQNotRecheduledBecauseHandledLbl);
            exit;
        end;

        if UserInvokedRun then begin
            RetentionPolicyLog.LogInfo(RetentionPolicyLogCategory::"Retention Policy - Schedule", JQNotRecheduledBecauseUserInvokedRunLbl);
            exit;
        end;

        if (Time() >= 080000T) and (Time() <= 200000T) then begin
            RetentionPolicyLog.LogInfo(RetentionPolicyLogCategory::"Retention Policy - Schedule", JQNotRecheduledBecauseOutsideTimeWindowLbl);
            exit;
        end;

        if Database.SessionId() <> CurrSessionId then begin
            RetentionPolicyLog.LogWarning(RetentionPolicyLogCategory::"Retention Policy - Schedule", StrSubstNo(SkipRescheduleOnLimitExceededLbl, Database.SessionId(), CurrSessionId));
            exit;
        end;

        RetentionPolicyLog.LogInfo(RetentionPolicyLogCategory::"Retention Policy - Schedule", RescheduleOnLimitExceededLbl);

        JobQueueEntry.ReadIsolation(IsolationLevel::ReadCommitted);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Retention Policy JQ");
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetFilter(Status, '%1|%2', JobQueueEntry.Status::Ready, JobQueueEntry.Status::"On Hold");
        if JobQueueEntry.IsEmpty() then
            JobQueueEntry.ScheduleJobQueueEntryForLater(Codeunit::"Retention Policy JQ", CurrentDateTime(), JobQueueCategoryTok, '')
        else begin
            JobQueueEntry.ReadIsolation(IsolationLevel::UpdLock);
            JobQueueEntry.FindFirst();
            JobQueueEntry.Restart();
        end;
        Handled := true;
    end;

    internal procedure SetSessionId(SessionId: Integer)
    begin
        CurrSessionId := SessionId
    end;
}