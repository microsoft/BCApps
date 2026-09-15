codeunit 101313 "Create Inventory Setup"
{

    trigger OnRun()
    var
        ExcelTemplate: Record "Excel Template";
    begin
        DemoDataSetup.Get();
        InventorySetup.Get();
        "Create No. Series".InsertSeriesOnly(InventorySetup."Item Nos.", XINV + '-01', XMaterials, true, false, true);
        "Create No. Series".InsertSeriesLine(InventorySetup."Item Nos.", XMAT, 10000, 0D, 1);
        "Create No. Series".InsertSeriesOnly(InventorySetup."Item Nos.", XINV + '-01-01', XWorkingClothes, true, false, true);
        "Create No. Series".InsertSeriesLine(InventorySetup."Item Nos.", XWCL, 10000, 0D, 1);
        "Create No. Series".InsertSeriesOnly(InventorySetup."Item Nos.", XINV + '-01-02', XWorkingTools, true, false, true);
        "Create No. Series".InsertSeriesLine(InventorySetup."Item Nos.", XWTL, 10000, 0D, 1);
        "Create No. Series".InsertSeriesOnly(InventorySetup."Item Nos.", XINV + '-02', XGoods, true, false, true);
        "Create No. Series".InsertSeriesLine(InventorySetup."Item Nos.", XITE, 10000, 0D, 1);
        "Create No. Series".InsertSeriesOnly(InventorySetup."Item Nos.", XINV + '-02-01', XAssemblyBOM, true, false, true);
        "Create No. Series".InsertSeriesLine(InventorySetup."Item Nos.", XBOM, 10000, 0D, 1);
        "Create No. Series".InsertSeriesOnly(InventorySetup."Item Nos.", XINV + '-02-02', XPackingOfGoodsBOM, true, false, true);
        "Create No. Series".InsertSeriesLine(InventorySetup."Item Nos.", XKIT, 10000, 0D, 1);
        "Create No. Series".InsertSeriesOnly(InventorySetup."Item Nos.", XINV + '-02-03', XDetailsInPackingGoods, true, false, true);
        "Create No. Series".InsertSeriesLine(InventorySetup."Item Nos.", XDET, 10000, 0D, 1);
        "Create No. Series".InsertSeriesOnly(InventorySetup."Nonstock Item Nos.", XINV + '-08', XNonStockItems, true, false, true);
        "Create No. Series".InsertSeriesLine(InventorySetup."Nonstock Item Nos.", XNSI, 10000, 0D, 1);
        "Create No. Series".InsertSeriesOnly(InventorySetup."Item Nos.", XINV + '-04', XOwnGoods, true, false, true);
        "Create No. Series".InsertSeriesLine(InventorySetup."Item Nos.", XOWG, 10000, 0D, 1);
        "Create No. Series".InsertSeriesOnly(InventorySetup."Item Nos.", XINV + '-03', XFinishedGoods, true, false, true);
        "Create No. Series".InsertSeriesLine(InventorySetup."Item Nos.", XFIG, 10000, 0D, 1);
        "Create No. Series".InsertSeriesOnly(InventorySetup."Item Nos.", XINV + '-06', XPackage, true, false, true);
        "Create No. Series".InsertSeriesLine(InventorySetup."Item Nos.", XPAC, 10000, 0D, 1);
        "Create No. Series".InsertSeriesOnly(InventorySetup."Item Nos.", XINV + '-07', XEquipmentforinstallation, true, false, true);
        "Create No. Series".InsertSeriesLine(InventorySetup."Item Nos.", XEQT, 10000, 19020101D, 1);
        "Create No. Series".InsertSeriesLine(InventorySetup."Item Nos.", XEQT, 20000, 19030101D, 1);
        "Create No. Series".InsertSeriesOnly(InventorySetup."Item Nos.", XINV + '-09', XOtherGoods, true, false, true);
        "Create No. Series".InsertSeriesLine(InventorySetup."Item Nos.", XOTG, 10000, 0D, 1);

        InventorySetup."Item Nos." := XINV + '-01';
        InventorySetup."Nonstock Item Nos." := XINV + '-08';
        "Create No. Series".InsertRelation(XINV + '-01', XINV + '-01-01');
        "Create No. Series".InsertRelation(XINV + '-01', XINV + '-01-02');
        "Create No. Series".InsertRelation(XINV + '-01', XINV + '-02');
        "Create No. Series".InsertRelation(XINV + '-01', XINV + '-02-01');
        "Create No. Series".InsertRelation(XINV + '-01', XINV + '-02-02');
        "Create No. Series".InsertRelation(XINV + '-01', XINV + '-02-03');
        "Create No. Series".InsertRelation(XINV + '-01', XINV + '-03');
        "Create No. Series".InsertRelation(XINV + '-01', XINV + '-04');
        "Create No. Series".InsertRelation(XINV + '-01', XINV + '-06');
        "Create No. Series".InsertRelation(XINV + '-01', XINV + '-07');
        "Create No. Series".InsertRelation(XINV + '-01', XINV + '-09');

        "Create No. Series".InsertSeriesOnly(InventorySetup."Transfer Order Nos.", XINV + '-12', XTransferOrder, true, false, true);
        "Create No. Series".InsertSeriesLine(InventorySetup."Transfer Order Nos.", XTORD, 10000, 19020101D, 1);
        "Create No. Series".InsertSeriesLine(InventorySetup."Transfer Order Nos.", XTORD, 20000, 19030101D, 1);
        "Create No. Series".InsertSeriesOnly(InventorySetup."Posted Transfer Shpt. Nos.", XINV + '-13-01', XTransferShipment, true, false, false);
        "Create No. Series".InsertSeriesLine(InventorySetup."Posted Transfer Shpt. Nos.", XTSHPT, 10000, 19020101D, 1);
        "Create No. Series".InsertSeriesLine(InventorySetup."Posted Transfer Shpt. Nos.", XTSHPT, 20000, 19030101D, 1);
        "Create No. Series".InsertSeriesOnly(InventorySetup."Posted Transfer Rcpt. Nos.", XINV + '-13-02', XTransferReceipt, true, false, false);
        "Create No. Series".InsertSeriesLine(InventorySetup."Posted Transfer Rcpt. Nos.", XTRCPT, 10000, 19020101D, 1);
        "Create No. Series".InsertSeriesLine(InventorySetup."Posted Transfer Rcpt. Nos.", XTRCPT, 20000, 19030101D, 1);
        "Create No. Series".InitBaseSeries(
          InventorySetup."Posted Direct Trans. Nos.", XDirectTrans, XPostedDirectTransfer, XPDT000001, XPDT999999, '', '', 1);

        "Create No. Series".InsertSeriesOnly(InventorySetup."Inventory Pick Nos.", XINV + '-16', XInventoryPick, true, false, true);
        "Create No. Series".InsertSeriesLine(InventorySetup."Inventory Pick Nos.", XIPick, 10000, 0D, 1);

        "Create No. Series".InsertSeriesOnly(InventorySetup."Posted Invt. Pick Nos.", XINV + '-17', XPostedInvtPick, true, false, true);
        "Create No. Series".InsertSeriesLine(InventorySetup."Posted Invt. Pick Nos.", XIPickPLUS, 10000, 0D, 1);
        "Create No. Series".InsertSeriesOnly(InventorySetup."Inventory Put-away Nos.", XINV + '-18', XInventoryPutaway, true, false, true);
        "Create No. Series".InsertSeriesLine(InventorySetup."Inventory Put-away Nos.", XIPut, 10000, 0D, 1);
        "Create No. Series".InsertSeriesOnly(InventorySetup."Posted Invt. Put-away Nos.", XINV + '-19', XPostedInvtPutaway, true, false, true);
        "Create No. Series".InsertSeriesLine(InventorySetup."Posted Invt. Put-away Nos.", XIPutPLUS, 10000, 0D, 1);

        "Create No. Series".InsertSeriesOnly(InventorySetup."Inventory Movement Nos.", XINV + '-20', XRegisteredInvtMovement, true, false, true);
        "Create No. Series".InsertSeriesLine(InventorySetup."Inventory Movement Nos.", XIM, 10000, 0D, 1);
        "Create No. Series".InsertSeriesOnly(InventorySetup."Registered Invt. Movement Nos.", XINV + '-21', XRegisteredInvtMovement, true, false, true);
        "Create No. Series".InsertSeriesLine(InventorySetup."Registered Invt. Movement Nos.", XRIM, 10000, 0D, 1);
        "Create No. Series".InsertSeriesOnly(InventorySetup."Internal Movement Nos.", XINV + '-22', XInternalMovement, true, false, true);
        "Create No. Series".InsertSeriesLine(InventorySetup."Internal Movement Nos.", XINTM, 10000, 0D, 1);

        "Create No. Series".InsertSeriesOnly(InventorySetup."Invt. Receipt Nos.", XINV + '-10', XItemReceiptAct, true, false, true);
        "Create No. Series".InsertSeriesLine(InventorySetup."Invt. Receipt Nos.", XIRCPT, 10000, 19020101D, 1);
        "Create No. Series".InsertSeriesLine(InventorySetup."Invt. Receipt Nos.", XIRCPT, 20000, 19030101D, 1);
        "Create No. Series".InsertSeriesOnly(InventorySetup."Posted Invt. Receipt Nos.", XINV + '-11', XPostedItemReceiptAct, true, false, true);
        "Create No. Series".InsertSeriesLine(InventorySetup."Posted Invt. Receipt Nos.", XIRCPTPlus, 10000, 19020101D, 1);
        "Create No. Series".InsertSeriesLine(InventorySetup."Posted Invt. Receipt Nos.", XIRCPTPlus, 20000, 19030101D, 1);

        "Create No. Series".InsertSeriesOnly(InventorySetup."Invt. Shipment Nos.", XINV + '-14', XItemShipmentAct, true, false, true);
        "Create No. Series".InsertSeriesLine(InventorySetup."Invt. Shipment Nos.", XISHIP, 10000, 19020101D, 1);
        "Create No. Series".InsertSeriesLine(InventorySetup."Invt. Shipment Nos.", XISHIP, 20000, 19030101D, 1);
        "Create No. Series".InsertSeriesOnly(InventorySetup."Posted Invt. Shipment Nos.", XINV + '-15', XPostedItemShipmentAct, true, false, false);
        "Create No. Series".InsertSeriesLine(InventorySetup."Posted Invt. Shipment Nos.", XISHIPPlus, 10000, 19020101D, 1);
        "Create No. Series".InsertSeriesLine(InventorySetup."Posted Invt. Shipment Nos.", XISHIPPlus, 20000, 19030101D, 1);

        InventorySetup."Copy Comments Order to Shpt." := true;
        InventorySetup."Copy Comments Order to Rcpt." := true;
        InventorySetup."Copy Comments to Item Doc." := true;
        InventorySetup."Prevent Negative Inventory" := false;
        InventorySetup."Adjmt. Rounding as Correction" := true;
        InventorySetup."Unit of Measure Mandatory" := true;
        InventorySetup."Automatic Cost Posting" := true;
        InventorySetup."Allow Invt. Doc. Reservation" := true;

        InventorySetup."Waybill 1-T Template Code" := XTTN1T;
        ExcelTemplate.InsertTemplate(XTTN1T, XWaybill1T, 'LocalFiles\RU_WMSBOL_1T.xlsx');
        InventorySetup."TORG-13 Template Code" := XTORG13;
        ExcelTemplate.InsertTemplate(XTORG13, XShipmentTORG13, 'LocalFiles\TORG_13.xlsx');

        InventorySetup."Shpt.Request M-11 Templ. Code" := XM11;
        ExcelTemplate.InsertTemplate(XM11, XM11, 'LocalFiles\M-11.xlsx');
        InventorySetup."TORG-16 Template Code" := XTORG16;
        ExcelTemplate.InsertTemplate(XTORG16, XTORG16, 'LocalFiles\TORG-16.xlsx');
        InventorySetup."INV-17 Template Code" := XINV17;
        ExcelTemplate.InsertTemplate(XINV17, XINV17, 'LocalFiles\INV-17.xlsx');
        InventorySetup."INV-17 Appendix Template Code" := XINV17APP;
        ExcelTemplate.InsertTemplate(XINV17APP, XINV17APP, 'LocalFiles\INV-17 appendix.xlsx');
        InventorySetup."Item Card M-17 Template Code" := XM17;
        ExcelTemplate.InsertTemplate(XM17, XM17, 'LocalFiles\M-17.xlsx');
        InventorySetup."Phys.Inv. INV-3 Template Code" := XINV3;
        ExcelTemplate.InsertTemplate(XINV3, XINV3, 'LocalFiles\INV-3.xlsx');
        InventorySetup."Phys.Inv. INV-19 Template Code" := XINV19;
        ExcelTemplate.InsertTemplate(XINV19, XINV19, 'LocalFiles\INV-19.xlsx');
        InventorySetup."TORG-29 Template Code" := XTORG29;
        ExcelTemplate.InsertTemplate(XTORG29, XTORG29, 'LocalFiles\TORG-29.xlsx');

        "Create No. Series".InitBaseSeries(
          InventorySetup."Phys. Invt. Order Nos.", XPHYSINV, XPhysicalInventoryOrder, XPHIO00001, XPHIO99999, '', '', 1);
        "Create No. Series".InitBaseSeries(
          InventorySetup."Posted Phys. Invt. Order Nos.", XPHYSINVPLUS, XPostedPhysInventOrder, XPPHI00001, XPPHI99999, '', '', 1);

        InventorySetup."Combined MPS/MRP Calculation" := true;
        Evaluate(InventorySetup."Default Safety Lead Time", '<1D>');
        InventorySetup."Current Demand Forecast" := Format(DemoDataSetup."Starting Year" + 1);
        InventorySetup.Modify();
    end;

    var
        DemoDataSetup: Record "Demo Data Setup";
        InventorySetup: Record "Inventory Setup";
        "Create No. Series": Codeunit "Create No. Series";
        XITEMTxt: Label 'ITEM', Comment = 'Can be translated.';
        XItemNoSeriesTxt: Label 'Items';
        XAssemblyBOM: Label 'Assembly BOM';
        NonStockNoSeriesTok: Label 'NS-ITEM', Comment = 'Catalog Item Number Series Code';
        XNonStockItems: Label 'Catalog Items';
        NonStockStartingNoTok: Label 'NS0001', Comment = 'Catalog Item Number Series Starting Number';
        NonStockEndingNoTok: Label 'NS0100', Comment = 'Catalog Item Number Series Ending Number';
        XTSHPT: Label 'TS';
        XTransferShipment: Label 'Transfer Shipment';
        XTRCPT: Label 'TR';
        XTransferReceipt: Label 'Transfer Receipt';
        XTORD: Label 'TO';
        XTransferOrder: Label 'Transfer Order';
        XDirectTrans: Label 'PDIRTRANS', Comment = 'Posted Direct Transfer';
        XPostedDirectTransfer: Label 'Posted Direct Transfer';
        XPDT000001: Label 'PDT000001', Comment = 'PDT - Posted Direct Transfer';
        XPDT999999: Label 'PDT999999', Comment = 'PDT - Posted Direct Transfer';
        XIPut: Label 'UIPT';
        XInventoryPutaway: Label 'Unposted Inventory Put-away';
        XIPick: Label 'UIPK';
        XInventoryPick: Label 'Unposted Inventory Pick';
        XIPutPLUS: Label 'IPT';
        XPostedInvtPutaway: Label 'Posted Invt. Put-away';
        XIPickPLUS: Label 'IPK';
        XPostedInvtPick: Label 'Posted Invt. Pick';
        NonStockLastUsedNoTok: Label 'NS0000', Comment = 'NonStock Item Number Series Last Used Number';
        NonStockWarningNoTok: Label 'NS0095', Comment = 'NonStock Item Number Series Warning Number';
        XRegisteredInvtMovement: Label 'Registered Invt. Movement';
        XInternalMovement: Label 'Internal Movement';
        XPHYSINV: Label 'PHYS-INV', Comment = 'Physical Inventory Order';
        XPhysicalInventoryOrder: Label 'Physical Inventory Order';
        XPHYSINVPLUS: Label 'PHYS-INV+', Comment = 'Physical Inventory Order';
        XPostedPhysInventOrder: Label 'Posted Phys. Invent. Order';
        XPHIO00001: Label 'PHIO00001', Comment = 'Physical Inventory Order';
        XPHIO99999: Label 'PHIO99999', Comment = 'Physical Inventory Order';
        XPPHI00001: Label 'PPHI00001', Comment = 'Posted Physical Inventory Order';
        XPPHI99999: Label 'PPHI99999', Comment = 'Posted Physical Inventory Order';
        XIRCPT: Label 'UIRA';
        XItemReceiptAct: Label 'Unposted Item Receipt Act';
        XISHIP: Label 'UISA';
        XItemShipmentAct: Label 'Unposted Item Shipment Act';
        XIRCPTPlus: Label 'IRA';
        XPostedItemReceiptAct: Label 'Posted Item Receipt Act';
        XISHIPPlus: Label 'ISA';
        XPostedItemShipmentAct: Label 'Posted Item Shipment Act';
        XMaterials: Label 'Materials';
        XMAT: Label 'MAT';
        XGoods: Label 'Goods';
        XITE: Label 'ITE';
        XWorkingClothes: Label 'Working Clothes';
        XWCL: Label 'WCL';
        XWorkingTools: Label 'Working Tools';
        XWTL: Label 'WTL';
        XOwnGoods: Label 'Own Goods';
        XOWG: Label 'OWG';
        XFinishedGoods: Label 'Finished Goods';
        XFIG: Label 'FIG';
        XOtherGoods: Label 'Other Goods';
        XOTG: Label 'OTG';
        XINV: Label 'INV';
        XBOM: Label 'BOM';
        XNSI: Label 'NSI';
        XPackage: Label 'Package';
        XPAC: Label 'PAC';
        XDET: Label 'DET';
        XKIT: Label 'KIT';
        XEquipmentforinstallation: Label 'Equipment for installation';
        XEQT: Label 'EQT';
        XPackingOfGoodsBOM: Label 'Packing of goods (BOM)';
        XDetailsInPackingGoods: Label 'Details in pack. goods';
        XRIM: Label 'RIM';
        XINTM: Label 'INTM';
        XIM: Label 'IM';
        XTTN1T: Label 'TTN-1T';
        XWaybill1T: Label 'WayBill 1-T';
        XTORG13: Label 'TORG13';
        XShipmentTORG13: Label 'XShipment TORG-13';
        XM11: Label 'M-11';
        XTORG16: Label 'TORG-16';
        XINV17: Label 'INV-17';
        XINV17APP: Label 'INV-17 app';
        XM17: Label 'M-17';
        XINV3: Label 'INV-3';
        XINV19: Label 'INV-19';
        XTORG29: Label 'TORG-29';

    procedure InsertMiniAppData()
    begin
        DemoDataSetup.Get();
        InventorySetup.Get();
        "Create No. Series".InitBaseSeries(InventorySetup."Item Nos.", XITEMTxt, XItemNoSeriesTxt, '1000', '9999', '', '9995', 1, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitBaseSeries(InventorySetup."Nonstock Item Nos.", NonStockNoSeriesTok, XNonStockItems, NonStockStartingNoTok,
          NonStockEndingNoTok, NonStockLastUsedNoTok, NonStockWarningNoTok, 1, Enum::"No. Series Implementation"::Sequence);
        "Create No. Series".InitFinalSeries(InventorySetup."Posted Transfer Shpt. Nos.", XTSHPT, XTransferShipment, 8);
        "Create No. Series".InitFinalSeries(InventorySetup."Posted Transfer Rcpt. Nos.", XTRCPT, XTransferReceipt, 9);
        "Create No. Series".InitTempSeries(InventorySetup."Transfer Order Nos.", XTORD, XTransferOrder);
        "Create No. Series".InitBaseSeries(
          InventorySetup."Posted Direct Trans. Nos.", XDirectTrans, XPostedDirectTransfer, XPDT000001, XPDT999999, '', '', 1);
        "Create No. Series".InitBaseSeries(
          InventorySetup."Phys. Invt. Order Nos.", XPHYSINV, XPhysicalInventoryOrder, XPHIO00001, XPHIO99999, '', '', 1);
        "Create No. Series".InitBaseSeries(
          InventorySetup."Posted Phys. Invt. Order Nos.", XPHYSINVPLUS, XPostedPhysInventOrder, XPPHI00001, XPPHI99999, '', '', 1);
        "Create No. Series".InsertSeriesOnly(InventorySetup."Invt. Receipt Nos.", XINV + '-10', XItemReceiptAct, true, false, true);
        "Create No. Series".InsertSeriesLine(InventorySetup."Invt. Receipt Nos.", XIRCPT, 10000, 19020101D, 1);
        "Create No. Series".InsertSeriesLine(InventorySetup."Invt. Receipt Nos.", XIRCPT, 20000, 19030101D, 1);
        "Create No. Series".InsertSeriesOnly(InventorySetup."Posted Invt. Receipt Nos.", XINV + '-11', XPostedItemReceiptAct, true, false, true);
        "Create No. Series".InsertSeriesLine(InventorySetup."Posted Invt. Receipt Nos.", XIRCPTPlus, 10000, 19020101D, 1);
        "Create No. Series".InsertSeriesLine(InventorySetup."Posted Invt. Receipt Nos.", XIRCPTPlus, 20000, 19030101D, 1);

        "Create No. Series".InsertSeriesOnly(InventorySetup."Invt. Shipment Nos.", XINV + '-14', XItemShipmentAct, true, false, true);
        "Create No. Series".InsertSeriesLine(InventorySetup."Invt. Shipment Nos.", XISHIP, 10000, 19020101D, 1);
        "Create No. Series".InsertSeriesLine(InventorySetup."Invt. Shipment Nos.", XISHIP, 20000, 19030101D, 1);
        "Create No. Series".InsertSeriesOnly(InventorySetup."Posted Invt. Shipment Nos.", XINV + '-15', XPostedItemShipmentAct, true, false, false);
        "Create No. Series".InsertSeriesLine(InventorySetup."Posted Invt. Shipment Nos.", XISHIPPlus, 10000, 19020101D, 1);
        "Create No. Series".InsertSeriesLine(InventorySetup."Posted Invt. Shipment Nos.", XISHIPPlus, 20000, 19030101D, 1);
        InventorySetup."Automatic Cost Posting" := true;
        InventorySetup."Automatic Cost Adjustment" := InventorySetup."Automatic Cost Adjustment"::Always;
        InventorySetup."Average Cost Calc. Type" := InventorySetup."Average Cost Calc. Type"::"Item & Location & Variant";
        InventorySetup."Average Cost Period" := InventorySetup."Average Cost Period"::Day;
        InventorySetup."Combined MPS/MRP Calculation" := true;
        Evaluate(InventorySetup."Default Safety Lead Time", '<1D>');
        InventorySetup."Current Demand Forecast" := Format(DemoDataSetup."Starting Year" + 1);
        InventorySetup.Modify();
    end;
}

