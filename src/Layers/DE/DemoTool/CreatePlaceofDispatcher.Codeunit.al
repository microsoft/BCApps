codeunit 161401 "Create Place of Dispatcher"
{

    trigger OnRun()
    begin
        InsertData('1', 'in Hamburg');
        InsertData('5', 'in Bremen und Bremerhaven');
        InsertData('7', 'in Lübeck, Brandenburg, Mecklenburg-Vorpommern, Sachsen, Sachsen-Anhalt');
        InsertData('9', 'sowie Brandenburg, Mecklenburg-Vorpommern, Sachsen, Sachsen-Anhalt, Thüringen');
    end;

    var
        "Place of Dispatcher": Record "Place of Dispatcher";

    procedure InsertData("Code": Code[10]; Text: Text[80])
    begin
        "Place of Dispatcher".Init();
        "Place of Dispatcher".Validate(Code, Code);
        "Place of Dispatcher".Validate(Text, Text);
        "Place of Dispatcher".Insert();
    end;
}

