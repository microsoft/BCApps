codeunit 101569 "Create Salutation Formula"
{

    trigger OnRun()
    begin
        InsertData(XCOMPANY, '', 0, XDearSirs, 0, 0, 0, 0, 0);
        InsertData(XCOMPANY, '', 1, '%1,', 6, 0, 0, 0, 0);
        InsertData(XCOMPANY, 'ENU', 0, 'Dear Sirs,', 0, 0, 0, 0, 0);
        InsertData(XCOMPANY, 'ENU', 1, '%1,', 6, 0, 0, 0, 0);
        InsertData(XCOMPANY, 'DAN', 0, 'Til rette vedkommende,', 0, 0, 0, 0, 0);
        InsertData(XCOMPANY, 'DAN', 1, '%1,', 6, 0, 0, 0, 0);
        InsertData(XCOMPANY, 'DEU', 0, 'Sehr geehrte Damen und Herren,', 0, 0, 0, 0, 0);
        InsertData(XCOMPANY, 'DEU', 1, '%1,', 6, 0, 0, 0, 0);
        InsertData(XCOMPANY, 'ESP', 0, 'Estimado Señor o la Señora,', 0, 0, 0, 0, 0);
        InsertData(XCOMPANY, 'ESP', 1, '%1,', 6, 0, 0, 0, 0);
        InsertData(XCOMPANY, 'FRA', 0, 'Cher Monsieur ou Madame,', 0, 0, 0, 0, 0);
        InsertData(XCOMPANY, 'FRA', 1, '%1,', 6, 0, 0, 0, 0);
        InsertData(XCOMPANY, 'ITA', 0, 'Spettabile Ditta %1,', 6, 0, 0, 0, 0);
        InsertData(XCOMPANY, 'ITA', 1, '%1,', 6, 0, 0, 0, 0);

        InsertData(XF, '', 0, XDearMsPCT1PCT2PCT3, 2, 3, 4, 0, 0);
        InsertData(XF, '', 1, XHiPCT1, 2, 0, 0, 0, 0);
        InsertData(XF, 'ENU', 0, 'Dear Ms. %1 %2 %3,', 2, 3, 4, 0, 0);
        InsertData(XF, 'ENU', 1, 'Hi %1,', 2, 0, 0, 0, 0);
        InsertData(XF, 'DAN', 0, 'Kære Fr. %1 %2 %3,', 2, 3, 4, 0, 0);
        InsertData(XF, 'DAN', 1, 'Hej %1,', 2, 0, 0, 0, 0);
        InsertData(XF, 'DEU', 0, 'Sehr geehrte Frau %1 %2 %3,', 2, 3, 4, 0, 0);
        InsertData(XF, 'DEU', 1, 'Hallo %1,', 2, 0, 0, 0, 0);
        InsertData(XF, 'ESP', 0, 'Estimada Señora %1 %2 %3,', 2, 3, 4, 0, 0);
        InsertData(XF, 'ESP', 1, 'Estimada Señora %1 %2 %3,', 2, 3, 4, 0, 0);
        InsertData(XF, 'FRA', 0, 'Chère Madame %1 %2 %3,', 2, 3, 4, 0, 0);
        InsertData(XF, 'FRA', 1, '%1,', 2, 0, 0, 0, 0);
        InsertData(XF, 'ITA', 0, 'Gentile Signora %1,', 2, 0, 0, 0, 0);
        InsertData(XF, 'ITA', 1, 'Cara %1,', 2, 0, 0, 0, 0);

        InsertData(XFMAR, '', 0, XDearMsPCT1PCT2PCT3, 2, 3, 4, 0, 0);
        InsertData(XFMAR, '', 1, XHiPCT1, 2, 0, 0, 0, 0);
        InsertData(XFMAR, 'ENU', 0, 'Dear Ms. %1 %2 %3,', 2, 3, 4, 0, 0);
        InsertData(XFMAR, 'ENU', 1, 'Hi %1,', 2, 0, 0, 0, 0);
        InsertData(XFMAR, 'DAN', 0, 'Kære Fru. %1 %2 %3,', 2, 3, 4, 0, 0);
        InsertData(XFMAR, 'DAN', 1, 'Hej %1,', 2, 0, 0, 0, 0);
        InsertData(XFMAR, 'DEU', 0, 'Sehr geehrte Frau %1 %2 %3,', 2, 3, 4, 0, 0);
        InsertData(XFMAR, 'DEU', 1, 'Hallo %1,', 2, 0, 0, 0, 0);
        InsertData(XFMAR, 'ESP', 0, 'Estimada Señora %1 %2 %3,', 2, 3, 4, 0, 0);
        InsertData(XFMAR, 'ESP', 1, 'Estimada Señora %1 %2 %3,', 2, 3, 4, 0, 0);
        InsertData(XFMAR, 'FRA', 0, 'Chère Madame %1 %2 %3,', 2, 3, 4, 0, 0);
        InsertData(XFMAR, 'FRA', 1, '%1,', 2, 0, 0, 0, 0);
        InsertData(XFMAR, 'ITA', 0, 'Gentile Signora %1 %2,', 2, 4, 0, 0, 0);
        InsertData(XFMAR, 'ITA', 1, 'Cara %1,', 2, 0, 0, 0, 0);

        InsertData(XFUMAR, '', 0, XDearMsPCT1PCT2PCT3UMAR, 2, 3, 4, 0, 0);
        InsertData(XFUMAR, '', 1, XHiPCT1, 2, 0, 0, 0, 0);
        InsertData(XFUMAR, 'ENU', 0, 'Dear Ms. %1 %2 %3,', 2, 3, 4, 0, 0);
        InsertData(XFUMAR, 'ENU', 1, 'Hi %1,', 2, 0, 0, 0, 0);
        InsertData(XFUMAR, 'DAN', 0, 'Kære Frk. %1 %2 %3,', 2, 3, 4, 0, 0);
        InsertData(XFUMAR, 'DAN', 1, 'Hej %1,', 2, 0, 0, 0, 0);
        InsertData(XFUMAR, 'DEU', 0, 'Sehr geehrte Frau %1 %2 %3,', 2, 3, 4, 0, 0);
        InsertData(XFUMAR, 'DEU', 1, 'Hallo %1,', 2, 0, 0, 0, 0);
        InsertData(XFUMAR, 'ESP', 0, 'Estimada Señora %1 %2 %3,', 2, 3, 4, 0, 0);
        InsertData(XFUMAR, 'ESP', 1, 'Estimada Señora %1 %2 %3,', 2, 3, 4, 0, 0);
        InsertData(XFUMAR, 'FRA', 0, 'Chère Madame %1 %2 %3,', 2, 3, 4, 0, 0);
        InsertData(XFUMAR, 'FRA', 1, '%1,', 2, 0, 0, 0, 0);
        InsertData(XFUMAR, 'ITA', 0, 'Gentile Signorina %1 %2,', 2, 4, 0, 0, 0);
        InsertData(XFUMAR, 'ITA', 1, 'Cara %1,', 2, 0, 0, 0, 0);

        InsertData(XM, '', 0, XDearMrPCT1PCT2PCT3, 2, 3, 4, 0, 0);
        InsertData(XM, '', 1, XHiPCT1, 2, 0, 0, 0, 0);
        InsertData(XM, 'ENU', 0, 'Dear Mr. %1 %2 %3,', 2, 3, 4, 0, 0);
        InsertData(XM, 'ENU', 1, 'Hi %1,', 2, 0, 0, 0, 0);
        InsertData(XM, 'DAN', 0, 'Kære Hr. %1 %2 %3,', 2, 3, 4, 0, 0);
        InsertData(XM, 'DAN', 1, 'Hej %1,', 2, 0, 0, 0, 0);
        InsertData(XM, 'DEU', 0, 'Sehr geehrter Herr %1 %2 %3,', 2, 3, 4, 0, 0);
        InsertData(XM, 'DEU', 1, 'Hallo %1,', 2, 0, 0, 0, 0);
        InsertData(XM, 'ESP', 0, 'Estimado Señor %1 %2 %3,', 2, 3, 4, 0, 0);
        InsertData(XM, 'ESP', 1, 'Estimado Señor %1 %2 %3,', 2, 3, 4, 0, 0);
        InsertData(XM, 'FRA', 0, 'Chère Monsieur %1 %2 %3,', 2, 3, 4, 0, 0);
        InsertData(XM, 'FRA', 1, '%1,', 2, 0, 0, 0, 0);
        InsertData(XM, 'ITA', 0, 'Gentile Signor %1,', 2, 0, 0, 0, 0);
        InsertData(XM, 'ITA', 1, 'Caro %1,', 2, 0, 0, 0, 0);

        InsertData(XUNISEX, '', 0, XDearPCT1PCT2PCT3, 2, 3, 4, 0, 0);
        InsertData(XUNISEX, '', 1, XHiPCT1, 2, 0, 0, 0, 0);
        InsertData(XUNISEX, 'ENU', 0, 'Dear %1 %2 %3,', 2, 3, 4, 0, 0);
        InsertData(XUNISEX, 'ENU', 1, 'Hi %1,', 2, 0, 0, 0, 0);
        InsertData(XUNISEX, 'DAN', 0, 'Kære %1 %2 %3,', 2, 3, 4, 0, 0);
        InsertData(XUNISEX, 'DAN', 1, 'Hej %1,', 2, 0, 0, 0, 0);
        InsertData(XUNISEX, 'DEU', 0, 'Sehr geehrte/r %1 %2 %3,', 2, 3, 4, 0, 0);
        InsertData(XUNISEX, 'DEU', 1, 'Hallo %1,', 2, 0, 0, 0, 0);
        InsertData(XUNISEX, 'ESP', 0, 'Estimado/a %1 %2 %3,', 2, 3, 4, 0, 0);
        InsertData(XUNISEX, 'ESP', 1, 'Hola %1,', 2, 0, 0, 0, 0);
        InsertData(XUNISEX, 'FRA', 0, 'Chère %1 %2 %3,', 2, 3, 4, 0, 0);
        InsertData(XUNISEX, 'FRA', 1, '%1,', 2, 0, 0, 0, 0);
        InsertData(XUNISEX, 'ITA', 0, 'Gentile %1 %2 %3,', 2, 3, 4, 0, 0);
        InsertData(XUNISEX, 'ITA', 1, 'Caro/a %1,', 2, 0, 0, 0, 0);
    end;

    var
        "Salutation Formula": Record "Salutation Formula";
        XDearSirs: Label 'Dear Sirs,';
        XDearMsPCT1PCT2PCT3: Label 'Dear Ms. %1 %2 %3,';
        XHiPCT1: Label 'Hi %1,';
        XDearMsPCT1PCT2PCT3UMAR: Label 'Dear Ms. %1 %2 %3,';
        XDearMrPCT1PCT2PCT3: Label 'Dear Mr. %1 %2 %3,';
        XDearPCT1PCT2PCT3: Label 'Dear %1 %2 %3,';
        XF: Label 'F';
        XM: Label 'M';
        XFMAR: Label 'F-MAR';
        XFUMAR: Label 'F-UMAR';
        XCOMPANY: Label 'COMPANY';
        XUNISEX: Label 'UNISEX';

    procedure InsertData("Salutation Code": Code[10]; "Language Code": Code[10]; "Salutation Type": Option Formal,Informal; Salutation: Text[40]; "Name 1": Option " ","Job Title","First Name","Middle Name",Surname,Initials,"Company Name"; "Name 2": Option " ","Job Title","First Name","Middle Name",Surname,Initials,"Company Name"; "Name 3": Option " ","Job Title","First Name","Middle Name",Surname,Initials,"Company Name"; "Name 4": Option " ","Job Title","First Name","Middle Name",Surname,Initials,"Company Name"; "Name 5": Option " ","Job Title","First Name","Middle Name",Surname,Initials,"Company Name")
    begin
        "Salutation Formula".Init();
        "Salutation Formula".Validate("Salutation Code", "Salutation Code");
        "Salutation Formula".Validate("Language Code", "Language Code");
        "Salutation Formula".Validate("Salutation Type", "Salutation Type");
        "Salutation Formula".Validate(Salutation, Salutation);
        "Salutation Formula".Validate("Name 1", "Name 1");
        "Salutation Formula".Validate("Name 2", "Name 2");
        "Salutation Formula".Validate("Name 3", "Name 3");
        "Salutation Formula".Validate("Name 4", "Name 4");
        "Salutation Formula".Validate("Name 5", "Name 5");
        "Salutation Formula".Insert();
    end;
}

