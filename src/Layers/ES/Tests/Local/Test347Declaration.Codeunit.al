codeunit 147316 "Test 347 Declaration"
{
    // // [FEATURE] [Make 347 Declaration] [VAT Cash Regime]
    // 
    // // Acceptance Criteria
    // // [Prerequisites] The VATEntry."VAT Cash Regime" is filled correctly at posting time
    // 
    // // The first part of the scenarios (when VATEntry."VAT Cash Regime" has to be filled in correctly at posting)
    // // is common with the 340 hence they will not be repeated here. Those are described in COD147315.
    // 
    // // 1. The report 347 contains correct values related to "VAT Cash Regime" in the following fields
    // // - VAT Cash Regime flag contains an X
    // // - The amounts are filled in correctly
    // 
    // // 2. Annual amount including VAT of operations under Cash Accounting Criteria
    // 
    // // Two lines for the same peer are summed up
    // // Two lines for different peers are not summed up
    // // Two lines for the same peer in different years are not summed up
    // 
    // // 3. Reverse charge status is exported to the file
    // 
    // // Multi-line Reverse charge
    // // Multi-line combined Reverse Charge and Normal
    // // VAT other than Reverse Charge

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Test347DeclarationParameter: Record "Test 347 Declaration Parameter";
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        Library340347Declaration: Codeunit "Library - 340 347 Declaration";
        Library347Declaration: Codeunit "Library - 347 Declaration";
        LibraryTextFileValidation: Codeunit "Library - Text File Validation";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        IsInitialized: Boolean;
        AnnualVATCashAmountErr: Label 'Incorrect Annual VAT Cash Amount';
        AmountCustVendErr: Label 'Incorrect Amount for Customer/Vendor';
        VATCashRegimeFlagErr: Label 'VAT Cash Regime flag should be ''''X''''';
        VATCashRegimeNoFlagErr: Label 'VAT Cash Regime flag should be empty';
        IncorrectQuarterAmountErr: Label 'Incorrect Quarter Amount';
        IncorrectVATCashRegimeFlagErr: Label 'Incorrect value for the VAT Cash Regime flag';
        IncorrectReverseChargeFlagErr: Label 'Incorrect value for the Reverse Charge flag';
        LineShouldNotBeEmptyErr: Label 'Line should not be empty';

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure VATCashRegimeNormalVATAmounts()
    var
        CustomerNo: Code[20];
        FileName: Text[1024];
        InvoiceAmount: Decimal;
    begin
        Initialize();
        // VATEntry."VAT Cash Regime" = FALSE values are propagated correctly to 347 lines
        // [GIVEN] VAT Entry Line X Unrealized = FALSE
        // [GIVEN] VAT Entry Line X has VAT Cash Regime = FALSE
        // [GIVEN] VATEntry.Document Type = Invoice and VATEntry.Type = SALE
        InvoiceAmount := CreateAndPostSalesInvoiceWithVATCashRegime(CustomerNo, false, false);

        // [WHEN] The user runs "Make 347 Declaration report"
        FileName := RunMake347DeclarationReport();

        // [THEN] In the generated file, the amount is filled in positions 284-299 is zero.
        ValidateFileHasExpectedVATCashRegimeAmount(
          FileName, CustomerNo, 0, InvoiceAmount);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure VATCashRegimeNormalVATFlag()
    var
        CustomerNo: Code[20];
        FileName: Text[1024];
    begin
        Initialize();
        // VATEntry."VAT Cash Regime" = FALSE values are propagated correctly to 347 lines
        // [GIVEN] VAT Entry Line X Unrealized = FALSE
        // [GIVEN] VAT Entry Line X has VAT Cash Regime = FALSE
        // [GIVEN] VATEntry.Document Type = Invoice and VATEntry.Type = SALE
        CreateAndPostSalesInvoiceWithVATCashRegime(CustomerNo, false, false);

        // [WHEN] The user runs "Make 347 Declaration report"
        FileName := RunMake347DeclarationReport();

        // [THEN] In the generated file, the record regarding "Seller Company" includes a blank in 281 field
        ValidateFileHasExpectedVATCashRegimeFlag(
          FileName, CustomerNo, ' ', VATCashRegimeNoFlagErr);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure VATCashRegimeUnrealizedVATAmountsSales()
    var
        CustomerNo: Code[20];
        FileName: Text[1024];
        InvoiceAmount: Decimal;
    begin
        Initialize();
        // VATEntry."VAT Cash Regime" = FALSE values are propagated correctly to 347 lines
        // [GIVEN] VAT Entry Line X Unrealized = TRUE
        // [GIVEN] VAT Entry Line X has VAT Cash Regime = FALSE
        // [GIVEN] VATEntry.Document Type = Invoice and VATEntry.Type = SALE
        InvoiceAmount := CreateAndPostSalesInvoiceWithVATCashRegime(CustomerNo, true, false);

        // [WHEN] The user runs "Make 347 Declaration report"
        FileName := RunMake347DeclarationReport();

        // [THEN] In the generated file, the amount is filled in positions 284-299 is zero.
        ValidateFileHasExpectedVATCashRegimeAmount(
          FileName, CustomerNo, 0, InvoiceAmount);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure VATCAshRegimeUnrealizedVATCashFlagSales()
    var
        CustomerNo: Code[20];
        FileName: Text[1024];
    begin
        Initialize();
        // VATEntry."VAT Cash Regime" = FALSE values are propagated correctly to 347 lines
        // [GIVEN] VAT Entry Line X Unrealized = TRUE
        // [GIVEN] VAT Entry Line X has VAT Cash Regime = FALSE
        // [GIVEN] VATEntry.Document Type = Invoice and VATEntry.Type = SALE
        CreateAndPostSalesInvoiceWithVATCashRegime(CustomerNo, true, false);

        // [WHEN] The user runs "Make 347 Declaration report"
        FileName := RunMake347DeclarationReport();

        // [THEN] In the generated file, the record regarding "Seller Company" includes a blank in 281 field
        ValidateFileHasExpectedVATCashRegimeFlag(
          FileName, CustomerNo, ' ', VATCashRegimeNoFlagErr);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure VATCashRegimeUnrealizedVATAmountsPurchase()
    var
        VendorNo: Code[20];
        FileName: Text[1024];
        InvoiceAmount: Decimal;
    begin
        Initialize();
        // VATEntry."VAT Cash Regime" = FALSE values are propagated correctly to 347 lines
        // [GIVEN] VAT Entry Line X Unrealized = TRUE
        // [GIVEN] VAT Entry Line X has VAT Cash Regime = FALSE
        // [GIVEN] VATEntry.Document Type = Invoice and VATEntry.Type = PURCHASE
        InvoiceAmount := CreateAndPostPurchaseInvoiceWithVATCashRegime(VendorNo, WorkDate(), true, false);

        // [WHEN] The user runs "Make 347 Declaration report"
        FileName := RunMake347DeclarationReport();

        // [THEN] In the generated file, the amount is filled in positions 284-299 is zero.
        ValidateFileHasExpectedVATCashRegimeAmount(
          FileName, VendorNo, 0, InvoiceAmount);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure VATCAshRegimeUnrealizedVATCashFlagPurchase()
    var
        VendorNo: Code[20];
        FileName: Text[1024];
    begin
        Initialize();
        // VATEntry."VAT Cash Regime" = FALSE values are propagated correctly to 347 lines
        // [GIVEN] VAT Entry Line X Unrealized = TRUE
        // [GIVEN] VAT Entry Line X has VAT Cash Regime = FALSE
        // [GIVEN] VATEntry.Document Type = Invoice and VATEntry.Type = PURCHASE
        CreateAndPostPurchaseInvoiceWithVATCashRegime(VendorNo, WorkDate(), true, false);

        // [WHEN] The user runs "Make 347 Declaration report"
        FileName := RunMake347DeclarationReport();

        // [THEN] In the generated file, the record regarding "Seller Company" includes a blank in 281 field
        ValidateFileHasExpectedVATCashRegimeFlag(
          FileName, VendorNo, ' ', VATCashRegimeNoFlagErr);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure VATCashRegimeFlagSales()
    var
        CustomerNo: Code[20];
        FileName: Text[1024];
    begin
        Initialize();
        // VATEntry."VAT Cash Regime" = TRUE values are propagated correctly to 347 lines
        // [GIVEN] VAT Entry Line X Unrealized = TRUE
        // [GIVEN] VAT Entry Line X has VAT Cash Regime = TRUE
        // [GIVEN] VATEntry.Document Type = Invoice and VATEntry.Type = SALE
        CreateAndPostSalesInvoiceWithVATCashRegime(CustomerNo, true, true);

        // [WHEN] The user runs "Make 347 Declaration report"
        FileName := RunMake347DeclarationReport();

        // [THEN] In the generated file, the record regarding "Seller Company" includes an X in 281 field
        ValidateFileHasExpectedVATCashRegimeFlag(FileName, CustomerNo, 'X', VATCashRegimeFlagErr);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure VATCashRegimeAmountsSalesNotPaid()
    var
        CustomerNo: Code[20];
        FileName: Text[1024];
        ExpectedVATCashAmount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 363492] AnnualAmount is not exported for not paid VAT Cash Sales Invoice
        Initialize();
        // VATEntry."VAT Cash Regime" = TRUE values are propagated correctly to 347 lines
        // [GIVEN] VAT Entry Line X Unrealized = TRUE
        // [GIVEN] VAT Entry Line X has VAT Cash Regime = TRUE
        // [GIVEN] VATEntry.Document Type = Invoice and VATEntry.Type = SALE
        ExpectedVATCashAmount := CreateAndPostSalesInvoiceWithVATCashRegime(CustomerNo, true, true);

        // [WHEN] The user runs "Make 347 Declaration report"
        FileName := RunMake347DeclarationReport();

        // [THEN] In the generated file, the sales amount is filled, per customer in positions 83-98
        // [THEN] In the generated file, the annual amount is filled with zero, per customer in positions 284-299
        ValidateFileHasExpectedVATCashRegimeAmount(
          FileName, CustomerNo, 0, ExpectedVATCashAmount);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure VATCashRegimeFlagPurchase()
    var
        VendorNo: Code[20];
        FileName: Text[1024];
    begin
        Initialize();
        // VATEntry."VAT Cash Regime" = TRUE values are propagated correctly to 347 lines
        // [GIVEN] VAT Entry Line X Unrealized = TRUE
        // [GIVEN] VAT Entry Line X has VAT Cash Regime = TRUE
        // [GIVEN] VATEntry.Document Type = Invoice and VATEntry.Type = PURCHASE
        CreateAndPostPurchaseInvoiceWithVATCashRegime(VendorNo, WorkDate(), true, true);

        // [WHEN] The user runs "Make 347 Declaration report"
        FileName := RunMake347DeclarationReport();

        // [THEN] In the generated file, the record regarding "Seller Company" includes an X in 281 field
        ValidateFileHasExpectedVATCashRegimeFlag(FileName, VendorNo, 'X', VATCashRegimeFlagErr);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure VATCashRegimeAmountsPurchaseNotPaid()
    var
        VendorNo: Code[20];
        FileName: Text[1024];
        ExpectedVATCashAmount: Decimal;
    begin
        // [FEATURE] [Purchases]
        // [SCENARIO 363492] AnnualAmount is not exported for not paid VAT Cash Purchase Invoice
        Initialize();
        // VATEntry."VAT Cash Regime" = TRUE values are propagated correctly to 347 lines
        // [GIVEN] VAT Entry Line X Unrealized = TRUE
        // [GIVEN] VAT Entry Line X has VAT Cash Regime = TRUE
        // [GIVEN] VATEntry.Document Type = Invoice and VATEntry.Type = PURCHASE
        ExpectedVATCashAmount := CreateAndPostPurchaseInvoiceWithVATCashRegime(VendorNo, WorkDate(), true, true);

        // [WHEN] The user runs "Make 347 Declaration report"
        FileName := RunMake347DeclarationReport();

        // [THEN] In the generated file, the purchase amount is filled, per vendor in positions 83-98
        // [THEN] In the generated file, the annual amount is filled with zero, per vendor in positions 284-299
        ValidateFileHasExpectedVATCashRegimeAmount(
          FileName, VendorNo, 0, ExpectedVATCashAmount);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure MultiLinesForSamePeerAreGrouped()
    var
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
        FileName: Text[1024];
        ExpectedVATCashAmount: Decimal;
    begin
        Initialize();
        // Two lines for the same peer are summed up
        // [GIVEN] VAT Entry Lines X, Y for the same peer with Unrealized = TRUE
        // [GIVEN] VAT Entry Lines X, Y have VAT Cash Regime = TRUE
        // [GIVEN] VATEntry.Type in [Sale,Purchase]
        ExpectedVATCashAmount := CreateAndPostSalesInvoiceDetailed(Customer, VATPostingSetup, WorkDate(), true, true);
        ExpectedVATCashAmount :=
          ExpectedVATCashAmount + CreateAndPostSalesInvoiceDetailed(Customer, VATPostingSetup, WorkDate(), true, true);

        // [WHEN] The user runs "Make 347 Declaration report"
        FileName := RunMake347DeclarationReport();

        // [THEN] In the generated file, annual amount is summed up
        ValidateFileHasLineForCustomer(FileName, Customer."No.");
        ValidateFileHasExpectedVATCashRegimeAmount(
          FileName, Customer."No.", 0, ExpectedVATCashAmount);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure MultiLinesForDifferentPeersAreNotGrouped()
    var
        Customer1: Record Customer;
        Customer2: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
        FileName: Text[1024];
        VATCashAmountCust1: Decimal;
        VATCashAmountCust2: Decimal;
    begin
        Initialize();
        // Two lines for different peers are not summed up
        // [GIVEN] VAT Entry Lines X, Y for different peers with Unrealized = TRUE
        // [GIVEN] VAT Entry Lines X, Y have VAT Cash Regime = TRUE
        // [GIVEN] VATEntry.Type in [Sale,Purchase]
        VATCashAmountCust1 := CreateAndPostSalesInvoiceDetailed(Customer1, VATPostingSetup, WorkDate(), true, true);
        VATCashAmountCust2 := CreateAndPostSalesInvoiceDetailed(Customer2, VATPostingSetup, WorkDate(), true, true);

        // [WHEN] The user runs "Make 347 Declaration report"
        FileName := RunMake347DeclarationReport();

        // [THEN] In the generated file, annual amount is split per customer
        ValidateFileHasLineForCustomer(FileName, Customer1."No.");
        ValidateFileHasLineForCustomer(FileName, Customer2."No.");

        ValidateFileHasExpectedVATCashRegimeAmount(
          FileName, Customer1."No.", 0, VATCashAmountCust1);
        ValidateFileHasExpectedVATCashRegimeAmount(
          FileName, Customer2."No.", 0, VATCashAmountCust2);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure MultiLinesInDifferentYearsAreNotGrouped()
    var
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
        FileName: Text[1024];
        VATCashAmountCurrentYear: Decimal;
    begin
        Initialize();
        // Two lines for the same peer in different years are not summed up
        // [GIVEN] VAT Entry Lines X, Y for the same peer with Unrealized = TRUE, the line dates are in different years
        // [GIVEN] VAT Entry Lines X, Y have VAT Cash Regime = TRUE
        // [GIVEN] VATEntry.Type in [Sale,Purchase]
        CreateAndPostSalesInvoiceDetailed(Customer, VATPostingSetup, CalcDate('<-1Y>', WorkDate()), true, true);
        VATCashAmountCurrentYear := CreateAndPostSalesInvoiceDetailed(Customer, VATPostingSetup, WorkDate(), true, true);

        // [WHEN] The user runs "Make 347 Declaration report" for one of the years
        FileName := RunMake347DeclarationReport();

        // [THEN] In the generated file, annual amount is only for the current line
        ValidateFileHasExpectedVATCashRegimeAmount(
          FileName, Customer."No.", 0, VATCashAmountCurrentYear);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure ReverseChargeMultiLine()
    var
        Customer1: Record Customer;
        Customer2: Record Customer;
        FileName: Text[1024];
    begin
        // [SCENARIO 264656] Blank value exports for Reverse Charge VAT Entry

        Initialize();
        // Multi-line Reverse charge
        // [GIVEN] VAT Entry Line X having "VAT Calculation Type" = Reverse Charge
        // [GIVEN] VAT Entry Line Y having "VAT Calculation Type" = Reverse Charge
        // [GIVEN] Lines X and Y come from the same document hence they are reported cumulated
        CreateAndPostSalesInvoiceReverseCharge(Customer1);
        CreateAndPostSalesInvoiceReverseCharge(Customer2);

        // [WHEN] The user runs "Make 347 Declaration report"
        FileName := RunMake347DeclarationReport();

        // [THEN] In the generated file, the record regarding "Seller Company" includes a blank value in field "Reverse Charge Operation" (282), for both lines
        ValidateFileHasExpectedReverseChargeFlag(FileName, Customer1."No.", ' ');
        ValidateFileHasExpectedReverseChargeFlag(FileName, Customer2."No.", ' ');
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure ReverseChargeMultiLineDifferentVATTypesDifferentCustomers()
    var
        Customer2: Record Customer;
        CustomerNo1: Code[20];
        FileName: Text[1024];
    begin
        // [SCENARIO 264656] Blank value exports with multiple VAT entries for different customer, one with Reverse Charge VAT Entry

        Initialize();
        // Multi-line Reverse charge
        // [GIVEN] VAT Entry Line X having "VAT Calculation Type" = Reverse Charge
        // [GIVEN] VAT Entry Line Y having "VAT Calculation Type" = Normal
        // [GIVEN] Lines X and Y come from the same document hence they are reported cumulated
        CreateAndPostSalesInvoiceWithVATCashRegime(CustomerNo1, false, false);
        CreateAndPostSalesInvoiceReverseCharge(Customer2);

        // [WHEN] The user runs "Make 347 Declaration report"
        FileName := RunMake347DeclarationReport();

        // [THEN] In the generated file, the record regarding "Seller Company" includes a value value in field "Reverse Charge Operation" (282), for both lines
        ValidateFileHasExpectedReverseChargeFlag(FileName, CustomerNo1, ' ');
        ValidateFileHasExpectedReverseChargeFlag(FileName, Customer2."No.", ' ');
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure ReverseChargeMultiLineDifferentVATTypesSameCustomer()
    var
        Customer: Record Customer;
        CustomerNo: Code[20];
        FileName: Text[1024];
    begin
        // [SCENARIO 264656] Blank value exports with multiple VAT entries for same customer, one with Reverse Charge VAT Entry

        Initialize();
        // Multi-line combined Reverse Charge and Normal
        // [GIVEN] VAT Entry Line X having "VAT Calculation Type" = Reverse Charge
        // [GIVEN] VAT Entry Line Y having "VAT Calculation Type" = Normal VAT
        // [GIVEN] Lines X and Y come from the same customer hence they are reported cumulated
        CreateAndPostSalesInvoiceWithVATCashRegime(CustomerNo, false, false);
        Customer.Get(CustomerNo);
        CreateAndPostSalesInvoiceReverseCharge(Customer);

        // [WHEN] The user runs "Make 347 Declaration report"
        FileName := RunMake347DeclarationReport();

        // [THEN] In the generated file, the record regarding "Seller Company" includes a blank value in field "Reverse Charge Operation" (282), for both lines
        ValidateFileHasExpectedReverseChargeFlag(FileName, CustomerNo, ' ');
        ValidateFileHasExpectedReverseChargeFlag(FileName, CustomerNo, ' ');
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure ReverseChargeNoFlag()
    var
        CustomerNo: Code[20];
        FileName: Text[1024];
    begin
        Initialize();
        // VAT other than Reverse Charge
        // [GIVEN] VAT Entry Line X having "VAT Calculation Type" = Normal VAT (or other than Reverse Charve)
        CreateAndPostSalesInvoiceWithVATCashRegime(CustomerNo, true, true);

        // [WHEN] The user runs "Make 347 Declaration report"
        FileName := RunMake347DeclarationReport();

        // [THEN] In the generated file, the record regarding "Seller Company" field "Reverse Charge Operation" (282) is ' '
        ValidateFileHasExpectedReverseChargeFlag(FileName, CustomerNo, ' ');
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure QuarterAmountForSalesVATCachInvoice()
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        CustomerNo: Code[20];
        FileName: Text[1024];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 363481] Quarter Amount for Sales Invoice in VAT Cash Regime shows zero
        Initialize();

        // [GIVEN] Sales Invoice with VAT Cash Regime
        CreateAndPostSalesInvoiceWithVATCashRegime(CustomerNo, true, true);
        SalesInvoiceHeader.SetRange("Bill-to Customer No.", CustomerNo);
        SalesInvoiceHeader.FindFirst();

        // [WHEN] The user runs "Make 347 Declaration report"
        FileName := RunMake347DeclarationReport();

        // [THEN] Quarter Amount is filled with zero
        ValidateFileQuarterAmount(FileName, CustomerNo, SalesInvoiceHeader."Posting Date", 0);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure QuarterAmountForPurchaseVATCachInvoice()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        VendorNo: Code[20];
        FileName: Text[1024];
    begin
        // [FEATURE] [Purchases]
        // [SCENARIO 363481] Quarter Amount for Purchase Invoice in VAT Cash Regime shows zero
        Initialize();

        // [GIVEN] Purchase Invoice with VAT Cash Regime
        CreateAndPostPurchaseInvoiceWithVATCashRegime(VendorNo, WorkDate(), true, true);
        PurchInvHeader.SetRange("Pay-to Vendor No.", VendorNo);
        PurchInvHeader.FindFirst();

        // [WHEN] The user runs "Make 347 Declaration report"
        FileName := RunMake347DeclarationReport();

        // [THEN] Quarter Amount is filled with zero
        ValidateFileQuarterAmount(FileName, VendorNo, PurchInvHeader."Posting Date", 0);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure AnnualAmountForSalesInvoiceInVATCashWithPaymentBothInReportingPeriod()
    var
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        FileName: Text[1024];
        InvoiceAmount: Decimal;
        PaidAmount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 363492] Annual Amount for Sales VAT Cash Invoice shows applied payment amount within reporting period
        Initialize();

        // [GIVEN] Sales Invoice inside reporting period with amount = "X"
        InvoiceAmount := CreateAndPostSalesInvoiceDetailed(Customer, VATPostingSetup, WorkDate(), true, true);

        // [GIVEN] Applied Payment Amount = "Y" less than Invoice Amount inside reporting period
        PaidAmount := Round(InvoiceAmount / LibraryRandom.RandIntInRange(2, 4));
        CreateAndPostPaymentJnlLine(
          GenJournalLine."Account Type"::Customer, Customer."No.", WorkDate(), -PaidAmount, GetSalesInvoiceNo(Customer."No."));

        // [GIVEN] Applied Payment Amount out of reporting period
        CreateAndPostPaymentJnlLine(
          GenJournalLine."Account Type"::Customer, Customer."No.", CalcDate('<1Y>', WorkDate()),
          -LibraryRandom.RandDec(100, 2), GetSalesInvoiceNo(Customer."No."));

        // [WHEN] The user runs "Make 347 Declaration report"
        FileName := RunMake347DeclarationReport();

        // [THEN] In the generated file, the sales amount = "X" in positions 83-98
        // [THEN] In the generated file, the annual amount = "Y" in positions 284-299
        ValidateFileHasExpectedVATCashRegimeAmount(
          FileName, Customer."No.", PaidAmount, InvoiceAmount);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure AnnualAmountForSalesInvoiceInVATCashWithOnlyPaymentInReportingPeriod()
    var
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
        GenJournalLine: Record "Gen. Journal Line";
        FileName: Text[1024];
        InvoiceAmount: Decimal;
        PaidAmount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 363492] Annual Amount for Sales VAT Cash Invoice out of period shows applied payment amount within reporting period
        Initialize();

        // [GIVEN] Sales Invoice out of reporting period with amount = "X"
        InvoiceAmount := CreateAndPostSalesInvoiceDetailed(Customer, VATPostingSetup, CalcDate('<-1Y>', WorkDate()), true, true);
        PaidAmount := Round(InvoiceAmount / LibraryRandom.RandIntInRange(2, 4));

        // [GIVEN] Applied Payment Amount = "Y" less than Invoice Amount inside reporting period
        CreateAndPostPaymentJnlLine(
          GenJournalLine."Account Type"::Customer, Customer."No.", WorkDate(), -PaidAmount, GetSalesInvoiceNo(Customer."No."));

        // [GIVEN] Applied Payment Amount out of reporting period
        CreateAndPostPaymentJnlLine(
          GenJournalLine."Account Type"::Customer, Customer."No.", CalcDate('<1Y>', WorkDate()),
          -LibraryRandom.RandDec(100, 2), GetSalesInvoiceNo(Customer."No."));

        // [WHEN] The user runs "Make 347 Declaration report"
        FileName := RunMake347DeclarationReport();

        // [THEN] In the generated file, the sales amount = "X" in positions 83-98
        // [THEN] In the generated file, the annual amount = "Y" in positions 284-299
        ValidateFileHasExpectedVATCashRegimeAmount(
          FileName, Customer."No.", PaidAmount, InvoiceAmount);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure AnnualAmountForPurchaseInvoiceInVATCashWithPaymentBothInReportingPeriod()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        FileName: Text[1024];
        InvoiceAmount: Decimal;
        PaidAmount: Decimal;
    begin
        // [FEATURE] [Purchases]
        // [SCENARIO 363492] Annual Amount for Purchase VAT Cash Invoice shows applied payment amount within reporting period
        Initialize();

        // [GIVEN] Purchase Invoice inside reporting period with amount = "X"
        InvoiceAmount := CreateAndPostPurchaseInvoiceWithVATCashRegime(VendorNo, WorkDate(), true, true);

        // [GIVEN] Applied Payment Amount = "Y" less than Invoice Amount inside reporting period
        PaidAmount := Round(InvoiceAmount / LibraryRandom.RandIntInRange(2, 4));
        CreateAndPostPaymentJnlLine(
          GenJournalLine."Account Type"::Vendor, VendorNo, WorkDate(), PaidAmount, GetPurchInvoiceNo(VendorNo));

        // [GIVEN] Applied Payment Amount out of reporting period
        CreateAndPostPaymentJnlLine(
          GenJournalLine."Account Type"::Vendor, VendorNo, CalcDate('<1Y>', WorkDate()),
          LibraryRandom.RandDec(100, 2), GetPurchInvoiceNo(VendorNo));

        // [WHEN] The user runs "Make 347 Declaration report"
        FileName := RunMake347DeclarationReport();

        // [THEN] In the generated file, the purchase amount = "X" in positions 83-98
        // [THEN] In the generated file, the annual amount = "Y" in positions 284-299
        ValidateFileHasExpectedVATCashRegimeAmount(
          FileName, VendorNo, PaidAmount, InvoiceAmount);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure AnnualAmountForPurchaseInvoiceInVATCashWithOnlyPaymentInReportingPeriod()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VendorNo: Code[20];
        FileName: Text[1024];
        InvoiceAmount: Decimal;
        PaidAmount: Decimal;
    begin
        // [FEATURE] [Purchases]
        // [SCENARIO 363492] Annual Amount for Purchase VAT Cash Invoice out of period shows applied payment amount within reporting period
        Initialize();

        // [GIVEN] Purchase Invoice inside reporting period with amount = "X"
        InvoiceAmount := CreateAndPostPurchaseInvoiceWithVATCashRegime(VendorNo, WorkDate(), true, true);

        // [GIVEN] Applied Payment Amount = "Y" less than Invoice Amount inside reporting period
        PaidAmount := Round(InvoiceAmount / LibraryRandom.RandIntInRange(2, 4));
        CreateAndPostPaymentJnlLine(
          GenJournalLine."Account Type"::Vendor, VendorNo, WorkDate(), PaidAmount, GetPurchInvoiceNo(VendorNo));

        // [GIVEN] Applied Payment Amount out of reporting period
        CreateAndPostPaymentJnlLine(
          GenJournalLine."Account Type"::Vendor, VendorNo, CalcDate('<1Y>', WorkDate()),
          LibraryRandom.RandDec(100, 2), GetPurchInvoiceNo(VendorNo));

        // [WHEN] The user runs "Make 347 Declaration report"
        FileName := RunMake347DeclarationReport();

        // [THEN] In the generated file, the purchase amount = "X" in positions 83-98
        // [THEN] In the generated file, the annual amount = "Y" in positions 284-299
        ValidateFileHasExpectedVATCashRegimeAmount(
          FileName, VendorNo, PaidAmount, InvoiceAmount);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure ExportPurchaseRevChargeAndVATCashInvoiceInSeparateLine()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        VendorNo: Code[20];
        FileName: Text[1024];
        NormalAmount: Decimal;
        VATCashAmount: Decimal;
        RevChargeAmount: Decimal;
    begin
        // [FEATURE] [Purchases]
        // [SCENARIO 363719] Reverse Charge VAT is exported in separate line from VAT Cash and Normal Purchase Invoices
        Initialize();

        // [GIVEN] Paid VAT Cash Purchase Invoice with amount = "C"
        VATCashAmount := CreateAndPostPurchaseInvoiceWithVATCashRegime(VendorNo, WorkDate(), true, true);
        CreateAndPostPaymentJnlLine(
          GenJournalLine."Account Type"::Vendor, VendorNo, WorkDate(), VATCashAmount, GetPurchInvoiceNo(VendorNo));
        Vendor.Get(VendorNo);

        // [GIVEN] Reverse Charge Purchase Invoice with amount = "R"
        RevChargeAmount := CreateAndPostPurchaseInvoiceReverseCharge(Vendor);

        // [GIVEN] Normal Purchase Invoice with amount = "N"
        NormalAmount := CreateAndPostPurchaseInvoiceSameVendor(Vendor, WorkDate(), false, false);

        // [WHEN] The user runs "Make 347 Declaration report"
        FileName := RunMake347DeclarationReport();

        // [THEN] In 1st line, the purchase amount = "N" + "C" in positions 83-98
        // [THEN] In 1st line, the annual amount = "C" in positions 284-299
        ValidateFileHasExpectedVATCashRegimeAmount(FileName, VendorNo, VATCashAmount, NormalAmount + VATCashAmount);
        // [THEN] In 1st line, flag for VAT Cash exists, flag for Reverse Charge VAT is empty
        ValidateFileHasExpectedVATCashRegimeFlag(FileName, VendorNo, 'X', VATCashRegimeFlagErr);
        ValidateFileHasExpectedReverseChargeFlag(FileName, VendorNo, ' ');
        // [THEN] In 1st line, Quarter Amount = "N"
        ValidateFileQuarterAmount(FileName, VendorNo, WorkDate(), NormalAmount);

        // [THEN] In 2nd line, the purchase amount = "R" in positions 83-98
        // [THEN] In 2nd line, the annual amount = 0 in positions 284-299
        // [THEN] In 2nd line, flag for VAT Cash is empty, flag for Reverse Charge VAT exists
        // [THEN] In 2nd line, Quarter Amount = RevChargeAmount "R"
        ValidateFileSecondLineForVendor(
          FileName, VendorNo, 0, RevChargeAmount, ' ', 'X', WorkDate(), RevChargeAmount);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure IgnoreOutPeriodNonCashRegimePurchaseInvoiceInPeriodPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
        VendorNo: Code[20];
        FileName: Text[1024];
        InvoiceAmount: Decimal;
        PaidAmount: Decimal;
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 363492] Out of Period Purchase Invoice and in period Payment without Cash Regime are not exported
        Initialize();

        // [GIVEN] Purchase Invoice without Cash Regime out of reporting period
        InvoiceAmount := CreateAndPostPurchaseInvoiceWithVATCashRegime(VendorNo, CalcDate('<-1Y>', WorkDate()), false, false);
        Vendor.Get(VendorNo);

        // [GIVEN] Fully Applied Payment to Purchase Invoice inside Reporting Period
        CreateAndPostPaymentJnlLine(
          GenJournalLine."Account Type"::Vendor, VendorNo, WorkDate(), InvoiceAmount, GetPurchInvoiceNo(VendorNo));

        // [GIVEN] Purchase Invoice with VAT Cash Regime inside reporting period with amount = "X"
        InvoiceAmount := CreateAndPostPurchaseInvoiceSameVendor(Vendor, WorkDate(), true, true);

        // [GIVEN] Applied Payment Amount = "Y" in reporting period
        PaidAmount := Round(InvoiceAmount / LibraryRandom.RandIntInRange(2, 4));
        CreateAndPostPaymentJnlLine(
          GenJournalLine."Account Type"::Vendor, VendorNo, WorkDate(), PaidAmount, GetPurchInvoiceNo(VendorNo));

        // [WHEN] Run report "Make 347 Declaration report"
        FileName := RunMake347DeclarationReport();

        // [THEN] In the generated file "X" amount is in positions 83-98, "Y" is in positions 284-299
        ValidateFileHasExpectedVATCashRegimeAmount(FileName, VendorNo, PaidAmount, InvoiceAmount);
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure IgnoreOutPeriodNonCashRegimeSalesInvoiceInPeriodPayment()
    var
        GenJournalLine: Record "Gen. Journal Line";
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
        FileName: Text[1024];
        InvoiceAmount: Decimal;
        PaidAmount: Decimal;
        OldGeneralLedgerSetupVATCashRegime: Boolean;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 363492] Out of Period Sales Invoice and in period Payment without Cash Regime are not exported
        Initialize();
        OldGeneralLedgerSetupVATCashRegime := SetGeneralLedgerSetupVATCashRegime(false);
        // [GIVEN] Sales Invoice without Cash Regime out of reporting period
        InvoiceAmount := CreateAndPostSalesInvoiceDetailed(Customer, VATPostingSetup, CalcDate('<-1Y>', WorkDate()), false, false);

        // [GIVEN] Fully Applied Payment to Sales Invoice Amount inside reporting period
        CreateAndPostPaymentJnlLine(
          GenJournalLine."Account Type"::Customer, Customer."No.", WorkDate(), -InvoiceAmount, GetSalesInvoiceNo(Customer."No."));

        // [GIVEN] Sales Invoice with VAT Cash Regime inside reporting period with amount = "X"
        Library340347Declaration.CreateVATPostingSetup(VATPostingSetup, true, true);
        Customer."VAT Bus. Posting Group" := VATPostingSetup."VAT Bus. Posting Group";
        Customer.Modify(true);
        Library340347Declaration.CreateAndPostSalesInvoice(VATPostingSetup, Customer."No.", WorkDate(), InvoiceAmount);

        // [GIVEN] Applied Payment Amount = "Y" in reporting period
        PaidAmount := Round(InvoiceAmount / LibraryRandom.RandIntInRange(2, 4));
        CreateAndPostPaymentJnlLine(
          GenJournalLine."Account Type"::Customer, Customer."No.", WorkDate(), -PaidAmount, GetSalesInvoiceNo(Customer."No."));

        // [WHEN] Run report "Make 347 Declaration report"
        FileName := RunMake347DeclarationReport();

        // [THEN] In the generated file "X" amount is in positions 83-98, "Y" is in positions 284-299
        ValidateFileHasExpectedVATCashRegimeAmount(FileName, Customer."No.", PaidAmount, InvoiceAmount);
        SetGeneralLedgerSetupVATCashRegime(OldGeneralLedgerSetupVATCashRegime);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunFormatTextNameOnLongCustomerName()
    var
        Customer: Record Customer;
        Make347Declaration: Report "Make 347 Declaration";
        FormattedName: Text[100];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 328188] Run FormatTextName function of "Make 347 Declaration" report on long Customer Name.

        // [GIVEN] Customer Name of length 100.
        Customer.Name := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Customer.Name), 0), 1, MaxStrLen(Customer.Name));

        // [WHEN] Run FormatTextName function of "Make 347 Declaration" report.
        FormattedName := Make347Declaration.FormatTextName(Customer.Name);

        // [THEN] Fuction runs without errors.
        Customer.TestField(Name, FormattedName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunFormatTextNameOnLongVendorName()
    var
        Vendor: Record Vendor;
        Make347Declaration: Report "Make 347 Declaration";
        FormattedName: Text[100];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 328188] Run FormatTextName function of "Make 347 Declaration" report on long Vendor Name.

        // [GIVEN] Vendor Name of length 100.
        Vendor.Name := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(Vendor.Name), 0), 1, MaxStrLen(Vendor.Name));

        // [WHEN] Run FormatTextName function of "Make 347 Declaration" report.
        FormattedName := Make347Declaration.FormatTextName(Vendor.Name);

        // [THEN] Fuction runs without errors.
        Vendor.TestField(Name, FormattedName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunFormatTextNameOnLongComanyName()
    var
        CompanyInfo: Record "Company Information";
        Make347Declaration: Report "Make 347 Declaration";
        FormattedName: Text[100];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 328188] Run FormatTextName function of "Make 347 Declaration" report on long Company Name.

        // [GIVEN] Company Name of length 100.
        CompanyInfo.Name :=
          CopyStr(LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(CompanyInfo.Name), 0), 1, MaxStrLen(CompanyInfo.Name));

        // [WHEN] Run FormatTextName function of "Make 347 Declaration" report.
        FormattedName := Make347Declaration.FormatTextName(CompanyInfo.Name);

        // [THEN] Fuction runs without errors.
        CompanyInfo.TestField(Name, FormattedName);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatTextNameClearDigits();
    var
        Make347Declaration: Report "Make 347 Declaration";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 423222] "Make 347 Declaration".FormatTextName(...) must replace digits to spaces if ClearNumerico = true

        Assert.AreEqual('   ', Make347Declaration.FormatTextName('123', true), 'Wrong formatted string.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FormatTextNameNotClearDigits();
    var
        Make347Declaration: Report "Make 347 Declaration";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 423222] "Make 347 Declaration".FormatTextName(...) must not replace digits to spaces if ClearNumerico = false

        Assert.AreEqual('123', Make347Declaration.FormatTextName('123', false), 'Wrong formatted string.');
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    [Scope('OnPrem')]
    procedure ExcludeCountryCodeFromCompanyVATRegNo()
    var
        CompanyInformation: Record "Company Information";
        CustomerNo: Code[20];
        FileName: Text[1024];
        Line: Text;
        VATRegNo: Code[10];
    begin
        // [SCENARIO 433410] VAT Registration no. of the company information is exported to the 347 declaration without the country code

        Initialize();

        // [GIVEN] "Country Code" is "ES", "VAT Registration No." is "ES123456789" in the Company Information
        VATRegNo := '123456789';
        CompanyInformation.Get();
        CompanyInformation."VAT Registration No." := CompanyInformation."Country/Region Code" + VATRegNo;
        CompanyInformation.Modify();

        // [GIVEN] Posted sales invoice
        CreateAndPostSalesInvoiceWithVATCashRegime(CustomerNo, false, false);

        // [WHEN] Run "Make 347 Declaration report"
        FileName := RunMake347DeclarationReport();

        // [THEN] VAT registration no. is "123456789" in the generated file
        Line := ReadLineIn347ReportFile(FileName, CustomerNo);
        Assert.AreEqual(VATRegNo, CopyStr(Line, 9, 9), '');
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    procedure SecondLineBeginningInDeclarationFile()
    var
        CustomerNo: Code[20];
        FileName: Text[1024];
        Line: Text;
    begin
        // [SCENARIO 462453] Second line of Make 347 Declaration file is not cut in the beginning.
        Initialize();
        CreateAndPostSalesInvoiceWithVATCashRegime(CustomerNo, false, false);

        // [WHEN] Run Make 347 Declaration report.
        FileName := RunMake347DeclarationReport();

        // [THEN] Second line of Make 347 Declaration file is not cut in the beginning.
        Line := LibraryTextFileValidation.ReadLine(FileName, 2);
        Assert.AreEqual('2347', CopyStr(Line, 1, 4), 'The second line must start from 2347');
    end;

    [Test]
    [HandlerFunctions('Make347DeclarationReportHandler')]
    procedure CashAmountForSalesDocumentWhenPaymentAndRefund()
    var
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
        InvoiceNo: Code[20];
        CrMemoNo: Code[20];
        PaymentBalAccNo: Code[20];
        RefundBalAccNo: Code[20];
        FileName: Text[1024];
        Line: Text[500];
        InvoiceAmount: Decimal;
        CrMemoAmount: Decimal;
        TotalAmount: Decimal;
        CashAmount: Decimal;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 497540] Total and cash amount for paid Sales Invoice and refunded Sales Credit Memo.
        Initialize();

        // [GIVEN] VAT Posting Setup with Unrealized VAT and VAT Cash Regime options set.
        Library340347Declaration.CreateVATPostingSetup(VATPostingSetup, true, true);

        // [GIVEN] Sales Invoice with amount "A1" and payment fully applied to invoice.
        Library340347Declaration.CreateCustomer(Customer, VATPostingSetup."VAT Bus. Posting Group");
        InvoiceNo := Library340347Declaration.CreateAndPostSalesInvoice(VATPostingSetup, Customer."No.", WorkDate(), InvoiceAmount);
        PaymentBalAccNo := CreateAndPostPaymentJnlLine("Gen. Journal Account Type"::Customer, Customer."No.", WorkDate(), -InvoiceAmount, InvoiceNo);

        // [GIVEN] Sales Credit Memo with amount "A2" < "A1" and refund fully applied to credit memo.
        CrMemoAmount := Round(InvoiceAmount / 4);
        CrMemoNo := Library340347Declaration.CreateAndPostSalesCrMemo(VATPostingSetup, Customer."No.", WorkDate(), CrMemoAmount, '');
        RefundBalAccNo := CreateAndPostRefundJnlLine("Gen. Journal Account Type"::Customer, Customer."No.", WorkDate(), CrMemoAmount, CrMemoNo);

        // [WHEN] Run Make 347 Declaration report with GL Accounts for Payments in Cash specified.
        Test347DeclarationParameter.GLAccForPaymentsInCash := StrSubstNo('%1;%2', PaymentBalAccNo, RefundBalAccNo);
        FileName := RunMake347DeclarationReport();

        // [THEN] Total amount is "A1" - "A2" on positions 83-98.
        // [THEN] Amount received in cash is "A1" - "A2" on positions 101-115.
        Line := ReadLineIn347ReportFile(FileName, Customer."No.");
        TotalAmount := ReadCVAmount(Line);
        CashAmount := ReadCashAmount(Line);
        Assert.AreEqual(InvoiceAmount - CrMemoAmount, TotalAmount, 'Total amount is incorrect.');
        Assert.AreEqual(InvoiceAmount - CrMemoAmount, CashAmount, 'Cash amount is incorrect.');
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();
        LibraryVariableStorage.Clear();
        Library347Declaration.Init347DeclarationParameters(Test347DeclarationParameter);
        if IsInitialized then
            exit;
        Library347Declaration.CreateAndPostSalesInvoiceToEnsureAReportGetsGenerated();
        LibrarySetupStorage.SaveCompanyInformation();
        IsInitialized := true;
        Commit();
    end;

    local procedure CreateAndPostSalesInvoiceDetailed(var Customer: Record Customer; var VATPostingSetup: Record "VAT Posting Setup"; PostingDate: Date; UseUnrealizedVAT: Boolean; UseVATCashRegime: Boolean) Amount: Decimal
    begin
        if VATPostingSetup."VAT Bus. Posting Group" = '' then
            Library340347Declaration.CreateVATPostingSetup(VATPostingSetup, UseUnrealizedVAT, UseVATCashRegime);

        if Customer."No." = '' then
            Library340347Declaration.CreateCustomer(Customer, VATPostingSetup."VAT Bus. Posting Group");

        Library340347Declaration.CreateAndPostSalesInvoice(VATPostingSetup, Customer."No.", PostingDate, Amount);

        exit(Amount);
    end;

    local procedure CreateAndPostSalesInvoiceReverseCharge(var Customer: Record Customer) Amount: Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        Library340347Declaration.CreateReverseChargeVATPostingSetup(VATPostingSetup, Customer."VAT Bus. Posting Group");
        if Customer."No." = '' then
            Library340347Declaration.CreateCustomer(Customer, VATPostingSetup."VAT Bus. Posting Group");
        Library340347Declaration.CreateAndPostSalesInvoice(VATPostingSetup, Customer."No.", WorkDate(), Amount);
    end;

    local procedure CreateAndPostSalesInvoiceWithVATCashRegime(var CustomerNo: Code[20]; UseUnrealizedVAT: Boolean; UseVATCashRegime: Boolean) Amount: Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Customer: Record Customer;
    begin
        Library340347Declaration.CreateVATPostingSetup(VATPostingSetup, UseUnrealizedVAT, UseVATCashRegime);
        Library340347Declaration.CreateCustomer(Customer, VATPostingSetup."VAT Bus. Posting Group");
        Library340347Declaration.CreateAndPostSalesInvoice(VATPostingSetup, Customer."No.", WorkDate(), Amount);
        CustomerNo := Customer."No.";
    end;

    local procedure CreateAndPostPurchaseInvoiceWithVATCashRegime(var VendorNo: Code[20]; PostingDate: Date; UseUnrealizedVAT: Boolean; UseVATCashRegime: Boolean) Amount: Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        ExternalDocumentNo: Code[35];
    begin
        Library340347Declaration.CreateVATPostingSetup(VATPostingSetup, UseUnrealizedVAT, UseVATCashRegime);
        Library340347Declaration.CreateVendor(Vendor, VATPostingSetup."VAT Bus. Posting Group");
        ExternalDocumentNo := LibraryUtility.GenerateGUID();
        Library340347Declaration.CreateAndPostPurchaseInvoice(VATPostingSetup, Vendor."No.", PostingDate, Amount, ExternalDocumentNo);
        VendorNo := Vendor."No.";
    end;

    local procedure CreateAndPostPurchaseInvoiceSameVendor(var Vendor: Record Vendor; PostingDate: Date; UseUnrealizedVAT: Boolean; UseVATCashRegime: Boolean) Amount: Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ExternalDocumentNo: Code[35];
    begin
        Library340347Declaration.CreateVATPostingSetup(VATPostingSetup, UseUnrealizedVAT, UseVATCashRegime);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
        ExternalDocumentNo := LibraryUtility.GenerateGUID();
        Library340347Declaration.CreateAndPostPurchaseInvoice(VATPostingSetup, Vendor."No.", PostingDate, Amount, ExternalDocumentNo);
    end;

    local procedure CreateAndPostPurchaseInvoiceReverseCharge(Vendor: Record Vendor) Amount: Decimal
    var
        VATPostingSetup: Record "VAT Posting Setup";
        ExtDocumentNo: Code[20];
    begin
        Library340347Declaration.CreateReverseChargeVATPostingSetup(VATPostingSetup, Vendor."VAT Bus. Posting Group");
        ExtDocumentNo := LibraryUtility.GenerateGUID();
        Library340347Declaration.CreateAndPostPurchaseInvoice(VATPostingSetup, Vendor."No.", WorkDate(), Amount, ExtDocumentNo);
    end;

    local procedure CreateAndPostPaymentJnlLine(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; PostingDate: Date; PmtAmount: Decimal; ApplToDocNo: Code[20]) BalAccountNo: Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine, GenJournalLine."Document Type"::Payment,
            AccountType, AccountNo,
            PmtAmount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", ApplToDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        BalAccountNo := GenJournalLine."Bal. Account No.";
    end;

    local procedure CreateAndPostRefundJnlLine(AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; PostingDate: Date; RefundAmount: Decimal; ApplToDocNo: Code[20]) BalAccountNo: Code[20]
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
            GenJournalLine, "Gen. Journal Document Type"::Refund, AccountType, AccountNo, RefundAmount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Applies-to Doc. Type", "Gen. Journal Document Type"::"Credit Memo");
        GenJournalLine.Validate("Applies-to Doc. No.", ApplToDocNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        BalAccountNo := GenJournalLine."Bal. Account No.";
    end;

    local procedure GetSalesInvoiceNo(CustomerNo: Code[20]): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesInvoiceHeader.SetRange("Bill-to Customer No.", CustomerNo);
        SalesInvoiceHeader.FindLast();
        exit(SalesInvoiceHeader."No.");
    end;

    local procedure GetPurchInvoiceNo(VendorNo: Code[20]): Code[20]
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.SetRange("Pay-to Vendor No.", VendorNo);
        PurchInvHeader.FindLast();
        exit(PurchInvHeader."No.");
    end;

    local procedure ReadReverseChargeFlag(Line: Text[1024]): Text[1]
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 282, 1));
    end;

    local procedure ReadVATCashRegimeFlag(Line: Text[1024]): Text[1]
    begin
        exit(LibraryTextFileValidation.ReadValue(Line, 281, 1));
    end;

    local procedure ReadVATCashRegimeYearlyAmount(Line: Text[1024]): Decimal
    var
        VATCashRegimeYearlyAmount: Integer;
    begin
        Evaluate(VATCashRegimeYearlyAmount, LibraryTextFileValidation.ReadValue(Line, 284, 16));
        exit(VATCashRegimeYearlyAmount / 100);
    end;

    local procedure ReadCVAmount(Line: Text[1024]): Decimal
    var
        VATCashRegimeYearlyAmount: Integer;
    begin
        Evaluate(VATCashRegimeYearlyAmount, LibraryTextFileValidation.ReadValue(Line, 83, 16));
        exit(VATCashRegimeYearlyAmount / 100);
    end;

    local procedure ReadCashAmount(Line: Text[1024]): Decimal
    var
        CashAmount: Integer;
    begin
        Evaluate(CashAmount, LibraryTextFileValidation.ReadValue(Line, 101, 15));
        exit(CashAmount / 100);
    end;

    local procedure ReadLineIn347ReportFile(FileName: Text[1024]; CustomerVendorNo: Code[20]): Text[500]
    begin
        exit(Library347Declaration.ReadLineWithCustomerOrVendor(FileName, CustomerVendorNo));
    end;

    local procedure RunMake347DeclarationReport(): Text[1024]
    begin
        exit(Library347Declaration.RunMake347DeclarationReport(Test347DeclarationParameter, LibraryVariableStorage));
    end;

    local procedure ValidateFileHasLineForCustomer(FileName: Text[1024]; CustomerVendorNo: Code[20])
    begin
        Library347Declaration.ValidateFileHasLineForCustomer(FileName, CustomerVendorNo);
    end;

    local procedure ValidateFileHasExpectedReverseChargeFlag(FileName: Text[1024]; CustomerNo: Code[20]; ExpectedFlagVallue: Text[1])
    var
        Line: Text[500];
        ActualFlagValue: Text[1];
    begin
        Line := ReadLineIn347ReportFile(FileName, CustomerNo);
        ActualFlagValue := ReadReverseChargeFlag(Line);
        Assert.AreEqual(
          ExpectedFlagVallue, ActualFlagValue, IncorrectReverseChargeFlagErr);
    end;

    local procedure ValidateFileHasExpectedVATCashRegimeAmount(FileName: Text[1024]; CustVendNo: Code[20]; ExpectedAnnualAmount: Decimal; ExpectedCVAmount: Decimal)
    var
        Line: Text[500];
    begin
        Line := ReadLineIn347ReportFile(FileName, CustVendNo);

        VerifyCVAndAnnualCashAmounts(Line, ExpectedAnnualAmount, ExpectedCVAmount);
    end;

    local procedure ValidateFileHasExpectedVATCashRegimeFlag(FileName: Text[1024]; CustVendNo: Code[20]; ExpectedFlagVallue: Text[1]; ErrorMessage: Text)
    var
        Line: Text[500];
        ActualFlagValue: Text[1];
    begin
        Line := ReadLineIn347ReportFile(FileName, CustVendNo);
        ActualFlagValue := ReadVATCashRegimeFlag(Line);
        Assert.AreEqual(ExpectedFlagVallue, ActualFlagValue, ErrorMessage);
    end;

    local procedure ValidateFileQuarterAmount(FileName: Text[1024]; CustVendNo: Code[20]; PostingDate: Date; ExpectedQuarterAmount: Decimal)
    var
        Line: Text[500];
    begin
        Line := ReadLineIn347ReportFile(FileName, CustVendNo);

        VerifyQuarterAmount(Line, PostingDate, ExpectedQuarterAmount);
    end;

    local procedure ValidateFileSecondLineForVendor(FileName: Text[1024]; VendNo: Code[20]; ExpectedAnnualAmount: Decimal; ExpectedCVAmount: Decimal; ExpectedVATCashFlag: Text[1]; ExpectedRevChargeFlag: Text[1]; PostingDate: Date; ExpectedQuarterAmount: Decimal)
    var
        Line: Text[500];
        ActualFlagValue: Text[1];
    begin
        Line := Library347Declaration.ReadSecondLineForVendor(FileName, VendNo);

        Assert.AreNotEqual('', Line, LineShouldNotBeEmptyErr);

        VerifyCVAndAnnualCashAmounts(Line, ExpectedAnnualAmount, ExpectedCVAmount);

        ActualFlagValue := ReadVATCashRegimeFlag(Line);
        Assert.AreEqual(ExpectedVATCashFlag, ActualFlagValue, IncorrectVATCashRegimeFlagErr);

        ActualFlagValue := ReadReverseChargeFlag(Line);
        Assert.AreEqual(ExpectedRevChargeFlag, ActualFlagValue, IncorrectReverseChargeFlagErr);

        VerifyQuarterAmount(Line, PostingDate, ExpectedQuarterAmount);
    end;

    local procedure VerifyCVAndAnnualCashAmounts(Line: Text[500]; ExpectedAnnualAmount: Decimal; ExpectedCVAmount: Decimal)
    var
        CVAmount: Decimal;
        VATCashRegimeAnnualAmount: Decimal;
    begin
        CVAmount := ReadCVAmount(Line);
        Assert.AreEqual(ExpectedCVAmount, CVAmount, AmountCustVendErr);

        VATCashRegimeAnnualAmount := ReadVATCashRegimeYearlyAmount(Line);
        Assert.AreEqual(ExpectedAnnualAmount, VATCashRegimeAnnualAmount, AnnualVATCashAmountErr);
    end;

    local procedure VerifyQuarterAmount(Line: Text[500]; PostingDate: Date; ExpectedQuarterAmount: Decimal)
    var
        QuarterAmount: Decimal;
        QuarterNo: Integer;
    begin
        QuarterNo := Date2DMY(PostingDate, 2) div 4 + 1;
        Evaluate(QuarterAmount, LibraryTextFileValidation.ReadValue(Line, 136 + 32 * (QuarterNo - 1), 16));
        QuarterAmount := QuarterAmount / 100;

        Assert.AreEqual(ExpectedQuarterAmount, QuarterAmount, IncorrectQuarterAmountErr);
    end;

    local procedure SetGeneralLedgerSetupVATCashRegime(NewVATCashRegime: Boolean) OldVATCashRegime: Boolean
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldVATCashRegime := GeneralLedgerSetup."VAT Cash Regime";
        GeneralLedgerSetup.Validate("VAT Cash Regime", NewVATCashRegime);
        GeneralLedgerSetup.Modify(true);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure Make347DeclarationReportHandler(var Make347Declaration: TestRequestPage "Make 347 Declaration")
    var
        FiscalYear: Variant;
        MinAmount: Variant;
        MinAmountInCash: Variant;
        ContactName: Variant;
        TelephoneNumber: Variant;
        DeclarationNumber: Variant;
        GLAccForPaymentsInCash: Variant;
        DeclarationMediaType: Option Telematic,"CD-R";
    begin
        LibraryVariableStorage.Dequeue(FiscalYear);
        LibraryVariableStorage.Dequeue(MinAmount);
        LibraryVariableStorage.Dequeue(MinAmountInCash);
        LibraryVariableStorage.Dequeue(GLAccForPaymentsInCash);
        LibraryVariableStorage.Dequeue(ContactName);
        LibraryVariableStorage.Dequeue(TelephoneNumber);
        LibraryVariableStorage.Dequeue(DeclarationNumber);
        Make347Declaration.FiscalYear.SetValue(FiscalYear);
        Make347Declaration.MinAmount.SetValue(MinAmount);
        Make347Declaration.MinAmountInCash.SetValue(MinAmountInCash);
        Make347Declaration.GLAccForPaymentsInCash.SetValue(GLAccForPaymentsInCash);
        Make347Declaration.ContactName.SetValue(ContactName);
        Make347Declaration.TelephoneNumber.SetValue(TelephoneNumber);
        Make347Declaration.DeclarationNumber.SetValue(DeclarationNumber);
        Make347Declaration.DeclarationMediaType.SetValue(DeclarationMediaType::Telematic);
        Make347Declaration.OK().Invoke();
    end;
}

