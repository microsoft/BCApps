codeunit 147539 "Bill - Group Test Report Tests"
{
    // Cartera Receivables Basic Scenarios

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        LibraryCarteraReceivables: Codeunit "Library - Cartera Receivables";
        LibraryERM: Codeunit "Library - ERM";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        FileManagement: Codeunit "File Management";
        ErrorElementNameTxt: Label 'ErrorText_Number_';
        CarteraDocumentErrorElementNameTxt: Label 'ErrorText_Number__Control56';
        DocRemainingAmountElementNameTxt: Label 'Doc__Remaining_Amount_';
        BillGroupNoElementNameTxt: Label 'BillGr_No_';
        BillGroupBankAccNoElementNameTxt: Label 'BillGr_Bank_Account_No_';
        ValueMustBeTxt: Label '%1 must be %2.';
        ValueCannotBeTxt: Label '%1 cannot be %2.';
        LocalCurrencyCode: Code[10];

    [Test]
    [HandlerFunctions('CheckDiscountCreditLimitModalPageHandler,BillGroupTestReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CorrectBillGroupNoErrors()
    var
        BillGroup: Record "Bill Group";
        TotalAmount: Decimal;
    begin
        Initialize();

        CreateBillGroupTestSetupData(BillGroup, TotalAmount);
        InvokeBillGroupTestReport(BillGroup);

        LibraryReportDataset.LoadDataSetFile();

        VerifyReportData(BillGroup, TotalAmount);
        Assert.AreEqual(0, CountErrorsInReportDataset(), 'There should be no erros reported by Bill Group test report');
    end;

    [Test]
    [HandlerFunctions('CheckDiscountCreditLimitModalPageHandler,BillGroupTestReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CorrectBillGroupNoErrorsFromList()
    var
        BillGroup: Record "Bill Group";
        TotalAmount: Decimal;
    begin
        Initialize();

        CreateBillGroupTestSetupData(BillGroup, TotalAmount);
        InvokeBillGroupTestReportFromList(BillGroup);

        LibraryReportDataset.LoadDataSetFile();

        VerifyReportData(BillGroup, TotalAmount);
        Assert.AreEqual(0, CountErrorsInReportDataset(), 'There should be no erros reported by Bill Group test report');
    end;

    [Test]
    [HandlerFunctions('BillGroupTestReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CorrectBillGroupFactoringNoRiskNoErrors()
    var
        BillGroup: Record "Bill Group";
        TotalAmount: Decimal;
    begin
        Initialize();

        CreateBillGroupFactoringTestSetupData(BillGroup, TotalAmount, BillGroup.Factoring::Unrisked);
        InvokeBillGroupTestReport(BillGroup);

        LibraryReportDataset.LoadDataSetFile();

        VerifyReportData(BillGroup, TotalAmount);
        Assert.AreEqual(0, CountErrorsInReportDataset(), 'There should be no erros reported by Bill Group test report');
    end;

    [Test]
    [HandlerFunctions('BillGroupTestReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CorrectBillGroupFactoringWithRiskNoErrors()
    var
        BillGroup: Record "Bill Group";
        TotalAmount: Decimal;
    begin
        Initialize();

        CreateBillGroupFactoringTestSetupData(BillGroup, TotalAmount, BillGroup.Factoring::Risked);
        InvokeBillGroupTestReport(BillGroup);

        LibraryReportDataset.LoadDataSetFile();

        VerifyReportData(BillGroup, TotalAmount);
        Assert.AreEqual(0, CountErrorsInReportDataset(), 'There should be no erros reported by Bill Group test report');
    end;

    [Test]
    [HandlerFunctions('CheckDiscountCreditLimitModalPageHandler,BillGroupTestReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CreditLimitWillBeExceededError()
    var
        BillGroup: Record "Bill Group";
        BankAccount: Record "Bank Account";
        TotalAmount: Decimal;
    begin
        Initialize();

        // Setup
        CreateBillGroupTestSetupData(BillGroup, TotalAmount);

        // Create errors
        BankAccount.Get(BillGroup."Bank Account No.");
        BankAccount.Validate("Credit Limit for Discount", TotalAmount / 2);
        BankAccount.Modify();

        // Excercise
        InvokeBillGroupTestReport(BillGroup);

        // Verify
        LibraryReportDataset.LoadDataSetFile();
        VerifyReportData(BillGroup, TotalAmount);
        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(ErrorElementNameTxt, 'The credit limit will be exceeded.');

        Assert.AreEqual(1, CountErrorsInReportDataset(), 'There should be one error reported by Bill Group test report');
    end;

    [Test]
    [HandlerFunctions('CheckDiscountCreditLimitModalPageHandler,BillGroupTestReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure BillGroupWronglySpecifiedErrors()
    var
        BillGroup: Record "Bill Group";
        TotalAmount: Decimal;
    begin
        Initialize();

        // Setup
        CreateBillGroupTestSetupData(BillGroup, TotalAmount);

        // Create errors
        // Error 1 - it is not printed
        BillGroup.Validate("No. Printed", 0);

        // Error 2 - Bank account no. not specified
        BillGroup.Validate("Bank Account No.", '');
        BillGroup.Modify(true);

        // Excercise
        InvokeBillGroupTestReport(BillGroup);

        // Verify
        LibraryReportDataset.LoadDataSetFile();
        VerifyReportData(BillGroup, TotalAmount);

        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(ErrorElementNameTxt, 'The bill group has not been printed.');

        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(
          ErrorElementNameTxt, StrSubstNo('%1 must be specified.', BillGroup.FieldCaption("Bank Account No.")));

        Assert.AreEqual(2, CountErrorsInReportDataset(), 'There should be two errors reported by Bill Group test report');
    end;

    [Test]
    [HandlerFunctions('CheckDiscountCreditLimitModalPageHandler,BillGroupTestReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure BillGroupIsEmptyError()
    var
        BillGroup: Record "Bill Group";
        BankAccount: Record "Bank Account";
        Customer: Record Customer;
    begin
        Initialize();

        // Setup
        CreateBillGroup(BillGroup, BankAccount, Customer);
        BillGroup.Validate("No. Printed", 1);
        BillGroup.Modify(true);

        // Excercise
        InvokeBillGroupTestReport(BillGroup);

        // Verify
        LibraryReportDataset.LoadDataSetFile();
        VerifyReportData(BillGroup, 0);

        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(ErrorElementNameTxt, 'The bill group is empty.');

        Assert.AreEqual(1, CountErrorsInReportDataset(), 'The bill group is empty.');
    end;

    [Test]
    [HandlerFunctions('CheckDiscountCreditLimitModalPageHandler,BillGroupTestReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure BankAccountWronglySpecifiedErrors()
    var
        BillGroup: Record "Bill Group";
        BankAccount: Record "Bank Account";
        Currency: Record Currency;
        TotalAmount: Decimal;
    begin
        Initialize();

        // Setup
        CreateBillGroupTestSetupData(BillGroup, TotalAmount);

        // Create errors
        BankAccount.Get(BillGroup."Bank Account No.");

        // Error 1 - different currency codes
        LibraryERM.CreateCurrency(Currency);
        BankAccount.Validate("Currency Code", Currency.Code);

        // Error 2 - operation fees code is blank
        BankAccount.Validate("Operation Fees Code", '');

        // Error 3 - Customer ratings code is blank
        BankAccount.Validate("Customer Ratings Code", '');

        // Error 4 - Company is blocked
        BankAccount.Validate(Blocked, true);

        // Error 5 - Bank account posting group is blank
        BankAccount.Validate("Bank Acc. Posting Group", '');

        BankAccount.Modify(true);

        // Excercise
        InvokeBillGroupTestReport(BillGroup);
        LibraryReportDataset.LoadDataSetFile();

        // Verify
        VerifyReportData(BillGroup, TotalAmount);

        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(
          ErrorElementNameTxt, StrSubstNo('Currency Code must be %1 in Bank Account %2.', BillGroup."Currency Code", BankAccount."No."));

        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(
          ErrorElementNameTxt, StrSubstNo('Operation Fees Code must be specified in Bank Account %1.', BankAccount."No."));

        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(
          ErrorElementNameTxt, StrSubstNo('Customer Ratings Code must be specified in Bank Account %1.', BankAccount."No."));

        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(
          ErrorElementNameTxt, StrSubstNo('%1 %2 is blocked.', BankAccount.TableCaption(), BillGroup."Bank Account No."));

        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(ErrorElementNameTxt,
          StrSubstNo(
            '%1 %2 has no %3.',
            BankAccount.TableCaption(),
            BillGroup."Bank Account No.",
            BankAccount.FieldCaption("Bank Acc. Posting Group")));

        Assert.AreEqual(5, CountErrorsInReportDataset(), 'There should be 5 errors reported by Bill Group test report');
    end;

    [Test]
    [HandlerFunctions('CheckDiscountCreditLimitModalPageHandler,BillGroupTestReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CarteraDocumentWronglySpecifiedErrors()
    var
        BillGroup: Record "Bill Group";
        Currency: Record Currency;
        CarteraDoc: Record "Cartera Doc.";
        TotalAmount: Decimal;
    begin
        Initialize();

        // Setup
        CreateCarteraDocumentTestSetupData(BillGroup, TotalAmount, CarteraDoc);

        // Create errors
        // Error 1 - currency is different
        LibraryERM.CreateCurrency(Currency);
        CarteraDoc.Validate("Currency Code", Currency.Code);

        // Error 2 - Remaining amount is zero
        CarteraDoc.Validate("Remaining Amt. (LCY)", 0);

        // Error 3 - It is not accepted
        CarteraDoc.Validate(Accepted, CarteraDoc.Accepted::No);

        // Error 4 - document type is different than bill and Factoring is not specified
        CarteraDoc.Validate("Document Type", CarteraDoc."Document Type"::Invoice);

        // Error 5 - document date is before bill group posting date
        CarteraDoc.Validate("Due Date", CalcDate('<-2M>', BillGroup."Posting Date"));
        CarteraDoc.Modify(true);

        // Excercise
        InvokeBillGroupTestReport(BillGroup);
        LibraryReportDataset.LoadDataSetFile();

        // Verify
        VerifyReportData(BillGroup, 0);

        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(
          CarteraDocumentErrorElementNameTxt,
          StrSubstNo(ValueMustBeTxt, CarteraDoc.FieldCaption("Currency Code"), BillGroup."Currency Code")
          );

        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(
          CarteraDocumentErrorElementNameTxt,
          StrSubstNo('%1 must not be zero.', CarteraDoc.FieldCaption("Remaining Amt. (LCY)"))
          );

        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(
          CarteraDocumentErrorElementNameTxt,
          'This Bill is due before the posting date of the bill group. It should not be included in a group for discount.'
          );

        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(
          CarteraDocumentErrorElementNameTxt,
          StrSubstNo(ValueCannotBeTxt, CarteraDoc.FieldCaption(Accepted), false)
          );

        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(
          CarteraDocumentErrorElementNameTxt,
          StrSubstNo(ValueMustBeTxt, CarteraDoc.FieldCaption("Document Type"), CarteraDoc."Document Type"::Bill)
          );

        Assert.AreEqual(6, CountErrorsInReportDataset(), 'There should be 6 errors reported by Bill Group test report');
    end;

    [Test]
    [HandlerFunctions('CheckDiscountCreditLimitModalPageHandler,BillGroupTestSaveAsPDFReportRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PrintBillGroupTest()
    var
        BillGroup: Record "Bill Group";
        TotalAmount: Decimal;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 333888] Report "Bill Group Test" can be printed without RDLC rendering errors
        Initialize();

        CreateBillGroupTestSetupData(BillGroup, TotalAmount);
        // [WHEN] Report "Bill Group Test" is being printed to PDF
        InvokeBillGroupTestReport(BillGroup);
        // [THEN] No RDLC rendering errors
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LocalCurrencyCode := '';
    end;

    [Normal]
    local procedure CreateBillGroupTestSetupData(var BillGroup: Record "Bill Group"; var TotalAmount: Decimal)
    var
        CarteraDoc: Record "Cartera Doc.";
    begin
        CreateCarteraDocumentTestSetupData(BillGroup, TotalAmount, CarteraDoc);
    end;

    local procedure CreateBillGroupFactoringTestSetupData(var BillGroup: Record "Bill Group"; var TotalAmount: Decimal; Factoring: Option)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        BankAccount: Record "Bank Account";
        CarteraDoc: Record "Cartera Doc.";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DocumentNo: Code[20];
    begin
        LibraryCarteraReceivables.CreateFactoringCustomer(Customer, LocalCurrencyCode);
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        LibraryCarteraReceivables.CreateBankAccount(BankAccount, LocalCurrencyCode);
        LibraryCarteraReceivables.CreateFactoringOperationFeesForBankAccount(BankAccount);
        LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccount."No.", BillGroup."Dealing Type"::Collection);
        BillGroup.Validate(Factoring, Factoring);
        BillGroup.Validate("No. Printed", 1);
        BillGroup.Modify(true);

        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, DocumentNo, Customer."No.", BillGroup."No.");
        TotalAmount :=
          LibraryCarteraReceivables.GetPostedSalesInvoiceAmount(Customer."No.", DocumentNo, CustLedgerEntry."Document Type"::Invoice);
    end;

    [Normal]
    local procedure CreateCarteraDocumentTestSetupData(var BillGroup: Record "Bill Group"; var TotalAmount: Decimal; var CarteraDoc: Record "Cartera Doc.")
    var
        Customer: Record Customer;
        BankAccount: Record "Bank Account";
    begin
        CreateBillGroup(BillGroup, BankAccount, Customer);
        CreateCarteraDocument(CarteraDoc, Customer, BillGroup, TotalAmount);
        BankAccount.Validate("Credit Limit for Discount", TotalAmount);
        BankAccount.Modify(true);
        BillGroup.Validate("No. Printed", 1);
        BillGroup.Modify(true);
    end;

    local procedure CreateCarteraDocument(var CarteraDoc: Record "Cartera Doc."; Customer: Record Customer; BillGroup: Record "Bill Group"; var TotalAmount: Decimal)
    var
        SalesHeader: Record "Sales Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DocumentNo: Code[20];
    begin
        LibraryCarteraReceivables.CreateSalesInvoice(SalesHeader, Customer."No.");
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryCarteraReceivables.AddCarteraDocumentToBillGroup(CarteraDoc, DocumentNo, Customer."No.", BillGroup."No.");
        TotalAmount :=
          LibraryCarteraReceivables.GetPostedSalesInvoiceAmount(Customer."No.", DocumentNo, CustLedgerEntry."Document Type"::Invoice);
    end;

    [Normal]
    local procedure CreateBillGroup(var BillGroup: Record "Bill Group"; var BankAccount: Record "Bank Account"; var Customer: Record Customer)
    begin
        LibraryCarteraReceivables.CreateCarteraCustomer(Customer, LocalCurrencyCode);
        LibraryCarteraReceivables.CreateBankAccount(BankAccount, LocalCurrencyCode);
        LibraryCarteraReceivables.CreateDiscountOperationFeesForBankAccount(BankAccount);
        LibraryCarteraReceivables.CreateBillGroup(BillGroup, BankAccount."No.", BillGroup."Dealing Type"::Discount);
    end;

    local procedure InvokeBillGroupTestReport(var BillGroup: Record "Bill Group")
    var
        BillGroups: TestPage "Bill Groups";
    begin
        BillGroups.OpenEdit();
        BillGroups.GotoRecord(BillGroup);

        // Test report action
        Commit();
        BillGroups.TestReport.Invoke();
    end;

    local procedure InvokeBillGroupTestReportFromList(var BillGroup: Record "Bill Group")
    var
        BillGroupsList: TestPage "Bill Groups List";
    begin
        BillGroupsList.OpenEdit();
        BillGroupsList.GotoRecord(BillGroup);

        // Test report action
        Commit();
        BillGroupsList.TestReport.Invoke();
    end;

    local procedure CountErrorsInReportDataset(): Integer
    var
        "Count": Integer;
    begin
        Count := 0;
        LibraryReportDataset.Reset();

        while LibraryReportDataset.GetNextRow() do
            if LibraryReportDataset.CurrentRowHasElement(ErrorElementNameTxt) or
               LibraryReportDataset.CurrentRowHasElement(CarteraDocumentErrorElementNameTxt)
            then
                Count := Count + 1;

        exit(Count);
    end;

    local procedure VerifyReportData(BillGroup: Record "Bill Group"; TotalAmount: Decimal)
    begin
        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(BillGroupNoElementNameTxt, BillGroup."No.");

        LibraryReportDataset.Reset();
        LibraryReportDataset.AssertElementWithValueExists(BillGroupBankAccNoElementNameTxt, BillGroup."Bank Account No.");

        LibraryReportDataset.Reset();
        if TotalAmount > 0 then
            LibraryReportDataset.AssertElementWithValueExists(DocRemainingAmountElementNameTxt, TotalAmount);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BillGroupTestReportRequestPageHandler(var BillGroupTest: TestRequestPage "Bill Group - Test")
    begin
        BillGroupTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BillGroupTestSaveAsPDFReportRequestPageHandler(var BillGroupTest: TestRequestPage "Bill Group - Test")
    begin
        BillGroupTest.SaveAsPdf(FileManagement.ServerTempFileName('.pdf'));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CheckDiscountCreditLimitModalPageHandler(var CheckDiscountCreditLimit: TestPage "Check Discount Credit Limit")
    begin
        CheckDiscountCreditLimit.Yes().Invoke();
    end;
}

