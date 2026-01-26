codeunit 144076 "ERM Payment Discount"
{
    // // [FEATURE] [Discount]
    //
    // 1. Test to verify Payment Discount Amount on Sales Document - Test report on Sales Order.
    // 2. Test to verify Payment Discount Amount on Sales Invoice Statistics Page.
    // 3. Test to verify Payment Discount Amount on Sales Document - Test report on Sales Invoice.
    // 4. Test to verify Purchase Amount (Actual) on Item Ledger Entry after posting Purchase Order without Payment Discount.
    // 5. Test to verify Purchase Amount (Actual) on Item Ledger Entry after posting Purchase Order without Invoice Discount.
    // 6. Test to verify Purchase Amount (Actual) on Item Ledger Entry after posting Purchase Order with Invoice Discount and Payment Discount.
    // 7. Test to verify Purchase Amount (Actual) on Item Ledger Entry after posting Purchase Order With Line Discount.
    // 8. Test to verify Purchase Amount (Actual) on Value Entry after posting Purchase Order With Payment Discount.
    // 9. Test to verify Purchase Amount (Actual) on Item Ledger Entry after posting Purchase Return Order.
    // 10. Test to verify Purchase Amount (Actual) on Value Entry after posting Purchase Credit Memo.
    // 11. Test to verify Purchase Amount (Actual) on Item Ledger Entry after posting Purchase Order.
    // 12. Test to verify Purchase Amount (Actual) on Value Entry after posting Purchase Invoice.
    // 13. Test to verify Payment Discount Amount on Sales Document - Test report on Sales Credit Memo.
    // 14. Test to verify Payment Discount Amount on Purchase Document - Test report on Purchase Invoice.
    // 15. Test to verify Payment Discount Amount on Purchase Document - Test report on Purchase Credit Memo.
    // 16. Test to verify Payment Discount Amount on Service Statistics Page.
    // 17. Test to verify Payment Discount Amount on Service Credit Memo Statistics Page.
    //
    // Covers Test Cases for WI - 351154.
    // -----------------------------------------------------------
    // Test Function Name                                  TFS ID
    // -----------------------------------------------------------
    // PaymentDiscountOnSalesOrderTestReport                152938
    // PaymentDiscountOnSalesInvoiceStatistics       152939,206395
    // PaymentDiscountOnSalesInvoiceTestReport       154763,206395
    // PurchaseAmountActualOnILEWithoutPaymentDiscount      155431
    // PurchaseAmountActualOnILEWithoutInvoiceDiscount      155432
    // PurchaseAmountActualOnILEWithInvoiceDiscount         155433
    // PurchaseAmountActualOnILEWithLineDiscount            155434
    // PurchaseAmountActualOnValeEntryWithPmtDiscount       155435
    //
    // Covers Test Cases for WI - 351155.
    // -----------------------------------------------------------
    // Test Function Name                                  TFS ID
    // -----------------------------------------------------------
    // PurchaseAmountActualOnILEPostedReturnOrder           169349
    // PurchaseAmountActualOnValueEntryPostedCreditMemo     169350
    // PurchaseAmountActualOnILEPostedPurchaseOrder         169351
    // PurchaseAmountActualOnValueEntryPostedPurchInv       169353
    // PaymentDiscountOnSalesCreditMemoTestReport           206396
    // PaymentDiscountOnPurchaseInvoiceTestReport           206393
    // PaymentDiscountOnPurchaseCreditMemoTestReport        206394
    // PaymentDiscountOnServiceInvoiceStatistics            206397
    // PaymentDiscountOnServiceCreditMemoStatistics         206398

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        AmountMustMatchMsg: Label 'Amount must match.';
        SalesLinePmtDiscGivenAmountCap: Label 'SalesLine__Pmt__Disc__Given_Amount_';
        SumPmtDiscRcdAmountCap: Label 'SumPmtDiscRcdAmount';
        IsInitialize: Boolean;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentDiscountOnSalesOrderTestReport()
    var
        Customer: Record Customer;
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Test to verify Payment Discount Amount on Sales Document - Test report on Sales Order.

        // Setup: Create Customer,Update General Ledger Setup,Create Sales Order and open Sales Order page.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines",
          GeneralLedgerSetup."Discount Calculation"::"Line Disc. * Inv. Disc. * Payment Disc.");
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order, Customer."No.", LibraryRandom.RandDec(10, 2));  // Random for Payment Discount %.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        OpenSalesOrderToCalculatePaymentDiscount(SalesHeader."No.");
        LibraryVariableStorage.Enqueue(Customer."No.");  // Enqueue for SalesDocumentTestRequestPageHandler.
        Commit();  // Commit requires to run report.

        // Exercise.
        REPORT.Run(REPORT::"Sales Document - Test");  // Opens SalesDocumentTestRequestPageHandler.

        // Verify: Verify Payment Discount Amount on Sales Document - Test report.
        VerifyValuesOnReport(
          SalesLinePmtDiscGivenAmountCap, Round(SalesLine."Line Amount" * SalesHeader."Payment Discount %" / 100));

        // TearDown.
        RollBackGeneralLedgerSetup(GeneralLedgerSetup."Payment Discount Type", GeneralLedgerSetup."Discount Calculation");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger.', '26.0')]
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentDiscountOnSalesInvoiceStatistics()
    var
        Customer: Record Customer;
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        PaymentDiscountAmount: Decimal;
    begin
        // Test to verify Payment Discount Amount on Sales Invoice Statistics Page.

        // Setup: Create Customer,Update General Ledger Setup,Create Sales Order.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines",
          GeneralLedgerSetup."Discount Calculation"::"Line Disc. * Inv. Disc. * Payment Disc.");
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Invoice, Customer."No.", LibraryRandom.RandDec(10, 2));  // Random for Payment Discount %.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        CreateSalesLine(SalesLine2, SalesHeader);
        PaymentDiscountAmount := (SalesLine.Amount + SalesLine2.Amount) * SalesHeader."Payment Discount %" / 100;
        LibraryVariableStorage.Enqueue(PaymentDiscountAmount);  // Enqueue for SalesStatisticsModalPageHandler.

        // Exercise.
        OpenSalesInvoiceStatistics(SalesHeader."No.");

        // Verify: verification done in SalesStatisticsModalPageHandler.

        // TearDown.
        RollBackGeneralLedgerSetup(GeneralLedgerSetup."Payment Discount Type", GeneralLedgerSetup."Discount Calculation");
    end;
#endif
    [Test]
    [HandlerFunctions('ConfirmHandler,SalesStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentDiscountOnSalesInvoiceSalesStatistics()
    var
        Customer: Record Customer;
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        PaymentDiscountAmount: Decimal;
    begin
        // Test to verify Payment Discount Amount on Sales Invoice Statistics Page.

        // Setup: Create Customer,Update General Ledger Setup,Create Sales Order.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines",
          GeneralLedgerSetup."Discount Calculation"::"Line Disc. * Inv. Disc. * Payment Disc.");
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Invoice, Customer."No.", LibraryRandom.RandDec(10, 2));  // Random for Payment Discount %.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        CreateSalesLine(SalesLine2, SalesHeader);
        PaymentDiscountAmount := (SalesLine.Amount + SalesLine2.Amount) * SalesHeader."Payment Discount %" / 100;
        LibraryVariableStorage.Enqueue(PaymentDiscountAmount);  // Enqueue for SalesStatisticsPageHandler.

        // Exercise.
        OpenSalesInvoiceSalesStatistics(SalesHeader."No.");

        // Verify: verification done in SalesStatisticsPageHandler.

        // TearDown.
        RollBackGeneralLedgerSetup(GeneralLedgerSetup."Payment Discount Type", GeneralLedgerSetup."Discount Calculation");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentDiscountOnSalesInvoiceTestReport()
    var
        Customer: Record Customer;
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Test to verify Payment Discount Amount on Sales Document - Test report on Sales Invoice.

        // Setup: Create Customer,Update General Ledger Setup,Create Sales Invoice and open Sales Invoice page.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines",
          GeneralLedgerSetup."Discount Calculation"::"Line Disc. * Inv. Disc. * Payment Disc.");
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Invoice, Customer."No.", LibraryRandom.RandDec(10, 2));  // Random for Payment Discount %.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        OpenSalesInvoiceToCalculatePaymentDiscount(SalesHeader."No.");
        LibraryVariableStorage.Enqueue(Customer."No.");  // Enqueue for SalesDocumentTestRequestPageHandler.
        Commit();  // Commit requires to run report.

        // Exercise.
        REPORT.Run(REPORT::"Sales Document - Test");  // Opens SalesDocumentTestRequestPageHandler.

        // Verify: Verify Payment Discount Amount on Sales Document - Test report.
        VerifyValuesOnReport(
          SalesLinePmtDiscGivenAmountCap, Round(SalesLine."Line Amount" * SalesHeader."Payment Discount %" / 100));

        // TearDown.
        RollBackGeneralLedgerSetup(GeneralLedgerSetup."Payment Discount Type", GeneralLedgerSetup."Discount Calculation");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseAmountActualOnILEWithoutPaymentDiscount()
    begin
        // Test to verify Purchase Amount (Actual) on Item Ledger Entry after posting Purchase Order without Payment Discount.

        // Setup.
        Initialize();
        PurchaseAmountActualOnItemLedgerEntry(0, LibraryRandom.RandDec(10, 2), 0);  // 0 for Payment Discount. % and Line Discount %, Random for Invoice Discount %.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseAmountActualOnILEWithoutInvoiceDiscount()
    begin
        // Test to verify Purchase Amount (Actual) on Item Ledger Entry after posting Purchase Order without Invoice Discount.

        // Setup.
        Initialize();
        PurchaseAmountActualOnItemLedgerEntry(LibraryRandom.RandDec(10, 2), 0, 0);  // Random for Payment Discount %, 0 for Invoice Discount. % and Line Discount %.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseAmountActualOnILEWithInvoiceDiscount()
    begin
        // Test to verify Purchase Amount (Actual) on Item Ledger Entry after posting Purchase Order with Invoice Discount and Payment Discount.

        // Setup.
        Initialize();
        PurchaseAmountActualOnItemLedgerEntry(LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2), 0);  // Random for Payment Discount % and Invoice Discount. %, 0 for Line Discount %.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseAmountActualOnILEWithLineDiscount()
    var
        DiscountPercentage: Decimal;
    begin
        // Test to verify Purchase Amount (Actual) on Item Ledger Entry after posting Purchase Order With Line Discount.

        // Setup.
        Initialize();
        DiscountPercentage := LibraryRandom.RandDec(10, 2);
        PurchaseAmountActualOnItemLedgerEntry(DiscountPercentage, DiscountPercentage, DiscountPercentage);
    end;

    local procedure PurchaseAmountActualOnItemLedgerEntry(PaymentDiscountPct: Decimal; InvoiceDiscountPct: Decimal; LineDiscountPct: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
        PurchaseAmountActual: Decimal;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines",
          GeneralLedgerSetup."Discount Calculation"::"Line Disc. * Inv. Disc. * Payment Disc.");
        CreatePurchaseOrderWithItemCharge(PurchaseLine, Vendor."No.", PaymentDiscountPct, InvoiceDiscountPct, LineDiscountPct);
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        OpenPurchaseOrderToCalculatePaymentDiscount(PurchaseHeader."No.");
        PurchaseAmountActual :=
          Round(PurchaseLine."Line Amount" - (PurchaseLine."Line Amount" * (PaymentDiscountPct) / 100));
        if InvoiceDiscountPct <> 0 then
            PurchaseAmountActual := PurchaseAmountActual - (PurchaseAmountActual * (InvoiceDiscountPct) / 100);
        DocumentNo := GetPostedDocumentNo(PurchaseHeader."Receiving No. Series");

        // Exercise.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // True for receive and invoice.

        // Verify.
        VerifyItemLedgerEntry(DocumentNo, PurchaseAmountActual);

        // TearDown.
        RollBackGeneralLedgerSetup(GeneralLedgerSetup."Payment Discount Type", GeneralLedgerSetup."Discount Calculation");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseAmountActualOnValeEntryWithPmtDiscount()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
        PurchaseAmountActual: Decimal;
    begin
        // Test to verify Purchase Amount (Actual) on Value Entry after posting Purchase Order With Payment Discount.

        // Setup: Create Vendor,Update General Ledger Setup,Create Purchase Order and open Purchase Order page.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines",
          GeneralLedgerSetup."Discount Calculation"::"Line Disc. + Inv. Disc. + Payment Disc.");
        CreatePurchaseOrderWithItemCharge(PurchaseLine, Vendor."No.", LibraryRandom.RandDec(10, 2), 0, 0);  // Random for Payment Discount. % and 0 for Invoice Discount % , Line Discount %.
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        OpenPurchaseOrderToCalculatePaymentDiscount(PurchaseHeader."No.");
        PurchaseAmountActual :=
          Round(PurchaseLine."Line Amount" - (PurchaseLine."Line Amount" * PurchaseHeader."Payment Discount %" / 100));

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // True for receive and invoice.

        // Verify.
        VerifyValueEntry(DocumentNo, PurchaseAmountActual);

        // TearDown.
        RollBackGeneralLedgerSetup(GeneralLedgerSetup."Payment Discount Type", GeneralLedgerSetup."Discount Calculation");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseAmountActualOnILEPostedReturnOrder()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        PurchaseAmountActual: Decimal;
    begin
        // Test to verify Purchase Amount (Actual) on Item Ledger Entry after posting Purchase Return Order.

        // Setup: Create Vendor,Update General Ledger Setup,Create Purchase Return Order and open Purchase Return Order page.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines",
          GeneralLedgerSetup."Discount Calculation"::"Line Disc. * Inv. Disc. * Payment Disc.");
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Return Order", Vendor."No.");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        OpenPurchaseReturnOrderToCalculatePaymentDiscount(PurchaseHeader."No.");
        PurchaseAmountActual :=
          Round(PurchaseLine."Line Amount" - (PurchaseLine."Line Amount" * PurchaseHeader."Payment Discount %" / 100));
        DocumentNo := GetPostedDocumentNo(PurchaseHeader."Return Shipment No. Series");

        // Exercise.
        DocumentNo2 := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // True for receive and invoice.

        // Verify.
        VerifyItemLedgerEntry(DocumentNo, -PurchaseAmountActual);
        VerifyValueEntry(DocumentNo2, -PurchaseAmountActual);

        // TearDown.
        RollBackGeneralLedgerSetup(GeneralLedgerSetup."Payment Discount Type", GeneralLedgerSetup."Discount Calculation");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseAmountActualOnValueEntryPostedCreditMemo()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
        PurchaseAmountActual: Decimal;
    begin
        // Test to verify Purchase Amount (Actual) on Value Entry after posting Purchase Credit Memo.

        // Setup: Create Vendor,Update General Ledger Setup,Create Purchase Credit Memo and open Purchase Credit Memo page.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines",
          GeneralLedgerSetup."Discount Calculation"::"Line Disc. * Inv. Disc. * Payment Disc.");
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Credit Memo", Vendor."No.");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        OpenPurchaseCreditMemoToCalculatePaymentDiscount(PurchaseHeader."No.");
        PurchaseAmountActual :=
          Round(PurchaseLine."Line Amount" - (PurchaseLine."Line Amount" * PurchaseHeader."Payment Discount %" / 100));

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // True for receive and invoice.

        // Verify.
        VerifyValueEntry(DocumentNo, -PurchaseAmountActual);

        // TearDown.
        RollBackGeneralLedgerSetup(GeneralLedgerSetup."Payment Discount Type", GeneralLedgerSetup."Discount Calculation");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseAmountActualOnILEPostedPurchaseOrder()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        PurchaseAmountActual: Decimal;
    begin
        // Test to verify Purchase Amount (Actual) on Item Ledger Entry after posting Purchase Order.

        // Setup: Create Vendor,Update General Ledger Setup,Create Purchase Order and open Purchase Order page.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines",
          GeneralLedgerSetup."Discount Calculation"::"Line Disc. * Inv. Disc. * Payment Disc.");
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        OpenPurchaseOrderToCalculatePaymentDiscount(PurchaseHeader."No.");
        PurchaseAmountActual :=
          Round(PurchaseLine."Line Amount" - (PurchaseLine."Line Amount" * PurchaseHeader."Payment Discount %" / 100));
        DocumentNo := GetPostedDocumentNo(PurchaseHeader."Receiving No. Series");

        // Exercise.
        DocumentNo2 := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // True for receive and invoice.

        // Verify.
        VerifyItemLedgerEntry(DocumentNo, PurchaseAmountActual);
        VerifyValueEntry(DocumentNo2, PurchaseAmountActual);

        // TearDown.
        RollBackGeneralLedgerSetup(GeneralLedgerSetup."Payment Discount Type", GeneralLedgerSetup."Discount Calculation");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseAmountActualOnValueEntryPostedPurchInv()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        DocumentNo: Code[20];
        PurchaseAmountActual: Decimal;
    begin
        // Test to verify Purchase Amount (Actual) on Value Entry after posting Purchase Invoice.

        // Setup: Create Vendor,Update General Ledger Setup,Create Purchase Invoice and open Purchase Invoice page.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines",
          GeneralLedgerSetup."Discount Calculation"::"Line Disc. * Inv. Disc. * Payment Disc.");
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        OpenPurchaseInvoiceToCalculatePaymentDiscount(PurchaseHeader."No.");
        PurchaseAmountActual :=
          Round(PurchaseLine."Line Amount" - (PurchaseLine."Line Amount" * PurchaseHeader."Payment Discount %" / 100));

        // Exercise.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // True for receive and invoice.

        // Verify.
        VerifyValueEntry(DocumentNo, PurchaseAmountActual);

        // TearDown.
        RollBackGeneralLedgerSetup(GeneralLedgerSetup."Payment Discount Type", GeneralLedgerSetup."Discount Calculation");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentDiscountOnPurchaseInvoiceTestReport()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        // Test to verify Payment Discount Amount on Purchase Document - Test report on Purchase Invoice.

        // Setup: Create Vendor,Update General Ledger Setup,Create Purchase Invoice and open Purchase Invoice page.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines",
          GeneralLedgerSetup."Discount Calculation"::"Line Disc. * Inv. Disc. * Payment Disc.");
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        OpenPurchaseInvoiceToCalculatePaymentDiscount(PurchaseHeader."No.");
        LibraryVariableStorage.Enqueue(Vendor."No.");  // Enqueue for PurchaseDocumentTestRequestPageHandler.
        Commit();  // Commit requires to run report.

        // Exercise.
        REPORT.Run(REPORT::"Purchase Document - Test");  // Opens PurchaseDocumentTestRequestPageHandler.

        // Verify: Verify Payment Discount Amount on Purchase Document - Test report.
        VerifyValuesOnReport(
          SumPmtDiscRcdAmountCap, Round(PurchaseLine."Line Amount" * PurchaseHeader."Payment Discount %" / 100));

        // TearDown.
        RollBackGeneralLedgerSetup(GeneralLedgerSetup."Payment Discount Type", GeneralLedgerSetup."Discount Calculation");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PurchaseDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentDiscountOnPurchaseCreditMemoTestReport()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        // Test to verify Payment Discount Amount on Purchase Document - Test report on Purchase Credit Memo.

        // Setup: Create Vendor,Update General Ledger Setup,Create Purchase Credit Memo and open Purchase Credit Memo page.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines",
          GeneralLedgerSetup."Discount Calculation"::"Line Disc. * Inv. Disc. * Payment Disc.");
        CreatePurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Credit Memo", Vendor."No.");
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        OpenPurchaseCreditMemoToCalculatePaymentDiscount(PurchaseHeader."No.");
        LibraryVariableStorage.Enqueue(Vendor."No.");  // Enqueue for PurchaseDocumentTestRequestPageHandler.
        Commit();  // Commit requires to run report.

        // Exercise.
        REPORT.Run(REPORT::"Purchase Document - Test");  // Opens PurchaseDocumentTestRequestPageHandler.

        // Verify: Verify Payment Discount Amount on Purchase Document - Test report.
        VerifyValuesOnReport(
          SumPmtDiscRcdAmountCap, Round(PurchaseLine."Line Amount" * PurchaseHeader."Payment Discount %" / 100));

        // TearDown.
        RollBackGeneralLedgerSetup(GeneralLedgerSetup."Payment Discount Type", GeneralLedgerSetup."Discount Calculation");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,SalesDocumentTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentDiscountOnSalesCreditMemoTestReport()
    var
        Customer: Record Customer;
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Test to verify Payment Discount Amount on Sales Document - Test report on Sales Credit Memo.

        // Setup: Create Customer,Update General Ledger Setup,Create Sales Credit Memo and open Sales Credit Memo page.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines",
          GeneralLedgerSetup."Discount Calculation"::"Line Disc. * Inv. Disc. * Payment Disc.");
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::"Credit Memo", Customer."No.", LibraryRandom.RandDec(10, 2));  // Random for Payment Discount %.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        OpenSalesCreditMemoToCalculatePaymentDiscount(SalesHeader."No.");
        LibraryVariableStorage.Enqueue(Customer."No.");  // Enqueue for SalesDocumentTestRequestPageHandler.
        Commit();  // Commit requires to run report.

        // Exercise.
        REPORT.Run(REPORT::"Sales Document - Test");  // Opens SalesDocumentTestRequestPageHandler.

        // Verify: Verify Payment Discount Amount on Sales Document - Test report.
        VerifyValuesOnReport(
          SalesLinePmtDiscGivenAmountCap, Round(SalesLine."Line Amount" * SalesHeader."Payment Discount %" / 100));

        // TearDown.
        RollBackGeneralLedgerSetup(GeneralLedgerSetup."Payment Discount Type", GeneralLedgerSetup."Discount Calculation");
    end;
#if not CLEAN27
    [Test]
    [HandlerFunctions('ConfirmHandler,ServiceStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentDiscountOnServiceInvoiceStatistics()
    var
        Customer: Record Customer;
        GeneralLedgerSetup: Record "General Ledger Setup";
        ServiceHeader: Record "Service Header";
    begin
        // Test to verify Payment Discount Amount on Service Statistics Page.

        // Setup: Create Customer,Update General Ledger Setup,Create Service Invoice and open Service Invoice page.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines",
          GeneralLedgerSetup."Discount Calculation"::"Line Disc. * Inv. Disc. + Payment Disc.");
        CreateServiceDocumentAndCalculatePmtDiscount(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");

        // Exercise.
        OpenServiceInvoiceStatistics(ServiceHeader."No.");

        // Verify: Verification done in ServiceStatisticsModalPageHandler.

        // TearDown.
        RollBackGeneralLedgerSetup(GeneralLedgerSetup."Payment Discount Type", GeneralLedgerSetup."Discount Calculation");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ServiceStatisticsModalPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentDiscountOnServiceCreditMemoStatistics()
    var
        Customer: Record Customer;
        GeneralLedgerSetup: Record "General Ledger Setup";
        ServiceHeader: Record "Service Header";
    begin
        // Test to verify Payment Discount Amount on Service Credit Memo Statistics Page.

        // Setup: Create Customer,Update General Ledger Setup,Create Service Credit Memo and open Service Credit Memo page.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines",
          GeneralLedgerSetup."Discount Calculation"::"Line Disc. * Inv. Disc. + Payment Disc.");
        CreateServiceDocumentAndCalculatePmtDiscount(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", Customer."No.");

        // Exercise.
        OpenServiceCreditMemoStatistics(ServiceHeader."No.");

        // Verify: Verification done in ServiceStatisticsModalPageHandler.

        // TearDown.
        RollBackGeneralLedgerSetup(GeneralLedgerSetup."Payment Discount Type", GeneralLedgerSetup."Discount Calculation");
    end;
#endif
    [Test]
    [HandlerFunctions('ConfirmHandler,ServiceStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentDiscountOnServiceInvoiceStatisticsNM()
    var
        Customer: Record Customer;
        GeneralLedgerSetup: Record "General Ledger Setup";
        ServiceHeader: Record "Service Header";
    begin
        // Test to verify Payment Discount Amount on Service Statistics Page.

        // Setup: Create Customer,Update General Ledger Setup,Create Service Invoice and open Service Invoice page.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines",
          GeneralLedgerSetup."Discount Calculation"::"Line Disc. * Inv. Disc. + Payment Disc.");
        CreateServiceDocumentAndCalculatePmtDiscount(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");

        // Exercise.
        OpenServiceInvoiceStatisticsNM(ServiceHeader."No.");

        // Verify: Verification done in ServiceStatisticsPageHandler.

        // TearDown.
        RollBackGeneralLedgerSetup(GeneralLedgerSetup."Payment Discount Type", GeneralLedgerSetup."Discount Calculation");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ServiceStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PaymentDiscountOnServiceCreditMemoStatisticsNM()
    var
        Customer: Record Customer;
        GeneralLedgerSetup: Record "General Ledger Setup";
        ServiceHeader: Record "Service Header";
    begin
        // Test to verify Payment Discount Amount on Service Credit Memo Statistics Page.

        // Setup: Create Customer,Update General Ledger Setup,Create Service Credit Memo and open Service Credit Memo page.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        GeneralLedgerSetup.Get();
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines",
          GeneralLedgerSetup."Discount Calculation"::"Line Disc. * Inv. Disc. + Payment Disc.");
        CreateServiceDocumentAndCalculatePmtDiscount(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", Customer."No.");

        // Exercise.
        OpenServiceCreditMemoStatisticsNM(ServiceHeader."No.");

        // Verify: Verification done in ServiceStatisticsPageHandler.

        // TearDown.
        RollBackGeneralLedgerSetup(GeneralLedgerSetup."Payment Discount Type", GeneralLedgerSetup."Discount Calculation");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecalculateInvoiceDiscAfterReleaseSalesDocument()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales][Invoice Discount]
        // [SCENARIO 376123] Field "Recalculate Invoice Disc." of "Sales Header" should be FALSE after releasing document
        Initialize();

        // [GIVEN] Sales order with sales line
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));

        LibrarySales.SetCalcInvDiscount(true);

        // [WHEN] Release sales document
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [THEN] "Recalculate Invoice Disc." = FALSE
        SalesHeader.CalcFields("Recalculate Invoice Disc.");
        SalesHeader.TestField("Recalculate Invoice Disc.", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecalculateInvoiceDiscAfterReleasePurchaseDocument()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase][Invoice Discount]
        // [SCENARIO 376123] Field "Recalculate Invoice Disc." of "Purchase Header" should be FALSE after releasing document
        Initialize();

        // [GIVEN] Purchase order with purchase line
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));

        LibraryPurchase.SetCalcInvDiscount(true);

        // [WHEN] Release purchase document
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [THEN] "Recalculate Invoice Disc." = FALSE
        PurchaseHeader.CalcFields("Recalculate Invoice Disc.");
        PurchaseHeader.TestField("Recalculate Invoice Disc.", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderFromSalesQuotePaymentDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesQuoteLineAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Quote]
        // [SCENARIO 256684] The Payment Discount is taken into account when a Sales Order is created from a Sales Quote.
        Initialize();
        UpdateSalesReceivablesSetup(false, SalesReceivablesSetup."Credit Warnings"::"No Warning");

        // [GIVEN] Sales Quote "Q" for Customer with Payment Discount with Sales Line.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, CreateCustomerWithPaymentTermsWithDiscount());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));

        // [GIVEN] Sales Line has Amount "A" after the Payment Discount is taken into account.
        ModifyGLSetupForPaymentDiscount();
        LibrarySales.CalcSalesDiscount(SalesHeader);
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesQuoteLineAmount := SalesLine.Amount;

        // [WHEN] Create Sales Order "O" form "Q".
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Order", SalesHeader);

        // [THEN] "O" has SalesLine where Amount = "A".
        FindSalesLineCreatedFromQuote(SalesLine, SalesHeader."No.");
        SalesLine.TestField(Amount, SalesQuoteLineAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderFromPurchQuotePaymentDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseQuoteLineAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Quote]
        // [SCENARIO 256684] The Payment Discount is taken into account when a Purchase Order is created from a Purchase Quote.
        Initialize();
        UpdatePurchasesPayablesSetup();

        // [GIVEN] Purchase Quote "Q" for Vendor with Payment Discount with Purchase Line.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Quote, CreateVendorWithPaymentTermsWithDiscount());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));

        // [GIVEN] Purchase Line has Amount "A" after the Payment Discount is taken into account.
        ModifyGLSetupForPaymentDiscount();
        LibraryPurchase.CalcPurchaseDiscount(PurchaseHeader);
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseQuoteLineAmount := PurchaseLine.Amount;

        // [WHEN] Create Sales Order "O" form "Q".
        CODEUNIT.Run(CODEUNIT::"Purch.-Quote to Order", PurchaseHeader);

        // [THEN] "O" has SalesLine where Amount = "A".
        FindPurchLineCreatedFromQuote(PurchaseLine, PurchaseHeader."No.");
        PurchaseLine.TestField(Amount, PurchaseQuoteLineAmount);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure PurchOrderWithDistributedItemChargeAndPaymentDiscount()
    var
        Item: array[2] of Record Item;
        ItemCharge: Record "Item Charge";
        PurchaseHeaderOrder: Record "Purchase Header";
        PurchaseLineOrder: Record "Purchase Line";
        PurchaseHeaderInvoice: Record "Purchase Header";
        PurchaseLineInvoice: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        ValueEntry: Record "Value Entry";
        ReceiptNo: Code[20];
        i: Integer;
    begin
        // [FEATURE] [Purchase] [Item Charge]
        // [SCENARIO 418830] Payment discount amount for item charge is distributed among several purchase receipt lines.
        Initialize();

        // [GIVEN] Enable discounts.
        UpdatePurchasesPayablesSetup();

        // [GIVEN] Purchase order with two lines - items "I1" and "I2".
        // [GIVEN] Post the order as Receive.
        LibraryPurchase.CreatePurchHeader(PurchaseHeaderOrder, PurchaseHeaderOrder."Document Type"::Order, '');
        for i := 1 to ArrayLen(Item) do begin
            LibraryInventory.CreateItem(Item[i]);
            LibraryPurchase.CreatePurchaseLine(PurchaseLineOrder, PurchaseHeaderOrder, PurchaseLineOrder.Type::Item, Item[i]."No.", 1);
        end;
        ReceiptNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderOrder, true, false);

        // [GIVEN] Purchase invoice with 10% payment discount.
        // [GIVEN] Create a line for item charge, quantity = 1, amount = 1000.
        CreatePurchaseHeader(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, '', 10);
        LibraryInventory.CreateItemCharge(ItemCharge);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLineInvoice, PurchaseHeaderInvoice, PurchaseLineInvoice.Type::"Charge (Item)", ItemCharge."No.", 1);
        PurchaseLineInvoice.Validate("Direct Unit Cost", 1000);
        PurchaseLineInvoice.Modify(true);

        // [GIVEN] Distribute the item charge equally among purchase receipt lines "I1" and "I2", 0.5 to each.
        for i := 1 to ArrayLen(Item) do begin
            PurchRcptLine.SetRange("Document No.", ReceiptNo);
            PurchRcptLine.SetRange("No.", Item[i]."No.");
            PurchRcptLine.FindFirst();
            LibraryPurchase.CreateItemChargeAssignment(
              ItemChargeAssignmentPurch, PurchaseLineInvoice, ItemCharge,
              ItemChargeAssignmentPurch."Applies-to Doc. Type"::Receipt, PurchRcptLine."Document No.", PurchRcptLine."Line No.",
              PurchRcptLine."No.", 0.5, PurchaseLineInvoice."Direct Unit Cost");
            ItemChargeAssignmentPurch.Insert(true);
        end;

        // [GIVEN] Calculate payment discounts.
        ModifyGLSetupForPaymentDiscount();
        OpenPurchaseInvoiceToCalculatePaymentDiscount(PurchaseHeaderInvoice."No.");

        // [WHEN] Post the purchase invoice.
        PurchaseHeaderInvoice.Find();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, true, true);

        // [THEN] The amount of 900 (1000 - 10%) is equally assigned to both "I1" and "I2", 450 to each.
        for i := 1 to ArrayLen(Item) do begin
            ValueEntry.SetRange("Item No.", Item[i]."No.");
            ValueEntry.CalcSums("Cost Amount (Actual)");
            ValueEntry.TestField("Cost Amount (Actual)", 450);
        end;
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();

        LibraryVariableStorage.Clear();
        if IsInitialize then
            exit;

        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        IsInitialize := true;
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20])
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine2: Record "Purchase Line";
    begin
        CreatePurchaseHeader(
          PurchaseHeader, DocumentType, VendorNo, LibraryRandom.RandDec(10, 2));  // Random for Payment Discount %.
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item));
        CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item));
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; PaymentDiscountPct: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Payment Discount %", PaymentDiscountPct);
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20])
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, LibraryRandom.RandDec(10, 2));  // Random for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseLineDiscount(Item: Record Item; VendorNo: Code[20]; LineDiscountPct: Decimal)
    var
        PriceListLine: Record "Price List Line";
    begin
        LibraryPriceCalculation.CreatePurchDiscountLine(
            PriceListLine, '', "Price Source Type"::Vendor, VendorNo, "Price Asset Type"::Item, Item."No.");
        PriceListLine.Validate("Starting Date", WorkDate());
        PriceListLine.Validate("Unit of Measure Code", Item."Base Unit of Measure");
        PriceListLine.Validate("Line Discount %", LineDiscountPct);
        PriceListLine.Status := "Price Status"::Active;
        PriceListLine.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithItemCharge(var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; PaymentDiscountPct: Decimal; DiscountPct: Decimal; LineDiscountPct: Decimal)
    var
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine2: Record "Purchase Line";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemCharge(ItemCharge);
        CreateVendorInvoiceDisc(VendorNo, DiscountPct);
        CreatePurchaseLineDiscount(Item, VendorNo, LineDiscountPct);
        CreatePurchaseHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo, PaymentDiscountPct);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.");
        CreatePurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::"Charge (Item)", ItemCharge."No.");
        LibraryInventory.CreateItemChargeAssignPurchase(
          ItemChargeAssignmentPurch, PurchaseLine2, PurchaseLine2."Document Type",
          PurchaseLine2."Document No.", PurchaseLine2."Line No.", ItemCharge."No.");
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; PaymentDiscountPct: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Payment Discount %", PaymentDiscountPct);
        SalesHeader.Modify(true);
        CreateSalesLine(SalesLine, SalesHeader);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    var
        Item: Record Item;
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));  // Random for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateServiceDocument(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; CustomerNo: Code[20])
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CustomerNo);
        ServiceHeader.Validate("Payment Discount %", LibraryRandom.RandDec(10, 2));
        ServiceHeader.Modify(true);
        CreateServiceLine(ServiceLine, ServiceHeader);
    end;

    local procedure CreateServiceDocumentAndCalculatePmtDiscount(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; CustomerNo: Code[20])
    var
        ServiceLine: Record "Service Line";
        ServiceLine2: Record "Service Line";
        PaymentDiscountAmount: Decimal;
    begin
        CreateServiceDocument(ServiceLine, ServiceHeader, DocumentType, CustomerNo);
        ServiceHeader.Get(ServiceLine."Document Type", ServiceLine."Document No.");
        CreateServiceLine(ServiceLine2, ServiceHeader);
        PaymentDiscountAmount := (ServiceLine.Amount + ServiceLine2.Amount) * ServiceHeader."Payment Discount %" / 100;
        LibraryVariableStorage.Enqueue(PaymentDiscountAmount);  // Enqueue for ServiceStatisticsModalPageHandler.
    end;

    local procedure CreateServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    var
        Item: Record Item;
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItem(Item));
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
    end;

    local procedure CreateVendorInvoiceDisc(VendorNo: Code[20]; DiscountPct: Decimal)
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, VendorNo, '', 0);  // Blank for currency, 0 for minimum amount.
        VendorInvoiceDisc.Validate("Discount %", DiscountPct);
        VendorInvoiceDisc.Modify(true);
    end;

    local procedure CreateCustomerWithPaymentTermsWithDiscount(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", CreatePaymentTermsWithDiscount());
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateVendorWithPaymentTermsWithDiscount(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", CreatePaymentTermsWithDiscount());
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreatePaymentTermsWithDiscount(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.FindPaymentTerms(PaymentTerms);
        PaymentTerms.Validate("Discount %", LibraryRandom.RandDec(99, 2));
        PaymentTerms.Modify(true);
        exit(PaymentTerms.Code);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Last Direct Cost", LibraryRandom.RandInt(100));  // Using RANDOM value for Unit Price.
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure GetPostedDocumentNo(NoSeriesCode: Code[20]): Code[20]
    var
        NoSeries: Codeunit "No. Series";
    begin
        exit(NoSeries.PeekNextNo(NoSeriesCode));
    end;

    local procedure FindSalesLineCreatedFromQuote(var SalesLine: Record "Sales Line"; QuoteNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Quote No.", QuoteNo);
        SalesHeader.FindFirst();
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
    end;

    local procedure FindPurchLineCreatedFromQuote(var PurchaseLine: Record "Purchase Line"; QuoteNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.SetRange("Quote No.", QuoteNo);
        PurchaseHeader.FindFirst();
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
    end;

    local procedure OpenPurchaseCreditMemoToCalculatePaymentDiscount(No: Code[20])
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.FILTER.SetFilter("No.", No);
        PurchaseCreditMemo.CalculateInvoiceDiscount.Invoke();
        PurchaseCreditMemo.Close();
    end;

    local procedure OpenPurchaseInvoiceToCalculatePaymentDiscount(No: Code[20])
    var
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.FILTER.SetFilter("No.", No);
        PurchaseInvoice.CalculateInvoiceDiscount.Invoke();
        PurchaseInvoice.Close();
    end;

    local procedure OpenPurchaseOrderToCalculatePaymentDiscount(No: Code[20])
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", No);
        PurchaseOrder.CalculateInvoiceDiscount.Invoke();
        PurchaseOrder.Close();
    end;

    local procedure OpenPurchaseReturnOrderToCalculatePaymentDiscount(No: Code[20])
    var
        PurchaseReturnOrder: TestPage "Purchase Return Order";
    begin
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.FILTER.SetFilter("No.", No);
        PurchaseReturnOrder.CalculateInvoiceDiscount.Invoke();
        PurchaseReturnOrder.Close();
    end;

    local procedure OpenSalesCreditMemoToCalculatePaymentDiscount(No: Code[20])
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.FILTER.SetFilter("No.", No);
        SalesCreditMemo.CalculateInvoiceDiscount.Invoke();
        SalesCreditMemo.Close();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger.', '26.0')]
    local procedure OpenSalesInvoiceStatistics(No: Code[20])
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", No);
        SalesInvoice.CalculateInvoiceDiscount.Invoke();
        SalesInvoice.Statistics.Invoke();  // Opens SalesStatisticsModalPageHandler.
        SalesInvoice.Close();
    end;
#endif
    local procedure OpenSalesInvoiceSalesStatistics(No: Code[20])
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", No);
        SalesInvoice.CalculateInvoiceDiscount.Invoke();
        SalesInvoice.SalesStatistics.Invoke();  // Opens SalesStatisticsPageHandler.
        SalesInvoice.Close();
    end;

    local procedure OpenSalesInvoiceToCalculatePaymentDiscount(No: Code[20])
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", No);
        SalesInvoice.CalculateInvoiceDiscount.Invoke();
        SalesInvoice.Close();
    end;

    local procedure OpenSalesOrderToCalculatePaymentDiscount(No: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", No);
        SalesOrder.CalculateInvoiceDiscount.Invoke();
        SalesOrder.Close();
    end;
#if not CLEAN27
    local procedure OpenServiceCreditMemoStatistics(No: Code[20])
    var
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        ServiceCreditMemo.OpenEdit();
        ServiceCreditMemo.FILTER.SetFilter("No.", No);
        ServiceCreditMemo."Calculate Inv. and Pmt. Disc.".Invoke();
        ServiceCreditMemo.Statistics.Invoke();  // Opens ServiceStatisticsModalPageHandler.
        ServiceCreditMemo.Close();
    end;

    local procedure OpenServiceInvoiceStatistics(No: Code[20])
    var
        ServiceInvoice: TestPage "Service Invoice";
    begin
        ServiceInvoice.OpenEdit();
        ServiceInvoice.FILTER.SetFilter("No.", No);
        ServiceInvoice."Calculate Invoice Discount".Invoke();
        ServiceInvoice.Statistics.Invoke();  // Opens ServiceStatisticsModalPageHandler.
        ServiceInvoice.Close();
    end;
#endif
    local procedure OpenServiceCreditMemoStatisticsNM(No: Code[20])
    var
        ServiceCreditMemo: TestPage "Service Credit Memo";
    begin
        ServiceCreditMemo.OpenEdit();
        ServiceCreditMemo.FILTER.SetFilter("No.", No);
#if not CLEAN27
        ServiceCreditMemo."Calculate Inv. and Pmt. Disc.".Invoke();
#else
        ServiceCreditMemo."Calculate Invoice Discount".Invoke();
#endif
        ServiceCreditMemo.ServiceStatistics.Invoke();  // Opens ServiceStatisticsModalPageHandler.
        ServiceCreditMemo.Close();
    end;

    local procedure OpenServiceInvoiceStatisticsNM(No: Code[20])
    var
        ServiceInvoice: TestPage "Service Invoice";
    begin
        ServiceInvoice.OpenEdit();
        ServiceInvoice.FILTER.SetFilter("No.", No);
        ServiceInvoice."Calculate Invoice Discount".Invoke();
        ServiceInvoice.ServiceStatistics.Invoke();  // Opens ServiceStatisticsModalPageHandler.
        ServiceInvoice.Close();
    end;

    local procedure UpdateSalesReceivablesSetup(NewStockOutWarning: Boolean; CreditWarning: Option)
    begin
        LibrarySales.SetStockoutWarning(NewStockOutWarning);
        LibrarySales.SetCreditWarnings(CreditWarning);
        LibrarySales.SetCalcInvDiscount(true);
    end;

    local procedure UpdatePurchasesPayablesSetup()
    begin
        LibraryPurchase.SetCalcInvDiscount(true);
    end;

    local procedure RollBackDiscountCalculationOnGeneralLedgerSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Discount Calculation", GeneralLedgerSetup."Discount Calculation"::" ");
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure RollBackGeneralLedgerSetup(PaymentDiscountType: Option; DiscountCalculation: Option)
    begin
        RollBackDiscountCalculationOnGeneralLedgerSetup();
        UpdateGeneralLedgerSetup(PaymentDiscountType, DiscountCalculation);
    end;

    local procedure UpdateGeneralLedgerSetup(PaymentDiscountType: Option; DiscountCalculation: Option)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Payment Discount Type", PaymentDiscountType);
        GeneralLedgerSetup.Validate("Discount Calculation", DiscountCalculation);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure ModifyGLSetupForPaymentDiscount()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        UpdateGeneralLedgerSetup(
          GeneralLedgerSetup."Payment Discount Type"::"Calc. Pmt. Disc. on Lines",
          GeneralLedgerSetup."Discount Calculation"::"Line Disc. * Inv. Disc. * Payment Disc.")
    end;

    local procedure VerifyItemLedgerEntry(DocumentNo: Code[20]; PurchaseAmountActual: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.CalcFields("Purchase Amount (Actual)");
        Assert.AreNearlyEqual(
          PurchaseAmountActual, ItemLedgerEntry."Purchase Amount (Actual)", LibraryERM.GetAmountRoundingPrecision(), AmountMustMatchMsg);
    end;

    local procedure VerifyValueEntry(DocumentNo: Code[20]; PurchaseAmountActual: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.FindFirst();
        Assert.AreNearlyEqual(
          PurchaseAmountActual, ValueEntry."Purchase Amount (Actual)", LibraryERM.GetAmountRoundingPrecision(), AmountMustMatchMsg);
    end;

    local procedure VerifyValuesOnReport(Caption: Text[50]; Value: Variant)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(Caption, Value);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseDocumentTestRequestPageHandler(var PurchaseDocumentTest: TestRequestPage "Purchase Document - Test")
    var
        BuyFromVendorNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BuyFromVendorNo);
        PurchaseDocumentTest."Purchase Header".SetFilter("Buy-from Vendor No.", BuyFromVendorNo);
        PurchaseDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesDocumentTestRequestPageHandler(var SalesDocumentTest: TestRequestPage "Sales Document - Test")
    var
        SellToCustomerNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(SellToCustomerNo);
        SalesDocumentTest."Sales Header".SetFilter("Sell-to Customer No.", SellToCustomerNo);
        SalesDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsModalPageHandler(var SalesStatistics: TestPage "Sales Statistics")
    var
        PmtDiscGivenAmount: Decimal;
        ExpectedPmtDiscGivenAmount: Decimal;
    begin
        ExpectedPmtDiscGivenAmount := Round(LibraryVariableStorage.DequeueDecimal());
        PmtDiscGivenAmount := SalesStatistics.PmtDiscGivenAmount.AsDecimal();
        SalesStatistics.OK().Invoke();
        Assert.AreEqual(ExpectedPmtDiscGivenAmount, PmtDiscGivenAmount, '');
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsPageHandler(var SalesStatistics: TestPage "Sales Statistics")
    var
        PmtDiscGivenAmount: Decimal;
        ExpectedPmtDiscGivenAmount: Decimal;
    begin
        ExpectedPmtDiscGivenAmount := Round(LibraryVariableStorage.DequeueDecimal());
        PmtDiscGivenAmount := SalesStatistics.PmtDiscGivenAmount.AsDecimal();
        SalesStatistics.OK().Invoke();
        Assert.AreEqual(ExpectedPmtDiscGivenAmount, PmtDiscGivenAmount, '');
    end;

#if not CLEAN27
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceStatisticsModalPageHandler(var ServiceStatistics: TestPage "Service Statistics")
    var
        PmtDiscGivenAmount: Decimal;
        ExpectedPmtDiscGivenAmount: Decimal;
    begin
        ExpectedPmtDiscGivenAmount := Round(LibraryVariableStorage.DequeueDecimal());
        PmtDiscGivenAmount := ServiceStatistics.PmtDiscGivenAmount.AsDecimal();
        ServiceStatistics.OK().Invoke();
        Assert.AreEqual(ExpectedPmtDiscGivenAmount, PmtDiscGivenAmount, '');
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure ServiceStatisticsPageHandler(var ServiceStatistics: TestPage "Service Statistics")
    var
        PmtDiscGivenAmount: Decimal;
        ExpectedPmtDiscGivenAmount: Decimal;
    begin
        ExpectedPmtDiscGivenAmount := Round(LibraryVariableStorage.DequeueDecimal());
        PmtDiscGivenAmount := ServiceStatistics.PmtDiscGivenAmount.AsDecimal();
        ServiceStatistics.OK().Invoke();
        Assert.AreEqual(ExpectedPmtDiscGivenAmount, PmtDiscGivenAmount, '');
    end;
}