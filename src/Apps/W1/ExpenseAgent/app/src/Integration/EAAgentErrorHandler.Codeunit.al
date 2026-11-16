// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExpenseAgent;

codeunit 6936 "EA Agent Error Handler"
{
    Access = Internal;
    TableNo = "Expense Agent Setup";
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        RunEAErrorHandler(Rec);
    end;


    local procedure RunEAErrorHandler(var Setup: Record "Expense Agent Setup")
    var
        ExpenseAgentStatus: Record "Expense Agent Status";
        EASchedulerTask: Record "EA Scheduler Task";
        EAAgentScheduler: Codeunit "EA Agent Scheduler";
    begin
        EASchedulerTask.ReadIsolation(IsolationLevel::UpdLock);
        if ExpenseAgentStatus.Get() then
            if ExpenseAgentStatus."EA Scheduler Task ID" <> 0 then
                if EASchedulerTask.Get(ExpenseAgentStatus."EA Scheduler Task ID") then begin
                    EASchedulerTask.Status := EASchedulerTask.Status::Failed;
                    EASchedulerTask."Error Message" := CopyStr(GetLastErrorText(), 1, MaxStrLen(EASchedulerTask."Error Message"));
                    EASchedulerTask.SetErrorCallStack(GetLastErrorCallStack());
                    EASchedulerTask.Modify();
                    Commit();
                end;
        Setup.Get();
        EAAgentScheduler.ScheduleAgent(Setup);
    end;
}
