codeunit 118839 "Create Dist. Item UOM"
{

    trigger OnRun()
    begin
        InsertData('LS-75', XPCS, 1, 2, 2, 4, 16);
        InsertData('LS-75', XPALLET, 16, 8, 4, 8, 256);
        InsertData('LS-120', XPCS, 1, 3, 3, 6, 66);
        InsertData('LS-120', XPALLET, 12, 9, 6, 12, 780);
        InsertData('LS-150', XPCS, 1, 3, 5, 6, 99);
        InsertData('LS-150', XPALLET, 6, 6, 5, 12, 400);
        InsertData('LS-10PC', XBOX, 1, 2, 2.5, 1, 4);
        InsertData('LS-10PC', XPCS, 1, 2, 2.5, 1, 4);
        InsertData('LS-Man-10', XPCS, 1, 1, 1, 1, 1.2);
        InsertData('LS-2', XBOX, 1, 1, 1, 1.1, 0.9);
        InsertData('LS-2', XPCS, 1, 1, 1, 1.1, 0.9);
        InsertData('LS-S15', XPCS, 1, 2, 3, 3, 26);

        InsertData('LS-100', XPCS, 1, 1, 1, 1.1, 0.9);
        InsertData('LSU-15', XPCS, 1, 1, 1, 1.1, 0.9);
        InsertData('LSU-8', XPCS, 1, 1, 1, 1.1, 0.9);
        InsertData('LSU-4', XPCS, 1, 1, 1, 1.1, 0.9);
        InsertData('FF-100', XPCS, 1, 1, 1, 1.1, 0.9);
        InsertData('C-100', XPCS, 1, 1, 1, 1.1, 0.9);
        InsertData('HS-100', XPCS, 1, 1, 1, 1.1, 0.9);
        InsertData('SPK-100', XPCS, 1, 1, 1, 1.1, 0.9);

        InsertData('LS-81', XPCS, 1, 2, 2, 4, 16);
        InsertData('LS-81', XPALLET, 12, 6, 3, 3, 260);

        CreateDistItem.ModifyData('LS-75', XPCS, XPALLET, XPCS, XPALLET);
        CreateDistItem.ModifyData('LS-120', XPCS, XPCS, XPCS, XPCS);
        CreateDistItem.ModifyData('LS-150', XPCS, XPCS, XPCS, XPCS);
        CreateDistItem.ModifyData('LS-10PC', XBOX, XBOX, XBOX, XBOX);
        CreateDistItem.ModifyData('LS-Man-10', XPCS, XPCS, XPCS, XPCS);
        CreateDistItem.ModifyData('LS-2', XBOX, XBOX, XBOX, XBOX);
        CreateDistItem.ModifyData('LS-S15', XPCS, XPCS, XPCS, XPCS);

        CreateDistItem.ModifyData('LS-100', XPCS, XPCS, XPCS, XPCS);
        CreateDistItem.ModifyData('LSU-15', XPCS, XPCS, XPCS, XPCS);
        CreateDistItem.ModifyData('LSU-8', XPCS, XPCS, XPCS, XPCS);
        CreateDistItem.ModifyData('LSU-4', XPCS, XPCS, XPCS, XPCS);
        CreateDistItem.ModifyData('FF-100', XPCS, XPCS, XPCS, XPCS);
        CreateDistItem.ModifyData('C-100', XPCS, XPCS, XPCS, XPCS);
        CreateDistItem.ModifyData('HS-100', XPCS, XPCS, XPCS, XPCS);
        CreateDistItem.ModifyData('SPK-100', XPCS, XPCS, XPCS, XPCS);

        CreateDistItem.ModifyData('LS-81', XPCS, XPALLET, XPCS, XPALLET);
    end;

    var
        CreateDistItem: Codeunit "Create Dist. Item";
        XPCS: Label 'PCS';
        XPALLET: Label 'PALLET';
        XBOX: Label 'BOX';

    procedure InsertData(ItemNo: Code[20]; UnitOfMeasureCode: Text[10]; QtyPerStockedQty: Decimal; Length: Decimal; Width: Decimal; Height: Decimal; Weight: Decimal)
    var
        ItemUnitofMeasure: Record "Item Unit of Measure";
    begin
        ItemUnitofMeasure.Init();
        ItemUnitofMeasure."Item No." := ItemNo;
        ItemUnitofMeasure.Code := UnitOfMeasureCode;
        ItemUnitofMeasure."Qty. per Unit of Measure" := QtyPerStockedQty;
        ItemUnitofMeasure.Length := Length;
        ItemUnitofMeasure.Width := Width;
        ItemUnitofMeasure.Validate(Height, Height);
        ItemUnitofMeasure.Weight := Weight;
        ItemUnitofMeasure.Insert();
    end;
}

