namespace System.Threading;

using System.Environment;

page 675 "My Job Queue"
{
    Caption = 'My Job Queue';
    Editable = false;
    PageType = ListPart;
    RefreshOnActivate = true;
    SourceTable = "Job Queue Entry";
    SourceTableView = sorting("Entry No.");

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Object Caption to Run"; Rec."Object Caption to Run")
                {
                    ApplicationArea = Basic, Suite;
                    Style = Attention;
                    StyleExpr = StatusIsError;
                    ToolTip = 'Specifies the name of the object that is selected in the Object ID to Run field.';
                    Visible = false;
                }
                field("Parameter String"; Rec."Parameter String")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a text string that is used as a parameter by the job queue when it is run.';
                    Visible = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Attention;
                    StyleExpr = StatusIsError;
                    ToolTip = 'Specifies a description of the job queue entry. You can edit and update the description on the job queue entry card. The description is also displayed in the Job Queue Entries window, but it cannot be updated there.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    Style = Attention;
                    StyleExpr = StatusIsError;
                    ToolTip = 'Specifies the status of the job queue entry. When you create a job queue entry, its status is set to On Hold. You can set the status to Ready and back to On Hold. Otherwise, status information in this field is updated automatically.';
                }
                field("Earliest Start Date/Time"; Rec."Earliest Start Date/Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the earliest date and time when the job queue entry should be run.';
                }
                field(Priority; Rec."Priority Within Category")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the priority within other jobs with the same category code.';
                    Visible = false;
                }
                field("Expiration Date/Time"; Rec."Expiration Date/Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date and time when the job queue entry is to expire, after which the job queue entry will not be run.';
                    Visible = false;
                }
                field("Job Queue Category Code"; Rec."Job Queue Category Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the code of the job queue category to which the job queue entry belongs. Choose the field to select a code from the list.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
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
            action(Cancel)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Delete';
                Image = Delete;
                ToolTip = 'Delete the record.';

                trigger OnAction()
                begin
                    Rec.Cancel();
                end;
            }
            action(Restart)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Restart';
                Image = Start;
                ToolTip = 'Stop and start the entry.';

                trigger OnAction()
                begin
                    Rec.Restart();
                end;
            }
            action(ShowRecord)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show Record';
                Image = ViewDetails;
                ToolTip = 'Show the record for the entry.';

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
                    Rec.RemoveFailedJobs(true);
                end;
            }
            action(ScheduleReport)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Schedule a Report';
                Image = "Report";
                ToolTip = 'Schedule a report.';

                trigger OnAction()
                begin
                    Page.RunModal(Page::"Schedule a Report");
                end;
            }
            action(EditJob)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Edit Job';
                Image = Edit;
                RunObject = Page "Job Queue Entry Card";
                RunPageOnRec = true;
                ShortCutKey = 'Return';
                ToolTip = 'Change the settings for the job queue entry.';
            }
            action(ScheduledTasks)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Scheduled Tasks';
                Image = ShowList;
                RunObject = Page "Scheduled Tasks";
                AccessByPermission = TableData "Scheduled Task" = R;
                ToolTip = 'View information about which tasks are ready to run in the job queue. The page also shows information about the company that each task is set up to run in.';
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        StatusIsError := Rec.Status = Rec.Status::Error;
    end;

    trigger OnOpenPage()
    begin
        Rec.SetRange("User ID", UserId());
    end;

    var
        StatusIsError: Boolean;
}

