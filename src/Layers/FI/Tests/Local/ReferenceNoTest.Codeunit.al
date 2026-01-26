codeunit 144005 "Reference No Test"
{
    // // [FEATURE] [Reference No]
    //
    // This Reference Nos test COD144006 works in collaboration with COD144005. Cod144005 (this codeunit) verifies that posting
    // documents will actually call the Reference No generating code (and it's errorhandling)
    // COD144006 verifies the concrete Reference Number genration and specifically that the right errors are generated when FI
    // system is set to NOT generate a valid numerical-only Reference No of max length 20 (inlcuding checkdigit).
    //
    // This codeunit replaces these manual tests for FI Reference No.
    // Print Reference No. UnChecked - These tests setup the REFNUM to properly generate a numberm but to not print it
    // 60770 REFNUM - Reference No. on Sales Order - Print Reference No. unchecked
    // 60771 REFNUM - Reference No. on Prepayment Invoice - Print Reference No. unchecked
    // 60772 REFNUM - Reference No. on Sales Invoice - Print Reference No. unchecked
    // 60773 REFNUM - Reference No. on Service Order - Print Reference No. unchecked
    // 60774 REFNUM - Reference No. on Service Invoice - Print Reference No. unchecked
    //
    // Print Reference No. Checked - - These tests setup the REFNUM to properly generate a number and Print it
    // 60775 REFNUM - Reference No. on Sales Order - Print Reference No. checked
    // 60776 REFNUM - Reference No. on Prepayment Invoice - Print Reference No. checked
    // 60777 REFNUM - Reference No. on Sales Invoice - Print Reference No. checked
    // 60779 REFNUM - Reference No. on Service Invoice - Print Reference No. checked
    // 60778 REFNUM - Reference No. on Service Order - Print Reference No. checked

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        RefNoNoSeriesCode: Code[20];
        DocumentPostingTxt: Label 'Error in Document Posting';
        abcTxt: Label 'ABC';

    [Test]
    [HandlerFunctions('PostedServiceInvoiceReportHandler')]
    [Scope('OnPrem')]
    procedure VerifyRefNumOnServiceInvoice()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        PostedDocumentNo: Code[20];
    begin
        // Setup Reference No. generation to generate numbers and to set Reference No. to be printed.
        // Verify that Reference No. is set on Service Invoice Header and present on Invoice report
        // Setup
        Initialize();
        SetupRefNumOnSalesAndReceivablesSetup(RefNoNoSeriesCode, true);

        // Exercise
        PostedDocumentNo := CreateAndPostServiceInvoice();
        ServiceInvoiceHeader.Get(PostedDocumentNo);

        Commit();

        LibraryVariableStorage.Enqueue(PostedDocumentNo);
        REPORT.Run(REPORT::"Service - Invoice", true, false, ServiceInvoiceHeader);

        // Verify
        Assert.AreNotEqual('', ServiceInvoiceHeader."Reference No.", 'Reference No. was not set on Service Invoice');
        VerifyPostedServiceInvoiceReferenceNo(ServiceInvoiceHeader."Reference No.");
    end;

    [Test]
    [HandlerFunctions('PostedServiceInvoiceReportHandler')]
    [Scope('OnPrem')]
    procedure VerifyNoRefNumOnServiceInvoice()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        PostedDocumentNo: Code[20];
    begin
        // Setup Reference No. generation to generate numbers, but set Reference No. to not be printed.
        // Verify that Reference No. is set on Service Invoice Header, but not present on Report
        // Setup
        Initialize();
        SetupRefNumOnSalesAndReceivablesSetup(RefNoNoSeriesCode, false);

        // Exercise
        PostedDocumentNo := CreateAndPostServiceInvoice();
        ServiceInvoiceHeader.Get(PostedDocumentNo);

        Commit();

        LibraryVariableStorage.Enqueue(PostedDocumentNo);
        REPORT.Run(REPORT::"Service - Invoice", true, false, ServiceInvoiceHeader);

        // Verify
        Assert.AreNotEqual('', ServiceInvoiceHeader."Reference No.", 'Reference No. was not set on Service Invoice');
        VerifyPostedServiceInvoiceReferenceNo('');
    end;

    [Test]
    [HandlerFunctions('PostedServiceInvoiceReportHandler')]
    [Scope('OnPrem')]
    procedure VerifyRefNumOnServiceOrder()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        PostedDocumentNo: Code[20];
    begin
        // Setup Reference No. generation to generate numbers and to set Reference No. to be printed.
        // Verify that Reference No. is set on Service Invoice Header and present on Invoice report
        // Setup
        Initialize();
        SetupRefNumOnSalesAndReceivablesSetup(RefNoNoSeriesCode, true);

        // Exercise
        PostedDocumentNo := CreateAndPostServiceOrder();
        ServiceInvoiceHeader.Get(PostedDocumentNo);

        Commit();

        LibraryVariableStorage.Enqueue(PostedDocumentNo);
        REPORT.Run(REPORT::"Service - Invoice", true, false, ServiceInvoiceHeader);

        // Verify
        Assert.AreNotEqual('', ServiceInvoiceHeader."Reference No.", 'Reference No. was not set on Service Invoice');
        VerifyPostedServiceInvoiceReferenceNo(ServiceInvoiceHeader."Reference No.");
    end;

    [Test]
    [HandlerFunctions('PostedServiceInvoiceReportHandler')]
    [Scope('OnPrem')]
    procedure VerifyNoRefNumOnServiceOrder()
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        PostedDocumentNo: Code[20];
    begin
        // Setup Reference No. generation to generate numbers, but set Reference No. to not be printed.
        // Verify that Reference No. is set on Service Invoice Header, but not present on Report
        // Setup
        Initialize();
        SetupRefNumOnSalesAndReceivablesSetup(RefNoNoSeriesCode, false);

        // Exercise
        PostedDocumentNo := CreateAndPostServiceOrder();
        ServiceInvoiceHeader.Get(PostedDocumentNo);

        Commit();

        LibraryVariableStorage.Enqueue(PostedDocumentNo);
        REPORT.Run(REPORT::"Service - Invoice", true, false, ServiceInvoiceHeader);

        // Verify
        Assert.AreNotEqual('', ServiceInvoiceHeader."Reference No.", 'Reference No. was not set on Service Invoice');
        VerifyPostedServiceInvoiceReferenceNo('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyRefNoInCustLedgerEntryFromServInv()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Service Invoice] [Sales]
        // [SCENARIO 376506] After posting Service Invoice, Customer Ledger Entry should contain its "Reference No."

        Initialize();

        // [GIVEN] Reference No Series is set
        SetupRefNumOnSalesAndReceivablesSetup(RefNoNoSeriesCode, false);

        // [WHEN] Posted Service Invoice
        PostedDocumentNo := CreateAndPostServiceOrder();
        ServiceInvoiceHeader.Get(PostedDocumentNo);

        // [THEN] Customer Ledger Entry contains Invoice's Reference No
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Invoice, PostedDocumentNo);
        CustLedgerEntry.TestField("Reference No.", ServiceInvoiceHeader."Reference No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyRefNoInCustLedgerEntryFromPrepaymentInvoice()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Prepayment %]
        // [SCENARIO 441637] Reference No is copied to related Customer Ledger Entry

        // [GIVEN] Sales Invoice with Prepayment percentage set to 100%
        Initialize();

        CreateSalesHeaderWithPrepaymentPercentage(SalesHeader, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(10));

        // [WHEN] The Sales Order is posted
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Reference No. is copied to Customer Ledger Entry record
        SalesInvoiceHeader.SetRange("No.", DocumentNo);
        SalesInvoiceHeader.FindFirst();
        SalesInvoiceHeader.TestField("Reference No.");

        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.TestField("Reference No.", SalesInvoiceHeader."Reference No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifySalesOrderPostWhenCustomerWithLetters()
    var
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 485328] Verify that No error message,and the letters should be removed from the Reference No. when Customer No Contains the Alphanumeric letters.
        Initialize();

        // [GIVEN] Setup the Sales & Receivables Setup & Update some fields.
        SetupInvNoAndCustomerNoTrueOnSalesAndReceivablesSetup();

        // [GIVEN] Create a Customer & Add Letters on Customer.
        CreateCustomerAndRename(Customer);

        // Create A Sales Invoice & Post.
        DocumentNo := CreateSalesInvoiceAndPost(Customer."No.");

        // [VERIFY] Verify that Sales Invoice Successfully Posted.
        Assert.IsTrue(SalesInvoiceHeader.Get(DocumentNo), DocumentPostingTxt);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Reference No Test");
        LibraryReportDataset.Reset();
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Reference No Test");
        IsInitialized := true;

        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        Commit();

        RefNoNoSeriesCode := CreateRefNumberSeries('1000');
        SetupServiceManagementSetup('1000');
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Reference No Test");
    end;

    local procedure CreateSalesHeaderWithPrepaymentPercentage(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Prepayment %", LibraryRandom.RandInt(99));
        SalesHeader.Modify(true);
    end;

    local procedure SetupRefNumOnSalesAndReceivablesSetup(RefNumNos: Code[20]; CheckPrintNo: Boolean)
    var
        SalesAndReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesAndReceivablesSetup.Get();
        SalesAndReceivablesSetup."Reference Nos." := RefNumNos;
        SalesAndReceivablesSetup."Print Reference No." := CheckPrintNo;
        SalesAndReceivablesSetup."Invoice No." := false;
        SalesAndReceivablesSetup."Customer No." := true;
        SalesAndReceivablesSetup.Date := false;
        SalesAndReceivablesSetup."Default Number" := '';
        SalesAndReceivablesSetup.Modify();
    end;

    local procedure SetupServiceManagementSetup(NoSeriesStartingNo: Code[20])
    var
        ServiceMgtSetup: Record "Service Mgt. Setup";
    begin
        // Have Service Management Setup use my Numerical number series.
        ServiceMgtSetup.Get();
        ServiceMgtSetup.Validate("Posted Service Invoice Nos.", CreateRefNumberSeries(NoSeriesStartingNo));
        ServiceMgtSetup.Modify();
    end;

    local procedure CreateAndPostServiceInvoice(): Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Customer: Record Customer;
        ServiceInvoiceHeader: Record "Service Invoice Header";
        LibraryService: Codeunit "Library - Service";
        PreviousPostedDocumentNo: Code[20];
        PostedDocumentNo: Code[20];
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        ServiceLine.Validate(Quantity, 1);
        ServiceLine.Modify();

        if ServiceInvoiceHeader.FindLast() then
            PreviousPostedDocumentNo := ServiceInvoiceHeader."No."
        else
            PreviousPostedDocumentNo := '0';

        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        if ServiceInvoiceHeader.FindLast() then
            PostedDocumentNo := ServiceInvoiceHeader."No."
        else
            PostedDocumentNo := '0';

        Assert.IsTrue(PreviousPostedDocumentNo < PostedDocumentNo, 'Unable to find Service Invoice');
        exit(PostedDocumentNo);
    end;

    local procedure CreateAndPostServiceOrder(): Code[20]
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Customer: Record Customer;
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        LibraryService: Codeunit "Library - Service";
        PreviousPostedDocumentNo: Code[20];
        PostedDocumentNo: Code[20];
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");

        ServiceLine.Validate(Quantity, 1);
        ServiceLine.Modify();

        if ServiceInvoiceHeader.FindLast() then
            PreviousPostedDocumentNo := ServiceInvoiceHeader."No."
        else
            PreviousPostedDocumentNo := '0';

        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        if ServiceInvoiceHeader.FindLast() then
            PostedDocumentNo := ServiceInvoiceHeader."No."
        else
            PostedDocumentNo := '0';

        Assert.IsTrue(PreviousPostedDocumentNo < PostedDocumentNo, 'Unable to find Service Invoice');
        exit(PostedDocumentNo);
    end;

    local procedure CreateRefNumberSeries(StartingNo: Code[20]): Code[10]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, true, false);
        // Spcifically specify the ending No as numerical or the number series will not be numerical
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, StartingNo, '9999');
        exit(NoSeries.Code);
    end;

    local procedure VerifyPostedServiceInvoiceReferenceNo(ExpectedReferenceNo: Code[20])
    begin
        LibraryReportDataset.LoadDataSetFile();
        Assert.AreNotEqual(0, LibraryReportDataset.RowCount(), 'Empty report dataset');
        while LibraryReportDataset.GetNextRow() do
            LibraryReportDataset.AssertCurrentRowValueEquals('RefernceNo_ServInvHeader', ExpectedReferenceNo);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PostedServiceInvoiceReportHandler(var RequestPage: TestRequestPage "Service - Invoice")
    var
        PostedDocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostedDocumentNo);

        RequestPage."Service Invoice Header".SetFilter("No.", PostedDocumentNo);
        RequestPage.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure SetupInvNoAndCustomerNoTrueOnSalesAndReceivablesSetup()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Reference Nos." := '';
        SalesReceivablesSetup."Print Reference No." := true;
        SalesReceivablesSetup."Invoice No." := true;
        SalesReceivablesSetup."Customer No." := true;
        SalesReceivablesSetup.Date := false;
        SalesReceivablesSetup."Default Number" := '';
        SalesReceivablesSetup.Modify();
    end;

    local procedure CreateCustomerAndRename(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Rename(Customer."No." + abcTxt);
    end;

    local procedure CreateSalesInvoiceAndPost(CustomerNo: Code[20]): Code[20];
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(item), LibraryRandom.RandInt(10));
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, true));
    end;
}