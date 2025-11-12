// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Task;

using System.Security.AccessControl;
using System.Security.User;
using System.Reflection;

page 1171 "User Task Card"
{
    Caption = 'User Task';
    PageType = Card;
    SourceTable = "User Task";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(Title; Rec.Title)
                {
                    ApplicationArea = Basic, Suite;
                    ShowMandatory = true;
                    ToolTip = 'Specifies the title of the task.';
                }
                field(MultiLineTextControl; MultiLineTextControl)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Task Description';
                    MultiLine = true;
                    ToolTip = 'Specifies what the task is about.';

                    trigger OnValidate()
                    begin
                        Rec.SetDescription(MultiLineTextControl);
                    end;
                }
                field("Created By User Name"; Rec."Created By User Name")
                {
                    ApplicationArea = Basic, Suite;
                    Editable = false;
                    Enabled = false;
                    Importance = Additional;
                    ToolTip = 'Specifies who created the task.';
                }
                field("Created DateTime"; Rec."Created DateTime")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies when the task was created.';
                }
            }
            group(Status)
            {
                Caption = 'Status';
                field("Assigned To User Name"; Rec."Assigned To User Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies who the task is assigned to.';

                    trigger OnAssistEdit()
                    var
                        User: Record User;
                        Users: Page Users;
                    begin
                        if User.Get(Rec."Assigned To") then
                            Users.SetRecord(User);

                        Users.LookupMode := true;
                        if Users.RunModal() = ACTION::LookupOK then begin
                            Users.GetRecord(User);
                            Rec.Validate("Assigned To", User."User Security ID");
                            CurrPage.Update(true);
                        end;
                    end;
                }
                field("User Task Group Assigned To"; Rec."User Task Group Assigned To")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User Task Group';
                    ToolTip = 'Specifies the group if the task has been assigned to a group of people.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Due DateTime"; Rec."Due DateTime")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the task must be completed.';
                }
                field("Percent Complete"; Rec."Percent Complete")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the progress of the task.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field("Start DateTime"; Rec."Start DateTime")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies when the task must start.';
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    ToolTip = 'Specifies the priority of the task.';
                }
                field("Completed By User Name"; Rec."Completed By User Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    Importance = Additional;
                    ToolTip = 'Specifies who completed the task.';

                    trigger OnAssistEdit()
                    var
                        User: Record User;
                        Users: Page Users;
                    begin
                        if User.Get(Rec."Completed By") then
                            Users.SetRecord(User);

                        Users.LookupMode := true;
                        if Users.RunModal() = ACTION::LookupOK then begin
                            Users.GetRecord(User);
                            Rec.Validate("Completed By", User."User Security ID");
                            CurrPage.Update(true);
                        end;
                    end;
                }
                field("Completed DateTime"; Rec."Completed DateTime")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                    ToolTip = 'Specifies when the task was completed.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
            }
            group("Task Item")
            {
                Caption = 'Task Item';
                field("Object Type"; Rec."Object Type")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    OptionCaption = ',,,Report,,,,,Page';
                    ToolTip = 'Specifies the type of window that the task opens.';

                    trigger OnValidate()
                    begin
                        // Clear out the values for object id if it exists.
                        if Rec."Object ID" <> 0 then
                            Rec."Object ID" := 0;
                    end;
                }
                field("Object ID"; Rec."Object ID")
                {
                    ApplicationArea = Basic, Suite;
                    BlankZero = true;
                    CaptionClass = GetObjectTypeCaption();
                    Lookup = true;
                    ToolTip = 'Specifies the window that the task opens.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        AllObjWithCaption: Record AllObjWithCaption;
                        AllObjectsWithCaption: Page "All Objects with Caption";
                    begin
                        // If object type is empty then show both pages / reports in lookup
                        AllObjWithCaption.FilterGroup(2);
                        case Rec."Object Type" of
                            0:
                                begin
                                    AllObjWithCaption.SetFilter("Object Type", 'Page|Report');
                                    AllObjWithCaption.SetFilter("Object Subtype", '%1|%2', '', 'List');
                                end;
                            AllObjWithCaption."Object Type"::Page:
                                begin
                                    AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Page);
                                    AllObjWithCaption.SetRange("Object Subtype", 'List');
                                end;
                            else
                                AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Report);
                        end;
                        AllObjWithCaption.FilterGroup(0);

                        AllObjectsWithCaption.IsObjectTypeVisible(false);
                        AllObjectsWithCaption.SetTableView(AllObjWithCaption);

                        AllObjectsWithCaption.LookupMode := true;
                        if AllObjectsWithCaption.RunModal() = ACTION::LookupOK then begin
                            AllObjectsWithCaption.GetRecord(AllObjWithCaption);
                            Rec."Object ID" := AllObjWithCaption."Object ID";
                            Rec."Object Type" := AllObjWithCaption."Object Type";
                        end;
                    end;

                    trigger OnValidate()
                    var
                        AllObjWithCaption: Record AllObjWithCaption;
                    begin
                        if Rec."Object Type" = AllObjWithCaption."Object Type"::Page then begin
                            AllObjWithCaption.SetRange("Object Type", AllObjWithCaption."Object Type"::Page);
                            AllObjWithCaption.SetRange("Object ID", Rec."Object ID");
                            if AllObjWithCaption.FindFirst() then
                                if AllObjWithCaption."Object Subtype" <> 'List' then
                                    Error(InvalidPageTypeErr);
                        end;
                    end;
                }
                field(ObjectName; DisplayObjectName())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Resource Name';
                    Enabled = false;
                    ToolTip = 'Specifies the name of the resource that is assigned to the task.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
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
            action("Mark Completed")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Mark Completed';
                Enabled = IsMarkCompleteEnabled;
                Image = Completed;
                ToolTip = 'Mark the task as completed.';

                trigger OnAction()
                begin
                    // Marks the current task as completed.
                    Rec.SetCompleted();
                    CurrPage.Update(true);
                end;
            }
            action(Recurrence)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Recurrence';
                Image = Refresh;
                ToolTip = 'Make this a recurring task.';

                trigger OnAction()
                var
                    UserTaskRecurrence: Page "User Task Recurrence";
                begin
                    UserTaskRecurrence.SetInitialData(Rec);
                    UserTaskRecurrence.RunModal();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("Go To Task Item_Promoted"; "Go To Task Item")
                {
                }
                actionref("Mark Completed_Promoted"; "Mark Completed")
                {
                }
                actionref(Recurrence_Promoted; Recurrence)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        ShouldOpenToViewPendingTasks: Boolean;
    begin
        if not IsShowingMyPendingTasks then
            if Evaluate(ShouldOpenToViewPendingTasks, Rec.GetFilter(ShouldShowPendingTasks)) and ShouldOpenToViewPendingTasks then
                SetPageToShowMyPendingUserTasks();
        FilterUserTasks();
    end;

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
        MultiLineTextControl := Rec.GetDescription();
        IsMarkCompleteEnabled := not Rec.IsCompleted();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Created By" := UserSecurityId();
        Rec.Validate("Created DateTime", CurrentDateTime());
        Rec.CalcFields("Created By User Name");

        Clear(MultiLineTextControl);
    end;

    var
        FilteredUserTask: Record "User Task";
        UserTaskManagement: Codeunit "User Task Management";
        IsShowingMyPendingTasks: Boolean;
        InvalidPageTypeErr: Label 'You must specify a list page.';
        PageTok: Label 'Page';
        ReportTok: Label 'Report';

    protected var
        MultiLineTextControl: Text;
        IsMarkCompleteEnabled: Boolean;

    local procedure DisplayObjectName(): Text
    var
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        AllObjWithCaption.SetRange("Object Type", Rec."Object Type");
        AllObjWithCaption.SetRange("Object ID", Rec."Object ID");
        if AllObjWithCaption.FindFirst() then
            exit(AllObjWithCaption."Object Name");
    end;

    local procedure GetObjectTypeCaption(): Text
    begin
        if Rec."Object Type" = Rec."Object Type"::Page then
            exit(PageTok);

        exit(ReportTok);
    end;

    local procedure FilterUserTasks()
    var
        DueDateFilterOptions: Option "NONE",TODAY,THIS_WEEK;
    begin
        if IsShowingMyPendingTasks then
            UserTaskManagement.SetFiltersToShowMyUserTasks(FilteredUserTask, DueDateFilterOptions::NONE);
    end;

    procedure SetPageToShowMyPendingUserTasks()
    begin
        // This functions sets up this page to show pending tasks assigned to current user
        IsShowingMyPendingTasks := true;
    end;
}

