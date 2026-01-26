codeunit 101110 "Create Inventory Posting Setup"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InsertData('', DemoDataSetup.FinishedCode(), '1260', '1261');
        InsertData('', DemoDataSetup.RawMatCode(), '1210', '1211');
        InsertData('', DemoDataSetup.ResaleCode(), '1200', '1201');
        InsertData(XBLUE, DemoDataSetup.FinishedCode(), '1260', '1261');
        InsertData(XBLUE, DemoDataSetup.RawMatCode(), '1210', '1211');
        InsertData(XBLUE, DemoDataSetup.ResaleCode(), '1200', '1201');
        InsertData(XGREEN, DemoDataSetup.FinishedCode(), '1260', '1261');
        InsertData(XGREEN, DemoDataSetup.RawMatCode(), '1210', '1211');
        InsertData(XGREEN, DemoDataSetup.ResaleCode(), '1200', '1201');
        InsertData(XRED, DemoDataSetup.FinishedCode(), '1260', '1261');
        InsertData(XRED, DemoDataSetup.RawMatCode(), '1210', '1211');
        InsertData(XRED, DemoDataSetup.ResaleCode(), '1200', '1201');
        InsertData(XYELLOW, DemoDataSetup.FinishedCode(), '1260', '1261');
        InsertData(XYELLOW, DemoDataSetup.RawMatCode(), '1210', '1211');
        InsertData(XYELLOW, DemoDataSetup.ResaleCode(), '1200', '1201');
        InsertData(XWHITE, DemoDataSetup.FinishedCode(), '1260', '1261');
        InsertData(XWHITE, DemoDataSetup.RawMatCode(), '1210', '1211');
        InsertData(XWHITE, DemoDataSetup.ResaleCode(), '1200', '1201');
        InsertData(XSILVER, DemoDataSetup.FinishedCode(), '1260', '1261');
        InsertData(XSILVER, DemoDataSetup.RawMatCode(), '1210', '1211');
        InsertData(XSILVER, DemoDataSetup.ResaleCode(), '1200', '1201');
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
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
        InsertData('', DemoDataSetup.ResaleCode(), '1200', '1201');
    end;

    procedure CreateEvaluationData()
    begin
        DemoDataSetup.Get();
        InsertData(XMAIN, DemoDataSetup.ResaleCode(), '1200', '1201');
        InsertData(XEAST, DemoDataSetup.ResaleCode(), '1200', '1201');
        InsertData(XWEST, DemoDataSetup.ResaleCode(), '1200', '1201');
    end;
}

