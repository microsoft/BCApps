// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

page 149035 "AIT Test Method Lines Compare"
{
    Caption = 'AI Test Method Lines Compare';
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "AIT Test Method Line";
    ModifyAllowed = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group("Version Configuration")
            {
                Caption = 'Version Configuration';

                field(Version; Version)
                {
                    Caption = 'Version';
                    ToolTip = 'Specifies the base version to compare with.';

                    trigger OnValidate()
                    begin
                        UpdateVersionFilter();
                    end;
                }
                field(BaseVersion; BaseVersion)
                {
                    Caption = 'Base Version';
                    ToolTip = 'Specifies the base version to compare to.';

                    trigger OnValidate()
                    begin
                        UpdateVersionFilter();
                    end;
                }
            }

            group("Version Comparison")
            {
                Caption = 'Version Comparison';
                grid(Summary)
                {
                    group("Summary Captions")
                    {
                        ShowCaption = false;
                        label(NoOfTests)
                        {
                            Caption = 'Number of Tests';
                            ToolTip = 'Specifies the number of tests in this Line';
                        }
                        label(NoOfTestsPassed)
                        {
                            Caption = 'Number of Tests Passed';
                            ToolTip = 'Specifies the number of tests passed in the version.';
                        }
                        label(NoOfTestsFailed)
                        {
                            Caption = 'Number of Tests Failed';
                            ToolTip = 'Specifies the number of tests that failed in the version.';
                        }
                        label(TotalDuration)
                        {
                            Caption = 'Total Duration (ms)';
                            ToolTip = 'Specifies Total Duration of the test for given version.';
                        }
                    }
                    group("Latest Version")
                    {
                        Caption = 'Latest Version';
                        field("No. of Tests Executed"; Rec."No. of Tests Executed")
                        {
                            ShowCaption = false;
                        }
                        field("No. of Tests Passed"; Rec."No. of Tests Passed")
                        {
                            Style = Favorable;
                            ShowCaption = false;
                        }
                        field("No. of Tests Failed"; Rec."No. of Tests Executed" - Rec."No. of Tests Passed")
                        {
                            Editable = false;
                            Caption = 'Number of Tests Failed';
                            ToolTip = 'Specifies the number of tests that failed in the current version.';
                            ShowCaption = false;
                            Style = Unfavorable;

                            trigger OnDrillDown()
                            var
                                AITLogEntry: Codeunit "AIT Log Entry";
                            begin
                                AITLogEntry.DrillDownFailedAITLogEntries(Rec."Test Suite Code", Rec."Line No.", Version);
                            end;
                        }
                        field(Duration; Rec."Total Duration (ms)")
                        {
                            ToolTip = 'Specifies Total Duration of the tests for this version.';
                            ShowCaption = false;
                        }
                    }
                    group("Base Version")
                    {
                        Caption = 'Base Version';
                        field("No. of Tests Executed - Base"; Rec."No. of Tests Executed - Base")
                        {
                            ToolTip = 'Specifies the number of tests in this Line for the base version.';
                            ShowCaption = false;
                        }
                        field("No. of Tests Passed - Base"; Rec."No. of Tests Passed - Base")
                        {
                            Style = Favorable;
                            ShowCaption = false;
                        }
                        field("No. of Tests Failed - Base"; Rec."No. of Tests Executed - Base" - Rec."No. of Tests Passed - Base")
                        {
                            Editable = false;
                            Caption = 'No. of Tests Failed - Base';
                            ToolTip = 'Specifies the number of tests that failed in the base version.';
                            Style = Unfavorable;
                            ShowCaption = false;

                            trigger OnDrillDown()
                            var
                                AITLogEntry: Codeunit "AIT Log Entry";
                            begin
                                AITLogEntry.DrillDownFailedAITLogEntries(Rec."Test Suite Code", Rec."Line No.", BaseVersion);
                            end;
                        }
                        field(DurationBase; Rec."Total Duration - Base (ms)")
                        {
                            ToolTip = 'Specifies Total Duration of the tests for the base version.';
                            Caption = 'Total Duration Base (ms)';
                            ShowCaption = false;
                        }
                    }
                }
            }
        }
    }

    var
        Version: Integer;
        BaseVersion: Integer;

    trigger OnOpenPage()
    begin
        UpdateVersionFilter();
    end;

    internal procedure SetVersion(VersionNo: Integer)
    begin
        Version := VersionNo;
    end;

    internal procedure SetBaseVersion(VersionNo: Integer)
    begin
        BaseVersion := VersionNo;
    end;

    local procedure UpdateVersionFilter()
    begin
        Rec.SetRange("Version Filter", Version);
        Rec.SetRange("Base Version Filter", BaseVersion);
        CurrPage.Update(false);
    end;
}