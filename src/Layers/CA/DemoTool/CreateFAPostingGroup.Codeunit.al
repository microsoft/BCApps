codeunit 101803 "Create FA Posting Group"
{

    trigger OnRun()
    begin
        InsertData(XCAR, '991320', '991340', '991330', '991340', '998840', '998840', '998530', '998830', '991320');
        InsertData(XMACHINERY, '991220', '991240', '991230', '991240', '998840', '998840', '998640', '998820', '991220');
        InsertData(XTELEPHONE, '991220', '991240', '991230', '991240', '998840', '998840', '998640', '998820', '991220');
    end;

    var
        "FA Posting Group": Record "FA Posting Group";
        CA: Codeunit "Make Adjustments";
        XCAR: Label 'CAR';
        XMACHINERY: Label 'MACHINERY';
        XTELEPHONE: Label 'TELEPHONE';
        XVEHICLES: Label 'VEHICLES';
        XOfficeEquipment: Label 'EQUIPMENT';
        XBuilding: Label 'BUILDING';


    procedure InsertData(Code: Code[10]; AcquisitionCostAccount: Code[20]; AccumDepreciationAccount: Code[20]; AcqCostAccOnDisposal: Code[20]; AccumDeprAccOnDisposal: Code[20]; GainsAccOnDisposal: Code[20]; LossesAccOnDisposal: Code[20]; MaintenanceExpenseAccount: Code[20]; DepreciationExpenseAcc: Code[20]; AcquisitionCostBalAcc: Code[20])
    begin
        "FA Posting Group".Init();
        "FA Posting Group".Validate(Code, Code);
        "FA Posting Group".Validate("Acquisition Cost Account", CA.Convert(AcquisitionCostAccount));
        "FA Posting Group".Validate("Accum. Depreciation Account", CA.Convert(AccumDepreciationAccount));
        "FA Posting Group".Validate("Acq. Cost Acc. on Disposal", CA.Convert(AcqCostAccOnDisposal));
        "FA Posting Group".Validate("Accum. Depr. Acc. on Disposal", CA.Convert(AccumDeprAccOnDisposal));
        "FA Posting Group".Validate("Gains Acc. on Disposal", CA.Convert(GainsAccOnDisposal));
        "FA Posting Group".Validate("Losses Acc. on Disposal", CA.Convert(LossesAccOnDisposal));
        "FA Posting Group".Validate("Maintenance Expense Account", CA.Convert(MaintenanceExpenseAccount));
        "FA Posting Group".Validate("Depreciation Expense Acc.", CA.Convert(DepreciationExpenseAcc));
        "FA Posting Group".Validate("Acquisition Cost Bal. Acc.", CA.Convert(AcquisitionCostBalAcc));
        "FA Posting Group".Insert();
    end;

    procedure InsertDataKey("Code": Code[10])
    begin
        "FA Posting Group".Init();
        "FA Posting Group".Validate(Code, Code);
        "FA Posting Group".Insert();
    end;

    procedure CreateTrialData()
    var
        GetGLAccNo: Codeunit "Get G/L Account No. and Name";
    begin
        InsertData(XOfficeEquipment, GetGLAccNo.OperatEquipment(), GetGLAccNo.AccumDeprOperEquip(), GetGLAccNo.OperatEquipment(), GetGLAccNo.AccumDeprOperEquip(), GetGLAccNo.GainsandLosse(), GetGLAccNo.GainsandLosse(), GetGLAccNo.RepairAndMaintenance(), GetGLAccNo.DepreciationEquipment(), GetGLAccNo.OperatEquipment());
        InsertData(XBuilding, GetGLAccNo.LandandBuilding(), GetGLAccNo.AccumDepreciationBuildings(), GetGLAccNo.LandandBuilding(), GetGLAccNo.AccumDepreciationBuildings(), GetGLAccNo.GainsandLosse(), GetGLAccNo.GainsandLosse(), GetGLAccNo.RepairAndMaintenance(), GetGLAccNo.DepreciationBuildings(), GetGLAccNo.LandandBuilding());
        InsertData(XVEHICLES, GetGLAccNo.Vehicle(), GetGLAccNo.AccumDepreciationVehicles(), GetGLAccNo.Vehicle(), GetGLAccNo.AccumDepreciationVehicles(), GetGLAccNo.GainsandLosse(), GetGLAccNo.GainsandLosse(), GetGLAccNo.RepairsAndMaintenance(), GetGLAccNo.DepreciationVehicles(), GetGLAccNo.Vehicle());
    end;
}

