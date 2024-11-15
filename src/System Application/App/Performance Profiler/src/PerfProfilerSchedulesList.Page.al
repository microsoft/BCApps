// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.PerformanceProfile;

/// <summary>
/// List for schedule based sampling profilers
/// </summary>
page 1933 "Perf. Profiler Schedules List"
{
    Caption = 'Profiler Schedules';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    AboutTitle = 'About performance profile scheduling';
    AboutText = 'Schedule performance profiles to run at specific times based on different criteria to troubleshoot performance issues.';
    Editable = false;
    CardPageID = "Perf. Profiler Schedule Card";
    SourceTable = "Performance Profile Scheduler";
    Permissions = tabledata "Performance Profile Scheduler" = rimd;

    layout
    {
        area(Content)
        {
            group("Profiling Status")
            {
                AboutTitle = 'Profiling Status';
                AboutText = 'Specifies if profiling is enabled for the current user session.';
                Caption = 'Profiling Status';

                field("Active Schedule ID"; ActiveScheduleIdDisplayText)
                {
                    AboutText = 'The ID of the active schedule for the current session.';
                    Caption = 'Active Schedule ID';
                    Editable = false;
                    DrillDown = true;
                    ToolTip = 'Specifies the ID of the active schedule for the current session.';

                    trigger OnDrillDown()
                    var
                        PerformanceProfileScheduler: Record "Performance Profile Scheduler";
                        ScheduleCardPage: Page "Perf. Profiler Schedule Card";
                    begin
                        if IsNullGuid(ActiveScheduleId) then
                            exit;

                        if not PerformanceProfileScheduler.Get(ActiveScheduleId) then
                            exit;

                        ScheduleCardPage.SetRecord(PerformanceProfileScheduler);
                        ScheduleCardPage.Run();
                    end;
                }
            }

            repeater(ProfilerSchedules)
            {
                field(Description; Rec.Description)
                {
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the schedule.';
                    AboutText = 'The description of the schedule.';
                }
                field("Schedule ID"; Rec."Schedule ID")
                {
                    Caption = 'Schedule ID';
                    ToolTip = 'Specifies the ID of the schedule.';
                    AboutText = 'The ID of the schedule.';
                    Editable = false;
                }
                field(Enabled; Rec.Enabled)
                {
                    Caption = 'Enabled';
                    ToolTip = 'Specifies if the schedule is enabled.';
                    AboutText = 'Specifies if the schedule is enabled.';
                }
                field("Start Time"; Rec."Starting Date-Time")
                {
                    Caption = 'Start Time';
                    ToolTip = 'Specifies the time the schedule will start.';
                    AboutText = 'The time the schedule will start.';
                }
                field("End Time"; Rec."Ending Date-Time")
                {
                    Caption = 'End Time';
                    ToolTip = 'Specifies the time the schedule will end.';
                    AboutText = 'The time the schedule will end.';
                }
                field("User Name"; UserName)
                {
                    Caption = 'User Name';
                    ToolTip = 'Specifies the name of the user who created the schedule.';
                    AboutText = 'The name of the user who created the schedule.';
                }
                field(Activity; Activity)
                {
                    Caption = 'Activity Type';
                    ToolTip = 'Specifies the type of activity for which the schedule is created.';
                    AboutText = 'The type of activity for which the schedule is created.';
                }
                field(Frequency; Rec.Frequency)
                {
                    Caption = 'Sampling Frequency';
                    ToolTip = 'Specifies the frequency at which the profiler will sample data.';
                    AboutText = 'The frequency at which the profiler will sample data.';
                }
                field("Profile Creation Threshold"; Rec."Profile Creation Threshold")
                {
                    Caption = 'Profile Creation Threshold (ms)';
                    ToolTip = 'Specifies to create only profiles that are greater then the profile creation threshold';
                    AboutText = 'Limit the amount of sampling profiles that are created by setting a millisecond threshold. Only profiles larger then the threshold will be created.';
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
                ToolTip = 'Open the profiles for the schedule';
                RunObject = page "Performance Profile List";
                RunPageLink = "Schedule ID" = field("Schedule ID");
            }
        }
    }

    trigger OnOpenPage()
    begin
        ScheduledPerfProfiler.FilterUsers(Rec, UserSecurityId());
        ScheduledPerfProfiler.IsProfilingEnabled(ActiveScheduleId);
        ActiveScheduleIdDisplayText := ActiveScheduleDisplayName();
    end;

    trigger OnAfterGetRecord()
    begin
        ScheduledPerfProfiler.MapRecordToActivityType(Rec, Activity);
        UserName := ScheduledPerfProfiler.MapRecordToUserName(Rec);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        ScheduledPerfProfiler.MapRecordToActivityType(Rec, Activity);
        UserName := ScheduledPerfProfiler.MapRecordToUserName(Rec);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        ScheduledPerfProfiler.MapRecordToActivityType(Rec, Activity);
        UserName := ScheduledPerfProfiler.MapRecordToUserName(Rec);
    end;

    var
        ScheduledPerfProfiler: Codeunit "Scheduled Perf. Profiler";
        UserName: Text;
        Activity: Enum "Perf. Profile Activity Type";
        ActiveScheduleIdDisplayText: Text;
        ActiveScheduleId: Guid;

    local procedure ActiveScheduleDisplayName(): Text
    begin
        if IsNullGuid(ActiveScheduleId) then
            exit('');

        exit(Format(ActiveScheduleId));
    end;
}