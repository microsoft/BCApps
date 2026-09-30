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
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        isInitialized: Boolean;
        TotalToDeferErr: Label 'The sum of the deferred amounts must be equal to the amount in the Amount to Defer field.';

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


    local procedure OpenGlBudgetPage(GLBudgetNameValue: Text)
    var
        GLBudgetNamesPage: TestPage "G/L Budget Names";
    begin
        GLBudgetNamesPage.OpenEdit();
        GLBudgetNamesPage.FILTER.SetFilter(Name, GLBudgetNameValue);
        GLBudgetNamesPage.EditBudget.Invoke();
    end;


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


    local procedure UpdateBillToSellToVATCalcOnGLSetup(BillToSellToVATCalc: Enum "G/L Setup VAT Calculation")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Bill-to/Sell-to VAT Calc.", BillToSellToVATCalc);
        GeneralLedgerSetup.Modify(true);
    end;


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

