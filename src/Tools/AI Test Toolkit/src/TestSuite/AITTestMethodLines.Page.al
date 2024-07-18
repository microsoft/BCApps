// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

page 149034 "AIT Test Method Lines"
{
    Caption = 'Tests';
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "AIT Test Method Line";
    AutoSplitKey = true;
    DelayedInsert = true;
    Extensible = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("LoadTestCode"; Rec."Test Suite Code")
                {
                    Visible = false;
                }
                field(LineNo; Rec."Line No.")
                {
                    Visible = false;
                }
                field(CodeunitID; Rec."Codeunit ID")
                {
                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field(CodeunitName; Rec."Codeunit Name")
                {
                }
                field(InputDataset; Rec."Input Dataset")
                {
                }
                field(Description; Rec.Description)
                {
                }
                field(Status; Rec.Status)
                {
                }
                field("No. of Tests"; Rec."No. of Tests")
                {
                }
                field("No. of Tests Passed"; Rec."No. of Tests Passed")
                {
                    Style = Favorable;
                }
                field("No. of Tests Failed"; Rec."No. of Tests" - Rec."No. of Tests Passed")
                {
                    Editable = false;
                    Caption = 'No. of Tests Failed';
                    ToolTip = 'Specifies the number of tests that failed in the current version.';
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
                    ToolTip = 'Specifies the number of operations in the current version.';
                    Visible = false;
                    Enabled = false;
                }
                field(Duration; Rec."Total Duration (ms)")
                {
                }
                field("Tokens Consumed"; Rec."Tokens Consumed")
                {
                }
                field(AvgDuration; AITTestSuiteMgt.GetAvgDuration(Rec))
                {
                    ToolTip = 'Specifies average duration of the AI Tests.';
                    Caption = 'Average Duration (ms)';
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
                Caption = 'Run Test';
                Image = Start;
                ToolTip = 'Starts running the AI Test Line.';

                trigger OnAction()
                begin
                    if Rec."Codeunit ID" = 0 then
                        exit;
                    AITTestSuiteMgt.RunAITestLine(Rec, true);
                end;
            }
            action(LogEntries)
            {
                Caption = 'Log Entries';
                Image = Entries;
                ToolTip = 'Open log entries for the line.';
                RunObject = page "AIT Log Entries";
                RunPageLink = "Test Suite Code" = field("Test Suite Code"), "Test Method Line No." = field("Line No."), Version = field("Version Filter");
            }
            action(Compare)
            {
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

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        if Rec."Test Suite Code" = '' then
            exit(true);
        if Rec."Test Suite Code" <> AITTestSuite.Code then
            if AITTestSuite.Get(Rec."Test Suite Code") then;
    end;
}