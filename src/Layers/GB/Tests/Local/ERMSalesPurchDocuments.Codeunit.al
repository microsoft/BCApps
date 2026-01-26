codeunit 144038 "ERM Sales Purch Documents"
{
    //  Includes test cases for UKGEN:
    // 
    //  1. Test to verify the Country/Region, VAT Registration No after changing the Buy from Vendor No field on Purchase Order.
    //  2. Test to verify the Country/Region, VAT Registration No after changing the Bill-to Customer No field on Purchase Order.
    //  6. Verify that column name displayed correctly after pressing the Show Column name on GL budget with G/L Account.
    //  7. Verify that column name displayed correctly after pressing the Show Column name on GL budget with Business Unit.
    //  8. Test to verify it is able to run report Stock Shipped not Invoiced retrospectively and Cost Amount (Expected) and Cost Amount (Actual) are correct.
    //  9. Test to verify it is able to run report Stock Received not Invoiced retrospectively and Cost Amount (Expected) and Cost Amount (Actual) are correc.
    // 
    //  Covers Test Cases for WI - 340223
    //  -----------------------------------------------------------------------
    //  Test Function Name                                              TFS ID
    //  -----------------------------------------------------------------------
    //  VATEntryPurchaseInvoiceWithBillToSellToVATCalc                  238365
    //  VATEntrySalesInvoiceWithBillToSellToVATCalc                     238364
    // 
    //  BUG ID 58719
    //  -----------------------------------------------------------------------
    //  Test Function Name                                              TFS ID
    //  -----------------------------------------------------------------------
    //  CheckGLBudgetWithGlAccount,CheckGLBudgetWithBusinessUnit

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
#if not CLEAN27
        ReverseChargeErr: Label '%1 must be %2 in %3.';
#endif
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        isInitialized: Boolean;
        TotalToDeferErr: Label 'The sum of the deferred amounts must be equal to the amount in the Amount to Defer field.';
#if not CLEAN27
        ReverseErr: Label 'VAT Bus. Posting Group cannot be %1. Item %2 is not subjected to Reverse Charge in Sales Line Document Type=''%3'',Document No.=''%4'',Line No.=''%5''.',
            Comment = '%1=VAT Bus. Posting Group ,%2=Item No. ,%3=Document Type ,%4=Document No. , %5=Line No.';
#endif

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTRUE')]
    [Scope('OnPrem')]
    procedure VATEntryPurchaseInvoiceWithBillToSellToVATCalc()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Vendor: Record Vendor;
        Vendor2: Record Vendor;
        DocumentNo: Code[20];
    begin
        // Setup: Update General Ledger Setup, create Vendor with Country Region. Create Purchase Order. Update Buy from Vendor No on Purchase Order.
        Initialize();
        UpdateBillToSellToVATCalcOnGLSetup(GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Sell-to/Buy-from No.");
        CreateVendorWithCountryRegion(Vendor);
        CreateVendorWithCountryRegion(Vendor2);
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.", LibraryInventory.CreateItem(Item));
        UpdatePurchaseHeaderPayToVendorNo(PurchaseHeader, Vendor2."No.");

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.

        // Verify: Verify the Country/Region, VAT Registration No in Posted Purchase Invoice and VAT Entry after changing the Buy from Vendor No
        // field on Purchase Order.
        VerifyPostedPurchaseInvoice(Vendor, DocumentNo, Vendor2."No.");
        VerifyVATEntry(DocumentNo, Vendor."Country/Region Code", PurchaseHeader."VAT Registration No.", Vendor2."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerTRUE')]
    [Scope('OnPrem')]
    procedure VATEntrySalesInvoiceWithBillToSellToVATCalc()
    var
        Customer: Record Customer;
        Customer2: Record Customer;
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        DocumentNo: Code[20];
    begin
        // Setup: Update General Ledger Setup, create Customer with Country Region. Create Sales Order. Update Sell To Customer No on Sales Order.
        Initialize();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());
        UpdateBillToSellToVATCalcOnGLSetup(GeneralLedgerSetup."Bill-to/Sell-to VAT Calc."::"Bill-to/Pay-to No.");
        CreateCustomerWithCountryRegion(Customer);
        CreateCustomerWithCountryRegion(Customer2);
        CreateSalesDocument(
          SalesHeader, SalesHeader."Document Type"::Order, Customer."No.", LibraryInventory.CreateItem(Item));
        UpdateSalesHeaderBillToCustomerNo(SalesHeader, Customer2."No.");

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.

        // Verify: Verify the Country/Region, VAT Registration No in Posted Sales Invoice and VAT Entry after changing the Sell To Customer No
        // field on Sales Order.
        VerifyPostedSalesInvoice(Customer2, DocumentNo, SalesHeader."Sell-to Customer No.");
        VerifyVATEntry(DocumentNo, Customer2."Country/Region Code", SalesHeader."VAT Registration No.", Customer2."No.");
    end;

#if not CLEAN27
    [Test]
    [Scope('OnPrem')]
    procedure ReverseChargeOnPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Purpose of this test is to hit Reverse Charge OnRun Trigger of Codeunit - 90 Purch.-Post.

        // Setup: Create and Post Purchase Invoice with Reverse Charge VAT.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        UpdatePurchasesPayablesSetup(VATPostingSetup."VAT Bus. Posting Group");
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor(VATPostingSetup."VAT Bus. Posting Group"),
          CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");

        // Exercise.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Reverse Charge on Purchase Invoice.
        VerifyReverseChargeOnPostedPurchaseInvoice(PurchaseLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReverseChargeOnPostedSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Purpose of this test is to verify Reverse Charge Amount on Posted Sales Invoice Line.

        // Setup: Create and Post Sales Invoice with Reverse Charge VAT.
        Initialize();
        SetupForSalesDocumentWithRevCharge(SalesHeader, SalesHeader."Document Type"::Invoice);
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");

        // Exercise.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Reverse Charge on Sales Invoice.
        VerifyReverseChargeOnPostedSalesInvoice(SalesLine, SalesLine."Reverse Charge Item");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReverseChargeOnPostedSalesInvoiceWithPrepayment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Purpose of this test is to verify Reverse Charge Amount on Posted Sales Invoice Line with partial Prepayment.

        // Setup: Create and Post Sales Order with Reverse Charge VAT.
        Initialize();
        SetupForSalesDocumentWithRevCharge(SalesHeader, SalesHeader."Document Type"::Order);
        UpdateSalesHeaderPrepaymentPct(SalesHeader);
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");

        // Exercise.
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // Verify: Verify Reverse Charge on Sales Invoice.
        VerifyReverseChargeOnPostedSalesInvoice(SalesLine, false);
    end;
#endif

    [Test]
    [HandlerFunctions('BudgetPageHandlerWithBusinessUnit')]
    [Scope('OnPrem')]
    procedure CheckGLBudgetWithBusinessUnit()
    begin
        // Verify that column name displayed correctly after pressing the Show Column name on GL budget with Business Unit.
        Initialize();
        CreateBusinessUnit();
        GLBudgetWithColumnValues();
    end;

    [Test]
    [HandlerFunctions('BudgetPageHandlerWithGLAccount')]
    [Scope('OnPrem')]
    procedure CheckGLBudgetWithGLAccount()
    begin
        // Verify that column name displayed correctly after pressing the Show Column name on GL budget with G/L Account.
        Initialize();
        GLBudgetWithColumnValues();
    end;

    local procedure GLBudgetWithColumnValues()
    var
        GLBudgetName: Record "G/L Budget Name";
    begin
        // Setup: Create GL Budget.
        LibraryERM.CreateGLBudgetName(GLBudgetName);

        // Exercise: Open GL Budget Page.
        OpenGlBudgetPage(GLBudgetName.Name);

        // Verify: Verification done in Handler.
    end;

#if not CLEAN27
    [Test]
    [HandlerFunctions('ConfirmHandlerTRUE')]
    [Scope('OnPrem')]
    procedure ChangeDocumentVatBusPostingGroupForDocumentWithReverseChargeItem()
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        // [SCENARIO 381636] Change "VAT Bus. Posting Group" in Purchase Header to Posting Group with "Reverse Charge VAT"
        Initialize();

        // [GIVEN] Found VAT Posting Setup with "Reverse Charge VAT"
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);

        // [GIVEN] Edited "Purchases & Payables Setup"
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Reverse Charge VAT Posting Gr.", VATPostingSetup."VAT Bus. Posting Group");
        PurchasesPayablesSetup.Validate("Domestic Vendors", VATPostingSetup."VAT Bus. Posting Group");
        PurchasesPayablesSetup.Modify(true);

        // [GIVEN] Created Purchase Order using VAT Posting Setup
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);

        // [GIVEN] Set "Reverse Charge Applies" to true for created Item
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        Item.Get(PurchaseLine."No.");
        Item.Validate("Reverse Charge Applies", true);
        Item.Modify(true);

        // [WHEN] Change "VAT Bus. Posting Group" in Purchase Header to value from VAT Posting Setup
        PurchaseHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        PurchaseHeader.Modify(true);

        // [THEN] "VAT Bus. Posting Group" is changed without error
        PurchaseHeader.TestField("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTRUE')]
    [Scope('OnPrem')]
    procedure RunPostingPreviewForDocumentWithReverseChargeItem()
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [FEATURE] [Reverse Charge]
        // [SCENARIO 380707] Run Posting Preview for document with "Reverse Charge Item" and validated "Reverse Charge VAT Posting Gr." in Purchase Setup
        Initialize();

        // [GIVEN] Created VAT Posting Setup with "Reverse Charge VAT"
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", 20);
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);

        // [GIVEN] Edited "Purchases & Payables Setup". Set "Reverse Charge VAT Posting Gr." and "Domestic Vendors" to value from VAT Posting Setup.
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Reverse Charge VAT Posting Gr.", VATPostingSetup."VAT Bus. Posting Group");
        PurchasesPayablesSetup.Validate("Domestic Vendors", VATPostingSetup."VAT Bus. Posting Group");
        PurchasesPayablesSetup.Modify(true);

        // [GIVEN] Created Purchase Order using VAT Posting Setup
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);

        // [GIVEN] Edited "Reverse Charge Applies" to True in Item
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
        Item.Get(PurchaseLine."No.");
        Item.Validate("Reverse Charge Applies", true);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);

        PurchaseHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        PurchaseHeader.Modify(true);
        Commit();

        // [WHEN] Run "Preview Posing" for created order
        GLPostingPreview.Trap();
        asserterror LibraryPurchase.PreviewPostPurchaseDocument(PurchaseHeader);

        // [THEN] No errors occured - preview mode error only
        // [THEN] Status is equal to "Open" in Purchase Header
        Assert.ExpectedError('');
        PurchaseHeader.TestField(Status, PurchaseHeader.Status::Open);
        GLPostingPreview.Close();
    end;
#endif

    [Test]
    procedure SalesInvoiceShouldNotPostWithIncorrectDeferralScheduleValues()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralTemplate: Record "Deferral Template";
        GLAccount: Record "G/L Account";
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
    begin
        // [SCENARIO 504969] Incorrect Deferral Schedule Values are wrongly kept if you refresh the page or close the browser.
        Initialize();

        // [GIVEN] Create Deferral Template with "Calculation Method" = "User-Defined","Start Date" ="Beginning of Next Calendar Year" and No. of Periods is 4.
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"User-Defined",
          DeferralTemplate."Start Date"::"Beginning of Next Calendar Year", LibraryRandom.RandIntInRange(4, 4));

        // [GIVEN] Create Sales Invoice withG/L Account and Deferral Template applied in line.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        CreateGLAccountWithVATPostSetup(GLAccount, SalesHeader."VAT Bus. Posting Group", LibraryRandom.RandIntInRange(5, 20));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", LibraryRandom.RandIntInRange(1, 1));
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(1000, 1000));
        SalesLine.Validate("Deferral Code", DeferralTemplate."Deferral Code");
        SalesLine.Modify(true);

        // [GIVEN] Update Amount in Deferral Schedule Line.
        DeferralHeader.Get(DeferralHeader."Deferral Doc. Type"::Sales, '', '', SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.");
        UpdateDeferralScheduleForNMonth(
          "Deferral Document Type"::Sales, SalesHeader."Document Type".AsInteger(), SalesHeader."No.",
          SalesLine."Line No.", DeferralHeader."Start Date", SalesLine."Unit Price", DeferralTemplate."No. of Periods", 1);

        // [WHEN] Update Deferral Amounts.
        FindDeferralSalesLine(DeferralLine, SalesLine);
        DeferralLine.Validate(Amount, LibraryRandom.RandDecInDecimalRange(500, 1000, 2));
        DeferralLine.Modify(true);

        // [VERIFY] Verify: Expected Error - The sum of the deferred amounts must be equal to the amount in the Amount to Defer field.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);
        Assert.ExpectedError(TotalToDeferErr);
    end;

    [Test]
    procedure PurchaseInvoiceShouldNotPostWithIncorrectDeferralScheduleValues()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralTemplate: Record "Deferral Template";
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
    begin
        // [SCENARIO 504969] Incorrect Deferral Schedule Values are wrongly kept if you refresh the page or close the browser.
        Initialize();

        // [GIVEN] Create Deferral Template with "Calculation Method" = "User-Defined","Start Date" ="Beginning of Next Calendar Year" and No. of Periods is 4.
        LibraryERM.CreateDeferralTemplate(
          DeferralTemplate, DeferralTemplate."Calc. Method"::"User-Defined",
          DeferralTemplate."Start Date"::"Beginning of Next Calendar Year", LibraryRandom.RandIntInRange(4, 4));

        // [GIVEN] Create Purchase Invoice withG/L Account and Deferral Template applied in line.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(),
          LibraryRandom.RandIntInRange(1, 1));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(1000, 1000));
        PurchaseLine.Validate("Deferral Code", DeferralTemplate."Deferral Code");
        PurchaseLine.Modify(true);

        // [GIVEN] Update Amount in Deferral Schedule Line.
        DeferralHeader.Get("Deferral Document Type"::Purchase, '', '', PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine."Line No.");
        UpdateDeferralScheduleForNMonth(
          "Deferral Document Type"::Purchase, PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.",
          PurchaseLine."Line No.", DeferralHeader."Start Date", PurchaseLine."Direct Unit Cost", DeferralTemplate."No. of Periods", 1);

        // [WHEN] Update Deferral Amounts.
        FindDeferralPurchaseLine(DeferralLine, PurchaseLine);
        DeferralLine.Validate(Amount, LibraryRandom.RandDecInDecimalRange(500, 1000, 2));
        DeferralLine.Modify(true);

        // [VERIFY] Verify: Expected Error - The sum of the deferred amounts must be equal to the amount in the Amount to Defer field.
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        Assert.ExpectedError(TotalToDeferErr);
    end;

#if not CLEAN27
    [Test]
    [Obsolete('Moved to Reverse Charge VAT GB app', '27.0')]
    procedure ErrorMessageOnSalesLineReverseChargeVAT()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [SCENARIO 548073] Error Message appear if line with Reverse Charge VAT in Sales Order.
        Initialize();

        // [GIVEN] Create VAT Posting Setup.
        CreateVATPostingSetupWithBlankVATBusPostingGroup(VATPostingSetup);

        // [GIVEN] Validate Reverse Charge Vat Posting Group in Sales and Receivables Setup.
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Reverse Charge VAT Posting Gr.", VATPostingSetup."VAT Bus. Posting Group");
        SalesReceivablesSetup.Modify(true);

        // [GIVEN] Create a Sales Header of type Order.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(VATPostingSetup));

        // [GIVEN] Create an Item.
        Item.Get(LibraryInventory.CreateItemNo());

        // [GIVEN] Create a Sales Line and Validate Type.
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine.Validate(Type, SalesLine.Type::Item);

        // [WHEN] Validate Item No. in Sales Line.
        asserterror SalesLine.Validate("No.", Item."No.");

        // [THEN] Error is thrown when line is Reverse Charge VAT.
        Assert.ExpectedError(
            StrSubstNo(
                ReverseErr,
                SalesLine."VAT Bus. Posting Group",
                Item."No.",
                SalesLine."Document Type",
                SalesLine."Document No.",
                SalesLine."Line No."));
    end;
#endif

    local procedure Initialize()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Sales Purch Documents");
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        if isInitialized then
            exit;

        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyVendorAddressNotificationId());
        PurchaseHeader.DontNotifyCurrentUserAgain(PurchaseHeader.GetModifyPayToVendorAddressNotificationId());

        isInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
    end;

    local procedure CreateBusinessUnit()
    var
        BusinessUnit: Record "Business Unit";
    begin
        BusinessUnit.Init();
        BusinessUnit.Validate(Code, LibraryUtility.GenerateRandomCode(BusinessUnit.FieldNo(Code), DATABASE::"Business Unit"));
        BusinessUnit.Validate(Name, LibraryUtility.GenerateRandomCode(BusinessUnit.FieldNo(Name), DATABASE::"Business Unit"));
        BusinessUnit.Insert();
    end;

#if not CLEAN27
    local procedure CreateCustomer(VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;
#endif

    local procedure CreateCustomerWithCountryRegion(var Customer: Record Customer)
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        LibrarySales.CreateCustomer(Customer);
        CompanyInformation.Get();
        Customer.Validate("VAT Registration No.", CompanyInformation."VAT Registration No.");
        Customer.Validate("Country/Region Code", CountryRegion.Code);
        Customer.Modify(true);
    end;

#if not CLEAN27
    local procedure CreateItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Validate("Reverse Charge Applies", true);
        Item.Modify(true);
        exit(Item."No.");
    end;
#endif

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; BuyFromVendorNo: Code[20]; No: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, BuyFromVendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, No, LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));  // Use Random value for Direct Unit Cost.
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; SellToCustomerNo: Code[20]; No: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, SellToCustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, No, LibraryRandom.RandDec(10, 2));  // Use Random value for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));  // Use Random value for Unit Price.
        SalesLine.Modify(true);
    end;

#if not CLEAN27
    local procedure CreateVendor(VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;
#endif

    local procedure CreateVendorWithCountryRegion(var Vendor: Record Vendor)
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        LibraryERM.CreateCountryRegion(CountryRegion);
        LibraryPurchase.CreateVendor(Vendor);
        CompanyInformation.Get();
        Vendor.Validate("VAT Registration No.", CompanyInformation."VAT Registration No.");
        Vendor.Validate("Country/Region Code", CountryRegion.Code);
        Vendor.Modify(true);
    end;

#if not CLEAN27
    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
    end;
#endif

    local procedure OpenGlBudgetPage(GLBudgetNameValue: Text)
    var
        GLBudgetNamesPage: TestPage "G/L Budget Names";
    begin
        GLBudgetNamesPage.OpenEdit();
        GLBudgetNamesPage.FILTER.SetFilter(Name, GLBudgetNameValue);
        GLBudgetNamesPage.EditBudget.Invoke();
    end;

#if not CLEAN27
    local procedure SetupForSalesDocumentWithRevCharge(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        UpdateSalesReceivableSetup(VATPostingSetup."VAT Bus. Posting Group");
        CreateSalesDocument(
          SalesHeader, DocumentType, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"),
          CreateItem(VATPostingSetup."VAT Prod. Posting Group"));
    end;
#endif

    local procedure UpdatePurchaseHeaderPayToVendorNo(var PurchaseHeader: Record "Purchase Header"; PayToVendorNo: Code[20])
    begin
        PurchaseHeader.Validate("Pay-to Vendor No.", PayToVendorNo);
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdateSalesHeaderBillToCustomerNo(var SalesHeader: Record "Sales Header"; BillToCustomerNo: Code[20])
    begin
        SalesHeader.Validate("Bill-to Customer No.", BillToCustomerNo);
        SalesHeader.Modify(true);
    end;

#if not CLEAN27
    local procedure UpdateSalesHeaderPrepaymentPct(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandDec(10, 2));  // Taken random for Prepayment Pct.
        SalesHeader.Modify(true);
    end;
#endif

    local procedure UpdateBillToSellToVATCalcOnGLSetup(BillToSellToVATCalc: Enum "G/L Setup VAT Calculation")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Bill-to/Sell-to VAT Calc.", BillToSellToVATCalc);
        GeneralLedgerSetup.Modify(true);
    end;

#if not CLEAN27
    local procedure UpdatePurchasesPayablesSetup(DomesticVendors: Code[20])
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Domestic Vendors", DomesticVendors);
        PurchasesPayablesSetup.Validate("Reverse Charge VAT Posting Gr.", PurchasesPayablesSetup."Domestic Vendors");
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateSalesReceivableSetup(DomesticCustomers: Code[20])
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Domestic Customers", DomesticCustomers);
        SalesReceivablesSetup.Validate("Reverse Charge VAT Posting Gr.", SalesReceivablesSetup."Domestic Customers");
        SalesReceivablesSetup.Modify(true);
    end;
#endif

    local procedure VerifyPostedSalesInvoice(Customer: Record Customer; No: Code[20]; SellToCustomerNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(No);
        SalesInvoiceHeader.TestField("VAT Registration No.", Customer."VAT Registration No.");
        SalesInvoiceHeader.TestField("Bill-to Customer No.", Customer."No.");
        SalesInvoiceHeader.TestField("VAT Country/Region Code", Customer."Country/Region Code");
        SalesInvoiceHeader.TestField("Sell-to Customer No.", SellToCustomerNo);
    end;

    local procedure VerifyPostedPurchaseInvoice(Vendor: Record Vendor; No: Code[20]; PayToVendorNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Get(No);
        PurchInvHeader.TestField("VAT Registration No.", Vendor."VAT Registration No.");
        PurchInvHeader.TestField("Pay-to Vendor No.", PayToVendorNo);
        PurchInvHeader.TestField("VAT Country/Region Code", Vendor."Country/Region Code");
        PurchInvHeader.TestField("Buy-from Vendor No.", Vendor."No.");
    end;

#if not CLEAN27
    local procedure VerifyReverseChargeOnPostedPurchaseInvoice(PurchaseLine: Record "Purchase Line")
    var
        PurchInvLine: Record "Purch. Inv. Line";
        ReverseCharge: Decimal;
    begin
        ReverseCharge := PurchaseLine."Amount Including VAT" - PurchaseLine.Amount;
        PurchInvLine.SetRange("Buy-from Vendor No.", PurchaseLine."Buy-from Vendor No.");
        PurchInvLine.FindFirst();
        PurchInvLine.TestField("No.", PurchaseLine."No.");
        PurchInvLine.TestField("Reverse Charge Item", PurchaseLine."Reverse Charge Item");
        Assert.AreNearlyEqual(
          ReverseCharge, PurchInvLine."Reverse Charge", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ReverseChargeErr, PurchInvLine.FieldCaption("Reverse Charge"), ReverseCharge, PurchInvLine.TableCaption()));
    end;

    local procedure VerifyReverseChargeOnPostedSalesInvoice(SalesLine: Record "Sales Line"; ReverseChargeItem: Boolean)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        ReverseCharge: Decimal;
    begin
        ReverseCharge := SalesLine."Amount Including VAT" - SalesLine.Amount;
        SalesInvoiceLine.SetRange("Sell-to Customer No.", SalesLine."Sell-to Customer No.");
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField("Reverse Charge Item", ReverseChargeItem);
        Assert.AreNearlyEqual(
          ReverseCharge, SalesInvoiceLine."Reverse Charge", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ReverseChargeErr, SalesInvoiceLine.FieldCaption("Reverse Charge"), ReverseCharge, SalesInvoiceLine.TableCaption()));
    end;
#endif

    local procedure VerifyVATEntry(DocumentNo: Code[20]; CountryRegionCode: Code[10]; VATRegistrationNo: Code[20]; BillToPayToNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        VATEntry.TestField("Country/Region Code", CountryRegionCode);
        VATEntry.TestField("VAT Registration No.", VATRegistrationNo);
        VATEntry.TestField("Bill-to/Pay-to No.", BillToPayToNo);
    end;

    local procedure CreateGLAccountWithVATPostSetup(var GLAccount: Record "G/L Account"; VATBusPostGrCode: Code[20]; VATPct: Decimal)
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        CreateVATPostingSetup(VATBusPostGrCode, VATProductPostingGroup.Code, VATPct);
        GLAccount.Validate("VAT Bus. Posting Group", VATBusPostGrCode);
        GLAccount.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        GLAccount.Modify(true);
    end;

    local procedure CreateVATPostingSetup(VATBusPostGr: Code[20]; VATProdPostGr: Code[20]; VATPct: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostGr, VATProdPostGr);
        VATPostingSetup."VAT Identifier" := VATProdPostGr;
        VATPostingSetup.Validate("VAT %", VATPct);
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    local procedure UpdateDeferralScheduleForNMonth(DefDocType: Enum "Deferral Document Type"; DocType: Option; DocNo: Code[20]; DocLineNo: Integer; StartDateDeferralHeader: Date; DefAmount1: Decimal; NoOfPeriod: Integer; LineNo: Integer)
    var
        DeferralLine: Record "Deferral Line";
    begin
        DeferralLine.SetRange("Posting Date", StartDateDeferralHeader);
        LibraryERM.FindDeferralLine(DeferralLine, DefDocType, '', '', DocType, DocNo, DocLineNo);
        UpdateDefScheduleLine(DeferralLine, (DefAmount1 / NoOfPeriod), Format(LineNo) + '1');
        DeferralLine.SetRange("Posting Date", CalcDate('<-CM+1M>', StartDateDeferralHeader));
        DeferralLine.FindFirst();
        UpdateDefScheduleLine(DeferralLine, (DefAmount1 / NoOfPeriod), Format(LineNo) + '2');
        DeferralLine.SetRange("Posting Date", CalcDate('<-CM+2M>', StartDateDeferralHeader));
        DeferralLine.FindFirst();
        UpdateDefScheduleLine(DeferralLine, (DefAmount1 / NoOfPeriod), Format(LineNo) + '3');
        DeferralLine.SetRange("Posting Date", CalcDate('<-CM+3M>', StartDateDeferralHeader));
        DeferralLine.FindFirst();
        UpdateDefScheduleLine(DeferralLine, (DefAmount1 / NoOfPeriod), Format(LineNo) + '4');
    end;

    local procedure UpdateDefScheduleLine(var DeferralLine: Record "Deferral Line"; DefAmount: Decimal; DefLineDescr: Text[100])
    begin
        DeferralLine.Validate(Description, PadStr(DefLineDescr, MaxStrLen(DeferralLine.Description), '0'));
        DeferralLine.Validate(Amount, DefAmount);
        DeferralLine.Modify(true);
    end;

    local procedure FindDeferralSalesLine(var DeferralLine: Record "Deferral Line"; SalesLine: Record "Sales Line")
    begin
        DeferralLine.SetRange("Deferral Doc. Type", DeferralLine."Deferral Doc. Type"::Sales);
        DeferralLine.SetRange("Gen. Jnl. Template Name", '');
        DeferralLine.SetRange("Gen. Jnl. Batch Name", '');
        DeferralLine.SetRange("Document Type", SalesLine."Document Type");
        DeferralLine.SetRange("Document No.", SalesLine."Document No.");
        DeferralLine.FindFirst();
    end;

    local procedure FindDeferralPurchaseLine(var DeferralLine: Record "Deferral Line"; PurchaseLine: Record "Purchase Line")
    begin
        DeferralLine.SetRange("Deferral Doc. Type", DeferralLine."Deferral Doc. Type"::Purchase);
        DeferralLine.SetRange("Gen. Jnl. Template Name", '');
        DeferralLine.SetRange("Gen. Jnl. Batch Name", '');
        DeferralLine.SetRange("Document Type", PurchaseLine."Document Type");
        DeferralLine.SetRange("Document No.", PurchaseLine."Document No.");
        DeferralLine.FindFirst();
    end;

#if not CLEAN27
    local procedure CreateVATPostingSetupWithBlankVATBusPostingGroup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, '', VATProductPostingGroup.Code); // Set VAT Bus. Posting Group to blank.
        VATPostingSetup.Validate("VAT Identifier", VATPostingSetup."VAT Prod. Posting Group");
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandInt(10));
        VATPostingSetup.Validate("Purchase VAT Account", GLAccount."No.");
        VATPostingSetup.Validate("Sales VAT Account", GLAccount."No.");
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateCustomer(var VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        exit(Customer."No.");
    end;
#endif

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTRUE(Question: Text[1024]; var Confirm: Boolean)
    begin
        Confirm := true;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BudgetPageHandlerWithGLAccount(var Budget: TestPage Budget)
    var
        GLAccount: Record "G/L Account";
    begin
        Budget.ColumnDimCode.SetValue(GLAccount.TableCaption());
        Budget.ShowColumnName.SetValue(false);
        GLAccount.Get(Budget.MatrixForm.Field1.Caption);
        Budget.ShowColumnName.SetValue(true);
        GLAccount.TestField(Name, Budget.MatrixForm.Field1.Caption);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BudgetPageHandlerWithBusinessUnit(var Budget: TestPage Budget)
    var
        BusinessUnit: Record "Business Unit";
    begin
        Budget.ColumnDimCode.SetValue(BusinessUnit.TableCaption());
        Budget.ShowColumnName.SetValue(false);
        BusinessUnit.Get(Budget.MatrixForm.Field1.Caption);
        Budget.ShowColumnName.SetValue(true);
        BusinessUnit.TestField(Name, Budget.MatrixForm.Field1.Caption);
    end;
}

