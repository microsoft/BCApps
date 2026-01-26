codeunit 101110 "Create Inventory Posting Setup"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        if DemoDataSetup."Data Type" = DemoDataSetup."Data Type"::Extended then begin
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
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        GetGLAccNo: Codeunit "Create G/L Account";
        XMAIN: Label 'MAIN';
        XEAST: Label 'EAST';
        XWEST: Label 'WEST';
        XBLUE: Label 'BLUE';
        XGREEN: Label 'GREEN';
        XRED: Label 'RED';
        XYELLOW: Label 'YELLOW';
        XWHITE: Label 'WHITE';
        XSILVER: Label 'SILVER';

    procedure InsertData("Location Code": Code[10]; "Inventory Posting Group": Code[20]; "Inventory Account": Code[20]; "Inventory Account (Interim)": Code[20])
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        MakeAdjustments: Codeunit "Make Adjustments";
    begin
        InventoryPostingSetup.Init();
        InventoryPostingSetup.Validate("Location Code", "Location Code");
        InventoryPostingSetup.Validate("Invt. Posting Group Code", "Inventory Posting Group");
        InventoryPostingSetup.Validate("Inventory Account", MakeAdjustments.Convert("Inventory Account"));
        InventoryPostingSetup.Validate("Inventory Account (Interim)", MakeAdjustments.Convert("Inventory Account (Interim)"));
        InventoryPostingSetup.Insert();
    end;

    procedure InsertMiniAppData()
    begin
        DemoDataSetup.Get();
        InsertData2('', DemoDataSetup.FinishedCode(), GetGLAccNo.FinishedGoods(), GetGLAccNo.FinishedGoodsInterim(), GetGLAccNo.WIPAccountFinishedGoods(), GetGLAccNo.MaterialVariance(), GetGLAccNo.CapacityVariance(), GetGLAccNo.MfgOverheadVariance(), GetGLAccNo.CapOverheadVariance(), GetGLAccNo.SubcontractedVariance());
        InsertData2('', DemoDataSetup.RawMatCode(), GetGLAccNo.RawMaterials(), GetGLAccNo.RawMaterialsInterim(), GetGLAccNo.WIPAccountFinishedGoods(), GetGLAccNo.MaterialVariance(), GetGLAccNo.CapacityVariance(), GetGLAccNo.MfgOverheadVariance(), GetGLAccNo.CapOverheadVariance(), GetGLAccNo.SubcontractedVariance());
        InsertData2('', DemoDataSetup.ResaleCode(), GetGLAccNo.ResaleItems(), GetGLAccNo.ResaleItemsInterim(), GetGLAccNo.WIPAccountFinishedGoods(), GetGLAccNo.MaterialVariance(), GetGLAccNo.CapacityVariance(), GetGLAccNo.MfgOverheadVariance(), GetGLAccNo.CapOverheadVariance(), GetGLAccNo.SubcontractedVariance());
    end;

    procedure CreateEvaluationData()
    begin
        DemoDataSetup.Get();
        InsertData2(XMAIN, DemoDataSetup.ResaleCode(), GetGLAccNo.ResaleItems(), GetGLAccNo.ResaleItemsInterim(), GetGLAccNo.WIPAccountFinishedGoods(), GetGLAccNo.MaterialVariance(), GetGLAccNo.CapacityVariance(), GetGLAccNo.MfgOverheadVariance(), GetGLAccNo.CapOverheadVariance(), GetGLAccNo.SubcontractedVariance());
        InsertData2(XEAST, DemoDataSetup.ResaleCode(), GetGLAccNo.ResaleItems(), GetGLAccNo.ResaleItemsInterim(), GetGLAccNo.WIPAccountFinishedGoods(), GetGLAccNo.MaterialVariance(), GetGLAccNo.CapacityVariance(), GetGLAccNo.MfgOverheadVariance(), GetGLAccNo.CapOverheadVariance(), GetGLAccNo.SubcontractedVariance());
        InsertData2(XWEST, DemoDataSetup.ResaleCode(), GetGLAccNo.ResaleItems(), GetGLAccNo.ResaleItemsInterim(), GetGLAccNo.WIPAccountFinishedGoods(), GetGLAccNo.MaterialVariance(), GetGLAccNo.CapacityVariance(), GetGLAccNo.MfgOverheadVariance(), GetGLAccNo.CapOverheadVariance(), GetGLAccNo.SubcontractedVariance());
        InsertData2(XMAIN, DemoDataSetup.FinishedCode(), GetGLAccNo.FinishedGoods(), GetGLAccNo.FinishedGoodsInterim(), GetGLAccNo.WIPAccountFinishedGoods(), GetGLAccNo.MaterialVariance(), GetGLAccNo.CapacityVariance(), GetGLAccNo.MfgOverheadVariance(), GetGLAccNo.CapOverheadVariance(), GetGLAccNo.SubcontractedVariance());
        InsertData2(XEAST, DemoDataSetup.FinishedCode(), GetGLAccNo.FinishedGoods(), GetGLAccNo.FinishedGoodsInterim(), GetGLAccNo.WIPAccountFinishedGoods(), GetGLAccNo.MaterialVariance(), GetGLAccNo.CapacityVariance(), GetGLAccNo.MfgOverheadVariance(), GetGLAccNo.CapOverheadVariance(), GetGLAccNo.SubcontractedVariance());
        InsertData2(XWEST, DemoDataSetup.FinishedCode(), GetGLAccNo.FinishedGoods(), GetGLAccNo.FinishedGoodsInterim(), GetGLAccNo.WIPAccountFinishedGoods(), GetGLAccNo.MaterialVariance(), GetGLAccNo.CapacityVariance(), GetGLAccNo.MfgOverheadVariance(), GetGLAccNo.CapOverheadVariance(), GetGLAccNo.SubcontractedVariance());
        InsertData2(XMAIN, DemoDataSetup.RawMatCode(), GetGLAccNo.RawMaterials(), GetGLAccNo.RawMaterialsInterim(), GetGLAccNo.WIPAccountFinishedGoods(), GetGLAccNo.MaterialVariance(), GetGLAccNo.CapacityVariance(), GetGLAccNo.MfgOverheadVariance(), GetGLAccNo.CapOverheadVariance(), GetGLAccNo.SubcontractedVariance());
        InsertData2(XEAST, DemoDataSetup.RawMatCode(), GetGLAccNo.RawMaterials(), GetGLAccNo.RawMaterialsInterim(), GetGLAccNo.WIPAccountFinishedGoods(), GetGLAccNo.MaterialVariance(), GetGLAccNo.CapacityVariance(), GetGLAccNo.MfgOverheadVariance(), GetGLAccNo.CapOverheadVariance(), GetGLAccNo.SubcontractedVariance());
        InsertData2(XWEST, DemoDataSetup.RawMatCode(), GetGLAccNo.RawMaterials(), GetGLAccNo.RawMaterialsInterim(), GetGLAccNo.WIPAccountFinishedGoods(), GetGLAccNo.MaterialVariance(), GetGLAccNo.CapacityVariance(), GetGLAccNo.MfgOverheadVariance(), GetGLAccNo.CapOverheadVariance(), GetGLAccNo.SubcontractedVariance());
    end;

    procedure InsertData2("Location Code": Code[10]; "Inventory Posting Group": Code[20]; "Inventory Account": Code[20]; "Inventory Account (Interim)": Code[20]; "WIP Account": Code[20]; "Material Variance Account": Code[20]; "Capacity Variance Account": Code[20]; "Mfg. Overhead Variance Account": Code[20]; "Cap. Overhead Variance Account": Code[20]; "Subcontracted Variance Account": Code[20])
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        MakeAdjustments: Codeunit "Make Adjustments";
    begin
        InventoryPostingSetup.Init();
        InventoryPostingSetup.Validate("Location Code", "Location Code");
        InventoryPostingSetup.Validate("Invt. Posting Group Code", "Inventory Posting Group");
        InventoryPostingSetup.Validate("Inventory Account", MakeAdjustments.Convert("Inventory Account"));
        InventoryPostingSetup.Validate("Inventory Account (Interim)", MakeAdjustments.Convert("Inventory Account (Interim)"));
        InventoryPostingSetup.Validate("WIP Account", "WIP Account");
        InventoryPostingSetup.Validate("Material Variance Account", "Material Variance Account");
        InventoryPostingSetup.Validate("Capacity Variance Account", "Capacity Variance Account");
        InventoryPostingSetup.Validate("Mfg. Overhead Variance Account", "Mfg. Overhead Variance Account");
        InventoryPostingSetup.Validate("Cap. Overhead Variance Account", "Cap. Overhead Variance Account");
        InventoryPostingSetup.Validate("Subcontracted Variance Account", "Subcontracted Variance Account");
        InventoryPostingSetup.Insert();
    end;
}

