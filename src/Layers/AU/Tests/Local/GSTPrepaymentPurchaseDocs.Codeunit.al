codeunit 144001 "GST Prepayment - Purchase Docs"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [GST] [Prepayment] [Purchase]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
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
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GenPostingSetup: Record "General Posting Setup";
        DocNo: Code[10];
        DocNo2: Code[10];
    begin
        Initialize();
        LibraryAULocalization.EnableGSTSetup(true, false);

        // Setup
        CreatePostingSetup(GenPostingSetup);
        CreateHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor(GenPostingSetup."Gen. Bus. Posting Group"));
        ChangePrepaymentOnHeader(PurchaseHeader, LibraryRandom.RandInt(50));
        CreateLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(GenPostingSetup."Gen. Prod. Posting Group"));

        // Exercise
        PurchaseHeader2 := PurchaseHeader;
        DocNo := PostPrepInvoice(PurchaseHeader);
        UpdateVendorInvoiceNo(PurchaseHeader);
        DocNo2 := PostDocument(PurchaseHeader);

        // Verify
        VerifyPrepaymentGLEntries(DocNo, GLEntry."Document Type"::Invoice, PurchaseHeader2, PurchaseLine, true);
        VerifyPrepaymentVATEntries(DocNo, GLEntry."Document Type"::Invoice, PurchaseLine, true);
        VerifyInvoiceGLEntries(DocNo2, GLEntry."Document Type"::Invoice, PurchaseHeader2, PurchaseLine, PurchaseHeader."Prepayment %");
        VerifyInvoiceVATEntries(DocNo2, GLEntry."Document Type"::Invoice, PurchaseLine);

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
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PrepInvChangeRateFullInvFCYGainExclVAT()
    begin
        PrepInvChangeRateFullInvFCYGain(LibraryRandom.RandInt(50), false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PrepInvChangeRateFullInvFCYGainInclVAT()
    begin
        PrepInvChangeRateFullInvFCYGain(LibraryRandom.RandInt(50), true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PrepInvChangeRateFullInvFCYGainExclVAT100()
    begin
        PrepInvChangeRateFullInvFCYGain(100, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PrepInvChangeRateFullInvFCYGainInclVAT100()
    begin
        PrepInvChangeRateFullInvFCYGain(100, true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PrepInvChangeRateFullInvFCYLossExclVAT()
    begin
        PrepInvChangeRateFullInvFCYLoss(LibraryRandom.RandInt(50), false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PrepInvChangeRateFullInvFCYLossInclVAT()
    begin
        PrepInvChangeRateFullInvFCYLoss(LibraryRandom.RandInt(50), true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PrepInvChangeRateFullInvFCYLossExclVAT100()
    begin
        PrepInvChangeRateFullInvFCYLoss(100, false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
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

    local procedure PrepInvFullInv(PrepaymentPercent: Decimal; PricesIncludeVAT: Boolean)
    var
        GLEntry: Record "G/L Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GenPostingSetup: Record "General Posting Setup";
        DocNo: Code[10];
        DocNo2: Code[10];
    begin
        Initialize();
        // Setup
        CreatePostingSetup(GenPostingSetup);
        CreateHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor(GenPostingSetup."Gen. Bus. Posting Group"));
        ChangePricesIncludingVAT(PurchaseHeader, PricesIncludeVAT);
        ChangePrepaymentOnHeader(PurchaseHeader, PrepaymentPercent);
        CreateLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(GenPostingSetup."Gen. Prod. Posting Group"));
        // Exercise
        PurchaseHeader2 := PurchaseHeader;
        DocNo := PostPrepInvoice(PurchaseHeader);
        UpdateVendorInvoiceNo(PurchaseHeader);
        DocNo2 := PostDocument(PurchaseHeader);

        // Verify
        VerifyPrepaymentGLEntries(DocNo, GLEntry."Document Type"::Invoice, PurchaseHeader2, PurchaseLine, true);
        VerifyPrepaymentVATEntries(DocNo, GLEntry."Document Type"::Invoice, PurchaseLine, true);
        VerifyInvoiceGLEntries(DocNo2, GLEntry."Document Type"::Invoice, PurchaseHeader2, PurchaseLine, PrepaymentPercent);
        VerifyInvoiceVATEntries(DocNo2, GLEntry."Document Type"::Invoice, PurchaseLine);
    end;

    local procedure PrepInvFullInvMultipleLinesDifferentRates(PrepaymentPercent: Decimal; PricesIncludeVAT: Boolean)
    var
        GLEntry: Record "G/L Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        GenPostingSetup: Record "General Posting Setup";
        DocNo: Code[10];
        DocNo2: Code[10];
    begin
        Initialize();

        // Setup
        CreatePostingSetup(GenPostingSetup);
        CreateHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor(GenPostingSetup."Gen. Bus. Posting Group"));
        ChangePricesIncludingVAT(PurchaseHeader, PricesIncludeVAT);
        ChangePrepaymentOnHeader(PurchaseHeader, PrepaymentPercent);
        CreateLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(GenPostingSetup."Gen. Prod. Posting Group"));
        CreatePostingSetupWithDifferentVATRate(GenPostingSetup, PurchaseLine);
        CreateLine(PurchaseLine2, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(GenPostingSetup."Gen. Prod. Posting Group"));

        // Exercise
        PurchaseHeader2 := PurchaseHeader;
        DocNo := PostPrepInvoice(PurchaseHeader);
        UpdateVendorInvoiceNo(PurchaseHeader);
        DocNo2 := PostDocument(PurchaseHeader);

        // Verify
        VerifyPrepaymentGLEntriesMultipleLinesDifferentRates(
          DocNo, GLEntry."Document Type"::Invoice, PurchaseHeader2, PurchaseLine, PurchaseLine2, true);
        VerifyPrepaymentVATEntriesMultipleLinesDifferentRates(
          DocNo, GLEntry."Document Type"::Invoice, PurchaseLine, PurchaseLine2, true);
        VerifyInvoiceGLEntriesMultipleLinesDifferentRates(
          DocNo2, GLEntry."Document Type"::Invoice, PurchaseHeader2, PurchaseLine, PurchaseLine2, PrepaymentPercent);
        VerifyInvoiceVATEntriesMultipleLinesDifferentRates(
          DocNo2, GLEntry."Document Type"::Invoice, PurchaseLine, PurchaseLine2);
    end;

    local procedure PrepInvFullInvMultipleLinesDifferentRatesAndPrepayment(PrepaymentPercent: Decimal; PricesIncludeVAT: Boolean)
    var
        GLEntry: Record "G/L Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        GenPostingSetup: Record "General Posting Setup";
        DocNo: Code[10];
        DocNo2: Code[10];
    begin
        Initialize();

        // Setup
        CreatePostingSetup(GenPostingSetup);
        CreateHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor(GenPostingSetup."Gen. Bus. Posting Group"));
        ChangePricesIncludingVAT(PurchaseHeader, PricesIncludeVAT);
        ChangePrepaymentOnHeader(PurchaseHeader, PrepaymentPercent);
        CreateLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(GenPostingSetup."Gen. Prod. Posting Group"));
        CreatePostingSetupWithDifferentVATRate(GenPostingSetup, PurchaseLine);
        CreateLine(PurchaseLine2, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(GenPostingSetup."Gen. Prod. Posting Group"));
        ChangePrepaymentOnLine(PurchaseHeader, PurchaseLine2, PrepaymentPercent * 3 / 2);

        // Exercise
        PurchaseHeader2 := PurchaseHeader;
        DocNo := PostPrepInvoice(PurchaseHeader);
        UpdateVendorInvoiceNo(PurchaseHeader);
        DocNo2 := PostDocument(PurchaseHeader);

        // Verify
        VerifyPrepaymentGLEntriesMultipleLinesDifferentRates(
          DocNo, GLEntry."Document Type"::Invoice, PurchaseHeader2, PurchaseLine, PurchaseLine2, true);
        VerifyPrepaymentVATEntriesMultipleLinesDifferentRates(
          DocNo, GLEntry."Document Type"::Invoice, PurchaseLine, PurchaseLine2, true);
        VerifyInvoiceGLEntriesMultipleLinesDifferentRates(
          DocNo2, GLEntry."Document Type"::Invoice, PurchaseHeader2, PurchaseLine, PurchaseLine2, PrepaymentPercent);
        VerifyInvoiceVATEntriesMultipleLinesDifferentRates(
          DocNo2, GLEntry."Document Type"::Invoice, PurchaseLine, PurchaseLine2);
    end;

    local procedure PrepInvPrepCrMemo(PrepaymentPercent: Decimal; PricesIncludeVAT: Boolean)
    var
        GLEntry: Record "G/L Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GenPostingSetup: Record "General Posting Setup";
        DocNo: Code[10];
    begin
        Initialize();

        // Setup
        CreatePostingSetup(GenPostingSetup);
        CreateHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor(GenPostingSetup."Gen. Bus. Posting Group"));
        ChangePricesIncludingVAT(PurchaseHeader, PricesIncludeVAT);
        ChangePrepaymentOnHeader(PurchaseHeader, PrepaymentPercent);
        CreateLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(GenPostingSetup."Gen. Prod. Posting Group"));

        // Exercise
        PurchaseHeader2 := PurchaseHeader;
        PostPrepInvoice(PurchaseHeader);
        UpdateVendorCrMemoNo(PurchaseHeader);
        DocNo := PostPrepCreditMemo(PurchaseHeader);

        // Verify
        VerifyPrepaymentGLEntries(DocNo, GLEntry."Document Type"::"Credit Memo", PurchaseHeader2, PurchaseLine, false);
        VerifyPrepaymentVATEntries(DocNo, GLEntry."Document Type"::"Credit Memo", PurchaseLine, false);
    end;

    local procedure PrepInvPrepCrMemoMultipleLinesDifferentRates(PrepaymentPercent: Decimal; PricesIncludeVAT: Boolean)
    var
        GLEntry: Record "G/L Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        GenPostingSetup: Record "General Posting Setup";
        DocNo: Code[10];
    begin
        Initialize();

        // Setup
        CreatePostingSetup(GenPostingSetup);
        CreateHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor(GenPostingSetup."Gen. Bus. Posting Group"));
        ChangePricesIncludingVAT(PurchaseHeader, PricesIncludeVAT);
        ChangePrepaymentOnHeader(PurchaseHeader, PrepaymentPercent);
        CreateLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(GenPostingSetup."Gen. Prod. Posting Group"));
        CreatePostingSetupWithDifferentVATRate(GenPostingSetup, PurchaseLine);
        CreateLine(PurchaseLine2, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(GenPostingSetup."Gen. Prod. Posting Group"));

        // Exercise
        PurchaseHeader2 := PurchaseHeader;
        PostPrepInvoice(PurchaseHeader);
        UpdateVendorCrMemoNo(PurchaseHeader);
        DocNo := PostPrepCreditMemo(PurchaseHeader);

        // Verify
        VerifyPrepaymentGLEntriesMultipleLinesDifferentRates(
          DocNo, GLEntry."Document Type"::"Credit Memo", PurchaseHeader2, PurchaseLine, PurchaseLine2, false);
        VerifyPrepaymentVATEntriesMultipleLinesDifferentRates(
          DocNo, GLEntry."Document Type"::"Credit Memo", PurchaseLine, PurchaseLine2, false);
    end;

    local procedure PrepInvChangePrepPercFullInv(PrepaymentPercent: Decimal; PricesIncludeVAT: Boolean)
    var
        GLEntry: Record "G/L Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GenPostingSetup: Record "General Posting Setup";
        DocNo: Code[10];
        DocNo2: Code[10];
    begin
        Initialize();

        // Setup
        CreatePostingSetup(GenPostingSetup);
        CreateHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor(GenPostingSetup."Gen. Bus. Posting Group"));
        ChangePricesIncludingVAT(PurchaseHeader, PricesIncludeVAT);
        ChangePrepaymentOnHeader(PurchaseHeader, PrepaymentPercent);
        CreateLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(GenPostingSetup."Gen. Prod. Posting Group"));

        // Exercise
        PostPrepInvoice(PurchaseHeader);
        PurchaseLine.Find();
        ChangePrepaymentOnLine(PurchaseHeader, PurchaseLine, PurchaseLine."Prepayment %" * 3 / 2);
        PurchaseHeader2 := PurchaseHeader;
        UpdateVendorInvoiceNo(PurchaseHeader);
        DocNo := PostPrepInvoice(PurchaseHeader);
        UpdateVendorInvoiceNo(PurchaseHeader);
        DocNo2 := PostDocument(PurchaseHeader);

        // Verify
        VerifyAdditionalPrepaymentGLEntries(DocNo, GLEntry."Document Type"::Invoice, PurchaseHeader2, PurchaseLine);
        VerifyAdditionalPrepaymentVATEntries(DocNo, GLEntry."Document Type"::Invoice, PurchaseLine);
        VerifyInvoiceGLEntries(DocNo2, GLEntry."Document Type"::Invoice, PurchaseHeader2, PurchaseLine, PrepaymentPercent);
        VerifyInvoiceVATEntries(DocNo2, GLEntry."Document Type"::Invoice, PurchaseLine);
    end;

    local procedure PrepInvChangePrepPercCrMemo(PrepaymentPercent: Decimal; PricesIncludeVAT: Boolean)
    var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GenPostingSetup: Record "General Posting Setup";
        DocNo: Code[10];
    begin
        Initialize();

        // Setup
        CreatePostingSetup(GenPostingSetup);
        CreateHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor(GenPostingSetup."Gen. Bus. Posting Group"));
        ChangePricesIncludingVAT(PurchaseHeader, PricesIncludeVAT);
        ChangePrepaymentOnHeader(PurchaseHeader, PrepaymentPercent);
        CreateLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(GenPostingSetup."Gen. Prod. Posting Group"));

        // Exercise
        PostPrepInvoice(PurchaseHeader);
        PurchaseLine.Find();
        ChangePrepaymentOnLine(PurchaseHeader, PurchaseLine, PurchaseLine."Prepayment %" * 3 / 2);
        PurchaseHeader2 := PurchaseHeader;
        UpdateVendorInvoiceNo(PurchaseHeader);
        PostPrepInvoice(PurchaseHeader);
        UpdateVendorCrMemoNo(PurchaseHeader);
        DocNo := PostPrepCreditMemo(PurchaseHeader);

        // Verify
        VerifyPrepaymentGLEntries(DocNo, GLEntry."Document Type"::"Credit Memo", PurchaseHeader2, PurchaseLine, false);
        VerifyPrepaymentVATEntries(DocNo, VATEntry."Document Type"::"Credit Memo", PurchaseLine, false);
    end;

    local procedure PrepInvPartInvFullInv(PrepaymentPercent: Decimal; PricesIncludeVAT: Boolean)
    var
        GLEntry: Record "G/L Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GenPostingSetup: Record "General Posting Setup";
        DocNo: Code[10];
        DocNo2: Code[10];
    begin
        Initialize();

        // Setup
        CreatePostingSetup(GenPostingSetup);
        CreateHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor(GenPostingSetup."Gen. Bus. Posting Group"));
        ChangePricesIncludingVAT(PurchaseHeader, PricesIncludeVAT);
        ChangePrepaymentOnHeader(PurchaseHeader, PrepaymentPercent);
        CreateLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(GenPostingSetup."Gen. Prod. Posting Group"));

        // Exercise
        PostPrepInvoice(PurchaseHeader);
        PurchaseLine.Find();
        ChangeQtyToPostOnLine(PurchaseLine);
        PurchaseHeader2 := PurchaseHeader;
        UpdateVendorInvoiceNo(PurchaseHeader);
        DocNo := PostDocument(PurchaseHeader);
        UpdateVendorInvoiceNo(PurchaseHeader);
        DocNo2 := PostDocument(PurchaseHeader);

        // Verify
        VerifyInvoiceGLEntries(DocNo, GLEntry."Document Type"::Invoice, PurchaseHeader2, PurchaseLine, PrepaymentPercent);
        VerifyInvoiceVATEntries(DocNo, GLEntry."Document Type"::Invoice, PurchaseLine);
        VerifyInvoiceGLEntries(DocNo2, GLEntry."Document Type"::Invoice, PurchaseHeader2, PurchaseLine, PrepaymentPercent);
        VerifyInvoiceVATEntries(DocNo2, GLEntry."Document Type"::Invoice, PurchaseLine);
    end;

    local procedure PrepInvPartInv2FullInv(PrepaymentPercent: Decimal; PricesIncludeVAT: Boolean)
    var
        GLEntry: Record "G/L Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GenPostingSetup: Record "General Posting Setup";
        DocNo: Code[10];
        DocNo2: Code[10];
    begin
        Initialize();

        // Setup
        CreatePostingSetup(GenPostingSetup);
        CreateHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor(GenPostingSetup."Gen. Bus. Posting Group"));
        ChangePricesIncludingVAT(PurchaseHeader, PricesIncludeVAT);
        ChangePrepaymentOnHeader(PurchaseHeader, PrepaymentPercent);
        CreateLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(GenPostingSetup."Gen. Prod. Posting Group"));
        ChangeQtyToPostOnLine(PurchaseLine);

        // Exercise
        PurchaseHeader2 := PurchaseHeader;
        PostPrepInvoice(PurchaseHeader);
        UpdateVendorInvoiceNo(PurchaseHeader);
        DocNo := PostDocument(PurchaseHeader);
        UpdateVendorInvoiceNo(PurchaseHeader);
        DocNo2 := PostDocument(PurchaseHeader);

        // Verify
        VerifyInvoiceGLEntries(DocNo, GLEntry."Document Type"::Invoice, PurchaseHeader2, PurchaseLine, PrepaymentPercent);
        VerifyInvoiceVATEntries(DocNo, GLEntry."Document Type"::Invoice, PurchaseLine);
        VerifyInvoiceGLEntries(DocNo2, GLEntry."Document Type"::Invoice, PurchaseHeader2, PurchaseLine, PrepaymentPercent);
        VerifyInvoiceVATEntries(DocNo2, GLEntry."Document Type"::Invoice, PurchaseLine);
    end;

    local procedure PrepInvFullInvFCY(PrepaymentPercent: Decimal; PricesIncludeVAT: Boolean)
    var
        GLEntry: Record "G/L Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GenPostingSetup: Record "General Posting Setup";
        DocNo: Code[10];
        DocNo2: Code[10];
    begin
        Initialize();

        // Setup
        CreatePostingSetup(GenPostingSetup);
        CreateHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor(GenPostingSetup."Gen. Bus. Posting Group"));
        ChangePricesIncludingVAT(PurchaseHeader, PricesIncludeVAT);
        ChangePrepaymentOnHeader(PurchaseHeader, PrepaymentPercent);
        ChangeCurrencyOnHeader(PurchaseHeader, CreateCurrencyWithExchangeRate(1));
        CreateLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(GenPostingSetup."Gen. Prod. Posting Group"));

        // Exercise
        PurchaseHeader2 := PurchaseHeader;
        DocNo := PostPrepInvoice(PurchaseHeader);
        UpdateVendorInvoiceNo(PurchaseHeader);
        DocNo2 := PostDocument(PurchaseHeader);

        // Verify
        VerifyPrepaymentGLEntries(DocNo, GLEntry."Document Type"::Invoice, PurchaseHeader2, PurchaseLine, true);
        VerifyPrepaymentVATEntries(DocNo, GLEntry."Document Type"::Invoice, PurchaseLine, true);
        VerifyInvoiceGLEntries(DocNo2, GLEntry."Document Type"::Invoice, PurchaseHeader2, PurchaseLine, PrepaymentPercent);
        VerifyInvoiceVATEntries(DocNo2, GLEntry."Document Type"::Invoice, PurchaseLine);
    end;

    local procedure PrepInvChangeRateFullInvFCYGain(PrepaymentPercent: Decimal; PricesIncludeVAT: Boolean)
    var
        GLEntry: Record "G/L Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GenPostingSetup: Record "General Posting Setup";
        DocNo: Code[10];
        DocNo2: Code[10];
        NewDate: Date;
        InvoicedAmount: Decimal;
    begin
        Initialize();

        // Setup
        CreatePostingSetup(GenPostingSetup);
        CreateHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor(GenPostingSetup."Gen. Bus. Posting Group"));
        ChangePricesIncludingVAT(PurchaseHeader, PricesIncludeVAT);
        ChangePrepaymentOnHeader(PurchaseHeader, PrepaymentPercent);
        ChangeCurrencyOnHeader(PurchaseHeader, CreateCurrencyWithExchangeRate(1));
        CreateLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(GenPostingSetup."Gen. Prod. Posting Group"));

        // Exercise
        PurchaseHeader2 := PurchaseHeader;
        DocNo := PostPrepInvoice(PurchaseHeader);
        NewDate := CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(10)), WorkDate());
        ChangePostingDate(PurchaseHeader, NewDate);
        PurchaseLine.Find();
        UpdateVendorInvoiceNo(PurchaseHeader);
        DocNo2 := PostDocument(PurchaseHeader);

        // Verify
        VerifyPrepaymentGLEntriesOnDate(DocNo, GLEntry."Document Type"::Invoice, PurchaseHeader2, PurchaseLine, true, WorkDate());
        VerifyPrepaymentVATEntriesOnDate(DocNo, GLEntry."Document Type"::Invoice, PurchaseLine, true, WorkDate());
        InvoicedAmount := GetPrepaymentInvoicedAmountOnDate(PurchaseLine, WorkDate());
        VerifyInvoiceGLEntriesOnDate(DocNo2, GLEntry."Document Type"::Invoice, PurchaseHeader2, PurchaseLine, NewDate, PrepaymentPercent);
        VerifyInvoiceGLEntriesAfterCurrencyRateChangeGain(
          DocNo2, GLEntry."Document Type"::Invoice, PurchaseLine, InvoicedAmount, NewDate);
        VerifyInvoiceVATEntriesOnDate(DocNo2, GLEntry."Document Type"::Invoice, PurchaseLine, NewDate);
    end;

    local procedure PrepInvChangeRateFullInvFCYLoss(PrepaymentPercent: Decimal; PricesIncludeVAT: Boolean)
    var
        GLEntry: Record "G/L Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GenPostingSetup: Record "General Posting Setup";
        DocNo: Code[10];
        DocNo2: Code[10];
        NewDate: Date;
        InvoicedAmount: Decimal;
    begin
        Initialize();

        // Setup
        CreatePostingSetup(GenPostingSetup);
        CreateHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor(GenPostingSetup."Gen. Bus. Posting Group"));
        ChangePricesIncludingVAT(PurchaseHeader, PricesIncludeVAT);
        ChangePrepaymentOnHeader(PurchaseHeader, PrepaymentPercent);
        ChangeCurrencyOnHeader(PurchaseHeader, CreateCurrencyWithExchangeRate(-1));
        CreateLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(GenPostingSetup."Gen. Prod. Posting Group"));

        // Exercise
        PurchaseHeader2 := PurchaseHeader;
        DocNo := PostPrepInvoice(PurchaseHeader);
        NewDate := CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(10)), WorkDate());
        ChangePostingDate(PurchaseHeader, NewDate);
        PurchaseLine.Find();
        UpdateVendorInvoiceNo(PurchaseHeader);
        DocNo2 := PostDocument(PurchaseHeader);

        // Verify
        VerifyPrepaymentGLEntriesOnDate(DocNo, GLEntry."Document Type"::Invoice, PurchaseHeader2, PurchaseLine, true, WorkDate());
        VerifyPrepaymentVATEntriesOnDate(DocNo, GLEntry."Document Type"::Invoice, PurchaseLine, true, WorkDate());
        InvoicedAmount := GetPrepaymentInvoicedAmountOnDate(PurchaseLine, WorkDate());
        VerifyInvoiceGLEntriesOnDate(DocNo2, GLEntry."Document Type"::Invoice, PurchaseHeader2, PurchaseLine, NewDate, PrepaymentPercent);
        VerifyInvoiceGLEntriesAfterCurrencyRateChangeLoss(
          DocNo2, GLEntry."Document Type"::Invoice, PurchaseLine, InvoicedAmount, NewDate);
        VerifyInvoiceVATEntriesOnDate(DocNo2, GLEntry."Document Type"::Invoice, PurchaseLine, NewDate);
    end;

    local procedure PrepInvFullInvUnrealized(PrepaymentPercent: Decimal; PricesIncludeVAT: Boolean)
    var
        GLEntry: Record "G/L Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseHeader2: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GenPostingSetup: Record "General Posting Setup";
        DocNo: Code[10];
        DocNo2: Code[10];
    begin
        Initialize();

        // Setup
        LibraryERM.SetUnrealizedVAT(true);
        CreatePostingSetup(GenPostingSetup);
        SetupUnrealizedVAT(GenPostingSetup);
        CreateHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor(GenPostingSetup."Gen. Bus. Posting Group"));
        ChangePricesIncludingVAT(PurchaseHeader, PricesIncludeVAT);
        ChangePrepaymentOnHeader(PurchaseHeader, PrepaymentPercent);
        CreateLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(GenPostingSetup."Gen. Prod. Posting Group"));

        // Exercise
        PurchaseHeader2 := PurchaseHeader;
        DocNo := PostPrepInvoice(PurchaseHeader);
        UpdateVendorInvoiceNo(PurchaseHeader);
        DocNo2 := PostDocument(PurchaseHeader);

        // Verify
        VerifyPrepaymentGLEntries(DocNo, GLEntry."Document Type"::Invoice, PurchaseHeader2, PurchaseLine, true);
        VerifyPrepaymentVATEntries(DocNo, GLEntry."Document Type"::Invoice, PurchaseLine, true);
        VerifyInvoiceGLEntries(DocNo2, GLEntry."Document Type"::Invoice, PurchaseHeader2, PurchaseLine, PrepaymentPercent);
        VerifyInvoiceVATEntries(DocNo2, GLEntry."Document Type"::Invoice, PurchaseLine);

        // Tear Down
        TearDownUnrealizedVAT(GenPostingSetup);
        LibraryERM.SetUnrealizedVAT(false);
    end;

    local procedure ChangeCurrencyOnHeader(var PurchaseHeader: Record "Purchase Header"; CurrencyCode: Code[10])
    var
        ReleasePurchaseDoc: Codeunit "Release Purchase Document";
    begin
        if PurchaseHeader.Status <> PurchaseHeader.Status::Open then
            ReleasePurchaseDoc.PerformManualReopen(PurchaseHeader);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
    end;

    local procedure ChangePostingDate(var PurchaseHeader: Record "Purchase Header"; PostingDate: Date)
    var
        ReleasePurchaseDoc: Codeunit "Release Purchase Document";
    begin
        if PurchaseHeader.Status <> PurchaseHeader.Status::Open then
            ReleasePurchaseDoc.PerformManualReopen(PurchaseHeader);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);
    end;

    local procedure ChangePrepaymentOnHeader(var PurchaseHeader: Record "Purchase Header"; PrepaymentPercent: Decimal)
    var
        ReleasePurchaseDoc: Codeunit "Release Purchase Document";
    begin
        if PurchaseHeader.Status <> PurchaseHeader.Status::Open then
            ReleasePurchaseDoc.PerformManualReopen(PurchaseHeader);
        PurchaseHeader.Validate("Prepayment %", PrepaymentPercent);
        PurchaseHeader.Modify(true);
    end;

    local procedure ChangePrepaymentOnLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; PrepaymentPercent: Decimal)
    var
        ReleasePurchaseDoc: Codeunit "Release Purchase Document";
    begin
        if PurchaseHeader.Status <> PurchaseHeader.Status::Open then
            ReleasePurchaseDoc.PerformManualReopen(PurchaseHeader);
        PurchaseLine.Validate("Prepayment %", PrepaymentPercent);
        PurchaseLine.Modify(true);
    end;

    local procedure ChangePricesIncludingVAT(var PurchaseHeader: Record "Purchase Header"; IncludingVAT: Boolean)
    begin
        PurchaseHeader.Validate("Prices Including VAT", IncludingVAT);
        PurchaseHeader.Modify(true);
    end;

    local procedure ChangeQtyToPostOnLine(var PurchaseLine: Record "Purchase Line"): Code[10]
    begin
        PurchaseLine.Validate("Qty. to Invoice", PurchaseLine."Qty. to Invoice" / 2);
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine."Qty. to Receive" / 2);
        PurchaseLine.Validate("Return Qty. to Ship", PurchaseLine."Return Qty. to Ship" / 2);
        PurchaseLine.Modify(true);
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

    local procedure CreateVendor(GenBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        Vendor.ABN := '53004084612'; // Valid ABN No.
        Vendor.Validate(Registered, true);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
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

    local procedure CreateLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20])
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, LibraryRandom.RandInt(20) * 2); // Qty to let at least 2 partial postings
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
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
        GenPostingSetup.Validate("Purch. Account", CreateAccount(GenProdPostingGroup.Code, GenPostingSetup.FieldCaption("Purch. Account")
            + ' ' + GenPostingSetup."Gen. Prod. Posting Group" + ' ' + GenPostingSetup."Gen. Bus. Posting Group"));
        GenPostingSetup.Validate(
          "Purch. Prepayments Account", CreateAccount(GenProdPostingGroup.Code, GenPostingSetup.FieldCaption("Purch. Prepayments Account")
            + ' ' + GenPostingSetup."Gen. Prod. Posting Group" + ' ' + GenPostingSetup."Gen. Bus. Posting Group"));
        GenPostingSetup.Validate(
          "Direct Cost Applied Account",
          CreateAccount(GenProdPostingGroup.Code, GenPostingSetup.FieldCaption("Direct Cost Applied Account")
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

    local procedure CreatePostingSetupWithDifferentVATRate(var GenPostingSetup: Record "General Posting Setup"; PurchaseLine: Record "Purchase Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenBusPostingGroup: Record "Gen. Business Posting Group";
    begin
        FindVATPostingSetupWithDifferentRate(VATPostingSetup, PurchaseLine);
        GenBusPostingGroup.Get(PurchaseLine."Gen. Bus. Posting Group");
        CreateGenPostingSetup(GenPostingSetup, VATPostingSetup, GenBusPostingGroup);
    end;

    local procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetFilter("Purchase VAT Account", '<>%1', '');
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
    end;

    local procedure FindVATPostingSetupWithDifferentRate(var VATPostingSetup: Record "VAT Posting Setup"; PurchaseLine: Record "Purchase Line")
    var
        VATProdPostingGroup: Record "VAT Product Posting Group";
        GLAccount: Record "G/L Account";
    begin
        VATPostingSetup.SetFilter("Purchase VAT Account", '<>%1', '');
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", PurchaseLine."VAT Bus. Posting Group");
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', PurchaseLine."VAT Prod. Posting Group");
        VATPostingSetup.SetFilter("VAT %", '>%1', PurchaseLine."VAT %");
        if not VATPostingSetup.FindFirst() then begin
            LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, PurchaseLine."VAT Bus. Posting Group", VATProdPostingGroup.Code);
            VATPostingSetup.Validate("VAT %", PurchaseLine."VAT %" + LibraryRandom.RandInt(10));
            LibraryERM.CreateGLAccount(GLAccount);
            VATPostingSetup.Validate("Purchase VAT Account", GLAccount."No.");
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

    local procedure GetAmountOnDate(PurchaseLine: Record "Purchase Line"; Date: Date) Amount: Decimal
    begin
        Amount := PurchaseLine.Amount * PurchaseLine."Qty. to Invoice" / PurchaseLine.Quantity;
        Amount := ConvertAndRoundAmount(Amount, PurchaseLine."Currency Code", Date);
    end;

    local procedure GetPrepaymentAmount(PurchaseLine: Record "Purchase Line") Amount: Decimal
    begin
        Amount := GetPrepaymentAmountOnDate(PurchaseLine, WorkDate());
    end;

    local procedure GetPrepaymentAmountOnDate(PurchaseLine: Record "Purchase Line"; Date: Date) Amount: Decimal
    begin
        Amount := PurchaseLine.Amount * PurchaseLine."Qty. to Invoice" / PurchaseLine.Quantity * PurchaseLine."Prepayment %" / 100;
        Amount := ConvertAndRoundAmount(Amount, PurchaseLine."Currency Code", Date);
    end;

    local procedure GetPrepaymentInvoicedAmount(PurchaseLine: Record "Purchase Line") Amount: Decimal
    begin
        Amount := GetPrepaymentInvoicedAmountOnDate(PurchaseLine, WorkDate());
    end;

    local procedure GetPrepaymentInvoicedAmountOnDate(PurchaseLine: Record "Purchase Line"; Date: Date) Amount: Decimal
    begin
        Amount := PurchaseLine."Prepayment Amount";
        Amount := ConvertAndRoundAmount(Amount, PurchaseLine."Currency Code", Date);
    end;

    local procedure GetPrepaymentVATAmountOnDate(PurchaseLine: Record "Purchase Line"; Date: Date) Amount: Decimal
    begin
        if FullGSTOnPrepayment() and not UnrealizedVATEnabled() then
            Amount := PurchaseLine.Amount * PurchaseLine."Qty. to Invoice" / PurchaseLine.Quantity * PurchaseLine."VAT %" / 100
        else
            Amount :=
              PurchaseLine.Amount *
              PurchaseLine."Qty. to Invoice" / PurchaseLine.Quantity * PurchaseLine."VAT %" / 100 * PurchaseLine."Prepayment %" / 100;
        Amount := ConvertAndRoundAmount(Amount, PurchaseLine."Currency Code", Date);
    end;

    local procedure GetPrepaymentVATBaseOnDate(PurchaseLine: Record "Purchase Line"; Date: Date) Amount: Decimal
    begin
        if FullGSTOnPrepayment() and not UnrealizedVATEnabled() then
            Amount := PurchaseLine.Amount * PurchaseLine."Qty. to Invoice" / PurchaseLine.Quantity
        else
            Amount := PurchaseLine.Amount * PurchaseLine."Qty. to Invoice" / PurchaseLine.Quantity * PurchaseLine."Prepayment %" / 100;
        Amount := ConvertAndRoundAmount(Amount, PurchaseLine."Currency Code", Date);
    end;

    local procedure GetVATAmountOnDate(PurchaseLine: Record "Purchase Line"; Date: Date) Amount: Decimal
    begin
        Amount := PurchaseLine.Amount * PurchaseLine."Qty. to Invoice" / PurchaseLine.Quantity * PurchaseLine."VAT %" / 100;
        Amount := ConvertAndRoundAmount(Amount, PurchaseLine."Currency Code", Date);
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

    local procedure GetPayablesAccountNo(VendorPostingGroupCode: Code[20]) PayablesAccount: Code[20]
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        VendorPostingGroup.Get(VendorPostingGroupCode);
        PayablesAccount := VendorPostingGroup."Payables Account";
    end;

    local procedure GetPurchaseAccountNo(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]) PurchaseAccount: Code[20]
    var
        GenPostingSetup: Record "General Posting Setup";
    begin
        GenPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        PurchaseAccount := GenPostingSetup."Purch. Account";
    end;

    local procedure GetPurchasePrepAccountNo(GenBusPostingGroup: Code[20]; GenProdPostingGroup: Code[20]) PurchasePrepAccount: Code[20]
    var
        GenPostingSetup: Record "General Posting Setup";
    begin
        GenPostingSetup.Get(GenBusPostingGroup, GenProdPostingGroup);
        PurchasePrepAccount := GenPostingSetup."Purch. Prepayments Account";
    end;

    local procedure GetVATAccountNo(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]) PurchVATAccount: Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup);
        if not UnrealizedVATEnabled() then
            PurchVATAccount := VATPostingSetup."Purchase VAT Account"
        else
            PurchVATAccount := VATPostingSetup."Purch. VAT Unreal. Account"
    end;

    local procedure ModifyCurrencyExchangeRate(var CurrencyExchangeRate: Record "Currency Exchange Rate"; ExchangeRateAmount: Decimal; RelationalExchRateAmount: Decimal)
    begin
        CurrencyExchangeRate.Validate("Exchange Rate Amount", ExchangeRateAmount);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", RelationalExchRateAmount);
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure PostDocument(var PurchaseHeader: Record "Purchase Header"): Code[10]
    begin
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure PostPrepCreditMemo(var PurchaseHeader: Record "Purchase Header") DocumentNo: Code[10]
    var
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
        NoSeries: Codeunit "No. Series";
    begin
        DocumentNo := NoSeries.PeekNextNo(PurchaseHeader."Prepmt. Cr. Memo No. Series");
        PurchasePostPrepayments.CreditMemo(PurchaseHeader);
        exit(DocumentNo);
    end;

    local procedure PostPrepInvoice(var PurchaseHeader: Record "Purchase Header") DocumentNo: Code[10]
    var
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
        NoSeries: Codeunit "No. Series";
    begin
        DocumentNo := NoSeries.PeekNextNo(PurchaseHeader."Prepayment No. Series");
        PurchasePostPrepayments.Invoice(PurchaseHeader);
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
          "Purch. VAT Unreal. Account", CreateAccount(GenProdPostingGroup.Code, VATPostingSetup.FieldCaption("Purch. VAT Unreal. Account")));
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
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", '');
        VATPostingSetup.Modify(true);
    end;

    local procedure UnrealizedVATEnabled(): Boolean
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        exit(GLSetup."Unrealized VAT");
    end;

    local procedure UpdateVendorInvoiceNo(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdateVendorCrMemoNo(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
    end;

    local procedure VerifyAdditionalPrepaymentGLEntries(DocumentNo: Code[10]; DocumentType: Enum "Gen. Journal Document Type"; PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line")
    begin
        VerifyGLEntry(
          DocumentNo, DocumentType,
          GetPurchasePrepAccountNo(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group"),
          GetPrepaymentAmount(PurchaseLine) -
          GetPrepaymentInvoicedAmount(PurchaseLine), 0, false);
        VerifyGLEntry(
          DocumentNo, DocumentType, GetPayablesAccountNo(PurchaseHeader."Vendor Posting Group"),
          -GetPrepaymentAmount(PurchaseLine) + GetPrepaymentInvoicedAmount(PurchaseLine), 0, false);
    end;

    local procedure VerifyAdditionalPrepaymentVATEntries(DocumentNo: Code[10]; DocumentType: Enum "Gen. Journal Document Type"; PurchaseLine: Record "Purchase Line")
    var
        VATEntry: Record "VAT Entry";
        GSTPurchaseEntry: Record "GST Sales Entry";
    begin
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("VAT Bus. Posting Group", PurchaseLine."VAT Bus. Posting Group");
        VATEntry.SetRange("VAT Prod. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        Assert.IsTrue(VATEntry.IsEmpty, EntriesError);
        GSTPurchaseEntry.SetRange("Document Type", DocumentType);
        GSTPurchaseEntry.SetRange("Document No.", DocumentNo);
        GSTPurchaseEntry.SetRange("VAT Bus. Posting Group", PurchaseLine."VAT Bus. Posting Group");
        GSTPurchaseEntry.SetRange("VAT Prod. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        Assert.IsTrue(GSTPurchaseEntry.IsEmpty, EntriesError);
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
            GLEntry.SetFilter(
              Amount, '<=%1&>=%2', Amount + LibraryERM.GetAmountRoundingPrecision(), Amount - LibraryERM.GetAmountRoundingPrecision());
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

    local procedure VerifyGSTPurchaseEntry(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]; Base: Decimal; Amount: Decimal; DoubleEntry: Boolean)
    var
        GSTPurchaseEntry: Record "GST Purchase Entry";
    begin
        GSTPurchaseEntry.SetRange("Document Type", DocumentType);
        GSTPurchaseEntry.SetRange("Document No.", DocumentNo);
        GSTPurchaseEntry.SetRange("VAT Bus. Posting Group", VATBusPostingGroup);
        GSTPurchaseEntry.SetRange("VAT Prod. Posting Group", VATProdPostingGroup);

        if DoubleEntry then // There are 2 VAT Entries with the same Document No. and Posting Groups, so additional filter is needed
            if Base < 0 then
                GSTPurchaseEntry.SetFilter("GST Base", '<0')
            else
                GSTPurchaseEntry.SetFilter("GST Base", '>=0');
        GSTPurchaseEntry.FindFirst();

        Assert.AreNearlyEqual(Base, GSTPurchaseEntry."GST Base", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValidationError, GSTPurchaseEntry.FieldCaption("GST Base"), Base, GSTPurchaseEntry.TableCaption()));
        Assert.AreNearlyEqual(Amount, GSTPurchaseEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValidationError, GSTPurchaseEntry.FieldCaption(Amount), Amount, GSTPurchaseEntry.TableCaption()));
    end;

    local procedure VerifyInvoiceGLEntries(DocumentNo: Code[10]; DocumentType: Enum "Gen. Journal Document Type"; PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; PrepaymentPercent: Decimal)
    begin
        VerifyInvoiceGLEntriesOnDate(DocumentNo, DocumentType, PurchaseHeader, PurchaseLine, WorkDate(), PrepaymentPercent);
    end;

    local procedure VerifyInvoiceGLEntriesMultipleLinesDifferentRates(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; PurchaseLine2: Record "Purchase Line"; PrepaymentPercent: Decimal)
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
        PrepaymentAmount := GetPrepaymentAmountOnDate(PurchaseLine, WorkDate());
        PrepaymentVATAmount := GetPrepaymentVATAmountOnDate(PurchaseLine, WorkDate());
        PrepaymentAmount2 := GetPrepaymentAmountOnDate(PurchaseLine2, WorkDate());
        PrepaymentVATAmount2 := GetPrepaymentVATAmountOnDate(PurchaseLine2, WorkDate());
        Amount := GetAmountOnDate(PurchaseLine, WorkDate());
        Amount2 := GetAmountOnDate(PurchaseLine2, WorkDate());
        VATAmount := GetVATAmountOnDate(PurchaseLine, WorkDate());
        VATAmount2 := GetVATAmountOnDate(PurchaseLine2, WorkDate());

        VerifyGLEntry(
          DocumentNo, DocumentType,
          GetPurchasePrepAccountNo(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group"),
          -PrepaymentAmount, -PrepaymentVATAmount, false);
        VerifyGLEntry(
          DocumentNo, DocumentType,
          GetVATAccountNo(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group"),
          -PrepaymentVATAmount, 0, true);
        VerifyGLEntry(
          DocumentNo, DocumentType,
          GetPurchasePrepAccountNo(PurchaseLine2."Gen. Bus. Posting Group", PurchaseLine2."Gen. Prod. Posting Group"),
          -PrepaymentAmount2, -PrepaymentVATAmount2, false);
        VerifyGLEntry(
          DocumentNo, DocumentType,
          GetVATAccountNo(PurchaseLine2."VAT Bus. Posting Group", PurchaseLine2."VAT Prod. Posting Group"),
          -PrepaymentVATAmount2, 0, true);
        VerifyGLEntry(
          DocumentNo, DocumentType,
          GetPurchaseAccountNo(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group"),
          Amount, VATAmount, false);
        VerifyGLEntry(
          DocumentNo, DocumentType,
          GetVATAccountNo(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group"),
          VATAmount, 0, true);
        VerifyGLEntry(
          DocumentNo, DocumentType,
          GetPurchaseAccountNo(PurchaseLine2."Gen. Bus. Posting Group", PurchaseLine2."Gen. Prod. Posting Group"),
          Amount2, VATAmount2, false);
        VerifyGLEntry(
          DocumentNo, DocumentType,
          GetVATAccountNo(PurchaseLine2."VAT Bus. Posting Group", PurchaseLine2."VAT Prod. Posting Group"),
          VATAmount2, 0, true);
        if PrepaymentPercent <> 100 then
            VerifyGLEntry(
              DocumentNo, DocumentType, GetPayablesAccountNo(PurchaseHeader."Vendor Posting Group"),
              -Amount - Amount2 + PrepaymentAmount + PrepaymentAmount2 - VATAmount - VATAmount2 +
              PrepaymentVATAmount + PrepaymentVATAmount2, 0, false);
    end;

    local procedure VerifyInvoiceGLEntriesOnDate(DocumentNo: Code[10]; DocumentType: Enum "Gen. Journal Document Type"; PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; Date: Date; PrepaymentPercent: Decimal)
    var
        PrepaymentAmount: Decimal;
        PrepaymentVATAmount: Decimal;
        Amount: Decimal;
        VATAmount: Decimal;
    begin
        PrepaymentAmount := GetPrepaymentAmountOnDate(PurchaseLine, Date);
        PrepaymentVATAmount := GetPrepaymentVATAmountOnDate(PurchaseLine, Date);
        Amount := GetAmountOnDate(PurchaseLine, Date);
        VATAmount := GetVATAmountOnDate(PurchaseLine, Date);
        VerifyGLEntry(
          DocumentNo, DocumentType,
          GetPurchasePrepAccountNo(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group"),
          -PrepaymentAmount, -PrepaymentVATAmount, false);
        VerifyGLEntry(
          DocumentNo, DocumentType,
          GetVATAccountNo(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group"),
          -PrepaymentVATAmount, 0, true);
        VerifyGLEntry(
          DocumentNo, DocumentType,
          GetPurchaseAccountNo(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group"),
          Amount, VATAmount, false);
        VerifyGLEntry(
          DocumentNo, DocumentType,
          GetVATAccountNo(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group"),
          VATAmount, 0, true);
        if PrepaymentPercent <> 100 then
            VerifyGLEntry(
              DocumentNo, DocumentType, GetPayablesAccountNo(PurchaseHeader."Vendor Posting Group"),
              PrepaymentAmount - Amount - VATAmount + PrepaymentVATAmount, 0, false);
    end;

    local procedure VerifyInvoiceGLEntriesAfterCurrencyRateChangeGain(DocumentNo: Code[10]; DocumentType: Enum "Gen. Journal Document Type"; PurchaseLine: Record "Purchase Line"; InvoicedAmount: Decimal; Date: Date)
    var
        AmountDifference: Decimal;
    begin
        AmountDifference := Abs(InvoicedAmount - GetPrepaymentAmountOnDate(PurchaseLine, Date));
        VerifyGLEntry(
          DocumentNo, DocumentType,
          GetPurchasePrepAccountNo(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group"),
          AmountDifference, 0, true);
        VerifyGLEntry(
          DocumentNo, DocumentType,
          GetRealizedGainsAccountNo(PurchaseLine."Currency Code"), -AmountDifference, 0, false);
    end;

    local procedure VerifyInvoiceGLEntriesAfterCurrencyRateChangeLoss(DocumentNo: Code[10]; DocumentType: Enum "Gen. Journal Document Type"; PurchaseLine: Record "Purchase Line"; InvoicedAmount: Decimal; Date: Date)
    var
        AmountDifference: Decimal;
    begin
        AmountDifference := Abs(InvoicedAmount - GetPrepaymentAmountOnDate(PurchaseLine, Date));
        VerifyGLEntry(
          DocumentNo, DocumentType,
          GetPurchasePrepAccountNo(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group"),
          -AmountDifference, 0, true);
        VerifyGLEntry(
          DocumentNo, DocumentType,
          GetRealizedLossesAccountNo(PurchaseLine."Currency Code"), AmountDifference, 0, false);
    end;

    local procedure VerifyInvoiceVATEntries(DocumentNo: Code[10]; DocumentType: Enum "Gen. Journal Document Type"; PurchaseLine: Record "Purchase Line")
    begin
        VerifyInvoiceVATEntriesOnDate(DocumentNo, DocumentType, PurchaseLine, WorkDate());
    end;

    local procedure VerifyInvoiceVATEntriesMultipleLinesDifferentRates(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; PurchaseLine: Record "Purchase Line"; PurchaseLine2: Record "Purchase Line")
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
        PrepaymentVATBase := GetPrepaymentVATBaseOnDate(PurchaseLine, WorkDate());
        PrepaymentVATAmount := GetPrepaymentVATAmountOnDate(PurchaseLine, WorkDate());
        PrepaymentVATBase2 := GetPrepaymentVATBaseOnDate(PurchaseLine2, WorkDate());
        PrepaymentVATAmount2 := GetPrepaymentVATAmountOnDate(PurchaseLine2, WorkDate());
        Amount := GetAmountOnDate(PurchaseLine, WorkDate());
        VATAmount := GetVATAmountOnDate(PurchaseLine, WorkDate());
        Amount2 := GetAmountOnDate(PurchaseLine2, WorkDate());
        VATAmount2 := GetVATAmountOnDate(PurchaseLine2, WorkDate());

        VerifyVATEntry(
          DocumentNo, DocumentType,
          PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group", -PrepaymentVATBase,
          -PrepaymentVATAmount, true);
        VerifyVATEntry(
          DocumentNo, DocumentType,
          PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group", Amount, VATAmount, true);
        VerifyVATEntry(
          DocumentNo, DocumentType,
          PurchaseLine2."VAT Bus. Posting Group", PurchaseLine2."VAT Prod. Posting Group", -PrepaymentVATBase2,
          -PrepaymentVATAmount2, true);
        VerifyVATEntry(
          DocumentNo, DocumentType,
          PurchaseLine2."VAT Bus. Posting Group", PurchaseLine2."VAT Prod. Posting Group", Amount2, VATAmount2, true);

        VerifyGSTPurchaseEntry(
          DocumentNo, DocumentType,
          PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group", -PrepaymentVATBase,
          -PrepaymentVATAmount, true);
        VerifyGSTPurchaseEntry(
          DocumentNo, DocumentType,
          PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group", Amount, VATAmount, true);
        VerifyGSTPurchaseEntry(
          DocumentNo, DocumentType,
          PurchaseLine2."VAT Bus. Posting Group", PurchaseLine2."VAT Prod. Posting Group", -PrepaymentVATBase2,
          -PrepaymentVATAmount2, true);
        VerifyGSTPurchaseEntry(
          DocumentNo, DocumentType,
          PurchaseLine2."VAT Bus. Posting Group", PurchaseLine2."VAT Prod. Posting Group", Amount2, VATAmount2,
          true);
    end;

    local procedure VerifyInvoiceVATEntriesOnDate(DocumentNo: Code[10]; DocumentType: Enum "Gen. Journal Document Type"; PurchaseLine: Record "Purchase Line"; Date: Date)
    var
        PrepaymentVATBase: Decimal;
        PrepaymentVATAmount: Decimal;
        Amount: Decimal;
        VATAmount: Decimal;
    begin
        PrepaymentVATBase := GetPrepaymentVATBaseOnDate(PurchaseLine, Date);
        PrepaymentVATAmount := GetPrepaymentVATAmountOnDate(PurchaseLine, Date);
        Amount := GetAmountOnDate(PurchaseLine, Date);
        VATAmount := GetVATAmountOnDate(PurchaseLine, Date);

        VerifyVATEntry(
          DocumentNo, DocumentType, PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group", -PrepaymentVATBase,
          -PrepaymentVATAmount, true);
        VerifyVATEntry(
          DocumentNo, DocumentType, PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group", Amount, VATAmount, true);
        VerifyGSTPurchaseEntry(
          DocumentNo, DocumentType, PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group", -PrepaymentVATBase,
          -PrepaymentVATAmount, true);
        VerifyGSTPurchaseEntry(
          DocumentNo, DocumentType, PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group", Amount, VATAmount, true);
    end;

    local procedure VerifyPrepaymentGLEntries(DocumentNo: Code[10]; DocumentType: Enum "Gen. Journal Document Type"; PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; Invoice: Boolean)
    begin
        VerifyPrepaymentGLEntriesOnDate(DocumentNo, DocumentType, PurchaseHeader, PurchaseLine, Invoice, WorkDate());
    end;

    local procedure VerifyPrepaymentGLEntriesMultipleLinesDifferentRates(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; PurchaseLine2: Record "Purchase Line"; Invoice: Boolean)
    var
        Sign: Integer;
        PrepaymentAmount: Decimal;
        PrepaymentVATAmount: Decimal;
        PrepaymentAmount2: Decimal;
        PrepaymentVATAmount2: Decimal;
    begin
        // Invert Amounts for Credit Memo
        if Invoice then
            Sign := 1
        else
            Sign := -1;

        PrepaymentAmount := GetPrepaymentAmountOnDate(PurchaseLine, WorkDate());
        PrepaymentVATAmount := GetPrepaymentVATAmountOnDate(PurchaseLine, WorkDate());
        PrepaymentAmount2 := GetPrepaymentAmountOnDate(PurchaseLine2, WorkDate());
        PrepaymentVATAmount2 := GetPrepaymentVATAmountOnDate(PurchaseLine2, WorkDate());

        VerifyGLEntry(
          DocumentNo, DocumentType,
          GetPurchasePrepAccountNo(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group"),
          Sign * PrepaymentAmount, Sign * PrepaymentVATAmount, false);
        VerifyGLEntry(
          DocumentNo, DocumentType,
          GetVATAccountNo(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group"),
          Sign * PrepaymentVATAmount, 0, false);
        VerifyGLEntry(
          DocumentNo, DocumentType,
          GetPurchasePrepAccountNo(PurchaseLine2."Gen. Bus. Posting Group", PurchaseLine2."Gen. Prod. Posting Group"),
          Sign * PrepaymentAmount2, Sign * PrepaymentVATAmount2, false);
        VerifyGLEntry(
          DocumentNo, DocumentType,
          GetVATAccountNo(PurchaseLine2."VAT Bus. Posting Group", PurchaseLine2."VAT Prod. Posting Group"),
          Sign * PrepaymentVATAmount2, 0, false);

        VerifyGLEntry(
          DocumentNo, DocumentType, GetPayablesAccountNo(PurchaseHeader."Vendor Posting Group"),
          -Sign * (PrepaymentAmount + PrepaymentAmount2 + PrepaymentVATAmount + PrepaymentVATAmount2), 0, false);
    end;

    local procedure VerifyPrepaymentGLEntriesOnDate(DocumentNo: Code[10]; DocumentType: Enum "Gen. Journal Document Type"; PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; Invoice: Boolean; Date: Date)
    var
        Sign: Integer;
        PrepaymentAmount: Decimal;
        PrepaymentVATAmount: Decimal;
    begin
        // Invert Amounts for Credit Memo
        if Invoice then
            Sign := 1
        else
            Sign := -1;
        PrepaymentAmount := GetPrepaymentAmountOnDate(PurchaseLine, Date);
        PrepaymentVATAmount := GetPrepaymentVATAmountOnDate(PurchaseLine, Date);

        VerifyGLEntry(
          DocumentNo, DocumentType,
          GetPurchasePrepAccountNo(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group"),
          Sign * PrepaymentAmount, Sign * PrepaymentVATAmount, false);
        VerifyGLEntry(
          DocumentNo, DocumentType,
          GetVATAccountNo(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group"),
          Sign * PrepaymentVATAmount, 0, false);
        VerifyGLEntry(
          DocumentNo, DocumentType, GetPayablesAccountNo(PurchaseHeader."Vendor Posting Group"),
          -Sign * (PrepaymentAmount + PrepaymentVATAmount), 0, false);
    end;

    local procedure VerifyPrepaymentVATEntries(DocumentNo: Code[10]; DocumentType: Enum "Gen. Journal Document Type"; PurchaseLine: Record "Purchase Line"; Invoice: Boolean)
    begin
        VerifyPrepaymentVATEntriesOnDate(DocumentNo, DocumentType, PurchaseLine, Invoice, WorkDate());
    end;

    local procedure VerifyPrepaymentVATEntriesMultipleLinesDifferentRates(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; PurchaseLine: Record "Purchase Line"; PurchaseLine2: Record "Purchase Line"; Invoice: Boolean)
    var
        Sign: Integer;
        PrepaymentVATBase: Decimal;
        PrepaymentVATAmount: Decimal;
        PrepaymentVATBase2: Decimal;
        PrepaymentVATAmount2: Decimal;
    begin
        // Invert Amounts for Credit Memo
        if Invoice then
            Sign := 1
        else
            Sign := -1;

        PrepaymentVATBase := GetPrepaymentVATBaseOnDate(PurchaseLine, WorkDate());
        PrepaymentVATAmount := GetPrepaymentVATAmountOnDate(PurchaseLine, WorkDate());
        PrepaymentVATBase2 := GetPrepaymentVATBaseOnDate(PurchaseLine2, WorkDate());
        PrepaymentVATAmount2 := GetPrepaymentVATAmountOnDate(PurchaseLine2, WorkDate());

        VerifyVATEntry(
          DocumentNo, DocumentType, PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group",
          Sign * PrepaymentVATBase, Sign * PrepaymentVATAmount, false);
        VerifyVATEntry(
          DocumentNo, DocumentType, PurchaseLine2."VAT Bus. Posting Group", PurchaseLine2."VAT Prod. Posting Group",
          Sign * PrepaymentVATBase2, Sign * PrepaymentVATAmount2, false);

        VerifyGSTPurchaseEntry(
          DocumentNo, DocumentType, PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group",
          Sign * PrepaymentVATBase, Sign * PrepaymentVATAmount, false);
        VerifyGSTPurchaseEntry(
          DocumentNo, DocumentType, PurchaseLine2."VAT Bus. Posting Group", PurchaseLine2."VAT Prod. Posting Group",
          Sign * PrepaymentVATBase2, Sign * PrepaymentVATAmount2, false);
    end;

    local procedure VerifyPrepaymentVATEntriesOnDate(DocumentNo: Code[10]; DocumentType: Enum "Gen. Journal Document Type"; PurchaseLine: Record "Purchase Line"; Invoice: Boolean; Date: Date)
    var
        Sign: Integer;
        PrepaymentVATBase: Decimal;
        PrepaymentVATAmount: Decimal;
    begin
        // Invert Amounts for Credit Memo
        if Invoice then
            Sign := 1
        else
            Sign := -1;

        PrepaymentVATBase := GetPrepaymentVATBaseOnDate(PurchaseLine, Date);
        PrepaymentVATAmount := GetPrepaymentVATAmountOnDate(PurchaseLine, Date);

        VerifyVATEntry(
          DocumentNo, DocumentType, PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group",
          Sign * PrepaymentVATBase, Sign * PrepaymentVATAmount, false);
        VerifyGSTPurchaseEntry(
          DocumentNo, DocumentType, PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group",
          Sign * PrepaymentVATBase, Sign * PrepaymentVATAmount, false);
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
    procedure ConfirmHandler(Message: Text[1024]; var Response: Boolean)
    begin
        Response := true;
    end;

    local procedure GetAmountRoundingPrecision(): Decimal
    begin
        exit(LibraryERM.GetAmountRoundingPrecision() + 0.01);
    end;
}

