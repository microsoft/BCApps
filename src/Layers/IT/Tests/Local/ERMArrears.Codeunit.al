codeunit 144095 "ERM Arrears"
{
    //  1. Verify interest on Arrears with different interest rate in Calculate Interest on Arrears report for customer.
    //  2. Verify interest on Arrears with same interest rate in Calculate Interest on Arrears report for customer.
    //  3. Verify interest on Arrears with different interest rate with Print Details in Calculate Interest on Arrears report for customer.
    //  4. Verify interest on Arrears with different interest rate in Calculate Interest on Arrears report for vendor.
    //  5. Verify interest on Arrears with same interest rate in Calculate Interest on Arrears report for Vendor.
    //  6. Verify interest on Arrears with different interest rate with Print Details in Calculate Interest on Arrears report for vendor.
    //  7. Verify interest on Arrears with different interest rate with Payment and Print Details in Calculate Interest on Arrears report for vendor.
    //  8. Verify interest on Arrears with different interest rate with Payment and without Print Details in Calculate Interest on Arrears report for vendor.
    //  9. Verify interest on Arrears with different interest rate with Partially Payment before Due Date and without Print Details in Calculate Interest on Arrears report for vendor.
    // 10. Verify interest on Arrears with different interest rate with Partially Payment before Due Date and with Print Details in Calculate Interest on Arrears report for vendor.
    // 11. Verify interest on Arrears with different interest rate with Full Payment before Due Date and without Print Details in Calculate Interest on Arrears report for vendor.
    // 12. Verify interest on Arrears with different interest rate with Full Payment before Due Date and with Print Details in Calculate Interest on Arrears report for vendor.
    // 13. Verify interest on Arrears with different interest rate with Full Payment after Due Date and with Print Details in Calculate Interest on Arrears report for vendor.
    // 14. Verify interest on Arrears with different interest rate with Full Payment after Due Date and without Print Details in Calculate Interest on Arrears report for vendor.
    // 15. Verify interest on Arrears with different interest rate with Payment and Print Details in Calculate Interest on Arrears report for customer.
    // 16. Verify interest on Arrears with different interest rate with Payment and without Print Details in Calculate Interest on Arrears report for customer.
    // 17. Verify interest on Arrears with different interest rate with Partially Payment before Due Date and without Print Details in Calculate Interest on Arrears report for customer.
    // 18. Verify interest on Arrears with different interest rate with Partially Payment before Due Date and with Print Details in Calculate Interest on Arrears report for customer.
    // 19. Verify interest on Arrears with different interest rate with Full Payment before Due Date and without Print Details in Calculate Interest on Arrears report for customer.
    // 20. Verify interest on Arrears with different interest rate with Full Payment before Due Date and with Print Details in Calculate Interest on Arrears report for customer.
    // 21. Verify interest on Arrears with different interest rate with Full Payment after Due Date and with Print Details in Calculate Interest on Arrears report for customer.
    // 22. Verify interest on Arrears with different interest rate with Full Payment after Due Date and without Print Details in Calculate Interest on Arrears report for customer.
    // 23. Verify No Negative interest on Arrears with different interest rate with Full Payment after Due Date and without Print Details in Calculate Interest on Arrears report for customer.
    // 24. Verify interest on Arrears with different interest rate, Partially paid with multiple Payments after Due Date and Print Details in Calculate Interest on Arrears report for customer.
    // 25. Verify interest on Arrears with different interest rate, Partially paid with multiple Payments after Due Date and without Print Details in Calculate Interest on Arrears report for customer.
    // 26. Verify interest on Arrears with different interest rate, Partially paid with multiple Payments before and after Due Date and Print Details in Calculate Interest on Arrears report for customer.
    // 27. Verify interest on Arrears with different interest rate, Partially paid with multiple Payments before and after Due Date and without Print Details in Calculate Interest on Arrears report for customer.
    // 28. Verify interest on Arrears with different interest rate, Fully paid with multiple Payments after Due Date and Print Details in Calculate Interest on Arrears report for customer.
    // 29. Verify interest on Arrears with different interest rate, Fully paid with multiple Payments after Due Date and without Print Details in Calculate Interest on Arrears report for customer.
    // 30. Verify interest on Arrears with different interest rate, Fully paid with multiple Payments before and after Due Date and Print Details in Calculate Interest on Arrears report for customer.
    // 31. Verify interest on Arrears with different interest rate, Fully paid with multiple Payments before and after Due Date and without Print Details in Calculate Interest on Arrears report for customer.
    // 32. Verify interest on Arrears with different interest rate, Partially paid with multiple Payments after Due Date and Print Details in Calculate Interest on Arrears report for vendor.
    // 33. Verify interest on Arrears with different interest rate, Partially paid with multiple Payments after Due Date and without Print Details in Calculate Interest on Arrears report for vendor.
    // 34. Verify interest on Arrears with different interest rate, Partially paid with multiple Payments before and after Due Date and Print Details in Calculate Interest on Arrears report for vendor.
    // 35. Verify interest on Arrears with different interest rate, Partially paid with multiple Payments before and after Due Date and without Print Details in Calculate Interest on Arrears report for vendor.
    // 36. Verify interest on Arrears with different interest rate, Fully paid with multiple Payments after Due Date and Print Details in Calculate Interest on Arrears report for vendor.
    // 37. Verify interest on Arrears with different interest rate, Fully paid with multiple Payments after Due Date and without Print Details in Calculate Interest on Arrears report for vendor.
    // 38. Verify interest on Arrears with different interest rate, Fully paid with multiple Payments before and after Due Date and Print Details in Calculate Interest on Arrears report for vendor.
    // 39. Verify interest on Arrears with different interest rate, Fully paid with multiple Payments before and after Due Date and without Print Details in Calculate Interest on Arrears report for vendor.
    // 40. Verify Customer and General ledger entries after issue Finance Charge Memo.
    // 41. Verify Customer and General ledger entries after issue Reminder.
    // 
    //  Covers Test Cases for WI - 345144
    // ---------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                        TFS ID
    // ---------------------------------------------------------------------------------------------------------------------------------
    // DifferentIntOnArrearsOnCustomer                                                                                     155600,155692
    // SameIntOnArrearsOnCustomer                                                                                                 155601
    // DifferentIntOnArrearsWithPrintDetailsOnCustomer                                                                     155691,152262
    // DifferentIntOnArrearsOnVendor                                                                                       155602,155696
    // SameIntOnArrearsOnVendor                                                                                                   155603
    // DifferentIntOnArrearsWithPrintDetailsOnVendor                                                                              155695
    // InterestOnArrearsWithPmtAndPrintDetailsOnVendor                                                                     155697,177904
    // InterestOnArrearsWithPmtWithoutPrintDetailsOnVendor                                                                        155698
    // InterestOnArrearsWithPmtAndPrintDetailsOnCustomer                                                                   153301,155693
    // InterestOnArrearsWithPmtWithoutPrintDetailsOnCustomer                                                               155694,177912
    // 
    //  Covers Test Cases for WI - 345142
    // ---------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                        TFS ID
    // ---------------------------------------------------------------------------------------------------------------------------------
    // PartialPmtBeforeDueDateWithoutPrintDetailsOnVendor,PartialPmtBeforeDueDateWithPrintDetailsOnVendor                         177897
    // FullPmtBeforeDueDateWithoutPrintDetailsOnVendor,FullPmtBeforeDueDateWithPrintDetailsOnOnVendor                             177899
    // FullPmtAfterDueDateWithPrintDetailsOnOnVendor,FullPmtAfterDueDateWithoutPrintDetailsOnVendor                               177902
    // PartialPmtBeforeDueDateWithoutPrintDetailsOnCustomer,PartialPmtBeforeDueDateWithPrintDetailsOnCustomer                     177906
    // FullPmtBeforeDueDateWithoutPrintDetailsOnCustomer,FullPmtBeforeDueDateWithPrintDetailsOnCustomer                           177907
    // FullPmtAfterDueDateWithPrintDetailsOnCustomer,FullPmtAfterDueDateWithoutPrintDetailsOnCustomer                             177910
    // NoNegativeIntOnArrearsBeforeCustomerPayment                                                                                152265
    // 
    //  Covers Test Cases for WI - 345821
    // ---------------------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                                        TFS ID
    // ---------------------------------------------------------------------------------------------------------------------------------
    // SalesInvPartiallyPaidWithMultiplePaymentPrintDetail,SalesInvPartiallyPaidWithMultiplePayment                               177913
    // SalesInvPartiallyPaidBeforeAndAfterDueDatePrintDetail,SalesInvPartiallyPaidWithMultPmtBeforeAndAfterDueDate                177908
    // SalesInvFullyPaidWithMultiplePaymentPrintDetail,SalesInvFullyPaidWithMultiplePayment                                       177911
    // SalesInvFullyPaidBeforeAndAfterDueDatePrintDetail,SalesInvFullyPaidWithMultPmtBeforeAndAfterDueDate                        177909
    // PurchInvPartiallyPaidWithMultiplePaymentPrintDetail,PurchInvPartiallyPaidWithMultiplePayment                               177905
    // PurchInvPartiallyPaidBeforeAndAfterDueDatePrintDetail,PurchInvPartiallyPaidWithMultPmtBeforeAndAfterDueDate                177900
    // PurchInvFullyPaidWithMultiplePaymentPrintDetail,PurchInvFullyPaidWithMultiplePayment                                       177903
    // PurchInvFullyPaidBeforeAndAfterDueDatePrintDetail,PurchInvFullyPaidWithMultPmtBeforeAndAfterDueDate                        177901
    // IssueFinanceChargeMemoForIntAndAdditionalFee                                                                               189377
    // IssueReminderForIntAndAdditionalFee                                                                                        189376

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryITLocalization: Codeunit "Library - IT Localization";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        CustRemainingAmountCap: Label 'Cust__Ledger_Entry__Remaining_Amt___LCY___Control1130098';
        DateFormulaTxt: Label '<%1 Y+%1 M>', Locked = true;
        DaysTxt: Label '%1 D', Comment = 'Days';
        RateLabelCustCap: Label 'RateLabel';
        RateLabelVendCap: Label 'RateLabel_Control1130023';
        TotalDayDiffCustCap: Label 'TotalDayDiff';
        TotalDayDiffVendCap: Label 'TotalDayDiff_Control1130024';
        VariableRateTxt: Label 'Variable Rate';
        VendRemainingAmountCap: Label 'Vendor_Ledger_Entry__Remaining_Amt___LCY__';
        YearsTxt: Label '1Y', Comment = 'Year';
        YearPlusTxt: Label '+1Y', Comment = 'Years';

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DifferentIntOnArrearsOnCustomer()
    begin
        // Verify interest on Arrears with different interest rate in Calculate Interest on Arrears report for customer.
        Initialize();
        InterestOnArrearsForCustomer(LibraryRandom.RandInt(5), false);  // Using Random for Interest rate and False for Print Details.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SameIntOnArrearsOnCustomer()
    begin
        // Verify interest on Arrears with same interest rate in Calculate Interest on Arrears report for customer.
        Initialize();
        InterestOnArrearsForCustomer(0, false);  // Using 0 for Interest rate and False for Print Details.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DifferentIntOnArrearsWithPrintDetailsOnCustomer()
    begin
        // Verify interest on Arrears with different interest rate with Print Details in Calculate Interest on Arrears report for customer.
        Initialize();
        InterestOnArrearsForCustomer(LibraryRandom.RandInt(5), true);  // Using Random for Interest rate and True for Print Details.
    end;

    local procedure InterestOnArrearsForCustomer(DiffInterestRate: Decimal; PrintDetails: Boolean)
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InterestRate: Decimal;
        PrintType: Option Customer,Vendor;
        EndingDate: Date;
    begin
        // Setup: Create Finance Charge Term with Interest on Arrears and post sales invoice.
        EndingDate := CalcDate(StrSubstNo(DateFormulaTxt, Format(LibraryRandom.RandIntInRange(4, 6))), WorkDate());  // Using Random for date formula.
        InterestRate := SetupForCalcInterestOnArrears(FinanceChargeTerms, DiffInterestRate, CalcDate('<-1M>', EndingDate));
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, CreateCustomer(
            FinanceChargeTerms.Code), WorkDate(), LibraryRandom.RandDecInRange(100, 500, 2));  // Using Random Decimal for Amount.
        EnqueueRequestPageHandlerValues(GenJournalLine."Account No.", PrintType::Customer, EndingDate, PrintDetails);  // Enqueue values of CalculateInterestOnArrearsRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Calculate Interest on Arrears");

        // Verify: Verify Interest rate and Days Difference in Calculate Interest on Arrears report for customer.
        FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Account No.", CustLedgerEntry."Document Type"::Invoice);
        VerifyCalcInterestOnArrearsReport(
          TotalDayDiffCustCap, RateLabelCustCap, DiffInterestRate, InterestRate, EndingDate, CustLedgerEntry."Due Date");
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DifferentIntOnArrearsOnVendor()
    begin
        // Verify interest on Arrears with different interest rate in Calculate Interest on Arrears report for vendor.
        Initialize();
        InterestOnArrearsForVendor(LibraryRandom.RandInt(5), false);  // Using Random for Interest rate and False for Print Details.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SameIntOnArrearsOnVendor()
    begin
        // Verify interest on Arrears with same interest rate in Calculate Interest on Arrears report for vendor.
        Initialize();
        InterestOnArrearsForVendor(0, false);  // Using 0 for Interest rate and False for Print Details.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DifferentIntOnArrearsWithPrintDetailsOnVendor()
    begin
        // Verify interest on Arrears with different interest rate with Print Details in Calculate Interest on Arrears report for vendor.
        Initialize();
        InterestOnArrearsForVendor(LibraryRandom.RandInt(5), true);  // Using Random for Interest rate and True for Print Details.
    end;

    local procedure InterestOnArrearsForVendor(DiffInterestRate: Decimal; PrintDetails: Boolean)
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        InterestRate: Decimal;
        PrintType: Option Customer,Vendor;
        EndingDate: Date;
    begin
        // Setup: Create Finance Charge Term with Interest on Arrears and post purchase invoice.
        EndingDate := CalcDate(StrSubstNo(DateFormulaTxt, Format(LibraryRandom.RandIntInRange(4, 6))), WorkDate());  // Using Random for date formula.
        InterestRate := SetupForCalcInterestOnArrears(FinanceChargeTerms, DiffInterestRate, CalcDate('<-1M>', EndingDate));
        CreateAndPostGenJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor, CreateVendor(
            FinanceChargeTerms.Code), WorkDate(), -LibraryRandom.RandDecInRange(100, 500, 2));  // Using Random Decimal for Amount.
        EnqueueRequestPageHandlerValues(GenJournalLine."Account No.", PrintType::Vendor, EndingDate, PrintDetails);  // Enqueue values of CalculateInterestOnArrearsRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Calculate Interest on Arrears");

        // Verify: Verify Interest rate and Days Difference in Calculate Interest on Arrears report for vendor.
        FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Account No.", VendorLedgerEntry."Document Type"::Invoice);
        VerifyCalcInterestOnArrearsReport(
          TotalDayDiffVendCap, RateLabelVendCap, DiffInterestRate, InterestRate, EndingDate, VendorLedgerEntry."Due Date");
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InterestOnArrearsWithPmtAndPrintDetailsOnVendor()
    var
        EndingDate: Date;
    begin
        // Verify interest on Arrears with different interest rate with Payment and Print Details in Calculate Interest on Arrears report for vendor.
        Initialize();
        EndingDate := CalcDate(StrSubstNo(DateFormulaTxt, Format(LibraryRandom.RandIntInRange(4, 6))), WorkDate());  // Using Random for date formula.
        InterestOnArrearsForVendorWithPayment(EndingDate, EndingDate, LibraryRandom.RandInt(5), true, YearsTxt, 2);  // Using Random for Interest rate, True for Print Details and 2 for Partially Payment.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InterestOnArrearsWithPmtWithoutPrintDetailsOnVendor()
    var
        EndingDate: Date;
    begin
        // Verify interest on Arrears with different interest rate with Payment and without Print Details in Calculate Interest on Arrears report for vendor.
        Initialize();
        EndingDate := CalcDate(StrSubstNo(DateFormulaTxt, Format(LibraryRandom.RandIntInRange(4, 6))), WorkDate());  // Using Random for date formula.
        InterestOnArrearsForVendorWithPayment(EndingDate, EndingDate, LibraryRandom.RandInt(5), false, YearsTxt, 2);  // Using Random for Interest rate, False for Print Details and 2 for Partially Payment.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PartialPmtBeforeDueDateWithoutPrintDetailsOnVendor()
    var
        EndingDate: Date;
    begin
        // Verify interest on Arrears with different interest rate with Partially Payment before Due Date and without Print Details in Calculate Interest on Arrears report for vendor.
        Initialize();
        EndingDate := CalcDate(StrSubstNo(DateFormulaTxt, Format(LibraryRandom.RandIntInRange(4, 6))), WorkDate());  // Using Random for date formula.
        InterestOnArrearsForVendorWithPayment(
          EndingDate, EndingDate, LibraryRandom.RandInt(5), false, StrSubstNo(
            DaysTxt, Format(LibraryRandom.RandIntInRange(10, 15))), 2);  // Using Random for Interest rate and No. of Days, False for Print Details and 2 for Partially Payment.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PartialPmtBeforeDueDateWithPrintDetailsOnVendor()
    var
        EndingDate: Date;
    begin
        // Verify interest on Arrears with different interest rate with Partially Payment before Due Date and with Print Details in Calculate Interest on Arrears report for vendor.
        Initialize();
        EndingDate := CalcDate(StrSubstNo(DateFormulaTxt, Format(LibraryRandom.RandIntInRange(4, 6))), WorkDate());  // Using Random for date formula.
        InterestOnArrearsForVendorWithPayment(
          EndingDate, EndingDate, LibraryRandom.RandInt(5), true, StrSubstNo(
            DaysTxt, Format(LibraryRandom.RandIntInRange(10, 15))), 2);  // Using Random for Interest rate and No. of Days, True for Print Details and 2 for Partially Payment.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FullPmtBeforeDueDateWithoutPrintDetailsOnVendor()
    var
        EndingDate: Date;
    begin
        // Verify interest on Arrears with different interest rate with Full Payment before Due Date and without Print Details in Calculate Interest on Arrears report for vendor.
        Initialize();
        EndingDate := CalcDate(StrSubstNo(DateFormulaTxt, Format(LibraryRandom.RandIntInRange(4, 6))), WorkDate());  // Using Random for date formula.
        InterestOnArrearsForVendorWithPayment(
          EndingDate, CalcDate('<30D>', WorkDate()), LibraryRandom.RandInt(5), false, StrSubstNo(
            DaysTxt, Format(LibraryRandom.RandIntInRange(10, 15))), 1);  // Using Random for Interest rate and No. of Days, False for Print Details, 1 for Full Payment and 30 Days required for calculate Days Diifferece.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FullPmtBeforeDueDateWithPrintDetailsOnOnVendor()
    var
        EndingDate: Date;
    begin
        // Verify interest on Arrears with different interest rate with Full Payment before Due Date and with Print Details in Calculate Interest on Arrears report for vendor.
        Initialize();
        EndingDate := CalcDate(StrSubstNo(DateFormulaTxt, Format(LibraryRandom.RandIntInRange(4, 6))), WorkDate());  // Using Random for date formula.
        InterestOnArrearsForVendorWithPayment(
          EndingDate, CalcDate('<30D>', WorkDate()), LibraryRandom.RandInt(5), true, StrSubstNo(
            DaysTxt, Format(LibraryRandom.RandIntInRange(10, 15))), 1);  // Using Random for Interest rate and No. of Days, True for Print Details, 1 for Full Payment and 30 Days required for calculate Days Diifferece.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FullPmtAfterDueDateWithPrintDetailsOnOnVendor()
    var
        EndingDate: Date;
    begin
        // Verify interest on Arrears with different interest rate with Full Payment after Due Date and with Print Details in Calculate Interest on Arrears report for vendor.
        Initialize();
        EndingDate := CalcDate(StrSubstNo(DateFormulaTxt, Format(LibraryRandom.RandIntInRange(4, 6))), WorkDate());  // Using Random for date formula.
        InterestOnArrearsForVendorWithPayment(EndingDate, CalcDate('<-30D>', EndingDate), LibraryRandom.RandInt(5), true, YearsTxt, 1);  // Using Random for Interest rate, True for Print Details, 1 for Full Payment and 30 days for Days Difference.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FullPmtAfterDueDateWithoutPrintDetailsOnVendor()
    var
        EndingDate: Date;
    begin
        // Verify interest on Arrears with different interest rate with Full Payment after Due Date and without Print Details in Calculate Interest on Arrears report for vendor.
        Initialize();
        EndingDate := CalcDate(StrSubstNo(DateFormulaTxt, Format(LibraryRandom.RandIntInRange(4, 6))), WorkDate());  // Using Random for date formula.
        InterestOnArrearsForVendorWithPayment(
          EndingDate, CalcDate('<-30D>', EndingDate), LibraryRandom.RandInt(5), false, YearsTxt, 1);  // Using Random for Interest rate, False for Print Details, 1 for Full Payment and 30 days for Days Difference.
    end;

    local procedure InterestOnArrearsForVendorWithPayment(EndingDate: Date; PrintEndingDate: Date; DiffInterestRate: Decimal; PrintDetails: Boolean; NoOfDays: Text[10]; PaymentPart: Integer)
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        GenJournalLine: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        InterestRate: Decimal;
        PrintType: Option Customer,Vendor;
    begin
        // Setup: Create Finance Charge Term with Interest on Arrears and post purchase invoice and Payment, post application.
        InterestRate := SetupForCalcInterestOnArrears(FinanceChargeTerms, DiffInterestRate, CalcDate('<-1M>', EndingDate));
        CreateInvoiceAndMakePayment(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, CreateVendor(
            FinanceChargeTerms.Code), NoOfDays, -LibraryRandom.RandDecInRange(100, 500, 2), PaymentPart);  // Using Random Decimal for Amount
        FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Account No.", VendorLedgerEntry."Document Type"::Invoice);
        PostVendorApplication(GenJournalLine."Account No.");
        EnqueueRequestPageHandlerValues(GenJournalLine."Account No.", PrintType::Vendor, EndingDate, PrintDetails);  // Enqueue values of CalculateInterestOnArrearsRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Calculate Interest on Arrears");

        // Verify: Verify Interest rate, Days Difference and Remaining Amount in Calculate Interest on Arrears report for vendor.
        VendorLedgerEntry.CalcFields("Remaining Amount");
        VerifyCalcInterestOnArrearsReport(
          TotalDayDiffVendCap, RateLabelVendCap, DiffInterestRate, InterestRate, PrintEndingDate, VendorLedgerEntry."Due Date");
        LibraryReportDataset.AssertElementWithValueExists(
          VendRemainingAmountCap, Round(VendorLedgerEntry."Remaining Amount", LibraryERM.GetAmountRoundingPrecision(), '<'));  // Remaining Amount after partial payment.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InterestOnArrearsWithPmtAndPrintDetailsOnCustomer()
    var
        EndingDate: Date;
    begin
        // Verify interest on Arrears with different interest rate with Payment and Print Details in Calculate Interest on Arrears report for customer.
        Initialize();
        EndingDate := CalcDate(StrSubstNo(DateFormulaTxt, Format(LibraryRandom.RandIntInRange(4, 6))), WorkDate());  // Using Random for date formula.
        InterestOnArrearsForCustomerWithPayment(EndingDate, EndingDate, LibraryRandom.RandInt(5), true, YearsTxt, 2);  // Using Random for Interest rate, True for Print Details and 2 for Partially Payment.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InterestOnArrearsWithPmtWithoutPrintDetailsOnCustomer()
    var
        EndingDate: Date;
    begin
        // Verify interest on Arrears with different interest rate with Payment and without Print Details in Calculate Interest on Arrears report for customer.
        Initialize();
        EndingDate := CalcDate(StrSubstNo(DateFormulaTxt, Format(LibraryRandom.RandIntInRange(4, 6))), WorkDate());  // Using Random for date formula.
        InterestOnArrearsForCustomerWithPayment(EndingDate, EndingDate, LibraryRandom.RandInt(5), false, YearsTxt, 2);  // Using Random for Interest rate, False for Print Details and 2 for Partially Payment.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PartialPmtBeforeDueDateWithoutPrintDetailsOnCustomer()
    var
        EndingDate: Date;
    begin
        // Verify interest on Arrears with different interest rate with Partially Payment before Due Date and without Print Details in Calculate Interest on Arrears report for customer.
        Initialize();
        EndingDate := CalcDate(StrSubstNo(DateFormulaTxt, Format(LibraryRandom.RandIntInRange(4, 6))), WorkDate());  // Using Random for date formula.
        InterestOnArrearsForCustomerWithPayment(
          EndingDate, EndingDate, LibraryRandom.RandInt(5), false, StrSubstNo(
            DaysTxt, Format(LibraryRandom.RandIntInRange(10, 15))), 2);  // Using Random for Interest rate and No. of Days, False for Print Details and 2 for Partially Payment.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PartialPmtBeforeDueDateWithPrintDetailsOnCustomer()
    var
        EndingDate: Date;
    begin
        // Verify interest on Arrears with different interest rate with Partially Payment before Due Date and with Print Details in Calculate Interest on Arrears report for customer.
        Initialize();
        EndingDate := CalcDate(StrSubstNo(DateFormulaTxt, Format(LibraryRandom.RandIntInRange(4, 6))), WorkDate());  // Using Random for date formula.
        InterestOnArrearsForCustomerWithPayment(
          EndingDate, EndingDate, LibraryRandom.RandInt(5), true, StrSubstNo(
            DaysTxt, Format(LibraryRandom.RandIntInRange(10, 15))), 2);  // Using Random for Interest rate and No. of Days, True for Print Details and 2 for Partially Payment.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FullPmtBeforeDueDateWithoutPrintDetailsOnCustomer()
    var
        EndingDate: Date;
    begin
        // Verify interest on Arrears with different interest rate with Full Payment before Due Date and without Print Details in Calculate Interest on Arrears report for customer.
        Initialize();
        EndingDate := CalcDate(StrSubstNo(DateFormulaTxt, Format(LibraryRandom.RandIntInRange(1, 4))), WorkDate());  // Using Random for date formula.
        InterestOnArrearsForCustomerWithPayment(
          EndingDate, CalcDate('<30D>', WorkDate()), LibraryRandom.RandInt(5), false, StrSubstNo(
            DaysTxt, Format(LibraryRandom.RandIntInRange(10, 15))), 1);  // Using Random for Interest rate and No. of Days, False for Print Details, 1 for Full Payment and 30 days for Days Difference.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FullPmtBeforeDueDateWithPrintDetailsOnCustomer()
    var
        EndingDate: Date;
    begin
        // Verify interest on Arrears with different interest rate with Full Payment before Due Date and with Print Details in Calculate Interest on Arrears report for customer.
        Initialize();
        EndingDate := CalcDate(StrSubstNo(DateFormulaTxt, Format(LibraryRandom.RandIntInRange(1, 4))), WorkDate());  // Using Random for date formula.
        InterestOnArrearsForCustomerWithPayment(
          EndingDate, CalcDate('<30D>', WorkDate()), LibraryRandom.RandInt(5), true, StrSubstNo(
            DaysTxt, Format(LibraryRandom.RandIntInRange(10, 15))), 1);  // Using Random for Interest rate and No. of Days, True for Print Details, 1 for Full Payment and 30 days for Days Difference.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FullPmtAfterDueDateWithPrintDetailsOnCustomer()
    var
        EndingDate: Date;
    begin
        // Verify interest on Arrears with different interest rate with Full Payment after Due Date and with Print Details in Calculate Interest on Arrears report for customer.
        Initialize();
        EndingDate := CalcDate(StrSubstNo(DateFormulaTxt, Format(LibraryRandom.RandIntInRange(4, 6))), WorkDate());  // Using Random for date formula.
        InterestOnArrearsForCustomerWithPayment(
          EndingDate, CalcDate('<-30D>', EndingDate), LibraryRandom.RandInt(5), true, YearsTxt, 1);  // Using Random for Interest rate, True for Print Details, 1 for Full Payment, and 30 days for Days Difference.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure FullPmtAfterDueDateWithoutPrintDetailsOnCustomer()
    var
        EndingDate: Date;
    begin
        // Verify interest on Arrears with different interest rate with Full Payment after Due Date and without Print Details in Calculate Interest on Arrears report for customer.
        Initialize();
        EndingDate := CalcDate(StrSubstNo(DateFormulaTxt, Format(LibraryRandom.RandIntInRange(4, 6))), WorkDate());  // Using Random for date formula.
        InterestOnArrearsForCustomerWithPayment(
          EndingDate, CalcDate('<-30D>', EndingDate), LibraryRandom.RandInt(5), false, YearsTxt, 1);  // Using Random for Interest rate, False for Print Details, 1 for Full Payment and 30 days for Days Difference.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure NoNegativeIntOnArrearsBeforeCustomerPayment()
    var
        EndingDate: Date;
    begin
        // Verify No Negative interest on Arrears with different interest rate with Full Payment after Due Date and without Print Details in Calculate Interest on Arrears report for customer.
        Initialize();
        EndingDate := CalcDate(StrSubstNo(DateFormulaTxt, Format(LibraryRandom.RandIntInRange(4, 6))), WorkDate());  // Using Random for date formula.
        InterestOnArrearsForCustomerWithPayment(
          EndingDate, CalcDate('<-30D>', EndingDate), LibraryRandom.RandInt(5), false, StrSubstNo(
            DaysTxt, Format(LibraryRandom.RandIntInRange(7, 10))), 1);  // Using Random Range from 7, require more than ending date, random Integer for Interest rate, False for Print Details, 1 for Full Payment and 30 days for Days Difference.
    end;

    local procedure InterestOnArrearsForCustomerWithPayment(EndingDate: Date; PrintEndingDate: Date; DiffInterestRate: Decimal; PrintDetails: Boolean; NoOfDays: Text[10]; PaymentPart: Integer)
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InterestRate: Decimal;
        PrintType: Option Customer,Vendor;
    begin
        // Setup: Create Finance Charge Term with Interest on Arrears and post Sales invoice and Payment, post application.
        InterestRate := SetupForCalcInterestOnArrears(FinanceChargeTerms, DiffInterestRate, CalcDate('<-1M>', EndingDate));
        CreateInvoiceAndMakePayment(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CreateCustomer(
            FinanceChargeTerms.Code), NoOfDays, LibraryRandom.RandIntInRange(100, 500), PaymentPart);  // Using Random Integer for Amount
        FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Account No.", CustLedgerEntry."Document Type"::Invoice);
        PostCustomerApplication(GenJournalLine."Account No.");
        EnqueueRequestPageHandlerValues(GenJournalLine."Account No.", PrintType::Customer, EndingDate, PrintDetails);  // Enqueue values of CalculateInterestOnArrearsRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Calculate Interest on Arrears");

        // Verify: Verify Interest rate, Days Difference and Remaining Amount in Calculate Interest on Arrears report for customer.
        CustLedgerEntry.CalcFields("Remaining Amount");
        VerifyCalcInterestOnArrearsReport(
          TotalDayDiffCustCap, RateLabelCustCap, DiffInterestRate, InterestRate, PrintEndingDate, CustLedgerEntry."Due Date");
        LibraryReportDataset.AssertElementWithValueExists(
          CustRemainingAmountCap, Round(CustLedgerEntry."Remaining Amount", LibraryERM.GetAmountRoundingPrecision(), '<'));  // Remaining Amount after partial payment.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvPartiallyPaidWithMultiplePaymentPrintDetail()
    begin
        // Verify interest on Arrears with different interest rate, Partially paid with multiple Payments after Due Date and Print Details in Calculate Interest on Arrears report for customer.
        Initialize();
        IntOnArrearsForCustomerWithMultiplePayment(true, YearsTxt, 4);  // Using True for Print Details, 4 for Partial Payment.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvPartiallyPaidWithMultiplePayment()
    begin
        // Verify interest on Arrears with different interest rate, Partially paid with multiple Payments after Due Date and without Print Details in Calculate Interest on Arrears report for customer.
        Initialize();
        IntOnArrearsForCustomerWithMultiplePayment(false, YearsTxt, 4);  // Using False for Print Details, 4 for Partial Payment.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvPartiallyPaidBeforeAndAfterDueDatePrintDetail()
    begin
        // Verify interest on Arrears with different interest rate, Partially paid with multiple Payments before and after Due Date and Print Details in Calculate Interest on Arrears report for customer.
        Initialize();
        IntOnArrearsForCustomerWithMultiplePayment(true, StrSubstNo(DaysTxt, Format(LibraryRandom.RandIntInRange(7, 10))), 4);  // Using Random for No. of Days, True for Print Details, 4 for Partial Payment.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvPartiallyPaidWithMultPmtBeforeAndAfterDueDate()
    begin
        // Verify interest on Arrears with different interest rate, Partially paid with multiple Payments before and after Due Date and without Print Details in Calculate Interest on Arrears report for customer.
        Initialize();
        IntOnArrearsForCustomerWithMultiplePayment(false, StrSubstNo(DaysTxt, Format(LibraryRandom.RandIntInRange(7, 10))), 4);  // Using Random for No. of Days, False for Print Details, 4 for Partial Payment.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvFullyPaidWithMultiplePaymentPrintDetail()
    begin
        // Verify interest on Arrears with different interest rate, Fully paid with multiple Payments after Due Date and Print Details in Calculate Interest on Arrears report for customer.
        Initialize();
        IntOnArrearsForCustomerWithMultiplePayment(true, YearsTxt, 2);  // Using True for Print Details, 2 for Full Payment.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvFullyPaidWithMultiplePayment()
    begin
        // Verify interest on Arrears with different interest rate, Fully paid with multiple Payments after Due Date and without Print Details in Calculate Interest on Arrears report for customer.
        Initialize();
        IntOnArrearsForCustomerWithMultiplePayment(false, YearsTxt, 2);  // Using False for Print Details, 2 for Full Payment.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvFullyPaidBeforeAndAfterDueDatePrintDetail()
    begin
        // Verify interest on Arrears with different interest rate, Fully paid with multiple Payments before and after Due Date and Print Details in Calculate Interest on Arrears report for customer.
        Initialize();
        IntOnArrearsForCustomerWithMultiplePayment(true, StrSubstNo(DaysTxt, Format(LibraryRandom.RandIntInRange(7, 10))), 2);  // Using Random for No. of Days, True for Print Details, 2 for Full Payment.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvFullyPaidWithMultPmtBeforeAndAfterDueDate()
    begin
        // Verify interest on Arrears with different interest rate, Fully paid with multiple Payments before and after Due Date and without Print Details in Calculate Interest on Arrears report for customer.
        Initialize();
        IntOnArrearsForCustomerWithMultiplePayment(false, StrSubstNo(DaysTxt, Format(LibraryRandom.RandIntInRange(7, 10))), 2);  // Using Random for No. of Days, False for Print Details, 2 for Full Payment.
    end;

    local procedure IntOnArrearsForCustomerWithMultiplePayment(PrintDetails: Boolean; NoOfDays: Text[10]; PaymentPart: Integer)
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DiffInterestRate: Decimal;
        EndingDate: Date;
        InterestRate: Decimal;
        PrintType: Option Customer,Vendor;
    begin
        // Setup: Create Finance Charge Term with Interest on Arrears and post Sales invoice and Payment, post application.
        EndingDate := CalcDate(StrSubstNo(DateFormulaTxt, Format(LibraryRandom.RandIntInRange(4, 6))), WorkDate());  // Using Random for date formula.
        DiffInterestRate := LibraryRandom.RandInt(5);  // Using Random Integer for Interest Rate.
        InterestRate := SetupForCalcInterestOnArrears(FinanceChargeTerms, DiffInterestRate, CalcDate('<-1M>', EndingDate));
        CreateInvoiceAndMakePayment(
          GenJournalLine, GenJournalLine."Account Type"::Customer, CreateCustomer(
            FinanceChargeTerms.Code), NoOfDays, LibraryRandom.RandIntInRange(100, 500), PaymentPart);  // Using Random Integer for Amount
        PostCustomerApplication(GenJournalLine."Account No.");
        CreateAndPostGenJournalLine(
          GenJournalLine2, GenJournalLine2."Document Type"::Payment, GenJournalLine."Account Type", GenJournalLine."Account No.",
          CalcDate(Format(NoOfDays) + YearPlusTxt, WorkDate()), -GenJournalLine.Amount / PaymentPart);
        FindCustomerLedgerEntry(CustLedgerEntry, GenJournalLine."Account No.", CustLedgerEntry."Document Type"::Invoice);
        PostCustomerApplication(GenJournalLine."Account No.");
        EnqueueRequestPageHandlerValues(GenJournalLine."Account No.", PrintType::Customer, EndingDate, PrintDetails);  // Enqueue values of CalculateInterestOnArrearsRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Calculate Interest on Arrears");

        // Verify: Verify Interest rate, Days Difference and Remaining Amount in Calculate Interest on Arrears report for customer.
        CustLedgerEntry.CalcFields("Remaining Amount");
        VerifyCalcInterestOnArrearsReport(
          TotalDayDiffCustCap, RateLabelCustCap, DiffInterestRate, InterestRate, CalcDate('<-30D>', EndingDate), CustLedgerEntry."Due Date");   // 30 days for Days Difference.
        LibraryReportDataset.AssertElementWithValueExists(
          CustRemainingAmountCap, Round(CustLedgerEntry."Remaining Amount", LibraryERM.GetAmountRoundingPrecision(), '<'));  // Remaining Amount after payment.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvPartiallyPaidWithMultiplePaymentPrintDetail()
    begin
        // Verify interest on Arrears with different interest rate, Partially paid with multiple Payments after Due Date and Print Details in Calculate Interest on Arrears report for vendor.
        Initialize();
        IntOnArrearsForVendorWithMultiplePayment(true, YearsTxt, 4);  // Using True for Print Details, 4 for Partial Payment.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvPartiallyPaidWithMultiplePayment()
    begin
        // Verify interest on Arrears with different interest rate, Partially paid with multiple Payments after Due Date and without Print Details in Calculate Interest on Arrears report for vendor.
        Initialize();
        IntOnArrearsForVendorWithMultiplePayment(false, YearsTxt, 4);  // Using False for Print Details, 4 for Partial Payment.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvPartiallyPaidBeforeAndAfterDueDatePrintDetail()
    begin
        // Verify interest on Arrears with different interest rate, Partially paid with multiple Payments before and after Due Date and Print Details in Calculate Interest on Arrears report for vendor.
        Initialize();
        IntOnArrearsForVendorWithMultiplePayment(true, StrSubstNo(DaysTxt, Format(LibraryRandom.RandIntInRange(7, 10))), 4);  // Using Random for // Using Random Integer for No. of Days, True for Print Details, 4 for Partial Payment.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvPartiallyPaidWithMultPmtBeforeAndAfterDueDate()
    begin
        // Verify interest on Arrears with different interest rate, Partially paid with multiple Payments before and after Due Date and without Print Details in Calculate Interest on Arrears report for vendor.
        Initialize();
        IntOnArrearsForVendorWithMultiplePayment(false, StrSubstNo(DaysTxt, Format(LibraryRandom.RandIntInRange(7, 10))), 4);  // Using Random for No. of Days, False for Print Details, 4 for Partial Payment.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvFullyPaidWithMultiplePaymentPrintDetail()
    begin
        // Verify interest on Arrears with different interest rate, Fully paid with multiple Payments after Due Date and Print Details in Calculate Interest on Arrears report for vendor.
        Initialize();
        IntOnArrearsForVendorWithMultiplePayment(true, YearsTxt, 2);  // Using True for Print Details, 2 for Full Payment.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvFullyPaidWithMultiplePayment()
    begin
        // Verify interest on Arrears with different interest rate, Fully paid with multiple Payments after Due Date and without Print Details in Calculate Interest on Arrears report for vendor.
        Initialize();
        IntOnArrearsForVendorWithMultiplePayment(false, YearsTxt, 2);  // Using False for Print Details, 2 for Full Payment.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvFullyPaidBeforeAndAfterDueDatePrintDetail()
    begin
        // Verify interest on Arrears with different interest rate, Fully paid with multiple Payments before and after Due Date and Print Details in Calculate Interest on Arrears report for vendor.
        Initialize();
        IntOnArrearsForVendorWithMultiplePayment(true, StrSubstNo(DaysTxt, Format(LibraryRandom.RandIntInRange(7, 10))), 2);  // Using Random for No. of Days, True for Print Details, 2 for Full Payment.
    end;

    [Test]
    [HandlerFunctions('CalculateInterestOnArrearsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvFullyPaidWithMultPmtBeforeAndAfterDueDate()
    begin
        // Verify interest on Arrears with different interest rate, Fully paid with multiple Payments before and after Due Date and without Print Details in Calculate Interest on Arrears report for vendor.
        Initialize();
        IntOnArrearsForVendorWithMultiplePayment(false, StrSubstNo(DaysTxt, Format(LibraryRandom.RandIntInRange(7, 10))), 2);  // Using Random for No. of Days, False for Print Details, 2 for Full Payment.
    end;

    local procedure IntOnArrearsForVendorWithMultiplePayment(PrintDetails: Boolean; NoOfDays: Text[10]; PaymentPart: Integer)
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DiffInterestRate: Decimal;
        EndingDate: Date;
        InterestRate: Decimal;
        PrintType: Option Customer,Vendor;
    begin
        // Setup: Create Finance Charge Term with Interest on Arrears and post purchase invoice and Payment, post application.
        EndingDate := CalcDate(StrSubstNo(DateFormulaTxt, Format(LibraryRandom.RandIntInRange(4, 6))), WorkDate());  // Using Random for date formula.
        DiffInterestRate := LibraryRandom.RandInt(5);  // Using Random Integer for Interest Rate.
        InterestRate := SetupForCalcInterestOnArrears(FinanceChargeTerms, DiffInterestRate, CalcDate('<-1M>', EndingDate));
        CreateInvoiceAndMakePayment(
          GenJournalLine, GenJournalLine."Account Type"::Vendor, CreateVendor(
            FinanceChargeTerms.Code), NoOfDays, -LibraryRandom.RandIntInRange(100, 500), PaymentPart);  // Using Random Decimal for Amount
        PostVendorApplication(GenJournalLine."Account No.");
        CreateAndPostGenJournalLine(
          GenJournalLine2, GenJournalLine2."Document Type"::Payment, GenJournalLine."Account Type", GenJournalLine."Account No.",
          CalcDate(Format(NoOfDays) + YearPlusTxt, WorkDate()), -GenJournalLine.Amount / PaymentPart);
        FindVendorLedgerEntry(VendorLedgerEntry, GenJournalLine."Account No.", VendorLedgerEntry."Document Type"::Invoice);
        PostVendorApplication(GenJournalLine."Account No.");
        VendorLedgerEntry.CalcFields("Remaining Amount");
        EnqueueRequestPageHandlerValues(GenJournalLine."Account No.", PrintType::Vendor, EndingDate, PrintDetails);  // Enqueue values of CalculateInterestOnArrearsRequestPageHandler.

        // Exercise.
        REPORT.Run(REPORT::"Calculate Interest on Arrears");

        // Verify: Verify Interest rate, Days Difference and Remaining Amount in Calculate Interest on Arrears report for vendor.
        VerifyCalcInterestOnArrearsReport(
          TotalDayDiffVendCap, RateLabelVendCap, DiffInterestRate, InterestRate, CalcDate('<-30D>', EndingDate), VendorLedgerEntry."Due Date");  // 30 days for Days Difference.
        LibraryReportDataset.AssertElementWithValueExists(
          VendRemainingAmountCap, Round(VendorLedgerEntry."Remaining Amount", LibraryERM.GetAmountRoundingPrecision(), '<'));  // Remaining Amount after partial payment.
    end;

    [Test]
    [HandlerFunctions('SuggestFinChargeMemoLinesRequestPageHandler,IssueFinanceChargeMemosRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IssueFinanceChargeMemoForIntAndAdditionalFee()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerNo: Code[20];
        FinanceChargeMemoNo: Code[20];
    begin
        // Verify Customer and General ledger entries after issue Finance Charge Memo.
        // Setup: Create Reminder & Finance charge Term, post sales order & invoice, create Finance Charge Memo.
        Initialize();
        CustomerNo := CreateAndPostSalesOrderAndInvoice();
        FinanceChargeMemoNo := CreateFinanceChargeMemo(CustomerNo);
        LibraryVariableStorage.Enqueue(FinanceChargeMemoNo);  // Enqueue value for IssueFinanceChargeMemosRequestPageHandler.
        Commit();  // Commit required for Run report.

        // Exercise: Suggest and Issue Finance charge Memo.
        SuggestAndIssueFinanceChargeMemoLines(FinanceChargeMemoNo);

        // Verify: Verify Finance Charge Memo ledger entry.
        VerifyGLEntry(CustomerNo, CustLedgerEntry."Document Type"::"Finance Charge Memo");
    end;

    [Test]
    [HandlerFunctions('SuggestReminderLinesRequestPageHandler,IssueReminderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure IssueReminderForIntAndAdditionalFee()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerNo: Code[20];
        ReminderNo: Code[20];
    begin
        // Verify Customer and General ledger entries after issue Reminder.
        // Setup: Create Reminder & Finance charge Term, post sales order & invoice, create Reminder.
        Initialize();
        CustomerNo := CreateAndPostSalesOrderAndInvoice();
        ReminderNo := CreateReminder(CustomerNo);
        LibraryVariableStorage.Enqueue(ReminderNo);  // Enqueue value for IssueReminderRequestPageHandler.
        Commit();  // Commit required for Run report.

        // Exercise: Suggest and Issue Reminder.
        SuggestAndIssueReminderLines(ReminderNo);

        // Verify: Verify Reminder ledger entry.
        VerifyGLEntry(CustomerNo, CustLedgerEntry."Document Type"::Reminder);
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreateAndPostGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; PostingDate: Date; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreateGeneralJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("External Document No.", GenJournalLine."Document No.");
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Bal. Account No.", CreateGLAccount());
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateAndPostSalesDocument(DocumentType: Enum "Gen. Journal Document Type"; CustomerNo: Code[20])
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandInt(10));  // Using Random for Quantity.
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(50, 2));
        SalesLine.Modify(true);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostSalesOrderAndInvoice() CustomerNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CustomerNo := CreateAndUpdateCustomer(CreateAndUpdateFinanceChargeMemo(), CreateReminderTermsWithReminderLevel());
        CreateAndPostSalesDocument(SalesHeader."Document Type"::Order, CustomerNo);
        CreateAndPostSalesDocument(SalesHeader."Document Type"::Invoice, CustomerNo);
    end;

    local procedure CreateAndUpdateFinanceChargeMemo(): Code[10]
    var
        FinanceChargeTerms: Record "Finance Charge Terms";
        GracePeriod: DateFormula;
        DueDateCalc: DateFormula;
    begin
        CreateFinanceChargeTerm(FinanceChargeTerms);
        FinanceChargeTerms.Validate("Interest Rate", LibraryRandom.RandInt(10));
        FinanceChargeTerms.Validate("Interest Period (Days)", LibraryRandom.RandIntInRange(25, 30));
        FinanceChargeTerms.Validate("Minimum Amount (LCY)", LibraryRandom.RandDecInRange(20, 40, 2));
        FinanceChargeTerms.Validate("Additional Fee (LCY)", FinanceChargeTerms."Minimum Amount (LCY)");
        Evaluate(GracePeriod, StrSubstNo(DaysTxt, LibraryRandom.RandIntInRange(3, 6)));
        FinanceChargeTerms.Validate("Grace Period", GracePeriod);
        Evaluate(DueDateCalc, '<1M>');
        FinanceChargeTerms.Validate("Due Date Calculation", DueDateCalc);
        FinanceChargeTerms.Validate("Post Interest", true);
        FinanceChargeTerms.Validate("Post Additional Fee", true);
        FinanceChargeTerms.Modify(true);
        exit(FinanceChargeTerms.Code);
    end;

    local procedure CreateAndUpdateCustomer(FinChargeTermsCode: Code[10]; ReminderTermsCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        Customer.Get(CreateCustomer(''));  // Using blank for Interest on Arrear Code.
        Customer.Validate("Fin. Charge Terms Code", FinChargeTermsCode);
        Customer.Validate("Reminder Terms Code", ReminderTermsCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateAndUpdateInterestOnArrears("Code": Code[10]; InterestRate: Decimal; StartingDate: Date): Decimal
    var
        InterestOnArrears: Record "Interest on Arrears";
        InterestOnArrears2: Record "Interest on Arrears";
    begin
        LibraryITLocalization.CreateInterestOnArrears(InterestOnArrears, Code, CalcDate('<-1D>', WorkDate()));
        UpdateInterestOnArrears(InterestOnArrears, LibraryRandom.RandIntInRange(5, 10));
        LibraryITLocalization.CreateInterestOnArrears(InterestOnArrears2, Code, StartingDate);
        UpdateInterestOnArrears(InterestOnArrears2, InterestOnArrears."Interest Rate" + InterestRate);
        exit(InterestOnArrears."Interest Rate");
    end;

    local procedure CreateCustomer(IntOnArrearsCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Int. on Arrears Code", IntOnArrearsCode);
        Customer.Validate("Payment Terms Code", FindPaymentTerm());
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateFinanceChargeMemo(CustomerNo: Code[20]): Code[20]
    var
        FinanceChargeMemoHeader: Record "Finance Charge Memo Header";
    begin
        LibraryERM.CreateFinanceChargeMemoHeader(FinanceChargeMemoHeader, CustomerNo);
        FinanceChargeMemoHeader.Validate("Posting Date", WorkDate());
        FinanceChargeMemoHeader.Validate("Document Date", CalcDate('<1Y>', WorkDate()));
        FinanceChargeMemoHeader.Modify(true);
        exit(FinanceChargeMemoHeader."No.")
    end;

    local procedure CreateFinanceChargeTerm(var FinanceChargeTerms: Record "Finance Charge Terms")
    begin
        LibraryERM.CreateFinanceChargeTerms(FinanceChargeTerms);
        FinanceChargeTerms.Validate("Interest Period (Days)", CalcDate('<CY>', WorkDate()) - CalcDate('<-CY>', WorkDate())); // Calculate No. of Days.
        FinanceChargeTerms.Validate("Post Additional Fee", false);
        FinanceChargeTerms.Modify(true);
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        exit(GLAccount."No.");
    end;

    local procedure CreateInvoiceAndMakePayment(var GenJournalLine: Record "Gen. Journal Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; NoOfDays: Text[10]; Amount: Decimal; PaymentPart: Integer)
    var
        GenJournalLine2: Record "Gen. Journal Line";
    begin
        CreateAndPostGenJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, AccountType, AccountNo, WorkDate(), Amount);
        CreateAndPostGenJournalLine(
          GenJournalLine2, GenJournalLine2."Document Type"::Payment, AccountType, AccountNo, CalcDate(Format(NoOfDays), WorkDate()),
          -Amount / PaymentPart);
    end;

    local procedure CreateReminder(CustomerNo: Code[20]): Code[20]
    var
        ReminderHeader: Record "Reminder Header";
    begin
        LibraryERM.CreateReminderHeader(ReminderHeader);
        ReminderHeader.Validate("Customer No.", CustomerNo);
        ReminderHeader.Validate("Posting Date", WorkDate());
        ReminderHeader.Validate("Document Date", CalcDate('<1Y>', WorkDate()));
        ReminderHeader.Modify(true);
        exit(ReminderHeader."No.");
    end;

    local procedure CreateReminderTermsWithReminderLevel(): Code[10]
    var
        ReminderLevel: Record "Reminder Level";
        ReminderTerms: Record "Reminder Terms";
        GracePeriod: DateFormula;
    begin
        LibraryERM.CreateReminderTerms(ReminderTerms);
        ReminderTerms.Validate("Post Interest", true);
        ReminderTerms.Validate("Post Additional Fee", true);
        ReminderTerms.Modify(true);
        LibraryERM.CreateReminderLevel(ReminderLevel, ReminderTerms.Code);
        Evaluate(GracePeriod, StrSubstNo(DaysTxt, LibraryRandom.RandIntInRange(5, 8)));
        ReminderLevel.Validate("Grace Period", GracePeriod);
        ReminderLevel.Validate("Additional Fee (LCY)", LibraryRandom.RandDecInRange(10, 20, 2));
        ReminderLevel.Modify(true);
        exit(ReminderTerms.Code);
    end;

    local procedure CreateVendor(IntOnArrearsCode: Code[10]): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Int. on Arrears Code", IntOnArrearsCode);
        Vendor.Validate("Payment Terms Code", FindPaymentTerm());
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure EnqueueRequestPageHandlerValues(AccountNo: Code[20]; PrintType: Option; InterestCalculationAsOf: Date; PrintDetails: Boolean)
    begin
        // Enqueue values of CalculateInterestOnArrearsRequestPageHandler.
        LibraryVariableStorage.Enqueue(AccountNo);
        LibraryVariableStorage.Enqueue(PrintType);
        LibraryVariableStorage.Enqueue(InterestCalculationAsOf);
        LibraryVariableStorage.Enqueue(PrintDetails);
    end;

    local procedure FindCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Type", DocumentType);
        CustLedgerEntry.SetRange(Open, true);
        CustLedgerEntry.FindFirst();
    end;

    local procedure FindPaymentTerm(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.CalcFields("Payment Nos.");
        PaymentTerms.SetFilter("Payment Nos.", '<>%1', 1);  // Required payment term at least in 2 Payment Nos.
        PaymentTerms.FindFirst();
        exit(PaymentTerms.Code);
    end;

    local procedure FindVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    begin
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document Type", DocumentType);
        VendorLedgerEntry.SetRange(Open, true);
        VendorLedgerEntry.FindFirst();
    end;

    local procedure GetInterestRate(InterestRate: Integer; Rate: Text[20]): Text
    begin
        if InterestRate = 0 then
            exit(Rate);
        exit(VariableRateTxt);
    end;

    local procedure PostCustomerApplication(CustomerNo: Code[20])
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
    begin
        FindCustomerLedgerEntry(CustLedgerEntry, CustomerNo, CustLedgerEntry."Document Type"::Payment);
        CustLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, CustLedgerEntry."Remaining Amount");
        FindCustomerLedgerEntry(CustLedgerEntry2, CustomerNo, CustLedgerEntry2."Document Type"::Invoice);
        CustLedgerEntry2.CalcFields("Remaining Amount");
        CustLedgerEntry2.Validate("Amount to Apply", CustLedgerEntry2."Remaining Amount");
        CustLedgerEntry2.Modify(true);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry2);
    end;

    local procedure PostVendorApplication(VendorNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorLedgerEntry2: Record "Vendor Ledger Entry";
    begin
        FindVendorLedgerEntry(VendorLedgerEntry, VendorNo, VendorLedgerEntry."Document Type"::Payment);
        VendorLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyVendorEntry(VendorLedgerEntry, VendorLedgerEntry."Remaining Amount");
        FindVendorLedgerEntry(VendorLedgerEntry2, VendorNo, VendorLedgerEntry2."Document Type"::Invoice);
        VendorLedgerEntry2.Validate("Amount to Apply", VendorLedgerEntry2."Remaining Amount");
        VendorLedgerEntry2.Modify(true);
        LibraryERM.SetAppliestoIdVendor(VendorLedgerEntry2);
        LibraryERM.PostVendLedgerApplication(VendorLedgerEntry2);
    end;

    local procedure SetupForCalcInterestOnArrears(var FinanceChargeTerms: Record "Finance Charge Terms"; InterestRate: Decimal; StartingDate: Date): Decimal
    begin
        CreateFinanceChargeTerm(FinanceChargeTerms);
        exit(CreateAndUpdateInterestOnArrears(FinanceChargeTerms.Code, InterestRate, StartingDate));
    end;

    local procedure SuggestAndIssueFinanceChargeMemoLines(No: Code[20])
    var
        FinanceChargeMemo: TestPage "Finance Charge Memo";
    begin
        FinanceChargeMemo.OpenEdit();
        FinanceChargeMemo.FILTER.SetFilter("No.", No);
        FinanceChargeMemo.SuggestFinChargeMemoLines.Invoke();  // Using SuggestFinChargeMemoLinesRequestPageHandler.
        FinanceChargeMemo.Issue.Invoke();
    end;

    local procedure SuggestAndIssueReminderLines(No: Code[20])
    var
        Reminder: TestPage Reminder;
    begin
        Reminder.OpenEdit();
        Reminder.FILTER.SetFilter("No.", No);
        Reminder.SuggestReminderLines.Invoke();  // Using SuggestReminderLinesRequestPageHandler.
        Reminder.Issue.Invoke();
    end;

    local procedure UpdateInterestOnArrears(var InterestOnArrears: Record "Interest on Arrears"; InterestRate: Decimal)
    begin
        InterestOnArrears.Validate("Interest Rate", InterestRate);
        InterestOnArrears.Modify(true);
    end;

    local procedure VerifyCalcInterestOnArrearsReport(DaysDiffCap: Text[50]; RateLabelCap: Text[50]; DiffInterestRate: Decimal; InterestRate: Decimal; InterestCalculationAsOf: Date; DueDate: Date)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists(DaysDiffCap, InterestCalculationAsOf - DueDate);
        LibraryReportDataset.AssertElementWithValueExists(RateLabelCap, GetInterestRate(DiffInterestRate, Format(InterestRate)));
    end;

    local procedure VerifyGLEntry(SourceNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        GLEntry: Record "G/L Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        FindCustomerLedgerEntry(CustLedgerEntry, SourceNo, DocumentType);
        CustLedgerEntry.CalcFields(Amount);
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Source No.", SourceNo);
        GLEntry.SetFilter("Debit Amount", '<>0');
        GLEntry.FindFirst();
        GLEntry.TestField("Debit Amount", CustLedgerEntry.Amount);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculateInterestOnArrearsRequestPageHandler(var CalculateInterestOnArrears: TestRequestPage "Calculate Interest on Arrears")
    var
        CustomerVendor: Variant;
        No: Variant;
        InterestCalculationAsOf: Variant;
        PrintDetails: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        LibraryVariableStorage.Dequeue(CustomerVendor);
        LibraryVariableStorage.Dequeue(InterestCalculationAsOf);
        LibraryVariableStorage.Dequeue(PrintDetails);
        CalculateInterestOnArrears.Customer.SetFilter("No.", No);
        CalculateInterestOnArrears.Vendor.SetFilter("No.", No);
        CalculateInterestOnArrears.CustomerVendor.SetValue(CustomerVendor);
        CalculateInterestOnArrears.InterestCalculationAsOf.SetValue(InterestCalculationAsOf);
        CalculateInterestOnArrears.PrintDetails.SetValue(PrintDetails);
        CalculateInterestOnArrears.FromPostingDate.SetValue(WorkDate());
        CalculateInterestOnArrears.ToPostingDate.SetValue(WorkDate());
        CalculateInterestOnArrears.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IssueFinanceChargeMemosRequestPageHandler(var IssueFinanceChargeMemos: TestRequestPage "Issue Finance Charge Memos")
    begin
        IssueFinanceChargeMemos.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure IssueReminderRequestPageHandler(var IssueReminders: TestRequestPage "Issue Reminders")
    begin
        IssueReminders.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestFinChargeMemoLinesRequestPageHandler(var SuggestFinChargeMemoLines: TestRequestPage "Suggest Fin. Charge Memo Lines")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        SuggestFinChargeMemoLines."Finance Charge Memo Header".SetFilter("No.", No);
        SuggestFinChargeMemoLines.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestReminderLinesRequestPageHandler(var SuggestReminderLines: TestRequestPage "Suggest Reminder Lines")
    var
        No: Variant;
    begin
        LibraryVariableStorage.Dequeue(No);
        SuggestReminderLines."Reminder Header".SetFilter("No.", No);
        SuggestReminderLines.OK().Invoke();
    end;
}

