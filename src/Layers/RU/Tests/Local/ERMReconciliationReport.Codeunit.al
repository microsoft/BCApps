codeunit 144719 "ERM Reconciliation Report"
{
    // // [FEATURE] [Reports] [Reconciliation]

    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        AmountPresentErr: Label 'Report must not contains amount value.';
        CellDoesNotContainValueErr: Label 'Cell R%1 C%2 does not contains value %3.';

    [Test]
    [Scope('OnPrem')]
    procedure Vend_OnDateAfterPurch_PrevPeriodAmtOK()
    var
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
    begin
        RunReconciliationForPurchase(WorkDate() + LibraryRandom.RandInt(5), true, InvoiceAmount, PaymentAmount);

        LibraryReportValidation.VerifyCellValue(13, 14, AmountAsText(InvoiceAmount - PaymentAmount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Vend_OnPurchDate_CurrPeriodAmtOK()
    var
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
    begin
        RunReconciliationForPurchase(WorkDate(), true, InvoiceAmount, PaymentAmount);

        LibraryReportValidation.VerifyCellValue(20, 12, AmountAsText(PaymentAmount));
        LibraryReportValidation.VerifyCellValue(25, 4, Format(WorkDate()) + ' - ' + Format(WorkDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Vend_OnDateBeforePurch_NoAmount()
    var
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
    begin
        RunReconciliationForPurchase(WorkDate() - LibraryRandom.RandInt(5), true, InvoiceAmount, PaymentAmount);

        Assert.IsFalse(
          LibraryReportValidation.CheckIfValueExistsInSpecifiedColumn('N', AmountAsText(InvoiceAmount)),
          AmountPresentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Vend_OnDateAfterSales_PrevPeriodAmtOK()
    var
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
    begin
        RunReconciliationForSales(WorkDate() + LibraryRandom.RandInt(5), true, InvoiceAmount, PaymentAmount, 2);

        LibraryReportValidation.VerifyCellValue(17, 12, AmountAsText(InvoiceAmount + PaymentAmount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Vend_OnSalesDate_CurrPeriodAmtOK()
    var
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
    begin
        RunReconciliationForSales(WorkDate(), true, InvoiceAmount, PaymentAmount, 2);

        LibraryReportValidation.VerifyCellValue(26, 14, AmountAsText(InvoiceAmount + PaymentAmount));
        LibraryReportValidation.VerifyCellValue(26, 4, Format(WorkDate()) + ' - ' + Format(WorkDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Vend_OnDateBeforeSales_NoAmount()
    var
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
    begin
        RunReconciliationForSales(WorkDate() - LibraryRandom.RandInt(5), true, InvoiceAmount, PaymentAmount, 2);

        Assert.IsFalse(
          LibraryReportValidation.CheckIfValueExistsInSpecifiedColumn('L', AmountAsText(InvoiceAmount)),
          AmountPresentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Cust_OnDateAfterPurch_PrevPeriodAmtOK()
    var
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
    begin
        RunReconciliationForPurchase(WorkDate() + LibraryRandom.RandInt(5), false, InvoiceAmount, PaymentAmount);

        LibraryReportValidation.VerifyCellValue(19, 18, AmountAsText(InvoiceAmount - PaymentAmount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Cust_OnPurchDate_CurrPeriodAmtOK()
    var
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
    begin
        RunReconciliationForPurchase(WorkDate(), false, InvoiceAmount, PaymentAmount);
        LibraryReportValidation.VerifyCellValue(24, 12, AmountAsText(InvoiceAmount - PaymentAmount));
        LibraryReportValidation.VerifyCellValue(24, 5, Format(WorkDate()) + ' - ' + Format(WorkDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Cust_OnDateBeforePurch_NoAmount()
    var
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
    begin
        RunReconciliationForPurchase(WorkDate() - LibraryRandom.RandInt(5), false, InvoiceAmount, PaymentAmount);

        Assert.IsFalse(
          LibraryReportValidation.CheckIfValueExistsInSpecifiedColumn('N', AmountAsText(InvoiceAmount)),
          AmountPresentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Cust_OnDateAfterSales_PrevPeriodAmtOK()
    var
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
    begin
        RunReconciliationForSales(WorkDate() + LibraryRandom.RandInt(5), false, InvoiceAmount, PaymentAmount, 2);

        LibraryReportValidation.VerifyCellValue(17, 12, AmountAsText(InvoiceAmount + PaymentAmount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Cust_OnSalesDate_CurrPeriodAmtOK()
    var
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
    begin
        RunReconciliationForSales(WorkDate(), false, InvoiceAmount, PaymentAmount, 2);

        LibraryReportValidation.VerifyCellValue(20, 14, AmountAsText(-PaymentAmount));
        LibraryReportValidation.VerifyCellValue(20, 5, Format(WorkDate()) + ' - ' + Format(WorkDate()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Cust_OnSalesDate_FullyAppliedDocsShown()
    var
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
    begin
        // [SCENARIO 378714] Report "Customer - Reconciliation Act" always shows Invoice closed by Payment in the current period
        // [GIVEN] Posted Sales Invoice, posted full Payment applied to the Invoice
        // [WHEN] Running the report
        RunReconciliationForSales(WorkDate(), false, InvoiceAmount, PaymentAmount, 1);

        // [THEN] Payment followed by Invoice are shown, numbered as '1' and '1.1' respectively, with correct Debit and Credit
        LibraryReportValidation.VerifyCellValue(15, 1, '1');
        LibraryReportValidation.VerifyCellValue(15, 12, AmountAsText(InvoiceAmount));
        LibraryReportValidation.VerifyCellValue(15, 20, AmountAsText(InvoiceAmount));
        LibraryReportValidation.VerifyCellValue(16, 1, '1.1');
        LibraryReportValidation.VerifyCellValue(16, 14, AmountAsText(-PaymentAmount));
        LibraryReportValidation.VerifyCellValue(16, 16, AmountAsText(-PaymentAmount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Cust_OnDateBeforeSales_NoAmount()
    var
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
    begin
        RunReconciliationForSales(WorkDate() - LibraryRandom.RandInt(5), false, InvoiceAmount, PaymentAmount, 2);

        Assert.IsFalse(
          LibraryReportValidation.CheckIfValueExistsInSpecifiedColumn('L', AmountAsText(InvoiceAmount)),
          AmountPresentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Cust_Agreements_LCY()
    var
        InvoiceAmount1: Decimal;
        InvoiceAmount2: Decimal;
        PaymentCoeff: Decimal;
        CustomerNo: Code[20];
        SkippedInvoiceNo: Code[20];
        SkippedCreditMemoNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 379097] Report "Customer - Reconciliation Act" qualifies for cases described in RFHs 352923..36, 353949, 354901..2, 355590, 355715
        // [GIVEN] Customer with "Agreement Posting" = Mandatory and empty "Currency Code",
        // [GIVEN] Customer Agreements "A1" and "A2",
        // [GIVEN] Posted Sales Invoice "I1" for "A1" with "Posting Date" = (WorkDate() - 1) and Amount = "IA1",
        // [GIVEN] Posted Payment for "I1" with "Posting Date" = (WorkDate() - 1) and Amount = "IA1" / 2, applied to "I1"
        // [GIVEN] Posted Sales Invoice "I2" for "A2" with "Posting Date" = WORKDATE and Amount = "IA2",
        // [GIVEN] Posted Sales Credit Memo "CM2" for "A2" as "I2" cancellation,
        // [GIVEN] Posted Sales Invoice "I3" for "A1" with "Posting Date" = WORKDATE and Amount = "IA2",
        // [GIVEN] 2 posted journal lines with "Posting Date" = WORKDATE and Amount = "IA2" * 2:
        // [GIVEN] Line1."Document No." = Line2."Document No.", Line1."Document Type" = Line2."Document Type" = '',
        // [GIVEN] Line1."Agreement No." = "A2", Line2."Agreement No." = "A1", Line2."Applies-to Doc. No." = "I2"
        Initialize();
        PaymentCoeff := 2;
        CustomerNo :=
          CreateDataForSalesWithAgreements(WorkDate(), '', InvoiceAmount1, InvoiceAmount2, PaymentCoeff, SkippedInvoiceNo, SkippedCreditMemoNo);

        // [WHEN] Printing report "Customer - Reconciliation Act"
        PrintCustomerReconciliation(CustomerNo, '', WorkDate());

        // [THEN] Aggregated customer initial balance is shown (Debit only),
        // [THEN] Open invoice from previous period is shown,
        // [THEN] Applied payment from previous period is shown,
        // [THEN] Aggregated ending balance for the invoice is shown (Debit only),
        // [THEN] Payment transfer from agreement 2 for current period is shown (Debit),
        // [THEN] Payment transfer to agreement 1 for current period is shown (Credit),
        // [THEN] Applied invoice (agreement 1) for current period is shown,
        // [THEN] Invoice, cancelled by Credit Memo, is skipped
        // [THEN] Credit Memo, cancelling the Invoice, is skipped
        // [THEN] Invoice (agreement 1) for current period is shown,
        // [THEN] Applied Payment transfer to agreement 1 for current period is shown,
        // [THEN] Payment (agreement 2) for current period is shown,
        // [THEN] Debit and Credit turnovers for current period are shown,
        // [THEN] Aggregated customer ending balance is shown (Credit only),
        // [THEN] Aggregated customer + linked vendor starting balance is shown (Debit only),
        // [THEN] Debit and Credit customer + linked vendor turnovers for current period are shown,
        // [THEN] Aggregated customer + linked vendor ending balance is shown (Credit only)
        VerifyCustReportWithAgreements(InvoiceAmount1, InvoiceAmount2, PaymentCoeff, SkippedInvoiceNo, SkippedCreditMemoNo);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,CustomerReconciliationActRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Cust_Agreements_FCY()
    var
        InvoiceAmount1: Decimal;
        InvoiceAmount2: Decimal;
        PaymentCoeff: Decimal;
        CustomerNo: Code[20];
        CurrencyCode: Code[10];
        ExchRate1: Decimal;
        ExchRate2: Decimal;
        SkippedInvoiceNo: Code[20];
        SkippedCreditMemoNo: Code[20];
    begin
        // [FEATURE] [Sales] [Currency]
        // [SCENARIO 379097] Report "Customer - Reconciliation Act" qualifies for cases described in RFHs 352923..36, 353949, 354901..2, 355590, 355715 in case of currency
        // [GIVEN] Currency "C" with Exchange Rate "E1" for WorkDate() - 1 and "E2" for WORKDATE,
        // [GIVEN] Customer with "Agreement Posting" = Mandatory and "Currency Code" = "C",
        // [GIVEN] Customer Agreements "A1" and "A2",
        // [GIVEN] Posted Sales Invoice "I1" for "A1" with "Posting Date" = (WorkDate() - 1) and Amount = "IA1",
        // [GIVEN] Posted Payment for "I1" with "Posting Date" = (WorkDate() - 1) and Amount = "IA1" / 2, applied to "I1"
        // [GIVEN] Posted Sales Invoice "I2" for "A2" with "Posting Date" = WORKDATE and Amount = "IA2",
        // [GIVEN] Posted Sales Credit Memo "CM2" for "A2" as "I2" cancellation,
        // [GIVEN] Posted Sales Invoice "I3" for "A1" with "Posting Date" = WORKDATE and Amount = "IA2",
        // [GIVEN] Posted Payment for "A2" with "Posting Date" = WORKDATE and Amount = "IA2" * 2,
        // [GIVEN] 2 posted journal lines with "Posting Date" = WORKDATE and Amount = "IA2" * 2:
        // [GIVEN] Line1."Document No." = Line2."Document No.", Line1."Document Type" = Line2."Document Type" = '',
        // [GIVEN] Line1."Agreement No." = "A2", Line2."Agreement No." = "A1", Line2."Applies-to Doc. No." = "I2".
        Initialize();
        PaymentCoeff := 2;
        ExchRate1 := LibraryRandom.RandIntInRange(70, 90);
        ExchRate2 := LibraryRandom.RandIntInRange(70, 90);
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate() - 1, ExchRate1, ExchRate1);
        LibraryERM.CreateExchangeRate(CurrencyCode, WorkDate(), ExchRate2, ExchRate2);
        CustomerNo :=
          CreateDataForSalesWithAgreements(WorkDate(), CurrencyCode, InvoiceAmount1, InvoiceAmount2, PaymentCoeff,
            SkippedInvoiceNo, SkippedCreditMemoNo);

        // [WHEN] Printing report "Customer - Reconciliation Act"
        PrintCustomerReconciliationWithCurrency(CustomerNo, WorkDate(), CurrencyCode);

        // [THEN] Aggregated customer initial balance is shown (Debit only),
        // [THEN] Open invoice from previous period is shown,
        // [THEN] Applied payment from previous period is shown,
        // [THEN] Aggregated ending balance for the invoice is shown (Debit only),
        // [THEN] Payment transfer from agreement 2 for current period is shown (Debit),
        // [THEN] Payment transfer to agreement 1 for current period is shown (Credit),
        // [THEN] Applied invoice (agreement 1) for current period is shown,
        // [THEN] Invoice, cancelled by Credit Memo, is skipped
        // [THEN] Credit Memo, cancelling the Invoice, is skipped
        // [THEN] Invoice (agreement 1) for current period is shown,
        // [THEN] Applied Payment transfer to agreement 1 for current period is shown,
        // [THEN] Payment (agreement 2) for current period is shown,
        // [THEN] Debit and Credit turnovers for current period are shown,
        // [THEN] Aggregated customer ending balance is shown (Credit only),
        // [THEN] Aggregated customer + linked vendor starting balance is shown (Debit only),
        // [THEN] Debit and Credit customer + linked vendor turnovers for current period are shown,
        // [THEN] Aggregated customer + linked vendor ending balance is shown (Credit only)
        VerifyCustReportWithAgreements(InvoiceAmount1, InvoiceAmount2, PaymentCoeff, SkippedInvoiceNo, SkippedCreditMemoNo);
    end;

    [Test]
    [HandlerFunctions('CustomerReconciliationActRequestPageHandler')]
    [Scope('OnPrem')]
    procedure Cust_FuturePaymentForPreviousPeriod()
    var
        InvoiceAmount: Decimal;
        CustomerNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 379097] Report "Customer - Reconciliation Act" qualifies for the case described in RFHs 378987
        // [GIVEN] Customer with "Agreement Posting" = "No Agreement" and empty "Currency Code",
        // [GIVEN] Posted Sales Invoice "I1" with "Posting Date" = (WorkDate() - 1) and Amount = "IA1",
        // [GIVEN] Posted Payment "P1" for "I1" with "Posting Date" = (WorkDate() + 1) and Amount = "IA1", applied to "I1"
        Initialize();
        CustomerNo :=
          CreateDataForSalesWithFuturePayment(WorkDate(), InvoiceAmount);

        // [WHEN] Printing report "Customer - Reconciliation Act" on WORKDATE
        PrintCustomerReconciliationWithCurrency(CustomerNo, WorkDate(), '');

        // [THEN] Customer initial balance with Debit Amount ="IA1" is shown,
        // [THEN] Invoice "I1" from previous period with Debit Amount ="IA1" is shown,
        // [THEN] Applied payment "P1" from future period is NOT shown
        VerifyCustReportWithFuturePayment(InvoiceAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Cust_ShowOldClosedInvoices()
    var
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        PaymentNo: Code[20];
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
        PmtDate: Date;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 379645] Report "Customer - Reconciliation Act" shows closed invoice and it's applied payment in the previous period section
        Initialize();

        CustomerNo := LibrarySales.CreateCustomerNo();
        // [GIVEN] Posted invoice "Inv" on April with amount 1180
        InvoiceNo := CreatePostSalesInvoice(CustomerNo, InvoiceAmount, '', GetRandomDateWithMonthShift(3));

        // [GIVEN] Posted payment "Pmt" on May with amount 1800 applied to "Inv", as a result "Inv" became closed
        PaymentAmount := GetAmountGreaterThan(InvoiceAmount);
        PmtDate := GetRandomDateWithMonthShift(4);
        CreateApplyPostCustomerPayment(PmtDate, CustomerNo, InvoiceNo, '', -PaymentAmount);
        PaymentNo := FindPaymentNo(CustomerNo);

        // [WHEN] Printing report "Customer - Reconciliation Act" on May
        PrintCustomerReconciliation(CustomerNo, '', PmtDate);

        // [THEN] "Inv" and related "Pmt" are printed in previous period document section with amounts 1180 and 1800
        // [THEN] "Pmt" is printed in current period payment section
        VerifyCustOldClosedInvoices(InvoiceAmount, InvoiceNo, PaymentAmount, PaymentNo);
        VerifyCustTurnoverAndSaldoForSingleDoc(19, PaymentAmount, 0, PaymentAmount - InvoiceAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure Cust_DoesntShowOldClosedInvoicesForOldPayments()
    var
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
        PmtDate: Date;
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 380823] Report "Customer - Reconciliation Act" doesn't show closed invoice and it's applied payment in the previous period section for old payments
        Initialize();

        CustomerNo := LibrarySales.CreateCustomerNo();
        // [GIVEN] Posted invoice "Inv" on April with amount 1180
        InvoiceNo := CreatePostSalesInvoice(CustomerNo, InvoiceAmount, '', GetRandomDateWithMonthShift(3));

        // [GIVEN] Posted payment "Pmt" on May with amount 1800 applied to "Inv", as a result "Inv" became closed
        PaymentAmount := GetAmountGreaterThan(InvoiceAmount);
        PmtDate := GetRandomDateWithMonthShift(4);
        CreateApplyPostCustomerPayment(PmtDate, CustomerNo, InvoiceNo, '', -PaymentAmount);

        // [WHEN] Printing report "Customer - Reconciliation Act" on June
        PrintCustomerReconciliation(CustomerNo, '', CalcDate('<1D>', PmtDate));

        // [THEN] "Inv" and related "Pmt" are not printed in previous period document section
        // [THEN] "Pmt" is printed in previous period payment section
        VerifyCustTurnoverAndSaldoForSingleDoc(16, PaymentAmount, 0, PaymentAmount - InvoiceAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroTurnoverAfterCustomerWithPartialCorrCreditMemo()
    var
        CustomerNo: Code[20];
        InvoiceNo: Code[20];
        InvoiceAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Invoice]
        // [SCENARIO 380825] Second customer has zero turnover after first customer with partial correction Credit Memo
        Initialize();

        // [GIVEN] First customer with:
        CustomerNo := LibrarySales.CreateCustomerNo();
        // [GIVEN] Sales Invoice (Amount = 1000)
        InvoiceNo := CreatePostSalesInvoice(CustomerNo, InvoiceAmount, '', WorkDate());
        // [GIVEN] Sales Credit Memo (Amount = 200) applied to the Invoice
        CreatePostPartialCorrectionSalesCrMemo(CustomerNo, InvoiceNo);
        // [GIVEN] Payment (Amount = 2000) applied to the Invoice
        CreateApplyPostCustomerPayment(WorkDate(), CustomerNo, InvoiceNo, '', -InvoiceAmount * 2);
        // [GIVEN] Second customer without transactions within period

        // [WHEN] Printing report "Customer - Reconciliation Act" for both customers
        PrintCustomerReconciliation(CustomerNo, LibrarySales.CreateCustomerNo(), WorkDate());

        // [THEN] The second customer has zero turnover
        VerifyCustomerZeroTurnoverLine();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ZeroTurnoverAfterCustomerWithPartialCorrInvoice()
    var
        CustomerNo: Code[20];
        CrMemoNo: Code[20];
        CrMemoAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 380825] Second customer has zero turnover after first customer with partial correction Invoice
        Initialize();

        // [GIVEN] First customer with:
        CustomerNo := LibrarySales.CreateCustomerNo();
        // [GIVEN] Sales Credit Memo (Amount = 1000)
        CrMemoNo := CreatePostSalesCrMemoWithTwoLines(WorkDate(), CustomerNo, CrMemoAmount);
        // [GIVEN] Sales Invoice (Amount = 200) applied to the Credit Memo
        CreatePostPartialCorrectionSalesInvoice(CustomerNo, CrMemoNo);
        // [GIVEN] Refund (Amount = 2000) applied to the Credit Memo
        CreateApplyPostCustomerRefund(CustomerNo, CrMemoNo, CrMemoAmount * 2);
        // [GIVEN] Second customer without transactions within period

        // [WHEN] Printing report "Customer - Reconciliation Act" for both customers
        PrintCustomerReconciliation(CustomerNo, LibrarySales.CreateCustomerNo(), WorkDate());

        // [THEN] The second customer has zero turnover
        VerifyCustomerZeroTurnoverLine();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoHasPositiveCreditAmount()
    var
        CustomerNo: Code[20];
        CrMemoAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 380824] Sales Credit Memo is printed with positive credit amount in case when it is not a correction
        Initialize();

        // [GIVEN] GLSetup."Mark Cr. Memos as Corrections" = FALSE
        UpdateGLSetupMarkCrMemosAsCorrections(false);
        // [GIVEN] Posted Sales Credit Memo
        CustomerNo := LibrarySales.CreateCustomerNo();
        CreatePostSalesCrMemoWithTwoLines(WorkDate(), CustomerNo, CrMemoAmount);

        // [WHEN] Printing report "Customer - Reconciliation Act"
        PrintCustomerReconciliation(CustomerNo, '', WorkDate());

        // [THEN] Report prints positive credit amount for the Credit Memo
        VerifySalesCreditMemoPositiveCreditAmount(CrMemoAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectionSalesCreditMemoHasNegativeDebitAmount()
    var
        CustomerNo: Code[20];
        CrMemoAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Credit Memo] [Correction]
        // [SCENARIO 380824] Sales Credit Memo is printed with negative debit amount in case when it is a correction
        Initialize();

        // [GIVEN] GLSetup."Mark Cr. Memos as Corrections" = TRUE
        UpdateGLSetupMarkCrMemosAsCorrections(true);
        // [GIVEN] Posted Sales Credit Memo
        CustomerNo := LibrarySales.CreateCustomerNo();
        CreatePostSalesCrMemoWithTwoLines(WorkDate(), CustomerNo, CrMemoAmount);

        // [WHEN] Printing report "Customer - Reconciliation Act"
        PrintCustomerReconciliation(CustomerNo, '', WorkDate());

        // [THEN] Report prints negative debit amount for the Credit Memo
        VerifySalesCreditMemoNegativeDebitAmount(CrMemoAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCreditMemoHasPositiveCreditAmountForPrevPeriod()
    var
        CustomerNo: Code[20];
        CrMemoAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Credit Memo]
        // [SCENARIO 380824] Sales Credit Memo is printed with positive credit amount in case when it is not a correction for previous reporting period
        Initialize();

        // [GIVEN] GLSetup."Mark Cr. Memos as Corrections" = FALSE
        UpdateGLSetupMarkCrMemosAsCorrections(false);
        // [GIVEN] Sales Credit Memo posted in previous period
        CustomerNo := LibrarySales.CreateCustomerNo();
        CreatePostSalesCrMemoWithTwoLines(WorkDate(), CustomerNo, CrMemoAmount);

        // [WHEN] Printing report "Customer - Reconciliation Act" for current month
        PrintCustomerReconciliation(CustomerNo, '', CalcDate('<1M>', WorkDate()));

        // [THEN] Report prints positive credit amount for the Credit Memo
        VerifySalesCreditMemoPositiveCreditAmount(CrMemoAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CorrectionSalesCreditMemoHasNegativeDebitAmountForPrevPeriod()
    var
        CustomerNo: Code[20];
        CrMemoAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Credit Memo] [Correction]
        // [SCENARIO 380824] Sales Credit Memo is printed with negative debit amount in case when it is a correction for previous reporting period
        Initialize();

        // [GIVEN] GLSetup."Mark Cr. Memos as Corrections" = TRUE
        UpdateGLSetupMarkCrMemosAsCorrections(true);
        // [GIVEN] Sales Credit Memo posted in previous period
        CustomerNo := LibrarySales.CreateCustomerNo();
        CreatePostSalesCrMemoWithTwoLines(WorkDate(), CustomerNo, CrMemoAmount);

        // [WHEN] Printing report "Customer - Reconciliation Act" for current month
        PrintCustomerReconciliation(CustomerNo, '', CalcDate('<1M>', WorkDate()));

        // [THEN] Report prints negative debit amount for the Credit Memo
        VerifySalesCreditMemoNegativeDebitAmount(CrMemoAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvoiceWithFullDiscountNoErrorInCustRecon()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        SalesInvoiceNo: Code[20];
    begin
        // [FEATURE] [Sales] [Line Discount]
        // [SCENARIO 359745] Sales Invoice with 100% Line discount gets exported in Customer Reconciliation Act with no error
        Initialize();

        // [GIVEN] Sales Invoice created
        CustomerNo := LibrarySales.CreateCustomerNo();
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);

        // [GIVEN] Sales Line created with 100% Line Discount
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(10));
        SalesLine.Validate("Line Discount %", 100);
        SalesLine.Modify();

        // [GIVEN] Sales Invoice was posted
        SalesInvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, false, true);

        // [WHEN] Printing report "Customer - Reconciliation Act"
        PrintCustomerReconciliation(CustomerNo, '', WorkDate());

        // [THEN] Report prints with no error and contains this document
        LibraryReportValidation.VerifyCellValue(15, 4, StrSubstNo('Invoice %1 Invoice %2', SalesInvoiceNo, SalesHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWithFullDiscountNoErrorInVendRecon()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        PurchaseInvoiceNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Line Discount]
        // [SCENARIO 359745] Purchase Invoice with 100% Line discount gets exported in Vendor Reconciliation Act with no error
        Initialize();

        // [GIVEN] Purchase Invoice created
        VendorNo := LibraryPurchase.CreateVendorNo();
        LibraryPurchase.CreatePurchaseInvoiceForVendorNo(PurchaseHeader, VendorNo);

        // [GIVEN] Purchase Line on this document has 100% Line Discount
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.Validate("Line Discount %", 100);
        PurchaseLine.Modify();

        // [GIVEN] Purchase Invoice was posted
        PurchaseInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        // [WHEN] Printing report "Vendor - Reconciliation Act"
        PrintVendorReconciliation(VendorNo, WorkDate());

        // [THEN] Report prints with no error and contains this document
        LibraryReportValidation.VerifyCellValue(15, 4, StrSubstNo('Invoice %1 Invoice %2', PurchaseInvoiceNo, PurchaseHeader."No."));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        IsInitialized := true;
        Commit();
    end;

    local procedure UpdateGLSetupMarkCrMemosAsCorrections(NewValue: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.Validate("Mark Cr. Memos as Corrections", NewValue);
        GLSetup.Modify(true);
    end;

    local procedure CreatePostPurchInvoice(VendorNo: Code[20]; var InvoiceAmount: Decimal; PostingDate: Date): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchaseHeader.Validate("Posting Date", PostingDate);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseLine.Modify(true);
        InvoiceAmount := PurchaseLine."Amount Including VAT";
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreateApplyPostCustomerPayment(PostingDate: Date; CustomerNo: Code[20]; InvoiceNo: Code[20]; AgreementNo: Code[20]; LineAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateApplyPostGenJnlLine(
              PostingDate, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, CustomerNo,
              GenJournalLine."Applies-to Doc. Type"::Invoice, InvoiceNo, AgreementNo, LineAmount);
    end;

    local procedure CreateApplyPostVendorPayment(VendorNo: Code[20]; InvoiceNo: Code[20]; LineAmount: Decimal)
    begin
        CreateApplyPostVendorPaymentWithPostingDate(VendorNo, InvoiceNo, LineAmount, WorkDate());
    end;

    local procedure CreateApplyPostVendorPaymentWithPostingDate(VendorNo: Code[20]; InvoiceNo: Code[20]; LineAmount: Decimal; PostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateApplyPostGenJnlLine(
              PostingDate, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, VendorNo,
              GenJournalLine."Applies-to Doc. Type"::Invoice, InvoiceNo, '', LineAmount);
    end;

    local procedure CreateApplyPostCustomerRefund(CustomerNo: Code[20]; CrMemoNo: Code[20]; LineAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateApplyPostGenJnlLine(
              WorkDate(), GenJournalLine."Document Type"::Refund, GenJournalLine."Account Type"::Customer, CustomerNo,
              GenJournalLine."Applies-to Doc. Type"::"Credit Memo", CrMemoNo, '', LineAmount);
    end;

    local procedure CreateApplyPostGenJnlLine(PostingDate: Date; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; AppliesToDocType: Enum "Gen. Journal Document Type"; AppliesToDocNo: Code[20]; AgreementNo: Code[20]; LineAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(GenJournalLine, DocumentType, AccountType, AccountNo, LineAmount);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Validate("Agreement No.", AgreementNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostGenJnlLine(LineAmount: Decimal; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; AgreementNo: Code[20]; PostingDate: Date)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        CreateApplyPostGenJnlLine(PostingDate, GenJournalLine."Document Type"::Payment, AccType, AccNo, "Gen. Journal Document Type"::" ", '', AgreementNo, LineAmount);
    end;

    local procedure CreateApplyPost2GenJnlLines(Amount: Decimal; AccType: Enum "Gen. Journal Account Type"; AccNo: Code[20]; AgreementNo1: Code[20]; AgreementNo2: Code[20]; AppliesToDocNo: Code[20]): Decimal
    var
        GenJnlLine1: Record "Gen. Journal Line";
        GenJnlLine2: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(GenJnlLine1, GenJnlLine1."Document Type"::" ", AccType, AccNo, Amount);

        GenJnlLine2.Copy(GenJnlLine1);
        GenJnlLine2.Validate("Line No.", LibraryUtility.GetNewRecNo(GenJnlLine2, GenJnlLine2.FieldNo("Line No.")));
        GenJnlLine2.Validate(Amount, -Amount);
        GenJnlLine2.Insert(true);
        GenJnlLine2.Validate("Agreement No.", AgreementNo2);
        GenJnlLine2.Validate("Applies-to Doc. Type", GenJnlLine2."Applies-to Doc. Type"::Invoice);
        GenJnlLine2.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJnlLine2.Modify(true);

        GenJnlLine1.Validate("Agreement No.", AgreementNo1);
        GenJnlLine1.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJnlLine1);

        exit(GenJnlLine2.Amount);
    end;

    local procedure FindPaymentNo(CustomerNo: Code[20]): Code[20]
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Payment);
        CustLedgerEntry.FindFirst();
        exit(CustLedgerEntry."Document No.");
    end;

    local procedure GetRandomDateWithMonthShift(MonthShift: Integer): Date
    begin
        exit(
          LibraryRandom.RandDateFrom(
            CalcDate(
              StrSubstNo('<-CM + %1M>', MonthShift),
              WorkDate()), 20));
    end;

    local procedure GetAmountGreaterThan(Amount: Decimal): Decimal
    begin
        exit(Round(Amount * LibraryRandom.RandDecInDecimalRange(1.1, 1.9, 2)));
    end;

    local procedure PrintVendorReconciliation(VendorNo: Code[20]; ReportDate: Date)
    begin
        PrintVendorReconciliationRequestPage(VendorNo, ReportDate, false);
    end;

    local procedure PrintVendorReconciliationRequestPage(VendorNo: Code[20]; ReportDate: Date; UseRequestPage: Boolean)
    var
        Vendor: Record Vendor;
        VendorReconciliationAct: Report "Vendor - Reconciliation Act";
    begin
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        VendorReconciliationAct.InitializeRequest(ReportDate, ReportDate, LibraryReportValidation.GetFileName(), true);
        Vendor.SetRange("No.", VendorNo);
        VendorReconciliationAct.UseRequestPage(UseRequestPage);
        VendorReconciliationAct.SetTableView(Vendor);
        Commit();
        VendorReconciliationAct.Run();
    end;

    local procedure PrintCustomerReconciliation(CustomerNo1: Code[20]; CustomerNo2: Code[20]; ReportDate: Date)
    begin
        PrintCustomerReconciliationRequestPage(CustomerNo1, CustomerNo2, ReportDate, false);
    end;

    local procedure PrintCustomerReconciliationRequestPage(CustomerNo1: Code[20]; CustomerNo2: Code[20]; ReportDate: Date; UseRequestPage: Boolean)
    var
        Customer: Record Customer;
        CustomerReconciliationAct: Report "Customer - Reconciliation Act";
    begin
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        Clear(CustomerReconciliationAct);
        CustomerReconciliationAct.InitializeRequest(ReportDate, ReportDate, LibraryReportValidation.GetFileName(), true);
        if CustomerNo2 = '' then
            Customer.SetRange("No.", CustomerNo1)
        else
            Customer.SetFilter("No.", '%1|%2', CustomerNo1, CustomerNo2);
        CustomerReconciliationAct.UseRequestPage(UseRequestPage);
        CustomerReconciliationAct.SetTableView(Customer);
        Commit();
        CustomerReconciliationAct.Run();
    end;

    local procedure PrintCustomerReconciliationWithCurrency(CustomerNo: Code[20]; ReportDate: Date; CurrencyCode: Code[10])
    var
        Customer: Record Customer;
        CustomerReconciliationAct: Report "Customer - Reconciliation Act";
    begin
        LibraryVariableStorage.Enqueue(CurrencyCode);
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        Clear(CustomerReconciliationAct);
        CustomerReconciliationAct.InitializeRequest(ReportDate, ReportDate, LibraryReportValidation.GetFileName(), true);
        Customer.SetRange("No.", CustomerNo);
        CustomerReconciliationAct.UseRequestPage(true);
        CustomerReconciliationAct.SetTableView(Customer);
        Commit();
        CustomerReconciliationAct.Run();
    end;

    local procedure PrintReconciliation(IsVendorReconciliation: Boolean; VendorNo: Code[20]; CustomerNo: Code[20]; ReportDate: Date)
    begin
        if IsVendorReconciliation then
            PrintVendorReconciliation(VendorNo, ReportDate)
        else
            PrintCustomerReconciliation(CustomerNo, '', ReportDate);
    end;

    local procedure RunReconciliationForPurchase(ReportDate: Date; IsVendorReconciliation: Boolean; var InvoiceAmount: Decimal; var PaymentAmount: Decimal)
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        InvoiceNo: Code[20];
    begin
        Initialize();

        CreateCustomerVendor(Vendor, Customer);
        InvoiceNo := CreatePostPurchInvoice(Vendor."No.", InvoiceAmount, WorkDate());
        PaymentAmount := InvoiceAmount / 2;
        CreateApplyPostVendorPayment(Vendor."No.", InvoiceNo, PaymentAmount);

        PrintReconciliation(IsVendorReconciliation, Vendor."No.", Customer."No.", ReportDate)
    end;

    local procedure RunReconciliationForSales(ReportDate: Date; IsVendorReconciliation: Boolean; var InvoiceAmount: Decimal; var PaymentAmount: Decimal; InvoiceAmountLargerBy: Decimal)
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        InvoiceNo: Code[20];
    begin
        Initialize();

        CreateCustomerVendor(Vendor, Customer);
        InvoiceNo := CreatePostSalesInvoice(Customer."No.", InvoiceAmount, '', WorkDate());
        PaymentAmount := -InvoiceAmount / InvoiceAmountLargerBy;
        CreateApplyPostCustomerPayment(WorkDate(), Customer."No.", InvoiceNo, '', PaymentAmount);

        PrintReconciliation(IsVendorReconciliation, Vendor."No.", Customer."No.", ReportDate)
    end;

    local procedure CreateDataForSalesWithAgreements(ReportDate: Date; CurrencyCode: Code[10]; var InvoiceAmount1: Decimal; var InvoiceAmount2: Decimal; PaymentCoeff: Decimal; var SkippedInvoiceNo: Code[20]; var SkippedCreditMemoNo: Code[20]): Code[20]
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        GenJnlLine: Record "Gen. Journal Line";
        InvoiceNo: Code[20];
        AgreementNo1: Code[20];
        AgreementNo2: Code[20];
        PaymentAmount: Decimal;
    begin
        CreateCustomerVendor(Vendor, Customer);
        Customer.Validate("Currency Code", CurrencyCode);
        Customer.Validate("Agreement Posting", Customer."Agreement Posting"::Mandatory);
        Customer.Modify();
        AgreementNo1 := CreateCustomerAgreement(Customer."No.", true);
        AgreementNo2 := CreateCustomerAgreement(Customer."No.", true);

        // invoice in previous period, agreement 1:
        InvoiceNo := CreatePostSalesInvoice(Customer."No.", InvoiceAmount1, AgreementNo1, CalcDate('<-1D>', ReportDate));
        // partial payment in previous period, agreement 1, applied to the invoice:
        CreateApplyPostCustomerPayment(
          CalcDate('<-1D>', ReportDate), Customer."No.", InvoiceNo, AgreementNo1, -InvoiceAmount1 / PaymentCoeff);
        // invoice in current period, agreement 2:
        InvoiceNo := CreatePostSalesInvoice(Customer."No.", InvoiceAmount2, AgreementNo2, ReportDate);
        // credit memo in current period, agreement 2, as a storno:
        SkippedInvoiceNo := InvoiceNo;
        SkippedCreditMemoNo := CreatePostSalesCrMemo(Customer."No.", InvoiceNo, AgreementNo2);
        // invoice in current period, agreement 1:
        InvoiceNo := CreatePostSalesInvoice(Customer."No.", InvoiceAmount2, AgreementNo1, ReportDate);
        // greater payment in current period, agreement 2:
        PaymentAmount := -InvoiceAmount2 * PaymentCoeff;
        CreatePostGenJnlLine(PaymentAmount, GenJnlLine."Account Type"::Customer, Customer."No.", AgreementNo2, ReportDate);
        // payment transfer from agreement 2 to agreement 1, partially applied to the invoice:
        CreateApplyPost2GenJnlLines(-PaymentAmount, GenJnlLine."Account Type"::Customer, Customer."No.",
          AgreementNo2, AgreementNo1, InvoiceNo);

        exit(Customer."No.");
    end;

    local procedure CreateDataForSalesWithFuturePayment(ReportDate: Date; var InvoiceAmount: Decimal): Code[20]
    var
        Vendor: Record Vendor;
        Customer: Record Customer;
        InvoiceNo: Code[20];
    begin
        CreateCustomerVendor(Vendor, Customer);
        InvoiceAmount := LibraryRandom.RandDec(100, 2);
        InvoiceNo := CreatePostSalesInvoice(Customer."No.", InvoiceAmount, '', ReportDate - 1);
        CreateApplyPostCustomerPayment(ReportDate + 1, Customer."No.", InvoiceNo, '', -InvoiceAmount);

        exit(Customer."No.");
    end;

    local procedure CreatePostSalesInvoice(CustomerNo: Code[20]; var InvoiceAmount: Decimal; AgreementNo: Code[20]; PostingDate: Date): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Validate("Agreement No.", AgreementNo);
        SalesHeader.Modify(true);
        InvoiceAmount := CreateSalesDocGLAccountLine(SalesHeader);
        InvoiceAmount += CreateSalesDocGLAccountLine(SalesHeader);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePostSalesCrMemo(CustomerNo: Code[20]; InvoiceNo: Code[20]; AgreementNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateCorrectionSalesCreditMemo(SalesHeader, CustomerNo, InvoiceNo, AgreementNo);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePostSalesCrMemoWithTwoLines(PostingDate: Date; CustomerNo: Code[20]; var Amount: Decimal): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
        Amount := CreateSalesDocGLAccountLine(SalesHeader);
        Amount += CreateSalesDocGLAccountLine(SalesHeader);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateSalesDocGLAccountLine(SalesHeader: Record "Sales Header"): Decimal
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandIntInRange(1000, 2000));
        SalesLine.Modify(true);
        exit(SalesLine."Amount Including VAT");
    end;

    local procedure CreateCorrectionSalesCreditMemo(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; InvoiceNo: Code[20]; AgreementNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
        LibrarySales.CopySalesDocument(SalesHeader, "Sales Document Type From"::"Posted Invoice", InvoiceNo, true, false);
        SalesHeader.Validate("Agreement No.", AgreementNo);
        SalesHeader.Validate("Applies-to Doc. Type", SalesHeader."Applies-to Doc. Type"::Invoice);
        SalesHeader.Validate("Applies-to Doc. No.", InvoiceNo);
        SalesHeader.Modify();
    end;

    local procedure CreatePostPartialCorrectionSalesCrMemo(CustomerNo: Code[20]; InvoiceNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        CreateCorrectionSalesCreditMemo(SalesHeader, CustomerNo, InvoiceNo, '');
        DeleteLastSalesLine(SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreatePostPartialCorrectionSalesInvoice(CustomerNo: Code[20]; InvoiceNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        LibrarySales.CopySalesDocument(SalesHeader, "Sales Document Type From"::"Posted Credit Memo", InvoiceNo, true, false);
        SalesHeader.Validate("Applies-to Doc. Type", SalesHeader."Applies-to Doc. Type"::"Credit Memo");
        SalesHeader.Validate("Applies-to Doc. No.", InvoiceNo);
        SalesHeader.Modify();
        DeleteLastSalesLine(SalesHeader);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateCustomerVendor(var Vendor: Record Vendor; var Customer: Record Customer)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibrarySales.CreateCustomer(Customer);
        Vendor.Validate("Customer No.", Customer."No.");
        Vendor.Modify();
        Customer.Validate("Vendor No.", Vendor."No.");
        Customer.Modify();
    end;

    local procedure CreateCustomerAgreement(CustomerNo: Code[20]; IsActive: Boolean): Code[20]
    var
        CustomerAgreement: Record "Customer Agreement";
    begin
        CustomerAgreement.Init();
        CustomerAgreement."Customer No." := CustomerNo;
        CustomerAgreement.Active := IsActive;
        CustomerAgreement."Expire Date" := CalcDate('<1M>', WorkDate());
        CustomerAgreement.Insert(true);
        exit(CustomerAgreement."No.");
    end;

    local procedure DeleteLastSalesLine(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindLast();
        SalesLine.Delete(true);
    end;

    local procedure AmountAsText(value: Decimal): Text[250]
    begin
        if value = 0 then
            exit('');
        exit(Format(value, 0, '<Precision,2:2><Standard Format,0>'));
    end;

    local procedure VerifyCustReportWithAgreements(InvoiceAmount1: Decimal; InvoiceAmount2: Decimal; k: Decimal; SkippedInvoiceNo: Code[20]; SkippedCreditMemoNo: Code[20])
    var
        Found: Boolean;
        DocDescr: Text;
    begin
        // Aggregated customer initial balance is shown (Debit only),
        LibraryReportValidation.VerifyCellValue(13, 12, AmountAsText(InvoiceAmount1 - InvoiceAmount1 / k));
        LibraryReportValidation.VerifyCellValue(13, 14, '');
        LibraryReportValidation.VerifyCellValue(13, 18, '');
        LibraryReportValidation.VerifyCellValue(13, 20, AmountAsText(InvoiceAmount1 - InvoiceAmount1 / k));
        // Open invoice from previous period is shown,
        LibraryReportValidation.VerifyCellValue(15, 1, '1');
        LibraryReportValidation.VerifyCellValue(15, 10, AmountAsText(InvoiceAmount1));
        LibraryReportValidation.VerifyCellValue(15, 12, AmountAsText(InvoiceAmount1));
        LibraryReportValidation.VerifyCellValue(15, 16, AmountAsText(InvoiceAmount1));
        LibraryReportValidation.VerifyCellValue(15, 20, AmountAsText(InvoiceAmount1));
        // Applied payment from previous period is shown,
        LibraryReportValidation.VerifyCellValue(16, 1, '1.1');
        LibraryReportValidation.VerifyCellValue(16, 10, AmountAsText(InvoiceAmount1 / k));
        LibraryReportValidation.VerifyCellValue(16, 14, AmountAsText(InvoiceAmount1 / k));
        LibraryReportValidation.VerifyCellValue(16, 16, AmountAsText(InvoiceAmount1 / k));
        LibraryReportValidation.VerifyCellValue(16, 18, AmountAsText(InvoiceAmount1 / k));
        // Aggregated ending balance for the invoice is shown (Debit only),
        LibraryReportValidation.VerifyCellValue(17, 12, AmountAsText(InvoiceAmount1 - InvoiceAmount1 / k));
        LibraryReportValidation.VerifyCellValue(17, 14, '');
        LibraryReportValidation.VerifyCellValue(17, 18, '');
        LibraryReportValidation.VerifyCellValue(17, 20, AmountAsText(InvoiceAmount1 - InvoiceAmount1 / k));
        // Payment transfer from agreement 2 for current period is shown (Debit),
        LibraryReportValidation.VerifyCellValue(19, 1, '1');
        LibraryReportValidation.VerifyCellValue(19, 10, AmountAsText(k * InvoiceAmount2));
        LibraryReportValidation.VerifyCellValue(19, 12, AmountAsText(k * InvoiceAmount2));
        LibraryReportValidation.VerifyCellValue(19, 16, AmountAsText(k * InvoiceAmount2));
        LibraryReportValidation.VerifyCellValue(19, 20, AmountAsText(k * InvoiceAmount2));
        // Payment transfer to agreement 1 for current period is shown (Credit),
        LibraryReportValidation.VerifyCellValue(21, 1, '2');
        LibraryReportValidation.VerifyCellValue(21, 10, AmountAsText(k * InvoiceAmount2));
        LibraryReportValidation.VerifyCellValue(21, 14, AmountAsText(InvoiceAmount2));
        LibraryReportValidation.VerifyCellValue(21, 16, AmountAsText(k * InvoiceAmount2));
        LibraryReportValidation.VerifyCellValue(21, 18, AmountAsText(InvoiceAmount2));
        // Applied invoice (agreement 1) for current period is shown (Debit),
        LibraryReportValidation.VerifyCellValue(22, 1, '2.1');
        LibraryReportValidation.VerifyCellValue(22, 10, AmountAsText(InvoiceAmount2));
        LibraryReportValidation.VerifyCellValue(22, 12, AmountAsText(InvoiceAmount2));
        LibraryReportValidation.VerifyCellValue(22, 16, AmountAsText(InvoiceAmount2));
        LibraryReportValidation.VerifyCellValue(22, 20, AmountAsText(InvoiceAmount2));
        // Invoice, cancelled by Credit Memo, is skipped
        DocDescr := LibraryReportValidation.GetValueAt(Found, 24, 5);
        Assert.AreEqual(0, StrPos(DocDescr, SkippedInvoiceNo), 'Invoice to be skipped is detected');
        // Credit Memo, cancelling the Invoice, is skipped
        Assert.AreEqual(0, StrPos(DocDescr, SkippedCreditMemoNo), 'Credit Memo to be skipped is detected');
        // Invoice (agreement 1) for current period is shown (Debit),
        LibraryReportValidation.VerifyCellValue(24, 1, '3');
        LibraryReportValidation.VerifyCellValue(24, 10, AmountAsText(InvoiceAmount2));
        LibraryReportValidation.VerifyCellValue(24, 12, AmountAsText(InvoiceAmount2));
        LibraryReportValidation.VerifyCellValue(24, 16, AmountAsText(InvoiceAmount2));
        LibraryReportValidation.VerifyCellValue(24, 20, AmountAsText(InvoiceAmount2));
        // Applied Payment transfer to agreement 1 for current period is shown (Credit),
        LibraryReportValidation.VerifyCellValue(25, 1, '3.1');
        LibraryReportValidation.VerifyCellValue(25, 10, AmountAsText(k * InvoiceAmount2));
        LibraryReportValidation.VerifyCellValue(25, 14, AmountAsText(InvoiceAmount2));
        LibraryReportValidation.VerifyCellValue(25, 16, AmountAsText(k * InvoiceAmount2));
        LibraryReportValidation.VerifyCellValue(25, 18, AmountAsText(InvoiceAmount2));
        // Payment (agreement 2) for current period is shown (Credit),
        LibraryReportValidation.VerifyCellValue(28, 1, '1');
        LibraryReportValidation.VerifyCellValue(28, 10, AmountAsText(k * InvoiceAmount2));
        LibraryReportValidation.VerifyCellValue(28, 14, AmountAsText(k * InvoiceAmount2));
        LibraryReportValidation.VerifyCellValue(28, 16, AmountAsText(k * InvoiceAmount2));
        LibraryReportValidation.VerifyCellValue(28, 18, AmountAsText(k * InvoiceAmount2));
        // Debit and Credit turnovers for current period are shown,
        LibraryReportValidation.VerifyCellValue(30, 12, AmountAsText((k + 1) * InvoiceAmount2));
        LibraryReportValidation.VerifyCellValue(30, 14, AmountAsText(k * 2 * InvoiceAmount2));
        LibraryReportValidation.VerifyCellValue(30, 18, AmountAsText(k * 2 * InvoiceAmount2));
        LibraryReportValidation.VerifyCellValue(30, 20, AmountAsText((k + 1) * InvoiceAmount2));
        // Aggregated customer ending balance is shown (Credit only),
        LibraryReportValidation.VerifyCellValue(31, 12, '');
        LibraryReportValidation.VerifyCellValue(31, 14, AmountAsText(InvoiceAmount2 * (k - 1) - InvoiceAmount1 * (1 - 1 / k)));
        LibraryReportValidation.VerifyCellValue(31, 18, AmountAsText(InvoiceAmount2 * (k - 1) - InvoiceAmount1 * (1 - 1 / k)));
        LibraryReportValidation.VerifyCellValue(31, 20, '');
        // Aggregated customer/vendor starting balance is shown (Debit only),
        LibraryReportValidation.VerifyCellValue(38, 12, AmountAsText(InvoiceAmount1 - InvoiceAmount1 / k));
        LibraryReportValidation.VerifyCellValue(38, 20, AmountAsText(InvoiceAmount1 - InvoiceAmount1 / k));
        // Debit and Credit customer/vendor turnovers for current period are shown,
        LibraryReportValidation.VerifyCellValue(39, 12, AmountAsText((k + 1) * InvoiceAmount2));
        LibraryReportValidation.VerifyCellValue(39, 14, AmountAsText(k * 2 * InvoiceAmount2));
        LibraryReportValidation.VerifyCellValue(39, 18, AmountAsText(k * 2 * InvoiceAmount2));
        LibraryReportValidation.VerifyCellValue(39, 20, AmountAsText((k + 1) * InvoiceAmount2));
        // Aggregated customer/vendor ending balance is shown (Credit only)
        LibraryReportValidation.VerifyCellValue(40, 14, AmountAsText(InvoiceAmount2 * (k - 1) - InvoiceAmount1 * (1 - 1 / k)));
        LibraryReportValidation.VerifyCellValue(40, 18, AmountAsText(InvoiceAmount2 * (k - 1) - InvoiceAmount1 * (1 - 1 / k)));
    end;

    local procedure VerifyCustReportWithFuturePayment(InvoiceAmount: Decimal)
    var
        Found: Boolean;
    begin
        // Aggregated customer initial balance is shown (Debit only),
        LibraryReportValidation.VerifyCellValue(13, 12, AmountAsText(InvoiceAmount));
        LibraryReportValidation.VerifyCellValue(13, 14, '');
        LibraryReportValidation.VerifyCellValue(13, 18, '');
        LibraryReportValidation.VerifyCellValue(13, 20, AmountAsText(InvoiceAmount));
        // Invoice from previous period is shown,
        LibraryReportValidation.VerifyCellValue(15, 1, '1');
        LibraryReportValidation.VerifyCellValue(15, 10, AmountAsText(InvoiceAmount));
        LibraryReportValidation.VerifyCellValue(15, 12, AmountAsText(InvoiceAmount));
        LibraryReportValidation.VerifyCellValue(15, 16, AmountAsText(InvoiceAmount));
        LibraryReportValidation.VerifyCellValue(15, 20, AmountAsText(InvoiceAmount));
        // Applied payment from future period is NOT shown
        Assert.AreNotEqual(LibraryReportValidation.GetValueAt(Found, 16, 1), '1.1',
          'Applied payment from future period should NOT be shown');
    end;

    local procedure VerifyCustOldClosedInvoices(InvoiceAmount: Decimal; InvoiceNo: Code[20]; PaymentAmount: Decimal; PaymentNo: Code[20])
    begin
        VerifyCellContainsValue(15, 4, InvoiceNo);
        LibraryReportValidation.VerifyCellValue(15, 10, AmountAsText(InvoiceAmount));
        VerifyCellContainsValue(16, 4, PaymentNo);
        LibraryReportValidation.VerifyCellValue(16, 10, AmountAsText(PaymentAmount));
    end;

    local procedure VerifyCellContainsValue(RowId: Integer; ColumnId: Integer; ExpectedValue: Text)
    var
        ValueFound: Boolean;
    begin
        Assert.IsTrue(
          StrPos(LibraryReportValidation.GetValueAt(ValueFound, RowId, ColumnId), ExpectedValue) <> 0,
          StrSubstNo(CellDoesNotContainValueErr, RowId, ColumnId, ExpectedValue));
    end;

    local procedure VerifyCustomerZeroTurnoverLine()
    begin
        VerifyCustTurnoverAndSaldoForSingleDoc(53, 0, 0, 0);
    end;

    local procedure VerifySalesCreditMemoPositiveCreditAmount(Amount: Decimal)
    begin
        VerifyCustTurnoverAndSaldoForSingleDoc(15, Amount, 0, Amount);
    end;

    local procedure VerifySalesCreditMemoNegativeDebitAmount(Amount: Decimal)
    begin
        VerifyCustTurnoverAndSaldoForSingleDoc(15, Amount, -Amount, 0);
    end;

    local procedure VerifyCustTurnoverAndSaldoForSingleDoc(RowNo: Integer; DocAmount: Decimal; DebitAmount: Decimal; CreditAmount: Decimal)
    begin
        LibraryReportValidation.VerifyCellValue(RowNo, 10, AmountAsText(DocAmount));
        LibraryReportValidation.VerifyCellValue(RowNo, 12, AmountAsText(DebitAmount));
        LibraryReportValidation.VerifyCellValue(RowNo, 14, AmountAsText(CreditAmount));
        RowNo += 1;
        LibraryReportValidation.VerifyCellValue(RowNo, 10, '');
        LibraryReportValidation.VerifyCellValue(RowNo, 12, AmountAsText(DebitAmount));
        LibraryReportValidation.VerifyCellValue(RowNo, 14, AmountAsText(CreditAmount));
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Text: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorReconciliationActRequestPageHandler(var VendorReconciliationAct: TestRequestPage "Vendor - Reconciliation Act")
    begin
        VendorReconciliationAct.ShowDetails.SetValue(0); // "Show Details" = "Full Detail"
        VendorReconciliationAct.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CustomerReconciliationActRequestPageHandler(var "Report": TestRequestPage "Customer - Reconciliation Act")
    begin
        Report.CurrencyCode.SetValue(LibraryVariableStorage.DequeueText());
        Report.OK().Invoke();
    end;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"File Management", 'OnBeforeDownloadHandler', '', false, false)]
    local procedure CopyServerFileToTargetOnBeforeDownloadHandler(ToFileName: Text; FromFileName: Text; var IsHandled: Boolean)
    var
        FileManagement: Codeunit "File Management";
    begin
        // In containers the client-side Download does not materialize the exported report file at the
        // server session path the test reads, so copy the server-side source file to the target path.
        if (FromFileName = '') or (ToFileName = '') then
            exit;
        if not FileManagement.ServerFileExists(FromFileName) then
            exit;
        FileManagement.CopyServerFile(FromFileName, ToFileName, true);
        IsHandled := true;
    end;
}

