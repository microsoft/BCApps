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
        InsertData(XForeign, XForeign);
        InsertData(XCOAST, XBelgianCoast);
        InsertData(XVOEREN, XVoerenFourons);
        InsertData(XHAGEL, XHageland);
        InsertData(XLIERHERENT, XRegionLierHerentals);
        InsertData(XKEMPLIMB, XKempenandLimburg);
        InsertData(XE, XEast);
        InsertData(XNK, XNoorderkempen);
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
        XCOAST: Label 'COAST';
        XBelgianCoast: Label 'Belgian Coast';
        XVOEREN: Label 'VOEREN';
        XVoerenFourons: Label 'Voeren/Fourons';
        XHAGEL: Label 'HAGEL';
        XHageland: Label 'Hageland';
        XLIERHERENT: Label 'LIERHERENT';
        XRegionLierHerentals: Label 'Region Lier-Herentals';
        XKEMPLIMB: Label 'KEMPLIMB';
        XKempenandLimburg: Label 'Kempen and Limburg';
        XE: Label 'E';
        XEast: Label 'East';
        XNK: Label 'NK';
        XNoorderkempen: Label 'Noorderkempen';

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

