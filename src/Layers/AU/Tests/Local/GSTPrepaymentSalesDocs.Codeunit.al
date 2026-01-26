codeunit 144000 "GST Prepayment - Sales Docs"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [GST] [Prepayment] [Sales]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryAULocalization: Codeunit "Library - AU Localization";
        isInitialized: Boolean;
        ValidationError: Label '%1 must be %2 in %3.';
        EntriesError: Label 'VAT Entries should not be created.';

    local procedure Initialize()
    begin
        if isInitialized then
            exit;

        LibraryAULocalization.EnableGSTSetup(true, true);

        isInitialized := true;
        Commit();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepInvFullInvExclVATNotFullPrep()
    var
        GLEntry: Record "G/L Entry";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenPostingSetup: Record "General Posting Setup";
        DocNo: Code[10];
        DocNo2: Code[10];
    begin
        Initialize();

        LibraryAULocalization.EnableGSTSetup(true, false);

        // Setup
        CreatePostingSetup(GenPostingSetup);
        CreateHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(GenPostingSetup."Gen. Bus. Posting Group"));
        ChangePrepaymentOnHeader(SalesHeader, LibraryRandom.RandInt(50));
        CreateLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(GenPostingSetup."Gen. Prod. Posting Group"));

        // Exercise
        SalesHeader2 := SalesHeader;
        DocNo := PostPrepInvoice(SalesHeader);
        DocNo2 := PostDocument(SalesHeader);

        // Verify
        VerifyPrepaymentGLEntries(DocNo, GLEntry."Document Type"::Invoice, SalesHeader2, SalesLine, true);
        VerifyPrepaymentVATEntries(DocNo, GLEntry."Document Type"::Invoice, SalesLine, true);
        VerifyInvoiceGLEntries(DocNo2, GLEntry."Document Type"::Invoice, SalesHeader2, SalesLine, SalesHeader."Prepayment %");
        VerifyInvoiceVATEntries(DocNo2, GLEntry."Document Type"::Invoice, SalesLine);

        // Tear Down
        LibraryAULocalization.EnableGSTSetup(true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepInvFullInvExclVAT()
    begin
        PrepInvFullInv(LibraryRandom.RandInt(50), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepInvFullInvInclVAT()
    begin
        PrepInvFullInv(LibraryRandom.RandInt(50), true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepInvFullInvMultipleLinesDifferentRatesExclVAT()
    begin
        PrepInvFullInvMultipleLinesDifferentRates(LibraryRandom.RandInt(50), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepInvFullInvMultipleLinesDifferentRatesInclVAT()
    begin
        PrepInvFullInvMultipleLinesDifferentRates(LibraryRandom.RandInt(50), true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepInvFullInvMultipleLinesDifferentRatesAndPrepaymentExclVAT()
    begin
        PrepInvFullInvMultipleLinesDifferentRatesAndPrepayment(LibraryRandom.RandInt(50), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepInvFullInvMultipleLinesDifferentRatesAndPrepaymentInclVAT()
    begin
        PrepInvFullInvMultipleLinesDifferentRatesAndPrepayment(LibraryRandom.RandInt(50), true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepInvFullInvExclVATPrep100()
    begin
        PrepInvFullInv(100, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepInvFullInvInclVATPrep100()
    begin
        PrepInvFullInv(100, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepInvFullInvMultipleLinesDifferentRatesExclVATPrep100()
    begin
        PrepInvFullInvMultipleLinesDifferentRates(100, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepInvFullInvMultipleLinesDifferentRatesInclVATPrep100()
    begin
        PrepInvFullInvMultipleLinesDifferentRates(100, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepInvPrepCrMemoExclVAT()
    begin
        PrepInvPrepCrMemo(LibraryRandom.RandInt(50), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepInvPrepCrMemoInclVAT()
    begin
        PrepInvPrepCrMemo(LibraryRandom.RandInt(50), true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepInvPrepCrMemoMultipleLinesDifferentRatesExclVAT()
    begin
        PrepInvPrepCrMemoMultipleLinesDifferentRates(LibraryRandom.RandInt(50), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepInvPrepCrMemoMultipleLinesDifferentRatesInclVAT()
    begin
        PrepInvPrepCrMemoMultipleLinesDifferentRates(LibraryRandom.RandInt(50), true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepInvPrepCrMemoExclVATPrep100()
    begin
        PrepInvPrepCrMemo(100, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepInvPrepCrMemoInclVATPrep100()
    begin
        PrepInvPrepCrMemo(100, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepInvPrepCrMemoMultipleLinesDifferentRatesExclVATPrep100()
    begin
        PrepInvPrepCrMemoMultipleLinesDifferentRates(100, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepInvPrepCrMemoMultipleLinesDifferentRatesInclVATPrep100()
    begin
        PrepInvPrepCrMemoMultipleLinesDifferentRates(100, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepInvChangePrepPercFullInvExclVAT()
    begin
        PrepInvChangePrepPercFullInv(LibraryRandom.RandInt(50), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepInvChangePrepPercFullInvInclVAT()
    begin
        PrepInvChangePrepPercFullInv(LibraryRandom.RandInt(50), true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepInvChangePrepPercCrMemoExclVAT()
    begin
        PrepInvChangePrepPercCrMemo(LibraryRandom.RandInt(50), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepInvChangePrepPercCrMemoInclVAT()
    begin
        PrepInvChangePrepPercCrMemo(LibraryRandom.RandInt(50), true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepInvPartInvFullInvExclVAT()
    begin
        //r01
        PrepInvPartInvFullInv(LibraryRandom.RandInt(50), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepInvPartInvFullInvInclVAT()
    begin
        PrepInvPartInvFullInv(LibraryRandom.RandInt(50), true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepInvPartInv2FullInvExclVAT()
    begin
        PrepInvPartInv2FullInv(LibraryRandom.RandInt(50), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepInvPartInv2FullInvInclVAT()
    begin
        PrepInvPartInv2FullInv(LibraryRandom.RandInt(50), true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepInvFullInvFCYExclVAT()
    begin
        PrepInvFullInvFCY(LibraryRandom.RandInt(50), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepInvFullInvFCYInclVAT()
    begin
        PrepInvFullInvFCY(LibraryRandom.RandInt(50), true);
    end;

    [Test]
    [HandlerFunctions('UpdateExchRateConfirmHandler')]
    [Scope('OnPrem')]
    procedure PrepInvChangeRateFullInvFCYGainExclVAT()
    begin
        PrepInvChangeRateFullInvFCYGain(LibraryRandom.RandInt(50), false);
    end;

    [Test]
    [HandlerFunctions('UpdateExchRateConfirmHandler')]
    [Scope('OnPrem')]
    procedure PrepInvChangeRateFullInvFCYGainInclVAT()
    begin
        PrepInvChangeRateFullInvFCYGain(LibraryRandom.RandInt(50), true);
    end;

    [Test]
    [HandlerFunctions('UpdateExchRateConfirmHandler')]
    [Scope('OnPrem')]
    procedure PrepInvChangeRateFullInvFCYGainExclVAT100()
    begin
        PrepInvChangeRateFullInvFCYGain(100, false);
    end;

    [Test]
    [HandlerFunctions('UpdateExchRateConfirmHandler')]
    [Scope('OnPrem')]
    procedure PrepInvChangeRateFullInvFCYGainInclVAT100()
    begin
        PrepInvChangeRateFullInvFCYGain(100, true);
    end;

    [Test]
    [HandlerFunctions('UpdateExchRateConfirmHandler')]
    [Scope('OnPrem')]
    procedure PrepInvChangeRateFullInvFCYLossExclVAT()
    begin
        PrepInvChangeRateFullInvFCYLoss(LibraryRandom.RandInt(50), false);
    end;

    [Test]
    [HandlerFunctions('UpdateExchRateConfirmHandler')]
    [Scope('OnPrem')]
    procedure PrepInvChangeRateFullInvFCYLossInclVAT()
    begin
        PrepInvChangeRateFullInvFCYLoss(LibraryRandom.RandInt(50), true);
    end;

    [Test]
    [HandlerFunctions('UpdateExchRateConfirmHandler')]
    [Scope('OnPrem')]
    procedure PrepInvChangeRateFullInvFCYLossExclVAT100()
    begin
        PrepInvChangeRateFullInvFCYLoss(100, false);
    end;

    [Test]
    [HandlerFunctions('UpdateExchRateConfirmHandler')]
    [Scope('OnPrem')]
    procedure PrepInvChangeRateFullInvFCYLossInclVAT100()
    begin
        PrepInvChangeRateFullInvFCYLoss(100, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepInvFullInvUnrealizedExclVAT()
    begin
        PrepInvFullInvUnrealized(LibraryRandom.RandInt(50), false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepInvFullInvUnrealizedInclVAT()
    begin
        PrepInvFullInvUnrealized(LibraryRandom.RandInt(50), true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GSTSalesEntries_ZeroBase()
    var
        GSTSalesEntry: Record "GST Sales Entry";
        GSTSalesEntries: TestPage "GST Sales Entries";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 312138] Stan can open "GST Sales Entries" page with entries having "GST Base" = 0
        GSTSalesEntry.Init();
        GSTSalesEntry.Amount := LibraryRandom.RandDecInRange(10, 20, 2);
        GSTSalesEntry.Insert(true);

        GSTSalesEntries.OpenView();
        GSTSalesEntries.Close();
    end;

    local procedure PrepInvFullInv(PrepaymentPercent: Decimal; PricesIncludeVAT: Boolean)
    var
        GLEntry: Record "G/L Entry";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenPostingSetup: Record "General Posting Setup";
        DocNo: Code[10];
        DocNo2: Code[10];
    begin
        Initialize();

        // Setup
        CreatePostingSetup(GenPostingSetup);
        CreateHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(GenPostingSetup."Gen. Bus. Posting Group"));
        ChangePricesIncludingVAT(SalesHeader, PricesIncludeVAT);
        ChangePrepaymentOnHeader(SalesHeader, PrepaymentPercent);
        CreateLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(GenPostingSetup."Gen. Prod. Posting Group"));

        // Exercise
        SalesHeader2 := SalesHeader;
        DocNo := PostPrepInvoice(SalesHeader);
        DocNo2 := PostDocument(SalesHeader);

        // Verify
        VerifyPrepaymentGLEntries(DocNo, GLEntry."Document Type"::Invoice, SalesHeader2, SalesLine, true);
        VerifyPrepaymentVATEntries(DocNo, GLEntry."Document Type"::Invoice, SalesLine, true);
        VerifyInvoiceGLEntries(DocNo2, GLEntry."Document Type"::Invoice, SalesHeader2, SalesLine, PrepaymentPercent);
        VerifyInvoiceVATEntries(DocNo2, GLEntry."Document Type"::Invoice, SalesLine);
    end;

    local procedure PrepInvFullInvMultipleLinesDifferentRates(PrepaymentPercent: Decimal; PricesIncludeVAT: Boolean)
    var
        GLEntry: Record "G/L Entry";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        GenPostingSetup: Record "General Posting Setup";
        DocNo: Code[10];
        DocNo2: Code[10];
    begin
        Initialize();

        // Setup
        CreatePostingSetup(GenPostingSetup);
        CreateHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(GenPostingSetup."Gen. Bus. Posting Group"));
        ChangePricesIncludingVAT(SalesHeader, PricesIncludeVAT);
        ChangePrepaymentOnHeader(SalesHeader, PrepaymentPercent);
        CreateLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(GenPostingSetup."Gen. Prod. Posting Group"));
        CreatePostingSetupWithDifferentVATRate(GenPostingSetup, SalesLine);
        CreateLine(SalesLine2, SalesHeader, SalesLine.Type::Item, CreateItem(GenPostingSetup."Gen. Prod. Posting Group"));

        // Exercise
        SalesHeader2 := SalesHeader;
        DocNo := PostPrepInvoice(SalesHeader);
        DocNo2 := PostDocument(SalesHeader);

        // Verify
        VerifyPrepaymentGLEntriesMultipleLinesDifferentRates(
          DocNo, GLEntry."Document Type"::Invoice, SalesHeader2, SalesLine, SalesLine2, true);
        VerifyPrepaymentVATEntriesMultipleLinesDifferentRates(
          DocNo, GLEntry."Document Type"::Invoice, SalesLine, SalesLine2, true);
        VerifyInvoiceGLEntriesMultipleLinesDifferentRates(
          DocNo2, GLEntry."Document Type"::Invoice, SalesHeader2, SalesLine, SalesLine2, PrepaymentPercent);
        VerifyInvoiceVATEntriesMultipleLinesDifferentRates(DocNo2, GLEntry."Document Type"::Invoice, SalesLine, SalesLine2);
    end;

    local procedure PrepInvFullInvMultipleLinesDifferentRatesAndPrepayment(PrepaymentPercent: Decimal; PricesIncludeVAT: Boolean)
    var
        GLEntry: Record "G/L Entry";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        GenPostingSetup: Record "General Posting Setup";
        DocNo: Code[10];
        DocNo2: Code[10];
    begin
        Initialize();

        // Setup
        CreatePostingSetup(GenPostingSetup);
        CreateHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(GenPostingSetup."Gen. Bus. Posting Group"));
        ChangePricesIncludingVAT(SalesHeader, PricesIncludeVAT);
        ChangePrepaymentOnHeader(SalesHeader, PrepaymentPercent);
        CreateLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(GenPostingSetup."Gen. Prod. Posting Group"));
        CreatePostingSetupWithDifferentVATRate(GenPostingSetup, SalesLine);
        CreateLine(SalesLine2, SalesHeader, SalesLine.Type::Item, CreateItem(GenPostingSetup."Gen. Prod. Posting Group"));
        ChangePrepaymentOnLine(SalesHeader, SalesLine2, PrepaymentPercent * 3 / 2);

        // Exercise
        SalesHeader2 := SalesHeader;
        DocNo := PostPrepInvoice(SalesHeader);
        DocNo2 := PostDocument(SalesHeader);

        // Verify
        VerifyPrepaymentGLEntriesMultipleLinesDifferentRates(
          DocNo, GLEntry."Document Type"::Invoice, SalesHeader2, SalesLine, SalesLine2, true);
        VerifyPrepaymentVATEntriesMultipleLinesDifferentRates(
          DocNo, GLEntry."Document Type"::Invoice, SalesLine, SalesLine2, true);
        VerifyInvoiceGLEntriesMultipleLinesDifferentRates(
          DocNo2, GLEntry."Document Type"::Invoice, SalesHeader2, SalesLine, SalesLine2, PrepaymentPercent);
        VerifyInvoiceVATEntriesMultipleLinesDifferentRates(DocNo2, GLEntry."Document Type"::Invoice, SalesLine, SalesLine2);
    end;

    local procedure PrepInvPrepCrMemo(PrepaymentPercent: Decimal; PricesIncludeVAT: Boolean)
    var
        GLEntry: Record "G/L Entry";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenPostingSetup: Record "General Posting Setup";
        DocNo: Code[10];
    begin
        Initialize();

        // Setup
        CreatePostingSetup(GenPostingSetup);
        CreateHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(GenPostingSetup."Gen. Bus. Posting Group"));
        ChangePricesIncludingVAT(SalesHeader, PricesIncludeVAT);
        ChangePrepaymentOnHeader(SalesHeader, PrepaymentPercent);
        CreateLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(GenPostingSetup."Gen. Prod. Posting Group"));

        // Exercise
        SalesHeader2 := SalesHeader;
        PostPrepInvoice(SalesHeader);
        DocNo := PostPrepCreditMemo(SalesHeader);

        // Verify
        VerifyPrepaymentGLEntries(DocNo, GLEntry."Document Type"::"Credit Memo", SalesHeader2, SalesLine, false);
        VerifyPrepaymentVATEntries(DocNo, GLEntry."Document Type"::"Credit Memo", SalesLine, false);
    end;

    local procedure PrepInvPrepCrMemoMultipleLinesDifferentRates(PrepaymentPercent: Decimal; PricesIncludeVAT: Boolean)
    var
        GLEntry: Record "G/L Entry";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        GenPostingSetup: Record "General Posting Setup";
        DocNo: Code[10];
    begin
        Initialize();

        // Setup
        CreatePostingSetup(GenPostingSetup);
        CreateHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(GenPostingSetup."Gen. Bus. Posting Group"));
        ChangePricesIncludingVAT(SalesHeader, PricesIncludeVAT);
        ChangePrepaymentOnHeader(SalesHeader, PrepaymentPercent);
        CreateLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(GenPostingSetup."Gen. Prod. Posting Group"));
        CreatePostingSetupWithDifferentVATRate(GenPostingSetup, SalesLine);
        CreateLine(SalesLine2, SalesHeader, SalesLine.Type::Item, CreateItem(GenPostingSetup."Gen. Prod. Posting Group"));

        // Exercise
        SalesHeader2 := SalesHeader;
        PostPrepInvoice(SalesHeader);
        DocNo := PostPrepCreditMemo(SalesHeader);

        // Verify
        VerifyPrepaymentGLEntriesMultipleLinesDifferentRates(
          DocNo, GLEntry."Document Type"::"Credit Memo", SalesHeader2, SalesLine, SalesLine2, false);
        VerifyPrepaymentVATEntriesMultipleLinesDifferentRates(
          DocNo, GLEntry."Document Type"::"Credit Memo", SalesLine, SalesLine2, false);
    end;

    local procedure PrepInvChangePrepPercFullInv(PrepaymentPercent: Decimal; PricesIncludeVAT: Boolean)
    var
        GLEntry: Record "G/L Entry";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenPostingSetup: Record "General Posting Setup";
        DocNo: Code[10];
        DocNo2: Code[10];
    begin
        Initialize();

        // Setup
        CreatePostingSetup(GenPostingSetup);
        CreateHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(GenPostingSetup."Gen. Bus. Posting Group"));
        ChangePricesIncludingVAT(SalesHeader, PricesIncludeVAT);
        ChangePrepaymentOnHeader(SalesHeader, PrepaymentPercent);
        CreateLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(GenPostingSetup."Gen. Prod. Posting Group"));

        // Exercise
        PostPrepInvoice(SalesHeader);
        ChangePrepaymentOnHeader(SalesHeader, SalesHeader."Prepayment %" * 3 / 2);
        SalesLine.Find();
        SalesHeader2 := SalesHeader;
        DocNo := PostPrepInvoice(SalesHeader);
        DocNo2 := PostDocument(SalesHeader);

        // Verify
        VerifyAdditionalPrepaymentGLEntries(DocNo, GLEntry."Document Type"::Invoice, SalesHeader2, SalesLine);
        VerifyAdditionalPrepaymentVATEntries(DocNo, GLEntry."Document Type"::Invoice, SalesLine);
        VerifyInvoiceGLEntries(DocNo2, GLEntry."Document Type"::Invoice, SalesHeader2, SalesLine, PrepaymentPercent);
        VerifyInvoiceVATEntries(DocNo2, GLEntry."Document Type"::Invoice, SalesLine);
    end;

    local procedure PrepInvChangePrepPercCrMemo(PrepaymentPercent: Decimal; PricesIncludeVAT: Boolean)
    var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenPostingSetup: Record "General Posting Setup";
        DocNo: Code[10];
    begin
        Initialize();

        // Setup
        CreatePostingSetup(GenPostingSetup);
        CreateHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(GenPostingSetup."Gen. Bus. Posting Group"));
        ChangePricesIncludingVAT(SalesHeader, PricesIncludeVAT);
        ChangePrepaymentOnHeader(SalesHeader, PrepaymentPercent);
        CreateLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(GenPostingSetup."Gen. Prod. Posting Group"));

        // Exercise
        PostPrepInvoice(SalesHeader);
        ChangePrepaymentOnHeader(SalesHeader, SalesHeader."Prepayment %" * 3 / 2);
        SalesLine.Find();
        SalesHeader2 := SalesHeader;
        PostPrepInvoice(SalesHeader);
        DocNo := PostPrepCreditMemo(SalesHeader);

        // Verify
        VerifyPrepaymentGLEntries(DocNo, GLEntry."Document Type"::"Credit Memo", SalesHeader2, SalesLine, false);
        VerifyPrepaymentVATEntries(DocNo, VATEntry."Document Type"::"Credit Memo", SalesLine, false);
    end;

    local procedure PrepInvPartInvFullInv(PrepaymentPercent: Decimal; PricesIncludeVAT: Boolean)
    var
        GLEntry: Record "G/L Entry";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenPostingSetup: Record "General Posting Setup";
        DocNo: Code[10];
        DocNo2: Code[10];
    begin
        //r02
        Initialize();

        // Setup
        CreatePostingSetup(GenPostingSetup);
        CreateHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(GenPostingSetup."Gen. Bus. Posting Group"));
        ChangePricesIncludingVAT(SalesHeader, PricesIncludeVAT);
        ChangePrepaymentOnHeader(SalesHeader, PrepaymentPercent);
        CreateLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(GenPostingSetup."Gen. Prod. Posting Group"));

        // Exercise
        PostPrepInvoice(SalesHeader);
        SalesLine.Find();
        ChangeQtyToPostOnLine(SalesLine);
        SalesHeader2 := SalesHeader;
        DocNo := PostDocument(SalesHeader);
        DocNo2 := PostDocument(SalesHeader);

        // Verify
        VerifyInvoiceGLEntries(DocNo, GLEntry."Document Type"::Invoice, SalesHeader2, SalesLine, PrepaymentPercent);
        VerifyInvoiceVATEntries(DocNo, GLEntry."Document Type"::Invoice, SalesLine);
        VerifyInvoiceGLEntries(DocNo2, GLEntry."Document Type"::Invoice, SalesHeader2, SalesLine, PrepaymentPercent);
        VerifyInvoiceVATEntries(DocNo2, GLEntry."Document Type"::Invoice, SalesLine);
    end;

    local procedure PrepInvPartInv2FullInv(PrepaymentPercent: Decimal; PricesIncludeVAT: Boolean)
    var
        GLEntry: Record "G/L Entry";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenPostingSetup: Record "General Posting Setup";
        DocNo: Code[10];
        DocNo2: Code[10];
    begin
        Initialize();

        // Setup
        CreatePostingSetup(GenPostingSetup);
        CreateHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(GenPostingSetup."Gen. Bus. Posting Group"));
        ChangePricesIncludingVAT(SalesHeader, PricesIncludeVAT);
        ChangePrepaymentOnHeader(SalesHeader, PrepaymentPercent);
        CreateLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(GenPostingSetup."Gen. Prod. Posting Group"));
        ChangeQtyToPostOnLine(SalesLine);

        // Exercise
        SalesHeader2 := SalesHeader;
        PostPrepInvoice(SalesHeader);
        DocNo := PostDocument(SalesHeader);
        DocNo2 := PostDocument(SalesHeader);

        // Verify
        VerifyInvoiceGLEntries(DocNo, GLEntry."Document Type"::Invoice, SalesHeader2, SalesLine, PrepaymentPercent);
        VerifyInvoiceVATEntries(DocNo, GLEntry."Document Type"::Invoice, SalesLine);
        VerifyInvoiceGLEntries(DocNo2, GLEntry."Document Type"::Invoice, SalesHeader2, SalesLine, PrepaymentPercent);
        VerifyInvoiceVATEntries(DocNo2, GLEntry."Document Type"::Invoice, SalesLine);
    end;

    local procedure PrepInvFullInvFCY(PrepaymentPercent: Decimal; PricesIncludeVAT: Boolean)
    var
        GLEntry: Record "G/L Entry";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenPostingSetup: Record "General Posting Setup";
        DocNo: Code[10];
        DocNo2: Code[10];
    begin
        Initialize();

        // Setup
        CreatePostingSetup(GenPostingSetup);
        CreateHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(GenPostingSetup."Gen. Bus. Posting Group"));
        ChangePricesIncludingVAT(SalesHeader, PricesIncludeVAT);
        ChangePrepaymentOnHeader(SalesHeader, PrepaymentPercent);
        ChangeCurrencyOnHeader(SalesHeader, CreateCurrencyWithExchangeRate(1));
        CreateLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(GenPostingSetup."Gen. Prod. Posting Group"));

        // Exercise
        SalesHeader2 := SalesHeader;
        DocNo := PostPrepInvoice(SalesHeader);
        DocNo2 := PostDocument(SalesHeader);

        // Verify
        VerifyPrepaymentGLEntries(DocNo, GLEntry."Document Type"::Invoice, SalesHeader2, SalesLine, true);
        VerifyPrepaymentVATEntries(DocNo, GLEntry."Document Type"::Invoice, SalesLine, true);
        VerifyInvoiceGLEntries(DocNo2, GLEntry."Document Type"::Invoice, SalesHeader2, SalesLine, PrepaymentPercent);
        VerifyInvoiceVATEntries(DocNo2, GLEntry."Document Type"::Invoice, SalesLine);
    end;

    local procedure PrepInvChangeRateFullInvFCYGain(PrepaymentPercent: Decimal; PricesIncludeVAT: Boolean)
    var
        GLEntry: Record "G/L Entry";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenPostingSetup: Record "General Posting Setup";
        DocNo: Code[10];
        DocNo2: Code[10];
        NewDate: Date;
        InvoicedAmount: Decimal;
    begin
        //r03
        Initialize();

        // Setup
        CreatePostingSetup(GenPostingSetup);
        CreateHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(GenPostingSetup."Gen. Bus. Posting Group"));
        ChangePricesIncludingVAT(SalesHeader, PricesIncludeVAT);
        ChangePrepaymentOnHeader(SalesHeader, PrepaymentPercent);
        ChangeCurrencyOnHeader(SalesHeader, CreateCurrencyWithExchangeRate(-1));
        CreateLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(GenPostingSetup."Gen. Prod. Posting Group"));

        // Exercise
        SalesHeader2 := SalesHeader;
        DocNo := PostPrepInvoice(SalesHeader);
        NewDate := CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(10)), WorkDate());
        ChangePostingDate(SalesHeader, NewDate);
        SalesLine.Find();
        DocNo2 := PostDocument(SalesHeader);

        // Verify
        VerifyPrepaymentGLEntriesOnDate(DocNo, GLEntry."Document Type"::Invoice, SalesHeader2, SalesLine, true, WorkDate());
        VerifyPrepaymentVATEntriesOnDate(DocNo, GLEntry."Document Type"::Invoice, SalesLine, true, WorkDate());
        InvoicedAmount := GetPrepaymentInvoicedAmountOnDate(SalesLine, WorkDate());
        VerifyInvoiceGLEntriesOnDate(DocNo2, GLEntry."Document Type"::Invoice, SalesHeader2, SalesLine, NewDate, PrepaymentPercent);
        VerifyInvoiceGLEntriesAfterCurrencyRateChangeGain(
          DocNo2, GLEntry."Document Type"::Invoice, SalesLine, InvoicedAmount, NewDate);
        VerifyInvoiceVATEntriesOnDate(DocNo2, GLEntry."Document Type"::Invoice, SalesLine, NewDate);
    end;

    local procedure PrepInvChangeRateFullInvFCYLoss(PrepaymentPercent: Decimal; PricesIncludeVAT: Boolean)
    var
        GLEntry: Record "G/L Entry";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenPostingSetup: Record "General Posting Setup";
        DocNo: Code[10];
        DocNo2: Code[10];
        NewDate: Date;
        InvoicedAmount: Decimal;
    begin
        Initialize();

        // Setup
        CreatePostingSetup(GenPostingSetup);
        CreateHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(GenPostingSetup."Gen. Bus. Posting Group"));
        ChangePricesIncludingVAT(SalesHeader, PricesIncludeVAT);
        ChangePrepaymentOnHeader(SalesHeader, PrepaymentPercent);
        ChangeCurrencyOnHeader(SalesHeader, CreateCurrencyWithExchangeRate(1));
        CreateLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(GenPostingSetup."Gen. Prod. Posting Group"));

        // Exercise
        SalesHeader2 := SalesHeader;
        DocNo := PostPrepInvoice(SalesHeader);
        NewDate := CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(10)), WorkDate());
        ChangePostingDate(SalesHeader, NewDate);
        SalesLine.Find();
        DocNo2 := PostDocument(SalesHeader);

        // Verify
        VerifyPrepaymentGLEntriesOnDate(DocNo, GLEntry."Document Type"::Invoice, SalesHeader2, SalesLine, true, WorkDate());
        VerifyPrepaymentVATEntriesOnDate(DocNo, GLEntry."Document Type"::Invoice, SalesLine, true, WorkDate());
        InvoicedAmount := GetPrepaymentInvoicedAmountOnDate(SalesLine, WorkDate());
        VerifyInvoiceGLEntriesOnDate(DocNo2, GLEntry."Document Type"::Invoice, SalesHeader2, SalesLine, NewDate, PrepaymentPercent);
        VerifyInvoiceGLEntriesAfterCurrencyRateChangeLoss(
          DocNo2, GLEntry."Document Type"::Invoice, SalesLine, InvoicedAmount, NewDate);
        VerifyInvoiceVATEntriesOnDate(DocNo2, GLEntry."Document Type"::Invoice, SalesLine, NewDate);
    end;

    local procedure PrepInvFullInvUnrealized(PrepaymentPercent: Decimal; PricesIncludeVAT: Boolean)
    var
        GLEntry: Record "G/L Entry";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenPostingSetup: Record "General Posting Setup";
        DocNo: Code[10];
        DocNo2: Code[10];
    begin
        Initialize();

        // Setup
        LibraryERM.SetUnrealizedVAT(true);
        CreatePostingSetup(GenPostingSetup);
        SetupUnrealizedVAT(GenPostingSetup);
        CreateHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(GenPostingSetup."Gen. Bus. Posting Group"));
        ChangePricesIncludingVAT(SalesHeader, PricesIncludeVAT);
        ChangePrepaymentOnHeader(SalesHeader, PrepaymentPercent);
        CreateLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(GenPostingSetup."Gen. Prod. Posting Group"));

        // Exercise
        SalesHeader2 := SalesHeader;
        DocNo := PostPrepInvoice(SalesHeader);
        DocNo2 := PostDocument(SalesHeader);

        // Verify
        VerifyPrepaymentGLEntries(DocNo, GLEntry."Document Type"::Invoice, SalesHeader2, SalesLine, true);
        VerifyPrepaymentVATEntries(DocNo, GLEntry."Document Type"::Invoice, SalesLine, true);
        VerifyInvoiceGLEntries(DocNo2, GLEntry."Document Type"::Invoice, SalesHeader2, SalesLine, PrepaymentPercent);
        VerifyInvoiceVATEntries(DocNo2, GLEntry."Document Type"::Invoice, SalesLine);

        // Tear Down
        TearDownUnrealizedVAT(GenPostingSetup);
        LibraryERM.SetUnrealizedVAT(false);
    end;

    local procedure ChangeCurrencyOnHeader(var SalesHeader: Record "Sales Header"; CurrencyCode: Code[10])
    var
        ReleaseSalesDoc: Codeunit "Release Sales Document";
    begin
        if SalesHeader.Status <> SalesHeader.Status::Open then
            ReleaseSalesDoc.PerformManualReopen(SalesHeader);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
    end;

    local procedure ChangePostingDate(var SalesHeader: Record "Sales Header"; PostingDate: Date)
    var
        ReleaseSalesDoc: Codeunit "Release Sales Document";
    begin
        if SalesHeader.Status <> SalesHeader.Status::Open then
            ReleaseSalesDoc.PerformManualReopen(SalesHeader);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
    end;

    local procedure ChangePrepaymentOnHeader(var SalesHeader: Record "Sales Header"; PrepaymentPercent: Decimal)
    var
        ReleaseSalesDoc: Codeunit "Release Sales Document";
    begin
        if SalesHeader.Status <> SalesHeader.Status::Open then
            ReleaseSalesDoc.PerformManualReopen(SalesHeader);
        SalesHeader.Validate("Prepayment %", PrepaymentPercent);
        SalesHeader.Modify(true);
    end;

    local procedure ChangePrepaymentOnLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; PrepaymentPercent: Decimal)
    var
        ReleaseSalesDoc: Codeunit "Release Sales Document";
    begin
        if SalesHeader.Status <> SalesHeader.Status::Open then
            ReleaseSalesDoc.PerformManualReopen(SalesHeader);
        SalesLine.Validate("Prepayment %", PrepaymentPercent);
        SalesLine.Modify(true);
    end;

    local procedure ChangePricesIncludingVAT(var SalesHeader: Record "Sales Header"; IncludingVAT: Boolean)
    begin
        SalesHeader.Validate("Prices Including VAT", IncludingVAT);
        SalesHeader.Modify(true);
    end;

    local procedure ChangeQtyToPostOnLine(var SalesLine: Record "Sales Line"): Code[10]
    begin
        SalesLine.Validate("Qty. to Invoice", SalesLine."Qty. to Invoice" / 2);
        SalesLine.Validate("Qty. to Ship", SalesLine."Qty. to Ship" / 2);
        SalesLine.Validate("Return Qty. to Receive", SalesLine."Return Qty. to Receive" / 2);
        SalesLine.Modify(true);
    end;

    local procedure ConvertAndRoundAmount(Amount: Decimal; CurrencyCode: Code[10]; Date: Date) FinalAmount: Decimal
    begin
        FinalAmount := LibraryERM.ConvertCurrency(Amount, CurrencyCode, '', Date);
        FinalAmount := Round(FinalAmount, LibraryERM.GetAmountRoundingPrecision());
    end;

    local procedure CreateAccount(GenProdPostingGroup: Code[20]; Description: Code[50]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        GLAccount.Validate(Name, Description); // add description for readability of the results
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateCurrencyWithExchangeRate(ExchangeRateChangeSign: Integer): Code[10]
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        Amount: Decimal;
        RelationalAmount: Decimal;
    begin
        LibraryERM.CreateCurrency(Currency);
        Currency.Validate("Realized Gains Acc.", CreateAccount('', Currency.FieldCaption("Realized Gains Acc.")));
        Currency.Validate("Realized Losses Acc.", CreateAccount('', Currency.FieldCaption("Realized Losses Acc.")));
        Currency.Validate("Invoice Rounding Precision", LibraryERM.GetInvoiceRoundingPrecisionLCY());
        Currency.Modify(true);
        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, WorkDate());
        Amount := 100;
        RelationalAmount := 100 + LibraryRandom.RandInt(100); // make sure that the relational amount will be positive after changes in exchange rate
        ModifyCurrencyExchangeRate(CurrencyExchangeRate, Amount, RelationalAmount);
        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, CalcDate('<1D>', WorkDate())); // make sure that exchange rate is different on any future date
        ModifyCurrencyExchangeRate(CurrencyExchangeRate, Amount, RelationalAmount + ExchangeRateChangeSign * LibraryRandom.RandInt(10));
        exit(Currency.Code);
    end;

    local procedure CreateCustomer(GenBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
    end;

    local procedure CreateItem(GenProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; No: Code[20])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, LibraryRandom.RandInt(20) * 2); // Qty to let at least 2 partial postings
        if Type <> SalesLine.Type::Item then begin
            SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
            SalesLine.Modify(true);
        end;
    end;

    local procedure CreateGenPostingSetup(var GenPostingSetup: Record "General Posting Setup"; VATPostingSetup: Record "VAT Posting Setup"; GenBusPostingGroup: Record "Gen. Business Posting Group")
    var
        GenProdPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.CreateGenProdPostingGroup(GenProdPostingGroup);
        GenProdPostingGroup."Def. VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group"; // bypassing triggers to avoid UI Confirm
        GenProdPostingGroup.Modify(true);
        GenBusPostingGroup."Def. VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group"; // bypassing triggers to avoid UI Confirm
        GenBusPostingGroup.Modify(true);
        LibraryERM.CreateGeneralPostingSetup(GenPostingSetup, GenBusPostingGroup.Code, GenProdPostingGroup.Code);
        GenPostingSetup.Validate("Sales Account", CreateAccount(GenProdPostingGroup.Code, GenPostingSetup.FieldCaption("Sales Account")
            + ' ' + GenPostingSetup."Gen. Prod. Posting Group" + ' ' + GenPostingSetup."Gen. Bus. Posting Group"));
        GenPostingSetup.Validate(
          "Sales Prepayments Account", CreateAccount(GenProdPostingGroup.Code, GenPostingSetup.FieldCaption("Sales Prepayments Account")
            + ' ' + GenPostingSetup."Gen. Prod. Posting Group" + ' ' + GenPostingSetup."Gen. Bus. Posting Group"));
        GenPostingSetup.Validate("COGS Account", CreateAccount(GenProdPostingGroup.Code, GenPostingSetup.FieldCaption("COGS Account")
            + ' ' + GenPostingSetup."Gen. Prod. Posting Group" + ' ' + GenPostingSetup."Gen. Bus. Posting Group"));
        GenPostingSetup.Modify(true);
    end;

    local procedure CreatePostingSetup(var GenPostingSetup: Record "General Posting Setup")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenBusPostingGroup: Record "Gen. Business Posting Group";
    begin
        FindVATPostingSetup(VATPostingSetup);
        LibraryERM.CreateGenBusPostingGroup(GenBusPostingGroup);
        CreateGenPostingSetup(GenPostingSetup, VATPostingSetup, GenBusPostingGroup);
    end;

    local procedure CreatePostingSetupWithDifferentVATRate(var GenPostingSetup: Record "General Posting Setup"; SalesLine: Record "Sales Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenBusPostingGroup: Record "Gen. Business Posting Group";
    begin
        FindVATPostingSetupWithDifferentRate(VATPostingSetup, SalesLine);
        GenBusPostingGroup.Get(SalesLine."Gen. Bus. Posting Group");
        CreateGenPostingSetup(GenPostingSetup, VATPostingSetup, GenBusPostingGroup);
    end;

    local procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetFilter("Sales VAT Account", '<>%1', '');
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
    end;

    local procedure FindVATPostingSetupWithDifferentRate(var VATPostingSetup: Record "VAT Posting Setup"; SalesLine: Record "Sales Line")
    var
        VATProdPostingGroup: Record "VAT Product Posting Group";
        GLAccount: Record "G/L Account";
    begin
        VATPostingSetup.SetFilter("Sales VAT Account", '<>%1', '');
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", SalesLine."VAT Bus. Posting Group");
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', SalesLine."VAT Prod. Posting Group");
        VATPostingSetup.SetFilter("VAT %", '>%1', SalesLine."VAT %");
        if not VATPostingSetup.FindFirst() then begin
            LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, SalesLine."VAT Bus. Posting Group", VATProdPostingGroup.Code);
            VATPostingSetup.Validate("VAT %", SalesLine."VAT %" + LibraryRandom.RandInt(10));
            LibraryERM.CreateGLAccount(GLAccount);
            VATPostingSetup.Validate("Sales VAT Account", GLAccount."No.");
            VATPostingSetup.Modify(true);
        end;
    end;

    local procedure FullGSTOnPrepayment(): Boolean
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        exit(GLSetup."Full GST on Prepayment");
    end;

    local procedure GetAmountOnDate(SalesLine: Record "Sales Line"; Date: Date) Amount: Decimal
    begin
        Amount := SalesLine.Amount * SalesLine."Qty. to Invoice" / SalesLine.Quantity;
        Amount := ConvertAndRoundAmount(Amount, SalesLine."Currency Code", Date);
    end;

    local procedure GetPrepaymentAmount(SalesLine: Record "Sales Line") Amount: Decimal
    begin
        Amount := GetPrepaymentAmountOnDate(SalesLine, WorkDate());
    end;

    local procedure GetPrepaymentAmountOnDate(SalesLine: Record "Sales Line"; Date: Date) Amount: Decimal
    begin
        Amount := SalesLine.Amount * SalesLine."Qty. to Invoice" / SalesLine.Quantity * SalesLine."Prepayment %" / 100;
        Amount := ConvertAndRoundAmount(Amount, SalesLine."Currency Code", Date);
    end;

    local procedure GetPrepaymentInvoicedAmount(SalesLine: Record "Sales Line") Amount: Decimal
    begin
        Amount := GetPrepaymentInvoicedAmountOnDate(SalesLine, WorkDate());
    end;

    local procedure GetPrepaymentInvoicedAmountOnDate(SalesLine: Record "Sales Line"; Date: Date) Amount: Decimal
    begin
        Amount := SalesLine."Prepayment Amount";
        Amount := ConvertAndRoundAmount(Amount, SalesLine."Currency Code", Date);
    end;

    local procedure GetPrepaymentVATAmountOnDate(SalesLine: Record "Sales Line"; Date: Date) Amount: Decimal
    begin
        if FullGSTOnPrepayment() and not UnrealizedVATEnabled() then
            Amount := SalesLine.Amount * SalesLine."Qty. to Invoice" / SalesLine.Quantity * SalesLine."VAT %" / 100
        else
            Amount :=
              SalesLine.Amount *
              SalesLine."Qty. to Invoice" / SalesLine.Quantity * SalesLine."VAT %" / 100 * SalesLine."Prepayment %" / 100;
        Amount := ConvertAndRoundAmount(Amount, SalesLine."Currency Code", Date);
    end;

    local procedure GetPrepaymentVATBaseOnDate(SalesLine: Record "Sales Line"; Date: Date) Amount: Decimal
    begin
        if FullGSTOnPrepayment() and not UnrealizedVATEnabled() then
            Amount := SalesLine.Amount * SalesLine."Qty. to Invoice" / SalesLine.Quantity
        else
            Amount := SalesLine.Amount * SalesLine."Qty. to Invoice" / SalesLine.Quantity * SalesLine."Prepayment %" / 100;
        Amount := ConvertAndRoundAmount(Amount, SalesLine."Currency Code", Date);
    end;

    local procedure GetVATAmountOnDate(SalesLine: Record "Sales Line"; Date: Date) Amount: Decimal
    begin
        Amount := SalesLine.Amount * SalesLine."Qty. to Invoice" / SalesLine.Quantity * SalesLine."VAT %" / 100;
        Amount := ConvertAndRoundAmount(Amount, SalesLine."Currency Code", Date);
    end;

    local procedure GetRealizedGainsAccountNo(CurrencyCode: Code[10]) RealizedGainsAccount: Code[20]
    var
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyCode);
        RealizedGainsAccount := Currency."Realized Gains Acc.";
    end;

    local procedure GetRealizedLossesAccountNo(CurrencyCode: Code[10]) RealizedLossesAccount: Code[20]
    var
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyCode);
        RealizedLossesAccount := Currency."Realized Losses Acc.";
    end;

    local procedure GetReceivablesAccountNo(CustomerPostingGroupCode: Code[20]) ReceivablesAccount: Code[20]
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CustomerPostingGroup.Get(CustomerPostingGroupCode);
        ReceivablesAccount := CustomerPostingGroup."Receivables Account";
    end;

    local procedure GetSalesAccountNo(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]) SalesAccount: Code[20]
    var
        GenPostingSetup: Record "General Posting Setup";
    begin
        GenPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        SalesAccount := GenPostingSetup."Sales Account";
    end;

    local procedure GetSalesPrepAccountNo(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]) SalesPrepAccount: Code[20]
    var
        GenPostingSetup: Record "General Posting Setup";
    begin
        GenPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        SalesPrepAccount := GenPostingSetup."Sales Prepayments Account";
    end;

    local procedure GetVATAccountNo(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]) SalesVATAccount: Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup);
        if not UnrealizedVATEnabled() then
            SalesVATAccount := VATPostingSetup."Sales VAT Account"
        else
            SalesVATAccount := VATPostingSetup."Sales VAT Unreal. Account"
    end;

    local procedure ModifyCurrencyExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; ExchangeRateAmount: Decimal; RelationalExchRateAmount: Decimal)
    begin
        CurrencyExchangeRate.Validate("Exchange Rate Amount", ExchangeRateAmount);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", RelationalExchRateAmount);
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure PostDocument(var SalesHeader: Record "Sales Header"): Code[20]
    begin
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure PostPrepCreditMemo(var SalesHeader: Record "Sales Header") DocumentNo: Code[20]
    var
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        NoSeries: Codeunit "No. Series";
    begin
        DocumentNo := NoSeries.PeekNextNo(SalesHeader."Prepmt. Cr. Memo No. Series");
        SalesPostPrepayments.CreditMemo(SalesHeader);
        exit(DocumentNo);
    end;

    local procedure PostPrepInvoice(var SalesHeader: Record "Sales Header") DocumentNo: Code[20]
    var
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
        NoSeries: Codeunit "No. Series";
    begin
        DocumentNo := NoSeries.PeekNextNo(SalesHeader."Prepayment No. Series");
        SalesPostPrepayments.Invoice(SalesHeader);
        exit(DocumentNo);
    end;

    local procedure SetupUnrealizedVAT(GenPostingSetup: Record "General Posting Setup")
    var
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        GenProdPostingGroup.Get(GenPostingSetup."Gen. Prod. Posting Group");
        GenBusPostingGroup.Get(GenPostingSetup."Gen. Bus. Posting Group");
        VATPostingSetup.Get(GenBusPostingGroup."Def. VAT Bus. Posting Group", GenProdPostingGroup."Def. VAT Prod. Posting Group");
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);
        VATPostingSetup.Validate(
          "Sales VAT Unreal. Account", CreateAccount(GenProdPostingGroup.Code, VATPostingSetup.FieldCaption("Sales VAT Unreal. Account")));
        VATPostingSetup.Modify(true);
    end;

    local procedure TearDownUnrealizedVAT(GenPostingSetup: Record "General Posting Setup")
    var
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        GenProdPostingGroup.Get(GenPostingSetup."Gen. Prod. Posting Group");
        GenBusPostingGroup.Get(GenPostingSetup."Gen. Bus. Posting Group");
        VATPostingSetup.Get(GenBusPostingGroup."Def. VAT Bus. Posting Group", GenProdPostingGroup."Def. VAT Prod. Posting Group");
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        VATPostingSetup.Validate("Sales VAT Unreal. Account", '');
        VATPostingSetup.Modify(true);
    end;

    local procedure UnrealizedVATEnabled(): Boolean
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        exit(GLSetup."Unrealized VAT");
    end;

    local procedure VerifyAdditionalPrepaymentGLEntries(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line")
    begin
        VerifyGLEntry(
          DocumentNo, DocumentType, GetSalesPrepAccountNo(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group"),
          -GetPrepaymentAmount(SalesLine) + GetPrepaymentInvoicedAmount(SalesLine), 0, false);
        VerifyGLEntry(
          DocumentNo, DocumentType, GetReceivablesAccountNo(SalesHeader."Customer Posting Group"),
          GetPrepaymentAmount(SalesLine) - GetPrepaymentInvoicedAmount(SalesLine), 0, false);
    end;

    local procedure VerifyAdditionalPrepaymentVATEntries(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; SalesLine: Record "Sales Line")
    var
        VATEntry: Record "VAT Entry";
        GSTSalesEntry: Record "GST Sales Entry";
    begin
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("VAT Bus. Posting Group", SalesLine."VAT Bus. Posting Group");
        VATEntry.SetRange("VAT Prod. Posting Group", SalesLine."VAT Prod. Posting Group");
        Assert.IsTrue(VATEntry.IsEmpty, EntriesError);

        GSTSalesEntry.SetRange("Document Type", DocumentType);
        GSTSalesEntry.SetRange("Document No.", DocumentNo);
        GSTSalesEntry.SetRange("VAT Bus. Posting Group", SalesLine."VAT Bus. Posting Group");
        GSTSalesEntry.SetRange("VAT Prod. Posting Group", SalesLine."VAT Prod. Posting Group");
        Assert.IsTrue(GSTSalesEntry.IsEmpty, EntriesError);
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; AccountNo: Code[20]; Amount: Decimal; VATAmount: Decimal; DoubleEntry: Boolean)
    var
        GLEntry: Record "G/L Entry";
        CreditAmount: Decimal;
        DebitAmount: Decimal;
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", AccountNo);
        if DoubleEntry then // There are 2 G/L Entries for the same account with the same Document No., so additional filter is needed
            GLEntry.SetFilter(Amount, '<=%1&>=%2', Amount + GetAmountRoundingPrecision(), Amount - GetAmountRoundingPrecision());
        GLEntry.FindFirst();

        if Amount > 0 then
            DebitAmount := Amount
        else
            CreditAmount := -Amount;

        Assert.AreNearlyEqual(Amount, GLEntry.Amount, GetAmountRoundingPrecision(),
          StrSubstNo(ValidationError, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption()));
        Assert.AreNearlyEqual(CreditAmount, GLEntry."Credit Amount", GetAmountRoundingPrecision(),
          StrSubstNo(ValidationError, GLEntry.FieldCaption("Credit Amount"), CreditAmount, GLEntry.TableCaption()));
        Assert.AreNearlyEqual(DebitAmount, GLEntry."Debit Amount", GetAmountRoundingPrecision(),
          StrSubstNo(ValidationError, GLEntry.FieldCaption("Debit Amount"), DebitAmount, GLEntry.TableCaption()));
        Assert.AreNearlyEqual(VATAmount, GLEntry."VAT Amount", GetAmountRoundingPrecision(),
          StrSubstNo(ValidationError, GLEntry.FieldCaption("VAT Amount"), VATAmount, GLEntry.TableCaption()));
    end;

    local procedure VerifyGSTSalesEntry(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; Base: Decimal; Amount: Decimal; DoubleEntry: Boolean)
    var
        GSTSalesEntry: Record "GST Sales Entry";
    begin
        GSTSalesEntry.SetRange("Document Type", DocumentType);
        GSTSalesEntry.SetRange("Document No.", DocumentNo);
        GSTSalesEntry.SetRange("VAT Bus. Posting Group", VATBusPostingGroup);
        GSTSalesEntry.SetRange("VAT Prod. Posting Group", VATProdPostingGroup);

        if DoubleEntry then // There are 2 VAT Entries with the same Document No. and Posting Groups, so additional filter is needed
            if Base < 0 then
                GSTSalesEntry.SetFilter("GST Base", '<0')
            else
                GSTSalesEntry.SetFilter("GST Base", '>=0');
        GSTSalesEntry.FindFirst();

        Assert.AreNearlyEqual(Base, GSTSalesEntry."GST Base", GetAmountRoundingPrecision(),
          StrSubstNo(ValidationError, GSTSalesEntry.FieldCaption("GST Base"), Base, GSTSalesEntry.TableCaption()));
        Assert.AreNearlyEqual(Amount, GSTSalesEntry.Amount, GetAmountRoundingPrecision(),
          StrSubstNo(ValidationError, GSTSalesEntry.FieldCaption(Amount), Amount, GSTSalesEntry.TableCaption()));
    end;

    local procedure VerifyInvoiceGLEntries(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; PrepaymentPercent: Decimal)
    begin
        VerifyInvoiceGLEntriesOnDate(DocumentNo, DocumentType, SalesHeader, SalesLine, WorkDate(), PrepaymentPercent);
    end;

    local procedure VerifyInvoiceGLEntriesMultipleLinesDifferentRates(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLine2: Record "Sales Line"; PrepaymentPercent: Decimal)
    var
        PrepaymentAmount: Decimal;
        PrepaymentVATAmount: Decimal;
        PrepaymentAmount2: Decimal;
        PrepaymentVATAmount2: Decimal;
        Amount: Decimal;
        VATAmount: Decimal;
        Amount2: Decimal;
        VATAmount2: Decimal;
    begin
        PrepaymentAmount := GetPrepaymentAmountOnDate(SalesLine, WorkDate());
        PrepaymentVATAmount := GetPrepaymentVATAmountOnDate(SalesLine, WorkDate());
        PrepaymentAmount2 := GetPrepaymentAmountOnDate(SalesLine2, WorkDate());
        PrepaymentVATAmount2 := GetPrepaymentVATAmountOnDate(SalesLine2, WorkDate());
        Amount := GetAmountOnDate(SalesLine, WorkDate());
        Amount2 := GetAmountOnDate(SalesLine2, WorkDate());
        VATAmount := GetVATAmountOnDate(SalesLine, WorkDate());
        VATAmount2 := GetVATAmountOnDate(SalesLine2, WorkDate());

        VerifyGLEntry(
          DocumentNo, DocumentType, GetSalesPrepAccountNo(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group"),
          PrepaymentAmount, PrepaymentVATAmount, false);
        VerifyGLEntry(
          DocumentNo, DocumentType, GetVATAccountNo(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group"),
          PrepaymentVATAmount, 0, true);
        VerifyGLEntry(
          DocumentNo, DocumentType, GetSalesPrepAccountNo(SalesLine2."Gen. Bus. Posting Group", SalesLine2."Gen. Prod. Posting Group"),
          PrepaymentAmount2, PrepaymentVATAmount2, false);
        VerifyGLEntry(
          DocumentNo, DocumentType, GetVATAccountNo(SalesLine2."VAT Bus. Posting Group", SalesLine2."VAT Prod. Posting Group"),
          PrepaymentVATAmount2, 0, true);
        VerifyGLEntry(
          DocumentNo, DocumentType, GetSalesAccountNo(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group"), -Amount,
          -VATAmount, false);
        VerifyGLEntry(
          DocumentNo, DocumentType, GetVATAccountNo(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group"), -VATAmount, 0,
          true);
        VerifyGLEntry(
          DocumentNo, DocumentType, GetSalesAccountNo(SalesLine2."Gen. Bus. Posting Group", SalesLine2."Gen. Prod. Posting Group"),
          -Amount2, -VATAmount2, false);
        VerifyGLEntry(
          DocumentNo, DocumentType, GetVATAccountNo(SalesLine2."VAT Bus. Posting Group", SalesLine2."VAT Prod. Posting Group"),
          -VATAmount2, 0, true);
        if PrepaymentPercent <> 100 then
            VerifyGLEntry(
              DocumentNo, DocumentType, GetReceivablesAccountNo(SalesHeader."Customer Posting Group"),
              Amount + Amount2 - PrepaymentAmount - PrepaymentAmount2 + VATAmount + VATAmount2 -
              PrepaymentVATAmount - PrepaymentVATAmount2, 0, false);
    end;

    local procedure VerifyInvoiceGLEntriesOnDate(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; Date: Date; PrepaymentPercent: Decimal)
    var
        PrepaymentAmount: Decimal;
        PrepaymentVATAmount: Decimal;
        Amount: Decimal;
        VATAmount: Decimal;
    begin
        PrepaymentAmount := GetPrepaymentAmountOnDate(SalesLine, Date);
        PrepaymentVATAmount := GetPrepaymentVATAmountOnDate(SalesLine, Date);
        Amount := GetAmountOnDate(SalesLine, Date);
        VATAmount := GetVATAmountOnDate(SalesLine, Date);

        VerifyGLEntry(
          DocumentNo, DocumentType, GetSalesPrepAccountNo(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group"),
          PrepaymentAmount, PrepaymentVATAmount, false);
        VerifyGLEntry(
          DocumentNo, DocumentType, GetVATAccountNo(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group"),
          PrepaymentVATAmount, 0, true);
        VerifyGLEntry(
          DocumentNo, DocumentType, GetSalesAccountNo(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group"), -Amount,
          -VATAmount, false);
        VerifyGLEntry(
          DocumentNo, DocumentType, GetVATAccountNo(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group"), -VATAmount, 0,
          true);
        if PrepaymentPercent <> 100 then
            VerifyGLEntry(
              DocumentNo, DocumentType, GetReceivablesAccountNo(SalesHeader."Customer Posting Group"),
              Amount - PrepaymentAmount + VATAmount - PrepaymentVATAmount, 0, false);
    end;

    local procedure VerifyInvoiceGLEntriesAfterCurrencyRateChangeGain(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; SalesLine: Record "Sales Line"; InvoicedAmount: Decimal; Date: Date)
    var
        AmountDifference: Decimal;
    begin
        AmountDifference := Abs(InvoicedAmount - GetPrepaymentAmountOnDate(SalesLine, Date));
        VerifyGLEntry(
          DocumentNo, DocumentType, GetSalesPrepAccountNo(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group"),
          AmountDifference, 0, true);
        VerifyGLEntry(DocumentNo, DocumentType, GetRealizedGainsAccountNo(SalesLine."Currency Code"), -AmountDifference, 0, false);
    end;

    local procedure VerifyInvoiceGLEntriesAfterCurrencyRateChangeLoss(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; SalesLine: Record "Sales Line"; InvoicedAmount: Decimal; Date: Date)
    var
        AmountDifference: Decimal;
    begin
        AmountDifference := Abs(InvoicedAmount - GetPrepaymentAmountOnDate(SalesLine, Date));
        VerifyGLEntry(
          DocumentNo, DocumentType, GetSalesPrepAccountNo(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group"),
          -AmountDifference, 0, true);
        VerifyGLEntry(DocumentNo, DocumentType, GetRealizedLossesAccountNo(SalesLine."Currency Code"), AmountDifference, 0, false);
    end;

    local procedure VerifyInvoiceVATEntries(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; SalesLine: Record "Sales Line")
    begin
        VerifyInvoiceVATEntriesOnDate(DocumentNo, DocumentType, SalesLine, WorkDate());
    end;

    local procedure VerifyInvoiceVATEntriesMultipleLinesDifferentRates(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; SalesLine: Record "Sales Line"; SalesLine2: Record "Sales Line")
    var
        PrepaymentVATBase: Decimal;
        PrepaymentVATAmount: Decimal;
        PrepaymentVATBase2: Decimal;
        PrepaymentVATAmount2: Decimal;
        Amount: Decimal;
        VATAmount: Decimal;
        Amount2: Decimal;
        VATAmount2: Decimal;
    begin
        PrepaymentVATBase := GetPrepaymentVATBaseOnDate(SalesLine, WorkDate());
        PrepaymentVATAmount := GetPrepaymentVATAmountOnDate(SalesLine, WorkDate());
        PrepaymentVATBase2 := GetPrepaymentVATBaseOnDate(SalesLine2, WorkDate());
        PrepaymentVATAmount2 := GetPrepaymentVATAmountOnDate(SalesLine2, WorkDate());
        Amount := GetAmountOnDate(SalesLine, WorkDate());
        VATAmount := GetVATAmountOnDate(SalesLine, WorkDate());
        Amount2 := GetAmountOnDate(SalesLine2, WorkDate());
        VATAmount2 := GetVATAmountOnDate(SalesLine2, WorkDate());

        VerifyVATEntry(
          DocumentNo, DocumentType, SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group", PrepaymentVATBase,
          PrepaymentVATAmount, true);
        VerifyVATEntry(
          DocumentNo, DocumentType, SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group", -Amount, -VATAmount, true);
        VerifyVATEntry(
          DocumentNo, DocumentType, SalesLine2."VAT Bus. Posting Group", SalesLine2."VAT Prod. Posting Group", PrepaymentVATBase2,
          PrepaymentVATAmount2, true);
        VerifyVATEntry(
          DocumentNo, DocumentType, SalesLine2."VAT Bus. Posting Group", SalesLine2."VAT Prod. Posting Group", -Amount2, -VATAmount2, true);

        VerifyGSTSalesEntry(
          DocumentNo, DocumentType, SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group", PrepaymentVATBase,
          PrepaymentVATAmount, true);
        VerifyGSTSalesEntry(
          DocumentNo, DocumentType, SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group", -Amount, -VATAmount, true);
        VerifyGSTSalesEntry(
          DocumentNo, DocumentType, SalesLine2."VAT Bus. Posting Group", SalesLine2."VAT Prod. Posting Group", PrepaymentVATBase2,
          PrepaymentVATAmount2, true);
        VerifyGSTSalesEntry(
          DocumentNo, DocumentType, SalesLine2."VAT Bus. Posting Group", SalesLine2."VAT Prod. Posting Group", -Amount2, -VATAmount2, true);
    end;

    local procedure VerifyInvoiceVATEntriesOnDate(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; SalesLine: Record "Sales Line"; Date: Date)
    var
        PrepaymentVATBase: Decimal;
        PrepaymentVATAmount: Decimal;
        Amount: Decimal;
        VATAmount: Decimal;
    begin
        PrepaymentVATBase := GetPrepaymentVATBaseOnDate(SalesLine, Date);
        PrepaymentVATAmount := GetPrepaymentVATAmountOnDate(SalesLine, Date);
        Amount := GetAmountOnDate(SalesLine, Date);
        VATAmount := GetVATAmountOnDate(SalesLine, Date);

        VerifyVATEntry(
          DocumentNo, DocumentType, SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group", PrepaymentVATBase,
          PrepaymentVATAmount, true);
        VerifyVATEntry(
          DocumentNo, DocumentType, SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group", -Amount, -VATAmount, true);

        VerifyGSTSalesEntry(
          DocumentNo, DocumentType, SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group", PrepaymentVATBase,
          PrepaymentVATAmount, true);
        VerifyGSTSalesEntry(
          DocumentNo, DocumentType, SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group", -Amount, -VATAmount, true);
    end;

    local procedure VerifyPrepaymentGLEntries(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; Invoice: Boolean)
    begin
        VerifyPrepaymentGLEntriesOnDate(DocumentNo, DocumentType, SalesHeader, SalesLine, Invoice, WorkDate());
    end;

    local procedure VerifyPrepaymentGLEntriesMultipleLinesDifferentRates(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLine2: Record "Sales Line"; Invoice: Boolean)
    var
        Sign: Integer;
        PrepaymentAmount: Decimal;
        PrepaymentVATAmount: Decimal;
        PrepaymentAmount2: Decimal;
        PrepaymentVATAmount2: Decimal;
    begin
        // Invert Amounts for Credit Memo
        if Invoice then
            Sign := -1
        else
            Sign := 1;

        PrepaymentAmount := GetPrepaymentAmountOnDate(SalesLine, WorkDate());
        PrepaymentVATAmount := GetPrepaymentVATAmountOnDate(SalesLine, WorkDate());
        PrepaymentAmount2 := GetPrepaymentAmountOnDate(SalesLine2, WorkDate());
        PrepaymentVATAmount2 := GetPrepaymentVATAmountOnDate(SalesLine2, WorkDate());

        VerifyGLEntry(
          DocumentNo, DocumentType, GetSalesPrepAccountNo(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group"),
          Sign * PrepaymentAmount, Sign * PrepaymentVATAmount, false);
        VerifyGLEntry(
          DocumentNo, DocumentType, GetVATAccountNo(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group"),
          Sign * PrepaymentVATAmount, 0, false);
        VerifyGLEntry(
          DocumentNo, DocumentType, GetSalesPrepAccountNo(SalesLine2."Gen. Bus. Posting Group", SalesLine2."Gen. Prod. Posting Group"),
          Sign * PrepaymentAmount2, Sign * PrepaymentVATAmount2, false);
        VerifyGLEntry(
          DocumentNo, DocumentType, GetVATAccountNo(SalesLine2."VAT Bus. Posting Group", SalesLine2."VAT Prod. Posting Group"),
          Sign * PrepaymentVATAmount2, 0, false);

        VerifyGLEntry(
          DocumentNo, DocumentType, GetReceivablesAccountNo(SalesHeader."Customer Posting Group"),
          -Sign * (PrepaymentAmount + PrepaymentAmount2 + PrepaymentVATAmount + PrepaymentVATAmount2), 0, false);
    end;

    local procedure VerifyPrepaymentGLEntriesOnDate(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; Invoice: Boolean; Date: Date)
    var
        Sign: Integer;
        PrepaymentAmount: Decimal;
        PrepaymentVATAmount: Decimal;
    begin
        // Invert Amounts for Credit Memo
        if Invoice then
            Sign := -1
        else
            Sign := 1;

        PrepaymentAmount := GetPrepaymentAmountOnDate(SalesLine, Date);
        PrepaymentVATAmount := GetPrepaymentVATAmountOnDate(SalesLine, Date);

        VerifyGLEntry(
          DocumentNo, DocumentType, GetSalesPrepAccountNo(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group"),
          Sign * PrepaymentAmount, Sign * PrepaymentVATAmount, false);
        VerifyGLEntry(
          DocumentNo, DocumentType, GetVATAccountNo(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group"),
          Sign * PrepaymentVATAmount, 0, false);
        VerifyGLEntry(
          DocumentNo, DocumentType, GetReceivablesAccountNo(SalesHeader."Customer Posting Group"),
          -Sign * (PrepaymentAmount + PrepaymentVATAmount), 0, false);
    end;

    local procedure VerifyPrepaymentVATEntries(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; SalesLine: Record "Sales Line"; Invoice: Boolean)
    begin
        VerifyPrepaymentVATEntriesOnDate(DocumentNo, DocumentType, SalesLine, Invoice, WorkDate());
    end;

    local procedure VerifyPrepaymentVATEntriesMultipleLinesDifferentRates(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; SalesLine: Record "Sales Line"; SalesLine2: Record "Sales Line"; Invoice: Boolean)
    var
        Sign: Integer;
        PrepaymentVATBase: Decimal;
        PrepaymentVATAmount: Decimal;
        PrepaymentVATBase2: Decimal;
        PrepaymentVATAmount2: Decimal;
    begin
        // Invert Amounts for Credit Memo
        if Invoice then
            Sign := -1
        else
            Sign := 1;

        PrepaymentVATBase := GetPrepaymentVATBaseOnDate(SalesLine, WorkDate());
        PrepaymentVATAmount := GetPrepaymentVATAmountOnDate(SalesLine, WorkDate());
        PrepaymentVATBase2 := GetPrepaymentVATBaseOnDate(SalesLine2, WorkDate());
        PrepaymentVATAmount2 := GetPrepaymentVATAmountOnDate(SalesLine2, WorkDate());

        VerifyVATEntry(
          DocumentNo, DocumentType, SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group", Sign * PrepaymentVATBase,
          Sign * PrepaymentVATAmount, false);
        VerifyVATEntry(
          DocumentNo, DocumentType, SalesLine2."VAT Bus. Posting Group", SalesLine2."VAT Prod. Posting Group", Sign * PrepaymentVATBase2,
          Sign * PrepaymentVATAmount2, false);

        VerifyGSTSalesEntry(
          DocumentNo, DocumentType, SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group", Sign * PrepaymentVATBase,
          Sign * PrepaymentVATAmount, false);
        VerifyGSTSalesEntry(
          DocumentNo, DocumentType, SalesLine2."VAT Bus. Posting Group", SalesLine2."VAT Prod. Posting Group", Sign * PrepaymentVATBase2,
          Sign * PrepaymentVATAmount2, false);
    end;

    local procedure VerifyPrepaymentVATEntriesOnDate(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; SalesLine: Record "Sales Line"; Invoice: Boolean; Date: Date)
    var
        Sign: Integer;
        PrepaymentVATBase: Decimal;
        PrepaymentVATAmount: Decimal;
    begin
        // Invert Amounts for Credit Memo
        if Invoice then
            Sign := -1
        else
            Sign := 1;

        PrepaymentVATBase := GetPrepaymentVATBaseOnDate(SalesLine, Date);
        PrepaymentVATAmount := GetPrepaymentVATAmountOnDate(SalesLine, Date);

        VerifyVATEntry(
          DocumentNo, DocumentType, SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group", Sign * PrepaymentVATBase,
          Sign * PrepaymentVATAmount, false);

        VerifyGSTSalesEntry(
          DocumentNo, DocumentType, SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group", Sign * PrepaymentVATBase,
          Sign * PrepaymentVATAmount, false);
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; Base: Decimal; Amount: Decimal; DoubleEntry: Boolean)
    var
        VATEntry: Record "VAT Entry";
        VATEntryRef: RecordRef;
        BaseRef: FieldRef;
        AmountRef: FieldRef;
        ActualBase: Decimal;
        ActualAmount: Decimal;
    begin
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("VAT Bus. Posting Group", VATBusPostingGroup);
        VATEntry.SetRange("VAT Prod. Posting Group", VATProdPostingGroup);

        VATEntryRef.GetTable(VATEntry);
        if not UnrealizedVATEnabled() then begin
            BaseRef := VATEntryRef.Field(VATEntry.FieldNo(Base));
            AmountRef := VATEntryRef.Field(VATEntry.FieldNo(Amount));
        end else begin
            BaseRef := VATEntryRef.Field(VATEntry.FieldNo("Unrealized Base"));
            AmountRef := VATEntryRef.Field(VATEntry.FieldNo("Unrealized Amount"));
        end;

        if DoubleEntry then // There are 2 VAT Entries with the same Document No. and Posting Groups, so additional filter is needed
            if Base < 0 then
                BaseRef.SetFilter('<0')
            else
                BaseRef.SetFilter('>=0');
        VATEntryRef.FindFirst();

        Evaluate(ActualBase, Format(BaseRef.Value));
        Evaluate(ActualAmount, Format(AmountRef.Value));

        Assert.AreNearlyEqual(Base, ActualBase, GetAmountRoundingPrecision(),
          StrSubstNo(ValidationError, BaseRef.Caption, Base, VATEntry.TableCaption()));
        Assert.AreNearlyEqual(Amount, ActualAmount, GetAmountRoundingPrecision(),
          StrSubstNo(ValidationError, AmountRef.Caption, Amount, VATEntry.TableCaption()));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure UpdateExchRateConfirmHandler(Message: Text[1024]; var Response: Boolean)
    begin
        Response := true;
    end;

    local procedure GetAmountRoundingPrecision(): Decimal
    begin
        exit(LibraryERM.GetAmountRoundingPrecision() + 0.01);
    end;
}

