namespace Microsoft.Foundation.Task;
using System.Threading;
using System.Visualization;

page 9102 "Job Queue Tasks Activities"
{
    Caption = 'Job Queue Tasks';
    PageType = CardPart;
    RefreshOnActivate = true;
    Extensible = false;

    layout
    {
        area(content)
        {
            cuegroup("Job Queue")
            {
                Caption = 'Job Queue Tasks';
                field("Tasks Failed"; FailedTasksCount)
                {
                    Caption = 'Tasks Failed';
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Job Queue Entries";
                    ToolTip = 'Specifies the number of job queue entries that failed.';
                    StyleExpr = FailedTasksExpr;

                    trigger OnDrillDown()
                    var
                        JobQueueEntry: Record "Job Queue Entry";
                        JobQueueManagement: Codeunit "Job Queue Management";
                        JobQueueEntries: Page "Job Queue Entries";
                    begin
                        if not JobQueueManagement.CheckUserInJobQueueAdminList(UserId()) then
                            JobQueueEntry.SetRange("User ID", UserId());

                        JobQueueEntry.SetRange(Status, JobQueueEntry.Status::Error);
                        JobQueueEntries.SetTableView(JobQueueEntry);
                        JobQueueEntries.Run();
                    end;
                }
                field("Tasks In Process"; InProcessTasksCount)
                {
                    Caption = 'Tasks In Process';
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Job Queue Entries";
                    ToolTip = 'Specifies the number of job queue entries in process.';
                    StyleExpr = InProcessTasksExpr;

                    trigger OnDrillDown()
                    var
                        JobQueueEntry: Record "Job Queue Entry";
                        JobQueueManagement: Codeunit "Job Queue Management";
                        JobQueueEntries: Page "Job Queue Entries";
                    begin
                        if not JobQueueManagement.CheckUserInJobQueueAdminList(UserId()) then
                            JobQueueEntry.SetRange("User ID", UserId());

                        JobQueueEntry.SetRange(Status, JobQueueEntry.Status::"In Process");
                        JobQueueEntries.SetTableView(JobQueueEntry);
                        JobQueueEntries.Run();
                    end;
                }
                field("Tasks In Queue"; InQueueTasksCount)
                {
                    Caption = 'Tasks In Queue';
                    ApplicationArea = Basic, Suite;
                    DrillDownPageID = "Job Queue Entries";
                    ToolTip = 'Specifies the number of job queue entries that are not yet processed.';
                    StyleExpr = InQueueTasksExpr;

                    trigger OnDrillDown()
                    var
                        JobQueueEntry: Record "Job Queue Entry";
                        JobQueueManagement: Codeunit "Job Queue Management";
                        JobQueueEntries: Page "Job Queue Entries";
                    begin
                        if not JobQueueManagement.CheckUserInJobQueueAdminList(UserId()) then
                            JobQueueEntry.SetRange("User ID", UserId());

                        JobQueueEntry.SetFilter(Status, '%1|%2', JobQueueEntry.Status::Ready, JobQueueEntry.Status::Waiting);
                        JobQueueEntries.SetTableView(JobQueueEntry);
                        JobQueueEntries.Run();
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Set Up Cues")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set Up Cues';
                Image = Setup;
                ToolTip = 'Set up the cues (status tiles) related to the role.';

                trigger OnAction()
                var
                    CuesAndKpis: Codeunit "Cues And KPIs";
                begin
                    CuesAndKpis.OpenCustomizePageForCurrentUser(Database::"Job Queue Role Center Cue");
                end;
            }
        }
    }

    var
        InProcessTasksExpr: Text;
        FailedTasksExpr: Text;
        InQueueTasksExpr: Text;
        InProcessTasksCount: Integer;
        InQueueTasksCount: Integer;
        FailedTasksCount: Integer;

    local procedure UpdateJobQueueCountAndStyleExpr()
    var
        TempJobQueueRoleCenterCue: Record "Job Queue Role Center Cue" temporary;
        JobQueueEntry: Record "Job Queue Entry";
        CuesAndKpis: Codeunit "Cues And KPIs";
        JobQueueManagement: Codeunit "Job Queue Management";
        FailedTasksExprEnum: Enum "Cues And KPIs Style";
        InProcessTasksExprEnum: Enum "Cues And KPIs Style";
        InQueueTasksExprEnum: Enum "Cues And KPIs Style";
    begin
        JobQueueEntry.ReadIsolation(IsolationLevel::ReadUncommitted);
        if not JobQueueManagement.CheckUserInJobQueueAdminList(UserId()) then
            JobQueueEntry.SetRange("User ID", UserId());
        JobQueueEntry.SetFilter(Status, '%1|%2', JobQueueEntry.Status::Ready, JobQueueEntry.Status::Waiting);
        InQueueTasksCount := JobQueueEntry.Count();

        JobQueueEntry.SetRange(Status, JobQueueEntry.Status::Error);
        FailedTasksCount := JobQueueEntry.Count();

        JobQueueEntry.SetRange(Status, JobQueueEntry.Status::"In Process");
        InProcessTasksCount := JobQueueEntry.Count();

        CuesAndKpis.SetCueStyle(Database::"Job Queue Role Center Cue", TempJobQueueRoleCenterCue.FieldNo("Job Queue - Tasks Failed"), FailedTasksCount, FailedTasksExprEnum);
        CuesAndKpis.SetCueStyle(Database::"Job Queue Role Center Cue", TempJobQueueRoleCenterCue.FieldNo("Job Queue - Tasks In Process"), InProcessTasksCount, InProcessTasksExprEnum);
        CuesAndKpis.SetCueStyle(Database::"Job Queue Role Center Cue", TempJobQueueRoleCenterCue.FieldNo("Job Queue - Tasks In Queue"), InQueueTasksCount, InQueueTasksExprEnum);

        FailedTasksExpr := CuesAndKpis.ConvertStyleToStyleText(FailedTasksExprEnum);
        InProcessTasksExpr := CuesAndKpis.ConvertStyleToStyleText(InProcessTasksExprEnum);
        InQueueTasksExpr := CuesAndKpis.ConvertStyleToStyleText(InQueueTasksExprEnum);
    end;

    trigger OnOpenPage()
    var
        TempJobQueueRoleCenterCue: Record "Job Queue Role Center Cue" temporary;
        JobQueueNotificationSetup: Record "Job Queue Notification Setup";
        CuesAndKpis: Codeunit "Cues And KPIs";
        JobQueueNotification: Codeunit "Job Queue - Send Notification";
    begin
        JobQueueNotification.SendNotificationWhenJobFailed();
        if not CuesAndKpis.PersonalizedCueSetupExistsForCurrentUser(Database::"Job Queue Role Center Cue", TempJobQueueRoleCenterCue.FieldNo("Job Queue - Tasks Failed")) then
            CuesAndKpis.InsertData(Database::"Job Queue Role Center Cue", TempJobQueueRoleCenterCue.FieldNo("Job Queue - Tasks Failed"), Enum::"Cues And KPIs Style"::Favorable, JobQueueNotificationSetup.Threshold1, Enum::"Cues And KPIs Style"::Unfavorable, JobQueueNotificationSetup.Threshold2, Enum::"Cues And KPIs Style"::Unfavorable);
        if not CuesAndKpis.PersonalizedCueSetupExistsForCurrentUser(Database::"Job Queue Role Center Cue", TempJobQueueRoleCenterCue.FieldNo("Job Queue - Tasks In Process")) then
            CuesAndKpis.InsertData(Database::"Job Queue Role Center Cue", TempJobQueueRoleCenterCue.FieldNo("Job Queue - Tasks In Process"), Enum::"Cues And KPIs Style"::Favorable, 3, Enum::"Cues And KPIs Style"::Ambiguous, 4, Enum::"Cues And KPIs Style"::Unfavorable);
        if not CuesAndKpis.PersonalizedCueSetupExistsForCurrentUser(Database::"Job Queue Role Center Cue", TempJobQueueRoleCenterCue.FieldNo("Job Queue - Tasks In Queue")) then
            CuesAndKpis.InsertData(Database::"Job Queue Role Center Cue", TempJobQueueRoleCenterCue.FieldNo("Job Queue - Tasks In Queue"), Enum::"Cues And KPIs Style"::Favorable, 3, Enum::"Cues And KPIs Style"::Ambiguous, 99, Enum::"Cues And KPIs Style"::Unfavorable);
        UpdateJobQueueCountAndStyleExpr();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateJobQueueCountAndStyleExpr();
    end;
}

