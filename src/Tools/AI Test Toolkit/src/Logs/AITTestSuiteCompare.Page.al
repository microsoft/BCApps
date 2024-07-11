// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

page 149036 "AIT Test Suite Compare"
{
    Caption = 'AI Test Suite Compare';
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "AIT Test Suite";
    SourceTableTemporary = true;
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

                field(Version; LatestVersion)
                {
                    Caption = 'Latest Version';
                    ToolTip = 'Specifies the latest version to compare with.';

                    trigger OnValidate()
                    begin
                        Rec.Version := LatestVersion;
                        CurrPage.Update();
                    end;
                }
                field(BaseVersion; BaseVersion)
                {
                    Caption = 'Base Version';
                    ToolTip = 'Specifies the Base version to compare to.';

                    trigger OnValidate()
                    begin
                        Rec."Base Version" := BaseVersion;
                        CurrPage.Update();
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
                            ToolTip = 'Specifies Total Duration of the tests for the version.';
                        }
                    }
                    group("Latest Version")
                    {
                        Caption = 'Latest Version';
                        field("No. of Tests"; Rec."No. of Tests Executed")
                        {
                            ToolTip = 'Specifies the number of tests in this line.';
                            ShowCaption = false;
                        }
                        field("No. of Tests Passed"; Rec."No. of Tests Passed")
                        {
                            Style = Favorable;
                            ToolTip = 'Specifies the number of tests passed in the current version.';
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
                                AITLogEntryCU: Codeunit "AIT Log Entry";
                            begin
                                AITLogEntryCU.DrillDownFailedAITLogEntries(Rec.Code, 0, Rec.Version);
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
                        field("No. of Tests - Base"; Rec."No. of Tests Executed - Base")
                        {
                            ToolTip = 'Specifies the number of tests in this Line for the base version.';
                            ShowCaption = false;
                        }
                        field("No. of Tests Passed - Base"; Rec."No. of Tests Passed - Base")
                        {
                            ToolTip = 'Specifies the number of tests passed in the base Version.';
                            Style = Favorable;
                            ShowCaption = false;
                        }
                        field("No. of Tests Failed - Base"; Rec."No. of Tests Executed - Base" - Rec."No. of Tests Passed - Base")
                        {
                            Editable = false;
                            Caption = 'Number of Tests Failed - Base';
                            ToolTip = 'Specifies the number of tests that failed in the base Version.';
                            Style = Unfavorable;
                            ShowCaption = false;

                            trigger OnDrillDown()
                            var
                                AITLogEntryCU: Codeunit "AIT Log Entry";
                            begin
                                AITLogEntryCU.DrillDownFailedAITLogEntries(Rec.Code, 0, Rec."Base Version");
                            end;
                        }
                        field(DurationBase; Rec."Total Duration (ms) - Base")
                        {
                            ToolTip = 'Specifies Total Duration of the tests for the version.';
                            Caption = 'Total Duration Base (ms)';
                            ShowCaption = false;
                        }
                    }
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrPage.Update();
    end;

    var
        LatestVersion: Integer;
        BaseVersion: Integer;

    internal procedure SetCompareVersions(Code: Code[10]; VersionNo: Integer; BaseVersionNo: Integer)
    begin
        LatestVersion := VersionNo;
        BaseVersion := BaseVersionNo;

        Rec.Code := Code;
        Rec.Version := VersionNo;
        Rec."Base Version" := BaseVersionNo;
    end;
}