codeunit 134108 "ERM Sales Full Prepmt Rounding"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Prepayment] [Rounding] [Sales]
        IsInitialized := false;
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        CannotBeLessThanMsg: Label 'cannot be less than %1', Comment = '.';
        CannotBeMoreThanMsg: Label 'cannot be more than %1', Comment = '.';

    [Test]
    [Scope('OnPrem')]
    procedure ShipAllPartiallyGetShptsToInv()
    var
        SalesOrderHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Header";
        SalesOrderLine: Record "Sales Line";
        i: Integer;
    begin
        Initialize();
        SalesOrderHeader."Prices Including VAT" := false;
        PrepareSalesOrder(SalesOrderHeader);
        AddSpecificOrderLine100PctPrepmt(SalesOrderLine, SalesOrderHeader);
        PostSalesPrepmtInvoice(SalesOrderHeader);

        SalesInvoiceHeader."Sell-to Customer No." := SalesOrderHeader."Sell-to Customer No.";
        CreateSalesInvoice(SalesInvoiceHeader, SalesOrderHeader."Prices Including VAT");

        for i := 1 to 3 do begin
            UpdateQtysInLine(SalesOrderLine, 2, 0);
            SalesOrderHeader.Find();
            LibrarySales.PostSalesDocument(SalesOrderHeader, true, false);
            GetShipmentLine(SalesInvoiceHeader, SalesOrderHeader."Last Shipping No.");
        end;

        SalesOrderHeader.Find();
        LibrarySales.PostSalesDocument(SalesOrderHeader, true, false);
        GetShipmentLine(SalesInvoiceHeader, SalesOrderHeader."Last Shipping No.");

        LibrarySales.PostSalesDocument(SalesInvoiceHeader, false, true);
        VerifyZeroCustomerAccEntry();

        SalesOrderLine.Find();
        Assert.AreEqual(
          SalesOrderLine."Prepmt. Amt. Inv.",
          SalesOrderLine."Prepmt Amt Deducted", '"Prepmt Amt Deducted" should be equal to "Prepmt. Amt. Inv.".');
    end;

    local procedure AddSpecificOrderLine100PctPrepmt(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        // Magic numbers from original repro steps Bug 332246
        AddSalesOrderLine(SalesLine, SalesHeader, 19.625, 1192, 100, 0);
        SalesLine.Validate("Line Amount", 16559.33);
        SalesLine.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FinalInvAfterRemoteInvPosExclVAT()
    begin
        FinalInvAfterRemoteInv(false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FinalInvAfterRemoteInvNegExclVAT()
    begin
        FinalInvAfterRemoteInv(false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FinalInvAfterRemoteInvPosInclVAT()
    begin
        FinalInvAfterRemoteInv(true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FinalInvAfterRemoteInvNegInclVAT()
    begin
        FinalInvAfterRemoteInv(true, false);
    end;

    local procedure FinalInvAfterRemoteInv(PricesInclVAT: Boolean; PositiveDiff: Boolean)
    var
        SalesOrderHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Header";
        SalesOrderLine: Record "Sales Line";
    begin
        Initialize();
        SalesOrderHeader."Prices Including VAT" := PricesInclVAT;
        PrepareSalesOrderWithPostedPrepmtInv(SalesOrderHeader, SalesOrderLine, 1, PositiveDiff);

        SalesInvoiceHeader."Sell-to Customer No." := SalesOrderHeader."Sell-to Customer No.";
        CreateSalesInvoice(SalesInvoiceHeader, SalesOrderHeader."Prices Including VAT");

        LibrarySales.PostSalesDocument(SalesOrderHeader, true, false);
        GetShipmentLine(SalesInvoiceHeader, SalesOrderHeader."Last Shipping No.");

        LibrarySales.PostSalesDocument(SalesInvoiceHeader, false, true);
        VerifyZeroCustomerAccEntry();

        SalesOrderHeader.Find();
        LibrarySales.PostSalesDocument(SalesOrderHeader, true, true);
        VerifyZeroCustomerAccEntry();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipTwiceGetShptsToInvPosExclVAT()
    begin
        ShipTwiceGetShptsToInv(false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipTwiceGetShptsToInvNegExclVAT()
    begin
        ShipTwiceGetShptsToInv(false, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipTwiceGetShptsToInvPosInclVAT()
    begin
        ShipTwiceGetShptsToInv(true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShipTwiceGetShptsToInvNegInclVAT()
    begin
        ShipTwiceGetShptsToInv(true, false);
    end;

    local procedure ShipTwiceGetShptsToInv(PricesInclVAT: Boolean; PositiveDiff: Boolean)
    var
        SalesOrderHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Header";
        SalesOrderLine: Record "Sales Line";
    begin
        Initialize();
        SalesOrderHeader."Prices Including VAT" := PricesInclVAT;
        PrepareSalesOrderWithPostedPrepmtInv(SalesOrderHeader, SalesOrderLine, 1, PositiveDiff);

        SalesInvoiceHeader."Sell-to Customer No." := SalesOrderHeader."Sell-to Customer No.";
        CreateSalesInvoice(SalesInvoiceHeader, SalesOrderHeader."Prices Including VAT");

        LibrarySales.PostSalesDocument(SalesOrderHeader, true, false);
        GetShipmentLine(SalesInvoiceHeader, SalesOrderHeader."Last Shipping No.");

        UpdateQtysInLine(SalesOrderLine, GetQtyToShipTFS332246(PositiveDiff), 0);
        SalesOrderHeader.Find();
        LibrarySales.PostSalesDocument(SalesOrderHeader, true, false);
        GetShipmentLine(SalesInvoiceHeader, SalesOrderHeader."Last Shipping No.");

        LibrarySales.PostSalesDocument(SalesInvoiceHeader, false, true);
        VerifyZeroCustomerAccEntry();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartInvFinRemInvPosExclVAT()
    var
        SalesHeader: Record "Sales Header";
    begin
        PostPartInvFinRemoteInv(SalesHeader, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartInvFinRemInvNegExclVAT()
    var
        SalesHeader: Record "Sales Header";
    begin
        PostPartInvFinRemoteInv(SalesHeader, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartInvFinRemInvPosInclVAT()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader."Prices Including VAT" := true;
        PostPartInvFinRemoteInv(SalesHeader, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartInvFinRemInvNegInclVAT()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader."Prices Including VAT" := true;
        PostPartInvFinRemoteInv(SalesHeader, false);
    end;

    local procedure PostPartInvFinRemoteInv(var SalesOrderHeader: Record "Sales Header"; PositiveDiff: Boolean)
    begin
        Initialize();
        PostPartialInvoiceWithPrepmt(SalesOrderHeader, PositiveDiff);
        PostInvoiceWithShptFromOrder(SalesOrderHeader);
        VerifyZeroCustomerAccEntry();
    end;

    local procedure PostInvoiceWithShptFromOrder(SalesOrderHeader: Record "Sales Header")
    var
        SalesInvoiceHeader: Record "Sales Header";
    begin
        LibrarySales.PostSalesDocument(SalesOrderHeader, true, false);

        SalesInvoiceHeader."Sell-to Customer No." := SalesOrderHeader."Sell-to Customer No.";
        CreateSalesInvoice(SalesInvoiceHeader, SalesOrderHeader."Prices Including VAT");

        GetShipmentLine(SalesInvoiceHeader, SalesOrderHeader."Last Shipping No.");

        LibrarySales.PostSalesDocument(SalesInvoiceHeader, false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartInvLineDiscFinRemInv()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PositiveDiff: Boolean;
    begin
        Initialize();
        PositiveDiff := true;
        PrepareSOLineWithLineDisc(SalesHeader, SalesLine, PositiveDiff);
        PostSalesPrepmtInvoice(SalesHeader);

        UpdateQtysInLine(SalesLine, GetQtyToShipTFS332246(PositiveDiff), GetQtyToShipTFS332246(PositiveDiff));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        PostInvoiceWithShptFromOrder(SalesHeader);
        VerifyZeroCustomerAccEntry();
    end;

    local procedure PrepareSOLineWithLineDisc(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; PositiveDiff: Boolean)
    begin
        PrepareSalesOrder(SalesHeader);
        AddSalesOrderLine100PctPrepmt(SalesLine, SalesHeader, PositiveDiff);
        SalesLine.Validate("Line Discount %", GetSpecialLineDiscPct());
        SalesLine.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialInvoicePosExclVAT()
    var
        SalesHeader: Record "Sales Header";
    begin
        PostPartialInvoiceWithPrepmt(SalesHeader, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialInvoiceNegExclVAT()
    var
        SalesHeader: Record "Sales Header";
    begin
        PostPartialInvoiceWithPrepmt(SalesHeader, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialInvoicePosInclVAT()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader."Prices Including VAT" := true;
        PostPartialInvoiceWithPrepmt(SalesHeader, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialInvoiceNegInclVAT()
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader."Prices Including VAT" := true;
        PostPartialInvoiceWithPrepmt(SalesHeader, false);
    end;

    local procedure PostPartialInvoiceWithPrepmt(var SalesHeader: Record "Sales Header"; PositiveDiff: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        Initialize();
        PrepareSalesOrderWithPostedPrepmtInv(SalesHeader, SalesLine, 2, PositiveDiff);

        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        SalesLine.FindFirst();
        SalesLine.TestField("Quantity Invoiced", GetQtyToShipTFS332246(PositiveDiff));

        VerifyZeroCustomerAccEntry();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartInvFinalInvPosInclVAT()
    begin
        PartInvFinalInvFromOrder(true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartInvFinalInvNegInclVAT()
    begin
        PartInvFinalInvFromOrder(true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartInvFinalInvPosExclVAT()
    begin
        PartInvFinalInvFromOrder(false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartInvFinalInvNegExclVAT()
    begin
        PartInvFinalInvFromOrder(false, false);
    end;

    local procedure PartInvFinalInvFromOrder(PricesInclVAT: Boolean; PositiveDiff: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        Initialize();
        SalesHeader."Prices Including VAT" := PricesInclVAT;
        PostPartialInvoiceWithPrepmt(SalesHeader, PositiveDiff);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        VerifyZeroCustomerAccEntry();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartInvWithLineDiscExclVAT()
    begin
        PartInvWithLineDisc(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartInvWithLineDiscInclVAT()
    begin
        PartInvWithLineDisc(true);
    end;

    local procedure PartInvWithLineDisc(PricesInclVAT: Boolean)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PositiveDiff: Boolean;
    begin
        Initialize();
        PositiveDiff := true;
        SalesHeader."Prices Including VAT" := PricesInclVAT;
        PrepareSOLineWithLineDisc(SalesHeader, SalesLine, PositiveDiff);
        PostSalesPrepmtInvoice(SalesHeader);

        UpdateQtysInLine(SalesLine, GetQtyToShipTFS332246(PositiveDiff), GetQtyToShipTFS332246(PositiveDiff));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        VerifyZeroCustomerAccEntry();

        UpdateQtysInLine(SalesLine, GetQtyToShipTFS332246(PositiveDiff), GetQtyToShipTFS332246(PositiveDiff));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        VerifyZeroCustomerAccEntry();

        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        VerifyZeroCustomerAccEntry();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorDecreasingInvLineQuantityWith100PctPrepmtAfterGetShipment()
    var
        SalesOrderHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
        OldStockoutWarning: Boolean;
    begin
        // [FEATURE] [Get Shipment Lines] [UI]
        // [SCENARIO 374897] Error when User tries to decrease SalesInvoiceLine.Quantity value with 100% Prepayment after Get Shipment Lines
        Initialize();
        DisableStockoutWarning(OldStockoutWarning);

        // [GIVEN] Sales Order with 100% Prepayment, Line Discount and Line Amount = "X". Post Prepayment. Post Shipment.
        PrepareSOPostPrepmtAndShip(SalesOrderHeader);

        // [GIVEN] Create Sales Invoice. Get Shipment Lines from posted Shipment.
        CreateInvWithGetShipLines(SalesInvoiceHeader, SalesOrderHeader);

        // [WHEN] Try to decrease Sales Invoice Line Quantity value from Sales Invoice page.
        OpenSalesInvoicePage(SalesInvoice, SalesInvoiceHeader);
        asserterror SalesInvoice.SalesLines.Quantity.SetValue(SalesInvoice.SalesLines.Quantity.AsDecimal() / 2);

        // [THEN] Error occurs: "Line Amount Excl. VAT cannot be less than X"
        VerifyLineAmountExpectedError(CannotBeLessThanMsg, SalesInvoice.SalesLines."Line Amount".AsDecimal());

        // TearDown
        LibrarySales.SetStockoutWarning(OldStockoutWarning);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorDecreasingInvLineUnitPriceWith100PctPrepmtAfterGetShipment()
    var
        SalesOrderHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [Get Shipment Lines] [UI]
        // [SCENARIO 374897] Error when User tries to decrease SalesInvoiceLine."Unit Price" value with 100% Prepayment after Get Shipment Lines
        Initialize();

        // [GIVEN] Sales Order with 100% Prepayment, Line Discount and Line Amount = "X". Post Prepayment. Post Shipment.
        PrepareSOPostPrepmtAndShip(SalesOrderHeader);

        // [GIVEN] Create Sales Invoice. Get Shipment Lines from posted Shipment.
        CreateInvWithGetShipLines(SalesInvoiceHeader, SalesOrderHeader);

        // [WHEN] Try to decrease Sales Invoice Line "Unit Price" value from Sales Invoice page.
        OpenSalesInvoicePage(SalesInvoice, SalesInvoiceHeader);
        asserterror SalesInvoice.SalesLines."Unit Price".SetValue(SalesInvoice.SalesLines."Unit Price".AsDecimal() - 0.01);

        // [THEN] Error occurs: "Line Amount Excl. VAT cannot be less than X"
        VerifyLineAmountExpectedError(CannotBeLessThanMsg, SalesInvoice.SalesLines."Line Amount".AsDecimal());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorIncreasingInvLineUnitPriceWith100PctPrepmtAfterGetShipment()
    var
        SalesOrderHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [Get Shipment Lines] [UI]
        // [SCENARIO 374897] Error when User tries to increase SalesInvoiceLine."Unit Price" value with 100% Prepayment after Get Shipment Lines
        Initialize();

        // [GIVEN] Sales Order with 100% Prepayment, Line Discount and Line Amount = "X". Post Prepayment. Post Shipment.
        PrepareSOPostPrepmtAndShip(SalesOrderHeader);

        // [GIVEN] Create Sales Invoice. Get Shipment Lines from posted Shipment.
        CreateInvWithGetShipLines(SalesInvoiceHeader, SalesOrderHeader);

        // [WHEN] Try to increase Sales Invoice Line "Unit Price" value from Sales Invoice page.
        OpenSalesInvoicePage(SalesInvoice, SalesInvoiceHeader);
        asserterror SalesInvoice.SalesLines."Unit Price".SetValue(SalesInvoice.SalesLines."Unit Price".AsDecimal() + 0.01);

        // [THEN] Error occurs: "Line Amount Excl. VAT cannot be more than X"
        VerifyLineAmountExpectedError(CannotBeMoreThanMsg, SalesInvoice.SalesLines."Line Amount".AsDecimal());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorDecreasingInvLineDiscountWith100PctPrepmtAfterGetShipment()
    var
        SalesOrderHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [Get Shipment Lines] [UI]
        // [SCENARIO 374897] Error when User tries to decrease SalesInvoiceLine."Line Discount %" value with 100% Prepayment after Get Shipment Lines
        Initialize();

        // [GIVEN] Sales Order with 100% Prepayment, Line Discount and Line Amount = "X". Post Prepayment. Post Shipment.
        PrepareSOPostPrepmtAndShip(SalesOrderHeader);

        // [GIVEN] Create Sales Invoice. Get Shipment Lines from posted Shipment.
        CreateInvWithGetShipLines(SalesInvoiceHeader, SalesOrderHeader);

        // [WHEN] Try to decrease Sales Invoice Line "Line Discount %" value from Sales Invoice page.
        OpenSalesInvoicePage(SalesInvoice, SalesInvoiceHeader);
        asserterror SalesInvoice.SalesLines."Line Discount %".SetValue(SalesInvoice.SalesLines."Line Discount %".AsDecimal() - 0.01);

        // [THEN] Error occurs: "Line Amount Excl. VAT cannot be more than X"
        VerifyLineAmountExpectedError(CannotBeMoreThanMsg, SalesInvoice.SalesLines."Line Amount".AsDecimal());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorIncreasingInvLineDiscountWith100PctPrepmtAfterGetShipment()
    var
        SalesOrderHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [Get Shipment Lines] [UI]
        // [SCENARIO 374897] Error when User tries to increase SalesInvoiceLine."Line Discount %" value with 100% Prepayment after Get Shipment Lines
        Initialize();

        // [GIVEN] Sales Order with 100% Prepayment, Line Discount and Line Amount = "X". Post Prepayment. Post Shipment.
        PrepareSOPostPrepmtAndShip(SalesOrderHeader);

        // [GIVEN] Create Sales Invoice. Get Shipment Lines from posted Shipment.
        CreateInvWithGetShipLines(SalesInvoiceHeader, SalesOrderHeader);

        // [WHEN] Try to increase Sales Invoice Line "Line Discount %" value from Sales Invoice page.
        OpenSalesInvoicePage(SalesInvoice, SalesInvoiceHeader);
        asserterror SalesInvoice.SalesLines."Line Discount %".SetValue(SalesInvoice.SalesLines."Line Discount %".AsDecimal() + 0.01);

        // [THEN] Error occurs: "Line Amount Excl. VAT cannot be less than X"
        VerifyLineAmountExpectedError(CannotBeLessThanMsg, SalesInvoice.SalesLines."Line Amount".AsDecimal());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoDocLinesWithDiffVATGroupsPrepmt100PctCompressLCY()
    var
        InvoiceNo: Code[20];
    begin
        // [SCENARIO 376958] Sales Order with two custom amount lines post with Prepayment = 100%, Compress Prepayment = TRUE and different line's VAT groups

        // [GIVEN] Two VAT Posting Setup "X" and "Y" with VAT % = 21
        // [GIVEN] Sales Order with "Prepayment %" = 100, "Compress Prepayment" = TRUE and two lines:
        // [GIVEN] Line1: "Line Amount" = 0.055, VAT Posting Setup "X"
        // [GIVEN] Line2: "Line Amount" := 95.3, VAT Posting Setup "Y"
        // [GIVEN] Post Prepayment Invoice
        // [WHEN] Post Sales Order
        // [THEN] G/L Entry with "Receivables Account" has been posted with Amount = 0
        // [THEN] G/L Entries are posted with zero Amount and "VAT Amount" balance
        // [THEN] VAT Entries are posted with zero Base and Amount balance
        InvoiceNo := TwoDocLinesPrepmt100Pct_Case376958(true, true, '');
        VerifyGLEntryBalance(InvoiceNo, 0, 0);
        VerifyVATEntryBalance(InvoiceNo, 0, 0);
        VerifyZeroPostedInvoiceAmounts(InvoiceNo);
        VerifyZeroCustomerAccEntry();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoDocLinesWithSameVATGroupsPrepmt100PctCompressLCY()
    var
        InvoiceNo: Code[20];
    begin
        // [SCENARIO 376958] Sales Order with two custom amount lines post with Prepayment = 100%, Compress Prepayment = TRUE

        // [GIVEN] Sales Order with "Prepayment %" = 100, "Compress Prepayment" = TRUE and two lines:
        // [GIVEN] "Line Amount" = 0.055
        // [GIVEN] "Line Amount" := 95.3
        // [GIVEN] Post Prepayment Invoice
        // [WHEN] Post Sales Order
        // [THEN] G/L Entry with "Receivables Account" has been posted with Amount = 0
        // [THEN] G/L Entries are posted with zero Amount and "VAT Amount" balance
        // [THEN] VAT Entries are posted with zero Base and Amount balance
        InvoiceNo := TwoDocLinesPrepmt100Pct_Case376958(false, true, '');
        VerifyGLEntryBalance(InvoiceNo, 0, 0);
        VerifyVATEntryBalance(InvoiceNo, 0, 0);
        VerifyZeroPostedInvoiceAmounts(InvoiceNo);
        VerifyZeroCustomerAccEntry();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoDocLinesWithDiffVATGroupsPrepmt100PctNotCompressLCY()
    var
        InvoiceNo: Code[20];
    begin
        // [SCENARIO 376958] Sales Order with two custom amount lines post with Prepayment = 100%, Compress Prepayment = FALSE and different line's VAT groups

        // [GIVEN] Two VAT Posting Setup "X" and "Y" with VAT % = 21
        // [GIVEN] Sales Order with "Prepayment %" = 100, "Compress Prepayment" = FALSE and two lines:
        // [GIVEN] Line1: "Line Amount" = 0.055, VAT Posting Setup "X"
        // [GIVEN] Line2: "Line Amount" := 95.3, VAT Posting Setup "Y"
        // [GIVEN] Post Prepayment Invoice
        // [WHEN] Post Sales Order
        // [THEN] G/L Entry with "Receivables Account" has been posted with Amount = 0
        // [THEN] G/L Entries are posted with zero Amount and "VAT Amount" balance
        // [THEN] VAT Entries are posted with zero Base and Amount balance
        InvoiceNo := TwoDocLinesPrepmt100Pct_Case376958(true, false, '');
        VerifyGLEntryBalance(InvoiceNo, 0, 0);
        VerifyVATEntryBalance(InvoiceNo, 0, 0);
        VerifyZeroPostedInvoiceAmounts(InvoiceNo);
        VerifyZeroCustomerAccEntry();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoDocLinesWithSameVATGroupsPrepmt100PctNotCompressLCY()
    var
        InvoiceNo: Code[20];
    begin
        // [SCENARIO 376958] Sales Order with two custom amount lines post with Prepayment = 100%, Compress Prepayment = FALSE

        // [GIVEN] Sales Order with "Prepayment %" = 100, "Compress Prepayment" = FALSE and two lines:
        // [GIVEN] "Line Amount" = 0.055
        // [GIVEN] "Line Amount" := 95.3
        // [GIVEN] Post Prepayment Invoice
        // [WHEN] Post Sales Order
        // [THEN] G/L Entry with "Receivables Account" has been posted with Amount = 0
        // [THEN] G/L Entries are posted with zero Amount and "VAT Amount" balance
        // [THEN] VAT Entries are posted with zero Base and Amount balance
        InvoiceNo := TwoDocLinesPrepmt100Pct_Case376958(false, false, '');
        VerifyGLEntryBalance(InvoiceNo, 0, 0);
        VerifyVATEntryBalance(InvoiceNo, 0, 0);
        VerifyZeroPostedInvoiceAmounts(InvoiceNo);
        VerifyZeroCustomerAccEntry();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoDocLinesWithDiffVATGroupsPrepmt100PctCompressFCY()
    begin
        // [FEATURE] [FCY]
        // [SCENARIO 376958] Sales Order with two custom amount lines post with Prepayment = 100%, Compress Prepayment = TRUE, Foreign Currency and different line's VAT groups

        // [GIVEN] Two VAT Posting Setup "X" and "Y" with VAT % = 21
        // [GIVEN] Sales Order with Currency, "Prepayment %" = 100, "Compress Prepayment" = TRUE and two lines:
        // [GIVEN] Line1: "Line Amount" = 0.055, VAT Posting Setup "X"
        // [GIVEN] Line2: "Line Amount" := 95.3, VAT Posting Setup "Y"
        // [GIVEN] Post Prepayment Invoice
        // [WHEN] Post Sales Order
        // [THEN] G/L Entry with "Receivables Account" has been posted with Amount = 0
        TwoDocLinesPrepmt100Pct_Case376958(true, true, CreateCurrencyCodeWithRandomExchRate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoDocLinesWithSameVATGroupsPrepmt100PctCompressFCY()
    begin
        // [FEATURE] [FCY]
        // [SCENARIO 376958] Sales Order with two custom amount lines post with Prepayment = 100%, Compress Prepayment = TRUE, Foreign Currency

        // [GIVEN] Sales Order with Currency,  "Prepayment %" = 100, "Compress Prepayment" = TRUE and two lines:
        // [GIVEN] "Line Amount" = 0.055
        // [GIVEN] "Line Amount" := 95.3
        // [GIVEN] Post Prepayment Invoice
        // [WHEN] Post Sales Order
        // [THEN] G/L Entry with "Receivables Account" has been posted with Amount = 0
        TwoDocLinesPrepmt100Pct_Case376958(false, true, CreateCurrencyCodeWithRandomExchRate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoDocLinesWithDiffVATGroupsPrepmt100PctNotCompressFCY()
    begin
        // [FEATURE] [FCY]
        // [SCENARIO 376958] Sales Order with two custom amount lines post with Prepayment = 100%, Compress Prepayment = FALSE, Foreign Currency and different line's VAT groups

        // [GIVEN] Two VAT Posting Setup "X" and "Y" with VAT % = 21
        // [GIVEN] Sales Order with Currency,  "Prepayment %" = 100, "Compress Prepayment" = FALSE and two lines:
        // [GIVEN] Line1: "Line Amount" = 0.055, VAT Posting Setup "X"
        // [GIVEN] Line2: "Line Amount" := 95.3, VAT Posting Setup "Y"
        // [GIVEN] Post Prepayment Invoice
        // [WHEN] Post Sales Order
        // [THEN] G/L Entry with "Receivables Account" has been posted with Amount = 0
        TwoDocLinesPrepmt100Pct_Case376958(true, false, CreateCurrencyCodeWithRandomExchRate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoDocLinesWithSameVATGroupsPrepmt100PctNotCompressFCY()
    begin
        // [FEATURE] [FCY]
        // [SCENARIO 376958] Sales Order with two custom amount lines post with Prepayment = 100%, Compress Prepayment = FALSE, Foreign Currency

        // [GIVEN] Sales Order with Currency,  "Prepayment %" = 100, "Compress Prepayment" = FALSE and two lines:
        // [GIVEN] "Line Amount" = 0.055
        // [GIVEN] "Line Amount" := 95.3
        // [GIVEN] Post Prepayment Invoice
        // [WHEN] Post Sales Order
        // [THEN] G/L Entry with "Receivables Account" has been posted with Amount = 0
        TwoDocLinesPrepmt100Pct_Case376958(false, false, CreateCurrencyCodeWithRandomExchRate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtLCYRoundingCalcEqualFinalInvoiceLCYRounding()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PrepmtInvNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [FCY]
        // [SCENARIO 379324] Prepayment LCY rounding works the same way as final invoice LCY rounding in case of currency
        Initialize();

        // [GIVEN] Sales Order with 100% Prepayment, Currency (Exch. Rate = 1:1000), VAT% = 10, Line Amount Excl. VAT = 100.01, Total Amount = 110.01 (VAT Amount = 10)
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 10);
        CreateSalesDoc(
          SalesHeader, SalesHeader."Document Type"::Order, VATPostingSetup."VAT Bus. Posting Group",
          CreateCurrencyCodeWithExchRate(0.001), false, false);
        AddSalesOrderLineWithPrepmtVATProdGroup(
          SalesLine, SalesHeader, VATPostingSetup."VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group", 1, 100.01);
        // [GIVEN] Post prepayment invoice
        PostSalesPrepmtInvoice(SalesHeader);
        PrepmtInvNo := FindPrepmtInvoice(SalesHeader."Sell-to Customer No.", SalesHeader."No.");

        // [WHEN] Post final invoice
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] There are 3 Prepayment Invoice G/L Entries:
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        VerifyGLEntryCount(PrepmtInvNo, 3);
        // [THEN] G/L Account 2310 <Customer Domestic> Amount = 110010, VAT Amount = 0
        VerifyGLEntryAmount(PrepmtInvNo, GetCustomerPostingGroupRecAccNo(SalesHeader."Sell-to Customer No."), 110010, 0);
        // [THEN] G/L Account 5380 <Customer Prepayment VAT 10 %> Amount = -100010, VAT Amount = -10000
        VerifyGLEntryAmount(PrepmtInvNo, GeneralPostingSetup."Sales Prepayments Account", -100010, -10000);
        // [THEN] G/L Account 5610 <Sales VAT 10 %> Amount = -100010, VAT Amount = 0
        VerifyGLEntryAmount(PrepmtInvNo, VATPostingSetup."Sales VAT Account", -10000, 0);

        // [THEN] There are 5 Invoice G/L Entries:
        VerifyGLEntryCount(InvoiceNo, 5);
        // [THEN] G/L Account 2310 <Customer Domestic> Amount = 0, VAT Amount = 0
        VerifyGLEntryAmount(InvoiceNo, GetCustomerPostingGroupRecAccNo(SalesHeader."Sell-to Customer No."), 0, 0);
        // [THEN] G/L Account 5380 <Customer Prepayment VAT 10 %> Amount = 100010, VAT Amount = 10000
        VerifyGLEntryAmount(InvoiceNo, GeneralPostingSetup."Sales Prepayments Account", 100010, 10000);
        // [THEN] G/L Account 6120 <Sales, Retail - EU> Amount = -100010, VAT Amount = -10000
        VerifyGLEntryAmount(InvoiceNo, SalesLine."No.", -100010, -10000);
        // [THEN] G/L Account 5610 <Sales VAT 10 %> Amount = -100010, VAT Amount = 0
        // [THEN] G/L Account 5610 <Sales VAT 10 %> Amount = 100010, VAT Amount = 0
        VerifyGLEntryAccountCount(InvoiceNo, VATPostingSetup."Sales VAT Account", 2);
        VerifyGLEntryAccountBalance(InvoiceNo, VATPostingSetup."Sales VAT Account", 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteLinesFromSeparateInvoiceAfterFullPrepaymentAndShipment()
    var
        SalesHeaderOrder: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Get Shipment Lines]
        // [SCENARIO 348166] Stan can delete line from Invoice created from prepaid shipment lines.

        // [GIVEN] Sales order with 2 lines
        PrepareSalesOrder(SalesHeaderOrder);
        AddSalesOrderLine(
          SalesLine, SalesHeaderOrder, LibraryRandom.RandDecInRange(10, 100, 2), LibraryRandom.RandDecInRange(1000, 2000, 2), 100, 0);
        AddSalesOrderLine(
          SalesLine, SalesHeaderOrder, LibraryRandom.RandDecInRange(10, 100, 2), LibraryRandom.RandDecInRange(1000, 2000, 2), 100, 0);
        // [GIVEN] Posted 100% prepayment invoice
        PostSalesPrepmtInvoice(SalesHeaderOrder);
        // [GIVEN] Posted shipment
        LibrarySales.PostSalesDocument(SalesHeaderOrder, true, false);

        // [GIVEN] Sales Invoice create from shipped lines
        LibrarySales.CreateSalesHeader(
          SalesHeaderInvoice, SalesHeaderInvoice."Document Type"::Invoice, SalesHeaderOrder."Sell-to Customer No.");
        GetShipmentLine(SalesHeaderInvoice, SalesHeaderOrder."Last Shipping No.");

        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeaderInvoice);
        SalesLine.SetFilter(Quantity, '<>0');
        SalesLine.FindFirst();
        Assert.RecordCount(SalesLine, 2);

        // [WHEN] Delete line with amount from Invoice
        SalesLine.Delete(true);

        // [THEN] The single line with amount remains in invoice
        Assert.RecordCount(SalesLine, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DescriptionOfRoundingAccountInPostedPrepaymentInvoice()
    var
        SalesHeaderOrder: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FETAURE] [Invoice Rounding]
        // [SCENARIO 397118] System copies "Invoice Rounding" account's description to posted invoice line.
        Initialize();

        LibraryERM.SetInvRoundingPrecisionLCY(1);
        LibrarySales.SetInvoiceRounding(true);

        PrepareSalesOrder(SalesHeaderOrder);
        AddSalesOrderLine(SalesLine, SalesHeaderOrder, 1, 1.1, 100, 0);

        LibraryERMCountryData.UpdateVATPostingSetup();

        PostSalesPrepmtInvoice(SalesHeaderOrder);

        VerifyDescriptionOnPostedInvoiceRoundingLine(SalesHeaderOrder);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Sales Full Prepmt Rounding");

        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Sales Full Prepmt Rounding");

        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateVATPostingSetup();

        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibrarySetupStorage.SaveSalesSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Sales Full Prepmt Rounding");
    end;

    local procedure TwoDocLinesPrepmt100Pct_Case376958(UseDiffVATGroups: Boolean; CompressPrepmt: Boolean; CurrencyCode: Code[10]) InvoiceNo: Code[20]
    var
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
    begin
        Initialize();
        CreateTwoVATPostingSetups(VATPostingSetup, 21);

        CreateSalesDoc(
          SalesHeader, SalesHeader."Document Type"::Order, VATPostingSetup[1]."VAT Bus. Posting Group", CurrencyCode, false, CompressPrepmt);
        AddSalesOrderLinesCase376958(SalesHeader, VATPostingSetup, UseDiffVATGroups);

        PostSalesPrepmtInvoice(SalesHeader);
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        VerifyGLEntryAmount(InvoiceNo, GetCustomerPostingGroupRecAccNo(SalesHeader."Sell-to Customer No."), 0, 0);
        VerifyGLEntryCount(InvoiceNo, 9); // 2 (prepmt + deduct) x 2 lines x 2(amount + VAT) + zero total balance
        VerifyVATEntryCount(InvoiceNo, 4); // 2 (prepmt + deduct) x 2 lines VAT
        VerifyZeroPostedInvoiceAmounts(InvoiceNo);
        VerifyZeroCustomerAccEntry();
    end;

    local procedure DisableStockoutWarning(var OldStockoutWarning: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldStockoutWarning := SalesReceivablesSetup."Stockout Warning";
        SalesReceivablesSetup.Validate("Stockout Warning", false);
        SalesReceivablesSetup.Modify();
    end;

    local procedure PrepareSOPostPrepmtAndShip(var SalesOrderHeader: Record "Sales Header")
    var
        SalesOrderLine: Record "Sales Line";
    begin
        PrepareSalesOrder(SalesOrderHeader);
        AddSalesOrderLine(
          SalesOrderLine, SalesOrderHeader,
          LibraryRandom.RandDecInRange(10, 100, 2),
          LibraryRandom.RandDecInRange(1000, 2000, 2),
          100,
          LibraryRandom.RandDecInRange(10, 50, 2));
        PostSalesPrepmtInvoice(SalesOrderHeader);
        LibrarySales.PostSalesDocument(SalesOrderHeader, true, false);
    end;

    local procedure CreateInvWithGetShipLines(var SalesInvoiceHeader: Record "Sales Header"; SalesOrderHeader: Record "Sales Header")
    begin
        SalesInvoiceHeader."Sell-to Customer No." := SalesOrderHeader."Sell-to Customer No.";
        CreateSalesInvoice(SalesInvoiceHeader, SalesOrderHeader."Prices Including VAT");
        GetShipmentLine(SalesInvoiceHeader, SalesOrderHeader."Last Shipping No.");
    end;

    local procedure PrepareSalesOrderWithPostedPrepmtInv(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; NoOfLines: Integer; PositiveDiff: Boolean)
    var
        i: Integer;
    begin
        PrepareSalesOrder(SalesHeader);
        for i := 1 to NoOfLines do
            AddSalesOrderLine100PctPrepmt(SalesLine, SalesHeader, PositiveDiff);

        PostSalesPrepmtInvoice(SalesHeader);

        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter(Quantity, '<>%1', 0);
        if SalesLine.FindSet() then
            repeat
                UpdateQtysInLine(SalesLine, GetQtyToShipTFS332246(PositiveDiff), 0);
            until SalesLine.Next() = 0;
    end;

    local procedure PrepareSalesOrder(var SalesHeader: Record "Sales Header")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreateSalesOrder(SalesHeader, VATPostingSetup."VAT Bus. Posting Group", SalesHeader."Prices Including VAT");
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
        VATPostingSetup[2].Modify(true);

        for i := 1 to ArrayLen(VATPostingSetup) do
            UpdateVATPostingSetupAccounts(VATPostingSetup[i]);
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header"; PricesInclVAT: Boolean)
    begin
        CreateSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice, '', '', PricesInclVAT, true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; VATBusPostingGroupCode: Code[20]; PricesInclVAT: Boolean)
    begin
        CreateSalesDoc(SalesHeader, SalesHeader."Document Type"::Order, VATBusPostingGroupCode, '', PricesInclVAT, true);
    end;

    local procedure CreateSalesDoc(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; VATBusPostingGroupCode: Code[20]; CurrencyCode: Code[10]; PricesInclVAT: Boolean; CompressPrepmt: Boolean)
    var
        CustomerNo: Code[20];
    begin
        if SalesHeader."Sell-to Customer No." = '' then
            CustomerNo := CreateCustomerWithVATBusPostGr(VATBusPostingGroupCode)
        else
            CustomerNo := SalesHeader."Sell-to Customer No.";
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Validate("Prices Including VAT", PricesInclVAT);
        SalesHeader.Validate("Compress Prepayment", CompressPrepmt);
        SalesHeader.Modify();
    end;

    local procedure CreateCustomerWithVATBusPostGr(VATBusPostingGroupCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        Customer.Modify(true);
        UpdateCustomerInvoiceRoundingAccount(Customer."Customer Posting Group", Customer."VAT Bus. Posting Group");
        exit(Customer."No.");
    end;

    local procedure CreateCurrencyCodeWithRandomExchRate(): Code[10]
    begin
        exit(UpdateCurrencyInvRoundPrecision(LibraryERM.CreateCurrencyWithRandomExchRates()));
    end;

    local procedure CreateCurrencyCodeWithExchRate(ExchRate: Decimal): Code[10]
    begin
        exit(UpdateCurrencyInvRoundPrecision(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchRate, ExchRate)));
    end;

    local procedure AddSalesOrderLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Qty: Decimal; UnitPrice: Decimal; PrepmtPct: Decimal; DiscountPct: Decimal)
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), Qty);
        UpdateGenPostingSetupPrepmtAccounts(SalesLine, SalesLine."VAT Prod. Posting Group");
        UpdateSalesLine(SalesLine, UnitPrice, DiscountPct, PrepmtPct);
    end;

    local procedure AddSalesOrderLineWithPrepmtVATProdGroup(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; VATProdPostingGroupCode: Code[20]; PrepmtAccVATProdPostingGroup: Code[20]; Qty: Decimal; UnitPrice: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        VATPostingSetup.Get(SalesHeader."VAT Bus. Posting Group", VATProdPostingGroupCode);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale), Qty);
        UpdateGenPostingSetupPrepmtAccounts(SalesLine, PrepmtAccVATProdPostingGroup);
        UpdateSalesLine(SalesLine, UnitPrice, 0, 100);
    end;

    local procedure AddSalesOrderLine100PctPrepmt(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; PositiveDiff: Boolean)
    begin
        AddSalesOrderLine(SalesLine, SalesHeader, GetLineQuantityTFS332246(PositiveDiff), 3.99, 100, 0);
    end;

    local procedure AddSalesOrderLinesCase376958(SalesHeader: Record "Sales Header"; VATPostingSetup: array[2] of Record "VAT Posting Setup"; UseDiffVATGroups: Boolean)
    var
        SalesLine: Record "Sales Line";
        VATProdPostingGroupCode2: Code[20];
    begin
        if UseDiffVATGroups then
            VATProdPostingGroupCode2 := VATPostingSetup[2]."VAT Prod. Posting Group"
        else
            VATProdPostingGroupCode2 := VATPostingSetup[1]."VAT Prod. Posting Group";

        AddSalesOrderLineWithPrepmtVATProdGroup(
          SalesLine, SalesHeader, VATPostingSetup[1]."VAT Prod. Posting Group", VATPostingSetup[1]."VAT Prod. Posting Group", 1, 0.055);
        AddSalesOrderLineWithPrepmtVATProdGroup(
          SalesLine, SalesHeader, VATProdPostingGroupCode2, VATProdPostingGroupCode2, 1, 95.3);
    end;

    local procedure FindPrepmtInvoice(CustomerNo: Code[20]; OrderNo: Code[20]): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesInvoiceHeader.SetRange("Prepayment Invoice", true);
        SalesInvoiceHeader.SetRange("Prepayment Order No.", OrderNo);
        SalesInvoiceHeader.FindFirst();
        exit(SalesInvoiceHeader."No.");
    end;

    local procedure GetQtyToShipTFS332246(PositiveDiff: Boolean): Decimal
    begin
        if PositiveDiff then
            exit(2.6);
        exit(2.5);
    end;

    local procedure GetLineQuantityTFS332246(PositiveDiff: Boolean): Decimal
    begin
        if PositiveDiff then
            exit(7.5);
        exit(7.6);
    end;

    local procedure GetSpecialLineDiscPct(): Decimal
    begin
        exit(29.72);
    end;

    local procedure GetShipmentLine(SalesHeader: Record "Sales Header"; ShipmentNo: Code[20])
    var
        SalesShptLine: Record "Sales Shipment Line";
        SalesGetShpt: Codeunit "Sales-Get Shipment";
    begin
        SalesGetShpt.SetSalesHeader(SalesHeader);
        SalesShptLine.SetRange("Document No.", ShipmentNo);
        SalesGetShpt.CreateInvLines(SalesShptLine);
    end;

    local procedure GetCustomerPostingGroupRecAccNo(CustomerNo: Code[20]): Code[20]
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        Customer.Get(CustomerNo);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        exit(CustomerPostingGroup."Receivables Account");
    end;

    local procedure GetCustomerInvoiceRoundingAccount(var GLAccount: Record "G/L Account"; CustomerNo: Code[20])
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        Customer.Get(CustomerNo);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        GLAccount.Get(CustomerPostingGroup."Invoice Rounding Account");
    end;

    local procedure PostSalesPrepmtInvoice(var SalesHeader: Record "Sales Header")
    var
        SalesPostPrepayments: Codeunit "Sales-Post Prepayments";
    begin
        SalesPostPrepayments.Invoice(SalesHeader);
    end;

    local procedure UpdateQtysInLine(var SalesLine: Record "Sales Line"; QtyToShip: Decimal; QtyToInvoice: Decimal)
    begin
        SalesLine.Find();
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Validate("Qty. to Invoice", QtyToInvoice);
        SalesLine.Modify();
    end;

    local procedure UpdateSalesLine(var SalesLine: Record "Sales Line"; NewUnitPrice: Decimal; NewDiscountPct: Decimal; NewPrepmtPct: Decimal)
    begin
        SalesLine.Validate("Unit Price", NewUnitPrice);
        SalesLine.Validate("Line Discount %", NewDiscountPct);
        SalesLine.Validate("Prepayment %", NewPrepmtPct);
        SalesLine.Modify(true);
    end;

    local procedure UpdateVATPostingSetupAccounts(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.Validate("Sales VAT Account", LibraryERM.CreateGLAccountWithSalesSetup());
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountWithPurchSetup());
        VATPostingSetup.Modify(true);
    end;

    local procedure UpdateGenPostingSetupPrepmtAccounts(var SalesLine: Record "Sales Line"; PrepmtAccVATProdPostingGroup: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        GLAccount: Record "G/L Account";
    begin
        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);

        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        GeneralPostingSetup."Gen. Prod. Posting Group" := GenProductPostingGroup.Code;
        GeneralPostingSetup."Sales Prepayments Account" :=
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale);
        GeneralPostingSetup.Insert();

        SalesLine."Gen. Prod. Posting Group" := GeneralPostingSetup."Gen. Prod. Posting Group";
        SalesLine.Modify();

        GLAccount.Get(GeneralPostingSetup."Sales Prepayments Account");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", PrepmtAccVATProdPostingGroup);
        GLAccount.Modify();
    end;

    local procedure UpdateCustomerInvoiceRoundingAccount(CustomerPostingGroupCode: Code[20]; VATBusPostingGroupCode: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        CustomerPostingGroup: Record "Customer Posting Group";
        GLAccount: Record "G/L Account";
    begin
        CustomerPostingGroup.Get(CustomerPostingGroupCode);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroupCode, VATProductPostingGroup.Code);

        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale));
        GLAccount.Validate(Name, LibraryUtility.GenerateGUID());
        GLAccount.Modify(true);
        CustomerPostingGroup.Validate("Invoice Rounding Account", GLAccount."No.");
        CustomerPostingGroup.Modify(true);
    end;

    local procedure UpdateCurrencyInvRoundPrecision(CurrencyCode: Code[10]): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyCode);
        Currency.Validate("Invoice Rounding Precision", 0.01);
        Currency.Modify(true);
        exit(Currency.Code);
    end;

    local procedure OpenSalesInvoicePage(var SalesInvoice: TestPage "Sales Invoice"; SalesInvoiceHeader: Record "Sales Header")
    begin
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesInvoiceHeader);
        SalesInvoice.SalesLines.Last();
    end;

    local procedure VerifyDescriptionOnPostedInvoiceRoundingLine(SalesHeaderOrder: Record "Sales Header")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        GLAccountRounding: Record "G/L Account";
    begin
        SalesInvoiceHeader.SetRange("Prepayment Order No.", SalesHeaderOrder."No.");
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeaderOrder."Sell-to Customer No.");
        SalesInvoiceHeader.FindFirst();

        GetCustomerInvoiceRoundingAccount(GLAccountRounding, SalesHeaderOrder."Sell-to Customer No.");
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.SetRange("No.", GLAccountRounding."No.");
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField(Description, GLAccountRounding.Name);
    end;

    local procedure VerifyZeroCustomerAccEntry()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.FindLast();
        CustLedgEntry.CalcFields(Amount);
        Assert.AreEqual(0, CustLedgEntry.Amount, 'Expected zero Customer Ledger Entry due to 100% prepayment.');
    end;

    local procedure VerifyZeroPostedInvoiceAmounts(DocumentNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");
        SalesInvoiceHeader.TestField(Amount, 0);
        SalesInvoiceHeader.TestField("Amount Including VAT", 0);
    end;

    local procedure VerifyLineAmountExpectedError(ErrorTemplate: Text; ExpectedLineAmount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        Assert.ExpectedErrorCode('Validation');
        Assert.ExpectedError(SalesLine.FieldCaption("Line Amount"));
        Assert.ExpectedError(StrSubstNo(ErrorTemplate, ExpectedLineAmount));
    end;

    local procedure VerifyGLEntryAmount(DocumentNo: Code[20]; GLAccountNo: Code[20]; ExpectedAmount: Decimal; ExpectedVATAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        Assert.AreEqual(ExpectedAmount, GLEntry.Amount, GLEntry.FieldCaption(Amount));
        Assert.AreEqual(ExpectedVATAmount, GLEntry."VAT Amount", GLEntry.FieldCaption("VAT Amount"));
    end;

    local procedure VerifyGLEntryCount(DocumentNo: Code[20]; ExpectedCount: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(GLEntry, ExpectedCount);
    end;

    local procedure VerifyGLEntryAccountCount(DocumentNo: Code[20]; GLAccountNo: Code[20]; ExpectedCount: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        Assert.RecordCount(GLEntry, ExpectedCount);
    end;

    local procedure VerifyGLEntryBalance(DocumentNo: Code[20]; ExpectedAmountBalance: Decimal; ExpectedVATAmountBalance: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.CalcSums(Amount, "VAT Amount");
        Assert.AreEqual(ExpectedAmountBalance, GLEntry.Amount, GLEntry.FieldCaption(Amount));
        Assert.AreEqual(ExpectedVATAmountBalance, GLEntry."VAT Amount", GLEntry.FieldCaption("VAT Amount"));
    end;

    local procedure VerifyGLEntryAccountBalance(DocumentNo: Code[20]; GLAccountNo: Code[20]; ExpectedAmountBalance: Decimal; ExpectedVATAmountBalance: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.CalcSums(Amount, "VAT Amount");
        Assert.AreEqual(ExpectedAmountBalance, GLEntry.Amount, GLEntry.FieldCaption(Amount));
        Assert.AreEqual(ExpectedVATAmountBalance, GLEntry."VAT Amount", GLEntry.FieldCaption("VAT Amount"));
    end;

    local procedure VerifyVATEntryCount(DocumentNo: Code[20]; ExpectedCount: Integer)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(VATEntry, ExpectedCount);
    end;

    local procedure VerifyVATEntryBalance(DocumentNo: Code[20]; ExpectedBaseBalance: Decimal; ExpectedAmountBalance: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.CalcSums(Base, Amount);
        Assert.AreEqual(ExpectedBaseBalance, VATEntry.Base, VATEntry.FieldCaption(Base));
        Assert.AreEqual(ExpectedAmountBalance, VATEntry.Amount, VATEntry.FieldCaption(Amount));
    end;
}

