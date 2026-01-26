codeunit 101258 "Create Transaction Type"
{

    trigger OnRun()
    begin
        InsertData('11', 'Rechtstreekse verkoop/aankoop, behalve rechtstr. handel met/door partic. consum.');
        InsertData('12', 'Directe handel met/door particuliere consumenten (incl. verkoop op afstand)');
        InsertData('21', 'Retourzendingen van goederen');
        InsertData('22', 'Vervanging van teruggezonden goederen');
        InsertData('23', 'Vervanging (bv. onder garantie) van goederen die niet zijn teruggezonden');
        InsertData('31', 'Vervoer van of naar een opslagr. (met uitz. van voorraad op afroep en consig.)');
        InsertData('32', 'Zicht- of proefzending (met inbegrip van voorraad op afroep en consignatie)');
        InsertData('33', 'Financiële leasing');
        InsertData('34', 'Transacties waarbij de eigendom wordt overgedragen zonder financiële compensatie');
        InsertData('41', 'Goed.waar.wordt verw. dat zij terug.naar de aanv.lids./het aanv.land van uitvoer');
        InsertData('42', 'Goed.waar.niet wordt verw.dat zij terug.naar de aanv.lids./het aanv.land v.uitv.');
        InsertData('51', 'Goed. die terugkeren naar de aanvank. lidstaat/het aanvank. land van uitvoer');
        InsertData('52', 'Goed. die niet terugkeren naar de aanvank.lidstaat/het aanvank. land van uitvoer');
        InsertData('71', 'Goed. in het vrije verk.brengen in een lids.en ze verv.uitv.naar een and.lidst.');
        InsertData('72', 'Vervoer van goed.van een lids.naar een and.lids.om de goed.ond.de uitv.te plaat.');
        InsertData('91', 'Huur, bruikleen en operationele lease gedurende meer dan 24 maanden');
        InsertData('99', 'Andere');
    end;

    var
        "Transaction Type": Record "Transaction Type";

    [Scope('OnPrem')]
    procedure InsertData("Code": Code[10]; Description: Text[80])
    begin
        "Transaction Type".Init();
        "Transaction Type".Validate(Code, Code);
        "Transaction Type".Validate(Description, Description);
        "Transaction Type".Insert();
    end;
}

