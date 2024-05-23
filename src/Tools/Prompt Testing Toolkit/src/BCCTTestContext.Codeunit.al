// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

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
    /// This method starts the scope of a test session where the performance numbers are collected.
    /// </summary>
    /// <param name="ScenarioOperation">Label of the scenario.</param>
    procedure StartScenario(ScenarioOperation: Text)
    begin
        BCCTLineCU.StartScenario(ScenarioOperation);
    end;

    /// <summary>
    /// This method ends the scope of a test session where the performance numbers are collected.
    /// </summary>
    /// <param name="ScenarioOperation">Label of the scenario.</param>
    procedure EndScenario(ScenarioOperation: Text)
    var
        BCCTLine: Record "BCCT Line";
        BCCTDatasetLine: Record "BCCT Dataset Line";
    begin
        GetBCCTLine(BCCTLine);
        GetBCCTDatasetLine(BCCTDatasetLine);
        BCCTLineCU.EndScenario(BCCTLine, ScenarioOperation, '', true, BCCTDatasetLine);
    end;

    /// <summary>
    /// This method ends the scope of a test session where the performance numbers are collected.
    /// </summary>
    /// <param name="ScenarioOperation">Label of the scenario.</param>
    /// <param name="ExecutionSuccess">Result of the test execution.</param>
    procedure EndScenario(ScenarioOperation: Text; ExecutionSuccess: Boolean)
    var
        BCCTLine: Record "BCCT Line";
        BCCTDatasetLine: Record "BCCT Dataset Line";
    begin
        GetBCCTLine(BCCTLine);
        GetBCCTDatasetLine(BCCTDatasetLine);
        BCCTLineCU.EndScenario(BCCTLine, ScenarioOperation, '', ExecutionSuccess, BCCTDatasetLine);
    end;

    /// <summary>
    /// This method ends the scope of a test session where the performance numbers are collected.
    /// </summary>
    /// <param name="ScenarioOperation">Label of the scenario.</param>
    /// <param name="ExecutionSuccess">Result of the test execution.</param>
    /// <param name="ProcedureName">Name of the procedure being executed</param>
    internal procedure EndScenario(ScenarioOperation: Text; ProcedureName: Text[128]; ExecutionSuccess: Boolean)
    var
        BCCTLine: Record "BCCT Line";
        BCCTDatasetLine: Record "BCCT Dataset Line";
    begin
        GetBCCTLine(BCCTLine);
        GetBCCTDatasetLine(BCCTDatasetLine);
        BCCTLineCU.EndScenario(BCCTLine, ScenarioOperation, ProcedureName, ExecutionSuccess, BCCTDatasetLine);
    end;

    /// <summary>
    /// This method simulates a users delay between operations. This method is called by the BCCT test to represent a realistic scenario.
    /// The calculation of the length of the wait is done usign the parameters defined on the BCCT suite.
    /// </summary>
    procedure UserWait()
    var
        BCCTHeader: Record "BCCT Header";
        BCCTLine: Record "BCCT Line";

    begin
        GetBCCTHeader(BCCTHeader);
        GetBCCTLine(BCCTLine);
        BCCTLineCU.UserWait(BCCTLine);
    end;

    /// <summary>
    /// Returns the BCCTLine associated with the sessions.
    /// </summary>
    /// <param name="BCCTLine">BCCTLine associated with the session.</param>
    local procedure GetBCCTLine(var BCCTLine: Record "BCCT Line")
    var
        BCCTRoleWrapperImpl: Codeunit "BCCT Role Wrapper";
    begin
        BCCTRoleWrapperImpl.GetBCCTLine(BCCTLine);
    end;

    /// <summary>
    /// Returns the BCCTDatasetLine associated with the tests.
    /// </summary>
    /// <param name="BCCTDatasetLine">BCCTLine associated with the session.</param>
    local procedure GetBCCTDatasetLine(var BCCTDatasetLine: Record "BCCT Dataset Line") //TODO: Consider exposing the Get input/output procedures from inside the record instead of sending the entire record
    var
        BCCTRoleWrapperImpl: Codeunit "BCCT Role Wrapper";
    begin
        BCCTRoleWrapperImpl.GetBCCTDatasetLine(BCCTDatasetLine);
    end;

    /// <summary>
    /// Returns the Input line from the dataset for the current iteration.
    /// </summary>
    procedure GetInput(): Text
    var
        BCCTDatasetLine: Record "BCCT Dataset Line";
        BCCTRoleWrapperImpl: Codeunit "BCCT Role Wrapper";
    begin
        BCCTRoleWrapperImpl.GetBCCTDatasetLine(BCCTDatasetLine);
        exit(BCCTDatasetLine.GetInputBlobAsText());
    end;


    /// <summary>
    /// Returns the BCCTHeader associated with the sessions.
    /// </summary>
    /// <param name="BCCTLine">BCCTLine associated with the session.</param>
    local procedure GetBCCTHeader(var BCCTHeader: Record "BCCT Header")
    var
        BCCTRoleWrapperImpl: Codeunit "BCCT Role Wrapper";
    begin
        BCCTRoleWrapperImpl.GetBCCTHeader(BCCTHeader);
    end;

    procedure SetTestOutput(TestOutput: Text)
    var
        BCCTRoleWrapperImpl: Codeunit "BCCT Role Wrapper";
    begin
        BCCTLineCU.SetTestOutput(BCCTRoleWrapperImpl.GetDefaultExecuteProcedureOperationLbl(), TestOutput);
    end;

    procedure SetTestOutput(Scenario: Text; TestOutput: Text)
    begin
        BCCTLineCU.SetTestOutput(Scenario, TestOutput);
    end;

}