// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

using System.TestTools.CodeCoverage;

page 130451 "AL Test Tool"
{
    AccessByPermission = tabledata "Test Method Line" = RIMD;
    ApplicationArea = All;
    AutoSplitKey = true;
    Caption = 'AL Test Tool';
    DataCaptionExpression = this.CurrentSuiteName;
    DelayedInsert = true;
    DeleteAllowed = true;
    ModifyAllowed = true;
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Test Method Line";
    UsageCategory = Administration;
    Permissions = tabledata "AL Test Suite" = rimd,
                  tabledata "Test Method Line" = rimd;

    layout
    {
        area(content)
        {
            group(Settings)
            {
                ShowCaption = false;
                field(CurrentSuiteName; this.CurrentSuiteName)
                {
                    ApplicationArea = All;
                    Caption = 'Suite Name';
                    ToolTip = 'Specifies the currently selected Test Suite';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ALTestSuite: Record "AL Test Suite";
                    begin
                        ALTestSuite.Name := this.CurrentSuiteName;
                        if PAGE.RunModal(0, ALTestSuite) <> ACTION::LookupOK then
                            exit(false);

                        Text := ALTestSuite.Name;
                        CurrPage.Update(false);
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        this.ChangeTestSuite();
                    end;
                }

                field(TestRunner; this.TestRunnerDisplayName)
                {
                    ApplicationArea = All;
                    Caption = 'Test Runner Codeunit';
                    Editable = false;
                    ToolTip = 'Specifies currently selected test runner';

                    trigger OnDrillDown()
                    begin
                        // Used to fix the rendering - don't show as a box
                        Error('');
                    end;

                    trigger OnAssistEdit()
                    var
                        TestSuiteMgt: Codeunit "Test Suite Mgt.";
                    begin
                        TestSuiteMgt.LookupTestRunner(this.GlobalALTestSuite);
                        this.TestRunnerDisplayName := TestSuiteMgt.GetTestRunnerDisplayName(this.GlobalALTestSuite);
                    end;
                }

                field(CodeCoverageTrackingType; this.GlobalALTestSuite."CC Tracking Type")
                {
                    ApplicationArea = All;
                    Caption = 'Code Coverage Tracking';
                    ToolTip = 'Specifies how the code coverage should be tracked';

                    trigger OnValidate()
                    var
                        TestSuiteMgt: Codeunit "Test Suite Mgt.";
                    begin
                        TestSuiteMgt.UpdateCodeCoverageTrackingType(this.GlobalALTestSuite);
                    end;
                }

                field(CodeCoverageTrackAllSesssions; this.GlobalALTestSuite."CC Track All Sessions")
                {
                    ApplicationArea = All;
                    Caption = 'Code Coverage Track All Sessions';
                    ToolTip = 'Specifies should all sessions be tracked';

                    trigger OnValidate()
                    var
                        TestSuiteMgt: Codeunit "Test Suite Mgt.";
                    begin
                        TestSuiteMgt.UpdateCodeCoverageTrackAllSesssions(this.GlobalALTestSuite);
                    end;
                }
            }

            repeater(Control1)
            {
                IndentationColumn = this.NameIndent;
                IndentationControls = Name;
                ShowAsTree = true;
                ShowCaption = false;
                field(LineType; Rec."Line Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the line type.';
                    Caption = 'Line Type';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = this.LineTypeEmphasize;
                }
                field(TestCodeunit; Rec."Test Codeunit")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the ID of the test codeunit.';
                    BlankZero = true;
                    Caption = 'Codeunit ID';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = this.TestCodeunitEmphasize;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Caption = 'Name';
                    Editable = false;
                    Style = Strong;
                    StyleExpr = this.NameEmphasize;
                    ToolTip = 'Specifies the name of the test tool.';
                }
                field(Run; Rec.Run)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the tests should be executed.';
                    Caption = 'Run';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(Result; Rec.Result)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the tests passed, failed or were skipped.';
                    BlankZero = true;
                    Caption = 'Result';
                    Editable = false;
                    Style = Favorable;
                    StyleExpr = this.ResultEmphasize;
                }
                field("Error Message"; this.ErrorMessageWithStackTraceTxt)
                {
                    ApplicationArea = All;
                    Caption = 'Error Message';
                    DrillDown = true;
                    Editable = false;
                    Style = Unfavorable;
                    StyleExpr = true;
                    ToolTip = 'Specifies full error message with stack trace';

                    trigger OnDrillDown()
                    begin
                        Message(this.ErrorMessageWithStackTraceTxt);
                    end;
                }
                field(Duration; this.RunDuration)
                {
                    ApplicationArea = All;
                    Caption = 'Duration';
                    Editable = false;
                    ToolTip = 'Specifies the duration of the test run';
                }
            }
            group(Control14)
            {
                ShowCaption = false;
                field(SuccessfulTests; this.Success)
                {
                    ApplicationArea = All;
                    AutoFormatType = 1;
                    Caption = 'Successful Tests';
                    Editable = false;
                    ToolTip = 'Specifies the number of Successful Tests';
                }
                field(FailedTests; this.Failure)
                {
                    ApplicationArea = All;
                    AutoFormatType = 1;
                    Caption = 'Failed Tests';
                    Editable = false;
                    ToolTip = 'Specifies the number of Failed Tests';
                }
                field(SkippedTests; this.Skipped)
                {
                    ApplicationArea = All;
                    AutoFormatType = 1;
                    Caption = 'Skipped Tests';
                    Editable = false;
                    ToolTip = 'Specifies the number of Skipped Tests';
                }
                field(NotExecutedTests; this.NotExecuted)
                {
                    ApplicationArea = All;
                    AutoFormatType = 1;
                    Caption = 'Tests not Executed';
                    Editable = false;
                    ToolTip = 'Specifies the number of Tests Not Executed';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("Run Tests")
            {
                Caption = 'Run Tests';
                action(RunTests)
                {
                    ApplicationArea = All;
                    Caption = '&Run Tests';
                    Image = Start;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Runs tests.';

                    trigger OnAction()
                    var
                        TestSuiteMgt: Codeunit "Test Suite Mgt.";
                        TestRunnerProgressDialog: Codeunit "Test Runner - Progress Dialog";
                    begin
                        BindSubscription(TestRunnerProgressDialog);
                        TestSuiteMgt.RunTestSuiteSelection(Rec);
                        CurrPage.Update(false);
                    end;
                }
                action(RunSelectedTests)
                {
                    ApplicationArea = All;
                    Caption = 'Run Se&lected Tests';
                    Image = TestFile;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Runs selected tests.';

                    trigger OnAction()
                    var
                        TestMethodLine: Record "Test Method Line";
                        TestSuiteMgt: Codeunit "Test Suite Mgt.";
                    begin
                        TestMethodLine.Copy(Rec);
                        CurrPage.SetSelectionFilter(TestMethodLine);
                        TestSuiteMgt.RunSelectedTests(TestMethodLine);
                    end;
                }
            }
            group("Manage Tests")
            {
                Caption = 'Manage Tests';
                action(GetTestCodeunits)
                {
                    ApplicationArea = All;
                    Caption = 'Get &Test Codeunits';
                    Image = ChangeToLines;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Prompts a dialog to add test codeunits.';

                    trigger OnAction()
                    var
                        TestSuiteMgt: Codeunit "Test Suite Mgt.";
                    begin
                        TestSuiteMgt.SelectTestMethods(this.GlobalALTestSuite);
                        CurrPage.Update(false);
                    end;
                }
                action(GetTestsByRange)
                {
                    ApplicationArea = All;
                    Caption = 'Get Test Codeunits by Ra&nge';
                    Image = GetLines;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Add test codeunits by using a range string.';

                    trigger OnAction()
                    var
                        TestSuiteMgt: Codeunit "Test Suite Mgt.";
                    begin
                        TestSuiteMgt.LookupTestMethodsByRange(this.GlobalALTestSuite);
                        CurrPage.Update(false);
                    end;
                }
                action(UpdateTests)
                {
                    ApplicationArea = All;
                    Caption = 'Update Test Methods';
                    Image = RefreshLines;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Updates the test methods for the entire test suite.';

                    trigger OnAction()
                    var
                        TestSuiteMgt: Codeunit "Test Suite Mgt.";
                    begin
                        TestSuiteMgt.UpdateTestMethods(Rec);
                        CurrPage.Update(false);
                    end;
                }
                action(DeleteLines)
                {
                    ApplicationArea = All;
                    Caption = '&Delete Lines';
                    Image = Delete;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Delete the selected lines.';

                    trigger OnAction()
                    var
                        TestMethodLine: Record "Test Method Line";
                        TestSuiteMgt: Codeunit "Test Suite Mgt.";
                    begin
                        if GuiAllowed() then
                            if not Confirm(this.DeleteQst, false) then
                                exit;

                        CurrPage.SetSelectionFilter(TestMethodLine);
                        TestMethodLine.DeleteAll(true);
                        TestSuiteMgt.CalcTestResults(Rec, this.Success, this.Failure, this.Skipped, this.NotExecuted);
                    end;
                }
                action(InvertRun)
                {
                    ApplicationArea = All;
                    Caption = '&Invert Run Selection';
                    Image = Change;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Invert Run Selection on selected lines.';

                    trigger OnAction()
                    begin
                        this.InvertRunSelection();
                    end;
                }

                action(CodeCoverage)
                {
                    ApplicationArea = All;
                    Caption = '&Code Coverage';
                    Image = CheckRulesSyntax;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    RunObject = page "AL Code Coverage";
                    ToolTip = 'Specifies the action for invoking Code Coverage page';
                }
            }
            group("Test Suite")
            {
                Caption = 'Test Suite';
                action(SelectTestRunner)
                {
                    ApplicationArea = All;
                    Caption = 'Select Test R&unner';
                    Image = SetupList;
                    Visible = false;
                    Promoted = true;
                    PromotedCategory = Process;
                    PromotedIsBig = true;
                    PromotedOnly = true;
                    ToolTip = 'Specifies the action to select a test runner';

                    trigger OnAction()
                    var
                        TestSuiteMgt: Codeunit "Test Suite Mgt.";
                    begin
                        TestSuiteMgt.LookupTestRunner(this.GlobalALTestSuite);
                        this.TestRunnerDisplayName := TestSuiteMgt.GetTestRunnerDisplayName(this.GlobalALTestSuite);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        TestSuiteMgt: Codeunit "Test Suite Mgt.";
    begin
        TestSuiteMgt.CalcTestResults(Rec, this.Success, this.Failure, this.Skipped, this.NotExecuted);
        this.UpdateDisplayPropertiesForLine();
        this.UpdateCalculatedFields();
    end;

    trigger OnOpenPage()
    begin
        this.SetCurrentTestSuite();
    end;

    var
        GlobalALTestSuite: Record "AL Test Suite";
        CurrentSuiteName: Code[10];
        Skipped: Integer;
        Success: Integer;
        Failure: Integer;
        NotExecuted: Integer;
        NameIndent: Integer;
        LineTypeEmphasize: Boolean;
        NameEmphasize: Boolean;
        TestCodeunitEmphasize: Boolean;
        ResultEmphasize: Boolean;
        RunDuration: Duration;
        TestRunnerDisplayName: Text;
        ErrorMessageWithStackTraceTxt: Text;
        DeleteQst: Label 'Are you sure you want to delete the selected lines?';

    local procedure ChangeTestSuite()
    var
        TestSuiteMgt: Codeunit "Test Suite Mgt.";
    begin
        this.GlobalALTestSuite.Get(this.CurrentSuiteName);
        this.GlobalALTestSuite.CalcFields("Tests to Execute");

        CurrPage.SaveRecord();

        Rec.FilterGroup(2);
        Rec.SetRange("Test Suite", this.CurrentSuiteName);
        Rec.FilterGroup(0);

        CurrPage.Update(false);

        this.TestRunnerDisplayName := TestSuiteMgt.GetTestRunnerDisplayName(this.GlobalALTestSuite);
    end;

    local procedure SetCurrentTestSuite()
    var
        TestSuiteMgt: Codeunit "Test Suite Mgt.";
    begin
        this.GlobalALTestSuite.SetAutoCalcFields("Tests to Execute");

        if not this.GlobalALTestSuite.Get(this.CurrentSuiteName) then
            if (this.CurrentSuiteName = '') and this.GlobalALTestSuite.FindFirst() then
                this.CurrentSuiteName := this.GlobalALTestSuite.Name
            else begin
                TestSuiteMgt.CreateTestSuite(this.CurrentSuiteName);
                Commit();
                this.GlobalALTestSuite.Get(this.CurrentSuiteName);
            end;

        Rec.FilterGroup(2);
        Rec.SetRange("Test Suite", this.CurrentSuiteName);
        Rec.FilterGroup(0);

        if Rec.Find('-') then;

        this.TestRunnerDisplayName := TestSuiteMgt.GetTestRunnerDisplayName(this.GlobalALTestSuite);
    end;

    local procedure UpdateDisplayPropertiesForLine()
    begin
        this.NameIndent := Rec."Line Type";
        this.LineTypeEmphasize := Rec."Line Type" = Rec."Line Type"::Codeunit;
        this.TestCodeunitEmphasize := Rec."Line Type" = Rec."Line Type"::Codeunit;
#pragma warning disable AA0205
        this.ResultEmphasize := Rec.Result = Rec.Result::Success;
#pragma warning restore AA0205
    end;

    local procedure UpdateCalculatedFields()
    var
        TestSuiteMgt: Codeunit "Test Suite Mgt.";
    begin
        this.RunDuration := Rec."Finish Time" - Rec."Start Time";
        this.ErrorMessageWithStackTraceTxt := TestSuiteMgt.GetErrorMessageWithStackTrace(Rec);
    end;

    local procedure InvertRunSelection()
    var
        TestMethodLine: Record "Test Method Line";
    begin
        CurrPage.SetSelectionFilter(TestMethodLine);

        if TestMethodLine.FindSet(true) then
            repeat
                TestMethodLine.Validate(Run, not TestMethodLine.Run);
                TestMethodLine.Modify(true);
            until TestMethodLine.Next() = 0;
    end;
}
