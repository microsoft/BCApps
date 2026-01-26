codeunit 101110 "Create Inventory Posting Setup"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData('', DemoDataSetup.FinishedCode(), '992120', '992121');
        InsertData('', DemoDataSetup.RawMatCode(), '992130', '992131');
        InsertData('', DemoDataSetup.ResaleCode(), '992110', '992111');
        InsertData(XBLUE, DemoDataSetup.FinishedCode(), '992120', '992121');
        InsertData(XBLUE, DemoDataSetup.RawMatCode(), '992130', '992131');
        InsertData(XBLUE, DemoDataSetup.ResaleCode(), '992110', '992111');
        InsertData(XGREEN, DemoDataSetup.FinishedCode(), '992120', '992121');
        InsertData(XGREEN, DemoDataSetup.RawMatCode(), '992130', '992131');
        InsertData(XGREEN, DemoDataSetup.ResaleCode(), '992110', '992111');
        InsertData(XRED, DemoDataSetup.FinishedCode(), '992120', '992121');
        InsertData(XRED, DemoDataSetup.RawMatCode(), '992130', '992131');
        InsertData(XRED, DemoDataSetup.ResaleCode(), '992110', '992111');
        InsertData(XYELLOW, DemoDataSetup.FinishedCode(), '992120', '992121');
        InsertData(XYELLOW, DemoDataSetup.RawMatCode(), '992130', '992131');
        InsertData(XYELLOW, DemoDataSetup.ResaleCode(), '992110', '992111');
        InsertData(XWHITE, DemoDataSetup.FinishedCode(), '992120', '992121');
        InsertData(XWHITE, DemoDataSetup.RawMatCode(), '992130', '992131');
        InsertData(XWHITE, DemoDataSetup.ResaleCode(), '992110', '992111');
        InsertData(XSILVER, DemoDataSetup.FinishedCode(), '992120', '992121');
        InsertData(XSILVER, DemoDataSetup.RawMatCode(), '992130', '992131');
        InsertData(XSILVER, DemoDataSetup.ResaleCode(), '992110', '992111');
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        GetGLAccNo: Codeunit "Get G/L Account No. and Name";
        XMAIN: Label 'MAIN';
        XEAST: Label 'EAST';
        XWEST: Label 'WEST';
        XBLUE: Label 'BLUE';
        XGREEN: Label 'GREEN';
        XRED: Label 'RED';
        XYELLOW: Label 'YELLOW';
        XWHITE: Label 'WHITE';
        XSILVER: Label 'SILVER';

    procedure InsertData(LocationCode: Code[10]; InventoryPostingGroup: Code[20]; InventoryAccount: Code[20]; InventoryAccountInterim: Code[20])
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        MakeAdjustments: Codeunit "Make Adjustments";
    begin
        InventoryPostingSetup.Init();
        InventoryPostingSetup.Validate("Location Code", LocationCode);
        InventoryPostingSetup.Validate("Invt. Posting Group Code", InventoryPostingGroup);
        InventoryPostingSetup.Validate("Inventory Account", MakeAdjustments.Convert(InventoryAccount));
        InventoryPostingSetup.Validate("Inventory Account (Interim)", MakeAdjustments.Convert(InventoryAccountInterim));
        InventoryPostingSetup.Insert();
    end;

    procedure InsertData(LocationCode: Code[10]; InventoryPostingGroup: Code[20]; InventoryAccount: Code[20]; InventoryAccountInterim: Code[20]; WIPAccount: Code[20]; MaterialVarianceAccount: Code[20]; CapacityVarianceAccount: Code[20]; MfgOverheadVarianceAccount: Code[20]; CapOverheadVarianceAccount: Code[20]; SubcontractedVarianceAccount: Code[20])
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        MakeAdjustments: Codeunit "Make Adjustments";
    begin
        InventoryPostingSetup.Init();
        InventoryPostingSetup.Validate("Location Code", LocationCode);
        InventoryPostingSetup.Validate("Invt. Posting Group Code", InventoryPostingGroup);
        InventoryPostingSetup.Validate("Inventory Account", MakeAdjustments.Convert(InventoryAccount));
        InventoryPostingSetup.Validate("Inventory Account (Interim)", MakeAdjustments.Convert(InventoryAccountInterim));
        InventoryPostingSetup.Validate("WIP Account", WIPAccount);
        InventoryPostingSetup.Validate("Material Variance Account", MaterialVarianceAccount);
        InventoryPostingSetup.Validate("Capacity Variance Account", CapacityVarianceAccount);
        InventoryPostingSetup.Validate("Mfg. Overhead Variance Account", MfgOverheadVarianceAccount);
        InventoryPostingSetup.Validate("Cap. Overhead Variance Account", CapOverheadVarianceAccount);
        InventoryPostingSetup.Validate("Subcontracted Variance Account", SubcontractedVarianceAccount);
        InventoryPostingSetup.Insert();
    end;

    procedure InsertMiniAppData()

    begin
        DemoDataSetup.Get();
        InsertData('', DemoDataSetup.FinishedCode(), GetGLAccNo.FinishedGoods(), GetGLAccNo.FinishedGoodsInterim(), GetGLAccNo.WIPAccountFinishedGoods(), GetGLAccNo.MaterialVariance(), GetGLAccNo.CapacityVariance(), GetGLAccNo.MfgOverheadVariance(), GetGLAccNo.CapOverheadVariance(), GetGLAccNo.SubcontractedVariance());
        InsertData('', DemoDataSetup.RawMatCode(), GetGLAccNo.RawMaterials(), GetGLAccNo.RawMaterialsInterim(), GetGLAccNo.WIPAccountFinishedGoods(), GetGLAccNo.MaterialVariance(), GetGLAccNo.CapacityVariance(), GetGLAccNo.MfgOverheadVariance(), GetGLAccNo.CapOverheadVariance(), GetGLAccNo.SubcontractedVariance());
        InsertData('', DemoDataSetup.ResaleCode(), GetGLAccNo.ResaleItems(), GetGLAccNo.ResaleItemsInterim(), GetGLAccNo.WIPAccountFinishedGoods(), GetGLAccNo.MaterialVariance(), GetGLAccNo.CapacityVariance(), GetGLAccNo.MfgOverheadVariance(), GetGLAccNo.CapOverheadVariance(), GetGLAccNo.SubcontractedVariance());
    end;

    procedure CreateEvaluationData()
    begin
        DemoDataSetup.Get();
        InsertData(XMAIN, DemoDataSetup.ResaleCode(), GetGLAccNo.ResaleItems(), GetGLAccNo.ResaleItemsInterim(), GetGLAccNo.WIPAccountFinishedGoods(), GetGLAccNo.MaterialVariance(), GetGLAccNo.CapacityVariance(), GetGLAccNo.MfgOverheadVariance(), GetGLAccNo.CapOverheadVariance(), GetGLAccNo.SubcontractedVariance());
        InsertData(XEAST, DemoDataSetup.ResaleCode(), GetGLAccNo.ResaleItems(), GetGLAccNo.ResaleItemsInterim(), GetGLAccNo.WIPAccountFinishedGoods(), GetGLAccNo.MaterialVariance(), GetGLAccNo.CapacityVariance(), GetGLAccNo.MfgOverheadVariance(), GetGLAccNo.CapOverheadVariance(), GetGLAccNo.SubcontractedVariance());
        InsertData(XWEST, DemoDataSetup.ResaleCode(), GetGLAccNo.ResaleItems(), GetGLAccNo.ResaleItemsInterim(), GetGLAccNo.WIPAccountFinishedGoods(), GetGLAccNo.MaterialVariance(), GetGLAccNo.CapacityVariance(), GetGLAccNo.MfgOverheadVariance(), GetGLAccNo.CapOverheadVariance(), GetGLAccNo.SubcontractedVariance());
        InsertData(XMAIN, DemoDataSetup.FinishedCode(), GetGLAccNo.FinishedGoods(), GetGLAccNo.FinishedGoodsInterim(), GetGLAccNo.WIPAccountFinishedGoods(), GetGLAccNo.MaterialVariance(), GetGLAccNo.CapacityVariance(), GetGLAccNo.MfgOverheadVariance(), GetGLAccNo.CapOverheadVariance(), GetGLAccNo.SubcontractedVariance());
        InsertData(XEAST, DemoDataSetup.FinishedCode(), GetGLAccNo.FinishedGoods(), GetGLAccNo.FinishedGoodsInterim(), GetGLAccNo.WIPAccountFinishedGoods(), GetGLAccNo.MaterialVariance(), GetGLAccNo.CapacityVariance(), GetGLAccNo.MfgOverheadVariance(), GetGLAccNo.CapOverheadVariance(), GetGLAccNo.SubcontractedVariance());
        InsertData(XWEST, DemoDataSetup.FinishedCode(), GetGLAccNo.FinishedGoods(), GetGLAccNo.FinishedGoodsInterim(), GetGLAccNo.WIPAccountFinishedGoods(), GetGLAccNo.MaterialVariance(), GetGLAccNo.CapacityVariance(), GetGLAccNo.MfgOverheadVariance(), GetGLAccNo.CapOverheadVariance(), GetGLAccNo.SubcontractedVariance());
        InsertData(XMAIN, DemoDataSetup.RawMatCode(), GetGLAccNo.RawMaterials(), GetGLAccNo.RawMaterialsInterim(), GetGLAccNo.WIPAccountFinishedGoods(), GetGLAccNo.MaterialVariance(), GetGLAccNo.CapacityVariance(), GetGLAccNo.MfgOverheadVariance(), GetGLAccNo.CapOverheadVariance(), GetGLAccNo.SubcontractedVariance());
        InsertData(XEAST, DemoDataSetup.RawMatCode(), GetGLAccNo.RawMaterials(), GetGLAccNo.RawMaterialsInterim(), GetGLAccNo.WIPAccountFinishedGoods(), GetGLAccNo.MaterialVariance(), GetGLAccNo.CapacityVariance(), GetGLAccNo.MfgOverheadVariance(), GetGLAccNo.CapOverheadVariance(), GetGLAccNo.SubcontractedVariance());
        InsertData(XWEST, DemoDataSetup.RawMatCode(), GetGLAccNo.RawMaterials(), GetGLAccNo.RawMaterialsInterim(), GetGLAccNo.WIPAccountFinishedGoods(), GetGLAccNo.MaterialVariance(), GetGLAccNo.CapacityVariance(), GetGLAccNo.MfgOverheadVariance(), GetGLAccNo.CapOverheadVariance(), GetGLAccNo.SubcontractedVariance());
    end;
}

