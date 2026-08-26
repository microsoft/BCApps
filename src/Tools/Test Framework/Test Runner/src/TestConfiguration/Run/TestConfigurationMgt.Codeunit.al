// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

using System.TestLibraries.Utilities;

/// <summary>
/// Orchestrates a test configuration run. For every enabled configuration it clones the base suite
/// (applying the requested execution order), asks each provider to prepare the shared context, seeds
/// the random libraries when requested and executes the clone. The outcome of every test method is
/// captured by codeunit "Test Configuration Runner". This surfaces flaky, order dependent and data
/// dependent tests.
/// </summary>
codeunit 130473 "Test Configuration Mgt"
{
    Permissions = tabledata "AL Test Suite" = rimd,
                  tabledata "Test Method Line" = rimd,
                  tabledata "Test Configuration" = rimd,
                  tabledata "Test Configuration Line" = rimd,
                  tabledata "Test Configuration Run Result" = rimd;

    var
        TestConfigurationContext: Codeunit "Test Configuration Context";
        TestSuiteMgt: Codeunit "Test Suite Mgt.";
        GeneratedSuitePrefixTok: Label 'TCFG', Locked = true;
        SuiteNotFoundErr: Label 'Test suite %1 was not found.', Comment = '%1 = suite name';

    /// <summary>
    /// Runs every enabled configuration against the base suite and returns the results as JSON.
    /// If no configurations exist yet, a default, editable set is created first.
    /// </summary>
    /// <param name="BaseSuiteName">The name of the base test suite.</param>
    /// <returns>The results serialized to JSON.</returns>
    procedure RunTestConfigurations(BaseSuiteName: Code[10]): Text
    var
        BaseSuite: Record "AL Test Suite";
        TestConfiguration: Record "Test Configuration";
        TestConfigurationRunResult: Record "Test Configuration Run Result";
        GeneratedSuiteNo: Integer;
    begin
        if not BaseSuite.Get(BaseSuiteName) then
            Error(SuiteNotFoundErr, BaseSuiteName);

        EnsureDefaultConfigurations();

        TestConfigurationRunResult.SetRange("Base Suite", BaseSuiteName);
        TestConfigurationRunResult.DeleteAll();

        GeneratedSuiteNo := 0;
        TestConfiguration.SetRange("Enabled", true);
        if TestConfiguration.FindSet() then
            repeat
                GeneratedSuiteNo += 1;
                RunConfiguration(BaseSuite, TestConfiguration, GeneratedSuiteNo);
            until TestConfiguration.Next() = 0;

        exit(ResultsToJson(BaseSuiteName));
    end;

    local procedure RunConfiguration(BaseSuite: Record "AL Test Suite"; TestConfiguration: Record "Test Configuration"; GeneratedSuiteNo: Integer)
    var
        GeneratedSuite: Record "AL Test Suite";
        GeneratedTestMethodLine: Record "Test Method Line";
        ConfiguredRandomSeed: Codeunit "Configured Random Seed";
        GeneratedSuiteName: Code[10];
    begin
        GeneratedSuiteName := GetGeneratedSuiteName(GeneratedSuiteNo);

        TestConfigurationContext.Activate(BaseSuite.Name, GeneratedSuiteName, TestConfiguration."Code");
        PrepareProviders(TestConfiguration."Code");

        CloneSuite(BaseSuite, GeneratedSuite, GeneratedSuiteName);
        TestSuiteMgt.ChangeStabilityRun(GeneratedSuite, TestConfigurationContext.OneByOne());

        // Start from a clean seed so a configuration without a seed provider is not affected by a previous one.
        ConfiguredRandomSeed.ClearSeed();
        if TestConfigurationContext.IsSeedSet() then
            ConfiguredRandomSeed.SetSeed(TestConfigurationContext.Seed());

        GeneratedTestMethodLine.SetRange("Test Suite", GeneratedSuiteName);
        if GeneratedTestMethodLine.FindFirst() then
            if TestConfigurationContext.OneByOne() then begin
                while TestSuiteMgt.RunNextTest(GeneratedTestMethodLine) do;
            end else
                TestSuiteMgt.RunAllTests(GeneratedTestMethodLine);

        // Leave the seed store and context inactive so a later regular test run is unaffected.
        ConfiguredRandomSeed.ClearSeed();
        TestConfigurationContext.Deactivate();
    end;

    local procedure PrepareProviders(ConfigCode: Code[20])
    var
        TestConfigurationLine: Record "Test Configuration Line";
        Provider: Interface "ITest Configuration Provider";
    begin
        TestConfigurationLine.SetRange("Configuration Code", ConfigCode);
        TestConfigurationLine.SetRange("Enabled", true);
        if TestConfigurationLine.FindSet() then
            repeat
                Provider := TestConfigurationLine."Provider";
                Provider.Prepare(TestConfigurationLine.GetSettings(), TestConfigurationContext);
            until TestConfigurationLine.Next() = 0;
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
        BaseCodeunitLine.Ascending(not TestConfigurationContext.ReverseCodeunits());
        if BaseCodeunitLine.FindSet() then
            repeat
                LineNoCounter += 10000;
                InsertClonedLine(GeneratedSuiteName, BaseCodeunitLine, LineNoCounter);

                BaseFunctionLine.SetRange("Test Suite", BaseSuite.Name);
                BaseFunctionLine.SetRange("Line Type", BaseFunctionLine."Line Type"::"Function");
                BaseFunctionLine.SetRange("Test Codeunit", BaseCodeunitLine."Test Codeunit");
                BaseFunctionLine.Ascending(not TestConfigurationContext.ReverseMethods());
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

    local procedure GetGeneratedSuiteName(GeneratedSuiteNo: Integer): Code[10]
    begin
        exit(CopyStr(StrSubstNo('%1%2', GeneratedSuitePrefixTok, GeneratedSuiteNo), 1, 10));
    end;

    /// <summary>
    /// Creates the default set of configurations when none exist yet. The set is editable afterwards.
    /// </summary>
    procedure EnsureDefaultConfigurations()
    var
        TestConfiguration: Record "Test Configuration";
        SeedSettings: JsonObject;
        WorkDateSettings: JsonObject;
    begin
        if not TestConfiguration.IsEmpty() then
            exit;

        AddConfiguration('BASELINE', 'Runs the suite without any changes.');

        AddConfiguration('SEED1-WD1Y', 'Random seed 1 and WorkDate one year in the future.');
        Clear(SeedSettings);
        SeedSettings.Add('seed', 1);
        AddLine('SEED1-WD1Y', 10000, "Test Configuration Provider"::Seed, SeedSettings);
        Clear(WorkDateSettings);
        WorkDateSettings.Add('formula', '<1Y>');
        AddLine('SEED1-WD1Y', 20000, "Test Configuration Provider"::WorkDateFuture, WorkDateSettings);

        AddConfiguration('ONEBYONE', 'Runs each test method in isolation.');
        AddLine('ONEBYONE', 10000, "Test Configuration Provider"::OneByOne, EmptySettings());

        AddConfiguration('SEED2-WD2Y', 'Random seed 2 and WorkDate two years in the future.');
        Clear(SeedSettings);
        SeedSettings.Add('seed', 2);
        AddLine('SEED2-WD2Y', 10000, "Test Configuration Provider"::Seed, SeedSettings);
        Clear(WorkDateSettings);
        WorkDateSettings.Add('formula', '<2Y>');
        AddLine('SEED2-WD2Y', 20000, "Test Configuration Provider"::WorkDateFuture, WorkDateSettings);

        AddConfiguration('REVERSE-METH', 'Runs the test methods in reverse order.');
        AddLine('REVERSE-METH', 10000, "Test Configuration Provider"::ReverseMethods, EmptySettings());
    end;

    local procedure AddConfiguration(ConfigCode: Code[20]; Description: Text[100])
    var
        TestConfiguration: Record "Test Configuration";
    begin
        if TestConfiguration.Get(ConfigCode) then
            exit;
        TestConfiguration.Init();
        TestConfiguration."Code" := ConfigCode;
        TestConfiguration."Description" := Description;
        TestConfiguration."Enabled" := true;
        TestConfiguration.Insert(true);
    end;

    local procedure AddLine(ConfigCode: Code[20]; LineNo: Integer; Provider: Enum "Test Configuration Provider"; Settings: JsonObject)
    var
        TestConfigurationLine: Record "Test Configuration Line";
    begin
        TestConfigurationLine.Init();
        TestConfigurationLine."Configuration Code" := ConfigCode;
        TestConfigurationLine."Line No." := LineNo;
        TestConfigurationLine."Provider" := Provider;
        TestConfigurationLine."Enabled" := true;
        TestConfigurationLine.SetSettings(Settings);
        TestConfigurationLine.Insert(true);
    end;

    local procedure EmptySettings() Settings: JsonObject
    begin
    end;

    /// <summary>
    /// Serializes all stored results for a base suite to JSON.
    /// </summary>
    /// <param name="BaseSuiteName">The name of the base test suite.</param>
    /// <returns>The results serialized to JSON.</returns>
    procedure ResultsToJson(BaseSuiteName: Code[10]): Text
    var
        TestConfigurationRunResult: Record "Test Configuration Run Result";
        RootObject: JsonObject;
        ResultsArray: JsonArray;
        ResultObject: JsonObject;
        ResultText: Text;
        TotalCount: Integer;
        FailureCount: Integer;
    begin
        TestConfigurationRunResult.SetRange("Base Suite", BaseSuiteName);
        if TestConfigurationRunResult.FindSet() then
            repeat
                Clear(ResultObject);
                ResultObject.Add('configuration', TestConfigurationRunResult."Configuration");
                ResultObject.Add('generatedSuite', TestConfigurationRunResult."Generated Suite");
                ResultObject.Add('testCodeunit', TestConfigurationRunResult."Test Codeunit");
                ResultObject.Add('codeunitName', TestConfigurationRunResult."Codeunit Name");
                ResultObject.Add('method', TestConfigurationRunResult."Method");
                ResultObject.Add('result', Format(TestConfigurationRunResult."Result"));
                ResultObject.Add('seed', TestConfigurationRunResult."Seed");
                ResultObject.Add('seedSet', TestConfigurationRunResult."Seed Set");
                ResultObject.Add('workDateOffset', TestConfigurationRunResult."WorkDate Offset");
                ResultObject.Add('workDate', Format(TestConfigurationRunResult."WorkDate", 0, 9));
                ResultObject.Add('reverseCodeunits', TestConfigurationRunResult."Reverse Codeunits");
                ResultObject.Add('reverseMethods', TestConfigurationRunResult."Reverse Methods");
                ResultObject.Add('oneByOne', TestConfigurationRunResult."One By One");
                ResultObject.Add('duration', Format(TestConfigurationRunResult."Duration"));
                ResultObject.Add('errorMessage', TestConfigurationRunResult.GetErrorMessage());
                ResultObject.Add('errorCallStack', TestConfigurationRunResult.GetErrorCallStack());
                ResultsArray.Add(ResultObject);

                TotalCount += 1;
                if TestConfigurationRunResult."Result" = TestConfigurationRunResult."Result"::Failure then
                    FailureCount += 1;
            until TestConfigurationRunResult.Next() = 0;

        RootObject.Add('baseSuite', BaseSuiteName);
        RootObject.Add('total', TotalCount);
        RootObject.Add('failures', FailureCount);
        RootObject.Add('results', ResultsArray);
        RootObject.WriteTo(ResultText);
        exit(ResultText);
    end;
}
