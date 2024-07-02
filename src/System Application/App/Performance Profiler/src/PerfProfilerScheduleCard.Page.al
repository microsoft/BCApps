// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.PerformanceProfile;
using System.Security.AccessControl;
using System.DataAdministration;

/// <summary>
/// Card page for schedule based sampling profilers
/// </summary>
page 1932 "Perf. Profiler Schedule Card"
{
    Caption = 'Profiler Schedule';
    PageType = Card;
    AboutTitle = 'About performance profiler schedules';
    AboutText = 'View and modify a specific profiler schedule.';
    DataCaptionExpression = Rec.Description;
    SourceTable = "Performance Profile Scheduler";
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';
                AboutText = 'General information about the profiler schedule.';
                AboutTitle = 'General information';

                field("Schedule ID"; Rec."Schedule ID")
                {
                    ApplicationArea = All;
                    Caption = 'Schedule ID';
                    ToolTip = 'Specifies the ID of the schedule.';
                    AboutText = 'The ID of the schedule.';
                    Editable = false;
                    Visible = false;
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    Caption = 'Enabled';
                    ToolTip = 'Specifies whether the schedule is enabled.';
                    AboutText = 'Specifies whether the schedule is enabled.';
                }
                field("Start Time"; Rec."Starting Date-Time")
                {
                    ApplicationArea = All;
                    Caption = 'Start Time';
                    ToolTip = 'Specifies the start time of the schedule.';
                    AboutText = 'The start time of the schedule.';

                    trigger OnValidate()
                    begin
                        ScheduledPerfProfiler.ValidatePerformanceProfileSchedulerDates(Rec, MaxRetentionPeriod);
                    end;
                }
                field("End Time"; Rec."Ending Date-Time")
                {
                    ApplicationArea = All;
                    Caption = 'End Time';
                    ToolTip = 'Specifies the end time of the schedule.';
                    AboutText = 'The end time of the schedule.';

                    trigger OnValidate()
                    begin
                        ScheduledPerfProfiler.ValidatePerformanceProfileSchedulerDates(Rec, MaxRetentionPeriod);
                        ScheduledPerfProfiler.ValidatePerformanceProfileEndTime(Rec);
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the schedule.';
                    AboutText = 'The description of the schedule.';
                }
            }

            group(Filtering)
            {
                Caption = 'Filtering Criteria';
                AboutText = 'Filtering criteria for the profiler schedule.';

                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = All;
                    Caption = 'User ID';
                    ToolTip = 'Specifies the ID of the user who created the schedule.';
                    AboutText = 'The ID of the user who created the schedule.';
                    TableRelation = User."User Security ID";
                    Lookup = true;
                }
                field(Activity; Activity)
                {
                    ApplicationArea = All;
                    Caption = 'Activity Type';
                    ToolTip = 'Specifies the type of activity for which the schedule is created.';
                    AboutText = 'The type of activity for which the schedule is created.';

                    trigger OnValidate()
                    begin
                        ScheduledPerfProfiler.MapActivityTypeToRecord(Rec, Activity);
                    end;
                }
            }
            group(Advanced)
            {
                Caption = 'Advanced Settings';
                AboutText = 'Advanced settings for the profiler schedule.';

                field(Frequency; Rec.Frequency)
                {
                    ApplicationArea = All;
                    Caption = 'Sampling Frequency';
                    ToolTip = 'Specifies the frequency at which the profiler will sample data.';
                    AboutText = 'The frequency at which the profiler will sample data.';
                }
                field("Retention Policy"; RetentionPeriod)
                {
                    ApplicationArea = All;
                    Caption = 'Retention Period';
                    ToolTip = 'Specifies the retention period of the profile.';
                    AboutText = 'The retention period the profile will be kept.';
                    Editable = false;

                    trigger OnDrillDown()
                    var
                        RetentionPolicySetup: Record "Retention Policy Setup";
                        NoRetentionPolicyErrorInfo: ErrorInfo;
                    begin
                        if RetentionPolicySetup.Get(Database::"Performance Profiles") then
                            Page.Run(Page::"Retention Policy Setup Card", RetentionPolicySetup)
                        else begin
                            NoRetentionPolicyErrorInfo.Message := NoRetentionPolicySetupErr;
                            NoRetentionPolicyErrorInfo.AddAction(CreateRetentionPolicySetupTxt, Codeunit::"Scheduled Perf. Profiler Impl.", 'CreateRetentionPolicySetup');
                            Error(NoRetentionPolicyErrorInfo);
                        end;
                    end;
                }
                field("Profile Creation Threshold"; Rec."Profile Creation Threshold")
                {
                    ApplicationArea = All;
                    Caption = 'Profile Creation Threshold (ms)';
                    ToolTip = 'Specifies Create only profiles that are greater then the profile creation threshold';
                    AboutText = 'Limit the amount of sampling profiles that are created by setting a millisecond threshold. Only profiles larger then the threshold will be created.';

                    trigger OnValidate()
                    begin
                        ScheduledPerfProfiler.ValidateThreshold(Rec);
                    end;
                }
            }
        }
    }

    actions
    {
        area(Promoted)
        {
            actionref(OpenProfiles; "Open Profiles")
            {
            }
        }

        area(Navigation)
        {
            action("Open Profiles")
            {
                ApplicationArea = All;
                Image = Setup;
                Caption = 'Open Profiles';
                ToolTip = 'Open profiles for the scheduled session';
                RunObject = page "Performance Profile List";
                RunPageLink = "Schedule ID" = field("Schedule ID");
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ScheduledPerfProfiler.InitializeFields(Rec, Activity);
    end;

    trigger OnOpenPage()
    begin
        ScheduledPerfProfiler.MapRecordToActivityType(Rec, Activity);
        MaxRetentionPeriod := 1000 * 60 * 60 * 24 * 7; // 1 week
    end;

    trigger OnAfterGetCurrRecord()
    begin
        ScheduledPerfProfiler.MapActivityTypeToRecord(Rec, Activity);
        RetentionPeriod := ScheduledPerfProfiler.GetRetentionPeriod();
    end;

    trigger OnModifyRecord(): Boolean
    begin
        ScheduledPerfProfiler.MapActivityTypeToRecord(Rec, Activity);
        ScheduledPerfProfiler.ValidatePerformanceProfileSchedulerRecord(Rec, Activity);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        ScheduledPerfProfiler.ValidatePerformanceProfileSchedulerRecord(Rec, Activity);
    end;

    var
        ScheduledPerfProfiler: Codeunit "Scheduled Perf. Profiler";
        Activity: Enum "Perf. Profile Activity Type";
        RetentionPeriod: Code[20];
        MaxRetentionPeriod: Duration;
        NoRetentionPolicySetupErr: Label 'No retention policy setup found for the performance profiles table.';
        CreateRetentionPolicySetupTxt: Label 'Create a retention policy setup';
}