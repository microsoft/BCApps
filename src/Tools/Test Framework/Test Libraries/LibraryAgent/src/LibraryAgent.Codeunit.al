// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Agents;

using System.Agents;
using System.TestTools.TestRunner;

/// <summary>
/// Provides test helper functions for creating and managing agent tasks, messages, and user interventions.
/// This library simplifies agent testing by providing convenient methods to create tasks, simulate user input,
/// wait for task completion, and capture test output.
/// </summary>
codeunit 130560 "Library - Agent"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    #region Manage Agent Tasks

    /// <summary>
    /// Creates a new agent task and waits for the task to complete.
    /// </summary>
    /// <param name="AgentTaskBuilder">The agent task builder codeunit used to configure and create the task.</param>
    /// <returns>True if the task completed successfully; false if it timed out or failed.</returns>
    procedure CreateTaskAndWait(var AgentTaskBuilder: Codeunit "Agent Task Builder"): Boolean
    var
        CreatedAgentTask: Record "Agent Task";
    begin
        exit(LibraryAgentImpl.CreateTaskAndWait(AgentTaskBuilder, CreatedAgentTask));
    end;

    /// <summary>
    /// Creates a new agent task and waits for the task to complete.
    /// </summary>
    /// <param name="AgentTaskBuilder">The agent task builder codeunit used to configure and create the task.</param>
    /// <param name="CreatedAgentTask">The record of the created agent task.</param>
    /// <returns>True if the task completed successfully; false if it timed out or failed.</returns>
    procedure CreateTaskAndWait(var AgentTaskBuilder: Codeunit "Agent Task Builder"; var CreatedAgentTask: Record "Agent Task"): Boolean
    begin
        exit(LibraryAgentImpl.CreateTaskAndWait(AgentTaskBuilder, CreatedAgentTask));
    end;

    /// <summary>
    /// Stops all tasks for all agents.
    /// Use this to clean up tasks during test teardown.
    /// </summary>
    [Scope('OnPrem')]
    procedure StopAllTasks()
    begin
        LibraryAgentImpl.StopAllTasks();
    end;

    /// <summary>
    /// Stops all agent tasks for a specific agent.
    /// Use this to clean up tasks during test teardown.
    /// </summary>
    /// <param name="AgentUserSecurityId">The unique identifier of the agent whose tasks should be deactivated.</param>
    procedure StopTasks(AgentUserSecurityId: Guid)
    begin
        LibraryAgentImpl.StopTasks(AgentUserSecurityId);
    end;

    /// <summary>
    /// Continues a paused task or the task that is waiting for user input.
    /// This convenience method creates a user intervention, marks output messages as sent, and waits for the task to complete.
    /// </summary>
    /// <param name="AgentTask">The agent task to continue. Will be refreshed with updated state.</param>
    /// <returns>True if the task completed successfully; false if it timed out or failed.</returns>
    procedure ContinueTaskAndWait(var AgentTask: Record "Agent Task"): Boolean
    var
        ContinueTaskTok: Label 'Continue Task', Locked = true;
    begin
        exit(LibraryAgentImpl.ContinueTaskAndWait(AgentTask, ContinueTaskTok));
    end;

    /// <summary>
    /// Continues a paused task or the task that is waiting for user input with custom user input.
    /// This convenience method creates a user intervention, marks output messages as sent, and waits for the task to complete.
    /// </summary>
    /// <param name="AgentTask">The agent task to continue. Will be refreshed with updated state.</param>
    /// <param name="UserInput">The user input text to provide when continuing the task.</param>
    /// <returns>True if the task completed successfully; false if it timed out or failed.</returns>
    procedure ContinueTaskAndWait(var AgentTask: Record "Agent Task"; UserInput: Text): Boolean
    begin
        exit(LibraryAgentImpl.ContinueTaskAndWait(AgentTask, UserInput));
    end;

    /// <summary>
    /// Waits for an agent task to complete, blocking until the task finishes or the default timeout is reached.
    /// This method should be used for end to end testing scenarios where the functionality to create task is invoked via product, e.g. through an action. 
    /// </summary>
    /// <param name="AgentTask">The agent task to wait for. Will be refreshed with final state.</param>
    /// <returns>True if the task completed successfully; false if it timed out or failed.</returns>
    procedure WaitForTaskToComplete(var AgentTask: Record "Agent Task"): Boolean
    begin
        exit(LibraryAgentImpl.WaitForTaskToComplete(AgentTask));
    end;

    /// <summary>
    /// Writes the agent task details and log entries to a test output JSON structure.
    /// </summary>
    /// <param name="AgentTask">The agent task to write to output.</param>
    /// <param name="AgentTaskTestOutput">The test output JSON codeunit to write to.</param>
    procedure WriteTaskToOutput(var AgentTask: Record "Agent Task"; var AgentTaskTestOutput: Codeunit "Test Output Json")
    begin
        LibraryAgentImpl.WriteTaskToOutput(AgentTask, AgentTaskTestOutput);
    end;

    /// <summary>
    /// Writes the agent task details and log entries to a test output JSON structure, filtered from a specific date/time.
    /// </summary>
    /// <param name="AgentTask">The agent task to write to output.</param>
    /// <param name="AgentTaskTestOutput">The test output JSON codeunit to write to.</param>
    /// <param name="FromDateTime">Only include log entries from this date/time onwards.</param>
    procedure WriteTaskToOutput(var AgentTask: Record "Agent Task"; var AgentTaskTestOutput: Codeunit "Test Output Json"; FromDateTime: DateTime)
    begin
        LibraryAgentImpl.WriteTaskToOutput(AgentTask, AgentTaskTestOutput, FromDateTime);
    end;

    /// <summary>
    /// Writes the turn to output for an agent test including task details, success status, and error reason.
    /// Sets the answer used for evaluation in the AI Test Context.
    /// </summary>
    /// <param name="AgentTask">The agent task to write to output.</param>
    /// <param name="TurnSuccessful">Whether the turn completed successfully.</param>
    /// <param name="ErrorReason">The error reason if the turn failed.</param>
    procedure WriteTurnToOutput(var AgentTask: Record "Agent Task"; TurnSuccessful: Boolean; ErrorReason: Text)
    begin
        LibraryAgentImpl.WriteTurnToOutput(AgentTask, TurnSuccessful, ErrorReason);
    end;

    /// <summary>
    /// Sets the agent task timeout. This value will be used for waiting on all task related methods like <see cref="CreateTaskAndWait"/>, <see cref="ContinueTaskAndWait"/>, <see cref="WaitForTaskToComplete"/>, <see cref="CreateUserInterventionAndWait"/> and other similar methods.
    /// </summary>
    /// <param name="NewTimeout">The new timeout duration to set for all agent task operations.</param>
    procedure SetAgentTaskTimeout(NewTimeout: Duration)
    begin
        LibraryAgentImpl.SetAgentTaskTimeout(NewTimeout);
    end;
    #endregion

    #region Manage Agent Messages

    /// <summary>
    /// Creates a new message for an existing agent task. The method will start the task immediately and wait for the task to complete.
    /// The task status is set to Ready after the message is created.
    /// </summary>
    /// <param name="AgentTaskMessageBuilder">The agent task message builder codeunit used to create the message details and the target agent task. Returns with updated status set to Ready.</param>
    /// <returns>True if the task completed successfully; false if it timed out or failed.</returns>
    procedure CreateMessageAndWait(var AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder"): Boolean
    var
        AgentTask: Record "Agent Task";
    begin
        exit(LibraryAgentImpl.CreateMessageAndWait(AgentTaskMessageBuilder, AgentTask));
    end;

    /// <summary>
    /// Creates a new message for an existing agent task. The method will start the task immediately and wait for the task to complete.
    /// The task status is set to Ready after the message is created.
    /// </summary>
    /// <param name="AgentTaskMessageBuilder">The agent task message builder codeunit used to create the message details and the target agent task. Returns with updated status set to Ready.</param>
    /// <param name="AgentTask">The agent task record that the message is associated with.</param>
    /// <returns>True if the task completed successfully; false if it timed out or failed.</returns>
    procedure CreateMessageAndWait(var AgentTaskMessageBuilder: Codeunit "Agent Task Message Builder"; var AgentTask: Record "Agent Task"): Boolean
    begin
        exit(LibraryAgentImpl.CreateMessageAndWait(AgentTaskMessageBuilder, AgentTask));
    end;

    #endregion

    #region Manage User Interventions

    /// <summary>
    /// Parses the User Intervention Request Type from text to enum.
    /// This function is used in data driven testing where the intervention request type is provided as text input. 
    /// The type must be provided to match the ordinal enum value in English. No translations should be used. 
    /// </summary>
    /// <param name="UserInterventionRequestTypeText">The text representation of the user intervention request type.</param>
    /// <returns>The corresponding <see cref="Enum 'Agent User Int Request Type'"/> for the provided text. If the value does not exist, an error is thrown.</returns>
    procedure ParseUserInterventionRequestType(UserInterventionRequestTypeText: Text): Enum "Agent User Int Request Type"
    begin
        exit(LibraryAgentImpl.ParseUserInterventionRequestType(UserInterventionRequestTypeText));
    end;

    /// <summary>
    /// Specifies whether the task currently requires a user intervention to proceed further.
    /// </summary>
    /// <param name="AgentTask">The agent task record to check for user intervention requests.</param>
    /// <returns>True if the task requires user intervention; false otherwise.</returns>
    procedure RequiresUserIntervention(AgentTask: Record "Agent Task"): Boolean
    begin
        exit(LibraryAgentImpl.RequiresUserIntervention(AgentTask));
    end;

    /// <summary>
    /// Retrieves the details of the last user intervention request including any annotations.
    /// Call the <see cref="RequiresUserIntervention"/> method first to check if there is an active user intervention request before calling this method to retrieve the details.
    /// </summary>
    /// <remarks>The method may return the user intervention that was already handled.</remarks>
    /// <param name="AgentTask">The agent task record containing the user intervention request.</param>
    /// <param name="TempUserInterventionRequest">Returns a temporary record with the intervention request details.</param>
    /// <param name="TempUserInterventionAnnotation">Returns a temporary record with any intervention annotations.</param>
    /// <param name="TempUserInterventionSuggestion">Returns a temporary record with any intervention suggestions.</param>
    /// <returns>True if a user intervention request was found; false otherwise.</returns>
    procedure GetLastUserInterventionRequestDetails(AgentTask: Record "Agent Task"; var TempUserInterventionRequest: Record "Agent User Int Request Details" temporary; var TempUserInterventionAnnotation: Record "Agent Annotation" temporary; var TempUserInterventionSuggestion: Record "Agent Task User Int Suggestion" temporary): Boolean
    begin
        exit(LibraryAgentImpl.GetLastUserInterventionRequestDetails(AgentTask, TempUserInterventionRequest, TempUserInterventionAnnotation, TempUserInterventionSuggestion));
    end;

    /// <summary>
    /// Retrieves the details of a user intervention request including any annotations.
    /// </summary>
    /// <param name="UserInterventionRequestEntry">The log entry containing the user intervention request.</param>
    /// <param name="TempUserInterventionRequest">Returns a temporary record with the intervention request details.</param>
    /// <param name="TempUserInterventionAnnotation">Returns a temporary record with any intervention annotations.</param>
    procedure GetUserInterventionRequestDetails(UserInterventionRequestEntry: Record "Agent Task Log Entry"; var TempUserInterventionRequest: Record "Agent User Int Request Details" temporary; var TempUserInterventionAnnotation: Record "Agent Annotation" temporary)
    var
        TempUserInterventionSuggestion: Record "Agent Task User Int Suggestion" temporary;
    begin
        LibraryAgentImpl.GetUserInterventionRequestDetails(UserInterventionRequestEntry, TempUserInterventionRequest, TempUserInterventionAnnotation, TempUserInterventionSuggestion);
    end;

    /// <summary>
    /// Retrieves the details of a user intervention request including any annotations.
    /// </summary>
    /// <param name="UserInterventionRequestEntry">The log entry containing the user intervention request.</param>
    /// <param name="TempUserInterventionRequest">Returns a temporary record with the intervention request details.</param>
    /// <param name="TempUserInterventionAnnotation">Returns a temporary record with any intervention annotations.</param>
    /// <param name="TempUserInterventionSuggestion">Returns a temporary record with any intervention suggestions.</param>
    procedure GetUserInterventionRequestDetails(UserInterventionRequestEntry: Record "Agent Task Log Entry"; var TempUserInterventionRequest: Record "Agent User Int Request Details" temporary; var TempUserInterventionAnnotation: Record "Agent Annotation" temporary; var TempUserInterventionSuggestion: Record "Agent Task User Int Suggestion" temporary)
    begin
        LibraryAgentImpl.GetUserInterventionRequestDetails(UserInterventionRequestEntry, TempUserInterventionRequest, TempUserInterventionAnnotation, TempUserInterventionSuggestion);
    end;

    /// <summary>
    /// Creates a user intervention response and then waits for the agent task to complete.
    /// </summary>
    /// <param name="AgentTask">The agent task to create the intervention for. Will be refreshed with updated state.</param>
    /// <param name="UserInput">The user's text input for the intervention.</param>
    /// <returns>True if the intervention was created and the task completed successfully; false otherwise.</returns>
#pragma warning disable AS0022, AS0024, AS0026, AS0078
    procedure CreateUserInterventionAndWait(var AgentTask: Record "Agent Task"; UserInput: Text): Boolean
#pragma warning restore AS0022, AS0024, AS0026, AS0078
    begin
        exit(LibraryAgentImpl.CreateUserInterventionAndWait(AgentTask, UserInput));
    end;

    /// <summary>
    /// Creates a user intervention response and then waits for the agent task to complete.
    /// </summary>
    /// <param name="UserInterventionRequestEntry">The log entry containing the intervention request to respond to.</param>
    /// <param name="SuggestionCode">The code of the suggestion selected by the user.</param>
    /// <returns>True if the intervention was created and the task completed successfully; false otherwise.</returns>
    procedure CreateUserInterventionFromSuggestionAndWait(var AgentTask: Record "Agent Task"; SuggestionCode: Code[20]): Boolean
    begin
        exit(LibraryAgentImpl.CreateUserInterventionFromSuggestionAndWait(AgentTask, SuggestionCode));
    end;

    #endregion

    #region Data-Driven Turn Processing

    /// <summary>
    /// Provides input to the agent based on the current turn's query and waits for the task to complete.
    /// For task input queries (detected by 'title' element): creates a task with from, title, message, and attachments.
    /// For intervention queries (detected by 'intervention' element): responds with a suggestion code or free-text instruction.
    /// Throws an error if the query contains both 'title' and 'intervention', or neither.
    /// We recommend using this method instead of using the granular methods that are defined below.
    /// </summary>
    /// <param name="AgentUserSecurityId">The security ID of the agent user to give the task to.</param>
    /// <param name="AgentTask">The agent task record. Task will be created for input queries; must be the existing task for interventions.</param>
    /// <param name="AgentTestResourceProvider">Interface for resolving attachment files from the consuming test app's resources.</param>
    /// <returns>True if the task completed without unexpected errors. This does not mean the task produced correct results — only that it finished. False indicates an unexpected error or timeout.</returns>
    procedure RunTurnAndWait(AgentUserSecurityId: Guid; var AgentTask: Record "Agent Task"; AgentTestResourceProvider: Interface IAgentTestResourceProvider): Boolean
    begin
        exit(LibraryAgentImpl.RunTurnAndWait(AgentUserSecurityId, AgentTask, true, AgentTestResourceProvider));
    end;

    /// <summary>
    /// Provides input to the agent based on the current turn's query and waits for the task to complete.
    /// Overload without attachment support — use when the query has no attachments.
    /// We recommend using this method instead of using the granular methods that are defined below.
    /// </summary>
    /// <param name="AgentUserSecurityId">The security ID of the agent user to give the task to.</param>
    /// <param name="AgentTask">The agent task record. Task will be created for input queries; must be the existing task for interventions.</param>
    /// <returns>True if the task completed without unexpected errors. This does not mean the task produced correct results — only that it finished. False indicates an unexpected error or timeout.</returns>
    procedure RunTurnAndWait(AgentUserSecurityId: Guid; var AgentTask: Record "Agent Task"): Boolean
    var
        NoOpResourceProvider: Codeunit "NoOp Agent Test Res. Provider";
    begin
        exit(LibraryAgentImpl.RunTurnAndWait(AgentUserSecurityId, AgentTask, false, NoOpResourceProvider));
    end;

    /// <summary>
    /// Gets the expected intervention request from the current turn's expected data.
    /// Uses AITTestContext.GetExpectedData() which is multi-turn aware (resolves to current turn).
    /// </summary>
    /// <param name="ExpectedInterventionRequest">Returns the intervention_request element if found.</param>
    /// <returns>True if the current turn's expected data contains an intervention_request.</returns>
    procedure GetExpectedInterventionRequest(var ExpectedInterventionRequest: Codeunit "Test Input Json"): Boolean
    begin
        exit(LibraryAgentImpl.GetExpectedInterventionRequest(ExpectedInterventionRequest));
    end;

    /// <summary>
    /// Validates the current intervention request against expected data from the test input.
    /// Uses Assert to fail the test with a descriptive message if any check fails.
    /// Checks that the task requires intervention, the type matches, and expected suggestions are present.
    /// </summary>
    /// <param name="AgentTask">The agent task to validate.</param>
    /// <param name="ExpectedInterventionRequest">The expected intervention request data from the YAML.</param>
    procedure ValidateInterventionRequest(AgentTask: Record "Agent Task"; ExpectedInterventionRequest: Codeunit "Test Input Json")
    begin
        LibraryAgentImpl.ValidateInterventionRequest(AgentTask, ExpectedInterventionRequest);
    end;

    /// <summary>
    /// Writes the turn output and determines if the test should continue to the next turn.
    /// Calls Commit() after writing output.
    /// Validates that the task did not pause for an unexpected intervention (no intervention_request in expected_data).
    /// </summary>
    /// <param name="AgentTask">The agent task for the current turn.</param>
    /// <param name="TurnSuccessful">Whether the current turn completed successfully.</param>
    /// <param name="ErrorReason">The error reason if the turn failed.</param>
    /// <returns>Continue is true if there is a next turn and the current turn was successful.</returns>
    procedure FinalizeTurn(var AgentTask: Record "Agent Task"; TurnSuccessful: Boolean; ErrorReason: Text) Continue: Boolean
    begin
        Continue := LibraryAgentImpl.FinalizeTurn(AgentTask, TurnSuccessful, ErrorReason);
    end;

    #endregion

    #region Manage agent

    /// <summary>
    /// Gets the agent that is used by the test suite.
    /// This method can be used to enable A/B testing in the AI Evaluation Tool.
    /// You need to implement the logic in the test to create the agent or use already preconfigured agent.
    /// </summary>
    /// <param name="AgentUserSecurityID">The user security ID of the agent used by the test suite. If no agent is set, a null GUID is returned.</param>
    procedure GetAgentUnderTest(var AgentUserSecurityID: Guid)
    begin
        LibraryAgentImpl.GetAgentUnderTest(AgentUserSecurityID);
    end;

    /// <summary>
    /// Ensures the agent is active. If the agent is not active, it will be activated.
    /// </summary>
    /// <param name="AgentUserSecurityID">The user security ID of the agent to activate.</param>
    procedure EnsureAgentIsActive(AgentUserSecurityID: Guid)
    begin
        LibraryAgentImpl.EnsureAgentIsActive(AgentUserSecurityID);
    end;

    #endregion

    var
        LibraryAgentImpl: Codeunit "Library - Agent Impl.";
}