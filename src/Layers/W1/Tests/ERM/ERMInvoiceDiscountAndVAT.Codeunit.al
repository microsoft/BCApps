codeunit 134027 "ERM Invoice Discount And VAT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Invoice Discount]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTemplates: Codeunit "Library - Templates";
        ItemTrackingMode: Option "Assign Lot No.","Select Entries";
        IsInitialized: Boolean;
        AmtMustBeErr: Label 'The %1 must be %2 in %3.', Comment = '%1 = Field Caption. %2 = Amount, %3 = Table Caption';
        InvDiscCodeErr: Label '%1 must be filled in. Enter a value. (Select Refresh to discard errors)', Comment = '%1 = Invoice Discount Code';
        UnexpectedErr: Label 'Error Message must be same';
        WrongLineAmountErr: Label '%1 has wrong amount', Comment = '%1 = Table Caption';
        TotalInvDiscountAmountErr: Label 'The sum of Inv Discount Amount in %1 must be equal to %2', Comment = '%1 = Table Caption, %2 = Amount';
        NegativeInvDiscountErr: Label '%1 must not have negative Invoice Discount Amount while line amount is positive or zero', Comment = '%1 = Table Caption';
        InvoiceDiscountAmountErr: Label 'Invoice Discount Amount must be greater than 0';
        LineDiscountAmountErr: Label 'Line Discount Amount must not be changed after validation.';
        AmtInclVATErr: Label 'Amount Including VAT is incorrect';
        IncorrectAmtErr: Label 'Amount is incorrect';
        PriceIncludingVATChangeMsg: Label 'You have modified the Prices Including VAT field.';
        UpdInvDiscQst: Label 'One or more lines have been invoiced. The discount distributed to invoiced lines will not be taken into account.\\Do you want to update the invoice discount?';
        WrongFieldValueErr: Label 'Wrong value of field %1.', Comment = '%1 = Field Caption';
        ChangedInvDiscountAmountErr: Label 'Invoice Discount Amount must not be changed';
        CalcTotalPurchAmountOnlyDiscountAllowedErr: Label 'Total Amount of Purchase lines with allowed discount is incorrect.';
        CalcTotalSalesAmountOnlyDiscountAllowedErr: Label 'Total Amount of Sales lines with allowed discount is incorrect.';
        GetInvoiceDiscountPctErr: Label 'Discount % is incorrect';
        MissingDiscountAccountMsg: Label 'G/L accounts for discounts are missing on one or more lines on the General Posting Setup page.';
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Table Caption';

    [Test]
    [Scope('OnPrem')]
    procedure TestInvDiscWithInvDiscOnItm()
    begin
        // Covers documents TFS_TC_ID=11233, TFS_TC_ID=11234 and TFS_TC_ID=11240.
        Initialize();
        InvDiscAndVATOnPurchInvoice(true, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvDiscWithoutInvDiscOnItm()
    begin
        // Covers documents TFS_TC_ID=11234, TFS_TC_ID=11236.
        Initialize();
        InvDiscAndVATOnPurchInvoice(false, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvDiscWithPurchInvStsOpen()
    begin
        // Covers documents TFS_TC_ID=11233, TFS_TC_ID=11237.
        Initialize();
        InvDiscAndVATOnPurchInvoice(true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvDiscEnterDiscAmtManualy()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
        NewInvDiscAmt: Decimal;
    begin
        // Covers documents TFS_TC_ID= 11233, TFS_TC_ID=11235.
        // 1. Find VAT Posting Setup.
        // 2. Create a new Item with Allow Invoice Discount TRUE.
        // 3. Create a new Vendor and update Invoice Discount Code On Vendor.
        // 4. Create a Purchase Invoice With the newly created Item and Random Quantity.
        // 5. Calculate Invoice Discount on Purchase Invoice. Enter a new Invoice Discount Amount on Purchase Invoice Line
        // 6. Release the Purchase Invoice.
        // 8. Verify the Amount Excluding VAT after updating Invoice Discount Amount in Purchase Invoice Line.

        // Setup: Create Purchase Invoice with newly created Item and Vendor, Calculate Purchase Invoice Discount,
        // Update Purchase Line with a Random Invoice Discount Amount.
        Initialize();
        LibraryPurchase.SetCalcInvDiscount(false);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        CreatePurchaseInvoiceHeader(PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(true, VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandInt(10));

        PurchCalcDiscount.CalculateInvoiceDiscount(PurchaseHeader, PurchaseLine);

        NewInvDiscAmt := LibraryRandom.RandInt(10);
        UpdateInvDiscAmtOnPurchaseLine(PurchaseLine, NewInvDiscAmt);

        // Exercise: Release Purchase Invoice.
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // Verify: Verify the Amount Excluding VAT after updating Invoice Discount Amount in Purchase Invoice Line.
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        Assert.AreEqual(
          PurchaseLine.Amount, PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost" - NewInvDiscAmt,
          StrSubstNo(AmtMustBeErr, PurchaseLine.FieldCaption("Outstanding Amount"), PurchaseLine."Line Amount" - NewInvDiscAmt,
            PurchaseLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvDiscWithMultiVATItems()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
        ItemNo: Code[20];
        ItemNo2: Code[20];
        VATPercent: Decimal;
    begin
        // Covers documents TFS_TC_ID=11236, TFS_TC_ID=11240.
        // 1. Find VAT Posting Setup.
        // 2. Create two new Items with Allow Invoice Discount TRUE and with Different VAT Business Posting Groups.
        // 3. Create a new Vendor and update Invoice Discount Code On Vendor.
        // 4. Create a Purchase Invoice With the newly created Items and Random Quantity.
        // 5. Calculate Invoice Discount on Purchase Invoice and Release Purchase Invoice.
        // 6. Verify Invoice Discount Amount and Amount Including VAT on Purchase Invoice Lines.

        // Setup: Create Purchase Invoice with newly created Items and Vendor.
        Initialize();
        FindMultiVATPostingSetup(VATPostingSetup);
        CreatePurchaseInvoiceHeader(PurchaseHeader);
        VATPostingSetup.SetRange("VAT Bus. Posting Group", PurchaseHeader."VAT Bus. Posting Group");

        ItemNo := CreateItem(true, VATPostingSetup."VAT Prod. Posting Group");
        VATPercent := VATPostingSetup."VAT %";
        VATPostingSetup.Next();

        ItemNo2 := CreateItem(true, VATPostingSetup."VAT Prod. Posting Group");

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo2, LibraryRandom.RandInt(10));

        // Exercise: Calculate Invoice Discount on Purchase Invoice, Release the Purchase Invoice.
        PurchCalcDiscount.CalculateInvoiceDiscount(PurchaseHeader, PurchaseLine);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        // Verify: Verify the Invoice Discount Amount and Amount Including VAT on Purchase Line.
        VerifyInvDiscAmtAndVATAmt(PurchaseLine, ItemNo, VATPercent, true);
        VerifyInvDiscAmtAndVATAmt(PurchaseLine, ItemNo2, VATPostingSetup."VAT %", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvDiscForPostedPurchInv()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
        PstdInvoiceNo: Code[20];
    begin
        // Covers documents TFS_TC_ID=11239, TFS_TC_ID=11240.
        // 1. Find VAT Posting Setup.
        // 2. Create a new Item with Allow Invoice Discount TRUE.
        // 3. Create a new Vendor and update Invoice Discount Code On Vendor.
        // 4. Create a Purchase Invoice With the newly created Items and Random Quantity.
        // 5. Calculate Invoice Discount on Purchase Invoice and Release Purchase Invoice.
        // 6. Post the Purchase Invoice.
        // 8. Verify Invoice Discount Amount and VAT Amount and Total Amount in GL Entry for Posted Purchase Invoice.

        // Setup: Create Purchase Invoice with newly created Items and Vendor. Calculate Invoice Discount on Purchase Invoice,
        // Release the Purchase Invoice.
        Initialize();
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        CreatePurchaseInvoiceHeader(PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(true, VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandInt(10));
        PurchCalcDiscount.CalculateInvoiceDiscount(PurchaseHeader, PurchaseLine);

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        UpdateGeneralPostingSetup(GeneralPostingSetup, PurchaseLine);

        // Exercise: Post the Purchase Invoice.
        PstdInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Verify Invoice Discount and VAT Amount in GL Entry for Posted Purchase Invoice.
        VerifyGLEntryForPostedPurchInv(
          -PurchaseLine."Inv. Discount Amount", -PurchaseLine."Inv. Discount Amount" * PurchaseLine."VAT %" / 100, PstdInvoiceNo,
          GeneralPostingSetup."Purch. Inv. Disc. Account");

        VerifyGLEntryForPostedPurchInv(
          PurchaseLine."Line Amount", PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100, PstdInvoiceNo,
          GeneralPostingSetup."Purch. Account");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExpectedAndActualCostOnReceive()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // Verify Values on Value Entry after posting Purchase Order as Receive.

        // Setup: Set Initial Setup and create Purchase Order.
        Initialize();
        LibraryInventory.SetAutomaticCostPosting(true);
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);

        // Exercise: Post Purchase Order as Receive.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Verify: Verify Cost Amount Expected and Cost Amount Actual on Value Entry.
        VerifyValuesOnValueEntry(DocumentNo, PurchaseLine."Line Amount", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExpectedAndActualCostOnInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        LineAmount: Decimal;
    begin
        // Verify Values on Value Entry after posting Purchase Order as Invoice.

        // Setup: Set Initial Setup and create Purchase Order.
        Initialize();
        LibraryInventory.SetAutomaticCostPosting(true);
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // Exercise: Reopen Purchase Order and Update Direct Unit Cost on Purchase Line. Post Purchase Order as Invoice.
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        LineAmount := UpdateDirectUnitCostOnPurchase(PurchaseLine);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // Verify: Verify Cost Amount Expected and Cost Amount Actual on Value Entry.
        VerifyValuesOnValueEntry(DocumentNo, -PurchaseLine."Line Amount", LineAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineDiscountOnSalesCreditMemoWithCopyDocument()
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        PostedDocumentNo: Code[20];
    begin
        // Verify Line Discount on Sales Credit Memo Using Copy Document after Posting Sales Invoice.

        // Setup: Create Sales Invoice and Update Sales & Receivable Setup for Exact Cost Reversing Mandatory.
        Initialize();
        PostedDocumentNo := CreateAndPostSalesInvoice(SalesLine);
        LibrarySales.SetExactCostReversingMandatory(true);

        // Exercise: Create Sales Credit Memo with Copy Document.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", SalesLine."Sell-to Customer No.");
        SalesCopyDocument(SalesHeader, PostedDocumentNo, "Sales Document Type From"::"Posted Invoice");

        // Verify: Verify Data in Sales Line.
        VerifySalesCreditMemo(SalesHeader."No.", SalesLine."No.", SalesLine."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDiscountedAmountAfterPostingFASalesOrderWithLineDiscount()
    var
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        SalesInvoiceNo: Code[20];
        PostingDate: Date;
    begin
        // Create Sales Invoice with Fixed Asset with discount and post it.
        Initialize();
        LibrarySales.CreateCustomer(Customer);

        SalesInvoiceNo := CreateAndPostSalesInvoiceWithFADiscount(SalesLine, PostingDate, Customer."No.");

        VerifyAmountOnSalesInvoiceAndGLAccount(SalesInvoiceNo, GetReceivablesAccount(Customer."Customer Posting Group"),
          PostingDate, SalesLine."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvDiscCodeCanNotBeBlankForCustomer()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
        ExpectedErr: Text[1024];
    begin
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CustomerCard.OpenEdit();
        CustomerCard.FILTER.SetFilter("No.", Customer."No.");
        CustomerCard.First();
        asserterror CustomerCard."Invoice Disc. Code".SetValue('');
        ExpectedErr := StrSubstNo(InvDiscCodeErr, Customer.FieldCaption("Invoice Disc. Code"));
        Assert.AreEqual(ExpectedErr, CustomerCard.GetValidationError(1), UnexpectedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInvDiscCodeCanNotBeBlankForVendor()
    var
        Vendor: Record Vendor;
        VendorCard: TestPage "Vendor Card";
        ExpectedErr: Text[1024];
    begin
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        VendorCard.OpenEdit();
        VendorCard.FILTER.SetFilter("No.", Vendor."No.");
        VendorCard.First();
        asserterror VendorCard."Invoice Disc. Code".SetValue('');
        ExpectedErr := StrSubstNo(InvDiscCodeErr, Vendor.FieldCaption("Invoice Disc. Code"));
        Assert.AreEqual(ExpectedErr, VendorCard.GetValidationError(1), UnexpectedErr);
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithMultilinesInvoiceDiscount()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        InvDiscountAmount: Decimal;
    begin
        // Test for bug: 346185
        // Add 3 sales lines, middle line amount should be 0. Direct price is set to rounding precision and Line Discount % = 100
        // Before fix this line after setting a certain value to Invoice Discount Amount
        // in statistics page has negative value in Invoice Discount Amount column

        // Setup: Create Purchase Invoice with newly created Item and Vendor.
        Initialize();
        LibraryPurchase.SetCalcInvDiscount(false);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreatePurchaseInvoiceHeader(PurchaseHeader);
        InvDiscountAmount := 100;

        // Init lines
        CreateMultiplePurchaseLines(VATPostingSetup, PurchaseHeader, InvDiscountAmount);
        LibraryVariableStorage.Enqueue(InvDiscountAmount);

        // Exercise: Calculate Invoice Discount on Purchase Invoice, Release the Purchase Invoice.
        CalculateInvoiceDiscountOnPurchaseInvoice(PurchaseHeader);

        // Verify lines' amounts and total amount against Invoice Discount Amount
        VerifyPurchaseLineAmounts(PurchaseHeader, InvDiscountAmount);
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithMultilinesInvoiceDiscount()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        InvDiscountAmount: Decimal;
    begin
        // Test for bug: 346185
        // Add 3 sales lines, middle line amount should be 0. Direct price is set to rounding precision and Line Discount % = 100
        // Before fix this line after setting a certain value to Invoice Discount Amount
        // in statistics page has negative value in Invoice Discount Amount column

        // Setup:
        Initialize();
        LibrarySales.SetCalcInvDiscount(false);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        InvDiscountAmount := 100;

        // Init lines
        CreateMultipleSalesLines(VATPostingSetup, SalesHeader, InvDiscountAmount);
        LibraryVariableStorage.Enqueue(InvDiscountAmount);

        // Exercise: Calculate Invoice Discount on Sales Invoice, Release the Sales Invoice.
        CalculateInvoiceDiscountOnSalesInvoice(SalesHeader);

        // Verify lines' amounts and total amount against Invoice Discount Amount
        VerifySalesLineAmounts(SalesHeader, InvDiscountAmount);
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderWithVendorDiscountStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithInvoiceDiscountAndZeroTotalAmount()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
    begin
        // Balanced lines have incorrect Invoice Discount Amount due to fix 346152

        // Setup: Create Purchase Invoice with newly created Item and Vendor.
        Initialize();
        LibraryPurchase.SetCalcInvDiscount(true);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreatePurchaseInvoiceHeader(PurchaseHeader);

        // Init lines
        CreateTwoPurchLinesWithZeroTotalAmount(VATPostingSetup, PurchaseHeader);

        // Exercise: Calculate Invoice Discount on Purchase Invoice, Release the Purchase Invoice.
        CalculateInvoiceDiscountOnPurchaseInvoice(PurchaseHeader);

        // Verify lines' amounts and total amount against Invoice Discount Amount
        VerifyPurchaseLineAmounts(PurchaseHeader, 0);
    end;

    [Test]
    [HandlerFunctions('SalesOrderWithCustomerDiscountStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithInvoiceDiscountAndZeroTotalAmount()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
    begin
        // Balanced lines have incorrect Invoice Discount Amount due to fix 346152

        // Setup:
        Initialize();
        LibrarySales.SetCalcInvDiscount(true);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomerWithDiscount(VATPostingSetup));

        // Init lines
        CreateTwoSalesLinesWithZeroTotalAmount(VATPostingSetup, SalesHeader);

        // Exercise: Calculate Invoice Discount on Sales Invoice, Release the Sales Invoice.
        CalculateInvoiceDiscountOnSalesInvoice(SalesHeader);

        // Verify lines' amounts and total amount against Invoice Discount Amount
        VerifySalesLineAmounts(SalesHeader, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderWithModifiedLineDiscountAmount()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LineDiscountAmount: Decimal;
    begin
        // Setup.
        Initialize();
        LibrarySales.SetCalcInvDiscount(true);

        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomerWithDiscount(VATPostingSetup));
        UpdateCurrencyRoundingPrecision(SalesHeader."Currency Code");

        // Create Sales line and modify Line Discount Amount.
        CreateSalesLine(
          SalesHeader, SalesLine, CreateItem(true, VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(1000), 1);
        SalesLine.Validate("Line Discount Amount", LibraryRandom.RandInt(400));
        LineDiscountAmount := SalesLine."Line Discount Amount";

        SalesLine.Validate("Line Discount Amount", SalesLine."Line Discount Amount" + 0.01 * LibraryRandom.RandInt(4));

        // Verify Line Discount Amount after validation.
        Assert.AreEqual(
          LineDiscountAmount, SalesLine."Line Discount Amount", LineDiscountAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithModifiedLineDiscountAmount()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        LineDiscountAmount: Decimal;
    begin
        // Setup.
        Initialize();
        LibrarySales.SetCalcInvDiscount(true);

        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Invoice, CreateVendorWithDiscount());
        UpdateCurrencyRoundingPrecision(PurchHeader."Currency Code");

        // Create Sales line and modify Line Discount Amount.
        CreatePurchaseLine(
          PurchHeader, PurchLine, CreateItem(true, VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandInt(1000), 1);
        PurchLine.Validate("Line Discount Amount", LibraryRandom.RandInt(400));
        LineDiscountAmount := PurchLine."Line Discount Amount";

        PurchLine.Validate("Line Discount Amount", PurchLine."Line Discount Amount" + 0.01 * LibraryRandom.RandInt(4));

        // Verify Line Discount Amount after validation.
        Assert.AreEqual(
          LineDiscountAmount, PurchLine."Line Discount Amount", LineDiscountAmountErr);
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceCopySalesInvoiceWithInvoiceDiscountAmount()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Test Invoice Discount Amount should be copied when using Copy Document function in Sales Invoice
        Initialize();
        CopyPostedSalesInvoiceWithInvoiceDiscountAmount(SalesHeader."Document Type"::Invoice, false);
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoCopyPostedSalesInvoiceWithInvoiceDiscountAmount()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Test Invoice Discount Amount should be copied when using Copy Document function in Sales Credit Memo
        Initialize();
        CopyPostedSalesInvoiceWithInvoiceDiscountAmount(SalesHeader."Document Type"::"Credit Memo", true);
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseOrderCopyPurchaseInvoiceWithInvoiceDiscountAmount()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Test Invoice Discount Amount should be copied when using Copy Document function in Purchase Order
        Initialize();
        CopyPostedPurchaseInvoiceWithInvoiceDiscountAmount(PurchaseHeader."Document Type"::Order, false);
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderCopyPostedPurchaseInvoiceWithInvoiceDiscountAmount()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Test Invoice Discount Amount should be copied when using Copy Document function in Purchase Return Order
        Initialize();
        CopyPostedPurchaseInvoiceWithInvoiceDiscountAmount(PurchaseHeader."Document Type"::"Return Order", true);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure AmountIncludingVATOnSalesLineWithEnablePricesIncludingVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
    begin
        // Verify Amount Including VAT on Sales Order After Enable Prices Including VAT.
        Initialize();

        // Setup: Create Sales Order and Calculate Invoice Discount.
        CreateSalesOrderWithCalculateInvoiceDiscount(SalesHeader, SalesLine);

        // Exercise: Enable Prices Including VAT on Sales Header.
        UpdatePricesIncludingVATOnsalesHeader(SalesHeader, true);

        // Verify: Verify Amount and Amount Including VAT on Sales Line.
        VerifyAmountAndAmountIncludingVATOnSalesLine(SalesLine[1]);
        VerifyAmountAndAmountIncludingVATOnSalesLine(SalesLine[2]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure AmountIncludingVATOnPurchaseLineWithEnablePricesIncludingVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[2] of Record "Purchase Line";
    begin
        // Verify Amount Including VAT on Purchase Order After Enable Prices Including VAT.
        Initialize();

        // Setup: Create Purchase Order and Calculate Invoice Discount.
        CreatePurchaseOrderWithCalculateInvoiceDiscount(PurchaseHeader, PurchaseLine);

        // Exercise: Enable Prices Including VAT on Purchase Header.
        UpdatePricesIncludingVATOnPurchaseHeader(PurchaseHeader, true);

        // Verify: Verify Amount and Amount Including VAT on Purchase Line.
        VerifyAmountAndAmountIncludingVATOnPurchaseLine(PurchaseLine[1]);
        VerifyAmountAndAmountIncludingVATOnPurchaseLine(PurchaseLine[2]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure AmountIncludingVATOnSalesLineWithVATBaseDiscountWithEnablePricesIncludingVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verify Amount Including VAT on Sales Order After Enable Prices Including VAT with Payment Discount Excluding VAT.

        // Setup: Update Pmt. Disc. Excl. VAT with VAT Tolerance and Create Sales Order and Calculate Invoice Discount.
        Initialize();
        LibraryPmtDiscSetup.SetPmtDiscExclVAT(true);
        CreateSalesOrderWithPmtDiscExclVATAndCalculateInvoiceDiscount(SalesHeader, SalesLine);

        // Exercise: Enable Prices Including VAT on Sales Header.
        UpdatePricesIncludingVATOnsalesHeader(SalesHeader, true);

        // Verify: Verify Amount Including VAT on Sales Line.
        SalesLine.Find(); // Update Prices Including VAT has changed amount on Sales Line.
        Assert.AreNearlyEqual(
          SalesLine.Amount * ((1 - SalesHeader."VAT Base Discount %" / 100) * SalesLine."VAT %" / 100 + 1),
          SalesLine."Amount Including VAT", LibraryERM.GetAmountRoundingPrecision(), AmtInclVATErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure AmountIncludingVATOnPurchaseLineWithVATBaseDiscountWithEnablePricesIncludingVAT()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Amount Including VAT on Purchase Order After Enable Prices Including VAT with Payment Discount Excluding VAT.

        // Setup: Update Pmt. Disc. Excl. VAT with VAT Tolerance and Create Purchase Order and Calculate Invoice Discount.
        Initialize();
        LibraryPmtDiscSetup.SetPmtDiscExclVAT(true);
        CreatePurchaseOrderWithPmtDiscExclVATAndCalculateInvoiceDiscount(PurchaseHeader, PurchaseLine);

        // Exercise: Enable Prices Including VAT on Purchase Header.
        UpdatePricesIncludingVATOnPurchaseHeader(PurchaseHeader, true);

        // Verify: Verify Amount Including VAT on Purchase Line.
        PurchaseLine.Find(); // Update Prices Including VAT has changed amount on Purchase Line.
        Assert.AreNearlyEqual(
          PurchaseLine.Amount * ((1 - PurchaseHeader."VAT Base Discount %" / 100) * PurchaseLine."VAT %" / 100 + 1),
          PurchaseLine."Amount Including VAT", LibraryERM.GetAmountRoundingPrecision(), AmtInclVATErr);
    end;

    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandler,UpdateInvDiscConfirmHandler')]
    [Scope('OnPrem')]
    procedure ConfirmationOnInvDiscUpdateInSalesOrderWithInvoicedLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLineInvoiced: Record "Sales Line";
        InvDiscountAmount: Decimal;
    begin
        // Verify that confirmation windows shows when user tries to update Invoice Discount in Order with at least one fully invoiced line.

        // [GIVEN] Create order with multiple lines
        // [GIVEN] Get random invoice discount amount
        // [GIVEN] Assign invoice discount amount through SalesOrderStatisticsPageHandler
        // [GIVEN] Post order partially
        // [GIVEN] Get line invoiced and save invoice discount before inv. discount update
        Initialize();
        CreateSalesOrderWithMultipleLines(SalesHeader);
        InvDiscountAmount := LibraryRandom.RandDec(100, 2);
        OpenSalesOrderStatistics(SalesHeader, InvDiscountAmount);
        PostSalesOrderPartially(SalesHeader);
        GetSalesLineInvoiced(SalesLineInvoiced, SalesHeader);
        InvDiscountAmount := SalesLineInvoiced."Inv. Discount Amount";

        // [WHEN] Assign invoice discount amount through SalesOrderStatisticsPageHandler and UpdateInvDiscConfirmHandler
        OpenSalesOrderStatistics(SalesHeader, InvDiscountAmount);

        // [THEN]: Get line invoiced and check that inv. discount amount was not changed
        SalesLineInvoiced.Find();
        Assert.AreEqual(
          InvDiscountAmount, SalesLineInvoiced."Inv. Discount Amount",
          StrSubstNo(WrongFieldValueErr, SalesLineInvoiced.FieldCaption("Inv. Discount Amount")));
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler,UpdateInvDiscConfirmHandler')]
    [Scope('OnPrem')]
    procedure ConfirmationOnInvDiscUpdateInPurchOrderWithInvoicedLine()
    var
        PurchHeader: Record "Purchase Header";
        PurchLineInvoiced: Record "Purchase Line";
        InvDiscountAmount: Decimal;
    begin
        // Verify that confirmation windows shows when user tries to update Invoice Discount in Order with at least one fully invoiced line.

        // [GIVEN] Create order with multiple lines
        // [GIVEN] Get random invoice discount amount
        // [GIVEN] Assign invoice discount amount through SalesOrderStatisticsPageHandler
        // [GIVEN] Post order partially
        // [GIVEN] Get line invoiced and save invoice discount before inv. discount update
        Initialize();
        CreatePurchOrderWithMultipleLines(PurchHeader);
        InvDiscountAmount := LibraryRandom.RandDec(100, 2);
        OpenPurchOrderStatistics(PurchHeader, InvDiscountAmount);
        PostPurchOrderPartially(PurchHeader);
        GetPurchLineInvoiced(PurchLineInvoiced, PurchHeader);
        InvDiscountAmount := PurchLineInvoiced."Inv. Discount Amount";

        // [WHEN] Assign invoice discount amount through SalesOrderStatisticsPageHandler and UpdateInvDiscConfirmHandler
        OpenPurchOrderStatistics(PurchHeader, InvDiscountAmount);

        // [THEN]: Get line invoiced and check that inv. discount amount was not changed
        PurchLineInvoiced.Find();
        Assert.AreEqual(
          InvDiscountAmount, PurchLineInvoiced."Inv. Discount Amount",
          StrSubstNo(WrongFieldValueErr, PurchLineInvoiced.FieldCaption("Inv. Discount Amount")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderTinyInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
        InvoiceDiscountAmount: Decimal;
    begin
        // [SCENARIO] Set -GLSetup."Amount Rounding Precision" to Invoice Discount Amount for SO with 3+ lines having same amounts

        // [GIVEN] LCY Sales Order with 3+ lines with equal amount each and some Amount Rounding Precision for currency
        Initialize();
        InitializeSalesMultipleLinesEqualAmountsScenario(SalesHeader, InvoiceDiscountAmount, '');
        // [WHEN] We set -GLSetup."Amount Rounding Precision" to Invoice Discount Amount
        UpdateInvDiscAmtOnSalesOrder(SalesHeader, InvoiceDiscountAmount);
        // [THEN] Then it must not be changed and/or dropped to 0
        VerifySalesOrderInvoiceDiscountAmount(SalesHeader, InvoiceDiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderTinyInvoiceDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        InvoiceDiscountAmount: Decimal;
    begin
        // [SCENARIO] Set -GLSetup."Amount Rounding Precision" to Invoice Discount Amount for PO with 3+ lines having same amounts

        // [GIVEN] FCY Purchase Order with 3+ lines with equal amount each and some Amount Rounding Precision for currency
        Initialize();
        InitializePurchaseMultipleLinesEqualAmountsScenario(PurchaseHeader, InvoiceDiscountAmount, '');
        // [WHEN] We set -GLSetup."Amount Rounding Precision" to Invoice Discount Amount
        UpdateInvDiscAmtOnPurchaseOrder(PurchaseHeader, InvoiceDiscountAmount);
        // [THEN] Then it must not be changed and/or dropped to 0
        VerifyPurchaseOrderInvoiceDiscountAmount(PurchaseHeader, InvoiceDiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderTinyInvoiceDiscountFCY()
    var
        SalesHeader: Record "Sales Header";
        InvoiceDiscountAmount: Decimal;
    begin
        // [SCENARIO] Set -Currency."Amount Rounding Precision" to Invoice Discount Amount for FCY SO with 3+ lines having same amounts

        // [GIVEN] FCY Sales Order with 3+ lines with equal amount each and some Amount Rounding Precision for currency
        Initialize();
        InitializeSalesMultipleLinesEqualAmountsScenario(
          SalesHeader, InvoiceDiscountAmount, LibraryERM.CreateCurrencyWithRounding());
        // [WHEN] We set -Currency."Amount Rounding Precision" to Invoice Discount Amount
        UpdateInvDiscAmtOnSalesOrder(SalesHeader, InvoiceDiscountAmount);
        // [THEN] Then it must not be changed and/or dropped to 0
        VerifySalesOrderInvoiceDiscountAmount(SalesHeader, InvoiceDiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderTinyInvoiceDiscountFCY()
    var
        PurchaseHeader: Record "Purchase Header";
        InvoiceDiscountAmount: Decimal;
    begin
        // [SCENARIO] Set -Currency."Amount Rounding Precision" to Invoice Discount Amount for FCY PO with 3+ lines having same amounts

        // [GIVEN] FCY Purchase Order with 3+ lines with equal amount each and some Amount Rounding Precision for currency
        Initialize();
        InitializePurchaseMultipleLinesEqualAmountsScenario(
          PurchaseHeader, InvoiceDiscountAmount, LibraryERM.CreateCurrencyWithRounding());
        // [WHEN] We set -Currency."Amount Rounding Precision" to Invoice Discount Amount
        UpdateInvDiscAmtOnPurchaseOrder(PurchaseHeader, InvoiceDiscountAmount);
        // [THEN] Then it must not be changed and/or dropped to 0
        VerifyPurchaseOrderInvoiceDiscountAmount(PurchaseHeader, InvoiceDiscountAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderPartialPostingWithCustomAmountAndHundredPctLineDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ExpectedLineDiscAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Line Discount] [Partial Posting]
        // [SCENARIO 374880] Total amount of G/L Account in Sales Order with "Line Discount %" = 100 and posted partially should be equal "Line Discount Amount"

        Initialize();
        // [GIVEN] Partially posted Order with "G/L Account" = "X" VAT % = 10, Quantity = 15, "Unit Price" = 9.0909, "Line Discount" = 100%, "Qty. Invoiced" = 9, "Line Disc. Amount" = 136.36
        CreateSalesOrderWithCustomVATAndLineDiscount(SalesHeader, SalesLine, 15, 9.0909, 100);
        ExpectedLineDiscAmount := SalesLine."Line Discount Amount";
        SalesLine.Validate("Qty. to Invoice", 9);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Post second part of Sales Order with "Qty. to Invoice" = 6
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Total Amount on "G/L Account No." = "X" in G/L Entry = -136.36
        VerifyTotalAmountInGLEntry(SalesLine."No.", -ExpectedLineDiscAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderPartialPostingWithCustomAmountAndHundredPctLineDiscount()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        ExpectedLineDiscAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Line Discount] [Partial Posting]
        // [SCENARIO 374880] Total amount of G/L Account in Purchase Order with "Line Discount %" = 100 and posted partially should be equal "Line Discount Amount"

        Initialize();
        // [GIVEN] Partially posted Order with "G/L Account" = "X" VAT % = 10, Quantity = 15, "Unit Cost" = 9.0909, "Line Discount" = 100%, "Qty. Invoiced" = 9, "Line Disc. Amount" = 136.36
        CreatePurchOrderWithCustomVATAndLineDiscount(PurchHeader, PurchLine, 15, 9.0909, 100);
        ExpectedLineDiscAmount := PurchLine."Line Discount Amount";
        PurchLine.Validate("Qty. to Invoice", 9);
        PurchLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
        PurchHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchHeader.Modify(true);

        // [WHEN] Post second part of Purchase Order with "Qty. to Invoice" = 6
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [THEN] Total Amount on "G/L Account No." = "X" in G/L Entry = 136.36
        VerifyTotalAmountInGLEntry(PurchLine."No.", ExpectedLineDiscAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmtOnSalesOrderWithMultiplesLinesWhenOneWithHundredLineDisc()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATDiscAmount: array[3] of Decimal;
        DocNo: Code[20];
    begin
        // [FEATURE] [Sales] [Line Discount]
        // [SCENARIO 378349] G/L Entry with VAT is posted for multiple lines order when one of the lines has "Line Discount %" = 100

        Initialize();
        // [GIVEN] Sales Order with sales lines:
        // [GIVEN] Line "1": Line Amount = 2000, "Line Discount %" = 40, "Line Discount Amonut" = 800, "Line Discount VAT Amount" = 80
        // [GIVEN] Line "2": Line Amount = 1000, "Line Discount %" = 100, "Line Discount Amonut" = 1000, "Line Discount VAT Amount" = 100
        CreateSalesOrderWithLineDiscount(SalesHeader, SalesLine, LibraryRandom.RandInt(50));
        VATDiscAmount[1] := Round(SalesLine."Line Discount Amount" * SalesLine."VAT %" / 100);
        VATDiscAmount[2] := SalesLine."Amount Including VAT" - SalesLine.Amount;
        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        AddSalesLineWithHundredLineDisc(SalesLine, SalesHeader, VATPostingSetup);
        VATDiscAmount[3] := Round(SalesLine."Line Discount Amount" * SalesLine."VAT %" / 100);
        UpdateAccInGenPostingSetup(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");

        // [WHEN] Post Sales Order
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] G/L Entry is posted with "Sales VAT Account" and "Amount" = 180 for both lines (VAT for Discount)
        VerifyAmountOfPairedGLEntries(
          DocNo, VATPostingSetup."Sales VAT Account", VATDiscAmount[1] + VATDiscAmount[3],
          -VATDiscAmount[1] - VATDiscAmount[2] - VATDiscAmount[3]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmtOnPurchOrderWithMultiplesLinesWhenOneWithHundredLineDisc()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        VATDiscAmount: array[3] of Decimal;
        DocNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Line Discount]
        // [SCENARIO 378349] G/L Entry with VAT is posted for multiple lines order when one of the lines has "Line Discount %" = 100

        Initialize();
        // [GIVEN] Purchase Order with sales lines:
        // [GIVEN] Line "1": Line Amount = 2000, "Line Discount %" = 40, "Line Discount Amonut" = 800, "Line Discount VAT Amount" = 80
        // [GIVEN] Line "2": Line Amount = 1000, "Line Discount %" = 100, "Line Discount Amonut" = 1000, "Line Discount VAT Amount" = 100
        CreatePurchOrderWithLineDiscount(PurchHeader, PurchLine, LibraryRandom.RandInt(50));
        VATDiscAmount[1] := Round(PurchLine."Line Discount Amount" * PurchLine."VAT %" / 100);
        VATDiscAmount[2] := PurchLine."Amount Including VAT" - PurchLine.Amount;
        VATPostingSetup.Get(PurchLine."VAT Bus. Posting Group", PurchLine."VAT Prod. Posting Group");
        AddPurchLineWithHundredLineDisc(PurchLine, PurchHeader, VATPostingSetup);
        VATDiscAmount[3] := Round(PurchLine."Line Discount Amount" * PurchLine."VAT %" / 100);
        UpdateAccInGenPostingSetup(PurchLine."Gen. Bus. Posting Group", PurchLine."Gen. Prod. Posting Group");

        // [WHEN] Post Purchase Order
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [THEN] G/L Entry is posted with "Purchase VAT Account" and "Amount" = -180 for both lines (VAT for Discount)
        // [THEN] G/L Entry is posted with "Purchase VAT Account" and "Amount" = 100 (Line "2")
        VerifyAmountOfPairedGLEntries(
          DocNo, VATPostingSetup."Purchase VAT Account", -VATDiscAmount[1] - VATDiscAmount[3],
          VATDiscAmount[1] + VATDiscAmount[2] + VATDiscAmount[3]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmtOnServiceOrderWithMultiplesLinesWhenOneWithHundredLineDisc()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ServHeader: Record "Service Header";
        ServLine: Record "Service Line";
        VATDiscAmount: array[3] of Decimal;
    begin
        // [FEATURE] [Service] [Line Discount]
        // [SCENARIO 378349] G/L Entry with VAT is posted for multiple lines order when one of the lines has "Line Discount %" = 100

        Initialize();
        // [GIVEN] Service Invoice with sales lines:
        // [GIVEN] Line "1": Line Amount = 2000, "Line Discount %" = 40, "Line Discount Amonut" = 800, "Line Discount VAT Amount" = 80
        // [GIVEN] Line "2": Line Amount = 1000, "Line Discount %" = 100, "Line Discount Amonut" = 1000, "Line Discount VAT Amount" = 100
        CreateServOrderWithLineDiscount(ServHeader, ServLine, LibraryRandom.RandInt(50));
        VATDiscAmount[1] := Round(ServLine."Line Discount Amount" * ServLine."VAT %" / 100);
        VATDiscAmount[2] := ServLine."Amount Including VAT" - ServLine.Amount;
        VATPostingSetup.Get(ServLine."VAT Bus. Posting Group", ServLine."VAT Prod. Posting Group");
        AddServLineWithHundredLineDisc(ServLine, ServHeader, VATPostingSetup);
        VATDiscAmount[3] := Round(ServLine."Line Discount Amount" * ServLine."VAT %" / 100);
        UpdateAccInGenPostingSetup(ServLine."Gen. Bus. Posting Group", ServLine."Gen. Prod. Posting Group");

        // [WHEN] Post Service Order
        LibraryService.PostServiceOrder(ServHeader, true, false, true);

        // [THEN] G/L Entry is posted with "Sales VAT Account" and "Amount" = 180 for both lines (VAT for Discount)
        // [THEN] G/L Entry is posted with "Sales VAT Account" and "Amount" = -100 (Line "2")
        VerifyAmountOfPairedGLEntries(
          GetServInNo(ServHeader."No."), VATPostingSetup."Sales VAT Account", VATDiscAmount[1] + VATDiscAmount[3],
          -VATDiscAmount[1] - VATDiscAmount[2] - VATDiscAmount[3])
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesAmountOnSalesOrderWithHundredPctLineDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocNo: Code[20];
    begin
        // [FEATURE] [Sales] [Line Discount]
        // [SCENARIO 160175] G/L Entry with "Sales Amount" is posted when "Line Discount %" = 100

        Initialize();
        // [GIVEN] Sales Order with "Amount" = "X", "Line Discount %" = 100
        CreateSalesOrderWithCustomVATAndLineDiscount(
          SalesHeader, SalesLine, LibraryRandom.RandInt(100), LibraryRandom.RandDec(100, 2), 100);

        // [WHEN] Post Sales Order
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] G/L Entry is posted with G/L Account in Sales Line and "Amount" = "X"
        VerifyGLEntry(DocNo, SalesLine."No.", -SalesLine."Line Discount Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchAmountOnPurchOrderWithHundredPctLineDiscount()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        DocNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Line Discount]
        // [SCENARIO 160175] G/L Entry with "Purchase Amount" is posted when "Line Discount %" = 100

        Initialize();
        // [GIVEN] Purchase Order with "Amount" = "X", "Line Discount %" = 100
        CreatePurchOrderWithCustomVATAndLineDiscount(
          PurchHeader, PurchLine, LibraryRandom.RandInt(100), LibraryRandom.RandDec(100, 2), 100);

        // [WHEN] Post Purchase Order
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [THEN] G/L Entry is posted with G/L Account in Purchase Line and "Amount" = "X"
        VerifyGLEntry(DocNo, PurchLine."No.", PurchLine."Line Discount Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServAmountOnServiceOrderWithHundredPctLineDiscount()
    var
        GenPostingSetup: Record "General Posting Setup";
        ServHeader: Record "Service Header";
        ServLine: Record "Service Line";
    begin
        // [FEATURE] [Service] [Line Discount]
        // [SCENARIO 160175] G/L Entry with "Service Amount" is posted when "Line Discount %" = 100

        Initialize();
        // [GIVEN] Purchase Order with "Amount" = "X", "Line Discount %" = 100
        CreateServOrderWithLineDiscount(ServHeader, ServLine, 100);

        // [WHEN] Post Service Order
        LibraryService.PostServiceOrder(ServHeader, true, false, true);

        // [THEN] G/L Entry is posted with G/L Account in Service Line and "Amount" = "X"
        GenPostingSetup.Get(ServLine."Gen. Bus. Posting Group", ServLine."Gen. Prod. Posting Group");
        VerifyGLEntry(GetServInNo(ServHeader."No."), GenPostingSetup."Sales Account", -ServLine."Line Discount Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerInvoiceDiscCode()
    var
        Customer: Record Customer;
        InvoiceDiscCode: Code[20];
    begin
        // [FEATURE] [UT] [Customer]
        // [SCENARIO 217896] Customer's "Invoice Disc. Code" is updated with new Customer."No." value OnRename trigger in case of xRec."No." = xRec."Invoice Disc. Code"
        Initialize();

        // OnInsert updates blank "Invoice Disc. Code" value with "No."
        Clear(Customer);
        Customer.Insert(true);
        Customer.TestField("Invoice Disc. Code", Customer."No.");

        // Validate("No.") updates blank "Invoice Disc. Code" value with "No."
        Clear(Customer);
        Customer.Validate("No.", LibraryUtility.GenerateGUID());
        Customer.TestField("Invoice Disc. Code", Customer."No.");

        // Validate("No.") doesn't modify non blank "Invoice Disc. Code" value
        InvoiceDiscCode := LibraryUtility.GenerateGUID();
        Clear(Customer);
        Customer.Insert(true);
        Customer.Validate("Invoice Disc. Code", InvoiceDiscCode);
        Customer.Validate("No.", LibraryUtility.GenerateGUID());
        Customer.TestField("Invoice Disc. Code", InvoiceDiscCode);

        // OnInsert doesn't modify non blank "Invoice Disc. Code" value
        InvoiceDiscCode := LibraryUtility.GenerateGUID();
        Clear(Customer);
        Customer.Validate("No.", LibraryUtility.GenerateGUID());
        Customer.Validate("Invoice Disc. Code", InvoiceDiscCode);
        Customer.Insert(true);
        Customer.TestField("Invoice Disc. Code", InvoiceDiscCode);

        // OnRename doesn't modify "Invoice Disc. Code" value in case of xRec."No." <> xRec."Invoice Disc. Code"
        InvoiceDiscCode := LibraryUtility.GenerateGUID();
        Clear(Customer);
        Customer.Insert(true);
        Customer.Validate("Invoice Disc. Code", InvoiceDiscCode);
        Customer.Rename(LibraryUtility.GenerateGUID());
        Customer.TestField("Invoice Disc. Code", InvoiceDiscCode);

        // OnRename updates "Invoice Disc. Code" value with new Rec."No." in case of xRec."No." = xRec."Invoice Disc. Code"
        Clear(Customer);
        Customer.Insert(true);
        Customer.Rename(LibraryUtility.GenerateGUID());
        Customer.TestField("Invoice Disc. Code", Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorInvoiceDiscCode()
    var
        Vendor: Record Vendor;
        InvoiceDiscCode: Code[20];
    begin
        // [FEATURE] [UT] [Vendor]
        // [SCENARIO 217896] Vendor's "Invoice Disc. Code" is updated with new Vendor."No." value OnRename trigger in case of xRec."No." = xRec."Invoice Disc. Code"
        Initialize();

        // OnInsert updates blank "Invoice Disc. Code" value with "No."
        Clear(Vendor);
        Vendor.Insert(true);
        Vendor.TestField("Invoice Disc. Code", Vendor."No.");

        // Validate("No.") updates blank "Invoice Disc. Code" value with "No."
        Clear(Vendor);
        Vendor.Validate("No.", LibraryUtility.GenerateGUID());
        Vendor.TestField("Invoice Disc. Code", Vendor."No.");

        // Validate("No.") doesn't modify non blank "Invoice Disc. Code" value
        InvoiceDiscCode := LibraryUtility.GenerateGUID();
        Clear(Vendor);
        Vendor.Insert(true);
        Vendor.Validate("Invoice Disc. Code", InvoiceDiscCode);
        Vendor.Validate("No.", LibraryUtility.GenerateGUID());
        Vendor.TestField("Invoice Disc. Code", InvoiceDiscCode);

        // OnInsert doesn't modify non blank "Invoice Disc. Code" value
        InvoiceDiscCode := LibraryUtility.GenerateGUID();
        Clear(Vendor);
        Vendor.Validate("No.", LibraryUtility.GenerateGUID());
        Vendor.Validate("Invoice Disc. Code", InvoiceDiscCode);
        Vendor.Insert(true);
        Vendor.TestField("Invoice Disc. Code", InvoiceDiscCode);

        // OnRename doesn't modify "Invoice Disc. Code" value in case of xRec."No." <> xRec."Invoice Disc. Code"
        InvoiceDiscCode := LibraryUtility.GenerateGUID();
        Clear(Vendor);
        Vendor.Insert(true);
        Vendor.Validate("Invoice Disc. Code", InvoiceDiscCode);
        Vendor.Rename(LibraryUtility.GenerateGUID());
        Vendor.TestField("Invoice Disc. Code", InvoiceDiscCode);

        // OnRename updates "Invoice Disc. Code" value with new Rec."No." in case of xRec."No." = xRec."Invoice Disc. Code"
        Clear(Vendor);
        Vendor.Insert(true);
        Vendor.Rename(LibraryUtility.GenerateGUID());
        Vendor.TestField("Invoice Disc. Code", Vendor."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerTemplateInvoiceDiscCodeRenameCustomer()
    var
        Customer: array[2] of Record Customer;
        CustomerTemplate: array[3] of Record "Customer Templ.";
    begin
        // [FEATURE] [UT] [Customer]
        // [SCENARIO 217896] Customer Template's "Invoice Disc. Code" is updated with new Customer."No." value OnRename Customer's trigger
        Initialize();

        // [GIVEN] Customer "X1" with "Invoice Disc. Code" = "X1"
        Customer[1].Insert(true);
        // [GIVEN] Customer "X2" with "Invoice Disc. Code" = "X2"
        Customer[2].Insert(true);

        // [GIVEN] Customer Template "T1" with "Invoice Disc. Code" = "X1"
        MockCustomerTemplate(CustomerTemplate[1], Customer[1]."No.");
        // [GIVEN] Customer Template "T2" with "Invoice Disc. Code" = "X1"
        MockCustomerTemplate(CustomerTemplate[2], Customer[1]."No.");
        // [GIVEN] Customer Template "T3" with "Invoice Disc. Code" = "X2"
        MockCustomerTemplate(CustomerTemplate[3], Customer[2]."No.");

        // [WHEN] Rename Customer "X1" to "X3"
        Customer[1].Rename(LibraryUtility.GenerateGUID());

        // [THEN] Customer Template "T1"."Invoice Disc. Code" = "X3"
        CustomerTemplate[1].Find();
        CustomerTemplate[1].TestField("Invoice Disc. Code", Customer[1]."No.");
        // [THEN] Customer Template "T2"."Invoice Disc. Code" = "X3"
        CustomerTemplate[2].Find();
        CustomerTemplate[2].TestField("Invoice Disc. Code", Customer[1]."No.");
        // [THEN] Customer Template "T3"."Invoice Disc. Code" = "X2"
        CustomerTemplate[3].Find();
        CustomerTemplate[3].TestField("Invoice Disc. Code", Customer[2]."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntriesForSalesInvoiceWith100PctLineDiscount()
    var
        GLEntry: Record "G/L Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Line Discount]
        // [SCENARIO 221273] Two VAT and G\L Entries (positive and negative) after posting sales order with 100% line discount
        Initialize();

        // [GIVEN] Sales order with 1 line having 100% "Line Discount"
        CreateSalesOrderWithLineDiscount(SalesHeader, SalesLine, 100);

        // [WHEN] Post the order
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] There are two G/L Entries for "Sales VAT Account" have been created
        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        GLEntry.SetRange("G/L Account No.", VATPostingSetup."Sales VAT Account");
        GLEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(GLEntry, 2);

        // [THEN] There are two VAT Entries have been created
        VATEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(VATEntry, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntriesForPurchInvoiceWith100PctLineDiscount()
    var
        GLEntry: Record "G/L Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATEntry: Record "VAT Entry";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Line Discount]
        // [SCENARIO 221273] Two VAT and G\L Entries (positive and negative) after posting purchase order with 100% line discount
        Initialize();

        // [GIVEN] Purchase Invoice with 1 line having 100% "Line Discount"
        CreatePurchOrderWithLineDiscount(PurchaseHeader, PurchaseLine, 100);

        // [WHEN] Post the order
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] There are two G/L Entries for "Purchase VAT Account" have been created
        VATPostingSetup.Get(PurchaseLine."VAT Bus. Posting Group", PurchaseLine."VAT Prod. Posting Group");
        GLEntry.SetRange("G/L Account No.", VATPostingSetup."Purchase VAT Account");
        GLEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(GLEntry, 2);

        // [THEN] There are two VAT Entries have been created
        VATEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(VATEntry, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATBaseBeforePmtDiscOnPurchaseInvoiceWithTwoLines()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATEntry: Record "VAT Entry";
        Base: Decimal;
        DocNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Payment Discount]
        // [SCENARIO 251869] When posting a purchase invoice with 2 lines, the field "Base Before Pmt. Disc." in the VAT Entry contains sum of VAT bases.
        Initialize();

        // [GIVEN] Purchase Invoice
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Purchase Line 1 with Amount of 100
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        Base += PurchaseLine.Amount;

        // [GIVEN] Purchase Line 2 with Amount of 200
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        Base += PurchaseLine.Amount;

        // [WHEN] Post Purchase Invoice
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] "Base Before Pmt. Disc." of VAT Entry is 300
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", DocNo);
        VATEntry.FindFirst();
        VATEntry.TestField("Base Before Pmt. Disc.", Base);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCalcTotalPurchAmountOnlyDiscountAllowed()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchLineDiscountNotAllowed: Record "Purchase Line";
        DocumentTotals: Codeunit "Document Totals";
    begin
        // [FEATURE] [Purchase] [Discount] [UT]
        // [SCENARIO 256682] CalcTotalPurchAmountOnlyDiscountAllowed function returns total amount of Purchase lines with allowed discount.
        Initialize();

        // [GIVEN] Purchase Header.
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Purchase Line "PL1" with Invoice Discount allowed.
        CreatePurchLineAndSetAllowInvDiscount(PurchLine, PurchHeader, true);

        // [GIVEN] Purchase Line "PL2" with Invoice Discount not allowed.
        CreatePurchLineAndSetAllowInvDiscount(PurchLineDiscountNotAllowed, PurchHeader, false);

        // [WHEN] Run CalcTotalPurchAmountOnlyDiscountAllowed.
        // [THEN] Calculated total amount is equal to "PL1" amount.
        Assert.AreEqual(
          PurchLine."Line Amount",
          DocumentTotals.CalcTotalPurchAmountOnlyDiscountAllowed(PurchLine),
          CalcTotalPurchAmountOnlyDiscountAllowedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCalcTotalSalesAmountOnlyDiscountAllowed()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineDiscountNotAllowed: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
    begin
        // [FEATURE] [Sales] [Discount] [UT]
        // [SCENARIO 256682] CalcTotalSalesAmountOnlyDiscountAllowed function returns total amount of Sales lines with allowed discount.
        Initialize();

        // [GIVEN] Sales Header.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [GIVEN] Sales Line "SL1" with Invoice Discount allowed.
        CreateSalesLineAndSetAllowInvDiscount(SalesLine, SalesHeader, true);

        // [GIVEN] Sales Line "SL2" with Invoice Discount not allowed.
        CreateSalesLineAndSetAllowInvDiscount(SalesLineDiscountNotAllowed, SalesHeader, false);

        // [WHEN] Run CalcTotalPurchAmountOnlyDiscountAllowed.
        // [THEN] Calculated total amount is equal to "PL1" amount.
        Assert.AreEqual(
          SalesLine."Line Amount",
          DocumentTotals.CalcTotalSalesAmountOnlyDiscountAllowed(SalesLine),
          CalcTotalSalesAmountOnlyDiscountAllowedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetVendInvoiceDiscountPctOnlyDiscountAllowed()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchLineDiscountNotAllowed: Record "Purchase Line";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
    begin
        // [FEATURE] [Purchase] [Discount] [UT]
        // [SCENARIO 256682] GetVendInvoiceDiscountPct function calculates Discount % based only on Purchase lines with allowed discount.
        Initialize();

        // [GIVEN] Purchase Header with default Invoice Discount Calculation.
        CreatePurchaseOrderWithInvoiceDiscountCalculation(PurchHeader, PurchHeader."Invoice Discount Calculation"::None);

        // [GIVEN] Purchase Line "PL1" with Invoice Discount allowed and Discount Amount.
        CreatePurchLineAndSetAllowInvDiscount(PurchLine, PurchHeader, true);
        PurchLine.Validate("Inv. Discount Amount", LibraryRandom.RandDec(Round(PurchLine.Amount, 1, '<'), 2));
        PurchLine.Modify(true);

        // [GIVEN] Purchase Line "PL2" with Invoice Discount not allowed.
        CreatePurchLineAndSetAllowInvDiscount(PurchLineDiscountNotAllowed, PurchHeader, false);
        PurchLineDiscountNotAllowed.Validate("Inv. Discount Amount", 0);
        PurchLineDiscountNotAllowed.Modify(true);

        // [WHEN] Run GetVendInvoiceDiscountPct.
        // [THEN] Discount % is calculated based on "PL1".
        Assert.AreEqual(
          Round(PurchLine."Inv. Discount Amount" / (PurchLine.Amount + PurchLine."Inv. Discount Amount") * 100, 0.01),
          PurchCalcDiscByType.GetVendInvoiceDiscountPct(PurchLine),
          GetInvoiceDiscountPctErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetCustInvoiceDiscountPctOnlyDiscountAllowed()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineDiscountNotAllowed: Record "Sales Line";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
    begin
        // [FEATURE] [Sales] [Discount] [UT]
        // [SCENARIO 256682] GetCustInvoiceDiscountPct function calculates Discount % based only on Sales lines with allowed discount.
        Initialize();

        // [GIVEN] Sales Header with default Invoice Discount Calculation.
        CreateSalesOrderWithInvoiceDiscountCalculation(SalesHeader, SalesHeader."Invoice Discount Calculation"::None);

        // [GIVEN] Sales Line "SL1" with Invoice Discount allowed and Discount Amount.
        CreateSalesLineAndSetAllowInvDiscount(SalesLine, SalesHeader, true);
        SalesLine.Validate("Inv. Discount Amount", LibraryRandom.RandDec(Round(SalesLine.Amount, 1, '<'), 2));
        SalesLine.Modify(true);

        // [GIVEN] Sales Line "SL2" with Invoice Discount not allowed.
        CreateSalesLineAndSetAllowInvDiscount(SalesLineDiscountNotAllowed, SalesHeader, false);
        SalesLineDiscountNotAllowed.Validate("Inv. Discount Amount", 0);
        SalesLineDiscountNotAllowed.Modify(true);

        // [WHEN] Run GetCustInvoiceDiscountPct.
        // [THEN] Discount % is calculated based on "SL1".
        Assert.AreEqual(
          Round(SalesLine."Inv. Discount Amount" / (SalesLine.Amount + SalesLine."Inv. Discount Amount") * 100, 0.01),
          SalesCalcDiscountByType.GetCustInvoiceDiscountPct(SalesLine),
          GetInvoiceDiscountPctErr);
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure NoMissedGLAccountNotificationSales()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Sales] [Discount] [UT]
        // [SCENARIO 421486] "G/L accounts for discounts are missing" notification is not shown for sales document if there is at least one general posting setup with empty G/L account
        Initialize();

        // [GIVEN] Enable Invoice Discount for sales
        LibrarySales.SetCalcInvDiscount(true);
        // [GIVEN] New general posting setup "BUS" "PROD" with empty G/L accounts
        CreateGeneralPostingSetup(GeneralPostingSetup);

        // [GIVEN] Sales order "SO" for customer "C" with some invoice discount and Gen. Bus. Posting Group = "BUS"
        CreateVATPostingSetup(VATPostingSetup, LibraryRandom.RandInt(20));
        LibrarySales.CreateSalesHeader(
           SalesHeader, SalesHeader."Document Type"::Order,
           CreateCustomerWithInvoiceDiscountGenPostGroup(VATPostingSetup."VAT Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group"));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(true, VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandDec(10, 2));

        // [WHEN] Open sales order page for "SO"
        SalesOrder.OpenEdit();
        SalesOrder.Filter.SetFilter("No.", SalesHeader."No.");

        // [THEN] No notification "G/L accounts for discounts are missing" (checked in VerifyNoNotificationsAreSend)
    end;

    [Test]
    [HandlerFunctions('VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure NoMissedGLAccountNotificationPurchase()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [FEATURE] [Purchase] [Discount] [UT]
        // [SCENARIO 421486] "G/L accounts for discounts are missing" notification is not shown for purchase document if there is at least one general posting setup with empty G/L account
        Initialize();

        // [GIVEN] Enable Invoice Discount for Purchase
        LibraryPurchase.SetCalcInvDiscount(true);
        // [GIVEN] New general posting setup "BUS" "PROD" with empty G/L accounts
        CreateGeneralPostingSetup(GeneralPostingSetup);

        // [GIVEN] Purchase order "PO" for vendor "V" with some invoice discount and Gen. Bus. Posting Group = "BUS"
        CreateVATPostingSetup(VATPostingSetup, LibraryRandom.RandInt(20));
        LibraryPurchase.CreatePurchHeader(
           PurchaseHeader, PurchaseHeader."Document Type"::Order,
           CreateVendorWithInvoiceDiscountGenPostGroup(VATPostingSetup."VAT Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(true, VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandDec(10, 2));

        // [WHEN] Open purchase order page for "PO"
        PurchaseOrder.OpenEdit();
        PurchaseOrder.Filter.SetFilter("No.", PurchaseHeader."No.");

        // [THEN] No notification "G/L accounts for discounts are missing" (checked in VerifyNoNotificationsAreSend)
    end;
#if not CLEAN27
    [Test]
    [HandlerFunctions('ServiceOrderStatisticsHandler,VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure NoMissedGLAccountNotificationService()
    var
        ServHeader: Record "Service Header";
        ServLine: Record "Service Line";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        ServiceOrder: TestPage "Service Order";
    begin
        // [FEATURE] [Service] [Discount] [UT]
        // [SCENARIO 421486] "G/L accounts for discounts are missing" notification is not shown for service document if there is at least one general posting setup with empty G/L account
        Initialize();

        // [GIVEN] New general posting setup "BUS" "PROD" with empty G/L accounts
        CreateGeneralPostingSetup(GeneralPostingSetup);

        // [GIVEN] Service order "SO" for customer "C" with some invoice discount and Gen. Bus. Posting Group = "BUS"
        CreateVATPostingSetup(VATPostingSetup, LibraryRandom.RandInt(20));
        LibraryService.CreateServiceHeader(
          ServHeader, ServHeader."Document Type"::Order,
          CreateCustomerWithInvoiceDiscountGenPostGroup(VATPostingSetup."VAT Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group"));
        LibraryService.CreateServiceLine(
          ServLine, ServHeader, ServLine.Type::Item, CreateItem(true, VATPostingSetup."VAT Prod. Posting Group"));

        // [WHEN] Open service order page for "SO" and run statistics to cause discount calculation
        ServiceOrder.OpenEdit();
        ServiceOrder.Filter.SetFilter("No.", ServHeader."No.");
        ServiceOrder.Statistics.Invoke();

        // [THEN] No notification "G/L accounts for discounts are missing" (checked in VerifyNoNotificationsAreSend)
    end;
#endif
    [Test]
    [HandlerFunctions('ServiceOrderStatisticsHandlerNM,VerifyNoNotificationsAreSend')]
    [Scope('OnPrem')]
    procedure NoMissedGLAccountNotificationServiceNM()
    var
        ServHeader: Record "Service Header";
        ServLine: Record "Service Line";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        ServiceOrder: TestPage "Service Order";
    begin
        // [FEATURE] [Service] [Discount] [UT]
        // [SCENARIO 421486] "G/L accounts for discounts are missing" notification is not shown for service document if there is at least one general posting setup with empty G/L account
        Initialize();

        // [GIVEN] New general posting setup "BUS" "PROD" with empty G/L accounts
        CreateGeneralPostingSetup(GeneralPostingSetup);

        // [GIVEN] Service order "SO" for customer "C" with some invoice discount and Gen. Bus. Posting Group = "BUS"
        CreateVATPostingSetup(VATPostingSetup, LibraryRandom.RandInt(20));
        LibraryService.CreateServiceHeader(
          ServHeader, ServHeader."Document Type"::Order,
          CreateCustomerWithInvoiceDiscountGenPostGroup(VATPostingSetup."VAT Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group"));
        LibraryService.CreateServiceLine(
          ServLine, ServHeader, ServLine.Type::Item, CreateItem(true, VATPostingSetup."VAT Prod. Posting Group"));

        // [WHEN] Open service order page for "SO" and run statistics to cause discount calculation
        ServiceOrder.OpenEdit();
        ServiceOrder.Filter.SetFilter("No.", ServHeader."No.");
        ServiceOrder.ServiceOrderStatistics.Invoke();

        // [THEN] No notification "G/L accounts for discounts are missing" (checked in VerifyNoNotificationsAreSend)
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyInvDiscountAmountOnCorrectiveCreditMemoIsSameAsPostedPurchInvInCaseOfLotTracking()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchHeaderCorrection: Record "Purchase Header";
        PurchaseLineCorrection: Record "Purchase Line";
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
        PstdInvoiceNo: Code[20];
    begin
        // [SCENARIO 487786] When Posted Purchase Invoice includes Invoice Discount and line that is lot-tracked, then Credit Memo from Create Corrective Credit Memo incorrectly has negative Invoice Discount Amount.
        Initialize();

        // [GIVEN] Find VAT Posting Setup.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        // [GIVEN] Create Purchase Invoice, Purchase Line, Item with Lot Specific Tracking
        CreatePurchaseInvoiceHeader(PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
            CreateItemWithTracking(true, VATPostingSetup."VAT Prod. Posting Group"),
            LibraryRandom.RandInt(10));

        // [THEN Calculate Invoice Discount on Purchase Invoice and set Item Tracking Line
        PurchCalcDiscount.CalculateInvoiceDiscount(PurchaseHeader, PurchaseLine);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Assign Lot No.");
        PurchaseLine.OpenItemTrackingLines();

        // [WHEN] Release and Post the Purchase Invoice
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        UpdateGeneralPostingSetup(GeneralPostingSetup, PurchaseLine);
        PstdInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        PurchInvHeader.Get(PstdInvoiceNo);

        // [WHEN] Create Corrective Credit Memo for Posted Purchase Invoice and find the Item Line
        CorrectPostedPurchInvoice.CreateCreditMemoCopyDocument(PurchInvHeader, PurchHeaderCorrection);
        PurchaseLineCorrection.SetRange("Document No.", PurchHeaderCorrection."No.");
        PurchaseLineCorrection.SetRange("No.", PurchaseLine."No.");
        PurchaseLineCorrection.FindFirst();

        // Verify: Verify Invoice Discount on newly created Purchase Credit Memo
        Assert.AreEqual(
            PurchaseLine."Inv. Discount Amount",
            PurchaseLineCorrection."Inv. Discount Amount",
            StrSubstNo(
                ValueMustBeEqualErr,
                PurchaseLineCorrection.FieldCaption("Inv. Discount Amount"),
                PurchaseLine."Inv. Discount Amount",
                PurchaseLineCorrection.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoErrorWhenSalesLineAmountIsZeroWithMultiLinesInvoiceDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[5] of Record "Sales Line";
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        VATProdPostingGroup: Record "VAT Product Posting Group";
        ItemNo: array[2] of Code[20];
        InvoiceDiscountPerc: Integer;
        SalesInvoicePage: TestPage "Sales Invoice";
        UnitPrice: Decimal;
    begin
        // [SCENARIO 573759] No error of "Attempted to Divide by zero" error when Allow Invoice Discount set to false on a Sales Invoice where calculated Invoice Discounts are
        // redistributed to certain lines. Sales Invoice can be reopened.
        Initialize();

        // [GIVEN] Set Cal. Inv. Discount to false
        LibrarySales.SetCalcInvDiscount(false);

        // [GIVEN] Find VAT Posting Setup
        LibraryERM.FindVATPostingSetup(VATPostingSetup[1], VATPostingSetup[1]."VAT Calculation Type"::"Normal VAT");

        // [GIVEN] Create Sales Header for Sales Invoice
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(VATPostingSetup[1]."VAT Bus. Posting Group"));

        // [GIVEN] Create new VAT Product Posting Group
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);

        // [GIVEN] Create VAT Posting Setup
        LibraryERM.CreateVATPostingSetup(VATPostingSetup[2], VATPostingSetup[1]."VAT Bus. Posting Group", VATProdPostingGroup.Code);

        // [GIVEN] Create 2 items
        ItemNo[1] := CreateItem(true, VATPostingSetup[1]."VAT Prod. Posting Group");
        ItemNo[2] := CreateItem(true, VATPostingSetup[2]."VAT Prod. Posting Group");

        // [GIVEN] Save value to Unit Price and Invoice Discount Percent
        UnitPrice := LibraryRandom.RandDec(1000, 2);
        InvoiceDiscountPerc := LibraryRandom.RandInt(100);

        // [GIVEN] Create multiple Sales Line
        CreateSalesLine(SalesHeader, SalesLine[1], ItemNo[1], UnitPrice, 1);
        CreateSalesLine(SalesHeader, SalesLine[2], ItemNo[2], UnitPrice, 1);
        CreateSalesLine(SalesHeader, SalesLine[3], ItemNo[1], UnitPrice, -1);
        CreateSalesLine(SalesHeader, SalesLine[4], ItemNo[2], UnitPrice, 1);
        CreateSalesLine(SalesHeader, SalesLine[5], ItemNo[2], UnitPrice, -1);

        // [GIVEN] Open Sales Invoice page
        SalesInvoicePage.OpenEdit();
        SalesInvoicePage.Filter.SetFilter("No.", SalesHeader."No.");

        // [WHEN] Set Invoice Discount Percent
        SalesInvoicePage.SalesLines."Invoice Disc. Pct.".SetValue(InvoiceDiscountPerc);

        // [THEN] Verify Invoice Discount Amount calculated correctly
        SalesInvoicePage.SalesLines.GoToRecord(SalesLine[4]);
        SalesInvoicePage.SalesLines."Invoice Discount Amount".AssertEquals(UnitPrice * InvoiceDiscountPerc / 100);

        // [WHEN] Set Allow Invoice Disc to false, no error will come
        SalesLine[4]."Allow Invoice Disc." := false;
        SalesLine[4].Modify();

        // [THEN] Verify Invoice Discount Amount will 0
        SalesInvoicePage.SalesLines.GoToRecord(SalesLine[4]);
        SalesInvoicePage.SalesLines."Invoice Discount Amount".AssertEquals(0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoErrorWhenPurchaseLineAmountIsZeroWithMultiLinesInvoiceDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: array[5] of Record "Purchase Line";
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        VATProdPostingGroup: Record "VAT Product Posting Group";
        ItemNo: array[2] of Code[20];
        InvoiceDiscountPerc: Integer;
        PurchaseInvoicePage: TestPage "Purchase Invoice";
        UniCost: Decimal;
        AmountBeforeDiscount: Decimal;
    begin
        // [SCENARIO 573759] No error of "Attempted to Divide by zero" error when Allow Invoice Discount set to false on a Purchase Invoice where calculated Invoice Discounts are
        // redistributed to certain lines. Purchase Invoice can be reopened.
        Initialize();

        // [GIVEN] Set Cal. Inv. Discount to false
        LibraryPurchase.SetCalcInvDiscount(false);

        // [GIVEN] Find VAT Posting Setup
        LibraryERM.FindVATPostingSetup(VATPostingSetup[1], VATPostingSetup[1]."VAT Calculation Type"::"Normal VAT");

        // [GIVEN] Create Purchase Header for Purchase Invoice
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, CreateVendorWithVATBusPostingGroup(VATPostingSetup[1]."VAT Bus. Posting Group"));

        // [GIVEN] Create new VAT Product Posting Group
        LibraryERM.CreateVATProductPostingGroup(VATProdPostingGroup);

        // [GIVEN] Create VAT Posting Setup
        LibraryERM.CreateVATPostingSetup(VATPostingSetup[2], VATPostingSetup[1]."VAT Bus. Posting Group", VATProdPostingGroup.Code);

        // [GIVEN] Create 2 items
        ItemNo[1] := CreateItem(true, VATPostingSetup[1]."VAT Prod. Posting Group");
        ItemNo[2] := CreateItem(true, VATPostingSetup[2]."VAT Prod. Posting Group");

        // [GIVEN] Save value to Unit Cost and Invoice Discount Percent
        UniCost := LibraryRandom.RandDec(1000, 2);
        InvoiceDiscountPerc := LibraryRandom.RandInt(100);

        // [GIVEN] Create multiple Purchase Line
        CreatePurchaseLine(PurchaseHeader, PurchaseLine[1], ItemNo[1], UniCost, 1);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine[2], ItemNo[2], UniCost, 1);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine[3], ItemNo[1], UniCost, -1);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine[4], ItemNo[2], UniCost, 1);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine[5], ItemNo[2], UniCost, -1);

        // [GIVEN] Open Purchase Invoice page
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.Filter.SetFilter("No.", PurchaseHeader."No.");

        // [WHEN] Set Invoice Discount Percent
        PurchaseInvoicePage.PurchLines."Invoice Disc. Pct.".SetValue(InvoiceDiscountPerc);

        // [THEN] Verify Invoice Discount Amount calculated correctly
        PurchaseInvoicePage.PurchLines.GoToRecord(PurchaseLine[4]);
        Evaluate(AmountBeforeDiscount, PurchaseInvoicePage.PurchLines.AmountBeforeDiscount.Value);
        PurchaseInvoicePage.PurchLines.InvoiceDiscountAmount.AssertEquals(AmountBeforeDiscount * InvoiceDiscountPerc / 100);

        // [WHEN] Set Allow Invoice Disc to false, no error will come
        PurchaseLine[4]."Allow Invoice Disc." := false;
        PurchaseLine[4].Modify();

        // [THEN] Verify Invoice Discount Percent will be same as before
        PurchaseInvoicePage.PurchLines.GoToRecord(PurchaseLine[4]);
        PurchaseInvoicePage.PurchLines."Invoice Disc. Pct.".AssertEquals(InvoiceDiscountPerc);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Invoice Discount And VAT");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        // Lazy Setup.
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Invoice Discount And VAT");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateFAPostingType();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibraryTemplates.EnableTemplatesFeature();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Invoice Discount And VAT");
    end;

    local procedure InvDiscAndVATOnPurchInvoice(AllowInvoiceDisc: Boolean; Released: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
        ItemNo: Code[20];
    begin
        // 1. Find VAT Posting Setup.
        // 2. Create a new Item with Allow Invoice Discount Parameter.
        // 3. Create a new Vendor and update Invoice Discount Code On Vendor.
        // 4. Create a Purchase Invoice With the newly created Item.
        // 5. Calculate Invoice Discount on Purchase Invoice.
        // 6. Let the Purchase Invoice be Open or Released as per the parameter.
        // 7. Verify Invoice Discount Amount and Amount Including VAT for the Purchase Invoice.

        // Setup: Create Purchase Invoice with newly created Item and Vendor.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        ItemNo := CreateItem(AllowInvoiceDisc, VATPostingSetup."VAT Prod. Posting Group");
        CreatePurchaseInvoiceHeader(PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));

        // Exercise: Calculate Invoice Discount on Purchase Invoice, Release the Purchase Invoice.
        PurchCalcDiscount.CalculateInvoiceDiscount(PurchaseHeader, PurchaseLine);

        if Released then
            LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // Verify: Verify Invoice Discount Amount and Amount Including VAT for the Purchase Invoice.
        VerifyInvDiscAmtAndVATAmt(PurchaseLine, ItemNo, VATPostingSetup."VAT %", AllowInvoiceDisc);
    end;

    local procedure InitializeSalesMultipleLinesEqualAmountsScenario(var SalesHeader: Record "Sales Header"; var InvoiceDiscountAmount: Decimal; CurrencyCode: Code[10])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
        Currency: Record Currency;
        Customer: Record Customer;
        ItemNo: Code[20];
        ItemCost: Decimal;
        ItemQuantity: Decimal;
        Index: Integer;
    begin
        CreateVATPostingSetup(VATPostingSetup, LibraryRandom.RandDecInRange(10, 20, 2));

        Customer.Get(CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        SetupCustomerInvoiceRoundingAccount(Customer."Customer Posting Group", VATPostingSetup);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);

        ItemNo := CreateItem(true, VATPostingSetup."VAT Prod. Posting Group");
        ItemCost := LibraryRandom.RandDec(100, 2);
        ItemQuantity := LibraryRandom.RandDec(100, 2);
        for Index := 1 to LibraryRandom.RandIntInRange(3, 10) do
            CreateSalesLine(SalesHeader, SalesLine, ItemNo, ItemCost, ItemQuantity);

        Currency.Initialize(CurrencyCode);
        InvoiceDiscountAmount := -Currency."Amount Rounding Precision";
    end;

    local procedure InitializePurchaseMultipleLinesEqualAmountsScenario(var PurchaseHeader: Record "Purchase Header"; var InvoiceDiscountAmount: Decimal; CurrencyCode: Code[10])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseLine: Record "Purchase Line";
        Currency: Record Currency;
        Vendor: Record Vendor;
        ItemNo: Code[20];
        ItemCost: Decimal;
        ItemQuantity: Decimal;
        Index: Integer;
    begin
        CreateVATPostingSetup(VATPostingSetup, LibraryRandom.RandDecInRange(10, 20, 2));

        Vendor.Get(CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        SetupVendorInvoiceRoundingAccount(Vendor."Vendor Posting Group", VATPostingSetup);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);

        ItemNo := CreateItem(true, VATPostingSetup."VAT Prod. Posting Group");
        ItemCost := LibraryRandom.RandDec(100, 2);
        ItemQuantity := LibraryRandom.RandDec(100, 2);
        for Index := 1 to LibraryRandom.RandIntInRange(3, 10) do
            CreatePurchaseLine(PurchaseHeader, PurchaseLine, ItemNo, ItemCost, ItemQuantity);

        Currency.Initialize(CurrencyCode);
        InvoiceDiscountAmount := -Currency."Amount Rounding Precision";
    end;

    local procedure CreateCurrency(var Currency: Record Currency; var Decimals: Integer)
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        Decimals := LibraryRandom.RandIntInRange(1, 4);
        Currency.Validate("Amount Rounding Precision", 1 / Power(10, Decimals));
        Currency.Modify(true);
    end;

    local procedure CreateGeneralPostingSetup(var GeneralPostingSetup: Record "General Posting Setup")
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, GenBusinessPostingGroup.Code, GenProductPostingGroup.Code);
    end;

    local procedure GetItemCost(Remainder: Decimal; LineDiscountPercent: Integer; InvDiscountAmount: Decimal; Decimals: Integer) ItemCost: Decimal
    begin
        if LineDiscountPercent = 100 then
            ItemCost := LibraryRandom.RandDec(InvDiscountAmount, Decimals)
        else
            if Remainder > 0 then
                ItemCost := Remainder
            else begin
                ItemCost := LibraryRandom.RandDec(InvDiscountAmount * 2, Decimals);
                if IsOdd(ItemCost, Decimals) then
                    ItemCost -= 1 / Power(10, Decimals);
            end;
    end;

    local procedure IsOdd(Value: Decimal; Decimals: Integer): Boolean
    begin
        exit(Value * Power(10, Decimals) mod 2 = 0)
    end;

    local procedure CalculateInvoiceDiscountOnSalesInvoice(SalesHeader: Record "Sales Header")
    begin
        SalesHeader.CalcInvDiscForHeader();
        Commit();
        PAGE.RunModal(PAGE::"Sales Order Statistics", SalesHeader); // InvDiscountAmount will be set in handler
    end;

    local procedure CalculateInvoiceDiscountOnPurchaseInvoice(PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.CalcInvDiscForHeader();
        Commit();
        PAGE.RunModal(PAGE::"Purchase Order Statistics", PurchaseHeader); // InvDiscountAmount will be set in handler
    end;

    local procedure CreateMultiplePurchaseLines(VATPostingSetup: Record "VAT Posting Setup"; PurchaseHeader: Record "Purchase Header"; InvDiscountAmount: Decimal)
    var
        Vendor: Record Vendor;
        Currency: Record Currency;
        PurchaseLine: Record "Purchase Line";
        ItemNo: Code[20];
        Decimals: Integer;
        RemainderAmt: Decimal;
    begin
        CreateCurrency(Currency, Decimals);
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        Vendor.Validate("Currency Code", Currency.Code);
        Vendor.Modify(true);
        PurchaseHeader.Validate("Currency Code", Currency.Code);
        PurchaseHeader.Modify(true);

        ItemNo := CreateItem(true, VATPostingSetup."VAT Prod. Posting Group");

        // 1st line
        CreatePurchaseLine(
          PurchaseHeader, PurchaseLine, ItemNo, GetItemCost(RemainderAmt, 0, InvDiscountAmount, Decimals), 1);
        RemainderAmt := InvDiscountAmount * 2 - PurchaseLine."Direct Unit Cost";

        // 2nd line
        CreatePurchaseLine(
          PurchaseHeader, PurchaseLine, ItemNo, GetItemCost(RemainderAmt, 100, InvDiscountAmount, Decimals), 1);
        PurchaseLine.Validate("Line Discount %", 100);
        PurchaseLine.Modify(true);

        // 3rd line
        CreatePurchaseLine(
          PurchaseHeader, PurchaseLine, ItemNo, GetItemCost(RemainderAmt, 0, InvDiscountAmount, Decimals), 1);
    end;

    local procedure CreateTwoPurchLinesWithZeroTotalAmount(VATPostingSetup: Record "VAT Posting Setup"; PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
        ItemNo: Code[20];
        ItemCost: Decimal;
        Quantity: Decimal;
        Discount: Decimal;
    begin
        ItemNo := CreateItem(true, VATPostingSetup."VAT Prod. Posting Group");
        ItemCost := LibraryRandom.RandDec(1000, 2);

        VendorInvoiceDisc.SetRange(Code, PurchaseHeader."Buy-from Vendor No.");
        VendorInvoiceDisc.SetRange("Currency Code", PurchaseHeader."Currency Code");
        VendorInvoiceDisc.FindFirst();
        Discount := VendorInvoiceDisc."Discount %";

        Quantity := LibraryRandom.RandDecInRange(100, 1000, 2) * Discount;

        // 1st line
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, ItemNo, ItemCost, Quantity);
        // 2nd line
        CreatePurchaseLine(PurchaseHeader, PurchaseLine, ItemNo, ItemCost, -Quantity);
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; ItemCost: Decimal; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", ItemCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateMultipleSalesLines(VATPostingSetup: Record "VAT Posting Setup"; SalesHeader: Record "Sales Header"; InvDiscountAmount: Decimal)
    var
        Currency: Record Currency;
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
        RemainderAmt: Decimal;
        Decimals: Integer;
    begin
        CreateCurrency(Currency, Decimals);
        Customer.Get(SalesHeader."Sell-to Customer No.");
        Customer.Validate("Currency Code", Currency.Code);
        Customer.Modify(true);
        SalesHeader.Validate("Currency Code", Currency.Code);
        SalesHeader.Modify(true);

        ItemNo := CreateItem(true, VATPostingSetup."VAT Prod. Posting Group");

        // 1st line
        CreateSalesLine(
          SalesHeader, SalesLine, ItemNo, GetItemCost(RemainderAmt, 0, InvDiscountAmount, Decimals), 1);
        RemainderAmt := InvDiscountAmount * 2 - SalesLine."Unit Price";

        // 2nd line
        CreateSalesLine(
          SalesHeader, SalesLine, ItemNo, GetItemCost(RemainderAmt, 100, InvDiscountAmount, Decimals), -1);
        SalesLine.Validate("Line Discount %", 100);
        SalesLine.Modify(true);

        // 3rd line
        CreateSalesLine(
          SalesHeader, SalesLine, ItemNo, GetItemCost(RemainderAmt, 0, InvDiscountAmount, Decimals), 1);
    end;

    local procedure CreateTwoSalesLinesWithZeroTotalAmount(VATPostingSetup: Record "VAT Posting Setup"; SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        ItemNo: Code[20];
        UnitPrice: Decimal;
        Quantity: Decimal;
        Discount: Decimal;
    begin
        ItemNo := CreateItem(true, VATPostingSetup."VAT Prod. Posting Group");
        UnitPrice := LibraryRandom.RandDec(1000, 2);

        CustInvoiceDisc.SetRange(Code, SalesHeader."Sell-to Customer No.");
        CustInvoiceDisc.SetRange("Currency Code", SalesHeader."Currency Code");
        CustInvoiceDisc.FindFirst();
        Discount := CustInvoiceDisc."Discount %";

        Quantity := LibraryRandom.RandDecInRange(100, 1000, 2) * Discount;

        // 1st line
        CreateSalesLine(SalesHeader, SalesLine, ItemNo, UnitPrice, Quantity);
        // 2nd line
        CreateSalesLine(SalesHeader, SalesLine, ItemNo, UnitPrice, -Quantity);
    end;

    local procedure CreateSalesLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; ItemCost: Decimal; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Unit Price", ItemCost);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineAndCalculateInvoiceDiscount(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; VATProductPostingGroupCode: Code[20])
    var
        SalesCalcDiscount: Codeunit "Sales-Calc. Discount";
    begin
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(true, VATProductPostingGroupCode),
          LibraryRandom.RandDec(10, 2));
        SalesCalcDiscount.CalculateWithSalesHeader(SalesHeader, SalesLine);
    end;

    local procedure CreateSalesOrderWithCalculateInvoiceDiscount(var SalesHeader: Record "Sales Header"; var SalesLine: array[2] of Record "Sales Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateVATPostingSetup(VATPostingSetup, LibraryRandom.RandInt(20));
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order,
          CreateCustomerWithInvoiceDiscount(VATPostingSetup."VAT Bus. Posting Group"));
        CreateSalesLineAndCalculateInvoiceDiscount(
          SalesHeader, SalesLine[1], VATPostingSetup."VAT Prod. Posting Group");
        CreateSalesLineAndCalculateInvoiceDiscount(
          SalesHeader, SalesLine[2], VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure CreateSalesOrderWithPmtDiscExclVATAndCalculateInvoiceDiscount(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesCalcDiscount: Codeunit "Sales-Calc. Discount";
    begin
        CreateVATPostingSetup(VATPostingSetup, LibraryRandom.RandInt(20));
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order,
          CreateCustomerWithInvoiceDiscount(VATPostingSetup."VAT Bus. Posting Group"));
        SalesHeader.Validate("Payment Discount %", LibraryRandom.RandDec(10, 2));
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          CreateItem(true, VATPostingSetup."VAT Prod. Posting Group"), LibraryRandom.RandDec(10, 2));
        SalesCalcDiscount.CalculateWithSalesHeader(SalesHeader, SalesLine);
    end;

    local procedure CreateSalesInvoiceWithMultilinesInvoiceDiscount(var InvDiscountAmount: Decimal): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
    begin
        // Create Sales Header
        LibrarySales.SetCalcInvDiscount(false); // "Calc. Inv. Discount" is False
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        InvDiscountAmount := LibraryRandom.RandInt(100);

        // Add 3 sales lines, middle line amount should be 0. Direct price is set to rounding precision and Line Discount % = 100
        CreateMultipleSalesLines(VATPostingSetup, SalesHeader, InvDiscountAmount);
        LibraryVariableStorage.Enqueue(InvDiscountAmount);

        // Calculate Invoice Discount on Sales Invoice
        CalculateInvoiceDiscountOnSalesInvoice(SalesHeader);

        exit(SalesHeader."No.");
    end;

    local procedure CreateSalesOrderWithInvoiceDiscountCalculation(var SalesHeader: Record "Sales Header"; InvoiceDiscountCalculation: Option)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Invoice Discount Calculation", InvoiceDiscountCalculation);
        SalesHeader.Validate("Prices Including VAT", false);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesLineAndSetAllowInvDiscount(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; AllowInvDiscount: Boolean)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Allow Invoice Disc.", AllowInvDiscount);
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchaseInvoiceWithMultilinesInvoiceDiscount(var InvDiscountAmount: Decimal): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
    begin
        // Create Purchase Header
        LibraryPurchase.SetCalcInvDiscount(false); // "Calc. Inv. Discount" is False.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        CreatePurchaseInvoiceHeader(PurchaseHeader);
        InvDiscountAmount := LibraryRandom.RandInt(100);

        // Add 3 purchase lines, middle line amount should be 0. Direct price is set to rounding precision and Line Discount % = 100
        CreateMultiplePurchaseLines(VATPostingSetup, PurchaseHeader, InvDiscountAmount);
        LibraryVariableStorage.Enqueue(InvDiscountAmount);

        // Calculate Invoice Discount on Purchase Invoice
        CalculateInvoiceDiscountOnPurchaseInvoice(PurchaseHeader);

        exit(PurchaseHeader."No.");
    end;

    local procedure CreatePurchaseOrderWithCalculateInvoiceDiscount(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: array[2] of Record "Purchase Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        CreateVATPostingSetup(VATPostingSetup, LibraryRandom.RandInt(20));
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order,
          CreateVendorWithInvoiceDiscount(VATPostingSetup."VAT Bus. Posting Group"));
        CreatePurchaseLineAndCalculateInvoiceDiscount(
          PurchaseHeader, PurchaseLine[1], VATPostingSetup."VAT Prod. Posting Group");
        CreatePurchaseLineAndCalculateInvoiceDiscount(
          PurchaseHeader, PurchaseLine[2], VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure CreatePurchaseLineAndCalculateInvoiceDiscount(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; VATProductPostingGroupCode: Code[20])
    var
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(true, VATProductPostingGroupCode),
          LibraryRandom.RandDec(10, 2));
        PurchCalcDiscount.CalculateInvoiceDiscount(PurchaseHeader, PurchaseLine);
    end;

    local procedure CreatePurchaseOrderWithPmtDiscExclVATAndCalculateInvoiceDiscount(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchCalcDiscount: Codeunit "Purch.-Calc.Discount";
    begin
        CreateVATPostingSetup(VATPostingSetup, LibraryRandom.RandInt(20));
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order,
          CreateVendorWithInvoiceDiscount(VATPostingSetup."VAT Bus. Posting Group"));
        PurchaseHeader.Validate("Payment Discount %", LibraryRandom.RandDec(10, 2));
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(true, VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(10, 2));
        PurchCalcDiscount.CalculateIncDiscForHeader(PurchaseHeader);
    end;

    local procedure CreatePurchaseOrderWithInvoiceDiscountCalculation(var PurchHeader: Record "Purchase Header"; InvoiceDiscountCalculation: Option)
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchHeader.Validate("Invoice Discount Calculation", InvoiceDiscountCalculation);
        PurchHeader.Validate("Prices Including VAT", false);
        PurchHeader.Modify(true);
    end;

    local procedure CreatePurchLineAndSetAllowInvDiscount(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"; AllowInvDiscount: Boolean)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchHeader, PurchLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Validate("Allow Invoice Disc.", AllowInvDiscount);
        PurchLine.Modify(true);
    end;

    local procedure FindMultiVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        Assert.IsTrue(VATPostingSetup.Count >= 2, 'Precondition: Valid set of VAT Posting Setup does not exist.');
    end;

    local procedure CreateItem(AllowInvDisc: Boolean; VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        // Create an Item with Invoice Discount, Unit Price. Make Sure that amount is any number between 11 to 110.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Allow Invoice Disc.", AllowInvDisc);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Validate("Unit Price", 10 + LibraryRandom.RandInt(100));
        Item.Validate("Last Direct Cost", Item."Unit Price");
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateVendor(): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        exit(CreateVendorWithInvoiceDiscount(VATPostingSetup."VAT Bus. Posting Group"));
    end;

    local procedure CreateVendorWithInvoiceDiscount(VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, Vendor."No.", Vendor."Currency Code", 0); // Minimum Amount set 0 to ensure Invoice Discount is always enabled
        VendorInvoiceDisc.Validate("Discount %", LibraryRandom.RandInt(10));
        VendorInvoiceDisc.Modify(true);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Validate("Invoice Disc. Code", VendorInvoiceDisc.Code);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithInvoiceDiscountGenPostGroup(VATBusPostingGroup: Code[20]; GenBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, Vendor."No.", Vendor."Currency Code", 0); // Minimum Amount set 0 to ensure Invoice Discount is always enabled
        VendorInvoiceDisc.Validate("Discount %", LibraryRandom.RandInt(10));
        VendorInvoiceDisc.Modify(true);
        Vendor.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Validate("Invoice Disc. Code", VendorInvoiceDisc.Code);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorWithDiscount(): Code[20]
    var
        Vendor: Record Vendor;
        VendInvoiceDisc: Record "Vendor Invoice Disc.";
        Currency: Record Currency;
        VendorNo: Code[20];
        Decimals: Integer;
    begin
        CreateCurrency(Currency, Decimals);
        VendorNo := CreateVendor();
        Vendor.Get(VendorNo);
        Vendor.Validate("Currency Code", Currency.Code);
        Vendor.Modify(true);

        LibraryERM.CreateInvDiscForVendor(VendInvoiceDisc, VendorNo, Currency.Code, 0);
        VendInvoiceDisc.Validate("Discount %", LibraryRandom.RandDecInRange(10, 90, Decimals));
        VendInvoiceDisc.Modify(true);

        Vendor.Get(VendorNo);
        Vendor.Validate("Invoice Disc. Code", VendInvoiceDisc.Code);
        Vendor.Modify(true);

        exit(VendorNo);
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

    local procedure CreateSalesOrderWithCustomVATAndLineDiscount(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; Quantity: Decimal; UnitPrice: Decimal; LineDiscPct: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 10);
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order,
          LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase), Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("Line Discount %", LineDiscPct);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderWithLineDiscount(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; LineDiscPct: Decimal)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        ItemNo: Code[20];
    begin
        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 10);
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order,
          LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        ItemNo :=
          LibraryInventory.CreateItemNoWithPostingSetup(
            GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Line Discount %", LineDiscPct);
        SalesLine.Modify(true);
    end;

    local procedure CreateAndPostSalesInvoice(var SalesLine: Record "Sales Line"): Code[20]
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(false, VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandDec(10, 2));  // Use random value for Quantity.
        SalesLine.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));  // Use random value for Line Discount.
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesInvoiceWithFADiscount(var SalesLine: Record "Sales Line"; var PostingDate: Date; CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"Fixed Asset", CreateFixedAsset(), LibraryRandom.RandInt(10));  // Use random value for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLine.Validate("Line Discount %", LibraryRandom.RandInt(10));
        SalesLine.Modify(true);

        PostingDate := SalesHeader."Posting Date";
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateSalesOrderWithMultipleLines(var SalesHeader: Record "Sales Header")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
        i: Integer;
    begin
        VATPostingSetup.SetFilter("Sales VAT Account", '<>%1', '');
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        for i := 1 to LibraryRandom.RandIntInRange(3, 5) do
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(true, VATPostingSetup."VAT Prod. Posting Group"),
              LibraryRandom.RandIntInRange(5, 10));
    end;

    local procedure PostSalesOrderPartially(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.Validate("Qty. to Ship", Round(SalesLine.Quantity / LibraryRandom.RandIntInRange(2, 5), 1));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreatePurchOrderWithCustomVATAndLineDiscount(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; Quantity: Decimal; DirectUnitCost: Decimal; LineDiscPct: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 10);
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Order,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase), Quantity);
        PurchLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchLine.Validate("Line Discount %", LineDiscPct);
        PurchLine.Modify(true);
    end;

    local procedure CreatePurchOrderWithMultipleLines(var PurchHeader: Record "Purchase Header")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchLine: Record "Purchase Line";
        i: Integer;
    begin
        VATPostingSetup.SetFilter("Purchase VAT Account", '<>%1', '');
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Order,
          CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        for i := 1 to LibraryRandom.RandIntInRange(3, 5) do
            LibraryPurchase.CreatePurchaseLine(
              PurchLine, PurchHeader, PurchLine.Type::Item, CreateItem(true, VATPostingSetup."VAT Prod. Posting Group"),
              LibraryRandom.RandIntInRange(5, 10));
    end;

    local procedure CreatePurchOrderWithLineDiscount(var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; LineDiscPct: Decimal)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        ItemNo: Code[20];
    begin
        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 10);
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Order,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        ItemNo :=
          LibraryInventory.CreateItemNoWithPostingSetup(
            GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::Item, ItemNo, LibraryRandom.RandInt(100));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Validate("Line Discount %", LineDiscPct);
        PurchLine.Modify(true);
    end;

    local procedure CreateServOrderWithLineDiscount(var ServHeader: Record "Service Header"; var ServLine: Record "Service Line"; LineDiscPct: Decimal)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ItemNo: Code[20];
    begin
        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 10);
        LibraryService.CreateServiceHeader(
          ServHeader, ServHeader."Document Type"::Order,
          LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        ItemNo :=
          LibraryInventory.CreateItemNoWithPostingSetup(
            GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        LibraryService.CreateServiceLine(
          ServLine, ServHeader, ServLine.Type::Item, ItemNo);
        LibraryService.CreateServiceItem(ServiceItem, ServHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServHeader, ServiceItem."No.");
        ServLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServLine.Validate(Quantity, LibraryRandom.RandInt(100));
        ServLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServLine.Validate("Line Discount %", LineDiscPct);
        ServLine.Modify(true);
    end;

    local procedure PostPurchOrderPartially(var PurchHeader: Record "Purchase Header")
    var
        PurchLine: Record "Purchase Line";
    begin
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.FindFirst();
        PurchLine.Validate("Qty. to Receive", Round(PurchLine.Quantity / LibraryRandom.RandIntInRange(2, 5), 1));
        PurchLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);
    end;

    local procedure CreateFixedAsset(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
        FAPostingGroup: Record "FA Posting Group";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        FindFAPostingGroup(FAPostingGroup);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", LibraryFixedAsset.GetDefaultDeprBook());
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup.Code);
        FADepreciationBook.Validate("Acquisition Date", WorkDate());  // Take WORKDATE because value is not important.
        FADepreciationBook.Modify(true);
        exit(FixedAsset."No.")
    end;

    local procedure FindFAPostingGroup(var FAPostingGroup: Record "FA Posting Group")
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.SetFilter("Gen. Prod. Posting Group", '<>%1', '');
        LibraryERM.FindGLAccount(GLAccount);
        FAPostingGroup.SetFilter("Acq. Cost Acc. on Disposal", '<>%1', '');
        FAPostingGroup.FindFirst();
        FAPostingGroup.Validate("Acq. Cost Acc. on Disposal", GLAccount."No.");
        FAPostingGroup.Modify(true);
    end;

    local procedure GetReceivablesAccount(CustomerPostingGroupCode: Code[20]): Code[20]
    var
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CustomerPostingGroup.Get(CustomerPostingGroupCode);
        exit(CustomerPostingGroup."Receivables Account");
    end;

    local procedure GetSalesVATAmountLine(SalesHeader: Record "Sales Header"; var VATAmountLine: Record "VAT Amount Line"; UpdateType: Integer)
    var
        TempSalesLine: Record "Sales Line" temporary;
        SalesPost: Codeunit "Sales-Post";
    begin
        SalesPost.GetSalesLines(SalesHeader, TempSalesLine, UpdateType);
        TempSalesLine.CalcVATAmountLines(UpdateType, SalesHeader, TempSalesLine, VATAmountLine);
    end;

    local procedure GetPurchaseVATAmountLine(PurchaseHeader: Record "Purchase Header"; var VATAmountLine: Record "VAT Amount Line"; UpdateType: Integer)
    var
        TempPurchaseLine: Record "Purchase Line" temporary;
        PurchPost: Codeunit "Purch.-Post";
    begin
        PurchPost.GetPurchLines(PurchaseHeader, TempPurchaseLine, UpdateType);
        TempPurchaseLine.CalcVATAmountLines(UpdateType, PurchaseHeader, TempPurchaseLine, VATAmountLine);
    end;

    local procedure SalesCopyDocument(SalesHeader: Record "Sales Header"; DocumentNo: Code[20]; DocumentType: Enum "Sales Document Type From")
    var
        CopySalesDocument: Report "Copy Sales Document";
    begin
        Clear(CopySalesDocument);
        CopySalesDocument.SetSalesHeader(SalesHeader);
        CopySalesDocument.SetParameters(DocumentType, DocumentNo, true, false);
        CopySalesDocument.UseRequestPage(false);
        CopySalesDocument.Run();
    end;

    local procedure CopySalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; FromDocType: Enum "Sales Document Type From"; DocumentNo: Code[20])
    begin
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", DocumentType);
        SalesHeader.Insert(true); // Creating empty Document for Copy function.
        Commit();
        SalesCopyDocument(SalesHeader, DocumentNo, FromDocType);
    end;

    local procedure CopyPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; FromDocType: Enum "Purchase Document Type From"; DocumentNo: Code[20])
    begin
        PurchaseHeader.Init();
        PurchaseHeader.Validate("Document Type", DocumentType);
        PurchaseHeader.Insert(true); // Creating empty Document for Copy function.
        LibraryPurchase.CopyPurchaseDocument(PurchaseHeader, FromDocType, DocumentNo, true, false);
    end;

    local procedure CopyPostedSalesInvoiceWithInvoiceDiscountAmount(ToDocType: Enum "Sales Document Type"; Post: Boolean)
    var
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
        InvDiscountAmount: Decimal;
        FromDocType: Enum "Sales Document Type From";
    begin
        // Setup: Update Sales & Receivables Setup
        // Create and post a Sales Invoice with Multiple lines, set and Calculate Invoice Discount
        LibrarySales.SetCreditWarningsToNoWarnings();
        LibrarySales.SetStockoutWarning(false);
        DocumentNo := CreateSalesInvoiceWithMultilinesInvoiceDiscount(InvDiscountAmount);
        FromDocType := "Sales Document Type From"::Invoice;

        if Post then begin
            SalesHeader.Get(SalesHeader."Document Type"::Invoice, DocumentNo);
            DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
            FromDocType := "Sales Document Type From"::"Posted Invoice";
        end;

        // Exercise: New a Sales Document by Copy Document function
        CopySalesDocument(SalesHeader, ToDocType, FromDocType, DocumentNo);

        // Verify: Verify total Invoice Discount Amount is correct
        VerifySalesLineAmounts(SalesHeader, InvDiscountAmount);
    end;

    local procedure CopyPostedPurchaseInvoiceWithInvoiceDiscountAmount(ToDocType: Enum "Purchase Document Type"; Post: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
        InvDiscountAmount: Decimal;
        FromDocType: Enum "Purchase Document Type From";
    begin
        // Setup: Create Purchase Invoice with Multiple lines, set and Calculate Invoice Discount
        DocumentNo := CreatePurchaseInvoiceWithMultilinesInvoiceDiscount(InvDiscountAmount);
        FromDocType := "Purchase Document Type From"::Invoice;

        if Post then begin
            PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, DocumentNo);
            DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
            FromDocType := "Purchase Document Type From"::"Posted Invoice";
        end;

        // Exercise: New a Purchase Document by Copy Document function
        CopyPurchaseDocument(PurchaseHeader, ToDocType, FromDocType, DocumentNo);

        // Verify: Verify total Invoice Discount Amount is correct
        VerifyPurchaseLineAmounts(PurchaseHeader, InvDiscountAmount);
    end;

    local procedure VerifySalesCreditMemo(DocumentNo: Code[20]; No: Code[20]; LineDiscount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Credit Memo");
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange("No.", No);
        SalesLine.FindFirst();
        SalesLine.TestField("Line Discount %", LineDiscount);
    end;

    local procedure VerifyAmountOnSalesInvoiceAndGLAccount(DocumentNo: Code[20]; GLAccountNo: Code[20]; PostingDate: Date; Amount: Decimal)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        GLEntry: Record "G/L Entry";
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField("Amount Including VAT", Amount);

        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Posting Date", PostingDate);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, Amount);
    end;

    local procedure CreateCustomer(VATBusPostingGroupCode: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithInvoiceDiscount(VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, Customer."No.", Customer."Currency Code", 0); // Minimum Amount set 0 to ensure Invoice Discount is always enabled
        CustInvoiceDisc.Validate("Discount %", LibraryRandom.RandInt(10));
        CustInvoiceDisc.Modify(true);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Validate("Invoice Disc. Code", CustInvoiceDisc.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithInvoiceDiscountGenPostGroup(VATBusPostingGroup: Code[20]; GenBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, Customer."No.", Customer."Currency Code", 0); // Minimum Amount set 0 to ensure Invoice Discount is always enabled
        CustInvoiceDisc.Validate("Discount %", LibraryRandom.RandInt(10));
        CustInvoiceDisc.Modify(true);
        Customer.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Validate("Invoice Disc. Code", CustInvoiceDisc.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithDiscount(VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        Customer: Record Customer;
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        Currency: Record Currency;
        CustomerNo: Code[20];
        Decimals: Integer;
    begin
        CreateCurrency(Currency, Decimals);
        CustomerNo := CreateCustomer(VATPostingSetup."VAT Bus. Posting Group");
        Customer.Get(CustomerNo);
        Customer.Validate("Currency Code", Currency.Code);
        Customer.Modify(true);

        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CustomerNo, Currency.Code, 0);
        CustInvoiceDisc.Validate("Discount %", LibraryRandom.RandDecInRange(10, 90, Decimals));
        CustInvoiceDisc.Modify(true);

        Customer.Get(CustomerNo);
        Customer.Validate("Invoice Disc. Code", CustInvoiceDisc.Code);
        Customer.Modify(true);

        exit(CustomerNo);
    end;

    local procedure CreateAndModifyVendor(VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure UpdateGeneralPostingSetup(var GeneralPostingSetup: Record "General Posting Setup"; PurchaseLine: Record "Purchase Line")
    var
        GLAccount: Record "G/L Account";
    begin
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        if GeneralPostingSetup."Purch. Inv. Disc. Account" = '' then begin
            GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
            GLAccount.FindFirst();
            GeneralPostingSetup.Validate("Purch. Inv. Disc. Account", GLAccount."No.");
            GeneralPostingSetup.Modify(true);
        end;
    end;

    local procedure CreatePurchaseInvoiceHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor());
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateAndModifyVendor(VATPostingSetup."VAT Bus. Posting Group"));

        // Create Purchase Line with Random Quantity and Direct Unit Cost.
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(false, VATPostingSetup."VAT Prod. Posting Group"),
          LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATPercent: Decimal)
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(
          VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);

        VATPostingSetup.Validate("VAT %", VATPercent);
        VATPostingSetup.Modify(true);
    end;

    local procedure MockCustomerTemplate(var CustomerTemplate: Record "Customer Templ."; InvoiceDiscCode: Code[20])
    begin
        CustomerTemplate.Code := LibraryUtility.GenerateGUID();
        CustomerTemplate."Invoice Disc. Code" := InvoiceDiscCode;
        CustomerTemplate.Insert();
    end;

    local procedure UpdateInvDiscAmtOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; NewInvDiscAmount: Decimal)
    begin
        PurchaseLine.Validate("Inv. Discount Amount", NewInvDiscAmount);
        PurchaseLine.Modify(true);
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

    local procedure UpdateCurrencyRoundingPrecision(CurrencyCode: Code[20])
    var
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyCode);
        Currency.Validate("Amount Rounding Precision", 0.1);
        Currency.Modify(true);
    end;

    local procedure UpdatePricesIncludingVATOnsalesHeader(var SalesHeader: Record "Sales Header"; PricesIncludingVAT: Boolean)
    begin
        LibraryVariableStorage.Enqueue(PriceIncludingVATChangeMsg);
        SalesHeader.Validate("Prices Including VAT", PricesIncludingVAT);
        SalesHeader.Modify(true);
    end;

    local procedure UpdatePricesIncludingVATOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header"; PricesIncludingVAT: Boolean)
    begin
        LibraryVariableStorage.Enqueue(PriceIncludingVATChangeMsg);
        PurchaseHeader.Validate("Prices Including VAT", PricesIncludingVAT);
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdateAccInGenPostingSetup(GenBusPostingGroupCode: Code[20]; GenProdPostingGroupCode: Code[20])
    var
        GenPostingSetup: Record "General Posting Setup";
    begin
        // Needed for CZ
        GenPostingSetup.Get(GenBusPostingGroupCode, GenProdPostingGroupCode);
        GenPostingSetup.Validate("Sales Account", LibraryERM.CreateGLAccountNo());
        GenPostingSetup.Validate("Sales Line Disc. Account", LibraryERM.CreateGLAccountNo());
        GenPostingSetup.Validate("Purch. Account", LibraryERM.CreateGLAccountNo());
        GenPostingSetup.Validate("Purch. Line Disc. Account", LibraryERM.CreateGLAccountNo());
        GenPostingSetup.Modify(true);
    end;

    local procedure AddSalesLineWithHundredLineDisc(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        ItemNo: Code[20];
    begin
        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
        ItemNo :=
          LibraryInventory.CreateItemNoWithPostingSetup(
            GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Line Discount %", 100);
        SalesLine.Modify(true);
    end;

    local procedure AddPurchLineWithHundredLineDisc(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        ItemNo: Code[20];
    begin
        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
        ItemNo :=
          LibraryInventory.CreateItemNoWithPostingSetup(
            GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::Item, ItemNo, LibraryRandom.RandInt(100));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Validate("Line Discount %", 100);
        PurchLine.Modify(true);
    end;

    local procedure AddServLineWithHundredLineDisc(var ServLine: Record "Service Line"; ServHeader: Record "Service Header"; VATPostingSetup: Record "VAT Posting Setup")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ItemNo: Code[20];
    begin
        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
        ItemNo :=
          LibraryInventory.CreateItemNoWithPostingSetup(
            GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        LibraryService.CreateServiceLine(
          ServLine, ServHeader, ServLine.Type::Item, ItemNo);
        LibraryService.CreateServiceItem(ServiceItem, ServHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServHeader, ServiceItem."No.");
        ServLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServLine.Validate(Quantity, LibraryRandom.RandInt(100));
        ServLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServLine.Validate("Line Discount %", 100);
        ServLine.Modify(true);
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

    local procedure OpenSalesOrderStatistics(SalesHeader: Record "Sales Header"; InvDiscountAmount: Decimal)
    begin
        LibraryVariableStorage.Enqueue(InvDiscountAmount);
        Commit();
        PAGE.RunModal(PAGE::"Sales Order Statistics", SalesHeader);
    end;

    local procedure OpenPurchOrderStatistics(PurchHeader: Record "Purchase Header"; InvDiscountAmount: Decimal)
    begin
        LibraryVariableStorage.Enqueue(InvDiscountAmount);
        Commit();
        PAGE.RunModal(PAGE::"Purchase Order Statistics", PurchHeader);
    end;

    local procedure GetSalesLineInvoiced(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetFilter(Type, '<>%1', SalesLine.Type::" ");
        SalesLine.SetFilter("Quantity Invoiced", '<>%1', 0);
        SalesLine.Find('-');
        repeat
        until (SalesLine.Next() = 0) or (SalesLine.Quantity = SalesLine."Quantity Invoiced");
        Assert.AreEqual(
          SalesLine.Quantity, SalesLine."Quantity Invoiced", StrSubstNo(WrongFieldValueErr, SalesLine.FieldCaption("Quantity Invoiced")));
    end;

    local procedure GetPurchLineInvoiced(var PurchLine: Record "Purchase Line"; PurchHeader: Record "Purchase Header")
    begin
        PurchLine.SetRange("Document Type", PurchHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchHeader."No.");
        PurchLine.SetFilter(Type, '<>%1', PurchLine.Type::" ");
        PurchLine.SetFilter("Quantity Invoiced", '<>%1', 0);
        PurchLine.Find('-');
        repeat
        until (PurchLine.Next() = 0) or (PurchLine.Quantity = PurchLine."Quantity Invoiced");
        Assert.AreEqual(
          PurchLine.Quantity, PurchLine."Quantity Invoiced", StrSubstNo(WrongFieldValueErr, PurchLine.FieldCaption("Quantity Invoiced")));
    end;

    local procedure GetServInNo(OrderNo: Code[20]): Code[20]
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader.SetRange("Order No.", OrderNo);
        ServiceInvoiceHeader.FindFirst();
        exit(ServiceInvoiceHeader."No.");
    end;

    local procedure VerifyInvDiscAmtAndVATAmt(PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; VATPercent: Decimal; AllowInvDisc: Boolean)
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
        InvDiscAmount: Decimal;
        AmtIncludingVAT: Decimal;
    begin
        VendorInvoiceDisc.SetRange(Code, PurchaseLine."Buy-from Vendor No.");
        VendorInvoiceDisc.FindFirst();

        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindFirst();

        // Calculate Invoice Discount Amount and Amount Including VAT.
        if AllowInvDisc then
            InvDiscAmount := PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost" * VendorInvoiceDisc."Discount %" / 100;

        AmtIncludingVAT := (PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost" - InvDiscAmount) * (1 + VATPercent / 100);

        // Verify the Invoice Discount Amount and Amount Including VAT.
        Assert.AreNearlyEqual(
          PurchaseLine."Inv. Discount Amount", InvDiscAmount, LibraryERM.GetInvoiceRoundingPrecisionLCY(),
          StrSubstNo(AmtMustBeErr, PurchaseLine.FieldCaption("Inv. Discount Amount"), InvDiscAmount, PurchaseLine.TableCaption()));

        Assert.AreNearlyEqual(
          PurchaseLine."Amount Including VAT", AmtIncludingVAT, LibraryERM.GetInvoiceRoundingPrecisionLCY(),
          StrSubstNo(AmtMustBeErr, PurchaseLine.FieldCaption("Amount Including VAT"), AmtIncludingVAT, PurchaseLine.TableCaption()));
    end;

    local procedure VerifyGLEntryForPostedPurchInv(Amount: Decimal; VATAmount: Decimal; DocumentNo: Code[20]; AccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", AccountNo);
        GLEntry.FindFirst();

        Assert.AreNearlyEqual(
          GLEntry.Amount, Amount, LibraryERM.GetInvoiceRoundingPrecisionLCY(),
          StrSubstNo(AmtMustBeErr, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption()));

        Assert.AreNearlyEqual(
          GLEntry."VAT Amount", VATAmount, LibraryERM.GetInvoiceRoundingPrecisionLCY(),
          StrSubstNo(AmtMustBeErr, GLEntry.FieldCaption("VAT Amount"), Amount, GLEntry.TableCaption()));
    end;

    local procedure UpdateDirectUnitCostOnPurchase(PurchaseLine: Record "Purchase Line"): Decimal
    var
        PurchaseLine2: Record "Purchase Line";
    begin
        PurchaseLine2.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        PurchaseLine2.Validate("Direct Unit Cost", PurchaseLine."Direct Unit Cost" + LibraryRandom.RandInt(10));
        PurchaseLine2.Modify(true);
        exit(PurchaseLine2."Line Amount");
    end;

    local procedure VerifyValuesOnValueEntry(DocumentNo: Code[20]; CostAmountExpected: Decimal; CostAmountActual: Decimal)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Purchase);
        ValueEntry.FindFirst();
        ValueEntry.TestField("Cost Amount (Expected)", CostAmountExpected);
        ValueEntry.TestField("Cost Amount (Actual)", CostAmountActual);
    end;

    local procedure VerifySalesLineAmounts(SalesHeader: Record "Sales Header"; InvDiscountAmount: Decimal)
    var
        SalesLine: Record "Sales Line";
        TotalInvDiscountAmount: Decimal;
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                VerifySalesLineAmountsAgainstDiscounts(SalesLine);
                TotalInvDiscountAmount += SalesLine."Inv. Discount Amount";
            until SalesLine.Next() = 0;

        Assert.AreEqual(
          InvDiscountAmount,
          TotalInvDiscountAmount,
          StrSubstNo(TotalInvDiscountAmountErr, SalesLine.TableCaption(), InvDiscountAmount));
    end;

    local procedure VerifyPurchaseLineAmounts(PurchaseHeader: Record "Purchase Header"; InvDiscountAmount: Decimal)
    var
        PurchLine: Record "Purchase Line";
        TotalInvDiscountAmount: Decimal;
    begin
        PurchLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchLine.SetRange("Document No.", PurchaseHeader."No.");
        if PurchLine.FindSet() then
            repeat
                VerifyPurchaseLineAmountsAgainstDiscounts(PurchLine);
                TotalInvDiscountAmount += PurchLine."Inv. Discount Amount";
            until PurchLine.Next() = 0;

        Assert.AreEqual(
          InvDiscountAmount,
          TotalInvDiscountAmount,
          StrSubstNo(TotalInvDiscountAmountErr, PurchLine.TableCaption(), InvDiscountAmount));
    end;

    local procedure VerifyAmountAndAmountIncludingVATOnSalesLine(SalesLine: Record "Sales Line")
    begin
        SalesLine.Find(); // Update Price Including VAT has changed amount on SalesLine
        Assert.AreNearlyEqual(
          (SalesLine."Line Amount" - SalesLine."Inv. Discount Amount") / (1 + SalesLine."VAT %" / 100),
          SalesLine.Amount, LibraryERM.GetAmountRoundingPrecision(), IncorrectAmtErr);
        Assert.AreNearlyEqual(
          SalesLine."Line Amount" - SalesLine."Inv. Discount Amount", SalesLine."Amount Including VAT",
          LibraryERM.GetAmountRoundingPrecision(), AmtInclVATErr);
    end;

    local procedure VerifyAmountAndAmountIncludingVATOnPurchaseLine(PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.Find(); // Update Price Including VAT has changed amount on PurchaseLine
        Assert.AreNearlyEqual(
          (PurchaseLine."Line Amount" - PurchaseLine."Inv. Discount Amount") / (1 + PurchaseLine."VAT %" / 100),
          PurchaseLine.Amount, LibraryERM.GetAmountRoundingPrecision(), IncorrectAmtErr);
        Assert.AreNearlyEqual(
          PurchaseLine."Line Amount" - PurchaseLine."Inv. Discount Amount", PurchaseLine."Amount Including VAT",
          LibraryERM.GetAmountRoundingPrecision(), AmtInclVATErr);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    var
        DequeueVariable: Variant;
        LocalMessage: Text[1024];
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        LocalMessage := DequeueVariable;
        Assert.IsTrue(StrPos(Question, LocalMessage) > 0, Question);
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsPageHandler(var SalesOrderStatisticsTestPage: TestPage "Sales Order Statistics")
    var
        VarValue: Variant;
        InvDiscountAmount: Decimal;
    begin
        LibraryVariableStorage.Dequeue(VarValue);
        InvDiscountAmount := VarValue;

        Assert.AreEqual(true, InvDiscountAmount > 0, InvoiceDiscountAmountErr);

        // to let page know that value was changed.
        // if page will have the same value as InvDiscountAmount further setting will not affect
        SalesOrderStatisticsTestPage.InvDiscountAmount_General.SetValue(0);
        SalesOrderStatisticsTestPage.InvDiscountAmount_General.SetValue(InvDiscountAmount);
        SalesOrderStatisticsTestPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsPageHandler(var PurchaseOrderStatisticsTestPage: TestPage "Purchase Order Statistics")
    var
        VarValue: Variant;
        InvDiscountAmount: Decimal;
    begin
        LibraryVariableStorage.Dequeue(VarValue);
        InvDiscountAmount := VarValue;

        Assert.AreEqual(true, InvDiscountAmount > 0, InvoiceDiscountAmountErr);

        // to let page know that value was changed.
        // if page will have the same value as InvDiscountAmount further setting will not affect
        PurchaseOrderStatisticsTestPage.InvDiscountAmount_General.SetValue(0);
        PurchaseOrderStatisticsTestPage.InvDiscountAmount_General.SetValue(InvDiscountAmount);
        PurchaseOrderStatisticsTestPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderWithCustomerDiscountStatisticsPageHandler(var SalesOrderStatisticsTestPage: TestPage "Sales Order Statistics")
    begin
        SalesOrderStatisticsTestPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderWithVendorDiscountStatisticsPageHandler(var PurchaseOrderStatisticsTestPage: TestPage "Purchase Order Statistics")
    begin
        PurchaseOrderStatisticsTestPage.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure UpdateInvDiscConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, UpdInvDiscQst) > 0, Question);
        Reply := false;
    end;

    local procedure VerifySalesLineAmountsAgainstDiscounts(SalesLine: Record "Sales Line")
    begin
        Assert.IsFalse(
            (SalesLine."Line Amount" >= 0) and (SalesLine."Inv. Discount Amount" < 0),
            StrSubstNo(NegativeInvDiscountErr, SalesLine.TableCaption));

        Assert.IsTrue(
          Abs(SalesLine."Line Amount" - SalesLine."Line Discount Amount") >= Abs(SalesLine.Amount),
          StrSubstNo(WrongLineAmountErr, SalesLine.TableCaption));
    end;

    local procedure VerifyPurchaseLineAmountsAgainstDiscounts(PurchaseLine: Record "Purchase Line")
    begin
        Assert.IsFalse(
            (PurchaseLine."Line Amount" >= 0) and (PurchaseLine."Inv. Discount Amount" < 0),
            StrSubstNo(NegativeInvDiscountErr, PurchaseLine.TableCaption));

        Assert.IsTrue(
          Abs(PurchaseLine."Line Amount" - PurchaseLine."Line Discount Amount") >= Abs(PurchaseLine.Amount),
          StrSubstNo(WrongLineAmountErr, PurchaseLine.TableCaption));
    end;

    local procedure VerifySalesOrderInvoiceDiscountAmount(var SalesHeader: Record "Sales Header"; InvoiceDiscountAmount: Decimal)
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
    begin
        GetSalesVATAmountLine(SalesHeader, TempVATAmountLine, 0); // 0 means General update
        TempVATAmountLine.SetRange(Positive, true);
        TempVATAmountLine.FindFirst();
        Assert.AreEqual(InvoiceDiscountAmount, TempVATAmountLine."Invoice Discount Amount", ChangedInvDiscountAmountErr);
    end;

    local procedure VerifyPurchaseOrderInvoiceDiscountAmount(var PurchaseHeader: Record "Purchase Header"; InvoiceDiscountAmount: Decimal)
    var
        TempVATAmountLine: Record "VAT Amount Line" temporary;
    begin
        GetPurchaseVATAmountLine(PurchaseHeader, TempVATAmountLine, 0); // 0 means General update
        TempVATAmountLine.SetRange(Positive, true);
        TempVATAmountLine.FindFirst();
        Assert.AreEqual(InvoiceDiscountAmount, TempVATAmountLine."Invoice Discount Amount", ChangedInvDiscountAmountErr);
    end;

    local procedure VerifyTotalAmountInGLEntry(GLAccNo: Code[20]; ExpectedLineDiscAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, ExpectedLineDiscAmount);
    end;

    local procedure VerifyAmountOfPairedGLEntries(DocNo: Code[20]; AccNo: Code[20]; FirstExpectedAmt: Decimal; SecondExpectedAmt: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetRange("G/L Account No.", AccNo);
        GLEntry.FindSet();
        GLEntry.TestField(Amount, FirstExpectedAmt);
        GLEntry.Next();
        GLEntry.TestField(Amount, SecondExpectedAmt)
    end;

    local procedure VerifyGLEntry(DocNo: Code[20]; GLAccNo: Code[20]; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, ExpectedAmount);
    end;

    local procedure CreateItemWithTracking(AllowInvDisc: Boolean; VATProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        // Create Item Tracking Code with Lot Specific Tracking
        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
        ItemTrackingCode.Validate("Lot Specific Tracking", true);
        ItemTrackingCode.Modify(true);

        // Create Item with Item Tracking Code
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);
        Item.Validate("Allow Invoice Disc.", AllowInvDisc);
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Validate("Unit Price", 10 + LibraryRandom.RandInt(100));
        Item.Validate("Last Direct Cost", Item."Unit Price");
        Item.Modify(true);

        exit(Item."No.");
    end;

    [SendNotificationHandler(true)]
    [Scope('OnPrem')]
    procedure VerifyNoNotificationsAreSend(var TheNotification: Notification): Boolean
    begin
        if TheNotification.Message = MissingDiscountAccountMsg then
            Assert.Fail('No notification should be thrown.');
    end;

#if not CLEAN27
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ServiceOrderStatisticsHandler(var ServiceOrderStatistics: TestPage "Service Order Statistics")
    begin
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure ServiceOrderStatisticsHandlerNM(var ServiceOrderStatistics: TestPage "Service Order Statistics")
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            ItemTrackingMode::"Assign Lot No.":
                ItemTrackingLines."Assign Lot No.".Invoke();
            ItemTrackingMode::"Select Entries":
                ItemTrackingLines."Select Entries".Invoke();
        end;
        ItemTrackingLines.OK().Invoke();
    end;
}
