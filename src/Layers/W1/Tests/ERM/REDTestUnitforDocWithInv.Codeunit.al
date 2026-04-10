codeunit 134807 "RED Test Unit for Doc With Inv"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Revenue Expense Deferral]
        IsInitialized := false;
    end;

    var
        ChangedInvDiscountAmountErr: Label 'Invoice Discount Amount must not be changed';
        Currency: Record Currency;
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        CalcMethod: Enum "Deferral Calculation Method";
        StartDate: Enum "Deferral Calculation Start Date";
        DeferralDocType: Option Purchase,Sales,"G/L";

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesOrderInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
        InvoiceDiscountAmount: Decimal;
        DeferralPercent: Decimal;
    begin
        // [FEATURE] [Sales] [Invoice Discount Amount]
        // [SCENARIO] Set Invoice Discount Amount for SO in LCY with multiple lines

        // [GIVEN] LCY Sales Order with multiple lines
        Initialize();
        InitializeSalesMultipleLinesEqualAmountsScenario(
          SalesHeader, InvoiceDiscountAmount, '', DeferralPercent, SetDateDay(15, WorkDate()));

        // [WHEN] Set Invoice Discount Amount
        UpdateInvDiscAmtOnSalesOrder(SalesHeader, InvoiceDiscountAmount);

        // [THEN] Verify the invoice discount amount
        VerifySalesOrderInvoiceDiscountAmount(SalesHeader, InvoiceDiscountAmount);

        // [THEN] Verify Deferrals do not include the Invoice Discount Amount
        VerifySalesLineDeferralAmounts(SalesHeader, 2, DeferralPercent);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderInvoiceDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        InvoiceDiscountAmount: Decimal;
        DeferralPercent: Decimal;
    begin
        // [FEATURE] [Purchase] [Invoice Discount Amount]
        // [SCENARIO] Set Invoice Discount Amount for PO in LCY with multiple lines

        // [GIVEN] LCY Purchase Order with multiple lines
        Initialize();
        InitializePurchaseMultipleLinesEqualAmountsScenario(
          PurchaseHeader, InvoiceDiscountAmount, '', DeferralPercent, SetDateDay(15, WorkDate()));

        // [WHEN] Set Invoice Discount Amount
        UpdateInvDiscAmtOnPurchaseOrder(PurchaseHeader, InvoiceDiscountAmount);

        // [THEN] Verify the invoice discount amount
        VerifyPurchaseOrderInvoiceDiscountAmount(PurchaseHeader, InvoiceDiscountAmount);

        // [THEN] Verify Deferrals do not include the Invoice Discount Amount
        VerifyPurchLineDeferralAmounts(PurchaseHeader, 2, DeferralPercent);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesOrderInvoiceDiscountFCY()
    var
        SalesHeader: Record "Sales Header";
        InvoiceDiscountAmount: Decimal;
        DeferralPercent: Decimal;
    begin
        // [FEATURE] [Sales] [Invoice Discount Amount]
        // [SCENARIO] Set Invoice Discount Amount for SO in FCY with multiple lines

        // [GIVEN] FCY Sales Order with multiple lines
        Initialize();
        InitializeSalesMultipleLinesEqualAmountsScenario(
          SalesHeader, InvoiceDiscountAmount, CreateCurrency(), DeferralPercent, SetDateDay(1, WorkDate()));

        // [WHEN] set Invoice Discount Amount
        UpdateInvDiscAmtOnSalesOrder(SalesHeader, InvoiceDiscountAmount);

        // [THEN] Verify the invoice discount amount
        VerifySalesOrderInvoiceDiscountAmount(SalesHeader, InvoiceDiscountAmount);

        // [THEN] Verify Deferrals do not include the Invoice Discount Amount
        VerifySalesLineDeferralAmounts(SalesHeader, 2, DeferralPercent);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPurchaseOrderInvoiceDiscountFCY()
    var
        PurchaseHeader: Record "Purchase Header";
        InvoiceDiscountAmount: Decimal;
        DeferralPercent: Decimal;
    begin
        // [FEATURE] [Purchase] [Invoice Discount Amount]
        // [SCENARIO] Set Invoice Discount Amount for PO in FCY with multiple lines

        // [GIVEN] FCY Purchase Order with multiple
        Initialize();
        InitializePurchaseMultipleLinesEqualAmountsScenario(
          PurchaseHeader, InvoiceDiscountAmount, CreateCurrency(), DeferralPercent, SetDateDay(1, WorkDate()));

        // [WHEN] Set Invoice Discount Amount
        UpdateInvDiscAmtOnPurchaseOrder(PurchaseHeader, InvoiceDiscountAmount);

        // [THEN] Verify the invoice discount amount
        VerifyPurchaseOrderInvoiceDiscountAmount(PurchaseHeader, InvoiceDiscountAmount);

        // [THEN] Verify Deferrals do not include the Invoice Discount Amount
        VerifyPurchLineDeferralAmounts(PurchaseHeader, 2, DeferralPercent);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVATEntryOnPostSalesOrderInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
        InvoiceDiscountAmount: Decimal;
        DeferralPercent: Decimal;
        DocNo: Code[20];
        AccNo: Code[20];
        PostingDate: Date;
    begin
        // [FEATURE] [Sales] [Post] [VAT Entry]
        // [SCENARIO 160355] Post doc with Invoice Discount Amount and VAT for SO
        // [GIVEN] LCY Sales Order with multiple lines
        Initialize();
        InitializeSalesMultipleLinesEqualAmountsScenario(
          SalesHeader, InvoiceDiscountAmount, '', DeferralPercent, SetDateDay(1, WorkDate()));

        // [GIVEN] Set Invoice Discount Amount
        UpdateInvDiscAmtOnSalesOrder(SalesHeader, InvoiceDiscountAmount);
        AccNo := GetDeferralTemplateAccountForSalesLine(SalesHeader);
        PostingDate := SalesHeader."Posting Date";

        // [WHEN] Post the Invoice
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The VAT Entry record reflects the VAT Base Amount and VAT Amount
        VerifyDeferralAndVAT(DocNo, DeferralDocType::Sales, AccNo, PostingDate, PeriodDate(PostingDate, 2), 3, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVATEntryOnPostPurchaseOrderInvoiceDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        InvoiceDiscountAmount: Decimal;
        DeferralPercent: Decimal;
        DocNo: Code[20];
        AccNo: Code[20];
        PostingDate: Date;
    begin
        // [FEATURE] [Purchase] [Post] [VAT Entry]
        // [SCENARIO 160355] Post doc with Invoice Discount Amount and VAT for PO
        // [GIVEN] LCY Purchase Order with multiple lines
        Initialize();
        InitializePurchaseMultipleLinesEqualAmountsScenario(
          PurchaseHeader, InvoiceDiscountAmount, '', DeferralPercent, SetDateDay(1, WorkDate()));
        AccNo := GetDeferralTemplateAccountForPurchLine(PurchaseHeader);
        PostingDate := PurchaseHeader."Posting Date";

        // [GIVEN] Set Invoice Discount Amount
        UpdateInvDiscAmtOnPurchaseOrder(PurchaseHeader, InvoiceDiscountAmount);

        // [WHEN] Post the Invoice
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The deferrals were posted to GL in 3 periods which should then balance to 0
        VerifyDeferralAndVAT(DocNo, DeferralDocType::Purchase, AccNo, PostingDate, PeriodDate(PostingDate, 2), 3, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVATEntryOnPostSalesOrderLineInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralPercent: Decimal;
        DocNo: Code[20];
        AccNo: Code[20];
        PostingDate: Date;
    begin
        // [FEATURE] [Sales] [Post] [VAT Entry]
        // [SCENARIO 160355] Post doc with Line Discount Amount and VAT for SO
        // [GIVEN] LCY Sales Order with line with Line Discount %
        Initialize();
        CreateSalesDocWithLineInvoiceDisc(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, DeferralPercent);
        AccNo := GetDeferralTemplateAccountForSalesLine(SalesHeader);
        PostingDate := SalesHeader."Posting Date";

        // [WHEN] Post the Order
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The VAT Entry record reflects the VAT Base Amount and VAT Amount
        VerifyDeferralAndVAT(DocNo, DeferralDocType::Sales, AccNo, PostingDate, PeriodDate(PostingDate, 3), 5, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVATEntryOnPostPurchaseOrderLineInvoiceDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralPercent: Decimal;
        DocNo: Code[20];
        AccNo: Code[20];
        PostingDate: Date;
    begin
        // [FEATURE] [Purchase] [Post] [VAT Entry]
        // [SCENARIO 160355] Post doc with Line Discount Amount and VAT for PO
        // [GIVEN] LCY Purchase Order with line with Line Discount %
        Initialize();
        CreatePurchaseDocWithLineInvoiceDisc(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, DeferralPercent);
        AccNo := GetDeferralTemplateAccountForPurchLine(PurchaseHeader);
        PostingDate := PurchaseHeader."Posting Date";

        // [WHEN] Post the Order
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The deferrals were posted to GL in 4 periods which should then balance to 0
        VerifyDeferralAndVAT(DocNo, DeferralDocType::Purchase, AccNo, PostingDate, PeriodDate(PostingDate, 3), 5, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVATEntryOnPostSalesOrderLineInvoiceDiscountWithInvDisc()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralPercent: Decimal;
        DocNo: Code[20];
        AccNo: Code[20];
        PostingDate: Date;
    begin
        // [FEATURE] [Sales] [Post] [VAT Entry]
        // [SCENARIO 160355] Post doc with Line Discount Amount, Invoice Disc Amount and VAT for SO
        // [GIVEN] LCY Sales Order with line with Line Discount %
        Initialize();
        CreateSalesDocWithLineInvoiceDisc(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, DeferralPercent);
        AccNo := GetDeferralTemplateAccountForSalesLine(SalesHeader);
        PostingDate := SalesHeader."Posting Date";

        // [GIVEN] Set Invoice Discount Amount
        UpdateInvDiscAmtOnSalesOrder(SalesHeader, LibraryRandom.RandDec(10, 2));

        // [WHEN] Post the Order
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The VAT Entry record reflects the VAT Base Amount and VAT Amount
        VerifyDeferralAndVAT(DocNo, DeferralDocType::Sales, AccNo, PostingDate, PeriodDate(PostingDate, 3), 5, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVATEntryOnPostPurchaseOrderLineInvoiceDiscountWithInvDisc()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralPercent: Decimal;
        DocNo: Code[20];
        AccNo: Code[20];
        PostingDate: Date;
    begin
        // [FEATURE] [Purchase] [Post] [VAT Entry]
        // [SCENARIO 160355] Post doc with Line Discount Amount, Invoice Disc Amount and VAT for PO
        // [GIVEN] LCY Purchase Order with line with Line Discount %
        Initialize();
        CreatePurchaseDocWithLineInvoiceDisc(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, DeferralPercent);
        AccNo := GetDeferralTemplateAccountForPurchLine(PurchaseHeader);
        PostingDate := PurchaseHeader."Posting Date";

        // [GIVEN] Set Invoice Discount Amount
        UpdateInvDiscAmtOnPurchaseOrder(PurchaseHeader, LibraryRandom.RandDec(10, 2));

        // [WHEN] Post the Order
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The VAT Entry record reflects the VAT Base Amount and VAT Amount
        VerifyDeferralAndVAT(DocNo, DeferralDocType::Purchase, AccNo, PostingDate, PeriodDate(PostingDate, 3), 5, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVATEntryOnPostSalesOrderInvoiceDiscountMultipleVATPercent()
    var
        SalesHeader: Record "Sales Header";
        InvoiceDiscountAmount: Decimal;
        DeferralPercent: Decimal;
        DocNo: Code[20];
        Line1AccNo: Code[20];
        Line2AccNo: Code[20];
        PostingDate: Date;
    begin
        // [FEATURE] [Sales] [Post] [VAT Entry]
        // [SCENARIO 160355] Post doc with Invoice Discount Amount and different VAT% per line for SO
        // [GIVEN] LCY Sales Order with two lines each with different VAT %
        Initialize();
        InitializeSalesMultipleLinesMultiplelVATPercentScenario(
          SalesHeader, InvoiceDiscountAmount, '', DeferralPercent, Line1AccNo, Line2AccNo);

        // [GIVEN] Set Invoice Discount Amount
        UpdateInvDiscAmtOnSalesOrder(SalesHeader, InvoiceDiscountAmount);
        PostingDate := SalesHeader."Posting Date";

        // [WHEN] Post the Invoice
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The VAT Entry record reflects the VAT Base Amount and VAT Amount
        VerifyTwoLinesAndVAT(DocNo, DeferralDocType::Sales, PostingDate,
          Line1AccNo, PeriodDate(PostingDate, 3), 5,
          Line2AccNo, PeriodDate(PostingDate, 2), 4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVATEntryOnPostPurchaseOrderInvoiceDiscountMultipleVATPercent()
    var
        PurchaseHeader: Record "Purchase Header";
        InvoiceDiscountAmount: Decimal;
        DeferralPercent: Decimal;
        DocNo: Code[20];
        Line1AccNo: Code[20];
        Line2AccNo: Code[20];
        PostingDate: Date;
    begin
        // [FEATURE] [Purchase] [Post] [VAT Entry]
        // [SCENARIO 160355] Post doc with Invoice Discount Amount and different VAT% per line for PO
        // [GIVEN] LCY Purchase Order with two lines each with different VAT %
        Initialize();
        InitializePurchaseMultipleLinesMultipleVATPercentScenario(
          PurchaseHeader, InvoiceDiscountAmount, '', DeferralPercent, Line1AccNo, Line2AccNo);
        PostingDate := PurchaseHeader."Posting Date";

        // [GIVEN] Set Invoice Discount Amount
        UpdateInvDiscAmtOnPurchaseOrder(PurchaseHeader, InvoiceDiscountAmount);

        // [WHEN] Post the Invoice
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The VAT Entry record reflects the VAT Base Amount and VAT Amount
        VerifyTwoLinesAndVAT(DocNo, DeferralDocType::Purchase, PostingDate,
          Line1AccNo, PeriodDate(PostingDate, 3), 5,
          Line2AccNo, PeriodDate(PostingDate, 2), 4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVATEntryOnPostSalesOrderSalesTaxWithLineInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DeferralPercent: Decimal;
        DocNo: Code[20];
        AccNo: Code[20];
        PostingDate: Date;
    begin
        // [FEATURE] [Sales] [Post] [VAT Entry]
        // [SCENARIO 160355] Post doc with Line Discount Amount and Sales Tax for SO
        // [GIVEN] Sales Order with line with Line Discount % and Sales Tax
        Initialize();
        CreateSalesDocWithSalesTax(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, DeferralPercent);
        AccNo := GetDeferralTemplateAccountForSalesLine(SalesHeader);
        PostingDate := SalesHeader."Posting Date";

        // [WHEN] Post the Order
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The VAT Entry record reflects the VAT Base Amount and VAT Amount for Sales Tax
        VerifyDeferralAndVAT(DocNo, DeferralDocType::Sales, AccNo, PostingDate, PeriodDate(PostingDate, 2), 4, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestVATEntryOnPostPurchaseOrderSalesTaxWithLineInvoiceDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DeferralPercent: Decimal;
        DocNo: Code[20];
        AccNo: Code[20];
        PostingDate: Date;
    begin
        // [FEATURE] [Purchase] [Post] [VAT Entry]
        // [SCENARIO 160355] Post doc with Line Discount Amount and Sales Tax for PO
        // [GIVEN] Purchase Order with line with Line Discount % and Sales Tax
        Initialize();
        CreatePurchaseDocWithSalesTax(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, DeferralPercent);
        AccNo := GetDeferralTemplateAccountForPurchLine(PurchaseHeader);
        PostingDate := PurchaseHeader."Posting Date";

        // [WHEN] Post the Order
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The VAT Entry record reflects the VAT Base Amount and VAT Amount for Sales Tax
        VerifyDeferralAndVAT(DocNo, DeferralDocType::Purchase, AccNo, PostingDate, PeriodDate(PostingDate, 2), 4, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostSalesOrderInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
        InvoiceDiscountAmount: Decimal;
        DeferralPercent: Decimal;
        DocNo: Code[20];
        AccNo: Code[20];
        PostingDate: Date;
    begin
        // [FEATURE] [Sales] [Post] [Invoice Discount Amount]
        // [SCENARIO 137128] Post doc with Invoice Discount Amount for SO
        // [GIVEN] LCY Sales Order with multiple lines
        Initialize();
        InitializeSalesMultipleLinesEqualAmountsScenario(
          SalesHeader, InvoiceDiscountAmount, '', DeferralPercent, SetDateDay(15, WorkDate()));

        // [GIVEN] Set Invoice Discount Amount
        UpdateInvDiscAmtOnSalesOrder(SalesHeader, InvoiceDiscountAmount);
        AccNo := GetDeferralTemplateAccountForSalesLine(SalesHeader);
        PostingDate := SalesHeader."Posting Date";

        // [WHEN] Post the Invoice
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] The deferrals were posted to GL in 3 periods which should then balance to 0
        ValidateGL(DocNo, AccNo, PostingDate, PeriodDate(PostingDate, 2), 4, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostPurchaseOrderInvoiceDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        InvoiceDiscountAmount: Decimal;
        DeferralPercent: Decimal;
        DocNo: Code[20];
        AccNo: Code[20];
        PostingDate: Date;
    begin
        // [FEATURE] [Purchase] [Post] [Invoice Discount Amount]
        // [SCENARIO 137128] Post doc with Invoice Discount Amount for PO
        // [GIVEN] FCY Purchase Order with multiple lines
        Initialize();
        InitializePurchaseMultipleLinesEqualAmountsScenario(
          PurchaseHeader, InvoiceDiscountAmount, '', DeferralPercent, SetDateDay(15, WorkDate()));
        AccNo := GetDeferralTemplateAccountForPurchLine(PurchaseHeader);
        PostingDate := PurchaseHeader."Posting Date";

        // [GIVEN] Set Invoice Discount Amount
        UpdateInvDiscAmtOnPurchaseOrder(PurchaseHeader, InvoiceDiscountAmount);

        // [WHEN] Post the Invoice
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] The deferrals were posted to GL in 3 periods which should then balance to 0
        ValidateGL(DocNo, AccNo, PostingDate, PeriodDate(PostingDate, 2), 4, 0);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"RED Test Unit for Doc With Inv");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"RED Test Unit for Doc With Inv");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"RED Test Unit for Doc With Inv");
    end;

    local procedure CreateDeferralCode(CalcMethod: Enum "Deferral Calculation Method"; StartDate: Enum "Deferral Calculation Start Date"; NumOfPeriods: Integer; var DeferralPercent: Decimal): Code[10]
    var
        DeferralTemplate: Record "Deferral Template";
    begin
        LibraryERM.CreateDeferralTemplate(DeferralTemplate, CalcMethod, StartDate, NumOfPeriods);
        DeferralTemplate."Deferral %" := LibraryRandom.RandDecInRange(10, 99, 2);
        DeferralPercent := DeferralTemplate."Deferral %";
        DeferralTemplate."Period Description" := 'Deferral Revenue for %4';
        DeferralTemplate.Modify();
        exit(DeferralTemplate."Deferral Code");
    end;

    local procedure UpdateInvDiscAmtOnSalesOrder(var SalesHeader: Record "Sales Header"; NewInvoiceDiscountAmount: Decimal)
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        SalesLine: Record "Sales Line";
        UpdateType: Integer;
    begin
        UpdateType := 0; // 0 means General update
        GetSalesVATAmountLine(SalesHeader, TempVATAmountLine, UpdateType);
        TempVATAmountLine.SetInvoiceDiscountAmount(
          NewInvoiceDiscountAmount, SalesHeader."Currency Code",
          SalesHeader."Prices Including VAT", SalesHeader."VAT Base Discount %");
        SalesLine.UpdateVATOnLines(UpdateType, SalesHeader, SalesLine, TempVATAmountLine);
    end;

    local procedure GetSalesVATAmountLine(SalesHeader: Record "Sales Header"; var VATAmountLine: Record "VAT Amount Line"; UpdateType: Integer)
    var
        TempSalesLine: Record "Sales Line" temporary;
        SalesPost: Codeunit "Sales-Post";
    begin
        SalesPost.GetSalesLines(SalesHeader, TempSalesLine, UpdateType);
        TempSalesLine.CalcVATAmountLines(UpdateType, SalesHeader, TempSalesLine, VATAmountLine);
        if (not VATAmountLine.Positive) and (VATAmountLine."Invoice Discount Amount" = 0) then
            VATAmountLine.FindLast();
    end;

    local procedure InitializeSalesMultipleLinesEqualAmountsScenario(var SalesHeader: Record "Sales Header"; var InvoiceDiscountAmount: Decimal; CurrencyCode: Code[10]; var DeferralPercent: Decimal; PostingDate: Date)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        ItemNo: Code[20];
        Index: Integer;
    begin
        CreateVATPostingSetup(VATPostingSetup, LibraryRandom.RandDecInRange(10, 20, 2));

        Customer.Get(CreateCustomerWithVAT(VATPostingSetup."VAT Bus. Posting Group"));
        SetupCustomerInvoiceRoundingAccount(Customer."Customer Posting Group", VATPostingSetup);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);

        ItemNo := CreateItemVATWithDeferral(true, VATPostingSetup."VAT Prod. Posting Group", DeferralPercent, '');
        for Index := 1 to LibraryRandom.RandIntInRange(3, 10) do
            CreateSalesLine(SalesHeader, SalesLine, ItemNo, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2), 0);

        Currency.Initialize(CurrencyCode);
        InvoiceDiscountAmount := LibraryRandom.RandDec(100, 2);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATPercent: Decimal)
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", VATPercent);
    end;

    local procedure CreateVATPostingSetupForSalesTax(var VATPostingSetup: Record "VAT Posting Setup"; VATBusPostingGroup: Code[20])
    var
        VATProdPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup, VATProdPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Sales Tax");
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateCustomerWithVAT(VATBusPostingGroupCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure SetupCustomerInvoiceRoundingAccount(CustomerPostingGroupCode: Code[20]; VATPostingSetup: Record "VAT Posting Setup")
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        GLAccount: Record "G/L Account";
    begin
        CustomerPostingGroup.Get(CustomerPostingGroupCode);
        CustomerPostingGroup.Validate(
          "Invoice Rounding Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale));
        CustomerPostingGroup.Modify(true);
    end;

    local procedure CreateItemVATWithDeferral(AllowInvDisc: Boolean; VATProdPostingGroup: Code[20]; var DeferralPercent: Decimal; TaxGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
        DefaultDeferralCode: Code[10];
    begin
        // Create an Item with Invoice Discount, Unit Price
        DefaultDeferralCode := CreateDeferralCode(CalcMethod::"Straight-Line", StartDate::"Posting Date", 2, DeferralPercent);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Allow Invoice Disc.", AllowInvDisc);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Validate("Unit Price", 10 + LibraryRandom.RandInt(100));
        Item.Validate("Last Direct Cost", Item."Unit Price");
        Item.Validate("Default Deferral Template Code", DefaultDeferralCode);
        if TaxGroupCode <> '' then
            Item.Validate("Tax Group Code", TaxGroupCode);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure InitializePurchaseMultipleLinesEqualAmountsScenario(var PurchaseHeader: Record "Purchase Header"; var InvoiceDiscountAmount: Decimal; CurrencyCode: Code[10]; var DeferralPercent: Decimal; PostingDate: Date)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        ItemNo: Code[20];
        Index: Integer;
    begin
        CreateVATPostingSetup(VATPostingSetup, LibraryRandom.RandDecInRange(10, 20, 2));

        Vendor.Get(CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        SetupVendorInvoiceRoundingAccount(Vendor."Vendor Posting Group", VATPostingSetup);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);

        ItemNo := CreateItemVATWithDeferral(true, VATPostingSetup."VAT Prod. Posting Group", DeferralPercent, '');
        for Index := 1 to LibraryRandom.RandIntInRange(3, 10) do
            CreatePurchaseLine(PurchaseHeader, PurchaseLine, ItemNo, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2), 0);

        Currency.Initialize(CurrencyCode);
        InvoiceDiscountAmount := LibraryRandom.RandDec(100, 2);
    end;

    local procedure VerifySalesOrderInvoiceDiscountAmount(var SalesHeader: Record "Sales Header"; InvoiceDiscountAmount: Decimal)
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
    begin
        GetSalesVATAmountLine(SalesHeader, TempVATAmountLine, 0); // 0 means General update

        Assert.AreEqual(InvoiceDiscountAmount, TempVATAmountLine."Invoice Discount Amount", ChangedInvDiscountAmountErr);
    end;

    local procedure VerifyPurchaseOrderInvoiceDiscountAmount(var PurchaseHeader: Record "Purchase Header"; InvoiceDiscountAmount: Decimal)
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
    begin
        GetPurchaseVATAmountLine(PurchaseHeader, TempVATAmountLine, 0); // 0 means General update

        Assert.AreEqual(InvoiceDiscountAmount, TempVATAmountLine."Invoice Discount Amount", ChangedInvDiscountAmountErr);
    end;

    local procedure UpdateInvDiscAmtOnPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; NewInvoiceDiscountAmount: Decimal)
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
        PurchaseLine: Record "Purchase Line";
        UpdateType: Integer;
    begin
        UpdateType := 0; // 0 means General update
        GetPurchaseVATAmountLine(PurchaseHeader, TempVATAmountLine, UpdateType);
        TempVATAmountLine.SetInvoiceDiscountAmount(
          NewInvoiceDiscountAmount, PurchaseHeader."Currency Code",
          PurchaseHeader."Prices Including VAT", PurchaseHeader."VAT Base Discount %");
        PurchaseLine.UpdateVATOnLines(UpdateType, PurchaseHeader, PurchaseLine, TempVATAmountLine);
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; ItemCost: Decimal; Quantity: Decimal; LineDiscountPercent: Integer)
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        UpdatePurchaseLine(PurchaseLine, ItemCost, LineDiscountPercent);
    end;

    local procedure UpdatePurchaseLine(var PurchaseLine: Record "Purchase Line"; ItemCost: Decimal; LineDiscountPercent: Integer)
    begin
        PurchaseLine.Validate("Direct Unit Cost", ItemCost);
        PurchaseLine.Validate("Line Discount %", LineDiscountPercent);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; ItemCost: Decimal; Quantity: Decimal; LineDiscountPercent: Integer)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        UpdateSalesLine(SalesLine, ItemCost, LineDiscountPercent);
    end;

    local procedure UpdateSalesLine(var SalesLine: Record "Sales Line"; UnitPrice: Decimal; LineDiscountPercent: Integer)
    begin
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("Line Discount %", LineDiscountPercent);
        SalesLine.Modify(true);
    end;

    local procedure CreateVendorWithVATBusPostingGroup(VATBusPostingGroupCode: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure SetupVendorInvoiceRoundingAccount(VendorPostingGroupCode: Code[20]; VATPostingSetup: Record "VAT Posting Setup")
    var
        VendorPostingGroup: Record "Vendor Posting Group";
        GLAccount: Record "G/L Account";
    begin
        VendorPostingGroup.Get(VendorPostingGroupCode);
        VendorPostingGroup.Validate(
          "Invoice Rounding Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));
        VendorPostingGroup.Modify(true);
    end;

    local procedure GetPurchaseVATAmountLine(PurchaseHeader: Record "Purchase Header"; var VATAmountLine: Record "VAT Amount Line"; UpdateType: Integer)
    var
        TempPurchaseLine: Record "Purchase Line" temporary;
        PurchPost: Codeunit "Purch.-Post";
    begin
        PurchPost.GetPurchLines(PurchaseHeader, TempPurchaseLine, UpdateType);
        TempPurchaseLine.CalcVATAmountLines(UpdateType, PurchaseHeader, TempPurchaseLine, VATAmountLine);
    end;

    local procedure VerifySalesLineDeferralAmounts(var SalesHeader: Record "Sales Header"; NoOfPeriods: Integer; DeferralPercent: Decimal)
    var
        SalesLine: Record "Sales Line";
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
        repeat
            // The deferral schedule was created
            ValidateDeferralSchedule(DeferralHeader, DeferralLine, "Deferral Document Type"::Sales,
              SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.",
              SalesLine."Deferral Code", SalesHeader."Posting Date",
              SalesLine.GetDeferralAmount(), NoOfPeriods, DeferralPercent);
        until SalesLine.Next() = 0;
    end;

    local procedure VerifyPurchLineDeferralAmounts(var PurchHeader: Record "Purchase Header"; NoOfPeriods: Integer; DeferralPercent: Decimal)
    var
        PurchLine: Record "Purchase Line";
        DeferralHeader: Record "Deferral Header";
        DeferralLine: Record "Deferral Line";
    begin
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.FindSet();
        repeat
            // The deferral schedule was created
            ValidateDeferralSchedule(DeferralHeader, DeferralLine, "Deferral Document Type"::Purchase,
              PurchLine."Document Type".AsInteger(), PurchLine."Document No.", PurchLine."Line No.",
              PurchLine."Deferral Code", PurchHeader."Posting Date", PurchLine.GetDeferralAmount(), NoOfPeriods, DeferralPercent);
        until PurchLine.Next() = 0;
    end;

    local procedure ValidateDeferralSchedule(var DeferralHeader: Record "Deferral Header"; var DeferralLine: Record "Deferral Line"; DeferralDocType: Enum "Deferral Document Type"; DocType: Integer; DocNo: Code[20]; LineNo: Integer; DeferralTemplateCode: Code[10]; HeaderPostingDate: Date; HeaderAmountToDefer: Decimal; NoOfPeriods: Integer; DeferralPercent: Decimal)
    var
        Period: Integer;
        DeferralAmount: Decimal;
        PostingDate: Date;
    begin
        DeferralHeader.Get(DeferralDocType, '', '', DocType, DocNo, LineNo);
        DeferralHeader.TestField("Deferral Code", DeferralTemplateCode);
        DeferralHeader.TestField("Start Date", HeaderPostingDate);
        DeferralHeader.TestField("Amount to Defer",
          Round(HeaderAmountToDefer * (DeferralPercent / 100), Currency."Amount Rounding Precision"));
        DeferralHeader.TestField("No. of Periods", NoOfPeriods);

        DeferralLineSetRange(DeferralLine, DeferralDocType, DocType, DocNo, LineNo);
        Clear(DeferralAmount);
        Period := 0;
        if DeferralLine.FindSet() then
            repeat
                if Period = 0 then
                    PostingDate := HeaderPostingDate
                else
                    PostingDate := SetDateDay(1, HeaderPostingDate);
                PostingDate := PeriodDate(PostingDate, Period);
                DeferralLine.TestField("Posting Date", PostingDate);
                DeferralAmount := DeferralAmount + DeferralLine.Amount;
                Period := Period + 1;
            until DeferralLine.Next() = 0;
        DeferralHeader.TestField("Amount to Defer", DeferralAmount);
    end;

    local procedure DeferralLineSetRange(var DeferralLine: Record "Deferral Line"; DeferralDocType: Enum "Deferral Document Type"; DocType: Integer; DocNo: Code[20]; LineNo: Integer)
    begin
        DeferralLine.SetRange("Deferral Doc. Type", DeferralDocType);
        DeferralLine.SetRange("Gen. Jnl. Template Name", '');
        DeferralLine.SetRange("Gen. Jnl. Batch Name", '');
        DeferralLine.SetRange("Document Type", DocType);
        DeferralLine.SetRange("Document No.", DocNo);
        DeferralLine.SetRange("Line No.", LineNo);
    end;

    local procedure SetDateDay(Day: Integer; StartDate: Date): Date
    begin
        // Use the workdate but set to a specific day of that month
        exit(DMY2Date(Day, Date2DMY(StartDate, 2), Date2DMY(StartDate, 3)));
    end;

    local procedure PeriodDate(PostingDate: Date; Period: Integer): Date
    var
        Expr: Text[50];
    begin
        // Expr := '<' + FORMAT(Period) + 'M>';
        // EXIT(CALCDATE(Expr,PostingDate));
        Expr := Format(Period);
        exit(CalcDate('<' + Expr + 'M>', PostingDate));
    end;

    local procedure ValidateGL(DocNo: Code[20]; AccNo: Code[20]; PostingDate: Date; PeriodDate: Date; DeferralCount: Integer; DeferralSum: Decimal)
    var
        GLSum: Decimal;
        NonDeferralAmt: Decimal;
        GLCount: Integer;
    begin
        GLCalcSum(DocNo, AccNo, PostingDate, PeriodDate, GLCount, GLSum, NonDeferralAmt);
        ValidateAccounts(DeferralCount, DeferralSum, GLCount, GLSum);
    end;

    local procedure GLCalcSum(DocNo: Code[20]; AccNo: Code[20]; StartPostDate: Date; EndPostDate: Date; var RecCount: Integer; var AccAmt: Decimal; var NonDeferralAmt: Decimal): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        Clear(AccAmt);
        Clear(GLEntry);
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetRange("G/L Account No.", AccNo);
        GLEntry.SetRange("Posting Date", StartPostDate, EndPostDate);
        RecCount := GLEntry.Count();
        GLEntry.CalcSums(Amount);
        AccAmt := GLEntry.Amount;
        if GLEntry.FindFirst() then begin
            NonDeferralAmt := GLEntry.Amount;
            exit(GLEntry."Transaction No.");
        end;
    end;

    local procedure GetDeferralTemplateAccountForSalesLine(SalesHeader: Record "Sales Header"): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        exit(GetDeferralTemplateAccount(SalesLine."Deferral Code"));
    end;

    local procedure GetDeferralTemplateAccountForPurchLine(PurchaseHeader: Record "Purchase Header"): Code[20]
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        exit(GetDeferralTemplateAccount(PurchaseLine."Deferral Code"));
    end;

    local procedure ValidateAccounts(DeferralCount: Integer; DeferralAmount: Decimal; GLCount: Integer; GLAmt: Decimal)
    begin
        Assert.AreEqual(DeferralCount, GLCount, 'An incorrect number of lines was posted');
        Assert.AreEqual(DeferralAmount, GLAmt, 'An incorrect Amount was posted for purchase');
    end;

    local procedure VerifyDeferralAndVAT(DocNo: Code[20]; DeferralDocType: Option Purchase,Sales,"G/L"; AccNo: Code[20]; PostingDate: Date; PeriodDate: Date; DeferralCount: Integer; DeferralSum: Decimal)
    var
        NonDeferralAmt: Decimal;
        GLSum: Decimal;
        LineAmtExcVAT: Decimal;
        LineAmt: Decimal;
        GLCount: Integer;
        TransactionNo: Integer;
    begin
        TransactionNo := GLCalcSum(DocNo, AccNo, PostingDate, PeriodDate, GLCount, GLSum, NonDeferralAmt);
        ValidateAccounts(DeferralCount, DeferralSum, GLCount, GLSum);
        case DeferralDocType of
            DeferralDocType::Sales:
                SalesIvcLineCalcSum(DocNo, LineAmtExcVAT, LineAmt);
            DeferralDocType::Purchase:
                PurchaseIvcLineCalcSum(DocNo, LineAmtExcVAT, LineAmt);
        end;
        VerifyVAT(TransactionNo, LineAmtExcVAT, LineAmt);
        VerifyGLEntryAmount(TransactionNo, LineAmtExcVAT, LineAmt);
    end;

    local procedure VerifyTwoLinesAndVAT(DocNo: Code[20]; DeferralDocType: Option Purchase,Sales,"G/L"; PostingDate: Date; Line1AccNo: Code[20]; Line1PeriodDate: Date; Line1DeferralCount: Integer; Line2AccNo: Code[20]; Line2PeriodDate: Date; Line2DeferralCount: Integer)
    var
        NonDeferralAmt: Decimal;
        GLSum: Decimal;
        LineAmtExcVAT: Decimal;
        LineAmt: Decimal;
        GLCount: Integer;
        TransactionNo: Integer;
    begin
        TransactionNo := GLCalcSum(DocNo, Line1AccNo, PostingDate, Line1PeriodDate, GLCount, GLSum, NonDeferralAmt);
        ValidateAccounts(Line1DeferralCount, 0, GLCount, GLSum);
        TransactionNo := GLCalcSum(DocNo, Line2AccNo, PostingDate, Line2PeriodDate, GLCount, GLSum, NonDeferralAmt);
        ValidateAccounts(Line2DeferralCount, 0, GLCount, GLSum);
        case DeferralDocType of
            DeferralDocType::Sales:
                SalesIvcLineCalcSum(DocNo, LineAmtExcVAT, LineAmt);
            DeferralDocType::Purchase:
                PurchaseIvcLineCalcSum(DocNo, LineAmtExcVAT, LineAmt);
        end;
        VerifyVAT(TransactionNo, LineAmtExcVAT, LineAmt);
        VerifyGLEntryAmount(TransactionNo, LineAmtExcVAT, LineAmt);
    end;

    local procedure VerifyVAT(TransactionNo: Integer; LineAmtExcVAT: Decimal; LineAmt: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetCurrentKey("Transaction No.");
        VATEntry.SetRange("Transaction No.", TransactionNo);
        VATEntry.CalcSums(Amount, Base);
        Assert.AreEqual(Abs(VATEntry.Base), LineAmtExcVAT, 'VAT Base Amount is not correct for the Discount');
        Assert.AreEqual(Abs(VATEntry.Amount), LineAmt, 'VAT Amount is not correct for the Discount');
    end;

    local procedure VerifyGLEntryAmount(TransactionNo: Integer; ExpectedAmount: Decimal; ExpectedVATAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Transaction No.", TransactionNo);
        GLEntry.SetFilter("Gen. Posting Type", '<>%1', GLEntry."Gen. Posting Type"::" ");
        GLEntry.CalcSums(Amount, "VAT Amount");
        Assert.AreEqual(ExpectedAmount, Abs(GLEntry.Amount), GLEntry.FieldCaption(Amount));
        Assert.AreEqual(ExpectedVATAmount, Abs(GLEntry."VAT Amount"), GLEntry.FieldCaption("VAT Amount"));
    end;

    local procedure SalesIvcLineCalcSum(DocNo: Code[20]; var SalesLineAmtExcVAT: Decimal; var SalesLineAmt: Decimal)
    var
        SalesInvLine: Record "Sales Invoice Line";
    begin
        Clear(SalesInvLine);
        SalesInvLine.SetRange("Document No.", DocNo);
        SalesInvLine.CalcSums(Amount, "Amount Including VAT");
        SalesLineAmtExcVAT := SalesInvLine.Amount;
        SalesLineAmt := SalesInvLine."Amount Including VAT" - SalesInvLine.Amount;
    end;

    local procedure PurchaseIvcLineCalcSum(DocNo: Code[20]; var PurchLineAmtExcVAT: Decimal; var PurchLineAmt: Decimal)
    var
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        Clear(PurchInvLine);
        PurchInvLine.SetRange("Document No.", DocNo);
        PurchInvLine.CalcSums(Amount, "Amount Including VAT");
        PurchLineAmtExcVAT := PurchInvLine.Amount;
        PurchLineAmt := PurchInvLine."Amount Including VAT" - PurchInvLine.Amount;
    end;

    local procedure CreateSalesDocWithLineInvoiceDisc(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; var DeferralPercent: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        CreateVATPostingSetup(VATPostingSetup, LibraryRandom.RandDecInRange(10, 20, 2));
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomerWithVAT(VATPostingSetup."VAT Bus. Posting Group"));
        SalesHeader.Validate("Posting Date", SetDateDay(15, WorkDate()));
        SalesHeader.Modify();

        CreateGLAccount(GLAccount, VATPostingSetup."VAT Prod. Posting Group", DeferralPercent);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", 20);
        SalesLine.Validate("Allow Invoice Disc.", true);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLine.Validate("Line Discount %", LibraryRandom.RandIntInRange(10, 39));
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseDocWithLineInvoiceDisc(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; var DeferralPercent: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        CreateVATPostingSetup(VATPostingSetup, LibraryRandom.RandDecInRange(10, 20, 2));
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, DocumentType, CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        PurchHeader.Validate("Posting Date", SetDateDay(15, WorkDate()));
        PurchHeader.Modify();

        CreateGLAccount(GLAccount, VATPostingSetup."VAT Prod. Posting Group", DeferralPercent);

        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::"G/L Account", GLAccount."No.", 20);
        PurchLine.Validate("Allow Invoice Disc.", true);
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(1000, 2));
        PurchLine.Validate("Line Discount %", LibraryRandom.RandIntInRange(10, 39));
        PurchLine.Modify();
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account"; VATProdPostingGroup: Code[20]; var DeferralPercent: Decimal)
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        GLAccount.Validate(
          "Default Deferral Template Code", CreateDeferralCode(CalcMethod::"Straight-Line", StartDate::"Posting Date", 3, DeferralPercent));
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Modify();
    end;

    local procedure InitializeSalesMultipleLinesMultiplelVATPercentScenario(var SalesHeader: Record "Sales Header"; var InvoiceDiscountAmount: Decimal; CurrencyCode: Code[10]; var DeferralPercent: Decimal; var Line1AccNo: Code[20]; var Line2AccNo: Code[20])
    var
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        ItemNo: Code[20];
    begin
        CreateTwoVATPostingSetups(VATPostingSetup, LibraryRandom.RandDecInRange(10, 20, 2));

        Customer.Get(CreateCustomerWithVAT(VATPostingSetup[1]."VAT Bus. Posting Group"));
        SetupCustomerInvoiceRoundingAccount(Customer."Customer Posting Group", VATPostingSetup[1]);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Validate("Posting Date", SetDateDay(13, WorkDate()));
        SalesHeader.Modify(true);

        CreateGLAccount(GLAccount, VATPostingSetup[1]."VAT Prod. Posting Group", DeferralPercent);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccount."No.", 2);
        UpdateSalesLine(SalesLine, LibraryRandom.RandDec(1000, 2), LibraryRandom.RandIntInRange(10, 99));
        Line1AccNo := GetDeferralTemplateAccount(SalesLine."Deferral Code");

        ItemNo := CreateItemVATWithDeferral(true, VATPostingSetup[2]."VAT Prod. Posting Group", DeferralPercent, '');
        CreateSalesLine(SalesHeader, SalesLine, ItemNo, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2), 0);
        Line2AccNo := GetDeferralTemplateAccount(SalesLine."Deferral Code");

        Currency.Initialize(CurrencyCode);
        InvoiceDiscountAmount := LibraryRandom.RandDec(100, 2);
    end;

    local procedure InitializePurchaseMultipleLinesMultipleVATPercentScenario(var PurchHeader: Record "Purchase Header"; var InvoiceDiscountAmount: Decimal; CurrencyCode: Code[10]; var DeferralPercent: Decimal; var Line1AccNo: Code[20]; var Line2AccNo: Code[20])
    var
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        PurchLine: Record "Purchase Line";
        Vendor: Record Vendor;
        GLAccount: Record "G/L Account";
        ItemNo: Code[20];
    begin
        CreateTwoVATPostingSetups(VATPostingSetup, LibraryRandom.RandDecInRange(10, 20, 2));

        Vendor.Get(CreateVendorWithVATBusPostingGroup(VATPostingSetup[1]."VAT Bus. Posting Group"));
        SetupVendorInvoiceRoundingAccount(Vendor."Vendor Posting Group", VATPostingSetup[1]);

        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, Vendor."No.");
        PurchHeader.Validate("Currency Code", CurrencyCode);
        PurchHeader.Validate("Posting Date", SetDateDay(13, WorkDate()));
        PurchHeader.Modify(true);

        CreateGLAccount(GLAccount, VATPostingSetup[1]."VAT Prod. Posting Group", DeferralPercent);

        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::"G/L Account", GLAccount."No.", 2);
        UpdatePurchaseLine(PurchLine, LibraryRandom.RandDec(1000, 2), LibraryRandom.RandIntInRange(10, 99));
        Line1AccNo := GetDeferralTemplateAccount(PurchLine."Deferral Code");

        ItemNo := CreateItemVATWithDeferral(true, VATPostingSetup[2]."VAT Prod. Posting Group", DeferralPercent, '');
        CreatePurchaseLine(PurchHeader, PurchLine, ItemNo, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2), 0);
        Line2AccNo := GetDeferralTemplateAccount(PurchLine."Deferral Code");

        Currency.Initialize(CurrencyCode);
        InvoiceDiscountAmount := LibraryRandom.RandDec(100, 2);
    end;

    local procedure CreateTwoVATPostingSetups(var VATPostingSetup: array[2] of Record "VAT Posting Setup"; VATRate: Decimal)
    var
        DummyGLAccount: Record "G/L Account";
        i: Integer;
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup[1], VATPostingSetup[1]."VAT Calculation Type"::"Normal VAT", VATRate);

        DummyGLAccount."VAT Bus. Posting Group" := VATPostingSetup[1]."VAT Bus. Posting Group";
        DummyGLAccount."VAT Prod. Posting Group" := VATPostingSetup[1]."VAT Prod. Posting Group";
        VATPostingSetup[2].Get(VATPostingSetup[1]."VAT Bus. Posting Group", LibraryERM.CreateRelatedVATPostingSetup(DummyGLAccount));
        VATPostingSetup[2].Validate("VAT Identifier", LibraryUtility.GenerateGUID());
        VATPostingSetup[2].Validate("VAT %", LibraryRandom.RandDec(100, 2));
        VATPostingSetup[2].Modify(true);

        for i := 1 to ArrayLen(VATPostingSetup) do
            UpdateVATPostingSetupAccounts(VATPostingSetup[i]);
    end;

    local procedure UpdateVATPostingSetupAccounts(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountWithSalesSetup());
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountWithPurchSetup());
        VATPostingSetup.Modify(true);
    end;

    local procedure GetDeferralTemplateAccount(DeferralCode: Code[10]): Code[20]
    var
        DeferralTemplate: Record "Deferral Template";
    begin
        DeferralTemplate.Get(DeferralCode);
        exit(DeferralTemplate."Deferral Account");
    end;

    local procedure CreateSalesDocWithSalesTax(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; var DeferralPercent: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        TaxDetail: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
        ItemNo: Code[20];
        TaxGroupCode: Code[20];
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Tax Area Code", CreateTaxArea());
        Customer.Validate("Tax Liable", true);
        Customer.Validate("Prices Including VAT", false);
        Customer.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
        SalesHeader.Validate("Posting Date", SetDateDay(15, WorkDate()));
        SalesHeader.Modify();

        // Create Posting Setup for Sales Tax.
        CreateVATPostingSetupForSalesTax(VATPostingSetup, SalesHeader."VAT Bus. Posting Group");
        SetupSalesTax(
          TaxDetail, TaxJurisdiction, Customer."Tax Area Code", TaxGroupCode, TaxDetail."Tax Type"::"Sales Tax",
          1000, SetDateDay(15, WorkDate()));

        ItemNo := CreateItemVATWithDeferral(true, VATPostingSetup."VAT Prod. Posting Group", DeferralPercent, TaxGroupCode);

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, 10 + LibraryRandom.RandInt(10));
        UpdateSalesLine(SalesLine, LibraryRandom.RandDec(100, 2), LibraryRandom.RandIntInRange(10, 39));
    end;

    local procedure CreatePurchaseDocWithSalesTax(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; var DeferralPercent: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        TaxDetail: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
        ItemNo: Code[20];
        TaxGroupCode: Code[20];
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Tax Area Code", CreateTaxArea());
        Vendor.Validate("Tax Liable", true);
        Vendor.Validate("Prices Including VAT", false);
        Vendor.Modify(true);

        LibraryPurchase.CreatePurchHeader(PurchHeader, DocumentType, Vendor."No.");
        PurchHeader.Validate("Tax Area Code", Vendor."Tax Area Code");
        PurchHeader.Validate("Tax Liable", true);
        PurchHeader.Validate("Posting Date", SetDateDay(15, WorkDate()));
        PurchHeader.Modify();

        CreateVATPostingSetupForSalesTax(VATPostingSetup, PurchHeader."VAT Bus. Posting Group");
        SetupSalesTax(
          TaxDetail, TaxJurisdiction, Vendor."Tax Area Code", TaxGroupCode, TaxDetail."Tax Type"::"Sales Tax",
          1000, SetDateDay(15, WorkDate()));
        ItemNo := CreateItemVATWithDeferral(true, VATPostingSetup."VAT Prod. Posting Group", DeferralPercent, TaxGroupCode);

        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::Item, ItemNo, 10 + LibraryRandom.RandInt(10));
        UpdatePurchaseLine(PurchLine, LibraryRandom.RandDec(100, 2), LibraryRandom.RandIntInRange(10, 39));
    end;

    local procedure SetupSalesTax(var TaxDetail: Record "Tax Detail"; var TaxJurisdiction: Record "Tax Jurisdiction"; TaxAreaCode: Code[20]; var TaxGroupCode: Code[20]; TaxType: Option; MaxAmountQty: Decimal; EffectiveDate: Date)
    begin
        TaxGroupCode := CreateTaxGroup();
        CreateTaxJurisdiction(TaxJurisdiction);
        CreateTaxAreaLine(TaxAreaCode, TaxJurisdiction.Code);
        CreateTaxDetail(TaxDetail, TaxJurisdiction.Code, TaxGroupCode, TaxType, EffectiveDate, false);
        TaxDetail.Validate("Maximum Amount/Qty.", MaxAmountQty);
        if MaxAmountQty = 0 then
            TaxDetail.Validate("Tax Above Maximum", 0);
        TaxDetail.Modify(true);
    end;

    local procedure CreateTaxArea(): Code[20]
    var
        TaxArea: Record "Tax Area";
    begin
        LibraryERM.CreateTaxArea(TaxArea);
        exit(TaxArea.Code);
    end;

    local procedure CreateTaxAreaLine(TaxArea: Code[20]; TaxJurisdiction: Code[10])
    var
        TaxAreaLine: Record "Tax Area Line";
    begin
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea, TaxJurisdiction);
        TaxAreaLine.Validate("Calculation Order", GetNextCalcOrdTaxAreaLine(TaxArea));
        TaxAreaLine.Modify(true);
    end;

    local procedure CreateTaxDetail(var TaxDetail: Record "Tax Detail"; TaxJurisdictionCode: Code[10]; TaxGroupCode: Code[20]; TaxType: Option; EffectiveDate: Date; CalcTaxonTax: Boolean)
    begin
        LibraryERM.CreateTaxDetail(TaxDetail, TaxJurisdictionCode, TaxGroupCode, TaxType, EffectiveDate);
        TaxDetail.Validate("Maximum Amount/Qty.", 100 * LibraryRandom.RandDec(100, 2));
        TaxDetail.Validate("Tax Below Maximum", LibraryRandom.RandInt(5));
        TaxDetail.Validate("Tax Above Maximum", LibraryRandom.RandIntInRange(TaxDetail."Tax Below Maximum", 10));
        TaxDetail.Validate("Calculate Tax on Tax", CalcTaxonTax);
        TaxDetail.Modify(true);
    end;

    local procedure CreateTaxGroup(): Code[10]
    var
        TaxGroup: Record "Tax Group";
    begin
        LibraryERM.CreateTaxGroup(TaxGroup);
        exit(TaxGroup.Code);
    end;

    local procedure CreateTaxJurisdiction(var TaxJurisdiction: Record "Tax Jurisdiction")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount."Income/Balance" := GLAccount."Income/Balance"::"Balance Sheet";
        GLAccount.Modify();
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        TaxJurisdiction.Validate("Tax Account (Sales)", GLAccount."No.");
        TaxJurisdiction.Validate("Tax Account (Purchases)", GLAccount."No.");
        TaxJurisdiction.Modify(true);
    end;

    local procedure GetNextCalcOrdTaxAreaLine(TaxArea: Code[20]): Integer
    var
        TaxAreaLine: Record "Tax Area Line";
    begin
        TaxAreaLine.SetFilter("Tax Area", TaxArea);
        TaxAreaLine.SetCurrentKey("Tax Area", "Calculation Order");
        TaxAreaLine.FindLast();
        exit(TaxAreaLine."Calculation Order" + 1);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;
}

