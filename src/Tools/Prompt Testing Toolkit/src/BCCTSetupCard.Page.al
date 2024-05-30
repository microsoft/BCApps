// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.Environment;

page 149031 "BCCT Setup Card"
{
    Caption = 'BC Copilot Test Suite';
    PageType = Document;
    SourceTable = "BCCT Header";
    Extensible = false;
    DataCaptionExpression = PageCaptionLbl + ' - ' + Rec."Code";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'BC Copilot Test Suite';
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
                field(Dataset; Rec.Dataset)
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
                field("Test Runner Id"; "Test Runner Id")
                {
                    ToolTip = 'Specifies the Test Runner to be used by the tests.';
                    ApplicationArea = All;
                    Editable = false;
                    trigger OnAssistEdit()
                    var
                        AITALTestSuiteMgt: Codeunit "AITT AL Test Suite Mgt";
                    begin
                        AITALTestSuiteMgt.AssistEditTestRunner(Rec);
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
                    field(BaseVersion; Rec."Base Version")
                    {
                        ToolTip = 'Specifies the Base version of the test run. Used for comparisons in the lines.';
                        ApplicationArea = All;

                        trigger OnValidate()
                        begin
                            UpdateAverageExecutionTimeBase();
                        end;
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
            part(BCCTLines; "BCCT Lines")
            {
                ApplicationArea = All;
                Enabled = Rec.Status <> Rec.Status::Running;
                SubPageLink = "BCCT Code" = field("Code"), "Version Filter" = field(Version), "Base Version Filter" = field("Base Version");
                UpdatePropagation = Both;
            }
            group("Latest Run")
            {
                Caption = 'Latest Run';

                grid(Summary)
                {
                    group("Summary Captions")
                    {
                        ShowCaption = false;
                        label(NoOfTests)
                        {
                            Caption = 'No. of Tests';
                            ApplicationArea = All;
                        }
                        label(NoOfTestsPassed)
                        {
                            Caption = 'No. of Tests Passed';
                            ApplicationArea = All;
                        }
                        label(NoOfTestsFailed)
                        {
                            Caption = 'No. of Tests Failed';
                            ApplicationArea = All;
                        }
                        label(NoOfOperations)
                        {
                            Caption = 'No. of Operations';
                            ApplicationArea = All;
                        }
                        label(TotalDuration)
                        {
                            Caption = 'Total Duration (ms)';
                            ApplicationArea = All;
                        }
                        label(AvgDuration)
                        {
                            Caption = 'Average Duration (ms)';
                            ApplicationArea = All;
                        }
                    }
                    group("Latest Version")
                    {
                        field("No. of Tests Executed"; Rec."No. of Tests Executed")
                        {
                            Editable = false;
                            ApplicationArea = All;
                            ShowCaption = false;
                        }
                        field("No. of Tests Passed"; Rec."No. of Tests Passed") // TODO: this should be filtered on not empty output
                        {
                            Editable = false;
                            ApplicationArea = All;
                            Style = Favorable;
                            ShowCaption = false;
                        }
                        field("No. of Tests Failed"; Rec."No. of Tests Executed" - Rec."No. of Tests Passed")
                        {
                            Editable = false;
                            ApplicationArea = All;
                            Style = Unfavorable;
                            ShowCaption = false;

                            trigger OnDrillDown()
                            var
                                BCCTLogEntries: Record "BCCT Log Entry";
                                BCCTLogEntry: Page "BCCT Log Entries";
                            begin
                                BCCTLogEntries.SetFilterForFailedTestProcedures();
                                BCCTLogEntries.SetRange("BCCT Code", Rec.Code);
                                BCCTLogEntries.SetRange(Version, Rec.Version);
                                BCCTLogEntry.SetTableView(BCCTLogEntries);
                                BCCTLogEntry.Run();
                            end;
                        }
                        field("No. of Operations"; Rec."No. of Operations")
                        {
                            ApplicationArea = All;
                            ShowCaption = false;
                        }

                        field("Total Duration (ms)"; Rec."Total Duration (ms)")
                        {
                            ApplicationArea = All;
                            ShowCaption = false;
                        }
                        field("Average Duration (ms)"; AvgTime)
                        {
                            Editable = false;
                            ApplicationArea = All;
                            ToolTip = 'Specifies the average time (ms) taken by the tests in the last run.';
                            ShowCaption = false;
                        }

                    }
                    group("Base Version")
                    {
                        field("No. of Tests Executed - Base"; Rec."No. of Tests Executed - Base")
                        {
                            Editable = false;
                            ApplicationArea = All;
                            ShowCaption = false;
                        }
                        field("No. of Tests Passed - Base"; Rec."No. of Tests Passed - Base") // TODO: this should be filtered on not empty output
                        {
                            Editable = false;
                            ApplicationArea = All;
                            Style = Favorable;
                            ShowCaption = false;
                        }
                        field("No. of Tests Failed - Base"; Rec."No. of Tests Executed - Base" - Rec."No. of Tests Passed - Base")
                        {
                            Editable = false;
                            ApplicationArea = All;
                            ToolTip = 'Specifies the number of tests that failed in the current Version.';
                            Style = Unfavorable;
                            ShowCaption = false;

                            trigger OnDrillDown()
                            var
                                BCCTLogEntries: Record "BCCT Log Entry";
                                BCCTLogEntry: Page "BCCT Log Entries";
                            begin
                                BCCTLogEntries.SetFilterForFailedTestProcedures();
                                BCCTLogEntries.SetRange("BCCT Code", Rec.Code);
                                BCCTLogEntries.SetRange(Version, Rec."Base Version");
                                BCCTLogEntry.SetTableView(BCCTLogEntries);
                                BCCTLogEntry.Run();
                            end;
                        }
                        field("No. of Operations - Base"; Rec."No. of Operations - Base")
                        {
                            ApplicationArea = All;
                            ShowCaption = false;
                        }

                        field("Total Duration (ms) - Base"; Rec."Total Duration (ms) - Base")
                        {
                            ApplicationArea = All;
                            ShowCaption = false;
                        }
                        field("Average Duration (ms) - Base"; AvgTimeBase)
                        {
                            Editable = false;
                            ApplicationArea = All;
                            ToolTip = 'Specifies the average time (ms) taken by the tests in the last run.';
                            ShowCaption = false;
                        }

                    }
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
                ApplicationArea = All;
                Caption = 'Start';
                Image = Start;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                ToolTip = 'Starts running the BCCT Suite.';

                trigger OnAction()
                begin
                    CurrPage.Update(false);
                    Rec.Find();
                    if Rec.Dataset = '' then
                        Error('Please specify a dataset before starting the suite.');
                    BCCTHeaderCU.ValidateDatasets(Rec);
                    BCCTStartTests.StartBCCTSuite(Rec);
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
                ToolTip = 'Stops the BCCT Suite that is running.';

                trigger OnAction()
                var
                    BCCTLine: Record "BCCT Line";
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
                    BCCTStartTests.StopBCCTSuite(Rec);

                    BCCTLine.SetRange("BCCT Code", Rec.Code);
                    BCCTLine.SetFilter(Status, '<> %1', BCCTLine.Status::Cancelled);
                    if not BCCTLine.IsEmpty then
                        repeat
                            Sleep(1000);
                            if CurrentDateTime > MaxDateTime then
                                Error(SomethingWentWrongErr);
                        until BCCTLine.IsEmpty;
                    Window.Close();

                    CurrPage.Update(false);
                    CurrPage.BCCTLines.Page.Refresh();
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
                    BCCTHeaderCU.ResetStatus(Rec);
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
                RunObject = page "BCCT Log Entries";
                RunPageLink = "BCCT Code" = field(Code), Version = field(Version);
            }
            action(Datasets)
            {
                ApplicationArea = All;
                Caption = 'Datasets';
                Image = DataEntry;
                Promoted = true;
                PromotedOnly = true;
                PromotedCategory = Process;
                ToolTip = 'Open datasets.';
                RunObject = page "BCCT Datasets";
            }
        }
    }

    var
        BCCTStartTests: Codeunit "BCCT Start Tests";
        BCCTHeaderCU: Codeunit "BCCT Header";
        EnableActions: Boolean;
        AvgTime: Decimal;
        AvgTimeBase: Decimal;
        PageCaptionLbl: Label 'BC Copilot Test';

    trigger OnOpenPage()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        EnableActions := (EnvironmentInformation.IsSaas() and EnvironmentInformation.IsSandbox()) or EnvironmentInformation.IsOnPrem();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateAverageExecutionTime();
        UpdateAverageExecutionTimeBase();
    end;

    local procedure UpdateAverageExecutionTime()
    begin
        Rec.CalcFields("No. of Tests Executed", "Total Duration (ms)", "No. of Tests Executed - Base", "Total Duration (ms) - Base");
        if Rec."No. of Tests Executed" > 0 then
            AvgTime := Rec."Total Duration (ms)" / Rec."No. of Tests Executed"
        else
            AvgTime := 0;
    end;

    local procedure UpdateAverageExecutionTimeBase()
    begin
        Rec.CalcFields("No. of Tests Executed - Base", "Total Duration (ms) - Base");
        if Rec."No. of Tests Executed - Base" > 0 then
            AvgTimeBase := Rec."Total Duration (ms) - Base" / Rec."No. of Tests Executed - Base"
        else
            AvgTimeBase := 0;
    end;
}