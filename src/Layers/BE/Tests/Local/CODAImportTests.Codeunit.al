codeunit 144015 "CODA Import Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryCODADataProvider: Codeunit "Library CODA Data Provider";
        LibraryCODAHelper: Codeunit "Library - CODA Helper";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        BBLEURTxt: Label 'BBL-EUR', Locked = true;
        WWBEURTxt: Label 'WWB-EUR', Locked = true;
        NBLTxt: Label 'NBL', Locked = true;
        EnterpriseNoTxt: Label '0448825928';
        ProtocolNoTxt: Label '200';
        VersionCodeTxt: Label '2';
        BankAccountNoTxt: Label '230002155541';
        SWIFTCodeTxt: Label 'GEBABEBB';
        IBANTxt: Label 'BE 29 7340 2822 2864';
        ExpectedValueAsZero: Label '0';
        InformationErr: Label 'Information must not be equal to Zero';
        ImportCodaFileErr: Label '%1 %2 of %3 %4 does not match %5 of %6 record.';
        ParseIdTxt: Label 'Header';
        EnterpriseNoLbl: Label '0058315707';
        ProtocolNo300Txt: Label '300';
        SWIFTCodeBBRUBEBBTxt: Label 'BBRUBEBB';
        CodaStatementEmptyErr: Label 'The CODA statement line table cannot be empty.';

    [Test]
    [HandlerFunctions('RequestPageHandlerPostCODAStatementLines,CODAStatementLineRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostCODAStatement()
    var
        CODAStatement: Record "CODA Statement";
        BankAccount: Record "Bank Account";
        BankAccountPage: TestPage "Bank Account List";
        CODAStatementListPage: TestPage "CODA Statement List";
        CODAStatementPage: TestPage "CODA Statement";
    begin
        // CODA - Print one of multiple coda statement
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=60073

        UpdateCompanyInformation('0058315707');
        UpdateBankAccountProtocol(BankAccount, 'NBL', '290', '1');
        UpdateElectronicBanking(true);

        Commit();

        BankAccountPage.OpenView();
        BankAccountPage.FILTER.SetFilter("No.", 'NBL');
        BankAccountPage."No.".Activate();
        DeleteAllCODALines();

        LibraryCODADataProvider.InsertSampleCODAStatement(CODAStatement, 'NBL');

        CODAStatement.FindFirst();

        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(false);
        // TFS ID 397033: Stan can print processed CODA statement
        // Handled by calling CODAStatementLineRequestPageHandler
        LibraryVariableStorage.Enqueue(true);

        Commit();

        // Process CODA Statement Lines
        CODAStatementListPage.OpenView();
        CODAStatementListPage.First();
        CODAStatementPage.Trap();

        CODAStatementListPage.View().Invoke();

        CODAStatementPage."Process CODA Statement Lines".Invoke();

        CODAStatementPage.Close();

        // Validation
        // BUG 367180: Amount must be zero and Unapplied Amount must be equal Statement Amount if a CODA statement lines applied to G/L account
        LibraryCODADataProvider.ValidateSampleCODAStatement(CODAStatement);
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerPostCODAStatementLines,MessageHandler,ConfirmHandler,GeneralJournalTemplateListModalPageHandler')]
    [Scope('OnPrem')]
    procedure TransferCODAStatementsToGeneralLedger()
    var
        BankAccount: Record "Bank Account";
        CODAStatement: Record "CODA Statement";
        ImportCODAStatement: Report "Import CODA Statement";
        CODAStatementListPage: TestPage "CODA Statement List";
        CODAStatementPage: TestPage "CODA Statement";
        FinancialJournalPage: TestPage "Financial Journal";
    begin
        // [SCENARIO 369875] Transfer statement amount from CODA statement to General Ledger

        UpdateCompanyInformation('0430018420');
        CreateBankAccount(BankAccount, 'KBC', '725', '737010689443');
        CreateGeneralJournalTemplate(BankAccount."No.", 'Financial', 'Bank Account');
        UpdateVendorBankAccount('50000', 'Test', '467538877123', true);
        UpdateElectronicBanking(true);

        // [GIVEN] CODA Statement with single line where Statement Amount = "X", Unapplied Amount = "X" and Amount = 0
        DeleteAllCODALines();
        ImportCODAStatement.SetBankAcc(BankAccount);
        ImportCODAStatement.InitializeRequest(LibraryCODADataProvider.ImportMultipleStatementsToCODAstatementDataFiles(1));
        ImportCODAStatement.Run();

        Commit();

        Assert.AreEqual(1, CODAStatement.Count, 'Line count failed');

        CODAStatementListPage.OpenView();
        CODAStatementListPage.First();

        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(false); // Default application
        LibraryVariableStorage.Enqueue(false); // Dont print
        CODAStatementPage.Trap();
        CODAStatementListPage.View().Invoke();

        // [GIVEN] Processed CODA Statement content
        CODAStatementPage."Process CODA Statement Lines".Invoke(); // Process CODA Statement lines

        // [WHEN] Transfer amounts to general ledger
        CODAStatementPage."Transfer to General Ledger".Invoke(); // Transfer to general ledger
        CODAStatementPage.Close();

        // [THEN] General journal line created with Amount = "X"
        FinancialJournalPage.OpenEdit();
        Assert.AreEqual('KBC', FinancialJournalPage."Bal. Account No.".Value, 'Balance Account No');
        Assert.AreEqual('Vendor', FinancialJournalPage."Account Type".Value, 'Account Type');
        Assert.AreEqual(Format(1352.48), FinancialJournalPage.Amount.Value, 'Amount');
        FinancialJournalPage.Close();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ImportMultipleStatementsToCODAstatement()
    var
        BankAccount: Record "Bank Account";
        CODAStatement: Record "CODA Statement";
        CODAStatementLine: Record "CODA Statement Line";
        ImportCODAStatement: Report "Import CODA Statement";
        StatementNo: Text;
    begin
        // Implementation of manual test case: CODA - Import multiple statements to CODA statement
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=60072

        // Create a bank account for KBC
        UpdateCompanyInformation('0430018420');
        UpdateElectronicBanking(true);
        CreateBankAccount(BankAccount, 'KBC', '725', '737010689443');
        CreateGeneralJournalTemplate(BankAccount."No.", 'Financial', 'Bank Account');

        UpdateVendorBankAccount('50000', 'Test', '467538877123', false);

        DeleteAllCODALines();
        // Run the processing only report with the two data files.
        ImportCODAStatement.SetBankAcc(BankAccount);
        ImportCODAStatement.InitializeRequest(LibraryCODADataProvider.ImportMultipleStatementsToCODAstatementDataFiles(1));
        ImportCODAStatement.Run();

        ImportCODAStatement.SetBankAcc(BankAccount);
        ImportCODAStatement.InitializeRequest(LibraryCODADataProvider.ImportMultipleStatementsToCODAstatementDataFiles(2));
        ImportCODAStatement.Run();

        Commit();

        Assert.AreEqual(33, CODAStatement.Count, 'Line count failed');

        // Pick CODA statement 025 from the list and check selected values
        StatementNo := '025';
        CODAStatement.Get(BankAccount."No.", StatementNo);
        Assert.AreNearlyEqual(CODAStatement."Balance Last Statement", 291730.22, 1, 'Balance Last Statement');

        CODAStatementLine.SetFilter("Bank Account No.", BankAccount."No.");
        CODAStatementLine.SetFilter("Statement No.", StatementNo);
        Assert.AreEqual(4, CODAStatementLine.Count, 'CODA statement Lines count failed');
        CODAStatementLine.FindFirst();
        Assert.AreEqual(10000, CODAStatementLine."Statement Line No.", 'CODAStatementLine."Statement Line No.');
        Assert.AreEqual(CODAStatementLine.ID::Movement, CODAStatementLine.ID, 'CODAStatementLine.ID');
        Assert.AreEqual(CODAStatementLine.Type::Global, CODAStatementLine.Type, 'CODAStatementLine.Type');
        Assert.AreEqual('OL9407316JBBO', CODAStatementLine."Bank Reference No.", 'CODAStatementLine."Bank Reference No."');
        Assert.AreEqual('EUBCRECL', CODAStatementLine."Ext. Reference No.", 'CODAStatementLine."Ext. Reference No."');
        Assert.AreEqual(7408, CODAStatementLine."Statement Amount", 'CODAStatementLine."Statement Amount"');
        Assert.AreEqual(CODAStatementLine."Statement Amount", CODAStatementLine."Unapplied Amount",
          'CODAStatementLine."Unapplied Amount"');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ImportAccountTypeIsBankAccountInTransactionCodingLine()
    var
        BankAccount: Record "Bank Account";
        CODAStatement: Record "CODA Statement";
    begin
        // CODA -Verify CODA statement line when Account Type is Bank Account in a transaction coding line
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=60257
        FindBankAccount(BankAccount, BBLEURTxt);
        Commit();
        ImportCODAWithSpecificAccountType(BankAccount, 'Bank Account', BBLEURTxt);

        CODAStatement.FindFirst();
        Assert.AreEqual(1, CODAStatement.Count, 'Line count failed');
        Assert.AreEqual(BankAccount."No.", CODAStatement."Bank Account No.", 'BankAccount."No."');
        Assert.AreEqual('084', CODAStatement."Statement No.", '"Statement No."');
        Assert.AreEqual(748802.07, CODAStatement."Statement Ending Balance", '"Statement Ending Balance"');
        Assert.AreEqual(20090421D, CODAStatement."Statement Date", '"Statement Date"');
        Assert.AreEqual(746171.93, CODAStatement."Balance Last Statement", '"Balance Last Statement"');
        Assert.AreEqual(1, CODAStatement."CODA Statement No.", '"CODA Statement No."');
        Assert.AreEqual(0, CODAStatement.Information, 'Information');
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerPostCODAStatementLines,MessageHandler')]
    [Scope('OnPrem')]
    procedure ImportAccountTypeIsBlankInTransactionCodingLine()
    var
        BankAccount: Record "Bank Account";
        CODAStatement: Record "CODA Statement";
        CODAStatementLine: Record "CODA Statement Line";
        BankAccountPage: TestPage "Bank Account List";
        CODAStatementListPage: TestPage "CODA Statement List";
        CODAStatementPage: TestPage "CODA Statement";
        PostingDate: Date;
    begin
        // CODA -Verify CODA statement line when Account Type is Blank in a transaction coding line
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=60261

        ImportCODAWithSpecificAccountType(BankAccount, '', '');

        CODAStatement.FindFirst();
        Assert.AreEqual(1, CODAStatement.Count, 'Line count failed');
        Assert.AreEqual(BankAccount."No.", CODAStatement."Bank Account No.", 'BankAccount."No."');
        Assert.AreEqual('084', CODAStatement."Statement No.", '"Statement No."');
        Assert.AreEqual(748802.07, CODAStatement."Statement Ending Balance", '"Statement Ending Balance"');
        Assert.AreEqual(20090421D, CODAStatement."Statement Date", '"Statement Date"');
        Assert.AreEqual(746171.93, CODAStatement."Balance Last Statement", '"Balance Last Statement"');
        Assert.AreEqual(1, CODAStatement."CODA Statement No.", '"CODA Statement No."');
        Assert.AreEqual(0, CODAStatement.Information, 'Information');

        // Pick CODA statement 084 from the list and check selected values

        CODAStatementLine.SetFilter("Bank Account No.", BankAccount."No.");
        CODAStatementLine.SetFilter("Statement No.", CODAStatement."Statement No.");
        Assert.AreEqual(4, CODAStatementLine.Count, 'CODA statement Lines count failed');
        CODAStatementLine.FindFirst();
        Assert.AreEqual(10000, CODAStatementLine."Statement Line No.", 'CODAStatementLine."Statement Line No.');
        Assert.AreEqual(CODAStatementLine.ID::Movement, CODAStatementLine.ID, 'CODAStatementLine.ID');
        Assert.AreEqual(CODAStatementLine.Type::Global, CODAStatementLine.Type, 'CODAStatementLine.Type');
        Assert.AreEqual(CODAStatementLine."Account Type"::"G/L Account", CODAStatementLine."Account Type",
          'CODAStatementLine."Account Type"');
        Assert.AreEqual('0000900000404        ', CODAStatementLine."Bank Reference No.", 'CODAStatementLine."Bank Reference No."');
        Assert.AreEqual('', CODAStatementLine."Ext. Reference No.", 'CODAStatementLine."Ext. Reference No."');
        Assert.AreEqual(2689.84, CODAStatementLine."Statement Amount", 'CODAStatementLine."Statement Amount"');
        Assert.AreEqual(CODAStatementLine."Statement Amount", CODAStatementLine."Unapplied Amount",
          'CODAStatementLine."Unapplied Amount"');

        // Process the data.
        CODAStatementListPage.Trap();
        BankAccountPage.OpenView();
        BankAccountPage.FILTER.SetFilter("No.", BankAccount."No.");
        BankAccountPage."No.".Activate();
        BankAccountPage."CODA S&tatements".Invoke();
        CODAStatementListPage.First();

        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(false); // Default application
        LibraryVariableStorage.Enqueue(false); // Dont print
        CODAStatementPage.Trap();
        CODAStatementListPage.View().Invoke();

        // validate the processed CODA Statement content
        CODAStatementPage."Process CODA Statement Lines".Invoke();
        CODAStatementPage.StmtLines.First();
        CODAStatementPage.StmtLines.Next();
        Assert.AreEqual(' ', CODAStatementPage.StmtLines."Application Status".Value, 'Application Status');
        Evaluate(PostingDate, Format(CODAStatementPage.StmtLines."Posting Date"));
        Assert.AreEqual(20090421D, PostingDate, 'Posting Date');
        Assert.AreEqual(' ', CODAStatementPage.StmtLines."Document Type".Value, 'Document Type');
        Assert.AreEqual('G/L Account', CODAStatementPage.StmtLines."Account Type".Value, 'Account Type');
        Assert.AreEqual(Format(0.0, 0, '<Precision,2:3><Standard Format,0>'),
          CODAStatementPage.StmtLines.Amount.Value, 'Amount');
        Assert.AreEqual(Format(-59.7, 0, '<Precision,2:3><Standard Format,0>'),
          CODAStatementPage.StmtLines."Statement Amount".Value, 'Statement Amount');
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerPostCODAStatementLines,MessageHandler')]
    [Scope('OnPrem')]
    procedure ImportAccountTypeIsCustomerInTransactionCodingLine()
    var
        BankAccount: Record "Bank Account";
        CODAStatement: Record "CODA Statement";
        BankAccountPage: TestPage "Bank Account List";
        CODAStatementListPage: TestPage "CODA Statement List";
        CODAStatementPage: TestPage "CODA Statement";
        PostingDate: Date;
    begin
        // CODA -Verify CODA statement line when Account Type is Customer in a transaction coding line
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=60259

        ImportCODAWithSpecificAccountType(BankAccount, 'Customer', '60000');

        CODAStatement.FindFirst();
        Assert.AreEqual(1, CODAStatement.Count, 'Line count failed');
        Assert.AreEqual(BankAccount."No.", CODAStatement."Bank Account No.", 'BankAccount."No."');
        Assert.AreEqual('084', CODAStatement."Statement No.", '"Statement No."');
        Assert.AreEqual(748802.07, CODAStatement."Statement Ending Balance", '"Statement Ending Balance"');
        Assert.AreEqual(20090421D, CODAStatement."Statement Date", '"Statement Date"');
        Assert.AreEqual(746171.93, CODAStatement."Balance Last Statement", '"Balance Last Statement"');
        Assert.AreEqual(1, CODAStatement."CODA Statement No.", '"CODA Statement No."');
        Assert.AreEqual(0, CODAStatement.Information, 'Information');

        // Process the data.
        CODAStatementListPage.Trap();
        BankAccountPage.OpenView();
        BankAccountPage.FILTER.SetFilter("No.", BankAccount."No.");
        BankAccountPage."No.".Activate();
        BankAccountPage."CODA S&tatements".Invoke();
        CODAStatementListPage.First();

        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(false); // Default application
        LibraryVariableStorage.Enqueue(false); // Dont print
        CODAStatementPage.Trap();
        CODAStatementListPage.View().Invoke();

        // validate the processed CODA Statement content
        CODAStatementPage."Process CODA Statement Lines".Invoke();
        CODAStatementPage.StmtLines.First();
        CODAStatementPage.StmtLines.Next();
        Assert.AreEqual('Partly applied', CODAStatementPage.StmtLines."Application Status".Value, 'Application Status');
        Evaluate(PostingDate, Format(CODAStatementPage.StmtLines."Posting Date"));
        Assert.AreEqual(20090421D, PostingDate, 'Posting Date');
        Assert.AreEqual('Payment', CODAStatementPage.StmtLines."Document Type".Value, 'Document Type');
        Assert.AreEqual('Customer', CODAStatementPage.StmtLines."Account Type".Value, 'Account Type');
        Assert.AreEqual('60000', CODAStatementPage.StmtLines."Account No.".Value, 'Account No.');
        // ala Assert.AreEqual('Blanemark Hifi Shop',CODAStatementPage.StmtLines.Description.VALUE,'Description');
        Assert.AreEqual(Format(-59.7, 0, '<Precision,2:3><Standard Format,0>'),
          CODAStatementPage.StmtLines.Amount.Value, 'Amount');
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerPostCODAStatementLines,MessageHandler')]
    [Scope('OnPrem')]
    procedure ImportAccountTypeIsVendorInTransactionCodingLine()
    var
        BankAccount: Record "Bank Account";
        CODAStatement: Record "CODA Statement";
        BankAccountPage: TestPage "Bank Account List";
        CODAStatementListPage: TestPage "CODA Statement List";
        CODAStatementPage: TestPage "CODA Statement";
        PostingDate: Date;
    begin
        // CODA -Verify CODA statement line when Account Type is Vendor in a transaction coding line
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=60258

        ImportCODAWithSpecificAccountType(BankAccount, 'Vendor', '62000');

        CODAStatement.FindFirst();
        Assert.AreEqual(1, CODAStatement.Count, 'Line count failed');
        Assert.AreEqual(BankAccount."No.", CODAStatement."Bank Account No.", 'BankAccount."No."');
        Assert.AreEqual('084', CODAStatement."Statement No.", '"Statement No."');
        Assert.AreEqual(748802.07, CODAStatement."Statement Ending Balance", '"Statement Ending Balance"');
        Assert.AreEqual(20090421D, CODAStatement."Statement Date", '"Statement Date"');
        Assert.AreEqual(746171.93, CODAStatement."Balance Last Statement", '"Balance Last Statement"');
        Assert.AreEqual(1, CODAStatement."CODA Statement No.", '"CODA Statement No."');
        Assert.AreEqual(0, CODAStatement.Information, 'Information');

        // Process the data.
        CODAStatementListPage.Trap();
        BankAccountPage.OpenView();
        BankAccountPage.FILTER.SetFilter("No.", BankAccount."No.");
        BankAccountPage."No.".Activate();
        BankAccountPage."CODA S&tatements".Invoke();
        CODAStatementListPage.FILTER.SetFilter("Bank Account No.", BankAccount."No.");

        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(false); // Default application
        LibraryVariableStorage.Enqueue(false); // Dont print
        CODAStatementPage.Trap();
        CODAStatementListPage.View().Invoke();

        // validate the processed CODA Statement content
        CODAStatementPage."Process CODA Statement Lines".Invoke();
        CODAStatementPage.StmtLines.First();
        CODAStatementPage.StmtLines.Next();
        Assert.AreEqual('Partly applied', CODAStatementPage.StmtLines."Application Status".Value, 'Application Status');
        Evaluate(PostingDate, Format(CODAStatementPage.StmtLines."Posting Date"));
        Assert.AreEqual(20090421D, PostingDate, 'Posting Date');
        Assert.AreEqual('Payment', CODAStatementPage.StmtLines."Document Type".Value, 'Document Type');
        Assert.AreEqual('Vendor', CODAStatementPage.StmtLines."Account Type".Value, 'Account Type');
        Assert.AreEqual('62000', CODAStatementPage.StmtLines."Account No.".Value, 'Account No.');
        Assert.AreEqual(Format(-59.7, 0, '<Precision,2:3><Standard Format,0>'),
          CODAStatementPage.StmtLines.Amount.Value, 'Amount');
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerPostCODAStatementLines,MessageHandler')]
    [Scope('OnPrem')]
    procedure ImportAccountTypeIsGLAccountInTransactionCodingLine()
    var
        BankAccount: Record "Bank Account";
        CODAStatement: Record "CODA Statement";
        GLAccount: Record "G/L Account";
        BankAccountPage: TestPage "Bank Account List";
        CODAStatementListPage: TestPage "CODA Statement List";
        CODAStatementPage: TestPage "CODA Statement";
        PostingDate: Date;
        Amount: Decimal;
    begin
        // CODA -Verify CODA statement line when Account Type is G/L Account in a transaction coding line
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=60260

        ImportCODAWithSpecificAccountType(BankAccount, 'G/L Account', '499999');

        CODAStatement.FindFirst();
        Assert.AreEqual(1, CODAStatement.Count, 'Line count failed');
        Assert.AreEqual(BankAccount."No.", CODAStatement."Bank Account No.", 'BankAccount."No."');
        Assert.AreEqual('084', CODAStatement."Statement No.", '"Statement No."');
        Assert.AreEqual(748802.07, CODAStatement."Statement Ending Balance", '"Statement Ending Balance"');
        Assert.AreEqual(20090421D, CODAStatement."Statement Date", '"Statement Date"');
        Assert.AreEqual(746171.93, CODAStatement."Balance Last Statement", '"Balance Last Statement"');
        Assert.AreEqual(1, CODAStatement."CODA Statement No.", '"CODA Statement No."');
        Assert.AreEqual(0, CODAStatement.Information, 'Information');

        // Process the data.
        CODAStatementListPage.Trap();
        BankAccountPage.OpenView();
        BankAccountPage.FILTER.SetFilter("No.", BankAccount."No.");
        BankAccountPage."No.".Activate();
        BankAccountPage."CODA S&tatements".Invoke();
        CODAStatementListPage.FILTER.SetFilter("Bank Account No.", BankAccount."No.");

        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(false); // Default application
        LibraryVariableStorage.Enqueue(false); // Dont print
        CODAStatementPage.Trap();
        CODAStatementListPage.View().Invoke();

        // validate the processed CODA Statement content
        CODAStatementPage."Process CODA Statement Lines".Invoke();
        CODAStatementPage.StmtLines.First();
        CODAStatementPage.StmtLines.Next();
        Assert.AreEqual('Partly applied', CODAStatementPage.StmtLines."Application Status".Value, 'Application Status');
        Evaluate(PostingDate, Format(CODAStatementPage.StmtLines."Posting Date"));
        Assert.AreEqual(20090421D, PostingDate, 'Posting Date');
        Assert.AreEqual('G/L Account', CODAStatementPage.StmtLines."Account Type".Value, 'Account Type');
        Assert.AreEqual('499999', CODAStatementPage.StmtLines."Account No.".Value, 'Account No.');
        GLAccount.Get('499999');
        Assert.AreEqual(GLAccount.Name, CODAStatementPage.StmtLines.Description.Value, 'Description');
        // BUG 367180: Amount must be zero if a CODA statement line applied to G/L account
        Amount := 0;
        Assert.AreEqual(Format(Amount, 0, '<Precision,2:3><Standard Format,0>'),
          CODAStatementPage.StmtLines.Amount.Value, 'Amount');
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerPostCODAStatementLines,MessageHandler')]
    [Scope('OnPrem')]
    procedure PrintOneOfMultipleCODAStatements()
    var
        BankAccount: Record "Bank Account";
        CODAStatement: Record "CODA Statement";
        ImportCODAStatement: Report "Import CODA Statement";
        CODAStatementListPage: TestPage "CODA Statement List";
        CODAStatementPage: TestPage "CODA Statement";
    begin
        // CODA - Print one of multiple coda statement
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=60073

        UpdateCompanyInformation('0058315707');
        FindBankAccount(BankAccount, NBLTxt);
        UpdateBankAccountProtocol(BankAccount, NBLTxt, '290', '1');
        BankAccount."Bank Account No." := '290004614187';
        BankAccount.Modify();
        Commit();
        UpdateElectronicBanking(true);

        Commit();

        // Run the processing only report with the data file.
        DeleteAllCODALines();
        ImportCODAStatement.SetBankAcc(BankAccount);
        ImportCODAStatement.InitializeRequest(LibraryCODADataProvider.PrintOneOfMultipleCODAStatementsDataFile());
        ImportCODAStatement.Run();

        Commit();

        CODAStatement.FindFirst();
        Assert.AreEqual(33, CODAStatement.Count, 'Line count failed');

        // Process CODA Statement Lines
        CODAStatementListPage.OpenView();
        CODAStatementListPage.First();
        CODAStatementPage.Trap();

        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        CODAStatementListPage.View().Invoke();

        // TODO : This action exposes a productbug. This test should continue on to
        // validate the processed CODA Statement content
        asserterror CODAStatementPage."Process CODA Statement Lines".Invoke();
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerPostCODAStatementLines,MessageHandler')]
    [Scope('OnPrem')]
    procedure VerifyPostingOfCODAStatementLines()
    var
        BankAccount: Record "Bank Account";
        ImportCODAStatement: Report "Import CODA Statement";
        CODAStatementListPage: TestPage "CODA Statement List";
        CODAStatementPage: TestPage "CODA Statement";
    begin
        // Implementation of manual test case: CODA - Verify the process of posting CODA statement lines
        // http://vstfnav:8080/tfs/web/wi.aspx?pcguid=9a2ffec1-5411-458b-b788-8c4a5507644c&id=60154

        // Create a bankaccount for KBC
        UpdateCompanyInformation('0477997984');
        UpdateElectronicBanking(true);

        // Update bank account information
        FindBankAccount(BankAccount, WWBEURTxt);
        BankAccount."Bank Account No." := '734020020001';
        BankAccount."Protocol No." := '725';
        BankAccount."Version Code" := '2';
        BankAccount."Bank Branch No." := '734';
        BankAccount."SWIFT Code" := 'KREDBEBB';
        BankAccount.Modify();

        // Run the processing only report with the two data files.
        DeleteAllCODALines();
        ImportCODAStatement.SetBankAcc(BankAccount);
        ImportCODAStatement.InitializeRequest(LibraryCODADataProvider.OntVangenCODA20090416DataFile());
        ImportCODAStatement.Run();

        Commit();

        CODAStatementListPage.OpenView();
        CODAStatementListPage.First();

        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(false); // Default application
        LibraryVariableStorage.Enqueue(false); // Dont print
        CODAStatementPage.Trap();
        CODAStatementListPage.View().Invoke();

        // validate the processed CODA Statement content
        CODAStatementPage."Process CODA Statement Lines".Invoke(); // Process CODA Statement lines
    end;

    [Test]
    [HandlerFunctions('RequestPageHandlerPostCODAStatementLines,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostCodedBankStatementWhenMultipleEntriesIndirectlyApplied()
    var
        BankAccount: Record "Bank Account";
        CODAStatement: Record "CODA Statement";
        CODAStatementLine: Record "CODA Statement Line";
        TempTransactionCoding: Record "Transaction Coding" temporary;
        ImportCODAStatement: Report "Import CODA Statement";
    begin
        // [SCENARIO 373926] CODA statement has correct values of status, unapplied amount, amount and statement amount
        // [SCENARIO 373926] after running "Post CODA Stmt. Line" action with transaction coding setup for multiple indirect relation

        // [GIVEN] Company information with "Enterprise No." to match the CODA file
        UpdateCompanyInformation('0820.877.643');
        UpdateElectronicBanking(true);

        // [GIVEN] A bank account with all the information matched the CODA file
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount."Bank Account No." := '7340 2822 2864';
        BankAccount."Protocol No." := '725';
        BankAccount."Version Code" := '2';
        BankAccount."Bank Branch No." := '734';
        BankAccount."SWIFT Code" := 'KREDBEBB';
        BankAccount.IBAN := 'BE 29 7340 2822 2864';
        BankAccount."Country/Region Code" := 'BE';
        BankAccount.Modify();

        // [GIVEN] Setup transaction coding with Globalisation Code = Detail to have an "indirect application"
        ReplaceTransactionCodingScenario373926(TempTransactionCoding);

        // [GIVEN] Import CODA statement from file
        DeleteAllCODALines();
        ImportCODAStatement.SetBankAcc(BankAccount);
        ImportCODAStatement.InitializeRequest(LibraryCODADataProvider.OntVangenCODAScenario373926DataFile());
        ImportCODAStatement.Run();
        Commit();

        // [GIVEN] Open the imported CODA statement
        CODAStatement.FindFirst();
        CODAStatement.SetRecFilter();
        LibraryVariableStorage.Enqueue(false); // Default application for "Post CODA Stmt. Lines"
        LibraryVariableStorage.Enqueue(false); // Dont print for "Post CODA Stmt. Lines"

        // [WHEN] Process CODA statement lines
        REPORT.RunModal(REPORT::"Post CODA Stmt. Lines", true, false, CODAStatement);

        // [THEN] Application status, unapplied amount, amount and statement amount are correct for all CODA statement lines after processing
        CODAStatementLine.SetRange("Bank Account No.", CODAStatement."Bank Account No.");
        CODAStatementLine.SetRange("Statement No.", CODAStatement."Statement No.");
        CODAStatementLine.SetRange(ID, CODAStatementLine.ID::Movement);
        CODAStatementLine.FindFirst();
        Assert.RecordCount(CODAStatementLine, 8);
        VerifyCODAStatementLine(CODAStatementLine, CODAStatementLine."Application Status"::"Indirectly applied", -837.63, 0, -837.63);
        VerifyCODAStatementLine(CODAStatementLine, CODAStatementLine."Application Status"::"Partly applied", -832.34, 0, -832.34);
        VerifyCODAStatementLine(CODAStatementLine, CODAStatementLine."Application Status"::"Partly applied", -5.29, 0, -5.29);
        VerifyCODAStatementLine(CODAStatementLine, CODAStatementLine."Application Status"::" ", -78.93, 0, -78.93);
        VerifyCODAStatementLine(CODAStatementLine, CODAStatementLine."Application Status"::"Indirectly applied", -1.5, 0, -1.5);
        VerifyCODAStatementLine(CODAStatementLine, CODAStatementLine."Application Status"::"Partly applied", -1.5, 0, -1.5);
        VerifyCODAStatementLine(CODAStatementLine, CODAStatementLine."Application Status"::"Indirectly applied", -0.3, 0, -0.3);
        VerifyCODAStatementLine(CODAStatementLine, CODAStatementLine."Application Status"::"Partly applied", -0.3, 0, -0.3);
        LibraryVariableStorage.AssertEmpty();

        // Tear down
        RestoreTransactionCoding(TempTransactionCoding);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckInformationValueIsShowingInCODAStatement()
    var
        BankAccount: Record "Bank Account";
        CODAStatement: Record "CODA Statement";
        ImportCODAStatement: Report "Import CODA Statement";
    begin
        // [SCENARIO 469446] Import the CODA file and verify the information in the CODA statement Lines are showing values in the BE.
        // [GIVEN] Update Enterprise No. in the Company Information.
        UpdateCompanyInformation(EnterpriseNoTxt);

        // [GIVEN] Find and create a new Bank Account.
        FindBankAccount(BankAccount, LibraryRandom.RandText(5));

        // [GIVEN] Updated the Bank Account Details.
        UpdateBankAccountDetails(BankAccount);

        // [THEN] Delete the Existing CODA Statements.
        DeleteAllCODALines();

        // [GIVEN] Run the Processing only report to import the sample data files.
        ImportCODAStatement.SetBankAcc(BankAccount);
        ImportCODAStatement.InitializeRequest(LibraryCODADataProvider.ImportAccountTypeTestDataFile());
        ImportCODAStatement.Run();

        // [THEN] Find the CODA Statement. 
        CODAStatement.FindFirst();

        // [VERIFY] Information must not be equal to zero.
        Assert.AreNotEqual(
            ExpectedValueAsZero,
            GetInformationFromCODAStatement(CODAStatement."Bank Account No.", CODAStatement."Statement No."),
            InformationErr);

        Assert.AreNotEqual(
            ExpectedValueAsZero,
            GetInformationFromCODAStatementLine(CODAStatement."Bank Account No.", CODAStatement."Statement No."),
            InformationErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyCodaFileImportErrorContent()
    var
        BankAccount: Record "Bank Account";
        ImportCODAStatement: Report "Import CODA Statement";
    begin
        // [SCENARIO 490155] Incorrect errors when Bank Account info does not match CODA File contents.

        // [GIVEN] Update Company Information.
        UpdateCompanyInformation(EnterpriseNoTxt);

        // [GIVEN] Create a bank account and configure according Coda File.
        FindBankAccount(BankAccount, LibraryRandom.RandText(5));
        UpdateBankAccountDetails(BankAccount);
        UpdateBankAccountVersionCode(BankAccount);
        UpdateElectronicBanking(true);

        // [GIVEN] Run Import coda Statement Batch to Import the Coda File.
        ImportCODAStatement.SetBankAcc(BankAccount);
        ImportCODAStatement.InitializeRequest(LibraryCODADataProvider.ImportAccountTypeTestDataFile());
        asserterror ImportCODAStatement.Run();

        // [VERIFY] verify the expected Coda file Import error message.
        Assert.ExpectedError(
            StrSubstNo(
                ImportCodaFileErr,
                BankAccount.FieldCaption("Version Code"),
                BankAccount."Version Code",
                BankAccount.TableCaption(),
                BankAccount."No.",
                VersionCodeTxt, ParseIdTxt));
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure ImportCODAFileWithMoreThanOneStatement()
    var
        BankAccount: Record "Bank Account";
        CODAStatement: Record "CODA Statement";
        ImportCODAStatement: Report "Import CODA Statement";
    begin
        // [SCENARIO 557240] Import Coda File with more than one statement

        // [GIVEN] Update Enterprise No. in Company Information.
        UpdateCompanyInformation(EnterpriseNoLbl);

        // [GIVEN] Create Bank Account with Version Code 2 and Protocol No. 300.
        CreateBankAccounInformation(BankAccount);

        // [THEN] Delete the Existing CODA Statements.
        DeleteAllCODALines();

        // [GIVEN] Run the Processing only report to import the sample data files.
        ImportCODAStatement.SetBankAcc(BankAccount);
        ImportCODAStatement.InitializeRequest(LibraryCODADataProvider.OnCODAScenario557240DataFile());
        ImportCODAStatement.Run();

        Commit();

        // [THEN] Find the CODA Statement. 
        CODAStatement.FindFirst();

        // [THEN] CODA Statement file sucessfully Import with 2 CODA Statement and Information must not be equal to zero.
        Assert.AreNotEqual(
            ExpectedValueAsZero,
            GetInformationFromCODAStatement(CODAStatement."Bank Account No.", CODAStatement."Statement No."),
            InformationErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,RequestPageHandlerPostCODAStatementLines,PostedSalesInvUpdateUpdateOKModalPageHandler')]
    procedure ProcessCODAStmtWithMultipleInvoicesHavingSameAmountAndStatusSetToApplied()
    var
        BankAccount: Record "Bank Account";
        CustomerBankAccount: Record "Customer Bank Account";
        CodaStatement: Record "CODA Statement";
        CodaStatementLine: Record "CODA Statement Line";
        TransactionCoding: Record "Transaction Coding";
        StatementMessage: Text;
        DocumentNo: Code[20];
    begin
        // [SCENARIO 560840] Process CODA statement lines with multiple invoices having the same amount, and verify that the status is set to "Applied."

        // [GIVEN] Create New Transaction Coding.
        TransactionCoding.DeleteAll();
        InsertTransactionCoding(1, 50, 0, TransactionCoding."Globalisation Code"::Detail, TransactionCoding."Account Type"::Customer, '');
        DeleteAllCODALines();

        // [GIVEN] Create Bank Account and Set IBAN according to CODA file.
        CreateBankAccounInformation(BankAccount);
        BankAccount.Validate(IBAN, 'BE04310075819431');
        BankAccount.Modify(true);

        // [GIVEN] Create Customer Bank Account and Set IBAN according to CODA file.
        LibraryCODAHelper.CreateCustomerBankAccount(CustomerBankAccount);
        CustomerBankAccount.Validate(IBAN, 'BE14001021457183');
        CustomerBankAccount.Modify(true);

        // [GIVEN] Run the Processing only report to import the sample data files.
        RunImportCodaStatementReport(BankAccount);

        // [GIVEN] Create and Post Sales Invoice.
        CreateAndPostSalesDocument(CustomerBankAccount."Customer No.");
        EnqueueMultipleValues();

        // [WHEN] Process CODA statement line via CODA Statement.
        OpenCodaStatementPageAndProcessCodaStmtLines(BankAccount."No.");

        // [THEN] Verify that the CODA statement line status is "Applied.".
        CodaStatementLine.SetRange("Bank Account No.", BankAccount."No.");
        CodaStatementLine.SetRange("Application Status", CodaStatementLine."Application Status"::Applied);
        Assert.IsTrue(CodaStatementLine.FindFirst(), CodaStatementEmptyErr);

        // [GIVEN] Find the statement message and Delete CODA Statement.
        StatementMessage := CodaStatementLine."Statement Message";
        StatementMessage := CopyStr(StatementMessage, 1, StrPos(StatementMessage, ' ') - 1);
        CodaStatement.Get(CodaStatementLine."Bank Account No.", CodaStatementLine."Statement No.");
        CodaStatement.Delete(true);

        // [GIVEN] Create and Post Sales Invoice.
        DocumentNo := CreateAndPostSalesDocument(CustomerBankAccount."Customer No.");

        LibraryVariableStorage.Enqueue(StatementMessage);

        // [GIVEN] Open Posted Sales Invoice Page and Update Payment Reference No.
        OpenPostedSalesInvoiceAndUpdatePaymentReference(DocumentNo);

        // [GIVEN] Open 
        EnqueueMultipleValues();

        // [GIVEN] Run the Processing only report to import the sample data files.
        RunImportCodaStatementReport(BankAccount);

        // [WHEN] Process CODA statement line via CODA Statement.
        Commit();
        OpenCodaStatementPageAndProcessCodaStmtLines(BankAccount."No.");

        // [THEN] Verify that the CODA statement line status is "Applied.".
        CodaStatementLine.SetRange("Bank Account No.", BankAccount."No.");
        CodaStatementLine.SetRange("Application Status", CodaStatementLine."Application Status"::Applied);
        Assert.IsTrue(CodaStatementLine.FindFirst(), CodaStatementEmptyErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,RequestPageHandlerPostCODAStatementLines,ConfirmHandler,PostedSalesInvUpdateUpdateOKModalPageHandler,GeneralJournalTemplateListModalPageHandler')]
    procedure FinancialJournalCreatedProcessCODAStmtWithMultipleInvoices()
    var
        BankAccount: Record "Bank Account";
        CustomerBankAccount: Record "Customer Bank Account";
        CodaStatement: Record "CODA Statement";
        CodaStatementLine: Record "CODA Statement Line";
        TransactionCoding: Record "Transaction Coding";
        GenJournalLine: Record "Gen. Journal Line";
        FinancialJournalPage: TestPage "Financial Journal";
        StatementMessage: Text;
        DocumentNo: Code[20];
    begin
        // [SCENARIO 598558] Process CODA statement lines with multiple invoices and lines transferred to Financial Journal

        // [GIVEN] Create New Transaction Coding.
        TransactionCoding.DeleteAll();
        InsertTransactionCoding(1, 50, 0, TransactionCoding."Globalisation Code"::Detail, TransactionCoding."Account Type"::Customer, '');
        DeleteAllCODALines();
        BankAccount.DeleteAll();
        GenJournalLine.DeleteAll();

        // [GIVEN] Create Bank Account and Set IBAN according to CODA file.
        UpdateCompanyInformation('0430018420');
        CreateBankAccount(BankAccount, 'KBC', '300', '737010689443');
        CreateGeneralJournalTemplate(BankAccount."No.", 'Financial', 'Bank Account');
        BankAccount.Validate("SWIFT Code", 'BBRUBEBB');
        BankAccount.Validate("Version Code", '2');
        BankAccount.Validate(IBAN, 'BE04310075819431');
        BankAccount.Modify(true);

        // [GIVEN] Create Customer Bank Account and Set IBAN according to CODA file.
        LibraryCODAHelper.CreateCustomerBankAccount(CustomerBankAccount);
        CustomerBankAccount.Validate(IBAN, 'BE14001021457183');
        CustomerBankAccount.Modify(true);

        // [GIVEN] Run the Processing only report to import the sample data files.
        RunImportCodaStatementReport(BankAccount);

        // [GIVEN] Create and Post Sales Invoice.
        CreateAndPostSalesDocumentSpecificAmount(CustomerBankAccount."Customer No.", 11547.83);
        EnqueueMultipleValues();

        // [WHEN] Process CODA statement line via CODA Statement.
        OpenCodaStatementPageAndProcessCodaStmtLines(BankAccount."No.");

        // [THEN] Verify that the CODA statement line status is "Applied.".
        CodaStatementLine.SetRange("Bank Account No.", BankAccount."No.");
        CodaStatementLine.SetFilter("Application Status", '%1|%2', CodaStatementLine."Application Status"::Applied, CodaStatementLine."Application Status"::"Partly applied");
        Assert.IsTrue(CodaStatementLine.FindFirst(), CodaStatementEmptyErr);

        // [GIVEN] Find the statement message and Delete CODA Statement.
        StatementMessage := CodaStatementLine."Statement Message";
        StatementMessage := CopyStr(StatementMessage, 1, StrPos(StatementMessage, ' ') - 1);
        CodaStatement.Get(CodaStatementLine."Bank Account No.", CodaStatementLine."Statement No.");
        CodaStatement.Delete(true);

        // [GIVEN] Create and Post Sales Invoice.
        DocumentNo := CreateAndPostSalesDocument(CustomerBankAccount."Customer No.");
        LibraryVariableStorage.Enqueue(StatementMessage);

        // [GIVEN] Open Posted Sales Invoice Page and Update Payment Reference No.
        OpenPostedSalesInvoiceAndUpdatePaymentReference(DocumentNo);
        EnqueueMultipleValues();

        // [GIVEN] Run the Processing only report to import the sample data files.
        RunImportCodaStatementReport(BankAccount);
        Commit();

        // [WHEN] Process CODA statement line via CODA Statement.
        OpenCodaStatementPageAndProcessCodaStmtLines(BankAccount."No.");
        LibraryVariableStorage.AssertEmpty();

        // DELETE ALL UNAPPLIED CODA STATEMENTS;
        CodaStatementLine.SetRange("Application Status", CodaStatementLine."Application Status"::" ");
        CodaStatementLine.DeleteAll();

        OpenCodaStatementPageAndTransferToGeneralLedger(BankAccount."No.");

        // [THEN] General journal line created with Amount = "X"
        FinancialJournalPage.OpenEdit();
        Assert.AreEqual('KBC', FinancialJournalPage."Bal. Account No.".Value, 'Balance Account No');
        Assert.AreEqual('Customer', FinancialJournalPage."Account Type".Value, 'Account Type');
        Assert.AreEqual(Format(-21.07), FinancialJournalPage.Amount.Value, 'Amount');
        FinancialJournalPage.Close();
    end;

    local procedure OpenCodaStatementPageAndTransferToGeneralLedger(BankAccountNo: Code[20])
    var
        CODAStatementPage: TestPage "CODA Statement";
    begin
        CODAStatementPage.OpenEdit();
        CODAStatementPage.Filter.SetFilter("Bank Account No.", BankAccountNo);
        CODAStatementPage."Transfer to General Ledger".Invoke(); // Transfer to general ledger
        CODAStatementPage.Close();
    end;

    local procedure CreateAndPostSalesDocumentSpecificAmount(CustomerNo: Code[20]; Amount: Decimal): Code[20]
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibraryInventory.CreateItem(Item);
        VATPostingSetup.Get(SalesHeader."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");
        VATPostingSetup.Validate("VAT %", 0);
        VATPostingSetup.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Unit Price", Amount);
        SalesLine.Modify(true);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        exit(DocumentNo);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandlerPostCODAStatementLines(var PostCODAStatementLines: TestRequestPage "Post CODA Stmt. Lines")
    var
        Variant: Variant;
    begin
        LibraryVariableStorage.Dequeue(Variant);
        PostCODAStatementLines.DefaultApplication.SetValue(Variant); // DefaultApplication
        LibraryVariableStorage.Dequeue(Variant);
        PostCODAStatementLines.PrintReport.SetValue(Variant); // PrintReport

        PostCODAStatementLines.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var returnValue: Boolean)
    begin
        returnValue := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GeneralJournalTemplateListModalPageHandler(var GeneralJournalTemplateListPage: TestPage "General Journal Template List")
    begin
        GeneralJournalTemplateListPage.Filter.SetFilter(Name, 'KBC');
        GeneralJournalTemplateListPage.OK().Invoke();
    end;

    [Normal]
    local procedure CreateBankAccount(var BankAccount: Record "Bank Account"; AccountName: Code[10]; BranchId: Text[20]; BankAccountNo: Text[30])
    begin
        if not BankAccount.Get(AccountName) then begin
            BankAccount.Init();
            BankAccount."No." := AccountName;
            BankAccount.Name := AccountName;
            BankAccount."Bank Account No." := BankAccountNo;
            BankAccount."Bank Branch No." := BranchId;
            BankAccount."Protocol No." := CopyStr(BranchId, 1, MaxStrLen(BankAccount."Protocol No."));
            BankAccount."Version Code" := '1';
            BankAccount.Insert();
        end;
    end;

    [Normal]
    local procedure FindBankAccount(var BankAccount: Record "Bank Account"; BankAccountNo: Text)
    var
        NewBankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        if NewBankAccount.Get(Format(BankAccountNo)) then
            NewBankAccount.Delete();
        NewBankAccount := BankAccount;
        NewBankAccount."No." := Format(CopyStr(BankAccountNo, 1, MaxStrLen(BankAccount."No.")));
        NewBankAccount.Insert();
        BankAccount := NewBankAccount;
    end;

    [Normal]
    local procedure UpdateBankAccountProtocol(var BankAccount: Record "Bank Account"; AccountName: Text; Protocol: Text[3]; Version: Text[1])
    begin
        if BankAccount.Get(AccountName) then begin
            BankAccount."Protocol No." := Protocol;
            BankAccount."Version Code" := Version;
            BankAccount.Modify();
        end;
    end;

    [Normal]
    local procedure CreateGeneralJournalTemplate(Name: Text; Type: Text; BalanceAccountType: Text)
    var
        GeneralJournalTemplate: TestPage "General Journal Templates";
    begin
        GeneralJournalTemplate.OpenView();
        if GeneralJournalTemplate.GotoKey(Name) then
            GeneralJournalTemplate.Edit().Invoke()
        else
            GeneralJournalTemplate.New();

        GeneralJournalTemplate.Name.SetValue := Name;
        GeneralJournalTemplate.Description.SetValue := Name;
        GeneralJournalTemplate.Type.SetValue := Type;
        GeneralJournalTemplate."Bal. Account Type".SetValue := BalanceAccountType;
        GeneralJournalTemplate."Bal. Account No.".SetValue := Name;
        GeneralJournalTemplate.OK().Invoke();
    end;

    [Normal]
    local procedure UpdateCompanyInformation(InterpriseNo: Text)
    var
        CompanyInformation: TestPage "Company Information";
    begin
        CompanyInformation.OpenEdit();
        CompanyInformation."Country/Region Code".SetValue := 'BE';
        CompanyInformation."VAT Registration No.".SetValue := '';
        CompanyInformation."Enterprise No.".SetValue := InterpriseNo;
        CompanyInformation.OK().Invoke();
    end;

    [Normal]
    local procedure UpdateElectronicBanking(SummarizeGeneralJournal: Boolean)
    var
        ElectronicBankingSetup: TestPage "Electronic Banking Setup";
    begin
        ElectronicBankingSetup.OpenEdit();
        ElectronicBankingSetup."Summarize Gen. Jnl. Lines".SetValue := SummarizeGeneralJournal;
        ElectronicBankingSetup.OK().Invoke();
    end;

    [Normal]
    local procedure UpdateVendorBankAccount(VendorNo: Code[20]; "Code": Code[10]; AccountNo: Text[30]; UpdatePreferredAccount: Boolean)
    var
        VendorBankAccount: Record "Vendor Bank Account";
        VendorListPage: TestPage "Vendor List";
        VendorCardPage: TestPage "Vendor Card";
    begin
        if VendorBankAccount.Get(VendorNo, Code) then begin
            VendorBankAccount.Validate("Bank Account No.", AccountNo);
            VendorBankAccount.Modify(true);
        end else begin
            VendorBankAccount.Init();
            VendorBankAccount.Validate("Vendor No.", VendorNo);
            VendorBankAccount.Validate(Code, Code);
            VendorBankAccount.Validate("Bank Account No.", AccountNo);
            VendorBankAccount.Insert(true);
        end;

        if UpdatePreferredAccount then begin
            Commit();

            VendorListPage.OpenView();
            VendorListPage.FILTER.SetFilter("No.", VendorNo);
            VendorListPage.First();

            VendorCardPage.Trap();
            VendorListPage.Edit().Invoke();
            VendorCardPage."Preferred Bank Account Code".SetValue(Code);
            VendorCardPage.OK().Invoke();
        end;
    end;

    [Normal]
    local procedure DeleteAllCODALines()
    var
        CODAStatement: Record "CODA Statement";
        CODAStatementLine: Record "CODA Statement Line";
        CODAStatementSourceLine: Record "CODA Statement Source Line";
    begin
        if not CODAStatement.IsEmpty() then
            CODAStatement.DeleteAll(true);

        if not CODAStatementLine.IsEmpty() then
            CODAStatementLine.DeleteAll(true);

        if not CODAStatementSourceLine.IsEmpty() then
            CODAStatementSourceLine.DeleteAll(true);

        Commit();
    end;

    local procedure ReplaceTransactionCodingScenario373926(var TempTransactionCoding: Record "Transaction Coding" temporary)
    var
        TransactionCoding: Record "Transaction Coding";
    begin
        TransactionCoding.FindSet();
        repeat
            TempTransactionCoding := TransactionCoding;
            TempTransactionCoding.Insert();
        until TransactionCoding.Next() = 0;
        TransactionCoding.DeleteAll();
        InsertTransactionCoding(1, 1, 0, TransactionCoding."Globalisation Code"::Global, TransactionCoding."Account Type"::Vendor, '');
        InsertTransactionCoding(
          1, 7, 0, TransactionCoding."Globalisation Code"::Global, TransactionCoding."Account Type"::"G/L Account", '580000');
        InsertTransactionCoding(1, 50, 0, TransactionCoding."Globalisation Code"::Global, TransactionCoding."Account Type"::Customer, '');
        InsertTransactionCoding(
          1, 51, 0, TransactionCoding."Globalisation Code"::Global, TransactionCoding."Account Type"::"G/L Account", '580000');
        InsertTransactionCoding(1, 52, 0, TransactionCoding."Globalisation Code"::Global, TransactionCoding."Account Type"::Customer, '');
        InsertTransactionCoding(4, 2, 0, TransactionCoding."Globalisation Code"::Detail, 0, '');
        InsertTransactionCoding(
          4, 2, 100, TransactionCoding."Globalisation Code"::Global, TransactionCoding."Account Type"::"G/L Account", '658100');
        InsertTransactionCoding(4, 3, 0, TransactionCoding."Globalisation Code"::Global, TransactionCoding."Account Type"::Vendor, '20');
        InsertTransactionCoding(5, 1, 0, TransactionCoding."Globalisation Code"::Global, TransactionCoding."Account Type"::Vendor, '');
        InsertTransactionCoding(5, 3, 0, TransactionCoding."Globalisation Code"::Global, TransactionCoding."Account Type"::Customer, '');
        InsertTransactionCoding(5, 5, 0, TransactionCoding."Globalisation Code"::Global, TransactionCoding."Account Type"::Customer, '');
        InsertTransactionCoding(13, 1, 0, TransactionCoding."Globalisation Code"::Detail, 0, '');
        InsertTransactionCoding(
          13, 1, 2, TransactionCoding."Globalisation Code"::Global, TransactionCoding."Account Type"::"G/L Account", '650050');
        InsertTransactionCoding(
          13, 1, 55, TransactionCoding."Globalisation Code"::Global, TransactionCoding."Account Type"::"G/L Account", '430000');
        InsertTransactionCoding(13, 15, 0, TransactionCoding."Globalisation Code"::Global, TransactionCoding."Account Type"::Vendor, '');
        InsertTransactionCoding(35, 37, 0, TransactionCoding."Globalisation Code"::Detail, 0, '');
        InsertTransactionCoding(
          35, 37, 6, TransactionCoding."Globalisation Code"::Global, TransactionCoding."Account Type"::"G/L Account", '658100');
        InsertTransactionCoding(
          35, 37, 11, TransactionCoding."Globalisation Code"::Global, TransactionCoding."Account Type"::"G/L Account", '498501');
        InsertTransactionCoding(
          80, 2, 0, TransactionCoding."Globalisation Code"::Global, TransactionCoding."Account Type"::"G/L Account", '656000');
    end;

    local procedure RestoreTransactionCoding(var TempTransactionCoding: Record "Transaction Coding" temporary)
    var
        TransactionCoding: Record "Transaction Coding";
    begin
        TransactionCoding.DeleteAll();
        TempTransactionCoding.FindSet();
        repeat
            TransactionCoding := TempTransactionCoding;
            TransactionCoding.Insert();
        until TempTransactionCoding.Next() = 0;
    end;

    local procedure InsertTransactionCoding(TransactionFamily: Integer; Transaction: Integer; TransactionCategory: Integer; GlobalisationCode: Option; AccountType: Option; AccountNo: Code[20])
    var
        TransactionCoding: Record "Transaction Coding";
    begin
        TransactionCoding.Init();
        TransactionCoding."Transaction Family" := TransactionFamily;
        TransactionCoding.Transaction := Transaction;
        TransactionCoding."Transaction Category" := TransactionCategory;
        TransactionCoding."Globalisation Code" := GlobalisationCode;
        TransactionCoding."Account Type" := AccountType;
        TransactionCoding."Account No." := AccountNo;
        TransactionCoding.Insert();
    end;

    local procedure VerifyCODAStatementLine(var CODAStatementLine: Record "CODA Statement Line"; ApplicationStatus: Option; UnappliedAmount: Decimal; Amount: Decimal; StatementAmount: Decimal)
    begin
        CODAStatementLine.TestField("Application Status", ApplicationStatus);
        CODAStatementLine.TestField("Unapplied Amount", UnappliedAmount);
        CODAStatementLine.TestField(Amount, Amount);
        CODAStatementLine.TestField("Statement Amount", StatementAmount);
        CODAStatementLine.Next();
    end;

    [Normal]
    local procedure ImportCODAWithSpecificAccountType(var BankAccount: Record "Bank Account"; AccountType: Text; TransactionAccountNo: Code[20])
    var
        TransactionCoding: Record "Transaction Coding";
        ImportCODAStatement: Report "Import CODA Statement";
    begin
        UpdateCompanyInformation('0448825928');

        BankAccount.Reset();
        Clear(BankAccount);
        // Update bank account for WWB-EUR
        if BankAccount.Get(BBLEURTxt) then begin
            BankAccount."Protocol No." := '200';
            BankAccount."Version Code" := '2';
            BankAccount."Bank Account No." := '230002155541';
            BankAccount."SWIFT Code" := 'GEBABEBB';
            BankAccount.Modify();
        end;

        TransactionCoding.DeleteAll();
        TransactionCoding.Init();
        TransactionCoding."Bank Account No." := '';
        TransactionCoding."Transaction Family" := 4;
        TransactionCoding.Transaction := 2;
        TransactionCoding."Transaction Category" := 0;
        TransactionCoding."Globalisation Code" := TransactionCoding."Globalisation Code"::Global;
        Evaluate(TransactionCoding."Account Type", AccountType);
        TransactionCoding."Account No." := TransactionAccountNo;

        TransactionCoding.Insert();

        UpdateElectronicBanking(false);

        Commit();

        // Run the processing only report with the data file.
        DeleteAllCODALines();
        ImportCODAStatement.SetBankAcc(BankAccount);
        ImportCODAStatement.InitializeRequest(LibraryCODADataProvider.ImportAccountTypeTestDataFile());
        ImportCODAStatement.Run();

        Commit();
    end;

    local procedure UpdateBankAccountDetails(var BankAccount: Record "Bank Account")
    begin
        BankAccount.Validate("Protocol No.", ProtocolNoTxt);
        BankAccount.Validate("Version Code", VersionCodeTxt);
        BankAccount.Validate("Bank Account No.", BankAccountNoTxt);
        BankAccount.Validate("SWIFT Code", SWIFTCodeTxt);
        BankAccount.Validate(IBAN, IBANTxt);
        BankAccount.Modify(true);
    end;

    local procedure GetInformationFromCODAStatement(BankAccountNo: Code[20]; StatementNo: Code[20]): Integer
    var
        CODAStatement: Record "CODA Statement";
    begin
        CODAStatement.Get(BankAccountNo, StatementNo);
        CODAStatement.CalcFields(Information);

        exit(CODAStatement.Information);
    end;

    local procedure GetInformationFromCODAStatementLine(BankAccountNo: Code[20]; StatementNo: Code[20]): Integer
    var
        CODAStatementLine: Record "CODA Statement Line";
        TotalInformationValue: Integer;
    begin
        CODAStatementLine.SetAutoCalcFields(Information);
        CODAStatementLine.SetRange("Bank Account No.", BankAccountNo);
        CODAStatementLine.SetRange("Statement No.", StatementNo);
        If CODAStatementLine.FindSet() then
            repeat
                TotalInformationValue += CODAStatementLine.Information;
            until CODAStatementLine.Next() = 0;

        exit(TotalInformationValue);
    end;

    local procedure UpdateBankAccountVersionCode(var BankAccount: Record "Bank Account")
    begin
        BankAccount.Validate("Version Code", Format(LibraryRandom.RandIntInRange(3, 9)));
        BankAccount.Modify(true)
    end;

    local procedure CreateBankAccounInformation(var BankAccount: Record "Bank Account")
    begin
        LibraryERM.CreateBankAccount(BankAccount);

        BankAccount.Validate("Version Code", VersionCodeTxt);
        BankAccount.Validate("Protocol No.", ProtocolNo300Txt);
        BankAccount.Validate(IBAN, 'BE75363216340251');
        BankAccount.Validate("SWIFT Code", SWIFTCodeBBRUBEBBTxt);
        BankAccount.Modify(true);
    end;

    local procedure CreateAndPostSalesDocument(CustomerNo: Code[20]): Code[20]
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        VATPostingSetup: Record "VAT Posting Setup";
        DocumentNo: Code[20];
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibraryInventory.CreateItem(Item);
        VATPostingSetup.Get(SalesHeader."VAT Bus. Posting Group", Item."VAT Prod. Posting Group");
        VATPostingSetup.Validate("VAT %", 0);
        VATPostingSetup.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("Unit Price", 21.07);
        SalesLine.Modify(true);
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        exit(DocumentNo);
    end;

    local procedure EnqueueMultipleValues()
    begin
        LibraryVariableStorage.Enqueue(false); // Default application
        LibraryVariableStorage.Enqueue(false); // Dont print
    end;

    local procedure OpenCodaStatementPageAndProcessCodaStmtLines(BankAccountNo: Code[20])
    var
        CODAStatementPage: TestPage "CODA Statement";
    begin
        CODAStatementPage.OpenEdit();
        CODAStatementPage.Filter.SetFilter("Bank Account No.", BankAccountNo);
        CODAStatementPage."Process CODA Statement Lines".Invoke();
        CODAStatementPage.Close();
    end;

    local procedure OpenPostedSalesInvoiceAndUpdatePaymentReference(DocumentNo: Code[20])
    var
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        PostedSalesInvoice.OpenEdit();
        PostedSalesInvoice.Filter.SetFilter("No.", DocumentNo);
        PostedSalesInvoice."Update Document".Invoke();
        PostedSalesInvoice.Close();
    end;

    local procedure RunImportCodaStatementReport(BankAccount: Record "Bank Account")
    var
        ImportCODAStatement: Report "Import CODA Statement";
    begin
        ImportCODAStatement.SetBankAcc(BankAccount);
        ImportCODAStatement.InitializeRequest(LibraryCODADataProvider.OnCODAScenario560840DataFile());
        ImportCODAStatement.Run();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CODAStatementLineRequestPageHandler(var CODAStatementList: TestRequestPage "CODA Statement - List")
    begin
        CODAStatementList.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesInvUpdateUpdateOKModalPageHandler(var PostedSalesInvUpdate: TestPage "Posted Sales Inv. - Update")
    begin
        PostedSalesInvUpdate."Payment Reference".SetValue(LibraryVariableStorage.DequeueText());
        PostedSalesInvUpdate.OK().Invoke();
    end;
}

