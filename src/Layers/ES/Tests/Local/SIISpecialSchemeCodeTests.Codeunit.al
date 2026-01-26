codeunit 147562 "SII Special Scheme Code Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        Assert: Codeunit Assert;
        LibrarySII: Codeunit "Library - SII";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        UploadType: Option Regular,Intracommunity,RetryAccepted;
        IncorrectXMLDocErr: Label 'The XML document was not generated properly.';
        XPathSalesFacturaExpedidaTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasEmitidas/siiRL:RegistroLRFacturasEmitidas/siiRL:FacturaExpedida/';
        XPathPurchFacturaRecibidaTok: Label '//soapenv:Body/siiRL:SuministroLRFacturasRecibidas/siiRL:RegistroLRFacturasRecibidas/siiRL:FacturaRecibida/';
        CannotInsertMoreThanThreeCodesErr: Label 'You cannot specify more than three special scheme codes for each document.';
        InconsitencyOfRegimeCodeAndVATClauseErr: Label 'If the sales special scheme code is 01 General, the SII exemption code of the VAT clause must not be equal to E2 or E3.';
        ConfirmChangeQst: Label 'Do you want to change %1?', Comment = '%1 = a Field Caption like Currency Code';

    [Test]
    [Scope('OnPrem')]
    procedure UT_NotAllowedToHaveMoreThanThreeSalesRegimeCodes()
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
        i: Integer;
    begin
        // [FEATURE] [UT] [Sales]
        // [SCENARIO 385942] Stan cannot specify more than three sales regime codes

        Initialize();

        for i := 1 to 3 do begin
            SIISalesDocumentSchemeCode.Init();
            SIISalesDocumentSchemeCode."Special Scheme Code" := i;
            SIISalesDocumentSchemeCode.Insert(True);
        end;
        SIISalesDocumentSchemeCode."Special Scheme Code" := i + 1;
        AssertError SIISalesDocumentSchemeCode.Insert(True);
        Assert.ExpectedError(CannotInsertMoreThanThreeCodesErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_NotAllowedToHaveMoreThanThreePurchRegimeCodes()
    var
        SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
        i: Integer;
    begin
        // [FEATURE] [UT] [Purchase]
        // [SCENARIO 385942] Stan cannot specify more than three purchase regime codes

        Initialize();

        for i := 1 to 3 do begin
            SIIPurchDocSchemeCode.Init();
            SIIPurchDocSchemeCode."Special Scheme Code" := i;
            SIIPurchDocSchemeCode.Insert(True);
        end;
        SIIPurchDocSchemeCode."Special Scheme Code" := i + 1;
        AssertError SIIPurchDocSchemeCode.Insert(True);
        Assert.ExpectedError(CannotInsertMoreThanThreeCodesErr);
    end;

    [Test]
    [HandlerFunctions('SalesDocSchemeCodesModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_MultipleSpecialRegimeCodesForSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoicePage: TestPage "Sales Invoice";
    begin
        // [FEATURE] [UI] [Sales] [Invoice]
        // [SCENARIO 385942] Stan can specify multiple special regime codes for the sales invoice

        Initialize();

        // [GIVEN] Sales invoice
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        SalesInvoicePage.OpenEdit();
        SalesInvoicePage.FILTER.SetFilter("No.", SalesHeader."No.");
        Assert.AreEqual(
          SalesInvoicePage."Special Scheme Code".Editable(), true, 'Special scheme should be editable when no multiple codes assigned.');

        // [GIVEN] Press "Special Scheme Codes" action
        // [WHEN] Insert two special regime codes in the opened "Special Regime Codes" page and close it
        // Handled by SalesDocSchemeCodesModalPageHandler
        SalesInvoicePage.SpecialSchemeCodes.Invoke();

        // [THEN] "Special Regime Code" field is not editable
        Assert.AreEqual(
          SalesInvoicePage."Special Scheme Code".Editable(), false, 'Special scheme should not be editable when multiple codes assigned.');

        // [THEN] "Multiple scheme codes" label field is visible
        Assert.AreEqual(
          SalesInvoicePage.MultipleSchemeCodesControl.Visible(), true,
          'Multiple scheme codes label is not visible when multiple codes assigned.');
    end;

    [Test]
    [HandlerFunctions('SalesDocSchemeCodesModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_MultipleSpecialRegimeCodesForPostedSalesInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedSalesInvoicePage: TestPage "Posted Sales Invoice";
    begin
        // [FEATURE] [UI] [Sales] [Invoice]
        // [SCENARIO 385942] Stan can specify multiple special regime codes for the posted sales invoice

        Initialize();

        // [GIVEN] Posted sales invoice
        SalesInvoiceHeader."No." := LibraryUtility.GenerateGUID();
        SalesInvoiceHeader.Insert();
        PostedSalesInvoicePage.OpenEdit();
        PostedSalesInvoicePage.FILTER.SetFilter("No.", SalesInvoiceHeader."No.");

        // [GIVEN] Press "Special Scheme Codes" action
        // [WHEN] Insert two special regime codes in the opened "Special Regime Codes" page and close it
        // Handled by SalesDocSchemeCodesModalPageHandler
        PostedSalesInvoicePage.SpecialSchemeCodes.Invoke();

        // [THEN] "Multiple scheme codes" label field is visible
        Assert.AreEqual(
          PostedSalesInvoicePage.MultipleSchemeCodesControl.Visible(), true,
          'Multiple scheme codes label is not visible when multiple codes assigned.');
    end;

    [Test]
    [HandlerFunctions('SalesDocShemeCodesVerifyFirstTwoCodesModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_MultipleSpecialRegimeCodesAfterPostingSalesInvoice()
    var
        SalesHeader: Record "Sales Header";
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
        PostedSalesInvoicePage: TestPage "Posted Sales Invoice";
        InvNo: Code[20];
        SchemeCode: array[2] of Option;
        i: Integer;
    begin
        // [FEATURE] [UI] [Sales] [Invoice]
        // [SCENARIO 385942] Stan can see multiple special regime codes after posting sales invoice

        Initialize();

        // [GIVEN] Sales invoice with two special scheme codes - 01 and 02
        CreateSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice, 0);
        SchemeCode[1] := SIISalesDocumentSchemeCode."Special Scheme Code"::"01 General";
        SchemeCode[2] := SIISalesDocumentSchemeCode."Special Scheme Code"::"02 Export";
        for i := 1 to ArrayLen(SchemeCode) do begin
            InsertSIISalesDocSpecialSchemeCode(
              SIISalesDocumentSchemeCode, SIISalesDocumentSchemeCode."Entry Type"::Sales,
              SalesHeader."Document Type", SalesHeader."No.", SchemeCode[i]);
            LibraryVariableStorage.Enqueue(Format(SIISalesDocumentSchemeCode."Special Scheme Code"));
        end;

        // [GIVEN] Post sales invoice
        InvNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Open posted sales invoice page
        PostedSalesInvoicePage.OpenEdit();
        PostedSalesInvoicePage.FILTER.SetFilter("No.", InvNo);
        Assert.AreEqual(
          PostedSalesInvoicePage.MultipleSchemeCodesControl.Visible(), true,
          'Multiple scheme codes label is not visible when multiple codes assigned.');

        // [WHEN] Press "Special Scheme Codes" action
        PostedSalesInvoicePage.SpecialSchemeCodes.Invoke();

        // [THEN] Codes 01 and 02 are available in the "Special Scheme Codes" page
        // Handled by SalesDocShemeCodesVerifyFirstTwoCodesModalPageHandler

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SalesDocSchemeCodesModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_MultipleSpecialRegimeCodesForSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesOrderPage: TestPage "Sales Order";
    begin
        // [FEATURE] [UI] [Sales] [Order]
        // [SCENARIO 385942] Stan can specify multiple special regime codes for the sales order

        Initialize();

        // [GIVEN] Sales order
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesOrderPage.OpenEdit();
        SalesOrderPage.FILTER.SetFilter("No.", SalesHeader."No.");
        Assert.AreEqual(
          SalesOrderPage."Special Scheme Code".Editable(), true, 'Special scheme should be editable when no multiple codes assigned.');

        // [GIVEN] Press "Special Scheme Codes" action
        // [WHEN] Insert two special regime codes in the opened "Special Regime Codes" page and close it
        // Handled by SalesDocSchemeCodesModalPageHandler
        SalesOrderPage.SpecialSchemeCodes.Invoke();

        // [THEN] "Special Regime Code" field is not editable
        Assert.AreEqual(
          SalesOrderPage."Special Scheme Code".Editable(), false, 'Special scheme should not be editable when multiple codes assigned.');

        // [THEN] "Multiple scheme codes" label field is visible
        Assert.AreEqual(
          SalesOrderPage.MultipleSchemeCodesControl.Visible(), true,
          'Multiple scheme codes label is not visible when multiple codes assigned.');
    end;

    [Test]
    [HandlerFunctions('SalesDocShemeCodesVerifyFirstTwoCodesModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_MultipleSpecialRegimeCodesAfterPostingSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
        PostedSalesInvoicePage: TestPage "Posted Sales Invoice";
        InvNo: Code[20];
        SchemeCode: array[2] of Option;
        i: Integer;
    begin
        // [FEATURE] [UI] [Sales] [Order]
        // [SCENARIO 385942] Stan can see multiple special regime codes after posting sales order

        Initialize();

        // [GIVEN] Sales order with two special scheme codes - 01 and 02
        CreateSalesDoc(SalesHeader, SalesHeader."Document Type"::Order, 0);
        SchemeCode[1] := SIISalesDocumentSchemeCode."Special Scheme Code"::"01 General";
        SchemeCode[2] := SIISalesDocumentSchemeCode."Special Scheme Code"::"02 Export";
        for i := 1 to ArrayLen(SchemeCode) do begin
            InsertSIISalesDocSpecialSchemeCode(
              SIISalesDocumentSchemeCode, SIISalesDocumentSchemeCode."Entry Type"::Sales,
              SalesHeader."Document Type", SalesHeader."No.", SchemeCode[i]);
            LibraryVariableStorage.Enqueue(Format(SIISalesDocumentSchemeCode."Special Scheme Code"));
        end;

        // [GIVEN] Post sales order
        InvNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Open posted sales invoice page
        PostedSalesInvoicePage.OpenEdit();
        PostedSalesInvoicePage.FILTER.SetFilter("No.", InvNo);
        Assert.AreEqual(
          PostedSalesInvoicePage.MultipleSchemeCodesControl.Visible(), true,
          'Multiple scheme codes label is not visible when multiple codes assigned.');

        // [WHEN] Press "Special Scheme Codes" action
        PostedSalesInvoicePage.SpecialSchemeCodes.Invoke();

        // [THEN] Codes 01 and 02 are available in the "Special Scheme Codes" page
        // Handled by SalesDocShemeCodesVerifyFirstTwoCodesModalPageHandler

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SalesDocSchemeCodesModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_MultipleSpecialRegimeCodesForSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesCreditMemoPage: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [UI] [Sales] [Credit Memo]
        // [SCENARIO 385942] Stan can specify multiple special regime codes for the sales credit memo

        Initialize();

        // [GIVEN] Sales credit memo
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        SalesCreditMemoPage.OpenEdit();
        SalesCreditMemoPage.FILTER.SetFilter("No.", SalesHeader."No.");
        Assert.AreEqual(
          SalesCreditMemoPage."Special Scheme Code".Editable(), true, 'Special scheme should be editable when no multiple codes assigned.');

        // [GIVEN] Press "Special Scheme Codes" action
        // [WHEN] Insert two special regime codes in the opened "Special Regime Codes" page and close it
        // Handled by SalesDocSchemeCodesModalPageHandler
        SalesCreditMemoPage.SpecialSchemeCodes.Invoke();

        // [THEN] "Special Regime Code" field is not editable
        Assert.AreEqual(
          SalesCreditMemoPage."Special Scheme Code".Editable(), false,
          'Special scheme should not be editable when multiple codes assigned.');

        // [THEN] "Multiple scheme codes" label field is visible
        Assert.AreEqual(
          SalesCreditMemoPage.MultipleSchemeCodesControl.Visible(), true,
          'Multiple scheme codes label is not visible when multiple codes assigned.');
    end;

    [Test]
    [HandlerFunctions('SalesDocSchemeCodesModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_MultipleSpecialRegimeCodesForPostedSalesCrMemo()
    var
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
    begin
        // [FEATURE] [UI] [Sales] [Credit Memo]
        // [SCENARIO 385942] Stan can specify multiple special regime codes for the posted sales credit memo

        Initialize();

        // [GIVEN] Posted sales credit memo
        SalesCrMemoHeader."No." := LibraryUtility.GenerateGUID();
        SalesCrMemoHeader.Insert();
        PostedSalesCreditMemo.OpenEdit();
        PostedSalesCreditMemo.FILTER.SetFilter("No.", SalesCrMemoHeader."No.");

        // [GIVEN] Press "Special Scheme Codes" action
        // [WHEN] Insert two special regime codes in the opened "Special Regime Codes" page and close it
        // Handled by SalesDocSchemeCodesModalPageHandler
        PostedSalesCreditMemo.SpecialSchemeCodes.Invoke();

        // [THEN] "Multiple scheme codes" label field is visible
        Assert.AreEqual(
          PostedSalesCreditMemo.MultipleSchemeCodesControl.Visible(), true,
          'Multiple scheme codes label is not visible when multiple codes assigned.');
    end;

    [Test]
    [HandlerFunctions('SalesDocShemeCodesVerifyFirstTwoCodesModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_MultipleSpecialRegimeCodesAfterPostingSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
        PostedSalesCreditMemo: TestPage "Posted Sales Credit Memo";
        CrMemo: Code[20];
        SchemeCode: array[2] of Option;
        i: Integer;
    begin
        // [FEATURE] [UI] [Sales] [Credit Memo]
        // [SCENARIO 385942] Stan can see multiple special regime codes after posting sales credit memo

        Initialize();

        // [GIVEN] Sales credit memo with two special scheme codes - 01 and 02
        CreateSalesDoc(SalesHeader, SalesHeader."Document Type"::"Credit Memo", 0);
        SchemeCode[1] := SIISalesDocumentSchemeCode."Special Scheme Code"::"01 General";
        SchemeCode[2] := SIISalesDocumentSchemeCode."Special Scheme Code"::"02 Export";
        for i := 1 to ArrayLen(SchemeCode) do begin
            InsertSIISalesDocSpecialSchemeCode(
              SIISalesDocumentSchemeCode, SIISalesDocumentSchemeCode."Entry Type"::Sales,
              SalesHeader."Document Type", SalesHeader."No.", SchemeCode[i]);
            LibraryVariableStorage.Enqueue(Format(SIISalesDocumentSchemeCode."Special Scheme Code"));
        end;

        // [GIVEN] Post sales credit memo
        CrMemo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Open posted sales credit memo page
        PostedSalesCreditMemo.OpenEdit();
        PostedSalesCreditMemo.FILTER.SetFilter("No.", CrMemo);
        Assert.AreEqual(
          PostedSalesCreditMemo.MultipleSchemeCodesControl.Visible(), true,
          'Multiple scheme codes label is not visible when multiple codes assigned.');

        // [WHEN] Press "Special Scheme Codes" action
        PostedSalesCreditMemo.SpecialSchemeCodes.Invoke();

        // [THEN] Codes 01 and 02 are available in the "Special Scheme Codes" page
        // Handled by SalesDocShemeCodesVerifyFirstTwoCodesModalPageHandler

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SalesDocSchemeCodesModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_MultipleSpecialRegimeCodesForServInvoice()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoicePage: TestPage "Service Invoice";
    begin
        // [FEATURE] [UI] [Service] [Invoice]
        // [SCENARIO 385942] Stan can specify multiple special regime codes for the service invoice

        Initialize();

        // [GIVEN] Service invoice
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        ServiceInvoicePage.OpenEdit();
        ServiceInvoicePage.FILTER.SetFilter("No.", ServiceHeader."No.");
        Assert.AreEqual(
          ServiceInvoicePage."Special Scheme Code".Editable(), true, 'Special scheme should be editable when no multiple codes assigned.');

        // [GIVEN] Press "Special Scheme Codes" action
        // [WHEN] Insert two special regime codes in the opened "Special Regime Codes" page and close it
        // Handled by SalesDocSchemeCodesModalPageHandler
        ServiceInvoicePage.SpecialSchemeCodes.Invoke();

        // [THEN] "Special Regime Code" field is not editable
        Assert.AreEqual(
          ServiceInvoicePage."Special Scheme Code".Editable(), false, 'Special scheme should not be editable when multiple codes assigned.');

        // [THEN] "Multiple scheme codes" label field is visible
        Assert.AreEqual(
          ServiceInvoicePage.MultipleSchemeCodesControl.Visible(), true,
          'Multiple scheme codes label is not visible when multiple codes assigned.');
    end;

    [Test]
    [HandlerFunctions('SalesDocSchemeCodesModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_MultipleSpecialRegimeCodesForPostedServInvoice()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        PostedServiceInvoicePage: TestPage "Posted Service Invoice";
    begin
        // [FEATURE] [UI] [Service] [Invoice]
        // [SCENARIO 385942] Stan can specify multiple special regime codes for the posted service invoice

        Initialize();

        // [GIVEN] Posted service invoice
        ServiceInvoiceHeader."No." := LibraryUtility.GenerateGUID();
        ServiceInvoiceHeader.Insert();
        PostedServiceInvoicePage.OpenEdit();
        PostedServiceInvoicePage.FILTER.SetFilter("No.", ServiceInvoiceHeader."No.");

        // [GIVEN] Press "Special Scheme Codes" action
        // [WHEN] Insert two special regime codes in the opened "Special Regime Codes" page and close it
        // Handled by SalesDocSchemeCodesModalPageHandler
        PostedServiceInvoicePage.SpecialSchemeCodes.Invoke();

        // [THEN] "Multiple scheme codes" label field is visible
        Assert.AreEqual(
          PostedServiceInvoicePage.MultipleSchemeCodesControl.Visible(), true,
          'Multiple scheme codes label is not visible when multiple codes assigned.');
    end;

    [Test]
    [HandlerFunctions('SalesDocShemeCodesVerifyFirstTwoCodesModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_MultipleSpecialRegimeCodesAfterPostingServInvoice()
    var
        ServiceHeader: Record "Service Header";
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PostedServiceInvoicePage: TestPage "Posted Service Invoice";
        SchemeCode: array[2] of Option;
        i: Integer;
    begin
        // [FEATURE] [UI] [Service] [Invoice]
        // [SCENARIO 385942] Stan can see multiple special regime codes after posting service invoice

        Initialize();

        // [GIVEN] Service invoice with two special scheme codes - 01 and 02
        CreateServiceDoc(ServiceHeader, ServiceHeader."Document Type"::Invoice);
        SchemeCode[1] := SIISalesDocumentSchemeCode."Special Scheme Code"::"01 General";
        SchemeCode[2] := SIISalesDocumentSchemeCode."Special Scheme Code"::"02 Export";
        for i := 1 to ArrayLen(SchemeCode) do begin
            InsertSIISalesDocSpecialSchemeCode(
              SIISalesDocumentSchemeCode, SIISalesDocumentSchemeCode."Entry Type"::Service,
              ServiceHeader."Document Type", ServiceHeader."No.", SchemeCode[i]);
            LibraryVariableStorage.Enqueue(Format(SIISalesDocumentSchemeCode."Special Scheme Code"));
        end;

        // [GIVEN] Post service invoice
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        FindPostedCustLedgEntry(CustLedgerEntry, ServiceHeader."Bill-to Customer No.");

        // [GIVEN] Open posted service invoice page
        PostedServiceInvoicePage.OpenEdit();
        PostedServiceInvoicePage.FILTER.SetFilter("No.", CustLedgerEntry."Document No.");
        Assert.AreEqual(
          PostedServiceInvoicePage.MultipleSchemeCodesControl.Visible(), true,
          'Multiple scheme codes label is not visible when multiple codes assigned.');

        // [WHEN] Press "Special Scheme Codes" action
        PostedServiceInvoicePage.SpecialSchemeCodes.Invoke();

        // [THEN] Codes 01 and 02 are available in the "Special Scheme Codes" page
        // Handled by SalesDocShemeCodesVerifyFirstTwoCodesModalPageHandler

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SalesDocSchemeCodesModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_MultipleSpecialRegimeCodesForServOrder()
    var
        ServiceHeader: Record "Service Header";
        ServiceOrderPage: TestPage "Service Order";
    begin
        // [FEATURE] [UI] [Service] [Order]
        // [SCENARIO 385942] Stan can specify multiple special regime codes for the service order

        Initialize();

        // [GIVEN] Service order
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        ServiceOrderPage.OpenEdit();
        ServiceOrderPage.FILTER.SetFilter("No.", ServiceHeader."No.");
        Assert.AreEqual(
          ServiceOrderPage."Special Scheme Code".Editable(), true, 'Special scheme should be editable when no multiple codes assigned.');

        // [GIVEN] Press "Special Scheme Codes" action
        // [WHEN] Insert two special regime codes in the opened "Special Regime Codes" page and close it
        // Handled by SalesDocSchemeCodesModalPageHandler
        ServiceOrderPage.SpecialSchemeCodes.Invoke();

        // [THEN] "Special Regime Code" field is novt editable
        Assert.AreEqual(
          ServiceOrderPage."Special Scheme Code".Editable(), false, 'Special scheme should not be editable when multiple codes assigned.');

        // [THEN] "Multiple scheme codes" label field is visible
        Assert.AreEqual(
          ServiceOrderPage.MultipleSchemeCodesControl.Visible(), true,
          'Multiple scheme codes label is not visible when multiple codes assigned.');
    end;

    [Test]
    [HandlerFunctions('SalesDocShemeCodesVerifyFirstTwoCodesModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_MultipleSpecialRegimeCodesAfterPostingServOrder()
    var
        ServiceHeader: Record "Service Header";
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PostedServiceInvoicePage: TestPage "Posted Service Invoice";
        SchemeCode: array[2] of Option;
        i: Integer;
    begin
        // [FEATURE] [UI] [Service] [Order]
        // [SCENARIO 385942] Stan can see multiple special regime codes after posting service order

        Initialize();

        // [GIVEN] Service order with two special scheme codes - 01 and 02
        CreateServiceDoc(ServiceHeader, ServiceHeader."Document Type"::Order);
        SchemeCode[1] := SIISalesDocumentSchemeCode."Special Scheme Code"::"01 General";
        SchemeCode[2] := SIISalesDocumentSchemeCode."Special Scheme Code"::"02 Export";
        for i := 1 to ArrayLen(SchemeCode) do begin
            InsertSIISalesDocSpecialSchemeCode(
              SIISalesDocumentSchemeCode, SIISalesDocumentSchemeCode."Entry Type"::Service,
              ServiceHeader."Document Type", ServiceHeader."No.", SchemeCode[i]);
            LibraryVariableStorage.Enqueue(Format(SIISalesDocumentSchemeCode."Special Scheme Code"));
        end;

        // [GIVEN] Post service order
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        FindPostedCustLedgEntry(CustLedgerEntry, ServiceHeader."Bill-to Customer No.");

        // [GIVEN] Open posted service invoice page
        PostedServiceInvoicePage.OpenEdit();
        PostedServiceInvoicePage.FILTER.SetFilter("No.", CustLedgerEntry."Document No.");
        Assert.AreEqual(
          PostedServiceInvoicePage.MultipleSchemeCodesControl.Visible(), true,
          'Multiple scheme codes label is not visible when multiple codes assigned.');

        // [WHEN] Press "Special Scheme Codes" action
        PostedServiceInvoicePage.SpecialSchemeCodes.Invoke();

        // [THEN] Codes 01 and 02 are available in the "Special Scheme Codes" page
        // Handled by SalesDocShemeCodesVerifyFirstTwoCodesModalPageHandler

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SalesDocSchemeCodesModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_MultipleSpecialRegimeCodesForServCrMemo()
    var
        ServiceHeader: Record "Service Header";
        ServiceCreditMemoPage: TestPage "Service Credit Memo";
    begin
        // [FEATURE] [UI] [Service] [Credit Memo]
        // [SCENARIO 385942] Stan can specify multiple special regime codes for the service credit memo

        Initialize();

        // [GIVEN] Service credit memo
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo", LibrarySales.CreateCustomerNo());
        ServiceCreditMemoPage.OpenEdit();
        ServiceCreditMemoPage.FILTER.SetFilter("No.", ServiceHeader."No.");
        Assert.AreEqual(
          ServiceCreditMemoPage."Special Scheme Code".Editable(), true,
          'Special scheme should be editable when no multiple codes assigned.');

        // [GIVEN] Press "Special Scheme Codes" action
        // [WHEN] Insert two special regime codes in the opened "Special Regime Codes" page and close it
        // Handled by SalesDocSchemeCodesModalPageHandler
        ServiceCreditMemoPage.SpecialSchemeCodes.Invoke();

        // [THEN] "Special Regime Code" field is not editable
        Assert.AreEqual(
          ServiceCreditMemoPage."Special Scheme Code".Editable(), false,
          'Special scheme should not be editable when multiple codes assigned.');

        // [THEN] "Multiple scheme codes" label field is visible
        Assert.AreEqual(
          ServiceCreditMemoPage.MultipleSchemeCodesControl.Visible(), true,
          'Multiple scheme codes label is not visible when multiple codes assigned.');
    end;

    [Test]
    [HandlerFunctions('SalesDocSchemeCodesModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_MultipleSpecialRegimeCodesForPostedServCrMemo()
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        PostedServCreditMemoPage: TestPage "Posted Service Credit Memo";
    begin
        // [FEATURE] [UI] [Service] [Credit Memo]
        // [SCENARIO 385942] Stan can specify multiple special regime codes for the posted service credit memo

        Initialize();

        // [GIVEN] Posted service credit memo
        ServiceCrMemoHeader."No." := LibraryUtility.GenerateGUID();
        ServiceCrMemoHeader.Insert();
        PostedServCreditMemoPage.OpenEdit();
        PostedServCreditMemoPage.FILTER.SetFilter("No.", ServiceCrMemoHeader."No.");

        // [GIVEN] Press "Special Scheme Codes" action
        // [WHEN] Insert two special regime codes in the opened "Special Regime Codes" page and close it
        // Handled by SalesDocSchemeCodesModalPageHandler
        PostedServCreditMemoPage.SpecialSchemeCodes.Invoke();

        // [THEN] "Multiple scheme codes" label field is visible
        Assert.AreEqual(
          PostedServCreditMemoPage.MultipleSchemeCodesControl.Visible(), true,
          'Multiple scheme codes label is not visible when multiple codes assigned.');
    end;

    [Test]
    [HandlerFunctions('SalesDocShemeCodesVerifyFirstTwoCodesModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_MultipleSpecialRegimeCodesAfterPostingServCrMemo()
    var
        ServiceHeader: Record "Service Header";
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PostedServCreditMemoPage: TestPage "Posted Service Credit Memo";
        SchemeCode: array[2] of Option;
        i: Integer;
    begin
        // [FEATURE] [UI] [Service] [Credit Memo]
        // [SCENARIO 385942] Stan can see multiple special regime codes after posting service credit memo

        Initialize();

        // [GIVEN] Service credit memo with two special scheme codes - 01 and 02
        CreateServiceDoc(ServiceHeader, ServiceHeader."Document Type"::"Credit Memo");
        SchemeCode[1] := SIISalesDocumentSchemeCode."Special Scheme Code"::"01 General";
        SchemeCode[2] := SIISalesDocumentSchemeCode."Special Scheme Code"::"02 Export";
        for i := 1 to ArrayLen(SchemeCode) do begin
            InsertSIISalesDocSpecialSchemeCode(
              SIISalesDocumentSchemeCode, SIISalesDocumentSchemeCode."Entry Type"::Service,
              ServiceHeader."Document Type", ServiceHeader."No.", SchemeCode[i]);
            LibraryVariableStorage.Enqueue(Format(SIISalesDocumentSchemeCode."Special Scheme Code"));
        end;

        // [GIVEN] Post service order
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        FindPostedCustLedgEntry(CustLedgerEntry, ServiceHeader."Bill-to Customer No.");

        // [GIVEN] Open posted service credit memo page
        PostedServCreditMemoPage.OpenEdit();
        PostedServCreditMemoPage.FILTER.SetFilter("No.", CustLedgerEntry."Document No.");
        Assert.AreEqual(
          PostedServCreditMemoPage.MultipleSchemeCodesControl.Visible(), true,
          'Multiple scheme codes label is not visible when multiple codes assigned.');

        // [WHEN] Press "Special Scheme Codes" action
        PostedServCreditMemoPage.SpecialSchemeCodes.Invoke();

        // [THEN] Codes 01 and 02 are available in the "Special Scheme Codes" page
        // Handled by SalesDocShemeCodesVerifyFirstTwoCodesModalPageHandler

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PurchDocSchemeCodesModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_MultipleSpecialRegimeCodesForPurchInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseInvoicePage: TestPage "Purchase Invoice";
    begin
        // [FEATURE] [UI] [Purchase] [Invoice]
        // [SCENARIO 385942] Stan can specify multiple special regime codes for the purchase invoice

        Initialize();

        // [GIVEN] Purchase invoice
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        PurchaseInvoicePage.OpenEdit();
        PurchaseInvoicePage.FILTER.SetFilter("No.", PurchaseHeader."No.");
        Assert.AreEqual(
          PurchaseInvoicePage."Special Scheme Code".Editable(), true,
          'Special scheme should be editable when no multiple codes assigned.');

        // [GIVEN] Press "Special Scheme Codes" action
        // [WHEN] Insert two special regime codes in the opened "Special Regime Codes" page and close it
        // Handled by SalesDocSchemeCodesModalPageHandler
        PurchaseInvoicePage.SpecialSchemeCodes.Invoke();

        // [THEN] "Special Regime Code" field is not editable
        Assert.AreEqual(
          PurchaseInvoicePage."Special Scheme Code".Editable(), false,
          'Special scheme should not be editable when multiple codes assigned.');

        // [THEN] "Multiple scheme codes" label field is visible
        Assert.AreEqual(
          PurchaseInvoicePage.MultipleSchemeCodesControl.Visible(), true,
          'Multiple scheme codes label is not visible when multiple codes assigned.');
    end;

    [Test]
    [HandlerFunctions('PurchDocSchemeCodesModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_MultipleSpecialRegimeCodesForPostedPurchInvoice()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        PostedPurchaseInvoicePage: TestPage "Posted Purchase Invoice";
    begin
        // [FEATURE] [UI] [Purchase] [Invoice]
        // [SCENARIO 385942] Stan can specify multiple special regime codes for the posted purchase invoice

        Initialize();

        // [GIVEN] Posted purchase invoice
        PurchInvHeader."No." := LibraryUtility.GenerateGUID();
        PurchInvHeader.Insert();
        PostedPurchaseInvoicePage.OpenEdit();
        PostedPurchaseInvoicePage.FILTER.SetFilter("No.", PurchInvHeader."No.");

        // [GIVEN] Press "Special Scheme Codes" action
        // [WHEN] Insert two special regime codes in the opened "Special Regime Codes" page and close it
        // Handled by SalesDocSchemeCodesModalPageHandler
        PostedPurchaseInvoicePage.SpecialSchemeCodes.Invoke();

        // [THEN] "Multiple scheme codes" label field is visible
        Assert.AreEqual(
          PostedPurchaseInvoicePage.MultipleSchemeCodesControl.Visible(), true,
          'Multiple scheme codes label is not visible when multiple codes assigned.');
    end;

    [Test]
    [HandlerFunctions('PurchDocShemeCodesVerifyFirstTwoCodesModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_MultipleSpecialRegimeCodesAfterPostingPurchInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
        SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
        PostedPurchaseInvoicePage: TestPage "Posted Purchase Invoice";
        InvNo: Code[20];
        SchemeCode: array[2] of Option;
        i: Integer;
    begin
        // [FEATURE] [UI] [Purchase] [Invoice]
        // [SCENARIO 385942] Stan can see multiple special regime codes after posting purchase invoice

        Initialize();

        // [GIVEN] Purchase invoice with two special scheme codes - 01 and 02
        CreatePurchDoc(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, 0);
        SchemeCode[1] := SIIPurchDocSchemeCode."Special Scheme Code"::"01 General";
        SchemeCode[2] := SIIPurchDocSchemeCode."Special Scheme Code"::"02 Special System Activities";
        for i := 1 to ArrayLen(SchemeCode) do begin
            InsertSIIPurchDocSpecialSchemeCode(
              SIIPurchDocSchemeCode, PurchaseHeader."Document Type", PurchaseHeader."No.", SchemeCode[i]);
            LibraryVariableStorage.Enqueue(Format(SIIPurchDocSchemeCode."Special Scheme Code"));
        end;

        // [GIVEN] Post purchase invoice
        InvNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Open posted purchase invoice page
        PostedPurchaseInvoicePage.OpenEdit();
        PostedPurchaseInvoicePage.FILTER.SetFilter("No.", InvNo);
        Assert.AreEqual(
          PostedPurchaseInvoicePage.MultipleSchemeCodesControl.Visible(), true,
          'Multiple scheme codes label is not visible when multiple codes assigned.');

        // [WHEN] Press "Special Scheme Codes" action
        PostedPurchaseInvoicePage.SpecialSchemeCodes.Invoke();

        // [THEN] Codes 01 and 02 are available in the "Special Scheme Codes" page
        // Handled by SalesDocShemeCodesVerifyFirstTwoCodesModalPageHandler

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PurchDocSchemeCodesModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_MultipleSpecialRegimeCodesForPurchOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseOrderPage: TestPage "Purchase Order";
    begin
        // [FEATURE] [UI] [Purchase] [Order]
        // [SCENARIO 385942] Stan can specify multiple special regime codes for the purchase order

        Initialize();

        // [GIVEN] Purchase order
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseOrderPage.OpenEdit();
        PurchaseOrderPage.FILTER.SetFilter("No.", PurchaseHeader."No.");
        Assert.AreEqual(
          PurchaseOrderPage."Special Scheme Code".Editable(), true, 'Special scheme should be editable when no multiple codes assigned.');

        // [GIVEN] Press "Special Scheme Codes" action
        // [WHEN] Insert two special regime codes in the opened "Special Regime Codes" page and close it
        // Handled by SalesDocSchemeCodesModalPageHandler
        PurchaseOrderPage.SpecialSchemeCodes.Invoke();

        // [THEN] "Special Regime Code" field is not editable
        Assert.AreEqual(
          PurchaseOrderPage."Special Scheme Code".Editable(), false, 'Special scheme should not be editable when multiple codes assigned.');

        // [THEN] "Multiple scheme codes" label field is visible
        Assert.AreEqual(
          PurchaseOrderPage.MultipleSchemeCodesControl.Visible(), true,
          'Multiple scheme codes label is not visible when multiple codes assigned.');
    end;

    [Test]
    [HandlerFunctions('PurchDocShemeCodesVerifyFirstTwoCodesModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_MultipleSpecialRegimeCodesAfterPostingPurchOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
        PostedPurchaseInvoicePage: TestPage "Posted Purchase Invoice";
        InvNo: Code[20];
        SchemeCode: array[2] of Option;
        i: Integer;
    begin
        // [FEATURE] [UI] [Purchase] [Order]
        // [SCENARIO 385942] Stan can see multiple special regime codes after posting purchase order

        Initialize();

        // [GIVEN] Purchase order with two special scheme codes - 01 and 02
        CreatePurchDoc(PurchaseHeader, PurchaseHeader."Document Type"::Order, 0);
        SchemeCode[1] := SIIPurchDocSchemeCode."Special Scheme Code"::"01 General";
        SchemeCode[2] := SIIPurchDocSchemeCode."Special Scheme Code"::"02 Special System Activities";
        for i := 1 to ArrayLen(SchemeCode) do begin
            InsertSIIPurchDocSpecialSchemeCode(
              SIIPurchDocSchemeCode, PurchaseHeader."Document Type", PurchaseHeader."No.", SchemeCode[i]);
            LibraryVariableStorage.Enqueue(Format(SIIPurchDocSchemeCode."Special Scheme Code"));
        end;

        // [GIVEN] Post purchase order
        InvNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Open posted purchase invoice page
        PostedPurchaseInvoicePage.OpenEdit();
        PostedPurchaseInvoicePage.FILTER.SetFilter("No.", InvNo);
        Assert.AreEqual(
          PostedPurchaseInvoicePage.MultipleSchemeCodesControl.Visible(), true,
          'Multiple scheme codes label is not visible when multiple codes assigned.');

        // [WHEN] Press "Special Scheme Codes" action
        PostedPurchaseInvoicePage.SpecialSchemeCodes.Invoke();

        // [THEN] Codes 01 and 02 are available in the "Special Scheme Codes" page
        // Handled by SalesDocShemeCodesVerifyFirstTwoCodesModalPageHandler

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PurchDocSchemeCodesModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_MultipleSpecialRegimeCodesForPurchCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseCreditMemoPage: TestPage "Purchase Credit Memo";
    begin
        // [FEATURE] [UI] [Purchase] [Credit Memo]
        // [SCENARIO 385942] Stan can specify multiple special regime codes for the purchase credit memo

        Initialize();

        // [GIVEN] Purchase credit memo
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", LibraryPurchase.CreateVendorNo());
        PurchaseCreditMemoPage.OpenEdit();
        PurchaseCreditMemoPage.FILTER.SetFilter("No.", PurchaseHeader."No.");
        Assert.AreEqual(
          PurchaseCreditMemoPage."Special Scheme Code".Editable(), true,
          'Special scheme should be editable when no multiple codes assigned.');

        // [GIVEN] Press "Special Scheme Codes" action
        // [WHEN] Insert two special regime codes in the opened "Special Regime Codes" page and close it
        // Handled by SalesDocSchemeCodesModalPageHandler
        PurchaseCreditMemoPage.SpecialSchemeCodes.Invoke();

        // [THEN] "Special Regime Code" field is not editable
        Assert.AreEqual(
          PurchaseCreditMemoPage."Special Scheme Code".Editable(), false,
          'Special scheme should not be editable when multiple codes assigned.');

        // [THEN] "Multiple scheme codes" label field is visible
        Assert.AreEqual(
          PurchaseCreditMemoPage.MultipleSchemeCodesControl.Visible(), true,
          'Multiple scheme codes label is not visible when multiple codes assigned.');
    end;

    [Test]
    [HandlerFunctions('PurchDocSchemeCodesModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_MultipleSpecialRegimeCodesForPostedPurchCrMemo()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PostedPurchaseCreditMemoPage: TestPage "Posted Purchase Credit Memo";
    begin
        // [FEATURE] [UI] [Purchase] [Credit Memo]
        // [SCENARIO 385942] Stan can specify multiple special regime codes for the posted purchase credit memo

        Initialize();

        // [GIVEN] Posted purchase credit memo
        PurchCrMemoHdr."No." := LibraryUtility.GenerateGUID();
        PurchCrMemoHdr.Insert();
        PostedPurchaseCreditMemoPage.OpenEdit();
        PostedPurchaseCreditMemoPage.FILTER.SetFilter("No.", PurchCrMemoHdr."No.");

        // [GIVEN] Press "Special Scheme Codes" action
        // [WHEN] Insert two special regime codes in the opened "Special Regime Codes" page and close it
        // Handled by SalesDocSchemeCodesModalPageHandler
        PostedPurchaseCreditMemoPage.SpecialSchemeCodes.Invoke();

        // [THEN] "Multiple scheme codes" label field is visible
        Assert.AreEqual(
          PostedPurchaseCreditMemoPage.MultipleSchemeCodesControl.Visible(), true,
          'Multiple scheme codes label is not visible when multiple codes assigned.');
    end;

    [Test]
    [HandlerFunctions('PurchDocShemeCodesVerifyFirstTwoCodesModalPageHandler')]
    [Scope('OnPrem')]
    procedure UI_MultipleSpecialRegimeCodesAfterPostingPurchCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
        PostedPurchaseCreditMemoPage: TestPage "Posted Purchase Credit Memo";
        CrMemo: Code[20];
        SchemeCode: array[2] of Option;
        i: Integer;
    begin
        // [FEATURE] [UI] [Purchase] [Credit Memo]
        // [SCENARIO 385942] Stan can see multiple special regime codes after posting purchase credit memo

        Initialize();

        // [GIVEN] Purchase credit memo with two special scheme codes - 01 and 02
        CreatePurchDoc(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", 0);
        SchemeCode[1] := SIIPurchDocSchemeCode."Special Scheme Code"::"01 General";
        SchemeCode[2] := SIIPurchDocSchemeCode."Special Scheme Code"::"02 Special System Activities";
        for i := 1 to ArrayLen(SchemeCode) do begin
            InsertSIIPurchDocSpecialSchemeCode(
              SIIPurchDocSchemeCode, PurchaseHeader."Document Type", PurchaseHeader."No.", SchemeCode[i]);
            LibraryVariableStorage.Enqueue(Format(SIIPurchDocSchemeCode."Special Scheme Code"));
        end;

        // [GIVEN] Post purchase credit memo
        CrMemo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Open posted purchase credit memo page
        PostedPurchaseCreditMemoPage.OpenEdit();
        PostedPurchaseCreditMemoPage.FILTER.SetFilter("No.", CrMemo);
        Assert.AreEqual(
          PostedPurchaseCreditMemoPage.MultipleSchemeCodesControl.Visible(), true,
          'Multiple scheme codes label is not visible when multiple codes assigned.');

        // [WHEN] Press "Special Scheme Codes" action
        PostedPurchaseCreditMemoPage.SpecialSchemeCodes.Invoke();

        // [THEN] Codes 01 and 02 are available in the "Special Scheme Codes" page
        // Handled by SalesDocShemeCodesVerifyFirstTwoCodesModalPageHandler

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSalesInvoiceWithMultipleSpecialRegimeCodes()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Export] [Sales] [Invoice]
        // [SCENARIO 385942] Multiple xml nodes generate per each regime code of the posted sales invoice

        Initialize();

        // [GIVEN] Posted sales invoice with three regime codes - 01,02 and 03
        PostSalesDocWithMultipleRegimeCodes(CustLedgerEntry, SalesHeader."Document Type"::Invoice, 0);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] ClaveRegimenEspecialOTrascendencia is "01" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ClaveRegimenEspecialOTrascendencia', '01');
        // [THEN] ClaveRegimenEspecialOTrascendenciaAdicional1 is "02" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ClaveRegimenEspecialOTrascendenciaAdicional1', '02');
        // [THEN] ClaveRegimenEspecialOTrascendenciaAdicional2 is "03" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ClaveRegimenEspecialOTrascendenciaAdicional2', '03');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSalesCrMemoWithMultipleSpecialRegimeCodes()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Export] [Sales] [Credit Memo]
        // [SCENARIO 385942] Multiple xml nodes generate per each regime code of the posted sales credit memo

        Initialize();

        // [GIVEN] Posted sales credit memo with three regime codes - 01,02 and 03
        PostSalesDocWithMultipleRegimeCodes(CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", 0);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] ClaveRegimenEspecialOTrascendencia is "01" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ClaveRegimenEspecialOTrascendencia', '01');
        // [THEN] ClaveRegimenEspecialOTrascendenciaAdicional1 is "02" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ClaveRegimenEspecialOTrascendenciaAdicional1', '02');
        // [THEN] ClaveRegimenEspecialOTrascendenciaAdicional2 is "03" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ClaveRegimenEspecialOTrascendenciaAdicional2', '03');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportSalesReplacementCrMemoWithMultipleSpecialRegimeCodes()
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Export] [Sales] [Credit Memo]
        // [SCENARIO 385942] Multiple xml nodes generate per each regime code of the posted sales replacement credit memo

        Initialize();

        // [GIVEN] Posted sales replacement credit memo with three regime codes - 01,02 and 03
        PostSalesDocWithMultipleRegimeCodes(
          CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Correction Type"::Replacement);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] ClaveRegimenEspecialOTrascendencia is "01" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ClaveRegimenEspecialOTrascendencia', '01');
        // [THEN] ClaveRegimenEspecialOTrascendenciaAdicional1 is "02" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ClaveRegimenEspecialOTrascendenciaAdicional1', '02');
        // [THEN] ClaveRegimenEspecialOTrascendenciaAdicional2 is "03" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ClaveRegimenEspecialOTrascendenciaAdicional2', '03');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportServInvoiceWithMultipleSpecialRegimeCodes()
    var
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Export] [Service] [Invoice]
        // [SCENARIO 385942] Multiple xml nodes generate per each regime code of the posted sales invoice

        Initialize();

        // [GIVEN] Posted service invoice with three regime codes - 01,02 and 03
        PostServiceDocWithMultipleRegimeCodes(CustLedgerEntry, ServiceHeader."Document Type"::Invoice, 0);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] ClaveRegimenEspecialOTrascendencia is "01" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ClaveRegimenEspecialOTrascendencia', '01');
        // [THEN] ClaveRegimenEspecialOTrascendenciaAdicional1 is "02" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ClaveRegimenEspecialOTrascendenciaAdicional1', '02');
        // [THEN] ClaveRegimenEspecialOTrascendenciaAdicional2 is "03" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ClaveRegimenEspecialOTrascendenciaAdicional2', '03');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportServCrMemoWithMultipleSpecialRegimeCodes()
    var
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Export] [Service] [Credit Memo]
        // [SCENARIO 385942] Multiple xml nodes generate per each regime code of the posted sales credit memo

        Initialize();

        // [GIVEN] Posted service credit memo with three regime codes - 01,02 and 03
        PostServiceDocWithMultipleRegimeCodes(CustLedgerEntry, ServiceHeader."Document Type"::"Credit Memo", 0);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] ClaveRegimenEspecialOTrascendencia is "01" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ClaveRegimenEspecialOTrascendencia', '01');
        // [THEN] ClaveRegimenEspecialOTrascendenciaAdicional1 is "02" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ClaveRegimenEspecialOTrascendenciaAdicional1', '02');
        // [THEN] ClaveRegimenEspecialOTrascendenciaAdicional2 is "03" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ClaveRegimenEspecialOTrascendenciaAdicional2', '03');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportServReplacementCrMemoWithMultipleSpecialRegimeCodes()
    var
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Export] [Service] [Credit Memo]
        // [SCENARIO 385942] Multiple xml nodes generate per each regime code of the posted sales replacement credit memo

        Initialize();

        // [GIVEN] Posted service replacement credit memo with three regime codes - 01,02 and 03
        PostServiceDocWithMultipleRegimeCodes(
          CustLedgerEntry, ServiceHeader."Document Type"::"Credit Memo", ServiceHeader."Correction Type"::Replacement);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] ClaveRegimenEspecialOTrascendencia is "01" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ClaveRegimenEspecialOTrascendencia', '01');
        // [THEN] ClaveRegimenEspecialOTrascendenciaAdicional1 is "02" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ClaveRegimenEspecialOTrascendenciaAdicional1', '02');
        // [THEN] ClaveRegimenEspecialOTrascendenciaAdicional2 is "03" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ClaveRegimenEspecialOTrascendenciaAdicional2', '03');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportPurchInvoiceWithMultipleSpecialRegimeCodes()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Export] [Purchase] [Invoice]
        // [SCENARIO 385942] Multiple xml nodes generate per each regime code of the posted purchase invoice

        Initialize();

        // [GIVEN] Posted sapurchaseles invoice with three regime codes - 01,02 and 03
        PostPurchDocWithMultipleRegimeCodes(VendorLedgerEntry, PurchaseHeader."Document Type"::Invoice, 0);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] ClaveRegimenEspecialOTrascendencia is "01" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:ClaveRegimenEspecialOTrascendencia', '01');
        // [THEN] ClaveRegimenEspecialOTrascendenciaAdicional1 is "02" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:ClaveRegimenEspecialOTrascendenciaAdicional1', '02');
        // [THEN] ClaveRegimenEspecialOTrascendenciaAdicional2 is "03" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:ClaveRegimenEspecialOTrascendenciaAdicional2', '03');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportPurchCrMemoWithMultipleSpecialRegimeCodes()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Export] [Purchase] [Credit Memo]
        // [SCENARIO 385942] Multiple xml nodes generate per each regime code of the posted purchase credit memo

        Initialize();

        // [GIVEN] Posted purchase credit memo with three regime codes - 01,02 and 03
        PostPurchDocWithMultipleRegimeCodes(VendorLedgerEntry, PurchaseHeader."Document Type"::"Credit Memo", 0);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] ClaveRegimenEspecialOTrascendencia is "01" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:ClaveRegimenEspecialOTrascendencia', '01');
        // [THEN] ClaveRegimenEspecialOTrascendenciaAdicional1 is "02" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:ClaveRegimenEspecialOTrascendenciaAdicional1', '02');
        // [THEN] ClaveRegimenEspecialOTrascendenciaAdicional2 is "03" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:ClaveRegimenEspecialOTrascendenciaAdicional2', '03');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportPurchReplacementCrMemoWithMultipleSpecialRegimeCodes()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Export] [Purchase] [Credit Memo]
        // [SCENARIO 385942] Multiple xml nodes generate per each regime code of the posted purchase replacement credit memo

        Initialize();

        // [GIVEN] Posted purchase replacement credit memo with three regime codes - 01,02 and 03
        PostPurchDocWithMultipleRegimeCodes(
          VendorLedgerEntry, PurchaseHeader."Document Type"::"Credit Memo", PurchaseHeader."Correction Type"::Replacement);

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendorLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] ClaveRegimenEspecialOTrascendencia is "01" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:ClaveRegimenEspecialOTrascendencia', '01');
        // [THEN] ClaveRegimenEspecialOTrascendenciaAdicional1 is "02" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:ClaveRegimenEspecialOTrascendenciaAdicional1', '02');
        // [THEN] ClaveRegimenEspecialOTrascendenciaAdicional2 is "03" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:ClaveRegimenEspecialOTrascendenciaAdicional2', '03');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_NotPossibleToAssignGeneralSalesSpecialSchemeCodeInVATPostingSetupWithE2ExemptCode()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATClause: Record "VAT Clause";
        VATClauseCode: Code[20];
    begin
        // [FEATURE] [UI] [Sales]
        // [SCENARIO 399176] Stan cannot assign "01 General" value for the "Special Scheme Code" in the VAT Posting Setup when "SII Exemption Code" of the related VAT clause is "E2"

        Initialize();
        VATClauseCode :=
          LibrarySII.CreateVATClauseWithSIIExemptionCode(VATClause."SII Exemption Code"::"E2 Exempt on account of Article 21");
        Commit();
        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Clause Code", VATClauseCode);
        asserterror VATPostingSetup.Validate("Sales Special Scheme Code", VATPostingSetup."Sales Special Scheme Code"::"01 General");
        Assert.ExpectedError(InconsitencyOfRegimeCodeAndVATClauseErr);

        VATPostingSetup.Init();
        VATPostingSetup.Validate("Sales Special Scheme Code", VATPostingSetup."Sales Special Scheme Code"::"01 General");
        asserterror VATPostingSetup.Validate("VAT Clause Code", VATClauseCode);
        Assert.ExpectedError(InconsitencyOfRegimeCodeAndVATClauseErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_NotPossibleToAssignGeneralSalesSpecialSchemeCodeInVATPostingSetupWithE3ExemptCode()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATClause: Record "VAT Clause";
        VATClauseCode: Code[20];
    begin
        // [FEATURE] [UI] [Sales]
        // [SCENARIO 399176] Stan cannot assign "01 General" value for the "Special Scheme Code" in the VAT Posting Setup when "SII Exemption Code" of the related VAT clause is "E3"

        Initialize();
        VATClauseCode :=
          LibrarySII.CreateVATClauseWithSIIExemptionCode(VATClause."SII Exemption Code"::"E3 Exempt on account of Article 22");
        Commit();
        VATPostingSetup.Init();
        VATPostingSetup.Validate("VAT Clause Code", VATClauseCode);
        asserterror VATPostingSetup.Validate("Sales Special Scheme Code", VATPostingSetup."Sales Special Scheme Code"::"01 General");
        Assert.ExpectedError(InconsitencyOfRegimeCodeAndVATClauseErr);

        VATPostingSetup.Init();
        VATPostingSetup.Validate("Sales Special Scheme Code", VATPostingSetup."Sales Special Scheme Code"::"01 General");
        asserterror VATPostingSetup.Validate("VAT Clause Code", VATClauseCode);

        Assert.ExpectedError(InconsitencyOfRegimeCodeAndVATClauseErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UI_SpecialSchemeCodeVisibleInVATPostingSetupPages()
    var
        VATPostingSetup: TestPage "VAT Posting Setup";
        VATPostingSetupCard: TestPage "VAT Posting Setup Card";
    begin
        // [FEATURE] [UI] [Sales] [Purchase]
        // [SCENARIO 399176] Stan can access "Sales Special Scheme Code" and "Purch. Special Scheme Code" fields in the VAT Posting Setup list and card pages

        Initialize();
        LibraryApplicationArea.EnableFoundationSetup();
        VATPostingSetup.OpenView();
        Assert.IsTrue(VATPostingSetup."Sales Special Scheme Code".Visible(), 'Special scheme code field is not visible');
        Assert.IsTrue(VATPostingSetup."Purch. Special Scheme Code".Visible(), 'Special scheme code field is not visible');
        VATPostingSetupCard.OpenView();
        Assert.IsTrue(VATPostingSetupCard."Sales Special Scheme Code".Visible(), 'Special scheme code field is not visible');
        Assert.IsTrue(VATPostingSetupCard."Purch. Special Scheme Code".Visible(), 'Special scheme code field is not visible');

        LibraryApplicationArea.DisableApplicationAreaSetup();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDocInheritsSpecialSchemeCodesFromVATPostingSetup()
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
        DocNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 399176] Special scheme codes specified in the VAT Posting Setup assign to the sales document

        Initialize();

        // [GIVEN] Sales invoice with three lines
        // [GIVEN] First line has VAT Posting Setup with "Sales Special Scheme Code" = "03"
        // [GIVEN] Second line has VAT Posting Setup with "Sales Special Scheme Code" = "04"
        // [GIVEN] Third line has VAT Posting Setup with "Sales Special Scheme Code" = "03"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySII.CreateSalesLineWithUnitPrice(
          SalesHeader,
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            CreateVATPostingSetupWithSalesSpecialSchemeCode(
              SalesHeader."VAT Bus. Posting Group", VATPostingSetup."Sales Special Scheme Code"::"03 Special System")));
        LibrarySII.CreateSalesLineWithUnitPrice(
          SalesHeader,
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            CreateVATPostingSetupWithSalesSpecialSchemeCode(
              SalesHeader."VAT Bus. Posting Group", VATPostingSetup."Sales Special Scheme Code"::"04 Gold")));
        LibrarySII.CreateSalesLineWithUnitPrice(
          SalesHeader,
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            CreateVATPostingSetupWithSalesSpecialSchemeCode(
              SalesHeader."VAT Bus. Posting Group", VATPostingSetup."Sales Special Scheme Code"::"03 Special System")));

        // [WHEN] Post sales invoice
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Two SII sales document scheme codes created for the posted invoice. One with "03" and the other one with "04"
        SIISalesDocumentSchemeCode.SetRange("Entry Type", SIISalesDocumentSchemeCode."Entry Type"::Sales);
        SIISalesDocumentSchemeCode.SetRange("Document Type", SIISalesDocumentSchemeCode."Document Type"::"Posted Invoice");
        SIISalesDocumentSchemeCode.SetRange("Document No.", DocNo);
        Assert.RecordCount(SIISalesDocumentSchemeCode, 2);
        SIISalesDocumentSchemeCode.FindSet();
        SIISalesDocumentSchemeCode.TestField(
          "Special Scheme Code", SIISalesDocumentSchemeCode."Special Scheme Code"::"03 Special System");
        SIISalesDocumentSchemeCode.Next();
        SIISalesDocumentSchemeCode.TestField("Special Scheme Code", SIISalesDocumentSchemeCode."Special Scheme Code"::"04 Gold");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MixOfSalesSpecialSchemeCodesFromVATPostingSetupAndDefaultExportCodeFromVATExemption()
    var
        SalesHeader: Record "Sales Header";
        VATPostingSetup: Record "VAT Posting Setup";
        VATClause: Record "VAT Clause";
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
        DocNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 399176] Both Special scheme codes specified in the VAT Posting Setup and default "02 Export" code of the VAT exemption assign to the sales document

        Initialize();

        // [GIVEN] Sales invoice with two lines
        // [GIVEN] First line has VAT Posting Setup with "Sales Special Scheme Code" = "01"
        // [GIVEN] Second line has VAT Posting Setup with the related VAT Clause that has "SII exemption Code" = "E2"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySII.CreateSalesLineWithUnitPrice(
          SalesHeader,
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            CreateVATPostingSetupWithSalesSpecialSchemeCode(
              SalesHeader."VAT Bus. Posting Group", VATPostingSetup."Sales Special Scheme Code"::"01 General")));
        LibrarySII.CreateSalesLineWithUnitPrice(
          SalesHeader,
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            LibrarySII.CreateVATPostingSetupWithSIIExemptVATClause(
              SalesHeader."VAT Bus. Posting Group", VATClause."SII Exemption Code"::"E2 Exempt on account of Article 21")));

        // [WHEN] Post sales invoice
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Two SII sales document scheme codes created for the posted invoice. One with "01" and the other one with "02"
        SIISalesDocumentSchemeCode.SetRange("Entry Type", SIISalesDocumentSchemeCode."Entry Type"::Sales);
        SIISalesDocumentSchemeCode.SetRange("Document Type", SIISalesDocumentSchemeCode."Document Type"::"Posted Invoice");
        SIISalesDocumentSchemeCode.SetRange("Document No.", DocNo);
        Assert.RecordCount(SIISalesDocumentSchemeCode, 2);
        SIISalesDocumentSchemeCode.FindSet();
        SIISalesDocumentSchemeCode.TestField("Special Scheme Code", SIISalesDocumentSchemeCode."Special Scheme Code"::"01 General");
        SIISalesDocumentSchemeCode.Next();
        SIISalesDocumentSchemeCode.TestField(
          "Special Scheme Code", SIISalesDocumentSchemeCode."Special Scheme Code"::"02 Export");

        // Tear down
        VATPostingSetup.ModifyAll("Sales Special Scheme Code", 0, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServDocInheritsSpecialSchemeCodesFromVATPostingSetup()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        VATPostingSetup: Record "VAT Posting Setup";
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
    begin
        // [FEATURE] [Service]
        // [SCENARIO 399176] Special scheme codes specified in the VAT Posting Setup assign to the service document

        Initialize();

        // [GIVEN] Ser invoice with three lines
        // [GIVEN] First line has VAT Posting Setup with "Sales Special Scheme Code" = "03"
        // [GIVEN] Second line has VAT Posting Setup with "Sales Special Scheme Code" = "04"
        // [GIVEN] Third line has VAT Posting Setup with "Sales Special Scheme Code" = "03"
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySII.CreateServiceLineWithUnitPrice(
          ServiceHeader,
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            CreateVATPostingSetupWithSalesSpecialSchemeCode(
              ServiceHeader."VAT Bus. Posting Group", VATPostingSetup."Sales Special Scheme Code"::"03 Special System")));
        LibrarySII.CreateServiceLineWithUnitPrice(
          ServiceHeader,
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            CreateVATPostingSetupWithSalesSpecialSchemeCode(
              ServiceHeader."VAT Bus. Posting Group", VATPostingSetup."Sales Special Scheme Code"::"04 Gold")));
        LibrarySII.CreateServiceLineWithUnitPrice(
          ServiceHeader,
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            CreateVATPostingSetupWithSalesSpecialSchemeCode(
              ServiceHeader."VAT Bus. Posting Group", VATPostingSetup."Sales Special Scheme Code"::"03 Special System")));

        // [WHEN] Post service invoice
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        LibraryService.FindServiceInvoiceHeader(ServiceInvoiceHeader, ServiceHeader."No.");

        // [THEN] Two SII service document scheme codes created for the posted invoice. One with "03" and the other one with "04"
        SIISalesDocumentSchemeCode.SetRange("Entry Type", SIISalesDocumentSchemeCode."Entry Type"::Service);
        SIISalesDocumentSchemeCode.SetRange("Document Type", SIISalesDocumentSchemeCode."Document Type"::"Posted Invoice");
        SIISalesDocumentSchemeCode.SetRange("Document No.", ServiceInvoiceHeader."No.");
        Assert.RecordCount(SIISalesDocumentSchemeCode, 2);
        SIISalesDocumentSchemeCode.FindSet();
        SIISalesDocumentSchemeCode.TestField("Special Scheme Code", SIISalesDocumentSchemeCode."Special Scheme Code"::"03 Special System");
        SIISalesDocumentSchemeCode.Next();
        SIISalesDocumentSchemeCode.TestField("Special Scheme Code", SIISalesDocumentSchemeCode."Special Scheme Code"::"04 Gold");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MixOfServSpecialSchemeCodesFromVATPostingSetupAndDefaultExportCodeFromVATExemption()
    var
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        VATPostingSetup: Record "VAT Posting Setup";
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
        VATClause: Record "VAT Clause";
    begin
        // [FEATURE] [Service]
        // [SCENARIO 399176] Both Special scheme codes specified in the VAT Posting Setup and default "02 Export" code of the VAT exemption assign to the service document

        Initialize();

        // [GIVEN] Sales invoice with two lines
        // [GIVEN] First line has VAT Posting Setup with "Sales Special Scheme Code" = "01"
        // [GIVEN] Second line has VAT Posting Setup with the related VAT Clause that has "SII exemption Code" = "E2"
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySII.CreateServiceLineWithUnitPrice(
          ServiceHeader,
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            CreateVATPostingSetupWithSalesSpecialSchemeCode(
              ServiceHeader."VAT Bus. Posting Group", VATPostingSetup."Sales Special Scheme Code"::"01 General")));
        LibrarySII.CreateServiceLineWithUnitPrice(
          ServiceHeader,
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            LibrarySII.CreateVATPostingSetupWithSIIExemptVATClause(
              ServiceHeader."VAT Bus. Posting Group", VATClause."SII Exemption Code"::"E2 Exempt on account of Article 21")));

        // [WHEN] Post service invoice
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        LibraryService.FindServiceInvoiceHeader(ServiceInvoiceHeader, ServiceHeader."No.");

        // [THEN] Two SII service document scheme codes created for the posted invoice. One with "01" and the other one with "02"
        SIISalesDocumentSchemeCode.SetRange("Entry Type", SIISalesDocumentSchemeCode."Entry Type"::Service);
        SIISalesDocumentSchemeCode.SetRange("Document Type", SIISalesDocumentSchemeCode."Document Type"::"Posted Invoice");
        SIISalesDocumentSchemeCode.SetRange("Document No.", ServiceInvoiceHeader."No.");
        Assert.RecordCount(SIISalesDocumentSchemeCode, 2);
        SIISalesDocumentSchemeCode.FindSet();
        SIISalesDocumentSchemeCode.TestField("Special Scheme Code", SIISalesDocumentSchemeCode."Special Scheme Code"::"01 General");
        SIISalesDocumentSchemeCode.Next();
        SIISalesDocumentSchemeCode.TestField("Special Scheme Code", SIISalesDocumentSchemeCode."Special Scheme Code"::"02 Export");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchDocInheritsSpecialSchemeCodesFromVATPostingSetup()
    var
        PurchaseHeader: Record "Purchase Header";
        VATPostingSetup: Record "VAT Posting Setup";
        SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
        DocNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 399176] Special scheme codes specified in the VAT Posting Setup assign to the Purchase document

        Initialize();

        // [GIVEN] Purchase invoice with three lines
        // [GIVEN] First line has VAT Posting Setup with "Purch. Special Scheme Code" = "03"
        // [GIVEN] Second line has VAT Posting Setup with "Purch. Special Scheme Code" = "04"
        // [GIVEN] Third line has VAT Posting Setup with "Purch. Special Scheme Code" = "03"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibrarySII.CreatePurchLineWithUnitCost(
          PurchaseHeader,
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            CreateVATPostingSetupWithPurchSpecialSchemeCode(
              PurchaseHeader."VAT Bus. Posting Group", VATPostingSetup."Purch. Special Scheme Code"::"03 Special System")));
        LibrarySII.CreatePurchLineWithUnitCost(
          PurchaseHeader,
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            CreateVATPostingSetupWithPurchSpecialSchemeCode(
              PurchaseHeader."VAT Bus. Posting Group", VATPostingSetup."Purch. Special Scheme Code"::"04 Gold")));
        LibrarySII.CreatePurchLineWithUnitCost(
          PurchaseHeader,
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            CreateVATPostingSetupWithPurchSpecialSchemeCode(
              PurchaseHeader."VAT Bus. Posting Group", VATPostingSetup."Purch. Special Scheme Code"::"03 Special System")));

        // [WHEN] Post purchase invoice
        DocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Two SII purchase document scheme codes created for the posted invoice. One with "03" and the other one with "04"
        SIIPurchDocSchemeCode.SetRange("Document Type", SIIPurchDocSchemeCode."Document Type"::"Posted Invoice");
        SIIPurchDocSchemeCode.SetRange("Document No.", DocNo);
        Assert.RecordCount(SIIPurchDocSchemeCode, 2);
        SIIPurchDocSchemeCode.FindSet();
        SIIPurchDocSchemeCode.TestField("Special Scheme Code", SIIPurchDocSchemeCode."Special Scheme Code"::"03 Special System");
        SIIPurchDocSchemeCode.Next();
        SIIPurchDocSchemeCode.TestField("Special Scheme Code", SIIPurchDocSchemeCode."Special Scheme Code"::"04 Gold");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure SalesInvWithRegimeCode17()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesInvLine: Record "Sales Invoice Line";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 433362] Sales invoice with "Special Scheme Code" equals "17 Operations Under The One-Stop-Shop Regime" exports with ClaveRegimenEspecialOTrascendencia equals "17"

        Initialize();

        // [GIVEN] Sales invoice with "Special Scheme Code" = "17 Operations Under The One-Stop-Shop Regime"
        PostSalesDocWithRegimeCode(
          CustLedgerEntry, SalesHeader."Document Type"::Invoice, 0,
          SalesHeader."Special Scheme Code"::"17 Operations Under The One-Stop-Shop Regime");

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] ClaveRegimenEspecialOTrascendencia is "17" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ClaveRegimenEspecialOTrascendencia', '17');

        // [THEN] "Special Scheme Code" is 17 in posted sales credit memo line
        // Bug id 463723: Special Scheme code does not exist on lines
        SalesInvLine.SetRange("Document No.", CustLedgerEntry."Document No.");
        SalesInvLine.FindFirst();
        SalesInvLine.TestField("Special Scheme Code", SalesInvLine."Special Scheme Code"::"17 Operations Under The One-Stop-Shop Regime");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure SalesCrMemoWithRegimeCode17()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 433362] Sales credit memo with "Special Scheme Code" equals "17 Operations Under The One-Stop-Shop Regime" exports with ClaveRegimenEspecialOTrascendencia equals "17"

        Initialize();

        // [GIVEN] Sales credit memo with "Special Scheme Code" = "17 Operations Under The One-Stop-Shop Regime"
        PostSalesDocWithRegimeCode(
          CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", 0,
          SalesHeader."Special Scheme Code"::"17 Operations Under The One-Stop-Shop Regime");

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] ClaveRegimenEspecialOTrascendencia is "17" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ClaveRegimenEspecialOTrascendencia', '17');

        // [THEN] "Special Scheme Code" is 17 in posted sales credit memo line
        // Bug id 463723: Special Scheme code does not exist on lines
        SalesCrMemoLine.SetRange("Document No.", CustLedgerEntry."Document No.");
        SalesCrMemoLine.FindFirst();
        SalesCrMemoLine.TestField("Special Scheme Code", SalesCrMemoLine."Special Scheme Code"::"17 Operations Under The One-Stop-Shop Regime");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure SalesReplacementCrMemoWithRegimeCode17()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        SalesCrMemoLine: Record "Sales Cr.Memo Line";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 433362] Sales replacement  credit memo with "Special Scheme Code" equals "17 Operations Under The One-Stop-Shop Regime" exports with ClaveRegimenEspecialOTrascendencia equals "17"

        Initialize();

        // [GIVEN] Sales replacement credit memo with "Special Scheme Code" = "17 Operations Under The One-Stop-Shop Regime"
        PostSalesDocWithRegimeCode(
          CustLedgerEntry, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Correction Type"::Replacement,
          SalesHeader."Special Scheme Code"::"17 Operations Under The One-Stop-Shop Regime");

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] ClaveRegimenEspecialOTrascendencia is "17" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ClaveRegimenEspecialOTrascendencia', '17');

        // [THEN] "Special Scheme Code" is 17 in posted sales credit memo line
        // Bug id 463723: Special Scheme code does not exist on lines
        SalesCrMemoLine.SetRange("Document No.", CustLedgerEntry."Document No.");
        SalesCrMemoLine.FindFirst();
        SalesCrMemoLine.TestField("Special Scheme Code", SalesCrMemoLine."Special Scheme Code"::"17 Operations Under The One-Stop-Shop Regime");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ServInvWithRegimeCode17()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ServiceHeader: Record "Service Header";
        ServInvLine: Record "Service Invoice Line";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Service] [Invoice]
        // [SCENARIO 433362] Service invoice with "Special Scheme Code" equals "17 Operations Under The One-Stop-Shop Regime" exports with ClaveRegimenEspecialOTrascendencia equals "17"

        Initialize();

        // [GIVEN] Service invoice with "Special Scheme Code" = "17 Operations Under The One-Stop-Shop Regime"
        PostServDocWithRegimeCode(
          CustLedgerEntry, ServiceHeader."Document Type"::Invoice, 0,
          ServiceHeader."Special Scheme Code"::"17 Operations Under The One-Stop-Shop Regime");

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] ClaveRegimenEspecialOTrascendencia is "17" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ClaveRegimenEspecialOTrascendencia', '17');

        // [THEN] "Special Scheme Code" is 17 in posted service invoice line
        // Bug id 463723: Special Scheme code does not exist on lines
        ServInvLine.SetRange("Document No.", CustLedgerEntry."Document No.");
        ServInvLine.FindFirst();
        ServInvLine.TestField("Special Scheme Code", ServInvLine."Special Scheme Code"::"17 Operations Under The One-Stop-Shop Regime");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ServCrMemoWithRegimeCode17()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ServiceHeader: Record "Service Header";
        ServCrMemoLine: Record "Service Cr.Memo Line";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Service] [Credit Memo]
        // [SCENARIO 433362] Service credit memo with "Special Scheme Code" equals "17 Operations Under The One-Stop-Shop Regime" exports with ClaveRegimenEspecialOTrascendencia equals "17"

        Initialize();

        // [GIVEN] Service credit memo with "Special Scheme Code" = "17 Operations Under The One-Stop-Shop Regime"
        PostServDocWithRegimeCode(
          CustLedgerEntry, ServiceHeader."Document Type"::"Credit Memo", 0,
          ServiceHeader."Special Scheme Code"::"17 Operations Under The One-Stop-Shop Regime");

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] ClaveRegimenEspecialOTrascendencia is "17" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ClaveRegimenEspecialOTrascendencia', '17');

        // [THEN] "Special Scheme Code" is 17 in posted service credit memo line
        // Bug id 463723: Special Scheme code does not exist on lines
        ServCrMemoLine.SetRange("Document No.", CustLedgerEntry."Document No.");
        ServCrMemoLine.FindFirst();
        ServCrMemoLine.TestField("Special Scheme Code", ServCrMemoLine."Special Scheme Code"::"17 Operations Under The One-Stop-Shop Regime");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ServReplacementCrMemoWithRegimeCode17()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ServiceHeader: Record "Service Header";
        ServCrMemoLine: Record "Service Cr.Memo Line";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [FEATURE] [Service] [Credit Memo]
        // [SCENARIO 433362] Service replacement credit memo with "Special Scheme Code" equals "17 Operations Under The One-Stop-Shop Regime" exports with ClaveRegimenEspecialOTrascendencia equals "17"

        Initialize();

        // [GIVEN] Service replacement credit memo with "Special Scheme Code" = "17 Operations Under The One-Stop-Shop Regime"
        PostServDocWithRegimeCode(
          CustLedgerEntry, ServiceHeader."Document Type"::"Credit Memo", ServiceHeader."Correction Type"::Replacement,
          ServiceHeader."Special Scheme Code"::"17 Operations Under The One-Stop-Shop Regime");

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(CustLedgerEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] ClaveRegimenEspecialOTrascendencia is "17" in exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathSalesFacturaExpedidaTok, 'sii:ClaveRegimenEspecialOTrascendencia', '17');

        // [THEN] "Special Scheme Code" is 17 in posted service credit memo line
        // Bug id 463723: Special Scheme code does not exist on lines
        ServCrMemoLine.SetRange("Document No.", CustLedgerEntry."Document No.");
        ServCrMemoLine.FindFirst();
        ServCrMemoLine.TestField("Special Scheme Code", ServCrMemoLine."Special Scheme Code"::"17 Operations Under The One-Stop-Shop Regime");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ChangeRegimeCodeInSalesHeader()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [UT]
        // [SCENARIO 463723] Special scheme code changes in sales lines when Stan changes the value in the sales header with confirmation

        Initialize();

        // [GIVEN] Sales invoice with "Special Scheme Code" = "01 General"
        CreateSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice, SalesHeader."Correction Type"::" ");
        LibraryVariableStorage.Enqueue(StrSubstNo(ConfirmChangeQst, SalesHeader.FieldCaption("Special Scheme Code")));
        LibraryVariableStorage.Enqueue(true); // confirm change

        // [WHEN] Confirm change of "Special Scheme Code" to "04 Gold" in the header
        SalesHeader.Validate("Special Scheme Code", SalesHeader."Special Scheme Code"::"04 Gold");
        SalesHeader.Modify(true);

        // [THEN] "Special Scheme Code" is "04 Gold" in the line
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);
        SalesLine.TestField("Special Scheme Code", SalesLine."Special Scheme Code"::"04 Gold");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure DoNotChangeRegimeCodeInSalesHeader()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [FEATURE] [Sales] [UT]
        // [SCENARIO 463723] Special scheme code does not change in sales lines when Stan changes the value in the sales header and not confirm

        Initialize();

        // [GIVEN] Sales invoice with "Special Scheme Code" = "01 General"
        CreateSalesDoc(SalesHeader, SalesHeader."Document Type"::Invoice, SalesHeader."Correction Type"::" ");
        LibraryVariableStorage.Enqueue(StrSubstNo(ConfirmChangeQst, SalesHeader.FieldCaption("Special Scheme Code")));
        LibraryVariableStorage.Enqueue(false); // do not confirm change

        // [WHEN] Confirm change of "Special Scheme Code" to "04 Gold" in the header
        SalesHeader.Validate("Special Scheme Code", SalesHeader."Special Scheme Code"::"04 Gold");
        SalesHeader.Modify(true);

        // [THEN] "Special Scheme Code" is "04 Gold" in the line
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);
        SalesLine.TestField("Special Scheme Code", SalesLine."Special Scheme Code"::"01 General");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ChangeRegimeCodeInServiceHeader()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Service] [UT]
        // [SCENARIO 463723] Special scheme code changes in sales lines when Stan changes the value in the service header with confirmation

        Initialize();

        // [GIVEN] Sales invoice with "Special Scheme Code" = "01 General"
        CreateServiceDoc(ServiceHeader, ServiceHeader."Document Type"::Invoice);
        LibraryVariableStorage.Enqueue(StrSubstNo(ConfirmChangeQst, ServiceHeader.FieldCaption("Special Scheme Code")));
        LibraryVariableStorage.Enqueue(true); // confirm change

        // [WHEN] Confirm change of "Special Scheme Code" to "04 Gold" in the header
        ServiceHeader.Validate("Special Scheme Code", ServiceHeader."Special Scheme Code"::"04 Gold");
        ServiceHeader.Modify(true);

        // [THEN] "Special Scheme Code" is "04 Gold" in the line
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();
        ServiceLine.TestField("Special Scheme Code", ServiceLine."Special Scheme Code"::"04 Gold");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure DoNotChangeRegimeCodeInServiceHeader()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
    begin
        // [FEATURE] [Service] [UT]
        // [SCENARIO 463723] Special scheme code does not change in sales lines when Stan changes the value in the service header and not confirm

        Initialize();

        // [GIVEN] Sales invoice with "Special Scheme Code" = "01 General"
        CreateServiceDoc(ServiceHeader, ServiceHeader."Document Type"::Invoice);
        LibraryVariableStorage.Enqueue(StrSubstNo(ConfirmChangeQst, ServiceHeader.FieldCaption("Special Scheme Code")));
        LibraryVariableStorage.Enqueue(false); // do not confirm change

        // [WHEN] Confirm change of "Special Scheme Code" to "04 Gold" in the header
        ServiceHeader.Validate("Special Scheme Code", ServiceHeader."Special Scheme Code"::"04 Gold");
        ServiceHeader.Modify(true);

        // [THEN] "Special Scheme Code" is "04 Gold" in the line
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();
        ServiceLine.TestField("Special Scheme Code", ServiceLine."Special Scheme Code"::"01 General");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ChangeRegimeCodeInPurchHeader()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [UT]
        // [SCENARIO 463723] Special scheme code changes in sales lines when Stan changes the value in the purchase header with confirmation

        Initialize();

        // [GIVEN] Sales invoice with "Special Scheme Code" = "01 General"
        CreatePurchDoc(PurchHeader, PurchHeader."Document Type"::Invoice, PurchHeader."Correction Type"::" ");
        LibraryVariableStorage.Enqueue(StrSubstNo(ConfirmChangeQst, PurchHeader.FieldCaption("Special Scheme Code")));
        LibraryVariableStorage.Enqueue(true); // confirm change

        // [WHEN] Confirm change of "Special Scheme Code" to "04 Gold" in the header
        PurchHeader.Validate("Special Scheme Code", PurchHeader."Special Scheme Code"::"04 Gold");
        PurchHeader.Modify(true);

        // [THEN] "Special Scheme Code" is "04 Gold" in the line
        LibraryPurchase.FindFirstPurchLine(PurchLine, PurchHeader);
        PurchLine.TestField("Special Scheme Code", PurchLine."Special Scheme Code"::"04 Gold");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure DoNotChangeRegimeCodeInPurchaseHeader()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        // [FEATURE] [Purchase] [UT]
        // [SCENARIO 463723] Special scheme code does not change in sales lines when Stan changes the value in the purchase header and not confirm

        Initialize();

        // [GIVEN] Sales invoice with "Special Scheme Code" = "01 General"
        CreatePurchDoc(PurchHeader, PurchHeader."Document Type"::Invoice, PurchHeader."Correction Type"::" ");
        LibraryVariableStorage.Enqueue(StrSubstNo(ConfirmChangeQst, PurchHeader.FieldCaption("Special Scheme Code")));
        LibraryVariableStorage.Enqueue(false); // do not confirm change

        // [WHEN] Confirm change of "Special Scheme Code" to "04 Gold" in the header
        PurchHeader.Validate("Special Scheme Code", PurchHeader."Special Scheme Code"::"04 Gold");
        PurchHeader.Modify(true);

        // [THEN] "Special Scheme Code" is "04 Gold" in the line
        LibraryPurchase.FindFirstPurchLine(PurchLine, PurchHeader);
        PurchLine.TestField("Special Scheme Code", PurchLine."Special Scheme Code"::"01 General");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLineInheritsSpecialSchemeCodeFromVATPostingSetup()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Sales] [UT]
        // [SCENARIO 463723] Special scheme codes specified in the VAT Posting Setup assign to the sales line

        Initialize();

        // [GIVEN] VAT Posting Setup "X" with "Sales Special Scheme Code" = "03"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());

        // [WHEN] Create sales line with "VAT Posting Setup" = "X"
        LibrarySII.CreateSalesLineWithUnitPrice(
          SalesHeader,
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            CreateVATPostingSetupWithSalesSpecialSchemeCode(
              SalesHeader."VAT Bus. Posting Group", VATPostingSetup."Sales Special Scheme Code"::"03 Special System")));

        // [THEN] Sales line has "Special Scheme Code" = "03"
        LibrarySales.FindFirstSalesLine(SalesLine, SalesHeader);
        SalesLine.TestField("Special Scheme Code", SalesLine."Special Scheme Code"::"03 Special System");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseLineInheritsSpecialSchemeCodeFromVATPostingSetup()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Purchase] [UT]
        // [SCENARIO 463723] Special scheme codes specified in the VAT Posting Setup assign to the purchase line

        Initialize();

        // [GIVEN] VAT Posting Setup "X" with "Purchase Special Scheme Code" = "03"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());

        // [WHEN] Create purchase line with "VAT Posting Setup" = "X"
        LibrarySII.CreatePurchLineWithUnitCost(
          PurchaseHeader,
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            CreateVATPostingSetupWithPurchSpecialSchemeCode(
              PurchaseHeader."VAT Bus. Posting Group", VATPostingSetup."Purch. Special Scheme Code"::"03 Special System")));

        // [THEN] Purchase line has "Special Scheme Code" = "03"
        LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.TestField("Special Scheme Code", PurchaseLine."Special Scheme Code"::"03 Special System");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceLineInheritsSpecialSchemeCodeFromVATPostingSetup()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [Service] [UT]
        // [SCENARIO 463723] Special scheme codes specified in the VAT Posting Setup assign to the service line

        Initialize();

        // [GIVEN] VAT Posting Setup "X" with "Sales Special Scheme Code" = "03"
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());

        // [WHEN] Create service line with "VAT Posting Setup" = "X"
        LibrarySII.CreateServiceLineWithUnitPrice(
          ServiceHeader,
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            CreateVATPostingSetupWithSalesSpecialSchemeCode(
              ServiceHeader."VAT Bus. Posting Group", VATPostingSetup."Sales Special Scheme Code"::"03 Special System")));

        // [THEN] Service line has "Special Scheme Code" = "03"
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.FindFirst();
        ServiceLine.TestField("Special Scheme Code", ServiceLine."Special Scheme Code"::"03 Special System");
    end;

    [Test]
    procedure SpecialSchemeCodeIs01ForPurchInvWithVATCashRegimInGenLedgSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        VendLedgEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [SCENARIO 561053] Special scheme code is "01" for purchase invoice with VAT Cash Regime in General Ledger Setup

        Initialize();

        // [GIVEN] VAT Cash Regime in General Ledger Setup
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("VAT Cash Regime", true);
        GeneralLedgerSetup.Modify(true);

        // [GIVEN] Posted purchase invoice
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibrarySII.CreatePurchLineWithUnitCost(PurchaseHeader, LibraryInventory.CreateItemNo());
        LibraryERM.FindVendorLedgerEntry(
          VendLedgEntry, PurchaseHeader."Document Type",
          LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendLedgEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] ClaveRegimenEspecialOTrascendencia is "01" in the exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:ClaveRegimenEspecialOTrascendencia', '01');
    end;

    [Test]
    procedure SpecialSchemeCodeIs07ForPurchInvWithVATCashRegimInVATPostingSetup()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        PurchaseHeader: Record "Purchase Header";
        VendLedgEntry: Record "Vendor Ledger Entry";
        SIIXMLCreator: Codeunit "SII XML Creator";
        XMLDoc: DotNet XmlDocument;
    begin
        // [SCENARIO 561053] Special scheme code is "07" for purchase invoice with VAT Cash Regime in VAT Posting Setup

        Initialize();

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Unrealized VAT", true);
        GeneralLedgerSetup.Modify(true);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        // [GIVEN] VAT Posting Setup "X" with "VAT Cash Regime"
        // [GIVEN] Posted purchase invoice with VAT Posting Setup "X"
        LibrarySII.CreatePurchLineWithUnitCost(
          PurchaseHeader,
          LibrarySII.CreateItemNoWithSpecificVATSetup(
            CreateVATPostingSetupWithVATCashRegime(PurchaseHeader."VAT Bus. Posting Group")));
        LibraryERM.FindVendorLedgerEntry(
          VendLedgEntry, PurchaseHeader."Document Type",
          LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [WHEN] Create xml for posted document
        Assert.IsTrue(SIIXMLCreator.GenerateXml(VendLedgEntry, XMLDoc, UploadType::Regular, false), IncorrectXMLDocErr);

        // [THEN] ClaveRegimenEspecialOTrascendencia is "07" in the exported SII File
        LibrarySII.VerifyOneNodeWithValueByXPath(
          XMLDoc, XPathPurchFacturaRecibidaTok, 'sii:ClaveRegimenEspecialOTrascendencia', '07');
    end;

    local procedure Initialize()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibrarySetupStorage.Restore();
        VATPostingSetup.ModifyAll("Sales Special Scheme Code", VATPostingSetup."Sales Special Scheme Code"::" ");
        VATPostingSetup.ModifyAll("Purch. Special Scheme Code", VATPostingSetup."Purch. Special Scheme Code"::" ");
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SII Special Scheme Code Tests");
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SII Special Scheme Code Tests");
        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibrarySII.InitSetup(true, false);
        LibrarySII.BindSubscriptionJobQueue();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SII Special Scheme Code Tests");
    end;

    local procedure PostSalesDocWithMultipleRegimeCodes(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Sales Document Type"; CorrType: Option)
    var
        SalesHeader: Record "Sales Header";
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
        SchemeCode: array[3] of Option;
        i: Integer;
    begin
        CreateSalesDoc(SalesHeader, DocType, CorrType);
        PrepareBufferOfFirstThreeSalesRegimeCodes(SchemeCode);
        for i := 1 to ArrayLen(SchemeCode) do
            InsertSIISalesDocSpecialSchemeCode(
              SIISalesDocumentSchemeCode, SIISalesDocumentSchemeCode."Entry Type"::Sales,
              SalesHeader."Document Type", SalesHeader."No.", SchemeCode[i]);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, SalesHeader."Document Type",
          LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure PostPurchDocWithMultipleRegimeCodes(var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocType: Enum "Purchase Document Type"; CorrType: Option)
    var
        PurchaseHeader: Record "Purchase Header";
        SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
        SchemeCode: array[3] of Option;
        i: Integer;
    begin
        CreatePurchDoc(PurchaseHeader, DocType, CorrType);
        PrepareBufferOfFirstThreePurchRegimeCodes(SchemeCode);
        for i := 1 to ArrayLen(SchemeCode) do
            InsertSIIPurchDocSpecialSchemeCode(
              SIIPurchDocSchemeCode, PurchaseHeader."Document Type", PurchaseHeader."No.", SchemeCode[i]);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntry, PurchaseHeader."Document Type",
          LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure PostServiceDocWithMultipleRegimeCodes(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Service Document Type"; CorrType: Option)
    var
        ServiceHeader: Record "Service Header";
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
        SchemeCode: array[3] of Option;
        i: Integer;
    begin
        CreateServiceDoc(ServiceHeader, DocType);
        ServiceHeader.Validate("Correction Type", CorrType);
        ServiceHeader.Modify(true);
        PrepareBufferOfFirstThreeSalesRegimeCodes(SchemeCode);
        for i := 1 to ArrayLen(SchemeCode) do
            InsertSIISalesDocSpecialSchemeCode(
              SIISalesDocumentSchemeCode, SIISalesDocumentSchemeCode."Entry Type"::Service,
              ServiceHeader."Document Type", ServiceHeader."No.", SchemeCode[i]);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        FindPostedCustLedgEntry(CustLedgerEntry, ServiceHeader."Bill-to Customer No.");
    end;

    local procedure PostSalesDocWithRegimeCode(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Sales Document Type"; CorrType: Option; SpecialSchemeCode: Enum "SII Sales Special Scheme Code")
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDoc(SalesHeader, DocType, CorrType);
        SalesHeader.Validate("Correction Type", CorrType);
        LibraryVariableStorage.Enqueue(StrSubstNo(ConfirmChangeQst, SalesHeader.FieldCaption("Special Scheme Code")));
        LibraryVariableStorage.Enqueue(true);
        SalesHeader.Validate("Special Scheme Code", SpecialSchemeCode);
        SalesHeader.Modify(true);
        LibraryERM.FindCustomerLedgerEntry(
          CustLedgerEntry, SalesHeader."Document Type",
          LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure PostServDocWithRegimeCode(var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Service Document Type"; CorrType: Option; SpecialSchemeCode: Enum "SII Sales Special Scheme Code")
    var
        ServiceHeader: Record "Service Header";
    begin
        CreateServiceDoc(ServiceHeader, DocType);
        ServiceHeader.Validate("Correction Type", CorrType);
        LibraryVariableStorage.Enqueue(StrSubstNo(ConfirmChangeQst, ServiceHeader.FieldCaption("Special Scheme Code")));
        LibraryVariableStorage.Enqueue(true);
        ServiceHeader.Validate("Special Scheme Code", SpecialSchemeCode);
        ServiceHeader.Modify(true);
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        FindPostedCustLedgEntry(CustLedgerEntry, ServiceHeader."Bill-to Customer No.");
    end;

    local procedure CreateSalesDoc(var SalesHeader: Record "Sales Header"; DocType: Enum "Sales Document Type"; CorrType: Option)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocType, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Correction Type", CorrType);
        SalesHeader.Modify(true);
        LibrarySII.CreateSalesLineWithUnitPrice(SalesHeader, LibraryInventory.CreateItemNo());
    end;

    local procedure CreatePurchDoc(var PurchaseHeader: Record "Purchase Header"; DocType: Enum "Purchase Document Type"; CorrType: Option)
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocType, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Correction Type", CorrType);
        PurchaseHeader.Modify(true);
        LibrarySII.CreatePurchLineWithUnitCost(PurchaseHeader, LibraryInventory.CreateItemNo());
    end;

    local procedure CreateServiceDoc(var ServiceHeader: Record "Service Header"; DocType: Enum "Service Document Type")
    var
        ServiceLine: Record "Service Line";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        LibrarySII.CreateServiceHeader(ServiceHeader, DocType, LibrarySales.CreateCustomerNo(), '');
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(100));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
    end;

    local procedure CreateVATPostingSetupWithSalesSpecialSchemeCode(VATBusPostGroupCode: Code[20]; SpecialSchemeCode: Enum "SII Sales Upload Scheme Code"): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        exit(CreateVATPostingSetup(VATBusPostGroupCode, SpecialSchemeCode, VATPostingSetup."Purch. Special Scheme Code"::" "));
    end;

    local procedure CreateVATPostingSetupWithPurchSpecialSchemeCode(VATBusPostGroupCode: Code[20]; SpecialSchemeCode: Enum "SII Purch. Upload Scheme Code"): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        exit(CreateVATPostingSetup(VATBusPostGroupCode, VATPostingSetup."Sales Special Scheme Code"::" ", SpecialSchemeCode));
    end;

    local procedure CreateVATPostingSetupWithVATCashRegime(VATBusPostGroupCode: Code[20]): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(
          VATBusPostGroupCode,
          CreateVATPostingSetupWithPurchSpecialSchemeCode(
            VATBusPostGroupCode, VATPostingSetup."Purch. Special Scheme Code"::" "));
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);
        VATPostingSetup.Validate("VAT Cash Regime", true);
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure CreateVATPostingSetup(VATBusPostGroupCode: Code[20]; SalesSpecialSchemeCode: Enum "SII Sales Upload Scheme Code"; PurchSpecialSchemeCode: Enum "SII Purch. Upload Scheme Code"): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup."VAT Bus. Posting Group" := VATBusPostGroupCode;
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetup."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        VATPostingSetup.Validate("Sales Special Scheme Code", SalesSpecialSchemeCode);
        VATPostingSetup.Validate("Purch. Special Scheme Code", PurchSpecialSchemeCode);
        VATPostingSetup.Insert(true);
        exit(VATPostingSetup."VAT Prod. Posting Group");
    end;

    local procedure FindPostedCustLedgEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustNo: Code[20])
    begin
        CustLedgerEntry.SetRange("Customer No.", CustNo);
        CustLedgerEntry.FindFirst();
    end;

    local procedure PrepareBufferOfFirstThreeSalesRegimeCodes(var SchemeCode: array[3] of Option)
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
    begin
        SchemeCode[1] := SIISalesDocumentSchemeCode."Special Scheme Code"::"01 General";
        SchemeCode[2] := SIISalesDocumentSchemeCode."Special Scheme Code"::"02 Export";
        SchemeCode[3] := SIISalesDocumentSchemeCode."Special Scheme Code"::"03 Special System";
    end;

    local procedure PrepareBufferOfFirstThreePurchRegimeCodes(var SchemeCode: array[3] of Option)
    var
        SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
    begin
        SchemeCode[1] := SIIPurchDocSchemeCode."Special Scheme Code"::"01 General";
        SchemeCode[2] := SIIPurchDocSchemeCode."Special Scheme Code"::"02 Special System Activities";
        SchemeCode[3] := SIIPurchDocSchemeCode."Special Scheme Code"::"03 Special System";
    end;

    local procedure InsertSIISalesDocSpecialSchemeCode(var SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code"; EntryType: Option; DocType: Enum "Sales Document Type"; DocNo: Code[20]; SpecialSchemeCode: Option)
    begin
        SIISalesDocumentSchemeCode.Init();
        SIISalesDocumentSchemeCode.Validate("Entry Type", EntryType);
        SIISalesDocumentSchemeCode.Validate("Document Type", DocType);
        SIISalesDocumentSchemeCode.Validate("Document No.", DocNo);
        SIISalesDocumentSchemeCode.Validate("Special Scheme Code", SpecialSchemeCode);
        SIISalesDocumentSchemeCode.Insert(true);
    end;

    local procedure InsertSIIPurchDocSpecialSchemeCode(var SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code"; DocType: Enum "Purchase Document Type"; DocNo: Code[20]; SpecialSchemeCode: Option)
    begin
        SIIPurchDocSchemeCode.Init();
        SIIPurchDocSchemeCode.Validate("Document Type", DocType);
        SIIPurchDocSchemeCode.Validate("Document No.", DocNo);
        SIIPurchDocSchemeCode.Validate("Special Scheme Code", SpecialSchemeCode);
        SIIPurchDocSchemeCode.Insert(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesDocSchemeCodesModalPageHandler(var SIISalesDocSchemeCodes: TestPage "SII Sales Doc. Scheme Codes")
    var
        SIISalesDocumentSchemeCode: Record "SII Sales Document Scheme Code";
    begin
        SIISalesDocSchemeCodes."Special Scheme Code".SetValue(SIISalesDocumentSchemeCode."Special Scheme Code"::"01 General");
        SIISalesDocSchemeCodes.New();
        SIISalesDocSchemeCodes."Special Scheme Code".SetValue(SIISalesDocumentSchemeCode."Special Scheme Code"::"02 Export");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesDocShemeCodesVerifyFirstTwoCodesModalPageHandler(var SIISalesDocSchemeCodes: TestPage "SII Sales Doc. Scheme Codes")
    begin
        SIISalesDocSchemeCodes."Special Scheme Code".AssertEquals(LibraryVariableStorage.DequeueText());
        Assert.IsTrue(SIISalesDocSchemeCodes.Next(), '');
        SIISalesDocSchemeCodes."Special Scheme Code".AssertEquals(LibraryVariableStorage.DequeueText());
        Assert.IsTrue(SIISalesDocSchemeCodes.Next(), '');
        SIISalesDocSchemeCodes."Special Scheme Code".AssertEquals(' ');
        Assert.IsFalse(SIISalesDocSchemeCodes.Next(), '');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchDocSchemeCodesModalPageHandler(var SIIPurchDocSchemeCodes: TestPage "SII Purch. Doc. Scheme Codes")
    var
        SIIPurchDocSchemeCode: Record "SII Purch. Doc. Scheme Code";
    begin
        SIIPurchDocSchemeCodes."Special Scheme Code".SetValue(SIIPurchDocSchemeCode."Special Scheme Code"::"01 General");
        SIIPurchDocSchemeCodes.New();
        SIIPurchDocSchemeCodes."Special Scheme Code".SetValue(
          SIIPurchDocSchemeCode."Special Scheme Code"::"02 Special System Activities");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PurchDocShemeCodesVerifyFirstTwoCodesModalPageHandler(var SIIPurchDocSchemeCodes: TestPage "SII Purch. Doc. Scheme Codes")
    begin
        SIIPurchDocSchemeCodes."Special Scheme Code".AssertEquals(LibraryVariableStorage.DequeueText());
        Assert.IsTrue(SIIPurchDocSchemeCodes.Next(), '');
        SIIPurchDocSchemeCodes."Special Scheme Code".AssertEquals(LibraryVariableStorage.DequeueText());
        Assert.IsTrue(SIIPurchDocSchemeCodes.Next(), '');
        SIIPurchDocSchemeCodes."Special Scheme Code".AssertEquals(' ');
        Assert.IsFalse(SIIPurchDocSchemeCodes.Next(), '');
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(Question, LibraryVariableStorage.DequeueText());
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;
}

