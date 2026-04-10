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
                Caption = 'Profiling Status';

#if not CLEAN27
                field("Active Schedule ID"; ActiveScheduleIdDisplayText)
                {
                    Caption = 'Active Schedule ID';
                    Editable = false;
                    DrillDown = true;
                    ToolTip = 'Specifies the ID of the active schedule for the current session.';
                    Visible = false;
                    ObsoleteReason = 'This field is obsolete. Use the "Active Schedule" field instead.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';

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
#endif
                field("Active Schedule"; ActiveScheduleDisplayNameText)
                {
                    ApplicationArea = All;
                    Caption = 'Active schedule for the current session';
                    Editable = false;
                    DrillDown = true;
                    ToolTip = 'Specifies the description of the active schedule for the current session.';

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
                }
                field(Activity; Activity)
                {
                    Caption = 'Activity Type';
                    ToolTip = 'Specifies the type of activity for which the schedule is created.';
                }
                field("User Name"; UserName)
                {
                    Caption = 'User Name';
                    ToolTip = 'Specifies the name of the user who created the schedule.';
                }
                field(Status; Status)
                {
                    ApplicationArea = All;
                    Caption = 'Status';
                    ToolTip = 'Specifies the status of the schedule.';
                    Editable = false;
                }
                field("Schedule ID"; Rec."Schedule ID")
                {
                    Caption = 'Schedule ID';
                    ToolTip = 'Specifies the ID of the schedule.';
                    Editable = false;
                    Visible = false;
                }
#if not CLEAN27
                field(Enabled; Rec.Enabled)
                {
                    Caption = 'Enabled';
                    ToolTip = 'Specifies if the schedule is enabled.';
                    AboutText = 'Specifies if the schedule is enabled.';
                    Visible = false;
                    ObsoleteReason = 'This field is obsolete.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                }
                field("Start Time"; Rec."Starting Date-Time")
                {
                    Caption = 'Start Time';
                    ToolTip = 'Specifies the time the schedule will start.';
                    AboutText = 'The time the schedule will start.';
                    Visible = false;
                    ObsoleteReason = 'This field is obsolete.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                }
                field("End Time"; Rec."Ending Date-Time")
                {
                    Caption = 'End Time';
                    ToolTip = 'Specifies the time the schedule will end.';
                    AboutText = 'The time the schedule will end.';
                    Visible = false;
                    ObsoleteReason = 'This field is obsolete.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                }
                field(Frequency; Rec.Frequency)
                {
                    Caption = 'Sampling Frequency';
                    ToolTip = 'Specifies the frequency at which the profiler will sample data.';
                    AboutText = 'The frequency at which the profiler will sample data.';
                    Visible = false;
                    ObsoleteReason = 'This field is obsolete.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                }
                field("Profile Creation Threshold"; Rec."Profile Creation Threshold")
                {
                    Caption = 'Profile Creation Threshold (ms)';
                    ToolTip = 'Specifies to create only profiles that are greater then the profile creation threshold';
                    AboutText = 'Limit the amount of sampling profiles that are created by setting a millisecond threshold. Only profiles larger then the threshold will be created.';
                    Visible = false;
                    ObsoleteReason = 'This field is obsolete.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                }
#endif
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
        ReloadActiveSchedule();
    end;

    trigger OnAfterGetRecord()
    begin
        ScheduledPerfProfiler.MapRecordToActivityType(Rec, Activity);
        UserName := ScheduledPerfProfiler.MapRecordToUserName(Rec);
        Status := ScheduledPerfProfilerImpl.GetStatus(Rec);
        ReloadActiveSchedule();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        ScheduledPerfProfiler.MapRecordToActivityType(Rec, Activity);
        UserName := ScheduledPerfProfiler.MapRecordToUserName(Rec);
        ReloadActiveSchedule();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        ScheduledPerfProfiler.MapRecordToActivityType(Rec, Activity);
        UserName := ScheduledPerfProfiler.MapRecordToUserName(Rec);
    end;

    var
        ScheduledPerfProfiler: Codeunit "Scheduled Perf. Profiler";
        ScheduledPerfProfilerImpl: Codeunit "Scheduled Perf. Profiler Impl.";
        UserName: Text;
        Activity: Enum "Perf. Profile Activity Type";
#if not CLEAN27
        ActiveScheduleIdDisplayText: Text;
#endif
        ActiveScheduleDisplayNameText: Text;
        ActiveScheduleId: Guid;
        Status: Text;

    local procedure ReloadActiveSchedule()
    begin
        ScheduledPerfProfiler.IsProfilingEnabled(ActiveScheduleId);
        ActiveScheduleDisplayNameText := ActiveScheduleDisplayName();
    end;

    local procedure ActiveScheduleDisplayName(): Text
    var
        PerformanceProfileScheduler: Record "Performance Profile Scheduler";
    begin
        if IsNullGuid(ActiveScheduleId) then
            exit('');

        if PerformanceProfileScheduler.Get(ActiveScheduleId) then
            exit(PerformanceProfileScheduler.Description);
    end;
}