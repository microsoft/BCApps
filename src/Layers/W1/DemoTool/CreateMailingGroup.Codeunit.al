codeunit 101555 "Create Mailing Group"
{

    trigger OnRun()
    begin
        InsertData(XXCARD, XXmascard);
        InsertData(XXGIFT, XXmasgift);
    end;

    var
        "Mailing Group": Record "Mailing Group";
        XXCARD: Label 'X-CARD';
        XXmascard: Label 'X-mas card';
        XXGIFT: Label 'X-GIFT';
        XXmasgift: Label 'X-mas gift';

    procedure InsertData("Code": Code[10]; Description: Text[30])
    begin
        "Mailing Group".Init();
        "Mailing Group".Validate(Code, Code);
        "Mailing Group".Validate(Description, Description);
        "Mailing Group".Insert();
    end;
}

