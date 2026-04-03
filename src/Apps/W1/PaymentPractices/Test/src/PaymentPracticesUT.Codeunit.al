// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AA0210 // table does not contain key with field A
namespace Microsoft.Test.Finance.Analysis;

using Microsoft.Finance.Analysis;
using Microsoft.Sales.Customer;
using System.Utilities;

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
        PaymentPeriods: array[3] of Record "Payment Period Line";
        Assert: Codeunit "Assert";
        PaymentPracticesLibrary: Codeunit "Payment Practices Library";
        PaymentPractices: Codeunit "Payment Practices";
        LibraryPurchase: Codeunit "Library - Purchase";
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
        PaymentPracticesLibrary.MockVendorInvoice(VendorNo, WorkDate(), WorkDate());

        // [GIVEN]Vendor with company size and an entry in the period, but with Excl. from Payment Practice = true
        VendorExcludedNo := PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(CompanySizeCodes[2], true);
        PaymentPracticesLibrary.MockVendorInvoice(VendorExcludedNo, WorkDate(), WorkDate());

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
        PaymentPracticesLibrary.MockCustomerInvoice(Customer."No.", WorkDate(), WorkDate());

        // [GIVEN] Customer with an entry in the period, but with Excl. from Payment Practice = true
        LibrarySales.CreateCustomer(CustomerExcluded);
        PaymentPracticesLibrary.SetExcludeFromPaymentPractices(CustomerExcluded, true);
        PaymentPracticesLibrary.MockCustomerInvoice(CustomerExcluded."No.", WorkDate(), WorkDate());

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
        PaymentPracticesLibrary.MockVendorInvoice(VendorNo, WorkDate(), WorkDate());

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
        PaymentPracticesLibrary.MockVendorInvoice(VendorNo, WorkDate(), WorkDate());

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
        PaymentPracticesLibrary.MockVendorInvoice(VendorNo, WorkDate(), WorkDate());

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
                Amount := PaymentPracticesLibrary.MockVendorInvoiceAndPaymentInPeriod(VendorNo, WorkDate(), PaymentPeriods[i]."Days From", PaymentPeriods[i]."Days To");
                PeriodAmounts[i] += Amount;
                TotalAmount += Amount;
            end;

        // [WHEN] Lines were generated for Header
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] Check that report dataset contains correct percentages for each period
        PrepareExpectedPeriodPcts(ExpectedPeriodPcts, ExpectedPeriodAmountPcts, PeriodCounts, TotalCount, PeriodAmounts, TotalAmount);
        PaymentPracticesLibrary.VerifyPeriodLine(PaymentPracticeHeader."No.", "Paym. Prac. Header Type"::Vendor, PaymentPeriods[1].Description, ExpectedPeriodPcts[1], ExpectedPeriodAmountPcts[1]);
        PaymentPracticesLibrary.VerifyPeriodLine(PaymentPracticeHeader."No.", "Paym. Prac. Header Type"::Vendor, PaymentPeriods[2].Description, ExpectedPeriodPcts[2], ExpectedPeriodAmountPcts[2]);
        PaymentPracticesLibrary.VerifyPeriodLine(PaymentPracticeHeader."No.", "Paym. Prac. Header Type"::Vendor, PaymentPeriods[3].Description, ExpectedPeriodPcts[3], ExpectedPeriodAmountPcts[3]);
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
                Amount := PaymentPracticesLibrary.MockCustomerInvoiceAndPaymentInPeriod(CustomerNo, WorkDate(), PaymentPeriods[i]."Days From", PaymentPeriods[i]."Days To");
                PeriodAmounts[i] += Amount;
                TotalAmount += Amount;
            end;

        // [WHEN] Lines were generated for Header
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] Check that report dataset contains correct percentages for each period
        PrepareExpectedPeriodPcts(ExpectedPeriodPcts, ExpectedPeriodAmountPcts, PeriodCounts, TotalCount, PeriodAmounts, TotalAmount);
        PaymentPracticesLibrary.VerifyPeriodLine(PaymentPracticeHeader."No.", "Paym. Prac. Header Type"::Customer, PaymentPeriods[1].Description, ExpectedPeriodPcts[1], ExpectedPeriodAmountPcts[1]);
        PaymentPracticesLibrary.VerifyPeriodLine(PaymentPracticeHeader."No.", "Paym. Prac. Header Type"::Customer, PaymentPeriods[2].Description, ExpectedPeriodPcts[2], ExpectedPeriodAmountPcts[2]);
        PaymentPracticesLibrary.VerifyPeriodLine(PaymentPracticeHeader."No.", "Paym. Prac. Header Type"::Customer, PaymentPeriods[3].Description, ExpectedPeriodPcts[3], ExpectedPeriodAmountPcts[3]);
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
                Amount := PaymentPracticesLibrary.MockVendorInvoiceAndPaymentInPeriod(VendorNo, WorkDate(), PaymentPeriods[i]."Days From", PaymentPeriods[i]."Days To");
                Vendor_PeriodAmounts[i] += Amount;
                Vendor_TotalAmount += Amount;
            end;

        // [GIVEN] Post several entries for the customer in 3 different periods
        for i := 1 to 3 do
            for j := 1 to LibraryRandom.RandInt(10) do begin
                Customer_PeriodCounts[i] += 1;
                Customer_TotalCount += 1;
                Amount := PaymentPracticesLibrary.MockCustomerInvoiceAndPaymentInPeriod(CustomerNo, WorkDate(), PaymentPeriods[i]."Days From", PaymentPeriods[i]."Days To");
                Customer_PeriodAmounts[i] += Amount;
                Customer_TotalAmount += Amount;
            end;

        // [WHEN] Lines were generated for Header
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] Check that report dataset contains correct percentages for each period for vendors
        PrepareExpectedPeriodPcts(Vendor_ExpectedPeriodPcts, Vendor_ExpectedPeriodAmountPcts, Vendor_PeriodCounts, Vendor_TotalCount, Vendor_PeriodAmounts, Vendor_TotalAmount);
        PaymentPracticesLibrary.VerifyPeriodLine(PaymentPracticeHeader."No.", "Paym. Prac. Header Type"::Vendor, PaymentPeriods[1].Description, Vendor_ExpectedPeriodPcts[1], Vendor_ExpectedPeriodAmountPcts[1]);
        PaymentPracticesLibrary.VerifyPeriodLine(PaymentPracticeHeader."No.", "Paym. Prac. Header Type"::Vendor, PaymentPeriods[2].Description, Vendor_ExpectedPeriodPcts[2], Vendor_ExpectedPeriodAmountPcts[2]);
        PaymentPracticesLibrary.VerifyPeriodLine(PaymentPracticeHeader."No.", "Paym. Prac. Header Type"::Vendor, PaymentPeriods[3].Description, Vendor_ExpectedPeriodPcts[3], Vendor_ExpectedPeriodAmountPcts[3]);

        // [THEN] Check that report dataset contains correct percentages for each period for customers
        PrepareExpectedPeriodPcts(Customer_ExpectedPeriodPcts, Customer_ExpectedPeriodAmountPcts, Customer_PeriodCounts, Customer_TotalCount, Customer_PeriodAmounts, Customer_TotalAmount);
        PaymentPracticesLibrary.VerifyPeriodLine(PaymentPracticeHeader."No.", "Paym. Prac. Header Type"::Customer, PaymentPeriods[1].Description, Customer_ExpectedPeriodPcts[1], Customer_ExpectedPeriodAmountPcts[1]);
        PaymentPracticesLibrary.VerifyPeriodLine(PaymentPracticeHeader."No.", "Paym. Prac. Header Type"::Customer, PaymentPeriods[2].Description, Customer_ExpectedPeriodPcts[2], Customer_ExpectedPeriodAmountPcts[2]);
        PaymentPracticesLibrary.VerifyPeriodLine(PaymentPracticeHeader."No.", "Paym. Prac. Header Type"::Customer, PaymentPeriods[3].Description, Customer_ExpectedPeriodPcts[3], Customer_ExpectedPeriodAmountPcts[3]);
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
            PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate() + LibraryRandom.RandInt(10), WorkDate());

        // [GIVEN] Post several entries paid late, this will affect total entries considered.
        PaidLateCount := LibraryRandom.RandInt(20);
        for i := 1 to PaidLateCount do
            PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + LibraryRandom.RandInt(10));

        // [GIVEN] Post several entries unpaid overdue, this will affect total entries considered.
        UnpaidOverdueCount := LibraryRandom.RandInt(20);
        for i := 1 to UnpaidOverdueCount do
            PaymentPracticesLibrary.MockVendorInvoice(VendorNo, WorkDate() - 50, WorkDate() - LibraryRandom.RandInt(40));

        // [GIVEN] Post several entries unpaid not overdue, these will not affect count
        for i := 1 to LibraryRandom.RandInt(20) do
            PaymentPracticesLibrary.MockVendorInvoice(VendorNo, WorkDate(), WorkDate() + LibraryRandom.RandInt(10));

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
            PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + ActualPaymentTime);
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
            PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate() + AgreedPaymentTime, WorkDate() + AgreedPaymentTime);
            AgreedPaymentTimeSum += AgreedPaymentTime;
        end;

        // [GIVEN] Post a lot of entries with varying agreed payment time. Unpaid
        TotalUnpaidEntries += LibraryRandom.RandInt(100);
        for i := 1 to TotalUnpaidEntries do begin
            AgreedPaymentTime := LibraryRandom.RandInt(30);
            PaymentPracticesLibrary.MockVendorInvoice(VendorNo, WorkDate(), WorkDate() + AgreedPaymentTime);
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
        PaymentPeriodLine: Record "Payment Period Line";
        VendorNo: Code[20];
    begin
        // [SCENARIO 493671] Payment is processed correctly for Payment Period with Days To = 0
        Initialize();

        // [GIVEN] Create a vendor
        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Create a payment period with DaysTo = 0
        PaymentPracticesLibrary.InitAndGetLastPaymentPeriod(PaymentPeriodLine);

        // [GIVEN] Create a payment practice header for Current Year of type Vendor
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader, "Paym. Prac. Header Type"::Vendor, "Paym. Prac. Aggregation Type"::Period);

        // [GIVEN] Post an entry for the vendor in the period
        PaymentPracticesLibrary.MockVendorInvoiceAndPaymentInPeriod(VendorNo, WorkDate(), PaymentPeriodLine."Days From", PaymentPeriodLine."Days To");

        // [WHEN] Lines were generated for Header
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] Check that report dataset contains the line for the period correcly
        PaymentPracticesLibrary.VerifyPeriodLine(PaymentPracticeHeader."No.", "Paym. Prac. Header Type"::Vendor, PaymentPeriodLine.Description, 100, 0);
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
        PaymentPracticesLibrary.MockVendorInvoice(VendorNo, WorkDate(), WorkDate());

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

    [Test]
    [HandlerFunctions('ConfirmHandler_Yes')]
    procedure DisputeRetData_CopyFromPrevious()
    var
        PaymentPracticeHeader1: Record "Payment Practice Header";
        PaymentPracticeHeader2: Record "Payment Practice Header";
        DisputeRetData1: Record "Paym. Prac. Dispute Ret. Data";
        DisputeRetData2: Record "Paym. Prac. Dispute Ret. Data";
    begin
        // [SCENARIO] CopyFromPrevious copies standing-policy fields and clears period-specific fields
        Initialize();

        // [GIVEN] First header with D&R data
        PaymentPracticesLibrary.CreatePaymentPracticeHeader(
            PaymentPracticeHeader1,
            "Paym. Prac. Header Type"::Vendor,
            "Paym. Prac. Aggregation Type"::Period,
            "Paym. Prac. Reporting Scheme"::"Dispute & Retention",
            DMY2Date(1, 4, 2025), DMY2Date(30, 9, 2025));
        DisputeRetData1.Get(PaymentPracticeHeader1."No.");
        DisputeRetData1."Dispute Resolution Process" := 'Mediation first';
        DisputeRetData1."Offers E-Invoicing" := true;
        DisputeRetData1."Has Constr. Contract Retention" := true;
        DisputeRetData1."Ret. Clause Used in Contracts" := true;
        DisputeRetData1."Retent. Withheld from Suppls." := 50000;
        DisputeRetData1."Payment Terms Have Changed" := true;
        DisputeRetData1."Suppliers Notified of Changes" := true;
        DisputeRetData1."Has Deducted Charges in Period" := true;
        DisputeRetData1."Payments Made in Period" := true;
        DisputeRetData1.Modify();

        // [GIVEN] Second header (later period) with empty D&R data
        PaymentPracticesLibrary.CreatePaymentPracticeHeader(
            PaymentPracticeHeader2,
            "Paym. Prac. Header Type"::Vendor,
            "Paym. Prac. Aggregation Type"::Period,
            "Paym. Prac. Reporting Scheme"::"Dispute & Retention",
            DMY2Date(1, 10, 2025), DMY2Date(31, 3, 2026));

        // [WHEN] Copy from previous on second header's D&R record
        DisputeRetData2.Get(PaymentPracticeHeader2."No.");
        DisputeRetData2.CopyFromPrevious();

        // [THEN] Standing-policy fields are copied
        DisputeRetData2.Get(PaymentPracticeHeader2."No.");
        Assert.AreEqual('Mediation first', DisputeRetData2."Dispute Resolution Process", 'Dispute Resolution Process should be copied.');
        Assert.IsTrue(DisputeRetData2."Offers E-Invoicing", 'Offers E-Invoicing should be copied.');
        Assert.IsTrue(DisputeRetData2."Has Constr. Contract Retention", 'Has Constr. Contract Retention should be copied.');
        Assert.IsTrue(DisputeRetData2."Ret. Clause Used in Contracts", 'Ret. Clause Used in Contracts should be copied.');

        // [THEN] Period-specific fields are cleared
        Assert.AreEqual(0, DisputeRetData2."Retent. Withheld from Suppls.", 'Retent. Withheld from Suppls. should be cleared.');
        Assert.IsFalse(DisputeRetData2."Payment Terms Have Changed", 'Payment Terms Have Changed should be cleared.');
        Assert.IsFalse(DisputeRetData2."Suppliers Notified of Changes", 'Suppliers Notified of Changes should be cleared.');
        Assert.IsFalse(DisputeRetData2."Has Deducted Charges in Period", 'Has Deducted Charges in Period should be cleared.');
        Assert.IsFalse(DisputeRetData2."Payments Made in Period", 'Payments Made in Period should be cleared.');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler_Yes')]
    procedure DisputeRetData_CopyFromPrevious_FiltersToSameScheme()
    var
        PaymentPracticeHeader1: Record "Payment Practice Header";
        PaymentPracticeHeader2: Record "Payment Practice Header";
        PaymentPracticeHeader3: Record "Payment Practice Header";
        DisputeRetData1: Record "Paym. Prac. Dispute Ret. Data";
        DisputeRetData3: Record "Paym. Prac. Dispute Ret. Data";
    begin
        // [SCENARIO] CopyFromPrevious only copies from headers with the same reporting scheme
        Initialize();
        PaymentPracticesLibrary.CleanupPaymentPracticeHeaders();

        // [GIVEN] First header with D&R scheme and data (oldest)
        PaymentPracticesLibrary.CreatePaymentPracticeHeader(
            PaymentPracticeHeader1,
            "Paym. Prac. Header Type"::Vendor,
            "Paym. Prac. Aggregation Type"::Period,
            "Paym. Prac. Reporting Scheme"::"Dispute & Retention",
            DMY2Date(1, 1, 2025), DMY2Date(30, 6, 2025));
        DisputeRetData1.Get(PaymentPracticeHeader1."No.");
        DisputeRetData1."Dispute Resolution Process" := 'D&R Process';
        DisputeRetData1."Offers E-Invoicing" := true;
        DisputeRetData1.Modify();

        // [GIVEN] Second header with Standard scheme (more recent, should be skipped)
        PaymentPracticesLibrary.CreatePaymentPracticeHeader(
            PaymentPracticeHeader2,
            "Paym. Prac. Header Type"::Vendor,
            "Paym. Prac. Aggregation Type"::Period,
            "Paym. Prac. Reporting Scheme"::Standard,
            DMY2Date(1, 7, 2025), DMY2Date(31, 12, 2025));

        // [GIVEN] Third header with D&R scheme (newest)
        PaymentPracticesLibrary.CreatePaymentPracticeHeader(
            PaymentPracticeHeader3,
            "Paym. Prac. Header Type"::Vendor,
            "Paym. Prac. Aggregation Type"::Period,
            "Paym. Prac. Reporting Scheme"::"Dispute & Retention",
            DMY2Date(1, 1, 2026), DMY2Date(30, 6, 2026));

        // [WHEN] Copy from previous on third header's D&R record
        DisputeRetData3.Get(PaymentPracticeHeader3."No.");
        DisputeRetData3.CopyFromPrevious();

        // [THEN] Data is copied from first header (same scheme), not second (different scheme)
        DisputeRetData3.Get(PaymentPracticeHeader3."No.");
        Assert.AreEqual('D&R Process', DisputeRetData3."Dispute Resolution Process", 'Should copy from D&R scheme header, not Standard.');
        Assert.IsTrue(DisputeRetData3."Offers E-Invoicing", 'Should copy from D&R scheme header.');
    end;

    [Test]
    procedure DisputeRetData_PreservedAfterGenerate()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        DisputeRetData: Record "Paym. Prac. Dispute Ret. Data";
    begin
        // [SCENARIO] ClearHeader + Generate preserves manually entered Dispute & Retention data
        Initialize();

        // [GIVEN] A Payment Practice Header with Dispute & Retention scheme
        PaymentPracticesLibrary.CreatePaymentPracticeHeader(
            PaymentPracticeHeader,
            "Paym. Prac. Header Type"::Vendor,
            "Paym. Prac. Aggregation Type"::Period,
            "Paym. Prac. Reporting Scheme"::"Dispute & Retention",
            WorkDate() - 180, WorkDate() + 180);

        // [GIVEN] User manually fills in dispute & retention fields
        DisputeRetData.Get(PaymentPracticeHeader."No.");
        DisputeRetData."Dispute Resolution Process" := 'Arbitration';
        DisputeRetData."Offers E-Invoicing" := true;
        DisputeRetData."Has Constr. Contract Retention" := true;
        DisputeRetData."Retent. Withheld from Suppls." := 25000;
        DisputeRetData.Modify();

        // [WHEN] ClearHeader is called (as Generate action does)
        PaymentPracticeHeader.ClearHeader();

        // [THEN] The Dispute & Retention data record still exists with its values
        Assert.IsTrue(DisputeRetData.Get(PaymentPracticeHeader."No."), 'T689 record should survive ClearHeader.');
        Assert.AreEqual('Arbitration', DisputeRetData."Dispute Resolution Process", 'Dispute Resolution Process should be preserved.');
        Assert.IsTrue(DisputeRetData."Offers E-Invoicing", 'Offers E-Invoicing should be preserved.');
        Assert.IsTrue(DisputeRetData."Has Constr. Contract Retention", 'Has Constr. Contract Retention should be preserved.');
        Assert.AreEqual(25000, DisputeRetData."Retent. Withheld from Suppls.", 'Retent. Withheld from Suppls. should be preserved.');
    end;

    [Test]
    procedure DisputeRetData_LifecycleCreateAndDelete()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        DisputeRetData: Record "Paym. Prac. Dispute Ret. Data";
        HeaderNo: Integer;
    begin
        // [SCENARIO] T689 record is created on header insert and deleted on header delete
        Initialize();

        // [GIVEN] A new Payment Practice Header is created via Insert(true) to fire OnInsert trigger
        PaymentPracticeHeader.Init();
        PaymentPracticeHeader."Header Type" := "Paym. Prac. Header Type"::Vendor;
        PaymentPracticeHeader."Aggregation Type" := "Paym. Prac. Aggregation Type"::Period;
        PaymentPracticeHeader."Starting Date" := WorkDate() - 180;
        PaymentPracticeHeader."Ending Date" := WorkDate() + 180;
        PaymentPracticeHeader.Insert(true);
        HeaderNo := PaymentPracticeHeader."No.";

        // [THEN] A corresponding T689 record exists
        Assert.IsTrue(DisputeRetData.Get(HeaderNo), 'T689 record should be created on header insert.');

        // [WHEN] The header is deleted
        PaymentPracticeHeader.Delete(true);

        // [THEN] The T689 record no longer exists
        Assert.IsFalse(DisputeRetData.Get(HeaderNo), 'T689 record should be deleted when header is deleted.');
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
        PaymentPracticesLibrary.CreateDefaultPaymentPeriodTemplates();
        PaymentPracticesLibrary.InitializePaymentPeriods(PaymentPeriods);
        Initialized := true;

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Payment Practices UT");
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

    [Test]
    procedure StandardScheme_GenerateProducesSameResults()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        VendorNo: Code[20];
    begin
        // [SCENARIO] Standard scheme produces same results as before
        Initialize();

        // [GIVEN] Vendor with entry
        VendorNo := LibraryPurchase.CreateVendorNo();
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate() + 30, WorkDate() + 10);

        // [WHEN] Generate with Standard scheme
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderWithScheme(
            PaymentPracticeHeader,
            "Paym. Prac. Header Type"::Vendor,
            "Paym. Prac. Aggregation Type"::Period,
            "Paym. Prac. Reporting Scheme"::Standard);
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] Data is generated correctly
        PaymentPracticesLibrary.VerifyBufferCount(PaymentPracticeHeader, 1, "Paym. Prac. Header Type"::Vendor);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler_Yes')]
    procedure ReportingScheme_SwitchClearsLines()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        VendorNo: Code[20];
    begin
        // [SCENARIO] Switching Reporting Scheme clears generated lines
        Initialize();
        PaymentPracticesLibrary.CleanupPaymentPracticeHeaders();

        // [GIVEN] Vendor with entry
        VendorNo := LibraryPurchase.CreateVendorNo();
        PaymentPracticesLibrary.MockVendorInvoice(VendorNo, WorkDate(), WorkDate());

        // [GIVEN] Generate with Standard scheme
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderWithScheme(
            PaymentPracticeHeader,
            "Paym. Prac. Header Type"::Vendor,
            "Paym. Prac. Aggregation Type"::"Company Size",
            "Paym. Prac. Reporting Scheme"::Standard);
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [WHEN] Switch Reporting Scheme
        PaymentPracticesLibrary.CreatePaymentPeriodTemplate("Paym. Prac. Reporting Scheme"::"Dispute & Retention");
        PaymentPracticeHeader.Validate("Reporting Scheme", "Paym. Prac. Reporting Scheme"::"Dispute & Retention");

        // [THEN] Lines are cleared
        PaymentPracticesLibrary.VerifyLinesCount(PaymentPracticeHeader, 0);

        // tear down
        PaymentPracticesLibrary.CreateDefaultPaymentPeriodTemplates();
    end;

    [Test]
    procedure SmallBusiness_ValidateHeaderRejectsCustomer()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
    begin
        // [SCENARIO] Small Business scheme rejects Customer header type
        Initialize();

        // [GIVEN] Header with Small Business scheme and Customer type
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderWithScheme(
            PaymentPracticeHeader,
            "Paym. Prac. Header Type"::Customer,
            "Paym. Prac. Aggregation Type"::Period,
            "Paym. Prac. Reporting Scheme"::"Small Business");

        // [WHEN] Generate
        asserterror PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] Error is raised
        Assert.ExpectedError('Payment Practice Header Type must be Vendor for the Small Business reporting scheme.');
    end;

    [Test]
    procedure SmallBusiness_ValidateHeaderRejectsVendorCustomer()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
    begin
        // [SCENARIO] Small Business scheme rejects Vendor+Customer header type
        Initialize();

        // [GIVEN] Header with Small Business scheme and Vendor+Customer type
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderWithScheme(
            PaymentPracticeHeader,
            "Paym. Prac. Header Type"::"Vendor+Customer",
            "Paym. Prac. Aggregation Type"::Period,
            "Paym. Prac. Reporting Scheme"::"Small Business");

        // [WHEN] Generate
        asserterror PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] Error is raised
        Assert.ExpectedError('Payment Practice Header Type must be Vendor for the Small Business reporting scheme.');
    end;

    [Test]
    procedure SmallBusiness_NonSmallVendorExcluded()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        VendorNo: Code[20];
    begin
        // [SCENARIO] Non-small-business vendor produces zero rows in Small Business scheme
        Initialize();

        // [GIVEN] Vendor without Small Business Supplier flag
        VendorNo := LibraryPurchase.CreateVendorNo();
        PaymentPracticesLibrary.MockVendorInvoice(VendorNo, WorkDate(), WorkDate());

        // [WHEN] Generate with Small Business scheme
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderWithScheme(
            PaymentPracticeHeader,
            "Paym. Prac. Header Type"::Vendor,
            "Paym. Prac. Aggregation Type"::Period,
            "Paym. Prac. Reporting Scheme"::"Small Business");
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] No data rows exist
        PaymentPracticesLibrary.VerifyBufferCount(PaymentPracticeHeader, 0, "Paym. Prac. Header Type"::Vendor);
    end;

    [Test]
    procedure SmallBusiness_SmallVendorIncluded()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        VendorNo: Code[20];
    begin
        // [SCENARIO] Small business vendor invoices are included
        Initialize();

        // [GIVEN] Small business vendor with entry
        VendorNo := PaymentPracticesLibrary.CreateSmallBusinessVendor();
        PaymentPracticesLibrary.MockVendorInvoice(VendorNo, WorkDate(), WorkDate());

        // [WHEN] Generate with Small Business scheme
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderWithScheme(
            PaymentPracticeHeader,
            "Paym. Prac. Header Type"::Vendor,
            "Paym. Prac. Aggregation Type"::Period,
            "Paym. Prac. Reporting Scheme"::"Small Business");
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] Data row exists
        PaymentPracticesLibrary.VerifyBufferCount(PaymentPracticeHeader, 1, "Paym. Prac. Header Type"::Vendor);
    end;

    [Test]
    procedure PaymentPeriodTemplate_DefaultMutualExclusion()
    var
        PaymentPeriodHeader1: Record "Payment Period Header";
        PaymentPeriodHeader2: Record "Payment Period Header";
    begin
        // [SCENARIO] Setting Default on one template clears Default on others with same scheme
        Initialize();

        // [GIVEN] Two templates for Standard scheme
        PaymentPeriodHeader1.Init();
        PaymentPeriodHeader1.Code := 'TEST-1';
        PaymentPeriodHeader1."Reporting Scheme" := "Paym. Prac. Reporting Scheme"::Standard;
        PaymentPeriodHeader1.Insert();
        PaymentPeriodHeader1.Validate(Default, true);
        PaymentPeriodHeader1.Modify();

        PaymentPeriodHeader2.Init();
        PaymentPeriodHeader2.Code := 'TEST-2';
        PaymentPeriodHeader2."Reporting Scheme" := "Paym. Prac. Reporting Scheme"::Standard;
        PaymentPeriodHeader2.Insert();

        // [WHEN] Set Default on second template
        PaymentPeriodHeader2.Validate(Default, true);
        PaymentPeriodHeader2.Modify();

        // [THEN] First template is no longer default
        PaymentPeriodHeader1.Get('TEST-1');
        Assert.IsFalse(PaymentPeriodHeader1.Default, 'First template should no longer be default.');

        // tear down
        PaymentPracticesLibrary.CreateDefaultPaymentPeriodTemplates();
    end;

    [Test]
    procedure GenerationGuard_BlankPeriodCode_TemplatesExist()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
    begin
        // [SCENARIO] Generation is blocked with simple error when Payment Period Code is blank but templates exist for the scheme
        Initialize();

        // [GIVEN] Templates exist for Standard scheme (created by Initialize)
        // [GIVEN] Header with blank Payment Period Code
        PaymentPracticeHeader.Init();
        PaymentPracticeHeader."Header Type" := "Paym. Prac. Header Type"::Vendor;
        PaymentPracticeHeader."Aggregation Type" := "Paym. Prac. Aggregation Type"::Period;
        PaymentPracticeHeader."Starting Date" := WorkDate() - 180;
        PaymentPracticeHeader."Ending Date" := WorkDate() + 180;
        PaymentPracticeHeader."Payment Period Code" := '';
        PaymentPracticeHeader.Insert();

        // [WHEN] Generate
        asserterror PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] Error about blank period code
        Assert.ExpectedError('You must select a Payment Period Code before generating.');
    end;

    [Test]
    procedure GenerationGuard_BlankPeriodCode_NoTemplates()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        PaymentPeriodHeader: Record "Payment Period Header";
        PaymentPeriodLine: Record "Payment Period Line";
    begin
        // [SCENARIO] Generation is blocked with actionable error when Payment Period Code is blank and no templates exist for the scheme
        Initialize();

        // [GIVEN] No templates exist for the scheme
        PaymentPeriodLine.DeleteAll();
        PaymentPeriodHeader.DeleteAll();

        // [GIVEN] Header with blank Payment Period Code
        PaymentPracticeHeader.Init();
        PaymentPracticeHeader."Header Type" := "Paym. Prac. Header Type"::Vendor;
        PaymentPracticeHeader."Aggregation Type" := "Paym. Prac. Aggregation Type"::Period;
        PaymentPracticeHeader."Starting Date" := WorkDate() - 180;
        PaymentPracticeHeader."Ending Date" := WorkDate() + 180;
        PaymentPracticeHeader."Payment Period Code" := '';
        PaymentPracticeHeader.Insert();

        // [WHEN] Generate
        asserterror PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] Error about no templates with navigation action text
        Assert.ExpectedError('No payment period templates exist for the selected reporting scheme. Create a template first.');

        // tear down
        PaymentPracticesLibrary.CreateDefaultPaymentPeriodTemplates();
    end;

    [Test]
    procedure GenerateDefaultTemplate_CreatesOnEmptyTable()
    var
        PaymentPeriodHeader: Record "Payment Period Header";
        PaymentPeriodLine: Record "Payment Period Line";
        PaymentPeriodListPage: TestPage "Payment Period List";
    begin
        // [SCENARIO] Generate Default Template action creates a default template when the table is empty
        Initialize();

        // [GIVEN] No payment period headers exist
        PaymentPeriodLine.DeleteAll();
        PaymentPeriodHeader.DeleteAll();

        // [WHEN] Run Generate Default Template action from Payment Period List page
        PaymentPeriodListPage.OpenEdit();
        PaymentPeriodListPage.GenerateDefaultTemplate.Invoke();
        PaymentPeriodListPage.Close();

        // [THEN] A default template is created with lines
        PaymentPeriodHeader.SetRange(Default, true);
        Assert.RecordIsNotEmpty(PaymentPeriodHeader);
        PaymentPeriodHeader.FindFirst();
        PaymentPeriodLine.SetRange("Period Header Code", PaymentPeriodHeader.Code);
        Assert.RecordIsNotEmpty(PaymentPeriodLine);

        // tear down
        PaymentPracticesLibrary.CreateDefaultPaymentPeriodTemplates();
    end;

    [Test]
    procedure GenerateDefaultTemplate_ErrorWhenAlreadyExists()
    var
        PaymentPeriodListPage: TestPage "Payment Period List";
    begin
        // [SCENARIO] Generate Default Template action raises an error when the default template already exists
        Initialize();

        // [GIVEN] Default template already exists
        PaymentPracticesLibrary.CreateDefaultPaymentPeriodTemplates();

        // [WHEN] Run Generate Default Template action again
        PaymentPeriodListPage.OpenEdit();
        asserterror PaymentPeriodListPage.GenerateDefaultTemplate.Invoke();

        // [THEN] Error about template already existing
        Assert.ExpectedError('already exists');
        PaymentPeriodListPage.Close();
    end;

    [Test]
    procedure PaymentPeriodTemplate_DefaultCanBeUnchecked()
    var
        PaymentPeriodHeader: Record "Payment Period Header";
    begin
        // [SCENARIO] Setting Default to false on a payment period template is always allowed
        Initialize();

        // [GIVEN] Template with Default = true
        PaymentPeriodHeader.Init();
        PaymentPeriodHeader.Code := 'TEST-UNCK';
        PaymentPeriodHeader."Reporting Scheme" := "Paym. Prac. Reporting Scheme"::Standard;
        PaymentPeriodHeader.Validate(Default, true);
        PaymentPeriodHeader.Insert();

        // [WHEN] Set Default to false
        PaymentPeriodHeader.Validate(Default, false);
        PaymentPeriodHeader.Modify();

        // [THEN] Default is false
        PaymentPeriodHeader.Get('TEST-UNCK');
        Assert.IsFalse(PaymentPeriodHeader.Default, 'Default should be unchecked.');

        // tear down
        PaymentPracticesLibrary.CreateDefaultPaymentPeriodTemplates();
    end;

    [Test]
    procedure CascadingAutoFill_PicksDefaultTemplate()
    var
        PaymentPeriodHeaderNonDef: Record "Payment Period Header";
        PaymentPracticeHeader: Record "Payment Practice Header";
        DefaultHeader: Record "Payment Period Header";
    begin
        // [SCENARIO] Cascading auto-fill picks the default template when it exists among multiple templates
        Initialize();

        // [GIVEN] A default Standard template exists (from Initialize)
        // [GIVEN] Another non-default Standard template
        PaymentPeriodHeaderNonDef.Init();
        PaymentPeriodHeaderNonDef.Code := 'TST-NONDEF';
        PaymentPeriodHeaderNonDef."Reporting Scheme" := "Paym. Prac. Reporting Scheme"::Standard;
        PaymentPeriodHeaderNonDef.Insert();

        // [WHEN] Insert Payment Practice Header (auto-detects Standard in W1 environment)
        PaymentPracticeHeader.Init();
        PaymentPracticeHeader.Insert(true);

        // [THEN] Payment Period Code is set to the default template
        DefaultHeader.SetRange("Reporting Scheme", "Paym. Prac. Reporting Scheme"::Standard);
        DefaultHeader.SetRange(Default, true);
        DefaultHeader.FindFirst();
        Assert.AreEqual(DefaultHeader.Code, PaymentPracticeHeader."Payment Period Code", 'Should auto-fill default template.');

    end;

    [Test]
    procedure CascadingAutoFill_PicksSoleTemplate()
    var
        PaymentPeriodHeader: Record "Payment Period Header";
        PaymentPracticeHeader: Record "Payment Practice Header";
    begin
        // [SCENARIO] Cascading auto-fill picks the sole template when no default exists
        Initialize();
        PaymentPracticesLibrary.CleanupPaymentPracticeHeaders();

        // [GIVEN] Delete all existing Standard templates
        PaymentPracticesLibrary.DeletePaymentPeriodTemplatesForScheme("Paym. Prac. Reporting Scheme"::Standard);

        // [GIVEN] One Standard template, not default
        PaymentPeriodHeader.Init();
        PaymentPeriodHeader.Code := 'TST-SOLE';
        PaymentPeriodHeader."Reporting Scheme" := "Paym. Prac. Reporting Scheme"::Standard;
        PaymentPeriodHeader.Insert();

        // [WHEN] Insert Payment Practice Header
        PaymentPracticeHeader.Init();
        PaymentPracticeHeader.Insert(true);

        // [THEN] Payment Period Code is set to the sole template
        Assert.AreEqual('TST-SOLE', PaymentPracticeHeader."Payment Period Code", 'Should auto-fill sole template.');

        // tear down
        PaymentPracticesLibrary.CreateDefaultPaymentPeriodTemplates();
    end;

    [Test]
    procedure CascadingAutoFill_BlankWhenMultipleNonDefault()
    var
        PaymentPeriodHeader1: Record "Payment Period Header";
        PaymentPeriodHeader2: Record "Payment Period Header";
        PaymentPracticeHeader: Record "Payment Practice Header";
    begin
        // [SCENARIO] Cascading auto-fill leaves Payment Period Code blank when multiple non-default templates exist
        Initialize();
        PaymentPracticesLibrary.CleanupPaymentPracticeHeaders();

        // [GIVEN] Delete all existing Standard templates
        PaymentPracticesLibrary.DeletePaymentPeriodTemplatesForScheme("Paym. Prac. Reporting Scheme"::Standard);

        // [GIVEN] Two Standard templates, neither default
        PaymentPeriodHeader1.Init();
        PaymentPeriodHeader1.Code := 'TST-A';
        PaymentPeriodHeader1."Reporting Scheme" := "Paym. Prac. Reporting Scheme"::Standard;
        PaymentPeriodHeader1.Insert();

        PaymentPeriodHeader2.Init();
        PaymentPeriodHeader2.Code := 'TST-B';
        PaymentPeriodHeader2."Reporting Scheme" := "Paym. Prac. Reporting Scheme"::Standard;
        PaymentPeriodHeader2.Insert();

        // [WHEN] Insert Payment Practice Header
        PaymentPracticeHeader.Init();
        PaymentPracticeHeader.Insert(true);

        // [THEN] Payment Period Code is blank
        Assert.AreEqual('', PaymentPracticeHeader."Payment Period Code", 'Should be blank when multiple non-default templates exist.');

        // tear down
        PaymentPracticesLibrary.CreateDefaultPaymentPeriodTemplates();
    end;

    [Test]
    procedure PaymentPeriodCard_SchemeNonEditableAfterInsert()
    var
        PaymentPeriodHeader: Record "Payment Period Header";
        PaymentPeriodCard: TestPage "Payment Period Card";
    begin
        // [SCENARIO] Reporting Scheme is not editable on Payment Period Card for existing templates
        Initialize();

        // [GIVEN] Existing payment period template
        PaymentPeriodHeader.Init();
        PaymentPeriodHeader.Code := 'TST-ROSED';
        PaymentPeriodHeader."Reporting Scheme" := "Paym. Prac. Reporting Scheme"::Standard;
        PaymentPeriodHeader.Insert();

        // [WHEN] Open Payment Period Card for existing template
        PaymentPeriodCard.OpenEdit();
        PaymentPeriodCard.Filter.SetFilter(Code, 'TST-ROSED');

        // [THEN] Reporting Scheme field is not editable
        Assert.IsFalse(PaymentPeriodCard."Reporting Scheme".Editable(), 'Reporting Scheme should not be editable after insert.');

        PaymentPeriodCard.Close();

    end;

    [Test]
    procedure GBCSVExport_HeaderRowContainsAll52Columns()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        HeaderLine: Text;
        DataLine: Text;
        ExpectedColumns: List of [Text];
    begin
        // [SCENARIO] CSV export produces correct header row with all 52 column names
        Initialize();

        // [GIVEN] A fully populated Payment Practice Header with Dispute & Retention scheme
        PaymentPracticesLibrary.CreateFullyPopulatedGBHeader(PaymentPracticeHeader);

        // [WHEN] Export GB CSV
        ExportGBCSVAndGetLines(PaymentPracticeHeader, HeaderLine, DataLine);

        // [THEN] Header row contains all 52 government column names
        ExpectedColumns.Add('Report Id');
        ExpectedColumns.Add('Policy Regime');
        ExpectedColumns.Add('Financial period start date');
        ExpectedColumns.Add('Start date');
        ExpectedColumns.Add('End date');
        ExpectedColumns.Add('Filing date');
        ExpectedColumns.Add('Company');
        ExpectedColumns.Add('Company number');
        ExpectedColumns.Add('Qualifying contracts in reporting period');
        ExpectedColumns.Add('Payments made in reporting period');
        ExpectedColumns.Add('Qualifying construction contracts in reporting period');
        ExpectedColumns.Add('Construction contracts have retention clauses');
        ExpectedColumns.Add('Average time to pay');
        ExpectedColumns.Add('Total value invoices paid within 30 days');
        ExpectedColumns.Add('Total value invoices paid between 31 and 60 days');
        ExpectedColumns.Add('Total value invoices paid later than 60 days');
        ExpectedColumns.Add('% Invoices paid within 30 days');
        ExpectedColumns.Add('% Invoices paid between 31 and 60 days');
        ExpectedColumns.Add('% Invoices paid later than 60 days');
        ExpectedColumns.Add('Total value invoices paid later than agreed terms');
        ExpectedColumns.Add('% Invoices not paid within agreed terms');
        ExpectedColumns.Add('% Invoices not paid due to dispute');
        ExpectedColumns.Add('Shortest (or only) standard payment period');
        ExpectedColumns.Add('Longest standard payment period');
        ExpectedColumns.Add('Standard payment terms');
        ExpectedColumns.Add('Payment terms have changed');
        ExpectedColumns.Add('Suppliers notified of changes');
        ExpectedColumns.Add('Maximum contractual payment period');
        ExpectedColumns.Add('Maximum contractual payment period information');
        ExpectedColumns.Add('Other information payment terms');
        ExpectedColumns.Add('Retention clauses included in all construction contracts');
        ExpectedColumns.Add('Retention clauses included in standard payment terms');
        ExpectedColumns.Add('Retention clauses are used in specific circumstances');
        ExpectedColumns.Add('Description of specific circumstances for retention clauses');
        ExpectedColumns.Add('Retention clauses used above a specific sum');
        ExpectedColumns.Add('Value above which retention clauses are used');
        ExpectedColumns.Add('Retention clauses are at a standard rate');
        ExpectedColumns.Add('Retention clauses standard rate percentage');
        ExpectedColumns.Add('Retention clauses have parity with client');
        ExpectedColumns.Add('Description of parity policy');
        ExpectedColumns.Add('Retention clause money release description');
        ExpectedColumns.Add('Retention clause money release is staged');
        ExpectedColumns.Add('Description of stages for money release');
        ExpectedColumns.Add('Retention value compared to client retentions as %');
        ExpectedColumns.Add('Retention value compared to total payments as %');
        ExpectedColumns.Add('Dispute resolution process');
        ExpectedColumns.Add('Participates in payment codes');
        ExpectedColumns.Add('E-Invoicing offered');
        ExpectedColumns.Add('Supply-chain financing offered');
        ExpectedColumns.Add('Policy covers charges for remaining on supplier list');
        ExpectedColumns.Add('Charges have been made for remaining on supplier list');
        ExpectedColumns.Add('URL');

        Assert.AreEqual(52, ExpectedColumns.Count(), 'Expected 52 columns.');
        VerifyCSVHeaderColumns(HeaderLine, ExpectedColumns);
    end;

    [Test]
    procedure GBCSVExport_DataRowFullyPopulated()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        HeaderLine: Text;
        DataLine: Text;
    begin
        // [SCENARIO] CSV data row has correct values for a fully populated Payment Practice Header
        Initialize();

        // [GIVEN] A fully populated Payment Practice Header with Dispute & Retention scheme
        PaymentPracticesLibrary.CreateFullyPopulatedGBHeader(PaymentPracticeHeader);

        // [WHEN] Export GB CSV
        ExportGBCSVAndGetLines(PaymentPracticeHeader, HeaderLine, DataLine);

        // [THEN] Data row contains expected values
        Assert.IsTrue(StrPos(DataLine, 'Regime-1') > 0, 'Data row should contain Regime-1.');
        Assert.IsTrue(StrPos(DataLine, 'None') > 0, 'Data row should contain None for financial period start date.');
        Assert.IsTrue(StrPos(DataLine, 'TRUE') > 0, 'Data row should contain TRUE for boolean gate fields.');
        Assert.IsTrue(StrPos(DataLine, 'Yes') > 0, 'Data row should contain Yes for policy tick-boxes.');
    end;

    [Test]
    procedure GBCSVExport_PeriodAggregation4BucketsTo3()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        HeaderLine: Text;
        DataLine: Text;
        PeriodCode: Code[20];
    begin
        // [SCENARIO] Period percentage aggregation from 4-bucket template to 3 CSV columns
        Initialize();
        PaymentPracticesLibrary.CleanupPaymentPracticeHeaders();

        // [GIVEN] Payment Practice Header with Dispute & Retention scheme
        PeriodCode := PaymentPracticesLibrary.CreatePaymentPeriodTemplate("Paym. Prac. Reporting Scheme"::"Dispute & Retention");
        PaymentPracticesLibrary.CreatePaymentPracticeHeader(
            PaymentPracticeHeader,
            "Paym. Prac. Header Type"::Vendor,
            "Paym. Prac. Aggregation Type"::Period,
            "Paym. Prac. Reporting Scheme"::"Dispute & Retention",
            WorkDate() - 180, WorkDate() + 180);
        PaymentPracticeHeader."Payment Period Code" := PeriodCode;
        PaymentPracticeHeader.Modify();

        // [GIVEN] 4 period lines: (0-30, 77%), (31-60, 20%), (61-120, 2%), (121+, 1%)
        PaymentPracticesLibrary.CreateMockPeriodLine(PaymentPracticeHeader."No.", PeriodCode, '0 to 30 days.', 77, 0);
        PaymentPracticesLibrary.CreateMockPeriodLine(PaymentPracticeHeader."No.", PeriodCode, '31 to 60 days.', 20, 0);
        PaymentPracticesLibrary.CreateMockPeriodLine(PaymentPracticeHeader."No.", PeriodCode, '61 to 120 days.', 2, 0);
        PaymentPracticesLibrary.CreateMockPeriodLine(PaymentPracticeHeader."No.", PeriodCode, 'More than 121 days.', 1, 0);

        // [WHEN] Export GB CSV
        ExportGBCSVAndGetLines(PaymentPracticeHeader, HeaderLine, DataLine);

        // [THEN] The >60 days bucket aggregates: 2 + 1 = 3
        // CSV columns 17-19 contain the percentage values
        Assert.IsTrue(StrPos(DataLine, '77') > 0, 'Data row should contain 77 for <=30 days.');
        Assert.IsTrue(StrPos(DataLine, '20') > 0, 'Data row should contain 20 for 31-60 days.');

        // tear down
        PaymentPracticesLibrary.CreateDefaultPaymentPeriodTemplates();
    end;

    [Test]
    procedure GBCSVExport_RFC4180Escaping()
    begin
        // [SCENARIO] RFC 4180 escaping for narrative fields with commas, quotes, newlines
        Initialize();

        // [WHEN]/[THEN] Field with comma is quoted
        Assert.AreEqual('"Payment terms are 30 days, net"', PaymentPracticesLibrary.GBCSVEscapeCSVField('Payment terms are 30 days, net'), 'Comma should be quote-wrapped.');

        // [WHEN]/[THEN] Field with double quotes has quotes doubled
        Assert.AreEqual('"The supplier must provide a ""valid"" invoice"', PaymentPracticesLibrary.GBCSVEscapeCSVField('The supplier must provide a "valid" invoice'), 'Double quotes should be escaped.');

        // [WHEN]/[THEN] Empty field returns empty
        Assert.AreEqual('', PaymentPracticesLibrary.GBCSVEscapeCSVField(''), 'Empty field should return empty.');

        // [WHEN]/[THEN] Field without special chars is returned as-is
        Assert.AreEqual('Simple text', PaymentPracticesLibrary.GBCSVEscapeCSVField('Simple text'), 'Simple text should not be wrapped.');
    end;

    [Test]
    procedure GBCSVExport_RetentionColumnsBlankWhenGateFalse()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        DisputeRetData: Record "Paym. Prac. Dispute Ret. Data";
        HeaderLine: Text;
        DataLine: Text;
        Cols: List of [Text];
        ColValue: Text;
        i: Integer;
    begin
        // [SCENARIO] Retention columns blank when Has Constr. Contract Retention = false
        Initialize();

        // [GIVEN] Payment Practice Header with retention gate = false
        PaymentPracticesLibrary.CreatePaymentPracticeHeader(
            PaymentPracticeHeader,
            "Paym. Prac. Header Type"::Vendor,
            "Paym. Prac. Aggregation Type"::Period,
            "Paym. Prac. Reporting Scheme"::"Dispute & Retention",
            WorkDate() - 180, WorkDate() + 180);
        DisputeRetData.Get(PaymentPracticeHeader."No.");
        DisputeRetData."Has Constr. Contract Retention" := false;
        DisputeRetData.Modify();

        // [WHEN] Export GB CSV
        ExportGBCSVAndGetLines(PaymentPracticeHeader, HeaderLine, DataLine);

        // [THEN] Retention columns (positions 31-45) are empty
        SplitCSVRow(DataLine, Cols);
        for i := 31 to 45 do begin
            Cols.Get(i, ColValue);
            Assert.AreEqual('', ColValue, StrSubstNo(RetentionColumnEmptyLbl, i));
        end;
    end;

    [Test]
    procedure GBCSVExport_DateFormattingMDYYYY()
    begin
        // [SCENARIO] Date formatting as M/D/YYYY
        Initialize();

        // [WHEN]/[THEN] April 29, 2017 formats as 4/29/2017
        Assert.AreEqual('4/29/2017', PaymentPracticesLibrary.GBCSVFormatDateGov(DMY2Date(29, 4, 2017)), 'Date should be formatted as M/D/YYYY.');

        // [WHEN]/[THEN] November 7, 2017 formats as 11/7/2017
        Assert.AreEqual('11/7/2017', PaymentPracticesLibrary.GBCSVFormatDateGov(DMY2Date(7, 11, 2017)), 'Date should be formatted as M/D/YYYY.');

        // [WHEN]/[THEN] January 1, 2020 formats without leading zeros
        Assert.AreEqual('1/1/2020', PaymentPracticesLibrary.GBCSVFormatDateGov(DMY2Date(1, 1, 2020)), 'Date should not have leading zeros.');
    end;

    [Test]
    procedure GBCSVExport_CardDisputeRetentionLinkVisible()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        PaymentPracticeCard: TestPage "Payment Practice Card";
    begin
        // [SCENARIO] Dispute & Retention link visible on Payment Practice Card for D&R scheme
        Initialize();

        // [GIVEN] Payment Practice Header with Dispute & Retention scheme
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderWithScheme(
            PaymentPracticeHeader,
            "Paym. Prac. Header Type"::Vendor,
            "Paym. Prac. Aggregation Type"::Period,
            "Paym. Prac. Reporting Scheme"::"Dispute & Retention");

        // [WHEN] Open Payment Practice Card
        PaymentPracticeCard.OpenEdit();
        PaymentPracticeCard.Filter.SetFilter("No.", Format(PaymentPracticeHeader."No."));

        // [THEN] Dispute & Retention link field is visible
        Assert.IsTrue(PaymentPracticeCard.DisputeRetentionLink.Visible(), 'Dispute & Retention link should be visible for D&R scheme.');

        PaymentPracticeCard.Close();
    end;

    local procedure ExportGBCSVAndGetLines(PaymentPracticeHeader: Record "Payment Practice Header"; var HeaderLine: Text; var DataLine: Text)
    var
        LibraryFileMgtHandler: Codeunit "Library - File Mgt Handler";
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
    begin
        LibraryFileMgtHandler.SetBeforeDownloadFromStreamHandlerActivated(true);
        BindSubscription(LibraryFileMgtHandler);

        PaymentPracticesLibrary.GBCSVExport(PaymentPracticeHeader);

        UnbindSubscription(LibraryFileMgtHandler);
        LibraryFileMgtHandler.GetTempBlob(TempBlob);
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        InStream.ReadText(HeaderLine);
        InStream.ReadText(DataLine);
    end;

    local procedure VerifyCSVHeaderColumns(HeaderRow: Text; ExpectedColumns: List of [Text])
    var
        Cols: List of [Text];
        ExpectedCol: Text;
        ActualCol: Text;
        i: Integer;
    begin
        SplitCSVRow(HeaderRow, Cols);
        Assert.AreEqual(ExpectedColumns.Count(), Cols.Count(), 'Column count mismatch.');
        for i := 1 to ExpectedColumns.Count() do begin
            ExpectedColumns.Get(i, ExpectedCol);
            Cols.Get(i, ActualCol);
            Assert.AreEqual(ExpectedCol, ActualCol, StrSubstNo(ColumnMismatchLbl, i));
        end;
    end;

    local procedure SplitCSVRow(Row: Text; var Cols: List of [Text])
    var
        ColText: Text;
        i: Integer;
        InQuotes: Boolean;
        Ch: Char;
    begin
        Clear(Cols);
        ColText := '';
        InQuotes := false;
        for i := 1 to StrLen(Row) do begin
            Ch := Row[i];
            if Ch = '"' then
                InQuotes := not InQuotes
            else
                if (Ch = ',') and (not InQuotes) then begin
                    Cols.Add(ColText);
                    ColText := '';
                end else
                    ColText += Format(Ch);
        end;
        Cols.Add(ColText);
    end;

    var
        RetentionColumnEmptyLbl: Label 'Retention column %1 should be empty when gate is false.', Comment = '%1 = Column index';
        ColumnMismatchLbl: Label 'Column %1 mismatch.', Comment = '%1 = Column index';
}
