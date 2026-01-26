codeunit 134386 "ERM Sales Documents II"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        DocumentErrorsMgt: Codeunit "Document Errors Mgt.";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryResource: Codeunit "Library - Resource";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        LibraryTemplates: Codeunit "Library - Templates";
        LibraryMarketing: Codeunit "Library - Marketing";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        ItemTrackingHandlerAction: Option AssignRandomSN,AssignSpecificLot;
        isInitialized: Boolean;
        AmountErr: Label '%1 must be %2 in %3.', Comment = '%1 = Field Name, %2 = Amount, %3 = Table Name';
        UnknownErr: Label 'Unknown error.';
        EditableErr: Label '%1 should not be editable.', Comment = '%1 = Control Name';
        InvoiceDiscountErr: Label '%1 must be %2.', Comment = '%1 = Control Name, %2 = Amount';
        SalesDocumentFoundErr: Label '%1 must not exist for order No %2.', Comment = '%1 = Table Name, %2 = Document No.';
        SalesInvoiceMustBeDeletedErr: Label 'Sales Invoice must be deleted.';
        BlankSellToCustomerFieldErr: Label 'Sell-to Customer No. field must be empty.';
        RecurrentDocumentDateErr: Label 'Document Date must be the same as in Create Recurring Sales Inv. report.';
        RecurrentExpiredDateErr: Label 'No sales invoice must be created for expired Valid To Date in Standard Customer Sales Code.';
        IncorrectSalesTypeToCopyPricesErr: Label 'To copy sales prices, The Sales Type Filter field must contain Customer.';
        MultipleCustomersSelectedErr: Label 'More than one customer uses these sales prices. To copy prices, the Sales Code Filter field must contain one customer only.';
        NotExistingFreightGLAccNoErr: Label 'The field %1 of table Sales & Receivables Setup contains a value (%2) that cannot be found in the related table', Comment = '%1 - caption of "Freight G/L Acc. No.", %2 - G/L Account No.';
        ShipToAdressTestValueTxt: Label 'ShipToAdressTestValue';
        EmptyStartingDateRecIsNotFoundErr: Label 'The record with empty starting date field is not found.';
        WorkStartingDateRecIsNotFoundErr: Label 'The record with specified starting date (%1) is not found.';
        EmptyStartingDateIsFoundErr: Label 'The record''s starting date (%1) is not equal to date within filter field (%2).';
        WorkStartingDateRecIsFoundErr: Label 'The record''s startings date (%1) is not empty. Only records with empty starting date should be found.';
        ExpectedRenameErr: Label 'You cannot rename the line.';
        SalesQuoteLineNotEditableErr: Label 'The Sales Quote line should be editable';
        CannotRenameItemUsedInSalesLinesErr: Label 'You cannot rename %1 in a %2, because it is used in sales document lines.', Comment = '%1 = Item No. caption, %2 = Table caption.';
        ChangeExtendedTextErr: Label 'You cannot change %1 for Extended Text Line.', Comment = '%1= Field Caption';

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Create Sales Invoice, Post and Verify Sales Invoice Header and Line.

        // Setup: Create Sales Invoice.
        Initialize();
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, CreateCustomer(), SalesLine.Type::Item, CreateItem());

        // Exercise: Post Sales Invoice.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Check Sell To Customer No., Item No., Quantity in Sales Invoice Header and Line.
        VerifySalesInvoice(GetSalesInvoiceHeaderNo(SalesHeader."No."), SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Create Sales Credit Memo, Post and Verify Sales Cr.Memo Header and Line.

        // Setup: Create Sales Credit Memo.
        Initialize();
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", CreateCustomer(), SalesLine.Type::Item, CreateItem());

        // Exercise: Post Sales Credit Memo.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Check Sell To Customer No., Item No., Quantity in Sales Credit Memo Header and Line.
        VerifySalesCreditMemo(GetSalesCreditMemoHeaderNo(SalesHeader."No."), SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorDialogOnSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        Assert: Codeunit Assert;
    begin
        // Create Sales Order Header, Post and Verify posting error.

        // Setup: Create Sales Order Header.
        Initialize();
        CreateSaleHeader(SalesHeader, SalesHeader."Document Type"::Order);

        // Exercise: Post Sales Order.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Check the Error message.
        Assert.AreEqual(StrSubstNo(DocumentErrorsMgt.GetNothingToPostErrorMsg()), GetLastErrorText, UnknownErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorDialogOnSalesQuote()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        Assert: Codeunit Assert;
    begin
        // Create Sales Quote Header then make Order, post the Order and Verify posting error.

        // Setup: Create Sales Quote Header.
        Initialize();
        CreateSaleHeader(SalesHeader, SalesHeader."Document Type"::Quote);

        // Exercise: Create Sales Order form Sales Quote and Post Sales Order.
        CODEUNIT.Run(CODEUNIT::"Sales-Quote to Order", SalesHeader);
        GetSalesOrderHeader(SalesHeader2, SalesHeader."No.");
        asserterror LibrarySales.PostSalesDocument(SalesHeader2, true, true);

        // Verify: Check the Error message.
        Assert.AreEqual(StrSubstNo(DocumentErrorsMgt.GetNothingToPostErrorMsg()), GetLastErrorText, UnknownErr);
    end;

    [Test]
    [HandlerFunctions('SalesCodePageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderStandardSalesCode()
    var
        SalesHeader: Record "Sales Header";
        StandardSalesLine: Record "Standard Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // Check Sales Code Line are copied correctly in Sales Line.

        // Setup: Update Stock Out Warning.
        Initialize();
        UpdateSalesReceivablesSetup(false, SalesReceivablesSetup."Credit Warnings"::"No Warning");

        // Exercise: Create Sales Order with Sales Code.
        CreateSalesOrderWithSalesCode(SalesHeader, StandardSalesLine, CreateItem(), '', '');

        // Verify: Verify Sales Code Line are copied correctly in Sales Line.
        VerifySalesLine(StandardSalesLine, SalesHeader."No.", '', '');
    end;

    [Test]
    [HandlerFunctions('SalesCodePageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderCopyStandardCode()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        StandardSalesLine: Record "Standard Sales Line";
        PostedSaleInvoiceNo: Code[20];
    begin
        // Verify Posted Sales Line of one document is copied correctly in Sales Line of second document.

        // Setup: Update Stock OutW Warning and Create and post Sales Order with Sales Code.
        Initialize();
        UpdateSalesReceivablesSetup(false, SalesReceivablesSetup."Credit Warnings"::"No Warning");
        CreateSalesOrderWithSalesCode(SalesHeader, StandardSalesLine, CreateItem(), '', '');
        ModifyUnitPrice(SalesHeader);
        PostedSaleInvoiceNo := PostSalesOrder(SalesHeader);
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader2."Document Type"::Invoice, SalesHeader."Sell-to Customer No.");
        Commit();  // COMMIT is required here.

        // Exercise: Copy Sales Document.
        SalesCopyDocument(SalesHeader2, PostedSaleInvoiceNo, "Sales Document Type From"::"Posted Invoice", false);

        // Verify: Verify values on Copy Sales Lines .
        VerifyCopySalesLine(PostedSaleInvoiceNo, SalesHeader2."No.");
    end;

    [Test]
    [HandlerFunctions('CreateRecurringSalesInvHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RecurringSalesInvoiceDocumentDate()
    var
        SalesHeader: Record "Sales Header";
        StandardSalesLine: Record "Standard Sales Line";
        StandardCustomerSalesCode: Record "Standard Customer Sales Code";
        DocumentDate: Date;
    begin
        // Check Document Date correct on sales invoice created from reccuring report
        Initialize();
        CreateStandardSalesLinesWithItemForCustomer(StandardSalesLine, StandardCustomerSalesCode);
        Commit();

        DocumentDate := WorkDate() + LibraryRandom.RandInt(10);
        SalesHeader.Get(SalesHeader."Document Type"::Invoice, RunReccuringSalesIvoice(DocumentDate, StandardSalesLine));

        Assert.AreEqual(DocumentDate, SalesHeader."Document Date", RecurrentDocumentDateErr);
    end;

    [Test]
    [HandlerFunctions('CreateRecurringSalesInvHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RecurringSalesInvoiceValidToDate()
    var
        SalesHeader: Record "Sales Header";
        StandardSalesLine: Record "Standard Sales Line";
        StandardCustomerSalesCode: Record "Standard Customer Sales Code";
        DocumentDate: Date;
    begin
        // Check That No Sales Invoices Created For Expired Standard Customer Code
        Initialize();

        CreateStandardSalesLinesWithItemForCustomer(StandardSalesLine, StandardCustomerSalesCode);
        StandardCustomerSalesCode."Valid To date" := WorkDate() - LibraryRandom.RandInt(10);
        StandardCustomerSalesCode.Modify();
        Commit();
        DocumentDate := WorkDate() + LibraryRandom.RandInt(10);
        Assert.IsFalse(
          SalesHeader.Get(SalesHeader."Document Type"::Invoice, RunReccuringSalesIvoice(DocumentDate, StandardSalesLine)),
          RecurrentExpiredDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPaymentMethodCash()
    var
        PaymentMethod: Record "Payment Method";
    begin
        // To test posting of Sales Order including Customer of Payment Method code as Cash.

        Initialize();
        // Payment Term Code With Balance Account Type as G/L Account and With Balance Account No.
        CustomerPaymentMethodCheck(CreatePaymentMethodCode(PaymentMethod."Bal. Account Type"::"G/L Account"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerPaymentMethodAccount()
    var
        PaymentMethod: Record "Payment Method";
    begin
        // To test posting of Sales Order including Customer of Payment Method code as Account.

        Initialize();
        // Payment Term Code With Balance Account Type as G/L Account and Without Balance Account No.
        CustomerPaymentMethodCheck(CreatePaymentMethodCode(PaymentMethod."Bal. Account Type"::"Bank Account"));
    end;

    local procedure CustomerPaymentMethodCheck(PaymentMethodCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        Amount: Decimal;
        PostedSaleInvoiceNo: Code[20];
    begin
        // Setup: Create Sales Order with Payment Method Code of Customer.
        Amount := CreateOrderPaymentMethod(SalesHeader, PaymentMethodCode);

        // Exercise: Post Sales Order as Ship and Invoice True.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        PostedSaleInvoiceNo := FindPostedSalesOrderToInvoice(SalesHeader."No.");

        // Verify: Verify Customer Ledger Entry and GL Entry.
        VerifyCustomerLedgerEntry(PostedSaleInvoiceNo, -Amount);
        VerifyAmountOnGLEntry(PostedSaleInvoiceNo, GetReceivableAccNo(SalesHeader."Bill-to Customer No."), Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ModifyCustomerLedgerEntry()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedSaleInvoiceNo: Code[20];
    begin
        // To modify Customer Ledger Entry after posting of order and verify same.

        // Setup: Create Sales Order with Partial Invoice.
        Initialize();
        CreateAndModifySalesOrder(SalesHeader, SalesLine);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        PostedSaleInvoiceNo := FindPostedSalesOrderToInvoice(SalesHeader."No.");

        // Exercise: Modify Customer Ledger Entry.
        ModifyCustLedgerEntry(CustLedgerEntry, PostedSaleInvoiceNo, SalesHeader."Sell-to Customer No.");

        // Verify: Verify Due Date,Payment Discount Date and Remaining Payment Disc Possible on Customer Ledger Entry.
        VerifyCustLedgerEntryDisc(CustLedgerEntry, PostedSaleInvoiceNo);
    end;

    [Test]
    [HandlerFunctions('TemplateSelectionPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerCreationByPage()
    var
        TempCustomer: Record Customer temporary;
    begin
        // To create a new Customer with Page and verify it.

        // Setup.
        Initialize();

        // Exercise: Create Customer with Page.
        CreateTempCustomer(TempCustomer);
        CreateCustomerCard(TempCustomer);

        // Verify: Verify values on Customer.
        VerifyCustomer(TempCustomer);
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CustomerCreditLimitWarning()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SalesInvoice: TestPage "Sales Invoice";
        CreditLimit: Decimal;
        UnitPrice: Decimal;
    begin
        // Verify values on Check Credit Limit warning page invoked by Sales Invoice.

        // Setup: Set StockOut warning and Credit Warnings,Create Customer and Item and Create a Sales Invoice.
        Initialize();
        UpdateSalesReceivablesSetup(false, SalesReceivablesSetup."Credit Warnings"::"Credit Limit");
        LibrarySales.CreateCustomer(Customer);
        LibraryVariableStorage.Enqueue(Customer."No.");
        LibraryVariableStorage.Enqueue(Customer."No.");
        CreditLimit := LibraryRandom.RandDec(100, 2);
        UnitPrice := CreditLimit + LibraryRandom.RandDec(100, 2);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // Taking Random values for Quantity and Unit Cost.
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesInvoice.SalesLines.Type.SetValue(Format(SalesLine.Type::Item));
        SalesInvoice.SalesLines."No.".SetValue(CreateItem());
        SalesInvoice.SalesLines.Quantity.SetValue(LibraryRandom.RandInt(5));
        SalesInvoice.SalesLines."Unit Price".SetValue(UnitPrice);

        // Exercise: Set Customer Credit Limit to invoke Credit Limit Warning.
        ModifyCreditLimitLCY(Customer."No.", CreditLimit);
        LibraryVariableStorage.Enqueue(CreditLimit);
        LibraryVariableStorage.Enqueue(GetAmountTotalIncVAT(SalesHeader));
        // Change the Unit Price to get a value changed on the exercise; otherwise, onvalide code will not be triggered.
        SalesInvoice.SalesLines."Unit Price".SetValue(0);
        SalesInvoice.SalesLines."Unit Price".SetValue(UnitPrice);

        // Verify: Verification is done in CreditLimitHandler.

        // Tear Down: Set the default value of 'StockOut Warning' and 'Credit Warnings' on Sales & Receivables Setup.
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

#if not CLEAN26
    [Obsolete('The sales statisticsss action opens the page non-modally.', '26.0')]
    [Test]
    [HandlerFunctions('SalesStatisticsHandler')]
    [Scope('OnPrem')]
    procedure NotEditableFieldsOnSalesInvoiceStatistics()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // Verify that some fields on Sales Statistics page are uneditable after calculating Invoice Discount on Sales Invoice.

        // Setup: Create Sales Invoice taking random values for Amount and Unit Price and calculate Invoice Discount.
        Initialize();
        CreateSaleHeader(SalesHeader, SalesHeader."Document Type"::Invoice);
        SalesHeader.Validate("Prices Including VAT", false);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        SalesHeader.CalcInvDiscForHeader();

        // Exercise: Open Sales Statistics page from Sales Invoice page.
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesInvoice.Statistics.Invoke();

        // Verify: Verification is done in SalesStatisticsHandler method.
    end;
#endif
    [Test]
    [HandlerFunctions('SalesStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure NotEditableFieldsOnSalesInvoiceStatisticsPage()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // Verify that some fields on Sales Statistics page are uneditable after calculating Invoice Discount on Sales Invoice.

        // Setup: Create Sales Invoice taking random values for Amount and Unit Price and calculate Invoice Discount.
        Initialize();
        CreateSaleHeader(SalesHeader, SalesHeader."Document Type"::Invoice);
        SalesHeader.Validate("Prices Including VAT", false);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        SalesHeader.CalcInvDiscForHeader();

        // Exercise: Open Sales Statistics page from Sales Invoice page.
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesInvoice.SalesStatistics.Invoke();

        // Verify: Verification is done in SalesStatisticsPageHandler method.
    end;

    [Test]
    [HandlerFunctions('SalesOptionDialogHandler')]
    [Scope('OnPrem')]
    procedure CancelSalesOrderPostingUsingOptionDialogBox()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Create Sales Order, Cancel Posting Using Option Dialog Box.

        // Setup: Create Sales Order.
        Initialize();
        LibraryVariableStorage.Enqueue(0);  // To Cancel Sales Order.
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CreateCustomer(), SalesLine.Type::Item, CreateItem());

        // Exercise: Cancel Option Dialog Box for Posting Sales Order Using String Menu Handler.
        CODEUNIT.Run(CODEUNIT::"Sales-Post (Yes/No)", SalesHeader);

        // Verify: Verify Sales Invoice and Shipment Header.
        VerifySalesInvoiceAndShipmentHeader(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('SalesOptionDialogHandler')]
    [Scope('OnPrem')]
    procedure ShipSalesOrderUsingOptionDialogBox()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Create Sales Order, Post as Ship and verify Sales Shipment Line for the posted order.

        // Setup: Create Sales Order.
        Initialize();
        LibraryVariableStorage.Enqueue(1);  // To Ship.
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CreateCustomer(), SalesLine.Type::Item, CreateItem());

        // Exercise: Ship Sales Order Using Option Dialog Box Handler.
        CODEUNIT.Run(CODEUNIT::"Sales-Post (Yes/No)", SalesHeader);

        // Verify: Verify the Sales Shipment Line for the shipment done.
        VerifySalesShipment(SalesLine, GetSalesShipmentHeaderNo(SalesHeader."No."));
    end;

    [Test]
    [HandlerFunctions('SalesOptionDialogHandler')]
    [Scope('OnPrem')]
    procedure InvoiceSalesOrderWithoutShip()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Create Sales Order, Post as Invoice and verify Error Without Ship.

        // Setup: Create Sales Order.
        Initialize();
        LibraryVariableStorage.Enqueue(2);  // To Invoice.
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CreateCustomer(), SalesLine.Type::Item, CreateItem());

        // Exercise: Invoice Sales Order Without Ship Using Option Dialog Box Handler.
        asserterror CODEUNIT.Run(CODEUNIT::"Sales-Post (Yes/No)", SalesHeader);

        // Verify: Verify Error while posting Invoice without Ship.
        Assert.AreEqual(StrSubstNo(DocumentErrorsMgt.GetNothingToPostErrorMsg()), GetLastErrorText, UnknownErr);
    end;

    [Test]
    [HandlerFunctions('SalesOptionDialogHandler')]
    [Scope('OnPrem')]
    procedure ShipAndInvoiceSalesOrderUsingOptionDialogBox()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Create Sales Order, Post as Ship and Invoice and verify Sales Invoice Line.

        // Setup: Create Sales Order.
        Initialize();
        LibraryVariableStorage.Enqueue(3);  // To Receive And Invoice.
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CreateCustomer(), SalesLine.Type::Item, CreateItem());

        // Exercise: Ship and Invoice Sales Order Using Option Dialog Box Handler.
        CODEUNIT.Run(CODEUNIT::"Sales-Post (Yes/No)", SalesHeader);

        // Verify: Verify Sales Shipment and Sales Invoice Line for the posted Sales Order.
        VerifySalesShipment(SalesLine, GetSalesShipmentHeaderNo(SalesHeader."No."));
        VerifySalesInvoice(GetSalesInvoiceHeaderNoOrder(SalesHeader."No."), SalesLine);
    end;

    [Test]
    [HandlerFunctions('SalesOptionDialogHandler')]
    [Scope('OnPrem')]
    procedure InvoiceAferShipUsingOptionDialogBox()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Create Sales Order, Post as Ship first than as Invoice and verify Sales Invoice Line.

        // Setup: Create Sales Order and Ship Using Option Dialog Box Handler.
        Initialize();
        LibraryVariableStorage.Enqueue(1);  // To Ship.
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CreateCustomer(), SalesLine.Type::Item, CreateItem());
        CODEUNIT.Run(CODEUNIT::"Sales-Post (Yes/No)", SalesHeader);
        LibraryVariableStorage.Enqueue(2);  // To Invoice.

        // Exercise: Invoice Sales after Shipping Order Using Option Dialog Box Handler.
        CODEUNIT.Run(CODEUNIT::"Sales-Post (Yes/No)", SalesHeader);

        // Verify: Verify Sales Invoice Line for the posted Sales Order.
        VerifySalesInvoice(GetSalesInvoiceHeaderNoOrder(SalesHeader."No."), SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithItemSalesPrices()
    var
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesPrice: Record "Sales Price";
        SalesInvoice: TestPage "Sales Invoice";
        PriceListLine: Record "Price List Line";
    begin
        // Verify that the Unit Price of the Sales Price of the Item gets populated on the Sales Invoice Line created for that particular Customer and Item.

        // Setup: Set StockOut warning and Credit Warnings,Create a Customer and an Item and set its Sales Price taking random Minimum Quantity and Unit Price.
        Initialize();
        PriceListLine.DeleteAll();
        UpdateSalesReceivablesSetup(false, SalesReceivablesSetup."Credit Warnings"::"Credit Limit");
        CreateSalesPriceWithUnitPrice(
          SalesPrice, CreateCustomer(), CreateItem(), LibraryRandom.RandDec(5, 2), LibraryRandom.RandDec(10, 2));
        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);

        // Exercise: Create a Sales Invoice for the new Item with Quantity same as Minimum Quantity of Sales Price.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, SalesPrice."Sales Code");
        OpenAndUpdateSalesInvoicePage(SalesInvoice, SalesHeader."No.", SalesPrice."Item No.", SalesPrice."Minimum Quantity");

        // Verify: Verify that the Unit Price in the Sales Line is equal to the Unit Price of the Sales Price of the Item.
        SalesInvoice.SalesLines."Unit Price".AssertEquals(SalesPrice."Unit Price");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,SendNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CustomerCreditLimitWithItemSalesPrices()
    var
        Customer: Record Customer;
        Customer2: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesPrice: Record "Sales Price";
        PriceListLine: Record "Price List Line";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        SalesInvoice: TestPage "Sales Invoice";
        UnitPrice: Decimal;
        CreditLimit: Decimal;
    begin
        // Verify that Unit Price gets updated when Sell-to Customer No gets changed and verify values on Check Credit Limit warning page invoked on Sales Invoice.

        // Setup: Set Stock Out warning and Credit Warnings, Create 2 Customers and set Credit Limit for 2nd Customer taking random values.
        Initialize();
        PriceListLine.DeleteAll();
        UpdateSalesReceivablesSetup(false, SalesReceivablesSetup."Credit Warnings"::"Credit Limit");
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomer(Customer2);
        LibraryVariableStorage.Enqueue(Customer2."No.");
        UpdateCreditLimitInCustomer(Customer2, LibraryRandom.RandDec(100, 2));
        CreditLimit := Customer2."Credit Limit (LCY)"; // This variable is used for validation in Handler method.
        LibraryVariableStorage.Enqueue(Customer2."No.");
        LibraryVariableStorage.Enqueue(CreditLimit);
        UnitPrice := Customer2."Credit Limit (LCY)" + LibraryRandom.RandDec(100, 2);

        // Create an Item and set its Sales Prices for 2 new Customers taking random Minimum Quantity and Unit Price.
        CreateSalesPriceWithUnitPrice(
          SalesPrice, Customer."No.", CreateItem(), LibraryRandom.RandDec(5, 2), LibraryRandom.RandDec(10, 2));
        CreateSalesPriceWithUnitPrice(SalesPrice, Customer2."No.", SalesPrice."Item No.", SalesPrice."Minimum Quantity", UnitPrice);
        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);

        // Create a Sales Invoice for the new Item for 1st Customer with Quantity more than Minimum Quantity of Sales Price.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        OpenAndUpdateSalesInvoicePage(
          SalesInvoice, SalesHeader."No.", SalesPrice."Item No.", SalesPrice."Minimum Quantity" + LibraryRandom.RandInt(5));

        // Exercise: Change the Sell-to Customer No. to 2nd Customer in the Sales Invoice.
        SalesInvoice."Sell-to Customer Name".SetValue(Customer2.Name);
        SalesInvoice.OK().Invoke();

        // Verify: Verification of data on Check Credit Limit dialog is done in 'CreditLimitLCYHandler' and also verify that Unit Price gets updated
        // to the Unit Price of the 2nd Customer in the Sales Price of the Item.
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesInvoice.SalesLines."Unit Price".AssertEquals(UnitPrice);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure InvoiceDiscountOnStatisticsForSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Check Invoice Discount Amount on Statistics when Cust. Invoice Discount are defined with Minimum Amount.

        // Setup: Create Sales Order.
        Initialize();
        CreateSalesOrderWithReceivableSetup(SalesHeader, SalesLine);

        // Exercise: Open Sales Order Statistics page.
        LibraryVariableStorage.Enqueue(0);
        LibraryVariableStorage.Enqueue(0);
        OpenSalesOrderStatistics(SalesHeader."No.");

        // Verify: Verification is done in 'SalesOrderStatisticsHandler' for zero amount.
    end;
#endif
    [Test]
    [HandlerFunctions('SalesOrderStatisticsHandlerNM')]
    [Scope('OnPrem')]
    procedure InvoiceDiscountOnStatisticsForSalesOrderNM()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Check Invoice Discount Amount on Statistics when Cust. Invoice Discount are defined with Minimum Amount.

        // Setup: Create Sales Order.
        Initialize();
        CreateSalesOrderWithReceivableSetup(SalesHeader, SalesLine);

        // Exercise: Open Sales Order Statistics page.
        LibraryVariableStorage.Enqueue(0);
        LibraryVariableStorage.Enqueue(0);
        OpenSalesOrderStatisticsNM(SalesHeader."No.");

        // Verify: Verification is done in 'SalesOrderStatisticsHandler' for zero amount.
    end;

    [Test]
    [HandlerFunctions('GetShipmentLinesHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceUsingGetShipmentLines()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Check GL Entry for posted Sales Invoice after creating through Get Shipment Lines.

        // Setup: Update Sales & Receivable Setup and Create Sales Order.
        Initialize();
        CreateSalesOrderWithReceivableSetup(SalesHeader, SalesLine);
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");

        // Exercise: Create and Post Sales Invoice.
        DocumentNo := CreateAndPostSalesInvoice(SalesHeader);

        // Verify: Verify GL Entry for Posted Sales Invoice.
        VerifyAmountOnGLEntry(DocumentNo, GeneralPostingSetup."Sales Account", -SalesLine."Line Amount");
    end;

    [Test]
    [HandlerFunctions('GetShipmentLinesHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceUsingChangedVATPostingGroup()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        InvSalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Check GL Entry for posted Sales Invoice after creating through Get Shipment Lines.

        // Setup: Create Sales Order.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Customer."No.", SalesLine.Type::Item, CreateItem());
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");

        // Create Invoice with another VAT Business Posting Group
        LibrarySales.CreateSalesHeader(InvSalesHeader, InvSalesHeader."Document Type"::Invoice, Customer."No.");
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>%1', InvSalesHeader."VAT Bus. Posting Group");
        VATPostingSetup.FindFirst();
        InvSalesHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        InvSalesHeader.Modify();
        SalesLine.Validate("Document Type", InvSalesHeader."Document Type");
        SalesLine.Validate("Document No.", InvSalesHeader."No.");

        // Verify: Get Shipment Lines produce error
        asserterror LibrarySales.GetShipmentLines(SalesLine);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [Test]
    [HandlerFunctions('GetShipmentLinesHandler,SalesOrderStatisticsHandler')]
    [Scope('OnPrem')]
    procedure InvoiceDiscountOnStatisticsForShippedSalesOrder()
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Amount: Decimal;
        InvDiscountAmountInvoicing: Decimal;
    begin
        // Check Program calculates the Invoice Discounts only on balance amount on General tab of Statistics.

        // Setup: Update Sales & Receivable Setup, Create and Ship Sales Order, Create and Post Sales Invoice.
        Initialize();
        CreateSalesOrderWithReceivableSetup(SalesHeader, SalesLine);
        CustInvoiceDisc.SetRange(Code, SalesHeader."Sell-to Customer No.");
        CustInvoiceDisc.FindFirst();
        Amount := Round(SalesLine."Line Amount" * CustInvoiceDisc."Discount %" / 100);
        CreateAndPostSalesInvoice(SalesHeader);

        // Add line in Shipped Sales Order.
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        LibrarySales.ReopenSalesDocument(SalesHeader);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, SalesLine."No.", LibraryRandom.RandDec(10, 2));
        ModifySalesLineUnitPrice(SalesLine, CustInvoiceDisc."Minimum Amount" + LibraryRandom.RandDec(10, 2));

        // InvDiscountAmountInvoicing and InvDiscountAmountGeneral are global variable and used in handler for verification.
        InvDiscountAmountInvoicing := SalesLine.Quantity * SalesLine."Unit Price" * CustInvoiceDisc."Discount %" / 100;
        LibraryVariableStorage.Enqueue(InvDiscountAmountInvoicing);
        LibraryVariableStorage.Enqueue(InvDiscountAmountInvoicing + Amount);

        // Exercise: Open Sales Order Statistics page.
        OpenSalesOrderStatistics(SalesHeader."No.");

        // Verify: Verification is done in 'SalesOrderStatisticsHandler'.
    end;
#endif
    [Test]
    [HandlerFunctions('GetShipmentLinesHandler,SalesOrderStatisticsHandlerNM')]
    [Scope('OnPrem')]
    procedure InvoiceDiscountOnStatisticsForShippedSalesOrderNM()
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Amount: Decimal;
        InvDiscountAmountInvoicing: Decimal;
    begin
        // Check Program calculates the Invoice Discounts only on balance amount on General tab of Statistics.

        // Setup: Update Sales & Receivable Setup, Create and Ship Sales Order, Create and Post Sales Invoice.
        Initialize();
        CreateSalesOrderWithReceivableSetup(SalesHeader, SalesLine);
        CustInvoiceDisc.SetRange(Code, SalesHeader."Sell-to Customer No.");
        CustInvoiceDisc.FindFirst();
        Amount := Round(SalesLine."Line Amount" * CustInvoiceDisc."Discount %" / 100);
        CreateAndPostSalesInvoice(SalesHeader);

        // Add line in Shipped Sales Order.
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        LibrarySales.ReopenSalesDocument(SalesHeader);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, SalesLine."No.", LibraryRandom.RandDec(10, 2));
        ModifySalesLineUnitPrice(SalesLine, CustInvoiceDisc."Minimum Amount" + LibraryRandom.RandDec(10, 2));

        // InvDiscountAmountInvoicing and InvDiscountAmountGeneral are global variable and used in handler for verification.
        InvDiscountAmountInvoicing := SalesLine.Quantity * SalesLine."Unit Price" * CustInvoiceDisc."Discount %" / 100;
        LibraryVariableStorage.Enqueue(InvDiscountAmountInvoicing);
        LibraryVariableStorage.Enqueue(InvDiscountAmountInvoicing + Amount);

        // Exercise: Open Sales Order Statistics page.
        OpenSalesOrderStatisticsNM(SalesHeader."No.");

        // Verify: Verification is done in 'SalesOrderStatisticsHandler'.
    end;

    [Test]
    [HandlerFunctions('MoveNegativeSalesLinesHandler,ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure SalesReturnOrderNavigate()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Test Navigate functionality for Sales Return Order.

        // Setup: Create Sales Return Order, perform MoveNegativeLines from Return Order page using 'MoveNegativeSalesLinesHandler' to create Sales Order and then post created Sales Order.
        // Use Random for Quantity on Sales Line.
        Initialize();
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", CreateCustomer(), SalesLine.Type::Item, CreateItem());
        SalesHeader.Validate("External Document No.", SalesHeader."Sell-to Customer No.");
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, SalesLine."No.", -LibraryRandom.RandDec(10, 2));
        Commit();
        OpenSalesReturnOrder(SalesHeader."No.");
        SalesHeader2.SetRange("Document Type", SalesHeader2."Document Type"::Order);
        SalesHeader2.SetRange("External Document No.", SalesHeader."External Document No.");
        SalesHeader2.FindFirst();
        LibrarySales.PostSalesDocument(SalesHeader2, true, true);

        // Exercise.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Number of entries for all related tables.
        VerifyNavigateEntry(SalesHeader."Sell-to Customer No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATEntryForSalesInvoiceWithICPartner()
    var
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedDocumentNo: Code[20];
        CustomerNo: Code[20];
    begin
        // Check value on VAT Entry after posting Sales Invoice with IC Partner.

        // Setup: Create Sales Invoice with IC Partner Code.
        Initialize();
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        CustomerNo :=
          LibrarySales.CreateCustomerWithBusPostingGroups(GLAccount."Gen. Bus. Posting Group", GLAccount."VAT Bus. Posting Group");
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, CustomerNo, SalesLine.Type::"G/L Account", GLAccount."No.");
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Using Random Number Generator for Random Unit Price.
        SalesLine.Validate("IC Partner Code", LibraryERM.CreateICPartnerNo());
        SalesLine.Validate("IC Partner Reference", FindICGLAccount());
        SalesLine.Modify(true);

        // Exercise: Post Sales Invoice.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Value on VAT Entry.
        SalesInvoiceHeader.Get(PostedDocumentNo);
        SalesInvoiceHeader.CalcFields(Amount);
        VerifyVATEntry(PostedDocumentNo, SalesInvoiceHeader.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesUnitPriceAndLineDiscount()
    var
        SalesPrice: Record "Sales Price";
        SalesLineDiscount: Record "Sales Line Discount";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
    begin
        // Verify Sales unit Price and Line Discount.

        // Setup: Create Sales Price and Sales Line Discount.
        Initialize();
        PriceListLine.DeleteAll();
        CreateSalesPrice(SalesPrice);
        CreateSalesLineDiscount(SalesLineDiscount, SalesPrice);
        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);
        CopyFromToPriceListLine.CopyFrom(SalesLineDiscount, PriceListLine);

        // Exercise: Create Sales Order.
        CreateSalesOrder(SalesLine, SalesPrice);

        // Verify: Verify Sales unit Price and Line Discount on Sales Line.
        VerifyUnitPriceAndLineDiscountOnSalesLine(SalesLine, SalesPrice."Minimum Quantity" / 2, 0, 0);
        VerifyUnitPriceAndLineDiscountOnSalesLine(SalesLine, SalesPrice."Minimum Quantity", SalesPrice."Unit Price", 0);
        VerifyUnitPriceAndLineDiscountOnSalesLine(
          SalesLine, SalesPrice."Minimum Quantity" * 2, SalesPrice."Unit Price", SalesLineDiscount."Line Discount %");
    end;

    [Test]
    [HandlerFunctions('GetShipmentLinesHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceUsingGetShipmentLinesWithBlockedCustomer()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        CustomerNo2: Code[20];
        ShipmentNo: Code[20];
    begin
        // Check Sales Shipment for Posted Sales Invoice after creating through Get Shipment Lines.

        // Setup: Create two Customers, Sales Order and post as Ship option.
        Initialize();
        CustomerNo := CreateCustomer();
        CustomerNo2 := CreateCustomer();
        Customer.Get(CustomerNo2);
        Customer.Validate("Bill-to Customer No.", CustomerNo);  // First created Customer used as Bill-to Customer No. for the second created Customer.
        Customer.Modify(true);

        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CustomerNo2, SalesLine.Type::Item, CreateItem());
        ModifySalesLineUnitPrice(SalesLine, LibraryRandom.RandDec(10, 2));
        ShipmentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);
        FindBlockedCustomer(Customer, CustomerNo);

        // Create a Sales Invoice by using Get Shipment Lines.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo2);
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        LibrarySales.GetShipmentLines(SalesLine);

        // Exercise: Post Sales Invoice.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Shipment Entry for Posted Sales Invoice after creating through Get Shipment Lines.
        VerifySalesShipment(SalesLine, ShipmentNo);
    end;

    [Test]
    [HandlerFunctions('NoSeriesPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderCreation()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        No: Code[20];
        CustomerNo: Code[20];
        ItemNo: Code[20];
    begin
        // Verify creation of Sales Order using page.

        // Setup: Update Sales And Receivable Setup, Create Customer and Item.
        Initialize();
        UpdateSalesReceivablesSetup(false, SalesReceivablesSetup."Credit Warnings"::"No Warning");
        ItemNo := CreateItem();
        CustomerNo := CreateCustomer();

        // Exercise: Create Sales Order.
        No := CreateSalesOrderWithPage(CustomerNo, ItemNo);

        // Verify: Verify Sales Order is created with given Customer and Item.
        SalesHeader.Get(SalesHeader."Document Type"::Order, No);
        SalesHeader.TestField("Sell-to Customer No.", CustomerNo);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.TestField("No.", ItemNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingPageHandler,EnterQuantityToCreatePageHandler,ConfirmHandlerYes,MessageHandler,NoSeriesPageHandler,ItemTrackingSummaryPageHandler,PostedItemTrackingLinesPageHadler')]
    [Scope('OnPrem')]
    procedure ItemTrackingOnPostedSalesDocument()
    var
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        No: Code[20];
        DocumentNo: Code[20];
        ItemNo: Code[20];
    begin
        // Verify Item Tracking Lines on Posted Sales Document.

        // Setup: Update Sales And Receivable Setup, Create and Post Item Journal Line and create Sales Order with Item Tracking Lines.
        Initialize();
        UpdateSalesReceivablesSetup(false, SalesReceivablesSetup."Credit Warnings"::"No Warning");
        ItemNo := CreateAndAssignItemTrackingOnItemJournal();
        No := CreateAndAssignItemTrackingOnSalesOrder(CreateCustomer(), ItemNo);
        SalesHeader.Get(SalesHeader."Document Type"::Order, No);
        UpdateGeneralPostingSetup(SalesHeader."Sell-to Customer No.", ItemNo);

        // Exercise.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Item Tracking Lines on Posted Sales Document.
        VerifyItemTrackingOnPostedSalesDocument(DocumentNo);
    end;

    [Test]
    [HandlerFunctions('NoSeriesPageHandler,DimensionSetEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure DimensionOnSalesOrder()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        DocumentNo: Code[20];
    begin
        // Verify Dimension on Sales Order through page.

        // Setup: Update Sales And Receivable Setup and Create Item.
        Initialize();
        UpdateSalesReceivablesSetup(false, SalesReceivablesSetup."Credit Warnings"::"No Warning");

        // Exercise: Create Customer with Dimension and Sales Order.
        DocumentNo := CreateSalesOrderWithPage(CreateCustomerWithDimension(), CreateItem());

        // Verify: Verify Dimension on Sales Order.
        VerifyDimensionOnSalesOrder(DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceDelete()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verify that Sales Invoice can be deleted.

        // Setup: Create a Customer and a Sales Invoice.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, Customer."No.", SalesLine.Type::Item, CreateItem());

        // Exercise: Delete the data of newly created Sales Invoice.
        SalesHeader.Delete(true);

        // Verify: Verify that the Sales Invoice gets deleted successfully.
        Assert.IsFalse(SalesHeader.Get(SalesHeader."Document Type"::Invoice, SalesHeader."No."), SalesInvoiceMustBeDeletedErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure SalesOrderWithDifferentBillToCustomerNo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
    begin
        // Test to validate Program populates information on Individual tab on Sales Order according to Bill To Customer No.

        // Setup: Create Sales Order.
        Initialize();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CreateCustomer(), SalesLine.Type::Item, CreateItem());

        // Exercise: Change Bill To Customer No.
        CustomerNo := CreateCustomer();
        SalesHeader.Validate("Bill-to Customer No.", CustomerNo);
        SalesHeader.Modify(true);

        // Verify: Sales Order With Different Bill To Customer No.
        VerifySalesOrder(SalesHeader."No.", CustomerNo, SalesLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DueDateOnSalesCreditMemoAfterCopyDocument()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Test Due Date is calculated on Sales Credit memo after running Copy Sales Document Report.
        DueDateOnSalesDocumentAfterCopyDocument(SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DueDateOnSalesReturnOrderAfterCopyDocument()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Test Due Date is calculated on Sales Return Order after running Copy Sales Document Report.
        DueDateOnSalesDocumentAfterCopyDocument(SalesHeader."Document Type"::"Return Order");
    end;

    [Test]
    [HandlerFunctions('SalesCodePageHandler')]
    [Scope('OnPrem')]
    procedure SalesLineWithStandardSalesCodeDimension()
    var
        DimensionValue1: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
        SalesHeader: Record "Sales Header";
        StandardSalesLine: Record "Standard Sales Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        // Check Sales Code Line with Dimensions are copied correctly in Sales Line.

        // Setup: Create Dimension Value.
        Initialize();
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue1, GeneralLedgerSetup."Shortcut Dimension 1 Code");
        LibraryDimension.CreateDimensionValue(DimensionValue2, GeneralLedgerSetup."Shortcut Dimension 2 Code");

        // Exercise: Create Sales Order with Sales Code.
        CreateSalesOrderWithSalesCode(SalesHeader, StandardSalesLine, CreateItem(), DimensionValue1.Code, DimensionValue2.Code);

        // Verify: Verify Sales Code Line are copied correctly in Sales Line.
        VerifySalesLine(StandardSalesLine, SalesHeader."No.", DimensionValue1.Code, DimensionValue2.Code);
    end;

    [Test]
    [HandlerFunctions('GetShipmentLinesHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CheckCreditLimitCustomerTotalAmount()
    var
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        CreditLimit: Decimal;
        TotalAmount: Decimal;
    begin
        // Verify Total Amount on Check Credit Limit page when having Invoice with Get Shipment Lines.

        // Setup: Set StockOut warning and Credit Warnings.
        Initialize();
        UpdateSalesReceivablesSetup(false, SalesReceivablesSetup."Credit Warnings"::"Credit Limit");

        CreditLimit := LibraryRandom.RandDec(100, 2);
        TotalAmount := CreateDocWithLineAndGetShipmentLine(SalesHeader, CreditLimit);
        LibraryVariableStorage.Enqueue(SalesHeader."Sell-to Customer No.");
        LibraryVariableStorage.Enqueue(SalesHeader."Sell-to Customer No.");
        LibraryVariableStorage.Enqueue(CreditLimit);
        LibraryVariableStorage.Enqueue(TotalAmount);
        OpenSalesOrderPageWithNewOrder(SalesHeader."Sell-to Customer No.");
        // Verify: Verification of the LineAmount is done in CreditLimitHandler.

        // Tear Down.
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('GetShipmentLinesHandler,SendNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CheckCreditLimitCustomerTotalAmountFromLine()
    var
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        CreditLimit: Decimal;
        TotalAmount: Decimal;
    begin
        // Verify Total Amount on Check Credit Limit page when having Invoice with Get Shipment Lines.
        // in case of Unit Price line validation

        // Setup: Set StockOut warning and Credit Warnings.
        Initialize();
        UpdateSalesReceivablesSetup(false, SalesReceivablesSetup."Credit Warnings"::"Credit Limit");

        CreditLimit := LibraryRandom.RandDec(100, 2);
        TotalAmount := CreateDocWithLineAndGetShipmentLine(SalesHeader, CreditLimit);
        LibraryVariableStorage.Enqueue(SalesHeader."Sell-to Customer No.");
        LibraryVariableStorage.Enqueue(SalesHeader."Sell-to Customer No.");

        LibraryVariableStorage.Enqueue(CreditLimit);
        LibraryVariableStorage.Enqueue(TotalAmount);
        OpenSalesInvoicePageAndValidateUnitPrice(SalesHeader."No.");
        // Verify: Verification of the Credit Limit is done in CreditLimitHandler.

        // Tear Down.
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure CreateDocWithLineAndGetShipmentLine(var NewSalesHeader: Record "Sales Header"; CreditLimit: Decimal) TotalAmount: Decimal
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Create and Ship Sales Order.

        CreateSalesDocumentFillUnitPrice(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CreateCustomerWithCreditLimit(CreditLimit),
          CreditLimit + LibraryRandom.RandDec(100, 2)); // Set Unit Price more than Credit Limit.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        TotalAmount := CalcTotalLineAmount(SalesHeader."Document Type", SalesHeader."No.");

        // Create Sales Invoice and Get Shipment Lines.
        CreateSalesDocumentFillUnitPrice(
          NewSalesHeader, SalesLine, NewSalesHeader."Document Type"::Invoice, SalesHeader."Sell-to Customer No.",
          LibraryRandom.RandDec(100, 2));

        TotalAmount += CalcTotalLineAmount(NewSalesHeader."Document Type", NewSalesHeader."No.");

        GetSalesDocumentShipmentLines(NewSalesHeader, SalesLine);

        exit(TotalAmount);
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceCopyDocBlankLines()
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        PostedSaleInvoiceNo: Code[20];
    begin
        // Create Sales Invoice with blank lines, copy Sales Document and check Sell-to Customer No.

        // Setup: Create Sales Invoice and post it.
        Initialize();
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, CreateCustomer(), SalesLine.Type::Item, CreateItem());
        CreateSalesBlankLines(SalesHeader);
        PostedSaleInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryVariableStorage.Enqueue(SalesHeader."Sell-to Customer No.");
        LibraryVariableStorage.Enqueue(SalesHeader."Sell-to Customer No.");
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader2."Document Type"::Invoice, SalesHeader."Sell-to Customer No.");
        Commit();

        // Exercise: Copy Sales Document.
        SalesCopyDocument(SalesHeader2, PostedSaleInvoiceNo, "Sales Document Type From"::"Posted Invoice", false);

        // Verify Sell-to Customer No. in copied lines.
        VerifySalesBlankLinesOnCopiedDocument(SalesHeader2."No.");
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('GetShipmentLinesHandler')]
    [Scope('OnPrem')]
    procedure LineDiscInPriceInclVATInvWithShptLinesFromPriceExclVATOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LineDiscAmt: Decimal;
        VATPercent: Decimal;
    begin
        // [FEATURE] [Discount]
        // [SCENARIO 109009] Line Discount Amount of Invoice with PricesInclVAT=TRUE generated by GetShptLines function from order with PricesExclVAT=FALSE is increased by VAT %
        Initialize();
        LineDiscAmt := LibraryRandom.RandDec(10, 2);

        // [GIVEN] Ship sales order with line discount LineDiscAmt and Prices Including VAT = FALSE
        CreateShipSalesOrderWithPricesInclVATAndLineDisc(SalesHeader, VATPercent, LineDiscAmt, false);

        // [GIVEN] Sales Invoice with Prices Including VAT = TRUE
        CreateSalesInvWithPricesInclVAT(SalesLine, SalesHeader."Sell-to Customer No.", true);

        // [WHEN] Invoice Line created from Shipment Line
        LibrarySales.GetShipmentLines(SalesLine);

        // [THEN] Line Discount Amount on Invoice is InvLineDiscAmt
        VerifyLineDiscAmountInLine(SalesLine."Document No.", Round(LineDiscAmt * (1 + VATPercent / 100)));
    end;

    [Test]
    [HandlerFunctions('GetShipmentLinesHandler')]
    [Scope('OnPrem')]
    procedure LineDiscInPriceExclVATInvWithShptLinesFromPriceInclVATOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LineDiscAmt: Decimal;
        VATPercent: Decimal;
    begin
        // [FEATURE] [Discount]
        // [SCENARIO 109009] Line Discount Amount of Invoice with PricesExclVAT=FALSE generated by GetShptLines function from order with PricesInclVAT=TRUE is decreased by VAT %
        Initialize();
        LineDiscAmt := LibraryRandom.RandDec(10, 2);

        // [GIVEN] Ship sales order with line discount LineDiscAmt and Prices Including VAT = TRUE
        CreateShipSalesOrderWithPricesInclVATAndLineDisc(SalesHeader, VATPercent, LineDiscAmt, true);

        // [GIVEN] Sales Invoice with Prices Including VAT = FALSE
        CreateSalesInvWithPricesInclVAT(SalesLine, SalesHeader."Sell-to Customer No.", false);

        // [WHEN] Invoice Line created from Shipment Line
        LibrarySales.GetShipmentLines(SalesLine);

        // [THEN] Line Discount Amount on Invoice is InvLineDiscAmt
        VerifyLineDiscAmountInLine(SalesLine."Document No.", Round(LineDiscAmt / (1 + VATPercent / 100)));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteLineWithExtendedTextInSaleOrder()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
    begin
        // [FEATURE] [Extended Text] [Sales Order] [Invoice Discount]
        // [SCENARIO 363756] Sales Line is deleted from Sales Order when there is Extended Text and "Calc Inv. Discount" is TRUE
        Initialize();
        UpdateSalesReceivablesSetupForCalcInvDiscount(true);

        // [GIVEN] Item "X" with Extended Text
        CreateItemAndExtendedText(Item);

        // [GIVEN] Sales Header
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [GIVEN] Sales Line with Item, second Sales Line with Extended Text
        CreateSalesLineWithExtendedText(SalesHeader, Item."No.");

        // [GIVEN] Sales - Calc Discount By Type calculation
        SalesCalcDiscountByType.ApplyDefaultInvoiceDiscount(0, SalesHeader);
        Commit(); // Commit to close transaction.

        // [WHEN] Delete Sales Line with Item
        DeleteSalesLine(SalesHeader."No.", SalesLine.Type::Item, Item."No.");

        // [THEN] Sales Lines with Extended Text of "X" deleted
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("No.", Item."No.");
        Assert.RecordIsEmpty(SalesLine);
    end;

    [Test]
    [HandlerFunctions('GetShipmentLinesHandler')]
    [Scope('OnPrem')]
    procedure DeleteLineWithExtendedTextInSaleOrderWithShptLines()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
        LineDiscAmt: Decimal;
        VATPercent: Decimal;
    begin
        // [FEATURE] [Extended Text] [Sales Order] [Invoice Discount]
        // [SCENARIO 363756] Sales Line is deleted from Sales Invoice when there is Extended Text and Shipment Lines
        Initialize();
        UpdateSalesReceivablesSetupForCalcInvDiscount(true);
        LineDiscAmt := LibraryRandom.RandDec(10, 2);

        // [GIVEN] Ship sales order with line discount LineDiscAmt and Prices Including VAT = FALSE
        CreateShipSalesOrderWithPricesInclVATAndLineDisc(SalesHeader, VATPercent, LineDiscAmt, false);

        // [GIVEN] Sales Invoice with Prices Including VAT = TRUE
        CreateSalesInvWithPricesInclVAT(SalesLine, SalesHeader."Sell-to Customer No.", true);

        // [WHEN] Invoice Line created from Shipment Line
        LibrarySales.GetShipmentLines(SalesLine);

        // [GIVEN] Item "X" with Extended Text
        CreateItemAndExtendedText(Item);
        // [GIVEN] Sales Line with Item, second Sales Line with Extended Text
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        CreateSalesLineWithExtendedText(SalesHeader, Item."No.");

        // [GIVEN] Sales - Calc Discount By Type calculation
        SalesCalcDiscountByType.ApplyDefaultInvoiceDiscount(0, SalesHeader);
        Commit(); // Commit to close transaction.

        // [WHEN] Delete Sales Line with Item
        DeleteSalesLine(SalesHeader."No.", SalesLine.Type::Item, Item."No.");

        // [THEN] Line Discount Amount on Invoice is InvLineDiscAmt - NA differs from W1
        VerifyLineDiscAmountInLine(SalesLine."Document No.", Round(LineDiscAmt * (1 + VATPercent / 100)));
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CheckCreditLimitSalesOrderLineAmountIncrease()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        NewUnitPrice: Decimal;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales Order] [Credit Limit]
        // [SCENARIO 363418] Credit Limit Warning Page correctly shows values in case of Sales Order Line Amount increase
        // TFS 272033: Overdue balance calculates based on Due Date less than WorkDate on Credit Limit Warning page

        Initialize();
        UpdateSalesReceivablesSetup(false, SalesReceivablesSetup."Credit Warnings"::"Credit Limit");

        // [GIVEN] Customer with "Credit Limit" = 199.99 (100 + 70 + 30 - 0.01)
        // [GIVEN] Posted Sales Order 1 with Line Amount = 100.
        // [GIVEN] Sales Order 2 with Line Amount = 70.
        // [GIVEN] Sales Order 3 with Line Amount = 15.
        DocumentNo := CreditLimitSalesDocLineUnitPriceIncrease(SalesHeader."Document Type"::Order, NewUnitPrice);
        // [WHEN] Change Line Amount from 15 to 30 in Sales Order 3
        OpenSalesOrderAndValidateUnitPrice(DocumentNo, NewUnitPrice);

        // [THEN] Credit Limit Warning page is shown with following values:
        // [THEN] "Outstanding Amt. (LCY)" = 100 (70 + 30)
        // [THEN] "Current Amount (LCY)" = 30
        // [THEN] "Total Amount (LCY)" = 200 (100 + 70 + 30)
        // [THEN] "Credit Limit (LCY)" = 199.99

        // Verify in SendNotificationHandler
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CheckCreditLimitSalesOrderLineAmountDecrease()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        NewUnitPrice: Decimal;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales Order] [Credit Limit]
        // [SCENARIO 363418] Credit Limit Warning Page correctly shows values in case of Sales Order Line Amount decrease
        // TFS 272033: Overdue balance calculates based on Due Date less than WorkDate on Credit Limit Warning page

        Initialize();
        UpdateSalesReceivablesSetup(false, SalesReceivablesSetup."Credit Warnings"::"Credit Limit");

        // [GIVEN] Customer with "Credit Limit" = 184.99 (100 + 70 + 15 - 0.01)
        // [GIVEN] Posted Sales Order 1 with Line Amount = 100.
        // [GIVEN] Sales Order 2 with Line Amount = 70.
        // [GIVEN] Sales Order 3 with Line Amount = 30.
        DocumentNo := CreditLimitSalesDocLineUnitPriceDecrease(SalesHeader."Document Type"::Order, NewUnitPrice);

        // [WHEN] Change Line Amount from 30 to 15 in Sales Order 3
        OpenSalesOrderAndValidateUnitPrice(DocumentNo, NewUnitPrice);

        // [THEN] Credit Limit Warning page is shown with following values:
        // [THEN] "Outstanding Amt. (LCY)" = 85 (70 + 15)
        // [THEN] "Current Amount (LCY)" = 15
        // [THEN] "Total Amount (LCY)" = 185 (100 + 70 + 15)
        // [THEN] "Credit Limit (LCY)" = 184.99

        // Verify in SendNotificationHandler
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CheckCreditLimitSalesInvoiceLineAmountIncrease()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        NewUnitPrice: Decimal;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales Invoice] [Credit Limit]
        // [SCENARIO 363418] Credit Limit Warning Page correctly shows values in case of Sales Invoice Line Amount increase
        // TFS 272033: Overdue balance calculates based on Due Date less than WorkDate on Credit Limit Warning page

        Initialize();
        UpdateSalesReceivablesSetup(false, SalesReceivablesSetup."Credit Warnings"::"Credit Limit");

        // [GIVEN] Customer with "Credit Limit" = 199.99 (100 + 70 + 30 - 0.01)
        // [GIVEN] Posted Sales Invoice 1 with Line Amount = 100.
        // [GIVEN] Sales Invoice 2 with Line Amount = 70.
        // [GIVEN] Sales Invoice 3 with Line Amount = 15.
        DocumentNo := CreditLimitSalesDocLineUnitPriceIncrease(SalesHeader."Document Type"::Invoice, NewUnitPrice);

        // [WHEN] Change Line Amount from 15 to 30 in Sales Invoice 3
        OpenSalesInvoiceAndValidateUnitPrice(DocumentNo, NewUnitPrice);

        // [THEN] Credit Limit Warning page is shown with following values:
        // [THEN] "Outstanding Amt. (LCY)" = 100 (70 + 30)
        // [THEN] "Current Amount (LCY)" = 30
        // [THEN] "Total Amount (LCY)" = 200 (100 + 70 + 30)
        // [THEN] "Credit Limit (LCY)" = 199.99

        // Verify in SendNotificationHandler
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CheckCreditLimitSalesInvoiceLineAmountDecrease()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        NewUnitPrice: Decimal;
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales Invoice] [Credit Limit]
        // [SCENARIO 363418] Credit Limit Warning Page correctly shows values in case of Sales Invoice Line Amount decrease
        // TFS 272033: Overdue balance calculates based on Due Date less than WorkDate on Credit Limit Warning page

        Initialize();
        UpdateSalesReceivablesSetup(false, SalesReceivablesSetup."Credit Warnings"::"Credit Limit");

        // [GIVEN] Customer with "Credit Limit" = 184.99 (100 + 70 + 15 - 0.01)
        // [GIVEN] Posted Sales Invoice 1 with Line Amount = 100.
        // [GIVEN] Sales Invoice 2 with Line Amount = 70.
        // [GIVEN] Sales Invoice 3 with Line Amount = 30.
        DocumentNo := CreditLimitSalesDocLineUnitPriceDecrease(SalesHeader."Document Type"::Invoice, NewUnitPrice);

        // [WHEN] Change Line Amount from 30 to 15 in Sales Invoice 3
        OpenSalesInvoiceAndValidateUnitPrice(DocumentNo, NewUnitPrice);

        // [THEN] Credit Limit Warning page is shown with following values:
        // [THEN] "Outstanding Amt. (LCY)" = 85 (70 + 15)
        // [THEN] "Current Amount (LCY)" = 15
        // [THEN] "Total Amount (LCY)" = 185 (100 + 70 + 15)
        // [THEN] "Credit Limit (LCY)" = 184.99

        // Verify in CreditLimitWarningMPH
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('SalesCodePageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckAssemblyOrderCreatedWithinStdCustSalesCode()
    var
        SalesHeader: Record "Sales Header";
        StandardSalesLine: Record "Standard Sales Line";
        Item: Record Item;
        AssemblyHeader: Record "Assembly Header";
    begin
        // [FEATURE] [Standard Sales Code] [Assembly]
        // [SCENARIO 371759] The Assembly Order should be created when a Standard Code with an Assembled Item is applied to a Sales Order
        Initialize();

        // [GIVEN] Std Cust. Sales Code for Assembly Item
        CreateAssembledItem(Item);

        // [WHEN] Get Std Cust. Sales Code on Sales Order, where Sales Line Quantity is "X"
        CreateSalesOrderWithSalesCode(SalesHeader, StandardSalesLine, Item."No.", '', '');

        // [THEN] Assemly Order is created, where Quantity is "X"
        AssemblyHeader.SetRange("Item No.", Item."No.");
        AssemblyHeader.FindFirst();
        AssemblyHeader.TestField(Quantity, StandardSalesLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_DeleteCustomerPriceGroupWithSalesPrice()
    var
        CustomerPriceGroup: Record "Customer Price Group";
        SalesPrice: Record "Sales Price";
    begin
        // [FEATURE] [UT] [Customer Price Group] [Sales Price]
        // [SCENARIO 364564] Delete related "Sales Price" when "Customer Price Group" is deleted

        // [GIVEN] Customer Price Group = "X"
        // [GIVEN] Sales Price with "Sales Type" = "Customer Price Group" and "Sales Code" = "X"
        Initialize();
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        LibraryCosting.CreateSalesPrice(
          SalesPrice, SalesPrice."Sales Type"::"Customer Price Group", CustomerPriceGroup.Code,
          LibraryInventory.CreateItemNo(), WorkDate(), '', '', '', LibraryRandom.RandInt(100));

        // [WHEN] Delete Customer Price Group
        CustomerPriceGroup.Delete(true);

        // [THEN] Sales Price is removed
        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::"Customer Price Group");
        SalesPrice.SetRange("Sales Code", CustomerPriceGroup.Code);
        Assert.RecordIsEmpty(SalesPrice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_RenameSalesPriceOnCustomerPriceGroupRename()
    var
        CustomerPriceGroup: Record "Customer Price Group";
        SalesPrice: Record "Sales Price";
        NewCustPriceGroupCode: Code[10];
        OldCustPriceGroupCode: Code[10];
    begin
        // [FEATURE] [UT] [Customer Price Group] [Sales Price]
        // [SCENARIO 364564] Rename related "Sales Price" when "Customer Price Group" is renamed

        // [GIVEN] Customer Price Group = "X"
        // [GIVEN] Sales Price with "Sales Type" = "Customer Price Group" and "Sales Code" = "X"
        Initialize();
        LibrarySales.CreateCustomerPriceGroup(CustomerPriceGroup);
        LibraryCosting.CreateSalesPrice(
          SalesPrice, SalesPrice."Sales Type"::"Customer Price Group", CustomerPriceGroup.Code,
          LibraryInventory.CreateItemNo(), WorkDate(), '', '', '', LibraryRandom.RandInt(100));
        OldCustPriceGroupCode := CustomerPriceGroup.Code;
        NewCustPriceGroupCode := LibraryUtility.GenerateGUID();

        // [WHEN] Rename Customer Price Group from "X" to "Y"
        CustomerPriceGroup.Rename(NewCustPriceGroupCode);

        // [THEN] Sales Price with "Sales Code" = "Y" is created
        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::"Customer Price Group");
        SalesPrice.SetRange("Sales Code", NewCustPriceGroupCode);
        Assert.RecordIsNotEmpty(SalesPrice);
        // [THEN] Sales Price with "Sales Code" = "X" is removed
        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::"Customer Price Group");
        SalesPrice.SetRange("Sales Code", OldCustPriceGroupCode);
        Assert.RecordIsEmpty(SalesPrice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_RenamingSalesPriceWhenRenameCustomer()
    var
        Customer: Record Customer;
        SalesPrice: Record "Sales Price";
        OldCustomerNo: Code[20];
    begin
        // [FEATURE] [UT] [Customer] [Sales Price]
        // [SCENARIO 382057] "Sales Price" record has been renamed in case of rename of related customer
        Initialize();

        // [GIVEN] Customer "A" with Sales Price: "Sales Type" = "Customer", "Sales Code" = "A"
        LibrarySales.CreateCustomer(Customer);
        OldCustomerNo := Customer."No.";
        LibrarySales.CreateSalesPrice(
          SalesPrice, LibraryInventory.CreateItemNo(), SalesPrice."Sales Type"::Customer, Customer."No.", WorkDate(), '', '', '', 0, 0);

        // [WHEN] Rename customer from "A" to "B"
        Customer.Rename(LibraryUtility.GenerateGUID());

        // [THEN] There is no sales price record with "Sales Type" = "Customer", "Sales Code" = "A"
        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::Customer);
        SalesPrice.SetRange("Sales Code", OldCustomerNo);
        Assert.RecordIsEmpty(SalesPrice);

        // [THEN] There is a sales price record with "Sales Type" = "Customer", "Sales Code" = "B"
        SalesPrice.SetRange("Sales Code", Customer."No.");
        Assert.RecordIsNotEmpty(SalesPrice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_RenamingSalesLineDiscountWhenRenameCustomer()
    var
        Customer: Record Customer;
        SalesLineDiscount: Record "Sales Line Discount";
        OldCustomerNo: Code[20];
    begin
        // [FEATURE] [UT] [Customer] [Sales Line Discount]
        // [SCENARIO 382057] "Sales Line Discount" record has been renamed in case of rename of related customer
        Initialize();

        // [GIVEN] Customer "A" with Sales Line Discount: "Sales Type" = "Customer", "Sales Code" = "A"
        LibrarySales.CreateCustomer(Customer);
        OldCustomerNo := Customer."No.";
        LibraryERM.CreateLineDiscForCustomer(
          SalesLineDiscount, SalesLineDiscount.Type::Item, LibraryInventory.CreateItemNo(),
          SalesLineDiscount."Sales Type"::Customer, Customer."No.",
          WorkDate(), '', '', SalesLineDiscount."Unit of Measure Code", 0);

        // [WHEN] Rename customer from "A" to "B"
        Customer.Rename(LibraryUtility.GenerateGUID());

        // [THEN] There is no sales line discount record with "Sales Type" = "Customer", "Sales Code" = "A"
        SalesLineDiscount.SetRange("Sales Type", SalesLineDiscount."Sales Type"::Customer);
        SalesLineDiscount.SetRange("Sales Code", OldCustomerNo);
        Assert.RecordIsEmpty(SalesLineDiscount);

        // [THEN] There is a sales line discount record with "Sales Type" = "Customer", "Sales Code" = "B"
        SalesLineDiscount.SetRange("Sales Code", Customer."No.");
        Assert.RecordIsNotEmpty(SalesLineDiscount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_RenameItemExistsInSalesInvoice()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 201723] Sales Line with Item updates when Item is renamed

        Initialize();

        LibraryInventory.CreateItem(Item);
        MockSalesLine(SalesLine, LibrarySales.CreateCustomerNo(), SalesLine.Type::Item, Item."No.");

        Item.Rename(LibraryUtility.GenerateRandomCode(Item.FieldNo("No."), DATABASE::Item));

        SalesLine.Find();
        SalesLine.TestField("No.", Item."No.");

        // Tear down
        SalesLine.Delete();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UT_RenameItemVariantExistsInSalesInvoice()
    var
        Item: array[2] of Record Item;
        ItemVariant: Record "Item Variant";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 496448] Sales Line with Item Variant updates when Item Variant "Code" is renamed.
        // [SCENARIO 496448] Sales Line with Item Variant raises error when Item Variant "Item No." is renamed.
        Initialize();

        LibraryInventory.CreateItem(Item[1]);
        LibraryInventory.CreateItem(Item[2]);
        LibraryInventory.CreateItemVariant(ItemVariant, Item[1]."No.");
        MockSalesLine(SalesLine, LibrarySales.CreateCustomerNo(), SalesLine.Type::Item, Item[1]."No.");
        SalesLine.Validate("Variant Code", ItemVariant.Code);
        SalesLine.Modify(true);

        // [WHEN] Rename Item Variant "Code"
        ItemVariant.Rename(ItemVariant."Item No.", LibraryUtility.GenerateRandomCode(ItemVariant.FieldNo(Code), Database::"Item Variant"));

        // [THEN] Sales Line with Item Variant is updated to the new "Code"
        SalesLine.Find('=');
        SalesLine.TestField("Variant Code", ItemVariant.Code);

        // [WHEN] Rename Item Variant "Item No."
        asserterror ItemVariant.Rename(Item[2]."No.", ItemVariant.Code);

        // [THEN] Error is raised
        Assert.ExpectedError(StrSubstNo(CannotRenameItemUsedInSalesLinesErr, ItemVariant.FieldCaption("Item No."), ItemVariant.TableCaption()));
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UT_RenameResourceExistsInSalesInvoice()
    var
        Customer: Record Customer;
        Resource: Record Resource;
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 201723] Sales Line with Resource updates when Resource is renamed

        Initialize();

        LibrarySales.CreateCustomer(Customer);
        LibraryResource.CreateResource(Resource, Customer."VAT Bus. Posting Group");
        MockSalesLine(SalesLine, Customer."No.", SalesLine.Type::Resource, Resource."No.");

        Resource.Rename(LibraryUtility.GenerateGUID());

        SalesLine.Find();
        SalesLine.TestField("No.", Resource."No.");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UT_RenameGLAccountExistsInSalesInvoice()
    var
        GLAccount: Record "G/L Account";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 201723] Sales Line with G/L Account updates when G/L Account is renamed

        Initialize();

        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        MockSalesLine(SalesLine, LibrarySales.CreateCustomerNo(), SalesLine.Type::"G/L Account", GLAccount."No.");

        GLAccount.Rename(LibraryUtility.GenerateGUID());

        SalesLine.Find();
        SalesLine.TestField("No.", GLAccount."No.");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UT_RenameFixedAssetExistsInSalesInvoice()
    var
        FixedAsset: Record "Fixed Asset";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 201723] Sales Line with Fixed Asset updates when Fixed Asset is renamed

        Initialize();

        LibraryFixedAsset.CreateFixedAssetWithSetup(FixedAsset);
        MockSalesLine(SalesLine, LibrarySales.CreateCustomerNo(), SalesLine.Type::"Fixed Asset", FixedAsset."No.");

        FixedAsset.Rename(LibraryUtility.GenerateGUID());

        SalesLine.Find();
        SalesLine.TestField("No.", FixedAsset."No.");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UT_RenameItemChargeExistsInSalesInvoice()
    var
        ItemCharge: Record "Item Charge";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 201723] Sales Line with Item Charge updates when Item Charge is renamed

        Initialize();

        LibraryInventory.CreateItemCharge(ItemCharge);
        MockSalesLine(SalesLine, LibrarySales.CreateCustomerNo(), SalesLine.Type::"Charge (Item)", ItemCharge."No.");

        ItemCharge.Rename(LibraryUtility.GenerateGUID());

        SalesLine.Find();
        SalesLine.TestField("No.", ItemCharge."No.");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UT_SalesLineItemChargeUOMWhenPacEnabled()
    var
        ItemCharge: Record "Item Charge";
        ItemCharge2: Record "Item Charge";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Given Pac Environment is not Disabled
        // A Sales line of type should be able to be created without the validation for Unit of measure triggering an error.

        Initialize();

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."PAC Environment" := GeneralLedgerSetup."PAC Environment"::Test;
        GeneralLedgerSetup.Modify();

        LibraryInventory.CreateItemCharge(ItemCharge);
        MockSalesLine(SalesLine, LibrarySales.CreateCustomerNo(), SalesLine.Type::"Charge (Item)", ItemCharge."No.");

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."PAC Environment" := GeneralLedgerSetup."PAC Environment"::Production;
        GeneralLedgerSetup.Modify();

        LibraryInventory.CreateItemCharge(ItemCharge2);
        MockSalesLine(SalesLine2, LibrarySales.CreateCustomerNo(), SalesLine2.Type::"Charge (Item)", ItemCharge2."No.");

        // [WHEN] Addition 464851 - Validate Quantity to 1 and change Item Charge
        SalesLine2.Validate(Quantity, 1);
        SalesLine2.Modify();
        SalesLine2.Validate("No.", ItemCharge."No.");
        SalesLine2.Modify();

        // [THEN] Addition 464851 - Verify that Quantity (Base) remains 1
        SalesLine2.TestField("Quantity (Base)", 1);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UT_SalesLineFixedAssetUOMWhenPacEnabled()
    var
        FixedAsset: Record "Fixed Asset";
        FixedAsset2: Record "Fixed Asset";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Given Pac Environment is not Disabled
        // A Sales line of type should be able to be created without the validation for Unit of measure triggering an error.

        Initialize();

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."PAC Environment" := GeneralLedgerSetup."PAC Environment"::Test;
        GeneralLedgerSetup.Modify();

        LibraryFixedAsset.CreateFixedAssetWithSetup(FixedAsset);
        MockSalesLine(SalesLine, LibrarySales.CreateCustomerNo(), SalesLine.Type::"Fixed Asset", FixedAsset."No.");

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."PAC Environment" := GeneralLedgerSetup."PAC Environment"::Production;
        GeneralLedgerSetup.Modify();

        LibraryFixedAsset.CreateFixedAssetWithSetup(FixedAsset2);
        MockSalesLine(SalesLine2, LibrarySales.CreateCustomerNo(), SalesLine2.Type::"Fixed Asset", FixedAsset2."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostAndCreateNewSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        NewSalesInvoice: TestPage "Sales Invoice";
    begin
        Initialize();

        // Setup
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader,
          SalesLine, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo(),
          LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(100, 2), '', WorkDate());

        // Exercise
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        NewSalesInvoice.Trap();
        SalesInvoice.PostAndNew.Invoke();

        // Verify
        NewSalesInvoice."No.".AssertEquals(IncStr(SalesHeader."No."));
        NewSalesInvoice.Close();
    end;

    [Test]
    [HandlerFunctions('SalesOptionDialogHandler')]
    [Scope('OnPrem')]
    procedure PostAndCreateNewSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        NewSalesOrder: TestPage "Sales Order";
    begin
        Initialize();

        // Setup
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader,
          SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(100, 2), '', WorkDate());

        LibraryVariableStorage.Enqueue(3); // Ship and Invoice during post

        // Exercise
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        NewSalesOrder.Trap();
        SalesOrder.PostAndNew.Invoke();

        // Verify
        NewSalesOrder."No.".AssertEquals(IncStr(SalesHeader."No."));
        NewSalesOrder.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    [Scope('OnPrem')]
    procedure CancelPostOnPostAndNewSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        Initialize();

        // Setup
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader,
          SalesLine, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo(),
          LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(100, 2), '', WorkDate());

        // Exercise
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice.PostAndNew.Invoke();

        // Verify SalesInvoice page is still open and accessible
        SalesInvoice."No.".AssertEquals(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('SalesOptionDialogHandler')]
    [Scope('OnPrem')]
    procedure CancelPostOnPostAndNewSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        Initialize();

        // Setup
        LibrarySales.CreateSalesDocumentWithItem(SalesHeader,
          SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(100, 2), '', WorkDate());

        LibraryVariableStorage.Enqueue(0); // Cancel post action

        // Exercise
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.PostAndNew.Invoke();

        // Verify SalesInvoice page is still open and accessible
        SalesOrder."No.".AssertEquals(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CustCreditLimitOnNewSalesQuoteFromCustomerCard()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Customer: Record Customer;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        CustomerCard: TestPage "Customer Card";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [Quote] [Credit Limit] [UI]
        // [SCENARIO 378849] Customer credit limit warning page is shown when create new Sales Quote from customer card
        UpdateSalesReceivablesSetup(false, SalesReceivablesSetup."Credit Warnings"::"Both Warnings");

        // [GIVEN] Customer with Credit Limit and overdue balance
        CreateCustomerWithCreditLimitAndOverdue(Customer);
        // [GIVEN] Open Customer Card
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        // [WHEN] Perform page action: New Sales Document -> Sales Quote
        SalesQuote.Trap();
        CustomerCard.NewSalesQuote.Invoke();

        // [THEN] Customer credit limit warning page is opened
        // Verify page values in NotificationDetailsHandler
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CustCreditLimitOnNewSalesOrderFromCustomerCard()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Customer: Record Customer;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        CustomerCard: TestPage "Customer Card";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Order] [Credit Limit] [UI]
        // [SCENARIO 378849] Customer credit limit warning page is shown when create new Sales Order from customer card

        Initialize();
        UpdateSalesReceivablesSetup(false, SalesReceivablesSetup."Credit Warnings"::"Both Warnings");

        // [GIVEN] Customer with Credit Limit and overdue balance
        CreateCustomerWithCreditLimitAndOverdue(Customer);
        // [GIVEN] Open Customer Card
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);

        // [WHEN] Perform page action: New Sales Document -> Sales Order
        SalesOrder.Trap();
        CustomerCard.NewSalesOrder.Invoke();
        SalesOrder."Ship-to Address 2".SetValue(''); // dummy validate to move page cursor from "No." field

        // [THEN] Customer credit limit warning page is opened
        // Verify page values in NotificationDetailsHandler
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CustCreditLimitOnNewBlanketSalesOrderFromCustomerCard()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Customer: Record Customer;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        CustomerCard: TestPage "Customer Card";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        // [FEATURE] [Blanket Order] [Credit Limit] [UI]
        // [SCENARIO 378849] Customer credit limit warning page is shown when create new Blanket Sales Order from customer card

        Initialize();
        UpdateSalesReceivablesSetup(false, SalesReceivablesSetup."Credit Warnings"::"Both Warnings");

        // [GIVEN] Customer with Credit Limit and overdue balance
        CreateCustomerWithCreditLimitAndOverdue(Customer);
        // [GIVEN] Open Customer Card
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        LibraryVariableStorage.Enqueue(Customer."No.");
        // [WHEN] Perform page action: New Sales Document -> Blanket Sales Order
        BlanketSalesOrder.Trap();
        CustomerCard.NewBlanketSalesOrder.Invoke();

        // [THEN] Customer credit limit warning page is opened
        // Verify page values in NotificationDetailsHandler
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CustCreditLimitOnNewSalesReturnOrderFromCustomerCard()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Customer: Record Customer;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        CustomerCard: TestPage "Customer Card";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // [FEATURE] [Return Order] [Credit Limit] [UI]
        // [SCENARIO 378849] Customer credit limit warning page is shown when create new Sales Return Order from customer card

        Initialize();
        UpdateSalesReceivablesSetup(false, SalesReceivablesSetup."Credit Warnings"::"Both Warnings");

        // [GIVEN] Customer with Credit Limit and overdue balance
        CreateCustomerWithCreditLimitAndOverdue(Customer);
        // [GIVEN] Open Customer Card
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        LibraryVariableStorage.Enqueue(Customer."No.");
        // [WHEN] Perform page action: New Sales Document -> Sales Return Order
        SalesReturnOrder.Trap();
        CustomerCard.NewSalesReturnOrder.Invoke();

        // [THEN] Customer credit limit warning page is opened
        // Verify page values in NotificationDetailsHandler
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CustCreditLimitOnNewSalesInvoiceFromCustomerCard()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Customer: Record Customer;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        CustomerCard: TestPage "Customer Card";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [Invoice] [Credit Limit] [UI]
        // [SCENARIO 378849] Customer credit limit warning page is shown when create new Sales Invoice from customer card

        Initialize();
        UpdateSalesReceivablesSetup(false, SalesReceivablesSetup."Credit Warnings"::"Both Warnings");

        // [GIVEN] Customer with Credit Limit and overdue balance
        CreateCustomerWithCreditLimitAndOverdue(Customer);
        // [GIVEN] Open Customer Card
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        LibraryVariableStorage.Enqueue(Customer."No.");
        // [WHEN] Perform page action: New Sales Document -> Sales Invoice
        SalesInvoice.Trap();
        CustomerCard.NewSalesInvoice.Invoke();

        // [THEN] Customer credit limit warning page is opened
        // Verify page values in NotificationDetailsHandler
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,NotificationDetailsHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CustCreditLimitOnNewSalesCreditMemoFromCustomerCard()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Customer: Record Customer;
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        CustomerCard: TestPage "Customer Card";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [Credit Memo] [Credit Limit] [UI]
        // [SCENARIO 378849] Customer credit limit warning page is shown when create new Sales Credit Memo from customer card

        Initialize();
        UpdateSalesReceivablesSetup(false, SalesReceivablesSetup."Credit Warnings"::"Both Warnings");

        // [GIVEN] Customer with Credit Limit and overdue balance
        CreateCustomerWithCreditLimitAndOverdue(Customer);
        // [GIVEN] Open Customer Card
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        LibraryVariableStorage.Enqueue(Customer."No.");
        // [WHEN] Perform page action: New Sales Document -> Sales Credit Memo
        SalesCreditMemo.Trap();
        CustomerCard.NewSalesCreditMemo.Invoke();

        // [THEN] Customer credit limit warning page is opened
        // Verify page values in NotificationDetailsHandler
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPriceMinimumQuantityWithMaxValue()
    var
        SalesPrice: Record "Sales Price";
        SalesPrices: TestPage "Sales Prices";
    begin
        // [FEATURE] [Sales Price] [UT] [UI]
        // [SCENARIO 381273] User should be able to input value with 5 decimals in "Minimum Quantity" field of Sales Price table
        CreateSalesPriceWithMinimumQuantity(SalesPrice, 0.12345);
        SalesPrices.OpenView();
        SalesPrices.SalesTypeFilter.SetValue(SalesPrice."Sales Type"::"All Customers");
        SalesPrices.GotoRecord(SalesPrice);
        Assert.AreEqual(Format(0.12345), SalesPrices."Minimum Quantity".Value, SalesPrice.FieldCaption("Minimum Quantity"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesPriceMinimumQuantityOverMaxValue()
    var
        SalesPrice: Record "Sales Price";
        SalesPrices: TestPage "Sales Prices";
    begin
        // [FEATURE] [Sales Price] [UT] [UI]
        // [SCENARIO 381273] User should not be able to input value with more than 5 decimals in "Minimum Quantity" field of Sales Price table
        CreateSalesPriceWithMinimumQuantity(SalesPrice, 0.123456);
        SalesPrices.OpenView();
        SalesPrices.SalesTypeFilter.SetValue(SalesPrice."Sales Type"::"All Customers");
        SalesPrices.GotoRecord(SalesPrice);
        Assert.AreNotEqual(Format(0.123456), SalesPrices."Minimum Quantity".Value, SalesPrice.FieldCaption("Minimum Quantity"));
        Assert.AreEqual(Format(0.12346), SalesPrices."Minimum Quantity".Value, SalesPrice.FieldCaption("Minimum Quantity"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ArchivedSalesQuoteReportWithPricesInclVATAndTwoLines()
    var
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        TotalBaseAmount: Decimal;
        TotalVATAmount: Decimal;
    begin
        // [FEATURE] [Report] [Archive] [Prices Incl. VAT] [Quote]
        // [SCENARIO 381574] Report 215 "Archived Sales Quote" correctly prints total vat base/amount in case of "Prices Including VAT" = TRUE and two lines with different VAT setup
        Initialize();
        UpdateSalesLogoPositionSetup();

        // [GIVEN] Sales quote with "Prices Including VAT" = TRUE, two lines with different VAT Setup
        CreateSalesQuoteWithTwoVATSetupLines(VATPostingSetup, SalesHeader, TotalBaseAmount, TotalVATAmount, true);
        // [GIVEN] Archive sales quote
        ArchiveSalesDocument(SalesHeader);

        // [WHEN] Print archived sales quote (REP 215 "Archived Sales Quote")
        RunArchivedSalesQuoteReport(SalesHeader);

        // [THEN] Report correctly prints total VAT Amount and Total VAT Base Amount
        VerifyArchiveDocExcelTotalVATBaseAmount('AK', 48, TotalVATAmount, TotalBaseAmount);

        // Tear Down
        VATPostingSetup[1].Delete(true);
        VATPostingSetup[2].Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ArchivedSalesOrderReportWithPricesInclVATAndTwoLines()
    var
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        TotalBaseAmount: Decimal;
        TotalVATAmount: Decimal;
    begin
        // [FEATURE] [Report] [Archive] [Prices Incl. VAT] [Order]
        // [SCENARIO 381574] Report 216 "Archived Sales Order" correctly prints total vat base/amount in case of "Prices Including VAT" = TRUE and two lines with different VAT Setup
        Initialize();
        UpdateSalesLogoPositionSetup();

        // [GIVEN] Sales order with "Prices Including VAT" = TRUE, two lines with different VAT Setup
        CreateSalesOrderWithTwoVATSetupLines(VATPostingSetup, SalesHeader, TotalBaseAmount, TotalVATAmount, true);
        // [GIVEN] Archive sales order
        ArchiveSalesDocument(SalesHeader);

        // [WHEN] Print archived sales order (REP 216 "Archived Sales Order")
        RunArchivedSalesOrderReportAsXml(SalesHeader);
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Report correctly prints total VAT Amount and Total VAT Base Amount
        LibraryReportDataset.SearchForElementByValue('//Column[@name=''VATAmount'']', TotalVATAmount);
        LibraryReportDataset.SearchForElementByValue('//Column[@name=''VATBaseAmount'']', TotalBaseAmount);

        // Tear Down
        VATPostingSetup[1].Delete(true);
        VATPostingSetup[2].Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ArchivedSalesQuoteReportWithoutPricesInclVATAndTwoLines()
    var
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        TotalBaseAmount: Decimal;
        TotalVATAmount: Decimal;
    begin
        // [FEATURE] [Report] [Archive] [Prices Excl. VAT] [Quote]
        // [SCENARIO 208301] Report 215 "Archived Sales Quote" correctly prints total vat base/amount in case of "Prices Including VAT" = FALSE and two lines with different VAT setup
        Initialize();
        UpdateSalesLogoPositionSetup();

        // [GIVEN] Sales quote with "Prices Including VAT" = FALSE, two lines with different VAT Setup
        CreateSalesQuoteWithTwoVATSetupLines(VATPostingSetup, SalesHeader, TotalBaseAmount, TotalVATAmount, false);
        // [GIVEN] Archive sales quote
        ArchiveSalesDocument(SalesHeader);

        // [WHEN] Print archived sales quote (REP 215 "Archived Sales Quote")
        RunArchivedSalesQuoteReport(SalesHeader);

        // [THEN] Report correctly prints total VAT Amount and Total Amount Incl. VAT
        VerifyArchiveDocExcelTotalVATBaseAmount('AK', 47, TotalVATAmount, TotalBaseAmount + TotalVATAmount);

        // Tear Down
        VATPostingSetup[1].Delete(true);
        VATPostingSetup[2].Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ArchivedSalesOrderReportWithoutPricesInclVATAndTwoLines()
    var
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        TotalBaseAmount: Decimal;
        TotalVATAmount: Decimal;
    begin
        // [FEATURE] [Report] [Archive] [Prices Excl. VAT] [Order]
        // [SCENARIO 208301] Report 216 "Archived Sales Order" correctly prints total vat base/amount in case of "Prices Including VAT" = FALSE and two lines with different VAT Setup
        Initialize();
        UpdateSalesLogoPositionSetup();

        // [GIVEN] Sales order with "Prices Including VAT" = FALSE, two lines with different VAT Setup
        CreateSalesOrderWithTwoVATSetupLines(VATPostingSetup, SalesHeader, TotalBaseAmount, TotalVATAmount, false);
        // [GIVEN] Archive sales order
        ArchiveSalesDocument(SalesHeader);

        // [WHEN] Print archived sales order (REP 216 "Archived Sales Order")
        RunArchivedSalesOrderReportAsXml(SalesHeader);
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Report correctly prints total VAT Amount and Total VAT Base Amount
        LibraryReportDataset.SearchForElementByValue('//Column[@name=''VATAmount'']', TotalVATAmount);
        LibraryReportDataset.SearchForElementByValue('//Column[@name=''VATBaseAmount'']', TotalBaseAmount);

        // Tear Down
        VATPostingSetup[1].Delete(true);
        VATPostingSetup[2].Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ArchivedSalesQuoteReportInCaseOfInvoiceDiscountAmount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InvDiscountAmount: Decimal;
    begin
        // [FEATURE] [Report] [Archive] [Invoice Discount] [Quote]
        // [SCENARIO 201417] Report 215 "Archived Sales Quote" correctly prints totals in case of Invoice Discount
        Initialize();
        UpdateSalesLogoPositionSetup();

        // [GIVEN] Sales Quote with "Line Amount" = 1000, "Invoice Discount Amount" = 200, "VAT %" = 25
        CreateSalesDocWithItemAndVATSetup(SalesHeader, SalesLine, SalesHeader."Document Type"::Quote);
        InvDiscountAmount := Round(SalesLine.Amount / 3);
        ApplyInvDiscBasedOnAmt(SalesHeader, InvDiscountAmount);
        // [GIVEN] Archive the sales quote
        ArchiveSalesDocument(SalesHeader);

        // [WHEN] Print archived sales quote (REP 215 "Archived Sales Quote")
        RunArchivedSalesQuoteReport(SalesHeader);

        // [THEN] Subtotal Amount = 1000, Invoice Discount Amount = -200, Total Excl. VAT = 800, VAT Amount = 200, Total Incl. VAT = 1000
        SalesLine.Find();
        VerifyArchiveDocExcelTotalsWithDiscount(
          'AK', 45, SalesLine."Line Amount", InvDiscountAmount, SalesLine."VAT Base Amount",
          SalesLine."Amount Including VAT" - SalesLine.Amount, SalesLine."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ArchivedSalesOrderReportInCaseOfInvoiceDiscountAmount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InvDiscountAmount: Decimal;
    begin
        // [FEATURE] [Report] [Archive] [Invoice Discount] [Order]
        // [SCENARIO 201417] Report 216 "Archived Sales Order" correctly prints totals in case of Invoice Discount
        Initialize();
        UpdateSalesLogoPositionSetup();

        // [GIVEN] Sales Order with "Line Amount" = 1000, "Invoice Discount Amount" = 200, "VAT %" = 25
        CreateSalesDocWithItemAndVATSetup(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);
        InvDiscountAmount := Round(SalesLine.Amount / 3);
        ApplyInvDiscBasedOnAmt(SalesHeader, InvDiscountAmount);
        // [GIVEN] Archive the sales order
        ArchiveSalesDocument(SalesHeader);

        // [WHEN] Print archived sales order (REP 216 "Archived Sales Order")
        RunArchivedSalesOrderReportAsXml(SalesHeader);

        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Report correctly prints total VAT Amount and Total VAT Base Amount
        SalesLine.Find();
        LibraryReportDataset.SearchForElementByValue('//Column[@name=''VATAmount'']', SalesLine."Amount Including VAT" - SalesLine.Amount);
        LibraryReportDataset.SearchForElementByValue('//Column[@name=''VATBaseAmount'']', SalesLine."VAT Base Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ArchivedSalesReturnOrderReportInCaseOfInvoiceDiscountAmount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InvDiscountAmount: Decimal;
    begin
        // [FEATURE] [Report] [Archive] [Invoice Discount] [Return Order]
        // [SCENARIO 201417] Report 418 "Arch. Sales Return Order" correctly prints totals in case of Invoice Discount
        Initialize();
        UpdateSalesLogoPositionSetup();

        // [GIVEN] Sales Return Order with "Line Amount" = 1000, "Invoice Discount Amount" = 200, "VAT %" = 25
        CreateSalesDocWithItemAndVATSetup(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order");
        InvDiscountAmount := Round(SalesLine.Amount / 3);
        ApplyInvDiscBasedOnAmt(SalesHeader, InvDiscountAmount);
        // [GIVEN] Archive the sales return order
        ArchiveSalesDocument(SalesHeader);

        // [WHEN] Print archived sales return order (REP 418 "Arch. Sales Return Order")
        RunArchivedSalesReturnOrderReport(SalesHeader);

        // [THEN] Subtotal Amount = 1000, Invoice Discount Amount = -200, Total Excl. VAT = 800, VAT Amount = 200, Total Incl. VAT = 1000
        SalesLine.Find();
        VerifyArchiveRetOrderExcelTotalsWithDiscount(
          'AT', 50, SalesLine."Line Amount", InvDiscountAmount, SalesLine."VAT Base Amount",
          SalesLine."Amount Including VAT" - SalesLine.Amount, SalesLine."Amount Including VAT");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UT_RenameStandardTextExistsInSalesOrder()
    var
        SalesLine: Record "Sales Line";
        StandardText: Record "Standard Text";
        DummyText: Text;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 203481] Sales Line with Standard Text updates when Standard Text is renamed

        Initialize();

        LibrarySales.CreateStandardTextWithExtendedText(StandardText, DummyText);
        SalesLine.Init();
        SalesLine.Type := SalesLine.Type::" ";
        SalesLine."No." := StandardText.Code;
        SalesLine.Insert();

        StandardText.Rename(LibraryUtility.GenerateGUID());

        SalesLine.Find();
        SalesLine.TestField("No.", StandardText.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckBillToWhenCreateNewSalesInvoiceFromCustomerCard()
    var
        Customer: Record Customer;
        CustomerBillTo: Record Customer;
        CustomerCard: TestPage "Customer Card";
        SalesInvoice: TestPage "Sales Invoice";
        BillToOptions: Option "Default (Customer)","Another Customer";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 207765] Bill-to option is updated when new Sales Invoice is created with DocNoVisible = false
        Initialize();

        // [GIVEN] No Series for Sales Invoice generates DocNoVisible = false
        UpdateNoSeriesOnSalesSetup(false);

        // [GIVEN] Customer "C" where Bill-to Customer "B" has Name "N"
        CreateCustomerWithBillToCustomer(Customer, CustomerBillTo);

        // [GIVEN] Open Customer Card for customer "C"
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);

        // [WHEN] Perform page action: New Sales Document -> Sales Invoice
        SalesInvoice.Trap();
        CustomerCard.NewSalesInvoice.Invoke();

        // [THEN] Sales Invoice is not inserted into database yet
        VerifySalesDocumentDoesNotExist(Customer."No.");
        // [THEN] Sales Invoice card is initialized with "Bill-to" = "Another Customer", "Bill-to Name" = "N"
        SalesInvoice.BillToOptions.AssertEquals(BillToOptions::"Another Customer");
        SalesInvoice."Bill-to Name".AssertEquals(CustomerBillTo.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckBillToWhenCreateNewSalesOrderFromCustomerCard()
    var
        Customer: Record Customer;
        CustomerBillTo: Record Customer;
        CustomerCard: TestPage "Customer Card";
        SalesOrder: TestPage "Sales Order";
        BillToOptions: Option "Default (Customer)","Another Customer";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 207765] Bill-to option is updated when new Sales Order is created with DocNoVisible = false
        Initialize();

        // [GIVEN] No Series for Sales Order generates DocNoVisible = false
        UpdateNoSeriesOnSalesSetup(false);

        // [GIVEN] Customer "C" where Bill-to Customer "B" has Name "N"
        CreateCustomerWithBillToCustomer(Customer, CustomerBillTo);

        // [GIVEN] Open Customer Card for customer "C"
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);

        // [WHEN] Perform page action: New Sales Document -> Sales Order
        SalesOrder.Trap();
        CustomerCard.NewSalesOrder.Invoke();

        // [THEN] Sales Order is not inserted into database yet
        VerifySalesDocumentDoesNotExist(Customer."No.");
        // [THEN] Sales Order card shows "Bill-to" = "Another Customer", "Bill-to Name" = "N"
        SalesOrder.BillToOptions.AssertEquals(BillToOptions::"Another Customer");
        SalesOrder."Bill-to Name".AssertEquals(CustomerBillTo.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckBillToWhenCreateNewSalesQuoteFromCustomerCard()
    var
        Customer: Record Customer;
        CustomerBillTo: Record Customer;
        CustomerCard: TestPage "Customer Card";
        SalesQuote: TestPage "Sales Quote";
        BillToOptions: Option "Default (Customer)","Another Customer";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 207765] Bill-to option is updated when new Sales Quote is created with DocNoVisible = false
        Initialize();

        // [GIVEN] No Series for Sales Quote generates DocNoVisible = false
        UpdateNoSeriesOnSalesSetup(false);

        // [GIVEN] Customer "C" where Bill-to Customer "B" has Name "N"
        CreateCustomerWithBillToCustomer(Customer, CustomerBillTo);

        // [GIVEN] Open Customer Card for customer "C"
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);

        // [WHEN] Perform page action: New Sales Document -> Sales Quote
        SalesQuote.Trap();
        CustomerCard.NewSalesQuote.Invoke();

        // [THEN] Sales Quote is not inserted into database yet
        VerifySalesDocumentDoesNotExist(Customer."No.");
        // [THEN] Sales Quote card is initialized with "Bill-to" = "Another Customer", "Bill-to Name" = "N"
        SalesQuote.BillToOptions.AssertEquals(BillToOptions::"Another Customer");
        SalesQuote."Bill-to Name".AssertEquals(CustomerBillTo.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckBillToWhenCreateNewBlanketOrderFromCustomerCard()
    var
        Customer: Record Customer;
        CustomerBillTo: Record Customer;
        CustomerCard: TestPage "Customer Card";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        BillToOptions: Option "Default (Customer)","Another Customer";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 207765] Bill-to option is updated when new Blanket Sales Order is created with DocNoVisible = false
        Initialize();

        // [GIVEN] No Series for Blanket Sales Order generates DocNoVisible = false
        UpdateNoSeriesOnSalesSetup(false);

        // [GIVEN] Customer "C" where Bill-to Customer "B" has Name "N"
        CreateCustomerWithBillToCustomer(Customer, CustomerBillTo);

        // [GIVEN] Open Customer Card for customer "C"
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);

        // [WHEN] Perform page action: New Sales Document -> Blanket Sales Order
        BlanketSalesOrder.Trap();
        CustomerCard.NewBlanketSalesOrder.Invoke();

        // [THEN] Sales Blanket Order is not inserted into database yet
        VerifySalesDocumentDoesNotExist(Customer."No.");
        // [THEN] Sales Blanket Order card is initialized with "Bill-to" = "Another Customer", "Bill-to Name" = "N"
        BlanketSalesOrder.BillToOptions.AssertEquals(BillToOptions::"Another Customer");
        BlanketSalesOrder."Bill-to Name".AssertEquals(CustomerBillTo.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckBillToWhenCreateNewSalesInvoiceWhenDocNoVisible()
    var
        Customer: Record Customer;
        CustomerBillTo: Record Customer;
        CustomerList: TestPage "Customer List";
        SalesInvoice: TestPage "Sales Invoice";
        BillToOptions: Option "Default (Customer)","Another Customer";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 207765] Bill-to option is updated when new Sales Invoice is created with DocNoVisible = true
        // Covers TFS ID 382214
        Initialize();

        // [GIVEN] No Series for Sales Invoice generates DocNoVisible = true
        UpdateNoSeriesOnSalesSetup(true);

        // [GIVEN] Customer "C" where Bill-to Customer "B" has Name "N"
        CreateCustomerWithBillToCustomer(Customer, CustomerBillTo);

        // [GIVEN] Open Customer List for customer "C"
        CustomerList.OpenEdit();
        CustomerList.GotoRecord(Customer);

        // [GIVEN] Perform page action: New Sales Document -> Sales Invoice
        SalesInvoice.Trap();
        CustomerList.NewSalesInvoice.Invoke();
        SalesInvoice."Sell-to Customer Name".AssertEquals(''); // no values are initialized on the page
        VerifySalesDocumentDoesNotExist(Customer."No.");

        // [WHEN] Activate "Sell-to Customer Name" field (runs OnInsert trigger on the page)
        SalesInvoice."Sell-to Customer Name".Activate();

        // [THEN] Sales Invoice is inserted into database
        VerifySalesDocumentExists(Customer."No.");
        // [THEN] Sales Invoice card is initialized with "Bill-to" = "Another Customer", "Bill-to Name" = "N"
        SalesInvoice.BillToOptions.AssertEquals(BillToOptions::"Another Customer");
        SalesInvoice."Bill-to Name".AssertEquals(CustomerBillTo.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckBillToWhenCreateNewSalesOrderWhenDocNoVisible()
    var
        Customer: Record Customer;
        CustomerBillTo: Record Customer;
        CustomerList: TestPage "Customer List";
        SalesOrder: TestPage "Sales Order";
        BillToOptions: Option "Default (Customer)","Another Customer";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 207765] Bill-to option is updated when new Sales Order is created with DocNoVisible = true
        // Covers TFS ID 382214
        Initialize();

        // [GIVEN] No Series for Sales Order generates DocNoVisible = true
        UpdateNoSeriesOnSalesSetup(true);

        // [GIVEN] Customer "C" where Bill-to Customer "B" has Name "N"
        CreateCustomerWithBillToCustomer(Customer, CustomerBillTo);

        // [GIVEN] Open Customer List for customer "C"
        CustomerList.OpenEdit();
        CustomerList.GotoRecord(Customer);

        // [GIVEN] Perform page action: New Sales Document -> Sales Order
        SalesOrder.Trap();
        CustomerList.NewSalesOrder.Invoke();
        SalesOrder."Sell-to Customer Name".AssertEquals(''); // no values are initialized on the page
        VerifySalesDocumentDoesNotExist(Customer."No.");

        // [WHEN] Activate "Sell-to Customer Name" field (runs OnInsert trigger on the page)
        SalesOrder."Sell-to Customer Name".Activate();

        // [THEN] Sales Order is inserted into database
        VerifySalesDocumentExists(Customer."No.");
        // [THEN] Sales Order card shows "Bill-to" = "Another Customer", "Bill-to Name" = "N"
        SalesOrder.BillToOptions.AssertEquals(BillToOptions::"Another Customer");
        SalesOrder."Bill-to Name".AssertEquals(CustomerBillTo.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckBillToWhenCreateNewSalesQuoteWhenDocNoVisible()
    var
        Customer: Record Customer;
        CustomerBillTo: Record Customer;
        CustomerList: TestPage "Customer List";
        SalesQuote: TestPage "Sales Quote";
        BillToOptions: Option "Default (Customer)","Another Customer";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 207765] Bill-to option is updated when new Sales Quote is created with DocNoVisible = true
        // Covers TFS ID 382214
        Initialize();

        // [GIVEN] No Series for Sales Quote generates DocNoVisible = true
        UpdateNoSeriesOnSalesSetup(true);

        // [GIVEN] Customer "C" where Bill-to Customer "B" has Name "N"
        CreateCustomerWithBillToCustomer(Customer, CustomerBillTo);

        // [GIVEN] Open Customer List for customer "C"
        CustomerList.OpenEdit();
        CustomerList.GotoRecord(Customer);

        // [GIVEN] Perform page action: New Sales Document -> Sales Quote
        SalesQuote.Trap();
        CustomerList.NewSalesQuote.Invoke();
        SalesQuote."Sell-to Customer Name".AssertEquals(''); // no values are initialized on the page
        VerifySalesDocumentDoesNotExist(Customer."No.");

        // [WHEN] Activate "Sell-to Customer Name" field (runs OnInsert trigger on the page)
        SalesQuote."Sell-to Customer Name".Activate();

        // [THEN] Sales Quote is inserted into database
        VerifySalesDocumentExists(Customer."No.");
        // [THEN] Sales Quote card is initialized with "Bill-to" = "Another Customer", "Bill-to Name" = "N"
        SalesQuote.BillToOptions.AssertEquals(BillToOptions::"Another Customer");
        SalesQuote."Bill-to Name".AssertEquals(CustomerBillTo.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckBillToWhenCreateNewBlanketOrderWhenDocNoVisible()
    var
        Customer: Record Customer;
        CustomerBillTo: Record Customer;
        CustomerList: TestPage "Customer List";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        BillToOptions: Option "Default (Customer)","Another Customer";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 207765] Bill-to option is updated when new Blanket Sales Order is created with DocNoVisible = true
        // Covers TFS ID 382214
        Initialize();

        // [GIVEN] No Series for Blanket Sales Order generates DocNoVisible = true
        UpdateNoSeriesOnSalesSetup(true);

        // [GIVEN] Customer "C" where Bill-to Customer "B" has Name "N"
        CreateCustomerWithBillToCustomer(Customer, CustomerBillTo);

        // [GIVEN] Open Customer List for customer "C"
        CustomerList.OpenEdit();
        CustomerList.GotoRecord(Customer);

        // [GIVEN] Perform page action: New Sales Document -> Blanket Sales Order
        BlanketSalesOrder.Trap();
        CustomerList.NewSalesBlanketOrder.Invoke();
        BlanketSalesOrder."Sell-to Customer Name".AssertEquals(''); // no values are initialized on the page
        VerifySalesDocumentDoesNotExist(Customer."No.");

        // [WHEN] Activate "Sell-to Customer Name" field (runs OnInsert trigger on the page)
        BlanketSalesOrder."Sell-to Customer Name".Activate();

        // [THEN] Blanket Sales Order is inserted into database
        VerifySalesDocumentExists(Customer."No.");
        // [THEN] Sales Blanket Order card is initialized with "Bill-to" = "Another Customer", "Bill-to Name" = "N"
        BlanketSalesOrder.BillToOptions.AssertEquals(BillToOptions::"Another Customer");
        BlanketSalesOrder."Bill-to Name".AssertEquals(CustomerBillTo.Name);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckBillToCustomerWhenReenteringSameSellTo()
    var
        Customer: Record Customer;
        CustomerBillTo: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 542320] Bill-to customer should stay the same when re-entering the same Sell-to customer
        Initialize();

        // [GIVEN] Customer "C" where Bill-to Customer "B" has Name "N"
        CreateCustomerWithBillToCustomer(Customer, CustomerBillTo);

        // [GIVEN] Create Ship-to Address for Customer "C" and assigne as default "Ship-to Address"
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        if ShipToAddress."Shipment Method Code" = '' then begin
            ShipToAddress.Validate("Shipment Method Code", CreateShipmentMethod());
            ShipToAddress.Modify(true);
        end;

        // [GIVEN] Set "C_SA" as default "Ship-to Address" for Customer "C".
        Customer.Validate("Ship-to Code", ShipToAddress.Code);
        Customer.Modify(true);

        // [GIVEN] Create Sales Order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.TestField("Bill-to Customer No.", CustomerBillTo."No.");
        SalesHeader.TestField("Ship-to Code", ShipToAddress.Code);

        // [WHEN] reenter the same Sell-to customer
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");

        // [THEN] Bill-to customer should stay the same
        SalesHeader.TestField("Bill-to Customer No.", CustomerBillTo."No.");
        SalesHeader.TestField("Ship-to Code", ShipToAddress.Code);
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

    [Test]
    [Scope('OnPrem')]
    procedure OnlyPostingGLAcctMayBeUsedAsFreightGLAccInSalRecSetupUT()
    var
        GLAccount: Record "G/L Account";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [Sales Receivables Setup] [Freight G/L Acc. No.] [UT]
        // [SCENARIO 212367] Only posting G/L Account may be used as Freight G/L Acc. in Sales Receivables Setup
        Initialize();

        // [GIVEN] G/L Account "GGG" of non-posting type
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount."Account Type" := GLAccount."Account Type"::"Begin-Total";
        GLAccount.Modify();

        // [WHEN] Set "GGG" as Freight G/L Acc. in Sales Receivables Setup
        SalesReceivablesSetup.Get();
        asserterror SalesReceivablesSetup.Validate("Freight G/L Acc. No.", GLAccount."No.");

        // [THEN] "Account Type must be equal to 'Posting'" error appears
        Assert.ExpectedTestFieldError(GLAccount.FieldCaption("Account Type"), Format(GLAccount."Account Type"::Posting));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OnlyNotBlockedGLAcctMayBeUsedAsFreightGLAccInSalRecSetupUT()
    var
        GLAccount: Record "G/L Account";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [Sales Receivables Setup] [Freight G/L Acc. No.] [UT]
        // [SCENARIO 212367] Only not blocked posting G/L Account may be used as Freight G/L Acc. in Sales Receivables Setup
        Initialize();

        // [GIVEN] Blocked G/L Account "GGG" of posting type
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount."Account Type" := GLAccount."Account Type"::Posting;
        GLAccount.Blocked := true;
        GLAccount.Modify();

        // [WHEN] Set "GGG" as Freight G/L Acc. in Sales Receivables Setup
        SalesReceivablesSetup.Get();
        asserterror SalesReceivablesSetup.Validate("Freight G/L Acc. No.", GLAccount."No.");

        // [THEN] "Blocked must be equal to 'No'" error appears
        Assert.ExpectedTestFieldError(GLAccount.FieldCaption(Blocked), Format(false));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_CannotCopyPricesWhenSalesTypeFilterNotCustomer()
    var
        SalesPrices: TestPage "Sales Prices";
    begin
        // [FEAUTURE] [UI] [Price] [Sales Price]
        // [SCENARIO 207389] Not possible to copy prices when "Sales Type Filter" is not Customer on "Sales Prices" page

        Initialize();

        // [GIVEN] Opened "Sales Prices" page and "Sales Type Filter" is "All Customers"
        SalesPrices.OpenEdit();
        SalesPrices.SalesTypeFilter.SetValue('All Customers');

        // [WHEN] Press action "Copy Prices" on "Sales Prices" page
        asserterror SalesPrices.CopyPrices.Invoke();

        // [THEN] Error message "Incorrect Sales Type Filter specified. Specify Customer in Sales Type Filter field and Customer No. in Sales Code Filter to copy prices." is thrown
        Assert.ExpectedError(IncorrectSalesTypeToCopyPricesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_CannotCopyPricesWhenSalesCodeFilterHasMultipleVendors()
    var
        SalesPrices: TestPage "Sales Prices";
        CopyFromCustomerNo: Code[20];
        CopyToCustomerNo: Code[20];
    begin
        // [FEAUTURE] [UI] [Price] [Sales Price]
        // [SCENARIO 207389] Not possible to copy prices when multiple customers specified in "Sales Code Filter" on "Sa;es Prices" page

        Initialize();

        // [GIVEN] Customers "X" and "Y"
        CopyFromCustomerNo := LibrarySales.CreateCustomerNo();
        CopyToCustomerNo := LibrarySales.CreateCustomerNo();

        // [GIVEN] Opened "Sales Prices" page. "Sales Type Filter" is "Customer", "Sales Code Filter" is "X|Y"
        SalesPrices.OpenEdit();
        SalesPrices.SalesTypeFilter.SetValue('Customer');
        SalesPrices.SalesCodeFilterCtrl.SetValue(StrSubstNo('%1|%2', CopyFromCustomerNo, CopyToCustomerNo));

        // [WHEN] Press action "Copy Prices" on "Sales Prices" page
        asserterror SalesPrices.CopyPrices.Invoke();

        // [THEN] Error message "There are more than one customer selected by Sales Code Filter. Specify a single Customer No. by Sales Code Filter to copy prices." is thrown
        Assert.ExpectedError(MultipleCustomersSelectedErr);
    end;

    [Test]
    [HandlerFunctions('SalesPricesSelectPriceOfCustomerModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_CopyPriceOnSalesPricesPage()
    var
        SalesPrice: Record "Sales Price";
        SalesPrices: TestPage "Sales Prices";
        CopyToCustomerNo: Code[20];
    begin
        // [FEAUTURE] [UI] [Price] [Sales Price]
        // [SCENARIO 207389] Copy price from one Customer to another by "Copy Prices" action on "Sa;es Prices" page

        Initialize();

        // [GIVEN] Customers "X" and "Y"
        // [GIVEN] Sales Price for Vendor "Y", "Unit Price" = 50
        // [GIVEN] Opened "Sales Prices" page. "Sales Type Filter" is "Customer", "Sales Code Filter" is "X"
        CopyPricesScenarioOnSalesPricePage(SalesPrice, CopyToCustomerNo, SalesPrices);

        // [WHEN] Press action "Copy Prices" on "Sales Prices" page and select price of Customer "Y"
        SalesPrices.CopyPrices.Invoke();

        // [THEN] Sales Price for Customer "X" with "Direct Unit Cost" = 50 is created
        VerifyCopiedSalesPrice(SalesPrice, CopyToCustomerNo);
    end;

    [Test]
    [HandlerFunctions('SalesPricesSelectPriceOfCustomerModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_CopyExistingPriceOnSalesPricesPage()
    var
        SalesPrice: Record "Sales Price";
        SalesPrices: TestPage "Sales Prices";
        CopyFromCustomerNo: Code[20];
        CopyToCustomerNo: Code[20];
    begin
        // [FEAUTURE] [UI] [Price] [Sales Price]
        // [SCENARIO 207389] Price not copies if it's already exist when use "Copy Prices" action on "Sales Prices" page

        Initialize();

        // [GIVEN] Customers "X" and "Y"
        CopyToCustomerNo := LibrarySales.CreateCustomerNo();
        CopyFromCustomerNo := LibrarySales.CreateCustomerNo();

        // [GIVEN] Two identical Sales Prices for Vendors "X" and "Y"
        CreateSalesPriceWithUnitPrice(
          SalesPrice, CopyFromCustomerNo, LibraryInventory.CreateItemNo(), 0, LibraryRandom.RandDec(100, 2));
        SalesPrice."Sales Code" := CopyToCustomerNo;
        SalesPrice.Insert();

        // [GIVEN] Opened "Sales Prices" page. "Sales Type Filter" is "Customer", "Sales Code Filter" is "X"
        SalesPrices.OpenEdit();
        SalesPrices.SalesTypeFilter.SetValue('Customer');
        SalesPrices.SalesCodeFilterCtrl.SetValue(CopyToCustomerNo);
        LibraryVariableStorage.Enqueue(CopyFromCustomerNo); // pass to SalesPricesSelectPriceOfCustomerModalPageHandler

        // [WHEN] Press action "Copy Prices" on "Sales Prices" page and select price of Customer "Y"
        SalesPrices.CopyPrices.Invoke();

        // [THEN] Existing Price not changed and no new Price was copied to Customer "X"
        VerifyUnchangedSalesPrice(SalesPrice);
    end;

    [Test]
    [HandlerFunctions('SalesPricesCancelPriceSelectionModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_DoNotSelectPriceWhenCopyPricesOnSalesPricesPage()
    var
        SalesPrice: Record "Sales Price";
        SalesPrices: TestPage "Sales Prices";
        CopyToCustomerNo: Code[20];
    begin
        // [FEAUTURE] [UI] [Price] [Sales Price]
        // [SCENARIO 207389] Price not copies if nothing is selected when use "Copy Prices" action on "Sales Prices" page

        Initialize();

        // [GIVEN] Customers "X" and "Y"
        // [GIVEN] Sales Price for Vendor "Y", "Unit Price" = 50
        // [GIVEN] Opened "Sales Prices" page. "Sales Type Filter" is "Customer", "Sales Code Filter" is "X"
        CopyPricesScenarioOnSalesPricePage(SalesPrice, CopyToCustomerNo, SalesPrices);

        // [WHEN] Press action "Copy Prices" on "Sales Prices" page and cancel selection
        SalesPrices.CopyPrices.Invoke();

        // [THEN] No price was copied to Customer "X"
        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::Customer);
        SalesPrice.SetRange("Sales Code", CopyToCustomerNo);
        Assert.RecordCount(SalesPrice, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_CopySalesPriceToCustomersSalesPrice()
    var
        SalesPrice: Record "Sales Price";
        ExistingSalesPrice: Record "Sales Price";
        CopyFromCustomerNo: Code[20];
        CopyToCustomerNo: Code[20];
    begin
        // [FEATURE] [UT] [Price] [Sales Price]
        // [SCENARIO 207389] Copy prices with CopySalesPriceToCustomersSalesPrice function in Sales Price table

        Initialize();

        CopyToCustomerNo := LibrarySales.CreateCustomerNo();
        CopyFromCustomerNo := LibrarySales.CreateCustomerNo();
        CreateSalesPriceWithUnitPrice(
          SalesPrice, CopyFromCustomerNo, LibraryInventory.CreateItemNo(), 0, LibraryRandom.RandDec(100, 2));

        CreateSalesPriceWithUnitPrice(
          SalesPrice, CopyFromCustomerNo, LibraryInventory.CreateItemNo(), 0, LibraryRandom.RandDec(100, 2));
        ExistingSalesPrice := SalesPrice;
        ExistingSalesPrice."Sales Code" := CopyToCustomerNo;
        ExistingSalesPrice.Insert();

        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::Customer);
        SalesPrice.SetRange("Sales Code", CopyFromCustomerNo);
        SalesPrice.CopySalesPriceToCustomersSalesPrice(SalesPrice, CopyToCustomerNo);

        SalesPrice.SetRange("Sales Code", CopyToCustomerNo);
        Assert.RecordCount(SalesPrice, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckShipToWhenCreateSecondSalesInvoiceFromCustomerCard()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustomerCard: TestPage "Customer Card";
        SalesInvoice: TestPage "Sales Invoice";
        ShipToOptions: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 216144] Ship-to option is 'Default' when second Sales Invoice is created with DocNoVisible = false
        Initialize();

        // [GIVEN] No Series for Sales Invoice generates DocNoVisible = false
        UpdateNoSeriesOnSalesSetup(false);

        // [GIVEN] Sales Invoice is created for Customer "C" where Ship-to option is updated with "X"
        CreateCustomerWithAddress(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesInvoice.OpenView();
        SalesInvoice.GotoRecord(SalesHeader);
        ShipToOptions := SalesInvoice.ShippingOptions.AsInteger();

        // [GIVEN] Open Customer Card for customer "C"
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);

        // [WHEN] Perform page action: New Sales Document -> Sales Invoice
        SalesInvoice.Trap();
        CustomerCard.NewSalesInvoice.Invoke();

        // [THEN] Sales Invoice card is initialized with "Ship-to" = "X"
        SalesInvoice.ShippingOptions.AssertEquals(ShipToOptions);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckShipToWhenCreateSecondSalesOrderFromCustomerCard()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustomerCard: TestPage "Customer Card";
        SalesOrder: TestPage "Sales Order";
        ShipToOptions: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 216144] Ship-to option is 'Default' when second Sales Order is created with DocNoVisible = false
        Initialize();

        // [GIVEN] No Series for Sales Order generates DocNoVisible = false
        UpdateNoSeriesOnSalesSetup(false);

        // [GIVEN] Sales Order is created for Customer "C" where Ship-to option is updated with "X"
        CreateCustomerWithAddress(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);
        ShipToOptions := SalesOrder.ShippingOptions.AsInteger();

        // [GIVEN] Open Customer Card for customer "C"
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);

        // [WHEN] Perform page action: New Sales Document -> Sales Order
        SalesOrder.Trap();
        CustomerCard.NewSalesOrder.Invoke();

        // [THEN] Sales Order card shows "Ship-to" = "X"
        SalesOrder.ShippingOptions.AssertEquals(ShipToOptions);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckShipToWhenCreateSecondSalesQuoteFromCustomerCard()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustomerCard: TestPage "Customer Card";
        SalesQuote: TestPage "Sales Quote";
        ShipToOptions: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 216144] Ship-to option is 'Default' when second Sales Quote is created with DocNoVisible = false
        Initialize();

        // [GIVEN] No Series for Sales Quote generates DocNoVisible = false
        UpdateNoSeriesOnSalesSetup(false);

        // [GIVEN] Sales Quote is created for Customer "C" where Ship-to option is updated with "X"
        CreateCustomerWithAddress(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, Customer."No.");
        SalesQuote.OpenView();
        SalesQuote.GotoRecord(SalesHeader);
        ShipToOptions := SalesQuote.ShippingOptions.AsInteger();

        // [GIVEN] Open Customer Card for customer "C"
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);

        // [WHEN] Perform page action: New Sales Document -> Sales Quote
        SalesQuote.Trap();
        CustomerCard.NewSalesQuote.Invoke();

        // [THEN] Sales Quote card is initialized with "Ship-to" = "X"
        SalesQuote.ShippingOptions.AssertEquals(ShipToOptions);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckShipToWhenCreateSecondBlanketOrderFromCustomerCard()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustomerCard: TestPage "Customer Card";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        ShipToOptions: Integer;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 216144] Ship-to option is 'Default' when second Blanket Sales Order is created with DocNoVisible = false
        Initialize();

        // [GIVEN] No Series for Blanket Sales Order generates DocNoVisible = false
        UpdateNoSeriesOnSalesSetup(false);

        // [GIVEN] Sales Blamket Order is created for Customer "C" where Ship-to option is updated with "X"
        CreateCustomerWithAddress(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", Customer."No.");
        BlanketSalesOrder.OpenView();
        BlanketSalesOrder.GotoRecord(SalesHeader);
        ShipToOptions := BlanketSalesOrder.ShippingOptions.AsInteger();

        // [GIVEN] Open Customer Card for customer "C"
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);

        // [WHEN] Perform page action: New Sales Document -> Blanket Sales Order
        BlanketSalesOrder.Trap();
        CustomerCard.NewBlanketSalesOrder.Invoke();

        // [THEN] Sales Blanket Order card is initialized with "Ship-to" = "X"
        BlanketSalesOrder.ShippingOptions.AssertEquals(ShipToOptions);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FreightGLAccCanOnlyBeFilledWithExistingGLAcc()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        GLAccNo: Code[20];
    begin
        // [FEATURE] [Sales Receivables Setup] [Freight G/L Acc. No.] [UT]
        // [SCENARIO 213392] Only existing G/L Account can be used as "Freight G/L Acc." in Sales Receivables Setup

        Initialize();
        GLAccNo := LibraryUtility.GenerateGUID();
        SalesReceivablesSetup.Get();
        asserterror SalesReceivablesSetup.Validate("Freight G/L Acc. No.", GLAccNo);
        Assert.ExpectedError(
            StrSubstNo(NotExistingFreightGLAccNoErr, SalesReceivablesSetup.FieldCaption("Freight G/L Acc. No."), GLAccNo));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FreightGLAccCanBeBlank()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [Sales Receivables Setup] [Freight G/L Acc. No.] [UT]
        // [SCENARIO 213392] "Freight G/L Acc." can be validated blank in Sales Receivables Setup

        Initialize();
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Freight G/L Acc. No.", '');
        SalesReceivablesSetup.TestField("Freight G/L Acc. No.", '');
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,AmountsOnCrLimitNotificationDetailsModalPageHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure OrderOutstandingAmountOnCreditLimitDetails()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustCheckCrLimit: Codeunit "Cust-Check Cr. Limit";
    begin
        // [FEATURE] [Credit Limit]
        // [SCENARIO 217740] "Outstanding Amount" of Sales Order is correct on "Credit Limit Details" page

        // [GIVEN] Customer with "Credit Limit" = 100
        // [GIVEN] Sales Order with Customer and "Amount Including VAT" = 350
        Initialize();
        CreateSalesDocWithCrLimitCustomer(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);

        // [WHEN] Check Credit Limit on Sales Order
        CustCheckCrLimit.SalesHeaderCheck(SalesHeader);

        // [THEN] "Credit Limit Notification" shown and subpage "Credit Limit Details" has "Outstanding Amount" and "Total Amount" equal 350
        // Amounts enqueued in AmountsOnCrLimitNotificationDetailsModalPageHandler
        VerifyAmountInclVATOfCreditLimitDetails(SalesLine."Amount Including VAT");

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,AmountsOnCrLimitNotificationDetailsModalPageHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure InvOutstandingAmountOnCreditLimitDetails()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustCheckCrLimit: Codeunit "Cust-Check Cr. Limit";
    begin
        // [FEATURE] [Credit Limit]
        // [SCENARIO 217740] "Outstanding Amount" of Sales Invoice is correct on "Credit Limit Details" page

        // [GIVEN] Customer with "Credit Limit" = 100
        // [GIVEN] Sales Invoice with Customer and "Amount Including VAT" = 350
        Initialize();
        CreateSalesDocWithCrLimitCustomer(SalesHeader, SalesLine, SalesHeader."Document Type"::Order);

        // [WHEN] Check Credit Limit on Sales Invoice
        CustCheckCrLimit.SalesHeaderCheck(SalesHeader);

        // [THEN] "Credit Limit Notification" shown and subpage "Credit Limit Details" has "Outstanding Amount" and "Total Amount" equal 350
        // Amounts enqueued in AmountsOnCrLimitNotificationDetailsModalPageHandler
        VerifyAmountInclVATOfCreditLimitDetails(SalesLine."Amount Including VAT");

        LibraryNotificationMgt.RecallNotificationsForRecord(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,CheckCrLimitGetOverdueAmountModalPageHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure BalanceDueLCYConsidersOnlyEntriesWithDueDateLessThanTodayOnCheckCrLimitPage()
    var
        SalesHeader: Record "Sales Header";
        CustCheckCrLimit: Codeunit "Cust-Check Cr. Limit";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        OverdueAmount: Decimal;
    begin
        // [FEAUTURE] [UI] [UT]
        // [SCENARIO 384838] "Balance Due (LCY)" considers only Customer Ledger Entries with "Due Date" less than today on "Check Credit Limit" page

        Initialize();

        // [GIVEN] Today date is 24.01.19
        // [GIVEN] Customer with two entries
        // [GIVEN] First entry has "Due Date" = 25.01.19 and Amount = 100
        // [GIVEN] Second entry has "Due Date" = 24.01.19 and Amount = 50
        CreateSalesOrderWithOverdueCust(SalesHeader, OverdueAmount, Today, Today - 1);
        LibraryVariableStorage.Enqueue(SalesHeader."Bill-to Customer No.");

        // [WHEN] Run Credit Limit check by function SalesHeaderCheck in codeunit "Cust-Check Cr. Limit"
        CustCheckCrLimit.SalesHeaderCheck(SalesHeader);

        // [THEN] "Check Credit Limit" page shown and "Balance Due (LCY)" is 50
        Assert.AreEqual(OverdueAmount, LibraryVariableStorage.DequeueDecimal(), 'Incorrect overdue amount on Check Credit Limit page');

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,CheckCrLimitDrilldownOverdueAmountModalPageHandler,CustomerLedgerEntriesVerifySingleEntryWithAmountPageHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure DrilldownOnBalanceDueLCYOfCheckCrLimitPageShowsOnlyOverdueEntries()
    var
        SalesHeader: Record "Sales Header";
        CustCheckCrLimit: Codeunit "Cust-Check Cr. Limit";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        OverdueAmount: Decimal;
    begin
        // [FEAUTURE] [UI] [UT]
        // [SCENARIO 384838] Only Customer Ledger Entries with "Due Date" less than today shows when drill-down field "Balance Due (LCY)" on "Check Credit Limit" page

        Initialize();

        // [GIVEN] Today is 24.01.19
        // [GIVEN] Customer with two entries
        // [GIVEN] First entry has "Due Date" = 24.01.19 and Amount = 100
        // [GIVEN] Second entry has "Due Date" = 23.01.19 and Amount = 50
        CreateSalesOrderWithOverdueCust(SalesHeader, OverdueAmount, Today, Today - 1);
        LibraryVariableStorage.Enqueue(SalesHeader."Bill-to Customer No.");

        // [GIVEN] Credit Limit check called and "Check Credit Limit" page is opened
        CustCheckCrLimit.SalesHeaderCheck(SalesHeader);

        // [WHEN] Drill-down field "Balance Due (LCY)" on "Check Credit Limit" page
        // [THEN] "Customer Ledger Entries" page is shown with only one Customer Ledger Entry entry with Amount = 50
        Assert.AreEqual(
          OverdueAmount, LibraryVariableStorage.DequeueDecimal(), 'Incorrect amount when drill-down Balance Due on Check Credit Limit page');

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CustomerLedgerEntriesVerifySingleEntryWithAmountPageHandler')]
    [Scope('OnPrem')]
    procedure DrilldownOnBalanceDueLCYOfCustStatFactboxPageShowsOnlyOverdueEntries()
    var
        SalesHeader: Record "Sales Header";
        CustomerList: TestPage "Customer List";
        OverdueAmount: Decimal;
    begin
        // [FEAUTURE] [UI] [UT]
        // [SCENARIO 218532] Only Customer Ledger Entries with "Due Date" less than today shows when drill-down field "Balance Due (LCY)" on "Customer Statistics Factbox" page

        Initialize();

        // [GIVEN] Today is 24.01.19
        // [GIVEN] Customer with two entries
        // [GIVEN] First entry has "Due Date" = 24.01.19 and Amount = 100
        // [GIVEN] Second entry has "Due Date" = 23.01.19 and Amount = 50
        CreateSalesOrderWithOverdueCust(SalesHeader, OverdueAmount, Today, Today - 1);
        Commit();  // so background session can see the new customer

        // [GIVEN] "Customer List" page opens for Customer with Overdue balance = 50
        CustomerList.OpenView();
        CustomerList.FILTER.SetFilter("No.", SalesHeader."Bill-to Customer No.");
        CustomerList.CustomerStatisticsFactBox."Balance Due (LCY)".AssertEquals(OverdueAmount);

        // [WHEN] Drill-down field "Balance Due (LCY)" on "Customer Statistics Factbox" page
        CustomerList.CustomerStatisticsFactBox."Balance Due (LCY)".DrillDown();

        // [THEN] "Customer Ledger Entries" page is shown with only one Customer Ledger Entry entry with Amount = 50
        Assert.AreEqual(
          OverdueAmount, LibraryVariableStorage.DequeueDecimal(), 'Incorrect amount when drill-down Balance Due on Check Credit Limit page');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_ShipToOptionForNewSalesDocument()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustomerMgt: Codeunit "Customer Mgt.";
        ShipToOptions: Enum "Sales Ship-to Options";
        BillToOptions: Enum "Sales Bill-to Options";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 222981] Ship-To Option for newly created Sales Document
        Initialize();
        CreateCustomerWithAddress(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        CustomerMgt.CalculateShipBillToOptions(ShipToOptions, BillToOptions, SalesHeader);
        Assert.AreEqual(
          Format(ShipToOptions::"Default (Sell-to Address)"), Format(ShipToOptions), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_ShipToOptionWhenShipToNameIsChanged()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustomerMgt: Codeunit "Customer Mgt.";
        ShipToOptions: Enum "Sales Ship-to Options";
        BillToOptions: Enum "Sales Bill-to Options";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 222981] Ship-To Option for Sales Document where 'Ship-to Name' is changed
        Initialize();
        CreateCustomerWithAddress(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader."Ship-to Name" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(SalesHeader."Ship-to Name")), 1, MaxStrLen(SalesHeader."Ship-to Name"));
        SalesHeader.Modify();

        CustomerMgt.CalculateShipBillToOptions(ShipToOptions, BillToOptions, SalesHeader);
        Assert.AreEqual(Format(ShipToOptions::"Custom Address"), Format(ShipToOptions), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_ShipToOptionWhenShipToName2IsChanged()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustomerMgt: Codeunit "Customer Mgt.";
        ShipToOptions: Enum "Sales Ship-to Options";
        BillToOptions: Enum "Sales Bill-to Options";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 222981] Ship-To Option for Sales Document where 'Ship-to Name 2' is changed
        Initialize();
        CreateCustomerWithAddress(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader."Ship-to Name 2" :=
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(SalesHeader."Ship-to Name 2")), 1, MaxStrLen(SalesHeader."Ship-to Name 2"));
        SalesHeader.Modify();

        CustomerMgt.CalculateShipBillToOptions(ShipToOptions, BillToOptions, SalesHeader);
        Assert.AreEqual(Format(ShipToOptions::"Custom Address"), Format(ShipToOptions), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_ShipToOptionWhenShipToAddressIsChanged()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustomerMgt: Codeunit "Customer Mgt.";
        ShipToOptions: Enum "Sales Ship-to Options";
        BillToOptions: Enum "Sales Bill-to Options";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 222981] Ship-To Option for Sales Document where 'Ship-to Address' is changed
        Initialize();
        CreateCustomerWithAddress(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader."Ship-to Address" :=
          CopyStr(
            LibraryUtility.GenerateRandomText(MaxStrLen(SalesHeader."Ship-to Address")), 1, MaxStrLen(SalesHeader."Ship-to Address"));
        SalesHeader.Modify();

        CustomerMgt.CalculateShipBillToOptions(ShipToOptions, BillToOptions, SalesHeader);
        Assert.AreEqual(Format(ShipToOptions::"Custom Address"), Format(ShipToOptions), '');
    end;

    [Test]
    [HandlerFunctions('ContactListPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure UpdateShipToContactFromSellToContactOnSalesDocuments()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        ContactNew: Record Contact;
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [UT] [Contact]
        // [SCENARIO 232395] Ship-To Contact is updated in Sales Document when Sell-to Contact is changed on the card page
        Initialize();

        // [GIVEN] Customer with two contacts "C1" and "C2"
        CreateCustomerWithTwoContacts(Customer, Contact, ContactNew);

        // [GIVEN] Sales Order with default Contact "C1"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        // [WHEN] Select second contact "C2" when lookup Sell-to Contact field on the Sales Order page
        LibraryVariableStorage.Enqueue(ContactNew."No.");
        SalesOrder."Sell-to Contact".Lookup();
        SalesOrder.OK().Invoke();

        // [THEN] Sales Order has "Sell-to Contact No." = "C2".No., "Sell-to Contact" = "C2".Name, "Ship-to Contact" = "C2".Name
        // [THEN] Ship-to Option is "Default (Sell-to Address)" in Sales Order
        VerifyShipToOptionWithContactOnSalesDocument(SalesHeader, ContactNew);
    end;

    [Test]
    [HandlerFunctions('ContactListPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure UpdateSellToContactNoFromSellToContactOnSalesDocuments()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        ContactNew: Record Contact;
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [UT] [Contact]
        // [SCENARIO 232395] Ship-To Contact updated in Sales Document when Sell-to Contact No. is changed on the card page
        Initialize();

        // [GIVEN] Customer with two contacts "C1" and "C2"
        CreateCustomerWithTwoContacts(Customer, Contact, ContactNew);

        // [GIVEN] Sales Order with default Contact "C1"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        // [WHEN] Select second contact "C2" when lookup Sell-to Contact No. field on the Sales Order page
        LibraryVariableStorage.Enqueue(ContactNew."No.");
        SalesOrder."Sell-to Contact No.".Lookup();
        SalesOrder.OK().Invoke();

        // [THEN] Sales Order has "Sell-to Contact No." = "C2".No., "Sell-to Contact" = "C2".Name, "Ship-to Contact" = "C2".Name
        // [THEN] Ship-to Option is "Default (Sell-to Address)" in Sales Order
        VerifyShipToOptionWithContactOnSalesDocument(SalesHeader, ContactNew);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllowInvoiceDiscIsFalseOnOverviewPageWhenFalseInSalesPrice()
    var
        SalesPrice: Record "Sales Price";
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        Item: Record Item;
        AllowInvoiceDisc: Boolean;
        AllowLineDisc: Boolean;
    begin
        // [FEATURE] [UT] [Sales Price] [Sales Price and Line Discounts]
        // [SCENARIO 254851] When open page Sales Price and Line Discounts for Item with Sales Price, having "Allow Invoice Disc." = FALSE and "Allow Line Disc." = TRUE, then on page: "Allow Invoice Disc." = FALSE and "Allow Line Disc." = TRUE.
        Initialize();
        AllowInvoiceDisc := false;
        AllowLineDisc := true;

        // [GIVEN] Sales Price for Item "I" with "Allow Invoice Disc." = FALSE and "Allow Line Disc." = TRUE
        CreateSalesPriceWithDiscounts(SalesPrice, AllowInvoiceDisc, AllowLineDisc);

        // [WHEN] Load data for Item "I" in Sales Price and Line Disc Buff
        Item.Get(SalesPrice."Item No.");
        TempSalesPriceAndLineDiscBuff.LoadDataForItem(Item);

        // [THEN] Sales Price and Line Disc Buff is created with "Allow Invoice Disc." = FALSE and "Allow Line Disc." = TRUE
        VerifySalesPriceAndLineDiscBuff(TempSalesPriceAndLineDiscBuff, SalesPrice."Item No.", AllowInvoiceDisc, AllowLineDisc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllowLineDiscIsFalseOnOverviewPageWhenFalseInSalesPrice()
    var
        SalesPrice: Record "Sales Price";
        TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary;
        Item: Record Item;
        AllowInvoiceDisc: Boolean;
        AllowLineDisc: Boolean;
    begin
        // [FEATURE] [UT] [Sales Price] [Sales Price and Line Discounts]
        // [SCENARIO 254851] When open page Sales Price and Line Discounts for Item with Sales Price, having "Allow Invoice Disc." = TRUE and "Allow Line Disc." = FALSE, then on page: "Allow Invoice Disc." = TRUE and "Allow Line Disc." = FALSE.
        Initialize();
        AllowInvoiceDisc := true;
        AllowLineDisc := false;

        // [GIVEN] Sales Price for Item "I" with "Allow Invoice Disc." = TRUE and "Allow Line Disc." = FALSE
        CreateSalesPriceWithDiscounts(SalesPrice, AllowInvoiceDisc, AllowLineDisc);

        // [WHEN] Load data for Item "I" in Sales Price and Line Disc Buff
        Item.Get(SalesPrice."Item No.");
        TempSalesPriceAndLineDiscBuff.LoadDataForItem(Item);

        // [THEN] Sales Price and Line Disc Buff is created with "Allow Invoice Disc." = TRUE and "Allow Line Disc." = FALSE
        VerifySalesPriceAndLineDiscBuff(TempSalesPriceAndLineDiscBuff, SalesPrice."Item No.", AllowInvoiceDisc, AllowLineDisc);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderShipToOptionWhenTwoCitiesHaveOnePostCode()
    var
        Customer: Record Customer;
        PostCode: Record "Post Code";
        SalesHeader: Record "Sales Header";
        CustomerMgt: Codeunit "Customer Mgt.";
        SalesOrder: TestPage "Sales Order";
        ShipToOptions: Enum "Sales Ship-to Options";
        BillToOptions: Enum "Sales Bill-to Options";
    begin
        // [FEATURE] [UI] [Order] [Post Code]
        // [SCENARIO 274927] Stan can set Ship-to Option to "Default (Sell-to Address)" when Sell-to City is changed to not first Post Code with the same Code.
        Initialize();

        // [GIVEN] Two Post Codes with equal Codes and cities "A" and "B"
        CreateTwoPostCodesWithEqualCodes(PostCode);
        // [GIVEN] Customer with Post Code Code and city "B"
        LibrarySales.CreateCustomer(Customer);
        UpdateCustomerPostCodeAndCity(Customer, PostCode);
        // [GIVEN] Sales Header entry with Ship-to address different from Customer Address
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Ship-to Address", LibraryUtility.GenerateRandomText(5));
        SalesHeader.Modify(true);

        // [WHEN] Stan sets Ship-to Option to "Default (Sell-to Address)"
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.ShippingOptions.SetValue(ShipToOptions::"Default (Sell-to Address)");
        SalesOrder.OK().Invoke();

        // [THEN] Ship-to Option is set to "Default (Sell-to Address)"
        SalesHeader.Find();
        CustomerMgt.CalculateShipBillToOptions(ShipToOptions, BillToOptions, SalesHeader);
        Assert.AreEqual(Format(ShipToOptions::"Default (Sell-to Address)"), Format(ShipToOptions), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteShipToOptionWhenTwoCitiesHaveOnePostCode()
    var
        Customer: Record Customer;
        PostCode: Record "Post Code";
        SalesHeader: Record "Sales Header";
        CustomerMgt: Codeunit "Customer Mgt.";
        SalesQuote: TestPage "Sales Quote";
        ShipToOptions: Enum "Sales Ship-to Options";
        BillToOptions: Enum "Sales Bill-to Options";
    begin
        // [FEATURE] [UI] [Quote] [Post Code]
        // [SCENARIO 274927] Stan can set Ship-to Option to "Default (Sell-to Address)" when Sell-to City is changed to not first Post Code with the same Code.
        Initialize();

        // [GIVEN] Two Post Codes with equal Codes and cities "A" and "B"
        CreateTwoPostCodesWithEqualCodes(PostCode);
        // [GIVEN] Customer with Post Code Code and city "B"
        LibrarySales.CreateCustomer(Customer);
        UpdateCustomerPostCodeAndCity(Customer, PostCode);
        // [GIVEN] Sales Header entry with Ship-to address different from Customer Address
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, Customer."No.");
        SalesHeader.Validate("Ship-to Address", LibraryUtility.GenerateRandomText(5));
        SalesHeader.Modify(true);

        // [WHEN] Stan sets Ship-to Option to "Default (Sell-to Address)"
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);
        SalesQuote.ShippingOptions.SetValue(ShipToOptions::"Default (Sell-to Address)");
        SalesQuote.OK().Invoke();

        // [THEN] Ship-to Option is set to "Default (Sell-to Address)"
        SalesHeader.Find();
        CustomerMgt.CalculateShipBillToOptions(ShipToOptions, BillToOptions, SalesHeader);
        Assert.AreEqual(Format(ShipToOptions::"Default (Sell-to Address)"), Format(ShipToOptions), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceShipToOptionWhenTwoCitiesHaveOnePostCode()
    var
        Customer: Record Customer;
        PostCode: Record "Post Code";
        SalesHeader: Record "Sales Header";
        CustomerMgt: Codeunit "Customer Mgt.";
        SalesInvoice: TestPage "Sales Invoice";
        ShipToOptions: Enum "Sales Ship-to Options";
        BillToOptions: Enum "Sales Bill-to Options";
    begin
        // [FEATURE] [UI] [Invoice] [Post Code]
        // [SCENARIO 274927] Stan can set Ship-to Option to "Default (Sell-to Address)" when Sell-to City is changed to not first Post Code with the same Code.
        Initialize();

        // [GIVEN] Two Post Codes with equal Codes and cities "A" and "B"
        CreateTwoPostCodesWithEqualCodes(PostCode);
        // [GIVEN] Customer with Post Code Code and city "B"
        LibrarySales.CreateCustomer(Customer);
        UpdateCustomerPostCodeAndCity(Customer, PostCode);
        // [GIVEN] Sales Header entry with Ship-to address different from Customer Address
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Ship-to Address", LibraryUtility.GenerateRandomText(5));
        SalesHeader.Modify(true);

        // [WHEN] Stan sets Ship-to Option to "Default (Sell-to Address)"
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice.ShippingOptions.SetValue(ShipToOptions::"Default (Sell-to Address)");
        SalesInvoice.OK().Invoke();

        // [THEN] Ship-to Option is set to "Default (Sell-to Address)"
        SalesHeader.Find();
        CustomerMgt.CalculateShipBillToOptions(ShipToOptions, BillToOptions, SalesHeader);
        Assert.AreEqual(Format(ShipToOptions::"Default (Sell-to Address)"), Format(ShipToOptions), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesBlanketOrderShipToOptionWhenTwoCitiesHaveOnePostCode()
    var
        Customer: Record Customer;
        PostCode: Record "Post Code";
        SalesHeader: Record "Sales Header";
        CustomerMgt: Codeunit "Customer Mgt.";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
        ShipToOptions: Enum "Sales Ship-to Options";
        BillToOptions: Enum "Sales Bill-to Options";
    begin
        // [FEATURE] [UI] [Blanket Order] [Post Code]
        // [SCENARIO 274927] Stan can set Ship-to Option to "Default (Sell-to Address)" when Sell-to City is changed to not first Post Code with the same Code.
        Initialize();

        // [GIVEN] Two Post Codes with equal Codes and cities "A" and "B"
        CreateTwoPostCodesWithEqualCodes(PostCode);
        // [GIVEN] Customer with Post Code Code and city "B"
        LibrarySales.CreateCustomer(Customer);
        UpdateCustomerPostCodeAndCity(Customer, PostCode);
        // [GIVEN] Sales Header entry with Ship-to address different from Customer Address
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", Customer."No.");
        SalesHeader.Validate("Ship-to Address", LibraryUtility.GenerateRandomText(5));
        SalesHeader.Modify(true);

        // [WHEN] Stan sets Ship-to Option to "Default (Sell-to Address)"
        BlanketSalesOrder.OpenEdit();
        BlanketSalesOrder.GotoRecord(SalesHeader);
        BlanketSalesOrder.ShippingOptions.SetValue(ShipToOptions::"Default (Sell-to Address)");
        BlanketSalesOrder.OK().Invoke();

        // [THEN] Ship-to Option is set to "Default (Sell-to Address)"
        SalesHeader.Find();
        CustomerMgt.CalculateShipBillToOptions(ShipToOptions, BillToOptions, SalesHeader);
        Assert.AreEqual(Format(ShipToOptions::"Default (Sell-to Address)"), Format(ShipToOptions), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesHeaderCheckUpdatesSalesHeader()
    var
        SalesHeader: Record "Sales Header";
        CustCheckCrLimit: Codeunit "Cust-Check Cr. Limit";
        ERMSalesDocumentsII: Codeunit "ERM Sales Documents II";
    begin
        // [SCENARIO 275714] Sales Header changed by subscriber on event inside SalesHeaderCheck
        // [GIVEN] Sales Header with empty Ship to Adress
        Initialize();

        CreateSaleHeader(SalesHeader, SalesHeader."Document Type"::Order);
        SalesHeader."Ship-to Address" := '';
        SalesHeader.Modify();

        // [WHEN] SalesHeaderCheck is called
        BindSubscription(ERMSalesDocumentsII);
        CustCheckCrLimit.SalesHeaderCheck(SalesHeader);
        UnbindSubscription(ERMSalesDocumentsII);

        // [THEN] Sales Header Ship to Adsress is equal to ShipToAdressTestValue
        SalesHeader.Find();
        SalesHeader.TestField("Ship-to Address", ShipToAdressTestValueTxt);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ArchivedSalesQuoteReportSalesLineOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DescriptionTxt: Text[10];
        ColumnNo: Integer;
        i: Integer;
        RowNo: Integer;
    begin
        // [FEATURE] [Report] [Archive] [Quote]
        // [SCENARIO 297794] Archived Sales Quote report prints Sales Lines in the order they were added.
        Initialize();

        // [GIVEN] Archived Sales Quote with multiple Sales Lines
        DescriptionTxt := CopyStr(LibraryRandom.RandText(10), 1);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, LibrarySales.CreateCustomerNo());
        for i := 1 to 10 do begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::" ", '', LibraryRandom.RandInt(10));
            SalesLine.Validate(Description, DescriptionTxt + Format(i));
            SalesLine.Modify(true);
        end;
        ArchiveSalesDocument(SalesHeader);

        // [WHEN] Report "Archived Sales Quote" is run.
        RunArchivedSalesQuoteReport(SalesHeader);
        // [THEN] Sales Lines are in correct order.
        LibraryReportValidation.OpenFile();
        LibraryReportValidation.FindRowNoColumnNoByValueOnWorksheet(DescriptionTxt + '1', 1, RowNo, ColumnNo);
        for i := 2 to 10 do begin
            RowNo := RowNo + 1;
            LibraryReportValidation.VerifyCellValue(RowNo, ColumnNo, DescriptionTxt + Format(i));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderSellToPhoneNoEmailArchived()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderArchive: Record "Sales Header Archive";
    begin
        // [FEATURE] [UT] [Archive]
        // [SCENARIO 297794] Sales Order "Sell-to Phone No." is archived successfully
        Initialize();

        LibrarySales.CreateSalesOrder(SalesHeader);
        SalesHeader.Validate("Sell-to Phone No.", LibraryUtility.GenerateRandomNumericText(5));
        SalesHeader."Sell-to E-Mail" := LibraryUtility.GenerateGUID();
        SalesHeader.Modify(true);

        ArchiveSalesDocument(SalesHeader);
        FindSalesHeaderArchive(SalesHeaderArchive, SalesHeader);

        SalesHeaderArchive.TestField("Sell-to Phone No.", SalesHeader."Sell-to Phone No.");
        SalesHeaderArchive.TestField("Sell-to E-Mail", SalesHeader."Sell-to E-Mail");
    end;

    [Test]
    procedure TwoSingleQuotesFilterRecordsWithEmptyStartingDate()
    var
        SalesPrice1: Record "Sales Price";
        SalesPrice2: Record "Sales Price";
        SalesPrices: TestPage "Sales Prices";
    begin
        // [FEATURE] [UT] [Customer] [Sales Price]
        // [SCENARIO 305079] Records with empty starting date are filtered when two single quotes are set as value for Starting date filter field on Sales Prices page.
        Initialize();

        // [GIVEN] Sales Price record "S1" with "S1"."Starting Date" = '';
        // [GIVEN] Sales Price record "S2" with "S2"."Starting Date" = WORKDATE;
        // [GIVEN] Sales Prices page.
        CreateTwoSalesPrices(SalesPrice1, SalesPrice2);
        SalesPrices.OpenView();
        SalesPrices.SalesTypeFilter.SetValue(SalesPrice1."Sales Type"::"All Customers");

        // [WHEN] Validate Starting Date Filter field with two single quotes.
        SalesPrices.StartingDateFilter.SetValue('''''');

        // [THEN] "S1" is found.
        Assert.IsTrue(SalesPrices.GotoRecord(SalesPrice1), EmptyStartingDateRecIsNotFoundErr);
        // [THEN] "S2" is not found.
        Assert.IsFalse(SalesPrices.GotoRecord(SalesPrice2), StrSubstNo(WorkStartingDateRecIsFoundErr, SalesPrice2."Starting Date"));
    end;

    [Test]
    procedure WorkdateFiltersRecordsWithWorkStartingDate()
    var
        SalesPrice1: Record "Sales Price";
        SalesPrice2: Record "Sales Price";
        SalesPrices: TestPage "Sales Prices";
    begin
        // [FEATURE] [UT] [Customer] [Sales Price]
        // [SCENARIO 305079] Records with defined starting date are filtered when this date is set as value for Starting date filter field on Sales Prices page.
        Initialize();

        // [GIVEN] Sales Price record "S1" with "S1"."Starting Date" = '';
        // [GIVEN] Sales Price record "S2" with "S2"."Starting Date" = WORKDATE;
        // [GIVEN] Sales Prices page.
        CreateTwoSalesPrices(SalesPrice1, SalesPrice2);
        SalesPrices.OpenView();
        SalesPrices.SalesTypeFilter.SetValue(SalesPrice1."Sales Type"::"All Customers");

        // [WHEN] Validate Starting Date Filter field with WORKDATE.
        SalesPrices.StartingDateFilter.SetValue(WorkDate());

        // [THEN] "S1" is not found.
        Assert.IsFalse(SalesPrices.GotoRecord(SalesPrice1), StrSubstNo(EmptyStartingDateIsFoundErr, SalesPrice1."Starting Date", WorkDate()));
        // [THEN] "S2" is found.
        Assert.IsTrue(SalesPrices.GotoRecord(SalesPrice2), StrSubstNo(WorkStartingDateRecIsNotFoundErr, WorkDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckErrorForRenameInStandardCustomerSalesCode()
    var
        StandardCustomerSalesCode: Record "Standard Customer Sales Code";
        StandardSalesCode: array[2] of Record "Standard Sales Code";
    begin
        // [FEATURE] [Customer] [Standard Code]
        // [SCENARIO 305079] Rename field Code in table StandardCustomerSalesCode with running OnRename trigger.
        Initialize();

        // [GIVEN] Two lines in Standard Sales Code was created.
        CreateStandardSalesCode(StandardSalesCode[1]);
        CreateStandardSalesCode(StandardSalesCode[2]);

        // [GIVEN] Standard Customer Sales Code was created for first line of Standard Sales Code.
        CreateStandardCustomerSalesCode(StandardCustomerSalesCode, StandardSalesCode[1].Code);

        // [WHEN] Rename Standard Customer Sales Code to field Code of second variant of Standard Sales Code
        asserterror StandardCustomerSalesCode.Rename('', StandardSalesCode[2].Code);

        // [THEN] The error about trying rename Standard Customer Sales Code was shown.
        Assert.ExpectedError(ExpectedRenameErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckErrorForRenameInStandardVendorPurchaseCode()
    var
        StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code";
        StandardPurchaseCode: array[2] of Record "Standard Purchase Code";
    begin
        // [FEATURE] [Vendor] [Standard Code]
        // [SCENARIO 305079] Rename field Code in table Standard Vendor Purchase Code with running OnRename trigger.
        Initialize();

        // [GIVEN] Two lines in Standard Purchase Code was created.
        CreateStandardPurchaseCode(StandardPurchaseCode[1]);
        CreateStandardPurchaseCode(StandardPurchaseCode[2]);

        // [GIVEN] Standard Vendor Purchase Code was created for first line of Standard Purchase Code.
        CreateStandardVendorPurchaseCode(StandardVendorPurchaseCode, StandardPurchaseCode[1].Code);

        // [WHEN] Rename Standard Vendor Purchase Code to field Code of second variant of Standard Purchase Code
        asserterror StandardVendorPurchaseCode.Rename('', StandardPurchaseCode[2].Code);

        // [THEN] The error about trying rename Standard Customer Sales Code was shown.
        Assert.ExpectedError(ExpectedRenameErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemLedgerentryCountryRegionAfterPostingSalesDocumentWithoutShipToCode()
    var
        CountryRegion: Record "Country/Region";
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 377153] Posting Sales document with Ship-to Country/Region code and empty Ship-to code creates Item Ledger with Country/Region code.
        Initialize();

        // [GIVEN] Sales document with Ship-to Country/Region code and empty Ship-to code.
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo(), SalesLine.Type::Item, '');
        LibraryERM.CreateCountryRegion(CountryRegion);
        SalesHeader.Validate("Ship-to Country/Region Code", CountryRegion.Code);
        SalesHeader.Modify(true);

        // [WHEN] Sales document is posted.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Resulting Item Ledger entry has Country/Region code.
        FindItemLedgerEntry(
          ItemLedgerEntry, SalesLine."No.", ItemLedgerEntry."Entry Type"::Sale, ItemLedgerEntry."Document Type"::"Sales Shipment");
        ItemLedgerEntry.TestField("Country/Region Code", CountryRegion.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemLedgerentryCountryRegionAfterPostingSalesReturnOrderWithSellToCountryRegion()
    var
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 377153] Posting Sales Return Order with Sell-To Country/Region code creates Item Ledger with Country/Region code.
        Initialize();

        // [GIVEN] Sales Return Order with Sell-to Country/Region code and empty Ship-to code.
        LibraryERM.CreateCountryRegion(CountryRegion);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", CountryRegion.Code);
        Customer.Modify(true);
        CreateSalesDocument(
            SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", Customer."No.", SalesLine.Type::Item, '');
        SalesHeader.Validate("Ship-to Country/Region Code", CountryRegion.Code);
        SalesHeader.Modify(true);

        // [WHEN] Sales Return Order is posted.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Resulting Item Ledger entry has Country/Region code.
        FindItemLedgerEntry(
          ItemLedgerEntry, SalesLine."No.", "Item Ledger Entry Type"::Sale, ItemLedgerEntry."Document Type"::"Sales Return Receipt");
        ItemLedgerEntry.TestField("Country/Region Code", CountryRegion.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure UpdateContactInfoAfterChangeSelltoContactNoinSalesOrderByValidatePageField()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        Contact2: Record Contact;
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 414694] When user change Sell-to Contact No. in Sales Order card then contact info must be updated
        Initialize();

        // [GIVEN] Customer with two contacts
        // [GIVEN] First contact "C1" with phone = "111111111", mobile phone = "222222222" and email = "contact1@mail.com"
        // [GIVEN] Second contact "C2" with phone = "333333333", mobile phone = "444444444" and email = "contact2@mail.com"
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);
        UpdateContactInfo(Contact, '111111111', '222222222', 'contact1@mail.com');
        Contact.Modify(true);
        Customer.Validate("Primary Contact No.", Contact."No.");
        Customer.Modify(true);
        LibraryMarketing.CreatePersonContact(Contact2);
        UpdateContactInfo(Contact2, '333333333', '444444444', 'contact2@mail.com');
        Contact2.Validate("Company No.", Contact."Company No.");
        Contact2.Modify(true);

        // [GIVEN] Sales Order with "Sell-to Contact No." = "C1"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesOrder.Trap();
        Page.Run(Page::"Sales Order", SalesHeader);

        // [WHEN] User set "Sell-to Contact No." = "C2" by validate page field
        SalesOrder."Sell-to Contact No.".SetValue(Contact2."No.");

        // [THEN] "Sales Order"."Phone No." = "333333333"
        SalesOrder."Sell-to Phone No.".AssertEquals(Contact2."Phone No.");

        // [THEN] "Sales Order"."Mobile Phone No." = "444444444"
        SalesOrder.SellToMobilePhoneNo.AssertEquals(Contact2."Mobile Phone No.");

        // [THEN] "Sales Order"."Email" = "contact2@mail.com"
        SalesOrder."Sell-to E-Mail".AssertEquals(Contact2."E-Mail");
    end;

    [Test]
    [HandlerFunctions('ContactListPageHandler,ConfirmHandlerYes')]
    procedure UpdateContactInfoAfterChangeSelltoContactNoinSalesOrderCardByLookup()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        Contact2: Record Contact;
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [UI]
        // [SCENARIO] When user change Sell-to Contact No. in Sales Order then contact info must be updated
        Initialize();

        // [GIVEN] Customer with two contacts
        // [GIVEN] First contact "C1" with phone = "111111111", mobile phone = "222222222" and email = "contact1@mail.com"
        // [GIVEN] Second contact "C2" with phone = "333333333", mobile phone = "444444444" and email = "contact2@mail.com"
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);
        UpdateContactInfo(Contact, '111111111', '222222222', 'contact1@mail.com');
        Contact.Modify(true);
        Customer.Validate("Primary Contact No.", Contact."No.");
        Customer.Modify(true);
        LibraryMarketing.CreatePersonContact(Contact2);
        UpdateContactInfo(Contact2, '333333333', '444444444', 'contact2@mail.com');
        Contact2.Validate("Company No.", Contact."Company No.");
        Contact2.Modify(true);

        // [GIVEN] Sales Order with "Sell-to Contact No." = "C1"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesOrder.Trap();
        Page.Run(Page::"Sales Order", SalesHeader);

        // [WHEN] User set "Sell-to Contact No." = "C2" by validate page field
        LibraryVariableStorage.Enqueue(Contact2."No.");
        SalesOrder."Sell-to Contact No.".Lookup();

        // [THEN] "Sales Order"."Phone No." = "333333333"
        SalesOrder."Sell-to Phone No.".AssertEquals(Contact2."Phone No.");

        // [THEN] "Sales Order"."Mobile Phone No." = "444444444"
        SalesOrder.SellToMobilePhoneNo.AssertEquals(Contact2."Mobile Phone No.");

        // [THEN] "Sales Order"."Email" = "contact2@mail.com"
        SalesOrder."Sell-to E-Mail".AssertEquals(Contact2."E-Mail");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CustomerLookupPageHandler')]
    procedure SalesQuoteLookup()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [UT][UI]
        // [SCENARIO 412023] Set "Sell-to Customer No." in Sales Header in Sales Quote page by lookup
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        LibraryVariableStorage.Enqueue(Customer.Name);
        SalesQuote.OpenNew();
        SalesQuote."Sell-to Customer Name".Lookup();
        SalesHeader.SetRange("Sell-to Customer No.", Customer."No.");
        Assert.RecordCount(SalesHeader, 1);
    end;

    [Test]
    [HandlerFunctions('ContactListPageHandler,ConfirmHandlerCount')]
    procedure SalesOrderContactChangeLookupBilltoContactAskedOnce()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        Contact2: Record Contact;
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 426882] When user change Sell-to Contact No. in Sales Order "Do you want to change Bill-to Contact No?" should not be asked twice
        Initialize();

        // [GIVEN] Customer with two contacts
        // [GIVEN] First contact "C1" with phone = "111111111", mobile phone = "222222222" and email = "contact1@mail.com"
        // [GIVEN] Second contact "C2" with phone = "333333333", mobile phone = "444444444" and email = "contact2@mail.com"
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);
        UpdateContactInfo(Contact, '111111111', '222222222', 'contact1@mail.com');
        Contact.Modify(true);
        Customer.Validate("Primary Contact No.", Contact."No.");
        Customer.Modify(true);
        LibraryMarketing.CreatePersonContact(Contact2);
        UpdateContactInfo(Contact2, '333333333', '444444444', 'contact2@mail.com');
        Contact2.Validate("Company No.", Contact."Company No.");
        Contact2.Modify(true);

        // [GIVEN] Sales Order with "Sell-to Contact No." = "C1"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesOrder.Trap();
        Page.Run(Page::"Sales Order", SalesHeader);

        // [WHEN] User set "Sell-to Contact No." = "C2" by Look-Up on "Contact No." field
        LibraryVariableStorage.Enqueue(Contact2."No.");
        LibraryVariableStorage.Enqueue(true);  // true for "Do you want to change Sell-to Contact No.?"
        LibraryVariableStorage.Enqueue(0);     // init value for count of confirmation handlers
        LibraryVariableStorage.Enqueue(false); // false for "Do you want to change Bill-to Contact No.?"
        SalesOrder."Sell-to Contact No.".Lookup();

        // [THEN] "Sales Order"."Phone No." = "333333333"
        SalesOrder."Sell-to Phone No.".AssertEquals(Contact2."Phone No.");

        // [THEN] "Sales Order"."Mobile Phone No." = "444444444"
        SalesOrder.SellToMobilePhoneNo.AssertEquals(Contact2."Mobile Phone No.");

        // [THEN] "Sales Order"."Email" = "contact2@mail.com"
        SalesOrder."Sell-to E-Mail".AssertEquals(Contact2."E-Mail");

        // [THEN] Number of confirmation questions = 2
        Assert.AreEqual(2, LibraryVariableStorage.DequeueInteger(), 'Number of confirmations is incorrect');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure MakeInvoiceFromQuoteTransfersLotTracking()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesQuoteHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Header";
        SalesQuoteLine: Record "Sales Line";
        SalesInvoiceLine: Record "Sales Line";
        SalesQuoteTestPage: TestPage "Sales Quote";
        SalesInvoiceTestPage: TestPage "Sales Invoice";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        ReservationStatus: Enum "Reservation Status";
    begin
        // [SCENARIO 451374] Makes Invoice action transfers tracking details from Sales Quote to Sales Invoice.
        Initialize();

        // [GIVEN] Sales Quote with 1 line and Lot tracking
        LibrarySales.CreateCustomer(Customer);
        LibraryItemTracking.CreateLotItem(Item);
        LibrarySales.CreateSalesHeader(SalesQuoteHeader, SalesQuoteHeader."Document Type"::Quote, Customer."No.");
        LibrarySales.CreateSalesLine(SalesQuoteLine, SalesQuoteHeader, SalesQuoteLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // [WHEN] Assign a random lot number.
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::AssignSpecificLot);
        LibraryVariableStorage.Enqueue(LibraryRandom.RandText(10));
        LibraryVariableStorage.Enqueue(SalesQuoteLine.Quantity);
        SalesQuoteLine.OpenItemTrackingLines(); // ItemTrackingLinesPageHandler required.

        // [THEN] Prospect Reservation Entries are created
        VerifyReservationEntry(SalesQuoteLine, 1, -SalesQuoteLine.Quantity, ReservationStatus::Prospect);

        // [WHEN] Make Sales Invoice
        SalesQuoteTestPage.OpenEdit();
        SalesQuoteTestPage.GoToRecord(SalesQuoteHeader);

        SalesInvoiceTestPage.Trap(); //ConfirmHandlerYes opens the newly created sales invoice.
        SalesQuoteTestPage.MakeInvoice.Invoke();

        // [THEN] Reservation Entries are transferred to Sales Invoice and Reservation Status is updated to Surplus. 1 Reservation entry is created for Assigned Lot with Quantity = Quantity on Sales Quote/Invoice Line.
        SalesInvoiceHeader.Get(SalesInvoiceHeader."Document Type"::Invoice, SalesInvoiceTestPage."No.".Value);
        SalesInvoiceLine.SetRange("Document Type", SalesInvoiceHeader."Document Type");
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst();
        VerifyReservationEntry(SalesInvoiceLine, 1, -SalesQuoteLine.Quantity, ReservationStatus::Surplus);

        // [THEN] No Reservation Entries exist for the Sales Quote.
        VerifyReservationEntry(SalesQuoteLine, 0, 0, ReservationStatus::Prospect);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure MakeInvoiceFromQuoteTransfersSNTracking()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesQuoteHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Header";
        SalesQuoteLine: Record "Sales Line";
        SalesInvoiceLine: Record "Sales Line";
        SalesQuoteTestPage: TestPage "Sales Quote";
        SalesInvoiceTestPage: TestPage "Sales Invoice";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        ReservationStatus: Enum "Reservation Status";
    begin
        // [SCENARIO 451374] Makes Invoice action transfers tracking details from Sales Quote to Sales Invoice.
        Initialize();

        // [GIVEN] Sales Quote with 1 line and SN tracking
        LibrarySales.CreateCustomer(Customer);
        LibraryItemTracking.CreateSerialItem(Item);
        LibrarySales.CreateSalesHeader(SalesQuoteHeader, SalesQuoteHeader."Document Type"::Quote, Customer."No.");
        LibrarySales.CreateSalesLine(SalesQuoteLine, SalesQuoteHeader, SalesQuoteLine.Type::Item, Item."No.", LibraryRandom.RandInt(5));

        // [WHEN] Assign random serial numbers.
        LibraryVariableStorage.Enqueue(ItemTrackingHandlerAction::AssignRandomSN);
        LibraryVariableStorage.Enqueue(SalesQuoteLine.Quantity);
        SalesQuoteLine.OpenItemTrackingLines(); // ItemTrackingLinesPageHandler required.

        // [THEN] Prospect Reservation Entries are created
        VerifyReservationEntry(SalesQuoteLine, SalesQuoteLine.Quantity, -1, ReservationStatus::Prospect);

        // [WHEN] Make Sales Invoice
        SalesQuoteTestPage.OpenEdit();
        SalesQuoteTestPage.GoToRecord(SalesQuoteHeader);

        SalesInvoiceTestPage.Trap(); //ConfirmHandlerYes opens the newly created sales invoice.
        SalesQuoteTestPage.MakeInvoice.Invoke();

        // [THEN] Reservation Entries are transferred to Sales Invoice and Reservation Status is updated to Surplus. 1 Reservation entry is created for Assigned Lot with Quantity = Quantity on Sales Quote/Invoice Line.
        SalesInvoiceHeader.Get(SalesInvoiceHeader."Document Type"::Invoice, SalesInvoiceTestPage."No.".Value);
        SalesInvoiceLine.SetRange("Document Type", SalesInvoiceHeader."Document Type");
        SalesInvoiceLine.SetRange("Document No.", SalesInvoiceHeader."No.");
        SalesInvoiceLine.FindFirst();
        VerifyReservationEntry(SalesInvoiceLine, SalesQuoteLine.Quantity, -1, ReservationStatus::Surplus);

        // [THEN] No Reservation Entries exist for the Sales Quote.
        VerifyReservationEntry(SalesQuoteLine, 0, 0, ReservationStatus::Prospect);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        ActionOption: Integer;
        LotNo: Text;
        HowMany: Integer;
        Counter: Integer;
    begin
        ActionOption := LibraryVariableStorage.DequeueInteger();
        case ActionOption of
            ItemTrackingHandlerAction::AssignRandomSN:
                begin
                    HowMany := LibraryVariableStorage.DequeueInteger();
                    if HowMany > 0 then begin
                        ItemTrackingLines.First();
                        for Counter := 1 to HowMany do begin
                            ItemTrackingLines."Serial No.".SetValue(LibraryRandom.RandText(5));
                            ItemTrackingLines."Quantity (Base)".SetValue(1);
                            ItemTrackingLines.Next();
                        end;
                    end;
                end;
            ItemTrackingHandlerAction::AssignSpecificLot:
                begin
                    LotNo := LibraryVariableStorage.DequeueText();
                    ItemTrackingLines.First();
                    ItemTrackingLines."Lot No.".SetValue(LotNo);
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    local procedure VerifyReservationEntry(var SalesLine: Record "Sales Line"; ExpectedCount: Integer; ExpectedQty: Decimal; ReservationStatus: Enum "Reservation Status")
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", SalesLine."No.");
        ReservationEntry.SetRange("Source Type", Database::"Sales Line");
        ReservationEntry.SetRange("Source ID", SalesLine."Document No.");
        ReservationEntry.SetRange("Source Subtype", SalesLine."Document Type");
        ReservationEntry.SetRange("Reservation Status", ReservationStatus);
        Assert.RecordCount(ReservationEntry, ExpectedCount);
        if ExpectedCount > 0 then begin
            ReservationEntry.FindSet();
            repeat
                Assert.AreEqual(ExpectedQty, ReservationEntry.Quantity, StrSubstNo('The Quantity on the Reservation Entry should be equal to %1', ExpectedQty));
            until ReservationEntry.Next() = 0;
        end;
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CheckVATBusPostingGroupWhenChangeBillToForSalesOrderWithDifferentGroup()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        SalesOrder: TestPage "Sales Order";
        BillToOptions: Option "Default (Customer)","Another Customer";
    begin
        // [FEATURE] [Sales Order] [VAT Posting Setup]
        // [SCENARIO 454698] When the VAT Bus. Posting Group is changed on the sales order header the sales lines are not being validated.
        Initialize();

        // Setup: Create Sales Order with VAT Bus. Posting Group different from Customer
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Order, Customer."No.");

        // Setup: Create VAT Posting Setup with another VAT Bus. Posting Group and change it in the Sales Order
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", Item."VAT Prod. Posting Group");
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>%1&<>%2', SalesHeader."VAT Bus. Posting Group", '');
        if not VATPostingSetup.FindFirst() then begin
            LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, Item."VAT Prod. Posting Group");
        end;
        SalesHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        SalesHeader.Modify();

        // Add sales order line with this VAT Bus. Posting Group
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, "Sales Line Type"::Item, Item."No.", 1);
        SalesLine.Validate("Unit Price", 1000);
        SalesLine.Modify();

        // [GIVEN] Open Sales Order card
        SalesOrder.Trap();
        Page.Run(Page::"Sales Order", SalesHeader);

        // [GIVEN] Change field "Bill-to" to "Another Customer" in Sales Order page
        SalesOrder.BillToOptions.SetValue(BillToOptions::"Another Customer");

        // [GIVEN] Change field "Bill-to" back to "Default Customer" in Sales Order page
        SalesOrder.BillToOptions.SetValue(BillToOptions::"Default (Customer)");

        // [THEN] Verify that VAT Bus. Posting Group in Sales Order equal to Customer VAT Bus. Posting Group now
        Assert.AreEqual(Customer."VAT Bus. Posting Group", SalesOrder."VAT Bus. Posting Group".Value, 'incorrect VAT Bus. Posting Group in Sales Header');
        SalesOrder.Close();

        // [THEN] Verify that VAT Bus. Posting Group in Sales Line changed to Customer VAT Bus. Posting Group now
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.TestField("VAT Bus. Posting Group");

        Assert.AreEqual(Customer."VAT Bus. Posting Group", SalesLine."VAT Bus. Posting Group", 'incorrect VAT Bus. Posting Group in Sales Line');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifySalesQuoteLineEditableWhenCreatingSalesQuoteUsingContact()
    var
        Contact: Record Contact;
        Customer: Record Customer;
        ContactCard: TestPage "Contact Card";
        SalesQuotes: TestPage "Sales Quotes";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [SCENARIO 460330] Quote not editable when creating sales quote from contact page.
        Initialize();

        // [GIVEN] Create Contact and Customer
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);

        // [GIVEN] Open Contact Card page
        ContactCard.OpenEdit();
        ContactCard.GoToRecord(Contact);

        // [WHEN] Open Sales Quotes List Page from Contact
        SalesQuotes.Trap();
        ContactCard.SalesQuotes.Invoke();

        // [THEN] Create new Sales Quote with filtered Sell-to Contact No.
        SalesQuote.OpenNew();
        SalesQuote."Sell-to Contact No.".SetValue(SalesQuotes.Filter.GetFilter("Sell-to Contact No."));

        // [VERIFY] Verify: Line Page is Editable
        Assert.IsTrue(SalesQuote.SalesLines.Editable(), SalesQuoteLineNotEditableErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyShipToCountryRegionCodeOnILE()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CountryRegion: Record "Country/Region";
        ItemLedgerEntries: Record "Item Ledger Entry";
        Customer: Record Customer;
        PostedSaleInvoiceNo: code[20];
    begin
        // [SCENARIO 453095] Creating a credit memo from a posted sales invoice with a manually add shipment address the item ledger entry is wrong.
        Initialize();

        // [GIVEN] Sales Order with Sell-to Country/Region code and empty Ship-to code.
        LibraryERM.CreateCountryRegion(CountryRegion);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Country/Region Code", CountryRegion.Code);
        Customer.Modify(true);
        CreateSalesDocument(
            SalesHeader, SalesLine, SalesHeader."Document Type"::Order, Customer."No.", SalesLine.Type::Item, '');
        SalesHeader.Validate("Ship-to Country/Region Code", CountryRegion.Code);
        SalesHeader.Modify(true);

        // [WHEN] Sales Order is posted.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        PostedSaleInvoiceNo := FindPostedSalesOrderToInvoice(SalesHeader."No.");

        // [GIVEN] Sales Credit Memo is created
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");
        SalesCopyDocument(SalesHeader, PostedSaleInvoiceNo, "Sales Document Type From"::"Posted Invoice", false);
        SalesHeader.Validate("Ship-to Country/Region Code", CountryRegion.Code);
        SalesHeader.Modify(true);

        // [WHEN] Sales Credit Memo is posted.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Resulting Item Ledger entry has same Country/Region code.
        FindItemLedgerEntry(
          ItemLedgerEntries, SalesLine."No.", "Item Ledger Entry Type"::Sale, ItemLedgerEntries."Document Type"::"Sales Return Receipt");
        ItemLedgerEntries.TestField("Country/Region Code", CountryRegion.Code);
    end;

    [Test]
    procedure VerifyInvoiceDiscountValueOnSalesHeaderAfterUpdatingPostingDateOnSalesOrderWithLineDiscount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO 468735] Verify Invoice Discount Value on Sales Header after updating Posting Date on Sales Order with Line Discount
        Initialize();

        // [GIVEN] Create Sales Header
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [GIVEN] Create Sales Lines
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1, 1000);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1, 250);

        // [GIVEN] Open Sales Order
        SalesOrder.OpenEdit();
        SalesOrder.Filter.SetFilter("No.", SalesHeader."No.");

        // [GIVEN] Set Invoice Discount Amount
        SalesOrder.SalesLines."Invoice Discount Amount".SetValue(100);
        SalesOrder.Close();

        // [GIVEN] Set Line Discount on first Sales Line
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        SalesLine.Get(SalesHeader."Document Type", SalesHeader."No.", 10000);
        SalesLine.SetSalesHeader(SalesHeader);
        SalesLine.Validate("Line Discount %", 10);
        SalesLine.Modify(true);

        // [WHEN] Set Posting Date
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        SalesHeader.Validate("Posting Date", SalesHeader."Posting Date" + 1);
        SalesHeader.Modify(true);

        // [THEN] Verify results
        SalesOrder.OpenEdit();
        SalesOrder.Filter.SetFilter("No.", SalesHeader."No.");
        SalesOrder.SalesLines."Invoice Discount Amount".AssertEquals(SalesHeader."Invoice Discount Value");
    end;

    [HandlerFunctions('CustomerLookupHandler,ConfirmHandlerYes')]
    [Test]
    procedure UpdateEmailAndPhoneNoWhenChangeBillToOfSalesInvoice()
    var
        Contact: array[2] of Record Contact;
        Customer: array[2] of Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [SCENARIO 564632] The Email and Phone No. should update when selecting Another Customer in the "Bill-to" field of a Sales Invoice
        Initialize();

        // [GIVEN] Create First Customer with First Contact with Phone = "111111111", Mobile Phone = "222222222" and Email = "contact1@mail.com"
        LibraryMarketing.CreateContactWithCustomer(Contact[1], Customer[1]);
        UpdateContactInfo(Contact[1], '111111111', '222222222', 'contact1@mail.com');
        Contact[1].Modify(true);

        // [GIVEN] Create Second Customer with Second Contact with Phone = "333333333", Mobile Phone = "444444444" and Email = "contact2@mail.com"
        LibraryMarketing.CreateContactWithCustomer(Contact[2], Customer[2]);
        UpdateContactInfo(Contact[2], '333333333', '444444444', 'contact2@mail.com');
        Contact[2].Modify(true);

        // [GIVEN] Create Sales Invoice with First Customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer[1]."No.");

        // [GIVEN] Sales Invoice Card is opened
        LibraryVariableStorage.Enqueue(Customer[2]."No.");
        LibraryVariableStorage.Enqueue('');
        LibraryVariableStorage.Enqueue(true); // yes to change "Bill-to Customer No."
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", SalesHeader."No.");

        // [WHEN] Select Second Customer when lookup "Bill-to Customer Name"
        SalesInvoice."Bill-to Name".Lookup();

        // [THEN] Verify Sales Invoice "Phone No." = "333333333"
        SalesInvoice.BillToContactPhoneNo.AssertEquals(Contact[2]."Phone No.");

        // [THEN] Verify Sales Invoice "Mobile Phone No." = "444444444"
        SalesInvoice.BillToContactMobilePhoneNo.AssertEquals(Contact[2]."Mobile Phone No.");

        // [THEN] Verify Sales Invoice "Email" = "contact2@mail.com"
        SalesInvoice.BillToContactEmail.AssertEquals(Contact[2]."E-Mail");
    end;

    [Test]
    [HandlerFunctions('ContactListPageHandler,ConfirmHandlerYes')]
    procedure ShipToContactUpdateFromAlternateShippingAddressContact()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        ContactNew: Record Contact;
        SalesHeader: Record "Sales Header";
        ShipToAddress: Record "Ship-to Address";
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO 562670] Alternate shipping address contact on a Sales Order is changed when changing the contact person on the General FastTab
        Initialize();

        // [GIVEN] Create Customer and ShipToAddress with Contact
        CreateCustomerWithTwoContacts(Customer, Contact, ContactNew);
        LibrarySales.CreateShipToAddress(ShipToAddress, Customer."No.");
        ShipToAddress.Validate(Contact, 'London');
        ShipToAddress.Modify(true);

        // [GIVEN] Sales Order with default Contact
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.Validate("Ship-to Code", ShipToAddress.Code);
        SalesHeader.Modify(true);

        // [WHEN] Open Sales Order page and change Contact on General Tab
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        LibraryVariableStorage.Enqueue(ContactNew."No.");
        SalesOrder."Sell-to Contact".Lookup();
        SalesOrder.OK().Invoke();

        // [THEN] Ship-to Option is "Alternate Shipping Address" in Sales Order
        Assert.AreEqual(ShipToAddress.Contact, SalesHeader."Ship-to Contact", ' ');
    end;

    [Scope('OnPrem')]
    procedure UpdateExtendedTextTypeNotAllowed()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO 564049] Error message when adding a sales line with type Item that have extended text previously
        Initialize();

        // [GIVEN] Item "X" with Extended Text
        CreateItemAndExtendedText(Item);

        // [GIVEN] Create Sales Header
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [GIVEN] Sales Line with Item, second Sales Line with Extended Text
        CreateSalesLineWithExtendedText(SalesHeader, Item."No.");

        // [WHEN] Get extended text Sales Line
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindLast();

        // [THEN] Error come when try to change type of extended text Sales line
        asserterror SalesLine.Validate(Type, SalesLine.Type::Item);

        // [THEN] Verify the error of extended text
        Assert.ExpectedError(StrSubstNo(ChangeExtendedTextErr, SalesLine.FieldCaption(Type)));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure UpdateEmailAndPhoneNoAfterChangeSelltoContactfieldinSalesQuote()
    var
        Customer: Record Customer;
        Contact: Record Contact;
        Contact2: Record Contact;
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [SCENARIO 564179] Email and Phone No. must be updated when change sell-to contact on sales Quote.
        Initialize();

        // [GIVEN] Create Two Contacts with Customer
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);
        UpdateContactInfo(Contact, '111111111', '222222222', 'contact1@mail.com');
        Contact.Modify(true);
        Customer.Validate("Primary Contact No.", Contact."No.");
        Customer.Modify(true);
        LibraryMarketing.CreatePersonContact(Contact2);
        UpdateContactInfo(Contact2, '333333333', '444444444', 'contact2@mail.com');
        Contact2.Validate("Company No.", Contact."Company No.");
        Contact2.Modify(true);

        // [GIVEN] Create Sales Quote
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, Customer."No.");
        SalesQuote.Trap();
        Page.Run(Page::"Sales Quote", SalesHeader);

        // [WHEN] Update "Sell-to Contact"
        SalesQuote."Sell-to Contact No.".SetValue(Contact2."No.");
        SalesQuote."Sell-to Contact".SetValue(Contact2.Name);

        // [THEN] Verify Email and Phone No auto update from Contact
        SalesQuote.SellToPhoneNo.AssertEquals(Contact2."Phone No.");
        SalesQuote.SellToEmail.AssertEquals(Contact2."E-Mail");
    end;

    [Test]
    [HandlerFunctions('ContactListModalPageHandler')]
    procedure CompanyNoAndCompanyNameAutomaticallyFilledOnContactCardWhenCreateNewFromSellToContactNoLookup()
    var
        Contact: Record Contact;
        Contact2: Record Contact;
        Customer: Record Customer;
        Salesheader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [SCENARIO 564179] "Company No." and "Company Name" auto filled from contacts when create new contact from "Sell-to Contact No." lookup
        Initialize();

        // [GIVEN] Create Contact with Customer
        LibraryMarketing.CreateContactWithCustomer(Contact, Customer);
        Customer.Validate("Primary Contact No.", Contact."No.");
        Customer.Modify(true);
        Contact.Validate("Contact Business Relation", Contact."Contact Business Relation"::Customer);
        Contact.Modify(true);

        // [GIVEN] Create Person Contact
        LibraryMarketing.CreatePersonContact(Contact2);
        Contact2.Validate("Company No.", Contact."Company No.");
        Contact2.Validate("Contact Business Relation", Contact2."Contact Business Relation"::Customer);
        Contact2.Modify(true);

        // [GIVEN] Create Sales Quote
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, Customer."No.");

        // [GIVEN] Lookup "Contact list" page.
        SalesQuote.OpenView();
        SalesQuote.GoToRecord(SalesHeader);
        LibraryVariableStorage.Enqueue(Contact2."Company No.");
        SalesQuote."Sell-to Contact No.".Lookup();

        // [THEN] Verify Company No. and Company Name after create new from "Sell-to Contact No." lookup.
    end;

    [HandlerFunctions('ShipToAddressListModalPageHandler')]
    [Test]
    procedure EmailAndPhoneNoUpdateWhenCreateNewShipToAddressFromCustomerCard()
    var
        Customer: Record Customer;
        ShipToAdd: Record "Ship-to Address";
        CustomerCard: TestPage "Customer Card";
    begin
        // [SCENARIO 603179] Email and Phone No. update when create new Ship-to Address from Customer Card

        Initialize();

        // [GIVEN] Customer with address details
        LibrarySales.CreateCustomer(Customer);
        Customer.Address := LibraryUtility.GenerateGUID();
        Customer."E-Mail" := LibraryUtility.GenerateGUID();
        Customer."Phone No." := LibraryUtility.GenerateGUID();
        Customer.Modify();

        // When: Create a new Ship-to Address from Customer Card
        CustomerCard.OpenEdit();
        CustomerCard.Filter.SetFilter("No.", Customer."No.");
        CustomerCard."Ship-to Code".Lookup();
        ShipToAdd.Init();
        ShipToAdd."Customer No." := Customer."No.";
        ShipToAdd.Code := LibraryUtility.GenerateRandomCode(ShipToAdd.FieldNo(Code), DATABASE::"Ship-to Address");
        ShipToAdd."Phone No." := Customer."Phone No.";
        ShipToAdd."E-Mail" := Customer."E-Mail";
        ShipToAdd.Insert();

        // Then: Email and Phone No. in Ship-to Address should be same as in Customer
        Assert.AreEqual(ShipToAdd."Phone No.", Customer."Phone No.", '');
        Assert.AreEqual(ShipToAdd."E-Mail", Customer."E-Mail", '');
    end;

    local procedure Initialize()
    var
        ICSetup: Record "IC Setup";
        GLSetup: Record "General Ledger Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Sales Documents II");
        if not ICSetup.Get() then begin
            ICSetup.Init();
            ICSetup.Insert();
        end;
        ICSetup."Auto. Send Transactions" := false;
        ICSetup.Modify();
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        DocumentNoVisibility.ClearState();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Sales Documents II");

        LibraryTemplates.EnableTemplatesFeature();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        GLSetup.Get();
        GLSetup."Show Amounts" := GLSetup."Show Amounts"::"All Amounts";
        GLSetup.Modify();
        LibrarySetupStorage.SaveGeneralLedgerSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Sales Documents II");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnCustomerCreditLimitNotExceeded', '', false, false)]
    local procedure ChangeSalesHeaderOnCustomerCreditLimitNotExceeded(var Sender: Record "Sales Header")
    begin
        Sender."Ship-to Address" := ShipToAdressTestValueTxt;
        Sender.Modify();
    end;

    local procedure CreateTwoVATPostingSetups(var VATPostingSetup: array[2] of Record "VAT Posting Setup")
    var
        DummyGLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup[1], VATPostingSetup[1]."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 30));
        DummyGLAccount."VAT Bus. Posting Group" := VATPostingSetup[1]."VAT Bus. Posting Group";
        DummyGLAccount."VAT Prod. Posting Group" := VATPostingSetup[1]."VAT Prod. Posting Group";
        VATPostingSetup[2].Get(
          VATPostingSetup[1]."VAT Bus. Posting Group",
          LibraryERM.CreateRelatedVATPostingSetup(DummyGLAccount));
    end;

    local procedure CreateSalesQuoteWithTwoVATSetupLines(var VATPostingSetup: array[2] of Record "VAT Posting Setup"; var SalesHeader: Record "Sales Header"; var TotalBaseAmount: Decimal; var TotalVATAmount: Decimal; PriceIncludingVAT: Boolean)
    begin
        CreateSalesDocWithTwoVATSetupLines(
          VATPostingSetup, SalesHeader, SalesHeader."Document Type"::Quote, TotalBaseAmount, TotalVATAmount, PriceIncludingVAT);
    end;

    local procedure CreateSalesOrderWithTwoVATSetupLines(var VATPostingSetup: array[2] of Record "VAT Posting Setup"; var SalesHeader: Record "Sales Header"; var TotalBaseAmount: Decimal; var TotalVATAmount: Decimal; PriceIncludingVAT: Boolean)
    begin
        CreateSalesDocWithTwoVATSetupLines(
          VATPostingSetup, SalesHeader, SalesHeader."Document Type"::Order, TotalBaseAmount, TotalVATAmount, PriceIncludingVAT);
    end;

    local procedure CreateSalesDocWithTwoVATSetupLines(var VATPostingSetup: array[2] of Record "VAT Posting Setup"; var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; var TotalBaseAmount: Decimal; var TotalVATAmount: Decimal; PriceIncludingVAT: Boolean)
    var
        GLAccount: Record "G/L Account";
        SalesLine: Record "Sales Line";
        i: Integer;
    begin
        CreateTwoVATPostingSetups(VATPostingSetup);
        LibrarySales.CreateSalesHeader(
          SalesHeader, DocumentType,
          LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup[1]."VAT Bus. Posting Group"));
        SalesHeader.Validate("Prices Including VAT", PriceIncludingVAT);
        SalesHeader.Modify(true);

        for i := 1 to ArrayLen(VATPostingSetup) do begin
            LibrarySales.CreateSalesLine(
              SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
              LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup[i], GLAccount."Gen. Posting Type"::Sale), 1);
            SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
            SalesLine.Modify(true);
            TotalBaseAmount += SalesLine.Amount;
            TotalVATAmount += SalesLine."Amount Including VAT" - SalesLine.Amount;
        end;
    end;

    local procedure CreateSalesDocWithItemAndVATSetup(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        Item: Record Item;
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 30));
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryInventory.CreateItemWithPostingSetup(
          Item, GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");

        CreateSalesDocument(
          SalesHeader, SalesLine, DocumentType,
          LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"),
          SalesLine.Type::Item, Item."No.");
        ModifySalesLineUnitPrice(SalesLine, LibraryRandom.RandDecInRange(1000, 2000, 2));
    end;

    local procedure CreateCustomerWithCreditLimitAndOverdue(var Customer: Record Customer)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        GLAccountNo: Code[20];
        CreditLimit: Decimal;
    begin
        CreditLimit := LibraryRandom.RandDecInRange(1000, 2000, 2);
        CreateCustomerAndGLAccountWithVATSetup(CustomerNo, GLAccountNo);
        ModifyCreditLimitLCY(CustomerNo, CreditLimit);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo, 1);
        ModifySalesLineUnitPrice(SalesLine, CreditLimit + LibraryERM.GetAmountRoundingPrecision());
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        LibraryVariableStorage.Enqueue(CustomerNo);
        LibraryVariableStorage.Enqueue(CustomerNo);
        LibraryVariableStorage.Enqueue(CustomerNo);
        LibraryVariableStorage.Enqueue(CustomerNo);
        LibraryVariableStorage.Enqueue(CreditLimit);
        Customer.Get(CustomerNo);
    end;

    local procedure CreditLimitSalesDocLineUnitPriceIncrease(DocumentType: Enum "Sales Document Type"; var NewUnitPrice: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLAccountNo: Code[20];
        CustomerNo: Code[20];
        UnitPrice: Decimal;
        LineAmount: array[4] of Decimal;
        CreditLimit: Decimal;
    begin
        CreateCustomerAndGLAccountWithVATSetup(CustomerNo, GLAccountNo);

        // Create Post Sales Document to get Customer's Balance
        CreateSalesDocument(SalesHeader, SalesLine, DocumentType, CustomerNo, SalesLine.Type::"G/L Account", GLAccountNo);
        ModifySalesLineUnitPrice(SalesLine, LibraryRandom.RandDecInRange(100, 200, 2));
        LineAmount[1] := SalesLine."Amount Including VAT";
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Create Sales Document to get "other" Outstanding
        CreateSalesDocument(SalesHeader, SalesLine, DocumentType, CustomerNo, SalesLine.Type::"G/L Account", GLAccountNo);
        ModifySalesLineUnitPrice(SalesLine, LibraryRandom.RandDecInRange(100, 200, 2));
        LineAmount[2] := SalesLine."Amount Including VAT";

        // Create new Sales Document to get "current" old/new Outstanding
        CreateSalesDocument(SalesHeader, SalesLine, DocumentType, CustomerNo, SalesLine.Type::"G/L Account", GLAccountNo);
        ModifySalesLineUnitPrice(SalesLine, LibraryRandom.RandDecInRange(100, 200, 2));
        LineAmount[3] := SalesLine."Amount Including VAT";
        UnitPrice := SalesLine."Unit Price";

        ModifySalesLineUnitPrice(SalesLine, UnitPrice * 2);
        LineAmount[4] := SalesLine."Amount Including VAT";
        NewUnitPrice := SalesLine."Unit Price";

        ModifySalesLineUnitPrice(SalesLine, UnitPrice);

        CreditLimit := Round(LineAmount[1] + LineAmount[2] + LineAmount[4] - 0.01);
        ModifyCreditLimitLCY(CustomerNo, CreditLimit);

        LibraryVariableStorage.Enqueue(CustomerNo);
        LibraryVariableStorage.Enqueue(CustomerNo);
        LibraryVariableStorage.Enqueue(LineAmount[2] + LineAmount[4]);
        LibraryVariableStorage.Enqueue(LineAmount[4]);
        LibraryVariableStorage.Enqueue(LineAmount[1] + LineAmount[2] + LineAmount[4]);
        LibraryVariableStorage.Enqueue(CreditLimit);

        exit(SalesHeader."No.");
    end;

    local procedure CreditLimitSalesDocLineUnitPriceDecrease(DocumentType: Enum "Sales Document Type"; var NewUnitPrice: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLAccountNo: Code[20];
        CustomerNo: Code[20];
        UnitPrice: Decimal;
        LineAmount: array[4] of Decimal;
        CreditLimit: Decimal;
    begin
        CreateCustomerAndGLAccountWithVATSetup(CustomerNo, GLAccountNo);

        // Create Post Sales Document to get Customer's Balance
        CreateSalesDocument(SalesHeader, SalesLine, DocumentType, CustomerNo, SalesLine.Type::"G/L Account", GLAccountNo);
        ModifySalesLineUnitPrice(SalesLine, LibraryRandom.RandDecInRange(100, 200, 2));
        LineAmount[1] := SalesLine."Amount Including VAT";
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Create Sales Document to get "other" Outstanding
        CreateSalesDocument(SalesHeader, SalesLine, DocumentType, CustomerNo, SalesLine.Type::"G/L Account", GLAccountNo);
        ModifySalesLineUnitPrice(SalesLine, LibraryRandom.RandDecInRange(100, 200, 2));
        LineAmount[2] := SalesLine."Amount Including VAT";

        // Create new Sales Document to get "current" old/new Outstanding
        CreateSalesDocument(SalesHeader, SalesLine, DocumentType, CustomerNo, SalesLine.Type::"G/L Account", GLAccountNo);
        ModifySalesLineUnitPrice(SalesLine, LibraryRandom.RandDecInRange(100, 200, 2));
        LineAmount[3] := SalesLine."Amount Including VAT";
        UnitPrice := SalesLine."Unit Price";

        ModifySalesLineUnitPrice(SalesLine, UnitPrice / 2);
        LineAmount[4] := SalesLine."Amount Including VAT";
        NewUnitPrice := SalesLine."Unit Price";

        ModifySalesLineUnitPrice(SalesLine, UnitPrice);

        CreditLimit := Round(LineAmount[1] + LineAmount[2] + LineAmount[4] - 0.01);
        ModifyCreditLimitLCY(CustomerNo, CreditLimit);

        LibraryVariableStorage.Enqueue(CustomerNo);
        LibraryVariableStorage.Enqueue(CustomerNo);
        LibraryVariableStorage.Enqueue(LineAmount[2] + LineAmount[4]);
        LibraryVariableStorage.Enqueue(LineAmount[4]);
        LibraryVariableStorage.Enqueue(LineAmount[1] + LineAmount[2] + LineAmount[4]);
        LibraryVariableStorage.Enqueue(CreditLimit);

        exit(SalesHeader."No.");
    end;

    local procedure CreateAndAssignItemTrackingOnItemJournal() ItemNo: Code[20]
    var
        ItemJournalLine: Record "Item Journal Line";
        LibraryUtility: Codeunit "Library - Utility";
        ItemJournal: TestPage "Item Journal";
    begin
        CreateItemJournalLine(ItemJournalLine, CreateItemWithItemTrackingCode());
        ItemNo := ItemJournalLine."Item No.";
        Commit();
        ItemJournal.OpenEdit();
        ItemJournal.CurrentJnlBatchName.SetValue(ItemJournalLine."Journal Batch Name");
        LibraryVariableStorage.Enqueue(true); // TRUE to handle Item Tracking Lines Page for Assigning Serial No.
        ItemJournal.ItemTrackingLines.Invoke(); // Item Tracking Lines is handled in ItemTrackingPageHandler.
        ItemJournal.Post.Invoke();
        LibraryUtility.GenerateGUID();  // Hack to fix New General Batch Creation issue with Generate GUID.
    end;

    local procedure CreateAndAssignItemTrackingOnSalesOrder(CustomerNo: Code[20]; ItemNo: Code[20]) No: Code[20]
    var
        SalesOrder: TestPage "Sales Order";
    begin
        No := CreateSalesOrderWithPage(CustomerNo, ItemNo);
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", No);
        LibraryVariableStorage.Enqueue(false); // FALSE to handle Item Tracking Lines Page for Selecting Entries.
        SalesOrder.SalesLines.ItemTrackingLines.Invoke();
    end;

    local procedure CreateAndPostSalesInvoice(SalesHeader: Record "Sales Header") DocumentNo: Code[20]
    var
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Post Sales Order as Ship, create Sales Invoice using Get Shipment Line and post it.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader."Document Type"::Invoice, SalesHeader."Sell-to Customer No.");
        SalesLine.Validate("Document Type", SalesHeader2."Document Type");
        SalesLine.Validate("Document No.", SalesHeader2."No.");
        LibrarySales.GetShipmentLines(SalesLine);
        DocumentNo := GetPostedDocumentNo(SalesHeader2."Posting No. Series");
        LibrarySales.PostSalesDocument(SalesHeader2, false, true);
    end;

    local procedure CreateCustomerCard(var Customer: Record Customer)
    var
        ConfigTemplateHeader: Record "Config. Template Header";
        CustomerCard: TestPage "Customer Card";
    begin
        LibrarySmallBusiness.CreateCustomerTemplate(ConfigTemplateHeader);
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(ConfigTemplateHeader.Code);
        LibraryVariableStorage.Enqueue(false);

        CustomerCard.OpenNew();
        Customer.Rename(CustomerCard."No.".Value);
        CustomerCard."Gen. Bus. Posting Group".SetValue(Customer."Gen. Bus. Posting Group");
        CustomerCard."VAT Bus. Posting Group".SetValue(Customer."VAT Bus. Posting Group");
        CustomerCard."Customer Posting Group".SetValue(Customer."Customer Posting Group");
        CustomerCard.OK().Invoke();
    end;

    local procedure CreateCustomerInvDiscount(MinimumAmount: Decimal): Code[20]
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, Customer."No.", '', MinimumAmount);
        CustInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(10, 2));  // Take Random Discount.
        CustInvoiceDisc.Modify(true);
        exit(CustInvoiceDisc.Code);
    end;

    local procedure CreateCustWithPaymentMethod(PaymentMethodCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Method Code", PaymentMethodCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithPaymentTermsCode(PaymentTermsCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Get(CreateCustomer());
        Customer.Validate("Payment Terms Code", PaymentTermsCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithDimension(): Code[20]
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        Customer: Record Customer;
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionCustomer(
          DefaultDimension, Customer."No.", DimensionValue."Dimension Code", DimensionValue.Code);

        // Storing Dimension Code and Dimension Value Code in Global Variables to use it in Page Handler.
        LibraryVariableStorage.Enqueue(DefaultDimension."Dimension Code");
        LibraryVariableStorage.Enqueue(DefaultDimension."Dimension Value Code");
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithCreditLimit(CreditLimitAmt: Decimal): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Credit Limit (LCY)", CreditLimitAmt);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithBillToCustomer(var Customer: Record Customer; var CustomerBillTo: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Name := LibraryUtility.GenerateGUID();
        Customer.Modify();
        LibrarySales.CreateCustomer(CustomerBillTo);
        CustomerBillTo.Name := LibraryUtility.GenerateGUID();
        CustomerBillTo.Modify();
        Customer.Validate("Bill-to Customer No.", CustomerBillTo."No.");
        Customer.Modify(true);
    end;

    local procedure CreateCustomerWithAddress(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate(Name, LibraryUtility.GenerateGUID());
        Customer.Validate(Address, LibraryUtility.GenerateGUID());
        Customer.Modify(true);
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

    local procedure CreateAssembledItem(var Item: Record Item)
    begin
        LibraryAssembly.SetupAssemblyItem(
            Item, Item."Costing Method"::Standard, Item."Costing Method"::Standard, Item."Replenishment System"::Assembly,
            '', false, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5),
        LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));
        Item.Validate("Assembly Policy", Item."Assembly Policy"::"Assemble-to-Order");
        Item.Modify(true);
    end;

    local procedure CreateItemWithItemTrackingCode(): Code[20]
    var
        Item: Record Item;
        LibraryUtility: Codeunit "Library - Utility";
    begin
        Item.Get(CreateItem());
        Item.Validate("Item Tracking Code", FindItemTrackingCode());
        Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemAndExtendedText(var Item: Record Item): Text[50]
    var
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Automatic Ext. Texts", true);
        Item.Modify(true);

        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, Item."No.");
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        UpdateTextInExtendedTextLine(ExtendedTextLine, Item."No.");
        exit(ExtendedTextLine.Text);
    end;

    local procedure CreateItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        ItemJournalTemplate.SetRange(Recurring, false);
        ItemJournalTemplate.SetRange(Type, ItemJournalTemplate.Type::Item);
        LibraryInventory.FindItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
    end;

    local procedure CreateItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        CreateItemJournalBatch(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase, ItemNo,
          1);  // Take 1 as Quantity for Item Tracking.

        // Validate Document No. as combination of Journal Batch Name and Line No.
        ItemJournalLine.Validate("Document No.", ItemJournalLine."Journal Batch Name" + Format(ItemJournalLine."Line No."));
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateOrderPaymentMethod(var SalesHeader: Record "Sales Header"; PaymentMethodCode: Code[10]): Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        // Using LibraryRandom for random value in Quantity.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustWithPaymentMethod(PaymentMethodCode));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandDec(10, 2));
        exit(SalesLine."Amount Including VAT");
    end;

    local procedure CreatePostCodeWithCode(var PostCode: Record "Post Code"; "Code": Code[20])
    begin
        PostCode.Init();
        PostCode.Validate(Code, Code);
        PostCode.Validate(
          City,
          CopyStr(
            LibraryUtility.GenerateRandomCode(PostCode.FieldNo(City), DATABASE::"Post Code"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Post Code", PostCode.FieldNo(City))));
        PostCode.Insert(true);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; No: Code[20]; Quantity: Decimal; UnitPrice: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("Qty. to Invoice", SalesLine."Qty. to Invoice" / 2);  // Value necessary for test case.
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesBlankLines(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        i: Integer;
    begin
        for i := 1 to LibraryRandom.RandInt(5) do begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, "Sales Line Type"::" ", '', 0);
            SalesLine.Validate(Description, LibraryUtility.GenerateGUID());
            SalesLine.Modify(true);
        end;
    end;

    local procedure CreateSalesLineWithExtendedText(SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        TransferExtendedText: Codeunit "Transfer Extended Text";
    begin
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandDec(20, 2),
          LibraryRandom.RandDec(100, 2));
        TransferExtendedText.SalesCheckIfAnyExtText(SalesLine, true);
        TransferExtendedText.InsertSalesExtText(SalesLine);
    end;

    local procedure DeleteSalesLine(DocumentNo: Code[20]; Type: eNUM "Sales Line Type"; ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLineByType(SalesLine, DocumentNo, Type, ItemNo);
        SalesLine.Delete(true);
    end;

    local procedure CreateSalesDocumentFillUnitPrice(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; UnitPrice: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        ModifySalesLineUnitPrice(SalesLine, UnitPrice);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; SelltoCustomerNo: Code[20]; Type: Enum "Sales Line Type"; No: Code[20])
    begin
        // Create Sales Order using Random Quantity for Sales Line.
        Clear(SalesHeader);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, SelltoCustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, LibraryRandom.RandDec(10, 2));  // Using Random Number Generator for Random Quantity.
    end;

    local procedure CreateSaleHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, Customer."No.");
    end;

    local procedure CreateSalesOrderWithPage(CustomerNo: Code[20]; ItemNo: Code[20]) SalesOrderNo: Code[20]
    var
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        Customer.Get(CustomerNo);

        SalesOrder.OpenNew();
        SalesOrder."No.".AssistEdit();  // No. Series Page  is handled in 'NoSeriesPageHandler'.
        SalesOrder."Sell-to Customer Name".SetValue(Customer.Name);
        SalesOrder.SalesLines.Type.SetValue(SalesLine.Type::Item);
        SalesOrder.SalesLines."No.".SetValue(ItemNo);
        SalesOrder.SalesLines.Quantity.SetValue(1);  // Take Quantity 1 as value is not important.
        SalesOrder.SalesLines.New();
        SalesOrderNo := SalesOrder."No.".Value();
        SalesOrder.OK().Invoke();
    end;

    local procedure CreateSalesOrderWithReceivableSetup(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        // Create Customer with Cust. Invoice Discount and create Sales Order.
        // Use Random for Minimum Amount on Cust. Invoice Discount, Quantity and Unit Price.
        UpdateSalesReceivablesSetupForCalcInvDiscount(true);
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CreateCustomerInvDiscount(200 + LibraryRandom.RandDec(100, 2)),
          SalesLine.Type::Item, CreateItem()); // Add 200 to control Minimum Amount on Cust. Invoice Discount.
        ModifySalesLineUnitPrice(SalesLine, LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateSalesOrderWithSalesCode(var SalesHeader: Record "Sales Header"; var StandardSalesLine: Record "Standard Sales Line"; ItemNo: Code[20]; ShortcutDimension1Code: Code[20]; ShortcutDimension2Code: Code[20])
    var
        StandardSalesCode: Record "Standard Sales Code";
        Customer: Record Customer;
        StandardCustomerSalesCode: Record "Standard Customer Sales Code";
    begin
        LibrarySales.CreateStandardSalesCode(StandardSalesCode);
        LibrarySales.CreateStandardSalesLine(StandardSalesLine, StandardSalesCode.Code);
        ModifyStandardSalesLine(StandardSalesLine, ItemNo, ShortcutDimension1Code, ShortcutDimension2Code);
        StandardSalesLine.Get(StandardSalesLine."Standard Sales Code", StandardSalesLine."Line No.");
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerSalesCode(StandardCustomerSalesCode, Customer."No.", StandardSalesCode.Code);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        StandardCustomerSalesCode.InsertSalesLines(SalesHeader);
    end;

    local procedure CreateSalesDocWithCrLimitCustomer(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocType: Enum "Sales Document Type")
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        CustNo: Code[20];
        CreditLimit: Decimal;
    begin
        UpdateSalesReceivablesSetup(false, SalesReceivablesSetup."Credit Warnings"::"Credit Limit");
        CreditLimit := LibraryRandom.RandDec(10, 2);
        CustNo := CreateCustomerWithCreditLimit(CreditLimit);
        CreateSalesDocWithIncreasedAmount(SalesHeader, SalesLine, DocType, CustNo, CreditLimit);
        LibraryVariableStorage.Enqueue(CustNo);
    end;

    local procedure CreateSalesDocWithIncreasedAmount(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocType: Enum "Sales Document Type"; CustNo: Code[20]; Amount: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, CustNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Unit Price", Amount + LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateShipSalesOrderWithPricesInclVATAndLineDisc(var SalesHeader: Record "Sales Header"; var VATPercent: Decimal; LineDiscAmt: Decimal; PricesInclVAT: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Prices Including VAT", PricesInclVAT);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item,
          LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(100, 1000));
        VATPercent := SalesLine."VAT %";
        SalesLine.Validate("Line Discount Amount", LineDiscAmt);
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    local procedure CreateSalesInvWithPricesInclVAT(var SalesLine: Record "Sales Line"; CustNo: Code[20]; PricesInclVAT: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustNo);
        SalesHeader.Validate("Prices Including VAT", PricesInclVAT);
        SalesHeader.Modify(true);
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
    end;

    local procedure CreateSalesOrderWithOverdueCust(var SalesHeader: Record "Sales Header"; var OverdueAmount: Decimal; NormalEntryDueDate: Date; OverdueEntryDueDate: Date)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        CustNo: Code[20];
    begin
        UpdateSalesReceivablesSetup(false, SalesReceivablesSetup."Credit Warnings"::"Credit Limit");
        CustNo := CreateCustomerWithCreditLimit(LibraryRandom.RandDec(10, 2));
        MockCustLedgEntryWithDueDate(CustNo, NormalEntryDueDate);
        OverdueAmount := MockCustLedgEntryWithDueDate(CustNo, OverdueEntryDueDate);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustNo);
    end;

    local procedure CreateStandardSalesLinesWithItemForCustomer(var StandardSalesLine: Record "Standard Sales Line"; var StandardCustomerSalesCode: Record "Standard Customer Sales Code")
    var
        StandardSalesCode: Record "Standard Sales Code";
        Customer: Record Customer;
    begin
        LibrarySales.CreateStandardSalesCode(StandardSalesCode);

        LibrarySales.CreateStandardSalesLine(StandardSalesLine, StandardSalesCode.Code);
        StandardSalesLine.Type := StandardSalesLine.Type::Item;
        StandardSalesLine.Quantity := LibraryRandom.RandInt(10);
        StandardSalesLine."No." := CreateItem();
        StandardSalesLine.Modify();

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerSalesCode(StandardCustomerSalesCode, Customer."No.", StandardSalesCode.Code);
    end;

    local procedure CreateSalesPriceWithUnitPrice(var SalesPrice: Record "Sales Price"; CustomerNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; UnitPriceAmount: Decimal)
    begin
        LibraryCosting.CreateSalesPrice(SalesPrice, SalesPrice."Sales Type"::Customer, CustomerNo, ItemNo, WorkDate(), '', '', '', Quantity);
        SalesPrice.Validate("Unit Price", UnitPriceAmount);
        SalesPrice.Modify(true);
    end;

    local procedure CreateSalesPriceWithDiscounts(var SalesPrice: Record "Sales Price"; AllowInvoiceDisc: Boolean; AllowLineDisc: Boolean)
    begin
        CreateSalesPriceWithUnitPrice(
          SalesPrice, LibrarySales.CreateCustomerNo(), LibraryInventory.CreateItemNo(),
          LibraryRandom.RandDecInRange(10, 20, 2), LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesPrice.Validate("Allow Invoice Disc.", AllowInvoiceDisc);
        SalesPrice.Validate("Allow Line Disc.", AllowLineDisc);
        SalesPrice.Modify(true);
    end;

    local procedure CreateAndModifySalesOrder(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomerInvDiscount(0));
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10) * 2, LibraryRandom.RandDec(10, 2) +
          100);
    end;

    local procedure CreateTempCustomer(var TempCustomer: Record Customer temporary)
    var
        GenBusinessPostingGroup: Record "Gen. Business Posting Group";
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryERM.FindGenBusinessPostingGroup(GenBusinessPostingGroup);
        LibraryERM.FindVATBusinessPostingGroup(VATBusinessPostingGroup);
        TempCustomer.Init();
        TempCustomer.Validate("No.", GenerateCustomerNo());
        TempCustomer.Insert();
        TempCustomer.Validate("Gen. Bus. Posting Group", GenBusinessPostingGroup.Code);
        TempCustomer.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
        TempCustomer.Validate("Customer Posting Group", LibrarySales.FindCustomerPostingGroup());
        TempCustomer.Modify(true);
    end;

    local procedure CreateTwoPostCodesWithEqualCodes(var PostCode: Record "Post Code")
    begin
        LibraryERM.CreatePostCode(PostCode);
        CreatePostCodeWithCode(PostCode, PostCode.Code);
        PostCode.SetRange(Code, PostCode.Code);
        PostCode.FindLast();
    end;

    local procedure CreateSalesLineDiscount(var SalesLineDiscount: Record "Sales Line Discount"; SalesPrice: Record "Sales Price")
    begin
        LibraryERM.CreateLineDiscForCustomer(
          SalesLineDiscount, SalesLineDiscount.Type::Item, SalesPrice."Item No.", SalesLineDiscount."Sales Type"::"All Customers", '',
          WorkDate(), '', '', SalesPrice."Unit of Measure Code", SalesPrice."Minimum Quantity" * 2);
        SalesLineDiscount.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));  // Using Random Number Generator for Random Line Discount.
        SalesLineDiscount.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesLine: Record "Sales Line"; SalesPrice: Record "Sales Price")
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, SalesPrice."Item No.", SalesPrice."Minimum Quantity" / 2);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, SalesPrice."Item No.", SalesPrice."Minimum Quantity");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, SalesPrice."Item No.", SalesPrice."Minimum Quantity" * 2);
    end;

    local procedure CreateSalesPrice(var SalesPrice: Record "Sales Price")
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryCosting.CreateSalesPrice(
          SalesPrice, SalesPrice."Sales Type"::"All Customers", '', Item."No.", WorkDate(), '', '', Item."Base Unit of Measure",
          LibraryRandom.RandDec(50, 2));
        SalesPrice.Validate("Unit Price", LibraryRandom.RandDec(10, 2));  // Using Random Number Generator for Random Unit Price.
        SalesPrice.Modify(true);
    end;

    local procedure CreateSalesPriceWithMinimumQuantity(var SalesPrice: Record "Sales Price"; MinQty: Decimal)
    begin
        SalesPrice.Init();
        SalesPrice.Validate("Sales Type", SalesPrice."Sales Type"::"All Customers");
        SalesPrice.Validate("Item No.", LibraryInventory.CreateItemNo());
        SalesPrice.Validate("Minimum Quantity", MinQty);
        SalesPrice.Insert(true);
    end;

    local procedure CreateSalesPriceWithStartingDate(var SalesPrice: Record "Sales Price"; SalesType: Enum "Sales Price Type"; ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; StartingDate: Date)
    begin
        SalesPrice.Init();
        SalesPrice.Validate("Sales Type", SalesType);
        SalesPrice.Validate("Item No.", ItemNo);
        SalesPrice.Validate("Unit of Measure Code", UnitOfMeasureCode);
        SalesPrice.Validate("Starting Date", StartingDate);
        SalesPrice.Insert(true);
    end;

    local procedure CreateSalesPriceWithoutStartingDate(var SalesPrice: Record "Sales Price"; SalesType: Enum "Sales Price Type"; ItemNo: Code[20]; UnitOfMeasureCode: Code[10])
    begin
        SalesPrice.Init();
        SalesPrice.Validate("Sales Type", SalesType);
        SalesPrice.Validate("Item No.", ItemNo);
        SalesPrice.Validate("Unit of Measure Code", UnitOfMeasureCode);
        SalesPrice.Insert(true);
    end;

    local procedure CreateTwoSalesPrices(var SalesPrice1: Record "Sales Price"; var SalesPrice2: Record "Sales Price")
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        CreateSalesPriceWithoutStartingDate(
          SalesPrice1,
          SalesPrice1."Sales Type"::"All Customers",
          Item."No.",
          Item."Base Unit of Measure");
        CreateSalesPriceWithStartingDate(
          SalesPrice2,
          SalesPrice2."Sales Type"::"All Customers",
          Item."No.",
          Item."Base Unit of Measure",
          WorkDate());
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateBankAccountNo(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        exit(BankAccount."No.");
    end;

    local procedure CreatePaymentMethodCode(BalAccountType: Enum "Payment Balance Account Type"): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Bal. Account Type", BalAccountType);
        case BalAccountType of
            PaymentMethod."Bal. Account Type"::"G/L Account":
                PaymentMethod.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
            PaymentMethod."Bal. Account Type"::"Bank Account":
                PaymentMethod.Validate("Bal. Account No.", CreateBankAccountNo());
        end;
        PaymentMethod.Modify();
        exit(PaymentMethod.Code);
    end;

    local procedure CreateCustomerAndGLAccountWithVATSetup(var CustomerNo: Code[20]; var GLAccountNo: Code[20])
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibrarySales.CreateCustomer(Customer);
        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        if not VATPostingSetup.Get(Customer."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group") then
            LibraryERM.CreateVATPostingSetup(VATPostingSetup, Customer."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");
        CustomerNo := Customer."No.";
        GLAccountNo := GLAccount."No."
    end;

    local procedure CreateNoSeriesWithManualNos(ManualNos: Boolean): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, ManualNos, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');
        NoSeriesLine."Starting No." := LibraryUtility.GenerateGUID();
        NoSeriesLine.Modify();
        exit(NoSeries.Code);
    end;

    local procedure CreateCustomerWithTwoContacts(var Customer: Record Customer; var Contact: Record Contact; var ContactNew: Record Contact)
    var
        ContactBusinessRelation: Record "Contact Business Relation";
    begin
        LibrarySales.CreateCustomer(Customer);
        ContactBusinessRelation.SetRange("Link to Table", ContactBusinessRelation."Link to Table"::Customer);
        ContactBusinessRelation.SetRange("No.", Customer."No.");
        ContactBusinessRelation.FindFirst();
        Contact.Get(ContactBusinessRelation."Contact No.");
        Customer.Contact := Contact.Name;
        Customer.Modify();

        ContactNew := Contact;
        ContactNew.Type := ContactNew.Type::Person;
        ContactNew."No." := '';
        ContactNew.Name := LibraryUtility.GenerateGUID();
        ContactNew.Insert(true);
    end;

    local procedure MockCustLedgEntryWithDueDate(CustNo: Code[20]; DueDate: Date): Decimal
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Customer No." := CustNo;
        CustLedgerEntry."Posting Date" := DueDate;
        CustLedgerEntry."Due Date" := DueDate;
        CustLedgerEntry.Open := true;
        CustLedgerEntry.Insert();
        exit(MockDtldCustLedgEntry(CustLedgerEntry."Entry No.", CustLedgerEntry."Customer No.", CustLedgerEntry."Due Date"));
    end;

    local procedure MockDtldCustLedgEntry(CustLedgEntryNo: Integer; CustNo: Code[20]; DueDate: Date): Decimal
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Entry No." := LibraryUtility.GetNewRecNo(DetailedCustLedgEntry, DetailedCustLedgEntry.FieldNo("Entry No."));
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgEntryNo;
        DetailedCustLedgEntry."Customer No." := CustNo;
        DetailedCustLedgEntry."Posting Date" := DueDate;
        DetailedCustLedgEntry."Initial Entry Due Date" := DueDate;
        DetailedCustLedgEntry.Amount := LibraryRandom.RandDecInRange(100, 500, 2);
        DetailedCustLedgEntry."Amount (LCY)" := DetailedCustLedgEntry.Amount;
        DetailedCustLedgEntry."Ledger Entry Amount" := true;
        DetailedCustLedgEntry.Insert();
        exit(DetailedCustLedgEntry."Amount (LCY)");
    end;

    local procedure CopyPricesScenarioOnSalesPricePage(var SalesPrice: Record "Sales Price"; var CopyToCustomerNo: Code[20]; var SalesPrices: TestPage "Sales Prices")
    var
        CopyFromCustomerNo: Code[20];
    begin
        CopyToCustomerNo := LibrarySales.CreateCustomerNo();
        CopyFromCustomerNo := LibrarySales.CreateCustomerNo();
        CreateSalesPriceWithUnitPrice(
          SalesPrice, CopyFromCustomerNo, LibraryInventory.CreateItemNo(), 0, LibraryRandom.RandDec(100, 2));
        SalesPrices.OpenEdit();
        SalesPrices.SalesTypeFilter.SetValue('Customer');
        SalesPrices.SalesCodeFilterCtrl.SetValue(CopyToCustomerNo);
        LibraryVariableStorage.Enqueue(CopyFromCustomerNo);
    end;

    local procedure RunReccuringSalesIvoice(DocumentDate: Date; StandardSalesLine: Record "Standard Sales Line"): Code[20]
    var
        SalesLine: Record "Sales Line";
        StandardCustomerSalesCode: Record "Standard Customer Sales Code";
    begin
        LibraryVariableStorage.Enqueue(DocumentDate);
        LibraryVariableStorage.Enqueue(WorkDate());
        StandardCustomerSalesCode.SetRange(Code, StandardSalesLine."Standard Sales Code");
        REPORT.Run(REPORT::"Create Recurring Sales Inv.", true, false, StandardCustomerSalesCode);

        SalesLine.SetRange(Type, StandardSalesLine.Type);
        SalesLine.SetRange("No.", StandardSalesLine."No.");
        if SalesLine.FindFirst() then
            exit(SalesLine."Document No.");

        exit('');
    end;

    local procedure ArchiveSalesDocument(SalesHeader: Record "Sales Header")
    var
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        ArchiveManagement.StoreSalesDocument(SalesHeader, false);
    end;

    local procedure ApplyInvDiscBasedOnAmt(var SalesHeader: Record "Sales Header"; InvDiscountAmount: Decimal)
    var
        SalesCalcDiscountByType: Codeunit "Sales - Calc Discount By Type";
    begin
        SalesCalcDiscountByType.ApplyInvDiscBasedOnAmt(InvDiscountAmount, SalesHeader);
    end;

    local procedure DueDateOnSalesDocumentAfterCopyDocument(SalesHeaderDocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PaymentTerms: Record "Payment Terms";
        SalesInvoiceNo: Code[20];
    begin
        // Setup: Create and Post Sales Order and Create Sales Document.
        Initialize();
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, CreateCustomerWithPaymentTermsCode(PaymentTerms.Code),
          SalesLine.Type::Item, CreateItem());
        SalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeaderDocumentType, SalesHeader."Sell-to Customer No.");

        // Exercise: Run Copy Sales Document Report with Include Header,Recalculate Lines as True.
        SalesCopyDocument(SalesHeader2, SalesInvoiceNo, "Sales Document Type From"::"Posted Invoice", true);

        // Verify: Verify Due Date on Sale Header.
        VerifyDueDateOnSalesHeader(SalesHeader2, PaymentTerms."Due Date Calculation");
    end;

    local procedure FindBlockedCustomer(var Customer: Record Customer; CustomerNo: Code[20])
    begin
        Customer.Get(CustomerNo);
        Customer.Validate(Blocked, Customer.Blocked::Ship);
        Customer.Modify(true);
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; SalesLineNo: Code[20]; EntryType: Enum "Item Ledger Entry Type"; DocumentType: Enum "Item Ledger Document Type")
    begin
        ItemLedgerEntry.SetRange("Item No.", SalesLineNo);
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Document Type", DocumentType);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindItemTrackingCode(): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        ItemTrackingCode.SetRange("SN Specific Tracking", true);
        ItemTrackingCode.FindFirst();
        exit(ItemTrackingCode.Code);
    end;

    local procedure FindPostedSalesOrderToInvoice(OrderNo: Code[20]): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Order No.", OrderNo);
        SalesInvoiceHeader.FindFirst();
        exit(SalesInvoiceHeader."No.");
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetFilter(Type, '<>%1', SalesLine.Type::" ");
        SalesLine.FindSet();
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

    local procedure FindSalesLineByType(var SalesLine: Record "Sales Line"; DocumentNo: Code[20]; Type: Enum "Sales Line Type"; ItemNo: Code[20])
    begin
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange(Type, Type);
        SalesLine.SetRange("No.", ItemNo);
        SalesLine.FindLast();
    end;

    local procedure FindSalesHeaderArchive(var SalesHeaderArchive: Record "Sales Header Archive"; SalesHeader: Record "Sales Header")
    begin
        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        SalesHeaderArchive.FindFirst();
    end;

    local procedure GenerateCustomerNo(): Code[20]
    var
        Customer: Record Customer;
        LibraryUtility: Codeunit "Library - Utility";
    begin
        exit(CopyStr(LibraryUtility.GenerateRandomCode(Customer.FieldNo("No."), DATABASE::Customer),
            1, LibraryUtility.GetFieldLength(DATABASE::Customer, Customer.FieldNo("No."))));
    end;

    local procedure GetPostedDocumentNo(NoSeriesCode: Code[20]): Code[20]
    var
        NoSeries: Codeunit "No. Series";
    begin
        exit(NoSeries.PeekNextNo(NoSeriesCode));
    end;

    local procedure GetSalesCreditMemoHeaderNo(DocumentNo: Code[20]): Code[20]
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        SalesCrMemoHeader.SetRange("Pre-Assigned No.", DocumentNo);
        SalesCrMemoHeader.FindFirst();
        exit(SalesCrMemoHeader."No.");
    end;

    local procedure GetSalesInvoiceHeaderNo(DocumentNo: Code[20]): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Pre-Assigned No.", DocumentNo);
        SalesInvoiceHeader.FindFirst();
        exit(SalesInvoiceHeader."No.");
    end;

    local procedure GetSalesOrderHeader(var SalesHeader: Record "Sales Header"; QuoteNo: Code[20])
    begin
        SalesHeader.SetRange("Quote No.", QuoteNo);
        SalesHeader.FindFirst();
    end;

    local procedure GetSalesInvoiceHeaderNoOrder(DocumentNo: Code[20]): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Order No.", DocumentNo);
        SalesInvoiceHeader.FindFirst();
        exit(SalesInvoiceHeader."No.");
    end;

    local procedure GetSalesShipmentHeaderNo(DocumentNo: Code[20]): Code[20]
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesShipmentHeader.SetRange("Order No.", DocumentNo);
        SalesShipmentHeader.FindFirst();
        exit(SalesShipmentHeader."No.");
    end;

    local procedure GetSalesDocumentShipmentLines(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        LibrarySales.GetShipmentLines(SalesLine);
    end;

    local procedure GetReceivableAccNo(CustomerNo: Code[20]): Code[20]
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        Customer.Get(CustomerNo);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        exit(CustomerPostingGroup."Receivables Account");
    end;

    local procedure CalcTotalLineAmount(DocType: Enum "Sales Document Type"; DocNo: Code[20]): Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", DocType);
        SalesLine.SetRange("Document No.", DocNo);
        SalesLine.CalcSums("Amount Including VAT");
        exit(SalesLine."Amount Including VAT");
    end;

    local procedure MockSalesLine(var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; LineType: Enum "Sales Line Type"; No: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, LineType, No, LibraryRandom.RandInt(10));
    end;

    local procedure ModifyCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocumentNo: Code[20]; CustomerNo: Code[20])
    var
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
        DueDate: Date;
        PmtDiscountDate: Date;
        RemainingPmtDiscPossible: Decimal;
    begin
        DueDate := CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate());
        PmtDiscountDate := CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate());
        RemainingPmtDiscPossible := LibraryRandom.RandDec(10, 2);
        CustomerLedgerEntries.OpenEdit();
        CustomerLedgerEntries.FILTER.SetFilter("Document No.", DocumentNo);
        CustomerLedgerEntries.FILTER.SetFilter("Customer No.", CustomerNo);
        CustomerLedgerEntries."Due Date".SetValue(DueDate);
        CustomerLedgerEntries."Pmt. Discount Date".SetValue(PmtDiscountDate);
        CustomerLedgerEntries."Remaining Pmt. Disc. Possible".SetValue(RemainingPmtDiscPossible);
        CustomerLedgerEntries.OK().Invoke();
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
    end;

    local procedure ModifySalesLineUnitPrice(var SalesLine: Record "Sales Line"; UnitPrice: Decimal)
    begin
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure ModifyStandardSalesLine(StandardSalesLine: Record "Standard Sales Line"; ItemNo: Code[20]; ShortcutDimension1Code: Code[20]; ShortcutDimension2Code: Code[20])
    begin
        StandardSalesLine.Validate(Type, StandardSalesLine.Type::Item);
        StandardSalesLine.Validate("No.", ItemNo);
        StandardSalesLine.Validate(Quantity, LibraryRandom.RandDec(10, 2));
        StandardSalesLine.Validate("Shortcut Dimension 1 Code", ShortcutDimension1Code);
        StandardSalesLine.Validate("Shortcut Dimension 2 Code", ShortcutDimension2Code);
        StandardSalesLine.Modify(true);
    end;

    local procedure ModifyUnitPrice(var SalesHeader: Record "Sales Header"): Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindLast();
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);
        exit(SalesLine."Unit Price");
    end;

    local procedure ModifyCreditLimitLCY(CustomerNo: Code[20]; CreditLimit: Decimal)
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        Customer.Validate("Credit Limit (LCY)", CreditLimit);
        Customer.Modify(true);
    end;

    local procedure OpenAndUpdateSalesInvoicePage(var SalesInvoice: TestPage "Sales Invoice"; SalesInvoiceNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", SalesInvoiceNo);
        SalesInvoice.SalesLines.Type.SetValue(Format(SalesLine.Type::Item));
        SalesInvoice.SalesLines."No.".SetValue(ItemNo);
        SalesInvoice.SalesLines.Quantity.SetValue(Quantity);
    end;

    local procedure OpenSalesOrderPageWithNewOrder(CustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        SalesOrder: TestPage "Sales Order";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        Customer.Get(CustomerNo);
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrder."Sell-to Customer Name".SetValue(Customer.Name);
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

    local procedure OpenSalesReturnOrder(No: Code[20])
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        SalesReturnOrder.OpenView();
        SalesReturnOrder.FILTER.SetFilter("No.", No);
        SalesReturnOrder.MoveNegativeLines.Invoke();
    end;

    local procedure OpenSalesInvoicePageAndValidateUnitPrice(No: Code[20])
    var
        SalesInvoice: TestPage "Sales Invoice";
        OldValue: Decimal;
    begin
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", No);
        Evaluate(OldValue, SalesInvoice.SalesLines."Unit Price".Value);
        SalesInvoice.SalesLines."Unit Price".SetValue(0);
        SalesInvoice.SalesLines."Unit Price".SetValue(OldValue);
    end;

    local procedure OpenSalesOrderAndValidateUnitPrice(DocumentNo: Code[20]; NewUnitPrice: Decimal)
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", DocumentNo);
        SalesOrder.SalesLines."Unit Price".SetValue(NewUnitPrice);
    end;

    local procedure OpenSalesInvoiceAndValidateUnitPrice(DocumentNo: Code[20]; NewUnitPrice: Decimal)
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", DocumentNo);
        SalesInvoice.SalesLines."Unit Price".SetValue(NewUnitPrice);
    end;

    local procedure PostSalesOrder(var SalesHeader: Record "Sales Header") PostedSaleInvoiceNo: Code[20]
    begin
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        PostedSaleInvoiceNo := FindPostedSalesOrderToInvoice(SalesHeader."No.");
    end;

    local procedure SalesCopyDocument(SalesHeader: Record "Sales Header"; DocumentNo: Code[20]; DocumentType: Enum "Sales Document Type From"; ReCalculateLines: Boolean)
    var
        CopySalesDocument: Report "Copy Sales Document";
    begin
        CopySalesDocument.SetSalesHeader(SalesHeader);
        CopySalesDocument.SetParameters(DocumentType, DocumentNo, true, ReCalculateLines);
        CopySalesDocument.UseRequestPage(false);
        CopySalesDocument.Run();
    end;

    local procedure RunArchivedSalesQuoteReport(SalesHeader: Record "Sales Header")
    var
        SalesHeaderArchive: Record "Sales Header Archive";
    begin
        FindSalesHeaderArchive(SalesHeaderArchive, SalesHeader);
        REPORT.SaveAsExcel(REPORT::"Archived Sales Quote", LibraryReportValidation.GetFileName(), SalesHeaderArchive);
    end;

    local procedure RunArchivedSalesOrderReportAsXml(SalesHeader: Record "Sales Header")
    var
        SalesHeaderArchive: Record "Sales Header Archive";
    begin
        FindSalesHeaderArchive(SalesHeaderArchive, SalesHeader);
        REPORT.SaveAsXml(REPORT::"Archived Sales Order", LibraryReportDataset.GetFileName(), SalesHeaderArchive);
    end;

    local procedure RunArchivedSalesReturnOrderReport(SalesHeader: Record "Sales Header")
    var
        SalesHeaderArchive: Record "Sales Header Archive";
    begin
        FindSalesHeaderArchive(SalesHeaderArchive, SalesHeader);
        REPORT.SaveAsExcel(REPORT::"Arch. Sales Return Order", LibraryReportValidation.GetFileName(), SalesHeaderArchive);
    end;

    local procedure UpdateCustomerPostCodeAndCity(var Customer: Record Customer; PostCode: Record "Post Code")
    begin
        Customer.Validate("Post Code", PostCode.Code);
        Customer.Validate(City, PostCode.City);
        Customer.Modify(true);
    end;

    local procedure UpdateCreditLimitInCustomer(var Customer: Record Customer; CreditLimitAmount: Decimal)
    begin
        Customer.Validate("Credit Limit (LCY)", CreditLimitAmount);
        Customer.Modify(true);
    end;

    local procedure UpdateSalesReceivablesSetup(NewStockOutWarning: Boolean; CreditWarning: Option)
    var
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        DocumentNoVisibility.ClearState();
        LibrarySales.SetStockoutWarning(NewStockOutWarning);
        LibrarySales.SetCreditWarnings(CreditWarning);
    end;

    local procedure UpdateGeneralPostingSetup(CustomerNo: Code[20]; ItemNo: Code[20])
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        GeneralPostingSetup: Record "General Posting Setup";
        Item: Record Item;
    begin
        Customer.Get(CustomerNo);
        Item.Get(ItemNo);
        LibraryERM.CreateGLAccount(GLAccount);
        GeneralPostingSetup.Get(Customer."Gen. Bus. Posting Group", Item."Gen. Prod. Posting Group");
        GeneralPostingSetup.Validate("COGS Account", GLAccount."No.");
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdateTextInExtendedTextLine(var ExtendedTextLine: Record "Extended Text Line"; TextLineText: Text[50])
    begin
        ExtendedTextLine.Validate(Text, TextLineText);
        ExtendedTextLine.Modify(true);
    end;

    local procedure UpdateSalesLogoPositionSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Logo Position on Documents", SalesReceivablesSetup."Logo Position on Documents"::"No Logo");
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateNoSeriesOnSalesSetup(ManualNos: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
    begin
        DocumentNoVisibility.ClearState();
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Blanket Order Nos.", CreateNoSeriesWithManualNos(ManualNos));
        SalesReceivablesSetup.Validate("Invoice Nos.", CreateNoSeriesWithManualNos(ManualNos));
        SalesReceivablesSetup.Validate("Order Nos.", CreateNoSeriesWithManualNos(ManualNos));
        SalesReceivablesSetup.Validate("Quote Nos.", CreateNoSeriesWithManualNos(ManualNos));
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateContactInfo(var Contact: Record Contact; PhoneNo: Text[30]; MobilePhoneNo: Text[30]; Email: Text[80])
    begin
        Contact.Validate("Phone No.", PhoneNo);
        Contact.Validate("Mobile Phone No.", MobilePhoneNo);
        Contact.Validate("E-Mail", Email);
        Contact.Modify(true);
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

    local procedure VerifyCustomer(Customer: Record Customer)
    var
        Customer2: Record Customer;
    begin
        Customer2.Get(Customer."No.");
        Customer2.TestField("Gen. Bus. Posting Group", Customer."Gen. Bus. Posting Group");
        Customer2.TestField("VAT Bus. Posting Group", Customer."VAT Bus. Posting Group");
        Customer2.TestField("Customer Posting Group", Customer."Customer Posting Group");
    end;

    local procedure VerifyCustomerLedgerEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.Find('+');
        CustLedgerEntry.TestField(Open, false);
        CustLedgerEntry.TestField("Remaining Amount", 0);

        CustLedgerEntry.Next();
        CustLedgerEntry.CalcFields(Amount);
        Assert.AreNearlyEqual(
          Amount, CustLedgerEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, CustLedgerEntry.FieldCaption(Amount), Amount, CustLedgerEntry.TableCaption()));
    end;

    local procedure VerifyCustLedgerEntryDisc(CustLedgerEntry: Record "Cust. Ledger Entry"; PostedSaleInvoiceNo: Code[20])
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry2.SetRange("Document No.", PostedSaleInvoiceNo);
        CustLedgerEntry2.FindFirst();
        CustLedgerEntry2.TestField("Due Date", CustLedgerEntry."Due Date");
        CustLedgerEntry2.TestField("Pmt. Discount Date", CustLedgerEntry."Pmt. Discount Date");
        CustLedgerEntry2.TestField("Remaining Pmt. Disc. Possible", CustLedgerEntry."Remaining Pmt. Disc. Possible");
    end;

    local procedure VerifyDimensionOnSalesOrder(No: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", No);
        SalesOrder.Dimensions.Invoke();  // Dimension is Handled in 'DimensionSetEntriesPageHandler'.
    end;

    local procedure VerifyItemTrackingOnPostedSalesDocument(No: Code[20])
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        PostedSalesInvoice.OpenView();
        PostedSalesInvoice.FILTER.SetFilter("No.", No);
        PostedSalesInvoice.SalesInvLines.ItemTrackingEntries.Invoke();  // PostedItemTrackingLines Page is handled in PostedItemTrackingLinesPageHadler.
    end;

    local procedure VerifyNavigateEntry(ExtDocNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        Navigate: TestPage Navigate;
    begin
        Navigate.OpenEdit();
        Navigate.ContactType.SetValue(Format(Navigate.ContactType.GetOption(3)));  // Take 3 as index for Customer option.
        Navigate.ContactNo.SetValue(ExtDocNo);
        Navigate.ExtDocNo.SetValue(ExtDocNo);
        Navigate.Find.Invoke();

        SalesInvoiceHeader.SetRange("External Document No.", ExtDocNo);
        Navigate.FILTER.SetFilter("Table ID", Format(DATABASE::"Sales Invoice Header"));
        Navigate."No. of Records".AssertEquals(SalesInvoiceHeader.Count);
        Navigate.Next();

        SalesShipmentHeader.SetRange("External Document No.", ExtDocNo);
        Navigate.FILTER.SetFilter("Table ID", Format(DATABASE::"Sales Shipment Header"));
        Navigate."No. of Records".AssertEquals(SalesShipmentHeader.Count);
        Navigate.Next();

        ReturnReceiptHeader.SetRange("External Document No.", ExtDocNo);
        Navigate.FILTER.SetFilter("Table ID", Format(DATABASE::"Return Receipt Header"));
        Navigate."No. of Records".AssertEquals(ReturnReceiptHeader.Count);
        Navigate.Next();

        SalesCrMemoHeader.SetRange("External Document No.", ExtDocNo);
        Navigate.FILTER.SetFilter("Table ID", Format(DATABASE::"Sales Cr.Memo Header"));
        Navigate."No. of Records".AssertEquals(SalesCrMemoHeader.Count);
    end;

    local procedure VerifySalesInvoice(DocumentNo: Code[20]; SalesLine: Record "Sales Line")
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceHeader.TestField("Sell-to Customer No.", SalesLine."Sell-to Customer No.");
        SalesInvoiceLine.SetRange("Document No.", DocumentNo);
        SalesInvoiceLine.FindFirst();
        SalesInvoiceLine.TestField(Type, SalesLine.Type);
        SalesInvoiceLine.TestField("No.", SalesLine."No.");
        SalesInvoiceLine.TestField(Quantity, SalesLine.Quantity);
        SalesInvoiceLine.TestField(Amount, SalesLine.Amount);
        SalesInvoiceLine.TestField("Unit Price", SalesLine."Unit Price");
    end;

    local procedure VerifySalesShipment(SalesLine: Record "Sales Line"; DocumentNo: Code[20])
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentHeader.Get(DocumentNo);
        SalesShipmentHeader.TestField("Sell-to Customer No.", SalesLine."Sell-to Customer No.");
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        SalesShipmentLine.FindFirst();
        SalesShipmentLine.TestField(Type, SalesLine.Type);
        SalesShipmentLine.TestField("No.", SalesLine."No.");
        SalesShipmentLine.TestField(Quantity, SalesLine.Quantity);
    end;

    local procedure VerifySalesOrder(SalesHeaderNo: Code[20]; BillToCustomerNo: Code[20]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
    begin
        // Verify 1: Verify Bill To Customer No in Sales Header.
        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesHeaderNo);
        SalesHeader.TestField("Bill-to Customer No.", BillToCustomerNo);

        // Verify 2: Verify Bill To Customer No in Sales Line.
        FindSalesLine(SalesLine, SalesLine."Document Type"::Order, SalesHeaderNo);
        SalesLine.TestField("Bill-to Customer No.", BillToCustomerNo);
        SalesLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifySalesCreditMemo(DocumentNo: Code[20]; SalesLine: Record "Sales Line")
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoHeader.Get(DocumentNo);
        SalesCrMemoHeader.TestField("Sell-to Customer No.", SalesLine."Sell-to Customer No.");
        SalesCrMemoLine.SetRange("Document No.", DocumentNo);
        SalesCrMemoLine.FindFirst();
        SalesCrMemoLine.TestField(Type, SalesLine.Type);
        SalesCrMemoLine.TestField("No.", SalesLine."No.");
        SalesCrMemoLine.TestField(Quantity, SalesLine.Quantity);
        SalesCrMemoLine.TestField(Amount, SalesLine.Amount);
        SalesCrMemoLine.TestField("Unit Price", SalesLine."Unit Price");
    end;

    local procedure VerifySalesBlankLinesOnCopiedDocument(DocumentNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange("No.", '');
        if SalesLine.FindSet() then
            repeat
                Assert.AreEqual('', SalesLine."Sell-to Customer No.", BlankSellToCustomerFieldErr);
            until SalesLine.Next() = 0;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesCodePageHandler(var StandardCustomerSalesCodes: TestPage "Standard Customer Sales Codes")
    begin
        StandardCustomerSalesCodes.OK().Invoke();
    end;

    local procedure UpdateSalesReceivablesSetupForCalcInvDiscount(CalcInvDiscount: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Calc. Inv. Discount", CalcInvDiscount);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure VerifySalesLine(StandardSalesLine: Record "Standard Sales Line"; DocumentNo: Code[20]; ShortcutDimension1Code: Code[20]; ShortcutDimension2Code: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.FindFirst();
        SalesLine.TestField(Type, StandardSalesLine.Type);
        SalesLine.TestField("No.", StandardSalesLine."No.");
        SalesLine.TestField(Quantity, StandardSalesLine.Quantity);
        SalesLine.TestField("Shortcut Dimension 1 Code", ShortcutDimension1Code);
        SalesLine.TestField("Shortcut Dimension 2 Code", ShortcutDimension2Code);
    end;

    local procedure VerifySalesInvoiceAndShipmentHeader(SalesHeaderNo: Code[20])
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesInvoiceHeader.SetRange("Order No.", SalesHeaderNo);
        Assert.IsFalse(SalesInvoiceHeader.FindFirst(), StrSubstNo(SalesDocumentFoundErr, SalesInvoiceHeader.TableCaption(), SalesHeaderNo));
        SalesShipmentHeader.SetRange("Order No.", SalesHeaderNo);
        Assert.IsFalse(SalesShipmentHeader.FindFirst(), StrSubstNo(SalesDocumentFoundErr, SalesShipmentHeader.TableCaption(), SalesHeaderNo));
    end;

    local procedure VerifyCopySalesLine(PostedDocumentNo: Code[20]; DocumentNo: Code[20])
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        SalesLine: Record "Sales Line";
    begin
        SalesInvoiceLine.SetRange("Document No.", PostedDocumentNo);
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);
        SalesInvoiceLine.FindFirst();

        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Invoice);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst();

        SalesLine.TestField("No.", SalesInvoiceLine."No.");
        SalesLine.TestField(Quantity, SalesInvoiceLine.Quantity);
        SalesLine.TestField("Unit Price", SalesInvoiceLine."Unit Price");
    end;

    local procedure VerifyUnitPriceAndLineDiscountOnSalesLine(SalesLine: Record "Sales Line"; Quantity: Decimal; UnitPrice: Decimal; LineDiscountPercentage: Decimal)
    var
        SalesLine2: Record "Sales Line";
    begin
        SalesLine2.SetRange("Document Type", SalesLine."Document Type");
        SalesLine2.SetRange("Document No.", SalesLine."Document No.");
        SalesLine2.SetRange("No.", SalesLine."No.");
        SalesLine2.SetRange(Quantity, Quantity);
        SalesLine2.FindFirst();
        SalesLine2.TestField("Unit Price", UnitPrice);
        SalesLine2.TestField("Line Discount %", LineDiscountPercentage);
    end;

    local procedure VerifyVATEntry(DocumentNo: Code[20]; Amount: Decimal)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.FindFirst();
        Assert.AreEqual(-Amount, VATEntry.Base, StrSubstNo(AmountErr, VATEntry.FieldCaption(Base), Amount, VATEntry.TableCaption()));
    end;

    local procedure VerifyDueDateOnSalesHeader(SalesHeader: Record "Sales Header"; DueDateCalculation: DateFormula)
    var
        SalesHeader2: Record "Sales Header";
    begin
        SalesHeader2.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeader2.SetRange("No.", SalesHeader."No.");
        SalesHeader2.FindFirst();
        SalesHeader2.TestField("Due Date", CalcDate(DueDateCalculation, SalesHeader."Document Date"));
    end;

    local procedure VerifyLineDiscAmountInLine(DocNo: Code[20]; ExpectedLineDiscAmt: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, SalesLine."Document Type"::Invoice, DocNo);
        Assert.AreEqual(
          ExpectedLineDiscAmt, SalesLine."Line Discount Amount",
          StrSubstNo(AmountErr, SalesLine.FieldCaption("Line Discount Amount"), SalesLine."Line Discount Amount",
            SalesLine.TableCaption()));
    end;

    local procedure VerifyArchiveDocExcelTotalVATBaseAmount(ColumnName: Text; RowNo: Integer; TotalVATAmount: Decimal; TotalBaseAmount: Decimal)
    begin
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValueByRef(ColumnName, RowNo, 1, LibraryReportValidation.FormatDecimalValue(TotalVATAmount));
        LibraryReportValidation.VerifyCellValueByRef(ColumnName, RowNo + 1, 1, LibraryReportValidation.FormatDecimalValue(TotalBaseAmount));
    end;

    local procedure VerifyArchiveDocExcelTotalsWithDiscount(ColumnName: Text; RowNo: Integer; Amount: Decimal; InvDicountAmount: Decimal; ExclVATAmount: Decimal; VATAmount: Decimal; InclVATAmount: Decimal)
    begin
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValueByRef(ColumnName, RowNo, 1, LibraryReportValidation.FormatDecimalValue(Amount));
        LibraryReportValidation.VerifyCellValueByRef(
          ColumnName, RowNo + 1, 1, LibraryReportValidation.FormatDecimalValue(-InvDicountAmount));
        LibraryReportValidation.VerifyCellValueByRef(ColumnName, RowNo + 2, 1, LibraryReportValidation.FormatDecimalValue(ExclVATAmount));
        LibraryReportValidation.VerifyCellValueByRef(ColumnName, RowNo + 3, 1, LibraryReportValidation.FormatDecimalValue(VATAmount));
        LibraryReportValidation.VerifyCellValueByRef(ColumnName, RowNo + 4, 1, LibraryReportValidation.FormatDecimalValue(InclVATAmount));
    end;

    local procedure VerifyArchiveRetOrderExcelTotalsWithDiscount(ColumnName: Text; RowNo: Integer; Amount: Decimal; InvDicountAmount: Decimal; ExclVATAmount: Decimal; VATAmount: Decimal; InclVATAmount: Decimal)
    begin
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValueByRef(ColumnName, RowNo, 1, LibraryReportValidation.FormatDecimalValue(Amount));
        LibraryReportValidation.VerifyCellValueByRef(
          ColumnName, RowNo + 1, 1, LibraryReportValidation.FormatDecimalValue(-InvDicountAmount));
        LibraryReportValidation.VerifyCellValueByRef(ColumnName, RowNo + 2, 1, LibraryReportValidation.FormatDecimalValue(ExclVATAmount));
        LibraryReportValidation.VerifyCellValueByRef(ColumnName, RowNo + 3, 1, LibraryReportValidation.FormatDecimalValue(ExclVATAmount));
        LibraryReportValidation.VerifyCellValueByRef(ColumnName, RowNo + 4, 1, LibraryReportValidation.FormatDecimalValue(VATAmount));
        LibraryReportValidation.VerifyCellValueByRef(ColumnName, RowNo + 5, 1, LibraryReportValidation.FormatDecimalValue(InclVATAmount));
    end;

    local procedure VerifySalesDocumentExists(CustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        Assert.RecordIsNotEmpty(SalesHeader);
    end;

    local procedure VerifySalesDocumentDoesNotExist(CustomerNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.SetRange("Sell-to Customer No.", CustomerNo);
        Assert.RecordIsEmpty(SalesHeader);
    end;

    local procedure VerifyCopiedSalesPrice(CopiedFromSalesPrice: Record "Sales Price"; CustNo: Code[20])
    var
        SalesPrice: Record "Sales Price";
    begin
        SalesPrice := CopiedFromSalesPrice;
        SalesPrice."Sales Type" := SalesPrice."Sales Type"::Customer;
        SalesPrice."Sales Code" := CustNo;
        SalesPrice.Find();
        SalesPrice.TestField("Unit Price", CopiedFromSalesPrice."Unit Price");
    end;

    local procedure VerifyUnchangedSalesPrice(SalesPrice: Record "Sales Price")
    begin
        SalesPrice.Find(); // test that existing price remains unchanged
        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::Customer);
        SalesPrice.SetRange("Sales Code", SalesPrice."Sales Code");
        Assert.RecordCount(SalesPrice, 1);
    end;

    local procedure VerifyAmountInclVATOfCreditLimitDetails(ExpectedAmount: Decimal)
    begin
        Assert.AreEqual(
          ExpectedAmount, LibraryVariableStorage.DequeueDecimal(),
          'Incorrect outstanding amount on Credit Limit Details page');
        Assert.AreEqual(
          ExpectedAmount, LibraryVariableStorage.DequeueDecimal(), 'Incorrect total amount on Credit Limit Details page');

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure VerifySellToShipToContactFieldForSalesDocument(var SalesHeader: Record "Sales Header"; SellToContactNo: Code[20]; SellToContact: Text[100]; ShipToContact: Text[100])
    begin
        SalesHeader.Find();
        SalesHeader.TestField("Sell-to Contact No.", SellToContactNo);
        SalesHeader.TestField("Sell-to Contact", SellToContact);
        SalesHeader.TestField("Ship-to Contact", ShipToContact);
    end;

    local procedure VerifyShipToOptionWithContactOnSalesDocument(SalesHeader: Record "Sales Header"; Contact: Record Contact)
    var
        CustomerMgt: Codeunit "Customer Mgt.";
        ShipToOptions: Enum "Sales Ship-to Options";
        BillToOptions: Enum "Sales Bill-to Options";
    begin
        VerifySellToShipToContactFieldForSalesDocument(SalesHeader, Contact."No.", Contact.Name, Contact.Name);
        CustomerMgt.CalculateShipBillToOptions(ShipToOptions, BillToOptions, SalesHeader);
        Assert.AreEqual(Format(ShipToOptions::"Default (Sell-to Address)"), Format(ShipToOptions), '');
    end;

    local procedure VerifySalesPriceAndLineDiscBuff(var TempSalesPriceAndLineDiscBuff: Record "Sales Price and Line Disc Buff" temporary; ItemNo: Code[20]; AllowInvoiceDisc: Boolean; AllowLineDisc: Boolean)
    begin
        TempSalesPriceAndLineDiscBuff.SetRange("Sales Type", TempSalesPriceAndLineDiscBuff."Sales Type"::Customer);
        TempSalesPriceAndLineDiscBuff.SetRange(Code, ItemNo);
        TempSalesPriceAndLineDiscBuff.FindFirst();
        TempSalesPriceAndLineDiscBuff.TestField("Allow Invoice Disc.", AllowInvoiceDisc);
        TempSalesPriceAndLineDiscBuff.TestField("Allow Line Disc.", AllowLineDisc);
    end;

    local procedure GetAmountTotalIncVAT(SalesHeader: Record "Sales Header"): Decimal
    var
        TotalSalesLine: Record "Sales Line";
    begin
        TotalSalesLine.SetRange("Document Type", SalesHeader."Document Type");
        TotalSalesLine.SetRange("Document No.", SalesHeader."No.");
        TotalSalesLine.CalcSums("Line Amount", Amount, "Amount Including VAT", "Inv. Discount Amount");
        exit(TotalSalesLine."Amount Including VAT");
    end;

    local procedure CreateStandardSalesCode(var StandardSalesCode: Record "Standard Sales Code")
    begin
        StandardSalesCode.Init();
        StandardSalesCode.Code := LibraryUtility.GenerateRandomCode(StandardSalesCode.FieldNo(Code), DATABASE::"Standard Sales Code");
        StandardSalesCode.Validate(Description, LibraryUtility.GenerateRandomText(MaxStrLen(StandardSalesCode.Description)));
        StandardSalesCode.Insert();
    end;

    local procedure CreateStandardCustomerSalesCode(var StandardCustomerSalesCode: Record "Standard Customer Sales Code"; CodeStandardSalesCode: Code[10])
    var
        StandardSalesCode: Record "Standard Sales Code";
    begin
        StandardSalesCode.Get(CodeStandardSalesCode);
        StandardSalesCode.Init();
        StandardCustomerSalesCode.Code := StandardSalesCode.Code;
        StandardCustomerSalesCode.Insert(true);
    end;

    local procedure CreateStandardPurchaseCode(var StandardPurchaseCode: Record "Standard Purchase Code")
    begin
        StandardPurchaseCode.Init();
        StandardPurchaseCode.Code :=
          LibraryUtility.GenerateRandomCode(StandardPurchaseCode.FieldNo(Code), DATABASE::"Standard Purchase Code");
        StandardPurchaseCode.Validate(Description, LibraryUtility.GenerateRandomText(MaxStrLen(StandardPurchaseCode.Description)));
        StandardPurchaseCode.Insert();
    end;

    local procedure CreateStandardVendorPurchaseCode(var StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code"; CodeStandardPurchaseCode: Code[10])
    var
        StandardPurchaseCode: Record "Standard Purchase Code";
    begin
        StandardPurchaseCode.Get(CodeStandardPurchaseCode);
        StandardPurchaseCode.Init();
        StandardVendorPurchaseCode.Code := StandardPurchaseCode.Code;
        StandardVendorPurchaseCode.Insert(true);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsHandler(var SalesStatistics: TestPage "Sales Statistics")
    begin
        // Verify that fields 'VAT Amount', 'Amount Excl. VAT' and 'Total Incl. VAT' are uneditable on Sales Statistics page.
        Assert.IsFalse(SalesStatistics.VATAmount.Editable(), StrSubstNo(EditableErr, SalesStatistics.VATAmount.Caption));
        Assert.IsFalse(SalesStatistics.Amount.Editable(), StrSubstNo(EditableErr, SalesStatistics.Amount.Caption));
        Assert.IsFalse(SalesStatistics.TotalAmount2.Editable(), StrSubstNo(EditableErr, SalesStatistics.TotalAmount2.Caption));
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesStatisticsPageHandler(var SalesStatistics: TestPage "Sales Statistics")
    begin
        // Verify that fields 'VAT Amount', 'Amount Excl. VAT' and 'Total Incl. VAT' are uneditable on Sales Statistics page.
        Assert.IsFalse(SalesStatistics.VATAmount.Editable(), StrSubstNo(EditableErr, SalesStatistics.VATAmount.Caption));
        Assert.IsFalse(SalesStatistics.Amount.Editable(), StrSubstNo(EditableErr, SalesStatistics.Amount.Caption));
        Assert.IsFalse(SalesStatistics.TotalAmount2.Editable(), StrSubstNo(EditableErr, SalesStatistics.TotalAmount2.Caption));
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure SalesOptionDialogHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        // Choose the option of the string menu.
        Choice := LibraryVariableStorage.DequeueInteger();  // Choose option.
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
    procedure ConfirmHandlerCount(Question: Text[1024]; var Reply: Boolean)
    begin
        if LibraryVariableStorage.Length() > 1 then
            Reply := LibraryVariableStorage.DequeueBoolean()
        else
            Reply := false;
        LibraryVariableStorage.Enqueue(LibraryVariableStorage.DequeueInteger() + 1);
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesOrderStatistics action. The new action uses RunObject and does not run the action trigger. Use a page extension to modify the behaviour.', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    var
        InvDiscountAmountGeneral: Decimal;
        InvDiscountAmountInvoicing: Decimal;
    begin
        InvDiscountAmountInvoicing := LibraryVariableStorage.DequeueDecimal();
        InvDiscountAmountGeneral := LibraryVariableStorage.DequeueDecimal();
        Assert.AreNearlyEqual(
          InvDiscountAmountGeneral, SalesOrderStatistics.InvDiscountAmount_General.AsDecimal(), LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(InvoiceDiscountErr, SalesOrderStatistics.InvDiscountAmount_General.Caption, InvDiscountAmountGeneral));
        Assert.AreNearlyEqual(
          InvDiscountAmountInvoicing, SalesOrderStatistics.InvDiscountAmount_Invoicing.AsDecimal(), LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(InvoiceDiscountErr, SalesOrderStatistics.InvDiscountAmount_Invoicing.Caption, InvDiscountAmountInvoicing));
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsHandlerNM(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    var
        InvDiscountAmountGeneral: Decimal;
        InvDiscountAmountInvoicing: Decimal;
    begin
        InvDiscountAmountInvoicing := LibraryVariableStorage.DequeueDecimal();
        InvDiscountAmountGeneral := LibraryVariableStorage.DequeueDecimal();
        Assert.AreNearlyEqual(
          InvDiscountAmountGeneral, SalesOrderStatistics.InvDiscountAmount_General.AsDecimal(), LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(InvoiceDiscountErr, SalesOrderStatistics.InvDiscountAmount_General.Caption, InvDiscountAmountGeneral));
        Assert.AreNearlyEqual(
          InvDiscountAmountInvoicing, SalesOrderStatistics.InvDiscountAmount_Invoicing.AsDecimal(), LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(InvoiceDiscountErr, SalesOrderStatistics.InvDiscountAmount_Invoicing.Caption, InvDiscountAmountInvoicing));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetShipmentLinesHandler(var GetShipmentLines: TestPage "Get Shipment Lines")
    begin
        GetShipmentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DimensionSetEntriesPageHandler(var EditDimensionSetEntries: TestPage "Edit Dimension Set Entries")
    begin
        EditDimensionSetEntries."Dimension Code".AssertEquals(LibraryVariableStorage.DequeueText());
        EditDimensionSetEntries.DimensionValueCode.AssertEquals(LibraryVariableStorage.DequeueText());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure MoveNegativeSalesLinesHandler(var MoveNegativeSalesLines: TestRequestPage "Move Negative Sales Lines")
    begin
        // Move Negative Sales Lines Requestpage Handler.
        MoveNegativeSalesLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreatePageHandler(var EnterQuantitytoCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantitytoCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        Flag: Boolean;
    begin
        if LibraryVariableStorage.Length() = 1 then
            Flag := LibraryVariableStorage.DequeueBoolean()
        else begin
            LibraryVariableStorage.DequeueText(); // dummy dequeue
            Flag := LibraryVariableStorage.DequeueBoolean();
        end;

        if Flag then
            // Enter Quantity To Create Page is Handled in 'EnterQuantityToCreatePageHandler'.
            ItemTrackingLines."Assign Serial No.".Invoke()
        else
            ItemTrackingLines."Select Entries".Invoke();  // Item Tracking Summary Page is handled in 'ItemTrackingSummaryPageHandler'.
        LibraryVariableStorage.Enqueue(ItemTrackingLines."Serial No.".Value);
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // This Handler function is used for handling Messages.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NoSeriesPageHandler(var NoSeriesPage: TestPage "No. Series")
    begin
        NoSeriesPage.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedItemTrackingLinesPageHadler(var PostedItemTrackingLines: TestPage "Posted Item Tracking Lines")
    begin
        PostedItemTrackingLines."Serial No.".AssertEquals(LibraryVariableStorage.DequeueText());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateRecurringSalesInvHandler(var CreateRecurringSalesInv: TestRequestPage "Create Recurring Sales Inv.")
    begin
        CreateRecurringSalesInv.OrderDate.SetValue(LibraryVariableStorage.DequeueDate());
        CreateRecurringSalesInv.PostingDate.SetValue(LibraryVariableStorage.DequeueDate());
        CreateRecurringSalesInv.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TemplateSelectionPageHandler(var SelectCustomerTemplList: TestPage "Select Customer Templ. List")
    begin
        SelectCustomerTemplList.First();
        SelectCustomerTemplList.OK().Invoke();
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    var
        CustCheckCrLimit: Codeunit "Cust-Check Cr. Limit";
    begin
        if not Notification.HasData('No.') then
            exit;
        Assert.AreEqual(Notification.GetData('No.'), LibraryVariableStorage.DequeueText(), 'Customer No. was different than expected');
        CustCheckCrLimit.ShowNotificationDetails(Notification);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NotificationDetailsHandler(var CreditLimitNotification: TestPage "Credit Limit Notification")
    var
        Customer: Record Customer;
    begin
        Customer.Get(LibraryVariableStorage.DequeueText());
        Customer.CalcFields("Balance (LCY)");
        CreditLimitNotification.CreditLimitDetails."No.".AssertEquals(Customer."No.");
        CreditLimitNotification.CreditLimitDetails."Balance (LCY)".AssertEquals(Customer."Balance (LCY)");
        CreditLimitNotification.CreditLimitDetails.OverdueBalance.AssertEquals(Customer.CalcOverdueBalance());
        CreditLimitNotification.CreditLimitDetails."Credit Limit (LCY)".AssertEquals(Customer."Credit Limit (LCY)");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AmountsOnCrLimitNotificationDetailsModalPageHandler(var CreditLimitNotification: TestPage "Credit Limit Notification")
    begin
        // Enqueue amounts from handler to verify in test body
        LibraryVariableStorage.Enqueue(CreditLimitNotification.CreditLimitDetails.OutstandingAmtLCY.Value);
        LibraryVariableStorage.Enqueue(CreditLimitNotification.CreditLimitDetails.TotalAmountLCY.Value);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CheckCrLimitDrilldownOverdueAmountModalPageHandler(var CreditLimitNotification: TestPage "Credit Limit Notification")
    begin
        CreditLimitNotification.CreditLimitDetails.OverdueBalance.DrillDown();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CheckCrLimitGetOverdueAmountModalPageHandler(var CreditLimitNotification: TestPage "Credit Limit Notification")
    begin
        LibraryVariableStorage.Enqueue(CreditLimitNotification.CreditLimitDetails.OverdueBalance.Value);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CustomerLedgerEntriesVerifySingleEntryWithAmountPageHandler(var CustomerLedgerEntries: TestPage "Customer Ledger Entries")
    begin
        LibraryVariableStorage.Enqueue(CustomerLedgerEntries.Amount.Value);
        Assert.IsFalse(CustomerLedgerEntries.Next(), 'There is more than one entry in Customer Ledger Entries page');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesPricesSelectPriceOfCustomerModalPageHandler(var SalesPrices: TestPage "Sales Prices")
    begin
        SalesPrices.SalesCodeFilterCtrl.SetValue(LibraryVariableStorage.DequeueText());
        SalesPrices.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesPricesCancelPriceSelectionModalPageHandler(var SalesPrices: TestPage "Sales Prices")
    begin
        SalesPrices.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ContactListPageHandler(var ContactList: TestPage "Contact List")
    begin
        ContactList.GotoKey(LibraryVariableStorage.DequeueText());
        ContactList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerLookupPageHandler(var CustomerLookup: TestPage "Customer Lookup")
    begin
        CustomerLookup.Filter.SetFilter(Name, LibraryVariableStorage.DequeueText());
        CustomerLookup.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CustomerLookupHandler(var CustomerLookup: TestPage "Customer Lookup")
    begin
        CustomerLookup.GotoKey(LibraryVariableStorage.DequeueText());
        Assert.AreEqual(LibraryVariableStorage.DequeueText(),
            CustomerLookup.Filter.GetFilter("Date Filter"), 'Wrong Date Filter.');
        CustomerLookup.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ContactListModalPageHandler(var ContactList: TestPage "Contact List")
    begin
        ContactList.FILTER.SetFilter("Company No.", LibraryVariableStorage.DequeueText());
        ContactList.New();
    end;

    [ModalPageHandler]
    procedure ShipToAddressListModalPageHandler(var ShipToAddList: TestPage "Ship-to Address List")
    begin
        ShipToAddList.New();
    end;
}
