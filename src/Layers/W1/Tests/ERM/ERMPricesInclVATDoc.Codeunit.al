codeunit 134046 "ERM Prices Incl VAT Doc"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Prices Including VAT]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        AmountError: Label '%1 must be %2 in %3.';
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryService: Codeunit "Library - Service";
        IsInitialized: Boolean;
        AmtErrorMessage: Label 'The %1 must be %2 in %3.';

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoicePriceInclVAT()
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        VATAmount: Decimal;
        Amount: Decimal;
    begin
        // Verify that correct VAT Amount calculated after Posting Sales Invoice with Prices Including VAT.

        // Setup: Find VAT Posting Setup, Create Sales Invoice. Compute VAT Amount.
        Initialize();
        FindVATPostingSetup(VATPostingSetup);
        CreateSalesDocument(SalesHeader, Amount, SalesHeader."Document Type"::Invoice, CreateCustomer(), true);
        VATAmount :=
          Round(
            CalculateVATAmount(
              SalesHeader."No.", SalesHeader."Document Type"::Invoice, VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %")));

        // Exercise: Post Sales Document.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify GL and VAT Entries after Posting Sales Credit Memo.
        VerifyGLAndVATEntry(DocumentNo, VATPostingSetup."Sales VAT Account", SalesHeader."Document Type"::Invoice, -VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoPriceExclVAT()
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
        VATAmount: Decimal;
        Amount: Decimal;
    begin
        // Verify that correct VAT Amount calculated after Posting Sales Credit Memo with Prices Excluding VAT.

        // Setup: Find VAT Posting Setup, Create Sales Credit Memo. Compute VAT Amount.
        Initialize();
        FindVATPostingSetup(VATPostingSetup);
        CreateSalesDocument(SalesHeader, Amount, SalesHeader."Document Type"::"Credit Memo", CreateCustomer(), false);
        VATAmount :=
          Round(CalculateVATAmount(SalesHeader."No.", SalesHeader."Document Type"::"Credit Memo", VATPostingSetup."VAT %" / 100));

        // Exercise: Post Sales Document.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify GL and VAT Entries after Posting Sales Credit Memo.
        VerifyGLAndVATEntry(DocumentNo, VATPostingSetup."Sales VAT Account", SalesHeader."Document Type"::"Credit Memo", VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderPriceInclVAT()
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Amount: Decimal;
        PurchaseInvoiceNo: Code[20];
    begin
        // VAT Amount in GL Entry after Posting Purchase Order for Prices Including VAT.

        // Create and Post Purchase order and Calculate VAT Amount.
        Initialize();
        PurchaseInvoiceNo := PurchasePricesIncludingVAT(PurchaseLine, PurchaseLine."Document Type"::Order, Amount);

        // Verify: Verify GL Entry VAT Amount.
        VATPostingSetup.Get(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        VerifyGLEntry(PurchaseInvoiceNo, VATPostingSetup."Purchase VAT Account", PurchaseLine."Document Type"::Invoice, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoPriceInclVAT()
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseCreditMemoNo: Code[20];
        Amount: Decimal;
    begin
        // Verify VAT Amount in GL Entry after Posting Purchase Credit Memo for Prices Including VAT.

        // Create and Post Purchase Credit Memo and Calculate VAT Amount.
        Initialize();
        PurchaseCreditMemoNo := PurchasePricesIncludingVAT(PurchaseLine, PurchaseLine."Document Type"::"Credit Memo", Amount);

        // Verify: Verify GL Entry VAT Amount.
        VATPostingSetup.Get(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        VerifyGLEntry(PurchaseCreditMemoNo, VATPostingSetup."Purchase VAT Account", PurchaseLine."Document Type"::"Credit Memo", -Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithNoVAT()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Check No VAT Amount in VAT Entry, GL Entry after Posting Sales Invoice with same Positive and Negative Quantity.
        Initialize();
        SalesDocumentNoVAT(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithNoVAT()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Check No VAT Amount in VAT Entry, GL Entry after Posting Sales Credit Memo with same Positive and Negative Quantity.
        Initialize();
        SalesDocumentNoVAT(SalesHeader."Document Type"::"Credit Memo");
    end;

    local procedure SalesDocumentNoVAT(DocumentType: Enum "Sales Document Type")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        GenProdPostingGroup: Code[20];
        PostedDocumentNo: Code[20];
    begin
        // Setup: Create Sales Document with positive and negative quantities.
        CreateSalesDocumentEqualQty(SalesHeader, GenProdPostingGroup, DocumentType);

        // Exercise: Post Sales Document.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify that Amount is Zero in GL and VAT Entries after Posting Sales Document.
        GeneralPostingSetup.Get(SalesHeader."Gen. Bus. Posting Group", GenProdPostingGroup);
        VerifyGLAndVATEntry(
          PostedDocumentNo, GetSalesGenPostGLAccNoByDocType(DocumentType, GeneralPostingSetup), DocumentType, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithNoVAT()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check no VAT Amount in VAT Entry, GL Entry after posting Purchase Invoice with Positive and Negative Quantities.
        Initialize();
        PurchaseDocumentNoVAT(PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoWithNoVAT()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check no VAT Amount in VAT Entry, GL Entry after posting Purchase Credit Memo with Positive and Negative Quantities.
        Initialize();
        PurchaseDocumentNoVAT(PurchaseHeader."Document Type"::"Credit Memo");
    end;

    local procedure PurchaseDocumentNoVAT(DocumentType: Enum "Purchase Document Type")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PostedDocumentNo: Code[20];
        GenProdPostingGroup: Code[20];
    begin
        // Create and Post Purchase Document with positive and negative quantities.
        CreatePurchaseDocumentEqualQty(PurchaseHeader, GenProdPostingGroup, DocumentType);

        // Exercise: Post Purchase Document.
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify that Amount is zero in GL Entry, VAT Entry after posting Purchase Document.
        GeneralPostingSetup.Get(PurchaseHeader."Gen. Bus. Posting Group", GenProdPostingGroup);
        VerifyGLAndVATEntry(
          PostedDocumentNo, GetPurchGenPostGLAccNoByDocType(DocumentType, GeneralPostingSetup), DocumentType, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATAmountLine: Record "VAT Amount Line";
        InvoiceDiscAmount: Decimal;
        QtyType: Option General,Invoicing,Shipping;
    begin
        // Verify Invoice Discount Amount on Statistics page for Purchase Order.

        // Setup: Modify Purchase Payables Setup and create Purchase order and update purchase Line for Invoice Quantity.
        Initialize();
        LibraryPurchase.SetCalcInvDiscount(true);
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, CreateInvoiceDiscForVendor(CreateVendor()), true);
        UpdatePartialQtyRcveAndInvoice(PurchaseLine);
        InvoiceDiscAmount :=
          Round(PurchaseLine."Qty. to Invoice" * PurchaseLine."Direct Unit Cost" * PurchaseHeader."Invoice Discount Value" / 100);

        // Exercise: Calculate VAT Amount Line for Invoice Discount Amount.
        PurchaseLine.CalcVATAmountLines(QtyType::Invoicing, PurchaseHeader, PurchaseLine, VATAmountLine);

        // Verify: Verify Invoice Discount Amount on Statistics page for Purchase Order.
        VerifyInvoiceDiscountAmount(InvoiceDiscAmount, VATAmountLine."Invoice Discount Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialPurchaseInvoiceDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATAmountLine: Record "VAT Amount Line";
        GeneralInvDiscAmount: Decimal;
        InvoiceDiscAmount: Decimal;
        QtyType: Option General,Invoicing,Shipping;
    begin
        // Verify Invoice Discount Amount on Statistics page for Purchase Order with different options.

        // Setup: Create and Post Purchase order and update purchase Line for Remaining quantity.
        Initialize();
        LibraryPurchase.SetCalcInvDiscount(true);
        CreateAndPostPurchasePartQty(PurchaseHeader, PurchaseLine);
        PurchaseLine.Get(PurchaseHeader."Document Type", PurchaseHeader."No.", PurchaseLine."Line No.");
        GeneralInvDiscAmount := Round(PurchaseLine."Direct Unit Cost" * PurchaseHeader."Invoice Discount Value" / 100);
        InvoiceDiscAmount :=
          Round(PurchaseLine."Qty. to Invoice" * PurchaseLine."Direct Unit Cost" * PurchaseHeader."Invoice Discount Value" / 100);

        // Exercise: Calculate VAT Amount Line for Invoice Discount Amount with different options.
        PurchaseLine.CalcVATAmountLines(QtyType::General, PurchaseHeader, PurchaseLine, VATAmountLine);
        PurchaseLine.CalcVATAmountLines(QtyType::Invoicing, PurchaseHeader, PurchaseLine, VATAmountLine);

        // Verify: Verify Invoice Discount Amount on Statistics page for Purchase Order on different options.
        VerifyInvoiceDiscountAmount(GeneralInvDiscAmount, VATAmountLine."Invoice Discount Amount");
        VerifyInvoiceDiscountAmount(InvoiceDiscAmount, VATAmountLine."Invoice Discount Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedPurchaseInvoiceDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATAmountLine: Record "VAT Amount Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        GeneralInvDiscAmount: Decimal;
    begin
        // Verify Invoice Discount Amount on Statistics page for Posted Purchase Invoice.

        // Setup: Create and Post Purchase order and update purchase Line for Remaining quantity.
        Initialize();
        LibraryPurchase.SetCalcInvDiscount(true);
        CreateAndPostPurchasePartQty(PurchaseHeader, PurchaseLine);
        PostPurchaseOrder(PurchaseHeader);  // Post Purchase Order for Remaining quantity.

        // Exercise: Find Posted Purchase Invoice and Calculate VAT Amount Line for Invoice Discount Amount.
        FindPostedPurchaseInvoice(PurchInvHeader, PurchInvLine, PurchaseHeader."No.");
        PurchInvLine.CalcVATAmountLines(PurchInvHeader, VATAmountLine);
        GeneralInvDiscAmount :=
          Round(PurchInvLine.Quantity * PurchInvLine."Direct Unit Cost" * PurchaseHeader."Invoice Discount Value" / 100);

        // Verify: Verify Invoice Discount Amount on Statistics page for Posted Purchase Invoice.
        VerifyInvoiceDiscountAmount(GeneralInvDiscAmount, VATAmountLine."Invoice Discount Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceVATBaseAmount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATAmountLine: Record "VAT Amount Line";
        QtyType: Option General,Invoicing,Shipping;
        VATBaseAmount: Decimal;
        Amount: Decimal;
        LineAmount: Decimal;
    begin
        // Verify VAT Base Amount on Statistics page for Sales Invoice.

        // Setup: Modify General Ledger Setup,Find VAT Posting Setup and create Sales Invoice.
        Initialize();
        LibraryPmtDiscSetup.ClearAdjustPmtDiscInVATSetup();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        FindVATPostingSetup(VATPostingSetup);
        CreateSalesDocument(SalesHeader, Amount, SalesHeader."Document Type"::Invoice, CreateCustomer(), true);

        // Exercise: Calculate VAT Base Amount.
        SalesLine.CalcVATAmountLines(QtyType::General, SalesHeader, SalesLine, VATAmountLine);
        VATBaseAmount :=
          CalculateSalesVATBaseAmount(LineAmount, SalesHeader."No.", SalesHeader."Document Type"::Invoice,
            VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"));

        // Verify: Verify VAT Base Amount on Statistics page for Sales Invoice.
        VerifyInvoiceDiscountAmount(VATBaseAmount, VATAmountLine."VAT Base");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceLineDiscAmount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATAmountLine: Record "VAT Amount Line";
        QtyType: Option General,Invoicing,Shipping;
        VATBaseAmount: Decimal;
        Amount: Decimal;
        LineAmount: Decimal;
    begin
        // Verify VAT Base Amount on Statistics page for Sales Invoice after changing Invoice Discount Manually.

        // Setup: Modify General Ledger Setup,Find VAT Posting Setup and create Sales Invoice.
        Initialize();
        LibraryPmtDiscSetup.ClearAdjustPmtDiscInVATSetup();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateSalesDocument(SalesHeader, Amount, SalesHeader."Document Type"::Invoice, CreateCustomer(), true);

        // Exercise: Calculate VAT Base Amount after Validating Invoice Discount Amount using RANDOM values on VAT Amount Line.
        SalesLine.CalcVATAmountLines(QtyType::General, SalesHeader, SalesLine, VATAmountLine);
        UpdateVATAmountLine(VATAmountLine);
        CalculateSalesVATBaseAmount(LineAmount, SalesHeader."No.", SalesHeader."Document Type"::Invoice,
          VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"));
        VATBaseAmount := LineAmount - VATAmountLine."Invoice Discount Amount";

        // Verify: Verify VAT Base Amount on Statistics page for Sales Invoice.
        VerifyInvoiceDiscountAmount(VATBaseAmount, VATAmountLine."VAT Base");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceVATBaseAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATAmountLine: Record "VAT Amount Line";
        QtyType: Option General,Invoicing,Shipping;
        VATBaseAmount: Decimal;
        Amount: Decimal;
    begin
        // Verify VAT Base Amount on Statistics page for Purchase Invoice.

        // Setup: Modify General Ledger Setup,Find VAT Posting Setup and create Sales Invoice.
        Initialize();
        LibraryPmtDiscSetup.ClearAdjustPmtDiscInVATSetup();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        FindVATPostingSetup(VATPostingSetup);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, CreateVendor(), true);

        // Exercise: Calculate VAT Base Amount.
        PurchaseLine.CalcVATAmountLines(QtyType::General, PurchaseHeader, PurchaseLine, VATAmountLine);
        VATBaseAmount :=
          CalculatePurchaseVATBaseAmount(Amount, PurchaseHeader."No.", PurchaseHeader."Document Type"::Invoice,
            VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"));

        // Verify: Verify VAT Base Amount on Statistics page for Sales Invoice.
        VerifyInvoiceDiscountAmount(VATBaseAmount, VATAmountLine."VAT Base");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceLineDiscAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATAmountLine: Record "VAT Amount Line";
        QtyType: Option General,Invoicing,Shipping;
        VATBaseAmount: Decimal;
        Amount: Decimal;
    begin
        // Verify VAT Base Amount on Statistics page for Purchase Invoice after changing Invoice Discount Manually.

        // Setup: Modify General Ledger Setup,Find VAT Posting Setup and create Sales Invoice.
        Initialize();
        LibraryPmtDiscSetup.ClearAdjustPmtDiscInVATSetup();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, CreateVendor(), true);

        // Exercise: Calculate VAT Base Amount after Validating Invoice Discount Amount using RANDOM values on VAT Amount Line.
        PurchaseLine.CalcVATAmountLines(QtyType::General, PurchaseHeader, PurchaseLine, VATAmountLine);
        UpdateVATAmountLine(VATAmountLine);
        CalculatePurchaseVATBaseAmount(Amount, PurchaseHeader."No.", PurchaseHeader."Document Type"::Invoice,
          VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"));
        VATBaseAmount := Amount - VATAmountLine."Invoice Discount Amount";

        // Verify: Verify VAT Base Amount on Statistics page for Sales Invoice.
        VerifyInvoiceDiscountAmount(VATBaseAmount, VATAmountLine."VAT Base");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PricesExclVATPostSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VATAmount: Decimal;
        Amount: Decimal;
        AmountIncludingVAT: Decimal;
        PostedDocumentNo: Code[20];
    begin
        // Verify Amount Including VAT,General Ledger Entry and VAT Entry after Posting Sales Order.

        // Setup: Create Sales Order and Calculate Amount Including VAT.
        Initialize();
        SalesDocumentPricesExclVAT(SalesHeader, VATPostingSetup, VATAmount, Amount, SalesHeader."Document Type"::Order);
        AmountIncludingVAT := Amount + VATAmount;

        // Exercise: Post Sales Document.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Amount Including VAT,General Ledger Entry and VAT Entry.
        VerifySalesOrderAmountInclVAT(PostedDocumentNo, AmountIncludingVAT);
        VerifyGLAndVATEntry(PostedDocumentNo, VATPostingSetup."Sales VAT Account", SalesHeader."Document Type"::Invoice, -VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PricesExclVATPostSalesCM()
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        PostedDocumentNo: Code[20];
        VATAmount: Decimal;
        Amount: Decimal;
        AmountIncludingVAT: Decimal;
    begin
        // Verify Amount Including VAT,General Ledger Entry and VAT Entry after Posting Sales Order.

        // Setup: Create Sales Order and Calculate Amount Including VAT.
        Initialize();
        SalesDocumentPricesExclVAT(SalesHeader, VATPostingSetup, VATAmount, Amount, SalesHeader."Document Type"::"Credit Memo");
        AmountIncludingVAT := Amount + VATAmount;

        // Exercise: Post Sales Document.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Amount Including VAT,General Ledger Entry and VAT Entry.
        VerifySalesCMAmountInclVAT(PostedDocumentNo, AmountIncludingVAT);
        VerifyGLAndVATEntry(PostedDocumentNo, VATPostingSetup."Sales VAT Account", SalesHeader."Document Type"::"Credit Memo", VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PricesExclVATSalesOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify VAT Amount on Statistics page for Sales Order.
        Initialize();
        SalesPricesExclVAT(SalesHeader."Document Type"::Order)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PricesExclVATSalesCM()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify VAT Amount on Statistics page for Sales Credit Memo.
        Initialize();
        SalesPricesExclVAT(SalesHeader."Document Type"::"Credit Memo")
    end;

    local procedure SalesPricesExclVAT(DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATAmount: Decimal;
        QtyType: Option General;
        Amount: Decimal;
    begin
        // Verify VAT Amount on Statistics page for Sales Credit Memo.

        // Setup.
        Initialize();
        SalesDocumentPricesExclVAT(SalesHeader, VATPostingSetup, VATAmount, Amount, DocumentType);

        // Exercise: Calculate VAT Base Amount.
        SalesLine.CalcVATAmountLines(QtyType::General, SalesHeader, SalesLine, VATAmountLine);

        // Verify: Verify VAT Amount on Statistics page for Sales Credit Memo.
        VerifyVATAmount(VATAmount, VATAmountLine."VAT Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PricesExclVATPurchOrder()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify VAT Amount on Statistics page for Purchase Order.
        Initialize();
        PurchasePricesExclVAT(PurchaseHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PricesExclVATPurchCM()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify VAT Amount on Statistics page for Purchase Credit Memo.
        Initialize();
        PurchasePricesExclVAT(PurchaseHeader."Document Type"::"Credit Memo");
    end;

    local procedure PurchasePricesExclVAT(DocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATAmountLine: Record "VAT Amount Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATAmount: Decimal;
        QtyType: Option General;
    begin
        // Verify VAT Amount on Statistics page for Purchase Order.

        // Setup.
        PurchDocumentPricesExclVAT(PurchaseHeader, PurchaseLine, VATAmount, VATPostingSetup, DocumentType);

        // Exercise: Calculate VAT Base Amount.
        PurchaseLine.CalcVATAmountLines(QtyType::General, PurchaseHeader, PurchaseLine, VATAmountLine);

        // Verify: Verify VAT Amount on Statistics page for Purchase Order.
        VerifyVATAmount(VATAmount, VATAmountLine."VAT Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PricesExclVATPostPurchOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PostedDocumentNo: Code[20];
        VATAmount: Decimal;
        AmountIncludingVAT: Decimal;
    begin
        // Verify Amount Including VAT,General Ledger Entry and VAT Entry after Posting Purchase Credit Memo.

        // Setup: Create Purchase Credit Memo and Calculate Amount Including VAT.
        Initialize();
        PurchDocumentPricesExclVAT(PurchaseHeader, PurchaseLine, VATAmount, VATPostingSetup, PurchaseHeader."Document Type"::Order);
        AmountIncludingVAT :=
          ((PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost") - PurchaseLine."Inv. Discount Amount") + VATAmount;

        // Exercise: Post Purchase Document.
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify Amount Including VAT,General Ledger Entry and VAT Entry.
        VerifyPurchOrderAmountInclVAT(PostedDocumentNo, AmountIncludingVAT);
        VerifyGLAndVATEntry(
          PostedDocumentNo, VATPostingSetup."Purchase VAT Account", PurchaseLine."Document Type"::Invoice, VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PricesExclVATPostPurchCM()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PostedDocumentNo: Code[20];
        VATAmount: Decimal;
        AmountIncludingVAT: Decimal;
    begin
        // Verify Amount Including VAT,General Ledger Entry and VAT Entry after Posting Purchase Credit Memo.

        // Setup: Create Purchase Credit Memo and Calculate Amount Including VAT.
        Initialize();
        PurchDocumentPricesExclVAT(PurchaseHeader, PurchaseLine, VATAmount, VATPostingSetup, PurchaseHeader."Document Type"::"Credit Memo");
        AmountIncludingVAT :=
          ((PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost") - PurchaseLine."Inv. Discount Amount") + VATAmount;

        // Exercise: Post Purchase Document.
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify Amount Including VAT,General Ledger Entry and VAT Entry.
        VerifyPurchCMAmountInclVAT(PostedDocumentNo, AmountIncludingVAT);
        VerifyGLAndVATEntry(
          PostedDocumentNo, VATPostingSetup."Purchase VAT Account", PurchaseLine."Document Type"::"Credit Memo", -VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderInvRounding()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Check VAT Amount on Sales Order with Invoice Rounding Precision.
        Initialize();
        SalesDocumentInvoiceRounding(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoInvRounding()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Check VAT Amount on Sales Credit Memo with Invoice Rounding Precision.
        Initialize();
        SalesDocumentInvoiceRounding(SalesHeader."Document Type"::"Credit Memo");
    end;

    local procedure SalesDocumentInvoiceRounding(DocumentType: Enum "Sales Document Type")
    var
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
        VATPostingSetup: Record "VAT Posting Setup";
        QtyType: Option General,Invoicing,Shipping;
        ExpectedAmountInclVAT: Decimal;
        ActualAmountInclVAT: Decimal;
        VATAmount: Decimal;
        UnitPrice: Decimal;
    begin
        // Setup: Find VAT Posting Setup, Currency and Create Sales Order. Calculate VAT Amount Line.
        UnitPrice := 10 + LibraryRandom.RandDec(10, 2);
        FindVATPostingSetup(VATPostingSetup);
        LibraryERM.FindCurrency(Currency);
        VATAmount := CreateSingleLineSalesDoc(SalesHeader, SalesLine, Currency, UnitPrice, DocumentType);
        SalesLine.CalcVATAmountLines(QtyType::Invoicing, SalesHeader, SalesLine, VATAmountLine);
        ExpectedAmountInclVAT :=
          Round(SalesLine.Quantity * UnitPrice, Currency."Invoice Rounding Precision", Currency.InvoiceRoundingDirection());

        // Exercise: Release Sales Document.
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        SalesHeader.CalcFields("Amount Including VAT");
        ActualAmountInclVAT := Round(SalesHeader."Amount Including VAT", Currency."Invoice Rounding Precision");

        // Verify: Verify Amount Including VAT on Released Sales Header and VAT Amount Line.
        Assert.AreEqual(
          ExpectedAmountInclVAT, ActualAmountInclVAT, StrSubstNo(AmountError, SalesHeader.FieldCaption("Amount Including VAT"),
            ExpectedAmountInclVAT, SalesHeader.TableCaption()));
        VerifyVATAmountLine(VATAmountLine, VATPostingSetup."VAT %", SalesLine."Line Amount" - VATAmount, VATAmount);

        // Tear Down: Delete Sales Header.
        SalesHeader.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderNoInvRounding()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Check VAT Amount on Sales Order with no Invoice Rounding Precision.
        Initialize();
        SalesDocumentNoInvoiceRounding(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoNoInvRounding()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Check VAT Amount on Sales Credit Memo with no Invoice Rounding Precision.
        Initialize();
        SalesDocumentNoInvoiceRounding(SalesHeader."Document Type"::"Credit Memo");
    end;

    local procedure SalesDocumentNoInvoiceRounding(DocumentType: Enum "Sales Document Type")
    var
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
        VATPostingSetup: Record "VAT Posting Setup";
        QtyType: Option General,Invoicing,Shipping;
        AmountIncludingVAT: Decimal;
        VATAmount: Decimal;
        UnitPrice: Decimal;
    begin
        // Setup: Find VAT Posting Setup, Currency and Create Sales Document. Take Random Unit Price for Sales Line.
        UnitPrice := 10 + LibraryRandom.RandDec(10, 2);
        FindVATPostingSetup(VATPostingSetup);
        LibraryERM.FindCurrency(Currency);
        CreateSingleLineSalesDoc(SalesHeader, SalesLine, Currency, UnitPrice, DocumentType);

        // Exercise: Update Random Unit Price on Sales Line, Release the Document and Calculate VAT Amount.
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(10));
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        SalesLine.CalcVATAmountLines(QtyType::Invoicing, SalesHeader, SalesLine, VATAmountLine);
        SalesHeader.CalcFields("Amount Including VAT");
        AmountIncludingVAT := SalesLine.Quantity * SalesLine."Unit Price";
        VATAmount := Round(AmountIncludingVAT * VATPostingSetup."VAT %" / (100 + VATPostingSetup."VAT %"));

        // Verify: Verify Amount Including VAT on Released Sales Header and VAT Amount Line.
        Assert.AreEqual(
          AmountIncludingVAT, SalesHeader."Amount Including VAT", StrSubstNo(AmountError, SalesHeader.FieldCaption("Amount Including VAT"),
            AmountIncludingVAT, SalesHeader.TableCaption()));
        VerifyVATAmountLine(VATAmountLine, VATPostingSetup."VAT %", Round(AmountIncludingVAT - VATAmount), VATAmount);

        // Tear Down: Delete Sales Header.
        SalesHeader.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderInvRounding()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check VAT Amount on Purchase Order with Invoice Rounding Precision.
        Initialize();
        PurchDocumentInvoiceRounding(PurchaseHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCreditMemoInvRounding()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check VAT Amount on Purchase Credit Memo with Invoice Rounding Precision.
        Initialize();
        PurchDocumentInvoiceRounding(PurchaseHeader."Document Type"::"Credit Memo");
    end;

    local procedure PurchDocumentInvoiceRounding(DocumentType: Enum "Purchase Document Type")
    var
        Currency: Record Currency;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATAmountLine: Record "VAT Amount Line";
        QtyType: Option General,Invoicing,Shipping;
        ActualAmtInclVAT: Decimal;
        ExpectedAmtInclVAT: Decimal;
        VATAmount: Decimal;
        DirectUnitCost: Decimal;
    begin
        // Setup: Find Currency and Create Purchase Document with Random Direct Unit Cost. Calculate VAT Amount Line.
        DirectUnitCost := 10 + LibraryRandom.RandDec(10, 2);
        LibraryERM.FindCurrency(Currency);
        VATAmount := CreateSingleLinePurchaseDoc(PurchaseHeader, PurchaseLine, Currency, DirectUnitCost, DocumentType);
        PurchaseLine.CalcVATAmountLines(QtyType::Invoicing, PurchaseHeader, PurchaseLine, VATAmountLine);
        ExpectedAmtInclVAT :=
          Round(PurchaseLine.Quantity * DirectUnitCost, Currency."Invoice Rounding Precision", Currency.InvoiceRoundingDirection());

        // Exercise: Release Purchase Document.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PurchaseHeader.CalcFields("Amount Including VAT");
        ActualAmtInclVAT := Round(PurchaseHeader."Amount Including VAT", Currency."Invoice Rounding Precision");

        // Verify: Verify Amount Including VAT on Released Purchase Header and VAT Amount Line.
        Assert.AreEqual(
          ExpectedAmtInclVAT, ActualAmtInclVAT, StrSubstNo(AmountError, PurchaseHeader.FieldCaption("Amount Including VAT"),
            ExpectedAmtInclVAT, PurchaseHeader.TableCaption()));
        VerifyVATAmountLine(VATAmountLine, PurchaseLine."VAT %", PurchaseLine."Line Amount" - VATAmount, VATAmount);

        // Tear Down: Delete Purchase Header.
        PurchaseHeader.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderNoInvRounding()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check VAT Amount for Purchase Order without Invoice Rounding Precision.
        Initialize();
        PurchDocumentNoInvoiceRounding(PurchaseHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCreditMemoNoInvRounding()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check VAT Amount on Purchase Credit Memo without Invoice Rounding Precision.
        Initialize();
        PurchDocumentNoInvoiceRounding(PurchaseHeader."Document Type"::"Credit Memo");
    end;

    local procedure PurchDocumentNoInvoiceRounding(DocumentType: Enum "Purchase Document Type")
    var
        Currency: Record Currency;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATAmountLine: Record "VAT Amount Line";
        QtyType: Option General,Invoicing,Shipping;
        AmountIncludingVAT: Decimal;
        VATAmount: Decimal;
        DirectUnitCost: Decimal;
    begin
        // Setup: Find Currency and Create Purchase Document. Take Random Values for Direct Unit Cost.
        DirectUnitCost := 10 + LibraryRandom.RandDec(10, 2);
        LibraryERM.FindCurrency(Currency);
        VATAmount := CreateSingleLinePurchaseDoc(PurchaseHeader, PurchaseLine, Currency, DirectUnitCost, DocumentType);

        // Exercise: Update Random Direct Unit Cost on Purchase Line. Calculate VAT Amount Line.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(10));
        PurchaseLine.Modify(true);
        PurchaseLine.CalcVATAmountLines(QtyType::Invoicing, PurchaseHeader, PurchaseLine, VATAmountLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PurchaseHeader.CalcFields("Amount Including VAT");
        AmountIncludingVAT := PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost";
        VATAmount := Round(AmountIncludingVAT * PurchaseLine."VAT %" / (100 + PurchaseLine."VAT %"));

        // Verify: Verify Amount Including VAT on Released Purchase Header and VAT Amount Line.
        Assert.AreEqual(
          AmountIncludingVAT, PurchaseHeader."Amount Including VAT", StrSubstNo(AmountError,
            PurchaseHeader.FieldCaption("Amount Including VAT"), AmountIncludingVAT, PurchaseHeader.TableCaption()));
        VerifyVATAmountLine(VATAmountLine, PurchaseLine."VAT %", Round(AmountIncludingVAT - VATAmount), VATAmount);

        // Tear Down: Delete Purchase Header.
        PurchaseHeader.Delete(true);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure SalesRetOrdStatisticsVATAmount()
    var
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // Verify Total Incl. VAT of Sales Return Order on Sales Invoice Statistics page.

        // Setup: Create Sales Return Order with Random Quantity and Unit Price.
        Initialize();
        LibraryERM.FindCurrency(Currency);
        CreateSingleLineSalesDoc(
          SalesHeader, SalesLine, Currency, LibraryRandom.RandInt(10), SalesHeader."Document Type"::"Return Order");  // Random value for Unit Price.
        LibraryVariableStorage.Enqueue(SalesLine."Amount Including VAT"); // Enqueue value for SalesOrderStatisticsModalPageHandler.
        OpenSalesRetOrdPage(SalesReturnOrder, SalesHeader."No.");

        // Exercise: Open Sales Order Statistics page.
        SalesReturnOrder.Statistics.Invoke();

        // Verify: Verify Total Incl. VAT of Sales Return Order on Sales Invoice Statistics page, Verification done in SalesOrderStatisticsModalPageHandler.
    end;
#endif
    [HandlerFunctions('SalesOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure SalesRetOrdStatisticsVATAmountNM()
    var
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // Verify Total Incl. VAT of Sales Return Order on Sales Invoice Statistics page.

        // Setup: Create Sales Return Order with Random Quantity and Unit Price.
        Initialize();
        LibraryERM.FindCurrency(Currency);
        CreateSingleLineSalesDoc(
          SalesHeader, SalesLine, Currency, LibraryRandom.RandInt(10), SalesHeader."Document Type"::"Return Order");  // Random value for Unit Price.
        LibraryVariableStorage.Enqueue(SalesLine."Amount Including VAT"); // Enqueue value for SalesOrderStatisticsPageHandler.
        OpenSalesRetOrdPage(SalesReturnOrder, SalesHeader."No.");

        // Exercise: Open Sales Order Statistics page.
        SalesReturnOrder.SalesOrderStatistics.Invoke();

        // Verify: Verify Total Incl. VAT of Sales Return Order on Sales Invoice Statistics page, Verification done in SalesOrderStatisticsPageHandler.
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesHandler')]
    [Scope('OnPrem')]
    procedure SalesRetOrdApplyCustomerEntriesBal()
    var
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // Verify Total Incl. VAT of Sales Return Order with Apply Customer Entries Balance.

        // Setup: Create Sales Return Order with Random Quantity and Unit Price.
        Initialize();
        LibraryERM.FindCurrency(Currency);
        CreateSingleLineSalesDoc(
          SalesHeader, SalesLine, Currency, LibraryRandom.RandInt(10), SalesHeader."Document Type"::"Return Order");  // Random value for Unit Price.
        LibraryVariableStorage.Enqueue(-SalesLine."Amount Including VAT"); // Enqueue value for SalesOrderStatisticsHandler.
        OpenSalesRetOrdPage(SalesReturnOrder, SalesHeader."No.");

        // Exercise: Open Apply Customer Entries page.
        SalesReturnOrder."Apply Entries".Invoke();

        // Verify: Verify Amount Including VAT on Apply Customer Entries page, Verification done in SalesOrderStatisticsHandler.
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure PurchRetOrdStatisticsVATAmount()
    var
        Currency: Record Currency;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // Verify Total Incl. VAT of Purchase Return Order on Purchase Invoice Statistics.

        // Setup: Create Purchase Return Order with Random Direct Unit Cost.
        Initialize();
        LibraryERM.FindCurrency(Currency);
        CreateSingleLinePurchaseDoc(
          PurchaseHeader, PurchaseLine, Currency, LibraryRandom.RandInt(10), PurchaseHeader."Document Type"::"Return Order");
        LibraryVariableStorage.Enqueue(PurchaseLine."Amount Including VAT");  // Enqueue value for PurchaseOrderStatisticsHandler.
        OpenPurchRetOrdPage(PurchaseReturnOrder, PurchaseHeader."No.");

        // Exercise: Open Purchase Order Statistics page.
        PurchaseReturnOrder.Statistics.Invoke();

        // Verify: Verify Amount Including VAT on Purchase Order Statistics page.
        // Verification done in handler.
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PurchReturnOrderStatisticsVATAmount()
    var
        Currency: Record Currency;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // Verify Total Incl. VAT of Purchase Return Order on Purchase Invoice Statistics.

        // Setup: Create Purchase Return Order with Random Direct Unit Cost.
        Initialize();
        LibraryERM.FindCurrency(Currency);
        CreateSingleLinePurchaseDoc(
          PurchaseHeader, PurchaseLine, Currency, LibraryRandom.RandInt(10), PurchaseHeader."Document Type"::"Return Order");
        LibraryVariableStorage.Enqueue(PurchaseLine."Amount Including VAT");  // Enqueue value for PurchaseOrderStatisticsPageHandler.
        OpenPurchRetOrdPage(PurchaseReturnOrder, PurchaseHeader."No.");

        // Exercise: Open Purchase Order Statistics page.
        PurchaseReturnOrder.PurchaseOrderStatistics.Invoke();

        // Verify: Verify Amount Including VAT on Purchase Order Statistics page.
        // Verification done in handler.
    end;

    [Test]
    [HandlerFunctions('ApplyVendorEntriesHandler')]
    [Scope('OnPrem')]
    procedure PurchRetOrdApplyVendorEntriesBal()
    var
        Currency: Record Currency;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        // Verify Total Incl. VAT of Purchase Return Order with Apply Vendor Entries Balance.

        // Setup: Create Purchase Return Order with Random Direct Unit Cost.
        Initialize();
        LibraryERM.FindCurrency(Currency);
        CreateSingleLinePurchaseDoc(
          PurchaseHeader, PurchaseLine, Currency, 10 + LibraryRandom.RandInt(10), PurchaseHeader."Document Type"::"Return Order");
        LibraryVariableStorage.Enqueue(PurchaseLine."Amount Including VAT");  // Enqueue value for ApplyVendorEntriesHandler.
        OpenPurchRetOrdPage(PurchaseReturnOrder, PurchaseHeader."No.");

        // Exercise: Open Apply Vendor Entries page.
        PurchaseReturnOrder."Apply Entries".Invoke();  // Using Action119 for Apply Entris Action.

        // Verify: Verify Amount Including VAT on Apply Vendor Entries page.
        // Verification done in handler.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineAmtAfterChangeVATProdPostingGroupInSalesDocWithPricesInclVATAndLineDisc()
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Sales] [Line Discount]
        // [SCENARIO 361066] A line amount is correct when the VAT Product Posting Group changes in the sales document with line discount and "Prices Including VAT" option enabled.

        Initialize();
        CreateSalesInvWithLineDiscAndPricesInclVAT(SalesLine);
        CreateNewVATPostingSetupBasedOnExisting(
          VATPostingSetup, SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group", SalesLine."VAT %");
        SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        SalesLine.TestField("Line Discount Amount",
          Round(
            Round(SalesLine.Quantity * SalesLine."Unit Price") * SalesLine."Line Discount %" / 100));
        SalesLine.TestField("Line Amount",
          Round(SalesLine.Quantity * SalesLine."Unit Price") - SalesLine."Line Discount Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineAmtAfterChangeVATProdPostingGroupInPurchDocWithPricesInclVATAndLineDisc()
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Purchase] [Line Discount]
        // [SCENARIO 361066] A line amount is correct when the VAT Product Posting Group changes in the purchase document with line discount and "Prices Including VAT" option enabled.

        Initialize();
        CreatePurchInvWithLineDiscAndPricesInclVAT(PurchaseLine);
        CreateNewVATPostingSetupBasedOnExisting(
          VATPostingSetup, PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group", PurchaseLine."VAT %");
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.TestField("Line Discount Amount",
          Round(
            Round(PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost") * PurchaseLine."Line Discount %" / 100));
        PurchaseLine.TestField("Line Amount",
          Round(PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost") - PurchaseLine."Line Discount Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineAmtAfterChangeVATProdPostingGroupInServDocWithPricesInclVATAndLineDisc()
    var
        ServiceLine: Record "Service Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Service] [Line Discount]
        // [SCENARIO 361066] A line amount is correct when the VAT Product Posting Group changes in the service document with line discount and "Prices Including VAT" option enabled.

        Initialize();
        CreateServInvWithLineDiscAndPricesInclVAT(ServiceLine);
        CreateNewVATPostingSetupBasedOnExisting(
          VATPostingSetup, ServiceLine."VAT Bus. Posting Group", ServiceLine."VAT Prod. Posting Group", ServiceLine."VAT %");
        ServiceLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        ServiceLine.TestField("Line Discount Amount",
          Round(
            Round(ServiceLine.Quantity * ServiceLine."Unit Price") * ServiceLine."Line Discount %" / 100));
        ServiceLine.TestField("Line Amount",
          Round(ServiceLine.Quantity * ServiceLine."Unit Price") - ServiceLine."Line Discount Amount");
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Prices Incl VAT Doc");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Prices Incl VAT Doc");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        IsInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Prices Incl VAT Doc");
    end;

    local procedure PurchasePricesIncludingVAT(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; var Amount: Decimal) PostedDocumentNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Setup: Create Purchase Document and Calculate VAT Amount.
        Amount := CreatePurchaseDocument(PurchaseHeader, PurchaseLine, DocumentType, CreateVendor(), true);

        // Exercise: Post Purchase Document.
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CalculateVATAmount(DocumentNo: Code[20]; DocumentType: Enum "Sales Document Type"; VATFactor: Decimal) VATAmount: Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.FindSet();
        repeat
            VATAmount += SalesLine."Line Amount" * VATFactor;
        until SalesLine.Next() = 0;
    end;

    local procedure CalculateSalesVATBaseAmount(var LineAmount: Decimal; DocumentNo: Code[20]; DocumentType: Enum "Sales Document Type"; VATFactor: Decimal): Decimal
    var
        SalesLine: Record "Sales Line";
        VATAmount: Decimal;
    begin
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.FindSet();
        repeat
            LineAmount += SalesLine."Line Amount";
            VATAmount += SalesLine."Line Amount" * VATFactor;
        until SalesLine.Next() = 0;
        exit(LineAmount - VATAmount);
    end;

    local procedure CalculatePurchaseVATBaseAmount(var Amount: Decimal; DocumentNo: Code[20]; DocumentType: Enum "Purchase Document Type"; VATFactor: Decimal): Decimal
    var
        PurchaseLine: Record "Purchase Line";
        VATAmount: Decimal;
    begin
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.FindSet();
        repeat
            Amount += PurchaseLine."Line Amount";
            VATAmount += PurchaseLine."Line Amount" * VATFactor;
        until PurchaseLine.Next() = 0;
        exit(Amount - VATAmount);
    end;

    local procedure CreateAndPostPurchasePartQty(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
        // Modify Purchase Payables Setup and create and Post Purchase order and update purchase Line for Remaining quantity.
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, CreateVendor(), true);
        UpdatePartialQtyRcveAndInvoice(PurchaseLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindVATPostingSetup(VATPostingSetup);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateItem(var Item: Record Item)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        // Using Random and value is not important for Test Case.
        FindVATPostingSetup(VATPostingSetup);
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Validate("Last Direct Cost", 100 * LibraryRandom.RandDec(100, 2));
        Item.Validate("Unit Price", Item."Last Direct Cost");
        Item.Modify(true);
    end;

    local procedure CreateInvoiceDiscForCustomer(CustomerNo: Code[20]): Code[20]
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        // Using Random values for calculation and value is not important for Test Case.
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CustomerNo, '', 0);
        CustInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(10, 2));
        CustInvoiceDisc.Modify(true);
        exit(CustomerNo);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; PricesIncludingVAT: Boolean) Amount: Decimal
    var
        Item: Record Item;
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
    begin
        // Using Random values for calculation. Quantity will always be greater than 2 in Partial Scenario.
        CreatePurchaseHeader(PurchaseHeader, DocumentType, VendorNo, '', PricesIncludingVAT);
        CreateItem(Item);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 2 + LibraryRandom.RandInt(10));
        Amount := PurchaseLine.Quantity * Item."Unit Price" * PurchaseLine."VAT %" / 100;
        PurchCalcDiscount.CalculateInvoiceDiscount(PurchaseHeader, PurchaseLine);
    end;

    local procedure CreatePurchaseDocumentEqualQty(var PurchaseHeader: Record "Purchase Header"; var GenProdPostingGroup: Code[20]; DocumentType: Enum "Purchase Document Type")
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
    begin
        // Create Purchase Document with 2 Lines and Random Quantity. Take positive quantity in first line and negative in next line.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendor());
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        CreateItem(Item);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", -PurchaseLine.Quantity);
        GenProdPostingGroup := Item."Gen. Prod. Posting Group";
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; CurrencyCode: Code[10]; PricesIncludingVAT: Boolean)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Prices Including VAT", PricesIncludingVAT);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreateSalesInvWithLineDiscAndPricesInclVAT(var SalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo(), '', true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Line Discount %", LibraryRandom.RandIntInRange(3, 10));
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchInvWithLineDiscAndPricesInclVAT(var PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo(), '', true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Line Discount %", LibraryRandom.RandIntInRange(3, 10));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateServInvWithLineDiscAndPricesInclVAT(var ServiceLine: Record "Service Line")
    var
        ServiceHeader: Record "Service Header";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        ServiceHeader.Validate("Prices Including VAT", true);
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceLine(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Validate("Line Discount %", LibraryRandom.RandIntInRange(3, 10));
        ServiceLine.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var Amount: Decimal; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; PricesIncludingVAT: Boolean)
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        Counter: Integer;
    begin
        // Create Sales Document as per the option selected with Random Quantity. Create multiple Sales Lines.
        CreateSalesHeader(SalesHeader, DocumentType, CustomerNo, '', PricesIncludingVAT);
        CreateItem(Item);
        for Counter := 1 to 1 + LibraryRandom.RandInt(5) do begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
            CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);
            SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
            Amount += (SalesLine.Quantity * SalesLine."Unit Price") - SalesLine."Inv. Discount Amount";
        end;
    end;

    local procedure CreateSalesDocumentEqualQty(var SalesHeader: Record "Sales Header"; var GenProdPostingGroup: Code[20]; DocumentType: Enum "Sales Document Type")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        // Create Sales Document with 2 lines and random quantity. Take positive quantity in first line and negative in next line.
        CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", -SalesLine.Quantity);
        GenProdPostingGroup := Item."Gen. Prod. Posting Group";
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; CurrencyCode: Code[10]; PricesIncludingVAT: Boolean)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Prices Including VAT", PricesIncludingVAT);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSingleLinePurchaseDoc(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Currency: Record Currency; DirectUnitCost: Decimal; DocumentType: Enum "Purchase Document Type") VATAmount: Decimal
    var
        Item: Record Item;
    begin
        // Take Random Quantity for Purchase Line.
        CreateItem(Item);
        CreatePurchaseHeader(PurchaseHeader, DocumentType, CreateVendor(), Currency.Code, true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
        VATAmount :=
          Round(PurchaseLine.Quantity * DirectUnitCost * PurchaseLine."VAT %" / (100 + PurchaseLine."VAT %"),
            Currency."Amount Rounding Precision");
        OnAfterCreateSingleLinePurchaseDoc(PurchaseHeader, PurchaseLine);
    end;

    local procedure CreateSingleLineSalesDoc(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Currency: Record Currency; UnitPrice: Decimal; DocumentType: Enum "Sales Document Type") VATAmount: Decimal
    var
        Item: Record Item;
    begin
        // Create Sales Line with Random Quantity.
        CreateItem(Item);
        CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer(), Currency.Code, true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
        VATAmount :=
          Round(SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."VAT %" / (100 + SalesLine."VAT %"),
            Currency."Amount Rounding Precision");
    end;

    local procedure CreateInvoiceDiscForVendor(VendorNo: Code[20]): Code[20]
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        // Using Random values for calculation and value is not important for Test Case.
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, VendorNo, '', 0);
        VendorInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(10, 2));
        VendorInvoiceDisc.Modify(true);
        exit(VendorNo);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindVATPostingSetup(VATPostingSetup);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateNewVATPostingSetupBasedOnExisting(var VATPostingSetup: Record "VAT Posting Setup"; VATBusPostingGroupCode: Code[20]; VATProdPostingGroupCode: Code[20]; VATRate: Decimal)
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetup.Get(VATBusPostingGroupCode, VATProdPostingGroupCode);
        VATPostingSetup.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        VATPostingSetup."VAT %" := VATRate + 1;
        VATPostingSetup.Insert(true);
    end;

    local procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
    end;

    local procedure GetSalesGenPostGLAccNoByDocType(DocumentType: Enum "Sales Document Type"; GeneralPostingSetup: Record "General Posting Setup"): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        case DocumentType of
            SalesHeader."Document Type"::Invoice:
                exit(GeneralPostingSetup."Sales Account");
            SalesHeader."Document Type"::"Credit Memo":
                exit(GeneralPostingSetup."Sales Credit Memo Account");
        end;
    end;

    local procedure GetPurchGenPostGLAccNoByDocType(DocumentType: Enum "Purchase Document Type"; GeneralPostingSetup: Record "General Posting Setup"): Code[20]
    var
        PurchHeader: Record "Purchase Header";
    begin
        case DocumentType of
            PurchHeader."Document Type"::Invoice:
                exit(GeneralPostingSetup."Purch. Account");
            PurchHeader."Document Type"::"Credit Memo":
                exit(GeneralPostingSetup."Purch. Credit Memo Account");
        end;
    end;

    local procedure OpenSalesRetOrdPage(var SalesReturnOrder: TestPage "Sales Return Order"; No: Code[20])
    begin
        SalesReturnOrder.OpenView();
        SalesReturnOrder.FILTER.SetFilter("No.", No);
    end;

    local procedure OpenPurchRetOrdPage(var PurchaseReturnOrder: TestPage "Purchase Return Order"; No: Code[20])
    begin
        PurchaseReturnOrder.OpenView();
        PurchaseReturnOrder.FILTER.SetFilter("No.", No);
    end;

    [Normal]
    local procedure PostPurchaseOrder(var PurchaseHeader: Record "Purchase Header")
    var
        LibraryUtility: Codeunit "Library - Utility";
    begin
        // Create Random Vendor Invoice No for Remaining Quantity.
        PurchaseHeader.Validate(
          "Vendor Invoice No.",
          LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."), DATABASE::"Purchase Header"));
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure PurchDocumentPricesExclVAT(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var VATAmount: Decimal; var VATPostingSetup: Record "VAT Posting Setup"; DocumentType: Enum "Purchase Document Type")
    var
        VendorNo: Code[20];
    begin
        // Find VAT Posting Setup and Create Vendor and Create Invoice Discount for Vendor.Create Purchase Document
        // and Calculate VAT Amount.
        FindVATPostingSetup(VATPostingSetup);
        VendorNo := CreateVendor();
        CreateInvoiceDiscForVendor(VendorNo);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, DocumentType, VendorNo, false);
        VATAmount := Round(PurchaseVATAmountCalculation(PurchaseHeader."No.", DocumentType, VATPostingSetup."VAT %" / 100));
    end;

    local procedure PurchaseVATAmountCalculation(DocumentNo: Code[20]; DocumentType: Enum "Purchase Document Type"; VATPercent: Decimal) VATAmount: Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindSet();
        repeat
            VATAmount += (PurchaseLine."Line Amount" - PurchaseLine."Inv. Discount Amount") * VATPercent;
        until PurchaseLine.Next() = 0;
    end;

    local procedure SalesDocumentPricesExclVAT(var SalesHeader: Record "Sales Header"; var VATPostingSetup: Record "VAT Posting Setup"; var VATAmount: Decimal; var Amount: Decimal; DocumentType: Enum "Sales Document Type")
    begin
        // Find VAT Postng Setup and Create Customer and Create Invoice Discount for Customer.Create Sales Document
        // and Calculate VAT Amount.
        FindVATPostingSetup(VATPostingSetup);
        CreateSalesDocument(SalesHeader, Amount, DocumentType, CreateInvoiceDiscForCustomer(CreateCustomer()), false);
        VATAmount := Round(SalesVATAmountCalculation(SalesHeader."No.", DocumentType, VATPostingSetup."VAT %" / 100));
    end;

    local procedure SalesVATAmountCalculation(DocumentNo: Code[20]; DocumentType: Enum "Sales Document Type"; VATPercent: Decimal) VATAmount: Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindSet();
        repeat
            VATAmount += (SalesLine."Line Amount" - SalesLine."Inv. Discount Amount") * VATPercent;
        until SalesLine.Next() = 0;
    end;

    local procedure UpdatePartialQtyRcveAndInvoice(var PurchaseLine: Record "Purchase Line")
    begin
        // Purchase Line Quantity to Invoice and Quantity to Receive will always be less than Purchase Line Quantity.
        PurchaseLine.Validate("Qty. to Invoice", PurchaseLine.Quantity - 1);
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity - 1);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateVATAmountLine(var VATAmountLine: Record "VAT Amount Line")
    begin
        VATAmountLine.Validate("Invoice Discount Amount", 100 * LibraryRandom.RandInt(5));
        VATAmountLine.Modify(true);
    end;

    local procedure FindPostedPurchaseInvoice(var PurchInvHeader: Record "Purch. Inv. Header"; var PurchInvLine: Record "Purch. Inv. Line"; OrderNo: Code[20])
    begin
        PurchInvHeader.SetRange("Order No.", OrderNo);
        PurchInvHeader.FindFirst();
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.FindFirst();
    end;

    local procedure VerifyInvoiceDiscountAmount(Amount: Decimal; VATAmountLineDiscount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATAmountLine: Record "VAT Amount Line";
    begin
        GeneralLedgerSetup.Get();
        Assert.AreNearlyEqual(
          Amount, VATAmountLineDiscount, GeneralLedgerSetup."Inv. Rounding Precision (LCY)",
          StrSubstNo(AmtErrorMessage, VATAmountLine.FieldCaption("Invoice Discount Amount"), Amount, VATAmountLine.TableCaption()));
    end;

    local procedure VerifyPurchCMAmountInclVAT(DocumentNo: Code[20]; AmountIncludingVAT: Decimal)
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Amount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        PurchCrMemoLine.SetRange("Document No.", DocumentNo);
        PurchCrMemoLine.FindSet();
        repeat
            Amount += PurchCrMemoLine."Amount Including VAT";
        until PurchCrMemoLine.Next() = 0;
        Assert.AreNearlyEqual(
          AmountIncludingVAT, Amount, GeneralLedgerSetup."Inv. Rounding Precision (LCY)", StrSubstNo(
            AmtErrorMessage, PurchCrMemoLine.FieldCaption("Amount Including VAT"), AmountIncludingVAT, PurchCrMemoLine.TableCaption()));
    end;

    local procedure VerifyPurchOrderAmountInclVAT(DocumentNo: Code[20]; AmountIncludingVAT: Decimal)
    var
        PurchInvLine: Record "Purch. Inv. Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Amount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.FindSet();
        repeat
            Amount += PurchInvLine."Amount Including VAT";
        until PurchInvLine.Next() = 0;
        Assert.AreNearlyEqual(
          AmountIncludingVAT, Amount, GeneralLedgerSetup."Inv. Rounding Precision (LCY)",
          StrSubstNo(AmtErrorMessage, PurchInvLine.FieldCaption("Amount Including VAT"), AmountIncludingVAT, PurchInvLine.TableCaption()));
    end;

    local procedure VerifySalesOrderAmountInclVAT(DocumentNo: Code[20]; AmountIncludingVAT: Decimal)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Amount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindSet();
        repeat
            Amount += SalesInvoiceLine."Amount Including VAT";
        until SalesInvoiceLine.Next() = 0;
        Assert.AreNearlyEqual(
          AmountIncludingVAT, Amount, GeneralLedgerSetup."Inv. Rounding Precision (LCY)", StrSubstNo(AmtErrorMessage,
            SalesInvoiceLine.FieldCaption("Amount Including VAT"), AmountIncludingVAT, SalesInvoiceLine.TableCaption()));
    end;

    local procedure VerifySalesCMAmountInclVAT(DocumentNo: Code[20]; AmountIncludingVAT: Decimal)
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Amount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        SalesCrMemoLine.SetRange("Document No.", DocumentNo);
        SalesCrMemoLine.FindSet();
        repeat
            Amount += SalesCrMemoLine."Amount Including VAT";
        until SalesCrMemoLine.Next() = 0;
        Assert.AreNearlyEqual(
          AmountIncludingVAT, Amount, GeneralLedgerSetup."Inv. Rounding Precision (LCY)", StrSubstNo(
            AmtErrorMessage, SalesCrMemoLine.FieldCaption("Amount Including VAT"), AmountIncludingVAT, SalesCrMemoLine.TableCaption()));
    end;

    local procedure VerifyGLAndVATEntry(PostedDocumentNo: Code[20]; GLAccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; VATAmount: Decimal)
    begin
        VerifyGLEntry(PostedDocumentNo, GLAccountNo, DocumentType, VATAmount);
        VerifyVATEntry(PostedDocumentNo, DocumentType, VATAmount);
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; GLEntryAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLEntry: Record "G/L Entry";
        Amount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindSet();
        repeat
            Amount += GLEntry.Amount;
        until GLEntry.Next() = 0;
        Assert.AreNearlyEqual(
          GLEntryAmount, Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, GLEntry.FieldCaption(Amount), GLEntryAmount, GLEntry.TableCaption()));
    end;

    local procedure VerifyVATAmount(Amount: Decimal; VATAmountLineDiscount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATAmountLine: Record "VAT Amount Line";
    begin
        GeneralLedgerSetup.Get();
        Assert.AreNearlyEqual(
          Amount, VATAmountLineDiscount, GeneralLedgerSetup."Inv. Rounding Precision (LCY)",
          StrSubstNo(AmtErrorMessage, VATAmountLine.FieldCaption("VAT Amount"), Amount, VATAmountLine.TableCaption()));
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; VATEntryAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATEntry: Record "VAT Entry";
        Amount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindSet();
        repeat
            Amount += VATEntry.Amount;
        until VATEntry.Next() = 0;
        Assert.AreNearlyEqual(
          VATEntryAmount, Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, VATEntry.FieldCaption(Amount), VATEntryAmount, VATEntry.TableCaption()));
    end;

    local procedure VerifyVATAmountLine(VATAmountLine: Record "VAT Amount Line"; VATPct: Decimal; VATBase: Decimal; VATAmount: Decimal)
    begin
        VATAmountLine.SetRange("VAT %", VATPct);
        VATAmountLine.FindFirst();
        Assert.AreEqual(
          VATBase, VATAmountLine."VAT Base", StrSubstNo(AmountError, VATAmountLine.FieldCaption("VAT Base"), VATBase,
            VATAmountLine.TableCaption()));
        Assert.AreEqual(
          VATAmount, VATAmountLine."VAT Amount", StrSubstNo(AmountError, VATAmountLine.FieldCaption("VAT Amount"),
            VATAmount, VATAmountLine.TableCaption()));
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsModalPageHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    var
        TotalInclVAT: Variant;
    begin
        LibraryVariableStorage.Dequeue(TotalInclVAT);
        SalesOrderStatistics."TotalAmount1[1]".AssertEquals(TotalInclVAT);
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsPageHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    var
        TotalInclVAT: Variant;
    begin
        LibraryVariableStorage.Dequeue(TotalInclVAT);
        SalesOrderStatistics."TotalAmount1[1]".AssertEquals(TotalInclVAT);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    var
        Balance: Variant;
    begin
        LibraryVariableStorage.Dequeue(Balance);
        ApplyCustomerEntries.ControlBalance.AssertEquals(Balance);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    var
        TotalInclVAT: Variant;
    begin
        LibraryVariableStorage.Dequeue(TotalInclVAT);
        PurchaseOrderStatistics."TotalAmount1[3]".AssertEquals(TotalInclVAT);
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsPageHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    var
        TotalInclVAT: Variant;
    begin
        LibraryVariableStorage.Dequeue(TotalInclVAT);
        PurchaseOrderStatistics."TotalAmount1[3]".AssertEquals(TotalInclVAT);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyVendorEntriesHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    var
        Balance: Variant;
    begin
        LibraryVariableStorage.Dequeue(Balance);
        ApplyVendorEntries.ControlBalance.AssertEquals(Balance);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateSingleLinePurchaseDoc(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    begin
    end;
}

