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
    InsertAllowed = false;
    DeleteAllowed = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group("Version Configuration")
            {
                Caption = 'General';

                field(Version; Rec.Version)
                {
                    Editable = false;
                    Caption = 'Latest Version';
                    ToolTip = 'Specifies the latest version.';
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

                field(ApplyFilter; ApplyFilter)
                {
                    Caption = 'Apply Filter';
                    ToolTip = 'Specifies whether to filter results to a specific line or see results of the suite as a whole.';

                    trigger OnValidate()
                    begin
                        UpdateLineFilter();
                    end;
                }
            }
            group("Line Filter")
            {
                Caption = 'Test Line Filter';
                Visible = ApplyFilter;

                field("Line No."; LineNo)
                {
                    Caption = 'Test Line';
                    ToolTip = 'Specifies the line to filter to.';
                    TableRelation = "AIT Test Method Line"."Line No." where("Test Suite Code" = field(Code));

                    trigger OnValidate()
                    begin
                        UpdateLineFilter();
                    end;
                }
            }

            group("Version Comparison")
            {
                Caption = 'Overview';

                grid(Summary)
                {
                    group("Latest Version")
                    {
                        Caption = 'Latest Version';
                        field(Tag; Rec.Tag)
                        {
                            Editable = false;
                            Caption = 'Tag';
                            ToolTip = 'Specifies the tag of the latest version.';
                        }
                        field("No. of Tests"; Rec."No. of Tests Executed")
                        {
                            Caption = 'No. of Tests';
                            ToolTip = 'Specifies the number of tests in the latest version.';
                        }
                        field("No. of Tests Passed"; Rec."No. of Tests Passed")
                        {
                            Caption = 'No. of Tests Passed';
                            ToolTip = 'Specifies the number of tests passed in the latest version.';
                            Style = Favorable;
                        }
                        field("No. of Tests Failed"; Rec."No. of Tests Executed" - Rec."No. of Tests Passed")
                        {
                            Editable = false;
                            Caption = 'No. of Tests Failed';
                            ToolTip = 'Specifies the number of tests that failed in the latest version.';
                            Style = Unfavorable;

                            trigger OnDrillDown()
                            var
                                AITLogEntryCU: Codeunit "AIT Log Entry";
                            begin
                                AITLogEntryCU.DrillDownFailedAITLogEntries(Rec.Code, LineNo, Rec.Version);
                            end;
                        }
                        field(Duration; Rec."Total Duration (ms)")
                        {
                            Caption = 'Total Duration (ms)';
                            ToolTip = 'Specifies Total Duration of the tests for the latest version.';
                        }
                    }
                    group("Base Version")
                    {
                        Caption = 'Base Version';

                        field("Tag - Base"; BaseTag)
                        {
                            Editable = false;
                            Caption = 'Tag';
                            ToolTip = 'Specifies the tag of the base version.';
                        }
                        field("No. of Tests - Base"; Rec."No. of Tests Executed - Base")
                        {
                            Caption = 'No. of Tests';
                            ToolTip = 'Specifies the number of tests in the base version.';
                        }
                        field("No. of Tests Passed - Base"; Rec."No. of Tests Passed - Base")
                        {
                            Caption = 'No. of Tests Passed';
                            ToolTip = 'Specifies the number of tests passed in the base version.';
                            Style = Favorable;
                        }
                        field("No. of Tests Failed - Base"; Rec."No. of Tests Executed - Base" - Rec."No. of Tests Passed - Base")
                        {
                            Editable = false;
                            Caption = 'No. of Tests Failed';
                            ToolTip = 'Specifies the number of tests that failed in the base version.';
                            Style = Unfavorable;

                            trigger OnDrillDown()
                            var
                                AITLogEntryCU: Codeunit "AIT Log Entry";
                            begin
                                AITLogEntryCU.DrillDownFailedAITLogEntries(Rec.Code, LineNo, BaseVersion);
                            end;
                        }
                        field(DurationBase; Rec."Total Duration (ms) - Base")
                        {
                            Caption = 'Total Duration (ms)';
                            ToolTip = 'Specifies Total Duration of the tests for the base version.';
                        }
                    }
                }
            }


            group("Failed Tests")
            {
                Caption = 'Failed Tests';

                grid("Failed Tests Grid")
                {
                    group("Log Entries")
                    {
                        ShowCaption = false;

                        part("Log Entries- Latest"; "AIT Log Entries Part")
                        {
                            Caption = 'Failed Tests - Latest Version';
                            SubPageLink = "Test Suite Code" = field(Code), Version = field(Version), "Test Method Line No." = field("Line No. Filter");
                            UpdatePropagation = Both;
                        }

                        part("Log Entries - Base"; "AIT Log Entries Part")
                        {
                            Caption = 'Failed Tests - Base Version';
                            SubPageLink = "Test Suite Code" = field(Code), Version = field("Base Version Filter"), "Test Method Line No." = field("Line No. Filter");
                            UpdatePropagation = Both;
                        }
                    }
                }
            }
        }
    }

    var
        AITTestMethodLine: Record "AIT Test Method Line";
        LineNo: Integer;
        BaseVersion: Integer;
        ApplyFilter: Boolean;
        BaseTag: Text[20];

    trigger OnOpenPage()
    begin
        BaseVersion := Rec.Version - 1;
        UpdateVersionFilter();
    end;

    internal procedure FilterToLine(Line: Integer)
    begin
        ApplyFilter := true;
        LineNo := Line;
        UpdateLineFilter();
    end;

    local procedure UpdateLineFilter()
    begin
        if AITTestMethodLine.Get(Rec.Code, LineNo) and ApplyFilter then
            Rec.SetRange("Line No. Filter", LineNo)
        else
            Rec.SetRange("Line No. Filter");

        CurrPage.Update();
    end;

    local procedure UpdateVersionFilter()
    var
        AITLogEntry: Record "AIT Log Entry";
    begin
        Rec.SetRange("Base Version Filter", BaseVersion);

        AITLogEntry.SetRange("Test Suite Code", Rec.Code);
        AITLogEntry.SetRange(Version, BaseVersion);

        if AITLogEntry.FindFirst() then
            BaseTag := AITLogEntry.Tag
        else
            BaseTag := '';

        CurrPage.Update();
    end;
}