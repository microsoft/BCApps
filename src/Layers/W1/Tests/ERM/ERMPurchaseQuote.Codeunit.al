codeunit 134325 "ERM Purchase Quote"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Quote] [Purchase]
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryMarketing: Codeunit "Library - Marketing";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryResource: Codeunit "Library - Resource";
        IsInitialized: Boolean;
        AmountErrorMessage: Label '%1 must be %2 in %3.';
        FieldError: Label '%1 not updated correctly.';
        ContactShouldNotBeEditableErr: Label 'Contact should not be editable when vendor is not selected.';
        ContactShouldBeEditableErr: Label 'Contact should be editable when vendorr is selected.';
        PayToAddressFieldsNotEditableErr: Label 'Pay-to address fields should not be editable.';
        PayToAddressFieldsEditableErr: Label 'Pay-to address fields should be editable.';
        MakeOrderQst: Label 'Do you want to convert the quote to an order?';
        OpenNewOrderTxt: Label 'The quote has been converted to order', Comment = '%1 - No. of new purchase order.';
        QuoteNoErr: Label 'Quote No. %1 must be in %2.', Comment = '%1= Quote No. Value, %2= Table Name.';

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseQuoteCreation()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Test that a Purchase Quote Header and Lines exist after Purchase Quote creation.

        // Setup.
        Initialize();

        // Exercise: Create Purchase Quote.
        CreatePurchaseQuote(PurchaseHeader, PurchaseLine, CreateVendor());

        // Verify: Verify that Correct Purchase Quote created.
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Quote, PurchaseHeader."No.");
        PurchaseLine.Get(PurchaseLine."Document Type"::Quote, PurchaseLine."Document No.", PurchaseLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountOnPurchaseQuote()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATAmountLine: Record "VAT Amount Line";
        QtyType: Option General,Invoicing,Shipping;
    begin
        // Test VAT Amount calculated correctly on Purchase Quote.

        // Setup: Create a Purchase Quote.
        Initialize();
        CreatePurchaseQuote(PurchaseHeader, PurchaseLine, CreateVendor());

        // Exercise: Calculate VAT Amount on VAT Amount Line from Purchase Line.
        PurchaseLine.CalcVATAmountLines(QtyType::Invoicing, PurchaseHeader, PurchaseLine, VATAmountLine);

        // Verify: Verify VAT Amount on Purchase Quote.
        GeneralLedgerSetup.Get();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PurchaseHeader.CalcFields(Amount);
        Assert.AreNearlyEqual(
          PurchaseHeader.Amount * PurchaseLine."VAT %" / 100, VATAmountLine."VAT Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErrorMessage, VATAmountLine.FieldCaption("VAT Amount"), PurchaseHeader.Amount * PurchaseLine."VAT %" / 100,
            VATAmountLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseQuoteReport()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseQuote: Report "Purchase - Quote";
        LibraryUtilityOnPrem: Codeunit "Library - Utility OnPrem";
        FilePath: Text[1024];
    begin
        // Test that a Report generated from Purchase Quote.

        // Setup: Create a Purchase Quote.
        Initialize();
        CreatePurchaseQuote(PurchaseHeader, PurchaseLine, CreateVendor());

        // Exercise: Generate Purchase Quote Report and save it as external file.
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Quote);
        PurchaseHeader.SetRange("No.", PurchaseHeader."No.");
        PurchaseQuote.SetTableView(PurchaseHeader);
        FilePath := TemporaryPath + Format(PurchaseHeader."Document Type") + PurchaseHeader."No." + '.xlsx';
        PurchaseQuote.SaveAsExcel(FilePath);

        // Verify: Verify that saved files have some data.
        LibraryUtilityOnPrem.CheckFileNotEmpty(FilePath);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderFromPurchaseQuote()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineCount: Integer;
    begin
        // Test that a Purchase Order created from Purchase Quote.

        // Setup: Create Purchase Quote and save the line count into a variable.
        Initialize();
        CreatePurchaseQuote(PurchaseHeader, PurchaseLine, CreateVendor());
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Quote);
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        LineCount := PurchaseLine.Count();

        // Exercise: Create Purchase Order form Purchase Quote.
        CODEUNIT.Run(CODEUNIT::"Purch.-Quote to Order", PurchaseHeader);

        // Verify: Verify that New Purchase Order created from Purchase Quote and No. of Lines are equal to Purchase Quote Lines.
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.");
        Assert.AreEqual(LineCount, PurchaseLine.Count, 'No. of Lines must be Equal.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseQuoteForContact()
    var
        PurchaseHeader: Record "Purchase Header";
        ContactBusinessRelation: Record "Contact Business Relation";
        Contact: Record Contact;
        BusinessRelation: Record "Business Relation";
    begin
        // Test that a Purchase Quote can be created for a Contact.

        // Setup:  Find a Contact Business Relation.
        Initialize();
        LibraryMarketing.CreateCompanyContact(Contact);
        LibraryMarketing.CreateBusinessRelation(BusinessRelation);
        LibraryMarketing.CreateContactBusinessRelation(ContactBusinessRelation, Contact."No.", BusinessRelation.Code);
        ContactBusinessRelation.Validate("Link to Table", ContactBusinessRelation."Link to Table"::Vendor);
        ContactBusinessRelation.Validate("No.", LibraryPurchase.CreateVendorNo());
        ContactBusinessRelation.Modify(true);

        // Exercise: Create a Purchase Quote for the Contact.
        PurchaseHeader.Insert(true);
        PurchaseHeader.Validate("Buy-from Contact No.", ContactBusinessRelation."Contact No.");
        PurchaseHeader.Modify(true);

        // Verify: Verify that the Purchase Header Contains the correct Contact.
        Assert.AreEqual(
          ContactBusinessRelation."Contact No.",
          PurchaseHeader."Buy-from Contact No.", StrSubstNo(FieldError, PurchaseHeader.FieldCaption("Buy-from Contact No.")));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ChangeVendorOnPurchaseQuote()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Test the Buy From Vendor No. after changing it on Purchase Quote.

        // Setup: Create a Purchase Quote.
        Initialize();
        CreatePurchaseQuote(PurchaseHeader, PurchaseLine, CreateVendor());

        // Exercise: Change the Buy From Vendor No. of Purchase Quote.
        PurchaseHeader.Validate("Buy-from Vendor No.", CreateVendor());
        PurchaseHeader.Modify(true);

        // Verify: Verify that correct Buy From Vendor No. updated in Purchase Line table.
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        Assert.AreEqual(
          PurchaseHeader."Buy-from Vendor No.", PurchaseLine."Buy-from Vendor No.",
          StrSubstNo(FieldError, PurchaseLine.FieldCaption("Buy-from Vendor No.")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderInvDiscFrmPurchQuote()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        InvDiscountAmount: Decimal;
    begin
        // Check Invoice Discount has been flow correctly on Purchase Order after Make Order from Purchase Quote.

        // Setup: Create Purchase Quote and Calculate Invoice Discount.
        Initialize();
        CreatePurchaseQuote(PurchaseHeader, PurchaseLine, CreateVendorInvDiscount(CreateVendor()));
        CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", PurchaseLine);
        PurchaseLine.Get(PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine."Line No.");
        InvDiscountAmount := PurchaseLine."Inv. Discount Amount";

        // Exercise: Create Purchase Order form Purchase Quote.
        CODEUNIT.Run(CODEUNIT::"Purch.-Quote to Order", PurchaseHeader);

        // Verify: Verify Invoice Discount Amount on Create Purchase Order.
        GeneralLedgerSetup.Get();
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.");
        Assert.AreNearlyEqual(
          InvDiscountAmount, PurchaseLine."Inv. Discount Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErrorMessage, PurchaseLine.FieldCaption("Inv. Discount Amount"), InvDiscountAmount, PurchaseLine.TableCaption()));
    end;
#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseQuoteStatisticsHandler')]
    [Scope('OnPrem')]
    procedure VATAmountNonEditableOnStatistics()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // Check that field 'VAT Amount' is not editable on Purchase Quote Statistics page.

        // Setup: Create Purchase Quote.
        Initialize();
        CreatePurchaseQuote(PurchaseHeader, PurchaseLine, CreateVendor());
        PurchaseQuote.OpenEdit();
        PurchaseQuote.FILTER.SetFilter("No.", PurchaseHeader."No.");

        // Exercise: Open Statistics page from Purchase Quote.
        PurchaseQuote.Statistics.Invoke();

        // Verify: Verification is done in 'PurchaseQuoteStatisticsHandler' handler method.
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseQuotePurchaseStatisticsHandler')]
    [Scope('OnPrem')]
    procedure VATAmountNonEditableOnPurchaseStatistics()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // Check that field 'VAT Amount' is not editable on Purchase Quote Statistics page.

        // Setup: Create Purchase Quote.
        Initialize();
        CreatePurchaseQuote(PurchaseHeader, PurchaseLine, CreateVendor());
        PurchaseQuote.OpenEdit();
        PurchaseQuote.FILTER.SetFilter("No.", PurchaseHeader."No.");

        // Exercise: Open Statistics page from Purchase Quote.
        PurchaseQuote.PurchaseStatistics.Invoke();

        // Verify: Verification is done in 'PurchaseQuotePurchaseStatisticsHandler' handler method.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderFromPurchaseQuoteWithPostingDateBlank()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        OldDefaultPostingDate: Enum "Default Posting Date";
    begin
        // Check that blank Posting Date is populating on created Purchase Order from Purchase Quote while Default Posting Date is set to No Date on the Purchase & Payables Setup.

        // Setup: Update Purchase & Payables Setup and create Purchase Quote.
        Initialize();
        UpdatePurchasePayablesSetup(OldDefaultPostingDate, PurchasesPayablesSetup."Default Posting Date"::"No Date");
        CreatePurchaseQuote(PurchaseHeader, PurchaseLine, CreateVendor());

        // Exercise: Create Purchase Order from Purchase Quote.
        CODEUNIT.Run(CODEUNIT::"Purch.-Quote to Order", PurchaseHeader);

        // Verify: Verify that New Purchase Order created from Purchase Quote with Posting Date blank.
        VerifyPostingDateOnOrder(PurchaseHeader);

        // Tear Down.
        UpdatePurchasePayablesSetup(OldDefaultPostingDate, OldDefaultPostingDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseQuoteContactNotEditableBeforeVendorSelected()
    var
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [FEATURE] [UI]
        // [Scenario] Contact Field on Purchase Quote Page not editable if no vendor selected
        // [Given]
        Initialize();

        // [WHEN] Purchase Quote page is opened
        PurchaseQuote.OpenNew();

        // [THEN] Contact Field is not editable
        Assert.IsFalse(PurchaseQuote."Buy-from Contact".Editable(), ContactShouldNotBeEditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseQuoteContactEditableAfterVendorSelected()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [FEATURE] [UI]
        // [Scenario] Contact Field on Purchase Quote Page  editable if vendor selected
        // [Given]
        Initialize();

        // [Given] A sample Purchase Quote
        CreatePurchaseQuote(PurchaseHeader, PurchaseLine, CreateVendor());

        // [WHEN] Purchase Quote page is opened
        PurchaseQuote.OpenEdit();
        PurchaseQuote.GotoRecord(PurchaseHeader);

        // [THEN] Contact Field is editable
        Assert.IsTrue(PurchaseQuote."Buy-from Contact".Editable(), ContactShouldBeEditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseQuotePayToAddressFieldsNotEditableIfSamePayToVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [FEATURE] [UI]
        // [Scenario] Pay-to Address Fields on Purchase Quote Page not editable if vendor selected equals pay-to vendor
        // [Given]
        Initialize();

        // [Given] A sample Purchase Quote
        CreatePurchaseQuote(PurchaseHeader, PurchaseLine, CreateVendor());

        // [WHEN] Purchase Quote page is opened
        PurchaseQuote.OpenEdit();
        PurchaseQuote.GotoRecord(PurchaseHeader);

        // [THEN] Pay-to Address Fields is not editable
        Assert.IsFalse(PurchaseQuote."Pay-to Address".Editable(), PayToAddressFieldsNotEditableErr);
        Assert.IsFalse(PurchaseQuote."Pay-to Address 2".Editable(), PayToAddressFieldsNotEditableErr);
        Assert.IsFalse(PurchaseQuote."Pay-to City".Editable(), PayToAddressFieldsNotEditableErr);
        Assert.IsFalse(PurchaseQuote."Pay-to Contact".Editable(), PayToAddressFieldsNotEditableErr);
        Assert.IsFalse(PurchaseQuote."Pay-to Post Code".Editable(), PayToAddressFieldsNotEditableErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseQuotePayToAddressFieldsEditableIfDifferentPayToVendor()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PayToVendor: Record Vendor;
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [FEATURE] [UI]
        // [Scenario] Pay-to Address Fields on Purchase Quote Page editable if vendor selected not equals pay-to vendor
        // [Given]
        Initialize();

        // [Given] A sample Purchase Quote
        CreatePurchaseQuote(PurchaseHeader, PurchaseLine, CreateVendor());

        // Purchase Quote page is opened
        PurchaseQuote.OpenEdit();
        PurchaseQuote.GotoRecord(PurchaseHeader);

        // [WHEN] Another Pay-to vendor is picked
        PayToVendor.Get(CreateVendor());
        PurchaseQuote."Pay-to Name".SetValue(PayToVendor.Name);

        // [THEN] Pay-to Address Fields is editable
        Assert.IsTrue(PurchaseQuote."Pay-to Address".Editable(), PayToAddressFieldsEditableErr);
        Assert.IsTrue(PurchaseQuote."Pay-to Address 2".Editable(), PayToAddressFieldsEditableErr);
        Assert.IsTrue(PurchaseQuote."Pay-to City".Editable(), PayToAddressFieldsEditableErr);
        Assert.IsTrue(PurchaseQuote."Pay-to Contact".Editable(), PayToAddressFieldsEditableErr);
        Assert.IsTrue(PurchaseQuote."Pay-to Post Code".Editable(), PayToAddressFieldsEditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseQuoteChangePricesInclVATRefreshesPage()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseQuotePage: TestPage "Purchase Quote";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 277993] User changes Prices including VAT, page refreshes and shows appropriate captions
        Initialize();

        // [GIVEN] Page with Prices including VAT disabled was open
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Quote, '');
        PurchaseQuotePage.OpenEdit();
        PurchaseQuotePage.GotoRecord(PurchaseHeader);

        // [WHEN] User checks Prices including VAT
        PurchaseQuotePage."Prices Including VAT".SetValue(true);

        // [THEN] Caption for PurchaseQuotePage.PurchLines."Direct Unit Cost" field is updated
        Assert.AreEqual('Direct Unit Cost Incl. VAT',
          PurchaseQuotePage.PurchLines."Direct Unit Cost".Caption,
          'The caption for PurchaseQuotePage.PurchLines."Direct Unit Cost" is incorrect');
    end;

    [Test]
    [HandlerFunctions('QuoteToOrderHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderFromPurchaseQuoteOpenCreatedOrderCard()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseQuote: TestPage "Purchase Quote";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 304297] User is suggested to open order which was created with Make Order action
        Initialize();

        // [GIVEN] Purchase Quote "PQ" opened with Purchase Quote page
        CreatePurchaseQuote(PurchaseHeader, PurchaseLine, CreateVendor());
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Quote);
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseQuote.OpenEdit();
        PurchaseQuote.FILTER.SetFilter("No.", PurchaseHeader."No.");

        // [WHEN] Make Order action is being selected, created order "PO" and confirmend to open order
        PurchaseOrder.Trap();
        LibraryVariableStorage.Enqueue(MakeOrderQst);
        LibraryVariableStorage.Enqueue(OpenNewOrderTxt);
        PurchaseQuote.MakeOrder.Invoke();

        // [THEN] Purchase Order page opened with order "PO"
        PurchaseOrder."Buy-from Vendor No.".AssertEquals(PurchaseHeader."Buy-from Vendor No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFullDocTypeName()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [SCENARIO] Get full document type and name
        // [GIVEN] Purchase Header of type "Quote"
        PurchaseHeader."Document Type" := PurchaseHeader."Document Type"::Quote;

        // [WHEN] GetFullDocTypeTxt is called
        // [THEN] 'Purchase Quote' is returned
        Assert.AreEqual('Purchase Quote', PurchaseHeader.GetFullDocTypeTxt(), 'The expected full document type is incorrect');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderFromQuoteWithBlockedResource()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Resource: Record Resource;
    begin
        // [FEATURE] [Resource]
        // [SCENARIO 289386] Create purchase order from quote with blocked resource
        Initialize();

        // [GIVEN] Purchase quote with resource
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Quote, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Resource, LibraryResource.CreateResourceNo(), LibraryRandom.RandInt(10));

        // [GIVEN] Blocked resource
        Resource.Get(PurchaseLine."No.");
        Resource.Validate(Blocked, true);
        Resource.Modify(true);

        // [WHEN] Create purchase order
        asserterror Codeunit.Run(Codeunit::"Purch.-Quote to Order", PurchaseHeader);

        // [THEN] Error "Blocked must be equal to 'No'  in Resource: No.= ***. Current value is 'Yes'."
        Assert.ExpectedTestFieldError(Resource.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderFromPurchQuoteDeleteComments()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchCommentLine: Record "Purch. Comment Line";
    begin
        // [FEATURE] [Order]
        // [SCENARIO 416939] Purch quote comments deleted on Purch Order from Purch Quote action
        Initialize();

        // [GIVEN] Created Purch Quote
        CreatePurchaseQuote(PurchHeader, PurchLine, CreateVendor());
        // [GIVEN] Created comment for quote
        CreatePurchQuoteComments(PurchHeader);
        PurchCommentLine.SetRange("Document Type", "Purchase Comment Document Type"::Quote);
        PurchCommentLine.SetRange("No.", PurchHeader."No.");
        Assert.RecordIsNotEmpty(PurchCommentLine);

        // [WHEN] Create Purch Order from Purch Quote.
        Codeunit.Run(Codeunit::"Purch.-Quote to Order", PurchHeader);

        // [THEN] Purch quote comments deleted
        Assert.RecordIsEmpty(PurchCommentLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestReleasePurchaseQuoteWithPrepayment()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 455940] Purchase Quote with Prepayment % can be release

        Initialize();

        // [GIVEN] Create Item and Customer
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 0));
        Item.Modify(true);
        LibraryPurchase.CreateVendor(Vendor);

        // [THEN] Update Prepayment % on customer.
        Vendor.Validate("Prepayment %", LibraryRandom.RandDec(100, 2));
        Vendor.Modify();

        // [GIVEN] Create Purchase Quote
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Quote, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));

        // [VERIFY] Purchase Quote released succesfully
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MakeOrderFromPurchaseQuoteWithEmptyItemLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        QuoteNo: Code[20];
    begin
        // [SCENARIO 557530] Purchase Quotes converts to Purchase Order if we have Item lines without any No. specified.
        Initialize();

        // [GIVEN] Create a Purchase Quote.
        CreatePurchaseQuote(PurchaseHeader, PurchaseLine, CreateVendor());

        // [GIVEN] Get Purchase Header and Purchase Line.
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Quote, PurchaseHeader."No.");
        PurchaseLine.Get(PurchaseLine."Document Type"::Quote, PurchaseLine."Document No.", PurchaseLine."Line No.");

        // [GIVEN] Store Vendor No and Quote No.
        VendorNo := PurchaseHeader."Buy-from Vendor No.";
        QuoteNo := PurchaseHeader."No.";

        // [GIVEN] Insert a Item line with empty No. value.
        PurchaseLine.Init();
        PurchaseLine.Validate("Document Type", PurchaseLine."Document Type"::Quote);
        PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
        PurchaseLine.Validate("Line No.", PurchaseLine."Line No." + 10000);
        PurchaseLine.Validate(Type, PurchaseLine.Type::Item);
        PurchaseLine.Insert(true);

        // [WHEN] Create Purch Order from Purch Quote.
        Codeunit.Run(Codeunit::"Purch.-Quote to Order", PurchaseHeader);

        // [THEN] Purchase Order should be created from Purchase Quote.
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchaseHeader.FindFirst();
        Assert.AreEqual(
            QuoteNo,
            PurchaseHeader."Quote No.",
            StrSubstNo(
                QuoteNoErr,
                QuoteNo,
                PurchaseHeader.TableCaption()));
    end;

    local procedure Initialize()
    var
        PurchaseHeader: Record "Purchase Header";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Purchase Quote");
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyVendorAddressNotificationId());
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyPayToVendorAddressNotificationId());
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Purchase Quote");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Purchase Quote");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorInvDiscount(VendorNo: Code[20]): Code[20]
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, VendorNo, '', 0); // Set Zero for Charge Amount.
        VendorInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(10, 2));  // Take Random Discount.
        VendorInvoiceDisc.Modify(true);
        exit(VendorNo);
    end;

    local procedure CreatePurchaseQuote(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20])
    var
        LibraryPurchase: Codeunit "Library - Purchase";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Quote, VendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);

        // Create Purchase Quote Line with Random Quantity and Direct Unit Cost. Take Unit Cost in multiple of 100 (Standard Value).
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", 100 * LibraryRandom.RandInt(10));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchQuoteComments(PurchHeader: Record "Purchase Header")
    var
        PurchCommentLine: Record "Purch. Comment Line";
    begin
        PurchCommentLine."Document Type" := "Purchase Comment Document Type"::Quote;
        PurchCommentLine."No." := PurchHeader."No.";
        PurchCommentLine."Line No." := 10000;
        PurchCommentLine.Insert();
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; QuoteNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.SetRange("Quote No.", QuoteNo);
        PurchaseHeader.FindFirst();
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
    end;

    local procedure UpdatePurchasePayablesSetup(var OldDefaultPostingDate: Enum "Default Posting Date"; DefaultPostingDate: Enum "Default Posting Date")
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        OldDefaultPostingDate := PurchasesPayablesSetup."Default Posting Date";
        PurchasesPayablesSetup.Validate("Default Posting Date", DefaultPostingDate);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure VerifyPostingDateOnOrder(PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.SetRange("Quote No.", PurchaseHeader."No.");
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.FindFirst();
        PurchaseHeader.TestField("Posting Date", 0D);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // Handler for confirmation messages, always send positive reply.
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure QuoteToOrderHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, LibraryVariableStorage.DequeueText()) <> 0, 'Invalid confirm message');
        Reply := true;
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseQuoteStatisticsHandler(var PurchaseStatistics: TestPage "Purchase Statistics")
    begin
        Assert.IsFalse(PurchaseStatistics.VATAmount.Editable(), 'The VAT Amount field should not be editable');
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseQuotePurchaseStatisticsHandler(var PurchaseStatistics: TestPage "Purchase Statistics")
    begin
        Assert.IsFalse(PurchaseStatistics.VATAmount.Editable(), 'The VAT Amount field should not be editable');
    end;
}

