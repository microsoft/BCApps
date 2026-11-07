codeunit 101584 "Create Team Salesperson"
{

    trigger OnRun()
    begin
        InsertData(XSALE, XRB);
        InsertData(XSALE, XJO);
    end;

    var
        "Team Salesperson": Record "Team Salesperson";
        XSALE: Label 'SALE';
        XRB: Label 'RB';
        XJO: Label 'JO';

    procedure InsertData("Team Code": Code[10]; "Salesperson Code": Code[10])
    begin
        "Team Salesperson".Init();
        "Team Salesperson".Validate("Team Code", "Team Code");
        "Team Salesperson".Validate("Salesperson Code", "Salesperson Code");
        "Team Salesperson".Insert();
    end;
}

