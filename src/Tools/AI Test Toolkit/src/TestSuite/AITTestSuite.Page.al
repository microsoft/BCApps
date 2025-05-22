// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Telemetry;
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

                    trigger OnValidate()
                    var
                        AITTestMethodLine: Record "AIT Test Method Line";
                    begin
                        if Rec."Input Dataset" = xRec."Input Dataset" then
                            exit;

                        AITTestMethodLine.SetRange("Test Suite Code", Rec.Code);

                        if AITTestMethodLine.IsEmpty() then
                            exit;

                        if GuiAllowed() then
                            if not Dialog.Confirm(InputDatasetChangedQst) then
                                exit;

                        AITTestMethodLine.ModifyAll("Input Dataset", Rec."Input Dataset", true);
                    end;
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
                field(Accuracy; Rec.Accuracy)
                {
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
                field("Tokens Consumed"; Rec."Tokens Consumed")
                {
                }
                field("Average Tokens Consumed"; AvgTokensConsumed)
                {
                    Editable = false;
                    Caption = 'Average Tokens Consumed';
                    ToolTip = 'Specifies the average number of tokens consumed by the tests in the last run.';
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
                Enabled = Rec.Status <> Rec.Status::Running;
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
            action(StartBatch)
            {
                Enabled = Rec.Status <> Rec.Status::Running;
                Caption = 'Start Batch';
                Image = ExecuteBatch;
                ToolTip = 'Starts running the AI Test Suite, the specified number of times.';

                trigger OnAction()
                var
                    AITBatchRunDialog: Page "AIT Batch Run Dialog";
                    Iterations: Integer;
                begin
                    CurrPage.Update(false);

                    AITBatchRunDialog.LookupMode := true;
                    if AITBatchRunDialog.RunModal() <> ACTION::LookupOK then
                        exit;

                    Iterations := AITBatchRunDialog.GetNumberOfIterations();
                    AITTestSuiteMgt.StartAITSuite(Iterations, Rec);

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
                Visible = Rec.Status = Rec.Status::Running;
                Caption = 'Cancel';
                ToolTip = 'Cancels the run and marks the run as Cancelled.';
                Image = Cancel;

                trigger OnAction()
                begin
                    AITTestSuiteMgt.CancelRun(Rec);
                end;
            }

            action(Compare)
            {
                Caption = 'View Runs';
                Image = History;
                ToolTip = 'View the run history of the suite.';
                Scope = Repeater;

                trigger OnAction()
                var
                    AITRunHistory: Page "AIT Run History";
                begin
                    AITRunHistory.SetTestSuite(Rec.Code);
                    AITRunHistory.Run();
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
            action("Download Test Summary")
            {
                Caption = 'Download Test Summary';
                Image = Export;
                ToolTip = 'Downloads a summary of the test results.';

                trigger OnAction()
                var
                    AITLogEntry: Record "AIT Log Entry";
                    AITTestSuiteMgt: Codeunit "AIT Test Suite Mgt.";
                begin
                    AITLogEntry.SetRange(Version, Rec.Version);
                    AITTestSuiteMgt.DownloadTestSummary(AITLogEntry);
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
                actionref(ResetStatus_Promoted; ResetStatus)
                {
                }
                actionref(Start_Promoted; Start)
                {
                }
                actionref(StartBatch_Promoted; StartBatch)
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
        AvgTimeDuration: Duration;
        AvgTokensConsumed: Integer;
        TotalDuration: Duration;
        PageCaptionLbl: Label 'AI Test';
        TestRunnerDisplayName: Text;
        InputDatasetChangedQst: Label 'You have modified the input dataset.\\Do you want to update the lines?';

    trigger OnOpenPage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000NEV', AITTestSuiteMgt.GetFeatureName(), Enum::"Feature Uptake Status"::Discovered);
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
        UpdateAverages();
        TestRunnerDisplayName := TestSuiteMgt.GetTestRunnerDisplayName(Rec."Test Runner Id");
    end;

    local procedure UpdateTotalDuration()
    begin
        Rec.CalcFields("Total Duration (ms)");
        TotalDuration := Rec."Total Duration (ms)";
    end;

    local procedure UpdateAverages()
    begin
        Rec.CalcFields("No. of Tests Executed", "Total Duration (ms)", "Tokens Consumed");
        if Rec."No. of Tests Executed" > 0 then
            AvgTimeDuration := Rec."Total Duration (ms)" div Rec."No. of Tests Executed"
        else
            AvgTimeDuration := 0;

        if Rec."No. of Tests Executed" > 0 then
            AvgTokensConsumed := Rec."Tokens Consumed" div Rec."No. of Tests Executed"
        else
            AvgTokensConsumed := 0;
    end;
}