// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Agents;
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

        GlobalAgentUserSecurityID := AITTestSuite."Agent User Security ID";
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
        AgentTaskLog.TransferFields(AITLogEntry, false);
        AgentTaskLog."Agent Task ID" := AgentTaskId;
        AgentTaskLog."Test Log Entry ID" := AITLogEntry."Entry No.";
        AgentTaskLog.Insert();
    end;

    /// <summary>
    /// Gets the comma-separated list of Agent Task IDs for a specific log entry.
    /// </summary>
    /// <param name="LogEntryNo">The log entry number.</param>
    /// <returns>Comma-separated string of Agent Task IDs.</returns>
    procedure GetAgentTaskIDsForLogEntry(LogEntryNo: Integer): Text
    var
        AgentTaskLog: Record "Agent Task Log";
    begin
        AgentTaskLog.SetRange("Test Log Entry ID", LogEntryNo);
        exit(GetAgentTaskIDs(AgentTaskLog));
    end;

    /// <summary>
    /// Gets the comma-separated list of Agent Task IDs for the given test suite, version, and line number.
    /// </summary>
    /// <param name="TestSuiteCode">The test suite code.</param>
    /// <param name="VersionNumber">The version number.</param>
    /// <param name="Tag">The tag.</param>
    /// <param name="TestMethodLineNo">The test method line number. Use 0 for all lines.</param>
    /// <returns>Comma-separated string of Agent Task IDs.</returns>
    procedure GetAgentTaskIDs(TestSuiteCode: Code[100]; VersionNumber: Integer; Tag: Text[20]; TestMethodLineNo: Integer): Text
    var
        VersionFilterText: Text;
    begin
        if VersionNumber > 0 then
            VersionFilterText := Format(VersionNumber);
        exit(GetAgentTaskIDs(TestSuiteCode, VersionFilterText, Tag, TestMethodLineNo));
    end;

    /// <summary>
    /// Gets the comma-separated list of Agent Task IDs for the given test suite, version, and line number.
    /// </summary>
    /// <param name="TestSuiteCode">The test suite code.</param>
    /// <param name="VersionFilter">The version filter.</param>
    /// <param name="Tag">The tag.</param>
    /// <param name="TestMethodLineNo">The test method line number. Use 0 for all lines.</param>
    /// <returns>Comma-separated string of Agent Task IDs.</returns>
    procedure GetAgentTaskIDs(TestSuiteCode: Code[100]; VersionFilter: Text; Tag: Text[20]; TestMethodLineNo: Integer): Text
    var
        AgentTaskLog: Record "Agent Task Log";
    begin
        AgentTaskLog.SetRange("Test Suite Code", TestSuiteCode);
        if Tag <> '' then
            AgentTaskLog.SetRange(Tag, Tag);
        if VersionFilter <> '' then
            AgentTaskLog.SetFilter(Version, VersionFilter);
        if TestMethodLineNo <> 0 then
            AgentTaskLog.SetRange("Test Method Line No.", TestMethodLineNo);

        exit(GetAgentTaskIDs(AgentTaskLog));
    end;

    /// <summary>
    /// Gets the total Copilot Credits consumed for a specific log entry.
    /// </summary>
    /// <param name="LogEntryNo">The log entry number.</param>
    /// <returns>Total Copilot Credits consumed.</returns>
    procedure GetCopilotCreditsForLogEntry(LogEntryNo: Integer): Decimal
    var
        AgentTaskLog: Record "Agent Task Log";

    begin
        AgentTaskLog.SetRange("Test Log Entry ID", LogEntryNo);
        exit(GetCopilotCredits(AgentTaskLog));
    end;

    /// <summary>
    /// Gets the total Copilot Credits consumed for the given test suite, version, and line number.
    /// </summary>
    /// <param name="TestSuiteCode">The test suite code.</param>
    /// <param name="Tag">The tag.</param>
    /// <param name="VersionNumber">The version number.</param>
    /// <param name="TestMethodLineNo">The test method line number. Use 0 for all lines.</param>
    /// <returns>Total Copilot Credits consumed.</returns>
    procedure GetCopilotCredits(TestSuiteCode: Code[100]; VersionNumber: Integer; Tag: Text[20]; TestMethodLineNo: Integer): Decimal
    var
        VersionFilterText: Text;
    begin
        if VersionNumber > 0 then
            VersionFilterText := Format(VersionNumber);
        exit(GetCopilotCredits(TestSuiteCode, VersionFilterText, Tag, TestMethodLineNo));
    end;

    /// <summary>
    /// Gets the total Copilot Credits consumed for the given test suite, version, and line number.
    /// </summary>
    /// <param name="TestSuiteCode">The test suite code.</param>
    /// <param name="VersionFilter">The version filter.</param>
    /// <param name="Tag">The tag.</param>
    /// <param name="TestMethodLineNo">The test method line number. Use 0 for all lines.</param>
    /// <returns>Total Copilot Credits consumed.</returns>
    procedure GetCopilotCredits(TestSuiteCode: Code[100]; VersionFilter: Text; Tag: Text[20]; TestMethodLineNo: Integer): Decimal
    var
        AgentTaskLog: Record "Agent Task Log";
    begin
        AgentTaskLog.SetRange("Test Suite Code", TestSuiteCode);
        if VersionFilter <> '' then
            AgentTaskLog.SetFilter(Version, VersionFilter);

        if Tag <> '' then
            AgentTaskLog.SetRange(Tag, Tag);

        if TestMethodLineNo > 0 then
            AgentTaskLog.SetRange("Test Method Line No.", TestMethodLineNo);

        exit(GetCopilotCredits(AgentTaskLog));
    end;

    local procedure GetCopilotCredits(var AgentTaskLog: Record "Agent Task Log"): Decimal
    var
        AgentTask: Codeunit "Agent Task";
        TaskIDList: List of [BigInteger];
        TotalCredits: Decimal;
    begin
        if AgentTaskLog.FindSet() then
            repeat
                if not TaskIDList.Contains(AgentTaskLog."Agent Task ID") then begin
                    TaskIDList.Add(AgentTaskLog."Agent Task ID");
                    TotalCredits += AgentTask.GetCopilotCreditsConsumed(AgentTaskLog."Agent Task ID");
                end;
            until AgentTaskLog.Next() = 0;

        exit(TotalCredits);
    end;

    /// <summary>
    /// Gets the count of Agent Tasks from a comma-separated list of Agent Task IDs.
    /// </summary>
    /// <param name="CommaSeparatedTaskIDs">Comma-separated string of Agent Task IDs.</param>
    /// <returns>The number of Agent Tasks in the list.</returns>
    procedure GetAgentTaskCount(CommaSeparatedTaskIDs: Text): Integer
    var
        TaskIDList: List of [Text];
    begin
        if CommaSeparatedTaskIDs = '' then
            exit(0);

        TaskIDList := CommaSeparatedTaskIDs.Split(',');
        exit(TaskIDList.Count());
    end;

    /// <summary>
    /// Opens the Agent Task List page filtered to the specified Agent Task IDs.
    /// </summary>
    /// <param name="CommaSeparatedTaskIDs">Comma-separated string of Agent Task IDs.</param>
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

    local procedure GetAgentTaskIDs(var AgentTaskLog: Record "Agent Task Log"): Text
    var
        TaskIDList: List of [BigInteger];
        TaskIDTextList: List of [Text];
    begin
        if AgentTaskLog.FindSet() then
            repeat
                if not TaskIDList.Contains(AgentTaskLog."Agent Task ID") then begin
                    TaskIDList.Add(AgentTaskLog."Agent Task ID");
                    TaskIDTextList.Add(Format(AgentTaskLog."Agent Task ID"));
                end;
            until AgentTaskLog.Next() = 0;

        exit(ConcatenateList(TaskIDTextList, ', '));
    end;

    local procedure ConvertCommaSeparatedToFilter(CommaSeparatedValues: Text): Text
    var
        Values: List of [Text];
        CurrentValue: Text;
        FilterText: Text;
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
                    FilterText := CurrentValue;
                    IsFirst := false;
                end else
                    FilterText += '|' + CurrentValue;
        end;
        exit(FilterText);
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

    var
        AgentTaskList: List of [BigInteger];
}