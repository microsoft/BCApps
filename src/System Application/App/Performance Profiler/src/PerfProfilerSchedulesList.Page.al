namespace System.Tooling;
using System.PerformanceProfile;
using System.Security.AccessControl;

page 1931 "Perf. Profiler Schedules List"
{
    Caption = 'Profiler Schedules';
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    AboutTitle = 'About performance profile scheduling';
    AboutText = 'Schedule performance profiles to run at specific times based on different criteria to troubleshoot performance issues.';
    DeleteAllowed = false;
    ModifyAllowed = false;
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

                field(Description; Rec.Description)
                {
                    Caption = 'Description';
                    ToolTip = 'The description of the schedule.';
                    AboutText = 'The description of the schedule.';
                }

                field(Frequency; Rec.Frequency)
                {
                    Caption = 'Sampling Frequency';
                    ToolTip = 'The frequency at which the profiler will sample data.';
                    AboutText = 'The frequency at which the profiler will sample data.';
                }

                field("Profile Creation Threshold"; Rec."Profile Creation Threshold")
                {
                    Caption = 'Profile Creation Threshold (ms)';
                    ToolTip = 'Create only profiles that are greater then the profile creation threshold';
                    AboutText = 'Limit the amount of sampling profiles that are created by setting a millisecond threshold. Only profiles larger then the threshold will be created.';
                }


                field("Profile Keep Time"; Rec."Profile Keep Time")
                {
                    Caption = 'Profile Expiration Time (days)';
                    ToolTip = 'The number of days the profile will be kept.';
                    AboutText = 'The number of days the profile will be kept.';

                    trigger OnValidate()
                    begin
                        this.ValidateProfileKeepTime();
                    end;
                }
            }
        }
    }

    local procedure ValidateProfileKeepTime()
    begin
        if (Rec."Profile Keep Time" < 1) or (Rec."Profile Keep Time" > 7) then begin
            Error(ProfileExpirationTimeRangeErrorLbl);
        end;
    end;

    var
        ProfileExpirationTimeRangeErrorLbl: Label 'The profile expiration time must be between 1 and 7 days.';
}