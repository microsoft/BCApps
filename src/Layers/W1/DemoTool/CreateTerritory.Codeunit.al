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

    procedure InsertData("Code": Code[10]; Name: Text[30])
    begin
        Territory.Init();
        Territory.Validate(Code, Code);
        Territory.Validate(Name, Name);
        if Territory.Insert() then;
    end;

    procedure GetTerritoryCode("Country Code": Code[10]; "Code": Code[10]): Code[10]
    var
        DemoDataSetup: Record "Demo Data Setup";
    begin
        DemoDataSetup.Get();
        if ("Country Code" = '') or ("Country Code" = DemoDataSetup."Country/Region Code") then
            exit(Code);

        exit(Foreign());
    end;

    procedure Foreign(): Code[10]
    begin
        exit(XForeign);
    end;
}

