// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

page 149035 "AIT Lines Compare"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "AIT Line";
    ModifyAllowed = false;
    InsertAllowed = false;
    DeleteAllowed = false;

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
                    ToolTip = 'Specifies the Base version to compare with.';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        UpdateVersionFilter();
                    end;
                }
                field(BaseVersion; BaseVersion)
                {
                    Caption = 'Base Version';
                    ToolTip = 'Specifies the Base version to compare to.';
                    ApplicationArea = All;

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
                            Caption = 'No. of Tests';
                            Tooltip = 'Specifies the number of tests in this Line';
                            ApplicationArea = All;
                        }
                        label(NoOfTestsPassed)
                        {
                            Caption = 'No. of Tests Passed';
                            ToolTip = 'Specifies the number of tests passed in the version.';
                            ApplicationArea = All;
                        }
                        label(NoOfTestsFailed)
                        {
                            Caption = 'No. of Tests Failed';
                            ToolTip = 'Specifies the number of tests that failed in the version.';
                            ApplicationArea = All;
                        }
                        label(NoOfOperations)
                        {
                            Caption = 'No. of Operations';
                            ToolTip = 'Specifies the number of operations in the version.';
                            ApplicationArea = All;
                        }
                        label(TotalDuration)
                        {
                            Caption = 'Total Duration (ms)';
                            ToolTip = 'Specifies Total Duration of the AIT for this role for the version.';
                            ApplicationArea = All;
                        }
                    }
                    group("Latest Version")
                    {
                        field("No. of Tests"; Rec."No. of Tests")
                        {
                            Tooltip = 'Specifies the number of tests in this Line';
                            ApplicationArea = All;
                            ShowCaption = false;
                        }
                        field("No. of Tests Passed"; Rec."No. of Tests Passed")
                        {
                            ApplicationArea = All;
                            Style = Favorable;
                            ToolTip = 'Specifies the number of tests passed in the current Version.';
                            ShowCaption = false;
                        }
                        field("No. of Tests Failed"; Rec."No. of Tests" - Rec."No. of Tests Passed")
                        {
                            Editable = false;
                            ApplicationArea = All;
                            Caption = 'No. of Tests Failed';
                            ToolTip = 'Specifies the number of tests that failed in the current Version.';
                            ShowCaption = false;
                            Style = Unfavorable;

                            trigger OnDrillDown()
                            var
                                AITHeaderRec: Record "AIT Header";
                            begin
                                AITHeaderRec.SetLoadFields(Version);
                                AITHeaderRec.Get(Rec."AIT Code");
                                FailedTestsAITLogEntryDrillDown(AITHeaderRec.Version);
                            end;
                        }
                        field("No. of Operations"; Rec."No. of Operations")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Specifies the number of operations in the current Version.';
                            ShowCaption = false;
                        }
                        field(Duration; Rec."Total Duration (ms)")
                        {
                            ToolTip = 'Specifies Total Duration of the AIT for this role.';
                            ApplicationArea = All;
                            ShowCaption = false;
                        }
                    }
                    group("Base Version")
                    {
                        field("No. of Tests - Base"; Rec."No. of Tests - Base")
                        {
                            Tooltip = 'Specifies the number of tests in this Line for the base version.';
                            ApplicationArea = All;
                            ShowCaption = false;
                        }
                        field("No. of Tests Passed - Base"; Rec."No. of Tests Passed - Base")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Specifies the number of tests passed in the base Version.';
                            Style = Favorable;
                            ShowCaption = false;
                        }
                        field("No. of Tests Failed - Base"; Rec."No. of Tests - Base" - Rec."No. of Tests Passed - Base")
                        {
                            Editable = false;
                            ApplicationArea = All;
                            Caption = 'No. of Tests Failed - Base';
                            ToolTip = 'Specifies the number of tests that failed in the base Version.';
                            Style = Unfavorable;
                            ShowCaption = false;

                            trigger OnDrillDown()
                            var
                                AITHeaderRec: Record "AIT Header";
                            begin
                                AITHeaderRec.SetLoadFields("Base Version");
                                AITHeaderRec.Get(Rec."AIT Code");
                                FailedTestsAITLogEntryDrillDown(AITHeaderRec."Base Version");
                            end;
                        }
                        field("No. of Operations - Base"; Rec."No. of Operations - Base")
                        {
                            ApplicationArea = All;
                            ToolTip = 'Specifies the number of operations in the base Version.';
                            ShowCaption = false;
                        }
                        field(DurationBase; Rec."Total Duration - Base (ms)")
                        {
                            ToolTip = 'Specifies Total Duration of the AIT for this role for the base version.';
                            Caption = 'Total Duration Base (ms)';
                            ApplicationArea = All;
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

    local procedure FailedTestsAITLogEntryDrillDown(VersionNo: Integer) // TODO: Move to codeunit
    var
        AITLogEntries: Record "AIT Log Entry";
        AITLogEntry: Page "AIT Log Entries";
    begin
        AITLogEntries.SetFilterForFailedTestProcedures();
        AITLogEntries.SetRange("AIT Code", Rec."AIT Code");
        AITLogEntries.SetRange(Version, VersionNo);
        AITLogEntries.SetRange("AIT Line No.", Rec."Line No.");
        AITLogEntry.SetTableView(AITLogEntries);
        AITLogEntry.Run();
    end;
}