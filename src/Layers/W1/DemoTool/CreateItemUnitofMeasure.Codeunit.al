codeunit 101701 "Create Item Unit of Measure"
{

    trigger OnRun()
    begin
        InsertData('80100', XBOX, 1);
        InsertData('80100', XPACK, 0.2);
        InsertData('80100', XPALLET, 32);
        InsertData('1896-S', XBOX, 4);
    end;

    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        XBOX: Label 'BOX';
        XPACK: Label 'PACK';
        XPALLET: Label 'PALLET';

    procedure InsertData("Item No.": Code[20]; "Code": Code[10]; "Qty. per Unit of Measure": Decimal)
    begin
        ItemUnitOfMeasure.Init();
        ItemUnitOfMeasure."Item No." := "Item No.";
        ItemUnitOfMeasure.Code := Code;
        ItemUnitOfMeasure."Qty. per Unit of Measure" := "Qty. per Unit of Measure";
        if "Qty. per Unit of Measure" = 1 then begin
            if ItemUnitOfMeasure.Insert() then;
        end else
            ItemUnitOfMeasure.Insert();
    end;
}

