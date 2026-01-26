#if not CLEAN27
#pragma warning disable AL0801
codeunit 144082 "UT Subcontracting"
{
    // 1. Purpose of the test is to validate Prod. Order Component - OnPreDataItem Trigger of Report - 12155 Subcontr. Dispatching List.
    // 2. Purpose of the test is to validate Transfer Shipment Header - OnPreDataItem Trigger of Report - 12154 Subcontract. Transfer Shipment.
    // 3. Purpose of the test is to validate Transfer Shipment Header - OnAfterGetRecord Trigger of Report - 12154 Subcontract. Transfer Shipment.
    // 4. Purpose of the test is to validate Item - OnAfterGetRecord Trigger of Report - 99000756 Detailed Calculation.
    // 5. Purpose of the test is to validate Routing Line - OnAfterGetRecord Trigger of Report - 99000756 Detailed Calculation.
    // 
    // Covers Test Cases for WI - 347118
    // ------------------------------------------------------------------------------
    // Test Function Name                                                      TFS ID
    // ------------------------------------------------------------------------------
    // OnPreDataItemProdOrderCompSubcontrDispatchingList                       155592
    // OnPreDataItemTransShptHdrSubcontractTransShpt                           155673
    // OnAfterGetRecordTransShptHdrSubcontractTransShpt                        238899
    // OnAfterGetRecordItemDetailedCalculation                                 238922
    // OnAfterGetRecordRoutingLineDetailedCalculation                          154754

    Subtype = Test;
    TestPermissions = Disabled;
    ObsoleteReason = 'Preparation for replacement by Subcontracting app';
    ObsoleteState = Pending;
    ObsoleteTag = '27.0';

    trigger OnRun()
    begin
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        CompanyTextCap: Label 'CompanyText_2_';
        CompanyInfoCap: Label '%1 %2  ';
        LablVendorCap: Label 'LablVendor';
        MessrsTxt: Label 'Messrs.';
        NoItemCap: Label 'No_Item';
        ProductionBOMNoItemCap: Label 'ProductionBOMNo_Item';
        ProdOrderCap: Label '%1 %2';
        ProdOrderNoCap: Label 'Purchase_Line_Prod__Order_No_';
        RefProdOrdCap: Label 'RefProdOrd';
        RoutingNoItemCap: Label 'RoutingNo_Item';
        RoutingNoCap: Label 'Purchase_Line_Routing_No_';
        TransferShipmentHdrNoCap: Label 'Transfer_Shipment_Header_No_';
        VendorNoCap: Label 'Vendor__No__';

    [Test]
    [HandlerFunctions('SubcontrDispatchingListRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemProdOrderCompSubcontrDispatchingList()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Purpose of the test is to validate Prod. Order Component - OnPreDataItem Trigger of Report - 12155 Subcontr. Dispatching List.

        // Setup: Create Purchase Line with Production Order Routing Line.
        Initialize();
        CreatePurchaseLine(PurchaseLine, CreateVendor());
        CreateProdOrderRoutingLine(PurchaseLine);
        LibraryVariableStorage.Enqueue(PurchaseLine."Buy-from Vendor No.");  // Enqueue for SubcontrDispatchingListRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Subcontr. Dispatching List");  // Opens SubcontrDispatchingListRequestPageHandler.

        // Verify: Verify values of Vendor No, Prod Order No, Routing No of Report - 12155 Subcontr. Dispatching List.
        VerifyXMLValuesOnMiscellaneousReports(
          VendorNoCap, ProdOrderNoCap, RoutingNoCap, PurchaseLine."Buy-from Vendor No.", PurchaseLine."Prod. Order No.",
          PurchaseLine."Routing No.");
    end;

    [Test]
    [HandlerFunctions('SubcontractTransferShipmentRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnPreDataItemTransShptHdrSubcontractTransShpt()
    var
        CompanyInformation: Record "Company Information";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        TransferShipmentLine: Record "Transfer Shipment Line";
        No: Code[20];
        ProdOrderNo: Code[20];
    begin
        // Purpose of the test is to validate Transfer Shipment Header - OnPreDataItem Trigger of Report - 12154 Subcontract. Transfer Shipment.

        // Setup: Create Transfer Shipment Line and Update Company Information.
        Initialize();
        UpdateCompanyInformation();
        ProdOrderNo := LibraryUTUtility.GetNewCode();
        No := CreateTransferShipmentLine(TransferShipmentHeader."Source Type"::Vendor, ProdOrderNo, LibraryUTUtility.GetNewCode());
        LibraryVariableStorage.Enqueue(No);  // Enqueue for SubcontractTransferShipmentRequestPageHandler.
        CompanyInformation.Get();

        // Exercise.
        REPORT.Run(REPORT::"Subcontract. Transfer Shipment");  // Opens SubcontractTransferShipmentRequestPageHandler.

        // Verify: Verify values of Transfer Shipment Header No, LablVendor, RefProdOrd of Report - 12154 Subcontract. Transfer Shipment.
        VerifyXMLValuesOnMiscellaneousReports(
          TransferShipmentHdrNoCap, LablVendorCap, RefProdOrdCap, No, StrSubstNo(MessrsTxt), StrSubstNo(
            ProdOrderCap, TransferShipmentLine.FieldCaption("Prod. Order No."), ProdOrderNo));
        LibraryReportDataset.AssertElementWithValueExists(
          CompanyTextCap, StrSubstNo(
            CompanyInfoCap, CompanyInformation.FieldCaption("Register Company No."), CompanyInformation."Register Company No."));
    end;

    [Test]
    [HandlerFunctions('SubcontractTransferShipmentRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordTransShptHdrSubcontractTransShpt()
    var
        CompanyInformation: Record "Company Information";
        TransferShipmentHeader: Record "Transfer Shipment Header";
        No: Code[20];
    begin
        // Purpose of the test is to validate Transfer Shipment Header - OnAfterGetRecord Trigger of Report - 12154 Subcontract. Transfer Shipment.

        // Setup: Create Transfer Shipment Line and Update Company Information.
        Initialize();
        UpdateCompanyInformation();
        No := CreateTransferShipmentLine(TransferShipmentHeader."Source Type", '', '');  // SubcontrPurchOrderNo and ProdOrderNo as blank.
        LibraryVariableStorage.Enqueue(No);  // Enqueue for SubcontractTransferShipmentRequestPageHandler.
        CompanyInformation.Get();

        // Exercise.
        REPORT.Run(REPORT::"Subcontract. Transfer Shipment");  // Opens SubcontractTransferShipmentRequestPageHandler.

        // Verify: Verify values of Transfer Shipment Header No, LablVendor, RefProdOrd of Report - 12154 Subcontract. Transfer Shipment.
        VerifyXMLValuesOnMiscellaneousReports(TransferShipmentHdrNoCap, LablVendorCap, RefProdOrdCap, No, '', '');
        LibraryReportDataset.AssertElementWithValueExists(
          CompanyTextCap, StrSubstNo(
            CompanyInfoCap, CompanyInformation.FieldCaption("Register Company No."), CompanyInformation."Register Company No."));
    end;

    [Test]
    [HandlerFunctions('DetailedCalculationRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordItemDetailedCalculation()
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        // Purpose of the test is to validate Item - OnAfterGetRecord Trigger of Report - 99000756 Detailed Calculation.
        DetailedCalculationWithProductionBOMLine(ProductionBOMLine.Type::Item);
    end;

    [Test]
    [HandlerFunctions('DetailedCalculationRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordRoutingLineDetailedCalculation()
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        // Purpose of the test is to validate Routing Line - OnAfterGetRecord Trigger of Report - 99000756 Detailed Calculation.
        DetailedCalculationWithProductionBOMLine(ProductionBOMLine.Type::"Production BOM");
    end;

    local procedure DetailedCalculationWithProductionBOMLine(Type: Enum "Production BOM Line Type")
    var
        Item: Record Item;
    begin
        // Setup: Create Item and Production BOM Line.
        Initialize();
        CreateItem(Item);
        CreateProductionBOMLine(Item."No.", Item."Production BOM No.", Type);
        LibraryVariableStorage.Enqueue(Item."No.");  // Enqueue for DetailedCalculationRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Detailed Calculation");   // Opens DetailedCalculationRequestPageHandler.

        // Verify: Verify values of Item No, Routing No, Production BOM No of Report - 99000756 Detailed Calculation.
        VerifyXMLValuesOnMiscellaneousReports(
          NoItemCap, RoutingNoItemCap, ProductionBOMNoItemCap, Item."No.", Item."Routing No.", Item."Production BOM No.");
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        Item."No." := LibraryUTUtility.GetNewCode();
        Item."Production BOM No." := CreateProductionBOMHeader();
        Item."Routing No." := CreateRoutingLine();
        Item.Insert();
    end;

    local procedure CreateProductionBOMHeader(): Code[20]
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        ProductionBOMHeader."No." := LibraryUTUtility.GetNewCode();
        ProductionBOMHeader.Insert();
        exit(ProductionBOMHeader."No.");
    end;

    local procedure CreateProductionBOMLine(No: Code[20]; ProductionBOMNo: Code[20]; Type: Enum "Production BOM Line Type")
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        ProductionBOMLine."Production BOM No." := ProductionBOMNo;
        ProductionBOMLine.Type := Type;
        ProductionBOMLine."No." := No;
        ProductionBOMLine.Insert();
    end;

    local procedure CreateProdOrderLine(ProdOrderNo: Code[20]; LineNo: Integer)
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.Status := ProdOrderLine.Status::Released;
        ProdOrderLine."Prod. Order No." := ProdOrderNo;
        ProdOrderLine."Line No." := LineNo;
        ProdOrderLine.Insert();
    end;

    local procedure CreatePurchaseHeader(BuyFromVendorNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Order;
        PurchaseHeader."No." := LibraryUTUtility.GetNewCode();
        PurchaseHeader."Buy-from Vendor No." := BuyFromVendorNo;
        PurchaseHeader.Insert();
        exit(PurchaseHeader."No.");
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; BuyFromVendorNo: Code[20])
    begin
        PurchaseLine."Document Type" := PurchaseLine."Document Type"::Order;
        PurchaseLine."Document No." := CreatePurchaseHeader(BuyFromVendorNo);
        PurchaseLine."Prod. Order No." := CreateProductionOrder();
        PurchaseLine."Buy-from Vendor No." := BuyFromVendorNo;
        PurchaseLine."Routing No." := LibraryUTUtility.GetNewCode();
        PurchaseLine."Prod. Order Line No." := LibraryRandom.RandInt(10);
        PurchaseLine.Insert();
    end;

    local procedure CreateProductionOrder(): Code[20]
    var
        ProductionOrder: Record "Production Order";
    begin
        ProductionOrder.Status := ProductionOrder.Status::Released;
        ProductionOrder."No." := LibraryUTUtility.GetNewCode();
        ProductionOrder.Insert();
        exit(ProductionOrder."No.");
    end;

    local procedure CreateProdOrderRoutingLine(PurchaseLine: Record "Purchase Line")
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        CreateProdOrderLine(PurchaseLine."Prod. Order No.", PurchaseLine."Line No.");
        ProdOrderRoutingLine.Status := ProdOrderRoutingLine.Status::Released;
        ProdOrderRoutingLine."Prod. Order No." := PurchaseLine."Prod. Order No.";
        ProdOrderRoutingLine."Routing No." := PurchaseLine."Routing No.";
        ProdOrderRoutingLine.Insert();
    end;

    local procedure CreateRoutingLine(): Code[20]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine."Routing No." := LibraryUTUtility.GetNewCode();
        RoutingLine.Type := RoutingLine.Type::"Work Center";
        RoutingLine."Work Center No." := CreateWorkCenter();
        RoutingLine.Insert();
        exit(RoutingLine."Routing No.");
    end;

    local procedure CreateTransferShipmentLine(SourceType: Enum "Analysis Source Type"; ProdOrderNo: Code[20]; SubcontrPurchOrderNo: Code[20]): Code[20]
    var
        TransferShipmentLine: Record "Transfer Shipment Line";
    begin
        TransferShipmentLine."Document No." := CreateTransferShipmentHeader(SourceType);
        TransferShipmentLine."Subcontr. Purch. Order No." := SubcontrPurchOrderNo;
        TransferShipmentLine."Prod. Order No." := ProdOrderNo;
        TransferShipmentLine.Quantity := LibraryRandom.RandDec(10, 2);
        TransferShipmentLine.Insert();
        exit(TransferShipmentLine."Document No.");
    end;

    local procedure CreateTransferShipmentHeader(SourceType: Enum "Analysis Source Type"): Code[20]
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
    begin
        TransferShipmentHeader."No." := LibraryUTUtility.GetNewCode();
        TransferShipmentHeader."Source Type" := SourceType;
        TransferShipmentHeader."Source No." := CreateVendor();
        TransferShipmentHeader.Insert();
        exit(TransferShipmentHeader."No.");
    end;

    local procedure CreateWorkCenter(): Code[20]
    var
        WorkCenter: Record "Work Center";
    begin
        WorkCenter."No." := LibraryUTUtility.GetNewCode();
        WorkCenter."Subcontractor No." := LibraryUTUtility.GetNewCode();
        WorkCenter.Insert();
        exit(WorkCenter."No.");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor."No." := LibraryUTUtility.GetNewCode();
        Vendor.Subcontractor := true;
        Vendor.Insert();
        exit(Vendor."No.");
    end;

    local procedure UpdateCompanyInformation()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        CompanyInformation."REA No." := LibraryUTUtility.GetNewCode10();
        CompanyInformation."Register Company No." := LibraryUTUtility.GetNewCode();
        CompanyInformation."Phone No." := LibraryUTUtility.GetNewCode();
        CompanyInformation."Fax No." := LibraryUTUtility.GetNewCode();
        CompanyInformation."E-Mail" := LibraryUTUtility.GetNewCode();
        CompanyInformation."Home Page" := LibraryUTUtility.GetNewCode();
        CompanyInformation.Modify();
    end;

    local procedure VerifyXMLValuesOnMiscellaneousReports(Caption: Text; Caption2: Text; Caption3: Text; Value: Variant; Value2: Variant; Value3: Variant)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(Caption, Value);
        LibraryReportDataset.AssertElementWithValueExists(Caption2, Value2);
        LibraryReportDataset.AssertElementWithValueExists(Caption3, Value3);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DetailedCalculationRequestPageHandler(var DetailedCalculation: TestRequestPage "Detailed Calculation")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        DetailedCalculation.Item.SetFilter("No.", No);
        DetailedCalculation.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SubcontrDispatchingListRequestPageHandler(var SubcontrDispatchingList: TestRequestPage "Subcontr. Dispatching List")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        SubcontrDispatchingList.Vendor.SetFilter("No.", No);
        SubcontrDispatchingList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SubcontractTransferShipmentRequestPageHandler(var SubcontractTransferShipment: TestRequestPage "Subcontract. Transfer Shipment")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        SubcontractTransferShipment."Transfer Shipment Header".SetFilter("No.", No);
        SubcontractTransferShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}
#endif
