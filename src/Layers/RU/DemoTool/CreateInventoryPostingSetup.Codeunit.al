codeunit 101110 "Create Inventory Posting Setup"
{

    trigger OnRun()
    begin
        InsertData('', '07-1000', '07-1000', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData('', '10-0100', '10-0100', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData('', '10-0200', '10-0200', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData('', '10-0300', '10-0300', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData('', '10-0400', '10-0400', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData('', '10-0500', '10-0500', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData('', '10-0600', '10-0600', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData('', '10-0800', '10-0800', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData('', '10-0900', '10-0900', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData('', '10-1000', '10-1000', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData('', '10-3000', '10-3000', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData('', '41-1000', '41-1000', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData('', '41-2000', '41-2000', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData('', '41-3000', '41-3000', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData('', '41-4000', '41-4000', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData('', '43-1000', '43-1000', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XBLUE, '07-1000', '07-1000', '', '', '', '', '', '');
        InsertData(XBLUE, '10-0100', '10-0100', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XBLUE, '10-0200', '10-0200', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XBLUE, '10-0300', '10-0300', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XBLUE, '10-0400', '10-0400', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XBLUE, '10-0500', '10-0500', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XBLUE, '10-0600', '10-0600', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XBLUE, '10-0800', '10-0800', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XBLUE, '10-0900', '10-0900', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XBLUE, '10-1000', '10-1000', '', '', '', '', '', '');
        InsertData(XBLUE, '10-3000', '10-3000', '', '', '', '', '', '');
        InsertData(XBLUE, '41-1000', '41-1000', '', '', '', '', '', '');
        InsertData(XBLUE, '41-2000', '41-2000', '', '', '', '', '', '');
        InsertData(XBLUE, '41-3000', '41-3000', '', '', '', '', '', '');
        InsertData(XBLUE, '41-4000', '41-4000', '', '', '', '', '', '');
        InsertData(XBLUE, '43-1000', '43-1000', '', '', '', '', '', '');
        InsertData(XYELLOW, '07-1000', '07-1000', '', '', '', '', '', '');
        InsertData(XYELLOW, '10-0100', '10-0100', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XYELLOW, '10-0200', '10-0200', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XYELLOW, '10-0300', '10-0300', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XYELLOW, '10-0400', '10-0400', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XYELLOW, '10-0500', '10-0500', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XYELLOW, '10-0600', '10-0600', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XYELLOW, '10-0800', '10-0800', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XYELLOW, '10-0900', '10-0900', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XYELLOW, '41-1000', '41-1000', '', '', '', '', '', '');
        InsertData(XYELLOW, '41-2000', '41-2000', '', '', '', '', '', '');
        InsertData(XYELLOW, '41-3000', '41-3000', '', '', '', '', '', '');
        InsertData(XYELLOW, '41-4000', '41-4000', '', '', '', '', '', '');
        InsertData(XYELLOW, '43-1000', '43-1000', '', '', '', '', '', '');
        InsertData(XWHITE, '07-1000', '07-1000', '', '', '', '', '', '');
        InsertData(XWHITE, '10-0100', '10-0100', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XWHITE, '10-0200', '10-0200', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XWHITE, '10-0300', '10-0300', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XWHITE, '10-0400', '10-0400', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XWHITE, '10-0500', '10-0500', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XWHITE, '10-0600', '10-0600', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XWHITE, '10-0800', '10-0800', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XWHITE, '10-0900', '10-0900', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XWHITE, '41-1000', '41-1000', '', '', '', '', '', '');
        InsertData(XWHITE, '41-2000', '41-2000', '', '', '', '', '', '');
        InsertData(XWHITE, '41-3000', '41-3000', '', '', '', '', '', '');
        InsertData(XWHITE, '41-4000', '41-4000', '', '', '', '', '', '');
        InsertData(XWHITE, '43-1000', '43-1000', '', '', '', '', '', '');
        InsertData(XSILVER, '07-1000', '07-1000', '', '', '', '', '', '');
        InsertData(XSILVER, '10-0100', '10-0100', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XSILVER, '10-0200', '10-0200', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XSILVER, '10-0300', '10-0300', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XSILVER, '10-0400', '10-0400', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XSILVER, '10-0500', '10-0500', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XSILVER, '10-0600', '10-0600', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XSILVER, '10-0800', '10-0800', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XSILVER, '10-0900', '10-0900', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XSILVER, '41-1000', '41-1000', '', '', '', '', '', '');
        InsertData(XSILVER, '41-2000', '41-2000', '', '', '', '', '', '');
        InsertData(XSILVER, '41-3000', '41-3000', '', '', '', '', '', '');
        InsertData(XSILVER, '41-4000', '41-4000', '', '', '', '', '', '');
        InsertData(XSILVER, '43-1000', '43-1000', '', '', '', '', '', '');
        InsertData(XRED, '07-1000', '07-1000', '', '', '', '', '', '');
        InsertData(XRED, '10-0100', '10-0100', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XRED, '10-0200', '10-0200', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XRED, '10-0300', '10-0300', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XRED, '10-0400', '10-0400', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XRED, '10-0500', '10-0500', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XRED, '10-0600', '10-0600', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XRED, '10-0800', '10-0800', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XRED, '10-0900', '10-0900', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XRED, '41-1000', '41-1000', '', '', '', '', '', '');
        InsertData(XRED, '41-2000', '41-2000', '', '', '', '', '', '');
        InsertData(XRED, '41-3000', '41-3000', '', '', '', '', '', '');
        InsertData(XRED, '41-4000', '41-4000', '', '', '', '', '', '');
        InsertData(XRED, '43-1000', '43-1000', '', '', '', '', '', '');
        InsertData(XGREEN, '07-1000', '07-1000', '', '', '', '', '', '');
        InsertData(XGREEN, '10-0100', '10-0100', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XGREEN, '10-0200', '10-0200', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XGREEN, '10-0300', '10-0300', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XGREEN, '10-0400', '10-0400', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XGREEN, '10-0500', '10-0500', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XGREEN, '10-0600', '10-0600', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XGREEN, '10-0800', '10-0800', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XGREEN, '10-0900', '10-0900', '40-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XGREEN, '41-1000', '41-1000', '', '', '', '', '', '');
        InsertData(XGREEN, '41-2000', '41-2000', '', '', '', '', '', '');
        InsertData(XGREEN, '41-3000', '41-3000', '', '', '', '', '', '');
        InsertData(XGREEN, '41-4000', '41-4000', '', '', '', '', '', '');
        InsertData(XGREEN, '43-1000', '43-1000', '', '', '', '', '', '');
        InsertData(XSTORAGE, '99-0020', '99-1020', '', '', '', '', '', '');
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
        XSTORAGE: Label 'STORAGE';

    procedure InsertData("Location Code": Code[10]; "Inventory Posting Group": Code[20]; "Inventory Account": Code[20]; "WIP Account": Code[20]; "Material Variance Account": Code[20]; "Capacity Variance Account": Code[20]; "Mfg. Overhead Variance Account": Code[20]; "Cap. Overhead Variance Account": Code[20]; "Subcontracted Variance Account": Code[20])
    var
        InventoryPostingSetup: Record "Inventory Posting Setup";
        MakeAdjustments: Codeunit "Make Adjustments";
    begin
        InventoryPostingSetup.Init();
        InventoryPostingSetup.Validate("Location Code", "Location Code");
        InventoryPostingSetup.Validate("Invt. Posting Group Code", "Inventory Posting Group");
        InventoryPostingSetup.Validate("Inventory Account", MakeAdjustments.Convert("Inventory Account"));
        InventoryPostingSetup.Validate("Inventory Account (Interim)", InventoryPostingSetup."Inventory Account");
        InventoryPostingSetup.Validate("WIP Account", MakeAdjustments.Convert("WIP Account"));
        InventoryPostingSetup.Validate("Material Variance Account", MakeAdjustments.Convert("Material Variance Account"));
        InventoryPostingSetup.Validate("Capacity Variance Account", MakeAdjustments.Convert("Capacity Variance Account"));
        InventoryPostingSetup.Validate("Mfg. Overhead Variance Account", MakeAdjustments.Convert("Mfg. Overhead Variance Account"));
        InventoryPostingSetup.Validate("Cap. Overhead Variance Account", MakeAdjustments.Convert("Cap. Overhead Variance Account"));
        InventoryPostingSetup.Validate("Subcontracted Variance Account", MakeAdjustments.Convert("Subcontracted Variance Account"));
        InventoryPostingSetup.Insert();
    end;

    procedure InsertMiniAppData()
    begin
        DemoDataSetup.Get();
        InsertData('', DemoDataSetup.ResaleCode(), '41-1000', '41-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
    end;

    procedure CreateEvaluationData()
    begin
        DemoDataSetup.Get();
        InsertData(XMAIN, DemoDataSetup.ResaleCode(), '41-1000', '41-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XEAST, DemoDataSetup.ResaleCode(), '41-1000', '41-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
        InsertData(XWEST, DemoDataSetup.ResaleCode(), '41-1000', '41-1000', '16-1000', '16-1000', '16-1000', '16-1000', '16-1000');
    end;
}

