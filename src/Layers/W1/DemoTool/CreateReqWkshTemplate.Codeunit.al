codeunit 101244 "Create Req. Wksh. Template"
{

    trigger OnRun()
    begin
        InsertData(XREQ, XReqWorksheet, false, 0);
        InsertData(XPLANNING, XPlanningWorksheet, false, 2);
    end;

    var
        "Req. Wksh. Template": Record "Req. Wksh. Template";
        XREQ: Label 'REQ';
        XReqWorksheet: Label 'Req. Worksheet';
        XPLANNING: Label 'PLANNING';
        XPlanningWorksheet: Label 'Planning Worksheet';

    procedure InsertData(Name: Code[10]; Description: Text[80]; Recurring: Boolean; Type: Option)
    begin
        "Req. Wksh. Template".Init();
        "Req. Wksh. Template".Validate(Name, Name);
        "Req. Wksh. Template".Validate(Description, Description);
        "Req. Wksh. Template".Validate(Type, Type);
        "Req. Wksh. Template".Insert(true);
        "Req. Wksh. Template".Validate(Recurring, false);
        "Req. Wksh. Template".Modify();
    end;
}

