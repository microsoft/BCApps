codeunit 134485 "ERM Dimension Shortcuts"
{
    Subtype = Test;
    EventSubscriberInstance = Manual;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Dimension] [Shortcuts]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryDimension: Codeunit "Library - Dimension";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        IsInitialized: Boolean;
        TempBatchNameTxt: Label 'BD_TEMP';
        ShortcutDimErrorTxt: Label 'Recurring Method must not be BD Balance by Dimension in Gen. Journal Line';
        KeepExistingDimensionsMsg: Label 'This will change the dimension specified on the document. Do you want to recalculate/update dimensions?';
        UpdateDimensionOnLineMsg: Label 'You may have changed a dimension.\\Do you want to update the lines?';

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderDimShortcutVisibility()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [GIVEN] Dimension Shortcuts defined by General Ledger Setup
        Initialize();
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', '', 1, '', 0D);

        // [WHEN] Open page Sales Order
        SalesOrder.OpenNew();

        // [THEN] Defined Dimension Shortcuts are visible, others are not
        AssertVisibility(1, SalesOrder.SalesLines."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(2, SalesOrder.SalesLines."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(3, SalesOrder.SalesLines.ShortcutDimCode3.Visible());
        AssertVisibility(4, SalesOrder.SalesLines.ShortcutDimCode4.Visible());
        AssertVisibility(5, SalesOrder.SalesLines.ShortcutDimCode5.Visible());
        AssertVisibility(6, SalesOrder.SalesLines.ShortcutDimCode6.Visible());
        AssertVisibility(7, SalesOrder.SalesLines.ShortcutDimCode7.Visible());
        AssertVisibility(8, SalesOrder.SalesLines.ShortcutDimCode8.Visible());
        SalesOrder.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteDimShortcutVisibility()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [GIVEN] Dimension Shortcuts defined by General Ledger Setup
        Initialize();
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote, '', '', 1, '', 0D);

        // [WHEN] Open page Sales Quote
        SalesQuote.OpenNew();

        // [THEN] Defined Dimension Shortcuts are visible, others are not
        AssertVisibility(1, SalesQuote.SalesLines."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(2, SalesQuote.SalesLines."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(3, SalesQuote.SalesLines.ShortcutDimCode3.Visible());
        AssertVisibility(4, SalesQuote.SalesLines.ShortcutDimCode4.Visible());
        AssertVisibility(5, SalesQuote.SalesLines.ShortcutDimCode5.Visible());
        AssertVisibility(6, SalesQuote.SalesLines.ShortcutDimCode6.Visible());
        AssertVisibility(7, SalesQuote.SalesLines.ShortcutDimCode7.Visible());
        AssertVisibility(8, SalesQuote.SalesLines.ShortcutDimCode8.Visible());
        SalesQuote.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceDimShortcutVisibility()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [GIVEN] Dimension Shortcuts defined by General Ledger Setup
        Initialize();
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, '', '', 1, '', 0D);

        // [WHEN] Open page Sales Invoice
        SalesInvoice.OpenNew();

        // [THEN] Defined Dimension Shortcuts are visible, others are not
        AssertVisibility(1, SalesInvoice.SalesLines."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(2, SalesInvoice.SalesLines."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(3, SalesInvoice.SalesLines.ShortcutDimCode3.Visible());
        AssertVisibility(4, SalesInvoice.SalesLines.ShortcutDimCode4.Visible());
        AssertVisibility(5, SalesInvoice.SalesLines.ShortcutDimCode5.Visible());
        AssertVisibility(6, SalesInvoice.SalesLines.ShortcutDimCode6.Visible());
        AssertVisibility(7, SalesInvoice.SalesLines.ShortcutDimCode7.Visible());
        AssertVisibility(8, SalesInvoice.SalesLines.ShortcutDimCode8.Visible());
        SalesInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoDimShortcutVisibility()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [GIVEN] Dimension Shortcuts defined by General Ledger Setup
        Initialize();
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", '', '', 1, '', 0D);

        // [WHEN] Open page Sales Credit Memo
        SalesCreditMemo.OpenNew();

        // [THEN] Defined Dimension Shortcuts are visible, others are not
        AssertVisibility(1, SalesCreditMemo.SalesLines."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(2, SalesCreditMemo.SalesLines."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(3, SalesCreditMemo.SalesLines.ShortcutDimCode3.Visible());
        AssertVisibility(4, SalesCreditMemo.SalesLines.ShortcutDimCode4.Visible());
        AssertVisibility(5, SalesCreditMemo.SalesLines.ShortcutDimCode5.Visible());
        AssertVisibility(6, SalesCreditMemo.SalesLines.ShortcutDimCode6.Visible());
        AssertVisibility(7, SalesCreditMemo.SalesLines.ShortcutDimCode7.Visible());
        AssertVisibility(8, SalesCreditMemo.SalesLines.ShortcutDimCode8.Visible());
        SalesCreditMemo.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOrderDimShortcutVisibility()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // [GIVEN] Dimension Shortcuts defined by General Ledger Setup
        Initialize();
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", '', '', 1, '', 0D);

        // [WHEN] Open page Sales Return Order
        SalesReturnOrder.OpenNew();

        // [THEN] Defined Dimension Shortcuts are visible, others are not
        AssertVisibility(1, SalesReturnOrder.SalesLines."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(2, SalesReturnOrder.SalesLines."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(3, SalesReturnOrder.SalesLines.ShortcutDimCode3.Visible());
        AssertVisibility(4, SalesReturnOrder.SalesLines.ShortcutDimCode4.Visible());
        AssertVisibility(5, SalesReturnOrder.SalesLines.ShortcutDimCode5.Visible());
        AssertVisibility(6, SalesReturnOrder.SalesLines.ShortcutDimCode6.Visible());
        AssertVisibility(7, SalesReturnOrder.SalesLines.ShortcutDimCode7.Visible());
        AssertVisibility(8, SalesReturnOrder.SalesLines.ShortcutDimCode8.Visible());
        SalesReturnOrder.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderDimShortcutVisibility()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchOrder: TestPage "Purchase Order";
    begin
        // [GIVEN] Dimension Shortcuts defined by General Ledger Setup
        Initialize();
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchHeader, PurchLine, PurchHeader."Document Type"::Order, '', '', 1, '', 0D);

        // [WHEN] Open page Purchase Order
        PurchOrder.OpenNew();

        // [THEN] Defined Dimension Shortcuts are visible, others are not
        AssertVisibility(1, PurchOrder.PurchLines."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(2, PurchOrder.PurchLines."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(3, PurchOrder.PurchLines.ShortcutDimCode3.Visible());
        AssertVisibility(4, PurchOrder.PurchLines.ShortcutDimCode4.Visible());
        AssertVisibility(5, PurchOrder.PurchLines.ShortcutDimCode5.Visible());
        AssertVisibility(6, PurchOrder.PurchLines.ShortcutDimCode6.Visible());
        AssertVisibility(7, PurchOrder.PurchLines.ShortcutDimCode7.Visible());
        AssertVisibility(8, PurchOrder.PurchLines.ShortcutDimCode8.Visible());
        PurchOrder.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchQuoteDimShortcutVisibility()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchQuote: TestPage "Purchase Quote";
    begin
        // [GIVEN] Dimension Shortcuts defined by General Ledger Setup
        Initialize();
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchHeader, PurchLine, PurchHeader."Document Type"::Quote, '', '', 1, '', 0D);

        // [WHEN] Open page Purchase Quote
        PurchQuote.OpenNew();

        // [THEN] Defined Dimension Shortcuts are visible, others are not
        AssertVisibility(1, PurchQuote.PurchLines."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(2, PurchQuote.PurchLines."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(3, PurchQuote.PurchLines.ShortcutDimCode3.Visible());
        AssertVisibility(4, PurchQuote.PurchLines.ShortcutDimCode4.Visible());
        AssertVisibility(5, PurchQuote.PurchLines.ShortcutDimCode5.Visible());
        AssertVisibility(6, PurchQuote.PurchLines.ShortcutDimCode6.Visible());
        AssertVisibility(7, PurchQuote.PurchLines.ShortcutDimCode7.Visible());
        AssertVisibility(8, PurchQuote.PurchLines.ShortcutDimCode8.Visible());
        PurchQuote.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvoiceDimShortcutVisibility()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchInvoice: TestPage "Purchase Invoice";
    begin
        // [GIVEN] Dimension Shortcuts defined by General Ledger Setup
        Initialize();
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchHeader, PurchLine, PurchHeader."Document Type"::Invoice, '', '', 1, '', 0D);

        // [WHEN] Open page Purchase Invoice
        PurchInvoice.OpenNew();

        // [THEN] Defined Dimension Shortcuts are visible, others are not
        AssertVisibility(1, PurchInvoice.PurchLines."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(2, PurchInvoice.PurchLines."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(3, PurchInvoice.PurchLines.ShortcutDimCode3.Visible());
        AssertVisibility(4, PurchInvoice.PurchLines.ShortcutDimCode4.Visible());
        AssertVisibility(5, PurchInvoice.PurchLines.ShortcutDimCode5.Visible());
        AssertVisibility(6, PurchInvoice.PurchLines.ShortcutDimCode6.Visible());
        AssertVisibility(7, PurchInvoice.PurchLines.ShortcutDimCode7.Visible());
        AssertVisibility(8, PurchInvoice.PurchLines.ShortcutDimCode8.Visible());
        PurchInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCreditMemoDimShortcutVisibility()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [GIVEN] Dimension Shortcuts defined by General Ledger Setup
        Initialize();
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchHeader, PurchLine, PurchHeader."Document Type"::"Credit Memo", '', '', 1, '', 0D);

        // [WHEN] Open page Purchase Credit Memo
        PurchCreditMemo.OpenNew();

        // [THEN] Defined Dimension Shortcuts are visible, others are not
        AssertVisibility(1, PurchCreditMemo.PurchLines."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(2, PurchCreditMemo.PurchLines."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(3, PurchCreditMemo.PurchLines.ShortcutDimCode3.Visible());
        AssertVisibility(4, PurchCreditMemo.PurchLines.ShortcutDimCode4.Visible());
        AssertVisibility(5, PurchCreditMemo.PurchLines.ShortcutDimCode5.Visible());
        AssertVisibility(6, PurchCreditMemo.PurchLines.ShortcutDimCode6.Visible());
        AssertVisibility(7, PurchCreditMemo.PurchLines.ShortcutDimCode7.Visible());
        AssertVisibility(8, PurchCreditMemo.PurchLines.ShortcutDimCode8.Visible());
        PurchCreditMemo.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchReturnOrderDimShortcutVisibility()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        PurchReturnOrder: TestPage "Purchase Return Order";
    begin
        // [GIVEN] Dimension Shortcuts defined by General Ledger Setup
        Initialize();
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchHeader, PurchLine, PurchHeader."Document Type"::"Return Order", '', '', 1, '', 0D);

        // [WHEN] Open page Purchase Return Order
        PurchReturnOrder.OpenNew();

        // [THEN] Defined Dimension Shortcuts are visible, others are not
        AssertVisibility(1, PurchReturnOrder.PurchLines."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(2, PurchReturnOrder.PurchLines."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(3, PurchReturnOrder.PurchLines.ShortcutDimCode3.Visible());
        AssertVisibility(4, PurchReturnOrder.PurchLines.ShortcutDimCode4.Visible());
        AssertVisibility(5, PurchReturnOrder.PurchLines.ShortcutDimCode5.Visible());
        AssertVisibility(6, PurchReturnOrder.PurchLines.ShortcutDimCode6.Visible());
        AssertVisibility(7, PurchReturnOrder.PurchLines.ShortcutDimCode7.Visible());
        AssertVisibility(8, PurchReturnOrder.PurchLines.ShortcutDimCode8.Visible());
        PurchReturnOrder.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderDimShortcutVisibilityAll()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [GIVEN] All Dimension Shortcuts defined by General Ledger Setup
        Initialize();

        SetGLSetupAllDimensions();

        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', '', 1, '', 0D);

        // [WHEN] Open page Sales Order
        SalesOrder.OpenNew();

        // [THEN] All Dimension Shortcuts are visible
        Assert.IsTrue(SalesOrder.SalesLines.ShortcutDimCode3.Visible(), 'Dim Shortcut 3 must be visible');
        Assert.IsTrue(SalesOrder.SalesLines.ShortcutDimCode4.Visible(), 'Dim Shortcut 4 must be visible');
        Assert.IsTrue(SalesOrder.SalesLines.ShortcutDimCode5.Visible(), 'Dim Shortcut 5 must be visible');
        Assert.IsTrue(SalesOrder.SalesLines.ShortcutDimCode6.Visible(), 'Dim Shortcut 6 must be visible');
        Assert.IsTrue(SalesOrder.SalesLines.ShortcutDimCode7.Visible(), 'Dim Shortcut 7 must be visible');
        Assert.IsTrue(SalesOrder.SalesLines.ShortcutDimCode8.Visible(), 'Dim Shortcut 8 must be visible');
        SalesOrder.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderDimShortcutVisibilityNone()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [GIVEN] None Dimension Shortcuts defined by General Ledger Setup
        Initialize();
        ClearDimShortcuts();

        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', '', 1, '', 0D);

        // [WHEN] Open page Sales Order
        SalesOrder.OpenNew();

        // [THEN] None Dimension Shortcuts are visible
        Assert.IsFalse(SalesOrder.SalesLines.ShortcutDimCode3.Visible(), 'Dim Shortcut 3 must not be visible');
        Assert.IsFalse(SalesOrder.SalesLines.ShortcutDimCode4.Visible(), 'Dim Shortcut 4 must not be visible');
        Assert.IsFalse(SalesOrder.SalesLines.ShortcutDimCode5.Visible(), 'Dim Shortcut 5 must not be visible');
        Assert.IsFalse(SalesOrder.SalesLines.ShortcutDimCode6.Visible(), 'Dim Shortcut 6 must not be visible');
        Assert.IsFalse(SalesOrder.SalesLines.ShortcutDimCode7.Visible(), 'Dim Shortcut 7 must not be visible');
        Assert.IsFalse(SalesOrder.SalesLines.ShortcutDimCode8.Visible(), 'Dim Shortcut 8 must not be visible');
        SalesOrder.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderDimShortcutVisibilitySelected()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        DimShortcuts: array[6] of Boolean;
    begin
        // [GIVEN] Three random Dimension Shortcuts defined by General Ledger Setup
        Initialize();

        Clear(DimShortcuts);
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        ClearDimShortcuts();
        AssignGLSetupShortcuts(DimShortcuts);

        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', '', 1, '', 0D);

        // [WHEN] Open page Sales Order
        SalesOrder.OpenNew();

        // [THEN] Only 3 defined Dimension Shortcuts are visible, others 3 are not
        Assert.AreEqual(SalesOrder.SalesLines.ShortcutDimCode3.Visible(), DimShortcuts[1], 'Dim Shortcut 3');
        Assert.AreEqual(SalesOrder.SalesLines.ShortcutDimCode4.Visible(), DimShortcuts[2], 'Dim Shortcut 4');
        Assert.AreEqual(SalesOrder.SalesLines.ShortcutDimCode5.Visible(), DimShortcuts[3], 'Dim Shortcut 5');
        Assert.AreEqual(SalesOrder.SalesLines.ShortcutDimCode6.Visible(), DimShortcuts[4], 'Dim Shortcut 6');
        Assert.AreEqual(SalesOrder.SalesLines.ShortcutDimCode7.Visible(), DimShortcuts[5], 'Dim Shortcut 7');
        Assert.AreEqual(SalesOrder.SalesLines.ShortcutDimCode8.Visible(), DimShortcuts[6], 'Dim Shortcut 8');
        SalesOrder.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesQuoteArchiveDimShortcutVisibility()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ArchiveManagement: Codeunit ArchiveManagement;
        SalesQuoteArchive: TestPage "Sales Quote Archive";
    begin
        // [SCENARIO 302075] Sales quote archive line dimensions shortcuts displayed properly
        Initialize();

        // [GIVEN] Set up all 8 dimensions in General Ledger Setup
        SetGLSetupAllDimensions();

        // [GIVEN] Make sales quote archive
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote, '', '', 1, '', 0D);
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);

        // [WHEN] Open page Sales Quote Archive
        SalesQuoteArchive.OpenEdit();
        SalesQuoteArchive.FILTER.SetFilter("No.", SalesHeader."No.");

        // [THEN] All defined Dimension Shortcuts are visible
        AssertVisibility(1, SalesQuoteArchive.SalesLinesArchive."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(2, SalesQuoteArchive.SalesLinesArchive."Shortcut Dimension 2 Code".Visible());
        AssertVisibility(3, SalesQuoteArchive.SalesLinesArchive.ShortcutDimCode3.Visible());
        AssertVisibility(4, SalesQuoteArchive.SalesLinesArchive.ShortcutDimCode4.Visible());
        AssertVisibility(5, SalesQuoteArchive.SalesLinesArchive.ShortcutDimCode5.Visible());
        AssertVisibility(6, SalesQuoteArchive.SalesLinesArchive.ShortcutDimCode6.Visible());
        AssertVisibility(7, SalesQuoteArchive.SalesLinesArchive.ShortcutDimCode7.Visible());
        AssertVisibility(8, SalesQuoteArchive.SalesLinesArchive.ShortcutDimCode8.Visible());
        SalesQuoteArchive.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchQuoteArchiveDimShortcutVisibility()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ArchiveManagement: Codeunit ArchiveManagement;
        PurchaseQuoteArchive: TestPage "Purchase Quote Archive";
    begin
        // [SCENARIO 302075] Purchase quote archive line dimensions shortcuts displayed properly
        Initialize();

        // [GIVEN] Set up all 8 dimensions in General Ledger Setup
        SetGLSetupAllDimensions();

        // [GIVEN] Make purchase quote archive
        LibraryPurchase.CreatePurchaseDocumentWithItem(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Quote, '', '', 1, '', 0D);
        ArchiveManagement.ArchivePurchDocument(PurchaseHeader);

        // [WHEN] Open page Purchase Quote Archive
        PurchaseQuoteArchive.OpenEdit();
        PurchaseQuoteArchive.FILTER.SetFilter("No.", PurchaseHeader."No.");

        // [THEN] All defined Dimension Shortcuts are visible
        AssertVisibility(1, PurchaseQuoteArchive.PurchLinesArchive."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(2, PurchaseQuoteArchive.PurchLinesArchive."Shortcut Dimension 2 Code".Visible());
        AssertVisibility(3, PurchaseQuoteArchive.PurchLinesArchive.ShortcutDimCode3.Visible());
        AssertVisibility(4, PurchaseQuoteArchive.PurchLinesArchive.ShortcutDimCode4.Visible());
        AssertVisibility(5, PurchaseQuoteArchive.PurchLinesArchive.ShortcutDimCode5.Visible());
        AssertVisibility(6, PurchaseQuoteArchive.PurchLinesArchive.ShortcutDimCode6.Visible());
        AssertVisibility(7, PurchaseQuoteArchive.PurchLinesArchive.ShortcutDimCode7.Visible());
        AssertVisibility(8, PurchaseQuoteArchive.PurchLinesArchive.ShortcutDimCode8.Visible());
        PurchaseQuoteArchive.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderArchiveSubformDimShortcutVisibility()
    var
        SalesOrderArchiveSubform: TestPage "Sales Order Archive Subform";
    begin
        // [GIVEN] [SCENARIO 344011] Sales Order Archive Subform line dimensions shortcuts displayed properly
        Initialize();

        // [GIVEN] Set up all 8 dimensions in General Ledger Setup
        SetGLSetupAllDimensions();

        // [WHEN] Open page "Sales Order Archive Subform"
        SalesOrderArchiveSubform.OpenNew();

        // [THEN] Defined Dimension Shortcuts are visible
        AssertVisibility(1, SalesOrderArchiveSubform."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(2, SalesOrderArchiveSubform."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(3, SalesOrderArchiveSubform.ShortcutDimCode3.Visible());
        AssertVisibility(4, SalesOrderArchiveSubform.ShortcutDimCode4.Visible());
        AssertVisibility(5, SalesOrderArchiveSubform.ShortcutDimCode5.Visible());
        AssertVisibility(6, SalesOrderArchiveSubform.ShortcutDimCode6.Visible());
        AssertVisibility(7, SalesOrderArchiveSubform.ShortcutDimCode7.Visible());
        AssertVisibility(8, SalesOrderArchiveSubform.ShortcutDimCode8.Visible());
        SalesOrderArchiveSubform.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderArchiveSubformDimShortcutVisibility()
    var
        PurchaseOrderArchiveSubform: TestPage "Purchase Order Archive Subform";
    begin
        // [GIVEN] [SCENARIO 344011] Purchase Order Archive Subform line dimensions shortcuts displayed properly
        Initialize();

        // [GIVEN] Set up all 8 dimensions in General Ledger Setup
        SetGLSetupAllDimensions();

        // [WHEN] Open page "Purchase Order Archive Subform"
        PurchaseOrderArchiveSubform.OpenNew();

        // [THEN] Defined Dimension Shortcuts are visible
        AssertVisibility(1, PurchaseOrderArchiveSubform."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(2, PurchaseOrderArchiveSubform."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(3, PurchaseOrderArchiveSubform.ShortcutDimCode3.Visible());
        AssertVisibility(4, PurchaseOrderArchiveSubform.ShortcutDimCode4.Visible());
        AssertVisibility(5, PurchaseOrderArchiveSubform.ShortcutDimCode5.Visible());
        AssertVisibility(6, PurchaseOrderArchiveSubform.ShortcutDimCode6.Visible());
        AssertVisibility(7, PurchaseOrderArchiveSubform.ShortcutDimCode7.Visible());
        AssertVisibility(8, PurchaseOrderArchiveSubform.ShortcutDimCode8.Visible());
        PurchaseOrderArchiveSubform.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteArchiveSubformDimShortcutVisibility()
    var
        SalesQuoteArchiveSubform: TestPage "Sales Quote Archive Subform";
    begin
        // [GIVEN] [SCENARIO 344011] Sales Quote Archive Subform line dimensions shortcuts displayed properly
        Initialize();

        // [GIVEN] Set up all 8 dimensions in General Ledger Setup
        SetGLSetupAllDimensions();

        // [WHEN] Open page "Sales Quote Archive Subform"
        SalesQuoteArchiveSubform.OpenNew();

        // [THEN] Defined Dimension Shortcuts are visible
        AssertVisibility(1, SalesQuoteArchiveSubform."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(2, SalesQuoteArchiveSubform."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(3, SalesQuoteArchiveSubform.ShortcutDimCode3.Visible());
        AssertVisibility(4, SalesQuoteArchiveSubform.ShortcutDimCode4.Visible());
        AssertVisibility(5, SalesQuoteArchiveSubform.ShortcutDimCode5.Visible());
        AssertVisibility(6, SalesQuoteArchiveSubform.ShortcutDimCode6.Visible());
        AssertVisibility(7, SalesQuoteArchiveSubform.ShortcutDimCode7.Visible());
        AssertVisibility(8, SalesQuoteArchiveSubform.ShortcutDimCode8.Visible());
        SalesQuoteArchiveSubform.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchQuoteArchiveSubformDimShortcutVisibility()
    var
        PurchaseQuoteArchiveSubform: TestPage "Purchase Quote Archive Subform";
    begin
        // [GIVEN] [SCENARIO 344011] Purchase Quote Archive Subform line dimensions shortcuts displayed properly
        Initialize();

        // [GIVEN] Set up all 8 dimensions in General Ledger Setup
        SetGLSetupAllDimensions();

        // [WHEN] Open page "Purchase Quote Archive Subform"
        PurchaseQuoteArchiveSubform.OpenNew();

        // [THEN] Defined Dimension Shortcuts are visible
        AssertVisibility(1, PurchaseQuoteArchiveSubform."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(2, PurchaseQuoteArchiveSubform."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(3, PurchaseQuoteArchiveSubform.ShortcutDimCode3.Visible());
        AssertVisibility(4, PurchaseQuoteArchiveSubform.ShortcutDimCode4.Visible());
        AssertVisibility(5, PurchaseQuoteArchiveSubform.ShortcutDimCode5.Visible());
        AssertVisibility(6, PurchaseQuoteArchiveSubform.ShortcutDimCode6.Visible());
        AssertVisibility(7, PurchaseQuoteArchiveSubform.ShortcutDimCode7.Visible());
        AssertVisibility(8, PurchaseQuoteArchiveSubform.ShortcutDimCode8.Visible());
        PurchaseQuoteArchiveSubform.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketSalesOrderArchiveSubformDimShortcutVisibility()
    var
        BlanketSalesOrderArchSub: TestPage "Blanket Sales Order Arch. Sub.";
    begin
        // [GIVEN] [SCENARIO 344011] Blanket Sales Order Arch. Sub. line dimensions shortcuts displayed properly
        Initialize();

        // [GIVEN] Set up all 8 dimensions in General Ledger Setup
        SetGLSetupAllDimensions();

        // [WHEN] Open page "Blanket Sales Order Arch. Sub."
        BlanketSalesOrderArchSub.OpenNew();

        // [THEN] Defined Dimension Shortcuts are visible
        AssertVisibility(1, BlanketSalesOrderArchSub."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(2, BlanketSalesOrderArchSub."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(3, BlanketSalesOrderArchSub.ShortcutDimCode3.Visible());
        AssertVisibility(4, BlanketSalesOrderArchSub.ShortcutDimCode4.Visible());
        AssertVisibility(5, BlanketSalesOrderArchSub.ShortcutDimCode5.Visible());
        AssertVisibility(6, BlanketSalesOrderArchSub.ShortcutDimCode6.Visible());
        AssertVisibility(7, BlanketSalesOrderArchSub.ShortcutDimCode7.Visible());
        AssertVisibility(8, BlanketSalesOrderArchSub.ShortcutDimCode8.Visible());
        BlanketSalesOrderArchSub.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketPurchOrderArchiveSubformDimShortcutVisibility()
    var
        BlanketPurchOrderArchSub: TestPage "Blanket Purch. Order Arch.Sub.";
    begin
        // [GIVEN] [SCENARIO 344011] Blanket Purch. Order Arch.Sub. line dimensions shortcuts displayed properly
        Initialize();

        // [GIVEN] Set up all 8 dimensions in General Ledger Setup
        SetGLSetupAllDimensions();

        // [WHEN] Open page "Blanket Purch. Order Arch.Sub."
        BlanketPurchOrderArchSub.OpenNew();

        // [THEN] Defined Dimension Shortcuts are visible
        AssertVisibility(1, BlanketPurchOrderArchSub."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(2, BlanketPurchOrderArchSub."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(3, BlanketPurchOrderArchSub.ShortcutDimCode3.Visible());
        AssertVisibility(4, BlanketPurchOrderArchSub.ShortcutDimCode4.Visible());
        AssertVisibility(5, BlanketPurchOrderArchSub.ShortcutDimCode5.Visible());
        AssertVisibility(6, BlanketPurchOrderArchSub.ShortcutDimCode6.Visible());
        AssertVisibility(7, BlanketPurchOrderArchSub.ShortcutDimCode7.Visible());
        AssertVisibility(8, BlanketPurchOrderArchSub.ShortcutDimCode8.Visible());
        BlanketPurchOrderArchSub.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOrderArchiveSubformDimShortcutVisibility()
    var
        SalesReturnOrderArcSubform: TestPage "Sales Return Order Arc Subform";
    begin
        // [GIVEN] [SCENARIO 344011] Sales Return Order Arc Subform line dimensions shortcuts displayed properly
        Initialize();

        // [GIVEN] Set up all 8 dimensions in General Ledger Setup
        SetGLSetupAllDimensions();

        // [WHEN] Open page "Sales Return Order Arc Subform"
        SalesReturnOrderArcSubform.OpenNew();

        // [THEN] Defined Dimension Shortcuts are visible
        AssertVisibility(1, SalesReturnOrderArcSubform."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(2, SalesReturnOrderArcSubform."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(3, SalesReturnOrderArcSubform.ShortcutDimCode3.Visible());
        AssertVisibility(4, SalesReturnOrderArcSubform.ShortcutDimCode4.Visible());
        AssertVisibility(5, SalesReturnOrderArcSubform.ShortcutDimCode5.Visible());
        AssertVisibility(6, SalesReturnOrderArcSubform.ShortcutDimCode6.Visible());
        AssertVisibility(7, SalesReturnOrderArcSubform.ShortcutDimCode7.Visible());
        AssertVisibility(8, SalesReturnOrderArcSubform.ShortcutDimCode8.Visible());
        SalesReturnOrderArcSubform.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchReturnOrderArchiveSubformDimShortcutVisibility()
    var
        PurchReturnOrderArcSubform: TestPage "Purch Return Order Arc Subform";
    begin
        // [GIVEN] [SCENARIO 344011] Purch Return Order Arc Subform line dimensions shortcuts displayed properly
        Initialize();

        // [GIVEN] Set up all 8 dimensions in General Ledger Setup
        SetGLSetupAllDimensions();

        // [WHEN] Open page "Purch Return Order Arc Subform"
        PurchReturnOrderArcSubform.OpenNew();

        // [THEN] Defined Dimension Shortcuts are visible
        AssertVisibility(1, PurchReturnOrderArcSubform."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(2, PurchReturnOrderArcSubform."Shortcut Dimension 1 Code".Visible());
        AssertVisibility(3, PurchReturnOrderArcSubform.ShortcutDimCode3.Visible());
        AssertVisibility(4, PurchReturnOrderArcSubform.ShortcutDimCode4.Visible());
        AssertVisibility(5, PurchReturnOrderArcSubform.ShortcutDimCode5.Visible());
        AssertVisibility(6, PurchReturnOrderArcSubform.ShortcutDimCode6.Visible());
        AssertVisibility(7, PurchReturnOrderArcSubform.ShortcutDimCode7.Visible());
        AssertVisibility(8, PurchReturnOrderArcSubform.ShortcutDimCode8.Visible());
        PurchReturnOrderArcSubform.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntriesPreviewDimVisibilityAll()
    var
        GLEntriesPreview: TestPage "G/L Entries Preview";
    begin
        // [SCENARIO 352854] Dimensions 1-8 are visible on the "G/L Entries Preview" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are filled in the general ledger setup
        SetGLSetupAllDimensions();

        // [WHEN] Open "G/L Entries Preview" page
        GLEntriesPreview.OpenView();

        // [THEN] Dimensions 1-8 are visible
        AssertVisibility(1, GLEntriesPreview."Global Dimension 1 Code".Visible());
        AssertVisibility(2, GLEntriesPreview."Global Dimension 2 Code".Visible());
        AssertVisibility(3, GLEntriesPreview."Shortcut Dimension 3 Code".Visible());
        AssertVisibility(4, GLEntriesPreview."Shortcut Dimension 4 Code".Visible());
        AssertVisibility(5, GLEntriesPreview."Shortcut Dimension 5 Code".Visible());
        AssertVisibility(6, GLEntriesPreview."Shortcut Dimension 6 Code".Visible());
        AssertVisibility(7, GLEntriesPreview."Shortcut Dimension 7 Code".Visible());
        AssertVisibility(8, GLEntriesPreview."Shortcut Dimension 8 Code".Visible());

        GLEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntriesPreviewDimVisibilityNone()
    var
        GLEntriesPreview: TestPage "G/L Entries Preview";
    begin
        // [SCENARIO 352854] Dimensions 3-8 are not visible on the "G/L Entries Preview" page when they are empty in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are empty in the general ledger setup
        ClearDimShortcuts();

        // [WHEN] Open "G/L Entries Preview" page
        GLEntriesPreview.OpenView();

        // [THEN] Dimensions 3-8 are not visible
        Assert.IsFalse(GLEntriesPreview."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code should not be visible');
        Assert.IsFalse(GLEntriesPreview."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code should not be visible');
        Assert.IsFalse(GLEntriesPreview."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code should not be visible');
        Assert.IsFalse(GLEntriesPreview."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code should not be visible');
        Assert.IsFalse(GLEntriesPreview."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code should not be visible');
        Assert.IsFalse(GLEntriesPreview."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code should not be visible');

        GLEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntriesPreviewDimVisibilitySelected()
    var
        GLEntriesPreview: TestPage "G/L Entries Preview";
        DimShortcuts: array[6] of Boolean;
    begin
        // [SCENARIO 352854] Three random dimensions from 3-8 range are visible on the "G/L Entries Preview" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random dimensions are filled in the general ledger setup
        ClearDimShortcuts();
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        AssignGLSetupShortcuts(DimShortcuts);

        // [WHEN] Open "G/L Entries Preview" page
        GLEntriesPreview.OpenView();

        // [THEN] Three random dimensions are visible
        Assert.AreEqual(DimShortcuts[1], GLEntriesPreview."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[2], GLEntriesPreview."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[3], GLEntriesPreview."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[4], GLEntriesPreview."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[5], GLEntriesPreview."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[6], GLEntriesPreview."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code has wrong visibility');

        GLEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryShortcutDimensionsAll_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        GLEntry: Record "G/L Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are filled with values in g/l entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);

        // [GIVEN] Mock G/L Entry record
        GLEntry.Init();
        RecRef.GetTable(GLEntry);
        GLEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, GLEntry.FieldNo("Entry No."));
        GLEntry."Dimension Set ID" := DimSetId;
        GLEntry.Insert(false);

        // [WHEN] Calculate G/L Entry shortcut dimension values
        GLEntry.Get(GLEntry."Entry No.");
        GLEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] G/L Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(GLEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryShortcutDimensionsNone_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        GLEntry: Record "G/L Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are not filled with values in g/l entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are not filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();

        // [GIVEN] Mock G/L Entry record
        GLEntry.Init();
        RecRef.GetTable(GLEntry);
        GLEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, GLEntry.FieldNo("Entry No."));
        GLEntry."Dimension Set ID" := DimSetId;
        GLEntry.Insert(false);

        // [WHEN] Calculate G/L Entry shortcut dimension values
        GLEntry.Get(GLEntry."Entry No.");
        GLEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] G/L Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(GLEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryShortcutDimensionsSelected_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        GLEntry: Record "G/L Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Three random shortcut dimensions 3-8 are filled with values in g/l entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();
        SetGLSetupShortcutDimensionsSelected(DimensionValue);

        // [GIVEN] Mock G/L Entry record
        GLEntry.Init();
        RecRef.GetTable(GLEntry);
        GLEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, GLEntry.FieldNo("Entry No."));
        GLEntry."Dimension Set ID" := DimSetId;
        GLEntry.Insert(false);

        // [WHEN] Calculate G/L Entry shortcut dimension values
        GLEntry.Get(GLEntry."Entry No.");
        GLEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] G/L Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(GLEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccountLedgerEntryShortcutDimensionsAll_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are filled with values in Bank Account Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);

        // [GIVEN] Mock Bank Account Ledger Entry record
        BankAccountLedgerEntry.Init();
        RecRef.GetTable(BankAccountLedgerEntry);
        BankAccountLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, BankAccountLedgerEntry.FieldNo("Entry No."));
        BankAccountLedgerEntry."Dimension Set ID" := DimSetId;
        BankAccountLedgerEntry.Insert(false);

        // [WHEN] Calculate Bank Account Ledger Entry shortcut dimension values
        BankAccountLedgerEntry.Get(BankAccountLedgerEntry."Entry No.");
        BankAccountLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Bank Account Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(BankAccountLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccountLedgerEntryShortcutDimensionsNone_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are not filled with values in Bank Account Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are not filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();

        // [GIVEN] Mock Bank Account Ledger Entry record
        BankAccountLedgerEntry.Init();
        RecRef.GetTable(BankAccountLedgerEntry);
        BankAccountLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, BankAccountLedgerEntry.FieldNo("Entry No."));
        BankAccountLedgerEntry."Dimension Set ID" := DimSetId;
        BankAccountLedgerEntry.Insert(false);

        // [WHEN] Calculate Bank Account Ledger Entry shortcut dimension values
        BankAccountLedgerEntry.Get(BankAccountLedgerEntry."Entry No.");
        BankAccountLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Bank Account Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(BankAccountLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccountLedgerEntryShortcutDimensionsSelected_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        BankAccountLedgerEntry: Record "Bank Account Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Three random shortcut dimensions 3-8 are filled with values in Bank Account Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();
        SetGLSetupShortcutDimensionsSelected(DimensionValue);

        // [GIVEN] Mock Bank Account Ledger Entry record
        BankAccountLedgerEntry.Init();
        RecRef.GetTable(BankAccountLedgerEntry);
        BankAccountLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, BankAccountLedgerEntry.FieldNo("Entry No."));
        BankAccountLedgerEntry."Dimension Set ID" := DimSetId;
        BankAccountLedgerEntry.Insert(false);

        // [WHEN] Calculate Bank Account Ledger Entry shortcut dimension values
        BankAccountLedgerEntry.Get(BankAccountLedgerEntry."Entry No.");
        BankAccountLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Bank Account Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(BankAccountLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustLedgerEntryShortcutDimensionsAll_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are filled with values in Cust. Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);

        // [GIVEN] Mock Cust. Ledger Entry record
        CustLedgerEntry.Init();
        RecRef.GetTable(CustLedgerEntry);
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Dimension Set ID" := DimSetId;
        CustLedgerEntry.Insert(false);

        // [WHEN] Calculate Cust. Ledger Entry shortcut dimension values
        CustLedgerEntry.Get(CustLedgerEntry."Entry No.");
        CustLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Cust. Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(CustLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustLedgerEntryShortcutDimensionsNone_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are not filled with values in Cust. Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are not filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();

        // [GIVEN] Mock Cust. Ledger Entry record
        CustLedgerEntry.Init();
        RecRef.GetTable(CustLedgerEntry);
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Dimension Set ID" := DimSetId;
        CustLedgerEntry.Insert(false);

        // [WHEN] Calculate Cust. Ledger Entry shortcut dimension values
        CustLedgerEntry.Get(CustLedgerEntry."Entry No.");
        CustLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Cust. Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(CustLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustLedgerEntryShortcutDimensionsSelected_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Three random shortcut dimensions 3-8 are filled with values in Cust. Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();
        SetGLSetupShortcutDimensionsSelected(DimensionValue);

        // [GIVEN] Mock Cust. Ledger Entry record
        CustLedgerEntry.Init();
        RecRef.GetTable(CustLedgerEntry);
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Dimension Set ID" := DimSetId;
        CustLedgerEntry.Insert(false);

        // [WHEN] Calculate Cust. Ledger Entry shortcut dimension values
        CustLedgerEntry.Get(CustLedgerEntry."Entry No.");
        CustLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Cust. Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(CustLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FALedgerEntryShortcutDimensionsAll_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        FALedgerEntry: Record "FA Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are filled with values in FA Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);

        // [GIVEN] Mock FA Ledger Entry record
        FALedgerEntry.Init();
        RecRef.GetTable(FALedgerEntry);
        FALedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, FALedgerEntry.FieldNo("Entry No."));
        FALedgerEntry."Dimension Set ID" := DimSetId;
        FALedgerEntry.Insert(false);

        // [WHEN] Calculate FA Ledger Entry shortcut dimension values
        FALedgerEntry.Get(FALedgerEntry."Entry No.");
        FALedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] FA Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(FALedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FALedgerEntryShortcutDimensionsNone_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        FALedgerEntry: Record "FA Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are not filled with values in FA Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are not filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();

        // [GIVEN] Mock FA Ledger Entry record
        FALedgerEntry.Init();
        RecRef.GetTable(FALedgerEntry);
        FALedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, FALedgerEntry.FieldNo("Entry No."));
        FALedgerEntry."Dimension Set ID" := DimSetId;
        FALedgerEntry.Insert(false);

        // [WHEN] Calculate FA Ledger Entry shortcut dimension values
        FALedgerEntry.Get(FALedgerEntry."Entry No.");
        FALedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] FA Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(FALedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FALedgerEntryShortcutDimensionsSelected_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        FALedgerEntry: Record "FA Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Three random shortcut dimensions 3-8 are filled with values in FA Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();
        SetGLSetupShortcutDimensionsSelected(DimensionValue);

        // [GIVEN] Mock FA Ledger Entry record
        FALedgerEntry.Init();
        RecRef.GetTable(FALedgerEntry);
        FALedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, FALedgerEntry.FieldNo("Entry No."));
        FALedgerEntry."Dimension Set ID" := DimSetId;
        FALedgerEntry.Insert(false);

        // [WHEN] Calculate FA Ledger Entry shortcut dimension values
        FALedgerEntry.Get(FALedgerEntry."Entry No.");
        FALedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] FA Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(FALedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemLedgerEntryShortcutDimensionsAll_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        ItemLedgerEntry: Record "Item Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are filled with values in Item Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);

        // [GIVEN] Mock Item Ledger Entry record
        ItemLedgerEntry.Init();
        RecRef.GetTable(ItemLedgerEntry);
        ItemLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, ItemLedgerEntry.FieldNo("Entry No."));
        ItemLedgerEntry."Dimension Set ID" := DimSetId;
        ItemLedgerEntry.Insert(false);

        // [WHEN] Calculate Item Ledger Entry shortcut dimension values
        ItemLedgerEntry.Get(ItemLedgerEntry."Entry No.");
        ItemLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Item Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(ItemLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemLedgerEntryShortcutDimensionsNone_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        ItemLedgerEntry: Record "Item Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are not filled with values in Item Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are not filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();

        // [GIVEN] Mock Item Ledger Entry record
        ItemLedgerEntry.Init();
        RecRef.GetTable(ItemLedgerEntry);
        ItemLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, ItemLedgerEntry.FieldNo("Entry No."));
        ItemLedgerEntry."Dimension Set ID" := DimSetId;
        ItemLedgerEntry.Insert(false);

        // [WHEN] Calculate Item Ledger Entry shortcut dimension values
        ItemLedgerEntry.Get(ItemLedgerEntry."Entry No.");
        ItemLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Item Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(ItemLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemLedgerEntryShortcutDimensionsSelected_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        ItemLedgerEntry: Record "Item Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Three random shortcut dimensions 3-8 are filled with values in Item Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();
        SetGLSetupShortcutDimensionsSelected(DimensionValue);

        // [GIVEN] Mock Item Ledger Entry record
        ItemLedgerEntry.Init();
        RecRef.GetTable(ItemLedgerEntry);
        ItemLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, ItemLedgerEntry.FieldNo("Entry No."));
        ItemLedgerEntry."Dimension Set ID" := DimSetId;
        ItemLedgerEntry.Insert(false);

        // [WHEN] Calculate Item Ledger Entry shortcut dimension values
        ItemLedgerEntry.Get(ItemLedgerEntry."Entry No.");
        ItemLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Item Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(ItemLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobLedgerEntryShortcutDimensionsAll_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        JobLedgerEntry: Record "Job Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are filled with values in Job Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);

        // [GIVEN] Mock Job Ledger Entry record
        JobLedgerEntry.Init();
        RecRef.GetTable(JobLedgerEntry);
        JobLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, JobLedgerEntry.FieldNo("Entry No."));
        JobLedgerEntry."Dimension Set ID" := DimSetId;
        JobLedgerEntry.Insert(false);

        // [WHEN] Calculate Job Ledger Entry shortcut dimension values
        JobLedgerEntry.Get(JobLedgerEntry."Entry No.");
        JobLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Job Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(JobLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobLedgerEntryShortcutDimensionsNone_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        JobLedgerEntry: Record "Job Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are not filled with values in Job Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are not filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();

        // [GIVEN] Mock Job Ledger Entry record
        JobLedgerEntry.Init();
        RecRef.GetTable(JobLedgerEntry);
        JobLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, JobLedgerEntry.FieldNo("Entry No."));
        JobLedgerEntry."Dimension Set ID" := DimSetId;
        JobLedgerEntry.Insert(false);

        // [WHEN] Calculate Job Ledger Entry shortcut dimension values
        JobLedgerEntry.Get(JobLedgerEntry."Entry No.");
        JobLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Job Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(JobLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobLedgerEntryShortcutDimensionsSelected_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        JobLedgerEntry: Record "Job Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Three random shortcut dimensions 3-8 are filled with values in Job Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();
        SetGLSetupShortcutDimensionsSelected(DimensionValue);

        // [GIVEN] Mock Job Ledger Entry record
        JobLedgerEntry.Init();
        RecRef.GetTable(JobLedgerEntry);
        JobLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, JobLedgerEntry.FieldNo("Entry No."));
        JobLedgerEntry."Dimension Set ID" := DimSetId;
        JobLedgerEntry.Insert(false);

        // [WHEN] Calculate Job Ledger Entry shortcut dimension values
        JobLedgerEntry.Get(JobLedgerEntry."Entry No.");
        JobLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Job Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(JobLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValueEntryShortcutDimensionsAll_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        ValueEntry: Record "Value Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are filled with values in Value Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);

        // [GIVEN] Mock Value Entry record
        ValueEntry.Init();
        RecRef.GetTable(ValueEntry);
        ValueEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, ValueEntry.FieldNo("Entry No."));
        ValueEntry."Dimension Set ID" := DimSetId;
        ValueEntry.Insert(false);

        // [WHEN] Calculate Value Entry shortcut dimension values
        ValueEntry.Get(ValueEntry."Entry No.");
        ValueEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Value Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(ValueEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValueEntryShortcutDimensionsNone_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        ValueEntry: Record "Value Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are not filled with values in Value Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are not filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();

        // [GIVEN] Mock Value Entry record
        ValueEntry.Init();
        RecRef.GetTable(ValueEntry);
        ValueEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, ValueEntry.FieldNo("Entry No."));
        ValueEntry."Dimension Set ID" := DimSetId;
        ValueEntry.Insert(false);

        // [WHEN] Calculate Value Entry shortcut dimension values
        ValueEntry.Get(ValueEntry."Entry No.");
        ValueEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Value Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(ValueEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValueEntryShortcutDimensionsSelected_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        ValueEntry: Record "Value Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Three random shortcut dimensions 3-8 are filled with values in Value Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();
        SetGLSetupShortcutDimensionsSelected(DimensionValue);

        // [GIVEN] Mock Value Entry record
        ValueEntry.Init();
        RecRef.GetTable(ValueEntry);
        ValueEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, ValueEntry.FieldNo("Entry No."));
        ValueEntry."Dimension Set ID" := DimSetId;
        ValueEntry.Insert(false);

        // [WHEN] Calculate Value Entry shortcut dimension values
        ValueEntry.Get(ValueEntry."Entry No.");
        ValueEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Value Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(ValueEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorLedgerEntryShortcutDimensionsAll_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are filled with values in Vendor Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);

        // [GIVEN] Mock Vendor Ledger Entry record
        VendorLedgerEntry.Init();
        RecRef.GetTable(VendorLedgerEntry);
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Dimension Set ID" := DimSetId;
        VendorLedgerEntry.Insert(false);

        // [WHEN] Calculate Vendor Ledger Entry shortcut dimension values
        VendorLedgerEntry.Get(VendorLedgerEntry."Entry No.");
        VendorLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Vendor Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(VendorLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorLedgerEntryShortcutDimensionsNone_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are not filled with values in Vendor Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are not filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();

        // [GIVEN] Mock Vendor Ledger Entry record
        VendorLedgerEntry.Init();
        RecRef.GetTable(VendorLedgerEntry);
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Dimension Set ID" := DimSetId;
        VendorLedgerEntry.Insert(false);

        // [WHEN] Calculate Vendor Ledger Entry shortcut dimension values
        VendorLedgerEntry.Get(VendorLedgerEntry."Entry No.");
        VendorLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Vendor Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(VendorLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorLedgerEntryShortcutDimensionsSelected_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Three random shortcut dimensions 3-8 are filled with values in Vendor Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();
        SetGLSetupShortcutDimensionsSelected(DimensionValue);

        // [GIVEN] Mock Vendor Ledger Entry record
        VendorLedgerEntry.Init();
        RecRef.GetTable(VendorLedgerEntry);
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Dimension Set ID" := DimSetId;
        VendorLedgerEntry.Insert(false);

        // [WHEN] Calculate Vendor Ledger Entry shortcut dimension values
        VendorLedgerEntry.Get(VendorLedgerEntry."Entry No.");
        VendorLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Vendor Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(VendorLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmployeeLedgerEntryShortcutDimensionsAll_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are filled with values in Employee Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);

        // [GIVEN] Mock Employee Ledger Entry record
        EmployeeLedgerEntry.Init();
        RecRef.GetTable(EmployeeLedgerEntry);
        EmployeeLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, EmployeeLedgerEntry.FieldNo("Entry No."));
        EmployeeLedgerEntry."Dimension Set ID" := DimSetId;
        EmployeeLedgerEntry.Insert(false);

        // [WHEN] Calculate Employee Ledger Entry shortcut dimension values
        EmployeeLedgerEntry.Get(EmployeeLedgerEntry."Entry No.");
        EmployeeLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Employee Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(EmployeeLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmployeeLedgerEntryShortcutDimensionsNone_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are not filled with values in Employee Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are not filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();

        // [GIVEN] Mock Employee Ledger Entry record
        EmployeeLedgerEntry.Init();
        RecRef.GetTable(EmployeeLedgerEntry);
        EmployeeLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, EmployeeLedgerEntry.FieldNo("Entry No."));
        EmployeeLedgerEntry."Dimension Set ID" := DimSetId;
        EmployeeLedgerEntry.Insert(false);

        // [WHEN] Calculate Employee Ledger Entry shortcut dimension values
        EmployeeLedgerEntry.Get(EmployeeLedgerEntry."Entry No.");
        EmployeeLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Employee Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(EmployeeLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmployeeLedgerEntryShortcutDimensionsSelected_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Three random shortcut dimensions 3-8 are filled with values in Employee Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();
        SetGLSetupShortcutDimensionsSelected(DimensionValue);

        // [GIVEN] Mock Employee Ledger Entry record
        EmployeeLedgerEntry.Init();
        RecRef.GetTable(EmployeeLedgerEntry);
        EmployeeLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, EmployeeLedgerEntry.FieldNo("Entry No."));
        EmployeeLedgerEntry."Dimension Set ID" := DimSetId;
        EmployeeLedgerEntry.Insert(false);

        // [WHEN] Calculate Employee Ledger Entry shortcut dimension values
        EmployeeLedgerEntry.Get(EmployeeLedgerEntry."Entry No.");
        EmployeeLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Employee Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(EmployeeLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobWIPEntryShortcutDimensionsAll_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        JobWIPEntry: Record "Job WIP Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are filled with values in Job WIP Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);

        // [GIVEN] Mock Job WIP Entry record
        JobWIPEntry.Init();
        RecRef.GetTable(JobWIPEntry);
        JobWIPEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, JobWIPEntry.FieldNo("Entry No."));
        JobWIPEntry."Dimension Set ID" := DimSetId;
        JobWIPEntry.Insert(false);

        // [WHEN] Calculate Job WIP Entry shortcut dimension values
        JobWIPEntry.Get(JobWIPEntry."Entry No.");
        JobWIPEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Job WIP Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(JobWIPEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobWIPEntryShortcutDimensionsNone_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        JobWIPEntry: Record "Job WIP Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are not filled with values in Job WIP Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are not filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();

        // [GIVEN] Mock Job WIP Entry record
        JobWIPEntry.Init();
        RecRef.GetTable(JobWIPEntry);
        JobWIPEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, JobWIPEntry.FieldNo("Entry No."));
        JobWIPEntry."Dimension Set ID" := DimSetId;
        JobWIPEntry.Insert(false);

        // [WHEN] Calculate Job WIP Entry shortcut dimension values
        JobWIPEntry.Get(JobWIPEntry."Entry No.");
        JobWIPEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Job WIP Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(JobWIPEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobWIPEntryShortcutDimensionsSelected_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        JobWIPEntry: Record "Job WIP Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Three random shortcut dimensions 3-8 are filled with values in Job WIP Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();
        SetGLSetupShortcutDimensionsSelected(DimensionValue);

        // [GIVEN] Mock Job WIP Entry record
        JobWIPEntry.Init();
        RecRef.GetTable(JobWIPEntry);
        JobWIPEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, JobWIPEntry.FieldNo("Entry No."));
        JobWIPEntry."Dimension Set ID" := DimSetId;
        JobWIPEntry.Insert(false);

        // [WHEN] Calculate Job WIP Entry shortcut dimension values
        JobWIPEntry.Get(JobWIPEntry."Entry No.");
        JobWIPEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Job WIP Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(JobWIPEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CapacityLedgerEntryShortcutDimensionsAll_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are filled with values in Capacity Ledge rEntry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);

        // [GIVEN] Mock Capacity Ledge rEntry record
        CapacityLedgerEntry.Init();
        RecRef.GetTable(CapacityLedgerEntry);
        CapacityLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, CapacityLedgerEntry.FieldNo("Entry No."));
        CapacityLedgerEntry."Dimension Set ID" := DimSetId;
        CapacityLedgerEntry.Insert(false);

        // [WHEN] Calculate Capacity Ledge rEntry shortcut dimension values
        CapacityLedgerEntry.Get(CapacityLedgerEntry."Entry No.");
        CapacityLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Capacity Ledge rEntry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(CapacityLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CapacityLedgerEntryShortcutDimensionsNone_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are not filled with values in Capacity Ledge rEntry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are not filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();

        // [GIVEN] Mock Capacity Ledge rEntry record
        CapacityLedgerEntry.Init();
        RecRef.GetTable(CapacityLedgerEntry);
        CapacityLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, CapacityLedgerEntry.FieldNo("Entry No."));
        CapacityLedgerEntry."Dimension Set ID" := DimSetId;
        CapacityLedgerEntry.Insert(false);

        // [WHEN] Calculate Capacity Ledge rEntry shortcut dimension values
        CapacityLedgerEntry.Get(CapacityLedgerEntry."Entry No.");
        CapacityLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Capacity Ledge rEntry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(CapacityLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CapacityLedgerEntryShortcutDimensionsSelected_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        CapacityLedgerEntry: Record "Capacity Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Three random shortcut dimensions 3-8 are filled with values in Capacity Ledge rEntry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();
        SetGLSetupShortcutDimensionsSelected(DimensionValue);

        // [GIVEN] Mock Capacity Ledge rEntry record
        CapacityLedgerEntry.Init();
        RecRef.GetTable(CapacityLedgerEntry);
        CapacityLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, CapacityLedgerEntry.FieldNo("Entry No."));
        CapacityLedgerEntry."Dimension Set ID" := DimSetId;
        CapacityLedgerEntry.Insert(false);

        // [WHEN] Calculate Capacity Ledge rEntry shortcut dimension values
        CapacityLedgerEntry.Get(CapacityLedgerEntry."Entry No.");
        CapacityLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Capacity Ledge rEntry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(CapacityLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PhysInventoryLedgerEntryShortcutDimensionsAll_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are filled with values in Phys. Inventory Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);

        // [GIVEN] Mock Phys. Inventory Ledger Entry record
        PhysInventoryLedgerEntry.Init();
        RecRef.GetTable(PhysInventoryLedgerEntry);
        PhysInventoryLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, PhysInventoryLedgerEntry.FieldNo("Entry No."));
        PhysInventoryLedgerEntry."Dimension Set ID" := DimSetId;
        PhysInventoryLedgerEntry.Insert(false);

        // [WHEN] Calculate Phys. Inventory Ledger Entry shortcut dimension values
        PhysInventoryLedgerEntry.Get(PhysInventoryLedgerEntry."Entry No.");
        PhysInventoryLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Phys. Inventory Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(PhysInventoryLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PhysInventoryLedgerEntryShortcutDimensionsNone_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are not filled with values in Phys. Inventory Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are not filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();

        // [GIVEN] Mock Phys. Inventory Ledger Entry record
        PhysInventoryLedgerEntry.Init();
        RecRef.GetTable(PhysInventoryLedgerEntry);
        PhysInventoryLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, PhysInventoryLedgerEntry.FieldNo("Entry No."));
        PhysInventoryLedgerEntry."Dimension Set ID" := DimSetId;
        PhysInventoryLedgerEntry.Insert(false);

        // [WHEN] Calculate Phys. Inventory Ledger Entry shortcut dimension values
        PhysInventoryLedgerEntry.Get(PhysInventoryLedgerEntry."Entry No.");
        PhysInventoryLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Phys. Inventory Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(PhysInventoryLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PhysInventoryLedgerEntryShortcutDimensionsSelected_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Three random shortcut dimensions 3-8 are filled with values in Phys. Inventory Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();
        SetGLSetupShortcutDimensionsSelected(DimensionValue);

        // [GIVEN] Mock Phys. Inventory Ledger Entry record
        PhysInventoryLedgerEntry.Init();
        RecRef.GetTable(PhysInventoryLedgerEntry);
        PhysInventoryLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, PhysInventoryLedgerEntry.FieldNo("Entry No."));
        PhysInventoryLedgerEntry."Dimension Set ID" := DimSetId;
        PhysInventoryLedgerEntry.Insert(false);

        // [WHEN] Calculate Phys. Inventory Ledger Entry shortcut dimension values
        PhysInventoryLedgerEntry.Get(PhysInventoryLedgerEntry."Entry No.");
        PhysInventoryLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Phys. Inventory Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(PhysInventoryLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashFlowForecastEntryShortcutDimensionsAll_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        CashFlowForecastEntry: Record "Cash Flow Forecast Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are filled with values in Cash Flow Forecast Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);

        // [GIVEN] Mock Cash Flow Forecast Entry record
        CashFlowForecastEntry.Init();
        RecRef.GetTable(CashFlowForecastEntry);
        CashFlowForecastEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, CashFlowForecastEntry.FieldNo("Entry No."));
        CashFlowForecastEntry."Dimension Set ID" := DimSetId;
        CashFlowForecastEntry.Insert(false);

        // [WHEN] Calculate Cash Flow Forecast Entry shortcut dimension values
        CashFlowForecastEntry.Get(CashFlowForecastEntry."Entry No.");
        CashFlowForecastEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Cash Flow Forecast Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(CashFlowForecastEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashFlowForecastEntryShortcutDimensionsNone_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        CashFlowForecastEntry: Record "Cash Flow Forecast Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are not filled with values in Cash Flow Forecast Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are not filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();

        // [GIVEN] Mock Cash Flow Forecast Entry record
        CashFlowForecastEntry.Init();
        RecRef.GetTable(CashFlowForecastEntry);
        CashFlowForecastEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, CashFlowForecastEntry.FieldNo("Entry No."));
        CashFlowForecastEntry."Dimension Set ID" := DimSetId;
        CashFlowForecastEntry.Insert(false);

        // [WHEN] Calculate Cash Flow Forecast Entry shortcut dimension values
        CashFlowForecastEntry.Get(CashFlowForecastEntry."Entry No.");
        CashFlowForecastEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Cash Flow Forecast Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(CashFlowForecastEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashFlowForecastEntryShortcutDimensionsSelected_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        CashFlowForecastEntry: Record "Cash Flow Forecast Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Three random shortcut dimensions 3-8 are filled with values in Cash Flow Forecast Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();
        SetGLSetupShortcutDimensionsSelected(DimensionValue);

        // [GIVEN] Mock Cash Flow Forecast Entry record
        CashFlowForecastEntry.Init();
        RecRef.GetTable(CashFlowForecastEntry);
        CashFlowForecastEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, CashFlowForecastEntry.FieldNo("Entry No."));
        CashFlowForecastEntry."Dimension Set ID" := DimSetId;
        CashFlowForecastEntry.Insert(false);

        // [WHEN] Calculate Cash Flow Forecast Entry shortcut dimension values
        CashFlowForecastEntry.Get(CashFlowForecastEntry."Entry No.");
        CashFlowForecastEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Cash Flow Forecast Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(CashFlowForecastEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResLedgerEntryShortcutDimensionsAll_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        ResLedgerEntry: Record "Res. Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are filled with values in Res. Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);

        // [GIVEN] Mock Res. Ledger Entry record
        ResLedgerEntry.Init();
        RecRef.GetTable(ResLedgerEntry);
        ResLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, ResLedgerEntry.FieldNo("Entry No."));
        ResLedgerEntry."Dimension Set ID" := DimSetId;
        ResLedgerEntry.Insert(false);

        // [WHEN] Calculate Res. Ledger Entry shortcut dimension values
        ResLedgerEntry.Get(ResLedgerEntry."Entry No.");
        ResLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Res. Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(ResLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResLedgerEntryShortcutDimensionsNone_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        ResLedgerEntry: Record "Res. Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are not filled with values in Res. Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are not filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();

        // [GIVEN] Mock Res. Ledger Entry record
        ResLedgerEntry.Init();
        RecRef.GetTable(ResLedgerEntry);
        ResLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, ResLedgerEntry.FieldNo("Entry No."));
        ResLedgerEntry."Dimension Set ID" := DimSetId;
        ResLedgerEntry.Insert(false);

        // [WHEN] Calculate Res. Ledger Entry shortcut dimension values
        ResLedgerEntry.Get(ResLedgerEntry."Entry No.");
        ResLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Res. Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(ResLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResLedgerEntryShortcutDimensionsSelected_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        ResLedgerEntry: Record "Res. Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Three random shortcut dimensions 3-8 are filled with values in Res. Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();
        SetGLSetupShortcutDimensionsSelected(DimensionValue);

        // [GIVEN] Mock Res. Ledger Entry record
        ResLedgerEntry.Init();
        RecRef.GetTable(ResLedgerEntry);
        ResLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, ResLedgerEntry.FieldNo("Entry No."));
        ResLedgerEntry."Dimension Set ID" := DimSetId;
        ResLedgerEntry.Insert(false);

        // [WHEN] Calculate Res. Ledger Entry shortcut dimension values
        ResLedgerEntry.Get(ResLedgerEntry."Entry No.");
        ResLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Res. Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(ResLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobWIPGLEntryShortcutDimensionsAll_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        JobWIPGLEntry: Record "Job WIP G/L Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are filled with values in Job WIP G/L Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);

        // [GIVEN] Mock Job WIP G/L Entry record
        JobWIPGLEntry.Init();
        RecRef.GetTable(JobWIPGLEntry);
        JobWIPGLEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, JobWIPGLEntry.FieldNo("Entry No."));
        JobWIPGLEntry."Dimension Set ID" := DimSetId;
        JobWIPGLEntry.Insert(false);

        // [WHEN] Calculate Job WIP G/L Entry shortcut dimension values
        JobWIPGLEntry.Get(JobWIPGLEntry."Entry No.");
        JobWIPGLEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Job WIP G/L Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(JobWIPGLEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobWIPGLEntryShortcutDimensionsNone_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        JobWIPGLEntry: Record "Job WIP G/L Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are not filled with values in Job WIP G/L Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are not filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();

        // [GIVEN] Mock Job WIP G/L Entry record
        JobWIPGLEntry.Init();
        RecRef.GetTable(JobWIPGLEntry);
        JobWIPGLEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, JobWIPGLEntry.FieldNo("Entry No."));
        JobWIPGLEntry."Dimension Set ID" := DimSetId;
        JobWIPGLEntry.Insert(false);

        // [WHEN] Calculate Job WIP G/L Entry shortcut dimension values
        JobWIPGLEntry.Get(JobWIPGLEntry."Entry No.");
        JobWIPGLEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Job WIP G/L Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(JobWIPGLEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobWIPGLEntryShortcutDimensionsSelected_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        JobWIPGLEntry: Record "Job WIP G/L Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Three random shortcut dimensions 3-8 are filled with values in Job WIP G/L Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();
        SetGLSetupShortcutDimensionsSelected(DimensionValue);

        // [GIVEN] Mock Job WIP G/L Entry record
        JobWIPGLEntry.Init();
        RecRef.GetTable(JobWIPGLEntry);
        JobWIPGLEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, JobWIPGLEntry.FieldNo("Entry No."));
        JobWIPGLEntry."Dimension Set ID" := DimSetId;
        JobWIPGLEntry.Insert(false);

        // [WHEN] Calculate Job WIP G/L Entry shortcut dimension values
        JobWIPGLEntry.Get(JobWIPGLEntry."Entry No.");
        JobWIPGLEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Job WIP G/L Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(JobWIPGLEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLedgerEntryShortcutDimensionsAll_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        ServiceLedgerEntry: Record "Service Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are filled with values in Service Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);

        // [GIVEN] Mock Service Ledger Entry record
        ServiceLedgerEntry.Init();
        RecRef.GetTable(ServiceLedgerEntry);
        ServiceLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, ServiceLedgerEntry.FieldNo("Entry No."));
        ServiceLedgerEntry."Dimension Set ID" := DimSetId;
        ServiceLedgerEntry.Insert(false);

        // [WHEN] Calculate Service Ledger Entry shortcut dimension values
        ServiceLedgerEntry.Get(ServiceLedgerEntry."Entry No.");
        ServiceLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Service Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(ServiceLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLedgerEntryShortcutDimensionsNone_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        ServiceLedgerEntry: Record "Service Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are not filled with values in Service Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are not filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();

        // [GIVEN] Mock Service Ledger Entry record
        ServiceLedgerEntry.Init();
        RecRef.GetTable(ServiceLedgerEntry);
        ServiceLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, ServiceLedgerEntry.FieldNo("Entry No."));
        ServiceLedgerEntry."Dimension Set ID" := DimSetId;
        ServiceLedgerEntry.Insert(false);

        // [WHEN] Calculate Service Ledger Entry shortcut dimension values
        ServiceLedgerEntry.Get(ServiceLedgerEntry."Entry No.");
        ServiceLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Service Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(ServiceLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLedgerEntryShortcutDimensionsSelected_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        ServiceLedgerEntry: Record "Service Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Three random shortcut dimensions 3-8 are filled with values in Service Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();
        SetGLSetupShortcutDimensionsSelected(DimensionValue);

        // [GIVEN] Mock Service Ledger Entry record
        ServiceLedgerEntry.Init();
        RecRef.GetTable(ServiceLedgerEntry);
        ServiceLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, ServiceLedgerEntry.FieldNo("Entry No."));
        ServiceLedgerEntry."Dimension Set ID" := DimSetId;
        ServiceLedgerEntry.Insert(false);

        // [WHEN] Calculate Service Ledger Entry shortcut dimension values
        ServiceLedgerEntry.Get(ServiceLedgerEntry."Entry No.");
        ServiceLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Service Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(ServiceLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MaintenanceLedgerEntryShortcutDimensionsAll_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are filled with values in Maintenance Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);

        // [GIVEN] Mock Maintenance Ledger Entry record
        MaintenanceLedgerEntry.Init();
        RecRef.GetTable(MaintenanceLedgerEntry);
        MaintenanceLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, MaintenanceLedgerEntry.FieldNo("Entry No."));
        MaintenanceLedgerEntry."Dimension Set ID" := DimSetId;
        MaintenanceLedgerEntry.Insert(false);

        // [WHEN] Calculate Maintenance Ledger Entry shortcut dimension values
        MaintenanceLedgerEntry.Get(MaintenanceLedgerEntry."Entry No.");
        MaintenanceLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Maintenance Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(MaintenanceLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MaintenanceLedgerEntryShortcutDimensionsNone_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are not filled with values in Maintenance Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are not filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();

        // [GIVEN] Mock Maintenance Ledger Entry record
        MaintenanceLedgerEntry.Init();
        RecRef.GetTable(MaintenanceLedgerEntry);
        MaintenanceLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, MaintenanceLedgerEntry.FieldNo("Entry No."));
        MaintenanceLedgerEntry."Dimension Set ID" := DimSetId;
        MaintenanceLedgerEntry.Insert(false);

        // [WHEN] Calculate Maintenance Ledger Entry shortcut dimension values
        MaintenanceLedgerEntry.Get(MaintenanceLedgerEntry."Entry No.");
        MaintenanceLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Maintenance Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(MaintenanceLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MaintenanceLedgerEntryShortcutDimensionsSelected_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        MaintenanceLedgerEntry: Record "Maintenance Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Three random shortcut dimensions 3-8 are filled with values in Maintenance Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();
        SetGLSetupShortcutDimensionsSelected(DimensionValue);

        // [GIVEN] Mock Maintenance Ledger Entry record
        MaintenanceLedgerEntry.Init();
        RecRef.GetTable(MaintenanceLedgerEntry);
        MaintenanceLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, MaintenanceLedgerEntry.FieldNo("Entry No."));
        MaintenanceLedgerEntry."Dimension Set ID" := DimSetId;
        MaintenanceLedgerEntry.Insert(false);

        // [WHEN] Calculate Maintenance Ledger Entry shortcut dimension values
        MaintenanceLedgerEntry.Get(MaintenanceLedgerEntry."Entry No.");
        MaintenanceLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Maintenance Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(MaintenanceLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarrantyLedgerEntryShortcutDimensionsAll_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        WarrantyLedgerEntry: Record "Warranty Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are filled with values in Warranty Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);

        // [GIVEN] Mock Warranty Ledger Entry record
        WarrantyLedgerEntry.Init();
        RecRef.GetTable(WarrantyLedgerEntry);
        WarrantyLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, WarrantyLedgerEntry.FieldNo("Entry No."));
        WarrantyLedgerEntry."Dimension Set ID" := DimSetId;
        WarrantyLedgerEntry.Insert(false);

        // [WHEN] Calculate Warranty Ledger Entry shortcut dimension values
        WarrantyLedgerEntry.Get(WarrantyLedgerEntry."Entry No.");
        WarrantyLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Warranty Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(WarrantyLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarrantyLedgerEntryShortcutDimensionsNone_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        WarrantyLedgerEntry: Record "Warranty Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Shortcut dimensions 3-8 are not filled with values in Warranty Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are not filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();

        // [GIVEN] Mock Warranty Ledger Entry record
        WarrantyLedgerEntry.Init();
        RecRef.GetTable(WarrantyLedgerEntry);
        WarrantyLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, WarrantyLedgerEntry.FieldNo("Entry No."));
        WarrantyLedgerEntry."Dimension Set ID" := DimSetId;
        WarrantyLedgerEntry.Insert(false);

        // [WHEN] Calculate Warranty Ledger Entry shortcut dimension values
        WarrantyLedgerEntry.Get(WarrantyLedgerEntry."Entry No.");
        WarrantyLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Warranty Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(WarrantyLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarrantyLedgerEntryShortcutDimensionsSelected_UT()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        WarrantyLedgerEntry: Record "Warranty Ledger Entry";
        RecRef: RecordRef;
        DimSetId: Integer;
    begin
        // [SCENARIO 352854] Three random shortcut dimensions 3-8 are filled with values in Warranty Ledger Entry record when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        DimSetId := CreateDimSet(DimensionValue);
        ClearDimShortcuts();
        SetGLSetupShortcutDimensionsSelected(DimensionValue);

        // [GIVEN] Mock Warranty Ledger Entry record
        WarrantyLedgerEntry.Init();
        RecRef.GetTable(WarrantyLedgerEntry);
        WarrantyLedgerEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, WarrantyLedgerEntry.FieldNo("Entry No."));
        WarrantyLedgerEntry."Dimension Set ID" := DimSetId;
        WarrantyLedgerEntry.Insert(false);

        // [WHEN] Calculate Warranty Ledger Entry shortcut dimension values
        WarrantyLedgerEntry.Get(WarrantyLedgerEntry."Entry No.");
        WarrantyLedgerEntry.CalcFields(
            "Shortcut Dimension 3 Code", "Shortcut Dimension 4 Code", "Shortcut Dimension 5 Code",
            "Shortcut Dimension 6 Code", "Shortcut Dimension 7 Code", "Shortcut Dimension 8 Code");

        // [THEN] Warranty Ledger Entry shortcut dimension values are calculated correctly
        VerifyEntryShortcutDimensions(WarrantyLedgerEntry, DimensionValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccLedgEntrPreviewDimVisibilityAll()
    var
        BankAccLedgEntrPreview: TestPage "Bank Acc. Ledg. Entr. Preview";
    begin
        // [SCENARIO 352854] Dimensions 1-8 are visible on the "Bank Acc. Ledg. Entr. Preview" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are filled in the general ledger setup
        SetGLSetupAllDimensions();

        // [WHEN] Open "Bank Acc. Ledg. Entr. Preview" page
        BankAccLedgEntrPreview.OpenView();

        // [THEN] Dimensions 1-8 are visible
        AssertVisibility(1, BankAccLedgEntrPreview."Global Dimension 1 Code".Visible());
        AssertVisibility(2, BankAccLedgEntrPreview."Global Dimension 2 Code".Visible());
        AssertVisibility(3, BankAccLedgEntrPreview."Shortcut Dimension 3 Code".Visible());
        AssertVisibility(4, BankAccLedgEntrPreview."Shortcut Dimension 4 Code".Visible());
        AssertVisibility(5, BankAccLedgEntrPreview."Shortcut Dimension 5 Code".Visible());
        AssertVisibility(6, BankAccLedgEntrPreview."Shortcut Dimension 6 Code".Visible());
        AssertVisibility(7, BankAccLedgEntrPreview."Shortcut Dimension 7 Code".Visible());
        AssertVisibility(8, BankAccLedgEntrPreview."Shortcut Dimension 8 Code".Visible());

        BankAccLedgEntrPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccLedgEntrPreviewDimVisibilityNone()
    var
        BankAccLedgEntrPreview: TestPage "Bank Acc. Ledg. Entr. Preview";
    begin
        // [SCENARIO 352854] Dimensions 3-8 are not visible on the "Bank Acc. Ledg. Entr. Preview" page when they are empty in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are empty in the general ledger setup
        ClearDimShortcuts();

        // [WHEN] Open "Bank Acc. Ledg. Entr. Preview" page
        BankAccLedgEntrPreview.OpenView();

        // [THEN] Dimensions 3-8 are not visible
        Assert.IsFalse(BankAccLedgEntrPreview."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code should not be visible');
        Assert.IsFalse(BankAccLedgEntrPreview."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code should not be visible');
        Assert.IsFalse(BankAccLedgEntrPreview."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code should not be visible');
        Assert.IsFalse(BankAccLedgEntrPreview."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code should not be visible');
        Assert.IsFalse(BankAccLedgEntrPreview."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code should not be visible');
        Assert.IsFalse(BankAccLedgEntrPreview."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code should not be visible');

        BankAccLedgEntrPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccLedgEntrPreviewDimVisibilitySelected()
    var
        BankAccLedgEntrPreview: TestPage "Bank Acc. Ledg. Entr. Preview";
        DimShortcuts: array[6] of Boolean;
    begin
        // [SCENARIO 352854] Three random dimensions from 3-8 range are visible on the "Bank Acc. Ledg. Entr. Preview" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random dimensions are filled in the general ledger setup
        ClearDimShortcuts();
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        AssignGLSetupShortcuts(DimShortcuts);

        // [WHEN] Open "Bank Acc. Ledg. Entr. Preview" page
        BankAccLedgEntrPreview.OpenView();

        // [THEN] Three random dimensions are visible
        Assert.AreEqual(DimShortcuts[1], BankAccLedgEntrPreview."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[2], BankAccLedgEntrPreview."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[3], BankAccLedgEntrPreview."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[4], BankAccLedgEntrPreview."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[5], BankAccLedgEntrPreview."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[6], BankAccLedgEntrPreview."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code has wrong visibility');

        BankAccLedgEntrPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccountLedgerEntriesDimVisibilityAll()
    var
        BankAccountLedgerEntries: TestPage "Bank Account Ledger Entries";
    begin
        // [SCENARIO 352854] Dimensions 1-8 are visible on the "Bank Account Ledger Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are filled in the general ledger setup
        SetGLSetupAllDimensions();

        // [WHEN] Open "Bank Account Ledger Entries" page
        BankAccountLedgerEntries.OpenView();

        // [THEN] Dimensions 1-8 are visible
        AssertVisibility(1, BankAccountLedgerEntries."Global Dimension 1 Code".Visible());
        AssertVisibility(2, BankAccountLedgerEntries."Global Dimension 2 Code".Visible());
        AssertVisibility(3, BankAccountLedgerEntries."Shortcut Dimension 3 Code".Visible());
        AssertVisibility(4, BankAccountLedgerEntries."Shortcut Dimension 4 Code".Visible());
        AssertVisibility(5, BankAccountLedgerEntries."Shortcut Dimension 5 Code".Visible());
        AssertVisibility(6, BankAccountLedgerEntries."Shortcut Dimension 6 Code".Visible());
        AssertVisibility(7, BankAccountLedgerEntries."Shortcut Dimension 7 Code".Visible());
        AssertVisibility(8, BankAccountLedgerEntries."Shortcut Dimension 8 Code".Visible());

        BankAccountLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccountLedgerEntriesDimVisibilityNone()
    var
        BankAccountLedgerEntries: TestPage "Bank Account Ledger Entries";
    begin
        // [SCENARIO 352854] Dimensions 3-8 are not visible on the "Bank Account Ledger Entries" page when they are empty in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are empty in the general ledger setup
        ClearDimShortcuts();

        // [WHEN] Open "Bank Account Ledger Entries" page
        BankAccountLedgerEntries.OpenView();

        // [THEN] Dimensions 3-8 are not visible
        Assert.IsFalse(BankAccountLedgerEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code should not be visible');
        Assert.IsFalse(BankAccountLedgerEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code should not be visible');
        Assert.IsFalse(BankAccountLedgerEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code should not be visible');
        Assert.IsFalse(BankAccountLedgerEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code should not be visible');
        Assert.IsFalse(BankAccountLedgerEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code should not be visible');
        Assert.IsFalse(BankAccountLedgerEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code should not be visible');

        BankAccountLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BankAccountLedgerEntriesDimVisibilitySelected()
    var
        BankAccountLedgerEntries: TestPage "Bank Account Ledger Entries";
        DimShortcuts: array[6] of Boolean;
    begin
        // [SCENARIO 352854] Three random dimensions from 3-8 range are visible on the "Bank Account Ledger Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random dimensions are filled in the general ledger setup
        ClearDimShortcuts();
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        AssignGLSetupShortcuts(DimShortcuts);

        // [WHEN] Open "Bank Account Ledger Entries" page
        BankAccountLedgerEntries.OpenView();

        // [THEN] Three random dimensions are visible
        Assert.AreEqual(DimShortcuts[1], BankAccountLedgerEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[2], BankAccountLedgerEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[3], BankAccountLedgerEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[4], BankAccountLedgerEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[5], BankAccountLedgerEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[6], BankAccountLedgerEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code has wrong visibility');

        BankAccountLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CapacityLedgerEntriesDimVisibilityAll()
    var
        CapacityLedgerEntries: TestPage "Capacity Ledger Entries";
    begin
        // [SCENARIO 352854] Dimensions 1-8 are visible on the "Capacity Ledger Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are filled in the general ledger setup
        SetGLSetupAllDimensions();

        // [WHEN] Open "Capacity Ledger Entries" page
        CapacityLedgerEntries.OpenView();

        // [THEN] Dimensions 1-8 are visible
        AssertVisibility(1, CapacityLedgerEntries."Global Dimension 1 Code".Visible());
        AssertVisibility(2, CapacityLedgerEntries."Global Dimension 2 Code".Visible());
        AssertVisibility(3, CapacityLedgerEntries."Shortcut Dimension 3 Code".Visible());
        AssertVisibility(4, CapacityLedgerEntries."Shortcut Dimension 4 Code".Visible());
        AssertVisibility(5, CapacityLedgerEntries."Shortcut Dimension 5 Code".Visible());
        AssertVisibility(6, CapacityLedgerEntries."Shortcut Dimension 6 Code".Visible());
        AssertVisibility(7, CapacityLedgerEntries."Shortcut Dimension 7 Code".Visible());
        AssertVisibility(8, CapacityLedgerEntries."Shortcut Dimension 8 Code".Visible());

        CapacityLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CapacityLedgerEntriesDimVisibilityNone()
    var
        CapacityLedgerEntries: TestPage "Capacity Ledger Entries";
    begin
        // [SCENARIO 352854] Dimensions 3-8 are not visible on the "Capacity Ledger Entries" page when they are empty in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are empty in the general ledger setup
        ClearDimShortcuts();

        // [WHEN] Open "Capacity Ledger Entries" page
        CapacityLedgerEntries.OpenView();

        // [THEN] Dimensions 3-8 are not visible
        Assert.IsFalse(CapacityLedgerEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code should not be visible');
        Assert.IsFalse(CapacityLedgerEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code should not be visible');
        Assert.IsFalse(CapacityLedgerEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code should not be visible');
        Assert.IsFalse(CapacityLedgerEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code should not be visible');
        Assert.IsFalse(CapacityLedgerEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code should not be visible');
        Assert.IsFalse(CapacityLedgerEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code should not be visible');

        CapacityLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CapacityLedgerEntriesDimVisibilitySelected()
    var
        CapacityLedgerEntries: TestPage "Capacity Ledger Entries";
        DimShortcuts: array[6] of Boolean;
    begin
        // [SCENARIO 352854] Three random dimensions from 3-8 range are visible on the "Capacity Ledger Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random dimensions are filled in the general ledger setup
        ClearDimShortcuts();
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        AssignGLSetupShortcuts(DimShortcuts);

        // [WHEN] Open "Capacity Ledger Entries" page
        CapacityLedgerEntries.OpenView();

        // [THEN] Three random dimensions are visible
        Assert.AreEqual(DimShortcuts[1], CapacityLedgerEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[2], CapacityLedgerEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[3], CapacityLedgerEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[4], CapacityLedgerEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[5], CapacityLedgerEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[6], CapacityLedgerEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code has wrong visibility');

        CapacityLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashFlowForecastEntriesDimVisibilityAll()
    var
        CashFlowForecastEntries: TestPage "Cash Flow Forecast Entries";
    begin
        // [SCENARIO 352854] Dimensions 1-8 are visible on the "Cash Flow Forecast Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are filled in the general ledger setup
        SetGLSetupAllDimensions();

        // [WHEN] Open "Cash Flow Forecast Entries" page
        CashFlowForecastEntries.OpenView();

        // [THEN] Dimensions 1-8 are visible
        AssertVisibility(1, CashFlowForecastEntries."Global Dimension 1 Code".Visible());
        AssertVisibility(2, CashFlowForecastEntries."Global Dimension 2 Code".Visible());
        AssertVisibility(3, CashFlowForecastEntries."Shortcut Dimension 3 Code".Visible());
        AssertVisibility(4, CashFlowForecastEntries."Shortcut Dimension 4 Code".Visible());
        AssertVisibility(5, CashFlowForecastEntries."Shortcut Dimension 5 Code".Visible());
        AssertVisibility(6, CashFlowForecastEntries."Shortcut Dimension 6 Code".Visible());
        AssertVisibility(7, CashFlowForecastEntries."Shortcut Dimension 7 Code".Visible());
        AssertVisibility(8, CashFlowForecastEntries."Shortcut Dimension 8 Code".Visible());

        CashFlowForecastEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashFlowForecastEntriesDimVisibilityNone()
    var
        CashFlowForecastEntries: TestPage "Cash Flow Forecast Entries";
    begin
        // [SCENARIO 352854] Dimensions 3-8 are not visible on the "Cash Flow Forecast Entries" page when they are empty in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are empty in the general ledger setup
        ClearDimShortcuts();

        // [WHEN] Open "Cash Flow Forecast Entries" page
        CashFlowForecastEntries.OpenView();

        // [THEN] Dimensions 3-8 are not visible
        Assert.IsFalse(CashFlowForecastEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code should not be visible');
        Assert.IsFalse(CashFlowForecastEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code should not be visible');
        Assert.IsFalse(CashFlowForecastEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code should not be visible');
        Assert.IsFalse(CashFlowForecastEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code should not be visible');
        Assert.IsFalse(CashFlowForecastEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code should not be visible');
        Assert.IsFalse(CashFlowForecastEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code should not be visible');

        CashFlowForecastEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CashFlowForecastEntriesDimVisibilitySelected()
    var
        CashFlowForecastEntries: TestPage "Cash Flow Forecast Entries";
        DimShortcuts: array[6] of Boolean;
    begin
        // [SCENARIO 352854] Three random dimensions from 3-8 range are visible on the "Cash Flow Forecast Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random dimensions are filled in the general ledger setup
        ClearDimShortcuts();
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        AssignGLSetupShortcuts(DimShortcuts);

        // [WHEN] Open "Cash Flow Forecast Entries" page
        CashFlowForecastEntries.OpenView();

        // [THEN] Three random dimensions are visible
        Assert.AreEqual(DimShortcuts[1], CashFlowForecastEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[2], CashFlowForecastEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[3], CashFlowForecastEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[4], CashFlowForecastEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[5], CashFlowForecastEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[6], CashFlowForecastEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code has wrong visibility');

        CashFlowForecastEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustLedgEntriesPreviewDimVisibilityAll()
    var
        CustLedgEntriesPreview: TestPage "Cust. Ledg. Entries Preview";
    begin
        // [SCENARIO 352854] Dimensions 1-8 are visible on the "Cust. Ledg. Entries Preview" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are filled in the general ledger setup
        SetGLSetupAllDimensions();

        // [WHEN] Open "Cust. Ledg. Entries Preview" page
        CustLedgEntriesPreview.OpenView();

        // [THEN] Dimensions 1-8 are visible
        AssertVisibility(1, CustLedgEntriesPreview."Global Dimension 1 Code".Visible());
        AssertVisibility(2, CustLedgEntriesPreview."Global Dimension 2 Code".Visible());
        AssertVisibility(3, CustLedgEntriesPreview."Shortcut Dimension 3 Code".Visible());
        AssertVisibility(4, CustLedgEntriesPreview."Shortcut Dimension 4 Code".Visible());
        AssertVisibility(5, CustLedgEntriesPreview."Shortcut Dimension 5 Code".Visible());
        AssertVisibility(6, CustLedgEntriesPreview."Shortcut Dimension 6 Code".Visible());
        AssertVisibility(7, CustLedgEntriesPreview."Shortcut Dimension 7 Code".Visible());
        AssertVisibility(8, CustLedgEntriesPreview."Shortcut Dimension 8 Code".Visible());

        CustLedgEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustLedgEntriesPreviewDimVisibilityNone()
    var
        CustLedgEntriesPreview: TestPage "Cust. Ledg. Entries Preview";
    begin
        // [SCENARIO 352854] Dimensions 3-8 are not visible on the "Cust. Ledg. Entries Preview" page when they are empty in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are empty in the general ledger setup
        ClearDimShortcuts();

        // [WHEN] Open "Cust. Ledg. Entries Preview" page
        CustLedgEntriesPreview.OpenView();

        // [THEN] Dimensions 3-8 are not visible
        Assert.IsFalse(CustLedgEntriesPreview."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code should not be visible');
        Assert.IsFalse(CustLedgEntriesPreview."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code should not be visible');
        Assert.IsFalse(CustLedgEntriesPreview."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code should not be visible');
        Assert.IsFalse(CustLedgEntriesPreview."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code should not be visible');
        Assert.IsFalse(CustLedgEntriesPreview."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code should not be visible');
        Assert.IsFalse(CustLedgEntriesPreview."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code should not be visible');

        CustLedgEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustLedgEntriesPreviewDimVisibilitySelected()
    var
        CustLedgEntriesPreview: TestPage "Cust. Ledg. Entries Preview";
        DimShortcuts: array[6] of Boolean;
    begin
        // [SCENARIO 352854] Three random dimensions from 3-8 range are visible on the "Cust. Ledg. Entries Preview" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random dimensions are filled in the general ledger setup
        ClearDimShortcuts();
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        AssignGLSetupShortcuts(DimShortcuts);

        // [WHEN] Open "Cust. Ledg. Entries Preview" page
        CustLedgEntriesPreview.OpenView();

        // [THEN] Three random dimensions are visible
        Assert.AreEqual(DimShortcuts[1], CustLedgEntriesPreview."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[2], CustLedgEntriesPreview."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[3], CustLedgEntriesPreview."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[4], CustLedgEntriesPreview."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[5], CustLedgEntriesPreview."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[6], CustLedgEntriesPreview."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code has wrong visibility');

        CustLedgEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerLedgerEntriesDimVisibilityAll()
    var
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
    begin
        // [SCENARIO 352854] Dimensions 1-8 are visible on the "Customer Ledger Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are filled in the general ledger setup
        SetGLSetupAllDimensions();

        // [WHEN] Open "Customer Ledger Entries" page
        CustomerLedgerEntries.OpenView();

        // [THEN] Dimensions 1-8 are visible
        AssertVisibility(1, CustomerLedgerEntries."Global Dimension 1 Code".Visible());
        AssertVisibility(2, CustomerLedgerEntries."Global Dimension 2 Code".Visible());
        AssertVisibility(3, CustomerLedgerEntries."Shortcut Dimension 3 Code".Visible());
        AssertVisibility(4, CustomerLedgerEntries."Shortcut Dimension 4 Code".Visible());
        AssertVisibility(5, CustomerLedgerEntries."Shortcut Dimension 5 Code".Visible());
        AssertVisibility(6, CustomerLedgerEntries."Shortcut Dimension 6 Code".Visible());
        AssertVisibility(7, CustomerLedgerEntries."Shortcut Dimension 7 Code".Visible());
        AssertVisibility(8, CustomerLedgerEntries."Shortcut Dimension 8 Code".Visible());

        CustomerLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerLedgerEntriesDimVisibilityNone()
    var
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
    begin
        // [SCENARIO 352854] Dimensions 3-8 are not visible on the "Customer Ledger Entries" page when they are empty in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are empty in the general ledger setup
        ClearDimShortcuts();

        // [WHEN] Open "Customer Ledger Entries" page
        CustomerLedgerEntries.OpenView();

        // [THEN] Dimensions 3-8 are not visible
        Assert.IsFalse(CustomerLedgerEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code should not be visible');
        Assert.IsFalse(CustomerLedgerEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code should not be visible');
        Assert.IsFalse(CustomerLedgerEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code should not be visible');
        Assert.IsFalse(CustomerLedgerEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code should not be visible');
        Assert.IsFalse(CustomerLedgerEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code should not be visible');
        Assert.IsFalse(CustomerLedgerEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code should not be visible');

        CustomerLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerLedgerEntriesDimVisibilitySelected()
    var
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
        DimShortcuts: array[6] of Boolean;
    begin
        // [SCENARIO 352854] Three random dimensions from 3-8 range are visible on the "Customer Ledger Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random dimensions are filled in the general ledger setup
        ClearDimShortcuts();
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        AssignGLSetupShortcuts(DimShortcuts);

        // [WHEN] Open "Customer Ledger Entries" page
        CustomerLedgerEntries.OpenView();

        // [THEN] Three random dimensions are visible
        Assert.AreEqual(DimShortcuts[1], CustomerLedgerEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[2], CustomerLedgerEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[3], CustomerLedgerEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[4], CustomerLedgerEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[5], CustomerLedgerEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[6], CustomerLedgerEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code has wrong visibility');

        CustomerLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmplLedgerEntriesPreviewDimVisibilityAll()
    var
        EmplLedgerEntriesPreview: TestPage "Empl. Ledger Entries Preview";
    begin
        // [SCENARIO 352854] Dimensions 1-8 are visible on the "Empl. Ledger Entries Preview" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are filled in the general ledger setup
        SetGLSetupAllDimensions();

        // [WHEN] Open "Empl. Ledger Entries Preview" page
        EmplLedgerEntriesPreview.OpenView();

        // [THEN] Dimensions 1-8 are visible
        AssertVisibility(3, EmplLedgerEntriesPreview."Shortcut Dimension 3 Code".Visible());
        AssertVisibility(4, EmplLedgerEntriesPreview."Shortcut Dimension 4 Code".Visible());
        AssertVisibility(5, EmplLedgerEntriesPreview."Shortcut Dimension 5 Code".Visible());
        AssertVisibility(6, EmplLedgerEntriesPreview."Shortcut Dimension 6 Code".Visible());
        AssertVisibility(7, EmplLedgerEntriesPreview."Shortcut Dimension 7 Code".Visible());
        AssertVisibility(8, EmplLedgerEntriesPreview."Shortcut Dimension 8 Code".Visible());

        EmplLedgerEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmplLedgerEntriesPreviewDimVisibilityNone()
    var
        EmplLedgerEntriesPreview: TestPage "Empl. Ledger Entries Preview";
    begin
        // [SCENARIO 352854] Dimensions 3-8 are not visible on the "Empl. Ledger Entries Preview" page when they are empty in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are empty in the general ledger setup
        ClearDimShortcuts();

        // [WHEN] Open "Empl. Ledger Entries Preview" page
        EmplLedgerEntriesPreview.OpenView();

        // [THEN] Dimensions 3-8 are not visible
        Assert.IsFalse(EmplLedgerEntriesPreview."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code should not be visible');
        Assert.IsFalse(EmplLedgerEntriesPreview."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code should not be visible');
        Assert.IsFalse(EmplLedgerEntriesPreview."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code should not be visible');
        Assert.IsFalse(EmplLedgerEntriesPreview."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code should not be visible');
        Assert.IsFalse(EmplLedgerEntriesPreview."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code should not be visible');
        Assert.IsFalse(EmplLedgerEntriesPreview."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code should not be visible');

        EmplLedgerEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmplLedgerEntriesPreviewDimVisibilitySelected()
    var
        EmplLedgerEntriesPreview: TestPage "Empl. Ledger Entries Preview";
        DimShortcuts: array[6] of Boolean;
    begin
        // [SCENARIO 352854] Three random dimensions from 3-8 range are visible on the "Empl. Ledger Entries Preview" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random dimensions are filled in the general ledger setup
        ClearDimShortcuts();
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        AssignGLSetupShortcuts(DimShortcuts);

        // [WHEN] Open "Empl. Ledger Entries Preview" page
        EmplLedgerEntriesPreview.OpenView();

        // [THEN] Three random dimensions are visible
        Assert.AreEqual(DimShortcuts[1], EmplLedgerEntriesPreview."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[2], EmplLedgerEntriesPreview."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[3], EmplLedgerEntriesPreview."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[4], EmplLedgerEntriesPreview."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[5], EmplLedgerEntriesPreview."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[6], EmplLedgerEntriesPreview."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code has wrong visibility');

        EmplLedgerEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmployeeLedgerEntriesDimVisibilityAll()
    var
        EmployeeLedgerEntries: TestPage "Employee Ledger Entries";
    begin
        // [SCENARIO 352854] Dimensions 1-8 are visible on the "EmployeeLedgerEntries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are filled in the general ledger setup
        SetGLSetupAllDimensions();

        // [WHEN] Open "EmployeeLedgerEntries" page
        EmployeeLedgerEntries.OpenView();

        // [THEN] Dimensions 1-8 are visible
        AssertVisibility(3, EmployeeLedgerEntries."Shortcut Dimension 3 Code".Visible());
        AssertVisibility(4, EmployeeLedgerEntries."Shortcut Dimension 4 Code".Visible());
        AssertVisibility(5, EmployeeLedgerEntries."Shortcut Dimension 5 Code".Visible());
        AssertVisibility(6, EmployeeLedgerEntries."Shortcut Dimension 6 Code".Visible());
        AssertVisibility(7, EmployeeLedgerEntries."Shortcut Dimension 7 Code".Visible());
        AssertVisibility(8, EmployeeLedgerEntries."Shortcut Dimension 8 Code".Visible());

        EmployeeLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmployeeLedgerEntriesDimVisibilityNone()
    var
        EmployeeLedgerEntries: TestPage "Employee Ledger Entries";
    begin
        // [SCENARIO 352854] Dimensions 3-8 are not visible on the "EmployeeLedgerEntries" page when they are empty in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are empty in the general ledger setup
        ClearDimShortcuts();

        // [WHEN] Open "EmployeeLedgerEntries" page
        EmployeeLedgerEntries.OpenView();

        // [THEN] Dimensions 3-8 are not visible
        Assert.IsFalse(EmployeeLedgerEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code should not be visible');
        Assert.IsFalse(EmployeeLedgerEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code should not be visible');
        Assert.IsFalse(EmployeeLedgerEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code should not be visible');
        Assert.IsFalse(EmployeeLedgerEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code should not be visible');
        Assert.IsFalse(EmployeeLedgerEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code should not be visible');
        Assert.IsFalse(EmployeeLedgerEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code should not be visible');

        EmployeeLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmployeeLedgerEntriesDimVisibilitySelected()
    var
        EmployeeLedgerEntries: TestPage "Employee Ledger Entries";
        DimShortcuts: array[6] of Boolean;
    begin
        // [SCENARIO 352854] Three random dimensions from 3-8 range are visible on the "EmployeeLedgerEntries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random dimensions are filled in the general ledger setup
        ClearDimShortcuts();
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        AssignGLSetupShortcuts(DimShortcuts);

        // [WHEN] Open "EmployeeLedgerEntries" page
        EmployeeLedgerEntries.OpenView();

        // [THEN] Three random dimensions are visible
        Assert.AreEqual(DimShortcuts[1], EmployeeLedgerEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[2], EmployeeLedgerEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[3], EmployeeLedgerEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[4], EmployeeLedgerEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[5], EmployeeLedgerEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[6], EmployeeLedgerEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code has wrong visibility');

        EmployeeLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAErrorLedgerEntriesDimVisibilityAll()
    var
        FAErrorLedgerEntries: TestPage "FA Error Ledger Entries";
    begin
        // [SCENARIO 352854] Dimensions 1-8 are visible on the "FA Error Ledger Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are filled in the general ledger setup
        SetGLSetupAllDimensions();

        // [WHEN] Open "FA Error Ledger Entries" page
        FAErrorLedgerEntries.OpenView();

        // [THEN] Dimensions 1-8 are visible
        AssertVisibility(1, FAErrorLedgerEntries."Global Dimension 1 Code".Visible());
        AssertVisibility(2, FAErrorLedgerEntries."Global Dimension 2 Code".Visible());
        AssertVisibility(3, FAErrorLedgerEntries."Shortcut Dimension 3 Code".Visible());
        AssertVisibility(4, FAErrorLedgerEntries."Shortcut Dimension 4 Code".Visible());
        AssertVisibility(5, FAErrorLedgerEntries."Shortcut Dimension 5 Code".Visible());
        AssertVisibility(6, FAErrorLedgerEntries."Shortcut Dimension 6 Code".Visible());
        AssertVisibility(7, FAErrorLedgerEntries."Shortcut Dimension 7 Code".Visible());
        AssertVisibility(8, FAErrorLedgerEntries."Shortcut Dimension 8 Code".Visible());

        FAErrorLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAErrorLedgerEntriesDimVisibilityNone()
    var
        FAErrorLedgerEntries: TestPage "FA Error Ledger Entries";
    begin
        // [SCENARIO 352854] Dimensions 3-8 are not visible on the "FA Error Ledger Entries" page when they are empty in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are empty in the general ledger setup
        ClearDimShortcuts();

        // [WHEN] Open "FA Error Ledger Entries" page
        FAErrorLedgerEntries.OpenView();

        // [THEN] Dimensions 3-8 are not visible
        Assert.IsFalse(FAErrorLedgerEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code should not be visible');
        Assert.IsFalse(FAErrorLedgerEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code should not be visible');
        Assert.IsFalse(FAErrorLedgerEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code should not be visible');
        Assert.IsFalse(FAErrorLedgerEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code should not be visible');
        Assert.IsFalse(FAErrorLedgerEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code should not be visible');
        Assert.IsFalse(FAErrorLedgerEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code should not be visible');

        FAErrorLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FAErrorLedgerEntriesDimVisibilitySelected()
    var
        FAErrorLedgerEntries: TestPage "FA Error Ledger Entries";
        DimShortcuts: array[6] of Boolean;
    begin
        // [SCENARIO 352854] Three random dimensions from 3-8 range are visible on the "FA Error Ledger Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random dimensions are filled in the general ledger setup
        ClearDimShortcuts();
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        AssignGLSetupShortcuts(DimShortcuts);

        // [WHEN] Open "FA Error Ledger Entries" page
        FAErrorLedgerEntries.OpenView();

        // [THEN] Three random dimensions are visible
        Assert.AreEqual(DimShortcuts[1], FAErrorLedgerEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[2], FAErrorLedgerEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[3], FAErrorLedgerEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[4], FAErrorLedgerEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[5], FAErrorLedgerEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[6], FAErrorLedgerEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code has wrong visibility');

        FAErrorLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FALedgerEntriesDimVisibilityAll()
    var
        FALedgerEntries: TestPage "FA Ledger Entries";
    begin
        // [SCENARIO 352854] Dimensions 1-8 are visible on the "FA Ledger Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are filled in the general ledger setup
        SetGLSetupAllDimensions();

        // [WHEN] Open "FA Ledger Entries" page
        FALedgerEntries.OpenView();

        // [THEN] Dimensions 1-8 are visible
        AssertVisibility(1, FALedgerEntries."Global Dimension 1 Code".Visible());
        AssertVisibility(2, FALedgerEntries."Global Dimension 2 Code".Visible());
        AssertVisibility(3, FALedgerEntries."Shortcut Dimension 3 Code".Visible());
        AssertVisibility(4, FALedgerEntries."Shortcut Dimension 4 Code".Visible());
        AssertVisibility(5, FALedgerEntries."Shortcut Dimension 5 Code".Visible());
        AssertVisibility(6, FALedgerEntries."Shortcut Dimension 6 Code".Visible());
        AssertVisibility(7, FALedgerEntries."Shortcut Dimension 7 Code".Visible());
        AssertVisibility(8, FALedgerEntries."Shortcut Dimension 8 Code".Visible());

        FALedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FALedgerEntriesDimVisibilityNone()
    var
        FALedgerEntries: TestPage "FA Ledger Entries";
    begin
        // [SCENARIO 352854] Dimensions 3-8 are not visible on the "FA Ledger Entries" page when they are empty in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are empty in the general ledger setup
        ClearDimShortcuts();

        // [WHEN] Open "FA Ledger Entries" page
        FALedgerEntries.OpenView();

        // [THEN] Dimensions 3-8 are not visible
        Assert.IsFalse(FALedgerEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code should not be visible');
        Assert.IsFalse(FALedgerEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code should not be visible');
        Assert.IsFalse(FALedgerEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code should not be visible');
        Assert.IsFalse(FALedgerEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code should not be visible');
        Assert.IsFalse(FALedgerEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code should not be visible');
        Assert.IsFalse(FALedgerEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code should not be visible');

        FALedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FALedgerEntriesDimVisibilitySelected()
    var
        FALedgerEntries: TestPage "FA Ledger Entries";
        DimShortcuts: array[6] of Boolean;
    begin
        // [SCENARIO 352854] Three random dimensions from 3-8 range are visible on the "FA Ledger Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random dimensions are filled in the general ledger setup
        ClearDimShortcuts();
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        AssignGLSetupShortcuts(DimShortcuts);

        // [WHEN] Open "FA Ledger Entries" page
        FALedgerEntries.OpenView();

        // [THEN] Three random dimensions are visible
        Assert.AreEqual(DimShortcuts[1], FALedgerEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[2], FALedgerEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[3], FALedgerEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[4], FALedgerEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[5], FALedgerEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[6], FALedgerEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code has wrong visibility');

        FALedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FALedgerEntriesPreviewDimVisibilityAll()
    var
        FALedgerEntriesPreview: TestPage "FA Ledger Entries Preview";
    begin
        // [SCENARIO 352854] Dimensions 1-8 are visible on the "FA Ledger Entries Preview" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are filled in the general ledger setup
        SetGLSetupAllDimensions();

        // [WHEN] Open "FA Ledger Entries Preview" page
        FALedgerEntriesPreview.OpenView();

        // [THEN] Dimensions 1-8 are visible
        AssertVisibility(1, FALedgerEntriesPreview."Global Dimension 1 Code".Visible());
        AssertVisibility(2, FALedgerEntriesPreview."Global Dimension 2 Code".Visible());
        AssertVisibility(3, FALedgerEntriesPreview."Shortcut Dimension 3 Code".Visible());
        AssertVisibility(4, FALedgerEntriesPreview."Shortcut Dimension 4 Code".Visible());
        AssertVisibility(5, FALedgerEntriesPreview."Shortcut Dimension 5 Code".Visible());
        AssertVisibility(6, FALedgerEntriesPreview."Shortcut Dimension 6 Code".Visible());
        AssertVisibility(7, FALedgerEntriesPreview."Shortcut Dimension 7 Code".Visible());
        AssertVisibility(8, FALedgerEntriesPreview."Shortcut Dimension 8 Code".Visible());

        FALedgerEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FALedgerEntriesPreviewDimVisibilityNone()
    var
        FALedgerEntriesPreview: TestPage "FA Ledger Entries Preview";
    begin
        // [SCENARIO 352854] Dimensions 3-8 are not visible on the "FA Ledger Entries Preview" page when they are empty in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are empty in the general ledger setup
        ClearDimShortcuts();

        // [WHEN] Open "FA Ledger Entries Preview" page
        FALedgerEntriesPreview.OpenView();

        // [THEN] Dimensions 3-8 are not visible
        Assert.IsFalse(FALedgerEntriesPreview."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code should not be visible');
        Assert.IsFalse(FALedgerEntriesPreview."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code should not be visible');
        Assert.IsFalse(FALedgerEntriesPreview."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code should not be visible');
        Assert.IsFalse(FALedgerEntriesPreview."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code should not be visible');
        Assert.IsFalse(FALedgerEntriesPreview."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code should not be visible');
        Assert.IsFalse(FALedgerEntriesPreview."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code should not be visible');

        FALedgerEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FALedgerEntriesPreviewDimVisibilitySelected()
    var
        FALedgerEntriesPreview: TestPage "FA Ledger Entries Preview";
        DimShortcuts: array[6] of Boolean;
    begin
        // [SCENARIO 352854] Three random dimensions from 3-8 range are visible on the "FA Ledger Entries Preview" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random dimensions are filled in the general ledger setup
        ClearDimShortcuts();
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        AssignGLSetupShortcuts(DimShortcuts);

        // [WHEN] Open "FA Ledger Entries Preview" page
        FALedgerEntriesPreview.OpenView();

        // [THEN] Three random dimensions are visible
        Assert.AreEqual(DimShortcuts[1], FALedgerEntriesPreview."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[2], FALedgerEntriesPreview."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[3], FALedgerEntriesPreview."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[4], FALedgerEntriesPreview."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[5], FALedgerEntriesPreview."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[6], FALedgerEntriesPreview."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code has wrong visibility');

        FALedgerEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralLedgerEntriesDimVisibilityAll()
    var
        GeneralLedgerEntries: TestPage "General Ledger Entries";
    begin
        // [SCENARIO 352854] Dimensions 1-8 are visible on the "General Ledger Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are filled in the general ledger setup
        SetGLSetupAllDimensions();

        // [WHEN] Open "General Ledger Entries" page
        GeneralLedgerEntries.OpenView();

        // [THEN] Dimensions 1-8 are visible
        AssertVisibility(1, GeneralLedgerEntries."Global Dimension 1 Code".Visible());
        AssertVisibility(2, GeneralLedgerEntries."Global Dimension 2 Code".Visible());
        AssertVisibility(3, GeneralLedgerEntries."Shortcut Dimension 3 Code".Visible());
        AssertVisibility(4, GeneralLedgerEntries."Shortcut Dimension 4 Code".Visible());
        AssertVisibility(5, GeneralLedgerEntries."Shortcut Dimension 5 Code".Visible());
        AssertVisibility(6, GeneralLedgerEntries."Shortcut Dimension 6 Code".Visible());
        AssertVisibility(7, GeneralLedgerEntries."Shortcut Dimension 7 Code".Visible());
        AssertVisibility(8, GeneralLedgerEntries."Shortcut Dimension 8 Code".Visible());

        GeneralLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralLedgerEntriesDimVisibilityNone()
    var
        GeneralLedgerEntries: TestPage "General Ledger Entries";
    begin
        // [SCENARIO 352854] Dimensions 3-8 are not visible on the "General Ledger Entries" page when they are empty in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are empty in the general ledger setup
        ClearDimShortcuts();

        // [WHEN] Open "General Ledger Entries" page
        GeneralLedgerEntries.OpenView();

        // [THEN] Dimensions 3-8 are not visible
        Assert.IsFalse(GeneralLedgerEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code should not be visible');
        Assert.IsFalse(GeneralLedgerEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code should not be visible');
        Assert.IsFalse(GeneralLedgerEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code should not be visible');
        Assert.IsFalse(GeneralLedgerEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code should not be visible');
        Assert.IsFalse(GeneralLedgerEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code should not be visible');
        Assert.IsFalse(GeneralLedgerEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code should not be visible');

        GeneralLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GeneralLedgerEntriesDimVisibilitySelected()
    var
        GeneralLedgerEntries: TestPage "General Ledger Entries";
        DimShortcuts: array[6] of Boolean;
    begin
        // [SCENARIO 352854] Three random dimensions from 3-8 range are visible on the "General Ledger Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random dimensions are filled in the general ledger setup
        ClearDimShortcuts();
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        AssignGLSetupShortcuts(DimShortcuts);

        // [WHEN] Open "General Ledger Entries" page
        GeneralLedgerEntries.OpenView();

        // [THEN] Three random dimensions are visible
        Assert.AreEqual(DimShortcuts[1], GeneralLedgerEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[2], GeneralLedgerEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[3], GeneralLedgerEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[4], GeneralLedgerEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[5], GeneralLedgerEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[6], GeneralLedgerEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code has wrong visibility');

        GeneralLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemLedgerEntriesDimVisibilityAll()
    var
        ItemLedgerEntries: TestPage "Item Ledger Entries";
    begin
        // [SCENARIO 352854] Dimensions 1-8 are visible on the "Item Ledger Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are filled in the general ledger setup
        SetGLSetupAllDimensions();

        // [WHEN] Open "Item Ledger Entries" page
        ItemLedgerEntries.OpenView();

        // [THEN] Dimensions 1-8 are visible
        AssertVisibility(1, ItemLedgerEntries."Global Dimension 1 Code".Visible());
        AssertVisibility(2, ItemLedgerEntries."Global Dimension 2 Code".Visible());
        AssertVisibility(3, ItemLedgerEntries."Shortcut Dimension 3 Code".Visible());
        AssertVisibility(4, ItemLedgerEntries."Shortcut Dimension 4 Code".Visible());
        AssertVisibility(5, ItemLedgerEntries."Shortcut Dimension 5 Code".Visible());
        AssertVisibility(6, ItemLedgerEntries."Shortcut Dimension 6 Code".Visible());
        AssertVisibility(7, ItemLedgerEntries."Shortcut Dimension 7 Code".Visible());
        AssertVisibility(8, ItemLedgerEntries."Shortcut Dimension 8 Code".Visible());

        ItemLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemLedgerEntriesDimVisibilityNone()
    var
        ItemLedgerEntries: TestPage "Item Ledger Entries";
    begin
        // [SCENARIO 352854] Dimensions 3-8 are not visible on the "Item Ledger Entries" page when they are empty in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are empty in the general ledger setup
        ClearDimShortcuts();

        // [WHEN] Open "Item Ledger Entries" page
        ItemLedgerEntries.OpenView();

        // [THEN] Dimensions 3-8 are not visible
        Assert.IsFalse(ItemLedgerEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code should not be visible');
        Assert.IsFalse(ItemLedgerEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code should not be visible');
        Assert.IsFalse(ItemLedgerEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code should not be visible');
        Assert.IsFalse(ItemLedgerEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code should not be visible');
        Assert.IsFalse(ItemLedgerEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code should not be visible');
        Assert.IsFalse(ItemLedgerEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code should not be visible');

        ItemLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemLedgerEntriesDimVisibilitySelected()
    var
        ItemLedgerEntries: TestPage "Item Ledger Entries";
        DimShortcuts: array[6] of Boolean;
    begin
        // [SCENARIO 352854] Three random dimensions from 3-8 range are visible on the "Item Ledger Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random dimensions are filled in the general ledger setup
        ClearDimShortcuts();
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        AssignGLSetupShortcuts(DimShortcuts);

        // [WHEN] Open "Item Ledger Entries" page
        ItemLedgerEntries.OpenView();

        // [THEN] Three random dimensions are visible
        Assert.AreEqual(DimShortcuts[1], ItemLedgerEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[2], ItemLedgerEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[3], ItemLedgerEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[4], ItemLedgerEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[5], ItemLedgerEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[6], ItemLedgerEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code has wrong visibility');

        ItemLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemLedgerEntriesPreviewDimVisibilityAll()
    var
        ItemLedgerEntriesPreview: TestPage "Item Ledger Entries Preview";
    begin
        // [SCENARIO 352854] Dimensions 1-8 are visible on the "Item Ledger Entries Preview" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are filled in the general ledger setup
        SetGLSetupAllDimensions();

        // [WHEN] Open "Item Ledger Entries Preview" page
        ItemLedgerEntriesPreview.OpenView();

        // [THEN] Dimensions 1-8 are visible
        AssertVisibility(1, ItemLedgerEntriesPreview."Global Dimension 1 Code".Visible());
        AssertVisibility(2, ItemLedgerEntriesPreview."Global Dimension 2 Code".Visible());
        AssertVisibility(3, ItemLedgerEntriesPreview."Shortcut Dimension 3 Code".Visible());
        AssertVisibility(4, ItemLedgerEntriesPreview."Shortcut Dimension 4 Code".Visible());
        AssertVisibility(5, ItemLedgerEntriesPreview."Shortcut Dimension 5 Code".Visible());
        AssertVisibility(6, ItemLedgerEntriesPreview."Shortcut Dimension 6 Code".Visible());
        AssertVisibility(7, ItemLedgerEntriesPreview."Shortcut Dimension 7 Code".Visible());
        AssertVisibility(8, ItemLedgerEntriesPreview."Shortcut Dimension 8 Code".Visible());

        ItemLedgerEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemLedgerEntriesPreviewDimVisibilityNone()
    var
        ItemLedgerEntriesPreview: TestPage "Item Ledger Entries Preview";
    begin
        // [SCENARIO 352854] Dimensions 3-8 are not visible on the "Item Ledger Entries Preview" page when they are empty in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are empty in the general ledger setup
        ClearDimShortcuts();

        // [WHEN] Open "Item Ledger Entries Preview" page
        ItemLedgerEntriesPreview.OpenView();

        // [THEN] Dimensions 3-8 are not visible
        Assert.IsFalse(ItemLedgerEntriesPreview."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code should not be visible');
        Assert.IsFalse(ItemLedgerEntriesPreview."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code should not be visible');
        Assert.IsFalse(ItemLedgerEntriesPreview."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code should not be visible');
        Assert.IsFalse(ItemLedgerEntriesPreview."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code should not be visible');
        Assert.IsFalse(ItemLedgerEntriesPreview."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code should not be visible');
        Assert.IsFalse(ItemLedgerEntriesPreview."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code should not be visible');

        ItemLedgerEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemLedgerEntriesPreviewDimVisibilitySelected()
    var
        ItemLedgerEntriesPreview: TestPage "Item Ledger Entries Preview";
        DimShortcuts: array[6] of Boolean;
    begin
        // [SCENARIO 352854] Three random dimensions from 3-8 range are visible on the "Item Ledger Entries Preview" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random dimensions are filled in the general ledger setup
        ClearDimShortcuts();
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        AssignGLSetupShortcuts(DimShortcuts);

        // [WHEN] Open "Item Ledger Entries Preview" page
        ItemLedgerEntriesPreview.OpenView();

        // [THEN] Three random dimensions are visible
        Assert.AreEqual(DimShortcuts[1], ItemLedgerEntriesPreview."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[2], ItemLedgerEntriesPreview."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[3], ItemLedgerEntriesPreview."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[4], ItemLedgerEntriesPreview."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[5], ItemLedgerEntriesPreview."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[6], ItemLedgerEntriesPreview."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code has wrong visibility');

        ItemLedgerEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobLedgerEntriesDimVisibilityAll()
    var
        JobLedgerEntries: TestPage "Job Ledger Entries";
    begin
        // [SCENARIO 352854] Dimensions 1-8 are visible on the "Job Ledger Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are filled in the general ledger setup
        SetGLSetupAllDimensions();

        // [WHEN] Open "Job Ledger Entries" page
        JobLedgerEntries.OpenView();

        // [THEN] Dimensions 1-8 are visible
        AssertVisibility(3, JobLedgerEntries."Shortcut Dimension 3 Code".Visible());
        AssertVisibility(4, JobLedgerEntries."Shortcut Dimension 4 Code".Visible());
        AssertVisibility(5, JobLedgerEntries."Shortcut Dimension 5 Code".Visible());
        AssertVisibility(6, JobLedgerEntries."Shortcut Dimension 6 Code".Visible());
        AssertVisibility(7, JobLedgerEntries."Shortcut Dimension 7 Code".Visible());
        AssertVisibility(8, JobLedgerEntries."Shortcut Dimension 8 Code".Visible());

        JobLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobLedgerEntriesDimVisibilityNone()
    var
        JobLedgerEntries: TestPage "Job Ledger Entries";
    begin
        // [SCENARIO 352854] Dimensions 3-8 are not visible on the "Job Ledger Entries" page when they are empty in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are empty in the general ledger setup
        ClearDimShortcuts();

        // [WHEN] Open "Job Ledger Entries" page
        JobLedgerEntries.OpenView();

        // [THEN] Dimensions 3-8 are not visible
        Assert.IsFalse(JobLedgerEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code should not be visible');
        Assert.IsFalse(JobLedgerEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code should not be visible');
        Assert.IsFalse(JobLedgerEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code should not be visible');
        Assert.IsFalse(JobLedgerEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code should not be visible');
        Assert.IsFalse(JobLedgerEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code should not be visible');
        Assert.IsFalse(JobLedgerEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code should not be visible');

        JobLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobLedgerEntriesDimVisibilitySelected()
    var
        JobLedgerEntries: TestPage "Job Ledger Entries";
        DimShortcuts: array[6] of Boolean;
    begin
        // [SCENARIO 352854] Three random dimensions from 3-8 range are visible on the "Job Ledger Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random dimensions are filled in the general ledger setup
        ClearDimShortcuts();
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        AssignGLSetupShortcuts(DimShortcuts);

        // [WHEN] Open "Job Ledger Entries" page
        JobLedgerEntries.OpenView();

        // [THEN] Three random dimensions are visible
        Assert.AreEqual(DimShortcuts[1], JobLedgerEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[2], JobLedgerEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[3], JobLedgerEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[4], JobLedgerEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[5], JobLedgerEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[6], JobLedgerEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code has wrong visibility');

        JobLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobLedgerEntriesPreviewDimVisibilityAll()
    var
        JobLedgerEntriesPreview: TestPage "Job Ledger Entries Preview";
    begin
        // [SCENARIO 352854] Dimensions 1-8 are visible on the "Job Ledger Entries Preview" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are filled in the general ledger setup
        SetGLSetupAllDimensions();

        // [WHEN] Open "Job Ledger Entries Preview" page
        JobLedgerEntriesPreview.OpenView();

        // [THEN] Dimensions 1-8 are visible
        AssertVisibility(3, JobLedgerEntriesPreview."Shortcut Dimension 3 Code".Visible());
        AssertVisibility(4, JobLedgerEntriesPreview."Shortcut Dimension 4 Code".Visible());
        AssertVisibility(5, JobLedgerEntriesPreview."Shortcut Dimension 5 Code".Visible());
        AssertVisibility(6, JobLedgerEntriesPreview."Shortcut Dimension 6 Code".Visible());
        AssertVisibility(7, JobLedgerEntriesPreview."Shortcut Dimension 7 Code".Visible());
        AssertVisibility(8, JobLedgerEntriesPreview."Shortcut Dimension 8 Code".Visible());

        JobLedgerEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobLedgerEntriesPreviewDimVisibilityNone()
    var
        JobLedgerEntriesPreview: TestPage "Job Ledger Entries Preview";
    begin
        // [SCENARIO 352854] Dimensions 3-8 are not visible on the "Job Ledger Entries Preview" page when they are empty in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are empty in the general ledger setup
        ClearDimShortcuts();

        // [WHEN] Open "Job Ledger Entries Preview" page
        JobLedgerEntriesPreview.OpenView();

        // [THEN] Dimensions 3-8 are not visible
        Assert.IsFalse(JobLedgerEntriesPreview."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code should not be visible');
        Assert.IsFalse(JobLedgerEntriesPreview."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code should not be visible');
        Assert.IsFalse(JobLedgerEntriesPreview."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code should not be visible');
        Assert.IsFalse(JobLedgerEntriesPreview."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code should not be visible');
        Assert.IsFalse(JobLedgerEntriesPreview."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code should not be visible');
        Assert.IsFalse(JobLedgerEntriesPreview."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code should not be visible');

        JobLedgerEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobLedgerEntriesPreviewDimVisibilitySelected()
    var
        JobLedgerEntriesPreview: TestPage "Job Ledger Entries Preview";
        DimShortcuts: array[6] of Boolean;
    begin
        // [SCENARIO 352854] Three random dimensions from 3-8 range are visible on the "Job Ledger Entries Preview" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random dimensions are filled in the general ledger setup
        ClearDimShortcuts();
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        AssignGLSetupShortcuts(DimShortcuts);

        // [WHEN] Open "Job Ledger Entries Preview" page
        JobLedgerEntriesPreview.OpenView();

        // [THEN] Three random dimensions are visible
        Assert.AreEqual(DimShortcuts[1], JobLedgerEntriesPreview."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[2], JobLedgerEntriesPreview."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[3], JobLedgerEntriesPreview."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[4], JobLedgerEntriesPreview."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[5], JobLedgerEntriesPreview."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[6], JobLedgerEntriesPreview."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code has wrong visibility');

        JobLedgerEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobWIPEntriesDimVisibilityAll()
    var
        JobWIPEntries: TestPage "Job WIP Entries";
    begin
        // [SCENARIO 352854] Dimensions 1-8 are visible on the "Job WIP Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are filled in the general ledger setup
        SetGLSetupAllDimensions();

        // [WHEN] Open "Job WIP Entries" page
        JobWIPEntries.OpenView();

        // [THEN] Dimensions 1-8 are visible
        AssertVisibility(1, JobWIPEntries."Global Dimension 1 Code".Visible());
        AssertVisibility(2, JobWIPEntries."Global Dimension 2 Code".Visible());
        AssertVisibility(3, JobWIPEntries."Shortcut Dimension 3 Code".Visible());
        AssertVisibility(4, JobWIPEntries."Shortcut Dimension 4 Code".Visible());
        AssertVisibility(5, JobWIPEntries."Shortcut Dimension 5 Code".Visible());
        AssertVisibility(6, JobWIPEntries."Shortcut Dimension 6 Code".Visible());
        AssertVisibility(7, JobWIPEntries."Shortcut Dimension 7 Code".Visible());
        AssertVisibility(8, JobWIPEntries."Shortcut Dimension 8 Code".Visible());

        JobWIPEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobWIPEntriesDimVisibilityNone()
    var
        JobWIPEntries: TestPage "Job WIP Entries";
    begin
        // [SCENARIO 352854] Dimensions 3-8 are not visible on the "Job WIP Entries" page when they are empty in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are empty in the general ledger setup
        ClearDimShortcuts();

        // [WHEN] Open "Job WIP Entries" page
        JobWIPEntries.OpenView();

        // [THEN] Dimensions 3-8 are not visible
        Assert.IsFalse(JobWIPEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code should not be visible');
        Assert.IsFalse(JobWIPEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code should not be visible');
        Assert.IsFalse(JobWIPEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code should not be visible');
        Assert.IsFalse(JobWIPEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code should not be visible');
        Assert.IsFalse(JobWIPEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code should not be visible');
        Assert.IsFalse(JobWIPEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code should not be visible');

        JobWIPEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobWIPEntriesDimVisibilitySelected()
    var
        JobWIPEntries: TestPage "Job WIP Entries";
        DimShortcuts: array[6] of Boolean;
    begin
        // [SCENARIO 352854] Three random dimensions from 3-8 range are visible on the "Job WIP Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random dimensions are filled in the general ledger setup
        ClearDimShortcuts();
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        AssignGLSetupShortcuts(DimShortcuts);

        // [WHEN] Open "Job WIP Entries" page
        JobWIPEntries.OpenView();

        // [THEN] Three random dimensions are visible
        Assert.AreEqual(DimShortcuts[1], JobWIPEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[2], JobWIPEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[3], JobWIPEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[4], JobWIPEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[5], JobWIPEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[6], JobWIPEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code has wrong visibility');

        JobWIPEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobWIPGLEntriesDimVisibilityAll()
    var
        JobWIPGLEntries: TestPage "Job WIP G/L Entries";
    begin
        // [SCENARIO 352854] Dimensions 1-8 are visible on the "Job WIP G/L Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are filled in the general ledger setup
        SetGLSetupAllDimensions();

        // [WHEN] Open "Job WIP G/L Entries" page
        JobWIPGLEntries.OpenView();

        // [THEN] Dimensions 1-8 are visible
        AssertVisibility(1, JobWIPGLEntries."Global Dimension 1 Code".Visible());
        AssertVisibility(2, JobWIPGLEntries."Global Dimension 2 Code".Visible());
        AssertVisibility(3, JobWIPGLEntries."Shortcut Dimension 3 Code".Visible());
        AssertVisibility(4, JobWIPGLEntries."Shortcut Dimension 4 Code".Visible());
        AssertVisibility(5, JobWIPGLEntries."Shortcut Dimension 5 Code".Visible());
        AssertVisibility(6, JobWIPGLEntries."Shortcut Dimension 6 Code".Visible());
        AssertVisibility(7, JobWIPGLEntries."Shortcut Dimension 7 Code".Visible());
        AssertVisibility(8, JobWIPGLEntries."Shortcut Dimension 8 Code".Visible());

        JobWIPGLEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobWIPGLEntriesDimVisibilityNone()
    var
        JobWIPGLEntries: TestPage "Job WIP G/L Entries";
    begin
        // [SCENARIO 352854] Dimensions 3-8 are not visible on the "Job WIP G/L Entries" page when they are empty in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are empty in the general ledger setup
        ClearDimShortcuts();

        // [WHEN] Open "Job WIP G/L Entries" page
        JobWIPGLEntries.OpenView();

        // [THEN] Dimensions 3-8 are not visible
        Assert.IsFalse(JobWIPGLEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code should not be visible');
        Assert.IsFalse(JobWIPGLEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code should not be visible');
        Assert.IsFalse(JobWIPGLEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code should not be visible');
        Assert.IsFalse(JobWIPGLEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code should not be visible');
        Assert.IsFalse(JobWIPGLEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code should not be visible');
        Assert.IsFalse(JobWIPGLEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code should not be visible');

        JobWIPGLEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobWIPGLEntriesDimVisibilitySelected()
    var
        JobWIPGLEntries: TestPage "Job WIP G/L Entries";
        DimShortcuts: array[6] of Boolean;
    begin
        // [SCENARIO 352854] Three random dimensions from 3-8 range are visible on the "Job WIP G/L Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random dimensions are filled in the general ledger setup
        ClearDimShortcuts();
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        AssignGLSetupShortcuts(DimShortcuts);

        // [WHEN] Open "Job WIP G/L Entries" page
        JobWIPGLEntries.OpenView();

        // [THEN] Three random dimensions are visible
        Assert.AreEqual(DimShortcuts[1], JobWIPGLEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[2], JobWIPGLEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[3], JobWIPGLEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[4], JobWIPGLEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[5], JobWIPGLEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[6], JobWIPGLEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code has wrong visibility');

        JobWIPGLEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MaintenanceLedgerEntriesDimVisibilityAll()
    var
        MaintenanceLedgerEntries: TestPage "Maintenance Ledger Entries";
    begin
        // [SCENARIO 352854] Dimensions 1-8 are visible on the "Maintenance Ledger Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are filled in the general ledger setup
        SetGLSetupAllDimensions();

        // [WHEN] Open "Maintenance Ledger Entries" page
        MaintenanceLedgerEntries.OpenView();

        // [THEN] Dimensions 1-8 are visible
        AssertVisibility(1, MaintenanceLedgerEntries."Global Dimension 1 Code".Visible());
        AssertVisibility(2, MaintenanceLedgerEntries."Global Dimension 2 Code".Visible());
        AssertVisibility(3, MaintenanceLedgerEntries."Shortcut Dimension 3 Code".Visible());
        AssertVisibility(4, MaintenanceLedgerEntries."Shortcut Dimension 4 Code".Visible());
        AssertVisibility(5, MaintenanceLedgerEntries."Shortcut Dimension 5 Code".Visible());
        AssertVisibility(6, MaintenanceLedgerEntries."Shortcut Dimension 6 Code".Visible());
        AssertVisibility(7, MaintenanceLedgerEntries."Shortcut Dimension 7 Code".Visible());
        AssertVisibility(8, MaintenanceLedgerEntries."Shortcut Dimension 8 Code".Visible());

        MaintenanceLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MaintenanceLedgerEntriesDimVisibilityNone()
    var
        MaintenanceLedgerEntries: TestPage "Maintenance Ledger Entries";
    begin
        // [SCENARIO 352854] Dimensions 3-8 are not visible on the "Maintenance Ledger Entries" page when they are empty in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are empty in the general ledger setup
        ClearDimShortcuts();

        // [WHEN] Open "Maintenance Ledger Entries" page
        MaintenanceLedgerEntries.OpenView();

        // [THEN] Dimensions 3-8 are not visible
        Assert.IsFalse(MaintenanceLedgerEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code should not be visible');
        Assert.IsFalse(MaintenanceLedgerEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code should not be visible');
        Assert.IsFalse(MaintenanceLedgerEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code should not be visible');
        Assert.IsFalse(MaintenanceLedgerEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code should not be visible');
        Assert.IsFalse(MaintenanceLedgerEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code should not be visible');
        Assert.IsFalse(MaintenanceLedgerEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code should not be visible');

        MaintenanceLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MaintenanceLedgerEntriesDimVisibilitySelected()
    var
        MaintenanceLedgerEntries: TestPage "Maintenance Ledger Entries";
        DimShortcuts: array[6] of Boolean;
    begin
        // [SCENARIO 352854] Three random dimensions from 3-8 range are visible on the "Maintenance Ledger Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random dimensions are filled in the general ledger setup
        ClearDimShortcuts();
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        AssignGLSetupShortcuts(DimShortcuts);

        // [WHEN] Open "Maintenance Ledger Entries" page
        MaintenanceLedgerEntries.OpenView();

        // [THEN] Three random dimensions are visible
        Assert.AreEqual(DimShortcuts[1], MaintenanceLedgerEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[2], MaintenanceLedgerEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[3], MaintenanceLedgerEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[4], MaintenanceLedgerEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[5], MaintenanceLedgerEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[6], MaintenanceLedgerEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code has wrong visibility');

        MaintenanceLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MaintLedgEntriesPreviewDimVisibilityAll()
    var
        MaintLedgEntriesPreview: TestPage "Maint. Ledg. Entries Preview";
    begin
        // [SCENARIO 352854] Dimensions 1-8 are visible on the "Maint. Ledg. Entries Preview" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are filled in the general ledger setup
        SetGLSetupAllDimensions();

        // [WHEN] Open "Maint. Ledg. Entries Preview" page
        MaintLedgEntriesPreview.OpenView();

        // [THEN] Dimensions 1-8 are visible
        AssertVisibility(1, MaintLedgEntriesPreview."Global Dimension 1 Code".Visible());
        AssertVisibility(2, MaintLedgEntriesPreview."Global Dimension 2 Code".Visible());
        AssertVisibility(3, MaintLedgEntriesPreview."Shortcut Dimension 3 Code".Visible());
        AssertVisibility(4, MaintLedgEntriesPreview."Shortcut Dimension 4 Code".Visible());
        AssertVisibility(5, MaintLedgEntriesPreview."Shortcut Dimension 5 Code".Visible());
        AssertVisibility(6, MaintLedgEntriesPreview."Shortcut Dimension 6 Code".Visible());
        AssertVisibility(7, MaintLedgEntriesPreview."Shortcut Dimension 7 Code".Visible());
        AssertVisibility(8, MaintLedgEntriesPreview."Shortcut Dimension 8 Code".Visible());

        MaintLedgEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MaintLedgEntriesPreviewDimVisibilityNone()
    var
        MaintLedgEntriesPreview: TestPage "Maint. Ledg. Entries Preview";
    begin
        // [SCENARIO 352854] Dimensions 3-8 are not visible on the "Maint. Ledg. Entries Preview" page when they are empty in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are empty in the general ledger setup
        ClearDimShortcuts();

        // [WHEN] Open "Maint. Ledg. Entries Preview" page
        MaintLedgEntriesPreview.OpenView();

        // [THEN] Dimensions 3-8 are not visible
        Assert.IsFalse(MaintLedgEntriesPreview."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code should not be visible');
        Assert.IsFalse(MaintLedgEntriesPreview."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code should not be visible');
        Assert.IsFalse(MaintLedgEntriesPreview."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code should not be visible');
        Assert.IsFalse(MaintLedgEntriesPreview."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code should not be visible');
        Assert.IsFalse(MaintLedgEntriesPreview."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code should not be visible');
        Assert.IsFalse(MaintLedgEntriesPreview."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code should not be visible');

        MaintLedgEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MaintLedgEntriesPreviewDimVisibilitySelected()
    var
        MaintLedgEntriesPreview: TestPage "Maint. Ledg. Entries Preview";
        DimShortcuts: array[6] of Boolean;
    begin
        // [SCENARIO 352854] Three random dimensions from 3-8 range are visible on the "Maint. Ledg. Entries Preview" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random dimensions are filled in the general ledger setup
        ClearDimShortcuts();
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        AssignGLSetupShortcuts(DimShortcuts);

        // [WHEN] Open "Maint. Ledg. Entries Preview" page
        MaintLedgEntriesPreview.OpenView();

        // [THEN] Three random dimensions are visible
        Assert.AreEqual(DimShortcuts[1], MaintLedgEntriesPreview."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[2], MaintLedgEntriesPreview."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[3], MaintLedgEntriesPreview."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[4], MaintLedgEntriesPreview."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[5], MaintLedgEntriesPreview."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[6], MaintLedgEntriesPreview."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code has wrong visibility');

        MaintLedgEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PhysInventoryLedgerEntriesDimVisibilityAll()
    var
        PhysInventoryLedgerEntries: TestPage "Phys. Inventory Ledger Entries";
    begin
        // [SCENARIO 352854] Dimensions 1-8 are visible on the "Phys. Inventory Ledger Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are filled in the general ledger setup
        SetGLSetupAllDimensions();

        // [WHEN] Open "Phys. Inventory Ledger Entries" page
        PhysInventoryLedgerEntries.OpenView();

        // [THEN] Dimensions 1-8 are visible
        AssertVisibility(1, PhysInventoryLedgerEntries."Global Dimension 1 Code".Visible());
        AssertVisibility(2, PhysInventoryLedgerEntries."Global Dimension 2 Code".Visible());
        AssertVisibility(3, PhysInventoryLedgerEntries."Shortcut Dimension 3 Code".Visible());
        AssertVisibility(4, PhysInventoryLedgerEntries."Shortcut Dimension 4 Code".Visible());
        AssertVisibility(5, PhysInventoryLedgerEntries."Shortcut Dimension 5 Code".Visible());
        AssertVisibility(6, PhysInventoryLedgerEntries."Shortcut Dimension 6 Code".Visible());
        AssertVisibility(7, PhysInventoryLedgerEntries."Shortcut Dimension 7 Code".Visible());
        AssertVisibility(8, PhysInventoryLedgerEntries."Shortcut Dimension 8 Code".Visible());

        PhysInventoryLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PhysInventoryLedgerEntriesDimVisibilityNone()
    var
        PhysInventoryLedgerEntries: TestPage "Phys. Inventory Ledger Entries";
    begin
        // [SCENARIO 352854] Dimensions 3-8 are not visible on the "Phys. Inventory Ledger Entries" page when they are empty in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are empty in the general ledger setup
        ClearDimShortcuts();

        // [WHEN] Open "Phys. Inventory Ledger Entries" page
        PhysInventoryLedgerEntries.OpenView();

        // [THEN] Dimensions 3-8 are not visible
        Assert.IsFalse(PhysInventoryLedgerEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code should not be visible');
        Assert.IsFalse(PhysInventoryLedgerEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code should not be visible');
        Assert.IsFalse(PhysInventoryLedgerEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code should not be visible');
        Assert.IsFalse(PhysInventoryLedgerEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code should not be visible');
        Assert.IsFalse(PhysInventoryLedgerEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code should not be visible');
        Assert.IsFalse(PhysInventoryLedgerEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code should not be visible');

        PhysInventoryLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PhysInventoryLedgerEntriesDimVisibilitySelected()
    var
        PhysInventoryLedgerEntries: TestPage "Phys. Inventory Ledger Entries";
        DimShortcuts: array[6] of Boolean;
    begin
        // [SCENARIO 352854] Three random dimensions from 3-8 range are visible on the "Phys. Inventory Ledger Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random dimensions are filled in the general ledger setup
        ClearDimShortcuts();
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        AssignGLSetupShortcuts(DimShortcuts);

        // [WHEN] Open "Phys. Inventory Ledger Entries" page
        PhysInventoryLedgerEntries.OpenView();

        // [THEN] Three random dimensions are visible
        Assert.AreEqual(DimShortcuts[1], PhysInventoryLedgerEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[2], PhysInventoryLedgerEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[3], PhysInventoryLedgerEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[4], PhysInventoryLedgerEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[5], PhysInventoryLedgerEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[6], PhysInventoryLedgerEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code has wrong visibility');

        PhysInventoryLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourceLedgEntriesPreviewDimVisibilityAll()
    var
        ResourceLedgEntriesPreview: TestPage "Resource Ledg. Entries Preview";
    begin
        // [SCENARIO 352854] Dimensions 1-8 are visible on the "Resource Ledg. Entries Preview" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are filled in the general ledger setup
        SetGLSetupAllDimensions();

        // [WHEN] Open "Resource Ledg. Entries Preview" page
        ResourceLedgEntriesPreview.OpenView();

        // [THEN] Dimensions 1-8 are visible
        AssertVisibility(1, ResourceLedgEntriesPreview."Global Dimension 1 Code".Visible());
        AssertVisibility(2, ResourceLedgEntriesPreview."Global Dimension 2 Code".Visible());
        AssertVisibility(3, ResourceLedgEntriesPreview."Shortcut Dimension 3 Code".Visible());
        AssertVisibility(4, ResourceLedgEntriesPreview."Shortcut Dimension 4 Code".Visible());
        AssertVisibility(5, ResourceLedgEntriesPreview."Shortcut Dimension 5 Code".Visible());
        AssertVisibility(6, ResourceLedgEntriesPreview."Shortcut Dimension 6 Code".Visible());
        AssertVisibility(7, ResourceLedgEntriesPreview."Shortcut Dimension 7 Code".Visible());
        AssertVisibility(8, ResourceLedgEntriesPreview."Shortcut Dimension 8 Code".Visible());

        ResourceLedgEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourceLedgEntriesPreviewDimVisibilityNone()
    var
        ResourceLedgEntriesPreview: TestPage "Resource Ledg. Entries Preview";
    begin
        // [SCENARIO 352854] Dimensions 3-8 are not visible on the "Resource Ledg. Entries Preview" page when they are empty in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are empty in the general ledger setup
        ClearDimShortcuts();

        // [WHEN] Open "Resource Ledg. Entries Preview" page
        ResourceLedgEntriesPreview.OpenView();

        // [THEN] Dimensions 3-8 are not visible
        Assert.IsFalse(ResourceLedgEntriesPreview."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code should not be visible');
        Assert.IsFalse(ResourceLedgEntriesPreview."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code should not be visible');
        Assert.IsFalse(ResourceLedgEntriesPreview."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code should not be visible');
        Assert.IsFalse(ResourceLedgEntriesPreview."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code should not be visible');
        Assert.IsFalse(ResourceLedgEntriesPreview."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code should not be visible');
        Assert.IsFalse(ResourceLedgEntriesPreview."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code should not be visible');

        ResourceLedgEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourceLedgEntriesPreviewDimVisibilitySelected()
    var
        ResourceLedgEntriesPreview: TestPage "Resource Ledg. Entries Preview";
        DimShortcuts: array[6] of Boolean;
    begin
        // [SCENARIO 352854] Three random dimensions from 3-8 range are visible on the "Resource Ledg. Entries Preview" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random dimensions are filled in the general ledger setup
        ClearDimShortcuts();
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        AssignGLSetupShortcuts(DimShortcuts);

        // [WHEN] Open "Resource Ledg. Entries Preview" page
        ResourceLedgEntriesPreview.OpenView();

        // [THEN] Three random dimensions are visible
        Assert.AreEqual(DimShortcuts[1], ResourceLedgEntriesPreview."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[2], ResourceLedgEntriesPreview."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[3], ResourceLedgEntriesPreview."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[4], ResourceLedgEntriesPreview."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[5], ResourceLedgEntriesPreview."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[6], ResourceLedgEntriesPreview."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code has wrong visibility');

        ResourceLedgEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourceLedgerEntriesDimVisibilityAll()
    var
        ResourceLedgerEntries: TestPage "Resource Ledger Entries";
    begin
        // [SCENARIO 352854] Dimensions 1-8 are visible on the "Resource Ledger Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are filled in the general ledger setup
        SetGLSetupAllDimensions();

        // [WHEN] Open "Resource Ledger Entries" page
        ResourceLedgerEntries.OpenView();

        // [THEN] Dimensions 1-8 are visible
        AssertVisibility(1, ResourceLedgerEntries."Global Dimension 1 Code".Visible());
        AssertVisibility(2, ResourceLedgerEntries."Global Dimension 2 Code".Visible());
        AssertVisibility(3, ResourceLedgerEntries."Shortcut Dimension 3 Code".Visible());
        AssertVisibility(4, ResourceLedgerEntries."Shortcut Dimension 4 Code".Visible());
        AssertVisibility(5, ResourceLedgerEntries."Shortcut Dimension 5 Code".Visible());
        AssertVisibility(6, ResourceLedgerEntries."Shortcut Dimension 6 Code".Visible());
        AssertVisibility(7, ResourceLedgerEntries."Shortcut Dimension 7 Code".Visible());
        AssertVisibility(8, ResourceLedgerEntries."Shortcut Dimension 8 Code".Visible());

        ResourceLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourceLedgerEntriesDimVisibilityNone()
    var
        ResourceLedgerEntries: TestPage "Resource Ledger Entries";
    begin
        // [SCENARIO 352854] Dimensions 3-8 are not visible on the "Resource Ledger Entries" page when they are empty in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are empty in the general ledger setup
        ClearDimShortcuts();

        // [WHEN] Open "Resource Ledger Entries" page
        ResourceLedgerEntries.OpenView();

        // [THEN] Dimensions 3-8 are not visible
        Assert.IsFalse(ResourceLedgerEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code should not be visible');
        Assert.IsFalse(ResourceLedgerEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code should not be visible');
        Assert.IsFalse(ResourceLedgerEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code should not be visible');
        Assert.IsFalse(ResourceLedgerEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code should not be visible');
        Assert.IsFalse(ResourceLedgerEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code should not be visible');
        Assert.IsFalse(ResourceLedgerEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code should not be visible');

        ResourceLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResourceLedgerEntriesDimVisibilitySelected()
    var
        ResourceLedgerEntries: TestPage "Resource Ledger Entries";
        DimShortcuts: array[6] of Boolean;
    begin
        // [SCENARIO 352854] Three random dimensions from 3-8 range are visible on the "Resource Ledger Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random dimensions are filled in the general ledger setup
        ClearDimShortcuts();
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        AssignGLSetupShortcuts(DimShortcuts);

        // [WHEN] Open "Resource Ledger Entries" page
        ResourceLedgerEntries.OpenView();

        // [THEN] Three random dimensions are visible
        Assert.AreEqual(DimShortcuts[1], ResourceLedgerEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[2], ResourceLedgerEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[3], ResourceLedgerEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[4], ResourceLedgerEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[5], ResourceLedgerEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[6], ResourceLedgerEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code has wrong visibility');

        ResourceLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLedgerEntriesDimVisibilityAll()
    var
        ServiceLedgerEntries: TestPage "Service Ledger Entries";
    begin
        // [SCENARIO 352854] Dimensions 1-8 are visible on the "Service Ledger Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are filled in the general ledger setup
        SetGLSetupAllDimensions();

        // [WHEN] Open "Service Ledger Entries" page
        ServiceLedgerEntries.OpenView();

        // [THEN] Dimensions 1-8 are visible
        AssertVisibility(1, ServiceLedgerEntries."Global Dimension 1 Code".Visible());
        AssertVisibility(2, ServiceLedgerEntries."Global Dimension 2 Code".Visible());
        AssertVisibility(3, ServiceLedgerEntries."Shortcut Dimension 3 Code".Visible());
        AssertVisibility(4, ServiceLedgerEntries."Shortcut Dimension 4 Code".Visible());
        AssertVisibility(5, ServiceLedgerEntries."Shortcut Dimension 5 Code".Visible());
        AssertVisibility(6, ServiceLedgerEntries."Shortcut Dimension 6 Code".Visible());
        AssertVisibility(7, ServiceLedgerEntries."Shortcut Dimension 7 Code".Visible());
        AssertVisibility(8, ServiceLedgerEntries."Shortcut Dimension 8 Code".Visible());

        ServiceLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLedgerEntriesDimVisibilityNone()
    var
        ServiceLedgerEntries: TestPage "Service Ledger Entries";
    begin
        // [SCENARIO 352854] Dimensions 3-8 are not visible on the "Service Ledger Entries" page when they are empty in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are empty in the general ledger setup
        ClearDimShortcuts();

        // [WHEN] Open "Service Ledger Entries" page
        ServiceLedgerEntries.OpenView();

        // [THEN] Dimensions 3-8 are not visible
        Assert.IsFalse(ServiceLedgerEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code should not be visible');
        Assert.IsFalse(ServiceLedgerEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code should not be visible');
        Assert.IsFalse(ServiceLedgerEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code should not be visible');
        Assert.IsFalse(ServiceLedgerEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code should not be visible');
        Assert.IsFalse(ServiceLedgerEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code should not be visible');
        Assert.IsFalse(ServiceLedgerEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code should not be visible');

        ServiceLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLedgerEntriesDimVisibilitySelected()
    var
        ServiceLedgerEntries: TestPage "Service Ledger Entries";
        DimShortcuts: array[6] of Boolean;
    begin
        // [SCENARIO 352854] Three random dimensions from 3-8 range are visible on the "Service Ledger Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random dimensions are filled in the general ledger setup
        ClearDimShortcuts();
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        AssignGLSetupShortcuts(DimShortcuts);

        // [WHEN] Open "Service Ledger Entries" page
        ServiceLedgerEntries.OpenView();

        // [THEN] Three random dimensions are visible
        Assert.AreEqual(DimShortcuts[1], ServiceLedgerEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[2], ServiceLedgerEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[3], ServiceLedgerEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[4], ServiceLedgerEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[5], ServiceLedgerEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[6], ServiceLedgerEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code has wrong visibility');

        ServiceLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLedgerEntriesPreviewDimVisibilityAll()
    var
        ServiceLedgerEntriesPreview: TestPage "Service Ledger Entries Preview";
    begin
        // [SCENARIO 352854] Dimensions 1-8 are visible on the "Service Ledger Entries Preview" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are filled in the general ledger setup
        SetGLSetupAllDimensions();

        // [WHEN] Open "Service Ledger Entries Preview" page
        ServiceLedgerEntriesPreview.OpenView();

        // [THEN] Dimensions 1-8 are visible
        AssertVisibility(1, ServiceLedgerEntriesPreview."Global Dimension 1 Code".Visible());
        AssertVisibility(2, ServiceLedgerEntriesPreview."Global Dimension 2 Code".Visible());
        AssertVisibility(3, ServiceLedgerEntriesPreview."Shortcut Dimension 3 Code".Visible());
        AssertVisibility(4, ServiceLedgerEntriesPreview."Shortcut Dimension 4 Code".Visible());
        AssertVisibility(5, ServiceLedgerEntriesPreview."Shortcut Dimension 5 Code".Visible());
        AssertVisibility(6, ServiceLedgerEntriesPreview."Shortcut Dimension 6 Code".Visible());
        AssertVisibility(7, ServiceLedgerEntriesPreview."Shortcut Dimension 7 Code".Visible());
        AssertVisibility(8, ServiceLedgerEntriesPreview."Shortcut Dimension 8 Code".Visible());

        ServiceLedgerEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLedgerEntriesPreviewDimVisibilityNone()
    var
        ServiceLedgerEntriesPreview: TestPage "Service Ledger Entries Preview";
    begin
        // [SCENARIO 352854] Dimensions 3-8 are not visible on the "Service Ledger Entries Preview" page when they are empty in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are empty in the general ledger setup
        ClearDimShortcuts();

        // [WHEN] Open "Service Ledger Entries Preview" page
        ServiceLedgerEntriesPreview.OpenView();

        // [THEN] Dimensions 3-8 are not visible
        Assert.IsFalse(ServiceLedgerEntriesPreview."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code should not be visible');
        Assert.IsFalse(ServiceLedgerEntriesPreview."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code should not be visible');
        Assert.IsFalse(ServiceLedgerEntriesPreview."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code should not be visible');
        Assert.IsFalse(ServiceLedgerEntriesPreview."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code should not be visible');
        Assert.IsFalse(ServiceLedgerEntriesPreview."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code should not be visible');
        Assert.IsFalse(ServiceLedgerEntriesPreview."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code should not be visible');

        ServiceLedgerEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLedgerEntriesPreviewDimVisibilitySelected()
    var
        ServiceLedgerEntriesPreview: TestPage "Service Ledger Entries Preview";
        DimShortcuts: array[6] of Boolean;
    begin
        // [SCENARIO 352854] Three random dimensions from 3-8 range are visible on the "Service Ledger Entries Preview" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random dimensions are filled in the general ledger setup
        ClearDimShortcuts();
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        AssignGLSetupShortcuts(DimShortcuts);

        // [WHEN] Open "Service Ledger Entries Preview" page
        ServiceLedgerEntriesPreview.OpenView();

        // [THEN] Three random dimensions are visible
        Assert.AreEqual(DimShortcuts[1], ServiceLedgerEntriesPreview."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[2], ServiceLedgerEntriesPreview."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[3], ServiceLedgerEntriesPreview."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[4], ServiceLedgerEntriesPreview."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[5], ServiceLedgerEntriesPreview."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[6], ServiceLedgerEntriesPreview."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code has wrong visibility');

        ServiceLedgerEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValueEntriesDimVisibilityAll()
    var
        ValueEntries: TestPage "Value Entries";
    begin
        // [SCENARIO 352854] Dimensions 1-8 are visible on the "Value Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are filled in the general ledger setup
        SetGLSetupAllDimensions();

        // [WHEN] Open "Value Entries" page
        ValueEntries.OpenView();

        // [THEN] Dimensions 1-8 are visible
        AssertVisibility(1, ValueEntries."Global Dimension 1 Code".Visible());
        AssertVisibility(2, ValueEntries."Global Dimension 2 Code".Visible());
        AssertVisibility(3, ValueEntries."Shortcut Dimension 3 Code".Visible());
        AssertVisibility(4, ValueEntries."Shortcut Dimension 4 Code".Visible());
        AssertVisibility(5, ValueEntries."Shortcut Dimension 5 Code".Visible());
        AssertVisibility(6, ValueEntries."Shortcut Dimension 6 Code".Visible());
        AssertVisibility(7, ValueEntries."Shortcut Dimension 7 Code".Visible());
        AssertVisibility(8, ValueEntries."Shortcut Dimension 8 Code".Visible());

        ValueEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValueEntriesDimVisibilityNone()
    var
        ValueEntries: TestPage "Value Entries";
    begin
        // [SCENARIO 352854] Dimensions 3-8 are not visible on the "Value Entries" page when they are empty in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are empty in the general ledger setup
        ClearDimShortcuts();

        // [WHEN] Open "Value Entries" page
        ValueEntries.OpenView();

        // [THEN] Dimensions 3-8 are not visible
        Assert.IsFalse(ValueEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code should not be visible');
        Assert.IsFalse(ValueEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code should not be visible');
        Assert.IsFalse(ValueEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code should not be visible');
        Assert.IsFalse(ValueEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code should not be visible');
        Assert.IsFalse(ValueEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code should not be visible');
        Assert.IsFalse(ValueEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code should not be visible');

        ValueEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValueEntriesDimVisibilitySelected()
    var
        ValueEntries: TestPage "Value Entries";
        DimShortcuts: array[6] of Boolean;
    begin
        // [SCENARIO 352854] Three random dimensions from 3-8 range are visible on the "Value Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random dimensions are filled in the general ledger setup
        ClearDimShortcuts();
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        AssignGLSetupShortcuts(DimShortcuts);

        // [WHEN] Open "Value Entries" page
        ValueEntries.OpenView();

        // [THEN] Three random dimensions are visible
        Assert.AreEqual(DimShortcuts[1], ValueEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[2], ValueEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[3], ValueEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[4], ValueEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[5], ValueEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[6], ValueEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code has wrong visibility');

        ValueEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValueEntriesPreviewDimVisibilityAll()
    var
        ValueEntriesPreview: TestPage "Value Entries Preview";
    begin
        // [SCENARIO 352854] Dimensions 1-8 are visible on the "Value Entries Preview" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are filled in the general ledger setup
        SetGLSetupAllDimensions();

        // [WHEN] Open "Value Entries Preview" page
        ValueEntriesPreview.OpenView();

        // [THEN] Dimensions 1-8 are visible
        AssertVisibility(1, ValueEntriesPreview."Global Dimension 1 Code".Visible());
        AssertVisibility(2, ValueEntriesPreview."Global Dimension 2 Code".Visible());
        AssertVisibility(3, ValueEntriesPreview."Shortcut Dimension 3 Code".Visible());
        AssertVisibility(4, ValueEntriesPreview."Shortcut Dimension 4 Code".Visible());
        AssertVisibility(5, ValueEntriesPreview."Shortcut Dimension 5 Code".Visible());
        AssertVisibility(6, ValueEntriesPreview."Shortcut Dimension 6 Code".Visible());
        AssertVisibility(7, ValueEntriesPreview."Shortcut Dimension 7 Code".Visible());
        AssertVisibility(8, ValueEntriesPreview."Shortcut Dimension 8 Code".Visible());

        ValueEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValueEntriesPreviewDimVisibilityNone()
    var
        ValueEntriesPreview: TestPage "Value Entries Preview";
    begin
        // [SCENARIO 352854] Dimensions 3-8 are not visible on the "Value Entries Preview" page when they are empty in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are empty in the general ledger setup
        ClearDimShortcuts();

        // [WHEN] Open "Value Entries Preview" page
        ValueEntriesPreview.OpenView();

        // [THEN] Dimensions 3-8 are not visible
        Assert.IsFalse(ValueEntriesPreview."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code should not be visible');
        Assert.IsFalse(ValueEntriesPreview."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code should not be visible');
        Assert.IsFalse(ValueEntriesPreview."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code should not be visible');
        Assert.IsFalse(ValueEntriesPreview."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code should not be visible');
        Assert.IsFalse(ValueEntriesPreview."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code should not be visible');
        Assert.IsFalse(ValueEntriesPreview."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code should not be visible');

        ValueEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValueEntriesPreviewDimVisibilitySelected()
    var
        ValueEntriesPreview: TestPage "Value Entries Preview";
        DimShortcuts: array[6] of Boolean;
    begin
        // [SCENARIO 352854] Three random dimensions from 3-8 range are visible on the "Value Entries Preview" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random dimensions are filled in the general ledger setup
        ClearDimShortcuts();
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        AssignGLSetupShortcuts(DimShortcuts);

        // [WHEN] Open "Value Entries Preview" page
        ValueEntriesPreview.OpenView();

        // [THEN] Three random dimensions are visible
        Assert.AreEqual(DimShortcuts[1], ValueEntriesPreview."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[2], ValueEntriesPreview."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[3], ValueEntriesPreview."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[4], ValueEntriesPreview."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[5], ValueEntriesPreview."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[6], ValueEntriesPreview."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code has wrong visibility');

        ValueEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendLedgEntriesPreviewDimVisibilityAll()
    var
        VendLedgEntriesPreview: TestPage "Vend. Ledg. Entries Preview";
    begin
        // [SCENARIO 352854] Dimensions 1-8 are visible on the "Vend. Ledg. Entries Preview" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are filled in the general ledger setup
        SetGLSetupAllDimensions();

        // [WHEN] Open "Vend. Ledg. Entries Preview" page
        VendLedgEntriesPreview.OpenView();

        // [THEN] Dimensions 1-8 are visible
        AssertVisibility(1, VendLedgEntriesPreview."Global Dimension 1 Code".Visible());
        AssertVisibility(2, VendLedgEntriesPreview."Global Dimension 2 Code".Visible());
        AssertVisibility(3, VendLedgEntriesPreview."Shortcut Dimension 3 Code".Visible());
        AssertVisibility(4, VendLedgEntriesPreview."Shortcut Dimension 4 Code".Visible());
        AssertVisibility(5, VendLedgEntriesPreview."Shortcut Dimension 5 Code".Visible());
        AssertVisibility(6, VendLedgEntriesPreview."Shortcut Dimension 6 Code".Visible());
        AssertVisibility(7, VendLedgEntriesPreview."Shortcut Dimension 7 Code".Visible());
        AssertVisibility(8, VendLedgEntriesPreview."Shortcut Dimension 8 Code".Visible());

        VendLedgEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendLedgEntriesPreviewDimVisibilityNone()
    var
        VendLedgEntriesPreview: TestPage "Vend. Ledg. Entries Preview";
    begin
        // [SCENARIO 352854] Dimensions 3-8 are not visible on the "Vend. Ledg. Entries Preview" page when they are empty in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are empty in the general ledger setup
        ClearDimShortcuts();

        // [WHEN] Open "Vend. Ledg. Entries Preview" page
        VendLedgEntriesPreview.OpenView();

        // [THEN] Dimensions 3-8 are not visible
        Assert.IsFalse(VendLedgEntriesPreview."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code should not be visible');
        Assert.IsFalse(VendLedgEntriesPreview."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code should not be visible');
        Assert.IsFalse(VendLedgEntriesPreview."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code should not be visible');
        Assert.IsFalse(VendLedgEntriesPreview."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code should not be visible');
        Assert.IsFalse(VendLedgEntriesPreview."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code should not be visible');
        Assert.IsFalse(VendLedgEntriesPreview."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code should not be visible');

        VendLedgEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendLedgEntriesPreviewDimVisibilitySelected()
    var
        VendLedgEntriesPreview: TestPage "Vend. Ledg. Entries Preview";
        DimShortcuts: array[6] of Boolean;
    begin
        // [SCENARIO 352854] Three random dimensions from 3-8 range are visible on the "Vend. Ledg. Entries Preview" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random dimensions are filled in the general ledger setup
        ClearDimShortcuts();
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        AssignGLSetupShortcuts(DimShortcuts);

        // [WHEN] Open "Vend. Ledg. Entries Preview" page
        VendLedgEntriesPreview.OpenView();

        // [THEN] Three random dimensions are visible
        Assert.AreEqual(DimShortcuts[1], VendLedgEntriesPreview."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[2], VendLedgEntriesPreview."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[3], VendLedgEntriesPreview."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[4], VendLedgEntriesPreview."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[5], VendLedgEntriesPreview."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[6], VendLedgEntriesPreview."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code has wrong visibility');

        VendLedgEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorLedgerEntriesDimVisibilityAll()
    var
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        // [SCENARIO 352854] Dimensions 1-8 are visible on the "Vendor Ledger Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are filled in the general ledger setup
        SetGLSetupAllDimensions();

        // [WHEN] Open "Vendor Ledger Entries" page
        VendorLedgerEntries.OpenView();

        // [THEN] Dimensions 1-8 are visible
        AssertVisibility(1, VendorLedgerEntries."Global Dimension 1 Code".Visible());
        AssertVisibility(2, VendorLedgerEntries."Global Dimension 2 Code".Visible());
        AssertVisibility(3, VendorLedgerEntries."Shortcut Dimension 3 Code".Visible());
        AssertVisibility(4, VendorLedgerEntries."Shortcut Dimension 4 Code".Visible());
        AssertVisibility(5, VendorLedgerEntries."Shortcut Dimension 5 Code".Visible());
        AssertVisibility(6, VendorLedgerEntries."Shortcut Dimension 6 Code".Visible());
        AssertVisibility(7, VendorLedgerEntries."Shortcut Dimension 7 Code".Visible());
        AssertVisibility(8, VendorLedgerEntries."Shortcut Dimension 8 Code".Visible());

        VendorLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorLedgerEntriesDimVisibilityNone()
    var
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        // [SCENARIO 352854] Dimensions 3-8 are not visible on the "Vendor Ledger Entries" page when they are empty in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are empty in the general ledger setup
        ClearDimShortcuts();

        // [WHEN] Open "Vendor Ledger Entries" page
        VendorLedgerEntries.OpenView();

        // [THEN] Dimensions 3-8 are not visible
        Assert.IsFalse(VendorLedgerEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code should not be visible');
        Assert.IsFalse(VendorLedgerEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code should not be visible');
        Assert.IsFalse(VendorLedgerEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code should not be visible');
        Assert.IsFalse(VendorLedgerEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code should not be visible');
        Assert.IsFalse(VendorLedgerEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code should not be visible');
        Assert.IsFalse(VendorLedgerEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code should not be visible');

        VendorLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorLedgerEntriesDimVisibilitySelected()
    var
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        DimShortcuts: array[6] of Boolean;
    begin
        // [SCENARIO 352854] Three random dimensions from 3-8 range are visible on the "Vendor Ledger Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random dimensions are filled in the general ledger setup
        ClearDimShortcuts();
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        AssignGLSetupShortcuts(DimShortcuts);

        // [WHEN] Open "Vendor Ledger Entries" page
        VendorLedgerEntries.OpenView();

        // [THEN] Three random dimensions are visible
        Assert.AreEqual(DimShortcuts[1], VendorLedgerEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[2], VendorLedgerEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[3], VendorLedgerEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[4], VendorLedgerEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[5], VendorLedgerEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[6], VendorLedgerEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code has wrong visibility');

        VendorLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarrantyLedgEntriesPreviewDimVisibilityAll()
    var
        WarrantyLedgEntriesPreview: TestPage "Warranty Ledg. Entries Preview";
    begin
        // [SCENARIO 352854] Dimensions 1-8 are visible on the "Warranty Ledg. Entries Preview" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are filled in the general ledger setup
        SetGLSetupAllDimensions();

        // [WHEN] Open "Warranty Ledg. Entries Preview" page
        WarrantyLedgEntriesPreview.OpenView();

        // [THEN] Dimensions 1-8 are visible
        AssertVisibility(1, WarrantyLedgEntriesPreview."Global Dimension 1 Code".Visible());
        AssertVisibility(2, WarrantyLedgEntriesPreview."Global Dimension 2 Code".Visible());
        AssertVisibility(3, WarrantyLedgEntriesPreview."Shortcut Dimension 3 Code".Visible());
        AssertVisibility(4, WarrantyLedgEntriesPreview."Shortcut Dimension 4 Code".Visible());
        AssertVisibility(5, WarrantyLedgEntriesPreview."Shortcut Dimension 5 Code".Visible());
        AssertVisibility(6, WarrantyLedgEntriesPreview."Shortcut Dimension 6 Code".Visible());
        AssertVisibility(7, WarrantyLedgEntriesPreview."Shortcut Dimension 7 Code".Visible());
        AssertVisibility(8, WarrantyLedgEntriesPreview."Shortcut Dimension 8 Code".Visible());

        WarrantyLedgEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarrantyLedgEntriesPreviewDimVisibilityNone()
    var
        WarrantyLedgEntriesPreview: TestPage "Warranty Ledg. Entries Preview";
    begin
        // [SCENARIO 352854] Dimensions 3-8 are not visible on the "Warranty Ledg. Entries Preview" page when they are empty in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are empty in the general ledger setup
        ClearDimShortcuts();

        // [WHEN] Open "Warranty Ledg. Entries Preview" page
        WarrantyLedgEntriesPreview.OpenView();

        // [THEN] Dimensions 3-8 are not visible
        Assert.IsFalse(WarrantyLedgEntriesPreview."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code should not be visible');
        Assert.IsFalse(WarrantyLedgEntriesPreview."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code should not be visible');
        Assert.IsFalse(WarrantyLedgEntriesPreview."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code should not be visible');
        Assert.IsFalse(WarrantyLedgEntriesPreview."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code should not be visible');
        Assert.IsFalse(WarrantyLedgEntriesPreview."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code should not be visible');
        Assert.IsFalse(WarrantyLedgEntriesPreview."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code should not be visible');

        WarrantyLedgEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarrantyLedgEntriesPreviewDimVisibilitySelected()
    var
        WarrantyLedgEntriesPreview: TestPage "Warranty Ledg. Entries Preview";
        DimShortcuts: array[6] of Boolean;
    begin
        // [SCENARIO 352854] Three random dimensions from 3-8 range are visible on the "Warranty Ledg. Entries Preview" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random dimensions are filled in the general ledger setup
        ClearDimShortcuts();
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        AssignGLSetupShortcuts(DimShortcuts);

        // [WHEN] Open "Warranty Ledg. Entries Preview" page
        WarrantyLedgEntriesPreview.OpenView();

        // [THEN] Three random dimensions are visible
        Assert.AreEqual(DimShortcuts[1], WarrantyLedgEntriesPreview."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[2], WarrantyLedgEntriesPreview."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[3], WarrantyLedgEntriesPreview."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[4], WarrantyLedgEntriesPreview."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[5], WarrantyLedgEntriesPreview."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[6], WarrantyLedgEntriesPreview."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code has wrong visibility');

        WarrantyLedgEntriesPreview.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarrantyLedgerEntriesDimVisibilityAll()
    var
        WarrantyLedgerEntries: TestPage "Warranty Ledger Entries";
    begin
        // [SCENARIO 352854] Dimensions 1-8 are visible on the "Warranty Ledger Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are filled in the general ledger setup
        SetGLSetupAllDimensions();

        // [WHEN] Open "Warranty Ledger Entries" page
        WarrantyLedgerEntries.OpenView();

        // [THEN] Dimensions 1-8 are visible
        AssertVisibility(1, WarrantyLedgerEntries."Global Dimension 1 Code".Visible());
        AssertVisibility(2, WarrantyLedgerEntries."Global Dimension 2 Code".Visible());
        AssertVisibility(3, WarrantyLedgerEntries."Shortcut Dimension 3 Code".Visible());
        AssertVisibility(4, WarrantyLedgerEntries."Shortcut Dimension 4 Code".Visible());
        AssertVisibility(5, WarrantyLedgerEntries."Shortcut Dimension 5 Code".Visible());
        AssertVisibility(6, WarrantyLedgerEntries."Shortcut Dimension 6 Code".Visible());
        AssertVisibility(7, WarrantyLedgerEntries."Shortcut Dimension 7 Code".Visible());
        AssertVisibility(8, WarrantyLedgerEntries."Shortcut Dimension 8 Code".Visible());

        WarrantyLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarrantyLedgerEntriesDimVisibilityNone()
    var
        WarrantyLedgerEntries: TestPage "Warranty Ledger Entries";
    begin
        // [SCENARIO 352854] Dimensions 3-8 are not visible on the "Warranty Ledger Entries" page when they are empty in the general ledger setup
        Initialize();

        // [GIVEN] Dimensions 3-8 are empty in the general ledger setup
        ClearDimShortcuts();

        // [WHEN] Open "Warranty Ledger Entries" page
        WarrantyLedgerEntries.OpenView();

        // [THEN] Dimensions 3-8 are not visible
        Assert.IsFalse(WarrantyLedgerEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code should not be visible');
        Assert.IsFalse(WarrantyLedgerEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code should not be visible');
        Assert.IsFalse(WarrantyLedgerEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code should not be visible');
        Assert.IsFalse(WarrantyLedgerEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code should not be visible');
        Assert.IsFalse(WarrantyLedgerEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code should not be visible');
        Assert.IsFalse(WarrantyLedgerEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code should not be visible');

        WarrantyLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WarrantyLedgerEntriesDimVisibilitySelected()
    var
        WarrantyLedgerEntries: TestPage "Warranty Ledger Entries";
        DimShortcuts: array[6] of Boolean;
    begin
        // [SCENARIO 352854] Three random dimensions from 3-8 range are visible on the "Warranty Ledger Entries" page when they are filled in the general ledger setup
        Initialize();

        // [GIVEN] Three random dimensions are filled in the general ledger setup
        ClearDimShortcuts();
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        DimShortcuts[LibraryRandom.RandIntInRange(1, 6)] := true;
        AssignGLSetupShortcuts(DimShortcuts);

        // [WHEN] Open "Warranty Ledger Entries" page
        WarrantyLedgerEntries.OpenView();

        // [THEN] Three random dimensions are visible
        Assert.AreEqual(DimShortcuts[1], WarrantyLedgerEntries."Shortcut Dimension 3 Code".Visible(), 'Dimension 3 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[2], WarrantyLedgerEntries."Shortcut Dimension 4 Code".Visible(), 'Dimension 4 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[3], WarrantyLedgerEntries."Shortcut Dimension 5 Code".Visible(), 'Dimension 5 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[4], WarrantyLedgerEntries."Shortcut Dimension 6 Code".Visible(), 'Dimension 6 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[5], WarrantyLedgerEntries."Shortcut Dimension 7 Code".Visible(), 'Dimension 7 Code has wrong visibility');
        Assert.AreEqual(DimShortcuts[6], WarrantyLedgerEntries."Shortcut Dimension 8 Code".Visible(), 'Dimension 8 Code has wrong visibility');

        WarrantyLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimSetEntryGlobalDimNoDefaultDimensions()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        i: Integer;
    begin
        // [SCENARIO 386822] "Global Dimension No." is filled with value when dimension set entries inserted from default dimensions
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);

        // [GIVEN] Customer with default dimensions
        LibrarySales.CreateCustomer(Customer);
        for i := 1 to 6 do
            LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::Customer, Customer."No.", DimensionValue[i]."Dimension Code", DimensionValue[i].Code);

        // [WHEN] Create sales document
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [THEN] Dimension set entries (DSE) inserted, "Global Dimension No." filled like DSE1 = 3, ..., DSE6 = 8
        VerifyDimSetEntryGlobalDimNo(DimensionValue);
    end;

    [Test]
    [HandlerFunctions('EditDimensionSetEntriesHandler')]
    [Scope('OnPrem')]
    procedure DimSetEntryGlobalDimNoAddedDimensions()
    var
        DimensionValue: array[6] of Record "Dimension Value";
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
        i: Integer;
    begin
        // [SCENARIO 386822] "Global Dimension No." is filled with value when dimension set entries inserted manuall by user
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);
        for i := 1 to 6 do
            LibraryVariableStorage.Enqueue(DimensionValue[i]."Dimension Code");

        // [GIVEN] Sales order without dimensions
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [WHEN] Setup dimensions via page from the sales order
        SalesOrder.OpenEdit();
        SalesOrder.GoToRecord(SalesHeader);
        SalesOrder.Dimensions.Invoke();

        // [THEN] Dimension set entries (DSE) inserted, "Global Dimension No." filled like DSE1 = 3, ..., DSE6 = 8
        VerifyDimSetEntryGlobalDimNo(DimensionValue);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecurringByDimSingleDimFilter()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecurringGenJournalLine: Record "Gen. Journal Line";
        DimensionValue: array[6] of Record "Dimension Value";
        GLAccount: Record "G/L Account";
        i: Integer;
        DimSetId: array[6] of Integer;
    begin
        // [SCENARIO 386822] Post recurring journal by dimensions with single dimension filter
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are filled in the general ledger setup ("D1".."D6")
        CreateShortcutDimensions(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);
        // [GIVEN] G/L Account "GLA" to be balanced by dimensions
        LibraryERM.CreateGLAccount(GLAccount);
        // [GIVEN] 6 posted gen. jnl. lines with "GLA" and "D1".."D6" and amounts 100..600
        for i := 1 to 6 do begin
            CreateGenJnlLine(GenJournalLine, GLAccount."No.", i * 100);
            DimSetId[i] := CreateDimSet(DimensionValue[i]);
            GenJournalLine.Validate("Dimension Set ID", DimSetId[i]);
            GenJournalLine.Modify(true);
            LibraryERM.PostGeneralJnlLine(GenJournalLine);
        end;

        // [WHEN] Post recurring journal with "D1".."D6" dimension filter
        for i := 1 to 6 do begin
            CreateRecurringGenJnlLine(RecurringGenJournalLine, GLAccount."No.");
            CreateGenJnlDimFilter(RecurringGenJournalLine, DimensionValue[i]);
            LibraryERM.PostGeneralJnlLine(RecurringGenJournalLine);
        end;

        // [THEN] Original g/l entry by "D1".."D6" balanced with recurring g/l entry by "D1".."D6"
        for i := 1 to 6 do
            VerifyGLEntrySingleDim(DimSetId[i], GLAccount."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecurringByDimNoDimFilter()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecurringGenJournalLine: Record "Gen. Journal Line";
        DimensionValue: array[6] of Record "Dimension Value";
        GLAccount: Record "G/L Account";
        i: Integer;
        DimSetId: array[6] of Integer;
    begin
        // [SCENARIO 386822] Post recurring journal by dimensions without dimension filter
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are filled in the general ledger setup ("D1".."D6")
        CreateShortcutDimensions(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);
        // [GIVEN] G/L Account "GLA" to be balanced by dimensions
        LibraryERM.CreateGLAccount(GLAccount);
        // [GIVEN] 6 posted gen. jnl. lines with "GLA" and "D1".."D6" and amounts 100..600
        for i := 1 to 6 do begin
            CreateGenJnlLine(GenJournalLine, GLAccount."No.", i * 100);
            DimSetId[i] := CreateDimSet(DimensionValue[i]);
            GenJournalLine.Validate("Dimension Set ID", DimSetId[i]);
            GenJournalLine.Modify(true);
            LibraryERM.PostGeneralJnlLine(GenJournalLine);
        end;

        // [WHEN] Post recurring journal without "D1" dimension filter
        CreateRecurringGenJnlLine(RecurringGenJournalLine, GLAccount."No.");
        LibraryERM.PostGeneralJnlLine(RecurringGenJournalLine);

        // [THEN] Original g/l entry by "D1" balanced with recurring g/l entry by "D1"
        for i := 1 to 6 do
            VerifyGLEntrySingleDim(DimSetId[i], GLAccount."No.");

        // [THEN] "GLA".Balance = 0
        GLAccount.CalcFields(Balance);
        Assert.IsTrue(GLAccount.Balance = 0, 'Wrong balance');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecurringByDimPostedEntryBatchName()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RecurringGenJournalLine: Record "Gen. Journal Line";
        DimensionValue: array[6] of Record "Dimension Value";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
        ERMDimensionShortcuts: Codeunit "ERM Dimension Shortcuts";
        i: Integer;
    begin
        // [SCENARIO 388380] Posted recurring journal lines contain original batch name, not the temporary one
        Initialize();
        RemoveTempBatches();

        // [GIVEN] Shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);
        // [GIVEN] 6 posted gen. jnl. lines
        LibraryERM.CreateGLAccount(GLAccount);
        for i := 1 to 6 do begin
            CreateGenJnlLine(GenJournalLine, GLAccount."No.", i * 100);
            GenJournalLine.Validate("Dimension Set ID", CreateDimSet(DimensionValue[i]));
            GenJournalLine.Modify(true);
            LibraryERM.PostGeneralJnlLine(GenJournalLine);
        end;

        // [GIVEN] Recurring Journal batch 'X' with line without dimension filter
        CreateRecurringGenJnlLine(RecurringGenJournalLine, GLAccount."No.");

        // [GIVEN] Recurring Journal batch, where Name = 'BD_TEMP998'
        GenJournalBatch."Journal Template Name" := RecurringGenJournalLine."Journal Template Name";
        GenJournalBatch.Name := StrSubstNo('%1%2', TempBatchNameTxt, '998');
        GenJournalBatch.Insert(true);

        // [WHEN] Post recurring journal 
        BindSubscription(ERMDimensionShortcuts); // OnAfterInsertGenJournalBatch
        LibraryERM.PostGeneralJnlLine(RecurringGenJournalLine);

        // [THEN] "Reversing" recurring entries contain original batch name
        GLEntry.SetRange("G/L Account No.", GLAccount."No.");
        GLEntry.SetRange("Journal Batch Name", RecurringGenJournalLine."Journal Batch Name");
        Assert.RecordCount(GLEntry, 6);
        GLEntry.SetFilter("Journal Batch Name", StrSubstNo('%1*', TempBatchNameTxt));
        Assert.RecordCount(GLEntry, 0);

        // [THEN] "Allocation" recurring entries contain original batch name
        GenJnlAllocation.SetRange("Journal Template Name", RecurringGenJournalLine."Journal Template Name");
        GenJnlAllocation.SetRange("Journal Batch Name", RecurringGenJournalLine."Journal Batch Name");
        GenJnlAllocation.SetRange("Journal Line No.", RecurringGenJournalLine."Line No.");
        GenJnlAllocation.FindFirst();

        GLEntry.SetRange("G/L Account No.", GenJnlAllocation."Account No.");
        GLEntry.SetRange("Journal Batch Name", RecurringGenJournalLine."Journal Batch Name");
        Assert.RecordCount(GLEntry, 6);
        GLEntry.SetFilter("Journal Batch Name", StrSubstNo('%1*', TempBatchNameTxt));
        Assert.RecordCount(GLEntry, 0);

        // [THEN] Recurring Journal batch still exists, where Name = 'BD_TEMP998'
        Assert.IsTrue(GenJournalBatch.Find(), 'temp batch is not found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecurringByDimValidateRecurringShortcutDimCode()
    var
        RecurringGenJournalLine: Record "Gen. Journal Line";
        DimensionValue: array[6] of Record "Dimension Value";
        RecurringGeneralJournal: TestPage "Recurring General Journal";
    begin
        // [SCENARIO 388417] User cannot fill shortcut dimension code on the recurring journal page for "Recurring Method" = "BD Balance by Dimension" line
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);
        // [GIVEN] Recurring journal line, "Recurring Method" = "BD Balance by Dimension"
        CreateRecurringGenJnlLine(RecurringGenJournalLine, LibraryERM.CreateGLAccountNo());

        // [WHEN] Fill shortcut dimension X code on the recurring journal page
        RecurringGeneralJournal.Trap();
        Page.Run(Page::"Recurring General Journal", RecurringGenJournalLine);

        // [THEN] Error message is thrown
        asserterror RecurringGeneralJournal.ShortcutDimCode3.SetValue(DimensionValue[1].Code);
        Assert.ExpectedError(ShortcutDimErrorTxt);
        asserterror RecurringGeneralJournal.ShortcutDimCode4.SetValue(DimensionValue[2].Code);
        Assert.ExpectedError(ShortcutDimErrorTxt);
        asserterror RecurringGeneralJournal.ShortcutDimCode5.SetValue(DimensionValue[3].Code);
        Assert.ExpectedError(ShortcutDimErrorTxt);
        asserterror RecurringGeneralJournal.ShortcutDimCode6.SetValue(DimensionValue[4].Code);
        Assert.ExpectedError(ShortcutDimErrorTxt);
        asserterror RecurringGeneralJournal.ShortcutDimCode7.SetValue(DimensionValue[5].Code);
        Assert.ExpectedError(ShortcutDimErrorTxt);
        asserterror RecurringGeneralJournal.ShortcutDimCode8.SetValue(DimensionValue[6].Code);
        Assert.ExpectedError(ShortcutDimErrorTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecurringByDimValidateRecurringShortcutDimCodeNonDimBalLine()
    var
        RecurringGenJournalLine: Record "Gen. Journal Line";
        DimensionValue: array[6] of Record "Dimension Value";
        RecurringGeneralJournal: TestPage "Recurring General Journal";
    begin
        // [SCENARIO 388417] User fill shortcut dimension code on the recurring journal page for "Recurring Method" <> "BD Balance by Dimension" line
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);
        // [GIVEN] Recurring journal line, "Recurring Method" = "F Fixed"
        CreateRecurringGenJnlLine(RecurringGenJournalLine, LibraryERM.CreateGLAccountNo());
        RecurringGenJournalLine."Recurring Method" := RecurringGenJournalLine."Recurring Method"::"F  Fixed";
        RecurringGenJournalLine.Modify();

        // [WHEN] Fill shortcut dimension X code on the recurring journal page
        RecurringGeneralJournal.Trap();
        Page.Run(Page::"Recurring General Journal", RecurringGenJournalLine);

        // [THEN] Shortcut dimension X code is filled in
        RecurringGeneralJournal.ShortcutDimCode3.SetValue(DimensionValue[1].Code);
        RecurringGeneralJournal.ShortcutDimCode3.AssertEquals(DimensionValue[1].Code);
        RecurringGeneralJournal.ShortcutDimCode4.SetValue(DimensionValue[2].Code);
        RecurringGeneralJournal.ShortcutDimCode4.AssertEquals(DimensionValue[2].Code);
        RecurringGeneralJournal.ShortcutDimCode5.SetValue(DimensionValue[3].Code);
        RecurringGeneralJournal.ShortcutDimCode5.AssertEquals(DimensionValue[3].Code);
        RecurringGeneralJournal.ShortcutDimCode6.SetValue(DimensionValue[4].Code);
        RecurringGeneralJournal.ShortcutDimCode6.AssertEquals(DimensionValue[4].Code);
        RecurringGeneralJournal.ShortcutDimCode7.SetValue(DimensionValue[5].Code);
        RecurringGeneralJournal.ShortcutDimCode7.AssertEquals(DimensionValue[5].Code);
        RecurringGeneralJournal.ShortcutDimCode8.SetValue(DimensionValue[6].Code);
        RecurringGeneralJournal.ShortcutDimCode8.AssertEquals(DimensionValue[6].Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecurringByDimTempBatchDeleted()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecurringGenJournalLine: Record "Gen. Journal Line";
        DimensionValue: array[6] of Record "Dimension Value";
        GLAccount: Record "G/L Account";
        GLEntry: Record "G/L Entry";
        GenJournalBatch: Record "Gen. Journal Batch";
        ERMDimensionShortcuts: Codeunit "ERM Dimension Shortcuts";
        i: Integer;
    begin
        // [SCENARIO 388437] Temporary recurring journal batch does not exist after trying to post without error
        Initialize();
        RemoveTempBatches();

        // [GIVEN] Shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);
        // [GIVEN] 6 posted gen. jnl. lines
        LibraryERM.CreateGLAccount(GLAccount);
        for i := 1 to 6 do begin
            CreateGenJnlLine(GenJournalLine, GLAccount."No.", i * 100);
            GenJournalLine.Validate("Dimension Set ID", CreateDimSet(DimensionValue[i]));
            GenJournalLine.Modify(true);
            LibraryERM.PostGeneralJnlLine(GenJournalLine);
        end;

        // [GIVEN] Recurring Journal batch 'X' with the line (should not be posted due to "Posting Date") 
        CreateRecurringGenJnlLine(RecurringGenJournalLine, GLAccount."No.");
        RecurringGenJournalLine."Posting Date" := WorkDate() - 1;
        RecurringGenJournalLine.Modify();
        // [GIVEN] Recurring Journal batch, where Name = 'BD_TEMP003'
        GenJournalBatch."Journal Template Name" := RecurringGenJournalLine."Journal Template Name";
        GenJournalBatch.Name := StrSubstNo('%1%2', TempBatchNameTxt, '003');
        GenJournalBatch.Insert(true);

        // [WHEN] Try to post recurring journal 'X'
        BindSubscription(ERMDimensionShortcuts); // OnAfterInsertGenJournalBatch
        LibraryERM.PostGeneralJnlLine(RecurringGenJournalLine);

        // [THEN] Temporary recurring batch does not exist
        GenJournalBatch.SetRange("Journal Template Name", RecurringGenJournalLine."Journal Template Name");
        GenJournalBatch.SetFilter(Name, StrSubstNo('%1*', TempBatchNameTxt));
        Assert.RecordCount(GenJournalBatch, 1);
        Assert.IsTrue(GenJournalBatch.FindFirst(), 'not found temp batch from previous posting');
        // [THEN] There are no posted G/L entries
        GLEntry.SetRange("G/L Account No.", GLAccount."No.");
        GLEntry.SetRange("Journal Batch Name", RecurringGenJournalLine."Journal Batch Name");
        Assert.RecordCount(GLEntry, 0);
        GLEntry.SetFilter("Journal Batch Name", StrSubstNo('%1*', TempBatchNameTxt));
        Assert.RecordCount(GLEntry, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecurringByDimPostTwoRecurringLines()
    var
        GenJournalLine: Record "Gen. Journal Line";
        RecurringGenJournalLine: Record "Gen. Journal Line";
        DimensionValue: array[6] of Record "Dimension Value";
        GLEntry: Record "G/L Entry";
        i: Integer;
        GLAccNo: array[6] of Code[20];
    begin
        // [SCENARIO 388437] Temporary recurring journal batch does not exist after trying to post without error
        Initialize();

        // [GIVEN] Shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);
        // [GIVEN] 6 posted gen. jnl. lines
        for i := 1 to 6 do begin
            GLAccNo[i] := LibraryERM.CreateGLAccountNo();
            CreateGenJnlLine(GenJournalLine, GLAccNo[i], i * 100);
            GenJournalLine.Validate("Dimension Set ID", CreateDimSet(DimensionValue[i]));
            GenJournalLine.Modify(true);
            LibraryERM.PostGeneralJnlLine(GenJournalLine);
        end;

        // [WHEN] Post two recurring journal liens with different accounts
        CreateTwoRecurringGenJnlLines(RecurringGenJournalLine, GLAccNo[1], GLAccNo[2]);
        LibraryERM.PostGeneralJnlLine(RecurringGenJournalLine);

        // [THEN] There are posted G/L entries for 
        GLEntry.SetRange("G/L Account No.", GLAccNo[1], GLAccNo[2]);
        GLEntry.SetRange("Journal Batch Name", RecurringGenJournalLine."Journal Batch Name");
        Assert.RecordCount(GLEntry, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecurringByDimPostOverflowBatchName()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        RecurringGenJournalLine: Record "Gen. Journal Line";
        DimensionValue: array[6] of Record "Dimension Value";
        i: Integer;
        GLAccNo: array[6] of Code[20];
    begin
        // [SCENARIO 388437] Temporary recurring journal batch gets overflow error
        Initialize();
        RemoveTempBatches();

        // [GIVEN] Shortcut dimensions 3-8 are filled in the general ledger setup
        CreateShortcutDimensions(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);
        // [GIVEN] 6 posted gen. jnl. lines
        for i := 1 to 6 do begin
            GLAccNo[i] := LibraryERM.CreateGLAccountNo();
            CreateGenJnlLine(GenJournalLine, GLAccNo[i], i * 100);
            GenJournalLine.Validate("Dimension Set ID", CreateDimSet(DimensionValue[i]));
            GenJournalLine.Modify(true);
            LibraryERM.PostGeneralJnlLine(GenJournalLine);
        end;

        // [GIVEN] Batch 'X' with two recurring journal lines with different accounts
        CreateTwoRecurringGenJnlLines(RecurringGenJournalLine, GLAccNo[1], GLAccNo[2]);
        // [GIVEN] Recurring Journal batch, where Name = 'BD_TEMP999'
        GenJournalBatch."Journal Template Name" := RecurringGenJournalLine."Journal Template Name";
        GenJournalBatch.Name := StrSubstNo('%1%2', TempBatchNameTxt, '999');
        GenJournalBatch.Insert(true);

        // [WHEN] Post batch 'X'
        asserterror LibraryERM.PostGeneralJnlLine(RecurringGenJournalLine);

        // [THEN] Overflow error on teh temp batch name calculation: 'The length of the string is 11'
        Assert.ExpectedError('The length of the string is 11');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FixDimSetEntryGlobalDimNoCodeunitUT()
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        DimensionValue: array[6] of Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimSetId: Integer;
    begin
        // [SCENARIO 396220] Fix "Global Dimension No." in Dimension Set Entry table
        Initialize();

        // [GIVEN] Corrupted "Global Dimension No." in Dimension Set Entry
        CreateShortcutDimensions(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);
        DimSetId := CreateCorruptedDimSetEntry(DimensionValue);

        // [WHEN] Run fix "Global Dimension No." procedure
        Codeunit.Run(Codeunit::"Update Dim. Set Glbl. Dim. No.");

        // [THEN] "Global Dimension No." corrected accordingly G/L setup
        VerifyDimSetEntryGlobalDimNo(DimensionValue);
        // [THEN] "Global Dimension No." = 0 for "Global Dimension 1 Code"
        GeneralLedgerSetup.Get();
        DimensionSetEntry.Get(DimSetId, GeneralLedgerSetup."Global Dimension 1 Code");
        DimensionSetEntry.TestField("Global Dimension No.", 0);
        // [THEN] "Global Dimension No." = 0 for "Global Dimension 2 Code"
        DimensionSetEntry.Get(DimSetId, GeneralLedgerSetup."Global Dimension 2 Code");
        DimensionSetEntry.TestField("Global Dimension No.", 0);
        // [THEN] "Global Dimension No." = 0 for non shortcut dimension set entries
        VerifyNonShrtcutDimSetEntryGlobalDimNo(DimSetId);
        // [THEN] Change log entries are created
        VerifyChangeLogEntry(DimSetId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FixEmptyGLSetupDimSetEntryGlobalDimNoCodeunitUT()
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        DimensionValue: array[6] of Record "Dimension Value";
    begin
        // [SCENARIO 396220] Fix "Global Dimension No." in Dimension Set Entry table with empty shortcuts in g/l setup
        Initialize();

        // [GIVEN] Empty shortcuts in g/l setup
        ClearDimShortcuts();
        // [GIVEN] Corrupted "Global Dimension No." in Dimension Set Entry
        CreateShortcutDimensions(DimensionValue);
        CreateCorruptedDimSetEntry(DimensionValue);

        // [WHEN] Run fix "Global Dimension No." procedure
        Codeunit.Run(Codeunit::"Update Dim. Set Glbl. Dim. No.");

        // [THEN] Dimension set entry doesn't contain any records with "Global Dimension No." <> 0
        DimensionSetEntry.SetFilter("Global Dimension No.", '<>0');
        Assert.RecordCount(DimensionSetEntry, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('UpdateDimSetGlblDimNoReqPageHandler,MessageHandler')]
    procedure FixDimSetEntryGlobalDimNoReportUT()
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        DimensionValue: array[6] of Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimSetId: Integer;
    begin
        // [SCENARIO 396220] Fix "Global Dimension No." in Dimension Set Entry table via running report
        Initialize();

        // [GIVEN] Corrupted "Global Dimension No." in Dimension Set Entry
        CreateShortcutDimensions(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);
        DimSetId := CreateCorruptedDimSetEntry(DimensionValue);

        // [WHEN] Run fix "Global Dimension No." procedure via report
        Commit();
        Report.Run(Report::"Update Dim. Set Glbl. Dim. No.");

        // [THEN] "Global Dimension No." corrected accordingly G/L setup
        VerifyDimSetEntryGlobalDimNo(DimensionValue);
        // [THEN] "Global Dimension No." = 0 for "Global Dimension 1 Code"
        GeneralLedgerSetup.Get();
        DimensionSetEntry.Get(DimSetId, GeneralLedgerSetup."Global Dimension 1 Code");
        DimensionSetEntry.TestField("Global Dimension No.", 0);
        // [THEN] "Global Dimension No." = 0 for "Global Dimension 2 Code"
        DimensionSetEntry.Get(DimSetId, GeneralLedgerSetup."Global Dimension 2 Code");
        DimensionSetEntry.TestField("Global Dimension No.", 0);
        // [THEN] "Global Dimension No." = 0 for non shortcut dimension set entries
        VerifyNonShrtcutDimSetEntryGlobalDimNo(DimSetId);
        // [THEN] Change log entries are created
        VerifyChangeLogEntry(DimSetId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InsertDimSetEntryGlobalDimNoUT()
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        DimensionValue: array[6] of Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
        GlobalDimensionValue: Record "Dimension Value";
        i: Integer;
        DimSetId: Integer;
    begin
        // [SCENARIO 396220] Insert(true) dimension set entry
        Initialize();
        GeneralLedgerSetup.Get();

        // [GIVEN] General ledger setup with shortcut dimensions
        CreateShortcutDimensions(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);
        DimSetId := GetDimSetId();

        // [WHEN] Insert(true) dimension set entry
        for i := 1 to 6 do begin
            DimensionSetEntry."Dimension Set ID" := DimSetId;
            DimensionSetEntry."Dimension Code" := DimensionValue[i]."Dimension Code";
            DimensionSetEntry."Dimension Value Code" := DimensionValue[i].Code;
            DimensionSetEntry."Global Dimension No." := i * 100; // wrong "Global Dimension No."
            DimensionSetEntry.Insert(true);
        end;

        LibraryDimension.CreateDimensionValue(GlobalDimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
        DimensionSetEntry."Dimension Set ID" := DimSetId;
        DimensionSetEntry."Dimension Code" := GlobalDimensionValue."Dimension Code";
        DimensionSetEntry."Dimension Value Code" := GlobalDimensionValue.Code;
        DimensionSetEntry."Global Dimension No." := 1; // wrong "Global Dimension No."
        DimensionSetEntry.Insert(true);

        // [THEN] "Global Dimension No." filled accordingly G/L setup
        VerifyDimSetEntryGlobalDimNo(DimensionValue);
        // [THEN] "Global Dimension No." = 0 for "Global Dimension 1 Code"
        GeneralLedgerSetup.Get();
        DimensionSetEntry.Get(DimSetId, GeneralLedgerSetup."Global Dimension 1 Code");
        DimensionSetEntry.TestField("Global Dimension No.", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifyDimSetEntryGlobalDimNoUT()
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        DimensionValue: array[6] of Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimSetId: Integer;
    begin
        // [SCENARIO 396220] Modify(true) dimension set entry
        Initialize();

        // [GIVEN] General ledger setup with shortcut dimensions
        CreateShortcutDimensions(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);
        // [GIVEN] Corrupted dimension set entry
        DimSetId := CreateCorruptedDimSetEntry(DimensionValue);

        // [WHEN] Modify(true) dimension set entry
        DimensionSetEntry.SetRange("Dimension Set ID", DimSetId);
        DimensionSetEntry.FindSet();
        repeat
            DimensionSetEntry.Modify(true);
        until DimensionSetEntry.Next() = 0;

        // [THEN] "Global Dimension No." filled accordingly G/L setup
        VerifyDimSetEntryGlobalDimNo(DimensionValue);
        // [THEN] "Global Dimension No." = 0 for "Global Dimension 1 Code"
        GeneralLedgerSetup.Get();
        DimensionSetEntry.Get(DimSetId, GeneralLedgerSetup."Global Dimension 1 Code");
        DimensionSetEntry.TestField("Global Dimension No.", 0);
        // [THEN] "Global Dimension No." = 0 for "Global Dimension 2 Code"
        DimensionSetEntry.Get(DimSetId, GeneralLedgerSetup."Global Dimension 2 Code");
        DimensionSetEntry.TestField("Global Dimension No.", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FixDimSetEntryGlobalDimNoSpecialSymbolsCodeunitUT()
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        DimensionValue: array[6] of Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimSetId: Integer;
    begin
        // [SCENARIO] Fix "Global Dimension No." in Dimension Set Entry table with dimensions containing special symbols ('& <> | () %')
        Initialize();

        // [GIVEN] Corrupted "Global Dimension No." in Dimension Set Entry with dimensions containing special symbols
        CreateSpecialSymbShortcutDimensions(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);
        DimSetId := CreateCorruptedDimSetEntry(DimensionValue);

        // [WHEN] Run fix "Global Dimension No." procedure
        Codeunit.Run(Codeunit::"Update Dim. Set Glbl. Dim. No.");

        // [THEN] "Global Dimension No." corrected accordingly G/L setup
        VerifyDimSetEntryGlobalDimNo(DimensionValue);
        // [THEN] "Global Dimension No." = 0 for "Global Dimension 1 Code"
        GeneralLedgerSetup.Get();
        DimensionSetEntry.Get(DimSetId, GeneralLedgerSetup."Global Dimension 1 Code");
        DimensionSetEntry.TestField("Global Dimension No.", 0);
        // [THEN] "Global Dimension No." = 0 for "Global Dimension 2 Code"
        DimensionSetEntry.Get(DimSetId, GeneralLedgerSetup."Global Dimension 2 Code");
        DimensionSetEntry.TestField("Global Dimension No.", 0);
        // [THEN] "Global Dimension No." = 0 for non shortcut dimension set entries
        VerifyNonShrtcutDimSetEntryGlobalDimNo(DimSetId);
        // [THEN] Change log entries are created
        VerifyChangeLogEntry(DimSetId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderSubformDescriptionUpdateDimShortcuts()
    var
        PurchHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        Item: Record Item;
        DimensionValue: array[6] of Record "Dimension Value";
        PurchOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO 412920] [Purchase Order] [UI]
        // [GIVEN] Purchase order subform dimension shortcuts updated when Description validated
        Initialize();

        // [GIVEN] General ledger setup with shortcut dimensions SD3-SD8
        CreateShortcutDimensions(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);

        // [GIVEN] Vendor V with default dimensions SD3-SD8
        CreateVendorWithDefaultDimension(Vendor, DimensionValue);
        // [GIVEN] Item I with description "XXX"
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Purchase order for vendor V
        LibraryPurchase.CreatePurchHeader(PurchHeader, "Purchase Document Type"::Order, Vendor."No.");

        // [GIVEN] Open page Purchase Order
        PurchOrder.OpenEdit();
        PurchOrder.Filter.SetFilter("No.", PurchHeader."No.");

        // [WHEN] Validate line Description with "XXX"
        PurchOrder.PurchLines.New();
        PurchOrder.PurchLines.Type.SetValue("Purchase Line Type"::Item);
        PurchOrder.PurchLines.Description.SetValue(Item.Description);

        // [THEN] Purchase line has shortcut dimensions SD3-SD8
        PurchOrder.PurchLines.ShortcutDimCode3.AssertEquals(DimensionValue[1].Code);
        PurchOrder.PurchLines.ShortcutDimCode4.AssertEquals(DimensionValue[2].Code);
        PurchOrder.PurchLines.ShortcutDimCode5.AssertEquals(DimensionValue[3].Code);
        PurchOrder.PurchLines.ShortcutDimCode6.AssertEquals(DimensionValue[4].Code);
        PurchOrder.PurchLines.ShortcutDimCode7.AssertEquals(DimensionValue[5].Code);
        PurchOrder.PurchLines.ShortcutDimCode8.AssertEquals(DimensionValue[6].Code);
        PurchOrder.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchReturnOrderSubformDescriptionUpdateDimShortcuts()
    var
        PurchHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        Item: Record Item;
        DimensionValue: array[6] of Record "Dimension Value";
        PurchReturnOrder: TestPage "Purchase Return Order";
    begin
        // [SCENARIO 412920] [Purchase Return Order] [UI]
        // [GIVEN] Purchase return order subform dimension shortcuts updated when Description validated
        Initialize();

        // [GIVEN] General ledger setup with shortcut dimensions SD3-SD8
        CreateShortcutDimensions(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);

        // [GIVEN] Vendor V with default dimensions SD3-SD8
        CreateVendorWithDefaultDimension(Vendor, DimensionValue);
        // [GIVEN] Item I with description "XXX"
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Purchase return order for vendor V
        LibraryPurchase.CreatePurchHeader(PurchHeader, "Purchase Document Type"::"Return Order", Vendor."No.");

        // [GIVEN] Open page Purchase Return Order
        PurchReturnOrder.OpenEdit();
        PurchReturnOrder.Filter.SetFilter("No.", PurchHeader."No.");

        // [WHEN] Validate line Description with "XXX"
        PurchReturnOrder.PurchLines.New();
        PurchReturnOrder.PurchLines.Type.SetValue("Purchase Line Type"::Item);
        PurchReturnOrder.PurchLines.Description.SetValue(Item.Description);

        // [THEN] Purchase line has shortcut dimensions SD3-SD8
        PurchReturnOrder.PurchLines.ShortcutDimCode3.AssertEquals(DimensionValue[1].Code);
        PurchReturnOrder.PurchLines.ShortcutDimCode4.AssertEquals(DimensionValue[2].Code);
        PurchReturnOrder.PurchLines.ShortcutDimCode5.AssertEquals(DimensionValue[3].Code);
        PurchReturnOrder.PurchLines.ShortcutDimCode6.AssertEquals(DimensionValue[4].Code);
        PurchReturnOrder.PurchLines.ShortcutDimCode7.AssertEquals(DimensionValue[5].Code);
        PurchReturnOrder.PurchLines.ShortcutDimCode8.AssertEquals(DimensionValue[6].Code);
        PurchReturnOrder.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchQuoteSubformDescriptionUpdateDimShortcuts()
    var
        PurchHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        Item: Record Item;
        DimensionValue: array[6] of Record "Dimension Value";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [SCENARIO 412920] [Purchase Quote] [UI]
        // [GIVEN] Purchase quote subform dimension shortcuts updated when Description validated
        Initialize();

        // [GIVEN] General ledger setup with shortcut dimensions SD3-SD8
        CreateShortcutDimensions(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);

        // [GIVEN] Vendor V with default dimensions SD3-SD8
        CreateVendorWithDefaultDimension(Vendor, DimensionValue);
        // [GIVEN] Item I with description "XXX"
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Purchase quote for vendor V
        LibraryPurchase.CreatePurchHeader(PurchHeader, "Purchase Document Type"::Quote, Vendor."No.");

        // [GIVEN] Open page Purchase Quote
        PurchaseQuote.OpenEdit();
        PurchaseQuote.Filter.SetFilter("No.", PurchHeader."No.");

        // [WHEN] Validate line Description with "XXX"
        PurchaseQuote.PurchLines.New();
        PurchaseQuote.PurchLines.Type.SetValue("Purchase Line Type"::Item);
        PurchaseQuote.PurchLines.Description.SetValue(Item.Description);

        // [THEN] Purchase line has shortcut dimensions SD3-SD8
        PurchaseQuote.PurchLines.ShortcutDimCode3.AssertEquals(DimensionValue[1].Code);
        PurchaseQuote.PurchLines.ShortcutDimCode4.AssertEquals(DimensionValue[2].Code);
        PurchaseQuote.PurchLines.ShortcutDimCode5.AssertEquals(DimensionValue[3].Code);
        PurchaseQuote.PurchLines.ShortcutDimCode6.AssertEquals(DimensionValue[4].Code);
        PurchaseQuote.PurchLines.ShortcutDimCode7.AssertEquals(DimensionValue[5].Code);
        PurchaseQuote.PurchLines.ShortcutDimCode8.AssertEquals(DimensionValue[6].Code);
        PurchaseQuote.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure VerifyDimensionsAreUpdatedOnSalesLineOnChangeSalespersonOnSalesHeader()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        SalespersonPurchaser, SalespersonPurchaser2 : Record "Salesperson/Purchaser";
        SalespersonDimensionValue: Record "Dimension Value";
        DimensionValue: array[6] of Record "Dimension Value";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO 469349] Verify dimensions are updated on sales line on change salesperson on sales header
        // [GIVEN] Initial state
        Initialize();

        // [GIVEN] General ledger setup with shortcut dimensions SD3-SD8
        CreateShortcutDimensions(DimensionValue);
        SetGLSetupShortcutDimensionsAll(DimensionValue);

        // [GIVEN] Create Customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create Salesperson with default dimension
        CreateSalespersonWithDefaultDim(SalespersonPurchaser, DimensionValue[1]."Dimension Code", DimensionValue[1].Code);

        // [GIVEN] Create Salesperson with default dimension
        LibraryDimension.CreateDimensionValue(SalespersonDimensionValue, DimensionValue[1]."Dimension Code");
        CreateSalespersonWithDefaultDim(SalespersonPurchaser2, SalespersonDimensionValue."Dimension Code", SalespersonDimensionValue.Code);

        // [GIVEN] Add Salesperson to Customer
        Customer."Salesperson Code" := SalespersonPurchaser.Code;
        Customer.Modify(true);

        // [GIVEN] Item I with description "XXX"
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create sales document
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [GIVEN] Open Sales Order
        SalesOrder.OpenEdit();
        SalesOrder.Filter.SetFilter("No.", SalesHeader."No.");

        // [GIVEN] Create new Sales Order Line        
        SalesOrder.SalesLines.New();
        SalesOrder.SalesLines.Type.SetValue("Sales Line Type"::Item);
        SalesOrder.SalesLines."No.".SetValue(Item."No.");

        // [WHEN] Update Salesperson on Sales Order
        SalesOrder."Salesperson Code".SetValue(SalespersonPurchaser2.Code);

        // [THEN] Verify that Sales Order Lines has shortcut dimension SD3       
        SalesOrder.SalesLines.ShortcutDimCode3.AssertEquals(SalespersonDimensionValue.Code);
        SalesOrder.Close();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Dimension Shortcuts");
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Dimension Shortcuts");

        IsInitialized := true;
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Dimension Shortcuts");
    end;

    local procedure AssignGLSetupShortcuts(DimShortcuts: array[6] of Boolean)
    var
        Dimension: Record Dimension;
        GLSetup: Record "General Ledger Setup";
        DimIndex: Integer;
    begin
        GLSetup.Get();
        for DimIndex := 1 to 6 do
            if DimShortcuts[DimIndex] then begin
                LibraryDimension.CreateDimension(Dimension);
                case DimIndex of
                    1:
                        GLSetup.Validate("Shortcut Dimension 3 Code", Dimension.Code);
                    2:
                        GLSetup.Validate("Shortcut Dimension 4 Code", Dimension.Code);
                    3:
                        GLSetup.Validate("Shortcut Dimension 5 Code", Dimension.Code);
                    4:
                        GLSetup.Validate("Shortcut Dimension 6 Code", Dimension.Code);
                    5:
                        GLSetup.Validate("Shortcut Dimension 7 Code", Dimension.Code);
                    6:
                        GLSetup.Validate("Shortcut Dimension 8 Code", Dimension.Code);
                end;
            end;

        GLSetup.Modify();
    end;

    local procedure AssertVisibility(DimNo: Integer; ShortcutVisible: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
        UseSetupShortcut: Boolean;
    begin
        GLSetup.Get();
        case DimNo of
            1:
                UseSetupShortcut := GLSetup."Shortcut Dimension 1 Code" <> '';
            2:
                UseSetupShortcut := GLSetup."Shortcut Dimension 2 Code" <> '';
            3:
                UseSetupShortcut := GLSetup."Shortcut Dimension 3 Code" <> '';
            4:
                UseSetupShortcut := GLSetup."Shortcut Dimension 4 Code" <> '';
            5:
                UseSetupShortcut := GLSetup."Shortcut Dimension 5 Code" <> '';
            6:
                UseSetupShortcut := GLSetup."Shortcut Dimension 6 Code" <> '';
            7:
                UseSetupShortcut := GLSetup."Shortcut Dimension 7 Code" <> '';
            8:
                UseSetupShortcut := GLSetup."Shortcut Dimension 8 Code" <> '';
        end;
        if UseSetupShortcut then
            Assert.AreEqual(ShortcutVisible, UseSetupShortcut, StrSubstNo('Dim Shortcut %1 must be visible', DimNo))
        else
            Assert.AreEqual(ShortcutVisible, UseSetupShortcut, StrSubstNo('Dim Shortcut %1 must not be visible', DimNo));
    end;

    local procedure ClearDimShortcuts()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.Validate("Shortcut Dimension 3 Code", '');
        GLSetup.Validate("Shortcut Dimension 4 Code", '');
        GLSetup.Validate("Shortcut Dimension 5 Code", '');
        GLSetup.Validate("Shortcut Dimension 6 Code", '');
        GLSetup.Validate("Shortcut Dimension 7 Code", '');
        GLSetup.Validate("Shortcut Dimension 8 Code", '');
        GLSetup.Modify();
    end;

    local procedure CreateVendorWithDefaultDimension(var Vendor: Record Vendor; DimensionValue: array[6] of Record "Dimension Value")
    var
        DefaultDimension: Record "Default Dimension";
        i: Integer;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        for i := 1 to 6 do
            LibraryDimension.CreateDefaultDimensionVendor(DefaultDimension, Vendor."No.", DimensionValue[i]."Dimension Code", DimensionValue[i].Code);
    end;

    local procedure RemoveTempBatches()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalBatch.SetFilter(Name, StrSubstNo('%1*', TempBatchNameTxt));
        GenJournalBatch.DeleteAll(true);
    end;

    local procedure SetGLSetupAllDimensions()
    var
        GLSetup: Record "General Ledger Setup";
        Dimension: Record Dimension;
    begin
        GLSetup.Get();
        LibraryDimension.CreateDimension(Dimension);
        GLSetup.Validate("Shortcut Dimension 3 Code", Dimension.Code);
        LibraryDimension.CreateDimension(Dimension);
        GLSetup.Validate("Shortcut Dimension 4 Code", Dimension.Code);
        LibraryDimension.CreateDimension(Dimension);
        GLSetup.Validate("Shortcut Dimension 5 Code", Dimension.Code);
        LibraryDimension.CreateDimension(Dimension);
        GLSetup.Validate("Shortcut Dimension 6 Code", Dimension.Code);
        LibraryDimension.CreateDimension(Dimension);
        GLSetup.Validate("Shortcut Dimension 7 Code", Dimension.Code);
        LibraryDimension.CreateDimension(Dimension);
        GLSetup.Validate("Shortcut Dimension 8 Code", Dimension.Code);
        GLSetup.Modify();
    end;

    local procedure CreateShortcutDimensions(var DimensionValue: array[6] of Record "Dimension Value")
    var
        i: Integer;
    begin
        for i := 1 to 6 do
            LibraryDimension.CreateDimWithDimValue(DimensionValue[i]);
    end;

    local procedure CreateDimSet(DimensionValue: array[6] of Record "Dimension Value"): Integer
    var
        TempDimensionSetEntry: Record "Dimension Set Entry" temporary;
        DimensionManagement: Codeunit DimensionManagement;
        i: Integer;
    begin
        for i := 1 to 6 do begin
            TempDimensionSetEntry.Init();
            TempDimensionSetEntry."Dimension Code" := DimensionValue[i]."Dimension Code";
            TempDimensionSetEntry."Dimension Value Code" := DimensionValue[i].Code;
            TempDimensionSetEntry."Dimension Value ID" := DimensionValue[i]."Dimension Value ID";
            TempDimensionSetEntry.Insert();
        end;

        exit(DimensionManagement.GetDimensionSetID(TempDimensionSetEntry));
    end;

    local procedure CreateDimSet(DimensionValue: Record "Dimension Value"): Integer
    var
        TempDimensionSetEntry: Record "Dimension Set Entry" temporary;
        DimensionManagement: Codeunit DimensionManagement;
    begin
        TempDimensionSetEntry.Init();
        TempDimensionSetEntry."Dimension Code" := DimensionValue."Dimension Code";
        TempDimensionSetEntry."Dimension Value Code" := DimensionValue.Code;
        TempDimensionSetEntry."Dimension Value ID" := DimensionValue."Dimension Value ID";
        TempDimensionSetEntry.Insert();

        exit(DimensionManagement.GetDimensionSetID(TempDimensionSetEntry));
    end;

    local procedure SetGLSetupShortcutDimensionsAll(DimensionValue: array[6] of Record "Dimension Value")
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.Validate("Shortcut Dimension 3 Code", DimensionValue[1]."Dimension Code");
        GLSetup.Validate("Shortcut Dimension 4 Code", DimensionValue[2]."Dimension Code");
        GLSetup.Validate("Shortcut Dimension 5 Code", DimensionValue[3]."Dimension Code");
        GLSetup.Validate("Shortcut Dimension 6 Code", DimensionValue[4]."Dimension Code");
        GLSetup.Validate("Shortcut Dimension 7 Code", DimensionValue[5]."Dimension Code");
        GLSetup.Validate("Shortcut Dimension 8 Code", DimensionValue[6]."Dimension Code");
        GLSetup.Modify();
    end;

    local procedure SetGLSetupShortcutDimensionsSelected(DimensionValue: array[6] of Record "Dimension Value")
    var
        GLSetup: Record "General Ledger Setup";
        ShortcutDimNo: array[6] of Boolean;
        i: Integer;
    begin
        ShortcutDimNo[LibraryRandom.RandIntInRange(1, 6)] := true;
        ShortcutDimNo[LibraryRandom.RandIntInRange(1, 6)] := true;
        ShortcutDimNo[LibraryRandom.RandIntInRange(1, 6)] := true;

        GLSetup.Get();
        for i := 1 to 6 do
            if ShortcutDimNo[i] then
                case i of
                    1:
                        GLSetup.Validate("Shortcut Dimension 3 Code", DimensionValue[1]."Dimension Code");
                    2:
                        GLSetup.Validate("Shortcut Dimension 4 Code", DimensionValue[2]."Dimension Code");
                    3:
                        GLSetup.Validate("Shortcut Dimension 5 Code", DimensionValue[3]."Dimension Code");
                    4:
                        GLSetup.Validate("Shortcut Dimension 6 Code", DimensionValue[4]."Dimension Code");
                    5:
                        GLSetup.Validate("Shortcut Dimension 7 Code", DimensionValue[5]."Dimension Code");
                    6:
                        GLSetup.Validate("Shortcut Dimension 8 Code", DimensionValue[6]."Dimension Code");
                end;
        GLSetup.Modify();
    end;

    local procedure CreateGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", AccountNo,
            GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), Amount);
        GenJournalLine."Document No." := CopyStr(LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Document No."), Database::"Gen. Journal Line"), 1, 20);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateRecurringGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
    begin
        LibraryERM.FindRecurringTemplateName(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Recurring := true;
        GenJournalBatch.Modify(true);
        GenJournalBatch.SetupNewBatch();
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", AccountNo, 0);
        GenJournalLine."Document No." := CopyStr(LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Document No."), Database::"Gen. Journal Line"), 1, 20);
        GenJournalLine."Recurring Method" := GenJournalLine."Recurring Method"::"BD Balance by Dimension";
        Evaluate(GenJournalLine."Recurring Frequency", '<1M>');
        GenJournalLine.Modify(true);

        LibraryERM.CreateGenJnlAllocation(GenJnlAllocation, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
        GenJnlAllocation.Validate("Account No.", LibraryERM.CreateGLAccountNo());
        GenJnlAllocation.Validate("Allocation %", 100);
        GenJnlAllocation.Modify(true);
    end;

    local procedure CreateTwoRecurringGenJnlLines(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; AccountNo2: Code[20])
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
    begin
        LibraryERM.FindRecurringTemplateName(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Recurring := true;
        GenJournalBatch.Modify(true);
        GenJournalBatch.SetupNewBatch();

        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", AccountNo, 0);
        GenJournalLine."Document No." := CopyStr(LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Document No."), Database::"Gen. Journal Line"), 1, 20);
        GenJournalLine."Recurring Method" := GenJournalLine."Recurring Method"::"BD Balance by Dimension";
        Evaluate(GenJournalLine."Recurring Frequency", '<1M>');
        GenJournalLine.Modify(true);

        LibraryERM.CreateGenJnlAllocation(GenJnlAllocation, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
        GenJnlAllocation.Validate("Account No.", LibraryERM.CreateGLAccountNo());
        GenJnlAllocation.Validate("Allocation %", 100);
        GenJnlAllocation.Modify(true);

        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"G/L Account", AccountNo2, 0);
        GenJournalLine."Document No." := CopyStr(LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("Document No."), Database::"Gen. Journal Line"), 1, 20);
        GenJournalLine."Recurring Method" := GenJournalLine."Recurring Method"::"BD Balance by Dimension";
        Evaluate(GenJournalLine."Recurring Frequency", '<1M>');
        GenJournalLine.Modify(true);

        LibraryERM.CreateGenJnlAllocation(GenJnlAllocation, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
        GenJnlAllocation.Validate("Account No.", LibraryERM.CreateGLAccountNo());
        GenJnlAllocation.Validate("Allocation %", 100);
        GenJnlAllocation.Modify(true);
    end;

    local procedure CreateGenJnlDimFilter(RecurringGenJournalLine: Record "Gen. Journal Line"; DimensionValue: Record "Dimension Value")
    var
        GenJnlDimFilter: Record "Gen. Jnl. Dim. Filter";
    begin
        GenJnlDimFilter.Init();
        GenJnlDimFilter."Journal Template Name" := RecurringGenJournalLine."Journal Template Name";
        GenJnlDimFilter."Journal Batch Name" := RecurringGenJournalLine."Journal Batch Name";
        GenJnlDimFilter."Journal Line No." := RecurringGenJournalLine."Line No.";
        GenJnlDimFilter."Dimension Code" := DimensionValue."Dimension Code";
        GenJnlDimFilter."Dimension Value Filter" := DimensionValue.Code;
        GenJnlDimFilter.Insert();
    end;

    local procedure CreateCorruptedDimSetEntry(var DimensionValue: array[6] of Record "Dimension Value"): Integer
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GlobalDimensionValue: array[2] of Record "Dimension Value";
        DimensionSetEntry: Record "Dimension Set Entry";
        AdditionalDimensionValue: Record "Dimension Value";
        DimSetId: Integer;
        i: Integer;
    begin
        GeneralLedgerSetup.Get();
        DimSetId := GetDimSetId();

        for i := 1 to 6 do begin
            DimensionSetEntry."Dimension Set ID" := DimSetId;
            DimensionSetEntry."Dimension Code" := DimensionValue[i]."Dimension Code";
            DimensionSetEntry."Dimension Value Code" := DimensionValue[i].Code;
            DimensionSetEntry."Global Dimension No." := 100;
            DimensionSetEntry.Insert(false);
        end;

        LibraryDimension.CreateDimensionValue(GlobalDimensionValue[1], GeneralLedgerSetup."Global Dimension 1 Code");
        DimensionSetEntry."Dimension Set ID" := DimSetId;
        DimensionSetEntry."Dimension Code" := GlobalDimensionValue[1]."Dimension Code";
        DimensionSetEntry."Dimension Value Code" := GlobalDimensionValue[1].Code;
        DimensionSetEntry."Global Dimension No." := 1;
        DimensionSetEntry.Insert(false);

        LibraryDimension.CreateDimensionValue(GlobalDimensionValue[2], GeneralLedgerSetup."Global Dimension 2 Code");
        DimensionSetEntry."Dimension Set ID" := DimSetId;
        DimensionSetEntry."Dimension Code" := GlobalDimensionValue[2]."Dimension Code";
        DimensionSetEntry."Dimension Value Code" := GlobalDimensionValue[2].Code;
        DimensionSetEntry."Global Dimension No." := 2;
        DimensionSetEntry.Insert(false);

        LibraryDimension.CreateDimWithDimValue(AdditionalDimensionValue);
        DimensionSetEntry."Dimension Set ID" := DimSetId;
        DimensionSetEntry."Dimension Code" := AdditionalDimensionValue."Dimension Code";
        DimensionSetEntry."Dimension Value Code" := AdditionalDimensionValue.Code;
        DimensionSetEntry."Global Dimension No." := 100;
        DimensionSetEntry.Insert(false);
        exit(DimSetId);
    end;

    local procedure GetDimSetId(): Integer
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        if DimensionSetEntry.FindLast() then
            exit(DimensionSetEntry."Dimension Set ID" + 1);

        exit(1);
    end;

    local procedure CreateSpecialSymbShortcutDimensions(var DimensionValue: array[6] of Record "Dimension Value")
    var
        Dimension: Record Dimension;
    begin
        Dimension.Init();
        Dimension.Validate(Code, '% ABC %');
        Dimension.Insert(true);
        LibraryDimension.CreateDimensionValue(DimensionValue[1], Dimension.Code);

        Dimension.Init();
        Dimension.Validate(Code, '(ABC) ABC (ABC)');
        Dimension.Insert(true);
        LibraryDimension.CreateDimensionValue(DimensionValue[2], Dimension.Code);

        Dimension.Init();
        Dimension.Validate(Code, '& ABC &');
        Dimension.Insert(true);
        LibraryDimension.CreateDimensionValue(DimensionValue[3], Dimension.Code);

        Dimension.Init();
        Dimension.Validate(Code, '| ABC |');
        Dimension.Insert(true);
        LibraryDimension.CreateDimensionValue(DimensionValue[4], Dimension.Code);

        Dimension.Init();
        Dimension.Validate(Code, '<> ABC <>');
        Dimension.Insert(true);
        LibraryDimension.CreateDimensionValue(DimensionValue[5], Dimension.Code);

        Dimension.Init();
        Dimension.Validate(Code, '& < % ( | ) % > &');
        Dimension.Insert(true);
        LibraryDimension.CreateDimensionValue(DimensionValue[6], Dimension.Code);
    end;

    local procedure VerifyEntryShortcutDimensions(RecVar: Variant; DimensionValue: array[6] of Record "Dimension Value")
    var
        GLSetup: Record "General Ledger Setup";
        RecRef: RecordRef;
        FldRef: FieldRef;
        i: Integer;
    begin
        RecRef.GetTable(RecVar);

        GLSetup.Get();

        for i := 481 to 486 do begin
            FldRef := RecRef.Field(i);
            case i of
                481:
                    if GLSetup."Shortcut Dimension 3 Code" <> '' then
                        Assert.AreEqual(DimensionValue[1].Code, FldRef.Value, 'Incorrect shortcut dimension 3 code value')
                    else
                        Assert.AreEqual('', FldRef.Value, 'Shortcut dimension 3 code should be empty');
                482:
                    if GLSetup."Shortcut Dimension 4 Code" <> '' then
                        Assert.AreEqual(DimensionValue[2].Code, FldRef.Value, 'Incorrect shortcut dimension 4 code value')
                    else
                        Assert.AreEqual('', FldRef.Value, 'Shortcut dimension 4 code should be empty');
                483:
                    if GLSetup."Shortcut Dimension 5 Code" <> '' then
                        Assert.AreEqual(DimensionValue[3].Code, FldRef.Value, 'Incorrect shortcut dimension 5 code value')
                    else
                        Assert.AreEqual('', FldRef.Value, 'Shortcut dimension 5 code should be empty');
                484:
                    if GLSetup."Shortcut Dimension 6 Code" <> '' then
                        Assert.AreEqual(DimensionValue[4].Code, FldRef.Value, 'Incorrect shortcut dimension 6 code value')
                    else
                        Assert.AreEqual('', FldRef.Value, 'Shortcut dimension 6 code should be empty');
                485:
                    if GLSetup."Shortcut Dimension 7 Code" <> '' then
                        Assert.AreEqual(DimensionValue[5].Code, FldRef.Value, 'Incorrect shortcut dimension 7 code value')
                    else
                        Assert.AreEqual('', FldRef.Value, 'Shortcut dimension 7 code should be empty');
                486:
                    if GLSetup."Shortcut Dimension 8 Code" <> '' then
                        Assert.AreEqual(DimensionValue[6].Code, FldRef.Value, 'Incorrect shortcut dimension 8 code value')
                    else
                        Assert.AreEqual('', FldRef.Value, 'Shortcut dimension 8 code should be empty');
            end;
        end;
    end;

    local procedure VerifyDimSetEntryGlobalDimNo(DimensionValue: array[6] of Record "Dimension Value")
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        i: Integer;
    begin
        for i := 1 to 6 do begin
            DimensionSetEntry.SetRange("Dimension Code", DimensionValue[i]."Dimension Code");
            DimensionSetEntry.FindFirst();
            Assert.RecordCount(DimensionSetEntry, 1);
            Assert.AreEqual(i + 2, DimensionSetEntry."Global Dimension No.", 'Global Dimension No is wrong');
        end;
    end;

    local procedure VerifyNonShrtcutDimSetEntryGlobalDimNo(DimSetId: Integer)
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        DimensionSetEntry.SetRange("Dimension Set ID", DimSetId);
        DimensionSetEntry.SetFilter(
            "Dimension Code", '<>%1&<>%2&<>%3&<>%4&<>%5&<>%6&<>%7&<>%8',
            GeneralLedgerSetup."Shortcut Dimension 1 Code", GeneralLedgerSetup."Shortcut Dimension 2 Code",
            GeneralLedgerSetup."Shortcut Dimension 3 Code", GeneralLedgerSetup."Shortcut Dimension 4 Code",
            GeneralLedgerSetup."Shortcut Dimension 5 Code", GeneralLedgerSetup."Shortcut Dimension 6 Code",
            GeneralLedgerSetup."Shortcut Dimension 7 Code", GeneralLedgerSetup."Shortcut Dimension 8 Code");
        DimensionSetEntry.FindFirst();
        Assert.RecordCount(DimensionSetEntry, 1);
        DimensionSetEntry.TestField("Global Dimension No.", 0);
    end;

    local procedure VerifyChangeLogEntry(DimSetId: Integer)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionSetEntry: Record "Dimension Set Entry";
        ChangeLogEntry: Record "Change Log Entry";
    begin
        GeneralLedgerSetup.Get();
        ChangeLogEntry.SetRange("Table No.", 480);

        DimensionSetEntry.SetRange("Dimension Set ID", DimSetId);
        DimensionSetEntry.SetFilter("Global Dimension No.", '>0');
        DimensionSetEntry.FindSet();
        repeat
            ChangeLogEntry.SetRange("Record ID", DimensionSetEntry.RecordId);
            ChangeLogEntry.FindFirst();
            Assert.RecordCount(ChangeLogEntry, 1);
            case DimensionSetEntry."Dimension Code" of
                GeneralLedgerSetup."Shortcut Dimension 3 Code":
                    ChangeLogEntry.TestField("New Value", '3');
                GeneralLedgerSetup."Shortcut Dimension 4 Code":
                    ChangeLogEntry.TestField("New Value", '4');
                GeneralLedgerSetup."Shortcut Dimension 5 Code":
                    ChangeLogEntry.TestField("New Value", '5');
                GeneralLedgerSetup."Shortcut Dimension 6 Code":
                    ChangeLogEntry.TestField("New Value", '6');
                GeneralLedgerSetup."Shortcut Dimension 7 Code":
                    ChangeLogEntry.TestField("New Value", '7');
                GeneralLedgerSetup."Shortcut Dimension 8 Code":
                    ChangeLogEntry.TestField("New Value", '8');
                else
                    ChangeLogEntry.TestField("New Value", '0');
            end;
        until DimensionSetEntry.Next() = 0;
    end;

    local procedure VerifyGLEntrySingleDim(DimSetId: Integer; GLAccountNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.SetRange("Dimension Set ID", DimSetId);
        Assert.RecordCount(GLEntry, 2);
        GLEntry.CalcSums(Amount);
        Assert.IsTrue(GLEntry.Amount = 0, 'Wrong balance');
    end;

    local procedure CreateSalespersonWithDefaultDim(var SalespersonPurchaser: Record "Salesperson/Purchaser"; DimensionCode: Code[20]; DimensionValueCode: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, Database::"Salesperson/Purchaser", SalespersonPurchaser.Code, DimensionCode, DimensionValueCode);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        if Question = KeepExistingDimensionsMsg then
            Reply := false;
        if Question = UpdateDimensionOnLineMsg then
            Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;

    [ModalPageHandler]
    procedure EditDimensionSetEntriesHandler(var EditDimensionSetEntries: TestPage "Edit Dimension Set Entries")
    var
        DimensionValue: Record "Dimension Value";
        i: Integer;
    begin
        for i := 1 to 6 do begin
            DimensionValue.SetRange("Dimension Code", LibraryVariableStorage.DequeueText());
            DimensionValue.FindFirst();

            EditDimensionSetEntries.New();
            EditDimensionSetEntries."Dimension Code".Value(DimensionValue."Dimension Code");
            EditDimensionSetEntries.DimensionValueCode.Value(DimensionValue.Code);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Gen. Journal Batch", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertGenJournalBatch(var Rec: Record "Gen. Journal Batch"; RunTrigger: Boolean);
    begin
        if Rec.IsTemporary then
            exit;
        if CopyStr(Rec.Name, 1, 7) = TempBatchNameTxt then
            Assert.AreEqual(StrSubstNo('#%1#%2#', ServiceInstanceId(), SessionId()), Rec.Description, 'Temp batch Description');
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure UpdateDimSetGlblDimNoReqPageHandler(var UpdateDimSetGlblDimNo: TestRequestPage "Update Dim. Set Glbl. Dim. No.")
    begin
        UpdateDimSetGlblDimNo.OK().Invoke();
    end;
}

