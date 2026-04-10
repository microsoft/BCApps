codeunit 134010 "ERM Application Customer"
{
    Permissions = TableData "Cust. Ledger Entry" = rimd;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Sales] [Application]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryERMCustomerWatch: Codeunit "Library - ERM Customer Watch";
        LibraryPmtDiscSetup: Codeunit "Library - Pmt Disc Setup";
        LibrarySales: Codeunit "Library - Sales";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        DeltaAssert: Codeunit "Delta Assert";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        WrongBalancePerTransNoErr: Label 'Wrong total amount of detailed entries per transaction.';

    [Test]
    [Scope('OnPrem')]
    procedure CustomerNoDiscount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize();

        for Stepwise := false to true do begin
            CustomerInvPmt(GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Invoice, GetCustomerAmount(), Stepwise);
            CustomerInvPmt(GenJournalLine."Document Type"::Refund, GenJournalLine."Document Type"::"Credit Memo", -GetCustomerAmount(), Stepwise);
            CustomerInvPmt(GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Refund, GetCustomerAmount(), Stepwise);
            CustomerInvPmt(GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::"Credit Memo", -GetCustomerAmount(), Stepwise);
        end;

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerDiscount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize();

        for Stepwise := false to true do begin
            CustomerInvPmtDisc(GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Invoice, GetCustomerAmount(), Stepwise);
            CustomerInvPmtDisc(GenJournalLine."Document Type"::Refund, GenJournalLine."Document Type"::"Credit Memo", -GetCustomerAmount(), Stepwise);
            // The following two combinations do not generate discount ledger entries and will thus fail to close.
            asserterror CustomerInvPmtDisc(GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Refund, GetCustomerAmount(), Stepwise);
            DeltaAssert.Reset();
            asserterror CustomerInvPmtDisc(GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::"Credit Memo", -GetCustomerAmount(), Stepwise);
            DeltaAssert.Reset();
        end;

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerVAT()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize();

        for Stepwise := false to true do begin
            CustomerInvPmtVAT(GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Invoice, GetCustomerAmount(), Stepwise);
            CustomerInvPmtVAT(GenJournalLine."Document Type"::Refund, GenJournalLine."Document Type"::"Credit Memo", -GetCustomerAmount(), Stepwise);
            CustomerInvPmtVAT(GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Refund, GetCustomerAmount(), Stepwise);
            CustomerInvPmtVAT(GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::"Credit Memo", -GetCustomerAmount(), Stepwise);
        end;

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerCorrection()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize();

        for Stepwise := false to true do begin
            CustomerInvPmtCorrection(GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Invoice, GetCustomerAmount(), Stepwise);
            CustomerInvPmtCorrection(GenJournalLine."Document Type"::Refund, GenJournalLine."Document Type"::"Credit Memo", -GetCustomerAmount(), Stepwise);
            CustomerInvPmtCorrection(GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Refund, GetCustomerAmount(), Stepwise);
            CustomerInvPmtCorrection(GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::"Credit Memo", -GetCustomerAmount(), Stepwise);
        end;

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerDiscVATAdjust()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize();

        for Stepwise := false to true do begin
            CustomerPmtDiscVATAdjust(GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Invoice, GetCustomerAmount(), Stepwise);
            CustomerPmtDiscVATAdjust(GenJournalLine."Document Type"::Refund, GenJournalLine."Document Type"::"Credit Memo", -GetCustomerAmount(), Stepwise);
            // The following two combinations do not generate payment tolerance ledger entries and will thus fail to close.
            asserterror CustomerPmtDiscVATAdjust(GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Refund, GetCustomerAmount(), Stepwise);
            asserterror CustomerPmtDiscVATAdjust(GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::"Credit Memo", -GetCustomerAmount(), Stepwise);
        end;

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerTolVATAdjust()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize();

        SetupPaymentTolerance();

        for Stepwise := false to true do begin
            CustomerPmtTolVATAdjust(GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Invoice, GetCustomerAmount(), Stepwise);
            CustomerPmtTolVATAdjust(GenJournalLine."Document Type"::Refund, GenJournalLine."Document Type"::"Credit Memo", -GetCustomerAmount(), Stepwise);
            // The following two combinations do not generate payment tolerance ledger entries and will thus fail to close.
            asserterror CustomerPmtTolVATAdjust(GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Refund, GetCustomerAmount(), Stepwise);
            asserterror CustomerPmtTolVATAdjust(GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::"Credit Memo", -GetCustomerAmount(), Stepwise);
        end;

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerDiscTolVATAdjust()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize();

        LibraryPmtDiscSetup.SetPmtDiscGracePeriodByText('<5D>');

        for Stepwise := false to true do begin
            CustomerPmtDiscTolVATAdjust(GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Invoice, GetCustomerAmount(), Stepwise);
            CustomerPmtDiscTolVATAdjust(GenJournalLine."Document Type"::Refund, GenJournalLine."Document Type"::"Credit Memo", -GetCustomerAmount(), Stepwise);
            // The following two combinations do not generate payment discount / tolerance ledger entries and will thus fail to close.
            asserterror CustomerPmtDiscTolVATAdjust(GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Refund, GetCustomerAmount(), Stepwise);
            asserterror CustomerPmtDiscTolVATAdjust(GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::"Credit Memo", -GetCustomerAmount(), Stepwise);
        end;

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerRealizedGain()
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize();

        for Stepwise := false to true do begin
            CustomerRealizedAdjust(GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Invoice, GetCustomerAmount(), Stepwise,
              0.9, DtldCustLedgEntry."Entry Type"::"Realized Loss");
            CustomerRealizedAdjust(GenJournalLine."Document Type"::Refund, GenJournalLine."Document Type"::"Credit Memo", -GetCustomerAmount(), Stepwise,
              1.1, DtldCustLedgEntry."Entry Type"::"Realized Loss");
            CustomerRealizedAdjust(GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Refund, GetCustomerAmount(), Stepwise,
              0.9, DtldCustLedgEntry."Entry Type"::"Realized Loss");
            CustomerRealizedAdjust(GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::"Credit Memo", -GetCustomerAmount(), Stepwise,
              1.1, DtldCustLedgEntry."Entry Type"::"Realized Loss");
        end;

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerRealizedLoss()
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize();

        for Stepwise := false to true do begin
            CustomerRealizedAdjust(GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Invoice, GetCustomerAmount(), Stepwise,
              1.1, DtldCustLedgEntry."Entry Type"::"Realized Gain");
            CustomerRealizedAdjust(GenJournalLine."Document Type"::Refund, GenJournalLine."Document Type"::"Credit Memo", -GetCustomerAmount(), Stepwise,
              0.9, DtldCustLedgEntry."Entry Type"::"Realized Gain");
            CustomerRealizedAdjust(GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Refund, GetCustomerAmount(), Stepwise,
              1.1, DtldCustLedgEntry."Entry Type"::"Realized Gain");
            CustomerRealizedAdjust(GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::"Credit Memo", -GetCustomerAmount(), Stepwise,
              0.9, DtldCustLedgEntry."Entry Type"::"Realized Gain");
        end;

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerUnrealizedGain()
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize();

        for Stepwise := false to true do begin
            CustomerUnrealizedAdjust(GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Invoice, GetCustomerAmount(), Stepwise,
              0.9, DtldCustLedgEntry."Entry Type"::"Realized Loss");
            CustomerUnrealizedAdjust(GenJournalLine."Document Type"::Refund, GenJournalLine."Document Type"::"Credit Memo", -GetCustomerAmount(), Stepwise,
              1.1, DtldCustLedgEntry."Entry Type"::"Realized Loss");
            CustomerUnrealizedAdjust(GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Refund, GetCustomerAmount(), Stepwise,
              0.9, DtldCustLedgEntry."Entry Type"::"Realized Loss");
            CustomerUnrealizedAdjust(GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::"Credit Memo", -GetCustomerAmount(), Stepwise,
              1.1, DtldCustLedgEntry."Entry Type"::"Realized Loss");
        end;

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CustomerUnrealizedLoss()
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalLine: Record "Gen. Journal Line";
        Stepwise: Boolean;
    begin
        Initialize();

        for Stepwise := false to true do begin
            CustomerUnrealizedAdjust(GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Invoice, GetCustomerAmount(), Stepwise,
              1.1, DtldCustLedgEntry."Entry Type"::"Realized Gain");
            CustomerUnrealizedAdjust(GenJournalLine."Document Type"::Refund, GenJournalLine."Document Type"::"Credit Memo", -GetCustomerAmount(), Stepwise,
              0.9, DtldCustLedgEntry."Entry Type"::"Realized Gain");
            CustomerUnrealizedAdjust(GenJournalLine."Document Type"::Payment, GenJournalLine."Document Type"::Refund, GetCustomerAmount(), Stepwise,
              1.1, DtldCustLedgEntry."Entry Type"::"Realized Gain");
            CustomerUnrealizedAdjust(GenJournalLine."Document Type"::Invoice, GenJournalLine."Document Type"::"Credit Memo", -GetCustomerAmount(), Stepwise,
              0.9, DtldCustLedgEntry."Entry Type"::"Realized Gain");
        end;

        TearDown();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FutureCurrAdjTransaction()
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        CurrencyCode: Code[10];
        DocumentNo: Code[20];
        LastTransactionNo: array[2] of Integer;
        TransactionNo: Integer;
        i: Integer;
        TotalAmount: Decimal;
        InvAmount: Decimal;
    begin
        // [FEATURE] [Adjust Exchange Rates] [Transaction No.]
        // [SCENARIO] Currency Adjustment job posts Detailed Customer Ledger Entries linked by "Transaction No." with related G/L Entries
        Initialize();

        // [GIVEN] Currency "FCY" with different rates on Workdate and on (WorkDate() + 1)
        CurrencyCode := SetExchRateForCurrency(2);

        LibrarySales.CreateCustomer(Customer);

        GetGLBalancedBatch(GenJournalTemplate, GenJournalBatch, GenJournalTemplate.Type::General);
        for i := 1 to 3 do begin
            // [GIVEN] Post Invoice in "FCY" on WorkDate
            InvAmount := LibraryRandom.RandDec(1000, 2);
            DocumentNo :=
              CreateJournalLine(
                GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer,
                Customer."No.", InvAmount, '<0D>', CurrencyCode, LibraryUtility.GenerateGUID(), '');
            RunGenJnlPostLine(GenJournalLine);
            // [GIVEN] Post 1st partial Payment in "FCY" on WorkDate with application to Invoice
            CreateJournalLine(
              GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer,
              Customer."No.", -InvAmount / (i + 1), '<0D>', CurrencyCode, LibraryUtility.GenerateGUID(), '');
            GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
            GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
            GenJournalLine.Modify();
            RunGenJnlPostLine(GenJournalLine);
            // [GIVEN] Post 2nd partial Payment in "FCY" on (WorkDate() + 2) with application to Invoice
            CreateJournalLine(
              GenJournalLine, GenJournalBatch, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer,
              Customer."No.", -InvAmount - GenJournalLine.Amount, '<2D>', CurrencyCode, LibraryUtility.GenerateGUID(), '');
            GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
            GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
            GenJournalLine.Modify();
            RunGenJnlPostLine(GenJournalLine);
        end;

        LastTransactionNo[1] := GetLastTransactionNo();

        // [WHEN] Run the Adjust Exchange Rates Batch job on (WorkDate() + 1)
        LibraryERM.RunExchRateAdjustmentSimple(
          CurrencyCode, CalcDate('<1D>', WorkDate()), CalcDate('<1D>', WorkDate()));

        // [THEN] posted G/L Entries on different dates have different "Transaction No."
        // [THEN] Dtld. Customer Ledger Entries have same "Transaction No." with related G/L Entries
        LastTransactionNo[2] := GetLastTransactionNo();
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        for TransactionNo := LastTransactionNo[1] + 1 to LastTransactionNo[2] do begin
            GLEntry.SetRange("Transaction No.", TransactionNo);
            GLEntry.SetRange("G/L Account No.", CustomerPostingGroup."Receivables Account");
            GLEntry.FindLast();
            TotalAmount := 0;
            DtldCustLedgEntry.SetRange("Transaction No.", TransactionNo);
            DtldCustLedgEntry.FindSet();
            repeat
                TotalAmount += DtldCustLedgEntry."Amount (LCY)";
            until DtldCustLedgEntry.Next() = 0;
            Assert.AreEqual(GLEntry.Amount, TotalAmount, WrongBalancePerTransNoErr);
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_ApplyMultipleLedgEntriesBySetAppliesToId()
    var
        ApplyingCustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        CustEntrySetApplID: Codeunit "Cust. Entry-SetAppl.ID";
        AppliesToID: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 213825] Multiple customer ledger entries applies when call SetApplId function of codeunit "Cust. Entry-SetAppl.ID"

        Initialize();
        MockCustLedgEntry(ApplyingCustLedgerEntry);
        MockCustLedgEntry(CustLedgerEntry);
        MockCustLedgEntry(CustLedgerEntry2);
        CustLedgerEntry.SetRange("Entry No.", CustLedgerEntry."Entry No.", CustLedgerEntry2."Entry No.");
        AppliesToID := LibraryUtility.GenerateGUID();

        CustEntrySetApplID.SetApplId(CustLedgerEntry, ApplyingCustLedgerEntry, AppliesToID);

        VerifyAppliedLedgerEntry(CustLedgerEntry, AppliesToID);
        VerifyAppliedLedgerEntry(CustLedgerEntry2, AppliesToID);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UT_ClearApplicationInforForMultipleAlreadyAppliedLedgEntriesBySetAppliesToId()
    var
        ApplyingCustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        CustEntrySetApplID: Codeunit "Cust. Entry-SetAppl.ID";
        AppliesToID: Code[20];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 213825] Application information clears for already applied customer ledger entries when call SetApplId function of codeunit "Cust. Entry-SetAppl.ID"

        Initialize();
        MockCustLedgEntry(ApplyingCustLedgerEntry);
        MockAppliedCustLedgEntry(CustLedgerEntry);
        MockAppliedCustLedgEntry(CustLedgerEntry2);
        CustLedgerEntry.SetRange("Entry No.", CustLedgerEntry."Entry No.", CustLedgerEntry2."Entry No.");
        AppliesToID := LibraryUtility.GenerateGUID();

        CustEntrySetApplID.SetApplId(CustLedgerEntry, ApplyingCustLedgerEntry, AppliesToID);

        VerifyUnappliedLedgerEntry(CustLedgerEntry);
        VerifyUnappliedLedgerEntry(CustLedgerEntry2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PaymentTwoInvoiceSetAppliesToIdFromGeneralJournal()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        InvoiceAmount: Decimal;
        PaymentAmount: Decimal;
    begin
        // [FEATURE] [General Journal]
        // [SCENARIO 342909] System clean "Applies-to ID" field in customer ledger entry when it is generated from general journal line applied to customer ledger entry
        Initialize();

        LibrarySales.CreateCustomer(Customer);

        InvoiceAmount := LibraryRandom.RandIntInRange(10, 20);
        PaymentAmount := -InvoiceAmount * 3;

        // Invoice 1
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.", InvoiceAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Invoice 2
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.", InvoiceAmount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Payment 1 with false "Applies-to ID"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, Customer."No.", PaymentAmount);
        GenJournalLine."Applies-to ID" := GenJournalLine."Document No.";
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");
        CustLedgerEntry.TestField("Applies-to ID", '');

        // Payment 2 with true "Applies-to ID"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Customer, Customer."No.", PaymentAmount);

        Clear(CustLedgerEntry);
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);
        CustLedgerEntry.ModifyAll("Applies-to ID", GenJournalLine."Document No.");

        GenJournalLine."Applies-to ID" := GenJournalLine."Document No.";
        GenJournalLine.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        CustLedgerEntry.FindSet();
        repeat
            CustLedgerEntry.TestField(Open, false);
        until CustLedgerEntry.Next() = 0;
        Assert.RecordCount(CustLedgerEntry, 2);

        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, CustLedgerEntry."Document Type"::Payment, GenJournalLine."Document No.");
        CustLedgerEntry.TestField("Applies-to ID", '');
    end;

    [Test]
    procedure ApplyLCYInvoiceToFCYPaymentWithGLSetupApplRounding()
    var
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntryApplying: Record "Cust. Ledger Entry";
        CustLedgerEntryApplied: Record "Cust. Ledger Entry";
        GLApplicationRoundingPrecision: Decimal;
        FCYApplicationRoundingPrecision: Decimal;
        ExchangeRate: Decimal;
        LCYAmount: Decimal;
        AmountDifference: Decimal;
    begin
        // [FEATURE] [Rounding] [FCY] [Payment] [Invoice]
        // [SCENARIO 380201] System generates "Appln. Rounding" DCLE when Stan applies LCY Invoice to FCY Payment when "Appln. Rounding Precision" specified in G/L Setup
        Initialize();

        AmountDifference := LibraryRandom.RandIntInRange(15, 20);
        GLApplicationRoundingPrecision := AmountDifference * 1.1;
        FCYApplicationRoundingPrecision := 0;
        ExchangeRate := LibraryRandom.RandDecInRange(10, 20, 2);
        LCYAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);

        LibraryERM.SetApplnRoundingPrecision(GLApplicationRoundingPrecision);

        CreateCurrencyWithApplicationRoundingPrecision(Currency, FCYApplicationRoundingPrecision, ExchangeRate);

        ScenarioPostDocumentAndApplyToOtherDocumentFCYApplnRounding(
          GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Document Type"::Payment,
          '', Currency.Code,
          LCYAmount, -(LCYAmount * ExchangeRate + AmountDifference),
          CustLedgerEntryApplying, CustLedgerEntryApplied);

        VerifyCustomerEntriesClosed(CustLedgerEntryApplying);
        VerifyRoundingDtldEntryExists(CustLedgerEntryApplying);

        VerifyCustomerEntriesClosed(CustLedgerEntryApplied);
        VerifyRoundingDtldEntryDoesnotExist(CustLedgerEntryApplied);
    end;

    [Test]
    procedure ApplyLCYInvoiceToFCYPaymentWithoutGLSetupApplRounding()
    var
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntryApplying: Record "Cust. Ledger Entry";
        CustLedgerEntryApplied: Record "Cust. Ledger Entry";
        GLApplicationRoundingPrecision: Decimal;
        FCYApplicationRoundingPrecision: Decimal;
        ExchangeRate: Decimal;
        LCYAmount: Decimal;
        AmountDifference: Decimal;
    begin
        // [FEATURE] [Rounding] [FCY] [Payment] [Invoice]
        // [SCENARIO 380201] System doesn't generate "Appln. Rounding" DCLE when Stan applies LCY Invoice to FCY Payment when "Appln. Rounding Precision" is not specified in G/L Setup
        Initialize();

        AmountDifference := LibraryRandom.RandIntInRange(15, 20);
        GLApplicationRoundingPrecision := 0;
        FCYApplicationRoundingPrecision := 0;
        ExchangeRate := LibraryRandom.RandDecInRange(10, 20, 2);
        LCYAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);

        LibraryERM.SetApplnRoundingPrecision(GLApplicationRoundingPrecision);

        CreateCurrencyWithApplicationRoundingPrecision(Currency, FCYApplicationRoundingPrecision, ExchangeRate);

        ScenarioPostDocumentAndApplyToOtherDocumentFCYApplnRounding(
          GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Document Type"::Payment,
          '', Currency.Code,
          LCYAmount, -(LCYAmount * ExchangeRate + AmountDifference),
          CustLedgerEntryApplying, CustLedgerEntryApplied);

        VerifyCustomerEntriesClosed(CustLedgerEntryApplying);
        VerifyRoundingDtldEntryDoesnotExist(CustLedgerEntryApplying);

        VerifyCustomerEntriesOpen(CustLedgerEntryApplied);
        VerifyRoundingDtldEntryDoesnotExist(CustLedgerEntryApplied);
    end;

    [Test]
    procedure ApplyLCYPaymentToFCYInvoiceWithGLSetupApplRounding()
    var
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntryApplying: Record "Cust. Ledger Entry";
        CustLedgerEntryApplied: Record "Cust. Ledger Entry";
        GLApplicationRoundingPrecision: Decimal;
        FCYApplicationRoundingPrecision: Decimal;
        ExchangeRate: Decimal;
        LCYAmount: Decimal;
        AmountDifference: Decimal;
    begin
        // [FEATURE] [Rounding] [FCY] [Payment] [Invoice]
        // [SCENARIO 380201] System generates "Appln. Rounding" DCLE when Stan applies LCY Payment to FCY Invoice when "Appln. Rounding Precision" specified in G/L Setup
        Initialize();

        AmountDifference := LibraryRandom.RandIntInRange(15, 20);
        GLApplicationRoundingPrecision := AmountDifference * 1.1;
        FCYApplicationRoundingPrecision := 0;
        ExchangeRate := LibraryRandom.RandDecInRange(10, 20, 2);
        LCYAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);

        LibraryERM.SetApplnRoundingPrecision(GLApplicationRoundingPrecision);

        CreateCurrencyWithApplicationRoundingPrecision(Currency, FCYApplicationRoundingPrecision, ExchangeRate);

        ScenarioPostDocumentAndApplyToOtherDocumentFCYApplnRounding(
          GenJournalLine."Document Type"::Payment,
          GenJournalLine."Document Type"::Invoice,
          '', Currency.Code,
          -LCYAmount, LCYAmount * ExchangeRate + AmountDifference,
          CustLedgerEntryApplying, CustLedgerEntryApplied);

        VerifyCustomerEntriesClosed(CustLedgerEntryApplying);
        VerifyRoundingDtldEntryExists(CustLedgerEntryApplying);

        VerifyCustomerEntriesClosed(CustLedgerEntryApplied);
        VerifyRoundingDtldEntryDoesnotExist(CustLedgerEntryApplied);
    end;

    [Test]
    procedure ApplyLCYPaymentToFCYInvoiceWithoutGLSetupApplRounding()
    var
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntryApplying: Record "Cust. Ledger Entry";
        CustLedgerEntryApplied: Record "Cust. Ledger Entry";
        GLApplicationRoundingPrecision: Decimal;
        FCYApplicationRoundingPrecision: Decimal;
        ExchangeRate: Decimal;
        LCYAmount: Decimal;
        AmountDifference: Decimal;
    begin
        // [FEATURE] [Rounding] [FCY] [Payment] [Invoice]
        // [SCENARIO 380201] System doesn't generate "Appln. Rounding" DCLE when Stan applies LCY Payment to FCY Invoice when "Appln. Rounding Precision" is not specified in G/L Setup
        Initialize();

        AmountDifference := LibraryRandom.RandIntInRange(15, 20);
        GLApplicationRoundingPrecision := 0;
        FCYApplicationRoundingPrecision := 0;
        ExchangeRate := LibraryRandom.RandDecInRange(10, 20, 2);
        LCYAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);

        LibraryERM.SetApplnRoundingPrecision(GLApplicationRoundingPrecision);

        CreateCurrencyWithApplicationRoundingPrecision(Currency, FCYApplicationRoundingPrecision, ExchangeRate);

        ScenarioPostDocumentAndApplyToOtherDocumentFCYApplnRounding(
          GenJournalLine."Document Type"::Payment,
          GenJournalLine."Document Type"::Invoice,
          '', Currency.Code,
          -LCYAmount, LCYAmount * ExchangeRate + AmountDifference,
          CustLedgerEntryApplying, CustLedgerEntryApplied);

        VerifyCustomerEntriesClosed(CustLedgerEntryApplying);
        VerifyRoundingDtldEntryDoesnotExist(CustLedgerEntryApplying);

        VerifyCustomerEntriesOpen(CustLedgerEntryApplied);
        VerifyRoundingDtldEntryDoesnotExist(CustLedgerEntryApplied);
    end;

    [Test]
    procedure ApplyLCYPaymentToFCYRefundWithGLSetupApplRounding()
    var
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntryApplying: Record "Cust. Ledger Entry";
        CustLedgerEntryApplied: Record "Cust. Ledger Entry";
        GLApplicationRoundingPrecision: Decimal;
        FCYApplicationRoundingPrecision: Decimal;
        ExchangeRate: Decimal;
        LCYAmount: Decimal;
        AmountDifference: Decimal;
    begin
        // [FEATURE] [Rounding] [FCY] [Payment] [Refund]
        // [SCENARIO 380201] System generates "Appln. Rounding" DCLE when Stan applies LCY Payment to FCY Refund when "Appln. Rounding Precision" specified in G/L Setup
        Initialize();

        AmountDifference := LibraryRandom.RandIntInRange(15, 20);
        GLApplicationRoundingPrecision := AmountDifference * 1.1;
        FCYApplicationRoundingPrecision := 0;
        ExchangeRate := LibraryRandom.RandDecInRange(10, 20, 2);
        LCYAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);

        LibraryERM.SetApplnRoundingPrecision(GLApplicationRoundingPrecision);

        CreateCurrencyWithApplicationRoundingPrecision(Currency, FCYApplicationRoundingPrecision, ExchangeRate);

        ScenarioPostDocumentAndApplyToOtherDocumentFCYApplnRounding(
          GenJournalLine."Document Type"::Payment,
          GenJournalLine."Document Type"::Refund,
          '', Currency.Code,
          -LCYAmount, LCYAmount * ExchangeRate + AmountDifference,
          CustLedgerEntryApplying, CustLedgerEntryApplied);

        VerifyCustomerEntriesClosed(CustLedgerEntryApplying);
        VerifyRoundingDtldEntryExists(CustLedgerEntryApplying);

        VerifyCustomerEntriesClosed(CustLedgerEntryApplied);
        VerifyRoundingDtldEntryDoesnotExist(CustLedgerEntryApplied);
    end;

    [Test]
    procedure ApplyLCYPaymentToFCYRefundWithoutGLSetupApplRounding()
    var
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntryApplying: Record "Cust. Ledger Entry";
        CustLedgerEntryApplied: Record "Cust. Ledger Entry";
        GLApplicationRoundingPrecision: Decimal;
        FCYApplicationRoundingPrecision: Decimal;
        ExchangeRate: Decimal;
        LCYAmount: Decimal;
        AmountDifference: Decimal;
    begin
        // [FEATURE] [Rounding] [FCY] [Payment] [Refund]
        // [SCENARIO 380201] System doesn't generate "Appln. Rounding" DCLE when Stan applies LCY Payment to FCY Refund when "Appln. Rounding Precision" is not specified in G/L Setup
        Initialize();

        AmountDifference := LibraryRandom.RandIntInRange(15, 20);
        GLApplicationRoundingPrecision := 0;
        FCYApplicationRoundingPrecision := 0;
        ExchangeRate := LibraryRandom.RandDecInRange(10, 20, 2);
        LCYAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);

        LibraryERM.SetApplnRoundingPrecision(GLApplicationRoundingPrecision);

        CreateCurrencyWithApplicationRoundingPrecision(Currency, FCYApplicationRoundingPrecision, ExchangeRate);

        ScenarioPostDocumentAndApplyToOtherDocumentFCYApplnRounding(
          GenJournalLine."Document Type"::Payment,
          GenJournalLine."Document Type"::Refund,
          '', Currency.Code,
          -LCYAmount, LCYAmount * ExchangeRate + AmountDifference,
          CustLedgerEntryApplying, CustLedgerEntryApplied);

        VerifyCustomerEntriesClosed(CustLedgerEntryApplying);
        VerifyRoundingDtldEntryDoesnotExist(CustLedgerEntryApplying);

        VerifyCustomerEntriesOpen(CustLedgerEntryApplied);
        VerifyRoundingDtldEntryDoesnotExist(CustLedgerEntryApplied);
    end;

    [Test]
    procedure ApplyLCYRefundToFCYPaymentWithGLSetupApplRounding()
    var
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntryApplying: Record "Cust. Ledger Entry";
        CustLedgerEntryApplied: Record "Cust. Ledger Entry";
        GLApplicationRoundingPrecision: Decimal;
        FCYApplicationRoundingPrecision: Decimal;
        ExchangeRate: Decimal;
        LCYAmount: Decimal;
        AmountDifference: Decimal;
    begin
        // [FEATURE] [Rounding] [FCY] [Payment] [Refund]
        // [SCENARIO 380201] System generates "Appln. Rounding" DCLE when Stan applies LCY Payment to FCY Invoice when "Appln. Rounding Precision" specified in G/L Setup
        Initialize();

        AmountDifference := LibraryRandom.RandIntInRange(15, 20);
        GLApplicationRoundingPrecision := AmountDifference * 1.1;
        FCYApplicationRoundingPrecision := 0;
        ExchangeRate := LibraryRandom.RandDecInRange(10, 20, 2);
        LCYAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);

        LibraryERM.SetApplnRoundingPrecision(GLApplicationRoundingPrecision);

        CreateCurrencyWithApplicationRoundingPrecision(Currency, FCYApplicationRoundingPrecision, ExchangeRate);

        ScenarioPostDocumentAndApplyToOtherDocumentFCYApplnRounding(
          GenJournalLine."Document Type"::Refund,
          GenJournalLine."Document Type"::Payment,
          '', Currency.Code,
          LCYAmount, -(LCYAmount * ExchangeRate + AmountDifference),
          CustLedgerEntryApplying, CustLedgerEntryApplied);

        VerifyCustomerEntriesClosed(CustLedgerEntryApplying);
        VerifyRoundingDtldEntryExists(CustLedgerEntryApplying);

        VerifyCustomerEntriesClosed(CustLedgerEntryApplied);
        VerifyRoundingDtldEntryDoesnotExist(CustLedgerEntryApplied);
    end;

    [Test]
    procedure ApplyLCYRefundToFCYPaymentWithoutGLSetupApplRounding()
    var
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntryApplying: Record "Cust. Ledger Entry";
        CustLedgerEntryApplied: Record "Cust. Ledger Entry";
        GLApplicationRoundingPrecision: Decimal;
        FCYApplicationRoundingPrecision: Decimal;
        ExchangeRate: Decimal;
        LCYAmount: Decimal;
        AmountDifference: Decimal;
    begin
        // [FEATURE] [Rounding] [FCY] [Payment] [Refund]
        // [SCENARIO 380201] System doesn't generate "Appln. Rounding" DCLE when Stan applies LCY Payment to FCY Invoice when "Appln. Rounding Precision" is not specified in G/L Setup
        Initialize();

        AmountDifference := LibraryRandom.RandIntInRange(15, 20);
        GLApplicationRoundingPrecision := 0;
        FCYApplicationRoundingPrecision := 0;
        ExchangeRate := LibraryRandom.RandDecInRange(10, 20, 2);
        LCYAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);

        LibraryERM.SetApplnRoundingPrecision(GLApplicationRoundingPrecision);

        CreateCurrencyWithApplicationRoundingPrecision(Currency, FCYApplicationRoundingPrecision, ExchangeRate);

        ScenarioPostDocumentAndApplyToOtherDocumentFCYApplnRounding(
          GenJournalLine."Document Type"::Refund,
          GenJournalLine."Document Type"::Payment,
          '', Currency.Code,
          LCYAmount, -(LCYAmount * ExchangeRate + AmountDifference),
          CustLedgerEntryApplying, CustLedgerEntryApplied);

        VerifyCustomerEntriesClosed(CustLedgerEntryApplying);
        VerifyRoundingDtldEntryDoesnotExist(CustLedgerEntryApplying);

        VerifyCustomerEntriesOpen(CustLedgerEntryApplied);
        VerifyRoundingDtldEntryDoesnotExist(CustLedgerEntryApplied);
    end;

    [Test]
    procedure ApplyFCYInvoiceToFCYPaymentWithCurrencyApplRounding()
    var
        Currency: array[2] of Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntryApplying: Record "Cust. Ledger Entry";
        CustLedgerEntryApplied: Record "Cust. Ledger Entry";
        GLApplicationRoundingPrecision: Decimal;
        FCYApplicationRoundingPrecision: array[2] of Decimal;
        ExchangeRate: array[2] of Decimal;
        LCYAmount: Decimal;
        AmountDifference: Decimal;
    begin
        // [FEATURE] [Rounding] [FCY] [Payment] [Invoice]
        // [SCENARIO 380201] System gets "Appln. Rounding Precision" from Invoice's currency when Stan applies FCY[1] Invoice to FCY[2] Payment
        Initialize();

        AmountDifference := LibraryRandom.RandIntInRange(15, 20);
        ExchangeRate[1] := LibraryRandom.RandDecInRange(10, 20, 2);
        ExchangeRate[2] := LibraryRandom.RandDecInRange(10, 20, 2);
        LCYAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);

        GLApplicationRoundingPrecision := 0;

        FCYApplicationRoundingPrecision[1] := AmountDifference * 1.5 * ExchangeRate[1];
        FCYApplicationRoundingPrecision[2] := AmountDifference * 0.5 * ExchangeRate[2];

        LibraryERM.SetApplnRoundingPrecision(GLApplicationRoundingPrecision);

        CreateCurrencyWithApplicationRoundingPrecision(Currency[1], FCYApplicationRoundingPrecision[1], ExchangeRate[1]);
        CreateCurrencyWithApplicationRoundingPrecision(Currency[2], FCYApplicationRoundingPrecision[2], ExchangeRate[2]);

        ScenarioPostDocumentAndApplyToOtherDocumentFCYApplnRounding(
          GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Document Type"::Payment,
          Currency[1].Code, Currency[2].Code,
          LCYAmount * ExchangeRate[1], -(LCYAmount + AmountDifference) * ExchangeRate[2],
          CustLedgerEntryApplying, CustLedgerEntryApplied);

        VerifyCustomerEntriesClosed(CustLedgerEntryApplying);
        VerifyRoundingDtldEntryExists(CustLedgerEntryApplying);

        VerifyCustomerEntriesClosed(CustLedgerEntryApplied);
        VerifyRoundingDtldEntryDoesnotExist(CustLedgerEntryApplied);
    end;

    [Test]
    procedure ApplyFCYInvoiceToFCYPaymentWithoutCurrencyApplRounding()
    var
        Currency: array[2] of Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntryApplying: Record "Cust. Ledger Entry";
        CustLedgerEntryApplied: Record "Cust. Ledger Entry";
        GLApplicationRoundingPrecision: Decimal;
        FCYApplicationRoundingPrecision: array[2] of Decimal;
        ExchangeRate: array[2] of Decimal;
        LCYAmount: Decimal;
        AmountDifference: Decimal;
    begin
        // [FEATURE] [Rounding] [FCY] [Payment] [Invoice]
        // [SCENARIO 380201] System doesn't generate "Appln. Rounding" DCLE when "Appln. Rounding Precision" is not specified in Invoice's currency when Stan applies FCY[1] Invoice to FCY[2] Payment
        Initialize();

        AmountDifference := LibraryRandom.RandIntInRange(15, 20);
        ExchangeRate[1] := LibraryRandom.RandDecInRange(10, 20, 2);
        ExchangeRate[2] := LibraryRandom.RandDecInRange(10, 20, 2);
        LCYAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);

        GLApplicationRoundingPrecision := 0;

        FCYApplicationRoundingPrecision[1] := 0;
        FCYApplicationRoundingPrecision[2] := AmountDifference * 1.1 * ExchangeRate[2];

        LibraryERM.SetApplnRoundingPrecision(GLApplicationRoundingPrecision);

        CreateCurrencyWithApplicationRoundingPrecision(Currency[1], FCYApplicationRoundingPrecision[1], ExchangeRate[1]);
        CreateCurrencyWithApplicationRoundingPrecision(Currency[2], FCYApplicationRoundingPrecision[2], ExchangeRate[2]);

        ScenarioPostDocumentAndApplyToOtherDocumentFCYApplnRounding(
          GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Document Type"::Payment,
          Currency[1].Code, Currency[2].Code,
          LCYAmount * ExchangeRate[1], -(LCYAmount + AmountDifference) * ExchangeRate[2],
          CustLedgerEntryApplying, CustLedgerEntryApplied);

        VerifyCustomerEntriesClosed(CustLedgerEntryApplying);
        VerifyRoundingDtldEntryDoesnotExist(CustLedgerEntryApplying);

        VerifyCustomerEntriesOpen(CustLedgerEntryApplied);
        VerifyRoundingDtldEntryDoesnotExist(CustLedgerEntryApplied);
    end;

    [Test]
    procedure ApplyFCYInvoiceToLCYPaymentWithCurrencyApplRounding()
    var
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntryApplying: Record "Cust. Ledger Entry";
        CustLedgerEntryApplied: Record "Cust. Ledger Entry";
        GLApplicationRoundingPrecision: Decimal;
        FCYApplicationRoundingPrecision: Decimal;
        ExchangeRate: Decimal;
        LCYAmount: Decimal;
        AmountDifference: Decimal;
    begin
        // [FEATURE] [Rounding] [FCY] [Payment] [Invoice]
        // [SCENARIO 380201] System generates "Appln. Rounding" DCLE when "Appln. Rounding Precision" is specified in Invoice's currency when Stan applies FCY Invoice to LCY Payment
        Initialize();

        AmountDifference := LibraryRandom.RandIntInRange(15, 20);
        ExchangeRate := LibraryRandom.RandDecInRange(10, 20, 2);
        LCYAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);

        GLApplicationRoundingPrecision := 0;
        FCYApplicationRoundingPrecision := AmountDifference * 1.1 * ExchangeRate;

        LibraryERM.SetApplnRoundingPrecision(GLApplicationRoundingPrecision);

        CreateCurrencyWithApplicationRoundingPrecision(Currency, FCYApplicationRoundingPrecision, ExchangeRate);

        ScenarioPostDocumentAndApplyToOtherDocumentFCYApplnRounding(
          GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Document Type"::Payment,
          Currency.Code, '',
          LCYAmount * ExchangeRate, -(LCYAmount + AmountDifference),
          CustLedgerEntryApplying, CustLedgerEntryApplied);

        VerifyCustomerEntriesClosed(CustLedgerEntryApplying);
        VerifyRoundingDtldEntryExists(CustLedgerEntryApplying);

        VerifyCustomerEntriesClosed(CustLedgerEntryApplied);
        VerifyRoundingDtldEntryDoesnotExist(CustLedgerEntryApplied);
    end;

    [Test]
    procedure ApplyFCYInvoiceToLCYPaymentWithoutCurrencyApplRounding()
    var
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntryApplying: Record "Cust. Ledger Entry";
        CustLedgerEntryApplied: Record "Cust. Ledger Entry";
        GLApplicationRoundingPrecision: Decimal;
        FCYApplicationRoundingPrecision: Decimal;
        ExchangeRate: Decimal;
        LCYAmount: Decimal;
        AmountDifference: Decimal;
    begin
        // [FEATURE] [Rounding] [FCY] [Payment] [Invoice]
        // [SCENARIO 380201] System doesn't generate "Appln. Rounding" DCLE when "Appln. Rounding Precision" is not specified in Invoice's currency when Stan applies FCY Invoice to LCY Payment
        Initialize();

        AmountDifference := LibraryRandom.RandIntInRange(15, 20);
        GLApplicationRoundingPrecision := 0;

        FCYApplicationRoundingPrecision := 0;

        ExchangeRate := LibraryRandom.RandDecInRange(10, 20, 2);
        LCYAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);

        LibraryERM.SetApplnRoundingPrecision(GLApplicationRoundingPrecision);

        CreateCurrencyWithApplicationRoundingPrecision(Currency, FCYApplicationRoundingPrecision, ExchangeRate);

        ScenarioPostDocumentAndApplyToOtherDocumentFCYApplnRounding(
          GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Document Type"::Payment,
          Currency.Code, '',
          LCYAmount * ExchangeRate, -(LCYAmount + AmountDifference),
          CustLedgerEntryApplying, CustLedgerEntryApplied);

        VerifyCustomerEntriesClosed(CustLedgerEntryApplying);
        VerifyRoundingDtldEntryDoesnotExist(CustLedgerEntryApplying);

        VerifyCustomerEntriesOpen(CustLedgerEntryApplied);
        VerifyRoundingDtldEntryDoesnotExist(CustLedgerEntryApplied);
    end;

    [Test]
    procedure ApplyLCYInvoiceToFCYPaymentWithoutGLSetupApplRoundingWithCurrencyApplnRounding()
    var
        Currency: Record Currency;
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntryApplying: Record "Cust. Ledger Entry";
        CustLedgerEntryApplied: Record "Cust. Ledger Entry";
        GLApplicationRoundingPrecision: Decimal;
        FCYApplicationRoundingPrecision: Decimal;
        ExchangeRate: Decimal;
        LCYAmount: Decimal;
        AmountDifference: Decimal;
    begin
        // [FEATURE] [Rounding] [FCY] [Payment] [Invoice]
        // [SCENARIO 380201] System doesn't generate "Appln. Rounding" DCLE when "Appln. Rounding Precision" is specified in Payment's currency when Stan applies LCY Invoice to FCY Payment
        Initialize();

        AmountDifference := LibraryRandom.RandIntInRange(15, 20);
        GLApplicationRoundingPrecision := 0;

        FCYApplicationRoundingPrecision := AmountDifference * 1.1;

        ExchangeRate := LibraryRandom.RandDecInRange(10, 20, 2);
        LCYAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);

        LibraryERM.SetApplnRoundingPrecision(GLApplicationRoundingPrecision);

        CreateCurrencyWithApplicationRoundingPrecision(Currency, FCYApplicationRoundingPrecision, ExchangeRate);

        ScenarioPostDocumentAndApplyToOtherDocumentFCYApplnRounding(
          GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Document Type"::Payment,
          '', Currency.Code,
          LCYAmount, -(LCYAmount * ExchangeRate + AmountDifference),
          CustLedgerEntryApplying, CustLedgerEntryApplied);

        VerifyCustomerEntriesClosed(CustLedgerEntryApplying);
        VerifyRoundingDtldEntryDoesnotExist(CustLedgerEntryApplying);

        VerifyCustomerEntriesOpen(CustLedgerEntryApplied);
        VerifyRoundingDtldEntryDoesnotExist(CustLedgerEntryApplied);
    end;

    [Test]
    procedure ApplyLCYInvoiceToLCYPaymentWithGLSetup()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntryApplying: Record "Cust. Ledger Entry";
        CustLedgerEntryApplied: Record "Cust. Ledger Entry";
        GLApplicationRoundingPrecision: Decimal;
        LCYAmount: Decimal;
        AmountDifference: Decimal;
    begin
        // [FEATURE] [Rounding] [FCY] [Payment] [Invoice]
        // [SCENARIO 380201] System doesn't generate "Appln. Rounding" DCLE when "Appln. Rounding Precision" is specified in Payment's currency when Stan applies LCY Invoice to LCY Payment
        Initialize();

        AmountDifference := LibraryRandom.RandIntInRange(15, 20);
        GLApplicationRoundingPrecision := AmountDifference * 1.1;

        LCYAmount := LibraryRandom.RandDecInRange(1000, 2000, 2);

        LibraryERM.SetApplnRoundingPrecision(GLApplicationRoundingPrecision);

        ScenarioPostDocumentAndApplyToOtherDocumentFCYApplnRounding(
          GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Document Type"::Payment,
          '', '',
          LCYAmount, -(LCYAmount + AmountDifference),
          CustLedgerEntryApplying, CustLedgerEntryApplied);

        VerifyCustomerEntriesClosed(CustLedgerEntryApplying);
        VerifyRoundingDtldEntryDoesnotExist(CustLedgerEntryApplying);

        VerifyCustomerEntriesOpen(CustLedgerEntryApplied);
        VerifyRoundingDtldEntryDoesnotExist(CustLedgerEntryApplied);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ApplyCustomerEntriesModalPageHandler,PostApplicationModalPageHandler,SimpleMessageHandler')]
    procedure TwoPaymentTwoInvoiceSetAppliesToIdFromGeneralJournal()
    var
        Customer: Record Customer;
        GenJournalLineInvoice: array[2] of Record "Gen. Journal Line";
        GenJournalLinePayment: array[2] of Record "Gen. Journal Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
        InvoiceAmount: array[2] of Decimal;
        PaymentAmount: array[2] of Decimal;
        AppliesToId: Code[20];
    begin
        // [FEATURE] [General Journal]
        // [SCENARIO 342909] System clean "Applies-to ID" field in customer ledger entry when it is generated from general journal line applied to customer ledger entry
        Initialize();

        LibrarySales.CreateCustomer(Customer);

        InvoiceAmount[1] := LibraryRandom.RandIntInRange(10, 20);
        InvoiceAmount[2] := LibraryRandom.RandIntInRange(10, 20);
        PaymentAmount[1] := -(InvoiceAmount[1] + InvoiceAmount[2]) * 3;
        PaymentAmount[2] := -InvoiceAmount[2];

        // [GIVEN] Posted Invoice "B"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLineInvoice[2], GenJournalLineInvoice[2]."Document Type"::Invoice, GenJournalLineInvoice[2]."Account Type"::Customer, Customer."No.", InvoiceAmount[2]);
        GenJournalLineInvoice[2].Validate("Posting Date", WorkDate() + 1);
        GenJournalLineInvoice[2].Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLineInvoice[2]);

        // [GIVEN] Posted Payment "A"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLinePayment[1], GenJournalLinePayment[1]."Document Type"::Payment, GenJournalLinePayment[1]."Account Type"::Customer, Customer."No.", PaymentAmount[1]);
        GenJournalLinePayment[1].Validate("Posting Date", WorkDate() - 1);
        GenJournalLinePayment[1].Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLinePayment[1]);

        // [GIVEN] Posted Payment "A" applied to Invoice "B" with "Applies-to ID", but not posted
        LibraryVariableStorage.Enqueue(GenJournalLineInvoice[2]."Document No.");
        LibraryVariableStorage.Enqueue(false);

        CustomerLedgerEntries.OpenEdit();
        CustomerLedgerEntries.Filter.SetFilter("Customer No.", Customer."No.");
        CustomerLedgerEntries.Filter.SetFilter("Document No.", GenJournalLinePayment[1]."Document No.");
        CustomerLedgerEntries."Apply Entries".Invoke();
        CustomerLedgerEntries.Close();

        AppliesToId := LibraryUtility.GenerateGUID();
        Clear(CustLedgerEntry);
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        CustLedgerEntry.SetRange("Applies-to ID", UserId());
        CustLedgerEntry.ModifyAll("Applies-to ID", AppliesToId);

        // [GIVEN] Payment "B" applied to Invoice "B" with "Applies-to Doc. No." and posted
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLinePayment[2], GenJournalLinePayment[2]."Document Type"::Payment, GenJournalLinePayment[2]."Account Type"::Customer, Customer."No.", PaymentAmount[2]);
        GenJournalLinePayment[2].Validate("Posting Date", WorkDate() + 1);
        GenJournalLinePayment[2].Validate("Applies-to Doc. Type", GenJournalLinePayment[2]."Applies-to Doc. Type"::Invoice);
        GenJournalLinePayment[2].Validate("Applies-to Doc. No.", GenJournalLineInvoice[2]."Document No.");
        GenJournalLinePayment[2].Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLinePayment[2]);

        // [GIVEN] Posting engine cleared "Applies-to ID" and "Applies-to Doc. No." on applied customer ledger entry of Invoice "B"
        VerifyBlankAppliestoID(Customer."No.", GenJournalLineInvoice[2]."Document No.", CustLedgerEntry."Document Type"::Invoice);

        // [GIVEN] Posted Invoice "A"
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLineInvoice[1], GenJournalLineInvoice[1]."Document Type"::Invoice, GenJournalLineInvoice[1]."Account Type"::Customer, Customer."No.", InvoiceAmount[1]);
        GenJournalLineInvoice[1].Validate("Posting Date", WorkDate() - 1);
        GenJournalLineInvoice[1].Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLineInvoice[1]);

        // [GIVEN] Posted Payment "A" applied to Posted Invoice "A" with "Applies-to ID."
        AppliesToId := LibraryUtility.GenerateGUID();
        Clear(CustLedgerEntry);
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        CustLedgerEntry.SetRange("Applies-to ID", AppliesToId);
        CustLedgerEntry.ModifyAll("Applies-to ID", UserId());

        LibraryVariableStorage.Enqueue(GenJournalLineInvoice[1]."Document No.");
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(WorkDate() - 1);

        CustomerLedgerEntries.OpenEdit();
        CustomerLedgerEntries.Filter.SetFilter("Customer No.", Customer."No.");
        CustomerLedgerEntries.Filter.SetFilter("Document No.", GenJournalLinePayment[1]."Document No.");

        // [WHEN] Stan posts 
        CustomerLedgerEntries."Apply Entries".Invoke();

        // [GIVEN] Applied documents posted and posting engine cleared "Applies-to ID" and "Applies-to Doc. No." on applied customer ledger entry of Invoice "A"
        VerifyBlankAppliestoID(Customer."No.", GenJournalLineInvoice[1]."Document No.", CustLedgerEntry."Document Type"::Invoice);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ApplyCustomerEntriesTwiceModalPageHandler')]
    procedure ThreeInvoicesAndApplyEntries()
    var
        Customer: Record Customer;
        GenJournalLine: Record "Gen. Journal Line";
        CustLedgerEntry: array[3] of Record "Cust. Ledger Entry";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
        Index: Integer;
    begin
        // [FEATURE] [General Journal]
        // [SCENARIO 411946] "Applies-to ID" must be cleared on applying entry when the mark is removed from applied entries.
        Initialize();

        LibrarySales.CreateCustomer(Customer);

        for Index := 1 to ArrayLen(CustLedgerEntry) do begin
            Clear(GenJournalLine);
            LibraryJournals.CreateGenJournalLineWithBatch(
                GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.", LibraryRandom.RandIntInRange(100, 200));
            GenJournalLine.Validate("Posting Date", WorkDate() + 1);
            GenJournalLine.Modify(true);
            LibraryERM.PostGeneralJnlLine(GenJournalLine);
            CustLedgerEntry[Index].SetRange("Customer No.", Customer."No.");
            LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry[Index], CustLedgerEntry[Index]."Document Type"::Invoice, GenJournalLine."Document No.");
        end;

        LibraryVariableStorage.Enqueue(CustLedgerEntry[2]."Document No.");

        CustomerLedgerEntries.OpenEdit();
        CustomerLedgerEntries.Filter.SetFilter("Customer No.", Customer."No.");
        CustomerLedgerEntries.Filter.SetFilter("Document No.", CustLedgerEntry[1]."Document No.");
        CustomerLedgerEntries."Apply Entries".Invoke(); // set and remove Applies-to ID mark on 2nd invoice (on page handler)
        CustomerLedgerEntries.Close();

        CustLedgerEntry[1].Find();
        CustLedgerEntry[1].TestField("Applies-to ID", '');

        CustLedgerEntry[2].Find();
        CustLedgerEntry[2].TestField("Applies-to ID", '');

        CustLedgerEntry[3].Find();
        CustLedgerEntry[3].TestField("Applies-to ID", '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ApplyCustomerEntriesPageHandler')]
    procedure AppliedAmtInApplyCLEIsEqualToAmtToApplyOfSelectedCLEWhenManuallyEnterAppliesToID()
    var
        Customer: Record Customer;
        CustLedgerEntry: array[3] of Record "Cust. Ledger Entry";
        CustomerLedgerEntries: TestPage "Customer Ledger Entries";
    begin
        // [SCENARIO 566073] Applied Amount in Apply Customer Entries page is equal to the sum of 
        // "Amount to Apply" of Cust. Ledger Entries when Stan sets "Applies-to ID" manually in them.
        Initialize();

        // [GIVEN] Create a Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create Gen. Journal Lines and Post them.
        CreateAndPostGenJnlLines(CustLedgerEntry, Customer);

        // [WHEN] Open Customer Ledger Entries page and run Apply Entries action.
        CustomerLedgerEntries.OpenEdit();
        CustomerLedgerEntries.Filter.SetFilter("Customer No.", Customer."No.");
        CustomerLedgerEntries.Filter.SetFilter("Document No.", CustLedgerEntry[1]."Document No.");
        CustomerLedgerEntries."Apply Entries".Invoke();
        CustomerLedgerEntries.Close();

        // [THEN] AppliedAmount in Apply Customer Entries page is equal to the sum of "Amount to Apply" 
        // of Cust. Ledger Entries When "Applies-to ID" is set, in ApplyCustomerEntriesPageHandler.
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibrarySetupStorage.Restore();
        // Lazy Setup.
        if isInitialized then
            exit;

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateAccountInCustomerPostingGroup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateJournalTemplMandatory(false);

        isInitialized := true;
        Commit();
        LibrarySetupStorage.SaveGeneralLedgerSetup();
    end;

    local procedure ApplyAndPostGenJournalLine(var GenJournalLineApplying: Record "Gen. Journal Line"; var GenJournalLineApplied: Record "Gen. Journal Line")
    begin
        GenJournalLineApplying.Validate("Applies-to Doc. Type", GenJournalLineApplied."Document Type");
        GenJournalLineApplying.Validate("Applies-to Doc. No.", GenJournalLineApplied."Document No.");
        GenJournalLineApplying.Modify(true);

        LibraryERM.PostGeneralJnlLine(GenJournalLineApplying);
    end;

    local procedure CustomerRealizedAdjust(PmtType: Enum "Gen. Journal Document Type"; InvType: Enum "Gen. Journal Document Type"; Amount: Decimal; Stepwise: Boolean; CurrencyAdjustFactor: Decimal; DtldLedgerType: Enum "Detailed CV Ledger Entry Type")
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        Desc: Text[30];
        InvAmount: Decimal;
        PmtAmount: Decimal;
    begin
        // Test without payment discount
        GetGLBalancedBatch(GenJournalTemplate, GenJournalBatch, GenJournalTemplate.Type::General);
        CreateCustomerWithPaymentTerms(Customer, GetPaymentTerms('0'));

        // Find currency code with realized gaisn/losses account
        Currency.Get(LibraryERM.CreateCurrencyWithGLAccountSetup());

        // Create new exchange rate
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        CurrencyExchangeRate.SetRange("Currency Code", Currency.Code);
        CurrencyExchangeRate.FindFirst();

        // Watch for Realized gain/loss dtld. ledger entries
        LibraryERMCustomerWatch.Init();
        LibraryERMCustomerWatch.DtldEntriesEqual(Customer."No.", DtldLedgerType, 0);

        // Generate a document that triggers application dtld. ledger entries.
        InvAmount := Amount;
        PmtAmount := LibraryERM.ConvertCurrency(InvAmount, Currency.Code, '', WorkDate()) * CurrencyAdjustFactor;

        Desc := GenerateDocument(GenJournalBatch, Customer, PmtType, InvType, PmtAmount, InvAmount, '<0D>', '', Currency.Code);

        // Adjust the currency exchange rate of the document currency to trigger realized gain/loss
        CurrencyExchangeRate."Relational Exch. Rate Amount" *= CurrencyAdjustFactor;
        CurrencyExchangeRate."Relational Adjmt Exch Rate Amt" *= CurrencyAdjustFactor;
        CurrencyExchangeRate.Modify(true);

        CustomerApplyUnapply(Desc, Stepwise);

        LibraryERMCustomerWatch.AssertCustomer();
    end;

    local procedure CustomerUnrealizedAdjust(PmtType: Enum "Gen. Journal Document Type"; InvType: Enum "Gen. Journal Document Type"; Amount: Decimal; Stepwise: Boolean; CurrencyAdjustFactor: Decimal; DtldLedgerType: Enum "Detailed CV Ledger Entry Type")
    var
        Currency: Record Currency;
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        Desc: Text[30];
        InvAmount: Decimal;
        PmtAmount: Decimal;
    begin
        // Test without payment discount
        GetGLBalancedBatch(GenJournalTemplate, GenJournalBatch, GenJournalTemplate.Type::General);
        CreateCustomerWithPaymentTerms(Customer, GetPaymentTerms('0'));

        Currency.Get(SetExchRateForCurrency(CurrencyAdjustFactor));

        // Watch for Realized gain/loss dtld. ledger entries
        LibraryERMCustomerWatch.Init();
        LibraryERMCustomerWatch.DtldEntriesEqual(Customer."No.", DtldLedgerType, 0);

        // Generate a document that triggers application dtld. ledger entries.
        InvAmount := Amount;
        PmtAmount := LibraryERM.ConvertCurrency(InvAmount, Currency.Code, '', WorkDate()) * CurrencyAdjustFactor;

        Desc := GenerateDocument(GenJournalBatch, Customer, PmtType, InvType, PmtAmount, InvAmount, '<1D>', '', Currency.Code);

        // Run the Adjust Exchange Rates Batch job.
        LibraryERM.RunExchRateAdjustmentSimple(
          Currency.Code, CalcDate('<1D>', WorkDate()), CalcDate('<1D>', WorkDate()));

        CustomerApplyUnapply(Desc, Stepwise);

        LibraryERMCustomerWatch.AssertCustomer();
    end;

    local procedure CustomerPmtDiscVATAdjust(PmtType: Enum "Gen. Journal Document Type"; InvType: Enum "Gen. Journal Document Type"; Amount: Decimal; Stepwise: Boolean)
    var
        Customer: Record Customer;
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // Tests the VAT adjustment detailed ledger entries created
        // when posting an application where the payment is overdue
        // but within the grace period of payment tolerance.

        // Find discounted payment terms
        CreateCustomerWithPaymentTerms(Customer, GetPaymentTerms('>0'));

        // Watch for detailed ledger entry type "Payment Discount Tolerance (VAT Adjustment)" and "Payment Discount Tolerance (VAT Excl.)"
        LibraryERMCustomerWatch.Init();
        LibraryERMCustomerWatch.DtldEntriesSigned(
          Amount, Customer."No.", DtldCustLedgEntry."Entry Type"::"Payment Discount (VAT Adjustment)", 0);
        LibraryERMCustomerWatch.DtldEntriesSigned(
          Amount, Customer."No.", DtldCustLedgEntry."Entry Type"::"Payment Discount (VAT Excl.)", 0);
        LibraryERMCustomerWatch.DtldEntriesSigned(
          Amount, Customer."No.", DtldCustLedgEntry."Entry Type"::"Payment Discount", 0);

        // Apply / Unapply with VAT posting setup
        CustomerApplyUnapplyVAT(
          Customer, PmtType, InvType, Amount - GetDiscount(Customer."Payment Terms Code", Amount), Amount, '<0D>', Stepwise);

        LibraryERMCustomerWatch.AssertCustomer();
    end;

    local procedure CustomerPmtTolVATAdjust(PmtType: Enum "Gen. Journal Document Type"; InvType: Enum "Gen. Journal Document Type"; Amount: Decimal; Stepwise: Boolean)
    var
        Customer: Record Customer;
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        // Tests the VAT adjustment detailed ledger entries created
        // when posting an application that triggers payment tolerance

        // Find none discounted payment terms
        CreateCustomerWithPaymentTerms(Customer, GetPaymentTerms('0'));

        // Watch for detailed ledger entry type "Payment Tolerance (VAT Adjustment)" and "Payment Tolerance (VAT Excl.)"
        LibraryERMCustomerWatch.Init();
        LibraryERMCustomerWatch.DtldEntriesGreaterThan(
          Customer."No.", DtldCustLedgEntry."Entry Type"::"Payment Tolerance (VAT Adjustment)", 0);
        LibraryERMCustomerWatch.DtldEntriesGreaterThan(
          Customer."No.", DtldCustLedgEntry."Entry Type"::"Payment Tolerance (VAT Excl.)", 0);
        LibraryERMCustomerWatch.DtldEntriesGreaterThan(
          Customer."No.", DtldCustLedgEntry."Entry Type"::"Payment Tolerance", 0);

        // Apply / Unapply with VAT posting setup
        CustomerApplyUnapplyVAT(Customer, PmtType, InvType, Amount - GetPaymentTolerance(), Amount, '<0D>', Stepwise);

        LibraryERMCustomerWatch.AssertCustomer();
    end;

    local procedure CustomerPmtDiscTolVATAdjust(PmtType: Enum "Gen. Journal Document Type"; InvType: Enum "Gen. Journal Document Type"; Amount: Decimal; Stepwise: Boolean)
    var
        Customer: Record Customer;
        PaymentTerms: Record "Payment Terms";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Offset: Text[30];
    begin
        // Tests the VAT adjustment detailed ledger entries created
        // when posting an application where the payment is overdue
        // but within the grace period of payment tolerance.

        // Find discounted payment terms
        PaymentTerms.Get(GetPaymentTerms('>0'));
        CreateCustomerWithPaymentTerms(Customer, PaymentTerms.Code);

        // Watch for detailed ledger entry type "Payment Discount Tolerance (VAT Adjustment)" and "Payment Discount Tolerance (VAT Excl.)"
        LibraryERMCustomerWatch.Init();
        LibraryERMCustomerWatch.DtldEntriesSigned(
          Amount, Customer."No.", DtldCustLedgEntry."Entry Type"::"Payment Discount Tolerance (VAT Adjustment)", 0);
        LibraryERMCustomerWatch.DtldEntriesSigned(
          Amount, Customer."No.", DtldCustLedgEntry."Entry Type"::"Payment Discount Tolerance (VAT Excl.)", 0);
        LibraryERMCustomerWatch.DtldEntriesSigned(
          Amount, Customer."No.", DtldCustLedgEntry."Entry Type"::"Payment Discount Tolerance", 0);

        // Trigger payment discount tolerance by exceeding discount due date by 1 day
        Offset := Format(PaymentTerms."Discount Date Calculation") + '+<1D>';

        // Apply / Unapply with VAT posting setup
        CustomerApplyUnapplyVAT(Customer, PmtType, InvType, Amount - GetDiscount(PaymentTerms.Code, Amount), Amount, Offset, Stepwise);

        LibraryERMCustomerWatch.AssertCustomer();
    end;

    local procedure CustomerInvPmt(PmtType: Enum "Gen. Journal Document Type"; InvType: Enum "Gen. Journal Document Type"; Amount: Decimal; Stepwise: Boolean)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Desc: Text[30];
    begin
        // Test without payment discount
        GetGLBalancedBatch(GenJournalTemplate, GenJournalBatch, GenJournalTemplate.Type::General);
        CreateCustomerWithPaymentTerms(Customer, GetPaymentTerms('0'));

        // Setup basic application watches
        LibraryERMCustomerWatch.Init();
        LibraryERMCustomerWatch.EntriesEqual(Customer."No.", InvType.AsInteger(), -Amount);
        LibraryERMCustomerWatch.EntriesEqual(Customer."No.", PmtType.AsInteger(), Amount);
        LibraryERMCustomerWatch.DtldEntriesEqual(Customer."No.", DtldCustLedgEntry."Entry Type"::"Initial Entry", 0);
        LibraryERMCustomerWatch.DtldEntriesGreaterThan(Customer."No.", DtldCustLedgEntry."Entry Type"::Application, 0);

        // Generate a document that triggers application dtld. ledger entries.
        Desc := GenerateDocument(GenJournalBatch, Customer, PmtType, InvType, Amount, Amount, '<0D>', '', '');
        CustomerApplyUnapply(Desc, Stepwise);

        LibraryERMCustomerWatch.AssertCustomer();
    end;

    local procedure CustomerInvPmtDisc(PmtType: Enum "Gen. Journal Document Type"; InvType: Enum "Gen. Journal Document Type"; Amount: Decimal; Stepwise: Boolean)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DiscountAmount: Decimal;
        Desc: Text[30];
    begin
        // Test with payment discount
        GetGLBalancedBatch(GenJournalTemplate, GenJournalBatch, GenJournalTemplate.Type::General);
        CreateCustomerWithPaymentTerms(Customer, GetPaymentTerms('>0'));
        DiscountAmount := GetDiscount(Customer."Payment Terms Code", Amount);

        // Watch for "Payment Discount" detailed ledger entries.
        LibraryERMCustomerWatch.Init();
        LibraryERMCustomerWatch.DtldEntriesEqual(Customer."No.", DtldCustLedgEntry."Entry Type"::"Payment Discount", DiscountAmount);

        // Generate a document that triggers payment discount dtld. ledger entries.
        Desc := GenerateDocument(GenJournalBatch, Customer, PmtType, InvType, Amount - DiscountAmount, Amount, '<0D>', '', '');
        CustomerApplyUnapply(Desc, Stepwise);

        LibraryERMCustomerWatch.AssertCustomer();
    end;

    local procedure CustomerInvPmtVAT(PmtType: Enum "Gen. Journal Document Type"; InvType: Enum "Gen. Journal Document Type"; Amount: Decimal; Stepwise: Boolean)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Desc: Text[30];
    begin
        // Test with VAT

        // Find a VAT setup that has a balancing account with direct posting
        GetDirectVATPostingSetup(VATPostingSetup, GLAccount, '>0');
        GetVATBalancedBatch(GenJournalTemplate, GenJournalBatch, GLAccount);

        // Find payment terms with no discount
        CreateCustomerWithPaymentTerms(Customer, GetPaymentTerms('0'));
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Modify(true);

        // Try out Customer watch
        LibraryERMCustomerWatch.Init();
        LibraryERMCustomerWatch.EntriesEqual(Customer."No.", InvType.AsInteger(), -Amount);
        LibraryERMCustomerWatch.EntriesEqual(Customer."No.", PmtType.AsInteger(), Amount);
        LibraryERMCustomerWatch.DtldEntriesEqual(Customer."No.", DtldCustLedgEntry."Entry Type"::"Initial Entry", 0);
        LibraryERMCustomerWatch.DtldEntriesGreaterThan(Customer."No.", DtldCustLedgEntry."Entry Type"::Application, 0);

        // Generate a document that triggers payment discount dtld. ledger entries.
        Desc := GenerateDocument(GenJournalBatch, Customer, PmtType, InvType, Amount, Amount, '<0D>', '', '');
        CustomerApplyUnapply(Desc, Stepwise);

        LibraryERMCustomerWatch.AssertCustomer();
    end;

    local procedure CustomerInvPmtCorrection(PmtType: Enum "Gen. Journal Document Type"; InvType: Enum "Gen. Journal Document Type"; Amount: Decimal; Stepwise: Boolean)
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        Customer: Record Customer;
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        Desc: Text[30];
    begin
        // Test with payment discount
        GetGLBalancedBatch(GenJournalTemplate, GenJournalBatch, GenJournalTemplate.Type::General);
        CreateCustomerWithPaymentTerms(Customer, GetPaymentTerms('0'));

        // Create a currency code with magic exchange rate valid for Amount = 1000
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, WorkDate());
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 64.580459);  // Magic exchange rate
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", 100);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", CurrencyExchangeRate."Exchange Rate Amount");
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", CurrencyExchangeRate."Relational Exch. Rate Amount");
        CurrencyExchangeRate.Modify(true);

        // Watch for "Correction of Remaining Amount" detailed ledger entries.
        LibraryERMCustomerWatch.Init();
        LibraryERMCustomerWatch.DtldEntriesGreaterThan(
          Customer."No.", DtldCustLedgEntry."Entry Type"::"Correction of Remaining Amount", 0);

        // Generate a document that triggers "Correction of Remaining Amount" dtld. ledger entries.
        Desc := GenerateDocument(GenJournalBatch, Customer, PmtType, InvType, Amount, Amount, '<0D>', Currency.Code, Currency.Code);
        CustomerApplyUnapply(Desc, Stepwise);

        LibraryERMCustomerWatch.AssertCustomer();
    end;

    local procedure CustomerApplyUnapplyVAT(Customer: Record Customer; PmtType: Enum "Gen. Journal Document Type"; InvType: Enum "Gen. Journal Document Type"; PmtAmount: Decimal; InvAmount: Decimal; PmtOffset: Text[30]; Stepwise: Boolean)
    var
        GeneralPostingSetup: Record "General Posting Setup";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        Desc: Text[30];
    begin
        // Setup payment tolerance on payment discount
        LibraryPmtDiscSetup.SetAdjustForPaymentDisc(true);

        // Find a VAT setup that has a balancing account with direct posting and update it
        GetDirectVATPostingSetup(VATPostingSetup, GLAccount, '>0');
        GetVATBalancedBatch(GenJournalTemplate, GenJournalBatch, GLAccount);
        VATPostingSetup.Validate("Adjust for Payment Discount", true);
        VATPostingSetup.Modify(true);

        // Update General Posting Setup
        GeneralPostingSetup.Get(GLAccount."Gen. Bus. Posting Group", GLAccount."Gen. Prod. Posting Group");
        GeneralPostingSetup.Validate("Sales Pmt. Disc. Credit Acc.", GLAccount."No.");
        GeneralPostingSetup.Validate("Sales Pmt. Disc. Debit Acc.", GLAccount."No.");
        GeneralPostingSetup.Validate("Sales Pmt. Tol. Credit Acc.", GLAccount."No.");
        GeneralPostingSetup.Validate("Sales Pmt. Tol. Debit Acc.", GLAccount."No.");
        GeneralPostingSetup.Modify(true);

        // Update Customer to our needs
        Customer.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Customer.Validate("Application Method", Customer."Application Method"::Manual);
        Customer.Modify(true);

        // Generate a document that triggers "Payment Tolerance (VAT Adjustment)" dtld. ledger entries.
        Desc := GenerateDocument(GenJournalBatch, Customer, PmtType, InvType, PmtAmount, InvAmount, PmtOffset, '', '');
        CustomerApplyUnapply(Desc, Stepwise);
    end;

    local procedure CustomerApplyUnapply(Desc: Text[30]; Stepwise: Boolean)
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange(Description, Desc);
        Assert.AreEqual(CustLedgerEntry.Count, 4, 'Expected to find exactly 4 Customer ledger entries!');

        // Exercise #1. Apply entries.
        PostCustomerApplication(CustLedgerEntry, Stepwise);

        // Verify #1.
        VerifyCustomerEntriesClosed(CustLedgerEntry);

        // Exercise #2. Unapply entries.
        PostCustomerUnapply(CustLedgerEntry, Stepwise);

        // Verify #2.
        VerifyCustomerEntriesOpen(CustLedgerEntry);

        // Exercise #3. Apply entries.
        PostCustomerApplication(CustLedgerEntry, Stepwise);

        // Verify #3.
        VerifyCustomerEntriesClosed(CustLedgerEntry);
    end;

    local procedure CreateCurrencyWithApplicationRoundingPrecision(var Currency: Record Currency; ApplicationRoundingPrecision: Decimal; ExchangeRate: Decimal)
    begin
        Clear(Currency);
        Currency.Get(LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchangeRate, ExchangeRate));
        Currency.Validate("Appln. Rounding Precision", ApplicationRoundingPrecision);
        Currency.Modify(true);
    end;

    local procedure ScenarioPostDocumentAndApplyToOtherDocumentFCYApplnRounding(DocumentTypeApplying: Enum "Gen. Journal Account Type"; DocumentTypeApplied: Enum "Gen. Journal Account Type"; CurrencyCodeApplying: Code[10]; CurrencyCodeApplied: Code[10]; AmountApplying: Decimal; AmountApplied: Decimal; var CustLedgerEntryApplying: Record "Cust. Ledger Entry"; var CustLedgerEntryApplied: Record "Cust. Ledger Entry")
    var
        Customer: Record Customer;
        GenJournalLine: array[2] of Record "Gen. Journal Line";
    begin
        LibrarySales.CreateCustomer(Customer);

        CreateGenJournalLineFCY(GenJournalLine[2], DocumentTypeApplied, Customer."No.", CurrencyCodeApplied, AmountApplied);
        LibraryERM.PostGeneralJnlLine(GenJournalLine[2]);

        CreateGenJournalLineFCY(GenJournalLine[1], DocumentTypeApplying, Customer."No.", CurrencyCodeApplying, AmountApplying);
        ApplyAndPostGenJournalLine(GenJournalLine[1], GenJournalLine[2]);

        FindCustLedgerEntry(
          CustLedgerEntryApplying, Customer,
          DocumentTypeApplying, GenJournalLine[1]."Document No.");

        FindCustLedgerEntry(
          CustLedgerEntryApplied, Customer,
          DocumentTypeApplied, GenJournalLine[2]."Document No.");
    end;

    local procedure SetupPaymentTolerance()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Payment Tolerance %", 1.0);
        GeneralLedgerSetup.Validate("Max. Payment Tolerance Amount", 5.0);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure GetCustomerAmount(): Decimal
    begin
        exit(-1000);
    end;

    local procedure GenerateDocument(GenJournalBatch: Record "Gen. Journal Batch"; Customer: Record Customer; PmtType: Enum "Gen. Journal Document Type"; InvType: Enum "Gen. Journal Document Type"; PmtAmount: Decimal; InvAmount: Decimal; PmtOffset: Text[30]; PmtCurrencyCode: Code[10]; InvCurrencyCode: Code[10]): Text[30]
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
        Desc: Text[30];
    begin
        ClearJournalBatch(GenJournalBatch);
        // Create four documents with seperate document no. and external document no. but with unique description.
        DocumentNo := CreateJournalLine(
            GenJournalLine, GenJournalBatch, PmtType, GenJournalLine."Account Type"::Customer,
            Customer."No.", PmtAmount / 4, PmtOffset, PmtCurrencyCode, DocumentNo, '');
        Desc := DocumentNo;
        DocumentNo := CreateJournalLine(
            GenJournalLine, GenJournalBatch, PmtType, GenJournalLine."Account Type"::Customer,
            Customer."No.", PmtAmount / 4, PmtOffset, PmtCurrencyCode, IncStr(DocumentNo), Desc);
        DocumentNo := CreateJournalLine(
            GenJournalLine, GenJournalBatch, PmtType, GenJournalLine."Account Type"::Customer,
            Customer."No.", PmtAmount / 2, PmtOffset, PmtCurrencyCode, IncStr(DocumentNo), Desc);
        DocumentNo := CreateJournalLine(
            GenJournalLine, GenJournalBatch, InvType, GenJournalLine."Account Type"::Customer,
            Customer."No.", -InvAmount, '<0D>', InvCurrencyCode, IncStr(DocumentNo), Desc);

        PostJournalBatch(GenJournalBatch);
        exit(Desc);
    end;

    local procedure CreateCustomerWithPaymentTerms(var Customer: Record Customer; PaymentTermsCode: Code[10])
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Payment Terms Code", PaymentTermsCode);
        Customer.Modify(true);
    end;

    local procedure CreateJournalLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Amount: Decimal; PmtOffset: Text[30]; CurrencyCode: Code[10]; DocNo: Code[20]; Description: Text[30]): Code[20]
    var
        DateOffset: DateFormula;
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine,
          GenJournalBatch."Journal Template Name",
          GenJournalBatch.Name,
          DocumentType,
          AccountType,
          AccountNo,
          Amount);

        Evaluate(DateOffset, PmtOffset);

        // Update journal line currency
        GenJournalLine.Validate("Posting Date", CalcDate(DateOffset, WorkDate()));
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate(Description, GenJournalLine."Document No.");

        // Update document number and description if specified
        if DocNo <> '' then
            GenJournalLine."Document No." := DocNo;
        if Description <> '' then
            GenJournalLine.Description := Description;

        GenJournalLine.Validate("External Document No.", GenJournalLine."Document No.");
        GenJournalLine.Modify(true);

        exit(GenJournalLine."Document No.");
    end;

    local procedure CreateGenJournalLineFCY(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Account Type"; CustomerNo: Code[20]; CurrencyCode: Code[10]; DocumentAmount: Decimal)
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, DocumentType,
          GenJournalLine."Account Type"::Customer, CustomerNo, 0);

        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate(Amount, DocumentAmount);
        GenJournalLine.Modify(true);
    end;

    local procedure ClearJournalBatch(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetFilter("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.DeleteAll();
    end;

    local procedure FindCustLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; Customer: Record Customer; DocumentType: Enum "Gen. Journal Account Type"; DocumentNo: Code[20])
    begin
        Clear(CustLedgerEntry);
        CustLedgerEntry.Reset();
        CustLedgerEntry.SetRange("Customer No.", Customer."No.");
        CustLedgerEntry.SetAutoCalcFields("Remaining Amount", "Remaining Amt. (LCY)", Amount, "Amount (LCY)");
        LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry, DocumentType, DocumentNo);
    end;

    local procedure MockCustLedgEntry(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry.Open := true;
        CustLedgerEntry.Insert();
        MockDtldLedgEntry(CustLedgerEntry."Entry No.");
    end;

    local procedure MockDtldLedgEntry(CustLedgEntryNo: Integer)
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.Init();
        DetailedCustLedgEntry."Entry No." :=
          LibraryUtility.GetNewRecNo(DetailedCustLedgEntry, DetailedCustLedgEntry.FieldNo("Entry No."));
        DetailedCustLedgEntry."Cust. Ledger Entry No." := CustLedgEntryNo;
        DetailedCustLedgEntry."Entry Type" := DetailedCustLedgEntry."Entry Type"::"Initial Entry";
        DetailedCustLedgEntry.Amount := LibraryRandom.RandDec(100, 2);
        DetailedCustLedgEntry.Insert();
    end;

    local procedure MockAppliedCustLedgEntry(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        MockCustLedgEntry(CustLedgerEntry);
        CustLedgerEntry."Amount to Apply" := LibraryRandom.RandDec(100, 2);
        CustLedgerEntry."Applies-to ID" := LibraryUtility.GenerateGUID();
        CustLedgerEntry."Accepted Pmt. Disc. Tolerance" := true;
        CustLedgerEntry."Accepted Payment Tolerance" := LibraryRandom.RandDec(100, 2);
        CustLedgerEntry.Modify();
    end;

    local procedure PostJournalBatch(GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        GenJournalLine.SetFilter("Journal Batch Name", GenJournalBatch.Name);
        GenJournalLine.FindFirst();

        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure PostCustomerApplication(var CustLedgerEntry: Record "Cust. Ledger Entry"; Stepwise: Boolean)
    begin
        if Stepwise then
            PostCustomerApplicationStepwis(CustLedgerEntry)
        else
            PostCustomerApplicationOneGo(CustLedgerEntry);
    end;

    local procedure PostCustomerApplicationOneGo(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        // The first entry is the applying entry.
        CustLedgerEntry.FindFirst();
        CustLedgerEntry.CalcFields(Amount);
        LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, CustLedgerEntry.Amount);

        // Apply to all other entries.
        LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry);

        // Call Apply codeunit.
        CustLedgerEntry.FindFirst();
        LibraryERM.PostCustLedgerApplication(CustLedgerEntry);
    end;

    local procedure PostCustomerApplicationStepwis(var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        CustLedgerEntry2: Record "Cust. Ledger Entry";
        i: Integer;
    begin
        // The first entry is the applying entry.
        CustLedgerEntry.FindLast();
        CustLedgerEntry2.SetRange("Entry No.", CustLedgerEntry."Entry No.");
        CustLedgerEntry2.FindFirst();

        CustLedgerEntry.FindFirst();
        for i := 1 to CustLedgerEntry.Count - 1 do begin
            CustLedgerEntry.CalcFields(Amount);
            LibraryERM.SetApplyCustomerEntry(CustLedgerEntry, CustLedgerEntry.Amount);

            // Apply to last entry.
            LibraryERM.SetAppliestoIdCustomer(CustLedgerEntry2);

            // Post application.
            LibraryERM.PostCustLedgerApplication(CustLedgerEntry);

            CustLedgerEntry.Next();
        end;
    end;

    local procedure PostCustomerUnapply(var CustLedgerEntry: Record "Cust. Ledger Entry"; Stepwise: Boolean)
    begin
        if Stepwise then
            PostCustomerUnapplyStepwise(CustLedgerEntry)
        else
            PostCustomerUnapplyOneGo(CustLedgerEntry);
    end;

    local procedure PostCustomerUnapplyOneGo(var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        ApplyUnapplyParameters: Record "Apply Unapply Parameters";
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        DtldCustLedgEntry2: Record "Detailed Cust. Ledg. Entry";
        CustEntryApplyPostedEntries: Codeunit "CustEntry-Apply Posted Entries";
    begin
        DtldCustLedgEntry.Get(FindLastApplEntry(CustLedgerEntry."Entry No."));

        DtldCustLedgEntry2.SetRange("Transaction No.", DtldCustLedgEntry."Transaction No.");
        DtldCustLedgEntry2.SetRange("Customer No.", DtldCustLedgEntry."Customer No.");
        DtldCustLedgEntry2.FindFirst();

        ApplyUnapplyParameters."Document No." := CustLedgerEntry."Document No.";
        ApplyUnapplyParameters."Posting Date" := DtldCustLedgEntry."Posting Date";
        CustEntryApplyPostedEntries.PostUnApplyCustomer(DtldCustLedgEntry, ApplyUnapplyParameters);
    end;

    local procedure PostCustomerUnapplyStepwise(var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        i: Integer;
    begin
        CustLedgerEntry.FindLast();

        for i := 1 to CustLedgerEntry.Count - 1 do begin
            // Unapply in reverse order.
            CustLedgerEntry.Next(-1);
            PostCustomerUnapplyOneGo(CustLedgerEntry);
        end;
    end;

    local procedure SetExchRateForCurrency(CurrencyAdjustFactor: Decimal): Code[10]
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        // Find currency code with realized gaisn/losses account
        Currency.Get(LibraryERM.CreateCurrencyWithGLAccountSetup());

        // Create new exchange rates
        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, WorkDate());
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 100);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", 100);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", 100);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", 100);
        CurrencyExchangeRate.Modify(true);

        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, CalcDate('<1D>', WorkDate()));
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 100);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", 100);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", 100 * CurrencyAdjustFactor);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", 100 * CurrencyAdjustFactor);
        CurrencyExchangeRate.Modify(true);

        exit(Currency.Code);
    end;

    local procedure GetDirectVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup"; var GLAccount: Record "G/L Account"; VATFilter: Text[30])
    begin
        VATPostingSetup.SetFilter("VAT %", VATFilter);
        VATPostingSetup.SetRange("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        VATPostingSetup.FindSet();
        repeat
            GLAccount.SetRange("Gen. Posting Type", GLAccount."Gen. Posting Type"::Sale);
            GLAccount.SetFilter("Gen. Bus. Posting Group", '<>''''');
            GLAccount.SetFilter("Gen. Prod. Posting Group", '<>''''');
            GLAccount.SetRange("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
            GLAccount.SetRange("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
            GLAccount.SetRange("Direct Posting", true);
        until (VATPostingSetup.Next() = 0) or GLAccount.FindFirst();

        VATPostingSetup.Get(GLAccount."VAT Bus. Posting Group", GLAccount."VAT Prod. Posting Group");
    end;

    local procedure GetLastTransactionNo(): Integer
    var
        GLEntry: Record "G/L Entry";
    begin
        GLEntry.FindLast();
        exit(GLEntry."Transaction No.");
    end;

    local procedure GetPaymentTerms(DiscountFilter: Text[30]): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.Reset();
        PaymentTerms.SetFilter("Discount %", DiscountFilter);
        PaymentTerms.FindFirst();
        PaymentTerms."Calc. Pmt. Disc. on Cr. Memos" := true;
        PaymentTerms.Modify(true);
        exit(PaymentTerms.Code);
    end;

    local procedure GetGLBalancedBatch(var GenJnlTemplate: Record "Gen. Journal Template"; var GenJnlBatch: Record "Gen. Journal Batch"; TemplateType: Enum "Gen. Journal Template Type")
    begin
        // Find template type.
        GenJnlTemplate.SetFilter(Type, Format(TemplateType));
        LibraryERM.FindGenJournalTemplate(GenJnlTemplate);

        // Create a GL balanced batch.
        LibraryERM.CreateGenJournalBatch(GenJnlBatch, GenJnlTemplate.Name);
        GenJnlBatch.Validate("Bal. Account Type", GenJnlBatch."Bal. Account Type"::"G/L Account");
        GenJnlBatch.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJnlBatch.Modify(true);
    end;

    local procedure GetVATBalancedBatch(var GenJournalTemplate: Record "Gen. Journal Template"; var GenJournalBatch: Record "Gen. Journal Batch"; GLAccount: Record "G/L Account")
    begin
        GenJournalBatch.SetRange("Bal. Account Type", GenJournalBatch."Bal. Account Type"::"G/L Account");
        GenJournalBatch.SetRange("Bal. Account No.", GLAccount."No.");
        if not GenJournalBatch.FindFirst() then begin
            GetGLBalancedBatch(GenJournalTemplate, GenJournalBatch, GenJournalTemplate.Type::General);
            GenJournalBatch.Name := 'CustVAT';
            GenJournalBatch."Bal. Account Type" := GenJournalBatch."Bal. Account Type"::"G/L Account";
            GenJournalBatch."Bal. Account No." := GLAccount."No.";
            GenJournalBatch.Insert(true);
        end;
    end;

    local procedure GetPaymentTolerance(): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        exit(GeneralLedgerSetup."Max. Payment Tolerance Amount");
    end;

    local procedure GetDiscount(PmtTerms: Code[10]; Amount: Decimal): Decimal
    var
        PaymentTerms: Record "Payment Terms";
    begin
        PaymentTerms.Get(PmtTerms);
        exit(Amount * PaymentTerms."Discount %" / 100);
    end;

    local procedure RunGenJnlPostLine(var GenJnlLine: Record "Gen. Journal Line"): Integer
    var
        GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line";
    begin
        exit(GenJnlPostLine.RunWithCheck(GenJnlLine));
    end;

    local procedure VerifyCustomerEntriesClosed(var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        CustLedgerEntryLocal: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.FindLast();
        CustLedgerEntryLocal.Copy(CustLedgerEntry);
        CustLedgerEntryLocal.SetRange(Open, true);
        Assert.RecordIsEmpty(CustLedgerEntryLocal);
    end;

    local procedure VerifyCustomerEntriesOpen(var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        CustLedgerEntryLocal: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.FindLast();
        CustLedgerEntryLocal.Copy(CustLedgerEntry);
        CustLedgerEntryLocal.SetRange(Open, false);
        Assert.RecordIsEmpty(CustLedgerEntryLocal);
    end;

    local procedure VerifyAppliedLedgerEntry(CustLedgerEntry: Record "Cust. Ledger Entry"; AppliesToID: Code[50])
    begin
        CustLedgerEntry.Find();
        CustLedgerEntry.CalcFields("Remaining Amount");
        CustLedgerEntry.TestField("Applies-to ID", AppliesToID);
        CustLedgerEntry.TestField("Amount to Apply", CustLedgerEntry."Remaining Amount");
    end;

    local procedure VerifyUnappliedLedgerEntry(CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        CustLedgerEntry.Find();
        CustLedgerEntry.TestField("Applies-to ID", '');
        CustLedgerEntry.TestField("Amount to Apply", 0);
        CustLedgerEntry.TestField("Accepted Payment Tolerance", 0);
        CustLedgerEntry.TestField("Accepted Pmt. Disc. Tolerance", false);
    end;

    local procedure VerifyBlankAppliestoID(CustomerNo: Code[20]; DocumentNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document No.", DocumentNo);
        CustLedgerEntry.SetRange("Document Type", DocumentType);
        CustLedgerEntry.FindSet();
        repeat
            CustLedgerEntry.TestField(Open, false);
            CustLedgerEntry.TestField("Applies-to ID", '');
            CustLedgerEntry.TestField("Applies-to Doc. No.", '');
        until CustLedgerEntry.Next() = 0;
    end;

    local procedure VerifyRoundingDtldEntryExists(CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::"Appln. Rounding");
        Assert.RecordIsNotEmpty(DetailedCustLedgEntry);
    end;

    local procedure VerifyRoundingDtldEntryDoesnotExist(CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
    begin
        DetailedCustLedgEntry.SetRange("Cust. Ledger Entry No.", CustLedgerEntry."Entry No.");
        DetailedCustLedgEntry.SetRange("Entry Type", DetailedCustLedgEntry."Entry Type"::"Appln. Rounding");
        Assert.RecordIsEmpty(DetailedCustLedgEntry);
    end;

    local procedure FindLastApplEntry(VendLedgEntryNo: Integer): Integer
    var
        DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry";
        ApplicationEntryNo: Integer;
    begin
        DtldCustLedgEntry.SetCurrentKey("Cust. Ledger Entry No.", "Entry Type");
        DtldCustLedgEntry.SetRange("Cust. Ledger Entry No.", VendLedgEntryNo);
        DtldCustLedgEntry.SetRange("Entry Type", DtldCustLedgEntry."Entry Type"::Application);
        ApplicationEntryNo := 0;
        if DtldCustLedgEntry.Find('-') then
            repeat
                if (DtldCustLedgEntry."Entry No." > ApplicationEntryNo) and not DtldCustLedgEntry.Unapplied then
                    ApplicationEntryNo := DtldCustLedgEntry."Entry No.";
            until DtldCustLedgEntry.Next() = 0;
        exit(ApplicationEntryNo);
    end;

    local procedure TearDown()
    begin
        LibraryPmtDiscSetup.ClearAdjustPmtDiscInVATSetup();
    end;

    local procedure CreateAndPostGenJnlLines(var CustLedgerEntry: array[3] of Record "Cust. Ledger Entry"; Customer: Record Customer)
    var
        GenJournalLine: Record "Gen. Journal Line";
        Index: Integer;
    begin
        for Index := 1 to ArrayLen(CustLedgerEntry) do begin
            Clear(GenJournalLine);
            LibraryJournals.CreateGenJournalLineWithBatch(
                GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Customer, Customer."No.", LibraryRandom.RandIntInRange(100, 200));
            GenJournalLine.Validate("Posting Date", WorkDate() + 1);
            GenJournalLine.Modify(true);
            LibraryERM.PostGeneralJnlLine(GenJournalLine);
            CustLedgerEntry[Index].SetRange("Customer No.", Customer."No.");
            LibraryERM.FindCustomerLedgerEntry(CustLedgerEntry[Index], CustLedgerEntry[Index]."Document Type"::Invoice, GenJournalLine."Document No.");
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries.Filter.SetFilter("Document No.", LibraryVariableStorage.DequeueText());
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        if (LibraryVariableStorage.DequeueBoolean()) then
            ApplyCustomerEntries."Post Application".Invoke()
        else
            ApplyCustomerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesTwiceModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    begin
        ApplyCustomerEntries.Filter.SetFilter("Document No.", LibraryVariableStorage.DequeueText());
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
        ApplyCustomerEntries."Set Applies-to ID".Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostApplicationModalPageHandler(var PostApplication: TestPage "Post Application")
    begin
        PostApplication.DocNo.SetValue(LibraryVariableStorage.DequeueText());
        PostApplication.PostingDate.SetValue(LibraryVariableStorage.DequeueDate());
        PostApplication.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    var
        AmountToApply: Decimal;
    begin
        ApplyCustomerEntries.First();
        ApplyCustomerEntries.AppliesToID.SetValue(UserId());
        AmountToApply := ApplyCustomerEntries."Amount to Apply".AsDecimal();
        ApplyCustomerEntries.AppliedAmount.AssertEquals(AmountToApply);
        ApplyCustomerEntries.Next();
        ApplyCustomerEntries.AppliesToID.SetValue(UserId());
        AmountToApply += ApplyCustomerEntries."Amount to Apply".AsDecimal();
        ApplyCustomerEntries.AppliedAmount.AssertEquals(AmountToApply);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure SimpleMessageHandler(Message: Text[1024])
    begin
    end;
}

