namespace System.Threading;

codeunit 461 "Job Queue Cleanup Tasks"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    TableNo = "Job Queue Entry";

    var
        JobQueueManagement: Codeunit "Job Queue Management";

    trigger OnRun()
    begin
        if (Rec."Object Type to Run" = Rec."Object Type to Run"::Codeunit) and (Rec."Object ID to Run" = Codeunit::"Job Queue Cleanup Tasks") then
            CleanupJQTasks()
        else
            JobQueueManagement.UpdateRetriableFailedJobQueueLogEntry(Rec);
    end;

    local procedure CleanupJQTasks()
    begin
        JobQueueManagement.CheckAndRefreshCategoryRecoveryTasks();
        JobQueueManagement.FindStaleJobsAndSetError();
    end;


}