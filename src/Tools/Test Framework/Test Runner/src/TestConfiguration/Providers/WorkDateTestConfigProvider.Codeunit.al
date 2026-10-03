// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

/// <summary>
/// Provider that moves WorkDate into the future for the duration of the run. The shift is stored as a
/// date formula in the context and re-applied before every test method, because the test runner
/// restores WorkDate after each codeunit. Settings: { "formula": "1Y" } (any AL date formula).
/// </summary>
codeunit 130476 "WorkDate Test Config. Prov." implements "ITest Configuration Provider"
{
    var
        DescriptionTxt: Label 'Moves WorkDate into the future.';
        InvalidFormulaErr: Label 'The WorkDate shift ''%1'' is not a valid date formula.', Comment = '%1 = the configured formula';

    procedure GetDescription(): Text
    begin
        exit(DescriptionTxt);
    end;

    procedure Validate(Settings: JsonObject)
    var
        WorkDateFormula: DateFormula;
        FormulaToken: JsonToken;
        FormulaText: Text;
    begin
        if not Settings.Get('formula', FormulaToken) then
            exit;
        if not FormulaToken.IsValue() then
            exit;
        if FormulaToken.AsValue().IsNull() then
            exit;
        FormulaText := FormulaToken.AsValue().AsText();
        if FormulaText = '' then
            exit;
        if not Evaluate(WorkDateFormula, CopyStr(FormulaText, 1, 30)) then
            Error(InvalidFormulaErr, FormulaText);
    end;

    procedure Prepare(Settings: JsonObject; TestConfigurationContext: Codeunit "Test Configuration Context")
    var
        FormulaToken: JsonToken;
        FormulaText: Text;
    begin
        FormulaText := '<1Y>';
        if Settings.Get('formula', FormulaToken) then
            if FormulaToken.IsValue() then
                if not FormulaToken.AsValue().IsNull() then
                    FormulaText := FormulaToken.AsValue().AsText();
        TestConfigurationContext.SetWorkDateFormula(CopyStr(FormulaText, 1, 30));
    end;

    procedure OnBeforeTestMethodRun(var CurrentTestMethodLine: Record "Test Method Line"; Settings: JsonObject; TestConfigurationContext: Codeunit "Test Configuration Context")
    begin
        if TestConfigurationContext.IsWorkDateShifted() then
            WorkDate(TestConfigurationContext.GetShiftedWorkDate());
    end;

#pragma warning disable AA0150
    procedure OnAfterTestMethodRun(var CurrentTestMethodLine: Record "Test Method Line"; IsSuccess: Boolean; Settings: JsonObject; TestConfigurationContext: Codeunit "Test Configuration Context")
    begin
    end;
#pragma warning restore AA0150
}
