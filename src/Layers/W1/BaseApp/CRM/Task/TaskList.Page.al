// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Task;

using Microsoft.CRM.Campaign;
using Microsoft.CRM.Comment;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Team;

page 5096 "Task List"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Task List';
    CardPageID = "Task Card";
    DataCaptionExpression = GetCaption();
    Editable = false;
    PageType = List;
    AboutTitle = 'About Task List';
    AboutText = 'Manage and track tasks across multiple companies by assigning, prioritizing, sorting, and updating the status of work items for yourself and others, with options to link tasks to contacts, teams, campaigns, and opportunities.';
    SourceTable = "To-do";
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                Editable = false;
                ShowCaption = false;
                field(Closed; Rec.Closed)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that the task is closed.';
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the date when the task should be started. There are certain rules for how dates should be entered found in How to: Enter Dates and Times.';
                }
                field(Type; Rec.Type)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the type of the task.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the description of the task.';
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the priority of the task.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the status of the task. There are five options: Not Started, In Progress, Completed, Waiting and Postponed.';
                }
                field("Organizer To-do No."; Rec."Organizer To-do No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the organizer''s task. The field is not editable.';
                }
                field("Date Closed"; Rec."Date Closed")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the date the task was closed.';
                }
                field(Canceled; Rec.Canceled)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that the task has been canceled.';
                }
                field(Comment; Rec.Comment)
                {
                    ApplicationArea = Comments;
                    ToolTip = 'Specifies that a comment has been assigned to the task.';
                }
                field("Contact No."; Rec."Contact No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the contact linked to the task.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Task: Record "To-do";
                        Cont: Record Contact;
                    begin
                        if Rec.Type = Rec.Type::Meeting then begin
                            Task.SetRange("No.", Rec."No.");
                            PAGE.RunModal(PAGE::"Attendee Scheduling", Task);
                        end else begin
                            if Cont.Get(Rec."Contact No.") then;
                            if PAGE.RunModal(0, Cont) = ACTION::LookupOK then;
                        end;
                    end;
                }
                field("Contact Company No."; Rec."Contact Company No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the contact number of the company for which the contact involved in the task works.';
                    Visible = false;
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code of the salesperson assigned to the task.';
                }
                field("Team Code"; Rec."Team Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code of the team to which the task is assigned.';
                }
                field("Campaign No."; Rec."Campaign No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the campaign to which the task is linked.';
                }
                field("Opportunity No."; Rec."Opportunity No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the opportunity to which the task is linked.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
            }
            group(Control55)
            {
                ShowCaption = false;
                field("Contact Name"; Rec."Contact Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Contact Name';
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the contact to which this task has been assigned.';
                }
                field("Contact Company Name"; Rec."Contact Company Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    DrillDown = false;
                    ToolTip = 'Specifies the name of the company for which the contact involved in the task works.';
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
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group(Task)
            {
                Caption = 'Task';
                Image = Task;
                action("Co&mment")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mment';
                    Image = ViewComments;
                    RunObject = Page "Rlshp. Mgt. Comment Sheet";
                    RunPageLink = "Table Name" = const("To-do"),
                                  "No." = field("Organizer To-do No."),
                                  "Sub No." = const(0);
                    ToolTip = 'View or add comments.';
                }
                action("Interaction Log E&ntries")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Interaction Log E&ntries';
                    Image = InteractionLog;
                    RunObject = Page "Interaction Log Entries";
                    RunPageLink = "To-do No." = field("Organizer To-do No.");
                    RunPageView = sorting("To-do No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View interaction log entries for the task.';
                }
                action("Postponed &Interactions")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Postponed &Interactions';
                    Image = PostponedInteractions;
                    RunObject = Page "Postponed Interactions";
                    RunPageLink = "To-do No." = field("Organizer To-do No.");
                    RunPageView = sorting("To-do No.");
                    ToolTip = 'View postponed interactions for the task.';
                }
                action("A&ttendee Scheduling")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'A&ttendee Scheduling';
                    Image = ProfileCalender;
                    ToolTip = 'View the status of a scheduled meeting.';

                    trigger OnAction()
                    var
                        Task: Record "To-do";
                    begin
                        Task.Get(Rec."Organizer To-do No.");
                        PAGE.RunModal(PAGE::"Attendee Scheduling", Task);
                    end;
                }
            }
        }
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Assign Activities")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Assign Activities';
                    Image = Allocate;
                    ToolTip = 'View all the tasks that have been assigned to salespeople and teams. A task can be organizing meetings, making phone calls, and so on.';

                    trigger OnAction()
                    var
                        TempTask: Record "To-do" temporary;
                    begin
                        TempTask.AssignActivityFromTask(Rec);
                    end;
                }
                action(MakePhoneCall)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Make &Phone Call';
                    Image = Calls;
                    ToolTip = 'Call the selected contact.';

                    trigger OnAction()
                    var
                        TempSegmentLine: Record "Segment Line" temporary;
                        ContactNo: Code[20];
                        ContCompanyNo: Code[20];
                    begin
                        if Rec."Contact No." <> '' then
                            ContactNo := Rec."Contact No."
                        else
                            ContactNo := CopyStr(Rec.GetFilter("Contact No."), 1, MaxStrLen(ContactNo));
                        if Rec."Contact Company No." <> '' then
                            ContCompanyNo := Rec."Contact Company No."
                        else
                            ContCompanyNo := CopyStr(Rec.GetFilter("Contact Company No."), 1, MaxStrLen(ContCompanyNo));
                        if ContactNo = '' then begin
                            if (Rec.Type = Rec.Type::Meeting) and (Rec."Team Code" = '') then
                                Error(PhoneCallOnlyInAttendeeSchedulingErr);
                            Error(MustSelectTaskWithContactErr);
                        end;
                        TempSegmentLine."To-do No." := Rec."No.";
                        TempSegmentLine."Contact No." := ContactNo;
                        TempSegmentLine."Contact Company No." := ContCompanyNo;
                        TempSegmentLine."Campaign No." := Rec."Campaign No.";
                        TempSegmentLine."Salesperson Code" := Rec."Salesperson Code";
                        TempSegmentLine.CreatePhoneCall();
                    end;
                }
                action("Delete Canceled Tasks")
                {
                    ApplicationArea = All;
                    Caption = 'Delete Canceled Tasks';
                    Image = Delete;
                    RunObject = Report "Delete Tasks";
                    ToolTip = 'Find and delete canceled tasks.';
                }
            }
            action("&Create Task")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = '&Create Task';
                Image = NewToDo;
                ToolTip = 'Create a new task.';

                trigger OnAction()
                var
                    TempTask: Record "To-do" temporary;
                begin
                    TempTask.CreateTaskFromTask(Rec);
                end;
            }
            action("Edit Organizer Task")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Edit Organizer Task';
                Image = Edit;
                RunObject = Page "Task Card";
                RunPageLink = "No." = field("Organizer To-do No.");
                ToolTip = 'View general information about the task such as type, description, priority and status of the task, as well as the salesperson or team the task is assigned to.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Create Task_Promoted"; "&Create Task")
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        Rec.CalcFields("Contact Name", "Contact Company Name");
    end;

    trigger OnAfterGetRecord()
    begin
        ContactNoOnFormat(Format(Rec."Contact No."));
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        RecordsFound := Rec.Find(Which);
        exit(RecordsFound);
    end;

    var
        RecordsFound: Boolean;
        MultipleTxt: Label '(Multiple)';
        UntitledTxt: Label 'untitled';
        PhoneCallOnlyInAttendeeSchedulingErr: Label 'The Make Phone Call function for this task is available only on the Attendee Scheduling window.';
        MustSelectTaskWithContactErr: Label 'You must select a task with a contact assigned to it before you can use the Make Phone Call function.';

    procedure GetCaption() CaptionStr: Text
    var
        Campaign: Record Campaign;
        Contact: Record Contact;
        Contact2: Record Contact;
        Opportunity: Record Opportunity;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        SegmentHeader: Record "Segment Header";
        Team: Record Team;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCaption(Rec, CaptionStr, IsHandled);
        if not IsHandled then begin
            if Contact.Get(Rec.GetFilter("Contact Company No.")) then begin
                Contact2.Get(Rec.GetFilter("Contact Company No."));
                if Contact2."No." <> Contact."No." then
                        CaptionStr := CopyStr(Contact."No." + ' ' + Contact.Name, 1, MaxStrLen(CaptionStr));
            end;
            if Contact.Get(Rec.GetFilter("Contact No.")) then
                CaptionStr := CopyStr(CaptionStr + ' ' + Contact."No." + ' ' + Contact.Name, 1, MaxStrLen(CaptionStr));
            if SalespersonPurchaser.Get(Rec.GetFilter("Salesperson Code")) then
                CaptionStr := CopyStr(CaptionStr + ' ' + SalespersonPurchaser.Code + ' ' + SalespersonPurchaser.Name, 1, MaxStrLen(CaptionStr));
            if Team.Get(Rec.GetFilter("Team Code")) then
                CaptionStr := CopyStr(CaptionStr + ' ' + Team.Code + ' ' + Team.Name, 1, MaxStrLen(CaptionStr));
            if Campaign.Get(Rec.GetFilter("Campaign No.")) then
                CaptionStr := CopyStr(CaptionStr + ' ' + Campaign."No." + ' ' + Campaign.Description, 1, MaxStrLen(CaptionStr));
            if Opportunity.Get(Rec.GetFilter("Opportunity No.")) then
                CaptionStr := CopyStr(CaptionStr + ' ' + Opportunity."No." + ' ' + Opportunity.Description, 1, MaxStrLen(CaptionStr));
            if SegmentHeader.Get(Rec.GetFilter("Segment No.")) then
                CaptionStr := CopyStr(CaptionStr + ' ' + SegmentHeader."No." + ' ' + SegmentHeader.Description, 1, MaxStrLen(CaptionStr));
            if CaptionStr = '' then
                CaptionStr := UntitledTxt;
        end;

        OnAfterGetCaption(Rec, CaptionStr);
    end;

    local procedure ContactNoOnFormat(Text: Text[1024])
    begin
        if Rec.Type = Rec.Type::Meeting then
            Text := MultipleTxt;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCaption(var ToDo: Record "To-do"; var CaptionStr: Text; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetCaption(var ToDo: Record "To-do"; var CaptionStr: Text)
    begin
    end;

}

