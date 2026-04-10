codeunit 134907 "ERM Invoice and Reminder"
{
    Permissions = TableData "Issued Reminder Header" = rimd,
                  TableData "Issued Reminder Line" = rimd,
                  TableData "Cust. Ledger Entry" = rimd,
                  TableData "Detailed Cust. Ledg. Entry" = rimd,
                  TableData "Feature Data Update Status" = rimd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [ERM] [Reminder] [Sales]
        IsInitialized := false;
    end;

    var
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        MIRHelperFunctions: Codeunit "MIR - Helper Functions";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        DueDateLbl: Label '<-%1D>', Locked = true;
        ReminderLineError: Label 'The %1 on the %2 and the %3 must be the same.';
        AmountError: Label 'Amount must be %1 in %2.';
        AmtDueLbl: Label 'You are receiving this email to formally notify you that payment owed by you is past due. The payment was due on %1. Enclosed is a copy of invoice with the details of remaining amount.', Comment = '%1 - Due Date';
        ProceedOnIssuingWithInvRoundingQst: Label 'The invoice rounding amount will be added to the reminder when it is posted according to invoice rounding setup.\Do you want to continue?';
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Table Caption';

    [Test]
    [Scope('OnPrem')]
    procedure CreateInvoiceAndModifyReminder()
    var
        ReminderHeader: Record "Reminder Header";
        SalesLine: Record "Sales Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DocumentNo: Code[20];
    begin
        // Check Reminder Line Error after Post Sales Invoice and Modify Reminder Header.

        // Setup: Create Sales Invoice, Reminder Header and Modify it with New Currency.
        Initialize();
        DocumentNo := CreateAndPostSalesInvoice(SalesLine);
        CreateReminderHeader(ReminderHeader, SalesLine."Sell-to Customer No.");
        ModifyReminderHeader(ReminderHeader);

        // Exercise: Create Reminder Line After Modify Reminder Header.
        asserterror CreateReminderLine(ReminderHeader."No.", DocumentNo);

        // Verify: Check Reminder Line Currency Error.
        Assert.AreEqual(
          StrSubstNo(ReminderLineError, ReminderHeader.FieldCaption("Currency Code"),
            ReminderHeader.TableCaption(), CustLedgerEntry.TableCaption()), GetLastErrorText, 'Error must be same.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateInvoiceAndReminder()
    var
        Currency: Record Currency;
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        SalesLine: Record "Sales Line";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        RemainingAmount: Decimal;
        DocumentNo: Code[20];
    begin
        // Check Reminder Line Remaining Amount after Post Sales Invoice.

        // Setup: Create Sales Invoice, Reminder Header and Line.
        Initialize();
        DocumentNo := CreateAndPostSalesInvoice(SalesLine);

        // Exercise: Create Reminder Header and Line.
        CreateReminderHeader(ReminderHeader, SalesLine."Sell-to Customer No.");
        RemainingAmount := CreateReminderLine(ReminderHeader."No.", DocumentNo);

        // Verify: Check Remaining Amount on Reminder Line after Posting Sales Invoice.
        Currency.Get(ReminderHeader."Currency Code");
        SalesInvoiceHeader.Get(DocumentNo);
        SalesInvoiceHeader.CalcFields("Amount Including VAT");
        Assert.AreNearlyEqual(
          SalesInvoiceHeader."Amount Including VAT", RemainingAmount, Currency."Appln. Rounding Precision",
          StrSubstNo(AmountError, SalesInvoiceHeader."Amount Including VAT",
            ReminderLine.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestReminderLinesOutOfGracePeriodOverduesOnlyTrue()
    var
        Customer: Record Customer;
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
        ReminderLine: Record "Reminder Line";
        ReminderHeader: Record "Reminder Header";
        WeekDateFormula: DateFormula;
        InvoiceDocNo: array[2] of Code[20];
        ReminderPostingDate: array[2] of Date;
    begin
        // [FEATURE] [Payment Terms]
        Initialize();

        // [GIVEN] Reminder Terms "RT" with 3 levels where summary of "Due Date Calculation" = 3W
        // [GIVEN] Level[1] with "Grace Period" = 1W,"Due Date Calculation" = 1W
        // [GIVEN] Level[2] with "Grace Period" = <blank>,"Due Date Calculation" = 1W
        // [GIVEN] Level[3] with "Grace Period" = <blank>,"Due Date Calculation" = 1W
        // [GIVEN] Payment Terms "PT" where "Due Date Calculation" = 1W
        // [GIVEN] Customer "C" where "Payment Terms Code" = "PT" and "Reminder Terms Code" = "RT"
        Evaluate(WeekDateFormula, '<1W>');
        ReminderPostingDate[1] := CalcDate('<3W+1D>', WorkDate());
        ReminderPostingDate[2] := CalcDate('<1W+1D>', ReminderPostingDate[1]);
        CreateCustomerWithPaymentAndReminderTerms(Customer, WeekDateFormula);

        // [GIVEN] Posted invoice "I[1]" for customer "C" where "Posting Date" = 01/01/17
        InvoiceDocNo[1] := PostSalesInvoice(Customer."No.", WorkDate());

        // [GIVEN] Issued reminder for invoice "I[1]" where "Posting Date" = 22/01/17 (>3W from "I[1]"."Posting Date")
        RunCreateReminders(Customer, DummyCustLedgerEntry, false, ReminderPostingDate[1]);
        VerifyReminderLineTypeForDocument(ReminderLine, InvoiceDocNo[1], ReminderLine."Line Type"::"Reminder Line");

        ReminderHeader.SetRange("No.", ReminderLine."Reminder No.");
        REPORT.RunModal(REPORT::"Issue Reminders", false, true, ReminderHeader);

        // [GIVEN] Posted invoice "I[2]" for customer "C" where "Posting Date" = 06/01/17 (>"I[1]"."Posting Date" and <"I[1]"."Postsing Date" + 1W)
        InvoiceDocNo[2] := PostSalesInvoice(Customer."No.", CalcDate(WeekDateFormula, WorkDate()) - 1);

        // [GIVEN] Reminder for customer "C" with "Posting Date" = 01/02/2017 (>3W from "I[2]"."Posting Date")
        // [WHEN] Run report "Create Reminders" where "Overdues Only" = TRUE
        RunCreateReminders(Customer, DummyCustLedgerEntry, true, ReminderPostingDate[2]);

        // [THEN] Reminder lines for both invoices created with "Line Type" = "Reminder Line"
        VerifyReminderLineTypeForDocument(ReminderLine, InvoiceDocNo[1], ReminderLine."Line Type"::"Reminder Line");
        VerifyReminderLineTypeForDocument(ReminderLine, InvoiceDocNo[2], ReminderLine."Line Type"::"Reminder Line");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestReminderLinesOutOfGracePeriodOverduesOnlyFalse()
    var
        Customer: Record Customer;
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
        ReminderLine: Record "Reminder Line";
        ReminderHeader: Record "Reminder Header";
        WeekDateFormula: DateFormula;
        InvoiceDocNo: array[2] of Code[20];
        ReminderPostingDate: array[2] of Date;
    begin
        // [FEATURE] [Payment Terms]
        Initialize();

        // [GIVEN] Reminder Terms "RT" with 3 levels where summary of "Due Date Calculation" = 3W
        // [GIVEN] Level[1] with "Grace Period" = 1W,"Due Date Calculation" = 1W
        // [GIVEN] Level[2] with "Grace Period" = <blank>,"Due Date Calculation" = 1W
        // [GIVEN] Level[3] with "Grace Period" = <blank>,"Due Date Calculation" = 1W
        // [GIVEN] Payment Terms "PT" where "Due Date Calculation" = 1W
        // [GIVEN] Customer "C" where "Payment Terms Code" = "PT" and "Reminder Terms Code" = "RT"
        Evaluate(WeekDateFormula, '<1W>');
        ReminderPostingDate[1] := CalcDate('<3W+1D>', WorkDate());
        ReminderPostingDate[2] := CalcDate('<1W+1D>', ReminderPostingDate[1]);
        CreateCustomerWithPaymentAndReminderTerms(Customer, WeekDateFormula);

        // [GIVEN] Posted invoice "I[1]" for customer "C" where "Posting Date" = 01/01/17
        InvoiceDocNo[1] := PostSalesInvoice(Customer."No.", WorkDate());

        // [GIVEN] Issued reminder for invoice "I[1]" where "Posting Date" = 22/01/17 (>3W from "I[1]"."Posting Date")
        RunCreateReminders(Customer, DummyCustLedgerEntry, false, ReminderPostingDate[1]);
        VerifyReminderLineTypeForDocument(ReminderLine, InvoiceDocNo[1], ReminderLine."Line Type"::"Reminder Line");

        ReminderHeader.SetRange("No.", ReminderLine."Reminder No.");
        REPORT.RunModal(REPORT::"Issue Reminders", false, true, ReminderHeader);

        // [GIVEN] Posted invoice "I[2]" for customer "C" where "Posting Date" = 06/01/17 (>"I[1]"."Posting Date" and <"I[1]"."Postsing Date" + 1W)
        InvoiceDocNo[2] := PostSalesInvoice(Customer."No.", CalcDate(WeekDateFormula, WorkDate()) - 1);

        // [GIVEN] Reminder for customer "C" with "Posting Date" = 01/02/2017 (>3W from "I[2]"."Posting Date")
        // [WHEN] Run report "Create Reminders" where "Overdues Only" = FALSE
        RunCreateReminders(Customer, DummyCustLedgerEntry, false, ReminderPostingDate[2]);

        // [THEN] Reminder lines for both invoices created with "Line Type" = "Reminder Line"
        VerifyReminderLineTypeForDocument(ReminderLine, InvoiceDocNo[1], ReminderLine."Line Type"::"Reminder Line");
        VerifyReminderLineTypeForDocument(ReminderLine, InvoiceDocNo[2], ReminderLine."Line Type"::"Reminder Line");
    end;

    [Test]
    [HandlerFunctions('ReminderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AmtDueTextReminderReport()
    var
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        // [FEATURE] [Report]
        // [SCENARIO 254526] "AmtDueText" of report "Reminder" (117) contains text
        Initialize();

        // [GIVEN] Issued reminder with line
        MockIssuedReminder(IssuedReminderHeader);
        IssuedReminderHeader.SetRecFilter();
        Commit();

        // [WHEN] Run report "Reminder"
        REPORT.Run(REPORT::Reminder, true, false, IssuedReminderHeader);

        // [THEN] "AmtDueText" has value
        VerifyAmtDueTextAndRemaininAmt(IssuedReminderHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateRemindersWhenLastIssuedReminderLevelIsSpecifiedStartingFromZero()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        WeekDateFormula: DateFormula;
        InvoiceDocNo: array[3] of Code[20];
        ReminderPostingDate: array[3] of Date;
        InvoicePostingDate: array[3] of Date;
        Index: Integer;
    begin
        // [FEATURE] [Last Issued Reminder Level]
        // [SCENARIO 273651] Report "Create Reminders" respects "Last Issued Reminder Level" filter specified on request page for Cust. Ledger Entry when filter starts from '0'

        // [GIVEN] Customer with Reminder Terms having 3 levels
        PrepareInvoiceAndReminderPostingDates(InvoicePostingDate, ReminderPostingDate);
        Evaluate(WeekDateFormula, '<1W>');
        CreateCustomerWithPaymentAndReminderTerms(Customer, WeekDateFormula);

        // [GIVEN] Posted invoice "Inv1" and issued reminder with level 2
        // [GIVEN] Posted invoice "Inv2" and issued reminder with level 1
        for Index := 1 to ArrayLen(InvoiceDocNo) - 1 do
            PrepareInvoiceAndReminder(Customer, InvoiceDocNo[Index], InvoicePostingDate[Index], ReminderPostingDate[Index]);

        // [GIVEN] Posted invoice "Inv3"
        InvoiceDocNo[3] := PostSalesInvoice(Customer."No.", InvoicePostingDate[3]);

        // [GIVEN] Specified filter "0|2" for "Last Issued Reminder Level" in Cust. Ledger Entry
        CustLedgerEntry.SetFilter("Last Issued Reminder Level", '0|2');

        // [WHEN] Run report "Create Reminders"
        RunCreateReminders(Customer, CustLedgerEntry, true, ReminderPostingDate[3]);

        // [THEN] Reminder lines for Invoices "Inv1" and "Inv3" are created but Reminder Line for "Inv2" is not created
        VerifyReminderLinePresentsForSalesInvoice(InvoiceDocNo[1]);
        VerifyReminderLinePresentsForSalesInvoice(InvoiceDocNo[3]);
        VerifyReminderLineNotPresentForSalesInvoice(InvoiceDocNo[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateRemindersWhenLastIssuedReminderLevelIsSpecifiedNotStartingFromZero()
    var
        Customer: Record Customer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
        WeekDateFormula: DateFormula;
        InvoiceDocNo: array[3] of Code[20];
        ReminderPostingDate: array[3] of Date;
        InvoicePostingDate: array[3] of Date;
        Index: Integer;
    begin
        // [FEATURE] [Last Issued Reminder Level]
        // [SCENARIO 273651] Report "Create Reminders" respects "Last Issued Reminder Level" filter specified on request page for Cust. Ledger Entry when filter doesn't start from '0'

        // [GIVEN] Customer with Reminder Terms having 3 levels
        PrepareInvoiceAndReminderPostingDates(InvoicePostingDate, ReminderPostingDate);
        Evaluate(WeekDateFormula, '<1W>');
        CreateCustomerWithPaymentAndReminderTerms(Customer, WeekDateFormula);

        // [GIVEN] Posted invoice "Inv1" and issued reminder with level 2
        // [GIVEN] Posted invoice "Inv2" and issued reminder with level 1
        for Index := 1 to ArrayLen(InvoiceDocNo) - 1 do
            PrepareInvoiceAndReminder(Customer, InvoiceDocNo[Index], InvoicePostingDate[Index], ReminderPostingDate[Index]);

        // [GIVEN] Posted invoice "Inv3"
        InvoiceDocNo[3] := PostSalesInvoice(Customer."No.", InvoicePostingDate[3]);

        // [GIVEN] Specified filter "1.." for "Last Issued Reminder Level" in Cust. Ledger Entry
        CustLedgerEntry.SetFilter("Last Issued Reminder Level", '1..');

        // [WHEN] Run report "Create Reminders"
        RunCreateReminders(Customer, CustLedgerEntry, true, ReminderPostingDate[3]);

        // [THEN] Reminder lines for Invoices "Inv1" and "Inv2" are created but Reminder Line for Invoice "Inv3" is not created
        VerifyReminderLinePresentsForSalesInvoice(InvoiceDocNo[1]);
        VerifyReminderLinePresentsForSalesInvoice(InvoiceDocNo[2]);
        VerifyReminderLineNotPresentForSalesInvoice(InvoiceDocNo[3]);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SuggestLinesReportHandler')]
    procedure IssueReminderForMultipleInvoicesWithDifferentReminderLevels()
    var
        ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry";
        ReminderHeader: Record "Reminder Header";
        InvoicePostingDate: array[2] of Date;
        ReminderPostingDate: array[2] of Date;
        WeekDateFormula: DateFormula;
        InvoiceDocumentNo: Code[20];
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales Invoice]
        // [SCENARIO 284335] When Invoice "Inv1" posted, Reminder "Rem1" for "Inv1" issued, Invoice "Inv2" posted, Reminder "Rem2" for "Inv1" and "Inv2" issued
        // [SCENARIO 284335] Reminder/Fin. Charge entry for invoice "Inv2" has Interest Posted set to 'FALSE'
        Initialize();
        Evaluate(WeekDateFormula, '<1W>');

        // [GIVEN] Customer with Reminder Terms having 2 levels and "Post Interest" enabled for second level
        CustomerNo := CreateCustomerWithPaymentReminderFinChargeTerms(WeekDateFormula);

        InvoicePostingDate[1] := WorkDate();
        InvoicePostingDate[2] := CalcDate(WeekDateFormula, InvoicePostingDate[1]);
        ReminderPostingDate[1] := CalcDate(WeekDateFormula, InvoicePostingDate[2]);
        ReminderPostingDate[2] := CalcDate(WeekDateFormula, ReminderPostingDate[1]) + 1;

        // [GIVEN] Posted invoice "Inv1" and issued Reminder "Rem1" with level 1
        PostSalesInvoice(CustomerNo, InvoicePostingDate[1]);
        CreateReminderForDate(ReminderHeader, CustomerNo, ReminderPostingDate[1]);
        REPORT.RunModal(REPORT::"Issue Reminders", false, true, ReminderHeader);

        // [GIVEN]  Posted invoice "Inv2" and created Reminder "Rem2" with level 2 for "Inv1" and level 1 for "Inv2"
        InvoiceDocumentNo := PostSalesInvoice(CustomerNo, InvoicePostingDate[2]);
        CreateReminderForDate(ReminderHeader, CustomerNo, ReminderPostingDate[2]);

        // [WHEN] Reminder issued
        REPORT.RunModal(REPORT::"Issue Reminders", false, true, ReminderHeader);

        // [THEN] Reminder/Fin. Charge entry for invoice "Inv2" has Intereset Posted set to 'FALSE'
        ReminderFinChargeEntry.SetFilter("Document No.", InvoiceDocumentNo);
        ReminderFinChargeEntry.FindFirst();
        ReminderFinChargeEntry.TestField("Interest Posted", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SuggestReminderLinesWithCorrectCalculationReminderLevel()
    var
        Customer: Record Customer;
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
        ReminderLine: Record "Reminder Line";
        ReminderHeader: Record "Reminder Header";
        WeekDateFormula: DateFormula;
        InvoiceDocNo: array[3] of Code[20];
        ReminderPostingDate: array[3] of Date;
    begin
        // [FEATURE] [Payment Terms]
        Initialize();

        // [GIVEN] Reminder Terms "RT" with 3 levels where summary of "Due Date Calculation" = 3W
        // [GIVEN] Level[1] with "Grace Period" = 1W,"Due Date Calculation" = 1W, Fee = "F"
        // [GIVEN] Level[2] with "Grace Period" = <blank>,"Due Date Calculation" = 1W, Fee = 2*"F"
        // [GIVEN] Level[3] with "Grace Period" = <blank>,"Due Date Calculation" = 1W, Fee = 3*"F"
        // [GIVEN] Payment Terms "PT" where "Due Date Calculation" = 1W
        // [GIVEN] Customer "C" where "Payment Terms Code" = "PT" and "Reminder Terms Code" = "RT"
        Evaluate(WeekDateFormula, '<1W>');
        ReminderPostingDate[1] := CalcDate('<1M+5D>', WorkDate());
        ReminderPostingDate[2] := CalcDate('<1W+5D>', ReminderPostingDate[1]);
        ReminderPostingDate[3] := CalcDate('<1W>', ReminderPostingDate[2]);

        CreateCustomerWithPaymentAndReminderTerms(Customer, WeekDateFormula);

        // [GIVEN] Posted invoice "I[1]" for customer "C" where "Posting Date" = 01/01/17, "Due Date = 18/01/17
        InvoiceDocNo[1] := PostSalesInvoiceWithDueDate(Customer."No.", WorkDate(), CalcDate('<2W+4D>', WorkDate()));

        // [GIVEN] Posted invoice "I[2]" for customer "C" where "Posting Date" = 01/01/17, "Due Date = 12/02/17
        InvoiceDocNo[2] := PostSalesInvoiceWithDueDate(Customer."No.", WorkDate(), CalcDate('<1M+1W+5D>', WorkDate()));

        // [GIVEN] Issued reminder for invoice "I[1]" where "Posting Date" = 05/02/17
        RunCreateReminders(Customer, DummyCustLedgerEntry, false, ReminderPostingDate[1]);
        ReminderHeader.SetRange("No.", ReminderLine."Reminder No.");
        REPORT.RunModal(REPORT::"Issue Reminders", false, true, ReminderHeader);

        // [GIVEN] Issued reminder for invoice "I[2]" where "Posting Date" = 17/02/17
        RunCreateReminders(Customer, DummyCustLedgerEntry, false, ReminderPostingDate[2]);
        ReminderHeader.SetRange("No.", ReminderLine."Reminder No.");
        REPORT.RunModal(REPORT::"Issue Reminders", false, true, ReminderHeader);

        // [GIVEN] Reminder for customer "C" with "Posting Date" = 24/02/17
        // [WHEN] Run report "Create Reminders" where "Overdues Only" = FALSE
        RunCreateReminders(Customer, DummyCustLedgerEntry, false, ReminderPostingDate[3]);

        ReminderLine.SetRange("Document No.", InvoiceDocNo[1]);
        ReminderLine.FindFirst();
        ReminderHeader.SetRange("No.", ReminderLine."Reminder No.");
        ReminderHeader.FindFirst();
        ReminderHeader.CalcFields("Additional Fee");

        // [THEN] ReminderHeader."Reminder Level" is equal to 1.
        Assert.AreEqual(ReminderHeader."Reminder Level", 1, 'ReminderHeader."Reminder Level"');
    end;

    [Test]
    [HandlerFunctions('ReminderTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure TestReminderReportCalculateAmountCorrectly()
    var
        ReminderLine: array[2] of Record "Reminder Line";
        SalesLine: Record "Sales Line";
        ReminderHeader: Record "Reminder Header";
        DocumentNo: Code[20];
        RemainingAmount: Decimal;
        AdditionalFee: Decimal;
        InterestAmount: Decimal;
    begin
        // [SCENARIO 370031] Run report Reminder - Test for Reminder Header with additional fee
        Initialize();

        // [GIVEN] Created and posted Sales Invoice
        DocumentNo := CreateAndPostSalesInvoice(SalesLine);
        InterestAmount := LibraryRandom.RandInt(10);

        // [GIVEN] Created Reminder Header and Line.
        CreateReminderHeader(ReminderHeader, SalesLine."Sell-to Customer No.");
        LibraryERM.CreateReminderLine(ReminderLine[1], ReminderHeader."No.", ReminderLine[1].Type::"Customer Ledger Entry");
        ReminderLine[1].Validate("Document No.", DocumentNo);
        ReminderLine[1].Validate(Amount, InterestAmount);
        ReminderLine[1].Modify(true);
        RemainingAmount := ReminderLine[1]."Remaining Amount";

        // [GIVEN] Created Reminder Line for additional fee
        LibraryERM.CreateReminderLine(ReminderLine[2], ReminderHeader."No.", ReminderLine[2].Type::"G/L Account");
        AdditionalFee := LibraryRandom.RandInt(10);
        ReminderLine[2].Validate(Amount, AdditionalFee);
        ReminderLine[2].Modify(true);
        Commit();

        // [WHEN] Run report 122 "Reminder - Test"
        ReminderHeader.SetRecFilter();
        ReminderHeader.PrintRecords();

        // [THEN] Check Total is equal to sum of Remaining amount, Interest amount and additional fee
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('NNC_TotalLCY', RemainingAmount + InterestAmount + AdditionalFee);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReminderInvoiceRoundingStatistics()
    var
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Customer: Record Customer;
        ReminderStatistics: TestPage "Reminder Statistics";
        TotalAmount: Decimal;
    begin
        // [FEATURE] [Invoice Rounding] [Statistics]
        // [SCENARIO 369814] Reminder Statistics with Invoice Rounding
        Initialize();

        // [GIVEN] Amount Rounding Precision = 0.01, Invoice Rounding Precision = 0.1 in G/L Setup
        UpdateGLSetupInvRoundingPrecision();
        GeneralLedgerSetup.Get();

        // [GIVEN] Reminder with G/L Account Line = 1912.41
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Reminder Terms Code", CreateReminderTerms());
        Customer.Modify(true);
        CreateReminderHeader(ReminderHeader, Customer."No.");
        CreateReminderLineForInvRounding(
            ReminderLine, ReminderHeader, GeneralLedgerSetup."Amount Rounding Precision");

        ReminderHeader.CalcFields("Additional Fee", "Interest Amount");
        TotalAmount := ReminderHeader."Additional Fee" + ReminderHeader."Interest Amount";

        // [WHEN] Reminder Statistics is opened
        ReminderStatistics.Trap();
        PAGE.RUN(PAGE::"Reminder Statistics", ReminderHeader);

        // [THEN] Invoice Rounding Amount = -0.01, Total = 1912.41 on Statistics page
        ReminderStatistics.ReminderTotal.AssertEquals(TotalAmount);
        ReminderStatistics.InvoiceRoundingAmount.AssertEquals(
            Round(TotalAmount, GeneralLedgerSetup."Inv. Rounding Precision (LCY)") - TotalAmount);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerVerifyMsg')]
    [Scope('OnPrem')]
    procedure IssueReminderWithInvRoundingConfirmFalse()
    var
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Customer: Record Customer;
        IssuedReminderHeader: Record "Issued Reminder Header";
    begin
        // [FEATURE] [Invoice Rounding]
        // [SCENARIO 369814] Issue Reminder with Invoice Rounding confirmed No
        Initialize();

        // [GIVEN] Amount Rounding Precision = 0.01, Invoice Rounding Precision = 0.1 in G/L Setup
        UpdateGLSetupInvRoundingPrecision();
        GeneralLedgerSetup.Get();

        // [GIVEN] Reminder with G/L Account Line = 1912.41
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Reminder Terms Code", CreateReminderTerms());
        Customer.Modify(true);
        CreateReminderHeader(ReminderHeader, Customer."No.");
        CreateReminderLineForInvRounding(
            ReminderLine, ReminderHeader, GeneralLedgerSetup."Amount Rounding Precision");

        // [WHEN] Confirm 'No' when issue Reminder
        LibraryVariableStorage.Enqueue(ProceedOnIssuingWithInvRoundingQst);
        LibraryVariableStorage.Enqueue(False);
        IssueReminder(ReminderHeader."No.");

        // [THEN] Reminder is not issued
        IssuedReminderHeader.SetRange("Customer No.", ReminderHeader."Customer No.");
        AssertError IssuedReminderHeader.FindFirst();
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerVerifyMsg')]
    [Scope('OnPrem')]
    procedure IssueReminderWithInvRoundingConfirmTrue()
    var
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        GeneralLedgerSetup: Record "General Ledger Setup";
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedReminderLine: Record "Issued Reminder Line";
        Customer: Record Customer;
        InvRoundingAmountAmount: Decimal;
    begin
        // [FEATURE] [Invoice Rounding]
        // [SCENARIO 369814] Issue Finance Charge Memo with Invoice Rounding confirmed Yes
        Initialize();

        // [GIVEN] Amount Rounding Precision = 0.01, Invoice Rounding Precision = 0.1 in G/L Setup
        UpdateGLSetupInvRoundingPrecision();
        GeneralLedgerSetup.Get();

        // [GIVEN] Finance Charge Memo with G/L Accout Line = 1912.41
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Reminder Terms Code", CreateReminderTerms());
        Customer.Modify(true);
        CreateReminderHeader(ReminderHeader, Customer."No.");
        CreateReminderLineForInvRounding(
            ReminderLine, ReminderHeader, GeneralLedgerSetup."Amount Rounding Precision");

        ReminderHeader.CalcFields("Additional Fee", "Interest Amount");
        InvRoundingAmountAmount := ReminderHeader."Additional Fee" + ReminderHeader."Interest Amount";
        InvRoundingAmountAmount :=
            Round(InvRoundingAmountAmount, GeneralLedgerSetup."Inv. Rounding Precision (LCY)") - InvRoundingAmountAmount;

        // [WHEN] Confirm 'Yes' when issue Reminder
        LibraryVariableStorage.Enqueue(ProceedOnIssuingWithInvRoundingQst);
        LibraryVariableStorage.Enqueue(true);
        IssueReminder(ReminderHeader."No.");

        // [THEN] Invoice Rounding Amount is posted in issued reminder with Amount = -0.01
        IssuedReminderHeader.SetRange("Customer No.", ReminderHeader."Customer No.");
        IssuedReminderHeader.FindFirst();
        IssuedReminderLine.SetRange("Reminder No.", IssuedReminderHeader."No.");
        IssuedReminderLine.SetFilter("No.", '<>%1', ReminderLine."No.");
        IssuedReminderLine.FindFirst();
        IssuedReminderLine.TestField(Amount, InvRoundingAmountAmount);
        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LastIssuedReminderLevelShouldNotBeLessZeroWhenCancelReminder()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        IssuedReminderHeader: Record "Issued Reminder Header";
        IssuedReminderLine: Record "Issued Reminder Line";
        CancelIssuedReminder: Codeunit "Cancel Issued Reminder";
    begin
        // [FEATURE] [Last Issued Reminder Level]
        // [SCENARIO 404002] When cancelling Reminder value of "Last Issued Reminder Level" Customer Ledger Entries should not become less then zero
        Initialize();

        // [GIVEN] CLE with "Last Issued Reminder Level" = 0;
        MockCustLedgerEntry(CustLedgerEntry, LibrarySales.CreateCustomerNo(), CustLedgerEntry."Document Type"::Invoice, 0, WorkDate());

        // [GIVEN] Issued Reminder with line linked to CLE 
        MockIssuedReminder(IssuedReminderHeader);
        IssuedReminderHeader."Reminder Terms Code" := CreateReminderTerms();
        IssuedReminderHeader.Modify();
        IssuedReminderLine.SetRange("Reminder No.", IssuedReminderHeader."No.");
        IssuedReminderLine.FindFirst();
        IssuedReminderLine.Type := IssuedReminderLine.Type::"Customer Ledger Entry";
        IssuedReminderLine."Entry No." := CustLedgerEntry."Entry No.";
        IssuedReminderLine.Modify();

        // [WHEN] Cancel Issued Reminder
        CancelIssuedReminder.SetParameters(true, true, WorkDate(), true);
        CancelIssuedReminder.Run(IssuedReminderHeader);

        // [THEN] CLE "Last Issued Reminder Level" = 0;
        CustLedgerEntry.Find();
        CustLedgerEntry.TestField("Last Issued Reminder Level", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CancelIssuedFinChargeMemoWithIntersets()
    var
        IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header";
        GLEntry: Record "G/L Entry";
        CancelIssuedFinChargeMemo: Codeunit "Cancel Issued Fin. Charge Memo";
        ExpectedAmount: Decimal;
    begin
        // [FEATURE] [Cancel Finance Charge Memo] [Interest Rate]
        // [SCENARIO 411355] When cancel the Issued Finance Charge Memo with detailed interest line, then do not use the detailed interest lines 
        Initialize();

        // [GIVEN] Issued Finance Charge Memo with Detailed interest line
        CreateIssuedFinChargeMemoWithInterestLine(IssuedFinChargeMemoHeader);

        // [GIVEN] G/L Entry with Ammount = 100 and type = "Finance Charge Memo"
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::"Finance Charge Memo");
        GLEntry.SetRange("Document No.", IssuedFinChargeMemoHeader."No.");
        GLEntry.SetRange("Gen. Posting Type", GLEntry."Gen. Posting Type"::" ");
        GLEntry.FindFirst();
        ExpectedAmount := GLEntry.Amount;

        // [WHEN] Cancel Issued Finance Charge Memo
        CancelIssuedFinChargeMemo.SetParameters(true, false, WorkDate(), false);
        CancelIssuedFinChargeMemo.Run(IssuedFinChargeMemoHeader);

        // [THEN] G/L Entry with Amount = -100 and type = " "
        GLEntry.Reset();
        GLEntry.SetRange("Document No.", IssuedFinChargeMemoHeader."No.");
        GLEntry.SetRange("Document Type", GLEntry."Document Type"::" ");
        GLEntry.SetRange(Amount, -ExpectedAmount);
        GLEntry.FindFirst();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyReminderHeaderCompanyBankAccountCode()
    var
        BankAccount: Record "Bank Account";
        ReminderHeader: Record "Reminder Header";
        Customer: Record Customer;
    begin
        // [SCENARIO 486467] The Company Bank Account Code is not filled in the Reminder/Fin. Charge Memo even if you setup the bank with Use as Default for Currency.
        Initialize();

        // [GIVEN] Create a Customer and Update Reminder Terms.
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Reminder Terms Code", CreateReminderTerms());
        Customer.Modify(true);

        // [GIVEN] If Bank Account Not exists then Create a Bank Account.
        FindBankAccountDefaultForCurrency(BankAccount);

        // [GIVEN] Create a Reminder Order.
        CreateReminderHeader(ReminderHeader, Customer."No.");

        // [VERIFY] Verify: Default Bank Account is set in Company Bank Account Code on Reminder/Fin. Charge Memo
        Assert.AreEqual(
            BankAccount."No.",
            ReminderHeader."Company Bank Account Code",
            StrSubstNo(
                ValueMustBeEqualErr,
                ReminderHeader.FieldCaption("Company Bank Account Code"),
                BankAccount."No.",
                ReminderHeader.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('SuggestLinesReportHandler')]
    procedure MakeReminderWithDueDateFilter()
    var
        Customer: Record Customer;
        ReminderHeader: Record "Reminder Header";
        ReminderLine: Record "Reminder Line";
        WeekDateFormula: DateFormula;
        TotalReminderLines: Decimal;
        DueDateFilter: Text;
        DueDateFilterLbl: Label '..%1', Locked = true;
        ReminderLinesErr: Label 'Reminder Lines haven''t been created correctly.';
    begin
        // [REMINDER] [SUGGEST REMINDER LINES]
        // [SCENARIO 543492] Make reminder lines from customer ledger entries with applied due date filter
        Initialize();

        // [GIVEN] Create customer X, reminder term = X, payment term = X
        // [GIVEN] Create 5 Customer Ledger Entries
        // [GIVEN] Customer ledger entry 1, due date = workdate - 7D, remaining amount = 100
        // [GIVEN] Customer ledger entry 2, due date = workdate - 6D, remaining amount = 100
        // [GIVEN] Customer ledger entry 3, due date = workdate - 5D, remaining amount = 100
        // [GIVEN] Customer ledger entry 4, due date = workdate - 4D, remaining amount = 100
        // [GIVEN] Customer ledger entry 5, due date = workdate - 3D, remaining amount = 100
        Evaluate(WeekDateFormula, '<1W>');
        CreateCustomerWithPaymentAndReminderTerms(Customer, WeekDateFormula);
        CreateCustomerLedgerEntries(Customer."No.");

        // [GIVEN] Create reminder X, customer no. = X, document date = workdate
        ReminderHeader."No." := LibraryUtility.GenerateRandomCode(ReminderHeader.FieldNo("No."), Database::"Reminder Header");
        ReminderHeader.Validate("Customer No.", Customer."No.");
        ReminderHeader."Document Date" := WorkDate();
        ReminderHeader.Insert();

        // [GIVEN] Create due date for filtering = workdate - 3D
        DueDateFilter := StrSubstNo(DueDateFilterLbl, CalcDate(StrSubstNo(DueDateLbl, 3), WorkDate()));
        LibraryVariableStorage.Enqueue(DueDateFilter);

        // [WHEN] Run Suggest Reminder Lines, due date filter = workdate - 3D
        Commit();
        Report.RunModal(Report::"Suggest Reminder Lines", true, false, ReminderHeader);

        // [THEN] Reminder lines within due date filter are created
        ReminderLine.SetRange("Reminder No.", ReminderHeader."No.");
        TotalReminderLines := ReminderLine.Count;

        ReminderLine.SetFilter("Due Date", DueDateFilter);
        Assert.AreEqual(TotalReminderLines, ReminderLine.Count, ReminderLinesErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrueFalse,ReminderLevelCommunicationPageHandler,LanguagesPageHandler')]
    procedure AddAndAttachTextforLanguageInReminderLevelCommunication()
    var
        ReminderTerms: Record "Reminder Terms";
        ReminderLevel: Record "Reminder Level";
        ReminderTermSetupPage: TestPage "Reminder Terms Setup";
    begin
        // [SCENARIO 566387] Adding and Attach New Text for language in Reminder Level Communication.
        Initialize();

        // [GIVEN] Create Reminder Term with levels
        LibraryErm.CreateReminderTerms(ReminderTerms);
        LibraryErm.CreateReminderLevel(ReminderLevel, ReminderTerms.Code);

        // [WHEN] Open Reminder Term Setup page and add text for language
        ReminderTermSetupPage.OpenEdit();
        ReminderTermSetupPage.GoToRecord(ReminderTerms);
        ReminderTermSetupPage.ReminderLevelSetup.First();

        // [THEN] Varify that the text for language is added in Reminder Level Communication.
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(false);
        ReminderTermSetupPage.ReminderLevelSetup.CustomerCommunications.Invoke();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrueFalse,ReminderLevelCommunicationPageHandler,ReminderRequestPageHandler,LanguagesPageHandlerNLD')]
    procedure AddTextforLanguageInReminderLevelCommunication()
    var
        ReminderTerms: Record "Reminder Terms";
        ReminderLevel: Record "Reminder Level";
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReminderHeader: Record "Reminder Header";
        IssuedReminderHeader: Record "Issued Reminder Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        IssuedReminder: TestPage "Issued Reminder";
        ReminderTermSetupPage: TestPage "Reminder Terms Setup";
        PostedDocumentNo: Code[20];
        ReminderNo: Code[20];
    begin
        // [SCENARIO 602665] Issue with the new feature for reminder texts where the configured body text is not included in the XML for report 117 (Reminder)
        Initialize();

        // [GIVEN] Create Reminder Term with levels
        LibraryErm.CreateReminderTerms(ReminderTerms);
        LibraryErm.CreateReminderLevel(ReminderLevel, ReminderTerms.Code);
        Evaluate(ReminderLevel."Grace Period", '2D');
        Evaluate(ReminderLevel."Due Date Calculation", '7D');
        ReminderLevel.Modify(true);

        // [WHEN] Open Reminder Term Setup page and add text for language
        ReminderTermSetupPage.OpenEdit();
        ReminderTermSetupPage.GoToRecord(ReminderTerms);
        ReminderTermSetupPage.ReminderLevelSetup.First();

        // [GIVEN] Add text for language NL in Reminder Level Communication.
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(false);
        ReminderTermSetupPage.ReminderLevelSetup.CustomerCommunications.Invoke();
        ReminderTermSetupPage.Close();

        // [GIVEN] Create Customer with Reminder Terms and Language Code = NL
        CustLedgerEntry.DeleteAll();
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Reminder Terms Code", ReminderTerms.Code);
        Customer.Validate("Language Code", 'NLD');
        Customer.Modify(true);

        // [GIVEN] Create and Post Sales Invoice for Customer
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item, LibraryRandom.RandDec(1000, 2), LibraryRandom.RandDec(1000, 2));
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [WHEN] Create Reminder with future posting date to make invoice overdue
        CreateReminderHeader(ReminderHeader, Customer."No.");
        ReminderHeader.Validate("Posting Date", CalcDate('<30D>', WorkDate()));
        ReminderHeader.Validate("Document Date", CalcDate('<30D>', WorkDate()));
        ReminderHeader.Modify(true);

        // [WHEN] Suggest Reminder Lines for Posted Invoice
        CreateReminderLine(ReminderHeader."No.", PostedDocumentNo);

        // [WHEN] Issue Reminder for Customer
        ReminderNo := ReminderHeader."No.";
        IssueReminder(ReminderNo);

        // [THEN] Verify Issued Reminder exists
        IssuedReminderHeader.SetRange("Customer No.", Customer."No.");
        IssuedReminderHeader.FindFirst();

        // [WHEN] Verify Reminder can be printed/sent with text for language NL
        IssuedReminder.OpenView();
        IssuedReminder.GoToRecord(IssuedReminderHeader);
        IssuedReminder."&Print".Invoke();
        IssuedReminder.Close();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('AmtDueText', StrSubstNo(AmtDueLbl, Format(IssuedReminderHeader."Due Date", 0, '<Day,2>-<Month,2>-<Year,2>')));
    end;

    local procedure Initialize()
    var
        FeatureKey: Record "Feature Key";
        FeatureKeyUpdateStatus: Record "Feature Data Update Status";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Invoice and Reminder");
        LibrarySetupStorage.Restore();
        if FeatureKey.Get('ReminderTermsCommunicationTexts') then begin
            FeatureKey.Enabled := FeatureKey.Enabled::None;
            FeatureKey.Modify();
            Commit();
        end;
        if FeatureKeyUpdateStatus.Get('ReminderTermsCommunicationTexts', CompanyName()) then begin
            FeatureKeyUpdateStatus."Feature Status" := FeatureKeyUpdateStatus."Feature Status"::Disabled;
            FeatureKeyUpdateStatus.Modify();
            Commit();
        end;
        // Lazy Setup.
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Invoice and Reminder");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        LibrarySetupStorage.SaveGeneralLedgerSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Invoice and Reminder");
    end;

    local procedure PrepareInvoiceAndReminderPostingDates(var InvoicePostingDate: array[3] of Date; var ReminderPostingDate: array[3] of Date)
    begin
        InvoicePostingDate[1] := WorkDate();
        InvoicePostingDate[2] := CalcDate('<1W>', InvoicePostingDate[1]) - 1;
        InvoicePostingDate[3] := CalcDate('<1W>', InvoicePostingDate[2]) - 1;
        ReminderPostingDate[1] := CalcDate('<3W+1D>', WorkDate());
        ReminderPostingDate[2] := CalcDate('<1W+1D>', ReminderPostingDate[1]);
        ReminderPostingDate[3] := CalcDate('<1W+1D>', ReminderPostingDate[2]);
    end;

    local procedure PrepareInvoiceAndReminder(var Customer: Record Customer; var PostedInvNo: Code[20]; InvoicePostingDate: Date; ReminderPostingDate: Date)
    var
        ReminderLine: Record "Reminder Line";
        ReminderHeader: Record "Reminder Header";
        DummyCustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        PostedInvNo := PostSalesInvoice(Customer."No.", InvoicePostingDate);
        RunCreateReminders(Customer, DummyCustLedgerEntry, true, ReminderPostingDate);
        VerifyReminderLineTypeForDocument(ReminderLine, PostedInvNo, ReminderLine."Line Type"::"Reminder Line");
        ReminderHeader.SetRange("No.", ReminderLine."Reminder No.");
        REPORT.RunModal(REPORT::"Issue Reminders", false, true, ReminderHeader);
    end;

    local procedure CreateAndPostSalesInvoice(var SalesLine: Record "Sales Line") DocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
    begin
        // Take Random Quantity for Sales Line.
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item,
          LibraryRandom.RandDec(1000, 2), LibraryRandom.RandDec(1000, 2));
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CreateCustomer());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateIssuedFinChargeMemoWithInterestLine(var IssuedFinChargeMemoHeader: Record "Issued Fin. Charge Memo Header")
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        FinanceChargeInterestRate: Record "Finance Charge Interest Rate";
        Customer: Record Customer;
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
        FinChrgMemoIssue: Codeunit "FinChrgMemo-Issue";
        CreationDate: Date;
        CreateFinanceChargeMemos: Report "Create Finance Charge Memos";

    begin
        CreateFinanceChargeTerm(FinanceChargeTerms);
        CreateFinanceChargeInterestRates(FinanceChargeInterestRate, FinanceChargeTerms.Code, CalcDate('<-1D>', WorkDate()));
        Customer.Get(MIRHelperFunctions.UpdateFinChargeTermsOnCustomer(FinanceChargeTerms.Code));
        MIRHelperFunctions.CreateAndPostSalesInvoiceBySalesJournal(Customer."No.");
        CreationDate := CalcDate('<' + Format(2 * LibraryRandom.RandInt(5)) + 'M>', WorkDate());
        Customer.SetRecFilter();
        CreateFinanceChargeMemos.SetTableView(Customer);
        CreateFinanceChargeMemos.InitializeRequest(CreationDate, CreationDate);
        CreateFinanceChargeMemos.UseRequestPage(false);
        CreateFinanceChargeMemos.Run();
        FinanceChargeMemoHeader.SetRange("Customer No.", Customer."No.");
        FinanceChargeMemoHeader.FindFirst();
        FinChrgMemoIssue.Set(FinanceChargeMemoHeader, false, WorkDate());
        LibraryERM.RunFinChrgMemoIssue(FinChrgMemoIssue);
        IssuedFinChargeMemoHeader.SetRange("Customer No.", Customer."No.");
        IssuedFinChargeMemoHeader.FindFirst();
    end;

    local procedure CreateFinanceChargeTerm(var FinanceChargeTerms: Record "Finance Charge Terms")
    begin
        LibraryERM.CreateFinanceChargeTerms(FinanceChargeTerms);
        FinanceChargeTerms.Validate("Interest Rate", LibraryRandom.RandInt(10));
        FinanceChargeTerms.Validate("Interest Period (Days)", LibraryRandom.RandInt(10));
        Evaluate(FinanceChargeTerms."Due Date Calculation", '<1M>');
        FinanceChargeTerms.Modify(true);
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

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    [Normal]
    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Currency Code", CreateCurrency());
        Customer.Validate("Reminder Terms Code", CreateReminderTerms());
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateCustomerWithPaymentAndReminderTerms(var Customer: Record Customer; WeekDateFormula: DateFormula)
    var
        ReminderTerms: Record "Reminder Terms";
        PaymentTerms: Record "Payment Terms";
        BlankDateFormula: DateFormula;
        FeeAmount: Decimal;
    begin
        FeeAmount := LibraryRandom.RandDecInRange(5, 10, 2);

        LibraryERM.CreateReminderTerms(ReminderTerms);
        CreateReminderLevelDueDateCalculation(ReminderTerms.Code, WeekDateFormula, WeekDateFormula, FeeAmount);
        CreateReminderLevelDueDateCalculation(ReminderTerms.Code, BlankDateFormula, WeekDateFormula, FeeAmount * 2);
        CreateReminderLevelDueDateCalculation(ReminderTerms.Code, BlankDateFormula, WeekDateFormula, FeeAmount * 3);

        LibraryERM.CreatePaymentTerms(PaymentTerms);
        PaymentTerms.Validate("Due Date Calculation", WeekDateFormula);
        PaymentTerms.Modify(true);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Validate("Reminder Terms Code", ReminderTerms.Code);
        Customer.Modify(true);

        Customer.SetRecFilter();
    end;

    [Scope('OnPrem')]
    procedure CreateCustomerWithPaymentReminderFinChargeTerms(DueDateFormula: DateFormula): Code[20]
    var
        Customer: Record Customer;
        ReminderTermsCode: Code[10];
        FinanceChargeTermsCode: Code[10];
        PaymentTermsCode: Code[10];
    begin
        FinanceChargeTermsCode := CreateFinanceChargeTerms(DueDateFormula);
        ReminderTermsCode := CreateReminderTermsAndLevels(DueDateFormula);
        PaymentTermsCode := CreatePaymentTerms(DueDateFormula);

        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTermsCode);
        Customer.Validate("Reminder Terms Code", ReminderTermsCode);
        Customer.Validate("Fin. Charge Terms Code", FinanceChargeTermsCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    [Scope('OnPrem')]
    procedure CreateFinanceChargeTerms(DueDateFormula: DateFormula): Code[10]
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
    begin
        LibraryERM.CreateFinanceChargeTerms(FinanceChargeTerms);
        FinanceChargeTerms.Validate("Interest Rate", LibraryRandom.RandInt(10));
        FinanceChargeTerms.Validate("Interest Period (Days)", 365);
        FinanceChargeTerms.Validate("Due Date Calculation", DueDateFormula);
        FinanceChargeTerms.Validate("Post Interest", true);
        FinanceChargeTerms.Modify(true);
        exit(FinanceChargeTerms.Code);
    end;

    [Scope('OnPrem')]
    procedure CreatePaymentTerms(DueDateFormula: DateFormula): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        PaymentTerms.Validate("Due Date Calculation", DueDateFormula);
        PaymentTerms.Modify(true);
        exit(PaymentTerms.Code);
    end;

    [Scope('OnPrem')]
    procedure CreateReminderForDate(var ReminderHeader: Record "Reminder Header"; CustomerNo: Code[20]; PostingAndDocumentDate: Date)
    begin
        LibraryERM.CreateReminderHeader(ReminderHeader);
        ReminderHeader.Validate("Customer No.", CustomerNo);
        ReminderHeader.Validate("Posting Date", PostingAndDocumentDate);
        ReminderHeader.Validate("Document Date", PostingAndDocumentDate);
        ReminderHeader.Modify(true);

        Commit();
        LibraryVariableStorage.Enqueue('');
        Report.RunModal(Report::"Suggest Reminder Lines", true, false, ReminderHeader);

        ReminderHeader.SetRecFilter();
    end;

    local procedure CreateReminderTerms(): Code[10]
    var
        ReminderTerms: Record "Reminder Terms";
    begin
        LibraryERM.CreateReminderTerms(ReminderTerms);
        CreateReminderLevel(ReminderTerms.Code);
        exit(ReminderTerms.Code);
    end;

    [Scope('OnPrem')]
    procedure CreateReminderTermsAndLevels(DueDateFormula: DateFormula): Code[10]
    var
        ReminderTerms: Record "Reminder Terms";
    begin
        LibraryERM.CreateReminderTerms(ReminderTerms);
        ReminderTerms.Validate("Post Interest", true);
        ReminderTerms.Modify(true);

        CreateReminderLevelWithCalculateInterest(ReminderTerms.Code, DueDateFormula, false);
        CreateReminderLevelWithCalculateInterest(ReminderTerms.Code, DueDateFormula, true);
        exit(ReminderTerms.Code);
    end;

    local procedure CreateReminderLevel(ReminderTermsCode: Code[10])
    var
        ReminderLevel: Record "Reminder Level";
    begin
        LibraryERM.CreateReminderLevel(ReminderLevel, ReminderTermsCode);
        Evaluate(ReminderLevel."Grace Period", '<' + Format(LibraryRandom.RandInt(5)) + 'M>');
        ReminderLevel.Modify(true);
    end;

    local procedure CreateReminderLevelDueDateCalculation(ReminderTermsCode: Code[10]; GraceFormula: DateFormula; DueFormula: DateFormula; FeeAmount: Decimal)
    var
        ReminderLevel: Record "Reminder Level";
    begin
        LibraryERM.CreateReminderLevel(ReminderLevel, ReminderTermsCode);
        ReminderLevel.Validate("Grace Period", GraceFormula);
        ReminderLevel.Validate("Due Date Calculation", DueFormula);
        ReminderLevel.Validate("Additional Fee (LCY)", FeeAmount);
        ReminderLevel.Modify(true);
    end;

    [Scope('OnPrem')]
    procedure CreateReminderLevelWithCalculateInterest(ReminderTermsCode: Code[10]; DueDateFormula: DateFormula; CalculateInterest: Boolean)
    var
        ReminderLevel: Record "Reminder Level";
    begin
        LibraryERM.CreateReminderLevel(ReminderLevel, ReminderTermsCode);
        ReminderLevel.Validate("Due Date Calculation", DueDateFormula);
        ReminderLevel.Validate("Calculate Interest", CalculateInterest);
        ReminderLevel.Modify(true);
    end;

    local procedure CreateReminderHeader(var ReminderHeader: Record "Reminder Header"; CustomerNo: Code[20])
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        if SalesReceivablesSetup."Reminder Nos." = '' then
            SalesReceivablesSetup.Validate("Reminder Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup."Issued Reminder Nos." := SalesReceivablesSetup."Reminder Nos.";
        SalesReceivablesSetup.Modify();

        LibraryERM.CreateReminderHeader(ReminderHeader);
        ReminderHeader.Validate("Customer No.", CustomerNo);
        ReminderHeader.Modify(true);
    end;

    local procedure CreateReminderLine(ReminderHeaderNo: Code[20]; DocumentNo: Code[20]): Decimal
    var
        ReminderLine: Record "Reminder Line";
    begin
        LibraryERM.CreateReminderLine(ReminderLine, ReminderHeaderNo, ReminderLine.Type::"Customer Ledger Entry");
        ReminderLine.Validate("Document No.", DocumentNo);
        ReminderLine.Modify(true);
        exit(ReminderLine."Remaining Amount");
    end;

    local procedure CreateReminderLineForInvRounding(var ReminderLine: Record "Reminder Line"; ReminderHeader: Record "Reminder Header"; AmountRoundingPrecision: Decimal)
    var
        GLAccount: Record "G/L Account";
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        VATProductPostingGroup: Record "VAT Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        LibraryERM.CreateReminderLine(
          ReminderLine, ReminderHeader."No.", ReminderLine.Type::"G/L Account");

        GLAccount.Get(LibraryERM.CreateGLAccountWithSalesSetup());
        GenProductPostingGroup.Get(GLAccount."Gen. Prod. Posting Group");
        GenProductPostingGroup.Validate("Def. VAT Prod. Posting Group", GLAccount."VAT Prod. Posting Group");
        GenProductPostingGroup.Modify(true);
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, ReminderHeader."VAT Bus. Posting Group", VATProductPostingGroup.Code);
        VATPostingSetup."VAT Identifier" := VATPostingSetup."VAT Prod. Posting Group";
        VATPostingSetup.Validate("VAT %", 0);
        VATPostingSetup.Modify(true);
        GLAccount.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        GLAccount.Modify(true);

        ReminderLine.Validate("No.", GLAccount."No.");
        ReminderLine.Validate(
          Amount,
          (LibraryRandom.RandIntInRange(10000, 20000) * 10 + 1) * AmountRoundingPrecision);
        ReminderLine.Modify(true);
    end;

    local procedure IssueReminder(ReminderNo: Code[20])
    var
        ReminderHeader: Record "Reminder Header";
        IssueReminders: Report "Issue Reminders";
    begin
        ReminderHeader.SetRange("No.", ReminderNo);
        Clear(IssueReminders);
        IssueReminders.SetTableView(ReminderHeader);
        IssueReminders.UseRequestPage(false);
        IssueReminders.Run();
    end;

    local procedure MockIssuedReminder(var IssuedReminderHeader: Record "Issued Reminder Header")
    var
        IssuedReminderLine: Record "Issued Reminder Line";
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        IssuedReminderHeader.Init();
        IssuedReminderHeader."No." :=
          LibraryUtility.GenerateRandomCode(IssuedReminderHeader.FieldNo("No."), DATABASE::"Issued Reminder Header");
        LibrarySales.CreateCustomerPostingGroup(CustomerPostingGroup);
        CustomerPostingGroup."Additional Fee Account" := '';
        CustomerPostingGroup.Modify();
        IssuedReminderHeader."Customer Posting Group" := CustomerPostingGroup.Code;
        IssuedReminderHeader."Due Date" := LibraryRandom.RandDate(LibraryRandom.RandIntInRange(10, 100));
        IssuedReminderHeader.Insert();
        IssuedReminderLine.Init();
        IssuedReminderLine."Line No." := LibraryUtility.GetNewRecNo(IssuedReminderLine, IssuedReminderLine.FieldNo("Line No."));
        IssuedReminderLine."Line Type" := IssuedReminderLine."Line Type"::"Reminder Line";
        IssuedReminderLine."Reminder No." := IssuedReminderHeader."No.";
        IssuedReminderLine."Due Date" := IssuedReminderHeader."Due Date";
        IssuedReminderLine."Remaining Amount" := LibraryRandom.RandIntInRange(10, 100);
        IssuedReminderLine.Amount := IssuedReminderLine."Remaining Amount";
        IssuedReminderLine.Type := IssuedReminderLine.Type::"G/L Account";
        IssuedReminderLine.Insert();
    end;

    local procedure ModifyReminderHeader(var ReminderHeader: Record "Reminder Header")
    begin
        ReminderHeader.Validate("Currency Code", CreateCurrency());
        ReminderHeader.Modify(true);
    end;

    local procedure PostSalesInvoice(CustomerNo: Code[20]; PostingDate: Date): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(100, 200));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, true));
    end;

    local procedure RunCreateReminders(var Customer: Record Customer; var CustLedgerEntry: Record "Cust. Ledger Entry"; OverdueEntriesOnly: Boolean; ReminderPostingDate: Date)
    var
        CreateReminders: Report "Create Reminders";
    begin
        CreateReminders.SetTableView(CustLedgerEntry);
        CreateReminders.SetTableView(Customer);
        CreateReminders.InitializeRequest(ReminderPostingDate, ReminderPostingDate, OverdueEntriesOnly, false, false);
        CreateReminders.UseRequestPage(false);
        CreateReminders.Run();
    end;

    local procedure UpdateGLSetupInvRoundingPrecision()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        LibraryERM.SetInvRoundingPrecisionLCY(GeneralLedgerSetup."Amount Rounding Precision" * 10);
    end;

    local procedure VerifyReminderLineTypeForDocument(var ReminderLine: Record "Reminder Line"; DocumentNo: Code[20]; ExpectedReminderLineType: Enum "Reminder Line Type")
    begin
        ReminderLine.SetRange("Document No.", DocumentNo);
        ReminderLine.FindFirst();
        ReminderLine.TestField("Line Type", ExpectedReminderLineType);
    end;

    local procedure VerifyReminderLinePresentsForSalesInvoice(DocumentNo: Code[20])
    var
        ReminderLine: Record "Reminder Line";
    begin
        ReminderLine.SetRange("Document Type", ReminderLine."Document Type"::Invoice);
        ReminderLine.SetRange("Document No.", DocumentNo);
        ReminderLine.SetRange(Type, ReminderLine.Type::"Customer Ledger Entry");
        ReminderLine.SetRange("Line Type", ReminderLine."Line Type"::"Reminder Line");
        Assert.RecordCount(ReminderLine, 1);
    end;

    local procedure VerifyReminderLineNotPresentForSalesInvoice(DocumentNo: Code[20])
    var
        ReminderLine: Record "Reminder Line";
    begin
        ReminderLine.SetRange("Document Type", ReminderLine."Document Type"::Invoice);
        ReminderLine.SetRange("Document No.", DocumentNo);
        ReminderLine.SetRange(Type, ReminderLine.Type::"Customer Ledger Entry");
        ReminderLine.SetRange("Line Type", ReminderLine."Line Type"::"Reminder Line");
        Assert.RecordIsEmpty(ReminderLine);
    end;

    local procedure VerifyAmtDueTextAndRemaininAmt(IssuedReminderHeader: Record "Issued Reminder Header")
    begin
        LibraryReportDataset.LoadDataSetFile();
        IssuedReminderHeader.CalcFields("Remaining Amount");
        LibraryReportDataset.AssertElementWithValueExists('RemainingAmountText', Format(IssuedReminderHeader."Remaining Amount"));
        LibraryReportDataset.AssertElementWithValueExists('AmtDueText', StrSubstNo(AmtDueLbl, IssuedReminderHeader."Due Date"));
    end;

    local procedure PostSalesInvoiceWithDueDate(CustomerNo: Code[20]; PostingDate: Date; DueDate: Date): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Due Date", DueDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(100, 200));
        SalesLine.Modify(true);
        exit(LibrarySales.PostSalesDocument(SalesHeader, false, true));
    end;

    local procedure MockCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; LastIssuedReminderLevel: Integer; DueDate: Date)
    var
        LastEntryNo: Integer;
    begin
        if CustLedgerEntry.FindLast() then
            LastEntryNo := CustLedgerEntry."Entry No.";
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LastEntryNo + 1;
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Posting Date" := WorkDate();
        CustLedgerEntry."Document Type" := DocumentType;
        CustLedgerEntry."Document No." := CustomerNo;
        CustLedgerEntry."Last Issued Reminder Level" := LastIssuedReminderLevel;
        CustLedgerEntry."Due Date" := DueDate;
        CustLedgerEntry.Open := true;
        CustLedgerEntry.Positive := true;
        CustLedgerEntry.Insert();
    end;

    procedure FindBankAccountDefaultForCurrency(var BankAccount: Record "Bank Account")
    begin
        BankAccount.SetRange(Blocked, false);
        BankAccount.SetRange("Use as Default for Currency", true);
        if not BankAccount.FindFirst() then begin
            LibraryERM.CreateBankAccount(BankAccount);
            BankAccount.Validate("Use as Default for Currency", true);
            BankAccount.Modify(true);
        end;
    end;

    local procedure CreateCustomerLedgerEntries(CustomerNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        i: Integer;
    begin
        for i := 1 to 5 do begin
            MockCustLedgerEntry(
                CustLedgerEntry, CustomerNo, "Gen. Journal Document Type"::Invoice,
                0, CalcDate(StrSubstNo(DueDateLbl, LibraryRandom.RandIntInRange(1, 10)), WorkDate()));
            CreateDetailedCustomerLedgerEntry(CustLedgerEntry."Entry No.");
        end;
    end;

    local procedure CreateDetailedCustomerLedgerEntry(CustLedgerEntryNo: Integer)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(DetailedCustLedgEntry);
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Entry No." := LibraryUtility.GetNewLineNo(RecRef, DetailedCustLedgEntry.FieldNo("Entry No."));
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgerEntryNo;
        DetailedCustLedgEntry.Amount := LibraryRandom.RandDec(10, 2);
        DetailedCustLedgEntry."Posting Date" := WorkDate();
        DetailedCustLedgEntry.Insert();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerVerifyMsg(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedMessage(LibraryVariableStorage.DequeueText(), Question);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReminderRequestPageHandler(var Reminder: TestRequestPage Reminder)
    begin
        Reminder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReminderTestRequestPageHandler(var ReminderTest: TestRequestPage "Reminder - Test")
    begin
        ReminderTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    procedure SuggestLinesReportHandler(var SuggestReminderLines: TestRequestPage "Suggest Reminder Lines")
    begin
        SuggestReminderLines.CustLedgEntry2.SetFilter("Due Date", LibraryVariableStorage.DequeueText());
        SuggestReminderLines.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerTrueFalse(QuestionText: Text[1024]; var Relpy: Boolean)
    begin
        Relpy := LibraryVariableStorage.DequeueBoolean();
    end;

    [PageHandler]
    procedure ReminderLevelCommunicationPageHandler(var ReminderLevelCommunication: TestPage "Reminder Level Communication")
    begin
        ReminderLevelCommunication."Add New Language".Invoke();
    end;

    [ModalPageHandler]
    procedure LanguagesPageHandler(var Languages: TestPage "Languages")
    begin
        Languages.Filter.SetFilter("Code", 'ENG');
        Languages.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure LanguagesPageHandlerNLD(var Languages: TestPage "Languages")
    begin
        Languages.Filter.SetFilter("Code", 'NLD');
        Languages.OK().Invoke();
    end;
}

