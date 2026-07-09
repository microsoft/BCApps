codeunit 101576 "Create Segment Header"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(XSM10001, XIncreasesale, XCP1001, XHR, XBUS, 19030126D);
        InsertData(XSM10002, XEvent, XCP1002, XBC, XGOLF, 19030126D);
        InsertData(XSM10003, XWorkingplacearrangementPress, XCP1003, XOF, XMEMO, 19030126D);
        InsertData(XSM10004, XWorkingplacearrangementCust, XCP1003, XOF, XABSTRACT, 19030126D);
    end;

    var
        "Segment Header": Record "Segment Header";
        DemoDataSetup: Record "Demo Data Setup";
        XSM10001: Label 'SM10001';
        XIncreasesale: Label 'Increase sale';
        XCP1001: Label 'CP1001';
        XHR: Label 'HR';
        XBUS: Label 'BUS';
        XSM10002: Label 'SM10002';
        XEvent: Label 'Event';
        XCP1002: Label 'CP1002';
        XBC: Label 'BC';
        XGOLF: Label 'GOLF';
        XWorkingplacearrangementPress: Label 'Working place arrangement, Press';
        XCP1003: Label 'CP1003';
        XOF: Label 'OF';
        XMEMO: Label 'MEMO';
        XSM10003: Label 'SM10003';
        XSM10004: Label 'SM10004';
        XWorkingplacearrangementCust: Label 'Working place arrangement, Customer';
        XABSTRACT: Label 'ABSTRACT';
        MakeAdjustments: Codeunit "Make Adjustments";

    procedure InsertData("No.": Code[10]; Description: Text[50]; "Campaign No.": Code[10]; "Salesperson Code": Code[10]; "Interaction Template Code": Code[10]; Date: Date)
    begin
        "Segment Header".Init();
        "Segment Header".Validate("No.", "No.");
        "Segment Header".Validate(Description, Description);
        "Segment Header".Validate("Campaign No.", "Campaign No.");
        "Segment Header".Validate("Salesperson Code", "Salesperson Code");
        "Segment Header".Validate(Date, MakeAdjustments.AdjustDate(Date));
        "Segment Header".Insert();

        "Segment Header".Validate("Interaction Template Code", "Interaction Template Code");
        "Segment Header".Modify();
    end;

    procedure CreateEvaluationData()
    begin
        InsertData(XSM10001, XIncreasesale, '', XHR, XBUS, 19030126D);
        InsertData(XSM10002, XEvent, '', XBC, XGOLF, 19030126D);
        InsertData(XSM10004, XWorkingplacearrangementCust, '', XOF, XABSTRACT, 19030126D);
    end;
}

