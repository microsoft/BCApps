// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Task;

using Microsoft.CRM.Campaign;
using Microsoft.CRM.Contact;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Team;
using System.Environment;

page 5146 "Assign Activity"
{
    Caption = 'Assign Activity';
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
            group("Activity Setup")
            {
                Caption = 'Activity Setup';
                field("Activity Code"; Rec."Activity Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Activity Code';
                    TableRelation = Activity.Code;
                    ToolTip = 'Specifies a code for the task activity.';

                    trigger OnValidate()
                    begin
                        if not Activity.IncludesMeeting(Rec."Activity Code") then begin
                            TeamMeetingOrganizerEditable := false;
                            Rec."Team Meeting Organizer" := ''
                        end else
                            if Rec."Team Code" <> '' then begin
                                TeamMeetingOrganizerEditable := true;
                                Rec."Team Meeting Organizer" := ''
                            end;
                    end;
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Activity Start Date';
                    ToolTip = 'Specifies the date when the task should be started. There are certain rules for how dates should be entered found in How to: Enter Dates and Times.';
                }
                field("Wizard Contact Name"; Rec."Wizard Contact Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Contact No.';
                    Editable = WizardContactNameEditable;
                    Lookup = false;
                    TableRelation = Contact;
                    ToolTip = 'Specifies a contact name from the wizard.';

                    trigger OnAssistEdit()
                    var
                        Cont: Record Contact;
                    begin
                        if (Rec."Wizard Contact Name" = '') and not SegHeader.Get(Rec.GetFilter("Segment No.")) then begin
                            if Cont.Get(Rec."Contact No.") then;
                            if PAGE.RunModal(0, Cont) = ACTION::LookupOK then begin
                                Rec.Validate("Contact No.", Cont."No.");
                                CurrPage.SetSelectionFilter(Rec);
                                Rec."Wizard Contact Name" := Cont.Name;
                            end;
                        end;
                    end;
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = Suite, RelationshipMgmt;
                    Caption = 'Salesperson Code';
                    Editable = SalespersonCodeEditable;
                    ToolTip = 'Specifies the code of the salesperson assigned to the task.';

                    trigger OnValidate()
                    begin
                        if SalesPurchPerson.Get(Rec."Salesperson Code") then begin
                            TeamMeetingOrganizerEditable := false;
                            Rec."Team Meeting Organizer" := '';
                            Rec."Team Code" := ''
                        end else
                            if Activity.IncludesMeeting(Rec."Activity Code") or
                               (Rec."Activity Code" = '') and
                               (Rec."Team Code" <> '')
                            then
                                TeamMeetingOrganizerEditable := true
                    end;
                }
                field("Team Code"; Rec."Team Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Team Code';
                    Editable = TeamCodeEditable;
                    ToolTip = 'Specifies the code of the team to which the task is assigned.';

                    trigger OnValidate()
                    begin
                        if Team.Get(Rec."Team Code") then begin
                            if Activity.IncludesMeeting(Rec."Activity Code") then
                                TeamMeetingOrganizerEditable := true;
                            Rec."Salesperson Code" := '';
                        end;
                        if Rec."Team Code" = '' then begin
                            TeamMeetingOrganizerEditable := false;
                            Rec."Team Meeting Organizer" := ''
                        end;
                    end;
                }
                field("Team Meeting Organizer"; Rec."Team Meeting Organizer")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Meeting Organizer';
                    Editable = TeamMeetingOrganizerEditable;
                    ToolTip = 'Specifies who on the team is the organizer of the task. You can modify the value in this field with the appropriate name when the to-do is for a team.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Salesperson: Record "Salesperson/Purchaser";
                        SalesPurchPerson: Page "Salespersons/Purchasers";
                    begin
                        SalesPurchPerson.LookupMode := true;
                        if SalesPurchPerson.RunModal() = ACTION::LookupOK then begin
                            SalesPurchPerson.GetRecord(Salesperson);
                            if TeamMeetingOrganizerEditable then
                                Rec."Team Meeting Organizer" := Salesperson.Code
                        end;
                    end;

                    trigger OnValidate()
                    var
                        SalesPurchPerson: Record "Salesperson/Purchaser";
                    begin
                        SalesPurchPerson.Get(Rec."Team Meeting Organizer");
                    end;
                }
                field("Wizard Campaign Description"; Rec."Wizard Campaign Description")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Campaign';
                    Importance = Additional;
                    Lookup = false;
                    TableRelation = Campaign;
                    ToolTip = 'Specifies a description of the campaign that is related to the task. The description is copied from the campaign card.';

                    trigger OnAssistEdit()
                    var
                        Campaign: Record Campaign;
                    begin
                        if not Campaign.Get(Rec.GetFilter("Campaign No.")) then begin
                            if Campaign.Get(Rec."Campaign No.") then;
                            if PAGE.RunModal(0, Campaign) = ACTION::LookupOK then begin
                                Rec.Validate("Campaign No.", Campaign."No.");
                                Rec."Wizard Campaign Description" := Campaign.Description;
                            end;
                        end;
                    end;
                }
                field("Segment Description"; Rec."Segment Description")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Create Tasks for Segment';
                    Editable = false;
                    Importance = Additional;
                    Lookup = false;
                    TableRelation = "Segment Header";
                    ToolTip = 'Specifies a description of the segment related to the task. The description is copied from the segment card.';

                    trigger OnAssistEdit()
                    var
                        Segment: Record "Segment Header";
                    begin
                        if Segment.Get(Rec."Segment No.") then;
                        if PAGE.RunModal(0, Segment) = ACTION::LookupOK then begin
                            Rec.Validate("Segment No.", Segment."No.");
                            Rec."Segment Description" := Segment.Description;
                        end;
                    end;
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
                ToolTip = 'Finish assigning the activity.';
                Visible = IsOnMobile;

                trigger OnAction()
                begin
                    Rec.CheckAssignActivityStatus();
                    Rec.FinishAssignActivity();
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
        WizardContactNameOnFormat(Format(Rec."Wizard Contact Name"));
    end;

    trigger OnInit()
    begin
        TeamCodeEditable := true;
        SalespersonCodeEditable := true;
        WizardContactNameEditable := true;
        TeamMeetingOrganizerEditable := true;
    end;

    trigger OnOpenPage()
    begin
        WizardContactNameEditable := false;
        IsOnMobile := ClientTypeManagement.GetCurrentClientType() = CLIENTTYPE::Phone;

        if SalesPurchPerson.Get(Rec.GetFilter("Salesperson Code")) or
           Team.Get(Rec.GetFilter("Team Code"))
        then begin
            SalespersonCodeEditable := false;
            TeamCodeEditable := false;
        end;

        if SalesPurchPerson.Get(Rec.GetFilter("Salesperson Code")) or
           (Rec."Salesperson Code" <> '') or
           (Rec."Activity Code" = '')
        then
            TeamMeetingOrganizerEditable := false;

        if Campaign.Get(Rec.GetFilter("Campaign No.")) then
            Rec."Campaign Description" := Campaign.Description;

        if SegHeader.Get(Rec.GetFilter("Segment No.")) then
            Rec."Segment Description" := SegHeader.Description;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction in [ACTION::OK, ACTION::LookupOK] then begin
            Rec.CheckAssignActivityStatus();
            Rec.FinishAssignActivity();
        end;
    end;

    var
        Cont: Record Contact;
        SalesPurchPerson: Record "Salesperson/Purchaser";
        Team: Record Team;
        Campaign: Record Campaign;
        SegHeader: Record "Segment Header";
        Activity: Record Activity;
        ClientTypeManagement: Codeunit "Client Type Management";
        TeamMeetingOrganizerEditable: Boolean;
        WizardContactNameEditable: Boolean;
        SalespersonCodeEditable: Boolean;
        TeamCodeEditable: Boolean;
        IsOnMobile: Boolean;

#pragma warning disable AA0074
        Text000: Label 'untitled';
        Text005: Label '(Multiple)';
#pragma warning restore AA0074

    procedure Caption() CaptionStr: Text
    begin
        if Cont.Get(Rec.GetFilter("Contact Company No.")) then
            CaptionStr := CopyStr(Cont."No." + ' ' + Cont.Name, 1, MaxStrLen(CaptionStr));
        if Cont.Get(Rec.GetFilter("Contact No.")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + Cont."No." + ' ' + Cont.Name, 1, MaxStrLen(CaptionStr));
        if SalesPurchPerson.Get(Rec.GetFilter("Salesperson Code")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + SalesPurchPerson.Code + ' ' + SalesPurchPerson.Name, 1, MaxStrLen(CaptionStr));
        if Team.Get(Rec.GetFilter("Team Code")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + Team.Code + ' ' + Team.Name, 1, MaxStrLen(CaptionStr));
        if Campaign.Get(Rec.GetFilter("Campaign No.")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + Campaign."No." + ' ' + Campaign.Description, 1, MaxStrLen(CaptionStr));
        if SegHeader.Get(Rec.GetFilter("Segment No.")) then
            CaptionStr := CopyStr(CaptionStr + ' ' + SegHeader."No." + ' ' + SegHeader.Description, 1, MaxStrLen(CaptionStr));
        if CaptionStr = '' then
            CaptionStr := Text000;

        OnAfterCaption(Rec, CaptionStr);
    end;

    local procedure WizardContactNameOnFormat(Text: Text[1024])
    begin
        if SegHeader.Get(Rec.GetFilter("Segment No.")) then
            Text := Text005;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCaption(Todo: Record "To-do"; var CaptionStr: Text)
    begin
    end;
}

