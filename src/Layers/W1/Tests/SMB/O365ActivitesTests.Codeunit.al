codeunit 139126 "O365 Activites Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Activities]
    end;

    var
        TestPaymentMethod: Record "Payment Method";
        Assert: Codeunit Assert;
        ActivitiesMgt: Codeunit "Activities Mgt.";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        isInitialized: Boolean;
        ExpectedAvergeCollectionDays: Decimal;
        ExpectedCountClosedInvoices: Integer;
        PaymentsCreated: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure CalcOverdueSalesInvoiceAmount()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        RemainingAmountSum: Decimal;
    begin
        // Setup
        Initialize();
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetFilter("Due Date", '<%1', WorkDate());
        CustLedgerEntry.SetRange(Open, true);
        if CustLedgerEntry.FindSet() then
            repeat
                CustLedgerEntry.CalcFields("Remaining Amt. (LCY)");
                RemainingAmountSum += CustLedgerEntry."Remaining Amt. (LCY)";
            until CustLedgerEntry.Next() = 0;

        // Execute & Verify
        Assert.AreEqual(RemainingAmountSum, ActivitiesMgt.OverdueSalesInvoiceAmount(false, false), 'Unexpected Sum');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcOverduePurchaseAmount()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        RemainingAmountSum: Decimal;
    begin
        // Setup
        Initialize();
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetFilter("Due Date", '<%1', WorkDate());
        VendorLedgerEntry.SetRange(Open, true);
        if VendorLedgerEntry.FindSet() then
            repeat
                VendorLedgerEntry.CalcFields("Remaining Amt. (LCY)");
                RemainingAmountSum += VendorLedgerEntry."Remaining Amt. (LCY)";
            until VendorLedgerEntry.Next() = 0;

        // Execute & Verify
        Assert.AreEqual(Abs(RemainingAmountSum), ActivitiesMgt.OverduePurchaseInvoiceAmount(false, false), 'Unexpected Sum');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcSalesThisMonthAmount()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        AmountSum: Decimal;
    begin
        // Setup
        Initialize();
        CustLedgerEntry.SetFilter("Document Type", '%1|%2',
          CustLedgerEntry."Document Type"::Invoice, CustLedgerEntry."Document Type"::"Credit Memo");
        CustLedgerEntry.SetRange("Posting Date", CalcDate('<-CM>', WorkDate()), WorkDate());
        if CustLedgerEntry.FindSet() then
            repeat
                AmountSum += CustLedgerEntry."Sales (LCY)";
            until CustLedgerEntry.Next() = 0;

        // Execute & Verify
        Assert.AreEqual(AmountSum, ActivitiesMgt.CalcSalesThisMonthAmount(false), 'Unexpected Sum');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcSalesYTD()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        AccountingPeriod: Record "Accounting Period";
        AmountSum: Decimal;
    begin
        // Setup
        Initialize();
        CustLedgerEntry.SetRange("Posting Date", AccountingPeriod.GetFiscalYearStartDate(WorkDate()), WorkDate());
        if CustLedgerEntry.FindSet() then
            repeat
                AmountSum := AmountSum + CustLedgerEntry."Sales (LCY)";
            until CustLedgerEntry.Next() = 0;

        // Execute & Verify
        Assert.AreEqual(AmountSum, ActivitiesMgt.CalcSalesYTD(), 'Unexpected Sum');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcTop10CustomerSalesYTD()
    var
        TopCustomerSales: Decimal;
        TotalSales: Decimal;
    begin
        // Setup
        Initialize();
        CalcCustomerSalesYTD(TopCustomerSales, TotalSales);

        // Verify
        Assert.AreEqual(TotalSales, ActivitiesMgt.CalcSalesYTD(), 'Unexpected Amount for Total SalesYTD');
        Assert.AreEqual(TopCustomerSales, ActivitiesMgt.CalcTop10CustomerSalesYTD(),
          'Unexpected Amount for Top10 Customer Sales YTD');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcTop10CustomerSalesRatioYTD()
    var
        TopCustomerSales: Decimal;
        TotalSales: Decimal;
    begin
        // Setup
        Initialize();
        CalcCustomerSalesYTD(TopCustomerSales, TotalSales);

        // Verify
        if TotalSales <> 0 then
            Assert.AreEqual(TopCustomerSales / TotalSales,
              ActivitiesMgt.CalcTop10CustomerSalesRatioYTD(),
              'Unexpected Amount for Top 10 Customer Sales Ratio YTD');
    end;

    local procedure CalcCustomerSalesYTD(var TopCustomerSales: Decimal; var TotalSales: Decimal)
    var
        AccountingPeriod: Record "Accounting Period";
        Customer: Record Customer;
        ColumnIndex: Integer;
    begin
        ColumnIndex := 1;
        Customer.SetCurrentKey("Sales (LCY)");
        Customer.Ascending(false);
        Customer.SetRange("Date Filter", AccountingPeriod.GetFiscalYearStartDate(WorkDate()), WorkDate());
        Customer.CalcFields("Sales (LCY)");
        if Customer.Find('-') then
            repeat
                if ColumnIndex <= 10 then
                    TopCustomerSales += Customer."Sales (LCY)";
                TotalSales += Customer."Sales (LCY)";
                ColumnIndex := ColumnIndex + 1;
            until Customer.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcAverageCollectionDays()
    begin
        // Setup
        Initialize();

        // The expected average collecation days is calculated when creating the test records
        CreateTestPayments();

        // Execute & Verify
        Assert.AreEqual(ExpectedAvergeCollectionDays, ActivitiesMgt.CalcAverageCollectionDays(), 'Unexpected Average Days');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownCalcOverdueSalesInvoiceAmount()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
    begin
        // Setup
        Initialize();
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetFilter("Due Date", '<%1', WorkDate());
        CustLedgerEntry.SetRange(Open, true);
        CustLedgerEntry.FindSet();
        CustomerLedgerEntries.Trap();

        // Execute
        ActivitiesMgt.DrillDownCalcOverdueSalesInvoiceAmount();

        // Verify
        repeat
            Assert.IsTrue(CustomerLedgerEntries.GotoRecord(CustLedgerEntry), 'Expected Entry Not Found');
        until CustLedgerEntry.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownOverduePurchaseInvoiceAmount()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
    begin
        // Setup
        Initialize();
        VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
        VendorLedgerEntry.SetFilter("Due Date", '<%1', WorkDate());
        VendorLedgerEntry.SetFilter("Remaining Amt. (LCY)", '<>0');
        VendorLedgerEntry.FindSet();
        VendorLedgerEntries.Trap();

        // Execute
        ActivitiesMgt.DrillDownOverduePurchaseInvoiceAmount();

        // Verify
        repeat
            Assert.IsTrue(VendorLedgerEntries.GotoRecord(VendorLedgerEntry), 'Expected Entry Not Found');
        until VendorLedgerEntry.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownSalesThisMonth()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
    begin
        // Setup
        Initialize();
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Posting Date", CalcDate('<-CM>', WorkDate()), WorkDate());
        CustLedgerEntry.FindSet();

        CustomerLedgerEntries.Trap();

        // Execute
        ActivitiesMgt.DrillDownSalesThisMonth();

        // Verify
        repeat
            Assert.IsTrue(CustomerLedgerEntries.GotoRecord(CustLedgerEntry), 'Expected Entry Not Found');
        until CustLedgerEntry.Next() = 0;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OverduePurchInvoiceRemainingAmountLCYSortingTest()
    var
        VendLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        PreviousRemainingAmtLCY: Decimal;
        CurrentEntryNo: Integer;
    begin
        // Setup
        Initialize();
        VendorLedgerEntries.Trap();

        // Execute
        ActivitiesMgt.DrillDownOverduePurchaseInvoiceAmount();

        // Verify
        // in order to verify, since fields which are not visible by default are inaccesible in a TestPage, a record is used;
        // to verify that the sorting was done correctly, the records are iterated through one by one and each time
        // the value of Remaining Amt. (LCY) is checked to be smaller then the previous Remaining Amt. (LCY) value
        VendorLedgerEntries.First();
        PreviousRemainingAmtLCY := 0;
        repeat
            CurrentEntryNo := VendorLedgerEntries."Entry No.".AsInteger();
            VendLedgerEntry.Get(CurrentEntryNo);
            VendLedgerEntry.CalcFields("Remaining Amt. (LCY)");
            if PreviousRemainingAmtLCY <> 0 then
                Assert.IsTrue(Abs(VendLedgerEntry."Remaining Amt. (LCY)") <= PreviousRemainingAmtLCY,
                  'Entries not sorted decreasingly by Remaining Amt. (LCY)');
            PreviousRemainingAmtLCY := Abs(VendLedgerEntry."Remaining Amt. (LCY)");
        until not VendorLedgerEntries.Next();
    end;

    [Test]
    [HandlerFunctions('VendorLedgerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure OverduePurchInvoiceRemainingAmountLCYVisibleTest()
    begin
        // Setup and Execute
        ActivitiesMgt.DrillDownOverduePurchaseInvoiceAmount();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OverdueSalesInvoiceRemainingAmountLCYSortingTest()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
        PreviousRemainingAmtLCY: Decimal;
        CurrentEntryNo: Integer;
    begin
        // Setup
        Initialize();
        CustomerLedgerEntries.Trap();

        // Execute
        ActivitiesMgt.DrillDownCalcOverdueSalesInvoiceAmount();

        // Verify
        // in order to verify, since fields which are not visible by default are inaccesible in a TestPage, a record is used;
        // to verify that the sorting was done correctly, the records are iterated through one by one and each time
        // the value of Remaining Amt. (LCY) is checked to be smaller then the previous Remaining Amt. (LCY) value
        CustomerLedgerEntries.First();
        PreviousRemainingAmtLCY := 0;
        repeat
            CurrentEntryNo := CustomerLedgerEntries."Entry No.".AsInteger();
            CustLedgerEntry.Get(CurrentEntryNo);
            CustLedgerEntry.CalcFields("Remaining Amt. (LCY)");
            if PreviousRemainingAmtLCY <> 0 then
                Assert.IsTrue(CustLedgerEntry."Remaining Amt. (LCY)" <= PreviousRemainingAmtLCY,
                  'Entries not sorted decreasingly by Remaining Amt. (LCY)');
            PreviousRemainingAmtLCY := CustLedgerEntry."Remaining Amt. (LCY)";
        until not CustomerLedgerEntries.Next();
    end;

    [Test]
    [HandlerFunctions('CustomerLedgerEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure OverdueSalesInvoiceRemainingAmountLCYVisibleTest()
    begin
        // Setup and Execute
        ActivitiesMgt.DrillDownCalcOverdueSalesInvoiceAmount();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountsAreCalculatedWhenLastModifiedIsSetTo0()
    var
        ActivitiesCue: Record "Activities Cue";
        O365Activities: TestPage "O365 Activities";
    begin
        // SETUP - Set all amounts to 0
        Initialize();
        ActivitiesCue.Get();
        ActivitiesCue."Overdue Sales Invoice Amount" := 0;
        ActivitiesCue."Overdue Purch. Invoice Amount" := 0;
        ActivitiesCue."Sales This Month" := 0;
        ActivitiesCue."Average Collection Days" := 0;

        // SETUP - Set LAst Date/Time Modified to 0
        ActivitiesCue."Last Date/Time Modified" := 0DT;
        ActivitiesCue.Modify();
        Commit();

        // WHEN - O365 Activities page is opened
        O365Activities.OpenView();
        O365Activities.Close();

        // THEN - Amounts are calculated
        ActivitiesCue.Get();
        Assert.AreNotEqual(ActivitiesCue."Overdue Sales Invoice Amount", 0, 'Amount is not calculated');
        Assert.AreNotEqual(ActivitiesCue."Overdue Purch. Invoice Amount", 0, 'Amount is not calculated');
        Assert.AreNotEqual(ActivitiesCue."Sales This Month", 0, 'Amount is not calculated');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountsAreRefreshedWhenDataIsStale()
    var
        ActivitiesCue: Record "Activities Cue";
        O365Activities: TestPage "O365 Activities";
    begin
        // SETUP - Set all amounts to 0
        Initialize();
        ActivitiesCue.Get();
        ActivitiesCue."Overdue Sales Invoice Amount" := 0;
        ActivitiesCue."Overdue Purch. Invoice Amount" := 0;
        ActivitiesCue."Sales This Month" := 0;
        ActivitiesCue."Average Collection Days" := 0;

        // SETUP - Set LAst Date/Time Modified to 0
        ActivitiesCue."Last Date/Time Modified" := CurrentDateTime - (60 * 60 * 1000);
        ActivitiesCue.Modify();
        Commit();

        // WHEN - O365 Activities page is opened
        O365Activities.OpenView();
        O365Activities.Close();

        // THEN - Amounts are calculated
        ActivitiesCue.Get();
        Assert.AreNotEqual(ActivitiesCue."Overdue Sales Invoice Amount", 0, 'Amount is not calculated');
        Assert.AreNotEqual(ActivitiesCue."Overdue Purch. Invoice Amount", 0, 'Amount is not calculated');
        Assert.AreNotEqual(ActivitiesCue."Sales This Month", 0, 'Amount is not calculated');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountsAreRefreshedWhenActivitiesPageIsOpened()
    var
        ActivitiesCue: Record "Activities Cue";
        O365Activities: TestPage "O365 Activities";
    begin
        // SETUP - Set all amounts to 0
        Initialize();
        ActivitiesCue.Get();
        ActivitiesCue."Overdue Sales Invoice Amount" := 0;
        ActivitiesCue."Overdue Purch. Invoice Amount" := 0;
        ActivitiesCue."Sales This Month" := 0;
        ActivitiesCue."Average Collection Days" := 0;

        // SETUP - Set LAst Date/Time Modified to 0
        ActivitiesCue."Last Date/Time Modified" := 0DT;
        ActivitiesCue.Modify();
        Commit();

        // WHEN - O365 Activities page is opened
        O365Activities.OpenView();
        Sleep(1000); // Let the child session do the calculations
        O365Activities.Close();

        // THEN - Amounts are calculated
        ActivitiesCue.Get();
        Assert.AreNotEqual(0, ActivitiesCue."Overdue Sales Invoice Amount", 'Amount is calculated');
        Assert.AreNotEqual(0, ActivitiesCue."Overdue Purch. Invoice Amount", 'Amount is calculated');
        Assert.AreNotEqual(0, ActivitiesCue."Sales This Month", 'Amount is calculated');
        Assert.AreNotEqual(0, ActivitiesCue."Average Collection Days", 'Amount is calculated');

        // [THEN] The calculated Amounts are positive
        Assert.IsTrue(ActivitiesCue."Overdue Sales Invoice Amount" > 0, 'Amount must be positive');
        Assert.IsTrue(ActivitiesCue."Overdue Purch. Invoice Amount" > 0, 'Amount must be positive');
    end;

    local procedure Initialize()
    var
        ActivitiesCue: Record "Activities Cue";
    begin
        LibraryApplicationArea.DisableApplicationAreaSetup();
        if isInitialized then
            exit;

        // Create test invoice records to get a clean dataset
        DeleteSalesInvoices();
        CreateTestSalesInvoices();
        CreateTestPurchaseInvoices();

        // Insert Activities Cue if not found
        if not ActivitiesCue.Get() then begin
            ActivitiesCue.Init();
            ActivitiesCue.Insert();
        end;

        isInitialized := true;
    end;

    local procedure CreateTestSalesInvoices()
    var
        TestItem: Record Item;
        TestCustomer: Record Customer;
        TestSalesHeader: Record "Sales Header";
        TestSalesLine: Record "Sales Line";
        I: Integer;
    begin
        LibrarySmallBusiness.CreateItem(TestItem);

        // create more than 10 customers and post a backdated sales invoice with random amount for each of them
        // this will ensure that the customers have non-empty Sales (LCY) value for both top ten customers and two 'other' customers

        // Create a payment method code to identify the test invoices
        LibraryERM.CreatePaymentMethod(TestPaymentMethod);

        for I := 1 to 12 do begin
            LibrarySmallBusiness.CreateCustomer(TestCustomer);
            TestCustomer."Payment Method Code" := TestPaymentMethod.Code;
            TestCustomer.Modify(true);
            LibrarySmallBusiness.CreateSalesInvoiceHeader(TestSalesHeader, TestCustomer);
            TestSalesHeader."Posting Date" := CalcDate('<-' + Format(2 * I) + 'D>', WorkDate());
            TestSalesHeader."Due Date" := CalcDate('<7D>', TestSalesHeader."Posting Date");
            TestSalesHeader.Modify(true);
            LibrarySmallBusiness.CreateSalesLine(TestSalesLine, TestSalesHeader, TestItem, I);

            // Make one invoice with zero amount
            if I = 10 then begin
                TestSalesLine."Unit Price" := 0;
                TestSalesLine.Modify(true);
            end;

            LibrarySmallBusiness.PostSalesInvoice(TestSalesHeader);
        end;
    end;

    local procedure CreateTestPurchaseInvoices()
    var
        TestItem: Record Item;
        TestVendor: Record Vendor;
        TestPurchaseHeader: Record "Purchase Header";
        TestPurchaseLine: Record "Purchase Line";
        I: Integer;
    begin
        LibrarySmallBusiness.CreateItem(TestItem);
        LibrarySmallBusiness.CreateVendor(TestVendor);

        // post test purchase invoices with backdated posting date in order to create some item ledger entries to drill down to
        for I := 1 to 10 do
            PostPurchaseInvoice(TestPurchaseHeader, TestPurchaseLine, TestVendor, TestItem, I, Format(I),
              CalcDate('<-' + Format(2 * I) + 'D>', WorkDate()));
    end;

    local procedure PostPurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Vendor: Record Vendor; Item: Record Item; Quantity: Integer; VendorInvoiceNo: Code[10]; PostingDate: Date)
    begin
        LibrarySmallBusiness.CreatePurchaseInvoiceHeader(PurchaseHeader, Vendor);
        PurchaseHeader."Vendor Invoice No." := VendorInvoiceNo;
        PurchaseHeader."Posting Date" := PostingDate;
        PurchaseHeader.Modify(true);
        LibrarySmallBusiness.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Item, Quantity);
        PurchaseLine."Direct Unit Cost" := LibraryRandom.RandDecInRange(100, 200, 2);
        PurchaseLine.Modify();
        LibrarySmallBusiness.PostPurchaseInvoice(PurchaseHeader);
    end;

    local procedure ApplyPaymentToCustomerInvoice(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        GenJournalLine.Validate("Applies-to Doc. Type", CustLedgerEntry."Document Type");
        GenJournalLine.Validate("Applies-to Doc. No.", CustLedgerEntry."Document No.");
        GenJournalLine.Modify(true);
    end;

    local procedure CreatePayment(var GenJournalLine: Record "Gen. Journal Line"; var CustLedgerEntry: Record "Cust. Ledger Entry"; PostingDate: Date)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GLAccount: Record "G/L Account";
        NoSeries: Codeunit "No. Series";
        LineNo: Integer;
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LineNo := 10000;
        if GenJournalLine.FindLast() then
            LineNo := GenJournalLine."Line No." + 10000;

        GenJournalLine.Init();
        GenJournalLine."Journal Template Name" := GenJournalBatch."Journal Template Name";
        GenJournalLine."Journal Batch Name" := GenJournalBatch.Name;
        GenJournalLine."Line No." := LineNo;
        GenJournalLine.Insert(true);

        GLAccount.SetRange(Blocked, false);
        GLAccount.SetRange("Direct Posting", true);
        GLAccount.SetRange("Account Subcategory Entry No.", 0);
        GLAccount.FindFirst();

        GenJournalLine.Validate("Document No.", NoSeries.PeekNextNo(GenJournalBatch."No. Series"));
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Document Type", GenJournalLine."Document Type"::Payment);
        GenJournalLine.Validate("Account Type", GenJournalLine."Account Type"::Customer);
        GenJournalLine.Validate("Account No.", CustLedgerEntry."Customer No.");
        CustLedgerEntry.CalcFields(Amount);
        GenJournalLine.Validate(Amount, -CustLedgerEntry.Amount);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Modify(true);
    end;

    local procedure CreateTestPayments()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        CountInvoices: Integer;
        PostingDate: Date;
    begin
        if PaymentsCreated then
            exit;

        // Ensure that 4 invoices created are paid with the same number of collection days
        ExpectedAvergeCollectionDays := 12;
        ExpectedCountClosedInvoices := 4;
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Payment Method Code", TestPaymentMethod.Code);
        CustLedgerEntry.SetRange(Open, true);
        CustLedgerEntry.SetCurrentKey("Posting Date");
        if CustLedgerEntry.FindSet() then
            repeat
                // Make sure the payment is made a fixed days after the invoice posting date
                PostingDate := CalcDate('<' + Format(ExpectedAvergeCollectionDays) + 'D>', CustLedgerEntry."Posting Date");
                CreatePayment(GenJournalLine, CustLedgerEntry, PostingDate);
                ApplyPaymentToCustomerInvoice(GenJournalLine, CustLedgerEntry);
                LibraryERM.PostGeneralJnlLine(GenJournalLine);
                CountInvoices += 1;
            until (CustLedgerEntry.Next() = 0) or (CountInvoices = ExpectedCountClosedInvoices);
        PaymentsCreated := true;
    end;

    local procedure DeleteSalesInvoices()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // Delete any invoices in the last 3 months
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Posting Date", CalcDate('<CM-3M>', WorkDate()), WorkDate());

        if CustLedgerEntry.FindSet() then
            repeat
                DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
                DetailedCustLedgEntry.DeleteAll(true);
            until CustLedgerEntry.Next() = 0;
        CustLedgerEntry.DeleteAll(true);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure CustomerLedgerEntriesPageHandler(var CustomerLedgerEntries: TestPage "Customer Ledger Entries")
    begin
        // Verify
        Assert.IsTrue(CustomerLedgerEntries."Remaining Amt. (LCY)".Visible(), 'Remaining Amt. (LCY) column not visible');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure VendorLedgerEntriesPageHandler(var VendorLedgerEntries: TestPage "Vendor Ledger Entries")
    begin
        // Verify
        Assert.IsTrue(VendorLedgerEntries."Remaining Amt. (LCY)".Visible(), 'Remaining Amt. (LCY) column not visible');
    end;
}

