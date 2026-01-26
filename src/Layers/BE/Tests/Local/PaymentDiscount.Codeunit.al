codeunit 144001 "Payment Discount"
{
    // // [FEATURE] [Payment Discount]
    // ----------------------------------------------------------------------------------
    // Test Function Name                                                          TFS ID
    // ----------------------------------------------------------------------------------
    // SalesPmtDiscWithAdjustForPmtDisc                                            358593
    // PurchPmtDiscWithAdjustForPmtDisc                                            358593

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryService: Codeunit "Library - Service";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        PmtDiscOnDocLineErr: Label 'The %1 on %2 in document no. %3 must be %4.';
        WrongFieldValueErr: Label 'Wrong value of field %1 in table %2.';

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtPmtDiscOnLineAfterUpdateVATOnLines()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ExpectedAmount: Decimal;
    begin
        // [FEATURE] [Prepayment] [Sales]
        // [SCENARIO 207864] "Prepmt. Pmt. Disc. Amount" is correct in "Sales Line" after calling UpdateVATOnLines

        CreateSalesDocInLCYWithPrepmt(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        CalcAndUpdateSalesVATOnLines(SalesHeader, SalesLine);
        ExpectedAmount := CalcSalesExpectedAmount(SalesHeader);
        SalesLine.TestField("Prepmt. Pmt. Discount Amount", ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepmtPmtDiscOnLinesAfterUpdateVATOnLines()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ExpectedAmount: Decimal;
    begin
        // [FEATURE] [Prepayment] [Purchase]
        // [SCENARIO 207864] "Prepmt. Pmt. Disc. Amount" is correct in "Purchase Line" after calling UpdateVATOnLines

        CreatePurchDocInLCYWithPrepmt(PurchHeader, PurchLine, PurchHeader."Document Type"::Order);
        CalcAndUpdatePurchVATOnLines(PurchHeader, PurchLine);
        ExpectedAmount := CalcPurchExpectedAmount(PurchHeader);
        PurchLine.TestField("Prepmt. Pmt. Discount Amount", ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPrepmtPmtDiscInclVATOnLineAfterUpdateVATOnLines()
    var
        GLSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ExpectedAmount: Decimal;
    begin
        // Check that "Prepmt. Pmt. Disc. Amount" is correct in "Sales Line" after calling UpdateVATOnLines

        GLSetup.Get();
        UpdateGLSetup(0, false); // pass zero for "VAT Tolerance %"
        CreateSalesDocInLCYWithPrepmt(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        CalcAndUpdateSalesVATOnLines(SalesHeader, SalesLine);
        ExpectedAmount := CalcSalesExpectedAmount(SalesHeader);
        SalesLine.TestField("Prepmt. Pmt. Discount Amount", ExpectedAmount);
        UpdateGLSetup(GLSetup."VAT Tolerance %", GLSetup."Pmt. Disc. Excl. VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepmtPmtDiscInclVATOnLinesAfterUpdateVATOnLines()
    var
        GLSetup: Record "General Ledger Setup";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ExpectedAmount: Decimal;
    begin
        // Check that "Prepmt. Pmt. Disc. Amount" is correct in "Sales Line" after calling UpdateVATOnLines

        GLSetup.Get();
        UpdateGLSetup(0, false); // pass zero for "VAT Tolerance %"
        CreatePurchDocInLCYWithPrepmt(PurchHeader, PurchLine, PurchHeader."Document Type"::Order);
        CalcAndUpdatePurchVATOnLines(PurchHeader, PurchLine);
        ExpectedAmount := CalcPurchExpectedAmount(PurchHeader);
        PurchLine.TestField("Prepmt. Pmt. Discount Amount", ExpectedAmount);
        UpdateGLSetup(GLSetup."VAT Tolerance %", GLSetup."Pmt. Disc. Excl. VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPmtDiscOnPrepmtInvLineBuf()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PrepmtInvBuf: Record "Prepayment Inv. Line Buffer" temporary;
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
    begin
        // Check that "Original Pmt. Disc. Possible" is correct in "Prepayment Inv. Line Buffer" after calling FillInvLineBuffer

        CreateSalesDocInLCYWithPrepmt(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        CalcAndUpdateSalesVATOnLines(SalesHeader, SalesLine);
        SalesPostPrepayments.FillInvLineBuffer(SalesHeader, SalesLine, PrepmtInvBuf);
        SalesLine.TestField("Prepmt. Pmt. Discount Amount");
        PrepmtInvBuf.TestField("Orig. Pmt. Disc. Possible", SalesLine."Prepmt. Pmt. Discount Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPmtDiscOnPrepmtInvLineBuf()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PrepmtInvBuf: Record "Prepayment Inv. Line Buffer" temporary;
        PurchPostPrepayments: Codeunit "Purchase-Post Prepayments";
    begin
        // Check that "Original Pmt. Disc. Possible" is correct in "Prepayment Inv. Line Buffer" after calling FillInvLineBuffer

        CreatePurchDocInLCYWithPrepmt(PurchHeader, PurchLine, PurchHeader."Document Type"::Order);
        CalcAndUpdatePurchVATOnLines(PurchHeader, PurchLine);
        PurchPostPrepayments.FillInvLineBuffer(PurchHeader, PurchLine, PrepmtInvBuf);
        PurchLine.TestField("Prepmt. Pmt. Discount Amount");
        PrepmtInvBuf.TestField("Orig. Pmt. Disc. Possible", PurchLine."Prepmt. Pmt. Discount Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtDiscOnPrepmtSalesInvLines()
    var
        SalesHeader: Record "Sales Header";
        InvNo: Code[20];
        TotalVATBaseAmount: Decimal;
        ExpectedAmount: Decimal;
    begin
        // Check that "Pmt. Discount Amount" is correct in Sales Invoice Lines after posting prepayment invoice

        TotalVATBaseAmount :=
          CreateSalesDocWithMultipleLinesAndPrepmt(SalesHeader, SalesHeader."Document Type"::Order);
        InvNo :=
          PostSOPrepaymentInvoice(SalesHeader);
        ExpectedAmount :=
          Round(TotalVATBaseAmount * SalesHeader."Payment Discount %" / 100, LibraryERM.GetAmountRoundingPrecision());
        VerifyPmtDiscOnSalesInvLines(InvNo, SalesHeader."Sell-to Customer No.", ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtDiscOnPrepmtSalesCrMemoLines()
    var
        SalesHeader: Record "Sales Header";
        CrMemoNo: Code[20];
        TotalVATBaseAmount: Decimal;
        ExpectedAmount: Decimal;
    begin
        // Check that "Pmt. Discount Amount" is correct in Sales Cr. Memo Lines after posting prepayment cr. memo

        TotalVATBaseAmount :=
          CreateSalesDocWithMultipleLinesAndPrepmt(SalesHeader, SalesHeader."Document Type"::Order);
        PostSOPrepaymentInvoice(SalesHeader);
        CrMemoNo :=
          PostSOPrepaymentCrMemo(SalesHeader);
        ExpectedAmount :=
          Round(TotalVATBaseAmount * SalesHeader."Payment Discount %" / 100, LibraryERM.GetAmountRoundingPrecision());
        VerifyPmtDiscOnSalesCrMemoLines(CrMemoNo, SalesHeader."Sell-to Customer No.", ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtDiscOnPrepmtPurchInvLines()
    var
        PurchHeader: Record "Purchase Header";
        InvNo: Code[20];
        TotalVATBaseAmount: Decimal;
        ExpectedAmount: Decimal;
    begin
        // Check that "Pmt. Discount Amount" is correct in Purch. Invoice Lines after posting prepayment invoice

        TotalVATBaseAmount :=
          CreatePurchDocWithMultipleLinesAndPrepmt(PurchHeader, PurchHeader."Document Type"::Order);
        InvNo :=
          PostPOPrepaymentInvoice(PurchHeader);
        ExpectedAmount :=
          Round(TotalVATBaseAmount * PurchHeader."Payment Discount %" / 100, LibraryERM.GetAmountRoundingPrecision());
        VerifyPmtDiscOnPurchInvLines(InvNo, PurchHeader."Pay-to Vendor No.", ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtDiscOnPrepmtPurchCrMemoLines()
    var
        PurchHeader: Record "Purchase Header";
        CrMemoNo: Code[20];
        TotalVATBaseAmount: Decimal;
        ExpectedAmount: Decimal;
    begin
        // Check that "Pmt. Discount Amount" is correct in Purch. Invoice Lines after posting prepayment cr. memo

        TotalVATBaseAmount :=
          CreatePurchDocWithMultipleLinesAndPrepmt(PurchHeader, PurchHeader."Document Type"::Order);
        PostPOPrepaymentInvoice(PurchHeader);
        CrMemoNo :=
          PostPOPrepaymentCrMemo(PurchHeader);
        ExpectedAmount :=
          Round(TotalVATBaseAmount * PurchHeader."Payment Discount %" / 100, LibraryERM.GetAmountRoundingPrecision());
        VerifyPmtDiscOnPurchCrMemoLines(CrMemoNo, PurchHeader."Pay-to Vendor No.", ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtPmtDiscOnInvCustLedgEntry()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PrepaymentSalesInvLine: Record "Sales Invoice Line";
        InvNo: Code[20];
        ExpectedAmount: Decimal;
    begin
        // Check that payment discount is correct in Customer Ledger Entry after posting prepayment invoice

        CreateSalesDocInLCYWithPrepmt(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        CalcAndUpdateSalesVATOnLines(SalesHeader, SalesLine);
        ExpectedAmount := CalcSalesExpectedAmount(SalesHeader);
        InvNo := PostSOPrepaymentInvoice(SalesHeader);
        VerifyPmtDiscOnCustLedgEntry(SalesHeader."Bill-to Customer No.", InvNo, ExpectedAmount);
        PrepaymentSalesInvLine.SetRange("Document No.", InvNo);
        PrepaymentSalesInvLine.FindFirst();
        PrepaymentSalesInvLine.TestField("Shipment Date", SalesLine."Shipment Date");
        PrepaymentSalesInvLine.TestField("Responsibility Center", SalesLine."Responsibility Center");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtPmtDiscOnCrMemoCustLedgEntry()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CrMemoNo: Code[20];
        ExpectedAmount: Decimal;
    begin
        // [SCENARIO] Check that payment discount is correct in Customer Ledger Entry after posting prepayment cr. memo

        // [GIVEN] Sales Order in LCY with prepayment
        CreateSalesDocInLCYWithPrepmt(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        CalcAndUpdateSalesVATOnLines(SalesHeader, SalesLine);
        ExpectedAmount := CalcSalesExpectedAmount(SalesHeader);
        PostSOPrepaymentInvoice(SalesHeader);

        // [WHEN] Posted Prepayment Credit Memo for Sales Order
        CrMemoNo := PostSOPrepaymentCrMemo(SalesHeader);

        // [THEN] Credit Memo contains correct Payment Discount
        VerifyPmtDiscOnCustLedgEntry(SalesHeader."Bill-to Customer No.", CrMemoNo, -ExpectedAmount);

        // [THEN] "Shipment Date" and "Responsibility Center" are copied to Credit Memo Line (TFS377440)
        VerifyShptDataAndRespCtrOnCrMemoLine(CrMemoNo, SalesLine."Shipment Date", SalesLine."Responsibility Center");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtPmtDiscOnInvVendLedgEntry()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        InvNo: Code[20];
        ExpectedAmount: Decimal;
    begin
        // Check that payment discount is correct in Vendor Ledger Entry after posting prepayment invoice

        CreatePurchDocInLCYWithPrepmt(PurchHeader, PurchLine, PurchHeader."Document Type"::Order);
        CalcAndUpdatePurchVATOnLines(PurchHeader, PurchLine);
        ExpectedAmount := CalcPurchExpectedAmount(PurchHeader);
        InvNo :=
          PostPOPrepaymentInvoice(PurchHeader);
        VerifyPmtDiscOnVendLedgEntry(PurchHeader."Pay-to Vendor No.", InvNo, -ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtPmtDiscOnCrMemoVendLedgEntry()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        CrMemoNo: Code[20];
        ExpectedAmount: Decimal;
    begin
        // Check that payment discount is correct in Vendor Ledger Entry after posting prepayment cr. memo

        CreatePurchDocInLCYWithPrepmt(PurchHeader, PurchLine, PurchHeader."Document Type"::Order);
        CalcAndUpdatePurchVATOnLines(PurchHeader, PurchLine);
        ExpectedAmount := CalcPurchExpectedAmount(PurchHeader);
        PostPOPrepaymentInvoice(PurchHeader);
        CrMemoNo :=
          PostPOPrepaymentCrMemo(PurchHeader);
        VerifyPmtDiscOnVendLedgEntry(PurchHeader."Pay-to Vendor No.", CrMemoNo, ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtPmtDiscWithFCYOnInvCustLedgEntry()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InvNo: Code[20];
        ExpectedAmount: Decimal;
    begin
        // Check that payment discount with FCY is correct in Customer Ledger Entry after posting prepayment invoice

        CreateSalesDocInFCYWithPrepmt(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        CalcAndUpdateSalesVATOnLines(SalesHeader, SalesLine);
        ExpectedAmount := CalcSalesExpectedAmount(SalesHeader);
        InvNo :=
          PostSOPrepaymentInvoice(SalesHeader);
        VerifyPmtDiscOnCustLedgEntry(SalesHeader."Bill-to Customer No.", InvNo, ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtPmtDiscWithFCYOnCrMemoCustLedgEntry()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CrMemoNo: Code[20];
        ExpectedAmount: Decimal;
    begin
        // Check that payment discount with FCY is correct in Customer Ledger Entry after posting prepayment invoice

        CreateSalesDocInFCYWithPrepmt(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        CalcAndUpdateSalesVATOnLines(SalesHeader, SalesLine);
        ExpectedAmount := CalcSalesExpectedAmount(SalesHeader);
        PostSOPrepaymentInvoice(SalesHeader);
        CrMemoNo :=
          PostSOPrepaymentCrMemo(SalesHeader);
        VerifyPmtDiscOnCustLedgEntry(SalesHeader."Bill-to Customer No.", CrMemoNo, -ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtPmtDiscWithFCYOnInvVendLedgEntry()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        InvNo: Code[20];
        ExpectedAmount: Decimal;
    begin
        // Check that payment discount with FCY is correct in Vendor Ledger Entry after posting prepayment invoice

        CreatePurchDocInFCYWithPrepmt(PurchHeader, PurchLine, PurchHeader."Document Type"::Order);
        CalcAndUpdatePurchVATOnLines(PurchHeader, PurchLine);
        ExpectedAmount := CalcPurchExpectedAmount(PurchHeader);
        InvNo :=
          PostPOPrepaymentInvoice(PurchHeader);
        VerifyPmtDiscOnVendLedgEntry(PurchHeader."Pay-to Vendor No.", InvNo, -ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtPmtDiscWithFCYOnCrMemoVendLedgEntry()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        CrMemoNo: Code[20];
        ExpectedAmount: Decimal;
    begin
        // Check that payment discount with FCY is correct in Vendor Ledger Entry after posting prepayment cr. memo

        CreatePurchDocInFCYWithPrepmt(PurchHeader, PurchLine, PurchHeader."Document Type"::Order);
        CalcAndUpdatePurchVATOnLines(PurchHeader, PurchLine);
        ExpectedAmount := CalcPurchExpectedAmount(PurchHeader);
        PostPOPrepaymentInvoice(PurchHeader);
        CrMemoNo :=
          PostPOPrepaymentCrMemo(PurchHeader);
        VerifyPmtDiscOnVendLedgEntry(PurchHeader."Pay-to Vendor No.", CrMemoNo, ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPmtDiscOnCustLedgEntryWithPricesInclVAT()
    begin
        SalesPmtDiscOnCustLedgEntry(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPmtDiscOnCustLedgEntryWithPricesExclVAT()
    begin
        SalesPmtDiscOnCustLedgEntry(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPmtDiscOnVendLedgEntryWithPricesInclVAT()
    begin
        PurchPmtDiscOnVendLedgEntry(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPmtDiscOnVendLedgEntryWithPricesExclVAT()
    begin
        PurchPmtDiscOnVendLedgEntry(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServPmtDiscOnCustLedgEntryWithPricesInclVAT()
    begin
        ServPmtDiscOnCustLedgEntry(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServPmtDiscOnCustLedgEntryWithPricesExclVAT()
    begin
        ServPmtDiscOnCustLedgEntry(false);
    end;

    local procedure SalesPmtDiscOnCustLedgEntry(PricesInclVAT: Boolean)
    var
        SalesHeader: Record "Sales Header";
        InvNo: Code[20];
        ExpectedAmount: Decimal;
    begin
        CreateSalesDocWithPricesInclVAT(SalesHeader, PricesInclVAT);
        ExpectedAmount :=
          Round(GetSalesVATBase(SalesHeader) * SalesHeader."Payment Discount %" / 100, LibraryERM.GetAmountRoundingPrecision());
        InvNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        VerifyPmtDiscOnCustLedgEntry(
          SalesHeader."Bill-to Customer No.", InvNo, ExpectedAmount);
    end;

    local procedure PurchPmtDiscOnVendLedgEntry(PricesInclVAT: Boolean)
    var
        PurchHeader: Record "Purchase Header";
        InvNo: Code[20];
        ExpectedAmount: Decimal;
    begin
        CreatePurchDocWithPricesInclVAT(PurchHeader, PricesInclVAT);
        ExpectedAmount :=
          Round(GetPurchVATBase(PurchHeader) * PurchHeader."Payment Discount %" / 100, LibraryERM.GetAmountRoundingPrecision());
        InvNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
        VerifyPmtDiscOnVendLedgEntry(
          PurchHeader."Pay-to Vendor No.", InvNo, -ExpectedAmount);
    end;

    local procedure ServPmtDiscOnCustLedgEntry(PricesInclVAT: Boolean)
    var
        ServHeader: Record "Service Header";
        ExpectedAmount: Decimal;
    begin
        CreateServDocWithPricesInclVAT(ServHeader, ServHeader."Document Type"::Order, PricesInclVAT);
        ExpectedAmount :=
          Round(GetServVATBase(ServHeader) * ServHeader."Payment Discount %" / 100, LibraryERM.GetAmountRoundingPrecision());
        LibraryService.PostServiceOrder(ServHeader, true, false, true);
        VerifyPmtDiscOnCustLedgEntry(
          ServHeader."Bill-to Customer No.", GetPostedServDocNo(ServHeader."No."), ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPmtDiscWithAdjustForPmtDisc()
    var
        OldGLSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        TotalAmtInclVAT: Decimal;
        InvNo: Code[20];
    begin
        // Verify that payment discount calculates correctly when using Adjust For Pmt. Disc. option.

        SetAdjPmtDisc(OldGLSetup);
        TotalAmtInclVAT := CreateNormalSalesDoc(SalesHeader);
        InvNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        TearDownGLSetup(OldGLSetup."Adjust for Payment Disc.", OldGLSetup."VAT Tolerance %", OldGLSetup."Pmt. Disc. Excl. VAT");
        VerifyOrigPmtDiscPossibleOnCustLedgEntry(
          SalesHeader."Bill-to Customer No.", InvNo, Round(TotalAmtInclVAT * SalesHeader."Payment Discount %" / 100));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPmtDiscWithAdjustForPmtDisc()
    var
        OldGLSetup: Record "General Ledger Setup";
        PurchHeader: Record "Purchase Header";
        TotalAmtInclVAT: Decimal;
        InvNo: Code[20];
    begin
        // Verify that payment discount calculates correctly when using Adjust For Pmt. Disc. option.

        SetAdjPmtDisc(OldGLSetup);
        TotalAmtInclVAT := CreateNormalPurchDoc(PurchHeader);
        InvNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
        TearDownGLSetup(OldGLSetup."Adjust for Payment Disc.", OldGLSetup."VAT Tolerance %", OldGLSetup."Pmt. Disc. Excl. VAT");
        VerifyOrigPmtDiscPossibleOnVendLedgEntry(
          PurchHeader."Pay-to Vendor No.", InvNo, -Round(TotalAmtInclVAT * PurchHeader."Payment Discount %" / 100));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesVATBaseOnPrepmtInvLineBuf()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempPrepmtInvLineBuf: Record "Prepayment Inv. Line Buffer" temporary;
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
    begin
        // [FEATURE] [Prepayment Invoice] [UT]
        // [SCENARIO 375192] Prepayment Invoice Line should contain lowered VAT Base in case of discount according to Payment Terms

        // [GIVEN] Sales Order with 100% Prepayment, Amount = 100 and "Payment Discount %" = 2%
        CreateSalesDocInFCYWithPrepmt(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        SalesHeader."Payment Discount %" := LibraryRandom.RandInt(10);
        SalesLine.Validate("Prepayment %", 100);
        SalesLine.Modify();

        // [WHEN] Create Prepayment Invoice
        CalcAndUpdateSalesVATOnLines(SalesHeader, SalesLine);
        SalesPostPrepayments.FillInvLineBuffer(SalesHeader, SalesLine, TempPrepmtInvLineBuf);

        // [THEN] VAT Base Amount for Prepayment Invoice is calculated correctly (100 * (1 - 0,02)) = 98
        TempPrepmtInvLineBuf.TestField("VAT Base Amount", Round(SalesLine.Amount * (1 - (SalesHeader."Payment Discount %" / 100))));
    end;

#if not CLEAN27
    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ServiceInvoiceStatisticsPageHandler')]
    procedure PaymentDiscInVATAmtLineOfServInvoice()
    var
        ServHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        PostedServiceInvoice: TestPage "Posted Service Invoice";
        ExpectedAmount: Decimal;
    begin
        // [FEATURE] [Service Invoice]
        // [SCENARIO 375681] "VAT Base (Lowered)" should be shown in Statistics of Posted Service Invoice and contain VAT Base excluding Payment Discount

        // [GIVEN] Posted Service Invoice having 1000 VAT Base and 2% Payment Discount
        CreateServDocWithPricesInclVAT(ServHeader, ServHeader."Document Type"::Order, false);
        ExpectedAmount :=
          Round(GetServVATBase(ServHeader) * (1 - ServHeader."Payment Discount %" / 100), LibraryERM.GetAmountRoundingPrecision());
        LibraryService.PostServiceOrder(ServHeader, true, false, true);
        ServiceInvoiceHeader.SetFilter("Order No.", ServHeader."No.");
        ServiceInvoiceHeader.FindFirst();

        // [WHEN] Open Posted Service Invoice Statistics
        LibraryVariableStorage.Enqueue(ExpectedAmount);
        PostedServiceInvoice.OpenEdit();
        PostedServiceInvoice.GotoRecord(ServiceInvoiceHeader);
        PostedServiceInvoice.Statistics.Invoke();
        PostedServiceInvoice.Close();

        // [THEN] "VAT Base (Lowered)" equals to 980, calculated as 1000 * (1 - 0,02)
        // Validation in page handler
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ServiceCreditMemoStatisticsPageHandler')]
    procedure PaymentDiscInVATAmtLineOfServCrMemo()
    var
        ServHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        PostedServiceCreditMemo: TestPage "Posted Service Credit Memo";
        ExpectedAmount: Decimal;
    begin
        // [FEATURE] [Service Cr Memo]
        // [SCENARIO 375789] "VAT Base (Lowered)" should be shown in Statistics of Posted Service Credit Memo and contain VAT Base excluding Payment Discount

        // [GIVEN] Posted Service Credit Memo having 1000 VAT Base and 2% VAT Base Discount
        CreateServCrMemo(ServHeader);
        ExpectedAmount :=
          Round(GetServVATBase(ServHeader) * (1 - ServHeader."VAT Base Discount %" / 100), LibraryERM.GetAmountRoundingPrecision());
        LibraryService.PostServiceOrder(ServHeader, true, false, true);
        ServiceCrMemoHeader.Get(ServHeader."Last Posting No.");

        // [WHEN] Open Posted Service Credit Memo Statistics
        LibraryVariableStorage.Enqueue(ExpectedAmount);
        PostedServiceCreditMemo.OpenEdit();
        PostedServiceCreditMemo.GotoRecord(ServiceCrMemoHeader);
        PostedServiceCreditMemo.Statistics.Invoke();
        PostedServiceCreditMemo.Close();

        // [THEN] "VAT Base (Lowered)" equals to 980, calculated as 1000 * (1 - 0,02)
        // Validation in page handler
    end;
#endif
    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ServiceInvoiceStatisticsPageHandlerNM')]
    procedure PaymentDiscInVATAmtLineOfServInvoiceNM()
    var
        ServHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        PostedServiceInvoice: TestPage "Posted Service Invoice";
        ExpectedAmount: Decimal;
    begin
        // [FEATURE] [Service Invoice]
        // [SCENARIO 375681] "VAT Base (Lowered)" should be shown in Statistics of Posted Service Invoice and contain VAT Base excluding Payment Discount

        // [GIVEN] Posted Service Invoice having 1000 VAT Base and 2% Payment Discount
        CreateServDocWithPricesInclVAT(ServHeader, ServHeader."Document Type"::Order, false);
        ExpectedAmount :=
          Round(GetServVATBase(ServHeader) * (1 - ServHeader."Payment Discount %" / 100), LibraryERM.GetAmountRoundingPrecision());
        LibraryService.PostServiceOrder(ServHeader, true, false, true);
        ServiceInvoiceHeader.SetFilter("Order No.", ServHeader."No.");
        ServiceInvoiceHeader.FindFirst();

        // [WHEN] Open Posted Service Invoice Statistics
        LibraryVariableStorage.Enqueue(ExpectedAmount);
        PostedServiceInvoice.OpenEdit();
        PostedServiceInvoice.GotoRecord(ServiceInvoiceHeader);
        PostedServiceInvoice.ServiceStatistics.Invoke();
        PostedServiceInvoice.Close();

        // [THEN] "VAT Base (Lowered)" equals to 980, calculated as 1000 * (1 - 0,02)
        // Validation in page handler
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ServiceCreditMemoStatisticsPageHandlerNM')]
    procedure PaymentDiscInVATAmtLineOfServCrMemoNM()
    var
        ServHeader: Record "Service Header";
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        PostedServiceCreditMemo: TestPage "Posted Service Credit Memo";
        ExpectedAmount: Decimal;
    begin
        // [FEATURE] [Service Cr Memo]
        // [SCENARIO 375789] "VAT Base (Lowered)" should be shown in Statistics of Posted Service Credit Memo and contain VAT Base excluding Payment Discount

        // [GIVEN] Posted Service Credit Memo having 1000 VAT Base and 2% VAT Base Discount
        CreateServCrMemo(ServHeader);
        ExpectedAmount :=
          Round(GetServVATBase(ServHeader) * (1 - ServHeader."VAT Base Discount %" / 100), LibraryERM.GetAmountRoundingPrecision());
        LibraryService.PostServiceOrder(ServHeader, true, false, true);
        ServiceCrMemoHeader.Get(ServHeader."Last Posting No.");

        // [WHEN] Open Posted Service Credit Memo Statistics
        LibraryVariableStorage.Enqueue(ExpectedAmount);
        PostedServiceCreditMemo.OpenEdit();
        PostedServiceCreditMemo.GotoRecord(ServiceCrMemoHeader);
        PostedServiceCreditMemo.ServiceStatistics.Invoke();
        PostedServiceCreditMemo.Close();

        // [THEN] "VAT Base (Lowered)" equals to 980, calculated as 1000 * (1 - 0,02)
        // Validation in page handler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATBaseBeforePmtDiscOnSalesPrepmtInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Prepayment] [Payment Discount]
        // [SCENARIO 212652] "Base Before Pmt. Disc" of VAT Entry is equal "Prepayment Line Amount" of Sales Line when post Prepayment Invoice with Payment Discount

        // [GIVEN] Sales Order with Payment Discount and "Prepayment Line Amount" = 50
        CreateSalesDocWithPmtDiscAndPrepmt(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);

        // [WHEN] Post Prepayment Invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] VAT Entry created with "Base Before Pmt. Disc" = 50
        SalesLine.Find();
        VerifyVATBaseBeforePmtDiscOnVATEntry(
          SalesHeader."Posting Date", FindSalesPrepmtInvoice(SalesHeader."Bill-to Customer No.", SalesHeader."No."),
          -SalesLine."Prepmt. Amt. Inv.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATBaseBeforePmtDiscOnPurchPrepmtInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Prepayment] [Payment Discount]
        // [SCENARIO 212652] "Base Before Pmt. Disc" of VAT Entry is equal "Prepayment Line Amount" of Purchase Line when post Prepayment Invoice with Payment Discount

        // [GIVEN] Purchase Order with Payment Discount and "Prepayment Line Amount" = 50
        CreatePurchDocWithPmtDiscAndPrepmt(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);

        // [WHEN] Post Prepayment Invoice
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // [THEN] VAT Entry created with "Base Before Pmt. Disc" = 50
        PurchaseLine.Find();
        VerifyVATBaseBeforePmtDiscOnVATEntry(
          PurchaseHeader."Posting Date", FindPurchPrepmtInvoice(PurchaseHeader."Pay-to Vendor No.", PurchaseHeader."No."),
          PurchaseLine."Prepmt. Amt. Inv.");
    end;

    local procedure CreateCust(): Code[20]
    var
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateVend(): Code[20]
    var
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        exit(Item."No.");
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreatePrepaymentAccount(GeneralPostingSetup: Record "General Posting Setup"; VATBusPostingGroup: Code[20]; VATProdPostingGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure SetupSalesPrepaymentAccount(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        FindSalesLine(SalesLine, SalesHeader);
        repeat
            GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
            GeneralPostingSetup."Sales Prepayments Account" :=
                CreatePrepaymentAccount(GeneralPostingSetup, SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
            GeneralPostingSetup.Modify(true);
        until SalesLine.Next() = 0;
    end;

    local procedure SetupPurchasePrepaymentAccount(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        repeat
            GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
            GeneralPostingSetup."Purch. Prepayments Account" :=
                CreatePrepaymentAccount(GeneralPostingSetup, PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");
            GeneralPostingSetup.Modify(true);
        until PurchaseLine.Next() = 0;
    end;

    local procedure UpdateGLSetup(VATTolerancePct: Decimal; PmtDiscExclVAT: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        if PmtDiscExclVAT then begin
            GLSetup.Validate("Pmt. Disc. Excl. VAT", PmtDiscExclVAT);
            GLSetup.Validate("VAT Tolerance %", VATTolerancePct);
        end else begin
            GLSetup.Validate("VAT Tolerance %", VATTolerancePct);
            GLSetup.Validate("Pmt. Disc. Excl. VAT", PmtDiscExclVAT);
        end;
        GLSetup.Modify(true);
    end;

    local procedure SetAdjPmtDisc(var OldGLSetup: Record "General Ledger Setup")
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        OldGLSetup := GLSetup;
        GLSetup.Validate("VAT Tolerance %", 0);
        GLSetup.Validate("Pmt. Disc. Excl. VAT", false);
        GLSetup.Validate("Adjust for Payment Disc.", true);
        GLSetup.Modify(true);
    end;

    local procedure TearDownGLSetup(AdjPmtDisc: Boolean; VATTolerancePct: Decimal; PmtDiscExclVAT: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.Validate("Adjust for Payment Disc.", AdjPmtDisc);
        GLSetup.Validate("Pmt. Disc. Excl. VAT", PmtDiscExclVAT);
        GLSetup.Validate("VAT Tolerance %", VATTolerancePct);
        GLSetup.Modify(true);
    end;

    local procedure CreateSalesDocWithPricesInclVAT(var SalesHeader: Record "Sales Header"; PricesInclVAT: Boolean)
    var
        SalesLine: Record "Sales Line";
        i: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCust());
        SalesHeader.Validate("Prices Including VAT", PricesInclVAT);
        SalesHeader.Modify(true);
        for i := 1 to LibraryRandom.RandIntInRange(3, 10) do
            CreateSalesLine(SalesLine, SalesHeader);
    end;

    local procedure CreateSalesDocInLCYWithPrepmt(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocType: Enum "Sales Document Type")
    begin
        CreateSalesDocWithPrepmt(SalesHeader, SalesLine, DocType, '');
    end;

    local procedure CreateSalesDocInFCYWithPrepmt(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocType: Enum "Sales Document Type")
    begin
        CreateSalesDocWithPrepmt(SalesHeader, SalesLine, DocType, CreateCurrency());
    end;

    local procedure CreateSalesDocWithPrepmt(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocType: Enum "Sales Document Type"; CurrencyCode: Code[10])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, CreateCust());
        SalesHeader."Shipment Date" := WorkDate();
        SalesHeader."Responsibility Center" := LibraryUtility.GenerateGUID();
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
        CreateSalesLine(SalesLine, SalesHeader);
        AddSOPrepayment(SalesHeader, LibraryRandom.RandIntInRange(10, 40));
    end;

    local procedure CreateSalesDocWithMultipleLinesAndPrepmt(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"): Decimal
    var
        SalesLine: Record "Sales Line";
        i: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, CreateCust());
        for i := 1 to LibraryRandom.RandIntInRange(3, 10) do
            CreateSalesLine(SalesLine, SalesHeader);
        AddSOPrepayment(SalesHeader, LibraryRandom.RandIntInRange(10, 40));
        exit(
          Round(GetSalesVATBase(SalesHeader) * SalesHeader."Prepayment %" / 100, LibraryERM.GetAmountRoundingPrecision()));
    end;

    local procedure CreateSalesDocWithPmtDiscAndPrepmt(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocType: Enum "Sales Document Type")
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, CreateCust());
        SalesHeader.Validate("Payment Discount %", LibraryRandom.RandInt(10));
        SalesHeader.Modify(true);
        CreateSalesLine(SalesLine, SalesHeader);
        AddSOPrepayment(SalesHeader, LibraryRandom.RandIntInRange(10, 40));
    end;

    local procedure CreateNormalSalesDoc(var SalesHeader: Record "Sales Header"): Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCust());
        CreateSalesLine(SalesLine, SalesHeader);
        exit(SalesLine."Amount Including VAT");
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchDocWithPricesInclVAT(var PurchHeader: Record "Purchase Header"; PricesInclVAT: Boolean)
    var
        PurchLine: Record "Purchase Line";
        i: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, CreateVend());
        PurchHeader.Validate("Prices Including VAT", PricesInclVAT);
        PurchHeader.Modify(true);
        for i := 1 to LibraryRandom.RandIntInRange(3, 10) do
            CreatePurchLine(PurchLine, PurchHeader);
    end;

    local procedure CreatePurchDocInLCYWithPrepmt(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; DocType: Enum "Purchase Document Type")
    begin
        CreatePurchDocWithPrepmt(PurchHeader, PurchLine, DocType, '');
    end;

    local procedure CreatePurchDocInFCYWithPrepmt(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; DocType: Enum "Purchase Document Type")
    begin
        CreatePurchDocWithPrepmt(PurchHeader, PurchLine, DocType, CreateCurrency());
    end;

    local procedure CreatePurchDocWithPrepmt(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; DocType: Enum "Purchase Document Type"; CurrencyCode: Code[10])
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, DocType, CreateVend());
        PurchHeader.Validate("Currency Code", CurrencyCode);
        PurchHeader.Modify(true);
        CreatePurchLine(PurchLine, PurchHeader);
        AddPOPrepayment(PurchHeader, LibraryRandom.RandIntInRange(10, 40));
    end;

    local procedure CreatePurchDocWithMultipleLinesAndPrepmt(var PurchHeader: Record "Purchase Header"; DocType: Enum "Purchase Document Type"): Decimal
    var
        PurchLine: Record "Purchase Line";
        i: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, DocType, CreateVend());
        for i := 1 to LibraryRandom.RandIntInRange(3, 10) do
            CreatePurchLine(PurchLine, PurchHeader);
        AddPOPrepayment(PurchHeader, LibraryRandom.RandIntInRange(10, 40));
        exit(
          Round(GetPurchVATBase(PurchHeader) * PurchHeader."Prepayment %" / 100, LibraryERM.GetAmountRoundingPrecision()));
    end;

    local procedure CreatePurchDocWithPmtDiscAndPrepmt(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; DocType: Enum "Purchase Document Type")
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, DocType, CreateVend());
        PurchHeader.Validate("Payment Discount %", LibraryRandom.RandInt(10));
        PurchHeader.Modify(true);
        CreatePurchLine(PurchLine, PurchHeader);
        AddPOPrepayment(PurchHeader, LibraryRandom.RandIntInRange(10, 40));
    end;

    local procedure CreateNormalPurchDoc(var PurchHeader: Record "Purchase Header"): Decimal
    var
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, CreateVend());
        CreatePurchLine(PurchLine, PurchHeader);
        exit(PurchLine."Amount Including VAT");
    end;

    local procedure CreatePurchLine(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header")
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::Item, CreateItem(), LibraryRandom.RandInt(100));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchLine.Modify(true);
    end;

    local procedure CreateServDocWithPricesInclVAT(var ServHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; PricesInclVAT: Boolean)
    var
        i: Integer;
    begin
        CreateServHeader(ServHeader, DocumentType, PricesInclVAT);
        for i := 1 to LibraryRandom.RandIntInRange(3, 10) do
            CreateServLineWithServItemLine(ServHeader);
    end;

    local procedure CreateServCrMemo(var ServHeader: Record "Service Header")
    var
        ServLine: Record "Service Line";
        i: Integer;
    begin
        CreateServHeader(ServHeader, ServHeader."Document Type"::"Credit Memo", false);
        for i := 1 to LibraryRandom.RandIntInRange(3, 10) do
            CreateServLine(ServHeader, ServLine);
    end;

    local procedure CreateServHeader(var ServHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; PricesInclVAT: Boolean)
    begin
        LibraryService.CreateServiceHeader(ServHeader, DocumentType, CreateCust());
        ServHeader.Validate("Prices Including VAT", PricesInclVAT);
        ServHeader.Modify(true);
    end;

    local procedure CreateServLineWithServItemLine(ServHeader: Record "Service Header")
    var
        ServItemLine: Record "Service Item Line";
        ServLine: Record "Service Line";
    begin
        LibraryService.CreateServiceItemLine(ServItemLine, ServHeader, '');
        CreateServLine(ServHeader, ServLine);
        ServLine.Validate("Service Item Line No.", ServItemLine."Line No.");
        ServLine.Modify(true);
    end;

    local procedure CreateServLine(ServHeader: Record "Service Header"; var ServLine: Record "Service Line")
    begin
        LibraryService.CreateServiceLine(ServLine, ServHeader, ServLine.Type::Item, CreateItem());
        ServLine.Validate(Quantity, LibraryRandom.RandInt(50));
        ServLine.Validate("Qty. to Invoice", ServLine.Quantity);
        ServLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServLine.Modify(true);
    end;

    local procedure GetPrepmtInvDocType(): Integer
    begin
        exit(0);
    end;

    local procedure AddSOPrepayment(var SalesHeader: Record "Sales Header"; PrepaymentPercentage: Decimal)
    begin
        SetupSalesPrepaymentAccount(SalesHeader);
        SalesHeader.Validate("Prepayment %", PrepaymentPercentage);
        SalesHeader.Modify(true);
    end;

    local procedure PostSOPrepaymentInvoice(var SalesHeader: Record "Sales Header"): Code[20]
    var
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
    begin
        SalesPostPrepayments.Invoice(SalesHeader);
        exit(SalesHeader."Last Prepayment No.");
    end;

    local procedure PostSOPrepaymentCrMemo(var SalesHeader: Record "Sales Header"): Code[20]
    var
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
    begin
        SalesPostPrepayments.CreditMemo(SalesHeader);
        exit(SalesHeader."Last Prepmt. Cr. Memo No.");
    end;

    local procedure AddPOPrepayment(var PurchaseHeader: Record "Purchase Header"; PrepaymentPercentage: Decimal)
    begin
        SetupPurchasePrepaymentAccount(PurchaseHeader);
        PurchaseHeader.Validate("Prepayment %", PrepaymentPercentage);
        PurchaseHeader.Modify(true);
        UpdatePrepaymentPctOnPurchaseLines(PurchaseHeader);
    end;

    local procedure PostPOPrepaymentInvoice(var PurchaseHeader: Record "Purchase Header"): Code[20]
    var
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
    begin
        PurchasePostPrepayments.Invoice(PurchaseHeader);
        exit(PurchaseHeader."Last Prepayment No.");
    end;

    local procedure PostPOPrepaymentCrMemo(var PurchaseHeader: Record "Purchase Header"): Code[20]
    var
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
    begin
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        PurchasePostPrepayments.CreditMemo(PurchaseHeader);
        exit(PurchaseHeader."Last Prepmt. Cr. Memo No.");
    end;

    local procedure UpdatePrepaymentPctOnPurchaseLines(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        FindPurchaseLine(PurchaseLine, PurchaseHeader);
        repeat
            PurchaseLine.Validate("Prepayment %", PurchaseHeader."Prepayment %");
            PurchaseLine.Modify(true);
        until PurchaseLine.Next() = 0;
    end;

    local procedure CalcAndUpdateSalesVATOnLines(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        VATAmountLine: Record "VAT Amount Line" temporary;
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
    begin
        SalesPostPrepayments.CalcVATAmountLines(SalesHeader, SalesLine, VATAmountLine, GetPrepmtInvDocType());
        SalesPostPrepayments.UpdateVATOnLines(SalesHeader, SalesLine, VATAmountLine, GetPrepmtInvDocType());
    end;

    local procedure CalcAndUpdatePurchVATOnLines(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line")
    var
        VATAmountLine: Record "VAT Amount Line" temporary;
        PurchPostPrepayments: Codeunit "Purchase-Post Prepayments";
    begin
        PurchPostPrepayments.CalcVATAmountLines(PurchHeader, PurchLine, VATAmountLine, GetPrepmtInvDocType());
        PurchPostPrepayments.UpdateVATOnLines(PurchHeader, PurchLine, VATAmountLine, GetPrepmtInvDocType());
    end;

    local procedure CalcSalesExpectedAmount(SalesHeader: Record "Sales Header"): Decimal
    begin
        if SalesHeader."Currency Code" = '' then
            SalesHeader."Currency Factor" := 1;
        exit(
          Round(
            GetSalesVATBase(SalesHeader) *
            SalesHeader."Prepayment %" / 100 * SalesHeader."Payment Discount %" / 100 / SalesHeader."Currency Factor",
            LibraryERM.GetAmountRoundingPrecision()));
    end;

    local procedure CalcPurchExpectedAmount(PurchHeader: Record "Purchase Header"): Decimal
    begin
        if PurchHeader."Currency Code" = '' then
            PurchHeader."Currency Factor" := 1;
        exit(
          Round(
            GetPurchVATBase(PurchHeader) *
            PurchHeader."Prepayment %" / 100 * PurchHeader."Payment Discount %" / 100 / PurchHeader."Currency Factor",
            LibraryERM.GetAmountRoundingPrecision()));
    end;

    local procedure GetSalesVATBase(SalesHeader: Record "Sales Header"): Decimal
    var
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line" temporary;
    begin
        SalesLine.CalcVATAmountLines(0, SalesHeader, SalesLine, VATAmountLine);
        VATAmountLine.CalcSums("VAT Base");
        exit(VATAmountLine."VAT Base");
    end;

    local procedure GetPurchVATBase(PurchHeader: Record "Purchase Header"): Decimal
    var
        PurchLine: Record "Purchase Line";
        VATAmountLine: Record "VAT Amount Line" temporary;
    begin
        PurchLine.CalcVATAmountLines(0, PurchHeader, PurchLine, VATAmountLine);
        VATAmountLine.CalcSums("VAT Base");
        exit(VATAmountLine."VAT Base");
    end;

    local procedure GetServVATBase(ServHeader: Record "Service Header"): Decimal
    var
        ServLine: Record "Service Line";
        VATAmountLine: Record "VAT Amount Line" temporary;
    begin
        ServLine.CalcVATAmountLines(0, ServHeader, ServLine, VATAmountLine, false);
        VATAmountLine.CalcSums("VAT Base");
        exit(VATAmountLine."VAT Base");
    end;

    local procedure GetPostedServDocNo(ServDocNo: Code[20]): Code[20]
    var
        ServInvHeader: Record "Service Invoice Header";
    begin
        ServInvHeader.SetRange("Order No.", ServDocNo);
        ServInvHeader.FindLast();
        exit(ServInvHeader."No.");
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindSet();
    end;

    local procedure FindSalesPrepmtInvoice(CustNo: Code[20]; OrderNo: Code[20]): Code[20]
    var
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        SalesInvHeader.SetRange("Bill-to Customer No.", CustNo);
        SalesInvHeader.SetRange("Prepayment Invoice", true);
        SalesInvHeader.SetRange("Prepayment Order No.", OrderNo);
        SalesInvHeader.FindFirst();
        exit(SalesInvHeader."No.");
    end;

    local procedure FindPurchPrepmtInvoice(VendorNo: Code[20]; OrderNo: Code[20]): Code[20]
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchInvHeader.SetRange("Prepayment Invoice", true);
        PurchInvHeader.SetRange("Prepayment Order No.", OrderNo);
        PurchInvHeader.FindFirst();
        exit(PurchInvHeader."No.");
    end;

    local procedure VerifyPmtDiscOnSalesInvLines(DocNo: Code[20]; CustNo: Code[20]; ExpectedAmount: Decimal)
    var
        SalesInvLine: Record "Sales Invoice Line";
        TotalPmtDiscAmount: Decimal;
    begin
        SalesInvLine.SetRange("Document No.", DocNo);
        SalesInvLine.SetRange("Sell-to Customer No.", CustNo);
        SalesInvLine.FindSet();
        repeat
            TotalPmtDiscAmount += SalesInvLine."Pmt. Discount Amount";
        until SalesInvLine.Next() = 0;
        Assert.AreEqual(
          ExpectedAmount, TotalPmtDiscAmount,
          StrSubstNo(PmtDiscOnDocLineErr, SalesInvLine.FieldCaption("Pmt. Discount Amount"), SalesInvLine.TableCaption(), DocNo, ExpectedAmount));
    end;

    local procedure VerifyPmtDiscOnSalesCrMemoLines(DocNo: Code[20]; CustNo: Code[20]; ExpectedAmount: Decimal)
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        TotalPmtDiscAmount: Decimal;
    begin
        SalesCrMemoLine.SetRange("Document No.", DocNo);
        SalesCrMemoLine.SetRange("Sell-to Customer No.", CustNo);
        SalesCrMemoLine.FindSet();
        repeat
            TotalPmtDiscAmount += SalesCrMemoLine."Pmt. Discount Amount";
        until SalesCrMemoLine.Next() = 0;
        Assert.AreEqual(
          ExpectedAmount, TotalPmtDiscAmount,
          StrSubstNo(PmtDiscOnDocLineErr, SalesCrMemoLine.FieldCaption("Pmt. Discount Amount"), SalesCrMemoLine.TableCaption(), DocNo, ExpectedAmount));
    end;

    local procedure VerifyPmtDiscOnCustLedgEntry(CustNo: Code[20]; DocNo: Code[20]; ExpectedAmount: Decimal)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.SetRange("Customer No.", CustNo);
        CustLedgEntry.SetRange("Document No.", DocNo);
        CustLedgEntry.FindFirst();
        CustLedgEntry.TestField("Orig. Pmt. Disc. Possible(LCY)", ExpectedAmount);
    end;

    local procedure VerifyPmtDiscOnPurchInvLines(DocNo: Code[20]; VendNo: Code[20]; ExpectedAmount: Decimal)
    var
        PurchInvLine: Record "Purch. Inv. Line";
        TotalPmtDiscAmount: Decimal;
    begin
        PurchInvLine.SetRange("Document No.", DocNo);
        PurchInvLine.SetRange("Pay-to Vendor No.", VendNo);
        PurchInvLine.FindSet();
        repeat
            TotalPmtDiscAmount += PurchInvLine."Pmt. Discount Amount";
        until PurchInvLine.Next() = 0;
        Assert.AreEqual(
          ExpectedAmount, TotalPmtDiscAmount,
          StrSubstNo(PmtDiscOnDocLineErr, PurchInvLine.FieldCaption("Pmt. Discount Amount"), PurchInvLine.TableCaption(), DocNo, ExpectedAmount));
    end;

    local procedure VerifyPmtDiscOnPurchCrMemoLines(DocNo: Code[20]; VendNo: Code[20]; ExpectedAmount: Decimal)
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
        TotalPmtDiscAmount: Decimal;
    begin
        PurchCrMemoLine.SetRange("Document No.", DocNo);
        PurchCrMemoLine.SetRange("Pay-to Vendor No.", VendNo);
        PurchCrMemoLine.FindSet();
        repeat
            TotalPmtDiscAmount += PurchCrMemoLine."Pmt. Discount Amount";
        until PurchCrMemoLine.Next() = 0;
        Assert.AreEqual(
          ExpectedAmount, TotalPmtDiscAmount,
          StrSubstNo(PmtDiscOnDocLineErr, PurchCrMemoLine.FieldCaption("Pmt. Discount Amount"), PurchCrMemoLine.TableCaption(), DocNo, ExpectedAmount));
    end;

    local procedure VerifyPmtDiscOnVendLedgEntry(VendNo: Code[20]; DocNo: Code[20]; ExpectedAmount: Decimal)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.SetRange("Vendor No.", VendNo);
        VendLedgEntry.SetRange("Document No.", DocNo);
        VendLedgEntry.FindFirst();
        VendLedgEntry.TestField("Orig. Pmt. Disc. Possible(LCY)", ExpectedAmount);
    end;

    local procedure VerifyOrigPmtDiscPossibleOnCustLedgEntry(CustNo: Code[20]; DocNo: Code[20]; ExpectedAmount: Decimal)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.SetRange("Customer No.", CustNo);
        CustLedgEntry.SetRange("Document No.", DocNo);
        CustLedgEntry.FindLast();
        Assert.AreEqual(
          ExpectedAmount, CustLedgEntry."Original Pmt. Disc. Possible",
          StrSubstNo(WrongFieldValueErr, CustLedgEntry.FieldCaption("Original Pmt. Disc. Possible"), CustLedgEntry.TableCaption));
    end;

    local procedure VerifyOrigPmtDiscPossibleOnVendLedgEntry(CustNo: Code[20]; DocNo: Code[20]; ExpectedAmount: Decimal)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.SetRange("Vendor No.", CustNo);
        VendLedgEntry.SetRange("Document No.", DocNo);
        VendLedgEntry.FindLast();
        Assert.AreEqual(
          ExpectedAmount, VendLedgEntry."Original Pmt. Disc. Possible",
          StrSubstNo(WrongFieldValueErr, VendLedgEntry.FieldCaption("Original Pmt. Disc. Possible"), VendLedgEntry.TableCaption));
    end;

    local procedure VerifyShptDataAndRespCtrOnCrMemoLine(CrMemoNo: Code[20]; ShipmentDate: Date; ResponsibilityCenter: Code[10])
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoLine.SetRange("Document No.", CrMemoNo);
        SalesCrMemoLine.FindFirst();
        SalesCrMemoLine.TestField("Shipment Date", ShipmentDate);
        SalesCrMemoLine.TestField("Responsibility Center", ResponsibilityCenter);
    end;

    local procedure VerifyVATBaseBeforePmtDiscOnVATEntry(PostingDate: Date; DocNo: Code[20]; Amount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Posting Date", PostingDate);
        VATEntry.SetRange("Document No.", DocNo);
        VATEntry.FindFirst();
        VATEntry.TestField("Base Before Pmt. Disc.", Amount);
    end;
#if not CLEAN27
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceInvoiceStatisticsPageHandler(var ServiceInvoiceStatistics: TestPage "Service Invoice Statistics")
    var
        ExpectedAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedAmount);
        ServiceInvoiceStatistics.Subform."VAT Base (Lowered)".AssertEquals(ExpectedAmount);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoStatisticsPageHandler(var ServiceCreditMemoStatistics: TestPage "Service Credit Memo Statistics")
    var
        ExpectedAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedAmount);
        ServiceCreditMemoStatistics.Subform."VAT Base (Lowered)".AssertEquals(ExpectedAmount);
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure ServiceInvoiceStatisticsPageHandlerNM(var ServiceInvoiceStatistics: TestPage "Service Invoice Statistics")
    var
        ExpectedAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedAmount);
        ServiceInvoiceStatistics.Subform."VAT Base (Lowered)".AssertEquals(ExpectedAmount);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ServiceCreditMemoStatisticsPageHandlerNM(var ServiceCreditMemoStatistics: TestPage "Service Credit Memo Statistics")
    var
        ExpectedAmount: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedAmount);
        ServiceCreditMemoStatistics.Subform."VAT Base (Lowered)".AssertEquals(ExpectedAmount);
    end;
}
