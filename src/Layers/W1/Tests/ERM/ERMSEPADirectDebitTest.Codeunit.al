codeunit 134406 "ERM SEPA Direct Debit Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SEPA] [Direct Debit]
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryXMLRead: Codeunit "Library - XML Read";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryDimension: Codeunit "Library - Dimension";
        ServerFileName: Text;
        IsInitialized: Boolean;
        NoEntriesErr: Label 'No entries have been created.', Comment = '%1=Field;%2=Table;%3=Field;%4=Table';
        EntryCountErr: Label 'Actual %1 is different than expected.', Comment = '%1=TableCaption';
        NoDataToExportErr: Label 'There is no data to export. Make sure the %1 field is not set to %2 or %3.', Comment = '%1=Field;%2=Value;%3=Value';
        Found: Boolean;
        ResetTransferDateNotAllowedErr: Label 'You cannot change the transfer date';

    [Test]
    [HandlerFunctions('CreateDirectDebitCollectionHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceDueDateOutRange()
    var
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
    begin
        Initialize();

        // Setup
        PostWorkdateSalesInvoiceSEPADirectDebit(Customer, WorkDate(), WorkDate(), Customer."Partner Type"::Company);
        CreateSEPABankAccount(BankAccount);

        // Execute;
        asserterror
          RunCreateDirectDebitCollectionReport(
            WorkDate() - 10, WorkDate() - 10, Customer."Partner Type"::Company, BankAccount."No.", false, false);

        // Verify
        Assert.ExpectedError(NoEntriesErr);
    end;

    [Test]
    [HandlerFunctions('CreateDirectDebitCollectionHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceDueDateInRange()
    var
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        PostedDocNo: Code[20];
    begin
        Initialize();

        // Setup
        PostedDocNo := PostWorkdateSalesInvoiceSEPADirectDebit(Customer, WorkDate(), WorkDate(), Customer."Partner Type"::Company);
        CreateSEPABankAccount(BankAccount);

        // Execute;
        RunCreateDirectDebitCollectionReport(
          WorkDate() - 5, WorkDate() + 5, Customer."Partner Type"::Company, BankAccount."No.", false, false);

        // Verify
        VerifyDirectDebitMandateID(Customer."No.", PostedDocNo, Found);
        VerifyDirectDebitCollectionEntryCount(PostedDocNo, 1);
    end;

    [Test]
    [HandlerFunctions('CreateDirectDebitCollectionHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceOnlyValidMandateOnCustomer()
    var
        Customer: Record Customer;
        Customer2: Record Customer;
        BankAccount: Record "Bank Account";
        PostedDocNo: Code[20];
        PostedDocNo2: Code[20];
    begin
        Initialize();

        // Setup
        PostTwoWorkdateSalesInvoicesSEPADirectDebit(Customer, Customer2, PostedDocNo, PostedDocNo2);
        CreateSEPABankAccount(BankAccount);

        // Execute;
        RunCreateDirectDebitCollectionReport(
          WorkDate() - 5, WorkDate() + 5, Customer."Partner Type"::Company, BankAccount."No.", true, false);

        // Verify
        VerifyTwoSalesInvoiceValidMandate(Customer."No.", PostedDocNo, Customer2."No.", PostedDocNo2);
    end;

    [Test]
    [HandlerFunctions('CreateDirectDebitCollectionHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceInvalidMandatePositive()
    var
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        PostedDocNo: Code[20];
    begin
        Initialize();

        // Setup
        PostedDocNo := PostWorkdateSalesInvoiceSEPADirectDebit(Customer, WorkDate() - 30, WorkDate() - 30, Customer."Partner Type"::Company);
        CreateSEPABankAccount(BankAccount);

        // Execute;
        RunCreateDirectDebitCollectionReport(
          WorkDate() - 5, WorkDate() + 5, Customer."Partner Type"::Company, BankAccount."No.", false, false);

        // Verify
        VerifyDirectDebitMandateID(Customer."No.", PostedDocNo, not Found);
        VerifyDirectDebitCollectionEntryCount(PostedDocNo, 1);
    end;

    [Test]
    [HandlerFunctions('CreateDirectDebitCollectionHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceInvalidMandateNegative()
    var
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
    begin
        Initialize();

        // Setup
        PostWorkdateSalesInvoiceSEPADirectDebit(Customer, WorkDate() - 30, WorkDate() - 30, Customer."Partner Type"::Company);
        CreateSEPABankAccount(BankAccount);

        // Execute
        asserterror
          RunCreateDirectDebitCollectionReport(
            WorkDate() - 5, WorkDate() + 5, Customer."Partner Type"::Company, BankAccount."No.", true, true);

        // Verify
        Assert.ExpectedError(NoEntriesErr);
    end;

    [Test]
    [HandlerFunctions('CreateDirectDebitCollectionHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceOnlyValidMandateOnInvoice()
    var
        Customer: Record Customer;
        Customer2: Record Customer;
        BankAccount: Record "Bank Account";
        PostedDocNo: Code[20];
        PostedDocNo2: Code[20];
    begin
        Initialize();

        // Setup
        PostTwoWorkdateSalesInvoicesSEPADirectDebit(Customer, Customer2, PostedDocNo, PostedDocNo2);
        CreateSEPABankAccount(BankAccount);

        // Execute;
        RunCreateDirectDebitCollectionReport(
          WorkDate() - 5, WorkDate() + 5, Customer."Partner Type"::Company, BankAccount."No.", false, true);

        // Verify
        VerifyTwoSalesInvoiceValidMandate(Customer."No.", PostedDocNo, Customer2."No.", PostedDocNo2);
    end;

    [Test]
    [HandlerFunctions('CreateDirectDebitCollectionHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoicePartnerType()
    var
        Customer: Record Customer;
        Customer2: Record Customer;
        BankAccount: Record "Bank Account";
        PostedDocNo: Code[20];
        PostedDocNo2: Code[20];
    begin
        Initialize();

        // Setup
        PostedDocNo := PostWorkdateSalesInvoiceSEPADirectDebit(Customer, WorkDate() - 30, WorkDate() + 30, Customer."Partner Type"::Company);
        PostedDocNo2 := PostWorkdateSalesInvoiceSEPADirectDebit(Customer2, WorkDate() - 30, WorkDate() + 30, Customer."Partner Type"::Person);
        CreateSEPABankAccount(BankAccount);

        // Execute
        RunCreateDirectDebitCollectionReport(
          WorkDate() - 5, WorkDate() + 5, Customer."Partner Type"::Person, BankAccount."No.", false, false);

        // Verify
        VerifyDirectDebitMandateID(Customer."No.", PostedDocNo, Found);
        VerifyDirectDebitCollectionEntryCount(PostedDocNo, 0);

        VerifyDirectDebitMandateID(Customer2."No.", PostedDocNo2, Found);
        VerifyDirectDebitCollectionEntryCount(PostedDocNo2, 1);
    end;

    [Test]
    [HandlerFunctions('CreateDirectDebitCollectionHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure VerifyXMLTags()
    var
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        DirectDebitCollectionEntry2: Record "Direct Debit Collection Entry";
        PostedDocNo: Code[20];
    begin
        Initialize();

        // Setup
        PostedDocNo := PostWorkdateSalesInvoiceSEPADirectDebit(Customer, WorkDate() - 30, WorkDate() + 30, Customer."Partner Type"::Company);
        CreateSEPABankAccount(BankAccount);

        // Execute
        RunCreateDirectDebitCollectionReport(
          WorkDate() - 5, WorkDate() + 5, Customer."Partner Type"::Company, BankAccount."No.", false, false);
        DirectDebitCollectionEntry.SetFilter("Applies-to Entry Document No.", '<>%1', PostedDocNo);
        DirectDebitCollectionEntry.DeleteAll(true);
        DirectDebitCollectionEntry.SetRange("Applies-to Entry Document No.", PostedDocNo);
        DirectDebitCollectionEntry.FindFirst();
        DirectDebitCollectionEntry2.SetRange("Direct Debit Collection No.", DirectDebitCollectionEntry."Direct Debit Collection No.");
        ExportToServerTempFile(DirectDebitCollectionEntry2);

        // Verify
        LibraryXMLRead.Initialize(ServerFileName);
        LibraryXMLRead.VerifyNodeValueInSubtree('PmtTpInf', 'LclInstrm', 'B2B');
        LibraryXMLRead.VerifyNodeValue('ChrgBr', 'SLEV');
        // PmtTpInf/InstrPrty removed due to BUG: 267559
        LibraryXMLRead.VerifyElementAbsenceInSubtree('PmtTpInf', 'InstrPrty');
        LibraryXMLRead.VerifyNodeValueInSubtree('MndtRltdInf', 'MndtId', DirectDebitCollectionEntry."Mandate ID");
        LibraryXMLRead.VerifyNodeValueInSubtree('DrctDbtTxInf', 'InstdAmt', DirectDebitCollectionEntry."Transfer Amount");
        LibraryXMLRead.VerifyAttributeValueInSubtree('DrctDbtTxInf', 'InstdAmt', 'Ccy', 'EUR');
        LibraryXMLRead.VerifyNodeValueInSubtree('CdtrAcct', 'IBAN', BankAccount.IBAN);
        LibraryXMLRead.VerifyNodeValueInSubtree('FinInstnId', 'BIC', BankAccount."SWIFT Code");
    end;

    [Test]
    [HandlerFunctions('CreateDirectDebitCollectionHandler,MessageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure ExportCancelledDDCollectionWithEntry()
    var
        BankAcc: Record "Bank Account";
        Customer: Record Customer;
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
    begin
        Initialize();

        // Pre-Setup
        PostWorkdateSalesInvoiceSEPADirectDebit(Customer, WorkDate(), WorkDate(), Customer."Partner Type"::Company);
        CreateSEPABankAccount(BankAcc);
        RunCreateDirectDebitCollectionReport(
          WorkDate() - 5, WorkDate() + 5, Customer."Partner Type"::Company, BankAcc."No.", false, false);

        // Setup
        DirectDebitCollection.SetRange("Partner Type", Customer."Partner Type"::Company);
        DirectDebitCollection.SetRange("To Bank Account No.", BankAcc."No.");
        DirectDebitCollection.FindLast();
        DirectDebitCollection.CloseCollection();

        // Exercise
        asserterror DirectDebitCollection.Export();

        // Verify
        Assert.ExpectedError(
          StrSubstNo(NoDataToExportErr, DirectDebitCollectionEntry.FieldCaption(Status),
            DirectDebitCollectionEntry.Status::Rejected, DirectDebitCollection.Status::Canceled));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExportClosedDDCollectionWithEntry()
    var
        BankAcc: Record "Bank Account";
        BankExportImportSetup: Record "Bank Export/Import Setup";
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        LastDirectDebitCollectionNo: Integer;
    begin
        Initialize();

        // Pre-Setup
        BankExportImportSetup.SetRange("Processing XMLport ID", XMLPORT::"SEPA DD pain.008.001.02");
        BankExportImportSetup.FindFirst();
        LibraryERM.CreateBankAccount(BankAcc);
        BankAcc."SEPA Direct Debit Exp. Format" := BankExportImportSetup.Code;
        BankAcc.IBAN := LibraryUtility.GenerateGUID();
        BankAcc."SWIFT Code" := LibraryUtility.GenerateGUID();
        BankAcc.Modify();
        if DirectDebitCollection.FindLast() then begin
            LastDirectDebitCollectionNo := DirectDebitCollection."No.";
            Clear(DirectDebitCollection);
        end;

        // Setup
        DirectDebitCollection."No." := LastDirectDebitCollectionNo + 1000;
        DirectDebitCollection."To Bank Account No." := BankAcc."No.";
        DirectDebitCollection.Status := DirectDebitCollection.Status::Closed;
        DirectDebitCollection.Insert();
        DirectDebitCollectionEntry."Direct Debit Collection No." := DirectDebitCollection."No.";
        DirectDebitCollectionEntry."Entry No." := 1;
        DirectDebitCollectionEntry.Status := DirectDebitCollectionEntry.Status::Posted;
        DirectDebitCollectionEntry.Insert();

        // Exercise
        asserterror DirectDebitCollection.Export();

        // Verify
        Assert.ExpectedError(
          StrSubstNo(NoDataToExportErr, DirectDebitCollectionEntry.FieldCaption(Status),
            DirectDebitCollectionEntry.Status::Rejected, DirectDebitCollection.Status::Canceled));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateStandardCustSalesCodeWithInvalidDDMandate()
    var
        Customer1: Record Customer;
        Customer2: Record Customer;
        SEPADirectDebitMandate1: Record "SEPA Direct Debit Mandate";
        SEPADirectDebitMandate2: Record "SEPA Direct Debit Mandate";
        StandardCustomerSalesCode: Record "Standard Customer Sales Code";
    begin
        Initialize();

        // Setup
        LibrarySales.CreateCustomer(Customer1);
        LibrarySales.CreateCustomer(Customer2);

        LibrarySales.CreateCustomerMandate(SEPADirectDebitMandate1, Customer1."No.", '', 0D, 0D);
        LibrarySales.CreateCustomerMandate(SEPADirectDebitMandate2, Customer2."No.", '', 0D, 0D);

        LibrarySales.CreateCustomerSalesCode(StandardCustomerSalesCode, Customer1."No.", '');

        // Execute
        asserterror StandardCustomerSalesCode.Validate("Direct Debit Mandate ID", SEPADirectDebitMandate2.ID);

        // Verify
        Assert.ExpectedErrorCode('DB:NothingInsideFilter');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ServiceDocDirectDebitWhenValidatePaymentMethodCode()
    var
        ServiceHeader: Record "Service Header";
        PaymentMethod: Record "Payment Method";
        Customer: Record Customer;
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
    begin
        // [FEATURE] [UT] [Service]
        // [SCENARIO 300593] "Direct Debit Mandate ID" is filled in when Payment Method validated on Service Invoice
        Initialize();

        // [GIVEN] Customer "CUST" with DD Mandate "DD"
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerMandate(SEPADirectDebitMandate, Customer."No.", '', 0D, 0D);

        // [GIVEN] Sevice invoice with customer "CUST"
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, Customer."No.");

        // [GIVEN] Payment method "PM" with "Direct Debit" = true
        CreateDirectDebitPaymentMethod(PaymentMethod);

        // [WHEN] Payment Method Code is being changed to "PM"
        ServiceHeader.Validate("Payment Method Code", PaymentMethod.Code);

        // [THEN] "Direct Debit Mandate ID" = "DD"
        ServiceHeader.TestField("Direct Debit Mandate ID", SEPADirectDebitMandate.ID);
    end;


    [Test]
    [Scope('OnPrem')]
    procedure PostServiceDocWithDirectDebit()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [UT] [Service]
        // [SCENARIO 300593] "Direct Debit Mandate ID" is populated to service invoice header and customer ledger entry when service document is being posted
        Initialize();

        // [GIVEN] Sevice invoice with "Direct Debit Mandate ID" = "DD"
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        ServiceHeader."Direct Debit Mandate ID" :=
            LibraryUtility.GenerateRandomCode(ServiceHeader.FieldNo("Direct Debit Mandate ID"), DATABASE::"Service Header");
        ServiceHeader.Modify();
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItemNo());
        ServiceLine.Validate(Quantity, LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);

        // [WHEN] Service invoice is being posted
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Service invoice header has "Direct Debit Mandate ID" = "DD"
        ServiceInvoiceHeader.SetRange("Bill-to Customer No.", ServiceHeader."Bill-to Customer No.");
        ServiceInvoiceHeader.FindFirst();
        ServiceInvoiceHeader.TestField("Direct Debit Mandate ID", ServiceHeader."Direct Debit Mandate ID");

        // [THEN] Customer ledger entry has "Direct Debit Mandate ID" = "DD"
        CustLedgerEntry.SetRange("Customer No.", ServiceHeader."Bill-to Customer No.");
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.TestField("Direct Debit Mandate ID", ServiceHeader."Direct Debit Mandate ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ClearDirectDebitMandateIDonServiceDocWhenDirectDebitIsFalse()
    var
        ServiceHeader: Record "Service Header";
        PaymentMethod: Record "Payment Method";
    begin
        // [FEATURE] [UT] [Service]
        // [SCENARIO 300593] Clear "Direct Debit Mandate ID" field when "Direct Debit" field is unchecked in validated Payment Method on Service Invoice
        Initialize();

        // [GIVEN] Sevice header with "Direct Debit Mandate ID" = "DD"
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        ServiceHeader."Direct Debit Mandate ID" :=
            LibraryUtility.GenerateRandomCode(ServiceHeader.FieldNo("Direct Debit Mandate ID"), DATABASE::"Service Header");
        ServiceHeader.Modify();

        // [GIVEN] Payment method "PM" with "Direct Debit" = false
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod."Direct Debit" := false;
        PaymentMethod.Modify();

        // [WHEN] Payment Method Code is being changed to "PM"
        ServiceHeader.Validate("Payment Method Code", PaymentMethod.Code);

        // [THEN] "Direct Debit Mandate ID" = ""
        ServiceHeader.TestField("Direct Debit Mandate ID", '');
    end;

    [Test]
    [HandlerFunctions('CreateDirectDebitCollectionHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceDueDateInRangeWithCurrency()
    var
        Currency: Record Currency;
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 327227] Report "Create Direct Debit Collection" works for entries with non-euro currencies.
        Initialize();

        // [GIVEN] Posted Sales Invoice with random Currency for Customer.
        Currency.Get(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2)));
        PostedDocNo :=
          PostWorkdateSalesInvoiceSEPADirectDebitWithCurrency(Customer, WorkDate(), WorkDate(), Customer."Partner Type"::Company, Currency.Code);
        CreateSEPABankAccount(BankAccount);

        // [WHEN] Report "Create Direct Debit Collection" is run for Customer.
        RunCreateDirectDebitCollectionReport(
          LibraryRandom.RandDate(-5), LibraryRandom.RandDate(5), Customer."Partner Type"::Company, BankAccount."No.", false, false);

        // [THEN] Direct Debit Collection Entry is created.
        VerifyDirectDebitMandateID(Customer."No.", PostedDocNo, Found);
        VerifyDirectDebitCollectionEntryCount(PostedDocNo, 1);
    end;

    [Test]
    [HandlerFunctions('CreateDirectDebitCollectionHandler,MessageHandler,ResetTransferDateConfirmHandler')]
    [Scope('OnPrem')]
    procedure ResetTransferDateOnDDEntryOnPageWhenTransferDateEarlierThanToday()
    var
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        DirectDebitCollections: TestPage "Direct Debit Collections";
        DirectDebitCollectEntries: TestPage "Direct Debit Collect. Entries";
        TransferDate: Date;
    begin
        // [SCENARIO 334429] Run "Reset Transfer Date" action of page "Direct Debit Collect. Entries" in case Transfer Date of DD Entry is less than TODAY.
        Initialize();

        // [GIVEN] Direct Debit Collection Entry with Transfer Date < TODAY.
        TransferDate := Today() - 1;
        if not SameYear(TransferDate, Today()) then
            exit;
        CreateDDEntryWithTransferDate(DirectDebitCollectionEntry, TransferDate);

        // [GIVEN] Error "The earliest possible transfer date is today." is shown in the factbox "File Export Errors".
        VerifyTransferDateErrorOnDDEntry(DirectDebitCollectionEntry);

        // [WHEN] Open page "Direct Debit Collect. Entries", run "Reset Transfer Date".
        DirectDebitCollectEntries.Trap();
        DirectDebitCollections.OpenEdit();
        DirectDebitCollections.Filter.SetFilter("No.", Format(DirectDebitCollectionEntry."Direct Debit Collection No."));
        DirectDebitCollections.Entries.Invoke();
        DirectDebitCollectEntries.ResetTransferDate.Invoke();

        // [THEN] Transfer Date of Direct Debit Collection Entry is changed to TODAY. No errors are shown for this DD Collection Entry.
        DirectDebitCollectionEntry.Get(DirectDebitCollectionEntry."Direct Debit Collection No.", DirectDebitCollectionEntry."Entry No.");
        DirectDebitCollectionEntry.TestField("Transfer Date", Today());
        VerifyNoErrorsOnDDEntry(DirectDebitCollectionEntry);
    end;

    [Test]
    [HandlerFunctions('CreateDirectDebitCollectionHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ResetTransferDateOnDDEntryWhenTransferDateLaterThanToday()
    var
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        TransferDate: Date;
    begin
        // [SCENARIO 334429] Run SetTodayAsTransferDateForOverdueEnries function of table "Direct Debit Collection Entry" in case Transfer Date of DD Entry is greater than TODAY.
        Initialize();

        // [GIVEN] Direct Debit Collection Entry with Transfer Date > TODAY.
        TransferDate := Today() + LibraryRandom.RandIntInRange(10, 20);
        CreateDDEntryWithTransferDate(DirectDebitCollectionEntry, TransferDate);

        // [WHEN] Run SetTodayAsTransferDateForOverdueEnries function of Direct Debit Collection Entry table.
        DirectDebitCollectionEntry.SetTodayAsTransferDateForOverdueEnries();

        // [THEN] Transfer Date of Direct Debit Collection Entry is not changed. No errors are shown for this DD Collection Entry.
        DirectDebitCollectionEntry.Get(DirectDebitCollectionEntry."Direct Debit Collection No.", DirectDebitCollectionEntry."Entry No.");
        DirectDebitCollectionEntry.TestField("Transfer Date", TransferDate);
        VerifyNoErrorsOnDDEntry(DirectDebitCollectionEntry);
    end;

    [Test]
    [HandlerFunctions('CreateDirectDebitCollectionHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ResetTransferDateOnDDEntryWhenStatusNotNew()
    var
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        TransferDate: Date;
    begin
        // [SCENARIO 334429] Run SetTodayAsTransferDateForOverdueEnries function of table "Direct Debit Collection Entry" in case Status of DD Entry is not New.
        Initialize();

        // [GIVEN] Direct Debit Collection Entry with Transfer Date < TODAY and Status = Rejected.
        TransferDate := Today() - 1;
        if not SameYear(TransferDate, Today()) then
            exit;

        CreateDDEntryWithTransferDate(DirectDebitCollectionEntry, TransferDate);
        UpdateStatusOnDDCollectionEntry(DirectDebitCollectionEntry, DirectDebitCollectionEntry.Status::Rejected);

        // [WHEN] Run SetTodayAsTransferDateForOverdueEnries function of Direct Debit Collection Entry table.
        DirectDebitCollectionEntry.SetTodayAsTransferDateForOverdueEnries();

        // [THEN] Transfer Date of Direct Debit Collection Entry is not changed. Error "The earliest possible transfer date is today." is shown in the factbox "File Export Errors".
        DirectDebitCollectionEntry.Get(DirectDebitCollectionEntry."Direct Debit Collection No.", DirectDebitCollectionEntry."Entry No.");
        DirectDebitCollectionEntry.TestField("Transfer Date", TransferDate);
        VerifyTransferDateErrorOnDDEntry(DirectDebitCollectionEntry);
    end;

    local procedure SameYear(DateOne: Date; DateTwo: Date): Boolean
    begin
        if DateOne = 0D then
            exit(false);

        if DateTwo = 0D then
            exit(false);

        exit(Date2DMY(DateOne, 3) = Date2DMY(DateTwo, 3));
    end;

    [Test]
    [HandlerFunctions('CreateDirectDebitCollectionHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ResetTransferDateOnDDEntryInCaseMultipleDDCollections()
    var
        DirectDebitCollectionEntry: array[2] of Record "Direct Debit Collection Entry";
        TransferDate: Date;
    begin
        // [SCENARIO 334429] Run SetTodayAsTransferDateForOverdueEnries function of table "Direct Debit Collection Entry" on one DD Collection in case there are several DD Collections.
        Initialize();

        // [GIVEN] Two Direct Debit Collections D1 and D2, each have one DD Collection Entry with Transfer Date < TODAY.
        TransferDate := Today() - 1;
        if not SameYear(TransferDate, Today()) then
            exit;
        CreateDDEntryWithTransferDate(DirectDebitCollectionEntry[1], TransferDate);
        CreateDDEntryWithTransferDate(DirectDebitCollectionEntry[2], TransferDate);

        // [WHEN] Run SetTodayAsTransferDateForOverdueEnries function of Direct Debit Collection Entry table on the D1 Collection.
        DirectDebitCollectionEntry[1].SetTodayAsTransferDateForOverdueEnries();

        // [THEN] Transfer Date of Direct Debit Collection Entry of D1 is changed to TODAY. No errors are shown for this DD Collection Entry.
        DirectDebitCollectionEntry[1].Get(
          DirectDebitCollectionEntry[1]."Direct Debit Collection No.", DirectDebitCollectionEntry[1]."Entry No.");
        DirectDebitCollectionEntry[1].TestField("Transfer Date", Today());
        VerifyNoErrorsOnDDEntry(DirectDebitCollectionEntry[1]);

        // [THEN] Transfer Date of Direct Debit Collection Entry of D2 is not changed. Error "The earliest possible transfer date is today." is shown in the factbox "File Export Errors".
        DirectDebitCollectionEntry[2].Get(
          DirectDebitCollectionEntry[2]."Direct Debit Collection No.", DirectDebitCollectionEntry[2]."Entry No.");
        DirectDebitCollectionEntry[2].TestField("Transfer Date", TransferDate);
        VerifyTransferDateErrorOnDDEntry(DirectDebitCollectionEntry[2]);
    end;

    [Test]
    [HandlerFunctions('CreateDirectDebitCollectionHandler,MessageHandler')]
    procedure ResetTransferDateOnDDEntryOnPageWhenStatusRejected()
    var
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        DirectDebitCollections: TestPage "Direct Debit Collections";
        DirectDebitCollectEntries: TestPage "Direct Debit Collect. Entries";
        TransferDate: Date;
    begin
        // [SCENARIO 391696] Run "Reset Transfer Date" action of page "Direct Debit Collect. Entries" in case Status of DD Entry is Rejected.
        Initialize();

        // [GIVEN] Direct Debit Collection Entry with Transfer Date < TODAY and Status = Rejected.
        TransferDate := Today() - 1;
        if not SameYear(TransferDate, Today()) then
            exit;
        CreateDDEntryWithTransferDate(DirectDebitCollectionEntry, TransferDate);
        UpdateStatusOnDDCollectionEntry(DirectDebitCollectionEntry, DirectDebitCollectionEntry.Status::Rejected);

        // [WHEN] Open Direct Debit Collect. Entries page and press "Reset Transfer Date".
        DirectDebitCollectEntries.Trap();
        DirectDebitCollections.OpenEdit();
        DirectDebitCollections.FILTER.SetFilter("No.", Format(DirectDebitCollectionEntry."Direct Debit Collection No."));
        DirectDebitCollections.Entries.Invoke();
        asserterror DirectDebitCollectEntries.ResetTransferDate.Invoke();

        // [THEN] Error "You cannot change the transfer date" is thrown.
        Assert.ExpectedError(ResetTransferDateNotAllowedErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('CreateDirectDebitCollectionHandler,MessageHandler')]
    procedure ResetTransferDateOnDDEntryOnPageWhenStatusFileCreated()
    var
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        DirectDebitCollections: TestPage "Direct Debit Collections";
        DirectDebitCollectEntries: TestPage "Direct Debit Collect. Entries";
        TransferDate: Date;
    begin
        // [SCENARIO 391696] Run "Reset Transfer Date" action of page "Direct Debit Collect. Entries" in case Status of DD Entry is File Created.
        Initialize();

        // [GIVEN] Direct Debit Collection Entry with Transfer Date < TODAY and Status = File Created.
        TransferDate := Today() - 1;
        if not SameYear(TransferDate, Today()) then
            exit;
        CreateDDEntryWithTransferDate(DirectDebitCollectionEntry, TransferDate);
        UpdateStatusOnDDCollectionEntry(DirectDebitCollectionEntry, DirectDebitCollectionEntry.Status::"File Created");

        // [WHEN] Open Direct Debit Collect. Entries page and press "Reset Transfer Date".
        DirectDebitCollectEntries.Trap();
        DirectDebitCollections.OpenEdit();
        DirectDebitCollections.Filter.SetFilter("No.", Format(DirectDebitCollectionEntry."Direct Debit Collection No."));
        DirectDebitCollections.Entries.Invoke();
        asserterror DirectDebitCollectEntries.ResetTransferDate.Invoke();

        // [THEN] Error "You cannot change the transfer date" is thrown.
        Assert.ExpectedError(ResetTransferDateNotAllowedErr);
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('CreateDirectDebitCollectionHandler,MessageHandler,ResetTransferDateConfirmHandler')]
    procedure ResetTransferDateOnTwoDDEntriesOnPageWhenStatusFileCreatedAndNew()
    var
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        DirectDebitCollections: TestPage "Direct Debit Collections";
        DirectDebitCollectEntries: TestPage "Direct Debit Collect. Entries";
        DirectDebitCollectionNo: Integer;
        DirectDebitCollectionEntryNo: array[2] of Integer;
        TransferDate: Date;
    begin
        // [SCENARIO 391696] Run "Reset Transfer Date" action of page "Direct Debit Collect. Entries" in case of two DD entries with Statuses New and File Created.
        Initialize();

        // [GIVEN] Two Direct Debit Collection Entries "DDE1" and "DDE2" with Transfer Date < TODAY in one DD Collection.
        // [GIVEN] "DDE1" Entry has Status = File Created, "DDE2" Entry has Status = New.
        TransferDate := Today() - 1;
        if not SameYear(TransferDate, Today()) then
            exit;
        CreateTwoDDEntriesWithTransferDate(DirectDebitCollectionNo, DirectDebitCollectionEntryNo, TransferDate);
        DirectDebitCollectionEntry.Get(DirectDebitCollectionNo, DirectDebitCollectionEntryNo[1]);
        UpdateStatusOnDDCollectionEntry(DirectDebitCollectionEntry, DirectDebitCollectionEntry.Status::"File Created");
        DirectDebitCollectionEntry.Get(DirectDebitCollectionNo, DirectDebitCollectionEntryNo[2]);
        DirectDebitCollectionEntry.TestField(Status, DirectDebitCollectionEntry.Status::New);

        // [WHEN] Open Direct Debit Collect. Entries page and press "Reset Transfer Date".
        DirectDebitCollectEntries.Trap();
        DirectDebitCollections.OpenEdit();
        DirectDebitCollections.Filter.SetFilter("No.", Format(DirectDebitCollectionNo));
        DirectDebitCollections.Entries.Invoke();
        DirectDebitCollectEntries.ResetTransferDate.Invoke();

        // [THEN] Transfer Date of Direct Debit Collection Entry "DDE1" was not changed.
        // [THEN] Transfer Date of Direct Debit Collection Entry "DDE2" was changed to TODAY.
        DirectDebitCollectionEntry.Get(DirectDebitCollectionNo, DirectDebitCollectionEntryNo[1]);
        DirectDebitCollectionEntry.TestField("Transfer Date", TransferDate);
        DirectDebitCollectionEntry.Get(DirectDebitCollectionNo, DirectDebitCollectionEntryNo[2]);
        DirectDebitCollectionEntry.TestField("Transfer Date", Today);
    end;

    [Test]
    [HandlerFunctions('CreateDirectDebitCollectionHandlerWithDimension')]
    [Scope('OnPrem')]
    procedure VarifyTotalFilterWorkingWhenCreatingDirectDebitCollectionsWithDimension()
    var
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        DimensionValue: array[2] of Record "Dimension Value";
    begin
        // [SCENARIO 471033] Total filter is not work when Creating Direct Debit Collections
        Initialize();

        // [GIVEN] Setup: Create new Dimension Values
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        LibraryDimension.CreateDimensionValue(DimensionValue[2], LibraryERM.GetGlobalDimensionCode(1));

        // [THEN] Create new Bank Account, Customer, Invoice with Dimension Value 1, and Post Sales Invoice
        CreateSEPABankAccount(BankAccount);
        PostWorkdateSalesInvoiceSEPADirectDebitWithCurrencyAndDimension(
            Customer,
            WorkDate() - LibraryRandom.RandIntInRange(20, 30),
            WorkDate() + LibraryRandom.RandIntInRange(20, 30),
            Customer."Partner Type"::Company, '',
            1,
            DimensionValue[1].Code);

        // [WHEN] Run "Create Direct Debit Collection" report with expected error 'No entries have been created.'
        asserterror RunCreateDirectDebitCollectionReportWithDimensionFilter(
            WorkDate() - LibraryRandom.RandIntInRange(5, 10),
            WorkDate() + LibraryRandom.RandIntInRange(5, 10),
            Customer."Partner Type"::Company,
            BankAccount."No.",
            false,
            false,
            DimensionValue[2].Code);

        // [VERIFY] Verify: Expected error occurred during execution of "Create Direct Debit Collection" report
        Assert.ExpectedError(NoEntriesErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure CheckNoSeriesDataInGLEntryWhenDirectDebitCollectionCreateJournalOnlyTurnedOff()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        DirectDebitCollection: Record "Direct Debit Collection";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
    begin
        // [SCENARIO 560180] "Verify that the No. Series data in the GL entry is not blank when 'Create Journal Only' for Direct Debit Collection is turned off."
        Initialize();

        // [GIVEN] Create Direct Debit Collection Entry and Customer Ledger Entry.
        CreateDirectDebitCollectionEntry(DirectDebitCollection, DirectDebitCollectionEntry, CustLedgEntry, SEPADirectDebitMandate);

        // [GIVEN] Export the SEPA file.
        DirectDebitCollection.Export();

        // [GIVEN] Create Template and Batch.
        CreateGenJnlTemplateAndBatch(GenJnlTemplate, GenJnlBatch, CreateNoSeries());

        // [WHEN] Set CreateJnlOnly value false & Run Post Direct Collection Report.
        RunPostDirectDebitCollection(DirectDebitCollection, GenJnlTemplate.Name, GenJnlBatch.Name);

        // [THEN] Verify that the GL Entry No. Series field data is not blank.
        VerifyGLEntry(GenJnlTemplate.Name, GenJnlBatch.Name);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM SEPA Direct Debit Test");

        LibraryVariableStorage.Clear();
        Found := true;

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM SEPA Direct Debit Test");

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Link Doc. Date To Posting Date", true);
        PurchasesPayablesSetup.Modify();
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Link Doc. Date To Posting Date", true);
        SalesReceivablesSetup.Modify();
        LibraryERMCountryData.CreateVATData();
        CreateEURCurrencyExchRatePreviousYear();
        Commit();
        IsInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM SEPA Direct Debit Test");
    end;

    local procedure CreateCustomerWithBankAccount(var Customer: Record Customer; var CustomerBankAccount: Record "Customer Bank Account"; PaymentMethodCode: Code[10]; PartnerType: Enum "Partner Type")
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        CustomerBankAccount.IBAN := Format(LibraryRandom.RandIntInRange(11111111, 99999999));
        CustomerBankAccount."SWIFT Code" := Format(LibraryRandom.RandIntInRange(1111, 9999));
        CustomerBankAccount.Modify();
        Customer.Validate("Partner Type", PartnerType);
        Customer.Validate("Currency Code", LibraryERM.GetCurrencyCode('EUR'));
        Customer.Validate("Payment Method Code", PaymentMethodCode);
        Customer.Modify();
    end;

    local procedure CreateCustomerForSEPADD(var Customer: Record Customer)
    var
        PaymentMethod: Record "Payment Method";
        CustomerBankAccount: Record "Customer Bank Account";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
    begin
        CreateDirectDebitPaymentMethod(PaymentMethod);
        CreateCustomerWithBankAccount(Customer, CustomerBankAccount, PaymentMethod.Code, Customer."Partner Type"::Company);
        LibrarySales.CreateCustomerMandate(
          SEPADirectDebitMandate, CustomerBankAccount."Customer No.", CustomerBankAccount.Code,
          CalcDate('<-1Y>', LibraryERM.MinDate(WorkDate(), Today())), CalcDate('<1Y>', LibraryERM.MaxDate(WorkDate(), Today())));
    end;

    local procedure CreateDirectDebitPaymentMethod(var PaymentMethod: Record "Payment Method")
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Direct Debit", true);
        PaymentMethod.Validate("Direct Debit Pmt. Terms Code", PaymentTerms.Code);
        PaymentMethod.Modify();
    end;

    local procedure CreateSEPABankAccount(var BankAccount: Record "Bank Account")
    var
        NoSeries: Record "No. Series";
        BankExportImportSetup: Record "Bank Export/Import Setup";
    begin
        NoSeries.FindFirst();
        BankExportImportSetup.SetRange("Processing Codeunit ID", CODEUNIT::"SEPA DD-Export File");
        BankExportImportSetup.FindFirst();

        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount."Bank Account No." := Format(LibraryRandom.RandIntInRange(111, 999));
        BankAccount.IBAN := Format(LibraryRandom.RandIntInRange(11111111, 99999999));
        BankAccount."SWIFT Code" := Format(LibraryRandom.RandIntInRange(1111, 9999));
        BankAccount."Creditor No." := Format(LibraryRandom.RandIntInRange(11111111, 99999999));
        BankAccount."SEPA Direct Debit Exp. Format" := BankExportImportSetup.Code;
        BankAccount.Validate("Direct Debit Msg. Nos.", NoSeries.Code);
        BankAccount.Modify();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateDirectDebitCollectionHandler(var CreateDirectDebitCollection: TestRequestPage "Create Direct Debit Collection")
    var
        FromDate: Variant;
        ToDate: Variant;
        ValidCustMandate: Variant;
        ValidInvMandate: Variant;
        BankAccNo: Variant;
        PartnerType: Variant;
    begin
        LibraryVariableStorage.Dequeue(FromDate);
        LibraryVariableStorage.Dequeue(ToDate);
        LibraryVariableStorage.Dequeue(PartnerType);
        LibraryVariableStorage.Dequeue(ValidCustMandate);
        LibraryVariableStorage.Dequeue(ValidInvMandate);
        LibraryVariableStorage.Dequeue(BankAccNo);
        CreateDirectDebitCollection.FromDueDate.SetValue(FromDate);
        CreateDirectDebitCollection.ToDueDate.SetValue(ToDate);
        CreateDirectDebitCollection.PartnerType.SetValue(PartnerType);
        CreateDirectDebitCollection.OnlyCustomerValidMandate.SetValue(ValidCustMandate);
        CreateDirectDebitCollection.OnlyInvoiceValidMandate.SetValue(ValidInvMandate);
        CreateDirectDebitCollection.BankAccNo.SetValue(BankAccNo);
        CreateDirectDebitCollection.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CreateDirectDebitCollectionHandlerWithDimension(var CreateDirectDebitCollection: TestRequestPage "Create Direct Debit Collection")
    var
        FromDate: Variant;
        ToDate: Variant;
        ValidCustMandate: Variant;
        ValidInvMandate: Variant;
        BankAccNo: Variant;
        PartnerType: Variant;
        DimValCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(FromDate);
        LibraryVariableStorage.Dequeue(ToDate);
        LibraryVariableStorage.Dequeue(PartnerType);
        LibraryVariableStorage.Dequeue(ValidCustMandate);
        LibraryVariableStorage.Dequeue(ValidInvMandate);
        LibraryVariableStorage.Dequeue(BankAccNo);
        LibraryVariableStorage.Dequeue(DimValCode);
        CreateDirectDebitCollection.FromDueDate.SetValue(FromDate);
        CreateDirectDebitCollection.ToDueDate.SetValue(ToDate);
        CreateDirectDebitCollection.PartnerType.SetValue(PartnerType);
        CreateDirectDebitCollection.OnlyCustomerValidMandate.SetValue(ValidCustMandate);
        CreateDirectDebitCollection.OnlyInvoiceValidMandate.SetValue(ValidInvMandate);
        CreateDirectDebitCollection.BankAccNo.SetValue(BankAccNo);
        CreateDirectDebitCollection.Customer.SetFilter("Global Dimension 1 Filter", DimValCode);
        CreateDirectDebitCollection.OK().Invoke();
    end;

    local procedure CreateDDEntryWithTransferDate(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; TransferDate: Date)
    var
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        PostedDocNo: Code[20];
    begin
        CreateSEPABankAccount(BankAccount);
        CreateCustomerForSEPADD(Customer);
        PostedDocNo := CreateAndPostSalesInvoice(Customer."No.", TransferDate);
        SalesInvoiceHeader.Get(PostedDocNo);
        SalesInvoiceHeader.TestField("Due Date", TransferDate);

        RunCreateDirectDebitCollectionReport(
          TransferDate, TransferDate, Customer."Partner Type"::Company, BankAccount."No.", false, false);

        FindDDCollectionEntry(DirectDebitCollectionEntry, PostedDocNo);
        DirectDebitCollectionEntry.TestField("Transfer Date", TransferDate);
    end;

    local procedure CreateTwoDDEntriesWithTransferDate(var DirectDebitCollectionNo: Integer; var DirectDebitCollectionEntryNo: array[2] of Integer; TransferDate: Date)
    var
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
        PostedDocNo1: Code[20];
        PostedDocNo2: Code[20];
    begin
        CreateSEPABankAccount(BankAccount);
        CreateCustomerForSEPADD(Customer);
        PostedDocNo1 := CreateAndPostSalesInvoice(Customer."No.", TransferDate);
        PostedDocNo2 := CreateAndPostSalesInvoice(Customer."No.", TransferDate);

        RunCreateDirectDebitCollectionReport(
            TransferDate, TransferDate, Customer."Partner Type"::Company, BankAccount."No.", false, false);

        FindDDCollectionEntry(DirectDebitCollectionEntry, PostedDocNo1);
        DirectDebitCollectionNo := DirectDebitCollectionEntry."Direct Debit Collection No.";
        DirectDebitCollectionEntryNo[1] := DirectDebitCollectionEntry."Entry No.";

        FindDDCollectionEntry(DirectDebitCollectionEntry, PostedDocNo2);
        DirectDebitCollectionEntryNo[2] := DirectDebitCollectionEntry."Entry No.";
    end;

    local procedure CreateAndPostSalesInvoice(CustomerNo: Code[20]; PostingDate: Date): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);

        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInRange(100, 200, 2), LibraryRandom.RandDecInRange(100, 200, 2));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));

        exit(LibrarySales.PostSalesDocument(SalesHeader, false, true));
    end;

    local procedure CreateEURCurrencyExchRatePreviousYear()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // create EUR Currency Exch Rate for the previous year to avoid test failure in the very beginning of a year
        if LibraryERM.GetCurrencyCode('EUR') <> '' then begin   // there is no EUR exchange rate in some countries like DE
            CurrencyExchangeRate.SetRange("Currency Code", LibraryERM.GetCurrencyCode('EUR'));
            CurrencyExchangeRate.FindFirst();
            CurrencyExchangeRate.Validate("Starting Date", CalcDate('<-1Y>', CurrencyExchangeRate."Starting Date"));
            CurrencyExchangeRate.Insert(true);
        end;
    end;

    local procedure EnqueueRequestPage(FromDate: Date; ToDate: Date; PartnerType: Enum "Partner Type"; BankAccNo: Code[20]; ValidCustMandate: Boolean; ValidInvMandate: Boolean)
    begin
        LibraryVariableStorage.Enqueue(FromDate);
        LibraryVariableStorage.Enqueue(ToDate);
        LibraryVariableStorage.Enqueue(PartnerType);
        LibraryVariableStorage.Enqueue(ValidCustMandate);
        LibraryVariableStorage.Enqueue(ValidInvMandate);
        LibraryVariableStorage.Enqueue(BankAccNo);
    end;

    local procedure ExportToServerTempFile(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry")
    var
        FileManagement: Codeunit "File Management";
        ExportFile: File;
        OutStream: OutStream;
    begin
        ServerFileName := FileManagement.ServerTempFileName('.xml');
        ExportFile.WriteMode := true;
        ExportFile.TextMode := true;
        ExportFile.Create(ServerFileName);
        ExportFile.CreateOutStream(OutStream);
        XMLPORT.Export(XMLPORT::"SEPA DD pain.008.001.02", OutStream, DirectDebitCollectionEntry);
        ExportFile.Close();
    end;

    local procedure FindDDCollectionEntry(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; PostedDocumentNo: Code[20])
    begin
        DirectDebitCollectionEntry.SetRange("Applies-to Entry Document No.", PostedDocumentNo);
        DirectDebitCollectionEntry.FindFirst();
    end;

    local procedure FindFirstErrorOnDDEntry(var PmtJnlExportErrorText: Record "Payment Jnl. Export Error Text"; DirectDebitCollectionEntry: Record "Direct Debit Collection Entry")
    begin
        PmtJnlExportErrorText.SetRange("Document No.", Format(DirectDebitCollectionEntry."Direct Debit Collection No."));
        PmtJnlExportErrorText.SetRange("Journal Line No.", DirectDebitCollectionEntry."Entry No.");
        PmtJnlExportErrorText.FindFirst();
    end;

    local procedure PostWorkdateSalesInvoiceSEPADirectDebit(var Customer: Record Customer; MandateFromDate: Date; MandateToDate: Date; Partnertype: Enum "Partner Type"): Code[20]
    begin
        exit(PostWorkdateSalesInvoiceSEPADirectDebitWithCurrency(Customer, MandateFromDate, MandateToDate, Partnertype, ''));
    end;

    local procedure PostWorkdateSalesInvoiceSEPADirectDebitWithCurrency(var Customer: Record Customer; MandateFromDate: Date; MandateToDate: Date; PartnerType: Enum "Partner Type"; CurrencyCode: Code[10]): Code[20]
    var
        CustomerBankAccount: Record "Customer Bank Account";
        PaymentMethod: Record "Payment Method";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        CreateDirectDebitPaymentMethod(PaymentMethod);
        CreateCustomerWithBankAccount(Customer, CustomerBankAccount, PaymentMethod.Code, PartnerType);
        LibrarySales.CreateCustomerMandate(SEPADirectDebitMandate, CustomerBankAccount."Customer No.",
          CustomerBankAccount.Code, MandateFromDate, MandateToDate);
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 2);
        SalesLine.Validate("Currency Code", CurrencyCode);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, true));
    end;

    local procedure PostTwoWorkdateSalesInvoicesSEPADirectDebit(var Customer: Record Customer; var Customer2: Record Customer; var PostedDocNo: Code[20]; var PostedDocNo2: Code[20])
    begin
        PostedDocNo :=
          PostWorkdateSalesInvoiceSEPADirectDebit(Customer, WorkDate() - 30, WorkDate() - 30, Customer."Partner Type"::Company);
        PostedDocNo2 :=
          PostWorkdateSalesInvoiceSEPADirectDebit(Customer2, WorkDate() - 30, WorkDate() + 30, Customer."Partner Type"::Company);
    end;

    local procedure RunCreateDirectDebitCollectionReport(FromDate: Date; ToDate: Date; PartnerType: Enum "Partner Type"; BankAccNo: Code[20]; ValidCustMandate: Boolean; ValidInvMandate: Boolean)
    begin
        EnqueueRequestPage(FromDate, ToDate, PartnerType, BankAccNo, ValidCustMandate, ValidInvMandate);
        Commit();
        REPORT.Run(REPORT::"Create Direct Debit Collection");
    end;

    local procedure UpdateStatusOnDDCollectionEntry(var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; StatusValue: Option)
    begin
        DirectDebitCollectionEntry.Status := StatusValue;
        DirectDebitCollectionEntry.Modify();
    end;

    local procedure VerifyDirectDebitMandateID(CustomerNo: Code[20]; DocumentNo: Code[20]; MandateIsFound: Boolean)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
    begin
        SEPADirectDebitMandate.SetRange("Customer No.", CustomerNo);
        SEPADirectDebitMandate.FindFirst();

        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.SetRange("Direct Debit Mandate ID", SEPADirectDebitMandate.ID);
        Assert.AreEqual(MandateIsFound, not CustLedgerEntry.IsEmpty, StrSubstNo(EntryCountErr, CustLedgerEntry.TableCaption()));
    end;

    local procedure VerifyDirectDebitCollectionEntryCount(DocNo: Code[20]; ExpectedCount: Integer)
    var
        DirectDebitCollectionEntry: Record "Direct Debit Collection Entry";
    begin
        DirectDebitCollectionEntry.SetRange("Applies-to Entry Document No.", DocNo);
        Assert.AreEqual(ExpectedCount, DirectDebitCollectionEntry.Count,
          StrSubstNo(EntryCountErr, DirectDebitCollectionEntry.TableCaption()));
    end;

    local procedure VerifyTwoSalesInvoiceValidMandate(CustomerNo1: Code[20]; PostedDocNo1: Code[20]; CustomerNo2: Code[20]; PostedDocNo2: Code[20])
    begin
        VerifyDirectDebitMandateID(CustomerNo1, PostedDocNo1, not Found);
        VerifyDirectDebitCollectionEntryCount(PostedDocNo1, 0);

        VerifyDirectDebitMandateID(CustomerNo2, PostedDocNo2, Found);
        VerifyDirectDebitCollectionEntryCount(PostedDocNo2, 1);
    end;

    local procedure VerifyTransferDateErrorOnDDEntry(DirectDebitCollectionEntry: Record "Direct Debit Collection Entry")
    var
        PmtJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        FindFirstErrorOnDDEntry(PmtJnlExportErrorText, DirectDebitCollectionEntry);
        Assert.ExpectedMessage('The earliest possible transfer date is today.', PmtJnlExportErrorText."Error Text");
        Assert.ExpectedMessage(
          'You can use the Reset Transfer Date action to eliminate the error.', PmtJnlExportErrorText."Additional Information");
    end;

    local procedure VerifyNoErrorsOnDDEntry(DirectDebitCollectionEntry: Record "Direct Debit Collection Entry")
    var
        PmtJnlExportErrorText: Record "Payment Jnl. Export Error Text";
    begin
        PmtJnlExportErrorText.SetRange("Document No.", Format(DirectDebitCollectionEntry."Direct Debit Collection No."));
        PmtJnlExportErrorText.SetRange("Journal Line No.", DirectDebitCollectionEntry."Entry No.");
        Assert.RecordIsEmpty(PmtJnlExportErrorText);
    end;

    local procedure PostWorkdateSalesInvoiceSEPADirectDebitWithCurrencyAndDimension(
        var Customer: Record Customer;
        MandateFromDate: Date;
        MandateToDate: Date;
        PartnerType: Enum "Partner Type";
                         CurrencyCode: Code[10];
                         DimSetID: Integer;
                         DimValCode: Code[20]): Code[20]
    var
        CustomerBankAccount: Record "Customer Bank Account";
        PaymentMethod: Record "Payment Method";
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        // Create Payment Method with Direct Debit, create Customer with Bank Account
        CreateDirectDebitPaymentMethod(PaymentMethod);
        CreateCustomerWithBankAccount(Customer, CustomerBankAccount, PaymentMethod.Code, PartnerType);
        Customer.Validate("Global Dimension 1 Code", DimValCode);
        Customer.Modify(true);

        // Create "SEPA Direct Debit Mandate" for the Customer Bank Account
        LibrarySales.CreateCustomerMandate(
            SEPADirectDebitMandate,
            CustomerBankAccount."Customer No.",
            CustomerBankAccount.Code,
            MandateFromDate,
            MandateToDate);

        // Create Sales Invoice
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Dimension Set ID", DimSetID);
        SalesHeader.Validate("Shortcut Dimension 1 Code", DimValCode);
        SalesHeader.Modify();

        // Create Item, sales Line, and post sales invoice
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 2);
        SalesLine.Validate("Currency Code", CurrencyCode);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);

        exit(LibrarySales.PostSalesDocument(SalesHeader, false, true));
    end;

    local procedure RunCreateDirectDebitCollectionReportWithDimensionFilter(FromDate: Date; ToDate: Date; PartnerType: Enum "Partner Type"; BankAccNo: Code[20]; ValidCustMandate: Boolean; ValidInvMandate: Boolean; DimValCode: Code[20])
    begin
        EnqueueRequestPage(FromDate, ToDate, PartnerType, BankAccNo, ValidCustMandate, ValidInvMandate);
        LibraryVariableStorage.Enqueue(DimValCode);
        Commit();
        Report.Run(Report::"Create Direct Debit Collection");
    end;

    local procedure CreateDirectDebitCollectionEntry(var DirectDebitCollection: Record "Direct Debit Collection"; var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var CustLedgEntry: Record "Cust. Ledger Entry"; var SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate")
    begin
        CreateDirectDebitCollectionEntryWithCurrency(
            DirectDebitCollection,
            DirectDebitCollectionEntry,
            CustLedgEntry,
            SEPADirectDebitMandate,
            LibraryERM.GetCurrencyCode('EUR'));
    end;

    local procedure CreateDirectDebitCollectionEntryWithCurrency(var DirectDebitCollection: Record "Direct Debit Collection"; var DirectDebitCollectionEntry: Record "Direct Debit Collection Entry"; var CustLedgEntry: Record "Cust. Ledger Entry"; var SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate"; CurrencyCode: Code[10])
    var
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        LibrarySales.CreateCustomer(Customer);

        LibrarySales.CreateCustomerBankAccount(CustomerBankAccount, Customer."No.");
        CustomerBankAccount.Validate(IBAN, Format(LibraryRandom.RandIntInRange(11111111, 99999999)));
        CustomerBankAccount.Validate("SWIFT Code", Format(LibraryRandom.RandIntInRange(1111, 9999)));
        CustomerBankAccount.Modify(true);

        Customer.Validate("Preferred Bank Account Code", CustomerBankAccount.Code);
        Customer.Validate("Partner Type", Customer."Partner Type"::Company);
        Customer.Modify(true);
        LibrarySales.CreateCustomerMandate(SEPADirectDebitMandate, Customer."No.", CustomerBankAccount.Code, Today(), WorkDate());

        PostSalesInvoice(Customer, SEPADirectDebitMandate.ID, CurrencyCode);

        CreateSEPABankAccount(BankAccount);
        BankAccount.Validate("Direct Debit Msg. Nos.", CreateNoSeries());
        BankAccount.Modify(true);
        if DirectDebitCollection."No." = 0 then
            DirectDebitCollection.CreateRecord(BankAccount.GetDirectDebitMessageNo(), BankAccount."No.", Customer."Partner Type");
        DirectDebitCollectionEntry.SetRange("Direct Debit Collection No.", DirectDebitCollection."No.");

        CustLedgEntry.FindLast();
        DirectDebitCollectionEntry.CreateNew(DirectDebitCollection."No.", CustLedgEntry);
        DirectDebitCollectionEntry.Modify(true);
    end;

    local procedure PostSalesInvoice(var Customer: Record Customer; DirectDebitMandateID: Code[35]; CurrencyCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.");
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Validate("Direct Debit Mandate ID", DirectDebitMandateID);
        SalesHeader.Modify(true);

        LibrarySales.PostSalesDocument(SalesHeader, false, true);
    end;

    local procedure CreateNoSeries(): Code[20]
    var
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
    begin
        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');

        exit(NoSeries.Code);
    end;

    local procedure CreateGenJnlTemplateAndBatch(var GenJnlTemplate: Record "Gen. Journal Template"; var GenJnlBatch: Record "Gen. Journal Batch"; NoSeriesCode: Code[20])
    begin
        LibraryERM.CreateGenJournalTemplate(GenJnlTemplate);
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        GenJnlBatch.Validate("No. Series", NoSeriesCode);
        GenJnlBatch.Modify(true);
    end;

    local procedure RunPostDirectDebitCollection(DirectDebitCollection: Record "Direct Debit Collection"; JnlTemplateName: Code[10]; JnlBatchName: Code[10])
    var
        PostDirectDebitCollection: Report "Post Direct Debit Collection";
    begin
        PostDirectDebitCollection.SetCollectionEntry(DirectDebitCollection."No.");
        PostDirectDebitCollection.SetJnlBatch(JnlTemplateName, JnlBatchName);
        PostDirectDebitCollection.SetCreateJnlOnly(false);

        Commit();
        PostDirectDebitCollection.Run();
    end;

    local procedure VerifyGLEntry(JnlTemplateName: Code[10]; JnlBatchName: Code[10])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Journal Templ. Name", JnlTemplateName);
        GLEntry.SetRange("Journal Batch Name", JnlBatchName);
        GLEntry.FindSet();
        repeat
            GLEntry.TestField("No. Series");
        until GLEntry.Next() = 0;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Dummy message handler.
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ResetTransferDateConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage('Do you want to insert today''s date in the Transfer Date field on all overdue entries?', Question);
        Reply := true;
    end;
}

