namespace System.DataAdministration;

using System.Threading;

codeunit 3998 "Retention Policy Scheduler"
{
    Access = Internal;
    Permissions = tabledata "Job Queue Category" = ri,
                  tabledata "Job Queue Entry" = rim;

    var
        JobQueueActivatedNotificationTxt: Label 'A Job Queue Entry to apply the retention policies has been scheduled to run.';
        JobQueueReadyNotificationTxt: Label 'A Job Queue Entry to apply the retention policies was set to Ready state.';
        JobQueueDeactivatedNotificationTxt: Label 'A Job Queue Entry to apply the retention policies was set to On-Hold state.';
        JobQueueCategoryTok: Label 'RETENTION', Locked = true, Comment = 'Max Length 10';
        JobQueueCategoryDescTxt: Label 'Retention Policies';
        RetentionPolicyLogCategory: Enum "Retention Policy Log Category";

    [EventSubscriber(ObjectType::Table, Database::"Retention Policy Setup", 'OnAfterInsertEvent', '', true, true)]
    local procedure CheckRetentionPolicyScheduleOnAfterInsert(var Rec: Record "Retention Policy Setup")
    var
        RetentionPolicySetup: Codeunit "Retention Policy Setup";
    begin
        if not CanScheduleJobQueueEntry(Rec) then
            exit;

        if RetentionPolicySetup.IsRetentionPolicyEnabled() then
            ScheduleRecurringRetentionPolicy()
        else
            UnScheduleRecurringRetentionPolicy();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Retention Policy Setup", 'OnAfterModifyEvent', '', true, true)]
    local procedure CheckRetentionPolicyScheduleOnAfterModify(var Rec: Record "Retention Policy Setup")
    var
        RetentionPolicySetup: Codeunit "Retention Policy Setup";
    begin
        if not CanScheduleJobQueueEntry(Rec) then
            exit;

        if RetentionPolicySetup.IsRetentionPolicyEnabled() then
            ScheduleRecurringRetentionPolicy()
        else
            UnScheduleRecurringRetentionPolicy();
    end;

    [EventSubscriber(ObjectType::Table, Database::"Retention Policy Setup", 'OnAfterDeleteEvent', '', true, true)]
    local procedure CheckRetentionPolicyScheduleOnAfterDelete(var Rec: Record "Retention Policy Setup")
    var
        RetentionPolicySetup: Codeunit "Retention Policy Setup";
    begin
        if not CanScheduleJobQueueEntry(Rec) then
            exit;

        if not RetentionPolicySetup.IsRetentionPolicyEnabled() then
            UnScheduleRecurringRetentionPolicy();
    end;

    local procedure CanScheduleJobQueueEntry(var RetentionPolicySetup: Record "Retention Policy Setup"): Boolean
    begin
        if RetentionPolicySetup.IsTemporary() then
            exit(false);

        if GetCurrentModuleExecutionContext() <> ExecutionContext::Normal then
            exit(false);

        if not TaskScheduler.CanCreateTask() then
            exit(false);

        exit(true)
    end;

    local procedure ScheduleRecurringRetentionPolicy()
    var
        JobQueueEntry: Record "Job Queue Entry";
        RetentionPolicyLog: Codeunit "Retention Policy Log";
        BlankRecordId: RecordId;
        NextRunDateFormula: DateFormula;
        ScheduleOffset: Duration;
    begin
        Evaluate(NextRunDateFormula, '<1D>');
        if JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"Retention Policy JQ") then begin
            if JobQueueEntry.IsReadyToStart() then
                exit;

            JobQueueEntry.SetStatus(JobQueueEntry.Status::Ready);
            RetentionPolicyLog.LogInfo(RetentionPolicyLogCategory::"Retention Policy - Schedule", JobQueueReadyNotificationTxt);
        end else begin
            CreateRetentionPolicyJobQueueCategory();
            ScheduleOffset := ScheduleOffset();
            JobQueueEntry.ScheduleRecurrentJobQueueEntryWithRunDateFormula(
                JobQueueEntry."Object Type to Run"::Codeunit,
                Codeunit::"Retention Policy JQ",
                BlankRecordId,
                JobQueueCategoryTok,
                0, // no rerun attempts
                NextRunDateFormula,
                220000T + ScheduleOffset, // 10pm
                JobTimeout() - ScheduleOffset); // Ensure we don't go over 8am
            RetentionPolicyLog.LogInfo(RetentionPolicyLogCategory::"Retention Policy - Schedule", JobQueueActivatedNotificationTxt);
        end;
    end;

    local procedure ScheduleOffset(): Duration
    begin
        // Random offset 0 to +4hr
        exit(Random(4 * 60 * 60 * 1000));
    end;

    local procedure JobTimeout(): Duration
    begin
        exit(10 * 60 * 60 * 1000) // 10hr timeout
    end;

    local procedure UnScheduleRecurringRetentionPolicy()
    var
        JobQueueEntry: Record "Job Queue Entry";
        RetentionPolicyLog: Codeunit "Retention Policy Log";
    begin
        if not JobQueueEntry.FindJobQueueEntry(JobQueueEntry."Object Type to Run"::Codeunit, Codeunit::"Retention Policy JQ") then
            exit;

        JobQueueEntry.SetStatus(JobQueueEntry.Status::"On Hold");
        RetentionPolicyLog.LogInfo(RetentionPolicyLogCategory::"Retention Policy - Schedule", JobQueueDeactivatedNotificationTxt);
    end;

    local procedure CreateRetentionPolicyJobQueueCategory()
    var
        JobQueueCategory: Record "Job Queue Category";
    begin
        if JobQueueCategory.Get(JobQueueCategoryTok) then
            exit;

        JobQueueCategory.Code := JobQueueCategoryTok;
        JobQueueCategory.Description := JobQueueCategoryDescTxt;
        JobQueueCategory.Insert();
    end;
}