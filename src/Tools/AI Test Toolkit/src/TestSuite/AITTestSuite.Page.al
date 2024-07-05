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
    PageType = Document;
    SourceTable = "AIT Test Suite";
    Extensible = false;
    DataCaptionExpression = this.PageCaptionLbl + ' - ' + Rec."Code";

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
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the description of the test suite.';
                    ApplicationArea = All;
                }
                field(Dataset; Rec."Input Dataset")
                {
                    ToolTip = 'Specifies the dataset to be used by the tests.';
                    ApplicationArea = All;
                    ShowMandatory = true;
                    NotBlank = true;
                }
                field("Model Version"; Rec."ModelVersion")
                {
                    ToolTip = 'Specifies the model version to be used by the tests.';
                    ApplicationArea = All;
                }
                field("Test Runner Id"; this.TestRunnerDisplayName)
                {
                    Caption = 'Test Runner';
                    ToolTip = 'Specifies the Test Runner to be used by the tests.';
                    ApplicationArea = All;
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
                        ApplicationArea = All;
                    }
                    field(Started; Rec."Started at")
                    {
                        ToolTip = 'Specifies when the test was started.';
                        ApplicationArea = All;
                    }
                    field(Version; Rec.Version)
                    {
                        ToolTip = 'Specifies the current version of the test run. Log entries will get this version no.';
                        ApplicationArea = All;
                        Editable = false;
                    }

                    field(Tag; Rec.Tag)
                    {
                        ToolTip = 'Specifies the tag for a test run. The Tag will be transferred to the log entries and enables comparison between tests.';
                        ApplicationArea = All;
                    }
                }
            }
            part(AITTestMethodLines; "AIT Test Method Lines")
            {
                ApplicationArea = All;
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
                    ApplicationArea = All;
                }
                field("No. of Tests Passed"; Rec."No. of Tests Passed") // TODO: this should be filtered on not empty output
                {
                    Caption = 'No. of Tests Passed';
                    ToolTip = 'Specifies the number of tests passed in the current version.';
                    Editable = false;
                    ApplicationArea = All;
                    Style = Favorable;
                }
                field("No. of Tests Failed"; Rec."No. of Tests Executed" - Rec."No. of Tests Passed")
                {
                    Editable = false;
                    ApplicationArea = All;
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
                    ApplicationArea = All;
                    Caption = 'No. of Operations';
                    ToolTip = 'Specifies the number of operations executed in the current version.';
                    Visible = false;
                    Enabled = false;
                }
                field("Total Duration"; this.TotalDuration)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Total Duration';
                    ToolTip = 'Specifies the Total Duration for executing all the selected tests in the current version.';
                }
                field("Average Duration"; this.AvgTimeDuration)
                {
                    Editable = false;
                    ApplicationArea = All;
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
                Enabled = (this.EnableActions and (Rec.Status <> Rec.Status::Running));
                ApplicationArea = All;
                Caption = 'Start';
                Image = Start;
                ToolTip = 'Starts running the AIT Suite.';

                trigger OnAction()
                begin
                    CurrPage.Update(false);
                    this.AITTestSuiteMgt.StartAITSuite(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(RefreshStatus)
            {
                ApplicationArea = All;
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
                ApplicationArea = All;
                Caption = 'Reset Status';
                ToolTip = 'Reset the status.';
                Image = ResetStatus;

                trigger OnAction()
                begin
                    this.AITTestSuiteMgt.ResetStatus(Rec);
                end;
            }

            action(Compare)
            {
                ApplicationArea = All;
                Caption = 'Compare Versions';
                Image = CompareCOA;
                ToolTip = 'Compare results of the suite to a base version.';
                Scope = Repeater;

                trigger OnAction()
                var
                    TemporaryAITTestSuiteRec: Record "AIT Test Suite" temporary;
                    AITTestSuiteComparePage: Page "AIT Test Suite Compare";
                begin
                    TemporaryAITTestSuiteRec.Code := Rec.Code;
                    TemporaryAITTestSuiteRec.Version := Rec.Version;
                    TemporaryAITTestSuiteRec."Base Version" := Rec."Version" - 1;
                    TemporaryAITTestSuiteRec.Insert();

                    AITTestSuiteComparePage.SetBaseVersion(Rec."Version" - 1);
                    AITTestSuiteComparePage.SetVersion(Rec.Version);
                    AITTestSuiteComparePage.SetRecord(TemporaryAITTestSuiteRec);
                    AITTestSuiteComparePage.Run();
                end;
            }
        }
        area(Navigation)
        {
            action(LogEntries)
            {
                ApplicationArea = All;
                Caption = 'Log Entries';
                Image = Entries;
                ToolTip = 'Open log entries.';
                RunObject = page "AIT Log Entries";
                RunPageLink = "Test Suite Code" = field(Code), Version = field(Version);
            }
            action(Datasets)
            {
                ApplicationArea = All;
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
        this.EnableActions := (EnvironmentInformation.IsSaaS() and EnvironmentInformation.IsSandbox()) or EnvironmentInformation.IsOnPrem();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.AssignDefaultTestRunner();
    end;

    trigger OnAfterGetCurrRecord()
    var
        TestSuiteMgt: Codeunit "Test Suite Mgt.";
    begin
        this.UpdateTotalDuration();
        this.UpdateAverageExecutionTime();
        this.TestRunnerDisplayName := TestSuiteMgt.GetTestRunnerDisplayName(Rec."Test Runner Id");
    end;

    local procedure UpdateTotalDuration()
    begin
        Rec.CalcFields("Total Duration (ms)");
        this.TotalDuration := Rec."Total Duration (ms)";
    end;

    local procedure UpdateAverageExecutionTime()
    begin
        Rec.CalcFields("No. of Tests Executed", "Total Duration (ms)", "No. of Tests Executed - Base", "Total Duration (ms) - Base");
        if Rec."No. of Tests Executed" > 0 then
            this.AvgTimeDuration := Rec."Total Duration (ms)" div Rec."No. of Tests Executed"
        else
            this.AvgTimeDuration := 0;
    end;
}