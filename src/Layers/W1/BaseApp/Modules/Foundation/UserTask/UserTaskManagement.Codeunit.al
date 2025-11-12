// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Task;

codeunit 1174 "User Task Management"
{
    // // Code unit to manage user tasks / user tasks groups.
    // // Due date filter options :-
    // // NONE :- All pending tasks assigned to logged in user or their groups.
    // // TODAY :- All pending tasks assigned to logged in user or their groups due today.
    // // THIS_WEEK :- All pending tasks assigned to logged in user or their groups due this week.


    trigger OnRun()
    begin
    end;

    var
        UserTaskGroupMember: Record "User Task Group Member";
        DueDateFilterOptions: Option "NONE",TODAY,THIS_WEEK;

    procedure GetMyPendingUserTasksCount(): Integer
    begin
        // Gets total count of user tasks assgined to logged in user.
        // This includes tasks assigned to the user and their groups.
        exit(CalculateUserTasksCount(DueDateFilterOptions::NONE));
    end;

    procedure GetMyPendingUserTasksCountDueToday(): Integer
    begin
        // Gets total count of user tasks assgined to logged in user.
        // This includes tasks assigned to the user and their groups due today.
        exit(CalculateUserTasksCount(DueDateFilterOptions::TODAY));
    end;

    procedure GetMyPendingUserTasksCountDueThisWeek(): Integer
    begin
        // Gets total count of user tasks assgined to logged in user.
        // This includes tasks assigned to the user and their groups due this week.
        exit(CalculateUserTasksCount(DueDateFilterOptions::THIS_WEEK));
    end;

    procedure SetFiltersToShowMyUserTasks(var UserTask: Record "User Task"; DueDateFilterOption: Integer)
    var
        MyTasksUserGroups: Text;
    begin
        MyTasksUserGroups := GetMyTasksUserGroupsAsFilterText();

        if MyTasksUserGroups <> '' then begin
            UserTask.FilterGroup(-1);
            UserTask.SetFilter("User Task Group Assigned To", MyTasksUserGroups);
            UserTask.SetRange("Assigned To", UserSecurityId());
        end else begin
            UserTask.FilterGroup(2);
            UserTask.SetRange("Assigned To", UserSecurityId());
        end;
        UserTask.FilterGroup(2);
        UserTask.SetFilter("Percent Complete", '<>100');
        UserTask.FilterGroup(0);

        case DueDateFilterOption of
            DueDateFilterOptions::NONE:
                UserTask.SetRange("Due DateTime");
            DueDateFilterOptions::THIS_WEEK:
                UserTask.SetFilter("Due DateTime", '<>%1 & <=%2', 0DT, CreateDateTime(CalcDate('<CW>'), 0T));
            DueDateFilterOptions::TODAY:
                UserTask.SetFilter("Due DateTime", '<>%1 & <=%2', 0DT, CurrentDateTime);
        end;
    end;

    procedure CompleteTasks(var UserTask: Record "User Task")
    begin
        if UserTask.FindSet(true) then
            repeat
                UserTask.SetCompleted();
                UserTask.Modify();
            until UserTask.Next() = 0;
    end;


    [EventSubscriber(ObjectType::Table, Database::"User Task Group", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteUserTaskGroup(var Rec: Record "User Task Group"; RunTrigger: Boolean)
    var
        UserTask: Record "User Task";
    begin
        if Rec.IsTemporary() then
            exit;

        UserTask.SetRange("User Task Group Assigned To", Rec.Code);
        // empty out 'user task group assigned to' for the tasks that were assigned to the user task group that is being deleted
        UserTask.ModifyAll("User Task Group Assigned To", '');
    end;

    local procedure CalculateUserTasksCount(DueDateFilterOption: Integer): Integer
    var
        UserTask: Record "User Task";
    begin
        UserTask.Reset();
        SetFiltersToShowMyUserTasks(UserTask, DueDateFilterOption);
        exit(UserTask.Count);
    end;

    local procedure GetMyTasksUserGroupsAsFilterText(): Text
    var
        FilterTxt: Text;
    begin
        // Returns a text contaning all the groups that logged in user belong to which can be used for setting filter
        // Example - If user belongs to 'A' and 'C' user tasks groups this function will return 'A|C' as filter text.
        UserTaskGroupMember.Reset();
        UserTaskGroupMember.SetRange("User Security ID", UserSecurityId());
        if UserTaskGroupMember.FindSet() then
            repeat
                FilterTxt := FilterTxt + UserTaskGroupMember."User Task Group Code" + '|';
            until UserTaskGroupMember.Next() = 0;

        // delete last char (|) to create a filter string
        if StrLen(FilterTxt) > 1 then
            FilterTxt := DelStr(FilterTxt, StrLen(FilterTxt), 1);
        exit(FilterTxt);
    end;

    internal procedure FindRec(var UserTask: Record "User Task"; var FilteredUserTask: Record "User Task"; Which: Text): Boolean
    var
        Found: Boolean;
        i: Integer;
    begin
        for i := 1 to StrLen(Which) do begin
            Found := UserTask.Find(Which[i]);
            if Found then
                while Found and not ValidateAgainstFilteredRecord(UserTask, FilteredUserTask) do
                    case Which[i] of
                        '=':
                            Found := false;
                        '<', '>':
                            Found := UserTask.Find(Which[i]);
                        '-':
                            Found := UserTask.Next() <> 0;
                        '+':
                            Found := UserTask.Next(-1) <> 0;
                    end;
            if Found then
                exit(true);
        end;
        exit(false);
    end;

    internal procedure NextRec(var UserTask: Record "User Task"; var FilteredUserTask: Record "User Task"; Steps: Integer) ResultSteps: Integer
    var
        Step: Integer;
    begin
        if Steps > 0 then
            Step := 1
        else
            Step := -1;
        ResultSteps := UserTask.Next(Step);
        if ResultSteps = 0 then
            exit(0);
        while (ResultSteps <> 0) and not ValidateAgainstFilteredRecord(UserTask, FilteredUserTask) do
            ResultSteps := UserTask.Next(Step);
        exit(ResultSteps);
    end;

    local procedure ValidateAgainstFilteredRecord(var UserTask: Record "User Task"; var FilteredUserTask: Record "User Task"): Boolean
    begin
        FilteredUserTask.ID := UserTask.ID;
        exit(FilteredUserTask.Find());
    end;

}

