codeunit 134475 "ERM Dimension Sales"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Dimension] [Sales]
        IsInitialized := false;
    end;

    var
        StandardCustomerSalesCode: Record "Standard Customer Sales Code";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibrarySales: Codeunit "Library - Sales";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        DimensionHeaderErr: Label 'The dimensions used in %1 %2 are invalid', Locked = true;
        DimensionLineErr: Label 'The dimensions used in %1 %2, line no. %3 are invalid', Locked = true;
        DimensionValueCodeErr: Label '%1 must be %2.', Comment = '%1 = dimension value field, %2 = dimension value code';
        DimSetEntryFilterErr: Label 'There is no Dimension Set Entry within the filter.';
        UpdateAutomaticCostMsg: Label 'The field Automatic Cost Posting should not be set to Yes if field Use Legacy G/L Entry Locking in General Ledger Setup table is set to No because of possibility of deadlocks.';
        UpdateAutomaticCostPeriodMsg: Label 'Some unadjusted value entries will not be covered with the new setting.';
        NoSalesInvoiceDocWithDimSetIDErr: Label 'There is no Sales Invoice with Dimension Set ID = %1', Comment = '%1 = dimension set ID';
        SalesInvoiceDocCntErr: Label 'Wrong number of created Sales Invoices.';
        UpdateFromHeaderLinesQst: Label 'You may have changed a dimension.\\Do you want to update the lines?';
        UpdateLineDimQst: Label 'You have changed one or more dimensions on the';

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure DimensionUpdateOnLine()
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        TempDimensionSetEntry: Record "Dimension Set Entry" temporary;
        DimensionValueCode: Code[20];
        ShortcutDimensionCode: Code[20];
        DimensionSetID: Integer;
    begin
        // [SCENARIO] Test Dimension on Sales Line updated successfully after updation of Dimension on Sales Header.

        // [GIVEN] Create Customer, Item, Sales Header with Dimension and Sales Line, Change Dimension Value for Sales Header Dimension
        // and Select Yes on Confirmation message occurs for updating Dimension on Sales Line.
        Initialize();
        CreateSalesOrderWithDimension(TempDimensionSetEntry, DimensionValueCode, ShortcutDimensionCode, DimensionSetID);

        // [THEN] Verify Dimension Set Entry and Dimension on Sales Line successfully updated.
        VerifyDimensionSetEntry(TempDimensionSetEntry, DimensionSetID);

        FindDimensionSetEntry(DimensionSetEntry, ShortcutDimensionCode, DimensionSetID);
        DimensionSetEntry.TestField("Dimension Value Code", DimensionValueCode);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure DimensionNotUpdateOnLine()
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        TempDimensionSetEntry: Record "Dimension Set Entry" temporary;
        DimensionValueCode: Code[20];
        ShortcutDimensionCode: Code[20];
        DimensionSetID: Integer;
    begin
        // [SCENARIO] Test Dimension on Sales Line not updated after updation of Dimension on Sales Header.

        // [GIVEN] Create Customer, Item, Sales Header with Dimension and Sales Line, Change Dimension Value for Sales Header Dimension
        // and Select No on Confirmation message occurs for updating Dimension on Sales Line.
        Initialize();
        CreateSalesOrderWithDimension(TempDimensionSetEntry, DimensionValueCode, ShortcutDimensionCode, DimensionSetID);

        // [THEN] Verify Dimension Set Entry and Dimension on Sales Line not updated.
        VerifyDimensionSetEntry(TempDimensionSetEntry, DimensionSetID);

        FindDimensionSetEntry(DimensionSetEntry, ShortcutDimensionCode, DimensionSetID);
        Assert.AreNotEqual(
          DimensionValueCode,
          DimensionSetEntry."Dimension Value Code",
          StrSubstNo(
            DimensionValueCodeErr, DimensionSetEntry.FieldCaption("Dimension Value Code"), DimensionSetEntry."Dimension Value Code"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValuePostingRuleOnHeader()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
    begin
        // [SCENARIO] Test error occurs on Posting Sales Invoice with Invalid Dimension On Sales Header.

        // [GIVEN] Create Customer with Default Dimension, Item, Sales Header and Update value of Dimension on Sales Header.
        Initialize();
        LibraryDimension.FindDimension(Dimension);
        CreateSalesOrder(
          SalesHeader, SalesLine, Dimension.Code, '', DefaultDimension."Value Posting"::"Same Code", SalesHeader."Document Type"::Invoice);
        UpdateDimensionOnSalesHeader(SalesHeader);
        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::Customer, SalesHeader."Sell-to Customer No.");

        // [WHEN] Post Sales Invoice.
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        asserterror LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // [THEN] Verify error occurs "Invalid Dimension" on Posting Sales Invoice.
        Assert.ExpectedError(
          StrSubstNo(DimensionHeaderErr, SalesHeader."Document Type", SalesHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValuePostingRuleOnLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
    begin
        // [SCENARIO] Test error occurs on Posting Sales Invoice with Invalid Dimension On Sales Line.

        // [GIVEN] Create Customer, Item with Default Dimension, Sales Header and Update value of Dimension on Sales Line.
        Initialize();
        LibraryDimension.FindDimension(Dimension);
        CreateSalesOrder(
          SalesHeader, SalesLine, '', Dimension.Code, DefaultDimension."Value Posting"::"Same Code", SalesHeader."Document Type"::Invoice);
        UpdateDimensionOnSalesLine(SalesLine);
        LibraryDimension.FindDefaultDimension(DefaultDimension, DATABASE::Item, SalesLine."No.");

        // [WHEN] Post Sales Invoice.
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        asserterror LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // [THEN] Verify error occurs "Invalid Dimension" on Posting Sales Invoice.
        Assert.ExpectedError(
          StrSubstNo(DimensionLineErr, SalesHeader."Document Type", SalesHeader."No.", SalesLine."Line No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderFromQuoteWithDimension()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        DimensionSetIdHeader: Integer;
        DimensionSetIdLine: Integer;
    begin
        // [SCENARIO] Test Dimension on Sales Order Created from Sales Quote.

        // [GIVEN] Stockout warning False on Sales and Receivable Setup, Create Customer and Item with Default Dimension, Sales Order.
        Initialize();
        LibrarySales.SetStockoutWarning(false);
        LibraryDimension.FindDimension(Dimension);
        CreateSalesOrder(
          SalesHeader, SalesLine, Dimension.Code, FindDifferentDimension(Dimension.Code), DefaultDimension."Value Posting"::" ",
          SalesHeader."Document Type"::Quote);
        DimensionSetIdHeader := SalesHeader."Dimension Set ID";
        DimensionSetIdLine := SalesLine."Dimension Set ID";

        // [WHEN] Convert Sales Quote to Order.
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Order", SalesHeader);

        // [THEN] Verify Dimension on created Sales Header and Sales Line.
        FindSalesOrder(SalesHeader, SalesHeader."No.");
        SalesHeader.TestField("Dimension Set ID", DimensionSetIdHeader);

        FindSalesLine(SalesLine, SalesHeader);
        SalesLine.TestField("Dimension Set ID", DimensionSetIdLine);

        // 4. Teardown: Rollback Stockout warning on Sales and Receivable Setup.
        LibrarySales.SetStockoutWarning(true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CombineShipment()
    var
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        CustNo: Code[20];
    begin
        // [SCENARIO] Test Dimension on Sales Line created from Combine Shipment.

        // [GIVEN] Create Customer, Item with Default Dimension, Two Sales Order with Combine Shipment True and Post both as Ship.
        Initialize();
        CustNo := CreateCustWithCombShip();
        CreateAndPostSalesOrder(SalesLine, CustNo);
        CreateAndPostSalesOrder(SalesLine2, CustNo);

        // [WHEN] Run Combine Shipments Report.
        RunCombineShipment(SalesLine."Sell-to Customer No.");

        // [THEN] Verify Dimension on Sales Line created after Combine Shipment.
        VerifySalesLineDimension(SalesLine);
        VerifySalesLineDimension(SalesLine2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryDimension()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Test Dimension on G/L Entry after Posting Sales Invoice.

        // [GIVEN] Create Customer, Items and Sales Invoice for different Items.
        Initialize();
        LibraryDimension.FindDimension(Dimension);
        CreateSalesOrder(
          SalesHeader, SalesLine, '', Dimension.Code, DefaultDimension."Value Posting"::" ", SalesHeader."Document Type"::Invoice);

        // Use Random because value is not important.
        LibrarySales.CreateSalesLine(
          SalesLine2, SalesHeader, SalesLine2.Type::Item,
          CreateItemWithDimension(FindDifferentDimension(Dimension.Code), DefaultDimension."Value Posting"::" "),
          LibraryRandom.RandDec(10, 2));

        // [WHEN] Post the Sales Invoice.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // [THEN] Verify Dimension on G/L Entry.
        VerifyGLEntryDimension(SalesLine, DocumentNo);
        VerifyGLEntryDimension(SalesLine2, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeDimensionAfterPartial()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Test Dimension on G/L Entry after Posting Sales Order in Multiple Steps with Change Dimension Value on Sales Line.

        // [GIVEN] Create Customer, Item, Create and Post Sales Order Partially.
        Initialize();
        LibraryDimension.FindDimension(Dimension);
        CreateSalesOrder(
          SalesHeader, SalesLine, '', Dimension.Code, DefaultDimension."Value Posting"::" ", SalesHeader."Document Type"::Order);
        UpdatePartialQuantityToShip(SalesLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Update Dimension Value on Sales Line Dimension and Post Sales Order.
        UpdateDimensionOnSalesLine(SalesLine);
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Verify Dimension on G/L Entry.
        VerifyGLEntryDimension(SalesLine, DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeShortcutDimensionInvoice()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        // [SCENARIO] Test Sales Header Dimension after change Shortcut Dimension 2 Code on Sales Invoice Header.

        // [GIVEN] Create Customer.
        Initialize();
        GeneralLedgerSetup.Get();
        LibrarySales.CreateCustomer(Customer);

        // [WHEN] Create Sales Header and Update Shortcut Dimension 2 Code on Sales Header.
        LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Shortcut Dimension 2 Code");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Shortcut Dimension 2 Code", DimensionValue.Code);
        SalesHeader.Modify(true);

        // [THEN] Verify Sales Header Dimension.
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, SalesHeader."Dimension Set ID");
        DimensionSetEntry.TestField("Dimension Code", GeneralLedgerSetup."Shortcut Dimension 2 Code");
        DimensionSetEntry.TestField("Dimension Value Code", SalesHeader."Shortcut Dimension 2 Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopyDocumentWithDimension()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Test Dimension on Sales Invoice Created from Copy Document.

        // [GIVEN] Set Stockout warning False on Sales and Receivable Setup, Create Customer with Default Dimension, Item,
        // Create and Post Sales Order.
        Initialize();
        LibrarySales.SetStockoutWarning(false);
        LibraryDimension.FindDimension(Dimension);
        CreateSalesOrder(
          SalesHeader, SalesLine, Dimension.Code, FindDifferentDimension(Dimension.Code), DefaultDimension."Value Posting"::" ",
          SalesHeader."Document Type"::Order);
        UpdatePartialQuantityToShip(SalesLine);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);
        SalesShipmentHeader.Get(DocumentNo);

        // [WHEN] Create Sales Invoice through Copy Document.
        Clear(SalesHeader);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, SalesLine."Sell-to Customer No.");
        RunCopySalesDocument(SalesHeader, SalesShipmentHeader."No.");

        // [THEN] Verify Dimension on Sales Header and Sales Line.
        SalesHeader.TestField("Dimension Set ID", SalesShipmentHeader."Dimension Set ID");
        SalesLine.SetFilter(Type, '<>''''');
        FindSalesLine(SalesLine, SalesHeader);
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        SalesShipmentLine.FindFirst();
        SalesLine.TestField("Dimension Set ID", SalesShipmentLine."Dimension Set ID");

        // 4. Teardown: Rollback Stockout warning on Sales and Receivable Setup.
        LibrarySales.SetStockoutWarning(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionOnInvoiceRounding()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
    begin
        // [SCENARIO] Test Dimension on G/L Entry of Invoice Rounding.

        // [GIVEN] Update Inv. Rounding Precision (LCY) on General Ledger Setup, Create Customer with Default Dimension, Item,
        // Create Sales Invoice and Update Line Amount on Sales Line.
        Initialize();
        LibraryDimension.FindDimension(Dimension);

        LibraryERM.SetInvRoundingPrecisionLCY(0.1);

        CreateSalesOrder(
          SalesHeader, SalesLine, Dimension.Code, '', DefaultDimension."Value Posting"::" ", SalesHeader."Document Type"::Invoice);
        UpdateInvoiceAmountForRounding(SalesLine);

        // [WHEN] Post Sales Invoice.
        LibrarySales.PostSalesDocument(SalesHeader, false, false);

        // [THEN] Verify Dimension on G/L Entry of Invoice Rounding.
        VerifyDimensionOnRoundingEntry(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandler')]
    [Scope('OnPrem')]
    procedure ArchiveDocument()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        // [SCENARIO] Test Dimension on Archive Sales Order.

        // [GIVEN] Create Customer with Default Dimension, Item, Sales Order.
        Initialize();
        LibraryDimension.FindDimension(Dimension);
        CreateSalesOrder(
          SalesHeader, SalesLine, Dimension.Code, '', DefaultDimension."Value Posting"::" ", SalesHeader."Document Type"::Order);

        // [WHEN] Create Archive Sales Order.
        ArchiveManagement.ArchiveSalesDocument(SalesHeader);

        // [THEN] Verify Dimension on Archive Sales Order.
        VerifyDimensionOnArchiveHeader(SalesHeader);
        VerifyDimensionOnArchiveLine(SalesLine);
    end;

    [Test]
    [HandlerFunctions('SalesCodePageHandler')]
    [Scope('OnPrem')]
    procedure DimensionStandardSalesCode()
    var
        Item: Record Item;
        Dimension: Record Dimension;
        StandardSalesLine: Record "Standard Sales Line";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        DifferentDimensionCode: Code[20];
    begin
        // [SCENARIO] Test Dimension on Standard Sales Code.

        // [GIVEN] Create Item and find Dimension.
        Initialize();
        LibraryDimension.FindDimension(Dimension);
        CreateItemWithExtendedText(Item, Dimension.Code);

        // [WHEN] Create Customer, GL Account, Standard Sales Code, Standard Sales Line and Standard Customer Sales Code.
        DifferentDimensionCode :=
          CreateStandardSalesDocument(
            StandardSalesLine, Dimension.Code, Item."No.", CreateGLAccountWithDimension(Dimension.Code, Item."VAT Prod. Posting Group"));
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerSalesCode(StandardCustomerSalesCode, Customer."No.", StandardSalesLine."Standard Sales Code");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        StandardCustomerSalesCode.InsertSalesLines(SalesHeader);

        // [THEN] Verify that Line Dimensions copied from Standard Sales Line.
        VerifyDimensionCode(StandardSalesLine."Dimension Set ID", DifferentDimensionCode);
    end;

    [Test]
    [HandlerFunctions('SalesCodePageHandler')]
    [Scope('OnPrem')]
    procedure DimensionOnCustomerAndStandardSalesCode()
    var
        Item: Record Item;
        Dimension: Record Dimension;
        Customer: Record Customer;
        StandardSalesLine: Record "Standard Sales Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DefaultDimension: Record "Default Dimension";
        StandardSalesCode: Record "Standard Sales Code";
        DifferentDimensionCode: Code[20];
    begin
        // [SCENARIO] Test Dimensions are "merged" between the ones coming from Standard Sales Code and Sales Header (customer)

        // [GIVEN] Create Item and customer with dimensions
        Initialize();
        LibraryDimension.FindDimension(Dimension);
        CreateItemWithExtendedText(Item, Dimension.Code);
        DifferentDimensionCode := FindDifferentDimension(Dimension.Code);
        Customer.Get(CreateCustomerWithDimension(DefaultDimension, DefaultDimension."Value Posting", DifferentDimensionCode));

        // Create Standard Codes and sales header
        LibrarySales.CreateStandardSalesCode(StandardSalesCode);
        CreateStandardSalesLine(StandardSalesLine, StandardSalesCode.Code, StandardSalesLine.Type::Item, Item."No.");
        UpdateDimensionSetID(StandardSalesLine, Dimension.Code);
        LibrarySales.CreateCustomerSalesCode(StandardCustomerSalesCode, Customer."No.", StandardSalesLine."Standard Sales Code");

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [WHEN]
        StandardCustomerSalesCode.InsertSalesLines(SalesHeader);

        // [THEN] Verify that sales Line Dimensions are copied from Standard Sales Line and header
        FindSalesLine(SalesLine, SalesHeader);
        VerifyDimensionCode(SalesLine."Dimension Set ID", Dimension.Code);
        VerifyDimensionCode(SalesLine."Dimension Set ID", DefaultDimension."Dimension Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLineDimension()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DefaultDimension: Record "Default Dimension";
        DefaultDimension2: Record "Default Dimension";
        SalesLine: Record "Sales Line";
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        // [SCENARIO] Check Sales Line Dimension.

        // [GIVEN]
        Initialize();

        // [WHEN] Create Sales Credit Memo.
        GeneralLedgerSetup.Get();
        CreateSalesDocument(SalesLine, SetGLAccountDefaultDimension(DefaultDimension, GeneralLedgerSetup."Global Dimension 1 Code"),
          CreateCustomerWithDimension(DefaultDimension2, DefaultDimension."Value Posting", GeneralLedgerSetup."Global Dimension 1 Code"));

        // [THEN] Verify Dimension Value on Sales Line.
        DimensionSetEntry.Get(SalesLine."Dimension Set ID", GeneralLedgerSetup."Global Dimension 1 Code");
        DimensionSetEntry.TestField("Dimension Value Code", SalesLine."Shortcut Dimension 1 Code");

        // Tear Down: Remove Default Dimension from G/L Account.
        DeleteDefaultDimension(DefaultDimension);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntryDimensionsForSales()
    var
        Customer: Record Customer;
        GeneralLedgerSetup: Record "General Ledger Setup";
        GLAccount: Record "G/L Account";
        DefaultDimension: Record "Default Dimension";
        DefaultDimension2: Record "Default Dimension";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedDocumentNo: Code[20];
    begin
        // [SCENARIO] Test Dimension on G/L Entry after posting Sales document with IC Partner.

        // [GIVEN] Set Default Dimension for G/L Account and Create Sales Credit Memo.
        Initialize();
        GeneralLedgerSetup.Get();
        Customer.Get(
          CreateCustomerWithDimension(
            DefaultDimension2, DefaultDimension."Value Posting", GeneralLedgerSetup."Global Dimension 1 Code"));
        GLAccount.Get(SetGLAccountDefaultDimension(DefaultDimension, GeneralLedgerSetup."Global Dimension 1 Code"));
        GLAccount."VAT Bus. Posting Group" := Customer."VAT Bus. Posting Group";
        GLAccount.Modify();
        CreateSalesDocument(SalesLine, GLAccount."No.", Customer."No.");

        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("IC Partner Code", LibraryERM.CreateICPartnerNo());
        SalesLine.Validate("IC Partner Reference", FindICGLAccount());
        SalesLine.Modify(true);

        // [WHEN] Post Sales Credit Memo.
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Verify Dimension Value and IC Partner Code on GL Entry.
        VerifyGLEntryICPartner(PostedDocumentNo, SalesLine."IC Partner Code", DefaultDimension."Dimension Value Code");

        // Tear Down: Remove Default Dimension from G/L Account.
        DeleteDefaultDimension(DefaultDimension);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DimensionAfterApplyForCustomer()
    var
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO] Test Dimension on G/L Entry after Apply from Customer Ledger Entry.

        // [GIVEN] Find Dimension, Create and Post General Journal Line.
        Initialize();
        LibraryDimension.FindDimension(Dimension);
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Account Type"::Customer,
          CreateCustomerWithDimension(DefaultDimension, DefaultDimension."Value Posting"::" ", Dimension.Code),
          LibraryRandom.RandDec(100, 2));

        // [WHEN] Apply Payment from Customer Ledger Entry.
        ApplyAndPostCustomerEntry(GenJournalLine."Document No.", GenJournalLine.Amount, GenJournalLine."Document Type");

        // [THEN] Verify Dimension on G/L Entry.
        VerifyGLEntry(GenJournalLine."Document No.", Dimension.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure ChangeSalesRetOrdDim()
    var
        DefaultDimension: Record "Default Dimension";
        DimensionSetEntry: Record "Dimension Set Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] Test changed Sales Return Header Shortcut Dimension 1 Code.

        // [GIVEN] Create Sales Return Order.
        Initialize();
        GeneralLedgerSetup.Get();
        CreateSalesOrder(
          SalesHeader, SalesLine, GeneralLedgerSetup."Shortcut Dimension 1 Code", '', DefaultDimension."Value Posting"::"Same Code",
          SalesHeader."Document Type"::"Return Order");

        // [WHEN] Change Shortcut Dimension 2 Code on Sales Return Header.
        ChangeDimensionOnSalesHeader(SalesHeader, GeneralLedgerSetup."Shortcut Dimension 1 Code");

        // [THEN] Verify Sales Return Header Dimension.
        FindDimensionSetEntry(DimensionSetEntry, GeneralLedgerSetup."Shortcut Dimension 1 Code", SalesHeader."Dimension Set ID");
        DimensionSetEntry.TestField("Dimension Value Code", SalesHeader."Shortcut Dimension 1 Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure InsertSalesRetOrdDim()
    var
        DefaultDimension: Record "Default Dimension";
        DimensionSetEntry: Record "Dimension Set Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] Test inserted Sales Return Header Shortcut Dimension 2 Code.

        // [GIVEN] Create Sales Return Order.
        Initialize();
        GeneralLedgerSetup.Get();
        CreateSalesOrder(
          SalesHeader, SalesLine, GeneralLedgerSetup."Shortcut Dimension 1 Code", '', DefaultDimension."Value Posting"::"Same Code",
          SalesHeader."Document Type"::"Return Order");

        // [WHEN] Insert Shortcut Dimension 2 Code on Sales Return Header.
        InsertDimOnSalesHdr(SalesHeader, GeneralLedgerSetup."Shortcut Dimension 2 Code");

        // [THEN] Verify Sales Return Header Shortcut Dimension 2 Code.
        FindDimensionSetEntry(DimensionSetEntry, GeneralLedgerSetup."Shortcut Dimension 2 Code", SalesHeader."Dimension Set ID");
        DimensionSetEntry.TestField("Dimension Value Code", SalesHeader."Shortcut Dimension 2 Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure DeleteSalesRetOrdDimError()
    var
        DefaultDimension: Record "Default Dimension";
        DimensionSetEntry: Record "Dimension Set Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] Verify error while filtering Dimension Set Entry after deleting Sales Return Header Shortcut Dimension 1 Code.

        // [GIVEN] Create Sales Return Order, delete Shortcut Dimension 1 Code.
        Initialize();
        GeneralLedgerSetup.Get();
        CreateSalesOrder(
          SalesHeader, SalesLine, GeneralLedgerSetup."Shortcut Dimension 1 Code", '', DefaultDimension."Value Posting"::"Same Code",
          SalesHeader."Document Type"::"Return Order");
        SalesHeader.Validate("Shortcut Dimension 1 Code", '');  // Blank value for Shortcut Dimension 1 Code.
        SalesHeader.Modify(true);

        // [WHEN] Find Shortcut Dimension 1 Code in Dimension Set Entry.
        asserterror LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, SalesHeader."Dimension Set ID");

        // [THEN] Verify error of Dimension Set Entry.
        Assert.ExpectedError(DimSetEntryFilterErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderWithDefaultDimension()
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        Location: Record Location;
        DefaultDimension: Record "Default Dimension";
        SalesHeader: Record "Sales Header";
        GLEntry: Record "G/L Entry";
        PostedInvoiceNo: Code[20];
    begin
        // [SCENARIO] Verify GL Entry after post Sales Order with Dimension which attached as a Default Dimension on Inventory Account.

        // [GIVEN] Update Inventory Setup, create Item, create Location with Inventory Setup.
        Initialize();
        LibraryVariableStorage.Enqueue(UpdateAutomaticCostMsg);  // Enqueue for MessageHandler
        LibraryVariableStorage.Enqueue(UpdateAutomaticCostPeriodMsg);  // Enqueue for MessageHandler
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, true, false, InventorySetup."Automatic Cost Adjustment"::Always, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // Set Default Dimension on Inventory Accout, create Sales Order and post.
        SetInvGLAccountDefaultDimension(DefaultDimension, Location.Code, Item."Inventory Posting Group");
        CreateSalesDocumentWithLocation(
          SalesHeader, DefaultDimension."Dimension Value Code", Location.Code, Item."No.", LibraryRandom.RandInt(10));  // Using Random Int for Unit Price.

        // Exercise.
        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Verify GL Entry after post Sales Order with Dimension.
        VerifyDimensionOnGLEntry(
          GLEntry."Document Type"::Invoice, PostedInvoiceNo, GLEntry."Gen. Posting Type"::Sale, DefaultDimension."Dimension Value Code");
        VerifyDimensionOnGLEntry(
          GLEntry."Document Type"::Invoice, PostedInvoiceNo, GLEntry."Gen. Posting Type"::" ", DefaultDimension."Dimension Value Code");

        // Tear Down.
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Never, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");
        DeleteDefaultDimension(DefaultDimension);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PostPhysInvWithDefaultDimension()
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        Location: Record Location;
        DefaultDimension: Record "Default Dimension";
        SalesHeader: Record "Sales Header";
        GLEntry: Record "G/L Entry";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [SCENARIO] Verify GL Entry after post Physical Inventory Journal with Dimension which attached as a Default Dimension on Inventory Account.

        // [GIVEN] Update Inventory Setup, create Item, create Location with Inventory Setup.
        Initialize();
        LibraryVariableStorage.Enqueue(UpdateAutomaticCostMsg);  // Enqueue for MessageHandler
        LibraryVariableStorage.Enqueue(UpdateAutomaticCostPeriodMsg);  // Enqueue for MessageHandler
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, true, false, InventorySetup."Automatic Cost Adjustment"::Always, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        SetInvGLAccountDefaultDimension(DefaultDimension, Location.Code, Item."Inventory Posting Group");

        // Create Sales Order and Post, create Item Journal, Calculate Inventory.
        CreateSalesDocumentWithLocation(
          SalesHeader, DefaultDimension."Dimension Value Code", Location.Code, Item."No.", LibraryRandom.RandDec(10, 2));  // Using Random Dec for Unit Price.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        CreateItemJournalAndCalculateInventory(ItemJournalLine, Item."No.", DefaultDimension);

        // Exercise.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [THEN] Verify GL Entry after post Physical Inventory Journal with Dimension.
        VerifyDimensionOnGLEntry(
          GLEntry."Document Type"::" ", ItemJournalLine."Document No.", GLEntry."Gen. Posting Type"::" ",
          DefaultDimension."Dimension Value Code");

        // Tear Down.
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Never, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");
        DeleteDefaultDimension(DefaultDimension);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CombineShipmentsWithDifferentDimensions()
    var
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
        DimSetID: array[2] of Integer;
    begin
        // [SCENARIO 122222] Combine Shipment Report combines documents by dimensions
        Initialize();
        DimSetID[1] := CreateDimSetID();
        DimSetID[2] := CreateDimSetID();

        // [GIVEN] Customer with "Combine Shipments"=TRUE
        CustomerNo := CreateCustWithCombShip();

        // [GIVEN] Create and Ship Sales Order with DimSetID = "D1"
        // [GIVEN] Create and Ship Sales Order with DimSetID = "D2"
        CreateShipTwoSalesOrdersWithGivenDimSetID(CustomerNo, DimSetID);

        // [GIVEN] Create and Ship Sales Order with DimSetID = "D1"
        // [GIVEN] Create and Ship Sales Order with DimSetID = "D2"
        CreateShipTwoSalesOrdersWithGivenDimSetID(CustomerNo, DimSetID);

        // [WHEN] Run Combine Shipments Report
        RunCombineShipment(CustomerNo);

        // [THEN] Report has generated 2 new Invoices
        SalesHeader.SetRange("Bill-to Customer No.", CustomerNo);
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Invoice);
        Assert.AreEqual(2, SalesHeader.Count, SalesInvoiceDocCntErr);

        // [THEN] New Invoices have Dimension Set ID = "D1", "D2"
        SalesHeader.SetRange("Dimension Set ID", DimSetID[1]);
        Assert.IsFalse(SalesHeader.IsEmpty, StrSubstNo(NoSalesInvoiceDocWithDimSetIDErr, DimSetID[1]));

        SalesHeader.SetRange("Dimension Set ID", DimSetID[2]);
        Assert.IsFalse(SalesHeader.IsEmpty, StrSubstNo(NoSalesInvoiceDocWithDimSetIDErr, DimSetID[2]));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerForSalesHeaderDimUpdate')]
    [Scope('OnPrem')]
    procedure PartlyShippedLineDimChangeFromHeaderGlobalDimConfirmYes()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DimensionValue: Record "Dimension Value";
    begin
        // [FEATURE] [Partial Posting]
        Initialize();

        // [SCENARIO 378707] Sales Header Shortcut Dimension 1 Code change causes confirmation for partly shipped line
        // [GIVEN] Sales Order with partly shipped Item line
        CreatePartlyShipSalesOrder(SalesHeader, SalesLine);
        CreateGlobal1DimensionValue(DimensionValue);

        // [GIVEN] Sales Header Shortcut Dimension 1 Code is being changed to "NewDimValue"
        // [GIVEN] Answer Yes to confirm lines dimension update (first confirmation)
        LibraryVariableStorage.Enqueue(true); // to reply Yes on second confirmation
        SalesHeader.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);

        // [WHEN] Answer Yes on shipped line update confirmation
        // The reply is inside the handler ConfirmHandlerForSalesHeaderDimUpdate

        // [THEN] Sales Line dimension set contains "NewDimValue"
        SalesLine.Find();
        VerifyDimensionOnDimSet(SalesLine."Dimension Set ID", DimensionValue);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerForSalesHeaderDimUpdate')]
    [Scope('OnPrem')]
    procedure PartlyShippedLineDimChangeFromHeaderGlobalDimConfirmNo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DimensionValue: Record "Dimension Value";
        SavedDimSetID: Integer;
    begin
        // [FEATURE] [Partial Posting]
        // [SCENARIO 378707] Sales Header Shortcut Dimension 1 Code change causes confirmation for partly shipped line
        Initialize();

        // [GIVEN] Sales Order with partly shipped Item line with some initial value "InitialDimSetID"
        CreatePartlyShipSalesOrder(SalesHeader, SalesLine);
        SavedDimSetID := SalesLine."Dimension Set ID";
        CreateGlobal1DimensionValue(DimensionValue);

        // [GIVEN] Sales Header Shortcut Dimension 1 Code is being changed to "NewDimValue"
        // [GIVEN] Answer Yes to confirm lines dimension update (first confirmation)
        LibraryVariableStorage.Enqueue(false); // to reply No on second confirmation
        asserterror SalesHeader.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);

        // [WHEN] Answer No on shipped line update confirmation
        // The reply is inside the handler ConfirmHandlerForSalesHeaderDimUpdate

        // [THEN] Sales Line dimension set left "InitialDimSetID"
        SalesLine.Find();
        SalesLine.TestField("Dimension Set ID", SavedDimSetID);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerForSalesHeaderDimUpdate,EditDimensionSetEntriesHandler')]
    [Scope('OnPrem')]
    procedure PartlyShippedLineDimChangeFromHeaderDimSetPageConfirmYes()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DimensionValue: Record "Dimension Value";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Partial Posting]
        // [SCENARIO 378707] Sales Header dimension change from Edit Dimension Set Entries page causes confirmation for partly shipped line
        Initialize();

        // [GIVEN] Sales Order with partly shipped Item line
        CreatePartlyShipSalesOrder(SalesHeader, SalesLine);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);

        // [GIVEN] Sales Header dimension set is being updated in Edit Dimension Set Entries page
        // [GIVEN] Answer Yes to confirm lines dimension update (first confirmation)
        LibraryVariableStorage.Enqueue(DimensionValue."Dimension Code");
        LibraryVariableStorage.Enqueue(DimensionValue.Code);
        LibraryVariableStorage.Enqueue(true); // to reply Yes on second confirmation
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrder.Dimensions.Invoke();

        // [WHEN] Answer Yes on shipped line update confirmation
        // The reply is inside the handler ConfirmHandlerForSalesHeaderDimUpdate

        // [THEN] Sales Line dimension set contains "NewDimValue"
        SalesLine.Find();
        VerifyDimensionOnDimSet(SalesLine."Dimension Set ID", DimensionValue);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerForSalesHeaderDimUpdate,EditDimensionSetEntriesHandler')]
    [Scope('OnPrem')]
    procedure PartlyShippedLineDimChangeFromHeaderDimSetPageConfirmNo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DimensionValue: Record "Dimension Value";
        SalesOrder: TestPage "Sales Order";
        SavedDimSetID: Integer;
    begin
        // [FEATURE] [Partial Posting]
        // [SCENARIO 378707] Sales Header dimension change from Edit Dimension Set Entries page causes confirmation for partly shipped line
        Initialize();

        // [GIVEN] Sales Order with partly shipped Item line with some initial value "InitialDimSetID"
        CreatePartlyShipSalesOrder(SalesHeader, SalesLine);
        SavedDimSetID := SalesLine."Dimension Set ID";
        LibraryDimension.CreateDimWithDimValue(DimensionValue);

        // [GIVEN] Sales Header dimension set is being updated in Edit Dimension Set Entries page
        // [GIVEN] Answer Yes to confirm lines dimension update (first confirmation)
        LibraryVariableStorage.Enqueue(DimensionValue."Dimension Code");
        LibraryVariableStorage.Enqueue(DimensionValue.Code);
        LibraryVariableStorage.Enqueue(false); // to reply No on second confirmation
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        asserterror SalesOrder.Dimensions.Invoke();

        // [WHEN] Answer No on shipped line update confirmation
        // The reply is inside the handler ConfirmHandlerForSalesHeaderDimUpdate

        // [THEN] Sales Line dimension set left "InitialDimSetID"
        SalesLine.Find();
        SalesLine.TestField("Dimension Set ID", SavedDimSetID);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PartlyShippedLineDimChangeFromLineGlobalDimConfirmYes()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DimensionValue: Record "Dimension Value";
    begin
        // [FEATURE] [Partial Posting]
        // [SCENARIO 378707] Sales Line Shortcut Dimension 1 Code change causes confirmation for partly shipped line
        Initialize();

        // [GIVEN] Sales Order with partly shipped Item line
        CreatePartlyShipSalesOrder(SalesHeader, SalesLine);
        CreateGlobal1DimensionValue(DimensionValue);

        // [GIVEN] Sales Line Shortcut Dimension 1 Code is being changed to "NewDimValue"
        LibraryVariableStorage.Enqueue(true); // to reply Yes on second confirmation
        SalesLine.Find();
        SalesLine.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);

        // [WHEN] Answer Yes on shipped line update confirmation

        // [THEN] Sales Line dimension set contains "NewDimValue"
        VerifyDimensionOnDimSet(SalesLine."Dimension Set ID", DimensionValue);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure PartlyShippedLineDimChangeFromLineGlobalDimConfirmNo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DimensionValue: Record "Dimension Value";
        SavedDimSetID: Integer;
    begin
        // [FEATURE] [Partial Posting]
        // [SCENARIO 378707] Sales Line Shortcut Dimension 1 Code change causes confirmation for partly shipped line
        Initialize();

        // [GIVEN] Sales Order with partly shipped Item line with some initial value "InitialDimSetID"
        CreatePartlyShipSalesOrder(SalesHeader, SalesLine);
        SavedDimSetID := SalesLine."Dimension Set ID";
        CreateGlobal1DimensionValue(DimensionValue);

        // [GIVEN] Sales Line Shortcut Dimension 1 Code is being changed to "NewDimValue"
        LibraryVariableStorage.Enqueue(false); // to reply No on second confirmation
        SalesLine.Find();
        asserterror SalesLine.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);

        // [WHEN] Answer No on shipped line update confirmation

        // [THEN] Sales Line dimension set left "InitialDimSetID"
        SalesLine.TestField("Dimension Set ID", SavedDimSetID);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,EditDimensionSetEntriesHandler')]
    [Scope('OnPrem')]
    procedure PartlyShippedLineDimChangeFromLineDimSetPageConfirmYes()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DimensionValue: Record "Dimension Value";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Partial Posting]
        // [SCENARIO 378707] Sales Line dimension change from Edit Dimension Set Entries page causes confirmation for partly shipped line
        Initialize();

        // [GIVEN] Sales Order with partly shipped Item line
        CreatePartlyShipSalesOrder(SalesHeader, SalesLine);
        LibraryDimension.CreateDimWithDimValue(DimensionValue);

        // [GIVEN] Sales Line dimension set is being updated in Edit Dimension Set Entries page
        LibraryVariableStorage.Enqueue(DimensionValue."Dimension Code");
        LibraryVariableStorage.Enqueue(DimensionValue.Code);
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrder.SalesLines.First();
        SalesOrder.SalesLines.Dimensions.Invoke();

        // [WHEN] Answer Yes on shipped line update confirmation

        // [THEN] Sales Line dimension set contains "NewDimValue"
        SalesLine.Find();
        VerifyDimensionOnDimSet(SalesLine."Dimension Set ID", DimensionValue);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo,EditDimensionSetEntriesHandler')]
    [Scope('OnPrem')]
    procedure PartlyShippedLineDimChangeFromLineDimSetPageConfirmNo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DimensionValue: Record "Dimension Value";
        SalesOrder: TestPage "Sales Order";
        SavedDimSetID: Integer;
    begin
        // [FEATURE] [Partial Posting]
        // [SCENARIO 378707] Sales Line dimension change from Edit Dimension Set Entries page causes confirmation for partly shipped line
        Initialize();

        // [GIVEN] Sales Order with partly shipped Item line with some initial value "InitialDimSetID"
        CreatePartlyShipSalesOrder(SalesHeader, SalesLine);
        SavedDimSetID := SalesLine."Dimension Set ID";
        LibraryDimension.CreateDimWithDimValue(DimensionValue);

        // [GIVEN] Sales Line dimension set is being updated in Edit Dimension Set Entries page
        LibraryVariableStorage.Enqueue(DimensionValue."Dimension Code");
        LibraryVariableStorage.Enqueue(DimensionValue.Code);
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrder.SalesLines.First();
        asserterror SalesOrder.SalesLines.Dimensions.Invoke();

        // [WHEN] Answer No on shipped line update confirmation

        // [THEN] Sales Line dimension set left "InitialDimSetID"
        SalesLine.Find();
        SalesLine.TestField("Dimension Set ID", SavedDimSetID);
    end;

    [Test]
    procedure SalesInvoiceMultipleLinesAndDimensionsWithNormalVAT()
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [Reverse Charge VAT] [VAT] [Dimension] [Rounding]
        // [SCENARIO 378079] The system distributes the rounding remainder between the lines of the posted document when "VAT Calculation Type" = "Normal VAT"
        Initialize();

        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 23);
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);

        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale));

        CreateDocumentWith258and350Lines(SalesHeader, Customer, GLAccount);

        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        VATEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Assert.RecordCount(VATEntry, 5);

        VATEntry.CalcSums(Amount);
        VATEntry.TestField(Amount, -31.79);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceMultipleLinesAndDimensionsWithReverseChargeVAT()
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        VATEntry: Record "VAT Entry";
    begin
        // [FEATURE] [Reverse Charge VAT] [VAT] [Dimension] [Rounding]
        // [SCENARIO 378079] The system distributes the rounding remainder between the lines of the posted document when "VAT Calculation Type" = "Reverse Charge VAT"
        Initialize();

        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", 23);
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);

        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale));

        CreateDocumentWith258and350Lines(SalesHeader, Customer, GLAccount);

        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        VATEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Assert.RecordCount(VATEntry, 5);

        VATEntry.CalcSums(Amount);
        VATEntry.TestField(Amount, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceMultipleLinesAndDimensionsWithNormalVATFCY()
    var
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        VATEntry: Record "VAT Entry";
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        ExpectedVATAmount: array[5] of Decimal;
    begin
        // [FEATURE] [Reverse Charge VAT] [VAT] [Dimension] [Rounding] [FCY]
        // [SCENARIO 401316] System calculates VAT Amount in currency's values and then converts to LCY amounts for Normal VAT
        Initialize();

        CurrencyCode := CreateCurrencyWithRelationalExchangeRate(4.3976);

        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 23);
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);

        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale));

        CreateDocumentWith258and350Lines(SalesHeader, Customer, GLAccount);

        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        VATEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Assert.RecordCount(VATEntry, 5);

        VATEntry.CalcSums(Amount);
        VATEntry.TestField(Amount, -139.8);

        InitializeExpectedVATAmounts(ExpectedVATAmount, -35.4, -26.12, -26.08, -26.12, -26.08);
        VerifyVATEntriesAmount(VATPostingSetup."VAT Prod. Posting Group", DocumentNo, ExpectedVATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceMultipleLinesAndDimensionsWithReverseChargeVATFCY()
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        VATEntry: Record "VAT Entry";
        CurrencyCode: Code[10];
    begin
        // [FEATURE] [Reverse Charge VAT] [VAT] [Dimension] [Rounding] [FCY]
        // [SCENARIO 401316] System does not calculate VAT Amount for  Reverse Charge VAT
        Initialize();

        CurrencyCode := CreateCurrencyWithRelationalExchangeRate(4.3976);

        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT", 23);
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);

        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale));

        CreateDocumentWith258and350Lines(SalesHeader, Customer, GLAccount);

        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        VATEntry.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        VATEntry.CalcSums(Amount);
        VATEntry.TestField(Amount, 0);
    end;

    [Test]
    procedure VerifyDimensionsAreNotReInitializedIfDefaultDimensionDoesntExist()
    var
        Customer: Record Customer;
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
    begin
        // [SCENARIO 455039] Verify dimensions are not re-initialized on validate field if default dimensions does not exist
        Initialize();

        // [GIVEN] Create Customer with default global dimension value
        CreateCustomerWithDefaultGlobalDimValue(Customer, DimensionValue);

        // [GIVEN] Create Item without Default Dimension
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Location without Default Dimension
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Create Sales Order
        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", Item."No.");

        // [GIVEN] Update global dimension 1 on Sales Line
        UpdateGlobalDimensionOnSalesLine(SalesLine, DimensionValue2);

        // [WHEN] Change Location on Sales Line
        UpdateLocationOnSalesLine(SalesLine, Location.Code);

        // [VERIFY] Verify Dimensions are not re initialized on Sales Line
        VerifyDimensionOnSalesOrderLine(SalesHeader."Document Type", SalesHeader."No.", DimensionValue2."Dimension Code");
    end;

    [Test]
    procedure VerifyAccountTypeDefaultDimensionsIsPulledOnSalesLine()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DimensionValue: Record "Dimension Value";
    begin
        // [SCENARIO 465518] Verify Dimension Code is pulled from Account Type Def. Dimension to Sales Line, if Customer and Item doesn't have def. dimensions
        Initialize();

        // [GIVEN] Create Customer without default dimension
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create Item without Default Dimension
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Account Type Default Dimension for Item table
        CreateAccountTypeDefaultDimension(DimensionValue, Customer."No.", Database::Item);

        // [WHEN] Create Sales Order
        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", Item."No.");

        // [VERIFY] Verify Dimension are puled from Account Type to Sales Line
        Assert.AreEqual(SalesLine."Shortcut Dimension 1 Code", DimensionValue.Code,
            StrSubstNo(DimensionValueCodeErr, SalesLine.FieldCaption("Shortcut Dimension 1 Code"), DimensionValue.Code));
    end;

    [Test]
    [HandlerFunctions('ChangeDimensionConfirmHandler,ChangeLocationMessageHandler')]
    procedure VerifyDimensionsAreNotReInitializedIfLocationIsNotChanged()
    var
        Customer: Record Customer;
        Location: array[2] of Record Location;
        DimensionValue: array[2] of Record "Dimension Value";
        ShiptoAddress: array[2] of Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        i: Integer;
    begin
        // [SCENARIO 504598] Verify dimensions are not re-initialized from location on validatation of ship-to code if location is not changed
        Initialize();

        // [GIVEN] Create customer with global dimension 1 value
        CreateCustomerWithDefaultGlobalDimValue(Customer, DimensionValue[1]);

        //[GIVEN] Create one more dimension value for global dimension 1 code
        LibraryDimension.CreateDimensionValue(DimensionValue[2], LibraryERM.GetGlobalDimensionCode(1));

        // [GIVEN] Create two locations with two different global dimension 1 values
        // [GIVEN] Create two shipping addresses with the locations for the customer
        for i := 1 to 2 do begin
            CreateLocationWithDefaultGlobalDimensionValue(Location[i], DimensionValue[i]);
            CreateShipToAddressWithLocation(ShiptoAddress[i], Customer."No.", Location[i].Code);
        end;

        // [GIVEN] Create sales order, global dimnesion 1 value is coppied from the customer
        CreateSalesOrder(SalesHeader, SalesLine, Customer."No.", '');

        // [GIVEN] Change global dimension 1 value on sales header
        ChangeDimensionOnDocument(SalesHeader, DimensionValue[2].Code); // ChangeDimensionConfirmHandler

        // [GIVEN] Change ship-to code on sales header and location code is coppied from ship-to address
        SalesHeader.Validate("Ship-to Code", ShiptoAddress[1].Code);

        // [GIVEN] Change location code on sales header
        SalesHeader.Validate("Location Code", Location[2].Code);

        // [WHEN] Change ship-to code with the same location code on sales header
        SalesHeader.Validate("Ship-to Code", ShiptoAddress[2].Code);

        // [THEN] Verify dimensions are not re-initialized on sales header and sales lines
        VerifyDimensionOnSalesOrder(SalesHeader, DimensionValue[2]."Dimension Code");
    end;

    local procedure Initialize()
    var
        ICSetup: Record "IC Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Dimension Sales");
        if not ICSetup.Get() then begin
            ICSetup.Init();
            ICSetup.Insert();
        end;
        ICSetup."Auto. Send Transactions" := false;
        ICSetup.Modify();
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Dimension Sales");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        IsInitialized := true;
        Commit();

        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Dimension Sales");
    end;

    local procedure ApplyAndPostCustomerEntry(DocumentNo: Code[20]; AmountToApply: Decimal; DocumentType: Enum "Gen. Journal Document Type")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, AmountToApply);
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry2, CustLedgerEntry2."Document Type"::Invoice, DocumentNo);
        CustLedgerEntry2.FindSet();
        repeat
            CustLedgerEntry2.CalcFields("Remaining Amount");
            CustLedgerEntry2.Validate("Amount to Apply", CustLedgerEntry2."Remaining Amount");
            CustLedgerEntry2.Modify(true);
        until CustLedgerEntry2.Next() = 0;

        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    local procedure InitializeExpectedVATAmounts(var ExpectedVATAmount: array[5] of Decimal; Amount1: Decimal; Amount2: Decimal; Amount3: Decimal; Amount4: Decimal; Amount5: Decimal)
    begin
        ExpectedVATAmount[1] := Amount1;
        ExpectedVATAmount[2] := Amount2;
        ExpectedVATAmount[3] := Amount3;
        ExpectedVATAmount[4] := Amount4;
        ExpectedVATAmount[5] := Amount5;
    end;

    local procedure ChangeDimensionOnSalesHeader(var SalesHeader: Record "Sales Header"; ShortcutDimensionCode: Code[20])
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        // Update Dimension value on Sales Header.
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, SalesHeader."Dimension Set ID");
        DimensionSetEntry.SetRange("Dimension Code", ShortcutDimensionCode);
        DimensionSetEntry.FindFirst();
        SalesHeader.Validate(
          "Shortcut Dimension 1 Code",
          FindDifferentDimensionValue(DimensionSetEntry."Dimension Code", DimensionSetEntry."Dimension Value Code"));
        SalesHeader.Modify(true);
    end;

    local procedure CreateDocumentWith258and350Lines(var SalesHeader: Record "Sales Header"; var Customer: Record Customer; var GLAccount: Record "G/L Account")
    var
        DimensionValue: array[5] of Record "Dimension Value";
        SalesLine: array[5] of Record "Sales Line";
        Index: Integer;
    begin
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        for Index := 2 to ArrayLen(DimensionValue) do
            LibraryDimension.CreateDimensionValue(DimensionValue[Index], DimensionValue[1]."Dimension Code");

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        for Index := 1 to ArrayLen(DimensionValue) do begin
            LibrarySales.CreateSalesLine(SalesLine[Index], SalesHeader, SalesLine[Index].Type::"G/L Account", GLAccount."No.", 1);
            SalesLine[Index].Validate("Shortcut Dimension 1 Code", DimensionValue[Index].Code);
            SalesLine[Index].Validate("Unit Price", 25.8);
            SalesLine[Index].Modify(true);
        end;

        SalesLine[Index].Validate("Unit Price", 35.0);
        SalesLine[Index].Modify(true);
    end;

    local procedure CreateCurrencyWithRelationalExchangeRate(RelationalExchangeRate: Decimal): Code[10]
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, WorkDate());
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 1);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", RelationalExchangeRate);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", 1);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", RelationalExchangeRate);
        CurrencyExchangeRate.Modify(true);

        exit(Currency.Code);
    end;

    local procedure CopyDimensionSetEntry(var TempDimensionSetEntry: Record "Dimension Set Entry" temporary; var DimensionSetEntry: Record "Dimension Set Entry")
    begin
        repeat
            TempDimensionSetEntry := DimensionSetEntry;
            TempDimensionSetEntry.Insert();
        until DimensionSetEntry.Next() = 0;
    end;

    local procedure CreateItemJournalAndCalculateInventory(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; DefaultDimension: Record "Default Dimension")
    var
        ItemJournalBatch: Record "Item Journal Batch";
        NoSeries: Codeunit "No. Series";
    begin
        // Find Item journal Batch and create Item Journal and Calculate Inventory.
        SelectAndClearItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::"Phys. Inventory");
        ItemJournalLine.Init();
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        LibraryInventory.CalculateInventoryForSingleItem(ItemJournalLine, ItemNo, WorkDate(), true, false);

        // Find created Item Journal Line.
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindFirst();

        // Update Item Journal Line and attach Dimension.
        ItemJournalLine.Validate(
          "Document No.", NoSeries.PeekNextNo(ItemJournalBatch."No. Series", ItemJournalLine."Posting Date"));
        ItemJournalLine.Validate("Qty. (Phys. Inventory)", 0);
        ItemJournalLine.Validate("Unit Amount", LibraryRandom.RandDec(10, 2));
        ItemJournalLine.Validate(
          "Dimension Set ID",
          LibraryDimension.CreateDimSet(
            ItemJournalLine."Dimension Set ID", DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code"));
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateAndPostSalesOrder(var SalesLine: Record "Sales Line"; CustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        Dimension: Record Dimension;
        DefaultDimension: Record "Default Dimension";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);

        // Use Random because value is not important.
        LibraryDimension.FindDimension(Dimension);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          CreateItemWithDimension(Dimension.Code, DefaultDimension."Value Posting"::" "), LibraryRandom.RandDec(10, 2));

        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure CreateShipTwoSalesOrdersWithGivenDimSetID(CustomerNo: Code[20]; DimSetIDs: array[2] of Integer)
    begin
        CreateShipSalesOrderWithDimSetID(CustomerNo, DimSetIDs[1]);
        CreateShipSalesOrderWithDimSetID(CustomerNo, DimSetIDs[2]);
    end;

    local procedure CreateShipSalesOrderWithDimSetID(CustomerNo: Code[20]; DimSetID: Integer)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Dimension Set ID", DimSetID);
        SalesHeader.Modify();

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(100, 2));

        LibrarySales.PostSalesDocument(SalesHeader, true, false); // Ship
    end;

    local procedure CreateCustomerWithDimension(var DefaultDimension: Record "Default Dimension"; ValuePosting: Enum "Default Dimension Value Posting Type"; DimensionCode: Code[20]): Code[20]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Customer: Record Customer;
        DimensionValue: Record "Dimension Value";
    begin
        LibrarySales.CreateCustomer(Customer);
        if DimensionCode = '' then
            exit(Customer."No.");
        LibraryDimension.FindDimensionValue(DimensionValue, DimensionCode);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, Customer."No.", DimensionCode, DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", ValuePosting);
        DefaultDimension.Modify(true);
        // another default dimension causing no error
        GeneralLedgerSetup.Get();
        if DimensionCode <> GeneralLedgerSetup."Shortcut Dimension 1 Code" then begin
            LibraryDimension.CreateDimWithDimValue(DimensionValue);
            LibraryDimension.CreateDefaultDimensionCustomer(
              DefaultDimension, Customer."No.", DimensionValue."Dimension Code", DimensionValue.Code);
            DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
            DefaultDimension.Modify(true);
        end;
        exit(Customer."No.");
    end;

    local procedure CreateDimensionSetEntry(var DimensionSetID: Integer; ShortcutDimensionCode: Code[20])
    var
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.FindDimensionValue(DimensionValue, FindDifferentDimension(ShortcutDimensionCode));
        DimensionSetID := LibraryDimension.CreateDimSet(DimensionSetID, DimensionValue."Dimension Code", DimensionValue.Code);

        LibraryDimension.FindDimensionValue(DimensionValue, ShortcutDimensionCode);
        DimensionSetID := LibraryDimension.CreateDimSet(DimensionSetID, ShortcutDimensionCode, DimensionValue.Code);
    end;

    local procedure CreateDimensionSetEntryHeader(var SalesHeader: Record "Sales Header"; ShortcutDimensionCode: Code[20])
    var
        DimensionSetID: Integer;
    begin
        DimensionSetID := SalesHeader."Dimension Set ID";
        CreateDimensionSetEntry(DimensionSetID, ShortcutDimensionCode);
        SalesHeader.Validate("Dimension Set ID", DimensionSetID);
        SalesHeader.Modify(true);
    end;

    local procedure CreateDimensionSetEntryLine(var SalesLine: Record "Sales Line"; ShortcutDimensionCode: Code[20])
    var
        DimensionSetID: Integer;
    begin
        DimensionSetID := SalesLine."Dimension Set ID";
        CreateDimensionSetEntry(DimensionSetID, ShortcutDimensionCode);
        SalesLine.Validate("Dimension Set ID", DimensionSetID);
        SalesLine.Modify(true);
    end;

    local procedure CreateItemWithDimension(DimensionCode: Code[20]; ValuePosting: Enum "Default Dimension Value Posting Type") ItemNo: Code[20]
    var
        Item: Record Item;
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
    begin
        LibraryInventory.CreateItem(Item);
        // Use Random because value is not important.
        Item.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        Item.Modify(true);
        ItemNo := Item."No.";
        if DimensionCode = '' then
            exit;
        LibraryDimension.FindDimensionValue(DimensionValue, DimensionCode);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, Item."No.", DimensionCode, DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", ValuePosting);
        DefaultDimension.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerDimensionCode: Code[20]; ItemDimensionCode: Code[20]; ValuePosting: Enum "Default Dimension Value Posting Type"; DocumentType: Enum "Sales Document Type")
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader, DocumentType, CreateCustomerWithDimension(DefaultDimension, ValuePosting, CustomerDimensionCode));

        // Use Random because value is not important.
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItemWithDimension(ItemDimensionCode, ValuePosting),
          LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateSalesOrderWithDimension(var TempDimensionSetEntry: Record "Dimension Set Entry" temporary; var DimensionValueCode: Code[20]; var ShortcutDimensionCode: Code[20]; var DimensionSetID: Integer)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        DefaultDimension: Record "Default Dimension";
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        // [GIVEN] Create Customer, Item, Sales Header and Sales Line with Dimension.
        GeneralLedgerSetup.Get();
        ShortcutDimensionCode := GeneralLedgerSetup."Shortcut Dimension 1 Code";
        CreateSalesOrder(SalesHeader, SalesLine, '', '', DefaultDimension."Value Posting"::" ", SalesHeader."Document Type"::Order);
        CreateDimensionSetEntryHeader(SalesHeader, ShortcutDimensionCode);
        CreateDimensionSetEntryLine(SalesLine, ShortcutDimensionCode);

        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, SalesLine."Dimension Set ID");
        CopyDimensionSetEntry(TempDimensionSetEntry, DimensionSetEntry);
        TempDimensionSetEntry.SetFilter("Dimension Code", '<>%1', ShortcutDimensionCode);
        TempDimensionSetEntry.FindSet();

        // [WHEN] Change Dimension Value for Sales Header Shortcut Dimension.
        ChangeDimensionOnSalesHeader(SalesHeader, ShortcutDimensionCode);
        FindSalesLine(SalesLine, SalesHeader);
        DimensionValueCode := SalesHeader."Shortcut Dimension 1 Code";
        DimensionSetID := SalesLine."Dimension Set ID";
    end;

    local procedure CreateItemWithExtendedText(var Item: Record Item; DimensionCode: Code[20])
    var
        DefaultDimension: Record "Default Dimension";
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
    begin
        Item.Get(CreateItemWithDimension(DimensionCode, DefaultDimension."Value Posting"::" "));
        Item.Validate("Automatic Ext. Texts", true);
        Item.Modify(true);
        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
    end;

    local procedure CreateGLAccountWithDimension(DimensionCode: Code[20]; VATProdPostingGroup: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        GLAccount.Modify(true);
        if DimensionCode = '' then
            exit;
        LibraryDimension.FindDimensionValue(DimensionValue, DimensionCode);
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, GLAccount."No.", DimensionCode, DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::" ");
        DefaultDimension.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateSalesDocumentWithLocation(var SalesHeader: Record "Sales Header"; ShortcutDimension1Code: Code[20]; LocationCode: Code[10]; ItemNo: Code[20]; UnitPrice: Decimal)
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Validate("Shortcut Dimension 1 Code", ShortcutDimension1Code);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));  // Using Random value for Quantity.
        SalesLine.Validate("Location Code", SalesHeader."Location Code");
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreateStandardSalesDocument(var StandardSalesLine: Record "Standard Sales Line"; DimensionCode: Code[20]; ItemNo: Code[20]; GLAccountNo: Code[20]) DifferentDimensionCode: Code[20]
    var
        StandardSalesCode: Record "Standard Sales Code";
    begin
        LibrarySales.CreateStandardSalesCode(StandardSalesCode);
        CreateStandardSalesLine(StandardSalesLine, StandardSalesCode.Code, StandardSalesLine.Type::Item, ItemNo);
        DifferentDimensionCode := FindDifferentDimension(DimensionCode);

        UpdateDimensionSetID(StandardSalesLine, DifferentDimensionCode);
        CreateStandardSalesLine(StandardSalesLine, StandardSalesCode.Code, StandardSalesLine.Type::"G/L Account", GLAccountNo);

        // Use Random because value is not important.
        StandardSalesLine.Validate("Amount Excl. VAT", StandardSalesLine.Quantity * LibraryRandom.RandDec(10, 2));
        StandardSalesLine.Modify(true);
        UpdateDimensionSetID(StandardSalesLine, DifferentDimensionCode);
    end;

    local procedure CreateStandardSalesLine(var StandardSalesLine: Record "Standard Sales Line"; StandardSalesCode: Code[10]; Type: Enum "Sales Line Type"; No: Code[20])
    begin
        LibrarySales.CreateStandardSalesLine(StandardSalesLine, StandardSalesCode);
        StandardSalesLine.Validate(Type, Type);
        StandardSalesLine.Validate("No.", No);

        // Use Random because value is not important.
        StandardSalesLine.Validate(Quantity, LibraryRandom.RandInt(10));
        StandardSalesLine.Modify(true);
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Use Random Number Generator for Amount.
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          AccountType, AccountNo, Amount);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, -GenJournalLine.Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateCustWithCombShip(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Combine Shipments", true);
        Customer.Modify();
        exit(Customer."No.");
    end;

    local procedure CreateDimSetID(): Integer
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        exit(LibraryDimension.CreateDimSet(0, Dimension.Code, DimensionValue.Code));
    end;

    local procedure CreatePartlyShipSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDecInDecimalRange(10, 20, 2));
        UpdatePartialQuantityToShip(SalesLine);

        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure CreateGlobal1DimensionValue(var DimensionValue: Record "Dimension Value"): Code[20]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
        exit(DimensionValue.Code);
    end;

    local procedure FindDifferentDimension("Code": Code[20]): Code[20]
    var
        Dimension: Record Dimension;
    begin
        Dimension.SetFilter(Code, '<>%1', Code);
        LibraryDimension.FindDimension(Dimension);
        exit(Dimension.Code);
    end;

    local procedure FindDifferentDimensionValue(DimensionCode: Code[20]; "Code": Code[20]): Code[20]
    var
        DimensionValue: Record "Dimension Value";
    begin
        DimensionValue.SetFilter(Code, '<>%1', Code);
        LibraryDimension.FindDimensionValue(DimensionValue, DimensionCode);
        exit(DimensionValue.Code);
    end;

    local procedure FindDimensionSetEntry(var DimensionSetEntry: Record "Dimension Set Entry"; ShortcutDimensionCode: Code[20]; DimensionSetID: Integer)
    begin
        DimensionSetEntry.SetRange("Dimension Code", ShortcutDimensionCode);
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, DimensionSetID);
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
    end;

    local procedure FindSalesOrder(var SalesHeader: Record "Sales Header"; QuoteNo: Code[20])
    begin
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("Quote No.", QuoteNo);
        SalesHeader.FindFirst();
    end;

    local procedure InsertDimOnSalesHdr(var SalesHeader: Record "Sales Header"; ShortcutDimension2Code: Code[20])
    var
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.FindDimensionValue(DimensionValue, ShortcutDimension2Code);
        SalesHeader.Validate("Shortcut Dimension 2 Code", DimensionValue.Code);
        SalesHeader.Modify(true);
    end;

    local procedure RunCombineShipment(CustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        CombineShipments: Report "Combine Shipments";
    begin
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        Clear(CombineShipments);
        CombineShipments.SetTableView(SalesHeader);
        CombineShipments.InitializeRequest(WorkDate(), WorkDate(), false, false, false, false);
        CombineShipments.UseRequestPage(false);
        CombineShipments.Run();
    end;

    local procedure RunCopySalesDocument(SalesHeader: Record "Sales Header"; DocumentNo: Code[20])
    var
        CopySalesDocument: Report "Copy Sales Document";
    begin
        Commit();
        Clear(CopySalesDocument);
        CopySalesDocument.SetSalesHeader(SalesHeader);
        CopySalesDocument.SetParameters("Sales Document Type From"::"Posted Shipment", DocumentNo, true, false);
        CopySalesDocument.UseRequestPage(false);
        CopySalesDocument.Run();
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        // Select General Journal Batch and delete General Journal Lines before creating new General Journal Lines in the General Journal
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure UpdatePartialQuantityToShip(SalesLine: Record "Sales Line")
    var
        LibraryUtility: Codeunit "Library - Utility";
    begin
        SalesLine.Validate("Qty. to Ship", SalesLine.Quantity * LibraryUtility.GenerateRandomFraction());
        SalesLine.Modify(true);
    end;

    local procedure UpdateDimensionSetID(var StandardSalesLine: Record "Standard Sales Line"; DifferentDimension: Code[20])
    var
        DimensionValue: Record "Dimension Value";
        DimensionSetID: Integer;
    begin
        LibraryDimension.FindDimensionValue(DimensionValue, DifferentDimension);
        DimensionSetID := LibraryDimension.CreateDimSet(StandardSalesLine."Dimension Set ID", DifferentDimension, DimensionValue.Code);
        StandardSalesLine.Validate("Dimension Set ID", DimensionSetID);
        StandardSalesLine.Modify(true);
    end;

    local procedure UpdateDimensionOnSalesHeader(SalesHeader: Record "Sales Header") DimensionSetID: Integer
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        // Update Dimension value on Sales Header Dimension.
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, SalesHeader."Dimension Set ID");
        DimensionSetID :=
          LibraryDimension.EditDimSet(
            DimensionSetEntry."Dimension Set ID", DimensionSetEntry."Dimension Code",
            FindDifferentDimensionValue(DimensionSetEntry."Dimension Code", DimensionSetEntry."Dimension Value Code"));
        SalesHeader.Validate("Dimension Set ID", DimensionSetID);
        SalesHeader.Modify(true);
    end;

    local procedure UpdateDimensionOnSalesLine(var SalesLine: Record "Sales Line")
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        DimensionSetID: Integer;
    begin
        // Update Dimension value on Sales Line Dimension.
        SalesLine.Get(SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
        LibraryDimension.FindDimensionSetEntry(DimensionSetEntry, SalesLine."Dimension Set ID");
        DimensionSetID :=
          LibraryDimension.EditDimSet(
            DimensionSetEntry."Dimension Set ID", DimensionSetEntry."Dimension Code",
            FindDifferentDimensionValue(DimensionSetEntry."Dimension Code", DimensionSetEntry."Dimension Value Code"));
        SalesLine.Validate("Dimension Set ID", DimensionSetID);
        SalesLine.Modify(true);
    end;

    local procedure UpdateInvoiceAmountForRounding(var SalesLine: Record "Sales Line")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        SalesLine.Validate("Line Amount", Round(SalesLine."Line Amount" / 3, 1) - GeneralLedgerSetup."Inv. Rounding Precision (LCY)" / 2);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; GLAccountCode: Code[20]; CustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        // Create Sales Credit Memo and modify Sales Line with Random values.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountCode, LibraryRandom.RandDec(5, 2));
    end;

    local procedure SelectAndClearItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; TemplateType: Enum "Item Journal Template Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, TemplateType);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure SetDefaultDimension(var DefaultDimension: Record "Default Dimension"; DimensionCode: Code[20]; No: Code[20])
    var
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.FindDimensionValue(DimensionValue, DimensionCode);
        LibraryDimension.CreateDefaultDimensionGLAcc(DefaultDimension, No, DimensionCode, DimensionValue.Code);
        DefaultDimension.Validate("Value Posting", DefaultDimension."Value Posting"::"Code Mandatory");
        DefaultDimension.Modify(true);
    end;

    local procedure SetGLAccountDefaultDimension(var DefaultDimension: Record "Default Dimension"; DimensionCode: Code[20]): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        SetDefaultDimension(DefaultDimension, DimensionCode, GLAccount."No.");
        exit(GLAccount."No.");
    end;

    local procedure SetInvGLAccountDefaultDimension(var DefaultDimension: Record "Default Dimension"; LocationCode: Code[10]; InventoryPostingGroup: Code[20])
    var
        GLAccount: Record "G/L Account";
        GeneralLedgerSetup: Record "General Ledger Setup";
        InventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        // Get GL Account No. from Inventory Setup.
        InventoryPostingSetup.Get(LocationCode, InventoryPostingGroup);
        GLAccount.Get(InventoryPostingSetup."Inventory Account");
        GeneralLedgerSetup.Get();

        // Set Default Dimension.
        SetDefaultDimension(DefaultDimension, GeneralLedgerSetup."Global Dimension 1 Code", GLAccount."No.");
    end;

    local procedure FindICGLAccount(): Code[20]
    var
        ICGLAccount: Record "IC G/L Account";
    begin
        ICGLAccount.SetRange("Account Type", ICGLAccount."Account Type"::Posting);
        ICGLAccount.SetRange(Blocked, false);
        ICGLAccount.FindFirst();
        exit(ICGLAccount."No.");
    end;

    local procedure DeleteDefaultDimension(DefaultDimension: Record "Default Dimension")
    begin
        DefaultDimension.Get(DefaultDimension."Table ID", DefaultDimension."No.", DefaultDimension."Dimension Code");
        DefaultDimension.Delete(true);
    end;

    local procedure VerifyDimensionOnArchiveHeader(SalesHeader: Record "Sales Header")
    var
        SalesHeaderArchive: Record "Sales Header Archive";
    begin
        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        SalesHeaderArchive.FindFirst();
        SalesHeaderArchive.TestField("Dimension Set ID", SalesHeader."Dimension Set ID");
    end;

    local procedure VerifyDimensionOnArchiveLine(SalesLine: Record "Sales Line")
    var
        SalesLineArchive: Record "Sales Line Archive";
    begin
        SalesLineArchive.SetRange("Document Type", SalesLine."Document Type");
        SalesLineArchive.SetRange("Document No.", SalesLine."Document No.");
        SalesLineArchive.FindFirst();
        SalesLineArchive.TestField("Dimension Set ID", SalesLine."Dimension Set ID");
    end;

    local procedure VerifyDimensionOnGLEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; GenPostingType: Enum "General Posting Type"; GlobalDimension1Code: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Gen. Posting Type", GenPostingType);
        GLEntry.FindFirst();
        GLEntry.TestField("Global Dimension 1 Code", GlobalDimension1Code);
    end;

    local procedure VerifyDimensionOnRoundingEntry(SalesHeader: Record "Sales Header")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLEntry: Record "G/L Entry";
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CustomerPostingGroup.Get(SalesHeader."Customer Posting Group");

        SalesInvoiceHeader.SetRange("Pre-Assigned No.", SalesHeader."No.");
        SalesInvoiceHeader.FindFirst();

        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange("Document No.", SalesInvoiceHeader."No.");
        GLEntry.SetRange("G/L Account No.", CustomerPostingGroup."Invoice Rounding Account");
        GLEntry.FindFirst();
        GLEntry.TestField("Dimension Set ID", SalesHeader."Dimension Set ID");
    end;

    local procedure VerifyDimensionSetEntry(var TempDimensionSetEntry: Record "Dimension Set Entry" temporary; DimensionSetID: Integer)
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetRange("Dimension Set ID", DimensionSetID);
        repeat
            DimensionSetEntry.SetRange("Dimension Code", TempDimensionSetEntry."Dimension Code");
            DimensionSetEntry.FindFirst();
            DimensionSetEntry.TestField("Dimension Value Code", TempDimensionSetEntry."Dimension Value Code");
        until TempDimensionSetEntry.Next() = 0;
    end;

    local procedure VerifyGLEntryDimension(SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.SetRange("No.", SalesLine."No.");
        SalesInvoiceLine.FindFirst();

        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Invoice);
        GLEntry.SetRange(Amount, -SalesInvoiceLine.Amount);
        GLEntry.FindFirst();
        GLEntry.TestField("Dimension Set ID", SalesLine."Dimension Set ID");
    end;

    local procedure VerifySalesLineDimension(SalesLine: Record "Sales Line")
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesLine2: Record "Sales Line";
    begin
        SalesShipmentHeader.SetRange("Order No.", SalesLine."Document No.");
        SalesShipmentHeader.FindFirst();

        SalesLine2.SetRange("Shipment No.", SalesShipmentHeader."No.");
        SalesLine2.SetRange("Shipment Line No.", SalesLine."Line No.");
        SalesLine2.FindFirst();
        SalesLine2.TestField("Dimension Set ID", SalesLine."Dimension Set ID");
    end;

    local procedure VerifyDimensionCode(DimensionSetID: Integer; DimensionCode: Code[20])
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetRange("Dimension Set ID", DimensionSetID);
        DimensionSetEntry.SetRange("Dimension Code", DimensionCode);
        Assert.IsTrue(DimensionSetEntry.FindFirst(),
          Format('Could not find dimensions with filters ' + DimensionSetEntry.GetFilters));
    end;

    local procedure VerifyGLEntryICPartner(DocumentNo: Code[20]; ICPartnerCode: Code[20]; GlobalDimensionCode: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Bal. Account Type", GLEntry."Bal. Account Type"::"IC Partner");
        GLEntry.FindFirst();
        GLEntry.TestField("Global Dimension 1 Code", GlobalDimensionCode);
        GLEntry.TestField("IC Partner Code", ICPartnerCode);
    end;

    local procedure VerifyGLEntry(DocumentnNo: Code[20]; DimensionCode: Code[20])
    var
        GLEntry: Record "G/L Entry";
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentnNo);
        GLEntry.FindSet();
        repeat
            Assert.IsTrue(DimensionSetEntry.Get(GLEntry."Dimension Set ID", DimensionCode), 'Dimension Set Entry must found');
        until GLEntry.Next() = 0;
    end;

    local procedure VerifyDimensionOnDimSet(DimSetID: Integer; DimensionValue: Record "Dimension Value")
    var
        TempDimensionSetEntry: Record "Dimension Set Entry" temporary;
        DimensionManagement: Codeunit DimensionManagement;
    begin
        DimensionManagement.GetDimensionSet(TempDimensionSetEntry, DimSetID);
        TempDimensionSetEntry.SetRange("Dimension Code", DimensionValue."Dimension Code");
        TempDimensionSetEntry.FindFirst();
        TempDimensionSetEntry.TestField("Dimension Value Code", DimensionValue.Code);
    end;

    local procedure VerifyVATEntriesAmount(VATProdPostingGroup: Code[20]; DocumentNo: Code[20]; ExpectedVATAmount: array[5] of Decimal)
    var
        VATEntry: Record "VAT Entry";
        Index: Integer;
        IncorrectAmountMsg: Label 'Incorrect Amount in "VAT Entry"[%1]', Locked = true;
    begin
        VATEntry.SetRange("VAT Prod. Posting Group", VATProdPostingGroup);
        VATEntry.SetRange("Document No.", DocumentNo);
        Assert.RecordCount(VATEntry, ArrayLen(ExpectedVATAmount));

        Index := 0;
        VATEntry.FindSet();
        repeat
            Index += 1;
            Assert.AreEqual(
              ExpectedVATAmount[Index],
              VATEntry.Amount,
              StrSubstNo(IncorrectAmountMsg, Index));
        until VATEntry.Next() = 0;
    end;

    local procedure VerifyDimensionOnSalesOrderLine(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; DimensionCode: Code[20])
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, DocumentType, DocumentNo);
        DimensionSetEntry.SetRange("Dimension Set ID", SalesLine."Dimension Set ID");
        DimensionSetEntry.FindFirst();
        Assert.AreEqual(
          DimensionCode, DimensionSetEntry."Dimension Code",
          StrSubstNo(DimensionValueCodeErr, DimensionSetEntry.FieldCaption("Dimension Code"), DimensionCode));
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
    end;

    local procedure UpdateLocationOnSalesLine(var SalesLine: Record "Sales Line"; LocationCode: Code[10])
    begin
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure UpdateGlobalDimensionOnSalesLine(var SalesLine: Record "Sales Line"; var DimensionValue: Record "Dimension Value")
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));
        SalesLine.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNo: Code[20])
    begin
        // Sales Order with one Sales line. Take random value for Quantity and Unit Price.        
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        CreateAndModifySalesLine(
          SalesLine, SalesHeader, ItemNo, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateAndModifySalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; UnitPrice: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreateCustomerWithDefaultGlobalDimValue(var Customer: Record Customer; var DimensionValue: Record "Dimension Value")
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, Customer."No.", DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreateLocationWithDefaultGlobalDimensionValue(var Location: Record Location; var DimensionValue: Record "Dimension Value")
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryWarehouse.CreateLocation(Location);
        LibraryDimension.CreateDefaultDimension(DefaultDimension, Database::Location, Location.Code, DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreateAccountTypeDefaultDimension(var DimensionValue: Record "Dimension Value"; CustomerNo: Code[20]; TableId: Integer)
    var
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.CreateDimensionValue(DimensionValue, LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, CustomerNo, DimensionValue."Dimension Code", DimensionValue.Code);
        LibraryDimension.CreateAccTypeDefaultDimension(DefaultDimension, TableId, DimensionValue."Dimension Code",
            DimensionValue.Code, DefaultDimension."Value Posting"::" ");
    end;

    local procedure ChangeDimensionOnDocument(var SalesHeader: Record "Sales Header"; DimensionValueCode: Code[20])
    begin
        SalesHeader.ValidateShortcutDimCode(1, DimensionValueCode);
        SalesHeader.Modify(true);
    end;

    local procedure VerifyDimensionOnSalesOrder(SalesHeader: Record "Sales Header"; DimensionCode: Code[20])
    var
        DimensionSetEntry: Record "Dimension Set Entry";
        SalesLine: Record "Sales Line";
    begin
        // Verify the dimension on sales header
        DimensionSetEntry.Get(SalesHeader."Dimension Set ID", DimensionCode);
        Assert.AreEqual(
          DimensionCode, DimensionSetEntry."Dimension Code",
          StrSubstNo(DimensionValueCodeErr, DimensionSetEntry.FieldCaption("Dimension Code"), DimensionCode));

        // Verify the dimension on sales line
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.");
        DimensionSetEntry.Get(SalesLine."Dimension Set ID", DimensionCode);
        Assert.AreEqual(
          DimensionCode, DimensionSetEntry."Dimension Code",
          StrSubstNo(DimensionValueCodeErr, DimensionSetEntry.FieldCaption("Dimension Code"), DimensionCode));
    end;

    local procedure CreateShipToAddressWithLocation(var ShiptoAddress: Record "Ship-to Address"; CustomerNo: Code[20]; LocationCode: Code[10])
    begin
        LibrarySales.CreateShipToAddress(ShiptoAddress, CustomerNo);
        ShiptoAddress.Validate("Location Code", LocationCode);
        ShiptoAddress.Modify();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerForSalesHeaderDimUpdate(Question: Text[1024]; var Reply: Boolean)
    begin
        case true of
            Question = UpdateFromHeaderLinesQst:
                Reply := true;
            StrPos(Question, UpdateLineDimQst) <> 0:
                Reply := LibraryVariableStorage.DequeueBoolean();
        end;
    end;

    [ConfirmHandler]
    procedure ChangeDimensionConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        ChangeDimensionsQst: Label 'You may have changed a dimension', Locked = true;
    begin
        Reply := Question.Contains(ChangeDimensionsQst);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Just for Handle the Message.
    end;

    [MessageHandler]
    procedure ChangeLocationMessageHandler(Message: Text[1024])
    begin
        // Just for handle the message.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesCodePageHandler(var StandardCustomerSalesCodes: Page "Standard Customer Sales Codes"; var Response: Action)
    begin
        // Modal Page Handler.
        StandardCustomerSalesCodes.SetRecord(StandardCustomerSalesCode);
        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EditDimensionSetEntriesHandler(var EditDimensionSetEntries: TestPage "Edit Dimension Set Entries")
    begin
        EditDimensionSetEntries.New();
        EditDimensionSetEntries."Dimension Code".SetValue(LibraryVariableStorage.DequeueText());
        EditDimensionSetEntries.DimensionValueCode.SetValue(LibraryVariableStorage.DequeueText());
        EditDimensionSetEntries.OK().Invoke();
    end;
}

