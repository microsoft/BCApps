// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

using System.TestLibraries.Utilities;

/// <summary>
/// Orchestrates a stability run. For every enabled configuration it runs the base suite in place
/// (applying the requested execution order and isolation), asks each provider to prepare the shared
/// context and seeds the random libraries when requested. No extra suites are created: the outcome of
/// every test method is captured after each configuration and, once all configurations have run, the
/// aggregated result is written back onto the base suite's own test method lines. When a method fails
/// under more than one configuration the individual error messages are concatenated into that line's
/// error message, so the results can be reviewed in the normal AL Test Tool.
/// </summary>
codeunit 130473 "Test Configuration Mgt"
{
    Permissions = tabledata "AL Test Suite" = rimd,
                  tabledata "Test Method Line" = rimd,
                  tabledata "Test Configuration" = rimd,
                  tabledata "Test Configuration Line" = rimd;

    var
        TestConfigurationContext: Codeunit "Test Configuration Context";
        TestSuiteMgt: Codeunit "Test Suite Mgt.";
        FailedMethods: Dictionary of [Text, Boolean];
        BestResult: Dictionary of [Text, Integer];
        AggMessages: Dictionary of [Text, Text];
        AggStacks: Dictionary of [Text, Text];
        ConfigResults: JsonArray;
        StoppedEarly: Boolean;
        SuiteNotFoundErr: Label 'Test suite %1 was not found.', Comment = '%1 = suite name';
        ConfigHeaderTok: Label '=== %1 ===', Comment = '%1 = configuration code', Locked = true;
        KeyTok: Label '%1|%2', Locked = true;

    /// <summary>
    /// Runs the enabled configurations against the base suite in order, clearing the previous
    /// configuration's results before each run. The run stops as soon as a configuration produces a
    /// failure, so the failing state is preserved for troubleshooting and later configurations are not
    /// run. The aggregated outcome is written onto the base suite's test method lines and returned as
    /// JSON. If no configurations exist yet, a default, editable set is created first.
    /// </summary>
    /// <param name="BaseSuiteName">The name of the base test suite.</param>
    /// <returns>The results serialized to JSON.</returns>
    procedure RunTestConfigurations(BaseSuiteName: Code[10]): Text
    var
        BaseSuite: Record "AL Test Suite";
        TestConfiguration: Record "Test Configuration";
        ConfiguredRandomSeed: Codeunit "Configured Random Seed";
    begin
        if not BaseSuite.Get(BaseSuiteName) then
            Error(SuiteNotFoundErr, BaseSuiteName);

        // Defensively leave stability mode before starting. Stability state lives in a single-instance
        // codeunit and is not rolled back if a previous run errored out before it could exit, so this
        // self-heals any stale flag/seed from an aborted run and prevents it from affecting this run.
        ConfiguredRandomSeed.ExitStabilityMode();

        EnsureDefaultConfigurations();
        // Validate every enabled configuration before entering stability mode, so bad settings (for
        // example an invalid WorkDate formula) are reported up front and cannot leave stability mode
        // active for later runs.
        ValidateConfigurations();
        ClearAggregation();

        ConfiguredRandomSeed.EnterStabilityMode();
        TestConfiguration.SetRange("Enabled", true);
        if TestConfiguration.FindSet() then
            repeat
                // Stop as soon as a configuration produces a failure so the failing state is preserved
                // for troubleshooting and the remaining configurations are not run.
                if RunConfiguration(BaseSuite, TestConfiguration) then
                    StoppedEarly := true;
            until (TestConfiguration.Next() = 0) or StoppedEarly;
        ConfiguredRandomSeed.ExitStabilityMode();

        WriteAggregatedResults(BaseSuite);
        exit(ResultsToJson(BaseSuiteName));
    end;

    /// <summary>
    /// Exits stability mode and resets the base suite to a clean state without running any triggers.
    /// This is the safe way to leave stability mode: the stored seed is cleared, the isolation flag is
    /// turned off and every result on the base suite is cleared using trigger free writes.
    /// </summary>
    /// <param name="BaseSuiteName">The name of the base test suite.</param>
    procedure ResetStabilityMode(BaseSuiteName: Code[10])
    var
        BaseSuite: Record "AL Test Suite";
        TestMethodLine: Record "Test Method Line";
        ConfiguredRandomSeed: Codeunit "Configured Random Seed";
    begin
        TestConfigurationContext.Deactivate();
        ConfiguredRandomSeed.ExitStabilityMode();

        if not BaseSuite.Get(BaseSuiteName) then
            exit;

        if BaseSuite."Stability Run" then begin
            BaseSuite."Stability Run" := false;
            BaseSuite.Modify(false);
        end;

        TestMethodLine.SetRange("Test Suite", BaseSuiteName);
        if TestMethodLine.FindSet(true) then
            repeat
                TestMethodLine.Result := TestMethodLine.Result::" ";
                ClearLineError(TestMethodLine);
                TestMethodLine."Start Time" := 0DT;
                TestMethodLine."Finish Time" := 0DT;
                TestMethodLine.Modify(false);
            until TestMethodLine.Next() = 0;
    end;

    local procedure RunConfiguration(var BaseSuite: Record "AL Test Suite"; TestConfiguration: Record "Test Configuration"): Boolean
    var
        ConfiguredRandomSeed: Codeunit "Configured Random Seed";
    begin
        TestConfigurationContext.Activate(BaseSuite.Name, TestConfiguration."Code");
        PrepareProviders(TestConfiguration."Code");

        // Clear the previous configuration's results so this configuration starts from a clean suite.
        ClearSuiteResults(BaseSuite.Name);

        // Start from a clean seed so a configuration without a seed provider is not affected by a
        // previous one; "Reset State Before Test Run" reads this before every test method.
        ConfiguredRandomSeed.ClearSeed();
        if TestConfigurationContext.IsSeedSet() then
            ConfiguredRandomSeed.SetSeed(TestConfigurationContext.Seed());

        ExecuteSuite(BaseSuite);

        ConfiguredRandomSeed.ClearSeed();
        TestConfigurationContext.Deactivate();

        exit(CaptureConfigResults(BaseSuite.Name, TestConfiguration));
    end;

    local procedure ExecuteSuite(var BaseSuite: Record "AL Test Suite")
    var
        TestMethodLine: Record "Test Method Line";
    begin
        if TestConfigurationContext.OneByOne() then begin
            RunOneByOne(BaseSuite);
            exit;
        end;

        TestMethodLine.SetRange("Test Suite", BaseSuite.Name);
        TestMethodLine.SetCurrentKey("Test Suite", "Line No.");
        // Reverse order is realized by iterating the suite lines from the last to the first, which the
        // test runner honors for the codeunit sequence. The run stays a normal, shared state run.
        TestMethodLine.Ascending(not TestConfigurationContext.ReverseOrder());
        if TestMethodLine.FindSet() then
            TestSuiteMgt.RunTests(TestMethodLine, BaseSuite);
    end;

    local procedure RunOneByOne(var BaseSuite: Record "AL Test Suite")
    var
        TestMethodLine: Record "Test Method Line";
        OriginalStabilityRun: Boolean;
        RemainingBefore: Integer;
        RemainingAfter: Integer;
    begin
        // One by one runs each test method on its own so its setup runs again for that method only.
        OriginalStabilityRun := BaseSuite."Stability Run";
        TestSuiteMgt.ChangeStabilityRun(BaseSuite, true);

        TestMethodLine.SetRange("Test Suite", BaseSuite.Name);
        if TestMethodLine.FindFirst() then begin
            RemainingBefore := CountUnrunCodeunits(BaseSuite.Name);
            while RemainingBefore > 0 do begin
                if not TestSuiteMgt.RunNextTest(TestMethodLine) then
                    RemainingBefore := 0
                else begin
                    RemainingAfter := CountUnrunCodeunits(BaseSuite.Name);
                    // A codeunit with no runnable method never gets a result, so RunNextTest would keep
                    // reselecting it. Mark just that codeunit skipped so the remaining codeunits still run.
                    if RemainingAfter >= RemainingBefore then
                        SkipFirstUnrunCodeunit(BaseSuite.Name);
                    RemainingBefore := CountUnrunCodeunits(BaseSuite.Name);
                end;
            end;
        end;

        TestSuiteMgt.ChangeStabilityRun(BaseSuite, OriginalStabilityRun);
    end;

    local procedure ClearSuiteResults(SuiteName: Code[10])
    var
        TestMethodLine: Record "Test Method Line";
    begin
        // Trigger free reset, matching how the platform runner clears results before a run.
        TestMethodLine.SetRange("Test Suite", SuiteName);
        TestMethodLine.ModifyAll("Error Message Preview", '');
        TestMethodLine.ModifyAll(Result, TestMethodLine.Result::" ");
    end;

    local procedure SkipFirstUnrunCodeunit(SuiteName: Code[10])
    var
        CodeunitLine: Record "Test Method Line";
    begin
        CodeunitLine.SetRange("Test Suite", SuiteName);
        CodeunitLine.SetRange("Line Type", CodeunitLine."Line Type"::Codeunit);
        CodeunitLine.SetRange(Result, CodeunitLine.Result::" ");
        CodeunitLine.SetRange(Run, true);
        if CodeunitLine.FindFirst() then begin
            CodeunitLine.Result := CodeunitLine.Result::Skipped;
            CodeunitLine.Modify(false);
        end;
    end;

    local procedure CountUnrunCodeunits(SuiteName: Code[10]): Integer
    var
        CodeunitLine: Record "Test Method Line";
    begin
        CodeunitLine.SetRange("Test Suite", SuiteName);
        CodeunitLine.SetRange("Line Type", CodeunitLine."Line Type"::Codeunit);
        CodeunitLine.SetRange(Result, CodeunitLine.Result::" ");
        CodeunitLine.SetRange(Run, true);
        exit(CodeunitLine.Count());
    end;

    local procedure ValidateConfigurations()
    var
        TestConfiguration: Record "Test Configuration";
        TestConfigurationLine: Record "Test Configuration Line";
        Provider: Interface "ITest Configuration Provider";
    begin
        TestConfiguration.SetRange("Enabled", true);
        if TestConfiguration.FindSet() then
            repeat
                TestConfigurationLine.SetRange("Configuration Code", TestConfiguration."Code");
                TestConfigurationLine.SetRange("Enabled", true);
                if TestConfigurationLine.FindSet() then
                    repeat
                        Provider := TestConfigurationLine."Provider";
                        Provider.Validate(TestConfigurationLine.GetSettings());
                    until TestConfigurationLine.Next() = 0;
            until TestConfiguration.Next() = 0;
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

    local procedure CaptureConfigResults(BaseSuiteName: Code[10]; TestConfiguration: Record "Test Configuration"): Boolean
    var
        TestMethodLine: Record "Test Method Line";
        ConfigObject: JsonObject;
        LineKey: Text;
        ConfigCode: Code[20];
        ConfigTotal: Integer;
        ConfigFailures: Integer;
    begin
        ConfigCode := TestConfiguration."Code";
        TestMethodLine.SetRange("Test Suite", BaseSuiteName);
        TestMethodLine.SetRange("Line Type", TestMethodLine."Line Type"::"Function");
        if TestMethodLine.FindSet() then
            repeat
                LineKey := MakeKey(TestMethodLine."Test Codeunit", TestMethodLine."Function");
                RecordBestResult(LineKey, TestMethodLine.Result);
                ConfigTotal += 1;
                if TestMethodLine.Result = TestMethodLine.Result::Failure then begin
                    ConfigFailures += 1;
                    FailedMethods.Set(LineKey, true);
                    AppendEntry(AggMessages, LineKey, StrSubstNo(ConfigHeaderTok, ConfigCode) + NewLine() + TestSuiteMgt.GetFullErrorMessage(TestMethodLine));
                    AppendEntry(AggStacks, LineKey, StrSubstNo(ConfigHeaderTok, ConfigCode) + NewLine() + TestSuiteMgt.GetErrorCallStack(TestMethodLine));
                end;
            until TestMethodLine.Next() = 0;

        // Keep an in memory summary per configuration so callers (for example the PowerShell script)
        // can report on every configuration that ran, including the one that stopped the run.
        Clear(ConfigObject);
        ConfigObject.Add('code', ConfigCode);
        ConfigObject.Add('description', TestConfiguration."Description");
        ConfigObject.Add('total', ConfigTotal);
        ConfigObject.Add('failures', ConfigFailures);
        ConfigResults.Add(ConfigObject);

        exit(ConfigFailures > 0);
    end;

    local procedure RecordBestResult(LineKey: Text; ResultValue: Option " ",Failure,Success,Skipped)
    var
        Priority: Integer;
    begin
        Priority := ResultPriority(ResultValue);
        if BestResult.ContainsKey(LineKey) then begin
            if Priority > BestResult.Get(LineKey) then
                BestResult.Set(LineKey, Priority);
        end else
            BestResult.Add(LineKey, Priority);
    end;

    local procedure ResultPriority(ResultValue: Option " ",Failure,Success,Skipped): Integer
    begin
        // A failure in any configuration wins, then a success, then skipped, then not executed.
        case ResultValue of
            ResultValue::Failure:
                exit(3);
            ResultValue::Success:
                exit(2);
            ResultValue::Skipped:
                exit(1);
            else
                exit(0);
        end;
    end;

    local procedure WriteAggregatedResults(var BaseSuite: Record "AL Test Suite")
    var
        FunctionLine: Record "Test Method Line";
        CodeunitLine: Record "Test Method Line";
        LineKey: Text;
    begin
        FunctionLine.SetRange("Test Suite", BaseSuite.Name);
        FunctionLine.SetRange("Line Type", FunctionLine."Line Type"::"Function");
        if FunctionLine.FindSet(true) then
            repeat
                LineKey := MakeKey(FunctionLine."Test Codeunit", FunctionLine."Function");
                ClearLineError(FunctionLine);
                ApplyBestResult(FunctionLine, LineKey);
                if FailedMethods.ContainsKey(LineKey) then begin
                    FunctionLine."Error Message Preview" := CopyStr(AggMessages.Get(LineKey), 1, MaxStrLen(FunctionLine."Error Message Preview"));
                    SetLineErrorMessage(FunctionLine, AggMessages.Get(LineKey));
                    SetLineErrorCallStack(FunctionLine, AggStacks.Get(LineKey));
                end;
                FunctionLine.Modify(false);
            until FunctionLine.Next() = 0;

        CodeunitLine.SetRange("Test Suite", BaseSuite.Name);
        CodeunitLine.SetRange("Line Type", CodeunitLine."Line Type"::Codeunit);
        if CodeunitLine.FindSet(true) then
            repeat
                CodeunitLine.Result := CodeunitResult(BaseSuite.Name, CodeunitLine."Test Codeunit");
                CodeunitLine.Modify(false);
            until CodeunitLine.Next() = 0;
    end;

    local procedure ApplyBestResult(var FunctionLine: Record "Test Method Line"; LineKey: Text)
    var
        Priority: Integer;
    begin
        if not BestResult.ContainsKey(LineKey) then begin
            FunctionLine.Result := FunctionLine.Result::" ";
            exit;
        end;
        Priority := BestResult.Get(LineKey);
        case Priority of
            3:
                FunctionLine.Result := FunctionLine.Result::Failure;
            2:
                FunctionLine.Result := FunctionLine.Result::Success;
            1:
                FunctionLine.Result := FunctionLine.Result::Skipped;
            else
                FunctionLine.Result := FunctionLine.Result::" ";
        end;
    end;

    local procedure CodeunitResult(SuiteName: Code[10]; TestCodeunit: Integer): Integer
    var
        FunctionLine: Record "Test Method Line";
        BestPriority: Integer;
        Priority: Integer;
    begin
        // Roll the codeunit up from its function lines, keeping never-executed codeunits blank.
        FunctionLine.SetRange("Test Suite", SuiteName);
        FunctionLine.SetRange("Test Codeunit", TestCodeunit);
        FunctionLine.SetRange("Line Type", FunctionLine."Line Type"::"Function");
        if FunctionLine.FindSet() then
            repeat
                Priority := ResultPriority(FunctionLine.Result);
                if Priority > BestPriority then
                    BestPriority := Priority;
            until FunctionLine.Next() = 0;

        case BestPriority of
            3:
                exit(FunctionLine.Result::Failure);
            2:
                exit(FunctionLine.Result::Success);
            1:
                exit(FunctionLine.Result::Skipped);
            else
                exit(FunctionLine.Result::" ");
        end;
    end;

    local procedure ClearLineError(var TestMethodLine: Record "Test Method Line")
    begin
        Clear(TestMethodLine."Error Message");
        Clear(TestMethodLine."Error Call Stack");
        TestMethodLine."Error Code" := '';
        TestMethodLine."Error Message Preview" := '';
    end;

    local procedure SetLineErrorMessage(var TestMethodLine: Record "Test Method Line"; Message: Text)
    var
        OutStr: OutStream;
    begin
        Clear(TestMethodLine."Error Message");
        TestMethodLine."Error Message".CreateOutStream(OutStr, TextEncoding::UTF16);
        OutStr.WriteText(Message);
    end;

    local procedure SetLineErrorCallStack(var TestMethodLine: Record "Test Method Line"; CallStack: Text)
    var
        OutStr: OutStream;
    begin
        Clear(TestMethodLine."Error Call Stack");
        TestMethodLine."Error Call Stack".CreateOutStream(OutStr, TextEncoding::UTF16);
        OutStr.WriteText(CallStack);
    end;

    local procedure AppendEntry(var Entries: Dictionary of [Text, Text]; LineKey: Text; Entry: Text)
    begin
        if Entries.ContainsKey(LineKey) then
            Entries.Set(LineKey, Entries.Get(LineKey) + NewLine() + NewLine() + Entry)
        else
            Entries.Add(LineKey, Entry);
    end;

    local procedure MakeKey(TestCodeunit: Integer; FunctionName: Text[128]): Text
    begin
        exit(StrSubstNo(KeyTok, TestCodeunit, FunctionName));
    end;

    local procedure NewLine(): Text
    var
        CarriageReturn: Char;
        LineFeed: Char;
    begin
        CarriageReturn := 13;
        LineFeed := 10;
        exit(Format(CarriageReturn) + Format(LineFeed));
    end;

    local procedure ClearAggregation()
    begin
        Clear(FailedMethods);
        Clear(BestResult);
        Clear(AggMessages);
        Clear(AggStacks);
        Clear(ConfigResults);
        StoppedEarly := false;
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

        AddConfiguration('REVERSE', 'Runs the suite in reverse order.');
        AddLine('REVERSE', 10000, "Test Configuration Provider"::ReverseOrder, EmptySettings());
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
        TestConfigurationLine.Insert(true);
        TestConfigurationLine.SetSettings(Settings);
        TestConfigurationLine.Modify(true);
    end;

    local procedure EmptySettings() Settings: JsonObject
    begin
    end;

    /// <summary>
    /// Serializes the aggregated results stored on the base suite's test method lines to JSON.
    /// </summary>
    /// <param name="BaseSuiteName">The name of the base test suite.</param>
    /// <returns>The results serialized to JSON.</returns>
    procedure ResultsToJson(BaseSuiteName: Code[10]): Text
    var
        TestMethodLine: Record "Test Method Line";
        RootObject: JsonObject;
        ResultsArray: JsonArray;
        ResultObject: JsonObject;
        ResultText: Text;
        TotalCount: Integer;
        FailureCount: Integer;
    begin
        TestMethodLine.SetRange("Test Suite", BaseSuiteName);
        TestMethodLine.SetRange("Line Type", TestMethodLine."Line Type"::"Function");
        if TestMethodLine.FindSet() then
            repeat
                Clear(ResultObject);
                ResultObject.Add('testCodeunit', TestMethodLine."Test Codeunit");
                ResultObject.Add('method', TestMethodLine."Function");
                ResultObject.Add('result', Format(TestMethodLine.Result));
                if TestMethodLine.Result = TestMethodLine.Result::Failure then begin
                    ResultObject.Add('errorMessage', TestSuiteMgt.GetFullErrorMessage(TestMethodLine));
                    ResultObject.Add('errorCallStack', TestSuiteMgt.GetErrorCallStack(TestMethodLine));
                    FailureCount += 1;
                end;
                ResultsArray.Add(ResultObject);
                TotalCount += 1;
            until TestMethodLine.Next() = 0;

        RootObject.Add('baseSuite', BaseSuiteName);
        RootObject.Add('total', TotalCount);
        RootObject.Add('failures', FailureCount);
        RootObject.Add('stoppedEarly', StoppedEarly);
        RootObject.Add('configurations', ConfigResults);
        RootObject.Add('results', ResultsArray);
        RootObject.WriteTo(ResultText);
        exit(ResultText);
    end;
}
