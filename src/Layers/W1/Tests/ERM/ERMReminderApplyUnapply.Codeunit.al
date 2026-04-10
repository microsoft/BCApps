codeunit 134012 "ERM Reminder Apply Unapply"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [ERM] [Reminder] [Sales]
        isInitialized := false;
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        RemainingAmountError: Label '%1 must be %2.';
        UnappliedError: Label '%1 %2 field must be true after Unapply entries.';
        WrongCustLedgEntryNoErr: Label 'Wrong Customer Ledger Entry No.';

    [Test]
    [Scope('OnPrem')]
    procedure ReminderAndCustLedgerEntries()
    var
        DummyReminderHeader: Record "Reminder Header";
        GenJournalLine: Record "Gen. Journal Line";
        CurrentDate: Date;
        ReminderNo: Code[20];
    begin
        // [SCENARIO 228341] Issue reminder after posted sales invoice and post customer payment
        // Covers documents TC_ID= 122638 AND 137017.
        Initialize();
        CurrentDate := WorkDate();

        // [GIVEN] Customer with "Country/Region Code" = "X"
        // [GIVEN] Posted sales invoice with Amount = 1000
        // [GIVEN] Create reminder "R". Suggest, issue reminder (issued reminder no. = "IR")
        // [WHEN] Post customer payment with Amount = 1000
        ReminderNo := CreateInvoiceReminder(GenJournalLine);

        // [THEN] Reminder "R" doesn't exist
        // [THEN] There is a Reminder "IR" VAT Entry with "Country/Region Code" = "X" (TFS 228341)
        // [THEN] There is a "Payment" customer ledger entry with "Remaining Amount" = 1000
        DummyReminderHeader.SetRange("No.", ReminderNo);
        Assert.RecordIsEmpty(DummyReminderHeader);
        VerifyReminderVATEntryCountryRegionCode(
          FindIssuedReminderNo(GenJournalLine."Account No."), GetCustomerCountryRegionCode(GenJournalLine."Account No."));
        VerifyCustLedgerEntryForRemAmt(GenJournalLine);

        // Cleanup: Roll back the previous Workdate.
        WorkDate := CurrentDate;
        ModifyReminderTerms(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ApplyAndUnapplyCustEntries()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrentDate: Date;
    begin
        // Covers documents TC_ID= 122639 AND 137018.
        // Check Customer Ledger Entry for Remaining Amount, Detailed Ledger Entry for Unapplied Entries after Post General
        // Journal Lines, Apply and Unapply Customer Ledger Entries.

        // Create Sales Invoice, Reminder and Issue it, Post General Journal Lines, Apply and unapply them and
        // Take backup for Current Workdate.
        Initialize();
        CurrentDate := WorkDate();
        CreateInvoiceReminder(GenJournalLine);
        ApplyAndPostCustomerEntry(GenJournalLine."Document No.", GenJournalLine.Amount);
        UnapplyCustLedgerEntry(GenJournalLine."Account No.", GenJournalLine."Document No.");

        // Verify: Detailed Ledger Entry for Unapplied Entries and Customer Ledger Entries for Remaining Amount.
        VerifyUnappliedDtldLedgEntry(GenJournalLine."Account No.", GenJournalLine."Document No.");
        VerifyCustLedgerEntryForRemAmt(GenJournalLine);

        // Cleanup: Roll back the previous Workdate.
        WorkDate := CurrentDate;
        ModifyReminderTerms(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure IssueSelectedLineUsingIssueReminderReport()
    var
        ReminderHeader: Record "Reminder Header";
        ReminderHeaderNo: Code[20];
        ReminderHeaderNo2: Code[20];
    begin
        // Check that Program allows Issuing the selected Reminder Header No.using Reminder No. Filter Field on Issue Reminder Report.

        // Setup: Create and Post Sales Orders and Create Remainder.
        Initialize();
        ReminderHeaderNo := CreateReminderForPostedSalesOrder();
        ReminderHeaderNo2 := CreateReminderForPostedSalesOrder();

        // Exercise: Run Issue Reminder Report for selected Reminder Header.
        ReminderHeader.SetRange("No.", ReminderHeaderNo);
        RunIssueReminder(ReminderHeader);

        // Verify: Check Selected Reminder is no more after Issuing and Other Reainder Header No. still exist on Reminder Header.
        asserterror ReminderHeader.Get(ReminderHeaderNo);
        ReminderHeader.Get(ReminderHeaderNo2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerLedgerEntryFactboxReminderPage()
    var
        ReminderLine: Record "Reminder Line";
        Reminder: TestPage Reminder;
        ExpectedResult: Text;
        CurrentDate: Date;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 213636] Page Reminder should contain factbox "Customer Ledger Entry" for Reminder Line
        Initialize();

        // [GIVEN] Reminder with Reminder Line
        CurrentDate := WorkDate();
        CreateReminderWithReminderLine(ReminderLine);

        // [WHEN] Open reminder page
        Reminder.Trap();
        Reminder.OpenView();
        Reminder.FILTER.SetFilter("No.", ReminderLine."Reminder No.");

        // [THEN] Factbox contains relevant information
        ExpectedResult := Reminder.Control9.FILTER.GetFilter("Entry No.");
        Assert.AreEqual(Format(ReminderLine."Entry No."), ExpectedResult, WrongCustLedgEntryNoErr);

        // Rollback
        WorkDate := CurrentDate;
        ModifyReminderTerms(false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerLedgerEntryFactboxIssuedReminderPage()
    var
        ReminderLine: Record "Reminder Line";
        IssuedReminderLine: Record "Issued Reminder Line";
        IssuedReminder: TestPage "Issued Reminder";
        ExpectedResult: Text;
        CurrentDate: Date;
    begin
        // [FEATURE] [UI]
        // [SCENARIO 213636] Page Issued Reminder should contain factbox "Customer Ledger Entry" for Reminder Line
        Initialize();

        // [GIVEN] Reminder with Reminder Line
        CurrentDate := WorkDate();
        CreateReminderWithReminderLine(ReminderLine);
        IssueReminder(ReminderLine."Document No.");
        IssuedReminderLine.SetRange("Document No.", ReminderLine."Document No.");
        IssuedReminderLine.FindFirst();

        // [WHEN] Open reminder page
        IssuedReminder.Trap();
        IssuedReminder.OpenView();
        IssuedReminder.FILTER.SetFilter("No.", IssuedReminderLine."Reminder No.");

        // [THEN] Factbox contains relevant information
        ExpectedResult := IssuedReminder.Control3.FILTER.GetFilter("Entry No.");
        Assert.AreEqual(Format(IssuedReminderLine."Entry No."), ExpectedResult, WrongCustLedgEntryNoErr);

        // Rollback
        WorkDate := CurrentDate;
        ModifyReminderTerms(false);
    end;

    local procedure Initialize()
    var
        FeatureKey: Record "Feature Key";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Reminder Apply Unapply");
        LibrarySetupStorage.Restore();

        if FeatureKey.Get('ReminderTermsCommunicationTexts') then begin
            FeatureKey.Enabled := FeatureKey.Enabled::None;
            FeatureKey.Modify();
        end;
        // Lazy Setup.
        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Reminder Apply Unapply");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        LibrarySetupStorage.SaveSalesSetup();
        LibrarySetupStorage.SaveGeneralLedgerSetup();
        isInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Reminder Apply Unapply");
    end;

    local procedure ApplyAndPostCustomerEntry(DocumentNo: Code[20]; AmountToApply: Decimal)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, DocumentNo);
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, AmountToApply);
        CustLedgerEntry2.SetRange("Document Type", CustLedgerEntry2."Document Type"::Invoice);
        CustLedgerEntry2.SetRange("Customer No.", CustLedgerEntry."Customer No.");
        CustLedgerEntry2.SetRange(Open, true);
        CustLedgerEntry2.FindSet();
        repeat
            CustLedgerEntry2.CalcFields("Remaining Amount");
            CustLedgerEntry2.Validate("Amount to Apply", CustLedgerEntry2."Remaining Amount");
            CustLedgerEntry2.Modify(true);
        until CustLedgerEntry2.Next() = 0;

        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    local procedure CreateInvoiceReminder(var GenJournalLine: Record "Gen. Journal Line") ReminderNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        OrderNo: Code[20];
    begin
        // Setup.
        ModifyReminderTerms(true);
        CreateSalesInvoice(SalesHeader);

        // Exercise: Post Sales Invoice, Create and Issue Reminder then Create and Post General Journal Lines.
        OrderNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        CreateReminder(OrderNo, SalesHeader."Sell-to Customer No.");
        ReminderNo := IssueReminder(OrderNo);
        CreateGeneralJournalLines(GenJournalLine, SalesHeader."Sell-to Customer No.", -CalculateTotalAmount(OrderNo));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(ReminderNo);
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        Counter: Integer;
    begin
        // Random Quantity for Sales Invoice.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer());
        for Counter := 1 to 2 * LibraryRandom.RandInt(3) do
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, CreateItem(), LibraryRandom.RandInt(100));
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
        PaymentMethod: Record "Payment Method";
        ReminderTerms: Record "Reminder Terms";
        CountryRegion: Record "Country/Region";
    begin
        ReminderTerms.FindFirst();
        LibrarySales.CreateCustomer(Customer);
        LibraryERM.CreatePaymentMethod(PaymentMethod);
        LibraryERM.CreateCountryRegion(CountryRegion);
        Customer.Validate("Payment Method Code", PaymentMethod.Code);
        Customer.Validate("Reminder Terms Code", ReminderTerms.Code);
        Customer.Validate("Country/Region Code", CountryRegion.Code);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateGeneralJournalLines(var GenJournalLine: Record "Gen. Journal Line"; CustomerNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, CustomerNo, Amount);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Unit Price", LibraryRandom.RandInt(100));
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure ModifyReminderTerms(BooleanValue: Boolean)
    var
        ReminderTerms: Record "Reminder Terms";
    begin
        ReminderTerms.FindFirst();
        ReminderTerms.Validate("Post Interest", BooleanValue);
        ReminderTerms.Validate("Post Additional Fee", BooleanValue);
        ReminderTerms.Modify(true);
        ModifyReminderLevel(BooleanValue, ReminderTerms.Code);
    end;

    local procedure ModifyReminderLevel(CalculateInterest: Boolean; ReminderTermsCode: Code[20])
    var
        ReminderLevel: Record "Reminder Level";
    begin
        ReminderLevel.SetRange("Reminder Terms Code", ReminderTermsCode);
        ReminderLevel.FindFirst();
        ReminderLevel.Validate("Calculate Interest", CalculateInterest);
        ReminderLevel.Modify(true);
    end;

    local procedure CreateReminder(DocumentNo: Code[20]; CustomerNo: Code[20])
    var
        ReminderHeader: Record "Reminder Header";
        ReminderLevel: Record "Reminder Level";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        CustLedgEntryLineFeeOn: Record "Cust. Ledger Entry";
        ReminderMake: Codeunit "Reminder-Make";
    begin
        Customer.Get(CustomerNo);
        ReminderLevel.SetRange("Reminder Terms Code", Customer."Reminder Terms Code");
        ReminderLevel.FindFirst();

        // Set Workdate according to Reminder Level with Grace Period and Add 1 day.
        WorkDate := CalcDate('<1D>', CalcDate(ReminderLevel."Grace Period", WorkDate()));
        ReminderHeader.Init();
        ReminderHeader.Insert(true);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.FindFirst();
        ReminderMake.Set(Customer, CustLedgerEntry, ReminderHeader, false, false, CustLedgEntryLineFeeOn);
        ReminderMake.Code();
    end;

    local procedure CreateReminderForPostedSalesOrder(): Code[20]
    var
        ReminderLine: Record "Reminder Line";
    begin
        CreateReminderWithReminderLine(ReminderLine);
        exit(ReminderLine."Reminder No.");
    end;

    local procedure CreateReminderWithReminderLine(var ReminderLine: Record "Reminder Line")
    var
        SalesHeader: Record "Sales Header";
        PostedSalesDocumentNo: Code[20];
    begin
        CreateSalesInvoice(SalesHeader);
        PostedSalesDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        CreateReminder(PostedSalesDocumentNo, SalesHeader."Sell-to Customer No.");
        ReminderLine.SetRange("Document Type", ReminderLine."Document Type"::Invoice);
        ReminderLine.SetRange("Document No.", PostedSalesDocumentNo);
        ReminderLine.FindFirst();
    end;

    local procedure FindIssuedReminderNo(CustomerNo: Code[20]): Code[20]
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        IssuedReminderHeader.SetRange("Customer No.", CustomerNo);
        IssuedReminderHeader.FindFirst();
        exit(IssuedReminderHeader."No.");
    end;

    [Scope('OnPrem')]
    procedure GetCustomerCountryRegionCode(CustomerNo: Code[20]): Code[10]
    var
        Customer: Record Customer;
    begin
        Customer.Get(CustomerNo);
        exit(Customer."Country/Region Code");
    end;

    local procedure IssueReminder(DocumentNo: Code[20]): Code[20]
    var
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
    begin
        ReminderLine.SetRange("Document Type", ReminderLine."Document Type"::Invoice);
        ReminderLine.SetRange("Document No.", DocumentNo);
        ReminderLine.FindFirst();
        ReminderHeader.SetRange("No.", ReminderLine."Reminder No.");
        RunIssueReminder(ReminderHeader);
        exit(ReminderLine."Reminder No.");
    end;

    local procedure CalculateTotalAmount(OrderNo: Code[20]): Decimal
    var
        Customer: Record Customer;
        SalesInvoiceHeader: Record "Sales Invoice Header";
        ReminderLevel: Record "Reminder Level";
    begin
        SalesInvoiceHeader.Get(OrderNo);
        Customer.Get(SalesInvoiceHeader."Sell-to Customer No.");
        ReminderLevel.SetRange("Reminder Terms Code", Customer."Reminder Terms Code");
        ReminderLevel.FindFirst();
        SalesInvoiceHeader.CalcFields(Amount);
        exit(SalesInvoiceHeader.Amount + ReminderLevel."Additional Fee (LCY)");
    end;

    local procedure UnapplyCustLedgerEntry(CustomerNo: Code[20]; DocumentNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.FindLast();
        LibraryERM.UnapplyCustomerLedgerEntry(CustLedgerEntry);
    end;

    local procedure RunIssueReminder(var ReminderHeader: Record "Reminder Header")
    var
        IssueReminders: Report "Issue Reminders";
    begin
        IssueReminders.SetTableView(ReminderHeader);
        IssueReminders.UseRequestPage(false);
        IssueReminders.Run();
    end;

    local procedure VerifyUnappliedDtldLedgEntry(CustomerNo: Code[20]; DocumentNo: Code[20])
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::Application);
        DetailedCustLedgEntry.SetRange("Document No.", DocumentNo);
        DetailedCustLedgEntry.SetRange("Customer No.", CustomerNo);
        DetailedCustLedgEntry.FindSet();
        repeat
            Assert.IsTrue(DetailedCustLedgEntry.Unapplied, StrSubstNo(UnappliedError, DetailedCustLedgEntry.TableCaption(),
                DetailedCustLedgEntry.Unapplied));
        until DetailedCustLedgEntry.Next() = 0;
    end;

    local procedure VerifyCustLedgerEntryForRemAmt(GenJournalLine: Record "Gen. Journal Line")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        CustLedgerEntry.SetRange("Document Type", GenJournalLine."Document Type");
        CustLedgerEntry.SetRange("Document No.", GenJournalLine."Document No.");
        CustLedgerEntry.SetRange("Customer No.", GenJournalLine."Account No.");
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields("Remaining Amount");
        Assert.AreNearlyEqual(GenJournalLine.Amount, CustLedgerEntry."Remaining Amount", GeneralLedgerSetup."Amount Rounding Precision",
          StrSubstNo(RemainingAmountError, CustLedgerEntry."Remaining Amount", GenJournalLine.Amount));
    end;

    local procedure VerifyReminderVATEntryCountryRegionCode(DocumentNo: Code[20]; ExpectedCountryRegionCode: Code[10])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Reminder);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        VATEntry.TestField("Country/Region Code", ExpectedCountryRegionCode);
    end;
}

