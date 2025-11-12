// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Task;

page 5198 "Attendee Wizard Subform"
{
    AutoSplitKey = true;
    Caption = 'Lines';
    DelayedInsert = true;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = Attendee;
    SourceTableTemporary = true;

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
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        StyleIsStrong := false;
        AttendanceTypeIndent := 0;
        SendInvitationEditable := true;

        if Rec."Attendance Type" = Rec."Attendance Type"::"To-do Organizer" then begin
            StyleIsStrong := true;
            SendInvitationEditable := false;
            Rec."Send Invitation" := true;
        end else
            AttendanceTypeIndent := 1;
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        Rec.Get(Rec."To-do No.", Rec."Line No.");
        if Rec."Attendee No." in [SalespersonFilter, ContactFilter] then
            Error(Text001, Rec.TableCaption);
        Rec.Delete();
        exit(false);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        xAttendee: Record Attendee;
        SplitResult: Integer;
    begin
        xAttendee.Copy(Rec);
        Rec.ValidateAttendee(Rec, Rec);
        Rec.Reset();
        Rec := xAttendee;
        if Rec.Get(Rec."To-do No.", Rec."Line No.") then begin
            repeat
            until (Rec.Next() = 0) or (Rec."Line No." = xRec."Line No.");
            Rec.Next(-1);
            SplitResult := Round((xRec."Line No." - Rec."Line No.") / 2, 1, '=');
        end;
        Rec.Copy(xAttendee);
        Rec."Line No." := Rec."Line No." + SplitResult;
        Rec.Insert();
        exit(false);
    end;

    trigger OnModifyRecord(): Boolean
    var
        xAttendee: Record Attendee;
    begin
        xAttendee.Copy(Rec);
        Rec.Get(Rec."To-do No.", Rec."Line No.");
        if (Rec."Attendee No." in [SalespersonFilter, ContactFilter]) and
           ((Rec."Attendee Type" <> Rec."Attendee Type") or
            (Rec."Attendee No." <> Rec."Attendee No.") or
            ((Rec."Attendance Type" = Rec."Attendance Type"::"To-do Organizer") and
             (Rec."Attendance Type" <> Rec."Attendance Type"::"To-do Organizer")))
        then
            Error(Text001, Rec.TableCaption);
        Rec.ValidateAttendee(xAttendee, Rec);
        Rec.Copy(xAttendee);
        Rec.Modify();
        exit(false);
    end;

    var
        SalespersonFilter: Code[20];
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'You cannot delete or change this %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ContactFilter: Code[20];
        StyleIsStrong: Boolean;
        SendInvitationEditable: Boolean;
        AttendanceTypeIndent: Integer;

    procedure SetAttendee(var Attendee: Record Attendee)
    begin
        Rec.DeleteAll();

        if Attendee.FindSet() then
            repeat
                Rec := Attendee;
                Rec.Insert();
            until Attendee.Next() = 0;
    end;

    procedure GetAttendee(var Attendee: Record Attendee)
    begin
        Attendee.DeleteAll();

        if Rec.FindSet() then
            repeat
                Attendee := Rec;
                Attendee.Insert();
            until Rec.Next() = 0;
    end;

    procedure UpdateForm()
    begin
        CurrPage.Update(false);
    end;

    procedure SetTaskFilter(NewSalespersonFilter: Code[20]; NewContactFilter: Code[20])
    begin
        SalespersonFilter := NewSalespersonFilter;
        ContactFilter := NewContactFilter;
    end;
}

