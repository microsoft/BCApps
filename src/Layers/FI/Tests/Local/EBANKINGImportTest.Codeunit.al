codeunit 144022 "E-BANKING Import Test"
{
    // [FEATURE] [E-BANKING]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        CompanyInformation: Record "Company Information";
        PaymentTerms: Record "Payment Terms";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryVariableStorage2: Codeunit "Library - Variable Storage";
        LibraryFileMgtHandler: Codeunit "Library - File Mgt Handler";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        FileMgt: Codeunit "File Management";
        Initialized: Boolean;

    [Test]
    [HandlerFunctions('PageReqHandler')]
    procedure TestDomesticImportOfPaymentFile()
    var
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        InvoiceBase: Code[19];
        PostingNo: Code[20];
        PostingDate: Date;
        InvoicesCount: Integer;
        i: Integer;
        FileName: Text;
    begin
        Initialize();
        WorkDate(20051122D);

        // Setup
        Setup(BankAccount, GenJournalBatch, GenJournalTemplate);
        FileName := FillInDomesticPaymentFileSample1();
        InvoiceBase := '87101010643';
        InvoicesCount := 4;
        PostingDate := DMY2Date(22, 11, 2005);

        CreateDomesticCustomer(Customer);
        LibraryVariableStorage2.AssertEmpty();
        for i := 1 to InvoicesCount do begin
            PostingNo := InvoiceBase + Format(i - 1);
            LibraryVariableStorage2.Enqueue(PostingNo); // save invoice numbers.
            CreateAndPostSalesInvoice(Customer, PostingNo); // Specifying specific Posting No.
        end;

        // Exercise
        ImportDomesticPaymentFile(GenJournalBatch.Name, GenJournalTemplate.Name, BankAccount."No.", FileName);

        // Validate
        ValidateGenJournalLines(GenJournalBatch.Name, GenJournalTemplate.Name, InvoicesCount, PostingDate, -240.06);
    end;

    [Test]
    [HandlerFunctions('PageReqHandler')]
    procedure TestDomesticImportOfTwoPaymentFiles()
    var
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        ReferenceNo: Code[20];
        PostingNo: Code[20];
        FileName: Text;
    begin
        Initialize();
        WorkDate(20060823D);

        // Setup
        CreateDomesticCustomer(Customer);
        ReferenceNo := CreateAndPostSalesInvoice(Customer, PostingNo); // Not specifying specific Posting No.
        Setup(BankAccount, GenJournalBatch, GenJournalTemplate);
        FileName := FillInDomesticPaymentFileSample3(true, ReferenceNo);

        // Exercise - Import the first file
        ImportDomesticPaymentFile(GenJournalBatch.Name, GenJournalTemplate.Name, BankAccount."No.", FileName);

        // Validate
        ValidateAndGetGenJournalLine(GenJournalLine, 2000, GenJournalBatch.Name, GenJournalTemplate.Name, PostingNo, ReferenceNo);

        // Exercise - Import the second file
        GenJournalLine.Validate("Posting Date", WorkDate());
        GenJournalLine.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalLine.Validate(Amount, -10);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        FileName := FillInDomesticPaymentFileSample3(false, ReferenceNo);
        ImportDomesticPaymentFile(GenJournalBatch.Name, GenJournalTemplate.Name, BankAccount."No.", FileName);

        // Validate
        ValidateAndGetGenJournalLine(GenJournalLine, 1500.6, GenJournalBatch.Name, GenJournalTemplate.Name, PostingNo, ReferenceNo);
    end;

    [Test]
    [HandlerFunctions('PageReqHandler')]
    procedure TestDomesticImportOfThePaymentFileTheSecondTime()
    var
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        BankRefFileSetup: Record "Reference File Setup";
        PostingDate: Date;
        ReferenceNo: Code[20];
        PostingNo: Code[20];
        FileName: Text;
    begin
        // [SCENARIO 334605] Stan can import reference file two times being under Windows User Group permissions.
        Initialize();
        WorkDate(20060823D);

        CreateDomesticCustomer(Customer);
        ReferenceNo := CreateAndPostSalesInvoice(Customer, PostingNo); // Not specifying specific Posting No.
        Setup(BankAccount, GenJournalBatch, GenJournalTemplate);
        FileName := FillInDomesticPaymentFileSample4(ReferenceNo);
        PostingDate := DMY2Date(23, 8, 2006);

        // Exercise
        ImportDomesticPaymentFile(GenJournalBatch.Name, GenJournalTemplate.Name, BankAccount."No.", FileName);
        ValidateGenJournalLinesFile4(GenJournalBatch.Name, GenJournalTemplate.Name, PostingDate, -2000);

        ImportDomesticPaymentFile(GenJournalBatch.Name, GenJournalTemplate.Name, BankAccount."No.", FileName);
        ValidateGenJournalLinesFile4(GenJournalBatch.Name, GenJournalTemplate.Name, PostingDate, -2000);

        // Validate
        BankRefFileSetup.Get(BankAccount."No.");
    end;

    [Test]
    [HandlerFunctions('PageReqHandler,MessageSink')]
    procedure TestDomesticImportOfPaymentFileFailesWhenThereAreNoMatchingDocuments()
    var
        RefPaymentImported: Record "Ref. Payment - Imported";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        PostingDate: Date;
        FileName: Text;
    begin
        Initialize();
        WorkDate(20060823D);

        // Setup
        Setup(BankAccount, GenJournalBatch, GenJournalTemplate);
        FileName := FillInDomesticPaymentFileSample2();
        PostingDate := DMY2Date(23, 8, 2006);

        // Exercise
        ImportDomesticPaymentFile(GenJournalBatch.Name, GenJournalTemplate.Name, BankAccount."No.", FileName);

        // Validate
        Assert.AreEqual(3, RefPaymentImported.Count, 'Expected number of entries does not match');

        RefPaymentImported.SetRange("Reference No.", '1030229');
        RefPaymentImported.SetRange("Banks Posting Date", PostingDate);
        RefPaymentImported.SetRange("Banks Payment Date", PostingDate);
        RefPaymentImported.SetRange("Payers Name", 'TESTIAS1');
        RefPaymentImported.FindSet();

        Assert.AreEqual(2, RefPaymentImported.Count, 'Expected number of bank payment entries does not match');

        RefPaymentImported.FindFirst();
        Assert.AreEqual(1500.6, RefPaymentImported.Amount, 'Expected amount on first line does not match');

        RefPaymentImported.Next();
        Assert.AreEqual(2000, RefPaymentImported.Amount, 'Expected amount on second line does not match');

        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        Assert.AreEqual(0, GenJournalLine.Count, 'Expected number of entries in Gen. Journal Lines does not match');
    end;

    [Test]
    [HandlerFunctions('PageReqHandler')]
    procedure GenJnlLineBalAccWithBankAccBatchBalAcc()
    var
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        PostingNo: Code[20];
        FileName: Text;
        ReferenceNo: Code[20];
    begin
        // [SCENARIO 415567] "Bal. Account No." should be filled from journal batch "Bal. Account No." if the balance account is empty in reference file and customer ledger entry
        Initialize();
        WorkDate(20060823D);

        // [GIVEN] Bank reference setup, reference file, general journal batch with filled balance account "BA" and "Bank Account" type
        CreateDomesticCustomer(Customer);
        ReferenceNo := CreateAndPostSalesInvoice(Customer, PostingNo);
        Setup(BankAccount, GenJournalBatch, GenJournalTemplate);
        FileName := FillInDomesticPaymentFileSample4(ReferenceNo);

        // [WHEN] Read reference file (general journal line "GJL" is created)
        ImportDomesticPaymentFile(GenJournalBatch.Name, GenJournalTemplate.Name, BankAccount."No.", FileName);

        // [THEN] "GJL"."Bal. Account No." = "BA"
        GenJournalLine.SetRange("Journal Template Name", GenJournalTemplate.Name);
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Bal. Account No.", GenJournalBatch."Bal. Account No.");
    end;

    [Test]
    [HandlerFunctions('PageReqHandler')]
    procedure GenJnlLineBalAccWithGLAccBatchBalAcc()
    var
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        PostingNo: Code[20];
        FileName: Text;
        ReferenceNo: Code[20];
    begin
        // [SCENARIO 415567] "Bal. Account No." should be empty if the balance account type is "G/L Account" in general journal batch
        Initialize();
        WorkDate(20060823D);

        // [GIVEN] Bank reference setup, reference file, general journal batch with filled balance account "BA" and "G/L Account" type
        CreateDomesticCustomer(Customer);
        ReferenceNo := CreateAndPostSalesInvoice(Customer, PostingNo);
        Setup(BankAccount, GenJournalBatch, GenJournalTemplate);
        FileName := FillInDomesticPaymentFileSample4(ReferenceNo);
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"G/L Account";
        GenJournalBatch."Bal. Account No." := LibraryERM.CreateGLAccountNo();
        GenJournalBatch.Modify();

        // [WHEN] Read reference file (general journal line "GJL" is created)
        ImportDomesticPaymentFile(GenJournalBatch.Name, GenJournalTemplate.Name, BankAccount."No.", FileName);

        // [THEN] "GJL"."Bal. Account No." = " "
        GenJournalLine.SetRange("Journal Template Name", GenJournalTemplate.Name);
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Bal. Account No.", '');
    end;

    local procedure Initialize()
    var
        RefPaymentImported: Record "Ref. Payment - Imported";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"E-BANKING Import Test");
        RefPaymentImported.DeleteAll(true);

        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"E-BANKING Import Test");

        Initialized := true;

        BindSubscription(LibraryFileMgtHandler);
        LibraryFileMgtHandler.SetDownloadSubscriberActivated(true); // to avoid downloading backup file to restricted location

        CompanyInformation.Get();
        SetupSalesAndReceivables();
        SetupPaymentTerms();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"E-BANKING Import Test");
    end;

    local procedure Setup(var BankAccount: Record "Bank Account"; var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalTemplate: Record "Gen. Journal Template")
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::"Cash Receipts");
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name, BankAccount."No.");

        SetupBankReferenceFile(BankAccount."No.");
    end;

    local procedure CreateGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; JnlTemplateName: Code[10]; BankAccountNo: Code[20])
    var
        NoSeries: Record "No. Series";
    begin
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, JnlTemplateName);
        GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"Bank Account";
        GenJournalBatch."Bal. Account No." := BankAccountNo;
        NoSeries.FindFirst();
        GenJournalBatch."No. Series" := NoSeries.Code;
        GenJournalBatch."Posting No. Series" := LibraryERM.CreateNoSeriesCode();
        GenJournalBatch.Modify(true);
    end;

    local procedure SetupBankReferenceFile(BankAccountNo: Code[20])
    var
        BankRefFileSetup: Record "Reference File Setup";
    begin
        BankRefFileSetup.Init();
        BankRefFileSetup."No." := BankAccountNo;
        BankRefFileSetup."Inform. of Appl. Cr. Memos" := true;
        BankRefFileSetup.Insert(true);
    end;

    local procedure FillInDomesticPaymentFileSample1(): Text[250]
    var
        FileWriter: File;
        TmpFile: Text;
    begin
        TmpFile := FileMgt.ServerTempFileName('txt');
        FileWriter.TextMode := true;
        FileWriter.Create(TmpFile);
        FileWriter.Write('005112223592 02693808410269380840000000000000000000000000000000000000000000000000000000000');
        FileWriter.Write('31590300012447705112205112111215  LM 06573500000008710101064305KESKO OYJ   1A00000240060A0');
        FileWriter.Write('31590300012447705112205112111215  LM 06573600000008710101064318KESKO OYJ   1A00000240060A0');
        FileWriter.Write('31590300012447705112205112111215  LM 06573700000008710101064321KESKO OYJ   1A00000240060A0');
        FileWriter.Write('31590300012447705112205112111215  LM 06573800000008710101064334KESKO OYJ   1A00000240060A0');
        FileWriter.Write('900000400000096024000000000000000000000000000000000000000000000000000000000000000000000000');
        FileWriter.Close();

        exit(TmpFile);
    end;

    local procedure FillInDomesticPaymentFileSample2(): Text[250]
    var
        FileWriter: File;
        TmpFile: Text;
    begin
        TmpFile := FileMgt.ServerTempFileName('txt');
        FileWriter.TextMode := true;
        FileWriter.Create(TmpFile);
        FileWriter.Write('006082323592 08948590810654467340000000000000000000000000000000000000000000000000000000000');
        FileWriter.Write('30000000145567806082306082308232588NGP4073800000000000001030229TESTIAS1    1J00001500600A0');
        FileWriter.Write('30000000145567806082306082309232588NGP4073800000000000001030229TESTIAS1    1J00002000000A0');
        FileWriter.Close();

        exit(TmpFile);
    end;

    local procedure FillInDomesticPaymentFileSample3(FirstStep: Boolean; ReferenceNo: Code[20]): Text[250]
    var
        FileWriter: File;
        TmpFile: Text;
    begin
        TmpFile := FileMgt.ServerTempFileName('txt');
        FileWriter.TextMode := true;
        FileWriter.Create(TmpFile);

        FileWriter.Write('006082323592 08948590810654467340000000000000000000000000000000000000000000000000000000000');
        if FirstStep then
            FileWriter.Write('30000000145567806082306082308232588NGP407380000000000000' + ReferenceNo + 'TESTIAS1    1J00002000000A0')
        else
            FileWriter.Write('30000000145567806082306082309232588NGP407380000000000000' + ReferenceNo + 'TESTIAS1    1J00001500600A0');

        FileWriter.Close();

        exit(TmpFile);
    end;

    local procedure FillInDomesticPaymentFileSample4(ReferenceNo: Code[20]): Text[250]
    var
        FileWriter: File;
        TmpFile: Text;
    begin
        TmpFile := FileMgt.ServerTempFileName('txt');
        FileWriter.TextMode := true;
        FileWriter.Create(TmpFile);

        FileWriter.Write('006082323592 08948590810654467340000000000000000000000000000000000000000000000000000000000');
        FileWriter.Write('30000000145567806082306082308232588NGP407380000000000000' + ReferenceNo + 'TESTIAS1    1J00002000000A0');

        FileWriter.Close();

        exit(TmpFile);
    end;

    local procedure SetupSalesAndReceivables()
    var
        SalesAndReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesAndReceivablesSetup.Get();
        SalesAndReceivablesSetup."Invoice No." := true;
        SalesAndReceivablesSetup."Customer No." := false;
        SalesAndReceivablesSetup.Date := false;
        SalesAndReceivablesSetup."Default Number" := '';
        SalesAndReceivablesSetup."Reference Nos." := '';

        SalesAndReceivablesSetup.Modify(true);
    end;

    local procedure SetupPaymentTerms()
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        Evaluate(PaymentTerms."Due Date Calculation", '<40D>');
        Evaluate(PaymentTerms."Discount Date Calculation", '<5D>');
        PaymentTerms.Validate("Due Date Calculation");
        PaymentTerms.Validate("Discount Date Calculation");
        PaymentTerms."Discount %" := 2;
        PaymentTerms.Modify(true);
    end;

    local procedure ImportDomesticPaymentFile(GenJournalBatchName: Code[10]; JnlTemplateName: Code[10]; BankAccountNo: Code[20]; FileName: Text)
    var
        ImportRefPayment: Report "Import Ref. Payment";
    begin
        Commit();
        LibraryVariableStorage.Clear();
        LibraryVariableStorage.Enqueue(BankAccountNo);
        ImportRefPayment.InitializeRequest(FileName);
        ImportRefPayment.SetLedgerNames(GenJournalBatchName, JnlTemplateName);
        ImportRefPayment.UseRequestPage := true;
        ImportRefPayment.RunModal();
    end;

    local procedure ValidateAndGetGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal; GenJournalBatchName: Code[20]; GenJournalTemplateName: Code[20]; PostingNo: Code[20]; ReferenceNo: Code[20])
    begin
        Clear(GenJournalLine);
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatchName);
        GenJournalLine.SetRange("Journal Template Name", GenJournalTemplateName);
        GenJournalLine.Validate("Posting Date", DMY2Date(22, 11, 2005));
        GenJournalLine.SetRange("Applies-to Doc. No.", PostingNo);
        GenJournalLine.SetRange("Reference No.", ReferenceNo);
        Assert.AreEqual(1, GenJournalLine.Count, 'Expected number of entries in Gen. Journal Lines does not match');
        GenJournalLine.FindFirst();
        Assert.AreEqual(-Amount, GenJournalLine.Amount, 'Expected amount on first line does not match');
    end;

    [RequestPageHandler]
    procedure PageReqHandler(var TestRequestPage: TestRequestPage "Import Ref. Payment")
    var
        BankAccountNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BankAccountNo);
        TestRequestPage.BankAccCode.SetValue(BankAccountNo);
        TestRequestPage.OK().Invoke();
    end;

    [MessageHandler]
    procedure MessageSink(Message: Text[1024])
    begin
    end;

    local procedure CreateDomesticCustomer(var Customer: Record Customer)
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer."Country/Region Code" := CompanyInformation."Country/Region Code";
        Customer."Payment Terms Code" := PaymentTerms.Code;
        Customer.Modify(true);
    end;

    local procedure CreateAndPostSalesInvoice(var Customer: Record Customer; var PostingNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        SalesHeader."Posting No." := PostingNo;
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", '3140', 1);
        SalesLine.Validate("VAT Prod. Posting Group", 'NO VAT');
        SalesLine.Validate("Unit Price", 244.96);
        SalesLine.Modify(true);

        PostingNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        CustLedgerEntry.SetRange("Document Type", SalesHeader."Document Type".AsInteger());
        CustLedgerEntry.SetRange("Document No.", PostingNo);
        CustLedgerEntry.FindFirst();
        exit(CustLedgerEntry."Reference No.");
    end;

    local procedure ValidateGenJournalLines(GenJournalBatchName: Code[10]; JnlTemplateName: Code[10]; InvoicesCount: Integer; PostingDate: Date; ExpectedAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        InvoiceNo: Variant;
    begin
        GenJournalLine.SetRange("Journal Template Name", JnlTemplateName);
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatchName);
        GenJournalBatch.Get(JnlTemplateName, GenJournalBatchName);
        Assert.AreEqual(InvoicesCount, GenJournalLine.Count, 'Expected Gen. Journal Lines count does not match');

        GenJournalLine.FindSet();
        repeat
            Assert.AreEqual(PostingDate, GenJournalLine."Posting Date", 'Posting Date does not match');
            Assert.AreEqual(ExpectedAmount, GenJournalLine.Amount, 'Amount does not match');
            Assert.AreEqual(
              GenJournalLine."Posting No. Series",
              GenJournalBatch."Posting No. Series",
              GenJournalLine.FieldCaption("Posting No. Series"));
            Assert.AreEqual(GenJournalLine."Applies-to Doc. Type"::Invoice,
              GenJournalLine."Applies-to Doc. Type",
              'Applies-to Doc. Type does not match');
            LibraryVariableStorage2.Dequeue(InvoiceNo);
            Assert.AreEqual(InvoiceNo, GenJournalLine."Applies-to Doc. No.", 'Applies-to Doc. No. does not match');
        until GenJournalLine.Next() = 0;
        LibraryVariableStorage2.AssertEmpty();
    end;

    local procedure ValidateGenJournalLinesFile4(GenJournalBatchName: Code[10]; JnlTemplateName: Code[10]; PostingDate: Date; ExpectedAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalLine.SetRange("Journal Template Name", JnlTemplateName);
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatchName);
        GenJournalBatch.Get(JnlTemplateName, GenJournalBatchName);
        Assert.RecordCount(GenJournalLine, 1);

        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Posting Date", PostingDate);
        GenJournalLine.TestField(Amount, ExpectedAmount);
        GenJournalLine.TestField("Posting No. Series", GenJournalBatch."Posting No. Series");
        GenJournalLine.TestField("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
    end;
}

