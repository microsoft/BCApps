namespace System.Threading;

using System.Environment;
using System.Privacy;
using System.Security.AccessControl;
using System.Automation;

page 672 "Job Queue Entries"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Job Queue Entries';
    CardPageID = "Job Queue Entry Card";
    PageType = List;
    AboutTitle = 'About Job Queue Entries';
    AboutText = 'Schedule, monitor, and manage automated jobs for reports and codeunits, including setting run parameters, recurrence patterns, priorities, and tracking job status or errors.';
    SourceTable = "Job Queue Entry";
    SourceTableView = sorting("Entry No.");
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the job queue entry. When you create a job queue entry, its status is set to On Hold. You can set the status to Ready and back to On Hold. Otherwise, status information in this field is updated automatically.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Basic, Suite;
                    Style = Unfavorable;
                    StyleExpr = UserDoesNotExist;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                }
                field("Object Type to Run"; Rec."Object Type to Run")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the object, report or codeunit, that is to be run for the job queue entry. After you specify a type, you then select an object ID of that type in the Object ID to Run field.';
                }
                field("Object ID to Run"; Rec."Object ID to Run")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the object that is to be run for this job. You can select an ID that is of the object type that you have specified in the Object Type to Run field.';
                }
                field("Object Caption to Run"; Rec."Object Caption to Run")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the object that is selected in the Object ID to Run field.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the job queue entry. You can edit and update the description on the job queue entry card. The description is also displayed in the Job Queue Entries window, but it cannot be updated there.';
                }
                field("Job Queue Category Code"; Rec."Job Queue Category Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the job queue category to which the job queue entry belongs. Choose the field to select a code from the list.';
                }
                field("Priority Within Category"; Rec."Priority Within Category")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the priority of the job within the job queue category. Only relevant when job queue category code is specified.';
                }
                field("User Session Started"; Rec."User Session Started")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date and time that a user session started.';
                }
                field("Parameter String"; Rec."Parameter String")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a text string that is used as a parameter by the job queue when it is run.';
                    Visible = false;
                }
                field("Earliest Start Date/Time"; Rec."Earliest Start Date/Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the earliest date and time when the job queue entry should be run.';
                }
                field(Scheduled; Rec.Scheduled)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Unfavorable;
                    StyleExpr = not Rec.Scheduled;
                    ToolTip = 'Specifies if the job queue entry has been scheduled to run automatically, which happens when an entry changes status to Ready. If the field is cleared, the job queue entry is not scheduled to run.';
                }
                field("Recurring Job"; Rec."Recurring Job")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if the job queue entry is recurring. If the Recurring Job check box is selected, then the job queue entry is recurring. If the check box is cleared, the job queue entry is not recurring. After you specify that a job queue entry is a recurring one, you must specify on which days of the week the job queue entry is to run. Optionally, you can also specify a time of day for the job to run and how many minutes should elapse between runs.';
                }
                field("No. of Minutes between Runs"; Rec."No. of Minutes between Runs")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the minimum number of minutes that are to elapse between runs of a job queue entry. This field only has meaning if the job queue entry is set to be a recurring job.';
                }
                field("Run on Mondays"; Rec."Run on Mondays")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the job queue entry runs on Mondays.';
                    Visible = false;
                }
                field("Run on Tuesdays"; Rec."Run on Tuesdays")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the job queue entry runs on Tuesdays.';
                    Visible = false;
                }
                field("Run on Wednesdays"; Rec."Run on Wednesdays")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the job queue entry runs on Wednesdays.';
                    Visible = false;
                }
                field("Run on Thursdays"; Rec."Run on Thursdays")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the job queue entry runs on Thursdays.';
                    Visible = false;
                }
                field("Run on Fridays"; Rec."Run on Fridays")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the job queue entry runs on Fridays.';
                    Visible = false;
                }
                field("Run on Saturdays"; Rec."Run on Saturdays")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the job queue entry runs on Saturdays.';
                    Visible = false;
                }
                field("Run on Sundays"; Rec."Run on Sundays")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies that the job queue entry runs on Sundays.';
                    Visible = false;
                }
                field("Starting Time"; Rec."Starting Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the earliest time of the day that the recurring job queue entry is to be run.';
                    Visible = false;
                }
                field("Ending Time"; Rec."Ending Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the latest time of the day that the recurring job queue entry is to be run.';
                    Visible = false;
                }
                field(Timeout; Rec."Job Timeout")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the maximum time that the job queue entry is allowed to run.';
                    Visible = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("Job &Queue")
            {
                Caption = 'Job &Queue';
                Image = CheckList;
                action(ResetStatusWithoutApproval)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set Status to Ready';
                    Image = ResetStatus;
                    ToolTip = 'Change the status of the selected entry.';

                    trigger OnAction()
                    begin
                        Rec.SetStatus(Rec.Status::Ready);
                    end;
                }
                action(Suspend)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Set On Hold';
                    Image = Pause;
                    ToolTip = 'Change the status of the selected entry.';

                    trigger OnAction()
                    begin
                        Rec.SetStatus(Rec.Status::"On Hold");
                    end;
                }
                action(ShowError)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Error';
                    Image = Error;
                    ToolTip = 'Show the error message that has stopped the entry.';

                    trigger OnAction()
                    begin
                        Rec.ShowErrorMessage();
                    end;
                }
                action(RestartWithoutApproval)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Restart';
                    Image = Start;
                    ToolTip = 'Stop and start the selected entry.';

                    trigger OnAction()
                    begin
                        Rec.Restart();
                    end;
                }
                group(SetPriority)
                {
                    Caption = 'Set Priority';
                    Image = TaskList;
                    ToolTip = 'Set the priority of the entry. Only relevant for jobs with a category code.';
                    Enabled = (Rec."Job Queue Category Code" <> '');

                    action(SetPriorityLow)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Low';
                        ToolTip = 'Set priority to low.';

                        trigger OnAction()
                        begin
                            Rec.SetPriority(Rec."Priority Within Category"::Low);
                        end;
                    }
                    action(SetPriorityNormal)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Normal';
                        ToolTip = 'Set priority to Normal.';

                        trigger OnAction()
                        begin
                            Rec.SetPriority(Rec."Priority Within Category"::Normal);
                        end;
                    }
                    action(SetPriorityHigh)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'High';
                        ToolTip = 'Set priority to High.';

                        trigger OnAction()
                        begin
                            Rec.SetPriority(Rec."Priority Within Category"::High);
                        end;
                    }
                }
                action(RunInForeground)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Run once (foreground)';
                    Image = DebugNext;
                    ToolTip = 'Run a copy of this job once in foreground.';

                    trigger OnAction()
                    var
                        JobQueueManagement: Codeunit "Job Queue Management";
                    begin
                        JobQueueManagement.RunJobQueueEntryOnce(Rec);
                    end;
                }
            }
            group(Flow)
            {
                Caption = 'Power Automate';
                Image = Flow;
                customaction(CreateFlowFromTemplate)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Automate Job Queue Notifications';
                    ToolTip = 'Create a new flow of job queue notifications in Power Automate from a list of relevant flow templates.';
                    Visible = IsSaaS and IsPowerAutomatePrivacyNoticeApproved;
                    CustomActionType = FlowTemplateGallery;
                    FlowTemplateCategoryName = 'd365bc_jobqueue';
                }
            }
        }
        area(navigation)
        {
            group(Action15)
            {
                Caption = 'Job &Queue';
                Image = CheckList;
                action(LogEntries)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Log Entries';
                    Image = Log;
                    RunObject = Page "Job Queue Log Entries";
                    RunPageLink = ID = field(ID);
                    ToolTip = 'View the job queue log entries.';
                }
                action(ShowRecord)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Show Record';
                    Image = ViewDetails;
                    ToolTip = 'Show the record for the selected entry.';

                    trigger OnAction()
                    begin
                        Rec.LookupRecordToProcess();
                    end;
                }
                action(RemoveError)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Remove Failed Entries';
                    Image = Delete;
                    ToolTip = 'Deletes the job queue entries that have failed.';

                    trigger OnAction()
                    begin
                        Rec.RemoveFailedJobs(false);
                    end;
                }
                action(RunNow)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Run the current Job Queue Entry now';
                    Image = DebugNext;
                    ToolTip = 'Schedules the current Job Queue Entry for immediate execution.';

                    trigger OnAction()
                    var
                        JobQueueDispatcher: Codeunit "Job Queue Dispatcher";
                        IsHandled: Boolean;
                    begin
                        IsHandled := false;
                        OnBeforeOnActionRunNow(Rec, IsHandled);
                        if IsHandled then
                            exit;

                        Rec.Status := Rec.Status::Ready;
                        Rec.Modify(false);
                        Commit(); // Commit() is needed because the dispatcher calls SelectLatestVersion;
                        JobQueueDispatcher.Run(Rec);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process', Comment = 'Generated from the PromotedActionCategories property index 1.';

                actionref(ResetStatusWithoutApproval_Promoted; ResetStatusWithoutApproval)
                {
                }
                actionref(RestartWithoutApproval_Promoted; RestartWithoutApproval)
                {
                }
                actionref(LogEntries_Promoted; LogEntries)
                {
                }
                actionref(RunInForeground_Promoted; RunInForeground)
                {
                }
                actionref(Suspend_Promoted; Suspend)
                {
                }
                actionref(ShowError_Promoted; ShowError)
                {
                }
                actionref(CreateFlowFromTemplate_Promoted; CreateFlowFromTemplate)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        PrivacyNotice: Codeunit "Privacy Notice";
        FlowServiceManagement: Codeunit "Flow Service Management";
    begin
        JobQueueManagement.TooManyScheduledTasksNotification();
        IsSaaS := EnvironmentInfo.IsSaaS();
        IsPowerAutomatePrivacyNoticeApproved := PrivacyNotice.GetPrivacyNoticeApprovalState(FlowServiceManagement.GetPowerAutomatePrivacyNoticeId()) = "Privacy Notice Approval State"::Agreed;
    end;

    trigger OnAfterGetRecord()
    var
        User: Record User;
    begin
        UserDoesNotExist := false;
        if Rec."User ID" = UserId then
            exit;
        if User.IsEmpty() then
            exit;
        User.SetRange("User Name", Rec."User ID");
        UserDoesNotExist := User.IsEmpty();
    end;

    var
        JobQueueManagement: Codeunit "Job Queue Management";
        UserDoesNotExist: Boolean;
        IsSaaS: Boolean;
        IsPowerAutomatePrivacyNoticeApproved: Boolean;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnActionRunNow(JobQueueEntry: Record "Job Queue Entry"; var IsHandled: Boolean)
    begin
    end;
}

