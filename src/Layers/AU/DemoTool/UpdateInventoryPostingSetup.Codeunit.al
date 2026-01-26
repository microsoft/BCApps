codeunit 118013 "Update Inventory Posting Setup"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        CreateInventoryPostingSetup.InsertData(XOUTLOG, DemoDataSetup.FinishedCode(), '992120', '992121');
        CreateInventoryPostingSetup.InsertData(XOUTLOG, DemoDataSetup.RawMatCode(), '992130', '992131');
        CreateInventoryPostingSetup.InsertData(XOUTLOG, DemoDataSetup.ResaleCode(), '992110', '992111');
        CreateInventoryPostingSetup.InsertData(XOWNLOG, DemoDataSetup.FinishedCode(), '992120', '992121');
        CreateInventoryPostingSetup.InsertData(XOWNLOG, DemoDataSetup.RawMatCode(), '992130', '992131');
        CreateInventoryPostingSetup.InsertData(XOWNLOG, DemoDataSetup.ResaleCode(), '992110', '992111');
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        GetGLAccNo: Codeunit "Create G/L Account";
        XOUTLOG: Label 'OUT. LOG.';
        XOWNLOG: Label 'OWN LOG.';
        CreateInventoryPostingSetup: Codeunit "Create Inventory Posting Setup";

    procedure CreateEvaluationData()
    begin
        DemoDataSetup.Get();
        CreateInventoryPostingSetup.InsertData2(XOUTLOG, DemoDataSetup.ResaleCode(), GetGLAccNo.ResaleItems(), GetGLAccNo.ResaleItemsInterim(), '', '', '', '', '', '');
        CreateInventoryPostingSetup.InsertData2(XOWNLOG, DemoDataSetup.ResaleCode(), GetGLAccNo.ResaleItems(), GetGLAccNo.ResaleItemsInterim(), '', '', '', '', '', '');
        CreateInventoryPostingSetup.InsertData2(XOUTLOG, DemoDataSetup.FinishedCode(), GetGLAccNo.FinishedGoods(), GetGLAccNo.FinishedGoodsInterim(), '', '', '', '', '', '');
        CreateInventoryPostingSetup.InsertData2(XOWNLOG, DemoDataSetup.FinishedCode(), GetGLAccNo.FinishedGoods(), GetGLAccNo.FinishedGoodsInterim(), '', '', '', '', '', '');
        CreateInventoryPostingSetup.InsertData2(XOUTLOG, DemoDataSetup.RawMatCode(), GetGLAccNo.RawMaterials(), GetGLAccNo.RawMaterialsInterim(), '', '', '', '', '', '');
        CreateInventoryPostingSetup.InsertData2(XOWNLOG, DemoDataSetup.RawMatCode(), GetGLAccNo.RawMaterials(), GetGLAccNo.RawMaterialsInterim(), '', '', '', '', '', '');
    end;
}

