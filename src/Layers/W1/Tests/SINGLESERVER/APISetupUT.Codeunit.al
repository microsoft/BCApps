codeunit 134636 "API Setup UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [API Setup] [UT]
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        Assert: Codeunit Assert;
        APIMockEvents: Codeunit "API Mock Events";
        IsInitialzed: Boolean;

    local procedure Initialze()
    begin
        APIMockEvents.SetIsAPIEnabled(true);
        APIMockEvents.SetIsIntegrationManagementEnabled(true);

        if IsInitialzed then
            exit;

        IsInitialzed := true;
        BindSubscription(APIMockEvents);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertingWithTriggerAssingsRelatedRecordIDsCustomer()
    var
        Customer: Record Customer;
    begin
        // Setup
        Initialze();
        Customer.Init();
        SetReferencedRecordCodesOnCustomer(Customer);

        // Execute
        Customer.Insert(true);

        // Verify
        VerifyCustomerRelatedRecordIDs(Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertingWithoutTriggerAssingsRelatedRecordIDsCustomer()
    var
        Customer: Record Customer;
    begin
        // Setup
        Initialze();
        Customer.Init();
        SetReferencedRecordCodesOnCustomer(Customer);

        // Execute
        Customer.Insert();

        // Verify
        VerifyCustomerRelatedRecordIDs(Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyingWithTriggerAssingsRelatedRecordIDsCustomer()
    var
        Customer: Record Customer;
    begin
        // Setup
        Initialze();
        Customer.Init();
        Customer.Insert(true);
        SetReferencedRecordCodesOnCustomer(Customer);

        // Execute
        Customer.Modify(true);

        // Verify
        VerifyCustomerRelatedRecordIDs(Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyingWithoutTriggerAssingsRelatedRecordIDsCustomer()
    var
        Customer: Record Customer;
    begin
        // Setup
        Initialze();
        Customer.Init();
        Customer.Insert(true);
        SetReferencedRecordCodesOnCustomer(Customer);

        // Execute
        Customer.Modify();

        // Verify
        VerifyCustomerRelatedRecordIDs(Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItIsNotPossibleToBlankRelatedRecordIdsOnCustomer()
    var
        Customer: Record Customer;
        PreviousCustomer: Record Customer;
    begin
        // Setup
        Initialze();
        CreateCustomerRunInsertTrigger(Customer);
        PreviousCustomer.Copy(Customer);

        Clear(Customer."Payment Method Id");
        Clear(Customer."Payment Terms Id");
        Clear(Customer."Currency Id");
        Clear(Customer.SystemId);

        // Execute
        Customer.Modify(true);

        // Verify
        VerifyCustomerRelatedRecordIDs(Customer);
        Assert.AreEqual(Customer."Payment Method Id", PreviousCustomer."Payment Method Id", 'Mismatch on "Payment Method Id"');
        Assert.AreEqual(Customer."Payment Terms Id", PreviousCustomer."Payment Terms Id", 'Mismatch on "Payment Terms Id"');
        Assert.AreEqual(Customer."Currency Id", PreviousCustomer."Currency Id", 'Mismatch on "Currency Id"');
        Assert.AreEqual(Customer.SystemId, PreviousCustomer.SystemId, 'Id should be preserved');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRelatedRecordIdsAreUpdatedOnAPISetupCustomer()
    var
        Customer: Record Customer;
        PreviousCustomer: Record Customer;
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        Initialze();

        // Setup
        CreateCustomerRunInsertTrigger(Customer);
        PreviousCustomer.Copy(Customer);

        Clear(Customer."Payment Method Id");
        Clear(Customer."Payment Terms Id");
        Clear(Customer."Currency Id");
        Clear(Customer.SystemId);

        // Execute
        GraphMgtGeneralTools.ApiSetup();

        // Verify
        VerifyCustomerRelatedRecordIDs(Customer);

        Assert.AreEqual(Customer."Payment Method Id", PreviousCustomer."Payment Method Id", 'Mismatch on "Payment Method Id"');
        Assert.AreEqual(Customer."Payment Terms Id", PreviousCustomer."Payment Terms Id", 'Mismatch on "Payment Terms Id"');
        Assert.AreEqual(Customer."Currency Id", PreviousCustomer."Currency Id", 'Mismatch on "Currency Id"');
        Assert.AreEqual(Customer.SystemId, PreviousCustomer.SystemId, 'Id should be preserved');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertingWithTriggerAssingsRelatedRecordIDsVendor()
    var
        Vendor: Record Vendor;
    begin
        // Setup
        Initialze();
        Vendor.Init();
        SetReferencedRecordCodesOnVendor(Vendor);

        // Execute
        Vendor.Insert(true);

        // Verify
        VerifyVendorRelatedRecordIDs(Vendor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertingWithoutTriggerAssingsRelatedRecordIDsVendor()
    var
        Vendor: Record Vendor;
    begin
        // Setup
        Initialze();
        Vendor.Init();
        SetReferencedRecordCodesOnVendor(Vendor);

        // Execute
        Vendor.Insert();

        // Verify
        VerifyVendorRelatedRecordIDs(Vendor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyingWithTriggerAssingsRelatedRecordIDsVendor()
    var
        Vendor: Record Vendor;
    begin
        // Setup
        Initialze();
        Vendor.Init();
        Vendor.Insert(true);
        SetReferencedRecordCodesOnVendor(Vendor);

        // Execute
        Vendor.Modify(true);

        // Verify
        VerifyVendorRelatedRecordIDs(Vendor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyingWithoutTriggerAssingsRelatedRecordIDsVendor()
    var
        Vendor: Record Vendor;
    begin
        // Setup
        Initialze();
        Vendor.Init();
        Vendor.Insert(true);
        SetReferencedRecordCodesOnVendor(Vendor);

        // Execute
        Vendor.Modify();

        // Verify
        VerifyVendorRelatedRecordIDs(Vendor);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItIsNotPossibleToBlankRelatedRecordIdsOnVendor()
    var
        Vendor: Record Vendor;
        PreviousVendor: Record Vendor;
    begin
        // Setup
        Initialze();
        CreateVendorRunInsertTrigger(Vendor);
        PreviousVendor.Copy(Vendor);

        Clear(Vendor."Payment Method Id");
        Clear(Vendor."Payment Terms Id");
        Clear(Vendor."Currency Id");

        // Execute
        Vendor.Modify(true);

        // Verify
        VerifyVendorRelatedRecordIDs(Vendor);
        Assert.AreEqual(Vendor."Payment Method Id", PreviousVendor."Payment Method Id", 'Mismatch on "Payment Method Id"');
        Assert.AreEqual(Vendor."Payment Terms Id", PreviousVendor."Payment Terms Id", 'Mismatch on "Payment Terms Id"');
        Assert.AreEqual(Vendor."Currency Id", PreviousVendor."Currency Id", 'Mismatch on "Currency Id"');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRelatedRecordIdsAreUpdatedOnAPISetupVendor()
    var
        Vendor: Record Vendor;
        PreviousVendor: Record Vendor;
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        Initialze();

        // Setup
        CreateVendorRunInsertTrigger(Vendor);
        PreviousVendor.Copy(Vendor);

        Clear(Vendor."Payment Method Id");
        Clear(Vendor."Payment Terms Id");
        Clear(Vendor."Currency Id");

        // Execute
        GraphMgtGeneralTools.ApiSetup();

        // Verify
        VerifyVendorRelatedRecordIDs(Vendor);

        Assert.AreEqual(Vendor."Payment Method Id", PreviousVendor."Payment Method Id", 'Mismatch on "Payment Method Id"');
        Assert.AreEqual(Vendor."Payment Terms Id", PreviousVendor."Payment Terms Id", 'Mismatch on "Payment Terms Id"');
        Assert.AreEqual(Vendor."Currency Id", PreviousVendor."Currency Id", 'Mismatch on "Currency Id"');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertingWithTriggerAssingsRelatedRecordIDsItem()
    var
        item: Record Item;
    begin
        // Setup
        Initialze();
        item.Init();
        SetReferencedRecordCodesOnItem(item);

        // Execute
        item.Insert(true);

        // Verify
        VerifyItemRelatedRecordIDs(item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInsertingWithoutTriggerAssingsRelatedRecordIDsItem()
    var
        Item: Record Item;
    begin
        // Setup
        Initialze();
        Item.Init();
        SetReferencedRecordCodesOnItem(Item);

        // Execute
        Item.Insert();

        // Verify
        VerifyItemRelatedRecordIDs(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyingWithTriggerAssingsRelatedRecordIDsItem()
    var
        Item: Record Item;
    begin
        // Setup
        Initialze();
        Item.Init();
        Item.Insert(true);
        SetReferencedRecordCodesOnItem(Item);

        // Execute
        Item.Modify(true);

        // Verify
        VerifyItemRelatedRecordIDs(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyingWithoutTriggerAssingsRelatedRecordIDsItem()
    var
        Item: Record Item;
    begin
        // Setup
        Initialze();
        Item.Init();
        Item.Insert(true);
        SetReferencedRecordCodesOnItem(Item);

        // Execute
        Item.Modify();

        // Verify
        VerifyItemRelatedRecordIDs(Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItIsNotPossibleToBlankRelatedRecordIdsOnItem()
    var
        Item: Record Item;
        PreviousItem: Record Item;
    begin
        // Setup
        Initialze();
        CreateItemRunInsertTrigger(Item);
        PreviousItem.Copy(Item);

        Clear(Item."Unit of Measure Id");

        // Execute
        Item.Modify(true);

        // Verify
        VerifyItemRelatedRecordIDs(Item);
        Assert.AreEqual(Item."Unit of Measure Id", PreviousItem."Unit of Measure Id", 'Mismatch on "Unit of Measure Id"');
        Assert.AreEqual(Item."Tax Group Id", PreviousItem."Tax Group Id", 'Mismatch on "Tax Group Id"');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRelatedRecordIdsAreUpdatedOnAPISetupItem()
    var
        Item: Record Item;
        PreviousItem: Record Item;
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        Initialze();

        // Setup
        CreateItemRunInsertTrigger(Item);
        PreviousItem.Copy(Item);

        Clear(Item."Unit of Measure Id");

        // Execute
        GraphMgtGeneralTools.ApiSetup();

        // Verify
        VerifyItemRelatedRecordIDs(Item);

        Assert.AreEqual(Item."Unit of Measure Id", PreviousItem."Unit of Measure Id", 'Mismatch on "Unit of Measure Id"');
        Assert.AreEqual(Item."Tax Group Id", PreviousItem."Tax Group Id", 'Mismatch on "Tax Group Id"');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesInvoicesAreCreatedOnAPISetup()
    var
        NewSalesInvoiceHeader: Record "Sales Invoice Header";
        NewSalesInvoiceHeader2: Record "Sales Invoice Header";
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        NewSalesHeader: Record "Sales Header";
        NewSalesHeader2: Record "Sales Header";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        Initialze();

        // Setup
        APIMockEvents.SetIsAPIEnabled(false);
        ClearExistingInvoices();

        LibrarySales.CreateSalesInvoice(NewSalesHeader);
        LibrarySales.CreateSalesInvoice(NewSalesHeader2);
        CreatePostedInvoice(NewSalesInvoiceHeader);
        CreatePostedInvoice(NewSalesInvoiceHeader2);
        APIMockEvents.SetIsAPIEnabled(true);

        // Execute
        GraphMgtGeneralTools.ApiSetup();

        // Verify
        Assert.AreEqual(4, SalesInvoiceEntityAggregate.Count, 'Wrong number of Aggregate records found');
        VerifySalesInvoiceAggregateMatchesMainTable(NewSalesHeader);
        VerifySalesInvoiceAggregateMatchesMainTable(NewSalesHeader2);
        VerifySalesInvoiceAggregateMatchesMainTable(NewSalesInvoiceHeader);
        VerifySalesInvoiceAggregateMatchesMainTable(NewSalesInvoiceHeader2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesInvoiceAgregatesAreDeletedOnAPISetup()
    var
        NewSalesInvoiceHeader: Record "Sales Invoice Header";
        NewSalesInvoiceHeader2: Record "Sales Invoice Header";
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        NewSalesHeader: Record "Sales Header";
        NewSalesHeader2: Record "Sales Header";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        Initialze();

        // Setup
        ClearExistingInvoices();

        CreatePostedInvoice(NewSalesInvoiceHeader);
        CreatePostedInvoice(NewSalesInvoiceHeader2);
        LibrarySales.CreateSalesInvoice(NewSalesHeader);
        LibrarySales.CreateSalesInvoice(NewSalesHeader2);

        APIMockEvents.SetIsAPIEnabled(false);
        NewSalesInvoiceHeader2.Delete();
        NewSalesHeader.Delete();
        Assert.IsTrue(
          SalesInvoiceEntityAggregate.Get(NewSalesInvoiceHeader2."No.", true), 'Aggregate record should exist for Posted Invoice');
        Assert.IsTrue(SalesInvoiceEntityAggregate.Get(NewSalesHeader."No.", false), 'Aggregate record should exist for Draft Invoice');
        APIMockEvents.SetIsAPIEnabled(true);

        // Execute
        GraphMgtGeneralTools.ApiSetup();

        // Verify
        Assert.AreEqual(2, SalesInvoiceEntityAggregate.Count, 'Wrong number of Aggregate records found');
        VerifySalesInvoiceAggregateMatchesMainTable(NewSalesHeader2);
        VerifySalesInvoiceAggregateMatchesMainTable(NewSalesInvoiceHeader);

        Assert.IsFalse(
          SalesInvoiceEntityAggregate.Get(NewSalesInvoiceHeader2."No.", true), 'Aggregate record should be deleted for Posted Invoice');
        Assert.IsFalse(
          SalesInvoiceEntityAggregate.Get(NewSalesHeader."No.", false), 'Aggregate record should be deleted for Draft Invoice');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesQuoteEntityBufferRecordsAreCreatedOnAPISetup()
    var
        SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer";
        Customer: Record Customer;
        NewSalesHeader: Record "Sales Header";
        NewSalesHeader2: Record "Sales Header";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        Initialze();

        // Setup
        APIMockEvents.SetIsAPIEnabled(false);
        ClearExistingQuotes();

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesQuoteForCustomerNo(NewSalesHeader, Customer."No.");
        LibrarySales.CreateSalesQuoteForCustomerNo(NewSalesHeader2, Customer."No.");
        APIMockEvents.SetIsAPIEnabled(true);

        // Execute
        GraphMgtGeneralTools.ApiSetup();

        // Verify
        Assert.AreEqual(2, SalesQuoteEntityBuffer.Count, 'Wrong number of Aggregate records found');
        VerifySalesQuoteEntityBufferMatchesMainTable(NewSalesHeader);
        VerifySalesQuoteEntityBufferMatchesMainTable(NewSalesHeader2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesQuoteEntityBufferRecordsAreDeletedOnAPISetup()
    var
        SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer";
        Customer: Record Customer;
        NewSalesHeader: Record "Sales Header";
        NewSalesHeader2: Record "Sales Header";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        Initialze();

        // Setup
        ClearExistingQuotes();

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesQuoteForCustomerNo(NewSalesHeader, Customer."No.");
        LibrarySales.CreateSalesQuoteForCustomerNo(NewSalesHeader2, Customer."No.");
        APIMockEvents.SetIsAPIEnabled(false);

        NewSalesHeader.Delete();
        APIMockEvents.SetIsAPIEnabled(true);

        // Execute
        GraphMgtGeneralTools.ApiSetup();

        // Verify
        Assert.AreEqual(1, SalesQuoteEntityBuffer.Count, 'Wrong number of Aggregate records found');
        Assert.IsFalse(SalesQuoteEntityBuffer.Get(NewSalesHeader."No."), 'Quote entity should have been deleted');
        VerifySalesQuoteEntityBufferMatchesMainTable(NewSalesHeader2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesCreditMemoAggregateRecordsAreCreatedOnAPISetup()
    var
        NewSalesCrMemoHeader: Record "Sales Cr.Memo Header";
        NewSalesCrMemoHeader2: Record "Sales Cr.Memo Header";
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        NewSalesHeader: Record "Sales Header";
        NewSalesHeader2: Record "Sales Header";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        Initialze();

        // Setup
        APIMockEvents.SetIsAPIEnabled(false);
        ClearExistingCreditMemos();

        LibrarySales.CreateSalesCreditMemo(NewSalesHeader);
        LibrarySales.CreateSalesCreditMemo(NewSalesHeader2);
        CreatePostedCreditMemo(NewSalesCrMemoHeader);
        CreatePostedCreditMemo(NewSalesCrMemoHeader2);
        APIMockEvents.SetIsAPIEnabled(true);

        // Execute
        GraphMgtGeneralTools.ApiSetup();

        // Verify
        Assert.AreEqual(4, SalesCrMemoEntityBuffer.Count, 'Wrong number of Aggregate records found');
        VerifySalesCreditMemoAggregateMatchesMainTable(NewSalesHeader);
        VerifySalesCreditMemoAggregateMatchesMainTable(NewSalesHeader2);
        VerifySalesCreditMemoAggregateMatchesMainTable(NewSalesCrMemoHeader);
        VerifySalesCreditMemoAggregateMatchesMainTable(NewSalesCrMemoHeader2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesCreditMemoAggregateRecordsAreDeletedOnAPISetup()
    var
        NewSalesCrMemoHeader: Record "Sales Cr.Memo Header";
        NewSalesCrMemoHeader2: Record "Sales Cr.Memo Header";
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        NewSalesHeader: Record "Sales Header";
        NewSalesHeader2: Record "Sales Header";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        Initialze();

        // Setup
        ClearExistingCreditMemos();

        LibrarySales.CreateSalesCreditMemo(NewSalesHeader);
        LibrarySales.CreateSalesCreditMemo(NewSalesHeader2);
        CreatePostedCreditMemo(NewSalesCrMemoHeader);
        CreatePostedCreditMemo(NewSalesCrMemoHeader2);

        APIMockEvents.SetIsAPIEnabled(false);
        NewSalesCrMemoHeader2.Delete();
        NewSalesHeader.Delete();

        Assert.IsTrue(
          SalesCrMemoEntityBuffer.Get(NewSalesCrMemoHeader2."No.", true), 'Aggregate record should exist for Posted Invoice');
        Assert.IsTrue(SalesCrMemoEntityBuffer.Get(NewSalesHeader."No.", false), 'Aggregate record should exist for Draft Invoice');
        APIMockEvents.SetIsAPIEnabled(true);

        // Execute
        GraphMgtGeneralTools.ApiSetup();

        // Verify
        Assert.AreEqual(2, SalesCrMemoEntityBuffer.Count, 'Wrong number of Aggregate records found');
        VerifySalesCreditMemoAggregateMatchesMainTable(NewSalesHeader2);
        VerifySalesCreditMemoAggregateMatchesMainTable(NewSalesCrMemoHeader);

        Assert.IsFalse(
          SalesCrMemoEntityBuffer.Get(NewSalesCrMemoHeader2."No.", true), 'Aggregate record should be deleted for Posted Invoice');
        Assert.IsFalse(
          SalesCrMemoEntityBuffer.Get(NewSalesHeader."No.", false), 'Aggregate record should be deleted for Draft Invoice');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesOrderBufferRecordsAreCreatedOnAPISetup()
    var
        SalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
        NewSalesHeader: Record "Sales Header";
        NewSalesHeader2: Record "Sales Header";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        Initialze();

        // Setup
        APIMockEvents.SetIsAPIEnabled(false);
        ClearExistingOrders();

        LibrarySales.CreateSalesOrder(NewSalesHeader);
        LibrarySales.CreateSalesOrder(NewSalesHeader2);
        APIMockEvents.SetIsAPIEnabled(true);

        // Execute
        GraphMgtGeneralTools.ApiSetup();

        // Verify
        Assert.AreEqual(2, SalesOrderEntityBuffer.Count, 'Wrong number of Aggregate records found');
        VerifySalesOrderEntityBufferMatchesMainTable(NewSalesHeader);
        VerifySalesOrderEntityBufferMatchesMainTable(NewSalesHeader2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesOrderBufferRecordsAreDeletedOnAPISetup()
    var
        SalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
        NewSalesHeader: Record "Sales Header";
        NewSalesHeader2: Record "Sales Header";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        Initialze();

        // Setup
        APIMockEvents.SetIsAPIEnabled(true);
        ClearExistingOrders();

        LibrarySales.CreateSalesOrder(NewSalesHeader);
        LibrarySales.CreateSalesOrder(NewSalesHeader2);
        APIMockEvents.SetIsAPIEnabled(false);

        NewSalesHeader.Delete();
        APIMockEvents.SetIsAPIEnabled(true);

        // Execute
        GraphMgtGeneralTools.ApiSetup();

        // Verify
        Assert.AreEqual(1, SalesOrderEntityBuffer.Count, 'Wrong number of Aggregate records found');
        Assert.IsFalse(SalesOrderEntityBuffer.Get(NewSalesHeader."No."), 'Order entity should have been deleted');
        VerifySalesOrderEntityBufferMatchesMainTable(NewSalesHeader2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseInvoicesBufferRecordsAreCreatedOnAPISetup()
    var
        NewPurchInvHeader: Record "Purch. Inv. Header";
        NewPurchInvHeader2: Record "Purch. Inv. Header";
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        NewPurchaseHeader: Record "Purchase Header";
        NewPurchaseHeader2: Record "Purchase Header";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        // Setup
        Initialze();
        APIMockEvents.SetIsAPIEnabled(false);
        ClearExistingPurchaseInvoices();

        LibraryPurchase.CreatePurchaseInvoice(NewPurchaseHeader);
        LibraryPurchase.CreatePurchaseInvoice(NewPurchaseHeader2);
        CreatePostedPurchaseInvoice(NewPurchInvHeader);
        CreatePostedPurchaseInvoice(NewPurchInvHeader2);
        APIMockEvents.SetIsAPIEnabled(true);

        // Execute
        GraphMgtGeneralTools.ApiSetup();

        // Verify
        Assert.AreEqual(4, PurchInvEntityAggregate.Count, 'Wrong number of Aggregate records found');
        VerifyPruchaseInvoiceAggregateMatchesMainTable(NewPurchaseHeader);
        VerifyPruchaseInvoiceAggregateMatchesMainTable(NewPurchaseHeader2);
        VerifyPruchaseInvoiceAggregateMatchesMainTable(NewPurchInvHeader);
        VerifyPruchaseInvoiceAggregateMatchesMainTable(NewPurchInvHeader2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseInvoicesBufferRecordsAreDeletedOnAPISetup()
    var
        NewPurchInvHeader: Record "Purch. Inv. Header";
        NewPurchInvHeader2: Record "Purch. Inv. Header";
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        NewPurchaseHeader: Record "Purchase Header";
        NewPurchaseHeader2: Record "Purchase Header";
        GraphMgtGeneralTools: Codeunit "Graph Mgt - General Tools";
    begin
        // Setup
        Initialze();
        ClearExistingPurchaseInvoices();

        LibraryPurchase.CreatePurchaseInvoice(NewPurchaseHeader);
        LibraryPurchase.CreatePurchaseInvoice(NewPurchaseHeader2);
        CreatePostedPurchaseInvoice(NewPurchInvHeader);
        CreatePostedPurchaseInvoice(NewPurchInvHeader2);

        APIMockEvents.SetIsAPIEnabled(false);
        NewPurchInvHeader2.Delete();
        NewPurchaseHeader.Delete();

        Assert.IsTrue(
          PurchInvEntityAggregate.Get(NewPurchInvHeader2."No.", true), 'Aggregate record should exist for Posted Invoice');
        Assert.IsTrue(PurchInvEntityAggregate.Get(NewPurchaseHeader."No.", false), 'Aggregate record should exist for Draft Invoice');
        APIMockEvents.SetIsAPIEnabled(true);

        // Execute
        GraphMgtGeneralTools.ApiSetup();

        // Verify
        Assert.AreEqual(2, PurchInvEntityAggregate.Count, 'Wrong number of Aggregate records found');
        VerifyPruchaseInvoiceAggregateMatchesMainTable(NewPurchaseHeader2);
        VerifyPruchaseInvoiceAggregateMatchesMainTable(NewPurchInvHeader);

        Assert.IsFalse(
          PurchInvEntityAggregate.Get(NewPurchInvHeader2."No.", true), 'Aggregate record should be deleted for Posted Invoice');
        Assert.IsFalse(
          PurchInvEntityAggregate.Get(NewPurchInvHeader."No.", false), 'Aggregate record should be deleted for Draft Invoice');
    end;

    local procedure VerifyCustomerRelatedRecordIDs(var Customer: Record Customer)
    var
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        Currency: Record Currency;
    begin
        Customer.Find();

        Assert.IsTrue(PaymentTerms.Get(Customer."Payment Terms Code"), 'Could not get payment terms');
        Assert.IsTrue(PaymentMethod.Get(Customer."Payment Method Code"), 'Could not get Payment Method');
        Assert.IsTrue(Currency.Get(Customer."Currency Code"), 'Could not get Currency');

        Assert.AreEqual(Customer."Payment Terms Id", PaymentTerms.SystemId, '"Payment Terms Id" was not set');
        Assert.AreEqual(Customer."Payment Method Id", PaymentMethod.SystemId, '"Payment Method Id" was not set');
        Assert.AreEqual(Customer."Currency Id", Currency.SystemId, '"Currency Id" was not set');
    end;

    local procedure VerifyVendorRelatedRecordIDs(var Vendor: Record Vendor)
    var
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        Currency: Record Currency;
    begin
        Vendor.Find();

        Assert.IsTrue(PaymentTerms.Get(Vendor."Payment Terms Code"), 'Could not get payment terms');
        Assert.IsTrue(PaymentMethod.Get(Vendor."Payment Method Code"), 'Could not get Payment Method');
        Assert.IsTrue(Currency.Get(Vendor."Currency Code"), 'Could not get Currency');

        Assert.AreEqual(Vendor."Payment Terms Id", PaymentTerms.SystemId, '"Payment Terms Id" was not set');
        Assert.AreEqual(Vendor."Payment Method Id", PaymentMethod.SystemId, '"Payment Method Id" was not set');
        Assert.AreEqual(Vendor."Currency Id", Currency.SystemId, '"Currency Id" was not set');
    end;

    local procedure VerifyItemRelatedRecordIDs(var Item: Record Item)
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        Item.Find();

        Assert.IsTrue(UnitOfMeasure.Get(Item."Base Unit of Measure"), 'Could not get "Base Unit of Measure"');

        Assert.AreEqual(Item."Unit of Measure Id", UnitOfMeasure.SystemId, '"Unit of Measure Id" was not set');
    end;

    local procedure CreatePostedInvoice(var SalesInvoiceHeader: Record "Sales Invoice Header")
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePostedCreditMemo(var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesCreditMemo(SalesHeader);
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePostedPurchaseInvoice(var PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure VerifySalesInvoiceAggregateMatchesMainTable(ExpectedRecord: Variant)
    var
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
        DummySalesHeader: Record "Sales Header";
        DummySalesInvoiceHeader: Record "Sales Invoice Header";
        DataTypeManagement: Codeunit "Data Type Management";
        SourceRecordRef: RecordRef;
        NoFieldRef: FieldRef;
        IdFieldRef: FieldRef;
        DraftInvoiceFieldRef: FieldRef;
        Posted: Boolean;
    begin
        SourceRecordRef.GetTable(ExpectedRecord);

        case SourceRecordRef.Number of
            DATABASE::"Sales Header":
                Posted := false;
            DATABASE::"Sales Invoice Header":
                Posted := true;
            else
                Assert.Fail('Test error, wrong record used ' + Format(SourceRecordRef.Number));
        end;

        DataTypeManagement.FindFieldByName(SourceRecordRef, NoFieldRef, DummySalesHeader.FieldName("No."));
        Assert.IsTrue(SalesInvoiceEntityAggregate.Get(NoFieldRef.Value, Posted), 'Could not find the Aggregate record');

        if Posted = false then begin
            DataTypeManagement.FindFieldByName(SourceRecordRef, IdFieldRef, DummySalesHeader.FieldName(SystemId));
            Assert.AreEqual(
                Format(IdFieldRef.Value), Format(SalesInvoiceEntityAggregate.Id), 'Integration Id was not set on the source record');
        end else begin
            DataTypeManagement.FindFieldByName(SourceRecordRef, DraftInvoiceFieldRef, DummySalesInvoiceHeader.FieldName("Draft Invoice SystemId"));
            if (not IsNullGuid((DraftInvoiceFieldRef.Value))) then
                Assert.AreEqual(
                    Format(DraftInvoiceFieldRef.Value), Format(SalesInvoiceEntityAggregate.Id), 'Integration Id must be set to the value from the draft')
            else begin
                DataTypeManagement.FindFieldByName(SourceRecordRef, IdFieldRef, DummySalesHeader.FieldName(SystemId));
                Assert.AreEqual(
                    Format(IdFieldRef.Value), Format(SalesInvoiceEntityAggregate.Id), 'Integration Id was not set on the source record');
            end;
        end;
    end;

    local procedure VerifySalesQuoteEntityBufferMatchesMainTable(ExpectedRecord: Variant)
    var
        SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer";
        DummySalesHeader: Record "Sales Header";
        DataTypeManagement: Codeunit "Data Type Management";
        SourceRecordRef: RecordRef;
        NoFieldRef: FieldRef;
        IdFieldRef: FieldRef;
    begin
        SourceRecordRef.GetTable(ExpectedRecord);

        DataTypeManagement.FindFieldByName(SourceRecordRef, NoFieldRef, DummySalesHeader.FieldName("No."));
        Assert.IsTrue(SalesQuoteEntityBuffer.Get(NoFieldRef.Value), 'Could not find the Aggregate record');

        DataTypeManagement.FindFieldByName(SourceRecordRef, IdFieldRef, DummySalesHeader.FieldName(SystemId));
        Assert.AreEqual(
          Format(IdFieldRef.Value), Format(SalesQuoteEntityBuffer.Id), 'Integration Id was not set on the source record');
    end;

    local procedure VerifySalesCreditMemoAggregateMatchesMainTable(ExpectedRecord: Variant)
    var
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
        DummySalesHeader: Record "Sales Header";
        DummySalesCrMemoHeader: Record "Sales Cr.Memo Header";
        DataTypeManagement: Codeunit "Data Type Management";
        SourceRecordRef: RecordRef;
        NoFieldRef: FieldRef;
        IdFieldRef: FieldRef;
        Posted: Boolean;
    begin
        SourceRecordRef.GetTable(ExpectedRecord);

        case SourceRecordRef.Number of
            DATABASE::"Sales Header":
                Posted := false;
            DATABASE::"Sales Cr.Memo Header":
                Posted := true;
            else
                Assert.Fail('Test error, wrong record used ' + Format(SourceRecordRef.Number));
        end;

        DataTypeManagement.FindFieldByName(SourceRecordRef, NoFieldRef, DummySalesHeader.FieldName("No."));
        Assert.IsTrue(SalesCrMemoEntityBuffer.Get(NoFieldRef.Value, Posted), 'Could not find the Aggregate record');

        if Posted then begin
            DataTypeManagement.FindFieldByName(SourceRecordRef, IdFieldRef, DummySalesCrMemoHeader.FieldName("Draft Cr. Memo SystemId"));
            if IsNullGuid(IdFieldRef.Value) then
                DataTypeManagement.FindFieldByName(SourceRecordRef, IdFieldRef, DummySalesCrMemoHeader.FieldName(SystemId));

            Assert.AreEqual(
  Format(IdFieldRef.Value), Format(SalesCrMemoEntityBuffer.Id), 'Integration Id was not set on the source record');
        end else begin
            DataTypeManagement.FindFieldByName(SourceRecordRef, IdFieldRef, DummySalesHeader.FieldName(SystemId));
            Assert.AreEqual(
              Format(IdFieldRef.Value), Format(SalesCrMemoEntityBuffer.Id), 'Integration Id was not set on the source record');
        end;
    end;

    local procedure VerifySalesOrderEntityBufferMatchesMainTable(ExpectedRecord: Variant)
    var
        SalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
        DummySalesHeader: Record "Sales Header";
        DataTypeManagement: Codeunit "Data Type Management";
        SourceRecordRef: RecordRef;
        NoFieldRef: FieldRef;
        IdFieldRef: FieldRef;
    begin
        SourceRecordRef.GetTable(ExpectedRecord);

        DataTypeManagement.FindFieldByName(SourceRecordRef, NoFieldRef, DummySalesHeader.FieldName("No."));
        Assert.IsTrue(SalesOrderEntityBuffer.Get(NoFieldRef.Value), 'Could not find the Aggregate record');

        DataTypeManagement.FindFieldByName(SourceRecordRef, IdFieldRef, DummySalesHeader.FieldName(SystemId));
        Assert.AreEqual(
          Format(IdFieldRef.Value), Format(SalesOrderEntityBuffer.Id), 'Integration Id was not set on the source record');
    end;

    local procedure VerifyPruchaseInvoiceAggregateMatchesMainTable(ExpectedRecord: Variant)
    var
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
        DummySalesHeader: Record "Sales Header";
        DummyPurchInvHeader: Record "Purch. Inv. Header";
        DataTypeManagement: Codeunit "Data Type Management";
        SourceRecordRef: RecordRef;
        NoFieldRef: FieldRef;
        IdFieldRef: FieldRef;
        Posted: Boolean;
    begin
        SourceRecordRef.GetTable(ExpectedRecord);

        case SourceRecordRef.Number of
            DATABASE::"Purchase Header":
                Posted := false;
            DATABASE::"Purch. Inv. Header":
                Posted := true;
            else
                Assert.Fail('Test error, wrong record used ' + Format(SourceRecordRef.Number));
        end;

        DataTypeManagement.FindFieldByName(SourceRecordRef, NoFieldRef, DummySalesHeader.FieldName("No."));
        Assert.IsTrue(PurchInvEntityAggregate.Get(NoFieldRef.Value, Posted), 'Could not find the Aggregate record');

        if Posted then begin
            DataTypeManagement.FindFieldByName(SourceRecordRef, IdFieldRef, DummyPurchInvHeader.FieldName("Draft Invoice SystemId"));
            if IsNullGuid(IdFieldRef.Value) then
                DataTypeManagement.FindFieldByName(SourceRecordRef, IdFieldRef, DummyPurchInvHeader.FieldName(SystemId));

            Assert.AreEqual(
              Format(IdFieldRef.Value), Format(PurchInvEntityAggregate.Id), 'Integration Id was not set on the source record');
        end else begin
            DataTypeManagement.FindFieldByName(SourceRecordRef, IdFieldRef, DummySalesHeader.FieldName(SystemId));
            Assert.AreEqual(
              Format(IdFieldRef.Value), Format(PurchInvEntityAggregate.Id), 'Integration Id was not set on the source record');
        end;
    end;

    local procedure ClearExistingPurchaseInvoices()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvEntityAggregate: Record "Purch. Inv. Entity Aggregate";
    begin
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Invoice);
        PurchaseHeader.DeleteAll();
        PurchInvHeader.DeleteAll();
        PurchInvEntityAggregate.DeleteAll();
    end;

    local procedure ClearExistingInvoices()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceEntityAggregate: Record "Sales Invoice Entity Aggregate";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.DeleteAll();
        SalesInvoiceHeader.DeleteAll();
        SalesInvoiceEntityAggregate.DeleteAll();
    end;

    local procedure ClearExistingQuotes()
    var
        SalesHeader: Record "Sales Header";
        SalesQuoteEntityBuffer: Record "Sales Quote Entity Buffer";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Quote);
        SalesHeader.DeleteAll();
        SalesQuoteEntityBuffer.DeleteAll();
    end;

    local procedure ClearExistingOrders()
    var
        SalesHeader: Record "Sales Header";
        SalesOrderEntityBuffer: Record "Sales Order Entity Buffer";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.DeleteAll();
        SalesOrderEntityBuffer.DeleteAll();
    end;

    local procedure ClearExistingCreditMemos()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoEntityBuffer: Record "Sales Cr. Memo Entity Buffer";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.DeleteAll();
        SalesCrMemoHeader.DeleteAll();
        SalesCrMemoEntityBuffer.DeleteAll();
    end;

    local procedure CreateCustomerRunInsertTrigger(var Customer: Record Customer)
    begin
        Customer.Init();
        SetReferencedRecordCodesOnCustomer(Customer);
        Customer.Insert(true);
    end;

    local procedure SetReferencedRecordCodesOnCustomer(var Customer: Record Customer)
    var
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        Currency: Record Currency;
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        LibraryERM.CreateCurrency(Currency);

        Customer."Payment Terms Code" := PaymentTerms.Code;
        Customer."Payment Method Code" := PaymentMethod.Code;
        Customer."Currency Code" := Currency.Code;
    end;

    local procedure CreateVendorRunInsertTrigger(var Vendor: Record Vendor)
    begin
        Vendor.Init();
        SetReferencedRecordCodesOnVendor(Vendor);
        Vendor.Insert(true);
    end;

    local procedure SetReferencedRecordCodesOnVendor(var Vendor: Record Vendor)
    var
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        Currency: Record Currency;
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        LibraryERM.CreateCurrency(Currency);

        Vendor."Payment Terms Code" := PaymentTerms.Code;
        Vendor."Payment Method Code" := PaymentMethod.Code;
        Vendor."Currency Code" := Currency.Code;
    end;

    local procedure CreateItemRunInsertTrigger(var Item: Record Item)
    begin
        Item.Init();
        SetReferencedRecordCodesOnItem(Item);
        Item.Insert(true);
    end;

    local procedure SetReferencedRecordCodesOnItem(var Item: Record Item)
    var
        UnitOfMeasure: Record "Unit of Measure";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        Item."Base Unit of Measure" := UnitOfMeasure.Code;
    end;
}

