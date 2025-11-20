codeunit 134039 "ERM Inv Disc VAT Sale/Purchase"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [VAT] [Invoice Discount]
        IsInitialized := false;
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryService: Codeunit "Library - Service";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        AmountError: Label '%1 must be %2 in %3.';
        InvDiscErr: Label 'The maximum %1 that you can apply is %2.';
        ValidationError: Label 'Error must match.';
        ErrorAmount: Label 'Amount must be %1 in %2.';
        LineDiscountPctErr: Label 'The value in the Line Discount % field must be between 0 and 100.';
        LineDscPctErr: Label 'Wrong value of Line Discount %.';
        LineAmountInvalidErr: Label 'You have set the line amount to a value that results in a discount that is not valid. Consider increasing the unit cost instead.';

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderInvDisc()
    var
        VATEntry: Record "VAT Entry";
        SalesHeader: Record "Sales Header";
        PostedDocumentNo: Code[20];
        InvDiscAmt: Decimal;
        VATPercent: Decimal;
    begin
        // Check that GL and VAT Entry has correct VAT and Invoice Discount Amount.

        // Setup: Modify General Ledger Setup, Create Sales Order and Calculate Invoice Discount.
        Initialize();
        LibraryERM.SetUnrealizedVAT(true);
        VATPercent := CreateSalesOrderAndCalcInvDisc(SalesHeader, InvDiscAmt, SalesHeader."Document Type"::Order);

        // Exercise: Post Sales Order with Ship and Invoice.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify GL Entry, VAT Entry for Invoice and VAT Amount.
        VerifyGLAndVATEntry(PostedDocumentNo, InvDiscAmt, Round(InvDiscAmt * VATPercent / 100), VATEntry.Type::Sale);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderInvDiscAndPayment()
    var
        VATEntry: Record "VAT Entry";
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        PostedDocumentNo: Code[20];
        InvDiscAmt: Decimal;
        Amount: Decimal;
        VATPercent: Decimal;
    begin
        // Check that GL and VAT Entry has correct VAT and Invoice Discount Amount after Post Sales Order and Payment.

        // Setup: Modify General Ledger Setup, Create Sales Order, Calculate Invoice Discount and Release it.
        Initialize();
        LibraryERM.SetUnrealizedVAT(true);
        VATPercent := CreateSalesOrderAndCalcInvDisc(SalesHeader, InvDiscAmt, SalesHeader."Document Type"::Order);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        SalesHeader.CalcFields("Amount Including VAT");
        Amount := SalesHeader."Amount Including VAT";

        // Exercise: Post Sales Order and Payment for Posted Order.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        CreateAndPostGenJournalLine(SalesHeader."Sell-to Customer No.", GenJournalLine."Account Type"::Customer, PostedDocumentNo, -Amount);

        // Verify: Verify GL Entry, VAT Entry for Invoice and VAT Amount after Payment for Invoice.
        VerifyGLAndVATEntry(PostedDocumentNo, InvDiscAmt, Round(InvDiscAmt * VATPercent / 100), VATEntry.Type::Sale);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderInvDisc()
    var
        VATEntry: Record "VAT Entry";
        PurchaseHeader: Record "Purchase Header";
        PostedDocumentNo: Code[20];
        InvDiscAmt: Decimal;
        VATPercent: Decimal;
    begin
        // Check that GL and VAT Entry has correct VAT and Invoice Discount Amount.

        // Setup: Modify General Ledger Setup, Create Purchase Order and Calculate Invoice Discount.
        Initialize();
        LibraryERM.SetUnrealizedVAT(true);
        VATPercent := CreatePurchOrderAndCalcInvDisc(PurchaseHeader, InvDiscAmt, PurchaseHeader."Document Type"::Order);

        // Exercise: Post Purchase Order with Receive and Invoice.
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify GL Entry, VAT Entry for Invoice and VAT Amount.
        VerifyGLAndVATEntry(PostedDocumentNo, -InvDiscAmt, Round(-InvDiscAmt * VATPercent / 100), VATEntry.Type::Purchase);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderInvDiscAndPayment()
    var
        VATEntry: Record "VAT Entry";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        ReleasePurchaseDocument: Codeunit "Release Purchase Document";
        PostedDocumentNo: Code[20];
        InvDiscAmt: Decimal;
        Amount: Decimal;
        VATPercent: Decimal;
    begin
        // Check that GL and VAT Entry has correct VAT and Invoice Discount Amount after Post Purchase Order and Payment.

        // Setup: Modify General Ledger Setup, Create Purchase Order, Calculate Invoice Discount and Release it.
        Initialize();
        LibraryERM.SetUnrealizedVAT(true);
        VATPercent := CreatePurchOrderAndCalcInvDisc(PurchaseHeader, InvDiscAmt, PurchaseHeader."Document Type"::Order);
        Clear(ReleasePurchaseDocument);
        ReleasePurchaseDocument.Run(PurchaseHeader);
        PurchaseHeader.CalcFields("Amount Including VAT");
        Amount := PurchaseHeader."Amount Including VAT";

        // Exercise: Post Purchase Order and Payment for Posted Order.
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreateAndPostGenJournalLine(PurchaseHeader."Buy-from Vendor No.", GenJournalLine."Account Type"::Vendor, PostedDocumentNo, Amount);

        // Verify: Verify GL Entry, VAT Entry for Invoice and VAT Amount after Payment for Invoice.
        VerifyGLAndVATEntry(PostedDocumentNo, -InvDiscAmt, Round(-InvDiscAmt * VATPercent / 100), VATEntry.Type::Purchase);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderVATAfterInvDisc()
    var
        VATAmountLine: Record "VAT Amount Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCalcDiscount: Codeunit "Sales-Calc. Discount";
        QtyType: Option General,Invoicing,Shipping;
        VATAmount: Decimal;
        InvoiceDiscountValue: Decimal;
    begin
        // Check VAT Amount on VAT Amount Line after Calculating Invoice Discount on Created Sales Order.

        // Setup: Create Sales Order, Calculate VAT Amount on Sales Line and Calculate Invoice Discount.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine, 1, SalesHeader."Document Type"::Order);  // Take 1 Fix for Creating 1 Sales Line.
        InvoiceDiscountValue := FindCustomerInvoiceDiscount(SalesHeader."Sell-to Customer No.");
        SalesLine.CalcVATAmountLines(QtyType::General, SalesHeader, SalesLine, VATAmountLine);
        VATAmount := VATAmountLine."VAT Amount" - (VATAmountLine."VAT Amount" * InvoiceDiscountValue / 100);
        SalesCalcDiscount.Run(SalesLine);

        // Exercise: Calculate again VAT Amount Line.
        SalesLine.CalcVATAmountLines(QtyType::General, SalesHeader, SalesLine, VATAmountLine);

        // Verify: Verify that after Calculate Invoice Discount VAT Amount has been changed.
        VerifyVATAmountLine(VATAmount, VATAmountLine."VAT Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderVATAfterInvDiscZero()
    var
        VATAmountLine: Record "VAT Amount Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCalcDiscount: Codeunit "Sales-Calc. Discount";
        QtyType: Option General,Invoicing,Shipping;
        VATAmount: Decimal;
    begin
        // Check VAT Amount on VAT Amount Line after Calculating Invoice Discount and Set Invoice Discount Amount Zero
        // on Created Sales Order.

        // Setup: Create Sales Order, Calculate VAT Amount on Sales Line and Calculate Invoice Discount.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine, 1, SalesHeader."Document Type"::Order);  // Take 1 Fix for Creating 1 Sales Line.
        SalesLine.CalcVATAmountLines(QtyType::General, SalesHeader, SalesLine, VATAmountLine);
        VATAmount := VATAmountLine."VAT Amount";
        SalesCalcDiscount.Run(SalesLine);
        SalesLine.CalcVATAmountLines(QtyType::General, SalesHeader, SalesLine, VATAmountLine);
        VATAmountLine.Validate("Invoice Discount Amount", 0);
        VATAmountLine.Modify(true);

        // Exercise: Calculate VAT Amount Field on VAT Amount Line.
        VATAmountLine.CalcVATFields('', false, 0);

        // Verify: Verify VAT Amount Value on VAT Amount Line after Set Invoice Discount Amount Zero.
        VerifyVATAmountLine(VATAmount, VATAmountLine."VAT Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderVATAfterInvDisc()
    var
        VATAmountLine: Record "VAT Amount Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
        InvoiceDiscountValue: Decimal;
        QtyType: Option General,Invoicing,Shipping;
        VATAmount: Decimal;
    begin
        // Check VAT Amount on VAT Amount Line after Calculating Invoice Discount on Created Purchase Order.

        // Setup: Create Purchase Order, Calculate Invoice Discount and VAT Amount Line. Take 1 Fix for Creating 1 Purchase Line.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, 1, PurchaseHeader."Document Type"::Order);
        InvoiceDiscountValue := FindVendorInvoiceDiscount(PurchaseHeader."Buy-from Vendor No.");
        PurchaseLine.CalcVATAmountLines(QtyType::General, PurchaseHeader, PurchaseLine, VATAmountLine);
        VATAmount := VATAmountLine."VAT Amount" - (VATAmountLine."VAT Amount" * InvoiceDiscountValue / 100);
        PurchCalcDiscount.Run(PurchaseLine);

        // Exercise: Calculate again VAT Amount Line.
        PurchaseLine.CalcVATAmountLines(QtyType::General, PurchaseHeader, PurchaseLine, VATAmountLine);

        // Verify: Verify that after Calculate Invoice Discount VAT Amount has been changed.
        VerifyVATAmountLine(VATAmount, VATAmountLine."VAT Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderVATAfterInvDiscZero()
    var
        VATAmountLine: Record "VAT Amount Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
        QtyType: Option General,Invoicing,Shipping;
        VATAmount: Decimal;
    begin
        // Check VAT Amount on VAT Amount Line after Calculating Invoice Discount and Set Invoice Discount Amount Zero
        // on Created Purchase Order.

        // Setup: Create Purchase Document and Calculate Invoice Discount and VAT Amount Line. Take 1 Fix for Creating 1 Purchase Line.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, 1, PurchaseHeader."Document Type"::Order);
        PurchaseLine.CalcVATAmountLines(QtyType::General, PurchaseHeader, PurchaseLine, VATAmountLine);
        VATAmount := VATAmountLine."VAT Amount";
        PurchCalcDiscount.Run(PurchaseLine);
        PurchaseLine.CalcVATAmountLines(QtyType::General, PurchaseHeader, PurchaseLine, VATAmountLine);
        VATAmountLine.Validate("Invoice Discount Amount", 0);  // Set Invoice Discount Zero.
        VATAmountLine.Modify(true);

        // Exercise: Calculate VAT Amount Field on VAT Amount Line.
        VATAmountLine.CalcVATFields('', false, 0);

        // Verify: Verify VAT Amount Value on VAT Amount Line after Set Invoice Discount Amount Zero.
        VerifyVATAmountLine(VATAmount, VATAmountLine."VAT Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCMWithLineDiscAndVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LineDiscVATAmt: Decimal;
        PostedDocumentNo: Code[20];
    begin
        // Check Line Discount Amount on GL Entry and Posted Sales Credit Memo after Post Sales Credit Memo.

        // Setup: Create Sales Credit Memo and Validate Line Discount Amount on Sales Line.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine, 1, SalesHeader."Document Type"::"Credit Memo"); // Take 1 Fix for Creating 1 Sales Line.
        SalesLine.Validate("Line Discount Amount", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);
        LineDiscVATAmt := SalesLine."Line Discount Amount" * SalesLine."VAT %" / 100;

        // Exercise: Post Sales Credit Memo.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Posted Sales Credit Memo for Line Discount Amount and GL Entry for VAT Amount with
        // Sales Credit Memo's Line Discount Amount.
        VerifyPostedSalesCrMemo(PostedDocumentNo, SalesLine."Line Discount Amount");
        VerifyGLEntry(SalesHeader."Document Type".AsInteger(), PostedDocumentNo, -SalesLine."Line Discount Amount", -LineDiscVATAmt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCMWithInvDiscAndVAT()
    var
        VATAmountLine: Record "VAT Amount Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCalcDiscount: Codeunit "Sales-Calc. Discount";
        PostedDocumentNo: Code[20];
        VATAmount: Decimal;
        OldCalcInvDiscperVATID: Boolean;
        InvoiceDiscountAmount: Decimal;
        QtyType: Option General,Invoicing,Shipping;
        VATAmount2: Decimal;
    begin
        // Check VAT Amount on VAT Amount Line after Calculating Invoice Discount on Sales Credit Memo with Modified "Calc Inv. Disc. VAT
        // Per ID" field on Purchase and Payable Setup.

        // Setup: Modify Sales and Receivables Setup for Calc. Inv. Disc. Per VAT ID, Create Credit Memo and Calculate Invoice Discount.
        Initialize();
        UpdateSalesCalcInvDiscPerVATID(OldCalcInvDiscperVATID, true);
        CreateSalesDocument(SalesHeader, SalesLine, 1, SalesHeader."Document Type"::"Credit Memo"); // Take 1 Fix for Creating 1 Sales Line.
        InvoiceDiscountAmount := Round(SalesLine."Line Amount" * FindCustomerInvoiceDiscount(SalesHeader."Sell-to Customer No.") / 100);
        VATAmount := (SalesLine."Line Amount" - InvoiceDiscountAmount) * SalesLine."VAT %" / 100;
        VATAmount2 := InvoiceDiscountAmount * SalesLine."VAT %" / 100;
        SalesCalcDiscount.Run(SalesLine);

        // Exercise: Calculate VAT Amount Lines for Sales Credit Memo and Post Credit Memo.
        SalesLine.CalcVATAmountLines(QtyType::General, SalesHeader, SalesLine, VATAmountLine);
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify VAT Amount on VAT Amount Lines after Calculate Invoice Discount on Sales Credit Memo.
        VerifyVATAmountLine(VATAmount, VATAmountLine."VAT Amount");
        VerifyGLEntry(SalesHeader."Document Type".AsInteger(), PostedDocumentNo, -InvoiceDiscountAmount, -VATAmount2);
        VerifyPostedSalesCrMemoInvDisc(PostedDocumentNo, InvoiceDiscountAmount);

        // Tear Down: Set Default value for Calc. Inv. disc. Per VAT ID field in Sales and Receivables Setup.
        UpdateSalesCalcInvDiscPerVATID(OldCalcInvDiscperVATID, OldCalcInvDiscperVATID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderWithInvDiscAndVAT()
    var
        VATAmountLine: Record "VAT Amount Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
        PostedDocumentNo: Code[20];
        InvoiceDiscountAmount: Decimal;
        QtyType: Option General,Invoicing,Shipping;
        VATAmount: Decimal;
        OldCalcInvDiscperVATID: Boolean;
        VATAmount2: Decimal;
    begin
        // Check VAT Amount on VAT Amount Line after Calculating Invoice Discount on Purchase Order with Modified "Calc Inv. Disc. VAT
        // Per ID" field on Purchase and Payable Setup.

        // Setup: Modify Purchase and Payable Setup for Calc. Inv. Disc. Per VAT ID, Create Purchase Order and Calculate Invoice
        // Discount with 1 fix Purchase Line.
        Initialize();
        UpdatePurchCalcInvDiscPerVATID(OldCalcInvDiscperVATID, true);
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, 1, PurchaseHeader."Document Type"::Order);
        InvoiceDiscountAmount :=
          Round(PurchaseLine."Line Amount" * FindVendorInvoiceDiscount(PurchaseHeader."Buy-from Vendor No.") / 100);
        VATAmount := (PurchaseLine."Line Amount" - InvoiceDiscountAmount) * PurchaseLine."VAT %" / 100;
        VATAmount2 := InvoiceDiscountAmount * PurchaseLine."VAT %" / 100;
        PurchCalcDiscount.Run(PurchaseLine);

        // Exercise: Calculate VAT Amount Lines for Purchase Order and Post Purchase Order.
        PurchaseLine.CalcVATAmountLines(QtyType::General, PurchaseHeader, PurchaseLine, VATAmountLine);
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify VAT Amount on VAT Amount Lines after Calculate Invoice Discount on Purchase Order.
        VerifyVATAmountLine(VATAmount, VATAmountLine."VAT Amount");
        VerifyGLEntry(PurchaseHeader."Document Type"::Invoice.AsInteger(), PostedDocumentNo, -InvoiceDiscountAmount, -VATAmount2);
        VerifyPostedPurchaseInvoice(InvoiceDiscountAmount, PurchaseHeader."No.");

        // Tear Down: Set Default value for Calc. Inv. disc. Per VAT ID field in Purchase and Payables Setup.
        UpdatePurchCalcInvDiscPerVATID(OldCalcInvDiscperVATID, OldCalcInvDiscperVATID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCMWithCustomInvDisc()
    var
        VATAmountLine: Record "VAT Amount Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QtyType: Option General,Invoicing,Shipping;
        InvoiceDiscountAmount: Decimal;
    begin
        // Check Invoice Discount Amount on VAT Amount Line With Purchase Credit Memo without Calculating Invoice Discount.

        // Setup: Create Purchase Credit Memo and Validate Random Invoice Discount Amount on Purchase Line with 1 Line.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, 1, PurchaseHeader."Document Type"::"Credit Memo");
        ModifyPurchaseLine(PurchaseLine);
        InvoiceDiscountAmount := PurchaseLine."Inv. Discount Amount";

        // Exercise: Calculate VAT Amount Line for Invoice Discount.
        PurchaseLine.CalcVATAmountLines(QtyType::General, PurchaseHeader, PurchaseLine, VATAmountLine);

        // Verify: Verify Invoice Discount on VAT Amount Line after Validating on Purchase Line.
        VerifyVATAmountLineForInvDisc(VATAmountLine."Invoice Discount Amount", InvoiceDiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchCMWithCustomInvDisc()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PostedDocumentNo: Code[20];
        VATAmount: Decimal;
        InvoiceDiscountAmount: Decimal;
    begin
        // Check Invoice Discount Amount has been flow on Posted Entries without Calculating Invoice Discount.

        // Setup: Create Purchase Credit Memo and Validate Random Invoice Discount Amount on Purchase Line with 1 Line.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, 1, PurchaseHeader."Document Type"::"Credit Memo");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        ModifyPurchaseLine(PurchaseLine);
        InvoiceDiscountAmount := PurchaseLine."Inv. Discount Amount";
        VATAmount := InvoiceDiscountAmount * PurchaseLine."VAT %" / 100;

        // Exercise: Post Purchase Credit Memo.
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Invoice Discount on GL Entry and Posted Purchase Credit Memo.
        VerifyGLEntry(PurchaseHeader."Document Type".AsInteger(), PostedDocumentNo, InvoiceDiscountAmount, VATAmount);
        VerifyPostedPurchaseCrMemo(PostedDocumentNo, InvoiceDiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvDiscErrForGreaterValue()
    var
        VATAmountLine: Record "VAT Amount Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
        QtyType: Option General,Invoicing,Shipping;
    begin
        // Check Error on Validate of Invoice Discount Amount on VAT Amount Line with More than Inv. Disc. Base Amount.

        // Setup: Create Purchase Order, Calculate Invoice Discount and VAT Amount Line. Take 1 Fix for Creating 1 Purchase Line.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, 1, PurchaseHeader."Document Type"::Order);
        PurchCalcDiscount.Run(PurchaseLine);
        PurchaseLine.CalcVATAmountLines(QtyType::General, PurchaseHeader, PurchaseLine, VATAmountLine);

        // Exercise: Validate Invoice Discount Amount with Greater Random Inv. Disc. Base Amount on VAT Amount Line.
        asserterror VATAmountLine.Validate(
            "Invoice Discount Amount", VATAmountLine."Inv. Disc. Base Amount" + LibraryRandom.RandDec(10, 1));

        // Verify: Verity Error on Validate of Invoice Discount Amount with More than Inv. Disc. Base Amount on VAT Amount Line.
        Assert.AreEqual(StrSubstNo(InvDiscErr, VATAmountLine.FieldCaption("Invoice Discount Amount"),
            VATAmountLine."Inv. Disc. Base Amount"), GetLastErrorText, ValidationError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EqualInvDiscInvBasePurchOrder()
    var
        VATAmountLine: Record "VAT Amount Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
        QtyType: Option General,Invoicing,Shipping;
    begin
        // Check Invoice Discount Amount has been updated with Inv. Disc. Base Amount on VAT Amount Line after Create Purchase Order.

        // Setup: Create Purchase Order, Calculate Invoice Discount and VAT Amount Line. Take 1 Fix for Creating 1 Purchase Line.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, 1, PurchaseHeader."Document Type"::Order);
        PurchCalcDiscount.Run(PurchaseLine);
        PurchaseLine.CalcVATAmountLines(QtyType::General, PurchaseHeader, PurchaseLine, VATAmountLine);

        // Exercise: Modify Invoice Discount Amount with Inv. Disc. Base Amount on VAT Amount Line.
        VATAmountLine.Validate("Invoice Discount Amount", VATAmountLine."Inv. Disc. Base Amount");
        VATAmountLine.Modify(true);

        // Verify: Verity Invoice Discount Amount has equal Amount with Inv. Disc. Base Amount on VAT Amount Line.
        Assert.AreEqual(VATAmountLine."Invoice Discount Amount", VATAmountLine."Inv. Disc. Base Amount", ValidationError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvDiscErrForZeroValue()
    var
        VATAmountLine: Record "VAT Amount Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        QtyType: Option General,Invoicing,Shipping;
    begin
        // Check Error on Validate of Invoice Discount Amount on VAT Amount Line when Inv. Disc. Base Amount is Zero.

        // Setup: Create Purchase Order, with Modified Item and Random Direct Unit Cost. Release it and Calculate VAT Amount Line.
        Initialize();
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendAndInvoiceDiscount());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ModifyAllowInvoiceDiscInItem(), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PurchaseLine.CalcVATAmountLines(QtyType::General, PurchaseHeader, PurchaseLine, VATAmountLine);

        // Exercise: Validate Invoice Discount Amount with Random Amount.
        asserterror VATAmountLine.Validate("Invoice Discount Amount", LibraryRandom.RandDec(10, 2));

        // Verify: Verity Error on Validate of Invoice Discount Amount when Inv. Disc. Base Amount is Zero.
        Assert.ExpectedTestFieldError(VATAmountLine.FieldCaption("Inv. Disc. Base Amount"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithLineDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LineDiscAmount: Decimal;
        LineAmount: Decimal;
    begin
        // Check Line Discount Amount and Line Amount Excluding VAT on Sales Line.

        // Setup: Create Sales Invoice.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine, 1, SalesHeader."Document Type"::Invoice);  // Take 1 Fix for Creating 1 Sales Line.
        SalesLine.Validate("Line Discount %", LibraryRandom.RandInt(5));
        SalesLine.Modify(true);

        // Exercise: Calculate Line Discount Amount and Line Amount Excluding VAT.
        LineDiscAmount := SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."Line Discount %" / 100;
        LineAmount := (SalesLine.Quantity * SalesLine."Unit Price") - LineDiscAmount;

        // Verify: Verify Line Discount Amount and Line Amount Excl VAT in Sales Invoice Line.
        VerifySalesLineAmount(LineDiscAmount, SalesLine."Line Discount Amount");
        VerifySalesLineAmount(LineAmount, SalesLine."Line Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithLineDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        LineDiscAmount: Decimal;
        LineAmount: Decimal;
    begin
        // Check Line Discount Amount and Line Amount Excluding VAT on Purchase Line.

        // Setup: Create Purchase Invoice. Take 1 Fix for Creating 1 Sales Line.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, 1, PurchaseHeader."Document Type"::Invoice);
        PurchaseLine.Validate("Line Discount %", LibraryRandom.RandInt(5));
        PurchaseLine.Modify(true);

        // Exercise: Calculate Line Discount Amount and Line Amount Excluding VAT.
        LineDiscAmount := PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost" * PurchaseLine."Line Discount %" / 100;
        LineAmount := (PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost") - LineDiscAmount;

        // Verify: Verify Line Discount Amount and Line Amount Excl VAT in Purchase Invoice Line.
        VerifyPurchLineAmount(LineDiscAmount, PurchaseLine."Line Discount Amount");
        VerifyPurchLineAmount(LineAmount, PurchaseLine."Line Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithZeroVAT()
    var
        VATAmountLine: Record "VAT Amount Line";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        QtyType: Option General,Invoicing,Shipping;
        VATAmount: Decimal;
    begin
        // Check that VAT Amount has been zero on Sales Order when Sales Line has Equal Negative and Positive Values.

        // Setup: Create Sales Order and Create Two Lines for GL Account and Item with One Negative and One Postive with Random.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::Sale),
          -LibraryRandom.RandInt(10), LibraryRandom.RandDec(100, 2));
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          UpdateItemWithVATProdPostingGroup(CreateItem(), VATPostingSetup."VAT Prod. Posting Group"),
          -SalesLine.Quantity, SalesLine."Unit Price");

        // Exercise: Calculate VAT Amount Line.
        SalesLine.CalcVATAmountLines(QtyType::General, SalesHeader, SalesLine, VATAmountLine);
        VATAmountLine.FindSet();
        repeat
            VATAmount += VATAmountLine."VAT Amount";
        until VATAmountLine.Next() = 0;

        // Verify: Verify VAT Amount for Zero in VAT Amount Line.
        VerifyVATAmountLine(0, VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderWithZeroVAT()
    var
        VATAmountLine: Record "VAT Amount Line";
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        QtyType: Option General,Invoicing,Shipping;
        VATAmount: Decimal;
    begin
        // Check that VAT Amount has been zero on Purchase Order when Purchase Line has Equal Negative and Positive Values.

        // Setup: Create Purchase Order and Create Two Lines for GL Account and Item with One Negative and One Positive with Random.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::Purchase),
          -LibraryRandom.RandInt(10), LibraryRandom.RandDec(100, 2));
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          UpdateItemWithVATProdPostingGroup(CreateItem(), VATPostingSetup."VAT Prod. Posting Group"),
          -PurchaseLine.Quantity, PurchaseLine."Direct Unit Cost");

        // Exercise: Calculate VAT Amount Line.
        PurchaseLine.CalcVATAmountLines(QtyType::General, PurchaseHeader, PurchaseLine, VATAmountLine);
        VATAmountLine.FindSet();
        repeat
            VATAmount += VATAmountLine."VAT Amount";
        until VATAmountLine.Next() = 0;

        // Verify: Verify VAT Amount for Zero in VAT Amount Line.
        VerifyVATAmountLine(0, VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATIdentifierOnSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        InvoiceDiscountAmount: Decimal;
        InvoiceDiscountAmount2: Decimal;
        QtyType: Option General,Invoicing,Shipping;
        VATIdentifier: Code[20];
    begin
        // Verify Invoice Discount and VAT Identifier on Sales Order for different VAT Posting Groups.

        // Setup: Create Invoice Discount Setup, Create Sales Order for two different VAT Posting Groups and Calculate Invoice Discount.
        Initialize();
        SetupForVATIdentifier(VATPostingSetup, VATPostingSetup2);
        VATIdentifier :=
          CreateAndCalcSaleInvDisc(
            SalesHeader, SalesLine, InvoiceDiscountAmount, InvoiceDiscountAmount2, SalesHeader."Document Type"::Order);

        // Exercise: Calculate VAT Amount.
        SalesLine.CalcVATAmountLines(QtyType::General, SalesHeader, SalesLine, VATAmountLine);

        // Verify VAT Identifier field on Sales Order Statistics (VAT Amount Line Table) and Tear Down VAT Setup.
        VerifyStatisticsAndVATTearDown(VATPostingSetup, VATPostingSetup2, InvoiceDiscountAmount, InvoiceDiscountAmount2, VATIdentifier);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATIdentifierOnPstdSalesInv()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        VATAmountLine: Record "VAT Amount Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        InvoiceDiscountAmount: Decimal;
        InvoiceDiscountAmount2: Decimal;
        VATIdentifier: Code[20];
        DocumentNo: Code[20];
    begin
        // Verify Invoice Discount and VAT Identifier on Posted Sales Invoice for different VAT Posting Groups.

        // Setup: Create Invoice Discount Setup, Create Sales Order for two different VAT Posting Groups and Calculate Invoice Discount.
        Initialize();
        SetupForVATIdentifier(VATPostingSetup, VATPostingSetup2);
        VATIdentifier :=
          CreateAndCalcSaleInvDisc(
            SalesHeader, SalesLine, InvoiceDiscountAmount, InvoiceDiscountAmount2, SalesHeader."Document Type"::Order);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise: Calculate VAT Amount.
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceLine.CalcVATAmountLines(SalesInvoiceHeader, VATAmountLine);

        // Verify VAT Identifier field on Posted Sales Invoice Statistics (VAT Amount Line Table) and Tear Down VAT Setup.
        VerifyStatisticsAndVATTearDown(VATPostingSetup, VATPostingSetup2, InvoiceDiscountAmount, InvoiceDiscountAmount2, VATIdentifier);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATIdentifierOnSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        InvoiceDiscountAmount: Decimal;
        InvoiceDiscountAmount2: Decimal;
        QtyType: Option General,Invoicing,Shipping;
        VATIdentifier: Code[20];
    begin
        // Verify Invoice Discount and VAT Identifier on Sales Credit Memo for different VAT Posting Groups.

        // Setup: Create Invoice Discount Setup, Create Credit Memo for two different VAT Posting Groups and Calculate Invoice Discount.
        Initialize();
        SetupForVATIdentifier(VATPostingSetup, VATPostingSetup2);
        VATIdentifier :=
          CreateAndCalcSaleInvDisc(
            SalesHeader, SalesLine, InvoiceDiscountAmount, InvoiceDiscountAmount2, SalesHeader."Document Type"::"Credit Memo");

        // Exercise: Calculate VAT Amount.
        SalesLine.CalcVATAmountLines(QtyType::General, SalesHeader, SalesLine, VATAmountLine);

        // Verify VAT Identifier field on Sales Credit Memo Statistics (VAT Amount Line Table) and Tear Down VAT Setup.
        VerifyStatisticsAndVATTearDown(VATPostingSetup, VATPostingSetup2, InvoiceDiscountAmount, InvoiceDiscountAmount2, VATIdentifier);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATIdentifierOnPstdSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        VATAmountLine: Record "VAT Amount Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        InvoiceDiscountAmount: Decimal;
        InvoiceDiscountAmount2: Decimal;
        VATIdentifier: Code[20];
        DocumentNo: Code[20];
    begin
        // Verify Invoice Discount and VAT Identifier on Posted Sales Credit Memo for different VAT Posting Groups.

        // Setup: Create Invoice Discount Setup, Create Credit Memo for two different VAT Posting Groups and Calculate Invoice Discount.
        Initialize();
        SetupForVATIdentifier(VATPostingSetup, VATPostingSetup2);
        VATIdentifier :=
          CreateAndCalcSaleInvDisc(
            SalesHeader, SalesLine, InvoiceDiscountAmount, InvoiceDiscountAmount2, SalesHeader."Document Type"::"Credit Memo");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise: Calculate VAT Amount.
        SalesCrMemoHeader.Get(DocumentNo);
        SalesCrMemoLine.CalcVATAmountLines(SalesCrMemoHeader, VATAmountLine);

        // Verify: Verify VAT Identifier field on Posted Sales Credit Memo Statistics (VAT Amount Line Table) and Tear Down VAT Setup.
        VerifyStatisticsAndVATTearDown(VATPostingSetup, VATPostingSetup2, InvoiceDiscountAmount, InvoiceDiscountAmount2, VATIdentifier);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATIdentifierOnPurchOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATAmountLine: Record "VAT Amount Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        InvoiceDiscountAmount: Decimal;
        InvoiceDiscountAmount2: Decimal;
        QtyType: Option General,Invoicing,Shipping;
        VATIdentifier: Code[20];
    begin
        // Verify Invoice Discount and VAT Identifier on Purchase Order for different VAT Posting Groups.

        // Setup: Create Invoice Discount Setup, Create Purchase Order for two different VAT Posting Groups and Calculate Invoice Discount.
        Initialize();
        SetupForVATIdentifier(VATPostingSetup, VATPostingSetup2);
        VATIdentifier :=
          CreateAndCalcPurchInvDisc(
            PurchaseHeader, PurchaseLine, InvoiceDiscountAmount, InvoiceDiscountAmount2, PurchaseHeader."Document Type"::Order);

        // Exercise: Calculate VAT Amount.
        PurchaseLine.CalcVATAmountLines(QtyType::General, PurchaseHeader, PurchaseLine, VATAmountLine);

        // Verify VAT Identifier field on Purchase Order Statistics (VAT Amount Line Table) and Tear Down VAT Setup.
        VerifyStatisticsAndVATTearDown(VATPostingSetup, VATPostingSetup2, InvoiceDiscountAmount, InvoiceDiscountAmount2, VATIdentifier);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATIdentifierOnPstdPurchInv()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
        VATAmountLine: Record "VAT Amount Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        InvoiceDiscountAmount: Decimal;
        InvoiceDiscountAmount2: Decimal;
        VATIdentifier: Code[20];
        DocumentNo: Code[20];
    begin
        // Verify Invoice Discount and VAT Identifier on Posted Purchase Invoice for different VAT Posting Groups.

        // Setup: Create Invoice Discount Setup, Create Purchase Order for two different VAT Posting Groups and Calculate Invoice Discount.
        Initialize();
        SetupForVATIdentifier(VATPostingSetup, VATPostingSetup2);
        VATIdentifier :=
          CreateAndCalcPurchInvDisc(
            PurchaseHeader, PurchaseLine, InvoiceDiscountAmount, InvoiceDiscountAmount2, PurchaseHeader."Document Type"::Order);
        DocumentNo := PostPurchDocument(PurchaseHeader);

        // Exercise: Calculate VAT Amount.
        PurchInvHeader.Get(DocumentNo);
        PurchInvLine.CalcVATAmountLines(PurchInvHeader, VATAmountLine);

        // Verify VAT Identifier field on Posted Purchase Invoice Statistics (VAT Amount Line Table) and Tear Down VAT Setup.
        VerifyStatisticsAndVATTearDown(VATPostingSetup, VATPostingSetup2, InvoiceDiscountAmount, InvoiceDiscountAmount2, VATIdentifier);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATIdentifierOnPurchCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATAmountLine: Record "VAT Amount Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        InvoiceDiscountAmount: Decimal;
        InvoiceDiscountAmount2: Decimal;
        QtyType: Option General,Invoicing,Shipping;
        VATIdentifier: Code[20];
    begin
        // Verify Invoice Discount and VAT Identifier on Purchase Credit Memo for different VAT Posting Groups.

        // Setup: Create Invoice Discount Setup, Create Credit Memo for two different VAT Posting Groups and Calculate Invoice Discount.
        Initialize();
        SetupForVATIdentifier(VATPostingSetup, VATPostingSetup2);
        VATIdentifier :=
          CreateAndCalcPurchInvDisc(
            PurchaseHeader, PurchaseLine, InvoiceDiscountAmount, InvoiceDiscountAmount2, PurchaseHeader."Document Type"::"Credit Memo");

        // Exercise: Calculate VAT Amount.
        PurchaseLine.CalcVATAmountLines(QtyType::General, PurchaseHeader, PurchaseLine, VATAmountLine);

        // Verify VAT Identifier field on Purchase Credit Memo Statistics (VAT Amount Line Table) and Tear Down VAT Setup.
        VerifyStatisticsAndVATTearDown(VATPostingSetup, VATPostingSetup2, InvoiceDiscountAmount, InvoiceDiscountAmount2, VATIdentifier);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATIdentifierOnPstdPurchCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        VATAmountLine: Record "VAT Amount Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        InvoiceDiscountAmount: Decimal;
        InvoiceDiscountAmount2: Decimal;
        VATIdentifier: Code[20];
        DocumentNo: Code[20];
    begin
        // Verify Invoice Discount and VAT Identifier on Posted Purchase Credit Memo for different VAT Posting Groups.

        // Setup: Create Invoice Discount Setup, Create Credit Memo for two different VAT Posting Groups and Calculate Invoice Discount.
        Initialize();
        SetupForVATIdentifier(VATPostingSetup, VATPostingSetup2);
        VATIdentifier :=
          CreateAndCalcPurchInvDisc(
            PurchaseHeader, PurchaseLine, InvoiceDiscountAmount, InvoiceDiscountAmount2, PurchaseHeader."Document Type"::"Credit Memo");
        DocumentNo := PostPurchDocument(PurchaseHeader);

        // Exercise: Calculate VAT Amount.
        PurchCrMemoHdr.Get(DocumentNo);
        PurchCrMemoLine.CalcVATAmountLines(PurchCrMemoHdr, VATAmountLine);

        // Verify: Verify VAT Identifier field on Posted Purchase Credit Memo Statistics (VAT Amount Line Table) and Tear Down VAT Setup.
        VerifyStatisticsAndVATTearDown(VATPostingSetup, VATPostingSetup2, InvoiceDiscountAmount, InvoiceDiscountAmount2, VATIdentifier);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountOnSalesOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify VAT Amount on Sales Order Statistics for different VAT Posting Groups.
        Initialize();
        VATAmountOnSalesDoc(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountOnSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify VAT Amount on Sales Credit Memo Statistics for different VAT Posting Groups.
        Initialize();
        VATAmountOnSalesDoc(SalesHeader."Document Type"::"Credit Memo");
    end;

    local procedure VATAmountOnSalesDoc(DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
        QtyType: Option General,Invoicing,Shipping;
        VATAmount: Decimal;
        VATAmount2: Decimal;
        VATPct: Decimal;
    begin
        // Setup: Create Sales Order/Credit Memo for two different VAT Posting Groups and Calculate VAT Amount.
        // Take 1 Fix for Creating 1 Sales Line.
        CreateSalesDocument(SalesHeader, SalesLine, 1, DocumentType);
        VATAmount := SalesLine."Line Amount" * SalesLine."VAT %" / 100;
        VATPct := SalesLine."VAT %";

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, FindItem(SalesLine."VAT Prod. Posting Group"), LibraryRandom.RandInt(10));
        VATAmount2 := SalesLine."Line Amount" * SalesLine."VAT %" / 100;

        // Exercise: Calculate VAT Amount.
        SalesLine.CalcVATAmountLines(QtyType::General, SalesHeader, SalesLine, VATAmountLine);

        // Verify: Verify VAT Amount field on Sales Order/Credit Memo Statistics (VAT Amount Line Table).
        VerifyVATOnStatistics(VATPct, VATAmount);
        VerifyVATOnStatistics(SalesLine."VAT %", VATAmount2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountOnPstdSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        AmountIncludingVAT: Decimal;
        AmountIncludingVAT2: Decimal;
        VATPct: Decimal;
        VATPct2: Decimal;
        DocumentNo: Code[20];
    begin
        // Verify VAT Amount on Posted Sales Invoice for different VAT Posting Groups.

        // Setup: Create Sales Order for two different VAT Posting Groups and Calculate VAT Amount.
        Initialize();
        DocumentNo := VATAmountOnPstdSalesDoc(AmountIncludingVAT, AmountIncludingVAT2, VATPct, VATPct2, SalesHeader."Document Type"::Order);

        // Verify: Verify Amount Including VAT field on Posted Sales Invoice.
        VerifyVATOnPstdSalesInvoice(DocumentNo, VATPct, AmountIncludingVAT);
        VerifyVATOnPstdSalesInvoice(DocumentNo, VATPct2, AmountIncludingVAT2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountOnPstdSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        AmountIncludingVAT: Decimal;
        AmountIncludingVAT2: Decimal;
        VATPct: Decimal;
        VATPct2: Decimal;
        DocumentNo: Code[20];
    begin
        // Verify VAT Amount on Posted Sales Credit Memo for different VAT Posting Groups.

        // Setup: Create Sales Credit Memo for two different VAT Posting Groups and Calculate VAT Amount.
        Initialize();
        DocumentNo :=
          VATAmountOnPstdSalesDoc(AmountIncludingVAT, AmountIncludingVAT2, VATPct, VATPct2, SalesHeader."Document Type"::"Credit Memo");

        // Verify: Verify Amount Including VAT field on Posted Sales Credit Memo.
        VerifyVATOnPstdSalesCrMemo(DocumentNo, VATPct, AmountIncludingVAT);
        VerifyVATOnPstdSalesCrMemo(DocumentNo, VATPct2, AmountIncludingVAT2);
    end;

    local procedure VATAmountOnPstdSalesDoc(var AmountIncludingVAT: Decimal; var AmountIncludingVAT2: Decimal; var VATPct: Decimal; var VATPct2: Decimal; DocumentType: Enum "Sales Document Type"): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verify VAT Amount on Posted Sales Invoice/Credit Memo for different VAT Posting Groups.

        // Setup: Create Sales Credit Memo for two different VAT Posting Groups and Calculate VAT Amount.
        // Take 1 Fix for Creating 1 Sales Line.
        CreateSalesDocument(SalesHeader, SalesLine, 1, DocumentType);
        AmountIncludingVAT := SalesLine."Line Amount" * SalesLine."VAT %" / 100 + SalesLine."Line Amount";
        VATPct := SalesLine."VAT %";

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, FindItem(SalesLine."VAT Prod. Posting Group"), LibraryRandom.RandInt(10));
        AmountIncludingVAT2 := SalesLine."Line Amount" * SalesLine."VAT %" / 100 + SalesLine."Line Amount";
        VATPct2 := SalesLine."VAT %";

        // Exercise: Post Sales Order.
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountOnPurchOrder()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify VAT Amount on Purchase Order Statistics for different VAT Posting Groups.
        Initialize();
        VATAmountOnPurchDoc(PurchaseHeader."Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountOnPurchCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify VAT Amount on Purchase Credit Memo Statistics for different VAT Posting Groups.
        Initialize();
        VATAmountOnPurchDoc(PurchaseHeader."Document Type"::"Credit Memo");
    end;

    local procedure VATAmountOnPurchDoc(DocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATAmountLine: Record "VAT Amount Line";
        QtyType: Option General,Invoicing,Shipping;
        VATAmount: Decimal;
        VATAmount2: Decimal;
        VATPct: Decimal;
    begin
        // Setup: Create Purchase Order for two different VAT Posting Groups and Calculate VAT Amount.
        // Take 1 Fix for Creating 1 Purchase Line.
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, 1, DocumentType);
        VATAmount := PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100;
        VATPct := PurchaseLine."VAT %";

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, FindItem(PurchaseLine."VAT Prod. Posting Group"),
          LibraryRandom.RandInt(10));
        VATAmount2 := PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100;

        // Exercise: Calculate VAT Amount.
        PurchaseLine.CalcVATAmountLines(QtyType::General, PurchaseHeader, PurchaseLine, VATAmountLine);

        // Verify: Verify VAT Amount field on Purchase Order Statistics (VAT Amount Line Table).
        VerifyVATOnStatistics(VATPct, VATAmount);
        VerifyVATOnStatistics(PurchaseLine."VAT %", VATAmount2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountOnPstdPurchInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        AmountIncludingVAT: Decimal;
        AmountIncludingVAT2: Decimal;
        VATPct: Decimal;
        VATPct2: Decimal;
        DocumentNo: Code[20];
    begin
        // Verify VAT Amount on Posted Purchase Invoice for different VAT Posting Groups.
        Initialize();
        DocumentNo :=
          VATAmountOnPstdPurchDoc(AmountIncludingVAT, AmountIncludingVAT2, VATPct, VATPct2, PurchaseHeader."Document Type"::Order);

        // Verify: Verify VAT Amount field on Posted Purchase Invoice.
        VerifyVATOnPstdPurchInvoice(DocumentNo, VATPct, AmountIncludingVAT);
        VerifyVATOnPstdPurchInvoice(DocumentNo, VATPct2, AmountIncludingVAT2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountOnPstdPurchCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        AmountIncludingVAT: Decimal;
        AmountIncludingVAT2: Decimal;
        VATPct: Decimal;
        VATPct2: Decimal;
        DocumentNo: Code[20];
    begin
        // Verify VAT Amount on Posted Purchase Credit Memo for different VAT Posting Groups.
        Initialize();
        DocumentNo :=
          VATAmountOnPstdPurchDoc(AmountIncludingVAT, AmountIncludingVAT2, VATPct, VATPct2, PurchaseHeader."Document Type"::"Credit Memo");

        // Verify: Verify VAT Amount field on Posted Purchase Credit Memo.
        VerifyVATOnPstdPurchCrMemo(DocumentNo, VATPct, AmountIncludingVAT);
        VerifyVATOnPstdPurchCrMemo(DocumentNo, VATPct2, AmountIncludingVAT2);
    end;

    local procedure VATAmountOnPstdPurchDoc(var AmountIncludingVAT: Decimal; var AmountIncludingVAT2: Decimal; var VATPct: Decimal; var VATPct2: Decimal; DocumentType: Enum "Purchase Document Type"): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup: Create Purchase Order/Credit Memo for two different VAT Posting Groups and Calculate VAT Amount.
        // Take 1 Fix for Creating 1 Purchase Line.
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, 1, DocumentType);
        AmountIncludingVAT := PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100 + PurchaseLine."Line Amount";
        VATPct := PurchaseLine."VAT %";

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, FindItem(PurchaseLine."VAT Prod. Posting Group"),
          LibraryRandom.RandInt(10));
        AmountIncludingVAT2 := PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100 + PurchaseLine."Line Amount";
        VATPct2 := PurchaseLine."VAT %";

        // Exercise: Post Purchase Order/Credit Memo.
        exit(PostPurchDocument(PurchaseHeader));
    end;

    [Test]
    [HandlerFunctions('GetReturnShipmentLinesForPurchasePageHandler,PurchaseStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure InvoiceDiscountAmountOnPurchaseCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
        InvoiceDiscountAmount: Decimal;
    begin
        // Check Inv. Discount Amount on Purchase CreditMemo Statistics after Posting Purchase Return Order.

        // Setup: Create Purchase Return Order and Credit Memo.
        Initialize();
        LibraryPurchase.SetCalcInvDiscount(true);
        VendorNo := CreateVendAndInvoiceDiscount();
        InvoiceDiscountAmount := CreateAndPostPurchaseReturnOrder(PurchaseHeader."Document Type"::"Return Order", VendorNo);
        LibraryVariableStorage.Enqueue(InvoiceDiscountAmount);

        // Exercise: Create and Get Shiment Lines for Purchase Credit Memo.
        CreatePurchaseCreditMemoAndGetShipmentLines(PurchaseHeader, VendorNo);

        // Verify: Verify Inv. Discount Amount on Purchase Creditmemo Statistics using Purchase Statistics Page handler.
        PurchaseHeader.CalcInvDiscForHeader();
        PAGE.RunModal(PAGE::"Purchase Statistics", PurchaseHeader);
    end;

    [Test]
    [HandlerFunctions('GetReturnShipmentLinesForPurchasePageHandler')]
    [Scope('OnPrem')]
    procedure InvoiceDiscountAmountOnPostedPurchaseCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
        PostedDocumentNo: Code[20];
        InvoiceDiscountAmount: Decimal;
    begin
        // Check Inv. Discount Amount on Posted Purchase CreditMemo.

        // Setup: Create Purchase Return Order,Credit Memo and Run Get Return Shipment Lines Codeunit for Purchase CreditMemo.
        Initialize();
        LibraryPurchase.SetCalcInvDiscount(true);
        VendorNo := CreateVendAndInvoiceDiscount();
        InvoiceDiscountAmount := CreateAndPostPurchaseReturnOrder(PurchaseHeader."Document Type"::"Return Order", VendorNo);
        CreatePurchaseCreditMemoAndGetShipmentLines(PurchaseHeader, VendorNo);

        // Exercise: Post Purchase Creditmemo.
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Inv. Discount Amount on Posted Purchase Creditmemo.
        VerifyPostedPurchaseCrMemo(PostedDocumentNo, InvoiceDiscountAmount);
    end;

    [Test]
    [HandlerFunctions('GetReturnShipmentLinesForSalesPageHandler,SalesStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure InvoiceDiscountAmountOnSalesCreditMemo()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        InvoiceDiscountAmount: Decimal;
    begin
        // Check Inv. Discount Amount on Sales CreditMemo Statistics after Posting Sales Return Order.

        // Setup: Create Sales Return Order and Credit Memo.
        Initialize();
        LibrarySales.SetCalcInvDiscount(true);
        CustomerNo := CreateCustAndInvoiceDiscount();
        InvoiceDiscountAmount := CreateAndPostSalesReturnOrder(SalesHeader."Document Type"::"Return Order", CustomerNo);
        LibraryVariableStorage.Enqueue(InvoiceDiscountAmount);

        // Exercise: Create and Run Get Return Shipment Lines Codeunit for Sales CreditMemo.
        CreateSalesCreditMemoAndGetShipmentLines(SalesHeader, CustomerNo);

        // Verify: Verify Inv. Discount Amount on Sales Creditmemo Statistics using Sales Statistics Page handler.
        SalesHeader.CalcInvDiscForHeader();
        PAGE.RunModal(PAGE::"Sales Statistics", SalesHeader);
    end;

    [Test]
    [HandlerFunctions('GetReturnShipmentLinesForSalesPageHandler')]
    [Scope('OnPrem')]
    procedure InvoiceDiscountAmountOnPostedSalesCreditMemo()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        PostedDocumentNo: Code[20];
        InvoiceDiscountAmount: Decimal;
    begin
        // Check Inv. Discount Amount on Posted Sales CreditMemo.

        // Setup: Create Sales Return Order,Credit Memo and Run Get Return Shipment Lines Codeunit for Sales CreditMemo.
        Initialize();
        LibrarySales.SetCalcInvDiscount(true);
        CustomerNo := CreateCustAndInvoiceDiscount();
        InvoiceDiscountAmount := CreateAndPostSalesReturnOrder(SalesHeader."Document Type"::"Return Order", CustomerNo);
        CreateSalesCreditMemoAndGetShipmentLines(SalesHeader, CustomerNo);

        // Exercise: Post Sales CreditMemo.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Inv. Discount Amount on Posted Sales Creditmemo.
        VerifyPostedSalesCrMemoInvDisc(PostedDocumentNo, InvoiceDiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineDiscountPctPositiveWhenQuantityDirectUnitCostLineDiscAmountArePositive()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 268348] The "Purchase Line"."Line Discount %" is positive when "Quantity", "Direct Unit Cost" and "Line Discount Amount" are positive
        Initialize();
        CreatePurchaseOrderWithQuantityAndDirectUnitCost(PurchaseLine, 1, 100);
        PurchaseLine.Validate("Line Discount Amount", 50);
        Assert.IsTrue(PurchaseLine."Line Discount %" > 0, LineDscPctErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineDiscountPctErrorWhenQuantityDirectUnitCostArePositiveLineDiscAmountIsNegative()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 268348] Wrong value of "Line Discount %" is reported if validate negative "Line Discount Amount" when "Quantity" and "Direct Unit Cost" are positive.
        Initialize();
        CreatePurchaseOrderWithQuantityAndDirectUnitCost(
          PurchaseLine, LibraryRandom.RandIntInRange(10, 100), LibraryRandom.RandIntInRange(10, 100));
        asserterror PurchaseLine.Validate("Line Discount Amount", -LibraryRandom.RandIntInRange(10, 100));
        Assert.ExpectedError(LineDiscountPctErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineDiscountPctPositiveWhenQuantityIsPositiveDirectUnitCostLineDiscAmountIsNegative()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 268348] The "Purchase Line"."Line Discount %" is positive when "Quantity" is positive, and "Direct Unit Cost" and "Line Discount Amount" are negative
        Initialize();
        CreatePurchaseOrderWithQuantityAndDirectUnitCost(PurchaseLine, 1, -100);
        PurchaseLine.Validate("Line Discount Amount", -50);
        Assert.IsTrue(PurchaseLine."Line Discount %" > 0, LineDscPctErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineDiscountPctErrorWhenQuantityDirectUnitCostLineDiscAmountAreNegative()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 268348] Wrong value of "Line Discount %" is reported if validate negative "Line Discount Amount" when "Quantity" and "Direct Unit Cost" are negative.
        Initialize();
        CreatePurchaseOrderWithQuantityAndDirectUnitCost(
          PurchaseLine, -LibraryRandom.RandIntInRange(10, 100), -LibraryRandom.RandIntInRange(10, 100));
        asserterror PurchaseLine.Validate("Line Discount Amount", -LibraryRandom.RandIntInRange(10, 100));
        Assert.ExpectedError(LineDiscountPctErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineDiscountPctPositiveWhenQuantityDirectUnitCostAreNegativeLineDiscAmountIsPositive()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 268348] The "Purchase Line"."Line Discount %" is positive when "Quantity" and "Direct Unit Cost" are negative, and "Line Discount Amount" are positive
        Initialize();
        CreatePurchaseOrderWithQuantityAndDirectUnitCost(PurchaseLine, -1, -100);
        PurchaseLine.Validate("Line Discount Amount", 50);
        Assert.IsTrue(PurchaseLine."Line Discount %" > 0, LineDscPctErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineDiscountPctErrorWhenQuantityIsNegativeDirectUnitCostLineDiscAmountArePostive()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 268348] Wrong value of "Line Discount %" is reported if validate positive "Line Discount Amount" when "Quantity" is negative and "Direct Unit Cost" is positive.
        Initialize();
        CreatePurchaseOrderWithQuantityAndDirectUnitCost(
          PurchaseLine, -LibraryRandom.RandIntInRange(10, 100), LibraryRandom.RandIntInRange(10, 100));
        asserterror PurchaseLine.Validate("Line Discount Amount", LibraryRandom.RandIntInRange(10, 100));
        Assert.ExpectedError(LineDiscountPctErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineDiscountPctErrorWhenQuantityLineDiscAmountArePositiveDirectUnitCostAreNegative()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 268348] Wrong value of "Line Discount %" is reported if validate positive "Line Discount Amount" when "Quantity" is positive and "Direct Unit Cost" is negative.
        Initialize();
        CreatePurchaseOrderWithQuantityAndDirectUnitCost(
          PurchaseLine, LibraryRandom.RandIntInRange(10, 100), -LibraryRandom.RandIntInRange(10, 100));
        asserterror PurchaseLine.Validate("Line Discount Amount", LibraryRandom.RandIntInRange(10, 100));
        Assert.ExpectedError(LineDiscountPctErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineDiscountPctPositiveWhenQuantityLineDiscAmountAreNegativeDirectUnitCostArePositive()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 268348] The "Purchase Line"."Line Discount %" is positive when "Quantity" and "Line Discount Amount" are negative, and "Direct Unit Cost" is positive
        Initialize();
        CreatePurchaseOrderWithQuantityAndDirectUnitCost(PurchaseLine, -1, 100);
        PurchaseLine.Validate("Line Discount Amount", -50);
        Assert.IsTrue(PurchaseLine."Line Discount %" > 0, LineDscPctErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineDiscountPctErrorWhenLineDiscountPctMoreThan100()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 268348] Wrong value of "Line Discount %" is reported when validate "Line Discount Amount" and the calculated "Line Discount %" more than 100
        Initialize();
        CreatePurchaseOrderWithQuantityAndDirectUnitCost(PurchaseLine, 1, 100);
        asserterror PurchaseLine.Validate("Line Discount Amount", 150);
        Assert.ExpectedError(LineDiscountPctErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineDiscountPctErrorWhenLineAmountMoreThanAmount()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 268348] Wrong value of "Line Discount %" is reported when validate "Line Amount" and the calculated "Line Discount %" less than 0
        Initialize();
        CreatePurchaseOrderWithQuantityAndDirectUnitCost(PurchaseLine, 1, 100);
        asserterror PurchaseLine.Validate("Line Amount", PurchaseLine.Amount * 2);
        Assert.ExpectedError(LineAmountInvalidErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineDiscountPctWhenLineAmountIsPositiveAndLessThanAmount()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 268348]  The "Sales Line"."Line Discount %" is positive when "Line Amount" is positive and less than "Amount"
        Initialize();
        CreatePurchaseOrderWithQuantityAndDirectUnitCost(PurchaseLine, 1, 100);
        PurchaseLine.Validate("Line Amount", PurchaseLine.Amount / 2);
        Assert.IsTrue(PurchaseLine."Line Discount %" in [1 .. 100], LineDscPctErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineDiscountPctErrorWhenLineAmountIsNegative()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 268348] Wrong value of "Line Discount %" is reported when validate "Line Amount" and the calculated "Line Discount %" is more than 100
        Initialize();
        CreatePurchaseOrderWithQuantityAndDirectUnitCost(PurchaseLine, 1, 100);
        asserterror PurchaseLine.Validate("Line Amount", -PurchaseLine.Amount);
        Assert.ExpectedError(LineAmountInvalidErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLineDiscountPctPositiveWhenQuantityUnitPriceLineDiscAmountArePositive()
    var
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [UT] [Service]
        // [SCENARIO 268348] The "Service Line"."Line Discount %" is positive when "Quantity", "Unit Price" and "Line Discount Amount" are positive
        Initialize();
        CreateServiceOrderWithQuantityAndUnitPrice(ServiceLine, 1, 100);
        ServiceLine.Validate("Line Discount Amount", 50);
        Assert.IsTrue(ServiceLine."Line Discount %" > 0, LineDscPctErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLineDiscountPctErrorWhenQuantityUnitPriceArePositiveLineDiscAmountIsNegative()
    var
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [UT] [Service]
        // [SCENARIO 268348] Wrong value of "Line Discount %" is reported if validate negative "Line Discount Amount" when "Quantity" and "Unit Price" are positive.
        Initialize();
        CreateServiceOrderWithQuantityAndUnitPrice(
          ServiceLine, LibraryRandom.RandIntInRange(10, 100), LibraryRandom.RandIntInRange(10, 100));
        asserterror ServiceLine.Validate("Line Discount Amount", -LibraryRandom.RandIntInRange(10, 100));
        Assert.ExpectedError(LineDiscountPctErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLineDiscountPctPositiveWhenQuantityIsPositiveUnitPriceLineDiscAmountIsNegative()
    var
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [UT] [Service]
        // [SCENARIO 268348] The "Service Line"."Line Discount %" is positive when "Quantity" is positive, and "Unit Price" and "Line Discount Amount" are negative
        Initialize();
        CreateServiceOrderWithQuantityAndUnitPrice(ServiceLine, 1, -100);
        ServiceLine.Validate("Line Discount Amount", -50);
        Assert.IsTrue(ServiceLine."Line Discount %" > 0, LineDscPctErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLineDiscountPctErrorWhenQuantityLineDiscAmountArePositiveUnitPriceAreNegative()
    var
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [UT] [Service]
        // [SCENARIO 268348] Wrong value of "Line Discount %" is reported if validate positive "Line Discount Amount" when "Quantity" is positive and "Unit Price" is negative.
        Initialize();
        CreateServiceOrderWithQuantityAndUnitPrice(
          ServiceLine, LibraryRandom.RandIntInRange(10, 100), -LibraryRandom.RandIntInRange(10, 100));
        asserterror ServiceLine.Validate("Line Discount Amount", LibraryRandom.RandIntInRange(10, 100));
        Assert.ExpectedError(LineDiscountPctErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLineDiscountPctErrorWhenLineDiscountPctMoreThan100()
    var
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [UT] [Service]
        // [SCENARIO 268348] Wrong value of "Line Discount %" is reported when validate "Line Discount Amount" and the calculated "Line Discount %" more than 100
        Initialize();
        CreateServiceOrderWithQuantityAndUnitPrice(ServiceLine, 1, 100);
        asserterror ServiceLine.Validate("Line Discount Amount", 150);
        Assert.ExpectedError(LineDiscountPctErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLineDiscountPctErrorWhenLineAmountMoreThanAmount()
    var
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [UT] [Service]
        // [SCENARIO 268348] Wrong value of "Line Discount %" is reported when validate "Line Amount" and the calculated "Line Discount %" less than 0
        Initialize();
        CreateServiceOrderWithQuantityAndUnitPrice(ServiceLine, 1, 100);
        asserterror ServiceLine.Validate("Line Amount", ServiceLine.Amount * 2);
        Assert.ExpectedError(LineDiscountPctErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLineDiscountPctWhenLineAmountIsPositiveAndLessThanAmount()
    var
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [UT] [Service]
        // [SCENARIO 268348]  The "Sales Line"."Line Discount %" is positive when "Line Amount" is positive and less than "Amount"
        Initialize();
        CreateServiceOrderWithQuantityAndUnitPrice(ServiceLine, 1, 100);
        ServiceLine.Validate("Line Amount", ServiceLine.Amount / 2);
        Assert.IsTrue(ServiceLine."Line Discount %" in [1 .. 100], LineDscPctErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLineDiscountPctErrorWhenLineAmountIsNegative()
    var
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [UT] [Service]
        // [SCENARIO 268348] Wrong value of "Line Discount %" is reported when validate "Line Amount" and the calculated "Line Discount %" is more than 100
        Initialize();
        CreateServiceOrderWithQuantityAndUnitPrice(ServiceLine, 1, 100);
        asserterror ServiceLine.Validate("Line Amount", -ServiceLine.Amount);
        Assert.ExpectedError(LineDiscountPctErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLineDiscountWhenPostItemCharge()
    var
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        ItemChargeSalesLine: Record "Sales Line";
        SalesHeaderInvoice: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ValueEntry: Record "Value Entry";
    begin
        // [FEATURE] [Sales Invoice] [Item Charge] [Line Discount] [Posting]
        // [SCENARIO 333460] Line Discount for assigned Item Charge is considered when posting a sales document
        Initialize();

        // [GIVEN] Creatd Item and Item Charge
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item, LibraryRandom.RandInt(100), LibraryRandom.RandInt(100));

        // [GIVEN] Created Sales Invoice with two lines for Item and Item Charge
        LibrarySales.CreateSalesHeader(SalesHeaderInvoice, SalesHeaderInvoice."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeaderInvoice, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        LibrarySales.CreateSalesLine(
          ItemChargeSalesLine, SalesHeaderInvoice, SalesLine.Type::"Charge (Item)", ItemCharge."No.", LibraryRandom.RandInt(10));
        ItemChargeSalesLine.Validate("Unit Price", LibraryRandom.RandInt(10));
        ItemChargeSalesLine.Validate("Line Amount", LibraryRandom.RandInt(10));
        ItemChargeSalesLine.Validate("Line Discount %", LibraryRandom.RandInt(10));
        ItemChargeSalesLine.Modify(true);

        // [GIVEN] Item Charge assigned to Item
        LibrarySales.CreateItemChargeAssignment(
          ItemChargeAssignmentSales, ItemChargeSalesLine, ItemCharge, SalesHeaderInvoice."Document Type", SalesHeaderInvoice."No.",
          SalesLine."Line No.", SalesLine."No.", ItemChargeSalesLine.Quantity, LibraryRandom.RandInt(100));
        ItemChargeAssignmentSales.Insert(true);

        // [WHEN] Post Sales Invoice
        LibrarySales.PostSalesDocument(SalesHeaderInvoice, false, false);

        // [THEN] Get Value Entry, its "Discount Amount" is calculated correctly
        ValueEntry.SetFilter("Item No.", Item."No.");
        ValueEntry.FindLast();
        Assert.AreEqual(
          (-ItemChargeSalesLine."Inv. Discount Amount" - ItemChargeSalesLine."Line Discount Amount") /
          ItemChargeSalesLine."Quantity (Base)" * ItemChargeAssignmentSales."Qty. to Assign",
          ValueEntry."Discount Amount", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLineDiscountWhenPostItemChargeLCY()
    var
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        ItemChargeSalesLine: Record "Sales Line";
        SalesHeaderInvoice: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ValueEntry: Record "Value Entry";
    begin
        // [FEATURE] [Sales Invoice] [Item Charge] [Line Discount] [Posting] [Currency]
        // [SCENARIO 333460] Line Discount for assigned Item Charge is considered when posting a sales document with Current Currency
        Initialize();

        // [GIVEN] Creatd Item and Item Charge
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item, LibraryRandom.RandInt(100), LibraryRandom.RandInt(100));

        // [GIVEN] Created Sales Invoice with Currency setup, two lines for Item and Item Charge
        LibrarySales.CreateSalesHeader(SalesHeaderInvoice, SalesHeaderInvoice."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeaderInvoice.Validate("Currency Code", LibraryERM.CreateCurrencyWithRandomExchRates());
        SalesHeaderInvoice.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeaderInvoice, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        LibrarySales.CreateSalesLine(
          ItemChargeSalesLine, SalesHeaderInvoice, SalesLine.Type::"Charge (Item)", ItemCharge."No.", LibraryRandom.RandInt(10));
        ItemChargeSalesLine.Validate("Unit Price", LibraryRandom.RandInt(10));
        ItemChargeSalesLine.Validate("Line Amount", LibraryRandom.RandInt(10));
        ItemChargeSalesLine.Validate("Line Discount %", LibraryRandom.RandInt(10));
        ItemChargeSalesLine.Modify(true);

        // [GIVEN] Item Charge assigned to Item
        LibrarySales.CreateItemChargeAssignment(
          ItemChargeAssignmentSales, ItemChargeSalesLine, ItemCharge, SalesHeaderInvoice."Document Type", SalesHeaderInvoice."No.",
          SalesLine."Line No.", SalesLine."No.", ItemChargeSalesLine.Quantity, LibraryRandom.RandInt(100));
        ItemChargeAssignmentSales.Insert(true);

        // [WHEN] Post Sales Invoice
        LibrarySales.PostSalesDocument(SalesHeaderInvoice, false, false);

        // [THEN] Get Value Entry, its "Discount Amount" is calculated correctly
        ValueEntry.SetFilter("Item No.", Item."No.");
        ValueEntry.FindLast();
        Assert.AreEqual(
          (-ItemChargeSalesLine."Inv. Discount Amount" - ItemChargeSalesLine."Line Discount Amount") /
          ItemChargeSalesLine."Quantity (Base)" * ItemChargeAssignmentSales."Qty. to Assign" / SalesHeaderInvoice."Currency Factor",
          ValueEntry."Discount Amount", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineDiscountWhenPostItemCharge()
    var
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ItemChargePurchaseLine: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
    begin
        // [FEATURE] [Purchase Invoice] [Item Charge] [Line Discount] [Posting]
        // [SCENARIO 333460] Line Discount for assigned Item Charge is considered when posting a purchase document
        Initialize();

        // [GIVEN] Creatd Item and Item Charge
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item, LibraryRandom.RandInt(100), LibraryRandom.RandInt(100));

        // [GIVEN] Created Purchase Invoice with two lines for Item and Item Charge
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeaderInvoice, PurchaseLine, PurchaseHeaderInvoice."Document Type"::Invoice,
          LibraryPurchase.CreateVendorNo(), Item."No.", LibraryRandom.RandInt(10), '', 0D);
        LibraryPurchase.CreatePurchaseLine(
          ItemChargePurchaseLine, PurchaseHeaderInvoice, ItemChargePurchaseLine.Type::"Charge (Item)",
          ItemCharge."No.", LibraryRandom.RandInt(10));
        ItemChargePurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(10));
        ItemChargePurchaseLine.Validate(Amount, LibraryRandom.RandInt(10));
        ItemChargePurchaseLine.Validate("Line Discount %", LibraryRandom.RandInt(10));
        ItemChargePurchaseLine.Modify(true);

        // [GIVEN] Item Charge assigned to Item
        LibraryPurchase.CreateItemChargeAssignment(
          ItemChargeAssignmentPurch, ItemChargePurchaseLine, ItemCharge, PurchaseHeaderInvoice."Document Type", PurchaseHeaderInvoice."No.",
          PurchaseLine."Line No.", PurchaseLine."No.", ItemChargePurchaseLine.Quantity, LibraryRandom.RandInt(100));
        ItemChargeAssignmentPurch.Insert(true);

        // [WHEN] Post Purchase Invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, false);

        // [THEN] Get Value Entry, its "Discount Amount" is calculated correctly
        ValueEntry.SetFilter("Item No.", Item."No.");
        ValueEntry.FindLast();
        Assert.AreEqual(
          (ItemChargePurchaseLine."Inv. Discount Amount" + ItemChargePurchaseLine."Line Discount Amount") /
          ItemChargePurchaseLine."Quantity (Base)" * ItemChargeAssignmentPurch."Qty. to Assign",
          ValueEntry."Discount Amount", '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PurchaseLineDiscountWhenPostItemChargeLCY()
    var
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ItemChargePurchaseLine: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ValueEntry: Record "Value Entry";
    begin
        // [FEATURE] [Purchase Invoice] [Item Charge] [Line Discount] [Posting] [Currency]
        // [SCENARIO 333460] Line Discount for assigned Item Charge is considered when posting a purchase document with Current Currency
        Initialize();

        // [GIVEN] Creatd Item and Item Charge
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item, LibraryRandom.RandInt(100), LibraryRandom.RandInt(100));

        // [GIVEN] Created Purchase Invoice with Currency setup, two lines for Item and Item Charge
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeaderInvoice, PurchaseLine, PurchaseHeaderInvoice."Document Type"::Invoice,
          LibraryPurchase.CreateVendorNo(), Item."No.", LibraryRandom.RandInt(10), '', 0D);
        PurchaseHeaderInvoice.Validate("Currency Code", LibraryERM.CreateCurrencyWithRandomExchRates());
        PurchaseHeaderInvoice.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          ItemChargePurchaseLine, PurchaseHeaderInvoice, ItemChargePurchaseLine.Type::"Charge (Item)",
          ItemCharge."No.", LibraryRandom.RandInt(10));
        ItemChargePurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(10));
        ItemChargePurchaseLine.Validate(Amount, LibraryRandom.RandInt(10));
        ItemChargePurchaseLine.Validate("Line Discount %", LibraryRandom.RandInt(10));
        ItemChargePurchaseLine.Modify(true);

        // [GIVEN] Item Charge assigned to Item
        LibraryPurchase.CreateItemChargeAssignment(
          ItemChargeAssignmentPurch, ItemChargePurchaseLine, ItemCharge, PurchaseHeaderInvoice."Document Type", PurchaseHeaderInvoice."No.",
          PurchaseLine."Line No.", PurchaseLine."No.", ItemChargePurchaseLine.Quantity, LibraryRandom.RandInt(100));
        ItemChargeAssignmentPurch.Insert(true);

        // [WHEN] Post Purchase Invoice
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, false, false);

        // [THEN] Get Value Entry, its "Discount Amount" is calculated correctly
        ValueEntry.SetFilter("Item No.", Item."No.");
        ValueEntry.FindLast();
        Assert.AreEqual(
          (ItemChargePurchaseLine."Inv. Discount Amount" + ItemChargePurchaseLine."Line Discount Amount") /
          ItemChargePurchaseLine."Quantity (Base)" * ItemChargeAssignmentPurch."Qty. to Assign" /
          PurchaseHeaderInvoice."Currency Factor",
          ValueEntry."Discount Amount", '');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Inv Disc VAT Sale/Purchase");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Inv Disc VAT Sale/Purchase");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Inv Disc VAT Sale/Purchase");
    end;

    local procedure CreateSalesOrderAndCalcInvDisc(var SalesHeader: Record "Sales Header"; var InvDiscAmt: Decimal; DocumentType: Enum "Sales Document Type"): Decimal
    var
        SalesLine: Record "Sales Line";
        SalesCalcDiscount: Codeunit "Sales-Calc. Discount";
    begin
        // Setup: Create Sales Order and Calculate Invoice Discount with Multiple Sales Line.
        CreateSalesDocument(SalesHeader, SalesLine, LibraryRandom.RandInt(5), DocumentType);
        SalesCalcDiscount.Run(SalesLine);
        InvDiscAmt := CalculateSalesInvDiscAmount(SalesHeader);
        exit(SalesLine."VAT %");
    end;

    local procedure CreatePurchOrderAndCalcInvDisc(var PurchaseHeader: Record "Purchase Header"; var InvDiscAmt: Decimal; DocumentType: Enum "Purchase Document Type"): Decimal
    var
        PurchaseLine: Record "Purchase Line";
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
    begin
        // Setup: Create Purchase Order and Calculate Invoice Discount with multiple Purchase Line.
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, LibraryRandom.RandInt(5), DocumentType);
        PurchCalcDiscount.Run(PurchaseLine);
        InvDiscAmt := CalculatePurchaseInvDiscAmount(PurchaseHeader);
        exit(PurchaseLine."VAT %");
    end;

    local procedure CreateAndPostGenJournalLine(CustomerNo: Code[20]; AccountType: Enum "Gen. Journal Account Type"; AppliestoDocNo: Code[20]; Amount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          AccountType, CustomerNo, Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliestoDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndCalcSaleInvDisc(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var InvoiceDiscountAmount: Decimal; var InvoiceDiscountAmount2: Decimal; DocumentType: Enum "Sales Document Type"): Code[10]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindVATPostingSetup(VATPostingSetup);
        CreateSalesOrderAndCalcInvDisc(SalesHeader, InvoiceDiscountAmount, DocumentType);
        InvoiceDiscountAmount2 :=
          CreateSalesLineAndCalcInvDisc(SalesHeader, SalesLine, FindItem(VATPostingSetup."VAT Prod. Posting Group"));
        exit(FindVATIdentifier(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group"));
    end;

    local procedure CreateAndCalcPurchInvDisc(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var InvoiceDiscountAmount: Decimal; var InvoiceDiscountAmount2: Decimal; DocumentType: Enum "Purchase Document Type"): Code[10]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindVATPostingSetup(VATPostingSetup);
        CreatePurchOrderAndCalcInvDisc(PurchaseHeader, InvoiceDiscountAmount, DocumentType);
        InvoiceDiscountAmount2 :=
          CreatePurchLineAndCalcInvDisc(PurchaseHeader, PurchaseLine, FindItem(VATPostingSetup."VAT Prod. Posting Group"));
        exit(FindVATIdentifier(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group"));
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; NoOfLines: Integer; DocumentType: Enum "Sales Document Type")
    var
        "Count": Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustAndInvoiceDiscount());
        for Count := 1 to NoOfLines do begin
            ;  // Create Multiple Sales Line with Random Qty and Price.
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
            SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
            SalesLine.Modify(true);
        end;
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; NoOFLines: Integer; DocumentType: Enum "Purchase Document Type")
    var
        "Count": Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendAndInvoiceDiscount());
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        for Count := 1 to NoOFLines do begin
            ;  // Create Multiple Purchase Line with Random Qty and Unit Cost.
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
            PurchaseLine.Modify(true);
        end;
    end;

    local procedure CreateCustomerInvDiscount(CustomerNo: Code[20])
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CustomerNo, '', 0);  // Set Zero for Charge Amount.
        CustInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(10, 2));  // Take Random Discount.
        CustInvoiceDisc.Modify(true);
    end;

    local procedure CreateVendorInvDiscount(VendorNo: Code[20])
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, VendorNo, '', 0); // Set Zero for Charge Amount.
        VendorInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(10, 2));  // Take Random Discount.
        VendorInvoiceDisc.Modify(true);
    end;

    local procedure CreateAndPostPurchaseReturnOrder(DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]): Decimal
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        PurchCalcDiscount.CalculateInvoiceDiscount(PurchaseHeader, PurchaseLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        exit(PurchaseLine."Inv. Discount Amount");
    end;

    local procedure CreateAndPostSalesReturnOrder(DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]): Decimal
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);
        SalesLine2.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        exit(SalesLine2."Inv. Discount Amount");
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

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; No: Code[20]; Quantity: Decimal; UnitPrice: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineAndCalcInvDisc(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]): Decimal
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        SalesCalcDiscount: Codeunit "Sales-Calc. Discount";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
        SalesCalcDiscount.Run(SalesLine);
        CustInvoiceDisc.SetRange(Code, SalesLine."Sell-to Customer No.");
        CustInvoiceDisc.FindFirst();
        exit(Round(SalesLine."Line Amount" * CustInvoiceDisc."Discount %" / 100));
    end;

    local procedure CreatePurchLineAndCalcInvDisc(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]): Decimal
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(50, 2));
        PurchaseLine.Modify(true);
        PurchCalcDiscount.Run(PurchaseLine);
        VendorInvoiceDisc.SetRange(Code, PurchaseLine."Buy-from Vendor No.");
        VendorInvoiceDisc.FindFirst();
        exit(Round(PurchaseLine."Line Amount" * VendorInvoiceDisc."Discount %" / 100));
    end;

    local procedure CreateCustAndInvoiceDiscount(): Code[20]
    var
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindVATPostingSetup(VATPostingSetup);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        CreateCustomerInvDiscount(Customer."No.");
        exit(Customer."No.");
    end;

    local procedure CreateVendAndInvoiceDiscount(): Code[20]
    var
        Vendor: Record Vendor;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindVATPostingSetup(VATPostingSetup);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
        CreateVendorInvDiscount(Vendor."No.");
        exit(Vendor."No.");
    end;

    local procedure CreatePurchaseCreditMemoAndGetShipmentLines(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);
        PurchaseHeader.Validate(
          "Vendor Cr. Memo No.",
          CopyStr(LibraryUtility.GenerateRandomCode(PurchaseHeader.FieldNo("Vendor Invoice No."), DATABASE::"Purchase Header"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Purchase Header", PurchaseHeader.FieldNo("Vendor Invoice No."))));
        PurchaseHeader.Modify(true);
        PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
        CODEUNIT.Run(CODEUNIT::"Purch.-Get Return Shipments", PurchaseLine);
    end;

    local procedure CreateSalesCreditMemoAndGetShipmentLines(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        CODEUNIT.Run(CODEUNIT::"Sales-Get Return Receipts", SalesLine);
    end;

    local procedure CalculateSalesInvDiscAmount(SalesHeader: Record "Sales Header") InvDiscountAmount: Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
        repeat
            InvDiscountAmount += SalesLine."Inv. Discount Amount";
        until SalesLine.Next() = 0;
    end;

    local procedure CalculatePurchaseInvDiscAmount(PurchaseHeader: Record "Purchase Header") InvDiscountAmount: Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindSet();
        repeat
            InvDiscountAmount += PurchaseLine."Inv. Discount Amount";
        until PurchaseLine.Next() = 0;
    end;

    local procedure FindCustomerInvoiceDiscount("Code": Code[20]): Decimal
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        CustInvoiceDisc.SetRange(Code, Code);
        CustInvoiceDisc.FindFirst();
        exit(CustInvoiceDisc."Discount %");
    end;

    local procedure FindItem(VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Not using Library Item Finder method to make this funtion World ready.
        FindVATPostingSetup(VATPostingSetup);
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', VATProdPostingGroup);
        VATPostingSetup.FindFirst();
        LibraryInventory.CreateItem(Item);
        Item.Validate(Blocked, false);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(100, 2)); // Using Random for Random Decimal value.
        Item.Validate("Unit Price", Item."Last Direct Cost");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure FindVATIdentifier(VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(VATBusPostingGroup, VATProdPostingGroup);
        exit(VATPostingSetup."VAT Identifier");
    end;

    local procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
    end;

    local procedure FindVendorInvoiceDiscount("Code": Code[20]): Decimal
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        VendorInvoiceDisc.SetRange(Code, Code);
        VendorInvoiceDisc.FindFirst();
        exit(VendorInvoiceDisc."Discount %");
    end;

    local procedure ModifyPurchaseLine(var PurchaseLine: Record "Purchase Line")
    begin
        // Taken Random Amount for invoice Disocunt Amount.
        PurchaseLine.Validate("Inv. Discount Amount", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure ModifyAllowInvoiceDiscInItem(): Code[20]
    var
        Item: Record Item;
    begin
        Item.Get(CreateItem());
        Item.Validate("Allow Invoice Disc.", false);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure PostPurchDocument(PurchaseHeader: Record "Purchase Header"): Code[20]
    begin
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true))
    end;

    local procedure SetupForVATIdentifier(var VATPostingSetup: Record "VAT Posting Setup"; var VATPostingSetup2: Record "VAT Posting Setup")
    var
        GLAccount: Record "G/L Account";
    begin
        FindVATPostingSetup(VATPostingSetup);
        LibraryERM.FindGLAccount(GLAccount);
        VATPostingSetup2.Get(VATPostingSetup."VAT Bus. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        UpdateVATPostingSetup(VATPostingSetup2, GLAccount."No.", GLAccount."No.");
    end;

    local procedure UpdateItemWithVATProdPostingGroup(ItemNo: Code[20]; VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure UpdateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; SalesVATAccount: Code[20]; PurchaseVATAccount: Code[20])
    begin
        VATPostingSetup.Validate("VAT Identifier", VATPostingSetup."VAT Prod. Posting Group");
        VATPostingSetup.Validate("Sales VAT Account", SalesVATAccount);
        VATPostingSetup.Validate("Purchase VAT Account", PurchaseVATAccount);
        VATPostingSetup.Modify(true);
    end;

    local procedure UpdateSalesCalcInvDiscPerVATID(var OldCalcInvDiscPerVATID: Boolean; CalcInvDiscPerVATID: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldCalcInvDiscPerVATID := SalesReceivablesSetup."Calc. Inv. Disc. per VAT ID";
        SalesReceivablesSetup.Validate("Calc. Inv. Disc. per VAT ID", CalcInvDiscPerVATID);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdatePurchCalcInvDiscPerVATID(var OldCalcInvDiscPerVATID: Boolean; CalcInvDiscPerVATID: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        OldCalcInvDiscPerVATID := PurchasesPayablesSetup."Calc. Inv. Disc. per VAT ID";
        PurchasesPayablesSetup.Validate("Calc. Inv. Disc. per VAT ID", CalcInvDiscPerVATID);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithQuantityAndDirectUnitCost(var PurchaseLine: Record "Purchase Line"; Quanitiy: Integer; DirectUnitCost: Integer)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), Quanitiy);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
    end;

    local procedure CreateServiceOrderWithQuantityAndUnitPrice(var ServiceLine: Record "Service Line"; Quanitiy: Integer; UnitPrice: Integer)
    var
        ServiceHeader: Record "Service Header";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        ServiceLine.Validate(Quantity, Quanitiy);
        ServiceLine.Validate("Unit Price", UnitPrice);
    end;

    local procedure VerifyStatisticsAndVATTearDown(VATPostingSetup: Record "VAT Posting Setup"; VATPostingSetup2: Record "VAT Posting Setup"; InvoiceDiscountAmount: Decimal; InvoiceDiscountAmount2: Decimal; VATIdentifier: Code[20])
    begin
        // Verify: Verify VAT Identifier field on Sales/Purchase Statistics (VAT Amount Line Table).
        VerifyDocumentStatistics(VATPostingSetup2."VAT Identifier", InvoiceDiscountAmount);
        VerifyDocumentStatistics(VATIdentifier, InvoiceDiscountAmount2);

        // Tear Down: Rollback VAT Posting Setup.
        UpdateVATPostingSetup(VATPostingSetup2, VATPostingSetup."Sales VAT Account", VATPostingSetup."Purchase VAT Account");
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; Base: Decimal; Type: Enum "General Posting Type")
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange(Type, Type);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange(Base, Base);
        Assert.IsTrue(VATEntry.FindFirst(), StrSubstNo(ErrorAmount, Base, DocumentNo));
    end;

    local procedure VerifyGLEntry(DocumentType: Option; DocumentNo: Code[20]; Amount: Decimal; VATAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLEntry: Record "G/L Entry";
    begin
        GeneralLedgerSetup.Get();
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange(Amount, Amount);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          VATAmount, GLEntry."VAT Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, GLEntry.FieldCaption("VAT Amount"), VATAmount, GLEntry.TableCaption()));
    end;

    local procedure VerifyGLAndVATEntry(DocumentNo: Code[20]; InvoiceDiscountAmount: Decimal; VATAmount: Decimal; Type: Enum "General Posting Type")
    var
        SalesHeader: Record "Sales Header";
    begin
        VerifyGLEntry(SalesHeader."Document Type"::Invoice.AsInteger(), DocumentNo, InvoiceDiscountAmount, VATAmount);
        VerifyVATEntry(DocumentNo, InvoiceDiscountAmount, Type);
    end;

    local procedure VerifyVATAmountLine(ExpectVATAmount: Decimal; ActualVATAmount: Decimal)
    var
        VATAmountLine: Record "VAT Amount Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        Assert.AreNearlyEqual(
          ExpectVATAmount, ActualVATAmount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, VATAmountLine.FieldCaption("VAT Amount"), ExpectVATAmount, VATAmountLine.TableCaption()));
    end;

    local procedure VerifyVATAmountLineForInvDisc(ActualInvDiscountAmount: Decimal; ExpectedInvDiscountAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATAmountLine: Record "VAT Amount Line";
    begin
        GeneralLedgerSetup.Get();
        Assert.AreNearlyEqual(
          ExpectedInvDiscountAmount, ActualInvDiscountAmount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, VATAmountLine.FieldCaption("Invoice Discount Amount"), ExpectedInvDiscountAmount,
            VATAmountLine.TableCaption()));
    end;

    local procedure VerifyPostedSalesCrMemo(DocumentNo: Code[20]; LineDiscountAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        GeneralLedgerSetup.Get();
        SalesCrMemoLine.SetRange("Document No.", DocumentNo);
        SalesCrMemoLine.FindFirst();
        Assert.AreNearlyEqual(
          LineDiscountAmount, SalesCrMemoLine."Line Discount Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, SalesCrMemoLine.FieldCaption("Line Discount Amount"), LineDiscountAmount, SalesCrMemoLine.TableCaption()));
    end;

    local procedure VerifyPostedSalesCrMemoInvDisc(DocumentNo: Code[20]; InvDiscountAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        GeneralLedgerSetup.Get();
        SalesCrMemoLine.SetRange("Document No.", DocumentNo);
        SalesCrMemoLine.SetRange(Type, SalesCrMemoLine.Type::Item);
        SalesCrMemoLine.FindFirst();
        Assert.AreNearlyEqual(
          InvDiscountAmount, SalesCrMemoLine."Inv. Discount Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, SalesCrMemoLine.FieldCaption("Inv. Discount Amount"), InvDiscountAmount, SalesCrMemoLine.TableCaption()));
    end;

    local procedure VerifyPostedPurchaseInvoice(InvDiscountAmount: Decimal; OrderNo: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        GeneralLedgerSetup.Get();
        PurchInvHeader.SetRange("Order No.", OrderNo);
        PurchInvHeader.FindFirst();
        PurchInvLine.SetRange("Document No.", PurchInvHeader."No.");
        PurchInvLine.FindFirst();
        Assert.AreNearlyEqual(
          InvDiscountAmount, PurchInvLine."Inv. Discount Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, PurchInvLine.FieldCaption("Inv. Discount Amount"), InvDiscountAmount, PurchInvLine.TableCaption()));
    end;

    local procedure VerifyPostedPurchaseCrMemo(DocumentNo: Code[20]; InvDiscountAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        GeneralLedgerSetup.Get();
        PurchCrMemoLine.SetRange("Document No.", DocumentNo);
        PurchCrMemoLine.SetRange(Type, PurchCrMemoLine.Type::Item);
        PurchCrMemoLine.FindFirst();
        Assert.AreNearlyEqual(
          InvDiscountAmount, PurchCrMemoLine."Inv. Discount Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountError, PurchCrMemoLine.FieldCaption("Inv. Discount Amount"), InvDiscountAmount, PurchCrMemoLine.TableCaption()));
    end;

    local procedure VerifySalesLineAmount(ExpectedAmount: Decimal; ActualAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesLine: Record "Sales Line";
    begin
        GeneralLedgerSetup.Get();
        Assert.AreNearlyEqual(
          ExpectedAmount, ActualAmount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(ErrorAmount, ExpectedAmount, SalesLine.TableCaption()));
    end;

    local procedure VerifyPurchLineAmount(ExpectedAmount: Decimal; ActualAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseLine: Record "Purchase Line";
    begin
        GeneralLedgerSetup.Get();
        Assert.AreNearlyEqual(
          ExpectedAmount, ActualAmount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(ErrorAmount, ExpectedAmount, PurchaseLine.TableCaption()));
    end;

    local procedure VerifyDocumentStatistics(VATIdentifier: Code[20]; InvoiceDiscountAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATAmountLine: Record "VAT Amount Line";
    begin
        GeneralLedgerSetup.Get();
        VATAmountLine.SetRange("VAT Identifier", VATIdentifier);
        VATAmountLine.FindFirst();
        Assert.AreNearlyEqual(
          InvoiceDiscountAmount, VATAmountLine."Invoice Discount Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(
            AmountError, VATAmountLine.FieldCaption("Invoice Discount Amount"), InvoiceDiscountAmount, VATAmountLine.TableCaption()));
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

    local procedure VerifyVATOnPstdSalesInvoice(DocumentNo: Code[20]; VATPct: Decimal; AmountIncludingVAT: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        GeneralLedgerSetup.Get();
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.SetRange("VAT %", VATPct);
        SalesInvoiceLine.FindFirst();
        Assert.AreNearlyEqual(
          AmountIncludingVAT, SalesInvoiceLine."Amount Including VAT", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(
            AmountError, SalesInvoiceLine.FieldCaption("Amount Including VAT"), AmountIncludingVAT, SalesInvoiceLine.TableCaption()));
    end;

    local procedure VerifyVATOnPstdSalesCrMemo(DocumentNo: Code[20]; VATPct: Decimal; AmountIncludingVAT: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        GeneralLedgerSetup.Get();
        SalesCrMemoLine.SetRange("Document No.", DocumentNo);
        SalesCrMemoLine.SetRange("VAT %", VATPct);
        SalesCrMemoLine.FindFirst();
        Assert.AreNearlyEqual(
          AmountIncludingVAT, SalesCrMemoLine."Amount Including VAT", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(
            AmountError, SalesCrMemoLine.FieldCaption("Amount Including VAT"), AmountIncludingVAT, SalesCrMemoLine.TableCaption()));
    end;

    local procedure VerifyVATOnPstdPurchInvoice(DocumentNo: Code[20]; VATPct: Decimal; AmountIncludingVAT: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchInvLine: Record "Purch. Inv. Line";
    begin
        GeneralLedgerSetup.Get();
        PurchInvLine.SetRange("Document No.", DocumentNo);
        PurchInvLine.SetRange("VAT %", VATPct);
        PurchInvLine.FindFirst();
        Assert.AreNearlyEqual(
          AmountIncludingVAT, PurchInvLine."Amount Including VAT", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(
            AmountError, PurchInvLine.FieldCaption("Amount Including VAT"), AmountIncludingVAT, PurchInvLine.TableCaption()));
    end;

    local procedure VerifyVATOnPstdPurchCrMemo(DocumentNo: Code[20]; VATPct: Decimal; AmountIncludingVAT: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        GeneralLedgerSetup.Get();
        PurchCrMemoLine.SetRange("Document No.", DocumentNo);
        PurchCrMemoLine.SetRange("VAT %", VATPct);
        PurchCrMemoLine.FindFirst();
        Assert.AreNearlyEqual(
          AmountIncludingVAT, PurchCrMemoLine."Amount Including VAT", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(
            AmountError, PurchCrMemoLine.FieldCaption("Amount Including VAT"), AmountIncludingVAT, PurchCrMemoLine.TableCaption()));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetReturnShipmentLinesForSalesPageHandler(var GetReturnShipmentLines: TestPage "Get Return Receipt Lines")
    begin
        GetReturnShipmentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseStatisticsPageHandler(var PurchaseStatistics: TestPage "Purchase Statistics")
    var
        InvoiceDiscountAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(InvoiceDiscountAmount);
        PurchaseStatistics.InvDiscountAmount.AssertEquals(InvoiceDiscountAmount);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsPageHandler(var SalesStatistics: TestPage "Sales Statistics")
    var
        InvoiceDiscountAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(InvoiceDiscountAmount);
        SalesStatistics.InvDiscountAmount.AssertEquals(InvoiceDiscountAmount);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetReturnShipmentLinesForPurchasePageHandler(var GetReturnShipmentLines: TestPage "Get Return Shipment Lines")
    begin
        GetReturnShipmentLines.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Answer: Boolean)
    begin
        Answer := true;
    end;
}

