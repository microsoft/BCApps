// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

using System.PerformanceProfile;
using System.Security.AccessControl;
using System.DataAdministration;
using System.Security.User;

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
    Permissions = tabledata "Performance Profile Scheduler" = rimd;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the schedule.';

                    trigger OnValidate()
                    begin
                        this.ValidateDescription();
                    end;
                }
                field("Schedule ID"; Rec."Schedule ID")
                {
                    ApplicationArea = All;
                    Caption = 'Schedule ID';
                    ToolTip = 'Specifies the ID of the schedule.';
                    Editable = false;
                }
#if not CLEAN27
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    Caption = 'Enabled';
                    ToolTip = 'Specifies whether the schedule is enabled.';
                    AboutText = 'Specifies whether the schedule is enabled.';
                    Visible = false;
                    ObsoleteReason = 'This field is moved to StatusGroup.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';
                }
                field("Start Time"; Rec."Starting Date-Time")
                {
                    ApplicationArea = All;
                    Caption = 'Start Time';
                    ToolTip = 'Specifies the start time of the schedule.';
                    AboutText = 'The start time of the schedule.';
                    Visible = false;
                    ObsoleteReason = 'This field is moved to StatusGroup.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';

                    trigger OnValidate()
                    begin
                        ScheduledPerfProfiler.ValidatePerformanceProfileSchedulerDatesRelation(Rec);
                    end;
                }
                field("End Time"; Rec."Ending Date-Time")
                {
                    ApplicationArea = All;
                    Caption = 'End Time';
                    ToolTip = 'Specifies the end time of the schedule.';
                    AboutText = 'The end time of the schedule.';
                    Visible = false;
                    ObsoleteReason = 'This field is moved to StatusGroup.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';

                    trigger OnValidate()
                    begin
                        ScheduledPerfProfiler.ValidatePerformanceProfileSchedulerDatesRelation(Rec);
                        ScheduledPerfProfiler.ValidatePerformanceProfileEndTime(Rec);
                    end;
                }
#endif
            }
            group(StatusGroup)
            {
                Caption = 'Status';

                field(Status; Status)
                {
                    ApplicationArea = All;
                    Caption = 'Status';
                    ToolTip = 'Specifies the status of the schedule.';
                    Editable = false;
                }
                field("Is Enabled"; Rec.Enabled)
                {
                    ApplicationArea = All;
                    Caption = 'Enabled';
                    ToolTip = 'Specifies whether the schedule is enabled.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
                field("Starting Date-Time"; Rec."Starting Date-Time")
                {
                    ApplicationArea = All;
                    Caption = 'Start Time';
                    ToolTip = 'Specifies the start time of the schedule.';

                    trigger OnValidate()
                    begin
                        if Rec.Enabled then
                            ScheduledPerfProfiler.ValidatePerformanceProfileSchedulerDatesRelation(Rec);
                        CurrPage.Update();
                    end;
                }
                field("Ending Date-Time"; Rec."Ending Date-Time")
                {
                    ApplicationArea = All;
                    Caption = 'End Time';
                    ToolTip = 'Specifies the end time of the schedule.';
                    AboutText = 'The time at which the schedule will become automatically inactive.';

                    trigger OnValidate()
                    begin
                        if Rec.Enabled then
                            ScheduledPerfProfiler.ValidatePerformanceProfileSchedulerDatesRelation(Rec);
                        ScheduledPerfProfiler.ValidatePerformanceProfileEndTime(Rec);
                        CurrPage.Update();
                    end;
                }
            }
            group(Filtering)
            {
                Caption = 'Filtering Criteria';
                AboutText = 'Determines which activities will be profiled.';
#if not CLEAN27
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = All;
                    Caption = 'User ID';
                    ToolTip = 'Specifies the ID of the user associated with the schedule.';
                    TableRelation = User."User Security ID";
                    Lookup = true;
                    Visible = false;
                    ObsoleteReason = 'This field is obsolete. Use "User Name" instead.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '27.0';

                    trigger OnValidate()
                    begin
                        ScheduledPerfProfiler.ValidateScheduleCreationPermissions(UserSecurityId(), Rec."User ID");
                    end;
                }
#endif
                field("User Name"; UserName)
                {
                    ApplicationArea = All;
                    Caption = 'User Name';
                    ToolTip = 'Specifies the name of the user associated with the schedule.';
                    AboutText = 'Only this user''s sessions will be profiled.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        SelectedUser: Record User;
                        UserSelection: Codeunit "User Selection";
                    begin
                        UserSelection.OpenWithSystemUsers(SelectedUser);
                        UserName := SelectedUser."User Name";
                        Rec.Validate("User ID", SelectedUser."User Security ID");
                    end;

                    trigger OnValidate()
                    var
                        User: Record User;
                    begin
                        User.SetRange("User Name", UserName);
                        if User.FindFirst() then
                            ScheduledPerfProfiler.ValidateScheduleCreationPermissions(UserSecurityId(), User."User Security ID");
                    end;
                }
                field(Activity; Activity)
                {
                    ApplicationArea = All;
                    Caption = 'Activity Type';
                    ToolTip = 'Specifies the type of activity for which the schedule is created.';
                    AboutText = 'Only this type of session will be profiled.';

                    trigger OnValidate()
                    begin
                        ScheduledPerfProfiler.MapActivityTypeToRecord(Rec, Activity);
                    end;
                }
            }
            group(Advanced)
            {
                Caption = 'Advanced Settings';

                field(Frequency; Rec.Frequency)
                {
                    ApplicationArea = All;
                    Caption = 'Sampling Frequency';
                    ToolTip = 'Specifies the frequency at which the profiler will sample data.';
                }
                field("Retention Policy"; RetentionPeriod)
                {
                    ApplicationArea = All;
                    Caption = 'Retention Period';
                    ToolTip = 'Specifies the retention period of the profile.';
                    Editable = false;

                    trigger OnDrillDown()
                    var
                        RetentionPolicySetup: Record "Retention Policy Setup";
                        NoRetentionPolicyErrorInfo: ErrorInfo;
                    begin
                        if RetentionPolicySetup.Get(Database::"Performance Profile Scheduler") then
                            Page.Run(Page::"Retention Policy Setup Card", RetentionPolicySetup)
                        else begin
                            NoRetentionPolicyErrorInfo.Message := NoRetentionPolicySetupErr;
                            NoRetentionPolicyErrorInfo.AddAction(CreateRetentionPolicySetupTxt, Codeunit::"Scheduled Perf. Profiler Impl.", 'CreateRetentionPolicySetup');
                            Error(NoRetentionPolicyErrorInfo);
                        end;
                    end;
                }
                field("Activity Duration Threshold"; ProfileCreationThreshold)
                {
                    ApplicationArea = All;
                    Caption = 'Activity Duration Threshold (ms)';
                    ToolTip = 'Specifies the minimum amount of time an activity must last in order to be recorded in a profile.';

                    trigger OnValidate()
                    begin
                        Rec."Profile Creation Threshold" := ProfileCreationThreshold;
                        ScheduledPerfProfiler.ValidateThreshold(Rec);
                        ProfileCreationThreshold := Rec."Profile Creation Threshold";
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
        ProfileCreationThreshold := Rec."Profile Creation Threshold";
        Status := ScheduledPerfProfilerImpl.GetStatus(Rec);
        UserName := ScheduledPerfProfiler.MapRecordToUserName(Rec);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        ScheduledPerfProfiler.MapActivityTypeToRecord(Rec, Activity);
        this.ValidateRecord();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        this.ValidateRecord();
        this.ValidateDescription();
    end;

    var
        ScheduledPerfProfiler: Codeunit "Scheduled Perf. Profiler";
        ScheduledPerfProfilerImpl: Codeunit "Scheduled Perf. Profiler Impl.";
        Activity: Enum "Perf. Profile Activity Type";
        ProfileCreationThreshold: BigInteger;
        RetentionPeriod: Code[20];
        Status: Text;
        UserName: Text;
        MaxRetentionPeriod: Duration;
        NoRetentionPolicySetupErr: Label 'No retention policy setup found for the performance profiles table.';
        CreateRetentionPolicySetupTxt: Label 'Create a retention policy setup';
        EmptyDescriptionErr: Label 'The description must be filled in.';

    local procedure ValidateRecord()
    begin
        if Rec.Enabled then
            ScheduledPerfProfiler.ValidatePerformanceProfileSchedulerDates(Rec, MaxRetentionPeriod);
        ScheduledPerfProfiler.ValidatePerformanceProfileSchedulerRecord(Rec, Activity);
    end;

    local procedure ValidateDescription()
    begin
        if Rec.Description = '' then
            Error(EmptyDescriptionErr);
    end;
}