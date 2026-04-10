codeunit 134262 "Bank Pmt. Appl. Tolerance"
{
    Subtype = Test;

    trigger OnRun()
    begin
        // [FEATURE] [Bank Payment Application] [Bank Reconciliation] [Match]
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        PaymentDiscAmountErr: Label 'Payment Discount Amount is incorrect in Detailed Cust. Ledger Entry.';

    [Test]
    [HandlerFunctions('MessageHandler,PmtTolWarningModalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesAppliedPmtEntryWithPmtToleranceWhenConfirmPmtDiscTolWarningOnAutomaticApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ToleranceAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Payment Tolerance]
        // [SCENARIO 380951] "Applied Payment Entry" includes "Payment Tolerance Amount" when automatically match "Bank Acc. Recon. Line" to Sales Invoice and confirm discount in "Payment Tolerance Warning" page
        Initialize();

        // [GIVEN] Payment Tolerance = 5%
        // [GIVEN] Sales Invoice with Posting Date = 01.01, "Pmt. Discount Date" = 10.01, Amount = 100
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        SalesPmtToleranceScenario(BankAccReconciliationLine, CustLedgerEntry, ToleranceAmount, false, true, -1);
        LibraryLowerPermissions.SetAccountReceivables();

        // [WHEN] Match Bank Acc. Reconciliation Line to Sales Invoice automatically and confirm discount in "Payment Tolerance Warning" page
        MatchBankReconLineAutomatically(BankAccReconciliationLine);

        // [THEN] "Applied Amount" in "Bank Account Reconciliation Line" is 95
        BankAccReconciliationLine.Find();
        BankAccReconciliationLine.TestField("Applied Amount", BankAccReconciliationLine."Statement Amount");

        // [THEN] "Applied Amount" is 100, "Applied Pmt. Discount" is 5 in "Applied Payment Entry" for Sales Invoice
        VerifyAppliedPmtEntry(
          BankAccReconciliationLine, CustLedgerEntry."Remaining Amount", ToleranceAmount);

        // [THEN] "Accepted Payment Tolerance" = 5 in Customer Ledger Entry for Sales Invoice
        CustLedgerEntry.Find();
        CustLedgerEntry.TestField("Accepted Payment Tolerance", ToleranceAmount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PmtTolWarningModalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesAppliedPmtEntryWithNoPmtToleranceWhenDoNotConfirmPmtDiscTolWarningOnAutomaticApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ToleranceAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Payment Tolerance]
        // [SCENARIO 380951] "Applied Payment Entry" does not include "Payment Tolerance Amount" when automatically match "Bank Acc. Recon. Line" to Sales Invoice and do not confirm discount in "Payment Tolerance Warning" page
        Initialize();

        // [GIVEN] Payment Tolerance = 5%
        // [GIVEN] Sales Invoice with Posting Date = 01.01, "Pmt. Discount Date" = 10.01, Amount = 100
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        SalesPmtToleranceScenario(BankAccReconciliationLine, CustLedgerEntry, ToleranceAmount, false, false, -1);
        LibraryLowerPermissions.SetAccountReceivables();

        // [WHEN] Match Bank Acc. Reconciliation Line to Sales Invoice automatically but do not confirm discount in "Payment Tolerance Warning" page
        MatchBankReconLineAutomatically(BankAccReconciliationLine);

        // [THEN] "Applied Amount" in "Bank Account Reconciliation Line" is 95
        BankAccReconciliationLine.Find();
        BankAccReconciliationLine.TestField("Applied Amount", BankAccReconciliationLine."Statement Amount");

        // [THEN] "Applied Amount" is 95, "Applied Pmt. Discount" is zero in "Applied Payment Entry" for Sales Invoice
        VerifyAppliedPmtEntry(
          BankAccReconciliationLine, BankAccReconciliationLine."Statement Amount", 0);

        // [THEN] "Accepted Pmt. Disc. Tolerance" is FALSE in Customer Ledger Entry for Sales Invoice
        CustLedgerEntry.Find();
        CustLedgerEntry.TestField("Accepted Payment Tolerance", 0);
    end;

    [Test]
    [HandlerFunctions('PaymentApplicationModalPageHandler,PmtTolWarningModalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesAppliedPmtEntryWithPmtToleranceWhenConfirmPmtDiscTolWarningOnManualApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ToleranceAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Payment Tolerance]
        // [SCENARIO 380951] "Applied Payment Entry" includes "Payment Tolerance Amount" when manually match "Bank Acc. Recon. Line" to Sales Invoice and confirm discount in "Payment Tolerance Warning" page
        Initialize();

        // [GIVEN] Payment Tolerance = 5%
        // [GIVEN] Sales Invoice with Posting Date = 01.01, "Pmt. Discount Date" = 10.01, Amount = 100
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        SalesPmtToleranceScenario(BankAccReconciliationLine, CustLedgerEntry, ToleranceAmount, true, true, -1);
        LibraryLowerPermissions.SetAccountReceivables();

        // [WHEN] Match Bank Acc. Reconciliation Line to Sales Invoice manually and confirm discount in "Payment Tolerance Warning" page
        MatchBankReconLineManually(BankAccReconciliationLine);

        // [THEN] "Applied Amount" in "Bank Account Reconciliation Line" is 95
        BankAccReconciliationLine.Find();
        BankAccReconciliationLine.TestField("Applied Amount", BankAccReconciliationLine."Statement Amount");

        // [THEN] "Applied Amount" is 100, "Applied Pmt. Discount" is 5 in "Applied Payment Entry" for Sales Invoice
        VerifyAppliedPmtEntry(
          BankAccReconciliationLine, CustLedgerEntry."Remaining Amount", ToleranceAmount);

        // [THEN] "Accepted Payment Tolerance" = 5 in Customer Ledger Entry for Sales Invoice
        CustLedgerEntry.Find();
        CustLedgerEntry.TestField("Accepted Payment Tolerance", ToleranceAmount);
    end;

    [Test]
    [HandlerFunctions('PaymentApplicationModalPageHandler,PmtTolWarningModalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesAppliedPmtEntryWithNoPmtToleranceWhenDoNotConfirmPmtDiscTolWarningOnManualApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ToleranceAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Payment Tolerance]
        // [SCENARIO 380951] "Applied Payment Entry" does not include "Payment Tolerance Amount" when manually match "Bank Acc. Recon. Line" to Sales Invoice and do not confirm discount in "Payment Tolerance Warning" page
        Initialize();

        // [GIVEN] Payment Tolerance = 5%
        // [GIVEN] Sales Invoice with Posting Date = 01.01, "Pmt. Discount Date" = 10.01, Amount = 100
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        SalesPmtToleranceScenario(BankAccReconciliationLine, CustLedgerEntry, ToleranceAmount, true, false, -1);
        LibraryLowerPermissions.SetAccountReceivables();

        // [WHEN] Match Bank Acc. Reconciliation Line to Sales Invoice manually but do not confirm discount in "Payment Tolerance Warning" page
        MatchBankReconLineManually(BankAccReconciliationLine);

        // [THEN] "Applied Amount" in "Bank Account Reconciliation Line" is 95
        BankAccReconciliationLine.Find();
        BankAccReconciliationLine.TestField("Applied Amount", BankAccReconciliationLine."Statement Amount");

        // [THEN] "Applied Amount" is 95, "Applied Pmt. Discount" is zero in "Applied Payment Entry" for Sales Invoice
        VerifyAppliedPmtEntry(
          BankAccReconciliationLine, BankAccReconciliationLine."Statement Amount", 0);

        // [THEN] "Accepted Pmt. Disc. Tolerance" is FALSE in Customer Ledger Entry for Sales Invoice
        CustLedgerEntry.Find();
        CustLedgerEntry.TestField("Accepted Payment Tolerance", 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PmtDiscTolWarningModalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesAppliedPmtEntryWithPmtDiscToleranceWhenConfirmPmtDiscTolWarningOnAutomaticApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Sales] [Payment Discount Tolerance]
        // [SCENARIO 380951] "Applied Payment Entry" includes "Payment Dis. Tolerance Amount" when automatically match "Bank Acc. Recon. Line" to Sales Invoice and confirm discount in "Payment Discount Tolerance Warning" page
        Initialize();

        // [GIVEN] Sales Invoice with Posting Date = 01.01, "Pmt. Discount Tolerance Date" = 10.01, Amount = 100, "Payment Discount" = 5
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        SalesPmtTolDiscScenario(BankAccReconciliationLine, CustLedgerEntry, false, true);
        LibraryLowerPermissions.SetAccountReceivables();

        // [WHEN] Match Bank Acc. Reconciliation Line to Sales Invoice automatically and confirm discount in "Payment Discount Tolerance Warning" page
        MatchBankReconLineAutomatically(BankAccReconciliationLine);

        // [THEN] "Applied Amount" in "Bank Account Reconciliation Line" is 95
        BankAccReconciliationLine.Find();
        BankAccReconciliationLine.TestField("Applied Amount", BankAccReconciliationLine."Statement Amount");

        // [THEN] "Applied Amount" is 100, "Applied Pmt. Discount" is 5 in "Applied Payment Entry" for Sales Invoice
        VerifyAppliedPmtEntry(
          BankAccReconciliationLine, CustLedgerEntry."Remaining Amount", CustLedgerEntry."Remaining Pmt. Disc. Possible");

        // [THEN] "Accepted Pmt. Disc. Tolerance" is TRUE in Customer Ledger Entry for Sales Invoice
        CustLedgerEntry.Find();
        CustLedgerEntry.TestField("Accepted Pmt. Disc. Tolerance", true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PmtDiscTolWarningModalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesAppliedPmtEntryWithNoPmtDiscToleranceWhenDoNotConfirmPmtDiscTolWarningOnAutomaticApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Sales] [Payment Discount Tolerance]
        // [SCENARIO 380951] "Applied Payment Entry" does not include "Payment Dis. Tolerance Amount" when automatically match "Bank Acc. Recon. Line" to Sales Invoice and do not confirm discount in "Payment Discount Tolerance Warning" page
        Initialize();

        // [GIVEN] Sales Invoice with Posting Date = 01.01, "Pmt. Discount Tolerance Date" = 10.01, Amount = 100, "Payment Discount" = 5
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        SalesPmtTolDiscScenario(BankAccReconciliationLine, CustLedgerEntry, false, false);
        LibraryLowerPermissions.SetAccountReceivables();

        // [WHEN] Match Bank Acc. Reconciliation Line to Sales Invoice automatically but do not confirm discount in "Payment Discount Tolerance Warning" page
        MatchBankReconLineAutomatically(BankAccReconciliationLine);

        // [THEN] "Applied Amount" in "Bank Account Reconciliation Line" is 95
        BankAccReconciliationLine.Find();
        BankAccReconciliationLine.TestField("Applied Amount", BankAccReconciliationLine."Statement Amount");

        // [THEN] "Applied Amount" is 95, "Applied Pmt. Discount" is zero in "Applied Payment Entry" for Sales Invoice
        VerifyAppliedPmtEntry(
          BankAccReconciliationLine, BankAccReconciliationLine."Statement Amount", 0);

        // [THEN] "Accepted Pmt. Disc. Tolerance" is FALSE in Customer Ledger Entry for Sales Invoice
        CustLedgerEntry.Find();
        CustLedgerEntry.TestField("Accepted Pmt. Disc. Tolerance", false);
    end;

    [Test]
    [HandlerFunctions('PaymentApplicationModalPageHandler,PmtDiscTolWarningModalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesAppliedPmtEntryWithPmtDiscToleranceWhenConfirmPmtDiscTolWarningOnManualApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Sales] [Payment Discount Tolerance]
        // [SCENARIO 380951] "Applied Payment Entry" includes "Payment Dis. Tolerance Amount" when manually match "Bank Acc. Recon. Line" to Sales Invoice and confirm discount in "Payment Discount Tolerance Warning" page
        Initialize();

        // [GIVEN] Sales Invoice with Posting Date = 01.01, "Pmt. Discount Tolerance Date" = 10.01, Amount = 100, "Payment Discount" = 5
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        SalesPmtTolDiscScenario(BankAccReconciliationLine, CustLedgerEntry, true, true);
        LibraryLowerPermissions.SetAccountReceivables();

        // [WHEN] Match Bank Acc. Reconciliation Line to Sales Invoice manually and confirm discount in "Payment Discount Tolerance Warning" page
        MatchBankReconLineManually(BankAccReconciliationLine);

        // [THEN] "Applied Amount" in "Bank Account Reconciliation Line" is 95
        BankAccReconciliationLine.Find();
        BankAccReconciliationLine.TestField("Applied Amount", BankAccReconciliationLine."Statement Amount");

        // [THEN] "Applied Amount" is 100, "Applied Pmt. Discount" is 5 in "Applied Payment Entry" for Sales Invoice
        VerifyAppliedPmtEntry(
          BankAccReconciliationLine, CustLedgerEntry."Remaining Amount", CustLedgerEntry."Remaining Pmt. Disc. Possible");

        // [THEN] "Accepted Pmt. Disc. Tolerance" is TRUE in Customer Ledger Entry for Sales Invoice
        CustLedgerEntry.Find();
        CustLedgerEntry.TestField("Accepted Pmt. Disc. Tolerance", true);
    end;

    [Test]
    [HandlerFunctions('PaymentApplicationModalPageHandler,PmtDiscTolWarningModalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesAppliedPmtEntryWithNoPmtDiscToleranceWhenDoNotConfirmPmtDiscTolWarningOnManualApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Sales] [Payment Discount Tolerance]
        // [SCENARIO 380951] "Applied Payment Entry" includes "Payment Dis. Tolerance Amount" when manually match "Bank Acc. Recon. Line" to Sales Invoice but do not confirm discount in "Payment Discount Tolerance Warning" page
        Initialize();

        // [GIVEN] Sales Invoice with Posting Date = 01.01, "Pmt. Discount Tolerance Date" = 10.01, Amount = 100, "Payment Discount" = 5
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        SalesPmtTolDiscScenario(BankAccReconciliationLine, CustLedgerEntry, true, false);
        LibraryLowerPermissions.SetAccountReceivables();

        // [WHEN] Match Bank Acc. Reconciliation Line to Sales Invoice manually but do not confirm discount in "Payment Discount Tolerance Warning" page
        MatchBankReconLineManually(BankAccReconciliationLine);

        // [THEN] "Applied Amount" in "Bank Account Reconciliation Line" is 95
        BankAccReconciliationLine.Find();
        BankAccReconciliationLine.TestField("Applied Amount", BankAccReconciliationLine."Statement Amount");

        // [THEN] "Applied Amount" is 95, "Applied Pmt. Discount" is zero in "Applied Payment Entry" for Sales Invoice
        VerifyAppliedPmtEntry(BankAccReconciliationLine, BankAccReconciliationLine."Statement Amount", 0);

        // [THEN] "Accepted Pmt. Disc. Tolerance" is FALSE in Customer Ledger Entry for Sales Invoice
        CustLedgerEntry.Find();
        CustLedgerEntry.TestField("Accepted Pmt. Disc. Tolerance", false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PmtTolWarningModalPageHandler,ConfirmHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure SalesPmtToleranceWhenConfirmPmtDiscTolWarningOnAutomaticApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        ToleranceAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Payment Tolerance]
        // [SCENARIO 380951] "Payment Tolerance" detailed ledger entry is created when automatically match "Bank Acc. Recon. Line" to Sales Invoice and confirm discount in "Payment Tolerance Warning" page
        Initialize();

        // [GIVEN] Payment Tolerance = 5%
        // [GIVEN] Sales Invoice with Posting Date = 01.01, "Pmt. Discount Date" = 10.01, Amount = 100
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        SalesPmtToleranceScenario(BankAccReconciliationLine, CustLedgerEntry, ToleranceAmount, false, true, -1);
        LibraryLowerPermissions.SetAccountReceivables();

        // [GIVEN] Bank Acc. Reconciliation Line and Sales Invoice automatically matched and discount in "Payment Discount Tolerance Warning" page is confirmed
        MatchBankReconLineAutomatically(BankAccReconciliationLine);

        LibraryVariableStorage.Enqueue(true); // Set "Yes" on "Payment Tolerance Warning" page
        // [WHEN] Post Bank Account Reconciliation
        PostReconciliation(BankAccReconciliationLine);

        // [THEN] Payment from Bank Acc. Reconciliation Line applied fully to Invoice ("Remaining Amount" is zero)
        VerifyCustLedgEntry(CustLedgerEntry."Entry No.", 0);

        // [THEN] Detailed Ledger Entry "Payment Tolerance" with Amount = 5 for Sales Invoice is created
        FilterPmtDiscToleranceDtldCustLedgEntry(
          DetailedCustLedgEntry, DetailedCustLedgEntry."Entry Type"::"Payment Tolerance", BankAccReconciliationLine."Statement No.",
          CustLedgerEntry."Customer No.");
        DetailedCustLedgEntry.FindFirst();
        DetailedCustLedgEntry.TestField(Amount, -ToleranceAmount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PmtTolWarningModalPageHandler,ConfirmHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure NoSalesPmtToleranceWhenDoNotConfirmPmtDiscTolWarningOnAutomaticApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        ToleranceAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Payment Tolerance]
        // [SCENARIO 380951] "Payment Tolerance" detailed ledger entries are not created when automatically match "Bank Acc. Recon. Line" to Sales Invoice but do not confirm discount in "Payment Tolerance Warning" page
        Initialize();

        // [GIVEN] Payment Tolerance = 5%
        // [GIVEN] Sales Invoice with Posting Date = 01.01, "Pmt. Discount Date" = 10.01, Amount = 100
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        SalesPmtToleranceScenario(BankAccReconciliationLine, CustLedgerEntry, ToleranceAmount, false, false, -1);
        LibraryLowerPermissions.SetAccountReceivables();

        // [GIVEN] Bank Acc. Reconciliation Line and Sales Invoice automatically matched and discount in "Payment Discount Tolerance Warning" page is not confirmed
        MatchBankReconLineAutomatically(BankAccReconciliationLine);

        // [WHEN] Post Bank Account Reconciliation
        PostReconciliation(BankAccReconciliationLine);

        // [THEN] Payment from Bank Acc. Reconciliation Line applied not fully to Invoice ("Remaining Amount" = 5)
        VerifyCustLedgEntry(CustLedgerEntry."Entry No.", ToleranceAmount);

        // [THEN] No Detailed Ledger Entry "Payment Tolerance" for Sales Invoice is created
        FilterPmtDiscToleranceDtldCustLedgEntry(
          DetailedCustLedgEntry, DetailedCustLedgEntry."Entry Type"::"Payment Tolerance", BankAccReconciliationLine."Statement No.",
          CustLedgerEntry."Customer No.");
        Assert.RecordIsEmpty(DetailedCustLedgEntry);
    end;

    [Test]
    [HandlerFunctions('PaymentApplicationModalPageHandler,PmtTolWarningModalPageHandler,ConfirmHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure SalesPmtToleranceWhenConfirmPmtDiscTolWarningOnManualApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        ToleranceAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Payment Tolerance]
        // [SCENARIO 380951] "Payment Tolerance" detailed ledger entry is created when manually match "Bank Acc. Recon. Line" to Sales Invoice and confirm discount in "Payment Tolerance Warning" page
        Initialize();

        // [GIVEN] Payment Tolerance = 5%
        // [GIVEN] Sales Invoice with Posting Date = 01.01, "Pmt. Discount Date" = 10.01, Amount = 100
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        SalesPmtToleranceScenario(BankAccReconciliationLine, CustLedgerEntry, ToleranceAmount, true, true, -1);
        LibraryLowerPermissions.SetAccountReceivables();

        // [GIVEN] Bank Acc. Reconciliation Line and Sales Invoice manually matched and discount in "Payment Discount Tolerance Warning" page is confirmed
        MatchBankReconLineManually(BankAccReconciliationLine);
        LibraryVariableStorage.Enqueue(true); // Set "Yes" on "Payment Tolerance Warning" page

        // [WHEN] Post Bank Account Reconciliation
        PostReconciliation(BankAccReconciliationLine);

        // [THEN] Payment from Bank Acc. Reconciliation Line applied fully to Invoice ("Remaining Amount" is zero)
        VerifyCustLedgEntry(CustLedgerEntry."Entry No.", 0);

        // [THEN] Detailed Ledger Entry "Payment Tolerance" with Amount = 5 for Sales Invoice is created
        FilterPmtDiscToleranceDtldCustLedgEntry(
          DetailedCustLedgEntry, DetailedCustLedgEntry."Entry Type"::"Payment Tolerance", BankAccReconciliationLine."Statement No.",
          CustLedgerEntry."Customer No.");
        DetailedCustLedgEntry.FindFirst();
        DetailedCustLedgEntry.TestField(Amount, -ToleranceAmount);
    end;

    [Test]
    [HandlerFunctions('PaymentApplicationModalPageHandler,PmtTolWarningModalPageHandler,ConfirmHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure NoSalesPmtToleranceWhenDoNotConfirmPmtDiscTolWarningOnManualApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        ToleranceAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Payment Tolerance]
        // [SCENARIO 380951] "Payment Tolerance" detailed ledger entry is created when manually match "Bank Acc. Recon. Line" to Sales Invoice but do not confirm discount in "Payment Tolerance Warning" page
        Initialize();

        // [GIVEN] Payment Tolerance = 5%
        // [GIVEN] Sales Invoice with Posting Date = 01.01, "Pmt. Discount Date" = 10.01, Amount = 100
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        SalesPmtToleranceScenario(BankAccReconciliationLine, CustLedgerEntry, ToleranceAmount, true, false, -1);

        // [GIVEN] Bank Acc. Reconciliation Line and Sales Invoice manually matched and discount in "Payment Discount Tolerance Warning" page is not confirmed
        MatchBankReconLineManually(BankAccReconciliationLine);
        LibraryLowerPermissions.SetAccountReceivables();

        // [WHEN] Post Bank Account Reconciliation
        PostReconciliation(BankAccReconciliationLine);

        // [THEN] Payment from Bank Acc. Reconciliation Line applied not fully to Invoice ("Remaining Amount" = 5)
        VerifyCustLedgEntry(CustLedgerEntry."Entry No.", ToleranceAmount);

        // [THEN] No Detailed Ledger Entry "Payment Tolerance" for Sales Invoice is created
        FilterPmtDiscToleranceDtldCustLedgEntry(
          DetailedCustLedgEntry, DetailedCustLedgEntry."Entry Type"::"Payment Tolerance", BankAccReconciliationLine."Statement No.",
          CustLedgerEntry."Customer No.");
        Assert.RecordIsEmpty(DetailedCustLedgEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PmtDiscTolWarningModalPageHandler,ConfirmHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure SalesPmtDiscToleranceWhenConfirmPmtDiscTolWarningOnAutomaticApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // [FEATURE] [Sales] [Payment Discount Tolerance]
        // [SCENARIO 380920] "Pmt. Discout Tolerance" detailed ledger entry is created when automatically match "Bank Acc. Recon. Line" to Sales Invoice and confirm discount in "Payment Discount Tolerance Warning" page
        Initialize();

        // [GIVEN] Sales Invoice with Posting Date = 01.01, "Pmt. Discount Tolerance Date" = 10.01, Amount = 100, "Payment Discount" = 5
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        SalesPmtTolDiscScenario(BankAccReconciliationLine, CustLedgerEntry, false, true);

        // [GIVEN] Bank Acc. Reconciliation Line and Sales Invoice automatically matched and discount in "Payment Discount Tolerance Warning" page is confirmed
        MatchBankReconLineAutomatically(BankAccReconciliationLine);
        LibraryVariableStorage.Enqueue(true); // Set "Yes" on "Payment Discount Tolerance Warning" page
        LibraryLowerPermissions.SetAccountReceivables();

        // [WHEN] Post Bank Account Reconciliation
        PostReconciliation(BankAccReconciliationLine);

        // [THEN] Payment from Bank Acc. Reconciliation Line applied fully to Invoice ("Remaining Amount" is zero)
        VerifyCustLedgEntry(CustLedgerEntry."Entry No.", 0);

        // [THEN] Detailed Ledger Entry "Pmt. Discount Tolerance" with Amount = 5 for Sales Invoice is created
        FilterPmtDiscToleranceDtldCustLedgEntry(
          DetailedCustLedgEntry, DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance",
          BankAccReconciliationLine."Statement No.", CustLedgerEntry."Customer No.");
        DetailedCustLedgEntry.FindFirst();
        DetailedCustLedgEntry.TestField(Amount, -CustLedgerEntry."Original Pmt. Disc. Possible");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PmtDiscTolWarningModalPageHandler,ConfirmHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure NoSalesPmtDiscToleranceWhenDoNotConfirmPmtDiscTolWarningOnAutomaticApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // [FEATURE] [Sales] [Payment Discount Tolerance]
        // [SCENARIO 380920] "Pmt. Discout Tolerance" detailed ledger entries are not created when automatically match "Bank Acc. Recon. Line" to Sales Invoice but do not confirm discount in "Payment Discount Tolerance Warning" page
        Initialize();

        // [GIVEN] Sales Invoice with Posting Date = 01.01, "Pmt. Discount Tolerance Date" = 10.01, Amount = 100, "Payment Discount" = 5
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        SalesPmtTolDiscScenario(BankAccReconciliationLine, CustLedgerEntry, false, false);

        // [GIVEN] Bank Acc. Reconciliation Line and Sales Invoice automatically matched and discount in "Payment Discount Tolerance Warning" page is not confirmed
        MatchBankReconLineAutomatically(BankAccReconciliationLine);
        LibraryVariableStorage.Enqueue(false); // Set "No" on "Payment Discount Tolerance Warning" page
        LibraryLowerPermissions.SetAccountReceivables();

        // [WHEN] Post Bank Account Reconciliation
        PostReconciliation(BankAccReconciliationLine);

        // [THEN] Payment from Bank Acc. Reconciliation Line applied not fully to Invoice ("Remaining Amount" = 5)
        VerifyCustLedgEntry(CustLedgerEntry."Entry No.", CustLedgerEntry."Original Pmt. Disc. Possible");

        // [THEN] No Detailed Ledger Entry "Pmt. Discount Tolerance" for Sales Invoice is created
        FilterPmtDiscToleranceDtldCustLedgEntry(
          DetailedCustLedgEntry, DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance",
          BankAccReconciliationLine."Statement No.", CustLedgerEntry."Customer No.");
        Assert.RecordIsEmpty(DetailedCustLedgEntry);
    end;

    [Test]
    [HandlerFunctions('PaymentApplicationModalPageHandler,PmtDiscTolWarningModalPageHandler,ConfirmHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure SalesPmtDiscToleranceWhenConfirmPmtDiscTolWarningOnManualApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // [FEATURE] [Sales] [Payment Discount Tolerance]
        // [SCENARIO 380920] "Pmt. Discout Tolerance" detailed ledger entry is created when manually match "Bank Acc. Recon. Line" to Sales Invoice and confirm discount in "Payment Discount Tolerance Warning" page
        Initialize();

        // [GIVEN] Sales Invoice with Posting Date = 01.01, "Pmt. Discount Tolerance Date" = 10.01, Amount = 100, "Payment Discount" = 5
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        SalesPmtTolDiscScenario(BankAccReconciliationLine, CustLedgerEntry, true, true);

        // [GIVEN] Bank Acc. Reconciliation Line and Sales Invoice manually matched and discount in "Payment Discount Tolerance Warning" page is confirmed
        MatchBankReconLineManually(BankAccReconciliationLine);
        LibraryVariableStorage.Enqueue(true); // Set "Yes" on "Payment Discount Tolerance Warning" page
        LibraryLowerPermissions.SetAccountReceivables();

        // [WHEN] Post Bank Account Reconciliation
        PostReconciliation(BankAccReconciliationLine);

        // [THEN] Payment from Bank Acc. Reconciliation Line applied fully to Invoice ("Remaining Amount" is zero)
        VerifyCustLedgEntry(CustLedgerEntry."Entry No.", 0);

        // [THEN] Detailed Ledger Entry "Pmt. Discount Tolerance" with Amount = 5 for Sales Invoice is created
        FilterPmtDiscToleranceDtldCustLedgEntry(
          DetailedCustLedgEntry, DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance",
          BankAccReconciliationLine."Statement No.", CustLedgerEntry."Customer No.");
        DetailedCustLedgEntry.FindFirst();
        DetailedCustLedgEntry.TestField(Amount, -CustLedgerEntry."Original Pmt. Disc. Possible");
    end;

    [Test]
    [HandlerFunctions('PaymentApplicationModalPageHandler,PmtDiscTolWarningModalPageHandler,ConfirmHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure NoSalesPmtDiscToleranceWhenDoNotConfirmPmtDiscTolWarningOnManualApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // [FEATURE] [Sales] [Payment Discount Tolerance]
        // [SCENARIO 380920] "Pmt. Discout Tolerance" detailed ledger entry is created when manually match "Bank Acc. Recon. Line" to Sales Invoice but do not confirm discount in "Payment Discount Tolerance Warning" page
        Initialize();

        // [GIVEN] Sales Invoice with Posting Date = 01.01, "Pmt. Discount Tolerance Date" = 10.01, Amount = 100, "Payment Discount" = 5
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        SalesPmtTolDiscScenario(BankAccReconciliationLine, CustLedgerEntry, true, false);
        LibraryVariableStorage.Enqueue(false); // Set "No" on "Payment Discount Tolerance Warning" page

        // [GIVEN] Bank Acc. Reconciliation Line and Sales Invoice manually matched and discount in "Payment Discount Tolerance Warning" page is not confirmed
        MatchBankReconLineManually(BankAccReconciliationLine);
        LibraryVariableStorage.Enqueue(false); // Set "No" on "Payment Discount Tolerance Warning" page
        LibraryLowerPermissions.SetAccountReceivables();

        // [WHEN] Post Bank Account Reconciliation
        PostReconciliation(BankAccReconciliationLine);

        // [THEN] Payment from Bank Acc. Reconciliation Line applied not fully to Invoice ("Remaining Amount" = 5)
        VerifyCustLedgEntry(CustLedgerEntry."Entry No.", CustLedgerEntry."Original Pmt. Disc. Possible");

        // [THEN] No Detailed Ledger Entry "Pmt. Discount Tolerance" for Sales Invoice is created
        FilterPmtDiscToleranceDtldCustLedgEntry(
          DetailedCustLedgEntry, DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance",
          BankAccReconciliationLine."Statement No.", CustLedgerEntry."Customer No.");
        Assert.RecordIsEmpty(DetailedCustLedgEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PmtDiscTolWarningModalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ClearSalesAcceptedPmtDiscToleranceWhenRemoveBankAccReconciliation()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Sales] [Payment Discount Tolerance]
        // [SCENARIO 380951] "Accepted Pmt. Disc. Tolerance" and "Amount to Apply" clears out when remove Bank Account Reconciliation previously applied to Sales Invoice with Payment Discount Tolerance
        Initialize();

        // [GIVEN] Sales Invoice with Posting Date = 01.01, "Pmt. Discount Tolerance Date" = 10.01, Amount = 100, "Payment Discount" = 5
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        SalesPmtTolDiscScenario(BankAccReconciliationLine, CustLedgerEntry, false, true);

        // [GIVEN] Bank Acc. Reconciliation Line and Sales Invoice automatically matched and discount in "Payment Discount Tolerance Warning" page is confirmed
        MatchBankReconLineAutomatically(BankAccReconciliationLine);
        LibraryLowerPermissions.SetAccountReceivables();

        // [WHEN] Delete Bank Account Reconciliation Line
        BankAccReconciliationLine.Delete(true);

        // [THEN] "Accepted Pmt. Disc. Tolerance" is FALSE in Customer Ledger Entry for Sales Invoice
        CustLedgerEntry.Find();
        CustLedgerEntry.TestField("Accepted Pmt. Disc. Tolerance", false);

        // [THEN] Amount to Apply = 0 in Customer Ledger Entry for Sales Invoice
        CustLedgerEntry.TestField("Amount to Apply", 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PmtTolWarningModalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ClearSalesAcceptedPmtToleranceWhenRemoveBankAccReconciliation()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        ToleranceAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Payment Tolerance]
        // [SCENARIO 380951] "Accepted Payment Tolerance" and "Amount to Apply" clears out when remove Bank Account Reconciliation previously applied to Sales Invoice with Payment Discount Tolerance
        Initialize();

        // [GIVEN] Payment Tolerance = 5%
        // [GIVEN] Sales Invoice with Posting Date = 01.01, "Pmt. Discount Date" = 10.01, Amount = 100
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        SalesPmtToleranceScenario(BankAccReconciliationLine, CustLedgerEntry, ToleranceAmount, false, true, -1);

        // [GIVEN] Bank Acc. Reconciliation Line and Sales Invoice automatically matched and discount in "Payment Discount Tolerance Warning" page is confirmed
        MatchBankReconLineAutomatically(BankAccReconciliationLine);
        LibraryLowerPermissions.SetAccountReceivables();

        // [WHEN] Delete Bank Account Reconciliation Line
        BankAccReconciliationLine.Delete(true);

        // [THEN] "Accepted Payment Tolerance" is 0 in Customer Ledger Entry for Sales Invoice
        CustLedgerEntry.Find();
        CustLedgerEntry.TestField("Accepted Payment Tolerance", 0);

        // [THEN] Amount to Apply = 0 in Customer Ledger Entry for Sales Invoice
        CustLedgerEntry.TestField("Amount to Apply", 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PmtTolWarningModalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchAppliedPmtEntryWithPmtToleranceWhenConfirmPmtDiscTolWarningOnAutomaticApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        ToleranceAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Payment Tolerance]
        // [SCENARIO 380951] "Applied Payment Entry" includes "Payment Tolerance Amount" when automatically match "Bank Acc. Recon. Line" to Purchase Invoice and confirm discount in "Payment Tolerance Warning" page
        Initialize();

        // [GIVEN] Payment Tolerance = 5%
        // [GIVEN] Purchase Invoice with Posting Date = 01.01, "Pmt. Discount Date" = 10.01, Amount = 100
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        PurchPmtToleranceScenario(BankAccReconciliationLine, VendLedgerEntry, ToleranceAmount, false, true, -1);

        LibraryLowerPermissions.SetBanking();

        // [WHEN] Match Bank Acc. Reconciliation Line to Purchase Invoice automatically and confirm discount in "Payment Tolerance Warning" page
        MatchBankReconLineAutomatically(BankAccReconciliationLine);

        // [THEN] "Applied Amount" in "Bank Account Reconciliation Line" is 95
        BankAccReconciliationLine.Find();
        BankAccReconciliationLine.TestField("Applied Amount", BankAccReconciliationLine."Statement Amount");

        // [THEN] "Applied Amount" is 100, "Applied Pmt. Discount" is 5 in "Applied Payment Entry" for Purchase Invoice
        VerifyAppliedPmtEntry(BankAccReconciliationLine, VendLedgerEntry."Remaining Amount", ToleranceAmount);

        // [THEN] "Accepted Payment Tolerance" = 5 in Vendor Ledger Entry for Purchase Invoice
        VendLedgerEntry.Find();
        VendLedgerEntry.TestField("Accepted Payment Tolerance", ToleranceAmount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PmtTolWarningModalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchAppliedPmtEntryWithNoPmtToleranceWhenDoNotConfirmPmtDiscTolWarningOnAutomaticApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        ToleranceAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Payment Tolerance]
        // [SCENARIO 380951] "Applied Payment Entry" does not include "Payment Tolerance Amount" when automatically match "Bank Acc. Recon. Line" to Purchase Invoice and do not confirm discount in "Payment Tolerance Warning" page
        Initialize();

        // [GIVEN] Payment Tolerance = 5%
        // [GIVEN] Purchase Invoice with Posting Date = 01.01, "Pmt. Discount Date" = 10.01, Amount = 100
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        PurchPmtToleranceScenario(BankAccReconciliationLine, VendLedgerEntry, ToleranceAmount, false, false, -1);
        LibraryLowerPermissions.SetBanking();

        // [WHEN] Match Bank Acc. Reconciliation Line to Purchase Invoice automatically but do not confirm discount in "Payment Tolerance Warning" page
        MatchBankReconLineAutomatically(BankAccReconciliationLine);

        // [THEN] "Applied Amount" in "Bank Account Reconciliation Line" is 95
        BankAccReconciliationLine.Find();
        BankAccReconciliationLine.TestField("Applied Amount", BankAccReconciliationLine."Statement Amount");

        // [THEN] "Applied Amount" is 95, "Applied Pmt. Discount" is zero in "Applied Payment Entry" for Purchase Invoice
        VerifyAppliedPmtEntry(BankAccReconciliationLine, BankAccReconciliationLine."Statement Amount", 0);

        // [THEN] "Accepted Pmt. Disc. Tolerance" is FALSE in Vendor Ledger Entry for Purchase Invoice
        VendLedgerEntry.Find();
        VendLedgerEntry.TestField("Accepted Payment Tolerance", 0);
    end;

    [Test]
    [HandlerFunctions('PaymentApplicationModalPageHandler,PmtTolWarningModalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchAppliedPmtEntryWithPmtToleranceWhenConfirmPmtDiscTolWarningOnManualApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        ToleranceAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Payment Tolerance]
        // [SCENARIO 380951] "Applied Payment Entry" includes "Payment Tolerance Amount" when manually match "Bank Acc. Recon. Line" to Purchase Invoice and confirm discount in "Payment Tolerance Warning" page
        Initialize();

        // [GIVEN] Payment Tolerance = 5%
        // [GIVEN] Purchase Invoice with Posting Date = 01.01, "Pmt. Discount Date" = 10.01, Amount = 100
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        PurchPmtToleranceScenario(BankAccReconciliationLine, VendLedgerEntry, ToleranceAmount, true, true, -1);
        LibraryLowerPermissions.SetBanking();

        // [WHEN] Match Bank Acc. Reconciliation Line to Purchase Invoice manually and confirm discount in "Payment Tolerance Warning" page
        MatchBankReconLineManually(BankAccReconciliationLine);

        // [THEN] "Applied Amount" in "Bank Account Reconciliation Line" is 95
        BankAccReconciliationLine.Find();
        BankAccReconciliationLine.TestField("Applied Amount", BankAccReconciliationLine."Statement Amount");

        // [THEN] "Applied Amount" is 100, "Applied Pmt. Discount" is 5 in "Applied Payment Entry" for Purchase Invoice
        VerifyAppliedPmtEntry(BankAccReconciliationLine, VendLedgerEntry."Remaining Amount", ToleranceAmount);

        // [THEN] "Accepted Payment Tolerance" = 5 in Vendor Ledger Entry for Purchase Invoice
        VendLedgerEntry.Find();
        VendLedgerEntry.TestField("Accepted Payment Tolerance", ToleranceAmount);
    end;

    [Test]
    [HandlerFunctions('PaymentApplicationModalPageHandler,PmtTolWarningModalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchAppliedPmtEntryWithNoPmtToleranceWhenDoNotConfirmPmtDiscTolWarningOnManualApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        ToleranceAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Payment Tolerance]
        // [SCENARIO 380951] "Applied Payment Entry" does not include "Payment Tolerance Amount" when manually match "Bank Acc. Recon. Line" to Purchase Invoice and do not confirm discount in "Payment Tolerance Warning" page
        Initialize();

        // [GIVEN] Payment Tolerance = 5%
        // [GIVEN] Purchase Invoice with Posting Date = 01.01, "Pmt. Discount Date" = 10.01, Amount = 100
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        PurchPmtToleranceScenario(BankAccReconciliationLine, VendLedgerEntry, ToleranceAmount, true, false, -1);
        LibraryLowerPermissions.SetBanking();

        // [WHEN] Match Bank Acc. Reconciliation Line to Purchase Invoice manually but do not confirm discount in "Payment Tolerance Warning" page
        MatchBankReconLineManually(BankAccReconciliationLine);

        // [THEN] "Applied Amount" in "Bank Account Reconciliation Line" is 95
        BankAccReconciliationLine.Find();
        BankAccReconciliationLine.TestField("Applied Amount", BankAccReconciliationLine."Statement Amount");

        // [THEN] "Applied Amount" is 95, "Applied Pmt. Discount" is zero in "Applied Payment Entry" for Purchase Invoice
        VerifyAppliedPmtEntry(BankAccReconciliationLine, BankAccReconciliationLine."Statement Amount", 0);

        // [THEN] "Accepted Pmt. Disc. Tolerance" is FALSE in Vendor Ledger Entry for Purchase Invoice
        VendLedgerEntry.Find();
        VendLedgerEntry.TestField("Accepted Payment Tolerance", 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PmtDiscTolWarningModalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchAppliedPmtEntryWithPmtDiscToleranceWhenConfirmPmtDiscTolWarningOnAutomaticApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase] [Payment Discount Tolerance]
        // [SCENARIO 380951] "Applied Payment Entry" includes "Payment Dis. Tolerance Amount" when automatically match "Bank Acc. Recon. Line" to Purchase Invoice and confirm discount in "Payment Discount Tolerance Warning" page
        Initialize();

        // [GIVEN] Purchase Invoice with Posting Date = 01.01, "Pmt. Discount Tolerance Date" = 10.01, Amount = 100, "Payment Discount" = 5
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        PurchPmtTolDiscScenario(BankAccReconciliationLine, VendLedgerEntry, false, true);
        LibraryLowerPermissions.SetBanking();

        // [WHEN] Match Bank Acc. Reconciliation Line to Purchase Invoice automatically and confirm discount in "Payment Discount Tolerance Warning" page
        MatchBankReconLineAutomatically(BankAccReconciliationLine);

        // [THEN] "Applied Amount" in "Bank Account Reconciliation Line" is 95
        BankAccReconciliationLine.Find();
        BankAccReconciliationLine.TestField("Applied Amount", BankAccReconciliationLine."Statement Amount");

        // [THEN] "Applied Amount" is 100, "Applied Pmt. Discount" is 5 in "Applied Payment Entry" for Purchase Invoice
        VerifyAppliedPmtEntry(
          BankAccReconciliationLine, VendLedgerEntry."Remaining Amount", VendLedgerEntry."Remaining Pmt. Disc. Possible");

        // [THEN] "Accepted Pmt. Disc. Tolerance" is TRUE in Vendor Ledger Entry for Purchase Invoice
        VendLedgerEntry.Find();
        VendLedgerEntry.TestField("Accepted Pmt. Disc. Tolerance", true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PmtDiscTolWarningModalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchAppliedPmtEntryWithNoPmtDiscToleranceWhenDoNotConfirmPmtDiscTolWarningOnAutomaticApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase] [Payment Discount Tolerance]
        // [SCENARIO 380951] "Applied Payment Entry" does not include "Payment Dis. Tolerance Amount" when automatically match "Bank Acc. Recon. Line" to Purchase Invoice and do not confirm discount in "Payment Discount Tolerance Warning" page
        Initialize();

        // [GIVEN] Purchase Invoice with Posting Date = 01.01, "Pmt. Discount Tolerance Date" = 10.01, Amount = 100, "Payment Discount" = 5
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        PurchPmtTolDiscScenario(BankAccReconciliationLine, VendLedgerEntry, false, false);
        LibraryLowerPermissions.SetBanking();

        // [WHEN] Match Bank Acc. Reconciliation Line to Purchase Invoice automatically but do not confirm discount in "Payment Discount Tolerance Warning" page
        MatchBankReconLineAutomatically(BankAccReconciliationLine);

        // [THEN] "Applied Amount" in "Bank Account Reconciliation Line" is 95
        BankAccReconciliationLine.Find();
        BankAccReconciliationLine.TestField("Applied Amount", BankAccReconciliationLine."Statement Amount");

        // [THEN] "Applied Amount" is 95, "Applied Pmt. Discount" is zero in "Applied Payment Entry" for Purchase Invoice
        VerifyAppliedPmtEntry(BankAccReconciliationLine, BankAccReconciliationLine."Statement Amount", 0);

        // [THEN] "Accepted Pmt. Disc. Tolerance" is FALSE in Vendor Ledger Entry for Purchase Invoice
        VendLedgerEntry.Find();
        VendLedgerEntry.TestField("Accepted Pmt. Disc. Tolerance", false);
    end;

    [Test]
    [HandlerFunctions('PaymentApplicationModalPageHandler,PmtDiscTolWarningModalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchAppliedPmtEntryWithPmtDiscToleranceWhenConfirmPmtDiscTolWarningOnManualApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase] [Payment Discount Tolerance]
        // [SCENARIO 380951] "Applied Payment Entry" includes "Payment Dis. Tolerance Amount" when manually match "Bank Acc. Recon. Line" to Purchase Invoice and confirm discount in "Payment Discount Tolerance Warning" page
        Initialize();

        // [GIVEN] Purchase Invoice with Posting Date = 01.01, "Pmt. Discount Tolerance Date" = 10.01, Amount = 100, "Payment Discount" = 5
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        PurchPmtTolDiscScenario(BankAccReconciliationLine, VendLedgerEntry, true, true);
        LibraryLowerPermissions.SetBanking();

        // [WHEN] Match Bank Acc. Reconciliation Line to Purchase Invoice manually and confirm discount in "Payment Discount Tolerance Warning" page
        MatchBankReconLineManually(BankAccReconciliationLine);

        // [THEN] "Applied Amount" in "Bank Account Reconciliation Line" is 95
        BankAccReconciliationLine.Find();
        BankAccReconciliationLine.TestField("Applied Amount", BankAccReconciliationLine."Statement Amount");

        // [THEN] "Applied Amount" is 100, "Applied Pmt. Discount" is 5 in "Applied Payment Entry" for Purchase Invoice
        VerifyAppliedPmtEntry(
          BankAccReconciliationLine, VendLedgerEntry."Remaining Amount", VendLedgerEntry."Remaining Pmt. Disc. Possible");

        // [THEN] "Accepted Pmt. Disc. Tolerance" is TRUE in Vendor Ledger Entry for Purchase Invoice
        VendLedgerEntry.Find();
        VendLedgerEntry.TestField("Accepted Pmt. Disc. Tolerance", true);
    end;

    [Test]
    [HandlerFunctions('PaymentApplicationModalPageHandler,PmtDiscTolWarningModalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchAppliedPmtEntryWithNoPmtDiscToleranceWhenDoNotConfirmPmtDiscTolWarningOnManualApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase] [Payment Discount Tolerance]
        // [SCENARIO 380951] "Applied Payment Entry" includes "Payment Dis. Tolerance Amount" when manually match "Bank Acc. Recon. Line" to Purchase Invoice but do not confirm discount in "Payment Discount Tolerance Warning" page
        Initialize();

        // [GIVEN] Purchase Invoice with Posting Date = 01.01, "Pmt. Discount Tolerance Date" = 10.01, Amount = 100, "Payment Discount" = 5
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        PurchPmtTolDiscScenario(BankAccReconciliationLine, VendLedgerEntry, true, false);
        LibraryLowerPermissions.SetBanking();

        // [WHEN] Match Bank Acc. Reconciliation Line to Purchase Invoice manually but do not confirm discount in "Payment Discount Tolerance Warning" page
        MatchBankReconLineManually(BankAccReconciliationLine);

        // [THEN] "Applied Amount" in "Bank Account Reconciliation Line" is 95
        BankAccReconciliationLine.Find();
        BankAccReconciliationLine.TestField("Applied Amount", BankAccReconciliationLine."Statement Amount");

        // [THEN] "Applied Amount" is 95, "Applied Pmt. Discount" is zero in "Applied Payment Entry" for Purchase Invoice
        VerifyAppliedPmtEntry(
          BankAccReconciliationLine, BankAccReconciliationLine."Statement Amount", 0);

        // [THEN] "Accepted Pmt. Disc. Tolerance" is FALSE in Vendor Ledger Entry for Purchase Invoice
        VendLedgerEntry.Find();
        VendLedgerEntry.TestField("Accepted Pmt. Disc. Tolerance", false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PmtTolWarningModalPageHandler,ConfirmHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure PurchPmtToleranceWhenConfirmPmtDiscTolWarningOnAutomaticApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        ToleranceAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Payment Tolerance]
        // [SCENARIO 380951] "Payment Tolerance" detailed ledger entry is created when automatically match "Bank Acc. Recon. Line" to Purchase Invoice and confirm discount in "Payment Tolerance Warning" page
        Initialize();

        // [GIVEN] Payment Tolerance = 5%
        // [GIVEN] Purchase Invoice with Posting Date = 01.01, "Pmt. Discount Date" = 10.01, Amount = 100
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        PurchPmtToleranceScenario(BankAccReconciliationLine, VendLedgerEntry, ToleranceAmount, false, true, -1);

        // [GIVEN] Bank Acc. Reconciliation Line and Purchase Invoice automatically matched and discount in "Payment Discount Tolerance Warning" page is confirmed
        MatchBankReconLineAutomatically(BankAccReconciliationLine);
        LibraryVariableStorage.Enqueue(true); // Set "Yes" on "Payment Tolerance Warning" page
        LibraryLowerPermissions.SetBanking();

        // [WHEN] Post Bank Account Reconciliation
        PostReconciliation(BankAccReconciliationLine);

        // [THEN] Payment from Bank Acc. Reconciliation Line applied fully to Invoice ("Remaining Amount" is zero)
        VerifyVendLedgEntry(VendLedgerEntry."Entry No.", 0);

        // [THEN] Detailed Ledger Entry "Payment Tolerance" with Amount = 5 for Purchase Invoice is created
        FilterPmtDiscToleranceDtldVendLedgEntry(
          DetailedVendLedgEntry, DetailedVendLedgEntry."Entry Type"::"Payment Tolerance", BankAccReconciliationLine."Statement No.",
          VendLedgerEntry."Vendor No.");
        DetailedVendLedgEntry.FindFirst();
        DetailedVendLedgEntry.TestField(Amount, -ToleranceAmount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PmtTolWarningModalPageHandler,ConfirmHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure NoPurchPmtToleranceWhenDoNotConfirmPmtDiscTolWarningOnAutomaticApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        ToleranceAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Payment Tolerance]
        // [SCENARIO 380951] "Payment Tolerance" detailed ledger entries are not created when automatically match "Bank Acc. Recon. Line" to Purchase Invoice but do not confirm discount in "Payment Tolerance Warning" page
        Initialize();

        // [GIVEN] Payment Tolerance = 5%
        // [GIVEN] Purchase Invoice with Posting Date = 01.01, "Pmt. Discount Date" = 10.01, Amount = 100
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        PurchPmtToleranceScenario(BankAccReconciliationLine, VendLedgerEntry, ToleranceAmount, false, false, -1);

        // [GIVEN] Bank Acc. Reconciliation Line and Purchase Invoice automatically matched and discount in "Payment Discount Tolerance Warning" page is not confirmed
        MatchBankReconLineAutomatically(BankAccReconciliationLine);
        LibraryLowerPermissions.SetBanking();

        // [WHEN] Post Bank Account Reconciliation
        PostReconciliation(BankAccReconciliationLine);

        // [THEN] Payment from Bank Acc. Reconciliation Line applied not fully to Invoice ("Remaining Amount" = 5)
        VerifyVendLedgEntry(VendLedgerEntry."Entry No.", ToleranceAmount);

        // [THEN] No Detailed Ledger Entry "Payment Tolerance" for Purchase Invoice is created
        FilterPmtDiscToleranceDtldVendLedgEntry(
          DetailedVendLedgEntry, DetailedVendLedgEntry."Entry Type"::"Payment Tolerance", BankAccReconciliationLine."Statement No.",
          VendLedgerEntry."Vendor No.");
        Assert.RecordIsEmpty(DetailedVendLedgEntry);
    end;

    [Test]
    [HandlerFunctions('PaymentApplicationModalPageHandler,PmtTolWarningModalPageHandler,ConfirmHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure PurchPmtToleranceWhenConfirmPmtDiscTolWarningOnManualApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        ToleranceAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Payment Tolerance]
        // [SCENARIO 380951] "Payment Tolerance" detailed ledger entry is created when manually match "Bank Acc. Recon. Line" to Purchase Invoice and confirm discount in "Payment Tolerance Warning" page
        Initialize();

        // [GIVEN] Payment Tolerance = 5%
        // [GIVEN] Purchase Invoice with Posting Date = 01.01, "Pmt. Discount Date" = 10.01, Amount = 100
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        PurchPmtToleranceScenario(BankAccReconciliationLine, VendLedgerEntry, ToleranceAmount, true, true, -1);

        // [GIVEN] Bank Acc. Reconciliation Line and Purchase Invoice manually matched and discount in "Payment Discount Tolerance Warning" page is confirmed
        MatchBankReconLineManually(BankAccReconciliationLine);
        LibraryVariableStorage.Enqueue(true); // Set "Yes" on "Payment Tolerance Warning" page
        LibraryLowerPermissions.SetBanking();

        // [WHEN] Post Bank Account Reconciliation
        PostReconciliation(BankAccReconciliationLine);

        // [THEN] Payment from Bank Acc. Reconciliation Line applied fully to Invoice ("Remaining Amount" is zero)
        VerifyVendLedgEntry(VendLedgerEntry."Entry No.", 0);

        // [THEN] Detailed Ledger Entry "Payment Tolerance" with Amount = 5 for Purchase Invoice is created
        FilterPmtDiscToleranceDtldVendLedgEntry(
          DetailedVendLedgEntry, DetailedVendLedgEntry."Entry Type"::"Payment Tolerance", BankAccReconciliationLine."Statement No.",
          VendLedgerEntry."Vendor No.");
        DetailedVendLedgEntry.FindFirst();
        DetailedVendLedgEntry.TestField(Amount, -ToleranceAmount);
    end;

    [Test]
    [HandlerFunctions('PaymentApplicationModalPageHandler,PmtTolWarningModalPageHandler,ConfirmHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure NoPurchPmtToleranceWhenDoNotConfirmPmtDiscTolWarningOnManualApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
        ToleranceAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Payment Tolerance]
        // [SCENARIO 380951] "Payment Tolerance" detailed ledger entry is created when manually match "Bank Acc. Recon. Line" to Purchase Invoice but do not confirm discount in "Payment Tolerance Warning" page
        Initialize();

        // [GIVEN] Payment Tolerance = 5%
        // [GIVEN] Purchase Invoice with Posting Date = 01.01, "Pmt. Discount Date" = 10.01, Amount = 100
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        PurchPmtToleranceScenario(BankAccReconciliationLine, VendLedgerEntry, ToleranceAmount, true, false, -1);

        // [GIVEN] Bank Acc. Reconciliation Line and Purchase Invoice manually matched and discount in "Payment Discount Tolerance Warning" page is not confirmed
        MatchBankReconLineManually(BankAccReconciliationLine);
        LibraryLowerPermissions.SetBanking();

        // [WHEN] Post Bank Account Reconciliation
        PostReconciliation(BankAccReconciliationLine);

        // [THEN] Payment from Bank Acc. Reconciliation Line applied not fully to Invoice ("Remaining Amount" = 5)
        VerifyVendLedgEntry(VendLedgerEntry."Entry No.", ToleranceAmount);

        // [THEN] No Detailed Ledger Entry "Payment Tolerance" for Purchase Invoice is created
        FilterPmtDiscToleranceDtldVendLedgEntry(
          DetailedVendLedgEntry, DetailedVendLedgEntry."Entry Type"::"Payment Tolerance", BankAccReconciliationLine."Statement No.",
          VendLedgerEntry."Vendor No.");
        Assert.RecordIsEmpty(DetailedVendLedgEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PmtDiscTolWarningModalPageHandler,ConfirmHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure PurchPmtDiscToleranceWhenConfirmPmtDiscTolWarningOnAutomaticApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        // [FEATURE] [Purchase] [Payment Discount Tolerance]
        // [SCENARIO 380920] "Pmt. Discout Tolerance" detailed ledger entry is created when automatically match "Bank Acc. Recon. Line" to Purchase Invoice and confirm discount in "Payment Discount Tolerance Warning" page
        Initialize();

        // [GIVEN] Purchase Invoice with Posting Date = 01.01, "Pmt. Discount Tolerance Date" = 10.01, Amount = 100, "Payment Discount" = 5
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        PurchPmtTolDiscScenario(BankAccReconciliationLine, VendLedgerEntry, false, true);

        // [GIVEN] Bank Acc. Reconciliation Line and Purchase Invoice automatically matched and discount in "Payment Discount Tolerance Warning" page is confirmed
        MatchBankReconLineAutomatically(BankAccReconciliationLine);
        LibraryVariableStorage.Enqueue(true); // Set "Yes" on "Payment Discount Tolerance Warning" page
        LibraryLowerPermissions.SetBanking();

        // [WHEN] Post Bank Account Reconciliation
        PostReconciliation(BankAccReconciliationLine);

        // [THEN] Payment from Bank Acc. Reconciliation Line applied fully to Invoice ("Remaining Amount" is zero)
        VerifyVendLedgEntry(VendLedgerEntry."Entry No.", 0);

        // [THEN] Detailed Ledger Entry "Pmt. Discount Tolerance" with Amount = 5 for Purchase Invoice is created
        FilterPmtDiscToleranceDtldVendLedgEntry(
          DetailedVendLedgEntry, DetailedVendLedgEntry."Entry Type"::"Payment Discount Tolerance",
          BankAccReconciliationLine."Statement No.", VendLedgerEntry."Vendor No.");
        DetailedVendLedgEntry.FindFirst();
        DetailedVendLedgEntry.TestField(Amount, -VendLedgerEntry."Original Pmt. Disc. Possible");
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PmtDiscTolWarningModalPageHandler,ConfirmHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure NoPurchPmtDiscToleranceWhenDoNotConfirmPmtDiscTolWarningOnAutomaticApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        // [FEATURE] [Purchase] [Payment Discount Tolerance]
        // [SCENARIO 380920] "Pmt. Discout Tolerance" detailed ledger entries are not created when automatically match "Bank Acc. Recon. Line" to Purchase Invoice but do not confirm discount in "Payment Discount Tolerance Warning" page
        Initialize();

        // [GIVEN] Purchase Invoice with Posting Date = 01.01, "Pmt. Discount Tolerance Date" = 10.01, Amount = 100, "Payment Discount" = 5
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        PurchPmtTolDiscScenario(BankAccReconciliationLine, VendLedgerEntry, false, false);

        // [GIVEN] Bank Acc. Reconciliation Line and Purchase Invoice automatically matched and discount in "Payment Discount Tolerance Warning" page is not confirmed
        MatchBankReconLineAutomatically(BankAccReconciliationLine);
        LibraryVariableStorage.Enqueue(false); // Set "No" on "Payment Discount Tolerance Warning" page
        LibraryLowerPermissions.SetBanking();

        // [WHEN] Post Bank Account Reconciliation
        PostReconciliation(BankAccReconciliationLine);

        // [THEN] Payment from Bank Acc. Reconciliation Line applied not fully to Invoice ("Remaining Amount" = 5)
        VerifyVendLedgEntry(VendLedgerEntry."Entry No.", VendLedgerEntry."Original Pmt. Disc. Possible");

        // [THEN] No Detailed Ledger Entry "Pmt. Discount Tolerance" for Purchase Invoice is created
        FilterPmtDiscToleranceDtldVendLedgEntry(
          DetailedVendLedgEntry, DetailedVendLedgEntry."Entry Type"::"Payment Discount Tolerance",
          BankAccReconciliationLine."Statement No.", VendLedgerEntry."Vendor No.");
        Assert.RecordIsEmpty(DetailedVendLedgEntry);
    end;

    [Test]
    [HandlerFunctions('PaymentApplicationModalPageHandler,PmtDiscTolWarningModalPageHandler,ConfirmHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure PurchPmtDiscToleranceWhenConfirmPmtDiscTolWarningOnManualApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        // [FEATURE] [Purchase] [Payment Discount Tolerance]
        // [SCENARIO 380920] "Pmt. Discout Tolerance" detailed ledger entry is created when manually match "Bank Acc. Recon. Line" to Purchase Invoice and confirm discount in "Payment Discount Tolerance Warning" page
        Initialize();

        // [GIVEN] Purchase Invoice with Posting Date = 01.01, "Pmt. Discount Tolerance Date" = 10.01, Amount = 100, "Payment Discount" = 5
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        PurchPmtTolDiscScenario(BankAccReconciliationLine, VendLedgerEntry, true, true);

        // [GIVEN] Bank Acc. Reconciliation Line and Purchase Invoice manually matched and discount in "Payment Discount Tolerance Warning" page is confirmed
        MatchBankReconLineManually(BankAccReconciliationLine);
        LibraryVariableStorage.Enqueue(true); // Set "Yes" on "Payment Discount Tolerance Warning" page
        LibraryLowerPermissions.SetBanking();

        // [WHEN] Post Bank Account Reconciliation
        PostReconciliation(BankAccReconciliationLine);

        // [THEN] Payment from Bank Acc. Reconciliation Line applied fully to Invoice ("Remaining Amount" is zero)
        VerifyVendLedgEntry(VendLedgerEntry."Entry No.", 0);

        // [THEN] Detailed Ledger Entry "Pmt. Discount Tolerance" with Amount = 5 for Purchase Invoice is created
        FilterPmtDiscToleranceDtldVendLedgEntry(
          DetailedVendLedgEntry, DetailedVendLedgEntry."Entry Type"::"Payment Discount Tolerance",
          BankAccReconciliationLine."Statement No.", VendLedgerEntry."Vendor No.");
        DetailedVendLedgEntry.FindFirst();
        DetailedVendLedgEntry.TestField(Amount, -VendLedgerEntry."Original Pmt. Disc. Possible");
    end;

    [Test]
    [HandlerFunctions('PaymentApplicationModalPageHandler,PmtDiscTolWarningModalPageHandler,ConfirmHandler,PostAndReconcilePageHandler')]
    [Scope('OnPrem')]
    procedure NoPurchPmtDiscToleranceWhenDoNotConfirmPmtDiscTolWarningOnManualApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        // [FEATURE] [Purchase] [Payment Discount Tolerance]
        // [SCENARIO 380920] "Pmt. Discout Tolerance" detailed ledger entry is created when manually match "Bank Acc. Recon. Line" to Purchase Invoice but do not confirm discount in "Payment Discount Tolerance Warning" page
        Initialize();

        // [GIVEN] Purchase Invoice with Posting Date = 01.01, "Pmt. Discount Tolerance Date" = 10.01, Amount = 100, "Payment Discount" = 5
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        PurchPmtTolDiscScenario(BankAccReconciliationLine, VendLedgerEntry, true, false);

        // [GIVEN] Bank Acc. Reconciliation Line and Purchase Invoice manually matched and discount in "Payment Discount Tolerance Warning" page is not confirmed
        MatchBankReconLineManually(BankAccReconciliationLine);
        LibraryVariableStorage.Enqueue(false); // Set "No" on "Payment Discount Tolerance Warning" page
        LibraryLowerPermissions.SetBanking();

        // [WHEN] Post Bank Account Reconciliation
        PostReconciliation(BankAccReconciliationLine);

        // [THEN] Payment from Bank Acc. Reconciliation Line applied not fully to Invoice ("Remaining Amount" = 5)
        VerifyVendLedgEntry(VendLedgerEntry."Entry No.", VendLedgerEntry."Original Pmt. Disc. Possible");

        // [THEN] No Detailed Ledger Entry "Pmt. Discount Tolerance" for Purchase Invoice is created
        FilterPmtDiscToleranceDtldVendLedgEntry(
          DetailedVendLedgEntry, DetailedVendLedgEntry."Entry Type"::"Payment Discount Tolerance",
          BankAccReconciliationLine."Statement No.", VendLedgerEntry."Vendor No.");
        Assert.RecordIsEmpty(DetailedVendLedgEntry);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PmtDiscTolWarningModalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ClearPurchAcceptedPmtDiscToleranceWhenRemoveBankAccReconciliation()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [FEATURE] [Purchase] [Payment Discount Tolerance]
        // [SCENARIO 380951] "Accepted Pmt. Disc. Tolerance" and "Amount to Apply" clears out when remove Bank Account Reconciliation previously applied to Purchase Invoice with Payment Discount Tolerance
        Initialize();

        // [GIVEN] Purchase Invoice with Posting Date = 01.01, "Pmt. Discount Tolerance Date" = 10.01, Amount = 100, "Payment Discount" = 5
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        PurchPmtTolDiscScenario(BankAccReconciliationLine, VendLedgerEntry, false, true);

        // [GIVEN] Bank Acc. Reconciliation Line and Purchase Invoice automatically matched and discount in "Payment Discount Tolerance Warning" page is confirmed
        MatchBankReconLineAutomatically(BankAccReconciliationLine);
        LibraryLowerPermissions.SetBanking();

        // [WHEN] Delete Bank Account Reconciliation Line
        BankAccReconciliationLine.Delete(true);

        // [THEN] "Accepted Pmt. Disc. Tolerance" is FALSE in Vendor Ledger Entry for Purchase Invoice
        VendLedgerEntry.Find();
        VendLedgerEntry.TestField("Accepted Pmt. Disc. Tolerance", false);

        // [THEN] Amount to Apply = 0 in Vendor Ledger Entry for Purchase Invoice
        VendLedgerEntry.TestField("Amount to Apply", 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PmtTolWarningModalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure ClearPurchAcceptedPmtToleranceWhenRemoveBankAccReconciliation()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        ToleranceAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Payment Tolerance]
        // [SCENARIO 380951] "Accepted Payment Tolerance" and "Amount to Apply" clears out when remove Bank Account Reconciliation previously applied to Purchase Invoice with Payment Discount Tolerance
        Initialize();

        // [GIVEN] Payment Tolerance = 5%
        // [GIVEN] Purchase Invoice with Posting Date = 01.01, "Pmt. Discount Date" = 10.01, Amount = 100
        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.01", "Transaction Text" = "X" and "Statement Amount" = 95
        PurchPmtToleranceScenario(BankAccReconciliationLine, VendLedgerEntry, ToleranceAmount, false, true, -1);

        // [GIVEN] Bank Acc. Reconciliation Line and Purchase Invoice automatically matched and discount in "Payment Discount Tolerance Warning" page is confirmed
        MatchBankReconLineAutomatically(BankAccReconciliationLine);
        LibraryLowerPermissions.SetBanking();

        // [WHEN] Delete Bank Account Reconciliation Line
        BankAccReconciliationLine.Delete(true);

        // [THEN] "Accepted Payment Tolerance" is 0 in Vendor Ledger Entry for Purchase Invoice
        VendLedgerEntry.Find();
        VendLedgerEntry.TestField("Accepted Payment Tolerance", 0);

        // [THEN] Amount to Apply = 0 in Vendor Ledger Entry for Purchase Invoice
        VendLedgerEntry.TestField("Amount to Apply", 0);
    end;

    [Test]
    [HandlerFunctions('PaymentApplicationModalPageHandler,PmtTolWarningModalPageHandler,ConfirmHandler,TransToDiffAccModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesAcceptedPmtToleranceRevertedWhenTransderDiffToGLAccAfterApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        MatchBankPayments: Codeunit "Match Bank Payments";
        ToleranceAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Payment Tolerance]
        // [SCENARIO 211312] "Accepted Payment Tolerance" is reverted from Customer Ledger Entry when difference after application of Bank Acc. Recon. Line is transferred to a new line with G/L Account
        Initialize();

        // [GIVEN] Posted Invoice with Amount = 100 and Max. Tolerance Amount = 2.1
        // [GIVEN] Bank Acc. Recon. Line with Statement Amount = 102.1 applied to Posted Invoice and accepted Payment Tolerance
        SalesPmtToleranceScenario(BankAccReconciliationLine, CustLedgerEntry, ToleranceAmount, true, true, 1);
        MatchBankReconLineManually(BankAccReconciliationLine);
        IncreaseStatementAmountOnBankAccReconLine(BankAccReconciliationLine, ToleranceAmount);
        LibraryLowerPermissions.SetAccountReceivables();
        LibraryLowerPermissions.AddFinancialReporting(); // permission for G/L Account

        // [WHEN] Transfer difference from existing Bank. Acc. Reconciliation Line to a new with G/L Account
        MatchBankPayments.TransferDiffToAccount(BankAccReconciliationLine, GenJournalLine);

        // [THEN] "Accepted Tolerance" in Customer Ledger Entry for Posted Invoice is 0
        CustLedgerEntry.Find();
        CustLedgerEntry.TestField("Accepted Payment Tolerance", 0);
    end;

    [Test]
    [HandlerFunctions('PaymentApplicationModalPageHandler,PmtTolWarningModalPageHandler,ConfirmHandler,TransToDiffAccModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SalesAcceptedPmtToleranceDecreasedWhenTransderModifiedDiffToGLAccAfterApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        MatchBankPayments: Codeunit "Match Bank Payments";
        ToleranceAmount: Decimal;
        DecreasedToleranceAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Payment Tolerance]
        // [SCENARIO 211312] "Accepted Payment Tolerance" is decreased from Customer Ledger Entry when modified difference after application of Bank Acc. Recon. Line is transferred to a new line with G/L Account
        Initialize();

        // [GIVEN] Posted Invoice with Amount = 100 and Max. Tolerance Amount = 2.1
        // [GIVEN] Bank Acc. Recon. Line with Statement Amount = 102.1 applied to Posted Invoice and accepted Payment Tolerance
        SalesPmtToleranceScenario(BankAccReconciliationLine, CustLedgerEntry, ToleranceAmount, true, true, 1);
        MatchBankReconLineManually(BankAccReconciliationLine);

        // [GIVEN] Statement Amount in Bank Acc. Recon. Line changed to 100.6
        BankAccReconciliationLine.Find();
        IncreaseStatementAmountOnBankAccReconLine(BankAccReconciliationLine, ToleranceAmount);
        DecreasedToleranceAmount := Round(BankAccReconciliationLine.Difference / LibraryRandom.RandIntInRange(3, 10));
        BankAccReconciliationLine.Validate("Statement Amount", BankAccReconciliationLine."Statement Amount" - DecreasedToleranceAmount);
        BankAccReconciliationLine.Modify(true);
        LibraryLowerPermissions.SetAccountReceivables();
        LibraryLowerPermissions.AddFinancialReporting(); // permission for G/L Account

        // [WHEN] Transfer difference from Application to G/L Account
        MatchBankPayments.TransferDiffToAccount(BankAccReconciliationLine, GenJournalLine);

        // [THEN] "Accepted Tolerance" in Customer Ledger Entry is 1.5 (102.1 - 100.6)
        CustLedgerEntry.Find();
        CustLedgerEntry.TestField("Accepted Payment Tolerance", -DecreasedToleranceAmount);
    end;

    [Test]
    [HandlerFunctions('PaymentApplicationModalPageHandler,PmtTolWarningModalPageHandler,ConfirmHandler,TransToDiffAccModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchAcceptedPmtToleranceRevertedWhenTransderDiffToGLAccAfterApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        MatchBankPayments: Codeunit "Match Bank Payments";
        ToleranceAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Payment Tolerance]
        // [SCENARIO 211312] "Accepted Payment Tolerance" is reverted from Vendor Ledger Entry when difference after application of Bank Acc. Recon. Line is transferred to a new line with G/L Account
        Initialize();

        // [GIVEN] Posted Invoice with Amount = 100 and Max. Tolerance Amount = 2.1
        // [GIVEN] Bank Acc. Recon. Line with Statement Amount = 102.1 applied to Posted Invoice and accepted Payment Tolerance
        PurchPmtToleranceScenario(BankAccReconciliationLine, VendLedgerEntry, ToleranceAmount, true, true, 1);
        MatchBankReconLineManually(BankAccReconciliationLine);
        IncreaseStatementAmountOnBankAccReconLine(BankAccReconciliationLine, ToleranceAmount);
        BankAccReconciliationLine.Find();
        LibraryLowerPermissions.SetAccountPayables();
        LibraryLowerPermissions.AddFinancialReporting(); // permission for G/L Account

        // [WHEN] Transfer difference from existing Bank. Acc. Reconciliation Line to a new with G/L Account
        MatchBankPayments.TransferDiffToAccount(BankAccReconciliationLine, GenJournalLine);

        // [THEN] "Accepted Tolerance" in Vendor Ledger Entry for Posted Invoice is 0
        VendLedgerEntry.Find();
        VendLedgerEntry.TestField("Accepted Payment Tolerance", 0);
    end;

    [Test]
    [HandlerFunctions('PaymentApplicationModalPageHandler,PmtTolWarningModalPageHandler,ConfirmHandler,TransToDiffAccModalPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PurchAcceptedPmtToleranceDecreasedWhenTransderModifiedDiffToGLAccAfterApplication()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        MatchBankPayments: Codeunit "Match Bank Payments";
        ToleranceAmount: Decimal;
        DecreasedToleranceAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Payment Tolerance]
        // [SCENARIO 211312] "Accepted Payment Tolerance" is decreased from Vendor Ledger Entry when modified difference after application of Bank Acc. Recon. Line is transferred to a new line with G/L Account
        Initialize();

        // [GIVEN] Posted Invoice with Amount = 100 and Max. Tolerance Amount = 2.1
        // [GIVEN] Bank Acc. Recon. Line with Statement Amount = 102.1 applied to Posted Invoice and accepted Payment Tolerance
        PurchPmtToleranceScenario(BankAccReconciliationLine, VendLedgerEntry, ToleranceAmount, true, true, 1);
        MatchBankReconLineManually(BankAccReconciliationLine);

        // [GIVEN] Statement Amount in Bank Acc. Recon. Line changed to 100.6
        BankAccReconciliationLine.Find();
        IncreaseStatementAmountOnBankAccReconLine(BankAccReconciliationLine, ToleranceAmount);
        DecreasedToleranceAmount := Round(BankAccReconciliationLine.Difference / LibraryRandom.RandIntInRange(3, 10));
        BankAccReconciliationLine.Validate("Statement Amount", BankAccReconciliationLine."Statement Amount" - DecreasedToleranceAmount);
        BankAccReconciliationLine.Modify(true);
        LibraryLowerPermissions.SetAccountPayables();
        LibraryLowerPermissions.AddFinancialReporting(); // permission for G/L Account

        // [WHEN] Transfer difference from Application to G/L Account
        MatchBankPayments.TransferDiffToAccount(BankAccReconciliationLine, GenJournalLine);

        // [THEN] "Accepted Tolerance" in Vendor Ledger Entry is 1.5 (102.1 - 100.6)
        VendLedgerEntry.Find();
        VendLedgerEntry.TestField("Accepted Payment Tolerance", -DecreasedToleranceAmount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PmtTolWarningModalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesAppliedPmtEntryWithPmtToleranceConfirmedWhenPostingDateAfterPmtDiscDate()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TolerancePct: Decimal;
        ToleranceAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Payment Tolerance]
        // [SCENARIO 210865] "Applied Payment Entry" includes "Payment Tolerance Amount" confirmed when Posting Date of Bank Recon. Journal Line after "Pmt. Discount Date" of Customer Ledger Entry
        Initialize();

        // [GIVEN] Payment Tolerance = 5%
        TolerancePct := LibraryRandom.RandInt(10);
        SetPmtDiscSetup(true, false, TolerancePct);

        // [GIVEN] Sales Invoice with Posting Date = 01.01, "Pmt. Discount Date" = 10.01, Amount = 100
        PostSalesInvoice(CustLedgerEntry, LibrarySales.CreateCustomerNo());
        ToleranceAmount := Round(CustLedgerEntry."Remaining Amount" * TolerancePct / 100);

        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.02", "Transaction Text" = "X" and "Statement Amount" = 95
        CreateBankReconciliationLine(
          BankAccReconciliationLine, CalcDate('<1M>', CustLedgerEntry."Pmt. Discount Date"),
          CustLedgerEntry."Remaining Amount" - ToleranceAmount,
          CustLedgerEntry."Document No.");
        LibraryVariableStorage.Enqueue(true); // Set "Yes" on "Payment Tolerance Warning" page

        // [WHEN] Match Bank Acc. Reconciliation Line to Sales Invoice automatically and confirm discount in "Payment Tolerance Warning" page
        MatchBankReconLineAutomatically(BankAccReconciliationLine);
        LibraryLowerPermissions.SetBanking();

        // [THEN] "Applied Amount" in "Bank Account Reconciliation Line" is 95
        BankAccReconciliationLine.Find();
        BankAccReconciliationLine.TestField("Applied Amount", BankAccReconciliationLine."Statement Amount");

        // [THEN] "Applied Amount" is 100, "Applied Pmt. Discount" is 5 in "Applied Payment Entry" for Sales Invoice
        VerifyAppliedPmtEntry(
          BankAccReconciliationLine, CustLedgerEntry."Remaining Amount", ToleranceAmount);

        // [THEN] "Accepted Payment Tolerance" = 5 in Customer Ledger Entry for Sales Invoice
        CustLedgerEntry.Find();
        CustLedgerEntry.TestField("Accepted Payment Tolerance", ToleranceAmount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PmtTolWarningModalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchAppliedPmtEntryWithPmtToleranceConfirmedWhenPostingDateAfterPmtDiscDate()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        TolerancePct: Decimal;
        ToleranceAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Payment Tolerance]
        // [SCENARIO 210865] "Applied Payment Entry" includes "Payment Tolerance Amount" confirmed when Posting Date of Bank Recon. Journal Line after "Pmt. Discount Date" of Vendor Ledger Entry
        Initialize();

        // [GIVEN] Payment Tolerance = 5%
        TolerancePct := LibraryRandom.RandInt(10);
        SetPmtDiscSetup(true, false, TolerancePct);

        // [GIVEN] Purchase Invoice with Posting Date = 01.01, "Pmt. Discount Date" = 10.01, Amount = 100
        PostPurchInvoice(VendLedgerEntry, LibraryPurchase.CreateVendorNo());
        ToleranceAmount := Round(VendLedgerEntry."Remaining Amount" * TolerancePct / 100);

        // [GIVEN] Bank Account Reconciliation Line with "Transaction Date" = "10.02", "Transaction Text" = "X" and "Statement Amount" = 95
        CreateBankReconciliationLine(
          BankAccReconciliationLine, CalcDate('<1M>', VendLedgerEntry."Pmt. Discount Date"),
          VendLedgerEntry."Remaining Amount" - ToleranceAmount,
          VendLedgerEntry."Document No.");
        LibraryVariableStorage.Enqueue(true); // Set "Yes" on "Payment Tolerance Warning" page

        // [WHEN] Match Bank Acc. Reconciliation Line to Purchase Invoice automatically and confirm discount in "Payment Tolerance Warning" page
        MatchBankReconLineAutomatically(BankAccReconciliationLine);
        LibraryLowerPermissions.SetBanking();

        // [THEN] "Applied Amount" in "Bank Account Reconciliation Line" is 95
        BankAccReconciliationLine.Find();
        BankAccReconciliationLine.TestField("Applied Amount", BankAccReconciliationLine."Statement Amount");

        // [THEN] "Applied Amount" is 100, "Applied Pmt. Discount" is 5 in "Applied Payment Entry" for Purchase Invoice
        VerifyAppliedPmtEntry(BankAccReconciliationLine, VendLedgerEntry."Remaining Amount", ToleranceAmount);

        // [THEN] "Accepted Payment Tolerance" = 5 in Vendor Ledger Entry for Purchase Invoice
        VendLedgerEntry.Find();
        VendLedgerEntry.TestField("Accepted Payment Tolerance", ToleranceAmount);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PmtTolWarningAssertDocModalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesBankStatementNoUsesAsDocNoInPmtToleranceWarningWindow()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        TolerancePct: Decimal;
        ToleranceAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Payment Tolerance]
        // [SCENARIO 213099] "Statement No." of "Bank Acc. Reconciliation" uses as "Document No." in "Payment Tolerance Warning" window when apply Bank Acc. Reconciliation Line to Sales Invoice with Payment Discount
        Initialize();

        // [GIVEN] Payment Tolerance = 5%
        TolerancePct := LibraryRandom.RandInt(10);
        SetPmtDiscSetup(true, false, TolerancePct);

        // [GIVEN] Sales Invoice with Posting Date = 01.01, "Pmt. Discount Date" = 10.01
        PostSalesInvoice(CustLedgerEntry, LibrarySales.CreateCustomerNo());
        ToleranceAmount := Round(CustLedgerEntry."Remaining Amount" * TolerancePct / 100);

        // [GIVEN] Bank Account Reconciliation Line with "Statement No." = "X" "Transaction Date" = "10.01"
        CreateBankReconciliationLine(
          BankAccReconciliationLine, CustLedgerEntry."Pmt. Discount Date", CustLedgerEntry."Remaining Amount" - ToleranceAmount,
          CustLedgerEntry."Document No.");
        LibraryVariableStorage.Enqueue(BankAccReconciliationLine."Statement No."); // Set "Statement No." for "Document No." on "Payment Tolerance Warning" page
        LibraryLowerPermissions.SetBanking();

        // [WHEN] Match Bank Acc. Reconciliation Line to Sales Invoice automatically
        MatchBankReconLineAutomatically(BankAccReconciliationLine);

        // [THEN] "Payment Tolerance Warning" page shown and "Document No." = "X"
        // Verification done in PmtTolWarningAssertDocModalPageHandler
    end;

    [Test]
    [HandlerFunctions('MessageHandler,PmtTolWarningAssertDocModalPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchBankStatementNoUsesAsDocNoInPmtToleranceWarningWindow()
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        VendLedgerEntry: Record "Vendor Ledger Entry";
        TolerancePct: Decimal;
        ToleranceAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Payment Tolerance]
        // [SCENARIO 213099] "Statement No." of "Bank Acc. Reconciliation" uses as "Document No." in "Payment Tolerance Warning" window when apply Bank Acc. Reconciliation Line to Purchase Invoice with Payment Discount
        Initialize();

        // [GIVEN] Payment Tolerance = 5%
        TolerancePct := LibraryRandom.RandInt(10);
        SetPmtDiscSetup(true, false, TolerancePct);

        // [GIVEN] Purchase Invoice with Posting Date = 01.01, "Pmt. Discount Date" = 10.01
        PostPurchInvoice(VendLedgerEntry, LibraryPurchase.CreateVendorNo());
        ToleranceAmount := Round(VendLedgerEntry."Remaining Amount" * TolerancePct / 100);

        // [GIVEN] Bank Account Reconciliation Line with "Statement No." = "X" "Transaction Date" = "10.01"
        CreateBankReconciliationLine(
          BankAccReconciliationLine, VendLedgerEntry."Pmt. Discount Date", VendLedgerEntry."Remaining Amount" - ToleranceAmount,
          VendLedgerEntry."Document No.");
        LibraryVariableStorage.Enqueue(BankAccReconciliationLine."Statement No."); // Set "Statement No." for "Document No." on "Payment Tolerance Warning" page
        LibraryLowerPermissions.SetBanking();

        // [WHEN] Match Bank Acc. Reconciliation Line to Purchase Invoice automatically
        MatchBankReconLineAutomatically(BankAccReconciliationLine);

        // [THEN] "Payment Tolerance Warning" page shown and "Document No." = "X"
        // Verification done in PmtTolWarningAssertDocModalPageHandler
    end;

    [Test]
    [HandlerFunctions('PmtDiscTolWarningModalPageHandler,ApplyCustomerEntriesModalPageHandler,GeneralJournalTemplateListModalPageHandler')]
    procedure PreDeductedPmtDiscAmountRemainsUnchanged()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        Customer: Record Customer;
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentTerms: Record "Payment Terms";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        CashReceiptJournal: TestPage "Cash Receipt Journal";
        InvoiceNo: Code[20];
        PaymentAmount: Decimal;
    begin
        // [SCENARIO 596009] When manually pre-deducting payment discount and applying payment within discount period,
        // the amount to apply should remain unchanged
        Initialize();

        // [GIVEN] Set up General Ledger Setup with Payment Discount Tolerance Warning and Payment Tolerance Warning enabled, "Pmt. Disc. Tolerance Posting" = 4 days
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Pmt. Disc. Tolerance Warning" := true;
        GeneralLedgerSetup."Payment Tolerance Warning" := true;
        Evaluate(GeneralLedgerSetup."Payment Discount Grace Period", '<4D>');
        GeneralLedgerSetup.Validate("Payment Discount Grace Period", GeneralLedgerSetup."Payment Discount Grace Period");
        GeneralLedgerSetup.Modify(true);

        // [GIVEN] Create Payment Terms.
        LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);

        // [GIVEN] Create Customer with the Payment Terms.
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTerms.Code);
        Customer.Modify(true);

        // [GIVEN] Create and Post Sales Invoice.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);
        InvoiceNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        CustLedgerEntry.SetAutoCalcFields(Amount);
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        CustLedgerEntry.SetRange("Document No.", InvoiceNo);
        CustLedgerEntry.FindFirst();
        PaymentAmount := CustLedgerEntry.Amount - CustLedgerEntry."Remaining Pmt. Disc. Possible";


        // [GIVEN] Create Cash Receipt Journal Line with Amount = Invoice Amount - Discount Amount.
        CreateCashReceiptJnlLineWithBankAcc(GenJournalLine, Customer."No.", PaymentAmount);
        LibraryVariableStorage.Enqueue(GenJournalLine."Journal Template Name");
        LibraryVariableStorage.Enqueue(true); // Set "Yes" on "Payment Tolerance Warning" page
        Commit();

        // [GIVEN] Open Cash Receipt Journal and Apply Entries.
        CashReceiptJournal.OpenEdit();
        CashReceiptJournal."Apply Entries".Invoke();
        GenJournalLine.Get(GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
        GenJournalLine.TestField(Amount, -PaymentAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryLowerPermissions.SetAccountReceivables();

        // [THEN] Verify Payment Discount is recorded correctly.
        DetailedCustLedgEntry.SetRange("Document No.", GenJournalLine."Document No.");
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::"Payment Discount Tolerance");
        DetailedCustLedgEntry.FindFirst();
        Assert.AreEqual(-CustLedgerEntry."Remaining Pmt. Disc. Possible", DetailedCustLedgEntry.Amount, PaymentDiscAmountErr);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Bank Pmt. Appl. Tolerance");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Bank Pmt. Appl. Tolerance");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        IsInitialized := true;
        Commit();

        LibrarySetupStorage.SaveGeneralLedgerSetup();
        LibrarySetupStorage.SavePurchasesSetup();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Bank Pmt. Appl. Tolerance");
    end;

    local procedure SetPmtDiscSetup(PaymentToleranceWarning: Boolean; PmtDiscToleranceWarning: Boolean; TolerancePct: Decimal)
    var
        PmtDiscGracePeriod: DateFormula;
    begin
        LibraryPmtDiscSetup.SetPmtToleranceWarning(PaymentToleranceWarning);
        LibraryPmtDiscSetup.SetPmtDiscToleranceWarning(PmtDiscToleranceWarning);
        Evaluate(PmtDiscGracePeriod, '<' + Format(LibraryRandom.RandInt(10)) + 'D>');
        LibraryPmtDiscSetup.SetPmtDiscGracePeriod(PmtDiscGracePeriod);
        RunChangePaymentTolerance(true, TolerancePct, 0);
    end;

    local procedure SalesPmtToleranceScenario(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var CustLedgerEntry: Record "Cust. Ledger Entry"; var ToleranceAmount: Decimal; ManualApplication: Boolean; ConfirmPmtDisc: Boolean; Sign: Integer)
    var
        PaymentApplicationProposal: Record "Payment Application Proposal";
        TolerancePct: Decimal;
    begin
        Initialize();
        TolerancePct := LibraryRandom.RandInt(10);
        SetPmtDiscSetup(true, false, TolerancePct);
        PostSalesInvoice(CustLedgerEntry, LibrarySales.CreateCustomerNo());
        ToleranceAmount := Round(CustLedgerEntry."Remaining Amount" * TolerancePct / 100);
        CreateBankReconciliationLine(
          BankAccReconciliationLine, CustLedgerEntry."Pmt. Discount Date", CustLedgerEntry."Remaining Amount" + Sign * ToleranceAmount,
          CustLedgerEntry."Document No.");
        if ManualApplication then
            SetDataForPaymentApplicationModalPageHandler(
              Format(PaymentApplicationProposal."Account Type"::Customer), CustLedgerEntry."Customer No.", CustLedgerEntry."Document No.");
        LibraryVariableStorage.Enqueue(ConfirmPmtDisc); // Set "Yes/No" on "Payment Tolerance Warning" page
    end;

    local procedure SalesPmtTolDiscScenario(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var CustLedgerEntry: Record "Cust. Ledger Entry"; ManualApplication: Boolean; ConfirmPmtDisc: Boolean)
    var
        PaymentApplicationProposal: Record "Payment Application Proposal";
    begin
        Initialize();
        SetPmtDiscSetup(false, true, 0);
        PostSalesInvoice(CustLedgerEntry, CreateCustWithPmtDisc());
        CreateBankReconciliationLine(
          BankAccReconciliationLine, CustLedgerEntry."Pmt. Disc. Tolerance Date",
          CustLedgerEntry."Remaining Amount" - CustLedgerEntry."Remaining Pmt. Disc. Possible", CustLedgerEntry."Document No.");
        if ManualApplication then
            SetDataForPaymentApplicationModalPageHandler(
              Format(PaymentApplicationProposal."Account Type"::Customer), CustLedgerEntry."Customer No.", CustLedgerEntry."Document No.");
        LibraryVariableStorage.Enqueue(ConfirmPmtDisc);
    end;

    local procedure PurchPmtToleranceScenario(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var VendLedgerEntry: Record "Vendor Ledger Entry"; var ToleranceAmount: Decimal; ManualApplication: Boolean; ConfirmPmtDisc: Boolean; Sign: Integer)
    var
        PaymentApplicationProposal: Record "Payment Application Proposal";
        TolerancePct: Decimal;
    begin
        Initialize();
        TolerancePct := LibraryRandom.RandInt(10);
        SetPmtDiscSetup(true, false, TolerancePct);
        PostPurchInvoice(VendLedgerEntry, LibraryPurchase.CreateVendorNo());
        ToleranceAmount := Round(VendLedgerEntry."Remaining Amount" * TolerancePct / 100);
        CreateBankReconciliationLine(
          BankAccReconciliationLine, VendLedgerEntry."Pmt. Discount Date", VendLedgerEntry."Remaining Amount" + Sign * ToleranceAmount,
          VendLedgerEntry."Document No.");
        if ManualApplication then
            SetDataForPaymentApplicationModalPageHandler(
              Format(PaymentApplicationProposal."Account Type"::Vendor), VendLedgerEntry."Vendor No.", VendLedgerEntry."Document No.");
        LibraryVariableStorage.Enqueue(ConfirmPmtDisc);
    end;

    local procedure PurchPmtTolDiscScenario(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var VendLedgerEntry: Record "Vendor Ledger Entry"; ManualApplication: Boolean; ConfirmPmtDisc: Boolean)
    var
        PaymentApplicationProposal: Record "Payment Application Proposal";
    begin
        Initialize();
        SetPmtDiscSetup(false, true, 0);
        PostPurchInvoice(VendLedgerEntry, CreateVendWithPmtDisc());
        CreateBankReconciliationLine(
          BankAccReconciliationLine, VendLedgerEntry."Pmt. Disc. Tolerance Date",
          VendLedgerEntry."Remaining Amount" - VendLedgerEntry."Remaining Pmt. Disc. Possible", VendLedgerEntry."Document No.");
        if ManualApplication then
            SetDataForPaymentApplicationModalPageHandler(
              Format(PaymentApplicationProposal."Account Type"::Vendor), VendLedgerEntry."Vendor No.", VendLedgerEntry."Document No.");
        LibraryVariableStorage.Enqueue(ConfirmPmtDisc);
    end;

    local procedure CreateCustWithPmtDisc(): Code[20]
    var
        PmtTerms: Record "Payment Terms";
        Cust: Record Customer;
    begin
        LibrarySales.CreateCustomer(Cust);
        LibraryERM.CreatePaymentTermsDiscount(PmtTerms, false);
        Cust.Validate("Payment Terms Code", PmtTerms.Code);
        Cust.Modify(true);
        exit(Cust."No.");
    end;

    local procedure CreateVendWithPmtDisc(): Code[20]
    var
        PmtTerms: Record "Payment Terms";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryERM.CreatePaymentTermsDiscount(PmtTerms, false);
        Vendor.Validate("Payment Terms Code", PmtTerms.Code);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure PostSalesInvoice(var CustLedgEntry: Record "Cust. Ledger Entry"; CustNo: Code[20])
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), LibraryRandom.RandInt(100));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Modify(true);

        LibraryERM.FindCustomerLedgerEntry(
          CustLedgEntry, CustLedgEntry."Document Type"::Invoice, LibrarySales.PostSalesDocument(SalesHeader, true, true));
        CustLedgEntry.CalcFields("Remaining Amount");
    end;

    local procedure PostPurchInvoice(var VendLedgEntry: Record "Vendor Ledger Entry"; VendNo: Code[20])
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchHeader, PurchHeader."Document Type"::Invoice, VendNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchLine, PurchHeader, PurchLine.Type::"G/L Account", LibraryERM.CreateGLAccountWithPurchSetup(), LibraryRandom.RandInt(100));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchLine.Modify(true);

        LibraryERM.FindVendorLedgerEntry(
          VendLedgEntry, VendLedgEntry."Document Type"::Invoice, LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true));
        VendLedgEntry.CalcFields("Remaining Amount");
    end;

    local procedure CreateBankReconciliationLine(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; TransactionDate: Date; StatementAmount: Decimal; DocNo: Code[20])
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        BankAccount.Validate("Match Tolerance Type", BankAccount."Match Tolerance Type"::Amount);
        BankAccount.Modify(true);
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccount."No.",
          BankAccReconciliation."Statement Type"::"Payment Application");
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Transaction Text", DocNo);
        BankAccReconciliationLine.Validate("Transaction Date", TransactionDate);
        BankAccReconciliationLine.Validate("Statement Amount", StatementAmount);
        BankAccReconciliationLine.Modify(true);
    end;

    local procedure MatchBankReconLineAutomatically(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        BankAccReconciliation.Get(
          BankAccReconciliationLine."Statement Type", BankAccReconciliationLine."Bank Account No.",
          BankAccReconciliationLine."Statement No.");
        CODEUNIT.Run(CODEUNIT::"Match Bank Pmt. Appl.", BankAccReconciliation);
    end;

    local procedure MatchBankReconLineManually(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        PaymentReconciliationJournal: TestPage "Payment Reconciliation Journal";
    begin
        PaymentReconciliationJournal.OpenEdit();
        PaymentReconciliationJournal.GotoRecord(BankAccReconciliationLine);
        PaymentReconciliationJournal.ApplyEntries.Invoke();
    end;

    local procedure PostReconciliation(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    var
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        BankAccReconciliation.Get(
          BankAccReconciliationLine."Statement Type", BankAccReconciliationLine."Bank Account No.",
          BankAccReconciliationLine."Statement No.");
        if (not BankAccReconciliation."Post Payments Only") then
            UpdateBankAccRecStmEndingBalance(BankAccReconciliation,
                                              BankAccReconciliation."Balance Last Statement" + BankAccReconciliationLine."Statement Amount");
        LibraryERM.PostBankAccReconciliation(BankAccReconciliation);
    end;

    local procedure UpdateBankAccRecStmEndingBalance(var BankAccRecon: Record "Bank Acc. Reconciliation"; NewStmEndingBalance: Decimal)
    begin
        BankAccRecon.Validate("Statement Ending Balance", NewStmEndingBalance);
        BankAccRecon.Modify();
    end;

    local procedure FilterPmtDiscToleranceDtldCustLedgEntry(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; EntryType: Enum "Detailed CV Ledger Entry Type"; DocNo: Code[20]; CustomerNo: Code[20])
    begin
        DetailedCustLedgEntry.SetRange("Entry Type", EntryType);
        DetailedCustLedgEntry.SetRange("Document Type", DetailedCustLedgEntry."Document Type"::Payment);
        DetailedCustLedgEntry.SetRange("Document No.", DocNo);
        DetailedCustLedgEntry.SetRange("Customer No.", CustomerNo);
    end;

    local procedure FilterPmtDiscToleranceDtldVendLedgEntry(var DetailedVendLedgEntry: Record "Detailed Vendor Ledg. Entry"; EntryType: Enum "Detailed CV Ledger Entry Type"; DocNo: Code[20]; VendorNo: Code[20])
    begin
        DetailedVendLedgEntry.SetRange("Entry Type", EntryType);
        DetailedVendLedgEntry.SetRange("Document Type", DetailedVendLedgEntry."Document Type"::Payment);
        DetailedVendLedgEntry.SetRange("Document No.", DocNo);
        DetailedVendLedgEntry.SetRange("Vendor No.", VendorNo);
    end;

    local procedure SetDataForPaymentApplicationModalPageHandler(AccountType: Text; AccountNo: Code[20]; DocNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(AccountType);
        LibraryVariableStorage.Enqueue(AccountNo);
        LibraryVariableStorage.Enqueue(DocNo);
    end;

    local procedure IncreaseStatementAmountOnBankAccReconLine(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; ToleranceAmount: Decimal)
    begin
        BankAccReconciliationLine.Find();
        BankAccReconciliationLine.Validate("Statement Amount", BankAccReconciliationLine."Statement Amount" + ToleranceAmount);
        BankAccReconciliationLine.Modify(true);
    end;

    local procedure RunChangePaymentTolerance(AllCurrency: Boolean; PaymentTolerance: Decimal; MaxPaymentToleranceAmount: Decimal)
    var
        ChangePaymentTolerance: Report "Change Payment Tolerance";
    begin
        Clear(ChangePaymentTolerance);
        ChangePaymentTolerance.InitializeRequest(AllCurrency, '', PaymentTolerance, MaxPaymentToleranceAmount);
        ChangePaymentTolerance.UseRequestPage(false);
        ChangePaymentTolerance.Run();
    end;

    local procedure VerifyCustLedgEntry(EntryNo: Integer; ExpectedAmount: Decimal)
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgEntry.Get(EntryNo);
        CustLedgEntry.CalcFields("Remaining Amount");
        CustLedgEntry.TestField("Remaining Amount", ExpectedAmount);
    end;

    local procedure VerifyVendLedgEntry(EntryNo: Integer; ExpectedAmount: Decimal)
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        VendLedgEntry.Get(EntryNo);
        VendLedgEntry.CalcFields("Remaining Amount");
        VendLedgEntry.TestField("Remaining Amount", ExpectedAmount);
    end;

    local procedure VerifyAppliedPmtEntry(BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; AppliedAmount: Decimal; AppliedPmtDiscount: Decimal)
    var
        AppliedPmtEntry: Record "Applied Payment Entry";
    begin
        AppliedPmtEntry.FilterAppliedPmtEntry(BankAccReconciliationLine);
        AppliedPmtEntry.FindFirst();
        AppliedPmtEntry.TestField("Applied Amount", AppliedAmount);
        AppliedPmtEntry.TestField("Applied Pmt. Discount", AppliedPmtDiscount);
    end;

    local procedure CreateCashReceiptJnlLineWithBankAcc(var GenJournalLine: Record "Gen. Journal Line"; AccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateBankAccount(BankAccount);

        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        GenJournalTemplate.Validate(Type, GenJournalTemplate.Type::"Cash Receipts");
        GenJournalTemplate.Modify(true);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, AccountNo,
            GenJournalLine."Bal. Account Type"::"Bank Account", BankAccount."No.", -Amount);
        GenJournalLine.Validate("Posting Date", WorkDate() + 3);
        GenJournalLine.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PmtTolWarningModalPageHandler(var PaymentToleranceWarning: TestPage "Payment Tolerance Warning")
    begin
        if LibraryVariableStorage.DequeueBoolean() then begin
            PaymentToleranceWarning.Posting.SetValue(1); // Accept payment discount tolerance
            PaymentToleranceWarning.Yes().Invoke();
        end else
            PaymentToleranceWarning.No().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PmtTolWarningAssertDocModalPageHandler(var PaymentToleranceWarning: TestPage "Payment Tolerance Warning")
    begin
        PaymentToleranceWarning.DocNo.AssertEquals(LibraryVariableStorage.DequeueText());
        PaymentToleranceWarning.No().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PmtDiscTolWarningModalPageHandler(var PaymentDiscToleranceWarning: TestPage "Payment Disc Tolerance Warning")
    begin
        if LibraryVariableStorage.DequeueBoolean() then begin
            PaymentDiscToleranceWarning.Posting.SetValue(1); // Accept payment discount tolerance
            PaymentDiscToleranceWarning.Yes().Invoke();
        end else
            PaymentDiscToleranceWarning.No().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PaymentApplicationModalPageHandler(var PaymentApplication: TestPage "Payment Application")
    var
        PaymentApplicationProposal: Record "Payment Application Proposal";
    begin
        PaymentApplication.FILTER.SetFilter("Account Type", LibraryVariableStorage.DequeueText());
        PaymentApplication.FILTER.SetFilter("Account No.", LibraryVariableStorage.DequeueText());
        PaymentApplication.FILTER.SetFilter("Document Type", Format(PaymentApplicationProposal."Document Type"::Invoice));
        PaymentApplication.FILTER.SetFilter("Document No.", LibraryVariableStorage.DequeueText());
        PaymentApplication.Applied.SetValue(true);
        PaymentApplication.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure TransToDiffAccModalPageHandler(var TransferDifferencetoAccount: TestPage "Transfer Difference to Account")
    begin
        TransferDifferencetoAccount."Account No.".SetValue(LibraryERM.CreateGLAccountNo());
        TransferDifferencetoAccount.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostAndReconcilePageHandler(var PostPmtsAndRecBankAcc: TestPage "Post Pmts and Rec. Bank Acc.")
    begin
        PostPmtsAndRecBankAcc.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GeneralJournalTemplateListModalPageHandler(var GeneralJournalTemplateList: TestPage "General Journal Template List")
    begin
        GeneralJournalTemplateList.GotoKey(LibraryVariableStorage.DequeueText());
        GeneralJournalTemplateList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries.OK().Invoke();
    end;
}

