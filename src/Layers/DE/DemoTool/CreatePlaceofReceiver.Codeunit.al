codeunit 161402 "Create Place of Receiver"
{

    trigger OnRun()
    begin
        InsertData('1', 'in Hamburg');
        InsertData('3', 'in Bremen und Bremerhaven');
        InsertData('6', 'in Berlin (West)');
        InsertData('7', 'im Saarland');
        InsertData('8', 'in Lübeck');
        InsertData('9', 'sowie Brandenburg, Mecklenburg-Vorpommern, Sachsen, Sachsen-Anhalt, Thüringen');
    end;

    var
        "Place of Receiver": Record "Place of Receiver";

    procedure InsertData("Code": Code[10]; Text: Text[250])
    begin
        "Place of Receiver".Init();
        "Place of Receiver".Validate(Code, Code);
        "Place of Receiver".Validate(Text, Text);
        "Place of Receiver".Insert();
    end;
}

