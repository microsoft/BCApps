codeunit 101258 "Create Transaction Type"
{

    trigger OnRun()
    begin
    end;

    var
        "Transaction Type": Record "Transaction Type";

    procedure InsertData("Code": Code[10]; Description: Text[80])
    begin
        "Transaction Type".Init();
        "Transaction Type".Validate(Code, Code);
        "Transaction Type".Validate(Description, Description);
        "Transaction Type".Insert();
    end;
}

