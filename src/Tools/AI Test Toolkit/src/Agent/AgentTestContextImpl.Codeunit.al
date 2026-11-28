// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Agents;
using System.AI;
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

    procedure GetAgentModelId(var ModelId: Code[30])
    var
        AITTestSuite: Record "AIT Test Suite";
        AITTestContext: Codeunit "AIT Test Context";
    begin
        AITTestContext.GetAITTestSuite(AITTestSuite);
        ModelId := AITTestSuite."Agent Model ID";
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

    procedure GetCreditCaption(): Text
    var
        Quota: Codeunit "Copilot Quota";
    begin
        exit(Quota.GetCreditCaption());
    end;

    procedure IsPricingPending(TaskFilter: Text): Boolean
    var
        Consumption: Record "Agent Eval AI Consumption";
        Quota: Codeunit "Copilot Quota";
        AgentTestConsumption: Codeunit "Agent Test Consumption";
        Credits: Decimal;
        Pending: Boolean;
    begin
        if not Quota.IsNewMonetizationEnabled() or (TaskFilter = '') then
            exit(false);
        Consumption.SetFilter("Agent Task ID", TaskFilter);
        Consumption.SetRange(Company, CompanyName());
        if Consumption.FindSet() then
            repeat
                AgentTestConsumption.GetTaskAIConsumption(Consumption."Agent Task ID", Consumption.Company, Credits, Pending);
                if Pending then
                    exit(true);
            until Consumption.Next() = 0;
        exit(false);
    end;

    procedure IsPricingPendingForTasks(CommaSeparatedTaskIDs: Text): Boolean
    begin
        exit(IsPricingPending(ConvertCommaSeparatedToFilter(CommaSeparatedTaskIDs)));
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
        AgentTestConsumption: Codeunit "Agent Test Consumption";
        CopilotQuota: Codeunit "Copilot Quota";
    begin
        AgentTestTaskLog.TransferFields(AITLogEntry, false);
        AgentTestTaskLog."Agent Task ID" := AgentTaskId;
        AgentTestTaskLog."Test Log Entry ID" := AITLogEntry."Entry No.";
        AgentTestTaskLog."New Monetization" := CopilotQuota.IsNewMonetizationEnabled();
        AgentTestTaskLog.Insert();

        if AgentTestTaskLog."New Monetization" then begin
            AgentTestConsumption.LogAIConsumption(AgentTaskId, AITLogEntry);
            exit;
        end;

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
        TaskLink: Record "Agent Eval AI Task Link";
        Quota: Codeunit "Copilot Quota";
    begin
        if Quota.IsNewMonetizationEnabled() then begin
            SetAIResultFilters(TaskLink, LogEntryNo);
            exit(GetAITaskIDs(TaskLink));
        end;
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
        TaskLink: Record "Agent Eval AI Task Link";
        Quota: Codeunit "Copilot Quota";
    begin
        if Quota.IsNewMonetizationEnabled() then begin
            SetAITaskLinkFilters(TaskLink, TestSuiteCode, VersionFilter, Tag, TestMethodLineNo);
            exit(GetAITaskIDs(TaskLink));
        end;
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
        TaskLink: Record "Agent Eval AI Task Link";
        Quota: Codeunit "Copilot Quota";
    begin
        if Quota.IsNewMonetizationEnabled() then begin
            SetAIResultFilters(TaskLink, LogEntryNo);
            exit(GetAICredits(TaskLink));
        end;
        AgentTestTaskLog.SetRange("Test Log Entry ID", LogEntryNo);
        exit(GetCopilotCredits(AgentTestTaskLog));
    end;

    procedure GetCreditTotalsForLogEntry(LogEntryNo: Integer; var CopilotCredits: Decimal; var AICredits: Decimal; var PricingPending: Boolean)
    var
        TaskLog: Record "Agent Task Log";
        TaskLink: Record "Agent Eval AI Task Link";
        Overview: Codeunit "Agent Consumption Overview";
        Consumption: Codeunit "Agent Test Consumption";
        LegacyTasks: List of [BigInteger];
        AITasks: List of [BigInteger];
        Credits: Decimal;
        Pending: Boolean;
    begin
        CopilotCredits := 0;
        AICredits := 0;
        PricingPending := false;
        TaskLog.SetRange("Test Log Entry ID", LogEntryNo);
        if TaskLog.FindSet() then
            repeat
                if not TaskLog."New Monetization" then
                    if not LegacyTasks.Contains(TaskLog."Agent Task ID") then begin
                        LegacyTasks.Add(TaskLog."Agent Task ID");
                        CopilotCredits += Overview.GetLegacyCopilotCreditsConsumed(TaskLog."Agent Task ID");
                    end;
            until TaskLog.Next() = 0;
        TaskLink.SetRange(Company, CompanyName());
        SetAIResultFilters(TaskLink, LogEntryNo);
        if TaskLink.FindSet() then
            repeat
                if not AITasks.Contains(TaskLink."Agent Task ID") then begin
                    AITasks.Add(TaskLink."Agent Task ID");
                    Consumption.GetTaskAIConsumption(TaskLink."Agent Task ID", TaskLink.Company, Credits, Pending);
                    AICredits += Credits;
                    PricingPending := PricingPending or Pending;
                end;
            until TaskLink.Next() = 0;
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
        TaskLink: Record "Agent Eval AI Task Link";
        Quota: Codeunit "Copilot Quota";
    begin
        if Quota.IsNewMonetizationEnabled() then begin
            SetAITaskLinkFilters(TaskLink, TestSuiteCode, VersionFilter, Tag, TestMethodLineNo);
            exit(GetAICredits(TaskLink));
        end;
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
        AgentTestTaskLog.SetRange("New Monetization", false);
        if AgentTestTaskLog.FindSet() then
            repeat
                if not TaskIDsList.Contains(AgentTestTaskLog."Agent Task ID") then begin
                    TaskIDsList.Add(AgentTestTaskLog."Agent Task ID");
                    TotalCredits += AgentConsumptionOverview.GetLegacyCopilotCreditsConsumed(AgentTestTaskLog."Agent Task ID");
                end;
            until AgentTestTaskLog.Next() = 0;

        exit(TotalCredits);
    end;

    local procedure SetAIResultFilters(var TaskLink: Record "Agent Eval AI Task Link"; LogEntryNo: Integer)
    var
        LogEntry: Record "AIT Log Entry";
    begin
        // Use the immutable identity so reused diagnostic entry numbers cannot join old accounting.
        if not LogEntry.Get(LogEntryNo) then
            Clear(LogEntry);
        TaskLink.SetRange("Log Entry System ID", LogEntry.SystemId);
        TaskLink.SetRange("Log Entry No.", LogEntryNo);
    end;

    local procedure SetAITaskLinkFilters(var TaskLink: Record "Agent Eval AI Task Link"; SuiteCode: Code[100]; VersionFilter: Text; Tag: Text[20]; LineNo: Integer)
    begin
        TaskLink.SetRange("Test Suite Code", SuiteCode);
        if VersionFilter <> '' then
            TaskLink.SetFilter(Version, VersionFilter);
        if Tag <> '' then
            TaskLink.SetRange(Tag, Tag);
        if LineNo > 0 then
            TaskLink.SetRange("Test Method Line No.", LineNo);
    end;

    local procedure GetAITaskIDs(var TaskLink: Record "Agent Eval AI Task Link"): Text
    var
        SeenTasks: List of [BigInteger];
        TaskIDs: List of [Text];
    begin
        TaskLink.SetRange(Company, CompanyName());
        if TaskLink.FindSet() then
            repeat
                if not SeenTasks.Contains(TaskLink."Agent Task ID") then begin
                    SeenTasks.Add(TaskLink."Agent Task ID");
                    TaskIDs.Add(Format(TaskLink."Agent Task ID", 0, 9));
                end;
            until TaskLink.Next() = 0;
        exit(ConcatenateList(TaskIDs, ', '));
    end;

    local procedure GetAICredits(var TaskLink: Record "Agent Eval AI Task Link"): Decimal
    var
        Consumption: Codeunit "Agent Test Consumption";
        SeenTasks: List of [BigInteger];
        Credits: Decimal;
        Pending: Boolean;
        Total: Decimal;
    begin
        TaskLink.SetRange(Company, CompanyName());
        if TaskLink.FindSet() then
            repeat
                if not SeenTasks.Contains(TaskLink."Agent Task ID") then begin
                    SeenTasks.Add(TaskLink."Agent Task ID");
                    Consumption.GetTaskAIConsumption(TaskLink."Agent Task ID", TaskLink.Company, Credits, Pending);
                    Total += Credits;
                end;
            until TaskLink.Next() = 0;
        exit(Total);
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
        Quota: Codeunit "Copilot Quota";
        TaskIDList: List of [BigInteger];
        TaskIDTextList: List of [Text];
    begin
        AgentTestTaskLog.SetRange("New Monetization", Quota.IsNewMonetizationEnabled());
        if AgentTestTaskLog.FindSet() then
            repeat
                if not TaskIDList.Contains(AgentTestTaskLog."Agent Task ID") then begin
                    TaskIDList.Add(AgentTestTaskLog."Agent Task ID");
                    // Format using XML/invariant culture (format 9) to avoid locale thousands
                    // separators that would otherwise be split as extra IDs by the comma-based
                    // serialization used in GetAgentTaskCount and ConvertCommaSeparatedToFilter.
                    TaskIDTextList.Add(Format(AgentTestTaskLog."Agent Task ID", 0, 9));
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