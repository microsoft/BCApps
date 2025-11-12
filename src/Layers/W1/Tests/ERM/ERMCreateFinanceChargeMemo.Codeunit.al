codeunit 134911 "ERM Create Finance Charge Memo"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [ERM] [Finance Charge Memo]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        ActiveDirectoryMockEvents: Codeunit "Active Directory Mock Events";
        MIRHelperFunctions: Codeunit "MIR - Helper Functions";
        IsInitialized: Boolean;
        AmountErr: Label 'Amount must be %1 for Finance Charge Header No: %2.';
        FinChrgMemoHeaderFilterTxt: Label 'Finance Charge Memo: No.: %1, Customer No.: %2';
        WrongNumberOfMemosErr: Label 'Wrong number of created Finance Charge Memos.';
        WrongNumberOfPrintedDocsErr: Label 'Wrong number of printed Finance Charge Memos.';
        PrintDocRef: Option " ",Print,Email;
        EmailTxt: Label 'abc@microsoft.com', Locked = true;
        ProceedOnIssuingWithInvRoundingQst: Label 'The invoice rounding amount will be added to the finance charge memo when it is posted according to invoice rounding setup.\Do you want to continue?';
        GLEntryMustNotBeEmpty: Label 'GL Entry must not be empty.';

    [Test]
    [Scope('OnPrem')]
    procedure FinChargeMemoWithCurrency()
    begin
        // Create and Issue Finance Charge Memo with Currency.
        // Setup.
        Initialize();
        FinanceChargeMemo(CreateCurrencyAndUpdateExcRate());
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FinChargeMemoWithOutCurrency()
    begin
        // Create and Issue Finance Charge Memo without Currency.
        // Setup.
        Initialize();
        FinanceChargeMemo('');
    end;

    local procedure FinanceChargeMemo(CurrencyCode: Code[10])
    var
        SalesHeader: Record "Sales Header";
        FinanceChargeTerms: Record "Finance Charge Terms";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeMemoAmount: Decimal;
        SalesLineAmount: Decimal;
    begin
        // Create and Post Sales Invoice with Currency and Create Finance Charge Memo.
        SalesLineAmount := CreateAndPostSalesInvoice(SalesHeader, CurrencyCode);
        GetFinanceChargeTerms(FinanceChargeTerms, SalesHeader."Sell-to Customer No.");
        CreateFinanceChargeMemo(
          SalesHeader."Sell-to Customer No.", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>',
            CalcDate(FinanceChargeTerms."Due Date Calculation", SalesHeader."Due Date")));

        // Exercise: Calculate Finance Charge Memo Remaining Amount and Issue Finance Charge Memo.
        FinanceChargeMemoHeader.SetRange("Customer No.", SalesHeader."Sell-to Customer No.");
        FinanceChargeMemoHeader.FindFirst();
        FinanceChargeMemoAmount :=
          SalesLineAmount * (FinanceChargeMemoHeader."Document Date" - FinanceChargeMemoHeader."Posting Date") /
          FinanceChargeTerms."Interest Period (Days)" * FinanceChargeTerms."Interest Rate" / 100;
        IssuingFinanceChargeMemos(FinanceChargeMemoHeader."No.");

        // Verify: Finance Charge Memo Amount.
        VerifyFinanceChargeMemoAmount(FinanceChargeMemoHeader."No.", FinanceChargeMemoAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestFinanceChargeMemo()
    var
        Customer: Record Customer;
        CreateFinanceChargeMemos: Report "Create Finance Charge Memos";
        CreationDate: Date;
    begin
        // Create Finance Charge Memo using suggest finance charge memo document.

        // 1. Setup: Create Customer and Sales Invoice.
        Initialize();
        Customer.Get(CreateCustomer());
        MIRHelperFunctions.CreateAndPostSalesInvoiceBySalesJournal(Customer."No.");
        CreationDate := CalcDate('<' + Format(2 * LibraryRandom.RandInt(5)) + 'M>', WorkDate());

        // 2. Exercise: Run Create Finance Charge Memos Report.
        CreateFinanceChargeMemos.SetTableView(Customer);
        CreateFinanceChargeMemos.InitializeRequest(CreationDate, CreationDate);
        CreateFinanceChargeMemos.UseRequestPage(false);
        CreateFinanceChargeMemos.Run();

        // 3. Verify: Check Finance Charge Memo Document.
        VerifyFinanceChargeMemoDocument(Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestFinanceChargeMemoLine()
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        CustomerNo: Code[20];
    begin
        // Create Finance Charge Memo using suggest finance charge memo line.

        // 1. Setup: Create Customer and Sales Invoice.
        Initialize();
        CustomerNo := CreateCustomer();
        MIRHelperFunctions.CreateAndPostSalesInvoiceBySalesJournal(CustomerNo);

        // 2. Exercise: Create Finance Charge Memo using suggest line.
        CreateSuggestFinanceChargeMemo(
          FinanceChargeMemoHeader, CustomerNo, CalcDate('<' + Format(2 * LibraryRandom.RandInt(5)) + 'M>', WorkDate()));

        // 3. Verify: Check Finance Charge Memo Document.
        VerifyFinanceChargeMemoDocument(CustomerNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FinChargeMemoWithoutCustomerNo()
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        LibraryUtility: Codeunit "Library - Utility";
        FinanceChargeMemoStatistics: TestPage "Finance Charge Memo Statistics";
    begin
        // Verify that no error exists on opening Statistics Page after creating Finance Charge Memo without Customer No.

        // Setup: Create Finance Charge Memo Header.
        Initialize();
        FinanceChargeMemoHeader.Init();
        FinanceChargeMemoHeader."No." :=
          LibraryUtility.GenerateRandomCode(
            FinanceChargeMemoHeader.FieldNo("No."), DATABASE::"Finance Charge Memo Header");
        FinanceChargeMemoHeader.Insert();

        // Exercise: Open Statistics Page.
        FinanceChargeMemoStatistics.Trap();
        PAGE.Run(PAGE::"Finance Charge Memo Statistics", FinanceChargeMemoHeader);

        // Verify: Verify that no error exists on opening Statistics Page without Customer No.
        FinanceChargeMemoStatistics.VatAmount.AssertEquals(0);
        FinanceChargeMemoStatistics.Interest.AssertEquals(0);
    end;

    [Test]
    [HandlerFunctions('FinChargeMemoReportTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FinChargeMemoReportTest()
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeMemoPage: TestPage "Finance Charge Memo";
    begin
        // Verify No. is filled in Finance Charge Memo test report when clicking Finance Charge Memo Test button from Finance Charge Memo Card

        // Setup: Create Finance Charge Memo
        LibraryERM.CreateFinanceChargeMemoHeader(FinanceChargeMemoHeader, CreateCustomer());
        Commit(); // Use COMMIT to finish write transaction so that Report can run in Exercise step

        // Exercise: Navigate to the created Finance Charge Memo, open its card and run Report 'Finance Charge Memo - Test'
        FinanceChargeMemoPage.OpenEdit();
        FinanceChargeMemoPage.FILTER.SetFilter("No.", FinanceChargeMemoHeader."No.");

        // Run Report 'Finance Charge Memo - Test'. Note, before importing bug solution, this case will fail at this step with error 'The method
        // RunReport is not supported for TestPages', because the original code for this Action runs report by setting the RunObject Property.
        // After importing bug solution, this step can be executed successfully
        FinanceChargeMemoPage.TestReport.Invoke();

        // Verify: Finance Charge Memo Header Filter "No." is set to the No. of current Finance Charge Memo
        LibraryReportDataset.LoadDataSetFile();

        // The Finance Charge Memo Filter value cannot be read from the Test Request Page, so we verify it in the Report
        // Below element indicates the Finance Charge Memo Filter value set in the request page
        LibraryReportDataset.AssertElementWithValueExists(
          'STRSUBSTNO_Text008_FinChrgMemoHeaderFilter_',
          StrSubstNo(FinChrgMemoHeaderFilterTxt, FinanceChargeMemoHeader."No.", FinanceChargeMemoHeader."Customer No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestFinanceChargeMemoWithCurrencies()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        CreateFinanceChargeMemos: Report "Create Finance Charge Memos";
        DueDateMonths: Integer;
    begin
        // Create Finance Charge Memo using 'Suggest Finance Charge Memos' when invoices with different currencies exist.

        // 1. Setup: Create Customer and Sales Invoice.
        Initialize();
        DueDateMonths := LibraryRandom.RandInt(5);
        Customer.Get(CreateCustomerWithFinanceChargeTerms(CreateFinanceChargeTerms(DueDateMonths)));
        CreateAndPostSalesInvoiceWithCustomerAtDate(SalesHeader, '', Customer."No.", WorkDate());
        WorkDate(CalcDate('<1M>', SalesHeader."Posting Date"));
        CreateAndPostSalesInvoiceWithCustomerAtDate(
          SalesHeader, CreateCurrencyAndUpdateExcRate(), Customer."No.", WorkDate());
        // 2. Exercise: Run Create Finance Charge Memos Report.
        CreateFinanceChargeMemos.SetTableView(Customer);
        CreateFinanceChargeMemos.InitializeRequest(SalesHeader."Posting Date", SalesHeader."Posting Date");
        CreateFinanceChargeMemos.UseRequestPage(false);
        CreateFinanceChargeMemos.Run();

        // 3. Verify: Check Finance Charge Memo Document.
        VerifyNumberOfFinChargeMemos(Customer."No.", 1);
    end;

    [Test]
    [HandlerFunctions('FinanceChargeMemoHandler,IssueFinanceChargeMemosHandler,ConfirmHandler,FinanceChargeMemoListHandler')]
    [Scope('OnPrem')]
    procedure TryIssueFinChargeMemoOutOfAllowedDates()
    var
        Customer: Record Customer;
        PrintCountVar: Variant;
        FinChargeMemoHeaderFilter: Text;
    begin
        // Create and Issue Finance Charge Memo, then create another one Issue Finance Charge Memo with Posting Date out of allowed range of Posting Dates and try to issue and print it by running report 193.
        // Another issued Finance Charge Memos should not be printed.

        // 1. Setup: Create and issue Finance Charge Memo, then setup allowed posting dates.
        Initialize();
        Customer.Get(CreateCustomerWithFinanceChargeTerms(CreateFinanceChargeTerms(1)));
        LibraryVariableStorage.Enqueue(PrintDocRef::Print);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(CreateFinChargeMemoAtDate(Customer, CalcDate('<-1D>', WorkDate())));
        LibraryVariableStorage.Enqueue(0); // Initial no of prints
        Commit();
        IssueAndPrintFinChargeMemo();

        LibraryERM.SetAllowPostingFromTo(CalcDate('<-1M>', WorkDate()), WorkDate());

        // 2. Exercise: Run report "Issue Finance Charge Memos".
        FinChargeMemoHeaderFilter := Format(CreateFinChargeMemoAtDate(Customer, CalcDate('<+1M-1D>', WorkDate())));
        FinChargeMemoHeaderFilter += '..' + Format(CreateFinChargeMemoAtDate(Customer, CalcDate('<+1M>', WorkDate())));
        Commit();
        LibraryVariableStorage.Enqueue(PrintDocRef::Print);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Dequeue(PrintCountVar); // Extract no of prints
        LibraryVariableStorage.Enqueue(FinChargeMemoHeaderFilter);
        LibraryVariableStorage.Enqueue(PrintCountVar); // Push no of prints
        IssueAndPrintFinChargeMemo();

        // 3. Verify: Verify number of printed Fin Charge Memos
        LibraryVariableStorage.Dequeue(PrintCountVar); // Extract no of prints
        Assert.AreEqual(1, PrintCountVar, WrongNumberOfPrintedDocsErr);
    end;

    [Test]
    [HandlerFunctions('IssueFinanceChargeMemosHandler,EmailEditorHandler,CloseEmailEditorHandler')]
    [Scope('OnPrem')]
    procedure TestIssueFinChargeMemoEmail()
    begin
        IssueFinChargeMemoEmail();
    end;

    procedure IssueFinChargeMemoEmail()
    var
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        Customer: Record Customer;
        LibraryEmail: Codeunit "Library - Email";
    begin
        // [FEATURE] [EMail]
        // [SCENARIO 376445] Issue Finance Charge Memo with Print = E-Mail and Hide Email-Dialog = No should show 'E-Mail Dialog' page
        Initialize();
        LibraryEmail.SetUpEmailAccount();

        // [GIVEN] Customer "A" with Finance Charge Memo
        Customer.Get(CreateCustomerWithFinanceChargeTerms(CreateFinanceChargeTerms(1)));
        LibraryVariableStorage.Enqueue(PrintDocRef::Email);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(CreateFinChargeMemoAtDate(Customer, CalcDate('<-1D>', WorkDate())));
        Commit();

        // [WHEN] Issue Finance Charge Memo Print = E-Mail and Hide Email-Dialog = No
        IssueAndPrintFinChargeMemo();

        // [THEN] Cancel on Email Dialog appeared
        // [THEN] Issued Finance Charge Memo for Customer "A" exists
        IssuedFinChargeMemoHeader.Init();
        IssuedFinChargeMemoHeader.SetRange("Customer No.", Customer."No.");
        Assert.RecordIsNotEmpty(IssuedFinChargeMemoHeader);
        ResetObjectOptions(REPORT::"Issue Finance Charge Memos");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FinChargeMemoInvoiceRoundingStatistics()
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        FinanceChargeMemoStatistics: TestPage "Finance Charge Memo Statistics";
        TotalAmount: Decimal;
    begin
        // [FEATURE] [Invoice Rounding] [Statistics]
        // [SCENARIO 369814] Finance Charge Memo Statistics with Invoice Rounding
        Initialize();

        // [GIVEN] Amount Rounding Precision = 0.01, Invoice Rounding Precision = 0.1 in G/L Setup
        UpdateGLSetupInvRoundingPrecision();
        GeneralLedgerSetup.Get();

        // [GIVEN] Finance Charge Memo with G/L Accout Line = 1912.41
        LibraryERM.CreateFinanceChargeMemoHeader(
          FinanceChargeMemoHeader, CreateCustomerWithFinanceChargeTerms(CreateFinanceChargeTerms(1)));
        CreateFinChargeMemoLineForInvRounding(
          FinanceChargeMemoLine, FinanceChargeMemoHeader, GeneralLedgerSetup."Amount Rounding Precision");

        FinanceChargeMemoHeader.CalcFields("Additional Fee", "Interest Amount");
        TotalAmount := FinanceChargeMemoHeader."Additional Fee" + FinanceChargeMemoHeader."Interest Amount";

        // [WHEN] Finance Charge Memo Statistics is opened
        FinanceChargeMemoStatistics.Trap();
        Page.Run(PAGE::"Finance Charge Memo Statistics", FinanceChargeMemoHeader);

        // [THEN] Invoice Rounding Amount = -0.01, Total = 1912.41 on Statistics page
        FinanceChargeMemoStatistics.FinChrgMemoTotal.AssertEquals(TotalAmount);
        FinanceChargeMemoStatistics.InvoiceRoundingAmount.AssertEquals(
          Round(TotalAmount, GeneralLedgerSetup."Inv. Rounding Precision (LCY)") - TotalAmount);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerVerifyMsg')]
    [Scope('OnPrem')]
    procedure IssueFinChargeMemoWithInvRoundingConfirmFalse()
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
    begin
        // [FEATURE] [Invoice Rounding]
        // [SCENARIO 369814] Issue Finance Charge Memo with Invoice Rounding confirmed No
        Initialize();

        // [GIVEN] Amount Rounding Precision = 0.01, Invoice Rounding Precision = 0.1 in G/L Setup
        UpdateGLSetupInvRoundingPrecision();
        GeneralLedgerSetup.Get();

        // [GIVEN] Finance Charge Memo with G/L Accout Line = 1912.41
        LibraryERM.CreateFinanceChargeMemoHeader(
          FinanceChargeMemoHeader, CreateCustomerWithFinanceChargeTerms(CreateFinanceChargeTerms(1)));
        CreateFinChargeMemoLineForInvRounding(
          FinanceChargeMemoLine, FinanceChargeMemoHeader, GeneralLedgerSetup."Amount Rounding Precision");
        Commit();

        // [WHEN] Confirm 'No' when issue Finance Charge Memo
        LibraryVariableStorage.Enqueue(ProceedOnIssuingWithInvRoundingQst);
        LibraryVariableStorage.Enqueue(false);
        LibraryERM.IssueFinanceChargeMemo(FinanceChargeMemoHeader);

        // [THEN] Finance Charge Memo is not issued
        IssuedFinChargeMemoHeader.SetRange("Customer No.", FinanceChargeMemoHeader."Customer No.");
        ASSERTERROR IssuedFinChargeMemoHeader.FindFirst();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerVerifyMsg')]
    [Scope('OnPrem')]
    procedure IssueFinChargeMemoWithInvRoundingConfirmTrue()
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line";
        InvRoundingAmountAmount: Decimal;
    begin
        // [FEATURE] [Invoice Rounding]
        // [SCENARIO 369814] Issue Finance Charge Memo with Invoice Rounding confirmed Yes
        Initialize();

        // [GIVEN] Amount Rounding Precision = 0.01, Invoice Rounding Precision = 0.1 in G/L Setup
        UpdateGLSetupInvRoundingPrecision();
        GeneralLedgerSetup.Get();

        // [GIVEN] Finance Charge Memo with G/L Accout Line = 1912.41
        LibraryERM.CreateFinanceChargeMemoHeader(
          FinanceChargeMemoHeader, CreateCustomerWithFinanceChargeTerms(CreateFinanceChargeTerms(1)));
        CreateFinChargeMemoLineForInvRounding(
          FinanceChargeMemoLine, FinanceChargeMemoHeader, GeneralLedgerSetup."Amount Rounding Precision");

        FinanceChargeMemoHeader.CalcFields("Additional Fee", "Interest Amount");
        InvRoundingAmountAmount := FinanceChargeMemoHeader."Additional Fee" + FinanceChargeMemoHeader."Interest Amount";
        InvRoundingAmountAmount :=
          Round(InvRoundingAmountAmount, GeneralLedgerSetup."Inv. Rounding Precision (LCY)") - InvRoundingAmountAmount;
        Commit();

        // [WHEN] Confirm 'Yes' when issue Finance Charge Memo
        LibraryVariableStorage.Enqueue(ProceedOnIssuingWithInvRoundingQst);
        LibraryVariableStorage.Enqueue(true);
        LibraryERM.IssueFinanceChargeMemo(FinanceChargeMemoHeader);

        // [THEN] Invoice Rounding Amount is posted in issued fin. charge memo with Amount = -0.01
        IssuedFinChargeMemoHeader.SetRange("Customer No.", FinanceChargeMemoHeader."Customer No.");
        IssuedFinChargeMemoHeader.FindFirst();
        IssuedFinChargeMemoLine.SetRange("Finance Charge Memo No.", IssuedFinChargeMemoHeader."No.");
        IssuedFinChargeMemoLine.SetFilter("No.", '<>%1', FinanceChargeMemoLine."No.");
        IssuedFinChargeMemoLine.FindFirst();
        IssuedFinChargeMemoLine.TestField(Amount, InvRoundingAmountAmount);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerVerifyMsg')]
    [Scope('OnPrem')]
    procedure IssueFinChargeMemoWithNegInvRounding()
    var
        FinanceChargeTerm: Record "Finance Charge Terms";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        InvRoundingAmountAmount: Decimal;
        FinChargeMemoNo: Code[20];
    begin
        // [SCENARIO 437580] Issue Finance Charge Memo with Negative Invoice Rounding
        Initialize();

        // [GIVEN] Amount Rounding Precision = 0.01, Invoice Rounding Precision =1 in G/L Setup
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Inv. Rounding Precision (LCY)", 1.00);
        GeneralLedgerSetup.Modify();

        // [GIVEN] UPdate Finance Charge Term with Interest Rate 6 and Minimum Amount (LCY)=100
        FinanceChargeTerm.Get(CreateFinanceChargeTerms(1));
        FinanceChargeTerm."Minimum Amount (LCY)" := 100;
        FinanceChargeTerm."Interest Rate" := 6;
        FinanceChargeTerm."Post Interest" := false;
        FinanceChargeTerm."Post Additional Fee" := false;
        FinanceChargeTerm.Modify();

        // [GIVEN] Create Finance Charge Memo 
        LibraryERM.CreateFinanceChargeMemoHeader(
          FinanceChargeMemoHeader, CreateCustomerWithFinanceChargeTerms(FinanceChargeTerm.Code));
        CreateFinChargeMemoLineForInvRounding(
          FinanceChargeMemoLine, FinanceChargeMemoHeader, GeneralLedgerSetup."Amount Rounding Precision");
        FinChargeMemoNo := FinanceChargeMemoHeader."No.";

        //[THEN] Calculate Invoice Rounding Amount
        FinanceChargeMemoHeader.CalcFields("Additional Fee", "Interest Amount");
        InvRoundingAmountAmount := FinanceChargeMemoHeader."Additional Fee" + FinanceChargeMemoHeader."Interest Amount";
        InvRoundingAmountAmount :=
          Round(InvRoundingAmountAmount, GeneralLedgerSetup."Inv. Rounding Precision (LCY)") - InvRoundingAmountAmount;
        Commit();

        // [WHEN] Confirm 'Yes' when issue Finance Charge Memo
        LibraryVariableStorage.Enqueue(ProceedOnIssuingWithInvRoundingQst);
        LibraryVariableStorage.Enqueue(true);
        LibraryERM.IssueFinanceChargeMemo(FinanceChargeMemoHeader);

        // [VERIFY] Finance Charge Memo Issue when negative Invoice Rounding.
        asserterror Error('');
        asserterror FinanceChargeMemoHeader.Get(FinChargeMemoNo);
        Assert.AssertRecordNotFound();

    end;

    [Test]
    [Scope('OnPrem')]
    procedure IssueFinChargeMemoCreatesGLEntryOfAltCustPostingGrpIfAllowMultiPostingGrps()
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        CustomerPostingGroup2: Record "Customer Posting Group";
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        IssueFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        GLEntry: Record "G/L Entry";
        FinChargeTermsCode: Code[10];
    begin
        // [SCENARIO 498604] When stan Issue a Finance Charge Memo having Alternate Customer Posting Group of Customer having Allow Multiple Posting Groups as true then it creates GL Entry of Alternate Customer Posting Group's Receivables Account.
        Initialize();

        // [GIVEN] Validate Allow Multiple Posting Groups in Sales & Receivables Setup.
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Allow Multiple Posting Groups", true);
        SalesReceivablesSetup.Modify(true);

        // [GIVEN] Create Finance Charge Terms.
        FinChargeTermsCode := CreateFinanceChargeTerms(LibraryRandom.RandInt(0));

        // [GIVEN] Create Customer Posting Group.
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup2);

        // [GIVEN] Create Customer Posting group 2.
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);

        // [GIVEN] Create Alternate Customer Posting Group.
        LibrarySales.CreateAltCustomerPostingGroup(CustomerPostingGroup.Code, CustomerPostingGroup2.Code);

        // [GIVEN] Create Customer and Validate Customer Posting Group,
        // Allow Multiple Posting Groups and Fin. Charge Terms Code.
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Customer Posting Group", CustomerPostingGroup.Code);
        Customer.Validate("Allow Multiple Posting Groups", true);
        Customer.Validate("Fin. Charge Terms Code", FinChargeTermsCode);
        Customer.Modify(true);

        // [GIVEN] Create Finance Charge Memo Header and Validate Customer Posting Group.
        LibraryERM.CreateFinanceChargeMemoHeader(FinanceChargeMemoHeader, Customer."No.");
        FinanceChargeMemoHeader.Validate("Customer Posting Group", CustomerPostingGroup2.Code);
        FinanceChargeMemoHeader.Modify(true);

        // [GIVEN] Create Finance Charge Memo Line.
        CreateFinChargeMemoLineForInvRounding(FinanceChargeMemoLine, FinanceChargeMemoHeader, LibraryRandom.RandInt(0));

        // [GIVEN] Issue Finance Charge Memo.
        LibraryERM.IssueFinanceChargeMemo(FinanceChargeMemoHeader);

        // [GIVEN] Find Issued Fin. Charge Memo Header.
        IssueFinChargeMemoHeader.SetRange("Customer No.", Customer."No.");
        IssueFinChargeMemoHeader.FindFirst();

        // [WHEN] Find GL Entry.
        GLEntry.SetRange("Document No.", IssueFinChargeMemoHeader."No.");
        GLEntry.SetRange("G/L Account No.", CustomerPostingGroup2."Receivables Account");

        // [VERIFY] GL Entry has Receivables Account of Customer Posting Group 2 in GL Account No. 
        Assert.IsFalse(GLEntry.IsEmpty(), GLEntryMustNotBeEmpty);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Create Finance Charge Memo");
        BindActiveDirectoryMockEvents();
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Create Finance Charge Memo");

        SetGLSetupInvoiceRounding();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Create Finance Charge Memo");
    end;

    local procedure CreateCustomer(): Code[20]
    begin
        exit(CreateCustomerWithFinanceChargeTerms(FindFinChargeTermsWithoutMIR()));
    end;

    local procedure FindFinChargeTermsWithoutMIR(): Code[10]
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
    begin
        FinanceChargeTerms.SetFilter("Due Date Calculation", '<>''''');
        FinanceChargeTerms.FindFirst();
        ClearFinanceChargeInterestRate(FinanceChargeTerms.Code);
        exit(FinanceChargeTerms.Code);
    end;

    local procedure ClearFinanceChargeInterestRate(FinChargeTermsCode: Code[10])
    var
        FinanceChargeInterestRate: Record "Finance Charge Interest Rate";
    begin
        FinanceChargeInterestRate.SetRange("Fin. Charge Terms Code", FinChargeTermsCode);
        FinanceChargeInterestRate.DeleteAll();
    end;

    local procedure CreateCustomerWithFinanceChargeTerms(FinChargeTermsCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Fin. Charge Terms Code", FinChargeTermsCode);
        Customer.Validate("Application Method", Customer."Application Method"::"Apply to Oldest");
        Customer.Validate("E-Mail", EmailTxt);
        Customer.Modify(true);
        SetupInterestAccOfCust(Customer."Customer Posting Group");
        exit(Customer."No.");
    end;

    local procedure CreateFinanceChargeTerms(DueDateMonths: Integer): Code[10]
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        VarDateFormula: DateFormula;
    begin
        LibraryERM.CreateFinanceChargeTerms(FinanceChargeTerms);
        FinanceChargeTerms.Validate("Interest Period (Days)", LibraryRandom.RandIntInRange(10, 30));
        Evaluate(VarDateFormula, '<+' + Format(LibraryRandom.RandIntInRange(2, 10)) + 'D>');
        FinanceChargeTerms.Validate("Grace Period", VarDateFormula);
        FinanceChargeTerms.Validate("Interest Rate", LibraryRandom.RandDecInRange(1, 5, 2));
        FinanceChargeTerms.Validate("Additional Fee (LCY)", LibraryRandom.RandDecInRange(1, 10, 2));
        FinanceChargeTerms.Validate("Post Interest", true);
        FinanceChargeTerms.Validate("Post Additional Fee", true);
        Evaluate(VarDateFormula, '<+' + Format(DueDateMonths) + 'M>');
        FinanceChargeTerms.Validate("Due Date Calculation", VarDateFormula);
        FinanceChargeTerms.Modify();
        exit(FinanceChargeTerms.Code);
    end;

    local procedure CreateAndPostSalesInvoice(var SalesHeader: Record "Sales Header"; CurrencyCode: Code[10]): Decimal
    begin
        exit(CreateAndPostSalesInvoiceWithCustomerAtDate(SalesHeader, CurrencyCode, CreateCustomer(), WorkDate()));
    end;

    local procedure CreateAndPostSalesInvoiceWithCustomerAtDate(var SalesHeader: Record "Sales Header"; CurrencyCode: Code[10]; CustomerNo: Code[20]; PostingDate: Date): Decimal
    var
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        // Create and Post Sales Invoice. Using Random value for Quantity.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Document Date", PostingDate);
        SalesHeader.Validate("Due Date", PostingDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        exit(SalesInvoiceHeader."Amount Including VAT");
    end;

    local procedure CreateCurrencyAndUpdateExcRate(): Code[10]
    var
        Currency: Record Currency;
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateFinanceChargeMemo(No: Code[20]; DocumentDate: Date)
    var
        Customer: Record Customer;
        CreateFinanceChargeMemos: Report "Create Finance Charge Memos";
    begin
        Customer.SetRange("No.", No);
        CreateFinanceChargeMemos.SetTableView(Customer);
        CreateFinanceChargeMemos.InitializeRequest(WorkDate(), DocumentDate);
        CreateFinanceChargeMemos.UseRequestPage(false);
        CreateFinanceChargeMemos.Run();
    end;

    local procedure CreateFinChargeMemoAtDate(Customer: Record Customer; PostingDate: Date): Code[20]
    var
        FinChargeMemoHeader: Record "Finance Charge Memo Header";
        FinChargeMemoLine: Record "Finance Charge Memo Line";
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        LibraryERM.CreateFinanceChargeMemoHeader(FinChargeMemoHeader, Customer."No.");
        FinChargeMemoHeader.Validate("Posting Date", PostingDate);
        FinChargeMemoHeader.Modify(true);
        LibraryERM.CreateFinanceChargeMemoLine(FinChargeMemoLine, FinChargeMemoHeader."No.", FinChargeMemoLine.Type::"G/L Account");
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        FinChargeMemoLine.Validate("No.", CustomerPostingGroup."Interest Account");
        FinChargeMemoLine.Validate(Amount, LibraryRandom.RandDecInDecimalRange(10, 1000, 2));
        FinChargeMemoLine.Modify(true);

        exit(FinChargeMemoHeader."No.");
    end;

    local procedure CreateFinChargeMemoLineForInvRounding(var FinanceChargeMemoLine: Record "Finance Charge Memo Line"; FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; AmountRoundingPrecision: Decimal)
    var
        GLAccount: Record "G/L Account";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateFinanceChargeMemoLine(
            FinanceChargeMemoLine, FinanceChargeMemoHeader."No.", FinanceChargeMemoLine.Type::"G/L Account");

        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        GenProductPostingGroup.Get(GLAccount."Gen. Prod. Posting Group");
        GenProductPostingGroup.Validate("Def. VAT Prod. Posting Group", GLAccount."VAT Prod. Posting Group");
        GenProductPostingGroup.Modify(true);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, FinanceChargeMemoHeader."VAT Bus. Posting Group", VATProductPostingGroup.Code);
        VATPostingSetup."VAT Identifier" := VATPostingSetup."VAT Prod. Posting Group";
        VATPostingSetup.Validate("VAT %", 0);
        VATPostingSetup.Modify(true);
        GLAccount.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        GLAccount.Modify(true);

        FinanceChargeMemoLine.Validate("No.", GLAccount."No.");
        FinanceChargeMemoLine.Validate(
            Amount,
            (LibraryRandom.RandIntInRange(10000, 20000) * 10 + 1) * AmountRoundingPrecision);
        FinanceChargeMemoLine.Modify(true);
    end;

    local procedure IssueAndPrintFinChargeMemo()
    var
        IssueFinanceChargeMemos: Report "Issue Finance Charge Memos";
    begin
        Clear(IssueFinanceChargeMemos);
        IssueFinanceChargeMemos.UseRequestPage(true);
        IssueFinanceChargeMemos.Run();
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(Item);

        // Using fix value with Random value because the value is important for test case.
        Item.Validate("Unit Price", 1000 + LibraryRandom.RandDec(10, 2));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateSuggestFinanceChargeMemo(var FinanceChargeMemoHeader: Record "Finance Charge Memo Header"; CustomerNo: Code[20]; DocumentDate: Date)
    begin
        LibraryERM.CreateFinanceChargeMemoHeader(FinanceChargeMemoHeader, CustomerNo);
        FinanceChargeMemoHeader.Validate("Document Date", DocumentDate);
        FinanceChargeMemoHeader.Modify(true);
        SuggestFinanceChargeMemoLines(FinanceChargeMemoHeader);
    end;

    local procedure SetupInterestAccOfCust(CustPostGroupCode: Code[20])
    var
        GLAccount: Record "G/L Account";
        GenProdPostGroup: Record "Gen. Product Posting Group";
        CustPostGroup: Record "Customer Posting Group";
    begin
        CustPostGroup.Get(CustPostGroupCode);
        GLAccount.Get(CustPostGroup."Interest Account");
        GenProdPostGroup.Get(GLAccount."Gen. Prod. Posting Group");
        if GenProdPostGroup."Def. VAT Prod. Posting Group" = '' then begin
            GenProdPostGroup.Validate("Def. VAT Prod. Posting Group", GLAccount."VAT Prod. Posting Group");
            GenProdPostGroup.Modify(true);
        end;
    end;

    local procedure GetFinanceChargeTerms(var FinanceChargeTerms: Record "Finance Charge Terms"; CustomerNo: Code[20])
    var
        Customer: Record Customer;
    begin
        // Fix added for Mininum Amount of Finance Charge Term to make test world ready.
        Customer.Get(CustomerNo);
        FinanceChargeTerms.Get(Customer."Fin. Charge Terms Code");
        FinanceChargeTerms.Validate("Minimum Amount (LCY)", LibraryRandom.RandInt(5));
        FinanceChargeTerms.Modify(true);
    end;

    local procedure IssuingFinanceChargeMemos(FinanceChargeMemoHeaderNo: Code[20])
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
    begin
        FinanceChargeMemoHeader.Get(FinanceChargeMemoHeaderNo);
        LibraryERM.IssueFinanceChargeMemo(FinanceChargeMemoHeader);
    end;

    local procedure SuggestFinanceChargeMemoLines(FinanceChargeMemoHeader: Record "Finance Charge Memo Header")
    var
        SuggestFinChargeMemoLines: Report "Suggest Fin. Charge Memo Lines";
    begin
        FinanceChargeMemoHeader.SetRange("No.", FinanceChargeMemoHeader."No.");
        SuggestFinChargeMemoLines.SetTableView(FinanceChargeMemoHeader);
        SuggestFinChargeMemoLines.UseRequestPage(false);
        SuggestFinChargeMemoLines.Run();
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure FinanceChargeMemoHandler(var FinanceChargeMemo: Report "Finance Charge Memo")
    var
        PrintCountVar: Variant;
        PrintCount: Integer;
    begin
        LibraryVariableStorage.Dequeue(PrintCountVar);
        PrintCount := PrintCountVar;
        PrintCount += 1;
        LibraryVariableStorage.Enqueue(PrintCount);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IssueFinanceChargeMemosHandler(var IssueFinanceChargeMemos: TestRequestPage "Issue Finance Charge Memos")
    begin
        IssueFinanceChargeMemos.PrintDoc.SetValue(LibraryVariableStorage.DequeueInteger());
        IssueFinanceChargeMemos.HideEmailDialog.SetValue(LibraryVariableStorage.DequeueBoolean());
        IssueFinanceChargeMemos."Finance Charge Memo Header".SetFilter("No.", LibraryVariableStorage.DequeueText());
        IssueFinanceChargeMemos.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerVerifyMsg(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure FinanceChargeMemoListHandler(var FinanceChargeMemoList: TestPage "Finance Charge Memo List")
    begin
    end;

    local procedure ResetObjectOptions(ReportID: Integer)
    var
        ObjectOptions: Record "Object Options";
    begin
        ObjectOptions.SetRange("Object Type", ObjectOptions."Object Type"::Report);
        ObjectOptions.SetRange("Object ID", ReportID);
        ObjectOptions.DeleteAll();
    end;

    local procedure SetGLSetupInvoiceRounding()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Inv. Rounding Precision (LCY)" := GeneralLedgerSetup."Amount Rounding Precision";
        GeneralLedgerSetup.Modify();
    end;

    local procedure UpdateGLSetupInvRoundingPrecision()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        LibraryERM.SetInvRoundingPrecisionLCY(GeneralLedgerSetup."Amount Rounding Precision" * 10);
    end;

    local procedure VerifyFinanceChargeMemoAmount(PreAssignedNo: Code[20]; CalcFinanceChargeMemoAmount: Decimal)
    var
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        IssuedFinChargeMemoLine: Record "Issued Fin. Charge Memo Line";
    begin
        IssuedFinChargeMemoHeader.SetRange("Pre-Assigned No.", PreAssignedNo);
        IssuedFinChargeMemoHeader.FindFirst();
        IssuedFinChargeMemoLine.SetRange("Finance Charge Memo No.", IssuedFinChargeMemoHeader."No.");
        IssuedFinChargeMemoLine.FindFirst();

        Assert.AreNearlyEqual(
          CalcFinanceChargeMemoAmount, IssuedFinChargeMemoLine.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(AmountErr, CalcFinanceChargeMemoAmount, PreAssignedNo));
    end;

    local procedure VerifyFinanceChargeMemoDocument(CustomerNo: Code[20])
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinanceChargeMemoLine: Record "Finance Charge Memo Line";
    begin
        FinanceChargeMemoHeader.SetRange("Customer No.", CustomerNo);
        FinanceChargeMemoHeader.FindFirst();

        FinanceChargeMemoLine.SetRange("Finance Charge Memo No.", FinanceChargeMemoHeader."No.");
        FinanceChargeMemoLine.FindFirst();
    end;

    local procedure VerifyNumberOfFinChargeMemos(CustomerNo: Code[20]; ExpectedNumber: Integer)
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
    begin
        FinanceChargeMemoHeader.SetRange("Customer No.", CustomerNo);
        Assert.AreEqual(ExpectedNumber, FinanceChargeMemoHeader.Count, WrongNumberOfMemosErr);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure FinChargeMemoReportTestRequestPageHandler(var FinChargeMemoTest: TestRequestPage "Finance Charge Memo - Test")
    begin
        FinChargeMemoTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EmailEditorHandler(var EmailEditor: TestPage "Email Editor")
    begin
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CloseEmailEditorHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 1;
    end;

    local procedure BindActiveDirectoryMockEvents()
    begin
        if ActiveDirectoryMockEvents.Enabled() then
            exit;
        BindSubscription(ActiveDirectoryMockEvents);
        ActiveDirectoryMockEvents.Enable();
    end;
}

