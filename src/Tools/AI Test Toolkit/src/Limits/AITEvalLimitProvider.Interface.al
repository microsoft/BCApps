// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

/// <summary>
/// Strategy interface for eval execution limit checking.
///
/// Dispatched via the "AIT Test Type" enum: each test type (Copilot, Agent, MCP)
/// maps to an implementation that defines its own limit-checking behavior.
/// The default implementation ("AIT Eval No Limit") is a null object — all methods
/// are no-ops and IsLimitReached() returns false.
///
/// Lifecycle during a test suite run:
///   1. CheckBeforeRun — called once before the suite starts. Raises Error() to block.
///   2. IsLimitReached — called repeatedly (per-line, per-method) during execution.
///   3. HandleLimitReached — called when IsLimitReached() returns true in the run loop.
///      Sets suite status to CreditLimitReached and marks remaining lines as Skipped.
///
/// UI integration:
///   4. ShowNotifications — called on page open to display limit/warning/disabled notifications.
///   5. OpenSetupPage — opens the provider's configuration page.
///
/// Implementations must be stateless: every call to IsLimitReached() should query
/// current data rather than relying on cached state.
/// </summary>
interface "AIT Eval Limit Provider"
{
    /// <summary>
    /// Pre-run gate. Called before the suite starts executing.
    /// Must raise Error() if the limit is already reached, providing the limit
    /// and current consumption in the error message.
    /// For no-limit implementations, this is a no-op.
    /// </summary>
    /// <param name="AITTestSuite">The test suite about to be run.</param>
    procedure CheckBeforeRun(AITTestSuite: Record "AIT Test Suite");

    /// <summary>
    /// Stateless check whether the execution limit has been reached.
    /// Called at multiple points during execution: before each test line,
    /// before/after each test method, and after line completion.
    /// Must query current data on every call (no caching).
    /// </summary>
    /// <returns>True if the limit is reached and execution should stop.</returns>
    procedure IsLimitReached(): Boolean;

    /// <summary>
    /// Handles the transition when a limit is reached during execution.
    /// Sets the suite status to CreditLimitReached and marks all pending,
    /// running, and not-started test method lines as Skipped.
    /// Called by the run loop when IsLimitReached() returns true.
    /// </summary>
    /// <param name="AITTestSuite">The test suite whose status will be updated.</param>
    procedure HandleLimitReached(var AITTestSuite: Record "AIT Test Suite");

    /// <summary>
    /// Sends or recalls page-scoped notifications based on the current limit state.
    /// Called on page open (OnAfterGetCurrRecord) in the test suite page.
    /// Manages three mutually exclusive notification states:
    /// enforcement disabled, limit reached, or approaching limit (80%+).
    /// For no-limit implementations, this is a no-op.
    /// </summary>
    procedure ShowNotifications();

    /// <summary>
    /// Opens the configuration page for this limit provider.
    /// Also used as the action handler for notification drill-down actions.
    /// For no-limit implementations, this is a no-op.
    /// </summary>
    procedure OpenSetupPage();
}
