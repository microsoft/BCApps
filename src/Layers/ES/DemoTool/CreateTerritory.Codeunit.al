codeunit 101286 "Create Territory"
{

    trigger OnRun()
    begin
        // The following are translatable
        InsertData(XN, XNorth);
        InsertData(XNW, XNorthWest);
        InsertData(XNE, XNorthEast);
        InsertData(XS, XSouth);
        InsertData(XSW, XSouthWest);
        InsertData(XSE, XSouthEast);
        InsertData(XW, XWestCountry);
        InsertData(XNWAL, XNorthWales);
        InsertData(XSWAL, XSouthWales);
        InsertData(XEANG, XEastAnglia);
        InsertData(XLND, XLondon);
        InsertData(XMID, XMidlands);
        InsertData(XSCOT, XScotland);
        InsertData(XGAL, XGalicia);
        InsertData(XCAT, XCataluna);
        InsertData(XAST, XAsturias);
        InsertData(XCANT, XCantabria);
        InsertData(XNAV, XNavarra);
        InsertData(XRIO, XRioja);
        InsertData(XARA, XAragon);
        InsertData(XBAL, XBaleares);
        InsertData(XMAD, XMadrid);
        InsertData(XCAN, XCanarias);
        InsertData(XVAL, XValencia);
        InsertData(XCASLEO, XCastillaLeon);
        InsertData(XCASMAN, XCastillaLaMancha);
        InsertData(XEXT, XExtremadura);
        InsertData(XMUR, XMurcia);
        InsertData(XAND, XAndalucia);
        InsertData(XCEU, XCeuta);
        InsertData(XMEL, XMelilla);
        InsertData(XForeign, XForeign);
        // The following are double-entries due to codeunit 101550 that demands with and without translation
        InsertData('EANG', 'East Anglia');
        InsertData('SCOT', 'Scotland');
        InsertData('LND', 'London');
        InsertData('SWAL', 'South Wales');
        InsertData('NWAL', 'North Wales');
        InsertData('MID', 'Midlands');
    end;

    var
        Territory: Record Territory;
        XN: Label 'N';
        XNW: Label 'NW';
        XNorth: Label 'North';
        XNE: Label 'NE';
        XNorthEast: Label 'North East';
        XNorthWest: Label 'North West';
        XS: Label 'S';
        XSouth: Label 'South';
        XSW: Label 'SW';
        XSouthWest: Label 'South West';
        XSE: Label 'SE';
        XSouthEast: Label 'South East';
        XW: Label 'W';
        XWestCountry: Label 'West Country';
        XNWAL: Label 'NWAL';
        XNorthWales: Label 'North Wales';
        XSWAL: Label 'SWAL';
        XSouthWales: Label 'South Wales';
        XEANG: Label 'EANG';
        XEastAnglia: Label 'East Anglia';
        XLND: Label 'LND';
        XLondon: Label 'London';
        XMID: Label 'MID';
        XMidlands: Label 'Midlands';
        XSCOT: Label 'SCOT';
        XScotland: Label 'Scotland';
        XForeign: Label 'Foreign';
        XGAL: Label 'GAL';
        XGalicia: Label 'Galicia';
        XCAT: Label 'CAT';
        XCataluna: Label 'Cataluña';
        XAST: Label 'AST';
        XAsturias: Label 'Asturias';
        XCANT: Label 'CANT';
        XCantabria: Label 'Cantabria';
        XNAV: Label 'NAV';
        XNavarra: Label 'Navarra';
        XRIO: Label 'RIO';
        XRioja: Label 'Rioja';
        XARA: Label 'ARA';
        XAragon: Label 'Aragón';
        XBAL: Label 'BAL';
        XBaleares: Label 'Baleares';
        XMAD: Label 'MAD';
        XMadrid: Label 'Madrid';
        XCAN: Label 'CAN';
        XCanarias: Label 'Canarias';
        XVAL: Label 'VAL';
        XValencia: Label 'Valencia';
        XCASLEO: Label 'CASLEO';
        XCastillaLeon: Label 'Castilla - León';
        XCASMAN: Label 'CASMAN';
        XCastillaLaMancha: Label 'Castilla - La Mancha';
        XEXT: Label 'EXT';
        XExtremadura: Label 'Extremadura';
        XMUR: Label 'MUR';
        XMurcia: Label 'Murcia';
        XAND: Label 'AND';
        XAndalucia: Label 'Andalucia';
        XCEU: Label 'CEU';
        XCeuta: Label 'Ceuta';
        XMEL: Label 'MEL';
        XMelilla: Label 'Melilla';

    procedure InsertData("Code": Code[10]; Name: Text[30])
    begin
        Territory.Init();
        Territory.Validate(Code, Code);
        Territory.Validate(Name, Name);
        if Territory.Insert() then;
    end;

    procedure GetTerritoryCode("Country Code": Code[10]; "Code": Code[10]): Code[10]
    begin
        if "Country Code" = '' then
            exit(Code)
        else
            exit(Foreign());
    end;

    procedure Foreign(): Code[10]
    begin
        exit(XForeign);
    end;
}

