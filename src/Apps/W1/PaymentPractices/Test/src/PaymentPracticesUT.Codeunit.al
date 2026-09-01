// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AA0210 // table does not contain key with field A
namespace Microsoft.Test.Finance.Analysis;

using Microsoft.Finance.Analysis;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.Environment;

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
    [HandlerFunctions('ConfirmHandlerYes')]
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
    [HandlerFunctions('ConfirmHandlerNo')]
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
    [HandlerFunctions('ConfirmHandlerYes')]
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
        PaymentPracticesLibrary.MockVendorInvoiceAndPaymentInPeriod(VendorNo, WorkDate(), PaymentPeriod."Days From", PaymentPeriod."Days To");

        // [WHEN] Lines were generated for Header
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] Check that report dataset contains the line for the period correcly
        PaymentPracticesLibrary.VerifyPeriodLine(PaymentPracticeHeader."No.", "Paym. Prac. Header Type"::Vendor, PaymentPeriod.Description, 100, 0);
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
    procedure StandardSchemeGenerateProducesSameResults()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 597313] Generating payment practices with Standard reporting scheme produces correct data for vendor entries
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
    procedure ReportingSchemeAutoDetectionOnInsert()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        EnvironmentInformation: Codeunit "Environment Information";
        ExpectedScheme: Enum "Paym. Prac. Reporting Scheme";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 629871] Inserting a Payment Practice Header auto-detects the Reporting Scheme based on environment
        Initialize();

        // [WHEN] Insert a new Payment Practice Header via Insert(true)
        PaymentPracticeHeader.Init();
        PaymentPracticeHeader.Insert(true);

        // [THEN] Reporting Scheme is auto-detected based on environment application family
        case EnvironmentInformation.GetApplicationFamily() of
            'GB':
                ExpectedScheme := "Paym. Prac. Reporting Scheme"::"Dispute & Retention";
            'AU', 'NZ':
                ExpectedScheme := "Paym. Prac. Reporting Scheme"::"Small Business";
            else
                ExpectedScheme := "Paym. Prac. Reporting Scheme"::Standard;
        end;
        Assert.AreEqual(
            ExpectedScheme,
            PaymentPracticeHeader."Reporting Scheme",
            'Reporting Scheme should be auto-detected based on environment application family.');
    end;

    [Test]
    procedure DisputeRetCalcHeaderTotalsAllPaidOnTime()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        PaymentPracticeData: Record "Payment Practice Data";
        InvoiceAmount1: Decimal;
        InvoiceAmount2: Decimal;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 597313] CalculateHeaderTotals counts all closed invoices paid on time with zero overdue totals
        Initialize();

        // [GIVEN] Payment Practice Header "PPH" with Dispute and Retention scheme
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderWithScheme(
            PaymentPracticeHeader,
            "Paym. Prac. Header Type"::Vendor,
            "Paym. Prac. Aggregation Type"::Period,
            "Paym. Prac. Reporting Scheme"::"Dispute & Retention");

        // [GIVEN] Two closed invoices paid on time (Actual <= Agreed)
        InvoiceAmount1 := 500;
        MockPaymentPracticeData(PaymentPracticeHeader."No.", 1, false, 10, 30, InvoiceAmount1, false);
        InvoiceAmount2 := 300;
        MockPaymentPracticeData(PaymentPracticeHeader."No.", 2, false, 20, 30, InvoiceAmount2, false);

        // [WHEN] CalculateHeaderTotals is called
        PaymentPracticeData.SetRange("Header No.", PaymentPracticeHeader."No.");
        PaymentPracticesLibrary.DisputeRetCalcHeaderTotals(PaymentPracticeHeader, PaymentPracticeData);

        // [THEN] Total payments = 2, total amount = sum of both, overdue = 0, dispute pct = 0
        Assert.AreEqual(2, PaymentPracticeHeader."Total Number of Payments", 'Total Number of Payments');
        Assert.AreEqual(InvoiceAmount1 + InvoiceAmount2, PaymentPracticeHeader."Total Amount of Payments", 'Total Amount of Payments');
        Assert.AreEqual(0, PaymentPracticeHeader."Total Amt. of Overdue Payments", 'Total Amt. of Overdue Payments');
        Assert.AreEqual(0, PaymentPracticeHeader."Pct Overdue Due to Dispute", 'Pct Overdue Due to Dispute');
    end;

    [Test]
    procedure DisputeRetCalcHeaderTotalsOverdueNoDispute()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        PaymentPracticeData: Record "Payment Practice Data";
        InvoiceAmount: Decimal;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 597313] CalculateHeaderTotals calculates overdue amounts correctly when no invoices are disputed
        Initialize();

        // [GIVEN] Payment Practice Header "PPH" with Dispute and Retention scheme
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderWithScheme(
            PaymentPracticeHeader,
            "Paym. Prac. Header Type"::Vendor,
            "Paym. Prac. Aggregation Type"::Period,
            "Paym. Prac. Reporting Scheme"::"Dispute & Retention");

        // [GIVEN] Closed overdue invoice without dispute (Actual > Agreed, Dispute = false)
        InvoiceAmount := 1000;
        MockPaymentPracticeData(PaymentPracticeHeader."No.", 1, false, 45, 30, InvoiceAmount, false);

        // [WHEN] CalculateHeaderTotals is called
        PaymentPracticeData.SetRange("Header No.", PaymentPracticeHeader."No.");
        PaymentPracticesLibrary.DisputeRetCalcHeaderTotals(PaymentPracticeHeader, PaymentPracticeData);

        // [THEN] Total payments = 1, overdue amount = invoice amount, dispute pct = 0
        Assert.AreEqual(1, PaymentPracticeHeader."Total Number of Payments", 'Total Number of Payments');
        Assert.AreEqual(InvoiceAmount, PaymentPracticeHeader."Total Amt. of Overdue Payments", 'Total Amt. of Overdue Payments');
        Assert.AreEqual(0, PaymentPracticeHeader."Pct Overdue Due to Dispute", 'Pct Overdue Due to Dispute');

        // [THEN] Data record has "Overdue Due to Dispute" = false
        PaymentPracticeData.FindFirst();
        Assert.IsFalse(PaymentPracticeData."Overdue Due to Dispute", 'Overdue Due to Dispute should be false');
    end;

    [Test]
    procedure DisputeRetCalcHeaderTotalsMixedOverdueDispute()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        PaymentPracticeData: Record "Payment Practice Data";
        OverdueAmount1: Decimal;
        OverdueAmount2: Decimal;
        OverdueAmount3: Decimal;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 597313] CalculateHeaderTotals calculates correct dispute percentage when some overdue invoices are disputed
        Initialize();

        // [GIVEN] Payment Practice Header "PPH" with Dispute and Retention scheme
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderWithScheme(
            PaymentPracticeHeader,
            "Paym. Prac. Header Type"::Vendor,
            "Paym. Prac. Aggregation Type"::Period,
            "Paym. Prac. Reporting Scheme"::"Dispute & Retention");

        // [GIVEN] Three overdue invoices: one disputed, two not
        OverdueAmount1 := 100;
        MockPaymentPracticeData(PaymentPracticeHeader."No.", 1, false, 45, 30, OverdueAmount1, true);
        OverdueAmount2 := 200;
        MockPaymentPracticeData(PaymentPracticeHeader."No.", 2, false, 50, 30, OverdueAmount2, false);
        OverdueAmount3 := 300;
        MockPaymentPracticeData(PaymentPracticeHeader."No.", 3, false, 60, 30, OverdueAmount3, false);

        // [WHEN] CalculateHeaderTotals is called
        PaymentPracticeData.SetRange("Header No.", PaymentPracticeHeader."No.");
        PaymentPracticesLibrary.DisputeRetCalcHeaderTotals(PaymentPracticeHeader, PaymentPracticeData);

        // [THEN] Dispute pct = 1/3 * 100 ≈ 33.33
        Assert.AreEqual(3, PaymentPracticeHeader."Total Number of Payments", 'Total Number of Payments');
        Assert.AreEqual(OverdueAmount1 + OverdueAmount2 + OverdueAmount3, PaymentPracticeHeader."Total Amt. of Overdue Payments", 'Total Amt. of Overdue Payments');
        Assert.AreNearlyEqual(33.33, PaymentPracticeHeader."Pct Overdue Due to Dispute", 0.01, 'Pct Overdue Due to Dispute');
    end;

    [Test]
    procedure DisputeRetCalcHeaderTotalsMixOnTimeAndOverdue()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        PaymentPracticeData: Record "Payment Practice Data";
        OnTimeAmount: Decimal;
        OverdueDisputedAmount: Decimal;
        OverdueNotDisputedAmount: Decimal;
        OpenAmount: Decimal;
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 597313] CalculateHeaderTotals correctly handles a mix of on-time, overdue, and open invoices
        Initialize();

        // [GIVEN] Payment Practice Header "PPH" with Dispute and Retention scheme
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderWithScheme(
            PaymentPracticeHeader,
            "Paym. Prac. Header Type"::Vendor,
            "Paym. Prac. Aggregation Type"::Period,
            "Paym. Prac. Reporting Scheme"::"Dispute & Retention");

        // [GIVEN] One on-time closed invoice
        OnTimeAmount := 400;
        MockPaymentPracticeData(PaymentPracticeHeader."No.", 1, false, 10, 30, OnTimeAmount, false);

        // [GIVEN] One overdue disputed invoice
        OverdueDisputedAmount := 600;
        MockPaymentPracticeData(PaymentPracticeHeader."No.", 2, false, 45, 30, OverdueDisputedAmount, true);

        // [GIVEN] One overdue non-disputed invoice
        OverdueNotDisputedAmount := 200;
        MockPaymentPracticeData(PaymentPracticeHeader."No.", 3, false, 50, 30, OverdueNotDisputedAmount, false);

        // [GIVEN] One open invoice (should be skipped)
        OpenAmount := 999;
        MockPaymentPracticeData(PaymentPracticeHeader."No.", 4, true, 0, 30, OpenAmount, false);

        // [WHEN] CalculateHeaderTotals is called
        PaymentPracticeData.SetRange("Header No.", PaymentPracticeHeader."No.");
        PaymentPracticesLibrary.DisputeRetCalcHeaderTotals(PaymentPracticeHeader, PaymentPracticeData);

        // [THEN] Total payments = 3 (open skipped), total amount = on-time + both overdue
        Assert.AreEqual(3, PaymentPracticeHeader."Total Number of Payments", 'Total Number of Payments');
        Assert.AreEqual(OnTimeAmount + OverdueDisputedAmount + OverdueNotDisputedAmount, PaymentPracticeHeader."Total Amount of Payments", 'Total Amount of Payments');

        // [THEN] Overdue amount = only overdue invoices
        Assert.AreEqual(OverdueDisputedAmount + OverdueNotDisputedAmount, PaymentPracticeHeader."Total Amt. of Overdue Payments", 'Total Amt. of Overdue Payments');

        // [THEN] Dispute pct = 1/2 * 100 = 50 (1 disputed out of 2 overdue)
        Assert.AreEqual(50, PaymentPracticeHeader."Pct Overdue Due to Dispute", 'Pct Overdue Due to Dispute');
    end;

    [Test]
    procedure CompanySizeGenerationSucceedsWithBlankPeriodCode()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 597313] Company Size aggregation succeeds
        Initialize();

        // [GIVEN] Vendor "V" with company size and an entry in the period
        VendorNo := PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(CompanySizeCodes[1], false);
        PaymentPracticesLibrary.MockVendorInvoice(VendorNo, WorkDate(), WorkDate());

        // [GIVEN] Header with Company Size aggregation
        PaymentPracticesLibrary.CreatePaymentPracticeHeader(
            PaymentPracticeHeader,
            "Paym. Prac. Header Type"::Vendor,
            "Paym. Prac. Aggregation Type"::"Company Size",
            WorkDate() - 180, WorkDate() + 180);

        // [WHEN] Generate payment practices
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] Lines are created (one per company size code)
        PaymentPracticesLibrary.VerifyLinesCount(PaymentPracticeHeader, 3);

        // [THEN] Data rows include the vendor invoice
        PaymentPracticesLibrary.VerifyBufferCount(PaymentPracticeHeader, 1, "Paym. Prac. Header Type"::Vendor);
    end;

    [Test]
    procedure CompanySizeStandardLeavesInvoiceCountAndValueZero()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        VendorNo: Code[20];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO 597313] Standard scheme with Company Size aggregation leaves Invoice Count and Invoice Value at zero
        Initialize();

        // [GIVEN] Vendor "V" with company size and a closed invoice in the period
        VendorNo := PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(CompanySizeCodes[1], false);
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + 10);

        // [GIVEN] Header with Standard scheme and Company Size aggregation
        PaymentPracticesLibrary.CreatePaymentPracticeHeader(
            PaymentPracticeHeader,
            "Paym. Prac. Header Type"::Vendor,
            "Paym. Prac. Aggregation Type"::"Company Size",
            "Paym. Prac. Reporting Scheme"::Standard,
            WorkDate() - 180, WorkDate() + 180);

        // [WHEN] Generate payment practices
        PaymentPractices.Generate(PaymentPracticeHeader);

        // [THEN] Lines exist
        PaymentPracticesLibrary.VerifyLinesCount(PaymentPracticeHeader, 3);

        // [THEN] All lines have Invoice Count = 0 and Invoice Value = 0
        VerifyAllLinesInvoiceCountAndValueZero(PaymentPracticeHeader."No.");
    end;

    [Test]
    procedure ModePaymentTimeCalculation()
    var
        PaymentPracticeHeader: Record "Payment Practice Header";
        VendorNo: Code[20];
        CompanySizeCode: Code[20];
    begin
        // [SCENARIO 568642] Check mode payment time calculation in header
        Initialize();

        // [GIVEN] Create a vendor
        CompanySizeCode := PaymentPracticesLibrary.CreateCompanySizeCode(true);
        VendorNo := PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(CompanySizeCode, false);

        // [GIVEN] Create a payment practice header with Extra Fields enabled
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader, "Paym. Prac. Header Type"::Vendor, "Paym. Prac. Aggregation Type"::Period);
        PaymentPracticeHeader."Reporting Scheme" := PaymentPracticeHeader."Reporting Scheme"::"Small Business";
        PaymentPracticeHeader.Modify();

        // [GIVEN] Post entries with payment times: 5, 5, 5, 10, 10, 15 (mode = 5)
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + 5);
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + 5);
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + 5);
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + 10);
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + 10);
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + 15);

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
        CompanySizeCode: Code[20];
        VendorNo1: Code[20];
        VendorNo2: Code[20];
    begin
        // [SCENARIO 568642] Check mode payment time min is the minimum of per-vendor modes
        Initialize();

        // [GIVEN] Create two vendors with small business company size
        CompanySizeCode := PaymentPracticesLibrary.CreateCompanySizeCode(true);
        VendorNo1 := PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(CompanySizeCode, false);
        VendorNo2 := PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(CompanySizeCode, false);

        // [GIVEN] Create a payment practice header with Extra Fields enabled
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader, "Paym. Prac. Header Type"::Vendor, "Paym. Prac. Aggregation Type"::Period);
        PaymentPracticeHeader."Reporting Scheme" := PaymentPracticeHeader."Reporting Scheme"::"Small Business";
        PaymentPracticeHeader.Modify();

        // [GIVEN] Vendor 1: payment times 5, 5, 10 (mode = 5)
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo1, WorkDate(), WorkDate(), WorkDate() + 5);
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo1, WorkDate(), WorkDate(), WorkDate() + 5);
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo1, WorkDate(), WorkDate(), WorkDate() + 10);

        // [GIVEN] Vendor 2: payment times 8, 8, 12 (mode = 8)
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo2, WorkDate(), WorkDate(), WorkDate() + 8);
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo2, WorkDate(), WorkDate(), WorkDate() + 8);
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo2, WorkDate(), WorkDate(), WorkDate() + 12);

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
        CompanySizeCode: Code[20];
        VendorNo1: Code[20];
        VendorNo2: Code[20];
    begin
        // [SCENARIO 568642] Check mode payment time max is the maximum of per-vendor modes
        Initialize();

        // [GIVEN] Create two vendors with small business company size
        CompanySizeCode := PaymentPracticesLibrary.CreateCompanySizeCode(true);
        VendorNo1 := PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(CompanySizeCode, false);
        VendorNo2 := PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(CompanySizeCode, false);

        // [GIVEN] Create a payment practice header with Extra Fields enabled
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader, "Paym. Prac. Header Type"::Vendor, "Paym. Prac. Aggregation Type"::Period);
        PaymentPracticeHeader."Reporting Scheme" := PaymentPracticeHeader."Reporting Scheme"::"Small Business";
        PaymentPracticeHeader.Modify();

        // [GIVEN] Vendor 1: payment times 5, 5, 10 (mode = 5)
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo1, WorkDate(), WorkDate(), WorkDate() + 5);
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo1, WorkDate(), WorkDate(), WorkDate() + 5);
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo1, WorkDate(), WorkDate(), WorkDate() + 10);

        // [GIVEN] Vendor 2: payment times 8, 8, 12 (mode = 8)
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo2, WorkDate(), WorkDate(), WorkDate() + 8);
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo2, WorkDate(), WorkDate(), WorkDate() + 8);
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo2, WorkDate(), WorkDate(), WorkDate() + 12);

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
        CompanySizeCode: Code[20];
        VendorNo: Code[20];
    begin
        // [SCENARIO 568642] Check median payment time calculation with odd number of entries
        Initialize();

        // [GIVEN] Create a vendor with small business company size
        CompanySizeCode := PaymentPracticesLibrary.CreateCompanySizeCode(true);
        VendorNo := PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(CompanySizeCode, false);

        // [GIVEN] Create a payment practice header with Extra Fields enabled
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader, "Paym. Prac. Header Type"::Vendor, "Paym. Prac. Aggregation Type"::Period);
        PaymentPracticeHeader."Reporting Scheme" := PaymentPracticeHeader."Reporting Scheme"::"Small Business";
        PaymentPracticeHeader.Modify();

        // [GIVEN] Post entries with payment times: 3, 7, 5, 11, 9 (sorted: 3, 5, 7, 9, 11; median = 7)
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + 3);
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + 7);
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + 5);
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + 11);
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + 9);

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
        CompanySizeCode: Code[20];
        VendorNo: Code[20];
    begin
        // [SCENARIO 568642] Check median payment time calculation with even number of entries
        Initialize();

        // [GIVEN] Create a vendor with small business company size
        CompanySizeCode := PaymentPracticesLibrary.CreateCompanySizeCode(true);
        VendorNo := PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(CompanySizeCode, false);

        // [GIVEN] Create a payment practice header with Extra Fields enabled
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader, "Paym. Prac. Header Type"::Vendor, "Paym. Prac. Aggregation Type"::Period);
        PaymentPracticeHeader."Reporting Scheme" := PaymentPracticeHeader."Reporting Scheme"::"Small Business";
        PaymentPracticeHeader.Modify();

        // [GIVEN] Post entries with payment times: 4, 10, 2, 8 (sorted: 2, 4, 8, 10; median = (4 + 8) / 2 = 6)
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + 4);
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + 10);
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + 2);
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + 8);

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
        CompanySizeCode: Code[20];
        VendorNo: Code[20];
        i: Integer;
    begin
        // [SCENARIO 568642] Check 80th percentile payment time calculation
        Initialize();

        // [GIVEN] Create a vendor with small business company size
        CompanySizeCode := PaymentPracticesLibrary.CreateCompanySizeCode(true);
        VendorNo := PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(CompanySizeCode, false);

        // [GIVEN] Create a payment practice header with Extra Fields enabled
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader, "Paym. Prac. Header Type"::Vendor, "Paym. Prac. Aggregation Type"::Period);
        PaymentPracticeHeader."Reporting Scheme" := PaymentPracticeHeader."Reporting Scheme"::"Small Business";
        PaymentPracticeHeader.Modify();

        // [GIVEN] Post 10 entries with payment times 1 through 10
        for i := 1 to 10 do
            PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + i);

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
        CompanySizeCode: Code[20];
        VendorNo: Code[20];
        i: Integer;
    begin
        // [SCENARIO 568642] Check 95th percentile payment time calculation
        Initialize();

        // [GIVEN] Create a vendor with small business company size
        CompanySizeCode := PaymentPracticesLibrary.CreateCompanySizeCode(true);
        VendorNo := PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(CompanySizeCode, false);

        // [GIVEN] Create a payment practice header with Extra Fields enabled
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader, "Paym. Prac. Header Type"::Vendor, "Paym. Prac. Aggregation Type"::Period);
        PaymentPracticeHeader."Reporting Scheme" := PaymentPracticeHeader."Reporting Scheme"::"Small Business";
        PaymentPracticeHeader.Modify();

        // [GIVEN] Post 20 entries with payment times 1 through 20
        for i := 1 to 20 do
            PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + i);

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
        CompanySizeCode: Code[20];
        VendorNo: Code[20];
        i: Integer;
    begin
        // [SCENARIO 568642] Check 80th percentile when index is not a whole number (7 * 80 / 100 = 5.6, truncated to 5)
        Initialize();

        // [GIVEN] Create a vendor with small business company size
        CompanySizeCode := PaymentPracticesLibrary.CreateCompanySizeCode(true);
        VendorNo := PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(CompanySizeCode, false);

        // [GIVEN] Create a payment practice header with Extra Fields enabled
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader, "Paym. Prac. Header Type"::Vendor, "Paym. Prac. Aggregation Type"::Period);
        PaymentPracticeHeader."Reporting Scheme" := PaymentPracticeHeader."Reporting Scheme"::"Small Business";
        PaymentPracticeHeader.Modify();

        // [GIVEN] Post 7 entries with payment times 1 through 7
        for i := 1 to 7 do
            PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + i);

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
        CompanySizeCode: Code[20];
        VendorNo: Code[20];
        i: Integer;
    begin
        // [SCENARIO 568642] Check 95th percentile when index is not a whole number (13 * 95 / 100 = 12.35, truncated to 12)
        Initialize();

        // [GIVEN] Create a vendor with small business company size
        CompanySizeCode := PaymentPracticesLibrary.CreateCompanySizeCode(true);
        VendorNo := PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(CompanySizeCode, false);

        // [GIVEN] Create a payment practice header with Extra Fields enabled
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader, "Paym. Prac. Header Type"::Vendor, "Paym. Prac. Aggregation Type"::Period);
        PaymentPracticeHeader."Reporting Scheme" := PaymentPracticeHeader."Reporting Scheme"::"Small Business";
        PaymentPracticeHeader.Modify();

        // [GIVEN] Post 13 entries with payment times 1 through 13
        for i := 1 to 13 do
            PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorNo, WorkDate(), WorkDate(), WorkDate() + i);

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
        CompanySizeCode: Code[20];
        VendorWithGLN: Code[20];
        VendorWithoutGLN: Code[20];
        PeppolInvoiceCount: Integer;
        NonPeppolInvoiceCount: Integer;
        ExpectedPctPeppol: Decimal;
        i: Integer;
    begin
        // [SCENARIO 568642] Check Pct Peppol Enabled calculation with one vendor that has GLN and one that does not.
        Initialize();

        // [GIVEN] Create a company size marked as small business
        CompanySizeCode := PaymentPracticesLibrary.CreateCompanySizeCode(true);

        // [GIVEN] Create a vendor with a GLN value (Peppol enabled) and small business company size
        VendorWithGLN := PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(CompanySizeCode, false);
        Vendor.Get(VendorWithGLN);
        Vendor.GLN := '1234567890123';
        Vendor.Modify();

        // [GIVEN] Create a vendor without a GLN value (not Peppol enabled) with small business company size
        VendorWithoutGLN := PaymentPracticesLibrary.CreateVendorNoWithSizeAndExcl(CompanySizeCode, false);

        // [GIVEN] Create a payment practice header with Extra Fields enabled
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader, "Paym. Prac. Header Type"::Vendor, "Paym. Prac. Aggregation Type"::Period);
        PaymentPracticeHeader."Reporting Scheme" := PaymentPracticeHeader."Reporting Scheme"::"Small Business";
        PaymentPracticeHeader.Modify();

        // [GIVEN] Post 3 paid invoices for the GLN vendor
        PeppolInvoiceCount := 3;
        for i := 1 to PeppolInvoiceCount do
            PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorWithGLN, WorkDate(), WorkDate(), WorkDate() + 5);

        // [GIVEN] Post 2 paid invoices for the non-GLN vendor
        NonPeppolInvoiceCount := 2;
        for i := 1 to NonPeppolInvoiceCount do
            PaymentPracticesLibrary.MockVendorInvoiceAndPayment(VendorWithoutGLN, WorkDate(), WorkDate(), WorkDate() + 10);

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
        // [SCENARIO 568642] Generate payment practices with "Only Small Businesses" enabled. Only small business vendors should be included in the statistics (median, mode, percentiles) .
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
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(SmallBizVendor1, WorkDate(), WorkDate(), WorkDate() + 5);
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(SmallBizVendor1, WorkDate(), WorkDate(), WorkDate() + 5);
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(SmallBizVendor1, WorkDate(), WorkDate(), WorkDate() + 10);

        // [GIVEN] Post paid invoices for small business vendor 2 with payment times 8, 8
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(SmallBizVendor2, WorkDate(), WorkDate(), WorkDate() + 8);
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(SmallBizVendor2, WorkDate(), WorkDate(), WorkDate() + 8);

        // [GIVEN] Post paid invoices for non-small business vendor 1 with payment time 20
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(NonSmallBizVendor1, WorkDate(), WorkDate(), WorkDate() + 20);

        // [GIVEN] Post paid invoices for non-small business vendor 2 with payment time 30
        PaymentPracticesLibrary.MockVendorInvoiceAndPayment(NonSmallBizVendor2, WorkDate(), WorkDate(), WorkDate() + 30);

        // [GIVEN] Create a payment practice header with "Small Businesses" reporting scheme
        PaymentPracticesLibrary.CreatePaymentPracticeHeaderSimple(PaymentPracticeHeader, "Paym. Prac. Header Type"::Vendor, "Paym. Prac. Aggregation Type"::Period);
        PaymentPracticeHeader."Reporting Scheme" := PaymentPracticeHeader."Reporting Scheme"::"Small Business";
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

    local procedure MockPaymentPracticeData(HeaderNo: Integer; EntryNo: Integer; IsOpen: Boolean; ActualPaymentDays: Integer; AgreedPaymentDays: Integer; InvoiceAmount: Decimal; IsDisputed: Boolean)
    var
        PaymentPracticeData: Record "Payment Practice Data";
    begin
        PaymentPracticeData.Init();
        PaymentPracticeData."Header No." := HeaderNo;
        PaymentPracticeData."Invoice Entry No." := EntryNo;
        PaymentPracticeData."Source Type" := "Paym. Prac. Header Type"::Vendor;
        PaymentPracticeData."Invoice Is Open" := IsOpen;
        PaymentPracticeData."Actual Payment Days" := ActualPaymentDays;
        PaymentPracticeData."Agreed Payment Days" := AgreedPaymentDays;
        PaymentPracticeData."Invoice Amount" := InvoiceAmount;
        if IsDisputed then
            PaymentPracticeData."Dispute Status" := 'DISPUTED';
        if (not IsOpen) and (ActualPaymentDays > AgreedPaymentDays) then
                PaymentPracticeData."Overdue Due to Dispute" := IsDisputed;
        PaymentPracticeData.Insert();
    end;

    local procedure VerifyAllLinesInvoiceCountAndValueZero(HeaderNo: Integer)
    var
        PaymentPracticeLine: Record "Payment Practice Line";
    begin
        PaymentPracticeLine.SetRange("Header No.", HeaderNo);
        PaymentPracticeLine.FindSet();
        repeat
            Assert.AreEqual(0, PaymentPracticeLine."Invoice Count", 'Invoice Count should be 0 for Standard scheme');
            Assert.AreEqual(0, PaymentPracticeLine."Invoice Value", 'Invoice Value should be 0 for Standard scheme');
        until PaymentPracticeLine.Next() = 0;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}
