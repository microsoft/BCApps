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
        BCCTLineCU.EndScenario(BCCTLine, ScenarioOperation, true, BCCTDatasetLine);
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
        BCCTLineCU.EndScenario(BCCTLine, ScenarioOperation, ExecutionSuccess, BCCTDatasetLine);
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
    local procedure GetBCCTDatasetLine(var BCCTDatasetLine: Record "BCCT Dataset Line")
    var
        BCCTRoleWrapperImpl: Codeunit "BCCT Role Wrapper";
    begin
        BCCTRoleWrapperImpl.GetBCCTDatasetLine(BCCTDatasetLine);
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

    /// <summary>
    /// Returns the paramater list associated with the sessions.
    /// </summary>
    procedure GetParameters(): Text
    var
        BCCTLine: Record "BCCT Line";
    begin
        GetBCCTLine(BCCTLine);
        exit(BCCTLine.Parameters);
    end;

    /// <summary>
    /// Returns the requested paramater value associated with the session.
    /// </summary>
    /// <param name="ParameterName">Name of the parameter.</param>
    procedure GetParameter(ParameterName: Text): Text
    var
        BCCTLine: Record "BCCT Line";
        dict: Dictionary of [Text, Text];
    begin
        GetBCCTLine(BCCTLine);
        if ParameterName = '' then
            exit('');
        if BCCTLine.Parameters = '' then
            exit('');
        BCCTLineCU.ParameterStringToDictionary(BCCTLine.Parameters, dict);
        if dict.Count = 0 then
            exit('');
        if not dict.ContainsKey(ParameterName) then
            exit('');
        exit(dict.Get(ParameterName));
    end;

}