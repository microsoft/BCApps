codeunit 119030 "Create Machine Center"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData('110', XMikeSeamans, '100', 0, '', 1, 100, 0, 0, DemoDataSetup.ManufactCode());
        InsertData('120', XBryanWalton, '100', 0, '', 1, 100, 0, 0, DemoDataSetup.ManufactCode());
        InsertData('130', XLindaMitchell, '100', 0, '', 1, 100, 0, 0, DemoDataSetup.ManufactCode());

        InsertData('210', XPackingtable1, '200', 0, '', 1, 100, 0, 0, DemoDataSetup.ManufactCode());
        InsertData('220', XPackingtable2, '200', 0, '', 1, 100, 0, 0, DemoDataSetup.ManufactCode());
        InsertData('230', XPackingMachine, '200', 0, '', 1, 100, 0, 0, DemoDataSetup.ManufactCode());

        InsertData('310', XPaintingCabin, '300', 0, '', 1, 100, 0, 0, DemoDataSetup.ManufactCode());
        InsertData('320', XPaintingRobot, '300', 0, '', 1, 100, 0, 0, DemoDataSetup.ManufactCode());
        InsertData('330', XDryingCabin, '300', 0, '', 1, 100, 0, 0, DemoDataSetup.ManufactCode());
        InsertData('340', XPaintinginspection, '300', 0, '', 1, 100, 0, 0, DemoDataSetup.ManufactCode());

        InsertData('410', XDrillingmachine, '400', 0, '', 1, 100, 0, 0, DemoDataSetup.ManufactCode());
        InsertData('420', XCNCmachine, '400', 0, '', 1, 100, 0, 0, DemoDataSetup.ManufactCode());
        InsertData('430', XMachinedeburr, '400', 0, '', 1, 100, 0, 0, DemoDataSetup.ManufactCode());
        InsertData('440', XMachineinspection, '400', 0, '', 1, 100, 0, 0, DemoDataSetup.ManufactCode());
    end;

    var
        XMikeSeamans: Label 'Mike Seamans';
        XBryanWalton: Label 'Bryan Walton';
        XLindaMitchell: Label 'Linda Mitchell';
        XPackingtable1: Label 'Packing table 1';
        XPackingtable2: Label 'Packing table 2';
        XPackingMachine: Label 'Packing Machine';
        XPaintingCabin: Label 'Painting Cabin';
        XPaintingRobot: Label 'Painting Robot';
        XDryingCabin: Label 'Drying Cabin';
        XPaintinginspection: Label 'Painting inspection';
        XDrillingmachine: Label 'Drilling machine';
        XCNCmachine: Label 'CNC machine';
        XMachinedeburr: Label 'Machine deburr';
        XMachineinspection: Label 'Machine inspection';
        DemoDataSetup: Record "Demo Data Setup";

    procedure InsertData(No: Code[20]; Name: Text[30]; WorkCenterNo: Code[10]; QueueTime: Decimal; QueueUnitOfMeasure: Text[10]; Capacity: Decimal; Efficiency: Decimal; MaxEfficiency: Decimal; MinEfficiency: Decimal; GenProdPostGrp: Code[20])
    var
        MachineCenter: Record "Machine Center";
        WorkCenter: Record "Work Center";
    begin
        MachineCenter.Validate("No.", No);
        MachineCenter.Validate(Name, Name);
        MachineCenter.Insert();
        WorkCenter.Get(WorkCenterNo);
        MachineCenter.Validate("Setup Time Unit of Meas. Code", WorkCenter."Unit of Measure Code");
        MachineCenter.Validate("Wait Time Unit of Meas. Code", WorkCenter."Unit of Measure Code");
        MachineCenter.Validate("Move Time Unit of Meas. Code", WorkCenter."Unit of Measure Code");
        MachineCenter.Validate("Work Center No.", WorkCenterNo);
        MachineCenter.Validate("Queue Time", QueueTime);
        MachineCenter.Validate("Queue Time Unit of Meas. Code", QueueUnitOfMeasure);
        MachineCenter.Validate(Capacity, Capacity);
        MachineCenter.Validate(Efficiency, Efficiency);
        MachineCenter.Validate("Maximum Efficiency", MaxEfficiency);
        MachineCenter.Validate("Minimum Efficiency", MinEfficiency);
        MachineCenter.Validate("Gen. Prod. Posting Group", GenProdPostGrp);
        MachineCenter.Modify();
    end;
}

