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
                field(Tag; Rec.Tag)
                {
                    ToolTip = 'Specifies a version or scenario the test is being run for. The Tag will be transferred to the log entries and enables comparison between scenarios.';
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
                field(Version; Rec.Version)
                {
                    ToolTip = 'Specifies the current version of the test run. Log entries will get this version no.';
                    ApplicationArea = All;
                    Editable = false;
                }
                field(BaseVersion; Rec."Base Version")
                {
                    ToolTip = 'Specifies the Base version of the test run. Used for comparisons in the lines.';
                    ApplicationArea = All;
                }
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
            }
            part(BCCTLines; "BCCT Lines")
            {
                ApplicationArea = All;
                Enabled = Rec.Status <> Rec.Status::Running;
                SubPageLink = "BCCT Code" = field("Code"), "Version Filter" = field(Version), "Base Version Filter" = field("Base Version");
                UpdatePropagation = Both;
            }
            group(LastRunSummary)
            {
                Caption = 'Last Run Summary';
                field("No. of Tests Executed"; Rec."No. of Tests Executed")
                {
                    Editable = false;
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of tests executed in the current version.';
                }
                field("No. of Tests Passed"; Rec."No. of Tests Passed") // TODO: this should be filtered on not empty output
                {
                    Editable = false;
                    ToolTip = 'Specifies the number of tests that passed in the current Version.';
                    ApplicationArea = All;
                    Style = Favorable;
                    DrillDownPageId = "BCCT Log Entries";
                }
                field("No. of Tests Failed"; Rec."No. of Tests Executed" - Rec."No. of Tests Passed")
                {
                    Editable = false;
                    ApplicationArea = All;
                    Caption = 'No. of Tests Failed';
                    ToolTip = 'Specifies the number of tests that failed in the current Version.';
                    Style = Unfavorable;

                    trigger OnDrillDown()
                    var
                        BCCTLogEntries: Record "BCCT Log Entry";
                        BCCTRoleWrapper: Codeunit "BCCT Role Wrapper";
                        BCCTLogEntry: Page "BCCT Log Entries";
                    begin
                        BCCTLogEntries.SetRange("BCCT Code", Rec.Code);
                        BCCTLogEntries.SetRange(Version, Rec.Version);
                        BCCTLogEntries.SetRange(Operation, BCCTRoleWrapper.GetDefaultExecuteProcedureOperationLbl());
                        BCCTLogEntries.SetFilter("Procedure Name", '<> %1', '');
                        BCCTLogEntries.SetRange(Status, BCCTLogEntries.Status::Error);
                        BCCTLogEntry.SetTableView(BCCTLogEntries);
                        BCCTLogEntry.Run();
                    end;
                }
                field("No. of Operations"; Rec."No. of Operations")
                {
                    ToolTip = 'Specifies the number of operations executed in the current version.';
                    ApplicationArea = All;
                }

                field("Total Duration (ms)"; Rec."Total Duration (ms)")
                {
                    ToolTip = 'Specifies the total time (ms) taken by the tests in the last run.';
                    ApplicationArea = All;
                }
                field("Average Duration (ms)"; AvgTime)
                {
                    Editable = false;
                    ApplicationArea = All;
                    Caption = 'Average Test Duration (ms)';
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
    end;

    local procedure UpdateAverageExecutionTime()
    begin
        Rec.CalcFields("No. of Tests Executed", "Total Duration (ms)");
        if Rec."No. of Tests Executed" > 0 then
            AvgTime := Rec."Total Duration (ms)" / Rec."No. of Tests Executed"
        else
            AvgTime := 0;
    end;
}