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
                }
                field(Description; Rec.Description)
                {
                }
                field(Dataset; Rec."Input Dataset")
                {
                    ShowMandatory = true;
                    NotBlank = true;
                }
                field("Model Version"; Rec."Model Version")
                {
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
                    }
                    field(Started; Rec."Started at")
                    {
                    }
                    field(Version; Rec.Version)
                    {
                        Editable = false;
                    }
                    field(Tag; Rec.Tag)
                    {
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
                }
                field("No. of Tests Passed"; Rec."No. of Tests Passed")
                {
                    Style = Favorable;
                }
                field("No. of Tests Failed"; Rec."No. of Tests Executed" - Rec."No. of Tests Passed")
                {
                    Editable = false;
                    Style = Unfavorable;
                    Caption = 'No. of Tests Failed';
                    ToolTip = 'Specifies the number of tests failed for the test suite.';

                    trigger OnDrillDown()
                    var
                        AITLogEntry: Codeunit "AIT Log Entry";
                    begin
                        AITLogEntry.DrillDownFailedAITLogEntries(Rec.Code, 0, Rec.Version);
                    end;
                }
                field("No. of Operations"; Rec."No. of Operations")
                {
                    Visible = false;
                    Enabled = false;
                }
                field("Total Duration"; TotalDuration)
                {
                    Editable = false;
                    Caption = 'Total Duration';
                    ToolTip = 'Specifies the time taken for executing the tests in the test suite.';
                }
                field("Average Duration"; AvgTimeDuration)
                {
                    Editable = false;
                    Caption = 'Average Duration';
                    ToolTip = 'Specifies the average time taken by the tests in the test suite.';
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
            action(ExportAIT)
            {
                Caption = 'Export';
                Image = Export;
                Enabled = Rec.Code <> '';
                ToolTip = 'Exports the AI Test Suite configuration.';

                trigger OnAction()
                var
                    AITTestSuite: Record "AIT Test Suite";
                begin
                    if Rec.Code <> '' then begin
                        AITTestSuite := Rec;
                        AITTestSuite.SetRecFilter();
                        AITTestSuiteMgt.ExportAITTestSuite(AITTestSuite);
                    end;
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
                actionref(ExportAIT_Promoted; ExportAIT)
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