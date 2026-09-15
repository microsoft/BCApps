codeunit 101574 "Create Attendee"
{

    trigger OnRun()
    begin
        InsertData(XTD100051, 10000, 2, 1, XJO, 0, false);
        InsertData(XTD100051, 20000, 0, 0, XCT100140, 0, false);
        InsertData(XTD100051, 30000, 0, 0, XCT100156, 0, false);
        InsertData(XTD100054, 10000, 2, 1, XRB, 0, false);
        InsertData(XTD100054, 20000, 0, 1, XJO, 0, false);
    end;

    var
        Attendee: Record Attendee;
        XTD100051: Label 'TD100051';
        XJO: Label 'JO';
        XCT100140: Label 'CT100140';
        XCT100156: Label 'CT100156';
        XTD100054: Label 'TD100054';
        XRB: Label 'RB';

    procedure InsertData(TodoNo: Code[20]; LineNo: Integer; AttendanceType: Integer; AttendeeType: Integer; AttendeeNo: Code[20]; InvitationResponse: Integer; InvitationSent: Boolean)
    begin
        Attendee.Init();
        Attendee."To-do No." := TodoNo;
        Attendee."Line No." := LineNo;
        Attendee.Validate("Attendance Type", AttendanceType);
        Attendee.Validate("Attendee Type", AttendeeType);
        Attendee.Validate("Attendee No.", AttendeeNo);
        Attendee."Invitation Response Type" := InvitationResponse;
        Attendee."Invitation Sent" := InvitationSent;
        Attendee.Insert();
    end;
}

