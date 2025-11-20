// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Threading;

using System.Environment;
using System.EMail;

page 9111 "Job Queue Activities"
{
    Caption = 'Job Queue';
    PageType = CardPart;
    RefreshOnActivate = true;
    SourceTable = "Scheduled Task";

    layout
    {
        area(content)
        {
            cuegroup("Scheduled Tasks")
            {
                Caption = 'Scheduled Tasks';

                field("No. of Scheduled Tasks For User"; NumberOfScheduledTasksForUser)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Scheduled Tasks For User';
                    StyleExpr = TasksForUserCue;
                    Image = Calendar;
                    ToolTip = 'Specifies the number of scheduled tasks for the current user.';

                    trigger OnDrillDown()
                    var
                        ScheduledTasks: Page "Scheduled Tasks";
                    begin
                        ScheduledTasks.Run();
                    end;
                }

                field("No. of Scheduled Tasks"; NumberOfScheduledTasks)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Scheduled Tasks';
                    StyleExpr = TasksCue;
                    Image = Calendar;
                    ToolTip = 'Specifies the number of scheduled tasks for the environment.';

                    trigger OnDrillDown()
                    var
                        ScheduledTasks: Page "Scheduled Tasks";
                    begin
                        ScheduledTasks.Run();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        TaskParameters: Dictionary of [Text, Text];
    begin
        TaskParameters.Add('UserId', Format(UserSecurityId()));
        CurrPage.EnqueueBackgroundTask(JobQueueActivitiesId, Codeunit::"Job Queue Activities", TaskParameters, 60000, PageBackgroundTaskErrorLevel::Warning);
    end;

    trigger OnPageBackgroundTaskCompleted(TaskId: Integer; Results: Dictionary of [Text, Text])
    var
        JobQueueActivities: Codeunit "Job Queue Activities";
    begin
        if TaskId = JobQueueActivitiesId then begin
            Evaluate(NumberOfScheduledTasks, Results.Get(JobQueueActivities.GetScheduledTasksKey()));
            Evaluate(NumberOfScheduledTasksForUser, Results.Get(JobQueueActivities.GetScheduledTasksForUserKey()));

            if NumberOfScheduledTasks > 10000 then
                TasksCue := 'Unfavorable'
            else
                TasksCue := 'Favorable';

            if NumberOfScheduledTasksForUser > 5 then
                TasksForUserCue := 'Unfavorable'
            else
                TasksForUserCue := 'Favorable';

        end;
    end;

    var
        JobQueueActivitiesId: Integer;
        NumberOfScheduledTasks: Integer;
        NumberOfScheduledTasksForUser: Integer;
        TasksForUserCue: Text;
        TasksCue: Text;
}

