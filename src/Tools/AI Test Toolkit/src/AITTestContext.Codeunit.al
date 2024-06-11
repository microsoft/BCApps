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
    /// This method starts the scope of a scenario being tested.
    /// </summary>
    /// <param name="ScenarioOperation">Label of the scenario.</param>
    procedure StartScenario(ScenarioOperation: Text)
    var
        AITALTestSuiteMgt: Codeunit "AIT AL Test Suite Mgt";
        ScenarioCannotUseDefaultScenarioErr: Label 'Please use a different Scenario Operation. It cannot be the same as %1.', Comment = '%1 = "Run Procedure"';
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

    procedure GetUserQuery(): Text
    var
        TestInputCU: Codeunit "Test Input";
    begin
        exit(TestInputCU.GetTestInput('user_query').ValueAsText());
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

    procedure SetTestOutput(TestOutputText: Text)
    var
        TestOutputCU: Codeunit "Test Output";
        AITALTestSuiteMgt: Codeunit "AIT AL Test Suite Mgt";
    begin
        TestOutputCU.TestData().Add('test_output', TestOutputText);
        this.AITTestSuiteMgt.SetTestOutput(AITALTestSuiteMgt.GetDefaultRunProcedureOperationLbl(), TestOutputCU.TestData().ToText());
    end;

    procedure SetAnswerForQnAEvaluation(Answer: Text)
    var
        TestOutputCU: Codeunit "Test Output";
        TestInputCU: Codeunit "Test Input";
        AITALTestSuiteMgt: Codeunit "AIT AL Test Suite Mgt";
    begin
        TestOutputCU.TestData().Add('answer', Answer);
        if not TestInputCU.GetTestInput('context').ElementValue().IsNull then
            TestOutputCU.TestData().Add('context', TestInputCU.GetTestInput('context').ValueAsText());
        if not TestInputCU.GetTestInput('question').ElementValue().IsNull then
            TestOutputCU.TestData().Add('question', TestInputCU.GetTestInput('question').ValueAsText());
        if not TestInputCU.GetTestInput('ground_truth').ElementValue().IsNull then
            TestOutputCU.TestData().Add('ground_truth', TestInputCU.GetTestInput('ground_truth').ValueAsText());
        this.AITTestSuiteMgt.SetTestOutput(AITALTestSuiteMgt.GetDefaultRunProcedureOperationLbl(), TestOutputCU.TestData().ToText());
    end;

    procedure SetScenarioOutput(Scenario: Text; TestOutputText: Text)
    var
        TestOutputCU: Codeunit "Test Output";
    begin
        TestOutputCU.TestData().Add('scenario_output', TestOutputText);
        this.AITTestSuiteMgt.SetTestOutput(Scenario, TestOutputCU.TestData().ToText());
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

}