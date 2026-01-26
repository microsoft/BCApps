codeunit 118013 "Update Inventory Posting Setup"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        CreateInventoryPostingSetup.InsertData(XOUTLOG, DemoDataSetup.FinishedCode(), '1260', '1261');
        CreateInventoryPostingSetup.InsertData(XOUTLOG, DemoDataSetup.RawMatCode(), '1210', '1211');
        CreateInventoryPostingSetup.InsertData(XOUTLOG, DemoDataSetup.ResaleCode(), '1200', '1201');
        CreateInventoryPostingSetup.InsertData(XOWNLOG, DemoDataSetup.FinishedCode(), '1260', '1261');
        CreateInventoryPostingSetup.InsertData(XOWNLOG, DemoDataSetup.RawMatCode(), '1210', '1211');
        CreateInventoryPostingSetup.InsertData(XOWNLOG, DemoDataSetup.ResaleCode(), '1200', '1201');
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        XOUTLOG: Label 'OUT. LOG.';
        XOWNLOG: Label 'OWN LOG.';
        CreateInventoryPostingSetup: Codeunit "Create Inventory Posting Setup";

    procedure CreateEvaluationData()
    begin
        DemoDataSetup.Get();
        CreateInventoryPostingSetup.InsertData(XOUTLOG, DemoDataSetup.ResaleCode(), '1200', '1201');
        CreateInventoryPostingSetup.InsertData(XOWNLOG, DemoDataSetup.ResaleCode(), '1200', '1201');
    end;
}

