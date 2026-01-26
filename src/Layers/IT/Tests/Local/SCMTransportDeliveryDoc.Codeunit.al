codeunit 144101 "SCM Transport Delivery Doc"
{
    // 1.  Test to verify error on Sales Header when Shipping Agent No is blank on Shipping Agent.
    // 2.  Test to verify error on Sales Header when 3rd Party Loader No is blank on Sales Header.
    // 3.  Test to verify error on Sales Header when 3rd Party Loader Type is blank on Sales Header.
    // 4.  Test to verify error after post Sales Order when 3rd Party Loader Type is blank on Sales Header.
    // 5.  Test to verify error after post Sales Order when TDD Prepared By is blank on Sales Header.
    // 6.  Test to verify error on Sales Shipment Header when Shipping Agent No is blank on Shipping Agent.
    // 7.  Test to verify error on Transfer Header when Shipping Agent No is blank on Shipping Agent.
    // 8.  Test to verify error on Transfer Header when 3rd Party Loader No is blank on Transfer Header.
    // 9.  Test to verify values on Sales - Shipment Report after post Sales Order with Additional Information.
    // 10. Test to verify error on Transfer Shipment Report when 3rd Party Loader No. is blank on Transfer Shipment Header.
    // 11. Test to verify values on Purchase - Return Shipment Report after post Purchase Order with Additional Information.
    // 12. Test to verify values on Service - Shipment Report after post Service Order with Additional Information.
    // 13. Test to verify values on Transfer Shipment Report after post Transfer Order with Additional Information.
    // 14. Test to verify error on Sales - Shipment Report when 3rd Party Loader No. is blank on Sales Shipment Header.
    // 15. Test to verify error on Purchase - Return Shipment Report when 3rd Party Loader No. is blank on Return Shipment Header.
    // 16. Test to verify error on Service - Shipment Report when 3rd Party Loader No. is blank on Service Shipment Header.
    // 17. Test to verify error on Return Shipment Header when Shipping Agent Code is blank on Shipping Agent.
    // 18. Test to verify error on Service Shipment Header when Shipping Agent Code is blank on Shipping Agent.
    // 19. Test to verify error on Transfer Shipment Header when Shipping Agent Code is blank on Shipping Agent.
    // 
    // Covers Test Cases for WI - 345128
    // -----------------------------------------------------------------------------
    // Test Function Name                                                     TFS ID
    // -----------------------------------------------------------------------------
    // SalesHeaderWithShippingAgentCodeError                           157355,157356
    // SalesHeaderWithThirdPartyLoaderTypeError                               157354
    // SalesHeaderWithThirdPartyLoaderNoError                          157352,157353
    // SalesOrderWithThirdPartyLoaderTypeError                         157349,157348
    // SalesOrderWithTDDPreparedByError                                157347,157346
    // SalesShipmentHeaderWithShippingAgentCodeError                          157345
    // TransferHeaderWithShippingAgentCodeError                               157344
    // TransferHeaderWithThirdPartyLoaderTypeError                     157343,157342
    // 
    // Covers Test Cases for WI - 345208
    // -----------------------------------------------------------------------------
    // Test Function Name                                                     TFS ID
    // -----------------------------------------------------------------------------
    // SalesShipmentReportWithAdditionalInformation                    157350,157351
    // PurchaseRetShipmentReportWithAdditionalInformation                     157358
    // ServiceShipmentReportWithAdditionalInformation                  157364,157365
    // TransferShipmentReportWithAdditionalInformation                        157363
    // SalesShipmentHeaderWithThirdPartyLoaderError                           157367
    // TransferShipmentHeaderWithThirdPartyLoaderError                        157362
    // ReturnShipmentHeaderWithThirdPartyLoaderError                          157369
    // ServiceShipmentHeaderWithThirdPartyLoaderError                         157370
    // ReturnShipmentHeaderWithShippingAgentCodeError                         157371
    // ServiceShipmentHeaderWithShippingAgentCodeError                        157368
    // TransferShipmentHeaderWithShippingAgentCodeError                       157372

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        PartyLoaderErr: Label '3rd-Party Loader must not be No in Shipment Method Code=''''.';
        ShippingAgentCodeErr: Label ' Shipping Agent Code  must be Vendor/Contact for Shipment Method Code %1 3rd-Party Loader.';
        TDDErr: Label 'TDD Prepared By must have a value in Sales Header: Document Type=%1, No.=%2. It cannot be zero or empty.';
        ThirdPartyLoaderErr: Label '3rd Party Loader Type must not be   in Sales Header: Document Type=%1, No.=%2';
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        ThirdPartyLoaderNoLbl: Label '3rd Party Loader No.';
        ThirdPartyLoaderNoErr: Label '3rd Party Loader No. must have a value in %1: No.=%2. It cannot be zero or empty.';
        ThirdPartyLoaderTypeErr: Label '3rd Party Loader Type must not be   in Transfer Shipment Header: No.=%1';

    [Test]
    [Scope('OnPrem')]
    procedure SalesHeaderWithShippingAgentCodeError()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentCode: Code[10];
    begin
        // Test to verify error on Sales Header when Shipping Agent No is blank on Shipping Agent.
        // Setup.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        ShippingAgentCode := CreateShippingAgent('');  // ShippingAgentNo as blank.

        // Exercise.
        asserterror SalesHeader.Validate("Shipping Agent Code", ShippingAgentCode);

        // Verify.
        Assert.ExpectedTestFieldError(ShippingAgent.FieldCaption("Shipping Agent No."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesHeaderWithThirdPartyLoaderTypeError()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Test to verify error on Sales Header when 3rd Party Loader No is blank on Sales Header.
        // Setup.
        Initialize();
        CreateSalesHeader(SalesHeader);

        // Exercise.
        asserterror SalesHeader.Validate("3rd Party Loader Type", SalesHeader."3rd Party Loader Type"::Vendor);

        // Verify.
        Assert.ExpectedError(PartyLoaderErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesHeaderWithThirdPartyLoaderNoError()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Test to verify error on Sales Header when 3rd Party Loader Type is blank on Sales Header.
        // Setup.
        Initialize();
        CreateSalesHeader(SalesHeader);

        // Exercise.
        asserterror SalesHeader.Validate("3rd Party Loader No.", CreateVendor());

        // Verify.
        Assert.ExpectedError(PartyLoaderErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithThirdPartyLoaderTypeError()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Test to verify error after post Sales Order when 3rd Party Loader Type is blank on Sales Header.
        PostSalesOrderWithTDD(LibraryUtility.GenerateGUID(), SalesHeader."3rd Party Loader Type", ThirdPartyLoaderErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithTDDPreparedByError()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Test to verify error after post Sales Order when TDD Prepared By is blank on Sales Header.
        PostSalesOrderWithTDD('', SalesHeader."3rd Party Loader Type"::Vendor, TDDErr);
    end;

    local procedure PostSalesOrderWithTDD(TDDPreparedBy: Text[50]; PartyLoaderType: Option; ErrorTxt: Text)
    var
        SalesHeader: Record "Sales Header";
    begin
        // Setup.
        Initialize();
        CreateSalesOrder(SalesHeader, TDDPreparedBy, PartyLoaderType);

        // Exercise.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Invoice.

        // Verify.
        if StrPos(ErrorTxt, SalesHeader.FieldCaption("TDD Prepared By")) > 0 then
            Assert.ExpectedTestFieldError(SalesHeader.FieldCaption("TDD Prepared By"), '')
        else
            Assert.ExpectedTestFieldError(SalesHeader.FieldCaption("3rd Party Loader Type"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesShipmentHeaderWithShippingAgentCodeError()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentCode: Code[10];
    begin
        // Test to verify error on Sales Shipment Header when Shipping Agent No is blank on Shipping Agent.
        // Setup.
        Initialize();
        ShippingAgentCode := CreateShippingAgent('');  // ShippingAgentNo as blank.
        SalesShipmentHeader.Get(CreateAndPostSalesOrder());

        // Exercise.
        asserterror SalesShipmentHeader.Validate("Shipping Agent Code", ShippingAgentCode);

        // Verify.
        Assert.ExpectedTestFieldError(ShippingAgent.FieldCaption("Shipping Agent No."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferHeaderWithShippingAgentCodeError()
    var
        TransferHeader: Record "Transfer Header";
        ShippigAgent: Record "Shipping Agent";
        ShippingAgentCode: Code[10];
    begin
        // Test to verify error on Transfer Header when Shipping Agent No is blank on Shipping Agent.
        // Setup.
        Initialize();
        LibraryInventory.CreateTransferHeader(TransferHeader, '', '', '');  // FromLocation, ToLocation and InTransitCode as blank.
        ShippingAgentCode := CreateShippingAgent('');  // ShippingAgentNo as blank.

        // Exercise.
        asserterror TransferHeader.Validate("Shipping Agent Code", ShippingAgentCode);

        // Verify.
        Assert.ExpectedTestFieldError(ShippigAgent.FieldCaption("Shipping Agent No."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferHeaderWithThirdPartyLoaderTypeError()
    var
        TransferHeader: Record "Transfer Header";
    begin
        // Test to verify error on Transfer Header when 3rd Party Loader No is blank on Transfer Header.
        // Setup.
        Initialize();
        LibraryInventory.CreateTransferHeader(TransferHeader, '', '', '');  // FromLocation, ToLocation and InTransitCode as blank.
        TransferHeader.Validate("Shipping Agent Code", CreateShippingAgent(CreateVendor()));

        // Exercise.
        asserterror TransferHeader.Validate("3rd Party Loader Type", TransferHeader."3rd Party Loader Type"::Vendor);

        // Verify.
        Assert.ExpectedError(PartyLoaderErr);
    end;

    [Test]
    [HandlerFunctions('SalesShipmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesShipmentReportWithAdditionalInformation()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        // Test to verify values on Sales - Shipment Report after post Sales Order with Additional Information.
        // Setup.
        Initialize();
        SalesShipmentHeader.Get(CreateAndPostSalesOrder());
        LibraryVariableStorage.Enqueue(SalesShipmentHeader."No.");  // Enqueue for SalesShipmentRequestPageHandler.

        // Exercise and Verify.
        RunMiscellaneousReportsAndVerifyXMLValues(
          REPORT::"Sales - Shipment", 'AdditionalInfo_SalesShipHdr', 'TDDPreparedBy_SalesShipHdr',
          SalesShipmentHeader."Additional Information", SalesShipmentHeader."TDD Prepared By");
    end;

    [Test]
    [HandlerFunctions('PurchaseReturnShipmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseRetShipmentReportWithAdditionalInformation()
    var
        PurchaseLine: Record "Purchase Line";
        ReturnShipmentHeader: Record "Return Shipment Header";
    begin
        // Test to verify values on Purchase - Return Shipment Report after post Purchase Return Order with Additional Information.
        // Setup.
        Initialize();
        ReturnShipmentHeader.Get(CreateAndPostPurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Return Order"));
        LibraryVariableStorage.Enqueue(ReturnShipmentHeader."No.");  // Enqueue for PurchaseReturnShipmentRequestPageHandler.

        // Exercise and Verify.
        RunMiscellaneousReportsAndVerifyXMLValues(
          REPORT::"Purchase - Return Shipment", 'AddInfo_ReturnShptHeader', 'TDDPrepdBy_ReturnShptHeader',
          ReturnShipmentHeader."Additional Information", ReturnShipmentHeader."TDD Prepared By");
    end;

    [Test]
    [HandlerFunctions('ServiceShipmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceShipmentReportWithAdditionalInformation()
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        // Test to verify values on Service - Shipment Report after post Service Order with Additional Information.
        // Setup.
        Initialize();
        ServiceShipmentHeader.Get(CreateAndPostServiceOrder());
        LibraryVariableStorage.Enqueue(ServiceShipmentHeader."No.");  // Enqueue for ServiceShipmentRequestPageHandler.

        // Exercise and Verify.
        RunMiscellaneousReportsAndVerifyXMLValues(
          REPORT::"Service - Shipment", 'AddInfo_ServShptHeader', 'TDDPrepBy_ServShptHeader',
          ServiceShipmentHeader."Additional Information", ServiceShipmentHeader."TDD Prepared By");
    end;

    [Test]
    [HandlerFunctions('TransferShipmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TransferShipmentReportWithAdditionalInformation()
    var
        TransferHeader: Record "Transfer Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
    begin
        // Test to verify values on Transfer Shipment Report after post Transfer Order with Additional Information.

        // Setup: Create and Post Transfer Order, Update Transfer Shipment Header.
        Initialize();
        CreateAndPostTransferOrder(TransferHeader);
        FindAndUpdateTransferShipmentHeader(
          TransferShipmentHeader, TransferHeader."Last Shipment No.", TransferHeader."3rd Party Loader No.");
        LibraryVariableStorage.Enqueue(TransferHeader."Last Shipment No.");  // Enqueue for TransferShipmentRequestPageHandler.
        Commit();  // Commit required.

        // Exercise and Verify.
        RunMiscellaneousReportsAndVerifyXMLValues(
          REPORT::"Transfer Shipment", 'AddInfo_TransShptHeader', 'TDDPreparedBy_TransShptHeader',
          TransferShipmentHeader."Additional Information", TransferShipmentHeader."TDD Prepared By");
    end;

    [Test]
    [HandlerFunctions('SalesShipmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesShipmentHeaderWithThirdPartyLoaderError()
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        // Test to verify error on Sales - Shipment Report when 3rd Party Loader No. is blank on Sales Shipment Header.
        // Setup.
        Initialize();
        SalesShipmentHeader.Get(CreateAndPostSalesOrder());
        SalesShipmentHeader.Validate("3rd Party Loader No.", '');
        SalesShipmentHeader.Modify(true);
        LibraryVariableStorage.Enqueue(SalesShipmentHeader."No.");  // Enqueue for SalesShipmentRequestPageHandler.
        Commit();  // Commit required.

        // Exercise and Verify.
        RunMiscellaneousReportsAndVerifyError(
                  REPORT::"Sales - Shipment", StrSubstNo(ThirdPartyLoaderNoErr, SalesShipmentHeader.TableCaption(), SalesShipmentHeader."No."));
    end;

    [Test]
    [HandlerFunctions('TransferShipmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TransferShipmentHeaderWithThirdPartyLoaderError()
    var
        TransferHeader: Record "Transfer Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
    begin
        // Test to verify error on Transfer Shipment Report when 3rd Party Loader No. is blank on Transfer Shipment Header.
        // Setup.
        Initialize();
        TransferShipmentHeader.Get(CreateAndPostTransferOrder(TransferHeader));
        TransferShipmentHeader.Validate("3rd Party Loader No.", '');
        TransferShipmentHeader.Modify(true);
        LibraryVariableStorage.Enqueue(TransferShipmentHeader."No.");  // Enqueue for TransferShipmentRequestPageHandler.
        Commit();  // Commit required.

        // Exercise and Verify.
        RunMiscellaneousReportsAndVerifyError(
          REPORT::"Transfer Shipment", StrSubstNo(ThirdPartyLoaderTypeErr, TransferShipmentHeader."No."));
    end;

    [Test]
    [HandlerFunctions('PurchaseReturnShipmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ReturnShipmentHeaderWithThirdPartyLoaderError()
    var
        PurchaseLine: Record "Purchase Line";
        ReturnShipmentHeader: Record "Return Shipment Header";
    begin
        // Test to verify error on Purchase - Return Shipment Report when 3rd Party Loader No. is blank on Return Shipment Header.
        // Setup.
        Initialize();
        ReturnShipmentHeader.Get(CreateAndPostPurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Return Order"));
        ReturnShipmentHeader.Validate("3rd Party Loader No.", '');
        ReturnShipmentHeader.Modify(true);
        LibraryVariableStorage.Enqueue(ReturnShipmentHeader."No.");  // Enqueue for PurchaseReturnShipmentRequestPageHandler.
        Commit();  // Commit required.

        // Exercise and Verify.
        RunMiscellaneousReportsAndVerifyError(
          REPORT::"Purchase - Return Shipment", StrSubstNo(
            ThirdPartyLoaderNoErr, ReturnShipmentHeader.TableCaption(), ReturnShipmentHeader."No."));
    end;

    [Test]
    [HandlerFunctions('ServiceShipmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceShipmentHeaderWithThirdPartyLoaderError()
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        // Test to verify error on Service - Shipment Report when 3rd Party Loader No. is blank on Service Shipment Header.
        // Setup.
        Initialize();
        ServiceShipmentHeader.Get(CreateAndPostServiceOrder());
        ServiceShipmentHeader.Validate("3rd Party Loader No.", '');
        ServiceShipmentHeader.Modify(true);
        LibraryVariableStorage.Enqueue(ServiceShipmentHeader."No.");  // Enqueue for ServiceShipmentRequestPageHandler.
        Commit();  // Commit required.

        // Exercise and Verify.
        RunMiscellaneousReportsAndVerifyError(
          REPORT::"Service - Shipment", StrSubstNo(ThirdPartyLoaderNoErr, ServiceShipmentHeader.TableCaption(), ServiceShipmentHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReturnShipmentHeaderWithShippingAgentCodeError()
    var
        PurchaseLine: Record "Purchase Line";
        ReturnShipmentHeader: Record "Return Shipment Header";
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentCode: Code[10];
    begin
        // Test to verify error on Return Shipment Header when Shipping Agent Code is blank on Shipping Agent.
        // Setup.
        Initialize();
        ReturnShipmentHeader.Get(CreateAndPostPurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Return Order"));
        ShippingAgentCode := CreateShippingAgent('');  // ShippingAgentNo as blank.

        // Exercise.
        asserterror ReturnShipmentHeader.Validate("Shipping Agent Code", ShippingAgentCode);

        // Verify.
        Assert.ExpectedTestFieldError(ShippingAgent.FieldCaption("Shipping Agent No."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceShipmentHeaderWithShippingAgentCodeError()
    var
        ServiceShipmentHeader: Record "Service Shipment Header";
    begin
        // Test to verify error on Service Shipment Header when Shipping Agent Code is blank on Shipping Agent.
        // Setup.
        Initialize();
        ServiceShipmentHeader.Get(CreateAndPostServiceOrder());

        // Exercise.
        asserterror ServiceShipmentHeader.Validate("Shipping Agent Code", '');

        // Verify.
        Assert.ExpectedError(StrSubstNo(ShippingAgentCodeErr, ServiceShipmentHeader."Shipment Method Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TransferShipmentHeaderWithShippingAgentCodeError()
    var
        TransferHeader: Record "Transfer Header";
        TransferShipmentHeader: Record "Transfer Shipment Header";
    begin
        // Test to verify error on Transfer Shipment Header when Shipping Agent Code is blank on Shipping Agent.
        // Setup.
        Initialize();
        TransferShipmentHeader.Get(CreateAndPostTransferOrder(TransferHeader));

        // Exercise.
        asserterror TransferShipmentHeader.Validate("Shipping Agent Code", '');

        // Verify.
        Assert.ExpectedError(StrSubstNo(ShippingAgentCodeErr, TransferHeader."Shipment Method Code"));
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"): Code[20]
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreatePurchaseHeader(PurchaseHeader, CreateVendor(), DocumentType);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(100, 2));  // Using random Quantity.
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as receive and invoice.
        exit(PurchaseHeader."Last Return Shipment No.");
    end;

    local procedure CreateAndPostSalesOrder(): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesOrder(SalesHeader, LibraryUtility.GenerateGUID(), SalesHeader."3rd Party Loader Type"::Vendor);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as ship and invoice.
        exit(SalesHeader."Last Shipping No.");
    end;

    local procedure CreateAndPostServiceOrder(): Code[20]
    var
        Customer: Record Customer;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Item: Record Item;
    begin
        LibrarySales.CreateCustomer(Customer);
        CreateServiceHeader(ServiceHeader, Customer."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItem(Item));
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));  // Using random Quantity.
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);  // Post as ship and invoice.
        exit(ServiceHeader."Last Shipping No.");
    end;

    local procedure CreateAndPostTransferOrder(var TransferHeader: Record "Transfer Header"): Code[20]
    var
        Location: Record Location;
        Location2: Record Location;
        PurchaseLine: Record "Purchase Line";
        TransferLine: Record "Transfer Line";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryWarehouse.CreateInTransitLocation(Location2);
        CreateAndPostPurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Order);
        LibraryInventory.CreateTransferHeader(TransferHeader, PurchaseLine."Location Code", Location.Code, Location2.Code);
        TransferHeader.Validate("Shipment Method Code", FindAndUpdateShippingMethod(true));  // ThirdPartyLoader as true.
        TransferHeader.Validate("Shipping Agent Code", CreateShippingAgent(CreateVendor()));
        TransferHeader.Validate("3rd Party Loader Type", TransferHeader."3rd Party Loader Type"::Vendor);
        TransferHeader.Validate("3rd Party Loader No.", CreateVendor());
        TransferHeader.Validate("TDD Prepared By", LibraryUtility.GenerateGUID());
        TransferHeader.Modify(true);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, PurchaseLine."No.", PurchaseLine.Quantity);
        LibraryInventory.PostTransferHeader(TransferHeader, true, true);  // Post as ship and invoice.
        exit(TransferHeader."Last Shipment No.");
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; DocumentType: Enum "Purchase Document Type")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Shipment Method Code", FindAndUpdateShippingMethod(true));  // ThirdPartyLoader as true.
        PurchaseHeader.Validate("Shipping Agent Code", CreateShippingAgent(CreateVendor()));
        PurchaseHeader.Validate("3rd Party Loader Type", PurchaseHeader."3rd Party Loader Type"::Vendor);
        PurchaseHeader.Validate("3rd Party Loader No.", CreateVendor());
        PurchaseHeader.Validate("TDD Prepared By", LibraryUtility.GenerateGUID());
        PurchaseHeader.Validate("Additional Information", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Shipping Agent Code", CreateShippingAgent(CreateVendor()));
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; TDDPreparedBy: Text[50]; PartyLoaderType: Option)
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeader(SalesHeader);
        SalesHeader.Validate("Shipment Method Code", FindAndUpdateShippingMethod(true));  // ThirdPartyLoader as true.
        SalesHeader.Validate("3rd Party Loader Type", PartyLoaderType);
        SalesHeader.Validate("3rd Party Loader No.", CreateVendor());
        SalesHeader.Validate("TDD Prepared By", TDDPreparedBy);
        SalesHeader.Validate("Additional Information", LibraryUtility.GenerateGUID());
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Taking random Quantity.
    end;

    local procedure CreateServiceHeader(var ServiceHeader: Record "Service Header"; CustomerNo: Code[20])
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, CustomerNo);
        ServiceHeader.Validate("Shipment Method Code", FindAndUpdateShippingMethod(true));  // ThirdPartyLoader as true.
        ServiceHeader.Validate("Shipping Agent Code", CreateShippingAgent(CreateVendor()));
        ServiceHeader.Validate("3rd Party Loader Type", ServiceHeader."3rd Party Loader Type"::Vendor);
        ServiceHeader.Validate("3rd Party Loader No.", CreateVendor());
        ServiceHeader.Validate("TDD Prepared By", LibraryUtility.GenerateGUID());
        ServiceHeader.Validate("Additional Information", LibraryUtility.GenerateGUID());
        ServiceHeader.Modify(true);
    end;

    local procedure CreateShippingAgent(ShippingAgentNo: Code[20]): Code[10]
    var
        ShippingAgent: Record "Shipping Agent";
    begin
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        ShippingAgent.Validate("Shipping Agent Type", ShippingAgent."Shipping Agent Type"::Vendor);
        ShippingAgent.Validate("Shipping Agent No.", ShippingAgentNo);
        ShippingAgent.Modify(true);
        exit(ShippingAgent.Code);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure FindAndUpdateShippingMethod(ThirdPartyLoader: Boolean): Code[10]
    var
        ShipmentMethod: Record "Shipment Method";
    begin
        ShipmentMethod.FindFirst();
        ShipmentMethod.Validate("3rd-Party Loader", ThirdPartyLoader);
        ShipmentMethod.Modify(true);
        exit(ShipmentMethod.Code);
    end;

    local procedure FindAndUpdateTransferShipmentHeader(var TransferShipmentHeader: Record "Transfer Shipment Header"; No: Code[20]; ThirdPartyLoaderNo: Code[20])
    begin
        TransferShipmentHeader.Get(No);
        TransferShipmentHeader.Validate("3rd Party Loader Type", TransferShipmentHeader."3rd Party Loader Type"::Vendor);
        TransferShipmentHeader.Validate("3rd Party Loader No.", ThirdPartyLoaderNo);
        TransferShipmentHeader.Validate("TDD Prepared By", LibraryUtility.GenerateGUID());
        TransferShipmentHeader.Validate("Additional Information", LibraryUtility.GenerateGUID());
        TransferShipmentHeader.Modify(true);
    end;

    local procedure RunMiscellaneousReportsAndVerifyError(ReportID: Integer; ErrorCode: Text)
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        // Exercise.
        asserterror REPORT.Run(ReportID);

        // Verify.
        if StrPos(ErrorCode, ThirdPartyLoaderNoLbl) > 0 then
            Assert.ExpectedTestFieldError(SalesShipmentHeader.FieldCaption("3rd Party Loader No."), '')
        else
            Assert.ExpectedTestFieldError(SalesShipmentHeader.FieldCaption("3rd Party Loader Type"), '');
    end;

    local procedure RunMiscellaneousReportsAndVerifyXMLValues(ReportID: Integer; Caption: Text; Caption2: Text; Value: Text; Value2: Text)
    begin
        // Exercise.
        REPORT.Run(ReportID);

        // Verify.
        VerifyValuesOnReport(Caption, Caption2, Value, Value2);
    end;

    local procedure VerifyValuesOnReport(Caption: Text; Caption2: Text; Value: Text; Value2: Text)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(Caption, Value);
        LibraryReportDataset.AssertElementWithValueExists(Caption2, Value2);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseReturnShipmentRequestPageHandler(var PurchaseReturnShipment: TestRequestPage "Purchase - Return Shipment")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        PurchaseReturnShipment."Return Shipment Header".SetFilter("No.", No);
        PurchaseReturnShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesShipmentRequestPageHandler(var SalesShipment: TestRequestPage "Sales - Shipment")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        SalesShipment."Sales Shipment Header".SetFilter("No.", No);
        SalesShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ServiceShipmentRequestPageHandler(var ServiceShipment: TestRequestPage "Service - Shipment")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        ServiceShipment."Service Shipment Header".SetFilter("No.", No);
        ServiceShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure TransferShipmentRequestPageHandler(var TransferShipment: TestRequestPage "Transfer Shipment")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        TransferShipment."Transfer Shipment Header".SetFilter("No.", No);
        TransferShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

