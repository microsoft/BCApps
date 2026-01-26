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
        //BEGIN IT
        InsertData(XxVALDAOSTA, XValleDAosta);
        InsertData(XxPIEMONTE, XPiemonte);
        InsertData(XxLIGURIA, XLiguria);
        InsertData(XxTRALTOADIG, XTrentinoAltoAdige);
        InsertData(XxFRVENGIU, XFriuliVeneziaGiulia);
        InsertData(XxVENETO, XVeneto);
        InsertData(XxEMROMAGNA, XEmiliaRomagna);
        InsertData(XxTOSCANA, XToscana);
        InsertData(XxMARCHE, XMarche);
        InsertData(XxUMBRIA, XUmbria);
        InsertData(XxLAZIO, XLazio);
        InsertData(XxABRUZZO, XAbruzzo);
        InsertData(XxMOLISE, XMolise);
        InsertData(XxCAMPANIA, XCampania);
        InsertData(XxPUGLIA, XPuglia);
        InsertData(XxBASILICATA, XBasilicata);
        InsertData(XxCALABRIA, XCalabria);
        InsertData(XxSICILIA, XSicilia);
        InsertData(XxSARDEGNA, XSardegna);
        //END IT

        // The following are double-entries due to codeunit 101550 that demands with and without translation
        InsertData('EANG', 'East Anglia');
        InsertData('SCOT', 'Scotland');
        InsertData('LND', 'London');
        InsertData('SWAL', 'South Wales');
        InsertData('NWAL', 'North Wales');
        InsertData('MID', 'Midlands');
    end;

    var
        XxVALDAOSTA: Label 'VALDAOSTA';
        XValleDAosta: Label 'Valle d''Aosta';
        XxPIEMONTE: Label 'PIEMONTE';
        XPiemonte: Label 'Piemonte';
        XxLIGURIA: Label 'LIGURIA';
        XLiguria: Label 'Liguria';
        XxTRALTOADIG: Label 'TRALTOADIG';
        XTrentinoAltoAdige: Label 'Trentino Alto Adige';
        XxFRVENGIU: Label 'FRVENGIU';
        XFriuliVeneziaGiulia: Label 'Friuli Venezia Giulia';
        XxVENETO: Label 'VENETO';
        XVeneto: Label 'Veneto';
        XxEMROMAGNA: Label 'EMROMAGNA';
        XEmiliaRomagna: Label 'Emilia Romagna';
        XxTOSCANA: Label 'TOSCANA';
        XToscana: Label 'Toscana';
        XxMARCHE: Label 'MARCHE';
        XMarche: Label 'Marche';
        XxUMBRIA: Label 'UMBRIA';
        XUmbria: Label 'Umbria';
        XxLAZIO: Label 'LAZIO';
        XLazio: Label 'Lazio';
        XxABRUZZO: Label 'ABRUZZO';
        XAbruzzo: Label 'Abruzzo';
        XxMOLISE: Label 'MOLISE';
        XMolise: Label 'Molise';
        XxCAMPANIA: Label 'CAMPANIA';
        XCampania: Label 'Campania';
        XxPUGLIA: Label 'PUGLIA';
        XPuglia: Label 'Puglia';
        XxBASILICATA: Label 'BASILICATA';
        XBasilicata: Label 'Basilicata';
        XxCALABRIA: Label 'CALABRIA';
        XCalabria: Label 'Calabria';
        XxSICILIA: Label 'SICILIA';
        XSicilia: Label 'Sicilia';
        XxSARDEGNA: Label 'SARDEGNA';
        XSardegna: Label 'Sardegna';
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

