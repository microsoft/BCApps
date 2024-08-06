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
    /// Get the AOAI Model Version for the AI Test Suite.
    /// </summary>
    /// <returns>The AOAI Model Version as an Option.</returns>
    procedure GetAOAIModelVersion(): Option
    begin
        exit(AITTestContextImpl.GetAOAIModelVersion());
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

    var
        AITTestContextImpl: Codeunit "AIT Test Context Impl.";
}