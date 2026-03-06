// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

/// <summary>
/// Exposes Agent specific functionality that can be used by the AI tests.
/// </summary>
codeunit 149048 "Agent Test Context"
{
    SingleInstance = true;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Gets the user security ID of the agent that is used by the test suite.
    /// </summary>
    /// <param name="AgentUserSecurityID">The user security ID of the agent used by the test suite. If no agent is set, a null GUID is returned.</param>
    procedure GetAgentUserSecurityID(var AgentUserSecurityID: Guid)
    begin
        AgentTestContextImpl.GetAgentUserSecurityID(AgentUserSecurityID);
    end;

    /// <summary>
    /// Adds agent task to be reported as used by the test
    /// </summary>
    /// <param name="AgentTaskId">The id of the agent task to be added to the log.</param>
    procedure AddTaskToLog(AgentTaskId: BigInteger)
    begin
        AgentTestContextImpl.AddTaskToLog(AgentTaskId);
    end;

    var
        AgentTestContextImpl: Codeunit "Agent Test Context Impl.";
}