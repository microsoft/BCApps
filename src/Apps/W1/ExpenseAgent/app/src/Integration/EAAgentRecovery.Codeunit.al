// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExpenseAgent;

using System.Environment;

codeunit 6937 "EA Agent Recovery"
{
    Access = Internal;
    TableNo = "Expense Agent Setup";
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnRun()
    begin
        RunEARecovery(Rec);
    end;

    internal procedure RunEARecovery(var Setup: Record "Expense Agent Setup")
    var
        ScheduledTask: Record "Scheduled Task";
        EAAgentScheduler: Codeunit "EA Agent Scheduler";
    begin
        // Check if task exists
        ScheduledTask.SetRange("Run Codeunit", Codeunit::"EA Agent Dispatcher");
        ScheduledTask.SetRange(Company, CompanyName());
        ScheduledTask.SetRange(Record, Setup.RecordId);
        if not ScheduledTask.IsEmpty() then
            exit; // Task already exists

        // Recover task
        Setup.Get();
        EAAgentScheduler.ScheduleAgent(Setup);
        Commit();
    end;
}
