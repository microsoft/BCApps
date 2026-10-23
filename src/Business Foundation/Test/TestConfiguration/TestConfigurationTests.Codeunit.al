// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner.Tests;

using System.TestLibraries.Utilities;
using System.TestTools.TestRunner;

codeunit 134549 "Test Configuration Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";
        TestConfigurationMgt: Codeunit "Test Configuration Mgt";
        TestSuiteMgt: Codeunit "Test Suite Mgt.";

    [Test]
    procedure CombinedLayoutPreservesSource()
    var
        ParentSuite: Record "AL Test Suite";
        GeneratedSuite: Record "AL Test Suite";
        Configuration: Record "Test Configuration";
        TestMethodLine: Record "Test Method Line";
        SuiteNames: List of [Code[10]];
        ExpectedMethods: List of [Text];
        MethodIndex: Integer;
    begin
        CreateSource(ParentSuite);
        CreateConfiguration(ParentSuite.Name, 'COMBINED', Configuration);
        Configuration."One By One" := true;
        Configuration."Reverse Order" := true;
        Configuration.Modify();

        SuiteNames := TestConfigurationMgt.GenerateStabilitySuites(ParentSuite.Name);

        GeneratedSuite.Get(SuiteNames.Get(1));
        LibraryAssert.AreEqual(ParentSuite.Name, GeneratedSuite."Created From Suite", 'The generated suite must retain its parent.');
        LibraryAssert.IsFalse(GeneratedSuite."Stability Run", 'Generated layouts must not use the legacy per-method loop.');
        LibraryAssert.AreEqual(ParentSuite."Test Runner Id", GeneratedSuite."Test Runner Id", 'Generation must preserve the selected runner.');
        TestMethodLine.SetRange("Test Suite", GeneratedSuite.Name);
        TestMethodLine.SetRange("Line Type", TestMethodLine."Line Type"::Codeunit);
        LibraryAssert.AreEqual(4, TestMethodLine.Count(), 'Each method needs its own header.');
        TestMethodLine.SetRange("Line Type", TestMethodLine."Line Type"::Function);
        ExpectedMethods := 'B1,B2,A1,A2'.Split(',');
        TestMethodLine.FindSet();
        repeat
            MethodIndex += 1;
            LibraryAssert.AreEqual(ExpectedMethods.Get(MethodIndex), TestMethodLine.Name, 'Reverse must retain method order within the source block.');
            LibraryAssert.AreEqual(TestMethodLine.Result::" ", TestMethodLine.Result, 'Generated results must be empty.');
            LibraryAssert.AreEqual(0DT, TestMethodLine."Start Time", 'Generated timing must be empty.');
            if TestMethodLine.Name = 'A1' then
                LibraryAssert.AreEqual('INPUT1', TestMethodLine."Data Input", 'Expanded input identity must be copied.');
        until TestMethodLine.Next() = 0;

        ParentSuite.Get(ParentSuite.Name);
        LibraryAssert.IsTrue(ParentSuite."Stability Run", 'The source legacy flag must not change.');
        TestMethodLine.Get(ParentSuite.Name, 10001);
        LibraryAssert.AreEqual(TestMethodLine.Result::Failure, TestMethodLine.Result, 'The source result must not change.');
        LibraryAssert.AreEqual(CreateDateTime(20260101D, 010000T), TestMethodLine."Start Time", 'The source timing must not change.');
    end;

    [Test]
    procedure ReplacementUsesParentNotDeletedConfiguration()
    var
        ParentSuite: Record "AL Test Suite";
        GeneratedSuite: Record "AL Test Suite";
        Configuration: Record "Test Configuration";
        TestMethodLine: Record "Test Method Line";
        OldSuiteNames: List of [Code[10]];
        NewSuiteNames: List of [Code[10]];
        OldSuiteName: Code[10];
    begin
        CreateSource(ParentSuite);
        CreateConfiguration(ParentSuite.Name, 'A', Configuration);
        CreateConfiguration(ParentSuite.Name, 'B', Configuration);
        OldSuiteNames := TestConfigurationMgt.GenerateStabilitySuites(ParentSuite.Name);
        Configuration.Get(ParentSuite.Name, 'A');
        Configuration.Delete(true);

        NewSuiteNames := TestConfigurationMgt.GenerateStabilitySuites(ParentSuite.Name);

        LibraryAssert.AreEqual(1, NewSuiteNames.Count(), 'Only the remaining enabled configuration should be generated.');
        foreach OldSuiteName in OldSuiteNames do begin
            LibraryAssert.IsFalse(GeneratedSuite.Get(OldSuiteName), 'Run All must delete every previous parent output.');
            TestMethodLine.SetRange("Test Suite", OldSuiteName);
            LibraryAssert.IsTrue(TestMethodLine.IsEmpty(), 'Replacement must not leave orphan test lines.');
        end;
        CreateConfiguration(ParentSuite.Name, 'A', Configuration);
        TestConfigurationMgt.GenerateStabilitySuites(ParentSuite.Name, 'A');
        LibraryAssert.IsTrue(GeneratedSuite.Get(NewSuiteNames.Get(1)), 'Single-configuration generation must preserve the other configuration.');
    end;

    [Test]
    procedure EmptyAndDisabledConfigurationsErrorWithoutDefaults()
    var
        ParentSuite: Record "AL Test Suite";
        Configuration: Record "Test Configuration";
    begin
        CreateSource(ParentSuite);
        asserterror TestConfigurationMgt.GenerateStabilitySuites(ParentSuite.Name);
        LibraryAssert.ExpectedError('no enabled test configurations');
        Configuration.SetRange("Test Suite", ParentSuite.Name);
        LibraryAssert.IsTrue(Configuration.IsEmpty(), 'Generation must not silently create defaults.');

        CreateSource(ParentSuite);
        CreateConfiguration(ParentSuite.Name, 'DISABLED', Configuration);
        Configuration.Enabled := false;
        Configuration.Modify();
        asserterror TestConfigurationMgt.GenerateStabilitySuites(ParentSuite.Name);
        LibraryAssert.ExpectedError('no enabled test configurations');
    end;

    [Test]
    procedure DefaultsAreExplicitAndParentOwned()
    var
        FirstParent: Record "AL Test Suite";
        SecondParent: Record "AL Test Suite";
        Configuration: Record "Test Configuration";
    begin
        CreateSource(FirstParent);
        CreateSource(SecondParent);
        TestConfigurationMgt.EnsureDefaultConfigurations(FirstParent.Name);
        Configuration.Get(FirstParent.Name, 'BASELINE');
        Configuration.Enabled := false;
        Configuration.Modify();
        TestConfigurationMgt.EnsureDefaultConfigurations(FirstParent.Name);
        TestConfigurationMgt.EnsureDefaultConfigurations(SecondParent.Name);
        Configuration.Get(FirstParent.Name, 'BASELINE');
        LibraryAssert.IsFalse(Configuration.Enabled, 'Explicit setup must preserve edits.');
        Configuration.Get(SecondParent.Name, 'BASELINE');
        LibraryAssert.IsTrue(Configuration.Enabled, 'The other parent must have independent configurations.');
    end;

    [Test]
    procedure DeletingParentRemovesOnlyItsConfigurations()
    var
        FirstParent: Record "AL Test Suite";
        SecondParent: Record "AL Test Suite";
        Configuration: Record "Test Configuration";
    begin
        CreateSource(FirstParent);
        CreateSource(SecondParent);
        CreateConfiguration(FirstParent.Name, 'BASELINE', Configuration);
        CreateConfiguration(SecondParent.Name, 'BASELINE', Configuration);

        FirstParent.Delete(true);

        LibraryAssert.IsFalse(Configuration.Get(FirstParent.Name, 'BASELINE'), 'Deleting a parent must remove its configurations.');
        LibraryAssert.IsTrue(Configuration.Get(SecondParent.Name, 'BASELINE'), 'Other parents must keep their configurations.');
    end;

    [Test]
    procedure DeletedConfigurationPreventsOrdinaryExecution()
    var
        ParentSuite: Record "AL Test Suite";
        Configuration: Record "Test Configuration";
        SuiteNames: List of [Code[10]];
    begin
        CreateSource(ParentSuite);
        CreateConfiguration(ParentSuite.Name, 'REMOVED', Configuration);
        SuiteNames := TestConfigurationMgt.GenerateStabilitySuites(ParentSuite.Name);
        Configuration.Delete(true);

        asserterror TestConfigurationMgt.RunSuite(SuiteNames.Get(1));
        LibraryAssert.ExpectedError('Test Configuration does not exist');
    end;

    [Test]
    procedure GeneratedSuiteCannotGenerateMoreSuites()
    var
        ParentSuite: Record "AL Test Suite";
        Configuration: Record "Test Configuration";
        SuiteNames: List of [Code[10]];
    begin
        CreateSource(ParentSuite);
        CreateConfiguration(ParentSuite.Name, 'BASELINE', Configuration);
        SuiteNames := TestConfigurationMgt.GenerateStabilitySuites(ParentSuite.Name);

        asserterror TestConfigurationMgt.GenerateStabilitySuites(SuiteNames.Get(1));
        LibraryAssert.ExpectedError('cannot generate more stability suites');
    end;

    [Test]
    procedure JsonKeepsDuplicateBlocksAndCompleteDiagnosticsSeparate()
    var
        ParentSuite: Record "AL Test Suite";
        Configuration: Record "Test Configuration";
        Header: Record "Test Method Line";
        Method: Record "Test Method Line";
        SuiteNames: List of [Code[10]];
        Results: JsonObject;
        ResultToken: JsonToken;
        MethodToken: JsonToken;
        MessageToken: JsonToken;
        StackToken: JsonToken;
        ErrorStream: OutStream;
        ErrorText: Text;
        StackText: Text;
        NewLine: Char;
    begin
        CreateSource(ParentSuite);
        CreateConfiguration(ParentSuite.Name, 'ONEBYONE', Configuration);
        Configuration."One By One" := true;
        Configuration.Modify();
        SuiteNames := TestConfigurationMgt.GenerateStabilitySuites(ParentSuite.Name);
        Header.SetRange("Test Suite", SuiteNames.Get(1));
        Header.SetRange("Line Type", Header."Line Type"::Codeunit);
        Header.FindFirst();
        Method.SetRange("Test Suite", Header."Test Suite");
        Method.SetRange("Line Type", Method."Line Type"::Function);
        Method.FindFirst();
        NewLine := 10;
        ErrorText := 'First line' + Format(NewLine) + PadStr('Details', 3000, 'x') + Format(NewLine) + 'Last line';
        StackText := 'Codeunit "Fixture".First\Second' + Format(NewLine) + PadStr('Stack', 3000, 'y') + Format(NewLine) + 'Last frame';
        Method.Result := Method.Result::Failure;
        Method."Error Message".CreateOutStream(ErrorStream, TextEncoding::UTF16);
        ErrorStream.WriteText(ErrorText);
        Method."Error Call Stack".CreateOutStream(ErrorStream, TextEncoding::UTF16);
        ErrorStream.WriteText(StackText);
        Method.Modify();

        Results.ReadFrom(TestSuiteMgt.TestResultsToJSON(Header));

        Results.Get('testResults', ResultToken);
        LibraryAssert.AreEqual(1, ResultToken.AsArray().Count(), 'JSON must contain only the current block, not every occurrence of the codeunit.');
        ResultToken.AsArray().Get(0, MethodToken);
        MethodToken.AsObject().Get('message', MessageToken);
        LibraryAssert.AreEqual(ErrorText, MessageToken.AsValue().AsText(), 'Multiline diagnostics must not be truncated.');
        MethodToken.AsObject().Get('stackTrace', StackToken);
        LibraryAssert.AreEqual(StackText, StackToken.AsValue().AsText(), 'JSON must retain the complete stack, including quoted identifiers and backslashes.');
        LibraryAssert.AreEqual(StackText, TestSuiteMgt.GetErrorCallStack(Method), 'The complete stack must be read.');
        Method.Run := false;
        Method.Modify();
        TestSuiteMgt.ClearTestResults(Method);
        Method.Find();
        LibraryAssert.IsFalse(Method.Run, 'Clearing results must preserve Run flags.');
        LibraryAssert.AreEqual('', TestSuiteMgt.GetFullErrorMessage(Method), 'Clearing results must remove the full error.');
    end;

    [Test]
    procedure RuntimeProvidersRespectExplicitSeedsAndDoNotCompoundDates()
    var
        Configuration: Record "Test Configuration";
        Any: Codeunit Any;
        ConfiguredRandomSeed: Codeunit "Configured Random Seed";
        SeedProvider: Codeunit "Seed Test Config. Provider";
        WorkDateProvider: Codeunit "WorkDate Test Config. Prov.";
        ConfiguredSeedValue: Integer;
        DefaultSeedValue: Integer;
        ExplicitSeedValue: Integer;
        OriginalWorkDate: Date;
    begin
        Any.SetSeed(1);
        DefaultSeedValue := Any.IntegerInRange(1, 1000000);
        Any.SetSeed(17);
        ConfiguredSeedValue := Any.IntegerInRange(1, 1000000);
        Any.SetSeed(42);
        ExplicitSeedValue := Any.IntegerInRange(1, 1000000);
        Configuration."Use Random Seed" := true;
        Configuration."Random Seed" := 17;
        Clear(Any);
        SeedProvider.Initialize(Configuration);
        LibraryAssert.AreEqual(ConfiguredSeedValue, Any.IntegerInRange(1, 1000000), 'A fresh Any instance must use the configured seed.');
        LibraryAssert.AreEqual(17, Any.GetSeed(), 'Lazy initialization must retain the configured seed.');
        Clear(Any);
        SeedProvider.ApplyBeforeTestMethodRun();
        LibraryAssert.AreEqual(ConfiguredSeedValue, Any.IntegerInRange(1, 1000000), 'Each method must start with the configured seed.');
        Configuration."Random Seed" := 0;
        SeedProvider.Initialize(Configuration);
        LibraryAssert.IsTrue(ConfiguredRandomSeed.IsSet(), 'Zero must be treated as an explicitly configured seed.');
        LibraryAssert.AreEqual(0, ConfiguredRandomSeed.GetSeed(), 'Zero must survive the seed transport.');
        SeedProvider.ApplyBeforeTestMethodRun();
        Any.SetSeed(42);
        LibraryAssert.AreEqual(ExplicitSeedValue, Any.IntegerInRange(1, 1000000), 'The configured seed must not override an explicit test seed.');
        Configuration."Use Random Seed" := false;
        Clear(Any);
        SeedProvider.Initialize(Configuration);
        LibraryAssert.IsFalse(ConfiguredRandomSeed.IsSet(), 'An unset seed must not retain an earlier configuration.');
        LibraryAssert.AreEqual(DefaultSeedValue, Any.IntegerInRange(1, 1000000), 'An unset seed must initialize the normal default.');
        SeedProvider.Reset();

        OriginalWorkDate := WorkDate();
        Evaluate(Configuration."WorkDate Offset", '<2Y>');
        WorkDateProvider.Initialize(Configuration);
        WorkDateProvider.ApplyBeforeTestMethodRun();
        WorkDateProvider.ApplyBeforeTestMethodRun();
        LibraryAssert.AreEqual(CalcDate('<2Y>', OriginalWorkDate), WorkDate(), 'Repeated callbacks must not compound the offset.');
        WorkDateProvider.Reset();
        LibraryAssert.AreEqual(OriginalWorkDate, WorkDate(), 'Normal reset must restore WorkDate.');
    end;

    local procedure CreateSource(var ALTestSuite: Record "AL Test Suite")
    var
        TestMethodLine: Record "Test Method Line";
    begin
        Clear(ALTestSuite);
        ALTestSuite.Name := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(ALTestSuite.Name));
        ALTestSuite."Stability Run" := true;
        ALTestSuite.Insert(true);
        AddLine(ALTestSuite.Name, 10000, 10, '');
        AddLine(ALTestSuite.Name, 10001, 10, 'A1');
        AddLine(ALTestSuite.Name, 10002, 10, 'A2');
        AddLine(ALTestSuite.Name, 20000, 20, '');
        AddLine(ALTestSuite.Name, 20001, 20, 'B1');
        AddLine(ALTestSuite.Name, 20002, 20, 'B2');
        TestMethodLine.Get(ALTestSuite.Name, 10001);
        TestMethodLine."Data Input Group Code" := 'GROUP';
        TestMethodLine."Data Input" := 'INPUT1';
        TestMethodLine.Result := TestMethodLine.Result::Failure;
        TestMethodLine."Start Time" := CreateDateTime(20260101D, 010000T);
        TestMethodLine.Modify();
    end;

    local procedure AddLine(SuiteName: Code[10]; LineNo: Integer; CodeunitID: Integer; MethodName: Text[128])
    var
        TestMethodLine: Record "Test Method Line";
    begin
        TestMethodLine.Init();
        TestMethodLine."Test Suite" := SuiteName;
        TestMethodLine."Line No." := LineNo;
        TestMethodLine."Test Codeunit" := CodeunitID;
        TestMethodLine.Name := MethodName;
        TestMethodLine."Function" := MethodName;
        if MethodName <> '' then begin
            TestMethodLine."Line Type" := TestMethodLine."Line Type"::Function;
            TestMethodLine.Level := 1;
        end;
        TestMethodLine.Insert();
    end;

    local procedure CreateConfiguration(SuiteName: Code[10]; ConfigurationCode: Code[20]; var Configuration: Record "Test Configuration")
    begin
        Clear(Configuration);
        Configuration.Init();
        Configuration."Test Suite" := SuiteName;
        Configuration.Code := ConfigurationCode;
        Configuration.Insert(true);
    end;
}
