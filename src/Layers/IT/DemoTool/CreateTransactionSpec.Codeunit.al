codeunit 161385 "Create Transaction Spec."
{

    trigger OnRun()
    begin
        InsertData(XxAT, XAustria);
        InsertData(XxDE, XGermany);
        InsertData(XxES, XSpain);
        InsertData(XxFR, XFrance);
        InsertData(XxBE, XBelgium);
        InsertData(XxBG, XBulgaria);
        InsertData(XxDK, XDenmark);
        InsertData(XxEE, XEstonia);
        InsertData(XxGB, XEngland);
        InsertData(XxNL, XHolland);
        InsertData(XxLV, XLatvia);
        InsertData(XxLT, XLithuania);
        InsertData(XxNO, XNorway);
        InsertData(XxPL, XPoland);
        InsertData(XxPT, XPortugal);
        InsertData(XxRU, XRussia);
        InsertData(XxSE, XSweden);
        InsertData(XxSI, XSlovenia);
        InsertData(XxFI, XFinland);
        InsertData(XxHU, XHungary);
        InsertData(XxRO, XRomania);
        InsertData(XxGR, XGreece);
        InsertData(XxIE, XIreland);
        InsertData(XxIS, XIceland);
        InsertData(XxIT, XItaly);
        InsertData(XxUS, XUsa);
    end;

    var
        XxAT: Label 'AT';
        XAustria: Label 'Austria';
        XxDE: Label 'DE';
        XGermany: Label 'Germany';
        XxES: Label 'ES';
        XSpain: Label 'Spain';
        XxFR: Label 'FR';
        XFrance: Label 'France';
        XxBE: Label 'BE';
        XBelgium: Label 'Belgium';
        XxBG: Label 'BG';
        XBulgaria: Label 'Bulgaria';
        XxDK: Label 'DK';
        XDenmark: Label 'Denmark';
        XxEE: Label 'EE';
        XEstonia: Label 'Estonia';
        XxGB: Label 'GB';
        XEngland: Label 'England';
        XxNL: Label 'NL';
        XHolland: Label 'Holland';
        XxLV: Label 'LV';
        XLatvia: Label 'Latvia';
        XxLT: Label 'LT';
        XLithuania: Label 'Lithuania';
        XxNO: Label 'NO';
        XNorway: Label 'Norway';
        XxPL: Label 'PL';
        XPoland: Label 'Poland';
        XxPT: Label 'PT';
        XPortugal: Label 'Portugal';
        XxRU: Label 'RU';
        XRussia: Label 'Russia';
        XxSE: Label 'SE';
        XSweden: Label 'Sweden';
        XxSI: Label 'SI';
        XSlovenia: Label 'Slovenia';
        XxFI: Label 'FI';
        XFinland: Label 'Finland';
        XxHU: Label 'HU';
        XHungary: Label 'Hungary';
        XxRO: Label 'RO';
        XRomania: Label 'Romania';
        XxGR: Label 'GR';
        XGreece: Label 'Greece';
        XxIE: Label 'IE';
        XIreland: Label 'Ireland';
        XxIS: Label 'IS';
        XIceland: Label 'Iceland';
        XxIT: Label 'IT';
        XItaly: Label 'Italy';
        XxUS: Label 'US';
        XUsa: Label 'USA';

    procedure InsertData("Code": Code[10]; Text: Text[50])
    var
        TransactionSpecification: Record "Transaction Specification";
    begin
        TransactionSpecification.Init();
        TransactionSpecification.Code := Code;
        TransactionSpecification.Text := Text;
        TransactionSpecification.Insert();
    end;
}

