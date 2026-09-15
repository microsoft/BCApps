codeunit 119006 "Create Item Unit of Measures"
{

    trigger OnRun()
    begin
        InsertData('1000', XPCS, 1);
        InsertData('1001', XPCS, 1);
        InsertData('1100', XPCS, 1);
        InsertData('1110', XPCS, 1);
        InsertData('1120', XPCS, 1);
        InsertData('1150', XPCS, 1);
        InsertData('1151', XPCS, 1);
        InsertData('1155', XPCS, 1);
        InsertData('1160', XPCS, 1);
        InsertData('1170', XPCS, 1);
        InsertData('1200', XPCS, 1);
        InsertData('1250', XPCS, 1);
        InsertData('1251', XPCS, 1);
        InsertData('1255', XPCS, 1);
        InsertData('1300', XPCS, 1);
        InsertData('1310', XPCS, 1);
        InsertData('1320', XPCS, 1);
        InsertData('1330', XPCS, 1);
        InsertData('1400', XPCS, 1);
        InsertData('1450', XPCS, 1);
        InsertData('1500', XPCS, 1);
        InsertData('1600', XPCS, 1);
        InsertData('1700', XPCS, 1);
        InsertData('1710', XPCS, 1);
        InsertData('1720', XPCS, 1);
        InsertData('1800', XPCS, 1);
        InsertData('1850', XPCS, 1);
        InsertData('1900', XPCS, 1);
    end;

    var
        XPCS: Label 'PCS';

    procedure InsertData(ItemNo: Code[20]; UnitOfMeasureCode: Text[10]; QtyPerStockedQty: Decimal)
    var
        ItemUnitofMeasure: Record "Item Unit of Measure";
    begin
        ItemUnitofMeasure."Item No." := ItemNo;
        ItemUnitofMeasure.Code := UnitOfMeasureCode;
        ItemUnitofMeasure."Qty. per Unit of Measure" := QtyPerStockedQty;
        ItemUnitofMeasure.Insert();
    end;
}

