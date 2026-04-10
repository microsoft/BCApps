codeunit 118013 "Update Inventory Posting Setup"
{

    trigger OnRun()
    begin
        InsertData(XOUTLOG, '07-1000', '07-1000', '', '', '', '', '', '');
        InsertData(XOUTLOG, '10-0100', '10-0100', '', '', '', '', '', '');
        InsertData(XOUTLOG, '10-0200', '10-0200', '', '', '', '', '', '');
        InsertData(XOUTLOG, '10-0300', '10-0300', '', '', '', '', '', '');
        InsertData(XOUTLOG, '10-0400', '10-0400', '', '', '', '', '', '');
        InsertData(XOUTLOG, '10-0500', '10-0500', '', '', '', '', '', '');
        InsertData(XOUTLOG, '10-0600', '10-0600', '', '', '', '', '', '');
        InsertData(XOUTLOG, '10-0800', '10-0800', '', '', '', '', '', '');
        InsertData(XOUTLOG, '10-0900', '10-0900', '', '', '', '', '', '');
        InsertData(XOUTLOG, '41-1000', '41-1000', '', '', '', '', '', '');
        InsertData(XOUTLOG, '41-2000', '41-2000', '', '', '', '', '', '');
        InsertData(XOUTLOG, '41-3000', '41-3000', '', '', '', '', '', '');
        InsertData(XOUTLOG, '41-4000', '41-4000', '', '', '', '', '', '');
        InsertData(XOUTLOG, '43-1000', '43-1000', '', '', '', '', '', '');
        InsertData(XOWNLOG, '07-1000', '07-1000', '', '', '', '', '', '');
        InsertData(XOWNLOG, '10-0100', '10-0100', '', '', '', '', '', '');
        InsertData(XOWNLOG, '10-0200', '10-0200', '', '', '', '', '', '');
        InsertData(XOWNLOG, '10-0300', '10-0300', '', '', '', '', '', '');
        InsertData(XOWNLOG, '10-0400', '10-0400', '', '', '', '', '', '');
        InsertData(XOWNLOG, '10-0500', '10-0500', '', '', '', '', '', '');
        InsertData(XOWNLOG, '10-0600', '10-0600', '', '', '', '', '', '');
        InsertData(XOWNLOG, '10-0800', '10-0800', '', '', '', '', '', '');
        InsertData(XOWNLOG, '10-0900', '10-0900', '', '', '', '', '', '');
        InsertData(XOWNLOG, '10-1000', '10-1000', '', '', '', '', '', '');
        InsertData(XOWNLOG, '41-1000', '41-1000', '', '', '', '', '', '');
        InsertData(XOWNLOG, '41-2000', '41-2000', '', '', '', '', '', '');
        InsertData(XOWNLOG, '41-3000', '41-3000', '', '', '', '', '', '');
        InsertData(XOWNLOG, '41-4000', '41-4000', '', '', '', '', '', '');
        InsertData(XOWNLOG, '43-1000', '43-1000', '', '', '', '', '', '');
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        XOUTLOG: Label 'OUT. LOG.';
        XOWNLOG: Label 'OWN LOG.';

    procedure InsertData("Location Code": Code[10]; "Inventory Posting Group": Code[20]; "Inventory Account": Code[20]; "WIP Account": Code[20]; "Material Variance Account": Code[20]; "Capacity Variance Account": Code[20]; "Mfg. Overhead Variance Account": Code[20]; "Cap. Overhead Variance Account": Code[20]; "Subcontracted Variance Account": Code[20])
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        MakeAdjustments: Codeunit "Make Adjustments";
    begin
        InventoryPostingSetup.Init();
        InventoryPostingSetup.Validate("Location Code", "Location Code");
        InventoryPostingSetup.Validate("Invt. Posting Group Code", "Inventory Posting Group");
        InventoryPostingSetup.Validate("Inventory Account", MakeAdjustments.Convert("Inventory Account"));
        InventoryPostingSetup.Validate("WIP Account", MakeAdjustments.Convert("WIP Account"));
        InventoryPostingSetup.Validate("Material Variance Account", MakeAdjustments.Convert("Material Variance Account"));
        InventoryPostingSetup.Validate("Capacity Variance Account", MakeAdjustments.Convert("Capacity Variance Account"));
        InventoryPostingSetup.Validate("Mfg. Overhead Variance Account", MakeAdjustments.Convert("Mfg. Overhead Variance Account"));
        InventoryPostingSetup.Validate("Cap. Overhead Variance Account", MakeAdjustments.Convert("Cap. Overhead Variance Account"));
        InventoryPostingSetup.Validate("Subcontracted Variance Account", MakeAdjustments.Convert("Subcontracted Variance Account"));
        InventoryPostingSetup.Insert();
    end;

    procedure CreateEvaluationData()
    begin
        DemoDataSetup.Get();
        InsertData(XOUTLOG, DemoDataSetup.ResaleCode(), '41-1000', '41-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XOWNLOG, DemoDataSetup.ResaleCode(), '41-1000', '41-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
    end;
}

