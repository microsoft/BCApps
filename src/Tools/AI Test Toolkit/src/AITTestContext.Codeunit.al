// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;
using System.TestTools.TestRunner;

/// <summary>
/// Exposes functions that can be used by the AIT tests.
/// </summary>
codeunit 149043 "AIT Test Context"
{
    SingleInstance = true;
    Access = Public;

    var
        AITTestSuiteMgt: Codeunit "AIT Test Suite Mgt.";
        ScenarioCannotUseDefaultScenarioErr: Label 'Please use a different Scenario Operation. It cannot be the same as %1.', Comment = '%1 = "Run Procedure"';
        AnswerTok: Label 'answer', Locked = true;
        ContextTok: Label 'context', Locked = true;
        GroundTruthTok: Label 'ground_truth', Locked = true;
        UserQueryTok: Label 'user_query', Locked = true;
        ScenarioOutputTok: Label 'scenario_output', Locked = true;
        TestMetricsTok: Label 'test_metrics', Locked = true;
        TestOutputTok: Label 'test_output', Locked = true;
        TestSetupTok: Label 'test_setup', Locked = true;
        QuestionTok: Label 'question', Locked = true;

    /// <summary>
    /// This method starts the scope of a scenario being tested.
    /// </summary>
    /// <param name="ScenarioOperation">Label of the scenario.</param>
    procedure StartScenario(ScenarioOperation: Text)
    var
        AITALTestSuiteMgt: Codeunit "AIT AL Test Suite Mgt";
    begin
        if ScenarioOperation = AITALTestSuiteMgt.GetDefaultRunProcedureOperationLbl() then
            Error(ScenarioCannotUseDefaultScenarioErr, AITALTestSuiteMgt.GetDefaultRunProcedureOperationLbl());
        this.AITTestSuiteMgt.StartScenario(ScenarioOperation);
    end;

    /// <summary>
    /// This method simulates a users delay between operations. This method is called by the AIT test to represent a realistic scenario.
    /// The calculation of the length of the wait is done usign the parameters defined on the AIT suite.
    /// </summary>
    procedure UserWait()
    var
        AITTestSuite: Record "AIT Test Suite";
        AITTestMethodLine: Record "AIT Test Method Line";

    begin
        this.GetAITTestSuite(AITTestSuite);
        this.GetAITTestMethodLine(AITTestMethodLine);
        this.AITTestSuiteMgt.UserWait(AITTestMethodLine);
    end;

    /// <summary>
    /// Returns the Test Input Value from the dataset for the current iteration.
    /// </summary>
    procedure GetInput(): Text
    var
        TestInputCU: Codeunit "Test Input";
    begin
        exit(TestInputCU.GetTestInputValue());
    end;

    /// <summary>
    /// Get the User Query value as text from the input dataset for the current iteration.
    /// </summary>
    /// <returns>A text value for the user_query element.</returns>
    procedure GetUserQuery(): Text
    begin
        exit(GetUserQueryAsJson().ValueAsText());
    end;

    /// <summary>
    /// Get the User Query from the input dataset for the current iteration.
    /// <returns>A Test Input Json codeunit for the user_query element.</returns>
    /// </summary>
    procedure GetUserQueryAsJson() TestInputJson: Codeunit "Test Input Json"
    var
        TestInputCU: Codeunit "Test Input";
    begin
        TestInputJson := TestInputCU.GetTestInput(UserQueryTok);
    end;

    /// <summary>
    /// Get the Test Setup value as text from the input dataset for the current iteration.
    /// </summary>
    /// <returns>A text value for the test_setup element.</returns>
    procedure GetTestSetupAsText(): Text
    begin
        exit(GetTestSetupAsJson().ValueAsText());
    end;

    /// <summary>
    /// Get the Test Setup from the input dataset for the current iteration.
    /// </summary>
    /// <returns>A Test Input Json codeunit for the test_setup element.</returns>
    procedure GetTestSetupAsJson() TestInputJson: Codeunit "Test Input Json"
    var
        TestInputCU: Codeunit "Test Input";
    begin
        TestInputJson := TestInputCU.GetTestInput(TestSetupTok);
    end;


    /// <summary>
    /// Get the Context value as text from the input dataset for the current iteration.
    /// </summary>
    /// <returns>A text value for the context element.</returns>
    procedure GetContext(): Text
    begin
        exit(GetContextAsJson().ValueAsText());
    end;

    /// <summary>
    /// Get the Context from the input dataset for the current iteration.
    /// <returns>A Test Input Json codeunit for the context element.</returns>
    /// </summary>
    procedure GetContextAsJson() TestInputJson: Codeunit "Test Input Json"
    var
        TestInputCU: Codeunit "Test Input";
    begin
        TestInputJson := TestInputCU.GetTestInput(ContextTok);
    end;

    /// <summary>
    /// Get the Question value as text from the input dataset for the current iteration.
    /// </summary>
    /// <returns>A text value for the question element.</returns>
    procedure GetQuestionAsText(): Text
    begin
        exit(GetQuestionAsJson().ValueAsText());
    end;

    /// <summary>
    /// Get the Question from the input dataset for the current iteration.
    /// <returns>A Test Input Json codeunit for the question element.</returns>
    /// </summary>
    procedure GetQuestionAsJson() TestInputJson: Codeunit "Test Input Json"
    var
        TestInputCU: Codeunit "Test Input";
    begin
        TestInputJson := TestInputCU.GetTestInput(QuestionTok);
    end;

    /// <summary>
    /// Get the Ground Truth value as text from the input dataset for the current iteration.
    /// </summary>
    /// <returns>A text value for the ground_truth element.</returns>
    procedure GetGroundTruthAsText(): Text
    begin
        exit(GetGroundTruthAsJson().ValueAsText());
    end;

    /// <summary>
    /// Get the Ground Truth from the input dataset for the current iteration.
    /// <returns>A Test Input Json codeunit for the ground_truth element.</returns>
    /// </summary>
    procedure GetGroundTruthAsJson() TestInputJson: Codeunit "Test Input Json"
    var
        TestInputCU: Codeunit "Test Input";
    begin
        TestInputJson := TestInputCU.GetTestInput(GroundTruthTok);
    end;

    /// <summary>
    /// Sets the scneario test output for the current iteration.
    /// </summary>
    /// <param name="TestOutputText">The test output as text.</param>
    procedure SetScenarioOutput(Scenario: Text; TestOutputText: Text)
    var
        TestOutputCU: Codeunit "Test Output";
    begin
        TestOutputCU.TestData().Add(ScenarioOutputTok, TestOutputText);
        this.AITTestSuiteMgt.SetTestOutput(Scenario, TestOutputCU.TestData().ToText());
    end;

    /// <summary>
    /// Sets the test output for the current iteration.
    /// </summary>
    /// <param name="TestOutputText">The test output as text.</param>
    procedure SetTestOutput(TestOutputText: Text)
    var
        TestOutputCU: Codeunit "Test Output";
        AITALTestSuiteMgt: Codeunit "AIT AL Test Suite Mgt";
    begin
        TestOutputCU.TestData().Add(TestOutputTok, TestOutputText);
        this.AITTestSuiteMgt.SetTestOutput(AITALTestSuiteMgt.GetDefaultRunProcedureOperationLbl(), TestOutputCU.TestData().ToText());
    end;

    /// <summary>
    /// Sets the answer for a question and answer evaluation.
    /// This will also copy the context, question and ground truth to the output dataset.
    /// </summary>
    /// <param name="Answer">The answer as text.</param>
    procedure SetAnswerForQnAEvaluation(Answer: Text)
    var
        TestOutputCU: Codeunit "Test Output";
        AITALTestSuiteMgt: Codeunit "AIT AL Test Suite Mgt";
    begin
        TestOutputCU.TestData().Add(AnswerTok, Answer);
        CopyElementToOutput(ContextTok);
        CopyElementToOutput(QuestionTok);
        CopyElementToOutput(GroundTruthTok);
        this.AITTestSuiteMgt.SetTestOutput(AITALTestSuiteMgt.GetDefaultRunProcedureOperationLbl(), TestOutputCU.TestData().ToText());
    end;

    /// <summary>
    /// Sets the test metric for the output dataset.
    /// </summary>
    /// <param name="TestMetric">The test metric as text.</param>
    procedure SetTestMetric(TestMetric: Text)
    var
        TestOutputCU: Codeunit "Test Output";
        AITALTestSuiteMgt: Codeunit "AIT AL Test Suite Mgt";
    begin
        TestOutputCU.TestData().Add(TestMetricsTok, TestMetric);
        this.AITTestSuiteMgt.SetTestOutput(AITALTestSuiteMgt.GetDefaultRunProcedureOperationLbl(), TestOutputCU.TestData().ToText());
    end;

    /// <summary>
    /// This method starts the scope of the Run Procedure scenario.
    /// </summary>
    internal procedure StartRunProcedureScenario()
    var
        AITALTestSuiteMgt: Codeunit "AIT AL Test Suite Mgt";
    begin
        this.AITTestSuiteMgt.StartScenario(AITALTestSuiteMgt.GetDefaultRunProcedureOperationLbl());
    end;

    /// <summary>
    /// This method ends the scope of the Run Procedure scenario.
    /// </summary>
    /// <param name="TestMethodLine">Record containing the result of the test execution.</param>
    /// <param name="ExecutionSuccess">Result of the test execution.</param>
    internal procedure EndRunProcedureScenario(TestMethodLine: Record "Test Method Line"; ExecutionSuccess: Boolean)
    var
        AITTestMethodLine: Record "AIT Test Method Line";
        AITALTestSuiteMgt: Codeunit "AIT AL Test Suite Mgt";
    begin
        this.GetAITTestMethodLine(AITTestMethodLine);
        this.AITTestSuiteMgt.EndRunProcedureScenario(AITTestMethodLine, AITALTestSuiteMgt.GetDefaultRunProcedureOperationLbl(), TestMethodLine, ExecutionSuccess);
    end;

    /// <summary>
    /// Returns the AITTestSuite associated with the sessions.
    /// </summary>
    /// <param name="AITTestMethodLine">AITTestMethodLine associated with the session.</param>
    local procedure GetAITTestSuite(var AITTestSuite: Record "AIT Test Suite")
    var
        AITTestRunnerImpl: Codeunit "AIT Test Runner";
    begin
        AITTestRunnerImpl.GetAITTestSuite(AITTestSuite);
    end;

    /// <summary>
    /// Returns the AITTestMethodLine associated with the sessions.
    /// </summary>
    /// <param name="AITTestMethodLine">AITTestMethodLine associated with the session.</param>
    local procedure GetAITTestMethodLine(var AITTestMethodLine: Record "AIT Test Method Line")
    var
        AITTestRunnerImpl: Codeunit "AIT Test Runner";
    begin
        AITTestRunnerImpl.GetAITTestMethodLine(AITTestMethodLine);
    end;

    /// <summary>
    /// Copies an element for the test input to the test output.
    /// </summary>
    /// <param name="ElementName">The name of the element to copy.</param>
    local procedure CopyElementToOutput(ElementName: Text)
    var
        TestOutputCU: Codeunit "Test Output";
        TestInputCU: Codeunit "Test Input";
    begin
        if TestInputCU.GetTestInput(ElementName).ElementValue().IsNull() then
            exit;

        TestOutputCU.TestData().Add(ElementName, TestInputCU.GetTestInput(ElementName).ValueAsText());
    end;
}