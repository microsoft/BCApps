codeunit 147530 "Cartera Recv. Basic Scenarios"
{
    // // [FEATURE] [Cartera] [Sales]
    // Cartera Receivables Basic Scenarios

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryCarteraCommon: Codeunit "Library - Cartera Common";
        LibraryCarteraReceivables: Codeunit "Library - Cartera Receivables";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryInventory: Codeunit "Library - Inventory";
        RecordNotFoundErr: Label '%1 was not found.', Comment = '%1=TableCaption';
        BillGroupNotPrintedMsg: Label 'This %1 has not been printed. Do you want to continue?';
        SettlementCompletedSuccessfullyMsg: Label '%1 receivable documents totaling %2 have been settled.';
        SuccessfulPostingForFactoringCollectionMsg: Label 'Bank Bill Group %1 was successfully posted for factoring collection.';
        SuccessfulDocumentRejectMsg: Label '%1 documents have been rejected.';
        CustomerNoElementNameTxt: Label 'Cust__Ledger_Entry__Customer_No__';
        RemainingAmountElementNameTxt: Label 'Cust__Ledger_Entry__Remaining_Amount_';
        PaymentMethodCodeModifyErr: Label 'For Cartera-based bills and invoices, you cannot change the Payment Method Code to this value.';
        CheckBillSituationGroupErr: Label '%1 cannot be applied because it is included in a bill group. To apply the document, remove it from the bill group and try again.', Comment = '%1 - document type and number';
        CheckBillSituationPostedErr: Label '%1 cannot be applied because it is included in a posted bill group.', Comment = '%1 - document type and number';
        PostDocumentAppliedToBillInGroupErr: Label 'A grouped document cannot be settled from a journal.\Remove Document %1/1 from Group/Pmt. Order %2 and try again.';
        DoYouWantToKeepExistingDimensionsQst: Label 'This will change the dimension specified on the document. Do you want to recalculate/update dimensions?';
        CarterDocExistErr: Label 'Carter Document Exists';
        DirectDebitMandateIDErr: Label 'The direct debit mandate should be the same.';
        CustVendorBankAccountErr: Label 'The customer bank account should be the same.';

    [Test]
    [Scope('OnPrem')]
    procedure CreateCarteraDocument()
    var
        CarteraDoc: Record "Cartera Doc.";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        Initialize();

        // Setup
        DocumentNo := PostCarteraSalesInvoice(SalesHeader, '');

        // Verify
        CarteraDoc.SetRange("Document No.", DocumentNo);
        CarteraDoc.SetRange("Account No.", SalesHeader."Sell-to Customer No.");
        Assert.IsFalse(CarteraDoc.IsEmpty, StrSubstNo(RecordNotFoundErr, CarteraDoc.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostBillGroupLCY()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        CarteraDoc: Record "Cartera Doc.";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PostedBillGroup: Record "Posted Bill Group";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        Initialize();

        // Pre-Setup
        DocumentNo := PostCarteraSalesInvoice(SalesHeader, '');

        // Setup
        LibraryCarteraReceivables.CreateBankAccount(BankAccount, '');
        LibraryCarteraReceivables.UpdateBankAccountWithFormatN19(BankAccount);
        LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccount."No.", BillGroup."Dealing Type"::Collection);
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(
          CarteraDoc, DocumentNo, SalesHeader."Sell-to Customer No.", BillGroup."No.");

        // Exercise
        LibraryVariableStorage.Enqueue(StrSubstNo(BillGroupNotPrintedMsg, BillGroup.TableCaption()));
        LibraryCarteraReceivables.PostCarteraBillGroup(BillGroup);

        // Pre-Verify
        LibraryCarteraReceivables.FindOpenCarteraDocCustomerLedgerEntries(
          CustLedgerEntry, SalesHeader."Sell-to Customer No.", DocumentNo, CustLedgerEntry."Document Situation"::"Posted BG/PO",
          CustLedgerEntry."Document Type"::Bill);

        // Verify
        PostedBillGroup.SetRange("Bank Account No.", BankAccount."No.");
        PostedBillGroup.FindLast();
        Assert.AreEqual(CustLedgerEntry.Amount, PostedBillGroup.Amount, '')
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountSelectionPageHandler,ConfirmHandlerYes')]
    [Scope('OnPrem')]
    procedure PostBillGroupNonLCY()
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
        CarteraDoc: Record "Cartera Doc.";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PostedBillGroup: Record "Posted Bill Group";
        SalesHeader: Record "Sales Header";
        BillGroupNo: Code[20];
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
    begin
        Initialize();

        // Pre-Setup
        CurrencyCode := LibraryCarteraCommon.CreateCarteraCurrency(true, false, false);
        DocumentNo := PostCarteraSalesInvoice(SalesHeader, CurrencyCode);
        // Setup
        LibraryCarteraReceivables.CreateBankAccount(BankAccount, CurrencyCode);
        LibraryCarteraReceivables.UpdateBankAccountWithFormatN19(BankAccount);
        BillGroupNo := CreateBillGroup(CurrencyCode, BankAccount."No.", BillGroup."Dealing Type"::Collection);
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(
          CarteraDoc, DocumentNo, SalesHeader."Sell-to Customer No.", BillGroupNo);

        // Exercise
        LibraryVariableStorage.Enqueue(StrSubstNo(BillGroupNotPrintedMsg, BillGroup.TableCaption()));
        PostBillGroup(BillGroupNo);

        // Pre-Verify
        LibraryCarteraReceivables.FindOpenCarteraDocCustomerLedgerEntries(
          CustLedgerEntry, SalesHeader."Sell-to Customer No.", DocumentNo, CustLedgerEntry."Document Situation"::"Posted BG/PO",
          CustLedgerEntry."Document Type"::Bill);

        // Verify
        PostedBillGroup.SetRange("Bank Account No.", BankAccount."No.");
        PostedBillGroup.FindLast();
        Assert.AreEqual(CurrencyCode, PostedBillGroup."Currency Code", '');
        Assert.AreEqual(CustLedgerEntry.Amount, PostedBillGroup.Amount, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentMethodCodeModificationCreateBills()
    var
        Customer: Record Customer;
        PaymentMethod: Record "Payment Method";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
        BillNo: Code[20];
    begin
        // [SCENARIO 384336] Payment Method is updated for Invoice Cartera Document
        Initialize();

        // [GIVEN] Customer with Cartera Payment Method "P1" where Invoice to Cartera = Yes
        LibraryCarteraReceivables.CreateSalesInvoiceWithCustBankAcc(SalesHeader, Customer, '');

        // [GIVEN] Cartera Document is posted for the Customer
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Cartera Payment Method "P2" with Invoice to Cartera = No
        LibraryCarteraCommon.CreatePaymentMethod(PaymentMethod, true, false);

        // [WHEN] Modify Payment Method Code to "P2"
        BillNo := UpdateCustLedgEntryPaymentCode(DocumentNo, Customer."No.", PaymentMethod.Code, true);

        // [THEN] Cartera Document has Payment Method = "P2"
        VerifyCarteraDocPaymentMethod(DocumentNo, Customer."No.", PaymentMethod.Code, BillNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentMethodCodeModification()
    var
        Customer: Record Customer;
        PaymentMethod: Record "Payment Method";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 384336] Payment Method is not updated for Invoice Cartera Document
        Initialize();

        // [GIVEN] Customer with Cartera Payment Method "P1" where Invoice to Cartera = Yes
        LibraryCarteraReceivables.CreateSalesInvoiceWithCustBankAcc(SalesHeader, Customer, '');

        // [GIVEN] Cartera Document is posted for the Customer
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Cartera Payment Method with Invoice to Cartera = Yes
        LibraryCarteraCommon.CreatePaymentMethod(PaymentMethod, false, false);

        // [WHEN] Modify Payment Method Code to "P2"
        asserterror UpdateCustLedgEntryPaymentCode(DocumentNo, Customer."No.", PaymentMethod.Code, true);

        // [THEN] Error appears
        Assert.ExpectedError(PaymentMethodCodeModifyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtMethodCodeModificationInvoicesToCartera()
    var
        Customer: Record Customer;
        PaymentMethod: Record "Payment Method";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 384336] Payment Method is not updated for Invoice Cartera Document
        Initialize();

        // [GIVEN] Customer with Cartera Payment Method "P1" where Create Bills = No
        LibraryCarteraCommon.CreatePaymentMethod(PaymentMethod, false, true);
        LibraryCarteraReceivables.CreateCustomer(Customer, '', PaymentMethod.Code);

        // [GIVEN] Cartera Document is posted for the Customer
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Cartera Payment Method "P2"
        LibraryCarteraCommon.CreatePaymentMethod(PaymentMethod, false, false);

        // [WHEN] Modify Payment Method Code to "P2".
        asserterror UpdateCustLedgEntryPaymentCode(DocumentNo, Customer."No.", PaymentMethod.Code, false);

        // [THEN] Error apprears
        Assert.ExpectedError(PaymentMethodCodeModifyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtMethodCodeModificationInvoicesToCarteraInvoice()
    var
        Customer: Record Customer;
        PaymentMethod: Record "Payment Method";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 384336] Payment Method is updated for Invoice Cartera Document
        Initialize();

        // [GIVEN] Customer with Cartera Payment Method "P1" where Create Bills = No
        LibraryCarteraCommon.CreatePaymentMethod(PaymentMethod, false, true);
        LibraryCarteraReceivables.CreateCustomer(Customer, '', PaymentMethod.Code);

        // [GIVEN] Cartera Document is posted for the Customer
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Cartera Payment Method "P2"
        LibraryCarteraCommon.CreatePaymentMethod(PaymentMethod, false, true);

        // [WHEN] Modify Payment Method Code to "P2".
        UpdateCustLedgEntryPaymentCode(DocumentNo, Customer."No.", PaymentMethod.Code, false);

        // [THEN] Cartera Document has Payment Method = "P2"
        VerifyCarteraDocInvoicePaymentMethod(DocumentNo, Customer."No.", PaymentMethod.Code);
    end;

    [Test]
    [HandlerFunctions('InsertDocModelHandler,ConfirmHandlerYes,SettleDocsInPostedBillGroupsRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostAndCloseBillGroupEndToEndLCY()
    var
        BillGroup: Record "Bill Group";
        SalesHeader: Record "Sales Header";
        PostedBillGroup: Record "Posted Bill Group";
        DocumentNo: Code[20];
    begin
        Initialize();
        DocumentNo := PostCarteraSalesInvoice(SalesHeader, '');
        CreateBillGroupLCY(BillGroup);

        LibraryVariableStorage.Enqueue(DocumentNo);
        AddCarteraDocumentToBillGroup(BillGroup."No.");

        LibraryVariableStorage.Enqueue(StrSubstNo(BillGroupNotPrintedMsg, BillGroup.TableCaption()));
        LibraryCarteraReceivables.PostCarteraBillGroup(BillGroup);

        SettleDocsInPostBillGrPage(PostedBillGroup, BillGroup."No.");

        asserterror PostedBillGroup.FindFirst();
        Assert.AssertNothingInsideFilter();
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountSelectionPageHandler,InsertDocModelHandler,ConfirmHandlerYes,SettleDocsInPostedBillGroupsRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostAndCloseBillGroupEndToEndNonLCY()
    var
        BillGroup: Record "Bill Group";
        SalesHeader: Record "Sales Header";
        PostedBillGroup: Record "Posted Bill Group";
        BillGroupNo: Code[20];
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
    begin
        Initialize();

        CurrencyCode := LibraryCarteraCommon.CreateCarteraCurrency(true, false, false);
        DocumentNo := PostCarteraSalesInvoice(SalesHeader, CurrencyCode);
        BillGroupNo := CreateBillGroupFCY(CurrencyCode);

        LibraryVariableStorage.Enqueue(DocumentNo);
        AddCarteraDocumentToBillGroup(BillGroupNo);

        LibraryVariableStorage.Enqueue(StrSubstNo(BillGroupNotPrintedMsg, BillGroup.TableCaption()));
        PostBillGroup(BillGroupNo);

        SettleDocsInPostBillGrPage(PostedBillGroup, BillGroupNo);

        asserterror PostedBillGroup.FindFirst();
        Assert.AssertNothingInsideFilter();
    end;

    [Test]
    [HandlerFunctions('InsertDocModelHandler,ConfirmHandlerYes,SettleDocsInPostedBillGroupsRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostAndCloseBillGroupEndToEndLCYFromList()
    var
        BillGroup: Record "Bill Group";
        SalesHeader: Record "Sales Header";
        PostedBillGroup: Record "Posted Bill Group";
        DocumentNo: Code[20];
    begin
        Initialize();
        DocumentNo := PostCarteraSalesInvoice(SalesHeader, '');
        CreateBillGroupLCY(BillGroup);

        LibraryVariableStorage.Enqueue(DocumentNo);
        AddCarteraDocumentToBillGroup(BillGroup."No.");

        LibraryVariableStorage.Enqueue(StrSubstNo(BillGroupNotPrintedMsg, BillGroup.TableCaption()));
        PostBillGroupFromList(BillGroup."No.");

        SettleDocsInPostBillGrPage(PostedBillGroup, BillGroup."No.");

        asserterror PostedBillGroup.FindFirst();
        Assert.AssertNothingInsideFilter();
    end;

    [Test]
    [HandlerFunctions('InsertDocModelHandler,ConfirmHandlerYes,MessageHandler,ConfirmRejectingInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RejectItemFromPostedBillGroupLCY()
    var
        CustomerBankAccount: Record "Customer Bank Account";
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        PaymentMethod: Record "Payment Method";
        PostedBillGroup: Record "Posted Bill Group";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        Initialize();

        LibraryCarteraReceivables.CreateCarteraCustomer(Customer, '');

        PaymentMethod.SetRange(Code, Customer."Payment Method Code");
        PaymentMethod.FindFirst();

        LibraryCarteraReceivables.CreateCustomerBankAccount(Customer, CustomerBankAccount);
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CreateBillGroupLCY(BillGroup);
        BillGroup.Validate(Factoring, BillGroup.Factoring::Risked);
        BillGroup.Modify(true);

        LibraryVariableStorage.Enqueue(DocumentNo);
        AddCarteraDocumentToBillGroup(BillGroup."No.");

        LibraryVariableStorage.Enqueue(StrSubstNo(BillGroupNotPrintedMsg, BillGroup.TableCaption()));
        LibraryVariableStorage.Enqueue(StrSubstNo(SuccessfulPostingForFactoringCollectionMsg, BillGroup."No."));
        LibraryCarteraReceivables.PostCarteraBillGroup(BillGroup);

        RejectDocsInPostBillGrPage(PostedBillGroup, BillGroup."No.");

        asserterror PostedBillGroup.FindFirst();
        Assert.AssertNothingInsideFilter();

        VerifyClosedCarteraDocStatus(BillGroup."No.", DocumentNo);
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountSelectionPageHandler,InsertDocModelHandler,ConfirmHandlerYes,MessageHandler,ConfirmRejectingInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RejectItemFromPostedBillGroupNonLCY()
    var
        CustomerBankAccount: Record "Customer Bank Account";
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        PaymentMethod: Record "Payment Method";
        PostedBillGroup: Record "Posted Bill Group";
        SalesHeader: Record "Sales Header";
        BillGroupNo: Code[20];
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
    begin
        Initialize();

        CurrencyCode := LibraryCarteraCommon.CreateCarteraCurrency(true, false, false);
        LibraryCarteraReceivables.CreateCarteraCustomer(Customer, CurrencyCode);

        PaymentMethod.SetRange(Code, Customer."Payment Method Code");
        PaymentMethod.FindFirst();

        LibraryCarteraReceivables.CreateCustomerBankAccount(Customer, CustomerBankAccount);
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        BillGroupNo := CreateBillGroupFCY(CurrencyCode);
        BillGroup.Get(BillGroupNo);
        BillGroup.Validate(Factoring, BillGroup.Factoring::Risked);
        BillGroup.Modify(true);

        LibraryVariableStorage.Enqueue(DocumentNo);
        AddCarteraDocumentToBillGroup(BillGroupNo);

        LibraryVariableStorage.Enqueue(StrSubstNo(BillGroupNotPrintedMsg, BillGroup.TableCaption()));
        LibraryVariableStorage.Enqueue(StrSubstNo(SuccessfulPostingForFactoringCollectionMsg, BillGroupNo));
        PostBillGroup(BillGroupNo);

        RejectDocsInPostBillGrPage(PostedBillGroup, BillGroup."No.");

        asserterror PostedBillGroup.FindFirst();
        Assert.AssertNothingInsideFilter();

        VerifyClosedCarteraDocStatus(BillGroup."No.", DocumentNo);
    end;

    [Test]
    [HandlerFunctions('InsertDocModelHandler,ConfirmHandlerYes,SettleDocsInPostedBillGroupsRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure TestRemovingTheDocumentFromBillGroup()
    var
        BillGroup: Record "Bill Group";
        SalesHeader: Record "Sales Header";
        PostedBillGroup: Record "Posted Bill Group";
        DocumentNo: Code[20];
    begin
        Initialize();
        DocumentNo := PostCarteraSalesInvoice(SalesHeader, '');
        CreateBillGroupLCY(BillGroup);

        LibraryVariableStorage.Enqueue(DocumentNo);
        AddCarteraDocumentToBillGroup(BillGroup."No.");

        // Excercise
        RemoveCarteraDocumentFromBillGroup(BillGroup."No.");

        // Verify
        VerifyCarteraDocumentRemovedFromBillGroup(BillGroup."No.");

        // Verify - Add same row again and test that you can post
        LibraryVariableStorage.Enqueue(DocumentNo);
        AddCarteraDocumentToBillGroup(BillGroup."No.");
        LibraryVariableStorage.Enqueue(StrSubstNo(BillGroupNotPrintedMsg, BillGroup.TableCaption()));
        PostBillGroupFromList(BillGroup."No.");

        SettleDocsInPostBillGrPage(PostedBillGroup, BillGroup."No.");

        asserterror PostedBillGroup.FindFirst();
        Assert.AssertNothingInsideFilter();
    end;

    [Test]
    [HandlerFunctions('CustomerDueRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerDuePaymentsInvoice()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // Setup
        Initialize();

        LibrarySales.CreateCustomer(Customer);
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise
        CustLedgerEntry.SetRange("Due Date", SalesHeader."Due Date");
        REPORT.Run(REPORT::"Customer - Due Payments", true, false, CustLedgerEntry);

        // Verify
        VerifyReportData(Customer);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,CustomerDueRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CustomerDuePaymentsBill()
    var
        BillGroup: Record "Bill Group";
        CarteraDoc: Record "Cartera Doc.";
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeader: Record "Sales Header";
        DocumentNo: Code[20];
    begin
        // Setup
        Initialize();
        DocumentNo := PostCarteraSalesInvoice(SalesHeader, '');

        CreateBillGroupLCY(BillGroup);
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(
          CarteraDoc, DocumentNo, SalesHeader."Sell-to Customer No.", BillGroup."No.");

        LibraryVariableStorage.Enqueue(StrSubstNo(BillGroupNotPrintedMsg, BillGroup.TableCaption()));
        LibraryCarteraReceivables.PostCarteraBillGroup(BillGroup);

        // Exercise
        CustLedgerEntry.SetRange("Due Date", SalesHeader."Due Date");
        REPORT.Run(REPORT::"Customer - Due Payments", true, false, CustLedgerEntry);

        // Verify
        Customer.Get(SalesHeader."Sell-to Customer No.");
        VerifyReportData(Customer);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,PaymentRegistrationSetupMPH')]
    [Scope('OnPrem')]
    procedure PostPaymentFromPaymentRegistrationPage()
    var
        BillGroup: Record "Bill Group";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DocumentNo: Code[20];
        AmountToPost: Decimal;
    begin
        // [FEATURE] [Bill Group] [Payment Registration]
        // [SCENARIO 364423] Customer Bill's Ledger Entry "Remaining Amount" is deducted after post payment from "Payment Registration" page
        Initialize();

        // [GIVEN] Create and post Sales Invoice with "X" amount. Create Bill.
        DocumentNo := PostCarteraSalesInvoice(SalesHeader, '');
        CreateBillGroupLCY(BillGroup);

        // [GIVEN] Open "Payment Registration" page. Navigate created Bill. Set "Amount Received" = "Y" ("Y" < "X")
        LibraryCarteraReceivables.FindOpenCarteraDocCustomerLedgerEntries(
          CustLedgerEntry, SalesHeader."Bill-to Customer No.", DocumentNo,
          CustLedgerEntry."Document Situation"::Cartera, CustLedgerEntry."Document Type"::Bill);
        CustLedgerEntry.CalcFields(Amount);
        AmountToPost := Round(CustLedgerEntry.Amount * LibraryRandom.RandDec(1, 2));

        // [WHEN] Invoke "Post Payment" action
        RunPostPaymentFromPaymentRegistrationPage(SalesHeader."Bill-to Customer No.", DocumentNo, AmountToPost);

        // [THEN] Customer Bill's Ledger Entry "Remaining Amount" = "X" - "Y"
        CustLedgerEntry.CalcFields("Remaining Amount");
        Assert.AreEqual(
          CustLedgerEntry.Amount - AmountToPost,
          CustLedgerEntry."Remaining Amount",
          CustLedgerEntry.FieldCaption("Remaining Amount"));
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountSelectionPageHandler,ConfirmHandler,InsertDocModelHandler')]
    [Scope('OnPrem')]
    procedure PostPaymentOrderPurchInvCurrencyFactorModified()
    var
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Currency: Record Currency;
        CustomerBankAccount: Record "Customer Bank Account";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Bill Group] [Currency]
        // [SCENARIO 374792] Post Bill Group for Sales Invoice with FCY and modified Currency Factor
        Initialize();

        // [GIVEN] Currency with Currency Factor = "X" defined for WORKDATE
        Currency.Get(LibraryCarteraCommon.CreateCarteraCurrency(true, false, false));

        // [GIVEN] Posted Sales Invoice with Amount = 100 with Currency Factor = "Y" (> "X")
        LibraryCarteraReceivables.CreateCarteraCustomer(Customer, Currency.Code);
        LibraryCarteraReceivables.CreateCustomerBankAccount(Customer, CustomerBankAccount);
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");
        SalesHeader.Validate(
          "Currency Factor", LibraryRandom.RandDecInDecimalRange(SalesHeader."Currency Factor", 100, 2));
        SalesHeader.Modify(true);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Bill Group for Posted Sales Invoice
        CreateBillGroupAndAddDocument(BillGroup, Currency.Code, SalesHeader."Posting Date", DocumentNo);

        // [WHEN] Post Bill Group
        LibraryCarteraReceivables.PostCarteraBillGroup(BillGroup);

        // [THEN] G/L Entry for Bill Group with Amount = 100 * "Y" exist
        VerifyBillGroupGLEntryExists(BillGroup."No.", Customer."Customer Posting Group", BillGroup."Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountSelectionPageHandler,ConfirmHandler,InsertDocModelHandler')]
    [Scope('OnPrem')]
    procedure PostPaymentOrderPurchInvDiffDatesExchRates()
    var
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Currency: Record Currency;
        CustomerBankAccount: Record "Customer Bank Account";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Bill Group] [Currency]
        // [SCENARIO 374792] Post Bill Group for Sales Invoice with FCY and different Exch. Rates between Posting Date
        Initialize();

        // [GIVEN] Currency with Currency Factor = "X" defined for WORKDATE
        Currency.Get(LibraryCarteraCommon.CreateCarteraCurrency(true, false, false));

        // [GIVEN] Posted Gen. Journal Line of Bill Type with Amount = 100 with Currency Factor = X
        LibraryCarteraReceivables.CreateCarteraCustomer(Customer, Currency.Code);
        LibraryCarteraReceivables.CreateCustomerBankAccount(Customer, CustomerBankAccount);
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Currency Factor = "Y" for Date = "Date2"(Gen. Journal Line Posting Date + 1)
        CreateExchangeRate(Currency.Code, SalesHeader."Posting Date", SalesHeader."Posting Date" + 1);

        // [GIVEN] Bill Group with Posting Date = "Date2" for Posted Gen. Journal Line
        CreateBillGroupAndAddDocument(BillGroup, Currency.Code, SalesHeader."Posting Date" + 1, DocumentNo);

        // [WHEN] Post Bill Group
        LibraryCarteraReceivables.PostCarteraBillGroup(BillGroup);

        // [THEN] G/L Entry with Amount = 100 * "X"
        VerifyBillGroupGLEntryExists(BillGroup."No.", Customer."Customer Posting Group", BillGroup."Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountSelectionPageHandler,ConfirmHandler,InsertDocModelHandler')]
    [Scope('OnPrem')]
    procedure PostPaymentOrderGenJournalLineCurrencyFactorModified()
    var
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        Currency: Record Currency;
        CustomerBankAccount: Record "Customer Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Bill Group] [Currency]
        // [SCENARIO 374792] Post Bill Group for Gen. Journal Line with FCY and modified Currency Factor
        Initialize();

        // [GIVEN] Currency with Currency Factor = "X" defined for WORKDATE
        Currency.Get(LibraryCarteraCommon.CreateCarteraCurrency(true, false, false));
        LibraryCarteraReceivables.CreateCarteraCustomer(Customer, Currency.Code);
        LibraryCarteraReceivables.CreateCustomerBankAccount(Customer, CustomerBankAccount);

        // [GIVEN] Posted Gen. Journal Line of Bill Type with Amount = 100 with Currency Factor = "Y" (> "X")
        CreateCarteraJournalLine(GenJournalLine, Customer."No.", Currency.Code);
        GenJournalLine.Validate(
          "Currency Factor", LibraryRandom.RandDecInDecimalRange(GenJournalLine."Currency Factor", 100, 2));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Bill Group for Posted Gen. Journal Line
        CreateBillGroupAndAddDocument(
          BillGroup, Currency.Code, GenJournalLine."Posting Date", GenJournalLine."Document No.");

        // [WHEN] Post Bill Group
        LibraryCarteraReceivables.PostCarteraBillGroup(BillGroup);

        // [THEN] G/L Entry for Bill Group with Amount = 100 * "Y" exist
        VerifyBillGroupGLEntryExists(BillGroup."No.", Customer."Customer Posting Group", BillGroup."Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountSelectionPageHandler,ConfirmHandler,InsertDocModelHandler')]
    [Scope('OnPrem')]
    procedure PostPaymentOrderGenJournalLineDiffDatesExchRates()
    var
        BillGroup: Record "Bill Group";
        Customer: Record Customer;
        Currency: Record Currency;
        CustomerBankAccount: Record "Customer Bank Account";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Bill Group] [Currency]
        // [SCENARIO 374792] Post Bill Group for Gen. Journal Line with FCY and different Exch. Rates between Posting Date
        Initialize();

        // [GIVEN] Currency with Currency Factor = "X" defined for WORKDATE
        Currency.Get(LibraryCarteraCommon.CreateCarteraCurrency(true, false, false));

        // [GIVEN] Posted Sales Invoice with Amount = 100 with Currency Factor = "X"
        LibraryCarteraReceivables.CreateCarteraCustomer(Customer, Currency.Code);
        LibraryCarteraReceivables.CreateCustomerBankAccount(Customer, CustomerBankAccount);
        CreateCarteraJournalLine(GenJournalLine, Customer."No.", Currency.Code);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Currency Factor = "Y" for Date = "Date2"(Invoice Posting Date + 1)
        CreateExchangeRate(Currency.Code, GenJournalLine."Posting Date", GenJournalLine."Posting Date" + 1);

        // [GIVEN] Bill Group with Posting Date = "Date2" for Posted Sales Invoice
        CreateBillGroupAndAddDocument(
          BillGroup, Currency.Code, GenJournalLine."Posting Date" + 1, GenJournalLine."Document No.");

        // [WHEN] Post Bill Group
        LibraryCarteraReceivables.PostCarteraBillGroup(BillGroup);

        // [THEN] G/L Entry with Amount = 100 * "X"
        VerifyBillGroupGLEntryExists(BillGroup."No.", Customer."Customer Posting Group", BillGroup."Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountSelectionPageHandler,ConfirmHandler,InsertDocModelHandler,SettleDocsInPostedBillGroupsRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SettleInvoiceAfterBillGroupSameRateAndExchRateAdjustment()
    var
        Customer: Record Customer;
        BillGroup: Record "Bill Group";
        CurrencyCode: Code[10];
        InvoiceNo: Code[20];
        PostingDate: array[4] of Date;
        CurrencyExchRate: array[4] of Decimal;
        AmtInv: Decimal;
        AmtPay: Decimal;
        SettleAmount: Decimal;
    begin
        // [FEATURE] [Adjust Exchange Rates]
        // [SCENARIO 375918] Sales Invoice, Bill Group, Adjust Exch.Rate, new Exch.Rate, Settle Invoice
        Initialize();

        // [GIVEN] Currency with Currency Factor on Date1 (1.0487), Date3 (1.223), Date4 (1.0788)
        CurrencyCode := CreateCurrencyForBillGroup();
        SetScenarioRatesDates(CurrencyExchRate, PostingDate);
        LibraryERM.CreateExchangeRate(CurrencyCode, PostingDate[1], CurrencyExchRate[1], CurrencyExchRate[1]);
        LibraryERM.CreateExchangeRate(CurrencyCode, PostingDate[3], CurrencyExchRate[3], CurrencyExchRate[3]);
        LibraryERM.CreateExchangeRate(CurrencyCode, PostingDate[4], CurrencyExchRate[4], CurrencyExchRate[4]);

        // [GIVEN] Posted Sales Invoice on Date1 with Amount = 5000.00
        LibraryCarteraReceivables.CreateFactoringCustomer(Customer, CurrencyCode);
        CreateAndPostInvoiceWOutVAT(Customer, InvoiceNo, SettleAmount, PostingDate[1]);

        // [GIVEN] Create Bill Group on Date2 < PostingDate < Date3
        CreateBillGroupAndAddDocument(BillGroup, CurrencyCode, PostingDate[2] + 1, InvoiceNo);
        LibraryCarteraReceivables.PostCarteraBillGroup(BillGroup);

        // [GIVEN] Run Adjust Exchange Rates on Date3
        RunExchRateAdjustment(CurrencyCode, PostingDate[3]);
        Commit();

        // [WHEN] Run TotalSettlement on Date4
        LibraryVariableStorage.Enqueue(StrSubstNo(SettlementCompletedSuccessfullyMsg, 1, SettleAmount));
        LibraryVariableStorage.Enqueue(PostingDate[4]);
        SettleDocsInPostBillGr(BillGroup."No.");

        // [THEN] 'Unrealized Losses Acc.' in Payment G/L Entry = -679.50 (5000/1.223 - 5000/1.0487)
        // [THEN] 'Receivables Account' in Payment G/L Entry = -4088.31 (-5000/1.223)
        // [THEN] Bank's 'G/L Account No.' in Payment G/L Entry = 4767.81 (5000/1.0478)
        AmtInv := Round(SettleAmount / CurrencyExchRate[1]);
        AmtPay := Round(SettleAmount / CurrencyExchRate[3]);
        VerifyPostedUnrealizedLossOnPayment(BillGroup."No.", CurrencyCode, AmtPay - AmtInv);
        VerifySettleGLEntries(
          BillGroup."No.", Customer."Customer Posting Group", BillGroup."Bank Account No.", -AmtPay, AmtInv);
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountSelectionPageHandler,ConfirmHandler,InsertDocModelHandler,SettleDocsInPostedBillGroupsRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SettleInvoiceAfterBillGroupSameRateAndTwoExchRateAdjustments()
    var
        Customer: Record Customer;
        BillGroup: Record "Bill Group";
        CurrencyCode: Code[10];
        InvoiceNo: Code[20];
        PostingDate: array[4] of Date;
        CurrencyExchRate: array[4] of Decimal;
        AmtInv: Decimal;
        AmtPay: Decimal;
        SettleAmount: Decimal;
    begin
        // [FEATURE] [Adjust Exchange Rates]
        // [SCENARIO 375918] Sales Invoice, Bill Group, Adjust Exch.Rate, Adjust Exch.Rate, Settle Invoice
        Initialize();

        // [GIVEN] Currency with Currency Factor on Date1 (1.0487), Date3 (1.223), Date4 (1.0788)
        CurrencyCode := CreateCurrencyForBillGroup();
        SetScenarioRatesDates(CurrencyExchRate, PostingDate);
        LibraryERM.CreateExchangeRate(CurrencyCode, PostingDate[1], CurrencyExchRate[1], CurrencyExchRate[1]);
        LibraryERM.CreateExchangeRate(CurrencyCode, PostingDate[3], CurrencyExchRate[3], CurrencyExchRate[3]);
        LibraryERM.CreateExchangeRate(CurrencyCode, PostingDate[4], CurrencyExchRate[4], CurrencyExchRate[4]);

        // [GIVEN] Posted Sales Invoice on Date1 with Amount = 5000.00
        LibraryCarteraReceivables.CreateFactoringCustomer(Customer, CurrencyCode);
        CreateAndPostInvoiceWOutVAT(Customer, InvoiceNo, SettleAmount, PostingDate[1]);

        // [GIVEN] Create Bill Group on Date2 < PostingDate < Date3
        CreateBillGroupAndAddDocument(BillGroup, CurrencyCode, PostingDate[2] + 1, InvoiceNo);
        LibraryCarteraReceivables.PostCarteraBillGroup(BillGroup);

        // [GIVEN] Run Adjust Exchange Rates on Date3, Date4
        RunExchRateAdjustment(CurrencyCode, PostingDate[3]);
        RunExchRateAdjustment(CurrencyCode, PostingDate[4]);
        Commit();

        // [WHEN] Run TotalSettlement on Date4
        LibraryVariableStorage.Enqueue(StrSubstNo(SettlementCompletedSuccessfullyMsg, 1, SettleAmount));
        LibraryVariableStorage.Enqueue(PostingDate[4]);
        SettleDocsInPostBillGr(BillGroup."No.");

        // [THEN] 'Unrealized Losses Acc.' in Payment G/L Entry = -133.03 (5000/1.0788 - 5000/1.0487)
        // [THEN] 'Receivables Account' in Payment G/L Entry = -4634.78 (-5000/1.0788)
        // [THEN] Bank's 'G/L Account No.' in Payment G/L Entry = 4767.81 (5000/1.0478)
        AmtInv := Round(SettleAmount / CurrencyExchRate[1]);
        AmtPay := Round(SettleAmount / CurrencyExchRate[4]);
        VerifyPostedUnrealizedLossOnPayment(BillGroup."No.", CurrencyCode, AmtPay - AmtInv);
        VerifySettleGLEntries(
          BillGroup."No.", Customer."Customer Posting Group", BillGroup."Bank Account No.", -AmtPay, AmtInv);
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountSelectionPageHandler,ConfirmHandler,InsertDocModelHandler,SettleDocsInPostedBillGroupsRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SettleInvoiceAfterBillGroupDiffRateAndExchRateAdjustment()
    var
        Customer: Record Customer;
        BillGroup: Record "Bill Group";
        CurrencyCode: Code[10];
        InvoiceNo: Code[20];
        PostingDate: array[4] of Date;
        CurrencyExchRate: array[4] of Decimal;
        AmtInv: Decimal;
        AmtPay: Decimal;
        SettleAmount: Decimal;
    begin
        // [FEATURE] [Adjust Exchange Rates]
        // [SCENARIO 375918] Sales Invoice, new Exch.Rate, Bill Group, Adjust Exch.Rate, new Exch.Rate, Settle Invoice
        Initialize();

        // [GIVEN] Currency with Currency Factor = "X" on Date1 (1.0487), Date2 (1.112), Date3 (1.223), Date4 (1.0788)
        CreateCurrencyWithExchRates(CurrencyCode, PostingDate, CurrencyExchRate);

        // [GIVEN] Posted Sales Invoice on Date1 with Amount = 5000.00
        LibraryCarteraReceivables.CreateFactoringCustomer(Customer, CurrencyCode);
        CreateAndPostInvoiceWOutVAT(Customer, InvoiceNo, SettleAmount, PostingDate[1]);

        // [GIVEN] Create Bill Group on Date2 < PostingDate < Date3
        CreateBillGroupAndAddDocument(BillGroup, CurrencyCode, PostingDate[2] + 1, InvoiceNo);
        LibraryCarteraReceivables.PostCarteraBillGroup(BillGroup);

        // [GIVEN] Run Adjust Exchange Rates on Date3
        RunExchRateAdjustment(CurrencyCode, PostingDate[3]);
        Commit();

        // [WHEN] Run TotalSettlement on Date4
        LibraryVariableStorage.Enqueue(StrSubstNo(SettlementCompletedSuccessfullyMsg, 1, SettleAmount));
        LibraryVariableStorage.Enqueue(PostingDate[4]);
        SettleDocsInPostBillGr(BillGroup."No.");

        // [THEN] 'Unrealized Losses Acc.' in Payment G/L Entry = -679.50 (5000/1.223 - 5000/1.0487)
        // [THEN] 'Receivables Account' in Payment G/L Entry = -4088.31 (-5000/1.223)
        // [THEN] Bank's 'G/L Account No.' in Payment G/L Entry = 4767.81 (5000/1.0478)
        AmtInv := Round(SettleAmount / CurrencyExchRate[1]);
        AmtPay := Round(SettleAmount / CurrencyExchRate[3]);
        VerifyPostedUnrealizedLossOnPayment(BillGroup."No.", CurrencyCode, AmtPay - AmtInv);
        VerifySettleGLEntries(
          BillGroup."No.", Customer."Customer Posting Group", BillGroup."Bank Account No.", -AmtPay, AmtInv);
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountSelectionPageHandler,ConfirmHandler,InsertDocModelHandler,SettleDocsInPostedBillGroupsRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SettleInvoiceAfterBillGroupDiffRateAndTwoExchRateAdjustments()
    var
        Customer: Record Customer;
        BillGroup: Record "Bill Group";
        CurrencyCode: Code[10];
        InvoiceNo: Code[20];
        PostingDate: array[4] of Date;
        CurrencyExchRate: array[4] of Decimal;
        AmtInv: Decimal;
        AmtPay: Decimal;
        SettleAmount: Decimal;
    begin
        // [FEATURE] [Adjust Exchange Rates]
        // [SCENARIO 375918] Sales Invoice, new Exch.Rate, Bill Group, Adjust Exch.Rate, Adjust Exch.Rate, Settle Invoice
        Initialize();

        // [GIVEN] Currency with Currency Factor = "X" on Date1 (1.0487), Date2 (1.112), Date3 (1.223), Date4 (1.0788)
        CreateCurrencyWithExchRates(CurrencyCode, PostingDate, CurrencyExchRate);

        // [GIVEN] Posted Sales Invoice on Date1 with Amount = 5000.00
        LibraryCarteraReceivables.CreateFactoringCustomer(Customer, CurrencyCode);
        CreateAndPostInvoiceWOutVAT(Customer, InvoiceNo, SettleAmount, PostingDate[1]);

        // [GIVEN] Create Bill Group on Date2 < PostingDate < Date3
        CreateBillGroupAndAddDocument(BillGroup, CurrencyCode, PostingDate[2] + 1, InvoiceNo);
        LibraryCarteraReceivables.PostCarteraBillGroup(BillGroup);

        // [GIVEN] Run Adjust Exchange Rates on Date3, Date4
        RunExchRateAdjustment(CurrencyCode, PostingDate[3]);
        RunExchRateAdjustment(CurrencyCode, PostingDate[4]);
        Commit();

        // [WHEN] Run TotalSettlement on Date4
        LibraryVariableStorage.Enqueue(StrSubstNo(SettlementCompletedSuccessfullyMsg, 1, SettleAmount));
        LibraryVariableStorage.Enqueue(PostingDate[4]);
        SettleDocsInPostBillGr(BillGroup."No.");

        // [THEN] 'Unrealized Losses Acc.' in Payment G/L Entry = -133.03 (5000/1.0788 - 5000/1.0487)
        // [THEN] 'Receivables Account' in Payment G/L Entry = -4634.78 (-5000/1.0788)
        // [THEN] Bank's 'G/L Account No.' in Payment G/L Entry = 4767.81 (5000/1.0478)
        AmtInv := Round(SettleAmount / CurrencyExchRate[1]);
        AmtPay := Round(SettleAmount / CurrencyExchRate[4]);
        VerifyPostedUnrealizedLossOnPayment(BillGroup."No.", CurrencyCode, AmtPay - AmtInv);
        VerifySettleGLEntries(
          BillGroup."No.", Customer."Customer Posting Group", BillGroup."Bank Account No.", -AmtPay, AmtInv);
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountSelectionPageHandler,ConfirmHandler,InsertDocModelHandler,SettleDocsInPostedBillGroupsRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SettleInvoiceAfterBillGroupDiffRateAndExchangeRateAdjustment()
    var
        Customer: Record Customer;
        BillGroup: Record "Bill Group";
        CurrencyCode: Code[10];
        InvoiceNo: Code[20];
        PostingDate: array[4] of Date;
        CurrencyExchRate: array[4] of Decimal;
        AmtInv: Decimal;
        AmtPay: Decimal;
        SettleAmount: Decimal;
    begin
        // [FEATURE] [Adjust Exchange Rates]
        // [SCENARIO 375918] Sales Invoice, new Exch.Rate, Bill Group, Adjust Exch.Rate, Settle Invoice
        Initialize();

        // [GIVEN] Currency with Currency Factor = "X" on Date1 (1.0487), Date2 (1.112), Date3 (1.223)
        CurrencyCode := CreateCurrencyForBillGroup();
        SetScenarioRatesDates(CurrencyExchRate, PostingDate);
        LibraryERM.CreateExchangeRate(CurrencyCode, PostingDate[1], CurrencyExchRate[1], CurrencyExchRate[1]);
        LibraryERM.CreateExchangeRate(CurrencyCode, PostingDate[2], CurrencyExchRate[2], CurrencyExchRate[2]);
        LibraryERM.CreateExchangeRate(CurrencyCode, PostingDate[3], CurrencyExchRate[3], CurrencyExchRate[3]);

        // [GIVEN] Posted Sales Invoice on Date1 with Amount = 5000.00
        LibraryCarteraReceivables.CreateFactoringCustomer(Customer, CurrencyCode);
        CreateAndPostInvoiceWOutVAT(Customer, InvoiceNo, SettleAmount, PostingDate[1]);

        // [GIVEN] Create Bill Group on Date2 < PostingDate < Date3
        CreateBillGroupAndAddDocument(BillGroup, CurrencyCode, PostingDate[2] + 1, InvoiceNo);
        LibraryCarteraReceivables.PostCarteraBillGroup(BillGroup);

        // [GIVEN] Run Adjust Exchange Rates on Date3
        RunExchRateAdjustment(CurrencyCode, PostingDate[3]);
        Commit();

        // [WHEN] Run TotalSettlement on Date4
        LibraryVariableStorage.Enqueue(StrSubstNo(SettlementCompletedSuccessfullyMsg, 1, SettleAmount));
        LibraryVariableStorage.Enqueue(PostingDate[4]);
        SettleDocsInPostBillGr(BillGroup."No.");

        // [THEN] 'Unrealized Losses Acc.' in Payment G/L Entry = -679.50 (5000/1.223 - 5000/1.0487)
        // [THEN] 'Receivables Account' in Payment G/L Entry = -4088.31 (-5000/1.223)
        // [THEN] Bank's 'G/L Account No.' in Payment G/L Entry = 4767.81 (5000/1.0478)
        AmtInv := Round(SettleAmount / CurrencyExchRate[1]);
        AmtPay := Round(SettleAmount / CurrencyExchRate[3]);
        VerifyPostedUnrealizedLossOnPayment(BillGroup."No.", CurrencyCode, AmtPay - AmtInv);
        VerifySettleGLEntries(
          BillGroup."No.", Customer."Customer Posting Group", BillGroup."Bank Account No.", -AmtPay, AmtInv);
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountSelectionPageHandler,ConfirmHandler,InsertDocModelHandler,SettleDocsInPostedBillGroupsRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SettleInvoiceAfterAdjustmentAndBillGroupAndTwoExchRateAdjustments()
    var
        Customer: Record Customer;
        BillGroup: Record "Bill Group";
        CurrencyCode: Code[10];
        InvoiceNo: Code[20];
        PostingDate: array[4] of Date;
        CurrencyExchRate: array[4] of Decimal;
        AmtInv: Decimal;
        AmtPay: Decimal;
        SettleAmount: Decimal;
    begin
        // [FEATURE] [Adjust Exchange Rates]
        // [SCENARIO 375918] Sales Invoice, Adjust Exch.Rate, Bill Group, Adjust Exch.Rate, Adjust Exch.Rate, Settle Invoice
        Initialize();

        // [GIVEN] Currency with Currency Factor = "X" on Date1 (1.0487), Date2 (1.112), Date3 (1.223), Date4 (1.0788)
        CreateCurrencyWithExchRates(CurrencyCode, PostingDate, CurrencyExchRate);

        // [GIVEN] Posted Sales Invoice on Date1 with Amount = 5000.00
        LibraryCarteraReceivables.CreateFactoringCustomer(Customer, CurrencyCode);
        CreateAndPostInvoiceWOutVAT(Customer, InvoiceNo, SettleAmount, PostingDate[1]);

        // [GIVEN] Run Adjust Exchange Rates on Date2
        RunExchRateAdjustment(CurrencyCode, PostingDate[2]);

        // [GIVEN] Create Bill Group on Date2 < PostingDate < Date3
        CreateBillGroupAndAddDocument(BillGroup, CurrencyCode, PostingDate[2] + 1, InvoiceNo);
        LibraryCarteraReceivables.PostCarteraBillGroup(BillGroup);

        // [GIVEN] Run Adjust Exchange Rates on Date3, Date4
        RunExchRateAdjustment(CurrencyCode, PostingDate[3]);
        RunExchRateAdjustment(CurrencyCode, PostingDate[4]);
        Commit();

        // [WHEN] Run TotalSettlement on Date4
        LibraryVariableStorage.Enqueue(StrSubstNo(SettlementCompletedSuccessfullyMsg, 1, SettleAmount));
        LibraryVariableStorage.Enqueue(PostingDate[4]);
        SettleDocsInPostBillGr(BillGroup."No.");

        // [THEN] 'Unrealized Losses Acc.' in Payment G/L Entry = -133.03 (5000/1.0788 - 5000/1.0487)
        // [THEN] 'Receivables Account' in Payment G/L Entry = -4634.78 (-5000/1.0788)
        // [THEN] Bank's 'G/L Account No.' in Payment G/L Entry = 4767.81 (5000/1.0478)
        AmtInv := Round(SettleAmount / CurrencyExchRate[1]);
        AmtPay := Round(SettleAmount / CurrencyExchRate[4]);
        VerifyPostedUnrealizedLossOnPayment(BillGroup."No.", CurrencyCode, AmtPay - AmtInv);
        VerifySettleGLEntries(
          BillGroup."No.", Customer."Customer Posting Group", BillGroup."Bank Account No.", -AmtPay, AmtInv);
    end;

    [Test]
    [HandlerFunctions('CurrenciesPageHandler,BankAccountSelectionPageHandler,ConfirmHandler,InsertDocModelHandler,SettleDocsInPostedBillGroupsRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BillsOnCollAccUsedToSettleInvoiceWithDiffExchRate()
    var
        Customer: Record Customer;
        CustPostingGroup: Record "Customer Posting Group";
        BillGroup: Record "Bill Group";
        GLEntry: Record "G/L Entry";
        CurrencyCode: Code[10];
        InvoiceNo: Code[20];
        SettleAmount: Decimal;
        ExchRateAmount: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Currency]
        // [SCENARIO 375918] G/L Account "Bolls on Collection Acc." is used to post settlemed for Posted Bill Group which contains Invoice with different currency exchange rate

        Initialize();

        // [GIVEN] Currency with different exchange rates on "Posting Date" = 01.01 and "Posting Date" = 02.01
        CurrencyCode := CreateCurrencyForBillGroup();
        for i := 0 to 1 do begin
            ExchRateAmount := LibraryRandom.RandDecInDecimalRange(1, 2, 2);
            LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate() + i, ExchRateAmount, ExchRateAmount);
        end;

        // [GIVEN] Posted Sales Invoice with "Posting Date" = 01.01
        LibraryCarteraReceivables.CreateCarteraCustomer(Customer, CurrencyCode);
        CreateAndPostInvoiceWOutVAT(Customer, InvoiceNo, SettleAmount, WorkDate());

        // [GIVEN] Posted Bill Group with "Posting Date" = 02.01
        CreateBillGroupAndAddDocument(BillGroup, CurrencyCode, WorkDate() + 1, InvoiceNo);
        LibraryCarteraReceivables.PostCarteraBillGroup(BillGroup);

        // [WHEN] Run Total Settlement of Posted Bill Group on "Posting Date" = 02.01
        LibraryVariableStorage.Enqueue(StrSubstNo(SettlementCompletedSuccessfullyMsg, 1, SettleAmount));
        LibraryVariableStorage.Enqueue(WorkDate() + 1);
        SettleDocsInPostBillGr(BillGroup."No.");

        // [THEN] Two G/L Entries are created (one for original amount and one for currency exch. difference) with "G/L Account No." = "Bills on Collection Acc."
        CustPostingGroup.Get(Customer."Customer Posting Group");
        VerifyGLEntryCount(GLEntry."Document Type"::Payment, BillGroup."No.", CustPostingGroup."Bills on Collection Acc.", 2);
    end;

    [Test]
    procedure CheckBillSituation_UT_OpenBillGroup()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CarteraDoc: Record "Cartera Doc.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 363341] TAB 21 "Cust. Ledger Entry".CheckBillSituation() throws an error in case of
        // [SCENARIO 363341] existing open cartera document (bill group) related to this ledger entry
        MockCustLedgEntry(CustLedgerEntry);
        MockCarteraDoc(CarteraDoc.Type::Receivable, CustLedgerEntry."Entry No.", LibraryUtility.GenerateGUID());

        asserterror CustLedgerEntry.CheckBillSituation();

        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(CheckBillSituationGroupErr, CustLedgerEntry.Description));
    end;

    [Test]
    procedure CheckBillSituation_UT_PostedBillGroup()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 363341] TAB 21 "Cust. Ledger Entry".CheckBillSituation() throws an error in case of
        // [SCENARIO 363341] existing posted cartera document (posted bill group) related to this ledger entry
        MockCustLedgEntry(CustLedgerEntry);
        MockPostedCarteraDoc(PostedCarteraDoc.Type::Receivable, CustLedgerEntry."Entry No.", LibraryUtility.GenerateGUID());

        asserterror CustLedgerEntry.CheckBillSituation();

        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(CheckBillSituationPostedErr, CustLedgerEntry.Description));
    end;

    [Test]
    procedure CrMemoTryApplyInvoiceAlreadyIncludedIntoBillGroup()
    var
        SalesHeader: Record "Sales Header";
        BillGroup: Record "Bill Group";
        CarteraDoc: Record "Cartera Doc.";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 363341] An error occurs trying apply the invoice already included into bill group
        Initialize();

        // [GIVEN] Posted sales invocie "X" with automatically created bill
        DocumentNo := PostCarteraSalesInvoice(SalesHeader, '');
        // [GIVEN] Bill group with added document "X"
        CreateBillGroupAndAddDocumentLCY(BillGroup, CarteraDoc, SalesHeader."Sell-to Customer No.", DocumentNo);
        // [GIVEN] Sales credit memo
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Sell-to Customer No.");

        // [WHEN] Try validate sales credit memo "Applies-to Doc. No." = "X"
        asserterror SalesHeader.Validate("Applies-to Doc. No.", DocumentNo);

        // [THEN] An error occurs: "Bill X cannot be applied since it is included in a bill group. Remove it from its bill group and try again."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(CheckBillSituationGroupErr, CarteraDoc.Description));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure CrMemoTryApplyInvoiceAlreadyIncludedIntoPostedBillGroup()
    var
        SalesHeader: Record "Sales Header";
        BillGroup: Record "Bill Group";
        CarteraDoc: Record "Cartera Doc.";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 363341] An error occurs trying apply the invoice already included into posted bill group
        Initialize();

        // [GIVEN] Posted sales invocie "X" with automatically created bill
        DocumentNo := PostCarteraSalesInvoice(SalesHeader, '');
        // [GIVEN] Posted bill group with added document "X"
        CreateBillGroupAndAddDocumentLCY(BillGroup, CarteraDoc, SalesHeader."Sell-to Customer No.", DocumentNo);
        LibraryCarteraReceivables.PostCarteraBillGroup(BillGroup);
        // [GIVEN] Sales credit memo
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", SalesHeader."Sell-to Customer No.");

        // [WHEN] Try validate sales credit memo "Applies-to Doc. No." = "X"
        asserterror SalesHeader.Validate("Applies-to Doc. No.", DocumentNo);

        // [THEN] An error occurs: "Bill X cannot be applied since it is included in a posted bill group."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(CheckBillSituationPostedErr, CarteraDoc.Description));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostCrMemoAppliedToInvoiceIncludedintoBillGroup()
    var
        SalesHeader: Record "Sales Header";
        BillGroup: Record "Bill Group";
        CarteraDoc: Record "Cartera Doc.";
        DocumentNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [SCENARIO 367139] An error occurs trying to posted credit memo applied to the bill already included into payment order
        Initialize();

        // [GIVEN] Posted sales invoice with automatically created bill
        DocumentNo := PostCarteraSalesInvoice(SalesHeader, '');
        CustomerNo := SalesHeader."Sell-to Customer No.";

        // [GIVEN] Purchase credit memo applied to posted bill
        LibrarySales.CreateSalesCreditMemo(SalesHeader);
        SalesHeader.Validate("Sell-to Customer No.", CustomerNo);
        ApplyHeaderToBill(SalesHeader, DocumentNo, '1');

        // [GIVEN] Add bill to Payment order
        CreateBillGroupAndAddDocumentLCY(BillGroup, CarteraDoc, SalesHeader."Sell-to Customer No.", DocumentNo);

        // [WHEN] Try to post the credit memo
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] An error occurs: "A grouped document cannot be settled from a journal."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(PostDocumentAppliedToBillInGroupErr, DocumentNo, BillGroup."No."));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostCrMemoAppliedToInvoiceIncludedintoPostedBillGroup()
    var
        SalesHeader: Record "Sales Header";
        BillGroup: Record "Bill Group";
        CarteraDoc: Record "Cartera Doc.";
        DocumentNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [SCENARIO 367139] An error occurs trying to posted credit memo applied to the bill already included into posted payment order
        Initialize();

        // [GIVEN] Posted sales invoice with automatically created bill
        DocumentNo := PostCarteraSalesInvoice(SalesHeader, '');
        CustomerNo := SalesHeader."Sell-to Customer No.";

        // [GIVEN] Purchase credit memo applied to posted bill
        LibrarySales.CreateSalesCreditMemo(SalesHeader);
        SalesHeader.Validate("Sell-to Customer No.", CustomerNo);
        ApplyHeaderToBill(SalesHeader, DocumentNo, '1');

        // [GIVEN] Add bill to Payment order, post it.
        CreateBillGroupAndAddDocumentLCY(BillGroup, CarteraDoc, SalesHeader."Sell-to Customer No.", DocumentNo);
        LibraryCarteraReceivables.PostCarteraBillGroup(BillGroup);

        // [WHEN] Try to post the credit memo
        asserterror LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] An error occurs: "A grouped document cannot be settled from a journal."
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(StrSubstNo(PostDocumentAppliedToBillInGroupErr, DocumentNo, BillGroup."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtMethodCodeModificationInvToCarteraInvoiceDocSituationIsBlank()
    var
        Customer: Record Customer;
        PaymentMethod: Record "Payment Method";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 384336] Payment Method is updated for Invoice Cartera Document
        Initialize();

        // [GIVEN] Customer with Cartera Payment Method "P1"
        LibraryCarteraCommon.CreatePaymentMethod(PaymentMethod, false, true);
        LibraryCarteraReceivables.CreateCustomer(Customer, '', PaymentMethod.Code);

        // [GIVEN] Cartera Document is posted for the Customer
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Cust. Ledger Entry with Document Situation = " "
        UpdateCustLedgerEntriesDocumentSituation(DocumentNo, Customer."No.", CustLedgerEntry."Document Situation"::" ");

        // [GIVEN] Cartera Payment Method "P2"
        LibraryCarteraCommon.CreatePaymentMethod(PaymentMethod, true, false);

        // [WHEN] Modify Payment Method Code to "P2".
        UpdateCustLedgEntryPaymentCode(DocumentNo, Customer."No.", PaymentMethod.Code, false);

        // [THEN] Cartera Document has Payment Method = "P2"
        VerifyCarteraDocInvoicePaymentMethod(DocumentNo, Customer."No.", PaymentMethod.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PmtMethodCodeModificationInvToCarteraInvoiceDocSituationIsNotBlank()
    var
        Customer: Record Customer;
        PaymentMethod: Record "Payment Method";
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 384336] Payment Method is not updated for Invoice Cartera Document
        Initialize();

        // [GIVEN] Customer with Cartera Payment Method "P1"
        LibraryCarteraCommon.CreatePaymentMethod(PaymentMethod, false, true);
        LibraryCarteraReceivables.CreateCustomer(Customer, '', PaymentMethod.Code);

        // [GIVEN] Cartera Document is posted for the Customer
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Cust. Ledger Entry with Document Situation <> " "
        UpdateCustLedgerEntriesDocumentSituation(DocumentNo, Customer."No.", CustLedgerEntry."Document Situation"::Cartera);

        // [GIVEN] Cartera Payment Method "P2"
        LibraryCarteraCommon.CreatePaymentMethod(PaymentMethod, true, false);

        // [WHEN] Modify Payment Method Code to "P2".
        asserterror UpdateCustLedgEntryPaymentCode(DocumentNo, Customer."No.", PaymentMethod.Code, false);

        // [THEN] Error appears
        Assert.ExpectedError(PaymentMethodCodeModifyErr);
    end;

    [Test]
    [HandlerFunctions('InsertDocModelHandler,ConfirmHandlerYesNo,SettleDocsInPostedBillGroupsRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SettleDocInPostBillGroupWithOtherSalespersonThanOneInCustCardWithDim()
    var
        Customer: Record Customer;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        BillGroup: Record "Bill Group";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedBillGroup: Record "Posted Bill Group";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Dimension] [Sales]
        // [SCENARIO 453011] Settle document in posted bill group with salesperson assigned from document that has different dimension setup

        Initialize();

        // [GIVEN] Salesperson "X" with default dimension of code "DIM" that has "Same Code" value posting
        // [GIVEN] Customer has salesperson "X"
        LibraryCarteraReceivables.CreateCarteraCustomer(Customer, '');
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        LibraryDimension.CreateDefaultDimensionWithNewDimValue(
          DefaultDimension, DATABASE::"Salesperson/Purchaser", SalespersonPurchaser.Code, DefaultDimension."Value Posting"::"Same Code");
        Customer.Validate("Salesperson Code", SalespersonPurchaser.Code);
        Customer.Modify(true);

        // [GIVEN] Posted Sales invoice with this customer
        // [GIVEN] Posted sales invoice has salesperson "Y" with default dimension of code "DIM" that has no value posting setup
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        LibraryDimension.CreateDimensionValue(DimensionValue, DefaultDimension."Dimension Code");
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::"Salesperson/Purchaser",
          SalespersonPurchaser.Code, DefaultDimension."Dimension Code", DimensionValue.Code);
        LibraryVariableStorage.Enqueue(DoYouWantToKeepExistingDimensionsQst);
        LibraryVariableStorage.Enqueue(false);
        SalesHeader.Validate("Salesperson Code", SalespersonPurchaser.Code);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader,
          SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(1000, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Posted bill group with sales invoice
        CreateBillGroupLCY(BillGroup);
        LibraryVariableStorage.Enqueue(DocumentNo);
        AddCarteraDocumentToBillGroup(BillGroup."No.");
        LibraryVariableStorage.Enqueue(StrSubstNo(BillGroupNotPrintedMsg, BillGroup.TableCaption));
        LibraryVariableStorage.Enqueue(true);
        LibraryCarteraReceivables.PostCarteraBillGroup(BillGroup);

        // [WHEN] Settle sales invoice in posted bill group
        SettleDocsInPostBillGrPage(PostedBillGroup, BillGroup."No.");

        // [THEN] Sales invoice is settled
        VerifyClosedCarteraDocStatusHonored(BillGroup."No.", DocumentNo);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDirectDebitMandateAndBankAccount()
    var
        Customer: Record Customer;
        SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate";
        SEPADirectDebitMandate1: Record "SEPA Direct Debit Mandate";
        CarteraDoc: Record "Cartera Doc.";
        DocumentNo: Code[20];
        PaymentMethodCode: Code[10];
        PaymentTermCode: Code[10];
        CustomerBankAccountCode: Code[20];
        CustomerBankAccountCode1: Code[20];
    begin
        // [SCENARIO 484624] Verify that The Cust./Vendor Bank Acc. Code and Direct Debit Mandate ID from the Bill Group or Receivable Docs should always be in sync.
        Initialize();

        // [GIVEN] Create a Carter Payment Method & Update the Bill Type.
        PaymentMethodCode := CreatePaymentMethodAndUpdate();

        // [GIVEN] Create a Payment Terms & update some field data.
        PaymentTermCode := CreatePaymentTermsAndUpdate();

        // [GIVEN] Create an Installment based on Payment Terms.
        LibraryCarteraReceivables.CreateMultipleInstallments(PaymentTermCode, LibraryRandom.RandInt(5));

        // [GIVEN] Create a Customer & update.
        CreateCustomerAndUpdate(Customer, PaymentMethodCode, PaymentTermCode);

        // [GIVEN] Create a Customer Bank Account & update.
        CustomerBankAccountCode := CreateCustomerBankAccountAndUpdate(Customer);

        // [GIVEN] Create another Customer Bank Account for same Customer & update.
        CustomerBankAccountCode1 := CreateCustomerBankAccountAndUpdate(Customer);

        // [GIVEN] Create a Customer Direct Debit Mandate & update.
        CreateDirectDebitMandateAndUpdate(SEPADirectDebitMandate, Customer."No.", CustomerBankAccountCode);

        // [GIVEN] Create another Customer Direct Debit Mandate for same Customer & update.
        CreateDirectDebitMandateAndUpdate(SEPADirectDebitMandate1, Customer."No.", CustomerBankAccountCode1);

        // [GIVEN] Create a Sales invoice & Post. 
        DocumentNo := CreateAndPostSalesInvoice(Customer."No.", SEPADirectDebitMandate.ID);

        // [VERIFY] Verify that Carter Doc. entries were created or not.
        Assert.IsTrue(FindCarteraDoc(CarteraDoc, DocumentNo, Customer."No."), CarterDocExistErr);

        // [GIVEN] Open the Receivables Cartera Docs page and update.
        OpenReceivablesCarteraDocPageAndUpdate(CarteraDoc, SEPADirectDebitMandate1);
        FindCarteraDoc(CarteraDoc, DocumentNo, Customer."No.");

        // [VERIFY] Verify that after the change in the "Cust./Vendor Bank Account Code" field data, the respective customer bank account field data changed.
        Assert.AreEqual(CarteraDoc."Direct Debit Mandate ID", SEPADirectDebitMandate1.ID, DirectDebitMandateIDErr);

        // [GIVEN] Create a Bill Group Document with Carter Lines.
        CreateBillGroupDocumentAndAddCarterLine(CarteraDoc, DocumentNo, Customer."No.");

        // [GIVEN] Open the Docs BG Subform page and update.
        OpenDocsBGSubformPageAndUpdate(CarteraDoc, SEPADirectDebitMandate.ID);
        FindCarteraDoc(CarteraDoc, DocumentNo, Customer."No.");

        // [VERIFY] Verify that after the change in the "Direct Debit Mandate ID" field, the respective Cust./Vendor Bank Account field data changed.
        Assert.AreEqual(CarteraDoc."Cust./Vendor Bank Acc. Code", SEPADirectDebitMandate."Customer Bank Account Code", CustVendorBankAccountErr);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibraryReportDataset.Reset();
    end;

    local procedure CreateBillGroupLCY(var BillGroup: Record "Bill Group")
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryCarteraReceivables.CreateBankAccount(BankAccount, '');
        LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccount."No.", BillGroup."Dealing Type"::Collection);
    end;

    local procedure CreateBillGroupFCY(CurrencyCode: Code[10]): Code[20]
    var
        BillGroup: Record "Bill Group";
        BankAccount: Record "Bank Account";
    begin
        LibraryCarteraReceivables.CreateBankAccount(BankAccount, CurrencyCode);
        exit(CreateBillGroup(CurrencyCode, BankAccount."No.", BillGroup."Dealing Type"::Collection));
    end;

    local procedure CreateBillGroupAndAddDocument(var BillGroup: Record "Bill Group"; CurrencyCode: Code[10]; PostingDate: Date; DocumentNo: Code[20])
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryCarteraReceivables.CreateBankAccount(BankAccount, CurrencyCode);
        BillGroup.Get(CreateBillGroup(CurrencyCode, BankAccount."No.", BillGroup."Dealing Type"::Collection));
        BillGroup.Validate("Posting Date", PostingDate);
        BillGroup.Modify(true);
        LibraryVariableStorage.Enqueue(DocumentNo);
        AddCarteraDocumentToBillGroup(BillGroup."No.");
        BillGroup.CalcFields("Amount (LCY)", Amount);
    end;

    procedure CreateBillGroupAndAddDocumentLCY(var BillGroup: Record "Bill Group"; var CarteraDoc: Record "Cartera Doc."; CustomerNo: Code[20]; DocumentNo: Code[20])
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryCarteraReceivables.CreateBankAccount(BankAccount, '');
        LibraryCarteraReceivables.UpdateBankAccountWithFormatN19(BankAccount);
        LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccount."No.", BillGroup."Dealing Type"::Collection);
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, DocumentNo, CustomerNo, BillGroup."No.");
    end;

    local procedure CreateCarteraJournalLine(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; CurrencyCode: Code[10])
    var
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryCarteraReceivables.CreateBankAccount(BankAccount, CurrencyCode);
        LibraryCarteraReceivables.CreateCarteraJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Bill, GenJournalLine."Account Type"::Customer,
          CustomerNo, GenJournalLine."Bal. Account Type"::"Bank Account", BankAccount."No.", LibraryRandom.RandInt(100));
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Bill No.", LibraryUtility.GenerateGUID());
        GenJournalLine.Modify(true);
    end;

    local procedure CreateExchangeRate(CurrencyCode: Code[10]; Date1: Date; Date2: Date)
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        ExchRateAdjust: Integer;
    begin
        LibraryERM.FindExchRate(CurrencyExchangeRate, CurrencyCode, Date1);
        ExchRateAdjust := LibraryRandom.RandInt(5);
        LibraryERM.CreateExchangeRate(
          CurrencyCode, Date2,
          CurrencyExchangeRate."Exchange Rate Amount" + ExchRateAdjust,
          CurrencyExchangeRate."Adjustment Exch. Rate Amount" + ExchRateAdjust);
    end;

    local procedure CreateCurrencyForBillGroup(): Code[10]
    var
        Currency: Record Currency;
    begin
        Currency.Get(LibraryERM.CreateCurrencyWithGLAccountSetup());
        Currency.Validate("Unrealized Gains Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Unrealized Losses Acc.", LibraryERM.CreateGLAccountNo());
        Currency.Validate("Invoice Rounding Precision", Currency."Amount Rounding Precision");
        Currency.Validate("Bill Groups - Collection", true);
        Currency.Modify(true);
        exit(Currency.Code);
    end;

    local procedure CreateCurrencyWithExchRates(var CurrencyCode: Code[10]; var PostingDate: array[4] of Date; var CurrencyExchRate: array[4] of Decimal)
    var
        i: Integer;
    begin
        CurrencyCode := CreateCurrencyForBillGroup();
        SetScenarioRatesDates(CurrencyExchRate, PostingDate);
        for i := 1 to ArrayLen(PostingDate) do
            LibraryERM.CreateExchangeRate(CurrencyCode, PostingDate[i], CurrencyExchRate[i], CurrencyExchRate[i]);
    end;

    local procedure MockCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgEntry.Init();
        CustLedgEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(CustLedgEntry, CustLedgEntry.FIELDNO("Entry No."));
        CustLedgEntry.Description := LibraryUtility.GenerateGUID();
        CustLedgEntry.Insert();
    end;

    local procedure MockCarteraDoc(Type: Enum "Cartera Document Type"; EntryNo: Integer; BGPONo: Code[20])
    var
        CarteraDoc: Record "Cartera Doc.";
    begin
        CarteraDoc.Type := Type;
        CarteraDoc."Entry No." := EntryNo;
        CarteraDoc."Bill Gr./Pmt. Order No." := BGPONo;
        CarteraDoc.Insert();
    end;

    local procedure MockPostedCarteraDoc(Type: Enum "Cartera Document Type"; EntryNo: Integer; BGPONo: Code[20])
    var
        PostedCarteraDoc: Record "Posted Cartera Doc.";
    begin
        PostedCarteraDoc.Type := Type;
        PostedCarteraDoc."Entry No." := EntryNo;
        PostedCarteraDoc."Bill Gr./Pmt. Order No." := BGPONo;
        PostedCarteraDoc.Insert();
    end;

    local procedure FindGLEntryByDocNoGLAccNo(var GLEntry: Record "G/L Entry"; DocumentNo: Code[20]; GLAccountNo: Code[20])
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
    end;

    local procedure AddCarteraDocumentToBillGroup(BillGroupNo: Code[20])
    var
        BillGroup: Record "Bill Group";
        BillGroupsTestPage: TestPage "Bill Groups";
    begin
        BillGroup.SetRange("No.", BillGroupNo);
        BillGroup.FindFirst();

        BillGroupsTestPage.OpenEdit();
        BillGroupsTestPage.GotoRecord(BillGroup);
        BillGroupsTestPage.Docs.Insert.Invoke();
        BillGroupsTestPage.OK().Invoke();
    end;

    local procedure ApplyHeaderToBill(var SalesHeader: Record "Sales Header"; DocumentNo: Code[20]; BillNo: Code[20])
    begin
        SalesHeader.Validate("Applies-to Doc. Type", SalesHeader."Applies-to Doc. Type"::Bill);
        SalesHeader.Validate("Applies-to Doc. No.", DocumentNo);
        SalesHeader.Validate("Applies-to Bill No.", BillNo);
        SalesHeader.Modify(true);
    end;

    local procedure RemoveCarteraDocumentFromBillGroup(BillGroupNo: Code[20])
    var
        BillGroup: Record "Bill Group";
        BillGroupsTestPage: TestPage "Bill Groups";
    begin
        BillGroup.SetRange("No.", BillGroupNo);
        BillGroup.FindFirst();

        BillGroupsTestPage.OpenEdit();
        BillGroupsTestPage.GotoRecord(BillGroup);
        BillGroupsTestPage.Docs.Remove.Invoke();
        BillGroupsTestPage.OK().Invoke();
    end;

    local procedure RunPostPaymentFromPaymentRegistrationPage(CustomerNo: Code[20]; DocumentNo: Code[20]; AmountToPost: Decimal)
    var
        PaymentRegistration: TestPage "Payment Registration";
    begin
        PaymentRegistration.OpenEdit();
        PaymentRegistration.FILTER.SetFilter("Source No.", CustomerNo);
        PaymentRegistration.FILTER.SetFilter("Document No.", DocumentNo);
        PaymentRegistration."Amount Received".SetValue(AmountToPost);
        PaymentRegistration.PostPayments.Invoke();
    end;

    local procedure RunExchRateAdjustment(CurrencyCode: Code[10]; PostingDate: Date)
    begin
        LibraryERM.RunExchRateAdjustmentSimple(CurrencyCode, PostingDate, PostingDate);
    end;

    local procedure SettleDocsInPostBillGr(BillGroupNo: Code[20])
    var
        PostedCarteraDoc: Record "Posted Cartera Doc.";
    begin
        PostedCarteraDoc.SetRange("Bill Gr./Pmt. Order No.", BillGroupNo);
        PostedCarteraDoc.FindFirst();
        PostedCarteraDoc.SetRecFilter();
        REPORT.RunModal(REPORT::"Settle Docs. in Post. Bill Gr.", true, false, PostedCarteraDoc);
    end;

    local procedure SettleDocsInPostBillGrPage(var PostedBillGroup: Record "Posted Bill Group"; BillGroupNo: Code[20])
    var
        PostedBillGroupsPage: TestPage "Posted Bill Groups";
        RemainingAmount: Decimal;
    begin
        PostedBillGroup.SetFilter("No.", BillGroupNo);
        PostedBillGroup.FindFirst();

        PostedBillGroupsPage.OpenEdit();
        PostedBillGroupsPage.GotoRecord(PostedBillGroup);

        Evaluate(RemainingAmount, PostedBillGroupsPage.Docs."Remaining Amount".Value);

        PostedBillGroupsPage.Docs."Total Settlement".Invoke();
    end;

    local procedure RejectDocsInPostBillGrPage(var PostedBillGroup: Record "Posted Bill Group"; BillGroupNo: Code[20])
    var
        PostedBillGroupsPage: TestPage "Posted Bill Groups";
    begin
        PostedBillGroup.SetFilter("No.", BillGroupNo);
        PostedBillGroup.FindFirst();

        PostedBillGroupsPage.OpenEdit();
        PostedBillGroupsPage.GotoRecord(PostedBillGroup);

        LibraryVariableStorage.Enqueue(StrSubstNo(SuccessfulDocumentRejectMsg, 1));

        PostedBillGroupsPage.Docs.Reject.Invoke();
    end;

    local procedure SetScenarioRatesDates(var ExchRate: array[4] of Decimal; var PostDate: array[4] of Date)
    var
        i: Integer;
    begin
        ExchRate[1] := 1.0487;
        ExchRate[2] := 1.112;
        ExchRate[3] := 1.223;
        ExchRate[4] := 1.0788;

        for i := 1 to ArrayLen(PostDate) do
            PostDate[i] := WorkDate() + (i - 1) * 2;
    end;

    local procedure VerifyBillGroupGLEntryExists(DocumentNo: Code[20]; CustomerPostingGroupCode: Code[20]; VerifyAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        CustomerPostingGroup.Get(CustomerPostingGroupCode);

        FindGLEntryByDocNoGLAccNo(GLEntry, DocumentNo, CustomerPostingGroup."Bills Account");
        Assert.AreEqual(-VerifyAmount, GLEntry.Amount, GLEntry.FieldCaption(Amount));

        FindGLEntryByDocNoGLAccNo(GLEntry, DocumentNo, CustomerPostingGroup."Bills on Collection Acc.");
        Assert.AreEqual(VerifyAmount, GLEntry.Amount, GLEntry.FieldCaption(Amount));
    end;

    local procedure VerifyCarteraDocumentRemovedFromBillGroup(BillGroupNo: Code[20])
    var
        CarteraDoc: Record "Cartera Doc.";
    begin
        CarteraDoc.SetRange("Bill Gr./Pmt. Order No.", BillGroupNo);
        Assert.IsTrue(CarteraDoc.IsEmpty, 'Bill group should have no rows present');
    end;

    local procedure VerifyCarteraDocPaymentMethod(DocumentNo: Code[20]; CustomerNo: Code[20]; PaymentMethodCode: Code[20]; BillNo: Code[20])
    var
        CarteraDoc: Record "Cartera Doc.";
    begin
        CarteraDoc.SetRange("Document No.", DocumentNo);
        CarteraDoc.SetRange("Account No.", CustomerNo);
        CarteraDoc.SetRange("No.", BillNo);
        CarteraDoc.FindFirst();
        CarteraDoc.TestField("Payment Method Code", PaymentMethodCode);
    end;

    local procedure VerifyCarteraDocInvoicePaymentMethod(DocumentNo: Code[20]; VendorNo: Code[20]; PaymentMethodCode: Code[20])
    var
        CarteraDoc: Record "Cartera Doc.";
    begin
        CarteraDoc.SetRange("Document No.", DocumentNo);
        CarteraDoc.SetRange("Account No.", VendorNo);
        CarteraDoc.SetRange("Document Type", CarteraDoc."Document Type"::Invoice);
        CarteraDoc.FindFirst();
        CarteraDoc.TestField("Payment Method Code", PaymentMethodCode);
    end;

    local procedure CreateBillGroup(CurrencyCode: Code[10]; BankAccountNo: Code[20]; DealingType: Enum "Cartera Dealing Type") BillGroupNo: Code[20]
    var
        BillGroups: TestPage "Bill Groups";
    begin
        BillGroups.OpenNew();

        BillGroups."Dealing Type".SetValue(DealingType);

        LibraryVariableStorage.Enqueue(CurrencyCode);
        BillGroups."Currency Code".Activate();
        BillGroups."Currency Code".Lookup();

        LibraryVariableStorage.Enqueue(BankAccountNo);
        BillGroups."Bank Account No.".Activate();
        BillGroups."Bank Account No.".Lookup();

        BillGroupNo := BillGroups."No.".Value();

        BillGroups.OK().Invoke();
    end;

    local procedure CreateAndPostInvoiceWOutVAT(var Customer: Record Customer; var InvoiceNo: Code[20]; var InvAmount: Decimal; PostingDate: Date)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccNo: Code[20];
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandDecInRange(10, 20, 2));
        VATPostingSetup.Validate("VAT %", 0);
        VATPostingSetup.Modify(true);
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);
        GLAccNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::Purchase);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccNo, 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);
        InvAmount := SalesLine.Amount;
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure PostCarteraSalesInvoice(var SalesHeader: Record "Sales Header"; CurrencyCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        LibraryCarteraReceivables.CreateCarteraCustomer(Customer, CurrencyCode);
        LibraryCarteraReceivables.CreateCustomerBankAccount(Customer, CustomerBankAccount);
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure UpdateCustLedgEntryPaymentCode(DocumentNo: Code[20]; CustomerNo: Code[20]; PaymentMethodCode: Code[20]; IsBill: Boolean): Code[20]
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        if IsBill then
            CustLedgerEntry.SetFilter("Bill No.", '<>%1', '');
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.Validate("Payment Method Code", PaymentMethodCode);
        CustLedgerEntry.Modify(true);
        exit(CustLedgerEntry."Bill No.");
    end;

    local procedure PostBillGroup(BillGroupNo: Code[20])
    var
        BillGroups: TestPage "Bill Groups";
    begin
        BillGroups.OpenEdit();
        BillGroups.GotoKey(BillGroupNo);
        BillGroups.Post.Invoke();
    end;

    local procedure PostBillGroupFromList(BillGroupNo: Code[20])
    var
        BillGroupsList: TestPage "Bill Groups List";
    begin
        BillGroupsList.OpenEdit();
        BillGroupsList.GotoKey(BillGroupNo);
        BillGroupsList.Post.Invoke();
    end;

    local procedure UpdateCustLedgerEntriesDocumentSituation(DocumentNo: Code[20]; CustomerNo: Code[20]; DocumentSituation: Enum "ES Document Situation")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindFirst();
        CustLedgerEntry."Document Situation" := DocumentSituation;
        CustLedgerEntry.Modify();
    end;

    local procedure VerifyReportData(Customer: Record Customer)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        CustLedgerEntry.FindLast();
        CustLedgerEntry.CalcFields("Remaining Amount");

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(CustomerNoElementNameTxt, Customer."No.");

        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(RemainingAmountElementNameTxt, CustLedgerEntry."Remaining Amount");
    end;

    local procedure VerifyClosedCarteraDocStatus(BillGroupNo: Code[20]; DocumentNo: Code[20])
    var
        ClosedCarteraDoc: Record "Closed Cartera Doc.";
    begin
        VerifyClosedCarteraDocWithStatus(BillGroupNo, DocumentNo, ClosedCarteraDoc.Status::Rejected);
    end;

    local procedure VerifyClosedCarteraDocStatusHonored(BillGroupNo: Code[20]; DocumentNo: Code[20])
    var
        ClosedCarteraDoc: Record "Closed Cartera Doc.";
    begin
        VerifyClosedCarteraDocWithStatus(BillGroupNo, DocumentNo, ClosedCarteraDoc.Status::Honored);
    end;

    local procedure VerifyClosedCarteraDocWithStatus(BillGroupNo: Code[20]; DocumentNo: Code[20]; Status: Enum "Cartera Document Status")
    var
        DummyClosedBillGroup: Record "Closed Bill Group";
        ClosedCarteraDoc: Record "Closed Cartera Doc.";
    begin
        DummyClosedBillGroup.SetRange("No.", BillGroupNo);
        Assert.RecordIsNotEmpty(DummyClosedBillGroup);

        ClosedCarteraDoc.SetRange("Document No.", DocumentNo);
        ClosedCarteraDoc.FindFirst();
        ClosedCarteraDoc.TestField(Status, Status);
    end;

    local procedure VerifyPostedUnrealizedLossOnPayment(DocumentNo: Code[20]; CurrencyCode: Code[10]; GainLossAmt: Decimal)
    var
        GLEntry: Record "G/L Entry";
        Currency: Record Currency;
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Payment);
        GLEntry.SetRange("Document No.", DocumentNo);

        Currency.Get(CurrencyCode);
        GLEntry.SetRange("G/L Account No.", Currency."Unrealized Losses Acc.");
        GLEntry.FindFirst();
        GLEntry.TestField(Amount, GainLossAmt);
    end;

    local procedure VerifySettleGLEntries(DocumentNo: Code[20]; CustPostingGroupCode: Code[20]; BankAccNo: Code[20]; RecAmt: Decimal; BankAmt: Decimal)
    var
        GLEntry: Record "G/L Entry";
        CustomerPostingGroup: Record "Customer Posting Group";
        BankAccount: Record "Bank Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Payment);
        GLEntry.SetRange("Document No.", DocumentNo);

        CustomerPostingGroup.Get(CustPostingGroupCode);
        VerifyGLAccAmountGLEntries(GLEntry, CustomerPostingGroup."Receivables Account", RecAmt);

        BankAccount.Get(BankAccNo);
        BankAccountPostingGroup.Get(BankAccount."Bank Acc. Posting Group");
        VerifyGLAccAmountGLEntries(GLEntry, BankAccountPostingGroup."G/L Account No.", BankAmt);
    end;

    local procedure VerifyGLAccAmountGLEntries(var GLEntry: Record "G/L Entry"; GlAccountNo: Code[20]; GLAmount: Decimal)
    begin
        GLEntry.SetRange("G/L Account No.", GlAccountNo);
        GLEntry.CalcSums(Amount);
        GLEntry.TestField(Amount, GLAmount);
    end;

    local procedure VerifyGLEntryCount(DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20]; GLAccNo: Code[20]; ExpectedCount: Integer)
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", DocType);
        GLEntry.SetRange("Document No.", DocNo);
        GLEntry.SetRange("G/L Account No.", GLAccNo);
        Assert.RecordCount(GLEntry, ExpectedCount);
    end;

    local procedure CreatePaymentMethodAndUpdate(): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        LibraryCarteraReceivables.CreateBillToCarteraPaymentMethod(PaymentMethod);
        PaymentMethod.Validate("Bill Type", PaymentMethod."Bill Type"::IOU);
        PaymentMethod.Modify(true);
        exit(PaymentMethod.Code);
    end;

    local procedure CreatePaymentTermsAndUpdate(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, true);
        PaymentTerms.Validate("Discount %", 0);
        Evaluate(PaymentTerms."Discount Date Calculation", '');
        PaymentTerms.Validate("Discount Date Calculation", PaymentTerms."Discount Date Calculation");
        PaymentTerms.Validate("VAT distribution", PaymentTerms."VAT distribution"::Proportional);
        PaymentTerms.Modify(true);
        exit(PaymentTerms.Code);
    end;

    local procedure CreateCustomerAndUpdate(Var Customer: Record Customer; PaymentMethodCode: Code[10]; PaymentTermCode: Code[10])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", '');
        Customer.Validate("Payment Method Code", PaymentMethodCode);
        Customer.Validate("Payment Terms Code", PaymentTermCode);
        Customer.Modify(true);
    end;

    local procedure CreateCustomerBankAccountAndUpdate(var Customer: Record Customer): Code[20]
    var
        CustomerBankAccount: Record "Customer Bank Account";
    begin
        LibraryCarteraReceivables.CreateCustomerBankAccount(Customer, CustomerBankAccount);
        CustomerBankAccount.IBAN := LibraryUtility.GenerateGUID();
        CustomerBankAccount."SWIFT Code" := LibraryUtility.GenerateGUID();
        CustomerBankAccount.Modify(true);
        exit(CustomerBankAccount.Code);
    end;

    local procedure CreateDirectDebitMandateAndUpdate(var SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate"; CustomerNo: Code[20]; CustomerBankAccountNo: Code[20])
    begin
        LibrarySales.CreateCustomerMandate(
           SEPADirectDebitMandate,
           CustomerNo,
           CustomerBankAccountNo,
           LibraryRandom.RandDate(10),
           LibraryRandom.RandDate(30));
        SEPADirectDebitMandate.Validate("Type of Payment", SEPADirectDebitMandate."Type of Payment"::Recurrent);
        SEPADirectDebitMandate.Validate("Expected Number of Debits", LibraryRandom.RandInt(100));
        SEPADirectDebitMandate.Modify(true);
    end;

    local procedure CreateAndPostSalesInvoice(CustomerNo: Code[20]; SEPADirectDebitMandateID: Code[35]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, CustomerNo);
        SalesHeader.Validate("Direct Debit Mandate ID", SEPADirectDebitMandateID);
        SalesHeader.Modify();
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, true));
    end;

    local procedure FindCarteraDoc(var CarteraDocs: Record "Cartera Doc."; DocNo: Code[20]; AccNo: Code[20]): Boolean
    begin
        CarteraDocs.SetRange("Document No.", DocNo);
        CarteraDocs.SetRange("Account No.", AccNo);
        exit(CarteraDocs.FindFirst());
    end;

    local procedure OpenReceivablesCarteraDocPageAndUpdate(var CarteraDoc: Record "Cartera Doc."; SEPADirectDebitMandate: Record "SEPA Direct Debit Mandate")
    var
        ReceivablesCarteraDocs: TestPage "Receivables Cartera Docs";
    begin
        ReceivablesCarteraDocs.OpenEdit();
        ReceivablesCarteraDocs.GoToRecord(CarteraDoc);
        ReceivablesCarteraDocs."Cust./Vendor Bank Acc. Code".SetValue(SEPADirectDebitMandate."Customer Bank Account Code");
        ReceivablesCarteraDocs.Close();
    end;

    local procedure OpenDocsBGSubformPageAndUpdate(var CarteraDoc: Record "Cartera Doc."; SEPADirectDebitMandateID: Code[35])
    var
        DocsinBGSubform: TestPage "Docs. in BG Subform";
    begin
        DocsinBGSubform.OpenEdit();
        DocsinBGSubform.GoToRecord(CarteraDoc);
        DocsinBGSubform."Direct Debit Mandate ID".SetValue(SEPADirectDebitMandateID);
        DocsinBGSubform.Close();
    end;

    local procedure CreateBillGroupDocumentAndAddCarterLine(var CarteraDoc: Record "Cartera Doc."; DocumentNo: code[20]; CustomerNo: code[20])
    var
        BankAccount: Record "Bank Account";
        BillGroup: Record "Bill Group";
    begin
        LibraryCarteraReceivables.CreateBankAccount(BankAccount, '');
        LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccount."No.", BillGroup."Dealing Type"::Collection);
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, DocumentNo, CustomerNo, BillGroup."No.");
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.ExpectedMessage(Format(ExpectedMessage), Question);
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerYesNo(Question: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
        ExpectedBool: Boolean;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        ExpectedBool := LibraryVariableStorage.DequeueBoolean();
        Assert.ExpectedMessage(Format(ExpectedMessage), Question);
        Reply := ExpectedBool;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure InsertDocModelHandler(var CarteraDocumentsPage: Page "Cartera Documents"; var Response: Action)
    var
        CarteraDoc: Record "Cartera Doc.";
        DocumentNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        CarteraDoc.SetRange("Document No.", DocumentNo);
        CarteraDoc.FindLast();

        CarteraDocumentsPage.SetRecord(CarteraDoc);

        Response := ACTION::LookupOK;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SettleDocsInPostedBillGroupsRequestPageHandler(var SettleDocsInPostedBillGroupsPage: TestRequestPage "Settle Docs. in Post. Bill Gr.")
    begin
        SettleDocsInPostedBillGroupsPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ConfirmRejectingInvoiceRequestPageHandler(var RejectDocsTestRequestPage: TestRequestPage "Reject Docs.")
    begin
        RejectDocsTestRequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerDueRequestPageHandler(var CustomerDuePayments: TestRequestPage "Customer - Due Payments")
    begin
        CustomerDuePayments.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CurrenciesPageHandler(var Currencies: TestPage Currencies)
    var
        CurrencyCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(CurrencyCode);
        Currencies.GotoKey(CurrencyCode);
        Currencies.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure BankAccountSelectionPageHandler(var BankAccountSelection: TestPage "Bank Account Selection")
    var
        BankAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccountNo);
        BankAccountSelection.GotoKey(BankAccountNo);
        BankAccountSelection.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentRegistrationSetupMPH(var PaymentRegistrationSetup: TestPage "Payment Registration Setup")
    begin
        PaymentRegistrationSetup.OK().Invoke();
    end;
}

