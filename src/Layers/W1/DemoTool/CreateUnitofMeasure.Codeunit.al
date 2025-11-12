codeunit 101204 "Create Unit of Measure"
{

    trigger OnRun()
    begin
        InsertData(XHOUR, XHour2, 'HUR');
        InsertData(XDAY, XDay2, 'DAY');
        InsertData(XPCS, XPiece, 'EA');
        InsertData(XCAN, XCan2, 'CA');
        InsertData(XBOX, XBox2, 'BX');
        InsertData(XPALLET, XPallet2, 'PF');
        InsertData(XPACK, XPack2, 'PK');
        InsertData(XMILES, XMiles2, '1A');
        InsertData(KMTok, KilometerTok, 'KMT');
        InsertData(KGTok, KiloTok, 'KGM');
        InsertData(XSET, XSET2, 'SET');
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
        KilometerTok: Label 'Kilometer';
        KMTok: Label 'KM';
        KGTok: Label 'KG';
        KiloTok: Label 'Kilo';
        XSET: Label 'SET';
        XSET2: Label 'Set';

    procedure InsertData("Code": Code[10]; Description: Text[10]; InternationalStandardCode: Code[10])
    begin
        UnitOfMeasure.Init();
        UnitOfMeasure.Validate(Code, Code);
        UnitOfMeasure.Validate(Description, Description);
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

