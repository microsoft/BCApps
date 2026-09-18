// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExpenseAgent;

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
        ExpenseAgentStatus: Record "Expense Agent Status";
        EAAgentScheduler: Codeunit "EA Agent Scheduler";
        CompletedTaskId: Guid;
    begin
        if ExpenseAgentStatus.Get() then
            CompletedTaskId := ExpenseAgentStatus."Agent Recovery Task ID";
        EAAgentScheduler.CompleteAgentTask(Setup, CompletedTaskId);
    end;
}
