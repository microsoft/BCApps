namespace System.Threading;

page 674 "Job Queue Log Entries"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Job Queue Log Entries';
    Editable = false;
    LinksAllowed = false;
    PageType = List;
    AboutTitle = 'About Job Queue Log Entries';
    AboutText = 'Monitor the execution status, details, and error messages of scheduled job queue entries to track processing outcomes and diagnose issues in automated tasks.';
    SourceTable = "Job Queue Log Entry";
    SourceTableView = sorting("Start Date/Time", ID)
                      order(descending);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Status; Rec.Status)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the status of the running of the job queue entry in a log.';
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the job queue entry in the log.';
                }
                field("Object Type to Run"; Rec."Object Type to Run")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the type of the object that is to be run for the job.';
                }
                field("Object ID to Run"; Rec."Object ID to Run")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the object that is to be run for the job.';
                }
                field("Object Caption to Run"; Rec."Object Caption to Run")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name or caption of the object that was run for the job.';
                }
                field("Parameter String"; Rec."Parameter String")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the parameter string of the corresponding job.';
                }
                field("Start Date/Time"; Rec."Start Date/Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date and time when the job was started.';
                }
                field(Duration; Rec.Duration())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Duration';
                    ToolTip = 'Specifies how long the job queue log entry will take to run.';
                }
                field("End Date/Time"; Rec."End Date/Time")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the date and time when the job ended.';
                    Visible = false;
                }
                field(ID; Rec.ID)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID of the job queue entry in the log.';
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Error Message';
                    ToolTip = 'Specifies an error that occurred in the job queue.';

                    trigger OnAssistEdit()
                    begin
                        Rec.ShowErrorMessage();
                    end;
                }
                field("Job Queue Category Code"; Rec."Job Queue Category Code")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the category code for the entry in the job queue log.';
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Delete7days)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Delete Entries Older Than 7 Days';
                Image = ClearLog;
                ToolTip = 'Clear the list of log entries that are older than 7 days.';

                trigger OnAction()
                begin
                    Rec.DeleteEntries(7);
                end;
            }
            action(Delete0days)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Delete All Entries';
                Image = Delete;
                ToolTip = 'Clear the list of all log entries.';

                trigger OnAction()
                begin
                    Rec.DeleteEntries(0);
                end;
            }
            action("Show Error Message")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show Error Message';
                Enabled = Rec.Status = Rec.Status::Error;
                Image = Error;
                ToolTip = 'Show the error message that has stopped the entry.';

                trigger OnAction()
                begin
                    Rec.ShowErrorMessage();
                end;
            }
            action("Show Job Queue Entry")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show Job Queue Entry';
                Image = ViewJob;
                RunObject = Page "Job Queue Entries";
                RunPageLink = ID = field(ID);
                ToolTip = 'View the job queue entries.';
            }
            action("Show Error Call Stack")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Show Error Call Stack';
                Enabled = Rec.Status = Rec.Status::Error;
                Image = StepInto;
                ToolTip = 'Show the call stack for the error that has stopped the entry.';

                trigger OnAction()
                begin
                    Rec.ShowErrorCallStack();
                end;
            }
            action(SetStatusToError)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Set Status to Error';
                Image = DefaultFault;
                ToolTip = 'Change the status of the entry.';

                trigger OnAction()
                begin
                    if Confirm(JobQueueEntryRunningQst, false) then
                        Rec.MarkAsError();
                end;
            }
        }
        area(navigation)
        {
            action(Details)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Details';
                Image = Log;
                ToolTip = 'View detailed information about the job queue log entry.';

                trigger OnAction()
                begin
                    OnShowDetails(Rec);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Details_Promoted; Details)
                {
                }
                actionref("Show Error Message_Promoted"; "Show Error Message")
                {
                }
                actionref("Show Error Call Stack_Promoted"; "Show Error Call Stack")
                {
                }
                actionref(SetStatusToError_Promoted; SetStatusToError)
                {
                }
                actionref("Show Job Queue Entry_Promoted"; "Show Job Queue Entry")
                {
                }
                group(Category_Delete)
                {
                    Caption = 'Delete';

                    actionref(Delete0days_Promoted; Delete0days)
                    {
                    }
                    actionref(Delete7days_Promoted; Delete7days)
                    {
                    }
                }
            }
            group(Category_Report)
            {
                Caption = 'Reports';

            }
        }
    }

    var
        JobQueueEntryRunningQst: Label 'This job queue entry may be still running. If you set the status to Error, it may keep running in the background. Are you sure you want to set the status to Error?';

    [IntegrationEvent(false, false)]
    local procedure OnShowDetails(JobQueueLogEntry: Record "Job Queue Log Entry")
    begin
    end;
}

