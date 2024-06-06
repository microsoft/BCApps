// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;
using System.TestTools.TestRunner;

/// <summary>
/// Exposes functions that can be used by the BCCT tests.
/// </summary>
codeunit 149043 "BCCT Test Context"
{
    SingleInstance = true;
    Access = Public;

    var
        BCCTLineCU: Codeunit "BCCT Line";

    /// <summary>
    /// This method starts the scope of the Run Procedure scenario.
    /// </summary>
    internal procedure StartRunProcedureScenario()
    var
        AITTALTestSuiteMgt: Codeunit "AITT AL Test Suite Mgt";
    begin
        this.BCCTLineCU.StartScenario(AITTALTestSuiteMgt.GetDefaultRunProcedureOperationLbl());
    end;

    /// <summary>
    /// This method ends the scope of the Run Procedure scenario.
    /// </summary>
    /// <param name="TestMethodLine">Record containing the result of the test execution.</param>
    /// <param name="ExecutionSuccess">Result of the test execution.</param>
    internal procedure EndRunProcedureScenario(TestMethodLine: Record "Test Method Line"; ExecutionSuccess: Boolean)
    var
        BCCTLine: Record "BCCT Line";
        AITTALTestSuiteMgt: Codeunit "AITT AL Test Suite Mgt";
    begin
        this.GetBCCTLine(BCCTLine);
        this.BCCTLineCU.EndRunProcedureScenario(BCCTLine, AITTALTestSuiteMgt.GetDefaultRunProcedureOperationLbl(), TestMethodLine, ExecutionSuccess);
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
        this.BCCTLineCU.StartScenario(ScenarioOperation);
    end;

    // /// <summary>
    // /// This method ends the scope of a scenario being tested.
    // /// </summary>
    // /// <param name="ScenarioOperation">Label of the scenario.</param>
    // procedure EndScenario(ScenarioOperation: Text)
    // var
    //     BCCTLine: Record "BCCT Line";
    //     AITTestRunnerImpl: Codeunit "AIT Test Runner";
    // begin
    //     this.GetBCCTLine(BCCTLine);
    //     this.BCCTLineCU.EndRunProcedureScenario(BCCTLine, ScenarioOperation, AITTestRunnerImpl.GetCurrTestMethodLine(), true);
    // end;

    // /// <summary>
    // /// This method ends the scope of a scenario being tested.
    // /// </summary>
    // /// <param name="ScenarioOperation">Label of the scenario.</param>
    // /// <param name="ScenarioOutput">Output of the scenario.</param>
    // procedure EndScenario(ScenarioOperation: Text; ScenarioOutput: Text)
    // var
    //     BCCTLine: Record "BCCT Line";
    //     AITTestRunnerImpl: Codeunit "AIT Test Runner";
    // begin
    //     this.GetBCCTLine(BCCTLine);
    //     this.SetScenarioOutput(ScenarioOperation, ScenarioOutput);
    //     this.BCCTLineCU.EndRunProcedureScenario(BCCTLine, ScenarioOperation, AITTestRunnerImpl.GetCurrTestMethodLine(), true);
    // end;

    // /// <summary>
    // /// This method ends the scope of a scenario being tested.
    // /// </summary>
    // /// <param name="ScenarioOperation">Label of the scenario.</param>
    // /// <param name="ExecutionSuccess">Result of the test execution.</param>
    // procedure EndScenario(ScenarioOperation: Text; ExecutionSuccess: Boolean)
    // var
    //     BCCTLine: Record "BCCT Line";
    //     AITTestRunnerImpl: Codeunit "AIT Test Runner";
    // begin
    //     this.GetBCCTLine(BCCTLine);
    //     this.BCCTLineCU.EndRunProcedureScenario(BCCTLine, ScenarioOperation, AITTestRunnerImpl.GetCurrTestMethodLine(), ExecutionSuccess);
    // end;

    // procedure EndScenario(ScenarioOperation: Text; ExecutionSuccess: Boolean; ScenarioOutput: Text)
    // var
    //     BCCTLine: Record "BCCT Line";
    //     AITTestRunnerImpl: Codeunit "AIT Test Runner";
    // begin
    //     this.GetBCCTLine(BCCTLine);
    //     this.SetScenarioOutput(ScenarioOperation, ScenarioOutput);
    //     this.BCCTLineCU.EndRunProcedureScenario(BCCTLine, ScenarioOperation, AITTestRunnerImpl.GetCurrTestMethodLine(), ExecutionSuccess);
    // end;

    /// <summary>
    /// This method simulates a users delay between operations. This method is called by the BCCT test to represent a realistic scenario.
    /// The calculation of the length of the wait is done usign the parameters defined on the BCCT suite.
    /// </summary>
    procedure UserWait()
    var
        BCCTHeader: Record "BCCT Header";
        BCCTLine: Record "BCCT Line";

    begin
        this.GetBCCTHeader(BCCTHeader);
        this.GetBCCTLine(BCCTLine);
        this.BCCTLineCU.UserWait(BCCTLine);
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
        TestInputCU.GetTestInput('user_query');
    end;

    /// <summary>
    /// Returns the BCCTHeader associated with the sessions.
    /// </summary>
    /// <param name="BCCTLine">BCCTLine associated with the session.</param>
    local procedure GetBCCTHeader(var BCCTHeader: Record "BCCT Header")
    var
        AITTestRunnerImpl: Codeunit "AIT Test Runner";
    begin
        AITTestRunnerImpl.GetBCCTHeader(BCCTHeader);
    end;

    procedure SetTestOutput(TestOutputText: Text)
    var
        TestOutputCU: Codeunit "Test Output";
        AITTALTestSuiteMgt: Codeunit "AITT AL Test Suite Mgt";
    begin
        TestOutputCU.TestData().Add('test_output', TestOutputText);
        this.BCCTLineCU.SetTestOutput(AITTALTestSuiteMgt.GetDefaultRunProcedureOperationLbl(), TestOutputCU.TestData().ToText());
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
        this.BCCTLineCU.SetTestOutput(AITTALTestSuiteMgt.GetDefaultRunProcedureOperationLbl(), TestOutputCU.TestData().ToText());
    end;

    procedure SetScenarioOutput(Scenario: Text; TestOutputText: Text)
    var
        TestOutputCU: Codeunit "Test Output";
    begin
        TestOutputCU.TestData().Add('scenario_output', TestOutputText);
        this.BCCTLineCU.SetTestOutput(Scenario, TestOutputCU.TestData().ToText());
    end;

    /// <summary>
    /// Returns the BCCTLine associated with the sessions.
    /// </summary>
    /// <param name="BCCTLine">BCCTLine associated with the session.</param>
    local procedure GetBCCTLine(var BCCTLine: Record "BCCT Line")
    var
        AITTestRunnerImpl: Codeunit "AIT Test Runner";
    begin
        AITTestRunnerImpl.GetBCCTLine(BCCTLine);
    end;

}