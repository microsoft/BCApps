codeunit 101006 "Create Price Group"
{

    trigger OnRun()
    begin
        InsertData('');
    end;

    var
        "Price Group": Record "Customer Price Group";

    procedure InsertData("Code": Code[10])
    begin
        "Price Group".Init();
        "Price Group".Validate(Code, Code);
        "Price Group".Insert();
    end;
}

