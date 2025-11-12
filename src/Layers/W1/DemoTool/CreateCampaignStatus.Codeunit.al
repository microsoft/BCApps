codeunit 101573 "Create Campaign Status"
{

    trigger OnRun()
    begin
        InsertData(X1PLAN, XPlanned);
        InsertData(X2APP, XApproved);
        InsertData(X3INIT, XInitiated);
        InsertData(X4SCH, XScheduled);
        InsertData(X5START, XStarted);
        InsertData(X9DONE, XDone);
    end;

    var
        "Campaign Status": Record "Campaign Status";
        X1PLAN: Label '1-PLAN';
        XPlanned: Label 'Planned';
        X2APP: Label '2-APP';
        XApproved: Label 'Approved';
        X3INIT: Label '3-INIT';
        XInitiated: Label 'Initiated';
        X4SCH: Label '4-SCH';
        XScheduled: Label 'Scheduled';
        X5START: Label '5-START';
        XStarted: Label 'Started';
        X9DONE: Label '9-DONE';
        XDone: Label 'Done';

    procedure InsertData("Code": Code[10]; Description: Text[30])
    begin
        "Campaign Status".Init();
        "Campaign Status".Validate(Code, Code);
        "Campaign Status".Validate(Description, Description);
        "Campaign Status".Insert();
    end;
}

