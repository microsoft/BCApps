codeunit 135001 "Page Management Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Page Management]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        WrongPageCaptionErr: Label 'Wrong page caption';
        PageManagement: Codeunit "Page Management";
        WrongPageErr: Label 'Wrong page ID for table %1';

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPageIDForRecord()
    var
        CompanyInformation: Record "Company Information";
        PageID: Integer;
    begin
        // [SCENARIO] The user defined page ID is returned when record is provided to GetPageID
        // [GIVEN] A Record, which has a user defined page id
        CompanyInformation.Get();

        // [WHEN] The GetPageID function is called with that record
        PageID := PageManagement.GetPageID(CompanyInformation);

        // [THEN] The correct page id is returned
        Assert.AreEqual(Page::"Company Information", PageID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPageIDForRecordRef()
    var
        CIRecordRef: RecordRef;
        PageID: Integer;
    begin
        // [SCENARIO] The user defined page ID is returned when RecordRef is provided to GetPageID
        // [GIVEN] A RecordRef, which has a user defined page id
        CIRecordRef.Open(DATABASE::"Company Information");
        CIRecordRef.FindFirst();

        // [WHEN] The GetPageID function is called with that RecordRef
        PageID := PageManagement.GetPageID(CIRecordRef);

        // [THEN] The correct page id is returned
        Assert.AreEqual(Page::"Company Information", PageID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPageIDForRecordID()
    var
        CIRecordRef: RecordRef;
        RecordID: RecordID;
        PageID: Integer;
    begin
        // [SCENARIO] The user defined page ID is returned when RecordID is provided to GetPageID
        // [GIVEN] A RecordID, which has a user defined page id
        CIRecordRef.Open(DATABASE::"Company Information");
        CIRecordRef.FindFirst();
        RecordID := CIRecordRef.RecordId;

        // [WHEN] The GetPageID function is called with that RecordID
        PageID := PageManagement.GetPageID(RecordID);

        // [THEN] The correct page id is returned
        Assert.AreEqual(Page::"Company Information", PageID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetMetaPageIDForRecord()
    var
        Customer: Record Customer;
        PageID: Integer;
    begin
        // [SCENARIO] The meta data page ID is returned when Record is provided to GetPageID
        // [GIVEN] A Record, which has a metadata page id
        Customer.FindLast();

        // [WHEN] The GetPageID function is called with that record
        PageID := PageManagement.GetPageID(Customer);

        // [THEN] The correct page id is returned
        Assert.AreEqual(Page::"Customer Card", PageID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetMetaPageIDForRecordRef()
    var
        Item: Record Item;
        DataTypeManagement: Codeunit "Data Type Management";
        RecordRef: RecordRef;
        PageID: Integer;
    begin
        // [SCENARIO] The meta data page ID is returned when RecordRef is provided to GetPageID
        // [GIVEN] A RecordRef, which has a metadata page id
        Item.SetFilter(Description, '<>%1', '');
        Item.FindFirst();
        DataTypeManagement.GetRecordRef(Item, RecordRef);

        // [WHEN] The GetPageID function is called with that RecordRef
        PageID := PageManagement.GetPageID(RecordRef);

        // [THEN] The correct page id is returned
        Assert.AreEqual(Page::"Item Card", PageID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetMetaPageIDForRecordID()
    var
        VendorRecordRef: RecordRef;
        RecordID: RecordID;
        PageID: Integer;
    begin
        // [SCENARIO] The meta data page ID is returned when RecordID is provided to GetPageID
        // [GIVEN] A RecordID, which has a metadata page id
        VendorRecordRef.Open(DATABASE::Vendor);
        VendorRecordRef.FindFirst();
        RecordID := VendorRecordRef.RecordId;

        // [WHEN] The GetPageID function is called with that RecordID
        PageID := PageManagement.GetPageID(RecordID);

        // [THEN] The correct page id is returned
        Assert.AreEqual(Page::"Vendor Card", PageID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPageIDForSalesHeader()
    var
        SalesHeader: Record "Sales Header";
        PageID: Integer;
    begin
        // [SCENARIO] The correct page ID is returned for the sales order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');

        // [WHEN] The GetPageID function is called for a sales order
        PageID := PageManagement.GetPageID(SalesHeader);

        // [THEN] "Sales Order" page id is returned
        Assert.AreEqual(Page::"Sales Order", PageID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPageIDForPurchaseHeader()
    var
        PurchaseHeader: Record "Purchase Header";
        PageID: Integer;
    begin
        // [SCENARIO] The correct page ID is returned for the purchase quote
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Quote, '');

        // [WHEN] The GetPageID function is called for a purchase qoute
        PageID := PageManagement.GetPageID(PurchaseHeader);

        // [THEN] "Purchase Quote" page id is returned
        Assert.AreEqual(Page::"Purchase Quote", PageID, '');
    end;

    [Test]
    [TestPermissions(TestPermissions::Disabled)]
    [Scope('OnPrem')]
    procedure TestGetPageIDForServiceInvHeader()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        LibraryUtility: Codeunit "Library - Utility";
        PageID: Integer;
    begin
        // [SCENARIO] The correct page ID is returned for the "Service Invoice Header" record
        ServiceInvoiceHeader.Init();
        ServiceInvoiceHeader."No." := LibraryUtility.GenerateRandomCode(ServiceInvoiceHeader.FieldNo("No."),
            DATABASE::"Service Invoice Header");
        ServiceInvoiceHeader.Insert();

        // [WHEN] The GetPageID function is called for a service invoice header
        PageID := PageManagement.GetPageID(ServiceInvoiceHeader);

        // [THEN] "Posted Service Invoice" page id is returned
        Assert.AreEqual(Page::"Posted Service Invoice", PageID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetListPageIDForTableID()
    var
        PageID: Integer;
    begin
        // [SCENARIO] The meta data list page ID is returned when Table ID is provided

        // [WHEN] The GetDefaultListPageID function is called with that table ID
        PageID := PageManagement.GetDefaultLookupPageID(DATABASE::Customer);

        // [THEN] The correct list page id is returned
        Assert.AreEqual(Page::"Customer Lookup", PageID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetPageCaptionCustomerCard()
    var
        CustomerCard: Page "Customer Card";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 257841] Function GetPageCaption should return caption of the "Customer Card" page for page ID = 21

        Assert.AreEqual(CustomerCard.Caption, PageManagement.GetPageCaption(Page::"Customer Card"), WrongPageCaptionErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetPageCaptionNonExistingPage()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 257841] Function GetPageCaption should return empty string for page ID = 0

        Assert.AreEqual('', PageManagement.GetPageCaption(0), WrongPageCaptionErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetPageIDSimulatedProdOrder()
    var
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 257841] GetPageID should return "Simulated Production Order" page for simulated production order

        ProductionOrder.Status := ProductionOrder.Status::Simulated;
        Assert.AreEqual(
          Page::"Simulated Production Order", PageManagement.GetPageID(ProductionOrder),
          StrSubstNo(WrongPageErr, ProductionOrder.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetPageIDPlannedProdOrder()
    var
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 257841] GetPageID should return "Planned Production Order" page for planned production order

        ProductionOrder.Status := ProductionOrder.Status::Planned;
        Assert.AreEqual(
          Page::"Planned Production Order", PageManagement.GetPageID(ProductionOrder),
          StrSubstNo(WrongPageErr, ProductionOrder.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetPageIDFirmPlannedProdOrder()
    var
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 257841] GetPageID should return "Firm Planned Prod. Order" page for firm planned production order

        ProductionOrder.Status := ProductionOrder.Status::"Firm Planned";
        Assert.AreEqual(
          Page::"Firm Planned Prod. Order", PageManagement.GetPageID(ProductionOrder),
          StrSubstNo(WrongPageErr, ProductionOrder.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetPageIDReleaseProdOrder()
    var
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 257841] GetPageID should return "Released Production Order" page for released production order

        ProductionOrder.Status := ProductionOrder.Status::Released;
        Assert.AreEqual(
          Page::"Released Production Order", PageManagement.GetPageID(ProductionOrder),
          StrSubstNo(WrongPageErr, ProductionOrder.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetPageIDFinishedProdOrder()
    var
        ProductionOrder: Record "Production Order";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 257841] GetPageID should return "Finished Production Order" page for finished production order

        ProductionOrder.Status := ProductionOrder.Status::Finished;
        Assert.AreEqual(
          Page::"Finished Production Order", PageManagement.GetPageID(ProductionOrder),
          StrSubstNo(WrongPageErr, ProductionOrder.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPageIDForSalesHeaderOneRecord()
    var
        SalesHeader: Record "Sales Header";
        PageID: Integer;
    begin
        // [SCENARIO] The correct page ID is returned for the sales order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');

        // [WHEN] The GetPageID function is called for a sales order
        PageID := PageManagement.GetPageID(SalesHeader);

        // [THEN] "Sales Order" page id is returned
        Assert.AreEqual(Page::"Sales Order", PageID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPageIDForSalesHeaderFilterOneDocumentType()
    var
        SalesHeader: Record "Sales Header";
        PageID: Integer;
    begin
        // [SCENARIO] The correct page ID is returned for sales header with filter applied on "Document Type" = Order
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);

        // [WHEN] The GetPageID function is called for sales header with filter applied on "Document Type" = Order
        PageID := PageManagement.GetPageID(SalesHeader);

        // [THEN] "Sales Order" page id is returned
        Assert.AreEqual(Page::"Sales Order", PageID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPageIDForSalesHeaderFilterMoreDocumentTypes()
    var
        SalesHeader: Record "Sales Header";
        PageID: Integer;
    begin
        // [SCENARIO] The correct page ID is returned for sales header with filter applied on "Document Type" = Order OR Invoice
        SalesHeader.SetFilter("Document Type", '%1|%2', SalesHeader."Document Type"::Order, SalesHeader."Document Type"::Invoice);

        // [WHEN] The GetPageID function is called for sales header with filter applied on "Document Type" = Order OR Invoice
        PageID := PageManagement.GetPageID(SalesHeader);

        // [THEN] "Sales List" page id is returned
        Assert.AreEqual(Page::"Sales List", PageID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPageIDForSalesHeaderFilterUnknownDocumentTypes()
    var
        SalesHeader: Record "Sales Header";
        PageID: Integer;
    begin
        // [SCENARIO] The correct page ID is returned for sales header with filter applied on "No." <> '' without any filter on "Document Type"
        SalesHeader.SetFilter("No.", '<>''''');

        // [WHEN] The GetPageID function is called for sales header with filter applied on "No." <> '' without any filter on "Document Type"
        PageID := PageManagement.GetPageID(SalesHeader);

        // [THEN] "Sales List" page id is returned
        Assert.AreEqual(Page::"Sales List", PageID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetListPageIDForSalesHeaderOneRecord()
    var
        SalesHeader: Record "Sales Header";
        PageID: Integer;
    begin
        // [SCENARIO] The correct page ID is returned for the sales order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');

        // [WHEN] The GetListPageID function is called for a sales order without any filter
        PageID := PageManagement.GetListPageID(SalesHeader);

        // [THEN] "Sales List" page id is returned
        Assert.AreEqual(Page::"Sales List", PageID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetListPageIDForSalesHeaderFilterOneDocumentType()
    var
        SalesHeader: Record "Sales Header";
        PageID: Integer;
    begin
        // [SCENARIO] The correct page ID is returned for sales header with filter applied on "Document Type" = Order
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);

        // [WHEN] The GetListPageID function is called for sales header with filter applied on "Document Type" = Order
        PageID := PageManagement.GetListPageID(SalesHeader);

        // [THEN] "Sales Order List" page id is returned
        Assert.AreEqual(Page::"Sales Order List", PageID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetListPageIDForSalesHeaderFilterMoreDocumentTypes()
    var
        SalesHeader: Record "Sales Header";
        PageID: Integer;
    begin
        // [SCENARIO] The correct page ID is returned for sales header with filter applied on "Document Type" = Order OR Invoice
        SalesHeader.SetFilter("Document Type", '%1|%2', SalesHeader."Document Type"::Order, SalesHeader."Document Type"::Invoice);

        // [WHEN] The GetListPageID function is called for sales header with filter applied on "Document Type" = Order OR Invoice
        PageID := PageManagement.GetListPageID(SalesHeader);

        // [THEN] "Sales List" page id is returned
        Assert.AreEqual(Page::"Sales List", PageID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetListPageIDForSalesHeaderFilterUnknownDocumentTypes()
    var
        SalesHeader: Record "Sales Header";
        PageID: Integer;
    begin
        // [SCENARIO] The correct page ID is returned for sales header with filter applied on "No." <> '' without any filter on "Document Type"
        SalesHeader.SetFilter("No.", '<>''''');

        // [WHEN] The GetListPageID function is called for sales header with filter applied on "No." <> '' without any filter on "Document Type"
        PageID := PageManagement.GetListPageID(SalesHeader);

        // [THEN] "Sales List" page id is returned
        Assert.AreEqual(Page::"Sales List", PageID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPageIDForPurchaseHeaderOneRecord()
    var
        PurchaseHeader: Record "Purchase Header";
        PageID: Integer;
    begin
        // [SCENARIO] The correct page ID is returned for the Purchase order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');

        // [WHEN] The GetPageID function is called for a Purchase order
        PageID := PageManagement.GetPageID(PurchaseHeader);

        // [THEN] "Purchase Order" page id is returned
        Assert.AreEqual(Page::"Purchase Order", PageID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPageIDForPurchaseHeaderFilterOneDocumentType()
    var
        PurchaseHeader: Record "Purchase Header";
        PageID: Integer;
    begin
        // [SCENARIO] The correct page ID is returned for Purchase header with filter applied on "Document Type" = Order
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);

        // [WHEN] The GetPageID function is called for Purchase header with filter applied on "Document Type" = Order
        PageID := PageManagement.GetPageID(PurchaseHeader);

        // [THEN] "Purchase Order" page id is returned
        Assert.AreEqual(Page::"Purchase Order", PageID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPageIDForPurchaseHeaderFilterMoreDocumentTypes()
    var
        PurchaseHeader: Record "Purchase Header";
        PageID: Integer;
    begin
        // [SCENARIO] The correct page ID is returned for Purchase header with filter applied on "Document Type" = Order OR Invoice
        PurchaseHeader.SetFilter("Document Type", '%1|%2', PurchaseHeader."Document Type"::Order, PurchaseHeader."Document Type"::Invoice);

        // [WHEN] The GetPageID function is called for Purchase header with filter applied on "Document Type" = Order OR Invoice
        PageID := PageManagement.GetPageID(PurchaseHeader);

        // [THEN] "Purchase List" page id is returned
        Assert.AreEqual(Page::"Purchase List", PageID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetPageIDForPurchaseHeaderFilterUnknownDocumentTypes()
    var
        PurchaseHeader: Record "Purchase Header";
        PageID: Integer;
    begin
        // [SCENARIO] The correct page ID is returned for Purchase header with filter applied on "No." <> '' without any filter on "Document Type"
        PurchaseHeader.SetFilter("No.", '<>''''');

        // [WHEN] The GetPageID function is called for Purchase header with filter applied on "No." <> '' without any filter on "Document Type"
        PageID := PageManagement.GetPageID(PurchaseHeader);

        // [THEN] "Purchase List" page id is returned
        Assert.AreEqual(Page::"Purchase List", PageID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetListPageIDForPurchaseHeaderOneRecord()
    var
        PurchaseHeader: Record "Purchase Header";
        PageID: Integer;
    begin
        // [SCENARIO] The correct page ID is returned for the Purchase order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');

        // [WHEN] The GetListPageID function is called for a Purchase order without any filter
        PageID := PageManagement.GetListPageID(PurchaseHeader);

        // [THEN] "Purchase List" page id is returned
        Assert.AreEqual(Page::"Purchase List", PageID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetListPageIDForPurchaseHeaderFilterOneDocumentType()
    var
        PurchaseHeader: Record "Purchase Header";
        PageID: Integer;
    begin
        // [SCENARIO] The correct page ID is returned for Purchase header with filter applied on "Document Type" = Order
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);

        // [WHEN] The GetListPageID function is called for Purchase header with filter applied on "Document Type" = Order
        PageID := PageManagement.GetListPageID(PurchaseHeader);

        // [THEN] "Purchase Order List" page id is returned
        Assert.AreEqual(Page::"Purchase Order List", PageID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetListPageIDForPurchaseHeaderFilterMoreDocumentTypes()
    var
        PurchaseHeader: Record "Purchase Header";
        PageID: Integer;
    begin
        // [SCENARIO] The correct page ID is returned for Purchase header with filter applied on "Document Type" = Order OR Invoice
        PurchaseHeader.SetFilter("Document Type", '%1|%2', PurchaseHeader."Document Type"::Order, PurchaseHeader."Document Type"::Invoice);

        // [WHEN] The GetListPageID function is called for Purchase header with filter applied on "Document Type" = Order OR Invoice
        PageID := PageManagement.GetListPageID(PurchaseHeader);

        // [THEN] "Purchase List" page id is returned
        Assert.AreEqual(Page::"Purchase List", PageID, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetListPageIDForPurchaseHeaderFilterUnknownDocumentTypes()
    var
        PurchaseHeader: Record "Purchase Header";
        PageID: Integer;
    begin
        // [SCENARIO] The correct page ID is returned for Purchase header with filter applied on "No." <> '' without any filter on "Document Type"
        PurchaseHeader.SetFilter("No.", '<>''''');

        // [WHEN] The GetListPageID function is called for Purchase header with filter applied on "No." <> '' without any filter on "Document Type"
        PageID := PageManagement.GetListPageID(PurchaseHeader);

        // [THEN] "Purchase List" page id is returned
        Assert.AreEqual(Page::"Purchase List", PageID, '');
    end;
}

