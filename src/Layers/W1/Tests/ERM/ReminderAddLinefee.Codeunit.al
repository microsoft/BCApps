codeunit 134997 "Reminder - Add. Line fee"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [ERM] [Reminder] [Additional Fee]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        ActiveDirectoryMockEvents: Codeunit "Active Directory Mock Events";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        ReminderLineMustExistErr: Label 'The Reminder Line does not exists. Filters: %1.';
        ReminderLineMustNotExistErr: Label 'The Reminder Line should not exists. Filters: %1.';
        MustMatchErr: Label 'Field %1 of %2 did not contain correct value.';
        MinDocumentValue: Decimal;
        MaxDocumentValue: Decimal;
        MustNotMatchErr: Label 'Field %1 of %2 must not match the expected value.';
        NumberReminderLineErr: Label 'The number of Reminder Lines did not match the expected.';
        AmountMustBePositiveErr: Label 'Amount must be positive';
        NoOpenEntriesErr: Label 'There is no open Cust. Ledger Entry with Document No.';
        LineFeeAlreadyAppliedErr: Label 'The line fee for %1 %2 on reminder level %3 has already been issued.';
        LineFeeAmountErr: Label 'Line Fee amount must be positive and non-zero for Line Fee applied to %1 %2.', Comment = '%1 = Document Type, %2 = Document No.';
        AppliesToDocErr: Label 'Line Fee has to be applied to an open overdue document.';
        EntryNotOverdueErr: Label '%1 %2 in %3 is not overdue.', Comment = '%1 = Document Type, %2 = Document No., %3 = Table name';
        MultipleLineFeesSameDocErr: Label 'You cannot issue multiple line fees for the same level for the same document. Error with line fees for %1 %2.', Comment = '%1 = Document Type, %2 = Document No.';
        ReminderHdrExistsErr: Label 'A reminder exists for customer %1 which there should not.';
        CountMismatchErr: Label 'The number of entries in %1 did not match the expected.';
        EmailTxt: Label 'abc@microsoft.com', Locked = true;
        PrintDocRef: Option " ",Print,Email;

    [Test]
    [Scope('OnPrem')]
    procedure RenameReminderTerms()
    var
        ReminderTerms: Record "Reminder Terms";
        ReminderLevel: Record "Reminder Level";
        CurrencyForReminderLvl: Record "Currency for Reminder Level";
        ReminderText: Record "Reminder Text";
        AdditionalFeeSetup: Record "Additional Fee Setup";
        Text: Text[100];
        ReminderTermsCode: Code[10];
        NewReminderTermsCode: Code[10];
        Level: Integer;
        Index: Integer;
    begin
        // [SCENARIO 107048] Reminder Terms can be renamed and all related items are renamed accordingly
        Initialize(false);

        // [GIVEN] Reminder Terms (R)
        ReminderTermsCode := CreateReminderTerms(false, false, false);

        // [GIVEN] R have two Reminder Levels (L1 and L2)
        for Level := 1 to 2 do
            CreateReminderTermsLevel(ReminderTermsCode, Level, Level, '', 0, 0, false, Level);

        // [GIVEN] L1 and L2 have 3 currencies set up
        for Level := 1 to 2 do
            for Index := 1 to 3 do
                CreateCurrencyforReminderLevel(ReminderTermsCode, Level, LibraryERM.CreateCurrencyWithRandomExchRates(), 0, 0);

        // [GIVEN] L1 and L2 have 2 Reminder texts associated
        for Level := 1 to 2 do
            for Index := 1 to 2 do begin
                Text := StrSubstNo('Random text: %1-%2', Level, Index);
                AddReminderText(ReminderTermsCode, Level, ReminderText.Position::Ending, Text);
            end;

        // [GIVEN] L1 and L2 have 2 10 Additional Fee Setup lines associated
        for Level := 1 to 2 do
            for Index := 1 to 10 do
                CreateAdditionalFeeSetupLine(ReminderTermsCode, Level, false, '', Index);

        // [WHEN] Reminder Terms R is renamed to R'
        NewReminderTermsCode := LibraryUtility.GenerateRandomCode(ReminderTerms.FieldNo(Code), DATABASE::"Reminder Terms");
        Assert.AreNotEqual(NewReminderTermsCode, ReminderTermsCode, 'Random code is not unique');
        ReminderTerms.Get(ReminderTermsCode);
        ReminderTerms.Rename(NewReminderTermsCode);
        Commit();

        // [THEN] All sub records are renamed as well
        ReminderLevel.SetRange("Reminder Terms Code", NewReminderTermsCode);
        Assert.AreEqual(2, ReminderLevel.Count, StrSubstNo(CountMismatchErr, ReminderLevel.TableCaption()));

        CurrencyForReminderLvl.SetRange("Reminder Terms Code", NewReminderTermsCode);
        for Level := 1 to 2 do begin
            CurrencyForReminderLvl.SetRange("No.", Level);
            Assert.AreEqual(3, CurrencyForReminderLvl.Count, StrSubstNo(CountMismatchErr, CurrencyForReminderLvl.TableCaption()));
        end;

        ReminderText.SetRange("Reminder Terms Code", NewReminderTermsCode);
        for Level := 1 to 2 do begin
            ReminderText.SetRange("Reminder Level", Level);
            Assert.AreEqual(2, ReminderText.Count, StrSubstNo(CountMismatchErr, ReminderText.TableCaption()));
        end;

        AdditionalFeeSetup.SetRange("Reminder Terms Code", NewReminderTermsCode);
        for Level := 1 to 2 do begin
            AdditionalFeeSetup.SetRange("Reminder Level No.", Level);
            Assert.AreEqual(10, AdditionalFeeSetup.Count, StrSubstNo(CountMismatchErr, AdditionalFeeSetup.TableCaption()));
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateReminderSingleCustomer()
    var
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustNo: Code[20];
        ReminderTermCode: Code[10];
        InvoiceA: Code[20];
    begin
        // [SCENARIO 107048] A reminder is created when an open CLE is present for a single customer with reminder terms setup at posting time
        Initialize(true);

        // [GIVEN] A customer A with Reminder Terms Code R_a set up
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);

        // [GIVEN] A posted sales invoice (I_a) for Customer A
        InvoiceA := PostSalesInvoice(CustNo, CalcDate('<-10D>', WorkDate()));

        // [GIVEN] I_a is overdue
        // [WHEN] "Create Reminders" action is invoked
        RunCreateReminderReport(CustNo, WorkDate(), CustLedgEntry);

        // [THEN] A Reminder is created for customer A with Reminder Terms Code R_a
        ReminderHeader.SetRange("Customer No.", CustNo);
        ReminderHeader.FindLast();
        Assert.AreEqual(ReminderTermCode, ReminderHeader."Reminder Terms Code",
          StrSubstNo(MustMatchErr, ReminderHeader.FieldCaption("Reminder Terms Code"), ReminderHeader.TableCaption()));

        // [THEN] The reminder have a line for Invoice I_a
        VerifyReminderLineExists(ReminderLine, ReminderHeader."No.", ReminderLine.Type::"Customer Ledger Entry", ReminderLine."Document Type"::Invoice, InvoiceA);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateReminderTwoCustomers()
    var
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustNoA: Code[20];
        CustNoB: Code[20];
        ReminderTermCodeA: Code[10];
        ReminderTermCodeB: Code[10];
        InvoiceA: Code[20];
        InvoiceB: Code[20];
    begin
        // [SCENARIO 107048] Two reminders are created when two open CLE are present for two different customers with reminder terms setup at posting time
        Initialize(true);

        // [GIVEN] A customer A with Reminder Terms Code R_a set up
        CreateStandardReminderTermSetupWithCust(CustNoA, ReminderTermCodeA, true);

        // [GIVEN] A customer A with Reminder Terms Code R_b set up
        CreateStandardReminderTermSetupWithCust(CustNoB, ReminderTermCodeB, true);

        // [GIVEN] A sales invoice is posted for each customer (I_a and I_b)
        InvoiceA := PostSalesInvoice(CustNoA, CalcDate('<-10D>', WorkDate()));
        InvoiceB := PostSalesInvoice(CustNoB, CalcDate('<-10D>', WorkDate()));

        // [GIVEN] I_a and I_b are overdue
        // [WHEN] "Create Reminders" action is invoked
        RunCreateReminderReport(CustNoA, WorkDate(), CustLedgEntry);
        RunCreateReminderReport(CustNoB, WorkDate(), CustLedgEntry);

        // [THEN] A Reminder is created for customer A with Reminder Terms Code R_a
        ReminderHeader.SetRange("Customer No.", CustNoA);
        ReminderHeader.FindLast();
        Assert.AreEqual(ReminderTermCodeA, ReminderHeader."Reminder Terms Code",
          StrSubstNo(MustMatchErr, ReminderHeader.FieldCaption("Reminder Terms Code"), ReminderHeader.TableCaption()));

        // [THEN] The reminder have a line for Invoice I_a
        VerifyReminderLineExists(ReminderLine, ReminderHeader."No.", ReminderLine.Type::"Customer Ledger Entry", ReminderLine."Document Type"::Invoice, InvoiceA);

        // [THEN] A Reminder is created for customer A with Reminder Terms Code R_b
        ReminderHeader.SetRange("Customer No.", CustNoB);
        ReminderHeader.FindLast();
        Assert.AreEqual(ReminderTermCodeB, ReminderHeader."Reminder Terms Code",
          StrSubstNo(MustMatchErr, ReminderHeader.FieldCaption("Reminder Terms Code"), ReminderHeader.TableCaption()));

        // [THEN] The reminder have a line for Invoice I_b
        VerifyReminderLineExists(ReminderLine, ReminderHeader."No.", ReminderLine.Type::"Customer Ledger Entry", ReminderLine."Document Type"::Invoice, InvoiceB);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateReminderEmptyRmdTerms()
    var
        ReminderHeader: Record "Reminder Header";
        CustLedgEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        CustNo: Code[20];
        ReminderTermCode: Code[10];
    begin
        // [SCENARIO 107048] A reminder is NOT created, if the customer does not have the terms setup on the customer card and CLE Rmd Terms is blank
        Initialize(true);

        // [GIVEN] A customer A with Reminder Terms Code NOT set up
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);
        Customer.Get(CustNo);
        Customer.Validate("Reminder Terms Code", '');
        Customer.Modify();

        // [GIVEN] A posted sales invoice (I_a) for Customer A with empty Reminder Terms Code
        PostSalesInvoice(CustNo, CalcDate('<-10D>', WorkDate()));

        // [GIVEN] I_a is overdue
        // [WHEN] "Create Reminders" action is invoked
        RunCreateReminderReport(CustNo, WorkDate(), CustLedgEntry);

        // [THEN] No reminders are created
        ReminderHeader.SetRange("Customer No.", CustNo);
        Assert.AreEqual(0, ReminderHeader.Count, StrSubstNo(ReminderHdrExistsErr, CustNo));
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    [Scope('OnPrem')]
    procedure CreateReminderAlreadyExists()
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustNo: Code[20];
        ReminderTermCode: Code[10];
    begin
        // [SCENARIO 107048] A reminder is not created when a reminder already exists for that Customer, Reminder Terms Code and Currency
        Initialize(true);

        // [GIVEN] A customer A with Reminder Terms Code R_a set up
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);

        // [GIVEN] A posted sales invoice (I_a) for Customer A
        PostSalesInvoice(CustNo, CalcDate('<-10D>', WorkDate()));

        // [GIVEN] I_a is overdue
        // [GIVEN] "Create Reminders" action is invoked for customer A
        RunCreateReminderReport(CustNo, WorkDate(), CustLedgEntry);

        // [WHEN] "Create Reminders" action is invoked again for all customers
        RunCreateReminderReport('', WorkDate(), CustLedgEntry);

        // [THEN] A Confirm dialog is shown indicating a problem
    end;

    [Test]
    [HandlerFunctions('ConfirmNoHandler')]
    [Scope('OnPrem')]
    procedure CreateReminderNoLevels()
    var
        ReminderLevel: Record "Reminder Level";
        ReminderHeader: Record "Reminder Header";
        CustLedgEntry: Record "Cust. Ledger Entry";
        CustNo: Code[20];
        ReminderTermCode: Code[10];
    begin
        // [SCENARIO 107048] A reminder is not created and no errors are thrown when trying to create a reminder for a reminder term without any levels
        Initialize(true);

        // [GIVEN] A customer A with Reminder Terms Code R_a set up without any levels
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);
        ReminderLevel.SetRange("Reminder Terms Code", ReminderTermCode);
        ReminderLevel.DeleteAll(true);

        // [GIVEN] A posted sales invoice (I_a) for Customer A
        PostSalesInvoice(CustNo, CalcDate('<-10D>', WorkDate()));

        // [GIVEN] I_a is overdue
        // [WHEN] "Create Reminders" action is invoked for all customers
        RunCreateReminderReport('', WorkDate(), CustLedgEntry);

        // [THEN] A confirm dialog is shown indicating a problem
        // [THEN] No error is thrown
        // [THEN] No reminder is created for customer A
        ReminderHeader.SetRange("Customer No.", CustNo);
        Assert.AreEqual(0, ReminderHeader.Count,
          StrSubstNo(CountMismatchErr, ReminderHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestSalesInvWithoutLineFee1stRmd()
    var
        ReminderLine: Record "Reminder Line";
        ReminderNo: Code[20];
        InvoiceA: Code[20];
        ReminderTermCode: Code[10];
        CustNo: Code[20];
    begin
        // [SCENARIO 107048] Add. Line Fee is NOT suggested for a sales invoice as the reminder terms associated with it does not have Add. Line Fee set up
        Initialize(false);

        // [GIVEN] A Reminder Term (N) that have Line Fee Amount = 0 for level 1
        // [GIVEN] A customer setup with Reminder Term N
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, false);

        // [GIVEN] A sales invoice (A) is posted for the customer
        // [GIVEN] The invoice due date + Reminder grace period < TODAY
        InvoiceA := PostSalesInvoice(CustNo, CalcDate('<-5D>', WorkDate()));

        // [WHEN] A reminder is created for the customer
        ReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, WorkDate());

        // [THEN] Invoice A is added to the reminder
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Customer Ledger Entry", ReminderLine."Document Type"::Invoice, InvoiceA);

        // [THEN] No Line Fee is added for invoice A
        VerifyReminderLineDoesNotExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee", ReminderLine."Document Type"::Invoice, InvoiceA);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestSalesInvWithLineFee1stRmd()
    var
        ReminderLine: Record "Reminder Line";
        ReminderLevel: Record "Reminder Level";
        ReminderNo: Code[20];
        InvoiceA: Code[20];
        ReminderTermCode: Code[10];
        CustNo: Code[20];
    begin
        // [SCENARIO 107048] Add. Line Fee is suggested on 1st reminder for sales invoice with reminder terms that have Add. Line Fee set up
        Initialize(false);

        // [GIVEN] A Reminder Term (N) that have Line Fee Amount = X, where X > 0 for level 1 and Line Fee description = D
        // [GIVEN] A customer setup with Reminder Term N
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);

        // [GIVEN] A sales invoice (A) is posted for the customer
        // [GIVEN] The invoice due date + Reminder grace period < TODAY
        InvoiceA := PostSalesInvoice(CustNo, CalcDate('<-5D>', WorkDate()));

        // [WHEN] A reminder is created for the customer
        ReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, WorkDate());

        // [THEN] Invoice A is added to the reminder
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Customer Ledger Entry", ReminderLine."Document Type"::Invoice, InvoiceA);

        // [THEN] A Line Fee line is added with amount = X and description = D
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee", ReminderLine."Document Type"::Invoice, InvoiceA);
        ReminderLevel.Get(ReminderTermCode, 1);
        Assert.AreEqual(ReminderLevel."Add. Fee per Line Description", ReminderLine.Description,
          StrSubstNo(MustMatchErr, ReminderLine.FieldCaption(Description), ReminderLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('IssueRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestSalesInvWith1LineFee2ndRmd()
    var
        ReminderLine: Record "Reminder Line";
        FirstReminderNo: Code[20];
        SecondReminderNo: Code[20];
        InvoiceA: Code[20];
        ReminderTermCode: Code[10];
        CustNo: Code[20];
    begin
        // [SCENARIO 107048] Second reminder for a sales invoice and line fee was applied on the 1st reminder, is not suggested again
        Initialize(false);

        // [GIVEN] A Reminder Term (N) is created
        // [GIVEN] A customer setup with Reminder Term N
        // [GIVEN] Level 1 for N has Line Fee amount = X, where X > 0 and Description = Dx
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);

        // [GIVEN] Level 2 for N has Line Fee amount = 0
        CreateReminderTermsLevel(ReminderTermCode, 5, 4, '', 0, 0, false, 2);

        // [GIVEN] A sales invoice (A) is posted for the customer
        InvoiceA := PostSalesInvoice(CustNo, CalcDate('<-10D>', WorkDate()));

        // [GIVEN] The first reminder is issued for invoice A with Line Fee
        FirstReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, CalcDate('<-6D>', WorkDate()));
        IssueReminder(FirstReminderNo, 0, false);

        // [GIVEN] The invoice and Line Fee is NOT paid
        // [GIVEN] The invoice due date + 2nd reminder grace period < TODAY
        // [WHEN] A 2nd reminder is created for the customer
        SecondReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, WorkDate());

        // [THEN] A reminder line is added for invoice A
        // [THEN] A reminder line of type Customer Ledger Entry is added refering to the first reminder
        VerifyReminderLineExists(ReminderLine, SecondReminderNo, ReminderLine.Type::"Customer Ledger Entry", ReminderLine."Document Type"::Invoice, InvoiceA);

        // [THEN] No Line Fee lines are added
        VerifyReminderLineDoesNotExists(ReminderLine, SecondReminderNo, ReminderLine.Type::"Line Fee", ReminderLine."Document Type"::Invoice, InvoiceA);
    end;

    [Test]
    [HandlerFunctions('IssueRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestSalesInvWith12LineFee2ndRmd()
    var
        ReminderLine: Record "Reminder Line";
        ReminderLevel: Record "Reminder Level";
        FirstReminderNo: Code[20];
        SecondReminderNo: Code[20];
        InvoiceA: Code[20];
        ReminderTermCode: Code[10];
        CustNo: Code[20];
    begin
        // [SCENARIO 107048] Second reminder for a sales invoice and with line fee set up for level 1 AND 2
        Initialize(false);

        // [GIVEN] A Reminder Term (N) is created
        // [GIVEN] A customer setup with Reminder Term N
        // [GIVEN] Level 1 for N has Line Fee amount = X, where X > 0
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);

        // [GIVEN] Level 2 for N has Line Fee amount = Y, where y > 0
        CreateReminderTermsLevel(ReminderTermCode, 5, 4, '', 0, LibraryRandom.RandDecInRange(1, 100, 2), false, 2);
        ReminderLevel.Get(ReminderTermCode, 2);

        // [GIVEN] A sales invoice (A) is posted for the customer
        InvoiceA := PostSalesInvoice(CustNo, CalcDate('<-10D>', WorkDate()));

        // [GIVEN] The first reminder is issued for invoice A with Line Fee
        FirstReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, CalcDate('<-6D>', WorkDate()));
        IssueReminder(FirstReminderNo, 0, false);

        // [GIVEN] The invoice and Line Fee is NOT paid
        // [GIVEN] The invoice due date + 2nd reminder grace period < TODAY
        // [WHEN] A 2nd reminder is created for the customer
        SecondReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, WorkDate());

        // [THEN] A reminder line is added for invoice A
        // [THEN] A reminder line of type Customer Ledger Entry is added refering to the first reminder
        VerifyReminderLineExists(ReminderLine, SecondReminderNo, ReminderLine.Type::"Customer Ledger Entry", ReminderLine."Document Type"::Invoice, InvoiceA);

        // [THEN] A Line Fee line is created with amount = Y
        VerifyReminderLineExists(ReminderLine, SecondReminderNo, ReminderLine.Type::"Line Fee", ReminderLine."Document Type"::Invoice, InvoiceA);
        Assert.AreEqual(ReminderLevel."Add. Fee per Line Amount (LCY)", ReminderLine.Amount,
          StrSubstNo(MustMatchErr, ReminderLine.FieldCaption(Amount), ReminderLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('IssueRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestSalesInvWithLineFee2ndRmdMultiple()
    var
        ReminderLine: Record "Reminder Line";
        CustLedgEntryLineFeeOn: Record "Cust. Ledger Entry";
        FirstReminderNo: Code[20];
        SecondReminderNo: Code[20];
        FirstIssuedReminderNo: Code[20];
        InvoiceA: Code[20];
        InvoiceB: Code[20];
        ReminderTermCode: Code[10];
        CustNo: Code[20];
    begin
        // [SCENARIO 107048] Reminder with two previous posted Line Fees that are not paid
        Initialize(false);

        // [GIVEN] A Reminder Term (N) that have level 1 set up with Line Fee Amount = X, where X > 0, and no Line Fee on level 2
        // [GIVEN] A customer setup with Reminder Term N
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);
        CreateReminderTermsLevel(ReminderTermCode, 5, 4, '', 0, 0, false, 2);

        // [GIVEN] Two sales invoices (A and B) are posted for the customer
        InvoiceA := PostSalesInvoice(CustNo, CalcDate('<-10D>', WorkDate()));
        InvoiceB := PostSalesInvoice(CustNo, CalcDate('<-10D>', WorkDate()));

        // [GIVEN] The first reminder (R1) is issued for invoice A and B with Line Fee X
        FirstReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, CalcDate('<-6D>', WorkDate()));
        FirstIssuedReminderNo := IssueReminder(FirstReminderNo, 0, false);

        // [GIVEN] The invoices and Line Fees are NOT paid
        // [GIVEN] The invoice due date + 2nd reminder grace period < TODAY
        // [WHEN] A 2nd reminder is created for the customer with Apply Line Fee on Invoices
        CustLedgEntryLineFeeOn.SetRange("Document Type", CustLedgEntryLineFeeOn."Document Type"::Invoice);
        SecondReminderNo := CreateReminderAndSuggestLines(CustNo, WorkDate(), CustLedgEntryLineFeeOn);

        // [THEN] A reminder line is added for invoice A
        VerifyReminderLineExists(ReminderLine, SecondReminderNo, ReminderLine.Type::"Customer Ledger Entry", ReminderLine."Document Type"::Invoice, InvoiceA);

        // [THEN] A reminder line is added for invoice B
        VerifyReminderLineExists(ReminderLine, SecondReminderNo, ReminderLine.Type::"Customer Ledger Entry", ReminderLine."Document Type"::Invoice, InvoiceB);

        // [THEN] A reminder line is added for Reminder R1
        VerifyReminderLineExists(
              ReminderLine, SecondReminderNo, ReminderLine.Type::"Customer Ledger Entry", ReminderLine."Document Type"::Reminder, FirstIssuedReminderNo);

        // [THEN] No Line Fee is added to the Reminder
        VerifyReminderLineDoesNotExists(ReminderLine, SecondReminderNo, ReminderLine.Type::"Line Fee", "General Posting Type"::Sale, '');
    end;

    [Test]
    [HandlerFunctions('IssueRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestSalesInvWithLineFee2ndRmdNotAppliedBefore()
    var
        ReminderLine: Record "Reminder Line";
        ReminderLevel: Record "Reminder Level";
        FirstReminderNo: Code[20];
        SecondReminderNo: Code[20];
        InvoiceA: Code[20];
        ReminderTermCode: Code[10];
        CustNo: Code[20];
    begin
        // [SCENARIO 107048] Second reminder for a sales invoice with reminder terms that have Line Fee on level 1 and 2, but the user did not issue line fee on the 1st reminder, the line fee is suggested
        Initialize(false);

        // [GIVEN] A Reminder Term (N) is created
        // [GIVEN] Level 1 for N has Line Fee amount = X, where X > 0 and Description = Dx
        // [GIVEN] Level 2 for N has Line Fee amount = Y, where y > 0 and Description = Dy
        // [GIVEN] A customer setup with Reminder Term N
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);
        CreateReminderTermsLevel(ReminderTermCode, 5, 5, '', 0, LibraryRandom.RandDecInRange(1, 100, 2), false, 2);
        ReminderLevel.Get(ReminderTermCode, 2);

        // [GIVEN] A sales invoice (A) is posted for the customer
        InvoiceA := PostSalesInvoice(CustNo, CalcDate('<-15D>', WorkDate()));

        // [GIVEN] The first reminder (R1) is issued for invoice A with Line Fee X but where the user deleted the Line Fee before issuing
        FirstReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, CalcDate('<-8D>', WorkDate()));
        GetReminderLines(ReminderLine, FirstReminderNo, ReminderLine.Type::"Line Fee", ReminderLine."Document Type"::Invoice, InvoiceA);
        ReminderLine.Delete(true);
        IssueReminder(FirstReminderNo, 0, false);

        // [GIVEN] The invoice is NOT paid
        // [GIVEN] The invoice due date + 2nd reminder grace period < TODAY
        // [WHEN] A 2nd reminder (R2) is created for the customer
        SecondReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, WorkDate());

        // [THEN] A reminder line is added for invoice A
        VerifyReminderLineExists(ReminderLine, SecondReminderNo, ReminderLine.Type::"Customer Ledger Entry", ReminderLine."Document Type"::Invoice, InvoiceA);

        // [THEN] A Line Fee line is added for invoice A with amount Y and description Dy
        VerifyReminderLineExists(ReminderLine, SecondReminderNo, ReminderLine.Type::"Line Fee", ReminderLine."Document Type"::Invoice, InvoiceA);
        Assert.AreEqual(ReminderLevel."Add. Fee per Line Amount (LCY)", ReminderLine.Amount,
          StrSubstNo(MustMatchErr, ReminderLine.FieldCaption(Amount), ReminderLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestSalesInvoiceValidateLineFeeText()
    var
        ReminderLine: Record "Reminder Line";
        ReminderLevel: Record "Reminder Level";
        ReminderNo: Code[20];
        InvoiceA: Code[20];
        ReminderTermCode: Code[10];
        CustNo: Code[20];
    begin
        // [SCENARIO 107048] The Add. Line Fee text is generated according to the reminder terms setup and have reference to the invoice in question
        Initialize(false);

        // [GIVEN] A Reminder Term (N) is created
        // [GIVEN] Level 1 for N has Line Fee amount = X, where X > 0 and Description = Dx
        // [GIVEN] A customer setup with Reminder Term N
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);

        // [GIVEN] The Line Fee description (Dx) contains a substitute for invoice number
        ReminderLevel.Get(ReminderTermCode, 1);
        ReminderLevel."Add. Fee per Line Description" := 'Something %8';
        ReminderLevel.Modify(true);

        // [GIVEN] A sales invoice (A) is posted for the customer
        InvoiceA := PostSalesInvoice(CustNo, CalcDate('<-10D>', WorkDate()));

        // [GIVEN] The invoice due date + Reminder grace period < TODAY
        // [WHEN] A reminder is created for the customer
        ReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, WorkDate());

        // [THEN] A Line Fee line is added with amount = X and description = Dx' where the invoice A No. is substituted into the description
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee", ReminderLine."Document Type"::Invoice, InvoiceA);
        Assert.AreEqual(
          StrSubstNo('Something %1', InvoiceA),
          ReminderLine.Description,
          StrSubstNo(MustMatchErr, ReminderLine.FieldCaption(Description), ReminderLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('UpdateReminderTextRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestUpdateReminderTextTotalCorrect()
    var
        ReminderLine: Record "Reminder Line";
        ReminderLine2: Record "Reminder Line";
        ReminderTermCode: Code[10];
        CustNo: Code[20];
        InvoiceA: Code[20];
        ReminderNo: Code[20];
        AmountX: Decimal;
        AmountA: Decimal;
        TextAmount: Decimal;
    begin
        // [SCENARIO 107048] Update reminder text includes the Add. Line Fee entries to be posted into the total amount of the reminder
        Initialize(false);

        // [GIVEN] Reminder terms set up without additional fee and with Line Fee = X, where X > 0
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);
        AddReminderText(ReminderTermCode, 1, "Reminder Text Position"::Ending, 'Total due: %7');

        // [GIVEN] A reminder with over due invoice (A) and Line Fee for invoice A
        InvoiceA := PostSalesInvoice(CustNo, CalcDate('<-10D>', WorkDate()));
        ReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, WorkDate());
        VerifyReminderLineExists(ReminderLine2, ReminderNo, ReminderLine2.Type::"Customer Ledger Entry", ReminderLine2."Document Type"::Invoice, InvoiceA);
        AmountA := ReminderLine2."Remaining Amount" + ReminderLine2.Amount + ReminderLine2."VAT Amount";

        VerifyReminderLineExists(ReminderLine2, ReminderNo, ReminderLine2.Type::"Line Fee", ReminderLine2."Document Type"::Invoice, InvoiceA);
        AmountX := ReminderLine2."Remaining Amount" + ReminderLine2.Amount + ReminderLine2."VAT Amount";

        // [GIVEN] All Reminder Lines with Line Type = "Ending Text" is removed from the Reminder
        ReminderLine.SetRange("Reminder No.", ReminderNo);
        ReminderLine.SetRange("Line Type", ReminderLine."Line Type"::"Ending Text");
        ReminderLine.DeleteAll();

        // [WHEN] User invokes "Update Reminder Text"
        UpdateReminderText(ReminderNo, 1);

        // [THEN] The ending text contains A+X as the amount
        ReminderLine.SetFilter(Description, '<>%1', '');
        ReminderLine.FindFirst();
        Evaluate(TextAmount, DelStr(ReminderLine.Description, 1, StrLen('Total due: ')));
        Assert.AreNearlyEqual(
          AmountX + AmountA,
          TextAmount,
          1,
          StrSubstNo(MustMatchErr, ReminderLine.FieldCaption(Description), ReminderLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('UpdateReminderTextRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestUpdateReminderTextLineFeeAmountChanged()
    var
        ReminderLine: Record "Reminder Line";
        ReminderLine2: Record "Reminder Line";
        ReminderTermCode: Code[10];
        CustNo: Code[20];
        InvoiceA: Code[20];
        ReminderNo: Code[20];
        AmountY: Decimal;
        AmountA: Decimal;
        TextAmount: Decimal;
    begin
        // [SCENARIO 107048] The reminder text (with the total) can be updated when the Line Fee Amount is changed manually
        Initialize(false);

        // [GIVEN] Reminder terms set up without additional fee and with Line Fee = X, where X > 0
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);
        AddReminderText(ReminderTermCode, 1, "Reminder Text Position"::Ending, 'Total due: %7');

        // [GIVEN] A reminder with over due invoice (A) and Line Fee for invoice A
        InvoiceA := PostSalesInvoice(CustNo, CalcDate('<-10D>', WorkDate()));
        ReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, WorkDate());
        VerifyReminderLineExists(ReminderLine2, ReminderNo, ReminderLine2.Type::"Customer Ledger Entry", ReminderLine2."Document Type"::Invoice, InvoiceA);
        AmountA := ReminderLine2."Remaining Amount" + ReminderLine2.Amount + ReminderLine2."VAT Amount";

        // [GIVEN] User changes the Line Fee Amount to Y
        VerifyReminderLineExists(ReminderLine2, ReminderNo, ReminderLine2.Type::"Line Fee", ReminderLine2."Document Type"::Invoice, InvoiceA);
        ReminderLine2.Validate(Amount, LibraryRandom.RandDecInRange(1, 100, 2));
        ReminderLine2.Modify();
        AmountY := ReminderLine2."Remaining Amount" + ReminderLine2.Amount + ReminderLine2."VAT Amount";

        // [GIVEN] All Reminder Lines with Line Type = "Ending Text" is removed from the Reminder
        ReminderLine.SetRange("Reminder No.", ReminderNo);
        ReminderLine.SetRange("Line Type", ReminderLine."Line Type"::"Ending Text");
        ReminderLine.DeleteAll();

        // [WHEN] User invokes "Update Reminder Text"
        UpdateReminderText(ReminderNo, 1);

        // [THEN] The total of the reminder is A+Y
        ReminderLine.SetFilter(Description, '<>%1', '');
        ReminderLine.FindFirst();
        Evaluate(TextAmount, DelStr(ReminderLine.Description, 1, StrLen('Total due: ')));
        Assert.AreNearlyEqual(
          AmountY + AmountA,
          TextAmount,
          1,
          StrSubstNo(MustMatchErr, ReminderLine.FieldCaption(Description), ReminderLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestLineFeeGLAccountSetup()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        ReminderLine: Record "Reminder Line";
        ReminderTermCode: Code[10];
        CustNo: Code[20];
        GLAccountNo: Code[20];
        InvoiceA: Code[20];
        ReminderNo: Code[20];
    begin
        // [SCENARIO 107048] The G/L account of Add. Line Fee fees are taken from Customer Posting Group setup (without VAT setup)
        Initialize(false);

        // [GIVEN] Reminder terms (R) set up without additional fee and with Line Fee = X, where X > 0 for level 1
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);

        // [GIVEN] A G/L account (M) is created without VAT
        // [GIVEN] G/L Account M is setup as default account for Line Fee in Customer Posting Group
        CustomerPostingGroup.FindFirst();
        GLAccountNo := CustomerPostingGroup."Add. Fee per Line Account";

        // [GIVEN] An overdue sales invoice for a customer with reminder terms R
        InvoiceA := PostSalesInvoice(CustNo, CalcDate('<-10D>', WorkDate()));

        // [WHEN] A reminder for the customer is created
        ReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, CalcDate('<-6D>', WorkDate()));

        // [THEN] The G/L account of the Line Fee Reminder line is M
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee", ReminderLine."Document Type"::Invoice, InvoiceA);
        Assert.AreEqual(GLAccountNo, ReminderLine."No.",
          StrSubstNo(MustMatchErr, ReminderLine.FieldCaption("No."), ReminderLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestLineFeeEmptyDocumentType()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerPostingGroup: Record "Customer Posting Group";
        ReminderLine: Record "Reminder Line";
        ReminderTermCode: Code[10];
        CustNo: Code[20];
        GLAccountNo: Code[20];
        ReminderNo: Code[20];
    begin
        // [SCENARIO 107048] Additional Fee per Line is applied on Customer Ledger Entry with Doc.Type set to blank
        Initialize(false);

        // [GIVEN] Reminder terms (R) set up without additional fee and with Line Fee = X, where X > 0 for level 1
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);
        CustomerPostingGroup.FindFirst();
        GLAccountNo := CustomerPostingGroup."Add. Fee per Line Account";

        // [GIVEN] An overdue gen. journal line for a customer with reminder terms R
        PostCustGenJnlLine(CustNo);

        // [WHEN] A reminder for the customer is created
        ReminderNo :=
          CreateReminderAndSuggestLinesLineFeeOnAll(
            CustNo, CalcDate('<' + Format(LibraryRandom.RandIntInRange(10, 100)) + 'D>', WorkDate()));
        CustLedgerEntry.SetRange("Customer No.", CustNo);
        CustLedgerEntry.FindLast();

        // [THEN] The Line Fee Reminder line is created
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee", ReminderLine."Document Type"::" ", CustLedgerEntry."Document No.");
        Assert.AreEqual(GLAccountNo, ReminderLine."No.",
          StrSubstNo(MustMatchErr, ReminderLine.FieldCaption("No."), ReminderLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestLineFeeGLAccountSetupVAT()
    var
        ReminderLine: Record "Reminder Line";
        CustomerPostingGroup: Record "Customer Posting Group";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        GLAccountNo: Code[20];
        OldGLAccountNo: Code[20];
        CustNo: Code[20];
        ReminderTermCode: Code[10];
        InvoiceA: Code[20];
        ReminderNo: Code[20];
    begin
        // [SCENARIO 107048] The G/L account of Add. Line Fee fees are taken from Customer Posting Group setup (with VAT setup)
        Initialize(false);

        // [GIVEN] Reminder terms (R) set up without additional fee and with Line Fee = X, where X > 0 for level 1
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);

        // [GIVEN] A G/L account (M) is created with VAT
        Customer.Get(CustNo);
        GLAccountNo := FindGLAccountWithVAT(Customer."VAT Bus. Posting Group");
        GLAccount.Get(GLAccountNo);

        // [GIVEN] G/L Account M is setup as default account for Line Fee in Customer Posting Group
        CustomerPostingGroup.FindFirst();
        OldGLAccountNo := CustomerPostingGroup."Add. Fee per Line Account";
        CustomerPostingGroup.ModifyAll("Add. Fee per Line Account", GLAccountNo);

        // [GIVEN] An overdue sales invoice for a customer with reminder terms R
        InvoiceA := PostSalesInvoice(CustNo, CalcDate('<-10D>', WorkDate()));

        // [WHEN] A reminder for the customer is created
        ReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, CalcDate('<-6D>', WorkDate()));
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee", ReminderLine."Document Type"::Invoice, InvoiceA);

        // [THEN] The G/L account of the Line Fee Reminder line is M
        Assert.AreEqual(
          GLAccountNo, ReminderLine."No.", StrSubstNo(MustMatchErr, ReminderLine.FieldCaption("No."), ReminderLine.TableCaption()));

        // [THEN] VAT posting groups are transfered to the Reminder line
        Assert.AreEqual(GLAccount."Gen. Prod. Posting Group", ReminderLine."Gen. Prod. Posting Group",
          StrSubstNo(MustMatchErr, ReminderLine.FieldCaption("Gen. Prod. Posting Group"), ReminderLine.TableCaption()));
        Assert.AreEqual(GLAccount."VAT Prod. Posting Group", ReminderLine."VAT Prod. Posting Group",
          StrSubstNo(MustMatchErr, ReminderLine.FieldCaption("VAT Prod. Posting Group"), ReminderLine.TableCaption()));

        // [THEN] The VAT percentage is that of the VAT Posting Group
        VATPostingSetup.Get(GLAccount."VAT Bus. Posting Group", ReminderLine."VAT Prod. Posting Group");
        Assert.AreEqual(VATPostingSetup."VAT %", ReminderLine."VAT %",
          StrSubstNo(MustMatchErr, ReminderLine.FieldCaption("VAT %"), ReminderLine.TableCaption()));
        Assert.AreNotEqual(0, ReminderLine."VAT %",
          StrSubstNo(MustNotMatchErr, ReminderLine.FieldCaption("VAT %"), ReminderLine.TableCaption()));

        // Clean up
        CustomerPostingGroup.ModifyAll("Add. Fee per Line Account", OldGLAccountNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestTwiceInvoke()
    var
        CustLedgEntryLineFeeOn: Record "Cust. Ledger Entry";
        ReminderLine: Record "Reminder Line";
        ReminderNo: Code[20];
        ReminderTermCode: Code[10];
        CustNo: Code[20];
        NumberOfLines: Integer;
    begin
        // [SCENARIO 107048] Suggest lines is executed twice without resulting in conflicts
        Initialize(false);

        // [GIVEN] Reminder terms (R) set up without additional fee and with Line Fee = X, where X > 0
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);

        // [GIVEN] A over due sales invoice for a customer with reminder terms R
        PostSalesInvoice(CustNo, CalcDate('<-10D>', WorkDate()));

        // [GIVEN] A reminder for the customer is created with Q Reminder Lines
        CustLedgEntryLineFeeOn.Reset();
        ReminderNo := CreateReminderAndSuggestLines(CustNo, WorkDate(), CustLedgEntryLineFeeOn);
        ReminderLine.SetRange("Reminder No.", ReminderNo);
        NumberOfLines := ReminderLine.Count();

        // [WHEN] "Suggest Reminder Lines" are invoked again
        SuggestReminderLines(ReminderNo, CustLedgEntryLineFeeOn);

        // [THEN] No errors is thrown
        // [THEN] The number of lines is Q
        Assert.AreEqual(NumberOfLines, ReminderLine.Count, NumberReminderLineErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestValidatePostingAndDueDate()
    var
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        CustNo: Code[20];
        ReminderTermCode: Code[10];
        InvoiceA: Code[20];
        ReminderNo: Code[20];
    begin
        // [SCENARIO 107048] The posting date of a Add. Line Fee line is equal the Reminder document date and Due date is equal the Reminder due date
        Initialize(false);

        // [GIVEN] Reminder terms (R) set up without additional fee and with Line Fee = X, where X > 0
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);

        // [GIVEN] A over due sales invoice for a customer with reminder terms R
        InvoiceA := PostSalesInvoice(CustNo, CalcDate('<-10D>', WorkDate()));

        // [WHEN] A reminder for the customer is created
        ReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, WorkDate());
        ReminderHeader.Get(ReminderNo);

        // [THEN] The posting date of the Line Fee is equal to the Reminder document date
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee", ReminderLine."Document Type"::Invoice, InvoiceA);
        Assert.AreEqual(ReminderHeader."Posting Date", ReminderLine."Posting Date",
          StrSubstNo(MustMatchErr, ReminderLine.FieldCaption("Posting Date"), ReminderLine.TableCaption()));

        // [THEN] The Due Date of the Line Fee is equal to the due date of the reminder due date
        Assert.AreEqual(ReminderHeader."Due Date", ReminderLine."Due Date",
          StrSubstNo(MustMatchErr, ReminderLine.FieldCaption("Due Date"), ReminderLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestLineFeeSumOnSelectedDocType()
    var
        CustLedgEntryLineFeeOn: Record "Cust. Ledger Entry";
        ReminderLine: Record "Reminder Line";
        ReminderNo: Code[20];
        CustNo: Code[20];
        ReminderTermCode: Code[10];
        InvoiceA: Code[20];
        CreditMemoB: Code[20];
    begin
        // [SCENARIO 107048] Add. Line Fee is only applied to the selected document types
        Initialize(false);

        // [GIVEN] Reminder terms (R) set up without additional fee and with Line Fee = X, where X > 0 for level 1
        // [GIVEN] A customer with reminder terms R
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);

        // [GIVEN] An overdue Credit Memo for the customer
        MaxDocumentValue := 1000;
        CreditMemoB := PostCreditMemo(CustNo, CalcDate('<-14D>', WorkDate()));

        // [GIVEN] An overdue Invoice for the customer
        MinDocumentValue := 1001;
        MaxDocumentValue := 100000;
        InvoiceA := PostSalesInvoice(CustNo, CalcDate('<-10D>', WorkDate()));

        // [GIVEN] A reminder is created for the customer
        // [WHEN] A suggest lines is invoked with Document Type for Line Fee set to Credit Memo
        CustLedgEntryLineFeeOn.SetRange("Document Type", CustLedgEntryLineFeeOn."Document Type"::"Credit Memo");
        ReminderNo := CreateReminderAndSuggestLines(CustNo, WorkDate(), CustLedgEntryLineFeeOn);

        // [THEN] A reminder line is created for the Credit Memo
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Customer Ledger Entry", ReminderLine."Document Type"::"Credit Memo", CreditMemoB);

        // [THEN] Line Fee is added for the overdue Credit Memo
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee", ReminderLine."Document Type"::"Credit Memo", CreditMemoB);

        // [THEN] A reminder line is created for the Invoice
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Customer Ledger Entry", ReminderLine."Document Type"::Invoice, InvoiceA);

        // [THEN] Line Fee is NOT added for the overdue Invoice
        VerifyReminderLineDoesNotExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee", ReminderLine."Document Type"::Invoice, InvoiceA);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestDifferentCurrencyExists()
    var
        ReminderLine: Record "Reminder Line";
        Customer: Record Customer;
        FeeAmountX: Decimal;
        ReminderTermCode: Code[10];
        CustNo: Code[20];
        InvoiceA: Code[20];
        ReminderNo: Code[20];
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 107048] Customer uses a different currencly that LCY, the Line Fee is picked from the reminder level currency table instead
        Initialize(false);

        // [GIVEN] Currency G with exchange rate
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(CalcDate('<-1Y>', WorkDate()), 2, 1);

        // [GIVEN] A Reminder term (R) with level 1 setup for currency G with Line Fee amount = X, where X > 0.
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);
        FeeAmountX := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateCurrencyforReminderLevel(ReminderTermCode, 1, CurrencyCode, 0, FeeAmountX);

        // [GIVEN] A customer (C) with currency G
        Customer.Get(CustNo);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Modify(true);

        // [GIVEN] A sales invoice (I_a) is posted for customer C with currency G
        InvoiceA := PostSalesInvoice(CustNo, CalcDate('<-10D>', WorkDate()));

        // [GIVEN] Invoice I_a is overdue
        // [WHEN] A reminder is created for customer C with currency G
        ReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, WorkDate());

        // [THEN] A Reminder line is created for Invoice I_a
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Customer Ledger Entry", ReminderLine."Document Type"::Invoice, InvoiceA);

        // [THEN] A Line Fee line is created for Invoice I_a with amount X
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee", ReminderLine."Document Type"::Invoice, InvoiceA);
        Assert.AreEqual(FeeAmountX, ReminderLine.Amount,
          StrSubstNo(MustMatchErr, ReminderLine.FieldCaption(Amount), ReminderLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestDifferentCurrencyNotExists()
    var
        ReminderLine: Record "Reminder Line";
        Customer: Record Customer;
        ReminderLevel: Record "Reminder Level";
        FeeAmountX: Decimal;
        FeeAmountY: Decimal;
        ReminderTermCode: Code[10];
        CustNo: Code[20];
        InvoiceA: Code[20];
        ReminderNo: Code[20];
        CurrencyCodeH: Code[10];
        CurrencyCodeG: Code[10];
    begin
        // [SCENARIO 107048] Customer uses a different currencly that LCY, the Line Fee is picked from the reminder level currency table instead.
        // Calculates the line fee based on the LCY fee.
        Initialize(false);

        // [GIVEN] Currency G and H with fixed exchange rates
        CurrencyCodeG := LibraryERM.CreateCurrencyWithExchangeRate(CalcDate('<-1Y>', WorkDate()), 2, 1);
        CurrencyCodeH := LibraryERM.CreateCurrencyWithExchangeRate(CalcDate('<-1Y>', WorkDate()), 3, 1);

        // [GIVEN] A Reminder term (R) with level 1 setup for currency G with Line Fee amount = X, where X > 0 and Line Fee Amount Y for LCY.
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);
        FeeAmountX := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateCurrencyforReminderLevel(ReminderTermCode, 1, CurrencyCodeG, 0, FeeAmountX);
        ReminderLevel.Get(ReminderTermCode, 1);
        FeeAmountY := ReminderLevel."Add. Fee per Line Amount (LCY)";

        // [GIVEN] A customer (C) with currency H
        Customer.Get(CustNo);
        Customer.Validate("Currency Code", CurrencyCodeH);
        Customer.Modify(true);

        // [GIVEN] A sales invoice (I_a) is posted for customer C with currency H
        InvoiceA := PostSalesInvoice(CustNo, CalcDate('<-10D>', WorkDate()));

        // [GIVEN] Invoice I_a is overdue
        // [WHEN] A reminder is created for customer C with currency H
        ReminderLine.DeleteAll();
        ReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, WorkDate());

        // [THEN] A Reminder line is created for Invoice I_a
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Customer Ledger Entry", ReminderLine."Document Type"::Invoice, InvoiceA);

        // [THEN] A Line Fee line is created for Invoice I_a with 3 times amount Y
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee", ReminderLine."Document Type"::Invoice, InvoiceA);
        Assert.AreNearlyEqual(3 * FeeAmountY, ReminderLine.Amount, 1,
          StrSubstNo(MustMatchErr, ReminderLine.FieldCaption(Amount), ReminderLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestTNoInterest()
    var
        ReminderLine: Record "Reminder Line";
        ReminderHeader: Record "Reminder Header";
        ReminderTermCode: Code[10];
        CustNo: Code[20];
        InvoiceA: Code[20];
        ReminderNo: Code[20];
    begin
        // [SCENARIO TFS=TFS=107048] When Reminder Terms is not set up to Calculate interest then the outstanding document was posted,
        // then no interest is calculated when the reminder is issued
        Initialize(false);

        // [GIVEN] A Reminder Term (N) with Calculate Interest = No and Post Interest = Yes
        // [GIVEN] A customer setup with Reminder Term N
        // [GIVEN] A Finance Charge Term (T) with 2% interest and with "Add. Line Fee in Interest" = TRUE
        CreateStandardReminderTermSetupWithCustAndFinChrg(CustNo, ReminderTermCode, false, false, true);

        // [GIVEN] A sales invoice (A) is posted for the customer
        // [GIVEN] The invoice due date + Reminder grace period < TODAY
        InvoiceA := PostSalesInvoice(CustNo, CalcDate('<-5D>', WorkDate()));

        // [WHEN] A reminder is created for the customer
        ReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, WorkDate());

        // [THEN] Invoice A is added to the reminder
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Customer Ledger Entry", ReminderLine."Document Type"::Invoice, InvoiceA);

        // [THEN] Interest is NOT calculated for invoice A
        Assert.AreEqual(0.0, ReminderLine.Amount,
          StrSubstNo(MustMatchErr, ReminderLine.FieldCaption(Amount), ReminderLine.TableCaption()));

        // [THEN] The reminder header have Post Interest = Yes
        ReminderHeader.Get(ReminderNo);
        Assert.AreEqual(true, ReminderHeader."Post Interest",
          StrSubstNo(MustMatchErr, ReminderHeader.FieldCaption("Post Interest"), ReminderHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestTCalcInterestTPostCNoPost()
    var
        ReminderLine: Record "Reminder Line";
        ReminderHeader: Record "Reminder Header";
        ReminderTerms: Record "Reminder Terms";
        ReminderTermCode: Code[10];
        CustNo: Code[20];
        InvoiceA: Code[20];
        ReminderNo: Code[20];
    begin
        // [SCENARIO TFS=TFS=107048] When Reminder Terms is set up to Calculate interest and post it when the outstanding document was posted,
        // and then the Reminder Terms is setup to NOT post the interest at time of issuing the reminder, the interest amount is shown on the reminder
        Initialize(false);

        // [GIVEN] A Reminder Term (N) with Calculate Interest = Yes and Post Interest = Yes
        // [GIVEN] A customer setup with Reminder Term N
        // [GIVEN] A Finance Charge Term (T) with 2% interest and with "Add. Line Fee in Interest" = TRUE
        CreateStandardReminderTermSetupWithCustAndFinChrg(CustNo, ReminderTermCode, false, true, true);

        // [GIVEN] A sales invoice (A) is posted for the customer
        // [GIVEN] The invoice due date + Reminder grace period < TODAY
        InvoiceA := PostSalesInvoice(CustNo, CalcDate('<-5D>', WorkDate()));

        // [GIVEN] Reminder Terms N is changed to Post Interest = No
        ReminderTerms.Get(ReminderTermCode);
        ReminderTerms."Post Interest" := false;
        ReminderTerms.Modify(true);

        // [WHEN] A reminder is created for the customer
        ReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, WorkDate());

        // [THEN] Invoice A is added to the reminder
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Customer Ledger Entry", ReminderLine."Document Type"::Invoice, InvoiceA);

        // [THEN] Interest is calculated for invoice A
        Assert.AreNotEqual(0.0, ReminderLine.Amount,
          StrSubstNo(MustNotMatchErr, ReminderLine.FieldCaption(Amount), ReminderLine.TableCaption()));

        // [THEN] The reminder header have Post Interest = No
        ReminderHeader.Get(ReminderNo);
        Assert.AreEqual(false, ReminderHeader."Post Interest",
          StrSubstNo(MustMatchErr, ReminderHeader.FieldCaption("Post Interest"), ReminderHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestTCalcInterestCPost()
    var
        ReminderLine: Record "Reminder Line";
        ReminderHeader: Record "Reminder Header";
        ReminderTermCode: Code[10];
        CustNo: Code[20];
        InvoiceA: Code[20];
        ReminderNo: Code[20];
    begin
        // [SCENARIO TFS=TFS=107048] When Reminder Terms is set up to Calculate interest and post it, the interest amount is shown on the reminder
        Initialize(false);

        // [GIVEN] A Reminder Term (N) with Calculate Interest = Yes and Post Interest = Yes
        // [GIVEN] A customer setup with Reminder Term N
        // [GIVEN] A Finance Charge Term (T) with 2% interest and with "Add. Line Fee in Interest" = TRUE
        CreateStandardReminderTermSetupWithCustAndFinChrg(CustNo, ReminderTermCode, false, true, true);

        // [GIVEN] A sales invoice (A) is posted for the customer
        // [GIVEN] The invoice due date + Reminder grace period < TODAY
        InvoiceA := PostSalesInvoice(CustNo, CalcDate('<-5D>', WorkDate()));

        // [WHEN] A reminder is created for the customer
        ReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, WorkDate());

        // [THEN] Invoice A is added to the reminder
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Customer Ledger Entry", ReminderLine."Document Type"::Invoice, InvoiceA);

        // [THEN] Interest is calculated for invoice A
        Assert.AreNotEqual(0.0, ReminderLine.Amount,
          StrSubstNo(MustNotMatchErr, ReminderLine.FieldCaption(Amount), ReminderLine.TableCaption()));

        // [THEN] The reminder header have Post Interest = Yes
        ReminderHeader.Get(ReminderNo);
        Assert.AreEqual(true, ReminderHeader."Post Interest",
          StrSubstNo(MustMatchErr, ReminderHeader.FieldCaption("Post Interest"), ReminderHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestSalesInvWithDynamicAddFee()
    var
        ReminderLine: Record "Reminder Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ReminderLevel: Record "Reminder Level";
        ReminderNo: Code[20];
        InvoiceA: Code[20];
        ReminderTermCode: Code[10];
        CustNo: Code[20];
    begin
        // [SCENARIO 107048] Additional fee is added to reminder when Single Dynamics calculation type is choosen and setup
        Initialize(false);

        // [GIVEN] A Reminder Term (N) that have CalculationType = Single Dynamic
        // [GIVEN] N applies 10% of the remaining amount as an Additional Fee on reminders
        // [GIVEN] A customer setup with Reminder Term N
        CreateStandardRmdTermSetupWithSingleDynCalc(ReminderTermCode, CustNo, 10);

        // [GIVEN] Additional Fee (LCY) on Reminder Level is 0
        ReminderLevel.Get(ReminderTermCode, 1);
        Assert.AreEqual(0, ReminderLevel."Additional Fee (LCY)",
          StrSubstNo(MustMatchErr, ReminderLevel.FieldCaption("Additional Fee (LCY)"), ReminderLevel.TableCaption()));

        // [GIVEN] A sales invoice (A) is posted for the customer
        // [GIVEN] The invoice due date + Reminder grace period < TODAY
        InvoiceA := PostSalesInvoice(CustNo, CalcDate('<-5D>', WorkDate()));
        FindOpenCustomerLedgerEntriesExclVAT(CustLedgerEntry, InvoiceA, CustNo);

        // [WHEN] A reminder is created for the customer
        ReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, WorkDate());

        // [THEN] Invoice A is added to the reminder
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Customer Ledger Entry", ReminderLine."Document Type"::Invoice, InvoiceA);

        // [THEN] Additional fee is added with 10% of InvoiceA
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"G/L Account", "Gen. Journal Document Type"::" ", '');
        Assert.AreNearlyEqual(CustLedgerEntry."Remaining Amount" * 0.1, ReminderLine.Amount, 1,
          StrSubstNo(MustMatchErr, ReminderLine.FieldCaption(Amount), ReminderLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateLineFeeSumOnReminder()
    var
        CustLedgEntryLineFeeOn: Record "Cust. Ledger Entry";
        ReminderLine: Record "Reminder Line";
        ReminderNo: Code[20];
        CustNo: Code[20];
        ReminderTermCode: Code[10];
        InvoiceA: Code[20];
        CreditMemoB: Code[20];
    begin
        // [SCENARIO 107048] Add. Line Fee is added to Credit Memo when selected on the Create Reminder request page
        Initialize(false);

        // [GIVEN] Reminder terms (R) set up without additional fee and with Line Fee = X, where X > 0 for level 1
        // [GIVEN] A customer with reminder terms R
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);

        // [GIVEN] An overdue Credit Memo for the customer
        MaxDocumentValue := 1000;
        CreditMemoB := PostCreditMemo(CustNo, CalcDate('<-14D>', WorkDate()));

        // [GIVEN] An overdue Invoice for the customer
        MinDocumentValue := 1001;
        MaxDocumentValue := 100000;
        InvoiceA := PostSalesInvoice(CustNo, CalcDate('<-10D>', WorkDate()));

        // [WHEN] A new reminder is created via the Create Reminders report for the customer with Document Type for Line Fee set to Credit Memo
        CustLedgEntryLineFeeOn.SetRange("Document Type", CustLedgEntryLineFeeOn."Document Type"::"Credit Memo");
        ReminderNo := RunCreateReminderReport(CustNo, WorkDate(), CustLedgEntryLineFeeOn);

        // [THEN] A reminder line is created for the Credit Memo
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Customer Ledger Entry", ReminderLine."Document Type"::"Credit Memo", CreditMemoB);

        // [THEN] Line Fee is added for the overdue Credit Memo
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee", ReminderLine."Document Type"::"Credit Memo", CreditMemoB);

        // [THEN] A reminder line is created for the Invoice
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Customer Ledger Entry", ReminderLine."Document Type"::Invoice, InvoiceA);

        // [THEN] Line Fee is NOT added for the overdue Invoice
        VerifyReminderLineDoesNotExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee", ReminderLine."Document Type"::Invoice, InvoiceA);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditChangeLineType()
    var
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        CustNo: Code[20];
        ReminderTermCode: Code[10];
    begin
        // [SCENARIO 107048] User can change the line type to "Line fee" on reminder lines
        Initialize(false);

        // [GIVEN] A reminder with an overdue Invoice
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);
        LibraryERM.CreateReminderHeader(ReminderHeader);
        ReminderHeader.Validate("Customer No.", CustNo);
        ReminderHeader.Validate("Posting Date", WorkDate());
        ReminderHeader.Validate("Document Date", WorkDate());
        ReminderHeader.Modify(true);

        // [GIVEN] User added a Reminder line
        ReminderLine.Init();
        ReminderLine.Validate("Reminder No.", ReminderHeader."No.");
        ReminderLine.Insert(true);

        // [GIVEN] User adds a description and Amount to the line
        ReminderLine.Description := 'A description';
        ReminderLine.Amount := 10;
        ReminderLine.Modify(true);

        // [WHEN] User tries to change the type of the Reminder Line to Line Fee
        ReminderLine.Validate(Type, ReminderLine.Type::"Line Fee");
        ReminderLine.Modify(true);

        // [THEN] The line type is changed
        // [THEN] All other fields on the line is cleared
        Assert.AreEqual(0, ReminderLine.Amount, StrSubstNo(MustMatchErr, ReminderLine.FieldCaption(Amount), ReminderLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditChangePostingDate()
    var
        ReminderLine: Record "Reminder Line";
        ReminderNo: Code[20];
    begin
        // [SCENARIO 107048] User is able to change the posting date to an arbitrary date
        Initialize(false);

        // [GIVEN] A reminder with an overdue Invoice and Line Fee for the invoice
        ReminderNo := CreateReminderWithOverdueInvoiceAndLineFee();

        // [WHEN] User tries to change the posting date to TODAY+2D for the Line Fee line
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee",
              ReminderLine."Document Type"::Invoice, '');
        ReminderLine.Validate("Posting Date", CalcDate('<+2D>', WorkDate()));
        ReminderLine.Modify(true);

        // [THEN] The date is saved
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditChangeDueDate()
    var
        ReminderLine: Record "Reminder Line";
        ReminderNo: Code[20];
    begin
        // [SCENARIO 107048] User is able to change the due date to an arbitrary date
        Initialize(false);

        // [GIVEN] A reminder with an overdue Invoice and Line Fee for the invoice
        ReminderNo := CreateReminderWithOverdueInvoiceAndLineFee();

        // [WHEN] User tries to change the Due date to TODAY+7D
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee",
              ReminderLine."Document Type"::Invoice, '');
        ReminderLine.Validate("Due Date", CalcDate('<+2D>', WorkDate()));
        ReminderLine.Modify(true);

        // [THEN] The date is saved
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditChangeAmount()
    var
        ReminderLine: Record "Reminder Line";
        ReminderNo: Code[20];
        AmountY: Decimal;
    begin
        // [SCENARIO 107048] User is able to change the amount of a Line Fee to any positive amount
        Initialize(false);

        // [GIVEN] A reminder with an overdue Invoice and Line Fee (X) for the invoice
        ReminderNo := CreateReminderWithOverdueInvoiceAndLineFee();

        // [WHEN] User tries to change the Amount to Y, where Y > 0 and Y != X
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee",
              ReminderLine."Document Type"::Invoice, '');
        AmountY := LibraryRandom.RandDecInRange(1, 100, 2);
        while AmountY = ReminderLine.Amount do
            AmountY := LibraryRandom.RandDecInRange(1, 100, 2);
        ReminderLine.Validate(Amount, AmountY);
        ReminderLine.Modify(true);

        // [THEN] The amount is changed to Y
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditChangeAmountNegative()
    var
        ReminderLine: Record "Reminder Line";
        ReminderNo: Code[20];
    begin
        // [SCENARIO 107048] User is able to change the amount of a Line Fee to any amount
        Initialize(false);

        // [GIVEN] A reminder with an overdue Invoice and Line Fee (X) for the invoice
        ReminderNo := CreateReminderWithOverdueInvoiceAndLineFee();

        // [WHEN] User tries to change the Amount to Y, where Y < 0 and Y != X
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee",
              ReminderLine."Document Type"::Invoice, '');
        asserterror ReminderLine.Validate(Amount, -LibraryRandom.RandDecInRange(1, 100, 2));

        // [THEN] An error is thrown saying the amount can't be negative
        Assert.ExpectedError(AmountMustBePositiveErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditChangeDescription()
    var
        ReminderLine: Record "Reminder Line";
        ReminderNo: Code[20];
    begin
        // [SCENARIO 107048] User is able to change the description of a Line Fee
        Initialize(false);

        // [GIVEN] A reminder with an overdue Invoice and Line Fee (X) for the invoice
        ReminderNo := CreateReminderWithOverdueInvoiceAndLineFee();

        // [WHEN] User tries to change the description of the Line Fee line
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee",
              ReminderLine."Document Type"::Invoice, '');
        ReminderLine.Validate(Description, 'Some description');
        ReminderLine.Modify(true);

        // [THEN] The description is saved
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditChangeGLAccount()
    var
        ReminderLine: Record "Reminder Line";
        GLAccount: Record "G/L Account";
        ReminderNo: Code[20];
        GLAccountNo: Code[20];
    begin
        // [SCENARIO 107048] User is able to change the G/L account for the Line Fee.
        Initialize(false);

        // [GIVEN] A reminder with an overdue Invoice and Line Fee (X) for the invoice
        ReminderNo := CreateReminderWithOverdueInvoiceAndLineFee();

        // [GIVEN] User added a new Reminder line of type Line Fee
        ReminderLine.Init();
        ReminderLine.Validate("Reminder No.", ReminderNo);
        ReminderLine.Validate(Type, ReminderLine.Type::"Line Fee");
        ReminderLine.Insert(true);

        // [GIVEN] There is no description on the line of type Line Fee
        ReminderLine.Validate(Description, '');
        ReminderLine.Modify(true);

        // [WHEN] User tries to change the G/L account for the Line Fee line
        GLAccountNo := FindGLAccountWithVAT('');
        GLAccount.Get(GLAccountNo);
        ReminderLine.Validate("No.", GLAccountNo);
        ReminderLine.Modify(true);

        // [THEN] The G/L account is saved
        // [THEN] The line description is changed to the name of the G/L account
        ReminderLine.Get(ReminderLine."Reminder No.", ReminderLine."Line No.");
        Assert.AreEqual(GLAccount.Name, ReminderLine.Description,
          StrSubstNo(MustMatchErr, ReminderLine.FieldCaption(Description), ReminderLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditChangeGLAccountExistingDesc()
    var
        ReminderLine: Record "Reminder Line";
        GLAccount: Record "G/L Account";
        ReminderNo: Code[20];
        GLAccountNo: Code[20];
        DescriptionText: Text[100];
    begin
        // [SCENARIO 107048] User is able to change the G/L account for the Line Fee. The description is not overwritten if exists.
        Initialize(false);

        // [GIVEN] A reminder with an overdue Invoice and Line Fee (X) for the invoice
        ReminderNo := CreateReminderWithOverdueInvoiceAndLineFee();

        // [GIVEN] User added a new Reminder line of type Line Fee
        ReminderLine.Init();
        ReminderLine.Validate("Reminder No.", ReminderNo);
        ReminderLine.Validate(Type, ReminderLine.Type::"Line Fee");
        ReminderLine.Insert(true);

        // [GIVEN] User added a description of the line
        DescriptionText := 'Some Description';
        ReminderLine.Validate(Description, DescriptionText);
        ReminderLine.Modify(true);

        // [WHEN] User tries to change the G/L account for the Line Fee line
        GLAccountNo := FindGLAccountWithVAT('');
        GLAccount.Get(GLAccountNo);
        ReminderLine.Validate("No.", GLAccountNo);
        ReminderLine.Modify(true);

        // [THEN] The G/L account is saved
        // [THEN] The line description is not changed
        ReminderLine.Get(ReminderLine."Reminder No.", ReminderLine."Line No.");
        Assert.AreEqual(DescriptionText, ReminderLine.Description,
          StrSubstNo(MustMatchErr, ReminderLine.FieldCaption(Description), ReminderLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditChangeAppliesTo()
    var
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        ReminderLevel: Record "Reminder Level";
        ReminderNo: Code[20];
        InvoiceA: Code[20];
    begin
        // [SCENARIO 107048] User is able to change the Applies To field for a Add. Line Fee on the Reminder
        Initialize(false);

        // [GIVEN] A reminder with an overdue Invoice and Line Fee (X) for the invoice created via Suggest Lines
        ReminderNo := CreateReminderWithOverdueInvoiceAndLineFee();
        ReminderHeader.Get(ReminderNo);

        // [GIVEN] The Reminder Term level has a description with document no. substituion
        ReminderLevel.Get(ReminderHeader."Reminder Terms Code", 1);
        ReminderLevel."Add. Fee per Line Description" := 'Line Fee %8';
        ReminderLevel.Modify(true);

        // [GIVEN] A overdue sales invoice exists
        InvoiceA := PostSalesInvoice(ReminderHeader."Customer No.", CalcDate('<-10D>', WorkDate()));

        // [WHEN] User tries to change the Applies To field to another overdue invoice that does not have a Line Fee applied to it
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee", ReminderLine."Document Type"::Invoice, '');
        ReminderLine.Validate("Applies-to Document Type", ReminderLine."Applies-to Document Type"::Invoice);
        ReminderLine.Validate("Applies-to Document No.", InvoiceA);
        ReminderLine.Modify(true);

        // [THEN] The change is accepted
        // [THEN] The line description is updated with the new Document No.
        Assert.AreEqual(
          StrSubstNo('Line Fee %1', InvoiceA), ReminderLine.Description,
          StrSubstNo(MustMatchErr, ReminderLine.FieldCaption(Description), ReminderLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditChangeAppliesToNotOverDue()
    var
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        ReminderNo: Code[20];
        InvoiceA: Code[20];
    begin
        // [SCENARIO 107048] User is not able to change the Applies To field to a invoice that is not overdue for a Add. Line Fee on the Reminder
        Initialize(false);

        // [GIVEN] A reminder with an overdue Invoice and Line Fee (X) for the invoice
        ReminderNo := CreateReminderWithOverdueInvoiceAndLineFee();
        ReminderHeader.Get(ReminderNo);

        // [GIVEN] An NOT overdue invoice for the same customer
        InvoiceA := PostSalesInvoice(ReminderHeader."Customer No.", CalcDate('<+10D>', WorkDate()));

        // [WHEN] User tries to change the Applies To field to another invoice that is not overdue
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee", ReminderLine."Document Type"::Invoice, '');
        ReminderLine.Validate("Applies-to Document Type", ReminderLine."Applies-to Document Type"::Invoice);
        asserterror ReminderLine.Validate("Applies-to Document No.", InvoiceA);

        // [THEN] An error is thrown
        Assert.ExpectedError(StrSubstNo('Document No. %1 in Cust. Ledger Entry is not overdue.', InvoiceA));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditChangeAppliesToNotSameCustomer()
    var
        ReminderLine: Record "Reminder Line";
        PaymentTermsCode: Code[10];
        ReminderTermCode: Code[10];
        InvoiceB: Code[20];
        CustNoA: Code[20];
        CustNoB: Code[20];
        ReminderNo: Code[20];
    begin
        // [SCENARIO 107048] User is not able to change the Applies To field to a invoice that does not belong to the customer for a Add. Line Fee on the Reminder
        Initialize(false);

        // [GIVEN] A reminder with an overdue Invoice and Line Fee (X) for the invoice
        PaymentTermsCode := CreatePaymentTerms(1);
        ReminderTermCode := CreateReminderTerms(true, false, false);
        CreateReminderTermsLevel(ReminderTermCode, 1, 1, '', 0, LibraryRandom.RandDecInRange(1, 100, 2), false, 1);
        CustNoA := CreateCustomerWithReminderAndPaymentTerms(ReminderTermCode, PaymentTermsCode);
        PostSalesInvoice(CustNoA, CalcDate('<-10D>', WorkDate()));
        ReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNoA, CalcDate('<-6D>', WorkDate()));

        // [GIVEN] A posted invoice (overdue) for another customer
        CustNoB := CreateCustomerWithReminderAndPaymentTerms(ReminderTermCode, PaymentTermsCode);
        InvoiceB := PostSalesInvoice(CustNoB, CalcDate('<-10D>', WorkDate()));

        // [WHEN] User tries to change the Applies To field to another invoice that does not belong to the customer of the Reminder
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee", ReminderLine."Document Type"::Invoice, '');
        ReminderLine.Validate("Applies-to Document Type", ReminderLine."Applies-to Document Type"::Invoice);
        asserterror ReminderLine.Validate("Applies-to Document No.", InvoiceB);

        // [THEN] An error is thrown
        Assert.ExpectedError(NoOpenEntriesErr);
    end;

    [Test]
    [HandlerFunctions('IssueRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure EditChangeAppliesToLevelAlreadyApplied()
    var
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        InvoiceA: Code[20];
        CustNo: Code[20];
        ReminderTermCode: Code[10];
    begin
        // [SCENARIO 107048] User is not able to issue Line Fee on same level for same invoice
        Initialize(false);

        // [GIVEN] A Reminder Term (R) is setup with Line Fee on level 1 with amount = X
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);

        // [GIVEN] An overdue sales invoice (I_a) for customer C
        InvoiceA := PostSalesInvoice(CustNo, CalcDate('<-10D>', WorkDate()));

        // [GIVEN] A reminder (R_1) is created for customer C with Reminder Term R without a reminder line for I_a
        CreateReminderHeader(ReminderHeader, CustNo, WorkDate());

        // [GIVEN] A Reminder Line with type Line Fee is added for invoice I_a with amount X
        CreateReminderLineOfTypeLineFee(ReminderLine, ReminderHeader."No.", ReminderLine."Applies-to Document Type"::Invoice, InvoiceA);

        // [GIVEN] Reminder R_1 is issued
        IssueReminder(ReminderHeader."No.", 0, false);

        // [GIVEN] A reminder (R_2) is created for customer C without lines
        CreateReminderHeader(ReminderHeader, CustNo, WorkDate());

        // [GIVEN] A Reminder Line of type Line Fee is added to R_2
        // [WHEN] The user attempts to apply the Line Fee to invoice I_A
        ReminderLine.Init();
        ReminderLine.Validate("Reminder No.", ReminderHeader."No.");
        ReminderLine.Validate(Type, ReminderLine.Type::"Line Fee");
        ReminderLine.Insert(true);
        ReminderLine.Validate("Applies-to Document Type", ReminderLine."Applies-to Document Type"::Invoice);
        asserterror ReminderLine.Validate("Applies-to Document No.", InvoiceA);

        // [THEN] An error is thrown that level 1 Line Fee already have been issued for invoice I_a
        Assert.ExpectedError(StrSubstNo(LineFeeAlreadyAppliedErr, ReminderLine."Applies-to Document Type"::Invoice, InvoiceA, 1))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditChangeAppliesToLevelDoesNotExists()
    var
        ReminderLine: Record "Reminder Line";
        GLAccount: Record "G/L Account";
        ReminderNo: Code[20];
    begin
        // [SCENARIO 107048] User is able to change Apply-to to a Reminder Term Level that does not exists
        Initialize(false);

        // [GIVEN] A reminder term (R) with Line Fee on level 1. Level 2 does NOT exists
        // [GIVEN] An overdue invoice I_A for customer C
        // [GIVEN] A reminder (R_1) with an overdue Invoice (I_a) and Line Fee (X) for the invoice
        ReminderNo := CreateReminderWithOverdueInvoiceAndLineFee();

        // [WHEN] User tries to change the "No. of Reminders" to 2 for the Line Fee line for invoice I_A
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee", ReminderLine."Document Type"::Invoice, '');
        ReminderLine.Validate("No. of Reminders", 2);

        // [THEN] The description of the Reminder Line is set to that of the G/L account.
        GLAccount.Get(ReminderLine."No.");
        Assert.AreEqual(
          GLAccount.Name, ReminderLine.Description,
          StrSubstNo(MustMatchErr, ReminderLine.FieldCaption(Description), ReminderLine.TableCaption()));

        // [THEN] The amount of the Reminder Line is set to zero
        Assert.AreEqual(0, ReminderLine.Amount, StrSubstNo(MustMatchErr, ReminderLine.FieldCaption(Amount), ReminderLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditChangeAppliesToLevelDoesNotExistsNoGLAcc()
    var
        ReminderLine: Record "Reminder Line";
        ReminderNo: Code[20];
    begin
        // [SCENARIO 107048] User is able to change Apply-to to a Reminder Term Level that does not exists. No G/L account selected
        Initialize(false);

        // [GIVEN] A reminder term (R) with Line Fee on level 1. Level 2 does NOT exists
        // [GIVEN] An overdue invoice I_A for customer C
        // [GIVEN] A reminder (R_1) with an overdue Invoice (I_a) and Line Fee (X) for the invoice
        ReminderNo := CreateReminderWithOverdueInvoiceAndLineFee();

        // [GIVEN] No G/L account is setup for the Line Fee Line
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee", ReminderLine."Document Type"::Invoice, '');
        ReminderLine.Validate("No.", '');
        ReminderLine.Modify(true);

        // [WHEN] User tries to change the "No. of Reminders" to 2 for the Line Fee line for invoice I_A
        ReminderLine.Validate("No. of Reminders", 2);

        // [THEN] The description of the Reminder Line is cleared
        Assert.AreEqual(
          '', ReminderLine.Description, StrSubstNo(MustMatchErr, ReminderLine.FieldCaption(Description), ReminderLine.TableCaption()));

        // [THEN] The amount of the Reminder Line is set to zero
        Assert.AreEqual(0, ReminderLine.Amount, StrSubstNo(MustMatchErr, ReminderLine.FieldCaption(Amount), ReminderLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditChangeAppliesToLevelWithoutLineFee()
    var
        ReminderLine: Record "Reminder Line";
        GLAccount: Record "G/L Account";
        ReminderNo: Code[20];
        ReminderTermCode: Code[10];
        CustNo: Code[20];
    begin
        // [SCENARIO 107048] User is able to change Apply-to to a Reminder Term Level that does not have a Line Fee
        Initialize(false);

        // [GIVEN] A reminder term (R) with Line Fee on level 1.
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);

        // [GIVEN] Reminder Term R has a level 2, with a Line Fee description but Line Fee Amount = 0
        CreateReminderTermsLevel(ReminderTermCode, 5, 5, '', 0, 0, false, 2);

        // [GIVEN] A reminder with an overdue Invoice (I_a) and Line Fee (X) for the invoice
        PostSalesInvoice(CustNo, CalcDate('<-10D>', WorkDate()));
        ReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, WorkDate());

        // [WHEN] User tries to change the "No. of Reminders" to 2 for the Line Fee line for invoice I_A
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee", ReminderLine."Document Type"::Invoice, '');
        ReminderLine.Validate("No. of Reminders", 2);

        // [THEN] The description of the Reminder Line is set to that of the G/L account.
        GLAccount.Get(ReminderLine."No.");
        Assert.AreEqual(
          GLAccount.Name, ReminderLine.Description,
          StrSubstNo(MustMatchErr, ReminderLine.FieldCaption(Description), ReminderLine.TableCaption()));

        // [THEN] The amount of the Reminder Line is set to zero
        Assert.AreEqual(0, ReminderLine.Amount, StrSubstNo(MustMatchErr, ReminderLine.FieldCaption(Amount), ReminderLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditDeleteLineFeeLine()
    var
        ReminderLine: Record "Reminder Line";
        ReminderNo: Code[20];
    begin
        // [SCENARIO 107048] User is able to delete a suggested line of Line Fee
        Initialize(false);

        // [GIVEN] A reminder with an overdue Invoice and Line Fee (X) for the invoice
        ReminderNo := CreateReminderWithOverdueInvoiceAndLineFee();

        // [WHEN] User attempts to delete the Line Fee line
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee", ReminderLine."Document Type"::Invoice, '');
        ReminderLine.Delete(true);

        // [THEN] The line is deleted
        VerifyReminderLineDoesNotExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee", ReminderLine."Document Type"::Invoice, '');
    end;

    [Test]
    [HandlerFunctions('IssueRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Issue1stRmdSingleInvoiceNoFee()
    var
        ReminderLevel: Record "Reminder Level";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        IssuedReminderLine: Record "Issued Reminder Line";
        CustNo: Code[20];
        ReminderTermCode: Code[10];
        InvoiceA: Code[20];
        ReminderNo: Code[20];
        IssuedReminderNo: Code[20];
        LineFeeX: Decimal;
    begin
        // [SCENARIO 107048] 1st reminder for single invoice with line fee: A single Cust. Ledg Entry is posted for the reminder
        Initialize(false);

        // [GIVEN] The Reminder Term R is set to Posted Line Fee = Yes
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);
        ReminderLevel.Get(ReminderTermCode, 1);
        LineFeeX := ReminderLevel."Add. Fee per Line Amount (LCY)";

        // [GIVEN] A reminder with Reminder Term R with a overdue sales invoice and a Line Fee X
        InvoiceA := PostSalesInvoice(CustNo, CalcDate('<-10D>', WorkDate()));
        ReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, WorkDate());

        // [GIVEN] No additional fee or interest on the reminder
        // [WHEN] The Reminder is issued
        IssuedReminderNo := IssueReminder(ReminderNo, 0, false);

        // [THEN] A Customer Ledger Entry is posted with amount = X
        FindOpenCustomerLedgerEntriesExclVAT(CustLedgerEntry, IssuedReminderNo, CustNo);
        Assert.AreNearlyEqual(LineFeeX, CustLedgerEntry.Amount, 1,
          StrSubstNo(MustMatchErr, CustLedgerEntry.FieldCaption(Amount), CustLedgerEntry.TableCaption()));

        // [THEN] The Applies-to Doc is saved in the Issued Reminder Line table
        IssuedReminderLine.SetRange("Reminder No.", IssuedReminderNo);
        IssuedReminderLine.SetRange(Type, IssuedReminderLine.Type::"Line Fee");
        IssuedReminderLine.FindFirst();
        Assert.AreEqual(InvoiceA, IssuedReminderLine."Applies-To Document No.",
          StrSubstNo(MustMatchErr, IssuedReminderLine.FieldCaption("Applies-To Document No."), IssuedReminderLine.TableCaption()));
        Assert.AreEqual(IssuedReminderLine."Applies-To Document Type"::Invoice, IssuedReminderLine."Applies-To Document Type",
          StrSubstNo(MustMatchErr, IssuedReminderLine.FieldCaption("Applies-To Document Type"), IssuedReminderLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('IssueRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Issue1stRmdSingleInvoiceNoFeeNoPost()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ReminderTerms: Record "Reminder Terms";
        IssuedReminderHeader: Record "Issued Reminder Header";
        CustNo: Code[20];
        ReminderTermCode: Code[10];
        ReminderNo: Code[20];
        IssuedReminderNo: Code[20];
    begin
        // [SCENARIO 107048] 1st reminder for single invoice with line fee with Reminder Terms says not to post line fees: Nothing it posted
        Initialize(false);

        // [GIVEN] The Reminder Term R is set to Posted Line Fee = No
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);
        ReminderTerms.Get(ReminderTermCode);
        ReminderTerms.Validate("Post Add. Fee per Line", false);
        ReminderTerms.Validate("Post Additional Fee", false);
        ReminderTerms.Modify(true);

        // [GIVEN] A reminder with Reminder Term R with a over due sales invoice and a Line Fee X
        PostSalesInvoice(CustNo, CalcDate('<-10D>', WorkDate()));
        ReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, WorkDate());

        // [GIVEN] No additional fee or interest on the reminder
        // [WHEN] The Reminder is issued
        IssuedReminderNo := IssueReminder(ReminderNo, 0, false);

        // [THEN] The Reminder document is posted
        IssuedReminderHeader.Get(IssuedReminderNo);

        // [THEN] No customer ledger entries are created
        asserterror FindOpenCustomerLedgerEntriesExclVAT(CustLedgerEntry, IssuedReminderNo, CustNo);
        Assert.ExpectedErrorCode('DB:NothingInsideFilter');
    end;

    [Test]
    [HandlerFunctions('IssueRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Issue1stRmdMultipleInvoiceNoFee()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ReminderLevel: Record "Reminder Level";
        CustNo: Code[20];
        ReminderTermCode: Code[10];
        LineFeeX: Decimal;
        ReminderNo: Code[20];
        IssuedReminderNo: Code[20];
    begin
        // [SCENARIO 107048] 1st reminder for multiple invoice with line fees
        Initialize(false);

        // [GIVEN] Customer C with Reminder Term R with Line Fee X
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);
        ReminderLevel.Get(ReminderTermCode, 1);
        LineFeeX := ReminderLevel."Add. Fee per Line Amount (LCY)";

        // [GIVEN] A reminder with 3 overdue sales invoices and a Line Fees for all invoices (X_1, X_2 and X_3)
        PostSalesInvoice(CustNo, CalcDate('<-12D>', WorkDate()));
        PostSalesInvoice(CustNo, CalcDate('<-11D>', WorkDate()));
        PostSalesInvoice(CustNo, CalcDate('<-10D>', WorkDate()));
        ReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, WorkDate());

        // [GIVEN] No additional fee or interest on the reminder
        // [WHEN] The Reminder is issued
        IssuedReminderNo := IssueReminder(ReminderNo, 0, false);

        // [THEN] A Customer Ledger Entry is posted with amount = X_1+X_2+X_3
        FindOpenCustomerLedgerEntriesExclVAT(CustLedgerEntry, IssuedReminderNo, CustNo);
        Assert.AreNearlyEqual(LineFeeX * 3, CustLedgerEntry.Amount, 1,
          StrSubstNo(MustMatchErr, CustLedgerEntry.FieldCaption(Amount), CustLedgerEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('IssueRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Issue1stRmdMultipleInvoiceMixedLineFees()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ReminderLevel: Record "Reminder Level";
        ReminderLine: Record "Reminder Line";
        CustNo: Code[20];
        ReminderTermCode: Code[10];
        LineFeeX: Decimal;
        ReminderNo: Code[20];
        IssuedReminderNo: Code[20];
        InvoiceA: Code[20];
    begin
        // [SCENARIO 107048] Reminder with multiple invoices, some with line fees
        Initialize(false);

        // [GIVEN] Customer C with Reminder Term R with Line Fee X
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);
        ReminderLevel.Get(ReminderTermCode, 1);
        LineFeeX := ReminderLevel."Add. Fee per Line Amount (LCY)";

        // [GIVEN] A reminder with 3 overdue sales invoices and a Line Fees on two of them (X_1 and X_2)
        PostSalesInvoice(CustNo, CalcDate('<-12D>', WorkDate()));
        PostSalesInvoice(CustNo, CalcDate('<-11D>', WorkDate()));
        InvoiceA := PostSalesInvoice(CustNo, CalcDate('<-10D>', WorkDate()));
        ReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, WorkDate());
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee", ReminderLine."Document Type"::Invoice, InvoiceA);
        ReminderLine.Delete(true);

        // [GIVEN] No additional fee or interest on the reminder
        // [WHEN] The Reminder is issued
        IssuedReminderNo := IssueReminder(ReminderNo, 0, false);

        // [THEN] A Customer Ledger Entry is posted with amount = X_1+X_2
        FindOpenCustomerLedgerEntriesExclVAT(CustLedgerEntry, IssuedReminderNo, CustNo);
        Assert.AreNearlyEqual(LineFeeX * 2, CustLedgerEntry.Amount, 1,
          StrSubstNo(MustMatchErr, CustLedgerEntry.FieldCaption(Amount), CustLedgerEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('IssueRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Issue1stRmdSingleInvoiceWithFee()
    var
        ReminderTerms: Record "Reminder Terms";
        ReminderLevel: Record "Reminder Level";
        CustomerPostingGroup: Record "Customer Posting Group";
        GLEntry: Record "G/L Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        GLAccountA: Code[20];
        GLAccountB: Code[20];
        CustNo: Code[20];
        ReminderTermCode: Code[10];
        ReminderNo: Code[20];
        IssuedReminderNo: Code[20];
        AmountY: Decimal;
        LineFeeX: Decimal;
    begin
        // [SCENARIO 107048] 1st reminder for single invoice with Add. Line Fee and a fee on the reminder: The fee is posted to a seperate G/L account than the line fee.
        Initialize(false);

        // [GIVEN] A reminder with 2 overdue sales invoices and a Line Fee for all the invoices (X_1 and X_2)
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);
        PostSalesInvoice(CustNo, CalcDate('<-12D>', WorkDate()));
        PostSalesInvoice(CustNo, CalcDate('<-11D>', WorkDate()));
        Customer.Get(CustNo);

        // [GIVEN] Customer Posting Group have G/L account A for Additional fees and G/L account B for Line Fees without VAT
        FindTwoGLAccounts(GLAccountA, GLAccountB, Customer."VAT Bus. Posting Group");
        CustomerPostingGroup.ModifyAll("Additional Fee Account", GLAccountA);
        CustomerPostingGroup.ModifyAll("Add. Fee per Line Account", GLAccountB);

        // [GIVEN] The reminder has an additional fee of Y
        ReminderLevel.Get(ReminderTermCode, 1);
        ReminderLevel.Validate("Additional Fee (LCY)", LibraryRandom.RandDecInRange(1, 100, 2));
        ReminderLevel.Modify(true);
        ReminderTerms.Get(ReminderTermCode);
        ReminderTerms.Validate("Post Additional Fee", true);
        ReminderTerms.Modify(true);
        ReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, WorkDate());

        // [WHEN] The Reminder is issued
        IssuedReminderNo := IssueReminder(ReminderNo, 0, false);

        AmountY := ReminderLevel."Additional Fee (LCY)";
        LineFeeX := ReminderLevel."Add. Fee per Line Amount (LCY)";

        // [THEN] The reminder is posted to Customer Ledger Entries with amount Y+X_1+X_2
        FindOpenCustomerLedgerEntriesExclVAT(CustLedgerEntry, IssuedReminderNo, CustNo);
        Assert.AreNearlyEqual(LineFeeX * 2 + AmountY, CustLedgerEntry.Amount, 1,
          StrSubstNo(MustMatchErr, CustLedgerEntry.FieldCaption(Amount), CustLedgerEntry.TableCaption()));

        // [THEN] A G/L entry is posted to G/L account A with amount Y
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::Reminder);
        GLEntry.SetRange("Document No.", IssuedReminderNo);
        GLEntry.SetRange("G/L Account No.", GLAccountA);
        GLEntry.FindFirst();
        Assert.AreNearlyEqual(-AmountY, GLEntry.Amount, 1,
          StrSubstNo(MustMatchErr, GLEntry.FieldCaption(Amount), GLEntry.TableCaption()));

        // [THEN] Two G/L entry is posted to G/L account B with amount X_1+X_2
        GLEntry.SetRange("G/L Account No.", GLAccountB);
        GLEntry.FindSet();
        repeat
            Assert.AreNearlyEqual(-LineFeeX, GLEntry.Amount, 1,
              StrSubstNo(MustMatchErr, GLEntry.FieldCaption(Amount), GLEntry.TableCaption()));
        until GLEntry.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('IssueRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Issue2ndRmdSingleInvoiceWithNewLineFee()
    var
        ReminderLine: Record "Reminder Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustNo: Code[20];
        ReminderTermCode: Code[10];
        AmountY: Decimal;
        ReminderNo: Code[20];
        SecondReminderNo: Code[20];
        SecondIssuedReminderNo: Code[20];
        InvoiceA: Code[20];
    begin
        // [SCENARIO 107048] 2nd reminder for an invoice, where line fee is issued only on the second reminder
        Initialize(false);

        // [GIVEN] Reminder Term T for level 1 has Line Fee amount = X, where X > 0
        // [GIVEN] The customer C uses a Reminder term T
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);

        // [GIVEN] Reminder Term T for level 2 has Line Fee amount = Y, where Y > 0
        AmountY := LibraryRandom.RandDecInRange(1, 100, 2);
        CreateReminderTermsLevel(ReminderTermCode, 3, 3, '', 0, AmountY, false, 2);

        // [GIVEN] An overdue invoice (I_a) for customer (C)
        InvoiceA := PostSalesInvoice(CustNo, CalcDate('<-10D>', WorkDate()));

        // [GIVEN] The 1st reminder (R_1) is issued for invoice I_a, but the user deleted the Line Fee before issuing it
        ReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, CalcDate('<-5D>', WorkDate()));
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee", ReminderLine."Document Type"::Invoice, InvoiceA);
        ReminderLine.Delete(true);
        IssueReminder(ReminderNo, 0, false);

        // [GIVEN] A 2nd reminder (R_2) is created for invoice I_a and Line Fee of Y is suggested for the invoice
        SecondReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, WorkDate());

        // [GIVEN] The reminder does not have additional fee or interests
        // [WHEN] The reminder is issued
        SecondIssuedReminderNo := IssueReminder(SecondReminderNo, 0, false);

        // [THEN] A Customer Ledger Entry is posted for the Reminder R_2 with amount = Y
        FindOpenCustomerLedgerEntriesExclVAT(CustLedgerEntry, SecondIssuedReminderNo, CustNo);
        Assert.AreNearlyEqual(AmountY, CustLedgerEntry.Amount, 1,
          StrSubstNo(MustMatchErr, CustLedgerEntry.FieldCaption(Amount), CustLedgerEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('IssueRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IssueValidateAmount()
    var
        ReminderLine: Record "Reminder Line";
        ReminderNo: Code[20];
    begin
        // [SCENARIO 107048] An empty amount for the Add. Line Fee throws an error
        Initialize(false);

        // [GIVEN] A reminder with an overdue sales invoice and a Line Fee
        ReminderNo := CreateReminderWithOverdueInvoiceAndLineFee();

        // [GIVEN] The user sets the Line Fee Amount to 0
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee", ReminderLine."Document Type"::Invoice, '');
        ReminderLine.Validate(Amount, 0);
        ReminderLine.Modify(true);

        // [WHEN] The Reminder is issued
        asserterror IssueReminder(ReminderNo, 0, false);

        // [THEN] An error is thrown indicating an error with the Line Fee Amount
        Assert.ExpectedError(
          StrSubstNo(LineFeeAmountErr, ReminderLine."Applies-to Document Type", ReminderLine."Applies-to Document No."));
    end;

    [Test]
    [HandlerFunctions('IssueRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IssueValidateAmountNegative()
    var
        ReminderLine: Record "Reminder Line";
        ReminderNo: Code[20];
    begin
        // [SCENARIO 107048] A negative amount for the Add. Line Fee throws an error
        Initialize(false);

        // [GIVEN] A reminder with an overdue sales invoice and a Line Fee
        ReminderNo := CreateReminderWithOverdueInvoiceAndLineFee();

        // [GIVEN] The user sets the Line Fee Amount to X, where X < 0
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee", ReminderLine."Document Type"::Invoice, '');
        ReminderLine.Amount := -LibraryRandom.RandDecInRange(1, 100, 2);
        ReminderLine.Modify(true);

        // [WHEN] The Reminder is issued
        asserterror IssueReminder(ReminderNo, 0, false);

        // [THEN] An error is thrown indicating an error with the Line Fee Amount
        Assert.ExpectedError(
          StrSubstNo(LineFeeAmountErr, ReminderLine."Applies-to Document Type", ReminderLine."Applies-to Document No."));
    end;

    [Test]
    [HandlerFunctions('IssueRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IssueValidateGLAccount()
    var
        ReminderLine: Record "Reminder Line";
        ReminderNo: Code[20];
    begin
        // [SCENARIO 107048] An empty G/L account throws an error
        Initialize(false);

        // [GIVEN] A reminder with a over due sales invoice and a Line Fee
        ReminderNo := CreateReminderWithOverdueInvoiceAndLineFee();

        // [GIVEN] The user removes the G/L account for the Line Fee line
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee", ReminderLine."Document Type"::Invoice, '');
        ReminderLine.Validate("No.", '');
        ReminderLine.Modify(true);

        // [WHEN] The Reminder is issued
        asserterror IssueReminder(ReminderNo, 0, false);

        // [THEN] An error is thrown indicating an error with the G/L account
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    [HandlerFunctions('IssueRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IssueValidateAppliesToEmpty()
    var
        ReminderLine: Record "Reminder Line";
        ReminderNo: Code[20];
    begin
        // [SCENARIO 107048] Line Fee throws an error when Applies-To is empty
        Initialize(false);

        // [GIVEN] A reminder with a over due sales invoice and a Line Fee
        ReminderNo := CreateReminderWithOverdueInvoiceAndLineFee();

        // [GIVEN] The user clears the Applies To for the Line Fee
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee", ReminderLine."Document Type"::Invoice, '');
        ReminderLine.Validate("Applies-to Document No.", '');
        ReminderLine.Modify(true);

        // [WHEN] The Reminder is issued
        asserterror IssueReminder(ReminderNo, 0, false);

        // [THEN] An error is thrown indicating that an Applies-to Document has to be set
        Assert.ExpectedError(AppliesToDocErr);
    end;

    [Test]
    [HandlerFunctions('IssueRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IssueValidateAppliesToNotOverDue()
    var
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ReminderNo: Code[20];
        InvoiceA: Code[20];
    begin
        // [SCENARIO 107048] Line Fee Applies To throws an error when the Apply To Invoice is not overdue
        Initialize(false);

        // [GIVEN] A reminder with a over due sales invoice and a Line Fee
        ReminderNo := CreateReminderWithOverdueInvoiceAndLineFee();
        ReminderHeader.Get(ReminderNo);

        // [GIVEN] An invoice that is NOT overdue
        InvoiceA := PostSalesInvoice(ReminderHeader."Customer No.", WorkDate());

        // [GIVEN] The user changes the Applies To for the Line Fee to a Invoice that is not overdue
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee", ReminderLine."Document Type"::Invoice, '');
        ReminderLine."Applies-to Document No." := InvoiceA;
        ReminderLine.Modify(true);

        // [WHEN] The Reminder is issued
        asserterror IssueReminder(ReminderNo, 0, false);

        // [THEN] An error is thrown indicating that the invoice have to be overdue
        Assert.ExpectedError(StrSubstNo(EntryNotOverdueErr,
            ReminderLine.FieldCaption("Document No."), InvoiceA, CustLedgerEntry.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('IssueRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IssueValidateAppliesToAnotherCustomer()
    var
        ReminderLine: Record "Reminder Line";
        PaymentTermsCode: Code[10];
        ReminderTermCode: Code[10];
        CustNoN: Code[20];
        CustNoM: Code[20];
        InvoiceA: Code[20];
        InvoiceB: Code[20];
        ReminderNo: Code[20];
    begin
        // [SCENARIO 107048] Line Fee Applies To throws an error when the Apply To Invoice belongs to another customer
        Initialize(false);

        // A Reminder Term (M) with Line Fee setup
        PaymentTermsCode := CreatePaymentTerms(1);
        ReminderTermCode := CreateReminderTerms(true, false, false);
        CreateReminderTermsLevel(ReminderTermCode, 1, 1, '', 0, LibraryRandom.RandDecInRange(1, 100, 2), false, 1);

        // [GIVEN] Two customers N and M
        CustNoN := CreateCustomerWithReminderAndPaymentTerms(ReminderTermCode, PaymentTermsCode);
        CustNoM := CreateCustomerWithReminderAndPaymentTerms(ReminderTermCode, PaymentTermsCode);

        // [GIVEN] A invoice I_a that is overdue for customer N
        InvoiceA := PostSalesInvoice(CustNoN, CalcDate('<-10D>', WorkDate()));

        // [GIVEN] A invoice I_b that is overdue for customer M
        InvoiceB := PostSalesInvoice(CustNoM, CalcDate('<-10D>', WorkDate()));

        // [GIVEN] A reminder with a overdue sales invoice I_b and a Line Fee for customer M
        ReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNoM, WorkDate());

        // [GIVEN] The user is able to overwrite, and changes the Applies To for the Line Fee to a Invoice I_a
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee", ReminderLine."Document Type"::Invoice, InvoiceB);
        ReminderLine."Applies-to Document No." := InvoiceA;
        ReminderLine.Modify(true);

        // [WHEN] The Reminder is issued
        asserterror IssueReminder(ReminderNo, 0, false);

        // [THEN] An error is thrown indicating that the invoice does not belong to the customer
        Assert.ExpectedErrorCode('DB:NothingInsideFilter');
    end;

    [Test]
    [HandlerFunctions('IssueRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IssueValidateAppliesToMultipleFees()
    var
        ReminderLine: Record "Reminder Line";
        ReminderLine2: Record "Reminder Line";
        ReminderNo: Code[20];
    begin
        // [SCENARIO 107048] Line Fee Applies To throws an error when trying to apply multiple line fees to same document on same reminder
        Initialize(false);

        // [GIVEN] A reminder with a over due sales invoice and a Line Fee
        ReminderNo := CreateReminderWithOverdueInvoiceAndLineFee();

        // [GIVEN] The user changes the Applies To for the Line Fee to a Invoice that is not overdue
        VerifyReminderLineExists(ReminderLine, ReminderNo, ReminderLine.Type::"Line Fee", ReminderLine."Document Type"::Invoice, '');
        ReminderLine2.Init();
        ReminderLine2.Validate("Reminder No.", ReminderNo);
        ReminderLine2.Validate(Type, ReminderLine.Type::"Line Fee");
        ReminderLine2.Insert(true);

        ReminderLine2.Validate("Applies-to Document Type", ReminderLine."Applies-to Document Type"::Invoice);
        ReminderLine2.Validate("Applies-to Document No.", ReminderLine."Applies-to Document No.");
        ReminderLine2.Modify(true);

        // [WHEN] The Reminder is issued
        asserterror IssueReminder(ReminderNo, 0, false);

        // [THEN] An error is thrown indicating that the invoice have to be overdue
        Assert.ExpectedError(
          StrSubstNo(MultipleLineFeesSameDocErr, ReminderLine."Applies-to Document Type", ReminderLine."Applies-to Document No."));
    end;

    [Test]
    [HandlerFunctions('IssueRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IssueVATOnLineFee()
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        VATEntry: Record "VAT Entry";
        ReminderLevel: Record "Reminder Level";
        GLAccount: Record "G/L Account";
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        GLAccountNo: Code[20];
        CustNo: Code[20];
        ReminderTermCode: Code[10];
        ReminderNo: Code[20];
        IssuedReminderNo: Code[20];
    begin
        // [SCENARIO 107048] A Line Fee posted on a G/L account with VAT set up, creates VAT entries when issued

        // [GIVEN] A Reminder Term (R) without additional fee and Line Fee = X, where X > 0 for level 1
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);
        ReminderLevel.Get(ReminderTermCode, 1);
        UpdateCustomerVATRegNo(CustNo);

        // [GIVEN] G/L Account (M) is created with VAT set up with a non-zero VAT percentage (Z)
        Customer.Get(CustNo);
        GLAccountNo := FindGLAccountWithVAT(Customer."VAT Bus. Posting Group");
        GLAccount.Get(GLAccountNo);
        VATPostingSetup.Get(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");

        // [GIVEN] M is set as default for Line Fee in Customer Posting Group
        CustomerPostingGroup.ModifyAll("Add. Fee per Line Account", GLAccountNo);

        // [GIVEN] A reminder with a overdue sales invoice and a Line Fee (X) to G/L account M
        PostSalesInvoice(CustNo, CalcDate('<-10D>', WorkDate()));
        ReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, CalcDate('<-6D>', WorkDate()));

        // [WHEN] The Reminder is issued
        IssuedReminderNo := IssueReminder(ReminderNo, 0, false);

        // [THEN] A VAT entry is created for the Line Fee with amount = Y*Z/100 and base = Y
        // [THEN] VAT Registration No. is filled in value taken from Customer (TFS 276034)
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Reminder);
        VATEntry.SetRange("Document No.", IssuedReminderNo);
        VATEntry.FindFirst();
        Assert.AreNearlyEqual(-ReminderLevel."Add. Fee per Line Amount (LCY)", VATEntry.Base, 0.02,
          StrSubstNo(MustMatchErr, VATEntry.FieldCaption(Base), VATEntry.TableCaption()));
        Assert.AreNearlyEqual(-ReminderLevel."Add. Fee per Line Amount (LCY)" * VATPostingSetup."VAT %" / 100, VATEntry.Amount, 0.02,
          StrSubstNo(MustMatchErr, VATEntry.FieldCaption(Amount), VATEntry.TableCaption()));
        VATEntry.TestField("VAT Registration No.", Customer."VAT Registration No.");
    end;

    [Test]
    [HandlerFunctions('IssueRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostNoInterestOnLineFeeFinCharge()
    var
        ReminderLevel: Record "Reminder Level";
        FinanceChrgMemoLine: Record "Finance Charge Memo Line";
        Customer: Record Customer;
        CustNo: Code[20];
        ReminderTermCode: Code[10];
        FinanceChrgTermCode: Code[10];
        ReminderNo: Code[20];
        IssuedReminderNo: Code[20];
        FinanceChrgNo: Code[20];
        AmountZ: Decimal;
    begin
        // [SCENARIO 107048] Post process: Interest is not applied to Line Fees on Reminders, only to Additional fees when "Add. Line Fee in Interest" = FALSE
        Initialize(false);

        // [GIVEN] A reminder term (R) with Line Fee set up for level 1 and additional fee Z
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);
        ReminderLevel.Get(ReminderTermCode, 1);
        AmountZ := LibraryRandom.RandDecInRange(1, 100, 2);
        ReminderLevel.Validate("Additional Fee (LCY)", AmountZ);
        ReminderLevel.Modify(true);

        // [GIVEN] A Finance Charge Term (T) with 2% interest and "Add. Line Fee in Interest" = FALSE
        FinanceChrgTermCode := CreateFinChrgTerms(2, 0, 5, true, false, false);
        Customer.Get(CustNo);
        Customer.Validate("Fin. Charge Terms Code", FinanceChrgTermCode);
        Customer.Modify(true);

        // [GIVEN] An Issued Reminder (IR_1) with reminder for Invoice I_a and Line Fee X for I_a
        PostSalesInvoice(CustNo, CalcDate('<-30D>', WorkDate()));
        ReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, CalcDate('<-20D>', WorkDate()));
        IssuedReminderNo := IssueReminder(ReminderNo, 0, false);

        // [GIVEN] IR_1 is overdue
        // [WHEN] A Finance Charge is created and lines are suggested (i.e. interest rate is calculated)
        FinanceChrgNo := CreateFinChrgAndSuggestLines(CustNo, WorkDate());

        // [THEN] The interest is calculated only on Z
        FinanceChrgMemoLine.SetRange("Finance Charge Memo No.", FinanceChrgNo);
        FinanceChrgMemoLine.SetRange("Document Type", FinanceChrgMemoLine."Document Type"::Reminder);
        FinanceChrgMemoLine.SetRange("Document No.", IssuedReminderNo);
        FinanceChrgMemoLine.FindFirst();
        Assert.AreNearlyEqual(AmountZ * 0.02 / 30 * 20, FinanceChrgMemoLine.Amount, 1,
          StrSubstNo(MustMatchErr, FinanceChrgMemoLine.FieldCaption(Amount), FinanceChrgMemoLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('IssueRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostNoInterestOnLineFeeFinChargeNoAddFee()
    var
        FinanceChrgMemoLine: Record "Finance Charge Memo Line";
        Customer: Record Customer;
        CustNo: Code[20];
        ReminderTermCode: Code[10];
        FinanceChrgTermCode: Code[10];
        ReminderNo: Code[20];
        IssuedReminderNo: Code[20];
        FinanceChrgNo: Code[20];
    begin
        // [SCENARIO 107048] Post process: Interest is not applied to Line Fees on Reminders when "Add. Line Fee in Interest" = FALSE
        Initialize(false);

        // [GIVEN] A reminder term (R) with Line Fee set up for level 1 and NO additional fee
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);

        // [GIVEN] A Finance Charge Term (T) with 2% interest and "Add. Line Fee in Interest" = FALSE
        FinanceChrgTermCode := CreateFinChrgTerms(2, 0, 5, true, false, false);
        Customer.Get(CustNo);
        Customer.Validate("Fin. Charge Terms Code", FinanceChrgTermCode);
        Customer.Modify(true);

        // [GIVEN] An Issued Reminder (IR_1) with reminder for Invoice I_a and Line Fee X for I_a
        PostSalesInvoice(CustNo, CalcDate('<-30D>', WorkDate()));
        ReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, CalcDate('<-20D>', WorkDate()));
        IssuedReminderNo := IssueReminder(ReminderNo, 0, false);

        // [GIVEN] IR_1 is overdue
        // [WHEN] A Finance Charge is created and lines are suggested (i.e. interest rate is calculated)
        FinanceChrgNo := CreateFinChrgAndSuggestLines(CustNo, WorkDate());

        // [THEN] No lines is added for IR_1 as only Line Fees is issued
        FinanceChrgMemoLine.SetRange("Finance Charge Memo No.", FinanceChrgNo);
        FinanceChrgMemoLine.SetRange("Document Type", FinanceChrgMemoLine."Document Type"::Reminder);
        FinanceChrgMemoLine.SetRange("Document No.", IssuedReminderNo);
        Assert.AreEqual(0, FinanceChrgMemoLine.Count,
          StrSubstNo(MustMatchErr, 'Row Count', FinanceChrgMemoLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('IssueRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostNoInterestOnLineFeeReminder()
    var
        ReminderLevel: Record "Reminder Level";
        ReminderLine: Record "Reminder Line";
        Customer: Record Customer;
        CustNo: Code[20];
        ReminderTermCode: Code[10];
        FinanceChrgTermCode: Code[10];
        ReminderNo: Code[20];
        IssuedReminderNo: Code[20];
        SecondReminderNo: Code[20];
        InvoiceA: Code[20];
        AmountZ: Decimal;
    begin
        // [SCENARIO 107048] Post process: Interest is not applied to Line Fees on Reminders, only to Additional fees when "Add. Line Fee in Interest" = FALSE
        Initialize(false);

        // [GIVEN] A reminder term (R) with Line Fee set up for level 1 and additional fee Z
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);
        ReminderLevel.Get(ReminderTermCode, 1);
        AmountZ := LibraryRandom.RandDecInRange(1, 100, 2);
        ReminderLevel.Validate("Additional Fee (LCY)", AmountZ);
        ReminderLevel.Validate("Calculate Interest", true);
        ReminderLevel.Modify(true);

        // [GIVEN] A Finance Charge Term (T) with 2% interest and "Add. Line Fee in Interest" = FALSE
        FinanceChrgTermCode := CreateFinChrgTerms(2, 0, 5, true, false, false);
        Customer.Get(CustNo);
        Customer.Validate("Fin. Charge Terms Code", FinanceChrgTermCode);
        Customer.Modify(true);

        // [GIVEN] An Issued Reminder (IR_1) with reminder for Invoice I_a and Line Fee X for I_a
        InvoiceA := PostSalesInvoice(CustNo, CalcDate('<-30D>', WorkDate()));
        ReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, CalcDate('<-20D>', WorkDate()));
        IssuedReminderNo := IssueReminder(ReminderNo, 0, false);

        // [GIVEN] IR_1 is overdue
        // [WHEN] A 2nd Reminder is created with R (and interest is calculated)
        SecondReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, WorkDate());

        // [THEN] The interest on I_a is calculated
        VerifyReminderLineExists(ReminderLine, SecondReminderNo, ReminderLine.Type::"Customer Ledger Entry", ReminderLine."Document Type"::Invoice, InvoiceA);
        Assert.AreNearlyEqual(ReminderLine."Remaining Amount" * 0.02, ReminderLine.Amount, ReminderLine."Remaining Amount" / 1000,
          StrSubstNo(MustMatchErr, ReminderLine.FieldCaption(Amount), ReminderLine.TableCaption()));

        // [THEN] The interest is calculated for IR_1 based only on Z
        VerifyReminderLineExists(
              ReminderLine, SecondReminderNo, ReminderLine.Type::"Customer Ledger Entry", ReminderLine."Document Type"::Reminder, IssuedReminderNo);
        Assert.AreNearlyEqual(AmountZ * 0.02 / 30 * 20, ReminderLine.Amount, 1,
          StrSubstNo(MustMatchErr, ReminderLine.FieldCaption(Amount), ReminderLine.TableCaption()));

        // [THEN] The remaining amount of IR_1 is not equal to Z (i.e. it includes the Line Fee)
        Assert.AreNotEqual(ReminderLine."Remaining Amount", AmountZ,
          StrSubstNo(MustNotMatchErr, ReminderLine.FieldCaption("Remaining Amount"), ReminderLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('IssueRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostInterestOnLineFeeFinCharge()
    var
        ReminderLevel: Record "Reminder Level";
        FinanceChrgMemoLine: Record "Finance Charge Memo Line";
        Customer: Record Customer;
        CustNo: Code[20];
        ReminderTermCode: Code[10];
        FinanceChrgTermCode: Code[10];
        ReminderNo: Code[20];
        IssuedReminderNo: Code[20];
        FinanceChrgNo: Code[20];
        AmountZ: Decimal;
        AmountX: Decimal;
    begin
        // [SCENARIO 107048] Post process: Interest is applied to Line Fees and to Additional fees on reminders when "Add. Line Fee in Interest" = TRUE
        Initialize(false);

        // [GIVEN] A reminder term (R) with Line Fee set up for level 1 and additional fee Z
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);
        ReminderLevel.Get(ReminderTermCode, 1);
        AmountZ := LibraryRandom.RandDecInRange(1, 100, 2);
        AmountX := ReminderLevel."Add. Fee per Line Amount (LCY)";
        ReminderLevel.Validate("Additional Fee (LCY)", AmountZ);
        ReminderLevel.Modify(true);

        // [GIVEN] A Finance Charge Term (T) with 2% interest and with "Add. Line Fee in Interest" = TRUE
        FinanceChrgTermCode := CreateFinChrgTerms(2, 0, 5, true, false, true);
        Customer.Get(CustNo);
        Customer.Validate("Fin. Charge Terms Code", FinanceChrgTermCode);
        Customer.Modify(true);

        // [GIVEN] An Issued Reminder (IR_1) with reminder for Invoice I_a and Line Fee X for I_a
        PostSalesInvoice(CustNo, CalcDate('<-30D>', WorkDate()));
        ReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, CalcDate('<-20D>', WorkDate()));
        IssuedReminderNo := IssueReminder(ReminderNo, 0, false);

        // [GIVEN] IR_1 is overdue
        // [WHEN] A Finance Charge is created and lines are suggested (i.e. interest rate is calculated)
        FinanceChrgNo := CreateFinChrgAndSuggestLines(CustNo, WorkDate());

        // [THEN] The interest is calculated on Z+X
        FinanceChrgMemoLine.SetRange("Finance Charge Memo No.", FinanceChrgNo);
        FinanceChrgMemoLine.SetRange("Document Type", FinanceChrgMemoLine."Document Type"::Reminder);
        FinanceChrgMemoLine.SetRange("Document No.", IssuedReminderNo);
        FinanceChrgMemoLine.FindFirst();
        Assert.AreNearlyEqual((AmountZ + AmountX) * 0.02 / 30 * 20, FinanceChrgMemoLine.Amount, 1,
          StrSubstNo(MustMatchErr, FinanceChrgMemoLine.FieldCaption(Amount), FinanceChrgMemoLine.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('IssueRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PostInterestOnLineFeeReminder()
    var
        ReminderLevel: Record "Reminder Level";
        ReminderLine: Record "Reminder Line";
        Customer: Record Customer;
        CustNo: Code[20];
        ReminderTermCode: Code[10];
        FinanceChrgTermCode: Code[10];
        ReminderNo: Code[20];
        IssuedReminderNo: Code[20];
        SecondReminderNo: Code[20];
        InvoiceA: Code[20];
        AmountZ: Decimal;
        AmountX: Decimal;
    begin
        // [SCENARIO 107048] Post process: Interest is applied to Line Fees and to Additional fees from reminders when "Add. Line Fee in Interest" = TRUE
        Initialize(false);

        // [GIVEN] A reminder term (R) with Line Fee set up for level 1 with additional fee Z and Line Fee X
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);
        ReminderLevel.Get(ReminderTermCode, 1);
        AmountZ := LibraryRandom.RandDecInRange(1, 100, 2);
        AmountX := ReminderLevel."Add. Fee per Line Amount (LCY)";
        ReminderLevel.Validate("Additional Fee (LCY)", AmountZ);
        ReminderLevel.Validate("Calculate Interest", true);
        ReminderLevel.Modify(true);

        // [GIVEN] A Finance Charge Term (T) with 2% interest and with "Add. Line Fee in Interest" = TRUE
        FinanceChrgTermCode := CreateFinChrgTerms(2, 0, 5, true, false, true);
        Customer.Get(CustNo);
        Customer.Validate("Fin. Charge Terms Code", FinanceChrgTermCode);
        Customer.Modify(true);

        // [GIVEN] An Issued Reminder (IR_1) with reminder for Invoice I_a and Line Fee X for I_a
        InvoiceA := PostSalesInvoice(CustNo, CalcDate('<-30D>', WorkDate()));
        ReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, CalcDate('<-20D>', WorkDate()));
        IssuedReminderNo := IssueReminder(ReminderNo, 0, false);

        // [GIVEN] IR_1 is overdue
        // [WHEN] A 2nd Reminder is created with R (and interest is calculated)
        SecondReminderNo := CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, WorkDate());

        // [THEN] The interest on I_a is calculated
        VerifyReminderLineExists(ReminderLine, SecondReminderNo, ReminderLine.Type::"Customer Ledger Entry", ReminderLine."Document Type"::Invoice, InvoiceA);
        Assert.AreNearlyEqual(ReminderLine."Remaining Amount" * 0.02, ReminderLine.Amount, ReminderLine."Remaining Amount" / 1000,
          StrSubstNo(MustMatchErr, ReminderLine.FieldCaption(Amount), ReminderLine.TableCaption()));

        // [THEN] The interest is calculated for IR_1 based on X+Z
        VerifyReminderLineExists(
              ReminderLine, SecondReminderNo, ReminderLine.Type::"Customer Ledger Entry", ReminderLine."Document Type"::Reminder, IssuedReminderNo);
        Assert.AreNearlyEqual((AmountZ + AmountX) * 0.02 / 30 * 20, ReminderLine.Amount, 1,
          StrSubstNo(MustMatchErr, ReminderLine.FieldCaption(Amount), ReminderLine.TableCaption()));

        // [THEN] The remaining amount of IR_1 is not equal to Z (i.e. it includes the Line Fee)
        Assert.AreNotEqual(ReminderLine."Remaining Amount", AmountZ,
          StrSubstNo(MustNotMatchErr, ReminderLine.FieldCaption("Remaining Amount"), ReminderLine.TableCaption()));
    end;

    [HandlerFunctions('IssueRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IssueReminderEmail()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        CustomerNo: Code[20];
        ReminderNo: Code[20];
    begin
        // [FEATURE] [EMail]
        // [SCENARIO 376445] Issue Reminder with Print = E-Mail and Hide Email-Dialog = No should show 'E-Mail Dialog' page
        Initialize(false);

        // [GIVEN] Customer "A" with Reminder Print = E-Mail and Hide Email-Dialog = No
        CreateReminderForCustomer(CustomerNo, ReminderNo);
        Commit();

        // [WHEN] Issue Reminder
        IssueReminder(ReminderNo, PrintDocRef::Email, false);

        // [THEN] Cancel on Email Dialog appeared
        // [THEN] Issued Reminder for Customer "A" exists
        IssuedReminderHeader.Init();
        IssuedReminderHeader.SetRange("Customer No.", CustomerNo);
        Assert.RecordIsNotEmpty(IssuedReminderHeader);
    end;

    local procedure Initialize(ClearExtReminders: Boolean)
    var
        CustomerPostingGroup: Record "Customer Posting Group";
        ReminderHeader: Record "Reminder Header";
        FeatureKey: Record "Feature Key";
        FeatureKeyUpdateStatus: Record "Feature Data Update Status";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Reminder - Add. Line fee");
        BindActiveDirectoryMockEvents();
        ResetDocumentValueRange();
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if ClearExtReminders then
            ReminderHeader.DeleteAll(true);

        if FeatureKey.Get('ReminderTermsCommunicationTexts') then begin
            FeatureKey.Enabled := FeatureKey.Enabled::None;
            FeatureKey.Modify();
        end;
        if FeatureKeyUpdateStatus.Get('ReminderTermsCommunicationTexts', CompanyName()) then begin
            FeatureKeyUpdateStatus."Feature Status" := FeatureKeyUpdateStatus."Feature Status"::Disabled;
            FeatureKeyUpdateStatus.Modify();
        end;

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Reminder - Add. Line fee");

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Link Doc. Date To Posting Date", true);
        SalesReceivablesSetup.Modify();
        SetGLSetupInvoiceRounding();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);
        CustomerPostingGroup.FindFirst();
        CustomerPostingGroup.ModifyAll("Add. Fee per Line Account", CustomerPostingGroup."Additional Fee Account");

        IsInitialized := true;
        Commit();

        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Reminder - Add. Line fee");
    end;

    local procedure ResetDocumentValueRange()
    begin
        MinDocumentValue := 1;
        MaxDocumentValue := 100000;
    end;

    local procedure CreateCurrencyforReminderLevel(ReminderTermsCode: Code[10]; Level: Integer; CurrencyCode: Code[10]; AdditionalFee: Decimal; LineFee: Decimal)
    var
        CurrencyForReminderLevel: Record "Currency for Reminder Level";
    begin
        CurrencyForReminderLevel.Init();
        CurrencyForReminderLevel.Validate("Reminder Terms Code", ReminderTermsCode);
        CurrencyForReminderLevel.Validate("No.", Level);
        CurrencyForReminderLevel.Validate("Currency Code", CurrencyCode);
        CurrencyForReminderLevel.Validate("Additional Fee", AdditionalFee);
        CurrencyForReminderLevel.Validate("Add. Fee per Line", LineFee);
        CurrencyForReminderLevel.Insert(true);
    end;

    local procedure CreateCustomerWithReminderAndPaymentTerms(ReminderTermsCode: Code[10]; PaymentTermsCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Reminder Terms Code", ReminderTermsCode);
        Customer.Validate("Payment Terms Code", PaymentTermsCode);
        Customer.Validate("E-Mail", EmailTxt);
        Customer.Modify(true);
        exit(Customer."No.")
    end;

    local procedure CreateCustomerWithReminderTermsAddFeePerLine(var CustNo: Code[20]; var ReminderTermCode: Code[10]; WithLineFee: Boolean; CurrencyCode: Code[10]; LineFee: Decimal)
    var
        PaymentTermsCode: Code[10];
    begin
        PaymentTermsCode := CreatePaymentTerms(1);
        ReminderTermCode := CreateReminderTerms(true, false, true);
        if WithLineFee then
            CreateReminderTermsLevel(ReminderTermCode, 1, 1, CurrencyCode, 0, LineFee, false, 1)
        else
            CreateReminderTermsLevel(ReminderTermCode, 1, 1, '', 0, 0, false, 1);

        CustNo := CreateCustomerWithReminderAndPaymentTerms(ReminderTermCode, PaymentTermsCode);
    end;

    local procedure CreatePaymentTerms(DueDateDays: Integer): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
        DueDateCalcFormula: DateFormula;
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        Evaluate(DueDateCalcFormula, '<+' + Format(DueDateDays) + 'D>');
        PaymentTerms.Validate("Due Date Calculation", DueDateCalcFormula);
        PaymentTerms.Modify(true);
        exit(PaymentTerms.Code)
    end;

    local procedure CreateReminderHeader(var ReminderHeader: Record "Reminder Header"; CustNo: Code[20]; PostingDate: Date)
    begin
        LibraryERM.CreateReminderHeader(ReminderHeader);
        ReminderHeader.Validate("Customer No.", CustNo);
        ReminderHeader.Validate("Posting Date", PostingDate);
        ReminderHeader.Validate("Document Date", PostingDate);
        ReminderHeader.Modify(true);
    end;

    local procedure CreateReminderAndSuggestLines(CustomerNo: Code[20]; PostingDate: Date; var CustLedgEntryLineFeeOn: Record "Cust. Ledger Entry"): Code[20]
    var
        ReminderHeader: Record "Reminder Header";
    begin
        CreateReminderHeader(ReminderHeader, CustomerNo, PostingDate);

        SuggestReminderLines(ReminderHeader."No.", CustLedgEntryLineFeeOn);
        exit(ReminderHeader."No.")
    end;

    local procedure CreateReminderAndSuggestLinesLineFeeOnAll(CustomerNo: Code[20]; PostingDate: Date): Code[20]
    var
        CustLedgEntryLineFeeOn: Record "Cust. Ledger Entry";
    begin
        CustLedgEntryLineFeeOn.Reset();
        exit(CreateReminderAndSuggestLines(CustomerNo, PostingDate, CustLedgEntryLineFeeOn));
    end;

    local procedure CreateReminderWithOverdueInvoiceAndLineFee(): Code[20]
    var
        CustNo: Code[20];
        ReminderTermCode: Code[10];
    begin
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);
        PostSalesInvoice(CustNo, CalcDate('<-10D>', WorkDate()));
        exit(CreateReminderAndSuggestLinesLineFeeOnAll(CustNo, CalcDate('<-6D>', WorkDate())));
    end;

    local procedure SuggestReminderLines(ReminderNo: Code[20]; var CustLedgEntryLineFeeOn: Record "Cust. Ledger Entry")
    var
        ReminderHeader: Record "Reminder Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ReminderMake: Codeunit "Reminder-Make";
    begin
        ReminderHeader.Get(ReminderNo);
        ReminderMake.SuggestLines(ReminderHeader, CustLedgerEntry, false, false, CustLedgEntryLineFeeOn);
        ReminderMake.Code();
    end;

    local procedure CreateReminderLineOfTypeLineFee(var ReminderLine: Record "Reminder Line"; ReminderNo: Code[20]; DocType: Enum "Gen. Journal Document Type"; DocNo: Code[20])
    begin
        ReminderLine.Init();
        ReminderLine.Validate("Reminder No.", ReminderNo);
        ReminderLine.Insert(true);
        ReminderLine.Validate(Type, ReminderLine.Type::"Line Fee");
        ReminderLine.Validate("Applies-to Document Type", DocType);
        ReminderLine.Validate("Applies-to Document No.", DocNo);
        ReminderLine.Modify(true);
    end;

    local procedure RunCreateReminderReport(CustNo: Code[20]; PostingDate: Date; var CustLedgEntryLineFeeOn: Record "Cust. Ledger Entry"): Code[20]
    var
        Customer: Record Customer;
        ReminderHeader: Record "Reminder Header";
        CreateReminders: Report "Create Reminders";
    begin
        CreateReminders.InitializeRequest(PostingDate, PostingDate, true, false, false);
        if CustNo <> '' then begin
            Customer.SetRange("No.", CustNo);
            CreateReminders.SetTableView(Customer);
        end;
        CreateReminders.SetApplyLineFeeOnFilters(CustLedgEntryLineFeeOn);
        CreateReminders.UseRequestPage(false);
        CreateReminders.Run();

        if CustNo <> '' then
            ReminderHeader.SetRange("Customer No.", CustNo);
        if ReminderHeader.FindLast() then
            exit(ReminderHeader."No.");
        exit('');
    end;

    local procedure CreateFinChrgAndSuggestLines(CustomerNo: Code[20]; PostingDate: Date): Code[20]
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
    begin
        LibraryERM.CreateFinanceChargeMemoHeader(FinanceChargeMemoHeader, CustomerNo);
        FinanceChargeMemoHeader.Validate("Posting Date", PostingDate);
        FinanceChargeMemoHeader.Validate("Document Date", PostingDate);
        FinanceChargeMemoHeader.Modify(true);

        FinanceChargeMemoHeader.SetRange("No.", FinanceChargeMemoHeader."No.");
        REPORT.RunModal(REPORT::"Suggest Fin. Charge Memo Lines", false, false, FinanceChargeMemoHeader);

        exit(FinanceChargeMemoHeader."No.")
    end;

    local procedure CreateReminderTerms(PostLineFee: Boolean; PostInterest: Boolean; PostAddFee: Boolean): Code[10]
    var
        ReminderTerms: Record "Reminder Terms";
    begin
        LibraryERM.CreateReminderTerms(ReminderTerms);
        ReminderTerms.Validate("Post Interest", PostInterest);
        ReminderTerms.Validate("Post Add. Fee per Line", PostLineFee);
        ReminderTerms.Validate("Post Additional Fee", PostAddFee);
        ReminderTerms.Validate("Note About Line Fee on Report", '%1 %2 %3 %4');
        ReminderTerms.Modify(true);
        exit(ReminderTerms.Code)
    end;

    local procedure CreateReminderTermsLevel(ReminderTermsCode: Code[10]; DueDateDays: Integer; GracePeriodDays: Integer; CurrencyCode: Code[10]; AdditionalFee: Decimal; LineFee: Decimal; CalculateInterest: Boolean; Level: Integer)
    var
        ReminderLevel: Record "Reminder Level";
        DueDateCalcFormula: DateFormula;
        GracePeriodCalcFormula: DateFormula;
    begin
        LibraryERM.CreateReminderLevel(ReminderLevel, ReminderTermsCode);
        Evaluate(DueDateCalcFormula, '<+' + Format(DueDateDays) + 'D>');
        Evaluate(GracePeriodCalcFormula, '<+' + Format(GracePeriodDays) + 'D>');
        ReminderLevel.Validate("No.", Level);
        ReminderLevel.Validate("Due Date Calculation", DueDateCalcFormula);
        ReminderLevel.Validate("Grace Period", GracePeriodCalcFormula);
        ReminderLevel.Validate("Calculate Interest", CalculateInterest);
        ReminderLevel.Validate("Add. Fee per Line Description",
          LibraryUtility.GenerateRandomCode(ReminderLevel.FieldNo("Add. Fee per Line Description"), DATABASE::"Reminder Level"));
        if CurrencyCode <> '' then
            CreateCurrencyforReminderLevel(ReminderTermsCode, Level, CurrencyCode, AdditionalFee, LineFee)
        else begin
            ReminderLevel.Validate("Add. Fee per Line Amount (LCY)", LineFee);
            ReminderLevel.Validate("Additional Fee (LCY)", AdditionalFee);
        end;
        ReminderLevel.Modify(true);
    end;

    local procedure CreateAdditionalFeeSetupLine(ReminderTermsCode: Code[10]; Level: Integer; PerLine: Boolean; Currency: Code[10]; Threshold: Decimal)
    var
        AdditionalFeeSetup: Record "Additional Fee Setup";
    begin
        AdditionalFeeSetup.Init();
        AdditionalFeeSetup."Reminder Terms Code" := ReminderTermsCode;
        AdditionalFeeSetup."Reminder Level No." := Level;
        AdditionalFeeSetup."Charge Per Line" := PerLine;
        AdditionalFeeSetup."Currency Code" := Currency;
        AdditionalFeeSetup."Threshold Remaining Amount" := Threshold;
        AdditionalFeeSetup."Additional Fee Amount" := LibraryRandom.RandDecInRange(0, 100, 2);
        AdditionalFeeSetup."Additional Fee %" := LibraryRandom.RandDecInRange(0, 100, 2);
        AdditionalFeeSetup.Insert(true);
    end;

    local procedure CreateStandardReminderTermSetupWithCust(var CustNo: Code[20]; var ReminderTermCode: Code[10]; WithLineFee: Boolean)
    begin
        CreateCustomerWithReminderTermsAddFeePerLine(
          CustNo, ReminderTermCode, WithLineFee, '', LibraryRandom.RandDecInRange(1, 100, 2));
    end;

    local procedure CreateStandardReminderTermSetupWithCustAndFinChrg(var CustNo: Code[20]; var ReminderTermCode: Code[10]; WithLineFee: Boolean; CalcInterest: Boolean; PostInterest: Boolean)
    var
        ReminderTerms: Record "Reminder Terms";
        ReminderLevel: Record "Reminder Level";
        Customer: Record Customer;
        FinanceChrgTermCode: Code[10];
    begin
        CreateCustomerWithReminderTermsAddFeePerLine(
          CustNo, ReminderTermCode, WithLineFee, '', LibraryRandom.RandDecInRange(1, 100, 2));

        ReminderTerms.Get(ReminderTermCode);
        ReminderTerms."Post Interest" := PostInterest;
        ReminderTerms.Modify(true);
        ReminderLevel.Get(ReminderTermCode, 1);
        ReminderLevel."Calculate Interest" := CalcInterest;
        ReminderLevel.Modify(true);

        // [GIVEN] A Finance Charge Term (T) with 2% interest and with "Add. Line Fee in Interest" = TRUE
        FinanceChrgTermCode := CreateFinChrgTerms(2, 0, 5, true, false, true);
        Customer.Get(CustNo);
        Customer.Validate("Fin. Charge Terms Code", FinanceChrgTermCode);
        Customer.Modify(true);
    end;

    local procedure CreateStandardRmdTermSetupWithSingleDynCalc(var ReminderTermCode: Code[10]; var CustNo: Code[20]; Percentage: Decimal)
    var
        ReminderLevel: Record "Reminder Level";
        AdditionalFeeSetup: Record "Additional Fee Setup";
        PaymentTermsCode: Code[10];
    begin
        CreateStandardReminderTermSetupWithCust(CustNo, ReminderTermCode, true);
        PaymentTermsCode := CreatePaymentTerms(1);
        ReminderTermCode := CreateReminderTerms(true, false, true);

        CreateReminderTermsLevel(ReminderTermCode, 1, 1, '', 0, 0, false, 1);

        ReminderLevel.Get(ReminderTermCode, 1);
        ReminderLevel."Add. Fee Calculation Type" := ReminderLevel."Add. Fee Calculation Type"::"Single Dynamic";
        ReminderLevel.Modify(true);

        AdditionalFeeSetup.Init();
        AdditionalFeeSetup."Reminder Terms Code" := ReminderTermCode;
        AdditionalFeeSetup."Reminder Level No." := 1;
        AdditionalFeeSetup."Charge Per Line" := false;
        AdditionalFeeSetup."Currency Code" := '';
        AdditionalFeeSetup."Threshold Remaining Amount" := 0;
        AdditionalFeeSetup."Additional Fee %" := Percentage;
        AdditionalFeeSetup.Insert(true);

        CustNo := CreateCustomerWithReminderAndPaymentTerms(ReminderTermCode, PaymentTermsCode);
    end;

    local procedure CreateFinChrgTerms(InterestRate: Decimal; AddFee: Decimal; GracePeriod: Integer; PostInterest: Boolean; PostAddFee: Boolean; IncludeLineFeeInInterest: Boolean): Code[10]
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        DueDateCalcFormula: DateFormula;
    begin
        LibraryERM.CreateFinanceChargeTerms(FinanceChargeTerms);
        FinanceChargeTerms.Validate("Interest Rate", InterestRate);
        FinanceChargeTerms.Validate("Interest Period (Days)", 30);
        FinanceChargeTerms.Validate("Additional Fee (LCY)", AddFee);
        FinanceChargeTerms.Validate(
          "Interest Calculation Method", FinanceChargeTerms."Interest Calculation Method"::"Average Daily Balance");
        Evaluate(DueDateCalcFormula, '<+' + Format(GracePeriod) + 'D>');
        FinanceChargeTerms.Validate("Grace Period", DueDateCalcFormula);
        FinanceChargeTerms.Validate("Post Interest", PostInterest);
        FinanceChargeTerms.Validate("Post Additional Fee", PostAddFee);
        FinanceChargeTerms.Validate("Add. Line Fee in Interest", IncludeLineFeeInInterest);
        FinanceChargeTerms.Modify(true);
        exit(FinanceChargeTerms.Code);
    end;

    local procedure CreateReminderForCustomer(var CustomerNo: Code[20]; var ReminderNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ReminderHeader: Record "Reminder Header";
        ReminderTermCode: Code[10];
    begin
        CreateStandardReminderTermSetupWithCust(CustomerNo, ReminderTermCode, true);
        PostSalesInvoice(CustomerNo, WorkDate() - 10);
        RunCreateReminderReport(CustomerNo, WorkDate(), CustLedgerEntry);
        ReminderHeader.SetRange("Customer No.", CustomerNo);
        ReminderHeader.FindFirst();
        ReminderNo := ReminderHeader."No.";
    end;

    local procedure AddReminderText(ReminderTermCode: Code[10]; Level: Integer; Position: Enum "Reminder Text Position"; Text: Text[100])
    var
        ReminderText: Record "Reminder Text";
        NextLineNo: Integer;
    begin
        ReminderText.SetRange("Reminder Terms Code", ReminderTermCode);
        ReminderText.SetRange("Reminder Level", Level);
        if ReminderText.FindLast() then;
        NextLineNo := ReminderText."Line No." + 1000;

        ReminderText.Init();
        ReminderText."Reminder Terms Code" := ReminderTermCode;
        ReminderText."Reminder Level" := Level;
        ReminderText.Position := Position;
        ReminderText.Text := Text;
        ReminderText."Line No." := NextLineNo;
        ReminderText.Insert(true);
    end;

    local procedure UpdateReminderText(ReminderNo: Code[20]; Level: Integer)
    var
        ReminderHeader: Record "Reminder Header";
    begin
        Commit();
        ReminderHeader.SetRange("No.", ReminderNo);
        LibraryVariableStorage.Enqueue(Level);
        REPORT.RunModal(REPORT::"Update Reminder Text", true, false, ReminderHeader);
    end;

    local procedure UpdateCustomerVATRegNo(CustomerNo: Code[20])
    var
        Customer: Record Customer;
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        Customer.Get(CustomerNo);
        Customer."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(CompanyInformation."Country/Region Code");
        Customer.Modify();
    end;

    local procedure FindOpenCustomerLedgerEntriesExclVAT(var CustLedgerEntry: Record "Cust. Ledger Entry"; IssuedReminderNo: Code[20]; CustomerNo: Code[20])
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document No.", IssuedReminderNo);
        CustLedgerEntry.SetRange(Open, true);
        CustLedgerEntry.FindSet();
        CustLedgerEntry.CalcFields(Amount, "Remaining Amount");
        CustLedgerEntry.Amount -= GetVATOfCustLedgEntry(CustLedgerEntry);
    end;

    local procedure GetVATOfCustLedgEntry(var CustLedgEntry: Record "Cust. Ledger Entry"): Decimal
    var
        VATEntry: Record "VAT Entry";
        Amount: Decimal;
    begin
        VATEntry.SetRange("Document No.", CustLedgEntry."Document No.");
        VATEntry.SetRange("Document Type", CustLedgEntry."Document Type");
        if VATEntry.FindSet() then
            repeat
                Amount += VATEntry.Amount;
            until VATEntry.Next() = 0;
        exit(-Amount);
    end;

    local procedure FindGLAccountWithVAT(VATBusGroup: Code[20]): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        AccountNo: Code[20];
    begin
        GetValidVATPostingSetup(VATPostingSetup, VATBusGroup);
        AccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::Sale); // Sale
        UpdateDefaultVATProdGroup(AccountNo);
        exit(AccountNo);
    end;

    local procedure FindTwoGLAccounts(var GLAccountA: Code[20]; var GLAccountB: Code[20]; VATBusGroup: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        GetValidVATPostingSetup(VATPostingSetup, VATBusGroup);
        VATPostingSetup.SetRange("VAT %", 0);
        VATPostingSetup.FindFirst();
        GLAccountA := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::Sale); // Sale
        VATPostingSetup.Next();
        GLAccountB := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, "General Posting Type"::Sale); // Sale
        UpdateDefaultVATProdGroup(GLAccountA);
        UpdateDefaultVATProdGroup(GLAccountB);
    end;

    local procedure GetValidVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; VATBusGroup: Code[20])
    begin
        if VATBusGroup <> '' then
            VATPostingSetup.SetRange("VAT Bus. Posting Group", VATBusGroup);
        VATPostingSetup.SetRange("VAT %", 1, 100);
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.SetFilter("Sales VAT Account", '<>%1', '');
        VATPostingSetup.FindFirst();
    end;

    local procedure UpdateDefaultVATProdGroup(AccountNo: Code[20])
    var
        GLAccount: Record "G/L Account";
        GenProdPostingGroup: Record "Gen. Product Posting Group";
    begin
        GLAccount.Get(AccountNo);
        if GenProdPostingGroup.Get(GLAccount."Gen. Prod. Posting Group") then begin
            if GenProdPostingGroup."Auto Insert Default" then
                GenProdPostingGroup."Def. VAT Prod. Posting Group" := GLAccount."VAT Prod. Posting Group";
            GenProdPostingGroup.Modify(true);
        end;
    end;

    local procedure GetReminderLines(var ReminderLine: Record "Reminder Line"; ReminderHeaderNo: Code[20]; Type: Enum "Reminder Source Type"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]): Boolean
    begin
        ReminderLine.Reset();
        ReminderLine.SetRange("Reminder No.", ReminderHeaderNo);
        ReminderLine.SetRange(Type, Type);
        if Type = ReminderLine.Type::"Line Fee" then begin
            if DocumentType <> DocumentType::" " then
                ReminderLine.SetRange("Applies-to Document Type", DocumentType);
            if DocumentNo <> '' then
                ReminderLine.SetRange("Applies-to Document No.", DocumentNo);
        end else begin
            if DocumentType <> DocumentType::" " then
                ReminderLine.SetRange("Document Type", DocumentType);
            if DocumentNo <> '' then
                ReminderLine.SetRange("Document No.", DocumentNo);
        end;

        exit(ReminderLine.FindSet());
    end;

    local procedure VerifyReminderLineExists(var ReminderLine: Record "Reminder Line"; ReminderHeaderNo: Code[20]; Type: Enum "Reminder Source Type"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        Assert.IsTrue(
          GetReminderLines(ReminderLine, ReminderHeaderNo, Type, DocumentType, DocumentNo),
          StrSubstNo(ReminderLineMustExistErr, ReminderLine.GetFilters));
    end;

    local procedure VerifyReminderLineDoesNotExists(var ReminderLine: Record "Reminder Line"; ReminderHeaderNo: Code[20]; Type: Enum "Reminder Source Type"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        Assert.IsFalse(
          GetReminderLines(ReminderLine, ReminderHeaderNo, Type, DocumentType, DocumentNo),
          StrSubstNo(ReminderLineMustNotExistErr, ReminderLine.GetFilters));
    end;

    local procedure IssueReminder(ReminderHeaderNo: Code[20]; PrintDoc: Option; HideEmailDialog: Boolean): Code[20]
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        ReminderHeader: Record "Reminder Header";
        IssueReminders: Report "Issue Reminders";
    begin
        LibraryVariableStorage.Enqueue(PrintDoc);
        LibraryVariableStorage.Enqueue(HideEmailDialog);
        ReminderHeader.Get(ReminderHeaderNo);
        ReminderHeader.SetRange("No.", ReminderHeaderNo);
        Clear(IssueReminders);
        IssueReminders.SetTableView(ReminderHeader);
        Commit();
        IssueReminders.Run();

        IssuedReminderHeader.SetFilter("Customer No.", ReminderHeader."Customer No.");
        IssuedReminderHeader.FindLast();
        exit(IssuedReminderHeader."No.")
    end;

    local procedure PostSalesInvoice(CustomerNo: Code[20]; PostingDate: Date): Code[20]
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(
          SalesLine,
          SalesHeader,
          SalesLine.Type::Item,
          Item."No.",
          LibraryRandom.RandDecInRange(MinDocumentValue, MaxDocumentValue, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, true)); // Ship, Invoice
    end;

    local procedure PostCreditMemo(CustomerNo: Code[20]; PostingDate: Date): Code[20]
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
        LibraryInventory.CreateItem(Item);
        LibrarySales.CreateSalesLine(
          SalesLine,
          SalesHeader,
          SalesLine.Type::Item,
          Item."No.",
          LibraryRandom.RandDecInRange(MinDocumentValue, MaxDocumentValue, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, true)); // Ship, Invoice
    end;

    local procedure PostCustGenJnlLine(CustNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
          GenJournalLine."Account Type"::Customer, CustNo, LibraryRandom.RandDec(100, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure SetGLSetupInvoiceRounding()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Inv. Rounding Precision (LCY)" := GeneralLedgerSetup."Amount Rounding Precision";
        GeneralLedgerSetup.Modify();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IssueRemindersRequestPageHandler(var IssueReminders: TestRequestPage "Issue Reminders")
    begin
        IssueReminders.PrintDoc.SetValue(LibraryVariableStorage.DequeueInteger());
        IssueReminders.HideEmailDialog.SetValue(LibraryVariableStorage.DequeueBoolean());
        IssueReminders.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure UpdateReminderTextRequestPageHandler(var UpdateText: TestRequestPage "Update Reminder Text")
    var
        Level: Variant;
    begin
        LibraryVariableStorage.Dequeue(Level);
        UpdateText.ReminderLevelNo.SetValue(Level);
        UpdateText.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmNoHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    local procedure BindActiveDirectoryMockEvents()
    begin
        if ActiveDirectoryMockEvents.Enabled() then
            exit;
        BindSubscription(ActiveDirectoryMockEvents);
        ActiveDirectoryMockEvents.Enable();
    end;
}

