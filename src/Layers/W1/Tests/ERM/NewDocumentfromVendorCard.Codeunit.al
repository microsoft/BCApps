codeunit 134770 "New Document from Vendor Card"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Vendor] [UI]
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryMarketing: codeunit "Library - Marketing";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        isInitialized: Boolean;
        VendorNoForEventSubscriber: Code[20];

    [Test]
    [Scope('OnPrem')]
    procedure NewBlanketPurchaseOrderFromVendor()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
    begin
        // Setup
        Initialize();
        LibraryPurchase.CreateVendorWithAddress(Vendor);

        // Execute
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);

        BlanketPurchaseOrder.Trap();
        VendorCard.NewBlanketPurchaseOrder.Invoke();

        // Verification
        Assert.AreEqual(Vendor.Name, BlanketPurchaseOrder."Buy-from Vendor Name".Value, 'Vendor name is not carried over to the document');
        Assert.AreEqual(
          Vendor.Address, BlanketPurchaseOrder."Buy-from Address".Value, 'Vendor address is not carried over to the document');
        Assert.AreEqual(Vendor."Post Code", BlanketPurchaseOrder."Buy-from Post Code".Value,
          'Vendor postcode is not carried over to the document');
        Assert.AreEqual(
          Vendor.Contact, BlanketPurchaseOrder."Buy-from Contact".Value, 'Vendor contact is not carried over to the document');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseQuoteFromVendor()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // Setup
        Initialize();
        LibraryPurchase.CreateVendorWithAddress(Vendor);

        // Execute
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);

        PurchaseQuote.Trap();
        VendorCard.NewPurchaseQuote.Invoke();

        // Verification
        Assert.AreEqual(Vendor.Name, PurchaseQuote."Buy-from Vendor Name".Value, 'Vendor name is not carried over to the document');
        Assert.AreEqual(Vendor.Address, PurchaseQuote."Buy-from Address".Value, 'Vendor address is not carried over to the document');
        Assert.AreEqual(Vendor."Post Code", PurchaseQuote."Buy-from Post Code".Value,
          'Vendor postcode is not carried over to the document');
        Assert.AreEqual(Vendor.Contact, PurchaseQuote."Buy-from Contact".Value, 'Vendor contact is not carried over to the document');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseInvoiceFromVendor()
    var
        Vendor: Record Vendor;
        DummyPurchaseHeader: Record "Purchase Header";
        VendorCard: TestPage "Vendor Card";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // Setup
        Initialize();
        LibraryPurchase.CreateVendorWithAddress(Vendor);

        // Execute
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);

        PurchaseInvoice.Trap();
        VendorCard.NewPurchaseInvoice.Invoke();

        // Verification
        VerifyBillToAddressOnPurchaseInvoiceIsVendorAddress(PurchaseInvoice, Vendor);

        PurchaseInvoice."Vendor Invoice No.".SetValue(
          LibraryUtility.GenerateRandomText(MaxStrLen(DummyPurchaseHeader."Vendor Invoice No.")));
        PurchaseInvoice.Close();

        // Execute
        PurchaseInvoice.Trap();
        VendorCard.NewPurchaseInvoice.Invoke();

        // Verification
        VerifyBillToAddressOnPurchaseInvoiceIsVendorAddress(PurchaseInvoice, Vendor);
    end;

    local procedure VerifyBillToAddressOnPurchaseInvoiceIsVendorAddress(PurchaseInvoice: TestPage "Purchase Invoice"; Vendor: Record Vendor)
    begin
        PurchaseInvoice."Buy-from Vendor Name".AssertEquals(Vendor.Name);
        PurchaseInvoice."Buy-from Address".AssertEquals(Vendor.Address);
        PurchaseInvoice."Buy-from Post Code".AssertEquals(Vendor."Post Code");
        PurchaseInvoice."Buy-from Contact".AssertEquals(Vendor.Contact);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseOrderFromVendor()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // Setup
        Initialize();
        LibraryPurchase.CreateVendorWithAddress(Vendor);

        // Execute
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);

        PurchaseOrder.Trap();
        VendorCard.NewPurchaseOrder.Invoke();

        // Verification
        Assert.AreEqual(Vendor.Name, PurchaseOrder."Buy-from Vendor Name".Value, 'Vendor name is not carried over to the document');
        Assert.AreEqual(Vendor.Address, PurchaseOrder."Buy-from Address".Value, 'Vendor address is not carried over to the document');
        Assert.AreEqual(Vendor."Post Code", PurchaseOrder."Buy-from Post Code".Value,
          'Vendor postcode is not carried over to the document');
        Assert.AreEqual(Vendor.Contact, PurchaseOrder."Buy-from Contact".Value, 'Vendor contact is not carried over to the document');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseCreditMemoFromVendor()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // Setup
        Initialize();
        LibraryPurchase.CreateVendorWithAddress(Vendor);

        // Execute
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);

        PurchaseCreditMemo.Trap();
        VendorCard.NewPurchaseCrMemo.Invoke();

        // Verification
        Assert.AreEqual(Vendor.Name, PurchaseCreditMemo."Buy-from Vendor Name".Value, 'Vendor name is not carried over to the document');
        Assert.AreEqual(Vendor.Address, PurchaseCreditMemo."Buy-from Address".Value, 'Vendor address is not carried over to the document');
        Assert.AreEqual(Vendor."Post Code", PurchaseCreditMemo."Buy-from Post Code".Value,
          'Vendor postcode is not carried over to the document');
        Assert.AreEqual(Vendor.Contact, PurchaseCreditMemo."Buy-from Contact".Value, 'Vendor contact is not carried over to the document');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewPurchaseReturnOrderFromVendor()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // Setup
        Initialize();
        LibraryPurchase.CreateVendorWithAddress(Vendor);

        // Execute
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);

        PurchaseReturnOrder.Trap();
        VendorCard.NewPurchaseReturnOrder.Invoke();

        // Verification
        Assert.AreEqual(Vendor.Name, PurchaseReturnOrder."Buy-from Vendor Name".Value, 'Vendor name is not carried over to the document');
        Assert.AreEqual(
          Vendor.Address, PurchaseReturnOrder."Buy-from Address".Value, 'Vendor address is not carried over to the document');
        Assert.AreEqual(Vendor."Post Code", PurchaseReturnOrder."Buy-from Post Code".Value,
          'Vendor postcode is not carried over to the document');
        Assert.AreEqual(
          Vendor.Contact, PurchaseReturnOrder."Buy-from Contact".Value, 'Vendor contact is not carried over to the document');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrdersFromVendorCard_CreateNewOrderFromPurchaseOrderList_AutomaticOrderNos()
    var
        Vendor: Record Vendor;
        NewDocumentFromVendorCard: Codeunit "New Document from Vendor Card";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO 504336] Simulate the scenario where new purchase order is created from the vendor card via Purchase Order list and New action.
        // [SCENARIO 504336] No. of Purchase Order is automatically assigned, so it is not visible in the page.
        Initialize();

        BindSubscription(NewDocumentFromVendorCard); // Uses OnOpenPurchaseOrder event subscriber to simulate page filters.

        // [GIVEN] Create Vendor.
        LibraryPurchase.CreateVendor(Vendor);
        NewDocumentFromVendorCard.SetVendorNoForEventSubscriber(Vendor); // Set Vendor No. for event subscriber to simulate page filters.

        // [GIVEN] Create New Purchase Order, with "Buy-from Vendor No." filter in filtergroup = 2 to simulate page filters.
        PurchaseOrder.OpenNew();

        // [WHEN] Set any field on the page to insert record.
        PurchaseOrder."Buy-from Address".SetValue(Vendor.Address);

        // [THEN] Vendor No. and Vendor Name are carried over to the document
        Assert.AreEqual(Vendor."No.", PurchaseOrder."Buy-from Vendor No.".Value(), 'Vendor No. is not carried over to the document');
        Assert.AreEqual(Vendor.Name, PurchaseOrder."Buy-from Vendor Name".Value(), 'Vendor Name is not carried over to the document');

        UnbindSubscription(NewDocumentFromVendorCard);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrdersFromVendorCard_CreateNewOrderFromPurchaseOrderList_ManualOrderNos()
    var
        Vendor: Record Vendor;
        NewDocumentFromVendorCard: Codeunit "New Document from Vendor Card";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO 504336] Simulate the scenario where new purchase order is created from the vendor card via Purchase Order list and New action.
        // [SCENARIO 504336] No. of Purchase Order can be manually set, so it is visible in the page.
        Initialize();

        // [GIVEN] Set Manual Nos. on Purchase Order No. Series
        UpdateManualNosOnPurchaseOrderNoSeries(true);

        BindSubscription(NewDocumentFromVendorCard); // Uses OnOpenPurchaseOrder event subscriber to simulate page filters.

        // [GIVEN] Create Vendor.
        LibraryPurchase.CreateVendor(Vendor);
        NewDocumentFromVendorCard.SetVendorNoForEventSubscriber(Vendor); // Set Vendor No. for event subscriber to simulate page filters.

        // [GIVEN] Create New Purchase Order, with "Buy-from Vendor No." filter in filtergroup = 2 to simulate page filters.
        PurchaseOrder.OpenNew();

        // [WHEN] Set any field on the page to insert record.
        PurchaseOrder."Buy-from Address".SetValue(Vendor.Address);

        // [THEN] Vendor No. and Vendor Name are carried over to the document
        Assert.AreEqual(Vendor."No.", PurchaseOrder."Buy-from Vendor No.".Value(), 'Vendor No. is not carried over to the document');
        Assert.AreEqual(Vendor.Name, PurchaseOrder."Buy-from Vendor Name".Value(), 'Vendor Name is not carried over to the document');

        UnbindSubscription(NewDocumentFromVendorCard);
        UpdateManualNosOnPurchaseOrderNoSeries(false);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ContactListRunModal,VendorLinkPageHandler')]
    procedure ContactHasCompanyNoFilledWhenCreatedFromPrimaryContactNoOfVendor()
    var
        BusinessRelation: Record "Business Relation";
        Vendor: Record Vendor;
        Contact: Record Contact;
        VendorCard: TestPage "Vendor Card";
    begin
        // [SCENARIO 525453] When Contact is created from Primary Contact No. field of a Vendor, it will already have a value in Company No. field.
        Initialize();

        // [GIVEN] Create Business Relation.
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);

        // [GIVEN] Change Business Relation Code to blank for Vendors.
        ChangeBusinessRelationCodeForVendors('');

        // [GIVEN] Create a Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Changes Business Relation Code for Vendors.
        LibraryVariableStorage.Enqueue(Vendor."No.");
        ChangeBusinessRelationCodeForVendors(BusinessRelation.Code);

        // [GIVEN] Create a Company Contact.
        LibraryMarketing.CreateCompanyContact(Contact);

        // [GIVEN] Create Vendor Link.
        Contact.CreateVendorLink();

        // [WHEN] Open Vendor Card page and run Lookup of Primary Contact No.
        VendorCard.OpenEdit();
        VendorCard.GoToRecord(Vendor);
        VendorCard."Primary Contact No.".Lookup();

        // [THEN] Company No. in Contact Card has a value in ContactListRunModal.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultRemitToCodeIsPopulatedInPurchInvWhenCreatedFromVendorCard()
    var
        Vendor: Record Vendor;
        NoSeries: Record "No. Series";
        PostCode: Record "Post Code";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        RemitAddress: Record "Remit Address";
        PurchaseInvoice: TestPage "Purchase Invoice";
        VendorCard: TestPage "Vendor Card";
    begin
        // [SCENARIO 565861] Remit-to Code on Purchase Invoice is poplulated from default 
        // Remit Address of Vendor when create a new Purchase Invoice from Vendor Card page.
        Initialize();

        // [GIVEN] Find Purchase & Payables Setup and Validate Invoice Nos.
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Invoice Nos." := LibraryERM.CreateNoSeriesCode();
        PurchasesPayablesSetup.Modify(true);

        // [GIVEN] Find No. Series and Validate Manual Nos. and Default Nos.
        NoSeries.Get(PurchasesPayablesSetup."Invoice Nos.");
        NoSeries.Validate("Manual Nos.", true);
        NoSeries.Validate("Default Nos.", true);
        NoSeries.Modify(true);

        // [GIVEN] Create a Post Code.
        LibraryERM.CreatePostCode(PostCode);

        // [GIVEN] Create a Vendor with Address.
        LibraryPurchase.CreateVendorWithAddress(Vendor);

        // [GIVEN] Create a Remit-to Address and Validate Address, Post Code and Default.
        LibraryPurchase.CreateRemitToAddress(RemitAddress, Vendor."No.");
        RemitAddress.Validate(Address, LibraryUtility.GenerateRandomCode20(Vendor.FieldNo("No."), DATABASE::Vendor));
        RemitAddress.Validate("Post Code", PostCode.Code);
        RemitAddress.Validate(Default, true);
        RemitAddress.Modify(true);

        // [GIVEN] Open Vendor Card page.
        VendorCard.OpenEdit();
        VendorCard.GoToRecord(Vendor);

        // [GIVEN] Run New Purchase Invoice action.
        PurchaseInvoice.Trap();
        VendorCard.NewPurchaseInvoice.Invoke();

        // [WHEN] Set value in No. and Buy-from Vendor No. in Purchase Invoice.
        PurchaseInvoice."No.".SetValue(LibraryUtility.GenerateRandomCode20(Vendor.FieldNo("No."), DATABASE::Vendor));
        PurchaseInvoice."Buy-from Vendor No.".SetValue(Vendor."No.");

        // [THEN] Verify Remit-to Code on Purchase Invoice is equal to Code of RemitAddress.
        PurchaseInvoice."Remit-to Code".AssertEquals(RemitAddress.Code);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"New Document from Vendor Card");

        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"New Document from Vendor Card");

        Commit();
        isInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"New Document from Vendor Card");
    end;

    local procedure UpdateManualNosOnPurchaseOrderNoSeries(ManualNos: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        NoSeries: Record "No. Series";
    begin
        PurchasesPayablesSetup.Get();
        NoSeries.Get(PurchasesPayablesSetup."Order Nos.");
        NoSeries.Validate("Manual Nos.", ManualNos);
        NoSeries.Modify(true);
    end;

    local procedure ChangeBusinessRelationCodeForVendors(BusRelCodeForVendors: Code[10]) OriginalBusRelCodeForVendors: Code[10]
    var
        MarketingSetup: Record "Marketing Setup";
    begin
        MarketingSetup.Get();
        OriginalBusRelCodeForVendors := MarketingSetup."Bus. Rel. Code for Vendors";
        MarketingSetup.Validate("Bus. Rel. Code for Vendors", BusRelCodeForVendors);
        MarketingSetup.Modify(true);
    end;

    internal procedure SetVendorNoForEventSubscriber(Vendor: Record Vendor)
    begin
        VendorNoForEventSubscriber := Vendor."No.";
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VendorLinkPageHandler(var VendorLink: TestPage "Vendor Link")
    var
        CurrMasterFields: Option Contact,Vendor;
    begin
        VendorLink."No.".SetValue(LibraryVariableStorage.DequeueText());
        VendorLink.CurrMasterFields.SetValue(CurrMasterFields::Vendor);
        VendorLink.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContactListRunModal(var ContactList: TestPage "Contact List")
    var
        ContactCard: TestPage "Contact Card";
    begin
        ContactCard.OpenView();
        ContactCard.Filter.SetFilter("Company No.", ContactList."No.".Value);
        ContactCard.New();
        LibraryVariableStorage.Enqueue(ContactList."No.");
        LibraryVariableStorage.Enqueue(ContactCard."Company No.");
        ContactCard."Company No.".AssertEquals(ContactList."No.");
    end;

    [EventSubscriber(ObjectType::Page, Page::"Purchase Order", 'OnOpenPageEvent', '', false, false)]
    local procedure OnOpenPurchaseOrder(var Rec: Record "Purchase Header")
    begin
        Rec.FilterGroup(2);
        Rec.SetRange("Document Type", Rec."Document Type"::Order);
        Rec.SetRange("Buy-from Vendor No.", VendorNoForEventSubscriber);
        Rec.FilterGroup(0);
    end;
}

