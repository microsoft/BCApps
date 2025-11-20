// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Task;

page 1170 "User Task List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'User Tasks';
    CardPageID = "User Task Card";
    DelayedInsert = true;
    DeleteAllowed = true;
    Editable = true;
    InsertAllowed = false;
    ModifyAllowed = false;
    ODataKeyFields = ID;
    PageType = List;
    AboutTitle = 'About User Tasks';
    AboutText = 'Organize, assign, and track tasks for individuals or groups, set priorities and deadlines, link tasks to relevant pages or reports, and monitor progress until completion.';
    RefreshOnActivate = true;
    SourceTable = "User Task";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field(ID; Rec.ID)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the task.';
                    visible = false;
                }
                field(Title; Rec.Title)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the title of the task.';
                }
                field("Due DateTime"; Rec."Due DateTime")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies when the task must be completed.';
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the priority of the task.';
                }
                field("Percent Complete"; Rec."Percent Complete")
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies the progress of the task.';
                }
                field("Assigned To User Name"; Rec."Assigned To User Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies who the task is assigned to.';
                }
                field("User Task Group Assigned To"; Rec."User Task Group Assigned To")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User Task Group';
                    ToolTip = 'Specifies the group if the task has been assigned to a group of people.';
                }
                field("Created DateTime"; Rec."Created DateTime")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the task was created.';
                    Visible = false;
                }
                field("Completed DateTime"; Rec."Completed DateTime")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the task was completed.';
                    Visible = false;
                }
                field("Start DateTime"; Rec."Start DateTime")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the task must start.';
                    Visible = false;
                }
                field("Created By User Name"; Rec."Created By User Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies who created the task.';
                    Visible = false;
                }
                field("Completed By User Name"; Rec."Completed By User Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies who completed the task.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(creation)
        {
            action("User Task Groups")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'User Task Groups';
                Image = Users;
                RunObject = Page "User Task Groups";
                ToolTip = 'Add or modify groups of users that you can assign user tasks to in this company.';
            }
            action("Mark Complete")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Mark as Completed';
                Image = CheckList;
                ToolTip = 'Indicate that the task is completed. The % Complete field is set to 100.';

                trigger OnAction()
                begin
                    MarkAsComplete();
                end;
            }
            action("Go To Task Item")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Go To Task Item';
                Image = Navigate;
                ToolTip = 'Open the page or report that is associated with this task.';

                trigger OnAction()
                begin
                    Rec.RunReportOrPageLink();
                end;
            }
        }
        area(processing)
        {
            action("Delete User Tasks")
            {
                ApplicationArea = All;
                Caption = 'Delete User Tasks';
                Image = Delete;
                RunObject = Report "User Task Utility";
                ToolTip = 'Find and delete user tasks.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("User Task Groups_Promoted"; "User Task Groups")
                {
                }
                actionref("Mark Complete_Promoted"; "Mark Complete")
                {
                }
                actionref("Go To Task Item_Promoted"; "Go To Task Item")
                {
                }
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        exit(UserTaskManagement.FindRec(Rec, FilteredUserTask, Which));
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    begin
        exit(UserTaskManagement.NextRec(Rec, FilteredUserTask, Steps));
    end;

    trigger OnAfterGetRecord()
    begin
        StyleTxt := Rec.SetStyle();
    end;

    trigger OnOpenPage()
    var
        ShouldOpenToViewPendingTasks: Boolean;
    begin
        if not IsShowingMyPendingTasks then
            if Evaluate(ShouldOpenToViewPendingTasks, Rec.GetFilter(ShouldShowPendingTasks)) and ShouldOpenToViewPendingTasks then
                SetPageToShowMyPendingUserTasks();
        FilterUserTasks();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Created By" := UserSecurityId();
        Rec.Validate("Created DateTime", CurrentDateTime());
        Rec.CalcFields("Created By User Name");
    end;

    var
        FilteredUserTask: Record "User Task";
        UserTaskManagement: Codeunit "User Task Management";
        DueDateFilterOptions: Option "NONE",TODAY,THIS_WEEK;
        StyleTxt: Text;
        IsShowingMyPendingTasks: Boolean;

    [ServiceEnabled]
    procedure SetComplete()
    begin
        Rec.SetCompleted();
        Rec.Modify();
    end;

    local procedure FilterUserTasks()
    begin
        if IsShowingMyPendingTasks then begin
            UserTaskManagement.SetFiltersToShowMyUserTasks(FilteredUserTask, DueDateFilterOptions::NONE);
            Rec.CopyFilters(FilteredUserTask); // for initial search. Will get overridden by page search
            Rec.SetRange(ShouldShowPendingTasks, true); // to pass the filter on to the card when it is opened
        end;
    end;

    local procedure MarkAsComplete()
    var
        UserTask: Record "User Task";
    begin
        if IsShowingMyPendingTasks then
            UserTaskManagement.SetFiltersToShowMyUserTasks(UserTask, DueDateFilterOptions::NONE);

        CurrPage.SetSelectionFilter(UserTask);
        UserTaskManagement.CompleteTasks(UserTask);
    end;

    procedure SetPageToShowMyPendingUserTasks()
    begin
        // This functions sets up this page to show pending tasks assigned to current user
        IsShowingMyPendingTasks := true;
    end;
}

