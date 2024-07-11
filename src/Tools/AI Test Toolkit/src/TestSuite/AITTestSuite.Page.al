// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Environment;
using System.TestTools.TestRunner;

page 149031 "AIT Test Suite"
{
    Caption = 'AI Test Suite';
    ApplicationArea = All;
    PageType = Document;
    SourceTable = "AIT Test Suite";
    Extensible = false;
    DataCaptionExpression = PageCaptionLbl + ' - ' + Rec."Code";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'AI Test Suite';
                Enabled = Rec.Status <> Rec.Status::Running;

                field("Code"; Rec."Code")
                {
                    ToolTip = 'Specifies the ID of the test suite.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the description of the test suite.';
                }
                field(Dataset; Rec."Input Dataset")
                {
                    ToolTip = 'Specifies the dataset to be used by the tests.';
                    ShowMandatory = true;
                    NotBlank = true;
                }
                field("Model Version"; Rec."Model Version")
                {
                    ToolTip = 'Specifies the model version to be used by the tests.';
                }
                field("Test Runner Id"; TestRunnerDisplayName)
                {
                    Caption = 'Test Runner';
                    ToolTip = 'Specifies the Test Runner to be used by the tests.';
                    Editable = false;

                    trigger OnDrillDown()
                    begin
                        // Used to fix the rendering - don't show as a box
                        Error('');
                    end;

                    trigger OnAssistEdit()
                    var
                        AITALTestSuiteMgt: Codeunit "AIT AL Test Suite Mgt";
                    begin
                        AITALTestSuiteMgt.AssistEditTestRunner(Rec);
                        CurrPage.Update(true);
                    end;
                }
                group(StatusGroup)
                {
                    Caption = 'Suite Status';
                    field(Status; Rec.Status)
                    {
                        ToolTip = 'Specifies the status of the test.';
                    }
                    field(Started; Rec."Started at")
                    {
                        ToolTip = 'Specifies when the test was started.';
                    }
                    field(Version; Rec.Version)
                    {
                        ToolTip = 'Specifies the current version of the test run. Log entries will get this version no.';
                        Editable = false;
                    }

                    field(Tag; Rec.Tag)
                    {
                        ToolTip = 'Specifies the tag for a test run. The Tag will be transferred to the log entries and enables comparison between tests.';
                    }
                }
            }
            part(AITTestMethodLines; "AIT Test Method Lines")
            {
                Enabled = Rec.Status <> Rec.Status::Running;
                SubPageLink = "Test Suite Code" = field("Code"), "Version Filter" = field(Version), "Base Version Filter" = field("Base Version");
                UpdatePropagation = Both;
            }
            group("Latest Run")
            {
                Caption = 'Latest Run';

                field("No. of Tests Executed"; Rec."No. of Tests Executed")
                {
                    Caption = 'No. of Tests Executed';
                    ToolTip = 'Specifies the number of tests executed in the current version.';
                    Editable = false;
                }
                field("No. of Tests Passed"; Rec."No. of Tests Passed")
                {
                    Caption = 'No. of Tests Passed';
                    ToolTip = 'Specifies the number of tests passed in the current version.';
                    Editable = false;
                    Style = Favorable;
                }
                field("No. of Tests Failed"; Rec."No. of Tests Executed" - Rec."No. of Tests Passed")
                {
                    Editable = false;
                    Style = Unfavorable;
                    Caption = 'No. of Tests Failed';
                    ToolTip = 'Specifies the number of tests failed in the current version.';

                    trigger OnDrillDown()
                    var
                        AITLogEntry: Codeunit "AIT Log Entry";
                    begin
                        AITLogEntry.DrillDownFailedAITLogEntries(Rec.Code, 0, Rec.Version);
                    end;
                }
                field("No. of Operations"; Rec."No. of Operations")
                {
                    Caption = 'No. of Operations';
                    ToolTip = 'Specifies the number of operations executed in the current version.';
                    Visible = false;
                    Enabled = false;
                }
                field("Total Duration"; TotalDuration)
                {
                    Editable = false;
                    Caption = 'Total Duration';
                    ToolTip = 'Specifies the total duration (ms) for executing all the selected tests in the current version.';
                }
                field("Average Duration"; AvgTimeDuration)
                {
                    Editable = false;
                    Caption = 'Average Duration';
                    ToolTip = 'Specifies the average time (ms) taken by the tests in the last run.';
                }
            }

        }
    }
    actions
    {
        area(Processing)
        {
            action(Start)
            {
                Enabled = (EnableActions and (Rec.Status <> Rec.Status::Running));
                Caption = 'Start';
                Image = Start;
                ToolTip = 'Starts running the AI Test Suite.';

                trigger OnAction()
                begin
                    CurrPage.Update(false);
                    AITTestSuiteMgt.StartAITSuite(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(RefreshStatus)
            {
                Caption = 'Refresh';
                ToolTip = 'Refreshes the page.';
                Image = Refresh;

                trigger OnAction()
                begin
                    Rec.Find();
                    CurrPage.Update(false);
                end;
            }
            action(ResetStatus)
            {
                Enabled = Rec.Status = Rec.Status::Running;
                Caption = 'Reset Status';
                ToolTip = 'Reset the status.';
                Image = ResetStatus;

                trigger OnAction()
                begin
                    AITTestSuiteMgt.ResetStatus(Rec);
                end;
            }

            action(Compare)
            {
                Caption = 'Compare Versions';
                Image = CompareCOA;
                ToolTip = 'Compare results of the suite to a base version.';
                Scope = Repeater;

                trigger OnAction()
                var
                    AITTestSuiteComparePage: Page "AIT Test Suite Compare";
                begin
                    AITTestSuiteComparePage.SetCompareVersions(Rec.Code, Rec.Version, Rec."Version" - 1);
                    AITTestSuiteComparePage.Run();
                end;
            }
        }
        area(Navigation)
        {
            action(LogEntries)
            {
                Caption = 'Log Entries';
                Image = Entries;
                ToolTip = 'Open log entries.';
                RunObject = page "AIT Log Entries";
                RunPageLink = "Test Suite Code" = field(Code), Version = field(Version);
            }
            action(Datasets)
            {
                Caption = 'Input Datasets';
                Image = DataEntry;
                ToolTip = 'Open input datasets.';
                RunObject = page "Test Input Groups";
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(Start_Promoted; Start)
                {
                }
                actionref(LogEntries_Promoted; LogEntries)
                {
                }
                actionref(Compare_Promoted; Compare)
                {
                }
                actionref(Datasets_Promoted; Datasets)
                {
                }
            }
        }
    }

    var
        AITTestSuiteMgt: Codeunit "AIT Test Suite Mgt.";
        EnableActions: Boolean;
        AvgTimeDuration: Duration;
        TotalDuration: Duration;
        PageCaptionLbl: Label 'AI Test';
        TestRunnerDisplayName: Text;

    trigger OnOpenPage()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        EnableActions := (EnvironmentInformation.IsSaaS() and EnvironmentInformation.IsSandbox()) or EnvironmentInformation.IsOnPrem();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.AssignDefaultTestRunner();
    end;

    trigger OnAfterGetCurrRecord()
    var
        TestSuiteMgt: Codeunit "Test Suite Mgt.";
    begin
        UpdateTotalDuration();
        UpdateAverageExecutionTime();
        TestRunnerDisplayName := TestSuiteMgt.GetTestRunnerDisplayName(Rec."Test Runner Id");
    end;

    local procedure UpdateTotalDuration()
    begin
        Rec.CalcFields("Total Duration (ms)");
        TotalDuration := Rec."Total Duration (ms)";
    end;

    local procedure UpdateAverageExecutionTime()
    begin
        Rec.CalcFields("No. of Tests Executed", "Total Duration (ms)", "No. of Tests Executed - Base", "Total Duration (ms) - Base");
        if Rec."No. of Tests Executed" > 0 then
            AvgTimeDuration := Rec."Total Duration (ms)" div Rec."No. of Tests Executed"
        else
            AvgTimeDuration := 0;
    end;
}