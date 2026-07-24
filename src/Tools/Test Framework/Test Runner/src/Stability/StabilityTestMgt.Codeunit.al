// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

using System.TestLibraries.Utilities;

/// <summary>
/// Orchestrates a stability run. For every enabled preset combination configured for a base suite,
/// it clones the suite (applying the requested execution order), activates the presets and executes
/// the clone. The outcome of every test method is captured by codeunit "Stability Test Subscribers".
/// The tool is designed to surface flaky, order-dependent and data-dependent tests.
/// </summary>
codeunit 130474 "Stability Test Mgt"
{
    Permissions = tabledata "AL Test Suite" = rimd,
                  tabledata "Test Method Line" = rimd,
                  tabledata "Stability Run Configuration" = rimd,
                  tabledata "Stability Run Result" = rimd;

    var
        StabilityContext: Codeunit "Stability Context";
        StabilityPreset: Codeunit "Stability Preset";
        TestSuiteMgt: Codeunit "Test Suite Mgt.";
        GeneratedSuitePrefixTok: Label 'STB', Locked = true;
        SuiteNotFoundErr: Label 'Test suite %1 was not found.', Comment = '%1 = suite name';

    /// <summary>
    /// Runs all enabled stability combinations for the base suite and returns the results as JSON.
    /// If no combinations are configured yet, a default, editable set is created first.
    /// </summary>
    /// <param name="BaseSuiteName">The name of the base test suite.</param>
    /// <returns>The stability results serialized to JSON.</returns>
    procedure RunStabilityTests(BaseSuiteName: Code[10]): Text
    var
        BaseSuite: Record "AL Test Suite";
        StabilityRunConfiguration: Record "Stability Run Configuration";
        StabilityRunResult: Record "Stability Run Result";
    begin
        if not BaseSuite.Get(BaseSuiteName) then
            Error(SuiteNotFoundErr, BaseSuiteName);

        EnsureDefaultConfiguration(BaseSuiteName);

        StabilityRunResult.SetRange("Base Suite", BaseSuiteName);
        StabilityRunResult.DeleteAll();

        StabilityRunConfiguration.SetRange("Base Suite", BaseSuiteName);
        StabilityRunConfiguration.SetRange("Enabled", true);
        if StabilityRunConfiguration.FindSet() then
            repeat
                RunCombination(BaseSuite, StabilityRunConfiguration."Line No.", StabilityRunConfiguration."Configuration");
            until StabilityRunConfiguration.Next() = 0;

        exit(ResultsToJson(BaseSuiteName));
    end;

    /// <summary>
    /// Creates the default set of stability combinations for a base suite when none exist yet.
    /// </summary>
    /// <param name="BaseSuiteName">The name of the base test suite.</param>
    procedure EnsureDefaultConfiguration(BaseSuiteName: Code[10])
    var
        StabilityRunConfiguration: Record "Stability Run Configuration";
    begin
        StabilityRunConfiguration.SetRange("Base Suite", BaseSuiteName);
        if not StabilityRunConfiguration.IsEmpty() then
            exit;

        AddConfiguration(BaseSuiteName, 10000, 'BASELINE');
        AddConfiguration(BaseSuiteName, 20000, 'SEED-1+WORKDATEFUTURE-1YEAR');
        AddConfiguration(BaseSuiteName, 30000, 'ONEBYONE');
        AddConfiguration(BaseSuiteName, 40000, 'SEED-2+WORKDATEFUTURE-2YEAR');
        AddConfiguration(BaseSuiteName, 50000, 'REVERSE-METHODS');
    end;

    local procedure AddConfiguration(BaseSuiteName: Code[10]; LineNo: Integer; Configuration: Text[250])
    var
        StabilityRunConfiguration: Record "Stability Run Configuration";
    begin
        StabilityRunConfiguration.Init();
        StabilityRunConfiguration."Base Suite" := BaseSuiteName;
        StabilityRunConfiguration."Line No." := LineNo;
        StabilityRunConfiguration."Configuration" := Configuration;
        StabilityRunConfiguration."Enabled" := true;
        StabilityRunConfiguration.Insert(true);
    end;

    local procedure RunCombination(BaseSuite: Record "AL Test Suite"; ConfigurationLineNo: Integer; Configuration: Text[250])
    var
        GeneratedSuite: Record "AL Test Suite";
        GeneratedTestMethodLine: Record "Test Method Line";
        AnySeedOverride: Codeunit "Any Seed Override";
        GeneratedSuiteName: Code[10];
    begin
        GeneratedSuiteName := GetGeneratedSuiteName(ConfigurationLineNo);

        StabilityContext.Activate(BaseSuite.Name, GeneratedSuiteName, Configuration);
        StabilityPreset.ApplyToContext(StabilityContext, Configuration);

        CloneSuite(BaseSuite, GeneratedSuite, GeneratedSuiteName);
        TestSuiteMgt.ChangeStabilityRun(GeneratedSuite, StabilityContext.OneByOne());

        // Start from a clean override so a combination without SEED-* is not affected by a previous one.
        AnySeedOverride.ClearOverride();
        if StabilityContext.IsSeedOverridden() then
            AnySeedOverride.SetOverride(StabilityContext.Seed());

        GeneratedTestMethodLine.SetRange("Test Suite", GeneratedSuiteName);
        if GeneratedTestMethodLine.FindFirst() then
            if StabilityContext.OneByOne() then begin
                while TestSuiteMgt.RunNextTest(GeneratedTestMethodLine) do;
            end else
                TestSuiteMgt.RunAllTests(GeneratedTestMethodLine);

        AnySeedOverride.ClearOverride();
        StabilityContext.Deactivate();
    end;

    local procedure CloneSuite(BaseSuite: Record "AL Test Suite"; var GeneratedSuite: Record "AL Test Suite"; GeneratedSuiteName: Code[10])
    var
        BaseCodeunitLine: Record "Test Method Line";
        BaseFunctionLine: Record "Test Method Line";
        LineNoCounter: Integer;
    begin
        if GeneratedSuite.Get(GeneratedSuiteName) then begin
            TestSuiteMgt.DeleteAllMethods(GeneratedSuite);
            GeneratedSuite.Delete(true);
        end;

        GeneratedSuite.Init();
        GeneratedSuite.Name := GeneratedSuiteName;
        GeneratedSuite."Test Runner Id" := BaseSuite."Test Runner Id";
        GeneratedSuite.Insert(true);

        LineNoCounter := 0;

        BaseCodeunitLine.SetRange("Test Suite", BaseSuite.Name);
        BaseCodeunitLine.SetRange("Line Type", BaseCodeunitLine."Line Type"::Codeunit);
        BaseCodeunitLine.Ascending(not StabilityContext.ReverseCodeunits());
        if BaseCodeunitLine.FindSet() then
            repeat
                LineNoCounter += 10000;
                InsertClonedLine(GeneratedSuiteName, BaseCodeunitLine, LineNoCounter);

                BaseFunctionLine.SetRange("Test Suite", BaseSuite.Name);
                BaseFunctionLine.SetRange("Line Type", BaseFunctionLine."Line Type"::"Function");
                BaseFunctionLine.SetRange("Test Codeunit", BaseCodeunitLine."Test Codeunit");
                BaseFunctionLine.Ascending(not StabilityContext.ReverseMethods());
                if BaseFunctionLine.FindSet() then
                    repeat
                        LineNoCounter += 10;
                        InsertClonedLine(GeneratedSuiteName, BaseFunctionLine, LineNoCounter);
                    until BaseFunctionLine.Next() = 0;
            until BaseCodeunitLine.Next() = 0;
    end;

    local procedure InsertClonedLine(GeneratedSuiteName: Code[10]; SourceLine: Record "Test Method Line"; NewLineNo: Integer)
    var
        NewLine: Record "Test Method Line";
    begin
        NewLine.Init();
        NewLine."Test Suite" := GeneratedSuiteName;
        NewLine."Line No." := NewLineNo;
        NewLine."Line Type" := SourceLine."Line Type";
        NewLine."Test Codeunit" := SourceLine."Test Codeunit";
        NewLine.Name := SourceLine.Name;
        NewLine."Function" := SourceLine."Function";
        NewLine.Run := SourceLine.Run;
        NewLine.Level := SourceLine.Level;
        NewLine.Insert(true);
    end;

    local procedure GetGeneratedSuiteName(ConfigurationLineNo: Integer): Code[10]
    begin
        exit(CopyStr(StrSubstNo('%1%2', GeneratedSuitePrefixTok, ConfigurationLineNo), 1, 10));
    end;

    /// <summary>
    /// Serializes all stored stability results for a base suite to JSON.
    /// </summary>
    /// <param name="BaseSuiteName">The name of the base test suite.</param>
    /// <returns>The stability results serialized to JSON.</returns>
    procedure ResultsToJson(BaseSuiteName: Code[10]): Text
    var
        StabilityRunResult: Record "Stability Run Result";
        RootObject: JsonObject;
        ResultsArray: JsonArray;
        ResultObject: JsonObject;
        ResultText: Text;
        TotalCount: Integer;
        FailureCount: Integer;
    begin
        StabilityRunResult.SetRange("Base Suite", BaseSuiteName);
        if StabilityRunResult.FindSet() then
            repeat
                Clear(ResultObject);
                ResultObject.Add('configuration', StabilityRunResult."Configuration");
                ResultObject.Add('generatedSuite', StabilityRunResult."Generated Suite");
                ResultObject.Add('testCodeunit', StabilityRunResult."Test Codeunit");
                ResultObject.Add('codeunitName', StabilityRunResult."Codeunit Name");
                ResultObject.Add('method', StabilityRunResult."Method");
                ResultObject.Add('result', Format(StabilityRunResult."Result"));
                ResultObject.Add('seed', StabilityRunResult."Seed");
                ResultObject.Add('seedOverridden', StabilityRunResult."Seed Overridden");
                ResultObject.Add('workDateOffset', StabilityRunResult."WorkDate Offset");
                ResultObject.Add('workDate', Format(StabilityRunResult."WorkDate", 0, 9));
                ResultObject.Add('reverseCodeunits', StabilityRunResult."Reverse Codeunits");
                ResultObject.Add('reverseMethods', StabilityRunResult."Reverse Methods");
                ResultObject.Add('oneByOne', StabilityRunResult."One By One");
                ResultObject.Add('duration', Format(StabilityRunResult."Duration"));
                ResultObject.Add('errorMessage', StabilityRunResult.GetErrorMessage());
                ResultObject.Add('errorCallStack', StabilityRunResult.GetErrorCallStack());
                ResultsArray.Add(ResultObject);

                TotalCount += 1;
                if StabilityRunResult."Result" = StabilityRunResult."Result"::Failure then
                    FailureCount += 1;
            until StabilityRunResult.Next() = 0;

        RootObject.Add('baseSuite', BaseSuiteName);
        RootObject.Add('total', TotalCount);
        RootObject.Add('failures', FailureCount);
        RootObject.Add('results', ResultsArray);
        RootObject.WriteTo(ResultText);
        exit(ResultText);
    end;
}
