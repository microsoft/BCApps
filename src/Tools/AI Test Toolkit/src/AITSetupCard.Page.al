// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Environment;
using System.TestTools.TestRunner;

page 149031 "AIT Setup Card"
{
    Caption = 'AI Test Suite';
    PageType = Document;
    SourceTable = "AIT Header";
    Extensible = false;
    DataCaptionExpression = this.PageCaptionLbl + ' - ' + Rec."Code";

    layout
    {
        area(content)
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
                field(MinDelay; Rec."Default Min. User Delay (ms)")
                {
                    ToolTip = 'Specifies the fastest user input.';
                    ApplicationArea = All;
                }
                field(MaxDelay; Rec."Default Max. User Delay (ms)")
                {
                    ToolTip = 'Specifies the slowest user input.';
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
                        ToolTip = 'Specifies a version or scenario the test is being run for. The Tag will be transferred to the log entries and enables comparison between scenarios.';
                        ApplicationArea = All;
                    }
                }
            }
            part(AITLines; "AIT Lines")
            {
                ApplicationArea = All;
                Enabled = Rec.Status <> Rec.Status::Running;
                SubPageLink = "AIT Code" = field("Code"), "Version Filter" = field(Version), "Base Version Filter" = field("Base Version");
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
                        AITLogEntries: Record "AIT Log Entry";
                        AITLogEntry: Page "AIT Log Entries";
                    begin
                        AITLogEntries.SetFilterForFailedTestProcedures();
                        AITLogEntries.SetRange("AIT Code", Rec.Code);
                        AITLogEntries.SetRange(Version, Rec.Version);
                        AITLogEntry.SetTableView(AITLogEntries);
                        AITLogEntry.Run();
                    end;
                }
                field("No. of Operations"; Rec."No. of Operations")
                {
                    ApplicationArea = All;
                    Caption = 'No. of Operations';
                    ToolTip = 'Specifies the number of operations executed in the current version.';
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
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                ToolTip = 'Starts running the AIT Suite.';

                trigger OnAction()
                begin
                    CurrPage.Update(false);
                    Rec.Find();
                    if Rec."Input Dataset" = '' then
                        Error('Please specify a dataset before starting the suite.');
                    this.AITHeaderCU.ValidateDatasets(Rec);
                    this.AITStartTests.StartAITSuite(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(Stop)
            {
                Enabled = Rec.Status = Rec.Status::Running;
                ApplicationArea = All;
                Caption = 'Stop';
                Image = Stop;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                ToolTip = 'Stops the AIT Suite that is running.';

                trigger OnAction()
                var
                    AITLine: Record "AIT Line";
                    Window: Dialog;
                    MaxDateTime: DateTime;
                    SomethingWentWrongErr: Label 'It is taking longer to stop the run than expected. You can reopen the page later to check the status or you can invoke "Reset Status" action.';
                begin
                    CurrPage.Update(false);
                    Rec.Find();
                    if Rec.Status <> Rec.Status::Running then
                        exit;
                    Window.Open('Cancelling all sessions...');
                    MaxDateTime := CurrentDateTime() + (60000 * 5); // Wait for a max of 5 mins
                    this.AITStartTests.StopAITSuite(Rec);

                    AITLine.SetRange("AIT Code", Rec.Code);
                    AITLine.SetFilter(Status, '<> %1', AITLine.Status::Cancelled);
                    if not AITLine.IsEmpty then
                        repeat
                            Sleep(1000);
                            if CurrentDateTime > MaxDateTime then
                                Error(SomethingWentWrongErr);
                        until AITLine.IsEmpty;
                    Window.Close();

                    CurrPage.Update(false);
                    CurrPage.AITLines.Page.Refresh();
                end;
            }
            action(RefreshStatus)
            {
                ApplicationArea = All;
                Caption = 'Refresh';
                ToolTip = 'Refreshes the page.';
                Image = Refresh;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;

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
                    this.AITHeaderCU.ResetStatus(Rec);
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
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                ToolTip = 'Open log entries.';
                RunObject = page "AIT Log Entries";
                RunPageLink = "AIT Code" = field(Code), Version = field(Version);
            }
            action(Datasets)
            {
                ApplicationArea = All;
                Caption = 'Input Datasets';
                Image = DataEntry;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                ToolTip = 'Open input datasets.';
                RunObject = page "Test Input Groups";
            }
        }
    }

    var
        AITStartTests: Codeunit "AIT Start Tests";
        AITHeaderCU: Codeunit "AIT Header";
        EnableActions: Boolean;
        AvgTimeDuration: Duration;
        TotalDuration: Duration;
        PageCaptionLbl: Label 'AI Test';
        TestRunnerDisplayName: Text;

    trigger OnOpenPage()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        this.EnableActions := (EnvironmentInformation.IsSaas() and EnvironmentInformation.IsSandbox()) or EnvironmentInformation.IsOnPrem();
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
        this.TestRunnerDisplayName := TestSuiteMgt.GetTestRunnerDisplayName(Rec."Test Runner ID");
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