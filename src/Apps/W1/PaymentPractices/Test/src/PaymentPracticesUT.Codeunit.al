// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Test.Finance.Analysis;

using Microsoft.Finance.Analysis;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Sales.Receivables;

codeunit 134197 "Payment Practices UT"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Payment Practices]
    end;

    var
        PaymentPeriods: array[3] of Record "Payment Period";
        Assert: Codeunit "Assert";
        PaymentPracticesLibrary: Codeunit "Payment Practices Library";
        PaymentPractices: Codeunit "Payment Practices";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        CompanySizeCodes: array[3] of Code[20];
        Initialized: Boolean;

    [Test]
    procedure VendorPaymentPractices_SizeEmpty()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
    begin
        // [SCENARIO] Generate payment practices for vendors by size with severals sizes and no entries in those dates. Report dataset will contain lines for each size with 0 entries.
        Initialize();

        // [GIVEN] Three vendors with different company size
        PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(CompanySizeCodes[1], false);
        PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(CompanySizeCodes[2], false);
        PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(CompanySizeCodes[3], false);

        // [WHEN] Generate payment practices for vendors by size
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader);
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] Report dataset will contain 3 lines, but 0 entries
        PaymentPracticesLibrary.VerifyLinesCount(PaymentPracticeHeader, 3);
        PaymentPracticesLibrary.VerifyBufferCount(PaymentPracticeHeader, 0, "Paym. Prac. Header Type"::Vendor);
    end;

    [Test]
    procedure VendorExclFromPaymentPractices()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        VendorNo: Code[20];
        VendorExcludedNo: Code[20];
    begin
        // [SCENARIO] Generate payment practices for vendor with excl. from payment practices = true and existing entries in those dates. Report dataset will contain entries only for vendor without excl.
        Initialize();

        // [GIVEN] Vendor with company size and an entry in the period
        VendorNo := PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(CompanySizeCodes[1], false);
        MockVendorInvoice(VendorNo, WorkDate(), WorkDate());

        // [GIVEN]Vendor with company size and an entry in the period, but with Excl. from Payment Practice = true
        VendorExcludedNo := PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(CompanySizeCodes[2], true);
        MockVendorInvoice(VendorExcludedNo, WorkDate(), WorkDate());

        // [WHEN] Generate payment practices for vendors by size
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader);
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] Report dataset will contain only 1 entry
        PaymentPracticesLibrary.VerifyBufferCount(PaymentPracticeHeader, 1, "Paym. Prac. Header Type"::Vendor);
    end;

    [Test]
    procedure CustomerExclFromPaymentPractices()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        Customer: Record Customer;
        CustomerExcluded: Record Customer;
    begin
        // [SCENARIO] Generate payment practices for customers with excl. from payment practices = true and existing entries in those dates. Report dataset will contain entries only for vendor without excl.
        Initialize();

        // [GIVEN] Customer with an entry in the period
        LibrarySales.CreateCustomer(Customer);
        MockCustomerInvoice(Customer."No.", WorkDate(), WorkDate());

        // [GIVEN] Customer with an entry in the period, but with Excl. from Payment Practice = true
        LibrarySales.CreateCustomer(CustomerExcluded);
        PaymentPracticesLibrary.SetExcludeFromPaymentPractices(CustomerExcluded, true);
        MockCustomerInvoice(CustomerExcluded."No.", WorkDate(), WorkDate());

        // [WHEN] Generate payment practices for cust+vendors
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader, "Paym. Prac. Header Type"::"Vendor+Customer", "Paym. Prac. Aggregation Type"::Period);
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] Report dataset will contain only 1 entry
        PaymentPracticesLibrary.VerifyBufferCount(PaymentPracticeHeader, 1, "Paym. Prac. Header Type"::Customer);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler_Yes')]
    procedure ConfirmToCleanUpOnAggrValidation_Yes()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        VendorNo: Code[20];
    begin
        // [SCENARIO] When lines already exist on header and you change Aggregation Type you need to confirm that lines will be deleted
        Initialize();

        // [GIVEN] Vendor with company size and an entry in the period
        VendorNo := PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(CompanySizeCodes[1], false);
        MockVendorInvoice(VendorNo, WorkDate(), WorkDate());

        // [GIVEN] Lines were generated for Header
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader);
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [WHEN] Change Aggregation Type
        PaymentPracticeHeader.Validate("Aggregation Type", PaymentPracticeHeader."Aggregation Type"::Period);
        // handled by Confirm handler

        // [THEN] Lines were deleted
        PaymentPracticesLibrary.VerifyLinesCount(PaymentPracticeHeader, 0);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler_No')]
    procedure ConfirmToCleanUpOnAggrValidation_No()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        VendorNo: Code[20];
    begin
        // [SCENARIO] When lines already exist on header and you change Aggregation Type you need to confirm that lines will be deleted
        Initialize();

        // [GIVEN] Vendor with company size and an entry in the period
        VendorNo := PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(CompanySizeCodes[1], false);
        MockVendorInvoice(VendorNo, WorkDate(), WorkDate());

        // [GIVEN] Lines were generated for Header
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader);
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [WHEN] Change Aggregation Type and say "no" in confirm handler
        PaymentPracticeHeader.Validate("Aggregation Type", PaymentPracticeHeader."Aggregation Type"::Period);
        // handled by Confirm handler

        // [THEN] Lines were not deleted and aggregation type was not changed
        PaymentPracticesLibrary.VerifyLinesCount(PaymentPracticeHeader, 3);
        PaymentPracticeHeader.TestField("Aggregation Type", PaymentPracticeHeader."Aggregation Type"::"Company Size");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler_Yes')]
    procedure ConfirmToCleanUpOnTypeValidation()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        VendorNo: Code[20];
    begin
        // [SCENARIO] When lines already exist on header and you change Header Type you need to confirm that lines will be deleted
        Initialize();

        // [GIVEN] Vendor with company size and an entry in the period
        VendorNo := PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(CompanySizeCodes[1], false);
        MockVendorInvoice(VendorNo, WorkDate(), WorkDate());

        // [GIVEN] Lines were generated for Header
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader, "Paym. Prac. Header Type"::Vendor, "Paym. Prac. Aggregation Type"::Period);
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [WHEN] Change Aggregation Type and say "yes" in confirm handler
        PaymentPracticeHeader.Validate("Header Type", PaymentPracticeHeader."Header Type"::Customer);
        // handled by Confirm handler

        // [THEN] Lines were deleted
        PaymentPracticesLibrary.VerifyLinesCount(PaymentPracticeHeader, 0);
    end;

    [Test]
    procedure ReportDataSetForVendorsByPeriod()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        PeriodAmounts: array[3] of Decimal;
        TotalAmount: Decimal;
        ExpectedPeriodPcts: array[3] of Decimal;
        PeriodCounts: array[3] of Integer;
        TotalCount: Integer;
        ExpectedPeriodAmountPcts: array[3] of Decimal;
        VendorNo: Code[20];
        Amount: Decimal;
        i: Integer;
        j: Integer;
    begin
        // [SCENARIO] Check report dataset for vendors by several entries in different periods
        Initialize();

        // [GIVEN] Create a vendor
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Create a payment practice header for Current Year of type Vendor
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader, "Paym. Prac. Header Type"::Vendor, "Paym. Prac. Aggregation Type"::Period);

        // [GIVEN] Post several entries for the vendor in 3 different periods
        for i := 1 to 3 do
            for j := 1 to LibraryRandom.RandInt(10) do begin
                PeriodCounts[i] += 1;
                TotalCount += 1;
                Amount := MockVendorInvoiceAndPaymentInPeriod(VendorNo, WorkDate(), PaymentPeriods[i]."Days From", PaymentPeriods[i]."Days To");
                PeriodAmounts[i] += Amount;
                TotalAmount += Amount;
            end;

        // [WHEN] Lines were generated for Header
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] Check that report dataset contains correct percentages for each period
        PrepareExpectedPeriodPcts(ExpectedPeriodPcts, ExpectedPeriodAmountPcts, PeriodCounts, TotalCount, PeriodAmounts, TotalAmount);
        PaymentPracticesLibrary.VerifyPeriodLine(PaymentPracticeHeader."No.", "Paym. Prac. Header Type"::Vendor, PaymentPeriods[1].Code, ExpectedPeriodPcts[1], ExpectedPeriodAmountPcts[1]);
        PaymentPracticesLibrary.VerifyPeriodLine(PaymentPracticeHeader."No.", "Paym. Prac. Header Type"::Vendor, PaymentPeriods[2].Code, ExpectedPeriodPcts[2], ExpectedPeriodAmountPcts[2]);
        PaymentPracticesLibrary.VerifyPeriodLine(PaymentPracticeHeader."No.", "Paym. Prac. Header Type"::Vendor, PaymentPeriods[3].Code, ExpectedPeriodPcts[3], ExpectedPeriodAmountPcts[3]);
    end;

    [Test]
    procedure ReportDataSetForCustomersByPeriod()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        ExpectedPeriodPcts: array[3] of Decimal;
        ExpectedPeriodAmountPcts: array[3] of Decimal;
        PeriodAmounts: array[3] of Decimal;
        TotalAmount: Decimal;
        PeriodCounts: array[3] of Integer;
        TotalCount: Integer;
        CustomerNo: Code[20];
        Amount: Decimal;
        i: Integer;
        j: Integer;
    begin
        // [SCENARIO] Check report dataset for customers by several entries in different periods
        Initialize();

        // [GIVEN] Create a Customer
        CustomerNo := LibrarySales.CreateCustomerNo();

        // [GIVEN] Create a payment practice header for Current Year of type Customer
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader, "Paym. Prac. Header Type"::Customer, "Paym. Prac. Aggregation Type"::Period);

        // [GIVEN] Post several entries for the customer in 3 different periods
        for i := 1 to 3 do
            for j := 1 to LibraryRandom.RandInt(10) do begin
                PeriodCounts[i] += 1;
                TotalCount += 1;
                Amount := MockCustomerInvoiceAndPaymentInPeriod(CustomerNo, WorkDate(), PaymentPeriods[i]."Days From", PaymentPeriods[i]."Days To");
                PeriodAmounts[i] += Amount;
                TotalAmount += Amount;
            end;

        // [WHEN] Lines were generated for Header
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] Check that report dataset contains correct percentages for each period
        PrepareExpectedPeriodPcts(ExpectedPeriodPcts, ExpectedPeriodAmountPcts, PeriodCounts, TotalCount, PeriodAmounts, TotalAmount);
        PaymentPracticesLibrary.VerifyPeriodLine(PaymentPracticeHeader."No.", "Paym. Prac. Header Type"::Customer, PaymentPeriods[1].Code, ExpectedPeriodPcts[1], ExpectedPeriodAmountPcts[1]);
        PaymentPracticesLibrary.VerifyPeriodLine(PaymentPracticeHeader."No.", "Paym. Prac. Header Type"::Customer, PaymentPeriods[2].Code, ExpectedPeriodPcts[2], ExpectedPeriodAmountPcts[2]);
        PaymentPracticesLibrary.VerifyPeriodLine(PaymentPracticeHeader."No.", "Paym. Prac. Header Type"::Customer, PaymentPeriods[3].Code, ExpectedPeriodPcts[3], ExpectedPeriodAmountPcts[3]);
    end;

    [Test]
    procedure ReportDataSetForCustomersVendorsByPeriod()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        Vendor_PeriodAmounts: array[3] of Decimal;
        Vendor_TotalAmount: Decimal;
        Vendor_PeriodCounts: array[3] of Integer;
        Vendor_TotalCount: Integer;
        Vendor_ExpectedPeriodPcts: array[3] of Decimal;
        Vendor_ExpectedPeriodAmountPcts: array[3] of Decimal;
        Customer_PeriodAmounts: array[3] of Decimal;
        Customer_TotalAmount: Decimal;
        Customer_PeriodCounts: array[3] of Integer;
        Customer_TotalCount: Integer;
        Customer_ExpectedPeriodPcts: array[3] of Decimal;
        Customer_ExpectedPeriodAmountPcts: array[3] of Decimal;
        CustomerNo: Code[20];
        VendorNo: Code[20];
        Amount: Decimal;
        i: Integer;
        j: Integer;
    begin
        // [SCENARIO] Check report dataset for customers by several entries in different periods
        Initialize();

        // [GIVEN] Create a Customer
        CustomerNo := LibrarySales.CreateCustomerNo();

        // [GIVEN] Create a vendor
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Create a payment practice header for Current Year of Type Vendor+Customer
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader, "Paym. Prac. Header Type"::"Vendor+Customer", "Paym. Prac. Aggregation Type"::Period);

        // [GIVEN] Post several entries for the vendor in 3 different periods
        for i := 1 to 3 do
            for j := 1 to LibraryRandom.RandInt(10) do begin
                Vendor_PeriodCounts[i] += 1;
                Vendor_TotalCount += 1;
                Amount := MockVendorInvoiceAndPaymentInPeriod(VendorNo, WorkDate(), PaymentPeriods[i]."Days From", PaymentPeriods[i]."Days To");
                Vendor_PeriodAmounts[i] += Amount;
                Vendor_TotalAmount += Amount;
            end;

        // [GIVEN] Post several entries for the customer in 3 different periods
        for i := 1 to 3 do
            for j := 1 to LibraryRandom.RandInt(10) do begin
                Customer_PeriodCounts[i] += 1;
                Customer_TotalCount += 1;
                Amount := MockCustomerInvoiceAndPaymentInPeriod(CustomerNo, WorkDate(), PaymentPeriods[i]."Days From", PaymentPeriods[i]."Days To");
                Customer_PeriodAmounts[i] += Amount;
                Customer_TotalAmount += Amount;
            end;

        // [WHEN] Lines were generated for Header
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] Check that report dataset contains correct percentages for each period for vendors
        PrepareExpectedPeriodPcts(Vendor_ExpectedPeriodPcts, Vendor_ExpectedPeriodAmountPcts, Vendor_PeriodCounts, Vendor_TotalCount, Vendor_PeriodAmounts, Vendor_TotalAmount);
        PaymentPracticesLibrary.VerifyPeriodLine(PaymentPracticeHeader."No.", "Paym. Prac. Header Type"::Vendor, PaymentPeriods[1].Code, Vendor_ExpectedPeriodPcts[1], Vendor_ExpectedPeriodAmountPcts[1]);
        PaymentPracticesLibrary.VerifyPeriodLine(PaymentPracticeHeader."No.", "Paym. Prac. Header Type"::Vendor, PaymentPeriods[2].Code, Vendor_ExpectedPeriodPcts[2], Vendor_ExpectedPeriodAmountPcts[2]);
        PaymentPracticesLibrary.VerifyPeriodLine(PaymentPracticeHeader."No.", "Paym. Prac. Header Type"::Vendor, PaymentPeriods[3].Code, Vendor_ExpectedPeriodPcts[3], Vendor_ExpectedPeriodAmountPcts[3]);

        // [THEN] Check that report dataset contains correct percentages for each period for customers
        PrepareExpectedPeriodPcts(Customer_ExpectedPeriodPcts, Customer_ExpectedPeriodAmountPcts, Customer_PeriodCounts, Customer_TotalCount, Customer_PeriodAmounts, Customer_TotalAmount);
        PaymentPracticesLibrary.VerifyPeriodLine(PaymentPracticeHeader."No.", "Paym. Prac. Header Type"::Customer, PaymentPeriods[1].Code, Customer_ExpectedPeriodPcts[1], Customer_ExpectedPeriodAmountPcts[1]);
        PaymentPracticesLibrary.VerifyPeriodLine(PaymentPracticeHeader."No.", "Paym. Prac. Header Type"::Customer, PaymentPeriods[2].Code, Customer_ExpectedPeriodPcts[2], Customer_ExpectedPeriodAmountPcts[2]);
        PaymentPracticesLibrary.VerifyPeriodLine(PaymentPracticeHeader."No.", "Paym. Prac. Header Type"::Customer, PaymentPeriods[3].Code, Customer_ExpectedPeriodPcts[3], Customer_ExpectedPeriodAmountPcts[3]);
    end;

    [Test]
    procedure AveragesCalculationInHeader_PctPaidOnTime()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        PaidOnTimeCount: Integer;
        PaidLateCount: Integer;
        UnpaidOverdueCount: Integer;
        ExpectedPctPaidOnTime: Decimal;
        VendorNo: Code[20];
        i: Integer;
    begin
        // [SCENARIO] Check averages calcation in header, for percentage of entries paid in time
        Initialize();

        // [GIVEN] Create a vendor
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Create a payment practice header for Current Year of type Vendor
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader, "Paym. Prac. Header Type"::Vendor, "Paym. Prac. Aggregation Type"::Period);

        // [GIVEN] Post several entries paid on time, this will affect total entries considered and total entries paid on time.
        PaidOnTimeCount := LibraryRandom.RandInt(20);
        for i := 1 to PaidOnTimeCount do
            MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate() + LibraryRandom.RandInt(10), WorkDate());

        // [GIVEN] Post several entries paid late, this will affect total entries considered.
        PaidLateCount := LibraryRandom.RandInt(20);
        for i := 1 to PaidLateCount do
            MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + LibraryRandom.RandInt(10));

        // [GIVEN] Post several entries unpaid overdue, this will affect total entries considered.
        UnpaidOverdueCount := LibraryRandom.RandInt(20);
        for i := 1 to UnpaidOverdueCount do
            MockVendorInvoice(VendorNo, WorkDate() - 50, WorkDate() - LibraryRandom.RandInt(40));

        // [GIVEN] Post several entries unpaid not overdue, these will not affect count
        for i := 1 to LibraryRandom.RandInt(20) do
            MockVendorInvoice(VendorNo, WorkDate(), WorkDate() + LibraryRandom.RandInt(10));

        // [WHEN] Lines were generated for Header
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] Check that report dataset contains correct percentage paid on time.
        ExpectedPctPaidOnTime := PaidOnTimeCount / (PaidOnTimeCount + PaidLateCount + UnpaidOverdueCount) * 100;
        PaymentPracticeHeader.Get(PaymentPracticeHeader."No.");
        Assert.AreNearlyEqual(ExpectedPctPaidOnTime, PaymentPracticeHeader."Pct Paid On Time", 0.01, 'Pct Paid On Time is not equal to expected.');
    end;

    [Test]
    procedure AveragesCalculationInHeader_ActualPaymentTime()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        ExpectedActualPaymentTime: Integer;
        TotalEntries: Integer;
        ActualPaymentTime: Integer;
        ActualPaymentTimeSum: Integer;
        i: Integer;
        VendorNo: Code[20];
    begin
        // [SCENARIO] Check averages calcation in header, for average actual payment times
        Initialize();

        // [GIVEN] Create a vendor
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Create a payment practice header for Current Year of type Vendor
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader, "Paym. Prac. Header Type"::Vendor, "Paym. Prac. Aggregation Type"::Period);

        // [GIVEN] Post a lot of entries with varying actual payment time
        TotalEntries := LibraryRandom.RandInt(100);
        for i := 1 to TotalEntries do begin
            ActualPaymentTime := LibraryRandom.RandInt(30);
            MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + ActualPaymentTime);
            ActualPaymentTimeSum += ActualPaymentTime;
        end;

        // [WHEN] Lines were generated for Header
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] Check that report dataset contains correct average for actual payment time. It's integer, so rounded.
        PaymentPracticeHeader.Get(PaymentPracticeHeader."No.");
        ExpectedActualPaymentTime := Round(ActualPaymentTimeSum / TotalEntries, 1);
        Assert.AreEqual(ExpectedActualPaymentTime, PaymentPracticeHeader."Average Actual Payment Period", 'Average Actual Payment Time is not equal to expected.');
    end;

    [Test]
    procedure AveragesCalculationInHeader_AgreedPaymentTime()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        ExpectedAgreedPaymentTime: Integer;
        TotalPaidEntries: Integer;
        TotalUnpaidEntries: Integer;
        AgreedPaymentTime: Integer;
        AgreedPaymentTimeSum: Integer;
        i: Integer;
        VendorNo: Code[20];
    begin
        // [SCENARIO] Check averages calcation in header, for agreed actual payment times
        Initialize();

        // [GIVEN] Create a vendor
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Create a payment practice header for Current Year of type Vendor
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader, "Paym. Prac. Header Type"::Vendor, "Paym. Prac. Aggregation Type"::Period);

        // [GIVEN] Post a lot of entries with varying agreed payment time. Paid
        TotalPaidEntries := LibraryRandom.RandInt(100);
        for i := 1 to TotalPaidEntries do begin
            AgreedPaymentTime := LibraryRandom.RandInt(30);
            MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate() + AgreedPaymentTime, WorkDate() + AgreedPaymentTime);
            AgreedPaymentTimeSum += AgreedPaymentTime;
        end;

        // [GIVEN] Post a lot of entries with varying agreed payment time. Unpaid
        TotalUnpaidEntries += LibraryRandom.RandInt(100);
        for i := 1 to TotalUnpaidEntries do begin
            AgreedPaymentTime := LibraryRandom.RandInt(30);
            MockVendorInvoice(VendorNo, WorkDate(), WorkDate() + AgreedPaymentTime);
            AgreedPaymentTimeSum += AgreedPaymentTime;
        end;
        // [WHEN] Lines were generated for Header
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] Check that report dataset contains correct average for agreed payment time. It's integer, so rounded.
        PaymentPracticeHeader.Get(PaymentPracticeHeader."No.");
        ExpectedAgreedPaymentTime := Round(AgreedPaymentTimeSum / (TotalPaidEntries + TotalUnpaidEntries), 1);
        Assert.AreEqual(ExpectedAgreedPaymentTime, PaymentPracticeHeader."Average Actual Payment Period", 'Average Actual Payment Time is not equal to expected.');
    end;


    [Test]
    procedure ReportDataSetForVendorsByPeriod_DaysToZero()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        PaymentPeriod: Record "Payment Period";
        VendorNo: Code[20];
    begin
        // [SCENARIO 493671] Payment is processed correctly for Payment Period with Days To = 0
        Initialize();

        // [GIVEN] Create a vendor
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Create a payment period with DaysTo = 0
        PaymentPracticesLibrary.InitAndGetLastPaymentPeriod(PaymentPeriod);

        // [GIVEN] Create a payment practice header for Current Year of type Vendor
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader, "Paym. Prac. Header Type"::Vendor, "Paym. Prac. Aggregation Type"::Period);

        // [GIVEN] Post an entry for the vendor in the period
        MockVendorInvoiceAndPaymentInPeriod(VendorNo, WorkDate(), PaymentPeriod."Days From", PaymentPeriod."Days To");

        // [WHEN] Lines were generated for Header
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] Check that report dataset contains the line for the period correcly
        PaymentPracticesLibrary.VerifyPeriodLine(PaymentPracticeHeader."No.", "Paym. Prac. Header Type"::Vendor, PaymentPeriod.Code, 100, 0);
    end;

    [Test]
    procedure PaymentPracticeHeader_EmptyDate()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
    begin
        // [SCENARIO 492413] Payment Practice header with empty date is not allowed to generate
        Initialize();

        // [GIVEN] Create a payment practice header with Starting Date = 0D
        PaymentPracticesLibrary.CreatePaymentPracticeHeader(PaymentPracticeHeader, "Paym. Prac. Header Type"::Vendor, "Paym. Prac. Aggregation Type"::"Company Size", 0D, 0D);

        // [WHEN] Generate payment practices for vendors by size
        asserterror PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] Error occurs for empty date
        Assert.ExpectedErrorCode('TestField');
    end;

    [Test]
    procedure PaymentPracticeHeader_ValidDates()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
    begin
        // [SCENARIO 492413] Payment Practice header can't accept starting date > ending date
        Initialize();

        // [GIVEN] Create a payment practice header with Starting Date = 0D and Ending date = 01/01/2020
        PaymentPracticesLibrary.CreatePaymentPracticeHeader(PaymentPracticeHeader, "Paym. Prac. Header Type"::Vendor, "Paym. Prac. Aggregation Type"::"Company Size", 0D, WorkDate());

        // [WHEN] Assigning Startin Date = 10/01/2020
        asserterror PaymentPracticeHeader.Validate("Starting Date", WorkDate() + LibraryRandom.RandInt(10));

        // [THEN] Error occurs for invalid dates
        Assert.ExpectedError('Starting Date must be less than or equal to Ending Date.');
    end;

    [Test]
    procedure PaymentPracticeLine_ModifiedManually()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        PaymentPracticeLine: Record "Payment Practice Line";
    begin
        // [SCENARIO 492413] Payment Practice Line "Modified Manually" gets changed when validating numerical values
        Initialize();

        // [GIVEN] Create vendor with size code
        PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(CompanySizeCodes[1], false);

        // [GIVEN] Generate payment practices for vendors by size
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader);
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [GIVEN] Find the generated line
        PaymentPracticeLine.SetRange("Header No.", PaymentPracticeHeader."No.");
        PaymentPracticeLine.FindFirst();

        // [WHEN] Modify Pct Paid in Period in line
        PaymentPracticeLine.Validate("Pct Paid in Period", LibraryRandom.RandDecInDecimalRange(0, 50, 2));
        PaymentPracticeLine.Modify();

        // [THEN] "Modified Manually" = true
        PaymentPracticeLine.TestField("Modified Manually");
    end;

    [Test]
    procedure ModePaymentTimeCalculation()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        VendorNo: Code[20];
    begin
        // [SCENARIO] Check mode payment time calculation in header
        Initialize();

        // [GIVEN] Create a vendor
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Create a payment practice header with Extra Fields enabled
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader, "Paym. Prac. Header Type"::Vendor, "Paym. Prac. Aggregation Type"::Period);
        PaymentPracticeHeader."Reporting Scheme" := "Paym. Prac. Extra Fields"::"Percentiles; Modes; Pct Peppol Enabled; Pct Small Business Payments";
        PaymentPracticeHeader.Modify();

        // [GIVEN] Post entries with payment times: 5, 5, 5, 10, 10, 15 (mode = 5)
        MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + 5);
        MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + 5);
        MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + 5);
        MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + 10);
        MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + 10);
        MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + 15);

        // [WHEN] Lines were generated for Header
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] Mode Payment Time = 5
        PaymentPracticeHeader.Get(PaymentPracticeHeader."No.");
        Assert.AreEqual(5, PaymentPracticeHeader."Mode Payment Time", 'Mode Payment Time is not equal to expected.');
    end;

    [Test]
    procedure ModePaymentTimeMinCalculation()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        VendorNo1: Code[20];
        VendorNo2: Code[20];
    begin
        // [SCENARIO] Check mode payment time min is the minimum of per-vendor modes
        Initialize();

        // [GIVEN] Create two vendors
        VendorNo1 := LibraryPurchase.CreateVendorNo();
        VendorNo2 := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Create a payment practice header with Extra Fields enabled
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader, "Paym. Prac. Header Type"::Vendor, "Paym. Prac. Aggregation Type"::Period);
        PaymentPracticeHeader."Extra Fields" := "Paym. Prac. Extra Fields"::"Percentiles; Modes; Pct Peppol Enabled; Pct Small Business Payments";
        PaymentPracticeHeader.Modify();

        // [GIVEN] Vendor 1: payment times 5, 5, 10 (mode = 5)
        MockVendorInvoiceAndPayment(VendorNo1, WorkDate(), WorkDate(), WorkDate() + 5);
        MockVendorInvoiceAndPayment(VendorNo1, WorkDate(), WorkDate(), WorkDate() + 5);
        MockVendorInvoiceAndPayment(VendorNo1, WorkDate(), WorkDate(), WorkDate() + 10);

        // [GIVEN] Vendor 2: payment times 8, 8, 12 (mode = 8)
        MockVendorInvoiceAndPayment(VendorNo2, WorkDate(), WorkDate(), WorkDate() + 8);
        MockVendorInvoiceAndPayment(VendorNo2, WorkDate(), WorkDate(), WorkDate() + 8);
        MockVendorInvoiceAndPayment(VendorNo2, WorkDate(), WorkDate(), WorkDate() + 12);

        // [WHEN] Lines were generated for Header
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] Mode Payment Time Min = 5 (minimum of per-vendor modes 5 and 8)
        PaymentPracticeHeader.Get(PaymentPracticeHeader."No.");
        Assert.AreEqual(5, PaymentPracticeHeader."Mode Payment Time Min.", 'Mode Payment Time Min. is not equal to expected.');
    end;

    [Test]
    procedure ModePaymentTimeMaxCalculation()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        VendorNo1: Code[20];
        VendorNo2: Code[20];
    begin
        // [SCENARIO] Check mode payment time max is the maximum of per-vendor modes
        Initialize();

        // [GIVEN] Create two vendors
        VendorNo1 := LibraryPurchase.CreateVendorNo();
        VendorNo2 := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Create a payment practice header with Extra Fields enabled
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader, "Paym. Prac. Header Type"::Vendor, "Paym. Prac. Aggregation Type"::Period);
        PaymentPracticeHeader."Extra Fields" := "Paym. Prac. Extra Fields"::"Percentiles; Modes; Pct Peppol Enabled; Pct Small Business Payments";
        PaymentPracticeHeader.Modify();

        // [GIVEN] Vendor 1: payment times 5, 5, 10 (mode = 5)
        MockVendorInvoiceAndPayment(VendorNo1, WorkDate(), WorkDate(), WorkDate() + 5);
        MockVendorInvoiceAndPayment(VendorNo1, WorkDate(), WorkDate(), WorkDate() + 5);
        MockVendorInvoiceAndPayment(VendorNo1, WorkDate(), WorkDate(), WorkDate() + 10);

        // [GIVEN] Vendor 2: payment times 8, 8, 12 (mode = 8)
        MockVendorInvoiceAndPayment(VendorNo2, WorkDate(), WorkDate(), WorkDate() + 8);
        MockVendorInvoiceAndPayment(VendorNo2, WorkDate(), WorkDate(), WorkDate() + 8);
        MockVendorInvoiceAndPayment(VendorNo2, WorkDate(), WorkDate(), WorkDate() + 12);

        // [WHEN] Lines were generated for Header
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] Mode Payment Time Max = 8 (maximum of per-vendor modes 5 and 8)
        PaymentPracticeHeader.Get(PaymentPracticeHeader."No.");
        Assert.AreEqual(8, PaymentPracticeHeader."Mode Payment Time Max.", 'Mode Payment Time Max. is not equal to expected.');
    end;

    [Test]
    procedure MedianPaymentTimeCalculation()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        VendorNo: Code[20];
    begin
        // [SCENARIO] Check median payment time calculation with odd number of entries
        Initialize();

        // [GIVEN] Create a vendor
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Create a payment practice header with Extra Fields enabled
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader, "Paym. Prac. Header Type"::Vendor, "Paym. Prac. Aggregation Type"::Period);
        PaymentPracticeHeader."Extra Fields" := "Paym. Prac. Extra Fields"::"Percentiles; Modes; Pct Peppol Enabled; Pct Small Business Payments";
        PaymentPracticeHeader.Modify();

        // [GIVEN] Post entries with payment times: 3, 7, 5, 11, 9 (sorted: 3, 5, 7, 9, 11; median = 7)
        MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + 3);
        MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + 7);
        MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + 5);
        MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + 11);
        MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + 9);

        // [WHEN] Lines were generated for Header
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] Median Payment Time = 7
        PaymentPracticeHeader.Get(PaymentPracticeHeader."No.");
        Assert.AreEqual(7, PaymentPracticeHeader."Median Payment Time", 'Median Payment Time is not equal to expected.');
    end;

    [Test]
    procedure MedianPaymentTimeCalculation_EvenCount()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        VendorNo: Code[20];
    begin
        // [SCENARIO] Check median payment time calculation with even number of entries
        Initialize();

        // [GIVEN] Create a vendor
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Create a payment practice header with Extra Fields enabled
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader, "Paym. Prac. Header Type"::Vendor, "Paym. Prac. Aggregation Type"::Period);
        PaymentPracticeHeader."Extra Fields" := "Paym. Prac. Extra Fields"::"Percentiles; Modes; Pct Peppol Enabled; Pct Small Business Payments";
        PaymentPracticeHeader.Modify();

        // [GIVEN] Post entries with payment times: 4, 10, 2, 8 (sorted: 2, 4, 8, 10; median = (4 + 8) / 2 = 6)
        MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + 4);
        MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + 10);
        MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + 2);
        MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + 8);

        // [WHEN] Lines were generated for Header
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] Median Payment Time = 6 (average of two middle values)
        PaymentPracticeHeader.Get(PaymentPracticeHeader."No.");
        Assert.AreEqual(6, PaymentPracticeHeader."Median Payment Time", 'Median Payment Time is not equal to expected.');
    end;

    [Test]
    procedure Percentile80thPaymentTimeCalculation()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        VendorNo: Code[20];
        i: Integer;
    begin
        // [SCENARIO] Check 80th percentile payment time calculation
        Initialize();

        // [GIVEN] Create a vendor
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Create a payment practice header with Extra Fields enabled
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader, "Paym. Prac. Header Type"::Vendor, "Paym. Prac. Aggregation Type"::Period);
        PaymentPracticeHeader."Extra Fields" := "Paym. Prac. Extra Fields"::"Percentiles; Modes; Pct Peppol Enabled; Pct Small Business Payments";
        PaymentPracticeHeader.Modify();

        // [GIVEN] Post 10 entries with payment times 1 through 10
        for i := 1 to 10 do
            MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + i);

        // [WHEN] Lines were generated for Header
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] 80th percentile = 8 (index = 10 * 80 div 100 = 8)
        PaymentPracticeHeader.Get(PaymentPracticeHeader."No.");
        Assert.AreEqual(8, PaymentPracticeHeader."80th Percentile Payment Time", '80th Percentile Payment Time is not equal to expected.');
    end;

    [Test]
    procedure Percentile95thPaymentTimeCalculation()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        VendorNo: Code[20];
        i: Integer;
    begin
        // [SCENARIO] Check 95th percentile payment time calculation
        Initialize();

        // [GIVEN] Create a vendor
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Create a payment practice header with Extra Fields enabled
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader, "Paym. Prac. Header Type"::Vendor, "Paym. Prac. Aggregation Type"::Period);
        PaymentPracticeHeader."Extra Fields" := "Paym. Prac. Extra Fields"::"Percentiles; Modes; Pct Peppol Enabled; Pct Small Business Payments";
        PaymentPracticeHeader.Modify();

        // [GIVEN] Post 20 entries with payment times 1 through 20
        for i := 1 to 20 do
            MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + i);

        // [WHEN] Lines were generated for Header
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] 95th percentile = 19 (index = 20 * 95 div 100 = 19)
        PaymentPracticeHeader.Get(PaymentPracticeHeader."No.");
        Assert.AreEqual(19, PaymentPracticeHeader."95th Percentile Payment Time", '95th Percentile Payment Time is not equal to expected.');
    end;

    [Test]
    procedure Percentile80thPaymentTime_FractionalIndex()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        VendorNo: Code[20];
        i: Integer;
    begin
        // [SCENARIO] Check 80th percentile when index is not a whole number (7 * 80 / 100 = 5.6, truncated to 5)
        Initialize();

        // [GIVEN] Create a vendor
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Create a payment practice header with Extra Fields enabled
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader, "Paym. Prac. Header Type"::Vendor, "Paym. Prac. Aggregation Type"::Period);
        PaymentPracticeHeader."Extra Fields" := "Paym. Prac. Extra Fields"::"Percentiles; Modes; Pct Peppol Enabled; Pct Small Business Payments";
        PaymentPracticeHeader.Modify();

        // [GIVEN] Post 7 entries with payment times 1 through 7
        for i := 1 to 7 do
            MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + i);

        // [WHEN] Lines were generated for Header
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] 80th percentile = 5 (index = 7 * 80 div 100 = 5, no interpolation)
        PaymentPracticeHeader.Get(PaymentPracticeHeader."No.");
        Assert.AreEqual(5, PaymentPracticeHeader."80th Percentile Payment Time", '80th Percentile Payment Time is not equal to expected.');
    end;

    [Test]
    procedure Percentile95thPaymentTime_FractionalIndex()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        VendorNo: Code[20];
        i: Integer;
    begin
        // [SCENARIO] Check 95th percentile when index is not a whole number (13 * 95 / 100 = 12.35, truncated to 12)
        Initialize();

        // [GIVEN] Create a vendor
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Create a payment practice header with Extra Fields enabled
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader, "Paym. Prac. Header Type"::Vendor, "Paym. Prac. Aggregation Type"::Period);
        PaymentPracticeHeader."Extra Fields" := "Paym. Prac. Extra Fields"::"Percentiles; Modes; Pct Peppol Enabled; Pct Small Business Payments";
        PaymentPracticeHeader.Modify();

        // [GIVEN] Post 13 entries with payment times 1 through 13
        for i := 1 to 13 do
            MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + i);

        // [WHEN] Lines were generated for Header
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] 95th percentile = 12 (index = 13 * 95 div 100 = 12, no interpolation)
        PaymentPracticeHeader.Get(PaymentPracticeHeader."No.");
        Assert.AreEqual(12, PaymentPracticeHeader."95th Percentile Payment Time", '95th Percentile Payment Time is not equal to expected.');
    end;

    [Test]
    procedure PctPeppolEnabledCalculation()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        Vendor: Record Vendor;
        VendorWithGLN: Code[20];
        VendorWithoutGLN: Code[20];
        PeppolInvoiceCount: Integer;
        NonPeppolInvoiceCount: Integer;
        ExpectedPctPeppol: Decimal;
        i: Integer;
    begin
        // [SCENARIO] Check Pct Peppol Enabled calculation with one vendor that has GLN and one that does not.
        Initialize();

        // [GIVEN] Create a vendor with a GLN value (Peppol enabled)
        VendorWithGLN := LibraryPurchase.CreateVendorNo();
        Vendor.Get(VendorWithGLN);
        Vendor.GLN := '1234567890123';
        Vendor.Modify();

        // [GIVEN] Create a vendor without a GLN value (not Peppol enabled)
        VendorWithoutGLN := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Create a payment practice header with Extra Fields enabled
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader, "Paym. Prac. Header Type"::Vendor, "Paym. Prac. Aggregation Type"::Period);
        PaymentPracticeHeader."Extra Fields" := "Paym. Prac. Extra Fields"::"Percentiles; Modes; Pct Peppol Enabled; Pct Small Business Payments";
        PaymentPracticeHeader.Modify();

        // [GIVEN] Post 3 paid invoices for the GLN vendor
        PeppolInvoiceCount := 3;
        for i := 1 to PeppolInvoiceCount do
            MockVendorInvoiceAndPayment(VendorWithGLN, WorkDate(), WorkDate(), WorkDate() + 5);

        // [GIVEN] Post 2 paid invoices for the non-GLN vendor
        NonPeppolInvoiceCount := 2;
        for i := 1 to NonPeppolInvoiceCount do
            MockVendorInvoiceAndPayment(VendorWithoutGLN, WorkDate(), WorkDate(), WorkDate() + 10);

        // [WHEN] Generate payment practices
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] Pct Peppol Enabled = 3 / 5 * 100 = 60 (percentage of invoices from vendors with GLN)
        PaymentPracticeHeader.Get(PaymentPracticeHeader."No.");
        ExpectedPctPeppol := PeppolInvoiceCount / (PeppolInvoiceCount + NonPeppolInvoiceCount) * 100;
        Assert.AreNearlyEqual(ExpectedPctPeppol, PaymentPracticeHeader."Pct Peppol Enabled", 0.01, 'Pct Peppol Enabled is not equal to expected.');
    end;

    [Test]
    procedure OnlySmallBusinesses_StatisticsAndPctSmallBusinessPayments()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        SmallBizSizeCode: Code[20];
        NonSmallBizSizeCode: Code[20];
        SmallBizVendor1: Code[20];
        SmallBizVendor2: Code[20];
        NonSmallBizVendor1: Code[20];
        NonSmallBizVendor2: Code[20];
    begin
        // [SCENARIO] Generate payment practices with "Only Small Businesses" enabled. Only small business vendors should be included in the statistics (median, mode, percentiles) .
        Initialize();

        // [GIVEN] Create a company size marked as "Small Business" and one that is not
        SmallBizSizeCode := PaymentPracticesLibrary.CreateCompanySizeCode(true);
        NonSmallBizSizeCode := PaymentPracticesLibrary.CreateCompanySizeCode(false);

        // [GIVEN] Create 2 vendors with the small business company size
        SmallBizVendor1 := PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(SmallBizSizeCode, false);
        SmallBizVendor2 := PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(SmallBizSizeCode, false);

        // [GIVEN] Create 2 vendors with the non-small business company size
        NonSmallBizVendor1 := PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(NonSmallBizSizeCode, false);
        NonSmallBizVendor2 := PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(NonSmallBizSizeCode, false);

        // [GIVEN] Post paid invoices for small business vendor 1 with payment times 5, 5, 10
        MockVendorInvoiceAndPayment(SmallBizVendor1, WorkDate(), WorkDate(), WorkDate() + 5);
        MockVendorInvoiceAndPayment(SmallBizVendor1, WorkDate(), WorkDate(), WorkDate() + 5);
        MockVendorInvoiceAndPayment(SmallBizVendor1, WorkDate(), WorkDate(), WorkDate() + 10);

        // [GIVEN] Post paid invoices for small business vendor 2 with payment times 8, 8
        MockVendorInvoiceAndPayment(SmallBizVendor2, WorkDate(), WorkDate(), WorkDate() + 8);
        MockVendorInvoiceAndPayment(SmallBizVendor2, WorkDate(), WorkDate(), WorkDate() + 8);

        // [GIVEN] Post paid invoices for non-small business vendor 1 with payment time 20
        MockVendorInvoiceAndPayment(NonSmallBizVendor1, WorkDate(), WorkDate(), WorkDate() + 20);

        // [GIVEN] Post paid invoices for non-small business vendor 2 with payment time 30
        MockVendorInvoiceAndPayment(NonSmallBizVendor2, WorkDate(), WorkDate(), WorkDate() + 30);

        // [GIVEN] Create a payment practice header with "Only Small Businesses" and Extra Fields enabled
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader, "Paym. Prac. Header Type"::Vendor, "Paym. Prac. Aggregation Type"::Period);
        PaymentPracticeHeader."Only Small Businesses" := true;
        PaymentPracticeHeader."Extra Fields" := "Paym. Prac. Extra Fields"::"Percentiles; Modes; Pct Peppol Enabled; Pct Small Business Payments";
        PaymentPracticeHeader.Modify();

        // [WHEN] Generate payment practices
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] Only 5 entries should be in the buffer (only small business vendors)
        PaymentPracticesLibrary.VerifyBufferCount(PaymentPracticeHeader, 5, "Paym. Prac. Header Type"::Vendor);

        // [THEN] Check header statistics - computed only from small business vendor data
        // Payment times: 5, 5, 8, 8, 10 (sorted)
        PaymentPracticeHeader.Get(PaymentPracticeHeader."No.");

        // Mode = 5 (most frequent across all data: 5 appears twice, 8 appears twice - tie broken by smallest)
        Assert.AreEqual(5, PaymentPracticeHeader."Mode Payment Time", 'Mode Payment Time is not equal to expected.');

        // Mode Min = minimum of per-vendor modes: vendor1 mode = 5, vendor2 mode = 8 → min = 5
        Assert.AreEqual(5, PaymentPracticeHeader."Mode Payment Time Min.", 'Mode Payment Time Min. is not equal to expected.');

        // Mode Max = maximum of per-vendor modes: vendor1 mode = 5, vendor2 mode = 8 → max = 8
        Assert.AreEqual(8, PaymentPracticeHeader."Mode Payment Time Max.", 'Mode Payment Time Max. is not equal to expected.');

        // Median of 5, 5, 8, 8, 10 (odd count = 5) → middle value = 8
        Assert.AreEqual(8, PaymentPracticeHeader."Median Payment Time", 'Median Payment Time is not equal to expected.');

        // 80th percentile: index = 5 * 80 div 100 = 4 → sorted[4] = 8
        Assert.AreEqual(8, PaymentPracticeHeader."80th Percentile Payment Time", '80th Percentile Payment Time is not equal to expected.');

        // 95th percentile: index = 5 * 95 div 100 = 4 → sorted[4] = 8
        Assert.AreEqual(8, PaymentPracticeHeader."95th Percentile Payment Time", '95th Percentile Payment Time is not equal to expected.');
    end;

    [Test]
    procedure OnlySmallBusinesses_ResetWhenHeaderTypeNotVendor()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
    begin
        // [SCENARIO] "Only Small Businesses" is reset to false when Header Type is changed to a non-Vendor type.
        Initialize();

        // [GIVEN] A payment practice header of type Vendor with "Only Small Businesses" enabled
        PaymentPracticesLibrary.CreatePaymentPracticeHeader(PaymentPracticeHeader, "Paym. Prac. Header Type"::Vendor, "Paym. Prac. Aggregation Type"::Period, WorkDate() - 180, WorkDate() + 180);
        PaymentPracticeHeader."Only Small Businesses" := true;
        PaymentPracticeHeader.Modify();

        // [WHEN] Header Type is changed to Customer
        PaymentPracticeHeader.Validate("Header Type", "Paym. Prac. Header Type"::Customer);

        // [THEN] "Only Small Businesses" is reset to false
        PaymentPracticeHeader.TestField("Only Small Businesses", false);
    end;

    [Test]
    procedure PaymentPracticeCardLinesPartAlwaysVisible()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        PaymentPracticeCard: TestPage "Payment Practice Card";
        VendorNo: Code[20];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 626602] Lines part on Payment Practice Card is visible after clicking Generate
        Initialize();

        // [GIVEN] Vendor "V" with company size and an entry in the period
        VendorNo := PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(CompanySizeCodes[1], false);
        MockVendorInvoice(VendorNo, WorkDate(), WorkDate());

        // [GIVEN] A payment practice header "PPH"
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader);

        // [WHEN] Open the Payment Practice Card for "PPH"
        PaymentPracticeCard.OpenEdit();
        PaymentPracticeCard.Filter.SetFilter("No.", Format(PaymentPracticeHeader."No."));

        // [THEN] Lines part is visible even before generating
        Assert.IsTrue(PaymentPracticeCard.Lines.Visible(), 'Lines part should be visible before generating.');

        // [WHEN] Generate the payment practice lines
        PaymentPracticeCard.Generate.Invoke();

        // [THEN] Lines part is still visible after generating
        Assert.IsTrue(PaymentPracticeCard.Lines.Visible(), 'Lines part should be visible after generating.');

        PaymentPracticeCard.Close();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Payment Practices UT");

        // This is so demodata and previous tests doesn't influence the tests
        PaymentPracticesLibrary.SetExcludeFromPaymentPracticesOnAllVendorsAndCustomers();

        if Initialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Payment Practices UT");

        PaymentPracticesLibrary.InitializeCompanySizes(CompanySizeCodes);
        PaymentPracticesLibrary.InitializePaymentPeriods(PaymentPeriods);
        Initialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Payment Practices UT");
    end;

    local procedure MockVendLedgerEntry(VendorNo: Code[20]; var VendorLedgerEntry: Record "Vendor Ledger Entry"; DocType: Enum "Gen. Journal Document Type"; PostingDate: Date; DueDate: Date; PmtPostingDate: Date; IsOpen: Boolean)
    begin
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Document Type" := DocType;
        VendorLedgerEntry."Posting Date" := PostingDate;
        VendorLedgerEntry."Document Date" := PostingDate;
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry."Due Date" := DueDate;
        VendorLedgerEntry.Open := IsOpen;
        VendorLedgerEntry."Closed at Date" := PmtPostingDate;
        VendorLedgerEntry.Amount := LibraryRandom.RandDec(1000, 2);
        VendorLedgerEntry.Insert();
    end;

    local procedure MockVendorInvoice(VendorNo: Code[20]; PostingDate: Date; DueDate: Date) InvoiceAmount: Decimal;
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        MockVendLedgerEntry(VendorNo, VendorLedgerEntry, "Gen. Journal Document Type"::Invoice, PostingDate, DueDate, 0D, true);
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        InvoiceAmount := VendorLedgerEntry."Amount (LCY)";
    end;

    local procedure MockVendorInvoiceAndPayment(VendorNo: Code[20]; PostingDate: Date; DueDate: Date; PaymentPostingDate: Date) InvoiceAmount: Decimal;
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        MockVendLedgerEntry(VendorNo, VendorLedgerEntry, "Gen. Journal Document Type"::Invoice, PostingDate, DueDate, PaymentPostingDate, false);
        VendorLedgerEntry.CalcFields("Amount (LCY)");
        InvoiceAmount := VendorLedgerEntry."Amount (LCY)";
    end;

    local procedure MockVendorInvoiceAndPaymentInPeriod(VendorNo: Code[20]; StartingDate: Date; PaidInDays_min: Integer; PaidInDays_max: Integer) InvoiceAmount: Decimal;
    var
        PostingDate: Date;
        DueDate: Date;
        PaymentPostingDate: Date;
    begin
        PostingDate := StartingDate;
        DueDate := StartingDate;
        if PaidInDays_max <> 0 then
            PaymentPostingDate := PostingDate + LibraryRandom.RandIntInRange(PaidInDays_min, PaidInDays_max)
        else
            PaymentPostingDate := PostingDate + PaidInDays_min + LibraryRandom.RandInt(10);
        InvoiceAmount := MockVendorInvoiceAndPayment(VendorNo, PostingDate, DueDate, PaymentPostingDate);
    end;

    local procedure MockCustLedgerEntry(CustomerNo: Code[20]; var CustLedgerEntry: Record "Cust. Ledger Entry"; DocType: Enum "Gen. Journal Document Type"; PostingDate: Date; DueDate: Date; PmtPostingDate: Date; IsOpen: Boolean)
    begin
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry."Document Type" := DocType;
        CustLedgerEntry."Posting Date" := PostingDate;
        CustLedgerEntry."Document Date" := PostingDate;
        CustLedgerEntry."Customer No." := CustomerNo;
        CustLedgerEntry."Due Date" := DueDate;
        CustLedgerEntry.Open := IsOpen;
        CustLedgerEntry."Closed at Date" := PmtPostingDate;
        CustLedgerEntry.Amount := LibraryRandom.RandDec(1000, 2);
        CustLedgerEntry.Insert();
    end;

    local procedure MockCustomerInvoice(CustomerNo: Code[20]; PostingDate: Date; DueDate: Date) InvoiceAmount: Decimal;
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        MockCustLedgerEntry(CustomerNo, CustLedgerEntry, "Gen. Journal Document Type"::Invoice, PostingDate, DueDate, 0D, true);
        CustLedgerEntry.CalcFields("Amount (LCY)");
        InvoiceAmount := CustLedgerEntry."Amount (LCY)";
    end;

    local procedure MockCustomerInvoiceAndPayment(CustomerNo: Code[20]; PostingDate: Date; DueDate: Date; PaymentPostingDate: Date) InvoiceAmount: Decimal;
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        MockCustLedgerEntry(CustomerNo, CustLedgerEntry, "Gen. Journal Document Type"::Invoice, PostingDate, DueDate, PaymentPostingDate, false);
        CustLedgerEntry.CalcFields("Amount (LCY)");
        InvoiceAmount := CustLedgerEntry."Amount (LCY)";
    end;

    local procedure MockCustomerInvoiceAndPaymentInPeriod(CustomerNo: Code[20]; StartingDate: Date; PaidInDays_min: Integer; PaidInDays_max: Integer) InvoiceAmount: Decimal;
    var
        PostingDate: Date;
        DueDate: Date;
        PaymentPostingDate: Date;
    begin
        PostingDate := StartingDate;
        DueDate := StartingDate + LibraryRandom.RandIntInRange(1, 5);
        PaymentPostingDate := PostingDate + LibraryRandom.RandIntInRange(PaidInDays_min, PaidInDays_max);
        InvoiceAmount := MockCustomerInvoiceAndPayment(CustomerNo, PostingDate, DueDate, PaymentPostingDate);
    end;

    local procedure PrepareExpectedPeriodPcts(var ExpectedPeriodPcts: array[3] of Decimal; var ExpectedPeriodAmountPcts: array[3] of Decimal; PeriodCounts: array[3] of Integer; TotalCount: Integer; PeriodAmounts: array[3] of Decimal; TotalAmount: Decimal)
    var
        i: Integer;
    begin
        for i := 1 to ArrayLen(ExpectedPeriodPcts) do begin
            if TotalCount <> 0 then
                ExpectedPeriodPcts[i] := PeriodCounts[i] / TotalCount * 100;
            if TotalAmount <> 0 then
                ExpectedPeriodAmountPcts[i] := PeriodAmounts[i] / TotalAmount * 100;
        end;
    end;

    [ConfirmHandler]
    procedure ConfirmHandler_Yes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandler_No(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}
