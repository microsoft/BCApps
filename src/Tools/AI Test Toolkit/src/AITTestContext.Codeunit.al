// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;
using System.TestTools.TestRunner;

/// <summary>
/// Exposes functions that can be used by the AI tests.
/// </summary>
codeunit 149044 "AIT Test Context"
{
    /// <summary>
    /// Sets to next turn.
    /// </summary>
    /// <returns>True if another turn exists</returns>
    procedure NextTurn(): Boolean
    begin
        exit(AITTestContextImpl.NextTurn());
    end;

    /// <summary>
    /// Gets the current turn. Turns start from turn 0.
    /// </summary>
    /// <returns>The current turn number.</returns>
    procedure GetCurrentTurn(): Integer
    begin
        exit(AITTestContextImpl.GetCurrentTurn());
    end;

    /// <summary>
    /// Returns the Test Input value as Test Input Json Codeunit from the input dataset for the current iteration.
    /// </summary>
    /// <returns>Test Input Json for the current test.</returns>
    procedure GetInput(): Codeunit "Test Input Json"
    begin
        exit(AITTestContextImpl.GetInput());
    end;

    /// <summary>
    /// Get the Test Setup from the input dataset for the current iteration.
    /// </summary>
    /// <returns>A Test Input Json codeunit for the test_setup element.</returns>
    procedure GetTestSetup(): Codeunit "Test Input Json"
    begin
        exit(AITTestContextImpl.GetTestSetup());
    end;

    /// <summary>
    /// Get the Context from the input dataset for the current iteration.
    /// </summary>
    /// <returns>A Test Input Json codeunit for the context element.</returns>
    procedure GetContext(): Codeunit "Test Input Json"
    begin
        exit(AITTestContextImpl.GetContext());
    end;

    /// <summary>
    /// Get the Question from the input dataset for the current iteration.
    /// </summary>
    /// <returns>A Test Input Json codeunit for the question element.</returns>
    procedure GetQuestion(): Codeunit "Test Input Json"
    begin
        exit(AITTestContextImpl.GetQuestion());
    end;

    /// <summary>
    /// Get the Ground Truth from the input dataset for the current iteration.
    /// </summary>
    /// <returns>A Test Input Json codeunit for the ground_truth element.</returns>
    procedure GetGroundTruth(): Codeunit "Test Input Json"
    begin
        exit(AITTestContextImpl.GetGroundTruth());
    end;

    /// <summary>
    /// Get the Expected Data value as text from the input dataset for the current iteration.
    /// Expected data is used for internal validation if the test was successful.
    /// </summary>
    /// <returns>Test Input Json for the expected data</returns>
    procedure GetExpectedData(): Codeunit "Test Input Json"
    begin
        exit(AITTestContextImpl.GetExpectedData());
    end;

    /// <summary>
    /// Sets the answer for a question and answer evaluation.
    /// This will also copy the context, question and ground truth to the output dataset.
    /// </summary>
    /// <param name="Answer">The answer as text.</param>
    procedure SetAnswerForQnAEvaluation(Answer: Text)
    begin
        AITTestContextImpl.SetAnswerForQnAEvaluation(Answer);
    end;

    /// <summary>
    /// Sets the query and respone for a single-turn evaluation.
    /// Optionally, a context can be provided.
    /// </summary>
    /// <param name="Query">The query as text.</param>
    /// <param name="Response">The response as text.</param>
    /// <param name="Context">The context as text.</param>
    procedure SetQueryResponse(Query: Text; Response: Text; Context: Text)
    begin
        AITTestContextImpl.SetQueryResponse(Query, Response, Context);
    end;

    /// <summary>
    /// Sets the query and response for a single-turn evaluation.
    /// </summary>
    /// <param name="Query">The query as text.</param>
    /// <param name="Response">The response as text.</param>
    procedure SetQueryResponse(Query: Text; Response: Text)
    begin
        AITTestContextImpl.SetQueryResponse(Query, Response, '');
    end;

    /// <summary>
    /// Adds a message to the current test iteration.
    /// This is used for multi-turn tests to add messages to the output.
    /// </summary>
    /// <param name="Content">The content of the message.</param>
    /// <param name="Role">The role of the message (e.g., 'user', 'assistant').</param>
    /// <param name="Context">The context of the message.</param>
    procedure AddMessage(Content: Text; Role: Text; Context: Text)
    begin
        AITTestContextImpl.AddMessage(Content, Role, Context);
    end;

    /// <summary>
    /// Adds a message to the current test iteration.
    /// This is used for multi-turn tests to add messages to the output.
    /// </summary>
    /// <param name="Content">The content of the message.</param>
    /// <param name="Role">The role of the message (e.g., 'user', 'assistant').</param>
    procedure AddMessage(Content: Text; Role: Text)
    begin
        AITTestContextImpl.AddMessage(Content, Role, '');
    end;

    /// <summary>
    /// Sets the test output for the current iteration.
    /// </summary>
    /// <param name="TestOutputJson">The test output.</param>
    procedure SetTestOutput(TestOutputJson: Codeunit "Test Output Json")
    begin
        AITTestContextImpl.SetTestOutput(TestOutputJson);
    end;

    /// <summary>
    /// Sets the test output for the current iteration.
    /// </summary>
    /// <param name="TestOutputText">The test output as text.</param>
    procedure SetTestOutput(TestOutputText: Text)
    begin
        AITTestContextImpl.SetTestOutput(TestOutputText);
    end;

    /// <summary>
    /// Sets the test output for the current iteration.
    /// </summary>
    /// <param name="Context">The context as text.</param>
    /// <param name="Question">The question as text.</param>
    /// <param name="Answer">The answer as text.</param>
    procedure SetTestOutput(Context: Text; Question: Text; Answer: Text)
    begin
        AITTestContextImpl.SetTestOutput(Context, Question, Answer);
    end;

    /// <summary>
    /// Sets the test metric for the output dataset.
    /// </summary>
    /// <param name="TestMetric">The test metric as text.</param>
    procedure SetTestMetric(TestMetric: Text)
    begin
        AITTestContextImpl.SetTestMetric(TestMetric);
    end;

    /// <summary>
    /// Sets the accuracy of the test.
    /// </summary>
    /// <param name="Accuracy">The accuracy as a decimal between 0 and 1.</param>
    procedure SetAccuracy(Accuracy: Decimal)
    begin
        AITTestContextImpl.SetAccuracy(Accuracy);
    end;

    /// <summary>
    /// Gets the AITTestSuite associated with the run.
    /// </summary>
    /// <param name="AITTestSuite">AITTestSuite associated with the run.</param>
    procedure GetAITTestSuite(var AITTestSuite: Record "AIT Test Suite")
    begin
        AITTestContextImpl.GetAITTestSuite(AITTestSuite);
    end;

    /// <summary>
    /// Integration event that is raised after a test run is completed.
    /// </summary>
    /// <param name="Code">The code of the test run.</param>
    /// <param name="Version">The version of the test run.</param>
    /// <param name="Tag">The tag of the test run.</param>
    [IntegrationEvent(false, false)]
    internal procedure OnAfterRunComplete(Code: Code[10]; Version: Integer; Tag: Text[20])
    begin
    end;

    var
        AITTestContextImpl: Codeunit "AIT Test Context Impl.";
}