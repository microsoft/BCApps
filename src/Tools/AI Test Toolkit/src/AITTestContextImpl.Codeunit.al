// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;
using System.TestTools.TestRunner;

/// <summary>
/// Exposes functions that can be used by the AI tests.
/// </summary>
codeunit 149043 "AIT Test Context Impl."
{
    SingleInstance = true;
    Access = Internal;

    var
        AITTestSuiteMgt: Codeunit "AIT Test Suite Mgt.";
        GlobalTestOutputJson: Codeunit "Test Output Json";
        CurrentTurn: Integer;
        NumberOfTurns: Integer;
        IsMultiTurn: Boolean;
        AnswerTok: Label 'answer', Locked = true;
        ContextTok: Label 'context', Locked = true;
        GroundTruthTok: Label 'ground_truth', Locked = true;
        ExpectedDataTok: Label 'expected_data', Locked = true;
        TestMetricsTok: Label 'test_metrics', Locked = true;
        TestSetupTok: Label 'test_setup', Locked = true;
        QuestionTok: Label 'question', Locked = true;
        TurnsTok: Label 'turns', Locked = true;

    /// <summary>
    /// Returns the Test Input value as Test Input Json Codeunit from the input dataset for the current iteration.
    /// </summary>
    /// <returns>Test Input Json for the current test.</returns>
    procedure GetInput() TestInputJson: Codeunit "Test Input Json"
    var
        TestInput: Codeunit "Test Input";
    begin
        TestInputJson := TestInput.GetTestInput();
    end;

    /// <summary>
    /// Get the Test Setup from the input dataset for the current iteration.
    /// </summary>
    /// <returns>A Test Input Json codeunit for the test_setup element.</returns>
    procedure GetTestSetup() TestInputJson: Codeunit "Test Input Json"
    begin
        TestInputJson := GetTestInput(TestSetupTok);
    end;

    /// <summary>
    /// Get the Context from the input dataset for the current iteration.
    /// </summary>
    /// <returns>A Test Input Json codeunit for the context element.</returns>
    procedure GetContext() TestInputJson: Codeunit "Test Input Json"
    begin
        TestInputJson := GetTestInput(ContextTok);
    end;

    /// <summary>
    /// Get the Question from the input dataset for the current iteration.
    /// </summary>
    /// <returns>A Test Input Json codeunit for the question element.</returns>
    procedure GetQuestion() TestInputJson: Codeunit "Test Input Json"
    begin
        TestInputJson := GetTestInput(QuestionTok);
    end;

    /// <summary>
    /// Get the Ground Truth from the input dataset for the current iteration.
    /// </summary>
    /// <returns>A Test Input Json codeunit for the ground_truth element.</returns>
    procedure GetGroundTruth() TestInputJson: Codeunit "Test Input Json"
    begin
        TestInputJson := GetTestInput(GroundTruthTok);
    end;

    /// <summary>
    /// Get the Expected Data value as text from the input dataset for the current iteration.
    /// Expected data is used for internal validation if the test was successful.
    /// </summary>
    /// <returns>Test Input Json for the expected data</returns>
    procedure GetExpectedData() TestInputJson: Codeunit "Test Input Json"
    begin
        TestInputJson := GetTestInput(ExpectedDataTok);
    end;

    /// <summary>
    /// Get the AOAI Model Version for the AI Test Suite.
    /// </summary>
    /// <returns>The AOAI Model Version as an Option.</returns>
    procedure GetAOAIModelVersion(): Option
    var
        AITTestSuite: Record "AIT Test Suite";
    begin
        GetAITTestSuite(AITTestSuite);
        exit(AITTestSuite."Model Version");
    end;

    /// <summary>
    /// Sets the answer for a question and answer evaluation.
    /// This will also copy the context, question and ground truth to the output dataset.
    /// </summary>
    /// <param name="Answer">The answer as text.</param>
    procedure SetAnswerForQnAEvaluation(Answer: Text)
    var
        CurrentTestOutputJson: Codeunit "Test Output Json";
    begin
        CurrentTestOutputJson.Add(AnswerTok, Answer);
        CopyElementToOutput(ContextTok, CurrentTestOutputJson);
        CopyElementToOutput(QuestionTok, CurrentTestOutputJson);
        CopyElementToOutput(GroundTruthTok, CurrentTestOutputJson);
        SetSuiteTestOutput(CurrentTestOutputJson.ToText());
    end;

    /// <summary>
    /// Sets the test output for the current iteration.
    /// </summary>
    /// <param name="TestOutputText">The test output as text.</param>
    procedure SetTestOutput(TestOutputText: Text)
    begin
        SetSuiteTestOutput(TestOutputText);
    end;

    /// <summary>
    /// Sets the test output for the current iteration.
    /// </summary>
    /// <param name="Context">The context as text.</param>
    /// <param name="Question">The question as text.</param>
    /// <param name="Answer">The answer as text.</param>
    procedure SetTestOutput(Context: Text; Question: Text; Answer: Text)
    var
        CurrentTestOutputJson: Codeunit "Test Output Json";
    begin
        CurrentTestOutputJson.Initialize();
        CurrentTestOutputJson.Add(ContextTok, Context);
        CurrentTestOutputJson.Add(QuestionTok, Question);
        CurrentTestOutputJson.Add(AnswerTok, Answer);
        SetSuiteTestOutput(CurrentTestOutputJson.ToText());
    end;

    /// <summary>
    /// Sets the test metric for the output dataset.
    /// </summary>
    /// <param name="TestMetric">The test metric as text.</param>
    procedure SetTestMetric(TestMetric: Text)
    var
        CurrentTestOutputJson: Codeunit "Test Output Json";
    begin
        CurrentTestOutputJson.Initialize();
        CurrentTestOutputJson.Add(TestMetricsTok, TestMetric);
        SetSuiteTestOutput(CurrentTestOutputJson.ToText());
    end;

    /// <summary>
    /// Sets to next turn for multiturn testing.
    /// </summary>
    /// <returns>True if another turn exists, otherwise false.</returns>
    procedure SetNextTurn(): Boolean
    begin
        if not IsMultiTurn then
            exit(false);

        if CurrentTurn + 1 > NumberOfTurns then
            exit(false);

        CurrentTurn := CurrentTurn + 1;

        exit(true);
    end;

    /// <summary>
    /// This method starts the scope of the Run Procedure scenario.
    /// </summary>
    procedure StartRunProcedureScenario()
    var
        AITALTestSuiteMgt: Codeunit "AIT AL Test Suite Mgt";
    begin
        AITTestSuiteMgt.StartScenario(AITALTestSuiteMgt.GetDefaultRunProcedureOperationLbl());
        InitializeGlobalVariables();
    end;

    /// <summary>
    /// This method ends the scope of the Run Procedure scenario.
    /// </summary>
    /// <param name="TestMethodLine">Record containing the result of the test execution.</param>
    /// <param name="ExecutionSuccess">Result of the test execution.</param>
    procedure EndRunProcedureScenario(TestMethodLine: Record "Test Method Line"; ExecutionSuccess: Boolean)
    var
        AITTestMethodLine: Record "AIT Test Method Line";
        AITALTestSuiteMgt: Codeunit "AIT AL Test Suite Mgt";
    begin
        GetAITTestMethodLine(AITTestMethodLine);
        AITTestSuiteMgt.EndRunProcedureScenario(AITTestMethodLine, AITALTestSuiteMgt.GetDefaultRunProcedureOperationLbl(), TestMethodLine, ExecutionSuccess);
    end;

    /// <summary>
    /// Initializes global variables for the iteration.
    /// </summary>
    local procedure InitializeGlobalVariables()
    var
        TestInput: Codeunit "Test Input";
        TestInputJson: Codeunit "Test Input Json";
    begin
        CurrentTurn := 0;
        GlobalTestOutputJson.Initialize();
        TestInputJson := TestInput.GetTestInput().ElementExists(TurnsTok, IsMultiTurn);

        if IsMultiTurn then
            NumberOfTurns := TestInputJson.GetElementCount() - 1;
    end;

    /// <summary>
    /// Sets to next turn for multiturn testing.
    /// </summary>
    /// <returns>True if another turn exists, otherwise false.</returns>
    local procedure GetTestInput(ElementName: Text) TestInputJson: Codeunit "Test Input Json"
    var
        TestInput: Codeunit "Test Input";
    begin
        if IsMultiTurn then
            TestInputJson := TestInput.GetTestInput(TurnsTok).ElementAt(CurrentTurn).Element(ElementName)
        else
            TestInputJson := TestInput.GetTestInput(ElementName);
    end;

    /// <summary>
    /// Sets the test output for the current iteration.
    /// </summary>
    local procedure SetSuiteTestOutput(Output: Text)
    var
        AITALTestSuiteMgt: Codeunit "AIT AL Test Suite Mgt";
        TestOutputCU: Codeunit "Test Output";
    begin
        if IsMultiTurn then begin
            if IsMultiTurn and not TestOutputCU.TestData().ElementExists(TurnsTok) then
                TestOutputCU.TestData().AddArray(TurnsTok);

            TestOutputCU.TestData().Element(TurnsTok).Add(Output);
        end else
            TestOutputCU.TestData().Initialize(Output);

        AITTestSuiteMgt.SetTestOutput(AITALTestSuiteMgt.GetDefaultRunProcedureOperationLbl(), TestOutputCU.Testdata().ToText());
    end;

    /// <summary>
    /// Returns the AITTestSuite associated with the sessions.
    /// </summary>
    /// <param name="AITTestMethodLine">AITTestMethodLine associated with the session.</param>
    local procedure GetAITTestSuite(var AITTestSuite: Record "AIT Test Suite")
    var
        AITTestRunIteration: Codeunit "AIT Test Run Iteration";
    begin
        AITTestRunIteration.GetAITTestSuite(AITTestSuite);
    end;

    /// <summary>
    /// Returns the AITTestMethodLine associated with the sessions.
    /// </summary>
    /// <param name="AITTestMethodLine">AITTestMethodLine associated with the session.</param>
    local procedure GetAITTestMethodLine(var AITTestMethodLine: Record "AIT Test Method Line")
    var
        AITTestRunIteration: Codeunit "AIT Test Run Iteration";
    begin
        AITTestRunIteration.GetAITTestMethodLine(AITTestMethodLine);
    end;

    /// <summary>
    /// Copies an element for the test input to the test output.
    /// </summary>
    /// <param name="ElementName">The name of the element to copy.</param>
    local procedure CopyElementToOutput(ElementName: Text; var CurrentTestOutputJson: Codeunit "Test Output Json")
    var
        TestInput: Codeunit "Test Input";
    begin
        if TestInput.GetTestInput(ElementName).ElementValue().IsNull() then
            exit;

        CurrentTestOutputJson.Add(ElementName, TestInput.GetTestInput(ElementName).ValueAsText());
    end;
}