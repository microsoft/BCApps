// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.AI;
using System.Testability;
using System.TestTools.TestRunner;

/// <summary>
/// Platform test-handler for language-first (<c>[TestDataSource]</c>) AI evals. When a migrated eval runs on the
/// platform test runner (e.g. <c>al runtests</c> / DME, with no AIT test suite context) this handler provides the
/// per-case bracketing that the classic <see cref="AIT Test Run Iteration"/> event subscribers provide under an AIT
/// suite: it resets per-case metrics before each case and writes one <see cref="AIT Log Entry"/> after each case.
/// Consuming test codeunits opt in via <c>TestHandlers = "AIT Test Handler"</c>.
///
/// The platform runs ITestHandler hooks outside test isolation, so the log entry written in
/// <c>OnAfterTestCaseRun</c> is persisted independently of the test body's transaction.
/// </summary>
codeunit 149050 "AIT Test Handler" implements ITestHandler
{
    Access = Public;

    procedure OnBeforeTestCodeunitRun(Context: TestHandlerContext)
    var
        AITTestRunIteration: Codeunit "AIT Test Run Iteration";
        TestDataSourceContext: Codeunit "Test Data Source Context";
    begin
        if not AITTestRunIteration.IsRunningUnderAITSuite() then
            TestDataSourceContext.StartRunIfNeeded(Context.CodeunitId());
    end;

    procedure OnAfterTestCodeunitRun(Context: TestHandlerContext)
    var
        AITTestRunIteration: Codeunit "AIT Test Run Iteration";
        AITTestCaseState: Codeunit "AIT Test Case State";
        TestDataSourceContext: Codeunit "Test Data Source Context";
    begin
        if AITTestRunIteration.IsRunningUnderAITSuite() then
            exit;

        TestDataSourceContext.EndRunIfOwned(Context.CodeunitId());
        AITTestCaseState.Reset();
    end;

    procedure OnBeforeTestCaseRun(Context: TestHandlerContext)
    var
        AITTestRunIteration: Codeunit "AIT Test Run Iteration";
        AITTestContextImpl: Codeunit "AIT Test Context Impl.";
        AITTestSuiteMgt: Codeunit "AIT Test Suite Mgt.";
        AITTestCaseState: Codeunit "AIT Test Case State";
        TestDataSourceContext: Codeunit "Test Data Source Context";
        MonthlyCopilotCredLimit: Codeunit "AIT Eval Monthly Copilot Cred.";
        AOAIToken: Codeunit "AOAI Token";
    begin
        // Under an AIT test suite the classic Test Runner - Mgt subscribers perform this bracketing and logging;
        // avoid duplicating it when the app-based runner is driving the suite.
        if AITTestRunIteration.IsRunningUnderAITSuite() then
            exit;

        // Honor the global monthly Copilot-credit limit for standalone platform-runner evals, mirroring the classic
        // app-suite behavior (AIT Test Run Iteration.OnBeforeTestMethodRun). When enforcement is enabled and the limit
        // is reached, skip the case (reported Skipped by the platform runner) and log a Skipped entry so the skip is
        // visible. Enforcement disabled (the default) -> IsLimitReached is false -> no-op.
        if MonthlyCopilotCredLimit.IsLimitReached() then begin
            Context.Skip(CreditLimitReachedLbl);
            AITTestSuiteMgt.LogSkippedDataDrivenEval(Context.CodeunitId(), Context.ProcedureName(), Context.TestCaseName(), CreditLimitReachedLbl);
            TestDataSourceContext.ClearCurrent();
            AITTestCaseState.Reset();
            exit;
        end;

        // Reset per-case accuracy/turns and open the run-procedure output scope, mirroring the classic
        // OnBeforeTestMethodRun setup so the test body's context.Set* calls attribute to this case.
        AITTestContextImpl.StartRunProcedureScenario();
        AITTestCaseState.SetCaseStart(CurrentDateTime(), AOAIToken.GetTotalServerSessionTokensConsumed());
    end;

    procedure OnAfterTestCaseRun(Context: TestHandlerContext)
    var
        AITTestRunIteration: Codeunit "AIT Test Run Iteration";
        AITTestSuiteMgt: Codeunit "AIT Test Suite Mgt.";
        AITTestCaseState: Codeunit "AIT Test Case State";
        TestDataSourceContext: Codeunit "Test Data Source Context";
    begin
        if AITTestRunIteration.IsRunningUnderAITSuite() then
            exit;

        // This hook runs outside test isolation, so the log entry persists independently of the test body.
        AITTestSuiteMgt.AddDataDrivenLogEntry(Context.CodeunitId, Context.ProcedureName, Context.TestCaseName, Context.Success);
        TestDataSourceContext.ClearCurrent();
        AITTestCaseState.Reset();
    end;

    var
        CreditLimitReachedLbl: Label 'The monthly Copilot credit limit for AI evaluations has been reached. This case was skipped.';
}
