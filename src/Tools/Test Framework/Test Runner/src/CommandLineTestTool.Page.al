// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

using System.TestTools.CodeCoverage;
using System.Tooling;

page 130455 "Command Line Test Tool"
{
    AccessByPermission = tabledata "Test Method Line" = RIMD;
    ApplicationArea = All;
    AutoSplitKey = true;
    Caption = 'Command Line Test Tool';
    DataCaptionExpression = this.CurrentSuiteName;
    DelayedInsert = true;
    DeleteAllowed = true;
    ModifyAllowed = true;
    PageType = Worksheet;
    SourceTable = "Test Method Line";
    UsageCategory = Administration;
    Permissions = tabledata "AL Test Suite" = rimd,
                  tabledata "Test Method Line" = rimd;

    layout
    {
        area(content)
        {
            field(CurrentSuiteName; this.CurrentSuiteName)
            {
                ApplicationArea = All;
                Caption = 'Suite Name';
                ToolTip = 'Specifies the current Suite Name';

                trigger OnValidate()
                begin
                    this.ChangeTestSuite();
                end;
            }
            field(TestCodeunitRangeFilter; this.TestCodeunitRangeFilter)
            {
                ApplicationArea = All;
                Caption = 'Test Codeunit Range';
                ToolTip = 'Specifies the values that will update the current suite selection';

                trigger OnValidate()
                var
                    TestSuiteMgt: Codeunit "Test Suite Mgt.";
                begin
                    TestSuiteMgt.DeleteAllMethods(this.GlobalALTestSuite);
                    TestSuiteMgt.SelectTestMethodsByRange(this.GlobalALTestSuite, this.TestCodeunitRangeFilter);
                    if Rec.FindFirst() then;
                end;
            }
            field(TestProcedureRangeFilter; this.TestProcedureRangeFilter)
            {
                ApplicationArea = All;
                Caption = 'Test Procedure Range';
                ToolTip = 'Specifies the test procedure range';

                trigger OnValidate()
                begin
                    if this.TestProcedureRangeFilter = '' then
                        exit;

                    this.TestSuiteMgt.SelectTestProceduresByName(this.GlobalALTestSuite.Name, this.TestProcedureRangeFilter);
                end;
            }
            field(TestRunnerCodeunitId; this.TestRunnerCodeunitId)
            {
                ApplicationArea = All;
                Caption = 'Test Runner Codeunit ID';
                ToolTip = 'Specifies the currently selected test runner ID';

                trigger OnValidate()
                var
                    TestSuiteMgt: Codeunit "Test Suite Mgt.";
                begin
                    TestSuiteMgt.ChangeTestRunner(this.GlobalALTestSuite, this.TestRunnerCodeunitId);
                end;
            }
            field(ExtensionId; this.ExtensionId)
            {
                ApplicationArea = All;
                Caption = 'Extension ID';
                ToolTip = 'Specifies the values if set will update the current suite selection';

                trigger OnValidate()
                var
                    TestSuiteMgt: Codeunit "Test Suite Mgt.";
                begin
                    TestSuiteMgt.DeleteAllMethods(this.GlobalALTestSuite);
                    TestSuiteMgt.SelectTestMethodsByExtension(this.GlobalALTestSuite, this.ExtensionId);
                    if Rec.FindFirst() then;
                end;
            }
            field(DisableTestMethod; this.RemoveTestMethod)
            {
                ApplicationArea = All;
                Caption = 'DisableTestMethod';
                ToolTip = 'Specifies the values that will update enabled property on the test method';

                trigger OnValidate()
                begin
                    this.FindAndDisableTestMethod();
                end;
            }

            field(TestResultJson; this.TestResultsJSONText)
            {
                ApplicationArea = All;
                Caption = 'Test Result JSON';
                Editable = false;
                ToolTip = 'Specifies the latest execution of the test as JSON';
            }

            field(CCTrackingType; this.CCTrackingType)
            {
                ApplicationArea = All;
                Caption = 'Code Coverage Tracking Type';
                ToolTip = 'Specifies the Code Coverage tracking type';

                trigger OnValidate()
                begin
                    this.TestSuiteMgt.SetCCTrackingType(this.GlobalALTestSuite, this.CCTrackingType);
                end;
            }

            field(CCMap; this.CCMap)
            {
                ApplicationArea = All;
                Caption = 'Code Coverage Map';
                ToolTip = 'Specifies the Code Coverage Map';
                trigger OnValidate()
                begin
                    this.TestSuiteMgt.SetCCMap(this.GlobalALTestSuite, this.CCMap);
                end;
            }

            field(CCTrackAllSessions; this.CCTrackAllSessions)
            {
                ApplicationArea = All;
                Caption = 'Code Coverage Track All Sessions';
                ToolTip = 'Specifies if the Code Coverage should track all sessions';

                trigger OnValidate()
                begin
                    this.TestSuiteMgt.SetCCTrackAllSessions(this.GlobalALTestSuite, this.CCTrackAllSessions);
                end;
            }

            field(CCExporterID; this.CodeCoverageExporterID)
            {
                ApplicationArea = All;
                Caption = 'Code Coverage Exporter ID';
                ToolTip = 'Specifies the Code Coverage exporter ID';

                trigger OnValidate()
                begin
                    this.TestSuiteMgt.SetCodeCoverageExporterID(this.GlobalALTestSuite, this.CodeCoverageExporterID);
                end;
            }

            field(CCResultsCSVText; this.CCResultsCSVText)
            {
                ApplicationArea = All;
                Editable = false;
                MultiLine = true;
                Caption = 'Code Coverage Results CSV';
                ToolTip = 'Specifies the Code Coverage results as CSV';
            }

            field(CCMapCSVText; this.CCMapCSVText)
            {
                Caption = 'Code Coverage Map CSV Text';
                ToolTip = 'Specifies the Code Coverage Map CSV Text';
                ApplicationArea = All;
                Editable = false;
                MultiLine = true;
            }

            field(CCInfo; this.CCInfo)
            {
                ApplicationArea = All;
                Editable = false;
                MultiLine = true;
                Caption = 'Code Coverage Information';
                ToolTip = 'Specifies the Code Coverage information';
            }

            field(StabilityRun; this.StabilityRun)
            {
                ApplicationArea = All;
                Caption = 'Stability run';
                ToolTip = 'Specifies the latest execution of the test as JSON';

                trigger OnValidate()
                var
                    TestSuiteMgt: Codeunit "Test Suite Mgt.";
                begin
                    TestSuiteMgt.ChangeStabilityRun(this.GlobalALTestSuite, this.StabilityRun);
                end;
            }
            repeater(Control1)
            {
                IndentationControls = Name;
                ShowCaption = false;
                field(LineType; this.LineTypeCode)
                {
                    ApplicationArea = All;
                    Caption = 'Line Type';
                    Editable = false;
                    ToolTip = 'Specifies a Non-Translatable value for console test runner.';
                }
                field(TestCodeunit; Rec."Test Codeunit")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ID the test codeunit.';
                    Caption = 'Codeunit ID';
                    Editable = false;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Name';
                    Editable = false;
                    ToolTip = 'Specifies the name of the test tool.';
                }
                field(Run; Rec.Run)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies wether the tests should run.';
                    Caption = 'Run';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(Result; this.ResultCode)
                {
                    ApplicationArea = All;
                    Caption = 'Result';
                    Editable = false;
                    ToolTip = 'Specifies a Non-Translatable value for console test runner.';
                }
                field(ErrorMessage; this.FullErrorMessage)
                {
                    ApplicationArea = All;
                    Caption = 'Error Message';
                    DrillDown = true;
                    Editable = false;
                    ToolTip = 'Specifies full error message with stack trace';
                }
                field(StackTrace; this.StackTrace)
                {
                    ApplicationArea = All;
                    Caption = 'Stack Trace';
                    ToolTip = 'Specifies stack trace';
                }
                field(FinishTime; Rec."Finish Time")
                {
                    ApplicationArea = All;
                    Caption = 'Finish Time';
                    ToolTip = 'Specifies the duration of the test run';
                }
                field(StartTime; Rec."Start Time")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the time the test started.';
                    Caption = 'Start Time';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(RunSelectedTests)
            {
                ApplicationArea = All;
                ToolTip = 'Runs the selected tests.';
                Caption = 'Run Se&lected Tests';
                Image = TestFile;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    TestMethodLine: Record "Test Method Line";
                    TestSuiteMgt: Codeunit "Test Suite Mgt.";
                begin
                    TestMethodLine.Copy(Rec);
                    CurrPage.SetSelectionFilter(TestMethodLine);
                    TestSuiteMgt.RunSelectedTests(TestMethodLine);
                    Rec.Find();
                    CurrPage.Update(true);
                end;
            }

            action(RunNextTest)
            {
                ApplicationArea = All;
                ToolTip = 'Runs the next test.';
                Caption = 'Run N&ext Test';
                Image = TestReport;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                var
                    TestMethodLine: Record "Test Method Line";
                    TestSuiteMgt: Codeunit "Test Suite Mgt.";
                begin
                    TestMethodLine.Copy(Rec);
                    Clear(this.TestResultsJSONText);
                    if TestSuiteMgt.RunNextTest(TestMethodLine) then
                        this.TestResultsJSONText := TestSuiteMgt.TestResultsToJSON(TestMethodLine)
                    else
                        this.TestResultsJSONText := this.AllTestsExecutedTxt;

                    if Rec.Find() then;
                    CurrPage.Update(true);
                end;
            }

            action(ClearTestResults)
            {
                ApplicationArea = All;
                ToolTip = 'Clear the test results.';
                Caption = 'Clear Test R&esults';
                Image = ClearLog;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                PromotedIsBig = true;

                trigger OnAction()
                begin
                    Rec.SetRange("Test Suite", this.CurrentSuiteName);
                    Rec.ModifyAll(Result, Rec.Result::" ", true);
                    Clear(this.TestResultsJSONText);
                end;
            }
            action(GetCodeCoverage)
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Update Code Coverage';
                Image = Action;

                trigger OnAction()
                var
                    ALCodeCoverageMgt: Codeunit "AL Code Coverage Mgt.";
                begin
                    Clear(this.CCResultsCSVText);
                    Clear(this.CCInfo);
                    if not ALCodeCoverageMgt.ConsumeCoverageResult(this.CCResultsCSVText, this.CCInfo) then
                        this.CCInfo := this.DoneLbl;
                    CurrPage.Update(true);
                end;
            }

            action(GetCodeCoverageMap)
            {
                ApplicationArea = All;
                ToolTip = 'Get Code Coverage Map';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                Image = Action;

                trigger OnAction()
                var
                    ALCodeCoverageMgt: Codeunit "AL Code Coverage Mgt.";
                begin
                    Clear(this.CCMapCSVText);
                    ALCodeCoverageMgt.GetCoveCoverageMap(this.CCMapCSVText);
                    CurrPage.Update(true);
                end;
            }
            action(ClearCodeCoverage)
            {
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                ToolTip = 'Clear Code Coverage';
                Image = Action;

                trigger OnAction()
                var
                    TestCodeCoverageResult: Record "Test Code Coverage Result";
                    CodeCoverage: Record "Code Coverage";
                begin
                    TestCodeCoverageResult.DeleteAll();
                    CodeCoverage.DeleteAll();
                    System.CodeCoverageRefresh();
                    this.CCInfo := '';
                    this.CCResultsCSVText := '';
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        this.TestSuiteMgt.CalcTestResults(Rec, this.Success, this.Failure, this.Skipped, this.NotExecuted);
        this.UpdateLine();
    end;

    trigger OnAfterGetRecord()
    begin
        this.TestSuiteMgt.CalcTestResults(Rec, this.Success, this.Failure, this.Skipped, this.NotExecuted);
        this.UpdateLine();
    end;

    trigger OnOpenPage()
    begin
        this.SetCurrentTestSuite();
    end;

    protected var
        GlobalALTestSuite: Record "AL Test Suite";

    var
        TestSuiteMgt: Codeunit "Test Suite Mgt.";
        CurrentSuiteName: Code[10];
        TestCodeunitRangeFilter: Text;
        TestProcedureRangeFilter: Text;
        TestRunnerCodeunitId: Integer;
        Skipped: Integer;
        Success: Integer;
        Failure: Integer;
        NotExecuted: Integer;
        ResultCode: Text;
        LineTypeCode: Text;
        FullErrorMessage: Text;
        StackTrace: Text;
        ExtensionId: Text;
        RemoveTestMethod: Text;
        TestResultsJSONText: Text;
        CCResultsCSVText: Text;
        CCMapCSVText: Text;
        CCInfo: Text;
        AllTestsExecutedTxt: Label 'All tests executed.', Locked = true;
        DoneLbl: Label 'Done.', Locked = true;
        CCTrackingType: Integer;
        CCMap: Integer;
        CCTrackAllSessions: Boolean;
        CodeCoverageExporterID: Integer;
        StabilityRun: Boolean;

    local procedure ChangeTestSuite()
    begin
        if not this.GlobalALTestSuite.Get(this.CurrentSuiteName) then begin
            this.TestSuiteMgt.CreateTestSuite(this.CurrentSuiteName);
            Commit();
        end;

        this.GlobalALTestSuite.CalcFields("Tests to Execute");

        CurrPage.SaveRecord();

        Rec.FilterGroup(2);
        Rec.SetRange("Test Suite", this.CurrentSuiteName);
        Rec.FilterGroup(0);

        CurrPage.Update(false);
    end;

    local procedure SetCurrentTestSuite()
    begin
        if not this.GlobalALTestSuite.Get(this.CurrentSuiteName) then
            if this.GlobalALTestSuite.FindFirst() then
                this.CurrentSuiteName := this.GlobalALTestSuite.Name
            else begin
                this.TestSuiteMgt.CreateTestSuite(this.CurrentSuiteName);
                Commit();
            end;

        Rec.FilterGroup(2);
        Rec.SetRange("Test Suite", this.CurrentSuiteName);
        Rec.FilterGroup(0);

        if Rec.Find('-') then;

        this.GlobalALTestSuite.Get(this.CurrentSuiteName);
        this.GlobalALTestSuite.CalcFields("Tests to Execute");
        this.TestRunnerCodeunitId := this.GlobalALTestSuite."Test Runner Id";
        this.StabilityRun := this.GlobalALTestSuite."Stability Run";
        this.CCTrackAllSessions := this.GlobalALTestSuite."CC Track All Sessions";
        this.CCTrackingType := this.GlobalALTestSuite."CC Tracking Type";
        this.CodeCoverageExporterID := this.GlobalALTestSuite."CC Exporter ID";
        this.CCMap := this.GlobalALTestSuite."CC Coverage Map";
    end;

    local procedure UpdateLine()
        ConvertToInteger: Integer;
    begin
        ConvertToInteger := Rec.Result;
        this.ResultCode := Format(ConvertToInteger);

        ConvertToInteger := Rec."Line Type";
        this.LineTypeCode := Format(ConvertToInteger);

        this.StackTrace := this.TestSuiteMgt.GetErrorCallStack(Rec);
        this.FullErrorMessage := this.TestSuiteMgt.GetFullErrorMessage(Rec);
    end;

    local procedure FindAndDisableTestMethod()
    var
        TestMethodLine: Record "Test Method Line";
        CodeunitTestMethodLine: Record "Test Method Line";
        CodeunitName: Text;
        TestMethodName: Text;
    begin
        if StrPos(this.RemoveTestMethod, ',') <= 0 then
            exit;

        CodeunitName := CopyStr(SelectStr(1, this.RemoveTestMethod), 1, MaxStrLen(CodeunitTestMethodLine.Name));
        TestMethodName := CopyStr(SelectStr(2, this.RemoveTestMethod), 1, MaxStrLen(CodeunitTestMethodLine.Name));

        if CodeunitName = '' then
            exit;

        if TestMethodName = '' then
            exit;

        CodeunitTestMethodLine.SetRange("Test Suite", this.GlobalALTestSuite.Name);
        CodeunitTestMethodLine.SetRange("Line Type", CodeunitTestMethodLine."Line Type"::Codeunit);
        CodeunitTestMethodLine.SetFilter(Name, CodeunitName);
        if CodeunitTestMethodLine.IsEmpty() then
            CodeunitTestMethodLine.SetRange(Name, CodeunitName);
        if not CodeunitTestMethodLine.FindSet() then
            exit;
        repeat
            TestMethodLine.SetRange("Test Suite", this.GlobalALTestSuite.Name);
            TestMethodLine.SetRange("Line Type", Rec."Line Type"::"Function");
            TestMethodLine.SetRange("Test Codeunit", CodeunitTestMethodLine."Test Codeunit");
            TestMethodLine.SetFilter(Name, TestMethodName);
            TestMethodLine.ModifyAll(Run, false);

            TestMethodLine.SetRange(Name);
            TestMethodLine.SetRange(Run, true);
            if TestMethodLine.IsEmpty() then begin
                CodeunitTestMethodLine.Validate(Run, false);
                CodeunitTestMethodLine.Modify(true);
            end;
        until CodeunitTestMethodLine.Next() = 0;

        CurrPage.Update();
    end;
}
