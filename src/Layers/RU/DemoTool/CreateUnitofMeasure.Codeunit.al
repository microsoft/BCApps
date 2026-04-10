codeunit 101204 "Create Unit of Measure"
{

    trigger OnRun()
    begin
        InsertData(XCAN, XCan2, '881', 'CA');
        InsertData(XBOTTLE, XBottle2, '868', 'BO');
        InsertData(XGR, XGram2, '163', 'GRM');
        InsertData(XYEAR, XYear2, '366', 'ANN');
        InsertData(XDAY, XDay2, '359', 'DAY');
        InsertData(XUNIT, XUnit2, '642', 'EA');
        InsertData(XQTR, XQuarter2, '364', 'QAN');
        InsertData(XKG, XKilogram2, '166', 'KGM');
        InsertData(XMILES, XMiles2, '008', 'SMI');
        InsertData(XKIT, XKit2, '839', 'KT');
        InsertData(XL, XLitre2, '112', 'LTR');
        InsertData(XMON, XMonth2, '362', 'MON');
        InsertData(XM, XMeter2, '006', 'MTR');
        InsertData(XM2, XSqMeter2, '055', 'MTK');
        InsertData(XMIN, XMinute2, '355', 'MIN');
        InsertData(XSET, XSet2, '704', 'SET');
        InsertData(XPALLET, XPallet2, '', 'PF');
        InsertData(XPAIR, XPair2, '715', 'PR');
        InsertData(XPACK, XPack2, '778', 'PK');
        InsertData(XROLL, XRoll2, '736', 'RO');
        InsertData(XTON, XTonne2, '168', 'L64');
        InsertData(XHOUR, XHour2, '356', 'HUR');
        InsertData(XPERSON, XPerson2, '792', 'IE');
        InsertData(XPCS, XPiece, '796', 'EA');
        InsertData(XBOX, XBox2, '812', 'BX');
    end;

    var
        UnitOfMeasure: Record "Unit of Measure";
        XHOUR: Label 'HOUR';
        XHour2: Label 'Hour';
        XDAY: Label 'DAY';
        XDay2: Label 'Day';
        XPCS: Label 'PCS';
        XPiece: Label 'Piece';
        XCAN: Label 'CAN';
        XCan2: Label 'Can';
        XBOX: Label 'BOX';
        XBox2: Label 'Box';
        XPALLET: Label 'PALLET';
        XPallet2: Label 'Pallet';
        XPACK: Label 'PACK';
        XPack2: Label 'Pack';
        XMILES: Label 'MILES';
        XMiles2: Label 'Miles';
        XBOTTLE: Label 'BOTTLE';
        XBottle2: Label 'Bottle';
        XGR: Label 'GR';
        XGram2: Label 'Gram';
        XYEAR: Label 'YEAR';
        XYear2: Label 'Year';
        XUNIT: Label 'UNIT';
        XUnit2: Label 'Unit';
        XQTR: Label 'QTR';
        XQuarter2: Label 'Quarter';
        XKG: Label 'KG';
        XKilogram2: Label 'Kilogram';
        XKIT: Label 'KIT';
        XKit2: Label 'Kit';
        XL: Label 'L';
        XLitre2: Label 'Litre';
        XMON: Label 'MON';
        XMonth2: Label 'Month';
        XM: Label 'M';
        XMeter2: Label 'Meter';
        XM2: Label 'M2';
        XSqMeter2: Label 'Sq. Meter';
        XMIN: Label 'MIN';
        XMinute2: Label 'Minute';
        XSET: Label 'SET';
        XSet2: Label 'Set';
        XPAIR: Label 'PAIR';
        XPair2: Label 'Pair';
        XROLL: Label 'ROLL';
        XRoll2: Label 'Roll';
        XTON: Label 'TON';
        XTonne2: Label 'Tonne';
        XPERSON: Label 'PERSON';
        XPerson2: Label 'Person';

    procedure InsertData("Code": Code[10]; Description: Text[10]; OKEICode: Code[10]; InternationalStandardCode: Code[10])
    begin
        UnitOfMeasure.Init();
        UnitOfMeasure.Validate(Code, Code);
        UnitOfMeasure.Validate(Description, Description);
        UnitOfMeasure.Validate("OKEI Code", OKEICode);
        UnitOfMeasure.Validate("International Standard Code", InternationalStandardCode);
        if UnitOfMeasure.Insert() then;
    end;

    procedure GetBoxUnitOfMeasureCode(): Code[10]
    begin
        UnitOfMeasure.Get(XBOX);
        exit(UnitOfMeasure.Code);
    end;

    procedure GetPcsUnitOfMeasureCode(): Code[10]
    begin
        UnitOfMeasure.Get(XPCS);
        exit(UnitOfMeasure.Code);
    end;

    procedure HourCode(): Code[10]
    begin
        UnitOfMeasure.Get(XHOUR);
        exit(UnitOfMeasure.Code);
    end;
}

