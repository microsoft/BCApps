codeunit 161600 "Create Transaction Specifi."
{
    // Quelle Statistik Austria 2002


    trigger OnRun()
    begin
        //Versendung
        InsertData(X10000, XEndgultigeVersendung);
        InsertData(X22002, XVorberVersendwirtLohnveredel);
        InsertData(X31514, 'Wiederversendung nach wirtschaftlicher Lohnveredelung');

        //Eingang
        InsertData(X40000, XEndgultigerEingang);
        InsertData(X51004, XVorberEingangwirtLohnveredel);
        InsertData(X61215, 'Wiedereingang nach wirtschaftlicher Lohnveredelung');
    end;

    var
        "Transaction Specification": Record "Transaction Specification";
        X10000: Label '10000';
        XEndgultigeVersendung: Label 'Endgültige Versendung';
        X22002: Label '22002';
        XVorberVersendwirtLohnveredel: Label 'Vorübergehende Versendung zur wirtschaftlichen Lohnveredelung';
        X31514: Label '31514';
        X40000: Label '40000';
        XEndgultigerEingang: Label 'Endgültiger Eingang';
        X51004: Label '51004';
        XVorberEingangwirtLohnveredel: Label 'Vorübergehender Eingang zur wirtschaftlichen Lohnveredelung';
        X61215: Label '61215';

    procedure InsertData("Code": Code[10]; Text: Text[250])
    begin
        "Transaction Specification".Init();
        "Transaction Specification".Validate(Code, Code);
        "Transaction Specification".Validate(Text, Text);
        "Transaction Specification".Insert();
    end;
}

