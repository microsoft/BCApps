// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

codeunit 149050 "AIT Credit Limit Mgt."
{
    Access = Internal;
    SingleInstance = true;

    var
        CreditLimitReachedDuringRun: Boolean;
        GlobalCreditLimitExceededErr: Label 'Cannot start the agent test suite. The monthly credit limit of %1 has been reached. Current consumption: %2.', Comment = '%1 = Credit limit, %2 = Credits consumed';

    procedure ResetCreditLimitFlag()
    begin
        CreditLimitReachedDuringRun := false;
    end;

    procedure IsCreditLimitReachedDuringRun(): Boolean
    begin
        exit(CreditLimitReachedDuringRun);
    end;

    procedure SetCreditLimitReachedDuringRun()
    begin
        CreditLimitReachedDuringRun := true;
    end;

    procedure CheckCreditLimitBeforeRun(AITTestSuite: Record "AIT Test Suite"): Boolean
    var
        AITCreditLimitSetup: Record "AIT Credit Limit Setup";
        AgentTestContextImpl: Codeunit "Agent Test Context Impl.";
        TotalCreditsConsumed: Decimal;
    begin
        // Only check for Agent type test suites
        if AITTestSuite."Test Type" <> AITTestSuite."Test Type"::Agent then
            exit(true);

        AITCreditLimitSetup.GetOrCreate();

        // If enforcement is disabled, allow the run
        if not AITCreditLimitSetup."Enforcement Enabled" then
            exit(true);

        // If no limit is set, allow the run
        if AITCreditLimitSetup."Monthly Credit Limit" <= 0 then
            exit(true);

        // Check global credit limit
        TotalCreditsConsumed := AgentTestContextImpl.GetTotalCreditsConsumedThisMonth(AITCreditLimitSetup.GetPeriodStartDate());
        if TotalCreditsConsumed >= AITCreditLimitSetup."Monthly Credit Limit" then begin
            Error(GlobalCreditLimitExceededErr, AITCreditLimitSetup."Monthly Credit Limit", TotalCreditsConsumed);
            exit(false);
        end;

        exit(true);
    end;

    procedure CheckCreditLimitDuringRun(AITTestSuite: Record "AIT Test Suite"): Boolean
    var
        AITCreditLimitSetup: Record "AIT Credit Limit Setup";
        AgentTestContextImpl: Codeunit "Agent Test Context Impl.";
        TotalCreditsConsumed: Decimal;
    begin
        // Only check for Agent type test suites
        if AITTestSuite."Test Type" <> AITTestSuite."Test Type"::Agent then
            exit(true);

        AITCreditLimitSetup.GetOrCreate();

        // If enforcement is disabled, continue
        if not AITCreditLimitSetup."Enforcement Enabled" then
            exit(true);

        // If no limit is set, continue
        if AITCreditLimitSetup."Monthly Credit Limit" <= 0 then
            exit(true);

        // Check global credit limit
        TotalCreditsConsumed := AgentTestContextImpl.GetTotalCreditsConsumedThisMonth(AITCreditLimitSetup.GetPeriodStartDate());
        if TotalCreditsConsumed >= AITCreditLimitSetup."Monthly Credit Limit" then
            exit(false);

        exit(true);
    end;

    procedure SetCreditLimitReachedStatus(var AITTestSuite: Record "AIT Test Suite")
    var
        AITTestMethodLine: Record "AIT Test Method Line";
        AITTestSuiteMgt: Codeunit "AIT Test Suite Mgt.";
    begin
        AITTestSuiteMgt.SetRunStatus(AITTestSuite, AITTestSuite.Status::CreditLimitReached);

        AITTestMethodLine.SetRange("Test Suite Code", AITTestSuite.Code);
        AITTestMethodLine.SetRange(Status, AITTestMethodLine.Status::Running);
        AITTestMethodLine.ModifyAll(Status, AITTestMethodLine.Status::Skipped, true);

        AITTestMethodLine.SetRange("Test Suite Code", AITTestSuite.Code);
        AITTestMethodLine.SetRange(Status, AITTestMethodLine.Status::Starting);
        AITTestMethodLine.ModifyAll(Status, AITTestMethodLine.Status::Skipped, true);

        AITTestMethodLine.SetRange(Status, AITTestMethodLine.Status::" ");
        AITTestMethodLine.ModifyAll(Status, AITTestMethodLine.Status::Skipped, true);
    end;

    procedure IsGlobalCreditLimitExceeded(): Boolean
    var
        AITCreditLimitSetup: Record "AIT Credit Limit Setup";
        AgentTestContextImpl: Codeunit "Agent Test Context Impl.";
        TotalCreditsConsumed: Decimal;
    begin
        AITCreditLimitSetup.GetOrCreate();

        if not AITCreditLimitSetup."Enforcement Enabled" then
            exit(false);

        if AITCreditLimitSetup."Monthly Credit Limit" <= 0 then
            exit(false);

        TotalCreditsConsumed := AgentTestContextImpl.GetTotalCreditsConsumedThisMonth(AITCreditLimitSetup.GetPeriodStartDate());
        exit(TotalCreditsConsumed >= AITCreditLimitSetup."Monthly Credit Limit");
    end;

    procedure CheckAndHandleCreditLimitAfterTest(AITTestSuite: Record "AIT Test Suite")
    begin
        if AITTestSuite."Test Type" <> AITTestSuite."Test Type"::Agent then
            exit;

        if IsCreditLimitReachedDuringRun() then
            exit;

        if IsGlobalCreditLimitExceeded() then
            SetCreditLimitReachedDuringRun();
    end;

    procedure ShouldSkipTestDueToCreditLimit(): Boolean
    begin
        exit(IsCreditLimitReachedDuringRun());
    end;

    procedure OpenCreditLimitsPage(Notification: Notification)
    begin
        Page.Run(Page::"AIT Credit Limits");
    end;

    procedure GetCreditUsagePercentage(): Decimal
    var
        AITCreditLimitSetup: Record "AIT Credit Limit Setup";
        AgentTestContextImpl: Codeunit "Agent Test Context Impl.";
        TotalCreditsConsumed: Decimal;
    begin
        AITCreditLimitSetup.GetOrCreate();

        if AITCreditLimitSetup."Monthly Credit Limit" <= 0 then
            exit(0);

        TotalCreditsConsumed := AgentTestContextImpl.GetTotalCreditsConsumedThisMonth(AITCreditLimitSetup.GetPeriodStartDate());
        exit(Round(TotalCreditsConsumed / AITCreditLimitSetup."Monthly Credit Limit" * 100, 0.1));
    end;

    procedure IsApproachingCreditLimit(): Boolean
    begin
        exit(GetCreditUsagePercentage() >= 80);
    end;
}
