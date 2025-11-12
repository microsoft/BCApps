codeunit 101615 "Create Ground for Termination"
{

    trigger OnRun()
    begin
        InsertData(XDECEASED, XEmployeeisdeceased);
        InsertData(XRETIRED, XEmployeeisretired);
        InsertData(XDISMISSED, XEmployeehasbeendismissed);
        InsertData(XRESIGNED, XEmployeehasresigned);
    end;

    var
        TerminationCause: Record "Grounds for Termination";
        XDECEASED: Label 'DECEASED';
        XEmployeeisdeceased: Label 'Employee is deceased.';
        XRETIRED: Label 'RETIRED';
        XEmployeeisretired: Label 'Employee is retired.';
        XDISMISSED: Label 'DISMISSED';
        XEmployeehasbeendismissed: Label 'Employee has been dismissed.';
        XRESIGNED: Label 'RESIGNED';
        XEmployeehasresigned: Label 'Employee has resigned.';

    procedure InsertData("Code": Code[10]; Description: Text[30])
    begin
        TerminationCause.Code := Code;
        TerminationCause.Description := Description;
        TerminationCause.Insert();
    end;
}

