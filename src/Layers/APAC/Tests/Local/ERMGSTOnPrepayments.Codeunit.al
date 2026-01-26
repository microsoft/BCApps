codeunit 141026 "ERM GST On Prepayments"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [GST] [Prepayment]
    end;

    var
        Assert: Codeunit Assert;
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        AmountErr: Label '%1 must be %2 in %3.';
        NotEqualToZeroTxt: Label '<>%1.';
        PurchaseLineAmountCap: Label 'Purchase_Line___Line_Amount_';
        PurchaseLinePrepmtAmountCap: Label 'Purchase_Line___Prepmt__Line_Amount_';
        TotalAUDIncVATCap: Label 'Prepayment_Inv__Line_Buffer__Amount___VATAmount';
        VATIdentifierCap: Label 'VATAmountLine__VAT_Identifier_';
        VATPctCap: Label 'VATAmountLine__VAT___';
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtSalesInvWithPrepmtPctDefinedOnCustomer()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] verify G/L Entries after posting General Journal Line applied to Sales Prepmt. Invoice when Prepayment% is defined on Customer.

        // [GIVEN] Create Sales Order, post Prepayment Invoice and apply Payment. Post Sales Order and create Payment.
        Initialize();
        GeneralLedgerSetup.Get();
        CreateGeneralPostingSetup(GeneralPostingSetup);
        PostSalesPrepaymentInvoiceAndApplyPayment(
          SalesLine, SalesLine.Type::Item, CreateCustomer(
            '', GeneralPostingSetup."Gen. Bus. Posting Group", LibraryRandom.RandDec(20, 2)),
          CreateItem(GeneralPostingSetup."Gen. Prod. Posting Group"), LibraryRandom.RandDec(20, 2));  // Using blank value for CustomerPriceGroup and random value for Prepayment%.
        PostSalesOrderAndCreatePayment(GenJournalLine, SalesLine, -CalculateNonPrepaymentSalesLineAmount(SalesLine));

        // Exercise,Verify & Tear Down.
        PostGeneralJournalLineAndVerifyGLEntries(
          GenJournalLine, SalesLine."Sell-to Customer No.", CalculateNonPrepaymentSalesLineAmount(SalesLine),
          GeneralLedgerSetup."Full GST on Prepayment", GeneralLedgerSetup."Adjust for Payment Disc.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtSalesInvWithSalesTypeAsCustomer()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesPrepaymentPct: Record "Sales Prepayment %";
        CustomerNo: Code[20];
    begin
        // [SCENARIO] verify G/L Entries after posting General Journal Line applied to Sales Prepmt. Invoice when Prepayment% is defined on Item with Sales Type as Customer.

        // [GIVEN] Create Sales Prepayment Percentage. Post Prepayment Invoice and apply Payment. Post Sales Order and create Payment.
        Initialize();
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CustomerNo := CreateCustomer('', GeneralPostingSetup."Gen. Bus. Posting Group", 0);  // Using blank value for Customer Price Group and 0 for Prepayment%.
        SalesPrepaymentInvoiceWithSalesType(
          CustomerNo, CustomerNo, CreateItem(GeneralPostingSetup."Gen. Prod. Posting Group"), SalesPrepaymentPct."Sales Type"::Customer);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtSalesInvWithSalesTypeAsAllCustomers()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesPrepaymentPct: Record "Sales Prepayment %";
    begin
        // [SCENARIO] verify G/L Entries after posting General Journal Line applied to Sales Prepmt. Invoice when Prepayment% is defined on Item with Sales Type as All Customers.

        // [GIVEN] Create Sales Prepayment Percentage. Post Prepayment Invoice and apply Payment. Post Sales Order and create Payment.
        Initialize();
        CreateGeneralPostingSetup(GeneralPostingSetup);
        SalesPrepaymentInvoiceWithSalesType(
          CreateCustomer('', GeneralPostingSetup."Gen. Bus. Posting Group", 0), '',
          CreateItem(GeneralPostingSetup."Gen. Prod. Posting Group"), SalesPrepaymentPct."Sales Type"::"All Customers"); // Using blank value for Customer Price Group,Sales Code and 0 for Prepayment%.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepmtSalesInvWithSalesTypeAsCustomerPriceGroup()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesPrepaymentPct: Record "Sales Prepayment %";
        CustomerPriceGroupCode: Code[10];
    begin
        // [SCENARIO] verify G/L Entries after posting General Journal Line applied to Sales Prepmt. Invoice when Prepayment% is defined on Item with Sales Type as Customer Price Group.

        // [GIVEN] Create Sales Prepayment Percentage. Post Prepayment Invoice and apply Payment. Post Sales Order and create Payment.
        Initialize();
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CustomerPriceGroupCode := CreateCustomerPriceGroup();
        SalesPrepaymentInvoiceWithSalesType(
          CreateCustomer(CustomerPriceGroupCode, GeneralPostingSetup."Gen. Bus. Posting Group", 0), CustomerPriceGroupCode,
          CreateItem(GeneralPostingSetup."Gen. Prod. Posting Group"), SalesPrepaymentPct."Sales Type"::"Customer Price Group");  // Using 0 for Prepayment%.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentInvoiceWithItemPrepaymentPct()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseLine: Record "Purchase Line";
        PrePaymentPct: Decimal;
        VendorNo: Code[20];
    begin
        // [SCENARIO] GL Entries in case of Prepayment % is defined on the Purchase menu button on the Item.

        // [GIVEN] Create General Posting Setup, Prepayment percent as Random and Vendor.
        Initialize();
        CreateGeneralPostingSetup(GeneralPostingSetup);
        PrePaymentPct := LibraryRandom.RandDec(10, 2);
        VendorNo := CreateVendor(GeneralPostingSetup."Gen. Bus. Posting Group", 0);  // Using 0 for Prepayment Percent.
        PrepaymentInvoiceWithDiffSourceOfPrepaymentPct(
          VendorNo, PurchaseLine.Type::Item, CreatePurchasePrepaymentPct(
            GeneralPostingSetup."Gen. Prod. Posting Group", VendorNo, PrePaymentPct), PrePaymentPct, 0);  // Using 0 for Line Discount %.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentInvoiceWithVendorPrepaymentPct()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseLine: Record "Purchase Line";
        PrePaymentPct: Decimal;
        VendorNo: Code[20];
    begin
        // [SCENARIO] GL Entries in case of Prepayment % is defined on the Vendor.

        // [GIVEN] Create General Posting Setup, Prepayment percent as Random and Vendor.
        Initialize();
        CreateGeneralPostingSetup(GeneralPostingSetup);
        PrePaymentPct := LibraryRandom.RandDec(10, 2);
        VendorNo := CreateVendor(GeneralPostingSetup."Gen. Bus. Posting Group", PrePaymentPct);
        PrepaymentInvoiceWithDiffSourceOfPrepaymentPct(
          VendorNo, PurchaseLine.Type::Item, CreatePurchasePrepaymentPct(
            GeneralPostingSetup."Gen. Prod. Posting Group", VendorNo, 0), PrePaymentPct, 0);  // Using 0 for Prepayment and Line Discount Percent.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentInvoiceWithPurchHeaderPrepaymentPct()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
    begin
        // [SCENARIO] GL Entries in case of Prepayment % is defined on the Purchase Header.

        // [GIVEN] Create General Posting Setup and Vendor.
        Initialize();
        CreateGeneralPostingSetup(GeneralPostingSetup);
        VendorNo := CreateVendor(GeneralPostingSetup."Gen. Bus. Posting Group", 0);  // Using 0 for Prepayment Percent.
        PrepaymentInvoiceWithDiffSourceOfPrepaymentPct(
          VendorNo, PurchaseLine.Type::Item, CreatePurchasePrepaymentPct(
            GeneralPostingSetup."Gen. Prod. Posting Group", VendorNo, 0), LibraryRandom.RandDec(10, 2), 0);  // Using 0 and Random for Prepayment, Line Discount Percent.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentInvoiceWithGLAccount()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
    begin
        // [SCENARIO] GL Entries in case of Prepayment % is defined with Type GL Account on the Purchase Line.

        // [GIVEN] Create General Posting Setup and Vendor.
        Initialize();
        CreateGeneralPostingSetup(GeneralPostingSetup);
        VendorNo := CreateVendor(GeneralPostingSetup."Gen. Bus. Posting Group", 0);  // Using 0 for Prepayment Percent.
        PrepaymentInvoiceWithDiffSourceOfPrepaymentPct(
          VendorNo, PurchaseLine.Type::"G/L Account", CreateGLAccount(
            GeneralPostingSetup."Gen. Prod. Posting Group"), LibraryRandom.RandDec(10, 2), 0);  // Using Random for Prepayment Percent and 0 for Line Discount %.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentInvoiceWithFixedAsset()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
    begin
        // [SCENARIO] GL Entries in case of Prepayment % is defined with Type Fixed Asset on the Purchase Line.

        // [GIVEN] Create General Posting Setup and Vendor.
        Initialize();
        CreateGeneralPostingSetup(GeneralPostingSetup);
        VendorNo := CreateVendor(GeneralPostingSetup."Gen. Bus. Posting Group", 0);  // Using 0 for Prepayment Percent.
        PrepaymentInvoiceWithDiffSourceOfPrepaymentPct(
          VendorNo, PurchaseLine.Type::"Fixed Asset", CreateFixedAsset(
            GeneralPostingSetup."Gen. Prod. Posting Group"), LibraryRandom.RandDec(10, 2), 0);  // Using Random for Prepayment Percent and 0 for Line Discount %.
    end;

    [Test]
    [HandlerFunctions('PurchasePrepmtDocTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchasePrepaymentDocumentTestReport()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO] Purchase Prepayment Doc. Test Report.

        // [GIVEN] Create Purchase Document, post Prepayment Invoice, Post Payment General with Prepayment Amount and Application with Prepayment Invoice.
        Initialize();
        GeneralLedgerSetup.Get();
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreatePurchaseOrder(
          PurchaseHeader, CreateVendor(
            GeneralPostingSetup."Gen. Bus. Posting Group", 0), PurchaseLine.Type::Item, CreateItem(
            GeneralPostingSetup."Gen. Prod. Posting Group"), LibraryRandom.RandDec(10, 2));  // Using 0 and Random for Prepayment Percent.
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");  // Enqueue value for PurchasePrepmtDocTestRequestPageHandler.
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.");
        Commit();  // Required for Run Report.

        // Exercise.
        REPORT.Run(REPORT::"Purchase Prepmt. Doc. - Test");

        // [THEN] Verify Purchase Prepayment Doc. Test Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(PurchaseLineAmountCap, PurchaseLine."Line Amount");
        LibraryReportDataset.AssertElementWithValueExists(PurchaseLinePrepmtAmountCap, PurchaseLine."Prepmt. Line Amount");
        LibraryReportDataset.AssertElementWithValueExists(VATIdentifierCap, PurchaseLine."VAT Identifier");
        LibraryReportDataset.AssertElementWithValueExists(VATPctCap, PurchaseLine."VAT %");
        LibraryReportDataset.AssertElementWithValueExists(
          TotalAUDIncVATCap, PurchaseLine."Prepmt. Line Amount" + (PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100));

        // Tear Down.
        UpdateGeneralLedgerSetup(GeneralLedgerSetup."Full GST on Prepayment", GeneralLedgerSetup."Adjust for Payment Disc.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentSalesInvoiceWithPaymentDiscount()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] verify G/L entries after posting General Journal line applied to Sales Prepayment Invoice with Payment Discount.

        // [GIVEN] Create and Post Sales Prepayment Invoice with Payment Discount and apply Payment. Post Sales Order and Create Payment.
        Initialize();
        GeneralLedgerSetup.Get();
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateSalesOrder(
          SalesLine, CreateCustomer('', GeneralPostingSetup."Gen. Bus. Posting Group", 0), SalesLine.Type::Item,
          CreateItem(GeneralPostingSetup."Gen. Prod. Posting Group"), LibraryRandom.RandDec(20, 2));  // Blank value used for Customer Price Group, Value 0 used for Prepayment% on Customer and Random value used for Prepayment% on Sales Order.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        UpdatePaymentTermsCodeOnSalesHeader(SalesHeader);
        PostPaymentAfterSalesPrepaymentInvoice(SalesHeader);
        PostSalesOrderAndCreatePayment(GenJournalLine, SalesLine, -CalculateNonPrepaymentSalesLineAmount(SalesLine));

        // Exercise,Verify & Tear Down.
        PostGeneralJournalLineAndVerifyGLEntries(
          GenJournalLine, SalesLine."Sell-to Customer No.", CalculateNonPrepaymentSalesLineAmount(SalesLine),
          GeneralLedgerSetup."Full GST on Prepayment", GeneralLedgerSetup."Adjust for Payment Disc.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentSalesInvoiceWithGLAccount()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] verify G/L entries after posting General Journal line applied to Sales Prepayment Invoice with G/L Account.

        // [GIVEN] Post Sales Prepayment Invoice and apply Payment. Post Sales Order and Create Payment.
        Initialize();
        CreateGeneralPostingSetup(GeneralPostingSetup);
        PostPaymentAppliedToPrepaymentSalesInvoice(
          GeneralPostingSetup, SalesLine.Type::"G/L Account", CreateGLAccount(GeneralPostingSetup."Gen. Prod. Posting Group"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentSalesInvoiceWithItem()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] verify G/L entries after posting General Journal line applied to Sales Prepayment Invoice with Item.

        // [GIVEN] Post Sales Prepayment Invoice and apply Payment. Post Sales Order and Create Payment.
        Initialize();
        CreateGeneralPostingSetup(GeneralPostingSetup);
        PostPaymentAppliedToPrepaymentSalesInvoice(
          GeneralPostingSetup, SalesLine.Type::Item, CreateItem(GeneralPostingSetup."Gen. Prod. Posting Group"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentSalesInvoiceWithFixedAsset()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        FixedAssetNo: Code[20];
    begin
        // [SCENARIO] verify G/L entries after posting General Journal line applied to Sales Prepayment Invoice with Fixed Asset.

        // [GIVEN] Create and post Purchase Order for Fixed Asset. Post Sales Prepayment Invoice and apply Payment. Post Sales Order and Create Payment.
        Initialize();
        CreateGeneralPostingSetup(GeneralPostingSetup);
        FixedAssetNo := CreateFixedAsset(GeneralPostingSetup."Gen. Prod. Posting Group");
        CreatePurchaseOrder(
          PurchaseHeader, CreateVendor(GeneralPostingSetup."Gen. Bus. Posting Group", 0), PurchaseLine.Type::"Fixed Asset", FixedAssetNo, 0);  // Using 0 for Prepayment Percent.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.
        PostPaymentAppliedToPrepaymentSalesInvoice(GeneralPostingSetup, SalesLine.Type::"Fixed Asset", FixedAssetNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentSalesInvoiceWithMultipleLine()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        // [SCENARIO] verify G/L entries after posting General Journal line applied to Sales Prepayment Invoice with multiple lines and different Prepayment %.

        // [GIVEN] Create and Post multiple line Sales Prepayment Invoice and apply Payment. Post Sales Order and Create Payment.
        Initialize();
        GeneralLedgerSetup.Get();
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateSalesOrder(
          SalesLine, CreateCustomer('', GeneralPostingSetup."Gen. Bus. Posting Group", 0), SalesLine.Type::Item,
          CreateItem(GeneralPostingSetup."Gen. Prod. Posting Group"), LibraryRandom.RandDec(20, 2));  // Blank value used for Customer Price Group, Value 0 used for Prepayment% on Customer and Random value used for Prepayment% on Sales Order.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        CreateSalesLine(
          SalesLine2, SalesHeader, SalesLine.Type::Item, CreateItem(GeneralPostingSetup."Gen. Prod. Posting Group"),
          SalesLine."Prepayment %" + LibraryRandom.RandDec(20, 2));  // Adding Random value for different Prepayment %.
        PostPaymentAfterSalesPrepaymentInvoice(SalesHeader);
        PostSalesOrderAndCreatePayment(
          GenJournalLine, SalesLine,
          -(CalculateNonPrepaymentSalesLineAmount(SalesLine) + CalculateNonPrepaymentSalesLineAmount(SalesLine2)));

        // Exercise,Verify & Tear Down.
        PostGeneralJournalLineAndVerifyGLEntries(
          GenJournalLine, SalesLine."Sell-to Customer No.",
          CalculateNonPrepaymentSalesLineAmount(SalesLine) + CalculateNonPrepaymentSalesLineAmount(SalesLine2),
          GeneralLedgerSetup."Full GST on Prepayment", GeneralLedgerSetup."Adjust for Payment Disc.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentSalesInvoiceWithUpdatedQuantity()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] verify G/L entries after posting General Journal line applied to Sales Prepayment Invoice with Updated Quantity on Sales Line.

        // [GIVEN] Create and Post Sales Prepayment Invoice. Reopen Sales Order to update Quantity on Sales Line and post Prepayment Invoice. Post Sales Order and Create Payment.
        Initialize();
        GeneralLedgerSetup.Get();
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateSalesOrder(
          SalesLine, CreateCustomer('', GeneralPostingSetup."Gen. Bus. Posting Group", 0), SalesLine.Type::Item,
          CreateItem(GeneralPostingSetup."Gen. Prod. Posting Group"), LibraryRandom.RandDec(20, 2));  // Blank value used for Customer Price Group, Value 0 used for Prepayment% on Customer and Random value used for Prepayment% on Sales Order.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        LibrarySales.ReopenSalesDocument(SalesHeader);
        SalesLine.Validate(Quantity, SalesLine.Quantity + LibraryRandom.RandDec(10, 2));  // Greater Quantity required for updation.
        SalesLine.Modify(true);
        PostPaymentAfterSalesPrepaymentInvoice(SalesHeader);
        PostSalesOrderAndCreatePayment(GenJournalLine, SalesLine, -CalculateNonPrepaymentSalesLineAmount(SalesLine));

        // Exercise,Verify & Tear Down.
        PostGeneralJournalLineAndVerifyGLEntries(
          GenJournalLine, SalesLine."Sell-to Customer No.", CalculateNonPrepaymentSalesLineAmount(SalesLine),
          GeneralLedgerSetup."Full GST on Prepayment", GeneralLedgerSetup."Adjust for Payment Disc.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentSalesInvoiceWithoutPrepmtPercentError()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] verify error on posting Prepayment Sales Invoice without Prepayment %.

        // [GIVEN] Create General Posting Setup and Sales Order.
        Initialize();
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateSalesOrder(
          SalesLine, CreateCustomer('', GeneralPostingSetup."Gen. Bus. Posting Group", 0), SalesLine.Type::Item,
          CreateItem(GeneralPostingSetup."Gen. Prod. Posting Group"), 0);  // Blank value used for Customer Posting Group and 0 used for Prepayment%.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise.
        asserterror LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [THEN] Error
        Assert.ExpectedError(DocumentErrorsMgt.GetNothingToPostErrorMsg());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithSecurityDeposit()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] verify G/L entries after posting General Journal line applied to Sales Invoice with Security Deposit.

        // [GIVEN] Create and Post General Journal line. Create and post Sales Order and create Payment.
        Initialize();
        GeneralLedgerSetup.Get();
        CreateGeneralPostingSetup(GeneralPostingSetup);
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGeneralJournalLine(
          GenJournalLine, WorkDate(), GenJournalLine."Account Type"::"G/L Account", GLAccount."No.", '', -LibraryRandom.RandDec(100, 2));  // Blank used for Applies to Doc No. and Random value used for Amount.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateSalesOrder(
          SalesLine, CreateCustomer('', GeneralPostingSetup."Gen. Bus. Posting Group", 0), SalesLine.Type::Item,
          CreateItem(GeneralPostingSetup."Gen. Prod. Posting Group"), 0);  // Blank value used for Customer Posting Group and 0 used for Prepayment%.
        PostSalesOrderAndCreatePayment(GenJournalLine, SalesLine, -SalesLine."Amount Including VAT");

        // Exercise,Verify & Tear Down.
        PostGeneralJournalLineAndVerifyGLEntries(
          GenJournalLine, SalesLine."Sell-to Customer No.", SalesLine."Amount Including VAT",
          GeneralLedgerSetup."Full GST on Prepayment", GeneralLedgerSetup."Adjust for Payment Disc.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithUpdatedSalesLineAfterShipment()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        // [SCENARIO] verify G/L entries after posting General Journal line applied to Sales Invoice with updated Sales Line after posting Shipment.

        // [GIVEN] Create and post Sales Order Shipment. Reopen Sales Order and create new line on Sales Order. Post Sales Order and create Payment.
        Initialize();
        GeneralLedgerSetup.Get();
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateSalesOrder(
          SalesLine, CreateCustomer('', GeneralPostingSetup."Gen. Bus. Posting Group", 0), SalesLine.Type::Item,
          CreateItem(GeneralPostingSetup."Gen. Prod. Posting Group"), 0);  // Blank value used for Customer Posting Group and 0 used for Prepayment%.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Post as Ship.
        LibrarySales.ReopenSalesDocument(SalesHeader);
        CreateSalesLine(SalesLine2, SalesHeader, SalesLine.Type::Item, SalesLine."No.", 0);  // Value 0 used for Prepayment %.
        PostSalesOrderAndCreatePayment(GenJournalLine, SalesLine, -(SalesLine."Amount Including VAT" + SalesLine2."Amount Including VAT"));

        // Exercise,Verify & Tear Down.
        PostGeneralJournalLineAndVerifyGLEntries(
          GenJournalLine, SalesLine."Sell-to Customer No.", SalesLine."Amount Including VAT" + SalesLine2."Amount Including VAT",
          GeneralLedgerSetup."Full GST on Prepayment", GeneralLedgerSetup."Adjust for Payment Disc.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedSalesInvoiceStatisticsWithPrepayment()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
    begin
        // [SCENARIO] verify VAT Amount line after posting General Journal line applied to Sales Prepayment Invoice.

        // [GIVEN] Post Sales Prepayment Invoice and apply Payment. Post Sales Order and Create Payment.
        Initialize();
        GeneralLedgerSetup.Get();
        CreateGeneralPostingSetup(GeneralPostingSetup);
        PostSalesPrepaymentInvoiceAndApplyPayment(
          SalesLine, SalesLine.Type::Item, CreateCustomer('', GeneralPostingSetup."Gen. Bus. Posting Group", 0),
          CreateItem(GeneralPostingSetup."Gen. Prod. Posting Group"), LibraryRandom.RandDec(10, 2));  // Blank value used for Customer Price Group, 0 used for Prepayment% on Customer and Random value used for Prepayment% on Sales Order.
        PostSalesOrderAndCreatePayment(GenJournalLine, SalesLine, -CalculateNonPrepaymentSalesLineAmount(SalesLine));

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] VAT Base and VAT Amount on VAT Amount Line.
        SalesInvoiceHeader.Get(GenJournalLine."Applies-to Doc. No.");
        SalesInvoiceLine.CalcVATAmountLines(SalesInvoiceHeader, VATAmountLine);
        Assert.AreNearlyEqual(
          -SalesLine."Line Amount" * SalesLine."VAT %" / 100, VATAmountLine."VAT Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(
            AmountErr, VATAmountLine.FieldCaption("VAT Amount"), -SalesLine."Line Amount" * SalesLine."VAT %" / 100,
            VATAmountLine.TableCaption()));
        Assert.AreNearlyEqual(
          -SalesLine."Line Amount", VATAmountLine."VAT Base", LibraryERM.GetAmountRoundingPrecision(), StrSubstNo(
            AmountErr, VATAmountLine.FieldCaption("VAT Amount"), -SalesLine."Line Amount", VATAmountLine.TableCaption()));

        // Tear Down.
        UpdateGeneralLedgerSetup(GeneralLedgerSetup."Full GST on Prepayment", GeneralLedgerSetup."Adjust for Payment Disc.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentSalesInvoiceWithInvoiceDiscount()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] verify G/L Entries after posting General Journal Line applied to Sales Prepayment Invoice with Invoice Discount.

        // [GIVEN] Create and Post Sales Prepayment Invoice with Invoice Discount and apply Payment. Post Sales Order and Create Payment.
        Initialize();
        GeneralLedgerSetup.Get();
        UpdateCalcInvDiscountOnSalesReceivablesSetup(true);  // Using TRUE for Calc.Inv.Discount
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateSalesOrder(
          SalesLine, CreateCustomerInvoiceDiscount(GeneralPostingSetup."Gen. Bus. Posting Group"), SalesLine.Type::Item,
          CreateItem(GeneralPostingSetup."Gen. Prod. Posting Group"), LibraryRandom.RandDec(20, 2));  // Random value used for Prepayment%.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        SalesHeader.CalcInvDiscForHeader();
        PostPaymentAfterSalesPrepaymentInvoice(SalesHeader);
        PostSalesOrderAndCreatePayment(GenJournalLine, SalesLine, -CalculateNonPrepaymentSalesLineAmount(SalesLine));

        // Exercise,Verify & Tear Down.
        PostGeneralJournalLineAndVerifyGLEntries(
          GenJournalLine, SalesLine."Sell-to Customer No.", CalculateNonPrepaymentSalesLineAmount(SalesLine),
          GeneralLedgerSetup."Full GST on Prepayment", GeneralLedgerSetup."Adjust for Payment Disc.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentSalesInvoiceWithLineDiscount()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] verify G/L Entries after posting General Journal Line applied to Sales Prepayment Invoice with Line Discount.

        // [GIVEN] Create and Post Sales Prepayment Invoice with Line Discount and apply Payment. Post Sales Order and Create Payment.
        Initialize();
        GeneralLedgerSetup.Get();
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateSalesOrder(
          SalesLine, CreateCustomer('', GeneralPostingSetup."Gen. Bus. Posting Group", 0), SalesLine.Type::Item,
          CreateItem(GeneralPostingSetup."Gen. Prod. Posting Group"), LibraryRandom.RandDec(20, 2));  // Blank value used for Customer Price Group,0 for Prepayment% on Customer and random value used for Prepayment% on Sales Order.
        SalesLine.Validate("Line Discount %", LibraryRandom.RandDec(20, 2));
        SalesLine.Modify(true);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        PostPaymentAfterSalesPrepaymentInvoice(SalesHeader);
        PostSalesOrderAndCreatePayment(GenJournalLine, SalesLine, -CalculateNonPrepaymentSalesLineAmount(SalesLine));

        // Exercise,Verify & Tear Down.
        PostGeneralJournalLineAndVerifyGLEntries(
          GenJournalLine, SalesLine."Sell-to Customer No.", CalculateNonPrepaymentSalesLineAmount(SalesLine),
          GeneralLedgerSetup."Full GST on Prepayment", GeneralLedgerSetup."Adjust for Payment Disc.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentInvoiceWithVendorInvoiceDiscount()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
    begin
        // [SCENARIO] GL Entries in case of Prepayment % is defined with Vendor Invoice Discount.

        // [GIVEN] Create General Posting Setup and Vendor.
        Initialize();
        CreateGeneralPostingSetup(GeneralPostingSetup);
        VendorNo := CreateVendorWithPaymentTerms(GeneralPostingSetup."Gen. Bus. Posting Group", 0, LibraryRandom.RandDec(10, 2));  // Using 0 for Payment Disc. % and Random for Inv. Disc %.
        PrepaymentInvoiceWithDiffSourceOfPrepaymentPct(
          VendorNo, PurchaseLine.Type::Item, CreateItemWithInvoiceDiscount(
            GeneralPostingSetup."Gen. Prod. Posting Group", true), LibraryRandom.RandDec(10, 2), 0);  // Using Random for Prepayment Percent and 0 for Line Discount %.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentInvoiceWithVendorPaymentDiscount()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
    begin
        // [SCENARIO] GL Entries in case of Prepayment % is defined with Vendor Payment Discount.

        // [GIVEN] Create General Posting Setup and Vendor.
        Initialize();
        CreateGeneralPostingSetup(GeneralPostingSetup);
        VendorNo := CreateVendorWithPaymentTerms(GeneralPostingSetup."Gen. Bus. Posting Group", LibraryRandom.RandDec(10, 2), 0);  // Using 0 for Inv. Disc % and Random for Payment Disc. %.
        PrepaymentInvoiceWithDiffSourceOfPrepaymentPct(
          VendorNo, PurchaseLine.Type::Item, CreateItem(
            GeneralPostingSetup."Gen. Prod. Posting Group"), LibraryRandom.RandDec(10, 2), 0);  // Using Random for Prepayment Percent and 0 for Line Discount %.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentInvoiceWithPurchaseLineDiscount()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
    begin
        // [SCENARIO] GL Entries in case of Prepayment % is defined with Purchase Line Discount.

        // [GIVEN] Create General Posting Setup and Vendor.
        Initialize();
        CreateGeneralPostingSetup(GeneralPostingSetup);
        VendorNo := CreateVendor(GeneralPostingSetup."Gen. Bus. Posting Group", 0);  // Using 0 for Prepayment Percent.
        PrepaymentInvoiceWithDiffSourceOfPrepaymentPct(
          VendorNo, PurchaseLine.Type::Item, CreateItem(
            GeneralPostingSetup."Gen. Prod. Posting Group"), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));  // Using Random for Prepayment Percent and Line Discount %.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchPrepaymentInvoiceWithDiffPctInMultipleLine()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        PurchaseInvoiceNo: Code[20];
    begin
        // [SCENARIO] GL Entries in case of different Prepayment % with different Type on Purchase Line.

        // [GIVEN] Create Purchase Order with multiple line, post Prepayment Invoice, Post Payment General with Prepayment Amount and Application with Prepayment Invoice.
        Initialize();
        GeneralLedgerSetup.Get();
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreatePurchaseOrder(
          PurchaseHeader, CreateVendor(GeneralPostingSetup."Gen. Bus. Posting Group", 0), PurchaseLine.Type::Item, CreateItem(
            GeneralPostingSetup."Gen. Prod. Posting Group"), LibraryRandom.RandDec(10, 2));  // Using 0 and Random for Prepayment %.
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.");
        CreatePurchaseLine(
          PurchaseLine2, PurchaseHeader, PurchaseLine2.Type::"G/L Account", CreateGLAccount(
            GeneralPostingSetup."Gen. Prod. Posting Group"), PurchaseLine."Prepayment %" + LibraryRandom.RandDec(10, 2));  // Using Random for Prepayment %.
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        PurchaseInvoiceNo := PostPaymentJournalForPurchasePrepaymentAndInvoice(GenJournalLine, PurchaseHeader, PurchaseLine);

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify GL Entries Credit Amount total with Purchase Amount Including VAT, GST Amount and Prepayment Amount total.
        VerifyCreditAmountOnGLEntry(
          PurchaseInvoiceNo, (PurchaseLine."Amount Including VAT" + PurchaseLine2."Amount Including VAT") -
          (PurchaseLine."Prepayment Amount" + PurchaseLine2."Prepayment Amount") +
          PurchaseLine."Prepayment Amount" + PurchaseLine2."Prepayment Amount");

        // Tear Down.
        UpdateGeneralLedgerSetup(GeneralLedgerSetup."Full GST on Prepayment", GeneralLedgerSetup."Adjust for Payment Disc.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchasePrepaymentInvoiceStatistics()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // [SCENARIO] Purchase Invoice Statistics values after post Purchase Prepayment Invoice.

        // [GIVEN] Create Purchase Document, post Prepayment Invoice, Post Payment General with Prepayment Amount and Application with Prepayment Invoice.
        Initialize();
        GeneralLedgerSetup.Get();
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreatePurchaseOrder(
          PurchaseHeader, CreateVendor(
            GeneralPostingSetup."Gen. Bus. Posting Group", 0), PurchaseLine.Type::Item, CreateItem(
            GeneralPostingSetup."Gen. Prod. Posting Group"), LibraryRandom.RandDec(10, 2));  // Using 0 and Random for Prepayment Percent.
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");  // Enqueue value for PurchasePrepmtDocTestRequestPageHandler.
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.");
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // Exercise: Post Purchase Invoice after posting Payment journal.
        PurchInvHeader.Get(PostPaymentJournalForPurchasePrepaymentAndInvoice(GenJournalLine, PurchaseHeader, PurchaseLine));

        // [THEN] Verify Purchase Invoice Statistics values.
        VerifyVATAmountLine(
          PurchaseLine, PurchInvHeader, -PurchaseLine."VAT Base Amount", -PurchaseLine."VAT Base Amount" * PurchaseLine."VAT %" / 100,
          -PurchaseLine."Prepmt. Line Amount" - Round(PurchaseLine."VAT Base Amount" * PurchaseLine."VAT %" / 100));

        // Tear Down.
        UpdateGeneralLedgerSetup(GeneralLedgerSetup."Full GST on Prepayment", GeneralLedgerSetup."Adjust for Payment Disc.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchPrepaymentInvoiceStatisticsWithPriceIncVAT()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        VATBase: Decimal;
    begin
        // [SCENARIO] Purchase Invoice Statistics values with Price Inc. VAT and without Full GST On Prepayment after post Purchase Prepayment Invoice.

        // [GIVEN] Create Purchase Document, post Prepayment Invoice, Post Payment General with Prepayment Amount and Application with Prepayment Invoice.
        Initialize();
        GeneralLedgerSetup.Get();
        CreateGeneralPostingSetup(GeneralPostingSetup);
        UpdateGeneralLedgerSetup(false, true);  // Using False for Full GST On Prepayment and Adjust for Payment Disc.
        CreatePurchaseOrder(
          PurchaseHeader, CreateVendor(
            GeneralPostingSetup."Gen. Bus. Posting Group", 0), PurchaseLine.Type::Item, CreateItem(
            GeneralPostingSetup."Gen. Prod. Posting Group"), LibraryRandom.RandDecInRange(10, 20, 2));  // Using 0 and Random for Prepayment Percent.
        PurchaseHeader.Validate("Prices Including VAT", true);
        PurchaseHeader.Modify(true);
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");  // Enqueue value for PurchasePrepmtDocTestRequestPageHandler.
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.");
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);

        // Exercise: Post Purchase Invoice after posting Payment journal.
        PurchInvHeader.Get(PostPaymentJournalForPurchasePrepaymentAndInvoice(GenJournalLine, PurchaseHeader, PurchaseLine));

        // [THEN] Verify Purchase Invoice Statistics values.
        VATBase := -PurchaseLine."Prepmt. Line Amount" / (1 + PurchaseLine."VAT %" / 100);
        VerifyVATAmountLine(
          PurchaseLine, PurchInvHeader, Round(VATBase), Round(VATBase * PurchaseLine."VAT %" / 100), -PurchaseLine."Prepmt. Line Amount");

        // Tear Down.
        UpdateGeneralLedgerSetup(GeneralLedgerSetup."Full GST on Prepayment", GeneralLedgerSetup."Adjust for Payment Disc.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceStatisticsWithFullPrepayment()
    begin
        // [SCENARIO] Purchase Invoice Statistics values after post Purchase Prepayment Invoice with full Prepayment.
        Initialize();
        PurchaseInvoiceStatisticsWithPrepayment(100);  // Using 100 for Prepayment percent as full Prepayment as in test case.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceStatisticsWithPartialPrepayment()
    begin
        // [SCENARIO] Purchase Invoice Statistics values after post Purchase Prepayment Invoice with partial Prepayment.
        Initialize();
        PurchaseInvoiceStatisticsWithPrepayment(LibraryRandom.RandDecInRange(25, 75, 2));  // Using Random for Prepayment percent as partial Prepayment.
    end;

    local procedure PurchaseInvoiceStatisticsWithPrepayment(PrepaymentPct: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // [GIVEN] Create Purchase Invoice, post Prepayment Invoice, Post Payment General with Prepayment Amount and Application with Prepayment Invoice.
        GeneralLedgerSetup.Get();
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreatePurchaseOrder(
          PurchaseHeader, CreateVendor(
            GeneralPostingSetup."Gen. Bus. Posting Group", PrepaymentPct), PurchaseLine.Type::Item, CreateItem(
            GeneralPostingSetup."Gen. Prod. Posting Group"), PrepaymentPct);
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.");
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        UpdatePurchaseHeader(PurchaseHeader, WorkDate());

        // Exercise: Post Purchase Invoice after posting Payment journal.
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));  // Post as Receive and Invoice.

        // [THEN] Verify Purchase Invoice Statistics values.
        VerifyVATAmountLine(
          PurchaseLine, PurchInvHeader, -PurchaseLine."VAT Base Amount", -PurchaseLine."VAT Base Amount" * PurchaseLine."VAT %" / 100,
          -PurchaseLine."Prepmt. Line Amount" - Round(PurchaseLine."VAT Base Amount" * PurchaseLine."VAT %" / 100));

        // Tear Down.
        UpdateGeneralLedgerSetup(GeneralLedgerSetup."Full GST on Prepayment", GeneralLedgerSetup."Adjust for Payment Disc.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceStatisticstWithFullPrepayment()
    begin
        // [SCENARIO] Sales Invoice Statistics values after post Sales Prepayment Invoice with full Prepayment.
        SalesInvoiceStatisticsWithPrepayment(100);  // Using 100 for Prepayment percent as full Prepayment as in Test case.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceStatisticsWithPartialPrepayment()
    begin
        // [SCENARIO] Sales Invoice Statistics values after post Sales Prepayment Invoice with partial Prepayment.
        SalesInvoiceStatisticsWithPrepayment(LibraryRandom.RandDecInRange(25, 75, 2));  // Using Random for Prepayment percent as partial Prepayment.
    end;

    local procedure SalesInvoiceStatisticsWithPrepayment(PrepaymentPct: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
    begin
        // [GIVEN] Post Sales Prepayment Invoice and apply Payment. Post Sales Order and Create Payment.
        Initialize();
        GeneralLedgerSetup.Get();
        CreateGeneralPostingSetup(GeneralPostingSetup);
        PostSalesPrepaymentInvoiceAndApplyPayment(
          SalesLine, SalesLine.Type::Item, CreateCustomer('', GeneralPostingSetup."Gen. Bus. Posting Group", PrepaymentPct),
          CreateItem(GeneralPostingSetup."Gen. Prod. Posting Group"), PrepaymentPct);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise.
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));  // Post as Ship and Invoice.

        // [THEN] VAT Base and VAT Amount on VAT Amount Line.
        SalesInvoiceLine.CalcVATAmountLines(SalesInvoiceHeader, VATAmountLine);
        Assert.AreNearlyEqual(
          -SalesLine."Line Amount" * SalesLine."VAT %" / 100, VATAmountLine."VAT Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(
            AmountErr, VATAmountLine.FieldCaption("VAT Amount"), -SalesLine."Line Amount" * SalesLine."VAT %" / 100,
            VATAmountLine.TableCaption()));
        Assert.AreNearlyEqual(
          -SalesLine."Line Amount", VATAmountLine."VAT Base", LibraryERM.GetAmountRoundingPrecision(), StrSubstNo(
            AmountErr, VATAmountLine.FieldCaption("VAT Amount"), -SalesLine."Line Amount", VATAmountLine.TableCaption()));

        // Tear Down.
        UpdateGeneralLedgerSetup(GeneralLedgerSetup."Full GST on Prepayment", GeneralLedgerSetup."Adjust for Payment Disc.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentAmountDoesNotIncludeInvDiscountOnSalesInvoice()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Invoice Discount] [Full GST On Prepayments]
        // [SCENARIO 376429] "Prepayment Line Amount" does not include Invoice Discount in Sales Invoice with "Full GST On Prepayments"

        // [GIVEN] Sales Order with "Full GST On Prepayments" Amount = 100, Prepayment = 10% and Customer with "Invoice Discount" = 5%
        Initialize();
        UpdateCalcInvDiscountOnSalesReceivablesSetup(true);
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreateSalesOrder(
          SalesLine, CreateCustomerInvoiceDiscount(GeneralPostingSetup."Gen. Bus. Posting Group"), SalesLine.Type::"G/L Account",
          CreateGLAccount(GeneralPostingSetup."Gen. Prod. Posting Group"), LibraryRandom.RandDec(20, 2));
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // [WHEN] Calculate "Invoice Discount" for Sales Order
        SalesHeader.CalcInvDiscForHeader();

        // [THEN] "Prepayment Amount" in Sales Line = 10
        SalesLine.Find();
        SalesLine.TestField("Prepmt. Line Amount", Round(SalesLine."Line Amount" * SalesLine."Prepayment %" / 100));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrepaymentAmountDoesNotIncludeInvDiscountOnPurchInvoice()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [Invoice Discount] [Full GST On Prepayments]
        // [SCENARIO 376429] "Prepayment Line Amount" does not include Invoice Discount in Purchase Invoice with "Full GST On Prepayments"

        // [GIVEN] Purchase Order with "Full GST On Prepayments" Amount = 100, Prepayment = 10% and Customer with "Invoice Discount" = 5%
        Initialize();
        UpdateCalcInvDiscountOnPurchSetup(true);
        CreateGeneralPostingSetup(GeneralPostingSetup);
        CreatePurchaseOrder(
          PurchHeader, CreateVendorWithPaymentTerms(GeneralPostingSetup."Gen. Bus. Posting Group", 0, LibraryRandom.RandInt(10)),
          PurchLine.Type::"G/L Account", CreateGLAccount(GeneralPostingSetup."Gen. Prod. Posting Group"),
          LibraryRandom.RandDec(10, 2));

        // [WHEN] Calculate "Invoice Discount" for Purchase Order
        PurchHeader.CalcInvDiscForHeader();

        // [THEN] "Prepayment Amount" in Sales Line = 10
        FindPurchaseLine(PurchLine, PurchHeader."No.");
        PurchLine.TestField("Prepmt. Line Amount", Round(PurchLine."Line Amount" * PurchLine."Prepayment %" / 100));
    end;

    [Test]
    procedure VendorFixedAssetPurchaseOrderGSTEntryValidation()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        FixedAssetNo: Code[20];
        VendorNo: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [GST Purchase Entry]
        // [SCENARIO 598568] Ensure Document Line Code and Description are populated for GST Purchase Entries after posting a purchase invoice for a fixed asset.
        Initialize();
        GeneralLedgerSetup.Get();
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(true, true, true);  // TRUE for Enable GST, GST Reports and Full GST On Prepayment.

        // [GIVEN] Create General Posting Setup, Vendor, and Fixed Asset
        CreateGeneralPostingSetup(GeneralPostingSetup);
        VendorNo := CreateVendor(GeneralPostingSetup."Gen. Bus. Posting Group", 0);
        FixedAssetNo := CreateFixedAsset(GeneralPostingSetup."Gen. Prod. Posting Group");

        // [GIVEN] Create Purchase Order with Vendor and Fixed Asset
        CreatePurchaseOrder(
            PurchaseHeader, VendorNo, PurchaseLine.Type::"Fixed Asset", FixedAssetNo, 0);
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.");

        // [WHEN] Post the Purchase Order Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Validate GST Purchase Entry fields
        ValidateGSTPurchaseEntryFields(DocumentNo);

        // Tear Down.
        UpdateLocalFunctionalitiesOnGeneralLedgerSetup(
          GeneralLedgerSetup."Enable GST (Australia)", GeneralLedgerSetup."GST Report", GeneralLedgerSetup."Full GST on Prepayment");
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        IsInitialized := true;
    end;

    local procedure CalculateNonPrepaymentSalesLineAmount(SalesLine: Record "Sales Line"): Decimal
    begin
        exit(SalesLine."Line Amount" - SalesLine."Prepmt. Line Amount");
    end;

    local procedure CreateCustomer(CustomerPriceGroup: Code[10]; GenBusPostingGroup: Code[20]; PrepaymentPct: Decimal): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        Customer.Validate("Customer Price Group", CustomerPriceGroup);
        Customer.Validate("Prepayment %", PrepaymentPct);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerInvoiceDiscount(GenBusPostingGroup: Code[20]): Code[20]
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CreateCustomer('', GenBusPostingGroup, 0), '', 0);  // Using blank value for Customer Price Group,Currency Code and 0 for Prepayment% and Minimum Amount.
        CustInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(10, 2));
        CustInvoiceDisc.Modify(true);
        exit(CustInvoiceDisc.Code);
    end;

    local procedure CreateCustomerPriceGroup(): Code[10]
    var
        CustomerPriceGroup: Record "Customer Price Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        CustomerPriceGroup.Validate("Allow Invoice Disc.", true);
        CustomerPriceGroup.Validate("Allow Line Disc.", true);
        CustomerPriceGroup.Validate("VAT Bus. Posting Gr. (Price)", VATPostingSetup."VAT Bus. Posting Group");
        CustomerPriceGroup.Modify(true);
        exit(CustomerPriceGroup.Code);
    end;

    local procedure CreateFixedAsset(GenProdPostingGroup: Code[20]): Code[20]
    var
        DepreciationBook: Record "Depreciation Book";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
        GLAccountNo: Code[20];
    begin
        GLAccountNo := CreateGLAccount(GenProdPostingGroup);
        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        FAPostingGroup.Validate("Acquisition Cost Account", GLAccountNo);
        FAPostingGroup.Validate("Acq. Cost Acc. on Disposal", GLAccountNo);
        FAPostingGroup.Validate("Losses Acc. on Disposal", GLAccountNo);
        FAPostingGroup.Validate("Gains Acc. on Disposal", GLAccountNo);
        FAPostingGroup.Modify(true);
        FixedAsset.Validate("FA Posting Group", FAPostingGroup.Code);
        FASetup.Get();
        DepreciationBook.Get(FASetup."Default Depr. Book");
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);
        FADepreciationBook.Validate("FA Posting Group", FixedAsset."FA Posting Group");
        FADepreciationBook.Modify(true);
        exit(FixedAsset."No.");
    end;

    local procedure CreateGeneralBusinessPostingGroup(DefVATBusinessPostingGroup: Code[20]): Code[20]
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
    begin
        LibraryERM.CreateGenBusPostingGroup(GenBusinessPostingGroup);
        GenBusinessPostingGroup.Validate("Def. VAT Bus. Posting Group", DefVATBusinessPostingGroup);
        GenBusinessPostingGroup.Modify(true);
        exit(GenBusinessPostingGroup.Code);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; AppliesToDocNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGeneralPostingSetup(var GeneralPostingSetup: Record "General Posting Setup")
    var
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        GenProdPostingGroupCode: Code[20];
        GLAccountNo: Code[20];
    begin
        UpdateGeneralLedgerSetup(true, true);  // Using False for Full GST On Prepayment and Adjust for Payment Disc.
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.Validate("Purchase VAT Account", GLAccount."No.");
        VATPostingSetup.Modify(true);
        GenProdPostingGroupCode := CreateGeneralProductPostingGroup(VATPostingSetup."VAT Prod. Posting Group");
        GLAccountNo := CreateGLAccount(GenProdPostingGroupCode);
        LibraryERM.CreateGeneralPostingSetup(
          GeneralPostingSetup, CreateGeneralBusinessPostingGroup(VATPostingSetup."VAT Bus. Posting Group"), GenProdPostingGroupCode);
        GeneralPostingSetup.Validate("Sales Account", GLAccountNo);
        GeneralPostingSetup.Validate("Sales Prepayments Account", GLAccountNo);
        GeneralPostingSetup.Validate("COGS Account", GLAccountNo);
        GeneralPostingSetup.Validate("Purch. Account", GLAccountNo);
        GeneralPostingSetup.Validate("Purch. Prepayments Account", GLAccountNo);
        GeneralPostingSetup.Validate("Purch. Inv. Disc. Account", GLAccountNo);
        GeneralPostingSetup.Validate("Purch. Line Disc. Account", GLAccountNo);
        GeneralPostingSetup.Validate("COGS Account", GLAccountNo);
        GeneralPostingSetup.Validate("Direct Cost Applied Account", GLAccountNo);
        GeneralPostingSetup.Validate("Sales Inv. Disc. Account", GLAccountNo);
        GeneralPostingSetup.Validate("Sales Line Disc. Account", GLAccountNo);
        GeneralPostingSetup.Validate("Sales Pmt. Disc. Debit Acc.", GLAccountNo);
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CreateGeneralProductPostingGroup(DefVATProdPostingGroup: Code[20]): Code[20]
    var
        GenProdPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.CreateGenProdPostingGroup(GenProdPostingGroup);
        GenProdPostingGroup.Validate("Def. VAT Prod. Posting Group", DefVATProdPostingGroup);
        GenProdPostingGroup.Modify(true);
        exit(GenProdPostingGroup.Code);
    end;

    local procedure CreateGLAccount(GenProdPostingGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateItem(GenProdPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemWithInvoiceDiscount(GenProdPostingGroup: Code[20]; AllowInvoiceDisc: Boolean): Code[20]
    var
        Item: Record Item;
    begin
        Item.Get(CreateItem(GenProdPostingGroup));
        Item.Validate("Allow Invoice Disc.", AllowInvoiceDisc);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Document Type"; No: Code[20]; PrepaymentPct: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, LibraryRandom.RandDec(10, 2));  // Random value is used for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Prepayment %", PrepaymentPct);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; BuyfromVendorNo: Code[20]; Type: Enum "Purchase Line Type"; No: Code[20]; PrepaymentPct: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, BuyfromVendorNo);
        PurchaseHeader.Validate("Prepayment %", PrepaymentPct);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, LibraryRandom.RandDec(10, 2));  // Random value is used for Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Validate("Prepayment %", PurchaseHeader."Prepayment %");
        PurchaseLine.Validate("Allow Invoice Disc.", true);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchasePrepaymentPct(GenProdPostingGroup: Code[20]; VendorNo: Code[20]; PrepaymentPct: Decimal): Code[20]
    var
        PurchasePrepaymentPct: Record "Purchase Prepayment %";
    begin
        LibraryPurchase.CreatePurchasePrepaymentPct(PurchasePrepaymentPct, CreateItem(GenProdPostingGroup), VendorNo, WorkDate());
        PurchasePrepaymentPct.Validate("Prepayment %", PrepaymentPct);
        PurchasePrepaymentPct.Modify(true);
        exit(PurchasePrepaymentPct."Item No.");
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Enum "Sales Document Type"; No: Code[20]; PrepaymentPercent: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, LibraryRandom.RandDec(10, 2));  // Random value is used for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Prepayment %", PrepaymentPercent);
        SalesLine.Validate("Allow Invoice Disc.", true);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesLine: Record "Sales Line"; SellToCustomerNo: Code[20]; Type: Enum "Sales Line Type"; No: Code[20]; PrepaymentPercent: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SellToCustomerNo);
        CreateSalesLine(SalesLine, SalesHeader, Type, No, PrepaymentPercent);
    end;

    local procedure CreateSalesPrepaymentPercentage(ItemNo: Code[20]; SalesCode: Code[20]; SalesType: Option)
    var
        SalesPrepaymentPct: Record "Sales Prepayment %";
    begin
        LibrarySales.CreateSalesPrepaymentPct(SalesPrepaymentPct, SalesType, SalesCode, ItemNo, WorkDate());
        SalesPrepaymentPct.Validate("Prepayment %", LibraryRandom.RandDec(10, 2));
        SalesPrepaymentPct.Modify(true);
    end;

    local procedure CreateVendor(GenBusPostingGroup: Code[20]; PrepaymentPct: Decimal): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        Vendor.Validate("Prepayment %", PrepaymentPct);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateVendorInvoiceDiscount(VendorNo: Code[20]; DiscountPct: Decimal): Code[20]
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, VendorNo, '', 0);  // Using blank for Currency Code and 0 for Minimum Amount.
        VendorInvoiceDisc.Validate("Discount %", DiscountPct);
        VendorInvoiceDisc.Modify(true);
        exit(VendorInvoiceDisc.Code);
    end;

    local procedure CreateVendorWithPaymentTerms(GenBusPostingGroup: Code[20]; DiscountPct: Decimal; InvDiscountPct: Decimal): Code[20]
    var
        Vendor: Record Vendor;
        PaymentTerms: Record "Payment Terms";
    begin
        Vendor.Get(CreateVendor(GenBusPostingGroup, 0));  // Using 0 for Prepayment percent.
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        PaymentTerms.Validate("Discount %", DiscountPct);
        PaymentTerms.Modify(true);
        Vendor.Validate("Invoice Disc. Code", CreateVendorInvoiceDiscount(Vendor."No.", InvDiscountPct));
        Vendor.Modify(true);
        exit(Vendor."No.")
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
    end;

    local procedure GetPrepaymentPurchaseInvoiceNo(VendorNo: Code[20]): Code[20]
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.FindFirst();
        exit(VendorLedgerEntry."Document No.");
    end;

    local procedure PostGeneralJournalLineAndVerifyGLEntries(GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; Amount: Decimal; OldFullGSTOnPrepayment: Boolean; AdjustForPaymentDisc: Boolean)
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify.
        Customer.Get(CustomerNo);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        VerifyAmountOnGLEntry(GenJournalLine."Document No.", GenJournalLine."Bal. Account No.", Amount);
        VerifyAmountOnGLEntry(GenJournalLine."Document No.", CustomerPostingGroup."Receivables Account", -Amount);

        // Tear Down.
        UpdateGeneralLedgerSetup(OldFullGSTOnPrepayment, AdjustForPaymentDisc);
    end;

    local procedure PostPaymentAfterSalesPrepaymentInvoice(var SalesHeader: Record "Sales Header")
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesInvoiceHeader.FindFirst();
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        CreateGeneralJournalLine(
          GenJournalLine, CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()), GenJournalLine."Account Type"::Customer
          , SalesHeader."Sell-to Customer No.", SalesInvoiceHeader."No.", -SalesInvoiceHeader."Amount Including VAT");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostPaymentAppliedToPrepaymentSalesInvoice(var GeneralPostingSetup: Record "General Posting Setup"; Type: Enum "Sales Line Type"; No: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        SalesLine: Record "Sales Line";
    begin
        GeneralLedgerSetup.Get();
        PostSalesPrepaymentInvoiceAndApplyPayment(
          SalesLine, Type, CreateCustomer('', GeneralPostingSetup."Gen. Bus. Posting Group", 0), No, LibraryRandom.RandDec(10, 2));  // Blank value used for Customer Posting Group, 0 used for Prepayment% and Random value used for Prepayment%.
        PostSalesOrderAndCreatePayment(GenJournalLine, SalesLine, -CalculateNonPrepaymentSalesLineAmount(SalesLine));

        // Exercise,Verify & Tear Down.
        PostGeneralJournalLineAndVerifyGLEntries(
          GenJournalLine, SalesLine."Sell-to Customer No.", CalculateNonPrepaymentSalesLineAmount(SalesLine),
          GeneralLedgerSetup."Full GST on Prepayment", GeneralLedgerSetup."Adjust for Payment Disc.");
    end;

    local procedure PostSalesOrderAndCreatePayment(var GenJournalLine: Record "Gen. Journal Line"; SalesLine: Record "Sales Line"; Amount: Decimal)
    var
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        AppliesToDocNo: Code[20];
    begin
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        PaymentTerms.Get(SalesHeader."Payment Terms Code");
        SalesHeader.Validate("Posting Date", CalcDate(PaymentTerms."Discount Date Calculation", WorkDate()));
        SalesHeader.Modify(true);
        AppliesToDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.
        CreateGeneralJournalLine(
          GenJournalLine, CalcDate(PaymentTerms."Due Date Calculation", WorkDate()), GenJournalLine."Account Type"::Customer,
          SalesLine."Sell-to Customer No.", AppliesToDocNo, Amount);
    end;

    local procedure PostSalesPrepaymentInvoiceAndApplyPayment(var SalesLine: Record "Sales Line"; Type: Enum "Sales Line Type"; CustomerNo: Code[20]; No: Code[20]; PrepaymentPercent: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesOrder(SalesLine, CustomerNo, Type, No, PrepaymentPercent);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        PostPaymentAfterSalesPrepaymentInvoice(SalesHeader);
    end;

    local procedure PostPaymentJournalForPurchasePrepaymentAndInvoice(var GenJournalLine: Record "Gen. Journal Line"; PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line") PurchaseInvoiceNo: Code[20]
    begin
        CreateGeneralJournalLine(
          GenJournalLine, CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()), GenJournalLine."Account Type"::Vendor,
          PurchaseHeader."Buy-from Vendor No.", GetPrepaymentPurchaseInvoiceNo(
            PurchaseHeader."Buy-from Vendor No."), PurchaseLine."Prepmt. Line Amount");

        // Update Vendor Invoice No, post Purchase Invoice, post Payment General with Purchase Amount and Application with Purchase Invoice.
        UpdatePurchaseHeader(PurchaseHeader, GenJournalLine."Posting Date");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        PurchaseInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Post as Receive and Invoice.
        CreateGeneralJournalLine(
          GenJournalLine, CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', PurchaseHeader."Posting Date"),
          GenJournalLine."Account Type"::Vendor, PurchaseHeader."Buy-from Vendor No.", PurchaseInvoiceNo,
          PurchaseLine."Amount Including VAT");
    end;

    local procedure PrepaymentInvoiceWithDiffSourceOfPrepaymentPct(BuyFromVendorNo: Code[20]; Type: Enum "Purchase Line Type"; No: Code[20]; PrepaymentPct: Decimal; LineDiscountPct: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseInvoiceNo: Code[20];
    begin
        // Setup: Create Purchase Document, post Prepayment Invoice, Post Payment General with Prepayment Amount and Application with Prepayment Invoice.
        GeneralLedgerSetup.Get();
        CreatePurchaseOrder(PurchaseHeader, BuyFromVendorNo, Type, No, PrepaymentPct);
        UpdateLineDiscountPercentOnPurchaseLine(PurchaseLine, PurchaseHeader."No.", LineDiscountPct);
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchaseHeader);
        PurchaseInvoiceNo := PostPaymentJournalForPurchasePrepaymentAndInvoice(GenJournalLine, PurchaseHeader, PurchaseLine);

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify GL Entries Credit Amount total with Purchase Amount Including VAT, GST Amount and Prepayment Amount total.
        VerifyCreditAmountOnGLEntry(
          PurchaseInvoiceNo, (PurchaseLine."Amount Including VAT" - PurchaseLine."Prepayment Amount") + PurchaseLine."Prepayment Amount");

        // Tear Down.
        UpdateGeneralLedgerSetup(GeneralLedgerSetup."Full GST on Prepayment", GeneralLedgerSetup."Adjust for Payment Disc.");
    end;

    local procedure SalesPrepaymentInvoiceWithSalesType(CustomerNo: Code[20]; SalesCode: Code[20]; ItemNo: Code[20]; SalesType: Option)
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        AppliesToDocNo: Code[20];
    begin
        GeneralLedgerSetup.Get();
        CreateSalesPrepaymentPercentage(ItemNo, SalesCode, SalesType);
        PostSalesPrepaymentInvoiceAndApplyPayment(SalesLine, SalesLine.Type::Item, CustomerNo, ItemNo, LibraryRandom.RandDec(10, 2));  // Random value used for Prepayment%.
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesLine."Sell-to Customer No.");
        SalesInvoiceHeader.FindFirst();
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        AppliesToDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Ship and Invoice.
        CreateGeneralJournalLine(
          GenJournalLine, WorkDate(), GenJournalLine."Account Type"::Customer, SalesLine."Sell-to Customer No.",
          AppliesToDocNo, -CalculateNonPrepaymentSalesLineAmount(SalesLine));

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify Prepayment Invoice GL Entries and Payment GL Entries.
        Customer.Get(SalesHeader."Sell-to Customer No.");
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        VerifyAmountOnGLEntry(SalesInvoiceHeader."No.", GeneralPostingSetup."Sales Prepayments Account", -SalesLine."Prepmt. Line Amount");
        VerifyAmountOnGLEntry(
          SalesInvoiceHeader."No.", VATPostingSetup."Sales VAT Account", -SalesLine."VAT Base Amount" * SalesLine."VAT %" / 100);
        VerifyAmountOnGLEntry(
          SalesInvoiceHeader."No.", CustomerPostingGroup."Receivables Account",
          SalesLine."VAT Base Amount" * SalesLine."VAT %" / 100 + SalesLine."Prepmt. Line Amount");
        VerifyAmountOnGLEntry(
          GenJournalLine."Document No.", GenJournalLine."Bal. Account No.", CalculateNonPrepaymentSalesLineAmount(SalesLine));
        VerifyAmountOnGLEntry(
          GenJournalLine."Document No.", CustomerPostingGroup."Receivables Account", -CalculateNonPrepaymentSalesLineAmount(SalesLine));

        // Tear Down.
        UpdateGeneralLedgerSetup(GeneralLedgerSetup."Full GST on Prepayment", GeneralLedgerSetup."Adjust for Payment Disc.");
    end;

    local procedure UpdateCalcInvDiscountOnSalesReceivablesSetup(NewCalcInvDiscount: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Calc. Inv. Discount", NewCalcInvDiscount);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateCalcInvDiscountOnPurchSetup(NewCalcInvDiscount: Boolean)
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        PurchSetup.Get();
        PurchSetup.Validate("Calc. Inv. Discount", NewCalcInvDiscount);
        PurchSetup.Modify(true);
    end;

    local procedure UpdateGeneralLedgerSetup(NewFullGSTOnPrepayment: Boolean; AdjustForPaymentDisc: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Full GST on Prepayment", NewFullGSTOnPrepayment);
        GeneralLedgerSetup.Validate("Adjust for Payment Disc.", AdjustForPaymentDisc);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateLineDiscountPercentOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20]; LineDiscountPct: Decimal)
    begin
        FindPurchaseLine(PurchaseLine, DocumentNo);
        PurchaseLine.Validate("Line Discount %", LineDiscountPct);
        PurchaseLine.Modify(true);
    end;

    local procedure UpdatePaymentTermsCodeOnSalesHeader(var SalesHeader: Record "Sales Header")
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.SetFilter("Discount %", StrSubstNo(NotEqualToZeroTxt, 0));  // Value 0 required for finding Payment Terms with Discount %.
        LibraryERM.FindPaymentTerms(PaymentTerms);
        SalesHeader.Validate("Payment Terms Code", PaymentTerms.Code);
        SalesHeader.Modify(true);
    end;

    local procedure UpdatePurchaseHeader(var PurchaseHeader: Record "Purchase Header"; Date: Date)
    begin
        PurchaseHeader.Validate("Posting Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', Date));
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
    end;

    local procedure VerifyAmountOnGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption()));
    end;

    local procedure VerifyCreditAmountOnGLEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        CreditAmount: Decimal;
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindSet();
        repeat
            CreditAmount += GLEntry."Credit Amount";
        until GLEntry.Next() = 0;
        Assert.AreEqual(CreditAmount, Amount, StrSubstNo(AmountErr, GLEntry.FieldCaption("Credit Amount"), Amount, GLEntry.TableCaption()));
    end;

    local procedure VerifyVATAmountLine(PurchaseLine: Record "Purchase Line"; PurchInvHeader: Record "Purch. Inv. Header"; VATBase: Decimal; VATAmount: Decimal; AmountIncludingVAT: Decimal)
    var
        PurchInvLine: Record "Purch. Inv. Line";
        VATAmountLine: Record "VAT Amount Line";
    begin
        PurchInvLine.CalcVATAmountLines(PurchInvHeader, VATAmountLine);
        VATAmountLine.TestField("VAT %", PurchaseLine."VAT %");
        VATAmountLine.TestField("Line Amount", -PurchaseLine."Prepmt. Line Amount");
        VATAmountLine.TestField("VAT Base", VATBase);
        VATAmountLine.TestField("VAT Amount", VATAmount);
        VATAmountLine.TestField("Amount Including VAT", AmountIncludingVAT);
    end;

    local procedure UpdateLocalFunctionalitiesOnGeneralLedgerSetup(EnableGST: Boolean; GSTReport: Boolean; FullGSTOnPrepayment: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Enable GST (Australia)", EnableGST);
        GeneralLedgerSetup.Validate("GST Report", GSTReport);
        GeneralLedgerSetup.Validate("Full GST on Prepayment", FullGSTOnPrepayment);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure ValidateGSTPurchaseEntryFields(DocumentNo: Code[20])
    var
        GSTPurchaseEntry: Record "GST Purchase Entry";
    begin
        GSTPurchaseEntry.SetRange("Document No.", DocumentNo);
        if GSTPurchaseEntry.FindSet() then
            repeat
                GSTPurchaseEntry.TestField("Document Line Code");
                GSTPurchaseEntry.TestField("Document Line Description");
            until GSTPurchaseEntry.Next() = 0
        else
            Error('No GST Purchase Entries found for document %1', DocumentNo);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchasePrepmtDocTestRequestPageHandler(var PurchasePrepmtDocTest: TestRequestPage "Purchase Prepmt. Doc. - Test")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        PurchasePrepmtDocTest."Purchase Header".SetFilter("No.", No);
        PurchasePrepmtDocTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

