codeunit 134375 "ERM Reminders With Min Amount"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [ERM] [Reminder] [Minimum Amount]
        IsInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        ExpectedMessage: Label 'The Credit Memo doesn''t have a Corrected Invoice No. Do you want to continue?';

    [Test]
    [Scope('OnPrem')]
    procedure ReminderAboveMinimumAmount()
    var
        Customer: Record Customer;
        ReminderHeaderNo: Code[20];
    begin
        // Covers Document TFS_TC_ID = 9054 and 9055.
        // Check that Reminder lines Exist after Posting Sales Invoice with above Minimum Amount.

        // Setup, Create and Suggest Reminder after creating and Posting Sales Invoice.
        ReminderHeaderNo := CreateReminderFromSalesInvoice(Customer, false);

        // Verify: Verify that the Reminder Lines Exists after Suggesting Lines from Reminder Header.
        VerifyReminderLines(ReminderHeaderNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ReminderBelowMinimumAmount()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        ReminderTerms: Record "Reminder Terms";
        SalesInvoiceLine: Record "Sales Invoice Line";
        ReminderHeaderNo: Code[20];
    begin
        // Covers Document TFS_TC_ID = 9054 and 9056.
        // Check that Reminder lines Exist after Posting Sales Credit Memo with below Minimum Amount.

        // Setup, Create and Suggest Reminder after creating and Posting Sales Invoice.
        CreateReminderFromSalesInvoice(Customer, false);

        // Exercise: Create a Sales Credit Memo and take Unit Price less than Reminder Terms Minimum Amount to generate Reminder Lines.
        // Post Credit Memo and Create Reminder.
        ReminderTerms.Get(Customer."Reminder Terms Code");
        SalesInvoiceLine.SetRange("Sell-to Customer No.", Customer."No.");
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);
        SalesInvoiceLine.FindFirst();
        CreateSalesCreditMemo(SalesHeader, Customer."No.", ReminderTerms."Minimum Amount (LCY)" - 1, SalesInvoiceLine.Quantity);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        ExecuteUIHandler();
        ReminderHeaderNo := CreateReminder(Customer."No.", false, '', false, true);

        // Verify: Verify that the Reminder Lines Exists after Suggesting Lines from Reminder Header.
        VerifyReminderLines(ReminderHeaderNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderOnMinimumAmount()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        ReminderHeaderNo: Code[20];
    begin
        // Covers Document TFS_TC_ID = 9054 and 9057.
        // Check that Reminder lines Exist after Posting Sales Invoice on Minimum Amount.

        // Setup, Create and Suggest Reminder after creating and Posting Sales Invoice.
        CreateReminderFromSalesInvoice(Customer, false);

        // Exercise: Create a Sales Invoice with Random Unit Price between 0.001 to 0.099 and Quantity between 1 to 10 to make sure
        // Invoice value always be a decimal Amount less than 1.
        CreateSalesInvoice(SalesHeader, Customer."No.", true, LibraryRandom.RandInt(99) / 1000, LibraryRandom.RandInt(10));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        ReminderHeaderNo := CreateReminder(Customer."No.", false, '', false, true);

        // Verify: Verify that the Reminder Lines Exists after Suggesting Lines from Reminder Header.
        VerifyReminderLines(ReminderHeaderNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderFromGeneralJournalLine()
    var
        Customer: Record Customer;
        ReminderTerms: Record "Reminder Terms";
        GenJournalLine: Record "Gen. Journal Line";
        ReminderHeaderNo: Code[20];
    begin
        // Covers Document TFS_TC_ID = 9054 and 9058.
        // Check that Reminder lines Exist after Posting General Journal Line.

        // Setup: Create a new Customer without Currency.
        Initialize();
        CreateCustomer(Customer, false);

        // Exercise: Create General Journal Lines for the Customer with an Amount greater than Reminder Terms Minimum Amount.
        // Post the General Journal Lines. Create a Reminder and Suggest Reminder Lines.
        ReminderTerms.Get(Customer."Reminder Terms Code");
        CreateGeneralJournalLine(GenJournalLine, Customer."No.", ReminderTerms."Minimum Amount (LCY)" + LibraryRandom.RandInt(10));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        ReminderHeaderNo := CreateReminder(Customer."No.", true, GenJournalLine."Currency Code", true, false);

        // Verify: Verify that the Reminder Lines Exists after Suggesting Lines from Reminder Header.
        VerifyReminderLines(ReminderHeaderNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderWithEarlierDueDate()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        ReminderTerms: Record "Reminder Terms";
        ReminderHeaderNo: Code[20];
    begin
        // Covers Document TFS_TC_ID = 9054 and 9059.
        // Check that Reminder lines Exist after Posting Sales Invoice with earlier Due Date.

        // Setup: Create a new Customer without Currency.
        Initialize();
        CreateCustomer(Customer, false);

        // Exercise: Create a Sales Invoice with Due Date earlier than Order Date and Post It. Take Unit Price greater than
        // Reminder Term Minimum Amount and Random Quantity between 1 to 10, values are not important for Quantity. Create Reminder.
        ReminderTerms.Get(Customer."Reminder Terms Code");
        CreateSalesInvoice(
          SalesHeader, Customer."No.", true, ReminderTerms."Minimum Amount (LCY)" + LibraryRandom.RandInt(10),
          LibraryRandom.RandInt(10));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        ReminderHeaderNo := CreateReminder(Customer."No.", false, '', false, true);

        // Verify: Verify that the Reminder Lines Exists after Suggesting Lines from Reminder Header.
        VerifyReminderLines(ReminderHeaderNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderAboveMinimumAmountFCY()
    var
        Customer: Record Customer;
        ReminderHeaderNo: Code[20];
    begin
        // Covers Document TFS_TC_ID = 9054 and 9060.
        // Check that Reminder lines Exist after Posting Sales Invoice with FCY and above Minimum Amount.

        // Setup, Create and Suggest Reminder after creating and Posting Sales Invoice.
        ReminderHeaderNo := CreateReminderFromSalesInvoice(Customer, true);

        // Verify: Verify that the Reminder Lines Exists after Suggesting Lines from Reminder Header.
        VerifyReminderLines(ReminderHeaderNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderBelowMinimumAmountFCY()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        ReminderHeaderNo: Code[20];
    begin
        // Covers Document TFS_TC_ID = 9054 and 9061.
        // Check that Reminder lines Exist after Posting Sales Invoice with FCY and below Minimum Amount.

        // Setup, Create and Suggest Reminder after creating and Posting Sales Invoice.
        ReminderHeaderNo := CreateReminderFromSalesInvoice(Customer, true);

        // Exercise: Create a Sales Invoice with Random Unit Price between 0.001 to 0.099 and Quantity between 1 to 10 to make sure
        // Invoice value always be a decimal Amount less than 1. Post the Invoice and Create Reminder.
        CreateSalesInvoice(SalesHeader, Customer."No.", false, LibraryRandom.RandInt(99) / 1000, LibraryRandom.RandInt(10));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        ReminderHeaderNo := CreateReminder(Customer."No.", false, '', false, true);

        // Verify: Verify that the Reminder Lines Exists after Suggesting Lines from Reminder Header.
        VerifyReminderLines(ReminderHeaderNo);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Reminders With Min Amount");
        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Reminders With Min Amount");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Reminders With Min Amount");
    end;

    local procedure CreateReminderFromSalesInvoice(var Customer: Record Customer; WithCurrency: Boolean): Code[20]
    var
        SalesHeader: Record "Sales Header";
        ReminderTerms: Record "Reminder Terms";
        ReminderHeaderNo: Code[20];
    begin
        // Setup: Create Customer, Reminder Terms and Reminder Levels.
        Initialize();
        CreateCustomer(Customer, WithCurrency);

        // Exercise: Create Sales Invoice and Post It. Take Unit Price greater than Reminder Terms Minimum Amount.
        // Create and Suggest Reminder Lines.
        ReminderTerms.Get(Customer."Reminder Terms Code");
        CreateSalesInvoice(
          SalesHeader, Customer."No.", false, 1 + LibraryRandom.RandInt(10) * ReminderTerms."Minimum Amount (LCY)",
          LibraryRandom.RandInt(10));
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        ReminderHeaderNo := CreateReminder(Customer."No.", false, '', false, false);
        exit(ReminderHeaderNo);
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; EarlierDueDate: Boolean; UnitPrice: Decimal; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);

        // Update a Random Due Date on Sales Header that is before Document Date.
        if EarlierDueDate then begin
            SalesHeader.Validate("Due Date", CalcDate(Format(-LibraryRandom.RandInt(30)) + 'D', SalesHeader."Document Date"));
            SalesHeader.Modify(true);
        end;

        // Create Sales Line with Unit Price.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesCreditMemo(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; UnitPrice: Decimal; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        // Create a Sales Header.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);

        // Create Sales Line, Update Unit Price and Quantity to Ship on Sales Line.
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), Quantity);
        SalesLine.Validate("Unit Price", UnitPrice);
        SalesLine.Validate("Qty. to Ship", 0);  // Qty to Ship must be zero in Sales Credit Memo.
        SalesLine.Modify(true);
    end;

    local procedure CreateReminder(CustomerNo: Code[20]; UseCurrencyOnHeader: Boolean; CurrencyCode: Code[10]; OverdueEntriesOnly: Boolean; IncludeEntriesOnHold: Boolean): Code[20]
    var
        ReminderHeader: Record "Reminder Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgEntryLineFeeOn: Record "Cust. Ledger Entry";
        ReminderMake: Codeunit "Reminder-Make";
    begin
        // Create Reminder Header and Update Currency Code.
        CreateReminderHeader(ReminderHeader, CustomerNo);
        if UseCurrencyOnHeader then begin
            ReminderHeader.Validate("Currency Code", CurrencyCode);
            ReminderHeader.Modify(true);
        end;

        // Suggest Reminder Lines.
        ReminderMake.SuggestLines(ReminderHeader, CustLedgerEntry, OverdueEntriesOnly, IncludeEntriesOnHold, CustLedgEntryLineFeeOn);
        ReminderMake.Code();
        exit(ReminderHeader."No.");
    end;

    [Normal]
    local procedure CreateCustomer(var Customer: Record Customer; CurrencyCode: Boolean)
    begin
        // Create a New Customer and update Reminder Terms.
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Reminder Terms Code", CreateReminderTerms());
        if CurrencyCode then
            Customer.Validate("Currency Code", CreateCurrency());
        Customer.Modify(true);
    end;

    [Normal]
    local procedure CreateReminderTerms(): Code[10]
    var
        ReminderTerms: Record "Reminder Terms";
        Counter: Integer;
    begin
        // Create a new Reminder Term and take Random Minimum Amount Greater than 5.
        LibraryERM.CreateReminderTerms(ReminderTerms);
        ReminderTerms.Validate("Minimum Amount (LCY)", 5 * LibraryRandom.RandInt(10));
        ReminderTerms.Modify(true);

        // Create Levels for Reminder Term, Creat Random levels greater than 2. Minimum 2 Levels are required.
        for Counter := 1 to 2 * LibraryRandom.RandInt(5) do
            CreateReminderLevel(ReminderTerms.Code);
        exit(ReminderTerms.Code);
    end;

    local procedure CreateReminderLevel(ReminderTermsCode: Code[10])
    var
        ReminderLevel: Record "Reminder Level";
    begin
        // Create Reminder Level with Grace Period of Five Days and a Random Additional Fee between 1 to 5. Upper Boundary 5 is important.
        LibraryERM.CreateReminderLevel(ReminderLevel, ReminderTermsCode);
        Evaluate(ReminderLevel."Grace Period", '<5D>');
        ReminderLevel.Validate("Additional Fee (LCY)", LibraryRandom.RandInt(5));
        ReminderLevel.Modify(true);
    end;

    [Normal]
    local procedure CreateReminderHeader(var ReminderHeader: Record "Reminder Header"; CustomerNo: Code[20])
    begin
        LibraryERM.CreateReminderHeader(ReminderHeader);
        ReminderHeader.Validate("Customer No.", CustomerNo);
        ReminderHeader.Validate("Document Date", CalcDate('<3M>', WorkDate()));
        ReminderHeader.Modify(true);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        // Create General Journal Lines of Invoice Type.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
        GenJournalLine.Validate("Currency Code", CreateCurrency());
        GenJournalLine.Modify(true);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure VerifyReminderLines(ReminderNo: Code[20])
    var
        ReminderLine: Record "Reminder Line";
        Assert: Codeunit Assert;
    begin
        // Verify that Reminder Lines Exists after Suggesting Reminder Lines from Reminder Header.
        ReminderLine.SetRange("Reminder No.", ReminderNo);
        Assert.IsFalse(ReminderLine.IsEmpty, 'Reminder Lines must exist.');
    end;

    local procedure ExecuteUIHandler()
    begin
        // Generate Dummy message. Required for executing the test case successfully.
        if Confirm(StrSubstNo(ExpectedMessage)) then;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

