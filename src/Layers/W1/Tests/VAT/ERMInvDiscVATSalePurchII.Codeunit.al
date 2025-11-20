codeunit 134040 "ERM Inv Disc VAT Sale/Purch II"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [VAT] [Invoice Discount]
        IsInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        AmountError: Label '%1 must be %2 in %3.';
        InvDiscErr: Label 'The maximum %1 that you can apply is %2.';

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderRoundingUp()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify VAT Amount on Sales Order Statistics for different VAT Posting Groups with GL VAT Rounding type Up.
        Initialize();
        CreateAndVerifySalesDoc('>', SalesHeader."Document Type"::Order, '>', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceFCYRoundingNear()
    var
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
    begin
        // Verify VAT Amount on Sales Invoice Statistics for different VAT Posting Groups with GL VAT Rounding type Nearest and FCY
        // with Currency VAT Rounding Down.
        Initialize();
        CreateAndVerifySalesDoc(
          '=', SalesHeader."Document Type"::Invoice, '=', CreateCurrency(Currency."VAT Rounding Type"::Down));
    end;

    local procedure CreateAndVerifySalesDoc(VATRoundingDirection: Text[1]; DocumentType: Enum "Sales Document Type"; RoundingType: Text[1]; CurrencyCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        VATAmountLine: Record "VAT Amount Line";
        QtyType: Option General,Invoicing,Shipping;
    begin
        // Setup:
        LibraryERM.SetVATRoundingType(VATRoundingDirection);
        // Exercise: Create Sales Document for two different VAT Posting Groups and calculate VAT Amount.
        CreateVATSalesDocument(SalesHeader, TempSalesLine, DocumentType, CurrencyCode);
        SalesLine.CalcVATAmountLines(QtyType::General, SalesHeader, TempSalesLine, VATAmountLine);

        // Verify: Verify VAT Amount field on Sales Document Statistics (VAT Amount Line Table) with GL VAT Rounding.
        TempSalesLine.FindSet();
        repeat
            VerifyVATOnStatistics(
              TempSalesLine."VAT %", RoundVATAmount(TempSalesLine."Line Amount" * TempSalesLine."VAT %" / 100, RoundingType));
        until TempSalesLine.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PstdSalesOrderRoundingUp()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify VAT Amount on Posted Sales Order different VAT Posting Groups with GL VAT Rounding type Up.
        Initialize();
        CreatePostAndVerifySalesDoc('>', SalesHeader."Document Type"::Order, '>', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PstdSalesInvoiceRoundingNear()
    var
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
    begin
        // Verify VAT Amount on General Ledger for different VAT Posting Groups with GL VAT Rounding type Nearest and FCY
        // with Currency VAT Rounding Down for Sales Invoice.
        Initialize();
        CreatePostAndVerifySalesDoc(
          '=', SalesHeader."Document Type"::Invoice, '<', CreateCurrency(Currency."VAT Rounding Type"::Down));
    end;

    local procedure CreatePostAndVerifySalesDoc(VATRoundingDirection: Text[1]; DocumentType: Enum "Sales Document Type"; RoundingType: Text[1]; CurrencyCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        TempSalesLine: Record "Sales Line" temporary;
        DocumentNo: Code[20];
    begin
        // Setup: Update GL Setup, Create Sales Document with two different VAT Posting Setup Items.
        LibraryERM.SetVATRoundingType(VATRoundingDirection);
        CreateVATSalesDocument(SalesHeader, TempSalesLine, DocumentType, CurrencyCode);

        // Exercise: Post the Sales Document.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify VAT Amount on GL Entry.
        TempSalesLine.FindSet();
        repeat
            VerifyVATAmountOnGLEntry(
              DocumentNo, TempSalesLine."VAT Prod. Posting Group", CurrencyCode, TempSalesLine."Line Amount" * TempSalesLine."VAT %" / 100,
              RoundingType);
        until TempSalesLine.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceRoundingUp()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify VAT Amount on Purchase Invoice Statistics for different VAT Posting Groups with GL VAT Rounding type Down.
        Initialize();
        CreateAndVerifyPurchaseDoc('>', PurchaseHeader."Document Type"::Invoice, '>', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderRoundingNear()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify VAT Amount on Purchase Order Statistics for different VAT Posting Groups with GL VAT Rounding type Nearest.
        Initialize();
        CreateAndVerifyPurchaseDoc('=', PurchaseHeader."Document Type"::Order, '=', '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCrMemoFCYRoundingNear()
    var
        Currency: Record Currency;
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify VAT Amount on Purchase Credit Memo Statistics for different VAT Posting Groups with GL VAT Rounding type Nearest and FCY
        // with Currency VAT Rounding Up.
        Initialize();
        CreateAndVerifyPurchaseDoc(
          '=', PurchaseHeader."Document Type"::"Credit Memo", '>', CreateCurrency(Currency."VAT Rounding Type"::Up));
    end;

    local procedure CreateAndVerifyPurchaseDoc(VATRoundingDirection: Text[1]; DocumentType: Enum "Purchase Document Type"; RoundingType: Text[1]; CurrencyCode: Code[10])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempPurchaseLine: Record "Purchase Line" temporary;
        VATAmountLine: Record "VAT Amount Line";
        QtyType: Option General,Invoicing,Shipping;
    begin
        // Setup.
        LibraryERM.SetVATRoundingType(VATRoundingDirection);

        // Exercise: Create Purchase Document for two different VAT Posting Groups and calculate VAT Amount.
        CreateVATPurchaseDocument(PurchaseHeader, TempPurchaseLine, DocumentType, CurrencyCode);
        PurchaseLine.CalcVATAmountLines(QtyType::General, PurchaseHeader, PurchaseLine, VATAmountLine);

        // Verify: Verify VAT Amount field on Purchase Document Statistics (VAT Amount Line Table) with GL VAT Rounding.
        TempPurchaseLine.FindSet();
        repeat
            VerifyVATOnStatistics(
              TempPurchaseLine."VAT %", RoundVATAmount(TempPurchaseLine."Line Amount" * TempPurchaseLine."VAT %" / 100, RoundingType));
        until TempPurchaseLine.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PstdPurchaseInvoiceRoundingUp()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify VAT Amount on Posted Purchase Invoice different VAT Posting Groups with GL VAT Rounding type Down.
        Initialize();
        CreatePostAndVerifyPurchaseDoc('>', PurchaseHeader."Document Type"::Invoice, '>', '', -1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PstdPurchaseOrderRoundingNear()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify VAT Amount on Posted Purchase Order different VAT Posting Groups with GL VAT Rounding type Nearest.
        Initialize();
        CreatePostAndVerifyPurchaseDoc('=', PurchaseHeader."Document Type"::Order, '=', '', -1)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PstdPurchaseCrMemoRoundingNear()
    var
        Currency: Record Currency;
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify VAT Amount on Purchase Credit Memo Statistics for different VAT Posting Groups with GL VAT Rounding type Nearest and FCY
        // with Currency VAT Rounding Up.
        Initialize();
        CreatePostAndVerifyPurchaseDoc(
          '=', PurchaseHeader."Document Type"::"Credit Memo", '>', CreateCurrency(Currency."VAT Rounding Type"::Up), 1);
    end;

    local procedure CreatePostAndVerifyPurchaseDoc(VATRoundingDirection: Text[1]; DocumentType: Enum "Purchase Document Type"; RoundingType: Text[1]; CurrencyCode: Code[10]; SignFactor: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
        TempPurchaseLine: Record "Purchase Line" temporary;
        DocumentNo: Code[20];
    begin
        // Setup.
        LibraryERM.SetVATRoundingType(VATRoundingDirection);

        // Exercise: Create Purchase Document for two different VAT Posting Groups and Post the document.
        CreateVATPurchaseDocument(PurchaseHeader, TempPurchaseLine, DocumentType, CurrencyCode);
        DocumentNo := PostPurchaseDocument(PurchaseHeader);

        // Verify: Verify VAT Amount On GL Entry.
        TempPurchaseLine.FindSet();
        repeat
            VerifyVATAmountOnGLEntry(
              DocumentNo, TempPurchaseLine."VAT Prod. Posting Group", CurrencyCode,
              SignFactor * (TempPurchaseLine."Line Amount" * TempPurchaseLine."VAT %" / 100), RoundingType);
        until TempPurchaseLine.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderNegativeInvDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
        SalesCalcDiscount: Codeunit "Sales-Calc. Discount";
        InvoiceDiscountAmount: Decimal;
        QtyType: Option General,Invoicing,Shipping;
    begin
        // Verify that Negative Invoice Discount can be entered on Sales Order Statistics.

        // Setup: Create Sales Order, Calculate Invoice Discount and VAT Amount on Sales Line.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine);
        SalesCalcDiscount.Run(SalesLine);
        SalesLine.CalcVATAmountLines(QtyType::General, SalesHeader, SalesLine, VATAmountLine);
        InvoiceDiscountAmount := -LibraryRandom.RandDec(100, 2);

        // Exercise: Update Negative Invoice Discount Amount for Sales Order.
        VATAmountLine.Validate("Invoice Discount Amount", InvoiceDiscountAmount);
        VATAmountLine.Modify(true);

        // Verify: Verify Negative Invoice Discount Amount on VAT Amount Line.
        Assert.AreEqual(
          InvoiceDiscountAmount, VATAmountLine."Invoice Discount Amount", StrSubstNo(
            AmountError, VATAmountLine.FieldCaption("Invoice Discount Amount"), InvoiceDiscountAmount, VATAmountLine.TableCaption()));

        // Tear Down: Delete Sales Order created.
        SalesHeader.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderLargeInvDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
        SalesCalcDiscount: Codeunit "Sales-Calc. Discount";
        QtyType: Option General,Invoicing,Shipping;
    begin
        // Verify Error Message after Updating Invoice Discount Amount greater than Invoice Discount Base Amount on Sales Order.

        // Setup: Create Sales Order, Calculate Invoice Discount and VAT Amount on Sales Line.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine);
        SalesCalcDiscount.Run(SalesLine);
        SalesLine.CalcVATAmountLines(QtyType::General, SalesHeader, SalesLine, VATAmountLine);

        // Exercise: Update Invoice Discount Amount more than Invoice Discount Base Amount.
        asserterror VATAmountLine.Validate(
            "Invoice Discount Amount", VATAmountLine."Inv. Disc. Base Amount" + LibraryRandom.RandDec(100, 2));

        // Verify: Verify the error message.
        Assert.ExpectedError(
          StrSubstNo(InvDiscErr, VATAmountLine.FieldCaption("Invoice Discount Amount"),
            VATAmountLine."Inv. Disc. Base Amount"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderEqualInvDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
        SalesCalcDiscount: Codeunit "Sales-Calc. Discount";
        QtyType: Option General,Invoicing,Shipping;
    begin
        // Verify VAT Base is Zero when Invoice Discount Amount is equal to Invoice Discount Base Amount for Sales Order.

        // Setup: Create Sales Order, Calculate Invoice Discount and VAT Amount Lines.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine);
        SalesCalcDiscount.Run(SalesLine);
        SalesLine.CalcVATAmountLines(QtyType::General, SalesHeader, SalesLine, VATAmountLine);

        // Exercise: Update Invoice Discount Amount equal to Invoice Discount Base Amount.
        VATAmountLine.Validate("Invoice Discount Amount", VATAmountLine."Inv. Disc. Base Amount");
        VATAmountLine.Modify(true);

        // Verify: Verify VAT Base Amount is Zero on VAT Amount Line.
        Assert.AreEqual(
          0, VATAmountLine."VAT Base", StrSubstNo(AmountError, VATAmountLine.FieldCaption("VAT Base"), 0, VATAmountLine.TableCaption()));

        // Tear Down: Delete Sales Order created.
        SalesHeader.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PstdSalesOrderEqualInvDiscount()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCalcDiscount: Codeunit "Sales-Calc. Discount";
        PostedDocumentNo: Code[20];
        InvoiceDiscountAmount: Decimal;
        VATAmount: Decimal;
    begin
        // Verify GL Entries after posting Sales Order when Invoice Discount Amount is equal to Invoice Discount Base Amount.

        // Setup: Create Sales Order, Calculate Invoice Discount. Update Invoice Discount Amount in Sales Lines.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine);
        SalesCalcDiscount.Run(SalesLine);
        InvoiceDiscountAmount := UpdateSalesLines(SalesHeader."No.");
        VATAmount := Round(InvoiceDiscountAmount * SalesLine."VAT %" / 100);

        // Exercise: Post Sales Order.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Amount and VAT Amount in GL Entry for Posted Sales Order.
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        VerifyGLEntry(
          GeneralPostingSetup."Sales Inv. Disc. Account", SalesHeader."Document Type"::Invoice.AsInteger(), PostedDocumentNo,
          InvoiceDiscountAmount, VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderNonDiscountItem()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
        "Count": Integer;
        QtyType: Option General,Invoicing,Shipping;
    begin
        // Verify Error Message after updating Invoice Discount Amount when Allow Invoice Discount is NO on Items taken in Sales Lines.

        // Setup: Create Sales Order with Non Discount Items, Release Sales Order and Calculate VAT Amount on Sales Line.
        Initialize();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomerInvDiscount());
        for Count := 1 to 1 + LibraryRandom.RandInt(5) do  // Create Multiple Sales Lines with Random Quantity and Price.
            CreateSalesLine(SalesLine, SalesHeader, CreateItemWithAllowInvDiscNo());
        SalesLine.CalcVATAmountLines(QtyType::General, SalesHeader, SalesLine, VATAmountLine);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // Exercise: Update Random Invoice Discount Amount for Sales Order.
        asserterror VATAmountLine.Validate("Invoice Discount Amount", LibraryRandom.RandInt(10));

        // Verify: Verify Error Message after changing Invoice Discount Amount.
        Assert.ExpectedTestFieldError(VATAmountLine.FieldCaption("Inv. Disc. Base Amount"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATSpecificationSalesInvoice()
    var
        SalesLine: Record "Sales Line";
        InvoiceDiscountAmount: Decimal;
    begin
        // Check VAT specification field on Sales Invoice Statistics Rounded to Amount Rounding Precision of the Currency.
        CreateSalesDocWithDiscount(SalesLine);
        InvoiceDiscountAmount := FindInvDiscAmountForCustomer(SalesLine."Sell-to Customer No.", SalesLine."Line Amount");

        // Verify: Verify that Line Amount, Invoice Discount Base Amount, Invoice Discount Amount, VAT Base, VAT Amount are Correctly
        // populated in VAT Amount Line.
        VerifyVATOnStatisticsAll(
          SalesLine."Currency Code", SalesLine."VAT %", SalesLine."Line Amount", InvoiceDiscountAmount,
          (SalesLine."Line Amount" - InvoiceDiscountAmount) * SalesLine."VAT %" / 100);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATSpecificationPurchInvoice()
    var
        PurchaseLine: Record "Purchase Line";
        Currency: Record Currency;
        InvoiceDiscountAmount: Decimal;
    begin
        // Check VAT specification field on Purchase Invoice Statistics Rounded to Amount Rounding Precision of the Currency.
        CreatePurchaseDocWithDiscount(
          PurchaseLine, CreateCurrency(Currency."VAT Rounding Type"::Nearest), PurchaseLine."Document Type"::Invoice);
        InvoiceDiscountAmount := FindInvDiscAmountForVendor(PurchaseLine."Buy-from Vendor No.", PurchaseLine."Line Amount");

        // Verify: Verify that Line Amount, Invoice Discount Base Amount, Invoice Discount Amount, VAT Base, VAT Amount are Correctly
        // populated in VAT Amount Line.
        VerifyVATOnStatisticsAll(
          PurchaseLine."Currency Code", PurchaseLine."VAT %", PurchaseLine."Line Amount", InvoiceDiscountAmount,
          (PurchaseLine."Line Amount" - InvoiceDiscountAmount) * PurchaseLine."VAT %" / 100);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATBaseAmountOnPstdSalesInv()
    var
        SalesHeader: Record "Sales Header";
        TempSalesLine: Record "Sales Line" temporary;
        DocumentNo: Code[20];
    begin
        // Setup.
        Initialize();
        CreateVATSalesDocument(SalesHeader, TempSalesLine, SalesHeader."Document Type"::Order, '');

        // Exercise: Post the Sales Document.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify VAT Base Amount field on Posted Invoice.
        VerifyVATBaseOnPstdSalesInv(TempSalesLine, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATBaseAmountOnPstdSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        TempSalesLine: Record "Sales Line" temporary;
        DocumentNo: Code[20];
    begin
        // Setup.
        Initialize();
        CreateVATSalesDocument(SalesHeader, TempSalesLine, SalesHeader."Document Type"::"Credit Memo", '');

        // Exercise: Post the Sales Document.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify VAT Base Amount field on Posted Credit Memo.
        VerifyVATBaseOnPstdSalesCrMemo(TempSalesLine, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATBaseAmountOnPstdPurchInv()
    var
        PurchaseHeader: Record "Purchase Header";
        TempPurchaseLine: Record "Purchase Line" temporary;
        DocumentNo: Code[20];
    begin
        // Setup.
        Initialize();
        CreateVATPurchaseDocument(PurchaseHeader, TempPurchaseLine, PurchaseHeader."Document Type"::Order, '');

        // Exercise: Post the Purchase Document.
        DocumentNo := PostPurchaseDocument(PurchaseHeader);

        // Verify: Verify VAT Base Amount field on Posted Invoice.
        VerifyVATBaseOnPstdPurchInv(TempPurchaseLine, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATBaseAmountOnPstdPurchCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        TempPurchaseLine: Record "Purchase Line" temporary;
        DocumentNo: Code[20];
    begin
        // Setup.
        Initialize();
        CreateVATPurchaseDocument(PurchaseHeader, TempPurchaseLine, PurchaseHeader."Document Type"::"Credit Memo", '');

        // Exercise: Post the Purchase Document.
        DocumentNo := PostPurchaseDocument(PurchaseHeader);

        // Verify: Verify VAT Base Amount field on Posted Credit Memo.
        VerifyVATBaseOnPstdPurchCrMemo(TempPurchaseLine, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderNegativeInvDiscount()
    var
        PurchaseLine: Record "Purchase Line";
        VATAmountLine: Record "VAT Amount Line";
        InvoiceDiscountAmount: Decimal;
    begin
        // Verify that Negative Invoice Discount can be entered on Purchase Order Statistics.

        // Setup: Create Purchase Order, Calculate Invoice Discount.
        Initialize();
        CreatePurchaseDocWithDiscount(PurchaseLine, '', PurchaseLine."Document Type"::Order);
        InvoiceDiscountAmount := -LibraryRandom.RandDec(100, 2);
        FindVATAmountLine(VATAmountLine, PurchaseLine."VAT Prod. Posting Group");

        // Exercise: Update Negative Invoice Discount Amount for Purchase Order.
        VATAmountLine.Validate("Invoice Discount Amount", InvoiceDiscountAmount);
        VATAmountLine.Modify(true);

        // Verify: Verify Negative Invoice Discount Amount on VAT Amount Line.
        Assert.AreEqual(
          InvoiceDiscountAmount, VATAmountLine."Invoice Discount Amount", StrSubstNo(
            AmountError, VATAmountLine.FieldCaption("Invoice Discount Amount"), InvoiceDiscountAmount, VATAmountLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderLargeInvDiscount()
    var
        PurchaseLine: Record "Purchase Line";
        VATAmountLine: Record "VAT Amount Line";
    begin
        // Verify Error Message after Updating Invoice Discount Amount greater than Invoice Discount Base Amount on Purchase Order.

        // Setup: Create Purchase Order, Calculate Invoice Discount.
        Initialize();
        CreatePurchaseDocWithDiscount(PurchaseLine, '', PurchaseLine."Document Type"::Order);
        FindVATAmountLine(VATAmountLine, PurchaseLine."VAT Prod. Posting Group");

        // Exercise: Update Invoice Discount Amount more than Invoice Discount Base Amount.
        asserterror VATAmountLine.Validate(
            "Invoice Discount Amount", VATAmountLine."Inv. Disc. Base Amount" + LibraryRandom.RandDec(100, 2));

        // Verify: Verify the error message.
        Assert.ExpectedError(
          StrSubstNo(InvDiscErr, VATAmountLine.FieldCaption("Invoice Discount Amount"),
            VATAmountLine."Inv. Disc. Base Amount"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderEqualInvDiscount()
    var
        PurchaseLine: Record "Purchase Line";
        VATAmountLine: Record "VAT Amount Line";
    begin
        // Verify VAT Base is Zero when Invoice Discount Amount is equal to Invoice Discount Base Amount for Purchase Order.

        // Setup: Create Purchase Order, Calculate Invoice Discount.
        Initialize();
        CreatePurchaseDocWithDiscount(PurchaseLine, '', PurchaseLine."Document Type"::Order);
        FindVATAmountLine(VATAmountLine, PurchaseLine."VAT Prod. Posting Group");

        // Exercise: Update Invoice Discount Amount equal to Invoice Discount Base Amount.
        VATAmountLine.Validate("Invoice Discount Amount", VATAmountLine."Inv. Disc. Base Amount");
        VATAmountLine.Modify(true);

        // Verify: Verify VAT Base Amount is Zero on VAT Amount Line.
        Assert.AreEqual(
          0, VATAmountLine."VAT Base", StrSubstNo(AmountError, VATAmountLine.FieldCaption("VAT Base"), 0, VATAmountLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PstdPurchOrderEqualInvDiscount()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        GeneralPostingSetup: Record "General Posting Setup";
        PostedDocumentNo: Code[20];
        InvoiceDiscountAmount: Decimal;
        VATAmount: Decimal;
    begin
        // Verify GL Entries after posting Purchase Order when Invoice Discount Amount is equal to Invoice Discount Base Amount.

        // Setup: Create Purchase Order, Calculate Invoice Discount. Update Invoice Discount Amount in Purchase Lines.
        Initialize();
        CreatePurchaseDocWithDiscount(PurchaseLine, '', PurchaseLine."Document Type"::Order);
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, PurchaseLine."Document No.");
        InvoiceDiscountAmount := UpdatePurchaseLine(PurchaseHeader."No.");
        VATAmount := Round(InvoiceDiscountAmount * PurchaseLine."VAT %" / 100);

        // Exercise: Post Purchase Order.
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Amount and VAT Amount in GL Entry for Posted Purchase Order.
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        VerifyGLEntry(
          GeneralPostingSetup."Purch. Inv. Disc. Account", PurchaseHeader."Document Type"::Invoice.AsInteger(), PostedDocumentNo,
          -InvoiceDiscountAmount, -VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderNonDiscountItem()
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        VATAmountLine: Record "VAT Amount Line";
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
        QtyType: Option General,Invoicing,Shipping;
        "Count": Integer;
    begin
        // Verify Error Message after updating Invoice Discount Amount when Allow Invoice Discount is NO on Items taken in Purchase Lines.

        // Setup: Create Purchase Header, Purchase Lines with Non Discount Items,Calculate VAT Amount on Purchase Line.
        // Release Purchase Order.
        Initialize();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendorInvDiscount());
        for Count := 1 to 1 + LibraryRandom.RandInt(5) do  // Create Multiple Purchase Lines with Random Quantity and Price.
            CreatePurchaseLine(PurchaseLine, PurchaseHeader, CreateItemWithAllowInvDiscNo());
        PurchCalcDiscount.CalculateInvoiceDiscount(PurchaseHeader, PurchaseLine);
        PurchaseLine.CalcVATAmountLines(QtyType::General, PurchaseHeader, PurchaseLine, VATAmountLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // Exercise: Update Random Invoice Discount Amount for Purchase Order.
        asserterror VATAmountLine.Validate("Invoice Discount Amount", LibraryRandom.RandInt(10));

        // Verify: Verify Error Message after changing Invoice Discount Amount.
        Assert.ExpectedTestFieldError(VATAmountLine.FieldCaption("Inv. Disc. Base Amount"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvDiscountPartPostSalesOrder()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCalcDiscount: Codeunit "Sales-Calc. Discount";
        TotalPartialLineAmount: Decimal;
        InvoiceDiscountAmount: Decimal;
        PostedDocumentNo: Code[20];
    begin
        // Verify GL Entries after posting partial Sales Order for Invoice Discount Amount.

        // Setup: Create Sales Order, Calculate Invoice Discount. Update Sales Line For Partial Posting.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine);
        SalesCalcDiscount.Run(SalesLine);
        TotalPartialLineAmount := UpdateSalesLinesForPartialPost(SalesHeader."No."); // Value used is Important for Test
        InvoiceDiscountAmount := Round(FindInvDiscAmountForCustomer(SalesLine."Sell-to Customer No.", TotalPartialLineAmount));

        // Exercise: Post Sales Order.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Amount and Invoice Discount Amount in GL Entry for Posted Sales Order.
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        VerifyInvDiscAmt(
          GeneralPostingSetup."Sales Inv. Disc. Account", SalesHeader."Document Type"::Invoice, PostedDocumentNo, InvoiceDiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvDiscountPartPostSalesOrderWithZeroLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceLine: Record "Sales Invoice Line";
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 277746] Inv. Discount Amount reset to zero when post sales line with invoice discount and Qty. to Ship = 0
        Initialize();

        // [GIVEN] Sales Order with Invoice Discount and multiple lines
        CreateSalesDocument(SalesHeader, SalesLine);
        LibrarySales.CalcSalesDiscount(SalesHeader);

        // [GIVEN] First line is updated with Qty. to Ship = 0
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.Validate("Qty. to Ship", 0);
        SalesLine.Modify(true);

        // [WHEN] Post Sales Order
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Sales Invoice Line is posted for zero Sales Line has "Inv. Discount Amount" = 0
        SalesInvoiceLine.Get(PostedDocumentNo, SalesLine."Line No.");
        SalesInvoiceLine.TestField("Inv. Discount Amount", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvDiscountPartPostPurchaseOrderWithZeroLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvLine: Record "Purch. Inv. Line";
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 277746] Inv. Discount Amount reset to zero when post purchase line with invoice discount and Qty. to Receive = 0
        Initialize();

        // [GIVEN] Purchase Order with Invoice Discount and multiples lines
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '', CreateVendorInvDiscount());
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, CreateItem());
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, CreateItem());
        LibraryPurchase.CalcPurchaseDiscount(PurchaseHeader);

        // [GIVEN] First line is updated with Qty. to Receive = 0
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Qty. to Receive", 0);
        PurchaseLine.Modify(true);

        // [WHEN] Post Purchase Order
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Purchase Invoice Line is posted for zero Purchase Line has "Inv. Discount Amount" = 0
        PurchInvLine.Get(PostedDocumentNo, PurchaseLine."Line No.");
        PurchInvLine.TestField("Inv. Discount Amount", 0);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Inv Disc VAT Sale/Purch II");
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Inv Disc VAT Sale/Purch II");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        IsInitialized := true;
        Commit();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Inv Disc VAT Sale/Purch II");
    end;

    local procedure CopyPurchaseLine(var TempPurchaseLine: Record "Purchase Line" temporary; PurchaseLine: Record "Purchase Line")
    begin
        TempPurchaseLine := PurchaseLine;
        TempPurchaseLine.Insert();
    end;

    local procedure CopySalesLine(var TempSalesLine: Record "Sales Line" temporary; SalesLine: Record "Sales Line")
    begin
        TempSalesLine := SalesLine;
        TempSalesLine.Insert();
    end;

    local procedure CreateCurrency(VATRoundingType: Option): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        Currency.Validate("VAT Rounding Type", VATRoundingType);
        Currency.Modify(true);
        exit(Currency.Code);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", FindVATBusPostingGroup());
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerInvDiscount(): Code[20]
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CreateCustomer(), '', 0);  // Set Zero for Charge Amount.
        CustInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(10, 2));  // Take Random Discount.
        CustInvoiceDisc.Modify(true);
        exit(CustInvoiceDisc.Code);
    end;

    local procedure CreateVendorInvDiscount(): Code[20]
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, CreateVendor(), '', 0);  // Set Zero for Charge Amount.
        VendorInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(10, 2));  // Take Random Discount.
        VendorInvoiceDisc.Modify(true);
        exit(VendorInvoiceDisc.Code);
    end;

    local procedure CreateItem(): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        FindVATPostingSetup(VATPostingSetup);
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemWithAllowInvDiscNo(): Code[20]
    var
        Item: Record Item;
    begin
        Item.Get(CreateItem());
        Item.Validate("Allow Invoice Disc.", false);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; CurrencyCode: Code[10]; VendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; No: Code[20])
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, No, LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        "Count": Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomerInvDiscount());
        for Count := 1 to 1 + LibraryRandom.RandInt(5) do  // Create Multiple Sales Lines.
            CreateSalesLine(SalesLine, SalesHeader, CreateItem());
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CurrencyCode: Code[10]; CustomerNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; No: Code[20])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, No, LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 3));
        SalesLine.Modify(true);
    end;

    local procedure CreateVATPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var TempPurchaseLine: Record "Purchase Line" temporary; DocumentType: Enum "Purchase Document Type"; CurrencyCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeader(PurchaseHeader, DocumentType, CurrencyCode, CreateVendor());
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, CreateItem());
        CopyPurchaseLine(TempPurchaseLine, PurchaseLine);  // Copy  First Purchase Line to Temporary Purchase Line.
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, FindItem(PurchaseHeader."VAT Bus. Posting Group", PurchaseLine."VAT %"));
        CopyPurchaseLine(TempPurchaseLine, PurchaseLine);  // Copy Second Purchase Line to Temporary Purchase Line.
    end;

    local procedure CreateVATSalesDocument(var SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary; DocumentType: Enum "Sales Document Type"; CurrencyCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeader(SalesHeader, DocumentType, CurrencyCode, CreateCustomer());
        CreateSalesLine(SalesLine, SalesHeader, CreateItem());
        CopySalesLine(TempSalesLine, SalesLine);  // Copy First Sales Line to Temporary Sales Line.
        CreateSalesLine(SalesLine, SalesHeader, FindItem(SalesHeader."VAT Bus. Posting Group", SalesLine."VAT %"));
        CopySalesLine(TempSalesLine, SalesLine);  // Copy Second Sales Line to Temporary Sales Line.
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", FindVATBusPostingGroup());
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreatePurchaseDocWithDiscount(var PurchaseLine: Record "Purchase Line"; CurrencyCode: Code[10]; DocumentType: Enum "Purchase Document Type"): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        VATAmountLine: Record "VAT Amount Line";
        NoSeries: Codeunit "No. Series";
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
        QtyType: Option General,Invoicing,Shipping;
    begin
        // Exercise: Create Purchase Header and Purchase Line.
        CreatePurchaseHeader(PurchaseHeader, DocumentType, CurrencyCode, CreateVendorInvDiscount());
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, CreateItem());
        PurchCalcDiscount.CalculateInvoiceDiscount(PurchaseHeader, PurchaseLine);
        PurchaseLine.CalcVATAmountLines(QtyType::General, PurchaseHeader, PurchaseLine, VATAmountLine);
        exit(NoSeries.PeekNextNo(PurchaseHeader."Posting No. Series"));
    end;

    local procedure CreateSalesDocWithDiscount(var SalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
        VATAmountLine: Record "VAT Amount Line";
        Currency: Record Currency;
        SalesCalcDiscount: Codeunit "Sales-Calc. Discount";
        QtyType: Option General,Invoicing,Shipping;
    begin
        // Exercise: Create Sales Header and Sales Line.
        CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, CreateCurrency(Currency."VAT Rounding Type"::Nearest),
          CreateCustomerInvDiscount());
        CreateSalesLine(SalesLine, SalesHeader, CreateItem());
        SalesCalcDiscount.Run(SalesLine);
        SalesLine.CalcVATAmountLines(QtyType::General, SalesHeader, SalesLine, VATAmountLine);
    end;

    local procedure FindItem(VATBusPostingGroup: Code[20]; VATPct: Decimal): Code[20]
    var
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Not using Library Item Finder method to make this funtion World ready.
        FindVATPostingSetup(VATPostingSetup);
        VATPostingSetup.SetRange("VAT Bus. Posting Group", VATBusPostingGroup);
        VATPostingSetup.SetFilter("VAT %", '<>%1', VATPct);
        VATPostingSetup.FindFirst();

        LibraryInventory.CreateItem(Item);
        Item.Validate(Blocked, false);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(100, 2)); // Using Random for Random Decimal value.
        Item.Validate("Unit Price", Item."Last Direct Cost");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure FindVATBusPostingGroup(): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindVATPostingSetup(VATPostingSetup);
        exit(VATPostingSetup."VAT Bus. Posting Group");
    end;

    local procedure FindInvDiscAmountForVendor("Code": Code[20]; LineAmount: Decimal): Decimal
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        VendorInvoiceDisc.SetRange(Code, Code);
        VendorInvoiceDisc.FindFirst();
        exit(LineAmount * VendorInvoiceDisc."Discount %" / 100);
    end;

    local procedure FindInvDiscAmountForCustomer("Code": Code[20]; LineAmount: Decimal): Decimal
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        CustInvoiceDisc.SetRange(Code, Code);
        CustInvoiceDisc.FindFirst();
        exit(LineAmount * CustInvoiceDisc."Discount %" / 100);
    end;

    local procedure FindVATAmountLine(var VATAmountLine: Record "VAT Amount Line"; VATIdentifier: Code[20])
    begin
        VATAmountLine.SetRange("VAT Identifier", VATIdentifier);
        VATAmountLine.FindFirst();
    end;

    local procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; GLAccountNo: Code[20]; DocumentType: Option; DocumentNo: Code[20])
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
    end;

    local procedure PostPurchaseDocument(PurchaseHeader: Record "Purchase Header"): Code[20]
    begin
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure RoundVATAmount(VATAmount: Decimal; RoundingType: Text[1]): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(Round(VATAmount, GeneralLedgerSetup."Amount Rounding Precision", RoundingType));
    end;

    local procedure UpdateSalesLines(DocumentNo: Code[20]) TotalAmount: Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindSet();
        repeat
            SalesLine.Validate("Inv. Discount Amount", SalesLine."Line Amount");
            SalesLine.Modify(true);
            TotalAmount += SalesLine."Line Amount";
        until SalesLine.Next() = 0;
    end;

    local procedure UpdateSalesLinesForPartialPost(DocumentNo: Code[20]) TotalPartialLineAmount: Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindSet();
        repeat
            SalesLine.Validate("Qty. to Ship", SalesLine.Quantity / 2); // Value used to validate partial quantity
            SalesLine.Modify(true);
            TotalPartialLineAmount += SalesLine."Qty. to Ship" * SalesLine."Unit Price";
        until SalesLine.Next() = 0;
    end;

    local procedure UpdatePurchaseLine(DocumentNo: Code[20]): Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Inv. Discount Amount", PurchaseLine."Line Amount");
        PurchaseLine.Modify(true);
        exit(PurchaseLine."Line Amount");
    end;

    local procedure VerifyGLEntry(GLAccountNo: Code[20]; DocumentType: Option; DocumentNo: Code[20]; Amount: Decimal; VATAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLEntry: Record "G/L Entry";
    begin
        GeneralLedgerSetup.Get();
        FindGLEntry(GLEntry, GLAccountNo, DocumentType, DocumentNo);
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, GeneralLedgerSetup."Inv. Rounding Precision (LCY)",
          StrSubstNo(AmountError, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption()));
        Assert.AreNearlyEqual(
          VATAmount, GLEntry."VAT Amount", GeneralLedgerSetup."Inv. Rounding Precision (LCY)",
          StrSubstNo(AmountError, GLEntry.FieldCaption("VAT Amount"), VATAmount, GLEntry.TableCaption()));
    end;

    local procedure VerifyVATAmountOnGLEntry(DocumentNo: Code[20]; VATProdPostingGroup: Code[20]; CurrencyCode: Code[10]; VATAmount: Decimal; RoundingType: Text[1])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLEntry: Record "G/L Entry";
        ActualVATAmount: Decimal;
        ExpectedVATAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("VAT Prod. Posting Group", VATProdPostingGroup);
        GLEntry.FindSet();
        repeat
            ActualVATAmount += GLEntry."VAT Amount";
        until GLEntry.Next() = 0;
        ExpectedVATAmount := LibraryERM.ConvertCurrency(RoundVATAmount(-VATAmount, RoundingType), CurrencyCode, '', WorkDate());
        Assert.AreNearlyEqual(
          ExpectedVATAmount, Round(ActualVATAmount), GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, GLEntry.FieldCaption("VAT Amount"), ExpectedVATAmount, GLEntry.TableCaption()));
    end;

    local procedure VerifyVATOnStatistics(VATPct: Decimal; VATAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATAmountLine: Record "VAT Amount Line";
    begin
        GeneralLedgerSetup.Get();
        VATAmountLine.SetRange("VAT %", VATPct);
        VATAmountLine.FindFirst();
        Assert.AreNearlyEqual(
          VATAmount, VATAmountLine."VAT Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, VATAmountLine.FieldCaption("VAT Amount"), VATAmount, VATAmountLine.TableCaption()));
    end;

    local procedure VerifyVATOnStatisticsAll(CurrencyCode: Code[10]; VATPercent: Decimal; LineAmount: Decimal; InvoiceDiscountAmount: Decimal; VATAmount: Decimal)
    var
        VATAmountLine: Record "VAT Amount Line";
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyCode);
        VATAmountLine.SetRange("VAT %", VATPercent);
        VATAmountLine.FindFirst();
        Assert.AreNearlyEqual(
          LineAmount, VATAmountLine."Line Amount", Currency."Amount Rounding Precision",
          StrSubstNo(AmountError, VATAmountLine.FieldCaption("Line Amount"), LineAmount, VATAmountLine.TableCaption()));
        Assert.AreNearlyEqual(
          LineAmount, VATAmountLine."Inv. Disc. Base Amount", Currency."Amount Rounding Precision",
          StrSubstNo(AmountError, VATAmountLine.FieldCaption("Inv. Disc. Base Amount"), LineAmount, VATAmountLine.TableCaption()));
        Assert.AreNearlyEqual(
          InvoiceDiscountAmount, VATAmountLine."Invoice Discount Amount", Currency."Amount Rounding Precision",
          StrSubstNo(AmountError, VATAmountLine.FieldCaption("Invoice Discount Amount"), InvoiceDiscountAmount, VATAmountLine.TableCaption()));
        Assert.AreNearlyEqual(
          LineAmount - InvoiceDiscountAmount, VATAmountLine."VAT Base", Currency."Amount Rounding Precision",
          StrSubstNo(AmountError, VATAmountLine.FieldCaption("VAT Base"), LineAmount - InvoiceDiscountAmount, VATAmountLine.TableCaption()));
        Assert.AreNearlyEqual(
          VATAmount, VATAmountLine."VAT Amount", Currency."Amount Rounding Precision",
          StrSubstNo(AmountError, VATAmountLine.FieldCaption("VAT Amount"), VATAmount, VATAmountLine.TableCaption()));
    end;

    local procedure VerifyVATBaseOnPstdSalesInv(var TempSalesLine: Record "Sales Line" temporary; DocumentNo: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        GeneralLedgerSetup.Get();
        TempSalesLine.FindSet();
        repeat
            SalesInvoiceLine.Get(DocumentNo, TempSalesLine."Line No.");
            Assert.AreNearlyEqual(
              TempSalesLine."Line Amount", SalesInvoiceLine."VAT Base Amount", GeneralLedgerSetup."Amount Rounding Precision",
              StrSubstNo(AmountError, SalesInvoiceLine.FieldCaption("VAT Base Amount"), TempSalesLine."Line Amount",
                SalesInvoiceLine.TableCaption()));
        until TempSalesLine.Next() = 0;
    end;

    local procedure VerifyVATBaseOnPstdSalesCrMemo(var TempSalesLine: Record "Sales Line" temporary; DocumentNo: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        GeneralLedgerSetup.Get();
        TempSalesLine.FindSet();
        repeat
            SalesCrMemoLine.Get(DocumentNo, TempSalesLine."Line No.");
            Assert.AreNearlyEqual(
              TempSalesLine."Line Amount", SalesCrMemoLine."VAT Base Amount", GeneralLedgerSetup."Amount Rounding Precision",
              StrSubstNo(AmountError, SalesCrMemoLine.FieldCaption("VAT Base Amount"), TempSalesLine."Line Amount",
                SalesCrMemoLine.TableCaption()));
        until TempSalesLine.Next() = 0;
    end;

    local procedure VerifyVATBaseOnPstdPurchInv(var TempPurchaseLine: Record "Purchase Line" temporary; DocumentNo: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        GeneralLedgerSetup.Get();
        TempPurchaseLine.FindSet();
        repeat
            PurchInvLine.Get(DocumentNo, TempPurchaseLine."Line No.");
            Assert.AreNearlyEqual(
              TempPurchaseLine."Line Amount", PurchInvLine."VAT Base Amount", GeneralLedgerSetup."Amount Rounding Precision",
              StrSubstNo(AmountError, PurchInvLine.FieldCaption("VAT Base Amount"), TempPurchaseLine."Line Amount",
                PurchInvLine.TableCaption()));
        until TempPurchaseLine.Next() = 0;
    end;

    local procedure VerifyVATBaseOnPstdPurchCrMemo(var TempPurchaseLine: Record "Purchase Line" temporary; DocumentNo: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        GeneralLedgerSetup.Get();
        TempPurchaseLine.FindSet();
        repeat
            PurchCrMemoLine.Get(DocumentNo, TempPurchaseLine."Line No.");
            Assert.AreNearlyEqual(
              TempPurchaseLine."Line Amount", PurchCrMemoLine."VAT Base Amount", GeneralLedgerSetup."Amount Rounding Precision",
              StrSubstNo(AmountError, PurchCrMemoLine.FieldCaption("VAT Base Amount"), TempPurchaseLine."Line Amount",
                PurchCrMemoLine.TableCaption()));
        until TempPurchaseLine.Next() = 0;
    end;

    local procedure VerifyInvDiscAmt(GLAccountNo: Code[20]; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; Amount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLEntry: Record "G/L Entry";
    begin
        GeneralLedgerSetup.Get();
        FindGLEntry(GLEntry, GLAccountNo, DocumentType.AsInteger(), DocumentNo);
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, GeneralLedgerSetup."Inv. Rounding Precision (LCY)",
          StrSubstNo(AmountError, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption()));
    end;
}

