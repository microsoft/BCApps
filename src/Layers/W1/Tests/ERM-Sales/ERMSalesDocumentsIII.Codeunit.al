codeunit 134387 "ERM Sales Documents III"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryService: Codeunit "Library - Service";
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        LibraryResource: Codeunit "Library - Resource";
        EnvironmentInfoTestLibrary: Codeunit "Environment Info Test Library";
        CopyFromToPriceListLine: Codeunit CopyFromToPriceListLine;
        isInitialized: Boolean;
        AmountErr: Label '%1 must be %2 in %3.', Comment = '.';
        CustomerMustBeDeletedErr: Label 'Customer must be deleted.';
        NoOfRecordErr: Label 'No. of records must be 1.';
        GetRetRcptErr: Label 'You cannot get a No. Series Line with empty No. Series Code.';
        PostGreaterQtyErr: Label 'You cannot invoice more than';
        OutstdSalesOrdErr: Label 'You cannot delete Customer %1 because there is at least one outstanding Sales Return Order for this customer.', Comment = '.';
        OutstdSalesReturnErr: Label 'You cannot delete Item %1 because there is at least one outstanding Sales Return Order that includes this item.', Comment = '%1: Field(No)';
        ReturnQuantityErr: Label 'You cannot return more than %1 units.', Comment = '.';
        QtyToInvSignErr: Label 'Qty. to Invoice must have the same sign as the return receipt in Sales Line Document Type=''Credit Memo'',Document No.=''%1'',Line No.=''%2''.', Comment = '.';
        QtyInvoiceErr: Label 'The quantity that you are trying to invoice is greater than the quantity in return receipt %1.', Comment = '.';
        AdjustCostMsg: Label 'Some unadjusted value entries will not be covered with the new setting.';
        WhseShipmentIsRequiredErr: Label 'Warehouse Shipment is required for Line No.';
        WhseReceiveIsRequiredErr: Label 'Warehouse Receive is required for Line No.';
        SalesOrderArchiveRespCenterErr: Label 'Sales Order Archives displays documents for Responisbility Center that should not be shown for current user';
        InvDiscAmtInSalesInvErr: Label 'Incorrect Inv. Discount Amount in Sales Invoice Line created by Get Shipment Lines function.';
        OptionString: Option PostedReturnReceipt,PostedInvoices,PostedShipments,PostedCrMemo;
        ShipToContactMustBeEditableErr: Label 'Ship-to Contact must be editable.';
        ConfirmCreateEmptyPostedInvMsg: Label 'Deleting this document will cause a gap in the number series for posted invoices. An empty posted invoice %1 will be created', Comment = '%1 - Invoice No.';
        WrongTableErr: Label 'Table %1 is unexpected.';
        InvoiceDiscountChangedErr: Label 'Invoice Discount % must not be auto calculated for header on open page.';
        QuoteNoMustBeVisibleErr: Label 'Quote No. must be visible.';
        QuoteNoMustNotBeVisibleErr: Label 'Quote No. must not be visible.';
        ZeroQuantityInLineErr: Label 'One or more document lines with a value in the No. field do not have a quantity specified.';
        WrongReportInvokedErr: Label 'Wrong report invoked.';
        ConfirmSendPostedShipmentQst: Label 'You can take the same actions for the related Sales - Shipment document.\\Do you want to do that now?';
        LinesNotUpdatedMsg: Label 'You have changed Language Code on the sales header, but it has not been changed on the existing sales lines.';
        LinesNotUpdatedDateMsg: Label 'You have changed the %1 on the sales header, which might affect the prices and discounts on the sales lines.';
        UpdateManuallyMsg: Label 'You must update the existing sales lines manually.';
        ReviewLinesManuallyMsg: Label ' You should review the lines and manually update prices and discounts if needed.';
        AffectExchangeRateMsg: Label 'The change may affect the exchange rate that is used for price calculation on the sales lines.';
        SplitMessageTxt: Label '%1\%2', Comment = 'Some message text 1.\Some message text 2.', Locked = true;
        ConfirmZeroQuantityPostingMsg: Label 'One or more document lines with a value in the No. field do not have a quantity specified. \Do you want to continue?';
        InternetURLTxt: Label 'www.microsoft.com', Locked = true;
        HttpTxt: Label 'http://', Locked = true;
        InvalidURLErr: Label 'URL must be prefix with http.';
        PackageTrackingNoErr: Label 'Package Tracking No does not exist.';
        CannotAllowInvDiscountErr: Label 'The value of the Allow Invoice Disc. field is not valid when the VAT Calculation Type field is set to "Full VAT".';
        PostingPreviewNoTok: Label '***', Locked = true;
        ReturnQtyToReceiveMustBeZeroErr: Label ' Return Qty. to Receive must be zero.';
        QtyToAssignErr: Label '%1 must be %2 in %3', Comment = '%1 = Qty. to Assign, %2 = Quantity, %3 = Sales Return Order Subform';
        UniCostLCYErr: Label 'Unit Cost (LCY) must be zero.';
        AdjustExchRateDefaultDescTxt: Label 'Adjmt. of %1 %2, Ex.Rate Adjust.', Locked = true;
        AccountBalanceErrLbl: Label 'G/L Account %1 is not balanced', Comment = '%1 = G/L Account No';
        DateErr: Label '%1 must be %2 in %3.', Comment = '%1= Field Caption, %2= Field Value, %3=Table Caption.';

    [Test]
    [Scope('OnPrem')]
    procedure CustomerCardEditPostCode()
    var
        Customer: Record Customer;
        PostCode: Record "Post Code";
    begin
        // Verify Post Code can be edited in Customer by page.

        // Setup: Create a Customer and a Post Code.
        Initialize();
        CreateCustomerWithPostCodeAndCity(Customer);
        LibraryERM.CreatePostCode(PostCode);

        // Modify: Modify the Post Code of the Customer by page.
        Customer.Get(ModifyCustomerPostCode(Customer."No.", PostCode.Code));

        // Verify: Verify that the Post Code gets modified for the Customer.
        VerifyCustomerData(Customer, PostCode.Code, PostCode.City);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerCardEditCity()
    var
        Customer: Record Customer;
        PostCode: Record "Post Code";
    begin
        // Verify City can be edited in Customer by page.

        // Setup: Create a Customer and a Post Code.
        Initialize();
        CreateCustomerWithPostCodeAndCity(Customer);
        LibraryERM.CreatePostCode(PostCode);

        // Modify: Modify the City of the Customer by page.
        Customer.Get(ModifyCustomerCity(Customer."No.", PostCode.City));

        // Verify: Verify that the City gets modified for the Customer.
        VerifyCustomerData(Customer, PostCode.Code, PostCode.City);
    end;

    [Test]
    [HandlerFunctions('PostCodesHandler')]
    [Scope('OnPrem')]
    procedure CustomerEditPostCodeLookUp()
    var
        Customer: Record Customer;
        PostCode: Record "Post Code";
        PostCode2: Record "Post Code";
        TempCode: Code[20];
    begin
        // Verify that system ask for City options when we edit Post Code if 2 similar values for Post Code exists.

        // Setup: Create a Customer and two Post Codes.
        Initialize();
        LibrarySales.CreateCustomer(Customer);

        TempCode :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(PostCode.FieldNo(Code), DATABASE::"Post Code"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Post Code", PostCode.FieldNo(Code)) - 1);
        CreatePostCode(PostCode, TempCode + 'A');
        CreatePostCode(PostCode2, TempCode + 'B');
        LibraryVariableStorage.Enqueue(Customer.FieldNo("Post Code")); // Passing field caption to handler.
        LibraryVariableStorage.Enqueue(PostCode.Code);

        // Exercise: Edit Post Code for the Customer and handle Post Codes page using handler.
        ModifyCustomerPostCode(Customer."No.", TempCode + '*');

        // Verify: Get the new Customer created in the record and verify that the Post Code and city gets modified for the Customer.
        Customer.Get(Customer."No.");
        VerifyCustomerData(Customer, PostCode.Code, FindCity(PostCode.Code));
    end;

    [Test]
    [HandlerFunctions('PostCodesCancelHandler')]
    [Scope('OnPrem')]
    procedure CustomerEditCityWithMultiplePostCodeCancelLookUp()
    var
        Customer: Record Customer;
        PostCode: Record "Post Code";
        PostCode2: Record "Post Code";
        CustomerCard: TestPage "Customer Card";
        TempCode: Code[20];
        City: Text[30];
        PrevCity: Text[30];
    begin
        // Verify that system does not modify the City after cancelling the lookup for Post Code

        // Setup: Create a Customer and two Post Codes pointing to the same City
        Initialize();
        LibrarySales.CreateCustomer(Customer);

        TempCode :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(PostCode.FieldNo(Code), DATABASE::"Post Code"), 1,
            MaxStrLen(PostCode.Code));
        CreatePostCode(PostCode, TempCode + 'A');
        CreatePostCode(PostCode2, TempCode + 'B');
        City := 'TestCity';
        CreateCityForPostCode(PostCode, City);
        CreateCityForPostCode(PostCode2, City);

        // Exercise: Edit City for the Customer and handle Post Codes page using handler.
        CustomerCard.OpenEdit();
        CustomerCard.GotoRecord(Customer);
        PrevCity := CustomerCard.City.Value();
        // The handler cancels the lookup window and an error is triggered in order to roll-back
        CustomerCard.City.SetValue(City);
        Assert.ExpectedErrorCode('NSValidateField:Dialog');

        // Verify: After Cancelling in the Post Codes page, City should have the previous value
        Assert.AreEqual(PrevCity, CustomerCard.City.Value, 'City should be unchanged after a cancel.');
    end;

    [Test]
    [HandlerFunctions('PostCodesHandler')]
    [Scope('OnPrem')]
    procedure CustomerEditCityLookUp()
    var
        Customer: Record Customer;
        PostCode: Record "Post Code";
        PostCode2: Record "Post Code";
        TempCity: Text[30];
    begin
        // Verify that system ask for Post Code options when we edit City if 2 similar values for City exists.

        // Setup: Create a Customer and two Cities for Post Codes.
        Initialize();
        LibrarySales.CreateCustomer(Customer);

        TempCity :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(PostCode.FieldNo(City), DATABASE::"Post Code"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Post Code", PostCode.FieldNo(City)) - 1);
        CreateCityForPostCode(PostCode, TempCity + 'A');
        CreateCityForPostCode(PostCode2, TempCity + 'B');
        LibraryVariableStorage.Enqueue(Customer.FieldNo(City)); // Passing Change Post Code to handler.
        LibraryVariableStorage.Enqueue(PostCode.City);

        // Exercise: Edit Post Code for the Customer and handle Post Codes page using handler.
        ModifyCustomerCity(Customer."No.", TempCity + '*');

        // Verify: Get the new Customer created in the record and verify that the Post Code and city gets modified for the Customer.
        Customer.Get(Customer."No.");
        VerifyCustomerData(Customer, FindPostCode(PostCode.City), PostCode.City);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerDelete()
    var
        Customer: Record Customer;
    begin
        // Verify that a Customer can be deleted.

        // Setup: Create a Customer.
        Initialize();
        LibrarySales.CreateCustomer(Customer);

        // Exercise: Delete the newly created customer.
        Customer.Delete(true);

        // Verify: Verify that customer gets deleted successfully.
        Assert.IsFalse(Customer.Get(Customer."No."), CustomerMustBeDeletedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResponsibilityCenterOnSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        UserSetup: Record "User Setup";
        ResponsibilityCenterCode: Code[10];
    begin
        // Check Responsibility Center on Sales Order.

        // Setup: Create User, Item and Customer.
        Initialize();
        ResponsibilityCenterCode := CreateResponsibilityCenterAndUserSetup();

        // Exercise.
        CreateSalesDocumentWithGL(SalesHeader, SalesHeader."Document Type"::Order);

        // Verify: Validate Responsibility Center on Sales Order.
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        SalesHeader.TestField("Responsibility Center", ResponsibilityCenterCode);

        // Tear Down.
        DeleteUserSetup(UserSetup, ResponsibilityCenterCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ResponsibilityCenterOnPostedSalesDocument()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        UserSetup: Record "User Setup";
        PostedDocumentNo: Code[20];
        ResponsibilityCenterCode: Code[10];
    begin
        // Check Responsibility Center on Posted Sales Document.

        // Setup: Create User, Item, Customer and create Sales Order.
        Initialize();
        ResponsibilityCenterCode := CreateResponsibilityCenterAndUserSetup();
        CreateSalesDocumentWithGL(SalesHeader, SalesHeader."Document Type"::Order);

        // Exercise.
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Validate Responsibility Center on Posted Documents.
        SalesInvoiceHeader.Get(PostedDocumentNo);
        SalesInvoiceHeader.TestField("Responsibility Center", ResponsibilityCenterCode);

        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        SalesShipmentHeader.FindFirst();
        SalesShipmentHeader.TestField("Responsibility Center", ResponsibilityCenterCode);

        // Tear Down.
        DeleteUserSetup(UserSetup, ResponsibilityCenterCode);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,GetShipmentLinesHandler')]
    [Scope('OnPrem')]
    procedure GetShipmentLineOnSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        // Verify Shipments on Get Shipment Lines are filtered according to Sell-to Customer No. on Sales Invoice.

        // Setup: Create and Ship two Sales Orders using different Sell-to Customer no. and same Bill-to Customer No. and then create Sales Invoice Header for first Customer.
        Initialize();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());
        CreateShipmentsAndSalesInvoice(SalesHeader, SalesLine);

        // Exercise: Create Sales Invoice lines using Get Shipment Line.
        LibrarySales.GetShipmentLines(SalesLine);

        // Verify: Verify No. of Shipments on Get Shipment Lines page for the Sales Invoice Customer.
        SalesShipmentLine.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        Assert.AreEqual(1, SalesShipmentLine.Count, NoOfRecordErr);  // Take 1 for the Sales Shipment Line.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,GetShipmentLinesHandler')]
    [Scope('OnPrem')]
    procedure GLEntriesAfterGetShipmentLine()
    var
        GeneralPostingSetup: Record "General Posting Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // Verify the GL Entries when posting the Sales Invoice after Get Shipment Lines.

        // Setup: Create and Ship two Sales Orders using different Sell-to Customer no. and same Bill-to Customer No. and then create Sales Invoice for first Customer using Get Shipment Line.
        Initialize();
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyBillToCustomerAddressNotificationId());
        SalesHeader.DontNotifyCurrentUserAgain(SalesHeader.GetModifyCustomerAddressNotificationId());
        CreateShipmentsAndSalesInvoice(SalesHeader, SalesLine);
        LibrarySales.GetShipmentLines(SalesLine);
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine.Type::Item);
        GeneralPostingSetup.Get(SalesLine."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");

        // Exercise: Post the created Sales Invoice.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Amount on GL Entry.
        VerifyGLEntry(DocumentNo, GeneralPostingSetup."Sales Account", -SalesLine."Line Amount");
    end;

    [Test]
    [HandlerFunctions('GetShipmentLinesHandler,ConfirmHandlerFalse')]
    [Scope('OnPrem')]
    procedure TotalsShouldBeRecalculatedByPriceInclVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoice: TestPage "Sales Invoice";
        Price: Decimal;
        AmountIncVAT: Decimal;
    begin
        // [FEATURE] [Totals] [UI]
        // [SCENARIO 401966] Changing "Price Incl VAT" forces the totals calculation.
        Initialize();

        // [GIVEN] Create and Receive Sales Order 'SO', where "Price Incl VAT" is 'No'
        // [GIVEN] Create Sales Invoice 'SI' and do "Get Shipment Lines" to get line from 'SO'.
        CreateShipmentsAndSalesInvoice(SalesHeader, SalesLine);
        LibrarySales.GetShipmentLines(SalesLine);
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine.Type::Item);
        Price := SalesLine."Unit Price";

        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", SalesHeader."No.");
        Evaluate(AmountIncVAT, SalesInvoice.SalesLines."Total Amount Incl. VAT".Value());

        // [WHEN] In 'SI' Change "Price Incl VAT" to Yes, but do not confirm recalculation of prices
        SalesInvoice."Prices Including VAT".SetValue(true);

        // [THEN] Price on the line is not changed, totals are updated on the page.
        SalesLine.Find();
        SalesLine.TestField("Unit Price", Price);
        Assert.AreNotEqual(AmountIncVAT, SalesLine."Amount Including VAT", 'total is not changed.');
        SalesInvoice.SalesLines."Total Amount Incl. VAT".AssertEquals(SalesLine."Amount Including VAT");
    end;

    [Test]
    [HandlerFunctions('QuantityOnGetShipmentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure GetShipmentLinesAfterPartialPosting()
    var
        SalesHeader: Record "Sales Header";
        GetShipmentLines: TestPage "Get Shipment Lines";
    begin
        // Verify Get Shipment Lines page having lines are filtered according to Sales Order.

        // Setup: Post the Sales Order.
        Initialize();
        PartiallyPostSalesOrder(SalesHeader);

        // Exercise: Open Get Shipment Lines page.
        GetShipmentLines.OpenEdit();

        // Verify: Verify that both lines are exists on Get Shipment Lines page with same Quantity on which Sales Order is posted.

        // Verification done in QuantityOnGetShipmentLinesPageHandler page handler.

        // Tear Down.
        SalesHeader.Delete(true);
    end;

    [Test]
    [HandlerFunctions('QuantityFilterUsingGetShipmentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure GetShipmentLineAfterPartialPostingWithQtyFilter()
    var
        SalesHeader: Record "Sales Header";
        GetShipmentLines: TestPage "Get Shipment Lines";
    begin
        // Verify Filter on Get Shipment Lines page filtered according to Quantity.

        // Setup: Post the Sales Order.
        Initialize();
        PartiallyPostSalesOrder(SalesHeader);

        // Exercise: Open Get Shipment Lines page.
        GetShipmentLines.OpenEdit();

        // Verify: Verify Quantity Filter on Get Shipment Lines page, Verification done in the QuantityFilterUsingGetShipmentLinesPageHandler page handler.

        // Tear Down.
        SalesHeader.Delete(true);
    end;

    [Test]
    [HandlerFunctions('InvokeGetShipmentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceAfterQuantityFilterOnGetShipmentLine()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GetShipmentLines: TestPage "Get Shipment Lines";
        PostedInvoiceNo: Code[20];
    begin
        // Verify G/L Entry for partially Posted Sales Invoice after Get Shipment Lines on Sales Invoice.

        // Setup: Post the Sales Order and open Get Shipment Lines page.
        Initialize();
        PartiallyPostSalesOrder(SalesHeader);
        GetShipmentLines.OpenEdit();

        // Exercise: Post the Sales Invoice.
        PostedInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Value on G/L Entry.
        SalesInvoiceHeader.Get(PostedInvoiceNo);
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        VerifyGLEntryForPostedInvoice(PostedInvoiceNo, SalesHeader."Document Type"::Invoice, SalesInvoiceHeader."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATAmountOnPostedSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GeneralPostingSetup: Record "General Posting Setup";
        DocumentNo: Code[20];
        VATAmount: Decimal;
    begin
        // Verify G/L Entry for VAT Amount after Posting Sales Invoice.

        // Setup.
        Initialize();
        CreateSalesDocumentWithItem(SalesHeader, SalesHeader."Document Type"::Invoice);
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine.Type::Item);
        VATAmount := Round(SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."VAT %" / 100);
        GeneralPostingSetup.Get(SalesHeader."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");

        // Exercise: Post the Sales Invoice.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify.
        VerifyVATAmountOnGLEntry(GeneralPostingSetup."Sales Account", DocumentNo, -VATAmount);
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocumentLinesHandler')]
    [Scope('OnPrem')]
    procedure PostSalesCrMemoUsingGetPostedDocLines()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesHeader3: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GeneralPostingSetup: Record "General Posting Setup";
        GeneralLedgerSetup: Record "General Ledger Setup";
        VATRoundingType: Option;
        DocumentNo: Code[20];
        VATAmount: Decimal;
    begin
        // Verify G/L Entry for VAT amount after posting Sales Credit Memo using Get Posted Document Lines to Reverse against posting of Purchase Return Order as Receive.

        // Setup.
        Initialize();

        // Setup: Set VAT Rounding Type in G/L Setup.
        VATRoundingType := UpdateGeneralLedgerVATSetup(GeneralLedgerSetup."VAT Rounding Type"::Nearest);

        // Setup: Create and Post Sales Invoice.
        CreateSalesDocumentWithItem(SalesHeader, SalesHeader."Document Type"::Invoice);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Setup: Create Sales Return Order using Copy Document and post it.
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader2."Document Type"::"Return Order", SalesHeader."Sell-to Customer No.");
        LibrarySales.CopySalesDocument(SalesHeader2, "Sales Document Type From"::"Posted Invoice", DocumentNo, true, false);  // Set TRUE for Include Header and FALSE for Recalculate Lines.
        LibrarySales.PostSalesDocument(SalesHeader2, true, false);

        // Setup: Create Sales Credit Memo using Get Posted Document Lines.
        LibrarySales.CreateSalesHeader(SalesHeader3, SalesHeader3."Document Type"::"Credit Memo", SalesHeader."Sell-to Customer No.");
        GetPostedDocumentLines(SalesHeader3."No.", OptionString::PostedInvoices);
        FindSalesLine(SalesLine, SalesHeader3."Document Type", SalesHeader3."No.", SalesLine.Type::Item);
        VATAmount := Round(SalesLine.Quantity * SalesLine."Unit Price" * SalesLine."VAT %" / 100);
        GeneralPostingSetup.Get(SalesHeader3."Gen. Bus. Posting Group", SalesLine."Gen. Prod. Posting Group");

        // Exercise: Post the Sales Credit Memo.
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader3, true, true);

        // Verify.
        VerifyVATAmountOnGLEntry(GeneralPostingSetup."Sales Credit Memo Account", DocumentNo, VATAmount);

        // Tear Down: Rollback General Ledger Setup.
        UpdateGeneralLedgerVATSetup(VATRoundingType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartingDateAsWorkDateOnSalesPrice()
    begin
        // Verify that correct date gets updated on Sales Price window in "Starting Date Filter" field when user enters W.

        Initialize();
        StartingDateOnSalesPrice('W', WorkDate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StartingDateAsTodayOnSalesPrice()
    begin
        // Verify that correct date gets updated on Sales Price window in "Starting Date Filter" field when user enters T.

        Initialize();
        StartingDateOnSalesPrice('T', Today);
    end;

    local procedure StartingDateOnSalesPrice(StartingDateFilter: Text[1]; StartingDate: Date)
    var
        Customer: Record Customer;
        SalesPrices: TestPage "Sales Prices";
    begin
        // Setup: Create Customer.
        LibrarySales.CreateCustomer(Customer);

        // Exercise: Open Sales Prices Page and Enter date code in Starting Date Filter.
        OpenSalesPricesPage(SalesPrices, Customer."No.", StartingDateFilter);

        // Verify: Verify that correct date comes in "Starting Date Filter".
        SalesPrices.StartingDateFilter.AssertEquals(StartingDate);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnDeletePostedSalesRetOrder()
    var
        SalesHeader: Record "Sales Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
        DocumentNo: Code[20];
    begin
        // Verify Error while delete Posted Sales Return Receipt without print the Document.

        // Setup: Create Customer, create Sales Return Order and Receipt.
        Initialize();
        DocumentNo := CreatePostSalesDocWithGL(SalesHeader, SalesHeader."Document Type"::"Return Order", false);
        ReturnReceiptHeader.Get(DocumentNo);

        // [GIVEN] "Sales Setup"."Allow Document Deletion Before"
        LibrarySales.SetAllowDocumentDeletionBeforeDate(ReturnReceiptHeader."Posting Date" + 1);

        // Exercise.
        asserterror ReturnReceiptHeader.Delete(true);

        // Verify: Verify Error while delete Posted Sales Return Receipt.
        Assert.ExpectedTestFieldError(ReturnReceiptHeader.FieldCaption("No. Printed"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnDeletePostedCreditMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        DocumentNo: Code[20];
    begin
        // Verify Error while delete Posted Sales Credit Memo without print the Document.

        // Setup: Create Customer, create Sales Credit Memo and Post.
        Initialize();
        DocumentNo := CreatePostSalesDocWithGL(SalesHeader, SalesHeader."Document Type"::"Credit Memo", true);
        SalesCrMemoHeader.Get(DocumentNo);
        LibrarySales.SetAllowDocumentDeletionBeforeDate(SalesCrMemoHeader."Posting Date" + 1);

        // Exercise.
        asserterror SalesCrMemoHeader.Delete(true);

        // Verify. Verify Error while delete Posted Sales Credit Memo.
        Assert.ExpectedTestFieldError(SalesCrMemoHeader.FieldCaption("No. Printed"), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedDocWithRetReasonCode()
    begin
        // Verify Return Reason Code on Return Receipt, Credit Memo, Item Ledger and Value Entry.
        RetReasonCodeOnPostedDocument(CreateRetReasonCode());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostedDocWithoutRetReasonCode()
    begin
        // Verify blank Return Reason Code on Return Receipt, Credit Memo, Item Ledger and Value Entry.
        RetReasonCodeOnPostedDocument('');
    end;

    local procedure RetReasonCodeOnPostedDocument(ReturnReasonCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        ItemNo: Code[20];
    begin
        // Setup: Create Customer, create Sales Return Order and Post.
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo();
        CreateSalesDocumentItem(SalesHeader, SalesHeader."Document Type"::"Return Order", ItemNo);
        ModifyReturnReasonCode(SalesHeader."Document Type", SalesHeader."No.", ReturnReasonCode);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Exercise.
        DocumentNo2 := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Verify: Verify Return Reason Code on Return Receipt, Credit Memo, Item Ledger and Value Entry.
        VerifyReturnReceipt(DocumentNo, SalesHeader."No.", SalesHeader."No. Series", ReturnReasonCode);
        VerifyCreditMemo(DocumentNo2, SalesHeader."No.", SalesHeader."No. Series", ReturnReasonCode);
        VerifyItemLedgerEntry(ItemNo, DocumentNo, ReturnReasonCode);
        VerifyValueEntry(DocumentNo2, ReturnReasonCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ErrorOnGetRetRcptNoAfterCreateCrMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [UT] [Return Receipt on Credit Memo] [Credit Memo]
        // [SCENARIO] The error is thrown when Get "Return Receipt No." after create Credit Memo without Return Receipt on Credit Memo.

        Initialize();
        SalesReceivablesSetup.Get();
        // [GIVEN] "Return Receipt on Credit Memo" = "No" in Sales Receivables Setup
        UpdateSalesSetup(false, SalesReceivablesSetup."Exact Cost Reversing Mandatory");

        // [GIVEN] Sales Credit Memo
        CreateSalesDocumentWithGL(SalesHeader, SalesHeader."Document Type"::"Credit Memo");

        // [WHEN] Get next no. from no. series "Return Receipt No. Series"
        asserterror LibraryUtility.GetNextNoFromNoSeries(SalesHeader."Return Receipt No. Series", WorkDate());

        // [THEN] The error "The No. Series does not exist." is thrown
        Assert.ExpectedError(GetRetRcptErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartialPostingOfSalesRetOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LastReturnReceiptNo: Code[20];
        LastPostingNo: Code[20];
    begin
        // Verify Posting Nos on Sales Return Order Header after partial posting.

        // Setup: Create Customer, create Sales Return Order, update partial quantity and Post.
        Initialize();
        CreateSalesDocumentWithGL(SalesHeader, SalesHeader."Document Type"::"Return Order");
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine.Type::"G/L Account");
        SalesLine.Validate("Qty. to Ship", SalesLine.Quantity / 2);  // Required for Partial Posting.
        LastReturnReceiptNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // Exercise.
        LastPostingNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // Verify: Verify Posting Nos on Sales Return Order Header after partial posting.
        SalesHeader.TestField("Last Return Receipt No.", LastReturnReceiptNo);
        SalesHeader.TestField("Return Receipt No.", '');
        SalesHeader.TestField("Last Posting No.", LastPostingNo);
        SalesHeader.TestField("Posting No.", '');
    end;

    [Test]
    [HandlerFunctions('RetRcptLinesPageHandler')]
    [Scope('OnPrem')]
    procedure ErrorOnUpdateGreaterQtytoInvOnCrMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLAccountNo: Code[20];
    begin
        // Verify error while update Qty. to Invoice more than Return Receipt Quantity on Credit Memo Line.

        // Setup: Create Customer, create Sales Return Order, update partial quantity and Post.
        Initialize();
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();

        CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::"Return Order", GLAccountNo, false);
        CreateSalesDocumentWithUnitPrice(
          SalesHeader2, SalesHeader2."Document Type"::"Credit Memo",
          SalesHeader."Sell-to Customer No.", SalesLine.Type::"G/L Account", GLAccountNo);
        GetReturnReceipt(SalesHeader2);
        FindSalesLine(SalesLine, SalesHeader2."Document Type", SalesHeader2."No.", SalesLine.Type::"G/L Account");

        // Exercise.
        asserterror SalesLine.Validate("Qty. to Invoice", SalesLine.Quantity + 1);  // Required Greater quantity than Return Receipt.

        // Verify: Verify error while update Qty. to Invoice more than Return Receipt Quantity on Credit Memo Line.
        Assert.ExpectedError(PostGreaterQtyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteCustomerWithOutstdSalesRetError()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // Verify Error on deleting Customer with Outstanding Sales Returns.

        // Setup: Create Sales Return Order.
        Initialize();
        CreateSalesDocumentWithGL(SalesHeader, SalesHeader."Document Type"::"Return Order");

        // Excercise: Delete Customer.
        Customer.Get(SalesHeader."Sell-to Customer No.");
        asserterror Customer.Delete(true);

        // Verify: Verify Error on deleting Customer.
        Assert.ExpectedError(StrSubstNo(OutstdSalesOrdErr, Customer."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteItemWithOutstdSalesRetError()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        // Verify Error on deleting Item with Outstanding Sales Returns.

        // Setup: Create Sales Return Order.
        Initialize();
        LibraryInventory.CreateItem(Item);
        CreateSalesDocumentItem(SalesHeader, SalesHeader."Document Type"::"Return Order", Item."No.");

        // Excercise.
        asserterror Item.Delete(true);

        // Verify: Verify Error on deleting Item.
        Assert.ExpectedError(StrSubstNo(OutstdSalesReturnErr, Item."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeSalesRetOrdHdrInfoAfterRcdError()
    var
        SalesHeader: Record "Sales Header";
    begin
        // Verify Error while changing Sales Return Order Header information after posting it as Receive.

        // Setup: Create Sales Return Order.
        Initialize();
        CreatePostSalesDocWithGL(SalesHeader, SalesHeader."Document Type"::"Return Order", false);

        // Exercise: Changing Sales Return order Header Sell-to Customer No.
        asserterror SalesHeader.Validate("Sell-to Customer No.", LibrarySales.CreateCustomerNo());

        // Verify: Verify Error on changing Sales Return order Header Information.
        Assert.ExpectedTestFieldError(SalesHeader.FieldCaption(Status), Format(SalesHeader.Status::Open));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteSalesRetOrdHdrAfterRcdError()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verify Error while deleting Sales Return Order Header After Posting it as Receive.

        // Setup: Create Sales Return Order.
        Initialize();
        CreatePostSalesDocWithGL(SalesHeader, SalesHeader."Document Type"::"Return Order", false);
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine.Type::"G/L Account");

        // Exercise: Delete Sales Header.
        asserterror SalesHeader.Delete(true);

        // Verify: Verify Error on deleting Sales Header.
        Assert.ExpectedTestFieldError(SalesLine.FieldCaption("Return Qty. Rcd. Not Invd."), Format(0));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ChangeSalesRetOrdHdrInfoAfterReopenError()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verify Error while changing Sales Return Order Header Information After Reopen Received Sales Returns.

        // Setup: Create Sales Return Order.
        Initialize();
        CreatePostSalesDocWithGL(SalesHeader, SalesHeader."Document Type"::"Return Order", false);
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine.Type::"G/L Account");
        LibrarySales.ReopenSalesDocument(SalesHeader);

        // Exercise: Changing Sales Return order Header "Sell-to Customer No." field.
        asserterror SalesHeader.Validate("Sell-to Customer No.", LibrarySales.CreateCustomerNo());

        // Verify: Verify Error on changing Sales Return order Header "Sell-to Customer No." field.
        Assert.ExpectedTestFieldError(SalesLine.FieldCaption("Return Qty. Received"), Format(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteSalesRetOrdHdrAfterReopenError()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verify Error while deleting Sales Return Order Header after Reopen Received Sales Returns.

        // Setup: Create Sales Return Order.
        Initialize();
        CreatePostSalesDocWithGL(SalesHeader, SalesHeader."Document Type"::"Return Order", false);
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine.Type::"G/L Account");
        LibrarySales.ReopenSalesDocument(SalesHeader);

        // Exercise.
        asserterror SalesHeader.Delete(true);

        // Verify: Verify Error on deleting Sales Header.
        Assert.ExpectedTestFieldError(SalesLine.FieldCaption("Return Qty. Rcd. Not Invd."), Format(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeRetOrdlnTypeError()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
    begin
        // Verify Error while changing Return Order Line Type field.

        // Setup: Create Sales Return Order.
        Initialize();
        CreatePostSalesDocWithGL(SalesHeader, SalesHeader."Document Type"::"Return Order", false);
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine.Type::"G/L Account");
        LibrarySales.ReopenSalesDocument(SalesHeader);

        // Exercise: Change Sales Return Order Line Type field.
        asserterror SalesLine.Validate(Type, SalesLine2.Type::Resource);

        // Verify: Verify Error while changing Sales Return Order Line Type.
        Assert.ExpectedTestFieldError(SalesLine.FieldCaption("Return Qty. Rcd. Not Invd."), Format(0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeRetOrdLnNoError()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verify Error while changing Return Order Line "No." field.

        // Setup: Create Sales Return Order.
        Initialize();
        CreatePostSalesDocWithGL(SalesHeader, SalesHeader."Document Type"::"Return Order", false);
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine.Type::"G/L Account");

        // Exercise: Change Sales Return Order Line "No." field.
        asserterror SalesLine.Validate("No.", LibraryERM.CreateGLAccountWithSalesSetup());

        // Verify: Verify Error while changing Sales Return Order Line "No." field.
        Assert.ExpectedTestFieldError(SalesHeader.FieldCaption(Status), Format(SalesHeader.Status::Open));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteRcdRetOrdLnError()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verify Error while deleting Sales Return Order Line of Received Sales Returns.

        // Setup: Create Sales Return Order.
        Initialize();
        CreatePostSalesDocWithGL(SalesHeader, SalesHeader."Document Type"::"Return Order", false);
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine.Type::"G/L Account");

        // Exercise: Delete Sales Return Order Line.
        asserterror SalesLine.Delete(true);

        // Verify: Verify Error while deleting Sales Return Order Line.
        Assert.ExpectedTestFieldError(SalesHeader.FieldCaption(Status), Format(SalesHeader.Status::Open));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeRetOrdLnRetQtyToReceiveError()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Verify Error while changing Return Order line "Return Qty. to Receive" field.

        // Setup: Create Sales Return Order.
        Initialize();
        CreatePostSalesDocWithGL(SalesHeader, SalesHeader."Document Type"::"Return Order", false);
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine.Type::"G/L Account");

        // Exercise: Change Sales Return Order Line "Return Qty. to Receive" field.
        asserterror SalesLine.Validate("Return Qty. to Receive", SalesLine.Quantity + LibraryRandom.RandInt(10));  // Use Random value for Quantity.

        // Verify: Verify Error while changing Sales Return Order Line "Return Qty. to Receive" filed.
        Assert.ExpectedError(StrSubstNo(ReturnQuantityErr, SalesLine.Quantity - SalesLine."Return Qty. Received"));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ChangeCrMemoHdrInfoError()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLAccountNo: Code[20];
    begin
        // Verify Error while changing Credit Memo Header Information created by Get Return Receipt Lines.

        // Setup: Create Sales Return Order,Create Credit Memo.
        Initialize();
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::"Return Order", GLAccountNo, false);
        CreateCreditMemo(SalesHeader, GLAccountNo);
        FindSalesLine(SalesLine, SalesHeader."Document Type"::"Credit Memo", SalesHeader."No.", SalesLine.Type::"G/L Account");

        // Exercise: Changing Sales Return order Header "Sell-to Customer No." field.
        asserterror SalesHeader.Validate("Sell-to Customer No.", LibrarySales.CreateCustomerNo());

        // Verify: Verify Error on Changing Sales Return order Header "Sell-to Customer No." field.
        Assert.ExpectedTestFieldError(SalesLine.FieldCaption("Return Receipt No."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeSalesCrMemoLnTypeError()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLAccountNo: Code[20];
    begin
        // Verify Error while changing Credit Memo Line Type field created by Get Return Receipt Line.

        // Setup: Create Sales Return Order,Create Credit Memo.
        Initialize();
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::"Return Order", GLAccountNo, false);
        CreateCreditMemo(SalesHeader, GLAccountNo);
        FindSalesLine(SalesLine, SalesHeader."Document Type"::"Credit Memo", SalesHeader."No.", SalesLine.Type::"G/L Account");

        // Exercise: Changing Credit Memo Line Type field.
        asserterror SalesLine.Validate(Type, SalesLine.Type::Resource);

        // Verify: Verify Error on Changing Credit Memo Line Type field.
        Assert.ExpectedTestFieldError(SalesLine.FieldCaption("Return Receipt No."), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegenerateSalesCrMemoLnAfterDelete()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLAccountNo: Code[20];
    begin
        // Verify Credit Memo Line after regenerate it by Get Return Receipt Line.

        // Setup: Create Sales Return Order,Create Credit Memo,Delete Credit Memo Line.
        Initialize();
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::"Return Order", GLAccountNo, false);
        CreateCreditMemo(SalesHeader, GLAccountNo);
        FindSalesLine(SalesLine, SalesHeader."Document Type"::"Credit Memo", SalesHeader."No.", SalesLine.Type::"G/L Account");
        SalesLine.DeleteAll(true);

        // Excercise: Regenerate Credit Memo Line by Get Return Receipt Line.
        CreateCrMemoLnWithGetRetRcptLn(SalesHeader, GLAccountNo);

        // Verify: Verify Credit Memo Line.
        FindSalesLine(SalesLine, SalesHeader."Document Type"::"Credit Memo", SalesHeader."No.", SalesLine.Type::"G/L Account");
        SalesLine.TestField("No.", GLAccountNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeSalesCrMemoLnQtyError()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLAccountNo: Code[20];
    begin
        // Verify Error while changing Credit Memo Line Quantity sign created by Get Return Receipt Line.

        // Setup: Create Sales Return Order,Create Credit Memo.
        Initialize();
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::"Return Order", GLAccountNo, false);
        CreateCreditMemo(SalesHeader, GLAccountNo);
        FindSalesLine(SalesLine, SalesHeader."Document Type"::"Credit Memo", SalesHeader."No.", SalesLine.Type::"G/L Account");

        // Exercise: Change Credit Memo Line Quantity sign.
        asserterror SalesLine.Validate(Quantity, -SalesLine.Quantity);

        // Verify: Verify Error on changing Credit Memo Line Quantity sign.
        Assert.ExpectedError(StrSubstNo(QtyToInvSignErr, SalesLine."Document No.", SalesLine."Line No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeSalesCrMemoLnQtyMorethanRetRcptQtyError()
    var
        ReturnReceiptLine: Record "Return Receipt Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLAccountNo: Code[20];
    begin
        // Verify Error while changing Credit Memo Line Quantity more than Return Receipt Quantity created by Get Return Receipt Line.

        // Setup: Create Sales Return Order,Create Credit Memo.
        Initialize();
        GLAccountNo := LibraryERM.CreateGLAccountWithSalesSetup();
        CreatePostSalesDoc(SalesHeader, SalesHeader."Document Type"::"Return Order", GLAccountNo, false);
        CreateCreditMemo(SalesHeader, GLAccountNo);
        FindSalesLine(SalesLine, SalesHeader."Document Type"::"Credit Memo", SalesHeader."No.", SalesLine.Type::"G/L Account");

        // Exercise: Credit Memo Line Quantity more than Return Return Receipt Quantity.
        asserterror SalesLine.Validate(Quantity, SalesLine.Quantity + LibraryRandom.RandInt(10));  // Use Random value for Quantity.

        // Verify: Verify Error on changing Credit Memo Line Quantity more than Return Return Receipt Quantity.
        ReturnReceiptLine.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        ReturnReceiptLine.FindFirst();
        Assert.ExpectedError(StrSubstNo(QtyInvoiceErr, ReturnReceiptLine."Document No."));
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocumentLinesHandler,ItemTrackingLinesHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostSalesRetOrderWithoutAppFromItemEntryWithIT()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderRetOrder: Record "Sales Header";
        SalesLine: Record "Sales Line";
        InventorySetup: Record "Inventory Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PostedCrMemoNo: Code[20];
    begin
        // Verify GL Entries after Post Sales Return Order (with IT) without Alpply from Item Entry after Get Posted Invoice Line to Reverse.

        // Setup: Update Setup, create Sales Order with Item Tracking and post.
        Initialize();
        InventorySetup.Get();
        LibrarySales.SetCalcInvDiscount(false);
        SalesReceivablesSetup.Get();
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, InventorySetup."Automatic Cost Posting", InventorySetup."Expected Cost Posting to G/L",
          InventorySetup."Automatic Cost Adjustment"::Always, InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");
        UpdateSalesSetup(SalesReceivablesSetup."Return Receipt on Credit Memo", true);

        CreateSalesDocumentItem(SalesHeader, SalesHeader."Document Type"::Order, CreateTrackedItem());
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine.Type::Item);
        SalesLine.OpenItemTrackingLines();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Create Sales Return Order, update 'Apply from Item Entry'.
        CreateAndUpdateSalesRetOrder(SalesHeaderRetOrder, SalesHeader."Sell-to Customer No.");
        LibraryVariableStorage.Enqueue(AdjustCostMsg);
        SalesHeaderRetOrder.CalcFields("Amount Including VAT");

        // Exercise.
        PostedCrMemoNo := LibrarySales.PostSalesDocument(SalesHeaderRetOrder, true, true);

        // Verify: Verify GL Entries after Post Sales Return Order (with IT) without Alpply from Item Entry.
        VerifyGLEntryForPostedInvoice(
          PostedCrMemoNo, SalesHeaderRetOrder."Document Type"::"Credit Memo", SalesHeaderRetOrder."Amount Including VAT");

        // Tear down.
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, InventorySetup."Automatic Cost Posting", InventorySetup."Expected Cost Posting to G/L",
          InventorySetup."Automatic Cost Adjustment", InventorySetup."Average Cost Calc. Type",
          InventorySetup."Average Cost Period");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExplBOMOnSalesCrMemoError()
    var
        ReturnReceiptHeader: Record "Return Receipt Header";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
    begin
        // Verify Error while applying Explode BOM on Credit Memo created by Get Return Receipt Line.

        // Setup: Create Sales Return Order,Create Credit Memo.
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo();

        CreateSalesDocumentItem(SalesHeader, SalesHeader."Document Type"::"Return Order", ItemNo);
        ReturnReceiptHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, false));
        SalesHeader.Get(SalesHeader."Document Type"::"Return Order", ReturnReceiptHeader."Return Order No.");

        CreateCreditMemo(SalesHeader, ItemNo);
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine.Type::" ");

        // Excercise: Apply Explode BOM on Sales Return Order Line.
        asserterror LibrarySales.ExplodeBOM(SalesLine);

        // Verify: Verify Error while applying Explode BOM on Sales Return Order Line.
        Assert.ExpectedTestFieldError(SalesLine.FieldCaption(Type), Format(SalesLine.Type::Item));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExtendedTextOnSalesRetOrd()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesReturnOrder: TestPage "Sales Return Order";
        ItemNo: Code[20];
    begin
        // Verify Extended Text on Sales Return Order Line with Extended Text Line of Item.

        // Setup: Create Customer, Item, Extended Text Line.
        Initialize();
        ItemNo := CreateItemAndExtendedText(false);

        CreateSalesDocumentItem(SalesHeader, SalesHeader."Document Type"::"Return Order", ItemNo);
        SalesReturnOrder.OpenEdit();

        // Exercise: Insert Extended Text in Sales Line.
        SalesReturnOrder.SalesLines."Insert &Ext. Texts".Invoke();

        // Verify: Verify desription of Extended Text of Sales Return Order Line.
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine.Type::Item);
        SalesLine.TestField(Description, ItemNo);
    end;

    [Test]
    [HandlerFunctions('SendNotificationHandler,RecallNotificationHandler')]
    [Scope('OnPrem')]
    procedure CreateSalesInvoiceLineWhiteLocationQtyError()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // Unit test
        asserterror SalesDocLineQtyValidation("Sales Document Type"::Invoice);
        Assert.ExpectedError(WhseShipmentIsRequiredErr);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSalesCrMemoLineWhiteLocationQtyError()
    var
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // Unit test
        asserterror SalesDocLineQtyValidation("Sales Document Type"::"Credit Memo");
        Assert.ExpectedError(WhseReceiveIsRequiredErr);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartiallyPostSalesOrderWithCompleteShipmentAdviceError()
    begin
        // Verify error when partially shipping Sales Order with Complete Shipping Advice if it contains first line with negative quantities.

        PartialPostingOfCompleteSalesOrder(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PartiallyPostSalesOrderWithCompleteShipmentAdviceErrorZero()
    begin
        // Verify error when partially shipping Sales Order with Complete Shipping Advicewith first line negative and also a line with zero.

        PartialPostingOfCompleteSalesOrder(true);
    end;

    local procedure PartialPostingOfCompleteSalesOrder(WithZeroLine: Boolean)
    var
        SalesHeader: Record "Sales Header";
    begin
        // Setup: Create Customer, create Sales Order, update partial Quantity to Ship and Post.
        Initialize();
        CreateSalesDocumentWithItem(SalesHeader, SalesHeader."Document Type"::Order);
        SalesHeader.Validate("Shipping Advice", SalesHeader."Shipping Advice"::Complete);
        SalesHeader.Modify();
        ModifyAndAddSalesLine(SalesHeader, WithZeroLine);

        // Exercise and Verify.
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreditMemoLineDiscountRoundingUsingCopyDoc()
    var
        SalesHeaderSrc: Record "Sales Header";
        SalesHeaderDst: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        UnitPrice: Decimal;
        DiscountAmt: Decimal;
    begin
        // [FEATURE] [Line Discount] [Credit Memo] [Rounding] [Copy Document]
        // [SCENARIO 375821] Line Discount Amount is correctly copied when using Copy Document for Sales Credit Memo
        Initialize();
        DiscountAmt := 1;
        UnitPrice := 20000000; // = 1 / (0.00001 / 2)

        // [GIVEN] Posted Sales Invoice with Quantity = 1, "Unit Price" = 20000000, "Line Discount Amount" = 1, "Line Discount %" = 0.00001
        CreateSalesDocumentWithGL(SalesHeaderSrc, SalesHeaderSrc."Document Type"::Invoice);
        ModifySalesLine(
          SalesHeaderSrc."Document Type"::Invoice, SalesHeaderSrc."No.", SalesLine.Type::"G/L Account", 1, UnitPrice, DiscountAmt);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeaderSrc, true, true);

        // [WHEN] Create new Sales Credit Memo using Copy Document
        LibrarySales.CreateSalesHeader(
          SalesHeaderDst, SalesHeaderDst."Document Type"::"Credit Memo", SalesHeaderSrc."Sell-to Customer No.");
        LibrarySales.CopySalesDocument(SalesHeaderDst, "Sales Document Type From"::"Posted Invoice", DocumentNo, true, false);

        // [THEN] Sales Credit Memo "Line Discount Amount" = 1
        FindSalesLine(SalesLine, SalesHeaderDst."Document Type", SalesHeaderDst."No.", SalesLine.Type::"G/L Account");
        Assert.AreEqual(DiscountAmt, SalesLine."Line Discount Amount", SalesLine.FieldCaption("Line Discount Amount"));
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocumentLinesHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoLineDiscountRoundingUsingGetPostedDocLines()
    var
        SalesHeaderSrc: Record "Sales Header";
        SalesHeaderDst: Record "Sales Header";
        SalesLine: Record "Sales Line";
        UnitPrice: Decimal;
        DiscountAmt: Decimal;
    begin
        // [FEATURE] [Line Discount] [Credit Memo] [Rounding] [Get Document Lines to Reverse]
        // [SCENARIO 375821] Line Discount Amount is correctly copied when using Get Posted Document Lines for Sales Credit Memo
        Initialize();
        DiscountAmt := 1;
        UnitPrice := 20000000; // = 1 / (0.00001 / 2)

        // [GIVEN] Posted Sales Invoice with Quantity = 1, "Unit Price" = 20000000, "Line Discount Amount" = 1, "Line Discount %" = 0.00001
        CreateSalesDocumentWithItem(SalesHeaderSrc, SalesHeaderSrc."Document Type"::Invoice);
        ModifySalesLine(SalesHeaderSrc."Document Type"::Invoice, SalesHeaderSrc."No.", SalesLine.Type::Item, 1, UnitPrice, DiscountAmt);
        LibrarySales.PostSalesDocument(SalesHeaderSrc, true, true);

        // [WHEN] Create new Sales Credit Memo using Get Posted Document Lines
        LibrarySales.CreateSalesHeader(
          SalesHeaderDst, SalesHeaderDst."Document Type"::"Credit Memo", SalesHeaderSrc."Sell-to Customer No.");
        GetPostedDocumentLines(SalesHeaderDst."No.", OptionString::PostedInvoices);

        // [THEN] Sales Credit Memo "Line Discount Amount" = 1
        FindSalesLine(SalesLine, SalesHeaderDst."Document Type", SalesHeaderDst."No.", SalesLine.Type::Item);
        Assert.AreEqual(DiscountAmt, SalesLine."Line Discount Amount", SalesLine.FieldCaption("Line Discount Amount"));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure SalesOrderArchiveUserRespCenterFilter()
    var
        ResponsibilityCenter: array[2] of Record "Responsibility Center";
        UserSetup: Record "User Setup";
        SalesOrderArchives: TestPage "Sales Order Archives";
        CustomerNo: Code[20];
        OldSalesRespCtrFilter: Code[10];
    begin
        // [FEATURE] [Responsibility Center] [Archive]
        // [SCENARIO 375976] Sales Order Archive shows entries depending on User's Responsibility Center
        Initialize();

        // [GIVEN] Responsibility Center "A" and "B"
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        OldSalesRespCtrFilter := UpdateUserSetupSalesRespCtrFilter(UserSetup, '');
        LibraryService.CreateResponsibilityCenter(ResponsibilityCenter[1]);
        LibraryService.CreateResponsibilityCenter(ResponsibilityCenter[2]);
        CustomerNo := LibrarySales.CreateCustomerNo();

        // [GIVEN] Archived Sales Order for Responsibility Center "A"
        CreateAndArchiveSalesOrderWithRespCenter(
          CustomerNo, ResponsibilityCenter[1].Code);

        // [GIVEN] Archived Sales Order for Responsibility Center "B"
        CreateAndArchiveSalesOrderWithRespCenter(
          LibrarySales.CreateCustomerNo(), ResponsibilityCenter[2].Code);

        // [GIVEN] User is assigned to Responsibility Center "A"
        UpdateUserSetupSalesRespCtrFilter(UserSetup, ResponsibilityCenter[1].Code);

        // [WHEN] Sales Order Archive page is opened
        SalesOrderArchives.OpenView();

        // [THEN] Only entries for Responsibility Center "A" are shown
        SalesOrderArchives."Sell-to Customer No.".AssertEquals(CustomerNo);
        Assert.IsFalse(SalesOrderArchives.Next(), SalesOrderArchiveRespCenterErr);

        UpdateUserSetupSalesRespCtrFilter(UserSetup, OldSalesRespCtrFilter);
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocumentLinesHandler')]
    [Scope('OnPrem')]
    procedure GetDocLinesToReverseFromInvoiceWithTwoShipments()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        LineDiscount: Decimal;
    begin
        // [FEATURE] [Line Discount] [Get Document Lines to Reverse]
        // [SCENARIO 376131] Action "Get Document Lines to Reserse" copies line discount from original sales document when the sales order is shipped in two parts, then invoiced

        // [GIVEN] Sales order with one line: "Line Discount %" = 10
        LineDiscount := LibraryRandom.RandDec(50, 2);
        CreateSalesDocumentWithItem(SalesHeader, SalesHeader."Document Type"::Order);
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.Validate("Line Discount %", LineDiscount);
        SalesLine.Validate("Qty. to Ship", SalesLine."Qty. to Ship" / 2);
        SalesLine.Modify(true);

        // [GIVEN] Post partial shipment
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        // [GIVEN] Ship remaining quantity
        LibrarySales.PostSalesDocument(SalesHeader, true, false);
        // [GIVEN] Invoice total amount
        LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [GIVEN] Create credit memo
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Sell-to Customer No.");
        // [WHEN] Run Get Document Lines to Reverse and copy from posted sales invoice
        GetPostedDocumentLines(SalesHeader."No.", OptionString::PostedInvoices);
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine.Type::Item);

        // [THEN] "Line Discount %" = 10 in the credit memo
        Assert.AreEqual(LineDiscount, SalesLine."Line Discount %", SalesLine.FieldCaption("Line Discount Amount"));
    end;

    [Test]
    [HandlerFunctions('CertificateofSupplyRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CertificateOfSupplyPartiallyShippedOrder()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Item: array[2] of Record Item;
        SalesHeader: Record "Sales Header";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Report] [Certificate of Supply]
        // [SCENARIO 376661] "Certificate of Supply" report shows only shipped lines
        Initialize();

        // [GIVEN] "VAT Posting Setup" with enabled "Certificate of Supply Required"
        CreateVATPostingSetupWithCertificateOfSupply(VATPostingSetup);

        // [GIVEN] Sales Order with 2 lines where "Sales Line"[1]."Qty to Ship" = 5 and "Sales Line"[2]."Qty to Ship" = 0
        CustomerNo := LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        CreateSalesLineWithItem(
          Item[1], SalesHeader, LibraryRandom.RandInt(10), VATPostingSetup."VAT Prod. Posting Group");
        CreateSalesLineWithItem(
          Item[2], SalesHeader, 0, VATPostingSetup."VAT Prod. Posting Group");

        // [GIVEN] Order shipped only
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Run report "Certificate of Supply"
        RunCertificateOfSupplyReport(CustomerNo);

        // [THEN] Exported row count = 1
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(1, LibraryReportDataset.RowCount(), NoOfRecordErr);
        // [THEN] Exported row refered to "Sales Line"[1]
        LibraryReportDataset.MoveToRow(1);
        LibraryReportDataset.AssertCurrentRowValueEquals('Item_No', Item[1]."No.");

        // Tear-down
        VATPostingSetup.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CopySalesInvoiceFirstLineNotShipped()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        Customer: Record Customer;
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Copy Document]
        // [SCENARIO 378027] It should be possible to Copy Sales Invoice with two lines where first was not Shipped
        Initialize();

        UpdateSalesSetup(false, true);

        // [GIVEN] Sales Order "S" with two Lines
        LibrarySales.CreateCustomer(Customer);
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        SalesLine.Validate("Qty. to Ship", 0);
        SalesLine.Modify();
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // [GIVEN] Post Sales Order as Ship and Invoice for second line
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Sales Credit Memo
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");

        // [WHEN] Run Copy Document for Posted Sales Invoice
        LibrarySales.CopySalesDocument(SalesHeader, "Sales Document Type From"::"Posted Invoice", PostedDocumentNo, true, false);

        // [THEN] Posted Sales Invoice is copied
        FilterSalesCreditMemoLine(SalesLine, SalesHeader."No.", Item."No.");
        SalesLine.FindFirst();
        SalesLine.TestField(Quantity, 0);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure CopySalesInvoiceFirstLineTypeBlank()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        PostedDocumentNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] [Copy Document]
        // [SCENARIO 379142] It should be possible to Copy Posted Sales Invoice with first Line blank Type and second Line Item Tracked
        Initialize();

        UpdateSalesSetup(false, true);

        // [GIVEN] Sales Invoice with two Lines
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");

        // [GIVEN] First Sales Invoice Line with Type = " "
        MockSalesInvoiceLine(SalesHeader."No.");

        // [GIVEN] Second Sales Invoice Tracked Line with type "Item"
        ItemNo := CreateTrackedItem();
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
        SalesLine.OpenItemTrackingLines();

        // [GIVEN] Post Sales Invoice
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Sales Credit Memo
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Customer."No.");

        // [WHEN] Run Copy Document for Posted Sales Invoice
        LibrarySales.CopySalesDocument(SalesHeader, "Sales Document Type From"::"Posted Invoice", PostedDocumentNo, true, false);

        // [THEN] Posted Sales Invoice is copied
        FilterSalesCreditMemoLine(SalesLine, SalesHeader."No.", ItemNo);
        Assert.RecordIsNotEmpty(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceDescriptionLine()
    var
        SalesHeader: Record "Sales Header";
        PostedDocNo: Code[20];
        Description: Text[50];
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 378530] Sales Invoice description line with Type = "G/L Account"
        Initialize();

        // [GIVEN] Sales Order with two lines:
        // [GIVEN] Line1: Type = "G/L Account", No="6610", Description = "Sales, Other Job Expenses"
        // [GIVEN] Line2: Type = "G/L Account", No="", Description = "Description Line"
        CreatePostSalesDocWithGLDescriptionLine(SalesHeader, Description, SalesHeader."Document Type"::Order);

        // [WHEN] Post Sales Order (Invoice).
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Description line has been posted: Type = "", No="", Description = "Description Line"
        VerifySalesInvDescriptionLineExists(PostedDocNo, Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesShptDescriptionLine()
    var
        SalesHeader: Record "Sales Header";
        PostedDocNo: Code[20];
        Description: Text[50];
    begin
        // [FEATURE] [Shipment]
        // [SCENARIO 378530] Sales Shipment description line with Type = "G/L Account"
        Initialize();

        // [GIVEN] Sales Order with two lines:
        // [GIVEN] Line1: Type = "G/L Account", No="6610", Description = "Sales, Other Job Expenses"
        // [GIVEN] Line2: Type = "G/L Account", No="", Description = "Description Line"
        CreatePostSalesDocWithGLDescriptionLine(SalesHeader, Description, SalesHeader."Document Type"::Order);

        // [WHEN] Post Sales Order (Ship).
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Description line has been posted: Type = "", No="", Description = "Description Line"
        VerifySalesShptDescriptionLineExists(PostedDocNo, Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesCrMemoDescriptionLine()
    var
        SalesHeader: Record "Sales Header";
        PostedDocNo: Code[20];
        Description: Text[50];
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 378530] Sales Credit Memo description line with Type = "G/L Account"
        Initialize();

        // [GIVEN] Sales Return Order with two lines:
        // [GIVEN] Line1: Type = "G/L Account", No="6610", Description = "Sales, Other Job Expenses"
        // [GIVEN] Line2: Type = "G/L Account", No="", Description = "Description Line"
        CreatePostSalesDocWithGLDescriptionLine(SalesHeader, Description, SalesHeader."Document Type"::"Return Order");

        // [WHEN] Post Sales Return Order (Invoice).
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Description line has been posted: Type = "", No="", Description = "Description Line"
        VerifySalesCrMemoDescriptionLineExists(PostedDocNo, Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesRetRcptDescriptionLine()
    var
        SalesHeader: Record "Sales Header";
        PostedDocNo: Code[20];
        Description: Text[50];
    begin
        // [FEATURE] [Return Receipt]
        // [SCENARIO 378530] Sales Return Receipt description line with Type = "G/L Account"
        Initialize();

        // [GIVEN] Sales Return Order with two lines:
        // [GIVEN] Line1: Type = "G/L Account", No="6610", Description = "Sales, Other Job Expenses"
        // [GIVEN] Line2: Type = "G/L Account", No="", Description = "Description Line"
        CreatePostSalesDocWithGLDescriptionLine(SalesHeader, Description, SalesHeader."Document Type"::"Return Order");

        // [WHEN] Post Sales Return Order (Ship).
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Description line has been posted: Type = "", No="", Description = "Description Line"
        VerifySalesRetRcptDescriptionLineExists(PostedDocNo, Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesShipmentLine_InitFromSalesLine_UT()
    var
        SalesLine: Record "Sales Line";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        // [FEATURE] [UT] [Shipment]
        // [SCENARIO] TAB111 "Sales Shipment Line".InitFromSalesLine() correctly inits SalesShipmentLine from SalesLine
        SalesShipmentHeader.Init();
        SalesShipmentHeader."Posting Date" := LibraryRandom.RandDate(100);
        SalesShipmentHeader."No." := LibraryUtility.GenerateGUID();

        InitSalesLine(SalesLine, SalesLine."Document Type"::Order);

        SalesShipmentLine.InitFromSalesLine(SalesShipmentHeader, SalesLine);
        Assert.AreEqual(SalesShipmentHeader."Posting Date", SalesShipmentLine."Posting Date", SalesShipmentLine.FieldCaption("Posting Date"));
        Assert.AreEqual(SalesShipmentHeader."No.", SalesShipmentLine."Document No.", SalesShipmentLine.FieldCaption("Document No."));
        Assert.AreEqual(SalesLine."Qty. to Ship", SalesShipmentLine.Quantity, SalesShipmentLine.FieldCaption(Quantity));
        Assert.AreEqual(SalesLine."Qty. to Ship (Base)", SalesShipmentLine."Quantity (Base)", SalesShipmentLine.FieldCaption("Quantity (Base)"));
        Assert.AreEqual(SalesLine."Qty. to Invoice", SalesShipmentLine."Quantity Invoiced", SalesShipmentLine.FieldCaption("Quantity Invoiced"));
        Assert.AreEqual(SalesLine."Qty. to Invoice (Base)", SalesShipmentLine."Qty. Invoiced (Base)", SalesShipmentLine.FieldCaption("Qty. Invoiced (Base)"));
        Assert.AreEqual(
          SalesLine."Qty. to Ship" - SalesLine."Qty. to Invoice",
          SalesShipmentLine."Qty. Shipped Not Invoiced", SalesShipmentLine.FieldCaption("Qty. Shipped Not Invoiced"));
        Assert.AreEqual(SalesLine."Document No.", SalesShipmentLine."Order No.", SalesShipmentLine.FieldCaption("Order No."));
        Assert.AreEqual(SalesLine."Line No.", SalesShipmentLine."Order Line No.", SalesShipmentLine.FieldCaption("Order Line No."));
        Assert.AreEqual(SalesShipmentLine.Type::" ", SalesShipmentLine.Type, SalesShipmentLine.FieldCaption(Type));
        Assert.AreEqual(SalesLine."No.", SalesShipmentLine."No.", SalesShipmentLine.FieldCaption("No."));
        Assert.AreEqual(SalesLine.Description, SalesShipmentLine.Description, SalesShipmentLine.FieldCaption(Description));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceLine_InitFromSalesLine_UT()
    var
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        // [FEATURE] [UT] [Invoice]
        // [SCENARIO] TAB113 "Sales Invoice Line".InitFromSalesLine() correctly inits SalesInvoiceLine from SalesLine
        SalesInvoiceHeader.Init();
        SalesInvoiceHeader."Posting Date" := LibraryRandom.RandDate(100);
        SalesInvoiceHeader."No." := LibraryUtility.GenerateGUID();

        InitSalesLine(SalesLine, SalesLine."Document Type"::Order);

        SalesInvoiceLine.InitFromSalesLine(SalesInvoiceHeader, SalesLine);
        Assert.AreEqual(SalesInvoiceHeader."Posting Date", SalesInvoiceLine."Posting Date", SalesInvoiceLine.FieldCaption("Posting Date"));
        Assert.AreEqual(SalesInvoiceHeader."No.", SalesInvoiceLine."Document No.", SalesInvoiceLine.FieldCaption("Document No."));
        Assert.AreEqual(SalesLine."Qty. to Invoice", SalesInvoiceLine.Quantity, SalesInvoiceLine.FieldCaption(Quantity));
        Assert.AreEqual(SalesLine."Qty. to Invoice (Base)", SalesInvoiceLine."Quantity (Base)", SalesInvoiceLine.FieldCaption("Quantity (Base)"));
        Assert.AreEqual(SalesInvoiceLine.Type::" ", SalesInvoiceLine.Type, SalesInvoiceLine.FieldCaption(Type));
        Assert.AreEqual(SalesLine."No.", SalesInvoiceLine."No.", SalesInvoiceLine.FieldCaption("No."));
        Assert.AreEqual(SalesLine.Description, SalesInvoiceLine.Description, SalesInvoiceLine.FieldCaption(Description));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoLine_InitFromSalesLine_UT()
    var
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        // [FEATURE] [UT] [Credit Memo]
        // [SCENARIO] TAB115 "Sales Cr.Memo Line".InitFromSalesLine() correctly inits SalesCrMemoLine from SalesLine
        SalesCrMemoHeader.Init();
        SalesCrMemoHeader."Posting Date" := LibraryRandom.RandDate(100);
        SalesCrMemoHeader."No." := LibraryUtility.GenerateGUID();

        InitSalesLine(SalesLine, SalesLine."Document Type"::"Return Order");

        SalesCrMemoLine.InitFromSalesLine(SalesCrMemoHeader, SalesLine);
        Assert.AreEqual(SalesCrMemoHeader."Posting Date", SalesCrMemoLine."Posting Date", SalesCrMemoLine.FieldCaption("Posting Date"));
        Assert.AreEqual(SalesCrMemoHeader."No.", SalesCrMemoLine."Document No.", SalesCrMemoLine.FieldCaption("Document No."));
        Assert.AreEqual(SalesLine."Qty. to Invoice", SalesCrMemoLine.Quantity, SalesCrMemoLine.FieldCaption(Quantity));
        Assert.AreEqual(SalesLine."Qty. to Invoice (Base)", SalesCrMemoLine."Quantity (Base)", SalesCrMemoLine.FieldCaption("Quantity (Base)"));
        Assert.AreEqual(SalesCrMemoLine.Type::" ", SalesCrMemoLine.Type, SalesCrMemoLine.FieldCaption(Type));
        Assert.AreEqual(SalesLine."No.", SalesCrMemoLine."No.", SalesCrMemoLine.FieldCaption("No."));
        Assert.AreEqual(SalesLine.Description, SalesCrMemoLine.Description, SalesCrMemoLine.FieldCaption(Description));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReturnReceiptLine_InitFromSalesLine_UT()
    var
        SalesLine: Record "Sales Line";
        ReturnReceiptHeader: Record "Return Receipt Header";
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        // [FEATURE] [UT] [Return Receipt]
        // [SCENARIO] TAB6661 "Return Receipt Line".InitFromSalesLine() correctly inits ReturnReceiptLine from SalesLine
        ReturnReceiptHeader.Init();
        ReturnReceiptHeader."Posting Date" := LibraryRandom.RandDate(100);
        ReturnReceiptHeader."No." := LibraryUtility.GenerateGUID();

        InitSalesLine(SalesLine, SalesLine."Document Type"::"Return Order");

        ReturnReceiptLine.InitFromSalesLine(ReturnReceiptHeader, SalesLine);
        Assert.AreEqual(ReturnReceiptHeader."Posting Date", ReturnReceiptLine."Posting Date", ReturnReceiptLine.FieldCaption("Posting Date"));
        Assert.AreEqual(ReturnReceiptHeader."No.", ReturnReceiptLine."Document No.", ReturnReceiptLine.FieldCaption("Document No."));
        Assert.AreEqual(SalesLine."Return Qty. to Receive", ReturnReceiptLine.Quantity, ReturnReceiptLine.FieldCaption(Quantity));
        Assert.AreEqual(SalesLine."Return Qty. to Receive (Base)", ReturnReceiptLine."Quantity (Base)", ReturnReceiptLine.FieldCaption("Quantity (Base)"));
        Assert.AreEqual(SalesLine."Qty. to Invoice", ReturnReceiptLine."Quantity Invoiced", ReturnReceiptLine.FieldCaption("Quantity Invoiced"));
        Assert.AreEqual(SalesLine."Qty. to Invoice (Base)", ReturnReceiptLine."Qty. Invoiced (Base)", ReturnReceiptLine.FieldCaption("Qty. Invoiced (Base)"));
        Assert.AreEqual(
          SalesLine."Return Qty. to Receive" - SalesLine."Qty. to Invoice",
          ReturnReceiptLine."Return Qty. Rcd. Not Invd.", ReturnReceiptLine.FieldCaption("Return Qty. Rcd. Not Invd."));
        Assert.AreEqual(SalesLine."Document No.", ReturnReceiptLine."Return Order No.", ReturnReceiptLine.FieldCaption("Return Order No."));
        Assert.AreEqual(SalesLine."Line No.", ReturnReceiptLine."Return Order Line No.", ReturnReceiptLine.FieldCaption("Return Order Line No."));
        Assert.AreEqual(ReturnReceiptLine.Type::" ", ReturnReceiptLine.Type, ReturnReceiptLine.FieldCaption(Type));
        Assert.AreEqual(SalesLine."No.", ReturnReceiptLine."No.", ReturnReceiptLine.FieldCaption("No."));
        Assert.AreEqual(SalesLine.Description, ReturnReceiptLine.Description, ReturnReceiptLine.FieldCaption(Description));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplaceSalesLineStandardTextWithExtText()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        StandardText: Record "Standard Text";
        ExtendedText: Text;
    begin
        // [FEATURE] [Standard Text] [Extended Text]
        // [SCENARIO 380579] Replacing of Sales Line's Standard Text Code updates attached Extended Text lines
        Initialize();

        // [GIVEN] Standard Text (Code = "ST1", Description = "SD1") with Extended Text "ET1".
        // [GIVEN] Standard Text (Code = "ST2", Description = "SD2") with Extended Text "ET2".
        // [GIVEN] Sales Order with line: "Type" = "", "No." = "ST1"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        MockSalesLine(SalesLine, SalesHeader);
        ValidateSalesLineStandardCode(SalesLine, LibrarySales.CreateStandardTextWithExtendedText(StandardText, ExtendedText));

        // [WHEN] Validate Sales Line "No." = "ST2"
        ValidateSalesLineStandardCode(SalesLine, LibrarySales.CreateStandardTextWithExtendedText(StandardText, ExtendedText));

        // [THEN] There are two Sales lines:
        // [THEN] Line1: Type = "", "No." = "ST2", Description = "SD2"
        // [THEN] Line2: Type = "", "No." = "", Description = "ET2"
        VerifySalesLineCount(SalesHeader, 2);
        VerifySalesLineDescription(SalesLine, SalesLine.Type::" ", StandardText.Code, StandardText.Description);
        SalesLine.Next();
        VerifySalesLineDescription(SalesLine, SalesLine.Type::" ", '', ExtendedText);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithDiffCustPostingGroup()
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InvNo: Code[20];
    begin
        // [SCENARIO 380573] Sales Invoice is posted with "Customer Posting Group" from Sales Header when "Customer Posting Group" in Customer Card is different

        Initialize();
        SetSalesAllowMultiplePostingGroups(true);

        // [GIVEN] Customer "X" with "Customer Posting Group" "DOMESTIC"
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Allow Multiple Posting Groups", true);
        Customer.Modify();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);

        // [GIVEN] Sales Invoice with Customer "X" and "Customer Posting Group" "FOREIGN"
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        LibrarySales.CreateAltCustomerPostingGroup(Customer."Customer Posting Group", CustomerPostingGroup.Code);
        SalesHeader.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        SalesHeader.Modify(true);

        // [WHEN] Post Sales Invoice
        InvNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SetSalesAllowMultiplePostingGroups(false);

        // [THEN] Customer Ledger Entry with "Customer Posting Group" "FOREIGN" is posted
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, InvNo);
        CustLedgerEntry.TestField("Customer Posting Group", SalesHeader."Customer Posting Group");
    end;

    [Test]
    [HandlerFunctions('CertificateofSupplyRequestPageHandler')]
    [Scope('OnPrem')]
    procedure NoErrorWhileCreatingCertificateOfSupplyForDocWithSeveralSalesShipLines()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Report] [Certificate of Supply]
        // [SCENARIO 381585] No "The Service Shipment Line already exists." should appear while reporting Certificate of Supply
        // [SCENARIO] with several Sales Shipment Lines having 0 quantity and the same "Line No."

        Initialize();

        // [GIVEN] "VAT Posting Setup" with enabled "Certificate of Supply Required"
        CreateVATPostingSetupWithCertificateOfSupply(VATPostingSetup);

        // [GIVEN] Sales Order 1 having 2 lines, and line 20000 has 0 "Quantity"
        CustomerNo := LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        CreateSalesLineWithItem(
          Item, SalesHeader, LibraryRandom.RandInt(10), VATPostingSetup."VAT Prod. Posting Group");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 0);

        // [GIVEN] Order 1 shipped only
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Sales Order 2 having 2 lines, and line 20000 with 0 "Quantity"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 0);

        // [GIVEN] Order 2 shipped only
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [WHEN] Run report "Certificate of Supply"
        RunCertificateOfSupplyReport(CustomerNo);

        // [THEN] Exported row count = 2 and no error appears
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreEqual(2, LibraryReportDataset.RowCount(), NoOfRecordErr);

        // Tear-down
        VATPostingSetup.Delete(true);
    end;

    [Test]
    [HandlerFunctions('GetSalesPricePageHandler')]
    [Scope('OnPrem')]
    procedure SalesLineFactboxSalesPriceUpdatedInReopenedOrder()
    var
        SalesPrice: Record "Sales Price";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Order] [Sales Price] [Sales Line Factbox] [UI]
        // [SCENARIO 382356] It should be possible to update sales price via Sales Line Factbox after reopening a released sales order

        Initialize();
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 15.0)");

        // [GIVEN] Sales price "P" for item "I"
        CreateSalesPriceForItemAndAllCustomers(SalesPrice);

        // [GIVEN] Sales order "S" for item "I"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, SalesPrice."Item No.", LibraryRandom.RandInt(10));

        // [GIVEN] Release the sales order
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        // COMMIT required to preserve the sales order from rollback after the first error
        Commit();

        // [GIVEN] Drill down to sales prices from the Sales Line Factbox and try to update the sales price
        // [GIVEN] Update fails, because the order is not in "Open" status
        // This action initializes the internal variable SalesHeader in Sales Lines Factbox
        asserterror SalesOrder.Control1906127307.SalesPrices.DrillDown();

        // [GIVEN] Reopen the sales order
        SalesOrder.Reopen.Invoke();

        // [WHEN] Drill down to sales prices from the Sales Line Factbox and try to update the sales price
        SalesOrder.Control1906127307.SalesPrices.DrillDown();

        // [THEN] Price in the sales order line is successfully updated
        SalesLine.Find();
        SalesLine.TestField("Unit Price", SalesPrice."Unit Price");
    end;

    [Test]
    [HandlerFunctions('GetPriceLinePageHandler')]
    [Scope('OnPrem')]
    procedure SalesLineFactboxPriceLineUpdatedInReopenedOrder()
    var
        SalesPrice: Record "Sales Price";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Order] [Best Price] [Sales Line Factbox] [UI]
        // [SCENARIO 382356] It should be possible to update sales price via Sales Line Factbox after reopening a released sales order

        Initialize();
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Sales price "P" for item "I"
        CreateSalesPriceForItemAndAllCustomers(SalesPrice);

        // [GIVEN] Sales order "S" for item "I"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, SalesPrice."Item No.", LibraryRandom.RandInt(10));

        // [GIVEN] Release the sales order
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        // COMMIT required to preserve the sales order from rollback after the first error
        Commit();

        // [GIVEN] Drill down to sales prices from the Sales Line Factbox and try to update the sales price
        // [GIVEN] Update fails, because the order is not in "Open" status
        // This action initializes the internal variable SalesHeader in Sales Lines Factbox
        asserterror SalesOrder.Control1906127307.SalesPrices.DrillDown();

        // [GIVEN] Reopen the sales order
        SalesOrder.Reopen.Invoke();

        // [WHEN] Drill down to sales prices from the Sales Line Factbox and try to update the sales price
        SalesOrder.Control1906127307.SalesPrices.DrillDown();

        // [THEN] Price in the sales order line is successfully updated
        SalesLine.Find();
        SalesLine.TestField("Unit Price", SalesPrice."Unit Price");
    end;

    [Test]
    [HandlerFunctions('GetSalesPricePageHandler')]
    [Scope('OnPrem')]
    procedure SalesLineFactboxSalesPriceNotUpdatedInReleasedOrder()
    var
        SalesPrice: Record "Sales Price";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Order] [Sales Price] [Sales Line Factbox] [UI]
        // [SCENARIO 382356] It should not be possible to update sales price via Sales Line Factbox after releasing the sales order

        Initialize();
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 15.0)");

        // [GIVEN] Sales price "P" for item "I"
        CreateSalesPriceForItemAndAllCustomers(SalesPrice);

        // [GIVEN] Sales order "S" for item "I"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, SalesPrice."Item No.", LibraryRandom.RandInt(10));

        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        // [GIVEN] Release the sales order
        SalesOrder.Release.Invoke();

        // [WHEN] Drill down to sales prices from the Sales Line Factbox and try to update the sales price
        asserterror SalesOrder.Control1906127307.SalesPrices.DrillDown();

        // [THEN] Update fails with an error: "Status must be equal to Open in Sales Header"
        Assert.ExpectedTestFieldError(SalesHeader.FieldCaption(Status), Format(SalesHeader.Status::Open));
    end;

    [Test]
    [HandlerFunctions('GetPriceLinePageHandler')]
    [Scope('OnPrem')]
    procedure SalesLineFactboxPriceLineNotUpdatedInReleasedOrder()
    var
        SalesPrice: Record "Sales Price";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Order] [Best Price] [Sales Line Factbox] [UI]
        // [SCENARIO 382356] It should not be possible to update sales price via Sales Line Factbox after releasing the sales order

        Initialize();
        LibraryPriceCalculation.EnableExtendedPriceCalculation();
        LibraryPriceCalculation.SetupDefaultHandler("Price Calculation Handler"::"Business Central (Version 16.0)");

        // [GIVEN] Sales price "P" for item "I"
        CreateSalesPriceForItemAndAllCustomers(SalesPrice);

        // [GIVEN] Sales order "S" for item "I"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, SalesPrice."Item No.", LibraryRandom.RandInt(10));

        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        // [GIVEN] Release the sales order
        SalesOrder.Release.Invoke();

        // [WHEN] Drill down to sales prices from the Sales Line Factbox and try to update the sales price
        asserterror SalesOrder.Control1906127307.SalesPrices.DrillDown();

        // [THEN] Update fails with an error: "Status must be equal to Open in Sales Header"
        Assert.ExpectedTestFieldError(SalesHeader.FieldCaption(Status), Format(SalesHeader.Status::Open));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShippingTimeIsPopulatedOnValidatingSellToCustomerName()
    var
        Customer: Record Customer;
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 382419] Shipping Time should be populated with a value from Customer when Sell-to Customer Name is validated on Sales Header.
        Initialize();

        // [GIVEN] New customer. "No." = "X", "Shipping Time" = "T".
        CreateCustomerWithShippingTime(Customer);

        // [WHEN] Create new Sales Order and select "X" in "Sell-to Customer Name" field.
        SalesOrder.OpenNew();
        SalesOrder."Sell-to Customer Name".SetValue(Customer."No.");

        // [THEN] Shipping Time in the Sales Order is equal to "T".
        SalesOrder."Shipping Time".AssertEquals(Customer."Shipping Time");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShippingTimeIsPopulatedOnValidatingSellToCustomerNo()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 382419] Shipping Time should be populated with a value from Customer when Sell-to Customer No. is validated on Sales Header.
        Initialize();

        // [GIVEN] New customer. "No." = "X", "Shipping Time" = "T".
        CreateCustomerWithShippingTime(Customer);

        // [GIVEN] Sales Order.
        MockSalesOrder(SalesHeader);

        // [WHEN] Select "X" in "Sell-to Customer No." in the order.
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");

        // [THEN] Shipping Time in the Sales Order is equal to "T".
        SalesHeader.TestField("Shipping Time", Customer."Shipping Time");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReturnOrderPostedAsReceiveWhenReturnReceiptOnCrMemoOptionIsDisabled()
    var
        SalesHeader: Record "Sales Header";
        ReturnReceiptHeader: Record "Return Receipt Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ExpectedReturnReceiptNo: Code[20];
    begin
        // [FEATURE] [Return Order] [Return Receipt on Credit Memo]
        // [SCENARIO 382442] Return Order posted as "Receive" should have correct "Document No." according to "Return Receipt No. Series" and "Document Type" in associated Item Ledger Entry

        Initialize();
        SalesReceivablesSetup.Get();

        // [GIVEN] "Return Receipt on Credit Memo" = "No" in Sales Receivables Setup
        UpdateSalesSetup(false, SalesReceivablesSetup."Exact Cost Reversing Mandatory");

        // [GIVEN] Sales Return Order
        CreateSalesDocumentItem(SalesHeader, SalesHeader."Document Type"::"Return Order", LibraryInventory.CreateItemNo());

        // [GIVEN] Next number from no. series "Return Receipt No. Series" is "X"
        ExpectedReturnReceiptNo :=
          LibraryUtility.GetNextNoFromNoSeries(SalesHeader."Return Receipt No. Series", WorkDate());

        // [WHEN] Post Sales Return Order as "Receive"
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] The "No." of Posted Receipt is "X"
        ReturnReceiptHeader.SetRange("Bill-to Customer No.", SalesHeader."Bill-to Customer No.");
        ReturnReceiptHeader.FindFirst();
        ReturnReceiptHeader.TestField("No.", ExpectedReturnReceiptNo);

        // [THEN] "Document Type" in Item Ledger Entry of Return Receipt is "Sales Return Receipt"
        ItemLedgerEntry.SetRange("Document Type", ItemLedgerEntry."Document Type"::"Sales Return Receipt");
        ItemLedgerEntry.SetRange("Document No.", ExpectedReturnReceiptNo);
        Assert.RecordIsNotEmpty(ItemLedgerEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetShipmentLinesCalcsDiscountAndServiceChargeForShippedItemWithExtText()
    var
        Customer: Record Customer;
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        SalesHeaderOrder: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        SalesLineOrder: Record "Sales Line";
        TransferExtendedText: Codeunit "Transfer Extended Text";
        ItemNos: array[10] of Code[20];
    begin
        // [FEATURE] [Get Shipment Lines] [Invoice Discount] [Service Charge]
        // [SCENARIO 382519] Get Shipment Lines function run in sales invoice should calculate discounted amount of shipped item with extended text and make a service charge line.
        Initialize();

        // [GIVEN] "Calc. Inv. Discount" is set up to TRUE in Sales & Receivables Setup.
        LibrarySales.SetCalcInvDiscount(true);

        // [GIVEN] Customer "C" with invoice discount = "X" percent and service charge = "Y" LCY.
        LibrarySales.CreateCustomer(Customer);
        CreateInvDiscountForCustomer(CustInvoiceDisc, Customer."No.",
          LibraryRandom.RandDecInDecimalRange(10, 20, 2), LibraryRandom.RandDecInDecimalRange(10, 20, 2));

        // [GIVEN] Item "I" with extended text.
        ItemNos[1] := CreateItemAndExtendedText(false);

        // [GIVEN] Sales order "SO" for customer "C" and item "I".
        // [GIVEN] Invoice discount is calculated for "SO", sales line with service charge is added.
        CreateSalesOrderWithSeveralItemsAndCalcInvDiscount(SalesHeaderOrder, SalesLineOrder, Customer."No.", ItemNos, 1);

        // [GIVEN] Sales line with extended text for item "I" is added to the order.
        TransferExtendedText.SalesCheckIfAnyExtText(SalesLineOrder, true);
        TransferExtendedText.InsertSalesExtText(SalesLineOrder);

        // [GIVEN] "SO" is shipped.
        LibrarySales.PostSalesDocument(SalesHeaderOrder, true, false);

        // [GIVEN] Sales invoice "SI" for customer "C" is created.
        LibrarySales.CreateSalesHeader(SalesHeaderInvoice, SalesHeaderInvoice."Document Type"::Invoice, Customer."No.");

        // [WHEN] Get shipment lines for "SI".
        GetShipmentLinesForSalesInvoice(SalesHeaderInvoice, SalesHeaderOrder."No.");

        // [THEN] "SI" has one line with same item, amount and discount as "SO".
        VerifySalesInvoiceLinesAgainstSalesOrderLines(SalesHeaderOrder, SalesHeaderInvoice, 1);

        // [THEN] "SI" has one service charge line with Amount = "Y" LCY.
        VerifySalesLineWithServiceCharge(SalesHeaderInvoice, CustInvoiceDisc."Service Charge");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetShipmentLinesCalcsDiscountsAndServiceChargeForSeveralShippedItems()
    var
        Customer: Record Customer;
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        SalesHeaderOrder: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        SalesLineOrder: Record "Sales Line";
        ItemNos: array[10] of Code[20];
        NoOfItems: Integer;
        i: Integer;
    begin
        // [FEATURE] [Get Shipment Lines] [Invoice Discount] [Service Charge]
        // [SCENARIO 382519] Get Shipment lines function run in sales invoice should calculate discounted amounts of all shipped items and make only one service charge line.
        Initialize();

        // [GIVEN] "Calc. Inv. Discount" is set up to TRUE in Sales & Receivables Setup.
        LibrarySales.SetCalcInvDiscount(true);

        // [GIVEN] Customer "C" with invoice discount = "X" percent and service charge = "Y" LCY.
        LibrarySales.CreateCustomer(Customer);
        CreateInvDiscountForCustomer(CustInvoiceDisc, Customer."No.",
          LibraryRandom.RandDecInDecimalRange(10, 20, 2), LibraryRandom.RandDecInDecimalRange(10, 20, 2));

        // [GIVEN] Several items "I1".."I5".
        NoOfItems := LibraryRandom.RandIntInRange(2, 5);
        for i := 1 to NoOfItems do
            ItemNos[i] := LibraryInventory.CreateItemNo();

        // [GIVEN] Sales order "SO" for customer "C" and items "I1".."I5".
        // [GIVEN] Invoice discount is calculated for "SO", sales line with service charge is added.
        // [GIVEN] "SO" is shipped.
        CreateSalesOrderWithSeveralItemsAndCalcInvDiscount(SalesHeaderOrder, SalesLineOrder, Customer."No.", ItemNos, NoOfItems);
        LibrarySales.PostSalesDocument(SalesHeaderOrder, true, false);

        // [GIVEN] Sales invoice "SI" for customer "C" is created.
        LibrarySales.CreateSalesHeader(SalesHeaderInvoice, SalesHeaderInvoice."Document Type"::Invoice, Customer."No.");

        // [WHEN] Get shipment lines for "SI".
        GetShipmentLinesForSalesInvoice(SalesHeaderInvoice, SalesHeaderOrder."No.");

        // [THEN] "SI" has lines with same items, amounts and discounts as "SO".
        VerifySalesInvoiceLinesAgainstSalesOrderLines(SalesHeaderOrder, SalesHeaderInvoice, NoOfItems);

        // [THEN] "SI" has one service charge line with Amount = "Y" LCY.
        VerifySalesLineWithServiceCharge(SalesHeaderInvoice, CustInvoiceDisc."Service Charge");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetShipmentLinesCalcsDiscountsAndServiceChargeWhenDiscountsAreTurnedOnAfterShipment()
    var
        Customer: Record Customer;
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        SalesHeaderOrder: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        SalesLineOrder: Record "Sales Line";
        SalesLineInvoice: Record "Sales Line";
        ItemNos: array[10] of Code[20];
    begin
        // [FEATURE] [Get Shipment Lines] [Invoice Discount] [Service Charge]
        // [SCENARIO 382519] Get Shipment Lines function run in sales invoice should calculate discount for sales invoice if Calc. Inv. Discount setting was turned on after the sales order was shipped.
        Initialize();

        // [GIVEN] "Calc. Inv. Discount" is disabled in Sales & Receivables Setup.
        LibrarySales.SetCalcInvDiscount(false);

        // [GIVEN] Customer "C" with invoice discount = "X" percent and service charge = "Y" LCY.
        // [GIVEN] Item "I".
        LibrarySales.CreateCustomer(Customer);
        CreateInvDiscountForCustomer(CustInvoiceDisc, Customer."No.",
          LibraryRandom.RandDecInDecimalRange(10, 20, 2), LibraryRandom.RandDecInDecimalRange(10, 20, 2));
        ItemNos[1] := LibraryInventory.CreateItemNo();

        // [GIVEN] Shipped sales order "SO" for customer "C" and item "I".
        CreateSalesOrderWithSeveralItemsAndCalcInvDiscount(SalesHeaderOrder, SalesLineOrder, Customer."No.", ItemNos, 1);
        LibrarySales.PostSalesDocument(SalesHeaderOrder, true, false);

        // [GIVEN] "Calc. Inv. Discount" is enabled in Sales & Receivables Setup.
        LibrarySales.SetCalcInvDiscount(true);

        // [GIVEN] Sales invoice "SI" for customer "C" is created.
        LibrarySales.CreateSalesHeader(SalesHeaderInvoice, SalesHeaderInvoice."Document Type"::Invoice, Customer."No.");

        // [WHEN] Get shipment lines for "SI".
        GetShipmentLinesForSalesInvoice(SalesHeaderInvoice, SalesHeaderOrder."No.");

        // [THEN] "Inv. Discount Amount" is calculated on "SI" line.
        FindSalesLine(SalesLineInvoice, SalesHeaderInvoice."Document Type", SalesHeaderInvoice."No.", SalesLineInvoice.Type::Item);
        Assert.AreNearlyEqual(
          SalesLineInvoice.Quantity * SalesLineInvoice."Unit Price" * CustInvoiceDisc."Discount %" / 100,
          SalesLineInvoice."Inv. Discount Amount", LibraryERM.GetAmountRoundingPrecision(), InvDiscAmtInSalesInvErr);

        // [THEN] "SI" has one service charge line with Amount = "Y" LCY.
        VerifySalesLineWithServiceCharge(SalesHeaderInvoice, CustInvoiceDisc."Service Charge");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostShipSalesOrderAfterReleased()
    var
        Customer: Record Customer;
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [Invoice Discount]
        // [SCENARIO 210418] Posting of the Sales Order without errors after the Sales Order has been released.
        Initialize();

        // [GIVEN] Calc. Inv. Discount is TRUE at Sales & Receivables Setup.
        LibrarySales.SetCalcInvDiscount(true);

        // [GIVEN] Item "ITEM".
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Customer "CUST" with Invoice Discounts and Service Change.
        LibrarySales.CreateCustomer(Customer);
        CreateInvDiscountForCustomer(CustInvoiceDisc, Customer."No.",
          LibraryRandom.RandDecInDecimalRange(10, 20, 2), LibraryRandom.RandDecInDecimalRange(10, 20, 2));

        // [GIVEN] Sales Order "SO" created for "CUST" with an "ITEM" with Unit Price.
        CreateSalesDocumentWithUnitPrice(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.", SalesLine.Type::Item, Item."No.");

        // [GIVEN] "SO" is released.
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // [WHEN] "SO" Post invoked with "Shipped" selected.
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] "SO" posted (shipped) without errors.
        VerifySalesShptDocExists(SalesHeader."No.");
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocumentLinesHandler')]
    [Scope('OnPrem')]
    procedure GetPostedDocLinesFromSalesShipmentWithAutoExtText()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderRet: Record "Sales Header";
    begin
        // [FEATURE] [Extended Text]
        // [SCENARIO 215215] Extended Text Line is copied from Posted Sales Shipment using 'Get Posted Document Lines to Reverse' with Auto Ext Text
        Initialize();

        // [GIVEN] Sales order for Item with extended text is shipped.
        CreatePostSalesDocWithAutoExtText(SalesHeader, SalesHeader."Document Type"::Order, false);

        // [GIVEN] Sales Return Order is created.
        LibrarySales.CreateSalesHeader(SalesHeaderRet, SalesHeaderRet."Document Type"::"Return Order", SalesHeader."Sell-to Customer No.");

        // [WHEN] Run 'Get Posted Document Lines to Reverse' for posted shipment
        GetPostedDocLinesToReverse(SalesHeaderRet, OptionString::PostedShipments);

        // [THEN] Extended Text Line exits for Sales Return Order attached to item line
        VerifySalesLineDescriptionLineExists(SalesHeaderRet);
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocumentLinesHandler')]
    [Scope('OnPrem')]
    procedure GetPostedDocLinesFromSalesInvoiceWithAutoExtText()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderRet: Record "Sales Header";
    begin
        // [FEATURE] [Extended Text]
        // [SCENARIO 215215] Extended Text Line is copied from Posted Sales Invoice using 'Get Posted Document Lines to Reverse' with Auto Ext Text
        Initialize();

        // [GIVEN] Sales order for Item with extended text is shipped and invoiced.
        CreatePostSalesDocWithAutoExtText(SalesHeader, SalesHeader."Document Type"::Order, true);

        // [GIVEN] Sales Return Order for customer is created.
        LibrarySales.CreateSalesHeader(SalesHeaderRet, SalesHeaderRet."Document Type"::"Return Order", SalesHeader."Sell-to Customer No.");

        // [WHEN] Get Posted Doc Lines To Reverse for posted invoice
        GetPostedDocLinesToReverse(SalesHeaderRet, OptionString::PostedInvoices);

        // [THEN] Extended Text Line exits for Sales Return Order attached to item line
        VerifySalesLineDescriptionLineExists(SalesHeaderRet);
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocumentLinesHandler')]
    [Scope('OnPrem')]
    procedure GetPostedDocLinesFromSalesRetOrderWithAutoExtText()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderRet: Record "Sales Header";
    begin
        // [FEATURE] [Extended Text]
        // [SCENARIO 215215] Extended Text Line is copied from Posted Sales Return Order using 'Get Posted Document Lines to Reverse' with Auto Ext Text
        Initialize();

        // [GIVEN] Posted Sales return order for Item with extended text.
        CreatePostSalesDocWithAutoExtText(SalesHeader, SalesHeader."Document Type"::"Return Order", false);

        // [GIVEN] Sales Return Order is created.
        LibrarySales.CreateSalesHeader(SalesHeaderRet, SalesHeaderRet."Document Type"::"Return Order", SalesHeader."Sell-to Customer No.");

        // [WHEN] Run 'Get Posted Document Lines to Reverse' for posted return receipt
        GetPostedDocLinesToReverse(SalesHeaderRet, OptionString::PostedReturnReceipt);

        // [THEN] Extended Text Line exits for Sales Return Order attached to item line
        VerifySalesLineDescriptionLineExists(SalesHeaderRet);
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocumentLinesHandler')]
    [Scope('OnPrem')]
    procedure GetPostedDocLinesFromSalesCrMemoWithAutoExtText()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderRet: Record "Sales Header";
    begin
        // [FEATURE] [Extended Text]
        // [SCENARIO 215215] Extended Text Line is copied from Posted Credit Memo using 'Get Posted Document Lines to Reverse' with Auto Ext Text
        Initialize();

        // [GIVEN] Posted Sales credit memo for Item with extended text.
        CreatePostSalesDocWithAutoExtText(SalesHeader, SalesHeader."Document Type"::"Credit Memo", true);

        // [GIVEN] Sales Return Order for customer is created.
        LibrarySales.CreateSalesHeader(SalesHeaderRet, SalesHeaderRet."Document Type"::"Return Order", SalesHeader."Sell-to Customer No.");

        // [WHEN] Get Posted Doc Lines To Reverse for posted credit memo
        GetPostedDocLinesToReverse(SalesHeaderRet, OptionString::PostedCrMemo);

        // [THEN] Extended Text Line exits for Sales Return Order attached to item line
        VerifySalesLineDescriptionLineExists(SalesHeaderRet);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalseOnUpdateSalesLines')]
    [Scope('OnPrem')]
    procedure ConfirmationOnShipmentDateUpdateOnPrem()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [SaaS]
        // [SCENARIO 220730] Confirmation dialog to update Sales Lines shown when "Shipment Date" of Sales Order is updated in OnPrem environment.
        Initialize();

        // [GIVEN] Sales Order with a line.
        CreateSalesDocumentWithItem(SalesHeader, SalesHeader."Document Type"::Order);

        // [WHEN] Change Shipment date for the Sales Order.
        // [THEN] Confirmation dialog appears to update Sales Lines: verifyed by ConfirmHandlerFalseOnUpdateSalesLines.
        LibraryVariableStorage.Enqueue('You have modified Shipment Date.\\Do you want to update the lines?');
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder."Shipment Date".SetValue := WorkDate() + 1;
        SalesOrder.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerFalseOnUpdateSalesLines')]
    [Scope('OnPrem')]
    procedure ConfirmationOnShipmentAgentCodeUpdateOnPremAndSaas()
    var
        SalesHeader: Record "Sales Header";
        ShippingAgent: Record "Shipping Agent";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [SaaS]
        // [Old SCENARIO 220730] Confirmation dialog to update Sales Lines shown when "Shipping Agent Code" of Sales Order is updated in OnPrem environment.
        // [SCENARIO 351962] Confirmation dialog to update Sales Lines shown when "Shipping Agent Code" of Sales Order is updated in OnPrem and SaaS environment.
        Initialize();
        EnvironmentInfoTestLibrary.SetTestabilitySoftwareAsAService(false);

        // [GIVEN] Sales Order "SO" with a line.
        CreateSalesDocumentWithItem(SalesHeader, SalesHeader."Document Type"::Order);
        SalesHeader.SetHideValidationDialog(false);

        // [GIVEN] Shipping Agent record "SA".
        LibraryInventory.CreateShippingAgent(ShippingAgent);

        // [WHEN] Update "SO".Shipping Agent Code with "SA".Code.
        // [THEN] Confirmation dialog appears to update Sales Lines: verifyed by ConfirmHandlerFalseOnUpdateSalesLines.
        LibraryVariableStorage.Enqueue('You have modified Shipping Agent Code.\\Do you want to update the lines?');
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder."Shipping Agent Code".SetValue := ShippingAgent.Code;
        SalesOrder.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuote_ShipToContactEditable()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 223431] Ship-to Contact is editable in the Sales Quote page.
        Initialize();
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, Customer."No.");
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);
        Assert.IsTrue(SalesQuote."Ship-to Contact".Editable(), ShipToContactMustBeEditableErr);
        SalesQuote.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrder_ShipToContactEditable()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 223431] Ship-to Contact is editable in the Sales Order page.
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        Assert.IsTrue(SalesOrder."Ship-to Contact".Editable(), ShipToContactMustBeEditableErr);
        SalesOrder.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoice_ShipToContactEditable()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 223431] Ship-to Contact is editable in the Sales Invoice page.
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        Assert.IsTrue(SalesInvoice."Ship-to Contact".Editable(), ShipToContactMustBeEditableErr);
        SalesInvoice.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BlanketSalesOrder_ShipToContactEditable()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 223431] Ship-to Contact is editable in the Blanket Sales Order page.
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", Customer."No.");
        BlanketSalesOrder.OpenEdit();
        BlanketSalesOrder.GotoRecord(SalesHeader);
        Assert.IsTrue(BlanketSalesOrder."Ship-to Contact".Editable(), ShipToContactMustBeEditableErr);
        BlanketSalesOrder.Close();
    end;

    [Test]
    [HandlerFunctions('CreateEmptyPostedInvConfirmHandler')]
    [Scope('OnPrem')]
    procedure EmptyPostedDocCreationConfirmOnSalesHeaderDeletion()
    var
        SalesHeader: Record "Sales Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        // [FEATURE] [Invoice] [Deletion]
        // [SCENARIO 226743] If "Posted Invoice Nos." and "Invoice Nos." No. Series are the same, then on deletion of Sales Invoice before posting, then confirmation for creation of empty posted invoice must appear

        // [GIVEN] "Posted Invoice Nos." and "Invoice Nos." No. Series are the same
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Invoice Nos.", SalesReceivablesSetup."Posted Invoice Nos.");
        SalesReceivablesSetup.Modify(true);

        // [GIVEN] Sales Invoice with "No." = 1111
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Invoice);
        SalesHeader.Validate("Sell-to Customer No.", LibrarySales.CreateCustomerNo());
        SalesHeader.Insert(true);

        SalesHeader.Validate("Posting No. Series", SalesHeader."No. Series");
        SalesHeader.Modify(true);

        LibraryVariableStorage.Enqueue(StrSubstNo(ConfirmCreateEmptyPostedInvMsg, SalesHeader."No."));

        // [WHEN] Delete Sales Invoice
        SalesHeader.ConfirmDeletion();

        // [THEN] "Deleting this document will cause a gap in the number series for posted invoices. An empty posted invoice 1111 will be created" error appear
        // Checked within CreateEmptyPostedInvConfirmHandler
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateSalesLinesByNo_UT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 252750] Sales Lines can be updated using the SalesHeader.UpdateSalesLinesByNo method.
        Initialize();

        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));

        SalesHeader."Shipment Date" := LibraryRandom.RandDateFrom(WorkDate(), 100);
        SalesHeader.Modify(true);
        SalesHeader.UpdateSalesLinesByFieldNo(SalesHeader.FieldNo("Shipment Date"), false);

        SalesLine.Find();
        SalesLine.TestField("Shipment Date", SalesHeader."Shipment Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateSalesLines_UT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 252750] Sales Lines can be updated using the SalesHeader.UpdateSalesLines method.
        Initialize();

        CreateSalesDocument(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));

        SalesHeader."Shipment Date" := LibraryRandom.RandDateFrom(WorkDate(), 100);
        SalesHeader.Modify(true);
        SalesHeader.UpdateSalesLines(SalesHeader.FieldCaption("Shipment Date"), false);

        SalesLine.Find();
        SalesLine.TestField("Shipment Date", SalesHeader."Shipment Date");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DoNotModifyHeaderOnAutoCalcInvoiceDiscInLinesSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderOld: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Invoice Discount] [Order] [UI] [Document Totals]
        // [SCENARIO 254317] Do not modify Order when invoice discount is calculated on lines
        Initialize();

        // [GIVEN] "Sales & Receivables Setup" with "Calc. Inv. Discount" = TRUE
        LibrarySales.SetCalcInvDiscount(true);

        // [GIVEN] Customer "X" with Discount settings
        // [GIVEN] Sales Order "SO" for the customer "X" with a single line
        CreateSalesDocumentWithSingleLineWithQuantity(
          SalesHeader, SalesHeader."Document Type"::Order, LibraryRandom.RandIntInRange(10, 20));

        SalesHeader.TestField("Invoice Discount Value", 0);
        SalesHeaderOld := SalesHeader;

        // [WHEN] Open Sales Order page with "SO"
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        // [THEN] The "SO"."Invoice Discount Value" = 0 (remains unchanged)
        SalesHeader.Find();
        Assert.AreEqual(SalesHeaderOld."Invoice Discount Value", SalesHeader."Invoice Discount Value", InvoiceDiscountChangedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DoNotModifyHeaderOnAutoCalcInvoiceDiscInLinesSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderOld: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [Invoice Discount] [Invoice] [UI] [Document Totals]
        // [SCENARIO 254317] Do not modify Invoice when invoice discount is calculated on lines
        Initialize();

        // [GIVEN] "Sales & Receivables Setup" with "Calc. Inv. Discount" = TRUE
        LibrarySales.SetCalcInvDiscount(true);

        // [GIVEN] Customer "X" with Discount settings
        // [GIVEN] Sales Invoice "SI" for the customer "X" with a single line
        CreateSalesDocumentWithSingleLineWithQuantity(
          SalesHeader, SalesHeader."Document Type"::Invoice, LibraryRandom.RandIntInRange(10, 20));

        SalesHeader.TestField("Invoice Discount Value", 0);
        SalesHeaderOld := SalesHeader;

        // [WHEN] Open Sales Invoice card page with "SI"
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);

        // [THEN] The "SI"."Invoice Discount Value" = 0 (remains unchanged)
        SalesHeader.Find();
        Assert.AreEqual(SalesHeaderOld."Invoice Discount Value", SalesHeader."Invoice Discount Value", InvoiceDiscountChangedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DoNotModifyHeaderOnAutoCalcInvoiceDiscInLinesSalesQuote()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderOld: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [Invoice Discount] [Quote] [UI] [Document Totals]
        // [SCENARIO 254317] Do not modify Quote when invoice discount is calculated on lines
        Initialize();

        // [GIVEN] "Sales & Receivables Setup" with "Calc. Inv. Discount" = TRUE
        LibrarySales.SetCalcInvDiscount(true);

        // [GIVEN] Customer "X" with Discount settings
        // [GIVEN] Sales Quote "SQ" for the customer "X" with a single line
        CreateSalesDocumentWithSingleLineWithQuantity(
          SalesHeader, SalesHeader."Document Type"::Quote, LibraryRandom.RandIntInRange(10, 20));

        SalesHeader.TestField("Invoice Discount Value", 0);
        SalesHeaderOld := SalesHeader;

        // [WHEN] Open Sales Quote card page with "SQ"
        SalesQuote.OpenEdit();
        SalesQuote.GotoRecord(SalesHeader);

        // [THEN] The "SQ"."Invoice Discount Value" = 0 (remains unchanged)
        SalesHeader.Find();
        Assert.AreEqual(SalesHeaderOld."Invoice Discount Value", SalesHeader."Invoice Discount Value", InvoiceDiscountChangedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DoNotModifyHeaderOnAutoCalcInvoiceDiscInLinesSalesCreditMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderOld: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [Invoice Discount] [Credit Memo] [UI] [Document Totals]
        // [SCENARIO 254317] Do not modify Credit Memo when invoice discount is calculated on lines
        Initialize();

        // [GIVEN] "Sales & Receivables Setup" with "Calc. Inv. Discount" = TRUE
        LibrarySales.SetCalcInvDiscount(true);

        // [GIVEN] Customer "X" with Discount settings
        // [GIVEN] Sales Credit Memo "CrM" for the customer "X" with a single line
        CreateSalesDocumentWithSingleLineWithQuantity(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo", LibraryRandom.RandIntInRange(10, 20));

        SalesHeader.TestField("Invoice Discount Value", 0);
        SalesHeaderOld := SalesHeader;

        // [WHEN] Open Sales Credit Memo card page with "CrM"
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.GotoRecord(SalesHeader);

        // [THEN] The "CrM"."Invoice Discount Value" = 0 (remains unchanged)
        SalesHeader.Find();
        Assert.AreEqual(SalesHeaderOld."Invoice Discount Value", SalesHeader."Invoice Discount Value", InvoiceDiscountChangedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithPostedShipmentNegativeQty()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        // [FEATURE] [Shipment]
        // [SCENARIO 253750] Calculation of "Quantity Invoiced" and "Qty. Invoiced (Base)" in Posted Shipment when posting a sales with negative quantity
        Initialize();

        // [GIVEN] "Shipment on Invoice" = TRUE, "Exact Cost Reversing Mandatory" = FALSE in Sales Setup
        UpdateSalesSetupShipmentOnInvoice(true, false, false);

        // [GIVEN] Sales Invoice with second line where item "I" has Quantity = -1
        LibrarySales.CreateSalesInvoice(SalesHeader);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), -1);

        // [WHEN] Post Sales Invoice
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Sales Shipment Line with item "I" has "Quantity Invoiced" = "Qty. Invoiced (Base)" = -1
        // [THEN] "Qty. Shipped Not Invoiced" = 0
        SalesShipmentLine.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        SalesShipmentLine.SetRange("No.", SalesLine."No.");
        SalesShipmentLine.FindFirst();
        SalesShipmentLine.TestField("Quantity Invoiced", -1);
        SalesShipmentLine.TestField("Qty. Invoiced (Base)", -1);
        SalesShipmentLine.TestField("Qty. Shipped Not Invoiced", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoWithPostedShipmentNegativeQty()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        // [FEATURE] [Return Receipt]
        // [SCENARIO 257861] Calculation of "Quantity Invoiced" and "Qty. Invoiced (Base)" in Posted Return Receipt when posting credit memo with negative quantity
        Initialize();

        // [GIVEN] "Return Receipt on Credit Memo" = TRUE, "Exact Cost Reversing Mandatory" = FALSE in Sales Setup
        UpdateSalesSetupShipmentOnInvoice(false, true, false);

        // [GIVEN] Sales Credit Memo with second line where item "I" has Quantity = -1
        LibrarySales.CreateSalesCreditMemo(SalesHeader);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), -1);

        // [WHEN] Post Sales Credit Memo
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Sales Return Receipt Line with item "I" has "Quantity Invoiced" = "Qty. Invoiced (Base)" = -1
        // [THEN] "Return Qty. Rcd. Not Invd." = 0
        ReturnReceiptLine.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        ReturnReceiptLine.SetRange("No.", SalesLine."No.");
        ReturnReceiptLine.FindFirst();
        ReturnReceiptLine.TestField("Quantity Invoiced", -1);
        ReturnReceiptLine.TestField("Qty. Invoiced (Base)", -1);
        ReturnReceiptLine.TestField("Return Qty. Rcd. Not Invd.", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_GetPostedDocument_ReturnOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesPost: Codeunit "Sales-Post";
        RecVar: Variant;
    begin
        // [SCENARIO 260584] COD80.GetPostedDocumentRecords returns single filtered "Sales Cr.Memo Header" record for invoiced "Sales Header" with "Document Type" = "Return Order"
        Initialize();

        CreateSalesDocumentWithItem(SalesHeader, SalesHeader."Document Type"::"Return Order");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesPost.GetPostedDocumentRecord(SalesHeader, RecVar);

        VerifyRecRefSingleRecord(RecVar, DATABASE::"Sales Cr.Memo Header");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_SendPostedDocument_ReturnOrder()
    var
        SalesHeader: Record "Sales Header";
        DocumentSendingProfile: Record "Document Sending Profile";
        SalesPost: Codeunit "Sales-Post";
    begin
        // [SCENARIO 260584] Stan can call COD80.SendPostedDocumentRecord for invoice "Sales Header" with "Document Type" = "Return Order" without error "Unsupported Document Type"
        Initialize();

        CreateSalesDocumentWithItem(SalesHeader, SalesHeader."Document Type"::"Return Order");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        SalesPost.SendPostedDocumentRecord(SalesHeader, DocumentSendingProfile);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_GetPostedDocument_ReturnOrder_ShippedOnly()
    var
        SalesHeader: Record "Sales Header";
        SalesPost: Codeunit "Sales-Post";
        RecVar: Variant;
    begin
        // [SCENARIO 260584] COD80.GetPostedDocumentRecords returns single filtered "Return Receipt Header" record for shipped only "Sales Header" with "Document Type" = "Return Order"
        Initialize();

        CreateSalesDocumentWithItem(SalesHeader, SalesHeader."Document Type"::"Return Order");
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        RecVar := 0D;
        SalesPost.GetPostedDocumentRecord(SalesHeader, RecVar);

        VerifyRecRefSingleRecord(RecVar, Database::"Return Receipt Header");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_SendPostedDocument_ReturnOrder_ShippedOnly()
    var
        SalesHeader: Record "Sales Header";
        DocumentSendingProfile: Record "Document Sending Profile";
        SalesPost: Codeunit "Sales-Post";
    begin
        // [SCENARIO 260584] Stan can call COD80.SendPostedDocumentRecord for shipped only "Sales Header" with "Document Type" = "Return Order" without error "Unsupported Document Type"
        Initialize();

        CreateSalesDocumentWithItem(SalesHeader, SalesHeader."Document Type"::"Return Order");
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        SalesPost.SendPostedDocumentRecord(SalesHeader, DocumentSendingProfile);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure COD351_InsertSalesCreditMemoWithExistingLines()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Credit Memo]
        // [SCENARIO 261555] COD351.DefaultSalesDocuments handle "Purchase Header".INSERT event only when "RunTrigger" is TRUE
        Initialize();

        VerifyTransactionTypeWhenInsertSalesDocument(SalesHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure COD351_InsertSalesReturnOrderWithExistingLines()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Return Order]
        // [SCENARIO 261555] COD351.DefaultSalesDocuments handle "Purchase Header".INSERT event only when "RunTrigger" is TRUE
        Initialize();

        VerifyTransactionTypeWhenInsertSalesDocument(SalesHeader."Document Type"::"Return Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure COD351_InsertSalesInvoiceWithExistingLines()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Invoice]
        // [SCENARIO 261555] COD351.DefaultSalesDocuments handle "Purchase Header".INSERT event only when "RunTrigger" is TRUE
        Initialize();

        VerifyTransactionTypeWhenInsertSalesDocument(SalesHeader."Document Type"::Invoice);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure COD351_InsertSalesOrderWithExistingLines()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Order]
        // [SCENARIO 261555] COD351.DefaultSalesDocuments handle "Purchase Header".INSERT event only when "RunTrigger" is TRUE
        Initialize();

        VerifyTransactionTypeWhenInsertSalesDocument(SalesHeader."Document Type"::Order);
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocumentLinesHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoLineDiscountNotRecalculatedAfterReducingLineQty()
    var
        SalesLineDiscount: Record "Sales Line Discount";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Credit Memo] [Line Discount] [Get Document Lines to Reverse]
        // [SCEANRIO 258074] Line discount % in sales credit memo line is not recalculated if the line is copied from a posted invoice

        Initialize();
        PriceListLine.DeleteAll();

        // [GIVEN] Sales line discount 10% for item "I" and customer "C", minimum quantity is 20
        CreateSalesLineDiscount(
          SalesLineDiscount, LibraryInventory.CreateItemNo(), LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandIntInRange(10, 20), LibraryRandom.RandInt(10));
        CopyFromToPriceListLine.CopyFrom(SalesLineDiscount, PriceListLine);

        // [GIVEN] Sales order for customer "C", 20 pcs of item "I" are sold
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SalesLineDiscount."Sales Code");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, SalesLineDiscount.Code, SalesLineDiscount."Minimum Quantity");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Post the sales order
        SalesInvoiceHeader.SetRange("Order No.", SalesHeader."No.");
        SalesInvoiceHeader.FindFirst();

        // [GIVEN] Create a sales credit memo
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", SalesLineDiscount."Sales Code");
        LibraryVariableStorage.Enqueue(OptionString::PostedInvoices);

        // [WHEN] Run "Get Document Lines to Reverse" function to copy lines from the posted invoice
        SalesHeader.GetPstdDocLinesToReverse();
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst();

        // [THEN] Field "Copied From Posted Doc." in the credit memo line is set to TRUE
        SalesLine.TestField("Copied From Posted Doc.", true);

        // [WHEN] Change quantity in the credit memo line from 20 to 10
        SalesLine.Validate(Quantity, SalesLineDiscount."Minimum Quantity" / 2);

        // [THEN] Line discount % in the credit memo line remains 10
        SalesLine.TestField("Line Discount %", SalesLineDiscount."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreditMemoLineDiscountRecalculatedManuallyCreatedLine()
    var
        SalesLineDiscount: Record "Sales Line Discount";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Credit Memo] [Line Discount]
        // [SCEANRIO 258074] Line discount % in sales credit memo line is recalculated on validating quantity if the line is created manually
        Initialize();
        PriceListLine.DeleteAll();

        // [GIVEN] Sales line discount 10% for item "I" and customer "C", minimum quantity is 20
        CreateSalesLineDiscount(
          SalesLineDiscount, LibraryInventory.CreateItemNo(), LibrarySales.CreateCustomerNo(),
          LibraryRandom.RandIntInRange(10, 20), LibraryRandom.RandInt(10));
        CopyFromToPriceListLine.CopyFrom(SalesLineDiscount, PriceListLine);

        // [GIVEN] Sales credit memo for customer "C", 20 pcs of item "I"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", SalesLineDiscount."Sales Code");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, SalesLineDiscount.Code, 0);

        // [WHEN] Set "Quantity" = 20 in the credit memo line
        SalesLine.Validate(Quantity, SalesLineDiscount."Minimum Quantity");

        // [THEN] "Line Discount %" is 10
        SalesLine.TestField("Line Discount %", SalesLineDiscount."Line Discount %");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceQuoteNoIsNotVisibleWhenBlank()
    var
        SalesHeaderInvFromQuote: Record "Sales Header";
        SalesHeaderInvWithoutQuote: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [UI] [Invoice]
        // [SCENARIO 263847] "Quote No." must not be visible when switch from Sales Invoice with filled "Quote No." to one with blank

        Initialize();

        // [GIVEN] Sales Invoice "SI1" with filled "Quote No."
        CreateSalesInvoiceWithQuoteNo(SalesHeaderInvFromQuote);

        // [GIVEN] Sales Invoice "SI2" with blank "Quote No."
        LibrarySales.CreateSalesHeader(
          SalesHeaderInvWithoutQuote, SalesHeaderInvWithoutQuote."Document Type"::Invoice, LibrarySales.CreateCustomerNo());

        // [GIVEN] Sales Invoice page is openned for "SI1"
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeaderInvFromQuote);
        Assert.IsTrue(SalesInvoice."Quote No.".Visible(), QuoteNoMustBeVisibleErr);

        // [WHEN] Press Next to go to "SI2"
        SalesInvoice.Next();

        // [THEN] "Quote No." is not visible
        Assert.IsFalse(SalesInvoice."Quote No.".Visible(), QuoteNoMustNotBeVisibleErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoiceQuoteNoIsVisibleWhenFilled()
    var
        SalesHeaderInvFromQuote: Record "Sales Header";
        SalesHeaderInvWithoutQuote: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [UI] [Invoice]
        // [SCENARIO 263847] "Quote No." must be visible when switch from Sales Invoice with blank "Quote No." to one with filled

        Initialize();

        // [GIVEN] Sales Invoice "SI1" with filled "Quote No."
        CreateSalesInvoiceWithQuoteNo(SalesHeaderInvFromQuote);

        // [GIVEN] Sales Invoice "SI2" with blank "Quote No."
        LibrarySales.CreateSalesHeader(
          SalesHeaderInvWithoutQuote, SalesHeaderInvWithoutQuote."Document Type"::Invoice, LibrarySales.CreateCustomerNo());

        // [GIVEN] Sales Invoice page is openned for "SI2"
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeaderInvWithoutQuote);
        Assert.IsFalse(SalesInvoice."Quote No.".Visible(), QuoteNoMustNotBeVisibleErr);

        // [WHEN] Press PREVIOUS to go to "SI1"
        SalesInvoice.Previous();

        // [THEN] "Quote No." is visible
        Assert.IsTrue(SalesInvoice."Quote No.".Visible(), QuoteNoMustBeVisibleErr);
        SalesInvoice."Quote No.".AssertEquals(SalesHeaderInvFromQuote."Quote No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceCardWithBlankQuantityIsFoundationFALSE()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [Invoice] [UI]
        // [SCENARIO 266493] Stan can post sales invoice having line with zero quantity from card page when foundation setup is disabled
        Initialize();

        CreateSalesDocumentWithTwoLinesSecondLineQuantityZero(SalesHeader, SalesHeader."Document Type"::Invoice);
        Commit();

        SalesInvoice.OpenView();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice.Post.Invoke();

        asserterror SalesHeader.Find();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceListWithBlankQuantityIsFoundationFALSE()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceList: TestPage "Sales Invoice List";
    begin
        // [FEATURE] [Invoice] [UI]
        // [SCENARIO 266493] Stan can post sales invoice having line with zero quantity from list page when foundation setup is disabled
        Initialize();

        CreateSalesDocumentWithTwoLinesSecondLineQuantityZero(SalesHeader, SalesHeader."Document Type"::Invoice);
        Commit();

        SalesInvoiceList.OpenView();
        SalesInvoiceList.GotoRecord(SalesHeader);
        SalesInvoiceList.Post.Invoke();

        asserterror SalesHeader.Find();
    end;

    [Test]
    [HandlerFunctions('SalesQuoteRequestPageHandler,ConfirmHandlerTrueWithEnqueMessage')]
    [Scope('OnPrem')]
    procedure PrintSalesQuoteCardWithBlankQuantityIsFoundationFALSE()
    var
        CompanyInformation: Record "Company Information";
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [Quote] [UI]
        // [SCENARIO 266493] Stan can print sales quote having line with zero quantity from card page when foundation setup is disabled
        Initialize();

        // [GIVEN] Company Information with "Allow Blank Payment Info."
        CompanyInformation.Get();
        CompanyInformation.Validate("Allow Blank Payment Info.", true);
        CompanyInformation.Modify();

        CreateSalesDocumentWithTwoLinesSecondLineQuantityZero(SalesHeader, SalesHeader."Document Type"::Quote);
        Commit();

        LibraryVariableStorage.Enqueue(ConfirmZeroQuantityPostingMsg);
        LibraryVariableStorage.Enqueue(true);

        SalesQuote.OpenView();
        SalesQuote.GotoRecord(SalesHeader);
        SalesQuote.Print.Invoke();

        SalesHeader.Find();

        Assert.AreEqual(REPORT::"Standard Sales - Quote", LibraryVariableStorage.DequeueInteger(), WrongReportInvokedErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SalesQuoteRequestPageHandler,ConfirmHandlerTrueWithEnqueMessage')]
    [Scope('OnPrem')]
    procedure PrintSalesQuoteListWithBlankQuantityIsFoundationFALSE()
    var
        CompanyInformation: Record "Company Information";
        SalesHeader: Record "Sales Header";
        SalesQuotes: TestPage "Sales Quotes";
    begin
        // [FEATURE] [Quote] [UI]
        // [SCENARIO 266493] Stan can print sales quote having line with zero quantity from list page when foundation setup is disabled
        Initialize();

        // [GIVEN] Company Information with "Allow Blank Payment Info."
        CompanyInformation.Get();
        CompanyInformation.Validate("Allow Blank Payment Info.", true);
        CompanyInformation.Modify();

        CreateSalesDocumentWithTwoLinesSecondLineQuantityZero(SalesHeader, SalesHeader."Document Type"::Quote);
        Commit();

        LibraryVariableStorage.Enqueue(ConfirmZeroQuantityPostingMsg);
        LibraryVariableStorage.Enqueue(true);

        SalesQuotes.OpenView();
        SalesQuotes.GotoRecord(SalesHeader);
        SalesQuotes.Print.Invoke();

        SalesHeader.Find();

        Assert.AreEqual(REPORT::"Standard Sales - Quote", LibraryVariableStorage.DequeueInteger(), WrongReportInvokedErr);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostOrderStrMenuHandler,ConfirmHandlerTrueWithEnqueMessage')]
    [Scope('OnPrem')]
    procedure PostSalesOrderCardWithBlankQuantityIsFoundationFALSE()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Order] [UI]
        // [SCENARIO 266493] Stan can post sales order having line with zero quantity from card page when foundation setup is disabled
        Initialize();

        CreateSalesDocumentWithTwoLinesSecondLineQuantityZero(SalesHeader, SalesHeader."Document Type"::Order);
        CreateSalesDocumentWithTwoLinesSecondLineQuantityZero(SalesHeader, SalesHeader."Document Type"::Order);
        Commit();

        LibraryVariableStorage.Enqueue(ConfirmZeroQuantityPostingMsg);
        LibraryVariableStorage.Enqueue(true);

        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.Post.Invoke();

        SalesHeader.Find();
    end;

    [Test]
    [HandlerFunctions('PostOrderStrMenuHandler,ConfirmHandlerTrueWithEnqueMessage')]
    [Scope('OnPrem')]
    procedure PostSalesOrderListWithBlankQuantityIsFoundationFALSE()
    var
        SalesHeader: Record "Sales Header";
        SalesOrderList: TestPage "Sales Order List";
    begin
        // [FEATURE] [Order] [UI]
        // [SCENARIO 266493] Stan can post sales order having line with zero quantity from list page when foundation setup is disabled
        Initialize();

        CreateSalesDocumentWithTwoLinesSecondLineQuantityZero(SalesHeader, SalesHeader."Document Type"::Order);
        Commit();

        LibraryVariableStorage.Enqueue(ConfirmZeroQuantityPostingMsg);
        LibraryVariableStorage.Enqueue(true);

        SalesOrderList.OpenView();
        SalesOrderList.GotoRecord(SalesHeader);
        SalesOrderList.Post.Invoke();

        SalesHeader.Find();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostSalesCreditMemoCardWithBlankQuantityIsFoundationFALSE()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [Credit Memo] [UI]
        // [SCENARIO 266493] Stan can post sales credit memo having line with zero quantity from card page when foundation setup is disabled
        Initialize();

        CreateSalesDocumentWithTwoLinesSecondLineQuantityZero(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        Commit();

        SalesCreditMemo.OpenView();
        SalesCreditMemo.GotoRecord(SalesHeader);
        SalesCreditMemo.Post.Invoke();

        asserterror SalesHeader.Find();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostSalesCreditMemoListWithBlankQuantityIsFoundationFALSE()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemos: TestPage "Sales Credit Memos";
    begin
        // [FEATURE] [Credit Memo] [UI]
        // [SCENARIO 266493] Stan can post sales credit memo having line with zero quantity from list page when foundation setup is disabled
        Initialize();

        CreateSalesDocumentWithTwoLinesSecondLineQuantityZero(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        Commit();

        SalesCreditMemos.OpenView();
        SalesCreditMemos.GotoRecord(SalesHeader);
        SalesCreditMemos.Post.Invoke();

        asserterror SalesHeader.Find();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceCardWithBlankQuantityIsFoundationTRUE()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [Invoice] [UI] [Application Area]
        // [SCENARIO 266493] Stan can post sales invoice having line with zero quantity from card page when foundation setup is enabled
        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();

        CreateSalesDocumentWithTwoLinesSecondLineQuantityZero(SalesHeader, SalesHeader."Document Type"::Invoice);
        Commit();

        SalesInvoice.OpenView();
        SalesInvoice.GotoRecord(SalesHeader);
        asserterror SalesInvoice.Post.Invoke();

        Assert.ExpectedError(ZeroQuantityInLineErr);

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceListWithBlankQuantityIsFoundationTRUE()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceList: TestPage "Sales Invoice List";
    begin
        // [FEATURE] [Invoice] [UI] [Application Area]
        // [SCENARIO 266493] Stan can post sales invoice having line with zero quantity from list page when foundation setup is enabled
        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();

        CreateSalesDocumentWithTwoLinesSecondLineQuantityZero(SalesHeader, SalesHeader."Document Type"::Invoice);
        Commit();

        SalesInvoiceList.OpenView();
        SalesInvoiceList.GotoRecord(SalesHeader);
        asserterror SalesInvoiceList.Post.Invoke();

        Assert.ExpectedError(ZeroQuantityInLineErr);

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrintSalesQuoteCardWithBlankQuantityIsFoundationTRUE()
    var
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [Quote] [UI] [Application Area]
        // [SCENARIO 266493] Stan can print sales quote having line with zero quantity from card page when foundation setup is enabled
        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();

        CreateSalesDocumentWithTwoLinesSecondLineQuantityZero(SalesHeader, SalesHeader."Document Type"::Quote);
        Commit();

        SalesQuote.OpenView();
        SalesQuote.GotoRecord(SalesHeader);
        asserterror SalesQuote.Print.Invoke();

        Assert.ExpectedError(ZeroQuantityInLineErr);

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PrintSalesQuoteListWithBlankQuantityIsFoundationTRUE()
    var
        SalesHeader: Record "Sales Header";
        SalesQuotes: TestPage "Sales Quotes";
    begin
        // [FEATURE] [Quote] [UI] [Application Area]
        // [SCENARIO 266493] Stan can print sales quote having line with zero quantity from list page when foundation setup is enabled
        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();

        CreateSalesDocumentWithTwoLinesSecondLineQuantityZero(SalesHeader, SalesHeader."Document Type"::Quote);
        Commit();

        SalesQuotes.OpenView();
        SalesQuotes.GotoRecord(SalesHeader);
        asserterror SalesQuotes.Print.Invoke();

        Assert.ExpectedError(ZeroQuantityInLineErr);

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesOrderCardWithBlankQuantityIsFoundationTRUE()
    var
        SalesHeader: Record "Sales Header";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Order] [UI] [Application Area]
        // [SCENARIO 266493] Stan can post sales order having line with zero quantity from card page when foundation setup is enabled
        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();

        CreateSalesDocumentWithTwoLinesSecondLineQuantityZero(SalesHeader, SalesHeader."Document Type"::Order);
        Commit();

        SalesOrder.OpenView();
        SalesOrder.GotoRecord(SalesHeader);
        asserterror SalesOrder.Post.Invoke();

        Assert.ExpectedError(ZeroQuantityInLineErr);

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesOrderListWithBlankQuantityIsFoundationTRUE()
    var
        SalesHeader: Record "Sales Header";
        SalesOrderList: TestPage "Sales Order List";
    begin
        // [FEATURE] [Order] [UI] [Application Area]
        // [SCENARIO 266493] Stan can post sales order having line with zero quantity from list page when foundation setup is enabled
        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();

        CreateSalesDocumentWithTwoLinesSecondLineQuantityZero(SalesHeader, SalesHeader."Document Type"::Order);
        Commit();

        SalesOrderList.OpenView();
        SalesOrderList.GotoRecord(SalesHeader);
        asserterror SalesOrderList.Post.Invoke();

        Assert.ExpectedError(ZeroQuantityInLineErr);

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesCreditMemoCardWithBlankQuantityIsFoundationTRUE()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [Credit Memo] [UI] [Application Area]
        // [SCENARIO 266493] Stan can post sales credit memo having line with zero quantity from card page when foundation setup is enabled
        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();

        CreateSalesDocumentWithTwoLinesSecondLineQuantityZero(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        Commit();

        SalesCreditMemo.OpenView();
        SalesCreditMemo.GotoRecord(SalesHeader);
        asserterror SalesCreditMemo.Post.Invoke();

        Assert.ExpectedError(ZeroQuantityInLineErr);

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostSalesCreditMemoListWithBlankQuantityIsFoundationTRUE()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemos: TestPage "Sales Credit Memos";
    begin
        // [FEATURE] [Credit Memo] [UI] [Application Area]
        // [SCENARIO 266493] Stan can post sales credit memo having line with zero quantity from list page when foundation setup is enabled
        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();

        CreateSalesDocumentWithTwoLinesSecondLineQuantityZero(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        Commit();

        SalesCreditMemos.OpenView();
        SalesCreditMemos.GotoRecord(SalesHeader);
        asserterror SalesCreditMemos.Post.Invoke();

        Assert.ExpectedError(ZeroQuantityInLineErr);

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CreateSalesOrderWithDiffBillToCustomerAndSalesPriceSpecified()
    var
        BillToCustomer: Record Customer;
        SellToCustomer: Record Customer;
        Item: Record Item;
        SalesPrice: Record "Sales Price";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Order] [Sales Price] [Bill-to Customer]
        // [SCENARIO 301121] Unit Price in a Sales Doc with specified Bill-to Customer gets the price from existing Sales Price
        Initialize();
        PriceListLine.DeleteAll();

        // [GIVEN] Create Customers
        LibrarySales.CreateCustomer(BillToCustomer);
        LibrarySales.CreateCustomer(SellToCustomer);

        // [GIVEN] Create an Item with price
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandInt(100));
        Item.Modify(true);

        // [GIVEN] Create a Sales Price for the Item and Bill-to Customer
        LibrarySales.CreateSalesPrice(
          SalesPrice, Item."No.", SalesPrice."Sales Type"::Customer, BillToCustomer."No.",
          WorkDate(), '', '', '', 0, LibraryRandom.RandIntInRange(101, 200));
        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);

        // [GIVEN] Create a Sales Order for the Sell-to Customer and specify a different Bill-to Customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SellToCustomer."No.");
        SalesHeader.Validate("Bill-to Customer No.", BillToCustomer."No.");
        SalesHeader.Modify(true);

        // [WHEN] Create Sales Line for the document
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // [THEN] Unit price in the Sales Line corresponds to the price specified in the Sales Price
        SalesLine.TestField("Unit Price", SalesPrice."Unit Price");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroSalesPriceMustBeRespectedOverItemCardUnitPriceWhenCreatingSalesOrder()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesPrice: Record "Sales Price";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Order] [Sales Price]
        // [SCENARIO 269258] Zero sales price must be respected over price from item card when creating sales order

        Initialize();
        PriceListLine.DeleteAll();

        // [GIVEN] Create customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create item with price
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandInt(100));
        Item.Modify(true);

        // [GIVEN] Create zero sales price for the item - customer combination
        LibrarySales.CreateSalesPrice(
          SalesPrice, Item."No.", SalesPrice."Sales Type"::Customer, Customer."No.", WorkDate(), '', '', '', 0, 0);
        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);

        // [GIVEN] Create sales order for the customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [WHEN] Create sales line for the order with the item
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // [THEN] Unit price in the sales line is zero - same as in existing sales price
        SalesLine.TestField("Unit Price", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitPriceFromItemCardMustBeRespectedWhenCreatingSalesOrderIfSalesPriceNOTExist()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Order] [Sales Price]
        // [SCENARIO 269258] Unit price from item card must be respected if sales price doesn't exist when creating sales order

        Initialize();

        // [GIVEN] Create customer
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create item with price
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandInt(100));
        Item.Modify(true);

        // [GIVEN] Create sales order for the customer
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [WHEN] Create sales line for the order with the item
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // [THEN] Unit price in the sales line is equal to unit price from item card since sales price doesn't exist for the item
        SalesLine.TestField("Unit Price", Item."Unit Price");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateSalesOrderLineAutoCalcInvoiceDisc()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCalcDiscount: Codeunit "Sales-Calc. Discount";
    begin
        // [FEATURE] [Invoice Discount] [UT]
        // [SCENARIO 273796] COD60.CalculateInvoiceDiscountOnLine returns actual Sales Line
        Initialize();

        // [GIVEN] "Sales & Receivables Setup" with "Calc. Inv. Discount" = TRUE
        LibrarySales.SetCalcInvDiscount(true);

        // [GIVEN] Sales Order "SO" for the customer with a single line
        CreateSalesDocumentWithSingleLineWithQuantity(
          SalesHeader, SalesHeader."Document Type"::Order, LibraryRandom.RandIntInRange(10, 20));

        // [GIVEN] "Recalculate Invoice Disc." in Sales Line is equal to TRUE
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine.Type::Item);

        SalesLine.TestField("Recalculate Invoice Disc.");

        // [WHEN] Call COD60.CalculateInvoiceDiscountOnLine
        SalesCalcDiscount.CalculateInvoiceDiscountOnLine(SalesLine);

        // [THEN] "Recalculate Invoice Disc." in returned Sales Line is equal to FALSE
        SalesLine.TestField("Recalculate Invoice Disc.", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateSalesOrderLineAutoCalcInvoiceDiscTwoLines()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCalcDiscount: Codeunit "Sales-Calc. Discount";
        LineNo: Integer;
    begin
        // [FEATURE] [Invoice Discount] [UT]
        // [SCENARIO 276919] COD60.CalculateInvoiceDiscountOnLine returns updated initial Sales Line
        Initialize();

        // [GIVEN] "Sales & Receivables Setup" with "Calc. Inv. Discount" = TRUE
        LibrarySales.SetCalcInvDiscount(true);

        // [GIVEN] Sales Order with two lines
        CreateSalesDocumentWithSingleLineWithQuantity(
          SalesHeader, SalesHeader."Document Type"::Order, LibraryRandom.RandIntInRange(10, 20));
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, SalesLine."No.", LibraryRandom.RandIntInRange(10, 20));

        // [GIVEN] "Recalculate Invoice Disc." in Sales Line is equal to TRUE
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine.Type::Item);
        LineNo := SalesLine."Line No.";
        SalesLine.TestField("Recalculate Invoice Disc.");

        // [WHEN] Call COD60.CalculateInvoiceDiscountOnLine from first line with Line No. = 10000
        SalesCalcDiscount.CalculateInvoiceDiscountOnLine(SalesLine);

        // [THEN] Returned line has Line No matching to 10000
        // [THEN] "Recalculate Invoice Disc." in returned Sales Line is equal to FALSE
        SalesLine.TestField("Line No.", LineNo);
        SalesLine.TestField("Recalculate Invoice Disc.", false);
    end;

    [Test]
    [HandlerFunctions('PostAndSendConfirmationModalPageHandler,PostOrderWithChoiceStrMenuHandler,VerifyingConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostAndSendSalesOrderBackgroundPostingEnabled()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        LibraryReportSelection: Codeunit "Library - Report Selection";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Order] [Email] [Post] [Send] [Job Queue]
        // [SCENARIO 271849] Stan can Post and Send sales order when "Post with Job Queue" is activated in setup
        Initialize();

        // [GIVEN] "Post with Job Queue" is TRUE in sales setup
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryReportSelection);

        // [GIVEN] Sales order ready to post
        CreateSalesDocumentWithGL(SalesHeader, SalesHeader."Document Type"::Order);

        // [WHEN] Push "Post and Send" on sales order card page
        // [THEN] Selected to post "Ship and Invoice"
        // [THEN] Declined to download report of posted Sales Shipment
        LibraryVariableStorage.Enqueue(3); // Select Ship and Invocie in menu
        LibraryVariableStorage.Enqueue(ConfirmSendPostedShipmentQst);
        LibraryVariableStorage.Enqueue(false); // do not download report
        SalesHeader.SetRecFilter();
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.PostAndSend.Invoke();

        // [THEN] Stan can find posted invoice
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        Assert.RecordIsNotEmpty(SalesInvoiceHeader);

        // [THEN] Sales order is deleted
        SalesHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        Assert.RecordIsEmpty(SalesHeader);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PostAndSendConfirmationModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostAndSendSalesInvoiceBackgroundPostingEnabled()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        LibraryReportSelection: Codeunit "Library - Report Selection";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [Invoice] [Email] [Post] [Send] [Job Queue]
        // [SCENARIO 271849] Stan can Post and Send sales invoice when "Post with Job Queue" is activated in setup
        Initialize();

        // [GIVEN] "Post with Job Queue" is TRUE in sales setup
        LibrarySales.SetPostWithJobQueue(true);
        BindSubscription(LibraryReportSelection);

        // [GIVEN] Sales invoice ready to post
        CreateSalesDocumentWithGL(SalesHeader, SalesHeader."Document Type"::Invoice);

        // [WHEN] Push "Post and Send" on sales invoice card page
        SalesHeader.SetRecFilter();
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice.PostAndSend.Invoke();

        // [THEN] Stan can find posted invoice
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        Assert.RecordIsNotEmpty(SalesInvoiceHeader);

        // [THEN] Sales invoice is deleted
        SalesHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        Assert.RecordIsEmpty(SalesHeader);
    end;

    [Test]
    [HandlerFunctions('PostAndSendConfirmationModalPageHandler')]
    [Scope('OnPrem')]
    procedure PostAndSendSalesInvoiceWithPreviewTokenInPostingNo()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        LibraryReportSelection: Codeunit "Library - Report Selection";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [Invoice] [Email] [Post] [Send] [Job Queue]
        // [SCENARIO 271849] Stan can Post and Send sales invoice which has the 'Posting No.' set to ***
        Initialize();

        // [GIVEN] "Post with Job Queue" is FALSE in sales setup
        LibrarySales.SetPostWithJobQueue(false);
        BindSubscription(LibraryReportSelection);

        // [GIVEN] Sales invoice with *** in 'Posting No.' ready to post
        CreateSalesDocumentWithGL(SalesHeader, SalesHeader."Document Type"::Invoice);
        SalesHeader."Posting No." := PostingPreviewNoTok;
        SalesHeader.Modify();

        // [WHEN] Push "Post and Send" on sales invoice card page
        SalesHeader.SetRecFilter();
        SalesInvoice.OpenEdit();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice.PostAndSend.Invoke();

        // [THEN] Stan can find posted invoice
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        Assert.RecordIsNotEmpty(SalesInvoiceHeader);

        // [THEN] Sales invoice is deleted
        SalesHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        Assert.RecordIsEmpty(SalesHeader);
        Assert.AreNotEqual(SalesHeader."No.", PostingPreviewNoTok, '*** entry created.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceChangePricesInclVATRefreshesPage()
    var
        SalesHeader: Record "Sales Header";
        DocumentTotals: Codeunit "Document Totals";
        SalesInvoicePage: TestPage "Sales Invoice";
    begin
        // [FEATURE] [Invoice] [UI]
        // [SCENARIO 277993] User changes Prices including VAT, page refreshes and shows appropriate captions
        Initialize();

        // [GIVEN] Page with Prices including VAT disabled was open
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, '');
        SalesInvoicePage.OpenEdit();
        SalesInvoicePage.GotoRecord(SalesHeader);

        // [WHEN] User checks Prices including VAT
        SalesInvoicePage."Prices Including VAT".SetValue(true);

        // [THEN] Caption for TotalSalesLine."Line Amount" field is updated
        Assert.AreEqual(DocumentTotals.GetTotalLineAmountWithVATAndCurrencyCaption(SalesHeader."Currency Code", true),
          SalesInvoicePage.SalesLines."TotalSalesLine.""Line Amount""".Caption,
          'The caption for SalesInvoicePage.SalesLines.Control7 is incorrect');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderChangePricesInclVATRefreshesPage()
    var
        SalesHeader: Record "Sales Header";
        DocumentTotals: Codeunit "Document Totals";
        SalesOrderPage: TestPage "Sales Order";
    begin
        // [FEATURE] [Order] [UI]
        // [SCENARIO 277993] User changes Prices including VAT, page refreshes and shows appropriate captions
        Initialize();

        // [GIVEN] Page with Prices including VAT disabled was open
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesOrderPage.OpenEdit();
        SalesOrderPage.GotoRecord(SalesHeader);

        // [WHEN] User checks Prices including VAT
        SalesOrderPage."Prices Including VAT".SetValue(true);

        // [THEN] Caption for TotalSalesLine."Line Amount" field is updated
        Assert.AreEqual(DocumentTotals.GetTotalLineAmountWithVATAndCurrencyCaption(SalesHeader."Currency Code", true),
          SalesOrderPage.SalesLines."TotalSalesLine.""Line Amount""".Caption,
          'The caption for SalesOrderPage.SalesLines.Control35 is incorrect');
    end;

    [Test]
    [HandlerFunctions('PostOrderWithChoiceStrMenuHandler')]
    [Scope('OnPrem')]
    procedure PostSalesOrderWithPreviewTokenInPostingAndShippingNo()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        LibraryReportSelection: Codeunit "Library - Report Selection";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Invoice] [Email] [Post] [Send] [Job Queue]
        // [SCENARIO 271849] Stan can Post and Send sales order which has the 'Posting No.' and 'Shipping No.' set to ***
        Initialize();

        // [GIVEN] "Post with Job Queue" is FALSE in sales setup
        LibrarySales.SetPostWithJobQueue(false);
        BindSubscription(LibraryReportSelection);

        // [GIVEN] Sales invoice with *** in 'Posting No.' ready to post
        CreateSalesDocumentWithGL(SalesHeader, SalesHeader."Document Type"::Order);
        SalesHeader."Posting No." := PostingPreviewNoTok;
        SalesHeader."Shipping No." := PostingPreviewNoTok;
        SalesHeader.Modify();

        // [WHEN] Push "Post and Send" on sales invoice card page
        SalesHeader.SetRecFilter();
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        LibraryVariableStorage.Enqueue(3); // Select Ship and Invocie in menu
        SalesOrder.Post.Invoke();

        // [THEN] Stan can find posted invoice
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        Assert.RecordIsNotEmpty(SalesInvoiceHeader);

        // [THEN] Sales invoice is deleted
        SalesHeader.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        Assert.RecordIsEmpty(SalesHeader);
        Assert.AreNotEqual(SalesHeader."No.", PostingPreviewNoTok, '*** entry created.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesQuoteChangePricesInclVATRefreshesPage()
    var
        SalesHeader: Record "Sales Header";
        DocumentTotals: Codeunit "Document Totals";
        SalesQuotePage: TestPage "Sales Quote";
    begin
        // [FEATURE] [Quote] [UI]
        // [SCENARIO 277993] User changes Prices including VAT, page refreshes and shows appropriate captions
        Initialize();

        // [GIVEN] Page with Prices including VAT disabled was open
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, '');
        SalesQuotePage.OpenEdit();
        SalesQuotePage.GotoRecord(SalesHeader);

        // [WHEN] User checks Prices including VAT
        SalesQuotePage."Prices Including VAT".SetValue(true);

        // [THEN] Caption for TotalSalesLine."Line Amount" field is updated
        Assert.AreEqual(DocumentTotals.GetTotalLineAmountWithVATAndCurrencyCaption(SalesHeader."Currency Code", true),
          SalesQuotePage.SalesLines."Subtotal Excl. VAT".Caption,
          'The caption for SalesQuotePage.SalesLines."Subtotal Excl. VAT" is incorrect');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoChangePricesInclVATRefreshesPage()
    var
        SalesHeader: Record "Sales Header";
        DocumentTotals: Codeunit "Document Totals";
        SalesCreditMemoPage: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [Credit Memo] [UI]
        // [SCENARIO 277993] User changes Prices including VAT, page refreshes and shows appropriate captions
        Initialize();

        // [GIVEN] Page with Prices including VAT disabled was open
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", '');
        SalesCreditMemoPage.OpenEdit();
        SalesCreditMemoPage.GotoRecord(SalesHeader);

        // [WHEN] User checks Prices including VAT
        SalesCreditMemoPage."Prices Including VAT".SetValue(true);

        // [THEN] Caption for TotalSalesLine."Line Amount" field is updated
        Assert.AreEqual(DocumentTotals.GetTotalLineAmountWithVATAndCurrencyCaption(SalesHeader."Currency Code", true),
          SalesCreditMemoPage.SalesLines."TotalSalesLine.""Line Amount""".Caption,
          'The caption for SalesCreditMemoPage.SalesLines.Control27 is incorrect');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesReturnOrderChangePricesInclVATRefreshesPage()
    var
        SalesHeader: Record "Sales Header";
        SalesReturnOrderPage: TestPage "Sales Return Order";
    begin
        // [FEATURE] [Return Order] [UI]
        // [SCENARIO 277993] User changes Prices including VAT, page refreshes and shows appropriate captions
        Initialize();

        // [GIVEN] Page with Prices including VAT disabled was open
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '');
        SalesReturnOrderPage.OpenEdit();
        SalesReturnOrderPage.GotoRecord(SalesHeader);

        // [WHEN] User checks Prices including VAT
        SalesReturnOrderPage."Prices Including VAT".SetValue(true);

        // [THEN] Caption for TotalSalesLine."Line Amount" field is updated
        Assert.AreEqual('Unit Price Incl. VAT',
          SalesReturnOrderPage.SalesLines."Unit Price".Caption,
          'The caption for SalesReturnOrderPage.SalesLines."Unit Price" is incorrect');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesBlanketOrderChangePricesInclVATRefreshesPage()
    var
        SalesHeader: Record "Sales Header";
        BlanketSalesOrderPage: TestPage "Blanket Sales Order";
    begin
        // [FEATURE] [Blanket Order] [UI]
        // [SCENARIO 277993] User changes Prices including VAT, page refreshes and shows appropriate captions
        Initialize();

        // [GIVEN] Page with Prices including VAT disabled was open
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", '');
        BlanketSalesOrderPage.OpenEdit();
        BlanketSalesOrderPage.GotoRecord(SalesHeader);

        // [WHEN] User checks Prices including VAT
        BlanketSalesOrderPage."Prices Including VAT".SetValue(true);

        // [THEN] Caption for TotalSalesLine."Line Amount" field is updated
        Assert.AreEqual('Unit Price Incl. VAT',
          BlanketSalesOrderPage.SalesLines."Unit Price".Caption,
          'The caption for BlanketSalesOrderPage.SalesLines."Unit Price" is incorrect');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSalesArchiveWorkDescription()
    var
        SalesHeader: Record "Sales Header";
        SalesHeaderArchive: Record "Sales Header Archive";
        ArchiveManagement: Codeunit ArchiveManagement;
        WorkDescription: Text;
    begin
        // [FEATURE] [Sales] [Archive] [Work Description]
        // [SCENARIO] Sales Archive has field "Work Description" mirroring Sales Header when document is archived

        // [GIVEN] Sales Order with non-empty "Work Description"
        WorkDescription := LibraryRandom.RandText(10);
        CreateSalesDocumentWithItem(SalesHeader, SalesHeader."Document Type"::Order);
        SalesHeader.SetWorkDescription(WorkDescription);
        Assert.AreEqual(WorkDescription, SalesHeader.GetWorkDescription(), '');

        // [WHEN] Archive Sales Order
        ArchiveManagement.ArchSalesDocumentNoConfirm(SalesHeader);

        SalesHeaderArchive.SetRange("Document Type", SalesHeader."Document Type");
        SalesHeaderArchive.SetRange("No.", SalesHeader."No.");
        SalesHeaderArchive.FindLast();

        // [THEN] Sales Archive Header has correct "Work Description"
        Assert.AreEqual(SalesHeader.GetWorkDescription(), SalesHeaderArchive.GetWorkDescription(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostedSalesShipmentHeaderWorkDescription()
    var
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        WorkDescription: Text;
    begin
        // [FEATURE] [Shipment] [Post] [Work Description]
        // [SCENARIO 278008] Sales Shipment Header has field "Work Description" mirroring Sales Header

        // [GIVEN] Sales Order with non-empty "Work Description"
        WorkDescription := LibraryRandom.RandText(10);
        CreateSalesDocumentWithItem(SalesHeader, SalesHeader."Document Type"::Order);
        SalesHeader.SetWorkDescription(WorkDescription);
        Assert.AreEqual(WorkDescription, SalesHeader.GetWorkDescription(), '');

        // [WHEN] Post Sales Order with "Ship" option
        SalesShipmentHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, false));

        // [THEN] Posted Sales Shipment Header has correct "Work Description"
        Assert.AreEqual(SalesHeader.GetWorkDescription(), SalesShipmentHeader.GetWorkDescription(), '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPostedSalesCrMemoHeaderWorkDescription()
    var
        SalesHeader: Record "Sales Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        WorkDescription: Text;
    begin
        // [FEATURE] [Credit Memo] [Post] [Work Description]
        // [SCENARIO 278008] Sales Cr. Memo Header has field "Work Description" mirroring Sales Header

        // [GIVEN] Sales Cr. Memo with non-empty "Work Description"
        WorkDescription := LibraryRandom.RandText(10);
        CreateSalesDocumentWithItem(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        SalesHeader.SetWorkDescription(WorkDescription);
        Assert.AreEqual(WorkDescription, SalesHeader.GetWorkDescription(), '');

        // [WHEN] Post Sales Cr. Memo
        SalesCrMemoHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, false));

        // [THEN] Posted Sales Credit Memo has correct "Work Description"
        Assert.AreEqual(WorkDescription, SalesCrMemoHeader.GetWorkDescription(), '');
    end;

    [Test]
    [HandlerFunctions('MessageCaptureHandler')]
    [Scope('OnPrem')]
    procedure WarningMessageWhenPostingDateIsUpdatedWithoutCurrency()
    var
        SalesHeader: Record "Sales Header";
        MessageText: Text;
    begin
        // [FEATURE] [UT] [Message] [FCY]
        // [SCENARIO 282342] Warning message that Sales Lines were not updated do not unclude currency related text when currency is not used
        Initialize();

        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesHeader.Validate("Posting Date", WorkDate() + 1);

        MessageText := StrSubstNo(LinesNotUpdatedDateMsg, SalesHeader.FieldCaption("Posting Date"));
        MessageText := MessageText + ReviewLinesManuallyMsg;

        // A message is captured by MessageCaptureHandler
        Assert.ExpectedMessage(MessageText, LibraryVariableStorage.DequeueText());

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageCaptureHandler,ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure WarningMessageWhenPostingDateIsUpdatedWithCurrency()
    var
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        MessageText: Text;
    begin
        // [FEATURE] [UT] [Message] [FCY]
        // [SCENARIO 282342] Warning message that Sales Lines were not updated including currency related text when currency is applied
        Initialize();

        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));

        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesHeader.Validate("Currency Code", Currency.Code);
        SalesHeader.Validate("Posting Date", WorkDate() + 1);

        // A message is captured by MessageCaptureHandler
        MessageText := StrSubstNo(LinesNotUpdatedDateMsg, SalesHeader.FieldCaption("Posting Date"));
        MessageText := MessageText + ReviewLinesManuallyMsg;
        MessageText := StrSubstNo(SplitMessageTxt, MessageText, AffectExchangeRateMsg);
        Assert.ExpectedMessage(MessageText, LibraryVariableStorage.DequeueText());

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageCaptureHandler')]
    [Scope('OnPrem')]
    procedure WarningMessageWhenLanguageCodeIsUpdated()
    var
        SalesHeader: Record "Sales Header";
        MessageText: Text;
    begin
        // [FEATURE] [UT] [Message]
        // [SCENARIO 282342] Warning message that Sales Lines were not updated including text for manual update
        Initialize();

        LibrarySales.CreateSalesInvoice(SalesHeader);
        SalesHeader.Validate("Language Code", LibraryERM.GetAnyLanguageDifferentFromCurrent());

        MessageText := StrSubstNo(LinesNotUpdatedMsg, SalesHeader.FieldCaption("Language Code"));
        MessageText := StrSubstNo(SplitMessageTxt, MessageText, UpdateManuallyMsg);

        Assert.ExpectedMessage(MessageText, LibraryVariableStorage.DequeueText());

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SalespersonSalesStatisticsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalespersonSalesStatisticsReportTotals()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Resource: Record Resource;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        SalespersonPurchaser2: Record "Salesperson/Purchaser";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        RequestPageXML: Text;
        TotalsSalesLCY: Decimal;
        TotalsProfitLCY: Decimal;
    begin
        // [SCENARIO 422598] Report "Salesperson - Sales Statistics" should correctly represent Totals values
        Initialize();

        // [GIVEN] Item "I" with "Type" = "Service", Unit Cost = 60, Unit Price = 100
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandInt(100));
        Item.Validate("Unit Price", Item."Unit Cost" + LibraryRandom.RandInt(10));
        Item.Modify();

        // [GIVEN] Create customer "CUST" with Salesperson = "SP" with Commission % = 20
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        SalespersonPurchaser.Validate("Commission %", LibraryRandom.RandDec(20, 2));
        SalespersonPurchaser.Modify();
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Salesperson Code", SalespersonPurchaser.Code);
        Customer.Modify();

        // [GIVEN] Resource "R" with Unit Cost = 30, Unit Price = 100
        LibraryResource.CreateResource(Resource, Customer."VAT Bus. Posting Group");

        // [GIVEN] Create and post Sales Order for customer "CUST" with item "I" and Resource "RC"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Resource, Resource."No.", 1);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Create customer "CUST2" with Salesperson = "SP2" with a random Commission %
        Clear(Customer);
        LibrarySales.CreateSalesperson(SalespersonPurchaser2);
        SalespersonPurchaser2.Validate("Commission %", LibraryRandom.RandDec(20, 2));
        SalespersonPurchaser2.Modify();
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Salesperson Code", SalespersonPurchaser2.Code);
        Customer.Modify();

        // [GIVEN] Create and post Sales Order for customer "CUST2" with item "I" and Resource "RC2"
        Clear(SalesLine);
        Clear(SalesHeader);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Resource, Resource."No.", 1);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Cust. Ledger Entries for Salesperson "SP" and "SP2"
        CustLedgerEntry.SetFilter("Salesperson Code", '%1|%2', SalespersonPurchaser.Code, SalespersonPurchaser2.Code);
        CustLedgerEntry.CalcSums("Sales (LCY)", "Profit (LCY)");
        TotalsSalesLCY := CustLedgerEntry."Sales (LCY)";
        TotalsProfitLCY := CustLedgerEntry."Profit (LCY)";

        Commit();
        SalespersonPurchaser.SetFilter(Code, '%1|%2', SalespersonPurchaser.Code, SalespersonPurchaser2.Code);

        // [WHEN] Run report "Salesperson - Sales Statistics"
        RequestPageXML := Report.RunRequestPage(Report::"Salesperson - Sales Statistics", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(Report::"Salesperson - Sales Statistics", SalespersonPurchaser, RequestPageXML);

        // [THEN] Totals elements exist and their values match those in the associated "Cust. Ledger Entry" records for "CUST" & "CUST2"
        LibraryReportDataset.AssertElementWithValueExists('Totals_Sales', TotalsSalesLCY);
        LibraryReportDataset.AssertElementWithValueExists('Totals_Profit', TotalsProfitLCY);

        Clear(LibraryReportDataset);
    end;

    [Test]
    [HandlerFunctions('SalespersonCommissionRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalespersonCommissionReportAdjustedProfitLCY()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Resource: Record Resource;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        CustomerList: TestPage "Customer List";
        CustomerStatistics: TestPage "Customer Statistics";
        RequestPageXML: Text;
        AdjustedProfitLCY: Decimal;
    begin
        // [SCENARIO 422598] Report "Salesperson - Commission" should correctly calculate Adjusted Profit
        Initialize();

        // [GIVEN] Item "I" with "Type" = "Service", Unit Cost = 60, Unit Price = 100
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandInt(100));
        Item.Validate("Unit Price", Item."Unit Cost" + LibraryRandom.RandInt(10));
        Item.Modify();

        // [GIVEN] Create customer "CUST" with Salesperson = "SP"
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        Customer.Validate("Salesperson Code", SalespersonPurchaser.Code);
        Customer.Modify();

        // [GIVEN] Resource "R" with Unit Cost = 30, Unit Price = 100
        LibraryResource.CreateResource(Resource, Customer."VAT Bus. Posting Group");

        // [GIVEN] Create and post Sales Order for customer "CUST" with item "I" and Resource "RC"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Resource, Resource."No.", 1);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Open statistics for customer "CUST" is being opened, Adjusted Profit (LCY) = 110
        CustomerList.OpenView();
        CustomerList.FILTER.SetFilter("No.", SalesHeader."Sell-to Customer No.");
        CustomerStatistics.Trap();
        CustomerList.Statistics.Invoke();
        AdjustedProfitLCY := CustomerStatistics.ThisPeriodAdjustedProfitLCY.AsDecimal();

        Commit();
        SalespersonPurchaser.SetFilter(Code, SalespersonPurchaser.Code);

        // [WHEN] Run report "Salesperson - Commission"
        RequestPageXML := Report.RunRequestPage(Report::"Salesperson - Commission", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(Report::"Salesperson - Commission", SalespersonPurchaser, RequestPageXML);

        // [THEN] "Adjusted Profit (LCY)" value = 110.
        LibraryReportDataset.AssertElementWithValueExists('AdjProfit', AdjustedProfitLCY);
    end;

    [Test]
    [HandlerFunctions('SalespersonCommissionRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalespersonCommissionReportTotals()
    var
        Item: Record Item;
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Resource: Record Resource;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        SalesHeader2: Record "Sales Header";
        SalespersonPurchaser2: Record "Salesperson/Purchaser";
        CustomerList: TestPage "Customer List";
        CustomerStatistics: TestPage "Customer Statistics";
        RequestPageXML: Text;
        SubtotalsSalesLCY: Decimal;
        SubtotalsProfitLCY: Decimal;
        SubtotalsSalesLCY2: Decimal;
        SubtotalsProfitLCY2: Decimal;
    begin
        // [SCENARIO 422598] Report "Salesperson - Commission" should correctly represent Subtotals and Totals values
        Initialize();

        // [GIVEN] Item "I" with "Type" = "Service", Unit Cost = 60, Unit Price = 100
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Cost", LibraryRandom.RandInt(100));
        Item.Validate("Unit Price", Item."Unit Cost" + LibraryRandom.RandInt(10));
        Item.Modify();

        // [GIVEN] Create customer "CUST" with Salesperson = "SP" with Commission % = 20
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        SalespersonPurchaser.Validate("Commission %", LibraryRandom.RandDec(20, 2));
        SalespersonPurchaser.Modify();
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Salesperson Code", SalespersonPurchaser.Code);
        Customer.Modify();

        // [GIVEN] Resource "R" with Unit Cost = 30, Unit Price = 100
        LibraryResource.CreateResource(Resource, Customer."VAT Bus. Posting Group");

        // [GIVEN] Create and post Sales Order for customer "CUST" with item "I" and Resource "RC"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Resource, Resource."No.", 1);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Create customer "CUST2" with Salesperson = "SP2" with a random Commission %
        Clear(Customer);
        LibrarySales.CreateSalesperson(SalespersonPurchaser2);
        SalespersonPurchaser2.Validate("Commission %", LibraryRandom.RandDec(20, 2));
        SalespersonPurchaser2.Modify();
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Salesperson Code", SalespersonPurchaser2.Code);
        Customer.Modify();

        // [GIVEN] Create and post Sales Order for customer "CUST2" with item "I" and Resource "RC2"
        Clear(SalesLine);
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader2."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader2, SalesLine.Type::Item, Item."No.", 1);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader2, SalesLine.Type::Resource, Resource."No.", 1);
        LibrarySales.PostSalesDocument(SalesHeader2, true, true);

        // [GIVEN] View statistics for customer "CUST"
        CustomerList.OpenView();
        CustomerList.FILTER.SetFilter("No.", SalesHeader."Sell-to Customer No.");
        CustomerStatistics.Trap();
        CustomerList.Statistics.Invoke();
        SubtotalsSalesLCY := CustomerStatistics."CustSalesLCY[1]".AsDecimal();
        SubtotalsProfitLCY := CustomerStatistics.ThisPeriodOriginalProfitLCY.AsDecimal();

        // [GIVEN] View statistics for customer "CUST2"
        CustomerList.FILTER.SetFilter("No.", SalesHeader2."Sell-to Customer No.");
        CustomerStatistics.Trap();
        CustomerList.Statistics.Invoke();
        SubtotalsSalesLCY2 := CustomerStatistics."CustSalesLCY[1]".AsDecimal();
        SubtotalsProfitLCY2 := CustomerStatistics.ThisPeriodOriginalProfitLCY.AsDecimal();

        Commit();
        SalespersonPurchaser.SetFilter(Code, '%1|%2', SalespersonPurchaser.Code, SalespersonPurchaser2.Code);

        // [WHEN] Run report "Salesperson - Commission"
        RequestPageXML := Report.RunRequestPage(Report::"Salesperson - Commission", RequestPageXML);
        LibraryReportDataset.RunReportAndLoad(Report::"Salesperson - Commission", SalespersonPurchaser, RequestPageXML);

        // [THEN] Subtotals and Totals elements exist and their values match those generated by the "Customer Statistics" page 
        // and the associated "Cust. Ledger Entry" records for "CUST" & "CUST2" Subtotals "CUST"
        
        // Subtotals for "SP1"
        LibraryReportDataset.AssertElementWithValueExists('Subtotals_Salesperson_Code', SalespersonPurchaser.Code);
        LibraryReportDataset.AssertElementWithValueExists('Subtotals_Sales', SubtotalsSalesLCY);
        LibraryReportDataset.AssertElementWithValueExists('Subtotals_Profit', SubtotalsProfitLCY);
        // Subtotals for "SP2"
        LibraryReportDataset.AssertElementWithValueExists('Subtotals_Salesperson_Code', SalespersonPurchaser2.Code);
        LibraryReportDataset.AssertElementWithValueExists('Subtotals_Sales', SubtotalsSalesLCY2);
        LibraryReportDataset.AssertElementWithValueExists('Subtotals_Profit', SubtotalsProfitLCY2);
        // Totals
        LibraryReportDataset.AssertElementWithValueExists('Totals_Sales', (SubtotalsSalesLCY + SubtotalsSalesLCY2));
        LibraryReportDataset.AssertElementWithValueExists('Totals_Profit', (SubtotalsProfitLCY + SubtotalsProfitLCY2));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure SalespersonCodeClearedOnChangedCustomerWithoutSalesperson()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        // [FEATURE] [Salesperson Code]
        // [SCENARIO 297510] "Salesperson Code" cleared when "Sell-to Customer No." changed to Customer with blank "Salesperson Code"
        Initialize();

        // [GIVEN] Salesperson "SP01"
        LibrarySales.CreateSalesperson(SalespersonPurchaser);

        // [GIVEN] Customer "CU01" with "Salesperson Code" = "SP01"
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Salesperson Code", SalespersonPurchaser.Code);
        Customer.Modify(true);

        // [GIVEN] Sales Order Created for Customer "CU01"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        SalesHeader.TestField("Salesperson Code", SalespersonPurchaser.Code);

        // [GIVEN] Customer "CU02" with blank "Salesperson Code"
        LibrarySales.CreateCustomer(Customer);

        // [WHEN] Set "Sell-to Customer No."/"Bill-to Customer No." = "CU02" on Sales Order
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");

        // [THEN] "Salesperson Code" cleared on Sales Order
        SalesHeader.TestField("Salesperson Code", '');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure SalespersonCodeUpdatedOnChangedCustomerWithSalesperson()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        // [FEATURE] [Salesperson Code]
        // [SCENARIO 297510] "Salesperson Code" updated when "Sell-to Customer No." changed to Customer with non-blank "Salesperson Code"
        Initialize();

        // [GIVEN] Salesperson "SP01"
        LibrarySales.CreateSalesperson(SalespersonPurchaser);

        // [GIVEN] Customer "CU01" with blank "Salesperson Code"
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Sales Order Created for Customer "CU01"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [GIVEN] Customer "CU02" with "Salesperson Code" = "SP01"
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Salesperson Code", SalespersonPurchaser.Code);
        Customer.Modify(true);

        // [WHEN] Set "Sell-to Customer No."/"Bill-to Customer No." = "CU02" on Sales Order
        SalesHeader.Validate("Sell-to Customer No.", Customer."No.");

        // [THEN] "Salesperson Code" updated on Sales Order
        SalesHeader.TestField("Salesperson Code", SalespersonPurchaser.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalespersonCodeUpdatedFromUserSetupWhenCustomerWithoutSalesperson()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        UserSetup: Record "User Setup";
    begin
        // [FEATURE] [Salesperson Code]
        // [SCENARIO 297510] Customer with blank "Salesperson Code" and Salesperson Code empty - use Salesperson from UserSetup
        Initialize();

        // [GIVEN] Salesperson "SP01"
        LibrarySales.CreateSalesperson(SalespersonPurchaser);

        // [GIVEN] Customer "CU01" with blank "Salesperson Code"
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] User Setup with Salesperson Code
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        UserSetup.Validate("Salespers./Purch. Code", SalespersonPurchaser.Code);
        UserSetup.Modify(true);

        // [WHEN] Sales Order Created for Customer with blank "Salesperson Code"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [THEN] Sales Order has Salesperson Code "SP01"
        SalesHeader.TestField("Salesperson Code", SalespersonPurchaser.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalespersonCodeUpdatedFromCustomerWithSalesperson()
    var
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        UserSetup: Record "User Setup";
    begin
        // [FEATURE] [Salesperson Code]
        // [SCENARIO 297510] Customer with "Salesperson Code" but UserSetup Salesperson code empty - updated from Customer
        Initialize();

        // [GIVEN] Salesperson "SP01"
        LibrarySales.CreateSalesperson(SalespersonPurchaser);

        // [GIVEN] Customer "CU01" with "Salesperson Code" = "SP01"
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Salesperson Code", SalespersonPurchaser.Code);
        Customer.Modify(true);

        // [GIVEN] User Setup without Salesperson Code
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        UserSetup.Validate("Salespers./Purch. Code", '');
        UserSetup.Modify(true);

        // [WHEN] Sales Order Created for Customer with Salesperson Code "SP01"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [THEN] Sales Order has Salesperson Code "SP01"
        SalesHeader.TestField("Salesperson Code", SalespersonPurchaser.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure SalespersonCodeUpdatedFromUserSetupWhenChangingToCustomerWithoutSalesperson()
    var
        SalesHeader: Record "Sales Header";
        Customer: array[2] of Record Customer;
        SalespersonPurchaser: array[2] of Record "Salesperson/Purchaser";
        UserSetup: Record "User Setup";
    begin
        // [FEATURE] [Salesperson Code]
        // [SCENARIO ] Customer with blank "Salesperson Code" and Salesperson Code empty - use Salesperson from UserSetup.
        Initialize();

        // [GIVEN] Salespersons "SP01" and "SP02".
        LibrarySales.CreateSalesperson(SalespersonPurchaser[1]);
        LibrarySales.CreateSalesperson(SalespersonPurchaser[2]);

        // [GIVEN] Customer "CU01" with "Salesperson Code" = "SP01".
        LibrarySales.CreateCustomer(Customer[1]);
        Customer[1].Validate("Salesperson Code", SalespersonPurchaser[1].Code);
        Customer[1].Modify(true);

        // [GIVEN] Customer "CU02" with blank "Salesperson Code".
        LibrarySales.CreateCustomer(Customer[2]);

        // [GIVEN] User Setup with Salesperson Code "SP02.
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        UserSetup.Validate("Salespers./Purch. Code", SalespersonPurchaser[2].Code);
        UserSetup.Modify(true);

        // [GIVEN] Sales Order created for Customer with Salesperson Code "SP01".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer[1]."No.");

        // [WHEN] "Sell-to Customer No." is changed to Customer "CU02" in Sales Order.
        SalesHeader.Validate("Sell-to Customer No.", Customer[2]."No.");

        // [THEN] Sales Order has Salesperson Code "SP02".
        SalesHeader.TestField("Salesperson Code", SalespersonPurchaser[2].Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesOrderInvalidTaxAreaCode()
    var
        SalesHeader: Record "Sales Header";
        TaxAreaCode: Code[20];
    begin
        // [FEATURE] [Sales Tax]
        // [SCENARIO 301913] "Tax Area Code" field on Sales Header is validated against "Tax Area"
        Initialize();

        // [GIVEN] Sales Header created
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());

        // [WHEN] Validate "Tax Area Code" to non-existing value "TAC01" on Sales Header
        TaxAreaCode := LibraryUtility.GenerateGUID();
        asserterror SalesHeader.Validate("Tax Area Code", TaxAreaCode);

        // [THEN] Error: "The Tax Area does not exist. Identification fields and values: Code='TAC01'."
        Assert.ExpectedErrorCode('DB:RecordNotFound');
        Assert.ExpectedErrorCannotFind(Database::"Tax Area", TaxAreaCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TaxAreaCodeBlankOnCustomerNotModifiedOnHeaderValidation()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        TaxArea: Record "Tax Area";
    begin
        // [FEATURE] [Sales Tax]
        // [SCENARIO 300856] Non-empty "Tax Area Code" validated on Sales Header doesn't change Customer's blank "Tax Area Code"
        Initialize();

        // [GIVEN] Customer with blank "Tax Area Code"
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Tax Area Code", '');
        Customer.Modify(true);

        // [GIVEN] Sales Header created
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [GIVEN] Tax Area "TA01" created
        LibraryERM.CreateTaxArea(TaxArea);

        // [WHEN] Validate "Tax Area Code" to "TA01" on Sales Header
        SalesHeader.Validate("Tax Area Code", TaxArea.Code);
        SalesHeader.Modify(true);

        // [THEN] Customer's "Tax Area Code" is not modified
        Customer.Find();
        Customer.TestField("Tax Area Code", '');
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocumentLinesHandler')]
    [Scope('OnPrem')]
    procedure CreditMemoPriceRecalculatedCopiedFromPostedLine()
    var
        SalesPrice: Record "Sales Price";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PriceListLine: Record "Price List Line";
    begin
        // [FEATURE] [Credit Memo] [Sales Price] [Get Document Lines to Reverse]
        // [SCENARIO 304556] Message appears about recalculated Unit Price on Credit type Sales Line copied from posted document
        Initialize();
        PriceListLine.DeleteAll();

        // [GIVEN] Sales Price 10 for item "I" and customer "C", minimum quantity is 0
        LibrarySales.CreateSalesPrice(
          SalesPrice, LibraryInventory.CreateItemNo(), SalesPrice."Sales Type"::Customer, LibrarySales.CreateCustomerNo(),
          WorkDate(), '', '', '', 0, LibraryRandom.RandInt(100));

        // [GIVEN] Sales Price 8 for item "I" and customer "C", minimum quantity is 20
        LibrarySales.CreateSalesPrice(
          SalesPrice, SalesPrice."Item No.", SalesPrice."Sales Type", SalesPrice."Sales Code",
          WorkDate(), '', '', '', LibraryRandom.RandIntInRange(10, 20), LibraryRandom.RandDec(SalesPrice."Unit Price", 2));
        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);

        // [GIVEN] Sales order for customer "C", 20 pcs of item "I" are sold
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SalesPrice."Sales Code");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, SalesPrice."Item No.", SalesPrice."Minimum Quantity");

        // [GIVEN] Post the sales order
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        SalesInvoiceHeader.SetRange("Order No.", SalesHeader."No.");
        SalesInvoiceHeader.FindFirst();

        // [GIVEN] Create a sales credit memo
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", SalesPrice."Sales Code");
        LibraryVariableStorage.Enqueue(OptionString::PostedInvoices);

        // [GIVEN] Run "Get Document Lines to Reverse" function to copy lines from the posted invoice
        SalesHeader.GetPstdDocLinesToReverse();
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine.Type::Item);
        SalesLine.TestField("Copied From Posted Doc.", true);

        // [WHEN] Change quantity in the credit memo line from 20 to 10
        SalesLine.Validate(Quantity, SalesPrice."Minimum Quantity" / 2);

        // [THEN] "Unit Price" is still 10 (TFS ID: 365623)
        SalesLine.TestField("Unit Price", SalesPrice."Unit Price");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreditMemoPriceRecalculatedManuallyCreatedLine()
    var
        SalesPrice: Record "Sales Price";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PriceListLine: Record "Price List Line";
        ZeroQuantityPrice: Decimal;
    begin
        // [FEATURE] [Credit Memo] [Sales Price]
        // [SCENARIO 304556] Unit Price in Sales Credit Memo line is recalculated without messages if the line is created manually
        Initialize();
        PriceListLine.DeleteAll();

        // [GIVEN] Sales Price 10 for item "I" and customer "C", minimum quantity is 0
        LibrarySales.CreateSalesPrice(
          SalesPrice, LibraryInventory.CreateItemNo(), "Sales Price Type"::Customer, LibrarySales.CreateCustomerNo(),
          WorkDate(), '', '', '', 0, LibraryRandom.RandInt(100));
        ZeroQuantityPrice := SalesPrice."Unit Price";

        // [GIVEN] Sales Price 8 for item "I" and customer "C", minimum quantity is 20
        LibrarySales.CreateSalesPrice(
          SalesPrice, SalesPrice."Item No.", SalesPrice."Sales Type", SalesPrice."Sales Code",
          WorkDate(), '', '', '', LibraryRandom.RandIntInRange(10, 20), LibraryRandom.RandDec(SalesPrice."Unit Price", 2));
        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);

        // [GIVEN] Sales credit memo for customer "C", 20 pcs of item "I" (Unit Price = 8)
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", SalesPrice."Sales Code");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, SalesPrice."Item No.", SalesPrice."Minimum Quantity");
        SalesLine.TestField("Unit Price", SalesPrice."Unit Price");

        // [WHEN] Set "Quantity" = 10 in the credit memo line
        SalesLine.Validate(Quantity, SalesPrice."Minimum Quantity" / 2);

        // [THEN] "Unit Price" is 10
        SalesLine.TestField("Unit Price", ZeroQuantityPrice);

        // [THEN] No message appears
    end;

    [Test]
    [HandlerFunctions('ItemSubstitutionEntriesHandler')]
    [Scope('OnPrem')]
    procedure ItemSubstituionDoesntInsertExtTextWhenAutoExtTextIsFalse()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        // [FEATURE] [Extended Text] [Item Substitution] [UT] [UI]
        // [SCENARIO 328989] No extended text is added when item is substituted by item with "Automatic Ext. Texts" set to False.
        Initialize();
        LibraryNotificationMgt.DisableMyNotification(ItemCheckAvail.GetItemAvailabilityNotificationId());

        // [GIVEN] Item "I1" and it's substitution Item "I2" with Extended text and "Automatic Ext. Texts" set to False.
        LibraryInventory.CreateItem(Item);
        CreateItemSubstitutionWithExtendedText(Item."No.", false);

        // [GIVEN] Sales Header with Sales Line with "I1".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [WHEN] Show Item Sub is called and suggested Item substitution is accepted.
        SalesLine.ShowItemSub();

        // [THEN] No extended text is added.
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::" ");
        Assert.RecordIsEmpty(SalesLine);
    end;

    [Test]
    [HandlerFunctions('ItemSubstitutionEntriesHandler')]
    [Scope('OnPrem')]
    procedure ItemSubstituionDoesntInsertExtTextWhenAutoExtTextIsTrue()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemCheckAvail: Codeunit "Item-Check Avail.";
    begin
        // [FEATURE] [Extended Text] [Item Substitution] [UT] [UI]
        // [SCENARIO 328989] Extended text is added when item is substituted by item with "Automatic Ext. Texts" set to True.
        Initialize();
        LibraryNotificationMgt.DisableMyNotification(ItemCheckAvail.GetItemAvailabilityNotificationId());

        // [GIVEN] Item "I1" and it's substitution Item "I2" with Extended text and "Automatic Ext. Texts" set to True.
        LibraryInventory.CreateItem(Item);
        CreateItemSubstitutionWithExtendedText(Item."No.", true);

        // [GIVEN] Sales Header with Sales Line with "I1".
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);

        // [WHEN] Show Item Sub is called and suggested Item substitution is accepted.
        SalesLine.ShowItemSub();

        // [THEN] Extended text is added.
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::" ");
        Assert.RecordIsNotEmpty(SalesLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetFullDocTypeName()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO] Get full document type and name
        // [GIVEN] Sales Header of type "Quote"
        SalesHeader."Document Type" := SalesHeader."Document Type"::Quote;

        // [WHEN] GetFullDocTypeTxt is called
        // [THEN] 'Sales Quote' is returned
        Assert.AreEqual('Sales Quote', SalesHeader.GetFullDocTypeTxt(), 'The expected full document type is incorrect');

        // [GIVEN] Sales Header of type "Order"
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;

        // [WHEN] GetFullDocTypeTxt is called
        // [THEN] 'Sales Order' is returned
        Assert.AreEqual('Sales Order', SalesHeader.GetFullDocTypeTxt(), 'The expected full document type is incorrect');

        // [GIVEN] Sales Header of type "Invoice"
        SalesHeader."Document Type" := SalesHeader."Document Type"::Invoice;

        // [WHEN] GetFullDocTypeTxt is called
        // [THEN] 'Sales Invoice' is returned
        Assert.AreEqual('Sales Invoice', SalesHeader.GetFullDocTypeTxt(), 'The expected full document type is incorrect');

        // [GIVEN] Sales Header of type "Credit Memo"
        SalesHeader."Document Type" := SalesHeader."Document Type"::"Credit Memo";

        // [WHEN] GetFullDocTypeTxt is called
        // [THEN] 'Sales Credit Memo' is returned
        Assert.AreEqual('Sales Credit Memo', SalesHeader.GetFullDocTypeTxt(), 'The expected full document type is incorrect');

        // [GIVEN] Sales Header of type "Blanket Order"
        SalesHeader."Document Type" := SalesHeader."Document Type"::"Blanket Order";

        // [WHEN] GetFullDocTypeTxt is called
        // [THEN] 'Sales Blanket Order' is returned
        Assert.AreEqual('Sales Blanket Order', SalesHeader.GetFullDocTypeTxt(), 'The expected full document type is incorrect');

        // [GIVEN] Sales Header of type "Return Order"
        SalesHeader."Document Type" := SalesHeader."Document Type"::"Return Order";

        // [WHEN] GetFullDocTypeTxt is called
        // [THEN] 'Sales Return Order' is returned
        Assert.AreEqual('Sales Return Order', SalesHeader.GetFullDocTypeTxt(), 'The expected full document type is incorrect');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure PostSalesCreditMemoCardWithBlankQuantityIsFoundationTRUEWithConfirmPosting()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [Credit Memo] [UI] [Application Area]
        // [SCENARIO 339576] User can post sales credit memo having line with zero quantity from card page when foundation setup is enabled
        Initialize();

        // [GIVEN] Foundation Setup was enabled
        LibraryApplicationArea.EnableFoundationSetup();

        // [GIVEN] Credit Memo was created, having line with zero quantity
        CreateSalesDocumentWithTwoLinesSecondLineQuantityZero(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        Commit();

        // [WHEN] Post CreditMemo from "Sales Credit Memo" Card
        SalesCreditMemo.OpenView();
        SalesCreditMemo.GotoRecord(SalesHeader);
        SalesCreditMemo.Post.Invoke();

        // [THEN] CreditMemo is posted successfully
        SalesHeader.SetRecFilter();
        Assert.RecordIsEmpty(SalesHeader);

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure PostSalesCreditMemoListWithBlankQuantityIsFoundationTRUEWithConfirmPosting()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemos: TestPage "Sales Credit Memos";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        // [FEATURE] [Credit Memo] [UI] [Application Area]
        // [SCENARIO 266493] User can post sales credit memo having line with zero quantity from list page when foundation setup is enabled
        Initialize();

        // [GIVEN] Foundation Setup was enabled
        LibraryApplicationArea.EnableFoundationSetup();

        // [GIVEN] Credit Memo was created, having line with zero quantity
        CreateSalesDocumentWithTwoLinesSecondLineQuantityZero(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        Commit();

        // [WHEN] Post CreditMemo from "Sales Credit Memos" List
        PostedSalesCreditMemo.Trap();
        SalesCreditMemos.OpenView();
        SalesCreditMemos.GotoRecord(SalesHeader);
        SalesCreditMemos.Post.Invoke();
        PostedSalesCreditMemo.Close();

        // [THEN] CreditMemo is posted successfully
        SalesHeader.SetRecFilter();
        Assert.RecordIsEmpty(SalesHeader);

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerTrueWithEnqueMessage')]
    procedure PostSalesCreditMemoCardWithBlankQuantityIsFoundationWithoutConfirmation()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [Credit Memo] [UI] [Application Area]
        // [SCENARIO 339576] User can show confirm massage during post sales credit memo having line with zero quantity from card page when foundation setup is enabled
        Initialize();

        // [GIVEN] Foundation Setup was enabled
        LibraryApplicationArea.EnableFoundationSetup();

        // [GIVEN] Credit Memo was created, having line with zero quantity
        CreateSalesDocumentWithTwoLinesSecondLineQuantityZero(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        Commit();

        LibraryVariableStorage.Enqueue(ConfirmZeroQuantityPostingMsg);
        LibraryVariableStorage.Enqueue(false);

        // [WHEN] Post CreditMemo from "Sales Credit Memo" Card
        SalesCreditMemo.OpenView();
        SalesCreditMemo.GotoRecord(SalesHeader);
        SalesCreditMemo.Post.Invoke();

        // [THEN] The Confirm and Error message was shown
        //Assert.ExpectedError(ConfirmZeroQuantityPostingMsg);

        // [THEN] CreditMemo is not posted
        SalesHeader.SetRecFilter();
        Assert.RecordIsNotEmpty(SalesHeader);

        LibraryApplicationArea.DisableApplicationAreaSetup();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerTrueWithEnqueMessage')]
    procedure PostSalesOrderCardWithBlankQuantityConfirmation()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [Sales Invoice] [UI] [Application Area]
        // [SCENARIO 339576] User can show confirm massage during post sales invoice having line with zero quantity from card page when foundation setup is enabled
        Initialize();

        // [GIVEN] Sales Invoice was created, having line with zero quantity
        CreateSalesDocumentWithTwoLinesSecondLineQuantityZero(SalesHeader, SalesHeader."Document Type"::Invoice);
        Commit();

        LibraryVariableStorage.Enqueue(ConfirmZeroQuantityPostingMsg);
        LibraryVariableStorage.Enqueue(false);

        // [WHEN] Post Invoice from "Sales Invoice" Card
        SalesInvoice.OpenView();
        SalesInvoice.GotoRecord(SalesHeader);
        SalesInvoice.Post.Invoke();

        // [THEN] The Confirm and Error message was shown
        //Assert.ExpectedError(ConfirmZeroQuantityPostingMsg);

        // [THEN] Sales Invoice is not posted
        SalesHeader.SetRecFilter();
        Assert.RecordIsNotEmpty(SalesHeader);

        //LibraryApplicationArea.DisableApplicationAreaSetup();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerTrueWithEnqueMessage')]
    procedure PostSalesReturnOrderCardWithBlankQuantityConfirmation()
    var
        SalesHeader: Record "Sales Header";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // [FEATURE] [Credit Memo] [UI] [Application Area]
        // [SCENARIO 339576] User can show confirm massage during post sales credit memo having line with zero quantity from card page when foundation setup is enabled
        Initialize();

        // [GIVEN] Sales Invoice was created, having line with zero quantity
        CreateSalesDocumentWithTwoLinesSecondLineQuantityZero(SalesHeader, SalesHeader."Document Type"::"Return Order");
        Commit();

        LibraryVariableStorage.Enqueue(ConfirmZeroQuantityPostingMsg);
        LibraryVariableStorage.Enqueue(false);

        // [WHEN] Post CreditMemo from "Sales Credit Memo" Card
        SalesReturnOrder.OpenView();
        SalesReturnORder.GotoRecord(SalesHeader);
        SalesReturnOrder.Post.Invoke();

        // [THEN] The Confirm and Error message was shown
        //Assert.ExpectedError(ConfirmZeroQuantityPostingMsg);

        // [THEN] CreditMemo is not posted
        SalesHeader.SetRecFilter();
        Assert.RecordIsNotEmpty(SalesHeader);

        //LibraryApplicationArea.DisableApplicationAreaSetup();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetStatusStyleTextFavorable()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 342484] GetStatusStyleText = 'Favorable' when Status = Open
        Initialize();

        // [WHEN] Function GetStatusStyleText is being run for Status = Open
        // [THEN] Return value is 'Favorable'
        Assert.AreEqual('Favorable', GetStatusStyleText("Sales Document Status"::Open), 'Unexpected style text');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetStatusStyleTextStrong()
    begin
        // [FEATURE] [UT]
        // [SCENARIO 342484] GetStatusStyleText = 'Strong' when Status <> Open
        // [WHEN] Function GetStatusStyleText is being run for Status <> Open
        // [THEN] Return value is 'Strong'
        Assert.AreEqual('Strong', GetStatusStyleText("Sales Document Status"::"Pending Approval"), 'Unexpected style text');
        Assert.AreEqual('Strong', GetStatusStyleText("Sales Document Status"::"Pending Prepayment"), 'Unexpected style text');
        Assert.AreEqual('Strong', GetStatusStyleText("Sales Document Status"::Released), 'Unexpected style text');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPackageNoIsIncludedInInternetAddressLink()
    var
        ShippingAgent: Record "Shipping Agent";
        PackageTrackingNo: Text[50];
    begin
        // [FEATURE] [Shipping Agent] [UT]
        // [SCENARIO 328798] GetTrackingInternetAddr returns text containing "Package Tracking No." if ShippingAgent."Internet Address" consists only from placeholder %1
        Initialize();
        CreateShippingAgent(ShippingAgent, '%1', PackageTrackingNo);
        Assert.AreEqual(
          PackageTrackingNo, CopyStr(ShippingAgent.GetTrackingInternetAddr(PackageTrackingNo), StrLen(HttpTxt) + 1),
          PackageTrackingNoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInternetAddressWithoutHttp()
    var
        ShippingAgent: Record "Shipping Agent";
        PackageTrackingNo: Text[50];
    begin
        // [FEATURE] [Shipping Agent] [UT]
        // [SCENARIO 328798] GetTrackingInternetAddr returns text containing "Package Tracking No." if ShippingAgent."Internet Address" does not contains Http
        Initialize();
        CreateShippingAgent(ShippingAgent, InternetURLTxt, PackageTrackingNo);
        Assert.AreEqual(HttpTxt + InternetURLTxt, ShippingAgent.GetTrackingInternetAddr(PackageTrackingNo), InvalidURLErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInternetAddressWithHttp()
    var
        ShippingAgent: Record "Shipping Agent";
        PackageTrackingNo: Text[50];
    begin
        // [FEATURE] [Shipping Agent] [UT]
        // [SCENARIO 328798] GetTrackingInternetAddr returns text containing "Package Tracking No." if ShippingAgent."Internet Address" contains Http
        Initialize();
        CreateShippingAgent(ShippingAgent, HttpTxt + InternetURLTxt, PackageTrackingNo);
        Assert.AreEqual(HttpTxt + InternetURLTxt, ShippingAgent.GetTrackingInternetAddr(PackageTrackingNo), InvalidURLErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestNoPackageNoExistIfNoPlaceHolderExistInURL()
    var
        ShippingAgent: Record "Shipping Agent";
        PackageTrackingNo: Text[50];
    begin
        // [FEATURE] [Shipping Agent] [UT]
        // [SCENARIO 328798] GetTrackingInternetAddr returns text without "Package Tracking No." if ShippingAgent."Internet Address" does not contain placeholder %1
        Initialize();
        CreateShippingAgent(ShippingAgent, InternetURLTxt, PackageTrackingNo);
        Assert.IsTrue(
          StrPos(ShippingAgent.GetTrackingInternetAddr(PackageTrackingNo), PackageTrackingNo) = 0, PackageTrackingNoErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetTrackingInternetAddrRespectsHttpsInURL()
    var
        ShippingAgent: Record "Shipping Agent";
        InternetAddress: Text;
        PackageTrackingNo: Text[50];
    begin
        // [FEATURE] [Shipping Agent] [UT]
        // [SCENARIO 386459] GetTrackingInternetAddr doesn't add "http://" if address already contains "https://"
        Initialize();

        // [GIVEN] Create Shipping agent with "Internet address" starting with "https://"
        InternetAddress := 'https://' + InternetURLTxt;
        CreateShippingAgent(ShippingAgent, InternetAddress, PackageTrackingNo);

        // [THEN] GetTrackingInternetAddr returns "Internet address" without adding "http://" to it
        Assert.AreEqual(InternetAddress, ShippingAgent.GetTrackingInternetAddr(PackageTrackingNo), InvalidURLErr);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure ChangePriceIncludingVATTrueValueRecalculateAmountCorrectlyForFullVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        UnitPrice: Decimal;
        LineAmount: Decimal;
    begin
        // [FEATURE] [Full VAT]
        // [SCENARIO 348949] Create Sales line with "Prices Including VAT" = False and Full VAT and change "Prices Including VAT" to True
        Initialize();

        // [GIVEN] Created VAT Posting Setup for Full VAT
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Full VAT", 100);

        // [GIVEN] Create Sales Header with Line
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        MockSalesLineWithGLAccount(SalesLine, SalesHeader, VATPostingSetup);

        // [GIVEN] Validate "VAT Prod. Posting Group"
        // [GIVEN] Memorize "Direct Unit Cost" as "D"
        // [GIVEN] Memorize "Line Amount" as "L"
        SalesLine.Validate("VAT Prod. Posting Group");
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLine.Modify(true);
        UnitPrice := SalesLine."Unit Price";
        LineAmount := SalesLine."Line Amount";

        // [WHEN] Change "Prices Including VAT" to True
        SalesHeader.Validate("Prices Including VAT", true);

        // [THEN] "Direct Unit Cost" are equal to "D"
        // [THEN] "Line Amount" are equal to "L"
        SalesLine.TestField("Unit Price", UnitPrice);
        SalesLine.TestField("Line Amount", LineAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure ChangePriceIncludingVATFalseValueRecalculateAmountCorrectlyForFullVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        UnitPrice: Decimal;
        LineAmount: Decimal;
    begin
        // [FEATURE] [Full VAT]
        // [SCENARIO 348949] Create Sales line with "Prices Including VAT" = True and Full VAT and change "Prices Including VAT" to False
        Initialize();

        // [GIVEN] Created VAT Posting Setup for Full VAT
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Full VAT", 100);

        // [GIVEN] Create Sales Header with Line with "Prices Including VAT" = true
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify(true);
        MockSalesLineWithGLAccount(SalesLine, SalesHeader, VATPostingSetup);

        // [GIVEN] Validate "VAT Prod. Posting Group"
        // [GIVEN] Memorize "Direct Unit Cost" as "D"
        // [GIVEN] Memorize "Line Amount" as "L"
        SalesLine.Validate("VAT Prod. Posting Group");
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLine.Modify(true);
        UnitPrice := SalesLine."Unit Price";
        LineAmount := SalesLine."Line Amount";

        // [WHEN] Change "Prices Including VAT" to False
        SalesHeader.Validate("Prices Including VAT", false);

        // [THEN] "Direct Unit Cost" are equal to "D"
        // [THEN] "Line Amount" are equal to "L"
        SalesLine.TestField("Unit Price", UnitPrice);
        SalesLine.TestField("Line Amount", LineAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure ChangePriceIncludingVATTrueValueRecalculateAmountCorrectlyForFullVATWithDiscountAmount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        UnitPrice: Decimal;
        LineAmount: Decimal;
    begin
        // [FEATURE] [Full VAT]
        // [SCENARIO 348949] Create Sales line with "Prices Including VAT" = False, "Inv. Discount Amount" and Full VAT and change "Prices Including VAT" to True
        Initialize();

        // [GIVEN] Created VAT Posting Setup for Full VAT
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Full VAT", 100);

        // [GIVEN] Create Sales Header with Line
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        MockSalesLineWithGLAccount(SalesLine, SalesHeader, VATPostingSetup);

        // [GIVEN] Validate "VAT Prod. Posting Group"
        // [GIVEN] Memorize "Direct Unit Cost" as "D"
        // [GIVEN] Memorize "Line Amount" as "L"
        SalesLine.Validate("VAT Prod. Posting Group");
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLine.Modify(true);
        UnitPrice := SalesLine."Unit Price";
        LineAmount := SalesLine."Line Amount";

        // [GIVEN] Mock "Inv. Discount Amount" for line
        SalesLine."Inv. Discount Amount" := SalesLine."Line Amount" / 10;
        SalesLine.Modify();

        // [WHEN] Change "Prices Including VAT" to True
        SalesHeader.Validate("Prices Including VAT", true);

        // [THEN] "Direct Unit Cost" are equal to "D"
        // [THEN] "Line Amount" are equal to "L"
        SalesLine.TestField("Unit Price", UnitPrice);
        SalesLine.TestField("Line Amount", LineAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure ChangePriceIncludingVATFalseValueRecalculateAmountCorrectlyForFullVATWithDiscountAmount()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        UnitPrice: Decimal;
        LineAmount: Decimal;
    begin
        // [FEATURE] [Full VAT]
        // [SCENARIO 348949] Create Sales line with "Prices Including VAT" = True, "Inv. Discount Amount" and Full VAT and change "Prices Including VAT" to False
        Initialize();

        // [GIVEN] Created VAT Posting Setup for Full VAT
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Full VAT", 100);

        // [GIVEN] Create Sales Header with Line with "Prices Including VAT" = true
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify(true);
        MockSalesLineWithGLAccount(SalesLine, SalesHeader, VATPostingSetup);

        // [GIVEN] Validate "VAT Prod. Posting Group"
        // [GIVEN] Memorize "Direct Unit Cost" as "D"
        // [GIVEN] Memorize "Line Amount" as "L"
        SalesLine.Validate("VAT Prod. Posting Group");
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));
        SalesLine.Modify(true);
        UnitPrice := SalesLine."Unit Price";
        LineAmount := SalesLine."Line Amount";

        // [GIVEN] Mock "Inv. Discount Amount" for line
        SalesLine."Inv. Discount Amount" := SalesLine."Line Amount" / 10;
        SalesLine.Modify();

        // [WHEN] Change "Prices Including VAT" to False
        SalesHeader.Validate("Prices Including VAT", false);

        // [THEN] "Direct Unit Cost" are equal to "D"
        // [THEN] "Line Amount" are equal to "L"
        SalesLine.TestField("Unit Price", UnitPrice);
        SalesLine.TestField("Line Amount", LineAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure RecreateSalesCommentLines()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCommentLine: Record "Sales Comment Line";
    begin
        // [FEATURE] [Sales Comment Line] [UT]
        // [SCENARIO 351187] The Sales Comment Lines must be copied after Sales Lines have been recreated
        Initialize();
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, "Sales Line Type"::Item, LibraryInventory.CreateItemNo(), 1);
        LibrarySales.CreateSalesCommentLine(SalesCommentLine, "Sales Document Type"::Order, SalesHeader."No.", SalesLine."Line No.");

        SalesHeader.Validate("Sell-to Customer No.", LibrarySales.CreateCustomerNo());
        // [SCENARIO 360476] No duplicate Comment Lines inserted
        Commit();

        VerifyCountSalesCommentLine(SalesHeader."Document Type", SalesHeader."No.", 10000);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure RecreateSalesCommentLineForSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCommentLine: Record "Sales Comment Line";
    begin
        // [FEATURE] [Sales Comment Line] [UT]
        // [SCENARIO 399071] The Sales Comment Lines must be copied after Sales Lines have been recreated if Sales Line No. < 10000
        Initialize();
        LibrarySales.CreateSalesHeader(SalesHeader, "Sales Document Type"::Order, LibrarySales.CreateCustomerNo());
        CreateSalesLineSimple(SalesLine, SalesHeader, 5000);
        LibrarySales.CreateSalesCommentLine(SalesCommentLine, "Sales Document Type"::Order, SalesHeader."No.", SalesLine."Line No.");
        LibrarySales.CreateSalesCommentLine(SalesCommentLine, "Sales Document Type"::Order, SalesHeader."No.", 0);

        SalesHeader.Validate("Sell-to Customer No.", LibrarySales.CreateCustomerNo());
        Commit();

        VerifyCountSalesCommentLine(SalesHeader."Document Type", SalesHeader."No.", 10000);
        VerifyCountSalesCommentLine(SalesHeader."Document Type", SalesHeader."No.", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DocumentTotalsCalculateCorrectlyWithFullVATAndPriceIncludingVATTrue()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
        TotalSalesLine: Record "Sales Line";
        DocumentTotals: Codeunit "Document Totals";
        VATAmount: Decimal;
    begin
        // [FEATURE] [Full VAT]
        // [SCENARIO 348949] Create Sales line with "Prices Including VAT" = True and Full VAT and check Totals
        Initialize();

        // [GIVEN] Created VAT Posting Setup for Full VAT
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Full VAT", 100);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup2, VATPostingSetup."VAT Bus. Posting Group", '');

        // [GIVEN] Create Sales Header with "Prices Including VAT" and Sales Line
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify(true);
        CreateSalesLineWithGLAccount(SalesLine, SalesHeader, VATPostingSetup);

        // [WHEN] Totals are calculated
        DocumentTotals.CalculateSalesTotals(TotalSalesLine, VATAmount, SalesLine);

        // [THEN] "Total Amount Excl. VAT" equal to 0
        // [THEN] "Total Amount Incl. VAT" equal to "Amount Including VAT"
        // [THEN] "Total VAT Amount" equal to "Amount Including VAT"
        TotalSalesLine.TestField(Amount, 0);
        TotalSalesLine.TestField("Amount Including VAT", SalesLine."Amount Including VAT");
        SalesLine.TestField("Amount Including VAT", VATAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotSetupAllowInvoiceDiscountForFullVATLine()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Full VAT]
        // [SCENARIO 348949] Create Sales line with Full VAT and try to set "Allow Invoice Disc." to True
        Initialize();

        // [GIVEN] Created VAT Posting Setup for Full VAT
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Full VAT", 100);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup2, VATPostingSetup."VAT Bus. Posting Group", '');

        // [GIVEN] Create Sales Header with "Prices Including VAT" and Sales Line
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify(true);
        CreateSalesLineWithGLAccount(SalesLine, SalesHeader, VATPostingSetup);

        // [WHEN] Set "Allow Invoice Disc." to True
        asserterror SalesLine.VALIDATE("Allow Invoice Disc.", true);

        // [THEN] The error was shown
        Assert.ExpectedError(CannotAllowInvDiscountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AllowInvoiceDiscountResetToFalseAfterSetUpVATCalcullationTypeToFullVAT()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        VATPostingSetup2: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Full VAT]
        // [SCENARIO 348949] Create Sales line with Normal VAT and change "VAT Prod. Posting Group" to Full VAT
        Initialize();

        // [GIVEN] VAT Posting Setup for Full VAT as "Full VAT Setup"
        // [GIVEN] VAT Posting Setup for Normal VAT as "Normal VAT Setup"
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Full VAT", 100);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup2, VATPostingSetup."VAT Bus. Posting Group", '');

        // [GIVEN] Create Sales Header with "Prices Including VAT" and Sales Line
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify(true);
        CreateSalesLineWithGLAccount(SalesLine, SalesHeader, VATPostingSetup);

        // [GIVEN] Validate "VAT Prod. Posting Group" and "Unit Price"
        SalesLine.Validate("VAT Prod. Posting Group");
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(1000, 2));

        // [GIVEN] Changed "VAT Prod. Posting Group" to "VAT Prod. Posting Group" from "Normal VAT Setup"
        SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup2."VAT Prod. Posting Group");
        SalesLine.Validate("Allow Invoice Disc.", true);

        // [WHEN] Change "VAT Prod. Posting Group" to "VAT Prod. Posting Group" from "Full VAT Setup"
        SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");

        // [THEN] "Allow Invoice Disc." set to False
        SalesLine.TestField("Allow Invoice Disc.", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecreatingSalesLinesWithoutOrderPromisingDoesNotTouchReqLines()
    var
        SalesHeader: Record "Sales Header";
        CodeCoverage: Record "Code Coverage";
        CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
    begin
        // [FEATURE] [Order Promising]
        // [SCENARIO 365071] Recreating sales lines does not try to delete requisition lines when they do not exist.
        Initialize();

        // [GIVEN] Sales order.
        CreateSalesDocumentItem(SalesHeader, SalesHeader."Document Type"::Order, LibraryInventory.CreateItemNo());
        SalesHeader.SetHideValidationDialog(true);

        // [WHEN] Turn on code coverage and change Sell-to Customer No. in the sales order.
        CodeCoverageMgt.StartApplicationCoverage();
        SalesHeader.Validate("Sell-to Customer No.", LibrarySales.CreateCustomerNo());
        CodeCoverageMgt.StopApplicationCoverage();

        // [THEN] There were no attempts to delete requisition lines for order promising.
        CodeCoverageMgt.Refresh();
        CodeCoverage.SetRange("Line Type", CodeCoverage."Line Type"::Code);
        CodeCoverage.SetRange("Object Type", CodeCoverage."Object Type"::Table);
        CodeCoverage.SetRange("Object ID", DATABASE::"Sales Header");
        CodeCoverage.SetFilter("No. of Hits", '>%1', 0);
        CodeCoverage.SetFilter(Line, StrSubstNo('@*%1*', 'ReqLine.DeleteAll'));
        Assert.RecordIsEmpty(CodeCoverage);
    end;

    [Test]
    [HandlerFunctions('CustomerLookupSelectCustomerPageHandler')]
    [Scope('OnPrem')]
    procedure ShippingTimeIsPopulatedFromCustomerOnLookupSellToCustomerName()
    var
        Customer: Record Customer;
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 372368] Shipping Time is populated with a value from Customer when Sell-to Customer Name is validated on Sales Order by LookUp.
        Initialize();

        // [GIVEN] New customer. "No." = "X", "Shipping Time" = "T".
        CreateCustomerWithShippingTime(Customer);
        LibraryVariableStorage.Enqueue(Customer."No.");

        // [WHEN] Create new Sales Order and select "X" in "Sell-to Customer Name" field.
        SalesOrder.OpenNew();
        SalesOrder."Sell-to Customer Name".Lookup();

        // [THEN] Shipping Time in the Sales Order is equal to "T".
        SalesOrder."Shipping Time".AssertEquals(Customer."Shipping Time");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CustomerLookupSelectCustomerPageHandler')]
    [Scope('OnPrem')]
    procedure ShippingTimeIsPopulatedFromShippingAgentServiceOnLookupSellToCustomerName()
    var
        Customer: Record Customer;
        ShippingAgent: Record "Shipping Agent";
        ShippingAgentServices: Record "Shipping Agent Services";
        SalesOrder: TestPage "Sales Order";
        ShippingTime: DateFormula;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 372368] Shipping Time is populated with a value from Sipping Agent Service when Sell-to Customer No. is validated on Sales Order by LookUp.
        Initialize();

        // [GIVEN] Created Shipping Agent and Shipping Agent Service with "Shipping Time" = "T"
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        Evaluate(ShippingTime, StrSubstNo('<%1D>', LibraryRandom.RandInt(10)));
        LibraryInventory.CreateShippingAgentService(ShippingAgentServices, ShippingAgent.Code, ShippingTime);

        // [GIVEN] Created Customer and validate "Shipping Agent Code" and "Shipping Agent Service Code" by created value
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Shipping Agent Code", ShippingAgent.Code);
        Customer.Validate("Shipping Agent Service Code", ShippingAgentServices.Code);
        Customer.Modify(true);
        LibraryVariableStorage.Enqueue(Customer."No.");

        // [WHEN] Create new Sales Order and select "X" in "Sell-to Customer Name" field.
        SalesOrder.OpenNew();
        SalesOrder."Sell-to Customer Name".Lookup();

        // [THEN] Shipping Time in the Sales Order is equal to "T".
        SalesOrder."Shipping Time".AssertEquals(ShippingAgentServices."Shipping Time");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure CustomerTemplateValidateVATRegFieldUI()
    var
        CustomerTemplCard: TestPage "Customer Templ. Card";
    begin
        // [FEATURE] [UT] [UI]
        // [SCENARIO 383454] Page 1382 "Customer Templ. Card" has field "Validate EU Vat Reg. No."
        LibraryApplicationArea.EnableFoundationSetup();
        CustomerTemplCard.OpenView();

        Assert.IsTrue(CustomerTemplCard."Validate EU Vat Reg. No.".Enabled(), 'Validate EU Vat Reg. No. should be visible');
        Assert.IsTrue(CustomerTemplCard."Validate EU Vat Reg. No.".Visible(), 'Validate EU Vat Reg. No. should be visible');

        CustomerTemplCard.Close();
        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesModalPageHandler')]
    procedure GetShipmentLinesWithItemChargeNormalOrder()
    var
        SalesHeaderOrder: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        SalesLineItem: Record "Sales Line";
        SalesLineChargeItem: Record "Sales Line";
        QtyToAssign: Decimal;
    begin
        // [FEATURE] [Get Shipment Lines] [Order] [Invoice] [Item Charge]
        // [SCENARIO 385039] "Get Shipment Lines" ignores the order of given shipment lines when it creates invoice with Item Charge
        Initialize();

        // [GIVEN] Sales order with item and charge item for the customer "X"
        // [GIVEN] "Qty. To Assign" = 3 in sales lines with charge item
        QtyToAssign := LibraryRandom.RandIntInRange(3, 10);

        CreateSalesOrderWithItemAndChargeItem(SalesHeaderOrder, SalesLineItem, SalesLineChargeItem, QtyToAssign);

        Commit();

        // [GIVEN] Sales order shipped only
        LibrarySales.PostSalesDocument(SalesHeaderOrder, true, false);

        VerifyQtyToAssignInDocumentLineForChargeItem(SalesHeaderOrder, SalesLineChargeItem."No.", QtyToAssign);

        // [GIVEN] Sales invoice for customer "X"
        LibrarySales.CreateSalesHeader(
          SalesHeaderInvoice, SalesHeaderInvoice."Document Type"::Invoice, SalesHeaderOrder."Sell-to Customer No.");

        // [WHEN] Call "Get Shipment Lines" with reversed order
        GetShipmentLinesWithOrder(SalesHeaderInvoice, SalesHeaderOrder, true);

        // [THEN] Charge Item line inserted with "Qty. To Assign" = 3
        VerifyQtyToAssignInDocumentLineForChargeItem(SalesHeaderInvoice, SalesLineChargeItem."No.", QtyToAssign);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesModalPageHandler')]
    procedure GetShipmentLinesWithItemChargeReversedOrder()
    var
        SalesHeaderOrder: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        SalesLineItem: Record "Sales Line";
        SalesLineChargeItem: Record "Sales Line";
        QtyToAssign: Decimal;
    begin
        // [FEATURE] [Get Shipment Lines] [Order] [Invoice] [Item Charge]
        // [SCENARIO 385039] "Get Shipment Lines" ignores the order of given shipment lines when it creates invoice with Item Charge
        Initialize();

        // [GIVEN] Sales order with item and charge item for the customer "X"
        // [GIVEN] "Qty. To Assign" = 3 in sales lines with charge item
        QtyToAssign := LibraryRandom.RandIntInRange(3, 10);

        CreateSalesOrderWithItemAndChargeItem(SalesHeaderOrder, SalesLineItem, SalesLineChargeItem, QtyToAssign);

        Commit();

        // [GIVEN] Sales order shipped only
        LibrarySales.PostSalesDocument(SalesHeaderOrder, true, false);

        VerifyQtyToAssignInDocumentLineForChargeItem(SalesHeaderOrder, SalesLineChargeItem."No.", QtyToAssign);

        // [GIVEN] Sales invoice for customer "X"
        LibrarySales.CreateSalesHeader(
          SalesHeaderInvoice, SalesHeaderInvoice."Document Type"::Invoice, SalesHeaderOrder."Sell-to Customer No.");

        // [WHEN] Call "Get Shipment Lines" with reversed order
        GetShipmentLinesWithOrder(SalesHeaderInvoice, SalesHeaderOrder, false);

        // [THEN] Charge Item line inserted with "Qty. To Assign" = 3
        VerifyQtyToAssignInDocumentLineForChargeItem(SalesHeaderInvoice, SalesLineChargeItem."No.", QtyToAssign);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesModalPageHandler')]
    procedure GetShipmentLinesWithItemChargeFirstNormalOrder()
    var
        SalesHeaderOrder: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        SalesLineItem: Record "Sales Line";
        SalesLineChargeItem: Record "Sales Line";
        QtyToAssign: Decimal;
    begin
        // [FEATURE] [Get Shipment Lines] [Order] [Invoice] [Item Charge]
        // [SCENARIO 385039] "Get Shipment Lines" ignores the order of given shipment lines when it creates invoice with Item Charge
        Initialize();

        // [GIVEN] Sales order with charge item and item for the customer "X"
        // [GIVEN] "Qty. To Assign" = 3 in sales line with charge item
        QtyToAssign := LibraryRandom.RandIntInRange(3, 10);

        CreateSalesOrderWithChargeItemAndItem(SalesHeaderOrder, SalesLineItem, SalesLineChargeItem, QtyToAssign);

        Commit();

        // [GIVEN] Sales order shipped only
        LibrarySales.PostSalesDocument(SalesHeaderOrder, true, false);

        VerifyQtyToAssignInDocumentLineForChargeItem(SalesHeaderOrder, SalesLineChargeItem."No.", QtyToAssign);

        // [GIVEN] Sales invoice for customer "X"
        LibrarySales.CreateSalesHeader(
          SalesHeaderInvoice, SalesHeaderInvoice."Document Type"::Invoice, SalesHeaderOrder."Sell-to Customer No.");

        // [WHEN] Call "Get Shipment Lines" with reversed order
        GetShipmentLinesWithOrder(SalesHeaderInvoice, SalesHeaderOrder, true);

        // [THEN] Charge Item line inserted with "Qty. To Assign" = 3
        VerifyQtyToAssignInDocumentLineForChargeItem(SalesHeaderInvoice, SalesLineChargeItem."No.", QtyToAssign);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesModalPageHandler')]
    procedure GetShipmentLinesWithItemChargeFirstReversedOrder()
    var
        SalesHeaderOrder: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        SalesLineItem: Record "Sales Line";
        SalesLineChargeItem: Record "Sales Line";
        QtyToAssign: Decimal;
    begin
        // [FEATURE] [Get Shipment Lines] [Order] [Invoice] [Item Charge]
        // [SCENARIO 385039] "Get Shipment Lines" ignores the order of given shipment lines when it creates invoice with Item Charge
        Initialize();

        // [GIVEN] Sales order with charge item and item for the customer "X"
        // [GIVEN] "Qty. To Assign" = 3 in sales line with charge item
        QtyToAssign := LibraryRandom.RandIntInRange(3, 10);

        CreateSalesOrderWithChargeItemAndItem(SalesHeaderOrder, SalesLineItem, SalesLineChargeItem, QtyToAssign);

        Commit();

        // [GIVEN] Sales order shipped only
        LibrarySales.PostSalesDocument(SalesHeaderOrder, true, false);

        VerifyQtyToAssignInDocumentLineForChargeItem(SalesHeaderOrder, SalesLineChargeItem."No.", QtyToAssign);

        // [GIVEN] Sales invoice for customer "X"
        LibrarySales.CreateSalesHeader(
          SalesHeaderInvoice, SalesHeaderInvoice."Document Type"::Invoice, SalesHeaderOrder."Sell-to Customer No.");

        // [WHEN] Call "Get Shipment Lines" with reversed order
        GetShipmentLinesWithOrder(SalesHeaderInvoice, SalesHeaderOrder, false);

        // [THEN] Charge Item line inserted with "Qty. To Assign" = 3
        VerifyQtyToAssignInDocumentLineForChargeItem(SalesHeaderInvoice, SalesLineChargeItem."No.", QtyToAssign);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesModalPageHandler,MessageHandler')]
    procedure GetShipmentLinesFromEmptyFilteredRecord()
    var
        SalesHeaderOrder: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        SalesLineItem: Record "Sales Line";
        SalesLineChargeItem: Record "Sales Line";
        SalesLineInvoice: Record "Sales Line";
        QtyToAssign: Decimal;
    begin
        // [FEATURE] [Get Shipment Lines] [Order] [Invoice] [Item Charge] [FCY]
        // [SCENARIO 385039] "Get Shipment Lines" does not insert lines into invoice when invoice's currency differs from shipment's currency
        Initialize();

        QtyToAssign := LibraryRandom.RandIntInRange(3, 10);

        CreateSalesOrderWithChargeItemAndItem(SalesHeaderOrder, SalesLineItem, SalesLineChargeItem, QtyToAssign);

        Commit();

        LibrarySales.PostSalesDocument(SalesHeaderOrder, true, false);

        VerifyQtyToAssignInDocumentLineForChargeItem(SalesHeaderOrder, SalesLineChargeItem."No.", QtyToAssign);

        LibrarySales.CreateSalesHeader(
          SalesHeaderInvoice, SalesHeaderInvoice."Document Type"::Invoice, SalesHeaderOrder."Sell-to Customer No.");
        SalesHeaderInvoice.Validate("Currency Code", LibraryERM.CreateCurrencyWithRandomExchRates());
        SalesHeaderInvoice.Modify(true);

        GetShipmentLinesWithOrder(SalesHeaderInvoice, SalesHeaderOrder, false);

        SalesLineInvoice.SetRange("Document Type", SalesHeaderInvoice."Document Type");
        SalesLineInvoice.SetRange("Document No.", SalesHeaderInvoice."No.");
        Assert.RecordIsEmpty(SalesLineInvoice);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesModalPageHandler,ConfirmHandlerTrue')]
    procedure GetShipmentLinesWithItemCharge_Shipment_UndoShipment_Shipment()
    var
        SalesHeaderOrder: Record "Sales Header";
        SalesHeaderInvoice: Record "Sales Header";
        SalesLineItem: Record "Sales Line";
        SalesLineChargeItem: Record "Sales Line";
        QtyToAssign: Decimal;
    begin
        // [FEATURE] [Get Shipment Lines] [Order] [Invoice] [Item Charge] [Undo Shipment]
        // [SCENARIO 385039] "Get Shipment Lines" doesn't pull item charge assignment from undone shipment lines
        Initialize();

        QtyToAssign := LibraryRandom.RandIntInRange(3, 10);

        CreateSalesOrderWithChargeItemAndItem(SalesHeaderOrder, SalesLineItem, SalesLineChargeItem, QtyToAssign);

        Commit();

        LibrarySales.PostSalesDocument(SalesHeaderOrder, true, false);

        VerifyQtyToAssignInDocumentLineForChargeItem(SalesHeaderOrder, SalesLineChargeItem."No.", QtyToAssign);

        UndoShipment(SalesHeaderOrder);

        VerifyQtyToAssignInDocumentLineForChargeItem(SalesHeaderOrder, SalesLineChargeItem."No.", QtyToAssign);

        LibrarySales.PostSalesDocument(SalesHeaderOrder, true, false);

        VerifyQtyToAssignInDocumentLineForChargeItem(SalesHeaderOrder, SalesLineChargeItem."No.", QtyToAssign);

        LibrarySales.CreateSalesHeader(
          SalesHeaderInvoice, SalesHeaderInvoice."Document Type"::Invoice, SalesHeaderOrder."Sell-to Customer No.");

        GetShipmentLinesWithOrder(SalesHeaderInvoice, SalesHeaderOrder, false);

        VerifyQtyToAssignInDocumentLineForChargeItem(SalesHeaderInvoice, SalesLineChargeItem."No.", QtyToAssign);
    end;

    [Test]
    [HandlerFunctions('PostedSalesDocumentLinesHandler')]
    [Scope('OnPrem')]
    procedure CrMemoGetPostedDocumentLinesPostedReturnReceiptUnitPrice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesPrice: Record "Sales Price";
        InitialUnitPrice: Decimal;
    begin
        // [FEATURE] [Get Document Lines to Reverse]
        // [SCENARIO 393339] Action "Get Document Lines to Reserse" copies Unit Price from Posted Return Receipt and not from current Sales Price
        Initialize();

        UpdateSalesSetup(true, false);
        // [GIVEN] Posted Sales Credit Memo with one line for Item "I1": "Unit Price" = 10
        CreateSalesDocumentWithItem(SalesHeader, SalesHeader."Document Type"::"Credit Memo");
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);
        InitialUnitPrice := SalesLine."Unit Price";
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [GIVEN] Sales Price for Item "I1" = 100 for WorkDate
        LibrarySales.CreateSalesPrice(
          SalesPrice, SalesLine."No.", "Sales Price Type"::"All Customers", '', WorkDate(), '', '', '', 0, InitialUnitPrice + 5);
        SalesLine.Reset();

        // [GIVEN] Create Credit Memo
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Sell-to Customer No.");

        // [WHEN] Run Get Document Lines to Reverse and copy from posted Posted Return Receipt
        GetPostedDocumentLines(SalesHeader."No.", OptionString::PostedReturnReceipt);
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine.Type::Item);

        // [THEN] Sales Line suggested has "Unit Price" = 10 for Item "I1"
        Assert.AreEqual(InitialUnitPrice, SalesLine."Unit Price", SalesLine.FieldCaption("Unit Price"));
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure RecreateSalesItemLineWithEmptyNo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        // [FEATURE]
        // [SCENARIO 414831] The sales line with "No." = '' and Type <> 'Item' must be recreated when Customer No. is changed
        Initialize();

        // [GIVEN] Item with empty description
        LibraryInventory.CreateItem(Item);
        Item.Description := '';
        Item.Modify();

        // [GIVEN] Sales Order with Customer No. = '10000' Sales Line with Type = "Item" and "No." is blank
        LibrarySales.CreateSalesHeader(
            SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::Item, '', 0);
        SalesLine.Validate("No.", '');
        SalesLine.Modify(true);

        // [WHEN] Change Customer No. in Purchase Header
        SalesHeader.Validate("Sell-to Customer No.", LibrarySales.CreateCustomerNo());

        // [THEN] Sales Line with "No." = '' and Type = "Item" exists
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("No.", '');
        Assert.RecordCount(SalesLine, 1);
    end;

    [Test]
    [HandlerFunctions('SalesListModalPageHandler')]
    procedure WorkDescriptionOnPostedSalesShipmentForDropShipment()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        WorkDescription: Text;
    begin
        // [FEATURE] [Shipment] [Drop Shipment] [Work Description]
        // [SCENARIO 422109] "Work Description" on posted sales shipment for drop shipment.
        Initialize();

        // [GIVEN] Drop shipment sales order with "Work Description" = "X".
        WorkDescription := LibraryRandom.RandText(10);
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '',
          LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10), '', WorkDate());
        SalesLine.Validate("Drop Shipment", true);
        SalesLine.Modify(true);
        SalesHeader.SetWorkDescription(WorkDescription);

        // [GIVEN] Create purchase order via "Drop Shipment" -> "Get Sales Orders".
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.GetDropShipment(PurchaseHeader);

        // [WHEN] Receive the purchase order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] The associated sales order is shipped as well.
        // [THEN] "Work Description" = "X" in the sales shipment header.
        SalesShipmentHeader.SetRange("Order No.", SalesHeader."No.");
        SalesShipmentHeader.FindFirst();
        Assert.AreEqual(WorkDescription, SalesShipmentHeader.GetWorkDescription(), '');
    end;

    [Test]
    [HandlerFunctions('CustomerLookupSelectCustomerPageHandler')]
    [Scope('OnPrem')]
    procedure EnsureInsertingSearchCustomerNameInSalesInvoice()
    var
        Customer: Record Customer;
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 447956] Inserting the customer name in a Sales Invoice without any error
        Initialize();

        // [GIVEN] Create customer
        LibrarySales.CreateCustomer(Customer);
        LibraryVariableStorage.Enqueue(Customer."No.");

        // [WHEN] Create new Sales Invoice and click on lookup at "Sell-to Customer Name" field
        SalesInvoice.OpenNew();
        SalesInvoice."Sell-to Customer Name".Lookup();

        // [THEN] Verify customer name inserted to "Sell-to Customer Name" without any error
        SalesInvoice."Sell-to Customer Name".AssertEquals(Customer.Name);
        SalesInvoice.Close();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure EditDescriptionCustLedgerEntryLoggedInChangeLog()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
        RecordRef: RecordRef;
        NewDescription, OldDescription : Text;
    begin
        Initialize();

        // [GIVEN] Create Customer Ledger Entry
        LibrarySales.MockCustLedgerEntry(CustLedgerEntry, LibrarySales.CreateCustomerNo());
        OldDescription := LibraryRandom.RandText(MaxStrLen(CustLedgerEntry.Description));
        CustLedgerEntry.Description := OldDescription;
        CustLedgerEntry.Modify();

        // [WHEN] Description is modified in customer ledger entries
        NewDescription := LibraryRandom.RandText(MaxStrLen(CustLedgerEntry.Description));
        CustomerLedgerEntries.OpenEdit();
        CustomerLedgerEntries.GoToRecord(CustLedgerEntry);
        CustomerLedgerEntries.Description.Value(NewDescription);
        CustomerLedgerEntries.Close();

        // [THEN] Description is changed & the change is logged in change log entry
        CustLedgerEntry.Get(CustLedgerEntry."Entry No.");
        Assert.AreEqual(NewDescription, CustLedgerEntry.Description, CustLedgerEntry.FieldCaption(Description));
        RecordRef.GetTable(CustLedgerEntry);
        VerifyChangeLogFieldValue(RecordRef, CustLedgerEntry.FieldNo(Description), OldDescription, NewDescription);
    end;

    [Test]
    [HandlerFunctions('ChangeLogEntriesModalPageHandler')]
    procedure ShowLoggedDescriptionChangesInCustLedgerEntries()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
        NewDescription, OldDescription : Text;
    begin
        Initialize();

        // [GIVEN] Create Customer Ledger Entry
        LibrarySales.MockCustLedgerEntry(CustLedgerEntry, LibrarySales.CreateCustomerNo());
        OldDescription := LibraryRandom.RandText(MaxStrLen(CustLedgerEntry.Description));
        CustLedgerEntry.Description := OldDescription;
        CustLedgerEntry.Modify();

        // [GIVEN] Description is modified
        NewDescription := LibraryRandom.RandText(MaxStrLen(CustLedgerEntry.Description));
        CustomerLedgerEntries.OpenEdit();
        CustomerLedgerEntries.GoToRecord(CustLedgerEntry);
        CustomerLedgerEntries.Description.Value(NewDescription);
        CustomerLedgerEntries.Close();

        LibraryVariableStorage.Enqueue(OldDescription);
        LibraryVariableStorage.Enqueue(NewDescription);

        // [WHEN] Show change log action is run
        CustomerLedgerEntries.OpenView();
        CustomerLedgerEntries.GoToRecord(CustLedgerEntry);
        CustomerLedgerEntries.ShowChangeHistory.Invoke();

        // [THEN] Modal page Change Log Entries with logged changed is open
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyReceivedFromCountryIsSetOnSalesCreditMemo()
    var
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 469244] Verify Received-from Country Code is assigned from Sell-to Customer on Sales Credit memo
        Initialize();

        // [GIVEN] Create customer with country/region
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateCountryRegion(CountryRegion);
        Customer."Country/Region Code" := CountryRegion.Code;
        Customer.Modify();

        // [GIVEN] New Sales Credit Memo
        SalesCreditMemo.OpenNew();

        // [WHEN] Customer is entered
        SalesCreditMemo."Sell-to Customer No.".SetValue(Customer."No.");

        // [THEN] Verify Received-from Country/Region Code is set
        Assert.AreEqual(Customer."Country/Region Code", SalesCreditMemo."Rcvd-from Country/Region Code".Value, 'Received-from Country Code is not set');
        SalesCreditMemo.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyReceivedFromCountryIsSetOnSalesReturnOrder()
    var
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 469244] Verify Received-from Country Code is assigned from Sell-to Customer on Sales Return Order
        Initialize();

        // [GIVEN] Create customer with country/region
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateCountryRegion(CountryRegion);
        Customer."Country/Region Code" := CountryRegion.Code;
        Customer.Modify();

        // [GIVEN] New Sales Return Order
        SalesReturnOrder.OpenNew();

        // [WHEN] Customer is entered
        SalesReturnOrder."Sell-to Customer No.".SetValue(Customer."No.");

        // [THEN] Verify Received-from Country/Region Code is set
        Assert.AreEqual(Customer."Country/Region Code", SalesReturnOrder."Rcvd-from Country/Region Code".Value, 'Received-from Country Code is not set');
        SalesReturnOrder.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyReceivedFromCountryIsNotSetOnSalesQuote()
    var
        Customer: Record Customer;
        CountryRegion: Record "Country/Region";
        SalesHeader: Record "Sales Header";
        SalesQuote: TestPage "Sales Quote";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 469244] Verify Received-from Country Code is not assigned from Sell-to Customer on Sales Quote
        Initialize();

        // [GIVEN] Create customer with country/region
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateCountryRegion(CountryRegion);
        Customer."Country/Region Code" := CountryRegion.Code;
        Customer.Modify();

        // [GIVEN] New Sales Quote
        SalesQuote.OpenNew();

        // [WHEN] Customer is entered
        SalesQuote."Sell-to Customer No.".SetValue(Customer."No.");

        // [THEN] Verify Received-from Country/Region Code is set
        SalesHeader.Get(SalesHeader."Document TYpe"::Quote, SalesQuote."No.".Value);
        SalesQuote.Close();
        Assert.AreNotEqual(Customer."Country/Region Code", SalesHeader."Rcvd.-from Count./Region Code", 'Received-from Country Code is set just as it is on customer');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyReceivedFromCountryIsNotSetOnSalesOrder()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales header";
        CountryRegion: Record "Country/Region";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 469244] Verify Received-from Country Code is not assigned from Sell-to Customer on Sales Order
        Initialize();

        // [GIVEN] Create customer with country/region
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateCountryRegion(CountryRegion);
        Customer."Country/Region Code" := CountryRegion.Code;
        Customer.Modify();

        // [GIVEN] New Sales Order
        SalesOrder.OpenNew();

        // [WHEN] Customer is entered
        SalesOrder."Sell-to Customer No.".SetValue(Customer."No.");

        // [THEN] Verify Received-from Country/Region Code is set
        SalesHeader.Get(SalesHeader."Document TYpe"::Order, SalesOrder."No.".Value);
        SalesOrder.Close();
        Assert.AreNotEqual(Customer."Country/Region Code", SalesHeader."Rcvd.-from Count./Region Code", 'Received-from Country Code is set just as it is on customer');
    end;


    [Test]
    [Scope('OnPrem')]
    procedure VerifyReceivedFromCountryIsNotSetOnSalesInvoice()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CountryRegion: Record "Country/Region";
        SalesInvoice: TestPage "Sales Invoice";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 469244] Verify Received-from Country Code is not assigned from Sell-to Customer on Sales Invoice
        Initialize();

        // [GIVEN] Create customer with country/region
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateCountryRegion(CountryRegion);
        Customer."Country/Region Code" := CountryRegion.Code;
        Customer.Modify();

        // [GIVEN] New Sales Invoice
        SalesInvoice.OpenNew();

        // [WHEN] Customer is entered
        SalesInvoice."Sell-to Customer No.".SetValue(Customer."No.");

        // [THEN] Verify Received-from Country/Region Code is set
        SalesHeader.Get(SalesHeader."Document TYpe"::Invoice, SalesInvoice."No.".Value);
        SalesInvoice.Close();
        Assert.AreNotEqual(Customer."Country/Region Code", SalesHeader."Rcvd.-from Count./Region Code", 'Received-from Country Code is set just as it is on customer');
    end;


    [Test]
    [Scope('OnPrem')]
    procedure VerifyReceivedFromCountryIsNotSetOnSalesBlanketOrder()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CountryRegion: Record "Country/Region";
        BlanketSalesOrder: TestPage "Blanket Sales Order";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 469244] Verify Received-from Country Code is not assigned from Sell-to Customer on Sales Blanket Order
        Initialize();

        // [GIVEN] Create customer with country/region
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreateCountryRegion(CountryRegion);
        Customer."Country/Region Code" := CountryRegion.Code;
        Customer.Modify();

        // [GIVEN] New Sales Blanket Order
        BlanketSalesOrder.OpenNew();

        // [WHEN] Customer is entered
        BlanketSalesOrder."Sell-to Customer No.".SetValue(Customer."No.");

        // [THEN] Verify Received-from Country/Region Code is set
        SalesHeader.Get(SalesHeader."Document TYpe"::"Blanket Order", BlanketSalesOrder."No.".Value);
        BlanketSalesOrder.Close();
        Assert.AreNotEqual(Customer."Country/Region Code", SalesHeader."Rcvd.-from Count./Region Code", 'Received-from Country Code is set just as it is on customer');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SuggestItemChargeAssignmentPageHandler,PostedSalesDocumentLinesPageHandler')]
    procedure GetPostedDocumentLinesToReverseCopiesLinesWhenDefaultQtyToShipIsBlankInSalesReceiSetup()
    var
        Item: Record Item;
        ItemCharge: Record "Item Charge";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Quantity: Decimal;
        SalesReturnOrder: TestPage "Sales Return Order";
        SalesReturnOrderSubform: TestPage "Sales Return Order Subform";
    begin
        // [SCENARIO 500596] Get Posted Document Lines to Reverse action on Sales Return Order copies Sales Invoice Lines of Type Item Charge Even when Default Qty to Ship on Sales & Receivables Setup is set to Blank.
        Initialize();

        // [GIVEN] Validate Default Quantity to Ship in Sales & Receivables Setup.
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Default Quantity to Ship", SalesReceivablesSetup."Default Quantity to Ship"::Blank);
        SalesReceivablesSetup.Modify(true);

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create an Item Charge.
        LibraryInventory.CreateItemCharge(ItemCharge);

        // [GIVEN] Generate and Save Quantity in a Variable.
        Quantity := LibraryRandom.RandIntInRange(25, 25);

        // [GIVEN] Create a Sales Order with Item Charge.
        CreateSalesOrderWithItemCharge(SalesHeader, ItemCharge."No.", Item."No.", Quantity);

        // [GIVEN] Set Sales Order Lines Qty. to Ship.
        SetSalesLinesQtyToShip(SalesHeader, Quantity);

        // [GIVEN] Update Qty. to Assign on Item Charge Assignment.
        UpdateQtyToAssignOnItemChargeAssignment(SalesHeader);

        // [GIVEN] Post Sales Order.
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Create a Sales Return Order.
        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader2."Document Type"::"Return Order", SalesHeader."Sell-to Customer No.");

        // [GIVEN] Open Sales Return Order page and run Get Posted Document Lines to Reverse action.
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.GoToRecord(SalesHeader2);
        LibraryVariableStorage.Enqueue(ItemCharge."No.");
        SalesReturnOrder.GetPostedDocumentLinesToReverse.Invoke();

        // [WHEN] Find Sales Line of Sales Return Order.
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Return Order");
        SalesLine.SetRange("Document No.", SalesHeader2."No.");
        SalesLine.SetRange(Type, SalesLine.Type::"Charge (Item)");
        SalesLine.FindFirst();

        // [VERIFY] Return Qty. to Receive in Sales Line is 0.
        Assert.AreEqual(0, SalesLine."Return Qty. to Receive", ReturnQtyToReceiveMustBeZeroErr);

        // [WHEN] Open Sales Return Order Subform page.
        SalesReturnOrderSubform.OpenEdit();
        SalesReturnOrderSubform.GoToRecord(SalesLine);

        // [VERIFY] Quantity and Qty. to Assign in Sales Line are same.
        Assert.AreEqual(
            Quantity,
            SalesReturnOrderSubform."Qty. to Assign".AsDecimal(),
            StrSubstNo(
                QtyToAssignErr,
                SalesReturnOrderSubform."Qty. to Assign".Caption(),
                Quantity,
                SalesReturnOrderSubform.Caption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyCityIsNotChangedWhenCityIsAlreadySetAndPostCodeIsValidated()
    var
        PostCodeA: Record "Post Code";
        PostCodeB: Record "Post Code";
        PostCode: Record "Post Code";
        CountryRegion: Record "Country/Region";
        PostCodeCode: Code[20];
        CountryRegionCode: Code[10];
        CityTxt: array[2] of Text[30];
        CountyTxt: Text[30];
    begin
        // [FEATURE]
        // [SCENARIO] Verify that the city that is already set on the customer is not changed when the Post Code is validated
        Initialize();

        // [GIVEN] Multiple Post Codes for the same country with the same post code and diffrent city name
        CountryRegion.Next(LibraryRandom.RandInt(CountryRegion.Count()));
        CountryRegionCode := CountryRegion.Code;
        PostCodeCode := CopyStr(LibraryUtility.GenerateRandomCode(PostCodeA.FieldNo(Code), DATABASE::"Post Code"), 1, LibraryUtility.GetFieldLength(DATABASE::"Post Code", PostCodeA.FieldNo(Code)));
        CreatePostCode(PostCodeA, PostCodeCode, '', CountryRegionCode);
        CreatePostCode(PostCodeB, PostCodeCode, '', CountryRegionCode);
        CityTxt[1] := PostCodeA.City;
        CityTxt[2] := PostCodeB.City;

        // [WHEN] The Post Code is validated with the city name
        PostCode.ValidatePostCode(CityTxt[1], PostCodeCode, CountyTxt, CountryRegionCode, false);
        PostCode.ValidatePostCode(CityTxt[2], PostCodeCode, CountyTxt, CountryRegionCode, false);

        // [THEN] The City is not changed
        Assert.AreEqual(PostCodeA.City, CityTxt[1], 'The City should not be changed');
        Assert.AreEqual(PostCodeB.City, CityTxt[2], 'The City should not be changed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyUnitCostLCYZeroWhenItemVariantCodeValidated()
    var
        Customer: Record Customer;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Location: Record Location;
        ReturnReason: Record "Return Reason";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemNo: Code[20];
    begin
        // [SCENARIO 547101] Verify Inventory Value Zero is behaving on a Return if a Variant is added or changed and the cost is 0
        Initialize();

        // [GIVEN] Create Location with posting setup
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Create Customer with Location Code
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Location Code", Location.Code);
        Customer.Modify();

        // [GIVEN] Create Item
        ItemNo := LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Return Reason Code with Inventory Value zero
        LibraryERM.CreateReturnReasonCode(ReturnReason);
        ReturnReason.Validate("Inventory Value Zero", true);
        ReturnReason.Modify();

        // [GIVEN] Add unit cost
        Item.Validate("Unit Cost", LibraryRandom.RandDec(1, 2));
        Item.Modify();

        // [GIVEN] Create Item Variant
        LibraryInventory.CreateItemVariant(ItemVariant, ItemNo);

        // [WHEN] Validate the Return Reason code, Location Code, Quanitity and Variant Code
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Return Order", Customer."No.", SalesLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Validate("Return Reason Code", ReturnReason.Code);
        SalesLine.Validate("Location Code", Location.Code);
        SalesLine.Validate(Quantity, LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Validate("Variant Code", ItemVariant.Code);
        Salesline.Modify();

        // [THEN] Verify the Unit Cost (LCY) is zero when Return Reason Code is validated
        Assert.AreEqual(0, SalesLine."Unit Cost (LCY)", UniCostLCYErr);
    end;

    [Test]
    procedure Salesperson_SellToBlank_UserSetup()
    var
        SellToCustomer: Record Customer;
        UserSetup: Record "User Setup";
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 539321] Sell-to Customer has blank salesperson, User Setup has salesperson, Salesperson Code on sales order is set to User Setup salesperson.
        Initialize();

        LibrarySales.CreateCustomer(SellToCustomer);
        CreateUserSetupWithSalesperson(UserSetup);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SellToCustomer."No.");

        SalesHeader.TestField("Salesperson Code", UserSetup."Salespers./Purch. Code");
    end;

    [Test]
    procedure Salesperson_SellTo_UserSetup()
    var
        SellToCustomer: Record Customer;
        UserSetup: Record "User Setup";
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 539321] Sell-to Customer has salesperson, User Setup has salesperson, Salesperson Code on sales order is set to Sell-to Customer salesperson.
        Initialize();

        CreateCustomerWithSalesperson(SellToCustomer);
        CreateUserSetupWithSalesperson(UserSetup);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SellToCustomer."No.");

        SalesHeader.TestField("Salesperson Code", SellToCustomer."Salesperson Code");
    end;

    [Test]
    procedure Salesperson_SellToBlank_BillToBlank_UserSetup()
    var
        SellToCustomer, BillToCustomer : Record Customer;
        SalesHeader: Record "Sales Header";
        UserSetup: Record "User Setup";
    begin
        // [SCENARIO 539321] Sell-to Customer has blank salesperson, Bill-to Customer has blank salesperson, User Setup has salesperson, Salesperson Code on sales order is set to User Setup salesperson.
        Initialize();

        LibrarySales.CreateCustomer(SellToCustomer);
        LibrarySales.CreateCustomer(BillToCustomer);
        SellToCustomer.Validate("Bill-to Customer No.", BillToCustomer."No.");
        SellToCustomer.Modify(true);
        CreateUserSetupWithSalesperson(UserSetup);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SellToCustomer."No.");

        SalesHeader.TestField("Salesperson Code", UserSetup."Salespers./Purch. Code");
    end;

    [Test]
    procedure Salesperson_SellTo_BillToBlank()
    var
        SellToCustomer, BillToCustomer : Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 539321] Sell-to Customer has salesperson, Bill-to Customer has blank salesperson, Salesperson Code on sales order is set to blank.
        Initialize();

        CreateCustomerWithSalesperson(SellToCustomer);
        LibrarySales.CreateCustomer(BillToCustomer);
        SellToCustomer.Validate("Bill-to Customer No.", BillToCustomer."No.");
        SellToCustomer.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SellToCustomer."No.");

        SalesHeader.TestField("Salesperson Code", '');
    end;

    [Test]
    procedure Salesperson_SellTo_BillTo_UserSetup()
    var
        SellToCustomer, BillToCustomer : Record Customer;
        SalesHeader: Record "Sales Header";
        UserSetup: Record "User Setup";
    begin
        // [SCENARIO 539321] Sell-to Customer has salesperson, Bill-to Customer has salesperson, User Setup has salesperson, Salesperson Code on sales order is set to Bill-to Customer salesperson.
        Initialize();

        CreateCustomerWithSalesperson(SellToCustomer);
        CreateCustomerWithSalesperson(BillToCustomer);
        SellToCustomer.Validate("Bill-to Customer No.", BillToCustomer."No.");
        SellToCustomer.Modify(true);
        CreateUserSetupWithSalesperson(UserSetup);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SellToCustomer."No.");

        SalesHeader.TestField("Salesperson Code", BillToCustomer."Salesperson Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure Salesperson_SellTo_BillTo_ResetBillTo()
    var
        SellToCustomer, BillToCustomer : Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 539321] Sell-to Customer has salesperson, Bill-to Customer has salesperson, Salesperson Code on sales order is set to Sell-to Customer salesperson after Bill-to Customer No. is reset.
        Initialize();

        CreateCustomerWithSalesperson(SellToCustomer);
        CreateCustomerWithSalesperson(BillToCustomer);
        SellToCustomer.Validate("Bill-to Customer No.", BillToCustomer."No.");
        SellToCustomer.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SellToCustomer."No.");
        SalesHeader.TestField("Salesperson Code", BillToCustomer."Salesperson Code");

        SalesHeader.Validate("Bill-to Customer No.", SellToCustomer."No.");

        SalesHeader.TestField("Salesperson Code", SellToCustomer."Salesperson Code");
    end;

    [Test]
    procedure Salesperson_SellTo_ShipTo()
    var
        SellToCustomer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 539321] Sell-to Customer has salesperson, Ship-to Address has salesperson, Salesperson Code on sales order is set to Ship-to Address salesperson.
        Initialize();

        CreateCustomerWithSalesperson(SellToCustomer);
        CreateShipToAddressWithSalesperson(ShipToAddress, SellToCustomer."No.");

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SellToCustomer."No.");
        SalesHeader.Validate("Ship-to Code", ShipToAddress."Code");

        SalesHeader.TestField("Salesperson Code", ShipToAddress."Salesperson Code");
    end;

    [Test]
    procedure Salesperson_SellTo_ShipTo_ShipToBlank_ChangeShipTo()
    var
        SellToCustomer: Record Customer;
        ShipToAddress1, ShipToAddress2 : Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 539321] Sell-to Customer has salesperson, Ship-to Address1 has salesperson, Ship-to Address2 has blank salesperson, Salesperson Code on sales order stays with Ship-to Address1 salesperson after Ship-to Address2 is selected.
        Initialize();

        CreateCustomerWithSalesperson(SellToCustomer);
        CreateShipToAddressWithSalesperson(ShipToAddress1, SellToCustomer."No.");
        SellToCustomer.Validate("Ship-to Code", ShipToAddress1."Code");
        SellToCustomer.Modify(true);
        LibrarySales.CreateShipToAddress(ShipToAddress2, SellToCustomer."No.");

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SellToCustomer."No.");
        SalesHeader.TestField("Salesperson Code", ShipToAddress1."Salesperson Code");

        SalesHeader.Validate("Ship-to Code", ShipToAddress2."Code");

        SalesHeader.TestField("Salesperson Code", ShipToAddress1."Salesperson Code");
    end;

    [Test]
    procedure Salesperson_SellTo_ShipTo_ShipTo2()
    var
        SellToCustomer: Record Customer;
        ShipToAddress1, ShipToAddress2 : Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 539321] Sell-to Customer has salesperson, Ship-to Address1 has salesperson, Ship-to Address2 has salesperson, Salesperson Code on sales order is set to Ship-to Address2 salesperson.
        Initialize();

        CreateCustomerWithSalesperson(SellToCustomer);
        CreateShipToAddressWithSalesperson(ShipToAddress1, SellToCustomer."No.");
        CreateShipToAddressWithSalesperson(ShipToAddress2, SellToCustomer."No.");
        SellToCustomer.Validate("Ship-to Code", ShipToAddress1."Code");
        SellToCustomer.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SellToCustomer."No.");
        SalesHeader.TestField("Salesperson Code", ShipToAddress1."Salesperson Code");

        SalesHeader.Validate("Ship-to Code", ShipToAddress2."Code");

        SalesHeader.TestField("Salesperson Code", ShipToAddress2."Salesperson Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure Salesperson_SellTo_BillTo_ShipTo_ChangeBillTo()
    var
        SellToCustomer, BillToCustomer1, BillToCustomer2 : Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 539321] Sell-to Customer has salesperson, Bill-to Customers have salesperson, Ship-to Address has salesperson, Salesperson Code on sales order stays with Ship-to Address salesperson after Bill-to Customer No. is changed.
        Initialize();

        CreateCustomerWithSalesperson(SellToCustomer);
        CreateCustomerWithSalesperson(BillToCustomer1);
        CreateCustomerWithSalesperson(BillToCustomer2);
        CreateShipToAddressWithSalesperson(ShipToAddress, SellToCustomer."No.");
        SellToCustomer.Validate("Bill-to Customer No.", BillToCustomer1."No.");
        SellToCustomer.Validate("Ship-to Code", ShipToAddress."Code");
        SellToCustomer.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SellToCustomer."No.");
        SalesHeader.TestField("Salesperson Code", ShipToAddress."Salesperson Code");

        SalesHeader.Validate("Bill-to Customer No.", BillToCustomer2."No.");

        SalesHeader.TestField("Salesperson Code", ShipToAddress."Salesperson Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure Salesperson_SellTo_BillTo_ShipToBlank_ManualEdit_ChangeBillTo()
    var
        Salesperson: Record "Salesperson/Purchaser";
        SellToCustomer, BillToCustomer : Record Customer;
        ShipToAddress: Record "Ship-to Address";
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO 539321] Sell-to Customer has salesperson, Bill-to Customer has salesperson, Ship-to Address has blank salesperson, Salesperson Code on sales order is set to Bill-to Customer salesperson after Salesperson Code on sales order is manually edited.
        Initialize();

        LibrarySales.CreateSalesperson(Salesperson);
        CreateCustomerWithSalesperson(SellToCustomer);
        CreateCustomerWithSalesperson(BillToCustomer);
        LibrarySales.CreateShipToAddress(ShipToAddress, SellToCustomer."No.");
        SellToCustomer.Validate("Ship-to Code", ShipToAddress."Code");
        SellToCustomer.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SellToCustomer."No.");

        SalesHeader.Validate("Salesperson Code", Salesperson."Code");
        SalesHeader.Modify(true);

        SalesHeader.Validate("Bill-to Customer No.", BillToCustomer."No.");

        SalesHeader.TestField("Salesperson Code", BillToCustomer."Salesperson Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure UnreliazedGainLossEntrieAreClearWhenUsingMultiplePostingGroups()
    var
        Currency: Record Currency;
        CurrencyExchangeRate: array[3] of Record "Currency Exchange Rate";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvHeader: Record "Sales Invoice Header";
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        CustomerPostingGroup: array[2] of Record "Customer Posting Group";
        ActualAmount: array[2] of Decimal;
        PostingDate: array[3] of Date;
        PaymentDocNo: Code[20];
        VATCalculationType: Enum "Tax Calculation Type";
    begin
        // [SCENARIO 563207] Unrealized Gain / Loss is cleared during applicaiton when using multiple customer posting groups.
        Initialize();

        // [GIVEN] Set Journal Templ Name mandatory to false.
        SetJournalTemplNameMandatoryFalse();

        // [GIVEN] Generate Posting Date.
        GeneratePostingDate(PostingDate);

        // [GIVEN] Create Currency and Exchange Rates.
        CreateCurrencyWithExchangeRates(Currency, CurrencyExchangeRate, PostingDate);

        // [GIVEN] Create VAT Posting Setup with Zero Vat.
        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATCalculationType::"Normal VAT", 0);

        // [GIVEN] Create Customer Posting Group One.
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup[1]);

        // [GIVEN] Set Allowed Multiple Posting Groups.
        SetSalesAllowMultiplePostingGroups(true);

        // [GIVEN Create Customer.
        CreateCustomerWithAllowMultiplePostingGroups(
            Customer, CustomerPostingGroup[1].Code,
            Currency.Code, VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] Create Alternative Customer Posting Group.
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup[2]);
        LibrarySales.CreateAltCustomerPostingGroup(CustomerPostingGroup[1].Code, CustomerPostingGroup[2].Code);

        // [GIVEN] Create Item.
        Item.Get(LibraryInventory.CreateItemNoWithVATProdPostingGroup(VATPostingSetup."VAT Prod. Posting Group"));

        // [GIVEN] Create Sales Invoice.
        CreateSalesInvoice(SalesHeader, SalesLine, PostingDate[3], Item."No.", Customer."No.");

        // [GIVEN] Post Sales Invoice.
        SalesInvHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [GIVEN] Run Exchange Rate Adjustment.
        LibraryERM.RunExchRateAdjustment(Currency.Code, PostingDate[3], PostingDate[1], AdjustExchRateDefaultDescTxt, PostingDate[2], LibraryRandom.RandText(10), false);

        // [GIVEN] Create General Journal Batch.
        CreateGeneralJournalBatch(GenJournalBatch, true);

        // [GIVEN] Create a Payment and Post.
        CreatePaymentAndPost(GenJournalLine, GenJournalBatch, Customer."No.", CustomerPostingGroup[2].Code, PostingDate[1], PaymentDocNo);

        // [WHEN] Apply Payment with Invoice.
        ApplyPostCustPayment2Invoices(PaymentDocNo, SalesInvHeader."No.");

        // [THEN] Verify G/L Entries for Payable Account are Balanced.
        VerifyGLEntryForAccount(CustomerPostingGroup, ActualAmount);
    end;

    [Test]
    procedure QuoteToInvoiceAutomaticSalesInvoiceRespectsWorkDate()
    var
        PaymentTerms: Record "Payment Terms";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: array[2] of Record "Sales Header";
        SalesQuoteToInvoice: Codeunit "Sales-Quote to Invoice";
    begin
        // [SCENARIO 571490] Document Date and Due Date is updated with Posting Date from Sales Quote to Sales Invoice
        Initialize();

        // [GIVEN] Validate Link Doc. Date To Posting Date and Default Posting Date in Sales and Receivables Setup.
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Link Doc. Date To Posting Date", true);
        SalesReceivablesSetup.Validate("Default Posting Date", SalesReceivablesSetup."Default Posting Date"::"Work Date");
        SalesReceivablesSetup.Modify(true);

        // [GIVEN] Create new Sales Quote for a Customer.
        LibrarySales.CreateSalesQuoteForCustomerNo(SalesHeader[1], LibrarySales.CreateCustomerNo());
        SalesHeader[1].Validate("Document Date", WorkDate() - 1);
        SalesHeader[1].Modify();

        // [GIVEN] Create Payment Terms Code.
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);

        // [GIVEN] Validate Payment Terms Code in Sales Header.
        SalesHeader[1].Validate(SalesHeader[1]."Payment Terms Code", PaymentTerms.Code);
        SalesHeader[1].Modify(true);

        // [WHEN] Run Sales-Invoice to Order.
        SalesQuoteToInvoice.Run(SalesHeader[1]);

        // [THEN] Invoice created with no errors.
        SalesQuoteToInvoice.GetSalesInvoiceHeader(SalesHeader[2]);

        // [THEN] Document Date should be updated as per Work Date.
        Assert.AreEqual(
            WorkDate(),
            SalesHeader[2]."Document Date",
            StrSubstNo(
                DateErr,
                SalesHeader[2].FieldCaption("Document Date"),
                WorkDate(),
                SalesHeader[2].TableCaption()));

        // [THEN] Due Date should be updated as per Work Date.
        Assert.AreEqual(
            CalcDate(PaymentTerms."Due Date Calculation", WorkDate()),
            SalesHeader[2]."Due Date",
            StrSubstNo(
                DateErr,
                SalesHeader[2].FieldCaption("Document Date"),
                WorkDate(),
                SalesHeader[2].TableCaption()));
    end;

    local procedure Initialize()
    var
        ReportSelections: Record "Report Selections";
        UserSetup: Record "User Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Sales Documents III");
        LibraryApplicationArea.DisableApplicationAreaSetup();
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        LibraryPriceCalculation.DisableExtendedPriceCalculation();
        UserSetup.DeleteAll();

        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Sales Documents III");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");

        ReportSelections.SetRange(Usage, LibraryERMCountryData.GetReportSelectionsUsageSalesQuote());
        ReportSelections.ModifyAll("Report ID", REPORT::"Standard Sales - Quote");

        isInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Sales Documents III");
    end;

    local procedure CreatePostSalesDocWithGLDescriptionLine(var SalesHeader: Record "Sales Header"; var LineDescription: Text[50]; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
            SalesLine, SalesHeader, SalesLine.Type::"G/L Account",
            LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandIntInRange(2, 5));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type, SalesLine."No.", 0);
        SalesLine.Validate("No.", '');
        LineDescription := CopyStr(LibraryUtility.GenerateRandomXMLText(10), 1, MaxStrLen(SalesLine.Description));
        SalesLine.Validate(Description, LineDescription);
        SalesLine.Modify(true);
    end;

    local procedure CreateAndArchiveSalesOrderWithRespCenter(CustomerNo: Code[20]; RespCenterCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        CreateSalesDocumentWithUnitPrice(
          SalesHeader, SalesHeader."Document Type"::Order, CustomerNo, SalesLine.Type::Item, LibraryInventory.CreateItemNo());
        SalesHeader.Validate("Responsibility Center", RespCenterCode);
        SalesHeader.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        ArchiveManagement.StoreSalesDocument(SalesHeader, false);
    end;

    local procedure CreateAndUpdateSalesRetOrder(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        OptionString: Option PostedReturnReceipt,PostedInvoices;
    begin
        // Create Sales Return Order and Get Posted Invoice Line to Reverse and update Apply from Item Entry.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", CustomerNo);
        GetPostedInvoiceLines(SalesHeader."No.", OptionString::PostedInvoices);
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine.Type::Item);
        SalesLine.Validate("Appl.-from Item Entry", 0);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Use Random value for Unit Price.
        SalesLine.Modify(true);
    end;

    local procedure CreateCreditMemo(var SalesHeader: Record "Sales Header"; No: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Sell-to Customer No.");
        CreateCrMemoLnWithGetRetRcptLn(SalesHeader, No);
    end;

    local procedure CreateCrMemoLnWithGetRetRcptLn(SalesHeader: Record "Sales Header"; No: Code[20])
    var
        ReturnReceiptLine: Record "Return Receipt Line";
        SalesGetReturnReceipts: Codeunit "Sales-Get Return Receipts";
    begin
        SalesGetReturnReceipts.SetSalesHeader(SalesHeader);
        ReturnReceiptLine.SetRange("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
        ReturnReceiptLine.SetRange("No.", No);
        ReturnReceiptLine.FindFirst();
        SalesGetReturnReceipts.CreateInvLines(ReturnReceiptLine);
    end;

    local procedure CreateInvDiscountForCustomer(var CustInvoiceDisc: Record "Cust. Invoice Disc."; CustomerNo: Code[20]; Discount: Decimal; ServiceCharge: Decimal)
    begin
        LibraryERM.CreateInvDiscForCustomer(CustInvoiceDisc, CustomerNo, '', 0);
        CustInvoiceDisc.Validate("Discount %", Discount);
        CustInvoiceDisc.Validate("Service Charge", ServiceCharge);
        CustInvoiceDisc.Modify(true);
    end;

    local procedure CreateItemAndExtendedText(AutoExtText: Boolean): Code[20]
    var
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
        Item: Record Item;
    begin
        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, LibraryInventory.CreateItemNo());
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
        ExtendedTextLine.Validate(Text, ExtendedTextHeader."No.");
        ExtendedTextLine.Modify(true);
        Item.Get(ExtendedTextHeader."No.");
        Item.Validate("Automatic Ext. Texts", AutoExtText);
        Item.Modify(true);
        exit(ExtendedTextHeader."No.");
    end;

    local procedure CreateItemSubstitutionWithExtendedText(ItemNo: Code[20]; AutoExtText: Boolean)
    var
        ItemSubstitution: Record "Item Substitution";
    begin
        ItemSubstitution.Init();
        ItemSubstitution.Validate(Type, ItemSubstitution.Type::Item);
        ItemSubstitution.Validate("No.", ItemNo);
        ItemSubstitution.Validate("Substitute Type", ItemSubstitution."Substitute Type"::Item);
        ItemSubstitution.Validate("Substitute No.", CreateItemAndExtendedText(AutoExtText));
        ItemSubstitution.Insert();
    end;

    local procedure CreateItemTrackingCode(): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, false);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateResponsibilityCenterAndUserSetup(): Code[10]
    var
        Location: Record Location;
        UserSetup: Record "User Setup";
        ResponsibilityCenter: Record "Responsibility Center";
    begin
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        LibraryService.CreateResponsibilityCenter(ResponsibilityCenter);
        ResponsibilityCenter.Validate("Location Code", LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location));
        ResponsibilityCenter.Modify(true);
        UserSetup.Validate("Sales Resp. Ctr. Filter", ResponsibilityCenter.Code);
        UserSetup.Modify(true);
        exit(ResponsibilityCenter.Code);
    end;

    local procedure CreateSalesDocumentWithItem(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocumentWithUnitPrice(
          SalesHeader, DocumentType, LibrarySales.CreateCustomerNo(), SalesLine.Type::Item, LibraryInventory.CreateItemNo());
    end;

    local procedure CreateSalesDocumentWithGL(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocumentWithUnitPrice(
          SalesHeader, DocumentType, LibrarySales.CreateCustomerNo(),
          SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup());
    end;

    local procedure CreateSalesDocumentItem(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocumentWithUnitPrice(
          SalesHeader, DocumentType, LibrarySales.CreateCustomerNo(), SalesLine.Type::Item, ItemNo);
    end;

    local procedure CreateSalesDocumentGL(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; GLAccountNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocumentWithUnitPrice(
          SalesHeader, DocumentType, LibrarySales.CreateCustomerNo(), SalesLine.Type::"G/L Account", GLAccountNo);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; Type: Enum "Sales Line Type"; No: Code[20]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, Quantity);
    end;

    local procedure CreateSalesDocumentWithUnitPrice(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustomerNo: Code[20]; Type: Enum "Sales Line Type"; No: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocument(SalesHeader, SalesLine, DocumentType, CustomerNo, Type, No, LibraryRandom.RandIntInRange(10, 20));
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(1000, 2000));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineDiscount(var SalesLineDiscount: Record "Sales Line Discount"; ItemNo: Code[20]; CustomerNo: Code[20]; MinQty: Decimal; DiscountPct: Decimal)
    begin
        LibraryERM.CreateLineDiscForCustomer(
          SalesLineDiscount, SalesLineDiscount.Type::Item, ItemNo, SalesLineDiscount."Sales Type"::Customer, CustomerNo,
          WorkDate(), '', '', '', MinQty);
        SalesLineDiscount.Validate("Line Discount %", DiscountPct);
        SalesLineDiscount.Modify(true);
    end;
 
    local procedure CreateSalesLineWithItem(var Item: Record Item; SalesHeader: Record "Sales Header"; QtyToShip: Decimal; VATProdPostingGroup: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandInt(100), LibraryRandom.RandInt(100));
        Item.Validate("VAT Prod. Posting Group", VATProdPostingGroup);
        Item.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10) + QtyToShip);
        SalesLine.Validate("Qty. to Ship", QtyToShip);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesExtLine(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        TransferExtendedText: Codeunit "Transfer Extended Text";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        TransferExtendedText.SalesCheckIfAnyExtText(SalesLine, true);
        TransferExtendedText.InsertSalesExtText(SalesLine);
    end;

    local procedure CreateSalesInvoiceWithQuoteNo(var SalesHeaderInvFromQuote: Record "Sales Header")
    var
        SalesHeaderQuote: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeaderQuote, SalesHeaderQuote."Document Type"::Quote, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesHeader(
          SalesHeaderInvFromQuote, SalesHeaderInvFromQuote."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesHeaderInvFromQuote.Validate("Quote No.", SalesHeaderInvFromQuote."No.");
        SalesHeaderInvFromQuote.Modify(true);
    end;

    local procedure CreateSalesOrderWithSeveralItemsAndCalcInvDiscount(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20]; ItemNos: array[10] of Code[20]; NoOfLines: Integer)
    var
        i: Integer;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        for i := 1 to NoOfLines do begin
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNos[i], LibraryRandom.RandInt(10));
            SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
            SalesLine.Modify(true);
        end;
        SalesHeader.CalcInvDiscForHeader();
    end;

    local procedure CreatePostSalesDocWithGL(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; Invoice: Boolean): Code[20]
    begin
        CreateSalesDocumentGL(SalesHeader, DocumentType, LibraryERM.CreateGLAccountWithSalesSetup());
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, Invoice));
    end;

    local procedure CreatePostSalesDoc(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; GLAccountNo: Code[20]; Invoice: Boolean): Code[20]
    begin
        CreateSalesDocumentGL(SalesHeader, DocumentType, GLAccountNo);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, Invoice));
    end;

    local procedure CreatePostSalesDocWithAutoExtText(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; PostInvoice: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocumentWithUnitPrice(
          SalesHeader, DocumentType, LibrarySales.CreateCustomerNo(),
          SalesLine.Type::Item, CreateItemAndExtendedText(true));
        CreateSalesExtLine(SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, PostInvoice);
    end;

    local procedure CreateSalesPriceForItemAndAllCustomers(var SalesPrice: Record "Sales Price")
    var
        Item: Record Item;
        PriceListLine: Record "Price List Line";
    begin
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesPrice(
          SalesPrice, Item."No.", "Sales Price Type"::"All Customers", '', WorkDate(), '', '', '', 0, LibraryRandom.RandDec(100, 2));
        CopyFromToPriceListLine.CopyFrom(SalesPrice, PriceListLine);
    end;

    local procedure CreateShippingAgent(var ShippingAgent: Record "Shipping Agent"; ShippingInternetAddress: Text[250]; var PackageTrackingNo: Text[50])
    begin
        LibraryInventory.CreateShippingAgent(ShippingAgent);
        ShippingAgent."Internet Address" := ShippingInternetAddress;
        ShippingAgent.Modify();
        PackageTrackingNo := LibraryUtility.GenerateGUID();
    end;

    local procedure CreateCustomerWithPostCodeAndCity(var Customer: Record Customer)
    var
        PostCode: Record "Post Code";
    begin
        LibraryERM.CreatePostCode(PostCode);
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Post Code", PostCode.Code);
        Customer.Validate(City, PostCode.City);
        Customer.Modify(true);
    end;

    local procedure CreateCustomerWithShippingTime(var Customer: Record Customer)
    var
        ShippingTime: DateFormula;
    begin
        LibrarySales.CreateCustomer(Customer);
        Evaluate(ShippingTime, StrSubstNo('<%1D>', LibraryRandom.RandInt(10)));
        Customer.Validate("Shipping Time", ShippingTime);
        Customer.Modify(true);
    end;

    local procedure CreateCustomerWithSalesperson(var Customer: Record Customer)
    var
        Salesperson: Record "Salesperson/Purchaser";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesperson(Salesperson);
        Customer.Validate("Salesperson Code", Salesperson.Code);
        Customer.Modify(true);
    end;

    local procedure CreateUserSetupWithSalesperson(var UserSetup: Record "User Setup")
    var
        Salesperson: Record "Salesperson/Purchaser";
    begin
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        LibrarySales.CreateSalesperson(Salesperson);
        UserSetup.Validate("Salespers./Purch. Code", Salesperson.Code);
        UserSetup.Modify(true);
    end;

    local procedure CreateShipToAddressWithSalesperson(var ShipToAddress: Record "Ship-to Address"; CustomerNo: Code[20])
    var
        Salesperson: Record "Salesperson/Purchaser";
    begin
        LibrarySales.CreateShipToAddress(ShipToAddress, CustomerNo);
        LibrarySales.CreateSalesperson(Salesperson);
        ShipToAddress.Validate("Salesperson Code", Salesperson.Code);
        ShipToAddress.Modify(true);
    end;

    local procedure CreatePostCode(var PostCode: Record "Post Code"; "Code": Code[20])
    begin
        PostCode.Init();
        PostCode.Validate(Code, Code);
        PostCode.Validate(
          City,
          CopyStr(
            LibraryUtility.GenerateRandomCode(PostCode.FieldNo(City), DATABASE::"Post Code"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Post Code", PostCode.FieldNo(City))));
        PostCode.Insert(true);
    end;

    local procedure CreateRetReasonCode(): Code[10]
    var
        ReturnReason: Record "Return Reason";
    begin
        LibraryERM.CreateReturnReasonCode(ReturnReason);
        exit(ReturnReason.Code);
    end;

    local procedure CreateCityForPostCode(var PostCode: Record "Post Code"; City: Text[30])
    begin
        PostCode.Init();
        PostCode.Validate(
          Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(PostCode.FieldNo(Code), DATABASE::"Post Code"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Post Code", PostCode.FieldNo(Code))));
        PostCode.Validate(City, City);
        PostCode.Insert(true);
    end;

    local procedure CreateShipmentsAndSalesInvoice(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        CustomerNo: Code[20];
    begin
        CreateSalesDocumentWithItem(SalesHeader, SalesHeader."Document Type"::Order);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        CustomerNo := SalesHeader."Sell-to Customer No.";
        CreateSalesDocumentWithItem(SalesHeader, SalesHeader."Document Type"::Order);
        SalesHeader.Validate("Bill-to Customer No.", CustomerNo);
        SalesHeader.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
    end;

    local procedure CreateTrackedItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateTrackedItem(Item, LibraryUtility.GetGlobalNoSeriesCode(), '', CreateItemTrackingCode());
        exit(Item."No.");
    end;

    local procedure CreateVATPostingSetupWithCertificateOfSupply(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        VATPostingSetup.Validate("VAT Bus. Posting Group", VATBusinessPostingGroup.Code);
        VATPostingSetup.Validate("Certificate of Supply Required", true);
        VATPostingSetup.Insert(true);
    end;

    local procedure CreateSalesLineSimple(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; LineNo: Integer)
    begin
        SalesLine.Init();
        SalesLine.Validate("Document Type", SalesHeader."Document Type");
        SalesLine.Validate("Document No.", SalesHeader."No.");
        SalesLine.Validate("Line No.", LineNo);
        SalesLine.Insert(true);
    end;

    local procedure CreateSalesLineAndItem(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandIntInRange(10, 100), LibraryRandom.RandIntInRange(10, 100));
        Item.Validate("Stockout Warning", Item."Stockout Warning"::No);
        Item.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandIntInRange(10, 100));
    end;

    local procedure CreateSalesDocumentWithSingleLineWithQuantity(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; LineQuantity: Decimal)
    var
        CustInvoiceDisc: Record "Cust. Invoice Disc.";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
    begin
        CustomerNo := LibrarySales.CreateCustomerNo();

        CreateInvDiscountForCustomer(
          CustInvoiceDisc, CustomerNo, LibraryRandom.RandIntInRange(10, 20), LibraryRandom.RandIntInRange(10, 100));

        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        CreateSalesLineAndItem(SalesLine, SalesHeader);
        SalesLine.Validate(Quantity, LineQuantity);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesDocumentWithTwoLinesSecondLineQuantityZero(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type")
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesDocumentWithSingleLineWithQuantity(SalesHeader, DocumentType, LibraryRandom.RandDecInRange(10, 20, 2));
        CreateSalesLineAndItem(SalesLine, SalesHeader);
        SalesLine.Validate(Quantity, 0);
        SalesLine.Modify(true);
        SalesHeader.SetRecFilter();
    end;

    local procedure CreateSalesOrderWithItemAndChargeItem(var SalesHeaderOrder: Record "Sales Header"; var SalesLineItem: Record "Sales Line"; var SalesLineChargeItem: Record "Sales Line"; QtyToAssign: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeaderOrder, SalesHeaderOrder."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
          SalesLineItem, SalesHeaderOrder, SalesLineItem.Type::Item, LibraryInventory.CreateItemNo(), QtyToAssign + 1);
        LibrarySales.CreateSalesLine(
          SalesLineChargeItem, SalesHeaderOrder,
          SalesLineChargeItem.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), QtyToAssign);
        SalesLineChargeItem.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesLineChargeItem.Modify(true);

        LibraryVariableStorage.Enqueue(QtyToAssign);
        SalesLineChargeItem.ShowItemChargeAssgnt();
        SalesLineChargeItem.Modify(true);

        Commit();

        SalesLineChargeItem.Find();
        SalesLineChargeItem.CalcFields("Qty. to Assign");
        SalesLineChargeItem.TestField("Qty. to Assign", QtyToAssign);
    end;

    local procedure CreateSalesOrderWithChargeItemAndItem(var SalesHeaderOrder: Record "Sales Header"; var SalesLineItem: Record "Sales Line"; var SalesLineChargeItem: Record "Sales Line"; QtyToAssign: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeaderOrder, SalesHeaderOrder."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
          SalesLineChargeItem, SalesHeaderOrder,
          SalesLineChargeItem.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), QtyToAssign);
        SalesLineChargeItem.Validate("Unit Price", LibraryRandom.RandDec(10, 2));
        SalesLineChargeItem.Modify(true);

        LibrarySales.CreateSalesLine(
          SalesLineItem, SalesHeaderOrder, SalesLineItem.Type::Item, LibraryInventory.CreateItemNo(), QtyToAssign + 1);

        LibraryVariableStorage.Enqueue(QtyToAssign);
        SalesLineChargeItem.ShowItemChargeAssgnt();
        SalesLineChargeItem.Modify(true);

        Commit();

        SalesLineChargeItem.Find();
        SalesLineChargeItem.CalcFields("Qty. to Assign");
        SalesLineChargeItem.TestField("Qty. to Assign", QtyToAssign);
    end;

    local procedure GetShipmentLinesWithOrder(SalesHeaderInvoice: Record "Sales Header"; SalesHeaderOrder: Record "Sales Header"; ReversedOrder: Boolean)
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
    begin
        SalesShipmentLine.Ascending(ReversedOrder);
        SalesShipmentLine.SetCurrentKey("Document No.", "Line No.");
        SalesShipmentLine.SetRange("Order No.", SalesHeaderOrder."No.");

        SalesGetShipment.SetSalesHeader(SalesHeaderInvoice);
        SalesGetShipment.CreateInvLines(SalesShipmentLine);
    end;

    local procedure GetStatusStyleText(Status: Enum "Sales Document Status"): Text
    var
        SalesHeader: Record "Sales Header";
    begin
        SalesHeader.Init();
        SalesHeader.Status := Status;
        exit(SalesHeader.GetStatusStyleText());
    end;

    local procedure MockSalesInvoiceLine(DocumentNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine."Document Type" := SalesLine."Document Type"::Invoice;
        SalesLine."Document No." := DocumentNo;
        SalesLine."Line No." := 10000;
        // Value is important for test
        SalesLine.Insert();
    end;

    local procedure MockSalesOrder(var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Init();
        SalesHeader."Document Type" := SalesHeader."Document Type"::Order;
        SalesHeader."No." := LibraryUtility.GenerateRandomCode(SalesHeader.FieldNo("No."), DATABASE::"Sales Header");
        SalesHeader.Insert();
    end;

    local procedure MockSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := LibraryUtility.GetNewRecNo(SalesLine, SalesLine.FieldNo("Line No."));
        SalesLine.Insert();
    end;

    local procedure InitSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type")
    begin
        SalesLine.Init();
        SalesLine."Document Type" := DocumentType;
        SalesLine."Document No." := LibraryUtility.GenerateGUID();
        SalesLine."Line No." := LibraryRandom.RandIntInRange(1000, 2000);
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := '';
        SalesLine.Description := LibraryUtility.GenerateGUID();
        SalesLine.Quantity := LibraryRandom.RandDecInRange(300, 400, 2);
        SalesLine."Qty. to Ship" := LibraryRandom.RandDecInRange(200, 300, 2);
        SalesLine."Qty. to Ship (Base)" := LibraryRandom.RandDecInRange(200, 300, 2);
        SalesLine."Qty. to Invoice" := LibraryRandom.RandDecInRange(100, 200, 2);
        SalesLine."Qty. to Invoice (Base)" := LibraryRandom.RandDecInRange(100, 200, 2);
        SalesLine."Return Qty. to Receive" := LibraryRandom.RandDecInRange(200, 300, 2);
        SalesLine."Return Qty. to Receive (Base)" := LibraryRandom.RandDecInRange(200, 300, 2);
    end;

    local procedure ValidateSalesLineStandardCode(var SalesLine: Record "Sales Line"; StandardTextCode: Code[20])
    var
        TransferExtendedText: Codeunit "Transfer Extended Text";
    begin
        SalesLine.Validate("No.", StandardTextCode);
        SalesLine.Modify(true);
        TransferExtendedText.SalesCheckIfAnyExtText(SalesLine, false);
        TransferExtendedText.InsertSalesExtText(SalesLine);
    end;

    local procedure DeleteUserSetup(var UserSetup: Record "User Setup"; ResponsibilityCenterCode: Code[10])
    begin
        UserSetup.SetRange("Sales Resp. Ctr. Filter", ResponsibilityCenterCode);
        UserSetup.FindFirst();
        UserSetup.Delete(true);
    end;

    local procedure FindCity("Code": Code[20]): Text[30]
    var
        PostCode: Record "Post Code";
    begin
        PostCode.SetRange(Code, Code);
        PostCode.FindFirst();
        exit(PostCode.City);
    end;

    local procedure FindCrMemoLine(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; DocumentNo: Code[20])
    begin
        SalesCrMemoLine.SetRange("Document No.", DocumentNo);
        SalesCrMemoLine.SetFilter("No.", '<>%1', '');
        SalesCrMemoLine.FindFirst();
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; GLAccountNo: Code[20]; DocumentNo: Code[20])
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
    end;

    local procedure FindPostCode(City: Text[30]): Code[20]
    var
        PostCode: Record "Post Code";
    begin
        PostCode.SetRange(City, City);
        PostCode.FindFirst();
        exit(PostCode.Code);
    end;

    local procedure FindRetRcptLine(var ReturnReceiptLine: Record "Return Receipt Line"; DocumentNo: Code[20])
    begin
        ReturnReceiptLine.SetRange("Document No.", DocumentNo);
        ReturnReceiptLine.SetFilter("No.", '<>%1', '');
        ReturnReceiptLine.FindFirst();
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; Type: Enum "Sales Line Type")
    begin
        SalesLine.SetRange("Document Type", DocumentType);
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange(Type, Type);
        SalesLine.FindFirst();
    end;

    local procedure FilterSalesCreditMemoLine(var SalesLine: Record "Sales Line"; DocumentNo: Code[20]; ItemNo: Code[20])
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::"Credit Memo");
        SalesLine.SetRange("Document No.", DocumentNo);
        SalesLine.SetRange("No.", ItemNo);
    end;

    local procedure ModifyAndAddSalesLine(SalesHeader: Record "Sales Header"; ZeroQtyToShip: Boolean)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindLast();
        SalesLine.Validate(Quantity, -SalesLine.Quantity);
        SalesLine.Modify();
        SalesLine."Line No." += 10000;
        SalesLine.Validate(Quantity, -SalesLine.Quantity * 2);
        if ZeroQtyToShip then begin
            SalesLine.Insert();
            SalesLine."Line No." += 10000;
            SalesLine.Validate("Qty. to Ship", 0);
        end else
            SalesLine.Validate("Qty. to Ship", SalesLine.Quantity / 2);
        SalesLine.Insert();
    end;

    local procedure ModifyReturnReasonCode(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; ReturnReasonCode: Code[10])
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, DocumentType, DocumentNo, SalesLine.Type::Item);
        SalesLine.Validate("Return Reason Code", ReturnReasonCode);
        SalesLine.Modify();
    end;

    local procedure ModifySalesLine(DocumentType: Enum "Sales Document Type"; DocumentNo: Code[20]; LineType: Enum "Sales Line Type"; NewQuantity: Decimal; NewUnitPrice: Decimal; NewLineDiscountAmt: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, DocumentType, DocumentNo, LineType);
        SalesLine.Validate(Quantity, NewQuantity);
        SalesLine.Validate("Unit Price", NewUnitPrice);
        SalesLine.Validate("Line Discount Amount", NewLineDiscountAmt);
        SalesLine.Modify();
    end;

    local procedure GetPostedDocumentLines(No: Code[20]; OptionString: Option)
    var
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        LibraryVariableStorage.Enqueue(OptionString);
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.FILTER.SetFilter("No.", No);
        SalesCreditMemo.GetPostedDocumentLinesToReverse.Invoke();
    end;

    local procedure GetPostedInvoiceLines(No: Code[20]; OptionString: Option)
    var
        SalesReturnOrder: TestPage "Sales Return Order";
    begin
        LibraryVariableStorage.Enqueue(OptionString);
        SalesReturnOrder.OpenEdit();
        SalesReturnOrder.FILTER.SetFilter("No.", No);
        SalesReturnOrder.GetPostedDocumentLinesToReverse.Invoke();
    end;

    local procedure GetPostedDocLinesToReverse(var SalesHeader: Record "Sales Header"; OptionString: Option)
    begin
        LibraryVariableStorage.Enqueue(OptionString);
        SalesHeader.GetPstdDocLinesToReverse();
    end;

    local procedure GetReturnReceipt(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine.Type::"G/L Account");
        CODEUNIT.Run(CODEUNIT::"Sales-Get Return Receipts", SalesLine);
        SalesLine.Delete();  // Delete Older Sales Line.
    end;

    local procedure GetShipmentLinesForSalesInvoice(var SalesHeader: Record "Sales Header"; SalesOrderNo: Code[20])
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        SalesGetShipment: Codeunit "Sales-Get Shipment";
    begin
        SalesShipmentHeader.SetRange("Order No.", SalesOrderNo);
        SalesShipmentHeader.FindFirst();
        SalesShipmentLine.SetRange("Document No.", SalesShipmentHeader."No.");
        SalesGetShipment.SetSalesHeader(SalesHeader);
        SalesGetShipment.CreateInvLines(SalesShipmentLine);
    end;

    local procedure PartiallyPostSalesOrder(var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
        CustomerNo: Code[20];
    begin
        // Create and Ship two Sales Orders using same Customer and create Sales Invoice.
        LibrarySales.CreateCustomer(Customer);
        CustomerNo := Customer."No.";

        PartiallyShipSalesDocument(SalesHeader, CustomerNo);
        LibraryVariableStorage.Enqueue(LibrarySales.PostSalesDocument(SalesHeader, true, false));

        SalesHeader.Get(SalesHeader."Document Type"::Order, SalesHeader."No.");
        LibraryVariableStorage.Enqueue(LibrarySales.PostSalesDocument(SalesHeader, true, false));

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);

        // Open created Sales Invoice page and do Get Shipment Line.
        OpenSalesInvoiceAndGetShipmentLine(SalesHeader."No.");
    end;

    local procedure OpenSalesInvoiceAndGetShipmentLine(No: Code[20])
    var
        SalesInvoice: TestPage "Sales Invoice";
    begin
        SalesInvoice.OpenEdit();
        SalesInvoice.FILTER.SetFilter("No.", No);
        SalesInvoice.SalesLines.GetShipmentLines.Invoke();
    end;

    local procedure PartiallyShipSalesDocument(var SalesHeader: Record "Sales Header"; SellToCustomerNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        // Create Sales Document using Random Quantity and Unit Price.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, SellToCustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandDec(10, 2));  // Taking Random values for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));  // Taking Random values for Unit Price.
        SalesLine.Validate("Qty. to Ship", SalesLine.Quantity / 2); // Taking here 2 because value is important.
        SalesLine.Modify(true);

        LibraryVariableStorage.Enqueue(SalesLine."Qty. to Ship");
    end;

    local procedure FilterQuantityOnGetShipmentLines(var GetShipmentLines: TestPage "Get Shipment Lines"; DocumentNo: Code[20]; Quantity: Decimal)
    begin
        GetShipmentLines.FILTER.SetFilter("Document No.", DocumentNo);
        GetShipmentLines.FILTER.SetFilter(Quantity, Format(Quantity));
        GetShipmentLines.Quantity.AssertEquals(Quantity);
    end;

    local procedure ModifyCustomerCity(CustomerNo: Code[20]; City: Text[30]): Code[20]
    var
        CustomerCard: TestPage "Customer Card";
    begin
        Commit();
        CustomerCard.OpenEdit();
        CustomerCard.FILTER.SetFilter("No.", CustomerNo);
        CustomerCard.City.SetValue(City);
        CustomerCard."Phone No.".Activate();
        CustomerCard.OK().Invoke();
        exit(CustomerNo);
    end;

    local procedure ModifyCustomerPostCode(CustomerNo: Code[20]; PostCode: Code[20]): Code[20]
    var
        CustomerCard: TestPage "Customer Card";
    begin
        Commit();
        CustomerCard.OpenEdit();
        CustomerCard.FILTER.SetFilter("No.", CustomerNo);
        CustomerCard."Post Code".SetValue(PostCode);
        CustomerCard."Phone No.".Activate();
        CustomerCard.OK().Invoke();
        exit(CustomerNo);
    end;

    local procedure OpenSalesPricesPage(SalesPrices: TestPage "Sales Prices"; CustomerNo: Code[20]; StartingDateFilter: Text[30])
    var
        CustomerList: TestPage "Customer List";
    begin
        CustomerList.OpenEdit();
        CustomerList.FILTER.SetFilter("No.", CustomerNo);
        SalesPrices.Trap();
        CustomerList.Sales_Prices.Invoke();
        SalesPrices.StartingDateFilter.SetValue(StartingDateFilter);
    end;

    local procedure RunCertificateOfSupplyReport(CustomerNo: Code[20])
    var
        CertificateOfSupply: Record "Certificate of Supply";
    begin
        CertificateOfSupply.Init();
        CertificateOfSupply.SetRange("Document Type", CertificateOfSupply."Document Type"::"Sales Shipment");
        CertificateOfSupply.SetRange("Customer/Vendor No.", CustomerNo);
        REPORT.Run(REPORT::"Certificate of Supply", true, false, CertificateOfSupply);
    end;

    local procedure UpdateGeneralLedgerVATSetup(VATRoundingType: Option) OldVATRoundingType: Integer
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        // Update VAT Rounding Type in General Ledger Setup.
        GeneralLedgerSetup.Get();
        OldVATRoundingType := GeneralLedgerSetup."VAT Rounding Type";
        GeneralLedgerSetup.Validate("VAT Rounding Type", VATRoundingType);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateUserSetupSalesRespCtrFilter(var UserSetup: Record "User Setup"; SalesRespCtrFilter: Code[10]) OldSalesRespCtrFilter: Code[10]
    begin
        OldSalesRespCtrFilter := UserSetup."Sales Resp. Ctr. Filter";
        UserSetup.Validate("Sales Resp. Ctr. Filter", SalesRespCtrFilter);
        UserSetup.Modify(true);
    end;

    local procedure UpdateSalesSetup(ReturnReceiptonCreditMemo: Boolean; ExactCostReversingMandatory: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Return Receipt on Credit Memo", ReturnReceiptonCreditMemo);
        SalesReceivablesSetup.Validate("Exact Cost Reversing Mandatory", ExactCostReversingMandatory);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateSalesSetupShipmentOnInvoice(ShipmentOnInvoice: Boolean; RetRcptOnCrMemo: Boolean; ExactCostReversingMandatory: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Shipment on Invoice", ShipmentOnInvoice);
        SalesReceivablesSetup.Validate("Return Receipt on Credit Memo", RetRcptOnCrMemo);
        SalesReceivablesSetup.Validate("Exact Cost Reversing Mandatory", ExactCostReversingMandatory);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UndoShipment(SalesHeaderOrder: Record "Sales Header")
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        SalesShipmentLine.SetRange("Order No.", SalesHeaderOrder."No.");

        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);
    end;

    local procedure VerifyCreditMemo(DocumentNo: Code[20]; ReturnOrderNo: Code[20]; ReturnOrderNoSeries: Code[20]; ReturnReasonCode: Code[10])
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        SalesCrMemoHeader.Get(DocumentNo);
        SalesCrMemoHeader.TestField("Return Order No.", ReturnOrderNo);
        SalesCrMemoHeader.TestField("Return Order No. Series", ReturnOrderNoSeries);
        FindCrMemoLine(SalesCrMemoLine, DocumentNo);
        SalesCrMemoLine.TestField("Return Reason Code", ReturnReasonCode);
    end;

    local procedure VerifyCustomerData(Customer: Record Customer; PostCode: Code[20]; City: Text[30])
    begin
        Customer.TestField("Post Code", PostCode);
        Customer.TestField(City, City);
    end;

    local procedure VerifyItemLedgerEntry(ItemNo: Code[20]; DocumentNo: Code[20]; ReturnReasonCode: Code[10])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.TestField("Return Reason Code", ReturnReasonCode);
    end;

    local procedure VerifyGLEntry(DocumentNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, GLAccountNo, DocumentNo);
        Assert.AreNearlyEqual(
          Amount, GLEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, GLEntry.FieldCaption(Amount), Amount, GLEntry.TableCaption()));
    end;

    local procedure VerifyGLEntryForPostedInvoice(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        TotalGLAmount: Decimal;
    begin
        GeneralLedgerSetup.Get();
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetFilter(Amount, '>0');
        GLEntry.FindSet();
        repeat
            TotalGLAmount += GLEntry.Amount;
        until GLEntry.Next() = 0;
        Assert.AreNearlyEqual(
          Amount, TotalGLAmount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErr, GLEntry.FieldCaption(Amount), GLEntry.Amount, GLEntry.TableCaption()));
    end;

    local procedure VerifyReturnReceipt(DocumentNo: Code[20]; ReturnOrderNo: Code[20]; ReturnOrderNoSeries: Code[20]; ReturnReasonCode: Code[10])
    var
        ReturnReceiptHeader: Record "Return Receipt Header";
        ReturnReceiptLine: Record "Return Receipt Line";
    begin
        ReturnReceiptHeader.Get(DocumentNo);
        ReturnReceiptHeader.TestField("Return Order No.", ReturnOrderNo);
        ReturnReceiptHeader.TestField("Return Order No. Series", ReturnOrderNoSeries);
        FindRetRcptLine(ReturnReceiptLine, DocumentNo);
        ReturnReceiptLine.TestField("Return Reason Code", ReturnReasonCode);
    end;

    local procedure VerifyValueEntry(DocumentNo: Code[20]; ReturnReasonCode: Code[10])
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.FindFirst();
        ValueEntry.TestField("Return Reason Code", ReturnReasonCode);
    end;

    local procedure VerifyVATAmountOnGLEntry(GLAccountNo: Code[20]; DocumentNo: Code[20]; VATAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, GLAccountNo, DocumentNo);
        GLEntry.TestField("VAT Amount", VATAmount);
    end;

    local procedure VerifySalesInvDescriptionLineExists(DocumentNo: Code[20]; ExpectedDescription: Text[50])
    var
        DummySalesInvoiceLine: Record "Sales Invoice Line";
    begin
        DummySalesInvoiceLine.SetRange("Document No.", DocumentNo);
        DummySalesInvoiceLine.SetRange(Type, DummySalesInvoiceLine.Type::" ");
        DummySalesInvoiceLine.SetRange("No.", '');
        DummySalesInvoiceLine.SetRange(Description, ExpectedDescription);
        Assert.RecordIsNotEmpty(DummySalesInvoiceLine);
    end;

    local procedure VerifySalesShptDescriptionLineExists(DocumentNo: Code[20]; ExpectedDescription: Text[50])
    var
        DummySalesShipmentLine: Record "Sales Shipment Line";
    begin
        DummySalesShipmentLine.SetRange("Document No.", DocumentNo);
        DummySalesShipmentLine.SetRange(Type, DummySalesShipmentLine.Type::" ");
        DummySalesShipmentLine.SetRange("No.", '');
        DummySalesShipmentLine.SetRange(Description, ExpectedDescription);
        Assert.RecordIsNotEmpty(DummySalesShipmentLine);
    end;

    local procedure VerifySalesShptDocExists(OrderNo: Code[20])
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
    begin
        SalesShipmentHeader.SetRange("Order No.", OrderNo);
        Assert.RecordIsNotEmpty(SalesShipmentHeader);
    end;

    local procedure VerifySalesCrMemoDescriptionLineExists(DocumentNo: Code[20]; ExpectedDescription: Text[50])
    var
        DummySalesCrMemoLine: Record "Sales Cr.Memo Line";
    begin
        DummySalesCrMemoLine.SetRange("Document No.", DocumentNo);
        DummySalesCrMemoLine.SetRange(Type, DummySalesCrMemoLine.Type::" ");
        DummySalesCrMemoLine.SetRange("No.", '');
        DummySalesCrMemoLine.SetRange(Description, ExpectedDescription);
        Assert.RecordIsNotEmpty(DummySalesCrMemoLine);
    end;

    local procedure VerifySalesRetRcptDescriptionLineExists(DocumentNo: Code[20]; ExpectedDescription: Text[50])
    var
        DummyReturnReceiptLine: Record "Return Receipt Line";
    begin
        DummyReturnReceiptLine.SetRange("Document No.", DocumentNo);
        DummyReturnReceiptLine.SetRange(Type, DummyReturnReceiptLine.Type::" ");
        DummyReturnReceiptLine.SetRange("No.", '');
        DummyReturnReceiptLine.SetRange(Description, ExpectedDescription);
        Assert.RecordIsNotEmpty(DummyReturnReceiptLine);
    end;

    local procedure VerifySalesLineCount(SalesHeader: Record "Sales Header"; ExpectedCount: Integer)
    var
        DummySalesLine: Record "Sales Line";
    begin
        DummySalesLine.SetRange("Document Type", SalesHeader."Document Type");
        DummySalesLine.SetRange("Document No.", SalesHeader."No.");
        Assert.RecordCount(DummySalesLine, ExpectedCount);
    end;

    local procedure VerifySalesLineDescription(SalesLine: Record "Sales Line"; ExpectedType: Enum "Sales Line Type"; ExpectedNo: Code[20]; ExpectedDescription: Text)
    begin
        Assert.AreEqual(ExpectedType, SalesLine.Type, SalesLine.FieldCaption(Type));
        Assert.AreEqual(ExpectedNo, SalesLine."No.", SalesLine.FieldCaption("No."));
        Assert.AreEqual(ExpectedDescription, SalesLine.Description, SalesLine.FieldCaption(Description));
    end;

    local procedure VerifySalesInvoiceLinesAgainstSalesOrderLines(SalesHeaderOrder: Record "Sales Header"; SalesHeaderInvoice: Record "Sales Header"; NoOfLines: Integer)
    var
        SalesLineOrder: Record "Sales Line";
        SalesLineInvoice: Record "Sales Line";
        i: Integer;
    begin
        FindSalesLine(SalesLineOrder, SalesHeaderOrder."Document Type", SalesHeaderOrder."No.", SalesLineOrder.Type::Item);
        FindSalesLine(SalesLineInvoice, SalesHeaderInvoice."Document Type", SalesHeaderInvoice."No.", SalesLineInvoice.Type::Item);
        for i := 1 to NoOfLines do begin
            SalesLineInvoice.TestField("No.", SalesLineOrder."No.");
            SalesLineInvoice.TestField("Inv. Discount Amount", SalesLineOrder."Inv. Discount Amount");
            SalesLineInvoice.TestField(Amount, SalesLineOrder.Amount);
            SalesLineInvoice.Next();
            SalesLineOrder.Next();
        end;
    end;

    local procedure VerifySalesLineWithServiceCharge(SalesHeader: Record "Sales Header"; ServiceChargeAmt: Decimal)
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        SalesLine: Record "Sales Line";
    begin
        CustomerPostingGroup.Get(SalesHeader."Customer Posting Group");
        FindSalesLine(SalesLine, SalesHeader."Document Type", SalesHeader."No.", SalesLine.Type::"G/L Account");
        Assert.RecordCount(SalesLine, 1);
        SalesLine.TestField("No.", CustomerPostingGroup."Service Charge Acc.");
        SalesLine.TestField(Amount, ServiceChargeAmt - SalesLine."Inv. Discount Amount");
    end;

    local procedure VerifySalesLineDescriptionLineExists(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst();
        SalesLine.SetRange("Attached to Line No.", SalesLine."Line No.");
        SalesLine.SetRange(Type, SalesLine.Type::" ");
        Assert.RecordIsNotEmpty(SalesLine);
    end;

    local procedure VerifyRecRefSingleRecord(RecVar: Variant; ExpectedTableNo: Integer)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVar);
        Assert.AreEqual(ExpectedTableNo, RecRef.Number, StrSubstNo(WrongTableErr, RecRef.Name));
        Assert.RecordCount(RecRef, 1);
    end;

    local procedure VerifyTransactionTypeWhenInsertSalesDocument(DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, DocumentType, '',
          '', LibraryRandom.RandDecInRange(10, 20, 2), '', LibraryRandom.RandDate(10));

        SalesHeader.Delete();

        SalesHeader."Transaction Type" := '';
        SalesHeader.Insert();

        SalesHeader.TestField("Transaction Type", '');
    end;

    local procedure VerifyQtyToAssignInDocumentLineForChargeItem(SalesHeader: Record "Sales Header"; ChargeItemNo: Code[20]; ExpectedQtyToAssign: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("No.", ChargeItemNo);

        SalesLine.FindFirst();
        SalesLine.CalcFields("Qty. to Assign");
        SalesLine.TestField("Qty. to Assign", ExpectedQtyToAssign);
    end;

    local procedure SalesDocLineQtyValidation(DocType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Location: Record Location;
        LibraryWarehouse: Codeunit "Library - Warehouse";
        SalesInvoice: TestPage "Sales Invoice";
        SalesCreditMemo: TestPage "Sales Credit Memo";
        i: Integer;
    begin
        // DocType: 2 = Invoice, 3 = Credit Memo
        // SETUP:
        LibraryWarehouse.CreateFullWMSLocation(Location, 3);
        SalesHeader.Init();
        SalesHeader."Document Type" := DocType;
        SalesHeader.Status := SalesHeader.Status::Open;
        i := 0;
        repeat
            i += 1;
            SalesHeader."No." := 'TEST' + Format(i);
        until SalesHeader.Insert();
        SalesLine."Document Type" := DocType;
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := 10000;
        SalesLine.Type := SalesLine.Type::Item;
        SalesLine."No." := LibraryInventory.CreateItemNo();
        SalesLine."Location Code" := Location.Code;
        SalesLine.Insert();
        case DocType of
            "Sales Document Type"::Invoice:
                begin
                    SalesInvoice.OpenEdit();
                    SalesInvoice.GotoRecord(SalesHeader);
                    // EXECUTE:
                    SalesInvoice.SalesLines.Quantity.SetValue(100);
                end;
            "Sales Document Type"::"Credit Memo":
                begin
                    SalesCreditMemo.OpenEdit();
                    SalesCreditMemo.GotoRecord(SalesHeader);
                    // EXECUTE:
                    SalesCreditMemo.SalesLines.Quantity.SetValue(100);
                end;
        end;
    end;

    local procedure VerifyCountSalesCommentLine(DocumentType: Enum "Sales Comment Document Type"; No: Code[20]; DocumentLineNo: Integer)
    var
        SalesCommentLine: Record "Sales Comment Line";
    begin
        SalesCommentLine.SetRange("Document Type", DocumentType);
        SalesCommentLine.SetRange("No.", No);
        SalesCommentLine.SetRange("Document Line No.", DocumentLineNo);
        Assert.RecordCount(SalesCommentLine, 1);
    end;

    local procedure MockSalesLineWithGLAccount(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine.Type := SalesLine.Type::"G/L Account";
        SalesLine."No." := VATPostingSetup.GetSalesAccount(false);
        SalesLine.Quantity := LibraryRandom.RandInt(10);
        SalesLine."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        SalesLine."VAT Prod. Posting Group" := VATPostingSetup."VAT Prod. Posting Group";
        SalesLine.Modify();
    end;

    local procedure CreateSalesLineWithGLAccount(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibrarySales.CreateSalesLineSimple(SalesLine, SalesHeader);
        SalesLine.Validate(Type, SalesLine.Type::"G/L Account");
        SalesLine.Validate("No.", VATPostingSetup.GetSalesAccount(false));
        SalesLine.Validate(Quantity, LibraryRandom.RandInt(10));
        SalesLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        SalesLine.Modify(true);
    end;

    local procedure VerifyChangeLogFieldValue(RecordRef: RecordRef; FieldNo: Integer; OldValue: Text; NewValue: Text)
    var
        ChangeLogEntry: Record "Change Log Entry";
    begin
        ChangeLogEntry.SetRange("Table No.", RecordRef.Number);
        ChangeLogEntry.SetRange("User ID", UserId);
        ChangeLogEntry.SetRange("Primary Key", RecordRef.GetPosition(false));
        ChangeLogEntry.SetRange("Field No.", FieldNo);
        ChangeLogEntry.FindLast();
        Assert.AreEqual(ChangeLogEntry."Old Value", OldValue, 'Change Log Entry (old value) for field ' + Format(FieldNo));
        Assert.AreEqual(ChangeLogEntry."New Value", NewValue, 'Change Log Entry (new value) for field ' + Format(FieldNo));
    end;

    local procedure SetSalesAllowMultiplePostingGroups(AllowMultiplePostingGroups: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Allow Multiple Posting Groups" := AllowMultiplePostingGroups;
        SalesReceivablesSetup."Check Multiple Posting Groups" := "Posting Group Change Method"::"Alternative Groups";
        SalesReceivablesSetup.Modify();
    end;

    local procedure CreateSalesOrderWithItemCharge(
        var SalesHeader: Record "Sales Header";
        ItemChargeNo: Code[20];
        ItemNo: Code[20];
        Quantity: Decimal)
    var
        SalesLineItemCharge: Record "Sales Line";
        SalesLineItem: Record "Sales Line";
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(
            SalesLineItem,
            SalesHeader,
            SalesLineItem.Type::Item,
            ItemNo,
            Quantity);

        SalesLineItem.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLineItem.Modify(true);

        LibrarySales.CreateSalesLine(
            SalesLineItemCharge,
            SalesHeader,
            SalesLineItemCharge.Type::"Charge (Item)",
            ItemChargeNo,
            Quantity);

        SalesLineItemCharge.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLineItemCharge.Modify(true);
    end;

    local procedure SetSalesLinesQtyToShip(var SalesHeader: Record "Sales Header"; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindSet();
        repeat
            SalesLine.Validate("Qty. to Ship", Quantity);
            SalesLine.Modify(true);
        until SalesLine.Next() = 0;
    end;

    local procedure UpdateQtyToAssignOnItemChargeAssignment(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::"Charge (Item)");
        SalesLine.FindFirst();
        SalesLine.ShowItemChargeAssgnt();
    end;

    procedure CreatePostCode(var PostCode: Record "Post Code"; Code: Code[20]; City: Text[30]; CountryRegionCode: Code[10])
    var
        CountryRegion: Record "Country/Region";
    begin
        PostCode.Init();
        if Code = '' then
            Code := CopyStr(
                LibraryUtility.GenerateRandomCode(PostCode.FieldNo(Code), DATABASE::"Post Code"),
                1,
                LibraryUtility.GetFieldLength(DATABASE::"Post Code", PostCode.FieldNo(Code)));
        PostCode.Validate(Code, Code);
        if City = '' then
            City := CopyStr(
                    LibraryUtility.GenerateRandomCode(PostCode.FieldNo(City), DATABASE::"Post Code"),
                    1,
                    LibraryUtility.GetFieldLength(DATABASE::"Post Code", PostCode.FieldNo(City)));
        PostCode.Validate(City, City);
        if CountryRegionCode = '' then begin
            CountryRegion.Next(LibraryRandom.RandInt(CountryRegion.Count()));
            CountryRegionCode := CountryRegion.Code;
        end;
        PostCode.Validate("Country/Region Code", CountryRegionCode);
        PostCode.Insert(true);
    end;

    local procedure SetJournalTemplNameMandatoryFalse()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Journal Templ. Name Mandatory" := false;
        GeneralLedgerSetup.Modify();
    end;

    local procedure GeneratePostingDate(var PostingDate: array[3] of Date)
    begin
        PostingDate[1] := WorkDate();
        PostingDate[2] := CalcDate('<-15D>', PostingDate[1]);
        PostingDate[3] := CalcDate('<-15D>', PostingDate[2]);
    end;

    local procedure CreateCurrencyWithExchangeRates(
        var Currency: Record Currency;
        var CurrencyExchangeRate: array[3] of Record "Currency Exchange Rate";
        PostingDate: array[3] of Date)
    var
        RelExchRateAmount: array[3] of Integer;
        AdjustExchRateAmount: Integer;
    begin
        RelExchRateAmount[1] := LibraryRandom.RandIntInRange(75, 75);
        RelExchRateAmount[2] := LibraryRandom.RandIntInRange(80, 80);
        RelExchRateAmount[3] := LibraryRandom.RandIntInRange(90, 90);
        AdjustExchRateAmount := LibraryRandom.RandIntInRange(100, 100);

        Currency.Get(LibraryERM.CreateCurrencyWithGLAccountSetup());

        LibraryERM.CreateExchRate(CurrencyExchangeRate[1], Currency.Code, PostingDate[3]);
        CurrencyExchangeRate[1].Validate("Exchange Rate Amount", AdjustExchRateAmount);
        CurrencyExchangeRate[1].Validate("Adjustment Exch. Rate Amount", AdjustExchRateAmount);
        CurrencyExchangeRate[1].Validate("Relational Exch. Rate Amount", RelExchRateAmount[1]);
        CurrencyExchangeRate[1].Validate("Relational Adjmt Exch Rate Amt", RelExchRateAmount[1]);
        CurrencyExchangeRate[1].Modify(true);

        LibraryERM.CreateExchRate(CurrencyExchangeRate[2], Currency.Code, PostingDate[2]);
        CurrencyExchangeRate[2].Validate("Exchange Rate Amount", AdjustExchRateAmount);
        CurrencyExchangeRate[2].Validate("Adjustment Exch. Rate Amount", AdjustExchRateAmount);
        CurrencyExchangeRate[2].Validate("Relational Exch. Rate Amount", RelExchRateAmount[2]);
        CurrencyExchangeRate[2].Validate("Relational Adjmt Exch Rate Amt", RelExchRateAmount[2]);
        CurrencyExchangeRate[2].Modify(true);

        LibraryERM.CreateExchRate(CurrencyExchangeRate[3], Currency.Code, PostingDate[1]);
        CurrencyExchangeRate[3].Validate("Exchange Rate Amount", AdjustExchRateAmount);
        CurrencyExchangeRate[3].Validate("Adjustment Exch. Rate Amount", AdjustExchRateAmount);
        CurrencyExchangeRate[3].Validate("Relational Exch. Rate Amount", RelExchRateAmount[3]);
        CurrencyExchangeRate[3].Validate("Relational Adjmt Exch Rate Amt", RelExchRateAmount[3]);
        CurrencyExchangeRate[3].Modify(true);
    end;

    local procedure CreateCustomerWithAllowMultiplePostingGroups(
        var Customer: Record Customer;
        CustomerPostingGroupCode: Code[20];
        CurrencyCode: Code[20];
        VATBusPostGroupCode: Code[20])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Allow Multiple Posting Groups", true);
        Customer.Validate("VAT Bus. Posting Group", VATBusPostGroupCode);
        Customer.Validate("Customer Posting Group", CustomerPostingGroupCode);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);
    end;

    local procedure CreateSalesInvoice(
        var SalesHeader: Record "Sales Header";
        var SalesLine: Record "Sales Line";
        PostingDate: Date;
        ItemCode: Code[20];
        CustomerNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Document Date", PostingDate);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLineWithUnitPrice(
            SalesLine, SalesHeader, ItemCode,
            LibraryRandom.RandIntInRange(100, 100), LibraryRandom.RandInt(0));
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; ForceDocBalance: Boolean)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate("Force Doc. Balance", ForceDocBalance);
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreatePaymentAndPost(
        GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; CustomerNo: Code[20];
        CustomerPostingGroupCode: Code[20]; PostingDate: Date; var PaymentDocNo: Code[20])
    begin
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, CustomerNo,
            GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), -LibraryRandom.RandIntInRange(100, 100));
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Posting Group", CustomerPostingGroupCode);
        GenJournalLine.Modify(true);
        PaymentDocNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure ApplyPostCustPayment2Invoices(PayDocNo: Code[20]; InvDocNo: Code[20])
    var
        CustLedgerEntryFrom: Record "Cust. Ledger Entry";
        CustLedgerEntryTo: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntryFrom, CustLedgerEntryFrom."Document Type"::Payment, PayDocNo);
        CustLedgerEntryFrom.CalcFields("Remaining Amount");
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntryFrom, CustLedgerEntryFrom."Remaining Amount");
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntryTo, CustLedgerEntryTo."Document Type"::Invoice, InvDocNo);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntryTo);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntryFrom);
    end;

    local procedure VerifyGLEntryForAccount(CustomerPostingGroup: array[2] of Record "Customer Posting Group"; ActualAmount: array[2] of Decimal)
    begin
        GetGLEntryBalance(CustomerPostingGroup[1]."Receivables Account", ActualAmount[1]);
        Assert.AreEqual(0, ActualAmount[1], StrSubstNo(AccountBalanceErrLbl, CustomerPostingGroup[1]."Receivables Account"));
        GetGLEntryBalance(CustomerPostingGroup[2]."Receivables Account", ActualAmount[2]);
        Assert.AreEqual(0, ActualAmount[2], StrSubstNo(AccountBalanceErrLbl, CustomerPostingGroup[2]."Receivables Account"));
    end;

    local procedure GetGLEntryBalance(AccountNo: Code[20]; var Balance: Decimal)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("G/L Account No.", AccountNo);
        GLEntry.CalcSums(Amount);
        Balance := GLEntry.Amount;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure CreateEmptyPostedInvConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := false;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostCodesHandler(var PostCodes: TestPage "Post Codes")
    var
        Customer: Record Customer;
        "Filter": Text;
        FieldNo: Integer;
    begin
        FieldNo := LibraryVariableStorage.DequeueInteger();
        Filter := LibraryVariableStorage.DequeueText();

        if FieldNo = Customer.FieldNo("Post Code") then
            PostCodes.FILTER.SetFilter(Code, Format(Filter))
        else
            PostCodes.FILTER.SetFilter(City, Format(Filter));
        PostCodes.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostCodesCancelHandler(var PostCodes: TestPage "Post Codes")
    begin
        PostCodes.Cancel().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalse(Message: Text[1024]; var Response: Boolean)
    begin
        Response := false;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Message: Text[1024]; var Response: Boolean)
    begin
        Response := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerFalseOnUpdateSalesLines(Message: Text[1024]; var Response: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
        Response := false;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetShipmentLinesHandler(var GetShipmentLines: TestPage "Get Shipment Lines")
    begin
        GetShipmentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuantityOnGetShipmentLinesPageHandler(var GetShipmentLines: TestPage "Get Shipment Lines")
    var
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
        QtyToShip: Decimal;
    begin
        QtyToShip := LibraryVariableStorage.DequeueDecimal();
        DocumentNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(DocumentNo));
        DocumentNo2 := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(DocumentNo2));

        // Verification for both lines filtering in the Get Shipment Lines page which is partially posted Sales Order for same Customer.
        FilterQuantityOnGetShipmentLines(GetShipmentLines, DocumentNo, QtyToShip);
        FilterQuantityOnGetShipmentLines(GetShipmentLines, DocumentNo2, QtyToShip);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuantityFilterUsingGetShipmentLinesPageHandler(var GetShipmentLines: TestPage "Get Shipment Lines")
    var
        DocumentNo: Code[20];
        QtyToShip: Decimal;
    begin
        QtyToShip := LibraryVariableStorage.DequeueDecimal();
        DocumentNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(DocumentNo));

        // Verification for filter in the Get Shipment Lines page according to Quantity.
        FilterQuantityOnGetShipmentLines(GetShipmentLines, DocumentNo, QtyToShip);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Assign Lot No.".Invoke();
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure InvokeGetShipmentLinesPageHandler(var GetShipmentLines: TestPage "Get Shipment Lines")
    var
        DocumentNo: Code[20];
        QtyToShip: Decimal;
    begin
        QtyToShip := LibraryVariableStorage.DequeueDecimal();
        DocumentNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(DocumentNo));

        FilterQuantityOnGetShipmentLines(GetShipmentLines, DocumentNo, QtyToShip);
        GetShipmentLines.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageCaptureHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemSubstitutionEntriesHandler(var ItemSubstitutionEntries: TestPage "Item Substitution Entries")
    begin
        ItemSubstitutionEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesDocumentLinesHandler(var PostedSalesDocumentLines: TestPage "Posted Sales Document Lines")
    var
        DocumentType: Option "Posted Shipments","Posted Invoices","Posted Return Receipts","Posted Cr. Memos";
    begin
        case LibraryVariableStorage.DequeueInteger() of
            OptionString::PostedReturnReceipt:
                PostedSalesDocumentLines.PostedShipmentsBtn.SetValue(Format(DocumentType::"Posted Return Receipts"));
            OptionString::PostedInvoices:
                PostedSalesDocumentLines.PostedShipmentsBtn.SetValue(Format(DocumentType::"Posted Invoices"));
            OptionString::PostedShipments:
                PostedSalesDocumentLines.PostedShipmentsBtn.SetValue(Format(DocumentType::"Posted Shipments"));
            OptionString::PostedCrMemo:
                PostedSalesDocumentLines.PostedShipmentsBtn.SetValue(Format(DocumentType::"Posted Cr. Memos"));
        end;
        PostedSalesDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure RetRcptLinesPageHandler(var GetReturnReceiptLines: TestPage "Get Return Receipt Lines")
    begin
        GetReturnReceiptLines.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CertificateofSupplyRequestPageHandler(var CertificateOfSupply: TestRequestPage "Certificate of Supply")
    begin
        CertificateOfSupply.PrintLineDetails.SetValue(true);
        CertificateOfSupply.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RecallNotificationHandler]
    [Scope('OnPrem')]
    procedure RecallNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure SendNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetSalesPricePageHandler(var GetSalesPrice: TestPage "Get Sales Price") // V15
    begin
        GetSalesPrice.First();
        GetSalesPrice.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetPriceLinePageHandler(var GetPriceLine: TestPage "Get Price Line") // V16
    begin
        GetPriceLine.First();
        GetPriceLine.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure PostOrderStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 0;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure PostOrderWithChoiceStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := LibraryVariableStorage.DequeueInteger();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesQuoteRequestPageHandler(var SalesQuote: TestRequestPage "Standard Sales - Quote")
    begin
        SalesQuote.Cancel().Invoke();
        LibraryVariableStorage.Enqueue(REPORT::"Standard Sales - Quote");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostAndSendConfirmationModalPageHandler(var PostandSendConfirmation: TestPage "Post and Send Confirmation")
    begin
        PostandSendConfirmation.Yes().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure VerifyingConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrueWithEnqueMessage(Message: Text[1024]; var Response: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Message);
        Response := LibraryVariableStorage.DequeueBoolean();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CustomerLookupSelectCustomerPageHandler(var CustomerLookup: TestPage "Customer Lookup")
    begin
        CustomerLookup.FILTER.SetFilter("No.", LibraryVariableStorage.DequeueText());
        CustomerLookup.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentSalesModalPageHandler(var ItemChargeAssignmentSales: TestPage "Item Charge Assignment (Sales)")
    begin
        ItemChargeAssignmentSales."Qty. to Assign".SetValue(LibraryVariableStorage.DequeueDecimal());
        ItemChargeAssignmentSales.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure SalesListModalPageHandler(var SalesList: TestPage "Sales List")
    begin
        SalesList.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalespersonCommissionRequestPageHandler(var SalespersonCommission: TestRequestPage "Salesperson - Commission")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalespersonSalesStatisticsRequestPageHandler(var SalespersonSalesStatistics: TestRequestPage "Salesperson - Sales Statistics")
    begin
    end;

    [ModalPageHandler]
    procedure ChangeLogEntriesModalPageHandler(var ChangeLogEntries: TestPage "Change Log Entries");
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), ChangeLogEntries."Old Value".Value(), ChangeLogEntries."Old Value".Caption());
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), ChangeLogEntries."New Value".Value(), ChangeLogEntries."New Value".Caption());
        ChangeLogEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesDocumentLinesPageHandler(var PostedSalesDocumentLines: TestPage "Posted Sales Document Lines")
    begin
        PostedSalesDocumentLines.PostedInvoices.Filter.SetFilter("No.", LibraryVariableStorage.DequeueText());
        PostedSalesDocumentLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SuggestItemChargeAssignmentPageHandler(var ItemChargeAssignmentSales: TestPage "Item Charge Assignment (Sales)")
    begin
        ItemChargeAssignmentSales.SuggestItemChargeAssignment.Invoke();
    end;
}
