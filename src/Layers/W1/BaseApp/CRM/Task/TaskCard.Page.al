// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Task;

using Microsoft.CRM.Comment;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Segment;
using System.Environment;

page 5098 "Task Card"
{
    Caption = 'Task Card';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "To-do";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                Editable = PagePartsEditable;
                field("No."; Rec."No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the description of the task.';
                }
                field(Location; Rec.Location)
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = LocationEnable;
                    ToolTip = 'Specifies the location where the meeting will take place.';
                    Visible = not IsSoftwareAsAService;
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code of the salesperson assigned to the task.';

                    trigger OnValidate()
                    begin
                        SalespersonCodeOnAfterValidate();
                    end;
                }
                field("No. of Attendees"; Rec."No. of Attendees")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = NoOfAttendeesEnable;
                    ToolTip = 'Specifies the number of attendees for the meeting. click the field to view the Attendee Scheduling card.';

                    trigger OnDrillDown()
                    begin
                        Rec.Modify();
                        Commit();
                        PAGE.RunModal(PAGE::"Attendee Scheduling", Rec);
                        Rec.Get(Rec."No.");
                        CurrPage.Update();
                    end;
                }
                field("Attendees Accepted No."; Rec."Attendees Accepted No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = AttendeesAcceptedNoEnable;
                    ToolTip = 'Specifies the number of attendees that have confirmed their participation in the meeting.';

                    trigger OnDrillDown()
                    begin
                        Rec.Modify();
                        Commit();
                        PAGE.RunModal(PAGE::"Attendee Scheduling", Rec);
                        Rec.Get(Rec."No.");
                        CurrPage.Update();
                    end;
                }
                field("Contact No."; Rec."Contact No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = ContactNoEditable;
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
                            if PAGE.RunModal(0, Cont) = ACTION::LookupOK then begin
                                Rec.Validate("Contact No.", Cont."No.");
                                CurrPage.Update();
                            end;
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        ContactNoOnAfterValidate();
                    end;
                }
                field("Contact Name"; Rec."Contact Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = false;
                    ToolTip = 'Specifies the name of the contact to which this task has been assigned.';
                }
                field(ContactPhoneNo; Contact."Phone No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Phone No.';
                    Importance = Additional;
                    Editable = false;
                    ExtendedDatatype = PhoneNo;
                    ToolTip = 'Specifies the telephone number of the contact to which this task has been assigned.';
                }
                field(ContactMobilePhoneNo; Contact."Mobile Phone No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Mobile Phone No.';
                    Importance = Additional;
                    Editable = false;
                    ExtendedDatatype = PhoneNo;
                    ToolTip = 'Specifies the mobile telephone number of the contact to which this task has been assigned.';
                }
                field(ContactEmail; Contact."E-Mail")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Email';
                    Importance = Additional;
                    Editable = false;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Specifies the email address of the contact to which this task has been assigned.';
                }
                field("Contact Company Name"; Rec."Contact Company Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = false;
                    ToolTip = 'Specifies the name of the company for which the contact involved in the task works.';
                }
                field("Team Code"; Rec."Team Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code of the team to which the task is assigned.';

                    trigger OnValidate()
                    begin
                        TeamCodeOnAfterValidate();
                    end;
                }
                field("Completed By"; Rec."Completed By")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = CompletedByEditable;
                    Enabled = CompletedByEnable;
                    ToolTip = 'Specifies the salesperson who completed this team task.';

                    trigger OnValidate()
                    begin
                        SwitchCardControls();
                    end;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the status of the task. There are five options: Not Started, In Progress, Completed, Waiting and Postponed.';
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the priority of the task.';
                }
                field(TypeSaaS; Rec.Type)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Type';
                    ToolTip = 'Specifies the type of the task.';
                    Visible = IsSoftwareAsAService;

                    trigger OnValidate()
                    begin
                        TypeOnAfterValidate();
                    end;
                }
                field(TypeOnPrem; Rec.Type)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Type';
                    ToolTip = 'Specifies the type of the task.';
                    Visible = not IsSoftwareAsAService;

                    trigger OnValidate()
                    begin
                        TypeOnAfterValidate();
                    end;
                }
                field(AllDayEvent; Rec."All Day Event")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'All Day Event';
                    Enabled = AllDayEventEnable;
                    ToolTip = 'Specifies that the task of the Meeting type is an all-day event, which is an activity that lasts 24 hours or longer.';

                    trigger OnValidate()
                    begin
                        AllDayEventOnAfterValidate();
                    end;
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the date when the task should be started. There are certain rules for how dates should be entered found in How to: Enter Dates and Times.';
                }
                field(StartTime; Rec."Start Time")
                {
                    ApplicationArea = RelationshipMgmt;
                    Enabled = StartTimeEnable;
                    ToolTip = 'Specifies the time when the task of the Meeting type should be started.';
                }
                field(Duration; Rec.Duration)
                {
                    ApplicationArea = RelationshipMgmt;
                    BlankZero = true;
                    Enabled = DurationEnable;
                    ToolTip = 'Specifies the duration of the task of the Meeting type.';
                }
                field(EndingDate; Rec."Ending Date")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Ending Date';
                    ToolTip = 'Specifies the date of when the task should end. There are certain rules for how dates should be entered. For more information, see How to: Enter Dates and Times.';
                }
                field(EndingTime; Rec."Ending Time")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Ending Time';
                    Enabled = EndingTimeEnable;
                    ToolTip = 'Specifies the time of when the task of the Meeting type should end.';
                }
                field(Canceled; Rec.Canceled)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that the task has been canceled.';

                    trigger OnValidate()
                    begin
                        SwitchCardControls();
                    end;
                }
                field(Closed; Rec.Closed)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that the task is closed.';

                    trigger OnValidate()
                    begin
                        SwitchCardControls();
                    end;
                }
                field("Date Closed"; Rec."Date Closed")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the date the task was closed.';
                }
            }
            group("Related Activities")
            {
                Caption = 'Related Activities';
                Editable = PagePartsEditable;
                field("Campaign No."; Rec."Campaign No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the campaign to which the task is linked.';

                    trigger OnValidate()
                    begin
                        CampaignNoOnAfterValidate();
                    end;
                }
                field("Campaign Description"; Rec."Campaign Description")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = false;
                    ToolTip = 'Specifies the description of the campaign to which the task is linked.';
                }
                field("Opportunity No."; Rec."Opportunity No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the number of the opportunity to which the task is linked.';

                    trigger OnValidate()
                    begin
                        OpportunityNoOnAfterValidate();
                    end;
                }
                field("Opportunity Description"; Rec."Opportunity Description")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = false;
                    ToolTip = 'Specifies a description of the opportunity related to the task. The description is copied from the opportunity card.';
                }
            }
            group(Recurring)
            {
                Caption = 'Recurring';
                Editable = PagePartsEditable;
                field(Control39; Rec.Recurring)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that the task occurs periodically.';

                    trigger OnValidate()
                    begin
                        RecurringOnPush();
                    end;
                }
                field("Recurring Date Interval"; Rec."Recurring Date Interval")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = RecurringDateIntervalEditable;
                    Enabled = RecurringDateIntervalEnable;
                    ToolTip = 'Specifies the date formula to assign automatically a recurring task to a salesperson or team.';
                }
                field("Calc. Due Date From"; Rec."Calc. Due Date From")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = CalcDueDateFromEditable;
                    Enabled = CalcDueDateFromEnable;
                    ToolTip = 'Specifies the date to use to calculate the date on which the next task should be completed.';
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
            group("Ta&sk")
            {
                Caption = 'Ta&sk';
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
                    begin
                        if Rec.Type <> Rec.Type::Meeting then
                            Error(CannotSelectAttendeesErr, Format(Rec.Type));

                        PAGE.RunModal(PAGE::"Attendee Scheduling", Rec);
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
                        TempTask.AssignActivityFromTask(Rec)
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
                    begin
                        if Rec."Contact No." = '' then begin
                            if (Rec.Type = Rec.Type::Meeting) and (Rec."Team Code" = '') then
                                Error(MakePhoneCallIsNotAvailableErr);
                            Error(MustAssignContactErr);
                        end;
                        TempSegmentLine."To-do No." := Rec."No.";
                        TempSegmentLine."Contact No." := Rec."Contact No.";
                        TempSegmentLine."Contact Company No." := Rec."Contact Company No.";
                        TempSegmentLine."Campaign No." := Rec."Campaign No.";
                        TempSegmentLine."Salesperson Code" := Rec."Salesperson Code";
                        TempSegmentLine.CreatePhoneCall();
                    end;
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

    trigger OnAfterGetRecord()
    begin
        SwitchCardControls();
        if Rec."No." <> Rec."Organizer To-do No." then
            PagePartsEditable := false
        else
            PagePartsEditable := true;
        SetRecurringEditable();
        EnableFields();
        ContactNoOnFormat(Format(Rec."Contact No."));
        Contact.GetOrClear(Rec."Contact No.");
    end;

    trigger OnInit()
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        CalcDueDateFromEnable := true;
        RecurringDateIntervalEnable := true;
        CompletedByEnable := true;
        AttendeesAcceptedNoEnable := true;
        NoOfAttendeesEnable := true;
        AllDayEventEnable := true;
        LocationEnable := true;
        DurationEnable := true;
        EndingTimeEnable := true;
        StartTimeEnable := true;
        CompletedByEditable := true;
        CalcDueDateFromEditable := true;
        RecurringDateIntervalEditable := true;
        ContactNoEditable := true;
        IsSoftwareAsAService := EnvironmentInfo.IsSaaS();
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if (Rec."Team Code" = '') and (Rec."Salesperson Code" = '') then
            Error(
              TaskWillAlwaysHaveResponsiblePersonTxt, Rec.TableCaption(), Rec.FieldCaption("Salesperson Code"), Rec.FieldCaption("Team Code"));

        if (Rec.Type = Rec.Type::Meeting) and (not Rec."All Day Event") then begin
            if Rec."Start Time" = 0T then
                Error(TaskTypeRequiresFieldErr, Rec.TableCaption(), Rec.Type, Rec.FieldCaption("Start Time"));
            if Rec.Duration = 0 then
                Error(TaskTypeRequiresFieldErr, Rec.TableCaption(), Rec.Type, Rec.FieldCaption(Duration));
        end;
    end;

    var
        Contact: Record Contact;
#pragma warning disable AA0470
        TaskWillAlwaysHaveResponsiblePersonTxt: Label 'The %1 will always have either the %2 or %3 assigned.';
        TaskTypeRequiresFieldErr: Label 'The %1 of the %2 type must always have the %3 assigned.';
#pragma warning restore AA0470
        CannotSelectAttendeesErr: Label 'You cannot select attendees for a task of the ''%1'' type.', Comment = '%1 = Task Type';
        MakePhoneCallIsNotAvailableErr: Label 'The Make Phone Call function for this task is available only in the Attendee Scheduling window.';
        MustAssignContactErr: Label 'You must assign a contact to this task before you can use the Make Phone Call function.';
        MultipleTxt: Label '(Multiple)';
        RecurringDateIntervalEditable: Boolean;
        CalcDueDateFromEditable: Boolean;
        CompletedByEditable: Boolean;
        StartTimeEnable: Boolean;
        EndingTimeEnable: Boolean;
        DurationEnable: Boolean;
        LocationEnable: Boolean;
        AllDayEventEnable: Boolean;
        NoOfAttendeesEnable: Boolean;
        AttendeesAcceptedNoEnable: Boolean;
        CompletedByEnable: Boolean;
        RecurringDateIntervalEnable: Boolean;
        CalcDueDateFromEnable: Boolean;
        IsSoftwareAsAService: Boolean;
        PagePartsEditable: Boolean;

    protected var
        ContactNoEditable: Boolean;

    procedure SetRecurringEditable()
    begin
        RecurringDateIntervalEditable := Rec.Recurring;
        CalcDueDateFromEditable := Rec.Recurring;
    end;

    procedure EnableFields()
    begin
        RecurringDateIntervalEnable := Rec.Recurring;
        CalcDueDateFromEnable := Rec.Recurring;

        if not Rec.Recurring then begin
            Evaluate(Rec."Recurring Date Interval", '');
            Clear(Rec."Calc. Due Date From");
        end;

        if Rec.Type = Rec.Type::Meeting then begin
            StartTimeEnable := not Rec."All Day Event";
            EndingTimeEnable := not Rec."All Day Event";
            DurationEnable := not Rec."All Day Event";
            LocationEnable := true;
            AllDayEventEnable := true;
        end else begin
            StartTimeEnable := Rec.Type = Rec.Type::"Phone Call";
            EndingTimeEnable := Rec.Type = Rec.Type::"Phone Call";
            DurationEnable := Rec.Type = Rec.Type::"Phone Call";
            LocationEnable := false;
            AllDayEventEnable := false;
        end;

        OnEnableFieldsOnBeforeGetEndDateTime(Rec, StartTimeEnable, EndingTimeEnable, DurationEnable, LocationEnable, AllDayEventEnable);
        Rec.GetEndDateTime();
    end;

    local procedure SwitchCardControls()
    begin
        if Rec.Type = Rec.Type::Meeting then begin
            ContactNoEditable := false;

            NoOfAttendeesEnable := true;
            AttendeesAcceptedNoEnable := true;
        end else begin
            ContactNoEditable := true;

            NoOfAttendeesEnable := false;
            AttendeesAcceptedNoEnable := false;
        end;
        if Rec."Team Code" = '' then
            CompletedByEnable := false
        else begin
            CompletedByEnable := true;
            CompletedByEditable := not Rec.Closed;
        end;

        OnAfterSwitchCardControls(ContactNoEditable, NoOfAttendeesEnable, AttendeesAcceptedNoEnable);
    end;

    local procedure TeamCodeOnAfterValidate()
    begin
        SwitchCardControls();
        Rec.CalcFields(
          "No. of Attendees",
          "Attendees Accepted No.",
          "Contact Name",
          "Contact Company Name",
          "Campaign Description",
          "Opportunity Description")
    end;

    protected procedure ContactNoOnAfterValidate()
    begin
        Rec.CalcFields("Contact Name", "Contact Company Name");
    end;

    local procedure TypeOnAfterValidate()
    begin
        EnableFields();
    end;

    local procedure AllDayEventOnAfterValidate()
    begin
        EnableFields();
    end;

    local procedure SalespersonCodeOnAfterValidate()
    begin
        SwitchCardControls();
        Rec.CalcFields(
          "No. of Attendees",
          "Attendees Accepted No.",
          "Contact Name",
          "Contact Company Name",
          "Campaign Description",
          "Opportunity Description");
    end;

    local procedure CampaignNoOnAfterValidate()
    begin
        Rec.CalcFields("Campaign Description");
    end;

    local procedure OpportunityNoOnAfterValidate()
    begin
        Rec.CalcFields("Opportunity Description");
    end;

    local procedure RecurringOnPush()
    begin
        SetRecurringEditable();

        OnAfterRecurringOnPush();
    end;

    local procedure ContactNoOnFormat(Text: Text[1024])
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeContactNoOnFormat(Rec, IsHandled);
        if isHandled then
            exit;

        if Rec.Type = Rec.Type::Meeting then
            Text := MultipleTxt;
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterRecurringOnPush()
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterSwitchCardControls(var ContactNoEditable: Boolean; var NoOfAttendeesEnable: Boolean; var AttendeesAcceptedNoEnable: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeContactNoOnFormat(var ToDo: Record "To-Do"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnEnableFieldsOnBeforeGetEndDateTime(var ToDo: Record "To-Do"; var StartTimeEnable: Boolean; var EndingTimeEnable: Boolean; var DurationEnable: Boolean; var LocationEnable: Boolean; var AllDayEventEnable: Boolean)
    begin
    end;
}

