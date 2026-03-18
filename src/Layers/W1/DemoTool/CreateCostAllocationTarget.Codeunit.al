codeunit 119087 "Create Cost Allocation Target"
{

    trigger OnRun()
    var
        DemoDataSetup: Record "Demo Data Setup";
        CostAccountAllocation: Codeunit "Cost Account Allocation";
        OrgWorkDate: Date;
    begin
        InsertDataStatic(XADM, '9901', XVEHICLE, '', 10, 0, 0);
        InsertDataStatic(XADM, '9901', XWORKSHOP, '', 8, 0, 0);
        InsertDataStatic(XADM, '9901', XPROD, '', 70, 0, 0);
        InsertDataStatic(XADM, '9901', XSALES, '', 25, 0, 0);
        InsertDataStatic(XADM, '9901', XADVERT, '', 10, 0, 0);
        InsertDataStatic(XPERS, '9901', XVEHICLE, '', 3, 0, 0);
        InsertDataStatic(XPERS, '9901', XWORKSHOP, '', 2, 0, 0);
        InsertDataStatic(XPERS, '9901', XPROD, '', 35, 0, 0);
        InsertDataStatic(XPERS, '9901', XSALES, '', 8, 0, 0);
        InsertDataStatic(XPERS, '9901', XADVERT, '', 2, 0, 0);
        InsertDataStatic(XBUILDING00, '9901', XVEHICLE, '', 220, 0, 120);
        InsertDataStatic(XBUILDING00, '9901', XWORKSHOP, '', 80, 0, 120);
        InsertDataStatic(XBUILDING00, '9901', XPROD, '', 1250, 0, 120);
        InsertDataStatic(XBUILDING00, '9901', XSALES, '', 270, 0, 120);
        InsertDataStatic(XBUILDING00, '9901', XADVERT, '', 30, 0, 120);
        InsertDataStatic(XBUILDING00, '9901', XINVENTORY, '', 420, 0, 60);
        InsertDataStatic(XBUILDING01, '9901', XVEHICLE, '', 220, 0, 130);
        InsertDataStatic(XBUILDING01, '9901', XWORKSHOP, '', 80, 0, 130);
        InsertDataStatic(XBUILDING01, '9901', XPROD, '', 1250, 0, 130);
        InsertDataStatic(XBUILDING01, '9901', XSALES, '', 270, 0, 130);
        InsertDataStatic(XBUILDING01, '9901', XADVERT, '', 30, 0, 130);
        InsertDataStatic(XBUILDING01, '9901', XINVENTORY, '', 420, 0, 65);
        InsertDataStatic(XGL, '9901', XPROD, '', 2, 0, 0);
        InsertDataStatic(XGL, '9901', XSALES, '', 1, 0, 0);
        InsertDataStatic(XWORKSHOPCA, '9901', XVEHICLE, '', 202, 0, 80);
        InsertDataStatic(XWORKSHOPCA, '9901', XPROD, '', 1000, 0, 80);
        InsertDataStatic(XVEHICLE00, '9901', XPROD, '', 120000, 0, 1.2);
        InsertDataStatic(XVEHICLE00, '9901', XSALES, '', 80000, 0, 0.8);
        InsertDataStatic(XVEHICLE00, '9901', XADVERT, '', 15000, 0, 0.8);
        InsertDataStatic(XVEHICLE01, '9901', XPROD, '', 60000, 0, 1.2);
        InsertDataStatic(XVEHICLE01, '9901', XSALES, '', 10000, 0, 0.8);
        InsertDataStatic(XVEHICLE01, '9901', XADVERT, '', 5000, 0, 0.8);
        InsertDataStatic(XPRODCA, '9903', '', XFURNITURE, 4800000, 0, 0);
        InsertDataStatic(XPRODCA, '9903', '', XCHAIRS, 800000, 0, 0);
        InsertDataStatic(XPRODCA, '9903', '', XACCESSO, 2200000, 0, 0);
        InsertDataStatic(XMATERIALCA, '9903', '', XFURNITURE, 80, 0, 0);
        InsertDataStatic(XMATERIALCA, '9903', '', XCHAIRS, 20, 0, 0);
        InsertDataDynamic(XSALESCA, '9903', '', XFITTINGS, 0, 0, 13, '70060|70200|70201', '', '', 7, '');
        InsertDataDynamic(XSALESCA, '9903', '', XPAINT, 0, 0, 13, '70100..70104', '', '', 7, '');
        InsertDataDynamic(XSALESCA, '9903', '', XFURNITURE, 0, 0, 13, '1896S..', '', '', 7, '');
        InsertDataDynamic(XSALESCA, '9903', '', XACCESSO, 0, 0, 13, '70000..70041', '', '', 7, '');
        InsertDataStatic(XADVERTCA, '9903', '', XCONSULTING, 2, 0, 0);
        InsertDataStatic(XADVERTCA, '9903', '', XFITTINGS, 2, 0, 0);
        InsertDataStatic(XADVERTCA, '9903', '', XPAINT, 2, 0, 0);
        InsertDataStatic(XADVERTCA, '9903', '', XFURNITURE, 80, 0, 0);
        InsertDataStatic(XADVERTCA, '9903', '', XCHAIRS, 20, 0, 0);
        InsertDataStatic(XADVERTCA, '9903', '', XACCESSO, 5, 0, 0);

        DemoDataSetup.Get();
        OrgWorkDate := WorkDate();
        WorkDate(DMY2Date(31, 12, DemoDataSetup."Starting Year" + 1));
        CostAccountAllocation.CalcAllocationKeys();
        WorkDate(OrgWorkDate);
    end;

    var
        XADM: Label 'ADM';
        XPERS: Label 'PERS', Comment = 'PERS stands for Person and it is a name of cost center.';
        XBUILDING00: Label 'BUILDING00', Comment = 'Building00 is an ID of Cost Allocation.';
        XBUILDING01: Label 'BUILDING01', Comment = 'Building01 is an ID of the Cost Allocation Target.';
        XGL: Label 'GL';
        XWORKSHOP: Label 'WORKSHOP', Comment = 'Workshop is a name of Cost Center';
        XPROD: Label 'PROD', Comment = 'PROD stands for Production and it is a name of cost center.';
        XVEHICLE00: Label 'VEHICLE00', Comment = 'Vehicle is an ID of Cost Allocation Target.';
        XVEHICLE01: Label 'VEHICLE01', Comment = 'Vehicle is an ID of Cost Allocation Target.';
        XVEHICLE: Label 'VEHICLE', Comment = 'Vehicle is a name of Cost Center.';
        XSALES: Label 'SALES', Comment = 'Sales is a name of Cost Center.';
        XADVERT: Label 'ADVERT', Comment = 'ADVERT stands for Advertisement and it is a name of Cost Center.';
        XCHAIRS: Label 'CHAIRS', Comment = 'Chairs is a name of Cost Object.';
        XFURNITURE: Label 'FURNITURE', Comment = 'Furniture is a name Cost Object.';
        XPAINT: Label 'PAINT';
        XACCESSO: Label 'ACCESSO', Comment = 'ACCESSO stands for Accesories and it is a name of cost center.';
        XFITTINGS: Label 'FITTINGS', Comment = 'Fittings is a name of Cost Object.';
        XINVENTORY: Label 'INVENTORY', Comment = 'Inventory is a name of Cost Object.';
        XCONSULTING: Label 'CONSULTING', Comment = 'Consulting is a name of Cost Object.';
        XWORKSHOPCA: Label 'WORKSHOP', Comment = 'Workshop is an ID of Cost Allocation Target.';
        XADVERTCA: Label 'ADVERT', Comment = 'ADVERT stands for Advertisement and it is a name of cost center.';
        XSALESCA: Label 'SALES', Comment = 'Sales is a ID of Cost Allocation Target.';
        XPRODCA: Label 'PROD', Comment = 'PROD stands for Production and it is name of cost center.';
        XMATERIALCA: Label 'MATERIAL', Comment = 'Material is an ID of Cost Allocation Target.';

    procedure InsertDataStatic(CostAllocationTargetID: Code[10]; TargetCostType: Code[20]; TargetCostCenter: Code[20]; TargetCostObject: Code[20]; CostAllocationTargetShare: Decimal; PercentPerShare: Decimal; AmountPerShare: Decimal)
    var
        CostAllocationTarget: Record "Cost Allocation Target";
        LastLineNo: Integer;
    begin
        CostAllocationTarget.Reset();
        CostAllocationTarget.SetRange(ID, CostAllocationTargetID);
        if CostAllocationTarget.FindLast() then
            LastLineNo := CostAllocationTarget."Line No."
        else
            LastLineNo := 0;
        CostAllocationTarget.Init();
        CostAllocationTarget.ID := CostAllocationTargetID;
        CostAllocationTarget."Line No." := LastLineNo + 10000;
        CostAllocationTarget.Validate("Target Cost Type", TargetCostType);
        CostAllocationTarget.Validate("Target Cost Center", TargetCostCenter);
        CostAllocationTarget.Validate("Target Cost Object", TargetCostObject);

        if not CostAllocationTarget.Insert() then
            CostAllocationTarget.Modify();

        CostAllocationTarget.Validate(Share, CostAllocationTargetShare);
        CostAllocationTarget.Base := CostAllocationTarget.Base::Static;
        if PercentPerShare <> 0 then begin
            CostAllocationTarget."Allocation Target Type" := CostAllocationTarget."Allocation Target Type"::"Percent per Share";
            CostAllocationTarget."Percent per Share" := PercentPerShare;
        end;

        if AmountPerShare <> 0 then begin
            CostAllocationTarget."Allocation Target Type" := CostAllocationTarget."Allocation Target Type"::"Amount per Share";
            CostAllocationTarget."Amount per Share" := AmountPerShare;
        end;

        CostAllocationTarget."Share Updated on" := Today;
        CostAllocationTarget."Last Date Modified" := Today;
        CostAllocationTarget."User ID" := UserId();
        if not CostAllocationTarget.Insert() then
            CostAllocationTarget.Modify();
    end;

    procedure InsertDataDynamic(CostAllocationTargetID: Code[10]; TargetCostType: Code[20]; TargetCostCenter: Code[20]; TargetCostObject: Code[20]; PercentperShare: Decimal; AmountperShare: Decimal; CostAllocationTargetBase: Integer; NoFilter: Text[30]; CostCenterFilter: Text[30]; CostObjectFilter: Text[30]; DateFilterCode: Integer; GroupFilter: Text[30])
    var
        CostAllocationTarget: Record "Cost Allocation Target";
        LastLineNo: Integer;
    begin
        CostAllocationTarget.Reset();
        CostAllocationTarget.SetRange(ID, CostAllocationTargetID);
        if CostAllocationTarget.FindLast() then
            LastLineNo := CostAllocationTarget."Line No."
        else
            LastLineNo := 0;
        CostAllocationTarget.Init();
        CostAllocationTarget.ID := CostAllocationTargetID;
        CostAllocationTarget."Line No." := LastLineNo + 10000;
        CostAllocationTarget.Validate("Target Cost Type", TargetCostType);
        CostAllocationTarget.Validate("Target Cost Center", TargetCostCenter);
        CostAllocationTarget.Validate("Target Cost Object", TargetCostObject);

        if PercentperShare <> 0 then begin
            CostAllocationTarget."Allocation Target Type" := CostAllocationTarget."Allocation Target Type"::"Percent per Share";
            CostAllocationTarget."Percent per Share" := PercentperShare;
        end;

        if AmountperShare <> 0 then begin
            CostAllocationTarget."Allocation Target Type" := CostAllocationTarget."Allocation Target Type"::"Amount per Share";
            CostAllocationTarget."Amount per Share" := AmountperShare;
        end;

        CostAllocationTarget.Base := "Cost Allocation target Base".FromInteger(CostAllocationTargetBase);
        CostAllocationTarget.Validate("No. Filter", NoFilter);
        CostAllocationTarget."Cost Center Filter" := CostCenterFilter;
        CostAllocationTarget."Cost Object Filter" := CostObjectFilter;
        CostAllocationTarget."Date Filter Code" := "Cost Allocation Target Period".FromInteger(DateFilterCode);
        CostAllocationTarget."Group Filter" := GroupFilter;

        CostAllocationTarget."Last Date Modified" := Today;
        CostAllocationTarget."User ID" := UserId();

        if not CostAllocationTarget.Insert() then
            CostAllocationTarget.Modify();
    end;
}

