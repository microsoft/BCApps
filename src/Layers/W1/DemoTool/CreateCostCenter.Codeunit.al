codeunit 119082 "Create Cost Center"
{

    trigger OnRun()
    var
        CostAccountMgt: Codeunit "Cost Account Mgt";
    begin
        InsertData(XADM, XAdministration, "Cost Center Subtype"::"Aux. Cost Center", 'B', 0, '');
        InsertData(XAdminHR, XGeneralAncillaryCC, "Cost Center Subtype"::" ", 'A', 3, '');
        InsertData(XBUILDING, XBuildingsAndProperty, "Cost Center Subtype"::"Aux. Cost Center", 'B', 0, '');
        InsertData(XGL, XBusinessManagement, "Cost Center Subtype"::"Aux. Cost Center", 'B', 0, '');
        InsertData(XLABOR, XLabResearch, "Cost Center Subtype"::"Aux. Cost Center", 'E', 0, '');
        InsertData(XOpAc, XOpAncillaryCC, "Cost Center Subtype"::" ", 'D', 3, '');
        InsertData(XPERS, XPersonalAdm, "Cost Center Subtype"::"Aux. Cost Center", 'B', 0, '');
        InsertData(XTotAdmin, XTotalGenAncCS, "Cost Center Subtype"::" ", 'C', 4, '');
        InsertData(XTotalOp, XTotalOpCC, "Cost Center Subtype"::"Aux. Cost Center", 'F', 4, '');
        InsertData(XVEHICLE, XVehicleOperation, "Cost Center Subtype"::"Aux. Cost Center", 'E', 0, '');
        InsertData(XWORKSHOP, XWorkshopAndRepairs, "Cost Center Subtype"::"Aux. Cost Center", 'E', 0, '');

        InsertData(XADVERT, XAdvertisingDepartment, "Cost Center Subtype"::"Main Cost Center", 'H', 0, '');
        InsertData(XINVENTORY, LowerCase(XINVENTORY), "Cost Center Subtype"::"Main Cost Center", 'H', 0, '');
        InsertData(XMainCC, XMainCostCenters, "Cost Center Subtype"::" ", 'G', 3, '');
        InsertData(XMATERIAL, XMaterialPurch, "Cost Center Subtype"::"Main Cost Center", 'H', 0, '');
        InsertData(XPROD, XProduction, "Cost Center Subtype"::"Main Cost Center", 'H', 0, '');
        InsertData(XSALES, LowerCase(XSALES), "Cost Center Subtype"::"Main Cost Center", 'H', 0, '');
        InsertData(XTotMain, XTotalMainCC, "Cost Center Subtype"::" ", 'I', 4, '');

        InsertData(XAncillCC, XAncillaryCostCenters, "Cost Center Subtype"::" ", 'X', 1, '');
        InsertData(XACTACCR, XActualAccruals, "Cost Center Subtype"::"Service Cost Center", 'X', 0, '');

        // Total
        InsertData(XTotal, XTotalCostCenter, "Cost Center Subtype"::" ", 'Z', 2, 'AA..ZZ');
        CostAccountMgt.IndentCostCenters();
    end;

    var
        XADM: Label 'ADM';
        XAdministration: Label 'Administration';
        XAdminHR: Label 'Admin HR', Comment = 'Admin HR is name of Cost Center Code where HR means Human Resource.';
        XGeneralAncillaryCC: Label 'General Ancillary Cost Centers';
        XBUILDING: Label 'BUILDING', Comment = 'Building is a name of Cost Center.';
        XBuildingsAndProperty: Label 'Buildings and Property';
        XGL: Label 'GL';
        XBusinessManagement: Label 'Business Management';
        XLABOR: Label 'LABOR', Comment = 'Labor is a name of Cost Center.';
        XLabResearch: Label 'Lab and Research';
        XOpAc: Label 'Op. Ac', Comment = 'Op. Ac is name of Cost Center Code where ''Op.'' means Operational and ''Ac'' means Ancillary.';
        XOpAncillaryCC: Label 'Op. Ancillary Cost Centers';
        XPERS: Label 'PERS', Comment = 'PERS stands for Person and it is a name of Cost Center.';
        XPersonalAdm: Label 'Business Management';
        XTotAdmin: Label 'Tot Admin';
        XTotalGenAncCS: Label 'Total Gen. Anc. CS';
        XTotalOp: Label 'Total Op.';
        XTotalOpCC: Label 'Total Op. Anc. CC';
        XVEHICLE: Label 'VEHICLE', Comment = 'Vehicle is a name of Cost Center.';
        XVehicleOperation: Label 'Vehicle Operation';
        XWORKSHOP: Label 'WORKSHOP', Comment = 'Workshop is a name of Cost Center.';
        XWorkshopAndRepairs: Label 'Workshop and Repairs';
        XADVERT: Label 'ADVERT', Comment = 'ADVERT stands for Advertisement and it is a name of Cost Center.';
        XAdvertisingDepartment: Label 'Advertising Department';
        XINVENTORY: Label 'INVENTORY', Comment = 'Inventory is a name of Cost Center.';
        XMainCC: Label 'MainCC';
        XMainCostCenters: Label 'Main Cost Centers';
        XMATERIAL: Label 'MATERIAL', Comment = 'Material is a name of Cost Center.';
        XMaterialPurch: Label 'Material Purchasing';
        XPROD: Label 'PROD', Comment = 'PROD stands for Production and it is a name of Cost Center.';
        XProduction: Label 'Production';
        XSALES: Label 'SALES', Comment = 'Sales is a name of Cost Center.';
        XTotMain: Label 'Tot Main';
        XTotalMainCC: Label 'Total Main CC';
        XAncillCC: Label 'AncillCC';
        XAncillaryCostCenters: Label 'Ancillary Cost Centers';
        XACTACCR: Label 'ACTACCR', Comment = 'ACTACCR stands for Actual Accurals and it is a name of Cost Center.';
        XActualAccruals: Label 'Actual Accruals';
        XTotal: Label 'Total';
        XTotalCostCenter: Label 'Total Cost Center';

    procedure InsertData(CostCenterCode: Code[20]; CostCenterName: Text[30]; CostSubType: Enum "Cost Center Subtype"; SortingOrder: Code[10]; LineType: Integer; TotalFromTo: Text[30])
    var
        CostCenter: Record "Cost Center";
    begin
        CostCenter.Init();
        CostCenter.Code := CostCenterCode;
        CostCenter.Name := CostCenterName;
        CostCenter."Cost Subtype" := CostSubType;
        CostCenter."Sorting Order" := SortingOrder;
        CostCenter.Totaling := TotalFromTo;
        CostCenter.Validate("Line Type", LineType);

        if CostCenter."Line Type" = CostCenter."Line Type"::"End-Total" then
            CostCenter."Blank Line" := true;

        if not CostCenter.Insert() then
            CostCenter.Modify();
    end;
}

