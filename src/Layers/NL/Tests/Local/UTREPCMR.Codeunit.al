codeunit 144041 "UT REP CMR"
{
    // 1. Purpose of test is to validate Sales Shipment Header - OnAfterGetRecord with Location for report 11401 CMR - Sales Shipment.
    // 2. Purpose of test is to validate Sales Shipment Line - OnAfterGetRecord without Location for report 11401 CMR - Sales Shipment.
    // 3. Purpose of test is to validate Transfer Shipment Header - OnAfterGetRecord with Transfer From code for report 11402 CMR - Transfer Shipment.
    // 4. Purpose of test is to validate Transfer Shipment Line - OnAfterGetRecord without Transfer From code for report 11402 CMR - Transfer Shipment.
    // 5. Purpose of test is to validate Return Shipment Header - OnAfterGetRecord with Location for report 11401 CMR - Sales Shipment.
    // 6. Purpose of test is to validate Return Shipment Line - OnAfterGetRecord without Location for report 11410 CMR - Return Shipment.
    // 
    // Covers Test Cases for WI - 342036
    // --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                TFS ID
    // --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    // OnAfterGetRecordSalesShipmentHeaderCMRSalesShipment,OnAfterGetRecordSalesShipmentLineCMRSalesShipment             151254,151255,151256,151257,151258,151259,151260,151261
    // OnAfterGetRecordTransferShipmentHeaderCMRTransferShipment,OnAfterGetRecordTransferShipmentLineCMRTransferShipment 151487,151488,151489,151490,151491,151492,151493,151494,151968
    // OnAfterGetRecordReturnShipmentHeaderCMRReturnShipment,OnAfterGetRecordReturnShipmentLineCMRReturnShipment

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        SalesUnitsPerParcelLbl: Label 'Sales_Shipment_Line__Units_per_Parcel_';
        TransferUnitsPerParcelLbl: Label 'Transfer_Shipment_Line__Units_per_Parcel_';
        ReturnUnitsPerParcelLbl: Label 'Return_Shipment_Line__Units_per_Parcel_';

    [Test]
    [HandlerFunctions('CMRSalesShipmentRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordSalesShipmentHeaderCMRSalesShipment()
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        // Purpose of test is to validate Sales Shipment Header - OnAfterGetRecord with Location for report 11401 CMR - Sales Shipment.
        Initialize();
        CMRWithSalesShipment(SalesShipmentLine, CreateLocation(), LibraryRandom.RandDec(10, 2));  // Use Random for Units Per Parcel.

        // Verify: Verify Units Per Parcel on Report CMR - Sales Shipment.
        LibraryReportDataset.AssertElementWithValueExists(
          SalesUnitsPerParcelLbl, Round(SalesShipmentLine.Quantity / SalesShipmentLine."Units per Parcel", 1, '>'));
    end;

    [Test]
    [HandlerFunctions('CMRSalesShipmentRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordSalesShipmentLineCMRSalesShipment()
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        // Purpose of test is to validate Sales Shipment Line - OnAfterGetRecord without Location for report 11401 CMR - Sales Shipment.
        Initialize();
        CMRWithSalesShipment(SalesShipmentLine, '', 0);  // Use Blank for Location and 0 for Units Per Parcel.

        // Verify: Verify Units Per Parcel on Report CMR - Sales Shipment.
        LibraryReportDataset.AssertElementWithValueExists(SalesUnitsPerParcelLbl, SalesShipmentLine.Quantity);
    end;

    local procedure CMRWithSalesShipment(var SalesShipmentLine: Record "Sales Shipment Line"; LocationCode: Code[10]; UnitsPerParcel: Decimal)
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        // Setup.
        CreateSalesShipment(SalesShipmentHeader, LocationCode, UnitsPerParcel);
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        SalesShipmentLine.FindFirst();
        LibraryVariableStorage.Enqueue(SalesShipmentHeader."No.");  // Required inside CMRSalesShipmentRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"CMR - Sales Shipment");  // Opens CMRSalesShipmentRequestPageHandler.

        // Verify: Verify Ship To, Ship-to Address and Document No. on Report CMR - Sales Shipment.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ShipTo', SalesShipmentHeader."Ship-to City");
        LibraryReportDataset.AssertElementWithValueExists('ShipToAddr_1_', SalesShipmentHeader."Ship-to Name");
        LibraryReportDataset.AssertElementWithValueExists('Sales_Shipment_Line_Document_No_', SalesShipmentHeader."No.");
    end;

    [Test]
    [HandlerFunctions('CMRTransferShipmentRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordTransferShipmentHeaderCMRTransferShipment()
    var
        TransferShipmentLine: Record "Transfer Shipment Line";
    begin
        // Purpose of test is to validate Transfer Shipment Header - OnAfterGetRecord with Location for report 11402 CMR - Transfer Shipment.
        Initialize();
        CMRWithTransferShipment(TransferShipmentLine, CreateLocation(), LibraryRandom.RandDec(10, 2));  // Use Random for Units Per Parcel.

        // Verify: Verify Units Per Parcel on Report CMR - Transfer Shipment.
        LibraryReportDataset.AssertElementWithValueExists(
          TransferUnitsPerParcelLbl, Round(TransferShipmentLine.Quantity / TransferShipmentLine."Units per Parcel", 1, '>'));
    end;

    [Test]
    [HandlerFunctions('CMRTransferShipmentRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordTransferShipmentLineCMRTransferShipment()
    var
        TransferShipmentLine: Record "Transfer Shipment Line";
    begin
        // Purpose of test is to validate Transfer Shipment Line - OnAfterGetRecord without Location for report 11402 CMR - Transfer Shipment.
        Initialize();
        CMRWithTransferShipment(TransferShipmentLine, '', 0);  // Use Blank for Location and 0 for Units Per Parcel.

        // Verify: Verify Units Per Parcel on Report CMR - Transfer Shipment.
        LibraryReportDataset.AssertElementWithValueExists(TransferUnitsPerParcelLbl, TransferShipmentLine.Quantity);
    end;

    local procedure CMRWithTransferShipment(var TransferShipmentLine: Record "Transfer Shipment Line"; LocationCode: Code[10]; UnitsPerParcel: Decimal)
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
    begin
        // Setup.
        CreateTransferShipment(TransferShipmentHeader, LocationCode, UnitsPerParcel);
        TransferShipmentLine.SetRange("Document No.", TransferShipmentHeader."No.");
        TransferShipmentLine.FindFirst();
        LibraryVariableStorage.Enqueue(TransferShipmentHeader."No.");  // Required inside CMRTransferShipmentRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"CMR - Transfer Shipment");  // Opens CMRTransferShipmentRequestPageHandler.

        // Verify: Verify Transfer-from City, Transfer-from Address, Transfer-to City and Document No. On Report CMR - Transfer Shipment.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TransferFrom', TransferShipmentHeader."Transfer-from City");
        LibraryReportDataset.AssertElementWithValueExists('FromAddr_1_', TransferShipmentHeader."Transfer-from Name");
        LibraryReportDataset.AssertElementWithValueExists('TransferTo', TransferShipmentHeader."Transfer-to City");
        LibraryReportDataset.AssertElementWithValueExists('Transfer_Shipment_Line_Document_No_', TransferShipmentHeader."No.");
    end;

    [Test]
    [HandlerFunctions('CMRReturnShipmentRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordReturnShipmentHeaderCMRReturnShipment()
    var
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        // Purpose of test is to validate Return Shipment Header - OnAfterGetRecord with Location for report 11410 CMR - Return Shipment.
        Initialize();
        CMRWithReturnShipment(ReturnShipmentLine, CreateLocation(), LibraryRandom.RandDec(10, 2));  // Use Random for Units Per Parcel.

        // Verify: Verify Units Per Parcel on Report CMR - Return Shipment.
        LibraryReportDataset.AssertElementWithValueExists(
          ReturnUnitsPerParcelLbl, Round(ReturnShipmentLine.Quantity / ReturnShipmentLine."Units per Parcel", 1, '>'));
    end;

    [Test]
    [HandlerFunctions('CMRReturnShipmentRequestPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnAfterGetRecordReturnShipmentLineCMRReturnShipment()
    var
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        // Purpose of test is to validate Sales Shipment Line - OnAfterGetRecord without Location for report 11401 CMR - Sales Shipment.
        Initialize();
        CMRWithReturnShipment(ReturnShipmentLine, '', 0);  // Use Blank for Location and 0 for Units Per Parcel.

        // Verify: Verify Units Per Parcel on Report CMR - Sales Shipment.
        LibraryReportDataset.AssertElementWithValueExists(ReturnUnitsPerParcelLbl, ReturnShipmentLine.Quantity);
    end;

    local procedure CMRWithReturnShipment(var ReturnShipmentLine: Record "Return Shipment Line"; LocationCode: Code[10]; UnitsPerParcel: Decimal)
    var
        ReturnShipmentHeader: Record "Return Shipment Header";
    begin
        // Setup.
        CreateReturnShipment(ReturnShipmentHeader, LocationCode, UnitsPerParcel);
        ReturnShipmentLine.SetRange("Document No.", ReturnShipmentHeader."No.");
        ReturnShipmentLine.FindFirst();
        LibraryVariableStorage.Enqueue(ReturnShipmentHeader."No.");  // Required inside CMRReturnShipmentRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"CMR - Return Shipment");  // Opens CMRReturnShipmentRequestPageHandler.

        // Verify: Verify Ship To, Ship-to Address and Document No. on Report CMR - Return Shipment.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ShipTo', ReturnShipmentHeader."Ship-to City");
        LibraryReportDataset.AssertElementWithValueExists('ShipToAddr_1_', ReturnShipmentHeader."Ship-to Name");
        LibraryReportDataset.AssertElementWithValueExists('Return_Shipment_Line_Document_No_', ReturnShipmentHeader."No.");
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        Item."No." := LibraryUTUtility.GetNewCode();
        Item.Insert();
        exit(Item."No.");
    end;

    local procedure CreateLocation(): Code[10]
    var
        Location: Record Location;
    begin
        Location.Code := LibraryUTUtility.GetNewCode10();
        Location.Insert();
        exit(Location.Code);
    end;

    local procedure CreateSalesShipment(var SalesShipmentHeader: Record "Sales Shipment Header"; LocationCode: Code[10]; UnitsPerParcel: Decimal)
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentHeader."No." := LibraryUTUtility.GetNewCode();
        SalesShipmentHeader."Location Code" := LocationCode;
        SalesShipmentHeader."Sell-to Address" := LibraryUTUtility.GetNewCode();
        SalesShipmentHeader."Sell-to City" := SalesShipmentHeader."Sell-to Address";
        SalesShipmentHeader."Sell-to Post Code" := SalesShipmentHeader."Sell-to Address";
        SalesShipmentHeader."Ship-to Name" := SalesShipmentHeader."Sell-to Address";
        SalesShipmentHeader."Ship-to Address" := SalesShipmentHeader."Sell-to Address";
        SalesShipmentHeader."Ship-to City" := SalesShipmentHeader."Sell-to Address";
        SalesShipmentHeader.Insert();
        SalesShipmentLine."Document No." := SalesShipmentHeader."No.";
        SalesShipmentLine.Type := SalesShipmentLine.Type::Item;
        SalesShipmentLine."No." := CreateItem();
        SalesShipmentLine."Units per Parcel" := UnitsPerParcel;
        SalesShipmentLine.Quantity := LibraryRandom.RandDec(10, 2);  // Use Random For Quantity.
        SalesShipmentLine.Insert();
    end;

    local procedure CreateTransferShipment(var TransferShipmentHeader: Record "Transfer Shipment Header"; TransferFromCode: Code[10]; UnitsPerParcel: Decimal)
    var
        TransferShipmentLine: Record "Transfer Shipment Line";
    begin
        TransferShipmentHeader."No." := LibraryUTUtility.GetNewCode();
        TransferShipmentHeader."Transfer-from Code" := TransferFromCode;
        TransferShipmentHeader."Transfer-from Name" := TransferShipmentHeader."Transfer-from Name";
        TransferShipmentHeader."Transfer-from Address" := TransferShipmentHeader."Transfer-from Name";
        TransferShipmentHeader."Transfer-from Post Code" := TransferShipmentHeader."Transfer-from Name";
        TransferShipmentHeader."Transfer-from City" := TransferShipmentHeader."Transfer-from Name";
        TransferShipmentHeader."Transfer-to Code" := CreateLocation();
        TransferShipmentHeader."Transfer-to City" := TransferShipmentHeader."Transfer-from Name";
        TransferShipmentHeader.Insert();
        TransferShipmentLine."Document No." := TransferShipmentHeader."No.";
        TransferShipmentLine."Item No." := CreateItem();
        TransferShipmentLine."Units per Parcel" := UnitsPerParcel;
        TransferShipmentLine.Quantity := LibraryRandom.RandDec(10, 2);  // Use Random For Quantity.
        TransferShipmentLine.Insert();
    end;

    local procedure CreateReturnShipment(var ReturnShipmentHeader: Record "Return Shipment Header"; LocationCode: Code[10]; UnitsPerParcel: Decimal)
    var
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        ReturnShipmentHeader."No." := LibraryUTUtility.GetNewCode();
        ReturnShipmentHeader."Location Code" := LocationCode;
        ReturnShipmentHeader."Pay-to Address" := LibraryUTUtility.GetNewCode();
        ReturnShipmentHeader."Pay-to City" := LibraryUTUtility.GetNewCode();
        ReturnShipmentHeader."Pay-to Post Code" := LibraryUTUtility.GetNewCode();
        ReturnShipmentHeader."Ship-to Name" := LibraryUTUtility.GetNewCode();
        ReturnShipmentHeader."Ship-to Address" := LibraryUTUtility.GetNewCode();
        ReturnShipmentHeader."Ship-to City" := LibraryUTUtility.GetNewCode();
        ReturnShipmentHeader.Insert();
        ReturnShipmentLine."Document No." := ReturnShipmentHeader."No.";
        ReturnShipmentLine.Type := ReturnShipmentLine.Type::Item;
        ReturnShipmentLine."No." := CreateItem();
        ReturnShipmentLine."Units per Parcel" := UnitsPerParcel;
        ReturnShipmentLine.Quantity := LibraryRandom.RandDec(10, 2);  // Use Random For Quantity.
        ReturnShipmentLine.Insert();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CMRSalesShipmentRequestPageHandler(var CMRSalesShipment: TestRequestPage "CMR - Sales Shipment")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        CMRSalesShipment."Sales Shipment Header".SetFilter("No.", No);
        CMRSalesShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CMRTransferShipmentRequestPageHandler(var CMRTransferShipment: TestRequestPage "CMR - Transfer Shipment")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        CMRTransferShipment."Transfer Shipment Header".SetFilter("No.", No);
        CMRTransferShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CMRReturnShipmentRequestPageHandler(var CMRReturnShipment: TestRequestPage "CMR - Return Shipment")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        CMRReturnShipment."Return Shipment Header".SetFilter("No.", No);
        CMRReturnShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

