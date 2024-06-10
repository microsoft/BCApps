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
        AITLineCU: Codeunit "AIT Line";

    /// <summary>
    /// This method starts the scope of the Run Procedure scenario.
    /// </summary>
    internal procedure StartRunProcedureScenario()
    var
        AITTALTestSuiteMgt: Codeunit "AITT AL Test Suite Mgt";
    begin
        this.AITLineCU.StartScenario(AITTALTestSuiteMgt.GetDefaultRunProcedureOperationLbl());
    end;

    /// <summary>
    /// This method ends the scope of the Run Procedure scenario.
    /// </summary>
    /// <param name="TestMethodLine">Record containing the result of the test execution.</param>
    /// <param name="ExecutionSuccess">Result of the test execution.</param>
    internal procedure EndRunProcedureScenario(TestMethodLine: Record "Test Method Line"; ExecutionSuccess: Boolean)
    var
        AITLine: Record "AIT Line";
        AITTALTestSuiteMgt: Codeunit "AITT AL Test Suite Mgt";
    begin
        this.GetAITLine(AITLine);
        this.AITLineCU.EndRunProcedureScenario(AITLine, AITTALTestSuiteMgt.GetDefaultRunProcedureOperationLbl(), TestMethodLine, ExecutionSuccess);
    end;

    /// <summary>
    /// This method starts the scope of a scenario being tested.
    /// </summary>
    /// <param name="ScenarioOperation">Label of the scenario.</param>
    procedure StartScenario(ScenarioOperation: Text)
    var
        AITTALTestSuiteMgt: Codeunit "AITT AL Test Suite Mgt";
        ScenarioCannotUseDefaultScenarioErr: Label 'Please use a different Scenario Operation. It cannot be the same as %1.', Comment = '%1 = "Run Procedure"';
    begin
        if ScenarioOperation = AITTALTestSuiteMgt.GetDefaultRunProcedureOperationLbl() then
            Error(ScenarioCannotUseDefaultScenarioErr, AITTALTestSuiteMgt.GetDefaultRunProcedureOperationLbl());
        this.AITLineCU.StartScenario(ScenarioOperation);
    end;

    // /// <summary>
    // /// This method ends the scope of a scenario being tested.
    // /// </summary>
    // /// <param name="ScenarioOperation">Label of the scenario.</param>
    // procedure EndScenario(ScenarioOperation: Text)
    // var
    //     AITLine: Record "AIT Line";
    //     AITTestRunnerImpl: Codeunit "AIT Test Runner";
    // begin
    //     this.GetAITLine(AITLine);
    //     this.AITLineCU.EndRunProcedureScenario(AITLine, ScenarioOperation, AITTestRunnerImpl.GetCurrTestMethodLine(), true);
    // end;

    // /// <summary>
    // /// This method ends the scope of a scenario being tested.
    // /// </summary>
    // /// <param name="ScenarioOperation">Label of the scenario.</param>
    // /// <param name="ScenarioOutput">Output of the scenario.</param>
    // procedure EndScenario(ScenarioOperation: Text; ScenarioOutput: Text)
    // var
    //     AITLine: Record "AIT Line";
    //     AITTestRunnerImpl: Codeunit "AIT Test Runner";
    // begin
    //     this.GetAITLine(AITLine);
    //     this.SetScenarioOutput(ScenarioOperation, ScenarioOutput);
    //     this.AITLineCU.EndRunProcedureScenario(AITLine, ScenarioOperation, AITTestRunnerImpl.GetCurrTestMethodLine(), true);
    // end;

    // /// <summary>
    // /// This method ends the scope of a scenario being tested.
    // /// </summary>
    // /// <param name="ScenarioOperation">Label of the scenario.</param>
    // /// <param name="ExecutionSuccess">Result of the test execution.</param>
    // procedure EndScenario(ScenarioOperation: Text; ExecutionSuccess: Boolean)
    // var
    //     AITLine: Record "AIT Line";
    //     AITTestRunnerImpl: Codeunit "AIT Test Runner";
    // begin
    //     this.GetAITLine(AITLine);
    //     this.AITLineCU.EndRunProcedureScenario(AITLine, ScenarioOperation, AITTestRunnerImpl.GetCurrTestMethodLine(), ExecutionSuccess);
    // end;

    // procedure EndScenario(ScenarioOperation: Text; ExecutionSuccess: Boolean; ScenarioOutput: Text)
    // var
    //     AITLine: Record "AIT Line";
    //     AITTestRunnerImpl: Codeunit "AIT Test Runner";
    // begin
    //     this.GetAITLine(AITLine);
    //     this.SetScenarioOutput(ScenarioOperation, ScenarioOutput);
    //     this.AITLineCU.EndRunProcedureScenario(AITLine, ScenarioOperation, AITTestRunnerImpl.GetCurrTestMethodLine(), ExecutionSuccess);
    // end;

    /// <summary>
    /// This method simulates a users delay between operations. This method is called by the AIT test to represent a realistic scenario.
    /// The calculation of the length of the wait is done usign the parameters defined on the AIT suite.
    /// </summary>
    procedure UserWait()
    var
        AITHeader: Record "AIT Header";
        AITLine: Record "AIT Line";

    begin
        this.GetAITHeader(AITHeader);
        this.GetAITLine(AITLine);
        this.AITLineCU.UserWait(AITLine);
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
    /// Returns the AITHeader associated with the sessions.
    /// </summary>
    /// <param name="AITLine">AITLine associated with the session.</param>
    local procedure GetAITHeader(var AITHeader: Record "AIT Header")
    var
        AITTestRunnerImpl: Codeunit "AIT Test Runner";
    begin
        AITTestRunnerImpl.GetAITHeader(AITHeader);
    end;

    procedure SetTestOutput(TestOutputText: Text)
    var
        TestOutputCU: Codeunit "Test Output";
        AITTALTestSuiteMgt: Codeunit "AITT AL Test Suite Mgt";
    begin
        TestOutputCU.TestData().Add('test_output', TestOutputText);
        this.AITLineCU.SetTestOutput(AITTALTestSuiteMgt.GetDefaultRunProcedureOperationLbl(), TestOutputCU.TestData().ToText());
    end;

    procedure SetAnswerForQnAEvaluation(Answer: Text)
    var
        TestOutputCU: Codeunit "Test Output";
        TestInputCU: Codeunit "Test Input";
        AITTALTestSuiteMgt: Codeunit "AITT AL Test Suite Mgt";
    begin
        TestOutputCU.TestData().Add('answer', Answer);
        if not TestInputCU.GetTestInput('context').ElementValue().IsNull then
            TestOutputCU.TestData().Add('context', TestInputCU.GetTestInput('context').ValueAsText());
        if not TestInputCU.GetTestInput('question').ElementValue().IsNull then
            TestOutputCU.TestData().Add('question', TestInputCU.GetTestInput('question').ValueAsText());
        if not TestInputCU.GetTestInput('ground_truth').ElementValue().IsNull then
            TestOutputCU.TestData().Add('ground_truth', TestInputCU.GetTestInput('ground_truth').ValueAsText());
        this.AITLineCU.SetTestOutput(AITTALTestSuiteMgt.GetDefaultRunProcedureOperationLbl(), TestOutputCU.TestData().ToText());
    end;

    procedure SetScenarioOutput(Scenario: Text; TestOutputText: Text)
    var
        TestOutputCU: Codeunit "Test Output";
    begin
        TestOutputCU.TestData().Add('scenario_output', TestOutputText);
        this.AITLineCU.SetTestOutput(Scenario, TestOutputCU.TestData().ToText());
    end;

    /// <summary>
    /// Returns the AITLine associated with the sessions.
    /// </summary>
    /// <param name="AITLine">AITLine associated with the session.</param>
    local procedure GetAITLine(var AITLine: Record "AIT Line")
    var
        AITTestRunnerImpl: Codeunit "AIT Test Runner";
    begin
        AITTestRunnerImpl.GetAITLine(AITLine);
    end;

}