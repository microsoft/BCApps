// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

using System.Reflection;

codeunit 130456 "Test Suite Mgt."
{
    Permissions = tabledata "AL Test Suite" = rimd,
                  tabledata "Test Method Line" = rimd;

    trigger OnRun()
    begin
    end;

    var
        NoTestRunnerSelectedTxt: Label 'No test runner is selected.';
        CannotChangeValueErr: Label 'You cannot change the value of the OnRun.', Locked = true;
        SelectTestsToRunQst: Label '&All,Active &Codeunit,Active &Line', Locked = true;
        SelectCodeunitsToRunQst: Label '&All,Active &Codeunit', Locked = true;
        DefaultTestSuiteNameTxt: Label 'DEFAULT', Locked = true;
        DialogUpdatingTestsMsg: Label 'Updating Tests: \#1#\#2#', Comment = '1 = Object being processed, 2 = Progress', Locked = true;
        ErrorMessageWithCallStackErr: Label 'Error Message: %1 - Error Call Stack: ', Locked = true;

    procedure IsTestMethodLine(FunctionName: Text[128]): Boolean
    begin
        exit((FunctionName <> '') and (FunctionName <> 'OnRun'))
    end;

    procedure SetCCTrackingType(var ALTestSuite: Record "AL Test Suite"; NewCCTrackingType: Integer)
    begin
        ALTestSuite.Validate("CC Tracking Type", NewCCTrackingType);
        ALTestSuite.Modify(true);
    end;

    procedure SetCCMap(var ALTestSuite: Record "AL Test Suite"; NewCCMap: Integer)
    begin
        ALTestSuite.Validate("CC Coverage Map", NewCCMap);
        ALTestSuite.Modify(true);
    end;

    procedure SetCCTrackAllSessions(var ALTestSuite: Record "AL Test Suite"; NewCCTrackAllSessions: Boolean)
    begin
        ALTestSuite.Validate("CC Track All Sessions", NewCCTrackAllSessions);
        ALTestSuite.Modify(true);
    end;

    procedure SetCodeCoverageExporterID(var ALTestSuite: Record "AL Test Suite"; NewCodeCoverageExporterID: Integer)
    begin
        ALTestSuite.Validate("CC Exporter ID", NewCodeCoverageExporterID);
        ALTestSuite.Modify(true);
    end;

    procedure RunTestSuiteSelection(var TestMethodLine: Record "Test Method Line")
    var
        ALTestSuite: Record "AL Test Suite";
        CurrentTestMethodLine: Record "Test Method Line";
        Selection: Integer;
        LineNoFilter: Text;
    begin
        CurrentTestMethodLine.Copy(TestMethodLine);
        ALTestSuite.Get(TestMethodLine."Test Suite");

        if GuiAllowed() then
            Selection := this.PromptUserToSelectTestsToRun(CurrentTestMethodLine)
        else
            Selection := ALTestSuite."Run Type"::All;

        if Selection <= 0 then
            exit;

        LineNoFilter := this.GetLineNoFilter(CurrentTestMethodLine, Selection);

        if LineNoFilter <> '' then
            CurrentTestMethodLine.SetFilter("Line No.", LineNoFilter);

        this.RunTests(CurrentTestMethodLine, ALTestSuite);
    end;

    procedure RunAllTests(var TestMethodLine: Record "Test Method Line")
    var
        ALTestSuite: Record "AL Test Suite";
    begin
        ALTestSuite.Get(TestMethodLine."Test Suite");

        TestMethodLine.Reset();
        TestMethodLine.SetRange("Test Suite", ALTestSuite.Name);

        this.RunTests(TestMethodLine, ALTestSuite);
    end;

    procedure RunNextTest(var TestMethodLine: Record "Test Method Line"): Boolean
    var
        ALTestSuite: Record "AL Test Suite";
    begin
        ALTestSuite.Get(TestMethodLine."Test Suite");

        TestMethodLine.Reset();
        TestMethodLine.SetRange("Test Suite", ALTestSuite.Name);
        TestMethodLine.SetRange(Result, TestMethodLine.Result::" ");
        TestMethodLine.SetRange(Run, true);
        TestMethodLine.SetRange("Line Type", TestMethodLine."Line Type"::Codeunit);

        if not TestMethodLine.FindFirst() then
            exit(false);

        TestMethodLine.SetRange("Test Codeunit", TestMethodLine."Test Codeunit");

        if ALTestSuite."Stability Run" then
            this.RunNextTestStabilityRun(TestMethodLine)
        else
            this.RunSelectedTests(TestMethodLine);

        TestMethodLine.SetRange(Result);
        exit(true);
    end;

    procedure RunNextTestStabilityRun(var TestMethodLine: Record "Test Method Line")
    var
        NextTestMethodLine: Record "Test Method Line";
        CurrentTestMethodLine: Record "Test Method Line";
    begin
        this.SetFiltersToTestMethods(TestMethodLine, NextTestMethodLine);
        if NextTestMethodLine.FindSet() then
            repeat
                if NextTestMethodLine.Run then begin
                    CurrentTestMethodLine.Copy(NextTestMethodLine);
                    CurrentTestMethodLine.SetRange("Line No.", NextTestMethodLine."Line No.");
                    this.RunSelectedTests(CurrentTestMethodLine);
                end;
            until NextTestMethodLine.Next() = 0;

        TestMethodLine.Get(TestMethodLine.RecordId);
    end;

    local procedure SetFiltersToTestMethods(var CodeunitTestMethodLine: Record "Test Method Line"; var FunctionTestMethodLine: Record "Test Method Line")
    begin
        FunctionTestMethodLine.SetRange("Test Suite", CodeunitTestMethodLine."Test Suite");
        FunctionTestMethodLine.SetRange("Line Type", CodeunitTestMethodLine."Line Type"::Function);
        FunctionTestMethodLine.SetRange("Test Codeunit", CodeunitTestMethodLine."Test Codeunit");
    end;

    procedure TestResultsToJSON(var TestMethodLine: Record "Test Method Line"): Text
    var
        CodeunitTestMethodLine: Record "Test Method Line";
        FunctionTestMethodLine: Record "Test Method Line";
        TestResultArray: JsonArray;
        TestResultJson: JsonObject;
        CodeunitResultJson: JsonObject;
        ResultsJsonText: Text;
        ConvertedText: Text;
        ResultInteger: Integer;
    begin
        CodeunitTestMethodLine.Copy(TestMethodLine);
        CodeunitTestMethodLine.SetRange("Test Suite", TestMethodLine."Test Suite");
        CodeunitTestMethodLine.SetRange("Line Type", TestMethodLine."Line Type"::Codeunit);
        CodeunitTestMethodLine.SetRange(Run, true);
        CodeunitTestMethodLine.SetRange("Test Codeunit", TestMethodLine."Test Codeunit");
        if not CodeunitTestMethodLine.FindFirst() then
            exit;

        CodeunitResultJson.Add('name', CodeunitTestMethodLine.Name);
        CodeunitResultJson.Add('codeUnit', CodeunitTestMethodLine."Test Codeunit");
        CodeunitResultJson.Add('startTime', CodeunitTestMethodLine."Start Time");
        CodeunitResultJson.Add('finishTime', CodeunitTestMethodLine."Finish Time");

        // Console test runner depends on an integer, not to be affected by translation
        ResultInteger := CodeunitTestMethodLine.Result;
        CodeunitResultJson.Add('result', ResultInteger);

        FunctionTestMethodLine.Copy(CodeunitTestMethodLine);
        FunctionTestMethodLine.SetRange("Line Type", TestMethodLine."Line Type"::Function);

        if FunctionTestMethodLine.FindFirst() then begin
            repeat
                Clear(TestResultJson);
                TestResultJson.Add('method', FunctionTestMethodLine.Name);
                TestResultJson.Add('startTime', FunctionTestMethodLine."Start Time");
                TestResultJson.Add('finishTime', FunctionTestMethodLine."Finish Time");
                ResultInteger := FunctionTestMethodLine.Result;
                TestResultJson.Add('result', ResultInteger);
                if (FunctionTestMethodLine.Result = FunctionTestMethodLine.Result::Failure) then begin
                    TestResultJson.Add('message', this.GetFullErrorMessage(FunctionTestMethodLine));
                    ConvertedText := this.GetErrorCallStack(FunctionTestMethodLine);
                    ConvertedText := ConvertedText.Replace('\', ';');
                    ConvertedText := ConvertedText.Replace('"', '');
                    TestResultJson.Add('stackTrace', ConvertedText);
                end;

                TestResultArray.Add(TestResultJson);
            until FunctionTestMethodLine.Next() = 0;

            CodeunitResultJson.Add('testResults', TestResultArray);
        end;

        CodeunitResultJson.WriteTo(ResultsJsonText);

        exit(ResultsJsonText);
    end;

    procedure RunSelectedTests(var TestMethodLine: Record "Test Method Line")
    var
        ALTestSuite: Record "AL Test Suite";
        CurrentCodeunitNumber: Integer;
        LineNoFilter: Text;
    begin
        TestMethodLine.SetCurrentKey("Line No.");
        TestMethodLine.Ascending(true);
        if not TestMethodLine.FindFirst() then
            exit;

        ALTestSuite.Get(TestMethodLine."Test Suite");
        LineNoFilter := '';

        CurrentCodeunitNumber := 0;
        repeat
            if TestMethodLine."Test Codeunit" <> CurrentCodeunitNumber then begin
                CurrentCodeunitNumber := TestMethodLine."Test Codeunit";
                if LineNoFilter <> '' then
                    LineNoFilter += '|';

                if TestMethodLine."Line Type" = TestMethodLine."Line Type"::Codeunit then
                    LineNoFilter += this.GetLineNoFilter(TestMethodLine, ALTestSuite."Run Type"::"Active Codeunit");

                if TestMethodLine."Line Type" = TestMethodLine."Line Type"::"Function" then
                    LineNoFilter += this.GetLineNoFilter(TestMethodLine, ALTestSuite."Run Type"::"Active Test");
            end else
                if TestMethodLine."Line Type" = TestMethodLine."Line Type"::"Function" then
                    LineNoFilter += '|' + Format(TestMethodLine."Line No.");
        until TestMethodLine.Next() = 0;

        TestMethodLine.Reset();
        TestMethodLine.SetRange("Test Suite", ALTestSuite.Name);
        TestMethodLine.SetFilter("Line No.", LineNoFilter);
        TestMethodLine.FindFirst();
        this.RunTests(TestMethodLine, ALTestSuite);
    end;

    procedure SelectTestMethods(var ALTestSuite: Record "AL Test Suite")
    var
        AllObjWithCaption: Record AllObjWithCaption;
        SelectTests: Page "Select Tests";
    begin
        SelectTests.LookupMode := true;
        if SelectTests.RunModal() = ACTION::LookupOK then begin
            SelectTests.SetSelectionFilter(AllObjWithCaption);
            this.GetTestMethods(ALTestSuite, AllObjWithCaption);
        end;
    end;

    procedure LookupTestMethodsByRange(var ALTestSuite: Record "AL Test Suite")
    var
        SelectTestsByRange: Page "Select Tests By Range";
    begin
        ALTestSuite.Find();
        SelectTestsByRange.LookupMode := true;
        if SelectTestsByRange.RunModal() = ACTION::LookupOK then
            this.SelectTestMethodsByRange(ALTestSuite, SelectTestsByRange.GetRange());
    end;

    procedure SelectTestMethodsByRange(var ALTestSuite: Record "AL Test Suite"; TestCodeunitFilter: Text)
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        AllObjWithCaption.SetFilter("Object ID", TestCodeunitFilter);
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Codeunit);
        AllObjWithCaption.SetRange("Object Subtype", this.GetTestObjectSubtype());
        this.GetTestMethods(ALTestSuite, AllObjWithCaption);
    end;

    procedure SelectTestProceduresByName(ALTestSuite: Code[10]; TestProcedureRangeFilter: Text)
    var
        TestMethodLine: Record "Test Method Line";
    begin
        TestMethodLine.SetRange("Test Suite", ALTestSuite);
        TestMethodLine.SetRange("Line Type", TestMethodLine."Line Type"::Function);
        TestMethodLine.ModifyAll(Run, false);

        TestMethodLine.SetFilter(Name, TestProcedureRangeFilter);
        TestMethodLine.ModifyAll(Run, true);
    end;

    procedure SelectTestMethodsByExtension(var ALTestSuite: Record "AL Test Suite"; ExtensionID: Text)
    var
        AllObjWithCaption: Record AllObjWithCaption;
        AppModuleInfo: ModuleInfo;
        AppExtensionId: Guid;
    begin
        Evaluate(AppExtensionId, ExtensionID);
        NavApp.GetModuleInfo(ExtensionID, AppModuleInfo);
        AllObjWithCaption.SetRange("App Package ID", AppModuleInfo.PackageID);
        AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Codeunit);
        AllObjWithCaption.SetRange("Object Subtype", this.GetTestObjectSubtype());
        this.GetTestMethods(ALTestSuite, AllObjWithCaption);
    end;

    procedure LookupTestRunner(var ALTestSuite: Record "AL Test Suite")
    var
        AllObjWithCaption: Record AllObjWithCaption;
        SelectTestRunner: Page "Select TestRunner";
    begin
        SelectTestRunner.LookupMode := true;
        if SelectTestRunner.RunModal() = ACTION::LookupOK then begin
            SelectTestRunner.GetRecord(AllObjWithCaption);
            this.ChangeTestRunner(ALTestSuite, AllObjWithCaption."Object ID");
        end;
    end;

    procedure ChangeTestRunner(var ALTestSuite: Record "AL Test Suite"; NewTestRunnerId: Integer)
    begin
        ALTestSuite.Validate("Test Runner Id", NewTestRunnerId);
        ALTestSuite.Modify(true);
    end;

    procedure ChangeStabilityRun(var ALTestSuite: Record "AL Test Suite"; NewStabiltyRun: Boolean)
    begin
        ALTestSuite.Validate("Stability Run", NewStabiltyRun);
        ALTestSuite.Modify(true);
    end;

    procedure CreateTestSuite(var TestSuiteName: Code[10])
    var
        ALTestSuite: Record "AL Test Suite";
    begin
        if TestSuiteName = '' then
            TestSuiteName := this.DefaultTestSuiteNameTxt;

        ALTestSuite.Name := CopyStr(TestSuiteName, 1, MaxStrLen(ALTestSuite.Name));
        ALTestSuite.Insert(true);
    end;

    procedure GetTestMethods(var ALTestSuite: Record "AL Test Suite"; var AllObjWithCaption: Record AllObjWithCaption)
    var
        TestLineNo: Integer;
    begin
        if not AllObjWithCaption.FindSet() then
            exit;

        repeat
            // Must be inside of loop. Test Runner used for discovering tests is adding methods
            TestLineNo := this.GetLastTestLineNo(ALTestSuite) + 10000;
            this.AddTestMethod(AllObjWithCaption, ALTestSuite, TestLineNo);
        until AllObjWithCaption.Next() = 0;
    end;

    procedure UpdateCodeCoverageTrackingType(var NewALTestSuite: Record "AL Test Suite")
    var
        ALTestSuite: Record "AL Test Suite";
    begin
        ALTestSuite.Get(NewALTestSuite.RecordId);
        ALTestSuite.Validate("CC Tracking Type", NewALTestSuite."CC Tracking Type");
        ALTestSuite.Modify();
        NewALTestSuite.Copy(ALTestSuite);
    end;

    procedure UpdateCodeCoverageTrackAllSesssions(var NewALTestSuite: Record "AL Test Suite")
    var
        ALTestSuite: Record "AL Test Suite";
    begin
        ALTestSuite.Get(NewALTestSuite.RecordId);
        ALTestSuite.Validate("CC Track All Sessions", NewALTestSuite."CC Track All Sessions");
        ALTestSuite.Modify();
        NewALTestSuite.Copy(ALTestSuite);
    end;

    procedure UpdateTestMethods(var TestMethodLine: Record "Test Method Line")
    var
        BackupTestMethodLine: Record "Test Method Line";
        CodeunitTestMethodLine: Record "Test Method Line";
        TempTestMethodLine: Record "Test Method Line" temporary;
        TestRunnerGetMethods: Codeunit "Test Runner - Get Methods";
        ExpandDataDrivenTests: Codeunit "Expand Data Driven Tests";
        Counter: Integer;
        TotalCount: Integer;
        Dialog: Dialog;
    begin
        BackupTestMethodLine.Copy(TestMethodLine);
        TestMethodLine.Reset();
        CodeunitTestMethodLine.Copy(TestMethodLine);
        if CodeunitTestMethodLine."Line Type" <> CodeunitTestMethodLine."Line Type"::Codeunit then
            this.FindCodeunitLineFromFunction(TestMethodLine, CodeunitTestMethodLine);

        TestMethodLine.SetRange("Test Suite", BackupTestMethodLine."Test Suite");
        TestMethodLine.SetRange("Line Type", TestMethodLine."Line Type"::Function);
        TestMethodLine.SetFilter("Line No.", this.GetLineNoFilterForTestCodeunit(CodeunitTestMethodLine));
        TestMethodLine.DeleteAll();
        TestMethodLine.SetRange("Line Type", TestMethodLine."Line Type"::Codeunit);

        if GuiAllowed() then begin
            Counter := 0;
            TotalCount := TestMethodLine.Count();
            Dialog.Open(this.DialogUpdatingTestsMsg);
        end;

        if TestMethodLine.FindSet() then
            repeat
                if GuiAllowed() then begin
                    Counter += 1;
                    Dialog.Update(1, format(TestMethodLine."Line Type") + ' ' + format(TestMethodLine."Test Codeunit") + ' - ' + TestMethodLine.Name);
                    Dialog.Update(2, format(Counter) + '/' + format(TotalCount) + ' (' + format(round(Counter / TotalCount * 100, 1)) + '%)');
                end;

                TempTestMethodLine.TransferFields(TestMethodLine);
                TempTestMethodLine.Insert();
                ExpandDataDrivenTests.SetDataDrivenTests(TempTestMethodLine);
                BindSubscription(ExpandDataDrivenTests);
                TestRunnerGetMethods.SetUpdateTests(true);
                TestRunnerGetMethods.Run(TestMethodLine);
                UnbindSubscription(ExpandDataDrivenTests);
                TempTestMethodLine.DeleteAll();
            until TestMethodLine.Next() = 0;

        if GuiAllowed() then
            Dialog.Close();

        TestMethodLine.SetRange("Test Suite", BackupTestMethodLine."Test Suite");
        TestMethodLine.SetRange("Test Codeunit", BackupTestMethodLine."Test Codeunit");
        TestMethodLine.SetRange(Name, BackupTestMethodLine.Name);
        if TestMethodLine.FindFirst() then begin
            TestMethodLine.CopyFilters(BackupTestMethodLine);
            exit;
        end;

        TestMethodLine.SetRange(Name);
        if TestMethodLine.FindFirst() then;

        TestMethodLine.CopyFilters(BackupTestMethodLine);
    end;

    local procedure PromptUserToSelectTestsToRun(TestMethodLine: Record "Test Method Line"): Integer
    var
        Selection: Integer;
    begin
        if TestMethodLine."Line Type" = TestMethodLine."Line Type"::Codeunit then
            Selection := StrMenu(this.SelectCodeunitsToRunQst, 1)
        else
            Selection := StrMenu(this.SelectTestsToRunQst, 3);

        exit(Selection);
    end;

    local procedure GetLineNoFilter(TestMethodLine: Record "Test Method Line"; Selection: Option): Text
    var
        DummyALTestSuite: Record "AL Test Suite";
    begin
        case Selection of
            DummyALTestSuite."Run Type"::"Active Test":
                exit(this.GetLineNoFilterActiveTest(TestMethodLine));
            DummyALTestSuite."Run Type"::"Active Codeunit":
                exit(this.GetLineNoFilterForTestCodeunit(TestMethodLine));
        end;
    end;

    local procedure GetLineNoFilterActiveTest(TestMethodLine: Record "Test Method Line"): Text
    var
        CodeunitTestMethodLine: Record "Test Method Line";
        LineNoFilter: Text;
    begin
        TestMethodLine.TestField("Line Type", TestMethodLine."Line Type"::"Function");
        CodeunitTestMethodLine.SetRange("Test Suite", TestMethodLine."Test Suite");
        CodeunitTestMethodLine.SetRange("Test Codeunit", TestMethodLine."Test Codeunit");
        CodeunitTestMethodLine.SetFilter("Line No.", this.GetLineNoFilterForTestCodeunit(TestMethodLine));
        CodeunitTestMethodLine.FindFirst();
#pragma warning disable AA0217
        LineNoFilter := StrSubstNo('%1|%2', CodeunitTestMethodLine."Line No.", TestMethodLine."Line No.");
#pragma warning restore
        exit(LineNoFilter);
    end;

    internal procedure GetLineNoFilterForTestCodeunit(TestMethodLine: Record "Test Method Line"): Text
    var
        CodeunitTestMethodLine: Record "Test Method Line";
        NextCodeunitTestMethodLine: Record "Test Method Line";
        LineNoFilter: Text;
    begin
        CodeunitTestMethodLine.SetFilter("Line No.", '<=%1', TestMethodLine."Line No.");
        CodeunitTestMethodLine.SetRange("Test Suite", TestMethodLine."Test Suite");
        CodeunitTestMethodLine.SetRange("Test Codeunit", TestMethodLine."Test Codeunit");
        CodeunitTestMethodLine.SetRange("Line Type", TestMethodLine."Line Type"::Codeunit);
        CodeunitTestMethodLine.SetAscending("Line No.", true);
        CodeunitTestMethodLine.FindLast();

        NextCodeunitTestMethodLine.SetFilter("Line No.", '>%1', TestMethodLine."Line No.");
        NextCodeunitTestMethodLine.SetRange("Test Suite", TestMethodLine."Test Suite");
        NextCodeunitTestMethodLine.SetRange("Line Type", TestMethodLine."Line Type"::Codeunit);
        NextCodeunitTestMethodLine.SetAscending("Line No.", true);
        if NextCodeunitTestMethodLine.FindFirst() then
#pragma warning disable AA0217
            LineNoFilter := StrSubstNo('%1..%2', CodeunitTestMethodLine."Line No.", NextCodeunitTestMethodLine."Line No." - 1)
        else
            LineNoFilter := StrSubstNo('%1..', CodeunitTestMethodLine."Line No.");
#pragma warning restore

        exit(LineNoFilter);
    end;

    procedure GetLastTestLineNo(ALTestSuite: Record "AL Test Suite"): Integer
    var
        TestMethodLine: Record "Test Method Line";
        LineNo: Integer;
    begin
        LineNo := 0;

        TestMethodLine.SetRange("Test Suite", ALTestSuite.Name);
        if TestMethodLine.FindLast() then
            LineNo := TestMethodLine."Line No.";

        exit(LineNo);
    end;

    procedure GetNextMethodNumber(TestMethodLine: Record "Test Method Line"): Integer
    var
        LineNo: Integer;
    begin
        LineNo := 0;

        TestMethodLine.SetRange("Test Suite", TestMethodLine."Test Suite");
        TestMethodLine.SetRange("Test Codeunit", TestMethodLine."Test Codeunit");
        TestMethodLine.SetFilter("Line No.", this.GetLineNoFilterForTestCodeunit(TestMethodLine));

        if TestMethodLine.FindLast() then
            LineNo := TestMethodLine."Line No.";

        exit(LineNo);
    end;

    local procedure AddTestMethod(AllObjWithCaption: Record AllObjWithCaption; ALTestSuite: Record "AL Test Suite"; NextLineNo: Integer)
    var
        TestMethodLine: Record "Test Method Line";
    begin
        TestMethodLine."Test Suite" := ALTestSuite.Name;
        TestMethodLine."Line No." := NextLineNo;
        TestMethodLine."Test Codeunit" := AllObjWithCaption."Object ID";
        TestMethodLine.Validate("Line Type", TestMethodLine."Line Type"::Codeunit);
        TestMethodLine.Name := AllObjWithCaption."Object Name";
        TestMethodLine.Insert(true);

        CODEUNIT.Run(CODEUNIT::"Test Runner - Get Methods", TestMethodLine);
    end;

    local procedure GetTestObjectSubtype(): Text
    begin
        exit('Test');
    end;

    procedure DeleteAllMethods(var ALTestSuite: Record "AL Test Suite")
    var
        TestMethodLine: Record "Test Method Line";
    begin
        TestMethodLine.SetRange("Test Suite", ALTestSuite.Name);
        TestMethodLine.DeleteAll(true);
    end;

    procedure RunTests(var TestMethodLine: Record "Test Method Line"; ALTestSuite: Record "AL Test Suite")
    begin
        CODEUNIT.Run(ALTestSuite."Test Runner Id", TestMethodLine);
    end;

    procedure GetTestRunnerDisplayName(ALTestSuite: Record "AL Test Suite"): Text
    begin
        exit(this.GetTestRunnerDisplayName(ALTestSuite."Test Runner Id"));
    end;

    procedure GetTestRunnerDisplayName(TestRunnerID: Integer): Text
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        if not AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Codeunit, TestRunnerId) then
            exit(this.NoTestRunnerSelectedTxt);

#pragma warning disable AA0217
        exit(StrSubstNo('%1 - %2', TestRunnerId, AllObjWithCaption."Object Name"));
#pragma warning restore        
    end;

    procedure UpdateRunValueOnChildren(var TestMethodLine: Record "Test Method Line")
    var
        BackupTestMethodLine: Record "Test Method Line";
    begin
        if TestMethodLine."Line Type" = TestMethodLine."Line Type"::"Function" then
            exit;

        BackupTestMethodLine.Copy(TestMethodLine);

        TestMethodLine.Reset();
        TestMethodLine.SetRange("Test Suite", BackupTestMethodLine."Test Suite");

        TestMethodLine.SetRange("Line Type", TestMethodLine."Line Type"::"Function");
        TestMethodLine.SetRange("Test Codeunit", BackupTestMethodLine."Test Codeunit");
        TestMethodLine.SetFilter("Line No.", this.GetLineNoFilterForTestCodeunit(TestMethodLine));
        TestMethodLine.ModifyAll(Run, BackupTestMethodLine.Run, true);

        TestMethodLine.Copy(BackupTestMethodLine);
    end;

    procedure DeleteChildren(var TestMethodLine: Record "Test Method Line")
    var
        BackupTestMethodLine: Record "Test Method Line";
    begin
        BackupTestMethodLine.Copy(TestMethodLine);

        TestMethodLine.Reset();
        TestMethodLine.SetRange("Test Suite", TestMethodLine."Test Suite");
        TestMethodLine.SetRange("Test Codeunit", BackupTestMethodLine."Test Codeunit");
        TestMethodLine.SetFilter(Level, '>%1', BackupTestMethodLine.Level);
        TestMethodLine.SetFilter("Line No.", this.GetLineNoFilterForTestCodeunit(TestMethodLine));

        if TestMethodLine.IsEmpty() then begin
            TestMethodLine.Copy(BackupTestMethodLine);
            exit;
        end;

        TestMethodLine.DeleteAll();

        TestMethodLine.Copy(BackupTestMethodLine);
    end;

    procedure CalcTestResults(CurrentTestMethodLine: Record "Test Method Line"; var Success: Integer; var Fail: Integer; var Skipped: Integer; var NotExecuted: Integer)
    var
        TestMethodLine: Record "Test Method Line";
    begin
        TestMethodLine.SetRange("Test Suite", CurrentTestMethodLine."Test Suite");
        TestMethodLine.SetFilter("Function", '<>%1', 'OnRun');
        TestMethodLine.SetRange("Line Type", TestMethodLine."Line Type"::"Function");

        TestMethodLine.SetRange(Result, TestMethodLine.Result::Success);
        Success := TestMethodLine.Count();

        TestMethodLine.SetRange(Result, TestMethodLine.Result::Failure);
        Fail := TestMethodLine.Count();

        TestMethodLine.SetRange(Result, TestMethodLine.Result::Skipped);
        Skipped := TestMethodLine.Count();

        TestMethodLine.SetRange(Result, TestMethodLine.Result::" ");
        NotExecuted := TestMethodLine.Count();
    end;

    local procedure GetLineLevel(var TestMethodLine: Record "Test Method Line"): Integer
    begin
        case TestMethodLine."Line Type" of
            TestMethodLine."Line Type"::Codeunit:
                exit(0);
            else
                exit(1);
        end;
    end;

    procedure SetLastErrorOnLine(var TestMethodLine: Record "Test Method Line")
    begin
        TestMethodLine."Error Code" := CopyStr(GetLastErrorCode(), 1, MaxStrLen(TestMethodLine."Error Code"));
        TestMethodLine."Error Message Preview" := CopyStr(GetLastErrorText(), 1, MaxStrLen(TestMethodLine."Error Message Preview"));
        this.SetFullErrorMessage(TestMethodLine, GetLastErrorText());
        this.SetErrorCallStack(TestMethodLine, GetLastErrorCallstack());
    end;

    procedure ClearErrorOnLine(var TestMethodLine: Record "Test Method Line")
    begin
        Clear(TestMethodLine."Error Call Stack");
        Clear(TestMethodLine."Error Code");
        Clear(TestMethodLine."Error Message");
        Clear(TestMethodLine."Error Message Preview");
    end;

    procedure GetFullErrorMessage(var TestMethodLine: Record "Test Method Line"): Text
    var
        ErrorMessageInStream: InStream;
        ErrorMessage: Text;
    begin
        TestMethodLine.CalcFields("Error Message");
        if not TestMethodLine."Error Message".HasValue() then
            exit('');

        TestMethodLine."Error Message".CreateInStream(ErrorMessageInStream, this.GetDefaultTextEncoding());
        ErrorMessageInStream.ReadText(ErrorMessage);
        exit(ErrorMessage);
    end;

    local procedure FindCodeunitLineFromFunction(TestMethodLine: Record "Test Method Line"; var CodeunitTestMethodLine: Record "Test Method Line")
    begin
        CodeunitTestMethodLine.SetRange("Test Suite", TestMethodLine."Test Suite");
        CodeunitTestMethodLine.SetRange("Line Type", CodeunitTestMethodLine."Line Type"::Codeunit);
        CodeunitTestMethodLine.SetFilter("Line No.", '<%1', TestMethodLine."Line No.");
        CodeunitTestMethodLine.SetCurrentKey("Line No.");
        CodeunitTestMethodLine.Ascending(true);
        CodeunitTestMethodLine.FindLast();
    end;

    local procedure SetFullErrorMessage(var TestMethodLine: Record "Test Method Line"; ErrorMessage: Text)
    var
        ErrorMessageOutStream: OutStream;
    begin
        TestMethodLine."Error Message".CreateOutStream(ErrorMessageOutStream, this.GetDefaultTextEncoding());
        ErrorMessageOutStream.WriteText(ErrorMessage);
        TestMethodLine.Modify(true);
    end;

    procedure GetErrorCallStack(var TestMethodLine: Record "Test Method Line"): Text
    var
        ErrorCallStackInStream: InStream;
        ErrorCallStack: Text;
    begin
        TestMethodLine.CalcFields("Error Call Stack");
        if not TestMethodLine."Error Call Stack".HasValue() then
            exit('');

        TestMethodLine."Error Call Stack".CreateInStream(ErrorCallStackInStream, this.GetDefaultTextEncoding());
        ErrorCallStackInStream.ReadText(ErrorCallStack);
        exit(ErrorCallStack);
    end;

    local procedure SetErrorCallStack(var TestMethodLine: Record "Test Method Line"; ErrorCallStack: Text)
    var
        ErrorCallStackOutStream: OutStream;
    begin
        TestMethodLine."Error Call Stack".CreateOutStream(ErrorCallStackOutStream, this.GetDefaultTextEncoding());
        ErrorCallStackOutStream.WriteText(ErrorCallStack);
        TestMethodLine.Modify(true);
    end;

    local procedure GetDefaultTextEncoding(): TextEncoding
    begin
        exit(TEXTENCODING::UTF16);
    end;

    procedure GetErrorMessageWithStackTrace(var TestMethodLine: Record "Test Method Line"): Text
    var
        FullErrorMessage: Text;
        NewLine: Text;
    begin
        FullErrorMessage := this.GetFullErrorMessage(TestMethodLine);

        if FullErrorMessage = '' then
            exit('');

        NewLine[1] := 10;
        FullErrorMessage := StrSubstNo(this.ErrorMessageWithCallStackErr, FullErrorMessage);
        FullErrorMessage += NewLine + NewLine + this.GetErrorCallStack(TestMethodLine);
        exit(FullErrorMessage);
    end;

    procedure ValidateTestMethodLineType(var TestMethodLine: Record "Test Method Line")
    begin
        case TestMethodLine."Line Type" of
            TestMethodLine."Line Type"::Codeunit:
                begin
                    TestMethodLine.TestField("Function", '');
                    TestMethodLine.Name := '';
                end;
        end;

        TestMethodLine.Level := this.GetLineLevel(TestMethodLine);
    end;

    procedure ValidateTestMethodTestCodeunit(var TestMethodLine: Record "Test Method Line")
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        if TestMethodLine."Test Codeunit" = 0 then
            exit;

        if AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Codeunit, TestMethodLine."Test Codeunit") then
            TestMethodLine.Name := AllObjWithCaption."Object Name";

        TestMethodLine.Level := this.GetLineLevel(TestMethodLine);
    end;

    procedure ValidateTestMethodName(var TestMethodLine: Record "Test Method Line")
    var
        TestUnitNo: Integer;
    begin
        case TestMethodLine."Line Type" of
            TestMethodLine."Line Type"::"Function":
                TestMethodLine.TestField(Name, TestMethodLine."Function");
            TestMethodLine."Line Type"::Codeunit:
                begin
                    TestMethodLine.TestField(Name);
                    Evaluate(TestUnitNo, TestMethodLine.Name);
                    TestMethodLine.Validate("Test Codeunit", TestUnitNo);
                end;
        end;
    end;

    procedure ValidateTestMethodFunction(var TestMethodLine: Record "Test Method Line")
    begin
        if TestMethodLine."Line Type" <> TestMethodLine."Line Type"::"Function" then begin
            TestMethodLine.TestField("Function", '');
            exit;
        end;

        TestMethodLine.Level := this.GetLineLevel(TestMethodLine);
        TestMethodLine.Name := TestMethodLine."Function";
    end;

    procedure ValidateTestMethodRun(var CurrentTestMethodLine: Record "Test Method Line")
    var
        TestMethodLine: Record "Test Method Line";
    begin
        if CurrentTestMethodLine."Function" = 'OnRun' then
            Error(this.CannotChangeValueErr);

        TestMethodLine.Copy(CurrentTestMethodLine);

        this.UpdateRunValueOnChildren(TestMethodLine);
    end;
}
