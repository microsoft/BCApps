codeunit 144039 "UT PAG Debit Credit"
{
    //  1. Purpose of the test is to verify Debit Amount and Credit Amount captions are available on Page ID - 256 Payment Journal.
    //  2. Purpose of the test is to verify Amount Caption is not available on Page ID - 256 Payment Journal.
    //  3. Purpose of the test is to verify Debit Amount and Credit Amount captions are available on Page ID - 255 Cash Receipt Journal.
    //  4. Purpose of the test is to verify Amount Caption is not available on Page ID - 255 Cash Receipt Journal.
    //  5. Purpose of the test is to verify Debit Amount and Credit Amount captions are available on Page ID - 254 Purchase Journal.
    //  6. Purpose of the test is to verify Amount Caption is not available on Page ID - 254 Purchase Journal.
    //  7. Purpose of the test is to verify Debit Amount and Credit Amount captions are available on Page ID - 253 Sales Journal.
    //  8. Purpose of the test is to verify Amount Caption is not available on Page ID - 253 Sales Journal.
    //  9. Purpose of the test is to verify Debit Amount and Credit Amount captions are available on Page ID - 39 General Journal.
    // 10. Purpose of the test is to verify Amount Caption is not available on Page ID - 39 General Journal.
    // 11. Purpose of the test is to verify Debit Amount and Credit Amount captions are available on Page ID - 283 Recurring General Journal.
    // 12. Purpose of the test is to verify Amount Caption is not available on Page ID - 283 Recurring General Journal
    // 13. Purpose of the test is to verify Debit Amount and Credit Amount captions are available on Page ID - 16 Chart Of Accounts.
    // 14. Purpose of the test is to verify Debit Amount and Credit Amount captions are available on Page ID - 20 General Ledger Entries.
    // 15. Purpose of the test is to verify Amount Caption is not available on Page ID - 20 General Ledger Entries.
    // 
    // Covers Test Cases for WI - 351171
    // ----------------------------------------------------------------------------------------------------------------------
    // Test Function Name                                                                                              TFS ID
    // ----------------------------------------------------------------------------------------------------------------------
    // AmountCaptionsAvailableOnPaymentJournalPage, AmountCaptionUnavailableOnPaymentJournalPage                       151219
    // AmountCaptionsAvailableOnCashReceiptJournalPage, AmountCaptionUnavailableOnCashReceiptJournalPage               151220
    // AmountCaptionsAvailableOnPurchaseJournalPage, AmountCaptionUnavailableOnPurchaseJournalPage                     151221
    // AmountCaptionsAvailableOnSalesJournalPage, AmountCaptionUnavailableOnSalesJournalPage                           151222
    // AmountCaptionsAvailableOnGeneralJournalPage, AmountCaptionUnavailableOnGeneralJournalPage                       151223
    // AmountCaptionsAvailableOnRecurringGenJournalPage, AmountCaptionUnavailableOnRecurringGenJournalPage             151224
    // AmountCaptionsAvailableOnChartOfAccountsPage                                                                    151225
    // AmountCaptionsAvailableOnGeneralLedgerEntriesPage, AmountCaptionUnavailableOnGeneralLedgerEntriesPage           151226

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        Assert: Codeunit Assert;
        CaptionMustBeSameMsg: Label 'Caption must be same.';
        CreditAmountCap: Label 'Credit Amount';
        DebitAmountCap: Label 'Debit Amount';
        CreditAmountLCYTxt: Label 'Credit Amount (LCY)';
        DebitAmountLCYTxt: Label 'Debit Amount (LCY)';
        isInitialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure AmountCaptionsAvailableOnPaymentJournalPage()
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        // Purpose of the test is to verify Debit Amount and Credit Amount captions are available on Page ID - 256 Payment Journal.
        Initialize();

        // Setup.
        // Exercise.
        PaymentJournal.OpenEdit();

        // Verify: Verify Debit Amount and Credit Amount Captions on Payment Journal Page.
        VerifyAmountCaptionOnPage(PaymentJournal."Credit Amount".Caption, PaymentJournal."Debit Amount".Caption);
        PaymentJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountCaptionUnavailableOnPaymentJournalPage()
    var
        PaymentJournal: TestPage "Payment Journal";
    begin
        // Purpose of the test is to verify Amount Caption is not available on Page ID - 256 Payment Journal.
        Initialize();

        // Setup.
        PaymentJournal.OpenEdit();

        // Exercise and verify
        Assert.AreEqual(PaymentJournal.Amount.Visible(), false, 'Field Amount should not be Visible in Payment Journal');
        PaymentJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountCaptionsAvailableOnCashReceiptJournalPage()
    var
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        // Purpose of the test is to verify Debit Amount and Credit Amount captions are available on Page ID - 255 Cash Receipt Journal.
        Initialize();

        // Setup.
        // Exercise.
        CashReceiptJournal.OpenEdit();

        // Verify: Verify Debit Amount and Credit Amount Captions on Cash Receipt Journal Page.
        VerifyAmountCaptionOnPage(CashReceiptJournal."Credit Amount".Caption, CashReceiptJournal."Debit Amount".Caption);
        CashReceiptJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountCaptionUnavailableOnCashReceiptJournalPage()
    var
        CashReceiptJournal: TestPage "Cash Receipt Journal";
    begin
        // Purpose of the test is to verify Amount Caption is not available on Page ID - 255 Cash Receipt Journal.
        Initialize();

        // Setup.
        CashReceiptJournal.OpenEdit();

        // Exercise and verify
        Assert.AreEqual(CashReceiptJournal.Amount.Visible(), false, 'Field Amount should not be Visible in Cash Receipt Journal');
        CashReceiptJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountCaptionsAvailableOnPurchaseJournalPage()
    var
        PurchaseJournal: TestPage "Purchase Journal";
    begin
        // Purpose of the test is to verify Debit Amount and Credit Amount captions are available on Page ID - 254 Purchase Journal.
        Initialize();

        // Setup.
        // Exercise.
        PurchaseJournal.OpenEdit();

        // Verify: Verify Debit Amount and Credit Amount Captions on Purchase Journal Page.
        VerifyAmountCaptionOnPage(PurchaseJournal."Credit Amount".Caption, PurchaseJournal."Debit Amount".Caption);
        PurchaseJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountCaptionUnavailableOnPurchaseJournalPage()
    var
        PurchaseJournal: TestPage "Purchase Journal";
    begin
        // Purpose of the test is to verify Amount Caption is not available on Page ID - 254 Purchase Journal.
        Initialize();

        // Setup.
        PurchaseJournal.OpenEdit();

        // Exercise and verify
        Assert.AreEqual(PurchaseJournal.Amount.Visible(), false, 'Field Amount should not be Visible in Cash Receipt Journal');
        PurchaseJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountCaptionsAvailableOnSalesJournalPage()
    var
        SalesJournal: TestPage "Sales Journal";
    begin
        // Purpose of the test is to verify Debit Amount and Credit Amount captions are available on Page ID - 253 Sales Journal.
        Initialize();

        // Setup.
        // Exercise.
        SalesJournal.OpenEdit();

        // Verify: Verify Debit Amount and Credit Amount Captions on Sales Journal Page.
        VerifyAmountCaptionOnPage(SalesJournal."Credit Amount".Caption, SalesJournal."Debit Amount".Caption);
        SalesJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountCaptionUnavailableOnSalesJournalPage()
    var
        SalesJournal: TestPage "Sales Journal";
    begin
        // Purpose of the test is to verify Amount Caption is not available on Page ID - 253 Sales Journal.
        Initialize();

        // Setup.
        SalesJournal.OpenEdit();

        // Exercise and verify
        Assert.AreEqual(SalesJournal.Amount.Visible(), false, 'Field Amount should not be Visible in Sales Journal');
        SalesJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountCaptionsAvailableOnGeneralJournalPage()
    var
        GeneralJournal: TestPage "General Journal";
    begin
        // Purpose of the test is to verify Debit Amount and Credit Amount captions are available on Page ID - 39 General Journal.
        Initialize();

        // Setup.
        // Exercise.
        GeneralJournal.OpenEdit();

        // Verify: Verify Debit Amount and Credit Amount Captions on General Journal Page.
        VerifyAmountCaptionOnPage(GeneralJournal."Credit Amount".Caption, GeneralJournal."Debit Amount".Caption);
        GeneralJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountCaptionUnavailableOnGeneralJournalPage()
    var
        GeneralJournal: TestPage "General Journal";
    begin
        // Purpose of the test is to verify Amount Caption is not available on Page ID - 39 General Journal.
        Initialize();

        // Setup.
        GeneralJournal.OpenEdit();

        // Exercise and verify
        Assert.AreEqual(GeneralJournal.Amount.Visible(), false, 'Field Amount should not be Visible in General Journal');
        GeneralJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountCaptionsAvailableOnRecurringGenJournalPage()
    var
        RecurringGeneralJournal: TestPage "Recurring General Journal";
    begin
        // Purpose of the test is to verify Debit Amount and Credit Amount captions are available on Page ID - 283 Recurring General Journal.
        // Commit is explicitly called in function CheckTemplateName in codeunit - 230 GenJnlManagement.
        Initialize();

        // Setup.
        // Exercise.
        RecurringGeneralJournal.OpenEdit();

        // Verify: Verify Debit Amount and Credit Amount Captions on Recurring General Journal Page.
        VerifyAmountCaptionOnPage(RecurringGeneralJournal."Credit Amount".Caption, RecurringGeneralJournal."Debit Amount".Caption);
        RecurringGeneralJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountCaptionUnavailableOnRecurringGenJournalPage()
    var
        RecurringGeneralJournal: TestPage "Recurring General Journal";
    begin
        // Purpose of the test is to verify Amount Caption is not available on Page ID - 283 Recurring General Journal.
        // Commit is explicitly called in function CheckTemplateName in codeunit - 230 GenJnlManagement.
        Initialize();

        // Setup.
        RecurringGeneralJournal.OpenEdit();

        // Exercise verify
        Assert.AreEqual(RecurringGeneralJournal.Amount.Visible(), false, 'Field Amount should not be Visible in Recurring General Journal');
        RecurringGeneralJournal.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountCaptionsAvailableOnChartOfAccountsPage()
    var
        ChartOfAccounts: TestPage "Chart of Accounts";
    begin
        // Purpose of the test is to verify Debit Amount and Credit Amount captions are available on Page ID - 16 Chart Of Accounts.
        Initialize();

        // Setup.
        // Exercise.
        ChartOfAccounts.OpenEdit();

        // Verify: Verify Debit Amount and Credit Amount Captions on Chart Of Accounts Page.
        VerifyAmountCaptionOnPage(ChartOfAccounts."Credit Amount".Caption, ChartOfAccounts."Debit Amount".Caption);
        ChartOfAccounts.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountCaptionsAvailableOnGeneralLedgerEntriesPage()
    var
        GeneralLedgerEntries: TestPage "General Ledger Entries";
    begin
        // Purpose of the test is to verify Debit Amount and Credit Amount captions are available on Page ID - 20 General Ledger Entries.
        Initialize();

        // Setup.
        // Exercise.
        GeneralLedgerEntries.OpenEdit();

        // Verify: Verify Debit Amount and Credit Amount Captions on General Ledger Entries Page.
        VerifyAmountCaptionLCYOnPage(GeneralLedgerEntries."Credit Amount".Caption, GeneralLedgerEntries."Debit Amount".Caption);
        GeneralLedgerEntries.Close();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AmountCaptionUnavailableOnGeneralLedgerEntriesPage()
    var
        GeneralLedgerEntries: TestPage "General Ledger Entries";
    begin
        // Purpose of the test is to verify Amount Caption is not available on Page ID - 20 General Ledger Entries.
        Initialize();

        // Setup.
        GeneralLedgerEntries.OpenEdit();

        // Exercise and verify
        Assert.AreEqual(GeneralLedgerEntries.Amount.Visible(), false, 'Field Amount should not be Visible in General Ledger Entries');
        GeneralLedgerEntries.Close();
    end;

    local procedure Initialize()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if isInitialized then
            exit;

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Show Amounts" := GeneralLedgerSetup."Show Amounts"::"Debit/Credit Only";
        GeneralLedgerSetup.Modify();

        isInitialized := true;
        Commit();
    end;

    local procedure VerifyAmountCaptionOnPage(CreditAmount: Text; DebitAmount: Text)
    begin
        Assert.AreEqual(StrSubstNo(DebitAmountCap), DebitAmount, CaptionMustBeSameMsg);
        Assert.AreEqual(StrSubstNo(CreditAmountCap), CreditAmount, CaptionMustBeSameMsg);
    end;

    local procedure VerifyAmountCaptionLCYOnPage(CreditAmount: Text; DebitAmount: Text)
    begin
        Assert.AreEqual(StrSubstNo(DebitAmountLCYTxt), DebitAmount, CaptionMustBeSameMsg);
        Assert.AreEqual(StrSubstNo(CreditAmountLCYTxt), CreditAmount, CaptionMustBeSameMsg);
    end;
}

