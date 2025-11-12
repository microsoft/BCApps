codeunit 134079 "ERM Inv Discount by Currency"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Invoice Discount] [FCY]
        isInitialized := false;
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        InvoiceDiscountError: Label 'Invoice Discount must be %1.';
        InvoiceDiscountAmount: Decimal;
        FieldError: Label '%1 must be %2 in %3.';
        InvDiscountAmountInvoicing: Decimal;
        AmountInclVAT: Decimal;
        TotalInclVAT: Decimal;
        VATAmount: Decimal;
        TotalExclVAT: Decimal;
        isInitialized: Boolean;
        IsVerify: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceDiscPurchaseCreditMemo()
    begin
        // Covers documents TC_ID=5327 and 5328.
        // Check that Invoice Discount amount calculated on Purchase Credit Memo as per discount mentioned on Vendor.

        // Setup.
        Initialize();
        CreateAndVerifyInvoiceDiscForPurchase("Purchase Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceDiscForPurchaseInvoice()
    begin
        // Covers documents TC_ID=5328,5329 and 5331.
        // Check that Invoice Discount amount calculated on Purchase Invoice as per discount mentioned on Vendor.

        // Setup.
        Initialize();
        CreateAndVerifyInvoiceDiscForPurchase("Purchase Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceDiscForPurchaseOrder()
    begin
        // Covers documents TC_ID=5328,5333, 5334 and 5339.
        // Check that Invoice Discount amount calculated on Purchase Order as per discount mentioned on Vendor.

        // Setup.
        Initialize();
        CreateAndVerifyInvoiceDiscForPurchase("Purchase Document Type"::Order);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceDiscForSalesCreditMemo()
    begin
        // Covers documents TC_ID=5328, 5340 and 5348.
        // Check that Invoice Discount amount calculated on Sales Credit Memo as per discount mentioned on Customer.

        // Setup.
        Initialize();
        CreateAndVerifyInvoiceDiscForSales("Sales Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceDiscForSalesInvoice()
    begin
        // Covers documents TC_ID=5328,5349,5350 and 5351.
        // Check that Invoice Discount amount calculated on Sales Invoice as per discount mentioned on Customer.

        // Setup.
        Initialize();
        CreateAndVerifyInvoiceDiscForSales("Sales Document Type"::Invoice);
    end;

    local procedure CreateAndVerifyInvoiceDiscForPurchase(DocType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Exercise: Create Purchase Header and Line for Credit Memo, Invoice and Order and Calculate Invoice Discount for Vendor on Purchase Line.
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, CreateCurrency(), DocType);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PurchaseHeader.CalcFields(Amount);
        CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", PurchaseLine);

        // Verify: Verify Invoice Discount on Purchase Line for Vendor.
        VerifyInvoiceDiscForVendor(PurchaseLine, PurchaseHeader.Amount);
    end;

    local procedure CreateAndVerifyInvoiceDiscForSales(DocType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Exercise: Create Sales Header and Line for Credit Memo and Invoice and Calculate Invoice Discount for Customer on Sales Line.
        CreateSalesDocument(SalesHeader, SalesLine, CreateCurrency(), DocType);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        SalesHeader.CalcFields(Amount);
        CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);

        // Verify: Verify Invoice Discount on Sales Line for Customer.
        VerifyInvoiceDiscForCustomer(SalesLine, SalesHeader.Amount);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('GeneralSalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure InvDiscAmountOnSalesLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        InvDiscAmountForLine: Decimal;
    begin
        // Check Invoice Discount Amount on Sales Lines after entering Invoice Discount Amount in Sales Order Statistics window.

        // Setup: Create Sales Order and add new Sales Line.
        Initialize();
        CreateSalesOrder(SalesHeader, SalesLine);
        CreateAndModifySalesLine(SalesLine2, SalesHeader, SalesLine.Quantity, SalesLine."Unit Price");

        // InvDiscountAmount is a global variable and used on Statistics page.
        // Assigning value to Invoice Discount Amount to make sure InvDiscountAmount is always less than total amount of Order.
        InvoiceDiscountAmount := SalesLine."Line Amount";
        InvDiscAmountForLine := Round(InvoiceDiscountAmount / 2);

        // Exercise: Open Sales Order Statistics Page and assign Invoice Discount Amount in Handler (SalesOrderStatisticsHandler).
        OpenSalesOrderStatistics(SalesHeader."No.");

        // Verify: Verify Invoice Discount Amount on Sales Line.
        VerifySalesLineInvDiscAmount(SalesHeader."No.", SalesLine."No.", InvDiscAmountForLine);
        VerifySalesLineInvDiscAmount(SalesHeader."No.", SalesLine2."No.", InvDiscAmountForLine);
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('GeneralSalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure InvDiscForPartialSalesOrder()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLEntry: Record "G/L Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        Amount: Decimal;
        PostedDocumentNo: Code[20];
    begin
        // Check Amount on GL Entry after posting Sales Order with partial Invoice.

        // Setup: Create Sales Order with Random Unit Price.
        Initialize();
        CreateSalesOrder(SalesHeader, SalesLine);
        CreateAndModifySalesLine(SalesLine2, SalesHeader, SalesLine.Quantity, SalesLine."Unit Price");

        // InvDiscountAmount is a global variable which is used to assign Invoice Discount Amount on Statistics page (SalesOrderStatisticsHandler).
        // Assigning value to InvDiscountAmount to make sure Inv. Discount Amount is always less than total amount of Order.
        InvoiceDiscountAmount := SalesLine."Line Amount";
        Amount := Round(InvoiceDiscountAmount / 2);
        OpenSalesOrderStatistics(SalesHeader."No.");
        UpdateQtyToShip(SalesLine2, SalesHeader."No.");
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");

        // Exercise: Post Sales Order and find GL Entry.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        FindGLEntry(GLEntry, PostedDocumentNo, GeneralPostingSetup."Sales Inv. Disc. Account");

        // Verify: Verify GL Entry for Invoice Discount Amount.
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(FieldError, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption()));
    end;
#endif
    [Test]
    [HandlerFunctions('GeneralSalesOrderStatisticsHandlerNM')]
    [Scope('OnPrem')]
    procedure InvDiscAmountOnSalesLineNM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        InvDiscAmountForLine: Decimal;
    begin
        // Check Invoice Discount Amount on Sales Lines after entering Invoice Discount Amount in Sales Order Statistics window.

        // Setup: Create Sales Order and add new Sales Line.
        Initialize();
        CreateSalesOrder(SalesHeader, SalesLine);
        CreateAndModifySalesLine(SalesLine2, SalesHeader, SalesLine.Quantity, SalesLine."Unit Price");

        // InvDiscountAmount is a global variable and used on Statistics page.
        // Assigning value to Invoice Discount Amount to make sure InvDiscountAmount is always less than total amount of Order.
        InvoiceDiscountAmount := SalesLine."Line Amount";
        InvDiscAmountForLine := Round(InvoiceDiscountAmount / 2);

        // Exercise: Open Sales Order Statistics Page and assign Invoice Discount Amount in Handler (SalesOrderStatisticsHandler).
        OpenSalesOrderStatisticsNM(SalesHeader."No.");

        // Verify: Verify Invoice Discount Amount on Sales Line.
        VerifySalesLineInvDiscAmount(SalesHeader."No.", SalesLine."No.", InvDiscAmountForLine);
        VerifySalesLineInvDiscAmount(SalesHeader."No.", SalesLine2."No.", InvDiscAmountForLine);
    end;

    [Test]
    [HandlerFunctions('GeneralSalesOrderStatisticsHandlerNM')]
    [Scope('OnPrem')]
    procedure InvDiscForPartialSalesOrderNM()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLEntry: Record "G/L Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        Amount: Decimal;
        PostedDocumentNo: Code[20];
    begin
        // Check Amount on GL Entry after posting Sales Order with partial Invoice.

        // Setup: Create Sales Order with Random Unit Price.
        Initialize();
        CreateSalesOrder(SalesHeader, SalesLine);
        CreateAndModifySalesLine(SalesLine2, SalesHeader, SalesLine.Quantity, SalesLine."Unit Price");

        // InvDiscountAmount is a global variable which is used to assign Invoice Discount Amount on Statistics page (SalesOrderStatisticsHandler).
        // Assigning value to InvDiscountAmount to make sure Inv. Discount Amount is always less than total amount of Order.
        InvoiceDiscountAmount := SalesLine."Line Amount";
        Amount := Round(InvoiceDiscountAmount / 2);
        OpenSalesOrderStatisticsNM(SalesHeader."No.");
        UpdateQtyToShip(SalesLine2, SalesHeader."No.");
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");

        // Exercise: Post Sales Order and find GL Entry.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        FindGLEntry(GLEntry, PostedDocumentNo, GeneralPostingSetup."Sales Inv. Disc. Account");

        // Verify: Verify GL Entry for Invoice Discount Amount.
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(FieldError, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption()));
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure InvDiscAmountOnPurchLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        InvDiscAmountForLine: Decimal;
    begin
        // Check Invoice Discount Amount on Purchase Line after entering Invoice Discount Amount in Purchase Order Statistics window.

        // Setup: Create Purchase Order and add new Purchase Line.
        Initialize();
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        CreateAndModifyPurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine.Quantity, PurchaseLine."Direct Unit Cost");

        // InvDiscountAmount is a global variable which is used to assign Invoice Discount Amount on Statistics page. Assigning value to InvDiscountAmount to make sure Inv. Discount Amount is always less than total amount of Order.
        InvoiceDiscountAmount := PurchaseLine."Line Amount";
        InvDiscAmountForLine := Round(InvoiceDiscountAmount / 2);

        // Exercise: Open Purchase Order Statistics Page and assign Invoice Discount Amount in Handler (PurchaseOrderStatisticsHandler).
        OpenPurchaseOrderStatistics(PurchaseHeader."No.");

        // Verify: Verify Invoice Discount Amount on Purchase Line.
        VerifyPurchLineInvDiscAmount(PurchaseHeader."No.", PurchaseLine."No.", InvDiscAmountForLine);
        VerifyPurchLineInvDiscAmount(PurchaseHeader."No.", PurchaseLine2."No.", InvDiscAmountForLine);
    end;

    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure InvDiscForPartialPurchOrder()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLEntry: Record "G/L Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        PostedDocumentNo: Code[20];
        Amount: Decimal;
    begin
        // Check Amount on GL Entry after posting Purchase Order with partial Invoice.

        // Setup: Create Purchase Order with Random Quantity and Direct Unit Cost.
        Initialize();
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        CreateAndModifyPurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine.Quantity, PurchaseLine."Direct Unit Cost");

        // InvDiscountAmount is a global variable which is used to assign Invoice Discount Amount on Statistics page (PurchaseOrderStatisticsHandler).
        // Assigning value to InvDiscountAmount to make sure Inv. Discount Amount is always less than total amount of Order.
        InvoiceDiscountAmount := PurchaseLine."Line Amount";
        Amount := Round(InvoiceDiscountAmount / 2);
        OpenPurchaseOrderStatistics(PurchaseHeader."No.");
        UpdateQtyToReceive(PurchaseLine2, PurchaseHeader."No.");
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");

        // Exercise: Post Purchase Order and find GL Entry.
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        FindGLEntry(GLEntry, PostedDocumentNo, GeneralPostingSetup."Purch. Inv. Disc. Account");

        // Verify: Verify GL Entry for Invoice Discount Amount.
        Assert.AreNearlyEqual(
          -Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(FieldError, GLEntry.FieldCaption(Amount), -Amount, GLEntry.TableCaption()));
    end;
#endif

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure InvDiscountAmountOnPurchLine()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        InvDiscAmountForLine: Decimal;
    begin
        // Check Invoice Discount Amount on Purchase Line after entering Invoice Discount Amount in Purchase Order Statistics window.

        // Setup: Create Purchase Order and add new Purchase Line.
        Initialize();
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        CreateAndModifyPurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine.Quantity, PurchaseLine."Direct Unit Cost");

        // InvDiscountAmount is a global variable which is used to assign Invoice Discount Amount on Statistics page. Assigning value to InvDiscountAmount to make sure Inv. Discount Amount is always less than total amount of Order.
        InvoiceDiscountAmount := PurchaseLine."Line Amount";
        InvDiscAmountForLine := Round(InvoiceDiscountAmount / 2);

        // Exercise: Open Purchase Order Statistics Page and assign Invoice Discount Amount in Handler (PurchaseOrderStatisticsPageHandler).
        OpenPurchaseOrderStats(PurchaseHeader."No.");

        // Verify: Verify Invoice Discount Amount on Purchase Line.
        VerifyPurchLineInvDiscAmount(PurchaseHeader."No.", PurchaseLine."No.", InvDiscAmountForLine);
        VerifyPurchLineInvDiscAmount(PurchaseHeader."No.", PurchaseLine2."No.", InvDiscAmountForLine);
    end;

    [Test]
    [HandlerFunctions('PurchaseOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure InvDiscountForPartialPurchOrder()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLEntry: Record "G/L Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        PostedDocumentNo: Code[20];
        Amount: Decimal;
    begin
        // Check Amount on GL Entry after posting Purchase Order with partial Invoice.

        // Setup: Create Purchase Order with Random Quantity and Direct Unit Cost.
        Initialize();
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine);
        CreateAndModifyPurchaseLine(PurchaseLine2, PurchaseHeader, PurchaseLine.Quantity, PurchaseLine."Direct Unit Cost");

        // InvDiscountAmount is a global variable which is used to assign Invoice Discount Amount on Statistics page (PurchaseOrderStatisticsPageHandler).
        // Assigning value to InvDiscountAmount to make sure Inv. Discount Amount is always less than total amount of Order.
        InvoiceDiscountAmount := PurchaseLine."Line Amount";
        Amount := Round(InvoiceDiscountAmount / 2);
        OpenPurchaseOrderStats(PurchaseHeader."No.");
        UpdateQtyToReceive(PurchaseLine2, PurchaseHeader."No.");
        PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");

        // Exercise: Post Purchase Order and find GL Entry.
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        FindGLEntry(GLEntry, PostedDocumentNo, GeneralPostingSetup."Purch. Inv. Disc. Account");

        // Verify: Verify GL Entry for Invoice Discount Amount.
        Assert.AreNearlyEqual(
          -Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(FieldError, GLEntry.FieldCaption(Amount), -Amount, GLEntry.TableCaption()));
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('GeneralSalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure InvoiceDiscountAmountsOnSalesOrderStatistics()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        // Check Invoice Discount Amount on General and Invoicing tab of Sales Order Statistics window after modifying Quantity to Invoice on Sales lines.

        // Setup: Create Sales Order with Random Quantity and Unit Price.
        Initialize();
        CreateSalesOrder(SalesHeader, SalesLine);
        CreateAndModifySalesLine(SalesLine2, SalesHeader, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2));
        InvoiceDiscountAmount := SalesLine."Line Amount"; // InvoiceDiscountAmount is a global variable and is assigned to make sure discount is less than total Order amount.
        OpenSalesOrderStatistics(SalesHeader."No.");

        // Exercise: Update Quantity to Invoice on Sales line.
        UpdateQtyToInvoice(SalesLine, SalesHeader."No.", SalesLine.Quantity / 2);
        UpdateQtyToInvoice(SalesLine2, SalesHeader."No.", 0);
        FindSalesLine(SalesLine, SalesHeader."No.", SalesLine."No.");

        // Calculation is done for distributed Inv. Discount Amount on Sales Lines for Invoicing.
        InvDiscountAmountInvoicing :=
          Round(
          InvoiceDiscountAmount *
            SalesLine."Qty. to Invoice" * SalesLine."Unit Price" / (SalesLine."Line Amount" + SalesLine2."Line Amount"));

        // Verify: IsVerify is a global variable and Verification is done in 'GeneralSalesOrderStatisticsHandler'.
        IsVerify := true;
        OpenSalesOrderStatistics(SalesHeader."No.");
    end;

    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('InvoicingSalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure VariousVATAmountsOnSalesOrderStatistics()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Check various VAT fields on Statistics window after modifying Inv. Discount Amount on Invoicing tab.

        // Setup: Create Sales Order and use Random for Inv. Discount Amount.
        Initialize();
        CreateSalesDocumentWithVAT(SalesHeader, SalesLine);
        UpdateQtyToInvoice(SalesLine, SalesHeader."No.", SalesLine.Quantity / 2);
        FindSalesLine(SalesLine, SalesHeader."No.", SalesLine."No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        InvoiceDiscountAmount := LibraryRandom.RandInt(10);  // InvoiceDiscountAmount is a global variable.

        // Following Global variables are used to verify on handler.
        GeneralLedgerSetup.Get();
        AmountInclVAT := Round(SalesLine."Unit Price" * SalesLine."Qty. to Invoice", GeneralLedgerSetup."Amount Rounding Precision");
        TotalInclVAT := Round(AmountInclVAT - InvoiceDiscountAmount, GeneralLedgerSetup."Amount Rounding Precision");
        VATAmount := Round(TotalInclVAT * SalesLine."VAT %" / (100 + SalesLine."VAT %"), GeneralLedgerSetup."Amount Rounding Precision");
        TotalExclVAT := ROund(TotalInclVAT - VATAmount, GeneralLedgerSetup."Amount Rounding Precision");

        // Exercise: Modify Invoice Discount Amount on Statistics window using 'InvoicingSalesOrderStatisticsHandler'.
        OpenSalesOrderStatistics(SalesHeader."No.");

        // Verify: IsVerify is a global variable and Verification is done in 'InvoicingSalesOrderStatisticsHandler'.
        IsVerify := true;
        OpenSalesOrderStatistics(SalesHeader."No.");
    end;
#endif
    [Test]
    [HandlerFunctions('GeneralSalesOrderStatisticsHandlerNM')]
    [Scope('OnPrem')]
    procedure InvoiceDiscountAmountsOnSalesOrderStatisticsNM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        // Check Invoice Discount Amount on General and Invoicing tab of Sales Order Statistics window after modifying Quantity to Invoice on Sales lines.

        // Setup: Create Sales Order with Random Quantity and Unit Price.
        Initialize();
        CreateSalesOrder(SalesHeader, SalesLine);
        CreateAndModifySalesLine(SalesLine2, SalesHeader, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2));
        InvoiceDiscountAmount := SalesLine."Line Amount"; // InvoiceDiscountAmount is a global variable and is assigned to make sure discount is less than total Order amount.
        OpenSalesOrderStatisticsNM(SalesHeader."No.");

        // Exercise: Update Quantity to Invoice on Sales line.
        UpdateQtyToInvoice(SalesLine, SalesHeader."No.", SalesLine.Quantity / 2);
        UpdateQtyToInvoice(SalesLine2, SalesHeader."No.", 0);
        FindSalesLine(SalesLine, SalesHeader."No.", SalesLine."No.");

        // Calculation is done for distributed Inv. Discount Amount on Sales Lines for Invoicing.
        InvDiscountAmountInvoicing :=
          Round(
          InvoiceDiscountAmount *
            SalesLine."Qty. to Invoice" * SalesLine."Unit Price" / (SalesLine."Line Amount" + SalesLine2."Line Amount"));

        // Verify: IsVerify is a global variable and Verification is done in 'GeneralSalesOrderStatisticsHandlerNM'.
        IsVerify := true;
        OpenSalesOrderStatisticsNM(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('InvoicingSalesOrderStatisticsHandlerNM')]
    [Scope('OnPrem')]
    procedure VariousVATAmountsOnSalesOrderStatisticsNM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Check various VAT fields on Statistics window after modifying Inv. Discount Amount on Invoicing tab.

        // Setup: Create Sales Order and use Random for Inv. Discount Amount.
        Initialize();
        CreateSalesDocumentWithVAT(SalesHeader, SalesLine);
        UpdateQtyToInvoice(SalesLine, SalesHeader."No.", SalesLine.Quantity / 2);
        FindSalesLine(SalesLine, SalesHeader."No.", SalesLine."No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        InvoiceDiscountAmount := LibraryRandom.RandInt(10);  // InvoiceDiscountAmount is a global variable.

        // Following Global variables are used to verify on handler.
        GeneralLedgerSetup.Get();
        AmountInclVAT := Round(SalesLine."Unit Price" * SalesLine."Qty. to Invoice", GeneralLedgerSetup."Amount Rounding Precision");
        TotalInclVAT := Round(AmountInclVAT - InvoiceDiscountAmount, GeneralLedgerSetup."Amount Rounding Precision");
        VATAmount := Round(TotalInclVAT * SalesLine."VAT %" / (100 + SalesLine."VAT %"), GeneralLedgerSetup."Amount Rounding Precision");
        TotalExclVAT := Round(TotalInclVAT - VATAmount, GeneralLedgerSetup."Amount Rounding Precision");

        // Exercise: Modify Invoice Discount Amount on Statistics window using 'InvoicingSalesOrderStatisticsHandlerNM'.
        OpenSalesOrderStatisticsNM(SalesHeader."No.");

        // Verify: IsVerify is a global variable and Verification is done in 'InvoicingSalesOrderStatisticsHandlerNM'.
        IsVerify := true;
        OpenSalesOrderStatisticsNM(SalesHeader."No.");
    end;

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Inv Discount by Currency");
        Clear(InvoiceDiscountAmount);
        Clear(InvDiscountAmountInvoicing);
        Clear(AmountInclVAT);
        Clear(TotalInclVAT);
        Clear(VATAmount);
        Clear(TotalExclVAT);
        Clear(IsVerify);
        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Inv Discount by Currency");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Inv Discount by Currency");
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; CurrencyCode: Code[10]; DocumentType: Enum "Purchase Document Type"): Code[20]
    var
        Counter: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendor(CurrencyCode));

        // Create multiple Purchase Lines. Make sure that No. of Lines always greater than 2 to better Testability.
        for Counter := 1 to 1 + LibraryRandom.RandInt(8) do begin
            // Required Random Value for Quantity field value is not important.
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(),
              LibraryRandom.RandDec(100, 2));

            if PurchaseLine."Document Type" = PurchaseLine."Document Type"::"Credit Memo" then
                PurchaseLine.Validate("Qty. to Receive", 0);  // Value not required for Purchase Credit Memo.

            // Required Random Value for "Direct Unit Cost" field value is not important.
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
            PurchaseLine.Modify(true);
        end;
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CurrencyCode: Code[10]; DocumentType: Enum "Sales Document Type"): Code[20]
    var
        Counter: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer(CurrencyCode));

        // Create multiple Sales Lines. Make sure that No. of Lines always greater than 2 to better Testability.
        for Counter := 1 to 1 + LibraryRandom.RandInt(8) do begin
            // Required Random Value for Quantity field value is not important.
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader,
              SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(100, 2));
            if SalesLine."Document Type" = SalesLine."Document Type"::"Credit Memo" then
                SalesLine.Validate("Qty. to Ship", 0); // Value not required for Sales Credit Memo.

            // Required Random Value for "Unit Price" field value is not important.
            SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
            SalesLine.Modify(true);
        end;
    end;

    local procedure CreateSalesDocumentWithVAT(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        // Create Sales Order with VAT and Price Incl. VAT.
        // Use Random values for Quantity more than 10 and Unit Price.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        ModifySalesHeaderForPriceInclVAT(SalesHeader, true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(),
          LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateVendor(CurrencyCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", CurrencyCode);
        Vendor.Modify(true);

        CreateInvoiceDiscForVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure CreateCustomer(CurrencyCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);

        CreateInvoiceDiscForCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateInvoiceDiscForVendor(Vendor: Record Vendor)
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        // Required Random Value for "Minimum Amount" and "Discount %" fields value is not important.
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, Vendor."No.", Vendor."Currency Code", LibraryRandom.RandDec(100, 2));
        VendorInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(10, 2));
        VendorInvoiceDisc.Modify(true);
    end;

    local procedure CreateInvoiceDiscForCustomer(Customer: Record Customer)
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        // Required Random Value for "Minimum Amount" and "Discount %" fields value is not important.
        LibraryERM.CreateInvDiscForCustomer(
          CustInvoiceDisc, Customer."No.", Customer."Currency Code", LibraryRandom.RandDec(100, 2));
        CustInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(10, 2));
        CustInvoiceDisc.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        Customer: Record Customer;
    begin
        // Create Customer, Item and Sales Order with one Sales line. Take random value for Quantity and Unit Price.
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateAndModifySalesLine(SalesLine, SalesHeader, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line")
    var
        Vendor: Record Vendor;
    begin
        // Create Vendor, Item and Purchase Order with one Purchase line. Take random value for Quantity and Direct Unit Cost.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        CreateAndModifyPurchaseLine(
          PurchaseLine, PurchaseHeader, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateAndModifySalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Quantity: Decimal; UnitPrice: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreateAndModifyPurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Quantity: Decimal; DirectUnitCost: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentNo: Code[20]; No: Code[20])
    begin
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange("No.", No);
        SalesLine.FindFirst();
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20]; No: Code[20])
    begin
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; GLAccountNo: Code[20])
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
    end;

    local procedure GetSalesInvDiscAmount(SalesLine: Record "Sales Line") TotalInvDiscAmount: Decimal
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type");
        SalesLine.SetRange("Sell-to Customer No.", SalesLine."Sell-to Customer No.");
        SalesLine.FindSet();
        repeat
            TotalInvDiscAmount += SalesLine."Inv. Discount Amount";
        until SalesLine.Next() = 0;
    end;

    local procedure GetPurchaseInvDiscAmount(PurchaseLine: Record "Purchase Line") TotalInvDiscAmount: Decimal
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type");
        PurchaseLine.SetRange("Buy-from Vendor No.", PurchaseLine."Buy-from Vendor No.");
        PurchaseLine.FindSet();
        repeat
            TotalInvDiscAmount += PurchaseLine."Inv. Discount Amount";
        until PurchaseLine.Next() = 0;
    end;

    local procedure ModifySalesHeaderForPriceInclVAT(var SalesHeader: Record "Sales Header"; PriceInclVAT: Boolean)
    begin
        SalesHeader.Validate("Prices Including VAT", PriceInclVAT);
        SalesHeader.Modify(true);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure OpenSalesOrderStatistics(No: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenView();
        SalesOrder.FILTER.SetFilter("No.", No);
        SalesOrder.Statistics.Invoke();
    end;
#endif
    local procedure OpenSalesOrderStatisticsNM(No: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenView();
        SalesOrder.FILTER.SetFilter("No.", No);
        SalesOrder.SalesOrderStatistics.Invoke();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the PurchaseOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    local procedure OpenPurchaseOrderStatistics(No: Code[20])
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenView();
        PurchaseOrder.FILTER.SetFilter("No.", No);
        PurchaseOrder.Statistics.Invoke();
    end;
#endif

    local procedure OpenPurchaseOrderStats(No: Code[20])
    var
        PurchaseOrder: TestPage "Purchase Order";
    begin
        PurchaseOrder.OpenView();
        PurchaseOrder.FILTER.SetFilter("No.", No);
        PurchaseOrder.PurchaseOrderStatistics.Invoke();
    end;

    local procedure UpdateQtyToShip(SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    begin
        FindSalesLine(SalesLine, DocumentNo, SalesLine."No.");
        SalesLine.Validate("Qty. to Ship", 0); // To not post the current line.
        SalesLine.Modify(true);
    end;

    local procedure UpdateQtyToReceive(PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20])
    begin
        FindPurchaseLine(PurchaseLine, DocumentNo, PurchaseLine."No.");
        PurchaseLine.Validate("Qty. to Receive", 0); // To not post the current line.
        PurchaseLine.Modify(true);
    end;

    local procedure UpdateQtyToInvoice(SalesLine: Record "Sales Line"; DocumentNo: Code[20]; QtyToInvoice: Decimal)
    begin
        FindSalesLine(SalesLine, DocumentNo, SalesLine."No.");
        SalesLine.Validate("Qty. to Invoice", QtyToInvoice);
        SalesLine.Modify(true);
    end;

    local procedure VerifyInvoiceDiscForVendor(PurchaseLine: Record "Purchase Line"; LineAmount: Decimal)
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
        Currency: Record Currency;
        InvDiscountAmount: Decimal;
    begin
        PurchaseLine.Get(PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.");
        VendorInvoiceDisc.SetRange(Code, PurchaseLine."Buy-from Vendor No.");
        VendorInvoiceDisc.SetRange("Currency Code", PurchaseLine."Currency Code");
        VendorInvoiceDisc.FindFirst();
        Currency.Get(PurchaseLine."Currency Code");
        Currency.InitRoundingPrecision();
        InvDiscountAmount := GetPurchaseInvDiscAmount(PurchaseLine);
        Assert.AreNearlyEqual(
          LineAmount * VendorInvoiceDisc."Discount %" / 100, InvDiscountAmount, Currency."Amount Rounding Precision",
          StrSubstNo(InvoiceDiscountError, InvDiscountAmount));
    end;

    local procedure VerifyInvoiceDiscForCustomer(SalesLine: Record "Sales Line"; LineAmount: Decimal)
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        Currency: Record Currency;
        InvDiscountAmount: Decimal;
    begin
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        CustInvoiceDisc.SetRange(Code, SalesLine."Sell-to Customer No.");
        CustInvoiceDisc.SetRange("Currency Code", SalesLine."Currency Code");
        CustInvoiceDisc.FindFirst();
        Currency.Get(SalesLine."Currency Code");
        Currency.InitRoundingPrecision();
        InvDiscountAmount := GetSalesInvDiscAmount(SalesLine);
        Assert.AreNearlyEqual(
          LineAmount * CustInvoiceDisc."Discount %" / 100, InvDiscountAmount, Currency."Amount Rounding Precision",
          StrSubstNo(InvoiceDiscountError, InvDiscountAmount));
    end;

    local procedure VerifySalesLineInvDiscAmount(DocumentNo: Code[20]; ItemNo: Code[20]; InvDiscountAmount: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, DocumentNo, ItemNo);
        Assert.AreNearlyEqual(
          InvDiscountAmount, SalesLine."Inv. Discount Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(InvoiceDiscountError, InvDiscountAmount));
    end;

    local procedure VerifyPurchLineInvDiscAmount(DocumentNo: Code[20]; ItemNo: Code[20]; InvDiscountAmount: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        FindPurchaseLine(PurchaseLine, DocumentNo, ItemNo);
        Assert.AreNearlyEqual(
          InvDiscountAmount, PurchaseLine."Inv. Discount Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(InvoiceDiscountError, InvDiscountAmount));
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GeneralSalesOrderStatisticsHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        if IsVerify then begin
            Assert.AreEqual(
              InvoiceDiscountAmount, SalesOrderStatistics.InvDiscountAmount_General.AsDecimal(),
              StrSubstNo(InvoiceDiscountError, InvoiceDiscountAmount));
            Assert.AreEqual(
              InvDiscountAmountInvoicing, SalesOrderStatistics.InvDiscountAmount_Invoicing.AsDecimal(),
              StrSubstNo(InvoiceDiscountError, InvDiscountAmountInvoicing));
        end else begin
            SalesOrderStatistics.InvDiscountAmount_General.SetValue(InvoiceDiscountAmount);
            SalesOrderStatistics.OK().Invoke();
        end;
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure GeneralSalesOrderStatisticsHandlerNM(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        if IsVerify then begin
            Assert.AreEqual(
              InvoiceDiscountAmount, SalesOrderStatistics.InvDiscountAmount_General.AsDecimal(),
              StrSubstNo(InvoiceDiscountError, InvoiceDiscountAmount));
            Assert.AreEqual(
              InvDiscountAmountInvoicing, SalesOrderStatistics.InvDiscountAmount_Invoicing.AsDecimal(),
              StrSubstNo(InvoiceDiscountError, InvDiscountAmountInvoicing));
        end else begin
            SalesOrderStatistics.InvDiscountAmount_General.SetValue(InvoiceDiscountAmount);
            SalesOrderStatistics.OK().Invoke();
        end;
    end;

#if not CLEAN26
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    begin
        PurchaseOrderStatistics.InvDiscountAmount_General.SetValue(InvoiceDiscountAmount);
        PurchaseOrderStatistics.OK().Invoke();
    end;
#endif

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseOrderStatisticsPageHandler(var PurchaseOrderStatistics: TestPage "Purchase Order Statistics")
    begin
        PurchaseOrderStatistics.InvDiscountAmount_General.SetValue(InvoiceDiscountAmount);
        PurchaseOrderStatistics.OK().Invoke();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure InvoicingSalesOrderStatisticsHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        if IsVerify then begin
            SalesOrderStatistics.AmountInclVAT_Invoicing.AssertEquals(AmountInclVAT);
            SalesOrderStatistics.TotalInclVAT_Invoicing.AssertEquals(TotalInclVAT);
            SalesOrderStatistics.VATAmount_Invoicing.AssertEquals(VATAmount);
            SalesOrderStatistics.TotalExclVAT_Invoicing.AssertEquals(TotalExclVAT);
        end else begin
            SalesOrderStatistics.InvDiscountAmount_Invoicing.SetValue(InvoiceDiscountAmount);
            SalesOrderStatistics.OK().Invoke();
        end;
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure InvoicingSalesOrderStatisticsHandlerNM(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    begin
        if IsVerify then begin
            SalesOrderStatistics.AmountInclVAT_Invoicing.AssertEquals(AmountInclVAT);
            SalesOrderStatistics.TotalInclVAT_Invoicing.AssertEquals(TotalInclVAT);
            SalesOrderStatistics.VATAmount_Invoicing.AssertEquals(VATAmount);
            SalesOrderStatistics.TotalExclVAT_Invoicing.AssertEquals(TotalExclVAT);
        end else begin
            SalesOrderStatistics.InvDiscountAmount_Invoicing.SetValue(InvoiceDiscountAmount);
            SalesOrderStatistics.OK().Invoke();
        end;
    end;

}