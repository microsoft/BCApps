codeunit 119086 "Create Cost Allocation Source"
{

    trigger OnRun()
    var
        DemoDataSetup: Record "Demo Data Setup";
    begin
        DemoDataSetup.Get();
        InsertData(XADMCT, 1, 0D, 0D, '', XADM, '', '9901', '');
        InsertData(XPERSCT, 1, 0D, 0D, '', XPERS, '', '9901', XNumberofEmp);
        InsertData(XBUILDING00, 1, 0D, DMY2Date(31, 12, DemoDataSetup."Starting Year"), '', XBUILDING, '', '9901', XFrPer);
        InsertData(XBUILDING01, 1, DMY2Date(1, 1, DemoDataSetup."Starting Year"), 0D, '', XBUILDING, '', '9901', XFrPer);   // SR
        InsertData(XGLCT, 1, 0D, 0D, '', XGL, '', '9901', '');
        InsertData(XWORKSHOPCT, 2, 0D, 0D, '', XWORKSHOP, '', '9901', XPerRepStd80);
        InsertData(XPRODCT, 2, 0D, 0D, '', XPROD, '', '9901', XEverythingOnMaterials);
        InsertData(XVEHICLE00, 3, DMY2Date(31, 12, DemoDataSetup."Starting Year"),
          DMY2Date(31, 12, DemoDataSetup."Starting Year"), '', XVEHICLE, '', '9901', XAmountsperKM);
        InsertData(XVEHICLE01, 3, DMY2Date(30, 6, DemoDataSetup."Starting Year"), 0D, '', XVEHICLE, '',
          '9901', XAmountsPerKmHalfYear);     // SR (Year 01 Before)
        InsertData(XPRODCT, 10, 0D, 0D, '', XPROD, '', '9903', '');
        InsertData(XMATERIALCT, 10, 0D, 0D, '', XMATERIAL, '', '9903', XGenMaterialGK);
        InsertData(XSALESCT, 10, 0D, 0D, '', XSALES, '', '9903', '');
        InsertData(XADVERTCT, 10, 0D, 0D, '', XADVERT, '', '9903', '');
    end;

    var
        XADM: Label 'ADM';
        XPERS: Label 'PERS', Comment = 'PERS stands for Person and it is a name of Cost Center.';
        XBUILDING00: Label 'BUILDING00', Comment = 'Building00 is an ID of Cost Allocation Target.';
        XFrPer: Label 'Fr. per m2', Comment = 'It refers to unit. Fr. means Fix Rate and m2 means meter square';
        XBUILDING01: Label 'BUILDING01', Comment = 'Building01 is an ID of Cost Allocation Target.';
        XGL: Label 'GL';
        XWORKSHOP: Label 'WORKSHOP', Comment = 'Workshop is a name of Cost Center.';
        XPROD: Label 'PROD', Comment = 'PROD stands for Production and it is a name of Cost Center.';
        XVEHICLE00: Label 'VEHICLE00', Comment = 'Vehicle00 is an ID of Cost Allocation Target.';
        XVEHICLE01: Label 'VEHICLE01', Comment = 'Vehicle01 is an ID of Cost Allocation Target.';
        XVEHICLE: Label 'VEHICLE', Comment = 'Vehicle is a name of Cost Center.';
        XPerRepStd80: Label 'Per Rep. Std. 80.-';
        XEverythingOnMaterials: Label 'Everything on Materials';
        XAmountsperKM: Label 'Amounts per KM';
        XNumberofEmp: Label 'By number of employees';
        XBUILDING: Label 'BUILDING', Comment = 'Building is an ID of Cost Allocation Source.';
        XAmountsPerKmHalfYear: Label 'Amounts per kilometer/Half year';
        XMATERIAL: Label 'MATERIAL', Comment = 'Material is a name of Cost Center.';
        XGenMaterialGK: Label 'Gen. Material GK';
        XSALES: Label 'SALES', Comment = 'Sales is an ID of Cost Allocation Source.';
        XADVERT: Label 'ADVERT', Comment = 'ADVERT stands for Avertisement and it is a name of cost center.';
        XADMCT: Label 'ADM';
        XPERSCT: Label 'PERS', Comment = 'PERS stands for Person and it is a name of cost center.';
        XSALESCT: Label 'SALES', Comment = 'Sales is an ID of Cost allocation Source.';
        XADVERTCT: Label 'ADVERT', Comment = 'ADVERT stands for Advertisement and it is name of cost center.';
        XGLCT: Label 'GL';
        XPRODCT: Label 'PROD', Comment = 'PROD stands for Production and it is a name of cost center.';
        XMATERIALCT: Label 'MATERIAL', Comment = 'Material is an ID of Cost Allocation Source.';
        XWORKSHOPCT: Label 'WORKSHOP', Comment = 'Workshop is an ID of Cost Allocation Source.';

    procedure InsertData(CostAllocationSourceID: Code[10]; CostAllocationSourceLevel: Integer; ValidFrom: Date; ValidTo: Date; CostTypeRange: Code[30]; CostCenterCode: Code[20]; CostObjectCode: Code[20]; DebitToCostType: Code[20]; CostAllocationSourceComment: Text[50])
    var
        CostAllocationSource: Record "Cost Allocation Source";
    begin
        CostAllocationSource.Init();
        CostAllocationSource.ID := CostAllocationSourceID;
        CostAllocationSource.Level := CostAllocationSourceLevel;
        CostAllocationSource."Valid From" := ValidFrom;
        CostAllocationSource."Valid To" := ValidTo;
        CostAllocationSource.Validate("Cost Type Range", CostTypeRange);
        CostAllocationSource.Validate("Cost Center Code", CostCenterCode);
        CostAllocationSource.Validate("Cost Object Code", CostObjectCode);
        CostAllocationSource.Validate("Credit to Cost Type", DebitToCostType);
        CostAllocationSource.Comment := CostAllocationSourceComment;
        if not CostAllocationSource.Insert() then
            CostAllocationSource.Modify();
    end;
}

