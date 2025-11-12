// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Task;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Team;

page 5197 "Attendee Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = Attendee;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = AttendanceTypeIndent;
                IndentationControls = "Attendance Type";
                ShowCaption = false;
                field("Attendance Type"; Rec."Attendance Type")
                {
                    ApplicationArea = RelationshipMgmt;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies the type of attendance for the meeting. You can select from: Required, Optional and Task Organizer.';
                }
                field("Attendee Type"; Rec."Attendee Type")
                {
                    ApplicationArea = RelationshipMgmt;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies the type of the attendee. You can choose from Contact or Salesperson.';
                }
                field("Attendee No."; Rec."Attendee No.")
                {
                    ApplicationArea = RelationshipMgmt;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies the number of the attendee participating in the task.';
                }
                field("Attendee Name"; Rec."Attendee Name")
                {
                    ApplicationArea = RelationshipMgmt;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies the name of the attendee participating in the task.';
                }
                field("Send Invitation"; Rec."Send Invitation")
                {
                    ApplicationArea = RelationshipMgmt;
                    Editable = SendInvitationEditable;
                    ToolTip = 'Specifies that you want to send an invitation to the attendee by e-mail. The Send Invitation option is only available for contacts and salespeople with an e-mail address. The Send Invitation option is not available for the meeting organizer.';
                }
                field("Invitation Response Type"; Rec."Invitation Response Type")
                {
                    ApplicationArea = RelationshipMgmt;
                    Style = Strong;
                    StyleExpr = StyleIsStrong;
                    ToolTip = 'Specifies the type of the attendee''s response to a meeting invitation.';
                }
                field("Invitation Sent"; Rec."Invitation Sent")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies that the meeting invitation has been sent to the attendee. The Send Invitation option is not available for the meeting organizer.';
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("Make &Phone Call")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Make &Phone Call';
                    Image = Calls;
                    ToolTip = 'Call the selected contact.';

                    trigger OnAction()
                    begin
                        MakePhoneCall();
                    end;
                }
            }
            group("&Line")
            {
                Caption = '&Line';
                Image = Line;
                action(Card)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Card';
                    Image = EditLines;
                    ShortCutKey = 'Shift+F7';
                    ToolTip = 'View or change detailed information about the attendee.';

                    trigger OnAction()
                    begin
                        ShowCard();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        StyleIsStrong := false;
        AttendanceTypeIndent := 0;
        SendInvitationEditable := true;

        if Rec."Attendance Type" = Rec."Attendance Type"::"To-do Organizer" then begin
            StyleIsStrong := true;
            SendInvitationEditable := false;
        end else
            AttendanceTypeIndent := 1;
    end;

    var
        PhoneCallNotAvailableForSalespersonErr: Label 'The Make Phone Call function is not available for a salesperson.';
        StyleIsStrong: Boolean;
        SendInvitationEditable: Boolean;
        AttendanceTypeIndent: Integer;

    local procedure ShowCard()
    var
        Cont: Record Contact;
        Salesperson: Record "Salesperson/Purchaser";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowCard(Rec, IsHandled);
        if IsHandled then
            exit;

        if Rec."Attendee Type" = Rec."Attendee Type"::Contact then begin
            if Cont.Get(Rec."Attendee No.") then
                PAGE.Run(PAGE::"Contact Card", Cont);
        end else
            if Salesperson.Get(Rec."Attendee No.") then
                PAGE.Run(PAGE::"Salesperson/Purchaser Card", Salesperson);
    end;

    local procedure MakePhoneCall()
    var
        Attendee: Record Attendee;
        TempSegmentLine: Record "Segment Line" temporary;
        Cont: Record Contact;
        Task: Record "To-do";
    begin
        if Rec."Attendee Type" = Rec."Attendee Type"::Salesperson then
            Error(PhoneCallNotAvailableForSalespersonErr);
        if Cont.Get(Rec."Attendee No.") then begin
            if Task.FindAttendeeTask(Task, Attendee) then
                TempSegmentLine."To-do No." := Task."No.";
            TempSegmentLine."Contact No." := Cont."No.";
            TempSegmentLine."Contact Company No." := Cont."Company No.";
            TempSegmentLine."Campaign No." := Task."Campaign No.";
            TempSegmentLine.CreatePhoneCall();
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowCard(var Attendee: Record Attendee; var IsHandled: Boolean)
    begin
    end;
}

