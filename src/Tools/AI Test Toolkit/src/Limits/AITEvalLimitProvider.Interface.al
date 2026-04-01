// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

/// <summary>
/// Strategy interface for eval execution limit checking.
///
/// Lifecycle during a test suite run:
///   1. CheckBeforeRun — called once before the suite starts. Raises Error() to block.
///   2. IsLimitReached — called at various points (per-line, per-method) during execution.
///
/// UI integration:
///   3. ShowNotifications — called on page open to display limit/warning/disabled notifications.
///   4. OpenConfigurationPage — opens the provider's configuration page.
///
/// </summary>
interface "AIT Eval Limit Provider"
{
    Access = Internal;

    /// <summary>
    /// Pre-run gate. Called before the suite starts executing.
    /// An Error() must be raised to block execution if the limit is already reached.
    /// </summary>
    /// <param name="AITTestSuite">The test suite about to be run.</param>
    procedure CheckBeforeRun(AITTestSuite: Record "AIT Test Suite");

    /// <summary>
    /// Checks whether the execution limits have been reached.
    /// Called at multiple points during execution: before each test line,
    /// before/after each test method, and after line completion.
    /// </summary>
    /// <returns>True if the limit is reached and execution should stop.</returns>
    procedure IsLimitReached(): Boolean;

    /// <summary>
    /// Sends or recalls page-scoped notifications based on the current limit state.
    /// </summary>
    procedure ShowNotifications();

    /// <summary>
    /// Opens the configuration page for this limit provider.
    /// </summary>
    procedure OpenConfigurationPage();
}
