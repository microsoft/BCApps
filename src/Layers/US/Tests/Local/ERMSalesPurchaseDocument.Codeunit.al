codeunit 142053 "ERM Sales/Purchase Document"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryERMTax: Codeunit "Library - ERM Tax";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryResource: Codeunit "Library - Resource";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        EditableErr: Label '%1 should not be editable.';
        PackageTrackingNoErr: Label 'No row found where Field ''PackageTrackingNoText''';
        PackageTrackingNoTextCapTxt: Label 'PackageTrackingNoText';
        SalesLineErr: Label 'There is no Sales Line within the filter.';
        SalesInvoiceLineErr: Label 'There is no Sales Invoice Line within the filter.';
        AmountNotEqualMsg: Label 'Amount must be equal.';
        LibraryWarehouse: Codeunit "Library - Warehouse";
        QuantityNotSufficientErr: Label 'Quantity (Base) is not sufficient to complete this action. The quantity in the bin is 0. %1 units are not available in Bin Content Location Code=''%2'',Bin Code=''%3'',Item No.=''%4'',Variant Code='''',Unit of Measure Code=''BOX''.';
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCommentLineWithCopyCmtsOrderToShptAsTrue()
    var
        SalesCommentLine: Record "Sales Comment Line";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Comment]
        // Verify Sales Comment Line after post Sales Order with CopyCommentOrderToShpt as true on Sales & Receivable Setup.
        // Setup.
        Initialize();
        SalesCommentLineWithSalesDocument(SalesHeader."Document Type"::Order, SalesCommentLine."Document Type"::Shipment, false);  // Post as Ship.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCommentLineWithCopyCmtsOrderToInvAsTrue()
    var
        SalesCommentLine: Record "Sales Comment Line";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Comment]
        // Verify Sales Comment Line after post Sales Order with CopyCommentsOrderToInvoice as true on Sales & Receivable Setup.
        // Setup.
        Initialize();
        SalesCommentLineWithSalesDocument(SalesHeader."Document Type"::Order, SalesCommentLine."Document Type"::"Posted Invoice", true);  // Post as Invoice.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCommentLineWithCopyCmtsRetOrdToRetRcptAsTrue()
    var
        SalesCommentLine: Record "Sales Comment Line";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Comment]
        // Verify Sales Comment Line after post Sales Return Order as Ship with CopyCmtsRetOrdToRetRcpt as true on Sales & Receivable Setup.
        // Setup.
        Initialize();
        SalesCommentLineWithSalesDocument(
          SalesHeader."Document Type"::"Return Order", SalesCommentLine."Document Type"::"Posted Return Receipt", false);  // Post as Ship.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCommentLineWithCopyCmtsRetOrdToCrMemoAsTrue()
    var
        SalesCommentLine: Record "Sales Comment Line";
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Comment]
        // Verify Sales Comment Line after post Sales Return Order as Invoice with CopyCmtsRetOrdToCrMemo as true on Sales & Receivable Setup.
        // Setup.
        Initialize();
        SalesCommentLineWithSalesDocument(
          SalesHeader."Document Type"::"Return Order", SalesCommentLine."Document Type"::"Posted Credit Memo", true);  // Post as Invoice.
    end;

    local procedure SalesCommentLineWithSalesDocument(DocumentType: Enum "Sales Document Type"; SalesCommentLineDocType: Enum "Sales Comment Document Type"; Invoice: Boolean)
    var
        SalesCommentLine: Record "Sales Comment Line";
        DocumentNo: Code[20];
    begin
        // Exercise: Create and Post Sales Return Order with Sales Comment Line.
        DocumentNo := CreateAndPostSalesDocumentWithSalesCommentLine(SalesCommentLine, DocumentType, Invoice);

        // Verify: Verify Sales Comment Line.
        VerifySalesCommentLine(SalesCommentLineDocType, DocumentNo, SalesCommentLine."Line No.", SalesCommentLine.Comment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCommentLineWithCopyCmtsOrderToShptAsFalse()
    var
        SalesCommentLine: Record "Sales Comment Line";
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Comment]
        // Verify Sales Comment Line after post Sales Order with CopyCommentOrderToShpt as false on Sales & Receivable Setup.

        // Setup: Update CopyCommentOrderToShpt field on Sales & Receivable Setup.
        Initialize();
        UpdateSalesReceivablesSetup(SalesReceivablesSetup.FieldNo("Copy Comments Order to Shpt."), false);

        // Exercise: Create and post Sales Order with Sales Comment Line.
        DocumentNo := CreateAndPostSalesDocumentWithSalesCommentLine(SalesCommentLine, SalesHeader."Document Type"::Order, false);  // Post as Ship.

        // Verify: Verify Sales Comment Line does not exist.
        VerifyErrorOnSalesCommentLine(SalesCommentLine."Document Type"::Shipment, DocumentNo, SalesCommentLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCommentLineWithCopyCmtsOrderToInvAsFalse()
    var
        SalesCommentLine: Record "Sales Comment Line";
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Comment]
        // Verify Sales Comment Line after post Sales Order with CopyCommentsOrderToInvoice as false on Sales & Receivable Setup.

        // Setup: Update CopyCommentsOrderToInvoice field on Sales & Receivable Setup.
        Initialize();
        UpdateSalesReceivablesSetup(SalesReceivablesSetup.FieldNo("Copy Comments Order to Invoice"), false);

        // Exercise: Create and post Sales Order with Sales Comment Line.
        DocumentNo := CreateAndPostSalesDocumentWithSalesCommentLine(SalesCommentLine, SalesHeader."Document Type"::Order, true);  // Post as Invoice.

        // Verify: Verify Sales Comment Line does not exist.
        VerifyErrorOnSalesCommentLine(SalesCommentLine."Document Type"::"Posted Invoice", DocumentNo, SalesCommentLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCommentLineWithCopyCmtsBlanketToOrdAsTrue()
    var
        SalesCommentLine: Record "Sales Comment Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Sales] [Comment]
        // Verify Sales Comment Line after Make Order from Blanket Sales Order with CopyCommentsBlanketToOrder as true on Sales & Receivable Setup.

        // Setup: Update CopyCommentsBlanketToOrder field on Sales & Receivable Setup. Create Blanket Sales Order with Sales Comment Line.
        Initialize();
        UpdateWarningsOnSalesReceivablesSetup();
        ItemNo := CreateSalesDocumentWithCommentLine(SalesCommentLine, SalesHeader."Document Type"::"Blanket Order");
        SalesHeader.Get(SalesHeader."Document Type"::"Blanket Order", SalesCommentLine."No.");

        // Exercise: Make Order from Blanket Sales Order.
        LibrarySales.BlanketSalesOrderMakeOrder(SalesHeader);
        FindSalesLine(SalesLine, ItemNo);

        // Verify: Verify Sales Comment Line.
        VerifySalesCommentLine(
          SalesCommentLine."Document Type"::Order, SalesLine."Document No.", SalesLine."Line No.", SalesCommentLine.Comment);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCommentLineWithCopyCmtsBlanketToOrdAsFalse()
    var
        SalesCommentLine: Record "Sales Comment Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ItemNo: Code[20];
    begin
        // [FEATURE] [Sales] [Comment]
        // Verify Sales Comment Line after Make Order from Blanket Sales Order with CopyCommentsBlanketToOrder as false on Sales & Receivable Setup.

        // Setup: Update CopyCommentsBlanketToOrder field on Sales & Receivable Setup. Create Blanket Sales Order with Sales Comment Line.
        Initialize();
        UpdateSalesReceivablesSetup(SalesReceivablesSetup.FieldNo("Copy Comments Blanket to Order"), false);
        ItemNo := CreateSalesDocumentWithCommentLine(SalesCommentLine, SalesHeader."Document Type"::"Blanket Order");
        SalesHeader.Get(SalesHeader."Document Type"::"Blanket Order", SalesCommentLine."No.");

        // Exercise: Make Order from Blanket Sales Order.
        LibrarySales.BlanketSalesOrderMakeOrder(SalesHeader);
        FindSalesLine(SalesLine, ItemNo);

        // Verify: Verify Sales Comment Line does not exist.
        VerifyErrorOnSalesCommentLine(SalesCommentLine."Document Type"::Order, SalesLine."No.", SalesLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCommentLineWithCopyCmtsRetOrdToRetRcptAsFalse()
    var
        SalesCommentLine: Record "Sales Comment Line";
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Comment]
        // Verify Sales Comment Line after post Sales Return Order as Ship with CopyCmtsRetOrdToRetRcpt as false on Sales & Receivable Setup.

        // Setup: Update CopyCmtsRetOrdToRetRcpt field on Sales & Receivable Setup.
        Initialize();
        UpdateSalesReceivablesSetup(SalesReceivablesSetup.FieldNo("Copy Cmts Ret.Ord. to Ret.Rcpt"), false);

        // Exercise: Create and Post Sales return Order with Sales Comment Line.
        DocumentNo := CreateAndPostSalesDocumentWithSalesCommentLine(SalesCommentLine, SalesHeader."Document Type"::"Return Order", false);  // Post as Ship.

        // Verify: Verify Sales Comment Line does not exist.
        VerifyErrorOnSalesCommentLine(SalesCommentLine."Document Type"::"Posted Return Receipt", DocumentNo, SalesCommentLine."Line No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCommentLineWithCopyCmtsRetOrdToCrMemoAsFalse()
    var
        SalesCommentLine: Record "Sales Comment Line";
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Comment]
        // Verify Sales Comment Line after post Sales Return Order as Invoice with CopyCmtsRetOrdToCrMemo as false on Sales & Receivable Setup.

        // Setup: Update CopyCmtsRetOrdToCrMemo field on Sales & Receivable Setup.
        Initialize();
        UpdateSalesReceivablesSetup(SalesReceivablesSetup.FieldNo("Copy Cmts Ret.Ord. to Cr. Memo"), false);

        // Exercise: Create and Post Sales Return Order with Sales Comment Line.
        DocumentNo := CreateAndPostSalesDocumentWithSalesCommentLine(SalesCommentLine, SalesHeader."Document Type"::"Return Order", true);  // Post as Invoice.

        // Verify: Verify Sales Comment Line does not exist.
        VerifyErrorOnSalesCommentLine(SalesCommentLine."Document Type"::"Posted Credit Memo", DocumentNo, SalesCommentLine."Line No.");
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandler')]
    [Scope('OnPrem')]
    procedure SalesStatisticsWithCalcInvDiscountAsTrue()
    var
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesInvoiceList: TestPage "Sales Invoice List";
    begin
        // [FEATURE] [Sales] [Statistics]
        // Verify InvDiscountAmount field is not editable on Sales Statistics with CalcInvDiscount as true on Sales & Receivable Setup.

        // Setup: Update CalcInvDiscount on Sales & Receivable Setup. Create Sales Order.
        Initialize();
        UpdateSalesReceivablesSetup(SalesReceivablesSetup.FieldNo("Calc. Inv. Discount"), false);
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Invoice);

        // Exercise: Open Sales Statistics page from Sales Invoice page.
        SalesInvoiceList.OpenEdit();
        SalesInvoiceList.FILTER.SetFilter("No.", SalesLine."Document No.");
        SalesInvoiceList.Statistics.Invoke();

        // Verify: Verification is done in SalesOrderStatsHandler method.
    end;
#endif
    [Test]
    [HandlerFunctions('SalesOrderStatsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure SalesStatisticsWithCalcInvDiscountAsTrueNM()
    var
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesInvoiceList: TestPage "Sales Invoice List";
    begin
        // [FEATURE] [Sales] [Statistics]
        // Verify InvDiscountAmount field is not editable on Sales Statistics with CalcInvDiscount as true on Sales & Receivable Setup.

        // Setup: Update CalcInvDiscount on Sales & Receivable Setup. Create Sales Order.
        Initialize();
        UpdateSalesReceivablesSetup(SalesReceivablesSetup.FieldNo("Calc. Inv. Discount"), false);
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Invoice);

        // Exercise: Open Sales Statistics page from Sales Invoice page.
        SalesInvoiceList.OpenEdit();
        SalesInvoiceList.FILTER.SetFilter("No.", SalesLine."Document No.");
        SalesInvoiceList.SalesOrderStats.Invoke();

        // Verify: Verification is done in SalesOrderStatsHandler method.
    end;

    [Test]
    [HandlerFunctions('SalesShipmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithPackageTrackingNoAsTrue()
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Package Tracking]
        // Verify Report Sales Shipment with Package Tracking No field on Sales Order as True.

        // Setup: Create and post Sales Order with PackageTrackingNo as True.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order);
        UpdatePackageTrackingNoOnSalesHeader(SalesHeader, SalesLine."Document No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Post as Ship.

        // Exercise: Open Print from Posted Sales Shipments page.
        OpenPrintFromPostedSalesShipments(DocumentNo, true);  // PackageTrackingNo as True.

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(PackageTrackingNoTextCapTxt, SalesHeader."Package Tracking No.");
    end;

    [Test]
    [HandlerFunctions('SalesShipmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithPackageTrackingNoAsFalse()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Package Tracking]
        // Verify Report Sales Shipment with Package Tracking No field on Sales Order as False.

        // Setup: Create and post Sales Order with PackageTrackingNo as False.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order);
        UpdatePackageTrackingNoOnSalesHeader(SalesHeader, SalesLine."Document No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Post as Ship.

        // Exercise: Open Print from Posted Sales Shipments page.
        OpenPrintFromPostedSalesShipments(DocumentNo, false);  // PackageTrackingNo as False.

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        asserterror LibraryReportDataset.AssertElementWithValueExists(PackageTrackingNoTextCapTxt, SalesHeader."Package Tracking No.");
        Assert.ExpectedError(PackageTrackingNoErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesLineWithoutFreightAmtOnSalesOrdShipment()
    var
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Freight Amount]
        // Verify Sales Line without FreightAmount on Sales Order Shipment.

        // Setup: Create Sales Order and G/L Account.
        Initialize();
        CreateSalesOrderUsingGLAccount(SalesLine);

        // Exercise: Open Post from Sales Order Shipment page.
        OpenPostFromSalesOrderShipment(SalesLine."Document No.", 0);  // FreightAmount as 0.

        // Verify: Verify Sales Line with type G/L Account does not exist.
        asserterror FilterSalesLine(SalesLine, SalesLine."Document No.", SalesLine.Type::"G/L Account");
        Assert.ExpectedError(SalesLineErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceLineWithOutFreightAmtOnSalesOrdShipment()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Freight Amount]
        // Verify Sales Invoice Line without FreightAmount on Sales Order Shipment.

        // Setup: Create Sales Order and G/L Account. Open post from Sales Order Shipment page.
        Initialize();
        CreateSalesOrderUsingGLAccount(SalesLine);
        OpenPostFromSalesOrderShipment(SalesLine."Document No.", 0);  // FreightAmount as 0.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise: Post Sales Order as Invoice.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Invoice.

        // Verify: Verify Sales Invoice Line with type G/L Account does not exist.
        asserterror FilterSalesInvoiceLine(SalesInvoiceLine, SalesLine."Document No.");
        Assert.ExpectedError(SalesInvoiceLineErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesLineWithFreightAmtOnSalesOrdShipment()
    var
        SalesLine: Record "Sales Line";
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [Sales] [Freight Amount]
        // Verify Sales Line with FreightAmount is updated on Sales Order Shipment.

        // Setup: Create Sales Order and G/L Account.
        Initialize();
        GLAccountNo := CreateSalesOrderUsingGLAccount(SalesLine);

        // Exercise: Open Post from Sales Order Shipment page.
        OpenPostFromSalesOrderShipment(SalesLine."Document No.", LibraryRandom.RandDec(10, 2));

        // Verify: Verify Sales Line with type G/L Account.
        FilterSalesLine(SalesLine, SalesLine."Document No.", SalesLine.Type::"G/L Account");
        SalesLine.TestField("No.", GLAccountNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceLineWithFreightAmtOnSalesOrdShipment()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [Sales] [Freight Amount]
        // Verify Sales Invoice Line with FreightAmount is updated on Sales Order Shipment.

        // Setup: Create Sales Order and G/L Account. Open post from Sales Order Shipment page.
        Initialize();
        GLAccountNo := CreateSalesOrderUsingGLAccount(SalesLine);
        OpenPostFromSalesOrderShipment(SalesLine."Document No.", LibraryRandom.RandDec(10, 2));
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise: Post Sales Order as Invoice.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Post as Invoice.

        // Verify: Verify Sales Invoice Line with type G/L Account.
        FilterSalesInvoiceLine(SalesInvoiceLine, DocumentNo);
        SalesInvoiceLine.TestField("No.", GLAccountNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceWithoutGenPostingType()
    var
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [Purchase] [Intercompany]
        // Verify G/L Entry and IC Outbox Transaction without General Posting Type and General Product Posting Group in G/L Account.
        Initialize();
        CreatePurchaseInvoiceUsingICPartnerCode(GLAccount."Gen. Posting Type"::" ", '');  // General Product Posting Group as blank.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseInvoiceWithGenPostingType()
    var
        GLAccount: Record "G/L Account";
    begin
        // [FEATURE] [Purchase] [Intercompany]
        // Verify G/L Entry and IC Outbox Transaction with General Posting Type and General Product Posting Group in G/L Account.
        Initialize();
        CreatePurchaseInvoiceUsingICPartnerCode(GLAccount."Gen. Posting Type"::Purchase, FindGenProdPostingGroup());
    end;

    local procedure CreatePurchaseInvoiceUsingICPartnerCode(GenPostingType: Enum "General Posting Type"; GenProdPostingGroup: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        PostedInvoiceNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Intercompany]
        // Setup: Update VAT In Use on GL Setup.

        // Exercise: Create and Post Purchase Invoice with IC Partner.
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        GLAccountNo :=
          CreateGLAccount(VATPostingSetup, GenPostingType, GenProdPostingGroup, '');
        PostedInvoiceNo :=
          CreateAndPostPurchaseInvoiceWithICPartner(
            PurchaseLine, GLAccountNo, CreateVendor('', VATPostingSetup."VAT Bus. Posting Group"), false);

        // Verify: Verify G/L Entry and IC Outbox Transaction.
        VerifyGLEntry(PostedInvoiceNo, GenPostingType, GenProdPostingGroup, PurchaseLine.Amount);
        VerifyICOutboxTransaction(PostedInvoiceNo, PurchaseLine."IC Partner Code");
    end;

    [Test]
    [HandlerFunctions('GetReturnShipmentLinesForPurchasePageHandler')]
    [Scope('OnPrem')]
    procedure PostPurchCrMemoAfterGetShipmentLinesWithPartialQty()
    var
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
        GLEntry: Record "G/L Entry";
        DocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // [FEATURE] [Purchase] [Credit Memo] [Get Shipment Lines]
        // Verify G/L Entry after partial post Purchase Return Order and then post Purchase Credit Memo.

        // Setup: Create and Post Purchase Return Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);  // Take random Quantity.
        CreateAndPostPurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Return Order", false, Quantity, Quantity / 2);  // Post as Ship and partial posting required.

        // Exercise.
        DocumentNo :=
          PostPurchaseCreditMemoAfterGetShipmentLines(PurchaseLine."Tax Area Code", PurchaseLine."Buy-from Vendor No.");

        // Verify: Verify G/L Entry.
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        VerifyAmountOnGLEntry(
          GLEntry."Document Type"::"Credit Memo", DocumentNo, GeneralPostingSetup."Purch. Account", -PurchaseLine.Amount / 2, 0);  // Additional-Currency Amount as 0.
        VerifyAmountOnGLEntry(
          GLEntry."Document Type"::"Credit Memo", DocumentNo,
          FindVendorPostingGroup(PurchaseLine."Buy-from Vendor No."), PurchaseLine."Amount Including VAT" / 2, 0);  // Additional-Currency Amount as 0;
    end;

    [Test]
    [HandlerFunctions('GetReturnShipmentLinesForPurchasePageHandler')]
    [Scope('OnPrem')]
    procedure PostPurchCrMemoAfterGetShipmentLines()
    var
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
        GLEntry: Record "G/L Entry";
        DocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // [FEATURE] [Purchase] [Credit Memo] [Get Shipment Lines]
        // Verify G/L Entry after post Purchase Return Order and then post Purchase Credit Memo.

        // Setup: Create and Post Purchase Return Order. Create and Post Purchase Credit Memo and Get Shipment Lines.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);  // Take random Quantity.
        CreateAndPostPurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Return Order", false, Quantity, Quantity / 2);  // Post as Ship and Partial posting required.
        PostPurchaseCreditMemoAfterGetShipmentLines(PurchaseLine."Tax Area Code", PurchaseLine."Buy-from Vendor No.");

        // Exercise: Post Purchase Credit Memo.
        DocumentNo := PostPurchaseCreditMemo(PurchaseLine."Document No.");

        // Verify: Verify G/L Entry.
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        VerifyAmountOnGLEntry(
          GLEntry."Document Type"::"Credit Memo", DocumentNo, GeneralPostingSetup."Purch. Account", -PurchaseLine.Amount / 2, 0);  // Additional-Currency Amount as 0;
        VerifyAmountOnGLEntry(
          GLEntry."Document Type"::"Credit Memo", DocumentNo,
          FindVendorPostingGroup(PurchaseLine."Buy-from Vendor No."), PurchaseLine."Amount Including VAT" / 2, 0);  // Additional-Currency Amount as 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemLedgerEntryAfterPostPurchaseReturnOrderWithTax()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        Quantity: Decimal;
    begin
        // [FEATURE] [Purchase] [Return Order] [Sales Tax]
        // Verify Item Ledger Entry after post Purchase Return Order with Tax Area.

        // Setup.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);  // Take random Quantity.

        // Exercise: Create and Post Purchase Return Order.
        DocumentNo := CreateAndPostPurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Return Order", false, Quantity, Quantity);  // Post as Ship.

        // Verify: Verify Item Ledger Entry.
        VerifyItemLedgerEntry(ItemLedgerEntry."Entry Type"::Purchase, DocumentNo, -Quantity);
    end;

    [Test]
    [HandlerFunctions('GetReturnShipmentLinesForPurchasePageHandler')]
    [Scope('OnPrem')]
    procedure VATEntryAfterPostPurchCrMemoWithGetShipmentLines()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLEntry: Record "G/L Entry";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        Quantity: Decimal;
        Amount: Decimal;
    begin
        // [FEATURE] [Purchase] [Credit Memo] [Sales Tax]
        // Verify G/L Entry and VAT Entry after post Purchase Credit Memo with Tax Area.

        // Setup: Create and Post Purchase Return Order.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);  // Take random Quantity.
        CreateAndPostPurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Return Order", false, Quantity, Quantity);  // Post as Ship.
        Amount := PurchaseLine.Amount * FindTaxDetail(PurchaseLine."Tax Group Code") / 100;

        // Exercise: Create and Post Purchase Credit Memo and Get Shipment Lines.
        DocumentNo :=
          PostPurchaseCreditMemoAfterGetShipmentLines(PurchaseLine."Tax Area Code", PurchaseLine."Buy-from Vendor No.");

        // Verify: Verify G/L Entry and VAT Entry.
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        VerifyAmountOnGLEntry(
          GLEntry."Document Type"::"Credit Memo", DocumentNo, GeneralPostingSetup."Purch. Account", -PurchaseLine.Amount, 0);  // Additional-Currency Amount as 0;
        VerifyAmountOnGLEntry(
          GLEntry."Document Type"::"Credit Memo", DocumentNo,
          FindVendorPostingGroup(PurchaseLine."Buy-from Vendor No."), PurchaseLine."Amount Including VAT", 0);  // Additional-Currency Amount as 0;
        VerifyVATEntry(DocumentNo, -PurchaseLine.Amount, -Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemLedgerEntryAfterPostSalesReturnOrderWithTax()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Return Order] [Sales Tax] [Inventory]
        // Verify Item Ledger Entry after post Sales Return Order with Tax Area.

        // Setup: Create Sales Return Order.
        Initialize();
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Return Order");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");

        // Exercise: Post Sales Return Order.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Post as Ship.

        // Verify: Verify Item Ledger Entry.
        VerifyItemLedgerEntry(ItemLedgerEntry."Entry Type"::Sale, DocumentNo, SalesLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('GetReturnShipmentLinesForSalesPageHandler')]
    [Scope('OnPrem')]
    procedure VATEntryAfterPostSalesCrMemoWithGetShipmentLines()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLEntry: Record "G/L Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        TaxPerc: Decimal;
        Amount: Decimal;
    begin
        // [FEATURE] [Sales] [Credit Memo] [Sales Tax]
        // Verify G/L Entry and VAT Entry after post Sales Credit Memo with Tax Area.

        // Create and Post Sales Return Order.
        Initialize();
        TaxPerc := CreateSalesDocument(SalesLine, SalesLine."Document Type"::"Return Order");
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, false);  // Post as Ship.
        Amount := SalesLine."Line Amount" * TaxPerc / 100;

        // Exercise: Create Sales Credit Memo and Get Shipment Lines.
        DocumentNo := CreateSalesCreditMemoAndGetShipmentLines(SalesLine."Sell-to Customer No.", SalesLine."Tax Area Code");

        // Verify: Verify G/L Entry.
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        VerifyAmountOnGLEntry(
          GLEntry."Document Type"::"Credit Memo", DocumentNo,
          GeneralPostingSetup."Sales Credit Memo Account", SalesLine."Line Amount", 0);  // Additional-Currency Amount as 0;
        VerifyAmountOnGLEntry(
          GLEntry."Document Type"::"Credit Memo", DocumentNo, FindCustomerPostingGroup(
            SalesLine."Sell-to Customer No."), -(SalesLine."Line Amount" + Amount), 0);  // Additional-Currency Amount as 0;
        VerifyVATEntry(DocumentNo, SalesLine."Line Amount", Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostJnlLineWithAdditionalCurrency()
    var
        GLEntry: Record "G/L Entry";
        TaxDetail: Record "Tax Detail";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        VATEntry: Record "VAT Entry";
        CurrencyCode: Code[10];
        Amount: Decimal;
        GLAccNo: array[2] of Code[20];
        TaxAreaCode: Code[20];
    begin
        // [FEATURE] [General Journal] [FCY] [ACY]
        // [SCENARIO] Journal line in FCY is posted successfuly if ACY is equal to FCY.
        Initialize();
        // [GIVEN] Additional Reporting Currency is 'USD', LCY is 'CAD'
        CurrencyCode := CreateCurrencyWithExchRate();
        ModifyAdditionalReportingCurrencyOnGLSetup(CurrencyCode);
        // [GIVEN] Sales Tax is set for account 'X'
        TaxAreaCode :=
          CreateTaxAreaLine(TaxDetail, TaxDetail."Tax Type"::"Sales Tax Only");
        CreateVatPostingSetup(VATPostingSetup);
        GLAccNo[1] :=
          CreateGLAccount(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale, FindGenProdPostingGroup(), TaxDetail."Tax Group Code");
        GLAccNo[2] := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Creates the journal line, where "Account No." is 'X', "Currency Code" is 'USD', "Bal. Account No." is 'CASH'
        Amount := LibraryRandom.RandDec(100, 2);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", GLAccNo[1], GenJournalLine."Bal. Account Type"::"G/L Account", GLAccNo[2], Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Tax Area Code", TaxAreaCode);
        GenJournalLine.Validate("Tax Liable", true);
        GenJournalLine.Modify(true);

        // [WHEN] Post the journal line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Posted transaction, where are G/L Entries for sales tax and ACY amounts are proportional to LCY amounts
        GLEntry.FindLast();
        GLEntry.SetRange("Transaction No.", GLEntry."Transaction No.");
        GLEntry.FindSet();
        repeat
            Assert.AreNearlyEqual(
              GLEntry."Additional-Currency Amount", CalcACYFromLCY(GLEntry, CurrencyCode), 0.01, 'Wrong Additional-Currency Amount');
        until GLEntry.Next() = 0;
        GLEntry.SetRange("G/L Account No.", GLAccNo[1]);
        GLEntry.FindFirst();
        GLEntry.TestField("Additional-Currency Amount", GenJournalLine."VAT Base Amount");
        GLEntry.SetRange("G/L Account No.", GLAccNo[2]);
        GLEntry.FindFirst();
        GLEntry.TestField("Additional-Currency Amount", -Amount);
        // [THEN] VAT Entry posted, where "VAT Calculation Type" is 'Sales Tax'
        VATEntry.SetRange("Transaction No.", GLEntry."Transaction No.");
        VATEntry.FindFirst();
        VATEntry.TestField("VAT Calculation Type", VATEntry."VAT Calculation Type"::"Sales Tax");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostJnlLineWithAdditionalCurrencyAndExpense()
    var
        GLEntry: Record "G/L Entry";
        TaxDetail: Record "Tax Detail";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        CurrencyCode: Code[10];
        Amount: Decimal;
        GLAccNo: array[2] of Code[20];
        TaxAreaCode: Code[20];
    begin
        // [FEATURE] [General Journal] [FCY] [ACY] [Expense]
        // [SCENARIO] Journal line in FCY is posted successfuly if ACY is equal to FCY and tax details include expenses.
        Initialize();
        // [GIVEN] Additional Reporting Currency is 'USD', LCY is 'CAD'
        CurrencyCode := CreateCurrencyWithExchRate();
        ModifyAdditionalReportingCurrencyOnGLSetup(CurrencyCode);
        // [GIVEN] Sales Tax is set for account 'X', where the second Detail has "Expense\Capitalize"
        TaxAreaCode :=
          CreateTaxAreaLine(TaxDetail, TaxDetail."Tax Type"::"Sales and Use Tax");
        TaxDetail."Tax Type" := TaxDetail."Tax Type"::"Excise Tax";
        TaxDetail."Expense/Capitalize" := true;
        TaxDetail."Tax Below Maximum" := LibraryRandom.RandIntInRange(2, 5);
        TaxDetail.Insert(true);
        CreateVatPostingSetup(VATPostingSetup);
        GLAccNo[1] :=
          CreateGLAccount(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale, FindGenProdPostingGroup(), TaxDetail."Tax Group Code");
        GLAccNo[2] := LibraryERM.CreateGLAccountNo();

        // [GIVEN] Creates the journal line, where "Account No." is 'X', "Currency Code" is 'USD', "Bal. Account No." is 'CASH'
        Amount := LibraryRandom.RandDec(1000, 2);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.FindGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", GLAccNo[1], GenJournalLine."Bal. Account Type"::"G/L Account", GLAccNo[2], Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Tax Area Code", TaxAreaCode);
        GenJournalLine.Validate("Tax Liable", true);
        GenJournalLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        GenJournalLine.Modify(true);

        // [WHEN] Post the journal line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Posted transaction, where are G/L Entries for sales tax and ACY amounts are proportional to LCY amounts
        GLEntry.FindLast();
        GLEntry.SetRange("Transaction No.", GLEntry."Transaction No.");
        GLEntry.FindSet();
        repeat
            Assert.AreNearlyEqual(
              GLEntry."Additional-Currency Amount", CalcACYFromLCY(GLEntry, CurrencyCode), 0.01, 'Wrong Additional-Currency Amount');
        until GLEntry.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesOrderWithAdditionalCurrency()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLEntry: Record "G/L Entry";
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
        CurrencyCode: Code[10];
        TaxPerc: Decimal;
        AdditionalCurrencyAmount: Decimal;
        AdditionalCurrencyAmount2: Decimal;
        AmountIncludingVAT: Decimal;
    begin
        // [FEATURE] [Sales] [Order] [ACY]
        // Verify G/L Entry after post Sales Order with additional Currency.

        // Setup: Create Sales Order.
        Initialize();
        CurrencyCode := CreateCurrencyWithExchRate();
        ModifyAdditionalReportingCurrencyOnGLSetup(CurrencyCode);
        TaxPerc := CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order);
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        AmountIncludingVAT := SalesLine."Line Amount" + (SalesLine."Line Amount" * TaxPerc / 100);
        AdditionalCurrencyAmount := LibraryERM.ConvertCurrency(SalesLine."Line Amount", '', CurrencyCode, WorkDate());
        AdditionalCurrencyAmount2 := LibraryERM.ConvertCurrency(AmountIncludingVAT, '', CurrencyCode, WorkDate());

        // Exercise: Post Sales Order.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify.
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");
        VerifyAmountOnGLEntry(
          GLEntry."Document Type"::Invoice, DocumentNo, GeneralPostingSetup."Sales Credit Memo Account",
          -SalesLine."Line Amount", -AdditionalCurrencyAmount);
        VerifyAmountOnGLEntry(
          GLEntry."Document Type"::Invoice, DocumentNo, FindCustomerPostingGroup(SalesLine."Sell-to Customer No."),
          AmountIncludingVAT, AdditionalCurrencyAmount2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchaseOrderWithAdditionalCurrency()
    var
        GLEntry: Record "G/L Entry";
        GeneralPostingSetup: Record "General Posting Setup";
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
        CurrencyCode: Code[10];
        AdditionalCurrencyAmount: Decimal;
        AdditionalCurrencyAmount2: Decimal;
    begin
        // [FEATURE] [Purchase] [Order] [ACY]
        // Verify G/L Entry after post Purchase Order with additional Currency.

        // Setup:  Create Currency with Exchange Rate.
        Initialize();
        CurrencyCode := CreateCurrencyWithExchRate();
        ModifyAdditionalReportingCurrencyOnGLSetup(CurrencyCode);

        // Exercise: Create and Post Purchase Order.
        DocumentNo :=
          CreateAndPostPurchaseDocument(
            PurchaseLine, PurchaseLine."Document Type"::Order, true, LibraryRandom.RandDec(10, 2), 0);  // Return Qty. to Ship as 0.
        AdditionalCurrencyAmount := LibraryERM.ConvertCurrency(PurchaseLine."Line Amount", '', CurrencyCode, WorkDate());
        AdditionalCurrencyAmount2 := LibraryERM.ConvertCurrency(-PurchaseLine."Amount Including VAT", '', CurrencyCode, WorkDate());

        // Verify.
        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        VerifyAmountOnGLEntry(
          GLEntry."Document Type"::Invoice, DocumentNo, GeneralPostingSetup."Purch. Account",
          PurchaseLine."Line Amount", AdditionalCurrencyAmount);
        VerifyAmountOnGLEntry(
          GLEntry."Document Type"::Invoice, DocumentNo, FindVendorPostingGroup(PurchaseLine."Buy-from Vendor No."),
          -PurchaseLine."Amount Including VAT", AdditionalCurrencyAmount2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceOrderWithAdditionalCurrency()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GLEntry: Record "G/L Entry";
        ServiceLine: Record "Service Line";
        DocumentNo: Code[20];
        CurrencyCode: Code[10];
        AdditionalCurrencyAmount: Decimal;
    begin
        // [FEATURE] [Service] [Order] [ACY]
        // Verify G/L Entry after post Service Order with additional Currency.

        // Setup: Create Currency with Exchange Rate.
        Initialize();
        CurrencyCode := CreateCurrencyWithExchRate();
        ModifyAdditionalReportingCurrencyOnGLSetup(CurrencyCode);

        // Exercise: Create and Post Service Order.
        CreateAndPostServiceOrder(ServiceLine);
        DocumentNo := FindServiceInvoiceHeader(ServiceLine."Document No.");
        AdditionalCurrencyAmount := LibraryERM.ConvertCurrency(ServiceLine."Line Amount", '', CurrencyCode, WorkDate());

        // Verify.
        GeneralPostingSetup.Get(ServiceLine."Gen. Bus. Posting Group", ServiceLine."Gen. Prod. Posting Group");
        VerifyAmountOnGLEntry(
          GLEntry."Document Type"::Invoice, DocumentNo, GeneralPostingSetup."Sales Credit Memo Account",
          -ServiceLine.Amount, -AdditionalCurrencyAmount);
        VerifyAmountOnGLEntry(
          GLEntry."Document Type"::Invoice, DocumentNo, FindCustomerPostingGroup(ServiceLine."Customer No."),
          ServiceLine."Amount Including VAT", AdditionalCurrencyAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPurchaseAmountIncludingVATOnICOutboxJnlLine()
    var
        TaxDetail: Record "Tax Detail";
    begin
        // [FEATURE] [Sales Tax] [Purchase] [Intercompany]
        // Verify Amount Including VAt on IC Outbox Jnl line when a purchase invoice is posted with IC Partner Code.
        CreateICOutboxJnlLineWithTax(TaxDetail."Tax Type"::"Sales Tax Only", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckSaleAmountIncludingVATOnICOutboxJnlLine()
    var
        TaxDetail: Record "Tax Detail";
        GLAccount: Record "G/L Account";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        VATPostingSetup: Record "VAT Posting Setup";
        TaxAreaCode: Code[20];
        DocumentNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [FEATURE] [Sales Tax] [Sales] [Intercompany]
        // Verify Amount Including VAt on IC Outbox Jnl line when a sales invoice is posted with IC Partner Code.

        // Setup: Create Tax Setup and create GL Account with VAT and Gen Posting setup.
        Initialize();
        TaxAreaCode := CreateTaxAreaLine(TaxDetail, TaxDetail."Tax Type"::"Sales Tax Only");
        CreateVatPostingSetup(VATPostingSetup);
        GLAccountNo :=
          CreateGLAccount(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale, FindGenProdPostingGroup(), TaxDetail."Tax Group Code");

        // Exercise: Create and Post Sales Invoice with IC Account,
        DocumentNo :=
          CreateAndPostSalesInvoiceWithICPartner(
            SalesLine, GLAccountNo, CreateCustomer(TaxAreaCode, VATPostingSetup."VAT Bus. Posting Group"));

        // Verify: Verify Amount Including VAT on IC Outbox Jnl. Line.
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        VerifyTaxAmountOnICOutboxJnlLine(SalesLine."IC Partner Code", -SalesInvoiceHeader."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckPurchAmountInclVatOnICOutboxJnlLineWithUseTax()
    var
        TaxDetail: Record "Tax Detail";
    begin
        // [FEATURE] [Sales Tax] [Purchase] [Intercompany] [Use Tax]
        // Verify Amount Including VAt on IC Outbox Jnl line when a purchase invoice is posted with IC Partner Code and Use Tax.
        CreateICOutboxJnlLineWithTax(TaxDetail."Tax Type"::"Sales and Use Tax", true);
    end;

#if not CLEAN27
    [Test]
    [HandlerFunctions('PurchaseInvoiceStatsModalPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyTotalInclTaxOnPurchInvStatistics()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Invoice] [Statistics]
        // Setup: Create Tax detail with Jurisdiction and Post Purchase Invoice.
        Initialize();
        CreatePurchaseDocumentWithTaxAreaCode(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Post Purchase Invoice
        OpenPostedInvoiceStatistics(PostedDocumentNo);

        // Verification has been done in handler PurchaseInvoiceStatsModalPageHandler
    end;

    [Test]
    [HandlerFunctions('PurchaseCreditMemoStatsModalPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyTotalIncTaxOnCreditMemoStatistics()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Credit Memo] [Statistics]
        // Setup: Create Tax detail with Jurisdiction and Post Purchase Credit Memo.
        Initialize();
        CreatePurchaseDocumentWithTaxAreaCode(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Post Purchase Credit Memo
        OpenPostedPurchCreditMemoStatistics(PostedDocumentNo);

        // Verification has been done in handler PurchaseCreditMemoStatsModalPageHandler
    end;
#endif
    [Test]
    [HandlerFunctions('PurchaseInvoiceStatsModalPageHandlerNM')]
    [Scope('OnPrem')]
    procedure VerifyTotalInclTaxOnPurchInvStatisticsNM()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Invoice] [Statistics]
        // Setup: Create Tax detail with Jurisdiction and Post Purchase Invoice.
        Initialize();
        CreatePurchaseDocumentWithTaxAreaCode(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Post Purchase Invoice
        OpenPostedInvoiceStatsNM(PostedDocumentNo);

        // Verification has been done in handler PurchaseInvoiceStatsModalPageHandler
    end;

    [Test]
    [HandlerFunctions('PurchaseCreditMemoStatsModalPageHandlerNM')]
    [Scope('OnPrem')]
    procedure VerifyTotalIncTaxOnCreditMemoStatisticsNM()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Credit Memo] [Statistics]
        // Setup: Create Tax detail with Jurisdiction and Post Purchase Credit Memo.
        Initialize();
        CreatePurchaseDocumentWithTaxAreaCode(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Post Purchase Credit Memo
        OpenPostedPurchCreditMemoStatsNM(PostedDocumentNo);

        // Verification has been done in handler PurchaseCreditMemoStatsModalPageHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelSalesInvoiceWithGLAndBlankedGenGroups()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        CustomerNo: Code[20];
        GLAccountNo: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Cancelled Document] [G/L Account] [Sales]
        // [SCENARIO 218359] Posted sales invoice with G/L Account and blanked Gen Bus.\Prod. Groups can be Cancelled
        Initialize();

        if GeneralPostingSetup.Get('', '') then
            GeneralPostingSetup.Delete();

        // [GIVEN] Customer "Cust" with blank "Gen. Bus. Posting Group"
        CustomerNo := LibrarySales.CreateCustomerNo();
        UpdateCustomerGenBusPostingGroup(CustomerNo, '');

        // [GIVEN] G/L Account "GLAcc" with blank "Gen. Prod. Posting Group"
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        UpdateGLAccGenProdPostingGroup(GLAccountNo, '');

        // [GIVEN] Posted sales invoice for the customer "Cust" and G/L Account "GLAcc"
        DocumentNo := CreateAndPostSalesInvoiceWithGLAccount(CustomerNo, GLAccountNo);

        // [WHEN] Cancel posted sales invoice
        CancelSalesInvoice(SalesCrMemoHeader, DocumentNo);

        // [THEN] The invoice has been cancelled and a new credit memo has been created
        SalesCrMemoHeader.TestField("Sell-to Customer No.", CustomerNo);
        VerifySalesCrMemoGLAccLine(SalesCrMemoHeader."No.", GLAccountNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelPurchInvoiceWithGLAndBlankedGenGroups()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        VendorNo: Code[20];
        GLAccountNo: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Cancelled Document] [G/L Account] [Purchase]
        // [SCENARIO 218359] Posted purchase invoice with G/L Account and blanked Gen Bus.\Prod. Groups can be Cancelled
        Initialize();

        if GeneralPostingSetup.Get('', '') then
            GeneralPostingSetup.Delete();

        // [GIVEN] Vendor "Vend" with blank "Gen. Bus. Posting Group"
        VendorNo := LibraryPurchase.CreateVendorNo();
        UpdateVendorGenBusPostingGroup(VendorNo, '');

        // [GIVEN] G/L Account "GLAcc" with blank "Gen. Prod. Posting Group"
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        UpdateGLAccGenProdPostingGroup(GLAccountNo, '');

        // [GIVEN] Posted purchase invoice for the vendor "Vend" and G/L Account "GLAcc"
        DocumentNo := CreateAndPostPurchInvoiceWithGLAccount(VendorNo, GLAccountNo);

        // [WHEN] Cancel posted purchase invoice
        CancelPurchInvoice(PurchCrMemoHdr, DocumentNo);

        // [THEN] The invoice has been cancelled and a new credit memo has been created
        PurchCrMemoHdr.TestField("Buy-from Vendor No.", VendorNo);
        VerifyPurchCrMemoGLAccLine(PurchCrMemoHdr."No.", GLAccountNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure SalesOrderWithMultipleFreightAmountSalesLines()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        ReleaseSalesDoc: Codeunit "Release Sales Document";
        FreightGLAccountNo: Code[20];
        FreightAmount: array[2] of Integer;
    begin
        // [FEATURE] [Sales] [Freight Amount]
        // [SCENARIO 285744] User posts separate Sales Order Shipments for one Sales order, which results in multiple Freight Amount Sales lines
        Initialize();

        // [GIVEN] Sales order with two Sales Lines "S1" and "S2"
        FreightGLAccountNo := CreateSalesOrderWithTwoSalesLinesUsingGLAccount(SalesLine);

        // [GIVEN] Sales order shipment is posted for "S1" with Freight Amount "F1"
        SalesLine[2].Validate("Qty. to Ship", 0);
        SalesLine[2].Modify(true);
        FreightAmount[1] := LibraryRandom.RandInt(100);
        OpenPostFromSalesOrderShipment(SalesLine[1]."Document No.", FreightAmount[1]);

        // [WHEN] Sales order shipment is posted for "S2" with Freight Amount "F2"
        FreightAmount[2] := LibraryRandom.RandInt(100);
        SalesHeader.Get(SalesLine[1]."Document Type", SalesLine[1]."Document No.");
        ReleaseSalesDoc.Reopen(SalesHeader);
        OpenPostFromSalesOrderShipment(SalesLine[1]."Document No.", FreightAmount[2]);

        // [THEN] Sales order has two Freight Amount Sales lines with Line Amount equal to "F2" and "F1"
        VerifySalesLinesWithFreightAmounts(SalesLine, FreightAmount[1], FreightAmount[2], FreightGLAccountNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure SalesOrderShippingNoMultipleFreightAmountOnPostingError()
    var
        FreightGLAccount: Record "G/L Account";
        ItemJournalLine: Record "Item Journal Line";
        Location: Record Location;
        Bin: array[2] of Record Bin;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Quantity: Integer;
    begin
        // [FEATURE] [Sales] [Freight Amount]
        // [SCENARIO 292273] When error occurs in posting Sales Order Shipping duplicate Freight Amount lines are not generated
        Initialize();

        // [GIVEN] Freight G/L Account No. is set to "F"
        LibraryERM.CreateGLAccount(FreightGLAccount);
        UpdateGLFreightAccountNoOnSalesReceivablesSetup(FreightGLAccount."No.");

        // [GIVEN] Location "L" with two Bins "B1" and "B2"
        CreateLocationWithTwoBins(Location, Bin);

        // [GIVEN] Item "I" and Quantity "Q"
        LibraryInventory.CreateItemWithoutVAT(Item);
        Quantity := LibraryRandom.RandInt(100);

        // [GIVEN] Item posted to "L" Bin "B1"
        CreateAndPostItemJournalLine(ItemJournalLine."Entry Type"::Purchase, Item."No.", Quantity, Location.Code, Bin[1].Code, '', '');

        // [GIVEN] Sales Order with "I" of qty. "Q"
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(), Item."No.", Quantity, Location.Code, 0D);
        SalesHeader.Validate("VAT Bus. Posting Group", '');
        SalesHeader.Modify(true);

        // [GIVEN] Item transferred to "L" Bin "B2"
        CreateAndPostItemJournalLine(
          ItemJournalLine."Entry Type"::Transfer, Item."No.", Quantity, Location.Code, Bin[1].Code, Location.Code, Bin[2].Code);

        // [WHEN] Error occurs twice in posting Sales Order Shipping.
        Commit();
        asserterror OpenPostFromSalesOrderShipment(SalesLine."Document No.", LibraryRandom.RandDec(100, 2));
        Assert.ExpectedErrorCode('TestWrapped:CSide');
        Assert.ExpectedError(StrSubstNo(QuantityNotSufficientErr, Quantity, Location.Code, Bin[1].Code, Item."No."));

        asserterror OpenPostFromSalesOrderShipment(SalesLine."Document No.", LibraryRandom.RandDec(100, 2));
        Assert.ExpectedErrorCode('TestWrapped:CSide');
        Assert.ExpectedError(StrSubstNo(QuantityNotSufficientErr, Quantity, Location.Code, Bin[1].Code, Item."No."));

        // [THEN] There is only one Freight Amount Line.
        VerifyFreightAmountLineCount(SalesLine, FreightGLAccount."No.", 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithDiscountAndZeroVAT()
    var
        GLEntry: Record "G/L Entry";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        Vendor: Record Vendor;
        PostedDocumentNo: Code[20];
        ExpectedAmount: Decimal;
    begin
        // [FEATURE]
        // [SCENARIO 306145] Posting Purchase Invoice with Discounted Purchase Line leads to G/L Entry with discounted Amount.
        Initialize();

        // [GIVEN] VAT Posting setup "X" with "VAT %" = 0 and "VAT Calculation Type" = Sales Tax.
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT %", 0);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Sales Tax");
        VATPostingSetup.Modify(true);

        // [GIVEN] Vendor using "X".
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);

        // [GIVEN] Item using "X".
        Item.Get(LibraryInventory.CreateItemNoWithoutVAT());
        Item.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        Item.Modify(true);

        // [GIVEN] Purchase Invoice for Vendor with Purchase Line for item with "Direct Unit Cost" = 100 and "Line Discount %" = 25.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice,
          Vendor."No.", Item."No.", 1, '', WorkDate());
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(100, 200));
        PurchaseLine.Validate("Line Discount %", LibraryRandom.RandInt(25));
        PurchaseLine.Modify(true);

        // [WHEN] Purchase Invoice is posted.
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] G/L Entry has disounted amount -75.
        GLEntry.SetRange("Document Type", PurchaseHeader."Document Type".AsInteger());
        GLEntry.SetRange("Document No.", PostedDocumentNo);
        GLEntry.SetRange("Gen. Posting Type", GLEntry."Gen. Posting Type"::" ");
        GLEntry.FindFirst();
        Assert.RecordCount(GLEntry, 1);
        ExpectedAmount := -PurchaseLine."Direct Unit Cost" * (100 - PurchaseLine."Line Discount %") / 100;
        Assert.AreEqual(Round(ExpectedAmount), GLEntry.Amount, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchOrderItemChargeWithGLAndBlankGenGroup()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemCharge: Record "Item Charge";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Item Charge]
        // [SCENARIO 309283] Lines of Type Charge (Item) with blank "Gen. Prod. Posting Group" on a Purchase Order can't be posted as Received
        Initialize();

        // [GIVEN] Sales Tax Application Area Enabled
        LibraryApplicationArea.EnableSalesTaxSetup();
        CreateVatPostingSetup(VATPostingSetup);

        // [GIVEN] Item Charge "TESTFREIGHT" with blank Gen. Prod. Posting Group
        CreateItemChargeWithPostingGroups(ItemCharge, '', VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Purchase Order "PO01" with a Purchase Line for the Item Charge "TESTFREIGHT"
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", ItemCharge."No.", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);

        // [WHEN] Post "PO01" with Receive
        asserterror LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Post fails on checking "Gen. Prod. Posting Group" on Item Charge Purchase Line
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedTestFieldError(ItemCharge.FieldCaption("Gen. Prod. Posting Group"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesOrderItemChargeWithGLAndBlankGenGroup()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemCharge: Record "Item Charge";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Item Charge]
        // [SCENARIO 309283] Lines of Type Charge (Item) with blank "Gen. Prod. Posting Group" on a Sales Order can't be posted as Shipped
        Initialize();

        // [GIVEN] Sales Tax Application Area Enabled
        LibraryApplicationArea.EnableSalesTaxSetup();
        CreateVatPostingSetup(VATPostingSetup);

        // [GIVEN] Item Charge "TESTFREIGHT" with blank Gen. Prod. Posting Group
        CreateItemChargeWithPostingGroups(ItemCharge, '', VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Sales Order "SO01" with a Sales Line for the Item Charge "TESTFREIGHT"
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order,
          LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)", ItemCharge."No.", LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);

        // [WHEN] Post "SO01" with Ship
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Post fails on checking "Gen. Prod. Posting Group" on Item Charge Purchase Line
        Assert.ExpectedErrorCode('TestField');
        Assert.ExpectedTestFieldError(ItemCharge.FieldCaption("Gen. Prod. Posting Group"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvoiceLineForICPartnerWithFullSalesTaxSetup()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        ICPartner: Record "IC Partner";
        TaxAreaCode: Code[20];
        GLAccountNo: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Intercompany] [Sales Tax]
        // [SCENARIO 306143] Purchase Invoice with Tax Area Code and Tax Group Code posted for IC Partner expecting IC Partners G/L Entries to contain Purchase Invoice Line Amount without VAT/Sales Tax
        Initialize();

        // [GIVEN] Setup Sales Tax with Jurisdiction, "TaxGroupCode", "TaxAreaCode" and Tax Details
        TaxAreaCode := CreateTaxAreaLine(TaxDetail, TaxDetail."Tax Type"::"Sales and Use Tax");

        // [GIVEN] G/L Account "GLAcc" with "TaxGroupCode"
        VATPostingSetup.Init();
        GLAccountNo := CreateGLAccount(VATPostingSetup, GLAccount."Gen. Posting Type"::" ", '', TaxDetail."Tax Group Code");

        // [GIVEN] Vendor with "TaxAreaCode", Tax Liable = TRUE
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, CreateVendor(TaxAreaCode, ''));

        // [GIVEN] Purchase Invoice for Vendor and "GLAcc" with, Tax Liable, with "TaxAreaCode" and "TaxGroupCode".
        // [GIVEN] Purchase Invoice Line "Amount" = 100
        // [GIVEN] Purchase Invoice Line have "IC Partner Code" and "IC Reference" populated
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, GLAccountNo, false);

        // [WHEN] Purchase Invoice posted
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Purchase Invoice is posted with Amount = -100 for "GLAcc" and with Amount = 100 for IC Partner's G/L Account
        ICPartner.Get(PurchaseLine."IC Partner Code");
        VerifyGLEntryForICPartner(
          DocumentNo, GLAccountNo, ICPartner.Code, GLEntry."Bal. Account Type"::"IC Partner", -PurchaseLine.Amount);
        VerifyGLEntryForICPartner(
          DocumentNo, ICPartner."Payables Account", GLAccountNo, GLEntry."Bal. Account Type"::"G/L Account", PurchaseLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceLineForICPartnerWithFullSalesTaxSetup()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        ICPartner: Record "IC Partner";
        TaxAreaCode: Code[20];
        GLAccountNo: Code[20];
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Intercompany] [Sales Tax]
        // [SCENARIO 306143] Sales Invoice with Tax Area Code and Tax Group Code posted for IC Partner expecting IC Partners G/L Entries to contain Sales Invoice Line Amount without VAT/Sales Tax
        Initialize();

        // [GIVEN] Setup Sales Tax with Jurisdiction, "TaxGroupCode", "TaxAreaCode" and Tax Details
        TaxAreaCode := CreateTaxAreaLine(TaxDetail, TaxDetail."Tax Type"::"Sales and Use Tax");

        // [GIVEN] G/L Account "GLAcc" with "TaxGroupCode"
        VATPostingSetup.Init();
        GLAccountNo := CreateGLAccount(VATPostingSetup, GLAccount."Gen. Posting Type"::" ", '', TaxDetail."Tax Group Code");

        // [GIVEN] Customer with "TaxAreaCode", Tax Liable = TRUE
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer(TaxAreaCode, ''));

        // [GIVEN] Sales Invoice for Customer and "GLAcc" with, Tax Liable, with "TaxAreaCode" and "TaxGroupCode".
        // [GIVEN] Sales Invoice Line "Amount" = 100
        // [GIVEN] Sales Invoice Line have "IC Partner Code" and "IC Reference" populated
        CreateSalesLine(SalesLine, SalesHeader, GLAccountNo);

        // [WHEN] Sales Invoice posted
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] Sales Invoice is posted with Amount = 100 for "GLAcc" and with Amount = -100 for IC Partner's G/L Account
        ICPartner.Get(SalesLine."IC Partner Code");
        VerifyGLEntryForICPartner(
          DocumentNo, GLAccountNo, ICPartner.Code, GLEntry."Bal. Account Type"::"IC Partner", SalesLine.Amount);
        VerifyGLEntryForICPartner(
          DocumentNo, ICPartner."Receivables Account", GLAccountNo, GLEntry."Bal. Account Type"::"G/L Account", -SalesLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPurchInvoiceItemBlankGenBusPostingGroup()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        GeneralPostingSetup: Record "General Posting Setup";
        Item: Record Item;
        Vendor: Record Vendor;
        PurchInvHeader: Record "Purch. Inv. Header";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 322043] Purchase Invoice with blank "Gen. Bus. Posting Group" on Purchase Lines can be posted
        Initialize();

        // [GIVEN] Sales Tax Application Area Enabled
        LibraryApplicationArea.EnableSalesTaxSetup();

        // [GIVEN] Gen. Posting Setup "BLANK","RETAIL"
        CreateGenPostingSetupWithBlankGenBusPostingGroup(GeneralPostingSetup);

        // [GIVEN] Item with Gen. Prod Posting Group "RETAIL"
        LibraryInventory.CreateItem(Item);
        Item.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        Item.Modify(true);

        // [GIVEN] Vendor with blank Gen. Business Posting Group
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", '');
        Vendor.Modify(true);

        // [GIVEN] Purchase Invoice "PI01" with a Purchase Line for the Item
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Invoice,
          Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);

        // [WHEN] Post "PI01" with Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [THEN] Invoice is posted without errors
        PurchInvHeader.Get(DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceItemBlankGenBusPostingGroup()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GeneralPostingSetup: Record "General Posting Setup";
        Item: Record Item;
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 322043] Sales Invoice with blank "Gen. Bus. Posting Group" on Sales Lines can be posted
        Initialize();

        // [GIVEN] Sales Tax Application Area Enabled
        LibraryApplicationArea.EnableSalesTaxSetup();

        // [GIVEN] Gen. Posting Setup "BLANK","RETAIL"
        CreateGenPostingSetupWithBlankGenBusPostingGroup(GeneralPostingSetup);

        // [GIVEN] Item with Gen. Prod Posting Group "RETAIL"
        LibraryInventory.CreateItem(Item);
        Item.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        Item.Modify(true);

        // [GIVEN] Customer with blank Gen. Business Posting Group
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", '');
        Customer.Modify(true);

        // [GIVEN] Sales Invoice "SI01" with a Sales Line for the Item
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice,
          Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);

        // [WHEN] Post "SI01" with Invoice
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [THEN] Invoice is posted without errors
        SalesInvoiceHeader.Get(DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderTaxAreaChangesSalesLinesTaxArea()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxArea: array[2] of Record "Tax Area";
        SalesOrder: TestPage "Sales Order";
        TaxGroupCode: Code[20];
        TaxAreaCode: Code[20];
    begin
        // [FEATURE] [Sales] [UI]
        // [SCENARIO 322892] Changing Tax Area after changing Quantity on Sales Order page changes Tax area on Sales Lines subpage.
        Initialize();

        // [GIVEN] Two Tax Areas "TA1"/"TA2" with one Tax Group.
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        CreateTaxArea(TaxArea[1], TaxGroupCode);
        CreateTaxArea(TaxArea[2], TaxGroupCode);

        // [GIVEN] Customer with Tax Area set to "TA1".
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Tax Area Code", TaxArea[1].Code);
        Customer.Modify(true);

        // [GIVEN] Sales Header with Sales Line with Tax Group.
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Customer."No.", '', 0, '', 0D);

        // [GIVEN] Sales Order page is opened, Tax Area set to "TA1", Quantity is set to 10.
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrder.SalesLines.Quantity.SetValue(LibraryRandom.RandInt(10));

        // [WHEN] Tax Area code on a page changed to "TA2"
        SalesOrder."Tax Area Code".SetValue(TaxArea[2].Code);
        Evaluate(TaxAreaCode, SalesOrder.SalesLines."Tax Area Code".Value);

        // [THEN] Tax Area on subpage is equal to "TA2".
        Assert.AreEqual(TaxArea[2].Code, TaxAreaCode, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteTaxAreaChangesSalesLinesTaxArea()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxArea: array[2] of Record "Tax Area";
        SalesQuote: TestPage "Sales Quote";
        TaxGroupCode: Code[20];
        TaxAreaCode: Code[20];
    begin
        // [FEATURE] [Sales] [UI]
        // [SCENARIO 322892] Changing Tax Area after changing Quantity on Sales Quote page changes Tax area on Sales Lines subpage.
        Initialize();

        // [GIVEN] Two Tax Areas "TA1"/"TA2" with one Tax Group.
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        CreateTaxArea(TaxArea[1], TaxGroupCode);
        CreateTaxArea(TaxArea[2], TaxGroupCode);

        // [GIVEN] Customer with Tax Area set to "TA1".
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Tax Area Code", TaxArea[1].Code);
        Customer.Modify(true);

        // [GIVEN] Sales Header with Sales Line with Tax Group.
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote, Customer."No.", '', 0, '', 0D);

        // [GIVEN] Sales Quote page is opened, Tax Area set to "TA1", Quantity is set to 10.
        SalesQuote.OpenEdit();
        SalesQuote.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesQuote.SalesLines.Quantity.SetValue(LibraryRandom.RandInt(10));

        // [WHEN] Tax Area code on a page changed to "TA2"
        SalesQuote."Tax Area Code".SetValue(TaxArea[2].Code);
        Evaluate(TaxAreaCode, SalesQuote.SalesLines."Tax Area Code".Value);

        // [THEN] Tax Area on subpage is equal to "TA2".
        Assert.AreEqual(TaxArea[2].Code, TaxAreaCode, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceTaxAreaChangesSalesLinesTaxArea()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxArea: array[2] of Record "Tax Area";
        SalesInvoice: TestPage "Sales Invoice";
        TaxGroupCode: Code[20];
        TaxAreaCode: Code[20];
    begin
        // [FEATURE] [Sales] [UI]
        // [SCENARIO 322892] Changing Tax Area after changing Quantity on Sales Invoice page changes Tax area on Sales Lines subpage.
        Initialize();

        // [GIVEN] Two Tax Areas "TA1"/"TA2" with one Tax Group.
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        CreateTaxArea(TaxArea[1], TaxGroupCode);
        CreateTaxArea(TaxArea[2], TaxGroupCode);

        // [GIVEN] Customer with Tax Area set to "TA1".
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Tax Area Code", TaxArea[1].Code);
        Customer.Modify(true);

        // [GIVEN] Sales Header with Sales Line with Tax Group.
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, Customer."No.", '', 0, '', 0D);

        // [GIVEN] Sales Invoice page is opened, Tax Area set to "TA1", Quantity is set to 10.
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesInvoice.SalesLines.Quantity.SetValue(LibraryRandom.RandInt(10));

        // [WHEN] Tax Area code on a page changed to "TA2"
        SalesInvoice."Tax Area Code".SetValue(TaxArea[2].Code);
        Evaluate(TaxAreaCode, SalesInvoice.SalesLines."Tax Area Code".Value);

        // [THEN] Tax Area on subpage is equal to "TA2".
        Assert.AreEqual(TaxArea[2].Code, TaxAreaCode, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoTaxAreaChangesSalesLinesTaxArea()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxArea: array[2] of Record "Tax Area";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        TaxGroupCode: Code[20];
        TaxAreaCode: Code[20];
    begin
        // [FEATURE] [Sales] [UI]
        // [SCENARIO 322892] Changing Tax Area after changing Quantity on Sales Credit Memo page changes Tax area on Sales Lines subpage.
        Initialize();

        // [GIVEN] Two Tax Areas "TA1"/"TA2" with one Tax Group.
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        CreateTaxArea(TaxArea[1], TaxGroupCode);
        CreateTaxArea(TaxArea[2], TaxGroupCode);

        // [GIVEN] Customer with Tax Area set to "TA1".
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Tax Area Code", TaxArea[1].Code);
        Customer.Modify(true);

        // [GIVEN] Sales Header with Sales Line with Tax Group.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", Customer."No.", '', 0, '', 0D);

        // [GIVEN] Sales Credit Memo page is opened, Tax Area set to "TA1", Quantity is set to 10.
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesCreditMemo.SalesLines.Quantity.SetValue(LibraryRandom.RandInt(10));

        // [WHEN] Tax Area code on a page changed to "TA2"
        SalesCreditMemo."Tax Area Code".SetValue(TaxArea[2].Code);
        Evaluate(TaxAreaCode, SalesCreditMemo.SalesLines."Tax Area Code".Value);

        // [THEN] Tax Area on subpage is equal to "TA2".
        Assert.AreEqual(TaxArea[2].Code, TaxAreaCode, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesBlanketOrderTaxAreaChangesSalesLinesTaxArea()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxArea: array[2] of Record "Tax Area";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        TaxGroupCode: Code[20];
        TaxAreaCode: Code[20];
    begin
        // [FEATURE] [Sales] [UI]
        // [SCENARIO 322892] Changing Tax Area after changing Quantity on Sales Blanket Order page changes Tax area on Sales Lines subpage.
        Initialize();

        // [GIVEN] Two Tax Areas "TA1"/"TA2" with one Tax Group.
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        CreateTaxArea(TaxArea[1], TaxGroupCode);
        CreateTaxArea(TaxArea[2], TaxGroupCode);

        // [GIVEN] Customer with Tax Area set to "TA1".
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Tax Area Code", TaxArea[1].Code);
        Customer.Modify(true);

        // [GIVEN] Sales Header with Sales Line with Tax Group.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Blanket Order", Customer."No.", '', 0, '', 0D);

        // [GIVEN] Sales Blanket Order page is opened, Tax Area set to "TA1", Quantity is set to 10.
        BlanketSalesOrder.OpenEdit();
        BlanketSalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        BlanketSalesOrder.SalesLines.Quantity.SetValue(LibraryRandom.RandInt(10));

        // [WHEN] Tax Area code on a page changed to "TA2"
        BlanketSalesOrder."Tax Area Code".SetValue(TaxArea[2].Code);
        Evaluate(TaxAreaCode, BlanketSalesOrder.SalesLines."Tax Area Code".Value);

        // [THEN] Tax Area on subpage is equal to "TA2".
        Assert.AreEqual(TaxArea[2].Code, TaxAreaCode, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOrderTaxAreaChangesSalesLinesTaxArea()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxArea: array[2] of Record "Tax Area";
        SalesReturnOrder: TestPage "Sales Return Order";
        TaxGroupCode: Code[20];
        TaxAreaCode: Code[20];
    begin
        // [FEATURE] [Sales] [UI]
        // [SCENARIO 322892] Changing Tax Area after changing Quantity on Sales Return Order page changes Tax area on Sales Lines subpage.
        Initialize();

        // [GIVEN] Two Tax Areas "TA1"/"TA2" with one Tax Group.
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        CreateTaxArea(TaxArea[1], TaxGroupCode);
        CreateTaxArea(TaxArea[2], TaxGroupCode);

        // [GIVEN] Customer with Tax Area set to "TA1".
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Tax Area Code", TaxArea[1].Code);
        Customer.Modify(true);

        // [GIVEN] Sales Header with Sales Line with Tax Group.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", Customer."No.", '', 0, '', 0D);

        // [GIVEN] Sales Return Order page is opened, Tax Area set to "TA1", Quantity is set to 10.
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesReturnOrder.SalesLines.Quantity.SetValue(LibraryRandom.RandInt(10));

        // [WHEN] Tax Area code on a page changed to "TA2"
        SalesReturnOrder."Tax Area Code".SetValue(TaxArea[2].Code);
        Evaluate(TaxAreaCode, SalesReturnOrder.SalesLines."Tax Area Code".Value);

        // [THEN] Tax Area on subpage is equal to "TA2".
        Assert.AreEqual(TaxArea[2].Code, TaxAreaCode, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PurchaseQuoteTaxAreaChangesPurchaseLinesTaxArea()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TaxArea: array[2] of Record "Tax Area";
        PurchaseQuote: TestPage "Purchase Quote";
        TaxGroupCode: Code[20];
        TaxAreaCode: Code[20];
    begin
        // [FEATURE] [Purchase] [UI]
        // [SCENARIO 322892] Changing Tax Area after changing Quantity on Purchase Quoute page changes Tax area on Purchase Lines subpage.
        Initialize();

        // [GIVEN] Two Tax Areas "TA1"/"TA2" with one Tax Group.
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        CreateTaxArea(TaxArea[1], TaxGroupCode);
        CreateTaxArea(TaxArea[2], TaxGroupCode);

        // [GIVEN] Vendor with Tax Area set to "TA1".
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Tax Area Code", TaxArea[1].Code);
        Vendor.Modify(true);

        // [GIVEN] Purchase Header with Purchase Line with Tax Group.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Quote, Vendor."No.", '', 0, '', 0D);

        // [GIVEN] Purchase Quoute page is opened, Tax Area set to "TA1", Quantity is set to 10.
        PurchaseQuote.OpenEdit();
        PurchaseQuote.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseQuote.PurchLines.Quantity.SetValue(LibraryRandom.RandInt(10));

        // [WHEN] Tax Area code on a page changed to "TA2"
        PurchaseQuote."Tax Area Code".SetValue(TaxArea[2].Code);
        Evaluate(TaxAreaCode, PurchaseQuote.PurchLines."Tax Area Code".Value);

        // [THEN] Tax Area on subpage is equal to "TA2".
        Assert.AreEqual(TaxArea[2].Code, TaxAreaCode, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PurchaseOrderTaxAreaChangesPurchaseLinesTaxArea()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TaxArea: array[2] of Record "Tax Area";
        PurchaseOrder: TestPage "Purchase Order";
        TaxGroupCode: Code[20];
        TaxAreaCode: Code[20];
    begin
        // [FEATURE] [Purchase] [UI]
        // [SCENARIO 322892] Changing Tax Area after changing Quantity on Purchase Order page changes Tax area on Purchase Lines subpage.
        Initialize();

        // [GIVEN] Two Tax Areas "TA1"/"TA2" with one Tax Group.
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        CreateTaxArea(TaxArea[1], TaxGroupCode);
        CreateTaxArea(TaxArea[2], TaxGroupCode);

        // [GIVEN] Vendor with Tax Area set to "TA1".
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Tax Area Code", TaxArea[1].Code);
        Vendor.Modify(true);

        // [GIVEN] Purchase Header with Purchase Line with Tax Group.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order, Vendor."No.", '', 0, '', 0D);

        // [GIVEN] Purchase Order page is opened, Tax Area set to "TA1", Quantity is set to 10.
        PurchaseOrder.OpenEdit();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseOrder.PurchLines.Quantity.SetValue(LibraryRandom.RandInt(10));

        // [WHEN] Tax Area code on a page changed to "TA2"
        PurchaseOrder."Tax Area Code".SetValue(TaxArea[2].Code);
        Evaluate(TaxAreaCode, PurchaseOrder.PurchLines."Tax Area Code".Value);

        // [THEN] Tax Area on subpage is equal to "TA2".
        Assert.AreEqual(TaxArea[2].Code, TaxAreaCode, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceTaxAreaChangesPurchaseLinesTaxArea()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TaxArea: array[2] of Record "Tax Area";
        PurchaseInvoice: TestPage "Purchase Invoice";
        TaxGroupCode: Code[20];
        TaxAreaCode: Code[20];
    begin
        // [FEATURE] [Purchase] [UI]
        // [SCENARIO 322892] Changing Tax Area after changing Quantity on Purchase Invoice page changes Tax area on Purchase Lines subpage.
        Initialize();

        // [GIVEN] Two Tax Areas "TA1"/"TA2" with one Tax Group.
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        CreateTaxArea(TaxArea[1], TaxGroupCode);
        CreateTaxArea(TaxArea[2], TaxGroupCode);

        // [GIVEN] Vendor with Tax Area set to "TA1".
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Tax Area Code", TaxArea[1].Code);
        Vendor.Modify(true);

        // [GIVEN] Purchase Header with Purchase Line with Tax Group.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, Vendor."No.", '', 0, '', 0D);

        // [GIVEN] Purchase Invoice page is opened, Tax Area set to "TA1", Quantity is set to 10.
        PurchaseInvoice.OpenEdit();
        PurchaseInvoice.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseInvoice.PurchLines.Quantity.SetValue(LibraryRandom.RandInt(10));

        // [WHEN] Tax Area code on a page changed to "TA2"
        PurchaseInvoice."Tax Area Code".SetValue(TaxArea[2].Code);
        Evaluate(TaxAreaCode, PurchaseInvoice.PurchLines."Tax Area Code".Value);

        // [THEN] Tax Area on subpage is equal to "TA2".
        Assert.AreEqual(TaxArea[2].Code, TaxAreaCode, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoTaxAreaChangesPurchaseLinesTaxArea()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TaxArea: array[2] of Record "Tax Area";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
        TaxGroupCode: Code[20];
        TaxAreaCode: Code[20];
    begin
        // [FEATURE] [Purchase] [UI]
        // [SCENARIO 322892] Changing Tax Area after changing Quantity on Purchase Credit Memo page changes Tax area on Purchase Lines subpage.
        Initialize();

        // [GIVEN] Two Tax Areas "TA1"/"TA2" with one Tax Group.
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        CreateTaxArea(TaxArea[1], TaxGroupCode);
        CreateTaxArea(TaxArea[2], TaxGroupCode);

        // [GIVEN] Vendor with Tax Area set to "TA1".
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Tax Area Code", TaxArea[1].Code);
        Vendor.Modify(true);

        // [GIVEN] Purchase Header with Purchase Line with Tax Group.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo", Vendor."No.", '', 0, '', 0D);

        // [GIVEN] Purchase Credit Memo page is opened, Tax Area set to "TA1", Quantity is set to 10.
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseCreditMemo.PurchLines.Quantity.SetValue(LibraryRandom.RandInt(10));

        // [WHEN] Tax Area code on a page changed to "TA2"
        PurchaseCreditMemo."Tax Area Code".SetValue(TaxArea[2].Code);
        Evaluate(TaxAreaCode, PurchaseCreditMemo.PurchLines."Tax Area Code".Value);

        // [THEN] Tax Area on subpage is equal to "TA2".
        Assert.AreEqual(TaxArea[2].Code, TaxAreaCode, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PurchaseBlanketOrderTaxAreaChangesPurchaseLinesTaxArea()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TaxArea: array[2] of Record "Tax Area";
        BlanketPurchaseOrder: TestPage "Blanket Purchase Order";
        TaxGroupCode: Code[20];
        TaxAreaCode: Code[20];
    begin
        // [FEATURE] [Purchase] [UI]
        // [SCENARIO 322892] Changing Tax Area after changing Quantity on Purchase Blanket Order page changes Tax area on Purchase Lines subpage.
        Initialize();

        // [GIVEN] Two Tax Areas "TA1"/"TA2" with one Tax Group.
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        CreateTaxArea(TaxArea[1], TaxGroupCode);
        CreateTaxArea(TaxArea[2], TaxGroupCode);

        // [GIVEN] Vendor with Tax Area set to "TA1".
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Tax Area Code", TaxArea[1].Code);
        Vendor.Modify(true);

        // [GIVEN] Purchase Header with Purchase Line with Tax Group.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Blanket Order", Vendor."No.", '', 0, '', 0D);

        // [GIVEN] Purchase Blanket Order page is opened, Tax Area set to "TA1", Quantity is set to 10.
        BlanketPurchaseOrder.OpenEdit();
        BlanketPurchaseOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
        BlanketPurchaseOrder.PurchLines.Quantity.SetValue(LibraryRandom.RandInt(10));

        // [WHEN] Tax Area code on a page changed to "TA2"
        BlanketPurchaseOrder."Tax Area Code".SetValue(TaxArea[2].Code);
        Evaluate(TaxAreaCode, BlanketPurchaseOrder.PurchLines."Tax Area Code".Value);

        // [THEN] Tax Area on subpage is equal to "TA2".
        Assert.AreEqual(TaxArea[2].Code, TaxAreaCode, '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PurchaseReturnOrderTaxAreaChangesPurchaseLinesTaxArea()
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TaxArea: array[2] of Record "Tax Area";
        PurchaseReturnOrder: TestPage "Purchase Return Order";
        TaxGroupCode: Code[20];
        TaxAreaCode: Code[20];
    begin
        // [FEATURE] [Purchase] [UI]
        // [SCENARIO 322892] Changing Tax Area after changing Quantity on Purchase Return Order page changes Tax area on Purchase Lines subpage.
        Initialize();

        // [GIVEN] Two Tax Areas "TA1"/"TA2" with one Tax Group.
        TaxGroupCode := LibraryERMTax.CreateTaxGroupCode();
        CreateTaxArea(TaxArea[1], TaxGroupCode);
        CreateTaxArea(TaxArea[2], TaxGroupCode);

        // [GIVEN] Vendor with Tax Area set to "TA1".
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Tax Area Code", TaxArea[1].Code);
        Vendor.Modify(true);

        // [GIVEN] Purchase Header with Purchase Line with Tax Group.
        LibraryPurchase.CreatePurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order", Vendor."No.", '', 0, '', 0D);

        // [GIVEN] Purchase Return Order page is opened, Tax Area set to "TA1", Quantity is set to 10.
        PurchaseReturnOrder.OpenEdit();
        PurchaseReturnOrder.FILTER.SetFilter("No.", PurchaseHeader."No.");
        PurchaseReturnOrder.PurchLines.Quantity.SetValue(LibraryRandom.RandInt(10));

        // [WHEN] Tax Area code on a page changed to "TA2"
        PurchaseReturnOrder."Tax Area Code".SetValue(TaxArea[2].Code);
        Evaluate(TaxAreaCode, PurchaseReturnOrder.PurchLines."Tax Area Code".Value);

        // [THEN] Tax Area on subpage is equal to "TA2".
        Assert.AreEqual(TaxArea[2].Code, TaxAreaCode, '');
    end;

    [Test]
    [HandlerFunctions('SalesOrderConfirmationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckAmountSubjectToSalesTaxOnStandardSalesOrderConf()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        AmountSubjectToSalesTax: Decimal;
    begin
        // [FEATURE] [Sales] [Report]
        // [SCENARIO 329239] When report "Standard Sales - Order Conf." is printed, Amount Subject To Sales Tax is calculated and shown.
        Initialize();

        // [GIVEN] Sales Order with Sales line with Item with Unit Price = 100, Quanity = 3 and Sales Tax 5%.
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order);
        AmountSubjectToSalesTax := SalesLine.Quantity * SalesLine."Unit Price";

        // [WHEN] Report "Standard Sales - Order Conf." is run.
        Commit();
        LibraryVariableStorage.Enqueue(SalesLine."Document No.");
        REPORT.Run(REPORT::"Standard Sales - Order Conf.", true, true, SalesHeader);

        // [THEN] In dataset AmountSubjectToSalesTax = 100 * 3 = 300.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('AmountSubjectToSalesTax', Round(AmountSubjectToSalesTax));
    end;

    [Test]
    [HandlerFunctions('SalesOrderConfirmationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckAmountExemptFromSalesTaxOnStandardSalesOrderConf()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TaxDetail: Record "Tax Detail";
        AmountExemptFromSalesTax: Decimal;
    begin
        // [FEATURE] [Sales] [Report]
        // [SCENARIO 329239] When report "Standard Sales - Order Conf." is printed, Amount Exempt From Sales Tax is calculated and shown.
        Initialize();

        // [GIVEN] Sales Order with Sales line with Item with Unit Price = 100, Quanity = 3 and Sales Tax 0%.
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order);
        AmountExemptFromSalesTax := SalesLine.Quantity * SalesLine."Unit Price";
        TaxDetail.SetRange("Tax Group Code", SalesLine."Tax Group Code");
        TaxDetail.FindFirst();
        TaxDetail.Validate("Tax Below Maximum", 0);
        TaxDetail.Modify(true);

        // [WHEN] Report "Standard Sales - Order Conf." is run.
        Commit();
        LibraryVariableStorage.Enqueue(SalesLine."Document No.");
        REPORT.Run(REPORT::"Standard Sales - Order Conf.", true, true, SalesHeader);

        // [THEN] In dataset AmountExemptFromSalesTax = 100 * 3 = 200.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('AmountExemptFromSalesTax', Round(AmountExemptFromSalesTax));
    end;

    [Test]
    [HandlerFunctions('SalesOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderReportKeepsSortingByLineNo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Order] [Report]
        // [SCENARIO 331886] NA-localized "Sales Order" report prints lines sorted as in the document.
        Initialize();

        CreateSalesDocumentWithTwoSalesLines(SalesLine[1], SalesLine[2], SalesLine[1]."Document Type"::Order);
        SalesLine[1].Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine[1].Modify(true);
        SalesLine[2].Validate("Unit Price", LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine[2].Modify(true);
        SalesHeader.Get(SalesLine[1]."Document Type", SalesLine[1]."Document No.");
        SalesHeader.SetRecFilter();

        Commit();
        REPORT.Run(REPORT::"Sales Order", true, true, SalesHeader);

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('TempSalesLineNo', SalesLine[1]."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('TempSalesLineNo', SalesLine[2]."No.");
    end;

    [Test]
    [HandlerFunctions('SalesReturnOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnOrderReportKeepsSortingByLineNo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Return Order] [Report]
        // [SCENARIO 331886] NA-localized "Return Authorization" report prints lines sorted as in the document.
        Initialize();

        CreateSalesDocumentWithTwoSalesLines(SalesLine[1], SalesLine[2], SalesLine[1]."Document Type"::"Return Order");
        SalesLine[1].Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine[1].Modify(true);
        SalesLine[2].Validate("Unit Price", LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine[2].Modify(true);
        SalesHeader.Get(SalesLine[1]."Document Type", SalesLine[1]."Document No.");
        SalesHeader.SetRecFilter();

        Commit();
        REPORT.Run(REPORT::"Return Authorization", true, true, SalesHeader);

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('TempSalesLine__No__', SalesLine[1]."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('TempSalesLine__No__', SalesLine[2]."No.");
    end;

    [Test]
    [HandlerFunctions('SalesBlanketOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesBlanketOrderReportKeepsSortingByLineNo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Blanket Order] [Report]
        // [SCENARIO 331886] NA-localized "Sales Blanket Order" report prints lines sorted as in the document.
        Initialize();

        CreateSalesDocumentWithTwoSalesLines(SalesLine[1], SalesLine[2], SalesLine[1]."Document Type"::"Blanket Order");
        SalesLine[1].Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine[1].Modify(true);
        SalesLine[2].Validate("Unit Price", LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine[2].Modify(true);
        SalesHeader.Get(SalesLine[1]."Document Type", SalesLine[1]."Document No.");
        SalesHeader.SetRecFilter();

        Commit();
        REPORT.Run(REPORT::"Sales Blanket Order", true, true, SalesHeader);

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('TempSalesLineNo', SalesLine[1]."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('TempSalesLineNo', SalesLine[2]."No.");
    end;

    [Test]
    [HandlerFunctions('SalesQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesQuoteReportKeepsSortingByLineNo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Quote] [Report]
        // [SCENARIO 331886] NA-localized "Sales Quote" report prints lines sorted as in the document.
        Initialize();

        CreateSalesDocumentWithTwoSalesLines(SalesLine[1], SalesLine[2], SalesLine[1]."Document Type"::Quote);
        SalesLine[1].Validate("Unit Price", LibraryRandom.RandDecInRange(100, 200, 2));
        SalesLine[1].Modify(true);
        SalesLine[2].Validate("Unit Price", LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine[2].Modify(true);
        SalesHeader.Get(SalesLine[1]."Document Type", SalesLine[1]."Document No.");
        SalesHeader.SetRecFilter();

        Commit();
        REPORT.Run(REPORT::"Sales Quote NA", true, true, SalesHeader);

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('TempSalesLineNo', SalesLine[1]."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('TempSalesLineNo', SalesLine[2]."No.");
    end;

    [Test]
    procedure RestrictSalesOrderPostingWhenOnHoldIsSet()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Order] [UT]
        // [SCENARIO 395885] System restricts posting of the Sales Order when Stan has specified a value in "On Hold" field of the sales header

        Initialize();

        LibrarySales.CreateSalesOrder(SalesHeader);

        SalesHeader.Validate("On Hold", 'X');
        SalesHeader.Modify(true);

        Commit();

        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, false);
        Assert.ExpectedTestFieldError(SalesHeader.FieldCaption("On Hold"), '''');

        // Have to reset the Posting No. as that does not get rolled back
        SalesHeader."Shipping No." := '';
        SalesHeader."Posting No." := '';

        SalesHeader.Validate("On Hold", '');
        SalesHeader.Modify(true);

        Commit();

        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);

        SalesLine.TestField("Quantity Shipped", SalesLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelSalesCrMemoCancelledSalesInvoiceWithGLAndBlankedGenGroups()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CancelPostedSalesCrMemo: Codeunit "Cancel Posted Sales Cr. Memo";
        CustomerNo: Code[20];
        GLAccountNo: Code[20];
        DocumentNo: Code[20];
    begin
        // [SCENARIO 431382] Cancel posted sales credit memo that canceled posted sales invoice with G/L account with blank gen. posting groups
        Initialize();
        if GeneralPostingSetup.Get('', '') then
            GeneralPostingSetup.Delete();

        // [GIVEN] Cancelled by sales credit memo "PSCM" posted sales invoice with g/l account with blank gen. posting groups
        CustomerNo := LibrarySales.CreateCustomerNo();
        UpdateCustomerGenBusPostingGroup(CustomerNo, '');
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        UpdateGLAccGenProdPostingGroup(GLAccountNo, '');
        DocumentNo := CreateAndPostSalesInvoiceWithGLAccount(CustomerNo, GLAccountNo);
        CancelSalesInvoice(SalesCrMemoHeader, DocumentNo);

        // [WHEN] Cancel "PSCM"
        CancelPostedSalesCrMemo.CancelPostedCrMemo(SalesCrMemoHeader);
        LibrarySmallBusiness.FindSalesCorrectiveInvoice(SalesInvoiceHeader, SalesCrMemoHeader);

        // [THEN] "PSCM" was cancelled and a new invoice was created
        SalesInvoiceHeader.TestField("Sell-to Customer No.", CustomerNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelPurchaseCrMemoCancelledPurchaseInvoiceWithGLAndBlankedGenGroups()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchInvHeader: Record "Purch. Inv. Header";
        CancelPostedPurchCrMemo: Codeunit "Cancel Posted Purch. Cr. Memo";
        VendorNo: Code[20];
        GLAccountNo: Code[20];
        DocumentNo: Code[20];
    begin
        // [SCENARIO 431382] Cancel posted Purchase credit memo that canceled posted Purchase invoice with G/L account with blank gen. posting groups
        Initialize();
        if GeneralPostingSetup.Get('', '') then
            GeneralPostingSetup.Delete();

        // [GIVEN] Cancelled by Purchase credit memo "PPCM" posted Purchase invoice with g/l account with blank gen. posting groups
        VendorNo := LibraryPurchase.CreateVendorNo();
        UpdateVendorGenBusPostingGroup(VendorNo, '');
        GLAccountNo := LibraryERM.CreateGLAccountWithPurchSetup();
        UpdateGLAccGenProdPostingGroup(GLAccountNo, '');
        DocumentNo := CreateAndPostPurchInvoiceWithGLAccount(VendorNo, GLAccountNo);
        CancelPurchInvoice(PurchCrMemoHdr, DocumentNo);

        // [WHEN] Cancel "PPCM"
        CancelPostedPurchCrMemo.CancelPostedCrMemo(PurchCrMemoHdr);
        LibrarySmallBusiness.FindPurchCorrectiveInvoice(PurchInvHeader, PurchCrMemoHdr);

        // [THEN] "PPCM" was cancelled and a new invoice was created
        PurchInvHeader.TestField("Buy-from Vendor No.", VendorNo);
    end;

#if not CLEAN27
    [Test]
    [HandlerFunctions('PurchaseInvoiceStatsPurchaseAmountLCYModalPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyAmountLCYOnPurchInvStatistics()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedDocumentNo: Code[20];
    begin
        // [SCENARIO 451479] Verify the Purchase (LCY) value in on Posted Purchase Invoice Statistics
        Initialize();

        // [GIVEN] Create Purchase Invoice and Post
        CreatePurchaseDocumentWithoutTaxAreaCode(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Opening the Posted Purchase Invoice Statistics
        OpenPostedInvoiceStatistics(PostedDocumentNo);

        // [VERIFY] Verification has been done in handler PurchaseInvoiceStatsModalPageHandler
    end;
#endif
    [Test]
    [HandlerFunctions('PurchaseInvoiceStatsPurchaseAmountLCYPageHandler')]
    [Scope('OnPrem')]
    procedure VerifyAmountLCYOnPurchInvStatisticsNM()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedDocumentNo: Code[20];
    begin
        // [SCENARIO 451479] Verify the Purchase (LCY) value in on Posted Purchase Invoice Statistics
        Initialize();

        // [GIVEN] Create Purchase Invoice and Post
        CreatePurchaseDocumentWithoutTaxAreaCode(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Opening the Posted Purchase Invoice Statistics
        OpenPostedInvoiceStatisticsNM(PostedDocumentNo);

        // [VERIFY] Verification has been done in handler PurchaseInvoiceStatsModalPageHandler
    end;

    [Test]
    procedure TestGLEntryConsistencyErrorIfCommentLineBetweenItem()
    var
        Currency: Record Currency;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine, SalesLine1, SalesLine2, SalesLine3 : Record "Sales Line";
        SalesInvocieHeader: Record "Sales Invoice Header";
        TaxArea: Record "Tax Area";
        TaxGroup: Record "Tax Group";
        TaxDetail: Record "Tax Detail";
        ItemNo: Code[20];
        PostedDocumentNo: Code[20];
        UnitPrice: Decimal;
    begin
        //[SCENARIO 597331] G/L Entry inconsistency when posting Sales Invoice with specific amounts and comment
        Initialize();

        // [GIVEN] Create Currency and set the new exchange rate from working date, Exch Rate Amt as 1, Relational Exch Rate Amt as 1.3691
        LibraryERM.CreateCurrency(Currency);
        CreateCurrencyExchangeRate(Currency.Code, WorkDate(), 1, 1.3691);

        // [GIVEN] Create Sales Tax and set Tax Below Max = 3.0 
        LibraryERM.CreateTaxArea(TaxArea);
        LibraryERM.CreateTaxGroup(TaxGroup);
        CreateTaxAreaSetupWithValues(TaxDetail, TaxArea.Code, TaxGroup.Code, 3);

        // [GIVEN] Create Customer with Currency and Tax Area Code
        CreateCustomerWithCurrencyAndTaxArea(Customer, Currency.Code, TaxArea.Code);

        // [GIVEN] Create Item with Tax Group Code
        ItemNo := CreateItem(TaxGroup.Code);

        // [GIVEN] Create Sales Invoice Document
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [GIVEN] Create first line with Item - Quantity as 1 and Unit Price as 730.991
        UnitPrice := 730.991;
        LibrarySales.CreateSalesLineWithUnitPrice(SalesLine, SalesHeader, ItemNo, UnitPrice, 1);

        // [GIVEN] Create second line with Item - Quantity as 1 and Unit Price as 730.991
        LibrarySales.CreateSalesLineWithUnitPrice(SalesLine1, SalesHeader, ItemNo, UnitPrice, 1);

        // [GIVEN] Create third line with Type as blank and Random Description
        LibrarySales.CreateSalesLine(SalesLine2, SalesHeader, SalesLine.Type::" ", '', 0);
        SalesLine2.Validate(Description, LibraryRandom.RandText(100));
        SalesLine2.Modify(true);

        // [GIVEN] Create fourth line with Item - Quantity as 1 and Unit Price as 730.991
        LibrarySales.CreateSalesLineWithUnitPrice(SalesLine3, SalesHeader, ItemNo, UnitPrice, 1);

        // [WHEN] Post the sales document
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] No error of G/L Consistency should come
        SalesInvocieHeader.Get(PostedDocumentNo);
    end;

    local procedure Initialize()
    var
        ICSetup: Record "IC Setup";
    begin
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;

        if not ICSetup.Get() then begin
            ICSetup.Init();
            ICSetup.Insert();
        end;
        ICSetup."Auto. Send Transactions" := false;
        ICSetup.Modify();

        LibraryERMCountryData.CreateVATData();
        LibraryApplicationArea.EnableFoundationSetup();
        LibrarySales.SetStockoutWarning(false);

        SetVatInUseInGeneralLedgerSetup(false);
        UpdateUseVendorsTaxAreaCodeOnPurchasePayableSetup();
        CreateSalesTaxVATPostingSetup();

        LibrarySetupStorage.SaveGeneralLedgerSetup();

        Commit();
        isInitialized := true;
    end;

    local procedure SetVatInUseInGeneralLedgerSetup(NewValue: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.GetRecordOnce();
        GeneralLedgerSetup.Validate("VAT in Use", NewValue);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure PostPurchaseCreditMemoAfterGetShipmentLines(TaxAreaCode: Code[20]; VendorNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", PurchaseHeader."No.");
        PurchaseHeader.Validate("Tax Area Code", TaxAreaCode);
        PurchaseHeader.Validate("Tax Liable", true);
        PurchaseHeader.Modify(true);
        PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
        CODEUNIT.Run(CODEUNIT::"Purch.-Get Return Shipments", PurchaseLine);  // Open Get Return Shipment Lines Page.
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CalcACYFromLCY(GLEntry: Record "G/L Entry"; CurrencyCode: Code[10]): Decimal
    var
        AddCurrency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
        CurrencyFactor: Decimal;
    begin
        AddCurrency.Get(CurrencyCode);
        CurrencyFactor := CurrExchRate.ExchangeRate(GLEntry."Posting Date", CurrencyCode);
        exit(Round(
            CurrExchRate.ExchangeAmtLCYToFCY(
              GLEntry."Posting Date", CurrencyCode, GLEntry.Amount, CurrencyFactor),
            AddCurrency."Amount Rounding Precision"));
    end;

    [Scope('OnPrem')]
    procedure CreateAndPostItemJournalLine(EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; Quantity: Integer; LocationCode: Code[10]; BinCode: Code[20]; NewLocationCode: Code[10]; NewBinCode: Code[20])
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate("Bin Code", BinCode);
        if EntryType = ItemJournalLine."Entry Type"::Transfer then begin
            ItemJournalLine.Validate("New Location Code", NewLocationCode);
            ItemJournalLine.Validate("New Bin Code", NewBinCode);
        end;
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; Invoice: Boolean; Quantity: Decimal; ReturnQtyToShip: Decimal): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
    begin
        TaxAreaCode := CreateTaxAreaLine(TaxDetail, TaxDetail."Tax Type"::"Sales Tax Only");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendor(TaxAreaCode, ''));
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(TaxDetail."Tax Group Code"), Quantity);
        PurchaseLine.Validate("Return Qty. to Ship", ReturnQtyToShip);  // Required to post partial Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));  // Take RANDOM Value for Unit Cost.
        PurchaseLine.Validate("Tax Group Code", TaxDetail."Tax Group Code");
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, Invoice));
    end;

    local procedure CreateAndPostPurchaseInvoiceWithICPartner(var PurchaseLine: Record "Purchase Line"; GLAccountNo: Code[20]; VendorNo: Code[20]; UseTax: Boolean): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, GLAccountNo, UseTax);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateAndPostSalesDocumentWithSalesCommentLine(var SalesCommentLine: Record "Sales Comment Line"; DocumentType: Enum "Sales Document Type"; Invoice: Boolean): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDocumentWithCommentLine(SalesCommentLine, DocumentType);
        SalesHeader.Get(SalesCommentLine."Document Type", SalesCommentLine."No.");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, Invoice));  // Post as Ship.
    end;

    local procedure CreateAndPostSalesInvoiceWithICPartner(var SalesLine: Record "Sales Line"; GLAccountNo: Code[20]; CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        CreateSalesLine(SalesLine, SalesHeader, GLAccountNo);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostServiceOrder(var ServiceLine: Record "Service Line")
    var
        Customer: Record Customer;
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        CreateServiceItem(ServiceItem, Customer."No.", Item."No.");
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Resource, CreateResource());
        ServiceLine.Validate("Service Item No.", ServiceItem."No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));  // Using RANDOM value for Quantity.
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Using RANDOM value for Unit Price.
        ServiceLine.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);  // Post as Invoice.
    end;

    local procedure CreateAndPostSalesInvoiceWithGLAccount(CustomerNo: Code[20]; GLAccountNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostPurchInvoiceWithGLAccount(VendorNo: Code[20]; GLAccountNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseLine.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateCustomer(TaxAreaCode: Code[20]; VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Tax Area Code", TaxAreaCode);
        Customer.Validate("Tax Liable", true);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCurrencyWithExchRate(): Code[10]
    var
        Currency: Record Currency;
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        Currency.Validate("Residual Gains Account", GLAccount."No.");
        Currency.Validate("Residual Losses Account", GLAccount."No.");
        Currency.Modify(true);
        exit(Currency.Code);
    end;

    local procedure CreateGLAccount(VATPostingSetup: Record "VAT Posting Setup"; GenPostingType: Enum "General Posting Type"; GenProdPostingGroup: Code[20]; TaxGroupCode: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Posting Type", GenPostingType);
        GLAccount.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Validate("Tax Group Code", TaxGroupCode);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateICPartner(): Code[20]
    var
        GLAccount: Record "G/L Account";
        ICPartner: Record "IC Partner";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        LibraryERM.CreateICPartner(ICPartner);
        ICPartner.Validate("Receivables Account", GLAccount."No.");
        ICPartner.Validate("Payables Account", GLAccount."No.");
        ICPartner.Modify(true);
        exit(ICPartner.Code);
    end;

    local procedure CreateICOutboxJnlLineWithTax(TaxType: Option; UseTax: Boolean)
    var
        TaxDetail: Record "Tax Detail";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        PurchaseLine: Record "Purchase Line";
        TaxAreaCode: Code[20];
        GLAccountNo: Code[20];
        DocumentNo: Code[20];
    begin
        // Setup: Create Tax Setup and create GL Account with VAT and Gen Posting setup.
        Initialize();
        TaxAreaCode := CreateTaxAreaLine(TaxDetail, TaxType);
        CreateVatPostingSetup(VATPostingSetup);
        GLAccountNo :=
          CreateGLAccount(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase, FindGenProdPostingGroup(), TaxDetail."Tax Group Code");

        // Exercise: Create and Post Purchase Invoice with IC Account.
        DocumentNo :=
          CreateAndPostPurchaseInvoiceWithICPartner(
            PurchaseLine, GLAccountNo, CreateVendor(TaxAreaCode, VATPostingSetup."VAT Bus. Posting Group"), UseTax);

        // Verify: Verifying Amount Including VAT on IC Outbox Jnl. Line.
        VerifyTaxAmountOnICOutboxJnlLine(PurchaseLine."IC Partner Code", CalcAmountInclVAT(DocumentNo, UseTax));
    end;

    local procedure CreateItem(TaxGroupCode: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Tax Group Code", TaxGroupCode);
        Item.Validate("VAT Prod. Posting Group", '');  // Need Blank Posting Group for Sales Tax Calculation.
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemChargeWithPostingGroups(var ItemCharge: Record "Item Charge"; GenProdPostingGroup: Code[20]; VATProdPostingGroup: Code[20])
    begin
        LibraryInventory.CreateItemChargeWithoutVAT(ItemCharge);
        ItemCharge.Validate("Gen. Prod. Posting Group", GenProdPostingGroup);
        ItemCharge.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        ItemCharge.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateLocationWithTwoBins(var Location: Record Location; var Bin: array[2] of Record Bin)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, true, false, false, false, false);
        LibraryWarehouse.CreateBin(Bin[1], Location.Code, '', '', '');
        LibraryWarehouse.CreateBin(Bin[2], Location.Code, '', '', '');
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; GLAccountNo: Code[20]; UseTax: Boolean)
    var
        ICGLAccount: Record "IC G/L Account";
    begin
        LibraryERM.CreateICGLAccount(ICGLAccount);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo, LibraryRandom.RandDec(10, 2));  // Using Random Number Generator for Random Quantity.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));  // Using Random Number Generator for Random Direct Unit Cost.
        PurchaseLine.Validate("IC Partner Code", CreateICPartner());
        PurchaseLine.Validate("IC Partner Ref. Type", PurchaseLine."IC Partner Ref. Type"::"G/L Account");
        PurchaseLine.Validate("IC Partner Reference", ICGLAccount."No.");
        PurchaseLine.Validate("Use Tax", UseTax);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateResource(): Code[20]
    var
        Resource: Record Resource;
    begin
        LibraryResource.CreateResourceNew(Resource);
        Resource.Validate(Capacity, LibraryRandom.RandDec(10, 2));  // Use random value for Capacity.
        Resource.Modify(true);
        exit(Resource."No.");
    end;

    local procedure CreateSalesCreditMemoAndGetShipmentLines(CustomerNo: Code[20]; TaxAreaCode: Code[20]): Code[20]
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
        SalesHeader.Validate("Tax Area Code", TaxAreaCode);
        SalesHeader.Validate("Tax Liable", true);
        SalesHeader.Modify(true);
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        CODEUNIT.Run(CODEUNIT::"Sales-Get Return Receipts", SalesLine);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateSalesDocumentWithCommentLine(var SalesCommentLine: Record "Sales Comment Line"; DocumentType: Enum "Sales Document Type"): Code[20]
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocument(SalesLine, DocumentType);
        LibrarySales.CreateSalesCommentLine(SalesCommentLine, SalesLine."Document Type", SalesLine."Document No.", 0);  // Value 0 required for Document Line No.
        exit(SalesLine."No.");
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"): Decimal
    var
        SalesHeader: Record "Sales Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
    begin
        TaxAreaCode := CreateTaxAreaLine(TaxDetail, TaxDetail."Tax Type"::"Sales Tax Only");
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer(TaxAreaCode, ''));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(TaxDetail."Tax Group Code"), LibraryRandom.RandDec(10, 2));  // Taken Random Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));  // Taken Random Unit Price.
        SalesLine.Modify(true);
        exit(TaxDetail."Tax Below Maximum");
    end;

    local procedure CreateSalesDocumentWithTwoSalesLines(var SalesLine: Record "Sales Line"; var SalesLine2: Record "Sales Line"; DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
    begin
        TaxAreaCode := CreateTaxAreaLine(TaxDetail, TaxDetail."Tax Type"::"Sales Tax Only");
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CreateCustomer(TaxAreaCode, ''));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2));
        LibrarySales.CreateSalesLine(
          SalesLine2, SalesHeader, SalesLine2.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; GLAccountNo: Code[20])
    var
        ICGLAccount: Record "IC G/L Account";
    begin
        LibraryERM.CreateICGLAccount(ICGLAccount);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("IC Partner Code", CreateICPartner());
        SalesLine.Validate("IC Partner Ref. Type", SalesLine."IC Partner Ref. Type"::"G/L Account");
        SalesLine.Validate("IC Partner Reference", ICGLAccount."No.");
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrderUsingGLAccount(var SalesLine: Record "Sales Line"): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        UpdateGLFreightAccountNoOnSalesReceivablesSetup(GLAccount."No.");
        CreateSalesDocument(SalesLine, SalesLine."Document Type"::Order);
        UpdateGLAccount(GLAccount, SalesLine."Tax Group Code");
        exit(GLAccount."No.");
    end;

    local procedure CreateSalesOrderWithTwoSalesLinesUsingGLAccount(var SalesLine: array[2] of Record "Sales Line"): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        UpdateGLFreightAccountNoOnSalesReceivablesSetup(GLAccount."No.");
        CreateSalesDocumentWithTwoSalesLines(SalesLine[1], SalesLine[2], SalesLine[1]."Document Type"::Order);
        exit(GLAccount."No.");
    end;

    local procedure CreateSalesTaxDetail(var TaxDetail: Record "Tax Detail"; TaxType: Option)
    var
        TaxGroup: Record "Tax Group";
    begin
        LibraryERM.CreateTaxGroup(TaxGroup);
        LibraryERM.CreateTaxDetail(TaxDetail, CreateSalesTaxJurisdiction(), TaxGroup.Code, TaxType, WorkDate());
        TaxDetail.Validate("Tax Below Maximum", LibraryRandom.RandInt(10));  // Using RANDOM value for Tax Below Maximum.
        TaxDetail.Modify(true);
    end;

    local procedure CreateSalesTaxJurisdiction(): Code[10]
    var
        GLAccount: Record "G/L Account";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        LibraryERM.CreateGLAccount(GLAccount);
        TaxJurisdiction.Validate("Tax Account (Sales)", GLAccount."No.");
        TaxJurisdiction.Validate("Tax Account (Purchases)", GLAccount."No.");
        TaxJurisdiction.Validate("Reverse Charge (Purchases)", GLAccount."No.");
        TaxJurisdiction.Modify(true);
        exit(TaxJurisdiction.Code);
    end;

    local procedure CreateServiceItem(var ServiceItem: Record "Service Item"; CustomerNo: Code[20]; ItemNo: Code[20])
    begin
        LibraryService.CreateServiceItem(ServiceItem, CustomerNo);
        ServiceItem.Validate("Item No.", ItemNo);
        ServiceItem.Modify(true);
    end;

    local procedure CreateTaxArea(var TaxArea: Record "Tax Area"; TaxGroupCode: Code[20])
    var
        TaxAreaLine: Record "Tax Area Line";
        TaxDetail: Record "Tax Detail";
        TaxJurisdiction: Record "Tax Jurisdiction";
    begin
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        LibraryERMTax.CreateTaxDetail(TaxDetail, TaxJurisdiction.Code, TaxGroupCode, LibraryRandom.RandInt(10));
        LibraryERM.CreateTaxArea(TaxArea);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxJurisdiction.Code);
    end;

    local procedure CreateTaxAreaLine(var TaxDetail: Record "Tax Detail"; TaxType: Option): Code[20]
    var
        TaxArea: Record "Tax Area";
        TaxAreaLine: Record "Tax Area Line";
    begin
        CreateSalesTaxDetail(TaxDetail, TaxType);
        LibraryERM.CreateTaxArea(TaxArea);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxArea.Code, TaxDetail."Tax Jurisdiction Code");
        exit(TaxArea.Code);
    end;

    local procedure CreateSalesTaxVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if not VATPostingSetup.Get('', '') then begin
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, '', '');
            VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Sales Tax");
            VATPostingSetup.Modify(true);
        end;
    end;

    local procedure CreateVatPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Sales Tax");
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateGenPostingSetupWithBlankGenBusPostingGroup(var GeneralPostingSetup: Record "General Posting Setup")
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        LibraryERM.CreateGeneralPostingSetup(GeneralPostingSetup, '', GenProductPostingGroup.Code);
        GeneralPostingSetup.Validate("Sales Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Validate("Purch. Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Validate("COGS Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Validate("Direct Cost Applied Account", LibraryERM.CreateGLAccountNo());
        GeneralPostingSetup.Modify(true);
    end;

    local procedure CreateVendor(TaxAreaCode: Code[20]; VATBusPostGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Tax Area Code", TaxAreaCode);
        Vendor.Validate("Tax Liable", true);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostGroup);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreatePurchaseDocumentWithTaxAreaCode(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
        TaxDetail: Record "Tax Detail";
        TaxAreaCode: Code[20];
    begin
        TaxAreaCode := CreateTaxAreaLine(TaxDetail, TaxDetail."Tax Type"::"Sales Tax Only");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, CreateVendor(TaxAreaCode, ''));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(TaxDetail."Tax Group Code"), LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(50, 100));
        PurchaseLine.Validate("Tax Group Code", TaxDetail."Tax Group Code");
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseDocumentWithoutTaxAreaCode(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(50, 100));
        PurchaseLine.Modify(true);
    end;

    local procedure CancelSalesInvoice(var SalesCrMemoHeader: Record "Sales Cr.Memo Header"; SalesInvHeaderNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CorrectPostedSalesInvoice: Codeunit "Correct Posted Sales Invoice";
    begin
        SalesInvoiceHeader.Get(SalesInvHeaderNo);
        CorrectPostedSalesInvoice.CancelPostedInvoice(SalesInvoiceHeader);
        LibrarySmallBusiness.FindSalesCorrectiveCrMemo(SalesCrMemoHeader, SalesInvoiceHeader);
    end;

    local procedure CancelPurchInvoice(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; PurchInvHeaderNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        CorrectPostedPurchInvoice: Codeunit "Correct Posted Purch. Invoice";
    begin
        PurchInvHeader.Get(PurchInvHeaderNo);
        CorrectPostedPurchInvoice.CancelPostedInvoice(PurchInvHeader);
        LibrarySmallBusiness.FindPurchCorrectiveCrMemo(PurchCrMemoHdr, PurchInvHeader);
    end;

    local procedure CalcAmountInclVAT(DocumentNo: Code[20]; UseTax: Boolean) AmountInclVAT: Decimal
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        TempSalesTaxAmountLine: Record "Sales Tax Amount Line" temporary;
        TempSalesTaxAmtLine: Record "Sales Tax Amount Line" temporary;
        SalesTaxCalculate: Codeunit "Sales Tax Calculate";
    begin
        PurchInvHeader.Get(DocumentNo);
        PurchInvHeader.CalcFields("Amount Including VAT");
        AmountInclVAT := PurchInvHeader."Amount Including VAT";
        if UseTax then begin
            SalesTaxCalculate.StartSalesTaxCalculation();
            SalesTaxCalculate.AddPurchInvoiceLines(PurchInvHeader."No.");
            SalesTaxCalculate.EndSalesTaxCalculation(PurchInvHeader."Posting Date");
            SalesTaxCalculate.GetSalesTaxAmountLineTable(TempSalesTaxAmountLine);
            SalesTaxCalculate.GetSummarizedSalesTaxTable(TempSalesTaxAmtLine);
            TempSalesTaxAmtLine.Reset();
            TempSalesTaxAmtLine.CalcSums("Tax Amount");
            AmountInclVAT := AmountInclVAT + TempSalesTaxAmtLine."Tax Amount";
        end;
        exit(AmountInclVAT);
    end;

    local procedure FindCustomerPostingGroup(CustomerNo: Code[20]): Code[20]
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        Customer.Get(CustomerNo);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        exit(CustomerPostingGroup."Receivables Account");
    end;

    local procedure FindGenProdPostingGroup(): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        exit(GeneralPostingSetup."Gen. Prod. Posting Group");
    end;

    local procedure FindServiceInvoiceHeader(OrderNo: Code[20]): Code[20]
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
    begin
        ServiceInvoiceHeader.SetRange("Order No.", OrderNo);
        ServiceInvoiceHeader.FindFirst();
        exit(ServiceInvoiceHeader."No.");
    end;

    local procedure FindTaxDetail(TaxGroupCode: Code[20]): Decimal
    var
        TaxDetail: Record "Tax Detail";
    begin
        TaxDetail.SetRange("Tax Group Code", TaxGroupCode);
        TaxDetail.FindFirst();
        exit(TaxDetail."Tax Below Maximum");
    end;

    local procedure FindVendorPostingGroup(VendorNo: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        Vendor.Get(VendorNo);
        VendorPostingGroup.Get(Vendor."Vendor Posting Group");
        exit(VendorPostingGroup."Payables Account");
    end;

    local procedure FilterSalesInvoiceLine(var SalesInvoiceLine: Record "Sales Invoice Line"; DocumentNo: Code[20])
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::"G/L Account");
        SalesInvoiceLine.FindFirst();
    end;

    local procedure FilterSalesLine(var SalesLine: Record "Sales Line"; DocumentNo: Code[20]; Type: Enum "Sales Line Type")
    begin
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange(Type, Type);
        SalesLine.FindFirst();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; No: Code[20])
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("No.", No);
        SalesLine.FindFirst();
    end;

    local procedure ModifyAdditionalReportingCurrencyOnGLSetup(AdditionalReportingCurrency: Code[10])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Additional Reporting Currency" := AdditionalReportingCurrency;
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure OpenPostFromSalesOrderShipment(No: Code[20]; FreightAmount: Decimal)
    var
        SalesOrderShipment: TestPage "Sales Order Shipment";
    begin
        SalesOrderShipment.OpenEdit();
        SalesOrderShipment.FILTER.SetFilter("No.", No);
        SalesOrderShipment.FreightAmount.SetValue(FreightAmount);
        SalesOrderShipment."P&ost".Invoke();
    end;

    local procedure OpenPrintFromPostedSalesShipments(No: Code[20]; PrintPackageTrackingNos: Boolean)
    var
        PostedSalesShipments: TestPage "Posted Sales Shipments";
    begin
        LibraryVariableStorage.Enqueue(No);
        LibraryVariableStorage.Enqueue(PrintPackageTrackingNos);
        PostedSalesShipments.OpenEdit();
        PostedSalesShipments.FILTER.SetFilter("No.", No);
        PostedSalesShipments."&Print".Invoke();
    end;

#if not CLEAN27
    local procedure OpenPostedInvoiceStatistics(PostesInvoiceNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        PurchInvHeader.Get(PostesInvoiceNo);
        PurchInvHeader.CalcFields("Amount Including VAT");
        LibraryVariableStorage.Enqueue(PurchInvHeader."Amount Including VAT");
        PostedPurchaseInvoice.OpenEdit();
        PostedPurchaseInvoice.FILTER.SetFilter("No.", PostesInvoiceNo);
        PostedPurchaseInvoice.Statistics.Invoke();
    end;

    local procedure OpenPostedPurchCreditMemoStatistics(PostesInvoiceNo: Code[20])
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PostedPurchaswCreditMemo: TestPage "Posted Purchase Credit Memo";
    begin
        PurchCrMemoHdr.Get(PostesInvoiceNo);
        PurchCrMemoHdr.CalcFields("Amount Including VAT");
        LibraryVariableStorage.Enqueue(PurchCrMemoHdr."Amount Including VAT");
        PostedPurchaswCreditMemo.OpenEdit();
        PostedPurchaswCreditMemo.FILTER.SetFilter("No.", PostesInvoiceNo);
        PostedPurchaswCreditMemo.Statistics.Invoke();
    end;
#endif
    local procedure OpenPostedInvoiceStatsNM(PostesInvoiceNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        PurchInvHeader.Get(PostesInvoiceNo);
        PurchInvHeader.CalcFields("Amount Including VAT");
        LibraryVariableStorage.Enqueue(PurchInvHeader."Amount Including VAT");
        PostedPurchaseInvoice.OpenEdit();
        PostedPurchaseInvoice.FILTER.SetFilter("No.", PostesInvoiceNo);
        PostedPurchaseInvoice.PurchaseInvoiceStats.Invoke();
    end;

    local procedure OpenPostedInvoiceStatisticsNM(PostesInvoiceNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        PurchInvHeader.Get(PostesInvoiceNo);
        PurchInvHeader.CalcFields("Amount Including VAT");
        LibraryVariableStorage.Enqueue(PurchInvHeader."Amount Including VAT");
        PostedPurchaseInvoice.OpenEdit();
        PostedPurchaseInvoice.FILTER.SetFilter("No.", PostesInvoiceNo);
        PostedPurchaseInvoice.PurchaseInvoiceStatistics.Invoke();
    end;

    local procedure OpenPostedPurchCreditMemoStatsNM(PostesInvoiceNo: Code[20])
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
    begin
        PurchCrMemoHdr.Get(PostesInvoiceNo);
        PurchCrMemoHdr.CalcFields("Amount Including VAT");
        LibraryVariableStorage.Enqueue(PurchCrMemoHdr."Amount Including VAT");
        PostedPurchaseCreditMemo.OpenEdit();
        PostedPurchaseCreditMemo.FILTER.SetFilter("No.", PostesInvoiceNo);
        PostedPurchaseCreditMemo.PurchaseCrMemoStats.Invoke();
    end;

    local procedure PostPurchaseCreditMemo(DocumentNo: Code[20]) DocumentNo2: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type"::"Return Order", DocumentNo);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        DocumentNo2 :=
          PostPurchaseCreditMemoAfterGetShipmentLines(PurchaseHeader."Tax Area Code", PurchaseHeader."Buy-from Vendor No.");
    end;

    local procedure UpdateGLAccount(var GLAccount: Record "G/L Account"; TaxGroupCode: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        GLAccount.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", GeneralPostingSetup."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", '');  // Need Blank Posting Group for Sales Tax Calculation.
        GLAccount.Validate("VAT Prod. Posting Group", '');  // Need Blank Posting Group for Sales Tax Calculation.
        GLAccount.Validate("Tax Group Code", TaxGroupCode);
        GLAccount.Modify(true);
    end;

    local procedure UpdateGLFreightAccountNoOnSalesReceivablesSetup(GLFreightAccountNo: Code[20])
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Freight G/L Acc. No.", GLFreightAccountNo);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdatePackageTrackingNoOnSalesHeader(var SalesHeader: Record "Sales Header"; DocumentNo: Code[20])
    begin
        SalesHeader.Get(SalesHeader."Document Type"::Order, DocumentNo);
        SalesHeader.Validate("Package Tracking No.", LibraryUtility.GenerateGUID());
        SalesHeader.Modify(true);
    end;

    local procedure UpdateSalesReceivablesSetup(FieldNo: Integer; Value: Variant)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        SalesReceivablesSetup.Get();
        RecRef.GetTable(SalesReceivablesSetup);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(Value);
        RecRef.SetTable(SalesReceivablesSetup);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateUseVendorsTaxAreaCodeOnPurchasePayableSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Use Vendor's Tax Area Code", true);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdateWarningsOnSalesReceivablesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Stockout Warning", false);
        SalesReceivablesSetup.Validate("Credit Warnings", SalesReceivablesSetup."Credit Warnings"::"No Warning");
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateCustomerGenBusPostingGroup(CustomerNo: Code[20]; NewGenBusPostingGroupCode: Code[20])
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer.Validate("Gen. Bus. Posting Group", NewGenBusPostingGroupCode);
        Customer.Modify(true);
    end;

    local procedure UpdateVendorGenBusPostingGroup(VendorNo: Code[20]; NewGenBusPostingGroupCode: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Vendor.Validate("Gen. Bus. Posting Group", NewGenBusPostingGroupCode);
        Vendor.Modify(true);
    end;

    local procedure UpdateGLAccGenProdPostingGroup(GLAccountNo: Code[20]; NewGenProdPostingGroupCode: Code[20])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(GLAccountNo);
        GLAccount.Validate("Gen. Prod. Posting Group", NewGenProdPostingGroupCode);
        GLAccount.Modify(true);
    end;

    local procedure CreateCurrencyExchangeRate(CurrencyCode: Code[10]; StartingDate: Date; ExchangeRateAmount: Decimal; RelationalExchRateAmount: Decimal)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin

        LibraryERM.CreateExchRate(CurrencyExchangeRate, CurrencyCode, StartingDate);
        CurrencyExchangeRate.Validate("Exchange Rate Amount", ExchangeRateAmount);  // Magic exchange rate
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", RelationalExchRateAmount);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);
    end;

    local procedure CreateTaxAreaSetupWithValues(var TaxDetail: Record "Tax Detail"; TaxAreaCode: Code[20]; TaxGroupCode: Code[20]; TaxBelowMax: Decimal)
    var
        TaxJurisdiction: Record "Tax Jurisdiction";
        TaxAreaLine: Record "Tax Area Line";
    begin
        LibraryERM.CreateTaxJurisdiction(TaxJurisdiction);
        TaxJurisdiction.Validate("Tax Account (Purchases)", LibraryERM.CreateGLAccountNo());
        TaxJurisdiction.Modify(true);
        LibraryERM.CreateTaxDetail(TaxDetail, TaxJurisdiction.Code, TaxGroupCode, TaxDetail."Tax Type"::"Sales and Use Tax", WorkDate());
        TaxDetail.Validate("Tax Below Maximum", TaxBelowMax);
        TaxDetail.Modify(true);
        LibraryERM.CreateTaxAreaLine(TaxAreaLine, TaxAreaCode, TaxJurisdiction.Code);
    end;

    local procedure CreateCustomerWithCurrencyAndTaxArea(var Customer: Record Customer; CurrencyCode: Code[10]; TaxAreaCode: Code[20])
    var
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Validate("Tax Area Code", TaxAreaCode);
        Customer.Validate("Tax Liable", true);
        Customer.Validate("VAT Bus. Posting Group", '');
        Customer.Modify(true);
    end;

    local procedure VerifyErrorOnSalesCommentLine(DocumentType: Enum "Sales Comment Document Type"; DocumentNo: Code[20]; LineNo: Integer)
    var
        SalesCommentLine: Record "Sales Comment Line";
    begin
        asserterror SalesCommentLine.Get(DocumentType, DocumentNo, 0, LineNo);  // Value 0 required for Document Line No.
        Assert.ExpectedErrorCannotFind(Database::"Sales Comment Line");
    end;

    [Scope('OnPrem')]
    procedure VerifyFreightAmountLineCount(SalesLine: Record "Sales Line"; FreightGLAccountNo: Code[20]; "Count": Integer)
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type");
        SalesLine.SetRange("Document No.", SalesLine."Document No.");
        SalesLine.SetRange(Type, SalesLine.Type::"G/L Account");
        SalesLine.SetRange("No.", FreightGLAccountNo);
        Assert.RecordCount(SalesLine, Count);
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; GenPostingType: Enum "General Posting Type"; GenProdPostingGroup: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Bal. Account Type", GLEntry."Bal. Account Type"::"IC Partner");
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(-Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), AmountNotEqualMsg);
        GLEntry.TestField("Gen. Posting Type", GenPostingType);
        GLEntry.TestField("Gen. Prod. Posting Group", GenProdPostingGroup);
    end;

    local procedure VerifyGLEntryForICPartner(DocumentNo: Code[20]; GLAccountNo: Code[20]; BalAccountNo: Code[20]; BalAccountType: Enum "Gen. Journal Account Type"; ExpectedAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange("Bal. Account No.", BalAccountNo);
        GLEntry.SetRange("Bal. Account Type", BalAccountType);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(ExpectedAmount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), AmountNotEqualMsg);
    end;

    local procedure VerifyAmountOnGLEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal; AdditionalCurrencyAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), AmountNotEqualMsg);
        Assert.AreNearlyEqual(
          AdditionalCurrencyAmount, GLEntry."Additional-Currency Amount",
          LibraryERM.GetAmountRoundingPrecision(), AmountNotEqualMsg);
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; Base: Decimal; Amount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::"Credit Memo");
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(Base, VATEntry.Base, LibraryERM.GetAmountRoundingPrecision(), AmountNotEqualMsg);
        Assert.AreNearlyEqual(Amount, VATEntry.Amount, LibraryERM.GetAmountRoundingPrecision(), AmountNotEqualMsg);
    end;

    local procedure VerifyItemLedgerEntry(EntryType: Enum "Item Ledger Entry Type"; DocumentNo: Code[20]; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.FindFirst();
        Assert.AreNearlyEqual(Quantity, ItemLedgerEntry.Quantity, LibraryERM.GetAmountRoundingPrecision(), AmountNotEqualMsg);
    end;

    local procedure VerifyICOutboxTransaction(DocumentNo: Code[20]; ICPartnerCode: Code[20])
    var
        ICOutboxTransaction: Record "IC Outbox Transaction";
    begin
        ICOutboxTransaction.SetRange("Document Type", ICOutboxTransaction."Document Type"::Invoice);
        ICOutboxTransaction.SetRange("Document No.", DocumentNo);
        ICOutboxTransaction.FindFirst();
        ICOutboxTransaction.TestField("IC Partner Code", ICPartnerCode);
    end;

    local procedure VerifyTaxAmountOnICOutboxJnlLine(ICPartnerCode: Code[20]; TaxAmount: Decimal)
    var
        ICOutboxJnlLine: Record "IC Outbox Jnl. Line";
    begin
        ICOutboxJnlLine.SetRange("Account Type", ICOutboxJnlLine."Account Type"::"IC Partner");
        ICOutboxJnlLine.SetRange("Account No.", ICPartnerCode);
        ICOutboxJnlLine.FindFirst();
        ICOutboxJnlLine.TestField(Amount, TaxAmount);
    end;

    local procedure VerifySalesCommentLine(DocumentType: Enum "Sales Comment Document Type"; DocumentNo: Code[20]; LineNo: Integer; Comment: Text[80])
    var
        SalesCommentLine: Record "Sales Comment Line";
    begin
        SalesCommentLine.Get(DocumentType, DocumentNo, 0, LineNo);  // Value 0 required for Document Line No.
        SalesCommentLine.TestField(Comment, Comment);
    end;

    local procedure VerifySalesCrMemoGLAccLine(DocumentNo: Code[20]; ExpectedNo: Code[20])
    var
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoLine.SetRange(Type, SalesCrMemoLine.Type::"G/L Account");
        SalesCrMemoLine.SetRange("Document No.", DocumentNo);
        SalesCrMemoLine.FindFirst();
        SalesCrMemoLine.TestField("No.", ExpectedNo);
    end;

    [Scope('OnPrem')]
    procedure VerifySalesLinesWithFreightAmounts(SalesLine: array[2] of Record "Sales Line"; FreightAmount: Integer; FreightAmount2: Integer; FreightGLAccountNo: Code[20])
    begin
        SalesLine[1].SetRange("Document Type", SalesLine[2]."Document Type");
        SalesLine[1].SetRange("Document No.", SalesLine[2]."Document No.");
        SalesLine[1].SetRange(Type, SalesLine[2].Type::"G/L Account");
        SalesLine[1].SetRange("No.", FreightGLAccountNo);
        SalesLine[1].SetRange("Line Amount", FreightAmount);
        Assert.RecordIsNotEmpty(SalesLine[1]);
        SalesLine[1].SetRange("Line Amount", FreightAmount2);
        Assert.RecordIsNotEmpty(SalesLine[1]);
    end;

    local procedure VerifyPurchCrMemoGLAccLine(DocumentNo: Code[20]; ExpectedNo: Code[20])
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        PurchCrMemoLine.SetRange(Type, PurchCrMemoLine.Type::"G/L Account");
        PurchCrMemoLine.SetRange("Document No.", DocumentNo);
        PurchCrMemoLine.FindFirst();
        PurchCrMemoLine.TestField("No.", ExpectedNo);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetReturnShipmentLinesForSalesPageHandler(var GetReturnShipmentLines: TestPage "Get Return Receipt Lines")
    begin
        GetReturnShipmentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetReturnShipmentLinesForPurchasePageHandler(var GetReturnShipmentLines: TestPage "Get Return Shipment Lines")
    begin
        GetReturnShipmentLines.OK().Invoke();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatsPageHandler(var SalesOrderStats: TestPage "Sales Order Stats.")
    begin
        Assert.IsFalse(SalesOrderStats."TotalSalesLine[1].""Inv. Discount Amount""".Editable(), StrSubstNo(EditableErr, 'Inv. Discount Amount'));
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatsPageHandlerNM(var SalesOrderStats: TestPage "Sales Order Stats.")
    begin
        Assert.IsFalse(SalesOrderStats."TotalSalesLine[1].""Inv. Discount Amount""".Editable(), StrSubstNo(EditableErr, 'Inv. Discount Amount'));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesShipmentRequestPageHandler(var SalesShipment: TestRequestPage "Sales Shipment NA")
    var
        No: Variant;
        PrintPackageTrackingNos: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(PrintPackageTrackingNos);
        SalesShipment."Sales Shipment Header".SetFilter("No.", No);
        SalesShipment.PrintPackageTrackingNos.SetValue(PrintPackageTrackingNos);
        SalesShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

#if not CLEAN27
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceStatsModalPageHandler(var PurchaseInvoiceStats: TestPage "Purchase Invoice Stats.")
    var
        AmountInclVAT: Variant;
    begin
        LibraryVariableStorage.Dequeue(AmountInclVAT);
        PurchaseInvoiceStats.AmountInclVAT.AssertEquals(AmountInclVAT);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoStatsModalPageHandler(var PurchCreditMemoStats: TestPage "Purch. Credit Memo Stats.")
    var
        AmountInclVAT: Variant;
    begin
        LibraryVariableStorage.Dequeue(AmountInclVAT);
        PurchCreditMemoStats.AmountInclVAT.AssertEquals(AmountInclVAT);
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceStatsModalPageHandlerNM(var PurchaseInvoiceStats: TestPage "Purchase Invoice Stats.")
    var
        AmountInclVAT: Variant;
    begin
        LibraryVariableStorage.Dequeue(AmountInclVAT);
        PurchaseInvoiceStats.AmountInclVAT.AssertEquals(AmountInclVAT);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoStatsModalPageHandlerNM(var PurchCreditMemoStats: TestPage "Purch. Credit Memo Stats.")
    var
        AmountInclVAT: Variant;
    begin
        LibraryVariableStorage.Dequeue(AmountInclVAT);
        PurchCreditMemoStats.AmountInclVAT.AssertEquals(AmountInclVAT);
    end;
#if not CLEAN27
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceStatsPurchaseAmountLCYModalPageHandler(var PurchaseInvoiceStatistics: TestPage "Purchase Invoice Statistics")
    var
        PurchaseAmountLCY: Variant;
        AmountLCY: Decimal;
    begin
        LibraryVariableStorage.Dequeue(PurchaseAmountLCY);
        Evaluate(AmountLCY, PurchaseInvoiceStatistics.AmountLCY.Value);
        PurchaseInvoiceStatistics.AmountLCY.AssertEquals(Abs(AmountLCY));
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceStatsPurchaseAmountLCYPageHandler(var PurchaseInvoiceStatistics: TestPage "Purchase Invoice Statistics")
    var
        PurchaseAmountLCY: Variant;
        AmountLCY: Decimal;
    begin
        LibraryVariableStorage.Dequeue(PurchaseAmountLCY);
        Evaluate(AmountLCY, PurchaseInvoiceStatistics.AmountLCY.Value);
        PurchaseInvoiceStatistics.AmountLCY.AssertEquals(Abs(AmountLCY));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderConfirmationRequestPageHandler(var StandardSalesOrderConf: TestRequestPage "Standard Sales - Order Conf.")
    begin
        StandardSalesOrderConf.Header.SetFilter("No.", LibraryVariableStorage.DequeueText());
        StandardSalesOrderConf.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderRequestPageHandler(var SalesOrder: TestRequestPage "Sales Order")
    begin
        SalesOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesReturnOrderRequestPageHandler(var ReturnAuthorization: TestRequestPage "Return Authorization")
    begin
        ReturnAuthorization.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesQuoteRequestPageHandler(var SalesQuoteNA: TestRequestPage "Sales Quote NA")
    begin
        SalesQuoteNA.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesBlanketOrderRequestPageHandler(var SalesBlanketOrder: TestRequestPage "Sales Blanket Order")
    begin
        SalesBlanketOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}
