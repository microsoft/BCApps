codeunit 163511 "Create Cash Desk User CZP"
{

    trigger OnRun()
    begin
        // only temporary user
        InsertData('POK01', UserId, true, true, true, true);
    end;

    var
        CashDeskUserCZP: Record "Cash Desk User CZP";

    procedure InsertData(CashDeskNo: Code[20]; UserID: Code[50]; Create: Boolean; Issue: Boolean; Post: Boolean; PostEET: Boolean)
    begin
        CashDeskUserCZP.Init();
        CashDeskUserCZP."Cash Desk No." := CashDeskNo;
        CashDeskUserCZP."User ID" := UserID;
        CashDeskUserCZP.Create := Create;
        CashDeskUserCZP.Issue := Issue;
        CashDeskUserCZP.Post := Post;
        CashDeskUserCZP."Post EET Only" := PostEET;
        CashDeskUserCZP.Insert();
    end;
}

