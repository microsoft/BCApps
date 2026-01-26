codeunit 101205 "Create Res. Unit of Measure"
{

    trigger OnRun()
    begin
        InsertData(XTerry, XKM, 1, false); // NAVCZ
    end;

    var
        ResUnitOfMeasure: Record "Resource Unit of Measure";
        XTerry: Label 'Terry';
        XKM: Label 'KM';

    procedure InsertData(ResourceNo: Code[20]; UnitOfMeasureCode: Code[20]; QtyPerUOM: Decimal; CapacityUsage: Boolean)
    begin
        ResUnitOfMeasure."Resource No." := ResourceNo;
        ResUnitOfMeasure.Code := UnitOfMeasureCode;
        ResUnitOfMeasure."Qty. per Unit of Measure" := QtyPerUOM;
        ResUnitOfMeasure."Related to Base Unit of Meas." := CapacityUsage;
        ResUnitOfMeasure.Insert();
    end;
}

