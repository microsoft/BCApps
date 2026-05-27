// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

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
    begin
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
    begin
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
    begin
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
    begin
        AgentTestConsumptionLog.SetRange("Test Suite Code", TestSuiteCode);
        AgentTestConsumptionLog.SetRange(Company, CompanyName());
        AgentTestConsumptionLog.SetFilter(SystemCreatedAt, '>=%1&<=%2', CreateDateTime(PeriodStartDate, 0T), CreateDateTime(PeriodEndDate, 235959.999T));
        AgentTestConsumptionLog.CalcSums("Copilot Credits");
        exit(AgentTestConsumptionLog."Copilot Credits");
    end;

}
