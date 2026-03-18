codeunit 101608 "Create Cause of Inactivity"
{

    trigger OnRun()
    begin
        InsertData(XLEAVE, XOnLeave);
        InsertData(XMATERNITY, XMaternityLeave);
        InsertData(XCOURSE, XAttendingaCourse);
    end;

    var
        "Cause of Inactivity": Record "Cause of Inactivity";
        XLEAVE: Label 'LEAVE';
        XOnLeave: Label 'On Leave';
        XMATERNITY: Label 'MATERNITY';
        XMaternityLeave: Label 'Maternity Leave';
        XCOURSE: Label 'COURSE';
        XAttendingaCourse: Label 'Attending a Course';

    procedure InsertData("Code": Code[10]; Description: Text[30])
    begin
        "Cause of Inactivity".Code := Code;
        "Cause of Inactivity".Description := Description;
        "Cause of Inactivity".Insert();
    end;
}

