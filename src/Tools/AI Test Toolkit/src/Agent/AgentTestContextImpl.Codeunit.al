// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Agents;
using System.Environment;
using System.TestTools.TestRunner;

codeunit 149049 "Agent Test Context Impl."
{
    SingleInstance = true;
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetAgentUserSecurityID(var AgentUserSecurityID: Guid)
    begin
        AgentUserSecurityID := GlobalAgentUserSecurityID;
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

    procedure LogAgentTasks(var AITLogEntry: Record "AIT Log Entry")
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
        AgentTestTaskLog: Record "Agent Task Log";
        AgentTestConsumptionLog: Record "Agent Test Consumption Log";
        AgentConsumptionOverview: Codeunit "Agent Consumption Overview";
    begin
        AgentTestTaskLog.TransferFields(AITLogEntry, false);
        AgentTestTaskLog."Agent Task ID" := AgentTaskId;
        AgentTestTaskLog."Test Log Entry ID" := AITLogEntry."Entry No.";
        AgentTestTaskLog.Insert();

        // Insert database level consumption tracking.
        AgentTestConsumptionLog."Agent Task ID" := AgentTaskId;
#pragma warning disable AA0139
        AgentTestConsumptionLog."Company" := CompanyName();
#pragma warning restore AA0139
        AgentTestConsumptionLog."Test Suite Code" := AITLogEntry."Test Suite Code";
        AgentTestConsumptionLog."Copilot Credits" := AgentConsumptionOverview.GetCopilotCreditsConsumed(AgentTaskId);
        AgentTestConsumptionLog.Insert();
    end;

    procedure GetAgentTaskIDsForLogEntry(LogEntryNo: Integer): Text
    var
        AgentTestTaskLog: Record "Agent Task Log";
    begin
        AgentTestTaskLog.SetRange("Test Log Entry ID", LogEntryNo);
        exit(GetCommaSeparatedAgentTaskIDs(AgentTestTaskLog));
    end;

    procedure GetAgentTaskIDs(TestSuiteCode: Code[100]; VersionNumber: Integer; Tag: Text[20]; TestMethodLineNo: Integer): Text
    var
        VersionFilterText: Text;
    begin
        if VersionNumber > 0 then
            VersionFilterText := Format(VersionNumber);

        exit(GetAgentTaskIDs(TestSuiteCode, VersionFilterText, Tag, TestMethodLineNo));
    end;

    procedure GetAgentTaskIDs(TestSuiteCode: Code[100]; VersionFilter: Text; Tag: Text[20]; TestMethodLineNo: Integer): Text
    var
        AgentTestTaskLog: Record "Agent Task Log";
    begin
        AgentTestTaskLog.SetRange("Test Suite Code", TestSuiteCode);
        if Tag <> '' then
            AgentTestTaskLog.SetRange(Tag, Tag);
        if VersionFilter <> '' then
            AgentTestTaskLog.SetFilter(Version, VersionFilter);
        if TestMethodLineNo > 0 then
            AgentTestTaskLog.SetRange("Test Method Line No.", TestMethodLineNo);

        exit(GetCommaSeparatedAgentTaskIDs(AgentTestTaskLog));
    end;

    procedure GetCopilotCreditsForLogEntry(LogEntryNo: Integer): Decimal
    var
        AgentTestTaskLog: Record "Agent Task Log";
    begin
        AgentTestTaskLog.SetRange("Test Log Entry ID", LogEntryNo);
        exit(GetCopilotCredits(AgentTestTaskLog));
    end;

    procedure GetCopilotCredits(TestSuiteCode: Code[100]; VersionNumber: Integer; Tag: Text[20]; TestMethodLineNo: Integer): Decimal
    var
        VersionFilterText: Text;
    begin
        if VersionNumber > 0 then
            VersionFilterText := Format(VersionNumber);
        exit(GetCopilotCredits(TestSuiteCode, VersionFilterText, Tag, TestMethodLineNo));
    end;

    procedure GetCopilotCredits(TestSuiteCode: Code[100]; VersionFilter: Text; Tag: Text[20]; TestMethodLineNo: Integer): Decimal
    var
        AgentTestTaskLog: Record "Agent Task Log";
    begin
        AgentTestTaskLog.SetRange("Test Suite Code", TestSuiteCode);
        if VersionFilter <> '' then
            AgentTestTaskLog.SetFilter(Version, VersionFilter);
        if Tag <> '' then
            AgentTestTaskLog.SetRange(Tag, Tag);
        if TestMethodLineNo > 0 then
            AgentTestTaskLog.SetRange("Test Method Line No.", TestMethodLineNo);
        exit(GetCopilotCredits(AgentTestTaskLog));
    end;

    local procedure GetCopilotCredits(var AgentTestTaskLog: Record "Agent Task Log"): Decimal
    var
        AgentConsumptionOverview: Codeunit "Agent Consumption Overview";
        TaskIDsList: List of [BigInteger];
        TotalCredits: Decimal;
    begin
        if AgentTestTaskLog.FindSet() then
            repeat
                if not TaskIDsList.Contains(AgentTestTaskLog."Agent Task ID") then begin
                    TaskIDsList.Add(AgentTestTaskLog."Agent Task ID");
                    TotalCredits += AgentConsumptionOverview.GetCopilotCreditsConsumed(AgentTestTaskLog."Agent Task ID");
                end;
            until AgentTestTaskLog.Next() = 0;

        exit(TotalCredits);
    end;

    procedure GetAgentTaskCount(CommaSeparatedTaskIDs: Text): Integer
    var
        TaskIDList: List of [Text];
    begin
        if CommaSeparatedTaskIDs = '' then
            exit(0);

        TaskIDList := CommaSeparatedTaskIDs.Split(',');
        exit(TaskIDList.Count());
    end;

    procedure OpenAgentTaskList(CommaSeparatedTaskIDs: Text)
    var
        AgentTask: Record "Agent Task";
        AgentTaskListPage: Page "Agent Task List";
        FilterText: Text;
    begin
        FilterText := ConvertCommaSeparatedToFilter(CommaSeparatedTaskIDs);
        if FilterText = '' then
            exit;

        AgentTask.SetFilter(ID, FilterText);
        AgentTaskListPage.SetTableView(AgentTask);
        AgentTaskListPage.Run();
    end;

    procedure OpenAgentConsumptionOverview(CommaSeparatedTaskIDs: Text)
    var
        AgentConsumptionOverview: Codeunit "Agent Consumption Overview";
        FilterText: Text;
    begin
        FilterText := ConvertCommaSeparatedToFilter(CommaSeparatedTaskIDs);
        if FilterText = '' then
            exit;

        AgentConsumptionOverview.OpenAgentTaskConsumptionOverview(FilterText);
    end;

    local procedure GetCommaSeparatedAgentTaskIDs(var AgentTestTaskLog: Record "Agent Task Log"): Text
    var
        TaskIDList: List of [BigInteger];
        TaskIDTextList: List of [Text];
    begin
        if AgentTestTaskLog.FindSet() then
            repeat
                if not TaskIDList.Contains(AgentTestTaskLog."Agent Task ID") then begin
                    TaskIDList.Add(AgentTestTaskLog."Agent Task ID");
                    TaskIDTextList.Add(Format(AgentTestTaskLog."Agent Task ID"));
                end;
            until AgentTestTaskLog.Next() = 0;

        exit(ConcatenateList(TaskIDTextList, ', '));
    end;

    local procedure ConvertCommaSeparatedToFilter(CommaSeparatedValues: Text): Text
    var
        FilterTextBuilder: TextBuilder;
        Values: List of [Text];
        CurrentValue: Text;
        IsFirst: Boolean;
    begin
        if CommaSeparatedValues = '' then
            exit('');

        Values := CommaSeparatedValues.Split(',');
        IsFirst := true;
        foreach CurrentValue in Values do begin
            CurrentValue := CurrentValue.Trim();
            if CurrentValue <> '' then
                if IsFirst then begin
                    FilterTextBuilder.Append(CurrentValue);
                    IsFirst := false;
                end else
                    FilterTextBuilder.Append('|' + CurrentValue);
        end;
        exit(FilterTextBuilder.ToText());
    end;

    local procedure ConcatenateList(TextList: List of [Text]; Separator: Text): Text
    var
        Result: Text;
        Item: Text;
        IsFirst: Boolean;
    begin
        IsFirst := true;
        foreach Item in TextList do
            if IsFirst then begin
                Result := Item;
                IsFirst := false;
            end else
                Result += Separator + Item;

        exit(Result);
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

        GlobalAgentUserSecurityID := AITTestSuite."Agent User Security ID";
        if not Agent.IsActive(GlobalAgentUserSecurityID) then
            Error(AgentIsNotActiveErr, AITTestSuite.Code, AITTestSuite."Agent User Security ID");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Action Triggers", GetAgentTaskEvalExecutionContext, '', true, true)]
    local procedure GetAgentTaskEvalExecutionContextEvent(AgentUserSecurityId: Guid; TaskId: BigInteger; var Context: JsonObject)
    var
        AIMonthlyEvalCopilotCredits: Codeunit "AIT Eval Monthly Copilot Cred.";
        LimitReachedTok: Label 'limitReached', Locked = true;
    begin
        // Agent task log entries are currently logged after the eval execution, so we need to answer independently of the task ID.
        Context.Add(LimitReachedTok, AIMonthlyEvalCopilotCredits.IsLimitReached());
    end;

    var
        AgentTaskList: List of [BigInteger];
        GlobalAgentUserSecurityID: Guid;
        AgentIsNotActiveErr: Label 'Agent %1 set on suite %2 is not active.', Comment = '%1 = Agent ID, %2 = Suite Code';
}