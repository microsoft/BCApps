codeunit 101714 "Create Analysis Line"
{

    trigger OnRun()
    begin
        InsertData(
          0, XCUSTGROUPS, 10000, 'A1', XLargeBusiness,
          3, XLARGE, false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XCUSTGROUPS, 20000, 'A2', XMediumBusiness,
          3, XMEDIUM, false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XCUSTGROUPS, 30000, 'A3', XPrivate1,
          3, XPRIVATE, false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XCUSTGROUPS, 40000, 'A4', XSmallBusiness,
          3, XSMALL, false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XCUSTGROUPS, 50000, '', XTotalforCustomerGroups,
          6, 'A1..A4', false, 0, true, false, false, false, '', '', '', '');
        InsertData(
          0, XCUSTALL, 60000, 'A1', XKeyAccounts,
          2, '10000..50000', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XCUSTALL, 70000, 'A2', XOutlets,
          2, '60000..62000', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XCUSTALL, 80000, 'A3', XSmallcustomers,
          2, '01121212..49858585', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XCUSTALL, 90000, 'A4', XTotalforallcustomers,
          6, 'A1..A3', false, 0, true, false, false, false, '', '', '', '');
        InsertData(
          0, XFURNITALL, 100000, 'A1', XPartsandSpares,
          0, '70000..70060', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XFURNITALL, 110000, 'A2', XFinishedItems,
          0, '1896-S..2000-S', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XFURNITALL, 120000, 'A3', XFurniturePaint,
          0, '70100..70104', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XFURNITALL, 130000, 'A4', XFurnitureTotal,
          6, 'A1..A3', false, 0, true, false, false, false, '', '', '', '');
        InsertData(
          0, XMYCUST, 140000, 'A1', XTheCannonGroupPLC,
          2, '10000', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XMYCUST, 150000, 'A2', XSelangorianLtd,
          2, '20000', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XMYCUST, 160000, 'A3', XJohnHaddockInsuranceCo,
          2, '30000', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XMYCUST, 170000, 'A4', XDeerfieldGraphicsCompany,
          2, '40000', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XMYCUST, 180000, 'A5', XGuildfordWaterDepartment,
          2, '50000', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XMYCUST, 190000, '', XKeyAccountsTotal,
          6, 'A1..A5', false, 0, true, false, false, false, '', '', '', '');
        InsertData(
          0, XMYITEMS, 200000, '1896-S', XATHENSDesk,
          0, '1896-S', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XMYITEMS, 210000, '1900-S', XPARISGuestChairblack,
          0, '1900-S', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XMYITEMS, 220000, '1906-S', XATHENSMobilePedestal,
          0, '1906-S', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XMYITEMS, 230000, '1908-S', XLONDONSwivelChairblue,
          0, '1908-S', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XMYITEMS, 240000, '1920-S', XANTWERPConferenceTable,
          0, '1920-S', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XMYITEMS, 250000, '1924-W', XCHAMONIXBaseStorageUnit,
          0, '1924-W', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XMYITEMS, 260000, '1928-S', XAMSTERDAMLamp,
          0, '1928-S', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XMYITEMS, 270000, '1928-W', XSTMORITZStorageUnitDrawers,
          0, '1928-W', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XMYITEMS, 280000, '1936-S', XBERLINGuestChairyellow,
          0, '1936-S', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XMYITEMS, 290000, '1952-W', XOSLOStorageUnitShelf,
          0, '1952-W', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XMYITEMS, 300000, '1960-S', XROMEGuestChairgreen,
          0, '1960-S', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XMYITEMS, 310000, '1964-S', XTOKYOGuestChairblue,
          0, '1964-S', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XMYITEMS, 320000, '1964-W', XINNSBRUCKStorageUnitGDoor,
          0, '1964-W', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XMYITEMS, 330000, '1968-S', XMEXICOSwivelChairblack,
          0, '1968-S', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XMYITEMS, 340000, '1968-W', XGRENOBLEWhiteboardred,
          0, '1968-W', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XMYITEMS, 350000, '1972-S', XMUNICHSwivelChairyellow,
          0, '1972-S', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XMYITEMS, 360000, '1972-W', XSAPPOROWhiteboardblack,
          0, '1972-W', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XMYITEMS, 370000, '1976-W', XINNSBRUCKStorageUnitWDoor,
          0, '1976-W', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XMYITEMS, 380000, '1980-S', XMOSCOWSwivelChairred,
          0, '1980-S', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XMYITEMS, 390000, '1984-W', XSARAJEVOWhiteboardblue,
          0, '1984-W', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XMYITEMS, 400000, '1988-S', XSEOULGuestChairred,
          0, '1988-S', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XMYITEMS, 410000, '1988-W', XCALGARYWhiteboardyellow,
          0, '1988-W', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XMYITEMS, 420000, '1992-W', XALBERTVILLEWhiteboardgreen,
          0, '1992-W', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XMYITEMS, 430000, '1996-S', XATLANTAWhiteboardbase,
          0, '1996-S', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          0, XMYITEMS, 440000, '2000-S', XSYDNEYSwivelChairgreen,
          0, '2000-S', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          2, XFURNITALL, 450000, 'A1', XPartsandSpares,
          0, '70000..70060', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          2, XFURNITALL, 460000, 'A2', XFinishedItems,
          0, '1896-S..2000-S', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          2, XFURNITALL, 470000, 'A3', XFurniturePaint,
          0, '70100..70104', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          2, XFURNITALL, 480000, 'A4', XFurnitureTotal,
          6, 'A1..A3', false, 0, true, false, false, false, '', '', '', '');
        InsertData(
          2, XMYITEMS, 490000, '1896-S', XATHENSDesk,
          0, '1896-S', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          2, XMYITEMS, 500000, '1900-S', XPARISGuestChairblack,
          0, '1900-S', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          2, XMYITEMS, 510000, '1906-S', XATHENSMobilePedestal,
          0, '1906-S', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          2, XMYITEMS, 520000, '1908-S', XLONDONSwivelChairblue,
          0, '1908-S', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          2, XMYITEMS, 530000, '1920-S', XANTWERPConferenceTable,
          0, '1920-S', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          2, XMYITEMS, 540000, '1924-W', XCHAMONIXBaseStorageUnit,
          0, '1924-W', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          2, XMYITEMS, 550000, '1928-S', XAMSTERDAMLamp,
          0, '1928-S', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          2, XMYITEMS, 560000, '1928-W', XSTMORITZStorageUnitDrawers,
          0, '1928-W', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          2, XMYITEMS, 570000, '1936-S', XBERLINGuestChairyellow,
          0, '1936-S', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          2, XMYITEMS, 580000, '1952-W', XOSLOStorageUnitShelf,
          0, '1952-W', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          2, XMYITEMS, 590000, '1960-S', XROMEGuestChairgreen,
          0, '1960-S', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          2, XMYITEMS, 600000, '1964-S', XTOKYOGuestChairblue,
          0, '1964-S', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          2, XMYITEMS, 610000, '1964-W', XINNSBRUCKStorageUnitGDoor,
          0, '1964-W', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          2, XMYITEMS, 620000, '1968-S', XMEXICOSwivelChairblack,
          0, '1968-S', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          2, XMYITEMS, 630000, '1968-W', XGRENOBLEWhiteboardred,
          0, '1968-W', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          2, XMYITEMS, 640000, '1972-S', XMUNICHSwivelChairyellow,
          0, '1972-S', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          2, XMYITEMS, 650000, '1972-W', XSAPPOROWhiteboardblack,
          0, '1972-W', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          2, XMYITEMS, 660000, '1976-W', XINNSBRUCKStorageUnitWDoor,
          0, '1976-W', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          2, XMYITEMS, 670000, '1980-S', XMOSCOWSwivelChairred,
          0, '1980-S', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          2, XMYITEMS, 680000, '1984-W', XSARAJEVOWhiteboardblue,
          0, '1984-W', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          2, XMYITEMS, 690000, '1988-S', XSEOULGuestChairred,
          0, '1988-S', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          2, XMYITEMS, 700000, '1988-W', XCALGARYWhiteboardyellow,
          0, '1988-W', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          2, XMYITEMS, 710000, '1992-W', XALBERTVILLEWhiteboardgreen,
          0, '1992-W', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          2, XMYITEMS, 720000, '1996-S', XATLANTAWhiteboardbase,
          0, '1996-S', false, 0, false, false, false, false, '', '', '', '');
        InsertData(
          2, XMYITEMS, 730000, '2000-S', XSYDNEYSwivelChairgreen,
          0, '2000-S', false, 0, false, false, false, false, '', '', '', '');
    end;

    var
        AnalysisLine: Record "Analysis Line";
        XCUSTGROUPS: Label 'CUSTGROUPS';
        XCUSTALL: Label 'CUST-ALL';
        XFURNITALL: Label 'FURNIT-ALL';
        XMYCUST: Label 'MY-CUST';
        XMYITEMS: Label 'MY-ITEMS';
        XLARGE: Label 'LARGE';
        XMEDIUM: Label 'MEDIUM';
        XPRIVATE: Label 'PRIVATE';
        XSMALL: Label 'SMALL';
        XLargeBusiness: Label 'Large Business';
        XMediumBusiness: Label 'Medium Business';
        XPrivate1: Label 'Private';
        XSmallBusiness: Label 'Small Business';
        XTotalforCustomerGroups: Label 'Total for Customer Groups';
        XKeyAccounts: Label 'Key Accounts';
        XOutlets: Label 'Outlets';
        XSmallcustomers: Label 'Small customers';
        XTotalforallcustomers: Label 'Total for all customers';
        XPartsandSpares: Label 'Parts and Spares';
        XFinishedItems: Label 'Finished Items';
        XFurniturePaint: Label 'Furniture Paint';
        XFurnitureTotal: Label 'Furniture, Total';
        XTheCannonGroupPLC: Label 'The Cannon Group PLC';
        XSelangorianLtd: Label 'Selangorian Ltd.';
        XJohnHaddockInsuranceCo: Label 'John Haddock Insurance Co.';
        XDeerfieldGraphicsCompany: Label 'Deerfield Graphics Company';
        XGuildfordWaterDepartment: Label 'Guildford Water Department';
        XKeyAccountsTotal: Label 'Key Accounts Total';
        XATHENSDesk: Label 'ATHENS Desk';
        XPARISGuestChairblack: Label 'PARIS Guest Chair, black';
        XATHENSMobilePedestal: Label 'ATHENS Mobile Pedestal';
        XLONDONSwivelChairblue: Label 'LONDON Swivel Chair, blue';
        XANTWERPConferenceTable: Label 'ANTWERP Conference Table';
        XCHAMONIXBaseStorageUnit: Label 'CHAMONIX Base Storage Unit';
        XAMSTERDAMLamp: Label 'AMSTERDAM Lamp';
        XSTMORITZStorageUnitDrawers: Label 'ST.MORITZ Storage Unit/Drawers';
        XBERLINGuestChairyellow: Label 'BERLIN Guest Chair, yellow';
        XOSLOStorageUnitShelf: Label 'OSLO Storage Unit/Shelf';
        XROMEGuestChairgreen: Label 'ROME Guest Chair, green';
        XTOKYOGuestChairblue: Label 'TOKYO Guest Chair, blue';
        XINNSBRUCKStorageUnitGDoor: Label 'INNSBRUCK Storage Unit/G.Door';
        XMEXICOSwivelChairblack: Label 'MEXICO Swivel Chair, black';
        XGRENOBLEWhiteboardred: Label 'GRENOBLE Whiteboard, red';
        XMUNICHSwivelChairyellow: Label 'MUNICH Swivel Chair, yellow';
        XSAPPOROWhiteboardblack: Label 'SAPPORO Whiteboard, black';
        XINNSBRUCKStorageUnitWDoor: Label 'INNSBRUCK Storage Unit/W.Door';
        XMOSCOWSwivelChairred: Label 'MOSCOW Swivel Chair, red';
        XSARAJEVOWhiteboardblue: Label 'SARAJEVO Whiteboard, blue';
        XSEOULGuestChairred: Label 'SEOUL Guest Chair, red';
        XCALGARYWhiteboardyellow: Label 'CALGARY Whiteboard, yellow';
        XALBERTVILLEWhiteboardgreen: Label 'ALBERTVILLE Whiteboard, green';
        XATLANTAWhiteboardbase: Label 'ATLANTA Whiteboard, base';
        XSYDNEYSwivelChairgreen: Label 'SYDNEY Swivel Chair, green';

    procedure InsertData(AnalysisArea: Option Sales,Purchase,Inventory; AnalysisLineTemplateName: Code[10]; LineNo: Integer; RowRefNo: Code[10]; Description: Text[80]; Type: Option Item,"Item Group",Customer,"Customer Group",Vendor,"Sales/Purchase person",Formula; Range: Text[250]; NewPage: Boolean; Show: Option Yes,No,"If Any Column Not Zero"; Bold: Boolean; Italic: Boolean; Underline: Boolean; ShowOppositeSign: Boolean; Dimension1Totaling: Text[80]; Dimension2Totaling: Text[80]; Dimension3Totaling: Text[80]; GroupDimensionCode: Code[20])
    begin
        AnalysisLine.Init();
        AnalysisLine.Validate("Analysis Area", AnalysisArea);
        AnalysisLine.Validate("Analysis Line Template Name", AnalysisLineTemplateName);
        AnalysisLine.Validate("Line No.", LineNo);
        AnalysisLine.Validate("Row Ref. No.", RowRefNo);
        AnalysisLine.Validate(Description, Description);
        AnalysisLine.Validate(Type, Type);
        AnalysisLine.Validate(Range, Range);
        AnalysisLine.Validate("New Page", NewPage);
        AnalysisLine.Validate(Show, Show);
        AnalysisLine.Validate(Bold, Bold);
        AnalysisLine.Validate(Italic, Italic);
        AnalysisLine.Validate(Underline, Underline);
        AnalysisLine.Validate("Show Opposite Sign", ShowOppositeSign);
        AnalysisLine.Validate("Dimension 1 Totaling", Dimension1Totaling);
        AnalysisLine.Validate("Dimension 2 Totaling", Dimension2Totaling);
        AnalysisLine.Validate("Dimension 3 Totaling", Dimension3Totaling);
        AnalysisLine.Validate("Group Dimension Code", GroupDimensionCode);
        AnalysisLine.Insert(true);
    end;
}

