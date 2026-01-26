codeunit 101313 "Create Inventory Setup"
{

    trigger OnRun()
    begin
        DemoDataSetup.Get();
        InventorySetup.Get();
        "Create No. Series".InitBaseSeries(InventorySetup."Item Nos.", XITEM1, XPartiallyManufactured, '70000', '70099', '70060', '70095', 1);
        "Create No. Series".InitBaseSeries(InventorySetup."Item Nos.", XITEM2, XPaint, '70100', '70199', '70104', '70195', 1, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitBaseSeries(InventorySetup."Item Nos.", XITEM3, XLooseHardware, '70200', '70299', '70201', '70295', 1, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitBaseSeries(InventorySetup."Item Nos.", XITEM4, XFinished, '1896-S', '2996-S', '2000-S', '', 4, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitBaseSeries(InventorySetup."Item Nos.", XITEM5, XAssemblyBOM, '1924-W', '2096-W', '1992-W', '', 4, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitBaseSeries(InventorySetup."Nonstock Item Nos.", XNSITEM, XNonStockItems, XNS0001, XNS0100, '', XNS0095, 1, Enum::"No. Series Implementation"::Sequence);
        InventorySetup."Item Nos." := XITEM1;
        InventorySetup."Nonstock Item Nos." := XNSITEM;
        "Create No. Series".InsertRelation(XITEM1, XITEM2);
        "Create No. Series".InsertRelation(XITEM1, XITEM3);
        "Create No. Series".InsertRelation(XITEM1, XITEM4);
        "Create No. Series".InsertRelation(XITEM1, XITEM5);
        "Create No. Series".InitFinalSeries(InventorySetup."Posted Transfer Shpt. Nos.", XTSHPT, XTransferShipment, 8);
        "Create No. Series".InitFinalSeries(InventorySetup."Posted Transfer Rcpt. Nos.", XTRCPT, XTransferReceipt, 9);
        "Create No. Series".InitTempSeries(InventorySetup."Transfer Order Nos.", XTORD, XTransferOrder);
        "Create No. Series".InitBaseSeries(
          InventorySetup."Posted Direct Trans. Nos.", XDirectTrans, XPostedDirectTransfer, XPDT000001, XPDT999999, '', '', 1);

        "Create No. Series".InitBaseSeries(
          InventorySetup."Inventory Put-away Nos.", XIPut, XInventoryPutaway, XIPU000001, XIPU999999, '', '', 1, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitBaseSeries(
          InventorySetup."Inventory Pick Nos.", XIPick, XInventoryPick, XIPI000001, XIPI999999, '', '', 1, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitBaseSeries(
          InventorySetup."Inventory Movement Nos.", XIMOVEMENT, XInventoryMovement, XIM000001, XIM999999, '', '', 1, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitBaseSeries(
          InventorySetup."Posted Invt. Put-away Nos.", XIPutPLUS, XPostedInvtPutaway, XPPU000001, XPPU999999, '', '', 1, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitBaseSeries(
          InventorySetup."Posted Invt. Pick Nos.", XIPickPLUS, XPostedInvtPick, XPPI000001, XPPI999999, '', '', 1, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitBaseSeries(
          InventorySetup."Registered Invt. Movement Nos.", XIMOVEPLUS, XRegisteredInvtMovement, XRIM000001, XRIM999999, '', '', 1, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitBaseSeries(
          InventorySetup."Internal Movement Nos.", XINTMOVE, XInternalMovement, XINTM000001, XINTM999999, '', '', 1, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitBaseSeries(
          InventorySetup."Phys. Invt. Order Nos.", XPHYSINV, XPhysicalInventoryOrder, XPHIO00001, XPHIO99999, '', '', 1, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitBaseSeries(
          InventorySetup."Posted Phys. Invt. Order Nos.", XPHYSINVPLUS, XPostedPhysInventOrder, XPPHI00001, XPPHI99999, '', '', 1, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitBaseSeries(
          InventorySetup."Invt. Receipt Nos.", XIReceipt, XInventoryReceipt, XIR000001, XIR999999, '', '', 1, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitBaseSeries(
          InventorySetup."Posted Invt. Receipt Nos.", XIReceiptPLUS, XPostedInventoryReceipt, XPIR000001, XPIR999999, '', '', 1, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitBaseSeries(
          InventorySetup."Invt. Shipment Nos.", XIShipment, XInventoryShipment, XIS000001, XIS999999, '', '', 1, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitBaseSeries(
          InventorySetup."Posted Invt. Shipment Nos.", XIShipmentPLUS, XPostedInventoryShipment, XPIS000001, XPIS999999, '', '', 1, Enum::"No. Series Implementation"::Sequence);

        InventorySetup."Combined MPS/MRP Calculation" := true;
        Evaluate(InventorySetup."Default Safety Lead Time", '<1D>');
        InventorySetup."Current Demand Forecast" := Format(DemoDataSetup."Starting Year" + 1);
        // NAVCZ
        InventorySetup."Post Neg.Transf. As Corr.CZL" := true;
        InventorySetup."Def.Tmpl. for Phys.Pos.Adj CZL" := CreateInvtMovementTemplate.GetSurplusCode();
        InventorySetup."Def.Tmpl. for Phys.Neg.Adj CZL" := CreateInvtMovementTemplate.GetDeficiencyCode();
        // NAVCZ
        InventorySetup.Modify();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        InventorySetup: Record "Inventory Setup";
        "Create No. Series": Codeunit "Create No. Series";
        CreateInvtMovementTemplate: Codeunit "Create Invt. Mvmt. Templ. CZL";
        XITEMTxt: Label 'ITEM', Comment = 'Can be translated.';
        XITEM1: Label 'ITEM1';
        XITEM2: Label 'ITEM2';
        XITEM3: Label 'ITEM3';
        XITEM4: Label 'ITEM4';
        XITEM5: Label 'ITEM5';
        XItemNoSeriesTxt: Label 'Items';
        XPartiallyManufactured: Label 'Partially Manufactured';
        XPaint: Label 'Paint';
        XLooseHardware: Label 'Loose Hardware';
        XFinished: Label 'Finished';
        XAssemblyBOM: Label 'Assembly BOM';
        XNSITEM: Label 'NS-ITEM';
        XNonStockItems: Label 'Catalog Items';
        XNS0001: Label 'NS0001';
        XNS0100: Label 'NS0100';
        XTSHPT: Label 'T-SHPT';
        XTransferShipment: Label 'Transfer Shipment';
        XTRCPT: Label 'T-RCPT';
        XTransferReceipt: Label 'Transfer Receipt';
        XTORD: Label 'T-ORD';
        XTransferOrder: Label 'Transfer Order';
        XDirectTrans: Label 'PDIRTRANS', Comment = 'Posted Direct Transfer';
        XPostedDirectTransfer: Label 'Posted Direct Transfer';
        XPDT000001: Label 'PDT000001', Comment = 'PDT - Posted Direct Transfer';
        XPDT999999: Label 'PDT999999', Comment = 'PDT - Posted Direct Transfer';
        XIPut: Label 'I-Put';
        XInventoryPutaway: Label 'Inventory Put-away';
        XIPU000001: Label 'IPU000001';
        XIPU999999: Label 'IPU999999';
        XIPick: Label 'I-Pick';
        XInventoryPick: Label 'Inventory Pick';
        XIPI000001: Label 'IPI000001';
        XIPI999999: Label 'IPI999999';
        XIMOVEMENT: Label 'I-MOVEMENT', Comment = 'I-MOVEMENT stands for Inventory-Movement.';
        XInventoryMovement: Label 'Inventory Movement';
        XIM000001: Label 'IM000001', Comment = 'IM stands for Inventory Movement.';
        XIM999999: Label 'IM999999', Comment = 'IM stands for Inventory Movement.';
        XIPutPLUS: Label 'I-Put+';
        XPostedInvtPutaway: Label 'Posted Invt. Put-away';
        XPPU000001: Label 'PPU000001';
        XPPU999999: Label 'PPU999999';
        XIPickPLUS: Label 'I-Pick+';
        XPostedInvtPick: Label 'Posted Invt. Pick';
        XPPI000001: Label 'PPI000001';
        XPPI999999: Label 'PPI999999';
        XNS0095: Label 'NS0095';
        XIMOVEPLUS: Label 'I-MOVE+';
        XRegisteredInvtMovement: Label 'Registered Invt. Movement';
        XRIM000001: Label 'RIM000001', Comment = 'RIM stands for Registered Inventory Movement.';
        XRIM999999: Label 'RIM999999', Comment = 'RIM stands for Registered Inventory Movement.';
        XINTMOVE: Label 'INT-MOVE', Comment = 'INT-MOVE stands for Internal Movement.';
        XInternalMovement: Label 'Internal Movement';
        XINTM000001: Label 'INTM000001', Comment = 'INTM stands for Internal Movement.';
        XINTM999999: Label 'RINTM999999', Comment = 'RINTM stands for Registered Internal Movement.';
        XPHYSINV: Label 'PHYS-INV', Comment = 'Physical Inventory Order';
        XPhysicalInventoryOrder: Label 'Physical Inventory Order';
        XPHYSINVPLUS: Label 'PHYS-INV+', Comment = 'Physical Inventory Order';
        XPostedPhysInventOrder: Label 'Posted Phys. Invent. Order';
        XPHIO00001: Label 'PHIO00001', Comment = 'Physical Inventory Order';
        XPHIO99999: Label 'PHIO99999', Comment = 'Physical Inventory Order';
        XPPHI00001: Label 'PPHI00001', Comment = 'Posted Physical Inventory Order';
        XPPHI99999: Label 'PPHI99999', Comment = 'Posted Physical Inventory Order';
        XInventoryReceipt: Label 'Inventory Receipt';
        XIR000001: Label 'IR000001';
        XIR999999: Label 'IR999999';
        XInventoryShipment: Label 'Inventory Shipment';
        XIS000001: Label 'IS000001';
        XIS999999: Label 'IS999999';
        XPostedInventoryReceipt: Label 'Posted Inventory Receipt';
        XPIR000001: Label 'IR000001';
        XPIR999999: Label 'IR999999';
        XPostedInventoryShipment: Label 'Posted Inventory Shipment';
        XPIS000001: Label 'IS000001';
        XPIS999999: Label 'IS999999';
        XIReceipt: Label 'I-RCPT';
        XIReceiptPLUS: Label 'I-RCPT+';
        XIShipment: Label 'I-SHPT';
        XIShipmentPLUS: Label 'I-SHPT+';

    procedure InsertMiniAppData()
    begin
        DemoDataSetup.Get();
        InventorySetup.Get();
        "Create No. Series".InitBaseSeries(InventorySetup."Item Nos.", XITEMTxt, XItemNoSeriesTxt, '1000', '9999', '', '9995', 1, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitBaseSeries(InventorySetup."Nonstock Item Nos.", XNSITEM, XNonStockItems, XNS0001, XNS0100, '', XNS0095, 1, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitFinalSeries(InventorySetup."Posted Transfer Shpt. Nos.", XTSHPT, XTransferShipment, 8);
        "Create No. Series".InitFinalSeries(InventorySetup."Posted Transfer Rcpt. Nos.", XTRCPT, XTransferReceipt, 9);
        "Create No. Series".InitTempSeries(InventorySetup."Transfer Order Nos.", XTORD, XTransferOrder);
        "Create No. Series".InitBaseSeries(
          InventorySetup."Posted Direct Trans. Nos.", XDirectTrans, XPostedDirectTransfer, XPDT000001, XPDT999999, '', '', 1);
        "Create No. Series".InitBaseSeries(
          InventorySetup."Phys. Invt. Order Nos.", XPHYSINV, XPhysicalInventoryOrder, XPHIO00001, XPHIO99999, '', '', 1);
        "Create No. Series".InitBaseSeries(
          InventorySetup."Posted Phys. Invt. Order Nos.", XPHYSINVPLUS, XPostedPhysInventOrder, XPPHI00001, XPPHI99999, '', '', 1);
        "Create No. Series".InitBaseSeries(
          InventorySetup."Invt. Receipt Nos.", XIReceipt, XInventoryReceipt, XIR000001, XIR999999, '', '', 1);
        "Create No. Series".InitBaseSeries(
          InventorySetup."Posted Invt. Receipt Nos.", XIReceiptPLUS, XPostedInventoryReceipt, XPIR000001, XPIR999999, '', '', 1);
        "Create No. Series".InitBaseSeries(
          InventorySetup."Invt. Shipment Nos.", XIShipment, XInventoryShipment, XIS000001, XIS999999, '', '', 1);
        "Create No. Series".InitBaseSeries(
          InventorySetup."Posted Invt. Shipment Nos.", XIShipmentPLUS, XPostedInventoryShipment, XPIS000001, XPIS999999, '', '', 1);
        InventorySetup."Automatic Cost Posting" := true;
        InventorySetup."Automatic Cost Adjustment" := InventorySetup."Automatic Cost Adjustment"::Always;
        InventorySetup."Average Cost Calc. Type" := InventorySetup."Average Cost Calc. Type"::"Item & Location & Variant";
        InventorySetup."Average Cost Period" := InventorySetup."Average Cost Period"::Day;
        InventorySetup."Combined MPS/MRP Calculation" := true;
        Evaluate(InventorySetup."Default Safety Lead Time", '<1D>');
        InventorySetup."Current Demand Forecast" := Format(DemoDataSetup."Starting Year" + 1);
        // NAVCZ
        InventorySetup."Def.Tmpl. for Phys.Pos.Adj CZL" := CreateInvtMovementTemplate.GetSurplusCode();
        InventorySetup."Def.Tmpl. for Phys.Neg.Adj CZL" := CreateInvtMovementTemplate.GetDeficiencyCode();
        // NAVCZ
        InventorySetup.Modify();
    end;
}

