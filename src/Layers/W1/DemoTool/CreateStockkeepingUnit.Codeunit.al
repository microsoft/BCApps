codeunit 118021 "Create Stockkeeping Unit"
{

    trigger OnRun()
    begin
        StockkeepingUnit.DeleteAll();

        InsertData(XBLUE, '70001', '', false, '', 1, true, 0, '', '', '', 0, 0);
        InsertData(XBLUE, '70002', '', false, '', 1, true, 0, '', '', '', 0, 0);
        InsertData(XBLUE, '70003', '', false, '', 0, false, 0, '', '', '', 0, 0);

        InsertData(XYELLOW, '70001', '', true, XBLUE, 3, true, 0, '', '', '', 0, 0);
        InsertData(XYELLOW, '70002', '', true, XBLUE, 3, true, 0, '', '', '', 0, 0);
        InsertData(XYELLOW, '70003', '', true, XBLUE, 0, false, 0, '', '', '', 0, 0);
        InsertData(XYELLOW, '1928-S', '', false, '', 0, false, 0, '', '', '', 0, 0);
        InsertData(XYELLOW, '1972-S', '', false, '', 0, false, 0, '', '', '', 0, 0);

        InsertData(XWHITE, 'LS-75', 'LS-75-B', false, '', 1, true, 0, XStd, XPCS, '30000', 12, 40);
        InsertData(XWHITE, 'LS-120', '', false, '', 1, true, 0, XStd, XPCS, '40000', 10, 36);
        InsertData(XWHITE, 'LS-150', '', false, '', 1, true, 0, XStd, XPCS, '50000', 6, 32);
        InsertData(XWHITE, 'LS-10PC', 'LS-10PC-B', false, '', 1, true, 0, XStd, XPCS, '40000', 30, 100);
        InsertData(XWHITE, 'LS-Man-10', '', false, '', 1, true, 0, XVar, XPCS, '30000', 200, 1000);
        InsertData(XWHITE, 'LS-2', '', true, XGREEN, 3, true, 0, XVar, XBOX, '', 0, 0);
        InsertData(XWHITE, 'LS-S15', '', true, XBLUE, 3, true, 0, XVar, XPCS, '', 0, 0);

        InsertData(XSilver, 'LS-75', 'LS-75-B', false, '', 1, true, 0, XStd, XPCS, '30000', 12, 40);
        InsertData(XSilver, 'LS-120', '', false, '', 1, true, 0, XStd, XPCS, '40000', 10, 36);
        InsertData(XSilver, 'LS-150', '', false, '', 1, true, 0, XStd, XPCS, '50000', 6, 32);
        InsertData(XSilver, 'LS-10PC', 'LS-10PC-B', false, '', 1, true, 0, XStd, XPCS, '40000', 30, 100);
        InsertData(XSilver, 'LS-Man-10', '', false, '', 1, true, 0, XVar, XPCS, '30000', 200, 1000);
        InsertData(XSilver, 'LS-2', '', true, XGREEN, 3, true, 0, XVar, XBOX, '', 0, 0);
        InsertData(XSilver, 'LS-S15', '', true, XBLUE, 3, true, 0, XVar, XPCS, '', 0, 0);
    end;

    var
        StockkeepingUnit: Record "Stockkeeping Unit";
        XBLUE: Label 'BLUE';
        XYELLOW: Label 'YELLOW';
        XWHITE: Label 'WHITE';
        XStd: Label 'Std';
        XPCS: Label 'PCS';
        XVar: Label 'Var';
        XBOX: Label 'BOX';
        XGREEN: Label 'GREEN';
        XSilver: Label 'Silver';

    procedure InsertData(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; TransferReplenishSystem: Boolean; TransferFromCode: Code[10]; ReorderingPolicy: Option " ","Fixed Reorder Qty.","Maximum Qty.","Order","Lot-for-Lot"; IncludeInventory: Boolean; ManufacturingPolicy: Option "Make-to-Stock","Make-to-Order"; PutAwayTemp: Code[10]; PutAwayUOM: Code[10]; VendorNo: Code[20]; ReorderPoint: Integer; ReorderQty: Integer)
    begin
        StockkeepingUnit.Init();
        StockkeepingUnit.Validate("Location Code", LocationCode);
        StockkeepingUnit.Validate("Item No.", ItemNo);
        StockkeepingUnit.Validate("Variant Code", VariantCode);
        StockkeepingUnit.Validate("Include Inventory", IncludeInventory);
        StockkeepingUnit.Validate("Manufacturing Policy", ManufacturingPolicy);
        if TransferReplenishSystem then begin
            StockkeepingUnit."Replenishment System" := StockkeepingUnit."Replenishment System"::Transfer;
            StockkeepingUnit."Transfer-from Code" := TransferFromCode;
        end;
        StockkeepingUnit.Validate("Put-away Template Code", PutAwayTemp);
        StockkeepingUnit.Validate("Put-away Unit of Measure Code", PutAwayUOM);
        StockkeepingUnit.Validate("Vendor No.", VendorNo);
        StockkeepingUnit.Validate("Reorder Point", ReorderPoint);
        StockkeepingUnit.Validate("Reorder Quantity", ReorderQty);
        StockkeepingUnit.Validate("Reordering Policy", ReorderingPolicy);
        StockkeepingUnit.Insert();
    end;
}

