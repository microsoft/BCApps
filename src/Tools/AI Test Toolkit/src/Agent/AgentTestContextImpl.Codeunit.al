// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.TestTools.AITestToolkit;
using System.TestTools.TestRunner;

codeunit 149049 "Agent Test Context Impl."
{
    SingleInstance = true;
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        GlobalAgentUserSecurityID: Guid;
        AgentIsNotActiveErr: Label 'Agent %1 set on suite %2 is not active.', Comment = '%1 = Agent ID, %2 = Suite Code';

    procedure GetAgentRecord(var AgentUserSecurityID: Guid)
    begin
        AgentUserSecurityID := GlobalAgentUserSecurityID;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Test Runner - Mgt", OnRunTestSuite, '', false, false)]
    local procedure OnRunTestSuite(var TestMethodLine: Record "Test Method Line")
    var
        AITTestSuite: Record "AIT Test Suite";
        Agent: Codeunit Agent;
        AITTestContext: Codeunit "AIT Test Context";
    begin
        AITTestContext.GetAITTestSuite(AITTestSuite);

        if IsNullGuid(AITTestSuite."Agent User Security ID") then
            exit;

        if not Agent.IsActive(GlobalAgentUserSecurityID) then
            Error(AgentIsNotActiveErr, AITTestSuite.Code, AITTestSuite."Agent User Security ID");
    end;

    procedure AddTaskToLog(AgentTaskId: BigInteger)
    begin
        if not AgentTaskList.Contains(AgentTaskId) then
            AgentTaskList.Add(AgentTaskId);
    end;

    procedure ClearTaskLog()
    begin
        Clear(AgentTaskList);
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"AIT Test Suite Mgt.", OnAfterInsertAITLogEntry, '', false, false)]
    local procedure InsertAgentTaskLogs(var AITLogEntry: Record "AIT Log Entry")
    begin
        LogAgentTasks(AITLogEntry);
    end;

    local procedure LogAgentTasks(var AITLogEntry: Record "AIT Log Entry")
    var
        AgentTaskId: BigInteger;
    begin
        if AgentTaskList.Count() = 0 then
            exit;

        foreach AgentTaskId in AgentTaskList do
            LogAgentTask(AgentTaskId, AITLogEntry);

        ClearTaskLog();
    end;

    local procedure LogAgentTask(AgentTaskId: BigInteger; var AITLogEntry: Record "AIT Log Entry")
    var
        AgentTaskLog: Record "Agent Task Log";
    begin
        AgentTaskLog.TransferFields(AITLogEntry, true);
        AgentTaskLog."Agent Task ID" := AgentTaskId;
        AgentTaskLog.Insert();
    end;

    var
        AgentTaskList: List of [BigInteger];
}