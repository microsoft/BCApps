codeunit 101552 "Create Cont. Alt. Addr. Range"
{

    trigger OnRun()
    begin
        InsertData(XCT100121, XTEMPSALES, 19020624D, 19030801D);
        InsertData(XCT100132, XHOLIDAY, 19030601D, 19030801D);
        InsertData(XCT100148, XFAIR, 19021211D, 19021223D);
        InsertData(XCT100152, XBUSINESS, 19030401D, 19030408D);
        InsertData(XCT100156, XTEMPSALES, 19030203D, 19030404D);
        InsertData(XCT100158, XBUSINESS, 19030104D, 19030109D);
        InsertData(XCT100162, XRENOVATION, 19030528D, 19030705D);
        InsertData(XCT100191, XWORKSHOP, 19030215D, 19030219D);
        InsertData(XCT100194, XOFFICE, 19040304D, 19040401D);
        InsertData(XCT100204, XWORKSHOP, 19030507D, 19030509D);
        InsertData(XCT100210, XTEMPOFFICE, 19030101D, 19030201D);
        InsertData(XCT100215, XFAIR, 19030205D, 19030214D);
        InsertData(XCT100218, XBUSINESS, 19030205D, 19030211D);
        InsertData(XCT100229, XRENOVATION, 19030324D, 19030706D);
        InsertData(XCT200009, XHOME, 19030118D, 19030501D);
        InsertData(XCT200011, XPRIVATE, 19040405D, 19040406D);
        InsertData(XCT200016, XSUMMER, 19020601D, 19020801D);
        InsertData(XCT200016, XEXHIBITION, 19030117D, 19030120D);
        InsertData(XCT200016, XSUMMER, 19030601D, 19030601D);
        InsertData(XCT200016, XSUMMER, 19040601D, 19040601D);
        InsertData(XCT200027, XBUSINESS, 19021011D, 19021018D);
        InsertData(XCT200031, XFAIR, 19021213D, 19021219D);
        InsertData(XCT200036, XHOME, 19021224D, 19030103D);
        InsertData(XCT200052, XCLOSED, 19031017D, 19031104D);
        InsertData(XCT200055, XEXHIBITION, 19030508D, 19030514D);
        InsertData(XCT200067, XHOLIDAY, 19030205D, 19030221D);
        InsertData(XCT200074, XHOLIDAY, 19020813D, 19020826D);
        InsertData(XCT200079, XLONDON, 19020101D, 19070101D);
        InsertData(XCT200080, XHOME, 19021022D, 19030405D);
        InsertData(XCT200080, XBRISTOL, 19030101D, 19040301D);
        InsertData(XCT200092, XHOME, 19030325D, 19030401D);
        InsertData(XCT200095, XHOLIDAY, 19030318D, 19030406D);
        InsertData(XCT200095, XHOLIDAY, 19040101D, 19040113D);
        InsertData(XCT200121, XHOME, 19021025D, 19030104D);
    end;

    var
        "Contact Alt. Addr. Date Range": Record "Contact Alt. Addr. Date Range";
        XCT100121: Label 'CT100121';
        XCT100132: Label 'CT100132';
        XCT100148: Label 'CT100148';
        XCT100156: Label 'CT100156';
        XCT100158: Label 'CT100158';
        XCT100162: Label 'CT100162';
        XCT100191: Label 'CT100191';
        XCT100194: Label 'CT100194';
        XCT100204: Label 'CT100204';
        XCT100210: Label 'CT100210';
        XCT100215: Label 'CT100215';
        XCT100218: Label 'CT100218';
        XCT100229: Label 'CT100229';
        XCT200009: Label 'CT200009';
        XCT200011: Label 'CT200011';
        XCT200016: Label 'CT200016';
        XCT200027: Label 'CT200027';
        XCT200031: Label 'CT200031';
        XCT200036: Label 'CT200036';
        XCT200052: Label 'CT200052';
        XCT200055: Label 'CT200055';
        XCT200067: Label 'CT200067';
        XCT200074: Label 'CT200074';
        XCT200079: Label 'CT200079';
        XCT200080: Label 'CT200080';
        XCT200092: Label 'CT200092';
        XCT200095: Label 'CT200095';
        XCT200121: Label 'CT200121';
        XCT100152: Label 'CT100152';
        MakeAdjustments: Codeunit "Make Adjustments";
        XBRISTOL: Label 'BRISTOL';
        XBUSINESS: Label 'BUSINESS';
        XCLOSED: Label 'CLOSED';
        XEXHIBITION: Label 'EXHIBITION';
        XFAIR: Label 'FAIR';
        XHOLIDAY: Label 'HOLIDAY';
        XHOME: Label 'HOME';
        XLONDON: Label 'LONDON';
        XOFFICE: Label 'OFFICE';
        XPRIVATE: Label 'PRIVATE';
        XRENOVATION: Label 'RENOVATION';
        XSUMMER: Label 'SUMMER';
        XTEMPOFFICE: Label 'TEMPOFFICE';
        XTEMPSALES: Label 'TEMPSALES';
        XWORKSHOP: Label 'WORKSHOP';

    procedure InsertData("Contact No.": Code[20]; "Contact Alt. Address Code": Code[10]; "Starting Date": Date; "Ending Date": Date)
    begin
        "Contact Alt. Addr. Date Range".Init();
        "Contact Alt. Addr. Date Range".Validate("Contact No.", "Contact No.");
        "Contact Alt. Addr. Date Range".Validate("Contact Alt. Address Code", "Contact Alt. Address Code");
        "Contact Alt. Addr. Date Range".Validate("Starting Date", MakeAdjustments.AdjustDate("Starting Date"));
        "Contact Alt. Addr. Date Range".Validate("Ending Date", MakeAdjustments.AdjustDate("Ending Date"));
        "Contact Alt. Addr. Date Range".Insert();
    end;
}

