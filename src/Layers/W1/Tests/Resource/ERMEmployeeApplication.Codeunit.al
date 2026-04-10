codeunit 134115 "ERM Employee Application"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Employee Payments]
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryHumanResource: Codeunit "Library - Human Resource";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        AmountErr: Label '%1 must be %2 in %3.';
        ApplyAmountErr: Label '%1 must be %2.';
        WrongEmployeeNoErr: Label 'Employee was not found.';
        EarlierPostingDateErr: Label 'You cannot apply and post an entry to an entry with an earlier posting date.';

    [Test]
    [HandlerFunctions('ApplyEmployeePageHandler')]
    [Scope('OnPrem')]
    procedure EmployeePostInvApplyPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Apply Employee Entries Page Fields with Posting Expense and Apply Payment without Currency.
        Initialize();
        ApplyEmployeeEntry(GenJournalLine."Document Type"::" ", GenJournalLine."Document Type"::Payment, '', '');
    end;

    local procedure ApplyEmployeeEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type"; CurrencyCode3: Code[10]; CurrencyCode2: Code[10])
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        Amount: Decimal;
        Balance: Decimal;
        AppliedAmount: Decimal;
        ApplyingAmount: Decimal;
    begin
        // Setup: Create Employee, Create and post General Journal  Line.
        SelectGenJournalBatch(GenJournalBatch);
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, CreateEmployeeNo(), DocumentType, -LibraryRandom.RandDec(100, 2),
          CurrencyCode3, GenJournalLine."Account Type"::Employee);
        Amount := GenJournalLine.Amount;
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account No.", DocumentType2, -GenJournalLine.Amount / 2, CurrencyCode2,
          GenJournalLine."Account Type"::Employee);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise.
        OpenEmployeeLedgerEntryPage(DocumentType2, GenJournalLine."Account No.");

        AppliedAmount := LibraryVariableStorage.DequeueDecimal();
        ApplyingAmount := LibraryVariableStorage.DequeueDecimal();
        Balance := LibraryVariableStorage.DequeueDecimal();

        // Verify: Verify Page fields value on Apply Employee Entries Page.
        Assert.AreEqual(Amount, AppliedAmount, StrSubstNo(ApplyAmountErr, 'Applied Amount', Amount));
        Assert.AreEqual(GenJournalLine.Amount, ApplyingAmount, StrSubstNo(ApplyAmountErr, 'Applying Amount', GenJournalLine.Amount));
        Assert.AreEqual(Amount + GenJournalLine.Amount, Balance, StrSubstNo(ApplyAmountErr, 'Balance', Amount + GenJournalLine.Amount));
        Assert.AreEqual(CurrencyCode2, LibraryVariableStorage.DequeueText(), StrSubstNo(ApplyAmountErr, 'Currency Code', CurrencyCode2));
    end;

    [Test]
    [HandlerFunctions('PostAndApplyEmployeePageHandler,PostApplicationPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure EmployeeApplyAndPostPaymentInv()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Employee Ledger Entries for Remaining Amount after Posting and Apply Expense and Payment through Page.
        Initialize();
        ApplyAndPostEmployeeEntry(GenJournalLine."Document Type"::" ", GenJournalLine."Document Type"::Payment);
    end;

    local procedure ApplyAndPostEmployeeEntry(DocumentType: Enum "Gen. Journal Document Type"; DocumentType2: Enum "Gen. Journal Document Type")
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        // Setup. Post Employee Expense and Partial Payment with Random Amount.
        GenJournalTemplate.DeleteAll();
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        SelectGenJournalBatch(GenJournalBatch);
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, CreateEmployeeNo(), DocumentType, -LibraryRandom.RandDec(100, 2), '',
          GenJournalLine."Account Type"::Employee);
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account No.", DocumentType2, -GenJournalLine.Amount / 2, '',
          GenJournalLine."Account Type"::Employee);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise.
        OpenEmployeeLedgerEntryPage(DocumentType2, GenJournalLine."Account No.");

        // Verify: Verify Page fields value on Apply Employee Entries Page.
        GeneralLedgerSetup.Get();
        LibraryERM.FindEmployeeLedgerEntry(EmployeeLedgerEntry, DocumentType, GenJournalLine."Document No.");
        EmployeeLedgerEntry.CalcFields("Remaining Amount");
        Assert.AreNearlyEqual(
          -GenJournalLine.Amount, EmployeeLedgerEntry."Remaining Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErr, EmployeeLedgerEntry.FieldCaption("Remaining Amount"), -GenJournalLine.Amount,
            EmployeeLedgerEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('PostAndApplyEmployeePageHandler,PostApplicationPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure EmployeePostAndApplyEqualAmount()
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        // Check Employee Ledger Entries for Amount and Remaining Amount after Applying Expense and Payment of equal amounts
        // through Page.

        // Setup: Post Employee Expense and Payment with Random Amount.
        Initialize();
        SelectGenJournalBatch(GenJournalBatch);
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, CreateEmployeeNo(), GenJournalLine."Document Type"::" ",
          -LibraryRandom.RandDec(100, 2), '', GenJournalLine."Account Type"::Employee);
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, GenJournalLine."Account No.", GenJournalLine."Document Type"::Payment,
          -GenJournalLine.Amount, '', GenJournalLine."Account Type"::Employee);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise.
        GeneralLedgerSetup.Get();
        OpenEmployeeLedgerEntryPage(GenJournalLine."Document Type", GenJournalLine."Account No.");

        // Verify: Verify Amount and Remaining Amount on Employee Ledger Entries.
        LibraryERM.FindEmployeeLedgerEntry(EmployeeLedgerEntry, GenJournalLine."Document Type", GenJournalLine."Document No.");
        EmployeeLedgerEntry.CalcFields(Amount, "Remaining Amount");
        Assert.AreNearlyEqual(
          GenJournalLine.Amount, EmployeeLedgerEntry.Amount, GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErr, EmployeeLedgerEntry.FieldCaption(Amount), GenJournalLine.Amount,
            EmployeeLedgerEntry.TableCaption()));
        Assert.AreNearlyEqual(
          0, EmployeeLedgerEntry."Remaining Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(AmountErr, EmployeeLedgerEntry.FieldCaption("Remaining Amount"), 0,
            EmployeeLedgerEntry.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmployeeApplyUsingAppliestoDocNoBlankAccNo()
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check that it is possible to enter an expense number without having a Employee number.
        // Setup: Create and post Employee Expense, create Payment and Apply Payment using Applies to Doc. No.
        Initialize();
        GenJournalTemplate.DeleteAll();
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, CreateEmployeeNo(), GenJournalLine."Document Type"::" ",
          -LibraryRandom.RandDec(100, 2), '', GenJournalLine."Account Type"::Employee);
        ModifyGenLineBalAccountNo(GenJournalLine);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        // Retrieve the new expense number
        EmployeeLedgerEntry.FindLast();
        EmployeeLedgerEntry.TestField("Document Type", EmployeeLedgerEntry."Document Type"::" ");

        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalBatch."Journal Template Name");
        CreateGeneralJournalLines(
          GenJournalLine, GenJournalBatch, '', GenJournalLine."Document Type"::Payment,
          0, '', GenJournalLine."Account Type");
        ModifyGenLineBalAccountNo(GenJournalLine);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::" ");
        GenJournalLine.TestField("Applies-to Doc. No.", '');
        GenJournalLine.TestField("Account No.", '');
        GenJournalLine.Validate("Applies-to Doc. No.", EmployeeLedgerEntry."Document No.");
        // Verify that the employee number was filled in.
        Assert.AreEqual(EmployeeLedgerEntry."Employee No.", GenJournalLine."Account No.", WrongEmployeeNoErr);
    end;

    [Test]
    [HandlerFunctions('ApplyEmployeeEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure AppliesToIDOnApplyEmployeeEntriesWithGeneralLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Applies to ID field should be blank on Apply Employee Entries Page.
        // Verify with ApplyEmployeeEntriesPageHandler.
        Initialize();
        CreateGeneralLineAndApplyEntries(GenJournalLine."Account Type"::Employee, CreateEmployeeNo(), -LibraryRandom.RandDec(100, 2)); // Take Random Amount for General Line.
    end;

    local procedure CreateGeneralLineAndApplyEntries(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalLine: Record "Gen. Journal Line";
        GeneralJournal: TestPage "General Journal";
    begin
        // Setup: Create and Post General Line for Expense.
        GenJournalTemplate.DeleteAll();
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          AccountType, AccountNo, Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Create Payment General Line with Zero Amount.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, 0);

        // Verify: Open Apply Entries Page and Check Applies to ID field should be blank.
        GeneralJournal.OpenView();
        GeneralJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        GeneralJournal."Apply Entries".Invoke();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyEmployeePaymentToThreeExpenses()
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        EmployeeNo: Code[20];
        PaymentNo: Code[20];
    begin
        Initialize();

        // [GIVEN] 3 Employee expenses with Amounts = -10, -20, -30, One payment with Amount = 60
        EmployeeNo := CreateEmployeeNo();
        CreateAndPostEmployeeMultipleJnlLines(PaymentNo, EmployeeNo);

        EmployeeLedgerEntry.SetRange("Employee No.", EmployeeNo);
        LibraryERM.SetAppliestoIdEmployee(EmployeeLedgerEntry);
        LibraryERM.FindEmployeeLedgerEntry(EmployeeLedgerEntry, EmployeeLedgerEntry."Document Type"::Payment, PaymentNo);

        // [WHEN] Apply Payment to three Expenses
        LibraryERM.PostEmplLedgerApplication(EmployeeLedgerEntry);

        // [THEN] All Employee Ledger Entries are closed
        EmployeeLedgerEntry.Reset();
        EmployeeLedgerEntry.SetRange("Employee No.", EmployeeNo);
        EmployeeLedgerEntry.SetRange(Open, true);
        Assert.RecordIsEmpty(EmployeeLedgerEntry);
    end;

    [Test]
    [HandlerFunctions('EmployeeLedgerEntriesPageHandler,ApplyEmployeeEntriesClearsAppliesToIdPageHandler')]
    [Scope('OnPrem')]
    procedure EmployeeAppliesToIdClearedAfterAmountToApplyIsSetToZero()
    var
        Employee: Record Employee;
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        Initialize();

        // [GIVEN] Employee with posted expense.

        SetupEmployeeWithTwoPostedDocuments(Employee);

        // [GIVEN] Employee Ledger Entries is opened and "Apply Entries" button is invoked, opening Apply Employee Entries Page.
        // Handled by EmployeeLedgerEntriesPageHandler
        EmployeeLedgerEntry.SetRange("Employee No.", Employee."No.");
        PAGE.Run(PAGE::"Employee Ledger Entries", EmployeeLedgerEntry);

        // The following sequence is executed by ApplyEmployeeEntriesClearsAppliesToIdPageHandler
        // [GIVEN] Set "Amount to Apply" = 100. "Applies-to ID" is populated.
        // [WHEN] Set "Amount to Apply" = 0.
        // [THEN] "Applies-to ID" is cleared.
    end;

    [Test]
    [HandlerFunctions('EmployeeLedgerEntriesPageHandler,ApplyEmployeeEntriesPageClearsAmountToApplyPageHandler')]
    [Scope('OnPrem')]
    procedure EmployeeAmountToApplyNotClearedAfterBeingSetToZero()
    var
        Employee: Record Employee;
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        Initialize();

        // [GIVEN] Employee with posted expense.
        SetupEmployeeWithTwoPostedDocuments(Employee);

        // [GIVEN] Employee Ledger Entries is opened and "Apply Entries" button is invoked, opening Apply Employee Entries Page.
        // Handled by EmployeeLedgerEntriesPageHandler
        EmployeeLedgerEntry.SetRange("Employee No.", Employee."No.");
        PAGE.Run(PAGE::"Employee Ledger Entries", EmployeeLedgerEntry);

        // The following sequence is executed by ApplyEmployeeEntriesPageClearsAmountToApplyPageHandler
        // [GIVEN] Set "Amount to Apply" = 100.
        // [GIVEN] Set "Amount to Apply" = 0.
        // [WHEN] Set "Amount to Apply" = 50.
        // [THEN] "Amount to Apply" is 50.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditFieldsOnEmployeeLedgerEntryPage()
    var
        GenJournalLine: Record "Gen. Journal Line";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        PaymentMethod: Record "Payment Method";
        EmployeeLedgerEntries: TestPage "Employee Ledger Entries";
        EmployeeNo: Code[20];
        MsgToRecipient: Text[140];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 259566] Update Employee Ledger Entry through Employee Ledger Entries page.
        Initialize();

        // [GIVEN] Employee with ledger entry
        EmployeeNo := CreateEmployeeNo();
        CreateAndPostJournalLine(
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Employee, EmployeeNo, LibraryRandom.RandDec(100, 2));
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        MsgToRecipient := LibraryUtility.GenerateGUID();
        // [GIVEN] Employee Ledger Entries page is opened for the Employee
        // [GIVEN] Only "Payment Method Code" and "Message to Recipient" fields are editable on the page
        // [WHEN] Set Payment Method as "Pmt", Message To Recipient as "Msg"
        // [THEN] "Payment Method Code" and "Message to Recipient" are updated with "Pmt" and "Msg" respectively
        EmployeeLedgerEntries.OpenEdit();
        EmployeeLedgerEntries.FILTER.SetFilter("Employee No.", EmployeeNo);
        Assert.IsFalse(EmployeeLedgerEntries."Posting Date".Editable(), EmployeeLedgerEntry.FieldCaption("Posting Date"));
        Assert.IsFalse(EmployeeLedgerEntries."Document Type".Editable(), EmployeeLedgerEntry.FieldCaption("Document Type"));
        Assert.IsFalse(EmployeeLedgerEntries."Document No.".Editable(), EmployeeLedgerEntry.FieldCaption("Document No."));
        Assert.IsFalse(EmployeeLedgerEntries."Employee No.".Editable(), EmployeeLedgerEntry.FieldCaption("Employee No."));
        Assert.IsFalse(EmployeeLedgerEntries.Description.Editable(), EmployeeLedgerEntry.FieldCaption(Description));
        Assert.IsFalse(EmployeeLedgerEntries.Open.Editable(), EmployeeLedgerEntry.FieldCaption(Open));
        Assert.IsFalse(EmployeeLedgerEntries."Entry No.".Editable(), EmployeeLedgerEntry.FieldCaption("Entry No."));

        Assert.IsFalse(EmployeeLedgerEntries."Original Amount".Editable(), EmployeeLedgerEntry.FieldCaption("Original Amount"));
        Assert.IsFalse(EmployeeLedgerEntries.Amount.Editable(), EmployeeLedgerEntry.FieldCaption(Amount));
        Assert.IsFalse(EmployeeLedgerEntries."Remaining Amount".Editable(), EmployeeLedgerEntry.FieldCaption("Remaining Amount"));
        Assert.IsFalse(EmployeeLedgerEntries."Remaining Amt. (LCY)".Editable(), EmployeeLedgerEntry.FieldCaption("Remaining Amt. (LCY)"));

        Assert.IsTrue(EmployeeLedgerEntries."Payment Method Code".Editable(), EmployeeLedgerEntry.FieldCaption("Payment Method Code"));
        Assert.IsTrue(EmployeeLedgerEntries."Message to Recipient".Editable(), EmployeeLedgerEntry.FieldCaption("Message to Recipient"));
        EmployeeLedgerEntries."Payment Method Code".SetValue(PaymentMethod.Code);
        EmployeeLedgerEntries."Message to Recipient".SetValue(MsgToRecipient);
        EmployeeLedgerEntries.Close();

        EmployeeLedgerEntry.SetRange("Employee No.", EmployeeNo);
        EmployeeLedgerEntry.FindFirst();
        EmployeeLedgerEntry.TestField("Payment Method Code", PaymentMethod.Code);
        EmployeeLedgerEntry.TestField("Message to Recipient", MsgToRecipient);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentTwoInvoiceSetAppliesToIdFromGeneralJournal()
    var
        Employee: Record Employee;
        GenJournalLine: Record "Gen. Journal Line";
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
    begin
        // [FEATURE] [General Journal]
        // [SCENARIO 342909] System clean "Applies-to ID" field in employee ledger entry when it is generated from general journal line applied to employee ledger entry
        Initialize();

        CreateEmployee(Employee);

        InvoiceAmount := -LibraryRandom.RandIntInRange(10, 20);
        PaymentAmount := -InvoiceAmount * 3;

        // Invoice 1
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Employee, Employee."No.", InvoiceAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Invoice 2
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Employee, Employee."No.", InvoiceAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Payment 1 with false "Applies-to ID"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Employee, Employee."No.", PaymentAmount);
        GenJournalLine."Applies-to ID" := GenJournalLine."Document No.";
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        LibraryERM.FindEmployeeLedgerEntry(
          EmployeeLedgerEntry, EmployeeLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");
        EmployeeLedgerEntry.TestField("Applies-to ID", '');

        // Payment 2 with true "Applies-to ID"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Employee, Employee."No.", PaymentAmount);

        Clear(EmployeeLedgerEntry);
        EmployeeLedgerEntry.SetRange("Employee No.", Employee."No.");
        EmployeeLedgerEntry.SetRange("Document Type", EmployeeLedgerEntry."Document Type"::" ");
        LibraryERM.SetAppliestoIdEmployee(EmployeeLedgerEntry);
        EmployeeLedgerEntry.ModifyAll("Applies-to ID", GenJournalLine."Document No.");

        GenJournalLine."Applies-to ID" := GenJournalLine."Document No.";
        GenJournalLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        EmployeeLedgerEntry.FindSet();
        repeat
            EmployeeLedgerEntry.TestField(Open, false);
        until EmployeeLedgerEntry.Next() = 0;
        Assert.RecordCount(EmployeeLedgerEntry, 2);

        LibraryERM.FindEmployeeLedgerEntry(
          EmployeeLedgerEntry, EmployeeLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");
        EmployeeLedgerEntry.TestField("Applies-to ID", '');
    end;

    [Test]
    [HandlerFunctions('MultipleSelectionApplyEmployeeEntriesModalPageHandler')]
    [Scope('OnPrem')]
    procedure CheckPostingDateForMultipleEmplLedgEntriesWhenSetAppliesToIDOnApplyEmployeeEntries()
    var
        Employee: Record Employee;
        GenJournalLine: Record "Gen. Journal Line";
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
    begin
        // [FEATURE] [Application]
        // [SCENARIO 383611] When "Set Applies-to ID" on "Apply Employee Entries" page is used for multiple lines, Posting date of each line is checked.
        Initialize();

        // [GIVEN] Two Employee Ledger Entries with Posting Date = "01.01.21" / "21.01.21".
        CreateEmployee(Employee);
        InvoiceAmount := -LibraryRandom.RandIntInRange(10, 20);
        PaymentAmount := -InvoiceAmount * 3;
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Employee, Employee."No.", InvoiceAmount);
        GenJournalLine.Validate("Posting Date", LibraryRandom.RandDate(-10));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine, GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Employee, Employee."No.", InvoiceAmount);
        GenJournalLine.Validate("Posting Date", LibraryRandom.RandDate(10));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] General Journal Line with Posting Date = "11.01.21".
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Employee, Employee."No.", PaymentAmount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::" ");
        GenJournalLine.Modify(true);

        // [GIVEN] "Apply Employee Entries" page is opened by Codeunit "Gen. Jnl.-Apply" run for General Journal Line.
        LibraryVariableStorage.Enqueue(GenJournalLine."Account No.");
        asserterror CODEUNIT.Run(CODEUNIT::"Gen. Jnl.-Apply", GenJournalLine);

        // [WHEN] Multiple lines are selected on "Apply Employee Entries" page and action "Set Applies-to ID" is used.
        // Done in MultipleSelectionApplyEmployeeEntriesModalPageHandler

        // [THEN] Error "You cannot apply and post an entry to an entry with an earlier posting date." is thrown.
        Assert.ExpectedErrorCode('Dialog');
        Assert.ExpectedError(EarlierPostingDateErr);

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        EmployeePostingGroup: Record "Employee Posting Group";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Employee Application");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        EmployeePostingGroup.DeleteAll();
        CreateEmployeePostingGroup(LibraryERM.CreateGLAccountNoWithDirectPosting());

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Employee Application");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.RemoveBlankGenJournalTemplate();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        isInitialized := true;
        Commit();

        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Employee Application");
    end;

    local procedure CreateGeneralJournalLines(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; AccountNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal; CurrencyCode: Code[10]; AccountType: Enum "Gen. Journal Account Type")
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateEmployee(var Employee: Record Employee)
    var
        EmployeePostingGroup: Record "Employee Posting Group";
    begin
        LibraryHumanResource.CreateEmployee(Employee);
        EmployeePostingGroup.FindFirst();
        Employee.Validate("Employee Posting Group", EmployeePostingGroup.Code);
        Employee.Validate("Application Method", Employee."Application Method"::Manual);
        Employee.Modify(true);
    end;

    local procedure CreateEmployeeNo(): Code[20]
    var
        Employee: Record Employee;
    begin
        CreateEmployee(Employee);
        exit(Employee."No.");
    end;

    local procedure CreateAndPostThreeEmployeeExpensesAndOnePayment(var PaymentNo: Code[20]; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Sign: Integer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        InvAmount: Decimal;
    begin
        // Create three expenses for employee
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::" ",
          AccountType, AccountNo, Sign * LibraryRandom.RandDecInRange(100, 200, 2));
        InvAmount += GenJournalLine.Amount;
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          GenJournalLine."Document Type"::" ",
          AccountType, AccountNo, GenJournalLine."Bal. Account Type", GenJournalLine."Bal. Account No.",
          Sign * LibraryRandom.RandDecInRange(100, 200, 2));
        InvAmount += GenJournalLine.Amount;
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          GenJournalLine."Document Type"::" ",
          AccountType, AccountNo, GenJournalLine."Bal. Account Type", GenJournalLine."Bal. Account No.",
          Sign * LibraryRandom.RandDecInRange(100, 200, 2));
        InvAmount += GenJournalLine.Amount;

        // Now counter all these expenses with a payment
        LibraryJournals.CreateGenJournalLine(
          GenJournalLine, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name",
          GenJournalLine."Document Type"::Payment,
          AccountType, AccountNo, GenJournalLine."Bal. Account Type", GenJournalLine."Bal. Account No.",
          -InvAmount);
        PaymentNo := GenJournalLine."Document No.";

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostEmployeeMultipleJnlLines(var PaymentNo: Code[20]; EmployeeNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateAndPostThreeEmployeeExpensesAndOnePayment(PaymentNo, GenJournalLine."Account Type"::Employee, EmployeeNo, -1);
    end;

    local procedure ModifyGenLineBalAccountNo(var GenJournalLine: Record "Gen. Journal Line")
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Modify(true);
    end;

    local procedure OpenEmployeeLedgerEntryPage(DocumentType: Enum "Gen. Journal Document Type"; EmployeeNo: Code[20])
    var
        EmployeeLedgerEntries: TestPage "Employee Ledger Entries";
    begin
        EmployeeLedgerEntries.OpenView();
        EmployeeLedgerEntries.FILTER.SetFilter("Document Type", Format(DocumentType));
        EmployeeLedgerEntries.FILTER.SetFilter("Employee No.", EmployeeNo);
        EmployeeLedgerEntries.ActionApplyEntries.Invoke();
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        // Select General Journal Batch and clear General Journal Lines to make sure that no line exist before creating
        // General Journal Lines.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch)
    end;

    local procedure SetupEmployeeWithTwoPostedDocuments(var Employee: Record Employee)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateEmployee(Employee);
        CreateAndPostJournalLine(
          GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Employee,
          Employee."No.", LibraryRandom.RandIntInRange(1000, 5000));
        CreateAndPostJournalLine(
          GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::Employee,
          Employee."No.", LibraryRandom.RandIntInRange(100, 500));
    end;

    local procedure CreateAndPostJournalLine(DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Document Type"; AccountNo: Code[20]; LineAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, DocumentType, AccountType, AccountNo, LineAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyEmployeeEntriesPageHandler(var ApplyEmployeeEntries: TestPage "Apply Employee Entries")
    begin
        ApplyEmployeeEntries."Applies-to ID".AssertEquals('');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyEmployeePageHandler(var ApplyEmployeeEntries: TestPage "Apply Employee Entries")
    begin
        ApplyEmployeeEntries.ActionSetAppliesToID.Invoke();
        LibraryVariableStorage.Enqueue(ApplyEmployeeEntries.AppliedAmount.Value);
        LibraryVariableStorage.Enqueue(ApplyEmployeeEntries.ApplyingAmount.Value);
        LibraryVariableStorage.Enqueue(ApplyEmployeeEntries.ControlBalance.Value);
        LibraryVariableStorage.Enqueue(ApplyEmployeeEntries.ApplnCurrencyCode.Value);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostAndApplyEmployeePageHandler(var ApplyEmployeeEntries: TestPage "Apply Employee Entries")
    begin
        ApplyEmployeeEntries.ActionSetAppliesToID.Invoke();
        ApplyEmployeeEntries.ActionPostApplication.Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostApplicationPageHandler(var PostApplication: Page "Post Application"; var Response: Action)
    begin
        // Modal Page Handler.
        Response := ACTION::OK
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure EmployeeLedgerEntriesPageHandler(var EmployeeLedgerEntries: TestPage "Employee Ledger Entries")
    begin
        EmployeeLedgerEntries.Last();
        EmployeeLedgerEntries.ActionApplyEntries.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyEmployeeEntriesClearsAppliesToIdPageHandler(var ApplyEmployeeEntries: TestPage "Apply Employee Entries")
    begin
        ApplyEmployeeEntries."Amount to Apply".SetValue := LibraryRandom.RandDec(100, 2);
        ApplyEmployeeEntries."Applies-to ID".AssertEquals(UserId);

        ApplyEmployeeEntries."Amount to Apply".SetValue := 0;
        ApplyEmployeeEntries."Applies-to ID".AssertEquals('');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyEmployeeEntriesPageClearsAmountToApplyPageHandler(var ApplyEmployeeEntries: TestPage "Apply Employee Entries")
    var
        AmountToApply: Decimal;
    begin
        AmountToApply := LibraryRandom.RandDecInRange(100, 200, 2);
        ApplyEmployeeEntries."Amount to Apply".SetValue := AmountToApply;
        ApplyEmployeeEntries."Amount to Apply".AssertEquals(AmountToApply);

        ApplyEmployeeEntries."Amount to Apply".SetValue := 0;
        ApplyEmployeeEntries."Amount to Apply".AssertEquals(0);

        AmountToApply := LibraryRandom.RandDecInRange(1, 50, 2);
        ApplyEmployeeEntries."Amount to Apply".SetValue := AmountToApply;
        ApplyEmployeeEntries."Amount to Apply".AssertEquals(AmountToApply);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MultipleSelectionApplyEmployeeEntriesModalPageHandler(var ApplyEmployeeEntries: Page "Apply Employee Entries"; var Response: Action)
    var
        EmployeeLedgerEntry: Record "Employee Ledger Entry";
    begin
        EmployeeLedgerEntry.SetRange("Employee No.", LibraryVariableStorage.DequeueText());
        ApplyEmployeeEntries.CheckEmplApplId(EmployeeLedgerEntry);
    end;

    local procedure CreateEmployeePostingGroup(ExpenseAccNo: Code[20]): Code[20]
    var
        EmployeePostingGroup: Record "Employee Posting Group";
    begin
        EmployeePostingGroup.Init();
        EmployeePostingGroup.Validate(Code, LibraryUtility.GenerateGUID());
        EmployeePostingGroup.Validate("Payables Account", ExpenseAccNo);
        EmployeePostingGroup.Insert(true);
        exit(EmployeePostingGroup.Code);
    end;
}

