codeunit 134921 "ERM Standard Journal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Standard Journal]
        IsInitialized := false;
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryJournals: Codeunit "Library - Journals";
        Assert: Codeunit Assert;
        LibraryUtility: Codeunit "Library - Utility";
        LibraryDimension: Codeunit "Library - Dimension";
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure SaveStandardJournal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
    begin
        // Test create General Journal Lines and Save them as Standard Journal.

        // 1. Setup: Create General Journal Batch, General Journal Lines and Standard Journal Code.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJournalLines(GenJournalLine, GenJournalBatch);

        // 2. Exercise: Save General Journal Lines as Standard Journal.
        CreateSaveStandardJournal(StandardGeneralJournal, GenJournalBatch);

        // 3. Verify: Verify correct number of Standard General Journal Lines created.
        VerifyStandardJournalLines(GenJournalLine, StandardGeneralJournal.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure GetStandardJournal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
    begin
        // Test create General Journal Lines using get Standard Journal.

        // 1. Setup: Create General Journal Batch, Create multiple General Journal Lines and save them as Standard Journal.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJournalLines(GenJournalLine, GenJournalBatch);
        CreateSaveStandardJournal(StandardGeneralJournal, GenJournalBatch);

        // 2. Exercise: Delete and get saved standard Journal in General Journal.
        DeleteGeneralJournalLine(GenJournalBatch.Name);
        StandardGeneralJournal.CreateGenJnlFromStdJnl(StandardGeneralJournal, GenJournalBatch.Name);

        // 3. Verify: Verify Standard General Journal Lines created match with the General Journal Lines.
        VerifyGeneralJournalLines(GenJournalLine, StandardGeneralJournal.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure GetStandardJournalWithDocumentNo()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
        DocumentNo: Code[20];
    begin
        // Test create General Journal Lines using get Standard Journal by providing a document number.

        // 1. Setup: Create General Journal Batch, Create multiple General Journal Lines and save them as Standard Journal.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJournalLines(GenJournalLine, GenJournalBatch);
        CreateSaveStandardJournal(StandardGeneralJournal, GenJournalBatch);

        // 2. Exercise: Get saved standard Journal in General Journal and use a document number for new lines.
        DocumentNo := LibraryUtility.GenerateGUID();
        StandardGeneralJournal.CreateGenJnlFromStdJnlWithDocNo(StandardGeneralJournal, GenJournalBatch.Name, DocumentNo, 0D);

        // 3. Verify: Verify Standard General Journal Lines created match with the General Journal Lines.
        VerifyGeneralJournalLinesWithDocNo(GenJournalLine, StandardGeneralJournal.Code, DocumentNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure UpdateAndGetStandardJournal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
        AccountNo: Code[20];
    begin
        // Test update an existing Standard Journal and create General Journal Lines using get Standard Journal.

        // 1. Setup: Create General Journal Batch, create multiple General Journal Lines and save them as Standard Journal.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJournalLines(GenJournalLine, GenJournalBatch);
        CreateSaveStandardJournal(StandardGeneralJournal, GenJournalBatch);

        // 2. Exercise: Update Standard General Journal Line and get it in General Journal.
        DeleteGeneralJournalLine(GenJournalBatch.Name);
        AccountNo := UpdateStandardJournalLine(GenJournalBatch."Journal Template Name", StandardGeneralJournal.Code);
        StandardGeneralJournal.CreateGenJnlFromStdJnl(StandardGeneralJournal, GenJournalBatch.Name);

        // 3. Verify: Verify updated G/L Account No. in General Journal Line.
        VerifyGeneralLedgerAccount(GenJournalBatch, AccountNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure SaveMultipleStandardJournal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalBatch2: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        StandardGeneralJournal: Record "Standard General Journal";
        StandardGeneralJournal2: Record "Standard General Journal";
        StandardGeneralJournal3: Record "Standard General Journal";
    begin
        // Test create General Journal Lines using get standard Journal and save multiple Standard Journals.

        // 1. Setup: Create General Journal Batch and create two Standard General Journal.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJournalLines(GenJournalLine, GenJournalBatch);
        CreateSaveStandardJournal(StandardGeneralJournal, GenJournalBatch);
        SaveGenJournalLineInTemp(TempGenJournalLine, GenJournalLine);
        DeleteGeneralJournalLine(GenJournalBatch.Name);

        CreateGeneralJournalBatch(GenJournalBatch2);
        CreateGeneralJournalLines(GenJournalLine, GenJournalBatch2);
        CreateSaveStandardJournal(StandardGeneralJournal2, GenJournalBatch2);

        // Get saved Standard Journal in General Journal Line.
        StandardGeneralJournal.CreateGenJnlFromStdJnl(StandardGeneralJournal, GenJournalBatch.Name);

        // 2. Exercise: Save Standard Journal.
        CreateSaveStandardJournal(StandardGeneralJournal3, GenJournalBatch2);

        // 3. Verify: Verify Standard General Journal Lines created match with the General Journal Lines.
        VerifyGeneralJournalLines(TempGenJournalLine, StandardGeneralJournal.Code);
        VerifyGeneralJournalLines(GenJournalLine, StandardGeneralJournal2.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure ReplaceExistingStandardJournal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
    begin
        // Test create General Journal Lines and replace an existing Standard Journal using save Standard Journal.

        // 1. Setup: Create General Journal Template and General Journal Batch.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJournalLines(GenJournalLine, GenJournalBatch);
        CreateSaveStandardJournal(StandardGeneralJournal, GenJournalBatch);

        // 2. Exercise: Save existing Standard Journal.
        DeleteGeneralJournalLine(GenJournalBatch.Name);
        StandardGeneralJournal.CreateGenJnlFromStdJnl(StandardGeneralJournal, GenJournalBatch.Name);
        SaveAsStandardJournal(GenJournalBatch, StandardGeneralJournal.Code);

        // 3. Verify: Verify Standard General Journal Lines created match with the General Journal Lines.
        VerifyGeneralJournalLines(GenJournalLine, StandardGeneralJournal.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure PostStandardJournal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        StandardGeneralJournal: Record "Standard General Journal";
        LibrarySales: Codeunit "Library - Sales";
    begin
        // Test create General Journal Lines save them as Standard Journal and post it.

        // 1. Setup: Create General Journal Batch, create a Customer and create General Journal Lines.
        // Save the General Journal Lines created as Standard General Journal.
        Initialize();
        GLAccount.FilterGroup(2);
        GLAccount.SetRange("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale);
        GLAccount.FilterGroup(0);
        LibraryERM.FindGLAccount(GLAccount);
        LibrarySales.CreateCustomer(Customer);
        CreateGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::Customer, Customer."No.", GLAccount."No.", '');

        // Save as Standard Journal.
        SaveGenJournalLineInTemp(TempGenJournalLine, GenJournalLine);
        CreateSaveStandardJournal(StandardGeneralJournal, GenJournalBatch);

        // 2. Exercise: Post the General Journal Lines.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 3. Verify: Verify Customer Ledger Entry with the General Journal Lines.
        VerifyCustomerLedgerEntry(TempGenJournalLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure CurrencyFactorAfterGetStandardJournalOnNewDate()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
        CurrencyCode: Code[10];
        NewPostingDate: Date;
        CurrencyFactor: array[2] of Decimal;
    begin
        // [FEATURE] [FCY]
        // [SCEANRIO 376966] Standard journal use currency factor from actual gen. journal's posting date
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch);

        // [GIVEN] Currency "C" with two Exchange Rates: 100 (date "D1"), 200 (date "D2")
        CurrencyCode := CreateCurrencyWithTwoExchRates(CurrencyFactor, NewPostingDate);

        // [GIVEN] General Journal Line with "Posting Date" = "D1", "Currency Code" = "C"
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"G/L Account",
          LibraryERM.CreateGLAccountNoWithDirectPosting(), '', CurrencyCode);

        // [GIVEN] Save current General Journal as Standard Journal
        CreateSaveStandardJournal(StandardGeneralJournal, GenJournalBatch);

        // [GIVEN] Modify General Journal Line "Posting Date" = "D2"
        GenJournalLine.Validate("Posting Date", NewPostingDate);
        GenJournalLine.Modify(true);

        // [WHEN] Get Standard Journal
        StandardGeneralJournal.CreateGenJnlFromStdJnl(StandardGeneralJournal, GenJournalBatch.Name);

        // [THEN] New General Journal Line has been created with "Posting Date" = "D2", "Currency Code" = "C", "Currency Factor" = 200.
        GenJournalLine.Next();
        Assert.AreEqual(NewPostingDate, GenJournalLine."Posting Date", GenJournalLine.FieldCaption("Posting Date"));
        Assert.AreEqual(CurrencyCode, GenJournalLine."Currency Code", GenJournalLine.FieldCaption("Currency Code"));
        Assert.AreEqual(CurrencyFactor[2], GenJournalLine."Currency Factor", GenJournalLine.FieldCaption("Currency Factor"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetStandardJournalLinesWithZeroAmountForBatchWithNoSeries()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        StandardGeneralJournal: Record "Standard General Journal";
    begin
        // [SCENARIO 293278] Function Get Standard Journal creates journal lines in batch with No. Series with same document number if source standard journal lines have zero amount
        Initialize();

        // [GIVEN] Create general journal batch with No. Series
        CreateGeneralJournalBatch(GenJournalBatch);
        GenJournalBatch."No. Series" := LibraryERM.CreateNoSeriesCode();
        GenJournalBatch.Modify();

        // [GIVEN] Create standard journal "STDJ"
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");
        // [GIVEN] Create 3 standard journal lines with zero amount
        CreateStandardJournalLinesWithZeroAmount(StandardGeneralJournal, LibraryRandom.RandIntInRange(3, 5));

        // [WHEN] Function Get Standard Journal with "STDJ" is being run
        Commit();
        StandardGeneralJournal.CreateGenJnlFromStdJnl(StandardGeneralJournal, GenJournalBatch.Name);

        // [THEN] Created general journal lines have same document number
        VerifySameDocumentNumberForCreatedGenJnlLines(GenJournalBatch);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GetStandardJournalLinesWithZeroAmountForBatchWithoutNoSeries()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        StandardGeneralJournal: Record "Standard General Journal";
    begin
        // [SCENARIO 293278] Function Get Standard Journal creates journal lines in batch without No. Series with empty document number if source standard journal lines have zero amount
        Initialize();

        // [GIVEN] Create general journal batch with empty No. Series
        CreateGeneralJournalBatch(GenJournalBatch);
        GenJournalBatch.TestField("No. Series", '');

        // [GIVEN] Create standard journal "STDJ"
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");
        // [GIVEN] Create 3 standard journal lines with zero amount
        CreateStandardJournalLinesWithZeroAmount(StandardGeneralJournal, LibraryRandom.RandIntInRange(3, 5));

        // [WHEN] Function Get Standard Journal with "STDJ" is being run
        Commit();
        StandardGeneralJournal.CreateGenJnlFromStdJnl(StandardGeneralJournal, GenJournalBatch.Name);

        // [THEN] Created general journal lines have empty document number
        VerifyEmptyDocumentNumberForCreatedGenJnlLines(GenJournalBatch);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure SaveStandardJournalWithExtDocNo()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
        StandardGeneralJournalLine: Record "Standard General Journal Line";
    begin
        // [SCENARIO 324153] "External Document No." passed to standard gen. jnl. line when save it from gen. jnl. line
        Initialize();

        // [GIVEN] Gen. jnl. line with "External Document No." = "ED"
        CreateGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), '', '');
        GenJournalLine."External Document No." := LibraryUtility.GenerateGUID();
        GenJournalLine.Modify(true);

        // [WHEN] Save gen. jnl. line as standard gen. jnl. line
        CreateSaveStandardJournal(StandardGeneralJournal, GenJournalBatch);

        // [THEN] "Standard General Journal Line"."External Document No." = "ED"
        StandardGeneralJournalLine.SetRange("Standard Journal Code", StandardGeneralJournal.Code);
        StandardGeneralJournalLine.FindFirst();
        StandardGeneralJournalLine.TestField("External Document No.", GenJournalLine."External Document No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure GetStandardJournalWithExtDocNo()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
        StandardGeneralJournalLine: Record "Standard General Journal Line";
    begin
        // [SCENARIO 324153] "External Document No." passed to gen. jnl. line when create it from standard gen. jnl. line
        Initialize();

        // [GIVEN] Standard gen. jnl. line with "External Document No." = "ED"
        CreateGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), '', '');
        GenJournalLine."External Document No." := LibraryUtility.GenerateGUID();
        GenJournalLine.Modify(true);
        CreateSaveStandardJournal(StandardGeneralJournal, GenJournalBatch);

        // [WHEN] Create gen. jnl. line from standard gen. jnl. line
        DeleteGeneralJournalLine(GenJournalBatch.Name);
        StandardGeneralJournal.CreateGenJnlFromStdJnl(StandardGeneralJournal, GenJournalBatch.Name);

        // [THEN] "Gen. Journal Line"."External Document No." = "ED"
        StandardGeneralJournalLine.SetRange("Standard Journal Code", StandardGeneralJournal.Code);
        StandardGeneralJournalLine.FindFirst();

        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst();

        GenJournalLine.TestField("External Document No.", StandardGeneralJournalLine."External Document No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure GetStandardJournalWithPaymentTermsAndMethod()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        Vendor: Record Vendor;
    begin
        // [SCENARIO 458858] "Payment Terms Code" and "Payment Method Code" passed to gen. jnl. line when create it from standard gen. jnl. line
        Initialize();

        // [GIVEN] Create Vendor with "Payment Terms" and "Payment Method"
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        Vendor.Validate("Payment Method Code", PaymentMethod.Code);
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Modify();

        // [GIVEN] Standard gen. jnl. line with Vendor payment
        CreateGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"Vendor", Vendor."No.", '', '');
        CreateSaveStandardJournal(StandardGeneralJournal, GenJournalBatch);

        // [WHEN] Create gen. jnl. line from standard gen. jnl. line
        DeleteGeneralJournalLine(GenJournalBatch.Name);
        StandardGeneralJournal.CreateGenJnlFromStdJnl(StandardGeneralJournal, GenJournalBatch.Name);

        // [THEN] Verify "Payment Terms Code" and "Payment Method Code"
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst();

        GenJournalLine.TestField("Payment Method Code", PaymentMethod.Code);
        GenJournalLine.TestField("Payment Terms Code", PaymentTerms.Code);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure S478445_GetStandardJournalWithPaymentTermsAndMethodFromBalAccount()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
        PaymentTerms: Record "Payment Terms";
        PaymentMethod: Record "Payment Method";
        Vendor: Record Vendor;
        GLAccountNo: Code[20];
    begin
        // [SCENARIO 478445] "Payment Terms Code" and "Payment Method Code" passed to General Journal Line created from Standard General Journal Line from Balancing Account.
        Initialize();

        // [GIVEN] Create G/L Account with Direct Posting
        GLAccountNo := LibraryERM.CreateGLAccountNoWithDirectPosting();

        // [GIVEN] Create Vendor with "Payment Terms" and "Payment Method"
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        Vendor.Validate("Payment Method Code", PaymentMethod.Code);
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Modify();

        // [GIVEN] Create Standard General Journal Line with G/L Account as "Account No." and Vendor as "Bal. Account No."
        CreateGeneralJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, GenJournalLine."Account Type"::"G/L Account", GLAccountNo, GenJournalLine."Bal. Account Type"::"Vendor", Vendor."No.", '');
        CreateSaveStandardJournal(StandardGeneralJournal, GenJournalBatch);

        // [WHEN] Create General Journal Line from Standard General Journal Line
        DeleteGeneralJournalLine(GenJournalBatch.Name);
        StandardGeneralJournal.CreateGenJnlFromStdJnl(StandardGeneralJournal, GenJournalBatch.Name);

        // [THEN] Verify "Payment Terms Code" and "Payment Method Code" transferred from Vendor as "Bal. Account No."
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst();

        GenJournalLine.TestField("Payment Method Code", Vendor."Payment Method Code");
        GenJournalLine.TestField("Payment Terms Code", Vendor."Payment Terms Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue,StandardGeneralJournalsHandler,UIMessageHandler')]
    [Scope('OnPrem')]
    procedure GetStandardJournalFromSimplifiedGenJournalPageWithPostingDate()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
        GenJournalPage: TestPage "General Journal";
        GenJournalSimplePage: TestPage "General Journal";
    begin
        // [SCENARIO 394413] Get Standard Journal from simplified General Journal page should create lines with Posting Date from page
        Initialize();

        GenJournalTemplate.DeleteAll();
        GenJournalBatch.DeleteAll();

        // [GIVEN] Standard Journal line 
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch,
            GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), '', '');

        CreateSaveStandardJournal(StandardGeneralJournal, GenJournalBatch);
        GenJournalLine.Delete();

        // [GIVEN] General Journal page opened in simplified mode with Posting Date = WorkDate() + 1 and empty Document No.
        GenJournalPage.OpenEdit();
        GenJournalPage.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        GenJournalSimplePage.Trap();
        GenJournalPage.SimpleView.Invoke();
        GenJournalSimplePage."<CurrentPostingDate>".SetValue(CalcDate('<+1D>', WorkDate()));

        // [WHEN] "Get Standard Journals" invoked 
        GenJournalSimplePage.GetStandardJournals.Invoke();
        GenJournalSimplePage.Close();

        // [THEN] Gen. Journal Line is created with Posting Date = WorkDate() + 1
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Posting Date", CalcDate('<+1D>', WorkDate()));

        GenJournalLine.Delete();

        // [GIVEN] General Journal page opened in simplified mode with Posting Date = WorkDate() + 2 and filled Document No.
        GenJournalSimplePage.OpenEdit();
        GenJournalSimplePage.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        GenJournalSimplePage."<Document No. Simple Page>".SetValue(
            LibraryUtility.GenerateRandomCode(
                GenJournalLine.FieldNo("Document No."), DATABASE::"Gen. Journal Line"));
        GenJournalSimplePage."<CurrentPostingDate>".SetValue(CalcDate('<+2D>', WorkDate()));

        // [WHEN] "Get Standard Journals" invoked 
        GenJournalSimplePage.GetStandardJournals.Invoke();
        GenJournalSimplePage.Close();

        // [THEN] Gen. Journal Line is created with Posting Date = WorkDate() + 2
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Posting Date", CalcDate('<+2D>', WorkDate()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure VerifyDimensionsOnGeneralJournalOnGetStandardJournal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
    begin
        // [SCENARIO 464111] Verify dimensions are transfered properly from Standard Journal to General Journal Lines with Get Standard Journal action
        Initialize();

        // [GIVEN] Create General Journal Batch
        CreateGeneralJournalBatch(GenJournalBatch);

        // [GIVEN] Create multiple General Journal Lines
        CreateGeneralJournalLines(GenJournalLine, GenJournalBatch);

        // [GIVEN] Update dimensions on General Jnl. Lines
        UpdateDimensionsOnGeneralJournalLine(GenJournalLine);

        // [GIVEN] Save General Journal Lines as Standard Journal
        CreateSaveStandardJournal(StandardGeneralJournal, GenJournalBatch);

        // [WHEN] Delete and get saved standard Journal in General Journal
        DeleteGeneralJournalLine(GenJournalBatch.Name);
        StandardGeneralJournal.CreateGenJnlFromStdJnl(StandardGeneralJournal, GenJournalBatch.Name);

        // [THEN] Verify dimensions on General Journal Lines
        VerifyDimensionsOnGeneralJournalLines(StandardGeneralJournal, GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    procedure CurrencyCodeShouldFlowFromStandardJournalToGeneralJournal()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        StandardGeneralJournal: Record "Standard General Journal";
        StandardGeneralJournalLine: Record "Standard General Journal Line";
        CurrencyCode: code[20];
    begin
        // [SCENARIO 547489] Currency Code is not populating as saved in the Standard General Journal Template.
        Initialize();

        // [GIVEN] Create General Journal Batch.
        CreateGeneralJournalBatch(GenJournalBatch);

        // [GIVEN] Create General Journal Line.
        CreateGeneralJournalLines(GenJournalLine, GenJournalBatch);

        // [GIVEN] Create and Save Standred Journal.
        CreateSaveStandardJournal(StandardGeneralJournal, GenJournalBatch);

        // [GIVEN] Create Currency With Random Exchange Rates.
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();

        // [GIVEN] Update the Currency Code in Standard Journal. 
        StandardGeneralJournalLine.SetRange("Journal Template Name", StandardGeneralJournal."Journal Template Name");
        StandardGeneralJournalLine.SetRange("Standard Journal Code", StandardGeneralJournal.Code);
        StandardGeneralJournalLine.SetRange("Account Type", StandardGeneralJournalLine."Account Type"::"G/L Account");
        StandardGeneralJournalLine.FindFirst();
        StandardGeneralJournalLine.Validate("Currency Code", CurrencyCode);
        StandardGeneralJournalLine.Modify(true);

        // [WHEN] Create General Journal From Standard Journal. 
        StandardGeneralJournal.CreateGenJnlFromStdJnl(StandardGeneralJournal, GenJournalBatch.Name);

        // [THEN] Currency Code must me populated in Standard General Journal.
        Assert.AreEqual(CurrencyCode, StandardGeneralJournalLine."Currency Code", '');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
    end;

    local procedure VerifyDimensionsOnGeneralJournalLines(var StandardGeneralJournal: Record "Standard General Journal"; var GenJournalLine: Record "Gen. Journal Line")
    var
        StandardGeneralJnlLine: Record "Standard General Journal Line";
    begin
        StandardGeneralJnlLine.SetRange("Journal Template Name", StandardGeneralJournal."Journal Template Name");
        StandardGeneralJnlLine.FindSet();
        repeat
            GenJournalLine.Reset();
            GenJournalLine.SetRange("Journal Template Name", StandardGeneralJnlLine."Journal Template Name");
            GenJournalLine.SetRange("Account Type", StandardGeneralJnlLine."Account Type");
            GenJournalLine.SetRange("Account No.", StandardGeneralJnlLine."Account No.");
            if GenJournalLine.FindFirst() then begin
                GenJournalLine.TestField("Shortcut Dimension 1 Code", StandardGeneralJnlLine."Shortcut Dimension 1 Code");
                GenJournalLine.TestField("Shortcut Dimension 2 Code", StandardGeneralJnlLine."Shortcut Dimension 2 Code");
            end;
        until StandardGeneralJnlLine.Next() = 0;
    end;

    local procedure UpdateDimensionsOnGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
    begin
        GeneralLedgerSetup.Get();
        LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Shortcut Dimension 1 Code");
        LibraryDimension.FindDimensionValue(DimensionValue2, GeneralLedgerSetup."Shortcut Dimension 2 Code");
        GenJournalLine.Reset();
        FindGeneralJournalLines(GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        repeat
            GenJournalLine.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);
            GenJournalLine.Validate("Shortcut Dimension 2 Code", DimensionValue2.Code);
            GenJournalLine.Modify(true);
        until GenJournalLine.Next() = 0;
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BalAccountNo: Code[20]; CurrencyCode: Code[10])
    begin
        // Using the random Amount because value is not important.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          AccountType, AccountNo, LibraryRandom.RandDec(100, 2));

        // The value of Document No. is not important.
        GenJournalLine.Validate("Document No.", GenJournalLine."Journal Batch Name" + Format(GenJournalLine."Line No."));
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20]; CurrencyCode: Code[10])
    begin
        // Using the random Amount because value is not important.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          AccountType, AccountNo, LibraryRandom.RandDec(100, 2));

        // The value of Document No. is not important.
        GenJournalLine.Validate("Document No.", GenJournalLine."Journal Batch Name" + Format(GenJournalLine."Line No."));
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGeneralJournalLines(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch")
    var
        Counter: Integer;
    begin
        // Using the random number of lines.
        for Counter := 1 to 1 + LibraryRandom.RandInt(5) do begin
            CreateGeneralJournalLine(GenJournalLine, GenJournalBatch,
              GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting(), '', '');
            CreateGeneralJournalLine(GenJournalLine, GenJournalBatch,
              GenJournalLine."Account Type"::Customer, LibrarySales.CreateCustomerNo(), '', '');
            CreateGeneralJournalLine(GenJournalLine, GenJournalBatch,
              GenJournalLine."Account Type"::Vendor, LibraryPurchase.CreateVendorNo(), '', '');
        end;
    end;

    local procedure CreateSaveStandardJournal(var StandardGeneralJournal: Record "Standard General Journal"; GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.CreateStandardGeneralJournal(StandardGeneralJournal, GenJournalBatch."Journal Template Name");
        SaveAsStandardJournal(GenJournalBatch, StandardGeneralJournal.Code);
    end;

    local procedure CreateStandardGeneralJournalLine(StandardGeneralJournal: Record "Standard General Journal"; var StandardGeneralJournalLine: Record "Standard General Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    var
        LineNo: Integer;
    begin
        StandardGeneralJournalLine.SetRange("Journal Template Name", StandardGeneralJournal."Journal Template Name");
        StandardGeneralJournalLine.SetRange("Standard Journal Code", StandardGeneralJournal.Code);
        if StandardGeneralJournalLine.FindLast() then;
        LineNo := StandardGeneralJournalLine."Line No." + 10000;

        StandardGeneralJournalLine.Init();
        StandardGeneralJournalLine."Journal Template Name" := StandardGeneralJournal."Journal Template Name";
        StandardGeneralJournalLine."Standard Journal Code" := StandardGeneralJournal.Code;
        StandardGeneralJournalLine."Line No." := LineNo;
        StandardGeneralJournalLine.Validate("Account Type", AccountType);
        StandardGeneralJournalLine.Validate("Account No.", AccountNo);
        StandardGeneralJournalLine.Insert();
    end;

    local procedure CreateStandardJournalLinesWithZeroAmount(StandardGeneralJournal: Record "Standard General Journal"; NumberOfLines: Integer)
    var
        StandardGeneralJournalLine: Record "Standard General Journal Line";
        i: Integer;
    begin
        for i := 1 to NumberOfLines do
            CreateStandardGeneralJournalLine(
              StandardGeneralJournal, StandardGeneralJournalLine,
              StandardGeneralJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNoWithDirectPosting());
    end;

    local procedure CreateCurrencyWithTwoExchRates(var CurrencyFactor: array[2] of Decimal; var NewPostingDate: Date) CurrencyCode: Code[10]
    begin
        CurrencyFactor[1] := LibraryRandom.RandDecInRange(100, 200, 2);
        CurrencyFactor[2] := CurrencyFactor[1] + LibraryRandom.RandDecInRange(100, 200, 2);
        NewPostingDate := LibraryRandom.RandDate(LibraryRandom.RandIntInRange(10, 20));
        CurrencyCode := LibraryERM.CreateCurrencyWithGLAccountSetup();
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate(), CurrencyFactor[1], CurrencyFactor[1]);
        LibraryERM.CreateExchangeRate(CurrencyCode, NewPostingDate, CurrencyFactor[2], CurrencyFactor[2]);
    end;

    local procedure DeleteGeneralJournalLine(JournalBatchName: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        GenJournalLine.DeleteAll(true);
    end;

    local procedure FindGeneralJournalLines(var GenJournalLine: Record "Gen. Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    begin
        GenJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        GenJournalLine.FindSet();
    end;

    local procedure FindGeneralJournalLinesWithDocNo(var GenJournalLine: Record "Gen. Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10]; DocumentNo: Code[20])
    begin
        GenJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        GenJournalLine.SetRange("Document No.", DocumentNo);
        GenJournalLine.FindSet();
    end;

    local procedure SaveAsStandardJournal(GenJournalBatch: Record "Gen. Journal Batch"; "Code": Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
        SaveAsStandardGenJournal: Report "Save as Standard Gen. Journal";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        Clear(SaveAsStandardGenJournal);
        SaveAsStandardGenJournal.Initialise(GenJournalLine, GenJournalBatch);
        SaveAsStandardGenJournal.InitializeRequest(Code, '', true);
        SaveAsStandardGenJournal.UseRequestPage(false);
        SaveAsStandardGenJournal.RunModal();
    end;

    local procedure SaveGenJournalLineInTemp(var GenJournalLine2: Record "Gen. Journal Line"; GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.SetRange("Account No.", GenJournalLine."Account No.");
        GenJournalLine.FindSet();
        repeat
            GenJournalLine2.Init();
            GenJournalLine2 := GenJournalLine;
            GenJournalLine2.Insert();
        until GenJournalLine.Next() = 0;
    end;

    local procedure UpdateStandardJournalLine(JournalTemplateName: Code[10]; StandardJournalCode: Code[10]): Code[20]
    var
        StandardGeneralJournalLine: Record "Standard General Journal Line";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGLAccount(GLAccount);
        StandardGeneralJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        StandardGeneralJournalLine.SetRange("Standard Journal Code", StandardJournalCode);
        StandardGeneralJournalLine.SetRange("Account Type", StandardGeneralJournalLine."Account Type"::"G/L Account");
        StandardGeneralJournalLine.FindFirst();
        StandardGeneralJournalLine.Validate("Account No.", GLAccount."No.");
        StandardGeneralJournalLine.Modify(true);
        exit(StandardGeneralJournalLine."Account No.");
    end;

    local procedure VerifyGeneralLedgerAccount(GenJournalBatch: Record "Gen. Journal Batch"; AccountNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        FindGeneralJournalLines(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name);
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::"G/L Account");
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Account No.", AccountNo);
    end;

    local procedure VerifyCustomerLedgerEntry(var GenJournalLine: Record "Gen. Journal Line")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        GenJournalLine.FindFirst();
        CustLedgerEntry.SetRange("Customer No.", GenJournalLine."Account No.");
        repeat
            CustLedgerEntry.SetRange("Document No.", GenJournalLine."Document No.");
            CustLedgerEntry.FindFirst();
            CustLedgerEntry.CalcFields(Amount);
            CustLedgerEntry.TestField(Amount, GenJournalLine.Amount);
        until GenJournalLine.Next() = 0;
    end;

    local procedure VerifyGeneralJournalLines(GenJournalLine: Record "Gen. Journal Line"; StandardJournalCode: Code[10])
    var
        StandardGeneralJournalLine: Record "Standard General Journal Line";
    begin
        StandardGeneralJournalLine.SetRange("Standard Journal Code", StandardJournalCode);
        StandardGeneralJournalLine.FindSet();
        FindGeneralJournalLines(GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        repeat
            StandardGeneralJournalLine.TestField(Amount, GenJournalLine.Amount);
            StandardGeneralJournalLine.Next();
        until GenJournalLine.Next() = 0;
    end;

    local procedure VerifyGeneralJournalLinesWithDocNo(GenJournalLine: Record "Gen. Journal Line"; StandardJournalCode: Code[10]; DocumentNo: Code[20])
    var
        StandardGeneralJournalLine: Record "Standard General Journal Line";
    begin
        StandardGeneralJournalLine.SetRange("Standard Journal Code", StandardJournalCode);
        StandardGeneralJournalLine.FindSet();
        FindGeneralJournalLinesWithDocNo(
          GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", DocumentNo);
        repeat
            StandardGeneralJournalLine.TestField(Amount, GenJournalLine.Amount);
            GenJournalLine.TestField("Document No.", DocumentNo);
            StandardGeneralJournalLine.Next();
        until GenJournalLine.Next() = 0;
    end;

    local procedure VerifyStandardJournalLines(GenJournalLine: Record "Gen. Journal Line"; StandardJournalCode: Code[10])
    var
        StandardGeneralJournalLine: Record "Standard General Journal Line";
    begin
        StandardGeneralJournalLine.SetRange("Standard Journal Code", StandardJournalCode);
        StandardGeneralJournalLine.FindSet();
        FindGeneralJournalLines(GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
        repeat
            GenJournalLine.TestField(Amount, StandardGeneralJournalLine.Amount);
            GenJournalLine.Next();
        until StandardGeneralJournalLine.Next() = 0;
    end;

    local procedure VerifySameDocumentNumberForCreatedGenJnlLines(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindSet();
        DocumentNo := GenJournalLine."Document No.";
        repeat
            GenJournalLine.TestField("Document No.", DocumentNo);
        until GenJournalLine.Next() = 0;
    end;

    local procedure VerifyEmptyDocumentNumberForCreatedGenJnlLines(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindSet();
        repeat
            GenJournalLine.TestField("Document No.", '');
        until GenJournalLine.Next() = 0;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure UIMessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure StandardGeneralJournalsHandler(var StandardGeneralJournals: TestPage "Standard General Journals")
    begin
        StandardGeneralJournals.First();
        StandardGeneralJournals.OK().Invoke();
    end;
}

