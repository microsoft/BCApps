codeunit 147303 "Make 340 Dec. 2012 RegF"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        IsInitialized := false;

        OperationCodeStartingPosition := 100; // defined by format of the Report 340 file.
        InvoiceNoStartingPosition := 218; // defined by format of the Report 340 file.
        CreditMemoStartingPosition := 218; // defined by format of the Report 340 file.
        VATStartingPosition := 118; // defined by format of the Report 340 file.
        ECStartingPosition := 367;  // defined by format of the Report 340 file.

        OperationCodeC := 'C';
        OperationCodeD := 'D';
        OperationCodeI := 'I';
        OperationCodeR := 'R';
    end;

    var
        Assert: Codeunit Assert;
        Library340: Codeunit "Library - Make 340 Declaration";
        Library340347Declaration: Codeunit "Library - 340 347 Declaration";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERMUnapply: Codeunit "Library - ERM Unapply";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;
        BookTypeCode: Label 'E';
        ESCountryCode: Label 'ES';
        CannotInsertPropertyTaxAccNo: Label 'You cannot insert property tax account no. for selected property location.';
        OperationCodeStartingPosition: Integer;
        InvoiceNoStartingPosition: Integer;
        CreditMemoStartingPosition: Integer;
        VATStartingPosition: Integer;
        ECStartingPosition: Integer;
        OperationCodeC: Code[1];
        OperationCodeD: Code[1];
        OperationCodeI: Code[1];
        OperationCodeR: Code[1];
        IncorrectCashCollectablesAmount: Label 'The amount of Cash Collecctables is incorrect.';
        IncorrectCompanyVATRegNo: Label 'The value of Company VAT Registeration Numer is incorrect.';
        IncorrectCustomerVATRegNo: Label 'The value of Customer VAT Registration Number is incorrect.';
        IncorrectLegalRepVATNo: Label 'The value of Legal Representative VAT Number is incorrect.';
        IncorrectNoOfLines: Label 'The numbers of lines generated in 340 declaration for a customer''s operations is incorrect.';
        IncorrectNumericExercise: Label 'The value of Numeric Exercise is incorrect.';
        IncorrectNoOfRegisters: Label 'The value for NoOfRegisters field is incorrect.';
        IncorrectOperationCode: Label 'The value for OperationCode field is incorrect.';
        IncorrectPropertyLocation: Label 'The value of Property Location is incorrect.';
        IncorrectPropertyTaxAccNo: Label 'The value of Property Tax Account Numer is incorrect.';
        NotEqualValues: Label 'The expected value is %1 while the actual value is %2.';
        NoRecordsFoundError: Label 'No records were found to be included in the declaration. The process has been aborted. No file will be created.';
        NumericExerciseBlank: Label '    ';
        NumericExerciseZero: Label '0000';
        UnexpectedReportLines: Label 'Unexpected number of lines with VAT% %1 and EC% %2. The expected value is %3 while the actual value is %4.';

    [Test]
    [Scope('OnPrem')]
    procedure AppliedPmtLessThanThreshold()
    var
        Cust: Record Customer;
        GLAcc: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceDocNo: Code[20];
        Amount: Decimal;
        ReferenceDate: Date;
    begin
        Initialize();

        // Pre-Setup
        Amount := LibraryRandom.RandDec(5999, 2);
        ReferenceDate := GetBasisOfCalcForPostingDate();

        // Setup
        CreateCustomer(Cust);
        LibraryERM.FindGLAccount(GLAcc);

        InvoiceDocNo := CreateAndPostInvoiceUsingJournal(Cust."No.", GLAcc."No.", Amount,
            GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);
        ApplyAndPostPayment(InvoiceDocNo, Cust."No.", GLAcc."No.", Amount,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", CalcDate('<1Y>', ReferenceDate));

        // Exercise
        asserterror Library340.RunMake340DeclarationReport(Date2DMY(ReferenceDate, 3) + 1, GLAcc."No.",
            Date2DMY(ReferenceDate, 2), Amount + LibraryRandom.RandDec(100, 2));

        // Verify
        Assert.ExpectedError(NoRecordsFoundError);

        // Tear-Down
        RemoveCustomerVATRegNo(Cust."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure AppliedPmtIsMoreThanThreshold()
    var
        GLAcc: Record "G/L Account";
        Cust: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        ActualAmount: Text[15];
        ActualNumericExercise: Text[4];
        Amount: Decimal;
        ExpectedAmount: Text[15];
        ExportedFileName: Text[1024];
        InvoiceDocNo: Code[20];
        Line: Text[1024];
        ReferenceDate: Date;
    begin
        // Setup.
        Initialize();

        // Pre-Setup
        Amount := LibraryRandom.RandDecInRange(6000, 10000, 2);
        ReferenceDate := GetBasisOfCalcForPostingDate();

        // Setup
        CreateCustomer(Cust);
        LibraryERM.FindGLAccount(GLAcc);

        InvoiceDocNo := CreateAndPostInvoiceUsingJournal(Cust."No.", GLAcc."No.", Amount,
            GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);
        ApplyAndPostPayment(InvoiceDocNo, Cust."No.", GLAcc."No.", Amount,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", CalcDate('<1Y>', ReferenceDate));

        // Exercise
        ExportedFileName := Library340.RunMake340DeclarationReport(Date2DMY(ReferenceDate, 3) + 1, GLAcc."No.",
            Date2DMY(ReferenceDate, 2), Amount - LibraryRandom.RandDec(100, 2));

        // Post-Exercise
        Line := Library340.ReadCustomerLine(ExportedFileName, Cust.Name);

        // Verify
        ActualAmount := Library340.ReadCashCollectableAmountInteger(Line);
        ExpectedAmount := CalculateExpectedAmount(Amount);
        Assert.AreEqual(ExpectedAmount, ActualAmount, IncorrectCashCollectablesAmount);

        VerifyPropertyTaxLine(Line, ' ', '0', '', false);

        ActualNumericExercise := Library340.ReadNumericExercise(Line);
        Assert.AreEqual(Format(Date2DMY(ReferenceDate, 3)), ActualNumericExercise, IncorrectNumericExercise);

        // Tear-Down
        RemoveCustomerVATRegNo(Cust."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateInvalidOpCodeC()
    var
        OperationCode: Record "Operation Code";
    begin
        // TFS298166 - http://vstfnav:8080/tfs/web/wi.aspx?id=298166
        Initialize();
        asserterror Library340.CreateOperationCode(OperationCode, OperationCodeC);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateInvalidOpCodeD()
    var
        OperationCode: Record "Operation Code";
    begin
        // TFS298166 - http://vstfnav:8080/tfs/web/wi.aspx?id=298166
        Initialize();
        asserterror Library340.CreateOperationCode(OperationCode, OperationCodeD);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateInvalidOpCodeI()
    var
        OperationCode: Record "Operation Code";
    begin
        // TFS298166 - http://vstfnav:8080/tfs/web/wi.aspx?id=298166
        Initialize();
        asserterror Library340.CreateOperationCode(OperationCode, OperationCodeI);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateAndMapOpCode()
    var
        OperationCode: Record "Operation Code";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        // Setup
        Initialize();

        // Exercise
        Library340.CreateOperationCode(OperationCode, GetValidCharacter());
        MapOperationCode(GenProductPostingGroup, OperationCode.Code);

        // Verify
        Assert.AreEqual(GenProductPostingGroup."Operation Code", OperationCode.Code, IncorrectOperationCode);

        // TearDown
        UnmapAndDeleteOperationCode(OperationCode, GenProductPostingGroup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteOpCodeMappedToGenProdPG()
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        OperationCode: Record "Operation Code";
    begin
        // Setup
        Initialize();

        // Exercise
        Library340.CreateOperationCode(OperationCode, GetValidCharacter());
        MapOperationCode(GenProductPostingGroup, OperationCode.Code);

        // Verify
        OperationCode.Reset();
        OperationCode.Get(OperationCode.Code);
        asserterror OperationCode.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure InvoicePriorTo2012AreNotConsideredFor340Report()
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceDocNo: Code[20];
        ReferenceAmount: Decimal;
        Amount: Decimal;
        FirstPaymentAmount: Decimal;
        ReferenceDate: Date;
    begin
        // TFS300246 - http://vstfnav:8080/tfs/web/wi.aspx?id=300246
        Initialize();

        // Pre-Setup
        PreSetup(Customer, GLAccount, ReferenceAmount, Amount, FirstPaymentAmount, ReferenceDate);
        ReferenceDate := LibraryUtility.GenerateRandomDate(DMY2Date(1, 1, 2000), DMY2Date(31, 12, 2011));

        // Setup
        InvoiceDocNo := CreateAndPostInvoiceUsingJournal(Customer."No.", GLAccount."No.", Amount,
            GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);
        ApplyAndPostPayment(InvoiceDocNo, Customer."No.", GLAccount."No.", Amount,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);

        // Exercise
        asserterror Library340.RunMake340DeclarationReport(Date2DMY(ReferenceDate, 3), GLAccount."No.",
            Date2DMY(ReferenceDate, 2), Amount - LibraryRandom.RandDec(100, 2));

        // Verify
        Assert.ExpectedError(NoRecordsFoundError);

        // Tear-Down
        RemoveCustomerVATRegNo(Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MapInvalidOpCodeC()
    var
        GenProdPostingGroup: Record "Gen. Product Posting Group";
    begin
        // Setup
        Initialize();

        // Exercise and Verify
        asserterror MapOperationCode(GenProdPostingGroup, OperationCodeC);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MapInvalidOpCodeD()
    var
        GenProdPostingGroup: Record "Gen. Product Posting Group";
    begin
        // Setup
        Initialize();

        // Exercise and Verify
        asserterror MapOperationCode(GenProdPostingGroup, OperationCodeD);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MapInvalidOpCodeI()
    var
        GenProdPostingGroup: Record "Gen. Product Posting Group";
    begin
        // Setup
        Initialize();

        // Exercise and Verify
        asserterror MapOperationCode(GenProdPostingGroup, OperationCodeI);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure MultiplePaymentsFromCustomerAppliedToInvoicesWithBill()
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        ExportedFileName: Text[1024];
        Line: Text[1024];
        FiscalYear: Integer;
        SecondPaymentAmount: Decimal;
        FirstPaymentAmount: Decimal;
        ReferenceAmount: Decimal;
        ReferenceDate: Date;
    begin
        // Post multiple payments from customer applied to invoices with bill.
        // TFS301791 - http://vstfnav:8080/tfs/web/wi.aspx?id=301791.
        // Setup.
        Initialize();
        PreSetup(Customer, GLAccount, ReferenceAmount, FirstPaymentAmount, SecondPaymentAmount, ReferenceDate);
        FiscalYear := Date2DMY(ReferenceDate, 3);
        PostAndApplyPaymentToAnInvoiceWithBill(GLAccount."No.", Customer."No.", FirstPaymentAmount,
          ReferenceDate, ReferenceDate);
        PostAndApplyPaymentToAnInvoiceWithBill(GLAccount."No.", Customer."No.", SecondPaymentAmount,
          ReferenceDate, CalcDate('<1Y>', ReferenceDate));

        // Exercise: Run report 'Make 340 Declaration'.
        ExportedFileName := Library340.RunMake340DeclarationReport(FiscalYear + 1, GLAccount."No.",
            Date2DMY(ReferenceDate, 2), ReferenceAmount);

        // Verify: Verify exported file.
        Line := Library340.ReadCustomerLine(ExportedFileName, Customer.Name);
        VerifyCashCollectableValues(Line, FirstPaymentAmount + SecondPaymentAmount, Format(FiscalYear));

        // Tear-Down.
        RemoveCustomerVATRegNo(Customer."No.");
    end;

    [Test]
    [HandlerFunctions('ModalPageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure MultiplePaymentsFromCustomerAppliedToInvoicesWithBillAlsoHavingAnUnpaidInvoice()
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        ExportedFileName: Text[1024];
        Line: Text[1024];
        FiscalYear: Integer;
        FirstPaymentAmount: Decimal;
        SecondPaymentAmount: Decimal;
        ReferenceAmount: Decimal;
        ReferenceDate: Date;
    begin
        // Post multiple payments from customer applied to invoices with bill also having an unpaid invoice.
        // TFS301815 - http://vstfnav:8080/tfs/web/wi.aspx?id=301815.
        // Setup.
        Initialize();
        PreSetup(Customer, GLAccount, ReferenceAmount, FirstPaymentAmount, SecondPaymentAmount, ReferenceDate);
        FiscalYear := Date2DMY(ReferenceDate, 3);
        PostAndApplyPaymentToAnInvoiceWithBill(GLAccount."No.", Customer."No.", FirstPaymentAmount,
          ReferenceDate, ReferenceDate);
        PostAndApplyPaymentToAnInvoiceWithBill(GLAccount."No.", Customer."No.", SecondPaymentAmount,
          ReferenceDate, CalcDate('<1Y>', ReferenceDate));
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", CalcDate('<1Y>', ReferenceDate), '',
          LibraryRandom.RandDecInRange(FirstPaymentAmount, SecondPaymentAmount, 2));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise: Run report 'Make 340 Declaration'.
        ExportedFileName := Library340.RunMake340DeclarationReport(FiscalYear + 1, GLAccount."No.",
            Date2DMY(ReferenceDate, 2), ReferenceAmount);

        // Verify: Verify exported file.
        Line := Library340.ReadNumericExerciseLine(ExportedFileName, Format(FiscalYear));
        VerifyCashCollectableValues(Line, FirstPaymentAmount + SecondPaymentAmount, Format(FiscalYear));

        // Tear-Down.
        RemoveCustomerVATRegNo(Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MapTwoOperationCodesToOneProdPostGroup()
    var
        OperationCode: Record "Operation Code";
        GenProductPostingGroup1: Record "Gen. Product Posting Group";
        GenProductPostingGroup2: Record "Gen. Product Posting Group";
    begin
        // TFS298171 - http://vstfnav:8080/tfs/web/wi.aspx?id=298171
        // Setup
        Initialize();

        // Exercise
        Library340.CreateOperationCode(OperationCode, GetValidCharacter());
        MapOperationCode(GenProductPostingGroup1, OperationCode.Code);
        MapOperationCode(GenProductPostingGroup2, OperationCode.Code);

        // Verify
        Assert.AreEqual(OperationCode.Code, GenProductPostingGroup1."Operation Code", IncorrectOperationCode);
        Assert.AreEqual(OperationCode.Code, GenProductPostingGroup2."Operation Code", IncorrectOperationCode);

        // Tear Down
        GenProductPostingGroup1.Delete(true);
        UnmapAndDeleteOperationCode(OperationCode, GenProductPostingGroup2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultiYear2SalesInvoices3PaymentsError()
    var
        Cust: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GLAcc: Record "G/L Account";
        AmountLessThanMin: Decimal;
        AmountMoreThanMin: Decimal;
        FirstPaymentAmount: Decimal;
        InvoiceDocNo: Code[20];
        MinPaymentAmount: Decimal;
        ReferenceDate: Date;
    begin
        // TFS299480 - http://vstfnav:8080/tfs/web/wi.aspx?id=299480
        Initialize();

        // Pre-Setup
        ReferenceDate := GetBasisOfCalcForPostingDate();
        MinPaymentAmount := 1000 * LibraryRandom.RandInt(10);
        AmountMoreThanMin := LibraryRandom.RandDecInRange(MinPaymentAmount + 1000, MinPaymentAmount + 2000, 2);
        FirstPaymentAmount := LibraryRandom.RandDecInRange(MinPaymentAmount, AmountMoreThanMin div 1, 2);
        AmountLessThanMin := LibraryRandom.RandDec(MinPaymentAmount - 1, 2);

        // Setup
        CreateCustomer(Cust);
        LibraryERM.FindGLAccount(GLAcc);

        InvoiceDocNo := CreateAndPostInvoiceUsingJournal(Cust."No.", GLAcc."No.", AmountMoreThanMin,
            GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);
        ApplyAndPostPayment(InvoiceDocNo, Cust."No.", GLAcc."No.", FirstPaymentAmount,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);
        ApplyAndPostPayment(InvoiceDocNo, Cust."No.", GLAcc."No.", AmountMoreThanMin - FirstPaymentAmount,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", CalcDate('<1Y>', ReferenceDate));

        // Pre-Exercise
        InvoiceDocNo := CreateAndPostInvoiceUsingJournal(Cust."No.", GLAcc."No.", AmountLessThanMin,
            GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", CalcDate('<2Y>', ReferenceDate));
        ApplyAndPostPayment(InvoiceDocNo, Cust."No.", GLAcc."No.", AmountLessThanMin,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", CalcDate('<2Y>', ReferenceDate));

        // Exercise
        asserterror Library340.RunMake340DeclarationReport(
            Date2DMY(CalcDate('<2Y>', ReferenceDate), 3), GLAcc."No.", Date2DMY(ReferenceDate, 2), MinPaymentAmount);

        // Verify
        Assert.ExpectedError(NoRecordsFoundError);

        // Tear-Down
        RemoveCustomerVATRegNo(Cust."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure MultiYear3SalesInvoices3Payments()
    var
        Cust: Record Customer;
        ActualAmount: Decimal;
        ActualNumericExercise: Text[4];
        ActualOperationCode: Code[1];
        Amount: Decimal;
        CustNo: Code[20];
        ExportedFileName: Text[1024];
        FiscalYear: Integer;
        GLAccNo: Code[20];
        Line: Text[1024];
        MinPaymentAmount: Decimal;
        ReferenceDate: Date;
    begin
        // TFS299519 - http://vstfnav:8080/tfs/web/wi.aspx?id=299519
        Initialize();

        // Pre-Setup
        PostSalesInvAndApplyPaymentsInPreviousYears(ReferenceDate, CustNo, GLAccNo, MinPaymentAmount);
        FiscalYear := Date2DMY(CalcDate('<2Y>', ReferenceDate), 3);

        // Setup
        Amount := LibraryRandom.RandDecInRange(MinPaymentAmount + 1000, MinPaymentAmount + 2000, 2);
        PostSalesInvoiceAndApplyPayment(CustNo, GLAccNo, Amount, CalcDate('<1Y>', ReferenceDate), Amount, CalcDate('<1Y>', ReferenceDate));
        PostSalesInvoiceAndApplyPayment(CustNo, GLAccNo, Amount, CalcDate('<2Y>', ReferenceDate), Amount, CalcDate('<2Y>', ReferenceDate));

        // Exercise
        ExportedFileName := Library340.RunMake340DeclarationReport(FiscalYear, GLAccNo, Date2DMY(ReferenceDate, 2), MinPaymentAmount);

        // Post-Exercise
        Cust.Get(CustNo);
        Line := Library340.ReadCustomerLine(ExportedFileName, Cust.Name);

        // Verify
        ActualOperationCode := Library340.ReadOperationCode(Line);
        Assert.AreEqual('', ActualOperationCode, IncorrectOperationCode);

        ActualAmount := Library340.ReadCashCollectablesAsAbsolute(Line);
        Assert.AreEqual(Amount, ActualAmount, IncorrectCashCollectablesAmount);

        ActualNumericExercise := Library340.ReadNumericExercise(Line);
        Assert.AreEqual(Format(FiscalYear), ActualNumericExercise, IncorrectNumericExercise);

        // Tear-Down
        RemoveCustomerVATRegNo(Cust."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultiYear3SalesInvoices3PaymentsError()
    var
        CustNo: Code[20];
        AmountLessThanMin: Decimal;
        GLAccNo: Code[20];
        MinPaymentAmount: Decimal;
        ReferenceDate: Date;
    begin
        // TFS299513 - http://vstfnav:8080/tfs/web/wi.aspx?id=299513
        Initialize();

        // Pre-Setup
        PostSalesInvAndApplyPaymentsInPreviousYears(ReferenceDate, CustNo, GLAccNo, MinPaymentAmount);

        // Setup
        AmountLessThanMin := LibraryRandom.RandDec(MinPaymentAmount - 1, 2);
        PostSalesInvoiceAndApplyPayment(CustNo, GLAccNo, AmountLessThanMin, CalcDate('<1Y>', ReferenceDate),
          AmountLessThanMin, CalcDate('<1Y>', ReferenceDate));
        PostSalesInvoiceAndApplyPayment(CustNo, GLAccNo, AmountLessThanMin, CalcDate('<2Y>', ReferenceDate),
          AmountLessThanMin, CalcDate('<2Y>', ReferenceDate));

        // Exercise
        asserterror Library340.RunMake340DeclarationReport(Date2DMY(CalcDate('<2Y>', ReferenceDate), 3),
            GLAccNo, Date2DMY(ReferenceDate, 2), MinPaymentAmount);

        // Verify
        Assert.ExpectedError(NoRecordsFoundError);

        // Tear-Down
        RemoveCustomerVATRegNo(CustNo);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure PaymentPostedAndAppliedToInvoicePostedLater()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        ExportedFileName: Text[1024];
        Line: Text[1024];
        PaymentDocNo: Code[20];
        ReferenceAmount: Decimal;
        Amount: Decimal;
        FirstPaymentAmount: Decimal;
        ReferenceDate: Date;
    begin
        // TFS300271 - http://vstfnav:8080/tfs/web/wi.aspx?id=300271
        Initialize();

        // Pre-Setup
        PreSetup(Customer, GLAccount, ReferenceAmount, Amount, FirstPaymentAmount, ReferenceDate);

        // Setup: Create and post a payment.
        GetGenJnlBatch(GenJournalBatch);
        PaymentDocNo := CreateGenJournal(GenJournalBatch, GenJournalLine, Customer."No.", GLAccount."No.",
            GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", -1 * Amount, ReferenceDate);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Setup: Create and post an invoice with payment applied.
        CreateGenJournal(GenJournalBatch, GenJournalLine, Customer."No.", GLAccount."No.",
          GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", Amount, CalcDate('<1M>', ReferenceDate));
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Payment);
        GenJournalLine.Validate("Applies-to Doc. No.", PaymentDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise
        ExportedFileName := Library340.RunMake340DeclarationReport(Date2DMY(ReferenceDate, 3),
            GLAccount."No.", Date2DMY(ReferenceDate, 2), Amount - LibraryRandom.RandDec(100, 2));

        // Post-Exercise
        Line := Library340.ReadCustomerLine(ExportedFileName, Customer.Name);

        // Verify
        VerifyCashCollectableValues(Line, Amount, Format(Date2DMY(ReferenceDate, 3)));

        // Tear-Down
        RemoveCustomerVATRegNo(Customer."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure PaymentsPostedOnDiffCashAccountsAndAppliedToSameInvoice()
    var
        Customer: Record Customer;
        GLAccount1: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        ExportedFileName: Text[1024];
        Line: Text[1024];
        InvoiceDocNo: Code[20];
        Amount: Decimal;
        ReferenceAmount: Decimal;
        FirstPaymentAmount: Decimal;
        ReferenceDate: Date;
    begin
        // TFS300268 - http://vstfnav:8080/tfs/web/wi.aspx?id=300268
        Initialize();

        // Pre-Setup
        PreSetup(Customer, GLAccount1, ReferenceAmount, Amount, FirstPaymentAmount, ReferenceDate);
        LibraryERM.CreateGLAccount(GLAccount2);

        // Setup: Create and apply two payments to an invoice.
        InvoiceDocNo := CreateAndPostInvoiceUsingJournal(Customer."No.", GLAccount1."No.", Amount,
            GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);
        ApplyAndPostPayment(InvoiceDocNo, Customer."No.", GLAccount1."No.", FirstPaymentAmount,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", CalcDate('<1Y>', ReferenceDate));
        ApplyAndPostPayment(InvoiceDocNo, Customer."No.", GLAccount2."No.", Amount - FirstPaymentAmount,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", CalcDate('<1Y>', ReferenceDate));

        // Exercise
        ExportedFileName := Library340.RunMake340DeclarationReport(Date2DMY(ReferenceDate, 3) + 1,
            GLAccount1."No.", Date2DMY(ReferenceDate, 2), ReferenceAmount);

        // Post-Exercise
        Line := Library340.ReadCustomerLine(ExportedFileName, Customer.Name);

        // Verify
        VerifyCashCollectableValues(Line, FirstPaymentAmount, Format(Date2DMY(ReferenceDate, 3)));

        // Tear-Down
        RemoveCustomerVATRegNo(Customer."No.");
    end;

    [Test]
    [HandlerFunctions('ModalPageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure PaymentFromCustomerAppliedToAnInvoiceWithBill()
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        ExportedFileName: Text[1024];
        Line: Text[1024];
        FiscalYear: Integer;
        Amount: Decimal;
        ReferenceAmount: Decimal;
        FirstPaymentAmount: Decimal;
        ReferenceDate: Date;
    begin
        // Verify payments from customer in current year applied to an invoice with bill.
        // TFS301746 - http://vstfnav:8080/tfs/web/wi.aspx?id=301746
        // Setup.
        Initialize();
        PreSetup(Customer, GLAccount, ReferenceAmount, Amount, FirstPaymentAmount, ReferenceDate);
        FiscalYear := Date2DMY(ReferenceDate, 3);
        PostAndApplyPaymentToAnInvoiceWithBill(GLAccount."No.", Customer."No.", Amount, ReferenceDate, ReferenceDate);

        // Exercise: Run report 'Make 340 Declaration'.
        ExportedFileName := Library340.RunMake340DeclarationReport(FiscalYear, GLAccount."No.",
            Date2DMY(ReferenceDate, 2), ReferenceAmount);

        // Verify: Verify exported file.
        Line := Library340.ReadNumericExerciseLine(ExportedFileName, Format(FiscalYear));
        VerifyCashCollectableValues(Line, Amount, Format(FiscalYear));

        // Tear-Down.
        RemoveCustomerVATRegNo(Customer."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure PaymentFromCustomerPostedWithBlankDocumentType()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        ExportedFileName: Text[1024];
        Line: Text[1024];
        InvoiceDocNo: Code[20];
        ReferenceAmount: Decimal;
        Amount: Decimal;
        FirstPaymentAmount: Decimal;
        ReferenceDate: Date;
    begin
        // TFS300257 - http://vstfnav:8080/tfs/web/wi.aspx?id=300257
        Initialize();

        // Pre-Setup
        PreSetup(Customer, GLAccount, ReferenceAmount, Amount, FirstPaymentAmount, ReferenceDate);

        // Setup
        InvoiceDocNo := CreateAndPostInvoiceUsingJournal(Customer."No.", GLAccount."No.", Amount,
            GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);

        // Setup: Create and post a payment with blank Document Type.
        GetGenJnlBatch(GenJournalBatch);
        CreateGenJournal(
            GenJournalBatch, GenJournalLine, Customer."No.", GLAccount."No.", "Gen. Journal Document Type"::" ",
            GenJournalLine."Account Type"::Customer,
            "General Posting Type"::" ", -1 * Amount, ReferenceDate);  // To create a payment line with <blank> Document Type.
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise
        ExportedFileName := Library340.RunMake340DeclarationReport(Date2DMY(ReferenceDate, 3), GLAccount."No.",
            Date2DMY(ReferenceDate, 2), Amount - LibraryRandom.RandDec(100, 2));

        // Post-Exercise
        Line := Library340.ReadCustomerLine(ExportedFileName, Customer.Name);

        // Verify
        VerifyCashCollectableValues(Line, Amount, Format(Date2DMY(ReferenceDate, 3)));

        // Tear-Down
        RemoveCustomerVATRegNo(Customer."No.");
    end;

    [Test]
    [HandlerFunctions('ModalPageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure PaymentFromCustomerPostedFromJournalInTwoLines()
    var
        GLAccount: Record "G/L Account";
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine1: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        InvoiceDocNo: Code[20];
        ExportedFileName: Text[1024];
        Line: Text[1024];
        ReferenceAmount: Decimal;
        MinimumAmount: Decimal;
        MaximumAmount: Decimal;
        ReferenceDate: Date;
    begin
        // TFS301390 - http://vstfnav:8080/tfs/web/wi.aspx?id=301390
        Initialize();

        // Pre-Setup
        PreSetup(Customer, GLAccount, ReferenceAmount, MaximumAmount, MinimumAmount, ReferenceDate);

        // Setup
        InvoiceDocNo := CreateAndPostInvoiceUsingJournal(Customer."No.", GLAccount."No.", MaximumAmount,
            GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);

        // Setup: Create payment from journal in two lines.
        GetGenJnlBatch(GenJournalBatch);
        CreateGenJournal(GenJournalBatch, GenJournalLine1, Customer."No.", '', GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", -1 * MaximumAmount, CalcDate('<1Y>', ReferenceDate));
        GenJournalLine1.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine1.Validate("Applies-to Doc. No.", InvoiceDocNo);
        GenJournalLine1.Modify(true);
        CreateGenJournal(GenJournalBatch, GenJournalLine2, GLAccount."No.", '', GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::"G/L Account", GenJournalLine."Gen. Posting Type"::Sale,
          MaximumAmount, CalcDate('<1Y>', ReferenceDate));
        GenJournalLine2.Validate("Bill-to/Pay-to No.", Customer."No.");
        GenJournalLine2.Validate("Sell-to/Buy-from No.", Customer."No.");
        GenJournalLine2.Modify(true);

        // Setup: Post the above two lines.
        GenJournalLine.SetRange("Document No.", GenJournalLine1."Document No.", GenJournalLine2."Document No.");
        GenJournalLine.FindFirst();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise
        ExportedFileName := Library340.RunMake340DeclarationReport(Date2DMY(ReferenceDate, 3) + 1, GLAccount."No.",
            Date2DMY(ReferenceDate, 2), MaximumAmount - LibraryRandom.RandDec(100, 2));

        // Post-Exercise
        Line := Library340.ReadYearLine(ExportedFileName, PadStr('', 4, '0')); // Payment line exports Year as 0000.

        // Verify
        VerifyCashCollectableValues(Line, MaximumAmount, Format(Date2DMY(ReferenceDate, 3)));

        // Tear-Down
        RemoveCustomerVATRegNo(Customer."No.");
    end;

    [Test]
    [HandlerFunctions('ModalPageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure PaymentFromCustomerWithBalancingAccountDefinedInPaymentMethod()
    var
        Customer: Record Customer;
        GLAccount1: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        ExportedFileName: Text[1024];
        Line: Text[1024];
        FirstPaymentAmount: Decimal;
        ReferenceAmount: Decimal;
        Amount: Decimal;
        AmountInclVAT: Decimal;
        ReferenceDate: Date;
    begin
        // TFS301345 - http://vstfnav:8080/tfs/web/wi.aspx?id=301345
        Initialize();

        // Pre-Setup
        PreSetup(Customer, GLAccount1, ReferenceAmount, Amount, FirstPaymentAmount, ReferenceDate);
        FindGLAccount(GLAccount2);

        // Setup
        UpdatePaymentMethod(Customer."Payment Method Code", GLAccount2."No.");
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", ReferenceDate, '', Amount);
        SalesHeader.CalcFields("Amount Including VAT");
        AmountInclVAT := SalesHeader."Amount Including VAT";
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise
        ExportedFileName := Library340.RunMake340DeclarationReport(Date2DMY(ReferenceDate, 3), GLAccount2."No.",
            Date2DMY(ReferenceDate, 2), Amount - LibraryRandom.RandDec(100, 2));

        // Post-Exercise
        Line := Library340.ReadNumericExerciseLine(ExportedFileName, Format(Date2DMY(ReferenceDate, 3)));

        // Verify
        VerifyCashCollectableValues(Line, AmountInclVAT, Format(Date2DMY(ReferenceDate, 3)));

        // Tear-Down
        RemoveCustomerVATRegNo(Customer."No.");
        UpdatePaymentMethod(Customer."Payment Method Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentFromVendor()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        InvoiceDocNo: Code[20];
        VendorNo: Code[20];
        Amount: Decimal;
        ReferenceAmount: Decimal;
        ReferenceDate: Date;
        FiscalYear: Integer;
    begin
        // TFS298664 - http://vstfnav:8080/tfs/web/wi.aspx?id=298664.
        Initialize();

        // Pre-Setup
        ReferenceAmount := 1000 * LibraryRandom.RandInt(10);
        Amount := LibraryRandom.RandIntInRange(ReferenceAmount + 1000, ReferenceAmount + 2000);
        ReferenceDate := GetBasisOfCalcForPostingDate();
        FiscalYear := Date2DMY(ReferenceDate, 3);

        // Setup
        VendorNo := CreateVendor();
        LibraryERM.FindGLAccount(GLAccount);
        InvoiceDocNo := CreateAndPostInvoiceUsingJournal(VendorNo, GLAccount."No.", -1 * Amount,
            GenJournalLine."Account Type"::Vendor, "General Posting Type"::" ", ReferenceDate);
        ApplyAndPostPayment(InvoiceDocNo, VendorNo, GLAccount."No.", -1 * Amount,
          GenJournalLine."Account Type"::Vendor, "General Posting Type"::" ", CalcDate('<1Y>', ReferenceDate));

        // Exercise
        asserterror Library340.RunMake340DeclarationReport(FiscalYear + 1, GLAccount."No.", Date2DMY(ReferenceDate, 2), ReferenceAmount);

        // Verify
        Assert.ExpectedError(NoRecordsFoundError);

        // Tear-Down
        RemoveVendorVATRegNo(VendorNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentFromCustomerFullyAppliedOnGLAccNotEqualToCashAccount()
    begin
        // TFS298675 - http://vstfnav:8080/tfs/web/wi.aspx?id=298675.
        GLAccountsOnRequestPage(CreateGLAccount());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentFromCustomerInCurrentYearFullyAppliedButGLAccountIsBlank()
    begin
        // TFS 298665- http://vstfnav:8080/tfs/web/wi.aspx?id=298665.
        GLAccountsOnRequestPage('');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentFromCustomerInPreviousYear()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        InvoiceDocNo: Code[20];
        Amount: Decimal;
        ReferenceAmount: Decimal;
        FirstPaymentAmount: Decimal;
        ReferenceDate: Date;
        FiscalYear: Integer;
    begin
        // TFS298680 - http://vstfnav:8080/tfs/web/wi.aspx?id=298680.
        Initialize();

        // Pre-Setup
        PreSetup(Customer, GLAccount, ReferenceAmount, Amount, FirstPaymentAmount, ReferenceDate);
        FiscalYear := Date2DMY(ReferenceDate, 3);

        // Setup
        InvoiceDocNo := CreateAndPostInvoiceUsingJournal(Customer."No.", GLAccount."No.", Amount,
            GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);
        ApplyAndPostPayment(InvoiceDocNo, Customer."No.", GLAccount."No.", Amount,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);

        // Exercise
        asserterror Library340.RunMake340DeclarationReport(FiscalYear + 1, GLAccount."No.",
            Date2DMY(ReferenceDate, 2), ReferenceAmount);

        // Verify
        Assert.ExpectedError(NoRecordsFoundError);

        // Tear-Down
        RemoveCustomerVATRegNo(Customer."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure PartialPaymentFromCustomerInCurrentYear()
    var
        Amount: Decimal;
        ReferenceAmount: Decimal;
        PartialPaymentAmount: Decimal;
    begin
        // TFS298712 - http://vstfnav:8080/tfs/web/wi.aspx?id=298712.
        ReferenceAmount := 1000 * LibraryRandom.RandInt(10);
        Amount := LibraryRandom.RandIntInRange(ReferenceAmount + 1000, ReferenceAmount + 2000);
        PartialPaymentAmount := LibraryRandom.RandIntInRange(ReferenceAmount, Amount);
        PaymentFromCustomerInCurrentYear(Amount, PartialPaymentAmount, ReferenceAmount, PartialPaymentAmount);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure PaymentFromCustomerInCurrentYearFullyAppliedOnCashAccount()
    var
        Amount: Decimal;
        ReferenceAmount: Decimal;
    begin
        // TFS298684 - http://vstfnav:8080/tfs/web/wi.aspx?id=298684.
        ReferenceAmount := 1000 * LibraryRandom.RandInt(10);
        Amount := LibraryRandom.RandIntInRange(ReferenceAmount + 1000, ReferenceAmount + 2000);
        PaymentFromCustomerInCurrentYear(Amount, Amount, ReferenceAmount, Amount);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure PaymentWhenAmountIsEqualToMinPaymentAmount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        ExportedFileName: Text[1024];
        Line: Text[1024];
        InvoiceDocNo: Code[20];
        Amount: Decimal;
        ReferenceAmount: Decimal;
        FirstPaymentAmount: Decimal;
        ReferenceDate: Date;
        FiscalYear: Integer;
    begin
        // TFS298683 - http://vstfnav:8080/tfs/web/wi.aspx?id=298683.
        Initialize();

        // Pre-Setup
        PreSetup(Customer, GLAccount, ReferenceAmount, Amount, FirstPaymentAmount, ReferenceDate);
        FiscalYear := Date2DMY(ReferenceDate, 3);

        // Setup
        InvoiceDocNo := CreateAndPostInvoiceUsingJournal(Customer."No.", GLAccount."No.", Amount,
            GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);
        ApplyAndPostPayment(InvoiceDocNo, Customer."No.", GLAccount."No.", Amount,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);

        // Exercise
        ExportedFileName := Library340.RunMake340DeclarationReport(FiscalYear, GLAccount."No.",
            Date2DMY(ReferenceDate, 2), Amount);  // Amount is equals to threshold.

        // Post-Exercise
        Line := Library340.ReadCustomerLine(ExportedFileName, Customer.Name);

        // Verify
        VerifyCashCollectableValues(Line, Amount, Format(FiscalYear));

        // Tear-Down
        RemoveCustomerVATRegNo(Customer."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure PaymentFromCustomerInCurrentYearFullyAppliedOnTwoInvoices()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        ExportedFileName: Text[1024];
        Line: Text[1024];
        InvoiceDocNo1: Code[20];
        InvoiceDocNo2: Code[20];
        Amount: Decimal;
        ReferenceAmount: Decimal;
        FirstPaymentAmount: Decimal;
        ReferenceDate: Date;
        FiscalYear: Integer;
    begin
        // TFS298707 - http://vstfnav:8080/tfs/web/wi.aspx?id=298707.
        Initialize();

        // Pre-Setup
        PreSetup(Customer, GLAccount, ReferenceAmount, Amount, FirstPaymentAmount, ReferenceDate);
        FiscalYear := Date2DMY(ReferenceDate, 3);

        // Setup
        InvoiceDocNo1 := CreateAndPostInvoiceUsingJournal(Customer."No.", GLAccount."No.", Amount,
            GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);
        InvoiceDocNo2 := CreateAndPostInvoiceUsingJournal(Customer."No.", GLAccount."No.", FirstPaymentAmount,
            GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);

        ApplyAndPostPayment(InvoiceDocNo1, Customer."No.", GLAccount."No.", Amount,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);
        ApplyAndPostPayment(InvoiceDocNo2, Customer."No.", GLAccount."No.", FirstPaymentAmount,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);

        // Exercise
        ExportedFileName := Library340.RunMake340DeclarationReport(FiscalYear, GLAccount."No.",
            Date2DMY(ReferenceDate, 2), ReferenceAmount);

        // Post-Exercise
        Line := Library340.ReadCustomerLine(ExportedFileName, Customer.Name);

        // Verify
        VerifyCashCollectableValues(Line, Amount + FirstPaymentAmount, Format(FiscalYear));

        // Tear-Down
        RemoveCustomerVATRegNo(Customer."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure PaymentFromCustomerUnapplyAndReapply()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ExportedFileName: Text[1024];
        Line: Text[1024];
        InvoiceDocNo1: Code[20];
        InvoiceDocNo2: Code[20];
        Amount: Decimal;
        ReferenceAmount: Decimal;
        FirstPaymentAmount: Decimal;
        ReferenceDate: Date;
        FiscalYear: Integer;
    begin
        // TFS300237 - http://vstfnav:8080/tfs/web/wi.aspx?id=300237.
        Initialize();

        // Pre-Setup
        PreSetup(Customer, GLAccount, ReferenceAmount, Amount, FirstPaymentAmount, ReferenceDate);
        FiscalYear := Date2DMY(ReferenceDate, 3);

        // Setup
        InvoiceDocNo1 := CreateAndPostInvoiceUsingJournal(Customer."No.", GLAccount."No.", Amount,
            GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);
        InvoiceDocNo2 := CreateAndPostInvoiceUsingJournal(Customer."No.", GLAccount."No.", FirstPaymentAmount,
            GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", CalcDate('<1M>', ReferenceDate));

        ApplyAndPostPayment(InvoiceDocNo1, Customer."No.", GLAccount."No.", Amount, GenJournalLine."Account Type"::Customer,
          "General Posting Type"::" ", CalcDate('<1Y>', ReferenceDate));
        ApplyAndPostPayment(InvoiceDocNo2, Customer."No.", GLAccount."No.", FirstPaymentAmount, GenJournalLine."Account Type"::Customer,
          "General Posting Type"::" ", CalcDate('<2Y>', ReferenceDate));

        UnapplyCustomerLedgerEntry(CustLedgerEntry, Customer."No.", CalcDate('<1Y>', ReferenceDate));
        ApplyCustomerEntries(Customer."No.");

        // Exercise
        ExportedFileName := Library340.RunMake340DeclarationReport(FiscalYear + 2, GLAccount."No.",
            Date2DMY(ReferenceDate, 2), ReferenceAmount);

        // Post-Exercise
        Line := Library340.ReadCustomerLine(ExportedFileName, Customer.Name);

        // Verify
        VerifyCashCollectableValues(Line, Amount + FirstPaymentAmount, Format(FiscalYear));

        // Tear-Down
        RemoveCustomerVATRegNo(Customer."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure PostMultiplePartialPaymentWhenAmountIsGreaterThanThreshold()
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        ExportedFileName: Text[1024];
        Line: Text[1024];
        FiscalYear: Integer;
        MaximumAmount: Decimal;
        MinimumAmount: Decimal;
        SecondPaymentAmount: Decimal;
        ReferenceDate: Date;
        PaymentPostingDate: Date;
    begin
        // Verify two payments received from customer in the reporting year with amount > Min Payment Amount and applied to an invoice posted in the reporting year.
        // TFS298772 - http://vstfnav:8080/tfs/weGLAccount."No."b/wi.aspx?id=298772
        // Setup.
        Initialize();
        PreSetup(Customer, GLAccount, SecondPaymentAmount, MaximumAmount, MinimumAmount, ReferenceDate);
        PaymentPostingDate := CalcDate('<2M>', ReferenceDate);
        FiscalYear := Date2DMY(ReferenceDate, 3);
        PostMultiplePartialPayments(Customer."No.", GLAccount."No.", MaximumAmount, MinimumAmount, SecondPaymentAmount,
          ReferenceDate, PaymentPostingDate);

        // Exercise: Run report 'Make 340 Declaration'.
        ExportedFileName := Library340.RunMake340DeclarationReport(FiscalYear, GLAccount."No.", Date2DMY(ReferenceDate, 2),
            MinimumAmount - LibraryRandom.RandDec(100, 2));

        // Post - Excercise.
        Line := Library340.ReadCustomerLine(ExportedFileName, Customer.Name);

        // Verify the exported file.
        VerifyCashCollectableValues(Line, MinimumAmount, Format(FiscalYear));

        // Tear-Down.
        RemoveCustomerVATRegNo(Customer."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure PostMultiplePaymentInDifferentMonthWhenAmountIsGreaterThanThreshold()
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        ExportedFileName: Text[1024];
        Line: Text[1024];
        FiscalYear: Integer;
        MaximumAmount: Decimal;
        MinimumAmount: Decimal;
        SecondPaymentAmount: Decimal;
        ReferenceDate: Date;
        PaymentPostingDate: Date;
    begin
        // Verify two payments received from customer in the reporting year with amount > Min Payment Amount and applied to an invoice posted in the reporting year.
        // TFS298772 - http://vstfnav:8080/tfs/web/wi.aspx?id=298772
        // Setup.
        Initialize();
        PreSetup(Customer, GLAccount, SecondPaymentAmount, MaximumAmount, MinimumAmount, ReferenceDate);
        PaymentPostingDate := CalcDate('<2M>', ReferenceDate);
        FiscalYear := Date2DMY(PaymentPostingDate, 3);
        PostMultiplePartialPayments(Customer."No.", GLAccount."No.", MaximumAmount, MinimumAmount, SecondPaymentAmount,
          ReferenceDate, PaymentPostingDate);

        // Exercise: Run report 'Make 340 Declaration'.
        ExportedFileName := Library340.RunMake340DeclarationReport(FiscalYear, GLAccount."No.", Date2DMY(PaymentPostingDate, 2),
            SecondPaymentAmount - LibraryRandom.RandDec(100, 2));

        // Post - Excercise.
        Line := Library340.ReadCustomerLine(ExportedFileName, Customer.Name);

        // Verify the exported file.
        VerifyCashCollectableValues(Line, MaximumAmount, Format(FiscalYear));

        // Tear-Down.
        RemoveCustomerVATRegNo(Customer."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure PostMultiplePaymentsForTwoCashAccounts()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount1: Record "G/L Account";
        GLAccount2: Record "G/L Account";
        ExportedFileName: Text[1024];
        Line: Text[1024];
        InvoiceDocNo: Code[20];
        FiscalYear: Integer;
        MinimumAmount: Decimal;
        MaximumAmount: Decimal;
        SecondPaymentAmount: Decimal;
        ReferenceDate: Date;
        PaymentPostingDate: Date;
    begin
        // Verify two payments received from customer for two cash accounts with amount > Min Payment Amount but only one account is selected.
        // TFS298773- http://vstfnav:8080/tfs/web/wi.aspx?id=298773
        // Setup.
        Initialize();
        PreSetup(Customer, GLAccount1, SecondPaymentAmount, MaximumAmount, MinimumAmount, ReferenceDate);
        PaymentPostingDate := CalcDate('<1M>', ReferenceDate);
        FiscalYear := Date2DMY(PaymentPostingDate, 3);
        LibraryERM.CreateGLAccount(GLAccount2);
        InvoiceDocNo := CreateAndPostInvoiceUsingJournal(Customer."No.", GLAccount1."No.",
            MaximumAmount, GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);

        // Pre - Excercise.
        ApplyAndPostPayment(InvoiceDocNo, Customer."No.", GLAccount1."No.", MinimumAmount,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", PaymentPostingDate);
        ApplyAndPostPayment(InvoiceDocNo, Customer."No.", GLAccount2."No.", MaximumAmount - MinimumAmount,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", CalcDate('<2M>', ReferenceDate));

        // Exercise: Run report 'Make 340 Declaration' For first Payment.
        ExportedFileName := Library340.RunMake340DeclarationReport(FiscalYear, GLAccount1."No.",
            Date2DMY(PaymentPostingDate, 2), MinimumAmount - LibraryRandom.RandDec(2000, 2));

        // Post - Excercise.
        Line := Library340.ReadCustomerLine(ExportedFileName, Customer.Name);

        // Verify the exported file.
        VerifyCashCollectableValues(Line, MinimumAmount, Format(FiscalYear));

        // Tear-Down.
        RemoveCustomerVATRegNo(Customer."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure PostPartialPaymentFromCustomerInCurrentYear()
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        ExportedFileName: Text[1024];
        Line: Text[1024];
        FiscalYear: Integer;
        MaximumAmount: Decimal;
        MinimumAmount: Decimal;
        SecondPaymentAmount: Decimal;
        ReferenceDate: Date;
        PaymentPostingDate: Date;
    begin
        // Verify partial payment received from customer in current year up to specified month and applied payment amount > Min Payment Amount.
        // TFS298761 - http://vstfnav:8080/tfs/web/wi.aspx?id=298761.
        // Setup.
        Initialize();

        PreSetup(Customer, GLAccount, SecondPaymentAmount, MaximumAmount, MinimumAmount, ReferenceDate);

        PaymentPostingDate := CalcDate('<1M>', ReferenceDate);
        FiscalYear := Date2DMY(PaymentPostingDate, 3);
        PostSalesInvoiceAndAppliedPayment(Customer."No.", GLAccount."No.", MinimumAmount, MaximumAmount,
          ReferenceDate, PaymentPostingDate);

        // Exercise: Run report 'Make 340 Declaration'.
        ExportedFileName := Library340.RunMake340DeclarationReport(FiscalYear, GLAccount."No.",
            Date2DMY(PaymentPostingDate, 2), MinimumAmount - LibraryRandom.RandDec(1000, 2));

        // Post - Excercise.
        Line := Library340.ReadCustomerLine(ExportedFileName, Customer.Name);

        // Verify the exported file.
        VerifyCashCollectableValues(Line, MinimumAmount, Format(FiscalYear));

        // Tear-Down.
        RemoveCustomerVATRegNo(Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialPaymentWhenPaymentAmountIsLessThanThreshold()
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        ExportedFileName: Text[1024];
        FiscalYear: Integer;
        MinimumAmount: Decimal;
        MaximumAmount: Decimal;
        SecondPaymentAmount: Decimal;
        ReferenceDate: Date;
        PaymentPostingDate: Date;
    begin
        // Verify partial payment received from customer in current year up to specified month and applied payment amount < Min Payment Amount.
        // TFS298763 - http://vstfnav:8080/tfs/web/wi.aspx?id=298763
        // Setup.
        Initialize();
        PreSetup(Customer, GLAccount, SecondPaymentAmount, MaximumAmount, MinimumAmount, ReferenceDate);
        PaymentPostingDate := CalcDate('<1M>', ReferenceDate);
        FiscalYear := Date2DMY(PaymentPostingDate, 3);

        // Pre - Excercise.
        PostSalesInvoiceAndAppliedPayment(Customer."No.", GLAccount."No.", MinimumAmount, MaximumAmount,
          ReferenceDate, PaymentPostingDate);

        // Exercise: Run report 'Make 340 Declaration'.
        asserterror ExportedFileName := Library340.RunMake340DeclarationReport(FiscalYear, GLAccount."No.",
              Date2DMY(PaymentPostingDate, 2), MaximumAmount);

        // Verify: Verify the error.
        Assert.ExpectedError(NoRecordsFoundError);

        // Tear-Down.
        RemoveCustomerVATRegNo(Customer."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure PostPartialPaymentWhenAmountIsEqualToThreshold()
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        ExportedFileName: Text[1024];
        Line: Text[1024];
        FiscalYear: Integer;
        MinimumAmount: Decimal;
        MaximumAmount: Decimal;
        SecondPaymentAmount: Decimal;
        ReferenceDate: Date;
        PaymentPostingDate: Date;
    begin
        // Verify partial payment received from customer in current year up to specified month and applied payment amount = Min Payment Amount.
        // TFS298764 - http://vstfnav:8080/tfs/web/wi.aspx?id=298764
        // Setup.
        Initialize();

        PreSetup(Customer, GLAccount, SecondPaymentAmount, MaximumAmount, MinimumAmount, ReferenceDate);
        PaymentPostingDate := CalcDate('<1M>', ReferenceDate);
        FiscalYear := Date2DMY(PaymentPostingDate, 3);

        // Pre - Excercise.
        PostSalesInvoiceAndAppliedPayment(Customer."No.", GLAccount."No.", MinimumAmount, MaximumAmount,
          ReferenceDate, PaymentPostingDate);

        // Exercise: Run report 'Make 340 Declaration'.
        ExportedFileName := Library340.RunMake340DeclarationReport(FiscalYear, GLAccount."No.",
            Date2DMY(PaymentPostingDate, 2), MinimumAmount);

        // Post - Excercise.
        Line := Library340.ReadCustomerLine(ExportedFileName, Customer.Name);

        // Verify the exported file.
        VerifyCashCollectableValues(Line, MinimumAmount, Format(FiscalYear));

        // Tear-Down.
        RemoveCustomerVATRegNo(Customer."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure PostPartialPaymentWhenAmountIsGreaterThanThresholdAppliedToTwoInvoices()
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        ExportedFileName: Text[1024];
        Line: Text[1024];
        FiscalYear: Integer;
        MinimumAmount: Decimal;
        MaximumAmount: Decimal;
        SecondPaymentAmount: Decimal;
        ReferenceDate: Date;
        PaymentPostingDate: Date;
    begin
        // Verify partial payment received from customer with amount > Min Payment Amount received in current year up to specified month and partially applied to 2 invoices in same year.
        // TFS298765 - http://vstfnav:8080/tfs/web/wi.aspx?id=298765
        // Setup.
        Initialize();
        PreSetup(Customer, GLAccount, SecondPaymentAmount, MaximumAmount, MinimumAmount, ReferenceDate);
        PaymentPostingDate := CalcDate('<2M>', ReferenceDate);
        FiscalYear := Date2DMY(PaymentPostingDate, 3);

        // Pre - Excercise.
        PostTwoSalesInvoicesAndAppliedPayments(Customer."No.", GLAccount."No.", MinimumAmount, MaximumAmount,
          ReferenceDate, PaymentPostingDate);

        // Exercise: Run report 'Make 340 Declaration'.
        ExportedFileName := Library340.RunMake340DeclarationReport(FiscalYear, GLAccount."No.", Date2DMY(PaymentPostingDate, 2),
            MinimumAmount - LibraryRandom.RandDec(1000, 2));

        // Post - Excercise.
        Line := Library340.ReadCustomerLine(ExportedFileName, Customer.Name);

        // Verify the exported file.
        VerifyCashCollectableValues(Line, 2 * MinimumAmount, Format(FiscalYear));

        // Tear-Down.
        RemoveCustomerVATRegNo(Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostPartialPaymentWhenAmountIsLessThanThresholdAppliedToTwoInvoices()
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        ExportedFileName: Text[1024];
        FiscalYear: Integer;
        MinimumAmount: Decimal;
        MaximumAmount: Decimal;
        SecondPaymentAmount: Decimal;
        ReferenceDate: Date;
        PaymentPostingDate: Date;
    begin
        // Verify partial payment received from customer with amount < Min Payment Amount received in current year up to specified month and partially applied to 2 invoices in same year.
        // TFS298766 - http://vstfnav:8080/tfs/web/wi.aspx?id=298766
        // Setup.
        Initialize();
        PreSetup(Customer, GLAccount, SecondPaymentAmount, MaximumAmount, MinimumAmount, ReferenceDate);
        PaymentPostingDate := CalcDate('<2M>', ReferenceDate);
        FiscalYear := Date2DMY(PaymentPostingDate, 3);

        // Pre - Excercise.
        PostTwoSalesInvoicesAndAppliedPayments(Customer."No.", GLAccount."No.", MinimumAmount, MaximumAmount,
          ReferenceDate, PaymentPostingDate);

        // Exercise: Run report 'Make 340 Declaration'.
        asserterror ExportedFileName := Library340.RunMake340DeclarationReport(FiscalYear, GLAccount."No.",
              Date2DMY(PaymentPostingDate, 2), 2 * MaximumAmount);

        // Verify: Verify the error.
        Assert.ExpectedError(NoRecordsFoundError);

        // Tear-Down.
        RemoveCustomerVATRegNo(Customer."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure PostPartialPaymentWhenAmountIsEqualToThresholdAppliedToTwoInvoices()
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        ExportedFileName: Text[1024];
        Line: Text[1024];
        FiscalYear: Integer;
        MinimumAmount: Decimal;
        MaximumAmount: Decimal;
        SecondPaymentAmount: Decimal;
        ReferenceDate: Date;
        PaymentPostingDate: Date;
    begin
        // Verify partial payment received from customer in current year up to specified month and applied payment amount = Min Payment Amount.
        // TFS298769 - http://vstfnav:8080/tfs/web/wi.aspx?id=298769
        // Setup.
        Initialize();
        PreSetup(Customer, GLAccount, SecondPaymentAmount, MaximumAmount, MinimumAmount, ReferenceDate);
        PaymentPostingDate := CalcDate('<2M>', ReferenceDate);
        FiscalYear := Date2DMY(PaymentPostingDate, 3);

        // Pre - Excercise.
        PostTwoSalesInvoicesAndAppliedPayments(Customer."No.", GLAccount."No.", MinimumAmount, MaximumAmount,
          ReferenceDate, PaymentPostingDate);

        // Exercise: Run report 'Make 340 Declaration'.
        ExportedFileName := Library340.RunMake340DeclarationReport(FiscalYear, GLAccount."No.",
            Date2DMY(PaymentPostingDate, 2), 2 * MinimumAmount);

        // Post - Excercise.
        Line := Library340.ReadCustomerLine(ExportedFileName, Customer.Name);

        // Verify the exported file.
        VerifyCashCollectableValues(Line, 2 * MinimumAmount, Format(FiscalYear));

        // Tear-Down.
        RemoveCustomerVATRegNo(Customer."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure PartialPaymentAppliedToTwoInvoicesPostedInDifferentYear()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GLAccount: Record "G/L Account";
        ExportedFileName: Text[1024];
        Line1: Text[1024];
        Line2: Text[1024];
        InvoiceDocNo1: Code[20];
        InvoiceDocNo2: Code[20];
        FiscalYear1: Integer;
        MinimumAmount: Decimal;
        MaximumAmount: Decimal;
        SecondPaymentAmount: Decimal;
        ReferenceDate: Date;
    begin
        // Verify payments received from customer with amount > Min Payment Amount, received in current year upto the specified month, partially applied to 2 invoices in different year.
        // TFS298770 - http://vstfnav:8080/tfs/web/wi.aspx?id=298770
        // Setup.
        Initialize();
        PreSetup(Customer, GLAccount, SecondPaymentAmount, MaximumAmount, MinimumAmount, ReferenceDate);
        FiscalYear1 := Date2DMY(ReferenceDate, 3);
        InvoiceDocNo1 := CreateAndPostInvoiceUsingJournal(Customer."No.", GLAccount."No.",
            MaximumAmount, GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);
        InvoiceDocNo2 := CreateAndPostInvoiceUsingJournal(Customer."No.", GLAccount."No.",
            MaximumAmount, GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", CalcDate('<1Y>', ReferenceDate));

        // Pre - Excercise.
        ApplyAndPostPayment(InvoiceDocNo1, Customer."No.", GLAccount."No.", MinimumAmount,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", CalcDate('<1Y>', ReferenceDate));
        ApplyAndPostPayment(InvoiceDocNo2, Customer."No.", GLAccount."No.", MinimumAmount,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", CalcDate('<1Y>', ReferenceDate));

        // Exercise: Run report 'Make 340 Declaration'.
        ExportedFileName := Library340.RunMake340DeclarationReport(FiscalYear1 + 1, GLAccount."No.",
            Date2DMY(ReferenceDate, 2), MinimumAmount - LibraryRandom.RandDec(100, 2));

        // Post - Excercise.
        Line1 := Library340.ReadCustomerLine(ExportedFileName, Customer.Name);

        // Verify the exported file.
        VerifyCashCollectableValues(Line1, MinimumAmount, Format(FiscalYear1));

        // Verify second line in the exported file.
        Line2 := ReadNumericExcerciseLine(ExportedFileName, Format(FiscalYear1 + 1));

        // Verify the exported file.
        VerifyCashCollectableValues(Line2, MinimumAmount, Format(FiscalYear1 + 1));

        // Tear-Down.
        RemoveCustomerVATRegNo(Customer."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure PostSalesInvoiceWithAppliedPartialPayment()
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        ExportedFileName: Text[1024];
        Line: Text[1024];
        FiscalYear: Integer;
        MinimumAmount: Decimal;
        MaximumAmount: Decimal;
        SecondPaymentAmount: Decimal;
        ReferenceDate: Date;
        PaymentPostingDate: Date;
        InvoicePostingDate: Date;
    begin
        // Verify payment received from customer ,received in current year upto the specified month, applied to invoice in same year but in different month.
        // TFS298771 - http://vstfnav:8080/tfs/web/wi.aspx?id=298771
        // Setup.
        Initialize();
        PreSetup(Customer, GLAccount, SecondPaymentAmount, MaximumAmount, MinimumAmount, ReferenceDate);
        PaymentPostingDate := CalcDate('<1M>', ReferenceDate);
        InvoicePostingDate := CalcDate('<2M>', ReferenceDate);
        FiscalYear := Date2DMY(PaymentPostingDate, 3);
        PostMultipleSalesInvoicesAndApplyPayment(Customer."No.", GLAccount."No.", MaximumAmount,
          ReferenceDate, PaymentPostingDate, InvoicePostingDate);

        // Exercise: Run report 'Make 340 Declaration'.
        ExportedFileName := Library340.RunMake340DeclarationReport(FiscalYear, GLAccount."No.",
            Date2DMY(PaymentPostingDate, 2), MinimumAmount);

        // Post - Excercise.
        Line := Library340.ReadCustomerLine(ExportedFileName, Customer.Name);

        // Verify the exported file.
        VerifyCashCollectableValues(Line, MaximumAmount, Format(FiscalYear));

        // Tear-Down.
        RemoveCustomerVATRegNo(Customer."No.");
    end;

    [Test]
    [HandlerFunctions('ModalPageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure PostTwoInvoicesWithBillAndApplyPaymentToASingleInvoice()
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        ExportedFileName: Text[1024];
        Line: Text[1024];
        FiscalYear: Integer;
        Amount: Decimal;
        ReferenceAmount: Decimal;
        FirstPaymentAmount: Decimal;
        ReferenceDate: Date;
    begin
        // Verify payments from customer in current year applied to an invoice with bill also having an unpiad invoice in same year.
        // TFS301802 - http://vstfnav:8080/tfs/web/wi.aspx?id=301802
        // Setup.
        Initialize();
        PreSetup(Customer, GLAccount, ReferenceAmount, Amount, FirstPaymentAmount, ReferenceDate);
        FiscalYear := Date2DMY(ReferenceDate, 3);
        PostAndApplyPaymentToAnInvoiceWithBill(GLAccount."No.", Customer."No.", Amount, ReferenceDate, ReferenceDate);

        // Create and post another invoice in same year.
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", ReferenceDate, '', Amount);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise: Run report 'Make 340 Declaration'.
        ExportedFileName := Library340.RunMake340DeclarationReport(FiscalYear, GLAccount."No.",
            Date2DMY(ReferenceDate, 2), ReferenceAmount);

        // Verify: Verify exported file.
        Line := Library340.ReadNumericExerciseLine(ExportedFileName, Format(FiscalYear));
        VerifyCashCollectableValues(Line, Amount, Format(FiscalYear));

        // Tear-Down.
        RemoveCustomerVATRegNo(Customer."No.");
    end;

    [Test]
    [HandlerFunctions('ModalPageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure PurchInvoicePropertyTax()
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        OperationCode: Record "Operation Code";
        PurchHeader: Record "Purchase Header";
        Vend: Record Vendor;
        Item: Record Item;
        ActualNumericExercise: Text[4];
        FileName: Text[1024];
        FiscalYear: Integer;
        InvoiceNo: Code[20];
        Line: Text[1024];
        ReferenceDate: Date;
    begin
        Initialize();

        // Pre-Setup
        ReferenceDate := GetBasisOfCalcForPostingDate();
        FiscalYear := Date2DMY(ReferenceDate, 3);

        // Setup
        Library340.CreateOperationCode(OperationCode, GetValidCharacter());
        FindItemWithOperationCode(Item, OperationCode.Code);

        Library340.CreateVendorVATRegistration(Vend);
        CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, Vend."No.", ReferenceDate);
        AddPurchaseLineWithVATandEC(PurchHeader, Item, LibraryRandom.RandDec(99, 2), LibraryRandom.RandDec(99, 2));
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // Exercise
        FileName := Library340.RunMake340DeclarationReport(FiscalYear, '', Date2DMY(ReferenceDate, 2), 0.0);

        // Post-Exercise
        Line := Library340.ReadVendorLine(FileName, Vend.Name);

        // Verify
        VerifyPropertyTaxLine(Line, OperationCode.Code, ' ', '', false);

        ActualNumericExercise := Library340.ReadNumericExercise(Line);
        Assert.AreEqual(Format(NumericExerciseBlank), ActualNumericExercise, IncorrectNumericExercise);

        // TearDown
        RemoveVendorVATRegNo(Vend."No.");
        GenProductPostingGroup.Get(Item."Gen. Prod. Posting Group");
        UnmapAndDeleteOperationCode(OperationCode, GenProductPostingGroup);
    end;

    [Test]
    [HandlerFunctions('ModalPageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure PurchCreditMemoPrPGroupMapped()
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        PurchaseLine: Record "Purchase Line";
        PurchHeader: Record "Purchase Header";
        Item: Record Item;
        OperationCode: Record "Operation Code";
        Vendor: Record Vendor;
        OperationCodeReport: Code[1];
        InvoiceNo: Code[20];
        FileName: Text[1024];
        ReferenceDate: Date;
        FiscalYear: Integer;
    begin
        Initialize();

        // Pre-Setup
        ReferenceDate := GetBasisOfCalcForPostingDate();
        FiscalYear := Date2DMY(ReferenceDate, 3);

        // Setup
        Library340.CreateOperationCode(OperationCode, GetValidCharacter());
        FindItemWithOperationCode(Item, OperationCode.Code);

        Library340.CreateVendorVATRegistration(Vendor);
        CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::"Credit Memo", Vendor."No.", ReferenceDate);
        PurchHeader.Validate("Vendor Cr. Memo No.", PurchHeader."No.");
        PurchHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchHeader, PurchaseLine.Type::Item, Item."No.",
          LibraryRandom.RandInt(10));
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // Exercise
        FileName := Library340.RunMake340DeclarationReport(FiscalYear, '', Date2DMY(ReferenceDate, 2), 0.0);
        OperationCodeReport := Library340.ReadOperationalCodeFromFile(FileName, InvoiceNo, CreditMemoStartingPosition,
            1, OperationCodeStartingPosition, 1);

        // Verify
        Assert.AreEqual(OperationCodeD, OperationCodeReport, IncorrectOperationCode);

        // TearDown
        RemoveVendorVATRegNo(Vendor."No.");
        GenProductPostingGroup.Get(Item."Gen. Prod. Posting Group");
        UnmapAndDeleteOperationCode(OperationCode, GenProductPostingGroup);
    end;

    [Test]
    [HandlerFunctions('ModalPageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure PurchOrderProdPostGroupMapped()
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        Item: Record Item;
        OperationCode: Record "Operation Code";
        PurchHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        OperationCodeReport: Code[1];
        InvoiceNo: Code[20];
        FileName: Text[1024];
        FiscalYear: Integer;
        ReferenceDate: Date;
    begin
        Initialize();

        // Pre-Setup
        ReferenceDate := GetBasisOfCalcForPostingDate();
        FiscalYear := Date2DMY(ReferenceDate, 3);

        // Setup
        Library340.CreateOperationCode(OperationCode, GetValidCharacter());
        FindItemWithOperationCode(Item, OperationCode.Code);

        Library340.CreateVendorVATRegistration(Vendor);

        CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, Vendor."No.", ReferenceDate);
        AddPurchaseLineWithVATandEC(PurchHeader, Item, LibraryRandom.RandDec(99, 2), LibraryRandom.RandDec(99, 2));
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        // Exercise
        FileName := Library340.RunMake340DeclarationReport(FiscalYear, '', Date2DMY(ReferenceDate, 2), 0.0);
        OperationCodeReport := Library340.ReadOperationalCodeFromFile(FileName, InvoiceNo,
            InvoiceNoStartingPosition, 1, OperationCodeStartingPosition, 1);

        // Verify
        Assert.AreEqual(OperationCode.Code, OperationCodeReport, IncorrectOperationCode);

        // TearDown
        RemoveVendorVATRegNo(Vendor."No.");
        GenProductPostingGroup.Get(Item."Gen. Prod. Posting Group");
        UnmapAndDeleteOperationCode(OperationCode, GenProductPostingGroup);
    end;

    local procedure ReadNumericExcerciseLine(FileName: Text[1024]; FiscalYear: Text[4]): Text[1024]
    begin
        exit(LibraryTextFileValidation.FindLineWithValue(FileName, 426, StrLen(FiscalYear), FiscalYear));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure ReversedPaymentsFromCustomer()
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        ReversalEntry: Record "Reversal Entry";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InvoiceDocNo: Code[20];
        Amount: Decimal;
        FirstPaymentAmount: Decimal;
        SecondPaymentAmount: Decimal;
        ReferenceDate: Date;
    begin
        // TFS300278 - http://vstfnav:8080/tfs/web/wi.aspx?id=300278
        Initialize();

        // Pre-Setup
        PreSetup(Customer, GLAccount, Amount, FirstPaymentAmount, SecondPaymentAmount, ReferenceDate);

        // Setup
        InvoiceDocNo := CreateAndPostInvoiceUsingJournal(Customer."No.",
            GLAccount."No.", Amount, GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);
        ApplyAndPostPayment(InvoiceDocNo, Customer."No.", GLAccount."No.", Amount,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", CalcDate('<1Y>', ReferenceDate));

        UnapplyCustomerLedgerEntry(CustLedgerEntry, Customer."No.", CalcDate('<1Y>', ReferenceDate));
        ReversalEntry.SetHideDialog(true);
        ReversalEntry.ReverseTransaction(CustLedgerEntry."Transaction No.");

        // Exercise
        asserterror Library340.RunMake340DeclarationReport(Date2DMY(ReferenceDate, 3) + 1, GLAccount."No.",
            Date2DMY(ReferenceDate, 2), Amount - LibraryRandom.RandDec(100, 2));

        // Verify
        Assert.ExpectedError(NoRecordsFoundError);

        // Tear-Down
        RemoveCustomerVATRegNo(Customer."No.");
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesSalesInvoicePageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoOperationCodeD()
    var
        Cust: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ActualOperationCode: Code[1];
        ExportedFileName: Text[1024];
        FiscalYear: Integer;
        InvoiceDocNo: Code[20];
        Line: Text[1024];
        ReferenceAmount: Integer;
        ReferenceDate: Date;
    begin
        // TFS298549 - http://vstfnav:8080/tfs/web/wi.aspx?id=298549
        Initialize();

        // Pre-Setup
        ReferenceAmount := 1000 * LibraryRandom.RandInt(10);
        ReferenceDate := GetBasisOfCalcForPostingDate();
        FiscalYear := Date2DMY(ReferenceDate, 3);

        // Setup
        CreateCustomer(Cust);

        LibrarySales.FindItem(Item);
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Cust."No.", ReferenceDate);
        AddSalesLineWithVATandEC(SalesHeader, Item, LibraryRandom.RandDec(99, 2), LibraryRandom.RandDec(99, 2));
        InvoiceDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise
        ExportedFileName := Library340.RunMake340DeclarationReport(FiscalYear, '', Date2DMY(ReferenceDate, 2), ReferenceAmount);

        // Post-Exercise
        Line := Library340.ReadCustomerLine(ExportedFileName, Cust.Name);

        // Verify
        ActualOperationCode := Library340.ReadOperationCode(Line);
        Assert.AreEqual(OperationCodeD, ActualOperationCode, IncorrectOperationCode);

        // Tear-Down
        RemoveCustomerVATRegNo(Cust."No.");
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesSalesInvoicePageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoOperationCodeDGrouped()
    var
        Cust: Record Customer;
        SalesHeader: Record "Sales Header";
        Item1: Record Item;
        Item2: Record Item;
        ActualOperationCode: Code[1];
        ActualNoOfLines: Integer;
        ExportedFileName: Text[1024];
        Line: Text[1024];
        ReferenceDate: Date;
        VATPercentage: Integer;
    begin
        Initialize();

        // Setup
        ReferenceDate := GetBasisOfCalcForPostingDate();
        VATPercentage := LibraryRandom.RandInt(100);

        // Create and Post Credit Memo with 2 lines with different VAT Product Posting Group, but same VAT %
        CreateCustomer(Cust);
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Cust."No.", ReferenceDate);

        LibrarySales.FindItem(Item1);
        AddSalesLineWithVATandEC(SalesHeader, Item1, VATPercentage, 0);
        FindItemWithDifferentVATPostingGroup(Item2, Item1."VAT Prod. Posting Group");
        AddSalesLineWithVATandEC(SalesHeader, Item2, VATPercentage, 0);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise
        ExportedFileName := Library340.RunMake340DeclarationReport(Date2DMY(ReferenceDate, 3), '', Date2DMY(ReferenceDate, 2), 0);

        // Verify
        Line := Library340.ReadCustomerLine(ExportedFileName, Cust.Name);

        ActualOperationCode := Library340.ReadOperationCode(Line);
        Assert.AreEqual(OperationCodeD, ActualOperationCode, IncorrectOperationCode);

        ActualNoOfLines := CountNoOfLinesForCustomer(ExportedFileName, Cust.Name);
        Assert.AreEqual(1, ActualNoOfLines, IncorrectNoOfLines);

        // Tear-Down
        RemoveCustomerVATRegNo(Cust."No.");
    end;

    [Test]
    [HandlerFunctions('ModalPageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoPrPsGroupMapped()
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        OperationCode: Record "Operation Code";
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Cust: Record Customer;
        InvoiceNo: Code[20];
        FileName: Text[1024];
        OperationCodeReport: Code[1];
        FiscalYear: Integer;
        ReferenceDate: Date;
    begin
        // TFS298200 - http://vstfnav:8080/tfs/web/wi.aspx?id=298200
        Initialize();

        // Pre-Setup
        ReferenceDate := GetBasisOfCalcForPostingDate();
        FiscalYear := Date2DMY(ReferenceDate, 3);

        // Setup
        Library340.CreateOperationCode(OperationCode, GetValidCharacter());
        FindItemWithOperationCode(Item, OperationCode.Code);

        Library340.CreateCustomerVATRegistration(Cust);
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Cust."No.", ReferenceDate);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise
        FileName := Library340.RunMake340DeclarationReport(FiscalYear, '', Date2DMY(ReferenceDate, 2), 0.0);

        // Verify
        OperationCodeReport := Library340.ReadOperationalCodeFromFile(FileName, InvoiceNo,
            InvoiceNoStartingPosition, 1, OperationCodeStartingPosition, 1);
        Assert.AreEqual(OperationCodeD, OperationCodeReport, IncorrectOperationCode);

        // Tear-Down
        RemoveCustomerVATRegNo(Cust."No.");
        GenProductPostingGroup.Get(Item."Gen. Prod. Posting Group");
        UnmapAndDeleteOperationCode(OperationCode, GenProductPostingGroup);
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesSalesInvoicePageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure SalesInvoiceCustomerInSpain()
    begin
        // TFS299643 - http://vstfnav:8080/tfs/web/wi.aspx?id=299643
        SalesInvoiceCountrySpecific(true, true);
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesSalesInvoicePageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure SalesInvoiceCustomerInEurope()
    begin
        // TFS299645 - http://vstfnav:8080/tfs/web/wi.aspx?id=299645
        SalesInvoiceCountrySpecific(false, true);
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesSalesInvoicePageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure SalesInvoiceCustomerOutsideEurope()
    begin
        SalesInvoiceCountrySpecific(false, false);
    end;

    [Test]
    [HandlerFunctions('ModalPageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure SalesInvoiceECEqualToZero()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Item1: Record Item;
        Item2: Record Item;
        InvoiceNo: Code[20];
        FileName: Text[1024];
        VATPercentage1: Decimal;
        VATPercentage2: Decimal;
        ECPercentage2: Decimal;
        NoOfLinesVAT1: Integer;
        NoOfLinesVAT2: Integer;
        FiscalYear: Integer;
        ReferenceDate: Date;
    begin
        Initialize();

        // Pre-Setup
        ReferenceDate := GetBasisOfCalcForPostingDate();
        FiscalYear := Date2DMY(ReferenceDate, 3);

        // Setup: First VAT Entry
        VATPercentage1 := LibraryRandom.RandDec(99, 2);
        Library340.CreateCustomerVATRegistration(Customer);
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", ReferenceDate);

        LibrarySales.FindItem(Item1);
        AddSalesLineWithVATandEC(SalesHeader, Item1, VATPercentage1, 0);

        // Setup: Second VAT Entry
        VATPercentage2 := LibraryRandom.RandDec(99, 2);
        ECPercentage2 := LibraryRandom.RandDec(99, 2);

        FindItemWithDifferentVATPostingGroup(Item2, Item1."VAT Prod. Posting Group");
        AddSalesLineWithVATandEC(SalesHeader, Item2, VATPercentage2, ECPercentage2);
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise
        FileName := Library340.RunMake340DeclarationReport(FiscalYear, '', Date2DMY(ReferenceDate, 2), 0.0);

        // Verify
        NoOfLinesVAT1 := GetNumberOfLinesByVATandEC(FileName, InvoiceNo, VATPercentage1, 0);
        NoOfLinesVAT2 := GetNumberOfLinesByVATandEC(FileName, InvoiceNo, VATPercentage2, ECPercentage2);
        Assert.AreEqual(1, NoOfLinesVAT1, StrSubstNo(UnexpectedReportLines, VATPercentage1, 0, 1, NoOfLinesVAT1));
        Assert.AreEqual(1, NoOfLinesVAT2, StrSubstNo(UnexpectedReportLines, VATPercentage2, ECPercentage2, 1, NoOfLinesVAT2));

        // Tear-Down
        RemoveCustomerVATRegNo(Customer."No.");
    end;

    [Test]
    [HandlerFunctions('ModalPageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure SalesInvoiceMultipleVATPercent()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Item1: Record Item;
        Item2: Record Item;
        FileName: Text[1024];
        VATPercentage1: Decimal;
        VATPercentage2: Decimal;
        ECPercentage: Decimal;
        NoOfLinesVAT1: Integer;
        NoOfLinesVAT2: Integer;
        InvoiceNo: Code[20];
        FiscalYear: Integer;
        ReferenceDate: Date;
    begin
        Initialize();

        // Pre-Setup
        ReferenceDate := GetBasisOfCalcForPostingDate();
        FiscalYear := Date2DMY(ReferenceDate, 3);

        // Setup: First VAT Entry
        VATPercentage1 := LibraryRandom.RandDec(99, 2);
        ECPercentage := LibraryRandom.RandDec(99, 2);
        Library340.CreateCustomerVATRegistration(Customer);

        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", ReferenceDate);
        LibrarySales.FindItem(Item1);
        AddSalesLineWithVATandEC(SalesHeader, Item1, VATPercentage1, ECPercentage);

        // Setup: Second VAT Entry
        VATPercentage2 := LibraryRandom.RandDec(99, 2);
        FindItemWithDifferentVATPostingGroup(Item2, Item1."VAT Prod. Posting Group");
        AddSalesLineWithVATandEC(SalesHeader, Item2, VATPercentage2, ECPercentage);
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise
        FileName := Library340.RunMake340DeclarationReport(FiscalYear, '', Date2DMY(ReferenceDate, 2), 0.0);

        // Verify
        NoOfLinesVAT1 := GetNumberOfLinesByVATandEC(FileName, InvoiceNo, VATPercentage1, ECPercentage);
        NoOfLinesVAT2 := GetNumberOfLinesByVATandEC(FileName, InvoiceNo, VATPercentage2, ECPercentage);
        Assert.AreEqual(1, NoOfLinesVAT1, StrSubstNo(UnexpectedReportLines, VATPercentage1, ECPercentage, 1, NoOfLinesVAT1));
        Assert.AreEqual(1, NoOfLinesVAT2, StrSubstNo(UnexpectedReportLines, VATPercentage2, ECPercentage, 1, NoOfLinesVAT2));

        // Tear-Down
        RemoveCustomerVATRegNo(Customer."No.");
    end;

    [Test]
    [HandlerFunctions('ModalPageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure SalesInvoiceMultipleVATandEC()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Item1: Record Item;
        Item2: Record Item;
        InvoiceNo: Code[20];
        FileName: Text[1024];
        VATPercentage1: Decimal;
        VATPercentage2: Decimal;
        ECPercentage1: Decimal;
        ECPercentage2: Decimal;
        NoOfLinesVAT1EC1: Integer;
        NoOfLinesVAT2EC2: Integer;
        FiscalYear: Integer;
        ReferenceDate: Date;
    begin
        Initialize();

        // Pre-Setup
        ReferenceDate := GetBasisOfCalcForPostingDate();
        FiscalYear := Date2DMY(ReferenceDate, 3);

        // Setup: First VAT Entry
        VATPercentage1 := LibraryRandom.RandDec(99, 2);
        ECPercentage1 := LibraryRandom.RandDec(99, 2);
        Library340.CreateCustomerVATRegistration(Customer);

        LibrarySales.FindItem(Item1);
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", ReferenceDate);
        AddSalesLineWithVATandEC(SalesHeader, Item1, VATPercentage1, ECPercentage1);

        // Setup: Second VAT Entry
        VATPercentage2 := LibraryRandom.RandDec(99, 2);
        ECPercentage2 := LibraryRandom.RandDec(99, 2);
        FindItemWithDifferentVATPostingGroup(Item2, Item1."VAT Prod. Posting Group");
        AddSalesLineWithVATandEC(SalesHeader, Item2, VATPercentage2, ECPercentage2);
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise
        FileName := Library340.RunMake340DeclarationReport(FiscalYear, '', Date2DMY(ReferenceDate, 2), 0.0);

        // Verify
        NoOfLinesVAT1EC1 := GetNumberOfLinesByVATandEC(FileName, InvoiceNo, VATPercentage1, ECPercentage1);
        NoOfLinesVAT2EC2 := GetNumberOfLinesByVATandEC(FileName, InvoiceNo, VATPercentage2, ECPercentage2);
        Assert.AreEqual(1, NoOfLinesVAT1EC1, StrSubstNo(UnexpectedReportLines, VATPercentage1, ECPercentage1, 1, NoOfLinesVAT1EC1));
        Assert.AreEqual(1, NoOfLinesVAT2EC2, StrSubstNo(UnexpectedReportLines, VATPercentage2, ECPercentage2, 1, NoOfLinesVAT2EC2));

        // Tear-Down
        RemoveCustomerVATRegNo(Customer."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure SalesInvoiceMultiYear2Payments()
    var
        Cust: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GLAcc: Record "G/L Account";
        Amount: Decimal;
        ExportedFileName: Text[1024];
        FirstPaymentAmount: Decimal;
        InvoiceDocNo: Code[20];
        Line: Text[1024];
        MinPaymentAmount: Decimal;
        ReferenceDate: Date;
    begin
        // TFS299463 - http://vstfnav:8080/tfs/web/wi.aspx?id=299463
        Initialize();

        // Pre-Setup
        ReferenceDate := GetBasisOfCalcForPostingDate();
        MinPaymentAmount := 1000 * LibraryRandom.RandInt(10);
        Amount := LibraryRandom.RandDecInRange(MinPaymentAmount + 1000, MinPaymentAmount + 2000, 2);
        FirstPaymentAmount := LibraryRandom.RandDecInRange(MinPaymentAmount, Amount div 1, 2);

        // Setup
        CreateCustomer(Cust);
        LibraryERM.FindGLAccount(GLAcc);

        InvoiceDocNo := CreateAndPostInvoiceUsingJournal(Cust."No.", GLAcc."No.", Amount,
            GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);
        ApplyAndPostPayment(InvoiceDocNo, Cust."No.", GLAcc."No.", FirstPaymentAmount,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);
        ApplyAndPostPayment(InvoiceDocNo, Cust."No.", GLAcc."No.", Amount - FirstPaymentAmount,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", CalcDate('<1Y>', ReferenceDate));

        // Exercise
        ExportedFileName := Library340.RunMake340DeclarationReport(Date2DMY(ReferenceDate, 3), GLAcc."No.",
            Date2DMY(ReferenceDate, 2), MinPaymentAmount);

        // Post-Exercise
        Line := Library340.ReadCustomerLine(ExportedFileName, Cust.Name);

        // Verify
        VerifySalesInvoiceMultiYearPayments(Line, FirstPaymentAmount, Date2DMY(ReferenceDate, 3));

        // Tear-Down
        RemoveCustomerVATRegNo(Cust."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure SalesInvoiceMultiYear3Payments()
    var
        Cust: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GLAcc: Record "G/L Account";
        Amount: Decimal;
        ExportedFileName: Text[1024];
        FirstPaymentAmount: Decimal;
        InvoiceDocNo: Code[20];
        Line: Text[1024];
        MinPaymentAmount: Decimal;
        ReferenceDate: Date;
        SecondPaymentAmount: Decimal;
    begin
        // TFS299466 - http://vstfnav:8080/tfs/web/wi.aspx?id=299466
        Initialize();

        // Pre-Setup
        ReferenceDate := GetBasisOfCalcForPostingDate();
        MinPaymentAmount := 1000 * LibraryRandom.RandInt(10);
        Amount := LibraryRandom.RandDecInRange(MinPaymentAmount + 1000, MinPaymentAmount + 2000, 2);
        FirstPaymentAmount := LibraryRandom.RandDecInRange(MinPaymentAmount, Amount div 1, 2);
        SecondPaymentAmount := LibraryRandom.RandDec((Amount - FirstPaymentAmount) div 1, 2);

        // Setup
        CreateCustomer(Cust);
        LibraryERM.FindGLAccount(GLAcc);

        InvoiceDocNo := CreateAndPostInvoiceUsingJournal(Cust."No.", GLAcc."No.", Amount,
            GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);
        ApplyAndPostPayment(InvoiceDocNo, Cust."No.", GLAcc."No.", FirstPaymentAmount,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);
        ApplyAndPostPayment(InvoiceDocNo, Cust."No.", GLAcc."No.", SecondPaymentAmount,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", CalcDate('<1Y>', ReferenceDate));
        ApplyAndPostPayment(InvoiceDocNo, Cust."No.", GLAcc."No.", Amount - SecondPaymentAmount,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", CalcDate('<2Y>', ReferenceDate));

        // Exercise
        ExportedFileName := Library340.RunMake340DeclarationReport(Date2DMY(ReferenceDate, 3), GLAcc."No.",
            Date2DMY(ReferenceDate, 2), MinPaymentAmount);

        // Post-Exercise
        Line := Library340.ReadCustomerLine(ExportedFileName, Cust.Name);

        // Verify
        VerifySalesInvoiceMultiYearPayments(Line, FirstPaymentAmount, Date2DMY(ReferenceDate, 3));

        // Tear-Down
        RemoveCustomerVATRegNo(Cust."No.");
    end;

    [Test]
    [HandlerFunctions('ModalPageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure SalesInvoiceOneVATPercent()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        FileName: Text[1024];
        VATPercentage: Decimal;
        ECPercentage: Decimal;
        NoOfLinesVAT: Integer;
        InvoiceNo: Code[20];
        FiscalYear: Integer;
        ReferenceDate: Date;
    begin
        Initialize();

        // Pre-Setup
        ReferenceDate := GetBasisOfCalcForPostingDate();
        FiscalYear := Date2DMY(ReferenceDate, 3);

        // Setup: First VAT Entry
        VATPercentage := LibraryRandom.RandDec(99, 2);
        ECPercentage := LibraryRandom.RandDec(99, 2);
        Library340.CreateCustomerVATRegistration(Customer);

        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.", ReferenceDate);
        LibrarySales.FindItem(Item);
        AddSalesLineWithVATandEC(SalesHeader, Item, VATPercentage, ECPercentage);

        // Setup: Second VAT Entry
        AddSalesLineWithVATandEC(SalesHeader, Item, VATPercentage, ECPercentage);
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise
        FileName := Library340.RunMake340DeclarationReport(FiscalYear, '', Date2DMY(ReferenceDate, 2), 0.0);

        // Verify
        NoOfLinesVAT := GetNumberOfLinesByVATandEC(FileName, InvoiceNo, VATPercentage, ECPercentage);
        Assert.AreEqual(1, NoOfLinesVAT, StrSubstNo(UnexpectedReportLines, VATPercentage, ECPercentage, 1, NoOfLinesVAT));

        // Tear-Down
        RemoveCustomerVATRegNo(Customer."No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure SalesInvoicePaymentsAppliedInMultipleYears()
    var
        Cust: Record Customer;
        GLAcc: Record "G/L Account";
        GenJournalLine: Record "Gen. Journal Line";
        ActualAmount: Text[15];
        ActualNumericExercise: Integer;
        ActualOperationCode: Code[1];
        Amount: Decimal;
        ExpectedAmount: Text[15];
        ExportedFileName: Text[1024];
        FirstPaymentAmount: Decimal;
        FiscalYear: Integer;
        InvoiceDocNo: Code[20];
        Line: Text[1024];
        ReferenceAmount: Integer;
        ReferenceDate: Date;
    begin
        // TFS299463 - http://vstfnav:8080/tfs/web/wi.aspx?id=299463
        Initialize();

        // Pre-Setup
        ReferenceAmount := 1000 * LibraryRandom.RandInt(10);
        Amount := LibraryRandom.RandDecInRange(ReferenceAmount + 1000, ReferenceAmount + 2000, 2);
        FirstPaymentAmount := LibraryRandom.RandDecInRange(ReferenceAmount, Amount div 1, 2);
        ReferenceDate := GetBasisOfCalcForPostingDate();
        FiscalYear := Date2DMY(CalcDate('<1Y>', ReferenceDate), 3);

        // Setup
        CreateCustomer(Cust);
        LibraryERM.FindGLAccount(GLAcc);

        InvoiceDocNo := CreateAndPostInvoiceUsingJournal(Cust."No.", GLAcc."No.", Amount,
            GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);
        ApplyAndPostPayment(InvoiceDocNo, Cust."No.", GLAcc."No.", FirstPaymentAmount,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", CalcDate('<1Y>', ReferenceDate));
        ApplyAndPostPayment(InvoiceDocNo, Cust."No.", GLAcc."No.", Amount - FirstPaymentAmount,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", CalcDate('<2Y>', ReferenceDate));

        // Exercise
        ExportedFileName := Library340.RunMake340DeclarationReport(FiscalYear, GLAcc."No.", Date2DMY(ReferenceDate, 2), ReferenceAmount);

        // Post-Exercise
        Line := Library340.ReadCustomerLine(ExportedFileName, Cust.Name);

        // Verify
        ActualOperationCode := Library340.ReadOperationCode(Line);
        Assert.AreEqual('', ActualOperationCode, IncorrectOperationCode);

        ActualAmount := Library340.ReadCashCollectableAmountInteger(Line);
        ExpectedAmount := CalculateExpectedAmount(FirstPaymentAmount);
        Assert.AreEqual(ExpectedAmount, ActualAmount, IncorrectCashCollectablesAmount);

        Evaluate(ActualNumericExercise, Library340.ReadNumericExercise(Line));
        Assert.AreEqual(FiscalYear - 1, ActualNumericExercise, IncorrectNumericExercise);

        // Tear-Down
        RemoveCustomerVATRegNo(Cust."No.");
    end;

    [Test]
    [HandlerFunctions('ModalPageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure SalesInvoicePropertyTaxBlank()
    var
        Cust: Record Customer;
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        OperationCode: Record "Operation Code";
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        ActualNumericExercise: Text[4];
        FileName: Text[1024];
        FiscalYear: Integer;
        InvoiceNo: Code[20];
        Line: Text[1024];
        ReferenceDate: Date;
    begin
        Initialize();

        // Pre-Setup
        ReferenceDate := GetBasisOfCalcForPostingDate();
        FiscalYear := Date2DMY(ReferenceDate, 3);

        // Setup
        Library340.CreateOperationCode(OperationCode, GetValidCharacter());
        FindItemWithOperationCode(Item, OperationCode.Code);

        Library340.CreateCustomerVATRegistration(Cust);
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Cust."No.", ReferenceDate);
        AddSalesLineWithVATandEC(SalesHeader, Item, LibraryRandom.RandDec(99, 2), LibraryRandom.RandDec(99, 2));
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise
        FileName := Library340.RunMake340DeclarationReport(FiscalYear, '', Date2DMY(ReferenceDate, 2), 0.0);

        // Post-Exercise
        Line := Library340.ReadCustomerLine(FileName, Cust.Name);

        // Verify
        VerifyPropertyTaxLine(Line, OperationCode.Code, '0', '', false);

        ActualNumericExercise := Library340.ReadNumericExercise(Line);
        Assert.AreEqual(Format(NumericExerciseZero), ActualNumericExercise, IncorrectNumericExercise);

        // TearDown
        RemoveCustomerVATRegNo(Cust."No.");
        GenProductPostingGroup.Get(Item."Gen. Prod. Posting Group");
        UnmapAndDeleteOperationCode(OperationCode, GenProductPostingGroup);
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesPropertyTaxAccNoPageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure SalesInvoicePropertyTaxInBasqueNavarra()
    var
        DeclarationLine: Record "340 Declaration Line";
    begin
        // TFS298518 - http://vstfnav:8080/tfs/web/wi.aspx?id=298518
        SalesInvoicePropertyTax(DeclarationLine."Property Location"::"Property in Basque / Navarra", true);
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesPropertyTaxAccNoPageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure SalesInvoicePropertyTaxInSpain()
    var
        DeclarationLine: Record "340 Declaration Line";
    begin
        // TFS298411 - http://vstfnav:8080/tfs/web/wi.aspx?id=298411
        SalesInvoicePropertyTax(DeclarationLine."Property Location"::"Property in Spain", true);
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesPropertyTaxAccNoPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoicePropertyTaxMissingTaxAccNoWithError()
    var
        DeclarationLine: Record "340 Declaration Line";
    begin
        // TFS298524 - http://vstfnav:8080/tfs/web/wi.aspx?id=298524
        asserterror SalesInvoicePropertyTax(DeclarationLine."Property Location"::"Property W/o Tax number", true);
        Assert.ExpectedError(CannotInsertPropertyTaxAccNo);
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesNoPropertyTaxAccNoPageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure SalesInvoicePropertyTaxMissingTaxAccNo()
    var
        DeclarationLine: Record "340 Declaration Line";
    begin
        // TFS298524 - http://vstfnav:8080/tfs/web/wi.aspx?id=298524
        SalesInvoicePropertyTax(DeclarationLine."Property Location"::"Property W/o Tax number", false);
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesPropertyTaxAccNoPageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure SalesInvoicePropertyTaxOutsideSpain()
    var
        DeclarationLine: Record "340 Declaration Line";
    begin
        // TFS298541 - http://vstfnav:8080/tfs/web/wi.aspx?id=298541
        SalesInvoicePropertyTax(DeclarationLine."Property Location"::"Property outside Spain", true);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure SalesInvoiceUnrealizedVAT()
    var
        Customer: Record Customer;
        GenBusPostingGroup: Record "Gen. Business Posting Group";
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        ReferenceDate: Date;
        InvoiceNo: Code[20];
        Amount: Decimal;
        FileName: Text[1024];
        Line: Text[1024];
        ActualAmount: Text[15];
        ExpectedAmount: Text[15];
        ActualNumericExercise: Text[4];
    begin
        Initialize();

        // Setup
        ReferenceDate := GetBasisOfCalcForPostingDate();

        LibraryERM.SetUnrealizedVAT(true);
        LibraryERM.CreateGenBusPostingGroup(GenBusPostingGroup);
        CreateUnrealizedVATPostingSetup(VATPostingSetup);
        CreateCustomer(Customer);
        SetCustomerPostingGroupAndPaymentMethod(Customer, VATPostingSetup."VAT Bus. Posting Group", GenBusPostingGroup.Code);

        Amount := LibraryRandom.RandDec(100000, 2);
        InvoiceNo := CreateAndPostInvoiceUsingJournal(Customer."No.", VATPostingSetup."Sales VAT Unreal. Account",
            Amount, GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);

        ApplyAndPostPayment(InvoiceNo, Customer."No.", VATPostingSetup."Sales VAT Unreal. Account", Amount / 3,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", CalcDate('<1M>', ReferenceDate));
        ApplyAndPostPayment(InvoiceNo, Customer."No.", VATPostingSetup."Sales VAT Unreal. Account", Amount / 3,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);

        // Exercise
        FileName := Library340.RunMake340DeclarationReport(Date2DMY(ReferenceDate, 3), VATPostingSetup."Sales VAT Unreal. Account",
            Date2DMY(ReferenceDate, 2), Amount / 4);

        // Verify
        Line := Library340.ReadCustomerLine(FileName, Customer.Name);

        // Verify amount in the exported file.
        ActualAmount := Library340.ReadCashCollectableAmountInteger(Line);
        ExpectedAmount := CalculateExpectedAmount(Amount / 3);
        Assert.AreEqual(ExpectedAmount, ActualAmount, StrSubstNo(NotEqualValues, ExpectedAmount, ActualAmount));

        // Verify year in the exported file.
        ActualNumericExercise := Library340.ReadNumericExercise(Line);
        Assert.AreEqual(Format(Date2DMY(ReferenceDate, 3)), ActualNumericExercise, NotEqualValues);

        // Tear-Down
        RemoveCustomerVATRegNo(Customer."No.");
        VATPostingSetup.Delete(true);
        LibraryERM.SetUnrealizedVAT(false);
    end;

    [Test]
    [HandlerFunctions('ModalPageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure SalesOrderProdPostGroupMapped()
    var
        Item: Record Item;
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        OperationCode: Record "Operation Code";
        SalesHeader: Record "Sales Header";
        Cust: Record Customer;
        InvoiceNo: Code[20];
        FileName: Text[1024];
        OperationCodeReport: Code[1];
        FiscalYear: Integer;
        ReferenceDate: Date;
    begin
        Initialize();

        // Pre-Setup
        ReferenceDate := GetBasisOfCalcForPostingDate();
        FiscalYear := Date2DMY(ReferenceDate, 3);

        // Setup
        Library340.CreateOperationCode(OperationCode, GetValidCharacter());
        FindItemWithOperationCode(Item, OperationCode.Code);

        Library340.CreateCustomerVATRegistration(Cust);
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Cust."No.", ReferenceDate);
        LibrarySales.FindItem(Item);

        AddSalesLineWithVATandEC(SalesHeader, Item, LibraryRandom.RandDec(99, 2), LibraryRandom.RandDec(99, 2));
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise
        FileName := Library340.RunMake340DeclarationReport(FiscalYear, '', Date2DMY(ReferenceDate, 2), 0.0);

        // Verify
        OperationCodeReport := Library340.ReadOperationalCodeFromFile(FileName, InvoiceNo, InvoiceNoStartingPosition, 1,
            OperationCodeStartingPosition, 1);
        Assert.AreEqual(OperationCode.Code, OperationCodeReport, IncorrectOperationCode);

        // TearDown
        RemoveCustomerVATRegNo(Cust."No.");
        GenProductPostingGroup.Get(Item."Gen. Prod. Posting Group");
        UnmapAndDeleteOperationCode(OperationCode, GenProductPostingGroup);
    end;

    [Test]
    [HandlerFunctions('ModalPageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure ServiceInvoiceProdPostGroupMapped()
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        OperationCode: Record "Operation Code";
        ServiceHeader: Record "Service Header";
        Item: Record Item;
        Cust: Record Customer;
        FileName: Text[1024];
        OperationCodeReport: Code[1];
        FiscalYear: Integer;
        ReferenceDate: Date;
        Line: Text[1024];
    begin
        Initialize();

        // Pre-Setup
        ReferenceDate := GetBasisOfCalcForPostingDate();
        FiscalYear := Date2DMY(ReferenceDate, 3);

        // Setup
        Library340.CreateOperationCode(OperationCode, GetValidCharacter());
        FindItemWithOperationCode(Item, OperationCode.Code);

        LibrarySales.FindItem(Item);
        Library340.CreateCustomerVATRegistration(Cust);
        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Invoice, Cust."No.",
          ReferenceDate, OperationCode.Code, LibraryRandom.RandDec(1000, 2));
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // Exercise
        FileName := Library340.RunMake340DeclarationReport(FiscalYear, '', Date2DMY(ReferenceDate, 2), 0.0);

        // Verify
        Line := Library340.ReadCustomerLine(FileName, Cust.Name);
        OperationCodeReport := Library340.ReadOperationCode(Line);
        Assert.AreEqual(OperationCode.Code, OperationCodeReport, IncorrectOperationCode);

        // TearDown
        RemoveCustomerVATRegNo(Cust."No.");
        GenProductPostingGroup.Get(Item."Gen. Prod. Posting Group");
        UnmapAndDeleteOperationCode(OperationCode, GenProductPostingGroup);
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesPropertyTaxAccNoPageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure ServiceInvoicePropertyTaxInBasqueNavarra()
    var
        DeclarationLine: Record "340 Declaration Line";
    begin
        // TFS298519 - http://vstfnav:8080/tfs/web/wi.aspx?id=298519
        ServiceInvoicePropertyTax(DeclarationLine."Property Location"::"Property in Basque / Navarra", true);
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesPropertyTaxAccNoPageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure ServiceInvoicePropertyTaxInSpain()
    var
        DeclarationLine: Record "340 Declaration Line";
    begin
        // TFS298516 - http://vstfnav:8080/tfs/web/wi.aspx?id=298516
        ServiceInvoicePropertyTax(DeclarationLine."Property Location"::"Property in Spain", true);
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesPropertyTaxAccNoPageHandler')]
    [Scope('OnPrem')]
    procedure ServiceInvoicePropertyTaxNoTaxAccNumberError()
    var
        DeclarationLine: Record "340 Declaration Line";
    begin
        // TFS298525 - http://vstfnav:8080/tfs/web/wi.aspx?id=298525
        asserterror ServiceInvoicePropertyTax(DeclarationLine."Property Location"::"Property W/o Tax number", true);
        Assert.ExpectedError(CannotInsertPropertyTaxAccNo);
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesNoPropertyTaxAccNoPageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure ServiceInvoicePropertyTaxNoTaxAccNumberNoError()
    var
        DeclarationLine: Record "340 Declaration Line";
    begin
        // TFS298525 - http://vstfnav:8080/tfs/web/wi.aspx?id=298525
        ServiceInvoicePropertyTax(DeclarationLine."Property Location"::"Property W/o Tax number", false);
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesPropertyTaxAccNoPageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure ServiceInvoicePropertyTaxOutsideSpain()
    var
        DeclarationLine: Record "340 Declaration Line";
    begin
        // TFS298542 - http://vstfnav:8080/tfs/web/wi.aspx?id=298542
        ServiceInvoicePropertyTax(DeclarationLine."Property Location"::"Property outside Spain", true);
    end;

    [Test]
    [HandlerFunctions('MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure UnappliedAndReAppliedPaymentFromCustomer()
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        ExportedFileName: Text[1024];
        Line: Text[1024];
        InvoiceDocNo: Code[20];
        FiscalYear: Integer;
        ReferenceAmount: Decimal;
        Amount: Decimal;
        FirstPaymentAmount: Decimal;
        ReferenceDate: Date;
    begin
        // TFS300230 - http://vstfnav:8080/tfs/web/wi.aspx?id=300230
        Initialize();

        // Pre-Setup
        PreSetup(Customer, GLAccount, ReferenceAmount, FirstPaymentAmount, Amount, ReferenceDate);
        FiscalYear := Date2DMY(ReferenceDate, 3);

        // Setup.
        InvoiceDocNo := CreateAndPostInvoiceUsingJournal(Customer."No.", GLAccount."No.", Amount,
            GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);
        ApplyAndPostPayment(InvoiceDocNo, Customer."No.", GLAccount."No.", Amount,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", CalcDate('<1Y>', ReferenceDate));
        UnapplyCustomerLedgerEntry(CustLedgerEntry, Customer."No.", CalcDate('<1Y>', ReferenceDate));
        ApplyCustomerEntries(Customer."No.");

        // Exercise
        ExportedFileName := Library340.RunMake340DeclarationReport(FiscalYear + 1, GLAccount."No.",
            Date2DMY(ReferenceDate, 2), Amount - LibraryRandom.RandDec(100, 2));

        // Post-Exercise
        Line := Library340.ReadCustomerLine(ExportedFileName, Customer.Name);

        // Verify
        VerifyCashCollectableValues(Line, Amount, Format(FiscalYear));

        // Tear-Down
        RemoveCustomerVATRegNo(Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnappliedPaymentFromCustomer()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        InvoiceDocNo: Code[20];
        Amount: Decimal;
        ReferenceAmount: Decimal;
        ReferenceDate: Date;
        FiscalYear: Integer;
    begin
        // TFS298682 - http://vstfnav:8080/tfs/web/wi.aspx?id=298682.
        Initialize();

        // Pre-Setup
        ReferenceAmount := 1000 * LibraryRandom.RandInt(10);
        Amount := LibraryRandom.RandIntInRange(ReferenceAmount + 1000, ReferenceAmount + 2000);
        ReferenceDate := GetBasisOfCalcForPostingDate();
        FiscalYear := Date2DMY(ReferenceDate, 3);

        // Setup
        CreateCustomer(Customer);
        LibraryERM.FindGLAccount(GLAccount);

        InvoiceDocNo := CreateAndPostInvoiceUsingJournal(Customer."No.", GLAccount."No.", Amount,
            GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);
        ApplyAndPostPayment(
            '', Customer."No.", GLAccount."No.", Amount, GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);

        // Exercise
        asserterror Library340.RunMake340DeclarationReport(FiscalYear, GLAccount."No.", Date2DMY(ReferenceDate, 2), ReferenceAmount);

        // Verify
        Assert.ExpectedError(NoRecordsFoundError);

        // Tear-Down
        RemoveCustomerVATRegNo(Customer."No.");
    end;

    [Test]
    [HandlerFunctions('ModalPageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure UnappliedInvoiceInCurrentYear()
    var
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        ExportedFileName: Text[1024];
        Line: Text[1024];
        FiscalYear: Integer;
        MinimumAmount: Decimal;
        MaximumAmount: Decimal;
        SecondPaymentAmount: Decimal;
        ReferenceDate: Date;
        PaymentPostingDate: Date;
        InvoicePostingDate: Date;
    begin
        // Verify unapplied invoice in current year but in same month.
        // TFS298771 - http://vstfnav:8080/tfs/web/wi.aspx?id=298771
        // Setup.
        Initialize();
        PreSetup(Customer, GLAccount, MaximumAmount, MinimumAmount, SecondPaymentAmount, ReferenceDate);
        PaymentPostingDate := CalcDate('<1M>', ReferenceDate);
        InvoicePostingDate := CalcDate('<2M>', ReferenceDate);
        FiscalYear := Date2DMY(InvoicePostingDate, 3);
        PostMultipleSalesInvoicesAndApplyPayment(Customer."No.", GLAccount."No.", MinimumAmount, ReferenceDate,
          PaymentPostingDate, InvoicePostingDate);

        // Exercise: Run report 'Make 340 Declaration'.
        ExportedFileName := Library340.RunMake340DeclarationReport(FiscalYear, GLAccount."No.",
            Date2DMY(InvoicePostingDate, 2), MinimumAmount);

        // Post - Excercise.
        Line := Library340.ReadCustomerLine(ExportedFileName, Customer.Name);

        // Verify the exported file.
        VerifyUnappliedInvoiceValues(Line);

        // Tear-Down.
        RemoveCustomerVATRegNo(Customer."No.");
    end;

    [Test]
    [HandlerFunctions('ModalPageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure VerifyOperationCodeCReport()
    var
        SalesHeader: Record "Sales Header";
        Item1: Record Item;
        Item2: Record Item;
        Cust: Record Customer;
        InvoiceNo: Code[20];
        FileName: Text[1024];
        OperationCodeReport: Code[1];
        FiscalYear: Integer;
        ReferenceDate: Date;
    begin
        // TFS298549 - http://vstfnav:8080/tfs/web/wi.aspx?id=298549
        Initialize();

        // Pre-Setup
        ReferenceDate := GetBasisOfCalcForPostingDate();
        FiscalYear := Date2DMY(ReferenceDate, 3);

        // Setup
        Library340.CreateCustomerVATRegistration(Cust);
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Cust."No.", ReferenceDate);

        LibrarySales.FindItem(Item1);
        AddSalesLineWithVATandEC(SalesHeader, Item1, LibraryRandom.RandDec(99, 2), LibraryRandom.RandDec(99, 2));

        FindItemWithDifferentVATPostingGroup(Item2, Item1."VAT Prod. Posting Group");
        AddSalesLineWithVATandEC(SalesHeader, Item2, LibraryRandom.RandDec(99, 2), LibraryRandom.RandDec(99, 2));
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise
        FileName := Library340.RunMake340DeclarationReport(FiscalYear, '', Date2DMY(ReferenceDate, 2), 0.0);

        // Verify
        OperationCodeReport := Library340.ReadOperationalCodeFromFile(FileName, InvoiceNo,
            InvoiceNoStartingPosition, 1, OperationCodeStartingPosition, 1);
        Assert.AreEqual(OperationCodeC, OperationCodeReport, IncorrectOperationCode);

        // Tear-Down
        RemoveCustomerVATRegNo(Cust."No.");
    end;

    [Test]
    [HandlerFunctions('ModalPageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure VerifyOperationCodeDInReport()
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        OperationCode: Record "Operation Code";
        SalesLine: Record "Sales Line";
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Cust: Record Customer;
        ActualOperationCode: Code[1];
        InvoiceNo: Code[20];
        FileName: Text[1024];
        FiscalYear: Integer;
        Line: Text[1024];
        ReferenceDate: Date;
    begin
        // TFS298549 - http://vstfnav:8080/tfs/web/wi.aspx?id=298549
        Initialize();

        // Pre-Setup
        ReferenceDate := GetBasisOfCalcForPostingDate();
        FiscalYear := Date2DMY(ReferenceDate, 3);

        // Setup
        Library340.CreateOperationCode(OperationCode, GetValidCharacter());
        FindItemWithOperationCode(Item, OperationCode.Code);

        Library340.CreateCustomerVATRegistration(Cust);
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", Cust."No.", ReferenceDate);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise
        FileName := Library340.RunMake340DeclarationReport(FiscalYear, '', Date2DMY(ReferenceDate, 2), 0.0);

        // Post-Exercise
        Line := Library340.ReadCustomerLine(FileName, Cust.Name);

        // Verify
        ActualOperationCode := Library340.ReadOperationCode(Line);
        Assert.AreEqual(OperationCodeD, ActualOperationCode, IncorrectOperationCode);

        VerifyPropertyTaxLine(Line, 'D', '0', '', false);

        // Tear-Down
        RemoveCustomerVATRegNo(Cust."No.");
        GenProductPostingGroup.Get(Item."Gen. Prod. Posting Group");
        UnmapAndDeleteOperationCode(OperationCode, GenProductPostingGroup);
    end;

    [Test]
    [HandlerFunctions('ModalPageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure VerifyOperationCodeIInReport()
    var
        GLAccount: Record "G/L Account";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        LibraryPurchase: Codeunit "Library - Purchase";
        InvoiceNo: Code[20];
        FileName: Text[1024];
        OperationCodeReport: Code[1];
        ReferenceDate: Date;
        FiscalYear: Integer;
    begin
        // TFS298549 - http://vstfnav:8080/tfs/web/wi.aspx?id=298549
        Initialize();

        // Pre-Setup
        ReferenceDate := GetBasisOfCalcForPostingDate();
        FiscalYear := Date2DMY(ReferenceDate, 3);

        // Setup
        Library340.CreateVendorVATRegistration(Vendor);
        Library340347Declaration.CreateReverseChargeVATPostingSetup(VATPostingSetup, Vendor."VAT Bus. Posting Group");
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader.Validate("Posting Date", ReferenceDate);
        PurchaseHeader.Modify(true);

        GLAccount."No." :=
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccount."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise
        FileName := Library340.RunMake340DeclarationReport(FiscalYear, '', Date2DMY(ReferenceDate, 2), 0.0);

        // Verify
        OperationCodeReport := Library340.ReadOperationalCodeFromFile(FileName, InvoiceNo,
            InvoiceNoStartingPosition, 1, OperationCodeStartingPosition, 1);
        Assert.AreEqual(OperationCodeI, OperationCodeReport, IncorrectOperationCode);

        // Tear-Down
        RemoveVendorVATRegNo(Vendor."No.");
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesSalesInvoicePageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure VerifyNoOfRegisterForCashLessThanTreshold()
    var
        ReferenceAmount: Integer;
    begin
        Initialize();

        ReferenceAmount := 1000 * LibraryRandom.RandInt(10);
        VerifyNoOfRegisters(ReferenceAmount, ReferenceAmount - 1, PadStr('', 8, '0') + Format(1));
    end;

    [Test]
    [HandlerFunctions('DeclarationLinesSalesInvoicePageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure VerifyNoOfRegisterForCashGreaterThanTreshold()
    var
        ReferenceAmount: Integer;
    begin
        Initialize();

        ReferenceAmount := 1000 * LibraryRandom.RandInt(10);
        VerifyNoOfRegisters(ReferenceAmount, ReferenceAmount + 1, PadStr('', 8, '0') + Format(2));
    end;

    [Test]
    [HandlerFunctions('ModalPageHandler,MessageHandlerOK')]
    [Scope('OnPrem')]
    procedure VerifyReverseChargeVATNoEUService()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        InvoiceNo: Code[20];
        FileName: Text[1024];
        OperationCodeReport: Code[1];
        ReferenceDate: Date;
        FiscalYear: Integer;
    begin
        // TFS318668 - http://vstfnav:8080/tfs/web/wi.aspx?id=318668
        Initialize();

        // Pre-Setup
        ReferenceDate := GetBasisOfCalcForPostingDate();
        FiscalYear := Date2DMY(ReferenceDate, 3);

        // Setup
        Library340.CreateVendorVATRegistration(Vendor);
        Library340347Declaration.CreateReverseChargeVATPostingSetup(VATPostingSetup, Vendor."VAT Bus. Posting Group");
        VATPostingSetup.Validate("EU Service", false);
        VATPostingSetup.Modify(true);

        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        PurchaseHeader.Validate("Posting Date", ReferenceDate);
        PurchaseHeader.Modify(true);

        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise
        FileName := Library340.RunMake340DeclarationReport(FiscalYear, '', Date2DMY(ReferenceDate, 2), 0.0);

        // Verify
        OperationCodeReport := Library340.ReadOperationalCodeFromFile(FileName, InvoiceNo,
            InvoiceNoStartingPosition, 1, OperationCodeStartingPosition, 1);
        Assert.AreEqual('', OperationCodeReport, IncorrectOperationCode);

        // Tear-Down
        RemoveVendorVATRegNo(Vendor."No.");
    end;

    local procedure Initialize()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Link Doc. Date To Posting Date", true);
        PurchasesPayablesSetup.Modify();
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Link Doc. Date To Posting Date", true);
        SalesReceivablesSetup.Modify();
        IsInitialized := true;
        Commit();
    end;

    local procedure AddPurchaseLineWithVATandEC(var PurchaseHeader: Record "Purchase Header"; var Item: Record Item; VATPercentage: Decimal; ECPercentage: Decimal)
    var
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, PurchaseHeader."VAT Bus. Posting Group", VATProductPostingGroup.Code);
        UpdateVATPostingSetup(VATPostingSetup, VATPercentage, ECPercentage);

        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure AddSalesLineWithVATandEC(var SalesHeader: Record "Sales Header"; var Item: Record Item; VATPercentage: Decimal; ECPercentage: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        SalesLine: Record "Sales Line";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, SalesHeader."VAT Bus. Posting Group", VATProductPostingGroup.Code);
        UpdateVATPostingSetup(VATPostingSetup, VATPercentage, ECPercentage);

        Item.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        Item.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        SalesLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        SalesLine.Modify(true);
    end;

    local procedure ApplyAndPostPayment(InvoiceDocNo: Code[20]; AccountNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal; AccountType: Enum "Gen. Journal Account Type"; GenPostingType: Enum "General Posting Type"; PostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GetGenJnlBatch(GenJournalBatch);
        CreateGenJournal(GenJournalBatch, GenJournalLine, AccountNo, GLAccountNo, GenJournalLine."Document Type"::Payment,
          AccountType, GenPostingType, -1 * Amount, PostingDate);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure ApplyCustomerEntries(CustomerNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange(Open, true);
        if CustLedgerEntry.FindSet() then
            repeat
                CustLedgerEntry.CalcFields("Remaining Amount");
                CustLedgerEntry.Validate("Applies-to ID", CustomerNo);
                CustLedgerEntry.Validate("Amount to Apply", CustLedgerEntry."Remaining Amount");
                CustLedgerEntry.Modify(true);
            until CustLedgerEntry.Next() = 0;
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    local procedure CountNoOfLinesForCustomer(FileName: Text[1024]; CustomerName: Code[20]): Integer
    begin
        exit(LibraryTextFileValidation.CountNoOfLinesWithValue(FileName, CustomerName, 36, StrLen(CustomerName)))
    end;

    local procedure CreateAndPostInvoiceUsingJournal(AccountNo: Code[20]; GLAccountNo: Code[20]; Amount: Decimal; AccountType: Enum "Gen. Journal Account Type"; GenPostingType: Enum "General Posting Type"; PostingDate: Date) InvoiceDocNo: Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GetGenJnlBatch(GenJournalBatch);
        InvoiceDocNo := CreateGenJournal(GenJournalBatch, GenJournalLine, AccountNo, GLAccountNo,
            GenJournalLine."Document Type"::Invoice, AccountType, GenPostingType, Amount, PostingDate);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostSalesInvoice(CustomerNo: Code[20]; PostingDate: Date; Amount: Integer): Code[10]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        FindItemWithOperationCode(Item, '');
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, PostingDate);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        UpdateSalesLineUnitPrice(SalesLine, Amount);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true))
    end;

    local procedure CreateCustomer(var Cust: Record Customer)
    var
        PaymentTerms: Record "Payment Terms";
    begin
        Library340.CreateCustomerVATRegistration(Cust);
        PaymentTerms.FindFirst();
        Cust.Validate("Payment Terms Code", PaymentTerms.Code);
        Cust.Modify(true);
    end;

    local procedure CreateCustomerInCountry(var Cust: Record Customer; Domestic: Boolean; European: Boolean)
    begin
        CreateCustomer(Cust);
        Cust."Country/Region Code" := FindCountryRegion(Domestic, European);
        Cust.Modify(true);
    end;

    local procedure CreateVendor(): Code[20]
    var
        PaymentTerms: Record "Payment Terms";
        Vendor: Record Vendor;
    begin
        Library340.CreateVendorVATRegistration(Vendor);
        Vendor.Validate("Pay-to Vendor No.", Vendor."No.");
        LibraryERM.FindPaymentTerms(PaymentTerms);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Validate("Payment Method Code", FindPaymentMethod(true));
        Vendor.Modify(true);
        exit(Vendor."No.")
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.")
    end;

    local procedure CalculateExpectedAmount(Amount: Decimal) ExpectedAmount: Text[15]
    begin
        Amount := 100 * Abs(Round(Amount, 0.01));  // Value in text file is always considered with 2 decimal places.
        ExpectedAmount := DelChr(DelChr(Format(Amount), '=', '.'), '=', ',');
        ExpectedAmount := PadStr('', 15 - StrLen(ExpectedAmount), '0') + ExpectedAmount;
    end;

    local procedure CreateGenJournal(var GenJournalBatch: Record "Gen. Journal Batch"; var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; GLAccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; GenPostingType: Enum "General Posting Type"; Amount: Decimal; PostingDate: Date): Code[20]
    begin
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", GLAccountNo);
        GenJournalLine.Validate("External Document No.", GenJournalLine."Document No.");
        GenJournalLine.Validate("Gen. Posting Type", GenPostingType);
        GenJournalLine.Validate("Bal. Gen. Posting Type", GenJournalLine."Bal. Gen. Posting Type"::" ");
        GenJournalLine.Validate("Bal. Gen. Bus. Posting Group", '');
        GenJournalLine.Validate("Bal. Gen. Prod. Posting Group", '');
        GenJournalLine.Modify(true);
        exit(GenJournalLine."Document No.")
    end;

    local procedure CreatePurchHeader(var PurchHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendNo: Code[20]; PostingDate: Date)
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, DocumentType, VendNo);
        PurchHeader.Validate("Posting Date", PostingDate);
        PurchHeader.Modify(true);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustNo: Code[20]; PostingDate: Date; OperationCode: Code[1]; UnitPrice: Decimal)
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeader(SalesHeader, DocumentType, CustNo, PostingDate);
        FindItemAndUpdateUnitPrice(Item, OperationCode, UnitPrice);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; CustNo: Code[20]; PostingDate: Date)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
    end;

    local procedure CreateServiceDocument(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; CustNo: Code[20]; PostingDate: Date; OperationCode: Code[1]; UnitPrice: Decimal)
    var
        Item: Record Item;
        ServiceLine: Record "Service Line";
    begin
        CreateServiceHeader(ServiceHeader, DocumentType, CustNo, PostingDate);
        FindItemAndUpdateUnitPrice(Item, OperationCode, UnitPrice);
        CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
    end;

    local procedure CreateServiceHeader(var ServiceHeader: Record "Service Header"; DocumentType: Enum "Service Document Type"; CustNo: Code[20]; PostingDate: Date)
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, DocumentType, CustNo);
        ServiceHeader.Validate("Posting Date", PostingDate);
        ServiceHeader.Modify(true);
    end;

    local procedure CreateServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; Type: Enum "Service Line Type"; ItemNo: Code[20])
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, Type, ItemNo);
        ServiceLine.Validate(Quantity, 1);
        ServiceLine.Modify(true);
    end;

    local procedure CreateUnrealizedVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    var
        VATBusinessPostingGroup: Record "VAT Business Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateVATBusinessPostingGroup(VATBusinessPostingGroup);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusinessPostingGroup.Code, VATProductPostingGroup.Code);
        LibraryERM.FindGLAccount(GLAccount);
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);
        VATPostingSetup.Validate("Sales VAT Unreal. Account", GLAccount."No.");
        VATPostingSetup.Modify(true);
    end;

    local procedure ClearGenJournalLines(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJnlLine.DeleteAll();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DeclarationLinesSalesInvoicePageHandler(var DeclarationLines: TestPage "340 Declaration Lines")
    begin
        DeclarationLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DeclarationLinesNoPropertyTaxAccNoPageHandler(var DeclarationLines: TestPage "340 Declaration Lines")
    var
        DocumentNo: Variant;
        OperationCode: Variant;
        PropertyLocation: Variant;
        PropertyTaxAccNo: Variant;
    begin
        DequeuePropertyTaxDetails(DocumentNo, OperationCode, PropertyLocation, PropertyTaxAccNo);
        UpdateDeclarationLine(DeclarationLines, DocumentNo, OperationCode, PropertyLocation);
        DeclarationLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure DeclarationLinesPropertyTaxAccNoPageHandler(var DeclarationLines: TestPage "340 Declaration Lines")
    var
        DocumentNo: Variant;
        OperationCode: Variant;
        PropertyLocation: Variant;
        PropertyTaxAccNo: Variant;
    begin
        DequeuePropertyTaxDetails(DocumentNo, OperationCode, PropertyLocation, PropertyTaxAccNo);
        UpdateDeclarationLine(DeclarationLines, DocumentNo, OperationCode, PropertyLocation);
        DeclarationLines."Property Tax Account No.".SetValue(PropertyTaxAccNo);
        DeclarationLines.OK().Invoke();
    end;

    local procedure DequeuePropertyTaxDetails(var DocumentNo: Variant; var OperationCode: Variant; var PropertyLocation: Variant; var PropertyTaxAccNo: Variant)
    begin
        LibraryVariableStorage.Dequeue(DocumentNo);
        LibraryVariableStorage.Dequeue(OperationCode);
        LibraryVariableStorage.Dequeue(PropertyLocation);
        LibraryVariableStorage.Dequeue(PropertyTaxAccNo);
    end;

    local procedure EnqueuePropertyTaxDetails(DocumentNo: Code[20]; OperationCode: Code[1]; PropertyLocation: Option; PropertyTaxAccNo: Text[25])
    begin
        LibraryVariableStorage.Enqueue(DocumentNo);
        LibraryVariableStorage.Enqueue(OperationCode);
        LibraryVariableStorage.Enqueue(PropertyLocation);
        LibraryVariableStorage.Enqueue(PropertyTaxAccNo);
    end;

    local procedure FindGLAccount(var GLAccount: Record "G/L Account")
    begin
        GLAccount.SetRange("Account Type", GLAccount."Account Type"::Posting);
        GLAccount.SetRange("Direct Posting", true);
        GLAccount.SetRange("Reconciliation Account", true);
        GLAccount.FindFirst();
    end;

    local procedure FindPaymentMethod(CreateBills: Boolean): Code[10]
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.SetRange("Create Bills", CreateBills);
        PaymentMethod.SetRange("Invoices to Cartera", false);
        LibraryERM.FindPaymentMethod(PaymentMethod);
        exit(PaymentMethod.Code);
    end;

    local procedure FindCountryRegion(Domestic: Boolean; European: Boolean): Code[10]
    var
        CountryRegion: Record "Country/Region";
    begin
        if Domestic then
            exit(ESCountryCode);
        if European then
            CountryRegion.SetFilter("EU Country/Region Code", '<>%1', '')
        else
            CountryRegion.SetRange("EU Country/Region Code", '');
        CountryRegion.SetFilter(Code, '<>%1', ESCountryCode);
        CountryRegion.Next(LibraryRandom.RandInt(CountryRegion.Count));
        exit(CountryRegion.Code);
    end;

    local procedure FindItemAndUpdateUnitPrice(var Item: Record Item; "Code": Code[1]; UnitPrice: Decimal)
    begin
        FindItemWithOperationCode(Item, Code);
        Item.Validate("Unit Price", UnitPrice);
        Item.Modify(true);
    end;

    local procedure FindItemWithOperationCode(var Item: Record Item; "Code": Code[1])
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        OperationCode: Record "Operation Code";
    begin
        if not OperationCode.Get(Code) then
            Library340.CreateOperationCode(OperationCode, Code);
        LibrarySales.FindItem(Item);
        GenProductPostingGroup.Get(Item."Gen. Prod. Posting Group");
        GenProductPostingGroup.Validate("Operation Code", Code);
        GenProductPostingGroup.Modify(true);
    end;

    local procedure FindItemWithDifferentVATPostingGroup(var Item: Record Item; VATProdPostingGroup: Code[20])
    begin
        Clear(Item);
        Item.SetFilter("Inventory Posting Group", '<>%1', '');
        Item.SetFilter("Gen. Prod. Posting Group", '<>%1', '');
        Item.SetRange("Item Tracking Code", '');
        Item.SetRange(Blocked, false);
        Item.SetFilter("Unit Price", '<>%1', 0);
        Item.SetFilter(Reserve, '<>%1', Item.Reserve::Always);
        Item.SetFilter("VAT Prod. Posting Group", '<>%1', VATProdPostingGroup);
        Item.FindSet();
    end;

    local procedure FindMaxVATPostingDate(MaxPostingDate: Date; VATEntry: Record "VAT Entry"): Date
    begin
        VATEntry.SetFilter("Posting Date", '>%1', MaxPostingDate);
        if VATEntry.FindLast() then
            exit(FindMaxVATPostingDate(VATEntry."Posting Date", VATEntry));

        exit(MaxPostingDate)
    end;

    local procedure GetBasisOfCalcForPostingDate(): Date
    var
        VATEntry: Record "VAT Entry";
        MaxPostingDate: Date;
    begin
        VATEntry.FindLast();
        MaxPostingDate := FindMaxVATPostingDate(VATEntry."Posting Date", VATEntry);

        // Posting year should be greater than 2011.
        if 1 + Date2DMY(MaxPostingDate, 3) >= 2011 then
            exit(CalcDate('<1Y>', MaxPostingDate));

        exit(CalcDate(StrSubstNo('<%1Y>', 2012 - Date2DMY(MaxPostingDate, 3)), MaxPostingDate));
    end;

    local procedure GetGenJnlBatch(var GenJnlBatch: Record "Gen. Journal Batch")
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.FindGenJournalTemplate(GenJnlTemplate);
        LibraryERM.FindGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        ClearGenJournalLines(GenJnlBatch)
    end;

    local procedure GetNumberOfLinesByVATandEC(FileName: Text[250]; InvoiceNo: Code[20]; VAT: Decimal; EC: Decimal): Integer
    var
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        File: File;
        InStr: InStream;
        VATReport: Decimal;
        ECReport: Decimal;
        Occurance: Integer;
        Line: Text[1024];
        ECText: Code[4];
        InvoiceNoReport: Code[20];
    begin
        Occurance := 0;
        File.TextMode(true);
        File.Open(FileName);
        File.CreateInStream(InStr);
        while not InStr.EOS do begin
            InStr.ReadText(Line);
            InvoiceNoReport := CopyStr(Line, InvoiceNoStartingPosition, 10);
            if PadStr(InvoiceNoReport, StrLen(InvoiceNoReport)) = InvoiceNo then begin
                Evaluate(VATReport, Format(LibraryTextFileValidation.ReadValue(Line, VATStartingPosition, 4)));
                ECText := LibraryTextFileValidation.ReadValue(Line, ECStartingPosition, 4);
                if ECText <> '' then
                    Evaluate(ECReport, Format(LibraryTextFileValidation.ReadValue(Line, ECStartingPosition, 4)))
                else
                    ECReport := 0;
                if (VAT = VATReport / 100) and (EC = ECReport / 100) then
                    Occurance += 1;
            end;
        end;
        exit(Occurance);
    end;

    local procedure GetPropertyTaxAccNo(): Text[25]
    var
        DeclarationLine: Record "340 Declaration Line";
    begin
        exit(
          CopyStr(
            LibraryUtility.GenerateRandomCode(
              DeclarationLine.FieldNo("Property Tax Account No."), 10744), 1,
            LibraryUtility.GetFieldLength(10744, DeclarationLine.FieldNo("Property Tax Account No.")
              )
            )
          );
    end;

    local procedure GetValidCharacter(): Code[1]
    var
        NonReservedCharacters: array[23] of Char;
        CountOfNonReservedChars: Integer;
    begin
        CountOfNonReservedChars := IdentifyValidCharacters(NonReservedCharacters);
        exit(Format(NonReservedCharacters[LibraryRandom.RandInt(CountOfNonReservedChars)]));
    end;

    local procedure GLAccountsOnRequestPage(CashGLAccount: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        InvoiceDocNo: Code[20];
        Amount: Decimal;
        ReferenceAmount: Decimal;
        FirstPaymentAmount: Decimal;
        ReferenceDate: Date;
    begin
        Initialize();

        // Pre-Setup
        PreSetup(Customer, GLAccount, ReferenceAmount, Amount, FirstPaymentAmount, ReferenceDate);

        // Setup
        InvoiceDocNo := CreateAndPostInvoiceUsingJournal(Customer."No.", GLAccount."No.",
            Amount, GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);
        ApplyAndPostPayment(InvoiceDocNo, Customer."No.", GLAccount."No.", Amount,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", CalcDate('<1Y>', ReferenceDate));

        // Exercise
        asserterror Library340.RunMake340DeclarationReport(Date2DMY(ReferenceDate, 3) + 1,
            CashGLAccount, Date2DMY(ReferenceDate, 2), ReferenceAmount);

        // Verify
        Assert.ExpectedError(NoRecordsFoundError);

        // Tear-Down
        RemoveCustomerVATRegNo(Customer."No.");
    end;

    local procedure IdentifyValidCharacters(var ValidCharacters: array[23] of Char): Integer
    var
        OperationCode: Record "Operation Code";
        Ascii: Integer;
        Index: Integer;
        ValidCharacter: Char;
    begin
        Index := 1;
        for Ascii := 65 to 90 do begin
            // If current character is not C, D, I, R
            ValidCharacter := Ascii;
            if not (Ascii in [67, 68, 73, 82]) and not OperationCode.Get(Format(ValidCharacter)) then begin
                ValidCharacters[Index] := Ascii;
                Index += 1;
            end;
        end;
    end;

    local procedure MapOperationCode(var GenProductPostingGroup: Record "Gen. Product Posting Group"; "Code": Code[1])
    begin
        LibraryERM.CreateGenProdPostingGroup(GenProductPostingGroup);
        GenProductPostingGroup.Validate("Operation Code", Code);
        GenProductPostingGroup.Modify(true);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandlerOK(message: Text[1024])
    begin
        // Dummy Message Handler
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalPageHandler(var DeclarationLines: Page "340 Declaration Lines"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    local procedure PostAndApplyPaymentToAnInvoiceWithBill(GLAccountNo: Code[20]; CustomerNo: Code[20]; Amount: Decimal; InvoicePostingDate: Date; PaymentPostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        SalesHeader: Record "Sales Header";
    begin
        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo, InvoicePostingDate, '', Amount);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        // Post and apply payment with amount > threshold to the above invoice.
        GetGenJnlBatch(GenJournalBatch);
        CreateGenJournal(GenJournalBatch, GenJournalLine, CustomerNo, GLAccountNo, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", -1 * Amount, PaymentPostingDate);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        ApplyCustomerEntries(CustomerNo);
    end;

    local procedure PostSalesInvoiceAndApplyPayment(CustNo: Code[20]; GLAccNo: Code[20]; InvoiceAmount: Decimal; InvoicePostingDate: Date; ApplyAmount: Decimal; ApplyPostingDate: Date) InvoiceDocNo: Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        InvoiceDocNo := CreateAndPostInvoiceUsingJournal(CustNo, GLAccNo, InvoiceAmount,
            GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", InvoicePostingDate);
        ApplyAndPostPayment(
            InvoiceDocNo, CustNo, GLAccNo, ApplyAmount, GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ApplyPostingDate);
    end;

    local procedure PostSalesInvAndApplyPaymentsInPreviousYears(var ReferenceDate: Date; var CustNo: Code[20]; var GLAccNo: Code[20]; var MinPaymentAmount: Decimal)
    var
        Cust: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GLAcc: Record "G/L Account";
        AmountMoreThanMin: Decimal;
        FirstPaymentAmount: Decimal;
        InvoiceDocNo: Code[20];
    begin
        Initialize();

        // Pre-Setup
        ReferenceDate := GetBasisOfCalcForPostingDate();
        MinPaymentAmount := 1000 * LibraryRandom.RandInt(10);
        AmountMoreThanMin := LibraryRandom.RandDecInRange(MinPaymentAmount + 1000, MinPaymentAmount + 2000, 2);
        FirstPaymentAmount := LibraryRandom.RandDecInRange(MinPaymentAmount, AmountMoreThanMin div 1, 2);

        // Setup
        CreateCustomer(Cust);
        LibraryERM.FindGLAccount(GLAcc);

        InvoiceDocNo := PostSalesInvoiceAndApplyPayment(Cust."No.", GLAcc."No.", AmountMoreThanMin,
            ReferenceDate, FirstPaymentAmount, ReferenceDate);
        ApplyAndPostPayment(InvoiceDocNo, Cust."No.", GLAcc."No.", AmountMoreThanMin - FirstPaymentAmount,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", CalcDate('<1Y>', ReferenceDate));

        // Post-Setup
        CustNo := Cust."No.";
        GLAccNo := GLAcc."No.";
    end;

    local procedure PostSalesInvoiceAndAppliedPayment(CustomerNo: Code[20]; GLAccountNo: Text[20]; Amount: Decimal; MaximumAmount: Decimal; ReferenceDate: Date; PaymentPostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceDocNo: Code[20];
    begin
        InvoiceDocNo := CreateAndPostInvoiceUsingJournal(CustomerNo, GLAccountNo, MaximumAmount,
            GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);
        ApplyAndPostPayment(
            InvoiceDocNo, CustomerNo, GLAccountNo, Amount, GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", PaymentPostingDate);
    end;

    local procedure PostTwoSalesInvoicesAndAppliedPayments(CustomerNo: Code[20]; GLAccountNo: Text[20]; Amount: Decimal; MaximumAmount: Decimal; ReferenceDate: Date; PaymentPostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceDocNo1: Code[20];
        InvoiceDocNo2: Code[20];
    begin
        InvoiceDocNo1 := CreateAndPostInvoiceUsingJournal(CustomerNo, GLAccountNo, MaximumAmount,
            GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);
        InvoiceDocNo2 := CreateAndPostInvoiceUsingJournal(CustomerNo, GLAccountNo, MaximumAmount,
            GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", CalcDate('<1M>', ReferenceDate));
        ApplyAndPostPayment(InvoiceDocNo1, CustomerNo, GLAccountNo, Amount, GenJournalLine."Account Type"::Customer,
          "General Posting Type"::" ", PaymentPostingDate);
        ApplyAndPostPayment(InvoiceDocNo2, CustomerNo, GLAccountNo, Amount, GenJournalLine."Account Type"::Customer,
          "General Posting Type"::" ", PaymentPostingDate);
    end;

    local procedure PostMultipleSalesInvoicesAndApplyPayment(CustomerNo: Code[20]; GLAccountNo: Text[20]; MaximumAmount: Decimal; ReferenceDate: Date; FirstPaymentPostingDate: Date; PostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceDocNo: Code[20];
    begin
        InvoiceDocNo := CreateAndPostInvoiceUsingJournal(CustomerNo, GLAccountNo, MaximumAmount,
            GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);
        ApplyAndPostPayment(InvoiceDocNo, CustomerNo, GLAccountNo, MaximumAmount,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", FirstPaymentPostingDate);
        CreateAndPostSalesInvoice(CustomerNo, PostingDate, MaximumAmount);
    end;

    local procedure PostMultiplePartialPayments(CustomerNo: Code[20]; GLAccountNo: Text[20]; MaximumAmount: Decimal; MinimumAmount: Decimal; SecondPaymentAmount: Decimal; ReferenceDate: Date; PaymentPostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceDocNo: Code[20];
    begin
        InvoiceDocNo := CreateAndPostInvoiceUsingJournal(CustomerNo, GLAccountNo, MaximumAmount,
            GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);
        ApplyAndPostPayment(InvoiceDocNo, CustomerNo, GLAccountNo, MinimumAmount, GenJournalLine."Account Type"::Customer,
          "General Posting Type"::" ", ReferenceDate);
        ApplyAndPostPayment(InvoiceDocNo, CustomerNo, GLAccountNo, SecondPaymentAmount,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", PaymentPostingDate);
    end;

    local procedure PreSetup(var Customer: Record Customer; var GLAccount: Record "G/L Account"; var ReferenceAmount: Decimal; var HigherAmount: Decimal; var LowerAmount: Decimal; var ReferenceDate: Date)
    begin
        // 1) ReferenceAmount < LowerAmount < HigherAmount; 2) ReferenceAmount + LowerAmount > HigherAmount
        ReferenceAmount := 1000 * LibraryRandom.RandInt(10);
        LowerAmount := ReferenceAmount div 0.8;
        HigherAmount := (ReferenceAmount + LowerAmount) div 1.3;
        ReferenceDate := GetBasisOfCalcForPostingDate();
        CreateCustomer(Customer);
        LibraryERM.FindGLAccount(GLAccount);
    end;

    local procedure PaymentFromCustomerInCurrentYear(InvoiceAmount: Decimal; PaymentAmount: Decimal; MinPaymentAmount: Decimal; ResultAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        Customer: Record Customer;
        GLAccount: Record "G/L Account";
        ExportedFileName: Text[1024];
        Line: Text[1024];
        InvoiceDocNo: Code[20];
        ReferenceDate: Date;
        FiscalYear: Integer;
    begin
        Initialize();

        // Pre-Setup
        ReferenceDate := GetBasisOfCalcForPostingDate();
        FiscalYear := Date2DMY(ReferenceDate, 3);

        // Setup
        CreateCustomer(Customer);
        LibraryERM.FindGLAccount(GLAccount);

        InvoiceDocNo := CreateAndPostInvoiceUsingJournal(Customer."No.", GLAccount."No.", InvoiceAmount,
            GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);
        ApplyAndPostPayment(InvoiceDocNo, Customer."No.", GLAccount."No.", PaymentAmount,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);

        // Exercise
        ExportedFileName := Library340.RunMake340DeclarationReport(FiscalYear, GLAccount."No.",
            Date2DMY(ReferenceDate, 2), MinPaymentAmount);

        // Post-Exercise
        Line := Library340.ReadCustomerLine(ExportedFileName, Customer.Name);

        // Verify
        VerifyCashCollectableValues(Line, ResultAmount, Format(FiscalYear));

        // Tear-Down
        RemoveCustomerVATRegNo(Customer."No.");
    end;

    local procedure RemoveCustomerVATRegNo(CustNo: Code[20])
    var
        Cust: Record Customer;
    begin
        Cust.Get(CustNo);
        Cust.Validate("VAT Registration No.", '');
        Cust.Modify(true);
    end;

    local procedure RemoveVendorVATRegNo(VendorNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(VendorNo);
        Vendor.Validate("VAT Registration No.", '');
        Vendor.Modify(true);
    end;

    local procedure SalesInvoiceCountrySpecific(Domestic: Boolean; European: Boolean)
    var
        CompanyInformation: Record "Company Information";
        Cust: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GLAcc: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        ActualCompanyVATNo: Text;
        ActualCustVATNo: Text;
        ActualLegalRepresentativeVATNo: Text;
        BlankVATNo: Text[9];
        ExportedFileName: Text[1024];
        InvoiceDocNo: Code[20];
        Line: Text[1024];
        ReferenceAmount: Decimal;
        ReferenceDate: Date;
    begin
        Initialize();

        // Pre-Setup
        ReferenceDate := GetBasisOfCalcForPostingDate();
        ReferenceAmount := 1000 * LibraryRandom.RandDec(10, 2);

        // Setup
        CreateCustomerInCountry(Cust, Domestic, European);
        LibraryERM.FindGLAccount(GLAcc);

        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, Cust."No.",
          ReferenceDate, GetValidCharacter(), LibraryRandom.RandDec(1000, 2));
        InvoiceDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        ApplyAndPostPayment(InvoiceDocNo, Cust."No.", GLAcc."No.", ReferenceAmount,
          GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);

        // Exercise
        ExportedFileName := Library340.RunMake340DeclarationReport(Date2DMY(ReferenceDate, 3), GLAcc."No.",
            Date2DMY(ReferenceDate, 2), ReferenceAmount);

        // Post-Exercise
        Line := Library340.ReadCustomerLine(ExportedFileName, Cust.Name);

        // Verify
        CompanyInformation.Get();
        ActualCompanyVATNo := Library340.ReadPresenterIDCompanyVATNo(Line);
        Assert.AreEqual(CompanyInformation."VAT Registration No.", ActualCompanyVATNo, IncorrectCompanyVATRegNo);

        BlankVATNo := PadStr('', 9, ' ');
        ActualCustVATNo := Library340.ReadSpanishCustVATNo(Line);
        if Domestic then
            Assert.AreEqual(Cust."VAT Registration No.", DelChr(ActualCustVATNo, '=', ' '), IncorrectCustomerVATRegNo)
        else
            Assert.AreEqual(BlankVATNo, ActualCustVATNo, IncorrectCustomerVATRegNo);

        ActualLegalRepresentativeVATNo := Library340.ReadLegalRepresentativeVATNo(Line);
        Assert.AreEqual(BlankVATNo, ActualLegalRepresentativeVATNo, IncorrectLegalRepVATNo);

        // Tear-Down
        RemoveCustomerVATRegNo(Cust."No.");
    end;

    local procedure SalesInvoicePropertyTax(PropertyLocation: Option; UsePropertyTaxAccNo: Boolean)
    var
        Cust: Record Customer;
        GLAcc: Record "G/L Account";
        SalesHeader: Record "Sales Header";
        ExportedFileName: Text[1024];
        FiscalYear: Integer;
        InvoiceDocNo: Code[20];
        Line: Text[1024];
        PropertyTaxAccNo: Text[25];
        ReferenceDate: Date;
    begin
        Initialize();

        // Pre-Setup
        ReferenceDate := GetBasisOfCalcForPostingDate();
        FiscalYear := Date2DMY(ReferenceDate, 3);
        PropertyTaxAccNo := GetPropertyTaxAccNo();

        // Setup
        CreateCustomer(Cust);
        LibraryERM.FindGLAccount(GLAcc);

        CreateSalesDocument(SalesHeader, SalesHeader."Document Type"::Invoice, Cust."No.", ReferenceDate, OperationCodeR,
          LibraryRandom.RandDec(1000, 2));
        InvoiceDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Pre-Exercise
        EnqueuePropertyTaxDetails(InvoiceDocNo, OperationCodeR, PropertyLocation, PropertyTaxAccNo);

        // Exercise
        ExportedFileName := Library340.RunMake340DeclarationReport(FiscalYear, GLAcc."No.", Date2DMY(ReferenceDate, 2),
            LibraryRandom.RandDecInRange(5000, 7000, 2));

        // Post-Exericse
        Line := Library340.ReadCustomerLine(ExportedFileName, Cust.Name);

        // Verify
        VerifyPropertyTaxLine(Line, OperationCodeR, Format(PropertyLocation), PropertyTaxAccNo, UsePropertyTaxAccNo);

        // Tear-Down
        RemoveCustomerVATRegNo(Cust."No.");
    end;

    local procedure ServiceInvoicePropertyTax(PropertyLocation: Option; UsePropertyTaxAccNo: Boolean)
    var
        Cust: Record Customer;
        GLAcc: Record "G/L Account";
        ServiceHeader: Record "Service Header";
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ExportedFileName: Text[1024];
        FiscalYear: Integer;
        InvoiceDocNo: Code[20];
        Line: Text[1024];
        ReferenceDate: Date;
        PropertyTaxAccNo: Text[25];
    begin
        Initialize();

        // Pre-Setup
        ReferenceDate := GetBasisOfCalcForPostingDate();
        FiscalYear := Date2DMY(ReferenceDate, 3);
        PropertyTaxAccNo := GetPropertyTaxAccNo();

        // Setup
        CreateCustomer(Cust);
        LibraryERM.FindGLAccount(GLAcc);

        CreateServiceDocument(ServiceHeader, ServiceHeader."Document Type"::Invoice, Cust."No.", ReferenceDate, OperationCodeR,
          LibraryRandom.RandDec(1000, 2));
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // Post-Setup
        ServiceInvoiceHeader.FindLast();
        InvoiceDocNo := ServiceInvoiceHeader."No.";

        // Pre-Exercise
        EnqueuePropertyTaxDetails(InvoiceDocNo, OperationCodeR, PropertyLocation, PropertyTaxAccNo);

        // Exercise
        ExportedFileName := Library340.RunMake340DeclarationReport(FiscalYear, GLAcc."No.", Date2DMY(ReferenceDate, 2),
            LibraryRandom.RandDecInRange(5000, 7000, 2));

        // Post-Exercise
        Line := Library340.ReadCustomerLine(ExportedFileName, Cust.Name);

        // Verify
        VerifyPropertyTaxLine(Line, OperationCodeR, Format(PropertyLocation), PropertyTaxAccNo, UsePropertyTaxAccNo);

        // Tear-Down
        RemoveCustomerVATRegNo(Cust."No.");
    end;

    local procedure SetCustomerPostingGroupAndPaymentMethod(var Customer: Record Customer; VATBusPostingGroupCode: Code[20]; GenBusPostingGroupCode: Code[20])
    begin
        Customer.Validate("VAT Bus. Posting Group", VATBusPostingGroupCode);
        Customer.Validate("Gen. Bus. Posting Group", GenBusPostingGroupCode);
        Customer.Validate("Payment Method Code", FindPaymentMethod(true));
        Customer.Modify(true);
    end;

    local procedure UnmapAndDeleteOperationCode(OperationCode: Record "Operation Code"; GenProductPostingGroup: Record "Gen. Product Posting Group")
    begin
        GenProductPostingGroup.Validate("Operation Code", '');
        GenProductPostingGroup.Modify(true);
        OperationCode.Delete(true);
    end;

    local procedure UnapplyCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; PostingDate: Date)
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Posting Date", PostingDate);
        CustLedgerEntry.FindLast();
        LibraryERMUnapply.UnapplyCustomerLedgerEntry(CustLedgerEntry);
    end;

    local procedure UpdateDeclarationLine(var DeclarationLines: TestPage "340 Declaration Lines"; DocumentNo: Code[20]; OperationCode: Code[1]; PropertyLocation: Option)
    begin
        DeclarationLines."Document No.".AssertEquals(DocumentNo);
        DeclarationLines."Operation Code".SetValue(OperationCode);
        DeclarationLines."Property Location".SetValue(PropertyLocation);
    end;

    local procedure UpdatePaymentMethod(PaymentMethodCode: Code[20]; GLAccountNo: Code[20])
    var
        PaymentMethod: Record "Payment Method";
    begin
        PaymentMethod.Get(PaymentMethodCode);
        PaymentMethod.Validate("Bal. Account No.", GLAccountNo);
        PaymentMethod.Modify(true);
    end;

    local procedure UpdateSalesLineUnitPrice(var SalesLine: Record "Sales Line"; UnitPrice: Decimal)
    begin
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure UpdateVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATPercentage: Decimal; ECPercentage: Decimal)
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.FindGLAccount(GLAccount);
        VATPostingSetup."VAT Identifier" := VATPostingSetup."VAT Prod. Posting Group";
        VATPostingSetup.Validate("VAT %", VATPercentage);
        VATPostingSetup.Validate("EC %", ECPercentage);
        VATPostingSetup.Validate("Sales VAT Account", GLAccount."No.");
        VATPostingSetup.Validate("Purchase VAT Account", GLAccount."No.");
        VATPostingSetup.Modify(true)
    end;

    local procedure VerifyPropertyTaxLine(Line: Text[1024]; OperationCode: Code[1]; PropertyLocation: Text[1]; PropertyTaxAccNo: Text[25]; UsePropertyTaxAccNo: Boolean)
    var
        ActualOperationCode: Code[1];
        ActualPropertylocation: Text[1];
        ActualPropertyTaxAccNo: Text[25];
    begin
        ActualOperationCode := Library340.ReadOperationCode(Line);
        Assert.AreEqual(OperationCode, ActualOperationCode, IncorrectOperationCode);

        ActualPropertylocation := Library340.ReadPropertyLocation(Line);
        Assert.AreEqual(PropertyLocation, ActualPropertylocation, IncorrectPropertyLocation);

        if UsePropertyTaxAccNo then begin
            ActualPropertyTaxAccNo := DelChr(Library340.ReadPropertyTaxAccNo(Line), '=', ' ');
            Assert.AreEqual(PropertyTaxAccNo, ActualPropertyTaxAccNo, IncorrectPropertyTaxAccNo);
        end;
    end;

    local procedure VerifyCashCollectableValues(Line: Text[1024]; Amount: Decimal; ExpectedNumericExercise: Text[4])
    var
        ActualAmount: Text[15];
        ActualNumericExercise: Text[4];
        ExpectedAmount: Text[15];
    begin
        ActualAmount := Library340.ReadCashCollectableAmountInteger(Line);
        ExpectedAmount := CalculateExpectedAmount(Amount);
        Assert.AreEqual(ExpectedAmount, ActualAmount, IncorrectCashCollectablesAmount);

        ActualNumericExercise := Library340.ReadNumericExercise(Line);
        Assert.AreEqual(ExpectedNumericExercise, ActualNumericExercise, IncorrectNumericExercise);

        // Verify other fields in the exported file.
        VerifyRecords(Line, 99, 1, BookTypeCode);
        VerifyRecords(Line, 100, 1, ' ');
        VerifyRecords(Line, 109, 8, PadStr('', 8, '0'));
        VerifyRecords(Line, 117, 5, PadStr('', 5, '0'));
        VerifyRecords(Line, 123, 13, PadStr('', 13, '0'));
        VerifyRecords(Line, 137, 13, PadStr('', 13, '0'));
        VerifyRecords(Line, 151, 13, PadStr('', 13, '0'));
        VerifyRecords(Line, 165, 13, PadStr('', 13, '0'));
        VerifyRecords(Line, 236, 10, PadStr('', 10, '0'));
        VerifyRecords(Line, 366, 5, PadStr('', 5, '0'));
        VerifyRecords(Line, 372, 13, PadStr('', 13, '0'));
    end;

    local procedure VerifyNoOfRegisters(MinPaymentAmount: Decimal; Amount: Decimal; ExpectedNoOfRegisters: Text)
    var
        Cust: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        GLAcc: Record "G/L Account";
        ExportedFileName: Text[1024];
        InvoiceDocNo: Code[20];
        ReferenceDate: Date;
        ActualNoOfRegisters: Text[9];
    begin
        // Pre-Setup
        ReferenceDate := GetBasisOfCalcForPostingDate();

        // Setup
        CreateCustomer(Cust);
        LibraryERM.FindGLAccount(GLAcc);

        InvoiceDocNo := CreateAndPostSalesInvoice(Cust."No.", ReferenceDate, Amount);
        ApplyAndPostPayment(
            InvoiceDocNo, Cust."No.", GLAcc."No.", Amount, GenJournalLine."Account Type"::Customer, "General Posting Type"::" ", ReferenceDate);

        // Exercise
        ExportedFileName := Library340.RunMake340DeclarationReport(Date2DMY(ReferenceDate, 3), GLAcc."No.",
            Date2DMY(ReferenceDate, 2), MinPaymentAmount);

        // Verify
        ActualNoOfRegisters := Library340.ReadNoOfRegisters(Library340.ReadType1RecordLine(ExportedFileName));
        Assert.AreEqual(ExpectedNoOfRegisters, ActualNoOfRegisters, IncorrectNoOfRegisters);

        // Tear-Down
        RemoveCustomerVATRegNo(Cust."No.")
    end;

    local procedure VerifyRecords(Line: Text[1024]; StartingPosition: Integer; Length: Integer; ExpectedValue: Text[1024])
    var
        FieldValue: Text[1024];
    begin
        FieldValue := LibraryTextFileValidation.ReadValue(Line, StartingPosition, Length);
        Assert.AreEqual(ExpectedValue, FieldValue, StrSubstNo(NotEqualValues, ExpectedValue, FieldValue));
    end;

    local procedure VerifySalesInvoiceMultiYearPayments(Line: Text[1024]; Amount: Decimal; Year: Integer)
    var
        ActualAmount: Decimal;
        ActualNumericExercise: Text[4];
        ActualOperationCode: Code[1];
    begin
        ActualOperationCode := Library340.ReadOperationCode(Line);
        Assert.AreEqual('', ActualOperationCode, IncorrectOperationCode);

        ActualAmount := Library340.ReadCashCollectablesAsAbsolute(Line);
        Assert.AreEqual(Amount, ActualAmount, IncorrectCashCollectablesAmount);

        ActualNumericExercise := Library340.ReadNumericExercise(Line);
        Assert.AreEqual(Format(Year), ActualNumericExercise, IncorrectNumericExercise);
    end;

    local procedure VerifyUnappliedInvoiceValues(Line: Text[1024])
    begin
        VerifyRecords(Line, 411, 15, PadStr('', 15, '0'));
        VerifyRecords(Line, 426, 4, PadStr('', 4, '0'));
    end;
}

