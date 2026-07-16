// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.AI;
using System.Testability;

/// <summary>
/// Platform test-handler for language-first (<c>[TestDataSource]</c>) AI evals. When a migrated eval runs on the
/// platform test runner (e.g. <c>al runtests</c> / DME, with no AIT test suite context) this handler provides the
/// per-case bracketing that the classic <see cref="AIT Test Run Iteration"/> event subscribers provide under an AIT
/// suite: it resets per-case metrics before each case and writes one <see cref="AIT Log Entry"/> after each case.
/// Consuming test codeunits opt in via <c>TestHandlers = "AIT Test Handler"</c>.
///
/// The platform runs ITestHandler hooks OUTSIDE the per-function test-isolation scope, so the log entry written in
/// <c>OnAfterTestCaseRun</c> survives the case-level rollback and is persisted directly (no buffering/flushing).
/// </summary>
codeunit 149050 "AIT Test Handler" implements ITestHandler
{
    Access = Public;

    // Only the per-case hooks are implemented. The other four ITestHandler hooks use the interface's empty default
    // implementations — the platform test-handler framework treats a hook a handler does not override as a no-op.

    procedure OnBeforeTestCaseRun(Context: TestHandlerContext)
    var
        AITTestRunIteration: Codeunit "AIT Test Run Iteration";
        AITTestContextImpl: Codeunit "AIT Test Context Impl.";
        AITTestSuiteMgt: Codeunit "AIT Test Suite Mgt.";
        DDCurrentCase: Codeunit "AIT DD Current Case";
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
            exit;
        end;

        // Reset per-case accuracy/turns and open the run-procedure output scope, mirroring the classic
        // OnBeforeTestMethodRun setup so the test body's context.Set* calls attribute to this case.
        AITTestContextImpl.StartRunProcedureScenario();
        DDCurrentCase.SetCaseStart(CurrentDateTime(), AOAIToken.GetTotalServerSessionTokensConsumed());
    end;

    procedure OnAfterTestCaseRun(Context: TestHandlerContext)
    var
        AITTestRunIteration: Codeunit "AIT Test Run Iteration";
        AITTestSuiteMgt: Codeunit "AIT Test Suite Mgt.";
    begin
        if AITTestRunIteration.IsRunningUnderAITSuite() then
            exit;

        // This hook runs outside the per-function isolation scope, so the log entry persists past the case rollback.
        AITTestSuiteMgt.AddDataDrivenLogEntry(Context.CodeunitId, Context.ProcedureName, Context.TestCaseName, Context.Success);
    end;

    var
        CreditLimitReachedLbl: Label 'The monthly Copilot credit limit for AI evaluations has been reached. This case was skipped.';
}
