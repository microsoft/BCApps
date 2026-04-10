// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Email;

using System.Threading;

codeunit 9112 "Job Queue Activities"
{
    Access = Internal;

    trigger OnRun()
    var
        JobQueueManagement: Codeunit "Job Queue Management";
        Result: Dictionary of [Text, Text];
        NumberOfScheduledTasks: Integer;
        NumberOfScheduledTasksForUser: Integer;
        UserId: Guid;
    begin
        if not Evaluate(UserId, Page.GetBackgroundParameters().Get('UserId')) then
            Error(ParseUserIdErr);

        NumberOfScheduledTasks := JobQueueManagement.GetScheduledTasks();
        NumberOfScheduledTasksForUser := JobQueueManagement.GetScheduledTasksForUser(UserId);

        Result.Add(GetScheduledTasksKey(), Format(NumberOfScheduledTasks));
        Result.Add(GetScheduledTasksForUserKey(), Format(NumberOfScheduledTasksForUser));

        Page.SetBackgroundTaskResult(Result);
    end;

    internal procedure GetScheduledTasksKey(): Text
    begin
        exit('scheduledTasks');
    end;

    internal procedure GetScheduledTasksForUserKey(): Text
    begin
        exit('scheduledTasksForUser');
    end;

    var
        ParseUserIdErr: Label 'Failed to parse user id';
}