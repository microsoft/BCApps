codeunit 161400 "Create Transaction Specifi."
{

    trigger OnRun()
    begin
        InsertData('1000', 'Endgültige Versendung');
        InsertData('1043', 'Wiederversendung nach wirtschaftlicher Lohnveredelung');
        InsertData('2200', 'Versendung zur wirtschaftlichen Lohnveredelung');
        InsertData('4300', 'Endgültiger Eingang');
        InsertData('4322', 'Wiedereingang nach wirtschaftlicher Lohnveredelung');
    end;

    var
        "Transaction Specification": Record "Transaction Specification";

    procedure InsertData("Code": Code[10]; Text: Text[250])
    begin
        "Transaction Specification".Init();
        "Transaction Specification".Validate(Code, Code);
        "Transaction Specification".Validate(Text, Text);
        "Transaction Specification".Insert();
    end;
}

