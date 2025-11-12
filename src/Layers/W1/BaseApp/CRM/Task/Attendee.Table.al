// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Task;

using Microsoft.CRM.Contact;
using Microsoft.CRM.Team;

table 5199 Attendee
{
    Caption = 'Attendee';
    DataClassification = CustomerContent;
    Permissions = tabledata "Salesperson/Purchaser" = R,
                  tabledata Contact = R;

    fields
    {
        field(1; "To-do No."; Code[20])
        {
            Caption = 'Task No.';
            TableRelation = "To-do";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(3; "Attendance Type"; Option)
        {
            Caption = 'Attendance Type';
            OptionCaption = 'Required,Optional,To-do Organizer';
            OptionMembers = Required,Optional,"To-do Organizer";

            trigger OnValidate()
            var
                Cont: Record Contact;
                Salesperson: Record "Salesperson/Purchaser";
            begin
                if "Attendance Type" = "Attendance Type"::"To-do Organizer" then
                    "Send Invitation" := true
                else
                    if "Attendee Type" = "Attendee Type"::Contact then begin
                        if Cont.Get("Attendee No.") then
                            "Send Invitation" := Cont."E-Mail" <> '';
                    end else
                        if Salesperson.Get("Attendee No.") then
                            "Send Invitation" := Salesperson."E-Mail" <> '';
            end;
        }
        field(4; "Attendee Type"; Option)
        {
            Caption = 'Attendee Type';
            OptionCaption = 'Contact,Salesperson';
            OptionMembers = Contact,Salesperson;

            trigger OnValidate()
            begin
                if "Attendee Type" <> xRec."Attendee Type" then begin
                    "Attendee No." := '';
                    "Attendee Name" := '';
                    "Send Invitation" := false;
                    if "Attendance Type" = "Attendance Type"::"To-do Organizer" then
                        "Send Invitation" := true;
                end;
            end;
        }
        field(5; "Attendee No."; Code[20])
        {
            Caption = 'Attendee No.';
            TableRelation = if ("Attendee Type" = const(Contact)) Contact where("No." = field("Attendee No."))
            else
            if ("Attendee Type" = const(Salesperson)) "Salesperson/Purchaser" where(Code = field("Attendee No."));

            trigger OnValidate()
            var
                Cont: Record Contact;
                Salesperson: Record "Salesperson/Purchaser";
            begin
                TestField("Attendee No.");
                if "Attendee Type" = "Attendee Type"::Contact then begin
                    Cont.Get("Attendee No.");
                    "Attendee Name" := Cont.Name;
                    if CurrFieldNo <> 0 then
                        "Send Invitation" := Cont."E-Mail" <> '';
                end else begin
                    Salesperson.Get("Attendee No.");
                    "Attendee Name" := Salesperson.Name;
                    if CurrFieldNo <> 0 then
                        if "Attendance Type" <> "Attendance Type"::"To-do Organizer" then
                            "Send Invitation" := Salesperson."E-Mail" <> '';
                end;
            end;
        }
        field(6; "Attendee Name"; Text[100])
        {
            Caption = 'Attendee Name';
            Editable = false;
        }
        field(7; "Send Invitation"; Boolean)
        {
            Caption = 'Send Invitation';

            trigger OnValidate()
            var
                Cont: Record Contact;
                Salesperson: Record "Salesperson/Purchaser";
                Task: Record "To-do";
            begin
                if not "Send Invitation" and
                   ("Attendance Type" = "Attendance Type"::"To-do Organizer")
                then
                    Error(SendInvitationIsNotAvailableErr);

                Task.Init();
                if Task.Get("To-do No.") then;
                if "Send Invitation" and (Task.Type <> Task.Type::"Phone Call") then
                    if "Attendee Type" = "Attendee Type"::Salesperson then begin
                        if Salesperson.Get("Attendee No.") and (Salesperson."E-Mail" = '') then
                            Error(MissingEmailAddressErr, FieldCaption("Send Invitation"), Salesperson.Name);
                    end else
                        if Cont.Get("Attendee No.") and (Cont."E-Mail" = '') then
                            Error(MissingEmailAddressErr, FieldCaption("Send Invitation"), Cont.Name);
            end;
        }
        field(8; "Invitation Response Type"; Option)
        {
            Caption = 'Invitation Response Type';
            OptionCaption = 'None,Accepted,Declined,Tentative';
            OptionMembers = "None",Accepted,Declined,Tentative;
        }
        field(9; "Invitation Sent"; Boolean)
        {
            Caption = 'Invitation Sent';
        }
    }

    keys
    {
        key(Key1; "To-do No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "To-do No.", "Attendee Type", "Attendee No.")
        {
        }
        key(Key3; "To-do No.", "Attendance Type")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        if "Attendance Type" = "Attendance Type"::"To-do Organizer" then
            Error(CannotDeleteTaskOrganizerErr);
        Task.DeleteAttendeeTask(Rec);

        Task.Get("To-do No.");
    end;

    trigger OnInsert()
    var
        Task2: Record "To-do";
    begin
        ValidateAttendee(Rec, Attendee);
        Task2.Get("To-do No.");
        Task2.CreateSubTask(Rec, Task2);
    end;

    trigger OnModify()
    var
        Task2: Record "To-do";
    begin
        ValidateAttendee(Rec, Attendee);
        if xRec."Attendance Type" = "Attendance Type"::"To-do Organizer" then begin
            if "Attendance Type" <> xRec."Attendance Type" then
                Error(CannotChangeForTaskOrgErr, FieldCaption("Attendance Type"));
            if "Attendee No." <> xRec."Attendee No." then
                Error(CannotChangeTaskOrganizerErr);
        end else
            if "Attendee No." <> xRec."Attendee No." then begin
                Task2.DeleteAttendeeTask(xRec);
                Task2.Get("To-do No.");
                Task2.CreateSubTask(Rec, Task2);
            end else
                if (xRec."Invitation Response Type" <> "Invitation Response Type") or
                   (xRec."Invitation Sent" <> "Invitation Sent")
                then
                    exit;
    end;

    var
        Attendee: Record Attendee;
        Task: Record "To-do";

        TaskOrganizerMustBeSalespersonErr: Label 'A task organizer must always be a salesperson.';
        OnlyOneTaskOrganizerErr: Label 'You cannot have more than one task organizer.';
        AttendeeAlreadyExistsErr: Label 'This attendee already exists.';
        MissingEmailAddressErr: Label 'You cannot select the %1 for %2 because he/she does not have an email address.', Comment = '%1 = field caption for Send Invitation, %2 = Salesperson Name';
        CannotDeleteTaskOrganizerErr: Label 'You cannot delete a task organizer.';
        CannotChangeForTaskOrgErr: Label 'You cannot change an %1 for a task organizer.', Comment = '%1 = Attendance Type';
        SendInvitationIsNotAvailableErr: Label 'The Send Invitation option is not available for a task organizer.';
        CannotChangeTaskOrganizerErr: Label 'You cannot change the task organizer.';
        NoEmailForOrganizerErr: Label 'You cannot set %1 as organizer because he/she does not have email address.', Comment = '%1 = Sales / Purchaseer person name';

    procedure ValidateAttendee(AttendeeRec: Record Attendee; var Attendee: Record Attendee)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeValidateAttendee(AttendeeRec, Attendee, IsHandled);
        if IsHandled then
            exit;

        AttendeeRec.TestField("Attendee No.");
        ValidateOrganizer(AttendeeRec."Attendee No.", AttendeeRec."Attendance Type", AttendeeRec."Attendee Type", AttendeeRec."To-do No.");

        if AttendeeRec."Attendance Type" = "Attendance Type"::"To-do Organizer" then begin
            if AttendeeRec."Attendee Type" = "Attendee Type"::Contact then
                Error(TaskOrganizerMustBeSalespersonErr);

            Attendee.SetRange("To-do No.", AttendeeRec."To-do No.");
            Attendee.SetRange("Attendance Type", "Attendance Type"::"To-do Organizer");
            if Attendee.Find('-') then
                if Attendee."Line No." <> AttendeeRec."Line No." then begin
                    Attendee.Reset();
                    Error(OnlyOneTaskOrganizerErr);
                end;
            Attendee.Reset();
        end;

        Attendee.SetRange("To-do No.", AttendeeRec."To-do No.");
        Attendee.SetFilter("Attendee No.", AttendeeRec."Attendee No.");
        if Attendee.Find('-') then
            if Attendee."Line No." <> AttendeeRec."Line No." then begin
                Attendee.Reset();
                Error(AttendeeAlreadyExistsErr);
            end;
        Attendee.Reset();
    end;

    procedure CreateAttendee(var Attendee: Record Attendee; TaskNo: Code[20]; LineNo: Integer; AttendanceType: Integer; AttendeeType: Integer; AttendeeNo: Code[20]; SendInvitation: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateAttendee(Attendee, TaskNo, "Line No.", AttendanceType, AttendeeType, AttendeeNo, SendInvitation, IsHandled);
        if IsHandled then
            exit;

        ValidateOrganizer(AttendeeNo, AttendanceType, AttendeeType, TaskNo);

        Attendee.Init();
        Attendee."To-do No." := TaskNo;
        Attendee."Line No." := LineNo;
        Attendee."Attendance Type" := AttendanceType;
        Attendee.Validate("Attendee Type", AttendeeType);
        Attendee.Validate("Attendee No.", AttendeeNo);
        if Attendee."Attendance Type" <> Attendee."Attendance Type"::"To-do Organizer" then
            Attendee.Validate("Send Invitation", SendInvitation)
        else
            Attendee.Validate("Send Invitation", true);
        if not Attendee.Get(Attendee."To-do No.", Attendee."Line No.") then
            Attendee.Insert();
    end;

    local procedure ValidateOrganizer(AttendeeNo: Code[20]; AttendanceType: Integer; AttendeeType: Integer; TodoNo: Code[20])
    var
        SalesPurchPerson: Record "Salesperson/Purchaser";
        Task2: Record "To-do";
    begin
        if AttendanceType <> Attendee."Attendance Type"::"To-do Organizer" then
            exit;

        if AttendeeType = "Attendee Type"::Contact then
            Error(TaskOrganizerMustBeSalespersonErr);

        SalesPurchPerson.Get(AttendeeNo);
        Task2.Init();
        if Task2.Get(TodoNo) then;
        if (SalesPurchPerson."E-Mail" = '') and (Task2.Type <> Task2.Type::"Phone Call") then
            Error(NoEmailForOrganizerErr, SalesPurchPerson.Name);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateAttendee(AttendeeRec: Record Attendee; var Attendee: Record Attendee; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateAttendee(var Attendee: Record Attendee; TaskNo: Code[20]; LineNo: Integer; AttendanceType: Integer; AttendeeType: Integer; AttendeeNo: Code[20]; SendInvitation: Boolean; var IsHandled: Boolean)
    begin
    end;
}

