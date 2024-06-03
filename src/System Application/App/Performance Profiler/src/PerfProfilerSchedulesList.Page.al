// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.PerformanceProfile;
using System.Security.AccessControl;

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

    layout
    {
        area(Content)
        {
            repeater(Profiles)
            {
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
                    ToolTip = 'Specifies whether the schedule is enabled.';
                    AboutText = 'Specifies whether the schedule is enabled.';
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
                field("User ID"; Rec."User ID")
                {
                    Caption = 'User ID';
                    ToolTip = 'Specifies the ID of the user who created the schedule.';
                    AboutText = 'The ID of the user who created the schedule.';
                    TableRelation = User."User Security ID";
                    Lookup = true;
                }
                field(Activity; Activity)
                {
                    Caption = 'Activity Type';
                    ToolTip = 'Specifies the type of activity for which the schedule is created.';
                    AboutText = 'The type of activity for which the schedule is created.';
                }
                field(Description; Rec.Description)
                {
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the schedule.';
                    AboutText = 'The description of the schedule.';
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


                field("Profile Keep Time"; Rec."Profile Keep Time")
                {
                    Caption = 'Profile Expiration Time (days)';
                    ToolTip = 'Specifies the number of days the profile will be kept.';
                    AboutText = 'The number of days the profile will be kept.';
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
                RunObject = page "Performance Profiles";
                RunPageLink = "Schedule ID" = field("Schedule ID");
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        SchedulerPage.MapRecordToActivityType(Rec, Activity);
    end;

    var
        SchedulerPage: Codeunit "Scheduled Perf. Profiler";
        Activity: Enum "Activity Type";
}