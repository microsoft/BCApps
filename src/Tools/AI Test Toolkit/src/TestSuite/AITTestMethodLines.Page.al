// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

page 149034 "AIT Test Method Lines"
{
    Caption = 'Tests';
    PageType = ListPart;
    SourceTable = "AIT Test Method Line";
    AutoSplitKey = true;
    DelayedInsert = true;
    Extensible = false;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                field("LoadTestCode"; Rec."Test Suite Code")
                {
                    ToolTip = 'Specifies the ID of the AIT.';
                    Visible = false;
                    ApplicationArea = All;
                }
                field(LineNo; Rec."Line No.")
                {
                    ToolTip = 'Specifies the line number of the AIT line.';
                    Visible = false;
                    ApplicationArea = All;
                }
                field(CodeunitID; Rec."Codeunit ID")
                {
                    ToolTip = 'Specifies the codeunit id to run.';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field(CodeunitName; Rec."Codeunit Name")
                {
                    ToolTip = 'Specifies the name of the codeunit.';
                    ApplicationArea = All;
                }
                field(InputDataset; Rec."Input Dataset")
                {
                    ToolTip = 'Specifies a dataset that overrides the default dataset for the suite.';
                    ApplicationArea = All;
                }
                field("Delay (ms btwn. iter.)"; Rec."Delay (ms btwn. iter.)")
                {
                    ToolTip = 'Specifies the delay between iterations.';
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the description of the AIT line.';
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ToolTip = 'Specifies the status of the AIT.';
                    ApplicationArea = All;
                }
                field(MinDelay; Rec."Min. User Delay (ms)")
                {
                    ToolTip = 'Specifies the min. user delay in ms of the AIT.';
                    ApplicationArea = All;
                    Visible = false;
                }
                field(MaxDelay; Rec."Max. User Delay (ms)")
                {
                    ToolTip = 'Specifies the max. user delay in ms of the AIT.';
                    ApplicationArea = All;
                    Visible = false;
                }
                field("No. of Tests"; Rec."No. of Tests")
                {
                    Tooltip = 'Specifies the number of tests in this Line';
                    ApplicationArea = All;
                }
                field("No. of Tests Passed"; Rec."No. of Tests Passed")
                {
                    ApplicationArea = All;
                    Style = Favorable;
                    ToolTip = 'Specifies the number of tests passed in the current Version.';
                }
                field("No. of Tests Failed"; Rec."No. of Tests" - Rec."No. of Tests Passed")
                {
                    Editable = false;
                    ApplicationArea = All;
                    Caption = 'No. of Tests Failed';
                    ToolTip = 'Specifies the number of tests that failed in the current Version.';
                    Style = Unfavorable;

                    trigger OnDrillDown()
                    var
                        AITTestSuite: Record "AIT Test Suite";
                        AITLogEntry: Codeunit "AIT Log Entry";
                    begin
                        AITTestSuite.SetLoadFields(Version);
                        AITTestSuite.Get(Rec."Test Suite Code");
                        AITLogEntry.DrillDownFailedAITLogEntries(Rec."Test Suite Code", Rec."Line No.", AITTestSuite.Version);
                    end;
                }
                field("No. of Operations"; Rec."No. of Operations")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of operations in the current Version.';
                    Visible = false;
                    Enabled = false;
                }
                field(Duration; Rec."Total Duration (ms)")
                {
                    ToolTip = 'Specifies Total Duration of the AIT for this role.';
                    ApplicationArea = All;
                }
                field(AvgDuration; AITTestSuiteMgt.GetAvgDuration(Rec))
                {
                    ToolTip = 'Specifies average duration of the AIT for this role.';
                    Caption = 'Average Duration (ms)';
                    ApplicationArea = All;
                    Visible = false;
                }
                field("No. of Tests - Base"; Rec."No. of Tests - Base")
                {
                    Tooltip = 'Specifies the number of tests in this Line for the base version.';
                    ApplicationArea = All;
                    Visible = false;
                }
                field("No. of Tests Passed - Base"; Rec."No. of Tests Passed - Base")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of tests passed in the base Version.';
                    Style = Favorable;
                    Visible = false;
                }
                field("No. of Tests Failed - Base"; Rec."No. of Tests - Base" - Rec."No. of Tests Passed - Base")
                {
                    Editable = false;
                    ApplicationArea = All;
                    Caption = 'No. of Tests Failed - Base';
                    ToolTip = 'Specifies the number of tests that failed in the base Version.';
                    Style = Unfavorable;
                    Visible = false;

                    trigger OnDrillDown()
                    var
                        AITTestSuite: Record "AIT Test Suite";
                        AITLogEntry: Codeunit "AIT Log Entry";
                    begin
                        AITTestSuite.SetLoadFields("Base Version");
                        AITTestSuite.Get(Rec."Test Suite Code");
                        AITLogEntry.DrillDownFailedAITLogEntries(Rec."Test Suite Code", Rec."Line No.", AITTestSuite."Base Version");
                    end;
                }
                field("No. of Operations - Base"; Rec."No. of Operations - Base")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of operations in the base Version.';
                    Visible = false;
                    Enabled = false;
                }
                field(DurationBase; Rec."Total Duration - Base (ms)")
                {
                    ToolTip = 'Specifies Total Duration of the AIT for this role for the base version.';
                    Caption = 'Total Duration Base (ms)';
                    ApplicationArea = All;
                    Visible = false;
                }
                field(AvgDurationBase; GetAvg(Rec."No. of Tests - Base", Rec."Total Duration - Base (ms)"))
                {
                    ToolTip = 'Specifies average duration of the AIT for this role for the base version.';
                    Caption = 'Average Duration Base (ms)';
                    ApplicationArea = All;
                    Visible = false;
                }
                field(AvgDurationDeltaPct; GetDiffPct(GetAvg(Rec."No. of Tests - Base", Rec."Total Duration - Base (ms)"), GetAvg(Rec."No. of Tests", Rec."Total Duration (ms)")))
                {
                    ToolTip = 'Specifies difference in duration of the AIT for this role compared to the base version.';
                    Caption = 'Change in Duration (%)';
                    ApplicationArea = All;
                    Visible = false;
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action("Run Test")
            {
                ApplicationArea = All;
                Caption = 'Run Test';
                Image = Start;
                Tooltip = 'Starts running the AIT Line.';

                trigger OnAction()
                begin
                    AITTestSuite.Get(Rec."Test Suite Code");
                    AITTestSuite.Version += 1;
                    AITTestSuite.Modify();
                    Commit();
                    Rec.SetRange("Codeunit ID", Rec."Codeunit ID");
                    Codeunit.Run(codeunit::"AIT Test Runner", Rec);
                    Rec.SetRange("Codeunit ID"); // reset filter
                end;
            }
            action(LogEntries)
            {
                ApplicationArea = All;
                Caption = 'Log Entries';
                Image = Entries;
                ToolTip = 'Open log entries for the line.';
                RunObject = page "AIT Log Entries";
                RunPageLink = "Test Suite Code" = field("Test Suite Code"), "Test Method Line No." = field("Line No."), Version = field("Version Filter");
            }
            action(Compare)
            {
                ApplicationArea = All;
                Caption = 'Compare Versions';
                Image = CompareCOA;
                ToolTip = 'Compare results of the line to a base version.';
                Scope = Repeater;

                trigger OnAction()
                var
                    AITTestMethodLine: Record "AIT Test Method Line";
                    AITTestSuiteRec: Record "AIT Test Suite";
                    AITTestMethodLineComparePage: Page "AIT Test Method Lines Compare";
                begin
                    CurrPage.SetSelectionFilter(AITTestMethodLine);

                    if not AITTestMethodLine.FindFirst() then
                        Error(NoLineSelectedErr);

                    AITTestSuiteRec.SetLoadFields(Version);
                    AITTestSuiteRec.Get(Rec."Test Suite Code");

                    AITTestMethodLineComparePage.SetBaseVersion(AITTestSuiteRec.Version - 1);
                    AITTestMethodLineComparePage.SetVersion(AITTestSuiteRec.Version);
                    AITTestMethodLineComparePage.SetRecord(AITTestMethodLine);
                    AITTestMethodLineComparePage.Run();
                end;
            }
        }
    }

    var
        AITTestSuite: Record "AIT Test Suite";
        AITTestSuiteMgt: Codeunit "AIT Test Suite Mgt.";
        NoLineSelectedErr: Label 'Select a line to compare';

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Min. User Delay (ms)" := AITTestSuite."Default Min. User Delay (ms)";
        Rec."Max. User Delay (ms)" := AITTestSuite."Default Max. User Delay (ms)";
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if Rec."Test Suite Code" = '' then
            exit(true);
        if Rec."Test Suite Code" <> AITTestSuite.Code then
            if AITTestSuite.Get(Rec."Test Suite Code") then;
    end;

    local procedure GetAvg(NumIterations: Integer; TotalNo: Integer): Integer
    begin
        if NumIterations = 0 then
            exit(0);
        exit(TotalNo div NumIterations);
    end;

    local procedure GetDiffPct(BaseNo: Integer; No: Integer): Decimal
    begin
        if BaseNo = 0 then
            exit(0);
        exit(round((100 * (No - BaseNo)) / BaseNo, 0.1));
    end;

    internal procedure Refresh()
    begin
        CurrPage.Update(false);
        if Rec.Find() then;
    end;
}