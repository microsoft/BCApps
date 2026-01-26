codeunit 144050 "ERM Make 340 Declar. for CAC"
{
    // // [FEATURE] [340 Declaration]

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        ValueNotFoundMsg: Label 'Value Not found.';
        DocNoNotFoundInLineErr: Label 'not found on expected position 218';
        Library340347Declaration: Codeunit "Library - 340 347 Declaration";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryCarteraPayables: Codeunit "Library - Cartera Payables";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        NoRecordsInDeclErr: Label 'No records were found to be included in the declaration';
        WrongOperationCodeErr: Label 'Operation Code must not be %1 in 340 Declaration Line Key=''%2';
        WrongTotalNoOfRecsErr: Label 'Wrong total no. of records';
        WrongNoOfPaymentRecordsErr: Label 'Wrong number of payment records';
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure PaymentFromCustomerFullyAppliedOnGLAccNotEqualToCashAccount()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        InvoiceDocNo: Code[20];
        Amount: Decimal;
        ReferenceDate: Date;
        ExportFileName: Text[1024];
    begin
        // [FEATURE] [MODELO340.CAC]
        // [SCENARIO 26] Sales payment in cash reported with empty Collection info
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        // [GIVEN] CAC Sales Invoice is posted
        ReferenceDate := WorkDate();

        GLAccount.Get(CreateGLAccount());
        GLAccount."Direct Posting" := true;
        GLAccount.Modify();

        Customer.Get(CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        Customer."VAT Registration No." := CopyStr(CreateGuid(), 1, 9);
        Customer.Modify();

        InvoiceDocNo := Library340347Declaration.CreateAndPostSalesInvoice(VATPostingSetup, Customer."No.", ReferenceDate, Amount);
        // [GIVEN] and fully paid by Payment in cash (to a G/L Account)
        ApplyAndPostPayment(
          InvoiceDocNo, Customer."No.", GLAccount."No.", Amount, GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReportWithGLAcc(ReferenceDate, GLAccount."No.");
        // [THEN] Payment record contains blank Collection info
        TempTest340DeclarationLineBuf."Document No." := PadStr('', 20, ' ');
        TempTest340DeclarationLineBuf."VAT Document No." := '';
        TempTest340DeclarationLineBuf."Operation Code" := '';
        TempTest340DeclarationLineBuf."Collection Date" := 0D;
        TempTest340DeclarationLineBuf."Collection Amount" := 0;
        TempTest340DeclarationLineBuf."Collection Payment Method" := '';
        TempTest340DeclarationLineBuf."Collection Bank Acc./Check No." := '';
        TempTest340DeclarationLineBuf.Type := TempTest340DeclarationLineBuf.Type::Sale;
        TempTest340DeclarationLineBuf.Insert();

        VerifyCollectionInfoInFile(ExportFileName, TempTest340DeclarationLineBuf);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceNoOnPayment()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        CustomerNo: Code[20];
        ServiceInvNo: Code[20];
        PaymentNo: Code[20];
        ExportFileName: Text[1024];
        Amount: Decimal;
        Line: Text[1024];
    begin
        // [FEATURE] [MODELO340.CAC] [Sales]
        // [SCENARIO 09] Invoice's 'Document No.' is reported for payment applied to CAC Service Invoice
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        // [GIVEN] CAC Service Invoice 'SERV.INV' is posted and fully paid by Payment 'PMT'
        CustomerNo := CreateCustomer(VATPostingSetup."VAT Bus. Posting Group");
        ServiceInvNo := Library340347Declaration.CreateAndPostServiceInvoice(VATPostingSetup, CustomerNo, WorkDate(), Amount);
        PaymentNo := Library340347Declaration.CreateAndPostPaymentForSI(CustomerNo, "Gen. Journal Document Type"::Invoice, ServiceInvNo, WorkDate(), Amount);

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] Payment record 'Document No.'='SERV.INV'
        FillSalesExpectedBuffer(TempTest340DeclarationLineBuf, PaymentNo, ServiceInvNo, '', '', '');
        Line := FindLine(ExportFileName, TempTest340DeclarationLineBuf.GetFieldPos(TempTest340DeclarationLineBuf.FieldNo("Document No.")), PaymentNo);
        TempTest340DeclarationLineBuf.VerifyField(Line, TempTest340DeclarationLineBuf.FieldNo("VAT Document No."))
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvoiceNoOnPayment()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        VendorNo: Code[20];
        ExtPurchaseInvNo: Code[35];
        PurchaseInvNo: Code[20];
        PaymentNo: Code[20];
        ExportFileName: Text[1024];
        Amount: Decimal;
        Line: Text[1024];
    begin
        // [FEATURE] [MODELO340.CAC] [Purchase]
        // [SCENARIO 09] Invoice's 'External Document No.' is reported for payment applied to CAC Purchase Invoice
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        // [GIVEN] CAC Purchase Invoice 'P.INV' with 'Vendor Invoice No.' = 'EXT.P.INV' is posted
        VendorNo := CreateVendor(VATPostingSetup."VAT Bus. Posting Group");
        PurchaseInvNo :=
          Library340347Declaration.CreateAndPostPurchaseInvoice(VATPostingSetup, VendorNo, WorkDate(), Amount, ExtPurchaseInvNo);
        // [GIVEN] and fully paid by Payment 'PMT'
        PaymentNo := Library340347Declaration.CreateAndPostPaymentForPI(VendorNo, "Gen. Journal Document Type"::Invoice, PurchaseInvNo, WorkDate(), Amount);

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] Payment record 'Document No.' = 'EXT.P.INV'
        FillPurchExpectedBuffer(TempTest340DeclarationLineBuf, PaymentNo, ExtPurchaseInvNo, '', '', '', 1);
        Line := FindLine(ExportFileName, TempTest340DeclarationLineBuf.GetFieldPos(TempTest340DeclarationLineBuf.FieldNo("Document No.")), PaymentNo);
        TempTest340DeclarationLineBuf.VerifyField(Line, TempTest340DeclarationLineBuf.FieldNo("VAT Document No."))
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure FullPaymentOfServiceInvoice()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        CustomerNo: Code[20];
        ServiceInvNo: Code[20];
        PaymentNo: Code[20];
        ExportFileName: Text[1024];
        Amount: Decimal;
    begin
        // [FEATURE] [MODELO340.CAC] [Sales]
        // [SCENARIO 03] Full payment of CAC Service Invoice.
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        // [GIVEN] CAC Service Invoice is posted and fully paid by Payment
        CustomerNo := CreateCustomer(VATPostingSetup."VAT Bus. Posting Group");
        ServiceInvNo := Library340347Declaration.CreateAndPostServiceInvoice(VATPostingSetup, CustomerNo, WorkDate(), Amount);
        PaymentNo := Library340347Declaration.CreateAndPostPaymentForSI(CustomerNo, "Gen. Journal Document Type"::Invoice, ServiceInvNo, WorkDate(), Amount);

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] Service Payment is reported as Z record with filled collection info
        FillSalesExpectedBuffer(TempTest340DeclarationLineBuf, PaymentNo, ServiceInvNo, 'Z', 'C', FindBancAccountNoUsed(true, CustomerNo));
        VerifyCollectionInfoInFile(ExportFileName, TempTest340DeclarationLineBuf);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure BankAccNonEmptyVend()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        BankAccount: Record "Bank Account";
        PurchInvHeader: Record "Purch. Inv. Header";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        ExpectedPmtMethod: Code[10];
        VendorNo: Code[20];
        ExtPurchaseInvNo: Code[35];
        PurchaseInvNo: Code[20];
        PaymentNo: Code[20];
        SavedBankCCCNo: Code[20];
        ExportFileName: Text[1024];
        Amount: Decimal;
    begin
        // [FEATURE] [MODELO340.CAC] [Purchase]
        // [SCENARIO 19] Payment Method Code for type 'O' is taken from Purchase Invoice
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        // [GIVEN] CAC Purchase Invoice is posted
        VendorNo := CreateVendor(VATPostingSetup."VAT Bus. Posting Group");
        PurchaseInvNo :=
          Library340347Declaration.CreateAndPostPurchaseInvoice(VATPostingSetup, VendorNo, WorkDate(), Amount, ExtPurchaseInvNo);

        PurchInvHeader.Get(PurchaseInvNo);
        ExpectedPmtMethod := PurchInvHeader."Payment Method Code";
        // [GIVEN] Vendor's Payment Method is changed
        Vendor.Get(VendorNo);
        Vendor."Payment Method Code" := GetNextPmtMethod(Vendor."Payment Method Code");
        Vendor.Modify();
        // [GIVEN] Invoice is partially paid in next month
        Amount := Amount - LibraryRandom.RandIntInRange(1, 10);
        WorkDate(CalcDate('<+1M>', WorkDate()));
        PaymentNo := Library340347Declaration.CreateAndPostPaymentForPI(VendorNo, "Gen. Journal Document Type"::Invoice, PurchaseInvNo, WorkDate(), Amount);

        // [GIVEN] Bank Account's account info is blank
        SavedBankCCCNo := DeleteBankAccountsInfo(FindBancAccountUsed(false, VendorNo));
        Commit();

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] Payment is reported as 'Z' record with Payment Method from Invoice
        Vendor.Get(VendorNo);
        FillPurchExpectedBuffer(TempTest340DeclarationLineBuf, PaymentNo, ExtPurchaseInvNo, 'Z', 'O', ExpectedPmtMethod, 1);
        VerifyCollectionInfoInFile(ExportFileName, TempTest340DeclarationLineBuf);

        BankAccount.Get(FindBancAccountUsed(false, VendorNo));
        BankAccount.Validate("CCC No.", SavedBankCCCNo);
        BankAccount.Modify();
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure BankAccNonEmptyCust()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
        SalesInvHeader: Record "Sales Invoice Header";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        ExpectedPmtMethod: Code[10];
        CustomerNo: Code[20];
        SalesInvNo: Code[20];
        PaymentNo: Code[20];
        SavedBankCCCNo: Code[20];
        ExportFileName: Text[1024];
        Amount: Decimal;
    begin
        // [FEATURE] [MODELO340.CAC] [Sales]
        // [SCENARIO 19] Payment Method Code for type 'O' is taken from Sales Invoice
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        // [GIVEN] CAC Sales Invoice is posted
        CustomerNo := CreateCustomer(VATPostingSetup."VAT Bus. Posting Group");
        SalesInvNo := Library340347Declaration.CreateAndPostSalesInvoice(VATPostingSetup, CustomerNo, WorkDate(), Amount);
        SalesInvHeader.Get(SalesInvNo);
        ExpectedPmtMethod := SalesInvHeader."Payment Method Code";
        // [GIVEN] CAC Invoice is paid in the next period
        WorkDate(CalcDate('<+1M>', WorkDate()));
        PaymentNo := Library340347Declaration.CreateAndPostPaymentForSI(CustomerNo, "Gen. Journal Document Type"::Invoice, SalesInvNo, WorkDate(), Amount);

        // [GIVEN] Bank Account's account info is blank
        SavedBankCCCNo := DeleteBankAccountsInfo(FindBancAccountUsed(true, CustomerNo));
        Commit();

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] Payment is reported as 'Z' record with Payment Type 'O' and Invoice's Payment Method
        Customer.Get(CustomerNo);
        FillSalesExpectedBuffer(TempTest340DeclarationLineBuf, PaymentNo, SalesInvNo, 'Z', 'O', ExpectedPmtMethod);
        VerifyCollectionInfoInFile(ExportFileName, TempTest340DeclarationLineBuf);

        BankAccount.Get(FindBancAccountUsed(true, CustomerNo));
        BankAccount.Validate("CCC No.", SavedBankCCCNo);
        BankAccount.Modify();
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure BankAccNonIBAN()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        BankAccount: Record "Bank Account";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        VendorNo: Code[20];
        ExtPurchaseInvNo: Code[35];
        PurchaseInvNo: Code[20];
        PaymentNo: Code[20];
        SavedBankCCCNo: Code[20];
        ExportFileName: Text[1024];
        Amount: Decimal;
    begin
        // [FEATURE] [MODELO340.CAC] [Purchase]
        // [SCENARIO 20] IBAN is reported when 'CCC No.' and 'Bank Account No.' are empty
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        // [GIVEN] CAC Purchase Invoice is posted
        VendorNo := CreateVendor(VATPostingSetup."VAT Bus. Posting Group");
        PurchaseInvNo :=
          Library340347Declaration.CreateAndPostPurchaseInvoice(VATPostingSetup, VendorNo, WorkDate(), Amount, ExtPurchaseInvNo);

        // [GIVEN] CAC Invoice is partially paid in the next period
        Amount := Amount - LibraryRandom.RandIntInRange(1, 10);
        WorkDate(CalcDate('<+1M>', WorkDate()));
        PaymentNo := Library340347Declaration.CreateAndPostPaymentForPI(VendorNo, "Gen. Journal Document Type"::Invoice, PurchaseInvNo, WorkDate(), Amount);
        // [GIVEN] 'CCC No.' and 'Bank Account No.' are empty on the Bank Account
        BankAccount.Get(FindBancAccountUsed(false, VendorNo));
        BankAccount."Bank Account No." := '';
        SavedBankCCCNo := BankAccount."CCC No.";
        BankAccount.Validate("CCC No.", '');
        BankAccount.IBAN := CopyStr(CreateGuid(), 1, 35);
        BankAccount.Modify();
        Commit();

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] Payment is reported as 'Z' record with Payment Type 'C' and IBAN
        FillPurchExpectedBuffer(TempTest340DeclarationLineBuf, PaymentNo, ExtPurchaseInvNo, 'Z', 'C', CopyStr(BankAccount.IBAN, 1, 35), 1);
        VerifyCollectionInfoInFile(ExportFileName, TempTest340DeclarationLineBuf);

        BankAccount.Validate("CCC No.", SavedBankCCCNo);
        BankAccount.Modify();
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure BankAccNonW1BankAccNoField()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        BankAccount: Record "Bank Account";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        VendorNo: Code[20];
        ExtPurchaseInvNo: Code[35];
        PurchaseInvNo: Code[20];
        PaymentNo: Code[20];
        SavedBankCCCNo: Code[20];
        ExportFileName: Text[1024];
        Amount: Decimal;
    begin
        // [FEATURE] [MODELO340.CAC] [Purchase]
        // [SCENARIO 20] 'Bank Account No.' is reported when 'CCC No.' is empty
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        // [GIVEN] CAC Purchase Invoice is posted
        VendorNo := CreateVendor(VATPostingSetup."VAT Bus. Posting Group");
        PurchaseInvNo :=
          Library340347Declaration.CreateAndPostPurchaseInvoice(VATPostingSetup, VendorNo, WorkDate(), Amount, ExtPurchaseInvNo);

        // [GIVEN] CAC Invoice is partially paid in the next period
        Amount := Amount - LibraryRandom.RandIntInRange(1, 10);
        WorkDate(CalcDate('<+1M>', WorkDate()));
        PaymentNo := Library340347Declaration.CreateAndPostPaymentForPI(VendorNo, "Gen. Journal Document Type"::Invoice, PurchaseInvNo, WorkDate(), Amount);

        // [GIVEN] 'CCC No.' and 'IBAN' are empty on the Bank Account
        BankAccount.Get(FindBancAccountUsed(false, VendorNo));
        SavedBankCCCNo := BankAccount."CCC No.";
        BankAccount.Validate("CCC No.", '');
        BankAccount.IBAN := '';
        BankAccount."Bank Account No." := CopyStr(CreateGuid(), 1, 30);
        BankAccount.Modify();
        Commit();

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] Payment is reported as 'Z' record with Payment Type 'C' and 'Bank Account No.'
        FillPurchExpectedBuffer(TempTest340DeclarationLineBuf, PaymentNo, ExtPurchaseInvNo, 'Z', 'C', BankAccount."Bank Account No.", 1);
        VerifyCollectionInfoInFile(ExportFileName, TempTest340DeclarationLineBuf);

        BankAccount.Validate("CCC No.", SavedBankCCCNo);
        BankAccount.Modify();
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure NewServiceInvoice()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        Amount: Decimal;
        ServiceInvNo: Code[20];
        CustomerNo: Code[20];
        ExportFileName: Text[1024];
    begin
        // [FEATURE] [MODELO340.CAC] [Service]
        // [SCENARIO 03] New Service Invoice under CAC
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        // [GIVEN] CAC Service Invoice is posted
        CustomerNo := CreateCustomer(VATPostingSetup."VAT Bus. Posting Group");
        ServiceInvNo := Library340347Declaration.CreateAndPostServiceInvoice(VATPostingSetup, CustomerNo, WorkDate(), Amount);

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] Service Invoice is reported as 'Z' record with empty collection info
        FillSalesExpectedBuffer(TempTest340DeclarationLineBuf, ServiceInvNo, ServiceInvNo, 'Z', '', '');
        VerifyCollectionInfoInFile(ExportFileName, TempTest340DeclarationLineBuf);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure PartialPaymentOfPurchaseInvoice()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        VendorNo: Code[20];
        ExtPurchaseInvNo: Code[35];
        PurchaseInvNo: Code[20];
        PaymentNo: Code[20];
        ExportFileName: Text[1024];
        Amount: Decimal;
    begin
        // [FEATURE] [MODELO340.CAC] [Purchase]
        // [SCENARIO 04] Partial payment for Purchase Invoice
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        // [GIVEN] CAC Purchase Invoice is posted
        VendorNo := CreateVendor(VATPostingSetup."VAT Bus. Posting Group");
        PurchaseInvNo :=
          Library340347Declaration.CreateAndPostPurchaseInvoice(VATPostingSetup, VendorNo, WorkDate(), Amount, ExtPurchaseInvNo);

        // [GIVEN] CAC Invoice is partially paid in the next period
        Amount := Amount - LibraryRandom.RandIntInRange(1, 10);
        WorkDate(CalcDate('<+1M>', WorkDate()));
        PaymentNo := Library340347Declaration.CreateAndPostPaymentForPI(VendorNo, "Gen. Journal Document Type"::Invoice, PurchaseInvNo, WorkDate(), Amount);

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] Payment is reported as 'Z' record with filled collection info
        FillPurchExpectedBuffer(
          TempTest340DeclarationLineBuf, PaymentNo, ExtPurchaseInvNo, 'Z', 'C', FindBancAccountNoUsed(false, VendorNo), 1);
        VerifyCollectionInfoInFile(ExportFileName, TempTest340DeclarationLineBuf);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure FullPaymentOfPurchaseInvoice()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        VendorNo: Code[20];
        ExtPurchaseInvNo: Code[35];
        PurchaseInvNo: Code[20];
        PaymentNo: Code[20];
        ExportFileName: Text[1024];
        Amount: Decimal;
    begin
        // [FEATURE] [MODELO340.CAC] [Purchase]
        // [SCENARIO 04] Fulll payment for Purchase Invoice
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        // [GIVEN] CAC Purchase Invoice is posted
        VendorNo := CreateVendor(VATPostingSetup."VAT Bus. Posting Group");
        PurchaseInvNo :=
          Library340347Declaration.CreateAndPostPurchaseInvoice(VATPostingSetup, VendorNo, WorkDate(), Amount, ExtPurchaseInvNo);

        // [GIVEN] CAC Invoice is fully paid in the next period
        WorkDate(CalcDate('<+1M>', WorkDate()));
        PaymentNo := Library340347Declaration.CreateAndPostPaymentForPI(VendorNo, "Gen. Journal Document Type"::Invoice, PurchaseInvNo, WorkDate(), Amount);

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] Payment is reported as 'Z' record with filled collection info
        FillPurchExpectedBuffer(
          TempTest340DeclarationLineBuf, PaymentNo, ExtPurchaseInvNo, 'Z', 'C', FindBancAccountNoUsed(false, VendorNo), 1);
        VerifyCollectionInfoInFile(ExportFileName, TempTest340DeclarationLineBuf);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure NewPurchaseCrMemo()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        CrMemoNo: Code[20];
        ExtCrMemoNo: Code[35];
        Amount: Decimal;
        ExportFileName: Text[1024];
    begin
        // [FEATURE] [MODELO340.CAC] [Purchase]
        // [SCENARIO 08] New CAC Purchase Credit Memo
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        // [GIVEN] CAC Purchase Credit Memo is posted
        CrMemoNo := Library340347Declaration.CreateAndPostPurchaseCrMemo(
            VATPostingSetup, CreateVendor(VATPostingSetup."VAT Bus. Posting Group"), WorkDate(), Amount, ExtCrMemoNo, '');

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] Credit Memo is reported as 3 record with empty collection info
        FillPurchExpectedBuffer(TempTest340DeclarationLineBuf, CrMemoNo, ExtCrMemoNo, '3', '', '', 1);
        VerifyCollectionInfoInFile(ExportFileName, TempTest340DeclarationLineBuf);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure NewPurchaseInvoice()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        ExtPurchaseInvNo: Code[35];
        PurchaseInvNo: Code[20];
        Amount: Decimal;
        ExportFileName: Text[1024];
    begin
        // [FEATURE] [MODELO340.CAC] [Purchase]
        // [SCENARIO 04] New Purchase Invoice under CAC
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        // [GIVEN] CAC Purchase Invoice is posted
        PurchaseInvNo := Library340347Declaration.CreateAndPostPurchaseInvoice(
            VATPostingSetup, CreateVendor(VATPostingSetup."VAT Bus. Posting Group"), WorkDate(), Amount, ExtPurchaseInvNo);

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] Invoice is reported as 'Z' record with empty collection info
        FillPurchExpectedBuffer(TempTest340DeclarationLineBuf, PurchaseInvNo, ExtPurchaseInvNo, 'Z', '', '', 1);
        VerifyCollectionInfoInFile(ExportFileName, TempTest340DeclarationLineBuf);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure PaidPurchaseCrMemo()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        CrMemoNo: Code[20];
        ExternalCrMemoNo: Code[35];
        RefundNo: Code[20];
        VendorNo: Code[20];
        Amount: Decimal;
        ExportFileName: Text[1024];
    begin
        // [FEATURE] [MODELO340.CAC] [Purchase]
        // [SCENARIO 08] Purchase CAC Credit Memo fully paid by Refund, reported as '3'

        // [GIVEN] Unrealized VAT is set
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        // [GIVEN] Posted CAC Credit Memo, not applied to Invoice
        VendorNo := CreateVendor(VATPostingSetup."VAT Bus. Posting Group");
        CrMemoNo := Library340347Declaration.CreateAndPostPurchaseCrMemo(VATPostingSetup, VendorNo, WorkDate(), Amount, ExternalCrMemoNo, '');
        // [GIVEN] Credit Memo is paid by Refund in the next month
        WorkDate(CalcDate('<+1M>', WorkDate()));
        RefundNo := Library340347Declaration.CreateAndPostPaymentForPI(VendorNo, "Gen. Journal Document Type"::"Credit Memo", CrMemoNo, WorkDate(), -Amount);

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] Refund is reported as '3' record
        // [THEN] External Credit Memo No. is reported as Document No.
        FillPurchExpectedBuffer(TempTest340DeclarationLineBuf, RefundNo, ExternalCrMemoNo, '3', 'C', FindBancAccountNoUsed(false, VendorNo), 1);
        VerifyCollectionInfoInFile(ExportFileName, TempTest340DeclarationLineBuf);
    end;

    [Test]
    [HandlerFunctions('Make340DeclarationHandler')]
    [Scope('OnPrem')]
    procedure UnappliedPurchaseCrMemo()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VendLedgEntry: Record "Vendor Ledger Entry";
        CrMemoNo: Code[20];
        ExternalCrMemoNo: Code[35];
        VendorNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [MODELO340.CAC] [Purchase]
        // [SCENARIO 21] Unapplied Refund to Purchase CAC Credit Memo is not reported
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        // [GIVEN] Posted CAC Credit Memo, not applied to Invoice
        VendorNo := CreateVendor(VATPostingSetup."VAT Bus. Posting Group");
        CrMemoNo := Library340347Declaration.CreateAndPostPurchaseCrMemo(VATPostingSetup, VendorNo, WorkDate(), Amount, ExternalCrMemoNo, '');
        // [GIVEN] Credit Memo is paid by Refund in the next month
        WorkDate(CalcDate('<+1M>', WorkDate()));
        Library340347Declaration.CreateAndPostPaymentForPI(VendorNo, "Gen. Journal Document Type"::"Credit Memo", CrMemoNo, WorkDate(), -Amount);
        // [GIVEN] Refund is unapplied in the same month
        VendLedgEntry.FindLast();
        LibraryERM.UnapplyVendorLedgerEntry(VendLedgEntry);
        Commit();

        // [WHEN] Export by report 'Make 340 Declaration'
        asserterror Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] Refund is not reported
        Assert.ExpectedError(NoRecordsInDeclErr);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure PartialPaymentOfSalesInvoiceByCrMemo()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        CustomerNo: Code[20];
        SalesInvNo: Code[20];
        CrMemoNo: Code[20];
        ExportFileName: Text[1024];
        Amount: Decimal;
    begin
        // [FEATURE] [MODELO340.CAC] [Sales]
        // [SCENARIO 03] Sales Invoice is partially paid by Cr. Memo
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        // [GIVEN] CAC Sales Invoice is posted
        CustomerNo := CreateCustomer(VATPostingSetup."VAT Bus. Posting Group");
        SalesInvNo := Library340347Declaration.CreateAndPostSalesInvoice(VATPostingSetup, CustomerNo, WorkDate(), Amount);
        // [GIVEN] Invoice is partially reverted by Credit Memo
        Amount := Round(Amount * 0.3);
        CrMemoNo := Library340347Declaration.CreateAndPostSalesCrMemo(VATPostingSetup, CustomerNo, WorkDate(), Amount, SalesInvNo);

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] Credit Memo is reported as 3 record without collection info
        FillSalesExpectedBuffer(TempTest340DeclarationLineBuf, CrMemoNo, CrMemoNo, '3', '', '');
        VerifyCollectionInfoInFile(ExportFileName, TempTest340DeclarationLineBuf);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure PartialPaymentOfSalesInvoice()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        CustomerNo: Code[20];
        SalesInvNo: Code[20];
        PaymentNo: Code[20];
        ExportFileName: Text[1024];
        Amount: Decimal;
    begin
        // [FEATURE] [MODELO340.CAC] [Sales]
        // [SCENARIO 03] Partial payment of CAC Sales Invoice.
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        // [GIVEN] CAC Sales Invoice is posted
        CustomerNo := CreateCustomer(VATPostingSetup."VAT Bus. Posting Group");
        SalesInvNo := Library340347Declaration.CreateAndPostSalesInvoice(VATPostingSetup, CustomerNo, WorkDate(), Amount);

        // [GIVEN] Invoice is partially paid by Payment in the next period
        Amount := Round(Amount * 0.3);
        WorkDate(CalcDate('<+1M>', WorkDate()));
        PaymentNo := Library340347Declaration.CreateAndPostPaymentForSI(CustomerNo, "Gen. Journal Document Type"::Invoice, SalesInvNo, WorkDate(), Amount);
        Commit();

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] Payment is reported as Z record with collection info
        FillSalesExpectedBuffer(TempTest340DeclarationLineBuf, PaymentNo, SalesInvNo, 'Z', 'C', FindBancAccountNoUsed(true, CustomerNo));
        VerifyCollectionInfoInFile(ExportFileName, TempTest340DeclarationLineBuf);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure FullPaymentOfSalesInvoice()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        CustomerNo: Code[20];
        SalesInvNo: Code[20];
        PaymentNo: Code[20];
        ExportFileName: Text[1024];
        Amount: Decimal;
    begin
        // [FEATURE] [MODELO340.CAC] [Sales]
        // [SCENARIO 03] Full payment of Sales Invoice.
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        // [GIVEN] CAC Sales Invoice is posted
        CustomerNo := CreateCustomer(VATPostingSetup."VAT Bus. Posting Group");
        SalesInvNo := Library340347Declaration.CreateAndPostSalesInvoice(VATPostingSetup, CustomerNo, WorkDate(), Amount);

        // [GIVEN] Invoice is fully paid by Payment in the next period
        WorkDate(CalcDate('<+1M>', WorkDate()));
        PaymentNo := Library340347Declaration.CreateAndPostPaymentForSI(CustomerNo, "Gen. Journal Document Type"::Invoice, SalesInvNo, WorkDate(), Amount);

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] Payment is reported as Z record with collection info
        FillSalesExpectedBuffer(TempTest340DeclarationLineBuf, PaymentNo, SalesInvNo, 'Z', 'C', FindBancAccountNoUsed(true, CustomerNo));
        VerifyCollectionInfoInFile(ExportFileName, TempTest340DeclarationLineBuf);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure FullPaymentOfSalesInvoiceTypeC()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        CustomerNo: Code[20];
        SalesInvNo: Code[20];
        PaymentNo: Code[20];
        ExportFileName: Text[1024];
        Amount: array[2] of Decimal;
        TaxPct: array[2] of Decimal;
    begin
        // [FEATURE] [MODELO340.CAC] [Sales]
        // [SCENARIO 17] Payment record for Sales Invoice with 2 VAT groups 'C' has Operation Code '2'
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        // [GIVEN] CAC Sales Invoice is posted
        CustomerNo := CreateCustomer(VATPostingSetup."VAT Bus. Posting Group");
        SalesInvNo := CreateAndPostSalesInvoiceTypeC(VATPostingSetup, CustomerNo, WorkDate(), Amount, TaxPct);

        // [GIVEN] Invoice is fully paid by Payment
        PaymentNo :=
          Library340347Declaration.CreateAndPostPaymentForSI(
            CustomerNo, "Gen. Journal Document Type"::Invoice, SalesInvNo, WorkDate(), Amount[1] + Amount[2]);

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] Invoice is reported as 2 records with operation code 2
        FillSalesExpectedBuffer(TempTest340DeclarationLineBuf, SalesInvNo, SalesInvNo, '2', '', '');
        TempTest340DeclarationLineBuf.UpdateTaxAmount(0, 0, 2);
        // [THEN] Payment is reported as 2 records of Type '2' with collection info
        FillSalesExpectedBuffer(TempTest340DeclarationLineBuf, PaymentNo, SalesInvNo, '2', 'C', FindBancAccountNoUsed(true, CustomerNo));
        TempTest340DeclarationLineBuf.UpdateTaxAmount(TaxPct[1], Amount[1], 2);
        FillSalesExpectedBuffer(TempTest340DeclarationLineBuf, PaymentNo, SalesInvNo, '2', 'C', FindBancAccountNoUsed(true, CustomerNo));
        TempTest340DeclarationLineBuf.UpdateTaxAmount(TaxPct[2], Amount[2], 2);
        VerifyCollectionDataIn340Export(ExportFileName, TempTest340DeclarationLineBuf);
    end;

    [Test]
    [HandlerFunctions('Make340DeclarationHandler')]
    [Scope('OnPrem')]
    procedure UnappliedFullPmtOfSalesInvoice()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerNo: Code[20];
        SalesInvNo: Code[20];
        Amount: Decimal;
    begin
        // [FEATURE] [MODELO340.CAC] [Sales]
        // [SCENARIO 21] Unapplied Payment to Sales CAC Invoice is not reported
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        // [GIVEN] CAC Sales Invoice is posted
        CustomerNo := CreateCustomer(VATPostingSetup."VAT Bus. Posting Group");
        SalesInvNo := Library340347Declaration.CreateAndPostSalesInvoice(VATPostingSetup, CustomerNo, WorkDate(), Amount);
        // [GIVEN] Invoice is fully paid in next month
        WorkDate(CalcDate('<+1M>', WorkDate()));
        Library340347Declaration.CreateAndPostPaymentForSI(CustomerNo, "Gen. Journal Document Type"::Invoice, SalesInvNo, WorkDate(), Amount);
        // [GIVEN] Payment is unapplied in the same period
        CustLedgerEntry.FindLast();
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);
        Commit();

        // [WHEN] Export by report 'Make 340 Declaration'
        asserterror Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] Payment is not reported
        Assert.ExpectedError(NoRecordsInDeclErr);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure NewNonCACPurchInvoice()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        Amount: Decimal;
        ExtPurchInvNo: Code[35];
        PurchInvNo: Code[20];
        ExportFileName: Text[1024];
    begin
        // [FEATURE] [MODELO340.CAC] [Purchase]
        // [SCENARIO 05] Normal Purchase Invoice (Non-CAC)
        Initialize();
        CreateNormalVATPostingSetup(VATPostingSetup);

        // [GIVEN] Non-CAC Purchase Invoice is posted
        PurchInvNo := Library340347Declaration.CreateAndPostPurchaseInvoice(
            VATPostingSetup, CreateVendor(VATPostingSetup."VAT Bus. Posting Group"), WorkDate(), Amount, ExtPurchInvNo);

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] Invoice is reported as ' ' record without collection info
        FillPurchExpectedBuffer(TempTest340DeclarationLineBuf, PurchInvNo, ExtPurchInvNo, '', '', '', 1);
        VerifyCollectionInfoInFile(ExportFileName, TempTest340DeclarationLineBuf);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure NewNonCACSalesInvoice()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        Amount: Decimal;
        SalesInvNo: Code[20];
        ExportFileName: Text[1024];
    begin
        // [FEATURE] [MODELO340.CAC] [Sales]
        // [SCENARIO 22] Normal Sales Invoice (Non-CAC)
        Initialize();
        CreateNormalVATPostingSetup(VATPostingSetup);

        // [GIVEN] Non-CAC Sales Invoice is posted
        SalesInvNo := Library340347Declaration.CreateAndPostSalesInvoice(
            VATPostingSetup, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"), WorkDate(), Amount);
        // [GIVEN] Operation Code'X' is set on Gen. Prod. Posting Group
        SetOperationCodeOnGPPG('X');
        Commit();

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] Invoice is reported as 'X' record without collection info
        FillSalesExpectedBuffer(TempTest340DeclarationLineBuf, SalesInvNo, SalesInvNo, 'X', '', '');
        VerifyCollectionInfoInFile(ExportFileName, TempTest340DeclarationLineBuf);

        // TearDown
        SetOperationCodeOnGPPG('');
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure NewSalesCrMemo()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        CustomerNo: Code[20];
        CrMemoNo: Code[20];
        ExportFileName: Text[1024];
        Amount: Decimal;
    begin
        // [FEATURE] [MODELO340.CAC] [Sales]
        // [SCENARIO 08] New CAC Sales Credit Memo
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        // [GIVEN] CAC Sales Credit Memo is posted
        CustomerNo := CreateCustomer(VATPostingSetup."VAT Bus. Posting Group");
        Amount := LibraryRandom.RandIntInRange(5000, 10000);
        CrMemoNo := Library340347Declaration.CreateAndPostSalesCrMemo(VATPostingSetup, CustomerNo, WorkDate(), Amount, '');

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] Credit Memo is reported as '3' record without collection info
        FillSalesExpectedBuffer(TempTest340DeclarationLineBuf, CrMemoNo, CrMemoNo, '3', '', '');
        VerifyCollectionInfoInFile(ExportFileName, TempTest340DeclarationLineBuf);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure NewSalesInvoice()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        Amount: Decimal;
        SalesInvNo: Code[20];
        ExportFileName: Text[1024];
    begin
        // [FEATURE] [MODELO340.CAC] [Sales]
        // [SCENARIO 22] CAC Sales Invoice doesn't use Operation Code from GPPG
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        // [GIVEN] CAC Sales Invoice is posted
        SalesInvNo := Library340347Declaration.CreateAndPostSalesInvoice(
            VATPostingSetup, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"), WorkDate(), Amount);
        // [GIVEN] Operation Code'X' is set on Gen. Prod. Posting Group
        SetOperationCodeOnGPPG('X');
        Commit();

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] Invoice is reported as normal record 'Z' without collection info
        FillSalesExpectedBuffer(TempTest340DeclarationLineBuf, SalesInvNo, SalesInvNo, 'Z', '', '');
        VerifyCollectionInfoInFile(ExportFileName, TempTest340DeclarationLineBuf);

        // TearDown
        SetOperationCodeOnGPPG('');
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure PaidSalesCrMemo()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        CustomerNo: Code[20];
        CrMemoNo: Code[20];
        RefundNo: Code[20];
        ExportFileName: Text[1024];
        Amount: Decimal;
    begin
        // [FEATURE] [MODELO340.CAC] [Sales]
        // [SCENARIO 08] Refund applied to CAC Sales Credit Memo reported with Operation Code '3'
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        // [GIVEN] CAC Sales Credit Memo is posted
        CustomerNo := CreateCustomer(VATPostingSetup."VAT Bus. Posting Group");
        Amount := LibraryRandom.RandIntInRange(5000, 10000);
        CrMemoNo := Library340347Declaration.CreateAndPostSalesCrMemo(VATPostingSetup, CustomerNo, WorkDate(), Amount, '');
        // [GIVEN] Credit Memo is paid by Refund
        WorkDate(CalcDate('<+1M>', WorkDate()));
        RefundNo :=
          Library340347Declaration.CreateAndPostPaymentForSI(CustomerNo, "Gen. Journal Document Type"::"Credit Memo", CrMemoNo, WorkDate(), -Amount);

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] Refund is reported as '3' record
        // [THEN] Credit Memo Document No. is reported as Document No in Refund line.
        FillSalesExpectedBuffer(TempTest340DeclarationLineBuf, RefundNo, CrMemoNo, '3', 'C', FindBancAccountNoUsed(true, CustomerNo));
        VerifyCollectionInfoInFile(ExportFileName, TempTest340DeclarationLineBuf);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure PaidCrMemoAndPayment()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        SalesInvNo: Code[20];
        CustomerNo: Code[20];
        CrMemoNo: Code[20];
        PaymentNo: Code[20];
        ExportFileName: Text[1024];
        Amount: Decimal;
        PostingDate: Date;
    begin
        // [FEATURE] [MODELO340.CAC] [Sales]
        // [SCENARIO 11] CAC Invoice paid by CAC Credit Memo and Payment (Purchase/Sales)
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        PostingDate := CalcDate('<-CM>', WorkDate());

        // [GIVEN] Posted CAC Invoice (Ext. Doc No.='INV-A') on 10.01 with Amount = 1000
        CustomerNo := CreateCustomer(VATPostingSetup."VAT Bus. Posting Group");
        SalesInvNo := Library340347Declaration.CreateAndPostSalesInvoice(VATPostingSetup, CustomerNo, PostingDate, Amount);

        // [GIVEN] Posted CAC credit memo (Ext. Doc No.='CRM') on 16.01 with Amount = -300 and applied to Invoice.
        Amount := LibraryRandom.RandIntInRange(1, 500);
        PostingDate := CalcDate('<+7D>', PostingDate);
        CrMemoNo := Library340347Declaration.CreateAndPostSalesCrMemo(VATPostingSetup, CustomerNo, PostingDate, Amount, SalesInvNo);

        // [GIVEN] Posted Payment (Doc No.='PMT') on 28.01 with Amount=-700 and applied to Invoice.
        PostingDate := CalcDate('<+7D>', PostingDate);
        PaymentNo := Library340347Declaration.CreateAndPostPaymentForSI(CustomerNo, "Gen. Journal Document Type"::Invoice, SalesInvNo, PostingDate, Amount);

        // [WHEN] Export by report 'Make 340 Declaration' for Month 01
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(PostingDate);

        // [THEN] 3 records created:
        VerifyTotalNoOfRec(ExportFileName, 3);

        // [THEN] Invoice 'INV-A' on 10.01 with '' operation code and empty collection data
        FillSalesExpectedBuffer(TempTest340DeclarationLineBuf, SalesInvNo, SalesInvNo, '', '', '');

        // [THEN] Invoice 'CRM' on 16.01 with '' operation code and empty collection data
        FillSalesExpectedBuffer(TempTest340DeclarationLineBuf, CrMemoNo, CrMemoNo, 'D', '', '');

        // [THEN] Payment 'INV-A' on 28.01 with 'Z' operation code, Collection Amount = 700.
        FillSalesExpectedBuffer(TempTest340DeclarationLineBuf, PaymentNo, SalesInvNo, 'Z', 'C', FindBancAccountNoUsed(true, CustomerNo));
        VerifyCollectionInfoInFile(ExportFileName, TempTest340DeclarationLineBuf);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure CorrectDatesTakenFromInvoice()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        SalesInvNo: Code[20];
        CustomerNo: Code[20];
        PaymentNo: Code[20];
        DocumentDate: Date;
        InvPostingDate: Date;
        PayPostingDate: Date;
        Amount: Decimal;
        ExportFileName: Text[1024];
    begin
        // [FEATURE] [MODELO340.CAC] [Sales]
        // [SCENARIO 23] 'Document Date','Operation Date' is taken from Invoice
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        DocumentDate := CalcDate('<-CM>', WorkDate());
        InvPostingDate := CalcDate('<+7D>', DocumentDate);
        PayPostingDate := CalcDate('<+14D>', DocumentDate);

        // [GIVEN] CAC-Invoice is posted. 'Document Date'=10.02.14, 'Posting Date'=14.02.14
        CustomerNo := CreateCustomer(VATPostingSetup."VAT Bus. Posting Group");
        SalesInvNo := CreateAndPostSalesInvoiceWithDocDate(
            CustomerNo, InvPostingDate, DocumentDate, VATPostingSetup."VAT Prod. Posting Group", Amount);

        // [GIVEN] Invoice is fully paid by Payment. 'Posting Date' = 25.02.14
        PaymentNo :=
          Library340347Declaration.CreateAndPostPaymentForSI(CustomerNo, "Gen. Journal Document Type"::Invoice, SalesInvNo, PayPostingDate, Amount);

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(PayPostingDate);

        // [THEN] Payment record contains 3 dates:
        // [THEN] 'Issued Date'=10.02.14; 'Operation Date'=14.02.14; 'Collection Date'=25.02.14
        FillSalesExpectedBuffer(TempTest340DeclarationLineBuf, PaymentNo, SalesInvNo, 'Z', 'C', FindBancAccountNoUsed(true, CustomerNo));
        VerifyFieldInExportedFile(101, ExportFileName, DateToText(DocumentDate));
        // 101 - Starting Position of 'Issued Date'.
        VerifyFieldInExportedFile(TempTest340DeclarationLineBuf.GetFieldPos(TempTest340DeclarationLineBuf.FieldNo("Posting Date")), ExportFileName, DateToText(InvPostingDate));
        VerifyFieldInExportedFile(TempTest340DeclarationLineBuf.GetFieldPos(TempTest340DeclarationLineBuf.FieldNo("Collection Date")), ExportFileName, DateToText(PayPostingDate));
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithPartialPrepayment()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TempTest340DeclarationLineBuf2: Record "Test 340 Declaration Line Buf." temporary;
        PurchHeader: Record "Purchase Header";
        ExportFileName: Text[1024];
        FinalInvNo: Code[20];
        PaymentNo: Code[20];
        PrepaymentNo: Code[20];
        PrepmtInvNo: Code[20];
    begin
        // [FEATURE] [MODELO340.CAC] [Purchase]
        // [SCENARIO 10] Partial Purchase Prepayment Invoice and Final invoice are paid within one period.
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        // [GIVEN] Created Purchase Order with partial prepayment %
        CreatePurchOrderWithPrepmt(
          PurchHeader, VATPostingSetup, CalcDate('<-CM>', WorkDate()), LibraryRandom.RandIntInRange(20, 50));
        // [GIVEN] Post a Prepayment Invoice
        PrepmtInvNo := PostPurchPrepmtInvoice(PurchHeader);
        FillPurchExpectedBuffer(TempTest340DeclarationLineBuf2, PrepmtInvNo, PurchHeader."Vendor Invoice No.", 'Z', '', '', 1);
        // [GIVEN] Post a payment for prepayment Invoice
        PrepaymentNo := PayForPurchInvoice(PrepmtInvNo);
        FillPurchExpectedBuffer(
          TempTest340DeclarationLineBuf2, PrepaymentNo, PurchHeader."Vendor Invoice No.",
          'Z', 'C', FindBancAccountNoUsed(false, PurchHeader."Buy-from Vendor No."), 1);
        // [GIVEN] Post the final Invoice
        FinalInvNo := PostFinalPurchInvoice(PurchHeader);
        FillPurchExpectedBuffer(TempTest340DeclarationLineBuf2, FinalInvNo, PurchHeader."Vendor Invoice No.", 'Z', '', '', 1);
        // [GIVEN] Post a payment for the final Invoice
        PaymentNo := PayForPurchInvoice(FinalInvNo);
        FillPurchExpectedBuffer(
          TempTest340DeclarationLineBuf2, PaymentNo, PurchHeader."Vendor Invoice No.",
          'Z', 'C', FindBancAccountNoUsed(false, PurchHeader."Buy-from Vendor No."), 1);

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] There are 4 records reported in the file
        VerifyTotalNoOfRec(ExportFileName, 4);
        // [THEN] a normal record for Prepayment Invoice
        // [THEN] a normal record for Final Invoice
        // [THEN] a Z record for prepayment, related to Prepayment Invoice
        // [THEN] a Z record for Final Invoice includes the reverse of prepaid amount
        VerifyCollectionDataIn340Export(ExportFileName, TempTest340DeclarationLineBuf2);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvoiceWithFullPrepayment()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TempTest340DeclarationLineBuf2: Record "Test 340 Declaration Line Buf." temporary;
        TempTest340DeclarationLineBuf3: Record "Test 340 Declaration Line Buf." temporary;
        PurchHeader: Record "Purchase Header";
        ExportFileName: Text[1024];
        FinalInvNo: Code[20];
        PrepaymentNo: Code[20];
        PrepmtInvNo: Code[20];
    begin
        // [FEATURE] [MODELO340.CAC] [Purchase]
        // [SCENARIO 10] 100% Purchase Prepayment Invoice and Final invoice are paid within one period.
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        // [GIVEN] Create Purchase Order with 100% prepayment
        CreatePurchOrderWithPrepmt(PurchHeader, VATPostingSetup, CalcDate('<-CM>', WorkDate()), 100);
        PrepmtInvNo := PostPurchPrepmtInvoice(PurchHeader);
        FillPurchExpectedBuffer(TempTest340DeclarationLineBuf2, PrepmtInvNo, PurchHeader."Vendor Invoice No.", 'Z', '', '', 1);
        // [GIVEN] Post a payment for prepayment Invoice
        PrepaymentNo := PayForPurchInvoice(PrepmtInvNo);
        FillPurchExpectedBuffer(
          TempTest340DeclarationLineBuf2, PrepaymentNo, PurchHeader."Vendor Invoice No.",
          'Z', 'C', FindBancAccountNoUsed(false, PurchHeader."Buy-from Vendor No."), 1);
        // [GIVEN] Post the final Invoice
        FinalInvNo := PostFinalPurchInvoice(PurchHeader);
        FillPurchExpectedBuffer(TempTest340DeclarationLineBuf3, FinalInvNo, PurchHeader."Vendor Invoice No.", 'Z', '', '', 1);

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] There are 2 records reported in the file
        VerifyTotalNoOfRec(ExportFileName, 2);
        // [THEN] a normal record for Prepayment Invoice
        // [THEN] a Z record for prepayment, related to Prepayment Invoice
        VerifyCollectionDataIn340Export(ExportFileName, TempTest340DeclarationLineBuf2);
        // [THEN] Final zero invoice is not reported
        asserterror VerifyCollectionInfoInFile(ExportFileName, TempTest340DeclarationLineBuf3);
        Assert.ExpectedError(DocNoNotFoundInLineErr);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithPartialPrepayment()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TempTest340DeclarationLineBuf2: Record "Test 340 Declaration Line Buf." temporary;
        SalesHeader: Record "Sales Header";
        ExportFileName: Text[1024];
        FinalInvNo: Code[20];
        PaymentNo: Code[20];
        PrepaymentNo: Code[20];
        PrepmtInvNo: Code[20];
    begin
        // [FEATURE] [MODELO340.CAC] [Sales]
        // [SCENARIO 10] Partial Sales Prepayment invoice and Final invoice are paid within one period.
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        // [GIVEN] Create Sales Order with partial prepayment %
        CreateSalesOrderWithPrepmt(
          SalesHeader, VATPostingSetup, CalcDate('<-CM>', WorkDate()), LibraryRandom.RandIntInRange(20, 50));
        // [GIVEN] Post a Prepayment Invoice
        PrepmtInvNo := PostSalesPrepmtInvoice(SalesHeader);
        FillSalesExpectedBuffer(TempTest340DeclarationLineBuf2, PrepmtInvNo, PrepmtInvNo, 'Z', '', '');
        // [GIVEN] Post a payment for prepayment Invoice
        PrepaymentNo := PayForSalesInvoice(PrepmtInvNo);
        FillSalesExpectedBuffer(
          TempTest340DeclarationLineBuf2, PrepaymentNo, PrepmtInvNo,
          'Z', 'C', FindBancAccountNoUsed(true, SalesHeader."Sell-to Customer No."));
        // [GIVEN] Post the final Invoice
        FinalInvNo := PostFinalSalesInvoice(SalesHeader);
        FillSalesExpectedBuffer(TempTest340DeclarationLineBuf2, FinalInvNo, FinalInvNo, 'Z', '', '');
        // [GIVEN] Post a payment for the final Invoice
        PaymentNo := PayForSalesInvoice(FinalInvNo);
        FillSalesExpectedBuffer(
          TempTest340DeclarationLineBuf2, PaymentNo, FinalInvNo,
          'Z', 'C', FindBancAccountNoUsed(true, SalesHeader."Sell-to Customer No."));

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] There are 4 records reported in the file
        VerifyTotalNoOfRec(ExportFileName, 4);
        // [THEN] a normal record for Prepayment Invoice
        // [THEN] a normal record for Final Invoice
        // [THEN] a Z record for prepayment, related to Prepayment Invoice
        // [THEN] a Z record for Final Invoice includes the reverse of prepaid amount
        VerifyCollectionDataIn340Export(ExportFileName, TempTest340DeclarationLineBuf2);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithFullPrepayment()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TempTest340DeclarationLineBuf2: Record "Test 340 Declaration Line Buf." temporary;
        TempTest340DeclarationLineBuf3: Record "Test 340 Declaration Line Buf." temporary;
        SalesHeader: Record "Sales Header";
        ExportFileName: Text[1024];
        FinalInvNo: Code[20];
        PrepaymentNo: Code[20];
        PrepmtInvNo: Code[20];
    begin
        // [FEATURE] [MODELO340.CAC] [Sales]
        // [SCENARIO 10] 100% Sales Prepayment invoice and Final invoice are paid within one period.
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        // [GIVEN] Create Sales Order with 100% prepayment
        CreateSalesOrderWithPrepmt(SalesHeader, VATPostingSetup, CalcDate('<-CM>', WorkDate()), 100);
        PrepmtInvNo := PostSalesPrepmtInvoice(SalesHeader);
        FillSalesExpectedBuffer(TempTest340DeclarationLineBuf2, PrepmtInvNo, PrepmtInvNo, 'Z', '', '');
        // [GIVEN] Post a payment for prepayment Invoice
        PrepaymentNo := PayForSalesInvoice(PrepmtInvNo);
        FillSalesExpectedBuffer(
          TempTest340DeclarationLineBuf2, PrepaymentNo, PrepmtInvNo,
          'Z', 'C', FindBancAccountNoUsed(true, SalesHeader."Sell-to Customer No."));
        // [GIVEN] Post the final Invoice
        FinalInvNo := PostFinalSalesInvoice(SalesHeader);
        FillSalesExpectedBuffer(TempTest340DeclarationLineBuf3, FinalInvNo, FinalInvNo, 'Z', '', '');

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] There are 2 records reported in the file
        VerifyTotalNoOfRec(ExportFileName, 2);
        // [THEN] a normal record for Prepayment Invoice
        // [THEN] a Z record for prepayment, related to Prepayment Invoice
        VerifyCollectionDataIn340Export(ExportFileName, TempTest340DeclarationLineBuf2);
        // [THEN] Final zero invoice is not reported
        asserterror VerifyCollectionInfoInFile(ExportFileName, TempTest340DeclarationLineBuf3);
        Assert.ExpectedError(DocNoNotFoundInLineErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OperationCodeZCanBeInserted()
    var
        OperationCode: Record "Operation Code";
        OperationCodes: TestPage "Operation Codes";
        NewOperationCode: Code[1];
    begin
        // [FEATURE] [MODELO340.CAC]
        // [SCENARIO 13] UI. Operation Code 'Z' can be inserted to Operation Codes
        NewOperationCode := 'Z';

        // [GIVEN] There is no Operation Code record with Code 'Z'
        OperationCode.SetRange(Code, NewOperationCode);
        OperationCode.DeleteAll();

        // [WHEN] User enters Code 'Z' for a new Operation Code record
        OperationCodes.OpenEdit();
        OperationCodes.New();
        OperationCodes.Code.SetValue(NewOperationCode);
        OperationCodes.Close();

        // [THEN]  Operation Code record is created
        OperationCode.SetRange(Code, NewOperationCode);
        Assert.IsFalse(OperationCode.IsEmpty, 'Operation Code "' + NewOperationCode + '" does not exist.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OperationCodeZIsEditable()
    var
        Rec340DeclarationLine: Record "340 Declaration Line";
        TestPage340DeclarationLines: TestPage "340 Declaration Lines";
    begin
        // [FEATURE] [MODELO340.CAC]
        // [SCENARIO 15] UI. Operation Code 'Z' is editable on preview page.

        // [GIVEN] Preview line with Operation Code 'Z'
        Rec340DeclarationLine.DeleteAll();
        Rec340DeclarationLine.Init();
        Rec340DeclarationLine."Operation Code" := 'Z';
        Rec340DeclarationLine.Insert();

        // [WHEN] User tries to edit 'Operation Code'
        TestPage340DeclarationLines.OpenEdit();
        TestPage340DeclarationLines.First();
        // [THEN]  Operation Code field is editable
        Assert.IsTrue(
          TestPage340DeclarationLines."Operation Code".Editable(), 'Operation Code "Z" must be editable');
        TestPage340DeclarationLines.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OperationCodeZUnrealizedPaymentChangeToAllowedSet()
    var
        Rec340DeclarationLine: Record "340 Declaration Line";
        OperationCode: Record "Operation Code";
        i: Integer;
        OperationCodeValue: Code[1];
        OperationCodeValues: array[9] of Code[1];
    begin
        // [FEATURE] [MODELO340.CAC]
        // [SCENARIO 13] CAC Payment's Operation Code can be changed to ['1'..'8','Z'] on preview page.

        // [GIVEN] CAC Payment's preview line with Operation Code 'Z'
        Rec340DeclarationLine.DeleteAll();
        Rec340DeclarationLine.Init();
        Rec340DeclarationLine."Operation Code" := 'Z';
        Rec340DeclarationLine."Unrealized VAT Entry No." := LibraryRandom.RandInt(10);
        Rec340DeclarationLine.Insert();

        // [WHEN] User tries to set 'Operation Code' to ['1'..'8','Z']
        OperationCodeValues[1] := '1';
        OperationCodeValues[2] := '2';
        OperationCodeValues[3] := '3';
        OperationCodeValues[4] := '4';
        OperationCodeValues[5] := '5';
        OperationCodeValues[6] := '6';
        OperationCodeValues[7] := '7';
        OperationCodeValues[8] := '8';
        OperationCodeValues[9] := 'Z';
        for i := 1 to 8 do begin
            OperationCodeValue := Format(OperationCodeValues[i]);
            CreateOperationCode(OperationCode, OperationCodeValue);
            Rec340DeclarationLine.Validate("Operation Code", OperationCodeValue);
            // [THEN] 'Operation Code' is changed
            Rec340DeclarationLine.TestField("Operation Code", OperationCodeValue);
            OperationCode.Delete();
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OperationCodeZUnrealizedPaymentChangeTNotoAllowedSet()
    var
        Rec340DeclarationLine: Record "340 Declaration Line";
        OperationCode: Record "Operation Code";
        OperationCodeValue: Code[1];
    begin
        // [FEATURE] [MODELO340.CAC]
        // [SCENARIO 13] CAC Payment's Operation Code 'Z' cannot be changed to '9' on preview page.

        // [GIVEN] CAC Payment's preview line with Operation Code 'Z'
        Rec340DeclarationLine.DeleteAll();
        Rec340DeclarationLine.Init();
        Rec340DeclarationLine."Operation Code" := 'Z';
        Rec340DeclarationLine."Unrealized VAT Entry No." := LibraryRandom.RandInt(10);
        Rec340DeclarationLine.Insert();

        // [WHEN] User tries to set 'Operation Code' to '9'
        OperationCodeValue := '9';
        CreateOperationCode(OperationCode, OperationCodeValue);
        asserterror Rec340DeclarationLine.Validate("Operation Code", OperationCodeValue);
        // [THEN] Error is thrown
        Assert.ExpectedError(StrSubstNo(WrongOperationCodeErr, OperationCodeValue, 0));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OperationCodeZChangeToAllowedSet()
    var
        Rec340DeclarationLine: Record "340 Declaration Line";
        OperationCode: Record "Operation Code";
        i: Integer;
        OperationCodeValue: Code[1];
        OperationCodeValues: array[9] of Code[1];
    begin
        // [FEATURE] [MODELO340.CAC]
        // [SCENARIO 15] CAC Invoice line cannot get Operation Code ['1'..'8','Z'] on preview page.

        // [GIVEN] CAC Invoice's preview line with Operation Code ''
        Rec340DeclarationLine.DeleteAll();
        Rec340DeclarationLine.Init();
        Rec340DeclarationLine."Operation Code" := '';
        Rec340DeclarationLine.Insert();

        // [WHEN] User tries to set 'Operation Code' to ['1'..'8','Z']
        OperationCodeValues[1] := '1';
        OperationCodeValues[2] := '2';
        OperationCodeValues[3] := '3';
        OperationCodeValues[4] := '4';
        OperationCodeValues[5] := '5';
        OperationCodeValues[6] := '6';
        OperationCodeValues[7] := '7';
        OperationCodeValues[8] := '8';
        OperationCodeValues[9] := 'Z';
        for i := 1 to StrLen(OperationCodeValue) do begin
            OperationCodeValue := Format(OperationCodeValues[i]);
            CreateOperationCode(OperationCode, OperationCodeValue);
            asserterror Rec340DeclarationLine.Validate("Operation Code", OperationCodeValue);
            // [THEN] Error is thrown
            Assert.ExpectedError(StrSubstNo(WrongOperationCodeErr, OperationCodeValue, 0));
        end;
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseChargeApplyPaymentToSalesOperationCodeZ()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        CustomerNo: Code[20];
        SalesInvNo: Code[20];
        PaymentNo: Code[20];
        ExportFileName: Text[1024];
        Amount: Decimal;
    begin
        // [FEATURE] [MODELO340.CAC]
        // [SCENARIO 16] Operation Code is 'Z' for Sales Payment with Reverse Charge VAT
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);
        CreateReverseChargeVATPostingSetup(VATPostingSetup);

        // [GIVEN] CAC Sales Invoice is posted
        Amount := LibraryRandom.RandDec(1000, 2);
        CustomerNo := CreateCustomer(VATPostingSetup."VAT Bus. Posting Group");
        SalesInvNo := Library340347Declaration.CreateAndPostSalesInvoice(VATPostingSetup, CustomerNo, WorkDate(), Amount);
        // [GIVEN] and paid by Payment
        PaymentNo := Library340347Declaration.CreateAndPostPaymentForSI(CustomerNo, "Gen. Journal Document Type"::Invoice, SalesInvNo, WorkDate(), Amount);

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] Payment is reported with Operation Code 'Z'
        FillSalesExpectedBuffer(TempTest340DeclarationLineBuf, PaymentNo, SalesInvNo, 'Z', 'C', FindBancAccountNoUsed(true, CustomerNo));
        VerifyCollectionDataIn340Export(ExportFileName, TempTest340DeclarationLineBuf);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure ReverseChargeApplyPaymentToPurchOperationCodeZ()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        ExtPurchaseInvNo: Code[35];
        VendorNo: Code[20];
        PurchInvNo: Code[20];
        PaymentNo: Code[20];
        ExportFileName: Text[1024];
        Amount: Decimal;
    begin
        // [FEATURE] [MODELO340.CAC]
        // [SCENARIO 16] Operation Code is 'Z' for Purchase Payment with Reverse Charge VAT
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);
        CreateReverseChargeVATPostingSetup(VATPostingSetup);

        // [GIVEN] CAC Purchase Invoice is posted
        VendorNo := CreateVendor(VATPostingSetup."VAT Bus. Posting Group");
        PurchInvNo := Library340347Declaration.CreateAndPostPurchaseInvoice(VATPostingSetup, VendorNo, WorkDate(), Amount, ExtPurchaseInvNo);
        // [GIVEN] and paid by Payment
        PaymentNo := Library340347Declaration.CreateAndPostPaymentForPI(VendorNo, "Gen. Journal Document Type"::Invoice, PurchInvNo, WorkDate(), Amount);

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] Payment is reported with Operation Code 'Z'
        FillPurchExpectedBuffer(
          TempTest340DeclarationLineBuf, PaymentNo, ExtPurchaseInvNo, 'Z', 'C', FindBancAccountNoUsed(false, VendorNo), 1);
        UpdatePurchReverseChargePaymentCollectionAmount(TempTest340DeclarationLineBuf, PaymentNo);
        VerifyCollectionDataIn340Export(ExportFileName, TempTest340DeclarationLineBuf);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure MonthAsPeriodInFile()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // [FEATURE] [MODELO340.CAC]
        // [SCENARIO 03] Month is reported as period
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        // [GIVEN] Posted CAC Sales Invoice
        // [WHEN] Export by report 'Make 340 Declaration'
        // [THEN] '01' reported for January
        VerifyPeriodInExportedRecType1(VATPostingSetup, CalcDate('<-CY+1D>', Today), '01');
        // [THEN] '12' reported for December
        VerifyPeriodInExportedRecType1(VATPostingSetup, CalcDate('<-CY-1D>', Today), '12');
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ConfirmYesHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure PmtOrderLinesForDiffOneVATInvWithoutVATCashRegime()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        BillGroup: Record "Bill Group";
        SecondVATPostingSetup: Record "VAT Posting Setup";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        BGPostAndPrint: Codeunit "BG/PO-Post and Print";
        ExportFileName: Text[1024];
        CustomerNo: Code[20];
        SalesInvNo: array[2] of Code[20];
        Amount: array[2] of Decimal;
        TaxPct: array[2] of Decimal;
        BankAccountNo: Code[20];
    begin
        // [FEATURE] [MODELO340.CAC]
        // [SCENARIO 19] (RHF 357970) Bill Group lines related to different one-VAT Sales Invoices are reported as 'Z'
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        // [GIVEN] 2 posted one-line Sales Invoices with different VAT%
        // [GIVEN] The two Sales Invoices has VAT Cash Regime = FALSE
        CustomerNo := CreateCustomerWithBills(VATPostingSetup."VAT Bus. Posting Group");
        SalesInvNo[1] := Library340347Declaration.CreateAndPostSalesInvoice(VATPostingSetup, CustomerNo, WorkDate(), Amount[1]);
        TaxPct[1] := VATPostingSetup."VAT %";
        CreateDiffVATPostingSetup(SecondVATPostingSetup, VATPostingSetup);
        VATPostingSetup := SecondVATPostingSetup;
        SalesInvNo[2] := Library340347Declaration.CreateAndPostSalesInvoice(VATPostingSetup, CustomerNo, WorkDate(), Amount[2]);
        TaxPct[2] := SecondVATPostingSetup."VAT %";
        // [GIVEN] Both Invoices are added into one Bill Group
        CreateBillGroup(BillGroup);
        BankAccountNo := GetAccountNoForBank(BillGroup."Bank Account No.");
        AddCarteraDocToPmtOrderBillGr(SalesInvNo[1], BillGroup."No.");
        AddCarteraDocToPmtOrderBillGr(SalesInvNo[2], BillGroup."No.");
        BGPostAndPrint.ReceivablePostOnly(BillGroup);
        // [GIVEN] Both Bill Group lines are settled
        SettlePostedBillGroup(BillGroup."No.");

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] 2 payment lines reported as 'Z' with 'No Of Registers' = '01'
        // [THEN] Bank Account info is taken from Bill Group
        FillSalesExpectedBuffer(TempTest340DeclarationLineBuf, BillGroup."No.", BillGroup."No.", 'Z', 'C', BankAccountNo);
        TempTest340DeclarationLineBuf.UpdateTaxAmount(TaxPct[1], Amount[1], 1);
        FillSalesExpectedBuffer(TempTest340DeclarationLineBuf, BillGroup."No.", BillGroup."No.", 'Z', 'C', BankAccountNo);
        TempTest340DeclarationLineBuf.UpdateTaxAmount(TaxPct[2], Amount[2], 1);
        VerifyCollectionInfoInFile(ExportFileName, TempTest340DeclarationLineBuf);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ConfirmYesHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure PmtOrderLinesForDiffOneVATInvWithVATCashRegime()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        BillGroup: Record "Bill Group";
        SecondVATPostingSetup: Record "VAT Posting Setup";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        BGPostAndPrint: Codeunit "BG/PO-Post and Print";
        ExportFileName: Text[1024];
        CustomerNo: Code[20];
        SalesInvNo: array[2] of Code[20];
        Amount: array[2] of Decimal;
        TaxPct: array[2] of Decimal;
        BankAccountNo: Code[20];
    begin
        // [ToDo]
        // [FEATURE] MODELO340.CAC
        // [SCENARIO 19.3] (RHF 357970) Bill Group lines related to different one-VAT Sales Invoices are reported as 'Z'
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        // [GIVEN] 2 posted one-line Sales Invoices with different VAT%
        // [GIVEN] The two Sales Invoices has VAT Cash Regime = TRUE
        CustomerNo := CreateCustomerWithBills(VATPostingSetup."VAT Bus. Posting Group");
        SalesInvNo[1] := Library340347Declaration.CreateAndPostSalesInvoice(VATPostingSetup, CustomerNo, WorkDate(), Amount[1]);
        TaxPct[1] := VATPostingSetup."VAT %";
        CreateDiffVATPostingSetup(SecondVATPostingSetup, VATPostingSetup);
        VATPostingSetup := SecondVATPostingSetup;
        SalesInvNo[2] := Library340347Declaration.CreateAndPostSalesInvoice(VATPostingSetup, CustomerNo, WorkDate(), Amount[2]);
        TaxPct[2] := SecondVATPostingSetup."VAT %";
        // [GIVEN] Both Invoices are added into one Bill Group
        CreateBillGroup(BillGroup);
        BankAccountNo := GetAccountNoForBank(BillGroup."Bank Account No.");
        AddCarteraDocToPmtOrderBillGr(SalesInvNo[1], BillGroup."No.");
        AddCarteraDocToPmtOrderBillGr(SalesInvNo[2], BillGroup."No.");
        BGPostAndPrint.ReceivablePostOnly(BillGroup);
        // [GIVEN] Both Bill Group lines are settled
        SettlePostedBillGroup(BillGroup."No.");

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] 2 payment lines reported as 'Z' with 'No Of Registers' = '01'
        // [THEN] Bank Account info is taken from Bill Group
        FillSalesExpectedBuffer(TempTest340DeclarationLineBuf, BillGroup."No.", BillGroup."No.", 'Z', 'C', BankAccountNo);
        TempTest340DeclarationLineBuf.UpdateTaxAmount(TaxPct[1], Amount[1], 1);
        FillSalesExpectedBuffer(TempTest340DeclarationLineBuf, BillGroup."No.", BillGroup."No.", 'Z', 'C', BankAccountNo);
        TempTest340DeclarationLineBuf.UpdateTaxAmount(TaxPct[2], Amount[2], 1);
        VerifyCollectionInfoInFile(ExportFileName, TempTest340DeclarationLineBuf);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ConfirmYesHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure PmtOrderLineForMultVATInv()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PaymentOrder: Record "Payment Order";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        BGPostAndPrint: Codeunit "BG/PO-Post and Print";
        ExportFileName: Text[1024];
        VendorNo: Code[20];
        PurchaseInvNo: array[2] of Code[20];
        ExtPurchaseInvNo: array[2] of Code[20];
        Amount: array[2, 2] of Decimal;
        TaxPct: array[2, 2] of Decimal;
        BankAccountNo: Code[20];
    begin
        // [FEATURE] [MODELO340.CAC]
        // [SCENARIO 19] (RHF 357970) Payment Order line related to multi-VAT Purchase Invoice is reported as '2'
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        // [GIVEN] Posted multi-VAT Purchase Invoice
        VendorNo := CreateVendor(VATPostingSetup."VAT Bus. Posting Group");
        PurchaseInvNo[1] := CreateAndPostPurchInvoiceTypeC(
            VATPostingSetup, VendorNo, WorkDate(), Amount[1], TaxPct[1], ExtPurchaseInvNo[1]);
        PurchaseInvNo[2] := CreateAndPostPurchInvoiceTypeC(
            VATPostingSetup, VendorNo, WorkDate(), Amount[2], TaxPct[2], ExtPurchaseInvNo[2]);

        // [GIVEN] Invoice is added into a Payment Order
        CreatePaymentOrder(PaymentOrder);
        BankAccountNo := GetAccountNoForBank(PaymentOrder."Bank Account No.");
        AddCarteraDocToPmtOrderBillGr(PurchaseInvNo[1], PaymentOrder."No.");
        AddCarteraDocToPmtOrderBillGr(PurchaseInvNo[2], PaymentOrder."No.");
        BGPostAndPrint.PayablePostOnly(PaymentOrder);
        // [GIVEN] Payment Order line is settled
        SettlePostedPaymentOrder(PaymentOrder."No.");

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] Payment line reported as '2' with 'No Of Registers' = '02'
        // [THEN] Bank Account info is taken from Payment Order
        FillPurchExpectedBuffer(TempTest340DeclarationLineBuf, PaymentOrder."No.", PaymentOrder."No.", '2', 'C', BankAccountNo, 1);
        TempTest340DeclarationLineBuf.UpdateTaxAmount(TaxPct[1, 1], Amount[1, 1] + Amount[2, 1], 2);
        FillPurchExpectedBuffer(TempTest340DeclarationLineBuf, PaymentOrder."No.", PaymentOrder."No.", '2', 'C', BankAccountNo, 1);
        TempTest340DeclarationLineBuf.UpdateTaxAmount(TaxPct[1, 2], Amount[1, 2] + Amount[2, 2], 2);
        VerifyCollectionInfoInFile(ExportFileName, TempTest340DeclarationLineBuf);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceWith100PctLineDisc()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        CustomerNo: Code[20];
        SalesInvNo: Code[20];
        Amount: Decimal;
        ExportFileName: Text[1024];
    begin
        // [FEATURE] [MODELO340.CAC]
        // [SCENARIO 19] (RFH 358052) Invoice with 100% Discount is not reported

        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        CustomerNo := CreateCustomer(VATPostingSetup."VAT Bus. Posting Group");

        // [GIVEN] Posted Invoice A with 100% Line discount
        Library340347Declaration.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, WorkDate(), WorkDate());
        Library340347Declaration.CreateSalesLine(SalesHeader, VATPostingSetup."VAT Prod. Posting Group", 0);
        Set100PctLineDiscOnSalesDoc(SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Posted Invoice B with non-zero VAT
        SalesInvNo := Library340347Declaration.CreateAndPostSalesInvoice(VATPostingSetup, CustomerNo, WorkDate(), Amount);

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] Total No of Records is 1
        VerifyTotalNoOfRec(ExportFileName, 1);
        // [THEN] Invoice B is reported
        FillSalesExpectedBuffer(TempTest340DeclarationLineBuf, SalesInvNo, SalesInvNo, 'Z', '', '');
        VerifyCollectionInfoInFile(ExportFileName, TempTest340DeclarationLineBuf);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvWith2LinesWithDiffUnrealVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchHeader: Record "Purchase Header";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        ExportFileName: Text[1024];
        PurchaseInvNo: Code[20];
    begin
        // [FEATURE] [MODELO340.CAC] [Purchase]
        // [SCENARIO 371612] Purchase Invoice Line with Unrealized Amount = 0 is not reported
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        // [GIVEN] Purchase Header with 2 lines with different VAT Posting Setup with Unrealized VAT, one line with Amount = 0
        CreatePurchaseInvoiceMultiLines(PurchHeader, VATPostingSetup."VAT Bus. Posting Group", 2);

        // [GIVEN] Posted Purchase Invoice
        PurchaseInvNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] Purchase Line with non-zero Amount is reported, Operation Code is Z, Total No of Records is 1.
        FillPurchExpectedBuffer(
          TempTest340DeclarationLineBuf, PurchaseInvNo, PurchHeader."Vendor Invoice No.", '', '', '', 1);
        VerifyCollectionInfoInFile(ExportFileName, TempTest340DeclarationLineBuf);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvWith2LinesWithDiffNormVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchHeader: Record "Purchase Header";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        ExportFileName: Text[1024];
        PurchaseInvNo: Code[20];
    begin
        // [FEATURE] [MODELO340.CAC] [Purchase]
        // [SCENARIO 375207] Purchase Invoice Line with Amount = 0 is not reported
        Initialize();
        CreateNormalVATPostingSetup(VATPostingSetup);

        // [GIVEN] Purchase Header with 2 lines with different VAT Posting Setup with Normal VAT, one line with Amount = 0
        CreatePurchaseInvoiceMultiLines(PurchHeader, VATPostingSetup."VAT Bus. Posting Group", 2);

        // [GIVEN] Posted Purchase Invoice
        PurchaseInvNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] Purchase Line with non-zero Amount is reported, Operation Code is empty, Total No of Records is 1.
        FillPurchExpectedBuffer(
          TempTest340DeclarationLineBuf, PurchaseInvNo, PurchHeader."Vendor Invoice No.", '', '', '', 1);
        VerifyCollectionInfoInFile(ExportFileName, TempTest340DeclarationLineBuf);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvWith3LinesWithDiffNormVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchHeader: Record "Purchase Header";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        ExportFileName: Text[1024];
        PurchaseInvNo: Code[20];
    begin
        // [FEATURE] [MODELO340.CAC] [Purchase]
        // [SCENARIO 375207] Purchase Invoice Line with Amount = 0 is not reported
        Initialize();
        CreateNormalVATPostingSetup(VATPostingSetup);

        // [GIVEN] Purchase Header with 3 lines with different VAT Posting Setup with Normal VAT, one line with Amount = 0
        CreatePurchaseInvoiceMultiLines(PurchHeader, VATPostingSetup."VAT Bus. Posting Group", 3);

        // [GIVEN] Posted Purchase Invoice
        PurchaseInvNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] Purchase Line with non-zero Amount is reported, Operation Code is C, Total No of Records is 2.
        FillPurchExpectedBuffer(
          TempTest340DeclarationLineBuf, PurchaseInvNo, PurchHeader."Vendor Invoice No.", 'C', '', '', 2);
        VerifyCollectionInfoInFile(ExportFileName, TempTest340DeclarationLineBuf);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_FormatAmnt_0()
    var
        Expected14: Text[14];
        Expected18: Text[18];
        Amount: Decimal;
    begin
        // [FEATURE] [MODELO340.CAC]
        // [SCENARIO 24] (0) = ' 0000000000000'

        Amount := 0;
        // test:       +12345678901234567
        Expected18 := ' 00000000000000000';
        Expected14 := ' 0000000000000';

        Validate_FormatAmnt(Amount, Expected14, Expected18);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_FormatAmnt_MinusDec()
    var
        Expected14: Text[14];
        Expected18: Text[18];
        Amount: Decimal;
    begin
        // [FEATURE] [MODELO340.CAC]
        // [SCENARIO 24] (-1.23) = 'N0000000000123'
        Amount := -123 / 100;
        // test:       +12345678901234567
        Expected18 := 'N00000000000000123';
        Expected14 := 'N0000000000123';

        Validate_FormatAmnt(Amount, Expected14, Expected18);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_FormatAmnt_PlsDec()
    var
        Expected14: Text[14];
        Expected18: Text[18];
        Amount: Decimal;
    begin
        // [FEATURE] [MODELO340.CAC]
        // [SCENARIO 24] (1.23) = ' 0000000000123'
        Amount := 123 / 100;
        // test:       +12345678901234567
        Expected18 := ' 00000000000000123';
        Expected14 := ' 0000000000123';

        Validate_FormatAmnt(Amount, Expected14, Expected18);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_FormatAmnt_PlsDecWithRound()
    var
        Expected14: Text[14];
        Expected18: Text[18];
        Amount: Decimal;
    begin
        // [FEATURE] [MODELO340.CAC]
        // [SCENARIO 24] (12.345) = ' 0000000001235' (with rounding)
        Amount := 12345 / 1000;
        // test:       +12345678901234567
        Expected18 := ' 00000000000001235';
        Expected14 := ' 0000000001235';

        Validate_FormatAmnt(Amount, Expected14, Expected18);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_FormatAmnt_MinInt()
    var
        Expected14: Text[14];
        Expected18: Text[18];
        Amount: Decimal;
    begin
        // [FEATURE] [MODELO340.CAC]
        // [SCENARIO 24] (-10) = 'N0000000001000'
        Amount := -10;
        // test:       +12345678901234567
        Expected18 := 'N00000000000001000';
        Expected14 := 'N0000000001000';

        Validate_FormatAmnt(Amount, Expected14, Expected18);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_FormatAmnt_PlsInt()
    var
        Expected14: Text[14];
        Expected18: Text[18];
        Amount: Decimal;
    begin
        // [FEATURE] [MODELO340.CAC]
        // [SCENARIO 24] (10) = ' 0000000001000'
        Amount := 10;
        // test:       +12345678901234567
        Expected18 := ' 00000000000001000';
        Expected14 := ' 0000000001000';

        Validate_FormatAmnt(Amount, Expected14, Expected18);
    end;

    local procedure Validate_FormatAmnt(Amount: Decimal; Expected14: Text[14]; Expected18: Text[18])
    var
        Make340Declaration: Report "Make 340 Declaration";
        Result14: Text;
        Result18: Text;
    begin
        Result14 := Make340Declaration.FormatTextAmt(Amount, false);
        Assert.AreEqual(Expected14, Result14, 'FormatTextAmt.');

        Result18 := Make340Declaration.FormatTextAmt(Amount, true);
        Assert.AreEqual(Expected18, Result18, 'FormatTextAmt.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_InsertTextWithReplace_Good()
    var
        OriginalText: Text[100];
        TextToInsert: Text[100];
        Position: Integer;
        Expected: Text[7];
    begin
        // [FEATURE] [MODELO340.CAC]
        // [SCENARIO 25] InsertTextWithReplace, override in the middle
        OriginalText := '1234567';
        TextToInsert := 'xxx';
        Position := 3;
        Expected := '12xxx67';

        Validate_InsertTextWithReplace(OriginalText, TextToInsert, Position, Expected);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_InsertTextWithReplace_More()
    var
        OriginalText: Text[100];
        TextToInsert: Text[100];
        Position: Integer;
        Expected: Text[9];
    begin
        // [FEATURE] [MODELO340.CAC]
        // [SCENARIO 25] InsertTextWithReplace, override all
        OriginalText := '1234567';
        TextToInsert := 'xxxxxxxxx';
        Position := 1;
        Expected := 'xxxxxxxxx';

        Validate_InsertTextWithReplace(OriginalText, TextToInsert, Position, Expected);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_InsertTextWithReplace_Far()
    var
        OriginalText: Text[100];
        TextToInsert: Text[100];
        Position: Integer;
        Expected: Text[8];
    begin
        // [FEATURE] [MODELO340.CAC]
        // [SCENARIO 25] InsertTextWithReplace, override in the end
        OriginalText := '1234567';
        TextToInsert := 'xxx';
        Position := 6;
        Expected := '12345xxx';

        Validate_InsertTextWithReplace(OriginalText, TextToInsert, Position, Expected);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_InsertTextWithReplace_Away()
    var
        OriginalText: Text[100];
        TextToInsert: Text[100];
        Position: Integer;
        Expected: Text[11];
    begin
        // [FEATURE] [MODELO340.CAC]
        // [SCENARIO 25] InsertTextWithReplace, add to the end
        OriginalText := '1234567';
        TextToInsert := 'xxx';
        Position := 9;
        Expected := '1234567 xxx';

        Validate_InsertTextWithReplace(OriginalText, TextToInsert, Position, Expected);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_InsertTextWithReplace_Empty()
    var
        OriginalText: Text[100];
        TextToInsert: Text[100];
        Position: Integer;
        Expected: Text[100];
    begin
        // [FEATURE] [MODELO340.CAC]
        // [SCENARIO 25] InsertTextWithReplace, insert empty string
        OriginalText := '1234567';
        TextToInsert := '';
        Position := 3;
        Expected := OriginalText;

        Validate_InsertTextWithReplace(OriginalText, TextToInsert, Position, Expected);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler,ConfirmYesHandler')]
    [Scope('OnPrem')]
    procedure Make340DeclForPaymentOrder2PaymentsExportVATRegime()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PaymentOrder: Record "Payment Order";
        Vendor: Record Vendor;
        VendLedgEntry: Record "Vendor Ledger Entry";
        TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary;
        BGPostAndPrint: Codeunit "BG/PO-Post and Print";
        PurchaseInvNo: array[2] of Code[20];
        ExtPurchaseInvNo: array[2] of Code[35];
        BankAccountNo: Code[20];
        Amount: array[2] of Decimal;
        ExportFileName: Text[1024];
    begin
        // [FEATURE] [Purchase] [VAT Cash Regime]
        // [SCENARIO 372288] Make 340 Declaration for Posted Payment Order with 2 Purchase Invoice Lines with VAT Cash Regime
        Initialize();
        CreateUnrealizedVATPostingSetup(VATPostingSetup);

        // [GIVEN] Vendor with Payment Method with Create Bills = TRUE
        LibraryCarteraPayables.CreateCarteraVendorUseBillToCarteraPayment(Vendor, '');
        LibraryVariableStorage.Enqueue(Vendor."No.");
        // [GIVEN] Posted Purch. Invoice "A" with Amount "X", Posted Purch. Invoice "B" with Amount "Y"
        PurchaseInvNo[1] :=
          Library340347Declaration.CreateAndPostPurchaseInvoice(VATPostingSetup, Vendor."No.", WorkDate(), Amount[1], ExtPurchaseInvNo[1]);
        PurchaseInvNo[2] :=
          Library340347Declaration.CreateAndPostPurchaseInvoice(VATPostingSetup, Vendor."No.", WorkDate(), Amount[2], ExtPurchaseInvNo[2]);

        // [GIVEN] Posted Payment Order with 2 Purch. Invoices inserted
        CreatePaymentOrder(PaymentOrder);
        BankAccountNo := GetAccountNoForBank(PaymentOrder."Bank Account No.");
        AddCarteraDocToPmtOrderBillGr(PurchaseInvNo[1], PaymentOrder."No.");
        AddCarteraDocToPmtOrderBillGr(PurchaseInvNo[2], PaymentOrder."No.");
        BGPostAndPrint.PayablePostOnly(PaymentOrder);

        // [GIVEN] Payment Order Lines Settled
        SettlePostedPaymentOrder(PaymentOrder."No.");

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());
        // [THEN] Total Number of Records export = 4 (2 Payment and 2 Invoice lines)
        VerifyTotalNoOfRec(ExportFileName, 4);
        Assert.AreEqual(
          2, LibraryTextFileValidation.CountNoOfLinesWithValue(ExportFileName, PadStr(PaymentOrder."No.", 18), 218, 18),
          WrongNoOfPaymentRecordsErr);

        // [THEN] 340 Declaration file contains Payment Line with Collection Amount = "X" and Payment Line with Collection Amount = "Y"
        FindPaymentVLE(VendLedgEntry, PaymentOrder."No.", Amount[1]);
        Create340DeclarationLineBufPurch(
          VendLedgEntry, TempTest340DeclarationLineBuf, PaymentOrder."No.", 'Z', 'C', BankAccountNo, 1);

        FindPaymentVLE(VendLedgEntry, PaymentOrder."No.", Amount[2]);
        Create340DeclarationLineBufPurch(
          VendLedgEntry, TempTest340DeclarationLineBuf, PaymentOrder."No.", 'Z', 'C', BankAccountNo, 1);

        VerifyCollectionDataIn340Export(ExportFileName, TempTest340DeclarationLineBuf);
    end;

    [Test]
    [HandlerFunctions('Declaration340LinesPageHandler,Make340DeclarationHandler,ExportedSuccessfullyMessageHandler')]
    [Scope('OnPrem')]
    procedure Make340DeclarationforEmptyDocumentType()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        VATPostingSetup: Record "VAT Posting Setup";
        VendorNo: Code[20];
        ExtPurchaseInvNo: Code[35];
        ExportFileName: Text[1024];
        Amount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 376198] Make 340 Declaration does not export entries with empty Document Type
        Initialize();

        // [GIVEN] Posted Purchase Invoice
        CreateUnrealizedVATPostingSetup(VATPostingSetup);
        VendorNo := CreateVendor(VATPostingSetup."VAT Bus. Posting Group");
        Library340347Declaration.CreateAndPostPurchaseInvoice(VATPostingSetup, VendorNo, WorkDate(), Amount, ExtPurchaseInvNo);
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);

        // [GIVEN] Posted Gen. Journal line with "empty" Document Type
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(),
          GenJournalLine."Bal. Account Type"::Vendor, VendorNo, -LibraryRandom.RandInt(100));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Export by report 'Make 340 Declaration'
        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(WorkDate());

        // [THEN] Exported file contains line for posted Invoice and not for posted Gen. Journal Line with empty Document Type
        VerifyTotalNoOfRec(ExportFileName, 1);
        Assert.AreEqual(
          0, LibraryTextFileValidation.CountNoOfLinesWithValue(ExportFileName, PadStr(GenJournalLine."Document No.", 18), 218, 18),
          WrongNoOfPaymentRecordsErr);
    end;

    local procedure Initialize()
    var
        OperationCode: Record "Operation Code";
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        OperationCode.DeleteAll();

        if IsInitialized then
            exit;

        SalesSetup.Get();
        SalesSetup."Correct. Doc. No. Mandatory" := false;
        SalesSetup.Modify();

        Library340347Declaration.SetupVATType(false, false); // Remove all VAT Cash regime

        IsInitialized := true;
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
    end;

    local procedure CreateReverseChargeVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        VATPostingSetup.Validate("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT");
        VATPostingSetup.Validate("Reverse Chrg. VAT Unreal. Acc.", VATPostingSetup."Sales VAT Account");
        VATPostingSetup.Validate("Reverse Chrg. VAT Acc.", VATPostingSetup."Purchase VAT Account");
        VATPostingSetup.Validate(
          "VAT Identifier", LibraryUtility.GenerateRandomCode20(VATPostingSetup.FieldNo("VAT Identifier"), DATABASE::"VAT Posting Setup"));
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandInt(25));
        VATPostingSetup.Validate("EC %", LibraryRandom.RandInt(25));
        VATPostingSetup.Modify(true);
    end;

    local procedure CreateUnrealizedVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        GenPostingSetup: Record "General Posting Setup";
        GLSetup: Record "General Ledger Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        GLSetup.Get();
        GLSetup.Validate("VAT Cash Regime", true);
        GLSetup.Modify();

        VATPostingSetup.Reset();
        VATPostingSetup.SetRange("VAT Bus. Posting Group", FindVATBusPostingGroup());
        VATPostingSetup.FindLast();

        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        VATPostingSetup."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        VATPostingSetup."Unrealized VAT Type" := VATPostingSetup."Unrealized VAT Type"::Percentage;
        VATPostingSetup."VAT Cash Regime" := true;
        VATPostingSetup."Sales VAT Unreal. Account" := VATPostingSetup."Sales VAT Account";
        VATPostingSetup."Purch. VAT Unreal. Account" := VATPostingSetup."Purchase VAT Account";
        VATPostingSetup.Insert();

        GenPostingSetup.Reset();
        GenPostingSetup.SetRange(
          "Gen. Bus. Posting Group", FindGenBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        GenPostingSetup.SetFilter("Sales Prepayments Account", '<>%1', '');
        GenPostingSetup.FindFirst();
        SetupVATOnGLAccount(GenPostingSetup."Sales Prepayments Account", VATPostingSetup);
        GenPostingSetup.SetFilter("Sales Prepayments Account", '<>%1', GenPostingSetup."Sales Prepayments Account");
        GenPostingSetup.ModifyAll("Sales Prepayments Account", GenPostingSetup."Sales Prepayments Account");

        GenPostingSetup.Reset();
        GenPostingSetup.SetRange(
          "Gen. Bus. Posting Group", FindGenBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        GenPostingSetup.SetFilter("Purch. Prepayments Account", '<>%1', '');
        GenPostingSetup.FindFirst();
        SetupVATOnGLAccount(GenPostingSetup."Purch. Prepayments Account", VATPostingSetup);
        GenPostingSetup.SetFilter("Purch. Prepayments Account", '<>%1', GenPostingSetup."Purch. Prepayments Account");
        GenPostingSetup.ModifyAll("Purch. Prepayments Account", GenPostingSetup."Purch. Prepayments Account");
    end;

    local procedure CreateNormalVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.Reset();
        VATPostingSetup.SetFilter("VAT %", '>%1', 0);
        VATPostingSetup.SetRange("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.FindFirst();
    end;

    local procedure CreateAndPostSalesInvoiceWithDocDate(CustomerNo: Code[20]; PostingDate: Date; DocumentDate: Date; VATProdPostingGroup: Code[20]; var Amount: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        Library340347Declaration.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, PostingDate, DocumentDate);
        Amount := Library340347Declaration.CreateSalesLine(SalesHeader, VATProdPostingGroup, 0);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostPurchInvoiceTypeC(VATPostingSetup: Record "VAT Posting Setup"; VendorNo: Code[20]; PostingDate: Date; var Amount: array[2] of Decimal; var TaxPct: array[2] of Decimal; var ExtPurchaseInvNo: Code[35]): Code[20]
    var
        PurchHeader: Record "Purchase Header";
        SecondVATPostingSetup: Record "VAT Posting Setup";
    begin
        CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, VendorNo, PostingDate);
        ExtPurchaseInvNo := PurchHeader."Vendor Invoice No.";

        Amount[1] := CreatePurchLine(PurchHeader, VATPostingSetup."VAT Prod. Posting Group", 0);
        TaxPct[1] := VATPostingSetup."VAT %";

        CreateDiffVATPostingSetup(SecondVATPostingSetup, VATPostingSetup);
        Amount[2] := CreatePurchLine(PurchHeader, SecondVATPostingSetup."VAT Prod. Posting Group", 0);
        TaxPct[2] := SecondVATPostingSetup."VAT %";

        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure CreateAndPostSalesInvoiceTypeC(VATPostingSetup: Record "VAT Posting Setup"; CustomerNo: Code[20]; PostingDate: Date; var Amount: array[2] of Decimal; var TaxPct: array[2] of Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SecondVATPostingSetup: Record "VAT Posting Setup";
    begin
        Library340347Declaration.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, PostingDate, PostingDate);
        Amount[1] := Library340347Declaration.CreateSalesLine(SalesHeader, VATPostingSetup."VAT Prod. Posting Group", 0);
        TaxPct[1] := VATPostingSetup."VAT %";

        CreateDiffVATPostingSetup(SecondVATPostingSetup, VATPostingSetup);
        Amount[2] := Library340347Declaration.CreateSalesLine(SalesHeader, SecondVATPostingSetup."VAT Prod. Posting Group", 0);
        TaxPct[2] := SecondVATPostingSetup."VAT %";

        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure FindBankAccount(): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.FindBankAccount(BankAccount);
        exit(BankAccount."No.");
    end;

    local procedure CreateBillGroup(var BillGroup: Record "Bill Group")
    begin
        BillGroup."No." := LibraryUtility.GenerateGUID();
        BillGroup."Bank Account No." := FindBankAccount();
        BillGroup.Insert(true);
    end;

    local procedure SettlePostedBillGroup(BillGroupNo: Code[20])
    var
        PostedCarteraDoc: Record "Posted Cartera Doc.";
    begin
        PostedCarteraDoc.SetRange("Bill Gr./Pmt. Order No.", BillGroupNo);
        REPORT.RunModal(REPORT::"Settle Docs. in Post. Bill Gr.", false, false, PostedCarteraDoc);
    end;

    local procedure CreateCustomer(VATBusPostingGroup: Code[20]): Code[20]
    var
        PmtMethod: Record "Payment Method";
    begin
        exit(CreateCustomerWithPmtMethod(PmtMethod."Bill Type"::Transfer, VATBusPostingGroup));
    end;

    local procedure CreateCustomerWithBills(VATBusPostingGroup: Code[20]): Code[20]
    var
        PmtMethod: Record "Payment Method";
    begin
        exit(CreateCustomerWithPmtMethod(PmtMethod."Bill Type"::"Bill of Exchange", VATBusPostingGroup));
    end;

    local procedure CreateCustomerWithPmtMethod(BillType: Enum "ES Bill Type"; VATBusPostingGroup: Code[20]): Code[20]
    var
        Customer: Record Customer;
        PmtTerms: Record "Payment Terms";
        PmtMethod: Record "Payment Method";
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Gen. Bus. Posting Group", FindGenBusPostingGroup(VATBusPostingGroup));
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        PmtMethod.SetRange("Bill Type", BillType);
        PmtMethod.FindFirst();
        Customer."Payment Method Code" := PmtMethod.Code;
        PmtTerms.FindFirst();
        Customer."Payment Terms Code" := PmtTerms.Code;
        Customer.Modify(true);
        LibraryVariableStorage.Enqueue(Customer."No.");
        exit(Customer."No.");
    end;

    local procedure CreateOperationCode(var OperationCode: Record "Operation Code"; OperationCodeValue: Code[1])
    begin
        OperationCode.Init();
        OperationCode.Validate(Code, OperationCodeValue);
        OperationCode.Insert();
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.")
    end;

    local procedure CreateVendor(VATBusPostingGroup: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        PmtTerms: Record "Payment Terms";
        PmtMethod: Record "Payment Method";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Gen. Bus. Posting Group", FindGenBusPostingGroup(VATBusPostingGroup));
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        PmtMethod.SetRange("Bill Type", PmtMethod."Bill Type"::Transfer);
        PmtMethod.FindFirst();
        Vendor."Payment Method Code" := PmtMethod.Code;
        PmtTerms.FindFirst();
        Vendor."Payment Terms Code" := PmtTerms.Code;
        Vendor.Modify(true);
        LibraryVariableStorage.Enqueue(Vendor."No.");
        exit(Vendor."No.");
    end;

    local procedure CreatePaymentOrder(var PaymentOrder: Record "Payment Order")
    begin
        PaymentOrder."No." := LibraryUtility.GenerateGUID();
        PaymentOrder."Bank Account No." := FindBankAccount();
        PaymentOrder.Insert(true);
    end;

    local procedure SettlePostedPaymentOrder(PaymentOrderNo: Code[20])
    var
        PostedCarteraDoc: Record "Posted Cartera Doc.";
    begin
        PostedCarteraDoc.SetRange("Bill Gr./Pmt. Order No.", PaymentOrderNo);
        REPORT.RunModal(REPORT::"Settle Docs. in Posted PO", false, false, PostedCarteraDoc);
    end;

    local procedure AddCarteraDocToPmtOrderBillGr(DocumentNo: Code[20]; PmtOrderBillGrDocNo: Code[20])
    var
        CarteraDoc: Record "Cartera Doc.";
    begin
        CarteraDoc.SetRange("Document No.", DocumentNo);
        CarteraDoc.ModifyAll("Bill Gr./Pmt. Order No.", PmtOrderBillGrDocNo);
    end;

    local procedure CreatePurchHeader(var PurchHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; PostingDate: Date)
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, DocumentType, VendorNo);
        PurchHeader.Validate("Prices Including VAT", true);
        PurchHeader.Validate("Posting Date", PostingDate);
        PurchHeader.Validate("Vendor Invoice No.", 'EXT.' + PurchHeader."No.");
        PurchHeader.Modify(true);
    end;

    local procedure CreatePurchLine(var PurchHeader: Record "Purchase Header"; VATProdPostingGrCode: Code[20]; Amount: Decimal): Decimal
    var
        Item: Record Item;
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::Item, Library340347Declaration.CreateItem(Item, VATProdPostingGrCode),
          LibraryRandom.RandIntInRange(2, 5));
        if Amount = 0 then
            PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandIntInRange(50, 100))
        else
            PurchLine.Validate("Direct Unit Cost", Amount / PurchLine.Quantity);
        PurchLine.Modify(true);
        exit(PurchLine."Line Amount");
    end;

    local procedure CreatePurchOrderWithPrepmt(var PurchHeader: Record "Purchase Header"; VATPostingSetup: Record "VAT Posting Setup"; PostingDate: Date; PrepmtPct: Decimal)
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Order, CreateVendor(VATPostingSetup."VAT Bus. Posting Group"));
        PurchHeader."Vendor Invoice No." := 'PREPMT.' + PurchHeader."No.";
        PurchHeader.Validate("Posting Date", PostingDate);
        PurchHeader.Validate("Prepayment %", PrepmtPct);
        PurchHeader.Modify(true);

        CreatePurchLine(PurchHeader, VATPostingSetup."VAT Prod. Posting Group", 0);
    end;

    local procedure CreateSalesOrderWithPrepmt(var SalesHeader: Record "Sales Header"; VATPostingSetup: Record "VAT Posting Setup"; PostingDate: Date; PrepmtPct: Decimal)
    begin
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"));
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Prepayment %", PrepmtPct);
        SalesHeader.Modify(true);

        Library340347Declaration.CreateSalesLine(SalesHeader, VATPostingSetup."VAT Prod. Posting Group", 0);
    end;

    local procedure CreatePurchaseInvoiceMultiLines(var PurchHeader: Record "Purchase Header"; VATBusPostingGroup: Code[20]; LinesCount: Integer)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        NewVATPostingSetup: Record "VAT Posting Setup";
        Amount: Decimal;
        i: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(
          PurchHeader, PurchHeader."Document Type"::Invoice, CreateVendor(VATBusPostingGroup));
        CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup);
        Library340347Declaration.CreatePurchaseLine(VATPostingSetup, PurchHeader, Amount);
        UpdateDirectUnitCostOnPurchLine(PurchHeader."No.", PurchHeader."Document Type", 0);
        for i := 1 to LinesCount - 1 do begin
            CreateVATPostingSetup(NewVATPostingSetup, VATPostingSetup."VAT Bus. Posting Group");
            Library340347Declaration.CreatePurchaseLine(NewVATPostingSetup, PurchHeader, Amount);
        end;
    end;

    local procedure DeleteBankAccountsInfo(BankAccNo: Code[20]) CCCNo: Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        BankAccount.Get(BankAccNo);
        BankAccount."Bank Account No." := '';
        CCCNo := BankAccount."CCC No.";
        BankAccount.Validate("CCC No.", '');
        BankAccount.IBAN := '';
        BankAccount.Modify();
    end;

    local procedure GetNextPmtMethod(PmtMethodCode: Code[10]): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.Get(PmtMethodCode);
        PaymentMethod.Next();
        exit(PaymentMethod.Code);
    end;

    local procedure PayForPurchInvoice(InvoiceNo: Code[20]): Code[20]
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.SetRange("Document No.", InvoiceNo);
        VendLedgEntry.FindLast();
        VendLedgEntry.CalcFields("Remaining Amount");
        exit(
          Library340347Declaration.CreateAndPostPaymentForPI(
            VendLedgEntry."Vendor No.", "Gen. Journal Document Type"::Invoice, InvoiceNo,
            VendLedgEntry."Posting Date" + 1, -VendLedgEntry."Remaining Amount"));
    end;

    local procedure PayForSalesInvoice(InvoiceNo: Code[20]): Code[20]
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document No.", InvoiceNo);
        CustLedgerEntry.FindLast();
        CustLedgerEntry.CalcFields("Remaining Amount");
        exit(
          Library340347Declaration.CreateAndPostPaymentForSI(
            CustLedgerEntry."Customer No.", "Gen. Journal Document Type"::Invoice, InvoiceNo,
            CustLedgerEntry."Posting Date" + 1, CustLedgerEntry."Remaining Amount"));
    end;

    local procedure PostPurchPrepmtInvoice(var PurchHeader: Record "Purchase Header"): Code[20]
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        LibraryPurchase.PostPurchasePrepaymentInvoice(PurchHeader);
        VendLedgEntry.FindLast();
        exit(VendLedgEntry."Document No.");
    end;

    local procedure PostSalesPrepmtInvoice(var SalesHeader: Record "Sales Header"): Code[20]
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);
        CustLedgEntry.FindLast();
        exit(CustLedgEntry."Document No.");
    end;

    local procedure PostFinalPurchInvoice(var PurchHeader: Record "Purchase Header"): Code[20]
    begin
        PurchHeader.Validate("Posting Date", PurchHeader."Posting Date" + 5);
        PurchHeader.Validate("Vendor Invoice No.", 'FI' + PurchHeader."Vendor Invoice No.");
        PurchHeader.Modify(true);
        exit(LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
    end;

    local procedure PostFinalSalesInvoice(var SalesHeader: Record "Sales Header"): Code[20]
    begin
        SalesHeader.Validate("Posting Date", SalesHeader."Posting Date" + 5);
        SalesHeader.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateDiffVATPostingSetup(var NewVATPostingSetup: Record "VAT Posting Setup"; VATPostingSetup: Record "VAT Posting Setup")
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        NewVATPostingSetup := VATPostingSetup;
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        NewVATPostingSetup."VAT Prod. Posting Group" := VATProductPostingGroup.Code;
        NewVATPostingSetup."VAT %" += 1;
        NewVATPostingSetup."VAT Identifier" := IncStr(VATPostingSetup."VAT Identifier");
        NewVATPostingSetup.Insert();
    end;

    local procedure UpdatePurchReverseChargePaymentCollectionAmount(var TempTest340DeclarationLineBuf: Record "Test 340 Declaration Line Buf." temporary; DocNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocNo);
        VATEntry.FindFirst();
        TempTest340DeclarationLineBuf."Collection Amount" := VATEntry.Base + VATEntry.Amount;
        TempTest340DeclarationLineBuf.Modify();
    end;

    local procedure ApplyAndPostPayment(InvoiceDocNo: Code[20]; AccountNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal; AccountType: Enum "Gen. Journal Account Type"; GenPostingType: Enum "General Posting Type"; PostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, AccountType, AccountNo, -1 * Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Bal. Account No.", GLAccountNo);
        GenJournalLine.Validate("Gen. Posting Type", GenPostingType);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure DateToText(Date: Date): Text[8]
    begin
        exit(Format(Date, 8, '<Year4><Month,2><Day,2>'));
    end;

    local procedure FillPurchExpectedBuffer(var Test340DeclarationLineBuf: Record "Test 340 Declaration Line Buf."; DocumentNo: Code[20]; VATDocumentNo: Code[35]; OperationCode: Code[1]; CollectionPaymentMethod: Text[1]; CollectionBankAcc: Text[35]; NoOfRegisters: Integer)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.SetRange("Document No.", DocumentNo);
        VendLedgEntry.FindLast();
        Create340DeclarationLineBufPurch(
          VendLedgEntry, Test340DeclarationLineBuf, VATDocumentNo, OperationCode, CollectionPaymentMethod, CollectionBankAcc, NoOfRegisters);
    end;

    local procedure FillSalesExpectedBuffer(var Test340DeclarationLineBuf: Record "Test 340 Declaration Line Buf."; DocumentNo: Code[20]; VATDocumentNo: Code[20]; OperationCode: Code[1]; CollectionPaymentMethod: Text[1]; CollectionBankAcc: Text[35])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.SetRange("Document No.", DocumentNo);
        CustLedgEntry.FindLast();
        Test340DeclarationLineBuf.Init();
        Test340DeclarationLineBuf.Type := Test340DeclarationLineBuf.Type::Sale;
        Test340DeclarationLineBuf."Entry No." += 1;
        Test340DeclarationLineBuf."CV No." := CustLedgEntry."Customer No.";
        Test340DeclarationLineBuf."Posting Date" := CustLedgEntry."Posting Date";
        Test340DeclarationLineBuf."Document Type" := CustLedgEntry."Document Type".AsInteger();
        Test340DeclarationLineBuf."Document No." := CustLedgEntry."Document No.";
        Test340DeclarationLineBuf."VAT Document No." := VATDocumentNo;
        Test340DeclarationLineBuf."Operation Code" := OperationCode;
        Test340DeclarationLineBuf."Tax %" := -1;
        // a marker of not set value
        Test340DeclarationLineBuf."No. of Registers" := 1;
        if CollectionPaymentMethod <> '' then begin
            Test340DeclarationLineBuf."Collection Date" := CustLedgEntry."Posting Date";
            CustLedgEntry.CalcFields("Original Amount");
            Test340DeclarationLineBuf."Collection Amount" := CustLedgEntry."Original Amount";
            Test340DeclarationLineBuf."Collection Payment Method" := CollectionPaymentMethod;
            Test340DeclarationLineBuf."Collection Bank Acc./Check No." := CollectionBankAcc;
        end;
        Test340DeclarationLineBuf.Insert();
    end;

    local procedure Create340DeclarationLineBufPurch(VendLedgEntry: Record "Vendor Ledger Entry"; var Test340DeclarationLineBuf: Record "Test 340 Declaration Line Buf."; VATDocumentNo: Code[35]; OperationCode: Code[1]; CollectionPaymentMethod: Text[1]; CollectionBankAcc: Text[35]; NoOfRegisters: Integer)
    begin
        Test340DeclarationLineBuf.Init();
        Test340DeclarationLineBuf.Type := Test340DeclarationLineBuf.Type::Purchase;
        Test340DeclarationLineBuf."Entry No." += 1;
        Test340DeclarationLineBuf."CV No." := VendLedgEntry."Vendor No.";
        Test340DeclarationLineBuf."Posting Date" := VendLedgEntry."Posting Date";
        Test340DeclarationLineBuf."Document Type" := VendLedgEntry."Document Type".AsInteger();
        Test340DeclarationLineBuf."Document No." := VendLedgEntry."Document No.";
        Test340DeclarationLineBuf."VAT Document No." := VATDocumentNo;
        Test340DeclarationLineBuf."Operation Code" := OperationCode;
        Test340DeclarationLineBuf."Tax %" := -1;
        // a marker of not set value
        Test340DeclarationLineBuf."No. of Registers" := NoOfRegisters;
        if CollectionPaymentMethod <> '' then begin
            Test340DeclarationLineBuf."Collection Date" := VendLedgEntry."Posting Date";
            VendLedgEntry.CalcFields("Original Amount");
            Test340DeclarationLineBuf."Collection Amount" := VendLedgEntry."Original Amount";
            Test340DeclarationLineBuf."Collection Payment Method" := CollectionPaymentMethod;
            Test340DeclarationLineBuf."Collection Bank Acc./Check No." := CollectionBankAcc;
        end;
        Test340DeclarationLineBuf.Insert();
    end;

    local procedure FindLine(ExportFileName: Text[1024]; SearchStartingPosition: Integer; TextToSearch: Text[500]) Line: Text[1024]
    begin
        if TextToSearch = '' then
            Assert.Fail('Text to search is empty. Test Defect?');

        Line :=
          LibraryTextFileValidation.FindLineWithValue(
            ExportFileName, SearchStartingPosition, StrLen(TextToSearch), TextToSearch);

        if Line = '' then
            Assert.Fail(
              StrSubstNo(
                'Line for value #%1 not found on expected position %2.',
                TextToSearch, SearchStartingPosition));
    end;

    local procedure FindPaymentVLE(var VendLedgEntry: Record "Vendor Ledger Entry"; DocumentNo: Code[20]; FindAmount: Decimal)
    begin
        LibraryERM.FindVendorLedgerEntry(VendLedgEntry, VendLedgEntry."Document Type"::Payment, DocumentNo);
        VendLedgEntry.SetRange(Amount, FindAmount);
        VendLedgEntry.FindFirst();
    end;

    local procedure UpdateDirectUnitCostOnPurchLine(DocumentNo: Code[20]; DocumentType: Enum "Purchase Document Type"; DirectUnitCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.FindLast();
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure FindBancAccountUsed(IsForCustomer: Boolean; CustVendNo: Code[20]): Code[20]
    var
        BankAccountLedgEntry: Record "Bank Account Ledger Entry";
    begin
        BankAccountLedgEntry.SetRange("Bal. Account No.", CustVendNo);
        if IsForCustomer then
            BankAccountLedgEntry.SetRange("Bal. Account Type", BankAccountLedgEntry."Bal. Account Type"::Customer)
        else
            BankAccountLedgEntry.SetRange("Bal. Account Type", BankAccountLedgEntry."Bal. Account Type"::Vendor);
        if not BankAccountLedgEntry.FindFirst() then
            exit('');
        exit(BankAccountLedgEntry."Bank Account No.");
    end;

    local procedure FindBancAccountNoUsed(IsForCustomer: Boolean; CustVendNo: Code[20]): Code[35]
    begin
        exit(GetAccountNoForBank(FindBancAccountUsed(IsForCustomer, CustVendNo)));
    end;

    local procedure GetAccountNoForBank(BankAccountNo: Code[20]): Code[20]
    var
        BankAccount: Record "Bank Account";
    begin
        if not BankAccount.Get(BankAccountNo) then
            exit('');
        if BankAccount."CCC No." <> '' then
            exit(BankAccount."CCC No.");
        if BankAccount."Bank Account No." <> '' then
            exit(BankAccount."Bank Account No.");
        exit(BankAccount.IBAN);
    end;

    local procedure FindGenBusPostingGroup(VATBusPostingGroupCode: Code[20]): Code[20]
    var
        GenBusPostingGroup: Record "Gen. Business Posting Group";
    begin
        GenBusPostingGroup.SetRange("Def. VAT Bus. Posting Group", VATBusPostingGroupCode);
        GenBusPostingGroup.FindFirst();
        exit(GenBusPostingGroup.Code);
    end;

    local procedure FindVATBusPostingGroup(): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.SetFilter("VAT Bus. Posting Group", '<>''''');
        VATPostingSetup.SetFilter("VAT Prod. Posting Group", '<>%1', '');
        VATPostingSetup.SetFilter("VAT %", '<>%1', 0);
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.SetFilter("Sales VAT Account", '<>%1', '');
        VATPostingSetup.SetFilter("Purchase VAT Account", '<>%1', '');
        VATPostingSetup.FindFirst();
        exit(VATPostingSetup."VAT Bus. Posting Group");
    end;

    local procedure CreateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusPostingGroupCode: Code[20])
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(
          VATPostingSetup, VATBusPostingGroupCode, VATProductPostingGroup.Code);
        VATPostingSetup.Validate(
          "VAT Identifier", LibraryUtility.GenerateRandomCode20(VATPostingSetup.FieldNo("VAT Identifier"), DATABASE::"VAT Posting Setup"));
        VATPostingSetup.Validate("VAT %", LibraryRandom.RandInt(20));
        VATPostingSetup.Validate("Purchase VAT Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    local procedure Set100PctLineDiscOnSalesDoc(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        if SalesLine.FindSet() then
            repeat
                SalesLine.Validate("Line Discount %", 100);
                SalesLine.Modify(true);
            until SalesLine.Next() = 0;
    end;

    local procedure SetOperationCodeOnGPPG(NewOperationCode: Code[1])
    var
        GenProdPostingGroup: Record "Gen. Product Posting Group";
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.FindLast();
        GenProdPostingGroup.Get(VATEntry."Gen. Prod. Posting Group");
        GenProdPostingGroup."Operation Code" := NewOperationCode;
        GenProdPostingGroup.Modify();
    end;

    local procedure SetupVATOnGLAccount(GLAccountNo: Code[20]; VATPostingSetup: Record "VAT Posting Setup")
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.Get(GLAccountNo);
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Modify();
    end;

    local procedure VerifyFieldInExportedFile(StartingPosition: Integer; FileName: Text[1024]; ExpectedValue: Text[1024])
    var
        FieldValue: Text[1024];
    begin
        FieldValue :=
          LibraryTextFileValidation.ReadValue(LibraryTextFileValidation.FindLineWithValue(FileName, StartingPosition,
              StrLen(ExpectedValue), ExpectedValue), StartingPosition, StrLen(ExpectedValue));
        Assert.AreEqual(ExpectedValue, FieldValue, '');
    end;

    local procedure VerifyPeriodInExportedRecType1(VATPostingSetup: Record "VAT Posting Setup"; PostingDate: Date; ExpectedPeriod: Text[2])
    var
        CompanyInformation: Record "Company Information";
        FieldValue: Text[1024];
        CompanyName: Text[10];
        ExportFileName: Text[1024];
        Line: Text[1024];
        Amount: Decimal;
    begin
        Library340347Declaration.CreateAndPostSalesInvoice(
          VATPostingSetup, CreateCustomer(VATPostingSetup."VAT Bus. Posting Group"), PostingDate, Amount);

        ExportFileName := Library340347Declaration.RunMake340DeclarationReport(PostingDate);

        CompanyInformation.Get();
        CompanyName := UpperCase(CopyStr(CompanyInformation.Name, 1, 10));
        Line := LibraryTextFileValidation.FindLineWithValue(ExportFileName, 18, 10, CompanyName);

        FieldValue := LibraryTextFileValidation.ReadValue(Line, 136, 2);
        Assert.AreEqual(ExpectedPeriod, FieldValue, ValueNotFoundMsg);
    end;

    local procedure VerifyTotalNoOfRec(ExportFileName: Text[1024]; ExpectedNoOfRec: Integer)
    var
        CompanyInformation: Record "Company Information";
        FieldValue: Text[1024];
        CompanyName: Text[10];
        NoOfRec: Integer;
        Line: Text[1024];
    begin
        CompanyInformation.Get();
        CompanyName := UpperCase(CopyStr(CompanyInformation.Name, 1, 10));
        Line := LibraryTextFileValidation.FindLineWithValue(ExportFileName, 18, 10, CompanyName);

        FieldValue := LibraryTextFileValidation.ReadValue(Line, 145, 2);
        Evaluate(NoOfRec, FieldValue, 9);
        Assert.AreEqual(ExpectedNoOfRec, NoOfRec, WrongTotalNoOfRecsErr);
    end;

    local procedure Validate_InsertTextWithReplace(OriginalText: Text[500]; TextToInsert: Text[500]; Position: Integer; Expected: Text[100])
    var
        Make340Declaration: Report "Make 340 Declaration";
        Result: Text[1024];
    begin
        Result := Make340Declaration.InsertTextWithReplace(OriginalText, TextToInsert, Position);

        Assert.AreEqual(Expected, Result, 'Incorrect replace.');
    end;

    local procedure VerifyCollectionDataIn340Export(ExportFileName: Text[1024]; var TempTest340DeclarationLineBuf2: Record "Test 340 Declaration Line Buf." temporary)
    begin
        if TempTest340DeclarationLineBuf2.FindSet() then
            repeat
                VerifyCollectionInfoInFile(ExportFileName, TempTest340DeclarationLineBuf2)
            until TempTest340DeclarationLineBuf2.Next() = 0;
    end;

    local procedure VerifyCollectionInfoInFile(ExportFileName: Text[1024]; TempTest340DeclarationLineBuf2: Record "Test 340 Declaration Line Buf." temporary)
    var
        Line: Text[1024];
        ExpectedValue: array[5] of Text[500];
        Len: array[5] of Integer;
        Pos: array[5] of Integer;
    begin
        TempTest340DeclarationLineBuf2.GetFieldData(TempTest340DeclarationLineBuf2.FieldNo("Document No."), ExpectedValue[1], Pos[1], Len[1]);
        TempTest340DeclarationLineBuf2.GetFieldData(TempTest340DeclarationLineBuf2.FieldNo("Collection Amount"), ExpectedValue[2], Pos[2], Len[2]);
        Line := LibraryTextFileValidation.FindLineWithValues(ExportFileName, Pos, Len, ExpectedValue);
        if Line = '' then
            Error(
              StrSubstNo(
                'Line for value #%1 not found on expected position %2.',
                StrSubstNo('%1|%2', ExpectedValue[1], ExpectedValue[2]), StrSubstNo('%1|%2', Pos[1], Pos[2])));

        Assert.AreEqual(TempTest340DeclarationLineBuf2.GetFieldLen(0), StrLen(Line), 'Record Line length');
        if TempTest340DeclarationLineBuf2."Document No." <> '' then
            TempTest340DeclarationLineBuf2.VerifyField(Line, TempTest340DeclarationLineBuf2.FieldNo("No. of Registers"));
        TempTest340DeclarationLineBuf2.VerifyField(Line, TempTest340DeclarationLineBuf2.FieldNo("VAT Document No."));
        TempTest340DeclarationLineBuf2.VerifyField(Line, TempTest340DeclarationLineBuf2.FieldNo("Operation Code"));
        TempTest340DeclarationLineBuf2.VerifyField(Line, TempTest340DeclarationLineBuf2.FieldNo("Collection Date"));
        TempTest340DeclarationLineBuf2.VerifyField(Line, TempTest340DeclarationLineBuf2.FieldNo("Collection Amount"));
        TempTest340DeclarationLineBuf2.VerifyField(Line, TempTest340DeclarationLineBuf2.FieldNo("Collection Payment Method"));
        TempTest340DeclarationLineBuf2.VerifyField(Line, TempTest340DeclarationLineBuf2.FieldNo("Collection Bank Acc./Check No."));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure Declaration340LinesPageHandler(var Declaration340Lines: TestPage "340 Declaration Lines")
    begin
        Declaration340Lines.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Make340DeclarationHandler(var Make340Declaration: TestRequestPage "Make 340 Declaration")
    var
        BilToPayToNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(BilToPayToNo);
        Make340Declaration.VATEntry.SetFilter("Bill-to/Pay-to No.", BilToPayToNo);
        Make340Declaration.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure ExportedSuccessfullyMessageHandler(Message: Text[1024])
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

