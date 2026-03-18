codeunit 101559 "Create Web Source"
{

    trigger OnRun()
    begin
        InsertData('ADATUM', 'Adatum',
          'http://www.adatum.com/');
        InsertData('FABRIKAM', '​Fabrikam, Inc.', 'http://www.fabrikam.com/');
        InsertData('LUCERNE', 'Lucerne Publishing', 'http://www.lucernepublishing.com/');
        InsertData(XUSSTOCK, XStockinfobysymbol, Xhttpcolslslfindotyahoodotcom);
        InsertData('CONTOSO', 'Contoso, Ltd.', 'http://www.contoso.com/');
    end;

    var
        "Web Source": Record "Web Source";
        XUSSTOCK: Label 'US-STOCK';
        XStockinfobysymbol: Label 'Stock info by symbol';
        Xhttpcolslslfindotyahoodotcom: Label '​http://firstupconsultants.com';

    procedure InsertData("Code": Code[10]; Description: Text[30]; URL: Text[250])
    begin
        "Web Source".Init();
        "Web Source".Validate(Code, Code);
        "Web Source".Validate(Description, Description);
        "Web Source".Validate(URL, URL);
        "Web Source".Insert();
    end;
}

