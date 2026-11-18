// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Agents;
using System.AI;

codeunit 149047 "Agent Test Consumption"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure GetCopilotCreditsForEnvironment(PeriodStartDate: Date): Decimal
    begin
        exit(GetCopilotCreditsForEnvironment(PeriodStartDate, DT2Date(CurrentDateTime())));
    end;

    procedure GetCopilotCreditsForEnvironment(PeriodStartDate: Date; PeriodEndDate: Date): Decimal
    var
        AgentTestConsumptionLog: Record "Agent Test Consumption Log";
        CopilotQuota: Codeunit "Copilot Quota";
    begin
        if CopilotQuota.IsNewMonetizationEnabled() then
            exit(GetAICredits('', false, PeriodStartDate, PeriodEndDate));
        AgentTestConsumptionLog.SetFilter(SystemCreatedAt, '>=%1&<=%2', CreateDateTime(PeriodStartDate, 0T), CreateDateTime(PeriodEndDate, 235959.999T));
        AgentTestConsumptionLog.CalcSums("Copilot Credits");
        exit(AgentTestConsumptionLog."Copilot Credits");
    end;

    procedure GetCopilotCreditsForCurrentCompany(PeriodStartDate: Date): Decimal
    begin
        exit(GetCopilotCreditsForCurrentCompany(PeriodStartDate, DT2Date(CurrentDateTime())));
    end;

    procedure GetCopilotCreditsForCurrentCompany(PeriodStartDate: Date; PeriodEndDate: Date): Decimal
    var
        AgentTestConsumptionLog: Record "Agent Test Consumption Log";
        CopilotQuota: Codeunit "Copilot Quota";
    begin
        if CopilotQuota.IsNewMonetizationEnabled() then
            exit(GetAICredits('', true, PeriodStartDate, PeriodEndDate));
        AgentTestConsumptionLog.SetRange(Company, CompanyName());
        AgentTestConsumptionLog.SetFilter(SystemCreatedAt, '>=%1&<=%2', CreateDateTime(PeriodStartDate, 0T), CreateDateTime(PeriodEndDate, 235959.999T));
        AgentTestConsumptionLog.CalcSums("Copilot Credits");
        exit(AgentTestConsumptionLog."Copilot Credits");
    end;

    procedure GetSuiteCreditsForEnvironment(TestSuiteCode: Code[100]; PeriodStartDate: Date): Decimal
    begin
        exit(GetSuiteCreditsForEnvironment(TestSuiteCode, PeriodStartDate, DT2Date(CurrentDateTime())));
    end;

    procedure GetSuiteCreditsForEnvironment(TestSuiteCode: Code[100]; PeriodStartDate: Date; PeriodEndDate: Date): Decimal
    var
        AgentTestConsumptionLog: Record "Agent Test Consumption Log";
        CopilotQuota: Codeunit "Copilot Quota";
    begin
        if CopilotQuota.IsNewMonetizationEnabled() then
            exit(GetAICredits(TestSuiteCode, false, PeriodStartDate, PeriodEndDate));
        AgentTestConsumptionLog.SetRange("Test Suite Code", TestSuiteCode);
        AgentTestConsumptionLog.SetFilter(SystemCreatedAt, '>=%1&<=%2', CreateDateTime(PeriodStartDate, 0T), CreateDateTime(PeriodEndDate, 235959.999T));
        AgentTestConsumptionLog.CalcSums("Copilot Credits");
        exit(AgentTestConsumptionLog."Copilot Credits");
    end;

    procedure GetSuiteCreditsForCurrentCompany(TestSuiteCode: Code[100]; PeriodStartDate: Date): Decimal
    begin
        exit(GetSuiteCreditsForCurrentCompany(TestSuiteCode, PeriodStartDate, DT2Date(CurrentDateTime())));
    end;

    procedure GetSuiteCreditsForCurrentCompany(TestSuiteCode: Code[100]; PeriodStartDate: Date; PeriodEndDate: Date): Decimal
    var
        AgentTestConsumptionLog: Record "Agent Test Consumption Log";
        CopilotQuota: Codeunit "Copilot Quota";
    begin
        if CopilotQuota.IsNewMonetizationEnabled() then
            exit(GetAICredits(TestSuiteCode, true, PeriodStartDate, PeriodEndDate));
        AgentTestConsumptionLog.SetRange("Test Suite Code", TestSuiteCode);
        AgentTestConsumptionLog.SetRange(Company, CompanyName());
        AgentTestConsumptionLog.SetFilter(SystemCreatedAt, '>=%1&<=%2', CreateDateTime(PeriodStartDate, 0T), CreateDateTime(PeriodEndDate, 235959.999T));
        AgentTestConsumptionLog.CalcSums("Copilot Credits");
        exit(AgentTestConsumptionLog."Copilot Credits");
    end;

    procedure LogAIConsumption(TaskId: BigInteger; LogEntry: Record "AIT Log Entry")
    var
        Consumption: Record "Agent Eval AI Consumption";
        TaskLink: Record "Agent Eval AI Task Link";
        TaskCompany: Text[30];
    begin
        TaskCompany := CopyStr(CompanyName(), 1, MaxStrLen(TaskCompany));
        // The first eval link owns budget attribution. The primary key prevents duplicate
        // full-task charges across results, suites, and concurrent runs.
        if not Consumption.Get(TaskId, TaskCompany) then begin
            Consumption."Agent Task ID" := TaskId;
            Consumption.Company := TaskCompany;
            Consumption."Test Suite Code" := LogEntry."Test Suite Code";
            Consumption."Accounting Date" := Today();
            RefreshAIConsumption(Consumption);
            if not Consumption.Insert() then
                Consumption.Get(TaskId, TaskCompany);
        end;

        // Accounting links intentionally survive deletion of the diagnostic eval logs.
        if not TaskLink.Get(TaskId, TaskCompany, LogEntry.SystemId) then begin
            TaskLink."Agent Task ID" := TaskId;
            TaskLink.Company := TaskCompany;
            TaskLink."Test Suite Code" := LogEntry."Test Suite Code";
            TaskLink.Version := LogEntry.Version;
            TaskLink.Tag := LogEntry.Tag;
            TaskLink."Test Method Line No." := LogEntry."Test Method Line No.";
            TaskLink."Log Entry System ID" := LogEntry.SystemId;
            TaskLink."Log Entry No." := LogEntry."Entry No.";
            if not TaskLink.Insert() then
                TaskLink.Get(TaskId, TaskCompany, LogEntry.SystemId);
        end;
    end;

    procedure GetTaskAIConsumption(TaskId: BigInteger; TaskCompany: Text[30]; var Credits: Decimal; var Pending: Boolean)
    var
        Consumption: Record "Agent Eval AI Consumption";
        Quota: Codeunit "Copilot Quota";
    begin
        Consumption.Get(TaskId, TaskCompany);
        if Quota.IsNewMonetizationEnabled() then
            RefreshAIConsumption(Consumption);
        Credits := Consumption."AI Credits";
        Pending := Consumption."Pricing Pending";
    end;

    procedure ReconcileAIConsumption()
    var
        Consumption: Record "Agent Eval AI Consumption";
        CopilotQuota: Codeunit "Copilot Quota";
        Credits: Decimal;
        Pending: Boolean;
    begin
        if not CopilotQuota.IsNewMonetizationEnabled() then
            exit;
        Consumption.SetRange(Company, CompanyName());
        if Consumption.FindSet(true) then
            repeat
                Credits := Consumption."AI Credits";
                Pending := Consumption."Pricing Pending";
                RefreshAIConsumption(Consumption);
                if (Credits <> Consumption."AI Credits") or (Pending <> Consumption."Pricing Pending") then
                    Consumption.Modify();
            until Consumption.Next() = 0;
        ReconcileAIRunHistory();
    end;

    local procedure ReconcileAIRunHistory()
    var
        History: Record "AIT Run History";
        TaskLink: Record "Agent Eval AI Task Link";
        Credits: Decimal;
        Pending: Boolean;
        Changed: Boolean;
    begin
        if History.FindSet(true) then
            repeat
                Changed := false;
                TaskLink.Reset();
                TaskLink.SetRange(Company, CompanyName());
                TaskLink.SetRange("Test Suite Code", History."Test Suite Code");
                TaskLink.SetRange(Version, History.Version);
                if GetStoredAICredits(TaskLink, Credits, Pending) then begin
                    Changed := (History."AI Credits" <> Credits) or (History."AI Pricing Pending" <> Pending);
                    History."AI Credits" := Credits;
                    History."AI Pricing Pending" := Pending;
                end;
                TaskLink.SetRange(Version);
                if History.Tag <> '' then
                    TaskLink.SetRange(Tag, History.Tag);
                if GetStoredAICredits(TaskLink, Credits, Pending) then begin
                    Changed := Changed or (History."AI Credits - By Tag" <> Credits) or (History."AI Pricing Pending - By Tag" <> Pending);
                    History."AI Credits - By Tag" := Credits;
                    History."AI Pricing Pending - By Tag" := Pending;
                end;
                if Changed then
                    History.Modify();
            until History.Next() = 0;
    end;

    local procedure GetStoredAICredits(var TaskLink: Record "Agent Eval AI Task Link"; var Credits: Decimal; var Pending: Boolean): Boolean
    var
        Consumption: Record "Agent Eval AI Consumption";
        SeenTasks: List of [BigInteger];
    begin
        Credits := 0;
        Pending := false;
        if not TaskLink.FindSet() then
            exit(false);
        repeat
            if not SeenTasks.Contains(TaskLink."Agent Task ID") then begin
                SeenTasks.Add(TaskLink."Agent Task ID");
                Consumption.Get(TaskLink."Agent Task ID", TaskLink.Company);
                Credits += Consumption."AI Credits";
                Pending := Pending or Consumption."Pricing Pending";
            end;
        until TaskLink.Next() = 0;
        exit(true);
    end;

    procedure GetPendingAITaskCount(PeriodStartDate: Date; CurrentCompanyOnly: Boolean): Integer
    var
        Consumption: Record "Agent Eval AI Consumption";
        PendingCount: Integer;
    begin
        Consumption.SetRange("Accounting Date", PeriodStartDate, Today());
        if CurrentCompanyOnly then
            Consumption.SetRange(Company, CompanyName());
        if Consumption.FindSet() then
            repeat
                RefreshAIConsumption(Consumption);
                if Consumption."Pricing Pending" then
                    PendingCount += 1;
            until Consumption.Next() = 0;
        exit(PendingCount);
    end;

    local procedure GetAICredits(SuiteCode: Code[100]; CurrentCompanyOnly: Boolean; PeriodStartDate: Date; PeriodEndDate: Date): Decimal
    var
        Consumption: Record "Agent Eval AI Consumption";
        Total: Decimal;
    begin
        Consumption.SetRange("Accounting Date", PeriodStartDate, PeriodEndDate);
        if SuiteCode <> '' then
            Consumption.SetRange("Test Suite Code", SuiteCode);
        if CurrentCompanyOnly then
            Consumption.SetRange(Company, CompanyName());
        if Consumption.FindSet() then
            repeat
                // Refresh in memory as well, so read-only consumers never write during a quota read.
                RefreshAIConsumption(Consumption);
                Total += Consumption."AI Credits";
            until Consumption.Next() = 0;
        exit(Total);
    end;

    local procedure RefreshAIConsumption(var Consumption: Record "Agent Eval AI Consumption")
    var
        Overview: Codeunit "Agent Consumption Overview";
        Credits: Decimal;
        Pending: Boolean;
        HasEntries: Boolean;
        ConsumptionUnavailableMsg: Label 'AI consumption could not be refreshed because the task is unavailable or inaccessible. Retaining the last snapshot for task %1.', Locked = true;
    begin
        if Overview.TryGetAIConsumption(Consumption."Agent Task ID", Consumption.Company, Credits, Pending, HasEntries) then begin
            if HasEntries then
                Consumption."AI Credits" := Credits;
            Consumption."Pricing Pending" := Pending;
        end else begin
            Consumption."Pricing Pending" := true;
            Session.LogMessage('AITAI0001', StrSubstNo(ConsumptionUnavailableMsg, Consumption."Agent Task ID"), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher);
        end;
    end;
}
