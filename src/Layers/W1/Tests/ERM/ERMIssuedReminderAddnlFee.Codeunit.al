codeunit 134905 "ERM Issued Reminder Addnl Fee"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [ERM] [Reminder]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        AmountError: Label 'Additional Fee Amount must be %1 for Issued Reminder No: %2.';
        ReminderEndingText: Label 'Balance %7';
        ErrorMustMatch: Label 'Error Must Match.';
        ReminderLineDescription: Label 'Balance %1';
        ReminderLevelNo: Integer;
        NoOfRemindersErr: Label 'The value of No. Of Reminders is not correct.';
        ReminderDueDateErr: Label 'The Reminder/Fin. Charge Entry Due Date should equal to Cust. Ledger Entry Due Date.';

    [Test]
    [Scope('OnPrem')]
    procedure ReminderWithLCY()
    var
        CurrencyCode: Code[10];
    begin
        // Check the Additional Fee Amount on Issued Reminder for a Customer with LCY.
        Initialize();
        CurrencyCode := CreateCurrency();
        CreateReminderWithCurrency(CurrencyCode, CurrencyCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderWithFCY()
    begin
        // Check the Additional Fee Amount on Issued Reminder for a Customer with FCY.
        Initialize();
        CreateReminderWithCurrency(CreateCurrency(), FindCurrency());
    end;

    local procedure CreateReminderWithCurrency(CurrencyCode: Code[10]; CurrencyCode2: Code[10])
    var
        Customer: Record Customer;
        ReminderNo: Code[20];
        Amount: Decimal;
        DocumentDate: Date;
        AdditionalFee: Decimal;
    begin
        // Setup: Create a Customer with Currency and Reminder Terms attached to it. Create and Post Sales Invoice for the Customer with
        // Currency selected. Create Reminder for the Customer through batch job on a Date after Grace Period.
        AdditionalFee := SetupAndPostSalesInvoice(Customer, DocumentDate, CurrencyCode, CurrencyCode2);
        Amount := Round(LibraryERM.ConvertCurrency(AdditionalFee, '', CurrencyCode2, WorkDate()));
        CreateReminder(Customer."No.", DocumentDate, false); // "Use Header Level" = FALSE

        // Exercise: Issue the Reminder.
        ReminderNo := IssueReminder(DocumentDate);

        // Verify: Verify the Additional Fee Amount on Issued Reminder Lines.
        VerifyReminderLine(ReminderNo, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateSalesInvoiceAndReminder()
    var
        Customer: Record Customer;
        ReminderLine: Record "Reminder Line";
        ReminderLevel: Record "Reminder Level";
        ReminderText: Record "Reminder Text";
        DueDate: Date;
        DocumentDate: Date;
    begin
        // Check Reminder Line Description after creating Reminder.
        // Setup: Create Sales Invoice and Reminder Terms Code.
        Initialize();
        CreateCustomer(Customer, '');
        ReminderLevel.SetRange("Reminder Terms Code", Customer."Reminder Terms Code");
        ReminderLevel.FindFirst();
        LibraryERM.CreateReminderText(
          ReminderText, Customer."Reminder Terms Code", ReminderLevel."No.", ReminderText.Position::Ending, ReminderEndingText);

        // Exercise: Post Sales Invoice and Create Reminder.
        DueDate := CreateAndPostSalesInvoice(Customer."No.", '');
        DocumentDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', CalcDate(ReminderLevel."Grace Period", DueDate));

        CreateReminder(Customer."No.", DocumentDate, false); // "Use Header Level" = FALSE

        // Verify: Check Description on Reminder Line after Creating Reminder.
        ReminderLine.SetRange("Line Type", ReminderLine."Line Type"::"Ending Text");
        ReminderLine.FindLast();
        Assert.AreEqual(StrSubstNo(ReminderLine.Description, ReminderLine.Amount + ReminderLine."Remaining Amount"),
          ReminderLine.Description, ErrorMustMatch);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ManualReminderMultipleInvoices()
    var
        Customer: Record Customer;
        ReminderNo: Code[20];
        DocumentDate: Date;
        Amount: Decimal;
        AdditionalFee: Decimal;
    begin
        // Check Additional Fee Amount on Issued Reminder with different Currencies for Different Sales Invoices.

        // Setup: Create a Customer with Currency and Reminder Terms attached to it. Create and Post Sales Invoice for the Customer with
        // a new Currency. Again post a Sales Invoice with Customer Currency and Create Reminder after Grace Period Date.
        AdditionalFee := SetupAndPostSalesInvoice(Customer, DocumentDate, CreateCurrency(), FindCurrency());
        CreateAndPostSalesInvoice(Customer."No.", Customer."Currency Code");
        Amount := Round(LibraryERM.ConvertCurrency(AdditionalFee, '', Customer."Currency Code", WorkDate()));
        CreateSuggestReminderManually(Customer."No.", Customer."Currency Code", DocumentDate);

        // Exercise: Issue the Reminder.
        ReminderNo := IssueReminder(DocumentDate);

        // Verify: Verify the Additional Fee Amount on Issued Reminder Lines.
        VerifyReminderLine(ReminderNo, Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestReminderLinesBatch()
    var
        Customer: Record Customer;
    begin
        // Test create reminder using suggest line.

        // Setup: Create and Post Sales Invoice using Sales Journal.
        CreateAndPostGenJournalLine(Customer);

        // Exercise: Run Suggest Reminder Lines report with Random Document Date.
        CreateSuggestReminderManually(
          Customer."No.", Customer."Currency Code", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()));

        // Verify: Verify Reminder Line must be created.
        FindReminderLine(GetReminderNo(Customer."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateRemindersBatch()
    var
        Customer: Record Customer;
    begin
        // Test create reminder using suggest reminder.

        // Setup: Create and Post Sales Invoice using Sales Journal.
        CreateAndPostGenJournalLine(Customer);

        // Exercise: Run Create Reminders report with Random Document Date.
        CreateReminder(Customer."No.", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()), false); // "Use Header Level" = FALSE

        // Verify: Verify Reminder Line must be created.
        FindReminderLine(GetReminderNo(Customer."No."));
    end;

    [Test]
    [HandlerFunctions('UpdateReminderTextPageHandler')]
    [Scope('OnPrem')]
    procedure UpdateReminderText()
    var
        Customer: Record Customer;
        ReminderHeader: Record "Reminder Header";
        ReminderLevel: Record "Reminder Level";
        ReminderText: Record "Reminder Text";
    begin
        // Check the functionality of Report Update Reminder Text.

        // Setup: Create Sales Invoice, Reminder Terms Code and Reminder Document.
        Initialize();
        CreateCustomer(Customer, '');
        GetReminderLevel(ReminderLevel, Customer."Reminder Terms Code");
        LibraryERM.CreateReminderText(
          ReminderText, Customer."Reminder Terms Code", ReminderLevel."No.", ReminderText.Position::Ending, ReminderEndingText);
        ReminderLevelNo := ReminderLevel."No.";  // Assign global variable.
        CreateReminder(
          Customer."No.",
          CalcDate(
            '<' + Format(LibraryRandom.RandInt(5)) + 'D>',
            CalcDate(ReminderLevel."Grace Period", CreateAndPostSalesInvoice(Customer."No.", ''))), false); // "Use Header Level" = FALSE
        FindReminderHeader(ReminderHeader, Customer."No.");

        // Exercise: Run Update Reminder Text Report.
        UpdateReminderTextBatch(ReminderHeader);

        // Verify: Check Description on Reminder Line after creating Reminder.
        VerifyReminderDescription(ReminderHeader."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderLevelInReminderFinChargeEntry()
    var
        Customer: Record Customer;
        ReminderLevel: Record "Reminder Level";
        ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry";
        DueDate: Date;
        DocumentDate: Date;
        IssuedReminderNo: Code[20];
    begin
        // Verify Reminder Level in Reminder/Fin. Charge Entry associated with the Issued Reminder, after issuing Reminder.

        // Setup: Create Customer. Create and post Sales Invoice. Create Reminder.
        CreateCustomer(Customer, '');
        DueDate := CreateAndPostSalesInvoice(Customer."No.", '');
        GetReminderLevel(ReminderLevel, Customer."Reminder Terms Code");
        DocumentDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', CalcDate(ReminderLevel."Grace Period", DueDate));  // Use Random Integer value to calculate Document date.
        CreateReminder(Customer."No.", DocumentDate, false); // "Use Header Level" = FALSE

        // Exercise: Issue the Reminder.
        IssuedReminderNo := IssueReminder(DocumentDate);

        // Verify: Verify Reminder Level in Reminder/Fin. Charge Entry.
        ReminderFinChargeEntry.SetRange(Type, ReminderFinChargeEntry.Type::Reminder);
        ReminderFinChargeEntry.SetRange("No.", IssuedReminderNo);
        ReminderFinChargeEntry.FindFirst();
        ReminderFinChargeEntry.TestField("Reminder Level", ReminderLevel."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyReminderHeaderRemainingAmountWithLineTypeReminderLine()
    var
        ReminderLine: Record "Reminder Line";
    begin
        // Test Remaining Amount on Reminder Header when Reminder Lines created with Line Type ReminderLine.
        ReminderHeaderWithRemainingAmount(ReminderLine."Line Type"::"Reminder Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyReminderHeaderRemainingAmountWithLineTypeNotDue()
    var
        ReminderLine: Record "Reminder Line";
    begin
        // Test Remaining Amount on Reminder Header when Reminder Line is created with Line Type Not Due.
        ReminderHeaderWithRemainingAmount(ReminderLine."Line Type"::"Not Due");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyReminderHeaderIntrestAmountWithLineTypeReminderLine()
    var
        ReminderLine: Record "Reminder Line";
    begin
        // Test Intrest Amount on Reminder Header when Reminder Lines created with Line Type ReminderLine.
        ReminderHeaderWithIntrestAmount(ReminderLine."Line Type"::"Reminder Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyReminderHeaderIntrestAmountWithLineTypeNotDue()
    var
        ReminderLine: Record "Reminder Line";
    begin
        // Test Intrest Amount on Reminder Header when Reminder Line is created with Line Type Not Due.
        ReminderHeaderWithIntrestAmount(ReminderLine."Line Type"::"Not Due");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyReminderHeaderAdditionalFeeAndVATAmountWithLineTypeAdditionalFee()
    var
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
    begin
        // Test Additional Fee and VAT Amounts on Reminder Header when Reminder Line is created with Line Type Additional Fee.

        // Setup: Insert Reminder Header with Customer No.
        Initialize();
        InsertReminderHeader(ReminderHeader);

        // Exercise: Insert Reminder Line with Line Type Additional Fee.
        AddReminderLine(ReminderLine, ReminderHeader."No.", ReminderLine.Type::"G/L Account", ReminderLine."Line Type"::"Additional Fee");

        // Verify: Verify Additional Fee and VAT Amounts On Reminder Header.
        ReminderHeader.CalcFields("Additional Fee", "VAT Amount");
        ReminderHeader.TestField("Additional Fee", ReminderLine.Amount);
        ReminderHeader.TestField("VAT Amount", ReminderLine."VAT Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyReminderHeaderAdditionalFeeAndVATAmountWithLineTypeNotDue()
    var
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
    begin
        // Test Additional Fee and VAT Amounts on Reminder Header when Reminder Line is created with Line Type Not Due.

        // Setup: Insert Reminder Header with Customer No.
        Initialize();
        InsertReminderHeader(ReminderHeader);

        // Exercise: Insert Reminder Line with Line Type Not Due.
        AddReminderLine(ReminderLine, ReminderHeader."No.", ReminderLine.Type::"G/L Account", ReminderLine."Line Type"::"Not Due");

        // Verify: Verify Additional Fee and VAT Amounts On Reminder Header.
        ReminderHeader.CalcFields("Additional Fee", "VAT Amount");
        ReminderHeader.TestField("Additional Fee", 0);
        ReminderHeader.TestField("VAT Amount", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyReminderLineAmountsForDiffrentLineTypes()
    var
        ReminderLine: Record "Reminder Line";
    begin
        // Test Amount,VATAmount and Remaining Amounts on Reminder Lines when Reminder Lines are created with Different Line Type Options.

        // Setup.
        Initialize();
        // Exercise: Insert Reminder Lines with Different Line Types and calculate Amounts.
        AddReminderLine(ReminderLine, '', ReminderLine.Type::"Customer Ledger Entry", ReminderLine."Line Type"::"Reminder Line");
        AddReminderLine(ReminderLine, '', ReminderLine.Type::"Customer Ledger Entry", ReminderLine."Line Type"::"Not Due");
        AddReminderLine(ReminderLine, '', ReminderLine.Type::"G/L Account", ReminderLine."Line Type"::"Reminder Line");

        ReminderLine.SetRange("Line Type", ReminderLine."Line Type"::"Reminder Line");
        ReminderLine.CalcSums(Amount, "VAT Amount", "Remaining Amount");
        ReminderLine.TestField(Amount, ReminderLine.Amount);
        ReminderLine.TestField("VAT Amount", ReminderLine."VAT Amount");
        ReminderLine.TestField("Remaining Amount", ReminderLine."Remaining Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateReminderForCustomerLedgerEntriesWithDifferentLevelWhenUseHeaderLevelTrue()
    var
        Customer: Record Customer;
        ReminderHeader: Record "Reminder Header";
        DocumentDate: Date;
        DueDate: Date;
        ReminderLevelGracePeriod: DateFormula;
    begin
        // Test No. Of Reminders for customer ledger entries with  different level are correct when option "Use Header Level" = TRUE.

        // Setup: Create a Customer and Reminder Terms with two levels attached to it. Create and Post two Sales Invoices with different Due Date for the Customer.
        SetupAndPostSalesInvoice(Customer, DocumentDate, '', '');
        CreateReminderLevel(ReminderLevelGracePeriod, Customer."Reminder Terms Code");
        DueDate := CalcDate('<' + Format(LibraryRandom.RandInt(3)) + 'D>', DocumentDate);
        CreateAndPostSalesInvoiceWithUpdateDueDate(Customer."No.", DueDate);

        // Create Reminder for the Customer through batch job on a Date after Grace Period. Issue the Reminder.
        CreateReminder(Customer."No.", DocumentDate, false); // Document Date need to between the Due Date of two Sales Invoices and "Use Header Level" = FALSE
        IssueReminder(DocumentDate);

        // Exercise: Create Reminder for the Customer with "Use Header Level" = TRUE.
        CreateReminder(Customer."No.", CalcDate(ReminderLevelGracePeriod, DueDate), true); // Document Date need to greater than the Due Date of two Sales Invoices.
        FindReminderHeader(ReminderHeader, Customer."No.");

        // Verify: Verify No. Of Reminders field on Reminder Lines.
        VerifyNoOfRemindersOnReminderLine(ReminderHeader."No.", ReminderHeader."Reminder Level");
    end;

    [Scope('OnPrem')]
    procedure AdditionalFeeLineReminderReport()
    var
        Customer: Record Customer;
        ReminderHeader: Record "Reminder Header";
        IssuedReminderNo: Code[20];
        AdditionalFee: Decimal;
        Amount: Decimal;
        CurrencyCode: Code[10];
        DocumentDate: Date;
    begin
        // [SCENARIO 297945] Additional Fee is printed with Issued Reminder when the additional fee amount is non-zero
        Initialize();

        // [GIVEN] Created Customer with Currency "USD" and Reminder Terms attached to it
        // [GIVEN] Created and Posted Sales Invoice for the Customer with Currency "USD" selected
        // [GIVEN] Created Reminder for the Customer after Grace Period Date.
        CurrencyCode := CreateCurrency();
        AdditionalFee := SetupAndPostSalesInvoice(Customer, DocumentDate, CurrencyCode, CurrencyCode);
        Amount := Round(LibraryERM.ConvertCurrency(AdditionalFee, '', CurrencyCode, WorkDate()));

        // [GIVEN] Created Reminder "REM01" for the Customer after Grace Period Date.
        CreateReminder(Customer."No.", DocumentDate, false);
        FindReminderHeader(ReminderHeader, Customer."No.");

        // [GIVEN] Issued Reminder "IR01" Created from reminder "REM01"
        IssuedReminderNo := IssueReminderWithReminderHeader(ReminderHeader);

        // [WHEN] Print "IR01" with report "Reminder"
        PrintIssuedReminder(IssuedReminderNo);

        // [THEN] "Additional Fee" line is printed
        VerifyAdditionalFeeOnReminderReport(Amount, IssuedReminderNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateReminderForMultipleCustomerLedgerEntriesWithCalculateInterestEnabledAndFinanceChargeInterestRate()
    var
        Customer: Record Customer;
        FinanceChargeInterestRate: Record "Finance Charge Interest Rate";
        FinanceChargeTerms: Record "Finance Charge Terms";
        ReminderHeader: Record "Reminder Header";
        ReminderLevel: Record "Reminder Level";
        DocumentDate: Date;
    begin
        // [SCENARIO 328296] Stan can create Reminder for multiple invoices when Reminder Level's Calculate Interest is True and Reminder terms have Finance Charge Interest Rate.
        Initialize();

        // [GIVEN] Two Sales invoices for Customer with Reminder Terms and Finance charge terms.
        SetupAndPostSalesInvoice(Customer, DocumentDate, '', '');
        CreateAndPostSalesInvoice(Customer."No.", '');

        // [GIVEN] Reminder Level with Calculate Interest set to True.
        GetReminderLevel(ReminderLevel, Customer."Reminder Terms Code");
        ReminderLevel.Validate("Calculate Interest", true);
        ReminderLevel.Modify();

        // [GIVEN] Reminder terms with Finance Charge Interest Rate.
        LibraryERM.CreateFinanceChargeTerms(FinanceChargeTerms);
        FinanceChargeTerms.Validate("Interest Period (Days)", 3);
        FinanceChargeTerms.Validate("Interest Rate", 3);
        FinanceChargeTerms.Validate("Add. Line Fee in Interest", true);
        FinanceChargeTerms.Modify(true);
        CreateFinanceChargeInterestRates(FinanceChargeInterestRate, FinanceChargeTerms.Code, DocumentDate - 4);
        Customer.Validate("Fin. Charge Terms Code", FinanceChargeTerms.Code);
        Customer.Modify(true);

        // [WHEN] Create Reminder using REP188 "Create Reminders".
        CreateReminder(Customer."No.", DocumentDate, false);

        // [THEN] Reminder is created.
        FindReminderHeader(ReminderHeader, Customer."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerCreateReminderCheckAutoInsertReminderNo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Customer: Record Customer;
        Reminder: TestPage Reminder;
        CustomerList: TestPage "Customer List";
    begin
        // [FEATURE] [Reminder]
        // [SCENARIO 334720] The new reminder is created from Customer List
        Initialize();

        // [GIVEN] The New Customer with outstanding balance was created
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));
        Customer.Get(SalesHeader."Sell-to Customer No.");
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [GIVEN] Customer List page was run
        CustomerList.OpenEdit();
        CustomerList.FILTER.SetFilter("No.", Customer."No.");
        CustomerList.First();
        Reminder.Trap();

        // [WHEN] "New Reminder" action is running
        CustomerList.NewReminder.Invoke();

        // [THEN] Reminder No. field is automatically inserted
        Assert.AreNotEqual(Reminder."No.".Value, '', 'Reminder."No."');

        Reminder.Close();
        CustomerList.Close();
    end;

    [Test]
    [HandlerFunctions('BatchCancelIssuedRemindersRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestIfReminderCanBeIssuedAfterCancellation()
    var
        Customer: Record Customer;
        Reminder: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        IssuedReminder: Record "Issued Reminder Header";
        GLSetup: Record "General Ledger Setup";
        ReminderNo: Code[20];
        IssueNo: Code[20];
        OldReminderLevel: Integer;
        DocumentDate: Date;
    begin
        // [SCENARIO 435427] To check if Reminder is getting issued after cancelation of previous reminder where reminder level are updated manually by user in first document
        Initialize();

        // [GIVEN] Create a customer and issue areminder document

        GLSetup.Get();
        GLSetup."Journal Templ. Name Mandatory" := false;
        GLSetup.Modify();

        CreateCustomer(Customer, '');
        SetupAndPostSalesInvoice(Customer, DocumentDate, '', '');
        CreateReminder(Customer."No.", DocumentDate, true);
        ReminderNo := GetReminderNo(Customer."No.");
        Reminder.Get(ReminderNo);
        OldReminderLevel := Reminder."Reminder Level";

        // [GIVEN] Update reminder Level on lines manually
        ReminderLine.SetRange("Reminder No.", ReminderNo);
        ReminderLine.SetFilter("No. of Reminders", '<>%1', 0);
        if ReminderLine.findset() then
            repeat
                ReminderLine.Validate("No. of Reminders", 4);
                ReminderLine.Modify(true);
            until ReminderLine.Next() = 0;

        // [GIVEN] Issue the reminder
        IssueNo := IssueReminderWithReminderHeader(Reminder);
        IssuedReminder.SetRange("No.", IssueNo);
        IssuedReminder.FindFirst();

        // [GIVEN] Cancel Issued Reminder
        RunCancelIssuedReminderReportWithParameters(IssuedReminder, true, true, DocumentDate);

        // [WHEN] a new Reminder is generated with same parameters
        CreateReminder(Customer."No.", DocumentDate, true);
        ReminderNo := GetReminderNo(Customer."No.");
        Reminder.Get(ReminderNo);

        // [THEN] New reminder should have previous reminder levels on line
        ReminderLine.SetRange("Reminder No.", Reminder."No.");
        ReminderLine.SetRange("No. of Reminders", OldReminderLevel);

        Assert.RecordIsNotEmpty(ReminderLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyDueDateInReminderFinChargeEntryAfterUpdateDueDateInCustLedgerEntry()
    var
        Customer: Record Customer;
        ReminderLevel: Record "Reminder Level";
        ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DueDate: Date;
        DocumentDate: Date;
        IssuedReminderNo: Code[20];
    begin
        // [SCENARIO: 461162] The Due date in the Reminder/Fin Charge Entry is updated incorrectly when changing the Due date in the Customer Ledger Entry.
        Initialize();

        // [GIVEN] Setup: Create Customer, Reminder Term, Update Payment Terms, and Post Sales Invoice 
        CreateCustomer(Customer, '');
        DueDate := CreateAndPostSalesInvoice(Customer."No.", '');
        GetReminderLevel(ReminderLevel, Customer."Reminder Terms Code");
        DocumentDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', CalcDate(ReminderLevel."Grace Period", DueDate));

        // [GIVEN] Create and issue 1st reminder
        CreateReminder(Customer."No.", DocumentDate, false);
        IssuedReminderNo := IssueReminder(DocumentDate);

        // [GIVEN] Create and issue 2nd reminder
        DueDate := DocumentDate + LibraryRandom.RandIntInRange(10, 11);
        CreateReminder(Customer."No.", DueDate, false);
        IssuedReminderNo := IssueReminder(DueDate);

        // [GIVEN] Create and issue 3rd reminder
        DueDate := DocumentDate + LibraryRandom.RandIntInRange(14, 15);
        CreateReminder(Customer."No.", DueDate, false);
        IssuedReminderNo := IssueReminder(DueDate);

        // [WHEN] Update Due Date for posted Customer Ledger Entry
        DueDate := DocumentDate + LibraryRandom.RandIntInRange(16, 17);
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        CustLedgerEntry.FindLast();
        CustLedgerEntry.Validate("Due Date", DueDate);
        CustLedgerEntry.Modify(true);

        // [VERIFY] Verify Due Date in Reminder/Fin. Charge Entry should equals Cust. Ledger Entry - Due Date
        ReminderFinChargeEntry.SetRange(Type, ReminderFinChargeEntry.Type::Reminder);
        ReminderFinChargeEntry.SetRange("No.", IssuedReminderNo);
        ReminderFinChargeEntry.FindFirst();
        Assert.AreEqual(ReminderFinChargeEntry."Due Date", CustLedgerEntry."Due Date", ReminderDueDateErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyEmailOnReminderPageWhenCustomerHasNoContacts()
    var
        Customer: Record Customer;
        ReminderLevel: Record "Reminder Level";
        ReminderText: Record "Reminder Text";
        ReminderHeader: Record "Reminder Header";
        ReminderPage: TestPage Reminder;
        CustomerCard: TestPage "Customer Card";
        EMail: Text[80];
        DueDate: Date;
        DocumentDate: Date;
    begin
        // [SCENARIO 581797] [ALL-E] Field Email on Reminder is empty when customer does not have any contacts
        Initialize();

        // [GIVEN] Create Customer with E-Mail and Reminder Terms Code.
        CreateCustomer(Customer, '');
        Customer.Validate("Reminder Terms Code", CreateReminderTerms());
        EMail := 'test1@test.com';
        Customer.Modify(true);

        CustomerCard.OpenEdit();
        CustomerCard.GoToRecord(Customer);
        CustomerCard."E-Mail".SetValue(EMail);
        CustomerCard.Close();

        // [GIVEN] Create Reminder Level with Random Grace Period and Random Additional Fee.
        ReminderLevel.SetRange("Reminder Terms Code", Customer."Reminder Terms Code");
        ReminderLevel.FindFirst();
        LibraryERM.CreateReminderText(
            ReminderText, Customer."Reminder Terms Code",
            ReminderLevel."No.", ReminderText.Position::Ending, ReminderEndingText);

        // [WHEN] Post Sales Invoice and Create Reminder.
        DueDate := CreateAndPostSalesInvoice(Customer."No.", '');
        DocumentDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', CalcDate(ReminderLevel."Grace Period", DueDate));
        CreateReminder(Customer."No.", DocumentDate, false);

        // [THEN] Find Reminder Header for Customer and open Reminder Page.
        FindReminderHeader(ReminderHeader, Customer."No.");
        ReminderPage.OpenEdit();
        ReminderPage.GoToRecord(ReminderHeader);

        // [THEN] Verify E-Mail on Reminder Page.
        ReminderPage.ContactEmail.AssertEquals(EMail);
    end;

    [Test]
    procedure VerifyDueDateAfterUpdateDueDateInCustLedgerEntry()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        GLAccount: Record "G/L Account";
        ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry";
        ReminderLevel: Record "Reminder Level";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        DueDate: Date;
        DocumentDate: Date;
        IssuedReminderNo: Code[20];
    begin
        // [SCENARIO 598460] The Due date in created Reminder is updated incorrectly when changing the Due date in the Customer Ledger Entry.
        Initialize();

        // [GIVEN] Create Customer and VAT Posting Setup. 
        CreateCustomer(Customer, '');
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        GLAccount.Get(CustomerPostingGroup."Additional Fee Account");
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        GLAccount.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        GLAccount.Modify(true);

        LibraryERM.CreateVATPostingSetup(VATPostingSetup, Customer."VAT Bus. Posting Group", VATProductPostingGroup.Code);

        //[GIVEN] Create and post Sales Invoice.
        DueDate := CreateAndPostSalesInvoice(Customer."No.", '');
        GetReminderLevel(ReminderLevel, Customer."Reminder Terms Code");
        DocumentDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', CalcDate(ReminderLevel."Grace Period", DueDate));

        // [GIVEN] Create and Issue Reminder.
        CreateReminder(Customer."No.", DocumentDate, false);
        IssuedReminderNo := IssueReminder(DocumentDate);

        // [WHEN] Update Due Date in forward direction for Customer Ledger Entry.
        DueDate := DocumentDate + LibraryRandom.RandIntInRange(16, 17);
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        CustLedgerEntry.FindLast();
        CustLedgerEntry.Validate("Due Date", DueDate);
        CustLedgerEntry.Modify(true);

        // [VERIFY] Verify Due Date in Reminder/Fin. Charge Entry should be equal to Cust. Ledger Entry - Due Date.
        ReminderFinChargeEntry.SetRange(Type, ReminderFinChargeEntry.Type::Reminder);
        ReminderFinChargeEntry.SetRange("No.", IssuedReminderNo);
        ReminderFinChargeEntry.FindFirst();
        Assert.AreEqual(ReminderFinChargeEntry."Due Date", CustLedgerEntry."Due Date", ReminderDueDateErr);

        // [WHEN] Update Due Date in backward direction for Customer Ledger Entry.
        DueDate := DocumentDate - LibraryRandom.RandIntInRange(16, 17);
        CustLedgerEntry.Validate("Due Date", DueDate);
        CustLedgerEntry.Modify(true);

        // [VERIFY] Verify Due Date in Reminder/Fin. Charge Entry should be equal to Cust. Ledger Entry - Due Date.
        ReminderFinChargeEntry.SetRange(Type, ReminderFinChargeEntry.Type::Reminder);
        ReminderFinChargeEntry.SetRange("No.", IssuedReminderNo);
        ReminderFinChargeEntry.FindFirst();
        Assert.AreEqual(ReminderFinChargeEntry."Due Date", CustLedgerEntry."Due Date", ReminderDueDateErr);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        DocumentNoVisibility: Codeunit DocumentNoVisibility;
        FeatureKey: Record "Feature Key";
        FeatureKeyUpdateStatus: Record "Feature Data Update Status";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Issued Reminder Addnl Fee");
        // Clear global variable.
        Clear(ReminderLevelNo);
        DocumentNoVisibility.ClearState();
        LibraryVariableStorage.Clear();

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
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Issued Reminder Addnl Fee");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Issued Reminder Addnl Fee");
    end;

    local procedure AddReminderLine(var ReminderLine: Record "Reminder Line"; ReminderHeaderNo: Code[20]; ReminderType: Enum "Reminder Source Type"; ReminderLineType: Enum "Reminder Line Type")
    begin
        ReminderLine.Init();
        ReminderLine."Reminder No." := ReminderHeaderNo;
        ReminderLine."Line No." += 10000;
        ReminderLine.Type := ReminderType;
        ReminderLine."Line Type" := ReminderLineType;
        ReminderLine."Remaining Amount" := LibraryRandom.RandDec(100, 2);
        ReminderLine.Amount := LibraryRandom.RandDec(10, 2);
        ReminderLine."VAT Amount" := LibraryRandom.RandDec(5, 2);
        ReminderLine.Insert();
    end;

    local procedure SetupAndPostSalesInvoice(var Customer: Record Customer; var DocumentDate: Date; CurrencyCode: Code[10]; CurrencyCode2: Code[10]): Decimal
    var
        ReminderLevel: Record "Reminder Level";
        DueDate: Date;
    begin
        // Setup: Create a Customer with Currency and Reminder Terms attached to it. Create and Post Sales Invoice for the Customer with
        // Currency selected. Create Reminder for the Customer after Grace Period Date.
        CreateCustomer(Customer, CurrencyCode);
        GetReminderLevel(ReminderLevel, Customer."Reminder Terms Code");
        DueDate := CreateAndPostSalesInvoice(Customer."No.", CurrencyCode2);
        DocumentDate := CalcDate('<1D>', CalcDate(ReminderLevel."Grace Period", DueDate));
        exit(ReminderLevel."Additional Fee (LCY)");
    end;

    local procedure CreateAndPostSalesInvoice(CustomerNo: Code[20]; CurrencyCode: Code[10]): Date
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Take Random Quantity for Sales Invoice.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Currency Code", CurrencyCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        exit(SalesHeader."Due Date");
    end;

    local procedure CreateAndPostSalesInvoiceWithUpdateDueDate(CustomerNo: Code[20]; DueDate: Date)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // Take Random Quantity for Sales Invoice.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Due Date", DueDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(10));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateCustomer(var Customer: Record Customer; CurrencyCode: Code[10])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Validate("Reminder Terms Code", CreateReminderTerms());
        Customer.Modify(true);
    end;

    local procedure CreateFinanceChargeInterestRates(var FinanceChargeInterestRate: Record "Finance Charge Interest Rate"; FinanceChargeTermsCode: Code[10]; StartDate: Date)
    begin
        FinanceChargeInterestRate.Init();
        FinanceChargeInterestRate.Validate("Fin. Charge Terms Code", FinanceChargeTermsCode);
        FinanceChargeInterestRate.Validate("Start Date", StartDate);
        FinanceChargeInterestRate.Validate("Interest Rate", LibraryRandom.RandInt(10));
        FinanceChargeInterestRate.Validate("Interest Period (Days)", LibraryRandom.RandInt(100));
        FinanceChargeInterestRate.Insert(true);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Sales);
        GenJournalTemplate.SetRange(Recurring, false);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateAndPostGenJournalLine(var Customer: Record Customer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
    begin
        CreateCustomer(Customer, '');
        LibraryERM.CreateGLAccount(GLAccount);
        CreateGeneralJournalBatch(GenJournalBatch);

        // Use Random Amount because value is not important.
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, Customer."No.", LibraryRandom.RandDec(1000, 2));
        GenJournalLine.Validate("Document No.", GenJournalLine."Journal Batch Name" + Format(GenJournalLine."Line No."));
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateReminder(CustomerNo: Code[20]; DocumentDate: Date; UseHeaderLevel: Boolean)
    var
        Customer: Record Customer;
        CreateReminders: Report "Create Reminders";
    begin
        Clear(CreateReminders);
        Customer.SetRange("No.", CustomerNo);
        CreateReminders.SetTableView(Customer);
        CreateReminders.InitializeRequest(DocumentDate, DocumentDate, true, UseHeaderLevel, false);
        CreateReminders.UseRequestPage(false);
        CreateReminders.Run();
    end;

    local procedure CreateReminderLevel(var ReminderLevelGracePeriod: DateFormula; ReminderTermsCode: Code[10])
    var
        ReminderLevel: Record "Reminder Level";
    begin
        // Create Reminder Level with a Random Grace Period and Random Additional Fee.
        LibraryERM.CreateReminderLevel(ReminderLevel, ReminderTermsCode);
        Evaluate(ReminderLevel."Grace Period", '<' + Format(LibraryRandom.RandInt(10)) + 'D>');
        ReminderLevel.Validate("Additional Fee (LCY)", LibraryRandom.RandInt(10));
        ReminderLevel.Modify(true);
        ReminderLevelGracePeriod := ReminderLevel."Grace Period";
    end;

    local procedure CreateReminderTerms(): Code[10]
    var
        ReminderTerms: Record "Reminder Terms";
        ReminderLevelGracePeriod: DateFormula;
    begin
        LibraryERM.CreateReminderTerms(ReminderTerms);
        CreateReminderLevel(ReminderLevelGracePeriod, ReminderTerms.Code);
        exit(ReminderTerms.Code);
    end;

    local procedure CreateSuggestReminderManually(CustomerNo: Code[20]; CurrencyCode: Code[10]; DocumentDate: Date)
    var
        ReminderHeader: Record "Reminder Header";
    begin
        LibraryERM.CreateReminderHeader(ReminderHeader);
        ReminderHeader.Validate("Customer No.", CustomerNo);
        ReminderHeader.Validate("Document Date", DocumentDate);
        ReminderHeader.Validate("Currency Code", CurrencyCode);
        ReminderHeader.Modify(true);
        SuggestReminderManually(ReminderHeader."No.");
    end;

    local procedure FindCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.FindCurrency(Currency);
        exit(Currency.Code);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDec(1000, 2), LibraryRandom.RandDec(1000, 2));
        exit(Item."No.");
    end;

    local procedure FindReminderHeader(var ReminderHeader: Record "Reminder Header"; CustomerNo: Code[20])
    begin
        ReminderHeader.SetRange("Customer No.", CustomerNo);
        ReminderHeader.FindFirst();
    end;

    local procedure FindReminderLine(ReminderNo: Code[20])
    var
        ReminderLine: Record "Reminder Line";
    begin
        ReminderLine.SetRange("Reminder No.", ReminderNo);
        ReminderLine.FindFirst();
    end;

    local procedure GetReminderLevel(var ReminderLevel: Record "Reminder Level"; ReminderTermsCode: Code[10])
    begin
        ReminderLevel.SetRange("Reminder Terms Code", ReminderTermsCode);
        ReminderLevel.FindFirst();
    end;

    local procedure GetReminderNo(CustomerNo: Code[20]): Code[20]
    var
        ReminderHeader: Record "Reminder Header";
    begin
        ReminderHeader.SetRange("Customer No.", CustomerNo);
        ReminderHeader.FindFirst();
        exit(ReminderHeader."No.");
    end;

    local procedure InsertReminderHeader(var ReminderHeader: Record "Reminder Header")
    begin
        ReminderHeader.Init();
        ReminderHeader."No." := LibraryUtility.GenerateGUID();
        ReminderHeader.Insert();
    end;

    local procedure InsertReminderWithTwoLines(var ReminderHeader: Record "Reminder Header"; var ReminderLine: Record "Reminder Line"; ReminderType: Enum "Reminder Source Type"; ReminderLineType: Enum "Reminder Line Type")
    begin
        InsertReminderHeader(ReminderHeader);
        AddReminderLine(ReminderLine, ReminderHeader."No.", ReminderLine.Type::"Customer Ledger Entry",
          ReminderLine."Line Type"::"Reminder Line");
        AddReminderLine(ReminderLine, ReminderHeader."No.", ReminderType, ReminderLineType);
    end;

    local procedure IssueReminderWithReminderHeader(ReminderHeader: Record "Reminder Header") IssuedReminderNo: Code[20]
    var
        ReminderIssue: Codeunit "Reminder-Issue";
        NoSeries: Codeunit "No. Series";
    begin
        ReminderIssue.Set(ReminderHeader, false, ReminderHeader."Document Date");
        IssuedReminderNo := NoSeries.PeekNextNo(ReminderHeader."Issuing No. Series");
        LibraryERM.RunReminderIssue(ReminderIssue);
    end;

    local procedure IssueReminder(DocumentDate: Date) IssuedReminderNo: Code[20]
    var
        NoSeriesLine: Record "No. Series Line";
        ReminderHeader: Record "Reminder Header";
        SalesAndReceivablesSetup: Record "Sales & Receivables Setup";
        ReminderIssue: Codeunit "Reminder-Issue";
        NoSeries: Codeunit "No. Series";
    begin
        SalesAndReceivablesSetup.Get();
        NoSeriesLine.SetRange("Series Code", SalesAndReceivablesSetup."Reminder Nos.");
        NoSeriesLine.FindFirst();
        ReminderHeader.Get(NoSeriesLine."Last No. Used");
        IssuedReminderNo := NoSeries.PeekNextNo(ReminderHeader."Issuing No. Series");
        ReminderIssue.Set(ReminderHeader, false, DocumentDate);
        LibraryERM.RunReminderIssue(ReminderIssue);
    end;

    local procedure PrintIssuedReminder(IssuedReminderNo: Code[20])
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
        Reminder: Report Reminder;
    begin
        Commit();
        IssuedReminderHeader.Get(IssuedReminderNo);
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        IssuedReminderHeader.SetRecFilter();
        Reminder.SetTableView(IssuedReminderHeader);
        Reminder.SaveAsExcel(LibraryReportValidation.GetFileName());
        LibraryReportValidation.OpenExcelFile();
    end;

    local procedure SuggestReminderManually(ReminderHeaderNo: Code[20])
    var
        ReminderHeader: Record "Reminder Header";
        SuggestReminderLines: Report "Suggest Reminder Lines";
    begin
        ReminderHeader.SetRange("No.", ReminderHeaderNo);
        SuggestReminderLines.SetTableView(ReminderHeader);
        SuggestReminderLines.UseRequestPage(false);
        SuggestReminderLines.Run();
    end;

    local procedure SumRemainigLineAmounts(ReminderLine: Record "Reminder Line"; FieldNumber: Integer): Decimal
    begin
        ReminderLine.SetRange("Reminder No.", ReminderLine."Reminder No.");
        ReminderLine.SetRange("Line Type", ReminderLine."Line Type"::"Reminder Line");
        case FieldNumber of
            ReminderLine.FieldNo("Remaining Amount"):
                begin
                    ReminderLine.CalcSums("Remaining Amount");
                    exit(ReminderLine."Remaining Amount");
                end;
            ReminderLine.FieldNo(Amount):
                begin
                    ReminderLine.CalcSums(Amount);
                    exit(ReminderLine.Amount);
                end;
        end;
    end;

    local procedure ReminderHeaderWithRemainingAmount(ReminderLineType: Enum "Reminder Line Type")
    var
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
    begin
        // Setup: Create Reminder Header.
        Initialize();

        // Exercise: Insert Reminder Lines.
        InsertReminderWithTwoLines(ReminderHeader, ReminderLine, ReminderLine.Type::"Customer Ledger Entry", ReminderLineType);

        // Verify: Verify Remaining Amount On Reminder Header.
        ReminderHeader.CalcFields("Remaining Amount");
        ReminderHeader.TestField("Remaining Amount", SumRemainigLineAmounts(ReminderLine, ReminderLine.FieldNo("Remaining Amount")));
    end;

    local procedure ReminderHeaderWithIntrestAmount(ReminderLineType: Enum "Reminder Line Type")
    var
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
    begin
        // Setup: Create Reminder Header and Reminder Lines with Line Types.
        Initialize();

        // Exercise: Insert Reminder Lines.
        InsertReminderWithTwoLines(ReminderHeader, ReminderLine, ReminderLine.Type::"Customer Ledger Entry", ReminderLineType);

        // Verify: Verify Intrest Amount On Reminder Header.
        ReminderHeader.CalcFields("Interest Amount");
        ReminderHeader.TestField("Interest Amount", SumRemainigLineAmounts(ReminderLine, ReminderLine.FieldNo(Amount)));
    end;

    local procedure UpdateReminderTextBatch(ReminderHeader: Record "Reminder Header")
    var
        UpdateReminderText: Report "Update Reminder Text";
    begin
        Clear(UpdateReminderText);
        UpdateReminderText.SetTableView(ReminderHeader);
        UpdateReminderText.Run();
    end;

    local procedure VerifyReminderLine(ReminderNo: Code[20]; Amount: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        IssuedReminderLine: Record "Issued Reminder Line";
    begin
        GeneralLedgerSetup.Get();
        IssuedReminderLine.SetRange("Reminder No.", ReminderNo);
        IssuedReminderLine.SetRange(Type, IssuedReminderLine.Type::"G/L Account");
        IssuedReminderLine.SetFilter("Line Type", '<>%1', IssuedReminderLine."Line Type"::Rounding);
        IssuedReminderLine.FindFirst();
        Assert.AreNearlyEqual(
          Amount, IssuedReminderLine.Amount, GeneralLedgerSetup."Amount Rounding Precision", StrSubstNo(AmountError, Amount, ReminderNo));
    end;

    local procedure VerifyNoOfRemindersOnReminderLine(ReminderNo: Code[20]; NoOfReminders: Integer)
    var
        ReminderLine: Record "Reminder Line";
    begin
        ReminderLine.SetRange("Reminder No.", ReminderNo);
        ReminderLine.SetRange(Type, ReminderLine.Type::"Customer Ledger Entry");
        ReminderLine.FindSet();
        repeat
            Assert.AreEqual(NoOfReminders, ReminderLine."No. of Reminders", NoOfRemindersErr);
        until ReminderLine.Next() = 0;
    end;

    local procedure VerifyReminderDescription(ReminderNo: Code[20])
    var
        ReminderLine: Record "Reminder Line";
        Amount: Decimal;
    begin
        ReminderLine.SetRange("Reminder No.", ReminderNo);
        ReminderLine.FindSet();
        repeat
            Amount += (ReminderLine."Remaining Amount" + ReminderLine.Amount) * (1 + (ReminderLine."VAT %" / 100));
        until ReminderLine.Next() = 0;
        Assert.AreEqual(
          StrSubstNo(ReminderLineDescription, Format(Amount, 0, '<Precision,2><Standard Format,0>')), ReminderLine.Description,
          ErrorMustMatch);
    end;

    local procedure VerifyAdditionalFeeOnReminderReport(Amount: Decimal; IssuedReminderNo: Code[20])
    var
        RowNo: Integer;
        ColumnNo: Integer;
    begin
        LibraryReportValidation.OpenExcelFile();
        Assert.IsTrue(LibraryReportValidation.CheckIfValueExists('Additional Fee'), 'Additional Fee must be printed');
        LibraryReportValidation.FindRowNoColumnNoByValueOnWorksheet('Additional Fee', 1, RowNo, ColumnNo);
        ColumnNo := LibraryReportValidation.FindFirstColumnNoByValue('Remaining Amount');
        Assert.AreEqual(
          Format(Amount), LibraryReportValidation.GetValueFromSpecifiedCellOnWorksheet(1, RowNo, ColumnNo),
          StrSubstNo(AmountError, Amount, IssuedReminderNo));
    end;

    local procedure RunCancelIssuedReminderReportWithParameters(var IssuedReminderHeader: Record "Issued Reminder Header"; UseSameDocumentNo: Boolean; UseSamePostingDate: Boolean; NewPostingDate: Date)
    begin
        LibraryVariableStorage.Enqueue(UseSameDocumentNo);
        LibraryVariableStorage.Enqueue(UseSamePostingDate);
        LibraryVariableStorage.Enqueue(NewPostingDate);
        Commit();
        REPORT.RunModal(REPORT::"Cancel Issued Reminders", true, false, IssuedReminderHeader);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure UpdateReminderTextPageHandler(var UpdateReminderText: TestRequestPage "Update Reminder Text")
    begin
        UpdateReminderText.ReminderLevelNo.SetValue(ReminderLevelNo);
        UpdateReminderText.UpdateAdditionalFee.SetValue(false);
        UpdateReminderText.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BatchCancelIssuedRemindersRequestPageHandler(var BatchCancelIssuedReminders: TestRequestPage "Cancel Issued Reminders")
    var
        UseSameDocumentNo: Boolean;
        UseSamePostingDate: Boolean;
        NewPostingDate: Date;
    begin
        UseSameDocumentNo := LibraryVariableStorage.DequeueBoolean();
        UseSamePostingDate := LibraryVariableStorage.DequeueBoolean();
        NewPostingDate := LibraryVariableStorage.DequeueDate();
        BatchCancelIssuedReminders.UseSameDocumentNo.SetValue(UseSameDocumentNo);
        BatchCancelIssuedReminders.UseSamePostingDate.SetValue(UseSamePostingDate);
        if not UseSamePostingDate then
            BatchCancelIssuedReminders.NewPostingDate.SetValue(NewPostingDate);
        BatchCancelIssuedReminders.OK().Invoke();
    end;
}

