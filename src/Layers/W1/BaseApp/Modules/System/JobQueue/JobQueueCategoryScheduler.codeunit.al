namespace System.Threading;

codeunit 451 "Job Queue Category Scheduler"
{
    TableNo = "Job Queue Category";
    InherentPermissions = X;
    Permissions = TableData "Job Queue Category" = rm,
                    TableData "Job Queue Entry" = rm;

    trigger OnRun()
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        if not JobQueueEntry.ActivateNextJobInCategory(Rec) then
            if JobQueueEntry.AnyReadyJobInCategory(Rec) then
                JobQueueEntry.RefreshRecoveryTask(Rec);
    end;
}