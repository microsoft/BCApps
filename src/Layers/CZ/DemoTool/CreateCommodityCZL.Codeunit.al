codeunit 163548 "Create Commodity CZL"
{
    trigger OnRun()
    begin
        InsertData('0', 'Bez kontroly limitu');
        InsertData('1', '§92b - dodání zlata');
        InsertData('11', '§92f  - povolenky na emise');
        InsertData('12', '§92f - obiloviny a technické plodiny');
        InsertData('13', '§92f - kovy');
        InsertData('14', '§92f - mobilní telefony');
        InsertData('15', '§92f - integrované obvody');
        InsertData('16', '§92f - přenos. zařízení pro automat. zpracov. dat');
        InsertData('17', '§92f - videoherní konzole');
        InsertData('4', '§92e - poskytnutí stavebních nebo montážních prací');
        InsertData('5', '§92c - zboží uvedené v příloze č.5 zákona ');
    end;

    procedure InsertData(Code: Code[10]; Description: Text[50])
    var
        CommodityCZL: Record "Commodity CZL";
    begin
        CommodityCZL.Init();
        CommodityCZL.Code := Code;
        CommodityCZL.Description := Description;
        CommodityCZL.Insert();
    end;
}