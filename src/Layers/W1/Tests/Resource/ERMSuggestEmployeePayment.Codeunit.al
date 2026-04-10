codeunit 134116 "ERM Suggest Employee Payment"
{
    Permissions = TableData "Employee Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Employee Payments]
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryJournals: Codeunit "Library - Journals";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        isInitialized: Boolean;
        AmountErrorMessageMsg: Label '%1 must be %2 in Gen. Journal Line Template Name=''''%3'''',Journal Batch Name=''''%4'''',Line No.=''''%5''''.';
        ValidateErrorErr: Label '%1 must be %2 in %3 %4 = %5.';
        SuggestEmployeeAmountErr: Label 'The available amount of suggest Employee payment is always greater then gen. journal line amount.';
        NoOfPaymentErr: Label 'No of payment is incorrect.';
        DocumentNoErr: Label 'Document No. must not increase when New Doc. No. Per Line is not enabled.';

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure EmployeePaymentWithManualCheck()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create and Post General Journal Lines and Suggest Employee Payments with Manual Check.
        Initialize();
        EmployeePayment(GenJournalLine."Bank Payment Type"::"Manual Check");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure EmployeePaymentWithComputerCheck()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Create and Post General Journal Lines and Suggest Employee Payments with Computer Check.
        Initialize();
        EmployeePayment(GenJournalLine."Bank Payment Type"::"Computer Check");
    end;

    local procedure EmployeePayment(BankPaymentType: Enum "Bank Payment Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        BankAccountNo: Code[20];
    begin
        // Create Setup, Post General Journal Lines, Suggest Employee Payment and Verify Posted Entries.
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::General);
        BankAccountNo := SetupAndCreateGenJournalLines(GenJournalLine, GenJournalBatch);

        // Exercise: Post General Journal Lines and Run Report Suggest Employee Payment.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Payments);
        SuggestEmployeePayment(
          GenJournalBatch, GenJournalLine."Account No.", GenJournalLine."Bal. Account Type"::"Bank Account", BankAccountNo,
          BankPaymentType, true);

        // Verify: Verify General Journal Lines Amount is same after Posting General journal Lines.
        VerifyGenJournalEntriesAmount(GenJournalLine."Account No.");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure EmployeePaymentWithAllEmployees()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        Employee2: Record Employee;
        BankAccountNo: Code[20];
        EmployeeNo: Code[20];
        NoOfLines: Integer;
    begin
        // Create Setup, Post General Journal Lines, Suggest Employee Payment for Multi Employee with Computer Check and Verify Posted Entries.
        Initialize();
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::General);
        BankAccountNo := SetupAndCreateGenJournalLines(GenJournalLine, GenJournalBatch);
        EmployeeNo := GenJournalLine."Account No.";
        NoOfLines := 2 * LibraryRandom.RandInt(5);  // Use Random Number to generate more than two lines.
        LibraryHumanResource.CreateEmployeeWithBankAccount(Employee2);
        CreateMultipleGenJournalLine(
          GenJournalLine, GenJournalBatch, NoOfLines, WorkDate(), Employee2."No.",
          GenJournalLine."Document Type"::" ", -1);

        // Exercise: Post General Journal Lines and Run Report Suggest Employee Payment.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Payments);
        SuggestEmployeePayment(
          GenJournalBatch, EmployeeNo, GenJournalLine."Bal. Account Type"::"Bank Account", BankAccountNo,
          GenJournalLine."Bank Payment Type"::"Computer Check", true);
        SuggestEmployeePayment(
          GenJournalBatch, Employee2."No.", GenJournalLine."Bal. Account Type"::"Bank Account", BankAccountNo,
          GenJournalLine."Bank Payment Type"::"Computer Check", true);

        // Verify: Verify General Journal Lines Amount is same after Posting General journal Lines.
        VerifyGenJournalEntriesAmount(EmployeeNo);
        VerifyGenJournalEntriesAmount(Employee2."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestEmployeePaymentWithLineRemovedAndReadded()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        Employee: Record Employee;
        RecordCountBefore: Integer;
        RecordCountAfterDelete: Integer;
        RecordCountAfterResuggest: Integer;
        PreCount: Integer;
        PostCount: Integer;
    begin
        // Suggest Employee payments with Discounts.

        // Setup: Create Payment Terms and Employee, Create Expenses and post them
        Initialize();

        LibraryHumanResource.CreateEmployeeWithBankAccount(Employee);
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::General);
        CreateMultipleGenJournalLine(GenJournalLine, GenJournalBatch, LibraryRandom.RandInt(2), CalcDate('<-1D>', WorkDate()),
          Employee."No.", GenJournalLine."Document Type"::" ", -1);
        CreateMultipleGenJournalLine(GenJournalLine, GenJournalBatch, LibraryRandom.RandInt(2), WorkDate(),
          Employee."No.", GenJournalLine."Document Type"::" ", -1);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Run Suggest Employee Payments report
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Payments);
        GenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        PreCount := GenJournalLine.Count();
        SuggestEmployeePayment(
          GenJournalBatch, '',
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), GenJournalLine."Bank Payment Type", false);
        GenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        PostCount := GenJournalLine.Count();

        Assert.IsTrue(PreCount < PostCount, 'Suggest Employee Payments should have added records.');

        RecordCountBefore := GenJournalLine.Count();
        GenJournalLine.FindLast();
        GenJournalLine.Delete();
        Commit();

        // Verify: Record was removed
        GenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        RecordCountAfterDelete := GenJournalLine.Count();
        Assert.AreNotEqual(RecordCountBefore, RecordCountAfterDelete, 'General Journal record should have been removed.');

        SuggestEmployeePayment(
          GenJournalBatch, '',
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), GenJournalLine."Bank Payment Type", false);
        GenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        RecordCountAfterResuggest := GenJournalLine.Count();

        // Verify: Record was recreated, i.e.  Before and After record counts are equal
        Assert.AreEqual(RecordCountBefore, RecordCountAfterResuggest, 'Suggest Employee payments did not add the line.');
        Assert.IsTrue(RecordCountAfterDelete < RecordCountAfterResuggest, 'Suggest Employee Payments should have added payment.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentToExpenseWithApplyEntry()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Apply Payment against the Expenses and show Only Applied Entries.
        Initialize();
        SetApplyIdToDocument(GenJournalLine."Document Type"::" ", GenJournalLine."Document Type"::Payment, -1);
    end;

    local procedure SetApplyIdToDocument(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; AmountSign: Integer)
    var
        Employee: Record Employee;
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        NumberOfLines: Integer;
    begin
        // Setup: Create Employee and General Journal Lines.
        NumberOfLines := 1 + LibraryRandom.RandInt(5);  // Use Random Number to generate more than one line.
        LibraryHumanResource.CreateEmployeeWithBankAccount(Employee);
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::General);
        CreateMultipleGenJournalLine(GenJournalLine, GenJournalBatch, NumberOfLines, WorkDate(), Employee."No.", DocumentType, AmountSign);
        CreateMultipleGenJournalLine(GenJournalLine, GenJournalBatch, 1, WorkDate(), Employee."No.", DocumentType2, -AmountSign);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Set Applies to ID to all Expenses.
        ApplyPaymentToEmployee(GenJournalLine."Account No.", NumberOfLines, DocumentType, DocumentType2);

        // Verify: Verify Employee Ledger Entry.
        VerifyEmployeeLedgerEntry(Employee."No.", NumberOfLines);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentBySuggestEmployeePayment()
    var
        Employee: Record Employee;
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        ExpenseAmount: Decimal;
        ExpenseNo: Code[20];
    begin
        // Test Employee Ledger Entry after Posting Payment Journal with running Suggest Employee Payment.

        // 1. Setup: Create Payment Terms with Discount Date and Calc. Pmt. Disc. on Cr. Memos as True, Employee with Payment Terms Code,
        // Create and Post General Journal Lines with Document Type as Expense and Payment
        Initialize();
        LibraryHumanResource.CreateEmployeeWithBankAccount(Employee);
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::General);
        ExpenseAmount := LibraryRandom.RandDec(1000, 2);  // Use Random for Expense Amount.
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, WorkDate(), Employee."No.", GenJournalLine."Document Type"::" ", -ExpenseAmount);
        ExpenseNo := GenJournalLine."Document No.";
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, WorkDate(), Employee."No.", GenJournalLine."Document Type"::Payment,
          ExpenseAmount * LibraryUtility.GenerateRandomFraction());
        ApplyGenJnlLineEntryToExpense(GenJournalLine, ExpenseNo);

        ApplyGenJnlLineEntryToExpense(GenJournalLine, ExpenseNo);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Run Suggest Employee Payment and Post the Payment Journal.
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Payments);
        SuggestEmployeePayment(
          GenJournalBatch, Employee."No.",
          GenJournalLine."Bal. Account Type", GenJournalLine."Bal. Account No.", GenJournalLine."Bank Payment Type"::" ", true);
        FindAndPostPaymentJournalLine(GenJournalBatch);

        // 3. Verify: Verify Remaining Amount on Employee Ledger Entry.
        VerifyRemainingOnEmployeeLedger(Employee."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestEmployeePaymentForExpense()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        DocumentNo2: Code[20];
    begin
        // Test Employee Ledger Entry after Posting Payment Journal with running Suggest Employee Payment against Expense.

        // 1. Setup: Create and post General Journal with Document Type as Expense.
        Initialize();
        DocumentNo := CreateAndPostGeneralJournal(GenJournalLine, GenJournalLine."Document Type"::" ");

        // 2. Exercise: Create General Journal Batch for Payment and Run Suggest Employee Payment with Random Last Payment Date.
        // Post the Payment Journal.
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Payments);
        SuggestEmployeePayment(
          GenJournalBatch, GenJournalLine."Account No.", GenJournalLine."Account Type"::"G/L Account",
          GenJournalLine."Bal. Account No.", GenJournalLine."Bank Payment Type"::" ", true);
        DocumentNo2 := FindAndPostPaymentJournalLine(GenJournalBatch);

        // 3. Verify: Verify values on Employee Ledger Entry after post the Payment Journal.
        VerifyValuesOnEmplLedgerEntry(
          GenJournalLine."Document No.", GenJournalLine."Document Type"::" ", GenJournalLine."Account No.", GenJournalLine.Amount,
          0, false);
        VerifyValuesOnEmplLedgerEntry(
          DocumentNo, GenJournalLine."Document Type"::" ", GenJournalLine."Account No.", GenJournalLine.Amount / 2, 0, false);
        VerifyValuesOnEmplLedgerEntry(
          DocumentNo2, GenJournalLine."Document Type"::Payment, GenJournalLine."Account No.", -GenJournalLine.Amount / 2 * 3, 0, false);
    end;

    [Test]
    [HandlerFunctions('SuggestEmployeePaymentsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestPaymentForEmployeeWithDebitBalance()
    begin
        Initialize();
        // [GIVEN] Employee with Negative Balance
        // [GIVEN] Use Employee Priority is FALSE
        // [WHEN] Suggest Employee Payment
        // [THEN] Payment is not suggested
        SuggestPaymentForEmployee();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GLEntriesWithDimensionValues()
    var
        GenJournalLine: Record "Gen. Journal Line";
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        EmployeeNo: Code[20];
        GLAccountNo: Code[20];
        ShortcutDimension1Code: Code[20];
        ShortcutDimension2Code: Code[20];
    begin
        // Setup: Create & Post General Journal Lines.
        Initialize();
        EmployeeNo := LibraryHumanResource.CreateEmployeeNoWithBankAccount();
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        CreateGeneralJournalWithAccountTypeGLAccount(GenJournalLine, GLAccountNo);
        UpdateGenJournalLine(GenJournalLine, EmployeeNo);
        ShortcutDimension1Code := GenJournalLine."Shortcut Dimension 1 Code";
        ShortcutDimension2Code := GenJournalLine."Shortcut Dimension 2 Code";
        CopyTempGenJournalLine(GenJournalLine, TempGenJournalLine); // Insert Temp General Journal Line for verification.

        // Exercise: Post General Journal Lines.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify: Verification of GL Entry with Dimension.
        VerifyValuesOnGLEntry(TempGenJournalLine, '', '');
        VerifyValuesOnGLEntry(TempGenJournalLine, ShortcutDimension1Code, ShortcutDimension2Code);
    end;

    [Test]
    [HandlerFunctions('SuggestEmployeePaymentsWithDimensionAndBalAccRequestPageHandler,SelectDimensionHandlerOnSuggesEmployeePayment')]
    [Scope('OnPrem')]
    procedure DimensionAfterSuggestEmployeePaymentOnGeneralJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        EmployeeNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // 1. Setup: Create and Post General Journal Lines.
        EmployeeNo := LibraryHumanResource.CreateEmployeeNoWithBankAccount();
        GLAccountNo := LibraryERM.CreateGLAccountNo();
        LibraryVariableStorage.Enqueue(EmployeeNo);
        LibraryVariableStorage.Enqueue(GLAccountNo);
        CreateGeneralJournalWithAccountTypeGLAccount(GenJournalLine, GLAccountNo);
        UpdateGenJournalLine(GenJournalLine, EmployeeNo);

        // Post General Journal Lines.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Suggest Employee Payment using PageHandler SelectDimensionHandlerOnSuggesEmployeePayment.
        SuggestEmployeePaymentUsingPage(GenJournalLine);

        // 3. Verify: Verify that General Journal line exist with blank Dimensions.
        VerifyDimensionOnGeneralJournalLine(GenJournalLine, EmployeeNo, GLAccountNo);
    end;

    [Test]
    [HandlerFunctions('SuggestEmployeePaymentsWithoutBalAccountRequestPageHandler,ClearDimensionHandlerOnSuggesEmployeePayment')]
    [Scope('OnPrem')]
    procedure DimensionOnPaymentJournalFromGeneralJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        EmployeeNo: Code[20];
        ShDim1Code: Code[20];
        ShDim2Code: Code[20];
    begin
        // Test the dimension valued posted with Expense are retrived when performing suggest Employee payment.

        // Setup:
        Initialize();

        // Exercise: Create GenJournalLine with Dimesnion and Post it. Run Suggest Employee Payment.
        EmployeeNo := CreateGenJnlLineWithEmployeeBalAcc(GenJournalLine);
        LibraryVariableStorage.Enqueue(EmployeeNo);
        UpdateDimensionOnGeneralJournalLine(GenJournalLine);
        ShDim1Code := GenJournalLine."Shortcut Dimension 1 Code";
        ShDim2Code := GenJournalLine."Shortcut Dimension 2 Code";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        SetupGenJnlLine(GenJournalLine);
        SuggestEmployeePaymentUsingPage(GenJournalLine);

        // Verify:
        VerifyDimensionOnGeneralJournalLineFromExpense(GenJournalLine, ShDim1Code, ShDim2Code);
    end;

    [Test]
    [HandlerFunctions('SuggestEmployeePaymentsWithAvailableAmtRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckGenJnlLineWhenSumOfExpensesGreaterThanLimit()
    var
        ExpenseAmount: Decimal;
    begin
        // Verify that after two Expenses each smaller than the limit and sum of them is exceeds the limit and after running suggest Employee payment report then one payment exist.
        ExpenseAmount := LibraryRandom.RandIntInRange(15, 20);
        CheckGenJnlLineAfterSuggestEmployeePayment(LibraryRandom.RandIntInRange(21, 25), 1, ExpenseAmount);
    end;

    [Test]
    [HandlerFunctions('SuggestEmployeePaymentsWithAvailableAmtRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckGenJnlLineWhenLimitMoreThanSumOfExpenses()
    var
        ExpenseAmount: Decimal;
    begin
        // Verify that after two Expenses each smaller than the limit and Sum of them is smaller then limit and after running suggest Employee payment report then two payment exist.
        ExpenseAmount := LibraryRandom.RandIntInRange(15, 20);
        CheckGenJnlLineAfterSuggestEmployeePayment(LibraryRandom.RandIntInRange(50, 100), 2, ExpenseAmount);
    end;

    [Test]
    [HandlerFunctions('SuggestEmployeePaymentsWithAvailableAmtRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckGenJnlLineWhenOneExpenseBiggerThanLimit()
    var
        ExpenseAmount: Decimal;
    begin
        // Verify that after two Expenses one is smaller, second is bigger than the limit and after running suggest Employee payment report then one payment exist.
        ExpenseAmount := LibraryRandom.RandIntInRange(200, 300);
        CheckGenJnlLineAfterSuggestEmployeePayment(LibraryRandom.RandIntInRange(100, 200), 1, ExpenseAmount);
    end;

    [Test]
    [HandlerFunctions('SuggestEmployeePaymentsWithAvailableAmtRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckGenJnlLineWhenBothInviceMoreThanLimit()
    var
        ExpenseAmount: Decimal;
    begin
        // Verify that after two Expenses both are bigger than the limit and after running suggest Employee payment report then no payment exist.
        ExpenseAmount := LibraryRandom.RandIntInRange(400, 500);
        CheckGenJnlLineAfterSuggestEmployeePayment(LibraryRandom.RandIntInRange(1, 10), 0, ExpenseAmount);
    end;

    [Test]
    [HandlerFunctions('SuggestEmployeePaymentsWithAvailableAmtRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckGenJnlLineWithTwoExpensesWithoutLimit()
    var
        ExpenseAmount: Decimal;
    begin
        // Verify that after two Expenses are posted and after running suggest Employee payment report without limit and then 2 payment exist.
        ExpenseAmount := LibraryRandom.RandIntInRange(400, 500);
        CheckGenJnlLineAfterSuggestEmployeePayment(0, 2, ExpenseAmount);
    end;

    [Test]
    [HandlerFunctions('SuggestEmployeePaymentsWithDimensionRequestPageHandler,SelectDimensionHandlerOnSuggesEmployeePayment')]
    [Scope('OnPrem')]
    procedure DimensionOnPaymentJournalFromGenJournalWithSums()
    var
        GenJournalLine: Record "Gen. Journal Line";
        EmployeeNo: Code[20];
        ShDim1Code: Code[20];
        ShDim2Code: Code[20];
    begin
        // Test the dimension valued posted with Expense are retrived when performing suggest Employee payment with 'Summarize per Employee' checked.

        // Setup:
        Initialize();

        // Exercise: Create GenJournalLine with Dimesnion and Post it. Create Default dimension for Employee, Run Suggest Employee Payment.
        EmployeeNo := CreateGenJnlLineWithEmployeeBalAcc(GenJournalLine);
        LibraryVariableStorage.Enqueue(EmployeeNo);
        UpdateDimensionOnGeneralJournalLine(GenJournalLine);
        ShDim1Code := GenJournalLine."Shortcut Dimension 1 Code";
        ShDim2Code := GenJournalLine."Shortcut Dimension 2 Code";
        UpdateDiffDimensionOnEmployee(EmployeeNo, ShDim1Code, ShDim2Code);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        SetupGenJnlLine(GenJournalLine);
        SuggestEmployeePaymentUsingPage(GenJournalLine);

        // Verify:
        VerifyDimensionOnGeneralJournalLineFromExpense(GenJournalLine, ShDim1Code, ShDim2Code);
    end;

    [Test]
    [HandlerFunctions('SuggestEmployeePaymentsWithDimensionRequestPageHandler,SelectNoDimensionHandlerOnSuggesEmployeePayment')]
    [Scope('OnPrem')]
    procedure DimensionOnPaymnetJournalSummarizeEmployeeNoSelection()
    begin
        // Test the dimension valued posted with Expense are retrived when performing suggest Employee payment with 'Summarize per Employee' checked.
        VerifyDimOnGeneralJournalLineSummarizePerVend(false);
    end;

    [Test]
    [HandlerFunctions('SuggestEmployeePaymentsWithDimensionRequestPageHandler,SelectFirstDimensionHandlerOnSuggesEmployeePayment')]
    [Scope('OnPrem')]
    procedure DimensionOnPaymnetJournalSummarizeEmployeeOneSelected()
    begin
        // Test the dimension valued posted with Expense are retrived when performing suggest Employee payment with 'Summarize per Employee' checked.
        VerifyDimOnGeneralJournalLineSummarizePerVend(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DefaultVendDimUsedWhenNoSelectedDimAndSummarizePerEmployee()
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlBatch: Record "Gen. Journal Batch";
        GenJnlLine: Record "Gen. Journal Line";
        EmployeeNo: Code[20];
        DimSetID: Integer;
    begin
        // [FEATURE] [Default Dimension]
        // [SCENARIO 371674] Default Dimensions should be used for Payment Journal when Suggest Employee Payments with no selected dimensions and "Summarize Per Employee" option

        Initialize();
        // [GIVEN] Employee with Default Dimension Set ID = "X" combined from "Global Dimension 1 Code" = "A" and "Global Dimension 2 Code" = "B"
        CreateEmployeeWithDimensions(EmployeeNo, DimSetID);
        // [GIVEN] Posted Expense
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJnlLine, GenJnlLine."Document Type"::" ", GenJnlLine."Account Type"::Employee, EmployeeNo,
          -LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        CreateGeneralJournalBatch(GenJnlBatch, GenJnlTemplate.Type::Payments);

        // [WHEN] Run Suggest Employee Payments with "Summarize Per Employee" option
        SuggestEmployeePayment(
          GenJnlBatch, GenJnlLine."Account No.",
          GenJnlLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), GenJnlLine."Bank Payment Type"::"Computer Check", true);

        // [THEN] General Journal Line is created with "Dimension Set ID" = "X", "Global Dimension 1 Code" = "A", "Global Dimension 2 Code" = "B"
        VerifyGenJnlLineDimSetID(GenJnlBatch, EmployeeNo, DimSetID);
    end;

    [Test]
    [HandlerFunctions('SuggestEmployeePaymentsDefaultValuesForRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestEmployeePaymentToVerifyRequestPage()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE Select Employee Payments]
        // [SCENARIO 159865] Test suggest Employee payment request page defaults correct values.

        // Setup:
        Initialize();

        // [GIVEN] Create GenJournalLine and Post it. Run Suggest Employee Payment.
        CreateGenJnlLineWithEmployeeBalAcc(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        SetupGenJnlLine(GenJournalLine);

        // [WHEN] Run Suggest Employee Payments is run
        SuggestEmployeePaymentUsingPage(GenJournalLine);

        // [THEN] SuggestEmployeePaymentsDefaultValuesForRequestPageHandler page handler will verify default values
    end;

    local procedure SuggestPaymentForEmployee()
    var
        GenJournalLine: Record "Gen. Journal Line";
        EmployeeNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // 1. Setup: Create and Post Expense for Employee.
        EmployeeNo := LibraryHumanResource.CreateEmployeeNoWithBankAccount();
        GLAccountNo := LibraryERM.CreateGLAccountNo();

        LibraryVariableStorage.Enqueue(EmployeeNo);
        LibraryVariableStorage.Enqueue(GLAccountNo);

        CreateExpenseForEmployeeToGiveNegativeBalance(GenJournalLine, EmployeeNo);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // 2. Exercise: Suggest Employee Payment using Page. Using Page is because InitializeRequest of Report does not have the option to set value in "Use Employee Priority" Field.
        SuggestEmployeePaymentUsingPage(GenJournalLine);

        // 3. Verify: Verify that Payment is not suggested for the Employee with Debit Balance.
        VerifyJournalLinesNotSuggested(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,SuggestEmployeePaymentsRequestWithBnkPmtTypePageHandler')]
    [Scope('OnPrem')]
    procedure SuggestEmployeePaymentWithElectronicPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SuggestEmployeePayments: Report "Suggest Employee Payments";
        BankAccountNo: Code[20];
        EmployeeNo: Code[20];
    begin
        // [FEATURE] [Bank Payment Type]
        // [SCENARIO] Stan can set "Electronic Payment" as "Bank Payment Type" on request page of "Suggest Employee Payments" report
        Initialize();

        // [GIVEN] Posted journal with type <blank> for Employee A for Amount = -100
        BankAccountNo := LibraryERM.CreateBankAccountNo();
        CreateAndPostGeneralJournalLine(GenJournalLine, GenJournalLine."Document Type"::" ");
        EmployeeNo := GenJournalLine."Account No.";

        // [WHEN] Run Report "Suggest Employee Payment" for Employee A with "Bank Payment Type" set to "Electronic Payment"
        SuggestEmployeePayments.SetGenJnlLine(GenJournalLine);
        LibraryVariableStorage.Enqueue(EmployeeNo);
        LibraryVariableStorage.Enqueue(GenJournalLine."Bal. Account Type"::"Bank Account");
        LibraryVariableStorage.Enqueue(BankAccountNo);
        LibraryVariableStorage.Enqueue(GenJournalLine."Bank Payment Type"::"Electronic Payment");
        SuggestEmployeePayments.Run();

        // [THEN] Payment Journal Line created for Employee A with Ammout 100 with "Bank Payment Type" = "Electronic Payment"
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Electronic Payment");
        GenJournalLine.SetRange("Account No.", EmployeeNo);
        GenJournalLine.SetRange(Amount, -GenJournalLine.Amount);
        Assert.RecordIsNotEmpty(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,SuggestEmployeePaymentsRequestWithBnkPmtTypePageHandler')]
    [Scope('OnPrem')]
    procedure SuggestEmployeePaymentWithElectronicPaymentIAT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        SuggestEmployeePayments: Report "Suggest Employee Payments";
        BankAccountNo: Code[20];
        EmployeeNo: Code[20];
    begin
        // [FEATURE] [Bank Payment Type]
        // [SCENARIO] Stan can set "Electronic Payment-IAT" as "Bank Payment Type" on request page of "Suggest Employee Payments" report
        Initialize();

        // [GIVEN] Posted journal with type <blank> for Employee A with Amount = -100
        BankAccountNo := LibraryERM.CreateBankAccountNo();
        CreateAndPostGeneralJournalLine(GenJournalLine, GenJournalLine."Document Type"::" ");
        EmployeeNo := GenJournalLine."Account No.";

        // [WHEN] Run Report "Suggest Employee Payment" for Employee A with "Bank Payment Type" set to "Electronic Payment-IAT" in request page of a report
        SuggestEmployeePayments.SetGenJnlLine(GenJournalLine);
        LibraryVariableStorage.Enqueue(EmployeeNo);
        LibraryVariableStorage.Enqueue(GenJournalLine."Bal. Account Type"::"Bank Account");
        LibraryVariableStorage.Enqueue(BankAccountNo);
        LibraryVariableStorage.Enqueue(GenJournalLine."Bank Payment Type"::"Electronic Payment-IAT");
        SuggestEmployeePayments.Run();

        // [THEN] Payment Journal Line created for Employee A with Ammout 100 with "Bank Payment Type" = "Electronic Payment-IAT"
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Bank Payment Type", GenJournalLine."Bank Payment Type"::"Electronic Payment-IAT");
        GenJournalLine.SetRange("Account No.", EmployeeNo);
        GenJournalLine.SetRange(Amount, -GenJournalLine.Amount);
        Assert.RecordIsNotEmpty(GenJournalLine);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure CheckRecipientBankAccount()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        EmployeeNo: Code[20];
    begin
        // [SCENARIO 273537] Suggest Employee Payments fills recipient bank account with Employee No.

        Initialize();

        // [GIVEN] Employee 'X'
        // [GIVEN] Posted General Journal Line, where "Bal. Account Type" = 'Employee', "Bal. Account No." = 'X'
        EmployeeNo := CreateGenJnlLineWithEmployeeBalAcc(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Run report "Suggest Employee Payments"
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Payments);
        SuggestEmployeePayment(
          GenJournalBatch,
          EmployeeNo,
          GenJournalLine."Bal. Account Type"::"Bank Account",
          CreateBankAccount(''),
          GenJournalLine."Bank Payment Type"::" ",
          false);

        // [THEN] New payment journal line is created, where "Account No." = 'X', "Recipient Bank Account" = 'X'
        VerifyGenJnlLineRecipientBankAccount(EmployeeNo);
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CreateEmployeePaymentWhenBatchNotExists()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        CreateEmployeePayment: TestPage "Create Employee Payment";
    begin
        // [FEATURE] [UI] [Create Employee Payment]
        // [SCENARIO 294543] When run page Create Employee Payment for non-existent Batch, then no error and Batch Name is cleared on page
        Initialize();
        GenJournalTemplate.DeleteAll();

        // [GIVEN] Created Gen. Journal Batch with payment Template
        LibraryJournals.CreateGenJournalBatchWithType(GenJournalBatch, GenJournalBatch."Template Type"::Payments);

        // [GIVEN] Ran page Create Employee Payment, set Batch Name and pushed OK
        CreateEmployeePayment.OpenEdit();
        CreateEmployeePayment."Batch Name".SetValue(GenJournalBatch.Name);
        CreateEmployeePayment."Starting Document No.".SetValue(LibraryRandom.RandInt(100));
        CreateEmployeePayment.OK().Invoke();

        // [GIVEN] Deleted Gen Journal Batch
        GenJournalBatch.Delete();

        // [WHEN] Run page Create Employee Payment
        CreateEmployeePayment.OpenEdit();

        // [THEN] Page Create Employee Payment shows Batch Name = Blank
        Assert.AreEqual('', Format(CreateEmployeePayment."Batch Name"), '');
        CreateEmployeePayment.Close();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure CreateEmployeePaymentWhenTemplateNotExists()
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        CreateEmployeePayment: TestPage "Create Employee Payment";
    begin
        // [FEATURE] [UI] [Create Employee Payment]
        // [SCENARIO 294543] When run page Create Employee Payment and no Gen. Journal Templates exist, then no error and Batch Name is cleared on page
        Initialize();

        // [GIVEN] Removed all Gen. Journal Templates
        GenJournalTemplate.DeleteAll();

        // [WHEN] Run page Create Employee Payment
        CreateEmployeePayment.OpenEdit();

        // [THEN] Page Create Employee Payment shows Batch Name = Blank
        Assert.AreEqual('', Format(CreateEmployeePayment."Batch Name"), '');
        CreateEmployeePayment.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateEmployeePaymentStartingDocumentNo()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        CreateEmployeePayment: TestPage "Create Employee Payment";
    begin
        // [FEATURE] [UI] [Create Employee Payment]
        // [SCENARIO 297928] Choosing Batch name on Create Employee Payment page leads to "Starting Document No." being equal to increment of last Gen. Journal Line's "Document No."
        Initialize();

        // [GIVEN] Gen. Journal Batch "B" with No. Series
        LibraryUtility.CreateNoSeries(NoSeries, false, false, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, '', '');
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::Payments);
        GenJournalBatch.Validate("No. Series", NoSeries.Code);
        GenJournalBatch.Modify(true);

        // [GIVEN] Gen. Journal line in Batch "B" with "Document No." equal to 100
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, WorkDate(), LibraryHumanResource.CreateEmployeeNo(),
          GenJournalLine."Document Type"::Payment, -LibraryRandom.RandInt(10));

        // [WHEN] On Create Employee Payment page "Batch name" is set to "B"
        CreateEmployeePayment.OpenEdit();
        CreateEmployeePayment."Batch Name".SetValue(GenJournalBatch.Name);

        // [THEN] "Starting Document No." is equal to 101
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindLast();
        CreateEmployeePayment."Starting Document No.".AssertEquals(IncStr(GenJournalLine."Document No."));
        CreateEmployeePayment.Close();
    end;

    [Test]
    [HandlerFunctions('SuggestEmployeePaymentsWithStartingNoSummarizedNewDocPerLineRPH')]
    [Scope('OnPrem')]
    procedure SuggestEmployeePaymentsTwoEmpoyeesNoSeriesIncrBy10()
    var
        Employee: array[2] of Record Employee;
        NoSeriesLine: Record "No. Series Line";
        GenJournalLine: Record "Gen. Journal Line";
        Index: Integer;
        EmployeeAmount: Decimal;
    begin
        // [FEATURE] [No. Series]
        // [SCENARIO 342243] "Suggest Employee Payments" report considers "Increment by No." setup in number series of general journal batch
        Initialize();

        for Index := 1 to ArrayLen(Employee) do begin
            CreateAndPostGeneralJournalLine(GenJournalLine, GenJournalLine."Document Type"::" ");
            Employee[Index].Get(GenJournalLine."Account No.");
            EmployeeAmount += GenJournalLine."Amount (LCY)";
        end;

        CreateNoSeriesWithIncrementByNo(NoSeriesLine, 10, 'A0001', 'A9999');

        SetupGenJournalLineForSuggestEmployeePayments(GenJournalLine, NoSeriesLine);

        LibraryVariableStorage.Enqueue(StrSubstNo('%1|%2', Employee[1]."No.", Employee[2]."No."));
        LibraryVariableStorage.Enqueue(-EmployeeAmount);
        LibraryVariableStorage.Enqueue(NoSeriesLine."Starting No.");
        LibraryVariableStorage.Enqueue(false); // Summarize - FALSE
        LibraryVariableStorage.Enqueue(false); // New Doc. No. per Line - FALSE

        Commit();

        RunSuggestEmployeePaymentsWithRequestPage(GenJournalLine);

        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Document No.", 'A0001');

        GenJournalLine.Next();
        GenJournalLine.TestField("Document No.", 'A0011');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SuggestEmployeePaymentsWithStartingNoSummarizedNewDocPerLineRPH')]
    [Scope('OnPrem')]
    procedure SuggestEmployeePaymentsTwoEmployeesNoSeriesIncrBy10SummarizedByEmployee()
    var
        Employee: array[2] of Record Employee;
        NoSeriesLine: Record "No. Series Line";
        GenJournalLine: Record "Gen. Journal Line";
        EmployeeIndex: Integer;
        DocIndex: Integer;
        EmployeeAmount: Decimal;
    begin
        // [FEATURE] [No. Series]
        // [SCENARIO 342243] "Suggest Employee Payments" report considers "Increment by No." setup in number series of general journal batch when "Summarized per Employee" = TRUE
        Initialize();

        for EmployeeIndex := 1 to ArrayLen(Employee) do begin
            LibraryHumanResource.CreateEmployeeWithBankAccount(Employee[EmployeeIndex]);
            for DocIndex := 1 to 2 do begin
                Clear(GenJournalLine);
                LibraryJournals.CreateGenJournalLineWithBatch(
                  GenJournalLine, GenJournalLine."Document Type"::" ",
                  GenJournalLine."Account Type"::Employee, Employee[EmployeeIndex]."No.", -LibraryRandom.RandDec(100, 2));

                LibraryERM.PostGeneralJnlLine(GenJournalLine);
                EmployeeAmount += GenJournalLine."Amount (LCY)";
            end;
        end;

        CreateNoSeriesWithIncrementByNo(NoSeriesLine, 10, 'A0001', 'A9999');

        SetupGenJournalLineForSuggestEmployeePayments(GenJournalLine, NoSeriesLine);

        LibraryVariableStorage.Enqueue(StrSubstNo('%1|%2', Employee[1]."No.", Employee[2]."No."));
        LibraryVariableStorage.Enqueue(-EmployeeAmount);
        LibraryVariableStorage.Enqueue(NoSeriesLine."Starting No.");
        LibraryVariableStorage.Enqueue(true); // Summarize - TRUE
        LibraryVariableStorage.Enqueue(true); // New Doc. No. per Line - TRUE

        Commit();

        RunSuggestEmployeePaymentsWithRequestPage(GenJournalLine);

        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Document No.", 'A0001');
        GenJournalLine.TestField("Account No.", Employee[1]."No.");

        GenJournalLine.Next();
        GenJournalLine.TestField("Document No.", 'A0011');
        GenJournalLine.TestField("Account No.", Employee[2]."No.");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SuggestEmployeePaymentsWithStartingNoSummarizedNewDocPerLineRPH')]
    [Scope('OnPrem')]
    procedure SuggestEmployeePaymentsTwoEmployeesNoSeriesIncrBy10DocNoPerLine()
    var
        Employee: array[2] of Record Employee;
        NoSeriesLine: Record "No. Series Line";
        GenJournalLine: Record "Gen. Journal Line";
        EmployeeIndex: Integer;
        DocIndex: Integer;
        EmployeeAmount: Decimal;
    begin
        // [FEATURE] [No. Series]
        // [SCENARIO 342243] "Suggest Employee Payments" report considers "Increment by No." setup in number series of general journal batch when "New Doc. No. per Line" = TRUE
        Initialize();

        for EmployeeIndex := 1 to ArrayLen(Employee) do begin
            LibraryHumanResource.CreateEmployeeWithBankAccount(Employee[EmployeeIndex]);
            for DocIndex := 1 to 2 do begin
                Clear(GenJournalLine);
                LibraryJournals.CreateGenJournalLineWithBatch(
                  GenJournalLine, GenJournalLine."Document Type"::" ",
                  GenJournalLine."Account Type"::Employee, Employee[EmployeeIndex]."No.", -LibraryRandom.RandDec(100, 2));

                LibraryERM.PostGeneralJnlLine(GenJournalLine);
                EmployeeAmount += GenJournalLine."Amount (LCY)";
            end;
        end;

        CreateNoSeriesWithIncrementByNo(NoSeriesLine, 10, 'A0001', 'A9999');

        SetupGenJournalLineForSuggestEmployeePayments(GenJournalLine, NoSeriesLine);

        LibraryVariableStorage.Enqueue(StrSubstNo('%1|%2', Employee[1]."No.", Employee[2]."No."));
        LibraryVariableStorage.Enqueue(-EmployeeAmount);
        LibraryVariableStorage.Enqueue(NoSeriesLine."Starting No.");
        LibraryVariableStorage.Enqueue(false); // Summarize - FALSE
        LibraryVariableStorage.Enqueue(true); // New Doc. No. per Line - TRUE

        Commit();

        RunSuggestEmployeePaymentsWithRequestPage(GenJournalLine);

        GenJournalLine.FindFirst();
        GenJournalLine.TestField("Document No.", 'A0001');
        GenJournalLine.TestField("Account No.", Employee[1]."No.");

        GenJournalLine.Next();
        GenJournalLine.TestField("Document No.", 'A0011');
        GenJournalLine.TestField("Account No.", Employee[1]."No.");

        GenJournalLine.Next();
        GenJournalLine.TestField("Document No.", 'A0021');
        GenJournalLine.TestField("Account No.", Employee[2]."No.");

        GenJournalLine.Next();
        GenJournalLine.TestField("Document No.", 'A0031');
        GenJournalLine.TestField("Account No.", Employee[2]."No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('SuggestEmployeePaymentsWithStartingNo')]
    procedure SuggestEmployeePaymentsEmployeesNoSeriesShouldHaveCorrectSeries()
    var
        Employee: array[2] of Record Employee;
        NoSeriesLine: Record "No. Series Line";
        GenJournalLine: Record "Gen. Journal Line";
        EmployeeIndex: Integer;
    begin
        // [SCENARIO 342243] "Suggest Employee Payments" report considers "Increment by No." setup in number series of general journal batch when "New Doc. No. per Line" = TRUE
        Initialize();

        // [GIVEN] Create Employee with Bank Account, Create and Post General Journal.
        for EmployeeIndex := 1 to ArrayLen(Employee) do begin
            LibraryHumanResource.CreateEmployeeWithBankAccount(Employee[EmployeeIndex]);
            Clear(GenJournalLine);
            LibraryJournals.CreateGenJournalLineWithBatch(
                GenJournalLine, GenJournalLine."Document Type"::" ",
               GenJournalLine."Account Type"::Employee, Employee[EmployeeIndex]."No.",
               -LibraryRandom.RandDec(100, 2));

            LibraryERM.PostGeneralJnlLine(GenJournalLine);
        end;

        // [GIVEN] Create No. Series and Increment No. Series.
        CreateNoSeriesWithIncrementByNo(NoSeriesLine, LibraryRandom.RandInt(1), LibraryERM.CreateNoSeriesCode(), LibraryERM.CreateNoSeriesCode());

        // [GIVEN] Setup General Journal to Suggest Employee payments.
        SetupGenJournalLineForSuggestEmployeePayments(GenJournalLine, NoSeriesLine);

        // [GIVEN] Enqueue Employee Filter, Starting No. Summarize and New Doc. No. Per Line.
        LibraryVariableStorage.Enqueue(StrSubstNo('%1|%2', Employee[1]."No.", Employee[2]."No."));
        LibraryVariableStorage.Enqueue(NoSeriesLine."Starting No.");
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(false);

        // [WHEN] Run Suggest Employee Payment Report.
        Commit();
        RunSuggestEmployeePaymentsWithRequestPage(GenJournalLine);

        // [THEN] No. Series should not increase on new line when New Doc. No. Per Line is disabled.
        GenJournalLine.SetFilter("Account No.", '%1|%2', Employee[1]."No.", Employee[2]."No.");
        GenJournalLine.FindLast();
        Assert.AreEqual(NoSeriesLine."Starting No.", GenJournalLine."Document No.", DocumentNoErr);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Suggest Employee Payment");
        ClearSelectedDim();

        LibraryVariableStorage.Clear();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Suggest Employee Payment");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateGenJournalTemplate();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Suggest Employee Payment");
    end;

    local procedure ApplyPaymentToEmployee(AccountNo: Code[20]; NumberOfLines: Integer; DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type")
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        EmployeeLedgerEntry2: Record "Employee Ledger Entry";
    begin
        FindEmployeeLedgerEntry(EmployeeLedgerEntry, AccountNo, DocumentType2);
        FindEmployeeLedgerEntry(EmployeeLedgerEntry2, AccountNo, DocumentType);
        repeat
            EmployeeLedgerEntry2.Validate("Amount to Apply", -EmployeeLedgerEntry.Amount / NumberOfLines);
            EmployeeLedgerEntry2.Modify(true);
        until EmployeeLedgerEntry2.Next() = 0;
        LibraryERM.SetAppliestoIdEmployee(EmployeeLedgerEntry2);
    end;

    local procedure ApplyGenJnlLineEntryToExpense(var GenJournalLine: Record "Gen. Journal Line"; ExpenseNo: Code[20])
    begin
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Document Type"::" ");
        GenJournalLine.Validate("Applies-to Doc. No.", ExpenseNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CheckGenJnlLineAfterSuggestEmployeePayment(Limit: Decimal; NoOfPayment: Integer; SecondExpenseAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
        Employee: Record Employee;
    begin
        // Setup: Create Employee and Create and post Gen journal line with document type Expense.
        Initialize();
        LibraryHumanResource.CreateEmployeeWithBankAccount(Employee);
        CreateAndPostMultipleGenJnlLine(GenJournalLine, Employee."No.", LibraryRandom.RandIntInRange(15, 20), SecondExpenseAmount);
        LibraryVariableStorage.Enqueue(Employee."No.");
        LibraryVariableStorage.Enqueue(Limit);

        // Exercise: Run report suggest Employee payment
        SuggestEmployeePaymentUsingPage(GenJournalLine);

        // Verify:
        VerifyAmountDoesNotExceedLimit(GenJournalLine, Limit, NoOfPayment);
    end;

    local procedure CreateAndPostMultipleGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; EmployeeNo: Code[20]; FirstExpenseAmount: Decimal; SecondExpenseAmount: Decimal)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::General);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, WorkDate(), EmployeeNo, GenJournalLine."Document Type"::" ",
          -FirstExpenseAmount);
        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, WorkDate(), EmployeeNo, GenJournalLine."Document Type"::" ",
          -SecondExpenseAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; Type: Enum "Gen. Journal Template Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.SetRange(Type, Type);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateExpenseForEmployeeToGiveNegativeBalance(var GenJournalLine: Record "Gen. Journal Line"; EmployeeNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Take Random Amount for expense and make it positive, so the employee will have negative balance.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Employee, EmployeeNo, LibraryRandom.RandDec(100, 2));
    end;

    local procedure CreateBankAccount(CurrencyCode: Code[10]): Code[20]
    var
        BankAccount: Record "Bank Account";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
    begin
        BankAccountPostingGroup.FindFirst();
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Currency Code", CurrencyCode);
        BankAccount.Validate("Bank Acc. Posting Group", BankAccountPostingGroup.Code);
        BankAccount.Modify(true);
        exit(BankAccount."No.");
    end;

    local procedure CreateMultipleGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; NumberOfLines: Integer; PostingDate: Date; EmployeeNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; AmountSign: Integer) AmountSum: Integer
    var
        Counter: Integer;
    begin
        for Counter := 1 to NumberOfLines do begin
            // Required value for Amount field is not important
            CreateGeneralJournalLine(
              GenJournalLine, GenJournalBatch, PostingDate, EmployeeNo, DocumentType, AmountSign * LibraryRandom.RandInt(100));
            AmountSum := AmountSum + GenJournalLine.Amount;
        end;
    end;

    local procedure CreateAndPostGeneralJournal(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type") DocumentNo: Code[20]
    var
        Employee: Record Employee;
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryHumanResource.CreateEmployeeWithBankAccount(Employee);
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::General);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, WorkDate(), Employee."No.", DocumentType, -LibraryRandom.RandDec(100, 2));
        DocumentNo := GenJournalLine."Document No.";

        CreateGeneralJournalLine(GenJournalLine, GenJournalBatch, WorkDate(), Employee."No.", DocumentType, GenJournalLine.Amount * 2);
        UpdateOnHoldOnGenJournalLine(GenJournalLine, GetOnHold());
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type")
    var
        Employee: Record Employee;
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryHumanResource.CreateEmployeeWithBankAccount(Employee);
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::General);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalBatch, WorkDate(), Employee."No.", DocumentType, -LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; PostingDate: Date; EmployeeNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Employee, EmployeeNo, Amount);
        GenJournalLine.Validate("Document No.", GenJournalBatch.Name + Format(GenJournalLine."Line No."));
        GenJournalLine.Validate("External Document No.", GenJournalLine."Document No.");
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalLine.Modify(true);
    end;

    local procedure CreatePostGenJnlLineRunSuggestEmployeePayments(var GenJournalLine: Record "Gen. Journal Line"; var ShortcutDim1Code: Code[20])
    var
        EmployeeNo: Code[20];
        ShortcutDim2Code: Code[20];
    begin
        EmployeeNo := CreateGenJnlLineWithEmployeeBalAcc(GenJournalLine);
        LibraryVariableStorage.Enqueue(EmployeeNo);
        UpdateDimensionOnGeneralJournalLine(GenJournalLine);
        ShortcutDim1Code := GenJournalLine."Shortcut Dimension 1 Code";
        ShortcutDim2Code := GenJournalLine."Shortcut Dimension 2 Code";
        UpdateDiffDimensionOnEmployee(EmployeeNo, ShortcutDim1Code, ShortcutDim2Code);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        SetupGenJnlLine(GenJournalLine);
        SuggestEmployeePaymentUsingPage(GenJournalLine);
        FindGeneralJournalLines(GenJournalLine);
    end;

    local procedure CreateDefDimWithFoundDimValue(DimensionCode: Code[20]; TableID: Integer; EmployeeNo: Code[20]): Code[20]
    var
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
    begin
        LibraryDimension.FindDimensionValue(DimensionValue, DimensionCode);
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, TableID, EmployeeNo, DimensionValue."Dimension Code", DimensionValue.Code);
        exit(DimensionValue.Code);
    end;

    local procedure CreateEmployeeWithDimensions(var EmployeeNo: Code[20]; var DimSetID: Integer)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        EmployeeNo := LibraryHumanResource.CreateEmployeeNoWithBankAccount();
        GLSetup.Get();
        DimSetID :=
          LibraryDimension.CreateDimSet(
            0, GLSetup."Global Dimension 1 Code",
            CreateDefDimWithFoundDimValue(GLSetup."Global Dimension 1 Code", DATABASE::Employee, EmployeeNo));
        DimSetID :=
          LibraryDimension.CreateDimSet(
            DimSetID, GLSetup."Global Dimension 2 Code",
            CreateDefDimWithFoundDimValue(GLSetup."Global Dimension 2 Code", DATABASE::Employee, EmployeeNo));
    end;

    local procedure CreateNoSeriesWithIncrementByNo(var NoSeriesLine: Record "No. Series Line"; IncrementByNo: Integer; StartingNo: Code[20]; EndingNo: Code[20])
    var
        NoSeries: Record "No. Series";
    begin
        NoSeries.Get(LibraryERM.CreateNoSeriesCode());
        NoSeriesLine.SetRange("Series Code", NoSeries.Code);
        NoSeriesLine.FindFirst();
        NoSeriesLine."Starting No." := StartingNo;
        NoSeriesLine."Ending No." := EndingNo;
        NoSeriesLine."Increment-by No." := IncrementByNo;
        NoSeriesLine.Modify();
    end;

    local procedure GetOnHold(): Code[3]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        exit(
          CopyStr(
            LibraryUtility.GenerateRandomCode(GenJournalLine.FieldNo("On Hold"), DATABASE::"Gen. Journal Line"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Gen. Journal Line", GenJournalLine.FieldNo("On Hold"))));
    end;

    local procedure FindAndPostPaymentJournalLine(GenJournalBatch: Record "Gen. Journal Batch"): Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(GenJournalLine."Document No.");
    end;

    local procedure FindEmployeeLedgerEntry(var EmployeeLedgerEntry: Record "Employee Ledger Entry"; EmployeeNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        EmployeeLedgerEntry.SetRange("Document Type", DocumentType);
        EmployeeLedgerEntry.SetRange("Employee No.", EmployeeNo);
        EmployeeLedgerEntry.FindSet();
    end;

    local procedure RunSuggestEmployeePaymentsWithRequestPage(var GenJournalLine: Record "Gen. Journal Line")
    var
        SuggestEmployeePayments: Report "Suggest Employee Payments";
    begin
        SuggestEmployeePayments.SetGenJnlLine(GenJournalLine);
        SuggestEmployeePayments.RunModal();
    end;

    local procedure SetupAndCreateGenJournalLines(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch") BankAccountNo: Code[20]
    var
        Employee: Record Employee;
        CurrencyCode: Code[10];
        NoOfLines: Integer;
    begin
        // Setup: Create Currency, Bank Account, Employee and General Journal Lines.
        CurrencyCode := '';
        BankAccountNo := CreateBankAccount(CurrencyCode);

        // Create 2 to 10 Gen. Journal Lines Boundary 2 is important to test Suggest Employee Payment for multiple lines.
        NoOfLines := 2 * LibraryRandom.RandInt(5);
        LibraryHumanResource.CreateEmployeeWithBankAccount(Employee);
        CreateMultipleGenJournalLine(
          GenJournalLine, GenJournalBatch, NoOfLines, WorkDate(), Employee."No.", GenJournalLine."Document Type"::" ", -1);
    end;

    local procedure SetupGenJournalLineForSuggestEmployeePayments(var GenJournalLine: Record "Gen. Journal Line"; NoSeriesLine: Record "No. Series Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        GenJournalBatch.Validate("No. Series", NoSeriesLine."Series Code");
        GenJournalBatch.Modify(true);

        GenJournalLine.Init();
        GenJournalLine.Validate("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.Validate("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
    end;

    local procedure SuggestEmployeePayment(GenJournalBatch: Record "Gen. Journal Batch"; EmployeeNo: Code[20]; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20]; BankPaymentType: Enum "Bank Payment Type"; SummarizePerEmployee: Boolean)
    var
        Employee: Record Employee;
        GenJournalLine: Record "Gen. Journal Line";
        SuggestEmployeePayments: Report "Suggest Employee Payments";
    begin
        GenJournalLine.Init();  // INIT is mandatory for Gen. Journal Line to Set the General Template and General Batch Name.
        GenJournalLine.Validate("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.Validate("Journal Batch Name", GenJournalBatch.Name);
        SuggestEmployeePayments.SetGenJnlLine(GenJournalLine);

        if EmployeeNo = '' then
            Employee.SetRange("No.")
        else
            Employee.SetRange("No.", EmployeeNo);
        SuggestEmployeePayments.SetTableView(Employee);

        // Required Random Value for "Document No." field value is not important.
        SuggestEmployeePayments.InitializeRequest(
          0, false, WorkDate(), Format(LibraryRandom.RandInt(100)),
          SummarizePerEmployee, BalAccountType, BalAccountNo, BankPaymentType);
        SuggestEmployeePayments.UseRequestPage(false);
        SuggestEmployeePayments.RunModal();
    end;

    local procedure SuggestEmployeePaymentUsingPage(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        SuggestEmployeePayments: Report "Suggest Employee Payments";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        GenJournalLine.Init();  // INIT is mandatory for Gen. Journal Line to Set the General Template and General Batch Name.
        GenJournalLine.Validate("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.Validate("Journal Batch Name", GenJournalBatch.Name);

        Commit();  // Commit required to avoid test failure.
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Batch Name");

        SuggestEmployeePayments.SetGenJnlLine(GenJournalLine);
        SuggestEmployeePayments.Run();
    end;

    local procedure UpdateOnHoldOnGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; OnHold: Code[3])
    begin
        GenJournalLine.Validate("On Hold", OnHold);
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; EmployeeNo: Code[20])
    begin
        FindGeneralJournalLines(GenJournalLine);
        GenJournalLine.ModifyAll("Bal. Account Type", GenJournalLine."Bal. Account Type"::Employee, true);
        GenJournalLine.ModifyAll("Bal. Account No.", EmployeeNo, true);
        UpdateDimensionOnGeneralJournalLine(GenJournalLine);
    end;

    local procedure UpdateDimensionOnGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
        DimensionValue2: Record "Dimension Value";
    begin
        GeneralLedgerSetup.Get();
        FindGeneralJournalLines(GenJournalLine); // Find General Journal Line to update Dimension on first record.
        LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Shortcut Dimension 1 Code");
        GenJournalLine.Validate("Shortcut Dimension 1 Code", DimensionValue.Code);
        LibraryDimension.FindDimensionValue(DimensionValue2, GeneralLedgerSetup."Shortcut Dimension 2 Code");
        GenJournalLine.Validate("Shortcut Dimension 2 Code", DimensionValue2.Code);
        GenJournalLine.Modify(true);
    end;

    local procedure UpdateDiffDimensionOnEmployee(EmployeeNo: Code[20]; GlobalDimValueCode1: Code[20]; GlobalDimValueCode2: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DefaultDimension: Record "Default Dimension";
    begin
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::Employee, EmployeeNo, GeneralLedgerSetup."Shortcut Dimension 1 Code",
          LibraryDimension.FindDifferentDimensionValue(GeneralLedgerSetup."Shortcut Dimension 1 Code", GlobalDimValueCode1));
        LibraryDimension.CreateDefaultDimension(
          DefaultDimension, DATABASE::Employee, EmployeeNo, GeneralLedgerSetup."Shortcut Dimension 2 Code",
          LibraryDimension.FindDifferentDimensionValue(GeneralLedgerSetup."Shortcut Dimension 2 Code", GlobalDimValueCode2));
    end;

    local procedure ClearSelectedDim()
    var
        SelectedDim: Record "Selected Dimension";
    begin
        SelectedDim.SetRange("User ID", UserId);
        SelectedDim.SetRange("Object Type", 3);
        SelectedDim.SetRange("Object ID", REPORT::"Suggest Employee Payments");
        SelectedDim.DeleteAll(true);
    end;

    local procedure CreateGeneralJournalWithAccountTypeGLAccount(var GenJournalLine: Record "Gen. Journal Line"; GLAccountNo: Code[20])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Create General Journal Lines & Take Random Amount for Expense.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccountNo, LibraryRandom.RandDec(100, 2));
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", GLAccountNo, LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Document No.", IncStr(GenJournalLine."Document No."));
        GenJournalLine.Validate("External Document No.", GenJournalLine."Document No.");
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGenJnlLineWithEmployeeBalAcc(var GenJournalLine: Record "Gen. Journal Line"): Code[20]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        Employee: Record Employee;
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalTemplate.Name, GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), LibraryRandom.RandDecInRange(10, 1000, 2));
        LibraryHumanResource.CreateEmployeeWithBankAccount(Employee);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::Employee);
        GenJournalLine.Validate("Bal. Account No.", Employee."No.");
        GenJournalLine.Modify(true);
        exit(Employee."No.");
    end;

    local procedure FindGeneralJournalLines(var GenJournalLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine.FindSet();
    end;

    local procedure GetDimensionFilterText(): Text
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionSelectionBuffer: Record "Dimension Selection Buffer";
    begin
        GeneralLedgerSetup.Get();
        DimensionSelectionBuffer.SetFilter(
          Code, '%1|%2', GeneralLedgerSetup."Shortcut Dimension 1 Code", GeneralLedgerSetup."Shortcut Dimension 2 Code");
        exit(DimensionSelectionBuffer.GetFilter(Code));
    end;

    local procedure GetEmployeeDefaultDim(EmplNo: Code[20]; DimensionCode: Code[20]): Code[20]
    var
        DefaultDimension: Record "Default Dimension";
    begin
        DefaultDimension.Get(DATABASE::Employee, EmplNo, DimensionCode);
        exit(DefaultDimension."Dimension Value Code");
    end;

    local procedure CopyTempGenJournalLine(GenJournalLine: Record "Gen. Journal Line"; var GenJournalLine2: Record "Gen. Journal Line")
    begin
        FindGeneralJournalLines(GenJournalLine);
        repeat
            GenJournalLine2 := GenJournalLine;
            GenJournalLine2.Insert();
        until GenJournalLine.Next() = 0;
    end;

    local procedure VerifyAmountDoesNotExceedLimit(GenJournalLine: Record "Gen. Journal Line"; Limit: Integer; NoOfPayment: Integer)
    var
        SuggestEmployeeGenJnlLine: Record "Gen. Journal Line";
    begin
        SuggestEmployeeGenJnlLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        SuggestEmployeeGenJnlLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        SuggestEmployeeGenJnlLine.CalcSums(Amount);
        if Limit <> 0 then
            Assert.IsTrue(SuggestEmployeeGenJnlLine.Amount <= Limit, SuggestEmployeeAmountErr);
        Assert.AreEqual(NoOfPayment, SuggestEmployeeGenJnlLine.Count, NoOfPaymentErr);
    end;

    local procedure VerifyGenJournalEntriesAmount(EmployeeNo: Code[20])
    var
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        Assert: Codeunit Assert;
        TotalAmountLCY: Decimal;
    begin
        GenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Employee);
        GenJournalLine.SetRange("Account No.", EmployeeNo);
        GenJournalLine.FindFirst();
        EmployeeLedgerEntry.SetRange("Document Type", EmployeeLedgerEntry."Document Type"::" ");
        EmployeeLedgerEntry.SetRange("Employee No.", GenJournalLine."Account No.");
        EmployeeLedgerEntry.FindSet();
        repeat
            EmployeeLedgerEntry.CalcFields("Amount (LCY)");
            TotalAmountLCY += Abs(EmployeeLedgerEntry."Amount (LCY)");
        until EmployeeLedgerEntry.Next() = 0;

        Assert.AreNearlyEqual(
          TotalAmountLCY, GenJournalLine."Amount (LCY)", Currency."Amount Rounding Precision",
          StrSubstNo(AmountErrorMessageMsg, GenJournalLine.FieldCaption("Amount (LCY)"),
            TotalAmountLCY, GenJournalLine."Journal Template Name",
            GenJournalLine."Journal Batch Name", GenJournalLine."Line No."));
    end;

    local procedure VerifyJournalLinesNotSuggested(JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.Init();
        GenJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        GenJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        Assert.RecordIsEmpty(GenJournalLine);
    end;

    local procedure VerifyRemainingOnEmployeeLedger(EmployeeNo: Code[20])
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        EmployeeLedgerEntry.SetRange("Employee No.", EmployeeNo);
        EmployeeLedgerEntry.FindSet();
        repeat
            EmployeeLedgerEntry.CalcFields("Remaining Amount");
            EmployeeLedgerEntry.TestField("Remaining Amount", 0);
        until EmployeeLedgerEntry.Next() = 0;
    end;

    local procedure VerifyEmployeeLedgerEntry(EmployeeNo: Code[20]; EmployeeLedgerEntryCount: Integer)
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        EmployeeLedgerEntry.Init();
        EmployeeLedgerEntry.SetRange("Employee No.", EmployeeNo);
        EmployeeLedgerEntry.SetFilter("Applies-to ID", '<>''''');
        Assert.RecordCount(EmployeeLedgerEntry, EmployeeLedgerEntryCount);
    end;

    local procedure VerifyValuesOnEmplLedgerEntry(DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; EmployeeNo: Code[20]; Amount2: Decimal; RemainingAmount: Decimal; Open2: Boolean)
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        EmployeeLedgerEntry.SetRange("Document No.", DocumentNo);
        EmployeeLedgerEntry.SetRange("Document Type", DocumentType);
        EmployeeLedgerEntry.SetRange("Employee No.", EmployeeNo);
        EmployeeLedgerEntry.FindFirst();
        EmployeeLedgerEntry.CalcFields(Amount, "Remaining Amount");
        Assert.AreNearlyEqual(Amount2, EmployeeLedgerEntry.Amount, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValidateErrorErr, EmployeeLedgerEntry.FieldCaption(Amount), Amount2, EmployeeLedgerEntry.TableCaption(), EmployeeLedgerEntry.FieldCaption("Entry No."), EmployeeLedgerEntry."Entry No."));
        EmployeeLedgerEntry.TestField("Remaining Amount", RemainingAmount);
        EmployeeLedgerEntry.TestField(Open, Open2);
    end;

    local procedure VerifyValuesOnGLEntry(GenJournalLine: Record "Gen. Journal Line"; ShortcutDimension1Code: Code[20]; ShortcutDimension2Code: Code[20])
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::" ");
        GLEntry.SetRange(Description, GenJournalLine.Description);
        GLEntry.SetRange("Global Dimension 1 Code", ShortcutDimension1Code);
        GLEntry.SetRange("Global Dimension 2 Code", ShortcutDimension2Code);
        GLEntry.FindSet();
        repeat
            GLEntry.TestField("Document Type", GLEntry."Document Type"::" ");
            GLEntry.TestField("Global Dimension 1 Code", ShortcutDimension1Code);
            GLEntry.TestField("Global Dimension 2 Code", ShortcutDimension2Code);
        until GLEntry.Next() = 0;
    end;

    local procedure VerifyDimensionOnGeneralJournalLine(GenJournalLine: Record "Gen. Journal Line"; EmployeeNo: Code[20]; GLAccountNo: Code[20])
    var
        GenJournalLine2: Record "Gen. Journal Line";
    begin
        GenJournalLine2.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine2.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine2.TestField("Shortcut Dimension 1 Code", '');
        GenJournalLine2.TestField("Shortcut Dimension 2 Code", '');
        GenJournalLine2.FindLast();
        GenJournalLine2.TestField("Account Type", GenJournalLine2."Account Type"::Employee);
        GenJournalLine2.TestField("Account No.", EmployeeNo);
        GenJournalLine2.TestField("Bal. Account Type", GenJournalLine2."Bal. Account Type"::"G/L Account");
        GenJournalLine2.TestField("Bal. Account No.", GLAccountNo);
    end;

    local procedure VerifyDimensionOnGeneralJournalLineFromExpense(GenJournalLine: Record "Gen. Journal Line"; DimValue1Code: Code[20]; DimValue2Code: Code[20])
    var
        GenJournalLine2: Record "Gen. Journal Line";
    begin
        GenJournalLine2.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        GenJournalLine2.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        GenJournalLine2.FindLast();
        GenJournalLine2.TestField("Shortcut Dimension 1 Code", DimValue1Code);
        GenJournalLine2.TestField("Shortcut Dimension 2 Code", DimValue2Code);
    end;

    local procedure VerifyDimOnGeneralJournalLineSummarizePerVend(FirstDim: Boolean)
    var
        GenJournalLine: Record "Gen. Journal Line";
        ShortcutDim1Code: Code[20];
        ShortcutDim2Code: Code[20];
    begin
        Initialize();
        CreatePostGenJnlLineRunSuggestEmployeePayments(GenJournalLine, ShortcutDim1Code);
        GetDefaultEmployeeGlobalDimCode(ShortcutDim1Code, ShortcutDim2Code, GenJournalLine."Account No.", FirstDim);
        VerifyDimensionOnGeneralJournalLineFromExpense(GenJournalLine, ShortcutDim1Code, ShortcutDim2Code);
    end;

    local procedure GetDefaultEmployeeGlobalDimCode(var ShortcutDim1Code: Code[20]; var ShortcutDim2Code: Code[20]; AccountNo: Code[20]; FirstDim: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        if FirstDim then
            ShortcutDim2Code := ''
        else begin
            GLSetup.Get();
            ShortcutDim1Code := GetEmployeeDefaultDim(AccountNo, GLSetup."Global Dimension 1 Code");
            ShortcutDim2Code := GetEmployeeDefaultDim(AccountNo, GLSetup."Global Dimension 2 Code");
        end;
    end;

    local procedure VerifyGenJnlLineDimSetID(GenJnlBatch: Record "Gen. Journal Batch"; EmployeeNo: Code[20]; DimSetID: Integer)
    var
        GenJnlLine: Record "Gen. Journal Line";
    begin
        GenJnlLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJnlLine.SetRange("Account No.", EmployeeNo);
        GenJnlLine.FindFirst();
        Assert.AreEqual(DimSetID, GenJnlLine."Dimension Set ID", GenJnlLine.FieldCaption("Dimension Set ID"));
    end;

    local procedure VerifyGenJnlLineRecipientBankAccount(EmployeeNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetRange("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.SetRange("Account Type", GenJournalLine."Account Type"::Employee);
        GenJournalLine.SetRange("Account No.", EmployeeNo);
        GenJournalLine.FindFirst();
        Assert.AreEqual(EmployeeNo, GenJournalLine."Recipient Bank Account", GenJournalLine.FieldCaption("Recipient Bank Account"));
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestEmployeePaymentsRequestPageHandler(var SuggestEmployeePayments: TestRequestPage "Suggest Employee Payments")
    begin
        SuggestEmployeePayments.Employee.SetFilter("No.", LibraryVariableStorage.DequeueText());
        SuggestEmployeePayments.BalAccountNo.SetValue(LibraryVariableStorage.DequeueText());
        SuggestEmployeePayments.StartingDocumentNo.SetValue(LibraryRandom.RandInt(10));  // Setting a Random Document No., value is not important.
        SuggestEmployeePayments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestEmployeePaymentsWithDimensionRequestPageHandler(var SuggestEmployeePayments: TestRequestPage "Suggest Employee Payments")
    begin
        SuggestEmployeePayments.Employee.SetFilter("No.", LibraryVariableStorage.DequeueText());
        SuggestEmployeePayments.SummarizePerEmployee.SetValue(true);
        SuggestEmployeePayments.SummarizePerDimText.AssistEdit();
        SuggestEmployeePayments.StartingDocumentNo.SetValue(LibraryRandom.RandInt(10));  // Setting a Random Document No., value is not important.
        SuggestEmployeePayments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestEmployeePaymentsWithDimensionAndBalAccRequestPageHandler(var SuggestEmployeePayments: TestRequestPage "Suggest Employee Payments")
    begin
        SuggestEmployeePayments.Employee.SetFilter("No.", LibraryVariableStorage.DequeueText());
        SuggestEmployeePayments.SummarizePerEmployee.SetValue(true);
        SuggestEmployeePayments.SummarizePerDimText.AssistEdit();
        SuggestEmployeePayments.StartingDocumentNo.SetValue(LibraryRandom.RandInt(10));  // Setting a Random Document No., value is not important.
        SuggestEmployeePayments.BalAccountNo.SetValue(LibraryVariableStorage.DequeueText());
        SuggestEmployeePayments.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectDimensionHandlerOnSuggesEmployeePayment(var DimensionSelectionMultiple: TestPage "Dimension Selection-Multiple")
    begin
        DimensionSelectionMultiple.FILTER.SetFilter(Code, GetDimensionFilterText());
        DimensionSelectionMultiple.First();
        repeat
            DimensionSelectionMultiple.Selected.SetValue(true);
        until not DimensionSelectionMultiple.Next();
        DimensionSelectionMultiple.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectNoDimensionHandlerOnSuggesEmployeePayment(var DimensionSelectionMultiple: TestPage "Dimension Selection-Multiple")
    begin
        DimensionSelectionMultiple.FILTER.SetFilter(Code, GetDimensionFilterText());
        DimensionSelectionMultiple.First();
        repeat
            DimensionSelectionMultiple.Selected.SetValue(false);
        until not DimensionSelectionMultiple.Next();
        DimensionSelectionMultiple.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectFirstDimensionHandlerOnSuggesEmployeePayment(var DimensionSelectionMultiple: TestPage "Dimension Selection-Multiple")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionSelectionBuffer: Record "Dimension Selection Buffer";
    begin
        GeneralLedgerSetup.Get();
        DimensionSelectionBuffer.SetRange(Code, GeneralLedgerSetup."Shortcut Dimension 1 Code");
        DimensionSelectionMultiple.FILTER.SetFilter(Code, DimensionSelectionBuffer.GetFilter(Code));
        DimensionSelectionMultiple.First();
        DimensionSelectionMultiple.Selected.SetValue(true);
        DimensionSelectionMultiple.OK().Invoke();
    end;

    local procedure SetupGenJnlLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        GenJournalLine.Init();  // INIT is mandatory for Gen. Journal Line to Set the General Template and General Batch Name.
        GenJournalLine.Validate("Journal Template Name", GenJournalTemplate.Name);
        GenJournalLine.Validate("Journal Batch Name", GenJournalBatch.Name);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestEmployeePaymentsWithoutBalAccountRequestPageHandler(var SuggestEmployeePayments: TestRequestPage "Suggest Employee Payments")
    begin
        SuggestEmployeePayments.Employee.SetFilter("No.", LibraryVariableStorage.DequeueText());
        SuggestEmployeePayments.SummarizePerEmployee.SetValue(false);
        SuggestEmployeePayments.SummarizePerDimText.AssistEdit();
        SuggestEmployeePayments.StartingDocumentNo.SetValue(LibraryRandom.RandInt(10));  // Setting a Random Document No., value is not important.
        SuggestEmployeePayments.BalAccountNo.SetValue('');
        SuggestEmployeePayments.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ClearDimensionHandlerOnSuggesEmployeePayment(var DimensionSelectionMultiple: TestPage "Dimension Selection-Multiple")
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionSelectionBuffer: Record "Dimension Selection Buffer";
    begin
        GeneralLedgerSetup.Get();
        DimensionSelectionBuffer.SetFilter(
          Code, '%1|%2', GeneralLedgerSetup."Shortcut Dimension 1 Code", GeneralLedgerSetup."Shortcut Dimension 2 Code");
        DimensionSelectionMultiple.FILTER.SetFilter(Code, DimensionSelectionBuffer.GetFilter(Code));
        DimensionSelectionMultiple.FILTER.SetFilter(Selected, 'yes');
        DimensionSelectionMultiple.First();
        repeat
            DimensionSelectionMultiple.Selected.SetValue(false);
        until not DimensionSelectionMultiple.Next();
        DimensionSelectionMultiple.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestEmployeePaymentsWithAvailableAmtRequestPageHandler(var SuggestEmployeePayments: TestRequestPage "Suggest Employee Payments")
    begin
        SuggestEmployeePayments.Employee.SetFilter("No.", LibraryVariableStorage.DequeueText());
        SuggestEmployeePayments."Available Amount (LCY)".SetValue(LibraryVariableStorage.DequeueDecimal());
        SuggestEmployeePayments.StartingDocumentNo.SetValue(LibraryRandom.RandInt(10));
        SuggestEmployeePayments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestEmployeePaymentsDefaultValuesForRequestPageHandler(var SuggestEmployeePayments: TestRequestPage "Suggest Employee Payments")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        GenJournalBatch.Get(LibraryVariableStorage.DequeueText(), LibraryVariableStorage.DequeueText());

        SuggestEmployeePayments.PostingDate.AssertEquals(WorkDate());
        SuggestEmployeePayments.BalAccountType.AssertEquals(GenJournalBatch."Bal. Account Type");
        SuggestEmployeePayments.BalAccountNo.AssertEquals(GenJournalBatch."Bal. Account No.");
        SuggestEmployeePayments.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestEmployeePaymentsRequestWithBnkPmtTypePageHandler(var SuggestEmployeePayments: TestRequestPage "Suggest Employee Payments")
    begin
        SuggestEmployeePayments.Employee.SetFilter("No.", LibraryVariableStorage.DequeueText());
        SuggestEmployeePayments.BalAccountType.SetValue(LibraryVariableStorage.DequeueInteger());
        SuggestEmployeePayments.BalAccountNo.SetValue(LibraryVariableStorage.DequeueText());
        SuggestEmployeePayments.BankPaymentType.SetValue(LibraryVariableStorage.DequeueInteger());
        SuggestEmployeePayments.StartingDocumentNo.SetValue(LibraryRandom.RandInt(10));  // Setting a Random Document No., value is not important.
        SuggestEmployeePayments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestEmployeePaymentsWithStartingNoSummarizedNewDocPerLineRPH(var SuggestEmployeePayments: TestRequestPage "Suggest Employee Payments")
    begin
        SuggestEmployeePayments.Employee.SetFilter("No.", LibraryVariableStorage.DequeueText());
        SuggestEmployeePayments."Available Amount (LCY)".SetValue(LibraryVariableStorage.DequeueDecimal());
        SuggestEmployeePayments.StartingDocumentNo.SetValue(LibraryVariableStorage.DequeueText());
        SuggestEmployeePayments.SummarizePerEmployee.SetValue(LibraryVariableStorage.DequeueBoolean());
        SuggestEmployeePayments.NewDocNoPerLine.SetValue(LibraryVariableStorage.DequeueBoolean());
        SuggestEmployeePayments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestEmployeePaymentsWithStartingNo(var SuggestEmployeePayments: TestRequestPage "Suggest Employee Payments")
    begin
        SuggestEmployeePayments.Employee.SetFilter("No.", LibraryVariableStorage.DequeueText());
        SuggestEmployeePayments.StartingDocumentNo.SetValue(LibraryVariableStorage.DequeueText());
        SuggestEmployeePayments.SummarizePerEmployee.SetValue(LibraryVariableStorage.DequeueBoolean());
        SuggestEmployeePayments.NewDocNoPerLine.SetValue(LibraryVariableStorage.DequeueBoolean());
        SuggestEmployeePayments.OK().Invoke();
    end;
}

