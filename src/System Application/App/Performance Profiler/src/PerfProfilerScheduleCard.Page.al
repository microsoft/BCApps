namespace System.Tooling;
using System.PerformanceProfile;
using System.Security.AccessControl;

page 1933 "Perf. Profiler Schedules Card"
{
    Caption = 'Profiler Schedule';
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    AboutTitle = 'About performance profiler schedules';
    AboutText = 'View and modify a specific profiler schedule.';
    SourceTable = "Performance Profile Scheduler";

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
                    Caption = 'Schedule ID';
                    ToolTip = 'The ID of the schedule.';
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
                    ToolTip = 'The time the schedule will start.';
                    AboutText = 'The time the schedule will start.';
                }

                field("End Time"; Rec."Ending Date-Time")
                {
                    Caption = 'End Time';
                    ToolTip = 'The time the schedule will end.';
                    AboutText = 'The time the schedule will end.';
                }


                field(Description; Rec.Description)
                {
                    Caption = 'Description';
                    ToolTip = 'The description of the schedule.';
                    AboutText = 'The description of the schedule.';
                }

            }

            group(Filtering)
            {
                Caption = 'Filtering Criteria';
                AboutText = 'Filtering criteria for the profiler schedule.';

                field("User ID"; Rec."User ID")
                {
                    Caption = 'User ID';
                    ToolTip = 'The ID of the user who created the schedule.';
                    AboutText = 'The ID of the user who created the schedule.';
                    TableRelation = User."User Security ID";
                    Lookup = true;
                }

                field("Client Type"; Rec."Client Type")
                {
                    Caption = 'Client Type';
                    ToolTip = 'The type of client for which the schedule is created.';
                    AboutText = 'The type of client for which the schedule is created.';
                }
            }

            group(Advanced)
            {
                Caption = 'Advanced Settings';
                AboutText = 'Advanced settings for the profiler schedule.';

                field(Frequency; Rec.Frequency)
                {
                    Caption = 'Sampling Frequency';
                    ToolTip = 'The frequency at which the profiler will sample data.';
                    AboutText = 'The frequency at which the profiler will sample data.';
                }

                field("Profile Keep Time"; Rec."Profile Keep Time")
                {
                    Caption = 'Profile Expiration Time (days)';
                    ToolTip = 'The number of days the profile will be kept.';
                    AboutText = 'The number of days the profile will be kept.';
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action("Open Profiles")
            {
                ApplicationArea = All;
                Caption = 'Open Profiles';
                RunObject = page "Performance Profiles";
                RunPageLink = "Schedule ID" = field("Schedule ID");
            }
        }
    }
}