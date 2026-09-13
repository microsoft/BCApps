// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// A test configuration provider contributes one part of a test configuration, for example a random
/// seed, a WorkDate shift or an execution order. A configuration is a list of enabled providers, so
/// new behavior is added by implementing this interface and adding a value to enum
/// "Test Configuration Provider" - existing configurations do not have to change.
/// </summary>
interface "ITest Configuration Provider"
{
    /// <summary>
    /// Returns a human readable description of what this provider does.
    /// </summary>
    /// <returns>The description.</returns>
    procedure GetDescription(): Text;

    /// <summary>
    /// Reads the provider settings and writes the intent (seed, WorkDate shift, order, isolation)
    /// into the shared context before the base suite runs.
    /// </summary>
    /// <param name="Settings">The provider specific settings, for example { "seed": 2 }.</param>
    /// <param name="TestConfigurationContext">The shared run context to write intent into.</param>
    procedure Prepare(Settings: JsonObject; TestConfigurationContext: Codeunit "Test Configuration Context");

    /// <summary>
    /// Validates the provider settings before the run starts. A provider that cannot apply its
    /// settings safely must error here so the problem is reported before stability mode is entered
    /// and no state can leak into later runs. Providers without settings can leave the body empty.
    /// </summary>
    /// <param name="Settings">The provider specific settings.</param>
    procedure Validate(Settings: JsonObject);

    /// <summary>
    /// Applies per test method behavior (for example the WorkDate shift) before a test method runs.
    /// </summary>
    /// <param name="CurrentTestMethodLine">The test method line that is about to run.</param>
    /// <param name="Settings">The provider specific settings.</param>
    /// <param name="TestConfigurationContext">The shared run context.</param>
    procedure OnBeforeTestMethodRun(var CurrentTestMethodLine: Record "Test Method Line"; Settings: JsonObject; TestConfigurationContext: Codeunit "Test Configuration Context");

    /// <summary>
    /// Optional hook that runs after a test method has run. Providers that do not need it can leave
    /// the body empty.
    /// </summary>
    /// <param name="CurrentTestMethodLine">The test method line that ran.</param>
    /// <param name="IsSuccess">Whether the test method passed.</param>
    /// <param name="Settings">The provider specific settings.</param>
    /// <param name="TestConfigurationContext">The shared run context.</param>
    procedure OnAfterTestMethodRun(var CurrentTestMethodLine: Record "Test Method Line"; IsSuccess: Boolean; Settings: JsonObject; TestConfigurationContext: Codeunit "Test Configuration Context");
}
