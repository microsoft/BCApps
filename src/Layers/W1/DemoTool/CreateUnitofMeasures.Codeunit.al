codeunit 119005 "Create Unit of Measures"
{

    trigger OnRun()
    begin
        InsertUnitOfMeasure(XKG, XKilo, 'KGM');
        InsertUnitOfMeasure(XGR, XGram, 'GRM');
        InsertUnitOfMeasure(XPCS, XPieces, 'EA');
        InsertUnitOfMeasure(XL, XLiter, 'LTR');
        InsertUnitOfMeasure(XCAN, XCanlc, 'CA');
        InsertUnitOfMeasure(XBOX, XBoxlc, 'BX');

        InsertLangUnitOfMeasure(XPCS, 'DAN', 'Styk');
        InsertLangUnitOfMeasure(XBOX, 'DAN', 'Dusin');
        InsertLangUnitOfMeasure(XGR, 'DAN', 'Kilogram');
        InsertLangUnitOfMeasure(XL, 'DAN', 'Liter');
        InsertLangUnitOfMeasure(XCAN, 'DAN', 'dåser');
        InsertLangUnitOfMeasure(XBOX, 'DAN', 'kasser');
    end;

    var
        UnitOfMeasure: Record "Unit of Measure";
        LangUnitOfMeasure: Record "Unit of Measure Translation";
        XKG: Label 'KG';
        XKilo: Label 'Kilo';
        XGR: Label 'GR';
        XGram: Label 'Gram';
        XPCS: Label 'PCS';
        XPieces: Label 'Pieces';
        XL: Label 'L';
        XLiter: Label 'Liter';
        XCAN: Label 'CAN';
        XCanlc: Label 'Can';
        XBOX: Label 'BOX';
        XBoxlc: Label 'Box';

    procedure InsertUnitOfMeasure("Code": Text[10]; Description: Text[30]; StdCode: Code[10])
    begin
        UnitOfMeasure.Validate(Code, Code);
        UnitOfMeasure.Validate(Description, Description);
        UnitOfMeasure.Validate("International Standard Code", StdCode);

        if not UnitOfMeasure.Insert() then
            exit;
    end;

    procedure InsertLangUnitOfMeasure(UnitOfMeasureCode: Text[10]; LanguageCode: Code[10]; Description: Text[30])
    begin
        LangUnitOfMeasure.Validate(Code, UnitOfMeasureCode);
        LangUnitOfMeasure.Validate("Language Code", LanguageCode);
        LangUnitOfMeasure.Validate(Description, Description);

        if not LangUnitOfMeasure.Insert() then
            exit;
    end;
}

