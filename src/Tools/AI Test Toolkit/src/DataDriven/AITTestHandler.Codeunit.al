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
        DDCurrentCase: Codeunit "AIT DD Current Case";
        AOAIToken: Codeunit "AOAI Token";
    begin
        // Under an AIT test suite the classic Test Runner - Mgt subscribers perform this bracketing and logging;
        // avoid duplicating it when the app-based runner is driving the suite.
        if AITTestRunIteration.IsRunningUnderAITSuite() then
            exit;

        // Reset per-case accuracy/turns and open the run-procedure output scope, mirroring the classic
        // OnBeforeTestMethodRun setup so the test body's context.Set* calls attribute to this case.
        AITTestContextImpl.StartRunProcedureScenario();
        DDCurrentCase.SetCaseStart(CurrentDateTime(), AOAIToken.GetTotalServerSessionTokensConsumed());
        DDCurrentCase.BeginPendingCase(Context.CodeunitId, Context.ProcedureName, Context.TestCaseName);
    end;

    procedure OnAfterTestCaseRun(Context: TestHandlerContext)
    var
        AITTestRunIteration: Codeunit "AIT Test Run Iteration";
        DDCurrentCase: Codeunit "AIT DD Current Case";
    begin
        if AITTestRunIteration.IsRunningUnderAITSuite() then
            exit;

        // NOTE (C8-A): this hook runs inside the per-function isolation scope, so DB writes here would be rolled back.
        // Record the outcome into the in-memory buffer (survives rollback); the actual AIT Log Entry is written from
        // AIT DD Current Case.OnAfterTestMethodRun, which runs outside that scope.
        DDCurrentCase.SetPendingSuccess(Context.Success);
    end;
}
