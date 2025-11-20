// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Task;

using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Interaction;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Team;
using System.Environment;

page 5097 "Create Task"
{
    Caption = 'Create Task';
    DataCaptionExpression = Caption();
    DeleteAllowed = false;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    SourceTable = "To-do";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(TypeSaaS; Rec.Type)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Type';
                    ToolTip = 'Specifies the type of the Task.';
                    Visible = IsSoftwareAsAService;

                    trigger OnValidate()
                    begin
                        ValidateTypeField();
                    end;
                }
                field(TypeOnPrem; Rec.Type)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Type';
                    ToolTip = 'Specifies the type of the Task.';
                    Visible = not IsSoftwareAsAService;

                    trigger OnValidate()
                    begin
                        ValidateTypeField();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the description of the Task.';
                }
                field(AllDayEvent; Rec."All Day Event")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'All Day Event';
                    Enabled = AllDayEventEnable;
                    ToolTip = 'Specifies that the Task of the Meeting type is an all-day event, which is an activity that lasts 24 hours or longer.';

                    trigger OnValidate()
                    begin
                        AllDayEventOnAfterValidate();
                    end;
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Start Date';
                    ToolTip = 'Specifies the date when the Task should be started. There are certain rules for how dates should be entered found in How to: Enter Dates and Times.';
                }
                field("Start Time"; Rec."Start Time")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Start Time';
                    Enabled = StartTimeEnable;
                    ToolTip = 'Specifies the time when the Task of the Meeting type should be started.';
                }
                field(Duration; Rec.Duration)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Duration';
                    Enabled = DurationEnable;
                    ToolTip = 'Specifies the duration of the Task of the Meeting type.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Ending Date';
                    ToolTip = 'Specifies the date of when the Task should end. There are certain rules for how dates should be entered. For more information, see How to: Enter Dates and Times.';
                }
                field("Ending Time"; Rec."Ending Time")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Ending Time';
                    Enabled = EndingTimeEnable;
                    ToolTip = 'Specifies the time of when the Task of the Meeting type should end.';
                }
                field(TeamTask; Rec."Team To-do")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Team Task';
                    ToolTip = 'Specifies if the Task is meant to be done team-wide. Select the check box to specify that the Task applies to the entire Team.';

                    trigger OnValidate()
                    begin
                        if not Rec."Team To-do" then begin
                            Rec."Team Code" := '';
                            SalespersonCodeEnable := true;
                            if Rec.Type = Rec.Type::Meeting then begin
                                Rec.ClearDefaultAttendeeInfo();
                                Rec.AssignDefaultAttendeeInfo();
                            end;
                        end else begin
                            SalespersonCodeEnable := false;
                            Rec."Salesperson Code" := '';
                        end;
                    end;
                }
                field("Wizard Contact Name"; Rec."Wizard Contact Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Contact';
                    Editable = WizardContactNameEditable;
                    Enabled = WizardContactNameEnable;
                    Lookup = false;
                    TableRelation = Contact;
                    ToolTip = 'Specifies a Contact name from the wizard.';

                    trigger OnAssistEdit()
                    var
                        Cont: Record Contact;
                    begin
                        if (Rec.GetFilter("Contact No.") = '') and (Rec.GetFilter("Contact Company No.") = '') and (Rec."Segment Description" = '') then begin
                            if Cont.Get(Rec."Contact No.") then;
                            if PAGE.RunModal(0, Cont) = ACTION::LookupOK then begin
                                Rec.Validate("Contact No.", Cont."No.");
                                Rec."Wizard Contact Name" := Cont.Name;
                            end;
                        end;
                    end;
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Salesperson';
                    Enabled = SalespersonCodeEnable;
                    ToolTip = 'Specifies the code of the Salesperson assigned to the Task.';
                }
                field("Team Code"; Rec."Team Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Team';
                    Editable = Rec."Team To-do";
                    Enabled = Rec."Team To-do" or not IsMeeting;
                    ToolTip = 'Specifies the code of the Team to which the Task is assigned.';

                    trigger OnValidate()
                    begin
                        if (xRec."Team Code" <> Rec."Team Code") and
                           (Rec."Team Code" <> '') and
                           (Rec.Type = Rec.Type::Meeting)
                        then begin
                            Rec.ClearDefaultAttendeeInfo();
                            Rec.AssignDefaultAttendeeInfo();
                        end
                    end;
                }
                field("Wizard Campaign Description"; Rec."Wizard Campaign Description")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Campaign';
                    Editable = WizardCampaignDescriptionEdita;
                    Importance = Additional;
                    Lookup = false;
                    TableRelation = Campaign;
                    ToolTip = 'Specifies a description of the campaign that is related to the task. The description is copied from the campaign card.';

                    trigger OnAssistEdit()
                    var
                        Campaign: Record Campaign;
                    begin
                        if Rec.GetFilter("Campaign No.") = '' then begin
                            if Campaign.Get(Rec."Campaign No.") then;
                            if PAGE.RunModal(0, Campaign) = ACTION::LookupOK then begin
                                Rec.Validate("Campaign No.", Campaign."No.");
                                Rec."Wizard Campaign Description" := Campaign.Description;
                            end;
                        end;
                    end;
                }
                field("Wizard Opportunity Description"; Rec."Wizard Opportunity Description")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Opportunity';
                    Editable = WizardOpportunityDescriptionEd;
                    Importance = Additional;
                    Lookup = false;
                    TableRelation = Opportunity;
                    ToolTip = 'Specifies a description of the Opportunity that is related to the Task. The description is copied from the Campaign card.';

                    trigger OnAssistEdit()
                    var
                        Opp: Record Opportunity;
                    begin
                        if Rec.GetFilter("Opportunity No.") = '' then begin
                            if Opp.Get(Rec."Opportunity No.") then;
                            if PAGE.RunModal(0, Opp) = ACTION::LookupOK then begin
                                Rec.Validate("Opportunity No.", Opp."No.");
                                Rec."Wizard Opportunity Description" := Opp.Description;
                            end;
                        end;
                    end;
                }
                field(SegmentDesc; Rec."Segment Description")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Create Tasks for Segment Contacts';
                    Editable = SegmentDescEditable;
                    Importance = Additional;
                    Lookup = false;
                    TableRelation = "Segment Header";
                    ToolTip = 'Specifies a description of the Segment related to the Task. The description is copied from the Segment Card.';

                    trigger OnAssistEdit()
                    var
                        SegmentHeader: Record "Segment Header";
                    begin
                        if Rec.GetFilter("Segment No.") = '' then begin
                            if SegmentHeader.Get(Rec."Segment No.") then;
                            if PAGE.RunModal(0, SegmentHeader) = ACTION::LookupOK then begin
                                Rec.Validate("Segment No.", SegmentHeader."No.");
                                Rec."Segment Description" := SegmentHeader.Description;
                            end;
                        end;
                    end;
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Priority';
                    Importance = Additional;
                    ToolTip = 'Specifies the priority of the Task. There are three options:';
                }
                field(Location; Rec.Location)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Location';
                    Enabled = LocationEnable;
                    Importance = Promoted;
                    ToolTip = 'Specifies the Location where the Meeting will take place.';
                }
            }
            group(MeetingAttendees)
            {
                Caption = 'Meeting Attendees';
                Visible = IsMeeting;
                part(AttendeeSubform; "Attendee Wizard Subform")
                {
                    ApplicationArea = RelationshipMgmt;
                    SubPageLink = "To-do No." = field("No.");
                }
                group(MeetingInteraction)
                {
                    Caption = 'Interaction';
                    field("Send on finish"; Rec."Send on finish")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Send Invitation(s) on Finish';
                        ToolTip = 'Specifies if the meeting invitation task will be sent when the Create Task wizard is finished.';
                    }
                    field("Interaction Template Code"; Rec."Interaction Template Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Caption = 'Interaction Template';
                        TableRelation = "Interaction Template";
                        ToolTip = 'Specifies the code for the Interaction Template that you have selected.';

                        trigger OnValidate()
                        begin
                            Rec.ValidateInteractionTemplCode();
                            InteractionTemplateCodeOnAfter();
                        end;
                    }
                    field("Language Code"; Rec."Language Code")
                    {
                        ApplicationArea = RelationshipMgmt;
                        Enabled = LanguageCodeEnable;
                        ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            Rec.LookupLanguageCode();
                        end;

                        trigger OnValidate()
                        begin
                            Rec.ValidateLanguageCode();
                        end;
                    }
                    field(Attachment; Rec."Attachment No." > 0)
                    {
                        ApplicationArea = RelationshipMgmt;
                        AssistEdit = true;
                        Caption = 'Attachment';
                        Editable = false;
                        Enabled = AttachmentEnable;
                        ToolTip = 'Specifies if the linked attachment is inherited or unique.';

                        trigger OnAssistEdit()
                        begin
                            Rec.AssistEditAttachment();
                        end;
                    }
                }
            }
            group(RecurringOptions)
            {
                Caption = 'Recurring';
                field(Recurring; Rec.Recurring)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Recurring Task';
                    ToolTip = 'Specifies that the Task occurs periodically.';

                    trigger OnValidate()
                    begin
                        RecurringOnAfterValidate();
                    end;
                }
                field("Recurring Date Interval"; Rec."Recurring Date Interval")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Recurring Date Interval';
                    Enabled = RecurringDateIntervalEnable;
                    ToolTip = 'Specifies the date formula to assign automatically a recurring Task to a Salesperson or Team.';
                }
                field("Calc. Due Date From"; Rec."Calc. Due Date From")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Calculate from Date';
                    Enabled = CalcDueDateFromEnable;
                    ToolTip = 'Specifies the date to use to calculate the date on which the next Task should be completed.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Finish)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = '&Finish';
                Image = Approve;
                InFooterBar = true;
                ToolTip = 'Finish the task.';
                Visible = IsOnMobile;

                trigger OnAction()
                begin
                    FinishPage();
                    CurrPage.Close();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_New)
            {
                Caption = 'New';

                actionref(Finish_Promoted; Finish)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        EnableFields();
        WizardContactNameOnFormat(Format(Rec."Wizard Contact Name"));
    end;

    trigger OnInit()
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        AttachmentEnable := true;
        LanguageCodeEnable := true;
        CalcDueDateFromEnable := true;
        RecurringDateIntervalEnable := true;
        WizardContactNameEnable := true;
        AllDayEventEnable := true;
        LocationEnable := true;
        DurationEnable := true;
        EndingTimeEnable := true;
        StartTimeEnable := true;
        SalespersonCodeEnable := true;
        WizardOpportunityDescriptionEd := true;
        WizardCampaignDescriptionEdita := true;
        WizardContactNameEditable := true;
        IsSoftwareAsAService := EnvironmentInfo.IsSaaS();
    end;

    trigger OnOpenPage()
    begin
        IsOnMobile := ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Phone;

        WizardContactNameEditable := false;
        WizardCampaignDescriptionEdita := false;
        WizardOpportunityDescriptionEd := false;

        if Rec."Segment Description" <> '' then
            SegmentDescEditable := false;

        IsMeeting := (Rec.Type = Rec.Type::Meeting);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then
            FinishPage();
    end;

    var
#pragma warning disable AA0074
        Text000: Label '(Multiple)';
        Text001: Label 'untitled';
#pragma warning restore AA0074
        Cont: Record Contact;
        SalesPurchPerson: Record "Salesperson/Purchaser";
        Campaign: Record Campaign;
        Team: Record Team;
        Opp: Record Opportunity;
        SegHeader: Record "Segment Header";
        AttendeeTemp: Record Attendee temporary;
        ClientTypeManagement: Codeunit "Client Type Management";
        SalespersonFilter: Code[20];
        ContactFilter: Code[20];
        WizardContactNameEditable: Boolean;
        WizardCampaignDescriptionEdita: Boolean;
        WizardOpportunityDescriptionEd: Boolean;
        SegmentDescEditable: Boolean;
        IsMeeting: Boolean;
        IsOnMobile: Boolean;
        DurationEnable: Boolean;
        LocationEnable: Boolean;
        AllDayEventEnable: Boolean;
        WizardContactNameEnable: Boolean;
        RecurringDateIntervalEnable: Boolean;
        CalcDueDateFromEnable: Boolean;
        LanguageCodeEnable: Boolean;
        AttachmentEnable: Boolean;
        IsSoftwareAsAService: Boolean;

    protected var
        StartTimeEnable: Boolean;
        EndingTimeEnable: Boolean;
        SalespersonCodeEnable: Boolean;

    procedure Caption(): Text
    var
        CaptionStr: Text;
    begin
        if Cont.Get(Rec.GetFilter(Rec."Contact Company No.")) then
            CaptionStr := CopyStr(Cont."No." + ' ' + Cont.Name, 1, MaxStrLen(CaptionStr));
        if Cont.Get(Rec.GetFilter(Rec."Contact No.")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + Cont."No." + ' ' + Cont.Name, 1, MaxStrLen(CaptionStr));
        if SalesPurchPerson.Get(Rec.GetFilter(Rec."Salesperson Code")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + SalesPurchPerson.Code + ' ' + SalesPurchPerson.Name, 1, MaxStrLen(CaptionStr));
        if Team.Get(Rec.GetFilter(Rec."Team Code")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + Team.Code + ' ' + Team.Name, 1, MaxStrLen(CaptionStr));
        if Campaign.Get(Rec.GetFilter(Rec."Campaign No.")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + Campaign."No." + ' ' + Campaign.Description, 1, MaxStrLen(CaptionStr));
        if Opp.Get(Rec.GetFilter(Rec."Opportunity No.")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + Opp."No." + ' ' + Opp.Description, 1, MaxStrLen(CaptionStr));
        if SegHeader.Get(Rec.GetFilter(Rec."Segment No.")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + SegHeader."No." + ' ' + SegHeader.Description, 1, MaxStrLen(CaptionStr));
        if CaptionStr = '' then
            CaptionStr := Text001;

        exit(CaptionStr);
    end;

    local procedure EnableFields()
    begin
        RecurringDateIntervalEnable := Rec.Recurring;
        CalcDueDateFromEnable := Rec.Recurring;

        if not Rec.Recurring then begin
            Evaluate(Rec."Recurring Date Interval", '');
            Clear(Rec."Calc. Due Date From");
        end;

        IsMeeting := Rec.Type = Rec.Type::Meeting;

        if IsMeeting then begin
            StartTimeEnable := not Rec."All Day Event";
            EndingTimeEnable := not Rec."All Day Event";
            DurationEnable := not Rec."All Day Event";
            LocationEnable := true;
            AllDayEventEnable := true;
            LanguageCodeEnable := Rec."Interaction Template Code" <> '';
            AttachmentEnable := Rec."Interaction Template Code" <> '';
        end else begin
            StartTimeEnable := Rec.Type = Rec.Type::"Phone Call";
            EndingTimeEnable := Rec.Type = Rec.Type::"Phone Call";
            DurationEnable := Rec.Type = Rec.Type::"Phone Call";
            LocationEnable := false;
            AllDayEventEnable := false;
        end;

        OnAfterEnableFields(Rec);
    end;

    procedure ValidateTypeField()
    begin
        if Rec.Type <> xRec.Type then
            if Rec.Type = Rec.Type::Meeting then begin
                Rec.ClearDefaultAttendeeInfo();
                Rec.AssignDefaultAttendeeInfo();
                Rec.LoadTempAttachment();
                if not Rec."Team To-do" then
                    if Rec."Salesperson Code" = '' then begin
                        if Cont.Get(Rec."Contact No.") then
                            Rec.Validate("Salesperson Code", Cont."Salesperson Code")
                        else
                            if Cont.Get(Rec."Contact Company No.") then
                                Rec.Validate("Salesperson Code", Cont."Salesperson Code");
                        if Campaign.Get(Rec.GetFilter("Campaign No.")) then
                            Rec.Validate("Salesperson Code", Campaign."Salesperson Code");
                        if Opp.Get(Rec.GetFilter("Opportunity No.")) then
                            Rec.Validate("Salesperson Code", Opp."Salesperson Code");
                        if SegHeader.Get(Rec.GetFilter("Segment No.")) then
                            Rec.Validate("Salesperson Code", SegHeader."Salesperson Code");
                        Rec.Modify();
                    end;
                Rec.GetAttendee(AttendeeTemp);
                CurrPage.AttendeeSubform.PAGE.SetAttendee(AttendeeTemp);
                CurrPage.AttendeeSubform.PAGE.SetTaskFilter(SalespersonFilter, ContactFilter);
                CurrPage.AttendeeSubform.PAGE.UpdateForm();
            end else begin
                Rec.ClearDefaultAttendeeInfo();
                CurrPage.AttendeeSubform.PAGE.GetAttendee(AttendeeTemp);
                Rec.SetAttendee(AttendeeTemp);
                SalespersonCodeEnable := not Rec."Team To-do";
                WizardContactNameEnable := true;
            end;
        IsMeeting := (Rec.Type = Rec.Type::Meeting);
        TypeOnAfterValidate();
        CurrPage.Update();
    end;

    local procedure TypeOnAfterValidate()
    begin
        EnableFields();
    end;

    local procedure AllDayEventOnAfterValidate()
    begin
        EnableFields();
    end;

    local procedure RecurringOnAfterValidate()
    begin
        EnableFields();
    end;

    local procedure InteractionTemplateCodeOnAfter()
    begin
        EnableFields();
    end;

    local procedure WizardContactNameOnFormat(Text: Text[1024])
    begin
        if SegHeader.Get(Rec.GetFilter("Segment No.")) then
            Text := Text000;
    end;

    local procedure FinishPage()
    begin
        CurrPage.AttendeeSubform.PAGE.GetAttendee(AttendeeTemp);
        Rec.SetAttendee(AttendeeTemp);

        Rec.CheckStatus();
        Rec.FinishWizard(false);
        OnAfterFinishPage(Rec);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterEnableFields(var Task: Record "To-do")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterFinishPage(var Task: Record "To-do")
    begin
    end;
}

