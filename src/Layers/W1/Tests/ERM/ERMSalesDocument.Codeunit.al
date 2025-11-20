codeunit 134385 "ERM Sales Document"
{
    EventSubscriberInstance = Manual;
    Permissions = TableData "Cust. Ledger Entry" = rimd,
                  TableData "Vendor Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryKitting: Codeunit "Library - Kitting";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        ArchiveManagement: Codeunit ArchiveManagement;
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryTemplates: Codeunit "Library - Templates";
        LibraryDimension: Codeunit "Library - Dimension";
        isInitialized: Boolean;
        ItemTrackingMode: Option " ",AssignLotNo,SelectEntries,AssignSerialNo,ApplyFromItemEntry,AssignAutoSerialNo,AssignAutoLotAndSerialNo,AssignManualLotNo,AssignManualTwoLotNo,AssignTwoLotNo,SelectEntriesForMultipleLines,UpdateQty,PartialAssignManualTwoLotNo;
        VATAmountError: Label 'VAT %1 must be %2 in %3.';
        FieldError: Label '%1 must be %2 in %3.';
        DiscountError: Label 'Discount Amount must be equal to %1.';
        PostError: Label 'The total amount for the invoice must be 0 or greater.';
        SalesCaption: Label 'Total Sales';
        ValidateError: Label '%1 must be %2 in %3 %4 = %5.';
        ColumnWrongVisibilityErr: Label 'Column[%1] has wrong visibility';
        CopyDocForReturnOrderMsg: Label 'One or more return document lines were not copied. This is because quantities on the posted';
        ColumnCaptionErr: Label 'Column Caption must match.';
        UpdateBinCodeErr: Label 'Bin Code should not be updated';
        CopyDocDateOrderConfirmMsg: Label 'The Posting Date of the copied document is different from the Posting Date of the original document. The original document already has a Posting No. based on a number series with date order. When you post the copied document, you may have the wrong date order in the posted documents.\Do you want to continue?';
        DocumentShouldNotBeCopiedErr: Label 'Document should not be copied';
        DocumentShouldBeCopiedErr: Label 'Document should be copied';
        WrongConfirmationMsgErr: Label 'Wrong confirmation message';
        TestFieldTok: Label 'TestField';
        VATBusPostingGroupErr: Label 'VAT Bus. Posting Group must be equal to';
        HandlingTimeErr: Label 'Wrong Outbound Whse. Handling Time';
        GenProdPostingGroupErr: Label '%1 is not set for the %2 G/L account with no. %3.', Comment = '%1 - caption Gen. Prod. Posting Group; %2 - G/L Account Description; %3 - G/L Account No.';
        DateFilterErr: Label 'Date Filter does not match expected value';
        AmountNotMatchedErr: Label 'Amount not matched.';
        AmountMustSameErr: Label 'Amount must be same';
        QtyHandleMustSameErr: Label 'Qty to handle must equal';
        CannotRenameItemErr: Label 'You cannot rename %1 in a %2 because it is used in Sales Document lines.';

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOrderCreation()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Check if the system allows creating a New Sales Return Order.

        // Setup.
        Initialize();

        // Exercise: Create Customer and Return Sales Order.
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", CreateCustomer());

        // Verify: Verify Sales Return Order.
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountOnReturnOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmountLine: Record "VAT Amount Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        QtyType: Option General,Invoicing,Shipping;
    begin
        // Check VAT Amount as on Sales Return Order.

        // Setup: Create Sales Return Order.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", CreateCustomer());

        // Exercise: Calculate VAT Amount and Release Sales Return Order.
        SalesLine.CalcVATAmountLines(QtyType::Invoicing, SalesHeader, SalesLine, VATAmountLine);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        SalesHeader.CalcFields(Amount);

        // Verify: Check VAT Amount on Sales Return Line.
        GeneralLedgerSetup.Get();
        Assert.AreNearlyEqual(
          SalesHeader.Amount * SalesLine."VAT %" / 100, VATAmountLine."VAT Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(VATAmountError, VATAmountLine.FieldCaption("VAT Amount"), SalesHeader.Amount * SalesLine."VAT %" / 100,
            VATAmountLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecieveandInvoiceReturnOrder()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATAmount: Decimal;
    begin
        // Create and Post Sales Return Order while verifying G/L entry, Customer Ledger Entry ,Value Entry and VAT Entry.

        // Setup: Create Sales Return Order and calculate VAT Amount.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", CreateCustomer());
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        SalesHeader.CalcFields(Amount);
        VATAmount := (SalesHeader.Amount * SalesLine."VAT %") / 100;

        // Exercise: Post Sales Return Order.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify posting of Sales Return Order, G/L Entry,Customer Ledger Entry,Value Entry and VAT Entry.
        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        VerifyGLEntry(SalesHeader."No.", VATAmount, VATPostingSetup."Sales VAT Account");
        VerifyVATEntry(SalesHeader."No.", -VATAmount);
        VerifyCustomerLedgerEntry(SalesHeader."No.", -(SalesHeader.Amount + VATAmount));
        VerifyValueEntries(SalesHeader."No.", SalesHeader.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceDiscountReturnOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InvoiceDiscountAmount: Decimal;
        DocumentNo: Code[20];
    begin
        // Check Invoice Discount on Sales Return Order and in G/L entry after posting.

        // Setup: Create Sales Return Order.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", SetInvDiscForCustomer());
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // Exercise: Calculate Invoice Discount Amount and Post Sales Return Order.
        DocumentNo := CalculateInvDiscount(SalesLine, InvoiceDiscountAmount, SalesHeader);

        // Verify: Verify Invoice Discount Amount.
        VerifyInvoiceDiscountAmount(SalesLine, -InvoiceDiscountAmount, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineDiscountReturnOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        LineAmount: Decimal;
    begin
        // Check Line Discount on Sales Return Order.

        // Setup: Create Sales Return Order.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", CreateCustomer());
        SalesLine.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);

        // Exercise: Calculate Expected Discount Amount.
        LineAmount := (SalesLine.Quantity * SalesLine."Unit Price") * ((100 - SalesLine."Line Discount %") / 100);

        // Verify: Verify Line Discount Amount.
        GeneralLedgerSetup.Get();
        Assert.AreNearlyEqual(
          LineAmount, SalesLine."Line Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(FieldError, SalesLine.FieldCaption("Line Amount"), LineAmount, SalesLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyInvoiceFromReturnOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        VATAmount: Decimal;
        DocumentNo: Code[20];
    begin
        // Check if Return Order can be applied against any document.

        // Setup: Create Sales Return Order.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, CreateCustomer());
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Create Sales Return Order needs to be created using Sales Invoice Item and Quantity.
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader2."Document Type"::"Return Order", SalesLine."Sell-to Customer No.");
        LibrarySales.CreateSalesLine(SalesLine2, SalesHeader2, SalesLine.Type::Item, SalesLine."No.", SalesLine.Quantity);

        // Exercise: Calculate Total Line Amount and Post Sales Order.
        VATAmount := -(SalesLine2."Line Amount" * (100 + SalesLine2."VAT %")) / 100;
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader2, true, true);

        // Verify: Checking Sales Credit Memo and Customer Ledger Entry
        SalesCrMemoHeader.Get(DocumentNo);
        VerifyCustomerLedgerEntry(SalesHeader2."No.", VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocationforReturnOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LocationCode: Code[10];
        OldRequireReceive: Boolean;
    begin
        // Check that Posted Credit Memo has Correct Location after Posting Sales Return Order.

        // Setup. Find Location with Require Receive with True and Create Sales Return Order.
        Initialize();
        OldRequireReceive := FindAndUpdateLocation(LocationCode, true);
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", CreateCustomer());
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Return Qty. to Receive", SalesLine.Quantity);
        SalesLine.Modify(true);

        // Exercise: Post Sales Return Order with Receive and Invoice.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify the Location on Posted Sales Credit Memo.
        VerifyLocationOnCreditMemo(SalesHeader."No.", SalesLine."Location Code");

        // Tear Down: Roll Back Location with previous state.
        FindAndUpdateLocation(LocationCode, OldRequireReceive);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CurrencyOnReturnOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Check that Currency has been posted correctly on Posted Credit Memo after Post Sales Return Order.

        // Setup: Create Sales Return Order with Currency and Random Quantity for Sales Line.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", CreateCustomer());
        SalesHeader.Validate("Currency Code", CreateCurrency());
        SalesHeader.Modify(true);
        SalesLine.Validate("Qty. to Ship", 0);  // Qty. to Ship must be 0 in Sales Return Order.

        // Exercise: Post Sales Return Order with Ship and Invoice option.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Posted Credit Memo for Currency.
        VerifyCurrencyOnPostedOrder(SalesHeader."No.", SalesHeader."Currency Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyDocumentFromReturnOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Check Copy Document Functionalities from Sales Return Order.

        // Setup: Create Sales Return Order.
        Initialize();
        SetSalesandReceivablesSetup();
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CreateCustomer());
        DocumentNo := SalesHeader."No.";

        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::"Return Order");
        SalesHeader.Insert(true);  // Using Copy Document feature need New record only without Customer.

        // Exercise: Copy Document from Sales Order to Sales Return Order.
        CopyDocument(SalesHeader, "Sales Document Type From"::Order, DocumentNo);

        // Verify: Verify Sales Line created on Sales Return Order after Copy Document from Sales Order.
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedDocumentNo: Code[20];
    begin
        // Create a Partial Sales Order and verify Quantity Shipped after posting.

        // Setup: Create Partial Sales Order.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CreateCustomer());
        ModifySalesLineQtyToShip(SalesLine);

        // Exercise: Post Partial Sales Order.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify partial Sales Order.
        VerifyPartialSalesOrder(SalesLine, PostedDocumentNo, SalesLine."Qty. to Ship");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountOnCreditMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Test VAT Amount on Sales Credit Memo.

        // 1. Setup: Find a Customer.
        Initialize();

        // 2. Exercise: Create a Sales Credit Memo.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", '');
        CreateSalesLines(SalesLine, SalesHeader);
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // 3. Verify: Verify VAT Amount on Sales Credit Memo.
        VerifyVATOnSalesCreditMemo(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesReturnOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // Test post a Sales Return Order and verify if the system is creating Sales Receipt Line, GL Entry, VAT Entry
        // Customer Ledger Entry and Value Entry.

        // 1. Setup: Create a Sales Return Order.
        Initialize();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", CreateCustomer());
        CreateSalesLines(SalesLine, SalesHeader);
        CopySalesLines(TempSalesLine, SalesLine);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        SalesHeader.CalcFields(Amount, "Amount Including VAT");

        // 2. Exercise: Post Sales Return Order as Receive and Invoice.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // 3. Verify: Verify that the Sales Receipt Line is created. Verify G/L Entry, VAT Entry, Customer Ledger Entry and Value Entry
        // for the Sales Return Order.
        VerifyPostedReturnOrderLine(TempSalesLine);
        FindSalesCrMemoHeader(SalesCrMemoHeader, SalesHeader."No.");
        VerifyGLEntryForCreditMemo(SalesCrMemoHeader."No.", SalesHeader."Amount Including VAT");
        VerifyVATEntryForCreditMemo(SalesCrMemoHeader."No.", SalesHeader."Amount Including VAT");
        VerifyLedgerEntry(SalesCrMemoHeader."No.", SalesHeader."Amount Including VAT");
        VerifyValueEntries(SalesHeader."No.", SalesHeader.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineDiscountOnCreditMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLineDiscount: Record "Sales Line Discount";
    begin
        // Test Line Discount on Sales Credit Memo.

        // 1. Setup: Setup Line Discount.
        Initialize();
        SetupLineDiscount(SalesLineDiscount);

        // 2. Exercise: Create a Sales Credit Memo.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", SalesLineDiscount."Sales Code");
        SalesLinesWithLineDiscount(SalesLine, SalesHeader, SalesLineDiscount);

        // 3. Verify: Verify Line Discount Amount on Sales Credit Memo.
        VerifyLineDiscountOnCreditMemo(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LineDiscountOnGLEntry()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        SalesLineDiscount: Record "Sales Line Discount";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PriceListLine: Record "Price List Line";
    begin
        // Test post a Sales Return Order and verify GL Entry for the Line Discount Amount.

        // 1. Setup: Setup Line Discount and create a Sales Return Order.
        Initialize();
        PriceListLine.DeleteAll();
        SetupLineDiscount(SalesLineDiscount);
        CopyFromToPriceListLine.CopyFrom(SalesLineDiscount, PriceListLine);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", SalesLineDiscount."Sales Code");
        SalesLinesWithLineDiscount(SalesLine, SalesHeader, SalesLineDiscount);
        CopySalesLines(TempSalesLine, SalesLine);

        // 2. Exercise: Post Sales Return Order as Receive and Invoice.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // 3. Verify: Verify that GL Entry exists for the Line Discount after posting Sales Return Order.
        FindSalesCrMemoHeader(SalesCrMemoHeader, SalesHeader."No.");
        Assert.AreEqual(
          SumLineDiscountAmount(TempSalesLine, SalesHeader."No."), -TotalLineDiscountInGLEntry(TempSalesLine, SalesCrMemoHeader."No."),
          StrSubstNo(DiscountError, TempSalesLine.FieldCaption("Line Discount Amount")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceDiscountOnCreditMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        // Test Invoice Discount on a Sales Credit Memo.

        // 1. Setup: Setup Invoice Discount.
        Initialize();
        SetupInvoiceDiscount(CustInvoiceDisc);

        // 2. Exercise: Create a Sales Credit Memo and calculate Invoice Discount.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustInvoiceDisc.Code);
        CreateSalesLines(SalesLine, SalesHeader);
        CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);

        // 3. Verify: Verify Invoice Discount Amount on Sales Credit Memo.
        VerifyInvoiceDiscount(SalesLine, CustInvoiceDisc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceDiscountOnGLEntry()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // Test Invoice Discount posted in GL Entry for the Sales Return Order.

        // 1. Setup: Setup Invoice Discount and create a Sales Return Order.
        Initialize();
        SetupInvoiceDiscount(CustInvoiceDisc);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", CustInvoiceDisc.Code);
        CreateSalesLines(SalesLine, SalesHeader);
        CODEUNIT.Run(CODEUNIT::"Sales-Calc. Discount", SalesLine);
        CopySalesLines(TempSalesLine, SalesLine);

        // 2. Exercise: Post the Sales Return Order as Receive and Invoice.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // 3. Verify: Verify the Invoice Discount in GL Entry for the Sales Return Order.
        FindSalesCrMemoHeader(SalesCrMemoHeader, SalesHeader."No.");
        Assert.AreEqual(
          SumInvoiceDiscountAmount(TempSalesLine, SalesHeader."No."), -TotalInvoiceDiscountInGLEntry(TempSalesLine, SalesCrMemoHeader."No."),
          StrSubstNo(DiscountError, TempSalesLine.FieldCaption("Inv. Discount Amount")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyInvoiceFromCreditMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesLine: Record "Sales Line" temporary;
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // Test apply a Sales Invoice to the Sales Credit Memo.

        // 1. Setup: Create a Sales Invoice.
        Initialize();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer());
        CreateSalesLines(SalesLine, SalesHeader);
        CopySalesLines(TempSalesLine, SalesLine);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        SalesHeader.CalcFields("Amount Including VAT");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Create a Sales Return Order using Sales Invoice Item and Quantity.
        Clear(SalesLine);
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader2."Document Type"::"Return Order", CreateCustomer());
        CreateSalesLinesFromDocument(TempSalesLine, SalesLine, SalesHeader2);

        // 2. Exercise: Post Sales Return Order as Receive and Invoice.
        LibrarySales.PostSalesDocument(SalesHeader2, true, true);

        // 3. Verify: Verify GL Entry for the Sales Return Order.
        FindSalesCrMemoHeader(SalesCrMemoHeader, SalesHeader2."No.");
        VerifyGLEntryForCreditMemo(SalesCrMemoHeader."No.", SalesHeader."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialSalesOrderVerifyGLEntry()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        GLEntry: Record "G/L Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DocumentNo: Code[20];
        TotalAmount: Decimal;
    begin
        // Check GL Entry after Posting Partial Sales Order.

        // Setup: Create and Post Sales Order with Partial Shipment.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CreateCustomer());
        ModifySalesLineQtyToShip(SalesLine);
        TotalAmount := SalesLine."Qty. to Ship" * SalesLine."Unit Price";
        TotalAmount := TotalAmount + (TotalAmount * SalesLine."VAT %" / 100);

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify GL Entry for Partial Sales Invoice.
        CustomerPostingGroup.Get(SalesHeader."Customer Posting Group");
        FindGLEntry(GLEntry, DocumentNo, CustomerPostingGroup."Receivables Account");
        GeneralLedgerSetup.Get();
        Assert.AreNearlyEqual(
          TotalAmount, GLEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(FieldError, GLEntry.FieldCaption(Amount), TotalAmount, GLEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderNegativeErrorMsg()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Check Sales Order Posting Error Message when amount is Negative.

        // Setup: Create and Post Sales Order with Partial Shipment and modify Sales Line with Negative Amount.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CreateCustomer());
        ModifySalesLineQtyToShip(SalesLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Reopen Partial Sales Order and Modify Unit price with Negative Value.
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        LibrarySales.ReopenSalesDocument(SalesHeader);
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No.");
        SalesLine.Validate("Unit Price", -SalesLine."Unit Price");
        SalesLine.Modify(true);

        // Exercise: Try to Post Sales Order with Negative Amount.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Error Message raised during Negative amount posting of Sales Order.
        Assert.AreEqual(PostError, GetLastErrorText, 'Unknown Error');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ArchieveVersionSalesOrder()
    var
        SalesLineArchive: Record "Sales Line Archive";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Check Sales Line Archive for Archive Version after Posting Partial Sales Order.

        // Setup: Create and Post Sales Order with Partial Shipment.
        Initialize();
        LibrarySales.SetArchiveOrders(true);
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CreateCustomer());
        ModifySalesLineQtyToShip(SalesLine);

        // Exercise: Post Sales Order with Ship.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Verify: Verify No. of Archived Versions fields on Sales Header and Sales Line Archive.
        // Take 1 as static because it will generate 1 on Posting of Sales Order on first time.
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        SalesHeader.CalcFields("No. of Archived Versions");
        SalesHeader.TestField("No. of Archived Versions", 1);

        SalesLineArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesLineArchive.SetRange("Document No.", SalesHeader."No.");
        SalesLineArchive.FindFirst();
        SalesLineArchive.TestField("Version No.", SalesHeader."No. of Archived Versions");
        SalesLineArchive.TestField("Qty. to Ship", SalesLine."Qty. to Ship");
        SalesLineArchive.TestField(Quantity, SalesLine.Quantity);
        SalesLineArchive.TestField("Qty. to Invoice", SalesLine."Qty. to Invoice");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithACY()
    var
        SalesLine: Record "Sales Line";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        PostedDocumentNo: Code[20];
        CurrencyCode: Code[10];
        InvoiceAmountLCY: Decimal;
    begin
        // Verify Amount on G/L Entry and Amount LCY on Customer Ledger Entry after posting Sales Invoice with ACY.

        // Setup: Create Currency and Exchange Rate. Update Inv. Rounding Precision LCY and Additional Currency on General Ledger Setup.
        // Run Additional Reporting Currency and create Customer with Currency.
        Initialize();
        CreateAdditionalCurrencySetup(CurrencyCode);
        LibraryERM.SetInvRoundingPrecisionLCY(1);  // 1 used for Inv. Rounding Precision LCY according to script.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);

        // Exercise: Create and Post Sales Invoice.
        CreateAndPostSalesDocument(SalesLine, VATPostingSetup, GeneralPostingSetup, SalesLine."Document Type"::Invoice, CurrencyCode);
        InvoiceAmountLCY := LibraryERM.ConvertCurrency(SalesLine."Line Amount", CurrencyCode, '', WorkDate());

        // Verify: Verify Amount on G/L Entry and Amount LCY on Customer Ledger Entry.
        PostedDocumentNo := FindSalesInvoiceHeaderNo(SalesLine."Document No.");
        VerifyAmountOnGLEntry(PostedDocumentNo, GeneralPostingSetup."Sales Account", -InvoiceAmountLCY);
        VerifyAmountLCYOnCustLedger(PostedDocumentNo, InvoiceAmountLCY);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RemainingPmtDiscPossibleACY()
    var
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        OldVATPercentage: Decimal;
        OldAdjustForPaymentDiscount: Boolean;
    begin
        // Verify Remaining Amount on Customer Ledger Entry after posting payment against Remaining Payment Discount Ledger Entry with ACY.

        // Setup: Create Currency and Exchange Rate. Update Additional Currency on General Ledger Setup.
        // Run Additional Reporting Currency. Find VAT Posting Setup. Create and post Sales Invoice.
        Initialize();
        CreateAdditionalCurrencySetup(CurrencyCode);
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        OldVATPercentage := UpdateVATPostingSetup(VATPostingSetup, OldAdjustForPaymentDiscount, true, LibraryRandom.RandDec(10, 2));
        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
        UpdateGeneralPostingSetup(GeneralPostingSetup, FindGLAccountNo());
        CreateAndPostSalesDocument(SalesLine, VATPostingSetup, GeneralPostingSetup, SalesLine."Document Type"::Invoice, CurrencyCode);

        // Exercise: Update Remaining Pmt. Disc. Possible on Customer Ledger Entry. Create and post payment against invoice.
        UpdateRemainingPmtDiscPossible(CustLedgerEntry, FindSalesInvoiceHeaderNo(SalesLine."Document No."));
        LibrarySales.CreatePaymentAndApplytoInvoice(
          GenJournalLine, SalesLine."Sell-to Customer No.", FindSalesInvoiceHeaderNo(SalesLine."Document No."),
          -CustLedgerEntry.Amount / 2);

        // Verify: Verify Amount on Customer Ledger Entry after posting the payment against Remaining Payment Discount Ledger Entry.
        VerifyRemainingAmountOnLedger(FindSalesInvoiceHeaderNo(SalesLine."Document No."), CustLedgerEntry."Document Type"::Invoice, 0);
        VerifyRemainingAmountOnLedger(GenJournalLine."Document No.", CustLedgerEntry."Document Type"::Payment, 0);

        // Tear down: Rollback Setup changes.
        UpdateGeneralPostingSetup(GeneralPostingSetup, '');
        UpdateVATPostingSetup(VATPostingSetup, OldAdjustForPaymentDiscount, OldAdjustForPaymentDiscount, OldVATPercentage);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPersonCodeSalesInvoice()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GLEntry: Record "G/L Entry";
        PaymentMethod: Record "Payment Method";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLAccount: Record "G/L Account";
        DocumentNo: Code[20];
        Amount: Decimal;
    begin
        // Check GL And Customer Ledger Entry for Amount and SalesPerson Code after Posting Sales Invoice.

        // Setup: Create and Post Sales Invoice with Payment Method and Sales Person Code.
        Initialize();

        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Bal. Account Type", PaymentMethod."Bal. Account Type"::"G/L Account");
        PaymentMethod.Validate("Bal. Account No.", GLAccount."No.");
        PaymentMethod.Modify();

        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, CreateCustomer());
        SalesHeader.Validate("Salesperson Code", SalespersonPurchaser.Code);
        SalesHeader.Validate("Payment Method Code", PaymentMethod.Code);
        SalesHeader.Modify(true);
        Amount := SalesLine."Line Amount" + (SalesLine."Line Amount" * SalesLine."VAT %" / 100);

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify GL and Customer Ledger Entry for Amount and SalesPerson Code.
        GeneralLedgerSetup.Get();
        FindGLEntry(GLEntry, DocumentNo, PaymentMethod."Bal. Account No.");
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(FieldError, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption()));

        FindCustLedgerEntry(CustLedgerEntry, DocumentNo, CustLedgerEntry."Document Type"::Payment);
        Assert.AreEqual(
          SalesHeader."Salesperson Code", CustLedgerEntry."Salesperson Code",
          StrSubstNo(FieldError, SalesHeader.FieldCaption("Salesperson Code"),
            SalesHeader."Salesperson Code", CustLedgerEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure YourReferenceSalesOrderToCustLedgerEntry()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        Initialize();

        // [GIVEN] Sales Order with non-empty Your Reference exists
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CreateCustomer());
        SalesHeader.Validate("Your Reference", LibraryRandom.RandText(10));
        SalesHeader.Modify(true);

        // [WHEN] The document is posted
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Cust. ledger entry with the same Your Reference is created
        FindCustLedgerEntry(CustLedgerEntry, DocumentNo, CustLedgerEntry."Document Type"::Invoice);
        Assert.AreEqual(SalesHeader."Your Reference", CustLedgerEntry."Your Reference", CustLedgerEntry.FieldCaption("Your Reference"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure YourReferenceSalesInvoiceToCustLedgerEntry()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        Initialize();

        // [GIVEN] Sales Invoice with non-empty Your Reference exists
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, CreateCustomer());
        SalesHeader.Validate("Your Reference", LibraryRandom.RandText(10));
        SalesHeader.Modify(true);

        // [WHEN] The document is posted
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Cust. ledger entry with the same Your Reference is created
        FindCustLedgerEntry(CustLedgerEntry, DocumentNo, CustLedgerEntry."Document Type"::Invoice);
        Assert.AreEqual(SalesHeader."Your Reference", CustLedgerEntry."Your Reference", CustLedgerEntry.FieldCaption("Your Reference"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure YourReferenceSalesReturnOrderToCustLedgerEntry()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        Initialize();

        // [GIVEN] Sales Order with non-empty Your Reference exists
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", CreateCustomer());
        SalesHeader.Validate("Your Reference", LibraryRandom.RandText(10));
        SalesHeader.Modify(true);

        // [WHEN] The document is posted
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Cust. ledger entry with the same Your Reference is created
        FindCustLedgerEntry(CustLedgerEntry, DocumentNo, CustLedgerEntry."Document Type"::"Credit Memo");
        Assert.AreEqual(SalesHeader."Your Reference", CustLedgerEntry."Your Reference", CustLedgerEntry.FieldCaption("Your Reference"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure YourReferenceSalesCrMemoToCustLedgerEntry()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        Initialize();

        // [GIVEN] Sales Credit Memo with non-empty Your Reference exists
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", CreateCustomer());
        SalesHeader.Validate("Your Reference", LibraryRandom.RandText(10));
        SalesHeader.Modify(true);

        // [WHEN] The document is posted
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Cust. ledger entry with the same Your Reference is created
        FindCustLedgerEntry(CustLedgerEntry, DocumentNo, CustLedgerEntry."Document Type"::"Credit Memo");
        Assert.AreEqual(SalesHeader."Your Reference", CustLedgerEntry."Your Reference", CustLedgerEntry.FieldCaption("Your Reference"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerStatisticsYearToDate()
    var
        Customer: Record Customer;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        CustomerStatisticsFactBox: TestPage "Customer Statistics FactBox";
    begin
        // Verify that program should show those value on YTD which one is posted in Current year and the
        // caption as Total Sales (LCY) in Customer Statistics-Bill to Customer Fact Box on Customer Card.

        // Setup: Create Customer, select General Journal Batch, post 2 general journal lines one for the current year and other
        // for previous year.
        Initialize();
        CreateAccountingPeriod();
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, Customer."No.", LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Posting Date", CalcDate('<-1Y>', WorkDate()));
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type",
          GenJournalLine."Account Type", GenJournalLine."Account No.", GenJournalLine.Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise.
        CustomerStatisticsFactBox.OpenView();
        CustomerStatisticsFactBox.FILTER.SetFilter("No.", Customer."No.");

        // Verify: Verify that Sales(LCY) contains value of current year sales and caption as Total Sales (LCY) on Customer Statistics FactBox.
        Assert.AreEqual(
          Format(GenJournalLine.Amount), CustomerStatisticsFactBox."Sales (LCY)".Value,
          StrSubstNo(FieldError, Customer.FieldCaption("Sales (LCY)"),
            Format(GenJournalLine.Amount), CustomerStatisticsFactBox.Caption));
        Assert.IsTrue(
          StrPos(CustomerStatisticsFactBox."Sales (LCY)".Caption, StrSubstNo(SalesCaption)) = 1,
          StrSubstNo(
            FieldError, CustomerStatisticsFactBox."Sales (LCY)".Caption, SalesCaption, CustomerStatisticsFactBox."Sales (LCY)".Caption));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithACY()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GeneralPostingSetup: Record "General Posting Setup";
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        VATAmountLCY: Decimal;
    begin
        // Verify Amount and Additional Currency Amount on G/L Entry and Amount LCY on Customer Ledger Entry after
        // posting Sales Credit Memo with ACY.

        // Setup: Create Currency and Exchange Rate. Update Additional Currency on General Ledger Setup.
        // Run Additional Reporting Currency and create Customer with Currency. Create Sales Credit Memo.
        Initialize();
        CreateAdditionalCurrencySetup(CurrencyCode);
        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", CreateCustomer());

        // Exercise: Post Sales Credit Memo.
        VATAmountLCY := SalesLine."Line Amount" * SalesLine."VAT %" / 100;
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Amount on G/L Entry and Amount LCY on Customer Ledger Entry.
        DocumentNo := FindSalesCreditMemoHeaderNo(SalesLine."Document No.");
        VerifyACYAmountOnGLEntry(DocumentNo, GeneralPostingSetup."Sales Credit Memo Account", SalesLine."Line Amount", CurrencyCode);
        VerifyAmountLCYOnCustLedger(DocumentNo, -(SalesLine."Line Amount" + VATAmountLCY));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoWithPaymentDisc()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        OldAdjustForPaymentDisc: Boolean;
        DocumentNo: Code[20];
        OldVATPercentage: Decimal;
        VATAmountLCY: Decimal;
    begin
        // Verify Amount on G/L Entry and Amount LCY on Customer Ledger Entry after posting Sales Credit Memo with Adjust for Payment Disc.

        // Setup: Update Additional Currency on General Ledger Setup. Create Sales Credit Memo.
        Initialize();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        OldVATPercentage := UpdateVATPostingSetup(VATPostingSetup, OldAdjustForPaymentDisc, true, LibraryRandom.RandDec(10, 2));
        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
        UpdateGeneralPostingSetup(GeneralPostingSetup, FindGLAccountNo());

        // Exercise: Create and Post Sales Invoice.
        CreateAndPostSalesDocument(SalesLine, VATPostingSetup, GeneralPostingSetup, SalesHeader."Document Type"::"Credit Memo", '');
        VATAmountLCY := SalesLine."Line Amount" * SalesLine."VAT %" / 100;

        // Verify: Verify Amount on G/L Entry and Amount LCY on Customer Ledger Entry.
        DocumentNo := FindSalesCreditMemoHeaderNo(SalesLine."Document No.");
        VerifyAmountOnGLEntry(DocumentNo, GeneralPostingSetup."Sales Credit Memo Account", SalesLine."Line Amount");
        VerifyAmountLCYOnCustLedger(DocumentNo, -(SalesLine."Line Amount" + VATAmountLCY));

        // Tear down: Rollback Setup changes.
        UpdateVATPostingSetup(VATPostingSetup, OldAdjustForPaymentDisc, OldAdjustForPaymentDisc, OldVATPercentage);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithPaymentDisc()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        OldAdjustForPaymentDisc: Boolean;
        DocumentNo: Code[20];
        OldVATPercentage: Decimal;
        VATAmountLCY: Decimal;
    begin
        // Verify Amount on G/L Entry and Amount LCY on Customer Ledger Entry after posting Sales Invoice with Adjust for Payment Disc.

        // Setup: Update Additional Currency on General Ledger Setup. Create Sales Credit Memo.
        Initialize();
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        OldVATPercentage := UpdateVATPostingSetup(VATPostingSetup, OldAdjustForPaymentDisc, true, LibraryRandom.RandDec(10, 2));
        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
        UpdateGeneralPostingSetup(GeneralPostingSetup, FindGLAccountNo());

        // Exercise: Create and Post Sales Invoice.
        CreateAndPostSalesDocument(SalesLine, VATPostingSetup, GeneralPostingSetup, SalesHeader."Document Type"::Invoice, '');
        VATAmountLCY := SalesLine."Line Amount" * SalesLine."VAT %" / 100;

        // Verify: Verify Amount on G/L Entry and Amount LCY on Customer Ledger Entry.
        DocumentNo := FindSalesInvoiceHeaderNo(SalesLine."Document No.");
        VerifyAmountOnGLEntry(DocumentNo, GeneralPostingSetup."Sales Account", -SalesLine."Line Amount");
        VerifyAmountLCYOnCustLedger(DocumentNo, SalesLine."Line Amount" + VATAmountLCY);

        // Tear down: Rollback Setup changes.
        UpdateVATPostingSetup(VATPostingSetup, OldAdjustForPaymentDisc, OldAdjustForPaymentDisc, OldVATPercentage);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesShipmentInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verifying that the posted Sales Shipment and posted Sales invoice have been created after posting.

        // Setup: Create Sales Order.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CreateCustomer());

        // Exercise: Post Sales Order.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Purchase Order.
        VerifySalesShipmentLine(SalesLine, FindShipmentHeaderNo(SalesHeader."No."));
        VerifySalesInvoiceLine(SalesLine, FindPostedSalesInvoiceNo(SalesHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesLine: Record "Sales Line";
        xSalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceNo: Code[20];
    begin
        // [SCENARIO] A Posted Sales Invoice is Updated
        // [GIVEN] A Sales Invoice exists
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CreateCustomer());
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesInvoiceNo := FindPostedSalesInvoiceNo(SalesHeader."No.");
        xSalesInvoiceHeader.Get(SalesInvoiceNo);

        // [WHEN] A Sales Invoice Header is Updated
        LibrarySales.ModifySalesInvoiceHeader(xSalesInvoiceHeader);
        LibrarySales.UpdateSalesInvoiceHeader(xSalesInvoiceHeader);

        // [THEN] The Sales Invoice is updated with the new values
        SalesInvoiceHeader.Get(SalesInvoiceNo);
        //        ValidateError: Label '%1 must be %2 in %3 %4 = %5.';
        Assert.AreEqual(SalesInvoiceHeader."Payment Method Code", xSalesInvoiceHeader."Payment Method Code",
            StrSubstNo(ValidateError,
                SalesInvoiceHeader.FieldCaption("Payment Method Code"),
                xSalesInvoiceHeader."Payment Method Code",
                SalesInvoiceHeader.TableCaption(),
                SalesInvoiceHeader.FieldCaption("No."),
                SalesInvoiceHeader."No."));

        Assert.AreEqual(SalesInvoiceHeader."Payment Reference", xSalesInvoiceHeader."Payment Reference",
            StrSubstNo(ValidateError,
                SalesInvoiceHeader.FieldCaption("Payment Reference"),
                xSalesInvoiceHeader."Payment Reference",
                SalesInvoiceHeader.TableCaption(),
                SalesInvoiceHeader.FieldCaption("No."),
                SalesInvoiceHeader."No."));

        Assert.AreEqual(SalesInvoiceHeader."Company Bank Account Code", xSalesInvoiceHeader."Company Bank Account Code",
            StrSubstNo(ValidateError,
                SalesInvoiceHeader.FieldCaption("Company Bank Account Code"),
                xSalesInvoiceHeader."Company Bank Account Code",
                SalesInvoiceHeader.TableCaption(),
                SalesInvoiceHeader.FieldCaption("No."),
                SalesInvoiceHeader."No."));

        Assert.AreEqual(SalesInvoiceHeader."Posting Description", xSalesInvoiceHeader."Posting Description",
            StrSubstNo(ValidateError,
                SalesInvoiceHeader.FieldCaption("Posting Description"),
                xSalesInvoiceHeader."Posting Description",
                SalesInvoiceHeader.TableCaption(),
                SalesInvoiceHeader.FieldCaption("No."),
                SalesInvoiceHeader."No."));

        Assert.AreEqual(SalesInvoiceHeader."Shipping Agent Code", xSalesInvoiceHeader."Shipping Agent Code",
            StrSubstNo(ValidateError,
                SalesInvoiceHeader.FieldCaption("Shipping Agent Code"),
                xSalesInvoiceHeader."Shipping Agent Code",
                SalesInvoiceHeader.TableCaption(),
                SalesInvoiceHeader.FieldCaption("No."),
                SalesInvoiceHeader."No."));

        Assert.AreEqual(SalesInvoiceHeader."Package Tracking No.", xSalesInvoiceHeader."Package Tracking No.",
            StrSubstNo(ValidateError,
                SalesInvoiceHeader.FieldCaption("Package Tracking No."),
                xSalesInvoiceHeader."Package Tracking No.",
                SalesInvoiceHeader.TableCaption(),
                SalesInvoiceHeader.FieldCaption("No."),
                SalesInvoiceHeader."No."));

        Assert.AreEqual(SalesInvoiceHeader."Shipping Agent Service Code", xSalesInvoiceHeader."Shipping Agent Service Code",
            StrSubstNo(ValidateError,
                SalesInvoiceHeader.FieldCaption("Shipping Agent Service Code"),
                xSalesInvoiceHeader."Shipping Agent Service Code",
                SalesInvoiceHeader.TableCaption(),
                SalesInvoiceHeader.FieldCaption("No."),
                SalesInvoiceHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesRetOrderReceiptCreditMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verifying that the posted Return receipt and posted Sales Credit Memo have been created after posting Sales Return order.

        // Setup: Create Sales Return Order.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", CreateCustomer());

        // Exercise: Post Sales Return Order.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Sales Return Order.
        VerifyReturnReceiptLine(SalesLine, FindReturnReceiptHeaderNo(SalesHeader."No."));
        VerifySalesCrMemoLine(SalesLine, FindSalesCrMemoHeaderNo(SalesHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceiveSalesReturnOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Verify Item Ledger Entry after receiving the Sales Return Order.

        // Setup. Create Sales Return Order.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", CreateCustomer());

        // Exercise: Receive Sales Return Order.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Verify: Verify Item Ledger Entry.
        VerifyItemLedgerEntry(DocumentNo, SalesLine."No.", SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('GetReturnReceiptHandler')]
    [Scope('OnPrem')]
    procedure UnitPriceInclVATOnSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        UnitPriceInclVAT: Decimal;
    begin
        // Check Unit Price Incl VAT field in Sales Credit Memo Line created by using the function Get Return Recipt lines When Price
        // Including VAT is True.

        // Setup: Create Sales Return Order and create Sales Credit Memo.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", CreateCustomer());
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader2."Document Type"::"Credit Memo", SalesHeader."Sell-to Customer No.");
        SalesHeader2.Validate("Prices Including VAT", true);
        SalesHeader2.Modify(true);
        SalesLine2.Validate("Document Type", SalesHeader2."Document Type");
        SalesLine2.Validate("Document No.", SalesHeader2."No.");
        UnitPriceInclVAT := SalesLine."Unit Price" + SalesLine."Unit Price" * SalesLine."VAT %" / 100;

        // Exercise.
        CODEUNIT.Run(CODEUNIT::"Sales-Get Return Receipts", SalesLine2);

        // Verify: Verify Unit Price Incl VAT field in Sales Credit Memo Line.
        SalesLine2.SetRange("Document Type", SalesHeader2."Document Type");
        SalesLine2.SetRange("Document No.", SalesHeader2."No.");
        SalesLine2.SetRange("No.", SalesLine."No.");
        SalesLine2.FindFirst();
        Assert.AreNearlyEqual(
          UnitPriceInclVAT, SalesLine2."Unit Price", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(FieldError, SalesLine.FieldCaption("Unit Price"), UnitPriceInclVAT, SalesLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PostedSalesDocumentLinesHandler')]
    [Scope('OnPrem')]
    procedure CheckStandardTextLineOnSalesReturnOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesHeader2: Record "Sales Header";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // Verify Standard Text Line on Sales Return Order.

        // Setup: Create Sales Order with Standard Text Code Line.
        Initialize();
        CreateAndPostSalesOrderWithStandardTextLine(SalesHeader, SalesLine);
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader2."Document Type"::"Return Order", SalesHeader."Sell-to Customer No.");
        LibraryVariableStorage.Enqueue(SalesLine."No.");

        // Exercise: Doing GetPostedDocumentLinesToReverse on Sales Return Order.
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.FILTER.SetFilter("No.", SalesHeader2."No.");
        SalesReturnOrder.GetPostedDocumentLinesToReverse.Invoke();

        // Verify: Verify Sales Line exist with Standard Text Code without any error.
        VerifySalesLine(SalesHeader2, SalesLine."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesLineStdTextOnModifySellToCustomerNo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 360323] Sales line with Standard Text type is not deleted when 'Sell-To Customer No.' changed
        Initialize();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());

        // [GIVEN] Create Sales Order header with Customer = 'A'
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CreateCustomer());
        // [GIVEN] Add a Sales Line of Standard Text
        CreateStandardTextLine(SalesLine, SalesHeader);

        // [WHEN] Modify 'Sell-To Customer No.' to 'B' on Sales Header.
        SalesHeader.Validate("Sell-to Customer No.", CreateCustomer());

        // [THEN] Sales line with Standard Text still exists
        SalesLine.SetRange(Type, SalesLine.Type::" ");
        SalesLine.SetRange("No.", SalesLine."No.");
        SalesLine.FindFirst();
    end;

    [Test]
    [HandlerFunctions('CombineShipmentRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PaymentDiscountPercentAfterRunningCombineShipment()
    var
        SalesHeader: array[2] of Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        Counter: Integer;
    begin
        // Test Payment Discount % on Sales Invoice after running Combine Shipments Report.

        // Setup: Create and Post Sales Orders as Ship with Payment Terms Code having Payment Discount % more than Zero.
        Initialize();
        for Counter := 1 to 2 do
            CreateAndPostSalesOrderWithPaymentTerms(SalesHeader[Counter]);

        // Exercise: Run Combine Shipments Report.
        SalesHeader2.SetFilter(
          "Sell-to Customer No.", '%1|%2', SalesHeader[1]."Sell-to Customer No.", SalesHeader[2]."Sell-to Customer No.");
        REPORT.Run(REPORT::"Combine Shipments", true, false, SalesHeader2);

        // Verify: Verify PaymentTerms Discount % on Created Sales Invoice.
        for Counter := 1 to 2 do
            VerifyPaymentDiscountOnSalesInvoice(SalesHeader[Counter]);
    end;

    [Test]
    [HandlerFunctions('EditAnalysisReportSaleRequestPageHandler,SaleAnalysisMatrixRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesAnalysisReportWithItemLedgerEntryTypeSales()
    var
        AnalysisColumn: Record "Analysis Column";
        AnalysisReportName: Record "Analysis Report Name";
        ItemAnalysisView: Record "Item Analysis View";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ValueEntry: Record "Value Entry";
        AnalysisLine: Record "Analysis Line";
    begin
        // Check Cost Amount(Expected) on Sales Analysis Matrix when Item Ledger Entry Type Filter Sales.

        // Setup: Post Sales Document with Ship Option and Create Analysis Report Name.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CreateCustomer());
        FindValueEntry(ValueEntry, SalesHeader."Document Type"::Order, LibrarySales.PostSalesDocument(SalesHeader, true, false));
        LibraryVariableStorage.Enqueue(ValueEntry."Cost Amount (Expected)");
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Sales);
        LibraryInventory.CreateAnalysisReportName(AnalysisReportName, ItemAnalysisView."Analysis Area");

        // Exercise: Open Analysis Report Sales with Correct filter Item Ledger Entry Type Sales.
        OpenAnalysisReportSales(
          AnalysisReportName.Name,
          CreateAnalysisLine(ItemAnalysisView."Analysis Area", AnalysisLine.Type::Customer, SalesHeader."Sell-to Customer No."),
          CreateAnalysisColumnWithItemLedgerEntryType(ItemAnalysisView."Analysis Area",
            Format(ValueEntry."Item Ledger Entry Type"::Sale), AnalysisColumn."Value Type"::"Cost Amount"));

        // Verify: Verification done in PurchaseAnalysisMatrixRequestPageHandler.
    end;

    [Test]
    [HandlerFunctions('SalesAnalysisReportSaleRequestPageHandler,SalesAnalysisMatrixRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesAnalysisReportWithSourceNoFilter()
    var
        AnalysisColumn: Record "Analysis Column";
        AnalysisReportName: Record "Analysis Report Name";
        Item: Record Item;
        AnalysisLine: Record "Analysis Line";
        ValueEntry: Record "Value Entry";
        AnalysisLineTemplateName: Code[10];
        AnalysisColumnTemplateName: Code[10];
    begin
        // Check Sales Analysis Matrix open succefully when selecting the Source Type Filter And Source Number.

        // Setup: Create Analysis Report Name.
        Initialize();
        LibraryInventory.CreateAnalysisReportName(AnalysisReportName, AnalysisReportName."Analysis Area"::Sales);
        AnalysisLineTemplateName := CreateAnalysisLine(AnalysisLine."Analysis Area"::Sales,
            AnalysisLine.Type::Item, LibraryInventory.CreateItem(Item));
        AnalysisColumnTemplateName := CreateAnalysisColumnWithItemLedgerEntryType(AnalysisReportName."Analysis Area"::Sales,
            Format(ValueEntry."Item Ledger Entry Type"::Sale), AnalysisColumn."Value Type"::"Cost Amount");
        EnqueueAnalysisColumnHeader(AnalysisColumnTemplateName);

        // Exercise: Open Analysis Report Sales with Correct filter Item Ledger Entry Type Sales.
        OpenAnalysisReportSales(AnalysisReportName.Name, AnalysisLineTemplateName, AnalysisColumnTemplateName);

        // Verify: Verification done in AnalysisReportSaleRequestPageHandler.
    end;

    [Test]
    [HandlerFunctions('EditAnalysisReportSaleRequestPageHandler,SaleAnalysisMatrixRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesAnalysisReportWithItemLedgerEntryTypePurchaseAndValueTypeSale()
    var
        AnalysisColumn: Record "Analysis Column";
        ValueEntry: Record "Value Entry";
    begin
        // Check Sales Amount on Sales Analysis Matrix when Item Ledger Entry Type Filter Purchase.
        SalesAnalysisReportWithItemLedgerEntryTypeAndValueType(AnalysisColumn."Value Type"::"Sales Amount",
          ValueEntry."Item Ledger Entry Type"::Purchase);
    end;

    [Test]
    [HandlerFunctions('EditAnalysisReportSaleRequestPageHandler,SaleAnalysisMatrixRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesAnalysisReportWithItemLedgerEntryTypePurchaseAndValueTypeCost()
    var
        AnalysisColumn: Record "Analysis Column";
        ValueEntry: Record "Value Entry";
    begin
        // Check Cost Amount(Expected) on Sales Analysis Matrix when Item Ledger Entry Type Filter Purchase.
        SalesAnalysisReportWithItemLedgerEntryTypeAndValueType(AnalysisColumn."Value Type"::"Cost Amount",
          ValueEntry."Item Ledger Entry Type"::Purchase);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDefaultBinOnSalesLine()
    var
        Item: Record Item;
        Bin: Record Bin;
        SalesLine: Record "Sales Line";
    begin
        // Verify that bin code exist on sales order line,when re-enter the item no removes the default bin.

        // Setup: Create sales document with bin & bin content.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateBinAndBinContent(Bin, CreateLocationWithBinMandatory(), Item."No.", Item."Base Unit of Measure", true); // True for Default Bin.
        CreateSalesDocumentWithLocation(SalesLine, SalesLine."Document Type"::Order, Item."No.", Bin."Location Code");

        // Exercise: Re-enter Item No on sales line.
        SalesLine.Validate("No.", Item."No.");

        // Verify: Verifying bin code exist. on sales line.
        SalesLine.TestField("Bin Code", Bin.Code);
    end;

    [Test]
    [HandlerFunctions('EditAnalysisReportSaleRequestPageHandler,SaleAnalysisMatrixColumnsRPH')]
    [Scope('OnPrem')]
    procedure SalesAnalysisReportMultipleColumns()
    var
        AnalysisColumn: Record "Analysis Column";
        AnalysisReportName: Record "Analysis Report Name";
        ItemAnalysisView: Record "Item Analysis View";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AnalysisLine: Record "Analysis Line";
        ValueEntry: Record "Value Entry";
        SalesAnalysisMatrix: Page "Sales Analysis Matrix";
    begin
        // Check columns' visibility in matrix form for count greater 7. regarding to RFH 344803

        // Setup: Post Sales Document with Ship Option and Create Analysis Report Name.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CreateCustomer());
        FindValueEntry(ValueEntry, SalesHeader."Document Type"::Order, LibrarySales.PostSalesDocument(SalesHeader, true, false));
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Sales);
        LibraryInventory.CreateAnalysisReportName(AnalysisReportName, ItemAnalysisView."Analysis Area");

        // Exercise: Open Analysis Report Sales with Correct filter Item Ledger Entry Type Sales.
        OpenAnalysisReportSales(AnalysisReportName.Name,
          CreateAnalysisLine(
            ItemAnalysisView."Analysis Area", AnalysisLine.Type::Customer, SalesHeader."Sell-to Customer No."),
          CreateAnalysisMultipleColumns(
            ItemAnalysisView."Analysis Area",
            Format(ValueEntry."Item Ledger Entry Type"::Sale),
            AnalysisColumn."Value Type"::"Cost Amount", SalesAnalysisMatrix.GetMatrixDimension()));

        // Verify: Verification done in SaleAnalysisMatrixColumnsRPH.
    end;

    [Test]
    [HandlerFunctions('SaleAnalysisMatrixRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesAnalysisReportRoundingFactorNone()
    var
        AnalysisReportName: Record "Analysis Report Name";
        SalesAnalysisReport: TestPage "Sales Analysis Report";
        AnalysisLineTemplateName: Code[10];
        AnalysisColumnTemplateName: Code[10];
        CustomerNo: Code[20];
        ItemNo: Code[20];
        RoundingFactor: Integer;
        Amount: Decimal;
    begin
        // [FEATURE] [Sale Analysis Matrix]
        // [SCENARIO 121960] Cost Amount cell in Sales Analysis Matrix with Rounding Factor = None.
        Initialize();
        RoundingFactor := 0;

        // [GIVEN] Analysis Report with Analysis Line and Analysis Column with Rounding Factor = None
        CreateAnalysisReport(
          AnalysisReportName, AnalysisLineTemplateName, AnalysisColumnTemplateName, ItemNo, RoundingFactor);
        // [GIVEN] Value Entry with Decimal Amount = "X"
        Amount := CreateValueEntry(ItemNo, CustomerNo);
        LibraryVariableStorage.Enqueue(RoundCostAmount(Amount, RoundingFactor));

        // [GIVEN] Opened Analysis Report Sale Page
        AnalysisReportSalePageOpen(
          SalesAnalysisReport, AnalysisReportName, AnalysisLineTemplateName, AnalysisColumnTemplateName);
        // [WHEN] Open Sales Analysis Matrix Page
        SalesAnalysisReportPageShowMatrix(SalesAnalysisReport, CustomerNo);

        // [THEN] Cost Amount = "X" has the same value in Overview Page
        // Verification done in handler SaleAnalysisMatrixRequestPageHandler
    end;

    [Test]
    [HandlerFunctions('SaleAnalysisMatrixRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesAnalysisReportRoundingFactor1()
    var
        AnalysisReportName: Record "Analysis Report Name";
        SalesAnalysisReport: TestPage "Sales Analysis Report";
        AnalysisLineTemplateName: Code[10];
        AnalysisColumnTemplateName: Code[10];
        CustomerNo: Code[20];
        ItemNo: Code[20];
        RoundingFactor: Integer;
        Amount: Decimal;
    begin
        // [FEATURE] [Sale Analysis Matrix]
        // [SCENARIO 121960] Cost Amount cell in Sales Analysis Matrix with Rounding Factor = 1.
        Initialize();
        RoundingFactor := 1;

        // [GIVEN] Analysis Report with Analysis Line and Analysis Column with Rounding Factor = 1
        CreateAnalysisReport(
          AnalysisReportName, AnalysisLineTemplateName, AnalysisColumnTemplateName, ItemNo, RoundingFactor);
        // [GIVEN] Value Entry with Decimal Amount = "X"
        Amount := CreateValueEntry(ItemNo, CustomerNo);
        LibraryVariableStorage.Enqueue(RoundCostAmount(Amount, RoundingFactor));

        // [GIVEN] Opened Analysis Report Sale Page
        AnalysisReportSalePageOpen(
          SalesAnalysisReport, AnalysisReportName, AnalysisLineTemplateName, AnalysisColumnTemplateName);
        // [WHEN] Open Sales Analysis Matrix Page
        SalesAnalysisReportPageShowMatrix(SalesAnalysisReport, CustomerNo);

        // [THEN] Cost Amount = rounded "X" with presicion = 1 in Overview Page
        // Verification done in handler SaleAnalysisMatrixRequestPageHandler
    end;

    [Test]
    [HandlerFunctions('SaleAnalysisMatrixRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesAnalysisReportRoundingFactor1000()
    var
        AnalysisReportName: Record "Analysis Report Name";
        SalesAnalysisReport: TestPage "Sales Analysis Report";
        AnalysisLineTemplateName: Code[10];
        AnalysisColumnTemplateName: Code[10];
        CustomerNo: Code[20];
        ItemNo: Code[20];
        RoundingFactor: Integer;
        Amount: Decimal;
    begin
        // [FEATURE] [Sale Analysis Matrix]
        // [SCENARIO 121960] Cost Amount cell in Sales Analysis Matrix with Rounding Factor = 1000.
        Initialize();
        RoundingFactor := 1000;

        // [GIVEN] Analysis Report with Analysis Line and Analysis Column with Rounding Factor = 1000
        CreateAnalysisReport(
          AnalysisReportName, AnalysisLineTemplateName, AnalysisColumnTemplateName, ItemNo, RoundingFactor);
        // [GIVEN] Value Entry with Decimal Amount = "X"
        Amount := CreateValueEntry(ItemNo, CustomerNo);
        LibraryVariableStorage.Enqueue(RoundCostAmount(Amount, RoundingFactor));

        // [GIVEN] Opened Analysis Report Sale Page
        AnalysisReportSalePageOpen(
          SalesAnalysisReport, AnalysisReportName, AnalysisLineTemplateName, AnalysisColumnTemplateName);
        // [WHEN] Open Sales Analysis Matrix Page
        SalesAnalysisReportPageShowMatrix(SalesAnalysisReport, CustomerNo);

        // [THEN] Cost Amount = rounded "X" as Thousands with presicion = 0.1 in Overview Page
        // Verification done in handler SaleAnalysisMatrixRequestPageHandler
    end;

    [Test]
    [HandlerFunctions('SaleAnalysisMatrixRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesAnalysisReportRoundingFactor1000000()
    var
        AnalysisReportName: Record "Analysis Report Name";
        SalesAnalysisReport: TestPage "Sales Analysis Report";
        AnalysisLineTemplateName: Code[10];
        AnalysisColumnTemplateName: Code[10];
        CustomerNo: Code[20];
        ItemNo: Code[20];
        RoundingFactor: Integer;
        Amount: Decimal;
    begin
        // [FEATURE] [Sale Analysis Matrix]
        // [SCENARIO 121960] Cost Amount cell in Sales Analysis Matrix with Rounding Factor = 1000000.
        Initialize();
        RoundingFactor := 1000000;

        // [GIVEN] Analysis Report with Analysis Line and Analysis Column with Rounding Factor = 1000000
        CreateAnalysisReport(
          AnalysisReportName, AnalysisLineTemplateName, AnalysisColumnTemplateName, ItemNo, RoundingFactor);
        // [GIVEN] Value Entry with Decimal Amount = "X"
        Amount := CreateValueEntry(ItemNo, CustomerNo);
        LibraryVariableStorage.Enqueue(RoundCostAmount(Amount, RoundingFactor));

        // [GIVEN] Opened Analysis Report Sale Page
        AnalysisReportSalePageOpen(
          SalesAnalysisReport, AnalysisReportName, AnalysisLineTemplateName, AnalysisColumnTemplateName);
        // [WHEN] Open Sales Analysis Matrix Page
        SalesAnalysisReportPageShowMatrix(SalesAnalysisReport, CustomerNo);

        // [THEN] Cost Amount = rounded "X" as Billions with presicion = 0.1 in Overview Page
        // Verification done in handler SaleAnalysisMatrixRequestPageHandler
    end;

    local procedure SalesAnalysisReportWithItemLedgerEntryTypeAndValueType(AnalysisColumnValueType: Enum "Analysis Value Type"; ValueType: Enum "Item Ledger Entry Type")
    var
        AnalysisReportName: Record "Analysis Report Name";
        ItemAnalysisView: Record "Item Analysis View";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AnalysisLine: Record "Analysis Line";
    begin
        // Setup: Post Sales Document with Ship Option and Create Analysis Report Name.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CreateCustomer());
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        LibraryVariableStorage.Enqueue(0);
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Sales);
        LibraryInventory.CreateAnalysisReportName(AnalysisReportName, ItemAnalysisView."Analysis Area");

        // Exercise: Open Analysis Report Sales with Correct filter Item Ledger Entry Type Purchase.
        OpenAnalysisReportSales(
          AnalysisReportName.Name,
          CreateAnalysisLine(ItemAnalysisView."Analysis Area", AnalysisLine.Type::Customer,
            SalesHeader."Sell-to Customer No."),
          CreateAnalysisColumnWithItemLedgerEntryType(ItemAnalysisView."Analysis Area",
            Format(ValueType), AnalysisColumnValueType));

        // Verify: Verification done in SalesAnalysisMatrixRequestPageHandler.
    end;

    [Test]
    [HandlerFunctions('MessageVerificationHandler')]
    [Scope('OnPrem')]
    procedure CopyUnappliedSalesLineToSalesReturnOrderByCopyDocument()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        PostedSalesHeaderNo: Code[20];
    begin
        // Verify that unapplied Sales Lines can be copied to Sales Return Order by Copy Document
        // and Appl.-from Item Entry is filled when Exact Cost Reversing Mondatory is enabled.

        // Setup: Create Item, customer and update Sales & Receivable Setup for Exact Cost Reversing Mandatory.
        Initialize();
        UpdateExactCostReversingMandatory(true);

        // Create Sales Order with multiple lines.
        CustomerNo := CreateCustomer();
        PostedSalesHeaderNo := CreateAndPostSalesOrderWithMultipleLines(CustomerNo);

        // Create Return Sales Order by Copy Document. Delete one Sales Line.
        CreateSalesReturnOrderByCopyDocument(
          SalesHeader, CustomerNo, "Sales Document Type From"::"Posted Invoice", PostedSalesHeaderNo, false, false);
        FindAndDeleteOneSalesLine(SalesHeader);

        // Post Sales Return Order.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Excise: Create Return Sales Order by Copy Document again.
        // Verify: Verify the warning message in MessageHandler2.
        LibraryVariableStorage.Enqueue(CopyDocForReturnOrderMsg); // Enqueue for MessageHandler2.
        CreateSalesReturnOrderByCopyDocument(
          SalesHeader, CustomerNo, "Sales Document Type From"::"Posted Invoice", PostedSalesHeaderNo, false, false);

        // Verify the unapplied line can be copied and Exact Cost Reversal link is created.
        VerifySalesReturnOrderLine(SalesHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustLedgerEntryWithDocumentTypeRefund()
    var
        PaymentMethod: Record "Payment Method";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DocumentNo: Code[20];
    begin
        // Verify that Customer ledger entry exist With Document Type Refund when payment method code with balancing account.

        // Setup: Create payment method and create Sales return order.
        Initialize();
        CreatePaymentMethodCode(PaymentMethod);
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", CreateCustomer());
        SalesHeader.Validate("Payment Method Code", PaymentMethod.Code);
        SalesHeader.Modify(true);

        // Exercise: Post Sales Return Order.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verifing that customer ledger entry exist with document type refund.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Refund, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyBinCodeOnSalesLineAfterUpdatingQtyToAsmToOrder()
    var
        SalesLine: Record "Sales Line";
        BinCode: Code[20];
    begin
        // Setup: Create sales document with bin & bin content.
        BinCode := InitSetupForSalesDocumentWithBinContent(SalesLine);

        // Exercise: Re-enter Qty. to Assemble to Order on sales line.
        UpdateQtyToAsmToOrderOnSalesLineByPage(SalesLine."Document No.", SalesLine."Qty. to Assemble to Order");

        // Verify: Verify Bin Code was not updated on Sales Line.
        VerifyBinCodeOnSalesLine(SalesLine."No.", BinCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyBinCodeOnSalesLineAfterUpdatingQuantity()
    var
        SalesLine: Record "Sales Line";
        BinCode: Code[20];
    begin
        // Setup: Create sales document with bin & bin content.
        BinCode := InitSetupForSalesDocumentWithBinContent(SalesLine);

        // Exercise: Re-enter Quantity on sales line.
        UpdateQuantityOnSalesLineByPage(SalesLine."Document No.", SalesLine.Quantity);

        // Verify: Verify Bin Code was not updated on Sales Line.
        VerifyBinCodeOnSalesLine(SalesLine."No.", BinCode);
    end;

    [Test]
    [HandlerFunctions('ConfirmCopyDocDateOrderHandlerVerify')]
    [Scope('OnPrem')]
    procedure CopyPostedInvShptDateOrderNonConfirm()
    var
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        CustomerNo: Code[20];
        PostedDocNo: Code[20];
        InitialPostingDate: Date;
        OldDateOrder: Boolean;
    begin
        // [FEATURE] [Date Order]
        // [SCENARIO 375365] Copy Document from Posted Sales Invoice and Shipment with Date Order enabled and user not accepted confirmation

        Initialize();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());

        // [GIVEN] Posted Sales Invoice with Posting Date = "X"
        PostedDocNo :=
          CreateAndPostSimpleSalesDocument(SalesHeader."Document Type"::Invoice, CustomerNo);

        // [GIVEN] Posted Invoice Nos. has "Date Order" = TRUE
        OldDateOrder := SetNoSeriesDateOrder(true);

        // [GIVEN] Sales Document with Posting Date = "X" + 1 day and Posting No. assigned
        CreateSalesDocumentWithPostingNo(
          SalesHeader, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandInt(5), PostedDocNo);
        InitialPostingDate := SalesHeader."Posting Date";
        LibraryVariableStorage.Enqueue(false);

        // [WHEN] Run Copy Document from Posted Sales Invoice to Sales Document with Include Header = TRUE
        CopyDocument(SalesHeader, "Sales Document Type From"::"Posted Invoice", PostedDocNo);
        SalesHeader.Find();

        // [THEN] Confirmation dialog appears with warning and Document not copied (user pressed cancel)
        Assert.AreEqual(InitialPostingDate, SalesHeader."Posting Date", DocumentShouldNotBeCopiedErr);

        // [WHEN] Run Copy Document from Posted Sales Shipment to Sales Document with Include Header = TRUE
        SalesShipmentHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesShipmentHeader.FindFirst();
        LibraryVariableStorage.Enqueue(false);
        CopyDocument(SalesHeader, "Sales Document Type From"::"Posted Shipment", SalesShipmentHeader."No.");
        SalesHeader.Find();

        // [THEN] Confirmation dialog appears with warning and Document not copied (user pressed cancel)
        Assert.AreEqual(InitialPostingDate, SalesHeader."Posting Date", DocumentShouldNotBeCopiedErr);

        SetNoSeriesDateOrder(OldDateOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmCopyDocDateOrderHandlerVerify')]
    [Scope('OnPrem')]
    procedure CopyPostedCrMemoRetRecDateOrderNonConfirm()
    var
        SalesHeader: Record "Sales Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
        CustomerNo: Code[20];
        PostedDocNo: Code[20];
        InitialPostingDate: Date;
        OldDateOrder: Boolean;
    begin
        // [FEATURE] [Date Order]
        // [SCENARIO 375365] Copy Document from Posted Sales Credit Memo and Return Receipt with Date Order enabled and user not accepted confirmation

        Initialize();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());

        // [GIVEN] Posted Credit Memo with Posting Date = "X"
        PostedDocNo :=
          CreateAndPostSimpleSalesDocument(SalesHeader."Document Type"::"Return Order", CustomerNo);

        // [GIVEN] Posted Invoice Nos. has "Date Order" = TRUE
        OldDateOrder := SetNoSeriesDateOrder(true);

        // [GIVEN] Sales Document with Posting Date = "X" + 1 day and Posting No. assigned
        CreateSalesDocumentWithPostingNo(
          SalesHeader, LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandInt(5), PostedDocNo);
        InitialPostingDate := SalesHeader."Posting Date";
        LibraryVariableStorage.Enqueue(false);

        // [WHEN] Run Copy Document from Posted Sales Cr. Memo to Sales Document with Include Header = TRUE
        CopyDocument(SalesHeader, "Sales Document Type From"::"Posted Credit Memo", PostedDocNo);

        // [THEN] Confirmation dialog appears with warning and Document not copied (user pressed cancel)
        SalesHeader.Find();
        Assert.AreEqual(InitialPostingDate, SalesHeader."Posting Date", DocumentShouldNotBeCopiedErr);

        // [WHEN] Run Copy Document from Posted Return Receipt to Sales Document with Include Header = TRUE
        ReturnReceiptHeader.SetRange("Sell-to Customer No.", CustomerNo);
        ReturnReceiptHeader.FindFirst();
        LibraryVariableStorage.Enqueue(false);
        CopyDocument(SalesHeader, "Sales Document Type From"::"Posted Return Receipt", ReturnReceiptHeader."No.");
        SalesHeader.Find();

        // [THEN] Confirmation dialog appears with warning and Document not copied (user pressed cancel)
        Assert.AreEqual(InitialPostingDate, SalesHeader."Posting Date", DocumentShouldBeCopiedErr);

        SetNoSeriesDateOrder(OldDateOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmCopyDocDateOrderHandlerVerify')]
    [Scope('OnPrem')]
    procedure CopyQuoteDateOrderNonConfirm()
    var
        SalesHeaderSrc: Record "Sales Header";
        SalesHeaderDst: Record "Sales Header";
        CustomerNo: Code[20];
        OldDateOrder: Boolean;
    begin
        // [FEATURE] [Date Order]
        // [SCENARIO 375365] Copy Document from Sales Quote with Date Order enabled and user not accepted confirmation

        Initialize();

        // [GIVEN] Posted Invoice Nos. has "Date Order" = TRUE
        OldDateOrder := SetNoSeriesDateOrder(true);

        // [GIVEN] Sales Quote with Posting Date = "X"
        LibrarySales.CreateSalesHeader(
          SalesHeaderSrc, SalesHeaderSrc."Document Type"::Quote, LibrarySales.CreateCustomerNo());

        // [GIVEN] Sales Document with Posting Date = "X" + 1 day and Posting No. assigned
        CustomerNo := LibrarySales.CreateCustomerNo();
        CreateSalesDocumentWithPostingNo(
          SalesHeaderDst, CustomerNo, LibraryRandom.RandInt(5),
          LibraryUtility.GenerateRandomCode(SalesHeaderDst.FieldNo("Posting No."), DATABASE::"Sales Header"));
        LibraryVariableStorage.Enqueue(false);

        // [WHEN] Run Copy Document from Sales Quote to Sales Document with Include Header = TRUE
        CopyDocument(SalesHeaderDst, "Sales Document Type From"::Quote, SalesHeaderSrc."No.");

        // [THEN] Confirmation dialog appears with warning and Document not copied (user pressed cancel)
        SalesHeaderDst.Find();
        Assert.AreEqual(CustomerNo, SalesHeaderDst."Sell-to Customer No.", DocumentShouldBeCopiedErr);

        SetNoSeriesDateOrder(OldDateOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CopyPostedInvShptDateOrderConfirm()
    var
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesShipmentHeader: Record "Sales Shipment Header";
        PostedDocNo: Code[20];
        CustomerNoSrc: Code[20];
        CustomerNoDst: Code[20];
        OldDateOrder: Boolean;
    begin
        // [FEATURE] [Date Order]
        // [SCENARIO 375365] Copy Document from Posted Sales Invoice and Shipment with Date Order enabled and user accepted confirmation

        Initialize();
        SetSalesReceivablesSetupStockoutCreditWarning(
          SalesReceivablesSetup."Credit Warnings"::"No Warning", false);

        // [GIVEN] Posted Sales Invoice with Posting Date = "X"
        PostedDocNo :=
          CreateAndPostSimpleSalesDocument(SalesHeader1."Document Type"::Invoice, CustomerNoSrc);

        // [GIVEN] Posted Invoice Nos. has "Date Order" = TRUE
        OldDateOrder := SetNoSeriesDateOrder(true);

        // [GIVEN] Sales Document with Posting Date = "X" + 1 day and Posting No. assigned
        CustomerNoDst := LibrarySales.CreateCustomerNo();
        CreateSalesDocumentWithPostingNo(SalesHeader1, CustomerNoDst, LibraryRandom.RandInt(5), PostedDocNo);
        // [WHEN] Run Copy Document from Posted Sales Invoice to Sales Document with Include Header = TRUE
        CopyDocument(SalesHeader1, "Sales Document Type From"::"Posted Invoice", PostedDocNo);
        SalesHeader1.Find();

        // [THEN] Confirmation dialog appears with warning and Document is copied after user confirmation
        Assert.AreEqual(CustomerNoSrc, SalesHeader1."Sell-to Customer No.", DocumentShouldBeCopiedErr);

        // [WHEN] Run Copy Document from Posted Sales Shipment to Sales Document with Include Header = TRUE
        SalesShipmentHeader.SetRange("Sell-to Customer No.", CustomerNoSrc);
        SalesShipmentHeader.FindFirst();
        CreateSalesDocumentWithPostingNo(SalesHeader2, CustomerNoDst, LibraryRandom.RandInt(5), PostedDocNo);
        CopyDocument(SalesHeader2, "Sales Document Type From"::"Posted Shipment", SalesShipmentHeader."No.");
        SalesHeader2.Find();

        // [THEN] Confirmation dialog appears with warning and Document is copied after user confirmation
        Assert.AreEqual(CustomerNoSrc, SalesHeader2."Sell-to Customer No.", DocumentShouldBeCopiedErr);

        SetNoSeriesDateOrder(OldDateOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CopyPostedCrMemoRetRecDateOrderConfirm()
    var
        SalesHeader1: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ReturnReceiptHeader: Record "Return Receipt Header";
        CustomerNo: Code[20];
        PostedDocNo: Code[20];
        OldDateOrder: Boolean;
    begin
        // [FEATURE] [Date Order]
        // [SCENARIO 375365] Copy Document from Posted Sales Credit Memo and Return Receipt with Date Order enabled and user accepted confirmation

        Initialize();
        SetSalesReceivablesSetupStockoutCreditWarning(
          SalesReceivablesSetup."Credit Warnings"::"No Warning", false);

        // [GIVEN] Posted Credit Memo with Posting Date = "X"
        PostedDocNo :=
          CreateAndPostSimpleSalesDocument(SalesHeader1."Document Type"::"Return Order", CustomerNo);

        // [GIVEN] Posted Invoice Nos. has "Date Order" = TRUE
        OldDateOrder := SetNoSeriesDateOrder(true);

        // [GIVEN] Sales Document with Posting Date = "X" + 1 day and Posting No. assigned
        CreateSalesDocumentWithPostingNo(
          SalesHeader1, LibrarySales.CreateCustomerNo(), LibraryRandom.RandInt(5), PostedDocNo);

        // [WHEN] Run Copy Document from Posted Sales Cr. Memo to Sales Document with Include Header = TRUE
        CopyDocument(SalesHeader1, "Sales Document Type From"::"Posted Credit Memo", PostedDocNo);

        // [THEN] Confirmation dialog appears with warning and Document is copied after user confirmation
        SalesHeader1.Find();
        Assert.AreEqual(CustomerNo, SalesHeader1."Sell-to Customer No.", DocumentShouldBeCopiedErr);

        // [WHEN] Run Copy Document from Posted Return Receipt to Sales Document with Include Header = TRUE
        CreateSalesDocumentWithPostingNo(
          SalesHeader2, LibrarySales.CreateCustomerNo(), LibraryRandom.RandInt(5), PostedDocNo);

        ReturnReceiptHeader.SetRange("Sell-to Customer No.", CustomerNo);
        ReturnReceiptHeader.FindFirst();
        CopyDocument(SalesHeader2, "Sales Document Type From"::"Posted Return Receipt", ReturnReceiptHeader."No.");
        SalesHeader2.Find();

        // [THEN] Confirmation dialog appears with warning and Document is copied after user confirmation
        Assert.AreEqual(CustomerNo, SalesHeader2."Sell-to Customer No.", DocumentShouldBeCopiedErr);

        SetNoSeriesDateOrder(OldDateOrder);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure CopyQuoteDateOrderConfirm()
    var
        SalesHeaderSrc: Record "Sales Header";
        SalesHeaderDst: Record "Sales Header";
        OldDateOrder: Boolean;
    begin
        // [FEATURE] [Date Order]
        // [SCENARIO 375365] Copy Document from Sales Quote with Date Order enabled and user accepted confirmation

        Initialize();

        // [GIVEN] Posted Invoice Nos. has "Date Order" = TRUE
        OldDateOrder := SetNoSeriesDateOrder(true);

        // [GIVEN] Sales Quote with Posting Date = "X"
        LibrarySales.CreateSalesHeader(SalesHeaderSrc, SalesHeaderSrc."Document Type"::Quote, LibrarySales.CreateCustomerNo());

        // [GIVEN] Sales Document with Posting Date = "X" + 1 day and Posting No. assigned
        CreateSalesDocumentWithPostingNo(
          SalesHeaderDst, LibrarySales.CreateCustomerNo(), LibraryRandom.RandInt(5),
          LibraryUtility.GenerateRandomCode(SalesHeaderDst.FieldNo("Posting No."), DATABASE::"Sales Header"));

        // [WHEN] Run Copy Document from Sales Quote to Sales Document with Include Header = TRUE
        CopyDocument(SalesHeaderDst, "Sales Document Type From"::Quote, SalesHeaderSrc."No.");

        // [THEN] Confirmation dialog appears with warning and Document is copied after user confirmation
        SalesHeaderDst.Find();
        Assert.AreEqual(SalesHeaderSrc."Sell-to Customer No.", SalesHeaderDst."Sell-to Customer No.", DocumentShouldBeCopiedErr);

        SetNoSeriesDateOrder(OldDateOrder);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopySalesInvoiceWithDifferentVATBusGroup()
    var
        SalesHeaderSrc: Record "Sales Header";
        SalesHeaderDst: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        // [SCENARIO 376478] It is not allowed to Copy document when VAT group of source lines does not match VAT group of destination header
        // [FEATURE] [Copy Document]
        Initialize();

        // [GIVEN] Source Sales Invoice with "VAT Bus. Posting Group" = "X" in line
        LibrarySales.CreateSalesHeader(
          SalesHeaderSrc, SalesHeaderSrc."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(20));
        SalesHeaderSrc.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        SalesHeaderSrc.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeaderSrc, SalesLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale),
          LibraryRandom.RandDec(10, 2));

        // [GIVEN] Destination Sales Invoice with "VAT Bus. Posting Group" = "Y"
        LibrarySales.CreateSalesHeader(
          SalesHeaderDst, SalesHeaderDst."Document Type"::Invoice, SalesHeaderSrc."Sell-to Customer No.");

        // [WHEN] Run "Copy Sales Document" report from Invoice to Invoice with Include Header = FALSE and Recalculate Lines = FALSE
        asserterror LibrarySales.CopySalesDocument(SalesHeaderDst, "Sales Document Type From"::Invoice, SalesHeaderSrc."No.", false, false);

        // [THEN] Error thrown due to different VAT Business Groups in copied line and header
        Assert.ExpectedErrorCode(TestFieldTok);
        Assert.ExpectedError(VATBusPostingGroupErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopySalesInvoiceWithDifferentVATBusGroupInclHeader()
    var
        SalesHeaderSrc: Record "Sales Header";
        SalesHeaderDst: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        VATBusPostGroup: Code[20];
    begin
        // [SCENARIO 421483] It is allowed to Copy document with multiple VAT Bus. Posting Group in the source lines if header included.
        // [FEATURE] [Copy Document]
        Initialize();

        // [GIVEN] Source Sales Invoice with "VAT Bus. Posting Group" = "X" in line
        LibrarySales.CreateSalesHeader(
          SalesHeaderSrc, SalesHeaderSrc."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandInt(20));
        SalesHeaderSrc.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        SalesHeaderSrc.Modify(true);
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeaderSrc, SalesLine.Type::"G/L Account",
            LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale), LibraryRandom.RandDec(10, 2));
        VATBusPostGroup := SalesLine."VAT Bus. Posting Group";

        // [GIVEN] Destination Sales Invoice with "VAT Bus. Posting Group" = "Y"
        LibrarySales.CreateSalesHeader(
          SalesHeaderDst, SalesHeaderDst."Document Type"::Invoice, SalesHeaderSrc."Sell-to Customer No.");

        // [WHEN] Run "Copy Sales Document" report from Invoice to Invoice with Include Header = TRUE and Recalculate Lines = FALSE
        LibrarySales.CopySalesDocument(SalesHeaderDst, "Sales Document Type From"::Invoice, SalesHeaderSrc."No.", true, false);

        // [THEN] Line is copied
        SalesLine.Reset();
        SalesLine.SetRange("Document Type", SalesHeaderDst."Document Type");
        SalesLine.SetRange("Document No.", SalesHeaderDst."No.");
        Assert.RecordCount(SalesLine, 1);
        SalesLine.FindFirst();
        SalesLine.TestField("VAT Bus. Posting Group", VATBusPostGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderCreationWithCustomerLocation()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        Location: Record Location;
        OneDay: Text;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 157733] When creating Sales Order, "Outbound Whse. Handling Time" filled from Location.

        // [GIVEN] Location "L" with "Outbound Whse. Handling Time" = "X"
        Initialize();
        OneDay := '1D';
        LibraryWarehouse.CreateLocation(Location);
        Evaluate(Location."Outbound Whse. Handling Time", OneDay);
        Location.Modify(true);

        // [GIVEN] Customer with Location "L"
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Location Code", Location.Code);
        Customer.Modify(true);

        // [WHEN] Create Sales Order with Customer.
        SalesHeader.Init();
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Insert(true);
        // [THEN] Sales Order contains "Outbound Whse. Handling Time" = "X"
        SalesHeader.Find();
        Assert.AreEqual(OneDay, Format(SalesHeader."Outbound Whse. Handling Time"), HandlingTimeErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesHeaderReserveField()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales Header] [UT]
        // [SCENARIO 377813] Sales Header should have init value "Optional" for field "Reserve"
        Initialize();

        SalesHeader.Init();
        SalesHeader.TestField(Reserve, SalesHeader.Reserve::Optional);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesHeaderReserveFieldFromCustomerOnInsert()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales Header] [UT]
        // [SCENARIO 377813] Sales Header should inherit field "Reserve" from Customer on Insert
        Initialize();

        // [GIVEN] Customer "C" with Reserve = Always
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Reserve, Customer.Reserve::Always);
        Customer.Modify(true);

        // [GIVEN] Sales Header with "Sell-to Customer No." = "C"
        SalesHeader.Init();
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");

        // [WHEN] Insert Sales Header
        SalesHeader.Insert(true);

        // [THEN] Sales Header has Reserve = Always
        SalesHeader.TestField(Reserve, Customer.Reserve);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesHeaderReserveFieldFromCustomerOnValidate()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
    begin
        // [FEATURE] [Sales Header] [UT]
        // [SCENARIO 377813] Sales Header should inherit field "Reserve" from Customer on Validate Customer No.
        Initialize();

        // [GIVEN] Customer "C" with Reserve = Never
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Reserve, Customer.Reserve::Never);
        Customer.Modify(true);

        // [GIVEN] Sales Header with Reserve = Optional
        SalesHeader.Init();
        SalesHeader.Insert(true);

        // [WHEN] Set "Sell-to Customer No." to "C" in Sales Header
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");

        // [THEN] Sales Header has Reserve = Never
        SalesHeader.TestField(Reserve, Customer.Reserve);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AnalysisReportManagementCopyColumnsToTempRESETBeforeDELETEALL()
    var
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        TempAnalysisColumn: Record "Analysis Column" temporary;
        ColumnName: array[2] of Code[10];
    begin
        // [FEATURE] [Analysis Report Management] [UT]
        // [SCENARIO 380725] AnalysisReportManagement.CopyColumnsToTemp: it should be RESET result table TempAnalysisColumn before DELETEALL it.
        Initialize();

        // [GIVEN] Analysis Line.
        CreateRandomAreaAnalysisLine(AnalysisLine);

        // [GIVEN] Two Analysis Column Template T1 and T2 with random quantity of Analysis Columns for each.
        ColumnName[1] := CreateNewTemplateAnalysisColumnRandomSet(AnalysisLine."Analysis Area");
        ColumnName[2] := CreateNewTemplateAnalysisColumnRandomSet(AnalysisLine."Analysis Area");

        // [WHEN] AnalysisReportManagement.CopyColumnsToTemp to the same temporary result table TempAnalysisColumn for each Template - first T1, then T2
        AnalysisReportManagementCopyColumnsToTemp(TempAnalysisColumn, AnalysisLine, ColumnName[1]);
        AnalysisReportManagementCopyColumnsToTemp(TempAnalysisColumn, AnalysisLine, ColumnName[2]);

        // [THEN] TempAnalysisColumn must contain the records for T2 only.
        AnalysisColumn.SetRange("Analysis Area", AnalysisLine."Analysis Area");
        AnalysisColumn.SetRange("Analysis Column Template", ColumnName[2]);
        TempAnalysisColumn.Reset();

        Assert.RecordCount(TempAnalysisColumn, AnalysisColumn.Count);

        TempAnalysisColumn.SetRange("Analysis Column Template", ColumnName[1]);
        Assert.RecordIsEmpty(TempAnalysisColumn);
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocumentLinesWithSpecificCrMemoValidationHandler')]
    [Scope('OnPrem')]
    procedure UI_GetPostedDocumentLinesToReverseFromSalesCrMemoWithItem()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        CustNo: Code[20];
        CrMemoNo: Code[20];
    begin
        // [FEATURE] [UI] [Credit Memo] [Get Posted Document Lines to Reverse]
        // [SCENARIO 382062] It is possible to get Posted Sales Credit Memo with item to reverse from new Sales Credit Memo

        Initialize();

        // [GIVEN] Posted Sales Credit Memo "X" with Item
        CustNo := LibrarySales.CreateCustomerNo();
        CrMemoNo :=
          CreateAndPostSimpleSalesDocument(SalesHeader."Document Type"::"Credit Memo", CustNo);
        LibraryVariableStorage.Enqueue(CrMemoNo); // for PostedSalesDocumentLinesWithSpecificCrMemoValidationHandler

        // [GIVEN] New Sales Credit Memo
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustNo);

        // [GIVEN] Opened Sales Credit Memo page with new Sales Credit Memo
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.FILTER.SetFilter("No.", SalesHeader."No.");

        // [WHEN] Invoke action "Get Posted Document Lines to Reverse"
        SalesCreditMemo.GetPostedDocumentLinesToReverse.Invoke();

        // [THEN] "Posted Sales Document Lines" is opened and Posted Sales Credit Memo "X" exists in "Posted Credit Memos" list
        // Verification done in handler PostedSalesDocumentLinesWithSpecificCrMemoValidationHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceAmountIsIncludedInSalesThisMonth()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ActivitiesMgt: Codeunit "Activities Mgt.";
        SalesThisMonthBeforeInvoicePost: Decimal;
        SalesThisMonthAfterInvoicePost: Decimal;
        InvoiceAmount: Decimal;
    begin
        // Check if invoice amount is included in the SalesThisMonth number.

        // Setup: Create Sales Invoice.
        Initialize();
        SalesThisMonthBeforeInvoicePost := ActivitiesMgt.CalcSalesThisMonthAmount(false);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));

        // Excercise: Post the Sales Document
        InvoiceAmount := SalesLine.Amount;
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesThisMonthAfterInvoicePost := ActivitiesMgt.CalcSalesThisMonthAmount(false);

        // Verify that the SalesThisMonth number is updated with the invoicing amount.
        Assert.AreEqual(InvoiceAmount, SalesThisMonthAfterInvoicePost - SalesThisMonthBeforeInvoicePost,
          'Unexpected SalesThisMonth amount.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreditMemoAmountIsIncludedInSalesThisMonth()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ActivitiesMgt: Codeunit "Activities Mgt.";
        SalesThisMonthBeforeInvoicePost: Decimal;
        SalesThisMonthAfterInvoicePost: Decimal;
        ReturnedAmount: Decimal;
    begin
        // Check if invoice amount is included in the SalesThisMonth number.

        // Setup: Create Sales CreditMemo.
        Initialize();
        SalesThisMonthBeforeInvoicePost := ActivitiesMgt.CalcSalesThisMonthAmount(false);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CreateCustomer());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));

        // Excercise: Post the Sales Document
        ReturnedAmount := SalesLine.Amount;
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesThisMonthAfterInvoicePost := ActivitiesMgt.CalcSalesThisMonthAmount(false);

        // Verify that the SalesThisMonth number is updated with the amount on credit memo.
        Assert.AreEqual(ReturnedAmount, SalesThisMonthBeforeInvoicePost - SalesThisMonthAfterInvoicePost,
          'Unexpected SalesThisMonth amount.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerListBalanceDueMatchesCustomerCard()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerMgt: Codeunit "Customer Mgt.";
        CustomerList: TestPage "Customer List";
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [Customer Card] [Customer List]
        // [SCENARIO] Balance Due should correctly show Balance due for current year on both Customer List and Customer Card opened from the Customer List
        Initialize();

        // [GIVEN] A Customer
        LibrarySales.CreateCustomer(Customer);

        // [WHEN] Posting two sales invoices where only one is due this year
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader."Due Date" := CalcDate('<1Y>', WorkDate());
        SalesHeader.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Balance (LCY) and Balance Due (LCY) are different
        Customer.SetFilter("Date Filter", CustomerMgt.GetCurrentYearFilter());
        Customer.CalcFields("Balance (LCY)", "Balance Due (LCY)");
        Assert.AreNotEqual(
          Customer."Balance (LCY)", Customer."Balance Due (LCY)", 'Balance Due (LCY) and Balance (LCY) must be different');

        // [THEN] Balance (LCY) and Balance Due (LCY) are correct on Customer List
        CustomerList.OpenView();
        CustomerList.GotoKey(Customer."No.");
        CustomerList."Balance (LCY)".AssertEquals(Customer."Balance (LCY)");
        CustomerList."Balance Due (LCY)".AssertEquals(Customer."Balance Due (LCY)");

        // [THEN] Balance (LCY) and Balance Due (LCY) are correct on Customer Card opened from Customer List
        CustomerCard.Trap();
        CustomerList.View().Invoke();
        CustomerCard."Balance (LCY)".AssertEquals(Customer."Balance (LCY)");
        CustomerCard."Balance Due (LCY)".AssertEquals(Customer."Balance Due (LCY)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerListDateFilterMatchesOpenedCustomerCardDateFilter()
    var
        Customer: Record Customer;
        CustomerList: TestPage "Customer List";
        CustomerCard: TestPage "Customer Card";
        DateFilter: Text;
    begin
        // [FEATURE] [Customer Card] [Customer List]
        // [SCENARIO 253165] Customer Card opened from the Customer List should have same Date Filter.
        Initialize();

        // [GIVEN] A Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Customer List with Date Filter.
        CustomerList.OpenView();
        CustomerList.GotoKey(Customer."No.");
        DateFilter := StrSubstNo('%1..%2', LibraryRandom.RandDate(-100), LibraryRandom.RandDate(100));
        CustomerList.FILTER.SetFilter("Date Filter", DateFilter);

        // [WHEN] Open Customer Card from Customer List.
        CustomerCard.Trap();
        CustomerList.View().Invoke();

        // [THEN] Customer List has Date Filter which is equal to the Customer List Date Filter.
        Assert.AreEqual(DateFilter, CustomerCard.FILTER.GetFilter("Date Filter"), DateFilterErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerCardOpenedDirectlyDateFilterIsWorkDate()
    var
        Customer: Record Customer;
        CustomerCard: TestPage "Customer Card";
    begin
        // [FEATURE] [Customer Card]
        // [SCENARIO 253165] Customer Card opened not from the Customer List should be  filtered until workdate..
        Initialize();

        // [GIVEN] A Customer.
        LibrarySales.CreateCustomer(Customer);

        // [WHEN] Open Customer Card directly.
        CustomerCard.OpenView();
        CustomerCard.GotoKey(Customer."No.");

        // [THEN] Customer Card are filtered until workdate.
        Assert.AreEqual('''''' + '..' + Format(WorkDate()), CustomerCard.FILTER.GetFilter("Date Filter"), DateFilterErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerListHasDefaultDateFilterUntilWorkDate()
    var
        Customer: Record Customer;
        CustomerList: TestPage "Customer List";
    begin
        // [FEATURE] [Customer List]
        // [SCENARIO 273278] "Default Filter" on "Customer List" page sets to "..WORKDATE" on opening

        Initialize();

        // [GIVEN] Work date is 10.01.2018
        Customer.SetRange("Date Filter", 0D, WorkDate());

        // [WHEN] Open "Customer List" page
        CustomerList.OpenView();

        // [THEN] "Date Filter" is "..10.01.2018"
        Assert.AreEqual(Customer.GetFilter("Date Filter"), CustomerList.FILTER.GetFilter("Date Filter"), 'Incorrect default date filter');

        CustomerList.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ATOLinkIsUpdatedWhenSalesLinesAreRecreated()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        AssembleToOrderLink: Record "Assemble-to-Order Link";
    begin
        // [FEATURE] [Assemble-to-Order]
        // [SCENARIO 229829] "Document Line No." in Assemble-to Order Link is updated, when the update of sales header causes re-creation of the sales lines.
        Initialize();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());

        // [GIVEN] Assemble-to Order Item "I".
        LibraryInventory.CreateItem(Item);
        UpdateItemParameters(Item, Item."Replenishment System"::Assembly, Item."Assembly Policy"::"Assemble-to-Order");

        // [GIVEN] Sales Order with 2 lines.
        // [GIVEN] Line no. 10000 is empty and contains only a description.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine[1], SalesHeader, SalesLine[1].Type::" ", '', 0);
        SalesLine[1].Validate(Description, LibraryUtility.GenerateGUID());
        SalesLine[1].Modify(true);

        // [GIVEN] Line no. 20000 is for item "I" and is set for assemble-to order.
        LibrarySales.CreateSalesLine(SalesLine[2], SalesHeader, SalesLine[2].Type::Item, Item."No.", LibraryRandom.RandInt(10));
        SalesLine[2].Validate("Qty. to Assemble to Order", SalesLine[2].Quantity);
        SalesLine[2].Modify(true);

        // [GIVEN] Line no. 10000 is deleted.
        SalesLine[1].Delete(true);

        // [WHEN] Change "Bill-to Customer No." in order to invoke re-creation of the sales lines.
        SalesHeader.Validate("Bill-to Customer No.", LibrarySales.CreateCustomerNo());
        SalesHeader.Modify(true);

        // [THEN] "Document Line No." in Assemble-to Order Link is equal to "Line No." on the sales line with ATO item "I".
        FindSalesLine(SalesLine[2], SalesHeader);
        FindATOLink(AssembleToOrderLink, SalesHeader);
        AssembleToOrderLink.TestField("Document Line No.", SalesLine[2]."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultLocationCodeFromCustomerOnValidateAndInsert()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Customer] [Location] [UT]
        // [SCENARIO 255036] "Location Code" in Sales Document must be copied from Customer when the Sales Header is inserted after validating "Sell-to Customer No."
        Initialize();

        // [GIVEN] Customer "10000" with Location "BLUE"
        CreateCustomerWithLocation(Customer);

        // [WHEN] Validate "Sell-to Customer No." with "10000" in new Sales Order
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Insert(true);

        // [THEN] "Location Code" = "BLUE" in the Sales Order
        SalesHeader.TestField("Location Code", Customer."Location Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultSalespersonCodeFromCustomerOnValidate()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Customer] [Salesperson Code]
        // [SCENARIO] "Salesperson Code" in Sales Document must be copied from Customer when the Customer has a Salesperson Code
        Initialize();

        // [GIVEN] Customer with Salesperson Code
        CreateCustomerWithSalesperson(Customer);

        // [WHEN] Validate Sell-to Cusotmer in new Sales Order
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Insert(true);

        // [THEN] Sales Document Salesperson Code is equal to Customer Salesperson Code
        SalesHeader.TestField("Salesperson Code", Customer."Salesperson Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultSalespersonCodeFromShiptoCodeWithoutSalesperson()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        ShipToAddress: Record "Ship-to Address";
    begin
        // [FEATURE] [Ship-to Address] [Salesperson Code]
        // [SCENARIO] "Salesperson Code" in Sales Document must be copied from the Customer when the Ship-to Address does not has a Salesperson Code
        Initialize();

        // [GIVEN] Customer with Ship-to Address without Salesperson Code
        CreateCustomerWithSalesperson(Customer);
        CreateShiptoAddressWithoutSalesperson(ShipToAddress, Customer."No.");
        Customer.Validate("Ship-to Code", ShipToAddress."Code");
        Customer.Modify(true);

        // [WHEN] Validate Customer with a Salesperson Code in new Sales Order
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Insert(true);

        // [THEN] Sales Document Salesperson Code is equal to Customer Salesperson Code
        SalesHeader.TestField("Salesperson Code", Customer."Salesperson Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultSalespersonCodeFromShiptoCodeSalesperson()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        ShipToAddress: Record "Ship-to Address";
    begin
        // [FEATURE] [Ship-to Address] [Salesperson Code]
        // [SCENARIO] "Salesperson Code" in Sales Document must be copied from Ship-to Address assigned to the Customer when the Ship-to Address has a Salesperson Code
        Initialize();

        // [GIVEN] Customer with Ship-to Address with Salesperson Code
        CreateCustomerWithSalesperson(Customer);
        CreateShiptoAddressWithSalesperson(ShipToAddress, Customer."No.");
        Customer.Validate("Ship-to Code", ShipToAddress."Code");
        Customer.Modify(true);

        // [WHEN] Validate Ship-to Address with a Salesperson Code in new Sales Order
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Insert(true);

        // [THEN] Sales Document Salesperson Code is equal to Ship-to Address Salesperson Code
        SalesHeader.TestField("Salesperson Code", ShipToAddress."Salesperson Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultSalespersonCodeFromShiptoCodeOnValidate()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        ShipToAddress: Record "Ship-to Address";
    begin
        // [FEATURE] [Ship-to Address] [Salesperson Code]
        // [SCENARIO] "Salesperson Code" in Sales Document must be copied from Ship-to Address when the Ship-to Address has a Salesperson Code
        Initialize();

        // [GIVEN] Customer with Ship-to Address with Salesperson Code
        CreateCustomerWithSalesperson(Customer);
        CreateShiptoAddressWithSalesperson(ShipToAddress, Customer."No.");

        // [WHEN] Validate Ship-to Address with a Salesperson Code in new Sales Order
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Validate("Ship-to Code", ShipToAddress."Code");
        SalesHeader.Insert(true);

        // [THEN] Sales Document Salesperson Code is equal to Ship-to Address Salesperson Code
        SalesHeader.TestField("Salesperson Code", ShipToAddress."Salesperson Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultSalespersonCodeFromCustomerNoShiptoSalespersonOnValidate()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        ShipToAddress: Record "Ship-to Address";
    begin
        // [FEATURE] [Ship-to Address] [Salesperson Code]
        // [SCENARIO] "Salesperson Code" in Sales Document must be copied from Customer when the Ship-to Address does not have a Salesperson Code
        Initialize();

        // [GIVEN] Customer with Ship-to Address without Salesperson Code
        CreateCustomerWithSalesperson(Customer);
        CreateShiptoAddressWithoutSalesperson(ShipToAddress, Customer."No.");

        // [WHEN] Validate Ship-to Address without a Salesperson Code in new Sales Order
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Validate("Ship-to Code", ShipToAddress."Code");
        SalesHeader.Insert(true);

        // [THEN] Sales Document Salesperson Code is equal to Customer Salesperson Code
        SalesHeader.TestField("Salesperson Code", Customer."Salesperson Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultSalespersonCodeFromBilltoCustomerwithSalesPersonCode()
    var
        BilltoCustomer: Record Customer;
        SelltoCustomer: Record Customer;
        SalesHeader: Record "Sales Header";
        ShipToAddress: Record "Ship-to Address";
    begin
        // [FEATURE] [Ship-to Address] [Salesperson Code]
        // [SCENARIO] "Salesperson Code" in Sales Document must be copied from the Bill-to Customer when the Sell-to Customer has a Bill-to Customer with Salesperson Code
        Initialize();

        // [GIVEN] Bill-to Customer with Salesperson Code
        CreateCustomerWithSalesperson(BilltoCustomer);

        // [GIVEN] Customer with Ship-to Address without Salesperson Code and Bill-to Customer with Salesperson Code
        CreateCustomerWithSalesperson(SelltoCustomer);
        CreateShiptoAddressWithoutSalesperson(ShipToAddress, SelltoCustomer."No.");
        SelltoCustomer.Validate("Ship-to Code", ShipToAddress."Code");
        SelltoCustomer.Validate("Bill-to Customer No.", BilltoCustomer."No.");
        SelltoCustomer.Modify(true);

        // [WHEN] Validate Ship-to Address with a Salesperson Code in new Sales Order
        SalesHeader.Validate("Sell-to Customer No.", SelltoCustomer."No.");
        SalesHeader.Insert(true);

        // [THEN] Sales Document Salesperson Code is equal to Customer Salesperson Code
        SalesHeader.TestField("Salesperson Code", BilltoCustomer."Salesperson Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultSalespersonCodeFromShiptowithSalesPersonCodewithBilltoWithoutSalesperson()
    var
        BilltoCustomer: Record Customer;
        SelltoCustomer: Record Customer;
        SalesHeader: Record "Sales Header";
        ShipToAddress: Record "Ship-to Address";
    begin
        // [FEATURE] [Ship-to Address] [Salesperson Code]
        // [SCENARIO] "Salesperson Code" in Sales Document must be copied from the Sell-to Customer Ship-to when the Sell-to Customer has a Ship-to and Bill-to Customer without Salesperson Code
        Initialize();

        // [GIVEN] Bill-to Customer without Salesperson Code
        LibrarySales.CreateCustomerWithAddress(BilltoCustomer);

        // [GIVEN] Customer with Ship-to Address without Salesperson Code and Bill-to Customer with Salesperson Code
        CreateCustomerWithSalesperson(SelltoCustomer);
        CreateShiptoAddressWithSalesperson(ShipToAddress, SelltoCustomer."No.");
        SelltoCustomer.Validate("Ship-to Code", ShipToAddress."Code");
        SelltoCustomer.Validate("Bill-to Customer No.", BilltoCustomer."No.");
        SelltoCustomer.Modify(true);

        // [WHEN] Validate Customer with a Salesperson Code in new Sales Order
        SalesHeader.Validate("Sell-to Customer No.", SelltoCustomer."No.");
        SalesHeader.Insert(true);

        // [THEN] Sales Document Salesperson Code is equal to Customer Salesperson Code
        SalesHeader.TestField("Salesperson Code", ShipToAddress."Salesperson Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure DefaultLocationCodeFromCustomerOnRevalidatingBuyFromVendor()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Customer] [Location] [UT]
        // [SCENARIO 255036] "Location Code" in Sales Document must be copied from Customer when "Sell-to Customer No." is set and then revalidated with a new value
        Initialize();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());

        // [GIVEN] Customer "10000" with Location "BLUE"
        CreateCustomerWithLocation(Customer);

        // [GIVEN] Sales Order with "Sell-to Customer No." = "10000"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [GIVEN] Customer "20000" with Location "RED"
        CreateCustomerWithLocation(Customer);

        // [WHEN] Validate "Sell-to Customer No." with "20000" in the Sales Order
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");

        // [THEN] "Location Code" = "RED" in the Sales Order
        SalesHeader.TestField("Location Code", Customer."Location Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S461624_DefaultLocationCodeOnSalesOrderFromCustomer_ValidateCustomerBeforeInsert()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Customer] [Ship-to Address] [Location] [Sales Order] [UT]
        // [SCENARIO 461624] Customer has default "Ship-to Address" defined with "Location Code" defined only on Customer.
        // [SCENARIO 461624] "Location Code" in Sales Document must be copied from Customer when Sales Header is inserted after validating "Sell-to Customer No.".
        Initialize();

        // [GIVEN] Create Customer "C10000" with Location "BLUE".
        // [GIVEN] Create Customer Ship-to Address "C10000_SA" without "Location Code".
        // [GIVEN] Update "Ship-to Code" for Customer "C10000".
        CreateCustomerWithLocationAndShipToAddressWithoutLocation(Customer, ShipToAddress);

        // [WHEN] Create "Sales Header" for Sales Order and validate "Sell-to Customer No." with "C10000" before inserting Sales Order Header.
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Insert(true);

        // [THEN] "Location Code" = "BLUE" in the Sales Order.
        SalesHeader.TestField("Location Code", Customer."Location Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S461624_DefaultLocationCodeOnSalesOrderFromCustomer_ValidateCustomerAfterInsert()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Customer] [Ship-to Address] [Location] [Sales Order] [UT]
        // [SCENARIO 461624] Customer has default "Ship-to Address" defined with "Location Code" defined only on Customer.
        // [SCENARIO 461624] "Location Code" in Sales Document must be copied from Customer when Sales Header is inserted before validating "Sell-to Customer No.".
        Initialize();

        // [GIVEN] Create Customer "C10000" with Location "BLUE".
        // [GIVEN] Create Customer Ship-to Address "C10000_SA" without "Location Code".
        // [GIVEN] Update "Ship-to Code" for Customer "C10000".
        CreateCustomerWithLocationAndShipToAddressWithoutLocation(Customer, ShipToAddress);

        // [WHEN] Create "Sales Header" for Sales Order and then validate "Sell-to Customer No." with "C10000" after inserting Sales Order Header.
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Modify(true);

        // [THEN] "Location Code" = "BLUE" in the Sales Order.
        SalesHeader.TestField("Location Code", Customer."Location Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S461624_DefaultLocationCodeOnSalesOrderFromShipToAddress_ValidateCustomerBeforeInsert()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Customer] [Ship-to Address] [Location] [Sales Order] [UT]
        // [SCENARIO 461624] Customer has default "Ship-to Address" defined with "Location Code" defined both on Customer and default "Ship-to Address".
        // [SCENARIO 461624] "Location Code" in Sales Document must be copied from default "Ship-to Address" when Sales Header is inserted after validating "Sell-to Customer No.".
        Initialize();

        // [GIVEN] Create Customer "C10000" with Location "BLUE".
        // [GIVEN] Create Customer Ship-to Address "C10000_SA" with Location "RED".
        // [GIVEN] Update "Ship-to Code" for Customer "C10000".
        CreateCustomerWithLocationAndShipToAddressWithDifferentLocation(Customer, ShipToAddress);

        // [WHEN] Create "Sales Header" for Sales Order and validate "Sell-to Customer No." with "C10000" before inserting Sales Order Header.
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Insert(true);

        // [THEN] "Location Code" = "RED" in the Sales Order.
        SalesHeader.TestField("Location Code", ShipToAddress."Location Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure S461624_DefaultLocationCodeOnSalesOrderFromShipToAddress_ValidateCustomerAfterInsert()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Customer] [Ship-to Address] [Location] [Sales Order] [UT]
        // [SCENARIO 461624] Customer has default "Ship-to Address" defined with "Location Code" defined both on Customer and default "Ship-to Address".
        // [SCENARIO 461624] "Location Code" in Sales Document must be copied from default "Ship-to Address" when Sales Header is inserted before validating "Sell-to Customer No.".
        Initialize();

        // [GIVEN] Create Customer "C10000" with Location "BLUE".
        // [GIVEN] Create Customer Ship-to Address "C10000_SA" with Location "RED".
        // [GIVEN] Update "Ship-to Code" for Customer "C10000".
        CreateCustomerWithLocationAndShipToAddressWithDifferentLocation(Customer, ShipToAddress);

        // [WHEN] Create "Sales Header" for Sales Order and then validate "Sell-to Customer No." with "C10000" after inserting Sales Order Header.
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Modify(true);

        // [THEN] "Location Code" = "RED" in the Sales Order.
        SalesHeader.TestField("Location Code", ShipToAddress."Location Code");
    end;

    [Test]
    procedure S470567_ShipmentMethodAssignmentPriority_CustomerWithoutSM_NoDefaultShipToAddress_ShipToAddressWithoutSM()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Customer] [Ship-to Address] [Shipment Method] [Sales Order] [UT]
        // [SCENARIO 470567] Customer does not have default "Ship-to Address" and "Shipment Method Code" is blank in Customer Card and blank in "Ship-to Address".
        // [SCENARIO 470567] "Shipment Method Code" must be copied from "Customer Card" if ther is not "Ship-to Address" defined or "Ship-to Address" has blank "Shipment Method Code".
        Initialize();

        // [GIVEN] Create Customer "C" without "Shipment Method Code" and without default "Ship-to Address".
        LibrarySales.CreateCustomer(Customer);
        if Customer."Shipment Method Code" <> '' then begin
            Customer.Validate("Shipment Method Code", '');
            Customer.Modify(true);
        end;

        // [GIVEN] Create Customer Ship-to Address "C_SA" without "Shipment Method Code".
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        if ShipToAddress."Shipment Method Code" <> '' then begin
            ShipToAddress.Validate("Shipment Method Code", '');
            ShipToAddress.Modify(true);
        end;

        // [WHEN] Create "Sales Header" for Sales Order and validate "Sell-to Customer No." with "C" after inserting Sales Order Header.
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Modify(true);

        // [THEN] "Shipment Method Code" in the Sales Order = "Shipment Method Code" from "Customer" (blank).
        SalesHeader.TestField("Shipment Method Code", '');

        // [WHEN] Set "C_SA" as "Ship-to Code" in Sales Order.
        SalesHeader.Validate("Ship-to Code", ShipToAddress.Code);
        SalesHeader.Modify(true);

        // [THEN] "Shipment Method Code" in the Sales Order = "Shipment Method Code" from "Customer" (blank).
        SalesHeader.TestField("Shipment Method Code", '');
    end;

    [Test]
    procedure S470567_ShipmentMethodAssignmentPriority_CustomerWithoutSM_NoDefaultShipToAddress_ShipToAddressWithSM()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Customer] [Ship-to Address] [Shipment Method] [Sales Order] [UT]
        // [SCENARIO 470567] Customer does not have default "Ship-to Address" and "Shipment Method Code" is blank in Customer Card, but is defined for "Ship-to Address".
        // [SCENARIO 470567] "Shipment Method Code" must be copied from "Customer Card" if ther is not "Ship-to Address" defined or "Ship-to Address" has blank "Shipment Method Code".
        Initialize();

        // [GIVEN] Create Customer "C" without "Shipment Method Code" and without default "Ship-to Address".
        LibrarySales.CreateCustomer(Customer);
        if Customer."Shipment Method Code" <> '' then begin
            Customer.Validate("Shipment Method Code", '');
            Customer.Modify(true);
        end;

        // [GIVEN] Create Customer Ship-to Address "C_SA" with "Shipment Method Code".
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        if ShipToAddress."Shipment Method Code" = '' then begin
            ShipToAddress.Validate("Shipment Method Code", CreateShipmentMethod());
            ShipToAddress.Modify(true);
        end;

        // [WHEN] Create "Sales Header" for Sales Order and validate "Sell-to Customer No." with "C" after inserting Sales Order Header.
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Modify(true);

        // [THEN] "Shipment Method Code" in the Sales Order = "Shipment Method Code" from "Customer" (blank).
        SalesHeader.TestField("Shipment Method Code", '');

        // [WHEN] Set "C_SA" as "Ship-to Code" in Sales Order.
        SalesHeader.Validate("Ship-to Code", ShipToAddress.Code);
        SalesHeader.Modify(true);

        // [THEN] "Shipment Method Code" in the Sales Order = "Shipment Method Code" from "Ship-to Address".
        SalesHeader.TestField("Shipment Method Code", ShipToAddress."Shipment Method Code");
    end;

    [Test]
    procedure S470567_ShipmentMethodAssignmentPriority_CustomerWithSM_NoDefaultShipToAddress_ShipToAddressWithoutSM()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Customer] [Ship-to Address] [Shipment Method] [Sales Order] [UT]
        // [SCENARIO 470567] Customer does not have default "Ship-to Address" and "Shipment Method Code" is defined for Customer Card and blank in "Ship-to Address".
        // [SCENARIO 470567] "Shipment Method Code" must be copied from "Customer Card" if ther is not "Ship-to Address" defined or "Ship-to Address" has blank "Shipment Method Code".
        Initialize();

        // [GIVEN] Create Customer "C" with "Shipment Method Code" and without default "Ship-to Address".
        LibrarySales.CreateCustomer(Customer);
        if Customer."Shipment Method Code" = '' then begin
            Customer.Validate("Shipment Method Code", CreateShipmentMethod());
            Customer.Modify(true);
        end;

        // [GIVEN] Create Customer Ship-to Address "C_SA" without "Shipment Method Code".
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        if ShipToAddress."Shipment Method Code" <> '' then begin
            ShipToAddress.Validate("Shipment Method Code", '');
            ShipToAddress.Modify(true);
        end;

        // [WHEN] Create "Sales Header" for Sales Order and validate "Sell-to Customer No." with "C" after inserting Sales Order Header.
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Modify(true);

        // [THEN] "Shipment Method Code" in the Sales Order = "Shipment Method Code" from "Customer".
        SalesHeader.TestField("Shipment Method Code", Customer."Shipment Method Code");

        // [WHEN] Set "C_SA" as "Ship-to Code" in Sales Order.
        SalesHeader.Validate("Ship-to Code", ShipToAddress.Code);
        SalesHeader.Modify(true);

        // [THEN] "Shipment Method Code" in the Sales Order = "Shipment Method Code" from "Customer".
        SalesHeader.TestField("Shipment Method Code", Customer."Shipment Method Code");
    end;

    [Test]
    procedure S470567_ShipmentMethodAssignmentPriority_CustomerWithSM_NoDefaultShipToAddress_ShipToAddressWithSM()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Customer] [Ship-to Address] [Shipment Method] [Sales Order] [UT]
        // [SCENARIO 470567] Customer does not have default "Ship-to Address" and "Shipment Method Code" is defined for Customer Card and is defined for "Ship-to Address".
        // [SCENARIO 470567] "Shipment Method Code" must be copied from "Customer Card" if ther is not "Ship-to Address" defined or "Ship-to Address" has blank "Shipment Method Code".
        Initialize();

        // [GIVEN] Create Customer "C" with "Shipment Method Code" and without default "Ship-to Address".
        LibrarySales.CreateCustomer(Customer);
        if Customer."Shipment Method Code" = '' then begin
            Customer.Validate("Shipment Method Code", CreateShipmentMethod());
            Customer.Modify(true);
        end;

        // [GIVEN] Create Customer Ship-to Address "C_SA" with "Shipment Method Code".
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        if ShipToAddress."Shipment Method Code" = '' then begin
            ShipToAddress.Validate("Shipment Method Code", CreateShipmentMethod());
            ShipToAddress.Modify(true);
        end;

        // [WHEN] Create "Sales Header" for Sales Order and validate "Sell-to Customer No." with "C" after inserting Sales Order Header.
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Modify(true);

        // [THEN] "Shipment Method Code" in the Sales Order = "Shipment Method Code" from "Customer".
        SalesHeader.TestField("Shipment Method Code", Customer."Shipment Method Code");

        // [WHEN] Set "C_SA" as "Ship-to Code" in Sales Order.
        SalesHeader.Validate("Ship-to Code", ShipToAddress.Code);
        SalesHeader.Modify(true);

        // [THEN] "Shipment Method Code" in the Sales Order = "Shipment Method Code" from "Ship-to Address".
        SalesHeader.TestField("Shipment Method Code", ShipToAddress."Shipment Method Code");
    end;

    [Test]
    procedure S470567_ShipmentMethodAssignmentPriority_CustomerWithoutSM_DefaultShipToAddress_ShipToAddressWithoutSM()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Customer] [Ship-to Address] [Shipment Method] [Sales Order] [UT]
        // [SCENARIO 470567] Customer has default "Ship-to Address" and "Shipment Method Code" is blank in Customer Card and blank in "Ship-to Address".
        // [SCENARIO 470567] "Shipment Method Code" must be copied from "Customer Card" if ther is not "Ship-to Address" defined or "Ship-to Address" has blank "Shipment Method Code".
        Initialize();

        // [GIVEN] Create Customer "C" without "Shipment Method Code" and without default "Ship-to Address".
        LibrarySales.CreateCustomer(Customer);
        if Customer."Shipment Method Code" <> '' then begin
            Customer.Validate("Shipment Method Code", '');
            Customer.Modify(true);
        end;

        // [GIVEN] Create Customer Ship-to Address "C_SA" without "Shipment Method Code".
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        if ShipToAddress."Shipment Method Code" <> '' then begin
            ShipToAddress.Validate("Shipment Method Code", '');
            ShipToAddress.Modify(true);
        end;

        // [GIVEN] Set "C_SA" as default "Ship-to Address" for Customer "C".
        Customer.Validate("Ship-to Code", ShipToAddress.Code);
        Customer.Modify(true);

        // [WHEN] Create "Sales Header" for Sales Order and validate "Sell-to Customer No." with "C" after inserting Sales Order Header.
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Modify(true);

        // [THEN] "Shipment Method Code" in the Sales Order = "Shipment Method Code" from "Customer" (blank).
        SalesHeader.TestField("Shipment Method Code", '');
    end;

    [Test]
    procedure S470567_ShipmentMethodAssignmentPriority_CustomerWithoutSM_DefaultShipToAddress_ShipToAddressWithSM()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Customer] [Ship-to Address] [Shipment Method] [Sales Order] [UT]
        // [SCENARIO 470567] Customer has default "Ship-to Address" and "Shipment Method Code" is blank in Customer Card, but is defined for "Ship-to Address".
        // [SCENARIO 470567] "Shipment Method Code" must be copied from "Customer Card" if ther is not "Ship-to Address" defined or "Ship-to Address" has blank "Shipment Method Code".
        Initialize();

        // [GIVEN] Create Customer "C" without "Shipment Method Code" and without default "Ship-to Address".
        LibrarySales.CreateCustomer(Customer);
        if Customer."Shipment Method Code" <> '' then begin
            Customer.Validate("Shipment Method Code", '');
            Customer.Modify(true);
        end;

        // [GIVEN] Create Customer Ship-to Address "C_SA" with "Shipment Method Code".
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        if ShipToAddress."Shipment Method Code" = '' then begin
            ShipToAddress.Validate("Shipment Method Code", CreateShipmentMethod());
            ShipToAddress.Modify(true);
        end;

        // [GIVEN] Set "C_SA" as default "Ship-to Address" for Customer "C".
        Customer.Validate("Ship-to Code", ShipToAddress.Code);
        Customer.Modify(true);

        // [WHEN] Create "Sales Header" for Sales Order and validate "Sell-to Customer No." with "C" after inserting Sales Order Header.
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Modify(true);

        // [THEN] "Shipment Method Code" in the Sales Order = "Shipment Method Code" from "Ship-to Address".
        SalesHeader.TestField("Shipment Method Code", ShipToAddress."Shipment Method Code");
    end;

    [Test]
    procedure S470567_ShipmentMethodAssignmentPriority_CustomerWithSM_DefaultShipToAddress_ShipToAddressWithoutSM()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Customer] [Ship-to Address] [Shipment Method] [Sales Order] [UT]
        // [SCENARIO 470567] Customer has default "Ship-to Address" and "Shipment Method Code" is defined for Customer Card and blank in "Ship-to Address".
        // [SCENARIO 470567] "Shipment Method Code" must be copied from "Customer Card" if ther is not "Ship-to Address" defined or "Ship-to Address" has blank "Shipment Method Code".
        Initialize();

        // [GIVEN] Create Customer "C" with "Shipment Method Code" and without default "Ship-to Address".
        LibrarySales.CreateCustomer(Customer);
        if Customer."Shipment Method Code" = '' then begin
            Customer.Validate("Shipment Method Code", CreateShipmentMethod());
            Customer.Modify(true);
        end;

        // [GIVEN] Create Customer Ship-to Address "C_SA" without "Shipment Method Code".
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        if ShipToAddress."Shipment Method Code" <> '' then begin
            ShipToAddress.Validate("Shipment Method Code", '');
            ShipToAddress.Modify(true);
        end;

        // [GIVEN] Set "C_SA" as default "Ship-to Address" for Customer "C".
        Customer.Validate("Ship-to Code", ShipToAddress.Code);
        Customer.Modify(true);

        // [WHEN] Create "Sales Header" for Sales Order and validate "Sell-to Customer No." with "C" after inserting Sales Order Header.
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Modify(true);

        // [THEN] "Shipment Method Code" in the Sales Order = "Shipment Method Code" from "Customer".
        SalesHeader.TestField("Shipment Method Code", Customer."Shipment Method Code");
    end;

    [Test]
    procedure S470567_ShipmentMethodAssignmentPriority_CustomerWithSM_DefaultShipToAddress_ShipToAddressWithSM()
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Customer] [Ship-to Address] [Shipment Method] [Sales Order] [UT]
        // [SCENARIO 470567] Customer has default "Ship-to Address" and "Shipment Method Code" is defined for Customer Card and is defined for "Ship-to Address".
        // [SCENARIO 470567] "Shipment Method Code" must be copied from "Customer Card" if ther is not "Ship-to Address" defined or "Ship-to Address" has blank "Shipment Method Code".
        Initialize();

        // [GIVEN] Create Customer "C" with "Shipment Method Code" and without default "Ship-to Address".
        LibrarySales.CreateCustomer(Customer);
        if Customer."Shipment Method Code" = '' then begin
            Customer.Validate("Shipment Method Code", CreateShipmentMethod());
            Customer.Modify(true);
        end;

        // [GIVEN] Create Customer Ship-to Address "C_SA" with "Shipment Method Code".
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        if ShipToAddress."Shipment Method Code" = '' then begin
            ShipToAddress.Validate("Shipment Method Code", CreateShipmentMethod());
            ShipToAddress.Modify(true);
        end;

        // [GIVEN] Set "C_SA" as default "Ship-to Address" for Customer "C".
        Customer.Validate("Ship-to Code", ShipToAddress.Code);
        Customer.Modify(true);

        // [WHEN] Create "Sales Header" for Sales Order and validate "Sell-to Customer No." with "C" after inserting Sales Order Header.
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.Insert(true);
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Modify(true);

        // [THEN] "Shipment Method Code" in the Sales Order = "Shipment Method Code" from "Ship-to Address".
        SalesHeader.TestField("Shipment Method Code", ShipToAddress."Shipment Method Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGLSplitByAditionalGroupingIdentifer()
    var
        SalesHeader: Record "Sales Header";
        GLEntry: Record "G/L Entry";
        ERMSalesDocument: Codeunit "ERM Sales Document";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] A subscriber can set the Additional Grouping Identifier to split G/L posting by line.
        Initialize();
        // Setup
        CreateSalesInvoiceWithDuplicateLine(SalesHeader);

        // Exercise
        BindSubscription(ERMSalesDocument); // set Additional Grouping Identifier
        CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);

        // Verify
        GLEntry.FindLast();
        GLEntry.SetRange("Transaction No.", GLEntry."Transaction No.");
        Assert.AreEqual(5, GLEntry.Count, 'wrong number of entries');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGLCombineByAditionalGroupingIdentifer()
    var
        SalesHeader: Record "Sales Header";
        GLEntry: Record "G/L Entry";
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] When the Additional Grouping Identifier is not set, lines are not split when posting to G/L.
        Initialize();
        // Setup
        CreateSalesInvoiceWithDuplicateLine(SalesHeader);

        // Exercise
        CODEUNIT.Run(CODEUNIT::"Sales-Post", SalesHeader);

        // Verify
        GLEntry.FindLast();
        GLEntry.SetRange("Transaction No.", GLEntry."Transaction No.");
        Assert.AreEqual(3, GLEntry.Count, 'wrong number of entries');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderCopiedFromArchivedOldVATClauseCodeWhenNoInclHeaderAndNoRecalc()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        OldVATRate: Decimal;
        OldVATClauseCode: Code[20];
        SalesHeaderNo: Code[20];
    begin
        // [FEATURE] [Archive]
        // [SCENARIO 259058] "VAT %" and "VAT Clause Code" are copied from archived line, if Sales Order is copied from Archived Sales Order with "Include Header" = 'No' and "Recalculate Lines" = 'No'
        Initialize();

        // [GIVEN] VAT Posting Setup with "VAT Clause Code" = "A" and "VAT %" = "X"
        CreateVATPostingSetupWithVATClauseCode(VATPostingSetup, CreateVATClauseCode());

        // [GIVEN] Sales Order with one Line, having "VAT Clause Code" = "A" and "VAT %" = "X"
        CreateSalesDocumentWithSetup(SalesHeader, SalesHeader."Document Type"::Order, VATPostingSetup);

        // [GIVEN] Sales Order was archived
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);
        SalesHeaderNo := SalesHeader."No.";

        // [GIVEN] "VAT Clause Code" was changed to "B" and "VAT %" was changed to "Y" in VAT Posting Setup
        OldVATRate := VATPostingSetup."VAT %";
        OldVATClauseCode := VATPostingSetup."VAT Clause Code";
        ModifyVATPostingSetupVATRateAndClauseCode(VATPostingSetup, LibraryRandom.RandDecInRange(10, 20, 2), CreateVATClauseCode());

        // [GIVEN] New Sales Order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SalesHeader."Sell-to Customer No.");

        // [WHEN] Copy Archived Sales Order to new Sales Order with "Include Header" = 'No' and "Recalculate Lines" = 'No'
        CopySalesDocumentFromArchived(SalesHeader, "Sales Document Type From"::"Arch. Order", SalesHeaderNo, false, false, SalesHeader."Document Type");

        // [THEN] New Sales Order has "VAT Clause Code" = "A" and "VAT %" = "X"
        VerifySalesLineVATRateAndClauseCode(SalesHeader."Document Type", SalesHeader."No.", OldVATRate, OldVATClauseCode);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderCopiedFromArchivedOldVATClauseCodeWhenInclHeaderAndNoRecalc()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        OldVATRate: Decimal;
        OldVATClauseCode: Code[20];
        SalesHeaderNo: Code[20];
    begin
        // [FEATURE] [Archive]
        // [SCENARIO 259058] "VAT %" and "VAT Clause Code" are copied from archived line, if Sales Order is copied from Archived Sales Order with "Include Header" = 'Yes' and "Recalculate Lines" = 'No'
        Initialize();

        // [GIVEN] VAT Posting Setup with "VAT Clause Code" = "A" and "VAT %" = "X"
        CreateVATPostingSetupWithVATClauseCode(VATPostingSetup, CreateVATClauseCode());

        // [GIVEN] Sales Order with one Line, having "VAT Clause Code" = "A" and "VAT %" = "X"
        CreateSalesDocumentWithSetup(SalesHeader, SalesHeader."Document Type"::Order, VATPostingSetup);

        // [GIVEN] Sales Order was archived
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);
        SalesHeaderNo := SalesHeader."No.";

        // [GIVEN] "VAT Clause Code" was changed to "B" and "VAT %" was changed to "Y" in VAT Posting Setup
        OldVATRate := VATPostingSetup."VAT %";
        OldVATClauseCode := VATPostingSetup."VAT Clause Code";
        ModifyVATPostingSetupVATRateAndClauseCode(VATPostingSetup, LibraryRandom.RandDecInRange(10, 20, 2), CreateVATClauseCode());

        // [GIVEN] New Sales Order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [WHEN] Copy Archived Sales Order to new Sales Order with "Include Header" = 'Yes' and "Recalculate Lines" = 'No'
        CopySalesDocumentFromArchived(SalesHeader, "Sales Document Type From"::"Arch. Order", SalesHeaderNo, true, false, SalesHeader."Document Type");

        // [THEN] New Sales Order has "VAT Clause Code" = "A" and "VAT %" = "X"
        VerifySalesLineVATRateAndClauseCode(SalesHeader."Document Type", SalesHeader."No.", OldVATRate, OldVATClauseCode);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderCopiedFromArchiveNewVATClauseCodeWhenNoInclHeaderAndRecalc()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesHeaderNo: Code[20];
    begin
        // [FEATURE] [Archive]
        // [SCENARIO 259058] "VAT %" and "VAT Clause Code" are copied from VAT Posting Setup, if Sales Order is copied from Archived Sales Order with "Include Header" = 'No' and "Recalculate Lines" = 'Yes'
        Initialize();

        // [GIVEN] VAT Posting Setup with "VAT Clause Code" = "A" and "VAT %" = "X"
        CreateVATPostingSetupWithVATClauseCode(VATPostingSetup, CreateVATClauseCode());

        // [GIVEN] Sales Order with one Line, having "VAT Clause Code" = "A" and "VAT %" = "X"
        CreateSalesDocumentWithSetup(SalesHeader, SalesHeader."Document Type"::Order, VATPostingSetup);

        // [GIVEN] Sales Order was archived
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);
        SalesHeaderNo := SalesHeader."No.";

        // [GIVEN] "VAT Clause Code" was changed to "B" and "VAT %" was changed to "Y" in VAT Posting Setup
        ModifyVATPostingSetupVATRateAndClauseCode(VATPostingSetup, LibraryRandom.RandDecInRange(10, 20, 2), CreateVATClauseCode());

        // [GIVEN] New Sales Order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SalesHeader."Sell-to Customer No.");

        // [WHEN] Copy Archived Sales Order to new Sales Order with "Include Header" = 'No' and "Recalculate Lines" = 'Yes'
        CopySalesDocumentFromArchived(SalesHeader, "Sales Document Type From"::"Arch. Order", SalesHeaderNo, false, true, SalesHeader."Document Type");

        // [THEN] New Sales Order has "VAT Clause Code" = "B" and "VAT %" = "Y"
        VerifySalesLineVATRateAndClauseCode(
          SalesHeader."Document Type", SalesHeader."No.", VATPostingSetup."VAT %", VATPostingSetup."VAT Clause Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderCopiedFromArchiveNewVATClauseCodeWhenInclHeaderAndRecalc()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesHeaderNo: Code[20];
    begin
        // [FEATURE] [Archive]
        // [SCENARIO 259058] "VAT %" and "VAT Clause Code" are copied from VAT Posting Setup, if Sales Order is copied from Archived Sales Order with "Include Header" = 'Yes' and "Recalculate Lines" = 'Yes'
        Initialize();

        // [GIVEN] VAT Posting Setup with "VAT Clause Code" = "A" and "VAT %" = "X"
        CreateVATPostingSetupWithVATClauseCode(VATPostingSetup, CreateVATClauseCode());

        // [GIVEN] Sales Order with one Line, having "VAT Clause Code" = "A" and "VAT %" = "X"
        CreateSalesDocumentWithSetup(SalesHeader, SalesHeader."Document Type"::Order, VATPostingSetup);

        // [GIVEN] Sales Order was archived
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);
        SalesHeaderNo := SalesHeader."No.";

        // [GIVEN] "VAT Clause Code" was changed to "B" and "VAT %" was changed to "Y" in VAT Posting Setup
        ModifyVATPostingSetupVATRateAndClauseCode(VATPostingSetup, LibraryRandom.RandDecInRange(10, 20, 2), CreateVATClauseCode());

        // [GIVEN] New Sales Order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [WHEN] Copy Archived Sales Order to new Sales Order with "Include Header" = 'Yes' and "Recalculate Lines" = 'Yes'
        CopySalesDocumentFromArchived(SalesHeader, "Sales Document Type From"::"Arch. Order", SalesHeaderNo, true, true, SalesHeader."Document Type");

        // [THEN] New Sales Order has "VAT Clause Code" = "B" and "VAT %" = "Y"
        VerifySalesLineVATRateAndClauseCode(
          SalesHeader."Document Type", SalesHeader."No.", VATPostingSetup."VAT %", VATPostingSetup."VAT Clause Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPartiallyPostedSalesOrderToOrderLastPostingAndShippingNoSAreBlank()
    var
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeaderNo: Code[20];
    begin
        // [FEATURE] [Order] [Copy Document]
        // [SCENARIO 264555] When Sales Order is partially posted and copied to new Sales Order, then new Sales Order has <blank> Last Posting No. and <blank> Last Shipping No.
        Initialize();
        LibrarySales.SetCreditWarnings(SalesReceivablesSetup."Credit Warnings"::"No Warning");
        LibrarySales.SetStockoutWarning(false);

        // [GIVEN] Partially posted Sales Order "SO" with "Qty. to Ship" < Quantity
        PostPartialSalesOrder(SalesHeader);
        SalesHeaderNo := SalesHeader."No.";

        // [GIVEN] Sales Order "O"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');

        // [WHEN] Copy Document "SO" to Sales Order "O"
        CopySalesDocument(SalesHeader, "Sales Document Type From"::Order, SalesHeaderNo);

        // [THEN] "Last Posting No." and "Last Shipping No." are both <blank> in Sales Order "O"
        SalesHeader.TestField("Last Posting No.", '');
        SalesHeader.TestField("Last Shipping No.", '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CopyArchivedPartiallyPostedSalesOrderToOrderLastPostingAndShippingNoSAreBlank()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderNo: Code[20];
    begin
        // [FEATURE] [Archive] [Order] [Copy Document]
        // [SCENARIO 264555] When partially posted Sales Order is archived and then Archived Sales Order is copied to new Sales Order,
        // [SCENARIO 264555] then new Sales Order has <blank> Last Posting No. and <blank> Last Shipping No.
        Initialize();
        LibrarySales.SetStockoutWarning(false);

        // [GIVEN] Partially posted Sales Order "SO" with "Qty. to Ship" < Quantity
        PostPartialSalesOrder(SalesHeader);
        SalesHeaderNo := SalesHeader."No.";

        // [GIVEN] Sales Order "SO" was archived
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);

        // [GIVEN] Sales Order "O"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');

        // [WHEN] Copy Archived Sales Order to Sales Order "O"
        CopySalesDocumentFromArchived(SalesHeader, "Sales Document Type From"::"Arch. Order", SalesHeaderNo, true, false, SalesHeader."Document Type");

        // [THEN] "Last Posting No." and "Last Shipping No." are both <blank> in Sales Order "O"
        SalesHeader.TestField("Last Posting No.", '');
        SalesHeader.TestField("Last Shipping No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopySalesOrderToOrderLastPrepaymentNoSAreBlank()
    var
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeaderNo: Code[20];
    begin
        // [FEATURE] [Order] [Prepayment] [Copy Document]
        // [SCENARIO 264555] When Sales Order has Prepayment Invoice and Credit Memo posted and then Sales Order is copied to new Sales Order,
        // [SCENARIO 264555] then new Sales Order has <blank> Last Prepayment No. and Last Prepmt. Cr. Memo No.
        Initialize();
        LibrarySales.SetCreditWarnings(SalesReceivablesSetup."Credit Warnings"::"No Warning");
        LibrarySales.SetStockoutWarning(false);

        // [GIVEN] Prepayment Invoice and Prepayment Credit Memo were posted for Sales Order "SO"
        PrepareSalesOrderWithPrepaymentInvAndCrMemo(SalesHeader);
        SalesHeaderNo := SalesHeader."No.";

        // [GIVEN] Sales Order "O"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');

        // [WHEN] Copy Document "SO" to Sales Order "O"
        CopySalesDocument(SalesHeader, "Sales Document Type From"::Order, SalesHeaderNo);

        // [THEN] "Last Prepayment No." and "Last Prepmt. Cr. Memo No." are both <blank> in Sales Order "O"
        SalesHeader.TestField("Last Prepayment No.", '');
        SalesHeader.TestField("Last Prepmt. Cr. Memo No.", '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CopyArchivedSalesOrderToOrderLastPrepaymentNoSAreBlank()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderNo: Code[20];
    begin
        // [FEATURE] [Archive] [Order] [Prepayment] [Copy Document]
        // [SCENARIO 264555] When Sales Order has Prepayment Invoice and Credit Memo posted and then Sales Order is archived and then Archived Sales Order is copied to new Sales Order,
        // [SCENARIO 264555] then new Sales Order has <blank> Last Prepayment No. and Last Prepmt. Cr. Memo No.
        Initialize();
        LibrarySales.SetStockoutWarning(false);

        // [GIVEN] Prepayment Invoice and Prepayment Credit Memo were posted for Sales Order "SO"
        PrepareSalesOrderWithPrepaymentInvAndCrMemo(SalesHeader);
        SalesHeaderNo := SalesHeader."No.";

        // [GIVEN] Sales Order "SO" was archived
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);

        // [GIVEN] Sales Order "O"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');

        // [WHEN] Copy Archived Sales Order to Sales Order "O"
        CopySalesDocumentFromArchived(SalesHeader, "Sales Document Type From"::"Arch. Order", SalesHeaderNo, true, false, SalesHeader."Document Type");

        // [THEN] "Last Prepayment No." and "Last Prepmt. Cr. Memo No." are both <blank> in Sales Order "O"
        SalesHeader.TestField("Last Prepayment No.", '');
        SalesHeader.TestField("Last Prepmt. Cr. Memo No.", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyPartiallyPostedSalesReturnOrderToOrderLastReturnReceiptNoIsBlank()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderNo: Code[20];
    begin
        // [FEATURE] [Return Order] [Copy Document]
        // [SCENARIO 264555] When Sales Return Order is partially posted and copied to new Sales Order, then new Sales Order has <blank> Last Return Receipt No.
        Initialize();

        // [GIVEN] Partially posted Sales Return Order "SR" with "Return Qty. to Receive" < Quantity
        PostPartialSalesReturnOrder(SalesHeader);
        SalesHeaderNo := SalesHeader."No.";

        // [GIVEN] Sales Order "O"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');

        // [WHEN] Copy Document "SR" to Sales Order "O"
        CopySalesDocument(SalesHeader, "Sales Document Type From"::"Return Order", SalesHeaderNo);

        // [THEN] "Last Return Receipt No." is <blank> in Sales Order "O"
        SalesHeader.TestField("Last Return Receipt No.", '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CopyArchivedPartiallyPostedSalesReturnOrderToOrderLastReturnReceiptNoIsBlank()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderNo: Code[20];
    begin
        // [FEATURE] [Archive] [Return Order] [Copy Document]
        // [SCENARIO 264555] When Sales Return Order is partially posted and archived and then Archived Sales Return Order is copied to new Sales Order,
        // [SCENARIO 264555] then new Sales Order has <blank> Last Return Receipt No.
        Initialize();

        // [GIVEN] Partially posted Sales Return Order "SR" with "Return Qty. to Receive" < Quantity
        PostPartialSalesReturnOrder(SalesHeader);
        SalesHeaderNo := SalesHeader."No.";

        // [GIVEN] Sales Return Order "SR" was archived
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);

        // [GIVEN] Sales Order "O"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');

        // [WHEN] Copy Archived Sales Return Order to Sales Order "O"
        CopySalesDocumentFromArchived(
          SalesHeader, "Sales Document Type From"::"Arch. Return Order", SalesHeaderNo, true, false, SalesHeader."Document Type"::"Return Order");

        // [THEN] "Last Return Receipt No." is <blank> in Sales Order "O"
        SalesHeader.TestField("Last Return Receipt No.", '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYesNo')]
    [Scope('OnPrem')]
    procedure CancelChangeBillToCustomerNoWhenValidateSellToCustomerNoSales()
    var
        SalesHeader: Record "Sales Header";
        BillToCustNo: Code[20];
    begin
        // [FEATURE] [UI] [UT] [Bill-to Customer]
        // [SCENARIO 288106] Stan validates Sell-to Cust No in Sales Document and cancels change of Bill-to Customer No
        Initialize();

        // [GIVEN] Sales Invoice with a Line
        LibrarySales.CreateSalesInvoice(SalesHeader);

        // [GIVEN] Stan confirmed change of Bill-to Customer No. and line recalculation in Sales Invoice
        BillToCustNo := LibrarySales.CreateCustomerNo();
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        SalesHeader.Validate("Bill-to Customer No.", BillToCustNo);
        SalesHeader.Modify(true);

        // [GIVEN] Stan validated Sell-to Customer No. in Sales Invoice
        LibraryVariableStorage.Enqueue(false);
        SalesHeader.Validate("Sell-to Customer No.");

        // [WHEN] Stan cancels change of Bill-to Customer No.
        // done in ConfirmHandlerYesNo

        // [THEN] Bill-to Customer No. is not changed
        SalesHeader.TestField("Bill-to Customer No.", BillToCustNo);

        // [THEN] No other confirmations pop up and no errors
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CustomerLookupHandler,ConfirmHandlerYesNo')]
    [Scope('OnPrem')]
    procedure LookUpSecondCustomerSameNameAsSellToCustOnSalesInvoice()
    var
        Customer1: Record Customer;
        Customer2: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [UI] [Sell-to Customer]
        // [SCENARIO 294718] Select second customer with the same name when lookup "Sell-to Customer Name" on Sales Invoice
        Initialize();

        // [GIVEN] Customers "Cust1" and "Cust2" with same name "Amazing"
        CreateCustomersWithSameName(Customer1, Customer2);

        // [GIVEN] Sales Invoice card is opened
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibraryVariableStorage.Enqueue(Customer2."No.");
        LibraryVariableStorage.Enqueue(true); // yes to change "Sell-to Customer No."
        LibraryVariableStorage.Enqueue(true); // yes to change "Bill-to Customer No."
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", SalesHeader."No.");

        // [WHEN] Select "Cust2" when lookup "Sell-to Customer Name"
        SalesInvoice."Sell-to Customer Name".Lookup();
        SalesInvoice.Close();

        // [THEN] "Sell-to Customer No." is updated with "Cust2" on the Sales Invoice
        SalesHeader.Find();
        SalesHeader.TestField("Sell-to Customer No.", Customer2."No.");
        SalesHeader.TestField("Sell-to Customer Name", Customer2.Name);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CustomerLookupHandler,ConfirmHandlerYesNo')]
    [Scope('OnPrem')]
    procedure LookUpSecondCustomerSameNameAsBillToCustOnSalesInvoice()
    var
        Customer1: Record Customer;
        Customer2: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [UI] [Bill-to Customer]
        // [SCENARIO 294718] Select second customer with the same name when lookup "Bill-to Customer Name" on Sales Invoice
        Initialize();

        // [GIVEN] Customers "Cust1" and "Cust2" with same name "Amazing"
        CreateCustomersWithSameName(Customer1, Customer2);

        // [GIVEN] Sales Invoice card is opened
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibraryVariableStorage.Enqueue(Customer2."No.");
        LibraryVariableStorage.Enqueue(true); // yes to change "Bill-to Customer No."
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", SalesHeader."No.");

        // [WHEN] Select "Cust2" when lookup "Bill-to Customer Name"
        SalesInvoice."Bill-to Name".Lookup();
        SalesInvoice.Close();

        // [THEN] "Bill-to Customer No." is updated with "Cust2" on the Sales Invoice
        SalesHeader.Find();
        SalesHeader.TestField("Bill-to Customer No.", Customer2."No.");
        SalesHeader.TestField("Bill-to Name", Customer2.Name);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyDocumentLineDescriptionToGLEntry()
    var
        SalesHeader: Record "Sales Header";
        TempSalesLine: Record "Sales Line" temporary;
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [G/L Entry] [Description]
        // [SCENARIO 300843] G/L account type document line Description is copied to G/L entry when SalesSetup."Copy Line Descr. to G/L Entry" = "Yes"
        Initialize();

        // [GIVEN] Set SalesSetup."Copy Line Descr. to G/L Entry" = "Yes"
        SetSalesSetupCopyLineDescrToGLEntry(true);

        // [GIVEN] Create sales order with 5 "G/L Account" type sales lines with unique descriptions "Descr1" - "Descr5"
        CreateSalesOrderWithUniqueDescriptionLines(SalesHeader, TempSalesLine, TempSalesLine.Type::"G/L Account");

        // [WHEN] Sales order is being posted
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] G/L entries created with descriptions "Descr1" - "Descr5"
        VerifyGLEntriesDescription(TempSalesLine, InvoiceNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CombineGLEntriesForTheSameAccountIfCopyDocumentLineDescrToGLEntryIsFalse()
    var
        SalesHeader: Record "Sales Header";
        AccountNo: Code[20];
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [G/L Entry] [Description]
        // [SCENARIO 300843] G/L account type lines combined  to single G/L entry when SalesSetup."Copy Line Descr. to G/L Entry" = "No"
        Initialize();

        // [GIVEN] Set SalesSetup."Copy Line Descr. to G/L Entry" = "No"
        SetSalesSetupCopyLineDescrToGLEntry(false);

        // [GIVEN] Create sales order with sereval "G/L Account" type sales with same G/L Account No.
        AccountNo := CreateSalesOrderWithSameAccountLines(SalesHeader, "Sales Line Type"::"G/L Account", 3);

        // [WHEN] Sales order is being posted
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] One combined G/L entry created
        VerifyCombinedGLEntries(InvoiceNo, AccountNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExtendCopyDocumentLineDescriptionToGLEntry()
    var
        SalesHeader: Record "Sales Header";
        TempSalesLine: Record "Sales Line" temporary;
        ERMSalesDocument: Codeunit "ERM Sales Document";
        InvoiceNo: Code[20];
    begin
        // [FEATURE] [G/L Entry] [Description] [Event]
        // [SCENARIO 300843] Event InvoicePostBuffer.OnAfterInvPostBufferPrepareSales can be used to copy document line Description to G/L entry for Item type
        Initialize();

        // [GIVEN] Subscribe on InvoicePostBuffer.OnAfterInvPostBufferPrepareSales
        BINDSUBSCRIPTION(ERMSalesDocument);

        // [GIVEN] Set SalesSetup."Copy Line Descr. to G/L Entry" = "No"
        SetSalesSetupCopyLineDescrToGLEntry(false);

        // [GIVEN] Create sales order with 5 "Item" type sales lines with unique descriptions "Descr1" - "Descr5"
        CreateSalesOrderWithUniqueDescriptionLines(SalesHeader, TempSalesLine, TempSalesLine.Type::Item);

        // [WHEN] Sales order is being posted
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] G/L entries created with descriptions "Descr1" - "Descr5"
        VerifyGLEntriesDescription(TempSalesLine, InvoiceNo);
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocumentLinesModalPageHandlerWithPostedShipments,MessageHandlerWithEnqueue')]
    [Scope('OnPrem')]
    procedure GetPostedDocToReverseMessageWhenSalesOrderAlreadyReversed()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [UI] [Return Order]
        // [SCENARIO 316339] Warning message when trying to Get Posted Doc to Reverse for already reversed Sales Order
        Initialize();

        // [GIVEN] Posted Sales Order
        CreateSalesDocumentWithItem(
          SalesHeader, SalesHeader."Document Type"::Order, LibraryInventory.CreateItemNo(), LibrarySales.CreateCustomerNo());
        LibraryVariableStorage.Enqueue(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [GIVEN] Posted Sales Return Order for Sales Order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", SalesHeader."Sell-to Customer No.");
        SalesHeader.GetPstdDocLinesToReverse();
        LibraryVariableStorage.Enqueue(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [GIVEN] Sales Return Order and Get Posted Doc to Reverse
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", SalesHeader."Sell-to Customer No.");

        // [GIVEN] Stan selected receipt on page Posted Sales Document Lines
        // done in PostedSalesDocumentLinesModalPageHandlerWithPostedShipments

        // [WHEN] Stan pushes OK on page Posted Sales Document Lines
        SalesHeader.GetPstdDocLinesToReverse();

        // [THEN] Message "One or more return document lines were not copied..."
        Assert.ExpectedMessage(CopyDocForReturnOrderMsg, LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocumentLinesModalPageHandlerWithPostedShipments,MessageHandlerWithEnqueue,ItemTrackingLinesModalPageHandler')]
    [Scope('OnPrem')]
    procedure GetPostedDocToReverseMessageWhenSalesOrderWithItemTrackingAlreadyReversed()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UI] [Return Order] [Item Tracking]
        // [SCENARIO 316339] Warning message when trying to Get Posted Doc to Reverse for already reversed Sales Order with Item Tracking
        Initialize();

        // [GIVEN] Posted Sales Order
        CreateSalesDocumentWithItem(
          SalesHeader, SalesHeader."Document Type"::Order, CreateTrackedItem(), LibrarySales.CreateCustomerNo());
        FindSalesLine(SalesLine, SalesHeader);
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(SalesLine.Quantity);
        SalesLine.OpenItemTrackingLines();
        LibraryVariableStorage.Enqueue(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [GIVEN] Posted Sales Return Order for Sales Order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", SalesHeader."Sell-to Customer No.");
        SalesHeader.GetPstdDocLinesToReverse();
        LibraryVariableStorage.Enqueue(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [GIVEN] Sales Return Order and Get Posted Doc to Reverse
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", SalesHeader."Sell-to Customer No.");

        // [GIVEN] Stan selected receipt on page Posted Sales Document Lines
        // done in PostedSalesDocumentLinesModalPageHandlerWithPostedShipments

        // [WHEN] Stan pushes OK on page Posted Sales Document Lines
        SalesHeader.GetPstdDocLinesToReverse();

        // [THEN] Message "One or more return document lines were not copied..."
        Assert.ExpectedMessage(CopyDocForReturnOrderMsg, LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderDateOnSalesDocumentIsInitializedWithWorkDate()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocType: Enum "Sales Document Type";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 327504] Order Date on sales documents is initialized with WORKDATE. This is required to pick the current sales price.
        Initialize();

        for DocType := SalesHeader."Document Type"::Quote to SalesHeader."Document Type"::"Return Order" do begin
            Clear(SalesHeader);
            CreateSalesDocument(SalesHeader, SalesLine, DocType, '');

            SalesHeader.TestField("Order Date", WorkDate());
        end;
    end;

    [Test]
    [HandlerFunctions('CustomerLookupHandler')]
    [Scope('OnPrem')]
    procedure LookUpSellToCustomerNameValidateItemInLine()
    var
        Customer1: Record Customer;
        Customer2: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InstructionMgt: Codeunit "Instruction Mgt.";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 332188]
        // [SCENARIO 391749] The Customer Lookup page must has Date Filter
        Initialize();
        InstructionMgt.DisableMessageForCurrentUser(InstructionMgt.QueryPostOnCloseCode());

        CreateCustomersWithSameName(Customer1, Customer2);

        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.Insert(true);
        SalesHeader.TestField("No.");

        LibraryVariableStorage.Enqueue(Customer1."No.");

        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", SalesHeader."No.");

        SalesInvoice."Sell-to Customer Name".Lookup();
        SalesInvoice.SalesLines.Type.SetValue(SalesLine.Type::Item);
        SalesInvoice.SalesLines."No.".SetValue(LibraryInventory.CreateItemNo());
        SalesInvoice.Close();

        SalesHeader.Find();
        SalesHeader.TestField("Sell-to Customer No.", Customer1."No.");
        SalesHeader.TestField("Sell-to Customer Name", Customer1.Name);
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);
        SalesLine.TestField(Type);
        SalesLine.TestField("No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CustomerLookupHandler,ConfirmHandlerYesNo')]
    [Scope('OnPrem')]
    procedure LookUpBillToCustomerNameValidateItemInLine()
    var
        Customer1: Record Customer;
        Customer2: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InstructionMgt: Codeunit "Instruction Mgt.";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 332188]
        Initialize();
        InstructionMgt.DisableMessageForCurrentUser(InstructionMgt.QueryPostOnCloseCode());

        CreateCustomersWithSameName(Customer1, Customer2);

        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.Insert(true);
        SalesHeader.TestField("No.");

        LibraryVariableStorage.Enqueue(Customer2."No.");
        LibraryVariableStorage.Enqueue(true);

        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", SalesHeader."No.");

        SalesInvoice."Sell-to Customer No.".SetValue(Customer1."No.");
        SalesInvoice."Bill-to Name".Lookup();
        SalesInvoice.SalesLines.Type.SetValue(SalesLine.Type::Item);
        SalesInvoice.SalesLines."No.".SetValue(LibraryInventory.CreateItemNo());
        SalesInvoice.Close();

        SalesHeader.Find();
        SalesHeader.TestField("Sell-to Customer No.", Customer1."No.");
        SalesHeader.TestField("Sell-to Customer Name", Customer1.Name);
        SalesHeader.TestField("Bill-to Customer No.", Customer2."No.");
        SalesHeader.TestField("Bill-to Name", Customer2.Name);
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);
        SalesLine.TestField(Type);
        SalesLine.TestField("No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidateSellToCustomerNameValidateItemInLine()
    var
        Customer1: Record Customer;
        Customer2: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InstructionMgt: Codeunit "Instruction Mgt.";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 332188]
        Initialize();
        InstructionMgt.DisableMessageForCurrentUser(InstructionMgt.QueryPostOnCloseCode());

        CreateCustomersWithSameName(Customer1, Customer2);

        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.Insert(true);
        SalesHeader.TestField("No.");

        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", SalesHeader."No.");

        SalesInvoice."Sell-to Customer Name".SetValue(Customer1."No.");
        SalesInvoice.SalesLines.Type.SetValue(SalesLine.Type::Item);
        SalesInvoice.SalesLines."No.".SetValue(LibraryInventory.CreateItemNo());
        SalesInvoice.Close();

        SalesHeader.Find();
        SalesHeader.TestField("Sell-to Customer No.", Customer1."No.");
        SalesHeader.TestField("Sell-to Customer Name", Customer1.Name);
        SalesHeader.TestField("Bill-to Customer No.", Customer1."No.");
        SalesHeader.TestField("Bill-to Name", Customer1.Name);
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);
        SalesLine.TestField(Type);
        SalesLine.TestField("No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYesNo')]
    [Scope('OnPrem')]
    procedure ValidateBillToCustomerNameValidateItemInLine()
    var
        Customer1: Record Customer;
        Customer2: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InstructionMgt: Codeunit "Instruction Mgt.";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 332188]
        Initialize();
        InstructionMgt.DisableMessageForCurrentUser(InstructionMgt.QueryPostOnCloseCode());

        CreateCustomersWithSameName(Customer1, Customer2);
        Customer2.Name := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(100, 0), 1, MaxStrLen(Customer2.Name));
        Customer2.Modify(); // we don't need duplicate names in this test

        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.Insert(true);
        SalesHeader.TestField("No.");

        LibraryVariableStorage.Enqueue(true);

        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", SalesHeader."No.");

        SalesInvoice."Sell-to Customer No.".SetValue(Customer1."No.");
        SalesInvoice."Bill-to Name".SetValue(Customer2."No.");
        SalesInvoice.SalesLines.Type.SetValue(SalesLine.Type::Item);
        SalesInvoice.SalesLines."No.".SetValue(LibraryInventory.CreateItemNo());
        SalesInvoice.Close();

        SalesHeader.Find();
        SalesHeader.TestField("Sell-to Customer No.", Customer1."No.");
        SalesHeader.TestField("Sell-to Customer Name", Customer1.Name);
        SalesHeader.TestField("Bill-to Customer No.", Customer2."No.");
        SalesHeader.TestField("Bill-to Name", Customer2.Name);
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);
        SalesLine.TestField(Type);
        SalesLine.TestField("No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesOrderAfterLastAccoutningPeriodWithAutomaticCostAdjustment()
    var
        SalesHeader: Record "Sales Header";
        AccountingPeriod: Record "Accounting Period";
        InventorySetup: Record "Inventory Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Item: Record Item;
        DocumentNo: Code[20];

    begin
        // Verify that Customer ledger entry exist With Document Type Refund when payment method code with balancing account.

        // Setup: Set automatic cost adjustment to always and average costing period to be accounting period
        Initialize();
        InventorySetup.FindFirst();
        InventorySetup."Automatic Cost Adjustment" := InventorySetup."Automatic Cost Adjustment"::Always;
        InventorySetup."Average Cost Period" := InventorySetup."Average Cost Period"::"Accounting Period";
        InventorySetup.Modify();

        // Setup: Create an Item and set the costing method to average
        Item.Get(CreateItem());
        Item.Validate("Costing Method", Item."Costing Method"::Average);
        Item.Modify();

        // Setup: Create Sales Order where the posting date is greater than the last accounting period
        CreateSalesDocumentWithItem(SalesHeader, SalesHeader."Document Type"::Order, Item."No.", CreateCustomer());
        if not AccountingPeriod.FindLast() then begin
            CreateAccountingPeriod();
            AccountingPeriod.FindLast();
        end;
        SalesHeader.Validate("Posting Date", CalcDate('<2D>', AccountingPeriod."Starting Date"));
        SalesHeader.Modify(true);

        // Exercise: Post Sales Order.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Posting succeeds and Custoemr Ledger Entry can be found.
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);
    end;

    [Test]
    //[HandlerFunctions('ConfirmHandler')]
    procedure ErrorGLAccountMustHaveAValueIsShownForPurchaseOrderWithMissingGenBusPostingGroupInGLAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        // [FEATURE] [Invoice Rounding] [Posting Group]
        // [SCENARIO 391619] Create Purchase Order with missing "Invoice Rounding Account" in "Vendor Posting Group"
        Initialize();

        // [GIVEN] "Inv. Rounding Precision (LCY)" = 1 in General Ledger Setup
        LibraryERM.SetInvRoundingPrecisionLCY(1);
        LibrarySales.SetInvoiceRounding(true);

        // [GIVEN] Created Vendor with new Vendor Posting Group
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        Customer.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        Customer.Modify(true);

        // [GIVEN] Delete "Gen. Prod. Posting Group" code from  "Invoice Rounding Account"
        GLAccount.Get(CustomerPostingGroup."Invoice Rounding Account");
        GLAccount."Gen. Prod. Posting Group" := '';
        GLAccount.Modify();

        // [GIVEN] Created Purchase Order
        LibrarySales.CreateSalesHeader(
            SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine.Modify(true);

        // [WHEN] Post Purchase Order with Invoice Rounding Line
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Error has been thrown: "Gen. Prod. Posting Group  is not set for the Prepayment G/L account with no. XXXXX."
        Assert.ExpectedError(
          StrSubstNo(GenProdPostingGroupErr, SalesLine.FieldCaption("Gen. Prod. Posting Group"), GLAccount.Name, GLAccount."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderDefaultLineType_Empty_UT()
    var
        SalesLine: Record "Sales Line";
        SalesLineType: Enum "Sales Line Type";
    begin
        // [SCENARIO 326906] Sales order line "Type" = "Document Default Line Type" from sales setup when InitType()
        Initialize();

        // [GIVEN] Sales & receivables setup "Document Default Line Type" = " "
        SalesLineType := SalesLineType::" ";
        SetDocumentDefaultLineType(SalesLineType);

        // [WHEN] Init sales line type
        SalesLine.GetDefaultLineType();
        InitSalesLineType(SalesLine);

        // [THEN] Sales order line "Type" = "Document Default Line Type"
        VerifySalesLineType(SalesLine, SalesLineType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderDefaultLineType_ChargeItem_UT()
    var
        SalesLine: Record "Sales Line";
        SalesLineType: Enum "Sales Line Type";
    begin
        // [SCENARIO 326906] Sales order line "Type" = "Document Default Line Type" from sales setup when InitType()
        Initialize();

        // [GIVEN] Sales & receivables setup "Document Default Line Type" = "Charge (Item)"
        SalesLineType := SalesLineType::"Charge (Item)";
        SetDocumentDefaultLineType(SalesLineType);

        // [WHEN] Init sales line type
        InitSalesLineType(SalesLine);

        // [THEN] Sales order line "Type" = "Document Default Line Type"
        VerifySalesLineType(SalesLine, SalesLineType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderDefaultLineType_FixedAsset_UT()
    var
        SalesLine: Record "Sales Line";
        SalesLineType: Enum "Sales Line Type";
    begin
        // [SCENARIO 326906] Sales order line "Type" = "Document Default Line Type" from sales setup when InitType()
        Initialize();

        // [GIVEN] Sales & receivables setup "Document Default Line Type" = "Fixed Asset"
        SalesLineType := SalesLineType::"Fixed Asset";
        SetDocumentDefaultLineType(SalesLineType);

        // [WHEN] Init sales line type
        InitSalesLineType(SalesLine);

        // [THEN] Sales order line "Type" = "Document Default Line Type"
        VerifySalesLineType(SalesLine, SalesLineType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderDefaultLineType_GLAccount_UT()
    var
        SalesLine: Record "Sales Line";
        SalesLineType: Enum "Sales Line Type";
    begin
        // [SCENARIO 326906] Sales order line "Type" = "Document Default Line Type" from sales setup when InitType()
        Initialize();

        // [GIVEN] Sales & receivables setup "Document Default Line Type" = "G/L Account"
        SalesLineType := SalesLineType::"G/L Account";
        SetDocumentDefaultLineType(SalesLineType);

        // [WHEN] Init sales line type
        InitSalesLineType(SalesLine);

        // [THEN] Sales order line "Type" = "Document Default Line Type"
        VerifySalesLineType(SalesLine, SalesLineType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderDefaultLineType_Item_UT()
    var
        SalesLine: Record "Sales Line";
        SalesLineType: Enum "Sales Line Type";
    begin
        // [SCENARIO 326906] Sales order line "Type" = "Document Default Line Type" from sales setup when InitType()
        Initialize();

        // [GIVEN] Sales & receivables setup "Document Default Line Type" = Item
        SalesLineType := SalesLineType::Item;
        SetDocumentDefaultLineType(SalesLineType);

        // [WHEN] Init sales line type
        InitSalesLineType(SalesLine);

        // [THEN] Sales order line "Type" = "Document Default Line Type"
        VerifySalesLineType(SalesLine, SalesLineType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderDefaultLineType_Resource_UT()
    var
        SalesLine: Record "Sales Line";
        SalesLineType: Enum "Sales Line Type";
    begin
        // [SCENARIO 326906] Sales order line "Type" = "Document Default Line Type" from sales setup when InitType()
        Initialize();

        // [GIVEN] Sales & receivables setup "Document Default Line Type" = Resource
        SalesLineType := SalesLineType::Resource;
        SetDocumentDefaultLineType(SalesLineType);

        // [WHEN] Init sales line type
        InitSalesLineType(SalesLine);

        // [THEN] Sales order line "Type" = "Document Default Line Type"
        VerifySalesLineType(SalesLine, SalesLineType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReceiveSalesReturnOrderForDeletedShipTo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ShipToAddress: Record "Ship-to Address";
        Customer: Record Customer;
        CustomerNo: Code[20];
        DocumentNo: Code[20];
    begin
        // [SCENARIO 443051] Ensure that Sales return is getting posted even if ship-to code is deleted from the ship-to address table.
        Initialize();

        // [GIVEN] Create customer, Ship-to Address
        CustomerNo := CreateCustomer();
        LibrarySales.CreateShipToAddress(ShipToAddress, CustomerNo);

        // [GIVEN] Update Ship-to code on customer
        Customer.Get(CustomerNo);
        Customer.Validate("Ship-to Code", ShipToAddress.Code);
        Customer.Modify(true);

        // [GIVEN] Create sales return document and update ship-to code of the sales header with customer
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", CustomerNo);
        SalesHeader.Validate("Ship-to Code", ShipToAddress.Code);
        SalesHeader.Modify(true);

        // [GIVEN] Delete ship-to address
        ShipToAddress.Delete(true);

        // [WHEN] Return order is posted
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Order should be posted without any error
        VerifyItemLedgerEntry(DocumentNo, SalesLine."No.", SalesLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyVATAmountAfterPosting()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        // [SCENARIO 456460] Total VAT rounding issue in sales invoice and sales order.
        // [GIVEN] VAT Posting Setup.
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 7);

        // [GIVEN] Create Sales Invoice with new customer and set Price Including VAT true
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify(true);

        // [GIVEN] Create first sales line with new GL Account which have VAT posting setup of 7%
        LibrarySales.CreateSalesLine(
          SalesLine[1], SalesHeader, SalesLine[1].Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale), 3000);
        SalesLine[1].Validate("Unit Price", 1.1);
        SalesLine[1].Modify(true);

        // [GIVEN] Create second sales line with new posting GL and VAT psoting setup will be same
        LibrarySales.CreateSalesLine(
          SalesLine[2], SalesHeader, SalesLine[2].Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale), -1);
        SalesLine[2].Validate("Unit Price", 1650);
        SalesLine[2].Modify(true);

        // [THEN] Post the document
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [VERIFY]  Verify first Sales Line VAT Base Amount and Amount Including VAT on posted invoice.
        SalesInvoiceLine.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesInvoiceLine.SetRange("No.", SalesLine[1]."No.");
        SalesInvoiceLine.FindFirst();
        Assert.AreEqual(SalesLine[1]."VAT Base Amount", SalesInvoiceLine."VAT Base Amount", AmountNotMatchedErr);
        Assert.AreEqual(SalesLine[1]."Amount Including VAT", SalesInvoiceLine."Amount Including VAT", AmountNotMatchedErr);

        // [VERIFY]  Verify second Sales Line VAT Base Amount and Amount Including VAT on posted invoice.
        SalesInvoiceLine.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesInvoiceLine.SetRange("No.", SalesLine[2]."No.");
        SalesInvoiceLine.FindFirst();
        Assert.AreEqual(SalesLine[2]."VAT Base Amount", SalesInvoiceLine."VAT Base Amount", AmountNotMatchedErr);
        Assert.AreEqual(SalesLine[2]."Amount Including VAT", SalesInvoiceLine."Amount Including VAT", AmountNotMatchedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPaymentTermCodeErrorOnDocumentDateBlank()
    var
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 463454]  "You cannot base a date calculation on an undefined date." error message if you try to change the payment terms with a blank document date
        Initialize();

        // [GIVEN] Create Payment Term
        LibraryERM.CreatePaymentTerms(PaymentTerms);

        // [GIVEN] Create Sales Order document
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CreateCustomer());

        // [WHEN] Blank the "Document Date"
        SalesHeader.Validate("Document Date", 0D);
        SalesHeader.Modify();

        // [VERIFY] Verify the "Document Date" error will come.
        asserterror SalesHeader.Validate("Payment Terms Code", PaymentTerms.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,CopyDocRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VerifySalesQuoteIsCreatedWithArchivedSalesQuoteDocument()
    var
        Contact: Record Contact;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        CustomerTemplate: Record "Customer Templ.";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [SCENARIO 461942] Not possible to create a new Sales Quote using Copy Document from an archived Sales Quote which has no Customer No. assigned
        Initialize();

        // [GIVEN] Create Item
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 0));
        Item.Modify(true);

        // [GIVEN] Create Customer Template
        CreateCustomerTemplateWithPostingSetup(CustomerTemplate);

        // [GIVEN] Create Contact
        LibraryMarketing.CreateCompanyContact(Contact);

        // [GIVEN] Created new Sales Quote and Archive Document
        SalesQuote.OpenNew();
        SalesQuote."Sell-to Customer Templ. Code".SetValue(CustomerTemplate.Code);
        SalesQuote."Sell-to Contact No.".SetValue(Contact."No.");
        SalesHeader.Get(SalesHeader."Document Type"::Quote, SalesQuote."No.".Value);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, "Sales Line Type"::Item, Item."No.", LibraryRandom.RandDec(50, 0));
        SalesQuote."Archive Document".Invoke();
        SalesQuote.Close();

        // [GIVEN] Open New Sales Quote Page to Create second new Sales Quote
        SalesQuote.OpenNew();
        SalesQuote."Sell-to Contact No.".Activate();

        // [WHEN] Use function "Copy Document" and use the No. of the first Sales Quote
        LibraryVariableStorage.Enqueue(10); // doc type on the request page
        LibraryVariableStorage.Enqueue(SalesHeader."No.");
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(false);
        Commit();
        SalesQuote.CopyDocument.Invoke();

        // [VERIFY] Verify: Second new Sales Quote is created with contact No.
        Assert.AreEqual(SalesQuote."Sell-to Contact No.".Value, Contact."No.", '');
    end;

    [Test]
    procedure PostingDateModifiesDocumentDate()
    var
        SalesOrder: Record "Sales Header";
        SalesReturnOrder: Record "Sales Header";
        SalesInvoice: Record "Sales Header";
        SalesCreditMemo: Record "Sales Header";
        DocDate, PostingDate : Date;
    begin
        // [SCENARIO] Checks that the SalesReceivablesSetup."Link Doc. Date To Posting Date" setting has the correct effect on sales documents when set to true

        // [GIVEN] Change the setting to true
        SetLinkDocDateToPostingDate(true);

        // [GIVEN] Create sales documents and set the document date
        DocDate := 20000101D;
        LibrarySales.CreateSalesHeader(SalesOrder, "Sales Document Type"::"Order", '');
        SalesOrder.Validate("Document Date", DocDate);
        LibrarySales.CreateSalesHeader(SalesReturnOrder, "Sales Document Type"::"Return Order", '');
        SalesReturnOrder.Validate("Document Date", DocDate);
        LibrarySales.CreateSalesHeader(SalesInvoice, "Sales Document Type"::"Invoice", '');
        SalesInvoice.Validate("Document Date", DocDate);
        LibrarySales.CreateSalesHeader(SalesCreditMemo, "Sales Document Type"::"Credit Memo", '');
        SalesCreditMemo.Validate("Document Date", DocDate);

        // [WHEN] The posting date is modified
        PostingDate := 30000101D;
        SalesOrder.Validate("Posting Date", PostingDate);
        SalesReturnOrder.Validate("Posting Date", PostingDate);
        SalesInvoice.Validate("Posting Date", PostingDate);
        SalesCreditMemo.Validate("Posting Date", PostingDate);

        // [THEN] The document date should be modified
        SalesOrder.TestField("Document Date", PostingDate);
        SalesReturnOrder.TestField("Document Date", PostingDate);
        SalesInvoice.TestField("Document Date", PostingDate);
        SalesCreditMemo.TestField("Document Date", PostingDate);
    end;

    [Test]
    procedure PostingDateModifiesDocumentDateOnInsert()
    var
        SalesHeader: Record "Sales Header";
        PostingDate: Date;
    begin
        // [SCENARIO] Checks that the SalesReceivablesSetup."Link Doc. Date To Posting Date" setting has the correct effect on sales documents when set to true when the document is created

        // [GIVEN] Link Doc. Date To Posting Date is true
        SetLinkDocDateToPostingDate(true);

        // [WHEN] Sales Header is created with posting date
        PostingDate := 30000101D;
        SalesHeader.Init();
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Insert(true);

        // [THEN] The document date is equal to posting date
        Assert.AreEqual(SalesHeader."Document Date", PostingDate, SalesHeader.FieldCaption("Document Date"));
    end;

    [Test]
    procedure PostingDateModifiesDocumentDateOnCustomerSelection()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        PostingDate: Date;
    begin
        // [SCENARIO] Checks that the SalesReceivablesSetup."Link Doc. Date To Posting Date" setting has the correct effect on sales documents when set to true when the customer is populated

        // [GIVEN] Link Doc. Date To Posting Date is true
        SetLinkDocDateToPostingDate(true);

        // [GIVEN] Customer C exists
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Sales Header is created with posting date
        PostingDate := 30000101D;
        SalesHeader.Init();
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Insert(true);

        // [WHEN] Sales Header sell-to customer is updated
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");
        SalesHeader.Modify(true);

        // [THEN] The document date is equal to posting date
        Assert.AreEqual(SalesHeader."Document Date", PostingDate, SalesHeader.FieldCaption("Document Date"));
    end;

    [Test]
    procedure PostingDateDoesNotModifiesDocumentDate()
    var
        SalesOrder: Record "Sales Header";
        SalesReturnOrder: Record "Sales Header";
        SalesInvoice: Record "Sales Header";
        SalesCreditMemo: Record "Sales Header";
        DocDate, PostingDate : Date;
    begin
        // [SCENARIO] Checks that the SalesReceivablesSetup."Link Doc. Date To Posting Date" setting has the correct effect on sales documents when set to false

        // [GIVEN] Change the setting to false
        SetLinkDocDateToPostingDate(false);

        // [GIVEN] Create sales documents and set the document date
        DocDate := 20000101D;
        LibrarySales.CreateSalesHeader(SalesOrder, "Sales Document Type"::"Order", '');
        SalesOrder.Validate("Document Date", DocDate);
        LibrarySales.CreateSalesHeader(SalesReturnOrder, "Sales Document Type"::"Return Order", '');
        SalesReturnOrder.Validate("Document Date", DocDate);
        LibrarySales.CreateSalesHeader(SalesInvoice, "Sales Document Type"::"Invoice", '');
        SalesInvoice.Validate("Document Date", DocDate);
        LibrarySales.CreateSalesHeader(SalesCreditMemo, "Sales Document Type"::"Credit Memo", '');
        SalesCreditMemo.Validate("Document Date", DocDate);

        // [WHEN] The posting date is modified
        PostingDate := 30000101D;
        SalesOrder.Validate("Posting Date", PostingDate);
        SalesReturnOrder.Validate("Posting Date", PostingDate);
        SalesInvoice.Validate("Posting Date", PostingDate);
        SalesCreditMemo.Validate("Posting Date", PostingDate);

        // [THEN] The document date should not be modified
        SalesOrder.TestField("Document Date", DocDate);
        SalesReturnOrder.TestField("Document Date", DocDate);
        SalesInvoice.TestField("Document Date", DocDate);
        SalesCreditMemo.TestField("Document Date", DocDate);
    end;

    [Test]
    procedure PostingDateDoesNotModifiesDocumentDateOnInsert()
    var
        SalesHeader: Record "Sales Header";
        PostingDate: Date;
    begin
        // [SCENARIO] Checks that the SalesReceivablesSetup."Link Doc. Date To Posting Date" setting has the correct effect on sales documents when set to false when the document is created

        // [GIVEN] Link Doc. Date To Posting Date is false
        SetLinkDocDateToPostingDate(false);

        // [WHEN] Sales Header is created with posting date
        PostingDate := 30000101D;
        SalesHeader.Init();
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Insert(true);

        // [THEN] The document date is equal to WorkDate() not to the posting date
        Assert.AreEqual(SalesHeader."Document Date", WorkDate(), SalesHeader.FieldCaption("Document Date"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceHavingAllocationAccountShouldPostGLEntriesWithCorrectDistributedAmounts()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLAccount: array[3] of Record "G/L Account";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        GLEntry: Record "G/L Entry";
        AllocationAccountCode: Code[20];
        Share: array[3] of Decimal;
        Amount: array[3] of Decimal;
        i: Integer;
    begin
        // [SCENARIO 494674] Allocation accounts and discount setup in a Sales document
        Initialize();

        // [GIVEN] Validate Discount Posting as All Discounts and Invoice Rounding as false in Sales & Receivables Setup.
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Discount Posting" := SalesReceivablesSetup."Discount Posting"::"All Discounts";
        SalesReceivablesSetup."Invoice Rounding" := false;
        SalesReceivablesSetup.Modify(true);

        // [GIVEN] Create Allocation Account with Fixed Distribution and save it in a Variable.
        AllocationAccountCode := CreateAllocationAccountWithFixedDistribution();

        // [GIVEN] Generate and save Shares in three Variables.
        Share[1] := LibraryRandom.RandDecInDecimalRange(0.85, 0.85, 2);
        Share[2] := LibraryRandom.RandDecInDecimalRange(0.10, 0.10, 2);
        Share[3] := LibraryRandom.RandDecInDecimalRange(0.05, 0.05, 2);

        // [GIVEN] Add GL Accounts with Share in Fixed Account Distribution.
        for i := 1 to ArrayLen(GLAccount) do
            CreateGLAccountAllocationForFixedDistrubution(AllocationAccountCode, GLAccount[i], Share[i]);

        // [GIVEN] Create Sales Invoice with Allocation Account.
        CreateSalesInvoiceWithAllocationAccount(SalesHeader, SalesLine, AllocationAccountCode);

        // [GIVEN] Generate and save distributed Amounts in three Variables.
        for i := 1 to ArrayLen(Amount) do
            Amount[i] := SalesLine.Amount * Share[i];

        // [GIVEN] Post Sales Invoice.
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [WHEN] Find GL Entry of GL Account 1.
        GLEntry.SetRange("G/L Account No.", GLAccount[1]."No.");
        GLEntry.FindFirst();

        // [THEN] Verify Amount 1 and GL Entry Amount are same.
        Assert.AreEqual(-Amount[1], GLEntry.Amount, AmountNotMatchedErr);

        // [WHEN] Find GL Entry of GL Account 2.
        GLEntry.SetRange("G/L Account No.", GLAccount[2]."No.");
        GLEntry.FindFirst();

        // [THEN] Verify Amount 2 and GL Entry Amount are same.
        Assert.AreEqual(-Amount[2], GLEntry.Amount, AmountNotMatchedErr);

        // [WHEN] Find GL Entry of GL Account 3.
        GLEntry.SetRange("G/L Account No.", GLAccount[3]."No.");
        GLEntry.FindFirst();

        // [THEN] Verify Amount 3 and GL Entry Amount are same.
        Assert.AreEqual(-Amount[3], GLEntry.Amount, AmountNotMatchedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerRegistrationNumberOnSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
    begin
        // [SCENARIO] Check Registration Number on Sales Invoice.
        // [GIVEN]: Create Customer with Registration number and create sales invoice.
        Initialize();
        LibrarySales.CreateCustomerWithVATRegNo(Customer);
        UpdateCustomerRegistrationNumber(Customer);

        // [WHEN]: Create sales invoice for that customer.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [THEN]: Verify Registration number on sales invoice.
        SalesHeader.TestField("Registration Number", Customer."Registration Number");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerRegistrationNumberOnSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
    begin
        // [SCENARIO] Check Registration Number on Sales Credit Memo.
        // [GIVEN]: Create Customer with Registration number and create sales credit memo.
        Initialize();
        LibrarySales.CreateCustomerWithVATRegNo(Customer);
        UpdateCustomerRegistrationNumber(Customer);

        // [WHEN]: Create sales cr. memo for that customer.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");

        // [THEN]: Verify Registration number on sales cr. memo.
        SalesHeader.TestField("Registration Number", Customer."Registration Number");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerRegistrationNumberOnPostedSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        Customer: Record Customer;
    begin
        // [SCENARIO] Check Registration Number on posted Sales Invoice.
        // [GIVEN]: Create Customer with Registration number and create sales invoice.
        Initialize();

        // [WHEN]: Create sales invoice for that customer.
        // [WHEN] Post the sales invoice.
        CreateSalesDocWithRegistrationNo(SalesHeader, Customer, SalesHeader."Document Type"::Invoice);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN]: Verify Registration number on posted sales invoice.
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesInvoiceHeader.FindFirst();
        SalesInvoiceHeader.TestField("Registration Number", Customer."Registration Number");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerRegistrationNumberOnPostedSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Customer: Record Customer;
    begin
        // [SCENARIO] Check Registration Number on Sales Credit Memo.

        // [GIVEN]: Create Customer with Registration number and create sales credit memo.
        Initialize();

        // [WHEN]: Create sales invoice for that customer.
        // [WHEN] Post the sales credit memo.
        CreateSalesDocWithRegistrationNo(SalesHeader, Customer, SalesHeader."Document Type"::"Credit Memo");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN]: Verify Registration number on posted sales credit memo.
        SalesCrMemoHeader.SetRange("Sell-to Customer No.", Customer."No.");
        SalesCrMemoHeader.FindFirst();
        SalesCrMemoHeader.TestField("Registration Number", Customer."Registration Number");
    end;

    [Test]
    procedure SalesInvoiceAmountExclVATWithInheritFromParentAllocationAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLEntry: Record "G/L Entry";
        DimensionValues: array[2] of Record "Dimension Value";
        AllocationAccountNo: Code[20];
        GLAccountNo: Code[20];
        PostedInvoiceNo: Code[20];
        DimSetID: array[2] of Integer;
        Share: array[2] of Decimal;
        Amount: array[2] of Decimal;
        AmtRoundingPrecision: Decimal;
    begin
        // [FEATURE] [Allocation Account] [Sales]
        // [SCENARIO 561035] G/L Entry amounts when Sales Invoice with Amount Incl. VAT not set is posted with Allocation Account with Inherit from parent lines.
        Initialize();

        // [GIVEN] Allocation Account "AA" with Fixed Distribution.
        // [GIVEN] Two distribution lines with Inherit from parent type and Shares 40 and 60.
        // [GIVEN] Lines have Dimension DEPARTMENT with SALES and PROD values.
        Share[1] := 40;
        Share[2] := 60;
        AllocationAccountNo := CreateAllocationAccountWithFixedDistribution();
        CreateDimensionWithValues(DimensionValues);
        DimSetID[1] := CreateInheritFromParentAllocationDistrubWithDimension(AllocationAccountNo, Share[1], DimensionValues[1]);
        DimSetID[2] := CreateInheritFromParentAllocationDistrubWithDimension(AllocationAccountNo, Share[2], DimensionValues[2]);

        // [GIVEN] Sales Invoice with Prices Including VAT not set.
        // [GIVEN] Sales Line with G/L Account "GL1", Amount 1000 and Allocation Account No. "AA".
        CreateSalesInvoiceWithInheritFromParentAllocationAccount(SalesHeader, SalesLine, AllocationAccountNo, false);
        AmtRoundingPrecision := LibraryERM.GetAmountRoundingPrecision();
        Amount[1] := Round(SalesLine.Amount * Share[1] / 100, AmtRoundingPrecision);
        Amount[2] := Round(SalesLine.Amount * Share[2] / 100, AmtRoundingPrecision);
        GLAccountNo := SalesLine."No.";

        // [WHEN] Post Sales Invoice.
        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] Two G/L Entries for G/L Account "GL1" with Amounts 400 and 600 were created.
        GLEntry.SetRange("Document No.", PostedInvoiceNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);

        GLEntry.SetRange("Dimension Set ID", DimSetID[1]);
        GLEntry.FindFirst();
        Assert.AreEqual(-Amount[1], GLEntry.Amount, AmountNotMatchedErr);

        GLEntry.SetRange("Dimension Set ID", DimSetID[2]);
        GLEntry.FindFirst();
        Assert.AreEqual(-Amount[2], GLEntry.Amount, AmountNotMatchedErr);
    end;

    [Test]
    procedure SalesInvoiceAmountInclVATWithInheritFromParentAllocationAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLEntry: Record "G/L Entry";
        DimensionValues: array[2] of Record "Dimension Value";
        AllocationAccountNo: Code[20];
        GLAccountNo: Code[20];
        PostedInvoiceNo: Code[20];
        DimSetID: array[2] of Integer;
        Share: array[2] of Decimal;
        Amount: array[2] of Decimal;
        AmtRoundingPrecision: Decimal;
    begin
        // [FEATURE] [Allocation Account] [Sales]
        // [SCENARIO 561035] G/L Entry amounts when Sales Invoice with Amount Incl. VAT set is posted with Allocation Account with Inherit from parent lines.
        Initialize();

        // [GIVEN] Allocation Account "AA" with Fixed Distribution.
        // [GIVEN] Two distribution lines with Inherit from parent type and Shares 40 and 60.
        // [GIVEN] Lines have Dimension DEPARTMENT with SALES and PROD values.
        Share[1] := 40;
        Share[2] := 60;
        AllocationAccountNo := CreateAllocationAccountWithFixedDistribution();
        CreateDimensionWithValues(DimensionValues);
        DimSetID[1] := CreateInheritFromParentAllocationDistrubWithDimension(AllocationAccountNo, Share[1], DimensionValues[1]);
        DimSetID[2] := CreateInheritFromParentAllocationDistrubWithDimension(AllocationAccountNo, Share[2], DimensionValues[2]);

        // [GIVEN] Sales Invoice with Prices Including VAT set.
        // [GIVEN] Sales Line with G/L Account "GL1", Amount 1000 and Allocation Account No. "AA".
        CreateSalesInvoiceWithInheritFromParentAllocationAccount(SalesHeader, SalesLine, AllocationAccountNo, true);
        AmtRoundingPrecision := LibraryERM.GetAmountRoundingPrecision();
        Amount[1] := Round(SalesLine.Amount * Share[1] / 100, AmtRoundingPrecision);
        Amount[2] := Round(SalesLine.Amount * Share[2] / 100, AmtRoundingPrecision);
        GLAccountNo := SalesLine."No.";

        // [WHEN] Post Sales Invoice.
        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] Two G/L Entries for G/L Account "GL1" with Amounts 400 and 600 were created.
        GLEntry.SetRange("Document No.", PostedInvoiceNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);

        GLEntry.SetRange("Dimension Set ID", DimSetID[1]);
        GLEntry.FindFirst();
        Assert.AreEqual(-Amount[1], GLEntry.Amount, AmountNotMatchedErr);

        GLEntry.SetRange("Dimension Set ID", DimSetID[2]);
        GLEntry.FindFirst();
        Assert.AreEqual(-Amount[2], GLEntry.Amount, AmountNotMatchedErr);
    end;

    [Test]
    procedure AmountUpdatedInSalesInvEntityAggregateTableWhenSaleInvHasLastLineAsGLAccount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesEntityAggregate: Record "Sales Invoice Entity Aggregate";
        LineAmtGLAccount: Decimal;
        LineAmtItem: Decimal;
        TotalAmountIncludingVAT: Decimal;
    begin
        // [SCENARIO 568828] Amount not updated in Sales Inv. Entity Aggregate Table when last line has type G/L Account
        Initialize();

        // [GIVEN] Create Sales Header and 2 Sales Line, 1st line type with Item
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LineAmtItem := CreateSalesLineWithReturnAmt(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItemWithPrice());
        TotalAmountIncludingVAT := SalesLine."Amount Including VAT";

        // [WHEN] 2nd line type with G/L Account
        LineAmtGLAccount := CreateSalesLineWithReturnAmt(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());
        TotalAmountIncludingVAT += SalesLine."Amount Including VAT";

        // [THEN] Check Amount and "Amount Including VAT" on Sales Invoice Entity Aggregate table
        SalesEntityAggregate.SetRange("No.", SalesHeader."No.");
        SalesEntityAggregate.FindFirst();
        Assert.AreEqual(LineAmtGLAccount + LineAmtItem, SalesEntityAggregate.Amount, AmountMustSameErr);
        Assert.AreEqual(TotalAmountIncludingVAT, SalesEntityAggregate."Amount Including VAT", AmountMustSameErr);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesModalPageHandler,SalesCombineShipmentRequestPageHandler,MessageHandler')]
    procedure CheckQtyToHandleOnItemChargeAssignmentWhenMultipleCombinedSalesShipmentsUsedForSameCustomer()
    var
        Customer: Record Customer;
        Item: array[2] of Record Item;
        ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)";
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        Quantity: array[2] of Decimal;
        i: Integer;
    begin
        // [SCENARIO 571650] Verify the quantity to handle across multiple sales shipments for the same customer with item charge assignment.
        Initialize();

        // [GIVEN] Create Customer.
        CreteCombineSalesShipmentCustomer(Customer, Location);

        // [GIVEN] Create and Post Item Journal.
        Quantity[1] := LibraryRandom.RandIntInRange(1000, 2000);
        Quantity[2] := LibraryRandom.RandIntInRange(1, 1);
        for i := 1 to 2 do begin
            // [GIVEN] Create Multiple Items.
            LibraryInventory.CreateItem(Item[i]);
            LibraryInventory.CreateItemJournalLineInItemTemplate(
                ItemJournalLine, Item[i]."No.", Location.Code, '', Quantity[i]);
            LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        end;

        // [GIVEN] Create First Sales Order and Ship.
        CreteSalesOrder(Customer."No.", Item[1]."No.", Quantity[1]);

        // [GIVEN] Create Second Sales Order with Item Charge and Ship.
        CreateSalesOrderWithItemChargeLineAndShip(Customer."No.", Item[2]."No.", Quantity[2]);
        LibraryVariableStorage.Enqueue(Customer."No.");

        // [WHEN] Run Combined Sales Shipment Report for Same Customer.
        Report.Run(Report::"Combine Shipments");

        // [GIVEN] Find Item Charge Assignment Sales Line.
        FindItemChargeAssignmentSalesLine(ItemChargeAssignmentSales, Customer."No.", Item[2]."No.");

        // [THEN] Verify Qty to handle in Item Charge Assignment Sales Line table.
        Assert.AreEqual(ItemChargeAssignmentSales."Qty. to Handle", Quantity[2], QtyHandleMustSameErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RenameItemNoExistsInValueEntry()
    var
        Item: Record Item;
        Item2: Record Item;
        ItemVariant: Record "Item Variant";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NewItemCode: Code[20];
    begin
        // [SCENARIO 574250] Verify Rename Item No. After Posting and Generating Value Entries with Variant Codes and blank Variant Code.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create  an Item Variant for Item.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Create and Post Item Journal with and without Variant Code.
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandDecInRange(10, 20, 2));
        ItemJournalLine.Validate("Variant Code", ItemVariant.Code);
        ItemJournalLine.Modify(true);

        LibraryInventory.CreateItemJournalLine(
         ItemJournalLine, ItemJournalBatch."Journal Template Name",
         ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", LibraryRandom.RandDecInRange(10, 20, 2));

        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [GIVEN] Create and Post Sales Invoice with Variant Code.
        LibrarySales.CreateSalesInvoice(SalesHeader, SalesLine, Item, '', ItemVariant.Code, LibraryRandom.RandDecInRange(5, 10, 2), WorkDate(), LibraryRandom.RandDecInRange(100, 200, 2));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Rename Item No. on Item.
        NewItemCode := LibraryUtility.GenerateRandomCode(Item.FieldNo("No."), Database::Item);
        Item2.Get(Item."No.");
        Item2.Rename(NewItemCode);

        // [THEN] Verify Item No. should be renamed with new Item No.
        Assert.AreEqual(NewItemCode, Item2."No.", StrSubstNo(CannotRenameItemErr, Item2.FieldCaption("No."), Item2.TableCaption()));
    end;

    [Test]
    procedure ReservationQuantityReflectsWrongQuantityOnTheSaleOrderLineWithAlternateUOM()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        UnitOfMeasure: array[2] of Record "Unit of Measure";
        ItemUnitOfMeasure: array[2] of Record "Item Unit of Measure";
        ReservationEntry: Record "Reservation Entry";
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 581623] Incorrect reservation quantity reflects 1.00001 quantity on the Sales order line with alternate UOM even though Base Unit of Measure reflects rounding to 1

        Initialize();

        // [GIVEN] Create Item.
        LibraryInventory.CreateItem(Item);
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify();

        // [GIVEN] Create Unit Of Measure Code 1.
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure[1]);

        // [GIVEN] Create Item Unit Of Measure 1.
        LibraryInventory.CreateItemUnitOfMeasure(
            ItemUnitOfMeasure[1],
            Item."No.",
            UnitOfMeasure[1].Code,
            72);

        // [GIVEN] Create and Post Item Joutnal Line.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', 4);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', 19);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', 49);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        //[GIVEN] Create Sales Order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          Item."No.", 1);
        SalesLine.Validate(Reserve, SalesLine.Reserve::Always);
        SalesLine.modify();
        AutoReserveSalesLine(SalesLine);
        SalesLine.CalcFields("Reserved Quantity");

        //[WHEN] Update Unit Of Measure Code on Sales Line
        SalesLine.Validate("Unit of Measure Code", UnitOfMeasure[1].Code);
        SalesLine.modify();
        AutoReserveSalesLine(SalesLine);

        //[THEN] Check Reserve Quantity must be equal to sales line quantity
        ReservationEntry.SetLoadFields("Source Type", "Source Subtype", "Source ID", "Source Ref. No.", Quantity);
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        ReservationEntry.SetRange("Source ID", SalesLine."Document No.");
        ReservationEntry.SetRange("Source Ref. No.", SalesLine."Line No.");
        ReservationEntry.SetRange("Source Subtype", 1);
        ReservationEntry.CalcSums(Quantity);
        Assert.AreEqual(SalesLine.Quantity, Abs(ReservationEntry.Quantity), '');
    end;

    [Test]
    [HandlerFunctions('ConfirmDueDateBeforeWorkDate,MessageHandlerValidateMessage')]
    [Scope('OnPrem')]
    procedure CheckQuantityBaseMustNotBe0InBinContentErrorShouldNotAppearWhenPostInventoryPick()
    var
        AssemblyItem: Record Item;
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        Customer: Record Customer;
        ItemComponent: Record Item;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        MyNotifications: Record "My Notifications";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InstructionMgt: Codeunit "Instruction Mgt.";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SerialNo: Code[50];
        DueDate: Date;
    begin
        // [SCENARIO 592151] Check "Quantity (Base) must not be 0 in Bin Content" error should not appear when post Inventory Pick for Assembly Item.
        Initialize();

        MyNotifications.Disable(InstructionMgt.GetPostingAfterWorkingDateNotificationId());
        DueDate := LibraryPlanning.SetSafetyWorkDate();
        // [GIVEN] Create Location with required pick
        LibraryWarehouse.CreateLocationWMS(Location, true, true, true, true, false);

        // [GIVEN] Create Bin in Location
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        Location."Default Bin Code" := Bin.Code;
        Location.Modify(true);

        // [GIVEN] Create Warehouse Employee with default location
        CreateDefaultWarehouseEmployee(Location);

        // [GIVEN] Create Assembly Item And Component Item and set as Assembly BOM
        LibraryInventory.CreateItem(AssemblyItem);
        AssemblyItem.Validate("Replenishment System", AssemblyItem."Replenishment System"::Assembly);
        AssemblyItem.Validate("Assembly Policy", Enum::"Assembly Policy"::"Assemble-to-Order");
        AssemblyItem.Validate("Item Tracking Code", 'SNALL');
        AssemblyItem.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        AssemblyItem.Modify(true);
        CreateAssemblyBomComponent(ItemComponent, AssemblyItem."No.");

        //[GIVEN] Bin Content for Assembly Item
        LibraryWarehouse.CreateBinContent(
             BinContent, Location.Code, Bin."Zone Code", Bin.Code, AssemblyItem."No.", '', AssemblyItem."Base Unit of Measure");

        // [GIVEN] Create and Post Item Journal with and without Variant Code.
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
         ItemJournalLine, ItemJournalBatch."Journal Template Name",
         ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemComponent."No.", LibraryRandom.RandDecInRange(10, 20, 2));
        ItemJournalLine."Location Code" := Location.Code;
        ItemJournalLine."Bin Code" := Bin.Code;
        ItemJournalLine.Modify();
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [GIVEN] Create Customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create Item Tracking Line for Assembly Order
        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, LibraryKitting.CreateOrder(DueDate, AssemblyItem."No.", 1));
        AssemblyHeader."Location Code" := Location.Code;
        AssemblyHeader.Modify(true);

        // [GIVEN] Create an Assembly Line for an Item
        CreateAssemblyOrderLine(AssemblyHeader, AssemblyLine, Enum::"BOM Component Type"::Item, ItemComponent."No.", 1, ItemComponent."Base Unit of Measure");
        SerialNo := 'TEST';
        EnqueueValuesForItemTrackingLines(SerialNo, 1);

        // [GIVEN] Create Sales order and create and post Inventory Pick
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(ItemTrackingMode::SelectEntries);
        NotificationLifecycleMgt.RecallAllNotifications();
        CreateSalesHeader(SalesHeader, AssemblyHeader."Due Date");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, AssemblyHeader."Item No.", AssemblyHeader.Quantity);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Modify(true);

        // [THEN] Check that the Inventory Pick is created and Post successfully
        CreateInventoryPickOnSalesLine(SalesLine, Bin.Code);
    end;

    [Test]
    procedure PageReminderTermsIsOpenedWhenOpeningReminderTermsFromCustomerCard()
    var
        Customer: Record Customer;
        ReminderTerms: Record "Reminder Terms";
        CustomerCardPage: TestPage "Customer Card";
        ReminderTermList: TestPage "Reminder Terms List";
    begin
        // [SCENARIO 609480] The old page Reminder Terms is opened when opening the reminder terms from the customer card
        Initialize();

        //[GIVEN] Create Customer and reminder terms
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateReminderTerms(ReminderTerms);

        // [WHEN] Open Customer Card page and click on "Reminder Terms Code" 
        CustomerCardPage.OpenEdit();
        CustomerCardPage.Filter.SetFilter("No.", Customer."No.");
        ReminderTermList.Trap();
        CustomerCardPage."Reminder Terms Code".SetValue(ReminderTerms.Code);

        //[THEN] Check Reminder terms List page open when click on Reminder Term Code on Customer Card
    end;

    local procedure Initialize()
    var
        AllProfile: Record "All Profile";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Sales Document");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Sales Document");

        AllProfile.SetRange("Profile ID", 'ORDER PROCESSOR');
        AllProfile.FindFirst();
        ConfPersonalizationMgt.SetCurrentProfile(AllProfile);

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateLocalData();
        LibraryERMCountryData.UpdatePrepaymentAccounts();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        isInitialized := true;
        Commit();

        LibrarySetupStorage.SaveSalesSetup();
        LibrarySetupStorage.SaveGeneralLedgerSetup();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Sales Document");
    end;

    local procedure PrepareSalesOrderWithPrepaymentInvAndCrMemo(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CreateCustomer());
        ModifySalesPrepaymentAccount(SalesLine);
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandDecInRange(10, 20, 2));
        SalesHeader.Modify(true);
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        LibrarySales.PostSalesPrepaymentCrMemo(SalesHeader);
    end;

    local procedure ModifySalesPrepaymentAccount(var SalesLine: Record "Sales Line")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        GLAccount.Get(GeneralPostingSetup."Sales Prepayments Account");
        GLAccount.Validate("VAT Bus. Posting Group", SalesLine."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", SalesLine."VAT Prod. Posting Group");
        GLAccount.Modify(true);
    end;

    local procedure PostPartialSalesOrder(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CreateCustomer());
        ModifySalesLineQtyToShip(SalesLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure PostPartialSalesReturnOrder(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", CreateCustomer());
        ModifySalesLineReturnQtyToReceive(SalesLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAccountingPeriod()
    var
        AccountingPeriod: Record "Accounting Period";
    begin
        if AccountingPeriod.GetFiscalYearStartDate(WorkDate()) = 0D then begin
            AccountingPeriod.Init();
            AccountingPeriod."Starting Date" := CalcDate('<-CY>', WorkDate());
            AccountingPeriod."New Fiscal Year" := true;
            AccountingPeriod.Insert();
        end;
    end;

    local procedure CreateAdditionalCurrencySetup(var CurrencyCode: Code[10])
    begin
        CurrencyCode := CreateCurrency();
        LibraryERM.SetAddReportingCurrency(CurrencyCode);
        LibraryERM.RunAddnlReportingCurrency(CurrencyCode, CurrencyCode, FindGLAccountNo());
    end;

    local procedure CreateAndPostSalesDocument(var SalesLine: Record "Sales Line"; VATPostingSetup: Record "VAT Posting Setup"; GeneralPostingSetup: Record "General Posting Setup"; DocumentType: Enum "Sales Document Type"; CurrencyCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        ItemNo: Code[20];
    begin
        CustomerNo :=
          CreateAndModifyCustomer(CurrencyCode, GeneralPostingSetup."Gen. Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        ItemNo := CreateAndModifyItem(GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");

        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);

        // Use Random value for Quantity because value is not important.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(100, 2));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostSimpleSalesDocument(DocumentType: Enum "Sales Document Type"; var CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        CustomerNo := LibrarySales.CreateCustomerNo();
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(100, 2));
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesOrderWithStandardTextLine(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CreateCustomer());
        SalesHeader.Validate("Currency Code", CreateCurrency());
        SalesHeader.Modify(true);
        CreateStandardTextLine(SalesLine, SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAnalysisColumnWithItemLedgerEntryType(ItemAnalysisViewAnalysisArea: Enum "Analysis Area Type"; ItemLedgerEntryTypeFilter: Text[250]; ValueType: Enum "Analysis Value Type"): Code[10]
    var
        AnalysisColumnTemplate: Record "Analysis Column Template";
    begin
        LibraryInventory.CreateAnalysisColumnTemplate(AnalysisColumnTemplate, ItemAnalysisViewAnalysisArea);
        CreateAnalysisColumn(AnalysisColumnTemplate.Name, ItemAnalysisViewAnalysisArea, ItemLedgerEntryTypeFilter, ValueType);
        exit(AnalysisColumnTemplate.Name);
    end;

    local procedure CreateAnalysisMultipleColumns(ItemAnalysisViewAnalysisArea: Enum "Analysis Area Type"; ItemLedgerEntryTypeFilter: Text[250]; ValueType: Enum "Analysis Value Type"; ColumnCount: Integer): Code[10]
    var
        AnalysisColumnTemplate: Record "Analysis Column Template";
        Index: Integer;
    begin
        LibraryInventory.CreateAnalysisColumnTemplate(AnalysisColumnTemplate, ItemAnalysisViewAnalysisArea);
        for Index := 1 to ColumnCount do
            CreateAnalysisColumn(AnalysisColumnTemplate.Name, ItemAnalysisViewAnalysisArea, ItemLedgerEntryTypeFilter, ValueType);
        LibraryVariableStorage.Enqueue(ColumnCount);
        exit(AnalysisColumnTemplate.Name);
    end;

    local procedure CreateAnalysisColumn(ColumnTemplateName: Code[10]; ItemAnalysisViewAnalysisArea: Enum "Analysis Area Type"; ItemLedgerEntryTypeFilter: Text[250]; ValueType: Enum "Analysis Value Type")
    var
        AnalysisColumn: Record "Analysis Column";
    begin
        LibraryERM.CreateAnalysisColumn(AnalysisColumn, ItemAnalysisViewAnalysisArea, ColumnTemplateName);
        AnalysisColumn.Validate("Column No.", CopyStr(LibraryUtility.GenerateGUID(), 1, AnalysisColumn.FieldNo("Column No.")));
        AnalysisColumn.Validate(
          "Column Header",
          CopyStr(
            LibraryUtility.GenerateRandomCode(AnalysisColumn.FieldNo("Column Header"), DATABASE::"Analysis Column"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Analysis Column", AnalysisColumn.FieldNo("Column Header"))));
        AnalysisColumn.Validate("Item Ledger Entry Type Filter", ItemLedgerEntryTypeFilter);
        AnalysisColumn.Validate("Value Type", ValueType);
        AnalysisColumn.Modify(true);
    end;

    local procedure CreateAnalysisLine(ItemAnalysisViewAnalysisArea: Enum "Analysis Area Type"; AnalysisLineType: Enum "Analysis Line Type"; RangeValue: Code[20]): Code[10]
    var
        AnalysisLine: Record "Analysis Line";
        AnalysisLineTemplate: Record "Analysis Line Template";
    begin
        LibraryInventory.CreateAnalysisLineTemplate(AnalysisLineTemplate, ItemAnalysisViewAnalysisArea);
        LibraryInventory.CreateAnalysisLine(AnalysisLine, ItemAnalysisViewAnalysisArea, AnalysisLineTemplate.Name);
        AnalysisLine.Validate(Type, AnalysisLineType);
        AnalysisLine.Validate(Range, RangeValue);
        AnalysisLine.Modify(true);
        exit(AnalysisLine."Analysis Line Template Name");
    end;

    local procedure CreateRandomAreaAnalysisLine(var AnalysisLine: Record "Analysis Line")
    var
        AnalysisLineTemplate: Record "Analysis Line Template";
    begin
        LibraryInventory.CreateAnalysisLineTemplate(AnalysisLineTemplate, AnalysisLineTemplate."Analysis Area"::Sales);
        LibraryInventory.CreateAnalysisLine(AnalysisLine, AnalysisLineTemplate."Analysis Area", AnalysisLineTemplate.Name);
    end;

    local procedure CreateNewTemplateAnalysisColumnRandomSet(AnalysisArea: Enum "Analysis Area Type"): Code[10]
    var
        AnalysisColumnTemplate: Record "Analysis Column Template";
        AnalysisColumn: Record "Analysis Column";
        ColumnsQty: Integer;
        i: Integer;
    begin
        ColumnsQty := LibraryRandom.RandInt(10);
        LibraryInventory.CreateAnalysisColumnTemplate(AnalysisColumnTemplate, AnalysisArea);
        for i := 1 to ColumnsQty do
            LibraryInventory.CreateAnalysisColumn(AnalysisColumn, AnalysisArea, AnalysisColumnTemplate.Name);
        exit(AnalysisColumnTemplate.Name);
    end;

    local procedure AnalysisReportManagementCopyColumnsToTemp(var AnalysisColumn: Record "Analysis Column"; AnalysisLine: Record "Analysis Line"; ColumnName: Code[10])
    var
        AnalysisReportManagement: Codeunit "Analysis Report Management";
    begin
        AnalysisLine.SetRange("Analysis Area", AnalysisLine."Analysis Area");
        AnalysisColumn.SetRange("Analysis Column Template", ColumnName);
        AnalysisReportManagement.CopyColumnsToTemp(AnalysisLine, ColumnName, AnalysisColumn);
    end;

    local procedure CreateAnalysisReport(var AnalysisReportName: Record "Analysis Report Name"; var AnalysisLineTemplateName: Code[10]; var AnalysisColumnTemplateName: Code[10]; var ItemNo: Code[20]; RoundingFactor: Decimal)
    var
        AnalysisLine: Record "Analysis Line";
        Item: Record Item;
        ValueEntry: Record "Value Entry";
        AnalysisColumn: Record "Analysis Column";
    begin
        ItemNo := LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateAnalysisReportName(AnalysisReportName, AnalysisReportName."Analysis Area"::Sales);
        AnalysisLineTemplateName :=
          CreateAnalysisLine(AnalysisLine."Analysis Area"::Sales, AnalysisLine.Type::Item, ItemNo);
        AnalysisColumnTemplateName :=
          CreateAnalysisColumnWithItemLedgerEntryType(
            AnalysisReportName."Analysis Area"::Sales,
            Format(ValueEntry."Item Ledger Entry Type"::Sale), AnalysisColumn."Value Type"::"Cost Amount");
        UpdateAnalysisColumnRoundingFactor(AnalysisColumnTemplateName, RoundingFactor);
    end;

    local procedure CreateBinAndBinContent(var Bin: Record Bin; LocationCode: Code[10]; ItemNo: Code[20]; UnitOfMeasure: Code[10]; IsDefault: Boolean)
    var
        BinContent: Record "Bin Content";
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        LibraryWarehouse.CreateBin(Bin, LocationCode, LibraryUtility.GenerateGUID(), '', '');
        LibraryWarehouse.CreateBinContent(BinContent, Bin."Location Code", '', Bin.Code, ItemNo, '', UnitOfMeasure);
        BinContent.Validate(Default, IsDefault);
        BinContent.Modify(true);
    end;

    local procedure CreateLocationWithBinMandatory(): Code[10]
    var
        Location: Record Location;
        LibraryWarehouse: Codeunit "Library - Warehouse";
    begin
        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);
        exit(Location.Code);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20])
    begin
        // Create Sales Order using Random Quantity for Sales Line.
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
    end;

    local procedure CreateSalesDocumentWithLocation(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer());
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
    end;

    local procedure CreateSalesDocumentWithPostingNo(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; PostingDateShift: Integer; PostingNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Posting Date", SalesHeader."Posting Date" + PostingDateShift);
        SalesHeader.Validate("Posting No.", PostingNo);
        SalesHeader.Modify(true);
    end;

    local procedure CreateSalesDocumentWithItem(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"; ItemNo: Code[20]; CustNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, CustNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
    end;

    local procedure CreateSalesInvoiceWithDuplicateLine(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine."Line No." += 10000;
        SalesLine.Insert();
    end;

    local procedure CreateSalesDocWithRegistrationNo(var SalesHeader: Record "Sales Header"; var Customer: Record Customer; SalesDocType: Enum "Sales Document Type")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesLine: Record "Sales Line";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        Customer.Get(CreateCustomer());
        Customer.Validate("Registration Number", LibraryRandom.RandText(20));
        Customer.Modify();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesDocType, Customer."No.");
        CreateSalesLines(SalesLine, SalesHeader);
    end;

    local procedure UpdateCustomerRegistrationNumber(var Customer: Record Customer)
    begin
        Customer.Validate("Registration Number", LibraryRandom.RandText(20));
        Customer.Modify();
    end;

    local procedure SetInvDiscForCustomer(): Code[20]
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
    begin
        // Setting Invoice Discount for Customer.
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CreateCustomer(), '', LibraryRandom.RandInt(10));
        CustInvoiceDisc.Validate("Discount %", LibraryRandom.RandInt(40));
        CustInvoiceDisc.Modify(true);
        exit(CustInvoiceDisc.Code);
    end;

    local procedure CalculateInvDiscount(var SalesLine: Record "Sales Line"; var InvoiceDiscountAmount: Decimal; SalesHeader: Record "Sales Header") DocumentNo: Code[20]
    var
        SalesCalcDiscount: Codeunit "Sales-Calc. Discount";
    begin
        SalesCalcDiscount.Run(SalesLine);
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        InvoiceDiscountAmount := SalesLine."Line Amount" * (SalesHeader."Invoice Discount Value" / 100);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CopyDocument(SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    begin
        LibrarySales.CopySalesDocument(SalesHeader, DocumentType, DocumentNo, true, false);
    end;

    local procedure CreateAndModifyCustomer(CurrencyCode: Code[10]; GenBusPostingGroup: Code[20]; VATBusinessPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", GenBusPostingGroup);
        Customer.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
        exit(Customer."No.");
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

    local procedure CreateCustomerWithPaymentTermsCode(): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Get(CreateCustomer());
        Customer.Validate("Payment Terms Code", CreatePaymentTermsCode());
        Customer.Validate("Combine Shipments", true);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithLocation(var Customer: Record Customer)
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocation(Location);
        LibrarySales.CreateCustomerWithLocationCode(Customer, Location.Code);
    end;

    local procedure CreateCustomerWithSalesperson(var Customer: Record Customer)
    var
        Salesperson: Record "Salesperson/Purchaser";
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateSalesperson(Salesperson);
        LibrarySales.CreateCustomerWithAddress(Customer);
        Customer.Validate("Salesperson Code", Salesperson.Code);
        Customer.Modify(true);
    end;

    local procedure CreateShiptoAddressWithoutSalesperson(var ShiptoAddress: Record "Ship-to Address"; CustomerNo: Code[20])
    var
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateShipToAddress(ShiptoAddress, CustomerNo);
        ShiptoAddress.Validate("Salesperson Code", '');
        ShiptoAddress.Modify(true);
    end;

    local procedure CreateShiptoAddressWithSalesperson(var ShiptoAddress: Record "Ship-to Address"; CustomerNo: Code[20])
    var
        Salesperson: Record "Salesperson/Purchaser";
        LibrarySales: Codeunit "Library - Sales";
    begin
        LibrarySales.CreateSalesperson(Salesperson);
        LibrarySales.CreateShipToAddress(ShiptoAddress, CustomerNo);
        ShiptoAddress.Validate("Salesperson Code", Salesperson.Code);
        ShiptoAddress.Modify(true);
    end;

    local procedure CreateCustomerWithLocationAndShipToAddressWithoutLocation(var Customer: Record Customer; var ShipToAddress: Record "Ship-to Address")
    begin
        CreateCustomerWithLocation(Customer);

        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");

        Customer.Validate("Ship-to Code", ShipToAddress.Code);
        Customer.Modify(true);
    end;

    local procedure CreateCustomerWithLocationAndShipToAddressWithDifferentLocation(var Customer: Record Customer; var ShipToAddress: Record "Ship-to Address")
    var
        ShipToLocation: Record Location;
    begin
        CreateCustomerWithLocation(Customer);

        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        LibraryWarehouse.CreateLocation(ShipToLocation);
        ShipToAddress.Validate("Location Code", ShipToLocation.Code);
        ShipToAddress.Modify(true);

        Customer.Validate("Ship-to Code", ShipToAddress.Code);
        Customer.Modify(true);
    end;

    local procedure CreateCustomersWithSameName(var Customer1: Record Customer; var Customer2: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer1);
        LibrarySales.CreateCustomer(Customer2);
        Customer1.Validate(Name, CopyStr(LibraryUtility.GenerateRandomAlphabeticText(100, 0), 1, MaxStrLen(Customer1.Name)));
        Customer1.Modify(true);
        Customer2.Validate(Name, Customer1.Name);
        Customer2.Modify(true);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Residual Gains Account", Currency."Realized Gains Acc.");
        Currency.Validate("Residual Losses Account", Currency."Realized Losses Acc.");
        Currency.Modify(true);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateAndModifyItem(GenProdPostingGroup: Code[20]; VATProductPostingGroup: Code[20]): Code[20]
    var
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Using RANDOM value for Unit Price.
        Item.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        Item.Validate("VAT Prod. Posting Group", VATProductPostingGroup);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        FindVATPostingSetup(VATPostingSetup);
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Validate("Unit Price", LibraryRandom.RandInt(10));  // Using RANDOM value for Unit Price.
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateTrackedItem(): Code[20]
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false);
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', ItemTrackingCode.Code);
        exit(Item."No.");
    end;

    local procedure CreateValueEntry(ItemNo: Code[20]; var CustomerNo: Code[20]): Decimal
    var
        ValueEntry: Record "Value Entry";
        RecRef: RecordRef;
    begin
        CustomerNo := CreateCustomer();
        ValueEntry.Init();
        RecRef.GetTable(ValueEntry);
        ValueEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, ValueEntry.FieldNo("Entry No."));
        ValueEntry."Item No." := ItemNo;
        ValueEntry."Posting Date" := WorkDate();
        ValueEntry."Item Ledger Entry Type" := ValueEntry."Item Ledger Entry Type"::Sale;
        ValueEntry."Source Type" := ValueEntry."Source Type"::Customer;
        ValueEntry."Source No." := CustomerNo;
        ValueEntry."Cost Amount (Expected)" := LibraryRandom.RandDecInRange(100000, 500000, 2);
        ValueEntry.Insert();
        exit(ValueEntry."Cost Amount (Expected)");
    end;

    local procedure CreatePaymentMethodCode(var PaymentMethod: Record "Payment Method")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Bal. Account No.", GLAccount."No.");
        PaymentMethod.Modify(true);
    end;

    local procedure CreateSalesLines(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    var
        Counter: Integer;
    begin
        // Using random value because value is not important.
        for Counter := 1 to 1 + LibraryRandom.RandInt(5) do
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateStandardTextLine(var SalesLine: Record "Sales Line"; var SalesHeader: Record "Sales Header")
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        SalesLine.Validate(Type, SalesLine.Type::" ");
        SalesLine.Validate("No.", FindStandardTextCode());
        SalesLine.Modify(true);
    end;

    local procedure CreateAndPostSalesOrderWithPaymentTerms(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CreateCustomerWithPaymentTermsCode());
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure CreatePaymentTermsCode(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        PaymentTerms.Validate("Discount %", LibraryRandom.RandDec(10, 2));
        PaymentTerms.Modify(true);
        exit(PaymentTerms.Code);
    end;

    local procedure CreateAndPostSalesOrderWithMultipleLines(CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        CreateSalesLines(SalesLine, SalesHeader);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateSalesReturnOrderByCopyDocument(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; DocType: Enum "Sales Document Type"; PostedSalesHeaderNo: Code[20]; IncludeHeader: Boolean; RecalcLines: Boolean)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", CustomerNo);
        LibrarySales.CopySalesDocument(SalesHeader, DocType, PostedSalesHeaderNo, IncludeHeader, RecalcLines);
    end;

    local procedure SetSalesSetupCopyLineDescrToGLEntry(CopyLineDescrToGLEntry: Boolean)
    var
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        SalesSetup.Get();
        SalesSetup."Copy Line Descr. to G/L Entry" := CopyLineDescrToGLEntry;
        SalesSetup.Modify();
    end;

    local procedure CreateSalesOrderWithUniqueDescriptionLines(var SalesHeader: Record "Sales Header"; var TempSalesLine: Record "Sales Line" temporary; Type: Enum "Sales Line Type")
    var
        SalesLine: Record "Sales Line";
        i: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        for i := 1 to LibraryRandom.RandIntInRange(3, 7) do begin
            case Type of
                SalesLine.Type::"G/L Account":
                    LibrarySales.CreateSalesLine(
                      SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
                SalesLine.Type::Item:
                    LibrarySales.CreateSalesLine(
                      SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
            end;
            SalesLine.Description :=
              COPYSTR(
                LibraryUtility.GenerateRandomAlphabeticText(MAXSTRLEN(SalesLine.Description), 1),
                1,
                MAXSTRLEN(SalesLine.Description));
            SalesLine.Modify();
            TempSalesLine := SalesLine;
            TempSalesLine.Insert();
        end;
    end;

    local procedure CreateSalesOrderWithSameAccountLines(var SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; LineCount: Integer): Code[20]
    var
        SalesLine: Record "Sales Line";
        AccountNo: Code[20];
        i: Integer;
    begin
        AccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        for i := 1 to LineCount do
            case Type of
                SalesLine.Type::"G/L Account":
                    LibrarySales.CreateSalesLine(
                      SalesLine, SalesHeader, SalesLine.Type::"G/L Account", AccountNo, 1);
            end;
        exit(AccountNo);
    end;

    local procedure CreateVATPostingSetupWithVATClauseCode(var VATPostingSetup: Record "VAT Posting Setup"; VATClauseCode: Code[20])
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDecInRange(10, 20, 2));
        ModifyVATPostingSetupVATRateAndClauseCode(VATPostingSetup, LibraryRandom.RandDecInRange(10, 20, 2), VATClauseCode);
    end;

    local procedure CreateVATClauseCode(): Code[20]
    var
        VATClause: Record "VAT Clause";
    begin
        LibraryERM.CreateVATClause(VATClause);
        exit(VATClause.Code);
    end;

    local procedure CreateSalesDocumentWithSetup(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; VATPostingSetup: Record "VAT Posting Setup")
    var
        SalesLine: Record "Sales Line";
        DummyGLAccount: Record "G/L Account";
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader, DocumentType, LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithVATPostingSetup(
            VATPostingSetup, DummyGLAccount."Gen. Posting Type"::Sale), LibraryRandom.RandDecInRange(10, 20, 2));
    end;

    local procedure CopySalesDocumentFromArchived(var ToSalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type From"; DocNo: Code[20];
                                                                                                         IncludeHeader: Boolean;
                                                                                                         RecalculateLines: Boolean;
                                                                                                         ArchivedDocType: Enum "Sales Document Type")
    var
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
        DocNoOccurrence: Integer;
        DocVersionNo: Integer;
    begin
        CopyDocumentMgt.SetProperties(
          IncludeHeader, RecalculateLines, false, false, false, false, false);
        GetDocNoOccurenceAndVersionFromArchivedDoc(DocNoOccurrence, DocVersionNo, ArchivedDocType, DocNo);
        CopyDocumentMgt.SetArchDocVal(DocNoOccurrence, DocVersionNo);
        CopyDocumentMgt.CopySalesDoc(DocType, DocNo, ToSalesHeader);
    end;

    local procedure CopySalesDocument(var ToSalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type From"; DocNo: Code[20])
    var
        CopyDocumentMgt: Codeunit "Copy Document Mgt.";
    begin
        CopyDocumentMgt.SetProperties(true, false, false, false, false, false, false);
        CopyDocumentMgt.CopySalesDoc(DocType, DocNo, ToSalesHeader);
    end;

    local procedure GetDocNoOccurenceAndVersionFromArchivedDoc(var DocNoOccurrence: Integer; var DocVersionNo: Integer; ArchivedDocType: Enum "Sales Document Type"; DocNo: Code[20])
    var
        SalesHeaderArchive: Record "Sales Header Archive";
    begin
        SalesHeaderArchive.SetRange("Document Type", ArchivedDocType);
        SalesHeaderArchive.SetRange("No.", DocNo);
        SalesHeaderArchive.FindFirst();
        DocNoOccurrence := SalesHeaderArchive."Doc. No. Occurrence";
        DocVersionNo := SalesHeaderArchive."Version No.";
    end;

    local procedure VerifySalesLine(SalesHeader: Record "Sales Header"; StandardTextCode: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesLine.FindFirst();
        SalesLine.TestField("No.", StandardTextCode);
        SalesLine.TestField(Type, SalesLine.Type::" ");
    end;

    local procedure SalesLinesWithLineDiscount(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; SalesLineDiscount: Record "Sales Line Discount")
    var
        Counter: Integer;
    begin
        // Using random value for the Quantity. Take Quantity greater than Sales Line Discount Minimum Quantity.
        for Counter := 1 to 1 + LibraryRandom.RandInt(5) do
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::Item, SalesLineDiscount.Code,
              SalesLineDiscount."Minimum Quantity" + LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateSalesLinesFromDocument(var SalesLine: Record "Sales Line"; SalesLine2: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.FindSet();
        repeat
            LibrarySales.CreateSalesLine(SalesLine2, SalesHeader, SalesLine.Type::Item, SalesLine."No.", SalesLine.Quantity);
        until SalesLine.Next() = 0;
    end;

    local procedure OpenAnalysisReportSales(AnalysisReportName: Code[10]; AnalysisLineTemplateName: Code[10]; AnalysisColumnTemplateName: Code[10])
    var
        AnalysisReportSale: TestPage "Analysis Report Sale";
    begin
        AnalysisReportSale.OpenEdit();
        AnalysisReportSale.FILTER.SetFilter(Name, AnalysisReportName);
        AnalysisReportSale."Analysis Line Template Name".SetValue(AnalysisLineTemplateName);
        AnalysisReportSale."Analysis Column Template Name".SetValue(AnalysisColumnTemplateName);
        AnalysisReportSale.EditAnalysisReport.Invoke();
    end;

    local procedure SumLineDiscountAmount(var SalesLine: Record "Sales Line"; DocumentNo: Code[20]) LineDiscountAmount: Decimal
    begin
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindSet();
        repeat
            LineDiscountAmount += SalesLine."Line Discount Amount";
        until SalesLine.Next() = 0;
    end;

    local procedure SumInvoiceDiscountAmount(var SalesLine: Record "Sales Line"; DocumentNo: Code[20]) InvoiceDiscountAmount: Decimal
    begin
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindSet();
        repeat
            InvoiceDiscountAmount += SalesLine."Inv. Discount Amount";
        until SalesLine.Next() = 0;
    end;

    local procedure SetupInvoiceDiscount(var CustInvoiceDisc: Record "Cust. Invoice Disc.")
    begin
        // Using random value for Minimum Amount and Discount Pct fields because value is not important.
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CreateCustomer(), '', LibraryRandom.RandDec(99, 2));
        CustInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(99, 2));
        CustInvoiceDisc.Modify(true);
    end;

    local procedure SetupLineDiscount(var SalesLineDiscount: Record "Sales Line Discount")
    var
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        // Using random value for Minimum Quantity and Line Discount Pct fields because value is not important.
        Item.Get(CreateItem());
        LibraryERM.CreateLineDiscForCustomer(SalesLineDiscount, SalesLineDiscount.Type::Item, Item."No.",
          SalesLineDiscount."Sales Type"::Customer, CreateCustomer(), WorkDate(), '', Item."Variant Filter",
          Item."Base Unit of Measure", LibraryRandom.RandDec(10, 2));
        SalesLineDiscount.Validate("Line Discount %", LibraryRandom.RandDec(99, 2));
        SalesLineDiscount.Modify(true);
    end;

    local procedure TotalLineDiscountInGLEntry(var SalesLine: Record "Sales Line"; DocumentNo: Code[20]): Decimal
    var
        GLEntry: Record "G/L Entry";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        SalesLine.FindSet();
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GeneralPostingSetup."Sales Line Disc. Account");
        exit(TotalAmountInGLEntry(GLEntry));
    end;

    local procedure TotalInvoiceDiscountInGLEntry(var SalesLine: Record "Sales Line"; DocumentNo: Code[20]): Decimal
    var
        GLEntry: Record "G/L Entry";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        SalesLine.FindSet();
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GeneralPostingSetup."Sales Inv. Disc. Account");
        exit(TotalAmountInGLEntry(GLEntry));
    end;

    local procedure TotalAmountInGLEntry(var GLEntry: Record "G/L Entry") TotalAmount: Decimal
    begin
        GLEntry.FindSet();
        repeat
            TotalAmount += GLEntry.Amount;
        until GLEntry.Next() = 0;
    end;

    local procedure FindATOLink(var AssembleToOrderLink: Record "Assemble-to-Order Link"; SalesHeader: Record "Sales Header")
    begin
        AssembleToOrderLink.SetRange("Document Type", SalesHeader."Document Type");
        AssembleToOrderLink.SetRange("Document No.", SalesHeader."No.");
        AssembleToOrderLink.FindFirst();
    end;

    local procedure FindSalesLines(var SalesLine: Record "Sales Line")
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type");
        SalesLine.SetRange("Document No.", SalesLine."Document No.");
        SalesLine.FindSet();
    end;

    local procedure CopySalesLines(var SalesLine: Record "Sales Line"; SalesLine2: Record "Sales Line")
    begin
        FindSalesLines(SalesLine2);
        repeat
            SalesLine.Init();
            SalesLine := SalesLine2;
            SalesLine.Insert();
        until SalesLine2.Next() = 0;
    end;

    local procedure FindCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        CustLedgerEntry.CalcFields(Amount);
    end;

    local procedure FindGLAccountNo(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; GLAccountNo: Code[20])
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.FindFirst();
    end;

    local procedure FindAndUpdateLocation(var "Code": Code[10]; RequireReceive: Boolean) OldRequireReceive: Boolean
    var
        Location: Record Location;
    begin
        Location.SetRange("Bin Mandatory", false);
        Location.SetRange("Use As In-Transit", false);
        Location.FindFirst();
        OldRequireReceive := Location."Require Receive";
        Location.Validate("Require Receive", RequireReceive);
        Location.Modify(true);
        Code := Location.Code;
    end;

    local procedure FindSalesInvoiceHeaderNo(DocumentNo: Code[20]): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Pre-Assigned No.", DocumentNo);
        SalesInvoiceHeader.FindFirst();
        exit(SalesInvoiceHeader."No.");
    end;

    local procedure FindSalesCreditMemoHeaderNo(PreAssignedNo: Code[20]): Code[20]
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        SalesCrMemoHeader.FindFirst();
        exit(SalesCrMemoHeader."No.");
    end;

    local procedure FindShipmentHeaderNo(OrderNo: Code[20]): Code[20]
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesShipmentHeader.SetRange("Order No.", OrderNo);
        SalesShipmentHeader.FindFirst();
        exit(SalesShipmentHeader."No.");
    end;

    local procedure FindPostedSalesInvoiceNo(OrderNo: Code[20]): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Order No.", OrderNo);
        SalesInvoiceHeader.FindFirst();
        exit(SalesInvoiceHeader."No.");
    end;

    local procedure FindReturnReceiptHeaderNo(OrderNo: Code[20]): Code[20]
    var
        ReturnReceiptHeader: Record "Return Receipt Header";
    begin
        ReturnReceiptHeader.SetRange("Return Order No.", OrderNo);
        ReturnReceiptHeader.FindFirst();
        exit(ReturnReceiptHeader."No.");
    end;

    local procedure FindSalesCrMemoHeaderNo(OrderNo: Code[20]): Code[20]
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.SetRange("Return Order No.", OrderNo);
        SalesCrMemoHeader.FindFirst();
        exit(SalesCrMemoHeader."No.");
    end;

    local procedure FindStandardTextCode(): Code[20]
    var
        StandardText: Record "Standard Text";
    begin
        StandardText.Next(LibraryRandom.RandInt(StandardText.Count));
        exit(StandardText.Code);
    end;

    local procedure FindValueEntry(var ValueEntry: Record "Value Entry"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    begin
        ValueEntry.SetRange("Document Type", DocumentType);
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.FindSet();
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; DocumentNo: Code[20])
    begin
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::"Credit Memo");
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
    end;

    local procedure FindVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
    end;

    local procedure FindSalesCrMemoHeader(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; ReturnOrderNo: Code[20])
    begin
        SalesCrMemoHeader.SetRange("Return Order No.", ReturnOrderNo);
        SalesCrMemoHeader.FindFirst();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst();
    end;

    local procedure FindAndDeleteOneSalesLine(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.Delete();
    end;

    local procedure InitSetupForSalesDocumentWithBinContent(var SalesLine: Record "Sales Line"): Code[20]
    var
        Item: Record Item;
        DefaultBin: Record Bin;
        Bin: Record Bin;
    begin
        // Create Assembly Item with Bin Content.
        Initialize();
        LibraryInventory.CreateItem(Item);
        UpdateItemParameters(Item, Item."Replenishment System"::Assembly, Item."Assembly Policy"::"Assemble-to-Order");
        CreateBinAndBinContent(DefaultBin, CreateLocationWithBinMandatory(), Item."No.", Item."Base Unit of Measure", true); // True for Default Bin.
        CreateBinAndBinContent(Bin, DefaultBin."Location Code", Item."No.", Item."Base Unit of Measure", false); // False for not Default Bin.

        // Create Sales Document with Location and update Bin Code.
        CreateSalesDocumentWithLocation(SalesLine, SalesLine."Document Type"::Order, Item."No.", DefaultBin."Location Code");
        SalesLine.Validate("Bin Code", Bin.Code);
        SalesLine.Modify(true);
        exit(Bin.Code);
    end;

    local procedure ModifySalesLineQtyToShip(var SalesLine: Record "Sales Line")
    begin
        SalesLine.Validate("Qty. to Ship", SalesLine."Qty. to Ship" / 2);
        SalesLine.Modify(true);
    end;

    local procedure ModifySalesLineReturnQtyToReceive(var SalesLine: Record "Sales Line")
    begin
        SalesLine.Validate("Return Qty. to Receive", SalesLine."Return Qty. to Receive" / 2);
        SalesLine.Modify(true);
    end;

    local procedure SetSalesandReceivablesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();  // Fix for Number Series Error.
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure SetNoSeriesDateOrder(DateOrder: Boolean) OldDateOrder: Boolean
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NoSeries: Record "No. Series";
    begin
        SalesReceivablesSetup.Get();
        NoSeries.Get(SalesReceivablesSetup."Posted Invoice Nos.");
        OldDateOrder := NoSeries."Date Order";
        NoSeries.Validate("Date Order", DateOrder);
        NoSeries.Modify(true);
    end;

    local procedure UpdateGeneralPostingSetup(var GeneralPostingSetup: Record "General Posting Setup"; AccountNo: Code[20])
    begin
        GeneralPostingSetup.Validate("Sales Pmt. Disc. Debit Acc.", AccountNo);
        GeneralPostingSetup.Validate("Sales Pmt. Disc. Credit Acc.", AccountNo);
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdateRemainingPmtDiscPossible(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentNo: Code[20])
    begin
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, DocumentNo);
        CustLedgerEntry.CalcFields(Amount);
        CustLedgerEntry.Validate("Remaining Pmt. Disc. Possible", CustLedgerEntry.Amount / 2);
        CustLedgerEntry.Modify(true);
    end;

    local procedure UpdateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; var OldAdjustForPaymentDiscount: Boolean; NewAdjustForPaymentDiscount: Boolean; NewVATPercentage: Decimal) OldVATPercentage: Decimal
    begin
        OldAdjustForPaymentDiscount := VATPostingSetup."Adjust for Payment Discount";
        OldVATPercentage := VATPostingSetup."VAT %";
        VATPostingSetup.Validate("Adjust for Payment Discount", NewAdjustForPaymentDiscount);
        VATPostingSetup.Validate("VAT %", NewVATPercentage);
        VATPostingSetup.Modify(true);
    end;

    local procedure UpdateExactCostReversingMandatory(NewExactCostReversingMandatory: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Exact Cost Reversing Mandatory", NewExactCostReversingMandatory);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateQuantityOnSalesLineByPage(DocumentNo: Code[20]; Qty: Decimal)
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", DocumentNo);
        SalesOrder.SalesLines.Quantity.SetValue(Qty); // Required for test to update it on page.
        SalesOrder.OK().Invoke();
    end;

    local procedure UpdateQtyToAsmToOrderOnSalesLineByPage(DocumentNo: Code[20]; QtyToAssemble: Decimal)
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", DocumentNo);
        SalesOrder.SalesLines."Qty. to Assemble to Order".SetValue(QtyToAssemble); // Required for test to update it on page.
        SalesOrder.OK().Invoke();
    end;

    local procedure UpdateItemParameters(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; AssemblyPolicy: Enum "Assembly Policy")
    begin
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Assembly Policy", AssemblyPolicy);
        Item.Modify(true);
    end;

    local procedure UpdateAnalysisColumnRoundingFactor(AnalysisColumnTemplateName: Code[10]; RoundingFactor: Integer)
    var
        AnalysisColumn: Record "Analysis Column";
    begin
        AnalysisColumn.SetRange("Analysis Area", AnalysisColumn."Analysis Area"::Sales);
        AnalysisColumn.SetRange("Analysis Column Template", AnalysisColumnTemplateName);
        AnalysisColumn.FindLast();
        case RoundingFactor of
            0:
                AnalysisColumn."Rounding Factor" := AnalysisColumn."Rounding Factor"::None;
            1:
                AnalysisColumn."Rounding Factor" := AnalysisColumn."Rounding Factor"::"1";
            1000:
                AnalysisColumn."Rounding Factor" := AnalysisColumn."Rounding Factor"::"1000";
            1000000:
                AnalysisColumn."Rounding Factor" := AnalysisColumn."Rounding Factor"::"1000000";
        end;
        AnalysisColumn.Modify();
    end;

    local procedure ModifyVATPostingSetupVATRateAndClauseCode(var VATPostingSetup: Record "VAT Posting Setup"; VATRate: Decimal; VATClauseCode: Code[20])
    begin
        VATPostingSetup.Validate("VAT %", VATRate);
        VATPostingSetup.Validate("VAT Clause Code", VATClauseCode);
        VATPostingSetup.Modify(true);
    end;

    local procedure RoundCostAmount(Amount: Decimal; RoundingFactor: Integer): Decimal
    begin
        case RoundingFactor of
            0:
                exit(Amount);
            1:
                exit(Round(Amount, 1));
            1000:
                exit(Round(Amount / 1000, 0.1));
            1000000:
                exit(Round(Amount / 1000000, 0.1));
        end;
    end;

    local procedure AnalysisReportSalePageOpen(var SalesAnalysisReport: TestPage "Sales Analysis Report"; AnalysisReportName: Record "Analysis Report Name"; AnalysisLineTemplateName: Code[10]; AnalysisColumnTemplateName: Code[10])
    var
        AnalysisReportSale: TestPage "Analysis Report Sale";
    begin
        AnalysisReportSale.OpenView();
        AnalysisReportSale.GotoRecord(AnalysisReportName);
        AnalysisReportSale."Analysis Line Template Name".SetValue(AnalysisLineTemplateName);
        AnalysisReportSale."Analysis Column Template Name".SetValue(AnalysisColumnTemplateName);
        SalesAnalysisReport.Trap();
        AnalysisReportSale.EditAnalysisReport.Invoke();
    end;

    local procedure SalesAnalysisReportPageShowMatrix(SalesAnalysisReport: TestPage "Sales Analysis Report"; CustomerNo: Code[20])
    var
        SalesPeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        Sourcetypefilter: Option ,Customer,Vendor,Item;
    begin
        SalesAnalysisReport.PeriodType.SetValue(SalesPeriodType::Year);
        SalesAnalysisReport.CurrentSourceTypeFilter.SetValue(Sourcetypefilter::Customer);
        SalesAnalysisReport.CurrentSourceTypeNoFilter.SetValue(CustomerNo);
        SalesAnalysisReport.ShowMatrix.Invoke();
    end;

    local procedure SetSalesReceivablesSetupStockoutCreditWarning(CreditWarnings: Option; StockoutWarning: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Credit Warnings", CreditWarnings);
        SalesReceivablesSetup.Validate("Stockout Warning", StockoutWarning);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure SetDocumentDefaultLineType(SalesLineType: Enum "Sales Line Type")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Document Default Line Type" := SalesLineType;
        SalesReceivablesSetup.Modify();
    end;

    local procedure InitSalesLineType(var SalesLine: Record "Sales Line")
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine.Type := SalesLine.GetDefaultLineType();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Post Invoice Events", 'OnAfterPrepareInvoicePostingBuffer', '', false, false)]
    local procedure OnAfterPrepareSales(var SalesLine: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        // Example of extending feature "Copy document line description to G/L entries" for lines with type = "Item"
        if InvoicePostingBuffer.Type = InvoicePostingBuffer.Type::Item then begin
            InvoicePostingBuffer."Fixed Asset Line No." := SalesLine."Line No.";
            InvoicePostingBuffer."Entry Description" := SalesLine.Description;
            InvoicePostingBuffer.BuildPrimaryKey();
        end;
    end;

    local procedure VerifyAmountOnGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount2: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          Amount2,
          GLEntry.Amount,
          LibraryERM.GetInvoiceRoundingPrecisionLCY(),
          StrSubstNo(ValidateError, GLEntry.FieldCaption(Amount), Amount2, GLEntry.TableCaption(), GLEntry.FieldCaption("Entry No."), GLEntry."Entry No."));
    end;

    local procedure VerifyACYAmountOnGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount2: Decimal; CurrencyCode: Code[10])
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, DocumentNo, GLAccountNo);
        Amount2 := LibraryERM.ConvertCurrency(Amount2, '', CurrencyCode, WorkDate());
        Assert.AreNearlyEqual(
          Amount2, GLEntry."Additional-Currency Amount", LibraryERM.GetInvoiceRoundingPrecisionLCY(),
          StrSubstNo(ValidateError, GLEntry.FieldCaption("Additional-Currency Amount"), GLEntry.Amount,
            GLEntry.TableCaption, GLEntry.FieldCaption("Entry No."), GLEntry."Entry No."));
    end;

    local procedure VerifyAmountLCYOnCustLedger(DocumentNo: Code[20]; AmountLCY: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields("Amount (LCY)");
        Assert.AreNearlyEqual(
          AmountLCY,
          CustLedgerEntry."Amount (LCY)",
          LibraryERM.GetInvoiceRoundingPrecisionLCY(),
          StrSubstNo(ValidateError, CustLedgerEntry.FieldCaption("Amount (LCY)"), AmountLCY, CustLedgerEntry.TableCaption(), CustLedgerEntry.FieldCaption("Entry No."), CustLedgerEntry."Entry No."));
    end;

    local procedure VerifyBinCodeOnSalesLine(ItemNo: Code[20]; BinCode: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("No.", ItemNo);
        SalesLine.FindFirst();
        Assert.AreEqual(BinCode, SalesLine."Bin Code", UpdateBinCodeErr);
    end;

    local procedure VerifyRemainingAmountOnLedger(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; RemainingAmount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.SetRange("Document Type", DocumentType);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields("Remaining Amount");
        Assert.AreNearlyEqual(
          RemainingAmount,
          CustLedgerEntry."Remaining Amount",
          LibraryERM.GetInvoiceRoundingPrecisionLCY(),
          StrSubstNo(
            ValidateError, CustLedgerEntry.FieldCaption("Remaining Amount"), RemainingAmount, CustLedgerEntry.TableCaption(), CustLedgerEntry.FieldCaption("Entry No."), CustLedgerEntry."Entry No."));
    end;

    local procedure VerifyCustomerLedgerEntry(ReturnOrderNo: Code[20]; Amount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        GeneralLedgerSetup.Get();
        FindSalesCrMemoHeader(SalesCrMemoHeader, ReturnOrderNo);
        FindCustLedgerEntry(CustLedgerEntry, SalesCrMemoHeader."No.", CustLedgerEntry."Document Type"::"Credit Memo");
        Assert.AreNearlyEqual(Amount, CustLedgerEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(FieldError, CustLedgerEntry.FieldCaption(Amount), Amount, CustLedgerEntry.TableCaption()));
    end;

    local procedure VerifyGLEntry(ReturnOrderNo: Code[20]; Amount: Decimal; AccountNo: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLEntry: Record "G/L Entry";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        GeneralLedgerSetup.Get();
        FindSalesCrMemoHeader(SalesCrMemoHeader, ReturnOrderNo);
        FindGLEntry(GLEntry, SalesCrMemoHeader."No.", AccountNo);
        Assert.AreNearlyEqual(Amount, GLEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(FieldError, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption()));
    end;

    local procedure VerifyInvoiceDiscountAmount(SalesLine: Record "Sales Line"; InvoiceDiscountAmount: Decimal; DocumentNo: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        GLEntry: Record "G/L Entry";
    begin
        GeneralLedgerSetup.Get();
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GeneralPostingSetup."Sales Inv. Disc. Account");
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(
          InvoiceDiscountAmount, GLEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(FieldError, GLEntry.FieldCaption(Amount), InvoiceDiscountAmount, GLEntry.TableCaption()));
    end;

    local procedure VerifyVATEntry(ReturnOrderNo: Code[20]; VATAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATEntry: Record "VAT Entry";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        GeneralLedgerSetup.Get();
        FindSalesCrMemoHeader(SalesCrMemoHeader, ReturnOrderNo);
        FindVATEntry(VATEntry, SalesCrMemoHeader."No.");
        Assert.AreNearlyEqual(VATAmount, -VATEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(VATAmountError, VATEntry.FieldCaption(Amount), VATEntry.Amount, VATEntry.TableCaption()));
    end;

    local procedure VerifyValueEntries(ReturnOrderNo: Code[20]; CostAmount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        ValueEntry: Record "Value Entry";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        TotalCostAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        FindSalesCrMemoHeader(SalesCrMemoHeader, ReturnOrderNo);
        FindValueEntry(ValueEntry, ValueEntry."Document Type"::"Sales Credit Memo", SalesCrMemoHeader."No.");
        repeat
            TotalCostAmount += ValueEntry."Sales Amount (Actual)";
        until ValueEntry.Next() = 0;
        Assert.AreNearlyEqual(-CostAmount, TotalCostAmount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(FieldError, ValueEntry.FieldCaption("Cost Amount (Actual)"), TotalCostAmount, ValueEntry.TableCaption()));
    end;

    local procedure VerifyLocationOnCreditMemo(ReturnOrderNo: Code[20]; LocationCode: Code[20])
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        FindSalesCrMemoHeader(SalesCrMemoHeader, ReturnOrderNo);
        SalesCrMemoLine.SetRange("Document No.", SalesCrMemoHeader."No.");
        SalesCrMemoLine.FindFirst();
        Assert.AreEqual(
          LocationCode, SalesCrMemoLine."Location Code",
          StrSubstNo(FieldError, SalesCrMemoLine.FieldCaption("Location Code"),
            LocationCode, SalesCrMemoLine.TableCaption()));
    end;

    local procedure VerifyCurrencyOnPostedOrder(ReturnOrderNo: Code[20]; CurrencyCode: Code[10])
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        FindSalesCrMemoHeader(SalesCrMemoHeader, ReturnOrderNo);
        SalesCrMemoHeader.Get(SalesCrMemoHeader."No.");
        Assert.AreEqual(
          CurrencyCode, SalesCrMemoHeader."Currency Code",
          StrSubstNo(
            FieldError,
            SalesCrMemoHeader.FieldCaption("Currency Code"),
            CurrencyCode, SalesCrMemoHeader.TableCaption()));
    end;

    local procedure VerifyPartialSalesOrder(SalesLine: Record "Sales Line"; DocumentNo: Code[20]; QuantityShipped: Decimal)
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        // Verify Quantity Shipped in Sales Line and Posted Sales Invoice Line.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        SalesLine.TestField("Quantity Shipped", QuantityShipped);

        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField(Quantity, QuantityShipped);
    end;

    local procedure VerifyPostedReturnOrderLine(var SalesLine: Record "Sales Line")
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoHeader.SetRange("Return Order No.", SalesLine."Document No.");
        SalesCrMemoHeader.FindFirst();
        repeat
            SalesCrMemoLine.Get(SalesCrMemoHeader."No.", SalesLine."Line No.");
            SalesCrMemoLine.TestField(Quantity, SalesLine.Quantity);
            SalesCrMemoLine.TestField("Unit Price", SalesLine."Unit Price");
        until SalesLine.Next() = 0;
    end;

    local procedure VerifySalesShipmentLine(SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        SalesShipmentLine.FindFirst();
        SalesShipmentLine.TestField("No.", SalesLine."No.");
        SalesShipmentLine.TestField(Quantity, SalesLine.Quantity);
    end;

    local procedure VerifySalesInvoiceLine(SalesLine: Record "Sales Line"; PostedInvoiceNo: Code[20])
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", PostedInvoiceNo);
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField("No.", SalesLine."No.");
        SalesInvoiceLine.TestField(Quantity, SalesLine.Quantity);
    end;

    local procedure VerifyVATOnSalesCreditMemo(SalesLine: Record "Sales Line")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATAmountSalesLine: Decimal;
    begin
        GeneralLedgerSetup.Get();
        FindSalesLines(SalesLine);
        repeat
            VATAmountSalesLine := SalesLine."Line Amount" * (1 + SalesLine."VAT %" / 100);
            Assert.AreNearlyEqual(
              VATAmountSalesLine, SalesLine."Amount Including VAT", GeneralLedgerSetup."Amount Rounding Precision",
              StrSubstNo(FieldError, SalesLine.FieldCaption("Amount Including VAT"), VATAmountSalesLine, SalesLine.TableCaption()));
        until SalesLine.Next() = 0;
    end;

    local procedure VerifyGLEntryForCreditMemo(DocumentNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetFilter(Amount, '>0');
        Assert.AreNearlyEqual(
          Amount, TotalAmountInGLEntry(GLEntry), GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(FieldError, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption()));
    end;

    local procedure VerifyGLEntriesDescription(var TempSalesLine: Record "Sales Line" temporary; InvoiceNo: code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SETRANGE("Document No.", InvoiceNo);
        TempSalesLine.FindSet();
        repeat
            GLEntry.SETRANGE(Description, TempSalesLine.Description);
            Assert.RecordIsNotEmpty(GLEntry);
        until TempSalesLine.Next() = 0;
    end;

    local procedure VerifyCombinedGLEntries(InvoiceNo: Code[20]; AccountNo: Code[20])
    var
        GLEntry: Record "g/l Entry";
    begin
        GLEntry.SETRANGE("Document No.", InvoiceNo);
        GLEntry.SETRANGE("G/L Account No.", AccountNo);
        Assert.IsTrue(GLEntry.Count() = 1, 'One G/L Entry should be posted');
    end;

    local procedure VerifyVATEntryForCreditMemo(DocumentNo: Code[20]; Amount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATEntry: Record "VAT Entry";
        TotalVATAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindSet();
        repeat
            TotalVATAmount += Abs(VATEntry.Base + VATEntry.Amount);
        until VATEntry.Next() = 0;
        Assert.AreNearlyEqual(
          Amount, TotalVATAmount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(FieldError, VATEntry.FieldCaption(Amount), Amount, VATEntry.TableCaption()));
    end;

    local procedure VerifyLedgerEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields("Amount (LCY)");
        Assert.AreNearlyEqual(
          Amount, -CustLedgerEntry."Amount (LCY)", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(FieldError, CustLedgerEntry.FieldCaption("Amount (LCY)"), Amount, CustLedgerEntry.TableCaption()));
    end;

    local procedure VerifyLineDiscountOnCreditMemo(SalesLine: Record "Sales Line")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        LineDiscountAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        FindSalesLines(SalesLine);
        repeat
            LineDiscountAmount := Round(SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."Line Discount %" / 100);
            Assert.AreNearlyEqual(
              LineDiscountAmount, SalesLine."Line Discount Amount", GeneralLedgerSetup."Amount Rounding Precision",
              StrSubstNo(FieldError, SalesLine.FieldCaption("Line Discount Amount"), LineDiscountAmount, SalesLine.TableCaption()));
        until SalesLine.Next() = 0;
    end;

    local procedure VerifyInvoiceDiscount(SalesLine: Record "Sales Line"; CustInvoiceDisc: Record "Cust. Invoice Disc.")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        InvoiceDiscountAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        FindSalesLines(SalesLine);
        repeat
            InvoiceDiscountAmount := Round(SalesLine."Line Amount" * CustInvoiceDisc."Discount %" / 100);
            Assert.AreNearlyEqual(
              InvoiceDiscountAmount, SalesLine."Inv. Discount Amount", GeneralLedgerSetup."Amount Rounding Precision",
              StrSubstNo(FieldError, SalesLine.FieldCaption("Inv. Discount Amount"), InvoiceDiscountAmount, SalesLine.TableCaption()));
        until SalesLine.Next() = 0;
    end;

    local procedure VerifyItemLedgerEntry(DocumentNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyReturnReceiptLine(SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    var
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        ReturnReceiptLine.SetRange("Document No.", DocumentNo);
        ReturnReceiptLine.FindFirst();
        ReturnReceiptLine.TestField("No.", SalesLine."No.");
        ReturnReceiptLine.TestField(Quantity, SalesLine.Quantity);
    end;

    local procedure VerifySalesCrMemoLine(SalesLine: Record "Sales Line"; PostedInvoiceNo: Code[20])
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoLine.SetRange("Document No.", PostedInvoiceNo);
        SalesCrMemoLine.FindFirst();
        SalesCrMemoLine.TestField("No.", SalesLine."No.");
        SalesCrMemoLine.TestField(Quantity, SalesLine.Quantity);
    end;

    local procedure VerifyPaymentDiscountOnSalesInvoice(SalesHeaderOrder: Record "Sales Header")
    var
        SalesHeaderInvoice: Record "Sales Header";
    begin
        SalesHeaderInvoice.SetRange("Document Type", SalesHeaderInvoice."Document Type"::Invoice);
        SalesHeaderInvoice.SetRange("Sell-to Customer No.", SalesHeaderOrder."Sell-to Customer No.");
        SalesHeaderInvoice.SetRange("Payment Terms Code", SalesHeaderOrder."Payment Terms Code");
        SalesHeaderInvoice.FindFirst();
        SalesHeaderInvoice.TestField("Payment Discount %", SalesHeaderOrder."Payment Discount %");
    end;

    local procedure VerifySalesReturnOrderLine(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.TestField("Appl.-from Item Entry");
    end;

    local procedure VerifySalesLineVATRateAndClauseCode(DocType: Enum "Sales Document Type"; DocNo: Code[20];
                                                                     VATRate: Decimal;
                                                                     VATClauseCode: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", DocType);
        SalesLine.SetRange("Document No.", DocNo);
        SalesLine.FindFirst();
        SalesLine.TestField("VAT %", VATRate);
        SalesLine.TestField("VAT Clause Code", VATClauseCode);
    end;

    local procedure VerifySalesLineType(SalesLine: Record "Sales Line"; SalesLineType: Enum "Sales Line Type")
    begin
        SalesLine.TestField(Type, SalesLineType);
    end;

    local procedure CreateCustomerTemplateWithPostingSetup(var CustomerTemplate: Record "Customer Templ.")
    var
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");

        LibraryTemplates.CreateCustomerTemplate(CustomerTemplate);
        CustomerTemplate.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        CustomerTemplate.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        CustomerTemplate.Validate("Customer Posting Group", LibrarySales.FindCustomerPostingGroup());
        CustomerTemplate.Modify(true);
    end;

    local procedure CreateShipmentMethod(): Code[10]
    var
        ShipmentMethod: Record "Shipment Method";
    begin
        ShipmentMethod.Init();
        ShipmentMethod.Code := LibraryUtility.GenerateRandomCode(ShipmentMethod.FieldNo(Code), Database::"Shipment Method");
        ShipmentMethod.Insert();
        exit(ShipmentMethod.Code);
    end;

    local procedure CreateSalesInvoiceWithAllocationAccount(
          var SalesHeader: Record "Sales Header";
          var SalesLine: Record "Sales Line";
          AllocationAccountCode: Code[20])
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(
            SalesLine,
            SalesHeader,
            SalesLine.Type::"Allocation Account",
            AllocationAccountCode,
            LibraryRandom.RandIntInRange(6, 6));

        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1500, 1500, 0));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesInvoiceWithInheritFromParentAllocationAccount(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; AllocationAccountNo: Code[20]; PricesInclVAT: Boolean)
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, Enum::"Tax Calculation Type"::"Normal VAT");
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);

        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify(true);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Validate("Prices Including VAT", PricesInclVAT);
        Customer.Modify(true);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
            GLAccount."No.", LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Validate("Selected Alloc. Account No.", AllocationAccountNo);
        SalesLine.Modify(true);
    end;

    local procedure CreateAllocationAccountWithFixedDistribution(): Code[20]
    var
        AllocationAccount: Record "Allocation Account";
    begin
        AllocationAccount."No." := Format(LibraryRandom.RandText(5));
        AllocationAccount."Account Type" := AllocationAccount."Account Type"::Fixed;
        AllocationAccount.Name := Format(LibraryRandom.RandText(10));
        AllocationAccount.Insert();

        exit(AllocationAccount."No.");
    end;

    local procedure CreateGLAccountAllocationForFixedDistrubution(AllocationAccountNo: Code[20]; var GLAccount: Record "G/L Account"; Shape: Decimal)
    var
        AllocAccountDistribution: Record "Alloc. Account Distribution";
    begin
        if GLAccount."No." = '' then
            GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());

        AllocAccountDistribution."Allocation Account No." := AllocationAccountNo;
        AllocAccountDistribution."Line No." := LibraryUtility.GetNewRecNo(AllocAccountDistribution, AllocAccountDistribution.FieldNo("Line No."));
        AllocAccountDistribution."Account Type" := AllocAccountDistribution."Account Type"::Fixed;
        AllocAccountDistribution."Destination Account Type" := AllocAccountDistribution."Destination Account Type"::"G/L Account";
        AllocAccountDistribution."Destination Account Number" := GLAccount."No.";
        AllocAccountDistribution.Validate(Share, Shape);
        AllocAccountDistribution.Insert();
    end;

    local procedure CreateInheritFromParentAllocationDistrubWithDimension(AllocationAccountNo: Code[20]; Share: Decimal; DimensionValue: Record "Dimension Value") DimSetID: Integer
    var
        AllocAccountDistribution: Record "Alloc. Account Distribution";
    begin
        DimSetID := LibraryDimension.CreateDimSet(0, DimensionValue."Dimension Code", DimensionValue.Code);

        AllocAccountDistribution."Allocation Account No." := AllocationAccountNo;
        AllocAccountDistribution."Line No." := LibraryUtility.GetNewRecNo(AllocAccountDistribution, AllocAccountDistribution.FieldNo("Line No."));
        AllocAccountDistribution."Account Type" := AllocAccountDistribution."Account Type"::Fixed;
        AllocAccountDistribution."Destination Account Type" := AllocAccountDistribution."Destination Account Type"::"Inherit from Parent";
        AllocAccountDistribution.Validate(Share, Share);
        AllocAccountDistribution.Validate("Dimension Set ID", DimSetID);
        AllocAccountDistribution.Insert();
    end;

    local procedure CreateDimensionWithValues(var DimensionValues: array[2] of Record "Dimension Value")
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValues[1], Dimension.Code);
        LibraryDimension.CreateDimensionValue(DimensionValues[2], Dimension.Code);
    end;

    local procedure SetLinkDocDateToPostingDate(NewValue: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Link Doc. Date To Posting Date", NewValue);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure CreateItemWithPrice(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Last Direct Cost", LibraryRandom.RandInt(100));
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateSalesLineWithReturnAmt(var SalesLine: Record "sales Line"; SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; No: Code[20]): Decimal
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, 1);
        SalesLine.Validate("Unit Cost", 100 + LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);
        exit(SalesLine."Line Amount");
    end;

    local procedure CreteCombineSalesShipmentCustomer(var Customer: Record Customer; var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Combine Shipments", true);
        Customer.Validate("Location Code", Location.Code);
        Customer.Modify(true);
    end;

    local procedure CreteSalesOrder(CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);

        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure CreateSalesOrderWithItemChargeLineAndShip(CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemCharge: Record "Item Charge";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrderPage: TestPage "Sales Order";
    begin
        ItemCharge.FindFirst();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)", ItemCharge."No.", Quantity);
        SalesLine.Validate("Unit Price", LibraryRandom.RandInt(10000));
        SalesLine.Modify(true);

        CrateSalesLineWithItemCharge(SalesHeader, ItemNo, Quantity, SalesLine."Line No.");

        // Open sales order page & assign item charge.
        SalesOrderPage.OpenEdit();
        SalesOrderPage.Filter.SetFilter("Document Type", Format(SalesHeader."Document Type"));
        SalesOrderPage.Filter.SetFilter("No.", SalesHeader."No.");
        SalesOrderPage.SalesLines.Filter.SetFilter(Type, Format(SalesLine.Type::"Charge (Item)"));
        SalesOrderPage.SalesLines."Item Charge &Assignment".Invoke();
        SalesOrderPage.Close();

        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure CrateSalesLineWithItemCharge(SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; LineNo: Integer)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.Init();
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        SalesLine.Validate("Line No.", LineNo / 2);
        SalesLine.Validate(Type, SalesLine.Type::Item);
        SalesLine.Validate("No.", ItemNo);
        SalesLine.Validate(Quantity, Quantity);
        SalesLine.Insert(true);
    end;

    local procedure FindSalesInvoice(CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        SalesHeader.FindFirst();

        exit(SalesHeader."No.");
    end;

    local procedure FindItemChargeAssignmentSalesLine(var ItemChargeAssignmentSales: Record "Item Charge Assignment (Sales)"; CustomerNo: Code[20]; ItemNo: Code[20])
    begin
        ItemChargeAssignmentSales.SetRange("Document Type", ItemChargeAssignmentSales."Document Type"::Invoice);
        ItemChargeAssignmentSales.SetRange("Document No.", FindSalesInvoice(CustomerNo));
        ItemChargeAssignmentSales.SetRange("Item No.", ItemNo);
        ItemChargeAssignmentSales.FindFirst();
    end;

    local procedure CreateInventoryPickOnSalesLine(var SalesLine: Record "Sales Line"; BinCode: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        PickCreated: Label 'Number of Invt. Pick activities created: 1 out of a total of 1.';
    begin
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryVariableStorage.Enqueue(PickCreated);
        LibraryWarehouse.CreateInvtPutPickMovement(SalesHeader."Document Type", SalesHeader."No.", false, true, false);
        FindWarehouseActivityLine(
          WarehouseActivityLine, SalesHeader."No.", WarehouseActivityLine."Activity Type"::"Invt. Pick", SalesLine."Location Code",
          WarehouseActivityLine."Action Type"::Take);
        WarehouseActivityLine.Validate("Qty. to Handle", WarehouseActivityLine.Quantity);
        WarehouseActivityLine.Validate("Serial No.", 'TEST');
        WarehouseActivityLine.Validate("Bin Code", BinCode);
        WarehouseActivityLine.Modify(true);

        //Post Inventory Pick
        WarehouseActivityHeader.SetRange("No.", WarehouseActivityLine."No.");
        WarehouseActivityHeader.FindFirst();
        LibraryWarehouse.PostInventoryActivity(WarehouseActivityHeader, false);
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type"; LocationCode: Code[10]; ActionType: Enum "Warehouse Action Type")
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Location Code", LocationCode);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.SetRange("Action Type", ActionType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure EnqueueValuesForItemTrackingLines(LotNo: Code[50]; Qty: Decimal)
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingMode::AssignSerialNo);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; ShipmentDate: Date)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Order Date", ShipmentDate);
        SalesHeader.Validate("Shipment Date", ShipmentDate);
        SalesHeader.Modify(true);
    end;

    local procedure CreateAssemblyOrderLine(AssemblyHeader: Record "Assembly Header"; var AssemblyLine: Record "Assembly Line"; Type: Enum "BOM Component Type"; No: Code[20]; Quantity: Decimal; UoM: Code[10])
    var
        RecRef: RecordRef;
    begin
        if No <> '' then begin
            LibraryAssembly.CreateAssemblyLine(AssemblyHeader, AssemblyLine, Type, No, UoM, Quantity, 1, '');
            exit;
        end;
        Clear(AssemblyLine);
        AssemblyLine."Document Type" := AssemblyHeader."Document Type";
        AssemblyLine."Document No." := AssemblyHeader."No.";
        RecRef.GetTable(AssemblyLine);
        AssemblyLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, AssemblyLine.FieldNo("Line No.")));
        AssemblyLine.Insert(true);
        AssemblyLine.Validate(Type, Type);
        AssemblyLine.Modify(true);
    end;

    local procedure CreateAssemblyBomComponent(var Item: Record Item; ParentItemNo: Code[20])
    var
        BomComponent: Record "BOM Component";
        BomRecordRef: RecordRef;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        Item.Validate("Replenishment System", Item."Replenishment System"::Purchase);
        Item.Modify(true);

        BomComponent.Init();
        BomComponent.Validate(BomComponent."Parent Item No.", ParentItemNo);
        BomRecordRef.GetTable(BomComponent);
        BomComponent.Validate(BomComponent."Line No.", LibraryUtility.GetNewLineNo(BomRecordRef, BomComponent.FieldNo(BomComponent."Line No.")));
        BomComponent.Validate(BomComponent.Type, BomComponent.Type::Item);
        BomComponent.Validate(BomComponent."No.", Item."No.");
        BomComponent.Validate(BomComponent."Quantity per", LibraryRandom.RandInt(10));
        BomComponent.Insert(true);
    end;

    local procedure CreateDefaultWarehouseEmployee(var NewDefaultLocation: Record Location)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.SetRange(Default, true);
        if WarehouseEmployee.FindFirst() then begin
            if WarehouseEmployee."Location Code" <> NewDefaultLocation.Code then begin
                WarehouseEmployee.Delete(true);
                LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, NewDefaultLocation.Code, true);
            end;
        end
        else
            LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, NewDefaultLocation.Code, true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        // Confirm Handler for the Confirmation message and always send reply as TRUE.
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetReturnReceiptHandler(var GetReturnReceiptLines: TestPage "Get Return Receipt Lines")
    begin
        GetReturnReceiptLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesDocumentLinesHandler(var PostedSalesDocumentLines: TestPage "Posted Sales Document Lines")
    var
        StandardTextCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(StandardTextCode);
        PostedSalesDocumentLines.PostedInvoices.FILTER.SetFilter("No.", StandardTextCode);
        PostedSalesDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesDocumentLinesWithSpecificCrMemoValidationHandler(var PostedSalesDocumentLines: TestPage "Posted Sales Document Lines")
    begin
        PostedSalesDocumentLines.PostedCrMemos."Document No.".AssertEquals(LibraryVariableStorage.DequeueText());
        PostedSalesDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesDocumentLinesModalPageHandlerWithPostedShipments(var PostedSalesDocumentLines: TestPage "Posted Sales Document Lines")
    begin
        PostedSalesDocumentLines.PostedShpts.FILTER.SetFilter("Document No.", LibraryVariableStorage.DequeueText());
        PostedSalesDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQtyToCreate(var EnterQtyToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQtyToCreate.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CombineShipmentRequestPageHandler(var CombineShipments: TestRequestPage "Combine Shipments")
    begin
        CombineShipments.PostingDate.SetValue(CalcDate('<1M>', WorkDate()));
        CombineShipments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CopyDocRequestPageHandler(var CopySalesDocument: TestRequestPage "Copy Sales Document")
    var
        ValueFromQueue: Variant;
    begin
        LibraryVariableStorage.Dequeue(ValueFromQueue); // Doc type
        CopySalesDocument.DocumentType.SetValue(ValueFromQueue);

        LibraryVariableStorage.Dequeue(ValueFromQueue); // Doc no
        CopySalesDocument.DocumentNo.SetValue(ValueFromQueue);

        LibraryVariableStorage.Dequeue(ValueFromQueue); // Sell-to no
        CopySalesDocument.SellToCustNo.SetValue(ValueFromQueue);

        LibraryVariableStorage.Dequeue(ValueFromQueue); // Sell-to name
        CopySalesDocument.SellToCustName.SetValue(ValueFromQueue);

        LibraryVariableStorage.Dequeue(ValueFromQueue); // Include header
        CopySalesDocument.IncludeHeader_Options.SetValue(ValueFromQueue);

        LibraryVariableStorage.Dequeue(ValueFromQueue); // Recalc lines
        CopySalesDocument.RecalculateLines.SetValue(ValueFromQueue);

        CopySalesDocument.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageVerificationHandler(Message: Text[1024])
    var
        DequeueVariable: Variant;
        ExpectedMessage: Text[1024];
    begin
        LibraryVariableStorage.Dequeue(DequeueVariable);
        ExpectedMessage := DequeueVariable;
        Assert.IsTrue(StrPos(Message, ExpectedMessage) > 0, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerWithEnqueue(Message: Text)
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerValidateMessage(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure EditAnalysisReportSaleRequestPageHandler(var SalesAnalysisReport: TestPage "Sales Analysis Report")
    var
        SalesPeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
    begin
        SalesAnalysisReport.PeriodType.SetValue(SalesPeriodType::Year);
        SalesAnalysisReport.ShowMatrix.Invoke();
    end;

    local procedure EnqueueAnalysisColumnHeader(AnalysisColumnTemplateName: Code[10])
    var
        AnalysisColumn: Record "Analysis Column";
    begin
        AnalysisColumn.SetRange("Analysis Area", AnalysisColumn."Analysis Area"::Sales);
        AnalysisColumn.SetRange("Analysis Column Template", AnalysisColumnTemplateName);
        AnalysisColumn.FindFirst();
        LibraryVariableStorage.Enqueue(AnalysisColumn."Column Header");
    end;

    local procedure AutoReserveSalesLine(SalesLine: Record "Sales Line")
    var
        ReservMgt: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
    begin
        ReservMgt.SetReservSource(SalesLine);
        ReservMgt.AutoReserve(FullAutoReservation, '', SalesLine."Shipment Date", SalesLine.Quantity, SalesLine."Quantity (Base)");
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SaleAnalysisMatrixRequestPageHandler(var SalesAnalysisMatrix: TestPage "Sales Analysis Matrix")
    var
        CostAmountExpected: Variant;
    begin
        LibraryVariableStorage.Dequeue(CostAmountExpected);
        SalesAnalysisMatrix.Field1.AssertEquals(CostAmountExpected);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesAnalysisReportSaleRequestPageHandler(var SalesAnalysisReport: TestPage "Sales Analysis Report")
    var
        SalesPeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
        Sourcetypefilter: Option ,Customer,Vendor,Item;
    begin
        SalesAnalysisReport.PeriodType.SetValue(SalesPeriodType::Year);
        SalesAnalysisReport.CurrentSourceTypeFilter.SetValue(Sourcetypefilter::Customer);
        SalesAnalysisReport.CurrentSourceTypeNoFilter.SetValue(CreateCustomer());
        SalesAnalysisReport.ShowMatrix.Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesAnalysisMatrixRequestPageHandler(var SalesAnalysisMatrix: TestPage "Sales Analysis Matrix")
    var
        SalesAnalysisMatrixField1Caption: Variant;
    begin
        LibraryVariableStorage.Dequeue(SalesAnalysisMatrixField1Caption);
        Assert.AreEqual(SalesAnalysisMatrixField1Caption, SalesAnalysisMatrix.Field1.Caption, ColumnCaptionErr);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SaleAnalysisMatrixColumnsRPH(var MatrixForm: TestPage "Sales Analysis Matrix")
    var
        CountVar: Variant;
        FieldVisibilityArray: array[32] of Boolean;
        "Count": Integer;
        Index: Integer;
    begin
        LibraryVariableStorage.Dequeue(CountVar);
        Count := CountVar;

        FieldVisibilityArray[1] := MatrixForm.Field1.Visible();
        FieldVisibilityArray[2] := MatrixForm.Field2.Visible();
        FieldVisibilityArray[3] := MatrixForm.Field3.Visible();
        FieldVisibilityArray[4] := MatrixForm.Field4.Visible();
        FieldVisibilityArray[5] := MatrixForm.Field5.Visible();
        FieldVisibilityArray[6] := MatrixForm.Field6.Visible();
        FieldVisibilityArray[7] := MatrixForm.Field7.Visible();
        FieldVisibilityArray[8] := MatrixForm.Field8.Visible();
        FieldVisibilityArray[9] := MatrixForm.Field9.Visible();
        FieldVisibilityArray[10] := MatrixForm.Field10.Visible();
        FieldVisibilityArray[11] := MatrixForm.Field11.Visible();
        FieldVisibilityArray[12] := MatrixForm.Field12.Visible();
        FieldVisibilityArray[13] := MatrixForm.Field13.Visible();
        FieldVisibilityArray[14] := MatrixForm.Field14.Visible();
        FieldVisibilityArray[15] := MatrixForm.Field15.Visible();
        FieldVisibilityArray[16] := MatrixForm.Field16.Visible();
        FieldVisibilityArray[17] := MatrixForm.Field17.Visible();
        FieldVisibilityArray[18] := MatrixForm.Field18.Visible();
        FieldVisibilityArray[19] := MatrixForm.Field19.Visible();
        FieldVisibilityArray[20] := MatrixForm.Field20.Visible();
        FieldVisibilityArray[21] := MatrixForm.Field21.Visible();
        FieldVisibilityArray[22] := MatrixForm.Field22.Visible();
        FieldVisibilityArray[23] := MatrixForm.Field23.Visible();
        FieldVisibilityArray[24] := MatrixForm.Field24.Visible();
        FieldVisibilityArray[25] := MatrixForm.Field25.Visible();
        FieldVisibilityArray[26] := MatrixForm.Field26.Visible();
        FieldVisibilityArray[27] := MatrixForm.Field27.Visible();
        FieldVisibilityArray[28] := MatrixForm.Field28.Visible();
        FieldVisibilityArray[29] := MatrixForm.Field29.Visible();
        FieldVisibilityArray[30] := MatrixForm.Field30.Visible();
        FieldVisibilityArray[31] := MatrixForm.Field31.Visible();
        FieldVisibilityArray[32] := MatrixForm.Field32.Visible();

        for Index := 1 to Count do
            Assert.AreEqual(true, FieldVisibilityArray[Index], StrSubstNo(ColumnWrongVisibilityErr, Index));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmCopyDocDateOrderHandlerVerify(Question: Text[1024]; var Reply: Boolean)
    var
        ExpectedConfirmText: Text;
    begin
        ExpectedConfirmText := CopyDocDateOrderConfirmMsg;
        Assert.AreEqual(ExpectedConfirmText, Question, WrongConfirmationMsgErr);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYesNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmDueDateBeforeWorkDate(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesModalPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
        ItemTrackingLines.OK().Invoke();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Post Invoice Events", 'OnPrepareLineOnAfterFillInvoicePostingBuffer', '', false, false)]
    local procedure AddGroupOnFillInvPostingBuffer(var InvoicePostingBuffer: Record "Invoice Posting Buffer"; SalesLine: Record "Sales Line")
    begin
        InvoicePostingBuffer."Additional Grouping Identifier" := Format(SalesLine."Line No.");
        InvoicePostingBuffer.BuildPrimaryKey();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerLookupHandler(var CustomerLookup: TestPage "Customer Lookup")
    begin
        CustomerLookup.GotoKey(LibraryVariableStorage.DequeueText());
        CustomerLookup.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ItemChargeAssignmentSalesModalPageHandler(var ItemChargeAssignmentSales: TestPage "Item Charge Assignment (Sales)")
    begin
        Commit();
        ItemChargeAssignmentSales.SuggestItemChargeAssignment.Invoke();
        ItemChargeAssignmentSales.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure SalesCombineShipmentRequestPageHandler(var CombineShipments: TestRequestPage "Combine Shipments")
    begin
        Commit();
        CombineShipments.PostingDate.SetValue(WorkDate());
        CombineShipments.SalesOrderHeader.SetFilter("Sell-to Customer No.", LibraryVariableStorage.DequeueText());
        CombineShipments.OK().Invoke();
    end;
}
