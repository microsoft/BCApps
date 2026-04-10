codeunit 134634 "Graph Collect Mgt Journal Line"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Graph] [Journal Line]
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryGraphJournalLines: Codeunit "Library - Graph Journal Lines";
        Assert: Codeunit Assert;
        GraphMgtJournalLines: Codeunit "Graph Mgt - Journal Lines";
        GraphMgtJournal: Codeunit "Graph Mgt - Journal";
        GraphMgtCustomerPayments: Codeunit "Graph Mgt - Customer Payments";
        LibraryAPIGeneralJournal: Codeunit "Library API - General Journal";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure TestInitializeLineWithoutOtherLines()
    var
        NewGenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        JournalName: Code[10];
    begin
        // [SCENARIO] Initialize a Journal Line in an empty General Journal
        // [GIVEN] an Empty General Journal
        Initialize();
        LibraryGraphJournalLines.Initialize();

        // [GIVEN] a journal lines journal batch name
        JournalName := CreateJournalLinesJournal();

        // [WHEN] we initialize a line
        GraphMgtJournalLines.SetJournalLineFilters(NewGenJournalLine);
        NewGenJournalLine.SetRange("Journal Batch Name", JournalName);
        GraphMgtJournalLines.SetJournalLineTemplateAndBatch(NewGenJournalLine, JournalName);
        LibraryAPIGeneralJournal.InitializeLine(NewGenJournalLine, 0, '', '');

        // [THEN] the Document No shouldn't be empty, if the Batch has a number series, and the LineNo shound't be 0
        GenJournalBatch.Get(GraphMgtJournal.GetDefaultJournalLinesTemplateName(), JournalName);
        if GenJournalBatch."No. Series" <> '' then
            Assert.AreNotEqual('', NewGenJournalLine."Document No.", 'The Document No shouldn''t be empty')
        else
            Assert.AreEqual('', NewGenJournalLine."Document No.", 'The Document No should be empty if the No. series is empty');
        Assert.AreNotEqual('', NewGenJournalLine."Line No.", 'The Line No shouldn''t be 0');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInitializeLineBetweenOtherLines()
    var
        GenJournalLine: Record "Gen. Journal Line";
        NewGenJournalLine: Record "Gen. Journal Line";
        JournalName: Code[10];
        DocumentNo: Code[20];
        Amount: Integer;
        LineNo: array[3] of Integer;
    begin
        // [SCENARIO] Initialize a Journal Line between 3 other lines
        // [GIVEN] 2 lines with total balance of 0 and 1 more at the end
        Initialize();
        LibraryGraphJournalLines.Initialize();

        // [GIVEN] a journal lines journal batch name
        JournalName := CreateJournalLinesJournal();

        Amount := LibraryRandom.RandDec(100, 0);
        DocumentNo := LibraryUtility.GenerateGUID();
        LineNo[1] := LibraryGraphJournalLines.CreateJournalLineWithAmountAndDocNo(JournalName, Amount, DocumentNo);
        LineNo[2] := LibraryGraphJournalLines.CreateJournalLineWithAmountAndDocNo(JournalName, -Amount, DocumentNo);
        LineNo[3] := LibraryGraphJournalLines.CreateSimpleJournalLine(JournalName);

        Assert.AreNotEqual(1, LineNo[3] - LineNo[2], 'The Lines created should have Line Nos with difference at least > 1');

        // [WHEN] we initialize a line after the 2 first lines that have a total balance of 0
        GraphMgtJournalLines.SetJournalLineFilters(NewGenJournalLine);
        NewGenJournalLine.SetRange("Journal Batch Name", JournalName);
        GraphMgtJournalLines.SetJournalLineTemplateAndBatch(NewGenJournalLine, JournalName);
        LibraryAPIGeneralJournal.InitializeLine(NewGenJournalLine, LineNo[2] + 1, '', '');

        // [THEN] the new line should be initialized with a different Document No
        GraphMgtJournalLines.SetJournalLineFilters(GenJournalLine);
        GenJournalLine.SetRange("Journal Batch Name", JournalName);
        GenJournalLine.SetRange("Line No.", LineNo[2]);
        GenJournalLine.FindFirst();
        Assert.AreNotEqual(GenJournalLine."Document No.", NewGenJournalLine."Document No.", 'The Document No should be increased');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInitializeLineAtTheBottom()
    var
        GenJournalLine: Record "Gen. Journal Line";
        NewGenJournalLine: Record "Gen. Journal Line";
        JournalName: Code[10];
        DocumentNo: Code[20];
        Amount: Integer;
        LineNo: array[2] of Integer;
    begin
        // [SCENARIO] Initialize a Journal Line at the bottom of a journal with 2 lines
        // [GIVEN] 2 lines with total balance of 0
        Initialize();
        LibraryGraphJournalLines.Initialize();

        // [GIVEN] a journal lines journal batch name
        JournalName := CreateJournalLinesJournal();

        Amount := LibraryRandom.RandDec(100, 0);
        DocumentNo := LibraryUtility.GenerateGUID();
        LineNo[1] := LibraryGraphJournalLines.CreateJournalLineWithAmountAndDocNo(JournalName, Amount, DocumentNo);
        LineNo[2] := LibraryGraphJournalLines.CreateJournalLineWithAmountAndDocNo(JournalName, -Amount, DocumentNo);

        // [WHEN] we initialize a line after the 2 first lines that have a total balance of 0
        GraphMgtJournalLines.SetJournalLineFilters(NewGenJournalLine);
        NewGenJournalLine.SetRange("Journal Batch Name", JournalName);
        GraphMgtJournalLines.SetJournalLineTemplateAndBatch(NewGenJournalLine, JournalName);
        LibraryAPIGeneralJournal.InitializeLine(NewGenJournalLine, LineNo[2] + 1, '', '');

        // [THEN] the new line should be initialized with a different Document No
        GraphMgtJournalLines.SetJournalLineFilters(GenJournalLine);
        GenJournalLine.SetRange("Journal Batch Name", JournalName);
        GenJournalLine.SetRange("Line No.", LineNo[2]);
        GenJournalLine.FindFirst();
        Assert.AreNotEqual(GenJournalLine."Document No.", NewGenJournalLine."Document No.", 'The Document No should be increased');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInitializeLineWithoutLineNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        NewGenJournalLine: Record "Gen. Journal Line";
        JournalName: Code[10];
        DocumentNo: Code[20];
        Amount: Integer;
        LineNo: array[2] of Integer;
        LineNoExpectedIncrease: Integer;
    begin
        // [SCENARIO] Initialize a Journal Line at the bottom of a journal with 2 lines without Line No specified
        // [GIVEN] 2 lines with total balance of 0
        Initialize();
        LibraryGraphJournalLines.Initialize();

        // [GIVEN] a journal lines journal batch name
        JournalName := CreateJournalLinesJournal();

        Amount := LibraryRandom.RandDec(100, 0);
        DocumentNo := LibraryUtility.GenerateGUID();
        LineNoExpectedIncrease := 10000;
        LineNo[1] := LibraryGraphJournalLines.CreateJournalLineWithAmountAndDocNo(JournalName, Amount, DocumentNo);
        LineNo[2] := LibraryGraphJournalLines.CreateJournalLineWithAmountAndDocNo(JournalName, -Amount, DocumentNo);

        // [WHEN] we initialize a line after the 2 first lines that have a total balance of 0 without line no
        GraphMgtJournalLines.SetJournalLineFilters(NewGenJournalLine);
        NewGenJournalLine.SetRange("Journal Batch Name", JournalName);
        GraphMgtJournalLines.SetJournalLineTemplateAndBatch(NewGenJournalLine, JournalName);
        LibraryAPIGeneralJournal.InitializeLine(NewGenJournalLine, 0, '', '');

        // [THEN] the new line should be initialized with a different Document No and a line no increased by 10000
        GraphMgtJournalLines.SetJournalLineFilters(GenJournalLine);
        GenJournalLine.SetRange("Journal Batch Name", JournalName);
        GenJournalLine.SetRange("Line No.", LineNo[2]);
        GenJournalLine.FindFirst();
        Assert.AreNotEqual(GenJournalLine."Document No.", NewGenJournalLine."Document No.", 'The Document No should be increased');
        Assert.AreEqual(
          GenJournalLine."Line No." + LineNoExpectedIncrease, NewGenJournalLine."Line No.",
          StrSubstNo('The LineNo should be increased by %1', LineNoExpectedIncrease));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestInitializeLineWithFixedDocumentNo()
    var
        NewGenJournalLine: Record "Gen. Journal Line";
        JournalName: Code[10];
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Initialize a Journal Line with Fixed Document No in an empty General Journal
        // [GIVEN] an Empty General Journal
        Initialize();
        LibraryGraphJournalLines.Initialize();

        // [GIVEN] a journal lines journal batch name
        JournalName := CreateJournalLinesJournal();

        // [WHEN] we initialize a line
        DocumentNo := LibraryUtility.GenerateGUID();
        Commit();

        GraphMgtJournalLines.SetJournalLineFilters(NewGenJournalLine);
        NewGenJournalLine.SetRange("Journal Batch Name", JournalName);
        GraphMgtJournalLines.SetJournalLineTemplateAndBatch(NewGenJournalLine, JournalName);
        LibraryAPIGeneralJournal.InitializeLine(NewGenJournalLine, 0, DocumentNo, '');

        // [THEN] the Document No shouldn't be changed
        Assert.AreEqual(DocumentNo, NewGenJournalLine."Document No.", 'The Document No shouldn''t be changed');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAlterDocNoBasedOnExternalDocNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
        NewGenJournalLine: Record "Gen. Journal Line";
        JournalName: Code[10];
        DocumentNo: Code[20];
        ExternalDocNo: Code[35];
        Amount: Integer;
        LineNo: array[2] of Integer;
    begin
        // [SCENARIO] Initialize a Journal Line with an External Doc No, at the bottom of a journal with 2 lines
        // [GIVEN] 2 lines with total balance of 0
        Initialize();
        LibraryGraphJournalLines.Initialize();

        // [GIVEN] a journal lines journal batch name
        JournalName := CreateJournalLinesJournal();

        Amount := LibraryRandom.RandDec(200, 0);
        DocumentNo := LibraryUtility.GenerateGUID();
        LineNo[1] := LibraryGraphJournalLines.CreateJournalLineWithAmountAndDocNo(JournalName, Amount, DocumentNo);
        LineNo[2] := LibraryGraphJournalLines.CreateJournalLineWithAmountAndDocNo(JournalName, Amount, DocumentNo);
        ExternalDocNo := LibraryUtility.GenerateGUID();

        // [WHEN] we initialize a line after the 2 first lines that have a non zero balance
        GraphMgtJournalLines.SetJournalLineFilters(NewGenJournalLine);
        NewGenJournalLine.SetRange("Journal Batch Name", JournalName);
        GraphMgtJournalLines.SetJournalLineTemplateAndBatch(NewGenJournalLine, JournalName);
        LibraryAPIGeneralJournal.InitializeLine(NewGenJournalLine, LineNo[2] + 1, '', ExternalDocNo);

        // [THEN] the new line should be initialized with a different Document No
        GraphMgtJournalLines.SetJournalLineFilters(GenJournalLine);
        GenJournalLine.SetRange("Journal Batch Name", JournalName);
        GenJournalLine.Reset();
        GenJournalLine.SetRange("Line No.", LineNo[2]);
        GenJournalLine.FindFirst();
        Assert.AreNotEqual(GenJournalLine."Document No.", NewGenJournalLine."Document No.", 'The Document No should be increased');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAccountNoAndIDCorrectSync()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        JournalName: Code[10];
        AccountNo: Code[20];
        AccountGUID: Guid;
        LineNo: array[3] of Integer;
        BlankGUID: Guid;
    begin
        // [FEATURE] [Account] [ID]
        // [SCENARIO] Initialize lines with and without AccountNo and AccountId to check if they sync correctly
        Initialize();
        LibraryGraphJournalLines.Initialize();

        // [GIVEN] a journal lines journal batch name
        JournalName := CreateJournalLinesJournal();

        // [GIVEN] a G/L Account with Direct Posting enabled
        AccountNo := LibraryGraphJournalLines.CreateAccount();

        // [WHEN] we create the lines with and without AccountNo and AccountId
        GLAccount.Reset();
        GLAccount.SetFilter("No.", AccountNo);
        GLAccount.FindFirst();
        AccountGUID := GLAccount.SystemId;
        Assert.AreNotEqual(BlankGUID, AccountGUID, 'The AccountGUID should not be blank');
        LineNo[1] := LibraryGraphJournalLines.CreateJournalLine(JournalName, AccountNo, BlankGUID, 0, '');
        LineNo[2] := LibraryGraphJournalLines.CreateJournalLine(JournalName, '', AccountGUID, 0, '');
        LineNo[3] := LibraryGraphJournalLines.CreateJournalLine(JournalName, AccountNo, AccountGUID, 0, '');
        Commit();

        // [THEN] the Nos and Ids should be the same everywhere
        GenJournalLine.Reset();
        GraphMgtJournalLines.SetJournalLineFilters(GenJournalLine);
        GenJournalLine.SetRange("Journal Batch Name", JournalName);
        GenJournalLine.SetRange("Line No.", LineNo[1]);
        GenJournalLine.FindFirst();
        Assert.AreEqual(AccountNo, GenJournalLine."Account No.", 'The AccountNo is wrong');
        Assert.AreEqual(AccountGUID, GenJournalLine."Account Id", 'The AccountId is wrong');
        GenJournalLine.Reset();
        GraphMgtJournalLines.SetJournalLineFilters(GenJournalLine);
        GenJournalLine.SetRange("Journal Batch Name", JournalName);
        GenJournalLine.SetRange("Line No.", LineNo[2]);
        GenJournalLine.FindFirst();
        Assert.AreEqual(AccountNo, GenJournalLine."Account No.", 'The AccountNo is wrong');
        Assert.AreEqual(AccountGUID, GenJournalLine."Account Id", 'The AccountId is wrong');
        GenJournalLine.Reset();
        GraphMgtJournalLines.SetJournalLineFilters(GenJournalLine);
        GenJournalLine.SetRange("Journal Batch Name", JournalName);
        GenJournalLine.SetRange("Line No.", LineNo[3]);
        GenJournalLine.FindFirst();
        Assert.AreEqual(AccountNo, GenJournalLine."Account No.", 'The AccountNo is wrong');
        Assert.AreEqual(AccountGUID, GenJournalLine."Account Id", 'The AccountId is wrong');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAccountNoAndIDErrorSync()
    var
        GLAccount: Record "G/L Account";
        JournalName: Code[10];
        AccountNo: Code[20];
        AccountGUID: Guid;
        BlankGUID: Guid;
    begin
        // [FEATURE] [Account] [ID]
        // [SCENARIO] Initialize lines with AccountNo and AccountId that no longer exist
        Initialize();
        LibraryGraphJournalLines.Initialize();

        // [GIVEN] a journal lines journal batch name
        JournalName := CreateJournalLinesJournal();

        // [GIVEN] an AccountNo and AccountId of a deleted G/L Account
        AccountNo := LibraryGraphJournalLines.CreateAccount();

        // [WHEN] we create the lines with AccountNo and AccountId that do not match
        GLAccount.Reset();
        GLAccount.SetFilter("No.", AccountNo);
        GLAccount.FindFirst();
        AccountGUID := GLAccount.SystemId;
        GLAccount.Delete();
        Commit();

        // [THEN] creating the lines should throw an error
        asserterror LibraryGraphJournalLines.CreateJournalLine(JournalName, AccountNo, BlankGUID, 0, '');

        asserterror LibraryGraphJournalLines.CreateJournalLine(JournalName, '', AccountGUID, 0, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEmptyAccountNoBlanksIdToo()
    var
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        JournalName: Code[10];
        AccountNo: Code[20];
        LineNo: Integer;
        AccountGUID: Guid;
        BlankGUID: Guid;
    begin
        // [FEATURE] [Account] [ID]
        // [SCENARIO] Setting the Account No to blank should also blank the Account Id
        Initialize();
        LibraryGraphJournalLines.Initialize();

        // [GIVEN] a journal batch name
        JournalName := CreateJournalLinesJournal();

        // [GIVEN] a G/L Account
        AccountNo := LibraryGraphJournalLines.CreateAccount();

        // [WHEN] we create the line with AccountNo and then blank it
        GLAccount.Reset();
        GLAccount.SetFilter("No.", AccountNo);
        GLAccount.FindFirst();
        AccountGUID := GLAccount.SystemId;
        LineNo := LibraryGraphJournalLines.CreateJournalLine(JournalName, AccountNo, BlankGUID, 0, '');
        GenJournalLine.Reset();
        GraphMgtJournalLines.SetJournalLineFilters(GenJournalLine);
        GenJournalLine.SetRange("Journal Batch Name", JournalName);
        GenJournalLine.SetRange("Line No.", LineNo);
        GenJournalLine.FindFirst();
        GenJournalLine.Validate("Account No.", '');
        GenJournalLine.Modify();
        Commit();

        // [THEN] the Account Id should also be blank
        GenJournalLine.Reset();
        GraphMgtJournalLines.SetJournalLineFilters(GenJournalLine);
        GenJournalLine.SetRange("Journal Batch Name", JournalName);
        GenJournalLine.SetRange("Line No.", LineNo);
        GenJournalLine.FindFirst();
        Assert.AreEqual(BlankGUID, GenJournalLine."Account Id", 'Blanking the Account No should blank the Account Id too.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomerNoAndIDCorrectSync()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        JournalName: Code[10];
        CustomerNo: Code[20];
        CustomerGUID: Guid;
        LineNo: array[3] of Integer;
        BlankGUID: Guid;
    begin
        // [FEATURE] [Customer] [ID]
        // [SCENARIO] Initialize lines with and without CustomerNo and CustomerId to check if they sync correctly
        Initialize();
        LibraryGraphJournalLines.Initialize();

        // [GIVEN] a customer payments journal batch name
        JournalName := CreateCustomerPaymentsJournal();

        // [GIVEN] a Customer
        CustomerNo := LibraryGraphJournalLines.CreateCustomer();

        // [WHEN] we create the lines with and without CustomerNo and CustomerId
        Customer.Reset();
        Customer.SetFilter("No.", CustomerNo);
        Customer.FindFirst();
        CustomerGUID := Customer.SystemId;
        Assert.AreNotEqual(BlankGUID, CustomerGUID, 'The CustomerGUID should not be blank');
        LineNo[1] := LibraryGraphJournalLines.CreateCustomerPayment(JournalName, CustomerNo, BlankGUID, '', BlankGUID, 0, '');
        LineNo[2] := LibraryGraphJournalLines.CreateCustomerPayment(JournalName, '', CustomerGUID, '', BlankGUID, 0, '');
        LineNo[3] := LibraryGraphJournalLines.CreateCustomerPayment(JournalName, CustomerNo, CustomerGUID, '', BlankGUID, 0, '');
        Commit();

        // [THEN] the Nos and Ids should be the same everywhere
        GenJournalLine.Reset();
        GraphMgtCustomerPayments.SetCustomerPaymentsFilters(GenJournalLine);
        GenJournalLine.SetRange("Line No.", LineNo[1]);
        Assert.IsTrue(GenJournalLine.FindFirst(), 'The customer payment should exist');
        Assert.AreEqual(CustomerNo, GenJournalLine."Account No.", 'The CustomerNo is wrong');
        Assert.AreEqual(CustomerGUID, GenJournalLine."Customer Id", 'The CustomerId is wrong');
        GenJournalLine.Reset();
        GraphMgtCustomerPayments.SetCustomerPaymentsFilters(GenJournalLine);
        GenJournalLine.SetRange("Line No.", LineNo[2]);
        GenJournalLine.FindFirst();
        Assert.IsTrue(GenJournalLine.FindFirst(), 'The customer payment should exist');
        Assert.AreEqual(CustomerNo, GenJournalLine."Account No.", 'The CustomerNo is wrong');
        Assert.AreEqual(CustomerGUID, GenJournalLine."Customer Id", 'The CustomerId is wrong');
        GenJournalLine.Reset();
        GraphMgtCustomerPayments.SetCustomerPaymentsFilters(GenJournalLine);
        GenJournalLine.SetRange("Line No.", LineNo[3]);
        GenJournalLine.FindFirst();
        Assert.IsTrue(GenJournalLine.FindFirst(), 'The customer payment should exist');
        Assert.AreEqual(CustomerNo, GenJournalLine."Account No.", 'The CustomerNo is wrong');
        Assert.AreEqual(CustomerGUID, GenJournalLine."Customer Id", 'The CustomerId is wrong');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCustomerNoAndIDErrorSync()
    var
        Customer: Record Customer;
        JournalName: Code[10];
        CustomerNo: Code[20];
        CustomerGUID: Guid;
        BlankGUID: Guid;
    begin
        // [FEATURE] [Customer] [ID]
        // [SCENARIO] Initialize lines with CustomerNo and CustomerId that no longer exist
        Initialize();
        LibraryGraphJournalLines.Initialize();

        // [GIVEN] a customer payments journal batch name
        JournalName := CreateCustomerPaymentsJournal();

        // [GIVEN] an CustomerNo and CustomerId of a deleted Customer
        CustomerNo := LibraryGraphJournalLines.CreateCustomer();

        // [WHEN] we create the lines with CustomerNo and CustomerId that do not match
        Customer.Reset();
        Customer.SetFilter("No.", CustomerNo);
        Customer.FindFirst();
        CustomerGUID := Customer.SystemId;
        Customer.Delete();
        Commit();

        // [THEN] creating the lines should throw an error
        asserterror LibraryGraphJournalLines.CreateCustomerPayment(JournalName, CustomerNo, BlankGUID, '', BlankGUID, 0, '');

        asserterror LibraryGraphJournalLines.CreateCustomerPayment(JournalName, '', CustomerGUID, '', BlankGUID, 0, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEmptyCustomerNoBlanksIdToo()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        JournalName: Code[10];
        CustomerNo: Code[20];
        LineNo: Integer;
        CustomerGUID: Guid;
        BlankGUID: Guid;
    begin
        // [FEATURE] [Customer] [ID]
        // [SCENARIO] Setting the Customer No to blank should also blank the Customer Id
        Initialize();
        LibraryGraphJournalLines.Initialize();

        // [GIVEN] a customer payments journal batch name
        JournalName := CreateCustomerPaymentsJournal();

        // [GIVEN] a Customer
        CustomerNo := LibraryGraphJournalLines.CreateCustomer();

        // [WHEN] we create the line with CustomerNo and then blank it
        Customer.Reset();
        Customer.SetFilter("No.", CustomerNo);
        Customer.FindFirst();
        CustomerGUID := Customer.SystemId;
        LineNo := LibraryGraphJournalLines.CreateCustomerPayment(JournalName, CustomerNo, BlankGUID, '', BlankGUID, 0, '');
        GenJournalLine.Reset();
        GraphMgtCustomerPayments.SetCustomerPaymentsFilters(GenJournalLine);
        GenJournalLine.SetRange("Line No.", LineNo);
        GenJournalLine.FindFirst();
        GenJournalLine.Validate("Account No.", '');
        GenJournalLine.Modify();
        Commit();

        // [THEN] the Customer Id should also be blank
        GenJournalLine.Reset();
        GraphMgtCustomerPayments.SetCustomerPaymentsFilters(GenJournalLine);
        GenJournalLine.SetRange("Line No.", LineNo);
        GenJournalLine.FindFirst();
        Assert.AreEqual(BlankGUID, GenJournalLine."Customer Id", 'Blanking the Customer No should blank the Customer Id too.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAppliesToDocNoAndIDCorrectSync()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
        JournalName: Code[10];
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        InvoiceGUID: Guid;
        LineNo: array[3] of Integer;
        BlankGUID: Guid;
    begin
        // [FEATURE] [Applies-To]
        // [SCENARIO] Initialize lines with and without AppliesToDocNo and AppliesToDocId to check if they sync correctly
        Initialize();
        LibraryGraphJournalLines.Initialize();

        // [GIVEN] a customer payments journal batch name
        JournalName := CreateCustomerPaymentsJournal();

        // [GIVEN] a Customer
        CustomerNo := LibraryGraphJournalLines.CreateCustomer();

        // [GIVEN] a posted sales invoice
        InvoiceNo := LibraryGraphJournalLines.CreatePostedSalesInvoice(CustomerNo);

        // [WHEN] we create the lines with and without AppliesToDocNo and AppliesToDocId
        SalesInvoiceHeader.Reset();
        SalesInvoiceHeader.SetFilter("No.", InvoiceNo);
        SalesInvoiceHeader.FindFirst();
        InvoiceGUID := SalesInvoiceAggregator.GetSalesInvoiceHeaderId(SalesInvoiceHeader);
        Assert.AreNotEqual(BlankGUID, InvoiceGUID, 'The InvoiceGUID should not be blank');
        LineNo[1] := LibraryGraphJournalLines.CreateCustomerPayment(JournalName, CustomerNo, BlankGUID, InvoiceNo, BlankGUID, 0, '');
        LineNo[2] := LibraryGraphJournalLines.CreateCustomerPayment(JournalName, CustomerNo, BlankGUID, '', InvoiceGUID, 0, '');
        LineNo[3] := LibraryGraphJournalLines.CreateCustomerPayment(JournalName, CustomerNo, BlankGUID, InvoiceNo, InvoiceGUID, 0, '');
        Commit();

        // [THEN] the Nos and Ids should be the same everywhere
        GenJournalLine.Reset();
        GraphMgtCustomerPayments.SetCustomerPaymentsFilters(GenJournalLine);
        GenJournalLine.SetRange("Line No.", LineNo[1]);
        GenJournalLine.FindFirst();
        Assert.AreEqual(InvoiceNo, GenJournalLine."Applies-to Doc. No.", 'The InvoiceNo is wrong');
        Assert.AreEqual(InvoiceGUID, GenJournalLine."Applies-to Invoice Id", 'The InvoiceId is wrong');
        GenJournalLine.Reset();
        GraphMgtCustomerPayments.SetCustomerPaymentsFilters(GenJournalLine);
        GenJournalLine.SetRange("Line No.", LineNo[2]);
        GenJournalLine.FindFirst();
        Assert.AreEqual(InvoiceNo, GenJournalLine."Applies-to Doc. No.", 'The InvoiceNo is wrong');
        Assert.AreEqual(InvoiceGUID, GenJournalLine."Applies-to Invoice Id", 'The InvoiceId is wrong');
        GenJournalLine.Reset();
        GraphMgtCustomerPayments.SetCustomerPaymentsFilters(GenJournalLine);
        GenJournalLine.SetRange("Line No.", LineNo[3]);
        GenJournalLine.FindFirst();
        Assert.AreEqual(InvoiceNo, GenJournalLine."Applies-to Doc. No.", 'The InvoiceNo is wrong');
        Assert.AreEqual(InvoiceGUID, GenJournalLine."Applies-to Invoice Id", 'The InvoiceId is wrong');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAppliesToDocIDErrorSync()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
        JournalName: Code[10];
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        InvoiceGUID: Guid;
        BlankGUID: Guid;
    begin
        // [FEATURE] [Applies-To]
        // [SCENARIO] Initialize line with AppliesToDocId that no longer exist
        Initialize();
        LibraryGraphJournalLines.Initialize();

        // [GIVEN] a customer payments journal batch name
        JournalName := CreateCustomerPaymentsJournal();

        // [GIVEN] a Customer
        CustomerNo := LibraryGraphJournalLines.CreateCustomer();

        // [GIVEN] a posted sales invoice
        InvoiceNo := LibraryGraphJournalLines.CreatePostedSalesInvoice(CustomerNo);

        // [WHEN] we create the line with AppliesToDocId that does not match to an invoice
        SalesInvoiceHeader.Reset();
        SalesInvoiceHeader.SetFilter("No.", InvoiceNo);
        SalesInvoiceHeader.FindFirst();
        InvoiceGUID := SalesInvoiceAggregator.GetSalesInvoiceHeaderId(SalesInvoiceHeader);
        SalesInvoiceHeader.Delete();
        Commit();

        // [THEN] creating the line should throw an error
        asserterror LibraryGraphJournalLines.CreateCustomerPayment(JournalName, CustomerNo, BlankGUID, '', InvoiceGUID, 0, '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestAppliesToDocNoSpecificSync()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GenJournalLine: Record "Gen. Journal Line";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
        JournalName: Code[10];
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        LineNo: Integer;
        InvoiceGUID: Guid;
        BlankGUID: Guid;
    begin
        // [FEATURE] [Applies-To]
        // [SCENARIO] Initialize line with AppliesToDocNo that no longer exist
        Initialize();
        LibraryGraphJournalLines.Initialize();

        // [GIVEN] a customer payments journal batch name
        JournalName := CreateCustomerPaymentsJournal();

        // [GIVEN] a Customer
        CustomerNo := LibraryGraphJournalLines.CreateCustomer();

        // [GIVEN] a posted sales invoice
        InvoiceNo := LibraryGraphJournalLines.CreatePostedSalesInvoice(CustomerNo);

        // [WHEN] we create the line with AppliesToDocNo that does not match to an invoice
        SalesInvoiceHeader.Reset();
        SalesInvoiceHeader.SetFilter("No.", InvoiceNo);
        SalesInvoiceHeader.FindFirst();
        InvoiceGUID := SalesInvoiceAggregator.GetSalesInvoiceHeaderId(SalesInvoiceHeader);
        SalesInvoiceHeader.Delete();
        Commit();

        LineNo := LibraryGraphJournalLines.CreateCustomerPayment(JournalName, CustomerNo, BlankGUID, InvoiceNo, BlankGUID, 0, '');

        // [THEN] creating the line should have the AppliesToDocNo and an empty AppliesToDocId
        GenJournalLine.Reset();
        GraphMgtCustomerPayments.SetCustomerPaymentsFilters(GenJournalLine);
        GenJournalLine.SetRange("Line No.", LineNo);
        GenJournalLine.FindFirst();
        Assert.AreEqual(InvoiceNo, GenJournalLine."Applies-to Doc. No.", 'The InvoiceNo is wrong');
        Assert.AreEqual(BlankGUID, GenJournalLine."Applies-to Invoice Id", 'The InvoiceId should be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestEmptyAppliesToDocNoBlanksIdToo()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GenJournalLine: Record "Gen. Journal Line";
        SalesInvoiceAggregator: Codeunit "Sales Invoice Aggregator";
        JournalName: Code[10];
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        InvoiceGUID: Guid;
        LineNo: Integer;
        BlankGUID: Guid;
    begin
        // [FEATURE] [Applies-To]
        // [SCENARIO] Setting the AppliesToDoc No to blank should also blank the AppliesToDoc Id
        Initialize();
        LibraryGraphJournalLines.Initialize();

        // [GIVEN] a customer payments journal batch name
        JournalName := CreateCustomerPaymentsJournal();

        // [GIVEN] a Customer
        CustomerNo := LibraryGraphJournalLines.CreateCustomer();

        // [GIVEN] a posted sales invoice
        InvoiceNo := LibraryGraphJournalLines.CreatePostedSalesInvoice(CustomerNo);

        // [WHEN] we create the line with AppliesToDocNo and then blank it
        SalesInvoiceHeader.Reset();
        SalesInvoiceHeader.SetFilter("No.", InvoiceNo);
        SalesInvoiceHeader.FindFirst();
        InvoiceGUID := SalesInvoiceAggregator.GetSalesInvoiceHeaderId(SalesInvoiceHeader);
        LineNo := LibraryGraphJournalLines.CreateCustomerPayment(JournalName, CustomerNo, BlankGUID, InvoiceNo, BlankGUID, 0, '');
        GenJournalLine.Reset();
        GraphMgtCustomerPayments.SetCustomerPaymentsFilters(GenJournalLine);
        GenJournalLine.SetRange("Line No.", LineNo);
        GenJournalLine.FindFirst();
        GenJournalLine.Validate("Applies-to Doc. No.", '');
        GenJournalLine.Modify();

        // [THEN] the AppliesToDocId should also be blank
        GenJournalLine.Reset();
        GraphMgtCustomerPayments.SetCustomerPaymentsFilters(GenJournalLine);
        GenJournalLine.SetRange("Line No.", LineNo);
        GenJournalLine.FindFirst();
        Assert.AreEqual(
          BlankGUID, GenJournalLine."Applies-to Invoice Id", 'Blanking the AppliesToDocNo should blank the AppliesToDocId too.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestHandleApiSetupFunction()
    var
        GenJournalLine: Record "Gen. Journal Line";
        JournalName: Code[10];
        AccountNo: Code[20];
        BlankGUID: Guid;
        LineNo: Integer;
    begin
        // [FEATURE] [Web Service]
        // [SCENARIO] When the web service is enabled the HandleApiSetup function should setup the required fields
        Initialize();
        LibraryGraphJournalLines.Initialize();

        // [GIVEN] a journal lines journal batch name
        JournalName := CreateJournalLinesJournal();

        // [GIVEN] a G/L Account with Direct Posting enabled
        AccountNo := LibraryGraphJournalLines.CreateAccount();

        // [GIVEN] a Journal Line with Account No but empty Account Id
        LineNo := LibraryGraphJournalLines.CreateJournalLine(JournalName, AccountNo, BlankGUID, 0, '');
        GenJournalLine.Reset();
        GraphMgtJournalLines.SetJournalLineFilters(GenJournalLine);
        GenJournalLine.SetRange("Journal Batch Name", JournalName);
        GenJournalLine.SetRange("Line No.", LineNo);
        GenJournalLine.FindFirst();
        GenJournalLine.Modify(false);

        // [WHEN] we run the functions of HandleApiSetup
        GraphMgtJournalLines.UpdateIds();

        // [THEN] the Id and AccountId should be set
        GenJournalLine.Reset();
        GraphMgtJournalLines.SetJournalLineFilters(GenJournalLine);
        GenJournalLine.SetRange("Journal Batch Name", JournalName);
        GenJournalLine.SetRange("Line No.", LineNo);
        GenJournalLine.FindFirst();
        Assert.AreEqual(false, IsNullGuid(GenJournalLine."Account Id"), 'The Account Id should not be empty');
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Graph Collect Mgt Journal Line");

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Graph Collect Mgt Journal Line");

        if not isInitialized then
            isInitialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Graph Collect Mgt Journal Line");
    end;

    local procedure CreateJournalLinesJournal(): Code[10]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        JournalName: Code[10];
    begin
        JournalName := LibraryUtility.GenerateRandomCode(GenJournalBatch.FieldNo(Name), DATABASE::"Gen. Journal Batch");
        LibraryAPIGeneralJournal.EnsureGenJnlBatchExists(GraphMgtJournal.GetDefaultJournalLinesTemplateName(), JournalName);
        GenJournalBatch.Get(GraphMgtJournal.GetDefaultJournalLinesTemplateName(), JournalName);
        GenJournalBatch."No. Series" := '';
        GenJournalBatch.Modify();
        exit(JournalName);
    end;

    local procedure CreateCustomerPaymentsJournal(): Code[10]
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        JournalName: Code[10];
    begin
        JournalName := LibraryUtility.GenerateRandomCode(GenJournalBatch.FieldNo(Name), DATABASE::"Gen. Journal Batch");
        LibraryAPIGeneralJournal.EnsureGenJnlBatchExists(GraphMgtJournal.GetDefaultCustomerPaymentsTemplateName(), JournalName);
        exit(JournalName);
    end;
}

