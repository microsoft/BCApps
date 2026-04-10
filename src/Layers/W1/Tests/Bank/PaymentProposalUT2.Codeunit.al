codeunit 134268 "Payment Proposal UT 2"
{
    Permissions = TableData "Cust. Ledger Entry" = imd,
                  TableData "Vendor Ledger Entry" = imd;
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Bank Reconciliation] [Payment Application Proposal] [UT]
    end;

    var
        ZeroVATPostingSetup: Record "VAT Posting Setup";
        LibraryRandom: Codeunit "Library - Random";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        TransactionDateIsBeforePostingDateTxt: Label 'The transaction date %1 is before the posting date %2.';

    local procedure Initialize()
    var
        InventorySetup: Record "Inventory Setup";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        AppliedPaymentEntry: Record "Applied Payment Entry";
        GeneralLedgerSetup: Record "General Ledger Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Payment Proposal UT 2");

        LibraryVariableStorage.Clear();
        BankAccReconciliation.DeleteAll(true);
        BankAccReconciliationLine.DeleteAll(true);
        AppliedPaymentEntry.DeleteAll(true);
        CloseExistingEntries();

        GeneralLedgerSetup.Get();
        Evaluate(GeneralLedgerSetup."Payment Discount Grace Period", '<0D>');
        GeneralLedgerSetup.Modify();

        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Payment Proposal UT 2");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibraryERM.FindZeroVATPostingSetup(ZeroVATPostingSetup, ZeroVATPostingSetup."VAT Calculation Type"::"Normal VAT");
        Commit();
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Payment Proposal UT 2");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplyWhenAmountIsMissing()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        PaymentApplicationProposal: Record "Payment Application Proposal";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);
        CreateAndPostPurhcaseInvoiceWithOneLine(VendorLedgerEntry, Amount, '', false);

        AppliedAmount := -Round(Amount / 2, LibraryERM.GetAmountRoundingPrecision());
        CreateBankReconciliationLine(
          BankAccReconciliationLine, AppliedAmount, VendorLedgerEntry."Document No.", VendorLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        // Excercise
        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        NoOfEntries := 1;
        Difference := 0;

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, VendorLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.IsTrue(PaymentApplicationProposal.IsEmpty, 'Payment Applications proposal table must be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplyWithExcessAmount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        PaymentApplicationProposal: Record "Payment Application Proposal";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := -LibraryRandom.RandDecInRange(1, 10000, 2);

        AppliedAmount := Round(Amount / 2, LibraryERM.GetAmountRoundingPrecision());

        CreateAndPostPurhcaseInvoiceWithOneLine(VendorLedgerEntry, -AppliedAmount, '', false);
        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, VendorLedgerEntry."Document No.", VendorLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        // Excercise
        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        NoOfEntries := 1;
        Difference := Amount - AppliedAmount;

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, VendorLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.IsTrue(PaymentApplicationProposal.IsEmpty, 'Payment Applications proposal table must be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplyOnMultipleRecords()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        PaymentApplicationProposal: Record "Payment Application Proposal";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        TotalAmount: Decimal;
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        I: Integer;
        VendorNo: Code[20];
    begin
        Initialize();

        NoOfEntries := 3;
        TotalAmount := 0;

        // Setup
        for I := 1 to NoOfEntries do begin
            Amount := -LibraryRandom.RandDecInRange(1, 10000, 2);
            CreateAndPostPurhcaseInvoiceWithOneLine(VendorLedgerEntry, -Amount, VendorNo, false);
            VendorNo := VendorLedgerEntry."Vendor No.";
            TotalAmount += Amount;
        end;

        CreateBankReconciliationLine(BankAccReconciliationLine, TotalAmount, '', '');
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        Clear(VendorLedgerEntry);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetAutoCalcFields("Remaining Amount");
        VendorLedgerEntry.FindSet();

        Difference := TotalAmount;

        // Excercise and verify multiple applications
        for I := 1 to NoOfEntries do begin
            TempPaymentApplicationProposal.Validate(Applied, true);
            TempPaymentApplicationProposal.Modify(true);

            Difference -= VendorLedgerEntry."Remaining Amount";
            AppliedAmount += VendorLedgerEntry."Remaining Amount";

            // Verify Bank Acc Reconciliation Line
            VerifyBankAccReconciliationLineIsUpdatedCorrectly(
              BankAccReconciliationLine, TempPaymentApplicationProposal, VendorLedgerEntry, AppliedAmount, Difference, I);

            // Verify Applied Payment Entry Exists and the fields are set
            VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

            VendorLedgerEntry.Next();
            TempPaymentApplicationProposal.Next();
        end;

        // Test no Insertions to Payment Application Proposal has occured
        Assert.IsTrue(PaymentApplicationProposal.IsEmpty, 'Payment Applications proposal table must be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUncheckingApplySingleRow()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        PaymentApplicationProposal: Record "Payment Application Proposal";
        AppliedPaymentEntry: Record "Applied Payment Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := -LibraryRandom.RandDecInRange(1, 10000, 2);
        CreateAndPostPurhcaseInvoiceWithOneLine(VendorLedgerEntry, -Amount, '', false);
        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, VendorLedgerEntry."Document No.", VendorLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        // Excercise
        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);
        TempPaymentApplicationProposal.Validate(Applied, false);
        TempPaymentApplicationProposal.Modify(true);

        Difference := Amount;
        AppliedAmount := 0;
        NoOfEntries := 0;

        // Verify line
        Assert.AreEqual(TempPaymentApplicationProposal."Applied Amount", 0, 'Applied amount must be set to zero when Unapplying');

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, VendorLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry is removed from database
        VerifyAppliedPaymentEntryDoesntExist(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.IsTrue(PaymentApplicationProposal.IsEmpty, 'Payment Applications proposal table must be empty');
        Assert.IsTrue(AppliedPaymentEntry.IsEmpty, 'Applied Payments entry table must be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUncheckingApplyMultipleRows()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        PaymentApplicationProposal: Record "Payment Application Proposal";
        AppliedPaymentEntry: Record "Applied Payment Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        TotalAmount: Decimal;
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        I: Integer;
        VendorNo: Code[20];
    begin
        Initialize();

        NoOfEntries := 3;
        TotalAmount := 0;

        // Setup - Apply to 3 Ledger Entries
        for I := 1 to NoOfEntries do begin
            Amount := -LibraryRandom.RandDecInRange(1, 10000, 2);
            CreateAndPostPurhcaseInvoiceWithOneLine(VendorLedgerEntry, -Amount, VendorNo, false);
            VendorNo := VendorLedgerEntry."Vendor No.";
            TotalAmount += Amount;
        end;

        CreateBankReconciliationLine(BankAccReconciliationLine, TotalAmount, '', '');
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        Clear(VendorLedgerEntry);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetAutoCalcFields("Remaining Amount");
        VendorLedgerEntry.FindSet();

        for I := 1 to NoOfEntries do begin
            TempPaymentApplicationProposal.Validate(Applied, true);
            TempPaymentApplicationProposal.Modify(true);
            VendorLedgerEntry.Next();
            TempPaymentApplicationProposal.Next();
        end;

        Difference := 0;
        AppliedAmount := TotalAmount;

        TempPaymentApplicationProposal.FindFirst();

        // Excercise - Uncheck one by one
        for I := 1 to NoOfEntries do begin
            Difference += TempPaymentApplicationProposal."Applied Amount";
            AppliedAmount -= TempPaymentApplicationProposal."Applied Amount";

            TempPaymentApplicationProposal.Validate(Applied, false);
            TempPaymentApplicationProposal.Modify(true);

            // Verify Bank Acc Reconciliation Line
            VerifyBankAccReconciliationLineIsUpdatedCorrectly(
              BankAccReconciliationLine, TempPaymentApplicationProposal, VendorLedgerEntry, AppliedAmount, Difference, NoOfEntries - I);

            // Verify Applied Payment Entry Does not Exist and the fields are set
            VerifyAppliedPaymentEntryDoesntExist(TempPaymentApplicationProposal);
            TempPaymentApplicationProposal.Next();
        end;

        // Test no Insertions to Payment Application Proposal has occured
        Assert.IsTrue(PaymentApplicationProposal.IsEmpty, 'Payment Applications proposal table must be empty');
        Assert.IsTrue(AppliedPaymentEntry.IsEmpty, 'Applied Payments entry table must be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSettingAppliedAmountOnSingleRowAppliesEntries()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        PaymentApplicationProposal: Record "Payment Application Proposal";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := -LibraryRandom.RandDecInRange(1, 10000, 2);
        CreateAndPostPurhcaseInvoiceWithOneLine(VendorLedgerEntry, -Amount, '', false);

        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, VendorLedgerEntry."Document No.", VendorLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        // Excercise
        AppliedAmount := Round(Amount / 2, LibraryERM.GetAmountRoundingPrecision());
        TempPaymentApplicationProposal.Validate("Applied Amt. Incl. Discount", AppliedAmount);
        TempPaymentApplicationProposal.Modify(true);

        NoOfEntries := 1;
        Difference := Amount - AppliedAmount;

        // Verify Applied got updated
        Assert.IsTrue(TempPaymentApplicationProposal.Applied, 'Applied should be set to True');

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, VendorLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.IsTrue(PaymentApplicationProposal.IsEmpty, 'Payment Applications proposal table must be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSettingAppliedAmountTooGreatRaisesError()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
    begin
        Initialize();

        // Setup
        Amount := -LibraryRandom.RandDecInRange(1, 10000, 2);
        CreateAndPostPurhcaseInvoiceWithOneLine(VendorLedgerEntry, -Amount, '', false);

        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, VendorLedgerEntry."Document No.", VendorLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        // Excercise
        AppliedAmount := Round(Amount * 2, LibraryERM.GetAmountRoundingPrecision());
        asserterror TempPaymentApplicationProposal.Validate("Applied Amt. Incl. Discount", AppliedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSettingAppliedAmountOnMultipleRowsAppliesEntries()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        PaymentApplicationProposal: Record "Payment Application Proposal";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        TotalAmount: Decimal;
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        I: Integer;
        VendorNo: Code[20];
    begin
        Initialize();

        NoOfEntries := 3;
        TotalAmount := 0;

        // Setup
        for I := 1 to NoOfEntries do begin
            Amount := -LibraryRandom.RandDecInRange(1, 10000, 2);
            CreateAndPostPurhcaseInvoiceWithOneLine(VendorLedgerEntry, -Amount, VendorNo, false);
            VendorNo := VendorLedgerEntry."Vendor No.";
            TotalAmount += Amount;
        end;

        CreateBankReconciliationLine(BankAccReconciliationLine, TotalAmount, '', '');
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        Clear(VendorLedgerEntry);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetAutoCalcFields("Remaining Amount");
        VendorLedgerEntry.FindSet();

        Difference := TotalAmount;

        // Excercise and verify multiple applications
        for I := 1 to NoOfEntries do begin
            TempPaymentApplicationProposal.Validate("Applied Amt. Incl. Discount", VendorLedgerEntry."Remaining Amount");
            TempPaymentApplicationProposal.Modify(true);

            Difference -= VendorLedgerEntry."Remaining Amount";
            AppliedAmount += VendorLedgerEntry."Remaining Amount";

            // Verify Applied got updated
            Assert.IsTrue(TempPaymentApplicationProposal.Applied, 'Applied should be set to True');

            // Verify Bank Acc Reconciliation Line
            VerifyBankAccReconciliationLineIsUpdatedCorrectly(
              BankAccReconciliationLine, TempPaymentApplicationProposal, VendorLedgerEntry, AppliedAmount, Difference, I);

            // Verify Applied Payment Entry Exists and the fields are set
            VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

            VendorLedgerEntry.Next();
            TempPaymentApplicationProposal.Next();
        end;

        // Test no Insertions to Payment Application Proposal has occured
        Assert.IsTrue(PaymentApplicationProposal.IsEmpty, 'Payment Applications proposal table must be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangingAppliedAmountUpdatesExistingEntries()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        PaymentApplicationProposal: Record "Payment Application Proposal";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        TotalAmount: Decimal;
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NewAppliedAmount: Decimal;
        NoOfEntries: Integer;
        I: Integer;
        VendorNo: Code[20];
    begin
        Initialize();

        NoOfEntries := 3;
        TotalAmount := 0;

        // Setup
        for I := 1 to NoOfEntries do begin
            Amount := -LibraryRandom.RandDecInRange(1, 10000, 2);
            CreateAndPostPurhcaseInvoiceWithOneLine(VendorLedgerEntry, -Amount, VendorNo, false);
            VendorNo := VendorLedgerEntry."Vendor No.";
            TotalAmount += Amount;
        end;

        CreateBankReconciliationLine(BankAccReconciliationLine, TotalAmount, '', '');
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        Clear(VendorLedgerEntry);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetAutoCalcFields("Remaining Amount");
        VendorLedgerEntry.FindSet();

        Difference := TotalAmount;

        for I := 1 to NoOfEntries do begin
            TempPaymentApplicationProposal.Validate("Applied Amt. Incl. Discount", VendorLedgerEntry."Remaining Amount");
            TempPaymentApplicationProposal.Modify(true);

            Difference -= VendorLedgerEntry."Remaining Amount";
            AppliedAmount += VendorLedgerEntry."Remaining Amount";

            VendorLedgerEntry.Next();
            TempPaymentApplicationProposal.Next();
        end;

        // Excercise and verify multiple applications
        TempPaymentApplicationProposal.FindFirst();
        for I := 1 to NoOfEntries do begin
            NewAppliedAmount := Round(TempPaymentApplicationProposal."Applied Amount" / 2, LibraryERM.GetAmountRoundingPrecision());
            Difference += TempPaymentApplicationProposal."Applied Amount" - NewAppliedAmount;
            AppliedAmount -= TempPaymentApplicationProposal."Applied Amount" - NewAppliedAmount;
            TempPaymentApplicationProposal.Validate("Applied Amt. Incl. Discount", NewAppliedAmount);

            // Verify Applied didn't change
            Assert.IsTrue(TempPaymentApplicationProposal.Applied, 'Applied should be set to True');

            // Verify Bank Acc Reconciliation Line
            VerifyBankAccReconciliationLineIsUpdatedCorrectly(
              BankAccReconciliationLine, TempPaymentApplicationProposal, VendorLedgerEntry, AppliedAmount, Difference, NoOfEntries);

            // Verify Applied Payment Entry Exists and the fields are updated
            VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);
            TempPaymentApplicationProposal.Next();
        end;

        // Test no Insertions to Payment Application Proposal has occured
        Assert.IsTrue(PaymentApplicationProposal.IsEmpty, 'Payment Applications proposal table must be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSettingAppliedAmountToZeroUnapliesEntries()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        PaymentApplicationProposal: Record "Payment Application Proposal";
        AppliedPaymentEntry: Record "Applied Payment Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := -LibraryRandom.RandDecInRange(1, 10000, 2);
        CreateAndPostPurhcaseInvoiceWithOneLine(VendorLedgerEntry, -Amount, '', false);

        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, VendorLedgerEntry."Document No.", VendorLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        AppliedAmount := Round(Amount / 2, LibraryERM.GetAmountRoundingPrecision());
        TempPaymentApplicationProposal.Validate("Applied Amount", Amount);
        TempPaymentApplicationProposal.Modify(true);

        // Excercise
        TempPaymentApplicationProposal.Validate("Applied Amt. Incl. Discount", 0);
        TempPaymentApplicationProposal.Modify(true);

        NoOfEntries := 0;
        Difference := Amount;

        // Verify Applied got updated
        Assert.IsFalse(TempPaymentApplicationProposal.Applied, 'Applied should be set to FALSE');

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, VendorLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryDoesntExist(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.IsTrue(PaymentApplicationProposal.IsEmpty, 'Payment Applications proposal table must be empty');
        Assert.IsTrue(AppliedPaymentEntry.IsEmpty, 'Applied Payments entry table must be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSettingAppliedAmountToZeroUnappliesMultipleEntries()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        PaymentApplicationProposal: Record "Payment Application Proposal";
        AppliedPaymentEntry: Record "Applied Payment Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        TotalAmount: Decimal;
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
        I: Integer;
        VendorNo: Code[20];
    begin
        Initialize();

        NoOfEntries := 3;
        TotalAmount := 0;

        // Setup
        for I := 1 to NoOfEntries do begin
            Amount := -LibraryRandom.RandDecInRange(1, 10000, 2);
            CreateAndPostPurhcaseInvoiceWithOneLine(VendorLedgerEntry, -Amount, VendorNo, false);
            VendorNo := VendorLedgerEntry."Vendor No.";
            TotalAmount += Amount;
        end;

        CreateBankReconciliationLine(BankAccReconciliationLine, TotalAmount, '', '');
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        Clear(VendorLedgerEntry);
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetAutoCalcFields("Remaining Amount");
        VendorLedgerEntry.FindSet();

        Difference := TotalAmount;

        for I := 1 to NoOfEntries do begin
            TempPaymentApplicationProposal.Validate("Applied Amt. Incl. Discount", VendorLedgerEntry."Remaining Amount");
            TempPaymentApplicationProposal.Modify(true);

            Difference -= VendorLedgerEntry."Remaining Amount";
            AppliedAmount += VendorLedgerEntry."Remaining Amount";

            VendorLedgerEntry.Next();
            TempPaymentApplicationProposal.Next();
        end;

        // Excercise and verify multiple applications
        TempPaymentApplicationProposal.FindFirst();
        for I := 1 to NoOfEntries do begin
            Difference += TempPaymentApplicationProposal."Applied Amount";
            AppliedAmount -= TempPaymentApplicationProposal."Applied Amount";
            TempPaymentApplicationProposal.Validate("Applied Amt. Incl. Discount", 0);
            TempPaymentApplicationProposal.Modify(true);

            // Verify Applied got updated
            Assert.IsFalse(TempPaymentApplicationProposal.Applied, 'Applied should be set to false');

            // Verify Bank Acc Reconciliation Line
            VerifyBankAccReconciliationLineIsUpdatedCorrectly(
              BankAccReconciliationLine, TempPaymentApplicationProposal, VendorLedgerEntry, AppliedAmount, Difference, NoOfEntries - I);

            // Verify Applied Payment Entry is Deleted
            VerifyAppliedPaymentEntryDoesntExist(TempPaymentApplicationProposal);
            TempPaymentApplicationProposal.Next();
        end;

        // Test no Insertions to Payment Application Proposal has occured
        Assert.IsTrue(PaymentApplicationProposal.IsEmpty, 'Payment Applications proposal table must be empty');
        Assert.IsTrue(AppliedPaymentEntry.IsEmpty, 'Applied Payments entry table must be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTransferingExcessAmountToVendorAccount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        PaymentApplicationProposal: Record "Payment Application Proposal";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := -LibraryRandom.RandDecInRange(1, 10000, 2);

        AppliedAmount := Round(Amount / 2, LibraryERM.GetAmountRoundingPrecision());

        CreateAndPostPurhcaseInvoiceWithOneLine(VendorLedgerEntry, -AppliedAmount, '', false);
        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, VendorLedgerEntry."Document No.", VendorLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        // Transfer Excess Amount to Vendor account
        CreateNewPaymentApplicationLine(
          TempPaymentApplicationProposal, BankAccReconciliationLine, TempPaymentApplicationProposal."Account Type"::Vendor,
          VendorLedgerEntry."Vendor No.");

        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        Assert.AreEqual(
          TempPaymentApplicationProposal."Applied Amount", Amount - AppliedAmount,
          'Difference was not transfered correctly to Vendor account');
        NoOfEntries := 2;
        Difference := 0;

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, VendorLedgerEntry, Amount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.IsTrue(PaymentApplicationProposal.IsEmpty, 'Payment Applications proposal table must be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRemovingOfTransferingExcessAmountToVendorAccount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        VendorTempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        PaymentApplicationProposal: Record "Payment Application Proposal";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := -LibraryRandom.RandDecInRange(1, 10000, 2);

        AppliedAmount := Round(Amount / 2, LibraryERM.GetAmountRoundingPrecision());

        CreateAndPostPurhcaseInvoiceWithOneLine(VendorLedgerEntry, -AppliedAmount, '', false);
        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, VendorLedgerEntry."Document No.", VendorLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        // Transfer Excess Amount to Vendor account
        CreateNewPaymentApplicationLine(
          VendorTempPaymentApplicationProposal, BankAccReconciliationLine, TempPaymentApplicationProposal."Account Type"::Vendor,
          VendorLedgerEntry."Vendor No.");

        VendorTempPaymentApplicationProposal.Validate(Applied, true);
        VendorTempPaymentApplicationProposal.Modify(true);

        VendorTempPaymentApplicationProposal.Validate(Applied, false);
        VendorTempPaymentApplicationProposal.Modify(true);

        NoOfEntries := 1;
        Difference := Amount - AppliedAmount;

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, VendorLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.IsTrue(PaymentApplicationProposal.IsEmpty, 'Payment Applications proposal table must be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUpdatingVendorDiscountOnNotAppliedProposal()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        PaymentApplicationProposal: Record "Payment Application Proposal";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        NewDiscountAmount: Decimal;
        NewDiscountDueDate: Date;
    begin
        Initialize();

        // Setup
        Amount := -LibraryRandom.RandDecInRange(1, 10000, 2);

        AppliedAmount := Round(Amount / 2, LibraryERM.GetAmountRoundingPrecision());

        CreateAndPostPurhcaseInvoiceWithOneLine(VendorLedgerEntry, -AppliedAmount, '', true);
        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, VendorLedgerEntry."Document No.", VendorLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        Assert.IsTrue(
          TempPaymentApplicationProposal."Remaining Pmt. Disc. Possible" < 0, 'Remaining Discount possible must be lesser than 0');
        Assert.AreNotEqual(TempPaymentApplicationProposal."Pmt. Disc. Due Date", 0D, 'Remaining Discount possible must be greater than 0');

        NewDiscountDueDate := CalcDate('<1M>', TempPaymentApplicationProposal."Pmt. Disc. Due Date");
        NewDiscountAmount := TempPaymentApplicationProposal."Remaining Pmt. Disc. Possible" * 2;
        TempPaymentApplicationProposal.Validate("Pmt. Disc. Due Date", NewDiscountDueDate);
        TempPaymentApplicationProposal.Validate("Remaining Pmt. Disc. Possible", NewDiscountAmount);

        TempPaymentApplicationProposal.Modify(true);

        VendorLedgerEntry.Get(VendorLedgerEntry."Entry No.");
        Assert.AreEqual(
          TempPaymentApplicationProposal."Remaining Pmt. Disc. Possible", NewDiscountAmount, 'Discount amount was not set correctly');
        Assert.AreEqual(
          TempPaymentApplicationProposal."Pmt. Disc. Due Date", NewDiscountDueDate, 'Discount due date was not set correctly');
        Assert.AreEqual(VendorLedgerEntry."Remaining Pmt. Disc. Possible", NewDiscountAmount, 'Discount amount was not set correctly');
        Assert.AreEqual(VendorLedgerEntry."Pmt. Discount Date", NewDiscountDueDate, 'Discount due date was not set correctly');

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryDoesntExist(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.IsTrue(PaymentApplicationProposal.IsEmpty, 'Payment Applications proposal table must be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSettingVendorDiscountOnAppliedProposal()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        PaymentApplicationProposal: Record "Payment Application Proposal";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        NewDiscountAmount: Decimal;
        Difference: Decimal;
        NewDiscountDueDate: Date;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := -LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostPurhcaseInvoiceWithOneLine(VendorLedgerEntry, -Amount, '', false);
        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, VendorLedgerEntry."Document No.", VendorLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        // Execute
        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        NewDiscountDueDate := CalcDate('<1M>', WorkDate());
        NewDiscountAmount := Round(Amount / 2, LibraryERM.GetAmountRoundingPrecision());
        TempPaymentApplicationProposal.Validate("Pmt. Disc. Due Date", NewDiscountDueDate);
        TempPaymentApplicationProposal.Validate("Remaining Pmt. Disc. Possible", NewDiscountAmount);
        TempPaymentApplicationProposal.Modify(true);

        // Verify
        Assert.AreEqual(
          TempPaymentApplicationProposal."Remaining Pmt. Disc. Possible", NewDiscountAmount, 'Discount amount was not set correctly');
        Assert.AreEqual(
          TempPaymentApplicationProposal."Pmt. Disc. Due Date", NewDiscountDueDate, 'Discount due date was not set correctly');

        VendorLedgerEntry.Get(VendorLedgerEntry."Entry No.");
        VendorLedgerEntry.CalcFields("Remaining Amount");

        Assert.AreEqual(VendorLedgerEntry."Remaining Pmt. Disc. Possible", NewDiscountAmount, 'Discount amount was not set correctly');
        Assert.AreEqual(VendorLedgerEntry."Pmt. Discount Date", NewDiscountDueDate, 'Discount due date was not set correctly');

        VerifyPaymentApplicationProposalDiscountFields(TempPaymentApplicationProposal, VendorLedgerEntry, NewDiscountAmount, Amount);

        // Verify that Vendor has overpaid, difference is discount applied amount is amount without discount
        NoOfEntries := 1;
        Difference := NewDiscountAmount;
        AppliedAmount := Amount - NewDiscountAmount;

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, VendorLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.IsTrue(PaymentApplicationProposal.IsEmpty, 'Payment Applications proposal table must be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSettingVendorDiscountOnAppliedProposalSettlesAmount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        PaymentApplicationProposal: Record "Payment Application Proposal";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        NewDiscountAmount: Decimal;
        Difference: Decimal;
        NewDiscountDueDate: Date;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := -LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostPurhcaseInvoiceWithOneLine(VendorLedgerEntry, -Amount, '', false);
        AppliedAmount := Round(Amount / 2, LibraryERM.GetAmountRoundingPrecision());
        CreateBankReconciliationLine(
          BankAccReconciliationLine, AppliedAmount, VendorLedgerEntry."Document No.", VendorLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        // Execute
        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        NewDiscountDueDate := CalcDate('<1M>', WorkDate());
        NewDiscountAmount := Amount - AppliedAmount;
        TempPaymentApplicationProposal.Validate("Pmt. Disc. Due Date", NewDiscountDueDate);
        TempPaymentApplicationProposal.Validate("Remaining Pmt. Disc. Possible", NewDiscountAmount);
        TempPaymentApplicationProposal.Modify(true);

        VendorLedgerEntry.Get(VendorLedgerEntry."Entry No.");
        VendorLedgerEntry.CalcFields("Remaining Amount");

        // Verify
        Assert.AreEqual(
          TempPaymentApplicationProposal."Remaining Pmt. Disc. Possible", NewDiscountAmount, 'Discount amount was not set correctly');
        Assert.AreEqual(
          TempPaymentApplicationProposal."Pmt. Disc. Due Date", NewDiscountDueDate, 'Discount due date was not set correctly');

        VerifyPaymentApplicationProposalDiscountFields(TempPaymentApplicationProposal, VendorLedgerEntry, NewDiscountAmount, Amount);

        // Verify No. are matching
        NoOfEntries := 1;
        Difference := 0;

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, VendorLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.IsTrue(PaymentApplicationProposal.IsEmpty, 'Payment Applications proposal table must be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestIncreasingVendorDiscountOnAppliedAmountTakesRemainingAmount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        PaymentApplicationProposal: Record "Payment Application Proposal";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        NewDiscountAmount: Decimal;
        Difference: Decimal;
        NewDiscountDueDate: Date;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := -LibraryRandom.RandDecInRange(1, 10000, 2);
        AppliedAmount := Round(Amount / 2, LibraryERM.GetAmountRoundingPrecision());

        CreateAndPostPurhcaseInvoiceWithOneLine(VendorLedgerEntry, -Amount, '', true);
        CreateBankReconciliationLine(
          BankAccReconciliationLine, AppliedAmount, VendorLedgerEntry."Document No.", VendorLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        // Execute
        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        NewDiscountDueDate := CalcDate('<1M>', WorkDate());
        NewDiscountAmount := Amount - AppliedAmount;
        TempPaymentApplicationProposal.Validate("Pmt. Disc. Due Date", NewDiscountDueDate);
        TempPaymentApplicationProposal.Validate("Remaining Pmt. Disc. Possible", NewDiscountAmount);
        TempPaymentApplicationProposal.Modify(true);

        VendorLedgerEntry.Get(VendorLedgerEntry."Entry No.");
        VendorLedgerEntry.CalcFields("Remaining Amount");

        // Verify
        Assert.AreEqual(
          TempPaymentApplicationProposal."Remaining Pmt. Disc. Possible", NewDiscountAmount, 'Discount amount was not set correctly');
        Assert.AreEqual(
          TempPaymentApplicationProposal."Pmt. Disc. Due Date", NewDiscountDueDate, 'Discount due date was not set correctly');

        VerifyPaymentApplicationProposalDiscountFields(TempPaymentApplicationProposal, VendorLedgerEntry, NewDiscountAmount, Amount);

        // Verify No. are matching
        NoOfEntries := 1;
        Difference := 0;

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, VendorLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.IsTrue(PaymentApplicationProposal.IsEmpty, 'Payment Applications proposal table must be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDecreasingVendorDiscountKeepsAppliedDiscount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        PaymentApplicationProposal: Record "Payment Application Proposal";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        NewDiscountAmount: Decimal;
        Difference: Decimal;
        NewDiscountDueDate: Date;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := -LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostPurhcaseInvoiceWithOneLine(VendorLedgerEntry, -Amount, '', true);
        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, VendorLedgerEntry."Document No.", VendorLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        // Execute
        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        NewDiscountDueDate := CalcDate('<1M>', WorkDate());
        NewDiscountAmount := Round(Amount / 2, LibraryERM.GetAmountRoundingPrecision());
        TempPaymentApplicationProposal.Validate("Pmt. Disc. Due Date", NewDiscountDueDate);
        TempPaymentApplicationProposal.Validate("Remaining Pmt. Disc. Possible", NewDiscountAmount);
        TempPaymentApplicationProposal.Modify(true);

        VendorLedgerEntry.Get(VendorLedgerEntry."Entry No.");
        VendorLedgerEntry.CalcFields("Remaining Amount");

        // Verify
        Assert.AreEqual(
          TempPaymentApplicationProposal."Remaining Pmt. Disc. Possible", NewDiscountAmount, 'Discount amount was not set correctly');
        Assert.AreEqual(
          TempPaymentApplicationProposal."Pmt. Disc. Due Date", NewDiscountDueDate, 'Discount due date was not set correctly');

        VerifyPaymentApplicationProposalDiscountFields(TempPaymentApplicationProposal, VendorLedgerEntry, NewDiscountAmount, Amount);

        // Verify No. are matching
        NoOfEntries := 1;
        Difference := NewDiscountAmount;
        AppliedAmount := Amount - NewDiscountAmount;

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, VendorLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.IsTrue(PaymentApplicationProposal.IsEmpty, 'Payment Applications proposal table must be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestDecreasingVendorDiscountRemovesAppliedDiscount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        PaymentApplicationProposal: Record "Payment Application Proposal";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        NewDiscountAmount: Decimal;
        Difference: Decimal;
        NewDiscountDueDate: Date;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := -LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostPurhcaseInvoiceWithOneLine(VendorLedgerEntry, -Amount, '', true);
        AppliedAmount := Amount - VendorLedgerEntry."Remaining Pmt. Disc. Possible";
        CreateBankReconciliationLine(
          BankAccReconciliationLine, AppliedAmount, VendorLedgerEntry."Document No.", VendorLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        // Execute
        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        NewDiscountDueDate := CalcDate('<1M>', WorkDate());
        NewDiscountAmount := Round(VendorLedgerEntry."Remaining Pmt. Disc. Possible" / 2, LibraryERM.GetAmountRoundingPrecision());
        TempPaymentApplicationProposal.Validate("Pmt. Disc. Due Date", NewDiscountDueDate);
        TempPaymentApplicationProposal.Validate("Remaining Pmt. Disc. Possible", NewDiscountAmount);
        TempPaymentApplicationProposal.Modify(true);

        VendorLedgerEntry.Get(VendorLedgerEntry."Entry No.");
        VendorLedgerEntry.CalcFields("Remaining Amount");

        // Verify
        Assert.AreEqual(
          TempPaymentApplicationProposal."Remaining Pmt. Disc. Possible", NewDiscountAmount, 'Discount amount was not set correctly');
        Assert.AreEqual(
          TempPaymentApplicationProposal."Pmt. Disc. Due Date", NewDiscountDueDate, 'Discount due date was not set correctly');

        VerifyPaymentApplicationProposalDiscountFields(TempPaymentApplicationProposal, VendorLedgerEntry, 0, AppliedAmount);

        // Verify No. are matching
        NoOfEntries := 1;
        Difference := 0;

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, VendorLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.IsTrue(PaymentApplicationProposal.IsEmpty, 'Payment Applications proposal table must be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSettingAppliedAmountToZeroRemovesTheDiscount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        PaymentApplicationProposal: Record "Payment Application Proposal";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := -LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostPurhcaseInvoiceWithOneLine(VendorLedgerEntry, -Amount, '', true);
        AppliedAmount := Amount - VendorLedgerEntry."Remaining Pmt. Disc. Possible";
        CreateBankReconciliationLine(
          BankAccReconciliationLine, AppliedAmount, VendorLedgerEntry."Document No.", VendorLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        // Execute
        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);
        TempPaymentApplicationProposal.Validate("Applied Amt. Incl. Discount", 0);
        TempPaymentApplicationProposal.Modify(true);

        // Verify
        VerifyPaymentApplicationProposalDiscountFields(TempPaymentApplicationProposal, VendorLedgerEntry, 0, 0);

        // Verify No. are matching
        NoOfEntries := 0;
        Difference := AppliedAmount;

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, VendorLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryDoesntExist(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.IsTrue(PaymentApplicationProposal.IsEmpty, 'Payment Applications proposal table must be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSettingTheFullAmountGivesTheDiscount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        PaymentApplicationProposal: Record "Payment Application Proposal";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        CreateVLEAndBankRecLine(VendorLedgerEntry, BankAccReconciliationLine, TempPaymentApplicationProposal, AppliedAmount, Amount);
        // Verify
        AppliedAmount := Amount - VendorLedgerEntry."Remaining Pmt. Disc. Possible";

        VerifyPaymentApplicationProposalDiscountFields(
          TempPaymentApplicationProposal, VendorLedgerEntry, VendorLedgerEntry."Remaining Pmt. Disc. Possible", Amount);

        // Verify No. are matching
        NoOfEntries := 1;
        Difference := VendorLedgerEntry."Remaining Pmt. Disc. Possible";

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, VendorLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.IsTrue(PaymentApplicationProposal.IsEmpty, 'Payment Applications proposal table must be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSettingTheDiscountAmountGivesTheDiscount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        PaymentApplicationProposal: Record "Payment Application Proposal";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        CreateVLEAndBankRecLine(VendorLedgerEntry, BankAccReconciliationLine, TempPaymentApplicationProposal, AppliedAmount, Amount);
        // Verify
        VerifyPaymentApplicationProposalDiscountFields(
          TempPaymentApplicationProposal, VendorLedgerEntry, VendorLedgerEntry."Remaining Pmt. Disc. Possible", Amount);

        // Verify No. are matching
        NoOfEntries := 1;
        Difference := VendorLedgerEntry."Remaining Pmt. Disc. Possible";

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, VendorLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.IsTrue(PaymentApplicationProposal.IsEmpty, 'Payment Applications proposal table must be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestChangingTheAmountRemovesTheDiscount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        PaymentApplicationProposal: Record "Payment Application Proposal";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        NewAppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        CreateVLEAndBankRecLine(VendorLedgerEntry, BankAccReconciliationLine, TempPaymentApplicationProposal, AppliedAmount, Amount);

        NewAppliedAmount := Round(AppliedAmount / 2, LibraryERM.GetAmountRoundingPrecision());

        // Execute
        TempPaymentApplicationProposal.Validate("Applied Amt. Incl. Discount", NewAppliedAmount);
        TempPaymentApplicationProposal.Modify(true);

        // Verify
        VerifyPaymentApplicationProposalDiscountFields(TempPaymentApplicationProposal, VendorLedgerEntry, 0, NewAppliedAmount);

        // Verify No. are matching
        NoOfEntries := 1;
        Difference := Amount - NewAppliedAmount;

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, VendorLedgerEntry, NewAppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.IsTrue(PaymentApplicationProposal.IsEmpty, 'Payment Applications proposal table must be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestRemovingTheAmountRemovesTheDiscount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        PaymentApplicationProposal: Record "Payment Application Proposal";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        CreateVLEAndBankRecLine(VendorLedgerEntry, BankAccReconciliationLine, TempPaymentApplicationProposal, AppliedAmount, Amount);

        // Execute
        TempPaymentApplicationProposal.Validate("Applied Amt. Incl. Discount", 0);
        TempPaymentApplicationProposal.Modify(true);

        // Verify
        VerifyPaymentApplicationProposalDiscountFields(TempPaymentApplicationProposal, VendorLedgerEntry, 0, 0);

        // Verify No. are matching
        NoOfEntries := 0;
        Difference := Amount;
        AppliedAmount := 0;

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, VendorLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryDoesntExist(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.IsTrue(PaymentApplicationProposal.IsEmpty, 'Payment Applications proposal table must be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSelectingApplySetsTheDiscountVendorPaidFullAmount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        PaymentApplicationProposal: Record "Payment Application Proposal";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := -LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostPurhcaseInvoiceWithOneLine(VendorLedgerEntry, -Amount, '', true);
        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, VendorLedgerEntry."Document No.", VendorLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        // Execut
        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        VendorLedgerEntry.Get(VendorLedgerEntry."Entry No.");
        VendorLedgerEntry.CalcFields("Remaining Amount");

        // Verify
        AppliedAmount := Amount - VendorLedgerEntry."Remaining Pmt. Disc. Possible";
        VerifyPaymentApplicationProposalDiscountFields(
          TempPaymentApplicationProposal, VendorLedgerEntry, VendorLedgerEntry."Remaining Pmt. Disc. Possible", Amount);

        // Verify No. are matching
        NoOfEntries := 1;
        Difference := VendorLedgerEntry."Remaining Pmt. Disc. Possible";

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, VendorLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.IsTrue(PaymentApplicationProposal.IsEmpty, 'Payment Applications proposal table must be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSelectingApplySetsTheDiscountVendorPaidDiscountAmount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        PaymentApplicationProposal: Record "Payment Application Proposal";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := -LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostPurhcaseInvoiceWithOneLine(VendorLedgerEntry, -Amount, '', true);
        AppliedAmount := Amount - VendorLedgerEntry."Remaining Pmt. Disc. Possible";

        CreateBankReconciliationLine(
          BankAccReconciliationLine, AppliedAmount, VendorLedgerEntry."Document No.", VendorLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        // Execute
        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        VendorLedgerEntry.Get(VendorLedgerEntry."Entry No.");
        VendorLedgerEntry.CalcFields("Remaining Amount");

        // Verify
        VerifyPaymentApplicationProposalDiscountFields(
          TempPaymentApplicationProposal, VendorLedgerEntry, VendorLedgerEntry."Remaining Pmt. Disc. Possible", Amount);

        // Verify No. are matching
        NoOfEntries := 1;
        Difference := 0;

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, VendorLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.IsTrue(PaymentApplicationProposal.IsEmpty, 'Payment Applications proposal table must be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestSelectingApplyDoesntSetDiscountIfAmountIsUnderExpectedAmount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        PaymentApplicationProposal: Record "Payment Application Proposal";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := -LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostPurhcaseInvoiceWithOneLine(VendorLedgerEntry, -Amount, '', true);
        AppliedAmount := Round((Amount - VendorLedgerEntry."Remaining Pmt. Disc. Possible") / 2, LibraryERM.GetAmountRoundingPrecision());

        CreateBankReconciliationLine(
          BankAccReconciliationLine, AppliedAmount, VendorLedgerEntry."Document No.", VendorLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        // Execute
        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        VendorLedgerEntry.Get(VendorLedgerEntry."Entry No.");
        VendorLedgerEntry.CalcFields("Remaining Amount");

        // Verify
        VerifyPaymentApplicationProposalDiscountFields(TempPaymentApplicationProposal, VendorLedgerEntry, 0, AppliedAmount);

        // Verify No. are matching
        NoOfEntries := 1;
        Difference := 0;

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, VendorLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.IsTrue(PaymentApplicationProposal.IsEmpty, 'Payment Applications proposal table must be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestUncheckingApplyRemovesTheDiscount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        PaymentApplicationProposal: Record "Payment Application Proposal";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        AppliedAmount: Decimal;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := -LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostPurhcaseInvoiceWithOneLine(VendorLedgerEntry, -Amount, '', true);
        AppliedAmount := Amount - VendorLedgerEntry."Remaining Pmt. Disc. Possible";

        CreateBankReconciliationLine(
          BankAccReconciliationLine, AppliedAmount, VendorLedgerEntry."Document No.", VendorLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        VendorLedgerEntry.Get(VendorLedgerEntry."Entry No.");
        VendorLedgerEntry.CalcFields("Remaining Amount");

        // Execute
        TempPaymentApplicationProposal.Validate(Applied, false);
        TempPaymentApplicationProposal.Modify(true);

        // Verify
        VerifyPaymentApplicationProposalDiscountFields(TempPaymentApplicationProposal, VendorLedgerEntry, 0, 0);

        // Verify No. are matching
        NoOfEntries := 0;
        Difference := Amount;
        AppliedAmount := 0;

        // Verify Bank Acc Reconciliation Line
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, VendorLedgerEntry, AppliedAmount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryDoesntExist(TempPaymentApplicationProposal);

        // Test no Insertions to Payment Application Proposal has occured
        Assert.IsTrue(PaymentApplicationProposal.IsEmpty, 'Payment Applications proposal table must be empty');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplyingOnMultipleLinesGivesTheDiscount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        TempPaymentApplicationProposal2: Record "Payment Application Proposal" temporary;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliationLine2: Record "Bank Acc. Reconciliation Line";
        BankAccount: Record "Bank Account";
        Amount: Decimal;
        FirstLineAmount: Decimal;
        SecondLineAmount: Decimal;
    begin
        Initialize();

        Amount := -LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostPurhcaseInvoiceWithOneLine(VendorLedgerEntry, -Amount, '', true);
        FirstLineAmount := Round(Amount / 2, LibraryERM.GetAmountRoundingPrecision());
        SecondLineAmount := Amount - FirstLineAmount - VendorLedgerEntry."Remaining Pmt. Disc. Possible";

        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccount."No.",
          BankAccReconciliation."Statement Type"::"Payment Application");

        CreateBankReconciliationLine2(BankAccReconciliationLine, BankAccReconciliation, FirstLineAmount, '', '');
        CreateBankReconciliationLine2(BankAccReconciliationLine2, BankAccReconciliation, SecondLineAmount, '', '');
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal2, BankAccReconciliationLine2);

        // Execute - Apply first line
        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        VerifyCommenDiscountSenarios(
          TempPaymentApplicationProposal, TempPaymentApplicationProposal2, BankAccReconciliationLine, BankAccReconciliationLine2,
          VendorLedgerEntry, FirstLineAmount, SecondLineAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestApplyingOnMultipleLinesGivesTheDiscountByTypingTheAmount()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        TempPaymentApplicationProposal2: Record "Payment Application Proposal" temporary;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        BankAccReconciliationLine2: Record "Bank Acc. Reconciliation Line";
        BankAccount: Record "Bank Account";
        Amount: Decimal;
        FirstLineAmount: Decimal;
        SecondLineAmount: Decimal;
    begin
        Initialize();

        // Setup
        Amount := -LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostPurhcaseInvoiceWithOneLine(VendorLedgerEntry, -Amount, '', true);
        FirstLineAmount := Round(Amount / 2, LibraryERM.GetAmountRoundingPrecision());
        SecondLineAmount := Amount - FirstLineAmount - VendorLedgerEntry."Remaining Pmt. Disc. Possible";

        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccount."No.",
          BankAccReconciliation."Statement Type"::"Payment Application");

        CreateBankReconciliationLine2(BankAccReconciliationLine, BankAccReconciliation, FirstLineAmount, '', '');
        CreateBankReconciliationLine2(BankAccReconciliationLine2, BankAccReconciliation, SecondLineAmount, '', '');
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal2, BankAccReconciliationLine2);

        // Execute - Apply first line
        TempPaymentApplicationProposal.Validate("Applied Amt. Incl. Discount", FirstLineAmount);
        TempPaymentApplicationProposal.Modify(true);

        VerifyCommenDiscountSenarios(
          TempPaymentApplicationProposal, TempPaymentApplicationProposal2, BankAccReconciliationLine, BankAccReconciliationLine2,
          VendorLedgerEntry, FirstLineAmount, SecondLineAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCannotSetTheDiscountAmountToVendorCreditLine()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostPurhcaseInvoiceWithOneLine(VendorLedgerEntry, Amount, '', true);
        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, '', '');
        CreateNewPaymentApplicationLine(
          TempPaymentApplicationProposal, BankAccReconciliationLine, TempPaymentApplicationProposal."Account Type"::Vendor,
          VendorLedgerEntry."Vendor No.");

        // Execute, Verify
        asserterror TempPaymentApplicationProposal.Validate("Pmt. Disc. Due Date", Today);
        asserterror TempPaymentApplicationProposal.Validate(
            "Remaining Pmt. Disc. Possible", LibraryRandom.RandDecInRange(1, 10000, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestPaymentDiscToleranceDateIsSet()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
    begin
        Initialize();

        GeneralLedgerSetup.Get();
        Evaluate(GeneralLedgerSetup."Payment Discount Grace Period", '<+10D>');
        GeneralLedgerSetup.Modify();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostPurhcaseInvoiceWithOneLine(VendorLedgerEntry, Amount, '', true);
        CreateBankReconciliationLine(BankAccReconciliationLine, -Amount, '', '');
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        Assert.IsTrue(
          TempPaymentApplicationProposal."Pmt. Disc. Tolerance Date" > 0D, 'Payment Disc. Tolerance Date was not set correctly');
        Assert.AreEqual(
          CalcDate(GeneralLedgerSetup."Payment Discount Grace Period", VendorLedgerEntry."Pmt. Discount Date"),
          TempPaymentApplicationProposal."Pmt. Disc. Tolerance Date", 'Payment Disc. Tolerance Date was not set correctly');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestModifyingPaymentDiscToleranceDateDoesntChangeDueDateAndViceVersa()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        PaymentDiscDueDate: Date;
        NewPaymentDiscToleranceDate: Date;
    begin
        Initialize();

        GeneralLedgerSetup.Get();
        Evaluate(GeneralLedgerSetup."Payment Discount Grace Period", '<+10D>');
        GeneralLedgerSetup.Modify();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostPurhcaseInvoiceWithOneLine(VendorLedgerEntry, Amount, '', true);
        CreateBankReconciliationLine(BankAccReconciliationLine, -Amount, '', '');
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        NewPaymentDiscToleranceDate := CalcDate('<-20D>', TempPaymentApplicationProposal."Pmt. Disc. Tolerance Date");
        PaymentDiscDueDate := TempPaymentApplicationProposal."Pmt. Disc. Due Date";
        TempPaymentApplicationProposal.Validate("Pmt. Disc. Tolerance Date", NewPaymentDiscToleranceDate);
        TempPaymentApplicationProposal.Modify(true);

        Assert.AreEqual(
          NewPaymentDiscToleranceDate, TempPaymentApplicationProposal."Pmt. Disc. Tolerance Date",
          'Tolerance date was not changed correctly');
        Assert.AreEqual(PaymentDiscDueDate, TempPaymentApplicationProposal."Pmt. Disc. Due Date", 'Due date should not be changed');

        PaymentDiscDueDate := CalcDate('<+10D>', TempPaymentApplicationProposal."Pmt. Disc. Due Date");
        TempPaymentApplicationProposal.Validate("Pmt. Disc. Due Date", PaymentDiscDueDate);
        TempPaymentApplicationProposal.Modify(true);

        Assert.AreEqual(
          NewPaymentDiscToleranceDate, TempPaymentApplicationProposal."Pmt. Disc. Tolerance Date", 'Tolerance date should not be changed');
        Assert.AreEqual(PaymentDiscDueDate, TempPaymentApplicationProposal."Pmt. Disc. Due Date", 'Due date was not updated correctly');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure TestApplyingPaymentWithDateBeforePostingDateShowsWarning()
    var
        TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        Amount: Decimal;
        NewTransactionDate: Date;
        Difference: Decimal;
        NoOfEntries: Integer;
    begin
        Initialize();

        // Setup
        Amount := LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostPurhcaseInvoiceWithOneLine(VendorLedgerEntry, Amount, '', false);
        CreateBankReconciliationLine(BankAccReconciliationLine, -Amount, '', '');
        NewTransactionDate := CalcDate('<-20D>', VendorLedgerEntry."Posting Date");
        BankAccReconciliationLine.Validate("Transaction Date", NewTransactionDate);
        BankAccReconciliationLine.Modify(true);

        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        LibraryVariableStorage.Enqueue(
          StrSubstNo(TransactionDateIsBeforePostingDateTxt, NewTransactionDate, VendorLedgerEntry."Posting Date"));
        TempPaymentApplicationProposal.Validate(Applied, true);
        TempPaymentApplicationProposal.Modify(true);

        // Verify Bank Acc Reconciliation Line
        Difference := 0;
        NoOfEntries := 1;
        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, VendorLedgerEntry, -Amount, Difference, NoOfEntries);

        // Verify Applied Payment Entry Exists and the fields are set
        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure CreateVLEAndBankRecLine(var VendorLedgerEntry: Record "Vendor Ledger Entry"; var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; var TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary; var AppliedAmount: Decimal; var Amount: Decimal)
    begin
        Initialize();

        // Setup
        Amount := -LibraryRandom.RandDecInRange(1, 10000, 2);

        CreateAndPostPurhcaseInvoiceWithOneLine(VendorLedgerEntry, -Amount, '', true);
        AppliedAmount := Amount - VendorLedgerEntry."Remaining Pmt. Disc. Possible";

        CreateBankReconciliationLine(BankAccReconciliationLine, Amount, VendorLedgerEntry."Document No.", VendorLedgerEntry."Document No.");
        CreatePaymentApplicationProposalLines(TempPaymentApplicationProposal, BankAccReconciliationLine);

        // Execute
        TempPaymentApplicationProposal.Validate("Applied Amt. Incl. Discount", AppliedAmount);
        TempPaymentApplicationProposal.Modify(true);

        VendorLedgerEntry.Get(VendorLedgerEntry."Entry No.");
        VendorLedgerEntry.CalcFields("Remaining Amount");
    end;

    local procedure VerifyCommenDiscountSenarios(var TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary; var TempPaymentApplicationProposal2: Record "Payment Application Proposal" temporary; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; BankAccReconciliationLine2: Record "Bank Acc. Reconciliation Line"; VendLedgerEntry: Record "Vendor Ledger Entry"; FirstLineAmount: Decimal; SecondLineAmount: Decimal)
    var
        NoOfEntries: Integer;
        Difference: Decimal;
    begin
        // Verify - First line application
        VerifyPaymentApplicationProposalDiscountFields(TempPaymentApplicationProposal, VendLedgerEntry, 0, FirstLineAmount);

        NoOfEntries := 1;
        Difference := 0;

        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine, TempPaymentApplicationProposal, VendLedgerEntry, FirstLineAmount, Difference, NoOfEntries);

        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");

        // Execute - Apply Second Line - ther should be a discount set
        TempPaymentApplicationProposal2.Validate(Applied, true);
        TempPaymentApplicationProposal2.Modify(true);

        // Verify - Second line application
        VerifyPaymentApplicationProposalDiscountFields(
          TempPaymentApplicationProposal2, VendLedgerEntry, VendLedgerEntry."Remaining Pmt. Disc. Possible",
          SecondLineAmount + VendLedgerEntry."Remaining Pmt. Disc. Possible");

        VerifyBankAccReconciliationLineIsUpdatedCorrectly(
          BankAccReconciliationLine2, TempPaymentApplicationProposal2, VendLedgerEntry, SecondLineAmount, Difference, NoOfEntries);

        VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal);

        Assert.TableIsEmpty(DATABASE::"Payment Application Proposal");
    end;

    local procedure GetCommonFields(var FieldRefArray: array[18] of FieldRef)
    var
        PaymentApplicationProposal: Record "Payment Application Proposal";
        RecRef: RecordRef;
        I: Integer;
    begin
        I := 1;
        RecRef.Open(DATABASE::"Payment Application Proposal");
        PaymentApplicationProposal.Init();
        AddToArray(FieldRefArray, I, RecRef.Field(PaymentApplicationProposal.FieldNo("Bank Account No.")));
        AddToArray(FieldRefArray, I, RecRef.Field(PaymentApplicationProposal.FieldNo("Statement No.")));
        AddToArray(FieldRefArray, I, RecRef.Field(PaymentApplicationProposal.FieldNo("Statement Line No.")));
        AddToArray(FieldRefArray, I, RecRef.Field(PaymentApplicationProposal.FieldNo("Statement Type")));
        AddToArray(FieldRefArray, I, RecRef.Field(PaymentApplicationProposal.FieldNo("Account Type")));
        AddToArray(FieldRefArray, I, RecRef.Field(PaymentApplicationProposal.FieldNo("Account No.")));
        AddToArray(FieldRefArray, I, RecRef.Field(PaymentApplicationProposal.FieldNo("Applies-to Entry No.")));
        AddToArray(FieldRefArray, I, RecRef.Field(PaymentApplicationProposal.FieldNo("Applied Amount")));
        AddToArray(FieldRefArray, I, RecRef.Field(PaymentApplicationProposal.FieldNo("Applied Pmt. Discount")));
        AddToArray(FieldRefArray, I, RecRef.Field(PaymentApplicationProposal.FieldNo(Quality)));
        AddToArray(FieldRefArray, I, RecRef.Field(PaymentApplicationProposal.FieldNo("Posting Date")));
        AddToArray(FieldRefArray, I, RecRef.Field(PaymentApplicationProposal.FieldNo("Document Type")));
        AddToArray(FieldRefArray, I, RecRef.Field(PaymentApplicationProposal.FieldNo("Document No.")));
        AddToArray(FieldRefArray, I, RecRef.Field(PaymentApplicationProposal.FieldNo(Description)));
        AddToArray(FieldRefArray, I, RecRef.Field(PaymentApplicationProposal.FieldNo("Currency Code")));
        AddToArray(FieldRefArray, I, RecRef.Field(PaymentApplicationProposal.FieldNo("Due Date")));
        AddToArray(FieldRefArray, I, RecRef.Field(PaymentApplicationProposal.FieldNo("External Document No.")));
        AddToArray(FieldRefArray, I, RecRef.Field(PaymentApplicationProposal.FieldNo("Match Confidence")));
    end;

    local procedure AddToArray(var FieldRefArray: array[17] of FieldRef; var I: Integer; CurrFieldRef: FieldRef)
    begin
        FieldRefArray[I] := CurrFieldRef;
        I += 1;
    end;

    local procedure CreatePaymentApplicationProposalLines(var TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line")
    begin
        TempPaymentApplicationProposal.TransferFromBankAccReconLine(BankAccReconciliationLine);
        CODEUNIT.Run(CODEUNIT::"Get Bank Stmt. Line Candidates", TempPaymentApplicationProposal);
        TempPaymentApplicationProposal.FindFirst();
    end;

    local procedure CreateBankReconciliationLine(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; Amount: Decimal; TransactionText: Text[140]; AdditionalTransactionInfo: Text[100])
    var
        BankAccount: Record "Bank Account";
        BankAccReconciliation: Record "Bank Acc. Reconciliation";
    begin
        LibraryERM.CreateBankAccount(BankAccount);
        LibraryERM.CreateBankAccReconciliation(BankAccReconciliation, BankAccount."No.",
          BankAccReconciliation."Statement Type"::"Payment Application");

        CreateBankReconciliationLine2(BankAccReconciliationLine, BankAccReconciliation, Amount, TransactionText, AdditionalTransactionInfo);
    end;

    local procedure CreateBankReconciliationLine2(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; BankAccReconciliation: Record "Bank Acc. Reconciliation"; Amount: Decimal; TransactionText: Text[140]; AdditionalTransactionInfo: Text[100])
    begin
        LibraryERM.CreateBankAccReconciliationLn(BankAccReconciliationLine, BankAccReconciliation);
        BankAccReconciliationLine.Validate("Transaction Text", TransactionText);
        BankAccReconciliationLine.Validate("Additional Transaction Info", AdditionalTransactionInfo);
        BankAccReconciliationLine.Validate("Transaction Date", WorkDate());
        BankAccReconciliationLine.Validate("Statement Amount", Amount);
        BankAccReconciliationLine.Modify(true);
    end;

    local procedure CreateAndPostPurhcaseInvoiceWithOneLine(var VendorLedgerEntry: Record "Vendor Ledger Entry"; Amount: Decimal; VendorNo: Code[20]; AddDiscount: Boolean)
    var
        Vendor: Record Vendor;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PaymentTerms: Record "Payment Terms";
        DocumentNo: Code[20];
    begin
        if VendorNo = '' then begin
            LibraryPurchase.CreateVendor(Vendor);
            VendorNo := Vendor."No.";

            if AddDiscount then begin
                LibraryERM.CreatePaymentTermsDiscount(PaymentTerms, false);
                Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
                Vendor.Modify(true);
            end;
        end;

        CreateItem(Item, Amount);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);

        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        Clear(VendorLedgerEntry);
        VendorLedgerEntry.Init();
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields("Remaining Amount");
    end;

    [Normal]
    local procedure CreateItem(var Item: Record Item; Amount: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("VAT Prod. Posting Group", ZeroVATPostingSetup."VAT Prod. Posting Group");
        Item.Validate("Unit Price", Amount);
        Item.Validate("Last Direct Cost", Amount);
        Item.Modify(true);
    end;

    [Normal]
    local procedure CreateNewPaymentApplicationLine(var TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary; BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20])
    begin
        Clear(TempPaymentApplicationProposal);
        TempPaymentApplicationProposal.Init();
        TempPaymentApplicationProposal.TransferFromBankAccReconLine(BankAccReconciliationLine);
        TempPaymentApplicationProposal."Account Type" := AccountType;
        TempPaymentApplicationProposal."Account No." := AccountNo;
        TempPaymentApplicationProposal.Insert(true);
    end;

    local procedure VerifyAppliedPaymentEntryMatchesProposalLine(TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary)
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
        AppliedPaymentEntryRecordRef: RecordRef;
        PaymentApplicationProposalRecordRef: RecordRef;
        CommonFieldsFieldRef: array[18] of FieldRef;
        AppliedPmtEntryFieldRef: FieldRef;
        PaymentProposalFieldRef: FieldRef;
        I: Integer;
    begin
        TempPaymentApplicationProposal.GetAppliedPaymentEntry(AppliedPaymentEntry);
        GetCommonFields(CommonFieldsFieldRef);

        PaymentApplicationProposalRecordRef.GetTable(TempPaymentApplicationProposal);
        AppliedPaymentEntryRecordRef.GetTable(AppliedPaymentEntry);

        for I := 1 to ArrayLen(CommonFieldsFieldRef) do begin
            AppliedPmtEntryFieldRef := AppliedPaymentEntryRecordRef.Field(CommonFieldsFieldRef[I].Number);
            PaymentProposalFieldRef := PaymentApplicationProposalRecordRef.Field(CommonFieldsFieldRef[I].Number);
            Assert.AreEqual(
              AppliedPmtEntryFieldRef.Value, PaymentProposalFieldRef.Value,
              StrSubstNo('The values for field %1 do not match', AppliedPmtEntryFieldRef.Name));
        end;
    end;

    local procedure VerifyBankAccReconciliationLineIsUpdatedCorrectly(var BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line"; TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary; VendorLedgerEntry: Record "Vendor Ledger Entry"; AppliedAmount: Decimal; Difference: Decimal; NoOfAppliedEntries: Integer)
    begin
        BankAccReconciliationLine.Get(
          BankAccReconciliationLine."Statement Type", BankAccReconciliationLine."Bank Account No.",
          BankAccReconciliationLine."Statement No.", BankAccReconciliationLine."Statement Line No.");
        Assert.AreEqual(
          Format(BankAccReconciliationLine."Account Type"), Format(TempPaymentApplicationProposal."Account Type"),
          'Account type is not set');
        Assert.AreEqual(BankAccReconciliationLine."Applied Entries", NoOfAppliedEntries, 'There should be only one Applied Entry');

        if NoOfAppliedEntries > 0 then begin
            Assert.AreEqual(BankAccReconciliationLine."Applied Amount", AppliedAmount, ' Applied Amount is not set');
            Assert.AreEqual(BankAccReconciliationLine.Difference, Difference, 'Difference is Not set correctly');
            Assert.AreEqual(BankAccReconciliationLine."Account No.", TempPaymentApplicationProposal."Account No.", 'Account No. is not set');
            Assert.IsTrue(
              (StrPos(BankAccReconciliationLine.GetAppliedToDocumentNo(), VendorLedgerEntry."Document No.") > 0) or
              (VendorLedgerEntry."Document No." = ''), 'Document No. is not added');
        end else begin
            Assert.AreEqual(BankAccReconciliationLine."Account No.", '', 'Account No. should be blank');
            Assert.AreEqual(BankAccReconciliationLine."Applied Amount", 0, ' Applied Amount should be zero');
            Assert.AreEqual(
              BankAccReconciliationLine.Difference, BankAccReconciliationLine."Statement Amount", 'Difference is Not set correctly');
            Assert.AreEqual(BankAccReconciliationLine.GetAppliedToDocumentNo(), '', 'Document No. should be blank');
        end;
    end;

    local procedure VerifyAppliedPaymentEntryDoesntExist(TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary)
    var
        AppliedPaymentEntry: Record "Applied Payment Entry";
    begin
        AppliedPaymentEntry.SetRange("Statement Type", TempPaymentApplicationProposal."Statement Type");
        AppliedPaymentEntry.SetRange("Bank Account No.", TempPaymentApplicationProposal."Bank Account No.");
        AppliedPaymentEntry.SetRange("Statement No.", TempPaymentApplicationProposal."Statement No.");
        AppliedPaymentEntry.SetRange("Statement Line No.", TempPaymentApplicationProposal."Statement Line No.");
        AppliedPaymentEntry.SetRange("Account Type", TempPaymentApplicationProposal."Account Type");
        AppliedPaymentEntry.SetRange("Account No.", TempPaymentApplicationProposal."Account No.");
        AppliedPaymentEntry.SetRange("Applies-to Entry No.", TempPaymentApplicationProposal."Applies-to Entry No.");

        Assert.IsTrue(AppliedPaymentEntry.IsEmpty, 'Applied Payment Entries should not be present');
    end;

    [Normal]
    local procedure VerifyPaymentApplicationProposalDiscountFields(TempPaymentApplicationProposal: Record "Payment Application Proposal" temporary; VendorLedgerEntry: Record "Vendor Ledger Entry"; ExpectedAppliedDiscountAmount: Decimal; ExpectedAppliedAmount: Decimal)
    begin
        Assert.AreEqual(
          ExpectedAppliedDiscountAmount, TempPaymentApplicationProposal."Applied Pmt. Discount",
          'Applied Pmt. Discount was not set to a correct value');
        Assert.AreEqual(ExpectedAppliedAmount, TempPaymentApplicationProposal."Applied Amount", 'Amount was not set to a correct value');
        Assert.AreEqual(
          ExpectedAppliedAmount - ExpectedAppliedDiscountAmount, TempPaymentApplicationProposal."Applied Amt. Incl. Discount",
          'Applied Amt. Including Discount was not set to correct value');
        Assert.AreEqual(
          TempPaymentApplicationProposal."Remaining Amount", VendorLedgerEntry."Remaining Amount",
          'Remaining Amount was not set to a correct value');
        Assert.AreEqual(
          TempPaymentApplicationProposal."Remaining Amt. Incl. Discount",
          VendorLedgerEntry."Remaining Amount" - VendorLedgerEntry."Remaining Pmt. Disc. Possible",
          'Remaining Amount Incl Discount was not set to a correct value');
    end;

    [Normal]
    local procedure CloseExistingEntries()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange(Open, true);
        CustLedgerEntry.ModifyAll(Open, false);

        VendorLedgerEntry.SetRange(Open, true);
        VendorLedgerEntry.ModifyAll(Open, false);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(MessageText: Text)
    var
        ExpectedMessageVariant: Variant;
        ExpectedMessageText: Text;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessageVariant);
        ExpectedMessageText := ExpectedMessageVariant;
        Assert.ExpectedMessage(ExpectedMessageText, MessageText);
    end;
}

