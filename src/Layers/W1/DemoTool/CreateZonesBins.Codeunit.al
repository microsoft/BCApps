codeunit 118833 "Create Zones / Bins"
{

    trigger OnRun()
    begin
        // Zones
        InsertZone(XWHITE, XBULK, XStorageZone, XPutAWAY, '', XLIFT, 50, false);
        InsertZone(XWHITE, XPICK, XPickingZone, XPUTPICK, '', '', 100, false);
        InsertZone(XWHITE, XRECEIVE, XReceivingZone, XRECEIVE, '', XHT1, 10, false);
        InsertZone(XWHITE, XSHIP, XShippingZone, XSHIP, '', XHT2, 200, false);
        InsertZone(XWHITE, XQC, XQualityAssuranceZone, XQC, '', '', 0, false);
        InsertZone(XWHITE, XSTAGE, XStagingZone, XPICK, '', '', 5, false);
        InsertZone(XWHITE, XADJUSTMENT, XVirtualforAdjustment, XQC, '', '', 0, false);
        InsertZone(XWHITE, XPRODUCTION, XProductionlc, XQC, '', XLIFT, 5, false);
        InsertZone(XWHITE, XCROSSDOCK, XCrossDocklc, XPUTPICK, '', '', 0, true);

        // Bins
        InsertBin(XWHITE, XBULK, XW050001, XPutAWAY, '', 0, '', 60, 15000, 15000, false, false);
        InsertBin(XWHITE, XBULK, XW050002, XPutAWAY, '', 0, '', 60, 15000, 15000, false, false);
        InsertBin(XWHITE, XBULK, XW050003, XPutAWAY, '', 0, '', 60, 15000, 15000, false, false);
        InsertBin(XWHITE, XBULK, XW050004, XPutAWAY, '', 0, '', 60, 15000, 15000, false, false);
        InsertBin(XWHITE, XBULK, XW050005, XPutAWAY, '', 0, '', 60, 1500, 1000, false, false);
        InsertBin(XWHITE, XBULK, XW050006, XPutAWAY, '', 0, '', 50, 1500, 1000, false, false);
        InsertBin(XWHITE, XBULK, XW050007, XPutAWAY, '', 0, '', 50, 15000, 15000, false, false);
        InsertBin(XWHITE, XBULK, XW050008, XPutAWAY, '', 0, '', 50, 15000, 15000, false, false);
        InsertBin(XWHITE, XBULK, XW050009, XPutAWAY, '', 0, '', 50, 15000, 15000, false, false);
        InsertBin(XWHITE, XBULK, XW050010, XPutAWAY, '', 0, '', 50, 15000, 15000, false, false);
        InsertBin(XWHITE, XBULK, XW050011, XPutAWAY, '', 0, '', 50, 15000, 15000, false, false);
        InsertBin(XWHITE, XBULK, XW050012, XPutAWAY, '', 0, '', 50, 15000, 15000, false, false);
        InsertBin(XWHITE, XBULK, XW050013, XPutAWAY, '', 0, '', 50, 15000, 15000, false, false);
        InsertBin(XWHITE, XBULK, XW050014, XPutAWAY, '', 0, '', 50, 15000, 15000, false, false);
        InsertBin(XWHITE, XBULK, XW050015, XPutAWAY, '', 0, '', 50, 3000, 2000, false, false);
        InsertBin(XWHITE, XBULK, XW050016, XPutAWAY, '', 0, '', 50, 3000, 2000, false, false);
        InsertBin(XWHITE, XBULK, XW050017, XPutAWAY, '', 0, '', 50, 3000, 2000, false, false);

        InsertBin(XWHITE, XPICK, XW010001, XPUTPICK, '', 0, '', 100, 15000, 15000, false, false);
        InsertBin(XWHITE, XPICK, XW010002, XPUTPICK, '', 0, '', 90, 250, 150, false, false);
        InsertBin(XWHITE, XPICK, XW010003, XPUTPICK, '', 0, '', 90, 250, 150, false, false);
        InsertBin(XWHITE, XPICK, XW020001, XPUTPICK, '', 0, '', 100, 15000, 15000, false, false);
        InsertBin(XWHITE, XPICK, XW020002, XPUTPICK, '', 0, '', 90, 250, 150, false, false);
        InsertBin(XWHITE, XPICK, XW020003, XPUTPICK, '', 0, '', 90, 15000, 15000, false, false);
        InsertBin(XWHITE, XPICK, XW030001, XPUTPICK, '', 0, '', 100, 2500, 15000, false, false);
        InsertBin(XWHITE, XPICK, XW030002, XPUTPICK, '', 0, '', 90, 280, 200, false, false);
        InsertBin(XWHITE, XPICK, XW030003, XPUTPICK, '', 0, '', 90, 280, 200, false, false);
        InsertBin(XWHITE, XPICK, XW040001, XPUTPICK, '', 0, '', 100, 250, 150, false, false);
        InsertBin(XWHITE, XPICK, XW040002, XPUTPICK, '', 0, '', 90, 250, 150, false, false);
        InsertBin(XWHITE, XPICK, XW040003, XPUTPICK, '', 0, '', 90, 15000, 15000, false, false);
        InsertBin(XWHITE, XPICK, XW040004, XPUTPICK, '', 0, '', 90, 15000, 15000, false, false);
        InsertBin(XWHITE, XPICK, XW040005, XPUTPICK, '', 0, '', 90, 15000, 15000, false, false);
        InsertBin(XWHITE, XPICK, XW040006, XPUTPICK, '', 0, '', 90, 250, 150, false, false);
        InsertBin(XWHITE, XPICK, XW040007, XPUTPICK, '', 0, '', 90, 250, 150, false, false);
        InsertBin(XWHITE, XPICK, XW040008, XPUTPICK, '', 0, '', 90, 250, 150, false, false);
        InsertBin(XWHITE, XPICK, XW040009, XPUTPICK, '', 0, '', 90, 250, 150, false, false);
        InsertBin(XWHITE, XPICK, XW040010, XPUTPICK, '', 0, '', 90, 250, 150, false, false);
        InsertBin(XWHITE, XPICK, XW040011, XPUTPICK, '', 0, '', 90, 250, 150, false, false);
        InsertBin(XWHITE, XPICK, XW040012, XPUTPICK, '', 0, '', 90, 15000, 15000, false, false);
        InsertBin(XWHITE, XPICK, XW040013, XPUTPICK, '', 0, '', 90, 15000, 15000, false, false);
        InsertBin(XWHITE, XPICK, XW040014, XPUTPICK, '', 0, '', 90, 15000, 15000, false, false);
        InsertBin(XWHITE, XPICK, XW040015, XPUTPICK, '', 0, '', 90, 15000, 15000, false, false);

        InsertBin(XWHITE, XReceivelc, XW080001, XRECEIVE, '', 0, '', 0, 10000, 10000, false, false);
        InsertBin(XWHITE, XReceivelc, XW080002, XRECEIVE, '', 0, '', 0, 10000, 10000, false, false);
        InsertBin(XWHITE, XReceivelc, XW080003, XRECEIVE, '', 0, '', 0, 10000, 10000, false, false);
        InsertBin(XWHITE, XReceivelc, XW080004, XRECEIVE, '', 0, '', 0, 10000, 10000, false, false);

        InsertBin(XWHITE, XSHIP, XW090001, XSHIP, '', 0, '', 200, 20000, 30000, false, false);
        InsertBin(XWHITE, XSHIP, XW090002, XSHIP, '', 0, '', 200, 20000, 30000, false, false);
        InsertBin(XWHITE, XSHIP, XW090003, XSHIP, '', 0, '', 200, 20000, 30000, false, false);
        InsertBin(XWHITE, XSHIP, XW090004, XSHIP, '', 0, '', 200, 20000, 30000, false, false);
        InsertBin(XWHITE, XSHIP, XW090005, XSHIP, '', 0, '', 200, 20000, 30000, false, false);
        InsertBin(XWHITE, XSHIP, XW090006, XSHIP, '', 0, '', 200, 20000, 30000, false, false);

        InsertBin(XWHITE, XQC, XW100001, XQC, '', 0, '', 0, 20000, 30000, false, false);
        InsertBin(XWHITE, XQC, XW100002, XQC, '', 0, '', 0, 20000, 30000, false, false);

        InsertBin(XWHITE, XSTAGE, XW060001, XPICK, '', 0, '', 0, 10000, 30000, false, false);
        InsertBin(XWHITE, XSTAGE, XW060002, XPICK, '', 0, '', 0, 10000, 30000, false, false);
        InsertBin(XWHITE, XSTAGE, XW060003, XPICK, '', 0, '', 0, 3000, 3000, false, false);
        InsertBin(XWHITE, XSTAGE, XW060004, XPICK, '', 0, '', 0, 3000, 3000, false, false);
        InsertBin(XWHITE, XSTAGE, XW060005, XPICK, '', 0, '', 0, 300, 300, false, false);
        InsertBin(XWHITE, XSTAGE, XW060006, XPICK, '', 0, '', 0, 300, 300, false, false);

        InsertBin(XWHITE, XPRODUCTION, XW070001, XQC, '', 0, '', 0, 20000, 30000, false, true);
        InsertBin(XWHITE, XPRODUCTION, XW070002, XQC, '', 0, '', 0, 20000, 30000, false, true);
        InsertBin(XWHITE, XPRODUCTION, XW070003, XQC, '', 0, '', 0, 20000, 30000, false, true);
        InsertBin(XWHITE, XPRODUCTION, XW070004, XQC, '', 0, '', 0, 20000, 30000, false, true);

        InsertBin(XWHITE, XADJUSTMENT, XW110001, XQC, '', 0, '', 0, 20000, 30000, false, false);
        InsertBin(XWHITE, XADJUSTMENT, XW110002, XQC, '', 0, '', 0, 20000, 30000, false, false);

        InsertBin(XWHITE, XCROSSDOCK, XW140001, XPUTPICK, '', 0, '', 500, 0, 0, true, false);
        InsertBin(XWHITE, XCROSSDOCK, XW140002, XPUTPICK, '', 0, '', 500, 0, 0, true, false);
        InsertBin(XWHITE, XCROSSDOCK, XW140003, XPUTPICK, '', 0, '', 500, 0, 0, true, false);
        InsertBin(XWHITE, XCROSSDOCK, XW140004, XPUTPICK, '', 0, '', 500, 0, 0, true, false);

        InsertBin(XSILVER, '', XS010001, '', '', 0, '', 0, 0, 0, false, false);
        InsertBin(XSILVER, '', XS010002, '', '', 0, '', 0, 0, 0, false, false);
        InsertBin(XSILVER, '', XS010003, '', '', 0, '', 0, 0, 0, false, false);
        InsertBin(XSILVER, '', XS020001, '', '', 0, '', 0, 0, 0, false, false);
        InsertBin(XSILVER, '', XS020002, '', '', 0, '', 0, 0, 0, false, false);
        InsertBin(XSILVER, '', XS020003, '', '', 0, '', 0, 0, 0, false, false);
        InsertBin(XSILVER, '', XS030001, '', '', 0, '', 0, 0, 0, false, false);
        InsertBin(XSILVER, '', XS030002, '', '', 0, '', 0, 0, 0, false, false);
        InsertBin(XSILVER, '', XS030003, '', '', 0, '', 0, 0, 0, false, false);
        InsertBin(XSILVER, '', XS040001, '', '', 0, '', 0, 0, 0, false, false);
        InsertBin(XSILVER, '', XS040002, '', '', 0, '', 0, 0, 0, false, false);
        InsertBin(XSILVER, '', XS040003, '', '', 0, '', 0, 0, 0, false, false);
        InsertBin(XSILVER, '', XS040004, '', '', 0, '', 0, 0, 0, false, false);
        InsertBin(XSILVER, '', XS040005, '', '', 0, '', 0, 0, 0, false, false);
        InsertBin(XSILVER, '', XS040006, '', '', 0, '', 0, 0, 0, false, false);
        InsertBin(XSILVER, '', XS040007, '', '', 0, '', 0, 0, 0, false, false);
        InsertBin(XSILVER, '', XS040008, '', '', 0, '', 0, 0, 0, false, false);
        InsertBin(XSILVER, '', XS040009, '', '', 0, '', 0, 0, 0, false, false);
        InsertBin(XSILVER, '', XS040010, '', '', 0, '', 0, 0, 0, false, false);
        InsertBin(XSILVER, '', XS040011, '', '', 0, '', 0, 0, 0, false, false);
        InsertBin(XSILVER, '', XS040012, '', '', 0, '', 0, 0, 0, false, false);
        InsertBin(XSILVER, '', XS040013, '', '', 0, '', 0, 0, 0, false, false);
        InsertBin(XSILVER, '', XS040014, '', '', 0, '', 0, 0, 0, false, false);
        InsertBin(XSILVER, '', XS040015, '', '', 0, '', 0, 0, 0, false, false);

        InsertBin(XSILVER, '', XS080001, '', '', 0, '', 0, 0, 0, false, false);
        InsertBin(XSILVER, '', XS080002, '', '', 0, '', 0, 0, 0, false, false);
        InsertBin(XSILVER, '', XS080003, '', '', 0, '', 0, 0, 0, false, false);
        InsertBin(XSILVER, '', XS080004, '', '', 0, '', 0, 0, 0, false, false);

        InsertBin(XSILVER, '', XS090001, '', '', 0, '', 0, 0, 0, false, false);
        InsertBin(XSILVER, '', XS090002, '', '', 0, '', 0, 0, 0, false, false);
        InsertBin(XSILVER, '', XS090003, '', '', 0, '', 0, 0, 0, false, false);
        InsertBin(XSILVER, '', XS090004, '', '', 0, '', 0, 0, 0, false, false);
        InsertBin(XSILVER, '', XS090005, '', '', 0, '', 0, 0, 0, false, false);
        InsertBin(XSILVER, '', XS090006, '', '', 0, '', 0, 0, 0, false, false);

        InsertBin(XSILVER, '', XS070001, '', '', 0, '', 0, 0, 0, false, false);
        InsertBin(XSILVER, '', XS070002, '', '', 0, '', 0, 0, 0, false, false);
        InsertBin(XSILVER, '', XS070003, '', '', 0, '', 0, 0, 0, false, false);
        InsertBin(XSILVER, '', XS070004, '', '', 0, '', 0, 0, 0, false, false);

        // Bin Contents
        InsertBinContent(XWHITE, XBULK, XW050001, 'LS-MAN-10', '', XPCS, XPutAWAY, '', 0, 2500, 60, true, 0, false);
        InsertBinContent(XWHITE, XBULK, XW050002, 'LS-S15', '', XPCS, XPutAWAY, '', 0, 500, 60, true, 0, false);
        InsertBinContent(XWHITE, XBULK, XW050003, 'LS-10PC', '', XBOX, XPutAWAY, '', 0, 400, 60, true, 0, false);
        InsertBinContent(XWHITE, XBULK, XW050004, 'LS-10PC', '', XBOX, XPutAWAY, '', 0, 400, 60, true, 0, false);
        InsertBinContent(XWHITE, XBULK, XW050005, 'LS-120', '', XPCS, XPutAWAY, '', 0, 30, 60, true, 0, false);
        InsertBinContent(XWHITE, XBULK, XW050006, 'LS-120', '', XPCS, XPutAWAY, '', 0, 30, 50, true, 0, false);
        InsertBinContent(XWHITE, XBULK, XW050007, 'LS-150', '', XPCS, XPutAWAY, '', 0, 20, 50, true, 0, false);
        InsertBinContent(XWHITE, XBULK, XW050008, 'LS-150', '', XPCS, XPutAWAY, '', 0, 20, 50, true, 0, false);
        InsertBinContent(XWHITE, XBULK, XW050009, 'LS-2', '', XBOX, XPutAWAY, '', 0, 1200, 50, true, 0, false);
        InsertBinContent(XWHITE, XBULK, XW050010, 'LS-75', '', XPCS, XPutAWAY, '', 0, 40, 50, true, 0, false);
        InsertBinContent(XWHITE, XBULK, XW050011, 'LS-75', '', XPCS, XPutAWAY, '', 0, 40, 50, true, 0, false);

        InsertBinContent(XWHITE, XPICK, XW010001, 'LS-75', '', XPCS, XPUTPICK, '', 12, 40, 100, true, 0, false);
        InsertBinContent(XWHITE, XPICK, XW010002, 'LS-75', '', XPCS, XPUTPICK, '', 2, 8, 90, true, 0, false);
        InsertBinContent(XWHITE, XPICK, XW010003, 'LS-10PC', '', XBOX, XPUTPICK, '', 100, 400, 90, true, 0, false);
        InsertBinContent(XWHITE, XPICK, XW020001, 'LS-120', '', XPCS, XPUTPICK, '', 10, 30, 100, true, 0, false);
        InsertBinContent(XWHITE, XPICK, XW020002, 'LS-120', '', XPCS, XPUTPICK, '', 6, 10, 90, true, 0, false);
        InsertBinContent(XWHITE, XPICK, XW020003, 'LS-S15', '', XPCS, XPUTPICK, '', 10, 50, 90, true, 0, false);
        InsertBinContent(XWHITE, XPICK, XW030001, 'LS-150', '', XPCS, XPUTPICK, '', 10, 20, 100, true, 0, false);
        InsertBinContent(XWHITE, XPICK, XW030002, 'LS-150', '', XPCS, XPUTPICK, '', 2, 6, 90, true, 0, false);
        InsertBinContent(XWHITE, XPICK, XW030003, 'LS-2', '', XBOX, XPUTPICK, '', 20, 200, 90, true, 0, false);
        InsertBinContent(XWHITE, XPICK, XW040001, 'LS-10PC', '', XBOX, XPUTPICK, '', 10, 40, 100, true, 0, false);
        InsertBinContent(XWHITE, XPICK, XW040002, 'LS-MAN-10', '', XPCS, XPUTPICK, '', 1000, 2500, 90, true, 0, false);

        InsertBinContent(XSILVER, '', XS010001, 'LS-75', '', XPCS, '', '', 0, 0, 0, true, 0, true);
        InsertBinContent(XSILVER, '', XS020001, 'LS-120', '', XPCS, '', '', 0, 0, 0, true, 0, true);
        InsertBinContent(XSILVER, '', XS030001, 'LS-150', '', XPCS, '', '', 0, 0, 0, true, 0, true);
    end;

    var
        XWHITE: Label 'WHITE';
        XBULK: Label 'BULK';
        XStorageZone: Label 'Storage Zone';
        XPutAWAY: Label 'Put AWAY';
        XLIFT: Label 'LIFT';
        XPICK: Label 'PICK';
        XPickingZone: Label 'Picking Zone';
        XPUTPICK: Label 'PUTPICK';
        XRECEIVE: Label 'RECEIVE';
        XReceivingZone: Label 'Receiving Zone';
        XHT1: Label 'HT1';
        XSHIP: Label 'SHIP';
        XShippingZone: Label 'Shipping Zone';
        XHT2: Label 'HT2';
        XQC: Label 'QC';
        XQualityAssuranceZone: Label 'Quality Assurance Zone';
        XSTAGE: Label 'STAGE';
        XStagingZone: Label 'Staging Zone';
        XADJUSTMENT: Label 'ADJUSTMENT';
        XVirtualforAdjustment: Label 'Virtual for Adjustment';
        XPRODUCTION: Label 'PRODUCTION';
        XProductionlc: Label 'Production';
        XCROSSDOCK: Label 'CROSS-DOCK';
        XCrossDocklc: Label 'Cross-Dock';
        XW050001: Label 'W-05-0001';
        XW050002: Label 'W-05-0002';
        XW050003: Label 'W-05-0003';
        XW050004: Label 'W-05-0004';
        XW050005: Label 'W-05-0005';
        XW050006: Label 'W-05-0006';
        XW050007: Label 'W-05-0007';
        XW050008: Label 'W-05-0008';
        XW050009: Label 'W-05-0009';
        XW050010: Label 'W-05-0010';
        XW050011: Label 'W-05-0011';
        XW050012: Label 'W-05-0012';
        XW050013: Label 'W-05-0013';
        XW050014: Label 'W-05-0014';
        XW050015: Label 'W-05-0015';
        XW050016: Label 'W-05-0016';
        XW050017: Label 'W-05-0017';
        XW010001: Label 'W-01-0001';
        XW010002: Label 'W-01-0002';
        XW010003: Label 'W-01-0003';
        XW020001: Label 'W-02-0001';
        XW020002: Label 'W-02-0002';
        XW020003: Label 'W-02-0003';
        XW030001: Label 'W-03-0001';
        XW030002: Label 'W-03-0002';
        XW030003: Label 'W-03-0003';
        XW040001: Label 'W-04-0001';
        XW040002: Label 'W-04-0002';
        XW040003: Label 'W-04-0003';
        XW040004: Label 'W-04-0004';
        XW040005: Label 'W-04-0005';
        XW040006: Label 'W-04-0006';
        XW040007: Label 'W-04-0007';
        XW040008: Label 'W-04-0008';
        XW040009: Label 'W-04-0009';
        XW040010: Label 'W-04-0010';
        XW040011: Label 'W-04-0011';
        XW040012: Label 'W-04-0012';
        XW040013: Label 'W-04-0013';
        XW040014: Label 'W-04-0014';
        XW040015: Label 'W-04-0015';
        XReceivelc: Label 'Receive';
        XW080001: Label 'W-08-0001';
        XW080002: Label 'W-08-0002';
        XW080003: Label 'W-08-0003';
        XW080004: Label 'W-08-0004';
        XW090001: Label 'W-09-0001';
        XW090002: Label 'W-09-0002';
        XW090003: Label 'W-09-0003';
        XW090004: Label 'W-09-0004';
        XW090005: Label 'W-09-0005';
        XW090006: Label 'W-09-0006';
        XW100001: Label 'W-10-0001';
        XW100002: Label 'W-10-0002';
        XW060001: Label 'W-06-0001';
        XW060002: Label 'W-06-0002';
        XW060003: Label 'W-06-0003';
        XW060004: Label 'W-06-0004';
        XW060005: Label 'W-06-0005';
        XW060006: Label 'W-06-0006';
        XW070001: Label 'W-07-0001';
        XW070002: Label 'W-07-0002';
        XW070003: Label 'W-07-0003';
        XW070004: Label 'W-07-0004';
        XW110001: Label 'W-11-0001';
        XW110002: Label 'W-11-0002';
        XW140001: Label 'W-14-0001';
        XW140002: Label 'W-14-0002';
        XW140003: Label 'W-14-0003';
        XW140004: Label 'W-14-0004';
        XS010001: Label 'S-01-0001';
        XS010002: Label 'S-01-0002';
        XS010003: Label 'S-01-0003';
        XS020001: Label 'S-02-0001';
        XS020002: Label 'S-02-0002';
        XS020003: Label 'S-02-0003';
        XS030001: Label 'S-03-0001';
        XS030002: Label 'S-03-0002';
        XS030003: Label 'S-03-0003';
        XS040001: Label 'S-04-0001';
        XS040002: Label 'S-04-0002';
        XS040003: Label 'S-04-0003';
        XS040004: Label 'S-04-0004';
        XS040005: Label 'S-04-0005';
        XS040006: Label 'S-04-0006';
        XS040007: Label 'S-04-0007';
        XS040008: Label 'S-04-0008';
        XS040009: Label 'S-04-0009';
        XS040010: Label 'S-04-0010';
        XS040011: Label 'S-04-0011';
        XS040012: Label 'S-04-0012';
        XS040013: Label 'S-04-0013';
        XS040014: Label 'S-04-0014';
        XS040015: Label 'S-04-0015';
        XSILVER: Label 'SILVER';
        XS080001: Label 'S-08-0001';
        XS080002: Label 'S-08-0002';
        XS080003: Label 'S-08-0003';
        XS080004: Label 'S-08-0004';
        XS090001: Label 'S-09-0001';
        XS090002: Label 'S-09-0002';
        XS090003: Label 'S-09-0003';
        XS090004: Label 'S-09-0004';
        XS090005: Label 'S-09-0005';
        XS090006: Label 'S-09-0006';
        XS070001: Label 'S-07-0001';
        XS070002: Label 'S-07-0002';
        XS070003: Label 'S-07-0003';
        XS070004: Label 'S-07-0004';
        XPCS: Label 'PCS';
        XBOX: Label 'BOX';

    local procedure InsertZone(LocationCode: Code[10]; "Code": Code[10]; Description: Text[30]; BinType: Code[10]; WhseClass: Code[10]; SpecialEquipmt: Code[10]; ZoneRanking: Integer; CrossDockBin: Boolean)
    var
        Zone: Record Zone;
    begin
        Zone.Init();
        Zone.Validate("Location Code", LocationCode);
        Zone.Validate(Code, Code);
        Zone.Validate(Description, Description);
        Zone."Bin Type Code" := BinType;
        Zone.Validate("Warehouse Class Code", WhseClass);
        Zone.Validate("Special Equipment Code", SpecialEquipmt);
        Zone.Validate("Zone Ranking", ZoneRanking);
        Zone.Validate("Cross-Dock Bin Zone", CrossDockBin);
        Zone.Insert();
    end;

    local procedure InsertBin(LocationCode: Code[10]; ZoneCode: Code[10]; BinNo: Code[10]; BinType: Code[10]; WhseClass: Code[10]; Blocked: Option " ",Inbound,Outbound,All; SpecialEquipmt: Code[10]; BinRanking: Integer; MaxCubage: Decimal; MaxWeight: Decimal; CrossDockBin: Boolean; DedicatedBin: Boolean)
    var
        Bin: Record Bin;
    begin
        Bin.Init();
        Bin.Validate("Location Code", LocationCode);
        Bin.Validate("Zone Code", ZoneCode);
        Bin.Validate(Code, BinNo);
        Bin.Validate("Bin Type Code", BinType);
        Bin.Validate("Warehouse Class Code", WhseClass);
        Bin."Block Movement" := Blocked;
        Bin.Validate("Special Equipment Code", SpecialEquipmt);
        Bin.Validate("Bin Ranking", BinRanking);
        Bin.Validate("Maximum Cubage", MaxCubage);
        Bin.Validate("Maximum Weight", MaxWeight);
        Bin.Validate("Cross-Dock Bin", CrossDockBin);
        Bin.Validate(Dedicated, DedicatedBin);
        Bin.Insert();
    end;

    procedure InsertBinContent(LocationCode: Code[10]; ZoneCode: Code[10]; BinNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; UOMCode: Code[10]; BinTypeCode: Code[10]; WhseClassCode: Code[10]; MinQty: Decimal; MaxQty: Decimal; BinRanking: Integer; "Fixed": Boolean; Blocked: Option; Default: Boolean)
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.Init();
        BinContent.Validate("Location Code", LocationCode);
        BinContent.Validate("Zone Code", ZoneCode);
        BinContent.Validate("Bin Code", BinNo);
        BinContent.Validate("Item No.", ItemNo);
        BinContent.Validate("Variant Code", VariantCode);
        BinContent.Validate("Unit of Measure Code", UOMCode);
        BinContent.Validate("Bin Type Code", BinTypeCode);
        BinContent.Validate("Warehouse Class Code", WhseClassCode);
        BinContent.Validate("Max. Qty.", MaxQty);
        BinContent.Validate("Min. Qty.", MinQty);
        BinContent.Validate("Bin Ranking", BinRanking);
        BinContent.Validate(Fixed, Fixed);
        BinContent.Validate("Block Movement", Blocked);
        BinContent.Validate(Default, Default);
        BinContent.Insert();
    end;
}

