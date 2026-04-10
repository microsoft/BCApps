namespace Microsoft.AccountantPortal;

using Microsoft.Foundation.Task;

page 1316 "Accountant Portal User Tasks"
{
    Caption = 'Accountant Portal User Tasks';
    PageType = List;
    SourceTable = "User Task";
    SourceTableView = sorting(ID);

    layout
    {
        area(content)
        {
            group(Task)
            {
                field(ID; Rec.ID)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'ID', Locked = true;
                    ToolTip = 'Specifies the ID that applies.';
                }
                field(Title; Rec.Title)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Subject', Locked = true;
                    ToolTip = 'Specifies the title of the task.';
                }
                field("Due DateTime"; Rec."Due DateTime")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Due Date', Locked = true;
                    ToolTip = 'Specifies when the task must be completed.';
                }
                field("Percent Complete"; Rec."Percent Complete")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '% Complete', Locked = true;
                    ToolTip = 'Specifies the progress of the task.';
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Priority', Locked = true;
                    ToolTip = 'Specifies the priority of the task.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Description', Locked = true;
                    ToolTip = 'Specifies a descriptions of the task.';
                }
                field(Created_By_Name; CreatedByName)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Created_By_Name', Locked = true;
                    ToolTip = 'Specifies the string value name of the user who created the task.';
                }
                field("Created DateTime"; Rec."Created DateTime")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Created Date', Locked = true;
                    ToolTip = 'Specifies when the task was created.';
                }
                field("Start DateTime"; Rec."Start DateTime")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Start Date', Locked = true;
                    ToolTip = 'Specifies when the task must start.';
                }
                field("Assigned To"; Rec."Assigned To")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Assigned To', Locked = true;
                    ToolTip = 'Specifies who the task is assigned to.';
                }
                field(Link; Link)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Link', Locked = true;
                    ToolTip = 'Specifies the string value of web link to this user task.';
                }
                field("User Task Group Assigned To"; Rec."User Task Group Assigned To")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'User Task Group Assigned To', Locked = true;
                    ToolTip = 'Specifies the group if the task has been assigned to a group of people.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("Created By User Name");
        CreatedByName := Rec."Created By User Name";
        Link := GetUrl(CLIENTTYPE::Web, CompanyName, OBJECTTYPE::Page, 1171, Rec) + '&Mode=Edit';
        if IsNullGuid(Rec."Assigned To") then
            Rec."Assigned To" := UserSecurityId();
    end;

    trigger OnOpenPage()
    begin
        Rec.Reset();
        UserTaskManagement.SetFiltersToShowMyUserTasks(Rec, DueDateFilterOptions::NONE);
    end;

    var
        UserTaskManagement: Codeunit "User Task Management";
        CreatedByName: Code[50];
        Link: Text;
        DueDateFilterOptions: Option "NONE",TODAY,THIS_WEEK;
}

