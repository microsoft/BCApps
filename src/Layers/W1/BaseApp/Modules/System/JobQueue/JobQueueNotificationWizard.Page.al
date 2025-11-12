// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.System.Threading;

using System.Environment;
using System.Telemetry;
using System.Environment.Configuration;
using System.Threading;
using System.Utilities;

page 1179 "Job Queue Notification Wizard"
{
    PageType = NavigatePage;
    RefreshOnActivate = true;
    Caption = 'Set Up Job Queue Notifications';
    SourceTable = "Job Queue Notification Setup";
    Editable = true;
    Extensible = false;

    layout
    {
        area(Content)
        {
            group(Control17)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and not (Step = Step::Finish);
                field(MediaResourcesStandardMediaReference; MediaResourcesStandard."Media Reference")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Control19)
            {
                Editable = false;
                ShowCaption = false;
                Visible = TopBannerVisible and (Step = Step::Finish);
                field(MediaResourcesDoneMediaReference; MediaResourcesDone."Media Reference")
                {
                    ApplicationArea = Jobs;
                    Editable = false;
                    ShowCaption = false;
                }
            }
            group(Step1)
            {
                Visible = Step = Step::Start;
                group("Para1.1")
                {
                    Caption = 'Welcome to Job Queue notifications';
                    InstructionalText = 'Get notified about background tasks that Business Central executes with Job Queues.';
                }
                group("Para1.2")
                {
                    Caption = 'Let''s go!';
                    InstructionalText = 'Choose Next to specify who to notify about issues with job queue entries that run in the background.';
                }
            }
            group(Step2)
            {
                ShowCaption = false;
                Visible = Step = Step::Participants;
                group("Para2.1")
                {
                    Caption = 'Who should know about issues with job queue entries?';
                    group("Para2.1.1")
                    {
                        ShowCaption = false;
                        field(NotifyUserInitiatingBackgroundTasks; NotifyUserInitiatingTask)
                        {
                            ApplicationArea = All;
                            Visible = true;
                            ToolTip = 'Specifies whether the user who initiates a background task should receive a notification when the task is failed.';
                            Caption = 'Notify the user who initiates background tasks';
                        }
                        field(NotifyAdmin; NotifyAdmin)
                        {
                            ApplicationArea = All;
                            Visible = true;
                            ToolTip = 'Specifies whether these job queue notification administrators should receive a notification when any task is failed in Job Queue.';
                            Caption = 'Notify these job queue notification administrators';
                        }
                    }
                    group("Para2.1.2")
                    {
                        ShowCaption = false;
                        Visible = NotifyAdmin;
                        InstructionalText = 'Choose one or more job queue notification administrators to notify about issues.';
                        part("Job Queue Admin List"; "Job Queue Admin Setup")
                        {
                            Caption = 'Job Queue Notification Administrators List';
                            ApplicationArea = All;
                            Visible = NotifyAdmin;
                        }
                    }
                }
            }
            group(Step3)
            {
                Visible = Step = Step::NotificationType;
                group("Para3.1")
                {
                    Caption = 'How do you want to notify users?';

                    field(InProductNotification; InProductNotification)
                    {
                        ApplicationArea = All;
                        Visible = true;
                        ToolTip = 'Specifies if the notifications should be displayed in the Business Central web client.';
                        Caption = 'In-product notifications';
                    }
                    field(NotifyWithPowerAutomateFlow; PowerAutomateFlowNotification)
                    {
                        ApplicationArea = All;
                        Editable = true;
                        Visible = true;
                        ToolTip = 'Specifies if the external business event will be enabled.';
                        Caption = 'Control notifications with business events (preview)';
                    }
                }
#if not CLEAN26
                group("Para3.2")
                {
                    ObsoleteReason = 'This group is not used.';
                    ObsoleteState = Pending;
                    ObsoleteTag = '26.0';
                    ShowCaption = false;
                    field(VTAndBEEnabled; VTAndBEEnabledLbl)
                    {
                        ApplicationArea = All;
                        Editable = false;
                        ShowCaption = false;
                        Visible = false;
                        StyleExpr = 'Favorable';
                        ObsoleteReason = 'This field is not used.';
                        ObsoleteState = Pending;
                        ObsoleteTag = '26.0';
                    }
                    field(VTAndBEDisabled; VTAndBEDisabledLbl)
                    {
                        ApplicationArea = All;
                        Editable = false;
                        ShowCaption = false;
                        Visible = false;
                        StyleExpr = 'Unfavorable';
                        ObsoleteReason = 'This field is not used.';
                        ObsoleteState = Pending;
                        ObsoleteTag = '26.0';
                    }
                }
#endif
                group("Para3.3")
                {
                    ShowCaption = false;
                    InstructionalText = 'Choose Next to specify when to show in-product notifications.';
                }
            }
            group(Step4)
            {
                Visible = Step = Step::NotificationTime;
                group("Para4.1")
                {
                    Caption = 'When do you want to display in-product notifications?';
                    field(ShowNotificationImmediately; NotifyWhenJobFailed)
                    {
                        ApplicationArea = All;
                        Caption = 'Immediately for each job queue entry';
                        ToolTip = 'Specifies the user should receive a notification once the task is failed.';
                        trigger OnValidate()
                        begin
                            if NotifyWhenJobFailed then
                                NotifyAfterThreshold := false;
                        end;
                    }
                    field(ShowNotificationReachingThreshold; NotifyAfterThreshold)
                    {
                        ApplicationArea = All;
                        Caption = 'After a threshold is reached';
                        ToolTip = 'Specifies the user should receive a notification when the count of failed jobs reach the low threshold.';
                        trigger OnValidate()
                        begin
                            if NotifyAfterThreshold then
                                NotifyWhenJobFailed := false;
                        end;
                    }
                    field(Threshold1; Threshold1)
                    {
                        ApplicationArea = All;
                        Caption = 'Low threshold';
                        ToolTip = 'Specifies the low threshold for the cue set up of failed jobs.';
                        Editable = NotifyAfterThreshold;
                        trigger OnValidate()
                        begin
                            if Threshold1 < 0 then
                                Error(Threshold1MustBeGreaterThanOrEqualTo0Err);
                            if Threshold1 > Threshold2 then
                                Error(Threshold1MustBeLessThanOrEqualToThreshold2Err);
                        end;
                    }
                    field(Threshold2; Threshold2)
                    {
                        ApplicationArea = All;
                        Caption = 'High threshold';
                        ToolTip = 'Specifies the high threshold for the cue set up of failed jobs.';
                        Editable = NotifyAfterThreshold;
                        trigger OnValidate()
                        begin
                            if Threshold2 < 0 then
                                Error(Threshold2MustBeGreaterThanOrEqualTo0Err);
                            if Threshold1 > Threshold2 then
                                Error(Threshold1MustBeLessThanOrEqualToThreshold2Err);
                        end;
                    }
                }
                group("Para4.2")
                {
                    Caption = 'NOTE: Job queue entries have issues when they fail more times than their Maximum number of attempts to run setting allows.';
                    InstructionalText = 'Choose Next to finish the in-product notifications setup.';
                }
            }
            group(Step5)
            {
                InstructionalText = 'The Job Queue notification setup is complete.';
                Visible = Step = Step::Finish;
                group(FinishGroup)
                {
                    Caption = 'To enable notifications using Power Automate:';
                    Visible = PowerAutomateFlowNotification;
                    field(CreateFlowFromTemplateTip; CreateFlowFromTemplateTipLbl)
                    {
                        ApplicationArea = All;
                        Editable = false;
                        ShowCaption = false;
                    }
                    field(CreateFlowFromTemplate; CreateFlowFromTemplateLbl)
                    {
                        ApplicationArea = All;
                        Editable = false;
                        ShowCaption = false;

                        trigger OnDrillDown()
                        begin
                            Page.RunModal(Page::"Job Queue Entries");
                        end;
                    }
                }
                label(Finish2)
                {
                    ApplicationArea = All;
                    Caption = 'Choose Finish to apply the setup and complete the guide.';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(BackAction)
            {
                ApplicationArea = Jobs;
                Caption = '&Back';
                Enabled = BackActionEnabled;
                Image = PreviousRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(true);
                end;
            }
            action(NextAction)
            {
                ApplicationArea = Jobs;
                Caption = '&Next';
                Enabled = NextActionEnabled;
                Image = NextRecord;
                InFooterBar = true;

                trigger OnAction()
                begin
                    NextStep(false);
                end;
            }
#if not CLEAN26
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = '&Refresh';
                Image = Refresh;
                InFooterBar = true;
                Visible = false;
                ObsoleteReason = 'This action is not needed.';
                ObsoleteState = Pending;
                ObsoleteTag = '26.0';
                trigger OnAction()
                begin
                    UpdateControls();
                end;
            }
#endif
            action(FinishAction)
            {
                ApplicationArea = Jobs;
                Caption = '&Finish';
                Enabled = FinishActionEnabled;
                Image = Approve;
                InFooterBar = true;

                trigger OnAction()
                var
                    FeatureTelemetry: Codeunit "Feature Telemetry";
                    GuidedExperience: Codeunit "Guided Experience";
                begin
                    if Rec.InProductNotification then
                        FeatureTelemetry.LogUptake('0000OK8', 'JobQueueFailedNotification-InProd ', Enum::"Feature Uptake Status"::"Set up");
                    if Rec.PowerAutomateFlowNotification then
                        FeatureTelemetry.LogUptake('0000OK9', 'JobQueueFailedNotification-External ', Enum::"Feature Uptake Status"::"Set up");

                    GuidedExperience.CompleteAssistedSetup(ObjectType::Page, Page::"Job Queue Notification Wizard");
                    UpdateJobQueueNotificationSetup();
                    CurrPage.Close();
                end;
            }
        }
    }

    trigger OnInit()
    begin
        LoadTopBanners();
        Step := Step::Start;
        UpdateControls();
    end;

    var
        MediaRepositoryStandard: Record "Media Repository";
        MediaRepositoryDone: Record "Media Repository";
        MediaResourcesStandard: Record "Media Resources";
        MediaResourcesDone: Record "Media Resources";
        ClientTypeManagement: Codeunit "Client Type Management";
        Step: Option Start,Participants,NotificationType,NotificationTime,Finish;
        TopBannerVisible: Boolean;
        BackActionEnabled: Boolean;
        NextActionEnabled: Boolean;
        FinishActionEnabled: Boolean;
        NotifyUserInitiatingTask: Boolean;
        NotifyAdmin: Boolean;
        InProductNotification: Boolean;
        PowerAutomateFlowNotification: Boolean;
        NotifyWhenJobFailed: Boolean;
        NotifyAfterThreshold: Boolean;
        Threshold1: Integer;
        Threshold2: Integer;
#if not CLEAN26
        VTAndBEEnabledLbl: Label 'Virtual tables and Business Events are enabled.';
        VTAndBEDisabledLbl: Label 'Virtual tables and Business Events are disabled.';
#endif
        CreateFlowFromTemplateTipLbl: Label 'You can set up automated flow to be used to notify users of Job Queue issues on Job Queue Entries page.';
        CreateFlowFromTemplateLbl: Label 'Open Job Queue Entries page to create an automated flow for Job Queue failure notification.';
        Threshold1MustBeGreaterThanOrEqualTo0Err: Label 'Threshold 1 must be greater than or equal to 0.';
        Threshold2MustBeGreaterThanOrEqualTo0Err: Label 'Threshold 2 must be greater than or equal to 0.';
        Threshold1MustBeLessThanOrEqualToThreshold2Err: Label 'Threshold 1 must be less than or equal to Threshold 2.';

    local procedure UpdateJobQueueNotificationSetup()
    begin
        Rec.NotifyUserInitiatingTask := NotifyUserInitiatingTask;
        Rec.NotifyJobQueueAdmin := NotifyAdmin;
        Rec.InProductNotification := InProductNotification;
        Rec.PowerAutomateFlowNotification := PowerAutomateFlowNotification;
        Rec.NotifyWhenJobFailed := NotifyWhenJobFailed;
        Rec.NotifyAfterThreshold := NotifyAfterThreshold;
        Rec.Threshold1 := Threshold1;
        Rec.Threshold2 := Threshold2;
        Rec.Modify();

        UpdateMyNotificationSetup();
    end;

    local procedure UpdateMyNotificationSetup()
    var
        MyNotifications: Record "My Notifications";
        JobQueueNotifiedAdmin: Record "Job Queue Notified Admin";
        JobQueueSendNotificationMgt: Codeunit "Job Queue - Send Notification";
        MyNotificationGUID: Guid;
    begin
        MyNotificationGUID := JobQueueSendNotificationMgt.GetJobQueueFailedNotificationId();
        MyNotifications.SetRange("Notification Id", MyNotificationGUID);
        if MyNotifications.FindSet() then
            if NotifyUserInitiatingTask then
                repeat
                    MyNotifications.Enabled := true;
                    MyNotifications.Modify();
                until MyNotifications.Next() = 0
            else
                repeat
                    MyNotifications.Enabled := false;
                    MyNotifications.Modify();
                until MyNotifications.Next() = 0;

        if not NotifyUserInitiatingTask and NotifyAdmin and JobQueueNotifiedAdmin.FindSet() then
            repeat
                if MyNotifications.Get(JobQueueNotifiedAdmin."User Name", MyNotificationGUID) then begin
                    MyNotifications.Enabled := true;
                    MyNotifications.Modify();
                end;
            until JobQueueNotifiedAdmin.Next() = 0;

    end;

    local procedure LoadFromJobQueueNotificationSetup()
    begin
        Rec.FindLast();

        NotifyUserInitiatingTask := Rec.NotifyUserInitiatingTask;
        NotifyAdmin := Rec.NotifyJobQueueAdmin;
        InProductNotification := Rec.InProductNotification;
        PowerAutomateFlowNotification := Rec.PowerAutomateFlowNotification;
        NotifyWhenJobFailed := Rec.NotifyWhenJobFailed;
        NotifyAfterThreshold := Rec.NotifyAfterThreshold;
        Threshold1 := Rec.Threshold1;
        Threshold2 := Rec.Threshold2;
    end;

    local procedure LoadTopBanners()
    begin
        if MediaRepositoryStandard.Get('AssistedSetup-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType())) and
           MediaRepositoryDone.Get('AssistedSetupDone-NoText-400px.png', Format(ClientTypeManagement.GetCurrentClientType()))
        then
            if MediaResourcesStandard.Get(MediaRepositoryStandard."Media Resources Ref") and
               MediaResourcesDone.Get(MediaRepositoryDone."Media Resources Ref")
            then
                TopBannerVisible := MediaResourcesDone."Media Reference".HasValue;
    end;

    local procedure NextStep(Backward: Boolean)
    begin
        if Backward then
            Step := Step - 1
        else
            Step := Step + 1;

        UpdateControls();
    end;

    local procedure UpdateControls()
    begin
        NextActionEnabled := Step <> Step::Finish;
        BackActionEnabled := Step <> Step::Start;
        FinishActionEnabled := Step = Step::Finish;
    end;

    trigger OnOpenPage()
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
    begin
        FeatureTelemetry.LogUptake('0000OKA', 'JobQueueFailedNotification-InProd ', Enum::"Feature Uptake Status"::Discovered);
        FeatureTelemetry.LogUptake('0000OKB', 'JobQueueFailedNotification-External ', Enum::"Feature Uptake Status"::Discovered);

        if Rec.IsEmpty() then
            Rec.Insert(true);

        LoadFromJobQueueNotificationSetup();
    end;
}
