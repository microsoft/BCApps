codeunit 119016 "Create Work Center"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData(
          '100', XAssemblydepartment, '', '1', 1.2, 0, 0, '', XMINUTES, 3, 100, 0, 0, 0.0001, 0, '1', 0, false, DemoDataSetup.ManufactCode());
        InsertData(
          '200', XPackingdepartment, '', '1', 1.5, 0, 0, '', XMINUTES, 1, 100, 0, 0, 0.0001, 0, '1', 0, false, DemoDataSetup.ManufactCode());
        InsertData(
          '300', XPaintingdepartment, '', '2', 1.7, 0, 0, '', XMINUTES, 1, 100, 0, 0, 0.0001, 0, '2', 0, false, DemoDataSetup.ManufactCode());
        InsertData(
          '400', XMachinedepartment, '', '2', 2.5, 0, 0, '', XMINUTES, 1, 100, 0, 0, 0.0001, 0, '2', 0, false, DemoDataSetup.ManufactCode());
    end;

    var
        XAssemblydepartment: Label 'Assembly department';
        XMINUTES: Label 'MINUTES';
        XPackingdepartment: Label 'Packing department';
        XPaintingdepartment: Label 'Painting department';
        XMachinedepartment: Label 'Machine department';
        DemoDataSetup: Record "Demo Data Setup";

    procedure InsertData(No: Code[20]; Name: Text[30]; AltWorkCenter: Code[20]; WorkCenterGroupCode: Code[10]; DirectUnitCost: Decimal; IndirectCostPct: Decimal; QueueTime: Decimal; QueueUnitOfMeasure: Text[10]; UnitOfMeasureCode: Text[10]; Capacity: Decimal; Efficiency: Decimal; MaxEfficiency: Decimal; MinEfficiency: Decimal; CalRoundPrecision: Decimal; SimulationType: Option Moves,Critical,"Moves when necessary"; ShopCalendarCode: Code[10]; UnitCostCalc: Option Time,Units; SpecificUnitCost: Boolean; GenProdPostGrp: Code[20])
    var
        WorkCenter: Record "Work Center";
    begin
        WorkCenter.Validate("No.", No);
        WorkCenter.Validate(Name, Name);
        WorkCenter.Validate("Alternate Work Center", AltWorkCenter);
        WorkCenter.Insert();
        WorkCenter.Validate("Work Center Group Code", WorkCenterGroupCode);
        WorkCenter.Validate("Direct Unit Cost", DirectUnitCost);
        WorkCenter.Validate("Indirect Cost %", IndirectCostPct);
        WorkCenter.Validate("Queue Time", QueueTime);
        WorkCenter.Validate("Queue Time Unit of Meas. Code", QueueUnitOfMeasure);
        WorkCenter.Validate("Unit of Measure Code", UnitOfMeasureCode);
        WorkCenter.Validate(Capacity, Capacity);
        WorkCenter.Validate(Efficiency, Efficiency);
        WorkCenter.Validate("Maximum Efficiency", MaxEfficiency);
        WorkCenter.Validate("Minimum Efficiency", MinEfficiency);
        WorkCenter.Validate("Calendar Rounding Precision", CalRoundPrecision);
        WorkCenter.Validate("Simulation Type", SimulationType);
        WorkCenter.Validate("Shop Calendar Code", ShopCalendarCode);
        WorkCenter.Validate("Unit Cost Calculation", UnitCostCalc);
        WorkCenter.Validate("Specific Unit Cost", SpecificUnitCost);
        WorkCenter.Validate("Gen. Prod. Posting Group", GenProdPostGrp);
        WorkCenter.Modify();
    end;
}

